@tool
extends RefCounted

## Paso 3: La Gran Posada, Taberna y Casino «El Jabalí Dorado» (2 pisos + sótano de peleas).
## - Primer edificio de 2 plantas reales:
##   - Planta 0 (`elevation_level = 0`):
##     1. `salon` (Gran Salón Comedor con 6 mesas y 12 sillas, chimenea y candelabros).
##     2. `barra_cocina` (Mostrador largo de caoba con Marta atendiendo detrás, pasa-platos de comandas, fogón y barriles).
##     3. `casino` (Sala de Póker con 4 sillas donde juegan los vecinos y Mesa de Billar 3D de verdad con troneras, bolas y tacos).
##     4. `escalera_bodega` (Vestíbulo con la gran escalera de madera al Piso +1 y la trampilla al Club de Peleas del Sótano -1).
##   - Planta +1 (`elevation_level = 1`, altura 3D `+22.0 px`):
##     - Galería / pasillo alto con barandilla de madera asomada al salón y 5 cuartos de huéspedes con camas reales:
##       Cuarto de Marta (`342, -252`), Aposento Real de Alistair (`400, -252`), Cuartos de Huéspedes (`435, -252`,
##       `468, -252`, `502, -252`) y Habitación de Alquiler del Jugador (`538, -252`).
## - Oficio `TradeRole.WAITER` (Camarero): se ocupa como cualquier vacante en `trade_configs`; camina entre las mesas
##   ocupadas y el pasa-platos de la barra tomando nota y llevando platos y jarras calientes.

const VillageNPC = preload("res://scripts/enemies/VillageNPC.gd")
const SimpleInventory = preload("res://scripts/systems/SimpleInventory.gd")
const WorldInteractableProp = preload("res://scripts/obstacles/WorldInteractableProp.gd")

const BUILDING_ID: String = "building_tavern"
const FAMILY_ID: String = "family_tavern"
const TITLE: String = "🍺 Gran Posada, Taberna y Casino 'El Jabalí Dorado'"

## Huella ampliada de 2 plantas (348 × 184 px), centrada en (434, -224), frente a la Avenida Norte-Sur.
const BASE: Vector2 = Vector2(260.0, -316.0)
const SIZE: Vector2 = Vector2(348.0, 184.0)
const RECT: Rect2 = Rect2(BASE, SIZE)
const CENTER: Vector2 = Vector2(434.0, -224.0)
const DOOR_POS: Vector2 = Vector2(434.0, -132.0)
const DOOR_W: float = 44.0

## Alturas 3D de la posada de 2 pisos
const FLOOR_1_H: float = 22.0
const TOTAL_WALL_H: float = 44.0

## Planta 0: 4 salas comunicadas por arcos anchos
const MID_WALL_Y: float = -232.0
const EAST_WING_X: float = 482.0
const GAP: float = 42.0
const ROOMS_FLOOR_0: Dictionary = {
	"barra_cocina": Rect2(Vector2(260.0, -316.0), Vector2(222.0, 84.0)),
	"salon": Rect2(Vector2(260.0, -232.0), Vector2(222.0, 100.0)),
	"casino": Rect2(Vector2(482.0, -232.0), Vector2(126.0, 100.0)),
	"escalera_bodega": Rect2(Vector2(482.0, -316.0), Vector2(126.0, 84.0)),
}

const OPENINGS_FLOOR_0: Array = [
	{"from": "salon", "to": "barra_cocina", "pos": Vector2(432.0, -232.0), "axis": "h", "width": 44.0},
	{"from": "salon", "to": "casino", "pos": Vector2(482.0, -182.0), "axis": "v", "width": 44.0},
	{"from": "casino", "to": "escalera_bodega", "pos": Vector2(534.0, -232.0), "axis": "h", "width": 40.0},
	{"from": "barra_cocina", "to": "escalera_bodega", "pos": Vector2(482.0, -276.0), "axis": "v", "width": 34.0},
]

## Puntos clave de Planta 0 (Salón, Barra, Cocina, Casino, Escalera y Trampilla)
const BAR_COUNTER_POS: Vector2 = Vector2(338.0, -234.0)
const BAR_COUNTER_SIZE: Vector2 = Vector2(108.0, 10.0)
const INNKEEPER_WORK_POS: Vector2 = Vector2(338.0, -248.0) # Marta detrás del mostrador
const PASS_COUNTER_POS: Vector2 = Vector2(396.0, -246.0)   # Pasa-platos donde el camarero recoge comandas
const BARREL_RACK_POS: Vector2 = Vector2(426.0, -304.0)    # Hilera de toneles de roble tras la barra
const STOVE_POS: Vector2 = Vector2(292.0, -296.0)          # Fogón y horno de la cocina
const PREP_POS: Vector2 = Vector2(346.0, -296.0)           # Mesa de corte de cocina
const FIREPLACE_POS: Vector2 = Vector2(270.0, -182.0)      # Chimenea de piedra del gran salón
const SOCIAL_POS: Vector2 = Vector2(420.0, -198.0)         # Mesa central de referencia del salón
const GAMES_POS: Vector2 = Vector2(518.0, -178.0)          # Mesa de Póker y Casino
const POOL_POS: Vector2 = Vector2(574.0, -178.0)           # Mesa de Billar 3D real
const WELL_POS: Vector2 = Vector2(228.0, -230.0)           # Pozo en el patio lateral oeste

