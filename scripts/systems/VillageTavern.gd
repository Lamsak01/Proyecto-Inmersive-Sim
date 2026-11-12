@tool
extends RefCounted
const _AN_SITIOS = preload("res://mapa/anclas.gd") # plan de sitios: zonas fijas siguen a lo movido

## Paso 3: La Gran Posada, Taberna y Casino «El Jabalí Dorado» (2 pisos + sótano de peleas).
## - Primer edificio de 2 plantas reales:
##   - Planta 0 (`elevation_level = 0`):
##     1. `salon` (Gran Salón Comedor con 6 mesas y 12 sillas, chimenea y candelabros).
##     2. `barra_cocina` (Mostrador largo de caoba con Marta atendiendo detrás, pasa-platos de comandas, fogón y barriles).
##     3. `casino` (Sala de Póker con 4 sillas donde juegan los vecinos y Mesa de Billar 3D de verdad con troneras, bolas y tacos).
##     4. `escalera_bodega` (Vestíbulo con la gran escalera de madera al Piso +1 y la trampilla al Club de Peleas del Sótano -1).
##   - Planta +1 (`elevation_level = 1`, altura 3D `+22.0 px`):
##     - Galería / pasillo alto con barandilla de madera asomada al salón y 3 cuartos (dueños, huéspedes y el tuyo) con 6 camas reales:
##       Cuarto de Marta (`342, -252`), Aposento Real de Alistair (`400, -252`), Cuartos de Huéspedes (`435, -252`,
##       `468, -252`, `502, -252`) y Habitación de Alquiler del Jugador (`538, -252`).
## - Oficio `TradeRole.WAITER` (Camarero): se ocupa como cualquier vacante en `trade_configs`; camina entre las mesas
##   ocupadas y el pasa-platos de la barra tomando nota y llevando platos y jarras calientes.

const VillageNPC = preload("res://scripts/enemies/VillageNPC.gd")
const Marca = preload("res://mapa/marca.gd")
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
const DOOR_POS: Vector2 = Vector2(454.0, -132.0)

## Alturas 3D de la posada de 2 pisos
const FLOOR_1_H: float = 34.0
const TOTAL_WALL_H: float = 68.0

## Planta 0: 4 salas comunicadas por arcos anchos
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

## Puntos clave (barra, cocina, salón, casino y camas de la Planta +1): son marcas de la escena del edificio
## (mapa/edificios/building_tavern.tscn → «Marcas»), no números aquí. Se piden con sitio(M_…), dining_tables(),
## guest_beds() y all_upper_beds(); llegan en el mapa original, como esperan las funciones que colocan cosas y vecinos.
const M_BARRA: String = "barra"
const M_TRABAJO: String = Marca.TRABAJO     ## Marta detrás del mostrador
const M_PASAPLATOS: String = "pasaplatos"   ## donde el camarero recoge comandas
const M_TONELES: String = "toneles"         ## hilera de toneles tras la barra
const M_FOGONES: String = "fogones"
const M_MESA_CORTE: String = "mesa_corte"
const M_CHIMENEA: String = "chimenea"
const M_MESA_CENTRAL: String = "mesa_central" ## referencia del salón: donde se reúne la gente
const M_POKER: String = "poker"
const M_BILLAR: String = "billar"
const M_MESA: String = "mesa_%d"            ## mesas del comedor, de la 1 a MESAS_COMEDOR
const M_CAMA_MARTA: String = "cama_marta"
const M_CAMA_ALISTAIR: String = "cama_alistair"
const M_CAMA_HUESPED: String = "cama_huesped_%d"
const M_CAMA_JUGADOR: String = "cama_jugador"
const MESAS_COMEDOR: int = 6
const CAMAS_HUESPED: int = 3

static var _listas: Dictionary = {} ## nombre de lista → sitios (se leen una vez de las marcas)

static func sitio(marca: String) -> Vector2:
	return Marca.sitio(BUILDING_ID, marca)

static func dining_tables() -> Array:
	return _lista(M_MESA, MESAS_COMEDOR)

static func guest_beds() -> Array:
	return _lista(M_CAMA_HUESPED, CAMAS_HUESPED)

## Las seis camas de la Planta +1: dueños, huéspedes y la tuya.
static func all_upper_beds() -> Array:
	if not _listas.has("camas"):
		_listas["camas"] = [sitio(M_CAMA_MARTA), sitio(M_CAMA_ALISTAIR)] + guest_beds() + [sitio(M_CAMA_JUGADOR)]
	return _listas["camas"]

## Las cuatro sillas de la mesa de póker, pegadas a ella.
static func poker_chairs() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for off: Vector2 in POKER_CHAIR_OFFSETS:
		out.append(sitio(M_POKER) + off)
	return out

static func _lista(marca: String, cuantas: int) -> Array:
	if not _listas.has(marca):
		var lista: Array = []
		for i in range(1, cuantas + 1):
			lista.append(sitio(marca % i))
		_listas[marca] = lista
	return _listas[marca]

const BAR_COUNTER_SIZE: Vector2 = Vector2(108.0, 10.0)
const WELL_POS: Vector2 = Vector2(228.0, -230.0)           # Pozo en el patio lateral oeste

