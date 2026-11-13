@tool
extends RefCounted

## V5b: edificios del pueblo en los solares (nombres provisionales, en docs/APORTES_CREATIVOS.md).
## - Ayuntamiento (solar n4): allí se vota y se guardan las arcas. El día de elecciones los vecinos van EN PERSONA a
##   votar cuando están libres; quien no va (trabaja hasta tarde, está enfermo, no le apetece) no vota. El alcalde pasa
##   el sábado por la tarde a cuadrar las cuentas. Las arcas están en un cofre que se puede forzar: si faltan monedas, al
##   día siguiente se sabe y el alcalde queda mal.
## - Albergue del Alba (solar e4), de la capilla: quien se queda sin dinero duerme allí bajo techo (si hay cama) en vez
##   de a la intemperie; descansa mejor, está menos desesperado y coge aprecio al sacerdote.
## - El Candil (solar e2): posada humilde (3 de oro la noche). Quien no puede pagar El Jabalí Dorado se aloja allí antes
##   de acabar en la calle. La lleva un posadero que llega como cualquier otro oficio vacante.

const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const Marca = preload("res://mapa/marca.gd")
const Edificio = preload("res://mapa/edificio.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")

const HALL_LOT: String = "n4"
const SHELTER_LOT: String = "e4"
const INN_LOT: String = "e2"
const HALL_TITLE: String = "🏛️ Ayuntamiento del Valle"
const SHELTER_TITLE: String = "🕯️ Albergue del Alba"
const INN_TITLE: String = "🕯️ Posada Humilde 'El Candil'"
const INN_FAMILY: String = "family_candil"
const INN_RENT: int = 3
const VOTE_HOURS: Vector2i = Vector2i(9, 21) # Se puede ir a votar de 9 a 20; a las 21 se cuenta
const MAYOR_OFFICE_HOUR: int = 14 # Sábado por la tarde (los talleres cierran a las 13)

# ---------------------------------------------------------------- montaje
static func setup_world(vm) -> void:
	var lay: Dictionary = VillageLots.shop_house_layout_mundo(VillageLots.shop_house_id(INN_FAMILY))
	vm.trade_configs[VillageNPC.TradeRole.LODGEKEEPER] = {
		"family_id": INN_FAMILY, "family_name": "Casa del Candil", "shop_title": INN_TITLE,
		"shop_center": VillageLots.lot_def(INN_LOT)["center"], "is_mixed_building": true,
		"house_title": INN_TITLE, "house_center": VillageLots.lot_def(INN_LOT)["center"],
		"title": "Posadero", "tex": vm._load_tex("res://assests/world/village/villager_innkeeper.png"),
		"stock": {"country_stew": 3}, "work_pos": lay["work_pos"], "bed1_pos": lay["bed1_pos"],
		"bed2_pos": lay["bed2_pos"], "table_pos": lay["table_pos"],
	}
	if not vm.house_pantry.has(INN_FAMILY):
		vm.house_pantry[INN_FAMILY] = 2
	ensure_lots(vm)

static func ensure_lots(vm) -> void:
	for e in [[HALL_LOT, "civic", HALL_TITLE], [SHELTER_LOT, "shelter", SHELTER_TITLE], [INN_LOT, "inn", INN_TITLE]]:
		var st: Dictionary = VillageLots.lot(vm, e[0])
		st["status"] = "built"
		st["kind"] = e[1]
		st["progress"] = 1.0
		st["title"] = e[2]
		if e[1] == "inn":
			st["role"] = int(VillageNPC.TradeRole.LODGEKEEPER)
			st["family_id"] = INN_FAMILY

## Sitios del ayuntamiento y del albergue: son marcas de sus escenas (mapa/marca.gd), ya en el mundo.
const HALL_ID: String = "building_town_hall"
const SHELTER_ID: String = "building_shelter"
const HALL_MARKS: Dictionary = {"desk": Marca.MESA, "ballot": "urna", "coffers": Marca.COFRE, "mayor": "alcalde"}
const SHELTER_BED_MARK: String = "cama_%d"
const SHELTER_BEDS: int = 4