## Escalera real entre Planta 0 y Planta +1 y Trampilla al Sótano (-1)
const STAIRS_BOTTOM_POS: Vector2 = Vector2(576.0, -284.0)  # Pie de la escalera en Planta 0 (sala noreste)
const STAIRS_TOP_POS: Vector2 = Vector2(576.0, -202.0)     # Desembarco de la escalera en Planta +1 (galería alta)
const STAIRS_PROP_POS: Vector2 = Vector2(576.0, -244.0)    # Punto interactivo [E] de la escalera
const STAIRS_RAMP_RECT: Rect2 = Rect2(Vector2(558.0, -292.0), Vector2(36.0, 96.0))

## 6 Mesas del Gran Salón Comedor (Planta 0) con 2 sillas cada una (12 plazas sentadas)
const DINING_TABLES: Array = [
	Vector2(296.0, -198.0),
	Vector2(358.0, -198.0),
	Vector2(420.0, -198.0),
	Vector2(296.0, -158.0),
	Vector2(358.0, -158.0),
	Vector2(454.0, -198.0),
]
const CHAIR_OFFSETS: Array = [Vector2(-13.0, 0.0), Vector2(13.0, 0.0)]

## 4 Sillas alrededor de la Mesa de Póker (Planta 0: Oeste, Este, Norte, Sur)
const POKER_CHAIR_OFFSETS: Array = [
	Vector2(-16.0, 0.0),
	Vector2(16.0, 0.0),
	Vector2(0.0, -13.0),
	Vector2(0.0, 13.0),
]
const POKER_CHAIRS: Array[Vector2] = [
	Vector2(502.0, -178.0),
	Vector2(534.0, -178.0),
	Vector2(518.0, -191.0),
	Vector2(518.0, -165.0),
]

## Planta +1: 5 Cuartos de Huéspedes en el ala norte (`y = -316..-216`) + Galería alta (`y = -216..-168`)
const HALLWAY_Y: float = -200.0
const BEDROOM_WALL_Y: float = -216.0
const MARTA_BED_POS: Vector2 = Vector2(342.0, -252.0)
const ALISTAIR_BED_POS: Vector2 = Vector2(400.0, -252.0)
const GUEST_BEDS: Array = [Vector2(435.0, -252.0), Vector2(468.0, -252.0), Vector2(502.0, -252.0)]
const PLAYER_BED_POS: Vector2 = Vector2(538.0, -252.0)
const ALL_UPPER_BEDS: Array = [
	Vector2(342.0, -252.0),
	Vector2(400.0, -252.0),
	Vector2(435.0, -252.0),
	Vector2(468.0, -252.0),
	Vector2(502.0, -252.0),
	Vector2(538.0, -252.0),
]
const BEDROOM_DOORS_X: Array = [342.0, 400.0, 451.0, 502.0, 538.0]
const BEDROOM_PARTITIONS_X: Array = [374.0, 418.0, 484.0, 520.0, 558.0]

const POKER_CALLOUTS: Array[String] = [
	"🃏 «Veo tus 5 monedas»",
	"🃏 «Subo la apuesta»",
	"🃏 «Doble pareja de reyes»",
	"🎲 «Paso esta ronda»",
	"🃏 «¡Escalera en el river!»",
	"🍺🃏 «Otra mano, que hoy tengo racha»",
]