## Escalera real entre Planta 0 y Planta +1 y Trampilla al Sótano (-1)
const STAIRS_BOTTOM_POS: Vector2 = Vector2(576.0, -284.0)  # Pie de la escalera en Planta 0 (sala noreste)
const STAIRS_TOP_POS: Vector2 = Vector2(576.0, -202.0)     # Desembarco de la escalera en Planta +1 (galería alta)
const STAIRS_PROP_POS: Vector2 = Vector2(576.0, -244.0)    # Punto medio de la rampa de la escalera
const STAIRS_RAMP_RECT: Rect2 = Rect2(Vector2(563.0, -292.0), Vector2(28.0, 96.0))
## Paso a 3D, paso 4a: un vecino cambia de planta solo al pisar el último peldaño (antes a 10 px: daba un escalón de golpe).
const STAIRS_END_TOL: float = 3.0
## Paso a 3D, paso 2: hueco de la escalera en la Planta +1 (ahí no hay suelo alto, solo la rampa): de la barandilla oeste
## (x 558) al muro este y del tope norte (y -298) al desembarco. Y borde sur del suelo alto (la barandilla está en y -168).
const STAIRS_WELL_RECT: Rect2 = Rect2(Vector2(558.0, -298.0), Vector2(50.0, 102.0))
const GALLERY_EDGE_Y: float = -166.0
const FLOOR_0_SURFACE_H: float = 2.95                 ## altura de la tarima de la Planta 0 (px sobre el relieve)
const FLOOR_1_SURFACE_H: float = FLOOR_1_H + 0.55     ## altura del suelo de la Planta +1

## 6 Mesas del Gran Salón Comedor (Planta 0) con 2 sillas cada una (12 plazas sentadas, todas visibles frente al muro sur)
const CHAIR_OFFSETS: Array = [Vector2(-15.0, 0.0), Vector2(15.0, 0.0)]

## 4 Sillas alrededor de la Mesa de Póker (Planta 0: Oeste, Este, Norte, Sur)
const POKER_CHAIR_OFFSETS: Array = [
	Vector2(-16.5, 0.0),
	Vector2(16.5, 0.0),
	Vector2(0.0, -16.0),
	Vector2(0.0, 16.0),
]