static func hall_spots() -> Dictionary:
	var out: Dictionary = {}
	for sitio: String in HALL_MARKS:
		out[sitio] = hall_spot(sitio)
	return out

## Un sitio del ayuntamiento («desk», «ballot», «coffers», «mayor»); `desfase` en su plano (gira con el edificio).
static func hall_spot(sitio: String, desfase: Vector2 = Vector2.ZERO) -> Vector2:
	return Marca.mundo(HALL_ID, HALL_MARKS[sitio], desfase)

static func shelter_beds() -> Array:
	var out: Array = []
	for i in range(1, SHELTER_BEDS + 1):
		out.append(Marca.mundo(SHELTER_ID, SHELTER_BED_MARK % i))
	return out

## Camas para huéspedes de la posada: la segunda de la casa y dos más (marcas de su escena), ya en el mundo.
const INN_GUEST_MARK: String = "cama_huesped_%d"
const INN_EXTRA_BEDS: int = 2

static func inn_guest_beds() -> Array:
	var id: String = VillageLots.shop_house_id(INN_FAMILY)
	var out: Array = [Marca.mundo(id, Marca.CAMA_2)]
	for i in range(1, INN_EXTRA_BEDS + 1):
		out.append(Marca.mundo(id, INN_GUEST_MARK % i))
	return out

## Dibujo de cada clase (lo llama VillageLots._build_kind).
static func build(vm, id: String, st: Dictionary) -> void:
	var d: Dictionary = VillageLots.lot_def(id)
	var c: Vector2 = d["center"]
	match str(st["kind"]):
		"civic":
			vm._construct_solid_building(HALL_ID, HALL_TITLE, c,
				"res://assests/world/village/floor_stone_forge.png", "res://assests/world/village/wall_stone_h.png", "res://assests/world/village/wall_stone_v.png")
			vm.cofre_mundo(hall_spot("coffers"), "Arcas del Pueblo", "town_hall", Edificio.giro_plano(HALL_ID))
		"shelter":
			vm._construct_solid_building(SHELTER_ID, SHELTER_TITLE, c,
				"res://assests/world/village/floor_wood_planks.png", "res://assests/world/village/wall_timber_h.png", "res://assests/world/village/wall_timber_v.png")
		"inn":
			VillageLots._build_shop_house(vm, id, st)

# ---------------------------------------------------------------- elecciones en persona
## VillageTown la llama cuando tocan elecciones normales: hoy se vota en el ayuntamiento.
static func open_voting(vm) -> void:
	var ts: Dictionary = vm.town_state
	ts["voting_day"] = VillageNeeds.today()
	ts["voted"] = []
	vm.VillageChronicle.add(vm, "election_call", "Hoy hay elecciones: los vecinos van al ayuntamiento a votar", true)

static func is_voting_today(vm) -> bool:
	return int(vm.town_state.get("voting_day", -1)) == VillageNeeds.today()

static func on_hour(vm, hour: int) -> void:
	if hour == RATION_HOUR:
		cook_shelter_rations(vm)
	if vm != null and vm.has_method("is_demo_mode") and bool(vm.call("is_demo_mode")):
		return
	if is_voting_today(vm):
		if hour >= VOTE_HOURS.x and hour < VOTE_HOURS.y:
			_send_voters(vm, hour)
		elif hour == VOTE_HOURS.y:
			close_voting(vm)
	if hour == MAYOR_OFFICE_HOUR and WorldClock != null and WorldClock.has_method("get_weekday") and int(WorldClock.get_weekday()) == 5:
		var mayor = vm.VillageTown.mayor_of(vm)
		if mayor != null and VillageNeeds.is_free(mayor):
			mayor.start_errand("mayor_office", hall_spot("mayor"))

static func _send_voters(vm, hour: int) -> void:
	var voted: Array = vm.town_state.get("voted", [])
	var ballot: Vector2 = hall_spot("ballot")
	for n in VillageNeeds.living(vm):
		if n.get_person_key() in voted or not VillageNeeds.is_free(n) or (n.person_profile != null and int(n.person_profile.age) < 16):
			continue
		# Por la tarde, al salir del trabajo, va más gente; los que no se fían de nada a veces ni van
		var ch: float = 0.55 if hour >= 16 else 0.25
		if "Desconfiado" in (n.person_profile.personality if n.person_profile != null else []):
			ch *= 0.6
		if randf() < ch:
			n.start_errand("vote", ballot + Vector2(randf_range(-10, 10), randf_range(4, 14)))

