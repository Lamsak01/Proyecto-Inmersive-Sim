@tool
extends RefCounted

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

const HEIST_TARGETS: Array[Dictionary] = [
	{"id": "sello_noble", "label": "el Sello de Lacre Noble", "pos": Vector2(280.0, -520.0), "reward": 55},
	{"id": "caliz_capilla", "label": "el Cáliz de Plata de la Capilla", "pos": Vector2(745.0, 336.0), "reward": 55},
	{"id": "libro_gremial", "label": "el Libro Mayor de los Gremios", "pos": Vector2(465.0, 24.0), "reward": 55},
]

## Lo que el perista acepta como «mercancía caliente» y cuánto paga (de su bolsillo). Antes daba 25 sin pedir nada.
const FENCE_PRICES: Dictionary = {"royal_safe_conduct": 25, "master_lockpick": 20, "surgical_kit": 18, "golden_egg": 15, "bandit_scrap": 12, "fox_pelt": 10, "steel_ingot": 10, "copper_coil": 9}
const DUST_PRICE: int = 30
const DUST_COOK_COST: int = 25
const RACKET_WEEKLY: int = 10
const BOSS_TRIBUTE: int = 12

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
	if not st.has("pickpockets") or not (st["pickpockets"] is Dictionary):
		st["pickpockets"] = {} # person_key -> {"name", "recruited_day"}
	if not st.has("forged_deed"):
		st["forged_deed"] = false
	return st

