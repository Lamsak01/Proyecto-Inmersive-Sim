@tool
extends RefCounted

## V6: los nobles.
## - El **señor del valle** vive con su pareja y su heredero en una mansión apartada (solar f1, loma del este). Una
##   familia rica de rentistas vive en una casa grande en la loma del norte (solar f2). Oficio nuevo `NOBLE`: no
##   trabajan con las manos; entre semana, de 10 a 13 h, administran sus tierras en casa y el resto del día es suyo.
## - **Rentas**: los lunes el señor cobra a quien lleva la granja y el rancho (las tierras son suyas). Paga más quien
##   más tiene; quien paga le coge algo de manía y quien no puede pagar se gana la suya. Si el señor muere, cobra el
##   siguiente de su casa; si no queda nadie, las tierras se quedan sin señor.
## - **Elecciones**: quien vive de las tierras del señor (los dueños de la granja y el rancho y sus jornaleros) tira
##   hacia el candidato que prefiere el señor.
## - Son ricos: entran solos en la secta de «ricos aburridos» (VillageSect) y pagan los impuestos de rico.
## Estado en `vm.nobility_state` (se guarda). Llegan una sola vez, en la primera hora de juego (también en partidas
## guardadas antes de V6). Nombres provisionales (docs/APORTES_CREATIVOS.md).

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const Marca = preload("res://mapa/marca.gd")
const VillageTrades = preload("res://scripts/systems/VillageTrades.gd")
const PersonProfile = preload("res://scripts/data/PersonProfile.gd")

const MANSION_LOT: String = "f1"
const MANOR_LOT: String = "f2"
const MANSION_TITLE: String = "🏰 Mansión del Señor del Valle"
const MANOR_TITLE: String = "🏛️ Casa Grande de los Rentistas"
const MANSION_FAMILY: String = "family_lord"
const MANOR_FAMILY: String = "family_rentiers"
const HOUSEHOLDS: Dictionary = {
	MANSION_LOT: {"family": MANSION_FAMILY, "name": "Casa del Señor", "members": [
		{"label": "Señor del Valle", "gold": Vector2i(380, 460), "age": Vector2i(46, 62), "lord": true},
		{"label": "Señora del Valle", "gold": Vector2i(140, 200), "age": Vector2i(40, 58)},
		{"label": "Heredero del Valle", "gold": Vector2i(60, 110), "age": Vector2i(18, 26)}]},
	MANOR_LOT: {"family": MANOR_FAMILY, "name": "Casa de los Rentistas", "members": [
		{"label": "Rentista", "gold": Vector2i(200, 260), "age": Vector2i(38, 60)},
		{"label": "Rentista", "gold": Vector2i(170, 230), "age": Vector2i(34, 58)}]},
}
const TENANT_KEYS: Array = ["farmer", "rancher"]
const RENT_WEEKDAY: int = 0 # Lunes
const RENT_SHARE: float = 0.1
const RENT_MIN: int = 3
const RENT_MAX: int = 20
const SWAY_BONUS: float = 25.0

static func state(vm) -> Dictionary:
	if not vm.nobility_state is Dictionary:
		vm.nobility_state = {}
	var defs: Dictionary = {"spawned": false, "lord": "", "rents_paid": 0, "rents_unpaid": 0, "last_rent_day": -1}
	for k in defs.keys():
		if not vm.nobility_state.has(k):
			vm.nobility_state[k] = defs[k]
	return vm.nobility_state

static func noble_role() -> int:
	return int(VillageNPC.TradeRole.NOBLE)

static func is_noble(n) -> bool:
	return int(n.trade_role) == noble_role()

# ---------------------------------------------------------------- mapa
static func ensure_lots(vm) -> void:
	for e in [[MANSION_LOT, "mansion", MANSION_TITLE], [MANOR_LOT, "manor", MANOR_TITLE]]:
		var st: Dictionary = VillageLots.lot(vm, e[0])
		st["status"] = "built"
		st["kind"] = e[1]
		st["progress"] = 1.0
		st["title"] = e[2]

static func _m(id: String) -> float:
	return -1.0 if bool(VillageLots.lot_def(id)["door_south"]) else 1.0

## Camas, despacho, mesa y cofre: marcas de la escena de cada casa (mapa/marca.gd), en el mapa original.
const BUILDING_IDS: Dictionary = {MANSION_LOT: "building_mansion", MANOR_LOT: "building_manor"}
const BED_COUNT: Dictionary = {MANSION_LOT: 3, MANOR_LOT: 2}
const BED_MARK: String = "cama_%d"

