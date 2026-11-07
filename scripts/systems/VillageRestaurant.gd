@tool
extends RefCounted

## R1 (crimen interno, 2026-11-06): el restaurante de aire italiano de película de cine negro. Nombre provisional
## «Trattoria Il Corvo» (anotado en docs/APORTES_CREATIVOS.md). Un local GRANDE con varias salas de verdad:
##   - Comedor (mesas con manteles de cuadros, velas en botellas, piano, barra con botellas).
##   - Terraza exterior al sur, junto a la puerta (mesas con sombrilla, macetas, guirnalda de bombillas).
##   - Cocina (fogones, encimera, ollas), con paso al comedor.
##   - Cámara frigorífica para la carne (hielo y piezas colgadas), con puerta desde la cocina.
##   - Bodega (barriles y vino), cuarto del dueño y un reservado con mesa redonda al fondo (lo usará la Familia en R2).
## El puesto empieza VACANTE (como la panadería): lo ocupa un cocinero por las reglas de siempre.
## Sin `class_name`: se carga con `preload`.

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")

const BUILDING_ID: String = "building_restaurant"
const TITLE: String = "🍝 Trattoria 'Il Corvo'"
const FAMILY_ID: String = "family_corvo"
const FAMILY_NAME: String = "Casa del Corvo"

## Edificio: 275 × 190, puerta al sur (mira a la cámara y a la terraza). Detrás del albergue y del taller.
const RECT: Rect2 = Rect2(Vector2(1020, 214), Vector2(275, 190))
const DOOR_X: float = 1120.0
const DOOR_W: float = 36.0
const ROW_Y: float = 294.0 ## tabique entre la fila del fondo (salas pequeñas) y la de delante (comedor y cocina)
const KITCHEN_X: float = 1215.0 ## tabique entre comedor y cocina (y entre el cuarto del dueño y la cámara)
const GAP: float = 30.0 ## anchura de los pasos entre salas

## Salas (para que los vecinos crucen los tabiques por los pasos). Fila de delante: comedor y cocina.
const ROOMS: Dictionary = {
	"comedor": Rect2(Vector2(1020, 294), Vector2(195, 110)),
	"cocina": Rect2(Vector2(1215, 294), Vector2(80, 110)),
	"reservado": Rect2(Vector2(1020, 214), Vector2(85, 80)),
	"bodega": Rect2(Vector2(1105, 214), Vector2(55, 80)),
	"dueno": Rect2(Vector2(1160, 214), Vector2(55, 80)),
	"camara": Rect2(Vector2(1215, 214), Vector2(80, 80)),
}
const ROOM_NAMES: Dictionary = {
	"comedor": "Comedor", "cocina": "Cocina", "reservado": "Reservado", "bodega": "Bodega",
	"dueno": "Cuarto del dueño", "camara": "Cámara frigorífica",
}
## Pasos entre salas: «h» = hueco en un tabique horizontal (se cruza en vertical), «v» = en uno vertical.
const OPENINGS: Array = [
	{"a": "comedor", "b": "reservado", "pos": Vector2(1062, 294), "axis": "h"},
	{"a": "comedor", "b": "bodega", "pos": Vector2(1132, 294), "axis": "h"},
	{"a": "comedor", "b": "dueno", "pos": Vector2(1187, 294), "axis": "h"},
	{"a": "comedor", "b": "cocina", "pos": Vector2(1215, 349), "axis": "v"},
	{"a": "cocina", "b": "camara", "pos": Vector2(1255, 294), "axis": "h"},
]

## Terraza exterior y sendero desde el camino del este (sigue la senda de la loma del este hacia el sur).
const TERRACE: Rect2 = Rect2(Vector2(1020, 410), Vector2(305, 40))
const PATH_RECT: Rect2 = Rect2(Vector2(1305, 64), Vector2(20, 346))
const TERRACE_TABLES: Array[Vector2] = [Vector2(1042, 430), Vector2(1080, 430), Vector2(1165, 430), Vector2(1205, 430), Vector2(1250, 430)]

