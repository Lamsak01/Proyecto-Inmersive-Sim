@tool
extends RefCounted

## Bloque P6: Casa propia, propiedades y ser terrateniente (10 mecánicas).
## 1) Construir tu casa al contado (100 Oro) o con hipoteca a plazos (15 de entrada + 3/día, con embargo si no pagas).
## 2) Cama propia, lavabo y cofre privado en tu casa (dormir gratis hasta las 6:00 y guardar sin que sea robo).
## 3) Mejoras de interior encargadas al carpintero (estantería, banco de trabajo, cama de roble, cerradura reforzada).
## 4) Invitar a tu pareja a vivir contigo (se muda a tu casa y aporta 5 de oro al día).
## 5) Comprar más casas o casas embargadas y ser casero (los inquilinos te pagan el alquiler cada noche).
## 6) Trato con tus inquilinos (subir el alquiler, perdonar cuotas a cambio de lealtad o desahuciarlos).
## 7) Pequeño huerto o gallinero en tu solar (produce comida fresca cada 2 días).
## 8) Invitar vecinos a cenar a tu casa (sube amistad, reconcilia rivales y sueltan secretos).
## 9) Escondite secreto bajo las tablas del suelo (oro oculto a salvo de robos y multas policiales).
## 10) Ser dueño de locales comerciales (cobras el 15 % semanal de la caja del taller).
## Estado en `vm.lots_state` y `vm.town_state["housing"]` (se guardan automáticamente).