## Planta +1: 3 cuartos en el ala norte (`y = -316..-216`) + Galería alta (`y = -216..-168`). 2026-11-11 (el usuario los
## vio minúsculos: eran 5, dos de solo 2 m): el de los dueños (x 264..376, Marta y Alistair), el de huéspedes (376..492,
## 3 camas) y el tuyo (492..558). Mismas 6 camas, en la misma fila (y -252).
const HALLWAY_Y: float = -200.0
const BEDROOM_WALL_Y: float = -216.0
const BEDROOM_DOORS_X: Array = [318.0, 434.0, 525.0]
const BEDROOM_PARTITIONS_X: Array = [376.0, 492.0, 558.0]
const BEDROOM_DOOR_HALF_W: float = 10.0

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
	vm._tavern_social_pos = sitio(M_MESA_CENTRAL)
	vm._tavern_games_pos = sitio(M_POKER)
	vm._tavern_pool_pos = sitio(M_BILLAR)
	vm._tavern_bed_pos = sitio(M_CAMA_JUGADOR)
	vm._tavern_well_pos = preload("res://mapa/objeto.gd").pos("pozo_taberna", WELL_POS) # editor del mapa: el pozo movido manda

	var tex_bed: Texture2D = vm._load_tex("res://assests/world/village/tavern_bed.png")
	var tex_stall: Texture2D = vm._load_tex("res://assests/world/village/work_stall.png")
	var tex_innkeeper: Texture2D = vm._load_tex("res://assests/world/village/villager_innkeeper.png")

	vm._construct_solid_building(BUILDING_ID, TITLE, CENTER,
		"res://assests/world/village/floor_wood_planks.png", "res://assests/world/village/wall_timber_h.png", "res://assests/world/village/wall_timber_v.png",
		Color(1.0, 0.88, 0.45))

	# Alfombra discreta bajo el salón del casino en Planta 0 (z_index = -2, bajo las mesas)
	var cas_rug: Polygon2D = vm._add_rect_poly(Vector2(543.0, -182.0), Vector2(52.0, 38.0), Color(0.44, 0.16, 0.14, 0.36), -2)
	cas_rug.add_to_group("tavern_floor0_2d")

	# Tabiques de la planta baja (piezas «Tabiques» de la escena): dejan de chocar cuando el protagonista está arriba
	for sb_w: StaticBody2D in vm.interior_walls[BUILDING_ID]:
		sb_w.add_to_group("tavern_floor0_2d")
		sb_w.add_to_group("tavern_floor0_walls")
		sb_w.collision_layer = load("res://scripts/fisica/Suelo.gd").capa(int(vm.player_elevation_level) == 0)

	# Mostrador largo de Marta y pasa-platos del camarero
	vm._add_rect_poly(sitio(M_BARRA), BAR_COUNTER_SIZE * 0.5, Color(0.42, 0.25, 0.12, 0.98), -1).add_to_group("tavern_floor0_2d")
	vm._add_sprite_prop(tex_stall, sitio(M_BARRA) + Vector2(0.0, 4.0), Vector2(1.4, 1.2), -1).add_to_group("tavern_floor0_2d")
	vm._add_prop_collider(sitio(M_BARRA), Vector2(96.0, 10.0), "tavern_floor0_walls")
	vm.register_no_stand_furniture(sitio(M_BARRA), Vector2(96.0, 10.0))

	# Chimenea del gran salón, fogón de cocina, mesa de preparación y toneles tras la barra (2D + choque)
	vm._add_rect_poly(sitio(M_CHIMENEA), Vector2(6.0, 14.0), Color(0.36, 0.34, 0.32, 0.98), -1).add_to_group("tavern_floor0_2d")
	vm._add_rect_poly(sitio(M_CHIMENEA) + Vector2(2.0, 0.0), Vector2(3.0, 9.0), Color(0.95, 0.42, 0.12, 0.92), -1).add_to_group("tavern_floor0_2d")
	vm._add_prop_collider(sitio(M_CHIMENEA), Vector2(12.0, 28.0), "tavern_floor0_walls")
	vm.register_no_stand_furniture(sitio(M_CHIMENEA), Vector2(12.0, 28.0))
	vm._add_rect_poly(sitio(M_FOGONES), Vector2(12.0, 5.5), Color(0.24, 0.22, 0.22, 0.98), -1).add_to_group("tavern_floor0_2d")
	vm._add_prop_collider(sitio(M_FOGONES), Vector2(24.0, 11.0), "tavern_floor0_walls")
	vm.register_no_stand_furniture(sitio(M_FOGONES), Vector2(24.0, 11.0))
	vm._add_rect_poly(sitio(M_MESA_CORTE), Vector2(12.0, 5.0), Color(0.48, 0.32, 0.18, 0.98), -1).add_to_group("tavern_floor0_2d")
	vm._add_prop_collider(sitio(M_MESA_CORTE), Vector2(24.0, 10.0), "tavern_floor0_walls")
	vm.register_no_stand_furniture(sitio(M_MESA_CORTE), Vector2(24.0, 10.0))
	vm._add_rect_poly(sitio(M_TONELES), Vector2(26.0, 5.0), Color(0.38, 0.24, 0.12, 0.98), -1).add_to_group("tavern_floor0_2d")
	vm._add_prop_collider(sitio(M_TONELES), Vector2(52.0, 10.0), "tavern_floor0_walls")
	vm.register_no_stand_furniture(sitio(M_TONELES), Vector2(52.0, 10.0))
	for b_cell_pos in [Vector2(498.0, -302.0), Vector2(534.0, -302.0), Vector2(498.0, -268.0)]:
		vm._add_rect_poly(b_cell_pos, Vector2(4.5, 4.5), Color(0.42, 0.27, 0.14, 0.96), -1).add_to_group("tavern_floor0_2d")
		vm._add_prop_collider(b_cell_pos, Vector2(9.0, 9.0), "tavern_floor0_walls")
		vm.register_no_stand_furniture(b_cell_pos, Vector2(9.0, 9.0))

	# 6 Mesas de comedor y tertulia en el Gran Salón (Planta 0) — colisión de tablero ajustada para dejar libres las sillas
	for tp in dining_tables():
		vm._add_rect_poly(tp, Vector2(11.0, 6.5), Color(0.54, 0.35, 0.18, 0.98), -1).add_to_group("tavern_floor0_2d")
		for off in CHAIR_OFFSETS:
			vm._add_rect_poly(tp + (off as Vector2), Vector2(3.5, 3.5), Color(0.38, 0.24, 0.12, 0.95), -1).add_to_group("tavern_floor0_2d")
		vm._add_prop_collider(tp, Vector2(13.0, 8.0), "tavern_floor0_walls")
		vm.register_no_stand_furniture(tp, Vector2(13.0, 8.0))

	# 1. Mesa Verde de Póker / Blackjack / Ruleta con 4 sillas
	vm._add_rect_poly(sitio(M_POKER), Vector2(14.0, 10.0), Color(0.42, 0.26, 0.12, 1.0), -1).add_to_group("tavern_floor0_2d")
	vm._add_rect_poly(sitio(M_POKER), Vector2(11.5, 7.5), Color(0.10, 0.50, 0.25, 1.0), -1).add_to_group("tavern_floor0_2d")
	for chair_off in POKER_CHAIR_OFFSETS:
		vm._add_rect_poly(sitio(M_POKER) + (chair_off as Vector2), Vector2(4.0, 4.0), Color(0.55, 0.36, 0.18, 0.95), -1).add_to_group("tavern_floor0_2d")
	vm._add_prop_collider(sitio(M_POKER), Vector2(14.0, 10.0), "tavern_floor0_walls")
	vm.register_no_stand_furniture(sitio(M_POKER), Vector2(14.0, 10.0))

	vm._add_station_area("TavernGamesTableArea", sitio(M_POKER), 24.0, "tavern_games")
	vm._tavern_games_label = vm._make_station_label(sitio(M_POKER) + Vector2(-120.0, -30.0), "🃏 Mesa de Póker y Casino [E: Jugar con Aldeanos]")
	vm.entities_root.add_child(vm._tavern_games_label)

	# 2. Mesa de Billar de la Posada
	vm._add_rect_poly(sitio(M_BILLAR), Vector2(14.0, 8.5), Color(0.38, 0.22, 0.10, 1.0), -1).add_to_group("tavern_floor0_2d")
	vm._add_rect_poly(sitio(M_BILLAR), Vector2(12.0, 6.5), Color(0.08, 0.48, 0.30, 1.0), -1).add_to_group("tavern_floor0_2d")
	vm._add_prop_collider(sitio(M_BILLAR), Vector2(26.0, 16.0), "tavern_floor0_walls")
	vm.register_no_stand_furniture(sitio(M_BILLAR), Vector2(26.0, 16.0))
	vm._add_station_area("TavernPoolTableArea", sitio(M_BILLAR), 24.0, "tavern_pool")
	vm._tavern_pool_label = vm._make_station_label(sitio(M_BILLAR) + Vector2(-115.0, -30.0), "🎱 Mesa de Billar [E: Jugar Billar de Posada]")
	vm.entities_root.add_child(vm._tavern_pool_label)

	# 3. Escalera de madera entre Planta 0 y Planta +1 (se sube y baja caminando, sin pulsar [E])
	for step_i in range(8):
		var sy: float = lerpf(STAIRS_BOTTOM_POS.y, STAIRS_TOP_POS.y, float(step_i) / 7.0)
		vm._add_rect_poly(Vector2(STAIRS_BOTTOM_POS.x, sy), Vector2(12.0, 2.5), Color(0.48, 0.31, 0.16, 0.95), -1).add_to_group("tavern_floor0_2d")

	# 3b. Barandillas sólidas y tabiques de los 3 cuartos en Planta +1 ("tavern_upper_walls")
	# Paso a 3D, paso 2c: las barandillas son bajas (grupo «barandilla»): se pueden saltar… y caer al salón.
	for bar in [[Vector2(434.0, -168.0), Vector2(348.0, 6.0)], # Barandilla sur de la galería alta
			[Vector2(558.0, -261.0), Vector2(6.0, 110.0)],     # Barandilla oeste del hueco de escalera
			[Vector2(582.0, -298.0), Vector2(48.0, 6.0)]]:     # Tope norte del hueco de escalera en Planta +1
		var sb_bar: StaticBody2D = vm._add_prop_collider(bar[0], bar[1], "tavern_upper_walls")
		if sb_bar != null:
			sb_bar.add_to_group("barandilla")
	var cur_ux: float = 264.0
	for dx in BEDROOM_DOORS_X:
		var a_ux: float = float(dx) - BEDROOM_DOOR_HALF_W
		if a_ux - cur_ux > 2.0:
			vm._add_prop_collider(Vector2((cur_ux + a_ux) * 0.5, BEDROOM_WALL_Y), Vector2(a_ux - cur_ux, 5.0), "tavern_upper_walls")
		cur_ux = float(dx) + BEDROOM_DOOR_HALF_W
	if 558.0 - cur_ux > 2.0:
		vm._add_prop_collider(Vector2((cur_ux + 558.0) * 0.5, BEDROOM_WALL_Y), Vector2(558.0 - cur_ux, 5.0), "tavern_upper_walls")
	for part_ux in BEDROOM_PARTITIONS_X:
		if float(part_ux) < 556.0:
			vm._add_prop_collider(Vector2(float(part_ux), -265.0), Vector2(5.0, 98.0), "tavern_upper_walls")

	# 4. Camas de huéspedes en Planta +1 (2.º piso)
	for b_pos in all_upper_beds():
		var spr: Sprite2D = vm._add_sprite_prop(tex_bed, b_pos, Vector2(1.18, 1.18), -1)
		if spr != null:
			spr.add_to_group("tavern_upper_2d")

	vm._add_station_area("TavernPlayerBedArea", sitio(M_CAMA_JUGADOR), 20.0, "tavern_bed")
	vm._tavern_bed_label = vm._make_station_label(sitio(M_CAMA_JUGADOR) + Vector2(-115.0, -28.0), "🛌 Cama de Posada (Piso +1) [E: Dormir hasta 06:00 (-8 Oro)]")
	vm.entities_root.add_child(vm._tavern_bed_label)

	vm._spawn_house_chest(Vector2(365.0, -300.0), "Cofre de la Posada El Jabalí", FAMILY_ID) # rincón del cuarto de los dueños (2026-11-11: chocaba con la cama de Marta)

	# 5. Marta, la Tabernera y Chef, detrás del mostrador
	var marta := VillageNPC.new()
	marta.name = "NPC_Marta_Innkeeper"
	marta.npc_name = "Marta"
	marta.npc_role = "Chef y Posadera"
	marta.trade_role = VillageNPC.TradeRole.INNKEEPER
	marta.tavern_social_pos = sitio(M_MESA_CENTRAL)
	vm.entities_root.add_child(marta)
	marta.setup_npc(tex_innkeeper, sitio(M_TRABAJO), sitio(M_CAMA_MARTA), {"country_stew": 6, "bread": 8, "roasted_chicken": 4}, sitio(M_MESA_CENTRAL), FAMILY_ID, "Posada El Jabalí")
	vm._innkeeper_npc = marta

	# 6. Oficio nuevo: Camarero (`TradeRole.WAITER`), registrado en `trade_configs` para cubrirse como cualquier vacante
	var waiter_role: int = int(VillageNPC.TradeRole.WAITER)
	vm.trade_configs[waiter_role] = {
		"family_id": FAMILY_ID,
		"family_name": "Posada El Jabalí",
		"shop_title": "🍺 Servicio de Salón — El Jabalí Dorado",
		"shop_center": sitio(M_PASAPLATOS),
		"is_mixed_building": true,
		"house_title": TITLE,
		"house_center": guest_beds()[1],
		"name": "Bastian",
		"title": "Camarero de Posada",
		"tex": vm._load_tex("res://assests/world/village/villager_traveler.png"),
		"stock": {"country_stew": 3, "bread": 4},
		"work_pos": sitio(M_PASAPLATOS),
		"bed1_pos": guest_beds()[1],
		"bed2_pos": guest_beds()[2],
		"table_pos": sitio(M_MESA_CENTRAL),
	}
	var waiter_stall: Sprite2D = vm._add_sprite_prop(tex_stall, sitio(M_PASAPLATOS), Vector2(0.85, 0.85), -1)
	vm._register_shop_business_stall(waiter_role, "🍺 Servicio de Mesas 'El Jabalí Dorado'", FAMILY_ID, _AN_SITIOS.mover(sitio(M_PASAPLATOS)), waiter_stall) # el puesto se guarda en el mundo