# ------------------------------------------------------------------ montaje del mundo
static func setup_world(vm) -> void:
	vm._tavern_social_pos = SOCIAL_POS
	vm._tavern_games_pos = GAMES_POS
	vm._tavern_pool_pos = POOL_POS
	vm._tavern_bed_pos = PLAYER_BED_POS
	vm._tavern_well_pos = WELL_POS

	var tex_bed: Texture2D = vm._load_tex("res://assests/world/village/tavern_bed.png")
	var tex_stall: Texture2D = vm._load_tex("res://assests/world/village/work_stall.png")
	var tex_innkeeper: Texture2D = vm._load_tex("res://assests/world/village/villager_innkeeper.png")

	vm._construct_solid_building(
		BUILDING_ID, TITLE,
		CENTER, SIZE, true,
		"res://assests/world/village/floor_wood_planks.png",
		"res://assests/world/village/wall_timber_h.png",
		"res://assests/world/village/wall_timber_v.png",
		DOOR_W, 20.0, Color(1.0, 0.88, 0.45)
	)

	# Alfombra discreta bajo el salón del casino en Planta 0 (z_index = -2, bajo las mesas)
	var cas_rug: Polygon2D = vm._add_rect_poly(Vector2(543.0, -182.0), Vector2(52.0, 38.0), Color(0.44, 0.16, 0.14, 0.36), -2)
	cas_rug.add_to_group("tavern_floor0_2d")

	# Tabiques internos de Planta 0 (idénticos a los pasos de OPENINGS_FLOOR_0 en 2D y 3D)
	var tex_wall_h: Texture2D = vm._load_tex("res://assests/world/village/wall_timber_h.png")
	var tex_wall_v: Texture2D = vm._load_tex("res://assests/world/village/wall_timber_v.png")
	var part_segs: Array = [
		[Vector2(335.0, MID_WALL_Y), Vector2(150.0, 6.0), tex_wall_h],
		[Vector2(484.0, MID_WALL_Y), Vector2(60.0, 6.0), tex_wall_h],
		[Vector2(581.0, MID_WALL_Y), Vector2(54.0, 6.0), tex_wall_h],
		[Vector2(EAST_WING_X, -304.5), Vector2(6.0, 23.0), tex_wall_v],
		[Vector2(EAST_WING_X, -231.5), Vector2(6.0, 55.0), tex_wall_v],
		[Vector2(EAST_WING_X, -146.0), Vector2(6.0, 28.0), tex_wall_v],
	]
	for pseg in part_segs:
		var child_idx_before: int = vm.entities_root.get_child_count()
		vm._add_solid_wall_segment(pseg[0], pseg[1], pseg[2])
		if vm.entities_root.get_child_count() > child_idx_before:
			var sb_w: Node = vm.entities_root.get_child(vm.entities_root.get_child_count() - 1)
			sb_w.add_to_group("tavern_floor0_2d")
			sb_w.add_to_group("tavern_floor0_walls")

	# Mostrador largo de Marta y pasa-platos del camarero
	vm._add_rect_poly(BAR_COUNTER_POS, BAR_COUNTER_SIZE * 0.5, Color(0.42, 0.25, 0.12, 0.98), -1).add_to_group("tavern_floor0_2d")
	vm._add_sprite_prop(tex_stall, BAR_COUNTER_POS + Vector2(0.0, 4.0), Vector2(1.4, 1.2), -1).add_to_group("tavern_floor0_2d")

	# 6 Mesas de comedor y tertulia en el Gran Salón (Planta 0)
	for tp in DINING_TABLES:
		vm._add_rect_poly(tp, Vector2(11.0, 6.5), Color(0.54, 0.35, 0.18, 0.98), -1).add_to_group("tavern_floor0_2d")
		for off in CHAIR_OFFSETS:
			vm._add_rect_poly(tp + (off as Vector2), Vector2(3.5, 3.5), Color(0.38, 0.24, 0.12, 0.95), -1).add_to_group("tavern_floor0_2d")

	# 1. Mesa Verde de Póker / Blackjack / Ruleta con 4 sillas
	vm._add_rect_poly(GAMES_POS, Vector2(14.0, 10.0), Color(0.42, 0.26, 0.12, 1.0), -1).add_to_group("tavern_floor0_2d")
	vm._add_rect_poly(GAMES_POS, Vector2(11.5, 7.5), Color(0.10, 0.50, 0.25, 1.0), -1).add_to_group("tavern_floor0_2d")
	for chair_off in POKER_CHAIR_OFFSETS:
		vm._add_rect_poly(GAMES_POS + (chair_off as Vector2), Vector2(4.0, 4.0), Color(0.55, 0.36, 0.18, 0.95), -1).add_to_group("tavern_floor0_2d")

	vm._add_station_area("TavernGamesTableArea", GAMES_POS, 18.0, "tavern_games")
	vm._tavern_games_label = vm._make_station_label(GAMES_POS + Vector2(-120.0, -30.0), "🃏 Mesa de Póker y Casino [E: Jugar con Aldeanos]")
	vm.entities_root.add_child(vm._tavern_games_label)

	# 2. Mesa de Billar de la Posada
	vm._add_rect_poly(POOL_POS, Vector2(14.0, 8.5), Color(0.38, 0.22, 0.10, 1.0), -1).add_to_group("tavern_floor0_2d")
	vm._add_rect_poly(POOL_POS, Vector2(12.0, 6.5), Color(0.08, 0.48, 0.30, 1.0), -1).add_to_group("tavern_floor0_2d")
	vm._add_station_area("TavernPoolTableArea", POOL_POS, 18.0, "tavern_pool")
	vm._tavern_pool_label = vm._make_station_label(POOL_POS + Vector2(-115.0, -30.0), "🎱 Mesa de Billar [E: Jugar Billar de Posada]")
	vm.entities_root.add_child(vm._tavern_pool_label)

	# 3. Escalera de madera entre Planta 0 y Planta +1 (Cuartos de Huéspedes)
	for step_i in range(8):
		var sy: float = lerpf(STAIRS_BOTTOM_POS.y, STAIRS_TOP_POS.y, float(step_i) / 7.0)
		vm._add_rect_poly(Vector2(STAIRS_BOTTOM_POS.x, sy), Vector2(12.0, 2.5), Color(0.48, 0.31, 0.16, 0.95), -1).add_to_group("tavern_floor0_2d")
	var stairs_prop := WorldInteractableProp.new()
	stairs_prop.name = "Prop_Tavern_Stairs"
	stairs_prop.global_position = STAIRS_PROP_POS
	vm.entities_root.add_child(stairs_prop)
	stairs_prop.setup_prop(vm, "tavern_stairs", BUILDING_ID, "Escalera de la Posada")

	# 4. Camas de huéspedes en Planta +1 (2.º piso)
	for b_pos in ALL_UPPER_BEDS:
		var spr: Sprite2D = vm._add_sprite_prop(tex_bed, b_pos, Vector2(1.18, 1.18), -1)
		if spr != null:
			spr.add_to_group("tavern_upper_2d")

	vm._add_station_area("TavernPlayerBedArea", PLAYER_BED_POS, 14.0, "tavern_bed")
	vm._tavern_bed_label = vm._make_station_label(PLAYER_BED_POS + Vector2(-115.0, -28.0), "🛌 Cama de Posada (Piso +1) [E: Dormir hasta 06:00 (-8 Oro)]")
	vm.entities_root.add_child(vm._tavern_bed_label)

	vm._spawn_house_chest(Vector2(312.0, -256.0), "Cofre de la Posada El Jabalí", FAMILY_ID)

	# 5. Marta, la Tabernera y Chef, detrás del mostrador
	var marta := VillageNPC.new()
	marta.name = "NPC_Marta_Innkeeper"
	marta.npc_name = "Marta"
	marta.npc_role = "Chef y Posadera"
	marta.trade_role = VillageNPC.TradeRole.INNKEEPER
	marta.tavern_social_pos = SOCIAL_POS
	vm.entities_root.add_child(marta)
	marta.setup_npc(tex_innkeeper, INNKEEPER_WORK_POS, MARTA_BED_POS, {"country_stew": 6, "bread": 8, "roasted_chicken": 4}, SOCIAL_POS, FAMILY_ID, "Posada El Jabalí")
	vm._innkeeper_npc = marta

	# 6. Oficio nuevo: Camarero (`TradeRole.WAITER`), registrado en `trade_configs` para cubrirse como cualquier vacante
	var waiter_role: int = int(VillageNPC.TradeRole.WAITER)
	vm.trade_configs[waiter_role] = {
		"family_id": FAMILY_ID,
		"family_name": "Posada El Jabalí",
		"shop_title": "🍺 Servicio de Salón — El Jabalí Dorado",
		"shop_center": PASS_COUNTER_POS,
		"shop_door_south": true,
		"is_mixed_building": true,
		"house_title": TITLE,
		"house_center": GUEST_BEDS[1],
		"name": "Bastian",
		"title": "Camarero de Posada",
		"tex": vm._load_tex("res://assests/world/village/villager_traveler.png"),
		"stock": {"country_stew": 3, "bread": 4},
		"work_pos": PASS_COUNTER_POS,
		"bed1_pos": GUEST_BEDS[1],
		"bed2_pos": GUEST_BEDS[2],
		"table_pos": SOCIAL_POS,
	}
	var waiter_stall: Sprite2D = vm._add_sprite_prop(tex_stall, PASS_COUNTER_POS, Vector2(0.85, 0.85), -1)
	vm._register_shop_business_stall(waiter_role, "🍺 Servicio de Mesas 'El Jabalí Dorado'", FAMILY_ID, PASS_COUNTER_POS, waiter_stall)