static func close_voting(vm) -> Dictionary:
	var ts: Dictionary = vm.town_state
	ts["voting_day"] = -1
	var voters: Array = []
	for n in VillageNeeds.living(vm):
		if n.get_person_key() in (ts.get("voted", []) as Array):
			voters.append(n)
		if n.errand_kind == "vote":
			n.end_errand()
	return vm.VillageTown.hold_election(vm, "", voters)

## VillageNeeds.tick: un encargo de los de aquí que ha llegado a su sitio.
static func on_errand_arrived(vm, n) -> void:
	match n.errand_kind:
		"vote":
			var voted: Array = vm.town_state.get("voted", [])
			if not n.get_person_key() in voted:
				voted.append(n.get_person_key())
				vm.town_state["voted"] = voted
			n._spawn_floating_text("🗳️", Color(1.0, 0.92, 0.6), -30.0)
			n.end_errand()
		"mayor_office":
			n.add_thought("Cuadró las cuentas del pueblo (+3)", 3.0)
			n.end_errand()

# ---------------------------------------------------------------- arcas
## Al forzar el cofre de las arcas: el botín sale de las arcas de verdad.
static func rob_coffers(vm) -> int:
	var ts: Dictionary = vm.town_state
	var take: int = mini(int(ts.get("treasury", 0)), randi_range(25, 60))
	ts["treasury"] = int(ts.get("treasury", 0)) - take
	ts["coffers_missing"] = int(ts.get("coffers_missing", 0)) + take
	return take

## Cada día: si faltan monedas en las arcas, se descubre y el alcalde queda en entredicho.
static func daily(vm) -> void:
	var ts: Dictionary = vm.town_state
	var miss: int = int(ts.get("coffers_missing", 0))
	if miss > 0:
		ts["coffers_missing"] = 0
		vm.VillageChronicle.add(vm, "coffers_robbed", "Faltan %d monedas en las arcas del ayuntamiento" % miss, true)
		var mayor = vm.VillageTown.mayor_of(vm)
		if mayor != null:
			mayor.add_thought("Han robado en las arcas que yo guardo (-10)", -10.0)
			for o in VillageNeeds.living(vm):
				if o != mayor and randf() < 0.3:
					o.modify_npc_relationship(mayor, -3, "¿Cómo deja que roben las arcas?", true)
	# Albergue: quien duerme allí coge aprecio al sacerdote que lo lleva
	var priest = vm.VillageFaith.priest_of(vm)
	if priest != null:
		for n in VillageNeeds.living(vm):
			if n.in_shelter:
				n.modify_npc_relationship(priest, 2, "Me da techo en el Albergue del Alba", true)

# ---------------------------------------------------------------- albergue y El Candil
## J4: cada mañana el cura del albergue prepara gachas para los pobres (pagadas por las arcas). Son el último recurso
## antes de pasar hambre: 1 de oro, o gratis si no tienes nada.
const RATION_HOUR: int = 6
const RATION_COST_TOWN: int = 2
const RATION_PRICE: int = 1
const RATION_EXTRA: int = 2
const RATION_MAX: int = 8

static func cook_shelter_rations(vm) -> int:
	var ts: Dictionary = vm.town_state
	if vm.VillageFaith.priest_of(vm) == null or str(VillageLots.lot(vm, SHELTER_LOT).get("status", "")) != "built":
		ts["shelter_rations"] = 0
		return 0
	var poor: int = 0
	for n in VillageNeeds.living(vm):
		if VillageNeeds.class_of(n) in ["pobre", "mendigo"]:
			poor += 1
	var want: int = mini(RATION_MAX, poor + RATION_EXTRA)
	var afford: int = int(float(ts.get("treasury", 0)) / float(RATION_COST_TOWN))
	var made: int = mini(want, afford)
	ts["treasury"] = int(ts.get("treasury", 0)) - made * RATION_COST_TOWN
	ts["shelter_rations"] = made # lo que sobra del día anterior no se guarda
	return made

