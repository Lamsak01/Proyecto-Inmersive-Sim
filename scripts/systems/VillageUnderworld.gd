@tool
extends RefCounted
const _AN_SITIOS = preload("res://mapa/anclas.gd") # plan de sitios: sitios al aire libre siguen a lo movido

## Bloque P7: Mercado negro, contrabando y bajos fondos (10 mecánicas).
## 1) Perista nocturno tras la taberna (21:00–04:00) o contacto clandestino una vez descubierto.
## 2) Catálogo de herramientas ilegales (ganzúa maestra, veneno lento, somnífero, salvoconducto falso y venta de botín).
## 3) Tráfico y cocina de «polvo de ocaso» (comprar, destilar en tu banco de trabajo casero y vender a ricos o adictos).
## 4) Encargos de robo a medida del perista (Sello Noble, Cáliz de la Capilla, Libro Mayor Gremial).
## 5) Ser prestamista usurero del pueblo (prestar 25 de oro al 40 % y cobrar en oro o en favores/votos).
## 6) Extorsión y cobro de «protección» semanal a comercios (10 de oro cada sábado por tienda intimidada).
## 7) Contratar a un ladrón o saboteador a sueldo (ensucia las manos de otro por 25 de oro).
## 8) Club de pelea clandestino a medianoche (apostar 15 de oro o pelear tú mismo por 35 de oro).
## 9) Sobornar la ronda nocturna del guardia (15 de oro por inmunidad nocturna ese día).
## 10) Delatar al perista al Comisario (+45 Oro) o destronarlo para convertirte en el Jefe del Hampa (+12 Oro/semana).
## Estado en `VillageNeeds.state(vm)["underworld"]` (se guarda automáticamente con `needs_state`).

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageClans = preload("res://scripts/systems/VillageClans.gd")
const VillageForensics = preload("res://scripts/systems/VillageForensics.gd")
const VillageHousing = preload("res://scripts/systems/VillageHousing.gd")
const VillageCollections = preload("res://scripts/systems/VillageCollections.gd")
const VillageNightJobs = preload("res://scripts/systems/VillageNightJobs.gd")
const AnimalModel3DScript = preload("res://scripts/visuals/AnimalModel3D.gd")

## Bloque P3 Parte B: Campamento físico nocturno de la caravana de contrabando (claro noreste al norte de mansión f1).
const SMUGGLER_CAMP_POS: Vector2 = Vector2(1350.0, -560.0)
const SMUGGLER_BORDER_POS: Vector2 = Vector2(1386.0, -584.0)

class SmugglerTradeArea extends Area2D:
	var vm_ref = null
	var mode: String = "buy"

	func _init(p_vm = null, p_mode: String = "buy") -> void:
		vm_ref = p_vm
		mode = p_mode
		name = "SmugglerTradeArea_" + p_mode
		collision_layer = 1
		collision_mask = 0
		monitoring = false
		monitorable = true
		add_to_group("interactable")
		var cs := CollisionShape2D.new()
		var cir := CircleShape2D.new()
		cir.radius = 24.0
		cs.shape = cir
		add_child(cs)

	func get_interact_label(_player: Node2D = null) -> String:
		return get_interaction_label()

	func get_interaction_label() -> String:
		if mode == "buy":
			return "Comprar lote de contrabando (−25 oro → +2 polvo de ocaso)"
		return "Vender polvo de ocaso (+35 oro)"

	func interact(interactor: Node = null) -> void:
		if vm_ref == null or not is_instance_valid(vm_ref):
			return
		var inv = interactor.get("inventory") if interactor != null else null
		if inv == null:
			var pl = VillageNeeds.player_of(vm_ref)
			if pl != null:
				inv = pl.get("inventory")
		if mode == "buy":
			vm_ref.VillageUnderworld.caravan_buy(vm_ref, inv, true, interactor)
		else:
			vm_ref.VillageUnderworld.caravan_sell(vm_ref, inv, interactor)

class SmugglerCampCart extends Node2D:
	var vm_ref = null
	var buy_area: SmugglerTradeArea = null
	var sell_area: SmugglerTradeArea = null

	func _init(p_vm = null) -> void:
		vm_ref = p_vm
		name = "SmugglerCampCart"
		y_sort_enabled = true
		add_to_group("smuggler_caravan_cart")
		_build_visuals()
		buy_area = SmugglerTradeArea.new(p_vm, "buy")
		buy_area.position = Vector2(-14.0, 8.0)
		add_child(buy_area)
		sell_area = SmugglerTradeArea.new(p_vm, "sell")
		sell_area.position = Vector2(14.0, 8.0)
		add_child(sell_area)

	func _build_visuals() -> void:
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([Vector2(-16, -8), Vector2(16, -8), Vector2(16, 8), Vector2(-16, 8)])
		poly.color = Color(0.28, 0.20, 0.14, 0.95)
		add_child(poly)
		AnimalModel3DScript.attach(self, "fantasy_town/cart.glb", 24.0, 4.0, Color(0.55, 0.48, 0.42), false)
		var lantern_holder := Node2D.new()
		lantern_holder.name = "SmugglerLanternHolder"
		lantern_holder.position = Vector2(18.0, -6.0)
		add_child(lantern_holder)
		AnimalModel3DScript.attach(lantern_holder, "fantasy_town/lantern.glb", 10.0, 2.0, Color.WHITE, true)

## Bloque FIS2: cada objetivo de robo está físicamente dentro de su edificio:
## - `sello_noble`: Mansión señorial (`solar f1`, estudio en `Vector2(1275, -444)`).
## - `caliz_capilla`: Capilla (`building_church`, altar en `Vector2(745, 336)`).
## - `libro_gremial`: Ayuntamiento (`solar n4`, mesa municipal en `Vector2(764, -449)`).
const HEIST_TARGETS: Array[Dictionary] = [
	{"id": "sello_noble", "label": "el Sello de Lacre Noble", "pos": Vector2(1275.0, -444.0), "reward": 55},
	{"id": "caliz_capilla", "label": "el Cáliz de Plata de la Capilla", "pos": Vector2(745.0, 336.0), "reward": 55},
	{"id": "libro_gremial", "label": "el Libro Mayor de los Gremios", "pos": Vector2(764.0, -449.0), "reward": 55},
]

## Lo que el perista acepta como «mercancía caliente» y cuánto paga (de su bolsillo). Antes daba 25 sin pedir nada.
const FENCE_PRICES: Dictionary = {"royal_safe_conduct": 25, "master_lockpick": 20, "surgical_kit": 18, "golden_egg": 15, "bandit_scrap": 12, "fox_pelt": 10, "steel_ingot": 10, "copper_coil": 9}
const DUST_PRICE: int = 30
const DUST_COOK_COST: int = 25
const RACKET_WEEKLY: int = 10
const BOSS_TRIBUTE: int = 12
const SEWER_KEY_COST: int = 20
## P5b: el perista trasnocha en el callejón de detrás de la taberna (esquina noroeste, fuera del edificio ampliado).
const FENCE_ALLEY_POS: Vector2 = Vector2(232.0, -298.0)
const FENCE_ALLEY_FROM: int = 22
const FENCE_ALLEY_UNTIL: int = 3
## P5b: rumores sutiles en la taberna (raros; solo de vecinos con algo turbio).
const FENCE_RUMOR_CHANCE: float = 0.10
const FENCE_RUMOR_MALICE: float = 0.2
const FENCE_RUMORS: Array[String] = [
	"Anoche volvía tarde y olía a pipa detrás de la taberna. ¿Quién fuma ahí a esas horas?",
	"Yo, de noche, no paso por el callejón. Manías mías.",
	"Hay quien paga por lo que no tiene dueño. No me preguntes quién, que no lo sé.",
	"Lo que se pierde en este pueblo no se pierde: cambia de manos antes del alba.",
	"Si oyes una puerta trasera pasada la medianoche, mejor no mires.",
	"Pasadas las nueve de la noche se oyen gritos y golpes sordos bajo las tablas de la bodega de la taberna.",
	"En el cuarto de la escalera de la taberna hay una trampilla entre barriles: de noche bajan a jugarse los cuartos a puñetazos.",
]

## Bloque FIS3: Cada entrada de `SEWER_LOCATIONS` define:
## - `pos`: Trampilla/rejilla en la calle (fuera de edificios y fuera de las calzadas de paso de los vecinos).
## - `chamber_center`: Centro de su cámara en la red de túneles conectada directamente bajo el centro del pueblo (`y = SEWER_Y = 63.0`).
## - `tunnel_pos`: Punto donde aparece el jugador al bajar por esa trampilla.
## - `ladder_pos`: Escalerilla física para subir de vuelta a esa trampilla de la calle.
## - `chest_pos`: Cofre de contrabando físico (1 vez al día por cámara).
const SEWER_Y: float = 63.0
const SEWER_LOCATIONS_BASE: Dictionary = {
	"cistern": {
		"title": "Cisterna Vieja bajo la Plaza",
		"pos": Vector2(518.0, 26.0),
		"chamber_center": Vector2(580.0, SEWER_Y),
		"tunnel_pos": Vector2(556.0, SEWER_Y - 6.0),
		"ladder_pos": Vector2(556.0, SEWER_Y - 24.0),
		"chest_pos": Vector2(604.0, SEWER_Y - 24.0),
		"difficulty": 0.30,
		"loot_item": "copper_coil"
	},
	"smuggler_tunnel": {
		"title": "Pasadizo del Contrabandista",
		"pos": Vector2(236.0, -148.0),
		"chamber_center": Vector2(420.0, SEWER_Y),
		"tunnel_pos": Vector2(396.0, SEWER_Y - 6.0),
		"ladder_pos": Vector2(396.0, SEWER_Y - 24.0),
		"chest_pos": Vector2(444.0, SEWER_Y - 24.0),
		"difficulty": 0.25,
		"loot_item": "bandit_scrap"
	},
	"flooded_vault": {
		"title": "Bóveda Inundada del Antiguo Gremio",
		"pos": Vector2(182.0, -64.0),
		"chamber_center": Vector2(260.0, SEWER_Y),
		"tunnel_pos": Vector2(236.0, SEWER_Y - 6.0),
		"ladder_pos": Vector2(236.0, SEWER_Y - 24.0),
		"chest_pos": Vector2(284.0, SEWER_Y - 24.0),
		"difficulty": 0.40,
		"loot_item": "steel_ingot"
	}
}
## Editor del mapa 3D (2026-11-10): build_sewers_world() rellena esto con las trampillas donde estén en la calle (siguen a
## las anclas) y la red de túneles desplazada lo que el usuario la movió (pieza «bajo_alcantarillas» de «BajoTierra»).
static var SEWER_LOCATIONS: Dictionary = SEWER_LOCATIONS_BASE.duplicate(true)
static var desp_red: Vector2 = Vector2.ZERO

static func fenceable_item(inv) -> String:
	if inv == null:
		return ""
	var best: String = ""
	for it in FENCE_PRICES.keys():
		if inv.has_item(it, 1) and (best == "" or int(FENCE_PRICES[it]) > int(FENCE_PRICES[best])):
			best = it
	return best

## Cobra `amount` a un comercio: primero de la caja del taller y, si no llega, del bolsillo del dueño. Devuelve lo cobrado.
static func _charge_shop(vm, role_i: int, amount: int) -> int:
	if vm.shop_businesses.has(role_i) and int(vm.shop_businesses[role_i].get("vault_gold", 0)) >= amount:
		vm.shop_businesses[role_i]["vault_gold"] = int(vm.shop_businesses[role_i]["vault_gold"]) - amount
		return amount
	var owner = vm.trade_npcs.get(role_i, null)
	if owner != null and is_instance_valid(owner) and not owner.is_dead and int(owner.personal_gold) >= amount:
		owner.personal_gold -= amount
		return amount
	return 0

static func state(vm) -> Dictionary:
	var ns: Dictionary = VillageNeeds.state(vm)
	if not ns.has("underworld") or not (ns["underworld"] is Dictionary):
		ns["underworld"] = {}
	var st: Dictionary = ns["underworld"]
	if not st.has("fence_key"):
		st["fence_key"] = ""
	if not st.has("fence_busted_until"):
		st["fence_busted_until"] = -1
	if not st.has("known_fence"):
		st["known_fence"] = false
	if not st.has("boss"):
		st["boss"] = "fence" # "fence" | "player"
	if not st.has("inventory") or not (st["inventory"] is Dictionary):
		st["inventory"] = {"lockpick": 0, "slow_poison": 0, "sleeping_draught": 0, "dusk_dust": 0}
	if not st.has("active_heist") or not (st["active_heist"] is Dictionary):
		st["active_heist"] = {}
	if not st.has("heists_done"):
		st["heists_done"] = 0
	if not st.has("usury_loans") or not (st["usury_loans"] is Dictionary):
		st["usury_loans"] = {}
	if not st.has("rackets") or not (st["rackets"] is Dictionary):
		st["rackets"] = {}
	if not st.has("hired_jobs") or not (st["hired_jobs"] is Array):
		st["hired_jobs"] = []
	if not st.has("guard_bribed_day"):
		st["guard_bribed_day"] = -1
	if not st.has("last_fight_day"):
		st["last_fight_day"] = -1
	if not st.has("pending_poison") or not (st["pending_poison"] is Dictionary):
		st["pending_poison"] = {} # person_key -> {"name", "die_day"}
	if not st.has("caravan_gold"):
		st["caravan_gold"] = 70
	if not st.has("caravan_busted_day"):
		st["caravan_busted_day"] = -99
	if not st.has("caravan_batches_left"):
		st["caravan_batches_left"] = 2
	if not st.has("pickpockets") or not (st["pickpockets"] is Dictionary):
		st["pickpockets"] = {} # person_key -> {"name", "recruited_day"}
	if not st.has("forged_deed"):
		st["forged_deed"] = false
	if not st.has("last_animal_race_day"):
		st["last_animal_race_day"] = -99
	if not st.has("last_cockfight_day"):
		st["last_cockfight_day"] = -99
	if not st.has("sewers") or not (st["sewers"] is Dictionary):
		st["sewers"] = {"unlocked": false, "current_loc": "", "last_explore_day": -99, "lost_coins_pool": 12, "explored_count": 0, "chest_days": {}}
	var sw_dict: Dictionary = st["sewers"]
	if not sw_dict.has("chest_days") or not (sw_dict["chest_days"] is Dictionary):
		sw_dict["chest_days"] = {}
	return st