# ------------------------------------------------------------------ asientos de comedor y póker
static func dining_seats() -> Array:
	var out: Array = []
	for tp in DINING_TABLES:
		for off in CHAIR_OFFSETS:
			out.append((tp as Vector2) + (off as Vector2))
	return out

static func poker_seats() -> Array:
	var out: Array = []
	for off in POKER_CHAIR_OFFSETS:
		out.append(GAMES_POS + (off as Vector2))
	return out

static func table_center_for_seat(seat: Vector2) -> Vector2:
	for tp in DINING_TABLES:
		if seat.distance_to(tp as Vector2) <= 20.0:
			return tp as Vector2
	if seat.distance_to(GAMES_POS) <= 22.0:
		return GAMES_POS
	return SOCIAL_POS

static func is_seat_taken(vm, pos: Vector2, ignore_npc = null) -> bool:
	if vm == null:
		return false
	for n in vm.VillageNeeds.living(vm):
		if n == ignore_npc:
			continue
		if n.global_position.distance_to(pos) <= 10.0:
			return true
		if ("_tavern_seat" in n and (n._tavern_seat as Vector2).distance_to(pos) <= 4.0):
			return true
		if n.errand_kind != "" and n.errand_pos.distance_to(pos) <= 8.0:
			return true
	return false

static func pick_seat_for(vm, npc) -> Vector2:
	var free: Array = []
	for s in dining_seats():
		if not is_seat_taken(vm, s, npc):
			free.append(s)
	if free.is_empty():
		return SOCIAL_POS
	return free[absi(npc.npc_name.hash() + int(Time.get_ticks_msec() / 1000)) % free.size()]

static func pick_poker_seat_for(vm, npc) -> Vector2:
	var free: Array = []
	for s in poker_seats():
		if not is_seat_taken(vm, s, npc):
			free.append(s)
	if free.is_empty():
		return Vector2.ZERO
	return free[absi(npc.npc_name.hash()) % free.size()]

# ------------------------------------------------------------------ navegación entre salas y entre pisos (Planta 0 y Planta +1)
static func is_upper_floor_target(pos: Vector2) -> bool:
	if not RECT.grow(6.0).has_point(pos):
		return false
	for b in ALL_UPPER_BEDS:
		if pos.distance_to(b as Vector2) <= 3.5:
			return true
	return false