# ------------------------------------------------------------------ asientos de comedor y póker
## Plan de sitios: los asientos se devuelven en su sitio ACTUAL (siguen a la taberna movida en el editor 3D).
static func dining_seats() -> Array:
	var out: Array = []
	for tp in dining_tables():
		for off in CHAIR_OFFSETS:
			out.append((tp as Vector2) + (off as Vector2))
	return _AN_SITIOS.mover_lista("taberna_comedor", out)

static func poker_seats() -> Array:
	var out: Array = []
	for off in POKER_CHAIR_OFFSETS:
		out.append(sitio(M_POKER) + (off as Vector2))
	return _AN_SITIOS.mover_lista("taberna_poker", out)

## Recibe y devuelve sitios actuales.
static func table_center_for_seat(seat: Vector2) -> Vector2:
	for tp in _AN_SITIOS.mover_lista("taberna_mesas", dining_tables()): # también si se movió un mueble
		if seat.distance_to(tp as Vector2) <= 20.0:
			return tp as Vector2
	var g: Vector2 = _AN_SITIOS.mover(sitio(M_POKER))
	if seat.distance_to(g) <= 22.0:
		return g
	return _AN_SITIOS.mover(sitio(M_MESA_CENTRAL))

static func is_at_seat(pos: Vector2) -> bool:
	if not RECT.grow(4.0).has_point(_AN_SITIOS.desmover(pos)): # plan de sitios: la zona se compara en el mapa original
		return false
	for s in dining_seats():
		if pos.distance_to(s as Vector2) <= 6.5:
			return true
	for ps in poker_seats():
		if pos.distance_to(ps as Vector2) <= 6.5:
			return true
	return false