## Bloque PN / FIS3: Red de alcantarillas en el nivel vertical -1 con túneles físicos conectados al sur del mapa.
static func sewers_state(vm) -> Dictionary:
	return state(vm)["sewers"]

static func unlock_sewers(vm, npc, inv) -> bool:
	var sw: Dictionary = sewers_state(vm)
	if bool(sw.get("unlocked", false)) or inv == null or int(inv.gold) < SEWER_KEY_COST:
		return false
	inv.add_gold(-SEWER_KEY_COST)
	if npc != null and is_instance_valid(npc):
		npc.personal_gold += SEWER_KEY_COST
	else:
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + SEWER_KEY_COST
	sw["unlocked"] = true
	VillageChronicle.add(vm, "sewers_unlocked", "Obtuviste la llave maestra y el plano de las alcantarillas bajo el pueblo (-%d de oro)" % SEWER_KEY_COST, false)
	return true

## Todo lo que ocupa la red de alcantarillas en el mapa (cámaras, pasillos y la roca de alrededor), ya movida si el
## usuario la movió en el editor. Paso a 3D, paso 2b: ahí el suelo está bajo tierra.
static func zona_alcantarillas() -> Rect2:
	return Rect2(Vector2(420.0, SEWER_Y) - Vector2(360.0, 160.0) + desp_red, Vector2(720.0, 320.0))

static func enter_sewer_location(vm, loc_id: String, player: Node2D = null) -> bool:
	var sw: Dictionary = sewers_state(vm)
	if not bool(sw.get("unlocked", false)) or not SEWER_LOCATIONS.has(loc_id):
		return false
	var pl: Node2D = player if (player != null and is_instance_valid(player)) else VillageNeeds.player_of(vm)
	sw["current_loc"] = loc_id
	if pl != null and is_instance_valid(pl):
		pl.global_position = SEWER_LOCATIONS[loc_id].get("tunnel_pos", SEWER_LOCATIONS[loc_id]["pos"])
	vm.set_player_elevation_level(-1)
	vm._elevation_anchor = Vector2.INF
	sync_sewer_visibility(vm)
	return true

## El nivel -1 lo comparten el sótano de tu casa y las alcantarillas: solo estás en las alcantarillas si entraste por ellas.
static func is_player_in_sewers(vm) -> bool:
	if vm == null or int(vm.player_elevation_level) != -1:
		return false
	return str(sewers_state(vm).get("current_loc", "")) != ""

static func exit_sewers_to_surface(vm) -> void:
	var sw: Dictionary = sewers_state(vm)
	var cur: String = str(sw.get("current_loc", ""))
	sw["current_loc"] = ""
	vm.set_player_elevation_level(0)
	sync_sewer_visibility(vm)
	if SEWER_LOCATIONS.has(cur):
		var pl = VillageNeeds.player_of(vm)
		if pl != null and is_instance_valid(pl):
			pl.global_position = SEWER_LOCATIONS[cur]["pos"]

static func _check_sewer_witness(vm, check_pos: Vector2) -> Dictionary:
	if vm == null or not vm.has_method("_find_conscious_witness_near"):
		return {"witness": null, "is_law": false}
	var wit = vm._find_conscious_witness_near(check_pos, 120.0, null)
	if wit == null:
		return {"witness": null, "is_law": false}
	var is_law: bool = int(wit.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)]
	if not is_law and vm.is_inside_tree():
		var eff_dist: float = 120.0
		if WorldClock and WorldClock.has_method("get_weather_vision_multiplier"):
			eff_dist *= float(WorldClock.call("get_weather_vision_multiplier"))
		var best_d2: float = eff_dist * eff_dist
		var best_law = null
		for n in vm.get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC and int(n.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)]:
				var v: VillageNPC = n as VillageNPC
				if v.is_dead or v.is_downed or v.is_sleeping or v.is_stunned_flag or v.sedated_timer > 0.0:
					continue
				if not vm.are_on_same_elevation(v.elevation_level, vm.player_elevation_level):
					continue
				var d2: float = check_pos.distance_squared_to(v.global_position)
				if d2 <= best_d2 and vm.has_line_of_sight(v.global_position, check_pos):
					best_d2 = d2
					best_law = v
		if best_law != null:
			wit = best_law
			is_law = true
	return {"witness": wit, "is_law": is_law}

static func _apply_sewer_witness(vm, wit_info: Dictionary, player: Node2D = null) -> String:
	var wit = wit_info.get("witness", null)
	if wit == null or not is_instance_valid(wit):
		return ""
	var is_law: bool = bool(wit_info.get("is_law", false))
	var w_name: String = str(wit.npc_name)
	if is_law:
		vm.wanted_level = clampi(int(vm.wanted_level) + 1, 1, 5)
		var msg_law: String = "🚨 ¡%s te vio colarte en las alcantarillas! (Búsqueda +1)" % w_name
		if wit.has_method("_spawn_floating_text"):
			wit._spawn_floating_text(msg_law, Color.ORANGE_RED, -46.0)
		if player != null and is_instance_valid(player) and player.has_method("_spawn_floating_text"):
			player._spawn_floating_text(msg_law, Color.ORANGE_RED, -46.0)
		VillageChronicle.add(vm, "sewer_seen", "¡%s te vio colarte en las alcantarillas! (Búsqueda +1)" % w_name, true)
		return " " + msg_law
	var msg_civ: String = "👀 ¡%s te vio colarte en las alcantarillas!" % w_name
	if wit.has_method("_spawn_floating_text"):
		wit._spawn_floating_text(msg_civ, Color(1.0, 0.82, 0.45), -46.0)
	if player != null and is_instance_valid(player) and player.has_method("_spawn_floating_text"):
		player._spawn_floating_text(msg_civ, Color(1.0, 0.82, 0.45), -46.0)
	if wit.has_method("add_thought"):
		wit.add_thought("Vi al forastero colarse en las alcantarillas (-2)", -2.0)
	if vm.has_method("record_social_event") and wit.has_method("get_person_key"):
		var ev: Dictionary = vm.record_social_event("player_secret", wit, null, "%s vio al forastero colarse en las alcantarillas" % w_name)
		ev["known_by"] = {wit.get_person_key(): true}
		ev["heard_from"] = {}
	return " " + msg_civ

static func interact_sewer_grate(vm, loc_id: String, player: Node2D = null) -> bool:
	if vm == null or not SEWER_LOCATIONS.has(loc_id):
		return false
	var sw: Dictionary = sewers_state(vm)
	if not bool(sw.get("unlocked", false)):
		if player != null and player.has_method("show_hint"):
			player.show_hint("🔒 Cerrada: el perista vende la llave.")
		return false
	var pl: Node2D = player if (player != null and is_instance_valid(player)) else VillageNeeds.player_of(vm)
	var check_pos: Vector2 = pl.global_position if pl != null else (SEWER_LOCATIONS[loc_id]["pos"] as Vector2)
	var wit_info: Dictionary = _check_sewer_witness(vm, check_pos)
	if not enter_sewer_location(vm, loc_id, pl):
		return false
	var wit_suffix: String = _apply_sewer_witness(vm, wit_info, pl)
	var title: String = str(SEWER_LOCATIONS[loc_id].get("title", loc_id))
	if pl != null and pl.has_method("show_hint"):
		pl.show_hint("🕳️🔦 Bajaste por la rejilla a %s (nivel -1).%s" % [title, wit_suffix])
	return true

static func exit_sewer_ladder(vm, loc_id: String, player: Node2D = null) -> bool:
	if vm == null or not SEWER_LOCATIONS.has(loc_id):
		return false
	var pl: Node2D = player if (player != null and is_instance_valid(player)) else VillageNeeds.player_of(vm)
	exit_sewers_to_surface(vm)
	if pl != null and is_instance_valid(pl):
		pl.global_position = SEWER_LOCATIONS[loc_id]["pos"]
	var check_pos: Vector2 = pl.global_position if pl != null else (SEWER_LOCATIONS[loc_id]["pos"] as Vector2)
	var wit_info: Dictionary = _check_sewer_witness(vm, check_pos)
	var seen_by_law: bool = bool(wit_info.get("is_law", false))
	if not seen_by_law and loc_id == "smuggler_tunnel" and int(vm.wanted_level) > 0 and VillageHousing.can_purge_wanted(vm):
		vm.wanted_level = maxi(0, int(vm.wanted_level) - 1)
		VillageHousing.mark_wanted_purge(vm)
		VillageChronicle.add(vm, "smuggler_escape", "Despistaste a la guardia saliendo por el Pasadizo del Contrabandista (-1 de búsqueda)", false)
	var wit_suffix: String = _apply_sewer_witness(vm, wit_info, pl)
	var title: String = str(SEWER_LOCATIONS[loc_id].get("title", loc_id))
	if pl != null and pl.has_method("show_hint"):
		pl.show_hint("🪜☀️ Subiste por la escalerilla a la calle (%s).%s" % [title, wit_suffix])
	return true

static func is_sewer_chest_looted_today(vm, loc_id: String) -> bool:
	if vm == null:
		return false
	var cdays: Dictionary = sewers_state(vm).get("chest_days", {})
	return int(cdays.get(loc_id, -99)) == today()

static func open_sewer_chest(vm, loc_id: String, inv, force_outcome: int = 0) -> Dictionary:
	if vm == null or not SEWER_LOCATIONS.has(loc_id):
		return {"ok": false}
	var sw: Dictionary = sewers_state(vm)
	if not bool(sw.get("unlocked", false)):
		return {"ok": false}
	var cdays: Dictionary = sw["chest_days"]
	if int(cdays.get(loc_id, -99)) == today():
		return {"ok": false, "wait": true}
	cdays[loc_id] = today()
	sw["current_loc"] = loc_id
	var def: Dictionary = SEWER_LOCATIONS[loc_id]
	var title: String = str(def.get("title", loc_id))
	var diff: float = float(def.get("difficulty", 0.30))
	var bonus: float = (0.12 if get_item_count(vm, "lockpick") > 0 else 0.0) + (0.10 if "VillageCulture" in vm and vm.VillageCulture != null and vm.VillageCulture.has_tech(vm, "voltaic_capacitors") else 0.0)
	var chance: float = clampf(0.65 - diff + bonus, 0.25, 0.85)
	var success: bool = (randf() < chance) if force_outcome == 0 else (force_outcome > 0)
	if success:
		var item_id: String = str(def.get("loot_item", "bandit_scrap"))
		if inv != null:
			inv.add_item(item_id, 1)
		var coins: int = mini(6, maxi(0, int(sw.get("lost_coins_pool", 0))))
		if coins > 0 and inv != null:
			sw["lost_coins_pool"] = int(sw.get("lost_coins_pool", 0)) - coins
			inv.add_gold(coins)
		sw["explored_count"] = int(sw.get("explored_count", 0)) + 1
		VillageChronicle.add(vm, "sewer_chest_looted", "Registraste el cofre de contrabando de %s en las alcantarillas y hallaste %s (+%d monedas del pozo)" % [title, item_id, coins], false)
		return {"ok": true, "success": true, "item": item_id, "coins": coins}
	var pl = VillageNeeds.player_of(vm)
	if pl != null:
		var hc = pl.get("health_comp")
		if hc != null and "current_health" in hc:
			hc.current_health = maxf(1.0, float(hc.current_health) - 14.0)
	var ns: Dictionary = VillageNeeds.state(vm)
	ns["player_hygiene"] = clampf(float(ns.get("player_hygiene", 80.0)) - 25.0, 0.0, 100.0)
	VillageChronicle.add(vm, "sewer_mishap", "Sufriste una trampa y aguas negras al abrir el cofre de contrabando en %s" % title, false)
	return {"ok": true, "success": false, "item": "", "coins": 0}