static func room_at_floor_0(pos: Vector2) -> String:
	for id in ROOMS_FLOOR_0.keys():
		if (ROOMS_FLOOR_0[id] as Rect2).grow(2.0).has_point(pos):
			return id
	var best: String = "salon"
	var best_d: float = INF
	for id in ROOMS_FLOOR_0.keys():
		var d: float = pos.distance_to((ROOMS_FLOOR_0[id] as Rect2).get_center())
		if d < best_d:
			best_d = d
			best = id
	return best

static func _opening_between_floor_0(a: String, b: String) -> Dictionary:
	for o in OPENINGS_FLOOR_0:
		if (o["from"] == a and o["to"] == b) or (o["from"] == b and o["to"] == a):
			return o
	return {}

static func _next_room_floor_0(from_room: String, to_room: String) -> String:
	if from_room == to_room:
		return to_room
	var queue: Array = [from_room]
	var parent: Dictionary = {from_room: ""}
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		if cur == to_room:
			break
		for o in OPENINGS_FLOOR_0:
			var nb: String = ""
			if o["from"] == cur:
				nb = str(o["to"])
			elif o["to"] == cur:
				nb = str(o["from"])
			if nb != "" and not parent.has(nb):
				parent[nb] = cur
				queue.append(nb)
	if not parent.has(to_room):
		return to_room
	var step: String = to_room
	while parent.get(step, "") != "" and parent[step] != from_room:
		step = str(parent[step])
	return step

static func route_floor_0(from_pos: Vector2, target_pos: Vector2) -> Vector2:
	var a: String = room_at_floor_0(from_pos)
	var b: String = room_at_floor_0(target_pos)
	if a == b:
		return target_pos
	var next: String = _next_room_floor_0(a, b)
	var op: Dictionary = _opening_between_floor_0(a, next)
	if op.is_empty():
		return target_pos
	var p: Vector2 = op["pos"]
	var nr: Rect2 = ROOMS_FLOOR_0[next]
	if str(op["axis"]) == "h":
		var ny: float = p.y - 12.0 if nr.get_center().y < p.y else p.y + 12.0
		var sy: float = p.y + 12.0 if nr.get_center().y < p.y else p.y - 12.0
		return Vector2(p.x, sy if absf(from_pos.x - p.x) > 10.0 else ny)
	var nx: float = p.x - 12.0 if nr.get_center().x < p.x else p.x + 12.0
	var sx: float = p.x + 12.0 if nr.get_center().x < p.x else p.x - 12.0
	return Vector2(sx if absf(from_pos.y - p.y) > 10.0 else nx, p.y)

static func _bedroom_door_x_for(pos: Vector2) -> float:
	if pos.x < 374.0:
		return 342.0
	if pos.x < 418.0:
		return 400.0
	if pos.x < 484.0:
		return 451.0
	if pos.x < 520.0:
		return 502.0
	return 538.0

static func route_floor_1(from_pos: Vector2, target_pos: Vector2) -> Vector2:
	var in_room_from: bool = from_pos.y < BEDROOM_WALL_Y - 3.0 and from_pos.x < 558.0
	var in_room_to: bool = target_pos.y < BEDROOM_WALL_Y - 3.0 and target_pos.x < 558.0
	var door_from_x: float = _bedroom_door_x_for(from_pos)
	var door_to_x: float = _bedroom_door_x_for(target_pos)
	if in_room_from and (not in_room_to or absf(door_from_x - door_to_x) > 5.0):
		if absf(from_pos.x - door_from_x) > 8.0:
			return Vector2(door_from_x, from_pos.y)
		return Vector2(door_from_x, HALLWAY_Y)
	if in_room_to and not in_room_from:
		if absf(from_pos.x - door_to_x) > 9.0:
			return Vector2(door_to_x, HALLWAY_Y)
		return target_pos
	return target_pos

## Ruta completa dentro de la taberna teniendo en cuenta las dos plantas (0 y +1) y la escalera física.
static func route(from_pos: Vector2, target_pos: Vector2, agent: Node2D = null, vm = null) -> Vector2:
	var from_elev: int = 0
	if agent != null and "elevation_level" in agent:
		from_elev = int(agent.elevation_level)
	var to_elev: int = 1 if is_upper_floor_target(target_pos) else 0

	# Subir de Planta 0 a Planta +1 por la escalera
	if from_elev == 0 and to_elev == 1:
		if not STAIRS_RAMP_RECT.has_point(from_pos) and from_pos.distance_to(STAIRS_BOTTOM_POS) > 12.0:
			return route_floor_0(from_pos, STAIRS_BOTTOM_POS)
		if from_pos.distance_to(STAIRS_TOP_POS) > 10.0:
			return STAIRS_TOP_POS
		if agent != null and vm != null and vm.has_method("set_npc_elevation_level"):
			vm.call("set_npc_elevation_level", agent, 1)
		return route_floor_1(from_pos, target_pos)

	# Bajar de Planta +1 a Planta 0 por la escalera
	if from_elev == 1 and to_elev == 0:
		if not STAIRS_RAMP_RECT.has_point(from_pos) and from_pos.distance_to(STAIRS_TOP_POS) > 12.0:
			return route_floor_1(from_pos, STAIRS_TOP_POS)
		if from_pos.distance_to(STAIRS_BOTTOM_POS) > 10.0:
			return STAIRS_BOTTOM_POS
		if agent != null and vm != null and vm.has_method("set_npc_elevation_level"):
			vm.call("set_npc_elevation_level", agent, 0)
		return route_floor_0(from_pos, target_pos)

	if from_elev == 1:
		return route_floor_1(from_pos, target_pos)
	return route_floor_0(from_pos, target_pos)