static func snap_seat_pos(pos: Vector2) -> Vector2:
	for s in dining_seats():
		if pos.distance_to(s as Vector2) <= 6.5:
			return s as Vector2
	for ps in poker_seats():
		if pos.distance_to(ps as Vector2) <= 6.5:
			return ps as Vector2
	return pos

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
		return _AN_SITIOS.mover(sitio(M_MESA_CENTRAL))
	return free[absi(npc.npc_name.hash() + (vm.VillageNeeds.total_hours() if vm != null else 0)) % free.size()] # hora del juego, no reloj real: misma partida, mismo resultado

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
	return es_cama_alta_original(_AN_SITIOS.desmover(pos)) # plan de sitios: se compara en el mapa original


## Lo mismo con un punto YA en el mapa original (dentro de `_route_original`; traducirlo dos veces lo estropea con el mapa ×E).
static func es_cama_alta_original(pos: Vector2) -> bool:
	if not RECT.grow(6.0).has_point(pos):
		return false
	for b in all_upper_beds():
		if pos.distance_to(b as Vector2) <= 3.5:
			return true
	return false

static func room_at_floor_0(pos: Vector2) -> String:
	var p_in := Vector2(
		clampf(pos.x, RECT.position.x + 1.0, RECT.end.x - 1.0),
		clampf(pos.y, RECT.position.y + 1.0, RECT.end.y - 1.0)
	)
	for id in ROOMS_FLOOR_0.keys():
		if (ROOMS_FLOOR_0[id] as Rect2).has_point(p_in):
			return id
	var best: String = "salon"
	var best_d: float = INF
	for id in ROOMS_FLOOR_0.keys():
		var r: Rect2 = ROOMS_FLOOR_0[id]
		var cl := Vector2(clampf(p_in.x, r.position.x, r.end.x), clampf(p_in.y, r.position.y, r.end.y))
		var d: float = p_in.distance_to(cl)
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

## La puerta del cuarto en el que está `pos` (o del que le toca por su x): dueños, huéspedes o el tuyo.
static func _bedroom_door_x_for(pos: Vector2) -> float:
	for i in range(BEDROOM_PARTITIONS_X.size()):
		if pos.x < float(BEDROOM_PARTITIONS_X[i]):
			return float(BEDROOM_DOORS_X[i])
	return float(BEDROOM_DOORS_X.back())

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
## Plan de sitios: la ruta se calcula en el mapa original (las constantes de la taberna) y se devuelve en el sitio actual.
static func route(from_pos: Vector2, target_pos: Vector2, agent: Node2D = null, vm = null) -> Vector2:
	return _AN_SITIOS.mover(_route_original(_AN_SITIOS.desmover(from_pos), _AN_SITIOS.desmover(target_pos), agent, vm))