static func beds(id: String) -> Array:
	var out: Array = []
	for i in range(1, int(BED_COUNT[id]) + 1):
		out.append(Marca.sitio(BUILDING_IDS[id], BED_MARK % i))
	return out

static func study_pos(id: String) -> Vector2:
	return Marca.sitio(BUILDING_IDS[id], Marca.DESPACHO)

static func table_pos(id: String) -> Vector2:
	return Marca.sitio(BUILDING_IDS[id], Marca.MESA)

static func build(vm, id: String, st: Dictionary) -> void:
	var d: Dictionary = VillageLots.lot_def(id)
	var c: Vector2 = VillageLots.building_center(id)
	var props: String = "res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/"
	var big: bool = str(st["kind"]) == "mansion"
	vm._construct_solid_building(BUILDING_IDS[id], str(st["title"]), c, Vector2(180, 120) if big else Vector2(150, 104),
		bool(d["door_south"]), "res://assests/world/village/floor_stone_forge.png", "res://assests/world/village/wall_stone_h.png",
		"res://assests/world/village/wall_stone_v.png", 48.0, 0.0, Color(1.0, 0.84, 0.5) if big else Color(0.95, 0.88, 0.7))
	var tex_bed: Texture2D = vm._load_tex("res://assests/world/village/tavern_bed.png")
	for b in beds(id):
		vm._add_sprite_prop(tex_bed, b, Vector2(1.2, 1.2), -1)
	vm._spawn_decor_prop(props + "table_chairs_1.png", table_pos(id), Vector2(0.5, 0.5))
	vm._add_rect_poly(study_pos(id), Vector2(12, 6), Color(0.40, 0.22, 0.12, 1.0), -1) # Escritorio
	var fam: String = MANSION_FAMILY if big else MANOR_FAMILY
	vm._spawn_house_chest(Marca.sitio(BUILDING_IDS[id], Marca.COFRE), "Cofre de " + str(HOUSEHOLDS[id]["name"]), fam)
	if not vm.house_pantry.has(fam):
		vm.house_pantry[fam] = 6

# ---------------------------------------------------------------- llegada
static func spawn_households(vm) -> Array:
	var st: Dictionary = state(vm)
	if bool(st["spawned"]):
		return []
	st["spawned"] = true
	var out: Array = []
	var log_size: int = vm.social_event_log.size()
	var tex: Texture2D = vm._load_tex("res://assests/world/village/villager_traveler.png")
	for id in HOUSEHOLDS.keys():
		var h: Dictionary = HOUSEHOLDS[id]
		var bl: Array = beds(id)
		var fam_people: Array = []
		for i in range((h["members"] as Array).size()):
			var spec: Dictionary = h["members"][i]
			var n = vm._spawn_generated_newcomer("NPC_Noble_", noble_role(), noble_role(), str(spec["label"]), tex,
				study_pos(id), bl[i % bl.size()], {}, table_pos(id), str(h["family"]), str(h["name"]))
			n.global_position = vm.sitio(bl[i % bl.size()] - Vector2(0, 14 * _m(id))) # Ya viven aquí: aparecen en casa
			n.personal_gold = randi_range(int(spec["gold"].x), int(spec["gold"].y))
			if n.person_profile != null:
				n.person_profile.age = randi_range(int(spec["age"].x), int(spec["age"].y))
			if bool(spec.get("lord", false)):
				st["lord"] = n.get_person_key()
			fam_people.append(n)
			out.append(n)
		for a in fam_people:
			for b in fam_people:
				if a != b:
					a.modify_npc_relationship(b, 55, "Somos de la misma casa", true)
		_marry(fam_people[0], fam_people[1])
	while vm.social_event_log.size() > log_size:
		vm.social_event_log.pop_back() # Ya vivían aquí: no «llegaron»
	vm.VillageChronicle.add(vm, "people", "En las lomas viven el señor del valle y una familia de rentistas: las tierras de labor son suyas", true)
	return out

static func _marry(a, b) -> void:
	if a.person_profile == null or b.person_profile == null:
		return
	a.person_profile.partner_id = str(b.person_profile.person_id)
	b.person_profile.partner_id = str(a.person_profile.person_id)
	a.person_profile.romance_status = PersonProfile.ROMANCE_PARTNERED
	b.person_profile.romance_status = PersonProfile.ROMANCE_PARTNERED