static func interact_sewer_chest(vm, loc_id: String, player: Node2D, inv) -> Dictionary:
	var res: Dictionary = open_sewer_chest(vm, loc_id, inv)
	if player != null and player.has_method("show_hint"):
		if not bool(res.get("ok", false)):
			player.show_hint("🔒 Este cofre de contrabando ya está vacío hoy; vuelve mañana.")
		elif bool(res.get("success", false)):
			player.show_hint("📦🔦 Hallaste 1 %s y +%d monedas en el cofre de contrabando." % [str(res.get("item", "botín")), int(res.get("coins", 0))])
		else:
			player.show_hint("🪤🐀 ¡Agua sucia y trampa en el cofre! Bajó tu salud e higiene.")
	return res

static func build_sewers_world(vm) -> void:
	if vm == null or not ("entities_root" in vm) or not is_instance_valid(vm.entities_root):
		return
	var PropScript = load("res://scripts/obstacles/WorldInteractableProp.gd")
	if PropScript == null:
		return
	if vm.is_inside_tree():
		for grp in ["sewer_station", "sewer_network_2d"]:
			for old_n in vm.get_tree().get_nodes_in_group(grp):
				if is_instance_valid(old_n):
					old_n.queue_free()

	var AN = load("res://mapa/anclas.gd")
	desp_red = load("res://mapa/edificio.gd").desplazamiento("bajo_alcantarillas")
	SEWER_LOCATIONS = SEWER_LOCATIONS_BASE.duplicate(true)
	for k in SEWER_LOCATIONS.keys():
		var dl: Dictionary = SEWER_LOCATIONS[k]
		dl["pos"] = AN.mover(dl["pos"])
		for f in ["chamber_center", "tunnel_pos", "ladder_pos", "chest_pos"]:
			dl[f] = (dl[f] as Vector2) + desp_red

	# 1. Red subterránea de 3 cámaras conectadas por galerías al sur del mapa (x = 205..635, y = 1480..1560)
	var net_root := Node2D.new()
	net_root.name = "SewersNetwork2D"
	net_root.position = desp_red # paredes y suelos con sus números de siempre, desplazados juntos
	net_root.add_to_group("sewer_network_2d")
	vm.entities_root.add_child(net_root)

	var vis_2d := Node2D.new()
	vis_2d.name = "SewersVisual2D"
	vis_2d.z_index = -2
	vis_2d.add_to_group("sewer_visual_2d")
	net_root.add_child(vis_2d)

	var add_rect_2d := func(center: Vector2, sz: Vector2, col: Color) -> void:
		var p := Polygon2D.new()
		var h: Vector2 = sz * 0.5
		p.polygon = PackedVector2Array([
			center + Vector2(-h.x, -h.y),
			center + Vector2(h.x, -h.y),
			center + Vector2(h.x, h.y),
			center + Vector2(-h.x, h.y),
		])
		p.color = col
		vis_2d.add_child(p)

	# Losa oscura subterránea alrededor de las galerías (bajo el centro del pueblo, en y = SEWER_Y)
	add_rect_2d.call(Vector2(420.0, SEWER_Y), Vector2(480.0, 120.0), Color(0.08, 0.10, 0.09, 0.96))
	# Suelos de piedra y canal de aguas turbias de las 3 cámaras
	for loc_id in ["flooded_vault", "smuggler_tunnel", "cistern"]:
		var c: Vector2 = SEWER_LOCATIONS_BASE[loc_id]["chamber_center"]
		add_rect_2d.call(c, Vector2(110.0, 80.0), Color(0.24, 0.28, 0.26))
		add_rect_2d.call(c + Vector2(0.0, -8.0), Vector2(104.0, 52.0), Color(0.32, 0.36, 0.34))
		add_rect_2d.call(c + Vector2(0.0, 26.0), Vector2(106.0, 18.0), Color(0.12, 0.40, 0.32, 0.92))
	# Dos galerías de paso entre las cámaras (x = 315..365 y x = 475..525)
	for corr_x in [340.0, 500.0]:
		add_rect_2d.call(Vector2(corr_x, SEWER_Y), Vector2(54.0, 40.0), Color(0.28, 0.32, 0.30))
		add_rect_2d.call(Vector2(corr_x, SEWER_Y + 14.0), Vector2(54.0, 10.0), Color(0.12, 0.40, 0.32, 0.90))

	# Paredes físicas StaticBody2D que encierran las 3 cámaras y los 2 pasillos conectados
	var walls_body := StaticBody2D.new()
	walls_body.name = "SewerTunnelWallsBody"
	walls_body.collision_layer = 1 if is_player_in_sewers(vm) else 0
	walls_body.collision_mask = 0
	net_root.add_child(walls_body)

	var wall_segments: Array = [
		[Vector2(202.0, SEWER_Y), Vector2(6.0, 86.0)],
		[Vector2(638.0, SEWER_Y), Vector2(6.0, 86.0)],
		[Vector2(260.0, SEWER_Y - 43.0), Vector2(116.0, 6.0)],
		[Vector2(420.0, SEWER_Y - 43.0), Vector2(116.0, 6.0)],
		[Vector2(580.0, SEWER_Y - 43.0), Vector2(116.0, 6.0)],
		[Vector2(260.0, SEWER_Y + 43.0), Vector2(116.0, 6.0)],
		[Vector2(420.0, SEWER_Y + 43.0), Vector2(116.0, 6.0)],
		[Vector2(580.0, SEWER_Y + 43.0), Vector2(116.0, 6.0)],
		[Vector2(340.0, SEWER_Y - 23.0), Vector2(56.0, 6.0)],
		[Vector2(340.0, SEWER_Y + 23.0), Vector2(56.0, 6.0)],
		[Vector2(315.0, SEWER_Y - 32.0), Vector2(6.0, 22.0)],
		[Vector2(315.0, SEWER_Y + 32.0), Vector2(6.0, 22.0)],
		[Vector2(365.0, SEWER_Y - 32.0), Vector2(6.0, 22.0)],
		[Vector2(365.0, SEWER_Y + 32.0), Vector2(6.0, 22.0)],
		[Vector2(500.0, SEWER_Y - 23.0), Vector2(56.0, 6.0)],
		[Vector2(500.0, SEWER_Y + 23.0), Vector2(56.0, 6.0)],
		[Vector2(475.0, SEWER_Y - 32.0), Vector2(6.0, 22.0)],
		[Vector2(475.0, SEWER_Y + 32.0), Vector2(6.0, 22.0)],
		[Vector2(525.0, SEWER_Y - 32.0), Vector2(6.0, 22.0)],
		[Vector2(525.0, SEWER_Y + 32.0), Vector2(6.0, 22.0)],
	]
	for seg in wall_segments:
		var w_pos: Vector2 = seg[0]
		var w_sz: Vector2 = seg[1]
		add_rect_2d.call(w_pos, w_sz, Color(0.16, 0.20, 0.18))
		var col := CollisionShape2D.new()
		var rshape := RectangleShape2D.new()
		rshape.size = w_sz
		col.shape = rshape
		col.position = w_pos
		walls_body.add_child(col)

	# 2. Tres trampillas en la calle + tres escalerillas de salida + tres cofres de contrabando abajo
	for loc_id in SEWER_LOCATIONS.keys():
		var def: Dictionary = SEWER_LOCATIONS[loc_id]
		var title: String = str(def.get("title", loc_id))

		var grate: Node2D = PropScript.new()
		grate.name = "SewerGrate_" + loc_id
		grate.global_position = def["pos"]
		vm.entities_root.add_child(grate)
		grate.setup_prop(vm, "sewer_grate", loc_id, title)

		var ladder: Node2D = PropScript.new()
		ladder.name = "SewerLadder_" + loc_id
		ladder.global_position = def["ladder_pos"]
		vm.entities_root.add_child(ladder)
		ladder.setup_prop(vm, "sewer_ladder", loc_id, title)

		var chest: Node2D = PropScript.new()
		chest.name = "SewerChest_" + loc_id
		chest.global_position = def["chest_pos"]
		vm.entities_root.add_child(chest)
		chest.setup_prop(vm, "sewer_chest", loc_id, title)

	sync_sewer_visibility(vm)

static func sync_sewer_visibility(vm) -> void:
	if vm == null or not ("entities_root" in vm) or not is_instance_valid(vm.entities_root):
		return
	var in_sewers: bool = is_player_in_sewers(vm)
	var use_3d: bool = load("res://scripts/visuals/CharacterAvatar3D.gd").use_3d_characters
	var net_root: Node2D = vm.entities_root.get_node_or_null("SewersNetwork2D") as Node2D
	if is_instance_valid(net_root):
		var vis_2d: Node2D = net_root.get_node_or_null("SewersVisual2D") as Node2D
		if is_instance_valid(vis_2d):
			vis_2d.visible = in_sewers and not use_3d
		var walls_body: StaticBody2D = net_root.get_node_or_null("SewerTunnelWallsBody") as StaticBody2D
		if is_instance_valid(walls_body):
			walls_body.collision_layer = 1 if in_sewers else 0

static func after_load(vm) -> void:
	if vm == null:
		return
	var sw: Dictionary = sewers_state(vm)
	if str(sw.get("current_loc", "")) != "":
		vm.set_player_elevation_level(-1)
		vm._elevation_anchor = Vector2.INF
	sync_sewer_visibility(vm)

static func explore_sewer_location(vm, loc_id: String, inv, force_outcome: int = 0) -> Dictionary:
	var sw: Dictionary = sewers_state(vm)
	if not bool(sw.get("unlocked", false)) or not SEWER_LOCATIONS.has(loc_id):
		return {"ok": false}
	if today() == int(sw.get("last_explore_day", -99)):
		return {"ok": false}
	var pl = VillageNeeds.player_of(vm)
	# La exploración es una salida de ida y vuelta: al terminar vuelves a la calle por la misma rejilla
	# (así nunca te quedas "bajo tierra" en la plaza, donde nadie podría verte robar).
	sw["last_explore_day"] = today()
	var def: Dictionary = SEWER_LOCATIONS[loc_id]
	var title: String = str(def.get("title", loc_id))
	var diff: float = float(def.get("difficulty", 0.30))
	var bonus: float = (0.12 if get_item_count(vm, "lockpick") > 0 else 0.0) + (0.10 if "VillageCulture" in vm and vm.VillageCulture != null and vm.VillageCulture.has_tech(vm, "voltaic_capacitors") else 0.0)
	var chance: float = clampf(0.65 - diff + bonus, 0.25, 0.85)
	var success: bool = (randf() < chance) if force_outcome == 0 else (force_outcome > 0)
	if success:
		var item_id: String = str(def.get("loot_item", "bandit_scrap"))
		if inv != null:
			inv.add_item(item_id, 1)
		var coins: int = mini(6, maxi(0, int(sw.get("lost_coins_pool", 0))))
		if coins > 0 and inv != null:
			sw["lost_coins_pool"] = int(sw.get("lost_coins_pool", 0)) - coins
			inv.add_gold(coins)
		sw["explored_count"] = int(sw.get("explored_count", 0)) + 1
		if loc_id == "smuggler_tunnel" and int(vm.wanted_level) > 0 and VillageHousing.can_purge_wanted(vm):
			vm.wanted_level = maxi(0, int(vm.wanted_level) - 1)
			VillageHousing.mark_wanted_purge(vm)
		VillageChronicle.add(vm, "sewer_explored", "Exploraste %s en las alcantarillas (nivel -1) y hallaste %s (+%d monedas caídas)" % [title, item_id, coins], false)
		return {"ok": true, "success": true, "item": item_id, "coins": coins}
	if pl != null:
		var hc = pl.get("health_comp")
		if hc != null and "current_health" in hc:
			hc.current_health = maxf(1.0, float(hc.current_health) - 14.0)
	var ns: Dictionary = VillageNeeds.state(vm)
	ns["player_hygiene"] = clampf(float(ns.get("player_hygiene", 80.0)) - 25.0, 0.0, 100.0)
	VillageChronicle.add(vm, "sewer_mishap", "Sufriste un percance entre las aguas negras y las ratas al explorar %s" % title, false)
	return {"ok": true, "success": false, "item": "", "coins": 0}

## Bloque PI.2: Carreras de animales (12 de oro) y peleas clandestinas de gallos/perros (15 de oro) contra el bolsillo real del vecino.
static func run_animal_race(vm, npc, inv, force_outcome: int = 0) -> int:
	if inv == null or int(inv.gold) < 12 or npc == null or int(npc.personal_gold) < 12:
		return 0
	var st: Dictionary = state(vm)
	if today() == int(st.get("last_animal_race_day", -99)):
		return 0
	st["last_animal_race_day"] = today()
	var bonus: float = 0.06 * float(VillageHousing.best_adult_animal_power(vm))
	var win_chance: float = clampf(0.45 + bonus, 0.25, 0.78)
	var won: bool = (randf() < win_chance) if force_outcome == 0 else (force_outcome > 0)
	if won:
		return VillageClans.pay_from_pocket(npc, 12, inv)
	inv.add_gold(-12)
	npc.personal_gold += 12
	return -12