const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const VillageLoans = preload("res://scripts/systems/VillageLoans.gd")
const TraitDiscovery = preload("res://scripts/systems/TraitDiscovery.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

const HOUSE_CASH_COST: int = 100
const FORECLOSED_COST: int = 80
const UPGRADE_COSTS: Dictionary = {"bookshelf": 35, "workbench": 40, "oak_bed": 30, "strong_lock": 25, "hidden_cellar": 45, "hearth": 25, "upper_floor": 50}
const GARDEN_COST: int = 35
const STASH_BUILD_COST: int = 30
const DINNER_COST: int = 10
const COMMERCIAL_DEED_COST: int = 120
const FOUND_SHOP_COST: int = 65
const ADVERTISE_COST: int = 12
const ADVERTISE_COOLDOWN_DAYS: int = 3
const SHOP_SALE_PRICE: int = 10
const CLERK_WAGE: int = 4
const STOCKABLE_ITEMS: Array[String] = ["bread", "cooked_meat", "herbal_poultice", "repair_kit", "clothes", "wood", "iron_ore", "fish", "masterwork_piece"]
const BUY_CHICK_COST: int = 15
const JUVENILE_DAYS: int = 3
const ADULT_ANIMAL_DAYS: int = 6

static func state(vm) -> Dictionary:
	var ts: Dictionary = vm.VillageTown.state(vm)
	if not ts.has("housing") or not (ts["housing"] is Dictionary):
		ts["housing"] = {}
	var hs: Dictionary = ts["housing"]
	if not hs.has("partner_key"):
		hs["partner_key"] = ""
	if not hs.has("stash_gold"):
		hs["stash_gold"] = 0
	if not hs.has("has_stash"):
		hs["has_stash"] = false
	if not hs.has("last_dinner_day"):
		hs["last_dinner_day"] = -99
	if not hs.has("last_party_day"):
		hs["last_party_day"] = -99
	if not hs.has("last_study_day"):
		hs["last_study_day"] = -99
	if not hs.has("commercial_deeds") or not (hs["commercial_deeds"] is Dictionary):
		hs["commercial_deeds"] = {}
	if not hs.has("rent_rates") or not (hs["rent_rates"] is Dictionary):
		hs["rent_rates"] = {}
	if not hs.has("intruder_attempt") or not (hs["intruder_attempt"] is Dictionary):
		hs["intruder_attempt"] = {}
	if not hs.has("player_shop") or not (hs["player_shop"] is Dictionary):
		hs["player_shop"] = {}
	if not hs.has("ranch_herd") or not (hs["ranch_herd"] is Array):
		hs["ranch_herd"] = [
			{"species": "sheep", "stage": "chick", "age_days": 0},
			{"species": "rooster", "stage": "chick", "age_days": 1}
		]
	if not hs.has("player_animals") or not (hs["player_animals"] is Array):
		hs["player_animals"] = []
	return hs

static func today() -> int:
	return int(WorldClock.current_day) if WorldClock else 1

static func player_lots(vm, built_only: bool = true) -> Array[String]:
	var out: Array[String] = []
	for l in VillageLots.LOTS:
		var id: String = str(l["id"])
		var st: Dictionary = VillageLots.lot(vm, id)
		if str(st.get("payer", "")) == "player" and (not built_only or str(st.get("status", "")) == "built"):
			out.append(id)
	return out

static func primary_player_lot(vm) -> String:
	var lots: Array[String] = player_lots(vm, true)
	if not lots.is_empty():
		return lots[0]
	var all_p: Array[String] = player_lots(vm, false)
	return all_p[0] if not all_p.is_empty() else ""

static func has_upgrade(vm, upg: String) -> bool:
	for id in player_lots(vm, true):
		var up: Dictionary = VillageLots.lot(vm, id).get("upgrades", {})
		if bool(up.get(upg, false)):
			return true
	return false

static func is_player_family_chest(vm, fam_id: String) -> bool:
	if not fam_id.begins_with("family_lot_"):
		return false
	var lot_id: String = fam_id.trim_prefix("family_lot_")
	return str(VillageLots.lot(vm, lot_id).get("payer", "")) == "player"

static func tenant_lot_of(vm, npc) -> String:
	if npc == null or not str(npc.lodging).begins_with("house:"):
		return ""
	var lid: String = str(npc.lodging).get_slice(":", 1)
	if str(VillageLots.lot(vm, lid).get("payer", "")) == "player":
		return lid
	return ""

static func rent_for_lot(vm, lot_id: String) -> int:
	var rates: Dictionary = state(vm)["rent_rates"]
	return int(rates.get(lot_id, 3))

## Tanda 5 (22): Precio de reventa de una casa según el atractivo del pueblo y las mejoras instaladas.
static func house_sale_price(vm, lot_id: String) -> int:
	var st: Dictionary = VillageLots.lot(vm, lot_id)
	var attr: float = float(vm.VillageMigration.attractiveness(vm).get("score", 0.0)) if "VillageMigration" in vm and vm.VillageMigration != null else 0.0
	var price: int = 90 + int(round(attr * 30.0))
	var up: Dictionary = st.get("upgrades", {})
	for uk in up.keys():
		if bool(up[uk]):
			price += 15
	if bool(st.get("has_garden", false)):
		price += 20
	return clampi(price, 80, 200)

## Tanda 5 (24): Descansar junto al hogar de leña calienta a quienes viven en tu casa (+10 de humor) y restaura fuerzas.
static func rest_by_hearth(vm, player: Node2D = null) -> bool:
	if not has_upgrade(vm, "hearth"):
		return false
	var p_lot: String = primary_player_lot(vm)
	if p_lot == "":
		return false
	if player != null:
		var hc = player.get("health_comp")
		if hc != null and "max_health" in hc:
			hc.current_health = hc.max_health
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for rk in (VillageLots.lot(vm, p_lot).get("residents", []) as Array):
		var r_npc = by_key.get(str(rk), null)
		if r_npc != null and not r_npc.is_dead:
			r_npc.add_thought("Calor de hogar junto a la chimenea de leña (+10)", 10.0)
	return true

## Bloque PG: Fundar tu propio negocio desde cero en un solar construido tuyo, abastecerlo, contratar dependiente y hacerle publicidad.
static func has_player_shop(vm) -> bool:
	return not (state(vm)["player_shop"] as Dictionary).is_empty()

static func found_player_shop(vm, lot_id: String, inv, carpenter = null) -> bool:
	if lot_id == "" or has_player_shop(vm) or inv == null or int(inv.gold) < FOUND_SHOP_COST:
		return false
	var st: Dictionary = VillageLots.lot(vm, lot_id)
	if str(st.get("payer", "")) != "player" or str(st.get("status", "")) != "built":
		return false
	inv.add_gold(-FOUND_SHOP_COST)
	if carpenter != null and "personal_gold" in carpenter:
		carpenter.personal_gold += FOUND_SHOP_COST
	else:
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + FOUND_SHOP_COST
	state(vm)["player_shop"] = {
		"lot": lot_id,
		"name": "Bazar del Forastero",
		"stock": 2,
		"till_gold": 0,
		"ad_days": 0,
		"last_ad_day": -99,
		"clerk_key": "",
		"total_sales": 0
	}
	VillageChronicle.add(vm, "player_shop_founded", "Acondicionaste un mostrador y fundaste tu propio negocio («Bazar del Forastero») en el solar %s" % lot_id, true)
	return true

static func stock_player_shop(vm, inv) -> int:
	if not has_player_shop(vm) or inv == null:
		return 0
	var ps: Dictionary = state(vm)["player_shop"]
	var added: int = 0
	for item_id in STOCKABLE_ITEMS:
		while added < 2 and inv.has_item(item_id, 1):
			inv.remove_item(item_id, 1)
			added += 1
		if added >= 2:
			break
	if added > 0:
		ps["stock"] = int(ps.get("stock", 0)) + added
	return added

static func advertise_player_shop(vm, inv) -> bool:
	if not has_player_shop(vm) or inv == null or int(inv.gold) < ADVERTISE_COST:
		return false
	var ps: Dictionary = state(vm)["player_shop"]
	if today() - int(ps.get("last_ad_day", -99)) < ADVERTISE_COOLDOWN_DAYS:
		return false
	inv.add_gold(-ADVERTISE_COST)
	vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + ADVERTISE_COST
	ps["ad_days"] = 3
	ps["last_ad_day"] = today()
	VillageChronicle.add(vm, "player_shop_ad", "Repartiste carteles y pregonaste tu negocio por el valle para atraer clientela", true)
	return true

## Bloque PI.1: Animales con etapas de crecimiento (cría -> joven -> adulto) y crianza en el Rancho y en tu corral.
static func animal_stage_for_days(days: int) -> String:
	if days >= ADULT_ANIMAL_DAYS:
		return "adult"
	if days >= JUVENILE_DAYS:
		return "juvenile"
	return "chick"

static func buy_young_animal(vm, species: String, inv, seller = null) -> bool:
	if inv == null or int(inv.gold) < BUY_CHICK_COST:
		return false
	var arr: Array = state(vm)["player_animals"]
	if arr.size() >= 4:
		return false
	inv.add_gold(-BUY_CHICK_COST)
	if seller != null and "personal_gold" in seller:
		seller.personal_gold += BUY_CHICK_COST
	else:
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + BUY_CHICK_COST
	arr.append({"species": species, "stage": "chick", "age_days": 0, "power": 1})
	VillageChronicle.add(vm, "animal_bought", "Compraste una cría (%s) para criarla en tu corral" % species, true)
	return true

static func feed_player_animals(vm, inv) -> int:
	var arr: Array = state(vm)["player_animals"]
	if arr.is_empty() or inv == null:
		return 0
	var used: String = ""
	for food_id in ["wheat", "bread", "carrot"]:
		if inv.has_item(food_id, 1):
			inv.remove_item(food_id, 1)
			used = food_id
			break
	if used == "":
		return 0
	for a in arr:
		if a is Dictionary:
			a["age_days"] = int(a.get("age_days", 0)) + 2
			a["stage"] = animal_stage_for_days(int(a["age_days"]))
			a["power"] = clampi(int(a.get("power", 1)) + 1, 1, 5)
	return arr.size()

static func best_adult_animal_power(vm, species_filter: String = "") -> int:
	var best: int = 0
	for a in (state(vm)["player_animals"] as Array):
		if not (a is Dictionary) or str(a.get("stage", "")) != "adult":
			continue
		if species_filter != "" and str(a.get("species", "")) != species_filter:
			continue
		best = maxi(best, int(a.get("power", 1)))
	return best

# ==============================================================================
# P6.1 y P6.5: Comprar casa al contado, con hipoteca o casa embargada
# ==============================================================================
static func buy_house_cash(vm, lot_id: String, inv) -> bool:
	var has_forged: bool = "VillageUnderworld" in vm and vm.VillageUnderworld != null and bool(vm.VillageUnderworld.state(vm).get("forged_deed", false))
	var cost: int = HOUSE_CASH_COST - (40 if has_forged else 0)
	if inv == null or int(inv.gold) < cost:
		return false
	if str(VillageLots.lot(vm, lot_id).get("status", "")) != "empty" or VillageLots.active_site(vm) != "":
		return false
	if has_forged:
		vm.VillageUnderworld.state(vm)["forged_deed"] = false
		if randf() < 0.30:
			vm.wanted_level = int(vm.wanted_level) + 1
			VillageChronicle.add(vm, "forged_deed_caught", "El ayuntamiento descubrió tu escritura falsificada al comprar el solar %s" % lot_id, true)
			return false
	inv.add_gold(-cost)
	# request_build con payer=null cobra de las arcas, así que ingresamos primero los 100 en las arcas y marcamos payer="player"
	# Con escritura falsa solo entra en las arcas lo que pagas: el resto lo pierde el pueblo (es un fraude, no oro nuevo)
	vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + cost
	var built: String = VillageLots.request_build(vm, lot_id, "house", null, "🏡 Casa del Forastero")
	if built == "":
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - cost
		inv.add_gold(cost)
		if has_forged:
			vm.VillageUnderworld.state(vm)["forged_deed"] = true
		return false
	var st: Dictionary = VillageLots.lot(vm, lot_id)
	st["payer"] = "player"
	st["upgrades"] = {}
	VillageChronicle.add(vm, "player_house_bought", "Encargaste al contado la construcción de tu propia casa en el solar %s" % lot_id, true)
	return true

static func buy_house_loan(vm, lot_id: String, inv) -> bool:
	if inv == null or int(inv.gold) < VillageLoans.DOWN_PAYMENT:
		return false
	if str(VillageLots.lot(vm, lot_id).get("status", "")) != "empty" or VillageLots.active_site(vm) != "":
		return false
	var principal: int = HOUSE_CASH_COST - VillageLoans.DOWN_PAYMENT
	var lender: Dictionary = VillageLoans.find_lender(vm, principal)
	if lender.is_empty():
		return false
	inv.add_gold(-VillageLoans.DOWN_PAYMENT)
	if str(lender["key"]) != "town" and lender.has("npc"):
		lender["npc"].personal_gold -= principal
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + HOUSE_CASH_COST
	else:
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + VillageLoans.DOWN_PAYMENT
	var built: String = VillageLots.request_build(vm, lot_id, "house", null, "🏡 Casa del Forastero")
	if built == "":
		inv.add_gold(VillageLoans.DOWN_PAYMENT)
		return false
	var st: Dictionary = VillageLots.lot(vm, lot_id)
	st["payer"] = "player"
	st["upgrades"] = {}
	var owed: int = int(round(float(principal) * (1.0 + VillageLoans.INTEREST)))
	st["loan"] = {"lender": str(lender["key"]), "lender_name": str(lender["name"]), "owed": owed, "missed": 0, "principal": principal}
	VillageChronicle.add(vm, "player_house_loan", "Encargaste tu casa en el solar %s con una hipoteca de %d de oro a %s" % [lot_id, owed, str(lender["name"])], true)
	return true

# ==============================================================================
# P6.2: Interactuar en el mundo con tu solar o tu cama (`VillageManager.interact`)
# ==============================================================================
## Muda a un vecino a tu casa principal (pareja o hijo adoptivo). Le saca de la lista de su casa anterior,
## para que no viva en dos sitios. `bed_i` elige cama (0 o 1). Devuelve false si no tienes casa.
static func move_into_player_home(vm, npc, bed_i: int) -> bool:
	var p_lot: String = primary_player_lot(vm)
	if p_lot == "" or npc == null:
		return false
	var key: String = npc.get_person_key()
	var old: String = str(npc.lodging)
	if old.begins_with("house:") and old != "house:" + p_lot:
		(VillageLots.lot(vm, old.trim_prefix("house:")).get("residents", []) as Array).erase(key)
	npc.lodging = "house:" + p_lot
	var beds: Array = VillageLots._house_beds(p_lot)
	if not beds.is_empty():
		npc.bed_position = beds[clampi(bed_i, 0, beds.size() - 1)]
	npc.home_table_pos = VillageLots.lot_def(p_lot)["center"] + Vector2(0, -2)
	VillageLots.add_resident(vm, p_lot, key)
	return true

## Confirmación sencilla: la primera E avisa; una segunda E en 4 s sobre lo mismo confirma.
static func press_twice(vm, tag: String) -> bool:
	var now: int = Time.get_ticks_msec()
	if str(vm.get_meta("e_confirm_tag", "")) == tag and now - int(vm.get_meta("e_confirm_ms", 0)) <= 4000:
		vm.set_meta("e_confirm_tag", "")
		return true
	vm.set_meta("e_confirm_tag", tag)
	vm.set_meta("e_confirm_ms", now)
	return false

static func try_interact(vm, player: Node2D, pos: Vector2) -> bool:
	var inv = player.get("inventory") if player != null else null
	for l in VillageLots.LOTS:
		var id: String = str(l["id"])
		var st: Dictionary = VillageLots.lot(vm, id)
		# 1. Cartel de solar libre de vivienda: encargar casa si tienes oro
		if str(st.get("status", "")) == "empty" and str(l.get("zone", "")) == "borde" and pos.distance_to(VillageLots.site_work_pos(id)) <= 32.0:
			if VillageLots.active_site(vm) != "":
				if player.has_method("show_hint"):
					player.show_hint("🚧 El carpintero ya está ocupado en otra obra. Espera a que termine.")
				return true
			var can_cash: bool = inv != null and int(inv.gold) >= HOUSE_CASH_COST
			var can_loan: bool = inv != null and int(inv.gold) >= VillageLoans.DOWN_PAYMENT
			if (can_cash or can_loan) and not press_twice(vm, "buy_lot:" + id):
				if player.has_method("show_hint"):
					var how: String = "al contado (-%d Oro)" % HOUSE_CASH_COST if can_cash else "con hipoteca (-%d Oro de entrada y 3 Oro/día)" % VillageLoans.DOWN_PAYMENT
					player.show_hint("🏡❓ ¿Comprar el solar %s %s? Pulsa E otra vez para confirmar." % [id, how])
				return true
			if can_cash and buy_house_cash(vm, id, inv):
				if player.has_method("show_hint"):
					player.show_hint("🏡🔨 Compraste el solar %s al contado (-100 Oro). El carpintero vendrá a levantar tu casa." % id)
				return true
			elif can_loan and buy_house_loan(vm, id, inv):
				if player.has_method("show_hint"):
					player.show_hint("🏦🏡 Encargaste tu casa en el solar %s con hipoteca (-15 Oro de entrada, 3 Oro/día)." % id)
				return true
		# 2. Dentro de una casa construida tuya: dormir en tu cama o estudiar en tu estantería
		if str(st.get("status", "")) == "built" and str(st.get("payer", "")) == "player":
			var c: Vector2 = l["center"]
			if pos.distance_to(c) <= 46.0:
				var hs: Dictionary = state(vm)
				var up: Dictionary = st.get("upgrades", {})
				# Dormir en tu cama es como la de la posada pero gratis: el tiempo pasa hasta la mañana
				var h_now: int = int(WorldClock.current_hour) if WorldClock != null else 22
				if h_now >= 6 and h_now < 20:
					if player.has_method("show_hint"):
						player.show_hint("🛏️ Aún es de día. Tu cama te espera a partir de las 20:00.")
					return true
				if bool(up.get("bookshelf", false)) and int(hs.get("last_study_day", -99)) != today():
					hs["last_study_day"] = today()
					if player.has_method("add_skill_xp"):
						player.call("add_skill_xp", "crafting", 15)
				var hearth_ok: bool = rest_by_hearth(vm, player)
				var surv = player.get_node_or_null("SurvivalComponent")
				if surv != null:
					if surv.has_method("restore_sleep"):
						surv.restore_sleep(100.0)
					surv.current_hygiene = 100.0
				var stam = player.get_node_or_null("StaminaComponent")
				if stam != null:
					stam.current_stamina = stam.max_stamina
					stam.stamina_changed.emit(stam.current_stamina, stam.max_stamina)
				if WorldClock != null and WorldClock.has_method("sleep_until_morning"):
					WorldClock.sleep_until_morning()
				if player.has_method("show_hint"):
					var bonus_txt: String = " (+estudio en tu estantería)" if bool(up.get("bookshelf", false)) else ""
					if hearth_ok:
						bonus_txt += " (+calor del hogar)"
					player.show_hint("🛌🏡 Dormiste en tu propia casa hasta la mañana%s." % bonus_txt)
				return true
	return false

# ==============================================================================
# Paso diario: pareja en casa, huerto, banco de trabajo y rentas comerciales
# ==============================================================================
static func daily(vm) -> void:
	var hs: Dictionary = state(vm)
	var pl = VillageNeeds.player_of(vm)
	var inv = pl.get("inventory") if pl != null else null
	var p_lots: Array[String] = player_lots(vm, true)
	if not p_lots.is_empty() and inv != null:
		# P6.4: Tu pareja que vive contigo aporta 5 de oro al día al hogar
		var pk: String = str(hs.get("partner_key", ""))
		if pk != "":
			var partner = vm._get_npcs_by_person_key().get(pk, null)
			if partner != null and not partner.is_dead and int(partner.personal_gold) >= 12:
				partner.personal_gold -= 5
				inv.add_gold(5)
		# P6.3 y P6.7:Cada 2 días, tu huerto da comida y tu banco de trabajo da un kit o cataplasma
		if today() % 2 == 0:
			for lid in p_lots:
				var st: Dictionary = VillageLots.lot(vm, lid)
				if bool(st.get("has_garden", false)):
					inv.add_item("bread", 1)
				var up: Dictionary = st.get("upgrades", {})
				if bool(up.get("workbench", false)):
					inv.add_item("herbal_poultice", 1)
		# Tanda 5 (21): Intrusos nocturnos o enemigos intentando forzar tu puerta si no tienes cerradura reforzada
		# Un intruso sin escarmentar en 2 días se lleva algo del escondite y deja sitio a otro
		var ia_old: Dictionary = hs["intruder_attempt"]
		if not ia_old.is_empty() and (bool(ia_old.get("repelled", false)) or today() - int(ia_old.get("day", today())) >= 2):
			if not bool(ia_old.get("repelled", false)):
				var stolen: int = mini(10, int(hs.get("stash_gold", 0)))
				hs["stash_gold"] = int(hs.get("stash_gold", 0)) - stolen
				var thief_n = vm._get_npcs_by_person_key().get(str(ia_old.get("intruder_key", "")), null)
				if thief_n != null and not thief_n.is_dead:
					thief_n.personal_gold += stolen
				VillageChronicle.add(vm, "intruder_stole", "Alguien forzó tu puerta de noche%s" % (" y se llevó %d de oro de tu escondite" % stolen if stolen > 0 else ""), false)
			hs["intruder_attempt"] = {}
		if (hs["intruder_attempt"] as Dictionary).is_empty() and not has_upgrade(vm, "strong_lock") and randf() < 0.20:
			for n in VillageNeeds.living(vm):
				if int(n.trade_role) != int(VillageNPC.TradeRole.CHILD) and (int(n.affinity) <= -35 or TraitCatalog.npc_tendency(n, "malice") >= 0.4):
					hs["intruder_attempt"] = {"intruder_key": n.get_person_key(), "intruder_name": n.npc_name, "day": today(), "repelled": false}
					VillageChronicle.add(vm, "intruder_try", "Anoche alguien intentó forzar la puerta de tu casa; quien fuera te guarda rencor", false)
					break
	# P6.10: Los sábados, los locales comerciales tuyos te pagan el 15 % de su caja
	if inv != null and WorldClock != null and WorldClock.has_method("get_weekday") and int(WorldClock.get_weekday()) == 5:
		var deeds: Dictionary = hs.get("commercial_deeds", {})
		for r_key in deeds.keys():
			var role_i: int = int(r_key)
			if vm.shop_businesses.has(role_i):
				var vault: int = int(vm.shop_businesses[role_i].get("vault_gold", 0))
				var cut: int = int(round(float(vault) * 0.15)) # solo lo que hay en la caja
				if cut > 0:
					vm.shop_businesses[role_i]["vault_gold"] = vault - cut
					inv.add_gold(cut)
	# Bloque PG: Tu propio negocio vende mercancía del mostrador a vecinos con oro y paga al dependiente
	if has_player_shop(vm):
		var ps: Dictionary = hs["player_shop"]
		var ck: String = str(ps.get("clerk_key", ""))
		var max_buyers: int = 1 + (1 if ck != "" else 0) + (2 if int(ps.get("ad_days", 0)) > 0 else 0)
		if int(ps.get("ad_days", 0)) > 0:
			ps["ad_days"] = maxi(0, int(ps["ad_days"]) - 1)
		for n in VillageNeeds.living(vm):
			if max_buyers <= 0 or int(ps.get("stock", 0)) <= 0:
				break
			if int(n.trade_role) == int(VillageNPC.TradeRole.CHILD) or VillageNeeds.is_outsider(n) or n.get_person_key() == ck:
				continue
			if int(n.personal_gold) >= 18:
				n.personal_gold -= SHOP_SALE_PRICE
				ps["till_gold"] = int(ps.get("till_gold", 0)) + SHOP_SALE_PRICE
				ps["stock"] = int(ps.get("stock", 0)) - 1
				ps["total_sales"] = int(ps.get("total_sales", 0)) + 1
				n.modify_affinity(2)
				n.add_thought("Compré buena mercancía en el Bazar del Forastero (+3)", 3.0)
				max_buyers -= 1
		if ck != "":
			var clerk = vm._get_npcs_by_person_key().get(ck, null)
			if clerk == null or clerk.is_dead:
				ps["clerk_key"] = ""
			elif int(ps.get("till_gold", 0)) >= CLERK_WAGE:
				ps["till_gold"] = int(ps["till_gold"]) - CLERK_WAGE
				clerk.personal_gold += CLERK_WAGE
	# Bloque PI.1: Crecimiento diario del ganado del Rancho y de tus propios animales de corral
	var r_herd: Array = hs["ranch_herd"]
	var new_r_chicks: Array = []
	var rancher = vm.trade_npcs.get(int(VillageNPC.TradeRole.RANCHER), null) if "trade_npcs" in vm else null
	for ra in r_herd:
		if not (ra is Dictionary):
			continue
		var old_st: String = str(ra.get("stage", "chick"))
		ra["age_days"] = int(ra.get("age_days", 0)) + 1
		ra["stage"] = animal_stage_for_days(int(ra["age_days"]))
		if old_st != "adult" and str(ra["stage"]) == "adult":
			if rancher != null and is_instance_valid(rancher) and not rancher.is_dead:
				rancher.shop_stock["wool"] = int(rancher.shop_stock.get("wool", 0)) + 1
				rancher.shop_stock["raw_meat"] = int(rancher.shop_stock.get("raw_meat", 0)) + 1
				rancher._sync_shop_stock_to_vm()
			if r_herd.size() + new_r_chicks.size() < 4:
				new_r_chicks.append({"species": str(ra.get("species", "sheep")), "stage": "chick", "age_days": 0})
	for nc in new_r_chicks:
		r_herd.append(nc)
	var p_animals: Array = hs["player_animals"]
	var adult_p_cnt: int = 0
	for pa in p_animals:
		if not (pa is Dictionary):
			continue
		pa["age_days"] = int(pa.get("age_days", 0)) + 1
		pa["stage"] = animal_stage_for_days(int(pa["age_days"]))
		if str(pa["stage"]) == "adult":
			adult_p_cnt += 1
	if adult_p_cnt > 0 and inv != null and today() % 2 == 0:
		inv.add_item("cooked_meat", 1)
	if adult_p_cnt >= 2 and p_animals.size() < 4 and today() % 4 == 0:
		p_animals.append({"species": "rooster", "stage": "chick", "age_days": 0, "power": 1})
		VillageChronicle.add(vm, "animal_bred", "Ha nacido una nueva cría en tu corral", true)

# ==============================================================================
# Diálogos con el carpintero, pareja, inquilinos y vecinos
# ==============================================================================
static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null or npc == null or int(npc.trade_role) == int(VillageNPC.TradeRole.CHILD):
		return
	var hs: Dictionary = state(vm)
	var opts: Array = []
	var free: Array = VillageLots.free_lots(vm, "house")
	var p_lot: String = primary_player_lot(vm)
	var is_carp: bool = int(npc.trade_role) == int(VillageNPC.TradeRole.CARPENTER)

	# Con el carpintero: comprar solar, mejoras, huerto, escondite o casas embargadas
	if is_carp:
		if not free.is_empty() and VillageLots.active_site(vm) == "":
			var lid: String = str(free[0])
			opts.append({"label": "🏡💰 Encargar casa propia en el solar %s al contado (-%d Oro)" % [lid, HOUSE_CASH_COST], "next": "END", "action": "housing_buy_cash:" + lid})
			opts.append({"label": "🏦🏡 Encargar casa en el solar %s con hipoteca (-15 Oro entrada, 3/día)" % lid, "next": "END", "action": "housing_buy_loan:" + lid})
		if p_lot != "" and str(VillageLots.lot(vm, p_lot).get("status", "")) == "built":
			var st: Dictionary = VillageLots.lot(vm, p_lot)
			var up: Dictionary = st.get("upgrades", {})
			for u in [["bookshelf", "📚 Estantería de estudio (+XP diaria)"], ["workbench", "⚗️ Banco de trabajo y alquimia"], ["oak_bed", "🛏️ Cama de roble macizo"], ["strong_lock", "🔒 Cerradura reforzada antirrobo"], ["hidden_cellar", "🕳️🕯️ Sótano secreto para esconderte o destilar"], ["hearth", "🔥🪵 Hogar de leña caldeado (+salud y humor)"], ["upper_floor", "🪜🏠 Altillo / Primer Piso con escalera (nivel +1)"]]:
				if not bool(up.get(u[0], false)):
					opts.append({"label": "%s (-%d Oro)" % [u[1], int(UPGRADE_COSTS[u[0]])], "next": "END", "action": "housing_upgrade:" + u[0]})
			if not bool(st.get("has_garden", false)):
				opts.append({"label": "🌱🐔 Montar huerto y gallinero en tu solar (-%d Oro)" % GARDEN_COST, "next": "END", "action": "housing_garden:" + p_lot})
			if not bool(hs.get("has_stash", false)):
				opts.append({"label": "🪵🗝️ Construir escondite secreto bajo las tablas (-%d Oro)" % STASH_BUILD_COST, "next": "END", "action": "housing_build_stash"})
			if not has_player_shop(vm):
				opts.append({"label": "🏪🔨 Acondicionar mostrador y fundar tu propio negocio en el solar %s (-%d Oro)" % [p_lot, FOUND_SHOP_COST], "next": "END", "action": "housing_found_shop:" + p_lot})
		# P6.5: Comprar una casa embargada al pueblo o al noble para alquilarla
		for l in VillageLots.LOTS:
			var id2: String = str(l["id"])
			var st2: Dictionary = VillageLots.lot(vm, id2)
			if str(st2.get("status", "")) == "built" and str(st2.get("kind", "")) == "house" and str(st2.get("payer", "")) in ["town", npc.get_person_key()]:
				opts.append({"label": "🏘️🔑 Comprar la casa del solar %s para alquilarla (-%d Oro)" % [id2, FORECLOSED_COST], "next": "END", "action": "housing_buy_foreclosed:" + id2})
				break

	# Tanda 5 (21): Defender tu puerta y escarmentar a un intruso nocturno
	# Solo hablando con el propio intruso (lo descubres al ver tu puerta forzada y preguntar por ahí)
	if not (hs["intruder_attempt"] as Dictionary).is_empty() and not bool(hs["intruder_attempt"].get("repelled", false)) and str(hs["intruder_attempt"].get("intruder_key", "")) == npc.get_person_key():
		opts.append({"label": "🚪🛡️ Plantarle cara por intentar forzar tu puerta anoche (hasta 15 Oro)", "next": "END", "action": "housing_repel_intruder"})

	# Tanda 5 (22): Vender una casa tuya reformada al precio del barrio y sus mejoras
	if is_carp or vm.VillageTown.is_mayor(vm, npc):
		for lid3 in player_lots(vm, true):
			opts.append({"label": "🏘️📈 Vender tu casa del solar %s (+%d Oro según atractivo y mejoras)" % [lid3, house_sale_price(vm, lid3)], "next": "END", "action": "housing_sell_house:" + lid3})

	# Tanda 5 (23): Esconderte en tu sótano secreto si te buscan por un delito menor
	if has_upgrade(vm, "hidden_cellar") and int(vm.wanted_level) == 1 and int(vm.player_murder_warrants_count) == 0 and today() - int(hs.get("last_hide_day", -99)) >= 7:
		opts.append({"label": "🕳️🤫 Esconderte en tu sótano secreto hasta que pase la búsqueda", "next": "END", "action": "housing_hide_cellar"})
	# Bloque PN: Subir al primer piso o bajar al sótano en tu casa (sistema de niveles verticales por capas)
	if has_upgrade(vm, "upper_floor") and int(vm.player_elevation_level) != 1:
		opts.append({"label": "🪜⬆️ Subir al primer piso / altillo de tu casa (nivel +1)", "next": "END", "action": "housing_change_level:1"})
	if has_upgrade(vm, "hidden_cellar") and int(vm.player_elevation_level) != -1:
		opts.append({"label": "🕳️⬇️ Bajar al sótano de tu casa (nivel -1)", "next": "END", "action": "housing_change_level:-1"})
	if int(vm.player_elevation_level) != 0:
		opts.append({"label": "🚪➡️ Volver a la planta baja / nivel de calle (nivel 0)", "next": "END", "action": "housing_change_level:0"})

	# P6.9: Usar tu escondite secreto bajo las tablas (disponible cuando tienes escondite)
	if bool(hs.get("has_stash", false)) and is_carp:
		opts.append({"label": "🗝️💰 Guardar 25 de oro en tu escondite bajo el suelo (Oculto: %d Oro)" % int(hs.get("stash_gold", 0)), "next": "END", "action": "housing_stash_put"})
		if int(hs.get("stash_gold", 0)) > 0:
			opts.append({"label": "🗝️📤 Sacar todo tu oro del escondite (%d Oro)" % int(hs.get("stash_gold", 0)), "next": "END", "action": "housing_stash_take"})

	# P6.4: Invitar a tu pareja o gran amistad soltera a mudarse contigo
	if p_lot != "" and str(hs.get("partner_key", "")) == "" and int(npc.affinity) >= 65 and npc.person_profile != null and str(npc.person_profile.partner_id) == "":
		opts.append({"label": "🏡💑 Invitarle a mudarse a vivir contigo en tu casa", "next": "END", "action": "housing_move_in"})

	# P6.6: Trato con tu inquilino si vive en una casa tuya
	var t_lot: String = tenant_lot_of(vm, npc)
	if t_lot != "":
		opts.append({"label": "💰📈 Subirle el alquiler de la casa a 5 de oro por noche", "next": "END", "action": "housing_rent_high:" + t_lot})
		opts.append({"label": "🤝🏠 Perdonarle la cuota a cambio de lealtad y su voto", "next": "END", "action": "housing_rent_forgive:" + t_lot})
		opts.append({"label": "📦🚪 Desahuciar al inquilino para dejar libre tu casa", "next": "END", "action": "housing_evict:" + t_lot})

	# P6.8: Invitar a cenar a tu casa
	if p_lot != "" and today() - int(hs.get("last_dinner_day", -99)) >= 3 and int(npc.affinity) >= 10:
		opts.append({"label": "🍷🍽️ Invitarle a cenar a tu casa para estrechar lazos (-%d Oro)" % DINNER_COST, "next": "END", "action": "housing_dinner"})
	# Tanda 4 (20): Fiestas en casa
	if p_lot != "" and str(VillageLots.lot(vm, p_lot).get("status", "")) == "built" and int(hs.get("last_party_day", -99)) != today():
		opts.append({"label": "🎉🍻 Organizar una fiesta en tu casa para los vecinos (-20 Oro en comida y bebida)", "next": "END", "action": "housing_party"})

	# P6.10: Comprar la escritura del local comercial de un artesano
	if npc.trade_role in VillageNPC.SHOP_ROLES and not (hs["commercial_deeds"] as Dictionary).has(str(int(npc.trade_role))):
		opts.append({"label": "🏪📜 Comprar la propiedad de su local comercial para cobrar renta semanal (-%d Oro)" % COMMERCIAL_DEED_COST, "next": "END", "action": "housing_deed:%d" % int(npc.trade_role)})

	# Bloque PG: Gestionar tu propio negocio (abastecer, hacer publicidad, contratar dependiente y recaudar caja)
	if has_player_shop(vm):
		var ps: Dictionary = hs["player_shop"]
		opts.append({"label": "📦🏪 Abastecer el mostrador de tu negocio con hasta 2 artículos de tu mochila (Stock: %d)" % int(ps.get("stock", 0)), "next": "END", "action": "housing_stock_shop"})
		if today() - int(ps.get("last_ad_day", -99)) >= ADVERTISE_COOLDOWN_DAYS:
			opts.append({"label": "📣🪧 Hacer publicidad de tu negocio por el pueblo (-%d Oro, atrae más clientes 3 días)" % ADVERTISE_COST, "next": "END", "action": "housing_advertise_shop"})
		if int(ps.get("till_gold", 0)) > 0:
			opts.append({"label": "💰🏪 Recaudar la caja de tu negocio (+%d Oro)" % int(ps.get("till_gold", 0)), "next": "END", "action": "housing_collect_shop"})
		if str(ps.get("clerk_key", "")) == "" and int(npc.trade_role) == int(VillageNPC.TradeRole.UNEMPLOYED) and not VillageNeeds.is_outsider(npc):
			opts.append({"label": "🤝🏪 Contratarle como dependiente de tu negocio (%d Oro/día de la caja)" % CLERK_WAGE, "next": "END", "action": "housing_hire_clerk"})

	# Bloque PI.1: Comprar crías y alimentar tus animales de corral (con el Ganadero o el Carpintero)
	var is_rancher: bool = int(npc.trade_role) == int(VillageNPC.TradeRole.RANCHER)
	if (is_rancher or is_carp) and (hs["player_animals"] as Array).size() < 4:
		opts.append({"label": "🐣🐓 Comprar cría de gallo/sabueso para criarla (-%d Oro -> crece en 6 días)" % BUY_CHICK_COST, "next": "END", "action": "housing_buy_chick:rooster"})
		opts.append({"label": "🐣🐑 Comprar cordero joven para criar en tu corral (-%d Oro -> crece en 6 días)" % BUY_CHICK_COST, "next": "END", "action": "housing_buy_chick:sheep"})
	if not (hs["player_animals"] as Array).is_empty() and (is_rancher or is_carp):
		opts.append({"label": "🌾🐣 Alimentar a tus crías con grano o pan (-1 Trigo/Pan -> +2 días de crecimiento y +1 vigor)", "next": "END", "action": "housing_feed_animals"})

	if not opts.is_empty():
		opts.append({"label": "⬅️ Volver", "next": "start"})
		diag["housing_menu"] = {"text": "🏡 Tu hogar, propiedades, inquilinos y alquileres:", "choices": opts}
		ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🏡 Casa propia, alquileres y propiedades…", "next": "housing_menu"})

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	var hs: Dictionary = state(vm)
	var arg: String = action_id.get_slice(":", 1)

	if action_id.begins_with("housing_buy_cash:"):
		if buy_house_cash(vm, arg, inv):
			npc._spawn_floating_text("🏡🔨 «¡Trato hecho! Hoy mismo empiezo a levantar tu casa en %s.»" % arg, Color.SPRING_GREEN, -46.0)
		else:
			npc._spawn_floating_text("Necesitas 100 de oro y que no haya otra obra en marcha", Color.ORANGE_RED, -44.0)

	elif action_id.begins_with("housing_buy_loan:"):
		if buy_house_loan(vm, arg, inv):
			npc._spawn_floating_text("🏦🏡 «¡Hipoteca aprobada! Empezaré tu casa en el solar %s.»" % arg, Color.SPRING_GREEN, -46.0)
		else:
			npc._spawn_floating_text("Necesitas 15 de oro de entrada y un prestamista disponible", Color.ORANGE_RED, -44.0)

	elif action_id.begins_with("housing_upgrade:"):
		var cost: int = int(UPGRADE_COSTS.get(arg, 30))
		if inv == null or int(inv.gold) < cost:
			npc._spawn_floating_text("Necesitas %d de oro" % cost, Color.ORANGE_RED, -44.0)
			return
		var p_lot: String = primary_player_lot(vm)
		if p_lot == "":
			return
		inv.add_gold(-cost)
		npc.personal_gold += cost
		var st: Dictionary = VillageLots.lot(vm, p_lot)
		if not st.has("upgrades") or not (st["upgrades"] is Dictionary):
			st["upgrades"] = {}
		st["upgrades"][arg] = true
		VillageChronicle.add(vm, "home_upgraded", "Mejoraste tu casa con: %s" % arg, true)
		npc._spawn_floating_text("🔨🏡 «¡Mejora instalada en tu casa!»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("housing_garden:"):
		if inv == null or int(inv.gold) < GARDEN_COST:
			npc._spawn_floating_text("Necesitas %d de oro" % GARDEN_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-GARDEN_COST)
		npc.personal_gold += GARDEN_COST
		var st: Dictionary = VillageLots.lot(vm, arg)
		st["has_garden"] = true
		var c: Vector2 = VillageLots.lot_def(arg)["center"]
		vm._spawn_decor_prop("res://assests/world/village/chicken_1.png", c + Vector2(-46, 22), Vector2(0.9, 0.9))
		VillageChronicle.add(vm, "home_garden", "Montaste un huerto y gallinero doméstico junto a tu casa", true)
		npc._spawn_floating_text("🌱🐔 «¡Ya tienes tu huerto y gallinero produciendo en casa!»", Color.SPRING_GREEN, -46.0)

	elif action_id == "housing_build_stash":
		if inv == null or int(inv.gold) < STASH_BUILD_COST:
			npc._spawn_floating_text("Necesitas %d de oro" % STASH_BUILD_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-STASH_BUILD_COST)
		npc.personal_gold += STASH_BUILD_COST
		hs["has_stash"] = true
		npc._spawn_floating_text("🪵🗝️ «Nadie encontrará jamás ese hueco bajo las tablas de tu casa.»", Color.SPRING_GREEN, -46.0)

	elif action_id == "housing_stash_put":
		if inv == null or int(inv.gold) < 25:
			npc._spawn_floating_text("Necesitas 25 de oro en la bolsa", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-25)
		hs["stash_gold"] = int(hs.get("stash_gold", 0)) + 25
		npc._spawn_floating_text("🗝️ Guardaste 25 de oro bajo las tablas (Total oculto: %d)" % int(hs["stash_gold"]), Color.GOLD, -46.0)

	elif action_id == "housing_stash_take":
		var g: int = int(hs.get("stash_gold", 0))
		hs["stash_gold"] = 0
		if inv != null and g > 0:
			inv.add_gold(g)
		npc._spawn_floating_text("🗝️ Recuperaste %d de oro de tu escondite secreto" % g, Color.GOLD, -46.0)

	elif action_id.begins_with("housing_buy_foreclosed:"):
		if inv == null or int(inv.gold) < FORECLOSED_COST:
			npc._spawn_floating_text("Necesitas %d de oro" % FORECLOSED_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-FORECLOSED_COST)
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + FORECLOSED_COST
		var st: Dictionary = VillageLots.lot(vm, arg)
		st["payer"] = "player"
		VillageChronicle.add(vm, "landlord_buy", "Compraste la casa del solar %s para alquilarla a vecinos" % arg, true)
		npc._spawn_floating_text("🏘️🔑 «La escritura del solar %s es tuya. Cobrarás tú los alquileres.»" % arg, Color.SPRING_GREEN, -46.0)

	elif action_id == "housing_move_in":
		if not move_into_player_home(vm, npc, 0):
			return
		hs["partner_key"] = npc.get_person_key()
		npc.modify_affinity(20)
		VillageChronicle.add(vm, "partner_moved_in", "%s se mudó a vivir contigo a tu casa" % npc.npc_name, true)
		npc._spawn_floating_text("🏡💑 «¡Me mudo contigo hoy mismo!»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("housing_rent_high:"):
		hs["rent_rates"][arg] = 5
		npc.modify_affinity(-8)
		npc._spawn_floating_text("😠 «¿5 de oro por noche? Es un abuso, pero lo pagaré...»", Color.ORANGE, -46.0)

	elif action_id.begins_with("housing_rent_forgive:"):
		hs["rent_rates"][arg] = 0
		npc.modify_affinity(16)
		vm.VillageTown.state(vm)["pledges"][npc.get_person_key()] = "player"
		npc._spawn_floating_text("🤝🏠 «¡Mil gracias por perdonarme el alquiler! Tienes mi lealtad.»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("housing_evict:"):
		var st: Dictionary = VillageLots.lot(vm, arg)
		(st.get("residents", []) as Array).erase(npc.get_person_key())
		npc.lodging = ""
		vm.evict_npc_to_vagrant_camp(npc, "desahuciado por su casero")
		npc.modify_affinity(-20)
		VillageChronicle.add(vm, "tenant_evicted", "Desahuciaste a %s de tu casa en el solar %s" % [npc.npc_name, arg], true)
		npc._spawn_floating_text("📦😠 «¡Me dejas en la calle!»", Color.ORANGE_RED, -46.0)

	elif action_id == "housing_dinner":
		if inv == null or int(inv.gold) < DINNER_COST:
			npc._spawn_floating_text("Necesitas %d de oro para las viandas de la cena" % DINNER_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-DINNER_COST)
		hs["last_dinner_day"] = today()
		npc.modify_affinity(14)
		npc.add_thought("Cena estupenda en casa del forastero (+8)", 8.0)
		TraitDiscovery.reveal_next(npc, "en una cena en tu casa")
		# Si tiene un rival, la velada suaviza la enemistad
		for o in VillageNeeds.living(vm):
			if o != npc and npc.get_relationship_with_npc(o.get_person_key()) <= -20:
				npc.modify_npc_relationship(o, 15, "Hicimos las paces cenando en casa del forastero", false)
				break
		VillageChronicle.add(vm, "dinner_party", "Invitaste a %s a cenar en tu casa" % npc.npc_name, true)
		npc._spawn_floating_text("🍷🍽️ «¡Qué gran velada en tu casa!»", Color.SPRING_GREEN, -46.0)

	elif action_id == "housing_party":
		if inv == null or int(inv.gold) < 20:
			npc._spawn_floating_text("Necesitas 20 de oro para la comida y bebida de la fiesta", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-20)
		if vm.shop_businesses.has(int(VillageNPC.TradeRole.INNKEEPER)):
			vm.shop_businesses[int(VillageNPC.TradeRole.INNKEEPER)]["vault_gold"] = int(vm.shop_businesses[int(VillageNPC.TradeRole.INNKEEPER)].get("vault_gold", 0)) + 20
		else:
			vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + 20
		hs["last_party_day"] = today()
		var guests: Array = [npc]
		for o in VillageNeeds.living(vm):
			if o != npc and int(o.trade_role) != int(VillageNPC.TradeRole.CHILD) and int(o.affinity) >= 10 and guests.size() < 4:
				guests.append(o)
		for g in guests:
			g.modify_affinity(10)
			g.add_thought("Fiesta memorable en casa del forastero (+10)", 10.0)
		for i in range(guests.size()):
			for j in range(i + 1, guests.size()):
				guests[i].modify_npc_relationship(guests[j], 8, "Brindamos juntos en la fiesta del forastero", true)
				guests[j].modify_npc_relationship(guests[i], 8, "Brindamos juntos en la fiesta del forastero", true)
		VillageChronicle.add(vm, "house_party", "Celebraste una fiesta en tu casa con %d vecinos del valle" % guests.size(), true)
		npc._spawn_floating_text("🎉🍻 «¡La mejor fiesta del valle! Todos se han reconciliado y brindan por ti.»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("housing_deed:"):
		var has_forged_deed: bool = "VillageUnderworld" in vm and vm.VillageUnderworld != null and bool(vm.VillageUnderworld.state(vm).get("forged_deed", false))
		var d_cost: int = COMMERCIAL_DEED_COST - (40 if has_forged_deed else 0)
		if inv == null or int(inv.gold) < d_cost:
			npc._spawn_floating_text("Necesitas %d de oro para comprar el local" % d_cost, Color.ORANGE_RED, -44.0)
			return
		if has_forged_deed:
			vm.VillageUnderworld.state(vm)["forged_deed"] = false
			if randf() < 0.30:
				vm.wanted_level = int(vm.wanted_level) + 1
				npc.modify_affinity(-15)
				VillageChronicle.add(vm, "forged_deed_caught", "%s descubrió tu escritura municipal falsificada y avisó a la guardia" % npc.npc_name, true)
				npc._spawn_floating_text("🚨📜 «¡Este sello municipal es falso! ¡Guardias!»", Color.ORANGE_RED, -46.0)
				return
		inv.add_gold(-d_cost)
		npc.personal_gold += d_cost
		hs["commercial_deeds"][arg] = true
		npc.modify_affinity(12)
		VillageChronicle.add(vm, "commercial_deed", "Compraste la propiedad del local de %s; cobrarás renta cada sábado" % npc.npc_name, true)
		npc._spawn_floating_text("🏪📜 «El local ahora es tuyo. Te pagaré el 15 %% de la caja cada sábado.»", Color.GOLD, -46.0)

	elif action_id == "housing_repel_intruder":
		var ia: Dictionary = hs.get("intruder_attempt", {})
		if ia.is_empty() or bool(ia.get("repelled", false)):
			return
		ia["repelled"] = true
		var intruder = vm._get_npcs_by_person_key().get(str(ia.get("intruder_key", "")), null)
		var paid: int = vm.VillageClans.pay_from_pocket(intruder, 15, inv) if intruder != null else 0
		if intruder != null:
			intruder.modify_affinity(-10)
			intruder.add_thought("Me pillaron intentando forzar la puerta del forastero (-10)", -10.0)
		VillageChronicle.add(vm, "intruder_repelled", "Escarmentaste a %s cuando intentaba forzar la puerta de tu casa (+%d Oro)" % [str(ia.get("intruder_name", "")), paid], true)
		npc._spawn_floating_text("🚪🛡️ «¡Le diste una buena lección a %s en tu puerta! (+%d Oro)»" % [str(ia.get("intruder_name", "")), paid], Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("housing_sell_house:"):
		var st_sell: Dictionary = VillageLots.lot(vm, arg)
		if str(st_sell.get("payer", "")) != "player":
			return
		var my_key_set: Array = (st_sell.get("residents", []) as Array).duplicate()
		if not my_key_set.is_empty():
			npc._spawn_floating_text("«Primero tiene que mudarse quien vive en esa casa.»", Color.ORANGE_RED, -44.0)
			return
		var price: int = house_sale_price(vm, arg)
		# Si queda hipoteca, la venta primero salda la deuda con quien prestó
		var owed: int = int((st_sell.get("loan", {}) as Dictionary).get("owed", 0))
		var buyer = null
		for n in VillageNeeds.living(vm):
			if int(n.trade_role) != int(VillageNPC.TradeRole.CHILD) and not VillageNeeds.is_outsider(n) and not str(n.lodging).begins_with("house:") and int(n.personal_gold) >= price:
				buyer = n
				break
		var got: int = 0
		if buyer != null:
			buyer.personal_gold -= price
			got = price
		else:
			var t_gold: int = int(vm.town_state.get("treasury", 0))
			got = mini(price, maxi(0, t_gold))
			vm.town_state["treasury"] = t_gold - got
		if got < owed:
			# No llega para saldar la hipoteca: se deshace la venta
			if buyer != null:
				buyer.personal_gold += got
			else:
				vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + got
			npc._spawn_floating_text("«Nadie paga lo bastante para cubrir tu hipoteca (%d de oro).»" % owed, Color.ORANGE_RED, -44.0)
			return
		if owed > 0:
			VillageLoans._credit(vm, str(st_sell["loan"].get("lender", "")), owed)
		st_sell.erase("loan")
		var paid: int = got - owed
		if inv != null and paid > 0:
			inv.add_gold(paid)
		if buyer != null:
			st_sell["payer"] = buyer.get_person_key()
			buyer.lodging = "house:" + arg
			var beds_s: Array = VillageLots._house_beds(arg)
			if not beds_s.is_empty():
				buyer.bed_position = beds_s[0]
			buyer.home_table_pos = VillageLots.lot_def(arg)["center"] + Vector2(0, -2)
			VillageLots.add_resident(vm, arg, buyer.get_person_key())
		else:
			st_sell["payer"] = "town"
		VillageChronicle.add(vm, "house_sold", "Vendiste tu casa del solar %s por %d de oro%s" % [arg, got, (" (%d para saldar la hipoteca)" % owed if owed > 0 else "")], true)
		npc._spawn_floating_text("🏘️💰 «¡Casa del solar %s vendida! Te quedan %d de oro.»" % [arg, paid], Color.GOLD, -46.0)

	elif action_id == "housing_hide_cellar":
		if not has_upgrade(vm, "hidden_cellar") or int(vm.wanted_level) != 1 or int(vm.player_murder_warrants_count) > 0 or today() - int(hs.get("last_hide_day", -99)) < 7:
			return
		hs["last_hide_day"] = today()
		vm.wanted_level = 0
		vm.set_player_elevation_level(-1)
		VillageChronicle.add(vm, "hid_in_cellar", "Te escondiste en el sótano secreto de tu casa hasta que la guardia dejó de buscarte", true)
		npc._spawn_floating_text("🕳️🤫 «La patrulla pasó de largo sin encontrarte en tu sótano secreto (nivel -1).»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("housing_change_level:"):
		var target_lvl: int = int(arg)
		if target_lvl == 1 and not has_upgrade(vm, "upper_floor"):
			return
		if target_lvl == -1 and not has_upgrade(vm, "hidden_cellar"):
			return
		vm.set_player_elevation_level(target_lvl)
		var lvl_lbl: String = "el primer piso (nivel +1)" if target_lvl == 1 else ("el sótano (nivel -1)" if target_lvl == -1 else "la planta de calle (nivel 0)")
		npc._spawn_floating_text("🪜🏠 Te desplazaste a %s" % lvl_lbl, Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("housing_found_shop:"):
		if found_player_shop(vm, arg, inv, npc):
			npc._spawn_floating_text("🏪🔨 «¡Ya tienes mostrador y letrero! Tu negocio está abierto en el solar %s.»" % arg, Color.SPRING_GREEN, -46.0)
		else:
			npc._spawn_floating_text("Necesitas %d de oro y una casa construida tuya" % FOUND_SHOP_COST, Color.ORANGE_RED, -44.0)

	elif action_id == "housing_stock_shop":
		var added: int = stock_player_shop(vm, inv)
		if added > 0:
			npc._spawn_floating_text("📦🏪 Colocaste %d artículo(s) en el mostrador (Stock: %d)" % [added, int(hs["player_shop"].get("stock", 0))], Color.SPRING_GREEN, -46.0)
		else:
			npc._spawn_floating_text("No llevas mercancía vendible en la mochila (pan, carne, ropa, madera, hierro...)", Color.ORANGE_RED, -44.0)

	elif action_id == "housing_advertise_shop":
		if advertise_player_shop(vm, inv):
			npc._spawn_floating_text("📣🪧 «¡Hecho! Pregonaré tu negocio por la plaza durante 3 días.»", Color.SPRING_GREEN, -46.0)
		else:
			npc._spawn_floating_text("Necesitas %d de oro o esperar a que termine la campaña anterior" % ADVERTISE_COST, Color.ORANGE_RED, -44.0)

	elif action_id == "housing_collect_shop":
		if not has_player_shop(vm):
			return
		var ps: Dictionary = hs["player_shop"]
		var gain: int = int(ps.get("till_gold", 0))
		if gain <= 0:
			return
		ps["till_gold"] = 0
		if inv != null:
			inv.add_gold(gain)
		npc._spawn_floating_text("💰🏪 Recaudaste %d de oro de la caja de tu negocio" % gain, Color.GOLD, -46.0)

	elif action_id == "housing_hire_clerk":
		if not has_player_shop(vm) or int(npc.trade_role) != int(VillageNPC.TradeRole.UNEMPLOYED):
			return
		hs["player_shop"]["clerk_key"] = npc.get_person_key()
		npc.modify_affinity(12)
		npc.add_thought("Tengo trabajo atendiendo el mostrador del Bazar del Forastero (+8)", 8.0)
		VillageChronicle.add(vm, "player_shop_clerk", "Contrataste a %s como dependiente de tu negocio" % npc.npc_name, true)
		npc._spawn_floating_text("🤝🏪 «¡Gracias por el empleo! Atenderé tu mostrador cada día.»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("housing_buy_chick:"):
		if buy_young_animal(vm, arg, inv, npc):
			npc._spawn_floating_text("🐣🐑 «Cuida bien de esta cría; en 6 días será un ejemplar adulto.» (-%d Oro)" % BUY_CHICK_COST, Color.SPRING_GREEN, -46.0)
		else:
			npc._spawn_floating_text("Necesitas %d de oro y espacio en tu corral (máx. 4 animales)" % BUY_CHICK_COST, Color.ORANGE_RED, -44.0)

	elif action_id == "housing_feed_animals":
		var fed: int = feed_player_animals(vm, inv)
		if fed > 0:
			npc._spawn_floating_text("🌾🐣 Alimentaste a tus %d animales (+2 días de crecimiento y +1 vigor)" % fed, Color.SPRING_GREEN, -46.0)
		else:
			npc._spawn_floating_text("Necesitas llevar trigo, pan o zanahorias en la mochila para darles de comer", Color.ORANGE_RED, -44.0)