static func on_hour(vm, _hour: int) -> void:
	if not bool(state(vm)["spawned"]):
		spawn_households(vm)

# ---------------------------------------------------------------- señor y rentas
static func nobles(vm) -> Array:
	return VillageNeeds.living(vm).filter(func(n): return is_noble(n))

## El señor vivo (null si está herido); si murió o se fue, hereda el mayor de la mansión.
static func lord_of(vm):
	var st: Dictionary = state(vm)
	var heirs: Array = []
	for n in nobles(vm):
		if n.get_person_key() == str(st["lord"]):
			return null if n.is_downed else n
		if n.family_id == MANSION_FAMILY:
			heirs.append(n)
	if heirs.is_empty():
		return null # Las tierras se quedan sin señor
	heirs.sort_custom(func(a, b): return (a.person_profile.age if a.person_profile else 0) > (b.person_profile.age if b.person_profile else 0))
	var new_lord = heirs[0]
	st["lord"] = new_lord.get_person_key()
	new_lord.npc_role = "Señor del Valle"
	vm.VillageChronicle.add(vm, "people", "%s es ahora quien manda en las tierras del valle" % new_lord.npc_name, true)
	return null if new_lord.is_downed else new_lord

static func tenants(vm) -> Array:
	var out: Array = []
	for k in TENANT_KEYS:
		var t = vm.trade_npcs.get(VillageTrades.role_of(k))
		if t != null and is_instance_valid(t) and not t.is_dead:
			out.append(t)
	return out

static func rent_for(n) -> int:
	return clampi(int(float(n.personal_gold) * RENT_SHARE), RENT_MIN, RENT_MAX)

## Lunes: el señor cobra las rentas de las tierras.
static func collect_rents(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	var res: Dictionary = {"paid": 0, "unpaid": 0}
	var lord = lord_of(vm)
	if lord == null:
		return res
	for t in tenants(vm):
		var rent: int = rent_for(t)
		if t.personal_gold >= rent:
			t.personal_gold -= rent
			lord.personal_gold += rent
			res["paid"] = int(res["paid"]) + rent
			t.add_thought("Pagué la renta de las tierras (-2)", -2.0)
			t.modify_npc_relationship(lord, -2, "Me cobra la renta de las tierras", true)
		else:
			res["unpaid"] = int(res["unpaid"]) + rent
			t.add_thought("No llego a la renta del señor (-6)", -6.0)
			lord.modify_npc_relationship(t, -5, "No me pagó la renta", true)
			t.modify_npc_relationship(lord, -3, "Me aprieta con la renta", true)
	st["rents_paid"] = int(st["rents_paid"]) + int(res["paid"])
	st["rents_unpaid"] = int(st["rents_unpaid"]) + int(res["unpaid"])
	return res

static func daily(vm) -> void:
	var st: Dictionary = state(vm)
	var today: int = int(WorldClock.current_day) if WorldClock else 0
	if WorldClock != null and WorldClock.has_method("get_weekday") and int(WorldClock.get_weekday()) == RENT_WEEKDAY and int(st["last_rent_day"]) != today:
		st["last_rent_day"] = today
		collect_rents(vm)

# ---------------------------------------------------------------- elecciones
## ¿Vive este vecino de las tierras del señor? (dueños de la granja y el rancho y sus jornaleros)
static func depends_on_lord(vm, voter) -> bool:
	if voter in tenants(vm):
		return true
	var job = (vm.work_state.get("jobs", {}) as Dictionary).get(voter.get_person_key()) if vm.work_state is Dictionary else null
	return job != null and str(job.get("place", "")) in TENANT_KEYS

## El candidato que prefiere el señor (el que mejor le cae, o él mismo).
static func lord_favourite(vm, cands: Array):
	var lord = lord_of(vm)
	if lord == null or cands.is_empty():
		return null
	if lord in cands:
		return lord
	var best = null
	var best_s: float = -INF
	for c in cands:
		var s: float = float(lord.get_relationship_with_npc(c.get_person_key()))
		if s > best_s:
			best_s = s
			best = c
	return best

## VillageTown.vote_of: lo que pesa el señor en el voto de este vecino por este candidato.
static func sway(vm, voter, cand, cands: Array) -> float:
	if is_noble(voter) or not depends_on_lord(vm, voter):
		return 0.0
	return SWAY_BONUS if cand == lord_favourite(vm, cands) else 0.0
