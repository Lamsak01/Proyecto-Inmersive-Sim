@tool
extends RefCounted
const _AN_SITIOS = preload("res://mapa/anclas.gd") # plan de sitios: sitios al aire libre siguen a lo movido

## V5d: jornaleros y lavadero.
## - Jornaleros: cada mañana (7 h) los dueños de la granja, el rancho, la cantera y el leñador contratan a vecinos sin
##   oficio, primero a los más necesitados. El jornalero va andando a su sitio y trabaja allí de 8 a 18 h; solo cuentan
##   las horas que de verdad está allí trabajando. Cada hora produce algo para el negocio (trigo, lana, piedra,
##   madera). A las 18 h cobra 1 de oro por hora; si el dueño no tiene para pagarle, se enfada. El domingo no se trabaja.
##   Nadie es contratado si su dueño falta, está herido o no tiene para pagar ni un día.
## - Lavadero (orilla oeste del lago): algunos van allí a lavarse en vez de al pozo; quien coincide se cuenta chismes.
## Estado en `vm.work_state` (se guarda). Al cargar una partida los jornales del día se cancelan sin cobrar.

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageTrades = preload("res://scripts/systems/VillageTrades.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

const HIRE_HOUR: int = 7
const WORK_FROM: int = 8
const PAY_HOUR: int = 18
const WAGE_PER_HOUR: int = 1
const SPOT_RADIUS: float = 50.0
const STOCK_CAP: int = 14
const OWNER_FOOD_RESERVE: int = 20 # F1: el dueño no se gasta en jornales lo que necesita para comer
## Paso 2 (2026-11-07): el Lavadero se traslada al arroyo/fuente del pueblo (al oeste de la Botica y al norte del Parque del Roble), lejos del lago.
const LAVADERO_POS: Vector2 = Vector2(215, 145)
const LAVADERO_CHANCE: float = 0.3
const LAVADERO_GOSSIP_RADIUS: float = 50.0

## Sitios de trabajo por oficio (clave de VillageTrades.CONFIG).
const PLACES: Dictionary = {
	"farmer": {"label": "la Granja del Sur", "icon": "🌾", "spots": [Vector2(-40, 445), Vector2(40, 445), Vector2(-40, 500), Vector2(40, 500)], "yield": {"wheat": 0.25, "carrot": 0.08}},
	"rancher": {"label": "el Rancho", "icon": "🐑", "spots": [Vector2(335, 440), Vector2(370, 500)], "yield": {"wool": 0.15, "raw_meat": 0.1}},
	"quarry": {"label": "la Cantera", "icon": "⛏️", "spots": [Vector2(-185, -350), Vector2(-150, -300)], "yield": {"stone": 0.3}},
	"woodcutter": {"label": "el bosque", "icon": "🪓", "spots": [Vector2(-470, 625), Vector2(-390, 635)], "yield": {"wood": 0.35}},
}

static func state(vm) -> Dictionary:
	if not vm.work_state is Dictionary:
		vm.work_state = {}
	for k in ["jobs", "acc", "hired_total", "unpaid_total", "paid_total", "lavadero_gossip"]:
		if not vm.work_state.has(k):
			if k in ["jobs", "acc"]:
				vm.work_state[k] = {}
			else:
				vm.work_state[k] = 0
	return vm.work_state

static func master_of(vm, key: String):
	var m = vm.trade_npcs.get(VillageTrades.role_of(key))
	if m != null and is_instance_valid(m) and not m.is_dead and not m.is_downed:
		return m
	return null

# ---------------------------------------------------------------- mapa
static func build_world(vm) -> void:
	var p: Vector2 = LAVADERO_POS
	vm._add_rect_poly(p, Vector2(18, 8), Color(0.55, 0.55, 0.58, 0.95), -2) # Pila de piedra
	vm._add_rect_poly(p, Vector2(14, 5), Color(0.30, 0.55, 0.78, 0.95), -1) # Agua
	vm._add_title_label(p + Vector2(-50, -24), Vector2(100, 12), "🧺 Lavadero", Color(0.75, 0.9, 1.0), 7)

# ---------------------------------------------------------------- jornaleros
static func _is_work_day() -> bool:
	return WorldClock == null or not (WorldClock.has_method("is_rite_day") and WorldClock.is_rite_day())

static func can_be_hired(n) -> bool:
	if n.is_dead or n.is_downed or n.is_hostile or not n.is_conscious() or VillageNeeds.is_outsider(n):
		return false
	if int(n.trade_role) != int(VillageNPC.TradeRole.UNEMPLOYED) or n.has_meta("day_job") or n.sick_level >= 2:
		return false
	return n.person_profile == null or int(n.person_profile.age) >= 16

## ¿Acepta hoy el jornal? Casi siempre si va justo de dinero; quien tiene ahorros y es vago, a menudo no.
static func accepts(n) -> float:
	var c: float = 0.9 if n.personal_gold < 30 else 0.45
	c += 0.2 * TraitCatalog.npc_tendency(n, "diligence")
	return clampf(c, 0.05, 0.98)

static func hire(vm) -> int:
	var st: Dictionary = state(vm)
	var shop_clerk_key: String = str(vm.VillageHousing.state(vm).get("player_shop", {}).get("clerk_key", "")) if "VillageHousing" in vm and vm.VillageHousing != null else ""
	var pool: Array = []
	for n in VillageNeeds.living(vm):
		if n.get_person_key() != shop_clerk_key and can_be_hired(n):
			pool.append(n)
	pool.sort_custom(func(a, b): return a.personal_gold < b.personal_gold) # Primero los más necesitados
	var hired: int = 0
	for key in PLACES.keys():
		var m = master_of(vm, key)
		var day_wage: int = WAGE_PER_HOUR * (PAY_HOUR - WORK_FROM)
		if m == null or m.personal_gold < day_wage + OWNER_FOOD_RESERVE:
			continue # Sin dueño o sin dinero para pagar un día sin quedarse sin comer, hoy no contrata
		var spots: Array = PLACES[key]["spots"]
		var free: int = mini(spots.size(), workers_needed(m, key)) - _workers_at(vm, key)
		var budget: int = int((m.personal_gold - OWNER_FOOD_RESERVE) / day_wage)
		var idx: int = _workers_at(vm, key)
		while free > 0 and budget > 0 and not pool.is_empty():
			var n = pool.pop_front()
			if randf() >= accepts(n):
				continue
			_assign(vm, n, key, _AN_SITIOS.mover(spots[idx % spots.size()])) # plan de sitios: sigue al campo movido
			idx += 1
			free -= 1
			budget -= 1
			hired += 1
	st["hired_total"] = int(st["hired_total"]) + hired
	return hired

## F1: cuántos jornaleros hacen falta hoy para llenar el almacén del producto principal (el de más rendimiento).
## Con el almacén lleno no contrata a nadie: pagaría por una cosecha que se tira.
static func workers_needed(m, key: String) -> int:
	var y: Dictionary = PLACES[key]["yield"]
	var main: String = ""
	for item in y.keys():
		if main == "" or float(y[item]) > float(y[main]):
			main = str(item)
	var room: int = STOCK_CAP - int(m.shop_stock.get(main, 0))
	if room <= 0:
		return 0
	return ceili(float(room) / (float(y[main]) * float(PAY_HOUR - WORK_FROM)))

static func _workers_at(vm, key: String) -> int:
	var c: int = 0
	for j in (state(vm)["jobs"] as Dictionary).values():
		if str(j["place"]) == key:
			c += 1
	return c

static func _assign(vm, n, key: String, spot: Vector2) -> void:
	state(vm)["jobs"][n.get_person_key()] = {"place": key, "hours": 0}
	n.set_meta("day_job", "%s Jornalero en %s" % [str(PLACES[key]["icon"]), str(PLACES[key]["label"])])
	n.set_meta("day_job_pos", spot)
	if n.errand_kind != "":
		n.end_errand()
	n.add_thought("Hoy tengo jornal en %s (+3)" % str(PLACES[key]["label"]), 3.0)

static func _release(n) -> void:
	for m in ["day_job", "day_job_pos"]:
		if n.has_meta(m):
			n.remove_meta(m)

static func on_hour(vm, hour: int) -> void:
	var st: Dictionary = state(vm)
	if hour == HIRE_HOUR and _is_work_day():
		hire(vm)
	elif hour > WORK_FROM and hour <= PAY_HOUR and not (st["jobs"] as Dictionary).is_empty():
		_count_hour(vm)
		if hour == PAY_HOUR:
			pay(vm)

## La hora que acaba de pasar: cuenta a quien está en su sitio trabajando y produce para el negocio.
static func _count_hour(vm) -> void:
	var st: Dictionary = state(vm)
	var by_key: Dictionary = {}
	for n in VillageNeeds.living(vm):
		by_key[n.get_person_key()] = n
	for pk in (st["jobs"] as Dictionary).keys():
		var j: Dictionary = st["jobs"][pk]
		var n = by_key.get(pk)
		var m = master_of(vm, str(j["place"]))
		if n == null or m == null or not n.has_meta("day_job_pos"):
			continue
		if n.is_sleeping or n.is_downed or int(n.current_activity) != 0 or n.global_position.distance_to(n.get_meta("day_job_pos")) > SPOT_RADIUS:
			continue
		j["hours"] = int(j["hours"]) + 1
		var acc: Dictionary = st["acc"]
		for item in (PLACES[str(j["place"])]["yield"] as Dictionary).keys():
			var ak: String = str(j["place"]) + ":" + str(item)
			acc[ak] = float(acc.get(ak, 0.0)) + float(PLACES[str(j["place"])]["yield"][item])
			while float(acc[ak]) >= 1.0:
				acc[ak] = float(acc[ak]) - 1.0
				if int(m.shop_stock.get(item, 0)) < STOCK_CAP:
					m.shop_stock[item] = int(m.shop_stock.get(item, 0)) + 1
					m._sync_shop_stock_to_vm()

## 18 h: cada uno cobra sus horas. Si el dueño no llega, paga lo que puede y el jornalero se enfada.
static func pay(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	var res: Dictionary = {"paid": 0, "unpaid": 0}
	var by_key: Dictionary = {}
	for n in VillageNeeds.living(vm):
		by_key[n.get_person_key()] = n
	for pk in (st["jobs"] as Dictionary).keys():
		var j: Dictionary = st["jobs"][pk]
		var n = by_key.get(pk)
		if n == null:
			continue
		var m = vm.trade_npcs.get(VillageTrades.role_of(str(j["place"])))
		var owed: int = int(j["hours"]) * WAGE_PER_HOUR
		var given: int = 0
		if m != null and is_instance_valid(m) and not m.is_dead:
			given = mini(owed, maxi(0, m.personal_gold))
			m.personal_gold -= given
		n.personal_gold = maxi(0, n.personal_gold) + given
		res["paid"] = int(res["paid"]) + given
		if given < owed:
			res["unpaid"] = int(res["unpaid"]) + (owed - given)
			n.add_thought("No me pagaron el jornal entero (-8)", -8.0)
			if m != null and is_instance_valid(m) and not m.is_dead:
				n.modify_npc_relationship(m, -6, "Me dejó a deber el jornal", true)
		elif owed > 0:
			n.add_thought("Cobré mi jornal (+4)", 4.0)
			if m != null and is_instance_valid(m):
				n.modify_npc_relationship(m, 1, "Me da trabajo", true)
		_release(n)
	st["paid_total"] = int(st["paid_total"]) + int(res["paid"])
	st["unpaid_total"] = int(st["unpaid_total"]) + int(res["unpaid"])
	st["jobs"] = {}
	return res

## Al cargar: los jornales del día se cancelan (las marcas de los vecinos no se guardan).
static func after_load(vm) -> void:
	for n in VillageNeeds.living(vm):
		_release(n)
	state(vm)["jobs"] = {}

# ---------------------------------------------------------------- lavadero
static func wash_spot(_vm, npc, default_spot: Vector2) -> Vector2:
	var lav: Vector2 = _AN_SITIOS.mover(LAVADERO_POS)
	if npc.global_position.distance_to(lav) < 700.0 and randf() < LAVADERO_CHANCE:
		return lav + Vector2(randf_range(-10, 10), 12)
	return default_spot

## Al terminar de lavarse en el lavadero, charla con quien esté allí.
static func on_washed(vm, n) -> void:
	var lav: Vector2 = _AN_SITIOS.mover(LAVADERO_POS)
	if n.global_position.distance_to(lav) > LAVADERO_GOSSIP_RADIUS:
		return
	for o in VillageNeeds.living(vm):
		if o != n and o.global_position.distance_to(lav) <= LAVADERO_GOSSIP_RADIUS:
			n.modify_npc_relationship(o, 1, "Coincidimos en el lavadero", true)
			var r: Dictionary = vm.VillageSocialLife.spread_gossip(vm, n, o)
			if not r.is_empty():
				state(vm)["lavadero_gossip"] = int(state(vm)["lavadero_gossip"]) + 1
			return