## Sitios con uso (calculados, sin guardar nada).
const STOVE_POS: Vector2 = Vector2(1278, 318) ## fogones (donde trabaja el cocinero)
const KITCHEN_COUNTER: Vector2 = Vector2(1255, 392)
const COLD_SHELF: Vector2 = Vector2(1262, 236) ## colgadero de carne en la cámara
const COUNTER_POS: Vector2 = Vector2(1192, 388) ## barra y caja del comedor (gestionar el negocio)
const PIANO_POS: Vector2 = Vector2(1036, 392)
const DINING_TABLES: Array[Vector2] = [Vector2(1044, 320), Vector2(1092, 320), Vector2(1150, 320), Vector2(1044, 366), Vector2(1160, 368)]
const BACKROOM_TABLE: Vector2 = Vector2(1062, 248)
const OWNER_BED: Vector2 = Vector2(1176, 236)
const OWNER_BED2: Vector2 = Vector2(1200, 262)
const OWNER_CHEST: Vector2 = Vector2(1204, 228)
const WINE_RACK: Vector2 = Vector2(1132, 224)

const PROPS: String = "res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/"

# ---------------------------------------------------------------- montaje
static func setup_world(vm) -> void:
	var role: int = int(VillageNPC.TradeRole.RESTAURATEUR)
	vm.trade_configs[role] = {
		"family_id": FAMILY_ID, "family_name": FAMILY_NAME, "shop_title": TITLE,
		"shop_center": RECT.get_center(), "is_mixed_building": true,
		"house_title": TITLE, "house_center": RECT.get_center(),
		"title": "Cocinero", "tex": vm._load_tex("res://assests/world/village/villager_innkeeper.png"),
		"stock": {"pasta_dish": 3, "braised_meat": 1}, "work_pos": STOVE_POS, "bed1_pos": OWNER_BED,
		"bed2_pos": OWNER_BED2, "table_pos": DINING_TABLES[3],
	}
	if not vm.house_pantry.has(FAMILY_ID):
		vm.house_pantry[FAMILY_ID] = 2

static func build(vm) -> void:
	var c: Vector2 = RECT.get_center()
	vm._construct_solid_building(BUILDING_ID, TITLE, c, RECT.size, true,
		"res://assests/world/village/floor_wood_planks.png", "res://assests/world/village/wall_stone_h.png",
		"res://assests/world/village/wall_stone_v.png", DOOR_W, DOOR_X - c.x, Color(1.0, 0.82, 0.55))
	_build_partitions(vm)
	_build_room_floors(vm)
	_build_furniture(vm)
	_build_terrace(vm)
	var stall: Sprite2D = vm._add_sprite_prop(vm._load_tex(PROPS + "storage_countertop_0.png"), COUNTER_POS, Vector2(0.55, 0.55), -1)
	vm._register_shop_business_stall(int(VillageNPC.TradeRole.RESTAURATEUR), TITLE, FAMILY_ID, COUNTER_POS, stall)
	vm._spawn_house_chest(OWNER_CHEST, "Cofre de " + TITLE, FAMILY_ID)

## Tabiques con sus pasos (huecos de GAP px). Muros de piedra, igual que el exterior.
static func _build_partitions(vm) -> void:
	var th: Texture2D = vm._load_tex("res://assests/world/village/wall_stone_h.png")
	var tv: Texture2D = vm._load_tex("res://assests/world/village/wall_stone_v.png")
	var x0: float = RECT.position.x
	var x1: float = RECT.end.x
	# Tabique horizontal del fondo, con los pasos de reservado, bodega, cuarto y cámara
	var gaps: Array[float] = []
	for o in OPENINGS:
		if str(o["axis"]) == "h":
			gaps.append(float((o["pos"] as Vector2).x))
	gaps.sort()
	var cur: float = x0
	for gx in gaps:
		var a: float = gx - GAP * 0.5
		if a - cur > 2.0:
			vm._add_solid_wall_segment(Vector2((cur + a) * 0.5, ROW_Y), Vector2(a - cur, 6.0), th)
		cur = gx + GAP * 0.5
	if x1 - cur > 2.0:
		vm._add_solid_wall_segment(Vector2((cur + x1) * 0.5, ROW_Y), Vector2(x1 - cur, 6.0), th)
	# Tabiques verticales de la fila del fondo
	for vx in [1105.0, 1160.0]:
		vm._add_solid_wall_segment(Vector2(vx, (RECT.position.y + ROW_Y) * 0.5), Vector2(6.0, ROW_Y - RECT.position.y), tv)
	# Tabique comedor | cocina (y cuarto | cámara), con el paso de la cocina en la fila de delante
	var top: float = RECT.position.y
	var bottom: float = RECT.end.y
	var gy: float = 349.0
	vm._add_solid_wall_segment(Vector2(KITCHEN_X, (top + gy - GAP * 0.5) * 0.5), Vector2(6.0, gy - GAP * 0.5 - top), tv)
	vm._add_solid_wall_segment(Vector2(KITCHEN_X, (gy + GAP * 0.5 + bottom) * 0.5), Vector2(6.0, bottom - gy - GAP * 0.5), tv)