static func _route_original(from_pos: Vector2, target_pos: Vector2, agent: Node2D = null, vm = null) -> Vector2:
	var from_elev: int = 0
	if agent != null and "elevation_level" in agent:
		from_elev = int(agent.elevation_level)
	var to_elev: int = 1 if es_cama_alta_original(target_pos) else 0 # target_pos ya está en el mapa original

	# Subir de Planta 0 a Planta +1 por la escalera
	if from_elev == 0 and to_elev == 1:
		if not STAIRS_RAMP_RECT.has_point(from_pos) and from_pos.distance_to(STAIRS_BOTTOM_POS) > 12.0:
			return route_floor_0(from_pos, STAIRS_BOTTOM_POS)
		if from_pos.distance_to(STAIRS_TOP_POS) > STAIRS_END_TOL:
			return STAIRS_TOP_POS
		if agent != null and vm != null and vm.has_method("set_npc_elevation_level"):
			vm.call("set_npc_elevation_level", agent, 1)
		return route_floor_1(from_pos, target_pos)

	# Bajar de Planta +1 a Planta 0 por la escalera
	if from_elev == 1 and to_elev == 0:
		if not STAIRS_RAMP_RECT.has_point(from_pos) and from_pos.distance_to(STAIRS_TOP_POS) > 12.0:
			return route_floor_1(from_pos, STAIRS_TOP_POS)
		if from_pos.distance_to(STAIRS_BOTTOM_POS) > STAIRS_END_TOL:
			return STAIRS_BOTTOM_POS
		if agent != null and vm != null and vm.has_method("set_npc_elevation_level"):
			vm.call("set_npc_elevation_level", agent, 0)
		return route_floor_0(from_pos, target_pos)

	if from_elev == 1:
		return route_floor_1(from_pos, target_pos)
	return route_floor_0(from_pos, target_pos)

## Altura 3D adicional (`2.95..22.55 px`) para que los pies apoyen sobre las tablas/alfombras de Planta 0, escalera y Planta +1.
static func elevation_height_for(pos: Vector2, elev_level: int) -> float:
	pos = _AN_SITIOS.desmover(pos)
	if RECT.grow(10.0).has_point(pos) and STAIRS_RAMP_RECT.has_point(pos):
		var t: float = clampf((pos.y - STAIRS_BOTTOM_POS.y) / maxf(1.0, STAIRS_TOP_POS.y - STAIRS_BOTTOM_POS.y), 0.0, 1.0)
		return lerpf(2.95, FLOOR_1_H + 0.55, t)
	if elev_level == 1 and RECT.grow(10.0).has_point(pos): # (2026-11-11: antes valía para cualquier sitio; ahora solo la posada)
		return FLOOR_1_H + 0.55
	if elev_level == 0 and RECT.grow(2.0).has_point(pos):
		return 2.95
	return 0.0

## Paso a 3D, paso 2: los suelos que hay en `pos` dentro de la posada, en px de altura sobre el relieve y de abajo
## arriba: la tarima de la Planta 0, la rampa de la escalera (en su hueco) o el suelo de la Planta +1. Fuera, ninguno.
static func floor_heights_at(pos: Vector2) -> Array[float]:
	pos = _AN_SITIOS.desmover(pos)
	var out: Array[float] = []
	if not RECT.grow(2.0).has_point(pos):
		return out
	out.append(FLOOR_0_SURFACE_H)
	if STAIRS_WELL_RECT.has_point(pos):
		var t: float = clampf((pos.y - STAIRS_BOTTOM_POS.y) / (STAIRS_TOP_POS.y - STAIRS_BOTTOM_POS.y), 0.0, 1.0)
		out.append(lerpf(FLOOR_0_SURFACE_H, FLOOR_1_SURFACE_H, t))
	elif pos.y <= GALLERY_EDGE_Y:
		out.append(FLOOR_1_SURFACE_H)
	return out

## Paso a 3D, paso 5a: el suelo de la Planta +1 como losa que tapa la vista (galería y cuartos; el hueco de la escalera no).
static func losa_planta_1() -> Dictionary:
	return {"rect": Rect2(RECT.position, Vector2(RECT.size.x, GALLERY_EDGE_Y - RECT.position.y)), "hueco": STAIRS_WELL_RECT, "h": FLOOR_1_SURFACE_H}


## Interacción con la escalera [E] para el jugador (subir al Piso +1 o bajar al Salón Planta 0).
static func stairs_label(vm) -> String:
	if vm != null and int(vm.player_elevation_level) == 1:
		return "🪜🍺 Bajar escalera al Gran Salón de la Taberna (Planta 0)"
	return "🪜🛌 Subir escalera a los Cuartos de Huéspedes (Planta +1)"