## Altura 3D adicional (`0..22 px`) para quien sube/baja la escalera o está en la Planta +1.
static func elevation_height_for(pos: Vector2, elev_level: int) -> float:
	if RECT.grow(10.0).has_point(pos) and STAIRS_RAMP_RECT.has_point(pos):
		var t: float = clampf((pos.y - STAIRS_BOTTOM_POS.y) / maxf(1.0, STAIRS_TOP_POS.y - STAIRS_BOTTOM_POS.y), 0.0, 1.0)
		return t * FLOOR_1_H
	return FLOOR_1_H if elev_level == 1 else 0.0

## Interacción con la escalera [E] para el jugador (subir al Piso +1 o bajar al Salón Planta 0).
static func stairs_label(vm) -> String:
	if vm != null and int(vm.player_elevation_level) == 1:
		return "🪜🍺 Bajar escalera al Gran Salón de la Taberna (Planta 0)"
	return "🪜🛌 Subir escalera a los Cuartos de Huéspedes (Planta +1)"

static func use_stairs(vm, player: Node2D) -> void:
	if vm == null or player == null:
		return
	if int(vm.player_elevation_level) == 1:
		player.global_position = STAIRS_BOTTOM_POS + Vector2(-12.0, 6.0)
		vm.set_player_elevation_level(0)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🪜🍺 Bajaste al Gran Salón (Planta 0)", Color(0.95, 0.85, 0.55), -38.0)
	else:
		player.global_position = STAIRS_TOP_POS + Vector2(-12.0, 4.0)
		vm.set_player_elevation_level(1)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🪜🛌 Subiste a los Cuartos de Huéspedes (Planta +1)", Color(0.85, 0.95, 1.0), -38.0)

# ------------------------------------------------------------------ rutina del Camarero (`TradeRole.WAITER`)
static func tick_waiter(vm, waiter, delta: float) -> void:
	if vm == null or waiter == null or not is_instance_valid(waiter):
		return
	if int(waiter.elevation_level) != 0 and RECT.grow(8.0).has_point(waiter.global_position):
		var wp_down: Vector2 = route(waiter.global_position, PASS_COUNTER_POS, waiter, vm)
		waiter._approach_or_stop(wp_down, 6.0, 46.0, delta)
		return

	var step: String = str(waiter.get_meta("waiter_step", "idle"))
	var timer: float = maxf(0.0, float(waiter.get_meta("waiter_timer", 0.0)) - delta)
	waiter.set_meta("waiter_timer", timer)

	if step == "idle":
		var customer = _pick_unserved_customer(vm, waiter)
		if customer != null:
			waiter.set_meta("waiter_step", "take_order")
			waiter.set_meta("waiter_target_key", customer.get_person_key())
			waiter.set_meta("waiter_target_pos", customer.global_position + Vector2(0.0, 10.0))
			waiter.set_meta("waiter_timer", 0.0)
			return
		# Patrulla entre el pasa-platos y las mesas del salón limpiando jarras
		var patrol_pts: Array = [PASS_COUNTER_POS, DINING_TABLES[0] + Vector2(0, 10), DINING_TABLES[2] + Vector2(0, 10), DINING_TABLES[4] + Vector2(0, 10)]
		var p_idx: int = int(waiter.get_meta("waiter_patrol_idx", 0)) % patrol_pts.size()
		var p_target: Vector2 = patrol_pts[p_idx]
		waiter._update_craft_bar_visual(0.35, "🍺 Atendiendo el salón...", Color(0.95, 0.78, 0.36, 0.90))
		if waiter.global_position.distance_to(p_target) > 12.0:
			waiter._move_towards_point(p_target, 42.0, delta)
		else:
			waiter.velocity = Vector2.ZERO
			if timer <= 0.0:
				waiter.set_meta("waiter_patrol_idx", (p_idx + 1) % patrol_pts.size())
				waiter.set_meta("waiter_timer", 3.5)
		return

	var target_key: String = str(waiter.get_meta("waiter_target_key", ""))
	var customer = vm._get_npcs_by_person_key().get(target_key, null)
	if customer == null or not is_instance_valid(customer) or not customer.is_conscious() or not RECT.has_point(customer.global_position):
		waiter.set_meta("waiter_step", "idle")
		return

	if step == "take_order":
		var order_pos: Vector2 = customer.global_position + Vector2(0.0, 10.0)
		waiter._update_craft_bar_visual(0.45, "📝 Tomando nota a %s" % customer.npc_name, Color(0.55, 0.88, 1.0, 0.95))
		if waiter.global_position.distance_to(order_pos) > 18.0:
			waiter._move_towards_point(order_pos, 48.0, delta)
			return
		waiter.velocity = Vector2.ZERO
		if timer <= 0.0:
			waiter.trigger_action_animation(1.4)
			waiter._spawn_floating_text("📝 «Enseguida te lo traigo, %s»" % customer.npc_name, Color(0.85, 0.95, 1.0), -34.0)
			customer._spawn_floating_text("🍺 «Un plato caliente y una jarra, por favor»", Color(1.0, 0.92, 0.68), -30.0)
			waiter.set_meta("waiter_step", "pickup_kitchen")
			waiter.set_meta("waiter_timer", 1.2)
		return

	if step == "pickup_kitchen":
		waiter._update_craft_bar_visual(0.72, "🍲 Recogiendo comanda en barra...", Color(1.0, 0.78, 0.35, 0.95))
		if waiter.global_position.distance_to(PASS_COUNTER_POS) > 16.0:
			waiter._move_towards_point(PASS_COUNTER_POS, 50.0, delta)
			return
		waiter.velocity = Vector2.ZERO
		if timer <= 0.0:
			waiter.trigger_action_animation(1.4)
			waiter._spawn_floating_text("🍲🍺 Comanda lista en bandeja", Color(1.0, 0.86, 0.45), -34.0)
			waiter.set_meta("waiter_step", "serve_table")
			waiter.set_meta("waiter_timer", 1.2)
		return

	if step == "serve_table":
		var serve_pos: Vector2 = customer.global_position + Vector2(0.0, 10.0)
		waiter._update_craft_bar_visual(0.92, "🍺 Llevando plato a %s..." % customer.npc_name, Color(0.45, 0.95, 0.55, 0.95))
		if waiter.global_position.distance_to(serve_pos) > 18.0:
			waiter._move_towards_point(serve_pos, 48.0, delta)
			return
		waiter.velocity = Vector2.ZERO
		waiter.trigger_action_animation(1.5)
		customer.trigger_action_animation(1.5)
		customer.set_meta("last_waiter_served_msec", Time.get_ticks_msec())
		customer.need_social = minf(100.0, float(customer.need_social) + 6.0)
		customer.feed_npc_gradual(10.0)
		if int(customer.personal_gold) >= 2:
			customer.personal_gold -= 1
			waiter.personal_gold += 1
			waiter._spawn_floating_text("🍲🍺 ¡Servido! (+1 Oro propina)", Color.SPRING_GREEN, -36.0)
		else:
			waiter._spawn_floating_text("🍲🍺 ¡Que aproveche!", Color.SPRING_GREEN, -36.0)
		customer._spawn_floating_text("😋🍺 «¡Gracias!»", Color(1.0, 0.90, 0.55), -30.0)
		waiter.set_meta("waiter_step", "idle")
		waiter.set_meta("waiter_timer", 3.0)

