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

const HOUSE_CASH_COST: int = 100
const FORECLOSED_COST: int = 80
const UPGRADE_COSTS: Dictionary = {"bookshelf": 35, "workbench": 40, "oak_bed": 30, "strong_lock": 25}
const GARDEN_COST: int = 35
const STASH_BUILD_COST: int = 30
const DINNER_COST: int = 10
const COMMERCIAL_DEED_COST: int = 120

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
	if not hs.has("last_study_day"):
		hs["last_study_day"] = -99
	if not hs.has("commercial_deeds") or not (hs["commercial_deeds"] is Dictionary):
		hs["commercial_deeds"] = {}
	if not hs.has("rent_rates") or not (hs["rent_rates"] is Dictionary):
		hs["rent_rates"] = {}
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

# ==============================================================================
# P6.1 y P6.5: Comprar casa al contado, con hipoteca o casa embargada
# ==============================================================================
static func buy_house_cash(vm, lot_id: String, inv) -> bool:
	if inv == null or int(inv.gold) < HOUSE_CASH_COST:
		return false
	if str(VillageLots.lot(vm, lot_id).get("status", "")) != "empty" or VillageLots.active_site(vm) != "":
		return false
	inv.add_gold(-HOUSE_CASH_COST)
	# request_build con payer=null cobra de las arcas, así que ingresamos primero los 100 en las arcas y marcamos payer="player"
	vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + HOUSE_CASH_COST
	var built: String = VillageLots.request_build(vm, lot_id, "house", null, "🏡 Casa del Forastero")
	if built == "":
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - HOUSE_CASH_COST
		inv.add_gold(HOUSE_CASH_COST)
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
			if inv != null and int(inv.gold) >= HOUSE_CASH_COST and buy_house_cash(vm, id, inv):
				if player.has_method("show_hint"):
					player.show_hint("🏡🔨 Compraste el solar %s al contado (-100 Oro). El carpintero vendrá a levantar tu casa." % id)
				return true
			elif inv != null and int(inv.gold) >= VillageLoans.DOWN_PAYMENT and buy_house_loan(vm, id, inv):
				if player.has_method("show_hint"):
					player.show_hint("🏦🏡 Encargaste tu casa en el solar %s con hipoteca (-15 Oro de entrada, 3 Oro/día)." % id)
				return true
		# 2. Dentro de una casa construida tuya: dormir en tu cama o estudiar en tu estantería
		if str(st.get("status", "")) == "built" and str(st.get("payer", "")) == "player":
			var c: Vector2 = l["center"]
			if pos.distance_to(c) <= 46.0:
				var hs: Dictionary = state(vm)
				var up: Dictionary = st.get("upgrades", {})
				if bool(up.get("bookshelf", false)) and int(hs.get("last_study_day", -99)) != today():
					hs["last_study_day"] = today()
					if player.has_method("add_skill_xp"):
						player.call("add_skill_xp", "crafting", 15)
				var surv = player.get_node_or_null("SurvivalComponent")
				if surv != null:
					surv.current_sleep = 100.0
					surv.current_hygiene = 100.0
				if "current_stamina" in player and "max_stamina" in player:
					player.current_stamina = player.max_stamina
				if WorldClock != null and WorldClock.has_method("advance_to_morning"):
					WorldClock.call("advance_to_morning", 6)
				if player.has_method("show_hint"):
					var bonus_txt: String = " (+estudio en tu estantería)" if bool(up.get("bookshelf", false)) else ""
					player.show_hint("🛌🏡 Descansaste y te aseaste en tu propia casa gratis%s." % bonus_txt)
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
	# P6.10: Los sábados, los locales comerciales tuyos te pagan el 15 % de su caja
	if inv != null and WorldClock != null and WorldClock.has_method("get_weekday") and int(WorldClock.get_weekday()) == 5:
		var deeds: Dictionary = hs.get("commercial_deeds", {})
		for r_key in deeds.keys():
			var role_i: int = int(r_key)
			if vm.shop_businesses.has(role_i):
				var vault: int = int(vm.shop_businesses[role_i].get("vault_gold", 0))
				var cut: int = maxi(6, int(round(float(vault) * 0.15)))
				if vault >= cut:
					vm.shop_businesses[role_i]["vault_gold"] = vault - cut
				inv.add_gold(cut)

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
			for u in [["bookshelf", "📚 Estantería de estudio (+XP diaria)"], ["workbench", "⚗️ Banco de trabajo y alquimia"], ["oak_bed", "🛏️ Cama de roble macizo"], ["strong_lock", "🔒 Cerradura reforzada antirrobo"]]:
				if not bool(up.get(u[0], false)):
					opts.append({"label": "%s (-%d Oro)" % [u[1], int(UPGRADE_COSTS[u[0]])], "next": "END", "action": "housing_upgrade:" + u[0]})
			if not bool(st.get("has_garden", false)):
				opts.append({"label": "🌱🐔 Montar huerto y gallinero en tu solar (-%d Oro)" % GARDEN_COST, "next": "END", "action": "housing_garden:" + p_lot})
			if not bool(hs.get("has_stash", false)):
				opts.append({"label": "🪵🗝️ Construir escondite secreto bajo las tablas (-%d Oro)" % STASH_BUILD_COST, "next": "END", "action": "housing_build_stash"})
		# P6.5: Comprar una casa embargada al pueblo o al noble para alquilarla
		for l in VillageLots.LOTS:
			var id2: String = str(l["id"])
			var st2: Dictionary = VillageLots.lot(vm, id2)
			if str(st2.get("status", "")) == "built" and str(st2.get("kind", "")) == "house" and str(st2.get("payer", "")) in ["town", npc.get_person_key()]:
				opts.append({"label": "🏘️🔑 Comprar la casa del solar %s para alquilarla (-%d Oro)" % [id2, FORECLOSED_COST], "next": "END", "action": "housing_buy_foreclosed:" + id2})
				break

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

	# P6.10: Comprar la escritura del local comercial de un artesano
	if npc.trade_role in VillageNPC.SHOP_ROLES and not (hs["commercial_deeds"] as Dictionary).has(str(int(npc.trade_role))):
		opts.append({"label": "🏪📜 Comprar la propiedad de su local comercial para cobrar renta semanal (-%d Oro)" % COMMERCIAL_DEED_COST, "next": "END", "action": "housing_deed:%d" % int(npc.trade_role)})

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
		var p_lot: String = primary_player_lot(vm)
		if p_lot == "":
			return
		hs["partner_key"] = npc.get_person_key()
		npc.lodging = "house:" + p_lot
		var beds: Array = VillageLots._house_beds(p_lot)
		if not beds.is_empty():
			npc.bed_position = beds[0]
		npc.home_table_pos = VillageLots.lot_def(p_lot)["center"] + Vector2(0, -2)
		VillageLots.add_resident(vm, p_lot, npc.get_person_key())
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

	elif action_id.begins_with("housing_deed:"):
		if inv == null or int(inv.gold) < COMMERCIAL_DEED_COST:
			npc._spawn_floating_text("Necesitas %d de oro para comprar el local" % COMMERCIAL_DEED_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-COMMERCIAL_DEED_COST)
		npc.personal_gold += COMMERCIAL_DEED_COST
		hs["commercial_deeds"][arg] = true
		npc.modify_affinity(12)
		VillageChronicle.add(vm, "commercial_deed", "Compraste la propiedad del local de %s; cobrarás renta cada sábado" % npc.npc_name, true)
		npc._spawn_floating_text("🏪📜 «El local ahora es tuyo. Te pagaré el 15 %% de la caja cada sábado.»", Color.GOLD, -46.0)