static func use_stairs(vm, player: Node2D) -> void:
	if vm == null or player == null:
		return
	if int(vm.player_elevation_level) == 1:
		player.global_position = _AN_SITIOS.mover(STAIRS_BOTTOM_POS + Vector2(-12.0, 6.0))
		vm.set_player_elevation_level(0)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🪜🍺 Bajaste al Gran Salón (Planta 0)", Color(0.95, 0.85, 0.55), -38.0)
	else:
		player.global_position = _AN_SITIOS.mover(STAIRS_TOP_POS + Vector2(-12.0, 4.0))
		vm.set_player_elevation_level(1)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🪜🛌 Subiste a los Cuartos de Huéspedes (Planta +1)", Color(0.85, 0.95, 1.0), -38.0)

# ------------------------------------------------------------------ rutina del Camarero (`TradeRole.WAITER`)
static func tick_waiter(vm, waiter, delta: float) -> void:
	if vm == null or waiter == null or not is_instance_valid(waiter):
		return
	if int(waiter.elevation_level) != 0 and RECT.grow(8.0).has_point(_AN_SITIOS.desmover(waiter.global_position)):
		var wp_down: Vector2 = route(waiter.global_position, _AN_SITIOS.mover(sitio(M_PASAPLATOS)), waiter, vm)
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
		var patrol_pts: Array = _AN_SITIOS.mover_lista("taberna_ronda", [sitio(M_PASAPLATOS), dining_tables()[0] + Vector2(0, 10), dining_tables()[2] + Vector2(0, 10), dining_tables()[4] + Vector2(0, 10)])
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
	if customer == null or not is_instance_valid(customer) or not customer.is_conscious() or not RECT.has_point(_AN_SITIOS.desmover(customer.global_position)):
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
		if waiter.global_position.distance_to(_AN_SITIOS.mover(sitio(M_PASAPLATOS))) > 16.0:
			waiter._move_towards_point(_AN_SITIOS.mover(sitio(M_PASAPLATOS)), 50.0, delta)
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
	# Entre las 08:00 y las 23:00, asegurar que haya vecinos sentados jugando al póker y comiendo/bebiendo en las mesas
	if hour < 8 or hour >= 24:
		return
	var demo_active: bool = vm.has_method("is_demo_mode") and bool(vm.call("is_demo_mode"))
	var poker_count: int = 0
	var table_count: int = 0
	for n in vm.VillageNeeds.living(vm):
		if demo_active and n.is_at_poker_table:
			n.set_poker_seating(false)
		if n.errand_kind != "leisure":
			continue
		if str(n.get_meta("leisure_place", "")) == "tavern_poker":
			if demo_active:
				n.end_errand()
				continue
			poker_count += 1
		elif str(n.get_meta("leisure_place", "")) == "tavern_hall":
			table_count += 1

	var candidates: Array = []
	for n in vm.VillageNeeds.living(vm):
		if n.is_vagrant_camper or n.is_sleeping or n.rite_pos != Vector2.ZERO or n.errand_kind != "":
			continue
		if int(n.trade_role) in [int(VillageNPC.TradeRole.INNKEEPER), int(VillageNPC.TradeRole.WAITER), int(VillageNPC.TradeRole.CHILD), int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.ROYAL_INVESTIGATOR)]:
			continue
		var can_go: bool = vm.VillageNeeds.is_free(n) or int(n.trade_role) in [int(VillageNPC.TradeRole.UNEMPLOYED), int(VillageNPC.TradeRole.FAMILY_MEMBER)]
		if can_go and int(n.personal_gold) >= 5:
			candidates.append(n)
	candidates.shuffle()

	for cand in candidates:
		if table_count < 4 and (demo_active or poker_count >= 2):
			var d_seat0: Vector2 = pick_seat_for(vm, cand)
			if d_seat0 != Vector2.ZERO and d_seat0 != _AN_SITIOS.mover(sitio(M_MESA_CENTRAL)):
				cand.set_meta("leisure_place", "tavern_hall")
				cand.start_errand("leisure", d_seat0)
				table_count += 1
				continue
		if not demo_active and poker_count < 3:
			var p_seat: Vector2 = pick_poker_seat_for(vm, cand)
			if p_seat != Vector2.ZERO:
				cand.set_meta("leisure_place", "tavern_poker")
				cand.start_errand("leisure", p_seat)
				poker_count += 1
				continue
		if table_count < 7:
			var d_seat: Vector2 = pick_seat_for(vm, cand)
			if d_seat != Vector2.ZERO and d_seat != _AN_SITIOS.mover(sitio(M_MESA_CENTRAL)):
				cand.set_meta("leisure_place", "tavern_hall")
				cand.start_errand("leisure", d_seat)
				if table_count < 4:
					cand.global_position = d_seat
					cand.facing_direction = (table_center_for_seat(d_seat) - d_seat).normalized()
					cand.set_meta("leisure_since", vm.VillageNeeds.total_hours())
				table_count += 1
		if (demo_active or poker_count >= 3) and table_count >= 7:
			break