## Tanda 6 (26): Timba clandestina de dados por 10 de oro contra el bolsillo real del vecino.
static func play_dice_bet(vm, npc, inv, force_win: int = 0) -> int:
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
# P7.4: Interacción física opcional para robar el objetivo del encargo nocturno
# ==============================================================================
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
			if tnpc != null and not tnpc.is_dead:
				var take: int = mini(30, int(tnpc.personal_gold) / 3)
				tnpc.personal_gold -= take
				cut = int(round(float(take) * 0.75)) # el resto se lo queda el ratero
			if inv != null:
				inv.add_gold(cut)
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

	# Tanda 6 (27): Tu red de carteristas reparte contigo el botín diario
	if inv != null:
		var pp_cut: int = run_pickpocket_network(vm, inv)
		if pp_cut > 0:
			VillageChronicle.add(vm, "pickpocket_cut", "Tu red de carteristas te entregó tu parte del botín diario (+%d de oro)" % pp_cut, false)

	# P7.6 y P7.10: Los sábados (weekday == 5), cobras las extorsiones de protección y tu tributo de Jefe del Hampa
	var is_sat: bool = WorldClock != null and WorldClock.has_method("get_weekday") and int(WorldClock.get_weekday()) == 5
	if is_sat and inv != null:
		var rackets: Dictionary = st.get("rackets", {})
		var racket_total: int = 0
		for rk in rackets.keys():
			var got: int = _charge_shop(vm, int(rk), RACKET_WEEKLY)
			racket_total += got
			var owner = vm.trade_npcs.get(int(rk), null)
			if got == 0 and owner != null and is_instance_valid(owner):
				owner.add_thought("No tengo con qué pagar la «protección»; tengo miedo (-6)", -6.0)
		if racket_total > 0:
			inv.add_gold(racket_total)
			VillageChronicle.add(vm, "racket_paid", "Cobraste %d de oro de «protección» semanal en los comercios" % racket_total, false)
		if str(st.get("boss", "fence")) == "player":
			var fence = get_fence_npc(vm)
			var trib: int = mini(BOSS_TRIBUTE, int(fence.personal_gold)) if fence != null else 0
			if trib > 0:
				fence.personal_gold -= trib
				inv.add_gold(trib)
				VillageChronicle.add(vm, "underworld_tribute", "Como Jefe del Hampa recibiste tu tributo semanal de los bajos fondos (+%d de oro)" % trib, false)

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
		# P7.2: Catálogo ilegal y venta de mercancía robada
		opts.append({"label": "🗝️ Comprar ganzúa silenciosa (-15 Oro) [Tienes: %d]" % get_item_count(vm, "lockpick"), "next": "END", "action": "underworld_buy:lockpick"})
		opts.append({"label": "🧪 Comprar vial de veneno lento indetectable (-35 Oro) [Tienes: %d]" % get_item_count(vm, "slow_poison"), "next": "END", "action": "underworld_buy:slow_poison"})
		opts.append({"label": "💤 Comprar somnífero pesado (-20 Oro) [Tienes: %d]" % get_item_count(vm, "sleeping_draught"), "next": "END", "action": "underworld_buy:sleeping_draught"})
		if int(vm.wanted_level) > 0:
			opts.append({"label": "📜 Comprar papeles falsos para rebajar tu búsqueda (-30 Oro)", "next": "END", "action": "underworld_buy:false_papers"})
		var hot: String = fenceable_item(VillageNeeds.player_of(vm).get("inventory") if VillageNeeds.player_of(vm) != null else null)
		if hot != "":
			opts.append({"label": "💰 Venderle tu %s (+%d Oro)" % [SimpleInventory.CATALOG.get(hot, {}).get("name", hot), int(FENCE_PRICES[hot])], "next": "END", "action": "underworld_fence_goods"})
		# P7.3: Comprar o cocinar polvo de ocaso
		opts.append({"label": "🌙 Comprar dosis de «polvo de ocaso» (-18 Oro) [Tienes: %d]" % get_item_count(vm, "dusk_dust"), "next": "END", "action": "underworld_buy:dusk_dust"})
		if VillageHousing.has_upgrade(vm, "workbench") and int(st.get("last_cook_day", -1)) != today():
			opts.append({"label": "⚗️🌙 Destilar 2 dosis de «polvo de ocaso» con tu banco de trabajo (-%d Oro)" % DUST_COOK_COST, "next": "END", "action": "underworld_cook_dust"})
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
		if int(st.get("last_fight_day", -1)) != today():
			opts.append({"label": "🥊🎲 Apostar 15 de oro en el club de pelea clandestino de medianoche", "next": "END", "action": "underworld_bet_fight"})
			opts.append({"label": "🥊🩸 Entrar tú mismo a pelear a puño limpio por la bolsa (+35 Oro)", "next": "END", "action": "underworld_join_brawl"})
		# P7.10b: Destronar al perista y ser Jefe del Hampa
		var rackets_cnt: int = (st.get("rackets", {}) as Dictionary).size()
		if str(st.get("boss", "fence")) != "player" and (int(st.get("heists_done", 0)) + rackets_cnt) >= 2:
			opts.append({"label": "👑🌑 Imponer tu ley y convertirte en el Jefe del Hampa (+12 Oro/semana)", "next": "END", "action": "underworld_takeover_boss"})
		# Tanda 5 (25): Caravana de contrabando de medianoche
		if int(st.get("caravan_busted_day", -99)) != today():
			opts.append({"label": "🐪🌙 Comprar lote de contrabando a la caravana de medianoche (-25 Oro -> +2 polvo de ocaso)", "next": "END", "action": "underworld_caravan_buy"})
			if get_item_count(vm, "dusk_dust") > 0 and int(st.get("caravan_gold", 0)) >= 35:
				opts.append({"label": "🐪💰 Vender «polvo de ocaso» a la caravana de medianoche (+35 Oro)", "next": "END", "action": "underworld_caravan_sell"})
		# Tanda 6 (28 y 29): Falsificar escritura municipal y retar al jefe de la «Red de las Sombras»
		if not bool(st.get("forged_deed", false)):
			opts.append({"label": "📜🖋️ Encargar una escritura municipal falsificada (-25 Oro -> ahorra 40 al comprar casa o local)", "next": "END", "action": "underworld_forge_deed"})
		if str(st.get("boss", "fence")) != "player" and d_now_ok_challenge(st):
			opts.append({"label": "🗡️👑 Retar cara a cara al jefe de la «Red de las Sombras» por el control del hampa", "next": "END", "action": "underworld_challenge_boss"})

	# Tanda 6 (26): Timbas clandestinas de dados por 10 de oro
	if not is_law and not is_priest and int(npc.personal_gold) >= 10 and (is_night_market_hours() or fence_here or "Tahúr" in (npc.person_profile.personality if npc.person_profile != null else [])):
		opts.append({"label": "🎲🪙 Echar una timba clandestina de dados por 10 de oro", "next": "END", "action": "underworld_dice_bet"})

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
		if bool(st.get("known_fence", false)) and int(st.get("caravan_busted_day", -99)) != today() and int(st.get("caravan_gold", 0)) >= 20:
			opts.append({"label": "🚨🐪 Avisar a la guardia de la ruta de la caravana de contrabando", "next": "END", "action": "underworld_caravan_report"})

	if not opts.is_empty():
		opts.append({"label": "⬅️ Volver", "next": "start"})
		diag["underworld_menu"] = {"text": "🌑 Mercado negro, usura, extorsión y bajos fondos:", "choices": opts}
		ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🌑 Mercado negro y bajos fondos…", "next": "underworld_menu"})

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key()
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
		if inv == null or int(inv.gold) < DUST_COOK_COST or int(st.get("last_cook_day", -1)) == d_now:
			npc._spawn_floating_text("Necesitas %d de oro en reactivos (y solo puedes destilar una vez al día)" % DUST_COOK_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-DUST_COOK_COST)
		npc.personal_gold += DUST_COOK_COST # los reactivos se los compras al perista
		st["last_cook_day"] = d_now
		add_item(vm, "dusk_dust", 2)
		npc._spawn_floating_text("⚗️🌙 Destilaste 2 dosis puras de «polvo de ocaso» en tu banco de trabajo", Color(0.85, 0.72, 1.0), -46.0)

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
		npc._spawn_floating_text("🕶️💎 «Un coleccionista paga 55 de oro por %s. Tráemelo tú: ve allí de noche y que nadie te vea.»" % str(t["label"]), Color.GOLD, -46.0)

	elif action_id == "underworld_deliver_heist":
		var ah2: Dictionary = st.get("active_heist", {})
		if ah2.is_empty() or not bool(ah2.get("stolen", false)):
			return
		var rew: int = int(ah2.get("reward", 55))
		var lbl: String = str(ah2.get("label", "el botín"))
		st["active_heist"] = {}
		st["heists_done"] = int(st.get("heists_done", 0)) + 1
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
		for rk in vm.shop_businesses.keys():
			role_id = int(rk)
			role_title = str(vm.shop_businesses[rk].get("title", "el taller"))
			break
		(st["hired_jobs"] as Array).append({"type": "sabotage", "role_id": role_id, "role_title": role_title, "execute_day": d_now + 1})
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
		(st["hired_jobs"] as Array).append({"type": "thief", "target_key": target.get_person_key(), "target_name": target.npc_name, "execute_day": d_now + 1})
		npc._spawn_floating_text("🧤 «Conozco las cerraduras de %s. Mañana tendrás tu parte del botín.»" % target.npc_name, Color.GOLD, -46.0)

	elif action_id == "underworld_bet_fight":
		if inv == null or int(inv.gold) < 15:
			npc._spawn_floating_text("Necesitas 15 de oro para apostar", Color.ORANGE_RED, -44.0)
			return
		st["last_fight_day"] = d_now
		inv.add_gold(-15)
		if randf() < 0.5:
			inv.add_gold(30)
			npc._spawn_floating_text("🥊💰 ¡Tu púgil ganó en el círculo clandestino! (+15 Oro netos)", Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("🥊💥 Tu luchador cayó a la lona. Perdiste las 15 monedas.", Color.ORANGE_RED, -46.0)

	elif action_id == "underworld_join_brawl":
		st["last_fight_day"] = d_now
		# Ganas más fácil si estás sano; si pierdes, te llevas la paliza y ni una moneda
		var pl_b = VillageNeeds.player_of(vm)
		var hc = pl_b.get("health_comp") if pl_b != null else null
		var hp_frac: float = clampf(float(hc.current_health) / maxf(1.0, float(hc.max_health)), 0.0, 1.0) if hc != null and "max_health" in hc else 0.6
		if randf() < 0.25 + 0.45 * hp_frac:
			if inv != null:
				inv.add_gold(35)
			npc.modify_affinity(10)
			VillageChronicle.add(vm, "fight_club", "Ganaste la bolsa del club de pelea clandestino de medianoche (+35 de oro)", false)
			npc._spawn_floating_text("🥊🏆 ¡Tumbaste a dos rivales a puño limpio y ganaste la bolsa (+35 Oro)!", Color.GOLD, -46.0)
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
		st["fence_busted_until"] = d_now + 7
		st["fence_key"] = ""
		if inv != null:
			inv.add_gold(45)
		npc.modify_affinity(18)
		vm.VillageFaith.add_rep(vm, "law", 12)
		VillageChronicle.add(vm, "fence_busted", "Delataste el mercado negro de %s ante el Comisario (+45 de oro)" % fname, true)
		npc._spawn_floating_text("🚨⚖️ «¡Conque %s dirigía el contrabando! Toma 45 de oro de recompensa.»" % fname, Color.SPRING_GREEN, -46.0)

	elif action_id == "underworld_takeover_boss":
		st["boss"] = "player"
		npc.modify_affinity(15)
		VillageChronicle.add(vm, "underworld_boss", "Te hiciste con el mando de los bajos fondos como nuevo Jefe del Hampa", false)
		npc._spawn_floating_text("👑🌑 «Tú mandas ahora en las sombras. Cada sábado recibirás tu tributo de 12 de oro.»", Color.GOLD, -46.0)

	elif action_id == "underworld_caravan_buy":
		if inv == null or int(inv.gold) < 25 or int(st.get("caravan_busted_day", -99)) == d_now:
			npc._spawn_floating_text("Necesitas 25 de oro para el lote de la caravana", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-25)
		st["caravan_gold"] = int(st.get("caravan_gold", 0)) + 25
		add_item(vm, "dusk_dust", 2)
		VillageChronicle.add(vm, "caravan_bought", "Compraste en secreto un lote de «polvo de ocaso» a la caravana de medianoche (-25 Oro)", false)
		npc._spawn_floating_text("🐪🌙 «La caravana te entrega 2 dosis puras sin pasar por aduana.»", Color.GOLD, -46.0)

	elif action_id == "underworld_caravan_sell":
		if get_item_count(vm, "dusk_dust") <= 0 or int(st.get("caravan_gold", 0)) < 35 or int(st.get("caravan_busted_day", -99)) == d_now:
			return
		add_item(vm, "dusk_dust", -1)
		st["caravan_gold"] = int(st.get("caravan_gold", 0)) - 35
		if inv != null:
			inv.add_gold(35)
		VillageChronicle.add(vm, "caravan_sold", "Vendiste mercancía prohibida a la caravana de contrabando de medianoche (+35 Oro)", false)
		npc._spawn_floating_text("🐪💰 «Los mercaderes de la caravana te pagan 35 de oro al contado.»", Color.GOLD, -46.0)

	elif action_id == "underworld_caravan_report":
		var conf: int = maxi(0, int(st.get("caravan_gold", 0)))
		if conf <= 0 or int(st.get("caravan_busted_day", -99)) == d_now:
			return
		st["caravan_gold"] = 0
		st["caravan_busted_day"] = d_now
		var rew: int = mini(25, conf)
		if inv != null and rew > 0:
			inv.add_gold(rew)
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + (conf - rew)
		npc.modify_affinity(12)
		vm.VillageFaith.add_rep(vm, "law", 10)
		VillageChronicle.add(vm, "caravan_busted", "Delataste la ruta de la caravana de contrabando; la guardia incautó %d de oro (recompensa +%d Oro)" % [conf, rew], true)
		npc._spawn_floating_text("🚨🐪 «¡Emboscamos a la caravana en el paso! Toma %d de oro de lo incautado.»" % rew, Color.SPRING_GREEN, -46.0)

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