## Suelos por sala (cocina de baldosa, cámara de piedra fría, reservado con alfombra roja).
static func _build_room_floors(vm) -> void:
	vm._add_rect_poly(ROOMS["cocina"].get_center(), ROOMS["cocina"].size * 0.5 - Vector2(3, 3), Color(0.78, 0.74, 0.66, 1.0), -2)
	vm._add_rect_poly(ROOMS["camara"].get_center(), ROOMS["camara"].size * 0.5 - Vector2(3, 3), Color(0.70, 0.82, 0.90, 1.0), -2)
	vm._add_rect_poly(ROOMS["bodega"].get_center(), ROOMS["bodega"].size * 0.5 - Vector2(3, 3), Color(0.40, 0.30, 0.22, 1.0), -2)
	vm._add_rect_poly(BACKROOM_TABLE, Vector2(30, 24), Color(0.48, 0.10, 0.10, 1.0), -2)
	# Manteles de cuadros rojos y blancos bajo cada mesa del comedor
	for t in DINING_TABLES:
		vm._add_rect_poly(t, Vector2(13, 9), Color(0.86, 0.22, 0.20, 1.0), -2)
		for q in [Vector2(-6.5, -4.5), Vector2(6.5, 4.5)]: # dos cuadros blancos en diagonal
			vm._add_rect_poly(t + q, Vector2(6.5, 4.5), Color(0.96, 0.94, 0.90, 1.0), -2)

static func _build_furniture(vm) -> void:
	for t in DINING_TABLES:
		vm._spawn_decor_prop(PROPS + "table_chairs_0.png", t, Vector2(0.42, 0.42))
	vm._spawn_decor_prop(PROPS + "piano.png", PIANO_POS, Vector2(0.5, 0.5))
	vm._spawn_decor_prop(PROPS + "drinks_shelf_0.png", COUNTER_POS + Vector2(0, 12), Vector2(0.5, 0.5))
	vm._spawn_decor_prop(PROPS + "plants_3.png", Vector2(1028, 302), Vector2(0.5, 0.5))
	vm._spawn_decor_prop(PROPS + "plants_5.png", Vector2(1207, 302), Vector2(0.5, 0.5))
	# Cocina
	vm._spawn_decor_prop(PROPS + "stove.png", STOVE_POS, Vector2(0.55, 0.55))
	vm._spawn_decor_prop(PROPS + "storage_countertop2_0.png", KITCHEN_COUNTER, Vector2(0.55, 0.55))
	vm._spawn_decor_prop(PROPS + "kitchen_props_3.png", Vector2(1230, 330), Vector2(0.5, 0.5))
	vm._spawn_decor_prop(PROPS + "pots_pack_0.png", Vector2(1286, 360), Vector2(0.5, 0.5))
	# Cámara frigorífica: bloques de hielo y piezas de carne colgadas
	for ip in [Vector2(1226, 222), Vector2(1226, 240), Vector2(1288, 222)]:
		vm._add_rect_poly(ip, Vector2(6, 6), Color(0.82, 0.94, 1.0, 1.0), -1)
	for mp in [Vector2(1248, 230), Vector2(1262, 230), Vector2(1276, 230)]:
		vm._add_rect_poly(mp, Vector2(3.5, 7), Color(0.70, 0.16, 0.14, 1.0), -1)
	vm._spawn_decor_prop(PROPS + "crates_3.png", Vector2(1284, 270), Vector2(0.5, 0.5))
	# Bodega
	vm._spawn_decor_prop(PROPS + "drinks_shelf_1.png", WINE_RACK, Vector2(0.5, 0.5))
	vm._spawn_decor_prop(PROPS + "barrels3_0.png", Vector2(1116, 262), Vector2(0.5, 0.5))
	vm._spawn_decor_prop(PROPS + "barrels_2.png", Vector2(1150, 262), Vector2(0.5, 0.5))
	# Reservado y cuarto del dueño
	vm._spawn_decor_prop(PROPS + "big_round_table_chairs_0.png", BACKROOM_TABLE, Vector2(0.5, 0.5))
	vm._spawn_decor_prop(PROPS + "fireplace_0.png", Vector2(1030, 226), Vector2(0.45, 0.45))
	var tex_bed: Texture2D = vm._load_tex("res://assests/world/village/tavern_bed.png")
	for b in [OWNER_BED, OWNER_BED2]:
		vm._add_sprite_prop(tex_bed, b, Vector2(1.0, 1.0), -1)