## Semilla inicial al arrancar partida: sienta a varios vecinos en el póker y en las mesas para que la taberna esté viva desde las 08:00.
static func seed_initial_patrons(vm) -> void:
	if vm == null:
		return
	on_hour(vm, 12)
	var seated_hall: int = 0
	for n in vm.VillageNeeds.living(vm):
		if str(n.get_meta("leisure_place", "")) == "tavern_hall":
			seated_hall += 1
	if seated_hall < 4:
		for n in vm.VillageNeeds.living(vm):
			if seated_hall >= 4:
				break
			if str(n.get_meta("leisure_place", "")) != "" or n.is_vagrant_camper or n.is_sleeping:
				continue
			if int(n.trade_role) in [int(VillageNPC.TradeRole.FAMILY_MEMBER), int(VillageNPC.TradeRole.UNEMPLOYED)]:
				var d_s: Vector2 = pick_seat_for(vm, n)
				if d_s != Vector2.ZERO and d_s != _AN_SITIOS.mover(sitio(M_MESA_CENTRAL)):
					n.set_meta("leisure_place", "tavern_hall")
					n.start_errand("leisure", d_s)
					seated_hall += 1
	for n in vm.VillageNeeds.living(vm):
		var lp: String = str(n.get_meta("leisure_place", ""))
		if n.errand_kind == "leisure" and lp in ["tavern_poker", "tavern_hall"] and n.errand_pos != Vector2.ZERO:
			n.global_position = n.errand_pos
			n.facing_direction = (table_center_for_seat(n.errand_pos) - n.errand_pos).normalized()
			n.set_meta("leisure_since", vm.VillageNeeds.total_hours())
			n.errand_since = vm.VillageNeeds.total_hours()

static var _poker_callout_cooldown: float = 4.0
static var _club_rumor_cooldown: float = 9.0

static func tick(vm, delta: float) -> void:
	if vm == null:
		return
	# El piso del protagonista (Planta 0 o +1) ya no se decide aquí: lo da la altura de su cuerpo 3D (paso a 3D, paso 2).
	# 1. Mantener la capa vertical (`elevation_level = 1`) de los vecinos que duermen en las camas del Piso +1,
	#    y orientar a Marta (detrás de la barra) y a los jugadores de póker/comensales sentados hacia su mesa.
	if is_instance_valid(vm._innkeeper_npc) and not vm._innkeeper_npc.is_dead:
		if vm._innkeeper_npc.global_position.distance_to(_AN_SITIOS.mover(sitio(M_TRABAJO))) <= 14.0 and vm._innkeeper_npc.velocity.length_squared() < 4.0:
			vm._innkeeper_npc.facing_direction = Vector2.DOWN

	var poker_seated: Array = []
	var hall_seated_count: int = 0
	var games_act: Vector2 = _AN_SITIOS.mover(sitio(M_POKER)) # plan de sitios: la mesa de póker en su sitio actual
	var mesas_act: Array = _AN_SITIOS.mover_lista("taberna_mesas", dining_tables())
	for n in vm.VillageNeeds.living(vm):
		if n.is_sleeping and is_upper_floor_target(n.global_position) and int(n.elevation_level) != 1:
			vm.set_npc_elevation_level(n, 1)
		elif not n.is_sleeping and not RECT.grow(10.0).has_point(_AN_SITIOS.desmover(n.global_position)) and int(n.elevation_level) == 1:
			# Si salió de la posada y no está en una casa con altillo, asegurar nivel 0
			if str(n.lodging) == "":
				vm.set_npc_elevation_level(n, 0)
		if int(n.elevation_level) == 0 and n.velocity.length_squared() < 4.0:
			if is_at_seat(n.global_position):
				var snapped: Vector2 = snap_seat_pos(n.global_position)
				if n.global_position.distance_to(snapped) > 0.2:
					n.global_position = snapped
				var tc: Vector2 = table_center_for_seat(snapped)
				if tc.distance_to(snapped) > 1.0:
					n.facing_direction = (tc - snapped).normalized()
				if snapped.distance_to(games_act) <= 22.0:
					poker_seated.append(n)
				else:
					hall_seated_count += 1
			elif n.global_position.distance_to(games_act) <= 22.0:
				n.facing_direction = (games_act - n.global_position).normalized()
				poker_seated.append(n)
			else:
				for tp in mesas_act:
					if n.global_position.distance_to(tp as Vector2) <= 18.0:
						n.facing_direction = ((tp as Vector2) - n.global_position).normalized()
						break

	# 2. Reacciones periódicas de la partida de póker con enfriamiento real (sin amontonar bocadillos)
	var demo_active_t: bool = vm.has_method("is_demo_mode") and bool(vm.call("is_demo_mode"))
	_poker_callout_cooldown = maxf(0.0, _poker_callout_cooldown - delta)
	if not demo_active_t and poker_seated.size() >= 1 and _poker_callout_cooldown <= 0.0:
		_poker_callout_cooldown = randf_range(7.0, 12.0)
		var actor = poker_seated[randi() % poker_seated.size()]
		var msg: String = POKER_CALLOUTS[randi() % POKER_CALLOUTS.size()]
		actor._spawn_floating_text(msg, Color(0.65, 1.0, 0.78), -30.0)

	# 2b. Rumor en vivo en la taberna sobre el horario y ubicación de la trampilla del Club de Peleas
	_club_rumor_cooldown = maxf(0.0, _club_rumor_cooldown - delta)
	var cur_h_t: int = int(WorldClock.current_hour) if WorldClock else 12
	if cur_h_t >= 8 and cur_h_t < 24 and hall_seated_count == 0 and not vm.is_building_door_blocked(BUILDING_ID):
		on_hour(vm, cur_h_t)
	if not demo_active_t and (cur_h_t >= 20 or cur_h_t < 3) and _club_rumor_cooldown <= 0.0:
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