static func take_shelter_ration(vm, npc) -> bool:
	var ts: Dictionary = vm.town_state
	if int(ts.get("shelter_rations", 0)) <= 0:
		return false
	ts["shelter_rations"] = int(ts["shelter_rations"]) - 1
	ts["rations_served"] = int(ts.get("rations_served", 0)) + 1
	var paid: String = "gratis"
	if npc.personal_gold >= RATION_PRICE:
		npc.personal_gold -= RATION_PRICE
		ts["treasury"] = int(ts.get("treasury", 0)) + RATION_PRICE
		paid = "-%d Oro" % RATION_PRICE
	npc.add_thought("Comió gachas en el Albergue del Alba (+2)", 2.0)
	npc._spawn_floating_text("🥣 Gachas del Albergue (%s)" % paid, Color(0.9, 0.85, 1.0), -32.0)
	return true

static func free_shelter_bed(vm) -> Vector2:
	var used: Array = []
	for n in VillageNeeds.living(vm):
		if n.in_shelter:
			used.append(n.bed_position)
	for b in shelter_beds():
		if not b in used:
			return b
	return Vector2.ZERO

## Desde evict_npc_to_vagrant_camp: si hay cama en el albergue, duerme allí.
static func try_shelter(vm, npc) -> bool:
	var b: Vector2 = free_shelter_bed(vm)
	if b == Vector2.ZERO:
		return false
	npc.is_vagrant_camper = true
	npc.in_shelter = true
	npc.lodging = ""
	npc.bed_position = b
	if vm.vagrant_camp_nodes.has(npc.npc_name) and is_instance_valid(vm.vagrant_camp_nodes[npc.npc_name]):
		vm.vagrant_camp_nodes[npc.npc_name].visible = false
	npc.add_thought("Sin dinero, pero con techo en el Albergue del Alba (-3)", -3.0)
	npc._spawn_floating_text("🕯️ Sin oro para la posada: duerme en el Albergue del Alba", Color(0.9, 0.85, 1.0), -38.0)
	return true

static func lodge_role() -> int:
	return int(VillageNPC.TradeRole.LODGEKEEPER)

static func inn_keeper(vm):
	var k = vm.trade_npcs.get(VillageNPC.TradeRole.LODGEKEEPER)
	if k != null and is_instance_valid(k) and not k.is_dead and not k.is_downed:
		return k
	return null

static func free_inn_bed(vm) -> Vector2:
	var used: Array = []
	for n in VillageNeeds.living(vm):
		if n.lodging == "candil":
			used.append(n.bed_position)
	for b in inn_guest_beds():
		if not b in used:
			return b
	return Vector2.ZERO

## Cobro nocturno de un huésped sin oficio. Devuelve true si este módulo se ha ocupado de él (se aloja o sigue en El
## Candil); false si debe seguir la regla de siempre (El Jabalí Dorado o la calle).
static func nightly_guest(vm, guest, tavern_rent: int) -> bool:
	var keeper = inn_keeper(vm)
	if guest.lodging == "candil":
		if keeper != null and guest.personal_gold >= INN_RENT:
			guest.personal_gold -= INN_RENT
			keeper.personal_gold = maxi(0, keeper.personal_gold) + INN_RENT
			return true
		guest.lodging = ""
		return false # Sin dinero ni para El Candil: la regla de siempre le saca a la calle (o al albergue)
	if guest.is_vagrant_camper or guest.personal_gold >= tavern_rent or keeper == null or guest.personal_gold < INN_RENT:
		return false
	var b: Vector2 = free_inn_bed(vm)
	if b == Vector2.ZERO:
		return false
	guest.personal_gold -= INN_RENT
	keeper.personal_gold = maxi(0, keeper.personal_gold) + INN_RENT
	guest.lodging = "candil"
	guest.bed_position = b
	guest.add_thought("No llega para El Jabalí; duerme en El Candil (-2)", -2.0)
	guest._spawn_floating_text("🕯️ Se aloja en El Candil (-%d Oro)" % INN_RENT, Color(1.0, 0.85, 0.5), -34.0)
	return true