static func run_cockfight(vm, npc, inv, force_outcome: int = 0) -> int:
	if inv == null or int(inv.gold) < 15 or npc == null or int(npc.personal_gold) < 15:
		return 0
	var st: Dictionary = state(vm)
	if today() == int(st.get("last_cockfight_day", -99)):
		return 0
	st["last_cockfight_day"] = today()
	var bonus: float = 0.06 * float(VillageHousing.best_adult_animal_power(vm, "rooster"))
	var win_chance: float = clampf(0.45 + bonus, 0.25, 0.78)
	var won: bool = (randf() < win_chance) if force_outcome == 0 else (force_outcome > 0)
	if not is_guard_bribed_tonight(vm) and force_outcome == 0 and randf() < 0.15:
		vm.wanted_level = int(vm.wanted_level) + 1
	if won:
		return VillageClans.pay_from_pocket(npc, 15, inv)
	inv.add_gold(-15)
	npc.personal_gold += 15
	return -15

## Tanda 6 (26): Timba clandestina de dados por 10 de oro contra el bolsillo real del vecino.
static func play_dice_bet(_vm, npc, inv, force_win: int = 0) -> int:
	if inv == null or int(inv.gold) < 10 or npc == null or int(npc.personal_gold) < 10:
		return 0
	var p_roll: int = randi_range(2, 12)
	var n_roll: int = randi_range(2, 12)
	if force_win > 0:
		p_roll = 12
		n_roll = 2
	elif force_win < 0:
		p_roll = 2
		n_roll = 12
	if p_roll >= n_roll:
		return VillageClans.pay_from_pocket(npc, 10, inv)
	inv.add_gold(-10)
	npc.personal_gold += 10
	return -10

## Tanda 6 (27): Tu red de carteristas sisa monedas del bolsillo del vecino más rico y reparte el botín a medias contigo.
static func run_pickpocket_network(vm, inv, catch_chance: float = 0.15) -> int:
	var st: Dictionary = state(vm)
	var pps: Dictionary = st.get("pickpockets", {})
	if pps.is_empty():
		return 0
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var total_player_cut: int = 0
	for pk in pps.keys():
		var pp_npc = by_key.get(str(pk), null)
		if pp_npc == null or not is_instance_valid(pp_npc) or pp_npc.is_dead:
			pps.erase(pk)
			continue
		var target = null
		var best_g: int = 5
		for cand in VillageNeeds.living(vm):
			if cand != pp_npc and not (int(cand.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.CHILD)]) and int(cand.personal_gold) > best_g:
				best_g = int(cand.personal_gold)
				target = cand
		# A veces pillan al carterista: lo detienen, sale de tu red y la guardia sospecha de ti
		if target != null and randf() < catch_chance:
			pps.erase(pk)
			target.modify_npc_relationship(pp_npc, -30, "Me pilló metiéndome la mano en el bolsillo", true)
			vm.wanted_level = int(vm.wanted_level) + 1
			VillageChronicle.add(vm, "pickpocket_caught", "%s pilló a %s robándole y le delató ante la guardia; ahora la guardia te vigila" % [target.npc_name, pp_npc.npc_name], true)
			continue
		if target != null and int(target.personal_gold) >= 6:
			target.personal_gold -= 6
			pp_npc.personal_gold += 3
			if inv != null:
				inv.add_gold(3)
			total_player_cut += 3
	return total_player_cut

static func d_now_ok_challenge(st: Dictionary) -> bool:
	return today() - int(st.get("last_boss_challenge", -99)) >= 7

static func is_caravan_here(st: Dictionary) -> bool:
	return is_night_market_hours() and ((today() - 1) % 3 == 0) and int(st.get("caravan_busted_day", -99)) != today()

static func get_active_smuggler_npc(vm):
	if vm == null or not is_instance_valid(vm) or vm.get_tree() == null:
		return null
	for n in vm.get_tree().get_nodes_in_group("smuggler_caravan_npc"):
		if is_instance_valid(n) and not n.get("is_dead"):
			return n
	return null

static func get_active_smuggler_cart(vm):
	if vm == null or not is_instance_valid(vm) or vm.get_tree() == null:
		return null
	for c in vm.get_tree().get_nodes_in_group("smuggler_caravan_cart"):
		if is_instance_valid(c):
			return c
	return null

static func spawn_smuggler_caravan(vm, at_camp: bool = true):
	if vm == null or not is_instance_valid(vm):
		return null
	var st: Dictionary = state(vm)
	var d_now: int = today()
	if int(st.get("caravan_busted_day", -99)) == d_now:
		return null
	if int(st.get("caravan_refilled_day", -99)) != d_now:
		st["caravan_refilled_day"] = d_now
		st["caravan_gold"] = maxi(70, int(st.get("caravan_gold", 0)))
		st["caravan_batches_left"] = 2
	var existing = get_active_smuggler_npc(vm)
	if existing != null:
		if at_camp:
			existing.global_position = _AN_SITIOS.mover(SMUGGLER_CAMP_POS + Vector2(-24.0, 4.0))
			existing.set_meta("smuggler_state", "camped")
		return existing
	var parent_node: Node = vm.entities_root if ("entities_root" in vm and is_instance_valid(vm.entities_root)) else (vm.get_parent() if vm.get_parent() != null else vm)
	var start_pos: Vector2 = _AN_SITIOS.mover((SMUGGLER_CAMP_POS + Vector2(-24.0, 4.0)) if at_camp else SMUGGLER_BORDER_POS)
	var smuggler := VillageNPC.new()
	smuggler.name = "SmugglerCaravanMerchant"
	smuggler.npc_name = "El Encapuchado"
	smuggler.npc_role = "Contrabandista del Paso"
	smuggler.trade_role = VillageNPC.TradeRole.TRAVELING_MERCHANT
	smuggler.merchant_id = "smuggler"
	smuggler.personal_gold = maxi(70, int(st.get("caravan_gold", 70)))
	smuggler.days_in_role = 7
	smuggler.tavern_social_pos = vm._tavern_social_pos
	parent_node.add_child(smuggler)
	smuggler.setup_npc(vm._load_tex("res://assests/world/village/npcs_64/sprite_casimir.png"), SMUGGLER_CAMP_POS + Vector2(-24.0, 4.0), SMUGGLER_BORDER_POS, {}, vm._tavern_social_pos, "none", "Caravana de Contrabando")
	smuggler.global_position = start_pos
	smuggler.modulate = Color(0.55, 0.52, 0.62)
	smuggler.set_meta("smuggler_state", "camped" if at_camp else "arriving")
	smuggler.add_to_group("smuggler_caravan_npc")
	if get_active_smuggler_cart(vm) == null:
		var cart := SmugglerCampCart.new(vm)
		cart.global_position = _AN_SITIOS.mover(SMUGGLER_CAMP_POS)
		parent_node.add_child(cart)
	return smuggler

static func despawn_smuggler_caravan(vm) -> void:
	if vm == null or not is_instance_valid(vm) or vm.get_tree() == null:
		return
	for c in vm.get_tree().get_nodes_in_group("smuggler_caravan_cart"):
		if is_instance_valid(c):
			if c.get_parent() != null:
				c.get_parent().remove_child(c)
			c.queue_free()
	for n in vm.get_tree().get_nodes_in_group("smuggler_caravan_npc"):
		if is_instance_valid(n) and not n.get("is_dead"):
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			n.queue_free()

static func on_hour(vm, h: int) -> void:
	if vm == null or not is_instance_valid(vm):
		return
	var st: Dictionary = state(vm)
	if h == 4 or int(st.get("caravan_busted_day", -99)) == today():
		var sm = get_active_smuggler_npc(vm)
		if sm != null:
			sm.set_meta("smuggler_state", "leaving")
		despawn_smuggler_caravan(vm)
		return
	if (h >= 22 or h < 4) and ((today() - 1) % 3 == 0) and int(st.get("caravan_busted_day", -99)) != today():
		if get_active_smuggler_npc(vm) == null:
			spawn_smuggler_caravan(vm, true)

static func update_smuggler_merchant_ai(vm, merchant, delta: float) -> void:
	if merchant == null or not is_instance_valid(merchant) or merchant.is_dead or merchant.is_downed:
		return
	var st_mode: String = str(merchant.get_meta("smuggler_state", "camped"))
	var h: int = hour()
	if (h >= 4 and h < 22) or int(state(vm).get("caravan_busted_day", -99)) == today():
		st_mode = "leaving"
		merchant.set_meta("smuggler_state", "leaving")
	if st_mode == "leaving":
		merchant._merchant_leaving = true
		merchant.current_activity = VillageNPC.ActivityState.WORKING
		merchant._move_towards_point(SMUGGLER_BORDER_POS, 68.0, delta)
		if merchant.global_position.distance_to(SMUGGLER_BORDER_POS) < 28.0:
			despawn_smuggler_caravan(vm)
		return
	var camp_spot: Vector2 = _AN_SITIOS.mover(SMUGGLER_CAMP_POS + Vector2(-24.0, 4.0))
	merchant._merchant_leaving = false
	merchant.current_activity = VillageNPC.ActivityState.WORKING
	merchant._move_towards_point(camp_spot, 68.0, delta)
	if merchant.global_position.distance_to(camp_spot) <= 24.0:
		merchant.set_meta("smuggler_state", "camped")
		merchant.velocity = Vector2.ZERO

static func _find_guard_witness_near(vm, pos: Vector2, max_dist: float = 160.0):
	if vm == null or not is_instance_valid(vm) or is_guard_bribed_tonight(vm):
		return null
	for n in VillageNeeds.living(vm):
		if not (int(n.trade_role) in [int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.SHERIFF)]):
			continue
		if n.is_dead or n.is_downed or n.is_sleeping or n.is_stunned_flag or n.sedated_timer > 0.0:
			continue
		if n.global_position.distance_to(pos) >= max_dist:
			continue
		if vm.has_method("has_line_of_sight") and not vm.has_line_of_sight(n.global_position, pos):
			continue
		return n
	return null

static func _check_and_apply_smuggler_guard_witness(vm, pos: Vector2) -> bool:
	var guard_w = _find_guard_witness_near(vm, pos, 160.0)
	if guard_w == null:
		return false
	var st: Dictionary = state(vm)
	vm.wanted_level = int(vm.wanted_level) + 1
	st["caravan_busted_day"] = today()
	VillageChronicle.add(vm, "smuggler_caught_live", "%s te sorprendió in fraganti traficando en el carro de contrabando y la caravana huyó" % guard_w.npc_name, true)
	if guard_w.has_method("_spawn_floating_text"):
		guard_w._spawn_floating_text("🚨 «¡Alto ahí! ¡Contrabando en el claro!»", Color.ORANGE_RED, -46.0)
	despawn_smuggler_caravan(vm)
	return true

static func caravan_buy(vm, inv, require_double_e: bool = true, actor = null) -> bool:
	if vm == null:
		return false
	var st: Dictionary = state(vm)
	var sm = get_active_smuggler_npc(vm)
	var trade_pos: Vector2 = _AN_SITIOS.mover(SMUGGLER_CAMP_POS)
	if actor != null and is_instance_valid(actor) and actor is Node2D:
		trade_pos = (actor as Node2D).global_position
	if inv == null or int(inv.gold) < 25 or not is_caravan_here(st) or int(st.get("caravan_batches_left", 2)) <= 0:
		if sm != null and sm.has_method("_spawn_floating_text"):
			sm._spawn_floating_text("Necesitas 25 de oro y lotes disponibles en el carro", Color.ORANGE_RED, -44.0)
		return false
	if require_double_e and not VillageHousing.press_twice(vm, "caravana_contrabando"):
		return false
	inv.add_gold(-25)
	st["caravan_gold"] = int(st.get("caravan_gold", 0)) + 25
	st["caravan_batches_left"] = int(st.get("caravan_batches_left", 2)) - 1
	add_item(vm, "dusk_dust", 2)
	VillageChronicle.add(vm, "caravan_bought", "Compraste en secreto un lote de «polvo de ocaso» a la caravana de medianoche (-25 Oro)", false)
	if sm != null and sm.has_method("_spawn_floating_text"):
		sm._spawn_floating_text("🐪🌙 «Toma 2 dosis puras sin pasar por aduana.»", Color.GOLD, -46.0)
	_check_and_apply_smuggler_guard_witness(vm, trade_pos)
	return true

static func caravan_sell(vm, inv, actor = null) -> bool:
	if vm == null:
		return false
	var st: Dictionary = state(vm)
	var sm = get_active_smuggler_npc(vm)
	var trade_pos: Vector2 = _AN_SITIOS.mover(SMUGGLER_CAMP_POS)
	if actor != null and is_instance_valid(actor) and actor is Node2D:
		trade_pos = (actor as Node2D).global_position
	if get_item_count(vm, "dusk_dust") <= 0 or int(st.get("caravan_gold", 0)) < 35 or not is_caravan_here(st):
		if sm != null and sm.has_method("_spawn_floating_text"):
			sm._spawn_floating_text("No tienes polvo de ocaso o al carro no le queda oro", Color.ORANGE_RED, -44.0)
		return false
	add_item(vm, "dusk_dust", -1)
	st["caravan_gold"] = int(st.get("caravan_gold", 0)) - 35
	if inv != null:
		inv.add_gold(35)
	VillageChronicle.add(vm, "caravan_sold", "Vendiste mercancía prohibida a la caravana de contrabando de medianoche (+35 Oro)", false)
	if sm != null and sm.has_method("_spawn_floating_text"):
		sm._spawn_floating_text("🐪💰 «35 de oro al contado, sin preguntas.»", Color.GOLD, -46.0)
	_check_and_apply_smuggler_guard_witness(vm, trade_pos)
	return true