static func _build_terrace(vm) -> void:
	vm._add_rect_poly(TERRACE.get_center(), TERRACE.size * 0.5, Color(0.62, 0.50, 0.40, 1.0), -2) # Losas de barro
	vm._add_rect_poly(PATH_RECT.get_center(), PATH_RECT.size * 0.5, Color(0.55, 0.47, 0.36, 1.0), -3) # Sendero
	for t in TERRACE_TABLES:
		vm._spawn_decor_prop(PROPS + "round_table_0.png", t, Vector2(0.4, 0.4))
	for pp in [Vector2(1024, 446), Vector2(1300, 446)]:
		vm._spawn_decor_prop(PROPS + "plants_8.png", pp, Vector2(0.5, 0.5))

# ---------------------------------------------------------------- recorrido por dentro
static func room_of(p: Vector2) -> String:
	for k in ROOMS:
		if (ROOMS[k] as Rect2).grow(1.0).has_point(p):
			return str(k)
	return ""

## Punto de un paso del lado de la sala `room` (a 12 px del tabique).
static func _side_point(o: Dictionary, room: String) -> Vector2:
	var pos: Vector2 = o["pos"]
	var rc: Vector2 = (ROOMS[room] as Rect2).get_center()
	if str(o["axis"]) == "h":
		return pos + Vector2(0, 12.0 * signf(rc.y - pos.y))
	return pos + Vector2(12.0 * signf(rc.x - pos.x), 0)

static func _path_rooms(from_room: String, to_room: String) -> Array:
	var prev: Dictionary = {from_room: ""}
	var queue: Array = [from_room]
	while not queue.is_empty():
		var r: String = queue.pop_front()
		if r == to_room:
			break
		for o in OPENINGS:
			var nxt: String = ""
			if str(o["a"]) == r:
				nxt = str(o["b"])
			elif str(o["b"]) == r:
				nxt = str(o["a"])
			if nxt != "" and not prev.has(nxt):
				prev[nxt] = r
				queue.append(nxt)
	if not prev.has(to_room):
		return []
	var path: Array = [to_room]
	while path[0] != from_room:
		path.push_front(prev[path[0]])
	return path

static func _opening_between(a: String, b: String) -> Dictionary:
	for o in OPENINGS:
		if (str(o["a"]) == a and str(o["b"]) == b) or (str(o["a"]) == b and str(o["b"]) == a):
			return o
	return {}

## Siguiente punto para ir de `from_pos` a `target_pos` dentro del restaurante, cruzando por los pasos.
static func route(from_pos: Vector2, target_pos: Vector2) -> Vector2:
	var ra: String = room_of(from_pos)
	var rb: String = room_of(target_pos)
	if ra == "" or rb == "" or ra == rb:
		return target_pos
	var path: Array = _path_rooms(ra, rb)
	if path.size() < 2:
		return target_pos
	var o: Dictionary = _opening_between(path[0], path[1])
	var near: Vector2 = _side_point(o, path[0])
	var far: Vector2 = _side_point(o, path[1])
	var pos: Vector2 = o["pos"]
	var in_gap: bool
	if str(o["axis"]) == "h":
		in_gap = absf(from_pos.x - pos.x) <= 9.0 and absf(from_pos.y - pos.y) <= 14.0
	else:
		in_gap = absf(from_pos.y - pos.y) <= 9.0 and absf(from_pos.x - pos.x) <= 14.0
	return far if in_gap else near
