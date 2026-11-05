@tool
extends RefCounted

## V3: llegadas y marchas según cómo va el pueblo.
## - Cada mañana se calcula el **atractivo** del pueblo: trabajo libre (tiendas vacantes y jornales sin cubrir frente a
##   gente parada), vivienda libre, pobreza (mendigos), seguridad (muertes y peleas sabidas de la última semana) y
##   comida. Sustituye a la vieja regla de «siempre 3 viajeros en la posada».
## - Si el atractivo es bueno y hay donde dormir, llegan forasteros a quedarse: jornaleros con poco, artesanos con
##   ahorros o una pareja que viene junta. Techo: 50 vecinos.
## - Si va mal, se marchan antes los que no tienen casa ni lazos (sin amigos ni pareja), más si duermen en la calle.
## - Si falta vivienda y hay demanda, el carpintero levanta una casa: la paga quien llegó con ahorros o, si no, las
##   arcas del pueblo (casa del pueblo, 2 de oro la noche para las arcas). Quien paga su casa vive en ella gratis.
## Estado en `vm.migration_state` (se guarda). Nada está programado: todo sale de las condiciones del pueblo.

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const VillageWork = preload("res://scripts/systems/VillageWork.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

const POP_CAP: int = 100
const TAVERN_GUEST_BEDS: Array = [Vector2(435, -252), Vector2(468, -252), Vector2(502, -252)]
const TAVERN_DAY_SPOTS: Array = [Vector2(440, 44), Vector2(495, 44), Vector2(415, -105)]
const ARRIVE_MIN_SCORE: float = 0.05
const LEAVE_BELOW_SCORE: float = 0.2
const TOWN_HOUSE_RENT: int = 2
const TREASURY_RESERVE: int = 40
const FRIEND_REL: int = 40
const SAFETY_DAYS: int = 7
const SAFETY_WEIGHTS: Dictionary = {"murder": 0.25, "death_found": 0.25, "illness_death": 0.1, "fight": 0.05}

static func state(vm) -> Dictionary:
	if not vm.migration_state is Dictionary:
		vm.migration_state = {}
	var defs: Dictionary = {"arrivals": 0, "departures": 0, "houses_ordered": 0, "last_score": 0.0, "last_parts": {}}
	for k in defs.keys():
		if not vm.migration_state.has(k):
			vm.migration_state[k] = defs[k]
	return vm.migration_state

## E1: apunta por qué falló una comida (sin oro o sin comida a la venta) y de qué oficio era, para la sonda
static func note_meal_failure(vm, npc) -> void:
	var st: Dictionary = state(vm)
	if not st.has("meal_fails"):
		st["meal_fails"] = {}
	var why: String = "sin_oro"
	if int(npc.personal_gold) >= 3:
		# F2: ¿no quedaba nada en todo el pueblo, o lo había pero era caro o la tienda no atendía?
		var left: int = 0
		for r in [VillageNPC.TradeRole.BAKER, VillageNPC.TradeRole.FISHMONGER, VillageNPC.TradeRole.BUTCHER, VillageNPC.TradeRole.HERBALIST, VillageNPC.TradeRole.INNKEEPER]:
			var h = vm.trade_npcs.get(r)
			if h != null and is_instance_valid(h) and not h.is_dead:
				for item in (h.shop_stock as Dictionary).keys():
					if float(SimpleInventory.CATALOG.get(str(item), {}).get("restore_hunger", 0.0)) > 0.0:
						left += int(h.shop_stock[item])
		why = "caro_o_cerrado" if left > 0 else "agotado"
	var role: String = str(VillageNPC.TradeRole.keys()[int(npc.trade_role)]).to_lower() if int(npc.trade_role) < VillageNPC.TradeRole.size() else str(npc.trade_role)
	var k: String = "%s/%s" % [why, role]
	st["meal_fails"][k] = int(st["meal_fails"].get(k, 0)) + 1
	if why == "caro_o_cerrado": # G3: a qué hora pasa (¿tiendas cerradas?)
		var hk: String = "hora_%02d" % int(WorldClock.current_hour)
		st["meal_fails"][hk] = int(st["meal_fails"].get(hk, 0)) + 1

static func residents(vm) -> Array:
	return VillageNeeds.living(vm).filter(func(n): return not VillageNeeds.is_outsider(n))

static func population(vm) -> int:
	return residents(vm).size()

static func is_unemployed(n) -> bool:
	return int(n.trade_role) == int(VillageNPC.TradeRole.UNEMPLOYED)

static func house_of(n) -> String:
	var l: String = str(n.lodging)
	return l.substr(6) if l.begins_with("house:") else ""

static func is_tavern_guest(n) -> bool:
	return is_unemployed(n) and str(n.lodging) == "" and not n.is_vagrant_camper and not n.in_shelter

# ---------------------------------------------------------------- vivienda
static func free_house_beds(vm) -> int:
	var c: int = 0
	for l in VillageLots.LOTS:
		var st: Dictionary = VillageLots.lot(vm, str(l["id"]))
		if str(st["status"]) == "built" and str(st["kind"]) == "house":
			c += maxi(0, (st["beds"] as Array).size() - (st["residents"] as Array).size())
	return c

static func free_tavern_bed(vm):
	var used: Array = []
	for n in residents(vm):
		# E3: cuenta cualquier vecino que duerma ahí (también un maestro que ya tiene oficio), no solo los parados
		if house_of(n) == "" and n.bed_position in TAVERN_GUEST_BEDS:
			used.append(n.bed_position)
	for b in TAVERN_GUEST_BEDS:
		if not b in used:
			return b
	return null

static func free_tavern_beds_count(vm) -> int:
	var used: Array = []
	for n in residents(vm):
		if house_of(n) == "" and n.bed_position in TAVERN_GUEST_BEDS:
			used.append(n.bed_position)
	var c: int = 0
	for b in TAVERN_GUEST_BEDS:
		if not b in used:
			c += 1
	return c

## Quita de las casas a quien ya no vive en ellas (muerto, marchado o con oficio y cama nueva).
static func prune_residents(vm) -> void:
	var by_key: Dictionary = {}
	for n in residents(vm):
		by_key[n.get_person_key()] = n
	for l in VillageLots.LOTS:
		var id: String = str(l["id"])
		var st: Dictionary = VillageLots.lot(vm, id)
		if str(st.get("kind", "")) != "house":
			continue
		st["residents"] = (st["residents"] as Array).filter(func(k): return by_key.has(k) and house_of(by_key[k]) == id)

static func move_into_house(vm, n, id: String = "") -> bool:
	var b: Dictionary = {}
	if id != "":
		var st: Dictionary = VillageLots.lot(vm, id)
		var res: Array = st["residents"]
		if res.size() < (st["beds"] as Array).size():
			b = {"lot": id, "bed": st["beds"][res.size()], "family_id": "family_lot_" + id, "table": VillageLots.lot_def(id)["center"] + Vector2(0, -2)}
	else:
		b = VillageLots.free_house_bed(vm)
	if b.is_empty():
		return false
	var old_fam: String = str(n.family_id)
	var lid: String = str(b["lot"])
	VillageLots.add_resident(vm, lid, n.get_person_key())
	n.bed_position = b["bed"]
	n.home_table_pos = b["table"]
	n.family_id = str(b["family_id"])
	n.family_name = str(VillageLots.lot(vm, lid)["title"]).replace("🏠 ", "")
	n.lodging = "house:" + lid
	if old_fam != "" and old_fam != "none" and old_fam != n.family_id and "VillageFamily" in vm and vm.VillageFamily != null:
		for kid_m in vm.VillageFamily.children_of_family(vm, old_fam):
			kid_m.family_id = n.family_id
			kid_m.family_name = n.family_name
			kid_m.home_table_pos = n.home_table_pos
			kid_m.bed_position = n.bed_position + Vector2(16, 6)
			kid_m.lodging = "family"
	if n.is_vagrant_camper and vm.vagrant_camp_nodes.has(n.npc_name) and is_instance_valid(vm.vagrant_camp_nodes[n.npc_name]):
		vm.vagrant_camp_nodes[n.npc_name].visible = false
	n.is_vagrant_camper = false
	n.in_shelter = false
	if not vm.house_pantry.has(n.family_id):
		vm.house_pantry[n.family_id] = 1
	n.add_thought("Por fin tengo una casa (+10)", 10.0)
	return true

## Las camas libres de las casas: primero quien pagó la casa, luego quien duerme en la calle o en el albergue,
## luego los huéspedes de la posada.
static func assign_houses(vm) -> int:
	var moved: int = 0
	var homeless: Array = residents(vm).filter(func(n): return is_unemployed(n) and house_of(n) == "")
	for l in VillageLots.LOTS:
		var st: Dictionary = VillageLots.lot(vm, str(l["id"]))
		if str(st["status"]) != "built" or str(st["kind"]) != "house":
			continue
		for n in homeless:
			if n.get_person_key() == str(st.get("payer", "")) and house_of(n) == "" and move_into_house(vm, n, str(l["id"])):
				moved += 1
	homeless.sort_custom(func(a, b): return int(a.is_vagrant_camper or a.in_shelter) > int(b.is_vagrant_camper or b.in_shelter))
	for n in homeless:
		if house_of(n) != "":
			continue
		if free_house_beds(vm) <= 0:
			break
		if move_into_house(vm, n):
			moved += 1
	return moved

## Noche: quien vive en una casa del pueblo paga 2 a las arcas; si no puede, no pasa nada (es su casa).
## Devuelve true si el vecino vive en una casa (para que el cobro de la posada lo salte).
static func nightly(vm, n) -> bool:
	if str(n.lodging) == "family":
		return true # V9: joven que aún vive con sus padres
	var id: String = house_of(n)
	if id == "":
		return false
	var owner_key: String = str(VillageLots.lot(vm, id).get("payer", ""))
	if owner_key == "town" and n.personal_gold >= TOWN_HOUSE_RENT:
		n.personal_gold -= TOWN_HOUSE_RENT
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + TOWN_HOUSE_RENT
	elif owner_key == "player":
		var rent_p: int = vm.VillageHousing.rent_for_lot(vm, id)
		if n.personal_gold >= rent_p:
			n.personal_gold -= rent_p
			var pl = VillageNeeds.player_of(vm)
			if pl != null and "inventory" in pl and pl.inventory != null:
				pl.inventory.add_gold(rent_p)
			vm.VillageHousing.state(vm)["rent_collected"] = int(vm.VillageHousing.state(vm).get("rent_collected", 0)) + rent_p
	elif owner_key != "" and owner_key != n.get_person_key() and n.personal_gold >= TOWN_HOUSE_RENT:
		# H: casa de otro (p. ej. un noble que la recuperó por deudas): el alquiler va a su dueño
		var landlord = vm._get_npcs_by_person_key().get(owner_key, null)
		var res_keys: Array = VillageLots.lot(vm, id).get("residents", [])
		var owner_lives_here: bool = res_keys.any(func(rk): return str(rk) == owner_key) # su familia no paga
		if landlord != null and is_instance_valid(landlord) and not landlord.is_dead and not owner_lives_here:
				n.personal_gold -= TOWN_HOUSE_RENT
				landlord.personal_gold += TOWN_HOUSE_RENT
	return true

# ---------------------------------------------------------------- atractivo
static func attractiveness(vm) -> Dictionary:
	var people: Array = residents(vm)
	var pop: int = maxi(1, people.size())
	var vacant: int = 0
	for r in vm.trade_configs.keys():
		var h = vm.trade_npcs.get(r)
		var biz: Dictionary = vm.shop_businesses.get(int(r), {})
		if (h == null or not is_instance_valid(h) or h.is_dead) and str(biz.get("owner_mode", "NPC")) != "SOLE_OWNER":
			vacant += 1
	var labor: int = 0
	for key in VillageWork.PLACES.keys():
		if VillageWork.master_of(vm, key) != null:
			labor += (VillageWork.PLACES[key]["spots"] as Array).size()
	var idle: int = people.filter(func(n): return is_unemployed(n)).size()
	var jobs: float = clampf(float(vacant * 2 + labor - idle) / 6.0, -1.0, 1.0)
	var beds: int = free_house_beds(vm) + (1 if free_tavern_bed(vm) != null else 0)
	var housing: float = clampf(float(beds) / 3.0, 0.0, 1.0) if beds > 0 else -0.3
	var beggars: int = people.filter(func(n): return VillageNeeds.class_of(n) == "mendigo").size()
	var poverty: float = -1.5 * float(beggars) / float(pop)
	var safety: float = 0.0
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	for e in vm.chronicle:
		if bool(e.get("known", false)) and today - int(e.get("day", 0)) <= SAFETY_DAYS:
			safety -= float(SAFETY_WEIGHTS.get(str(e.get("type", "")), 0.0))
	safety = maxf(-1.0, safety)
	# `village_food_shortage_days` solo crece (cuenta comidas fallidas): miramos las del último día, según la población
	var ms: Dictionary = state(vm)
	var hungry: int = maxi(0, int(vm.village_food_shortage_days) - int(ms.get("food_seen", vm.village_food_shortage_days)))
	ms["food_seen"] = int(vm.village_food_shortage_days)
	var food: float = -0.4 * clampf(float(hungry) / maxf(1.0, float(pop) * 0.15), 0.0, 1.0)
	var parts: Dictionary = {"jobs": jobs, "housing": housing, "poverty": poverty, "safety": safety, "food": food}
	var score: float = 0.4 * jobs + 0.3 * housing + poverty + safety + food
	return {"score": score, "parts": parts}

# ---------------------------------------------------------------- llegadas
const SETTLER_KINDS: Array = [
	{"id": "jornalero", "weight": 0.42, "gold": Vector2i(8, 25), "label": "Jornalero Recién Llegado"},
	{"id": "artesano", "weight": 0.28, "gold": Vector2i(70, 130), "label": "Artesano Recién Llegado"},
	{"id": "pareja", "weight": 0.12, "gold": Vector2i(40, 70), "label": "Recién Llegado"},
	{"id": "familia", "weight": 0.18, "gold": Vector2i(50, 90), "label": "Recién Llegado"}, # V9: con 1 o 2 hijos
]

static func _pick_kind(couple_ok: bool) -> Dictionary:
	var r: float = randf()
	for k in SETTLER_KINDS:
		if str(k["id"]) in ["pareja", "familia"] and not couple_ok:
			continue
		r -= float(k["weight"])
		if r <= 0.0:
			return k
	return SETTLER_KINDS[0]

static func _spawn_one(vm, kind: Dictionary, idx: int):
	var tex: Texture2D = vm._load_tex("res://assests/world/village/villager_traveler.png")
	var n = vm._spawn_generated_newcomer("NPC_Traveler_", VillageNPC.TradeRole.UNEMPLOYED, VillageNPC.TradeRole.UNEMPLOYED,
		str(kind["label"]), tex, TAVERN_DAY_SPOTS[idx % TAVERN_DAY_SPOTS.size()], TAVERN_GUEST_BEDS[idx % TAVERN_GUEST_BEDS.size()],
		{}, vm._tavern_social_pos, "none", "Huésped de Posada")
	n.personal_gold = randi_range(int(kind["gold"].x), int(kind["gold"].y))
	n.set_meta("arrived_day", int(WorldClock.current_day) if WorldClock else 1) # M19 «El forastero raro»
	vm.unemployed_npcs.append(n)
	vm.arrivals_today_count += 1
	state(vm)["arrivals"] = int(state(vm)["arrivals"]) + 1
	return n

## Llega alguien (o una pareja) si hay donde dormir. Devuelve cuántos llegaron.
static func try_arrival(vm) -> int:
	if population(vm) >= POP_CAP or vm.arrivals_today_count >= vm.MAX_DAILY_ARRIVALS:
		return 0
	var house_beds: int = free_house_beds(vm)
	var tav = free_tavern_bed(vm)
	if house_beds <= 0 and tav == null:
		return 0 # Sin cama no viene nadie a quedarse
	var couple_ok: bool = (house_beds + free_tavern_beds_count(vm) >= 2) and population(vm) + 2 <= POP_CAP and vm.arrivals_today_count + 2 <= vm.MAX_DAILY_ARRIVALS
	var kind: Dictionary = _pick_kind(couple_ok)
	if couple_ok and "VillageFamily" in vm and vm.VillageFamily != null and vm.VillageFamily.pupils(vm).is_empty():
		kind = SETTLER_KINDS[3]
	var who: Array = [_spawn_one(vm, kind, int(state(vm)["arrivals"]))]
	if str(kind["id"]) in ["pareja", "familia"]:
		who.append(_spawn_one(vm, kind, int(state(vm)["arrivals"])))
		who[0].modify_npc_relationship(who[1], 60, "Llegamos juntos al valle", true)
		who[1].modify_npc_relationship(who[0], 60, "Llegamos juntos al valle", true)
		vm.VillageFamily.marry(who[0], who[1])
		var shared_fam: String = "family_settler_%d" % int(state(vm)["arrivals"])
		for p_s in who:
			p_s.family_id = shared_fam
	for n in who:
		if not move_into_house(vm, n):
			var t_bed = free_tavern_bed(vm)
			n.bed_position = t_bed if t_bed != null else n.bed_position
	if str(kind["id"]) == "familia":
		var mother = who[0] if who[0].person_profile != null and str(who[0].person_profile.gender) == "F" else who[1]
		var father = who[1] if mother == who[0] else who[0]
		for k_idx in range(randi_range(1, 2)):
			if population(vm) < POP_CAP:
				var kid_age: int = randi_range(12, 14) if k_idx == 0 else randi_range(8, 11)
				var kid = vm.VillageFamily.spawn_child(vm, mother, father, kid_age)
				kid.lodging = "family"
				kid.global_position = mother.global_position + Vector2(-10, 6)
				who.append(kid)
		if "VillageFamily" in vm and vm.VillageFamily != null:
			vm.VillageFamily.update_school(vm, false)
	var names: String = " y ".join(who.map(func(n): return n.npc_name))
	vm._hint_player("🎒🚶 %s %s al valle para quedarse." % [names, "llegan" if who.size() > 1 else "llega"])
	return who.size()

# ---------------------------------------------------------------- marchas
static func ties(vm, n) -> int:
	if n.person_profile != null and str(n.person_profile.partner_id) != "":
		return 99
	var c: int = 0
	for o in residents(vm):
		if o != n and n.get_relationship_with_npc(o.get_person_key()) >= FRIEND_REL:
			c += 1
	return c

static func leave_chance(vm, n, score: float) -> float:
	if score >= LEAVE_BELOW_SCORE or not is_unemployed(n) or house_of(n) != "" or n.has_meta("leaving") or VillageNeeds.is_outsider(n):
		return 0.0
	if n.is_downed or n.sick_level >= 2 or n.is_hostile or ties(vm, n) >= 2:
		return 0.0
	var homeless: bool = n.is_vagrant_camper or n.in_shelter
	return clampf((LEAVE_BELOW_SCORE - score) * (0.5 if homeless else 0.15), 0.0, 0.3)

static func exit_pos(n) -> Vector2:
	return Vector2(-900, 48) if n.global_position.x < 300.0 else Vector2(1480, 48)

static func start_leaving(vm, n) -> void:
	n.set_meta("leaving", true)
	n.add_thought("Aquí no hay nada para mí: me marcho (-4)", -4.0)
	if n.errand_kind != "":
		n.end_errand()
	n.start_errand("leave", exit_pos(n))
	vm.VillageChronicle.add(vm, "departure", "%s se marcha del valle: aquí no encontró su sitio" % n.npc_name, true)

## VillageNeeds.tick: ha llegado al borde del mapa. Se va de verdad.
static func on_left(vm, n) -> void:
	n.end_errand()
	state(vm)["departures"] = int(state(vm)["departures"]) + 1
	vm.record_social_event("departure", n, null, "%s se marchó del valle" % n.npc_name)
	vm.unemployed_npcs.erase(n)
	if vm.vagrant_camp_nodes.has(n.npc_name) and is_instance_valid(vm.vagrant_camp_nodes[n.npc_name]):
		vm.vagrant_camp_nodes[n.npc_name].visible = false
	n.lodging = ""
	prune_residents(vm)
	vm.VillageClans.on_npc_departure(vm, n) # P1.6: herencia de casa al marcharse
	vm._free_transient_npc(n)

## Cada hora: quien se iba y perdió el encargo (se le acabó el plazo) sigue su camino.
static func on_hour(vm, _hour: int) -> void:
	for n in residents(vm):
		if n.has_meta("leaving") and n.errand_kind == "" and not n.is_sleeping and not n.is_downed:
			n.start_errand("leave", exit_pos(n))

# ---------------------------------------------------------------- obras
## ¿Hace falta otra casa? Solo si no queda cama en casas, hay gente sin casa y el pueblo atrae (o hay gente durmiendo
## en la calle). Paga quien tenga ahorros; si no, las arcas.
static func maybe_order_house(vm, score: float) -> String:
	if VillageLots.active_site(vm) != "" or free_house_beds(vm) > 0 or VillageLots._carpenter(vm) == null:
		return ""
	var homeless: Array = residents(vm).filter(func(n): return is_unemployed(n) and house_of(n) == "" and not n.has_meta("leaving"))
	if homeless.is_empty():
		return ""
	var street: bool = homeless.any(func(n): return n.is_vagrant_camper or n.in_shelter)
	if score < 0.1 and not street:
		return ""
	var lots: Array = VillageLots.free_lots(vm, "house")
	if lots.is_empty():
		# Bloque PQ: Si ya no quedan solares libres pero hace falta cama, se amplía una casa construida con altillo (+2 camas)
		for l in VillageLots.LOTS:
			var lid: String = str(l["id"])
			var lst: Dictionary = VillageLots.lot(vm, lid)
			if str(lst.get("status", "")) == "built" and str(lst.get("kind", "")) == "house" and not bool((lst.get("upgrades", {}) as Dictionary).get("upper_floor", false)):
				homeless.sort_custom(func(a, b): return a.personal_gold > b.personal_gold)
				var exp_payer = homeless[0] if int(homeless[0].personal_gold) >= VillageLots.UPPER_FLOOR_COST + 15 else null
				var exp_reserve: int = 0 if street else TREASURY_RESERVE
				if exp_payer != null or int(vm.town_state.get("treasury", 0)) >= VillageLots.UPPER_FLOOR_COST + exp_reserve:
					if VillageLots.expand_house_upper_floor(vm, lid, exp_payer):
						return lid
		return ""
	var cost: int = int(VillageLots.KINDS["house"]["cost"])
	homeless.sort_custom(func(a, b): return a.personal_gold > b.personal_gold)
	# E2: una pareja junta sus ahorros para la casa
	var buyer = homeless[0]
	var mate = _partner_of(vm, buyer)
	var pooled: int = int(buyer.personal_gold) + (int(mate.personal_gold) if mate != null else 0)
	var payer = buyer if pooled >= cost + 20 else null
	if payer != null and int(buyer.personal_gold) < cost and mate != null:
		var need: int = cost - int(buyer.personal_gold)
		mate.personal_gold -= need
		buyer.personal_gold += need
	# H: sin dinero para pagarla entera, con la entrada se pide prestado el resto (al pueblo o a un noble)
	var loan: Dictionary = {}
	if payer == null:
		loan = vm.VillageLoans.arrange(vm, buyer, mate, cost)
		if not loan.is_empty():
			vm.VillageLoans.disburse(vm, loan, buyer, mate)
			payer = buyer
	# Bloque AA: el tamaño de la casa va con el bolsillo (con préstamo o a cargo del pueblo, casita; con ahorros de sobra, casona)
	var wealth: String = "poor" if (payer == null or not loan.is_empty()) else ("rich" if pooled >= cost + 120 else "mid")
	# Los huraños (poco sociables) prefieren un barrio apartado
	var lot_id: String = VillageLots.pick_house_lot(vm, wealth, TraitCatalog.npc_tendency(buyer, "sociability") <= -0.3)
	var word: String = str(VillageLots.HOUSE_PLOTS[VillageLots.plot_of(lot_id)]["word"])
	var title: String = ("🏠 %s de %s" % [word, str(payer.npc_name).split(" ")[0]]) if payer != null else "🏠 %s del pueblo" % word
	# E2: si alguien duerme al raso, el pueblo no se guarda la reserva
	var reserve: int = 0 if street else TREASURY_RESERVE
	if payer == null and int(vm.town_state.get("treasury", 0)) < cost + reserve:
		return ""
	var id: String = VillageLots.request_build(vm, lot_id, "house", payer, title)
	if id != "":
		state(vm)["houses_ordered"] = int(state(vm)["houses_ordered"]) + 1
		if not loan.is_empty():
			vm.VillageLoans.open_loan(vm, id, buyer, loan)
	elif not loan.is_empty():
		vm.VillageLoans.undo(vm, loan, buyer)
	return id

static func _partner_of(vm, n):
	if n.person_profile == null or str(n.person_profile.partner_id) == "":
		return null
	var m = vm.VillageFamily.by_key(vm).get(str(n.person_profile.partner_id))
	if m == null or not is_instance_valid(m) or m.is_dead:
		return null
	return m

# ---------------------------------------------------------------- cada día
static func daily(vm) -> void:
	for i in range(vm.unemployed_npcs.size() - 1, -1, -1):
		var g = vm.unemployed_npcs[i]
		if not is_instance_valid(g) or g.is_dead or not is_unemployed(g):
			vm.unemployed_npcs.remove_at(i)
	prune_residents(vm)
	vm.VillageLoans.daily(vm) # H: cuotas y desahucios antes de repartir casas libres
	assign_houses(vm)
	var a: Dictionary = attractiveness(vm)
	var score: float = float(a["score"])
	var st: Dictionary = state(vm)
	st["last_score"] = score
	st["last_parts"] = a["parts"]
	# Marchas: como mucho una al día
	var people: Array = residents(vm)
	people.shuffle()
	for n in people:
		if randf() < leave_chance(vm, n, score):
			start_leaving(vm, n)
			break
	# Llegadas: más probables cuanto mejor va el pueblo
	if score > ARRIVE_MIN_SCORE and randf() < clampf(score * 0.8, 0.0, 0.6):
		try_arrival(vm)
		if score > 0.5 and randf() < 0.3:
			try_arrival(vm)
	maybe_order_house(vm, score)

## Al cargar: los que se iban se quedan (la marca no se guarda); las casas se repasan.
static func after_load(vm) -> void:
	prune_residents(vm)