static func send_guards_to_bust_caravan(vm, reporting_guard = null) -> int:
	if vm == null or not is_instance_valid(vm):
		return 0
	var chosen: Array = []
	if reporting_guard != null and is_instance_valid(reporting_guard) and not reporting_guard.get("is_dead"):
		if int(reporting_guard.trade_role) in [int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.SHERIFF)]:
			chosen.append(reporting_guard)
	for n in VillageNeeds.living(vm):
		if chosen.size() >= 2:
			break
		if n in chosen:
			continue
		if int(n.trade_role) in [int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.SHERIFF)] and not n.is_downed:
			chosen.append(n)
	for g in chosen:
		g.start_errand("smuggler_bust", _AN_SITIOS.mover(SMUGGLER_CAMP_POS))
	return chosen.size()

static func on_guard_bust_arrived(vm, guard_npc = null) -> void:
	if vm == null:
		return
	var st: Dictionary = state(vm)
	st["caravan_busted_day"] = today()
	st["caravan_gold"] = 0
	if guard_npc != null and is_instance_valid(guard_npc) and guard_npc.has_method("_spawn_floating_text"):
		guard_npc._spawn_floating_text("🚨🐪 «¡Por orden de la guardia, queda desmantelado este campamento!»", Color.SPRING_GREEN, -46.0)
	despawn_smuggler_caravan(vm)

static func today() -> int:
	return int(WorldClock.current_day) if WorldClock else 1

static func hour() -> int:
	return int(WorldClock.current_hour) if WorldClock else 22

static func is_night_market_hours() -> bool:
	var h: int = hour()
	return h >= 21 or h <= 4

static func is_guard_bribed_tonight(vm) -> bool:
	return int(state(vm).get("guard_bribed_day", -1)) == today()

static func get_item_count(vm, item_id: String) -> int:
	var inv_d: Dictionary = state(vm).get("inventory", {})
	return int(inv_d.get(item_id, 0))

static func add_item(vm, item_id: String, delta: int) -> void:
	var st: Dictionary = state(vm)
	var inv_d: Dictionary = st["inventory"]
	inv_d[item_id] = maxi(0, int(inv_d.get(item_id, 0)) + delta)

# ==============================================================================
# P7.1: Perista nocturno tras la taberna
# ==============================================================================
static func get_fence_npc(vm):
	if vm == null:
		return null
	var st: Dictionary = state(vm)
	if int(st.get("fence_busted_until", -1)) > today():
		return null
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var fk: String = str(st.get("fence_key", ""))
	if fk != "" and by_key.has(fk) and not by_key[fk].is_dead:
		return by_key[fk]
	var best = null
	var best_sc: float = -999.0
	for n in VillageNeeds.living(vm):
		if VillageNeeds.is_outsider(n) or int(n.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.PRIEST), int(VillageNPC.TradeRole.DOCTOR), int(VillageNPC.TradeRole.CHILD)]:
			continue
		var sc: float = 1.4 * TraitCatalog.npc_tendency(n, "malice") - TraitCatalog.npc_tendency(n, "honesty")
		if sc > best_sc:
			best_sc = sc
			best = n
	if best != null:
		st["fence_key"] = best.get_person_key()
	return best

static func is_fence(vm, npc) -> bool:
	if vm == null or npc == null:
		return false
	var f = get_fence_npc(vm)
	return f != null and f == npc

# ==============================================================================
# P5b: el perista se deja ver de noche en el callejón y hay rumores para encontrarlo
# ==============================================================================
static func is_fence_alley_hour(h: int) -> bool:
	return h >= FENCE_ALLEY_FROM or h < FENCE_ALLEY_UNTIL

## Cada hora: a las 22:00 el perista va al callejón y se queda hasta las 3:00 (no duerme mientras).
static func fence_on_hour(vm, h: int) -> void:
	if vm == null:
		return
	var f = get_fence_npc(vm)
	if f == null or not is_instance_valid(f) or f.is_dead:
		return
	if is_fence_alley_hour(h):
		if f.errand_kind == "fence_alley" or f.is_incapacitated() or f.is_in_live_fight() or f.is_busy_with_player() or f.is_at_poker_table:
			return
		if f.errand_kind != "" or f.rite_pos != Vector2.ZERO:
			return # otro recado o rito en marcha: esta noche no sale
		f.start_errand("fence_alley", _AN_SITIOS.mover(FENCE_ALLEY_POS))
	elif f.errand_kind == "fence_alley":
		f.end_errand()

static func is_in_alley(npc) -> bool:
	return npc != null and is_instance_valid(npc) and npc.errand_kind == "fence_alley" and npc.global_position.distance_to(_AN_SITIOS.mover(FENCE_ALLEY_POS)) <= 30.0

## Letrero de [E]: en el callejón, quien no lo conoce solo ve una figura encapuchada.
static func alley_interact_label(vm, npc) -> String:
	if vm == null or not is_in_alley(npc) or not is_fence(vm, npc):
		return ""
	if bool(state(vm).get("known_fence", false)):
		return ""
	return "Hablar con la figura encapuchada"

## Rumor sutil al final del saludo (o "" si no toca). Raro: 10 %, 1 por vecino y día, 1 al día en todo el pueblo.
static func tavern_rumor(vm, npc, force: bool = false) -> String:
	if vm == null or npc == null or not is_instance_valid(npc):
		return ""
	var st: Dictionary = state(vm)
	if bool(st.get("known_fence", false)):
		return ""
	var h: int = hour()
	if not force and not (h >= 19 or h < 1):
		return ""
	var pl = VillageNeeds.player_of(vm)
	if pl == null or pl.global_position.distance_to(vm.sitio(vm._tavern_social_pos)) > 140.0:
		return ""
	if is_fence(vm, npc) or int(npc.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.PRIEST), int(VillageNPC.TradeRole.CHILD)]:
		return ""
	if VillageNeeds.is_outsider(npc) or TraitCatalog.npc_tendency(npc, "malice") < FENCE_RUMOR_MALICE:
		return ""
	var d: int = today()
	if int(st.get("fence_rumor_day", -1)) == d:
		return ""
	if not (st.get("fence_rumor_heard", null) is Dictionary):
		st["fence_rumor_heard"] = {}
	var key: String = npc.get_person_key()
	if int((st["fence_rumor_heard"] as Dictionary).get(key, -1)) == d:
		return ""
	st["fence_rumor_heard"][key] = d
	if not force and randf() >= FENCE_RUMOR_CHANCE:
		return ""
	st["fence_rumor_day"] = d
	return FENCE_RUMORS[randi() % FENCE_RUMORS.size()]

# ==============================================================================
# P7.4: Objeto físico visible del robo por encargo y su interacción [E]
# ==============================================================================
static func sync_heist_visuals(vm) -> Node:
	if vm == null:
		return null
	if vm.is_inside_tree():
		for old_h in vm.get_tree().get_nodes_in_group("heist_target_prop"):
			if is_instance_valid(old_h):
				if old_h.get_parent() != null:
					old_h.get_parent().remove_child(old_h)
				old_h.queue_free()
	var ah: Dictionary = state(vm).get("active_heist", {})
	if ah.is_empty() or bool(ah.get("stolen", false)):
		return null
	var PropScript = load("res://scripts/obstacles/WorldInteractableProp.gd")
	if PropScript == null:
		return null
	var h_id: String = str(ah.get("id", "sello_noble"))
	var h_lbl: String = str(ah.get("label", "el objetivo"))
	var tpos := Vector2(float(ah.get("pos_x", 0.0)), float(ah.get("pos_y", 0.0)))
	var prop: Node2D = PropScript.new()
	prop.name = "HeistTargetProp_" + h_id
	prop.global_position = tpos
	var parent: Node = vm.entities_root if ("entities_root" in vm and is_instance_valid(vm.entities_root)) else vm
	parent.add_child(prop)
	prop.setup_prop(vm, "heist_target", h_id, h_lbl)
	return prop

static func try_interact(vm, player: Node2D, pos: Vector2) -> bool:
	var st: Dictionary = state(vm)
	var ah: Dictionary = st.get("active_heist", {})
	if ah.is_empty() or bool(ah.get("stolen", false)):
		return false
	var tpos := Vector2(float(ah.get("pos_x", 0.0)), float(ah.get("pos_y", 0.0)))
	if pos.distance_to(tpos) > 72.0:
		return false
	if not is_night_market_hours() and get_item_count(vm, "lockpick") <= 0:
		if player.has_method("show_hint"):
			player.show_hint("🕵️ Demasiada gente mirando. Vuelve de noche (21:00–04:00) o trae una ganzúa del perista.")
		return true
	var had_pick: bool = get_item_count(vm, "lockpick") > 0
	if had_pick:
		add_item(vm, "lockpick", -1)
	# Alguien despierto puede verte (con sigilo y ganzúa te ven desde menos lejos)
	var in_stealth: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
	var rad: float = (52.0 if in_stealth else 135.0) * (0.6 if had_pick else 1.0)
	var witness = vm._find_conscious_witness_near(player.global_position, rad, null)
	if witness != null:
		vm.wanted_level = int(vm.wanted_level) + 1
		witness.modify_affinity(-20)
		witness._spawn_floating_text("😠 «¡Eh! ¡Deja eso en su sitio!»", Color.ORANGE_RED, -46.0)
		VillageChronicle.add(vm, "heist_seen", "%s te sorprendió intentando llevarte %s" % [witness.npc_name, str(ah.get("label", "algo"))], true)
		if player.has_method("show_hint"):
			player.show_hint("🚨 %s te ha visto. Tendrás que volver en otro momento." % witness.npc_name)
		return true
	ah["stolen"] = true
	st["active_heist"] = ah
	sync_heist_visuals(vm)
	if player.has_method("show_hint"):
		player.show_hint("🕶️💎 Sustrajiste %s en silencio. Llévaselo al perista para cobrar." % str(ah.get("label", "el botín")))
	return true

# ==============================================================================
# Paso diario: P7.6 (protección), P7.7 (trabajos encargados) y P7.10 (jefe del hampa)
# ==============================================================================
static func daily(vm) -> void:
	var st: Dictionary = state(vm)
	var d_now: int = today()
	var pl = VillageNeeds.player_of(vm)
	var inv = pl.get("inventory") if pl != null else null
	var by_key: Dictionary = vm._get_npcs_by_person_key()

	# P7.7: Ejecutar sabotajes o robos encargados al perista
	var jobs: Array = st.get("hired_jobs", [])
	var pending: Array = []
	for j in jobs:
		if not (j is Dictionary):
			continue
		if int(j.get("execute_day", 0)) > d_now:
			pending.append(j)
			continue
		var jtype: String = str(j.get("type", ""))
		if jtype == "sabotage":
			var r_id: int = int(j.get("role_id", int(VillageNPC.TradeRole.BLACKSMITH)))
			if vm.shop_businesses.has(r_id):
				vm.shop_businesses[r_id]["sabotaged_days"] = maxi(2, int(vm.shop_businesses[r_id].get("sabotaged_days", 0)) + 2)
				vm._refresh_shop_stall_visual(r_id)
			var r_title: String = str(j.get("role_title", "el taller"))
			VillageChronicle.add(vm, "hired_sabotage", "Un saboteador a sueldo averió de noche %s mientras tú tenías coartada" % r_title, true)
		elif jtype == "thief":
			var tkey: String = str(j.get("target_key", ""))
			var tnpc = by_key.get(tkey, null)
			var cut: int = 0
			var take: int = 0
			if tnpc != null and not tnpc.is_dead:
				take = mini(30, int(float(tnpc.personal_gold) / 3.0))
				tnpc.personal_gold -= take
				cut = int(round(float(take) * 0.75)) # el resto se lo queda el ratero
			if inv != null:
				inv.add_gold(cut)
			# Regla 1: la parte del ratero (25 %) no se esfuma: se la lleva el perista que lo contrató.
			var rest: int = maxi(0, take - cut)
			var fence_n = by_key.get(str(j.get("fence_key", "")), null)
			if rest > 0:
				if fence_n != null and not fence_n.is_dead:
					fence_n.personal_gold += rest
				else:
					var swp: Dictionary = sewers_state(vm)
					swp["lost_coins_pool"] = int(swp.get("lost_coins_pool", 0)) + rest
			VillageChronicle.add(vm, "hired_theft", "El ratero contratado desvalijó a %s de noche y te entregó tu parte (+%d de oro)" % [str(j.get("target_name", "un vecino")), cut], false)
	st["hired_jobs"] = pending

	# P7.2b: El veneno lento del jugador hace efecto días después (a veces el cuerpo lo aguanta)
	var pp: Dictionary = st.get("pending_poison", {})
	for pk in pp.keys():
		var pinfo: Dictionary = pp[pk]
		if int(pinfo.get("die_day", 0)) > d_now:
			continue
		pp.erase(pk)
		var pv = by_key.get(str(pk), null)
		if pv == null or not is_instance_valid(pv) or pv.is_dead:
			continue
		if randf() < 0.2:
			pv.add_thought("Anoche vomité algo que me sentó fatal; menos mal que lo eché (-5)", -5.0)
			continue
		VillageForensics.state(vm)["poisoned"][pv.npc_name] = {"killer_key": "player", "killer_name": "Jugador", "autopsied": false}
		pv.last_hit_weapon_name = "Fallo súbito (¿veneno lento?)"
		pv.last_hit_by_player = false
		pv._confirm_true_death()

	# Tanda 5 (25): Cada 3 días llega una nueva caravana de contrabando al paso del valle
	if (d_now - 1) % 3 == 0 and int(st.get("caravan_busted_day", -99)) != d_now:
		st["caravan_gold"] = maxi(70, int(st.get("caravan_gold", 0)))
		st["caravan_batches_left"] = 2

	# Bloque PN: Vecinos con el bolsillo lleno pueden extraviar 1 moneda por las rejillas de la plaza hacia la cisterna
	var sw_d: Dictionary = sewers_state(vm)
	if int(sw_d.get("lost_coins_pool", 0)) < 30:
		var dropped: int = 0
		for n_drop in VillageNeeds.living(vm):
			if dropped >= 2:
				break
			if int(n_drop.trade_role) != int(VillageNPC.TradeRole.CHILD) and int(n_drop.personal_gold) >= 22:
				n_drop.personal_gold -= 1
				sw_d["lost_coins_pool"] = int(sw_d.get("lost_coins_pool", 0)) + 1
				dropped += 1

	# Tanda 6 (27): Tu red de carteristas reparte contigo el botín diario
	if inv != null:
		var pp_cut: int = run_pickpocket_network(vm, inv)
		if pp_cut > 0:
			VillageChronicle.add(vm, "pickpocket_cut", "Tu red de carteristas te entregó tu parte del botín diario (+%d de oro)" % pp_cut, false)

	# P7.6 y P7.10 / P5: la «protección» y el tributo del sábado ya no saltan solos a tu mochila:
	# los aparta `VillageCollections.on_saturday` y los recoges en el local o hablando con el perista de noche.