static func _pick_unserved_customer(vm, waiter):
	var now_ms: int = Time.get_ticks_msec()
	var best = null
	var best_d: float = INF
	for n in vm.VillageNeeds.living(vm):
		if n == waiter or n == vm._innkeeper_npc or not n.is_conscious() or int(n.elevation_level) != 0:
			continue
		if not (ROOMS_FLOOR_0["salon"].has_point(n.global_position) or ROOMS_FLOOR_0["casino"].has_point(n.global_position)):
			continue
		if n.velocity.length_squared() > 16.0:
			continue
		var last_ms: int = int(n.get_meta("last_waiter_served_msec", -999999))
		if now_ms - last_ms < 32000:
			continue
		var d: float = waiter.global_position.distance_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	return best

# ------------------------------------------------------------------ ambiente en vivo: comensales en mesas y partida de póker
static func on_hour(vm, hour: int) -> void:
	if vm == null or vm.is_building_door_blocked(BUILDING_ID):
		return
	# Entre las 11:00 y las 22:00, asegurar que haya vecinos sentados jugando al póker y pasando el rato en las mesas
	if hour < 11 or hour >= 23:
		return
	var poker_count: int = 0
	var table_count: int = 0
	for n in vm.VillageNeeds.living(vm):
		if str(n.get_meta("leisure_place", "")) == "tavern_poker":
			poker_count += 1
		elif str(n.get_meta("leisure_place", "")) == "tavern_hall":
			table_count += 1

	var candidates: Array = []
	for n in vm.VillageNeeds.living(vm):
		if not vm.VillageNeeds.is_free(n) or n.is_vagrant_camper:
			continue
		if int(n.trade_role) in [int(VillageNPC.TradeRole.INNKEEPER), int(VillageNPC.TradeRole.WAITER), int(VillageNPC.TradeRole.CHILD), int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.ROYAL_INVESTIGATOR)]:
			continue
		if int(n.personal_gold) >= 6:
			candidates.append(n)
	candidates.shuffle()

	for cand in candidates:
		if poker_count < 3:
			var p_seat: Vector2 = pick_poker_seat_for(vm, cand)
			if p_seat != Vector2.ZERO:
				cand.set_meta("leisure_place", "tavern_poker")
				cand.start_errand("leisure", p_seat)
				poker_count += 1
				continue
		if table_count < 4:
			var d_seat: Vector2 = pick_seat_for(vm, cand)
			if d_seat != Vector2.ZERO:
				cand.set_meta("leisure_place", "tavern_hall")
				cand.start_errand("leisure", d_seat)
				table_count += 1
		if poker_count >= 3 and table_count >= 4:
			break

## Semilla inicial al arrancar partida: sienta a un par de vecinos libres en el póker y en las mesas para que la taberna esté viva desde las 08:00.
static func seed_initial_patrons(vm) -> void:
	if vm == null:
		return
	on_hour(vm, 12)
	for n in vm.VillageNeeds.living(vm):
		var lp: String = str(n.get_meta("leisure_place", ""))
		if lp in ["tavern_poker", "tavern_hall"] and n.errand_pos != Vector2.ZERO:
			n.global_position = n.errand_pos
			n.set_meta("leisure_since", vm.VillageNeeds.total_hours())

static var _poker_callout_cooldown: float = 4.0
static var _club_rumor_cooldown: float = 9.0

static func tick(vm, delta: float) -> void:
	if vm == null:
		return
	var pl = vm.VillageNeeds.player_of(vm)
	if pl != null and is_instance_valid(pl) and STAIRS_RAMP_RECT.has_point(pl.global_position):
		if int(vm.player_elevation_level) == 0 and pl.global_position.y >= STAIRS_TOP_POS.y - 6.0:
			vm.set_player_elevation_level(1)
		elif int(vm.player_elevation_level) == 1 and pl.global_position.y <= STAIRS_BOTTOM_POS.y + 6.0:
			vm.set_player_elevation_level(0)
	# 1. Mantener la capa vertical (`elevation_level = 1`) de los vecinos que duermen en las camas del Piso +1,
	#    y orientar a Marta (detrás de la barra) y a los jugadores de póker/comensales hacia su mesa.
	if is_instance_valid(vm._innkeeper_npc) and not vm._innkeeper_npc.is_dead:
		if vm._innkeeper_npc.global_position.distance_to(INNKEEPER_WORK_POS) <= 14.0 and vm._innkeeper_npc.velocity.length_squared() < 4.0:
			vm._innkeeper_npc.facing_direction = Vector2.DOWN

	var poker_seated: Array = []
	for n in vm.VillageNeeds.living(vm):
		if n.is_sleeping and is_upper_floor_target(n.global_position) and int(n.elevation_level) != 1:
			vm.set_npc_elevation_level(n, 1)
		elif not n.is_sleeping and not RECT.grow(10.0).has_point(n.global_position) and int(n.elevation_level) == 1:
			# Si salió de la posada y no está en una casa con altillo, asegurar nivel 0
			if str(n.lodging) == "":
				vm.set_npc_elevation_level(n, 0)
		if int(n.elevation_level) == 0 and n.velocity.length_squared() < 4.0:
			if n.global_position.distance_to(GAMES_POS) <= 22.0:
				n.facing_direction = (GAMES_POS - n.global_position).normalized()
				poker_seated.append(n)
			else:
				for tp in DINING_TABLES:
					if n.global_position.distance_to(tp as Vector2) <= 18.0:
						n.facing_direction = ((tp as Vector2) - n.global_position).normalized()
						break

	# 2. Reacciones periódicas de la partida de póker con enfriamiento real (sin amontonar bocadillos)
	_poker_callout_cooldown = maxf(0.0, _poker_callout_cooldown - delta)
	if poker_seated.size() >= 1 and _poker_callout_cooldown <= 0.0:
		_poker_callout_cooldown = randf_range(7.0, 12.0)
		var actor = poker_seated[randi() % poker_seated.size()]
		var msg: String = POKER_CALLOUTS[randi() % POKER_CALLOUTS.size()]
		actor._spawn_floating_text(msg, Color(0.65, 1.0, 0.78), -30.0)

	# 2b. Rumor en vivo en la taberna sobre el horario y ubicación de la trampilla del Club de Peleas
	_club_rumor_cooldown = maxf(0.0, _club_rumor_cooldown - delta)
	var cur_h_t: int = int(WorldClock.current_hour) if WorldClock else 12
	if (cur_h_t >= 20 or cur_h_t < 3) and _club_rumor_cooldown <= 0.0:
		_club_rumor_cooldown = randf_range(16.0, 24.0)
		var speaker = vm._innkeeper_npc if (is_instance_valid(vm._innkeeper_npc) and not vm._innkeeper_npc.is_sleeping and not vm._innkeeper_npc.is_dead) else (poker_seated[0] if not poker_seated.is_empty() else null)
		if speaker != null:
			speaker._spawn_floating_text("🕳️🥊 «De 21:00 a 03:00 abre la trampilla del sótano en el cuarto de la escalera»", Color(1.0, 0.84, 0.45), -34.0)

	# 3. En modo 2D, mostrar las camas del piso superior solo cuando el jugador está en Planta +1
	if vm.is_inside_tree():
		var show_upper_2d: bool = int(vm.player_elevation_level) == 1
		for node_u in vm.get_tree().get_nodes_in_group("tavern_upper_2d"):
			if node_u is CanvasItem:
				(node_u as CanvasItem).visible = show_upper_2d