# ==============================================================================
# Diálogos del mercado negro, usura, extorsión y bajos fondos
# ==============================================================================
static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null or npc == null or int(npc.trade_role) == int(VillageNPC.TradeRole.CHILD) or VillageNeeds.is_outsider(npc):
		return
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key()
	var is_law: bool = int(npc.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)]
	var is_priest: bool = int(npc.trade_role) == int(VillageNPC.TradeRole.PRIEST)
	var fence_here: bool = is_fence(vm, npc)
	var opts: Array = []

	# P7.1: Perista nocturno (se activa de noche o siempre que ya lo conozcas)
	if fence_here and (is_night_market_hours() or bool(st.get("known_fence", false))):
		st["known_fence"] = true
		# P5: tributo apartado del Jefe del Hampa; se recoge del perista solo de noche
		var trib_due: int = VillageCollections.pending_total(vm, "tribute")
		if trib_due > 0 and is_night_market_hours():
			opts.append({"label": "💰 Recoger tu tributo (%d de oro)" % trib_due, "next": "END", "action": "underworld_collect_tribute"})
		# P7.2: Catálogo ilegal y venta de mercancía robada
		opts.append({"label": "🗝️ Comprar ganzúa silenciosa (-15 Oro) [Tienes: %d]" % get_item_count(vm, "lockpick"), "next": "END", "action": "underworld_buy:lockpick"})
		opts.append({"label": "🧪 Comprar vial de veneno lento indetectable (-35 Oro) [Tienes: %d]" % get_item_count(vm, "slow_poison"), "next": "END", "action": "underworld_buy:slow_poison"})
		opts.append({"label": "💤 Comprar somnífero pesado (-20 Oro) [Tienes: %d]" % get_item_count(vm, "sleeping_draught"), "next": "END", "action": "underworld_buy:sleeping_draught"})
		if int(vm.wanted_level) > 0:
			opts.append({"label": "📜 Comprar papeles falsos para rebajar tu búsqueda (-30 Oro)", "next": "END", "action": "underworld_buy:false_papers"})
		var hot: String = fenceable_item(VillageNeeds.player_of(vm).get("inventory") if VillageNeeds.player_of(vm) != null else null)
		if hot != "":
			opts.append({"label": "💰 Venderle tu %s (+%d Oro)" % [SimpleInventory.CATALOG.get(hot, {}).get("name", hot), int(FENCE_PRICES[hot])], "next": "END", "action": "underworld_fence_goods"})
		# P7.3: Comprar polvo de ocaso (destilarlo se hace físicamente con [E] en el banco de trabajo de tu casa)
		opts.append({"label": "🌙 Comprar dosis de «polvo de ocaso» (-18 Oro) [Tienes: %d]" % get_item_count(vm, "dusk_dust"), "next": "END", "action": "underworld_buy:dusk_dust"})
		# P7.4: Encargos de robo a medida
		var ah: Dictionary = st.get("active_heist", {})
		if ah.is_empty():
			opts.append({"label": "🕶️💎 Pedir un encargo de robo a medida para un coleccionista", "next": "END", "action": "underworld_take_heist"})
		elif bool(ah.get("stolen", false)):
			opts.append({"label": "💎💰 Entregar %s al perista (+%d Oro)" % [str(ah.get("label", "el botín")), int(ah.get("reward", 55))], "next": "END", "action": "underworld_deliver_heist"})
		# P7.7: Contratar saboteador o ladrón a sueldo
		opts.append({"label": "💣 Contratar un saboteador nocturno contra un taller (-25 Oro)", "next": "END", "action": "underworld_hire_saboteur"})
		opts.append({"label": "🧤 Enviar un ratero a sueldo a desvalijar al vecino más rico (-25 Oro)", "next": "END", "action": "underworld_hire_thief"})
		# P7.8: Club de pelea clandestino
		# P6: ya no va en la charla: el club está en el sótano de la taberna (VillageClub)
		# P7.10b: Destronar al perista y ser Jefe del Hampa
		var rackets_cnt: int = (st.get("rackets", {}) as Dictionary).size()
		if str(st.get("boss", "fence")) != "player" and (int(st.get("heists_done", 0)) + rackets_cnt) >= 2:
			opts.append({"label": "👑🌑 Imponer tu ley y convertirte en el Jefe del Hampa (+12 Oro/semana)", "next": "END", "action": "underworld_takeover_boss"})
		# Bloque P3 Parte B: Comprar y vender con la caravana nocturna se hace físicamente en su carro del claro noreste (SMUGGLER_CAMP_POS).
		# Tanda 6 (28 y 29): Falsificar escritura municipal y retar al jefe de la «Red de las Sombras»
		if not bool(st.get("forged_deed", false)):
			opts.append({"label": "📜🖋️ Encargar una escritura municipal falsificada (-25 Oro -> ahorra 40 al comprar casa o local)", "next": "END", "action": "underworld_forge_deed"})
		if str(st.get("boss", "fence")) != "player" and d_now_ok_challenge(st):
			opts.append({"label": "🗡️👑 Retar cara a cara al jefe de la «Red de las Sombras» por el control del hampa", "next": "END", "action": "underworld_challenge_boss"})

	# Tanda 6 (26): Timbas clandestinas de dados por 10 de oro
	if not is_law and not is_priest and int(npc.personal_gold) >= 10 and (is_night_market_hours() or fence_here or "Tahúr" in (npc.person_profile.personality if npc.person_profile != null else [])):
		opts.append({"label": "🎲🪙 Echar una timba clandestina de dados por 10 de oro", "next": "END", "action": "underworld_dice_bet"})

	# Bloque PI.2: Carreras de animales y peleas de gallos/perros con apuestas (1/día, contra el bolsillo del vecino)
	if not is_law and not is_priest:
		if int(npc.personal_gold) >= 12 and int(st.get("last_animal_race_day", -99)) != today():
			opts.append({"label": "🐕🏁 Apostar 12 de oro en carrera de animales contra %s (1/día)" % npc.npc_name, "next": "END", "action": "underworld_animal_race"})
		if int(npc.personal_gold) >= 15 and int(st.get("last_cockfight_day", -99)) != today() and (is_night_market_hours() or fence_here or int(npc.trade_role) == int(VillageNPC.TradeRole.RANCHER)):
			opts.append({"label": "🐓⚔️ Apostar 15 de oro en pelea clandestina de gallos/perros contra %s (1/día, riesgo de guardia)" % npc.npc_name, "next": "END", "action": "underworld_cockfight"})

	# Tanda 6 (27): Reclutar vecinos sin oficio en tu red de carteristas
	if not is_law and not is_priest and not fence_here and int(npc.trade_role) == int(VillageNPC.TradeRole.UNEMPLOYED) and int(npc.personal_gold) < 25 and not (st.get("pickpockets", {}) as Dictionary).has(key) and (st.get("pickpockets", {}) as Dictionary).size() < 3:
		opts.append({"label": "🧤🪙 Reclutarle en tu red de carteristas (-10 Oro de adelanto -> te dará 3 Oro/día del botín)", "next": "END", "action": "underworld_recruit_pickpocket"})

	# P7.3b: Vender polvo de ocaso a ricos, nobles o adictos
	if get_item_count(vm, "dusk_dust") > 0 and not is_law and not is_priest:
		var add_map: Dictionary = VillageNeeds.state(vm).get("addict", {})
		var wants: bool = VillageNeeds.class_of(npc) == "rico" or int(npc.trade_role) == int(VillageNPC.TradeRole.NOBLE) or float(add_map.get(key, 0.0)) >= 20.0
		if wants and int(npc.personal_gold) >= DUST_PRICE and int((st.get("dust_sold_day", {}) as Dictionary).get(key, -1)) != today():
			opts.append({"label": "🌙💰 Venderle en secreto una dosis de «polvo de ocaso» (+%d Oro)" % DUST_PRICE, "next": "END", "action": "underworld_sell_dust"})

	# P7.2b: Usar veneno lento o somnífero del mercado negro sobre el vecino
	if get_item_count(vm, "slow_poison") > 0 and not fence_here and not is_law and not (st.get("pending_poison", {}) as Dictionary).has(key):
		opts.append({"label": "🧪💀 Deslizar veneno lento indetectable en su bebida", "next": "END", "action": "underworld_use_poison"})
	if get_item_count(vm, "sleeping_draught") > 0 and not fence_here:
		opts.append({"label": "💤🧪 Echar somnífero pesado para dormirlo profundamente", "next": "END", "action": "underworld_use_draught"})

	# P7.5: Ser prestamista usurero del pueblo
	var loans: Dictionary = st.get("usury_loans", {})
	if loans.has(key):
		var ln: Dictionary = loans[key]
		opts.append({"label": "💸👊 Exigir el pago del préstamo usurero con intereses (+%d Oro)" % int(ln.get("amount_due", 35)), "next": "END", "action": "underworld_collect_gold"})
		opts.append({"label": "🤝🗳️ Perdonar los intereses de la deuda a cambio de su voto y deuda de honor", "next": "END", "action": "underworld_collect_favor"})
	elif not is_law and not is_priest and (int(npc.personal_gold) <= 35 or "Tahúr" in (npc.person_profile.personality if npc.person_profile != null else [])):
		opts.append({"label": "💸🪙 Prestarle 25 de oro al 40 %% de interés (-25 Oro -> deberá 35)", "next": "END", "action": "underworld_lend_gold"})

	# P7.6: Extorsión de «protección» semanal a comercios
	if npc.trade_role in VillageNPC.SHOP_ROLES:
		var r_key: String = str(int(npc.trade_role))
		if not (st.get("rackets", {}) as Dictionary).has(r_key):
			opts.append({"label": "👊🏪 Exigir 10 de oro cada sábado por «proteger» su taller", "next": "END", "action": "underworld_demand_protection"})

	# P7.9 y P7.10a: Con la guardia -> sobornar la ronda nocturna o delatar al perista
	if is_law:
		if not is_guard_bribed_tonight(vm):
			opts.append({"label": "🌙🪙 Sobornar la ronda nocturna para que mire a otro lado hoy (-15 Oro)", "next": "END", "action": "underworld_bribe_patrol"})
		var fence = get_fence_npc(vm)
		if fence != null and bool(st.get("known_fence", false)):
			opts.append({"label": "🚨🕵️ Delatar el mercado negro de %s ante la ley (+45 Oro)" % fence.npc_name, "next": "END", "action": "underworld_report_fence"})
		if bool(st.get("known_fence", false)) and is_caravan_here(st) and int(st.get("caravan_gold", 0)) >= 20:
			opts.append({"label": "🚨🐪 Avisar a la guardia de la ruta de la caravana de contrabando", "next": "END", "action": "underworld_caravan_report"})

	# Bloque PN / FIS3: La llave de las alcantarillas se compra al perista; para bajar o subir se usan las rejillas y escalerillas del mundo.
	var sw: Dictionary = sewers_state(vm)
	var is_tinker: bool = int(npc.trade_role) == int(VillageNPC.TradeRole.TINKER)
	if (fence_here or is_tinker) and not bool(sw.get("unlocked", false)):
		opts.append({"label": "🕳️🗝️ Comprar llave maestra y plano de las Alcantarillas del Pueblo (-%d Oro)" % SEWER_KEY_COST, "next": "END", "action": "underworld_unlock_sewers"})

	if not opts.is_empty():
		opts.append({"label": "⬅️ Volver", "next": "start"})
		diag["underworld_menu"] = {"text": "🌑 Mercado negro, usura, extorsión y bajos fondos:", "choices": opts}
		ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🌑 Mercado negro y bajos fondos…", "next": "underworld_menu"})

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key() if npc != null and is_instance_valid(npc) and npc.has_method("get_person_key") else ""
	var d_now: int = today()

	if action_id.begins_with("underworld_buy:"):
		var item: String = action_id.trim_prefix("underworld_buy:")
		var prices: Dictionary = {"lockpick": 15, "slow_poison": 35, "sleeping_draught": 20, "false_papers": 30, "dusk_dust": 18}
		var cost: int = int(prices.get(item, 20))
		if inv == null or int(inv.gold) < cost:
			npc._spawn_floating_text("«Sin oro contante y sonante no hay trato (%d Oro).»" % cost, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-cost)
		npc.personal_gold += cost
		if item == "false_papers":
			vm.wanted_level = maxi(0, int(vm.wanted_level) - 1)
			npc._spawn_floating_text("📜 «Con estos sellos falsos la guardia archivará tus cargos menores.»", Color.SPRING_GREEN, -46.0)
			return
		add_item(vm, item, 1)
		if item == "sleeping_draught":
			inv.add_item("sleeping_draught", 1)
		npc._spawn_floating_text("🕶️ «Guárdalo bajo la capa. Tú y yo no nos hemos visto.» (+1 %s)" % item, Color.GOLD, -46.0)

	elif action_id == "underworld_fence_goods":
		var hot: String = fenceable_item(inv)
		if hot == "":
			return
		var price: int = mini(int(FENCE_PRICES[hot]), int(npc.personal_gold))
		if price < 5:
			npc._spawn_floating_text("«Ahora mismo no tengo con qué pagarte. Vuelve otra noche.»", Color.ORANGE_RED, -44.0)
			return
		inv.remove_item(hot, 1)
		npc.personal_gold -= price
		inv.add_gold(price)
		npc._spawn_floating_text("💰 «Buena mercancía. No preguntaré de dónde salió (+%d Oro).»" % price, Color.GOLD, -46.0)

	elif action_id == "underworld_cook_dust":
		var pl_cook: Node2D = VillageNeeds.player_of(vm) as Node2D
		if inv == null or int(inv.gold) < DUST_COOK_COST or int(st.get("last_cook_day", -1)) == d_now:
			var err_txt: String = "Necesitas %d de oro en reactivos (y solo puedes destilar una vez al día)" % DUST_COOK_COST
			if npc != null and is_instance_valid(npc) and npc.has_method("_spawn_floating_text"):
				npc._spawn_floating_text(err_txt, Color.ORANGE_RED, -44.0)
			elif pl_cook != null and pl_cook.has_method("show_hint"):
				pl_cook.show_hint(err_txt)
			return
		inv.add_gold(-DUST_COOK_COST)
		if npc != null and is_instance_valid(npc) and "personal_gold" in npc:
			npc.personal_gold += DUST_COOK_COST
		else:
			vm.pay_into(get_fence_npc(vm), DUST_COOK_COST) # los reactivos se los compras al perista
		st["last_cook_day"] = d_now
		add_item(vm, "dusk_dust", 2)
		var cook_pos: Vector2 = pl_cook.global_position if pl_cook != null else Vector2.ZERO
		var wit_cook: Node = vm._find_conscious_witness_near(cook_pos, 85.0, null) if pl_cook != null else null
		var partner_k: String = str(VillageHousing.state(vm).get("partner_key", ""))
		if wit_cook != null and wit_cook != get_fence_npc(vm) and (not wit_cook.has_method("get_person_key") or str(wit_cook.call("get_person_key")) != partner_k):
			vm.wanted_level = maxi(int(vm.wanted_level), 1)
			if wit_cook.has_method("modify_affinity"):
				wit_cook.call("modify_affinity", -10)
			VillageChronicle.add(vm, "dust_cook_witnessed", "%s vio cómo destilabas polvo de ocaso y avisó a la guardia" % str(wit_cook.get("npc_name")), true)
		var ok_txt: String = "⚗️🌙 Destilaste 2 dosis puras de «polvo de ocaso» en tu banco de trabajo"
		if npc != null and is_instance_valid(npc) and npc.has_method("_spawn_floating_text"):
			npc._spawn_floating_text(ok_txt, Color(0.85, 0.72, 1.0), -46.0)
		elif pl_cook != null and pl_cook.has_method("show_hint"):
			pl_cook.show_hint(ok_txt)

	elif action_id == "underworld_sell_dust":
		if get_item_count(vm, "dusk_dust") <= 0 or int(npc.personal_gold) < DUST_PRICE:
			return
		add_item(vm, "dusk_dust", -1)
		if inv != null:
			inv.add_gold(DUST_PRICE)
		npc.personal_gold -= DUST_PRICE
		if not st.has("dust_sold_day") or not (st["dust_sold_day"] is Dictionary):
			st["dust_sold_day"] = {}
		st["dust_sold_day"][key] = d_now
		var add_map: Dictionary = VillageNeeds.state(vm)["addict"]
		add_map[key] = clampf(float(add_map.get(key, 0.0)) + 25.0, 0.0, 100.0)
		npc._spawn_floating_text("🌙💰 «Chst... dámelo rápido antes de que pase la ronda (+%d Oro).»" % DUST_PRICE, Color.GOLD, -46.0)

	elif action_id == "underworld_use_poison":
		if get_item_count(vm, "slow_poison") <= 0:
			return
		add_item(vm, "slow_poison", -1)
		# Alguien despierto puede verte echarlo (la víctima no cuenta: no lo nota)
		var pl_node = VillageNeeds.player_of(vm)
		var w_pos: Vector2 = pl_node.global_position if pl_node != null else npc.global_position
		var pw = vm._find_conscious_witness_near(w_pos, 135.0, npc)
		if pw != null:
			vm.wanted_level = int(vm.wanted_level) + 1
			pw.modify_affinity(-30)
			npc.modify_affinity(-40)
			pw._spawn_floating_text("😱 «¡Le ha echado algo en la bebida!»", Color.ORANGE_RED, -46.0)
			npc._spawn_floating_text("«¿Qué me has echado?» (tira la bebida)", Color.ORANGE_RED, -30.0)
			VillageChronicle.add(vm, "poison_seen", "%s te vio echar algo en la bebida de %s" % [pw.npc_name, npc.npc_name], true)
			return
		# Veneno lento: hace efecto la noche siguiente, lejos de ti
		st["pending_poison"][key] = {"name": npc.npc_name, "die_day": d_now + 1}
		npc._spawn_floating_text("🧪 Bebe sin darse cuenta de nada...", Color(0.75, 0.95, 0.65), -46.0)

	elif action_id == "underworld_use_draught":
		if get_item_count(vm, "sleeping_draught") <= 0:
			return
		add_item(vm, "sleeping_draught", -1)
		npc.sedated_timer = 45.0
		npc.is_sleeping = true
		npc._spawn_floating_text("💤 Cae en un sueño profundo por el somnífero", Color.AQUA, -46.0)

	elif action_id == "underworld_take_heist":
		var idx: int = int(st.get("heists_done", 0)) % HEIST_TARGETS.size()
		var t: Dictionary = HEIST_TARGETS[idx]
		var p: Vector2 = t["pos"]
		st["active_heist"] = {"id": str(t["id"]), "label": str(t["label"]), "pos_x": p.x, "pos_y": p.y, "reward": int(t["reward"]), "stolen": false}
		sync_heist_visuals(vm)
		npc._spawn_floating_text("🕶️💎 «Un coleccionista paga 55 de oro por %s. Tráemelo tú: ve allí de noche y que nadie te vea.»" % str(t["label"]), Color.GOLD, -46.0)

	elif action_id == "underworld_deliver_heist":
		var ah2: Dictionary = st.get("active_heist", {})
		if ah2.is_empty() or not bool(ah2.get("stolen", false)):
			return
		var rew: int = int(ah2.get("reward", 55))
		var lbl: String = str(ah2.get("label", "el botín"))
		# Regla 1: el perista paga de su bolsillo; si no le llega, que vuelvas cuando haya vendido algo.
		if int(npc.personal_gold) < rew:
			npc._spawn_floating_text("🕶️💰 «Ahora no tengo %d monedas. Vuelve cuando haya colocado algo de género.»" % rew, Color.ORANGE_RED, -46.0)
			return
		npc.personal_gold -= rew
		st["active_heist"] = {}
		st["heists_done"] = int(st.get("heists_done", 0)) + 1
		sync_heist_visuals(vm)
		if inv != null:
			inv.add_gold(rew)
		VillageChronicle.add(vm, "heist_completed", "Completaste en secreto el robo de %s para el mercado negro (+%d de oro)" % [lbl, rew], false)
		npc._spawn_floating_text("💎💰 «Impecable. Aquí tienes tus %d monedas por %s.»" % [rew, lbl], Color.GOLD, -46.0)

	elif action_id == "underworld_lend_gold":
		if inv == null or int(inv.gold) < 25:
			npc._spawn_floating_text("Necesitas 25 de oro para prestar", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-25)
		npc.personal_gold += 25
		st["usury_loans"][key] = {"npc_name": npc.npc_name, "amount_due": 35, "due_day": d_now + 7}
		npc._spawn_floating_text("💸 «Me salvas el pellejo... te devolveré las 35 monedas o te lo compensaré.»", Color.GOLD, -46.0)

	elif action_id == "underworld_collect_gold":
		if not (st["usury_loans"] as Dictionary).has(key):
			return
		var due: int = int(st["usury_loans"][key].get("amount_due", 35))
		var paid: int = mini(due, int(npc.personal_gold)) # solo puede darte lo que tiene
		npc.personal_gold -= paid
		if inv != null:
			inv.add_gold(paid)
		if paid >= due:
			st["usury_loans"].erase(key)
		else:
			st["usury_loans"][key]["amount_due"] = due - paid
		npc.modify_affinity(-10)
		npc._spawn_floating_text("💸😠 «Toma %d monedas, usurero...%s»" % [paid, "" if paid >= due else " No tengo más."], Color.GOLD, -46.0)

	elif action_id == "underworld_collect_favor":
		st["usury_loans"].erase(key)
		VillageClans.grant_honor_debt(vm, npc, "le perdonó los intereses de una deuda a cambio de lealtad")
		vm.VillageTown.state(vm)["pledges"][key] = "player"
		npc.modify_affinity(14)
		npc._spawn_floating_text("🤝🗳️ «Trato hecho: tienes mi voto, descuentos en mi casa y mi lealtad.»", Color.SPRING_GREEN, -46.0)

	elif action_id == "underworld_collect_tribute":
		var got_t: int = VillageCollections.collect_tribute(vm, npc, inv)
		npc._spawn_floating_text("💰 «Tu parte, jefe: %d monedas.»" % got_t, Color.GOLD, -46.0)

	elif action_id == "underworld_demand_protection":
		var r_key: String = str(int(npc.trade_role))
		st["rackets"][r_key] = {"npc_name": npc.npc_name, "since_day": d_now}
		npc.modify_affinity(-15)
		var first: int = _charge_shop(vm, int(npc.trade_role), RACKET_WEEKLY)
		if inv != null:
			inv.add_gold(first)
		VillageChronicle.add(vm, "protection_racket", "Intimidaste a %s para que te pague «protección» cada sábado" % npc.npc_name, false)
		npc._spawn_floating_text("😰💰 «¡Está bien, no rompas nada! Toma %d de oro hoy y cada sábado...»" % first, Color.GOLD, -46.0)

	elif action_id == "underworld_hire_saboteur":
		if inv == null or int(inv.gold) < 25:
			npc._spawn_floating_text("Necesitas 25 de oro", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-25)
		npc.personal_gold += 25
		var role_id: int = int(VillageNPC.TradeRole.BLACKSMITH)
		var role_title: String = "la Herrería"
		var found_owned: bool = false
		for rk in vm.shop_businesses.keys():
			var o_cand = vm.trade_npcs.get(int(rk), null)
			if o_cand != null and is_instance_valid(o_cand) and not o_cand.is_dead:
				role_id = int(rk)
				role_title = str(vm.shop_businesses[rk].get("title", "el taller"))
				found_owned = true
				break
		if not found_owned:
			for rk in vm.shop_businesses.keys():
				role_id = int(rk)
				role_title = str(vm.shop_businesses[rk].get("title", "el taller"))
				break
		VillageNightJobs.queue(vm, {"type": "sabotage", "role_id": role_id, "role_title": role_title, "paid_by_player": true}) # P6b: alguien va de verdad a la 1:00
		npc._spawn_floating_text("💣 «Esta noche averiaremos %s. Tú tendrás coartada limpia.»" % role_title, Color.GOLD, -46.0)

	elif action_id == "underworld_hire_thief":
		if inv == null or int(inv.gold) < 25:
			npc._spawn_floating_text("Necesitas 25 de oro", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-25)
		npc.personal_gold += 25
		var target = npc
		var best_g: int = -1
		for cand in VillageNeeds.living(vm):
			if cand != npc and int(cand.personal_gold) > best_g:
				best_g = int(cand.personal_gold)
				target = cand
		VillageNightJobs.queue(vm, {"type": "thief", "target_key": target.get_person_key(), "target_name": target.npc_name, "fence_key": npc.get_person_key(), "paid_by_player": true}) # P6b
		npc._spawn_floating_text("🧤 «Conozco las cerraduras de %s. Mañana tendrás tu parte del botín.»" % target.npc_name, Color.GOLD, -46.0)

	elif action_id == "underworld_bet_fight":
		if inv == null or int(inv.gold) < 15:
			npc._spawn_floating_text("Necesitas 15 de oro para apostar", Color.ORANGE_RED, -44.0)
			return
		st["last_fight_day"] = d_now
		inv.add_gold(-15)
		npc.personal_gold += 15
		if randf() < 0.5:
			var win_pay: int = mini(30, maxi(15, int(npc.personal_gold)))
			npc.personal_gold = maxi(0, int(npc.personal_gold) - win_pay)
			inv.add_gold(win_pay)
			npc._spawn_floating_text("🥊💰 ¡Tu púgil ganó en el círculo clandestino! (+%d Oro netos)" % (win_pay - 15), Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("🥊💥 Tu luchador cayó a la lona. Perdiste las 15 monedas.", Color.ORANGE_RED, -46.0)

	elif action_id == "underworld_join_brawl":
		st["last_fight_day"] = d_now
		# Ganas más fácil si estás sano; si pierdes, te llevas la paliza y ni una moneda
		var pl_b = VillageNeeds.player_of(vm)
		var hc = pl_b.get("health_comp") if pl_b != null else null
		var hp_frac: float = clampf(float(hc.current_health) / maxf(1.0, float(hc.max_health)), 0.0, 1.0) if hc != null and "max_health" in hc else 0.6
		if randf() < 0.25 + 0.45 * hp_frac:
			var prize_br: int = mini(35, maxi(0, int(npc.personal_gold)))
			npc.personal_gold = maxi(0, int(npc.personal_gold) - prize_br)
			if inv != null and prize_br > 0:
				inv.add_gold(prize_br)
			npc.modify_affinity(10)
			VillageChronicle.add(vm, "fight_club", "Ganaste la bolsa del club de pelea clandestino de medianoche (+%d de oro)" % prize_br, false)
			npc._spawn_floating_text("🥊🏆 ¡Tumbaste a dos rivales a puño limpio y ganaste la bolsa (+%d Oro)!" % prize_br, Color.GOLD, -46.0)
		else:
			if hc != null:
				hc.current_health = maxf(1.0, float(hc.current_health) - 30.0)
			npc._spawn_floating_text("🥊🩸 Te molieron a golpes en el círculo. Ni una moneda.", Color.ORANGE_RED, -46.0)

	elif action_id == "underworld_bribe_patrol":
		if inv == null or int(inv.gold) < 15:
			npc._spawn_floating_text("Necesitas 15 de oro", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-15)
		npc.personal_gold += 15
		st["guard_bribed_day"] = d_now
		npc._spawn_floating_text("🌙🤫 «Esta noche patrullaré el otro extremo y no veré nada.»", Color.GOLD, -46.0)

	elif action_id == "underworld_report_fence":
		var fence = get_fence_npc(vm)
		var fname: String = fence.npc_name if fence != null else "el perista"
		var seized_f: int = 0
		if fence != null:
			seized_f = mini(45, maxi(0, int(fence.personal_gold)))
			fence.personal_gold -= seized_f
		var tr_rep: int = mini(45 - seized_f, maxi(0, int(vm.town_state.get("treasury", 0))))
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - tr_rep
		var total_rep: int = seized_f + tr_rep
		st["fence_busted_until"] = d_now + 7
		st["fence_key"] = ""
		if inv != null and total_rep > 0:
			inv.add_gold(total_rep)
		npc.modify_affinity(18)
		vm.VillageFaith.add_rep(vm, "law", 12)
		VillageChronicle.add(vm, "fence_busted", "Delataste el mercado negro de %s ante el Alguacil mayor (+%d de oro)" % [fname, total_rep], true)
		npc._spawn_floating_text("🚨⚖️ «¡Conque %s dirigía el contrabando! Toma %d de oro de recompensa.»" % [fname, total_rep], Color.SPRING_GREEN, -46.0)

	elif action_id == "underworld_takeover_boss":
		st["boss"] = "player"
		npc.modify_affinity(15)
		VillageChronicle.add(vm, "underworld_boss", "Te hiciste con el mando de los bajos fondos como nuevo Jefe del Hampa", false)
		npc._spawn_floating_text("👑🌑 «Tú mandas ahora en las sombras. Cada sábado recibirás tu tributo de 12 de oro.»", Color.GOLD, -46.0)

	elif action_id == "underworld_caravan_buy":
		if not caravan_buy(vm, inv, false, npc):
			npc._spawn_floating_text("Necesitas 25 de oro y que la caravana esté acampada esta noche con lotes disponibles", Color.ORANGE_RED, -44.0)
			return
		npc._spawn_floating_text("🐪🌙 «La caravana te entrega 2 dosis puras sin pasar por aduana.»", Color.GOLD, -46.0)

	elif action_id == "underworld_caravan_sell":
		if not caravan_sell(vm, inv, npc):
			return
		npc._spawn_floating_text("🐪💰 «Los mercaderes de la caravana te pagan 35 de oro al contado.»", Color.GOLD, -46.0)

	elif action_id == "underworld_caravan_report":
		var conf: int = maxi(0, int(st.get("caravan_gold", 0)))
		if conf <= 0 or not is_caravan_here(st):
			return
		st["caravan_gold"] = 0
		var rew: int = mini(25, conf)
		if inv != null and rew > 0:
			inv.add_gold(rew)
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + (conf - rew)
		npc.modify_affinity(12)
		vm.VillageFaith.add_rep(vm, "law", 10)
		var sent_guards: int = send_guards_to_bust_caravan(vm, npc)
		if sent_guards <= 0 or get_active_smuggler_npc(vm) == null:
			st["caravan_busted_day"] = d_now
		VillageChronicle.add(vm, "caravan_busted", "Delataste la ruta de la caravana de contrabando; la guardia incautó %d de oro (recompensa +%d Oro)" % [conf, rew], true)
		npc._spawn_floating_text("🚨🐪 «¡Marchamos al claro noreste a emboscar la caravana! Toma %d de oro de adelanto.»" % rew, Color.SPRING_GREEN, -46.0)

	elif action_id == "underworld_dice_bet":
		var net: int = play_dice_bet(vm, npc, inv)
		if net > 0:
			npc._spawn_floating_text("🎲💰 ¡Buenos dados! Le ganaste %d de oro a %s." % [net, npc.npc_name], Color.GOLD, -46.0)
		elif net < 0:
			npc._spawn_floating_text("🎲😠 Mala tirada. %s se embolsa tus 10 monedas." % npc.npc_name, Color.ORANGE_RED, -46.0)
		else:
			npc._spawn_floating_text("Ambos necesitáis al menos 10 de oro en el bolsillo para apostar", Color.ORANGE_RED, -44.0)

	elif action_id == "underworld_recruit_pickpocket":
		if inv == null or int(inv.gold) < 10 or (st.get("pickpockets", {}) as Dictionary).has(key):
			npc._spawn_floating_text("Necesitas 10 de oro de adelanto para reclutarle", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-10)
		npc.personal_gold += 10
		st["pickpockets"][key] = {"name": npc.npc_name, "recruited_day": d_now}
		npc.modify_affinity(10)
		VillageChronicle.add(vm, "pickpocket_recruited", "Reclutaste a %s en tu red de carteristas" % npc.npc_name, false)
		npc._spawn_floating_text("🧤🤫 «Mis dedos son rápidos. Cada día te daré la mitad de lo que sise.»", Color.GOLD, -46.0)

	elif action_id == "underworld_forge_deed":
		if inv == null or int(inv.gold) < 25 or bool(st.get("forged_deed", false)):
			npc._spawn_floating_text("Necesitas 25 de oro para falsificar el sello municipal", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-25)
		npc.personal_gold += 25
		st["forged_deed"] = true
		VillageChronicle.add(vm, "deed_forged", "Encargaste en el mercado negro una escritura con sello municipal falsificado (-25 Oro)", false)
		npc._spawn_floating_text("📜🖋️ «Ni el alcalde distinguirá este lacre. Te ahorrarás 40 monedas en tu próxima compra.»", Color.GOLD, -46.0)

	elif action_id == "underworld_challenge_boss":
		if str(st.get("boss", "fence")) == "player" or not d_now_ok_challenge(st):
			return
		var pl_c = VillageNeeds.player_of(vm)
		var hc_c = pl_c.get("health_comp") if pl_c != null else null
		var hp_ok: bool = hc_c == null or not ("max_health" in hc_c) or float(hc_c.current_health) >= 0.4 * float(hc_c.max_health)
		if not hp_ok:
			npc._spawn_floating_text("🗡️🩸 Estás demasiado malherido para retar al jefe de la Red de las Sombras", Color.ORANGE_RED, -46.0)
			return
		st["last_boss_challenge"] = d_now
		var hp_f: float = clampf(float(hc_c.current_health) / maxf(1.0, float(hc_c.max_health)), 0.0, 1.0) if hc_c != null and "max_health" in hc_c else 0.6
		if randf() >= 0.15 + 0.45 * hp_f:
			if hc_c != null and "max_health" in hc_c:
				hc_c.current_health = maxf(1.0, float(hc_c.current_health) - 40.0)
			npc.modify_affinity(-15)
			VillageChronicle.add(vm, "shadow_boss_lost", "Retaste al jefe de la «Red de las Sombras» y te dejaron tirado en el callejón", false)
			npc._spawn_floating_text("🗡️🩸 Sus matones te dan una paliza. Tendrás que esperar una semana para volver a intentarlo.", Color.ORANGE_RED, -46.0)
			return
		st["boss"] = "player"
		var spoils: int = VillageClans.pay_from_pocket(npc, 25, inv)
		npc.modify_affinity(12)
		VillageChronicle.add(vm, "shadow_boss_defeated", "Derrotaste al jefe de la «Red de las Sombras» y tomaste el mando del hampa (+%d Oro)" % spoils, false)
		npc._spawn_floating_text("🗡️👑 «¡Basta, me rindo! La Red de las Sombras es tuya (+%d Oro y 12/semana).»" % spoils, Color.GOLD, -46.0)

	elif action_id == "underworld_animal_race":
		var race_net: int = run_animal_race(vm, npc, inv)
		if race_net > 0:
			npc._spawn_floating_text("🐕🏁 ¡Tu animal cruzó la meta primero! Le ganaste %d de oro a %s." % [race_net, npc.npc_name], Color.GOLD, -46.0)
		elif race_net < 0:
			npc._spawn_floating_text("🐕💨 El ejemplar de %s fue más veloz. Perdiste 12 de oro." % npc.npc_name, Color.ORANGE_RED, -46.0)
		else:
			npc._spawn_floating_text("Necesitáis al menos 12 de oro cada uno (máx. 1 carrera al día)", Color.ORANGE_RED, -44.0)

	elif action_id == "underworld_cockfight":
		var fight_net: int = run_cockfight(vm, npc, inv)
		if fight_net > 0:
			npc._spawn_floating_text("🐓⚔️ ¡Victoria en el ruedo clandestino! Le ganaste %d de oro a %s." % [fight_net, npc.npc_name], Color.GOLD, -46.0)
		elif fight_net < 0:
			npc._spawn_floating_text("🐓💥 Tu gallo cayó en el ruedo. %s se lleva tus 15 monedas." % npc.npc_name, Color.ORANGE_RED, -46.0)
		else:
			npc._spawn_floating_text("Necesitáis al menos 15 de oro cada uno (máx. 1 pelea al día)", Color.ORANGE_RED, -44.0)

	elif action_id == "underworld_unlock_sewers":
		if unlock_sewers(vm, npc, inv):
			npc._spawn_floating_text("🕳️🗝️ «Con esta llave abrirás las rejillas de la Cisterna, el Pasadizo y la Bóveda (nivel -1).»", Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("Necesitas %d de oro para comprar la llave y el plano de las alcantarillas" % SEWER_KEY_COST, Color.ORANGE_RED, -44.0)

	elif action_id.begins_with("underworld_sewer_explore:"):
		var sloc: String = action_id.trim_prefix("underworld_sewer_explore:")
		var sres: Dictionary = explore_sewer_location(vm, sloc, inv)
		if not bool(sres.get("ok", false)):
			npc._spawn_floating_text("Ya exploraste las alcantarillas hoy o te falta la llave maestra", Color.ORANGE_RED, -44.0)
		elif bool(sres.get("success", false)):
			npc._spawn_floating_text("🕳️🔦 Exploraste el nivel -1 y hallaste 1 %s (+%d monedas caídas)" % [str(sres.get("item", "reliquia")), int(sres.get("coins", 0))], Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("🕳️🐀 Sufriste mordeduras de ratas y aguas negras en las alcantarillas", Color.ORANGE_RED, -46.0)

	elif action_id == "underworld_sewer_surface":
		exit_sewers_to_surface(vm)
		npc._spawn_floating_text("🪜☀️ Subiste por la escalerilla de las alcantarillas a la calle (nivel 0)", Color.SPRING_GREEN, -46.0)
