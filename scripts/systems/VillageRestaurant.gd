@tool
extends RefCounted
const _AN_SITIOS = preload("res://mapa/anclas.gd") # plan de sitios: zonas fijas siguen a lo movido

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
const Marca = preload("res://mapa/marca.gd")

const BUILDING_ID: String = "building_restaurant"
const TITLE: String = "🍲 Casa de Comidas 'El Fogón del Valle'"
const FAMILY_ID: String = "family_corvo"
const FAMILY_NAME: String = "Casa del Corvo"

## Edificio: 275 × 190, puerta al sur (mira a la Calle Mayor y a la terraza, lejos del cementerio).
const BASE: Vector2 = Vector2(-255, -206)
const RECT: Rect2 = Rect2(BASE, Vector2(275, 190))

## Salas (para que los vecinos crucen los tabiques por los pasos). Fila de delante: comedor y cocina.
const ROOMS: Dictionary = {
	"comedor": Rect2(BASE + Vector2(0, 80), Vector2(195, 110)),
	"cocina": Rect2(BASE + Vector2(195, 80), Vector2(80, 110)),
	"reservado": Rect2(BASE + Vector2(0, 0), Vector2(85, 80)),
	"bodega": Rect2(BASE + Vector2(85, 0), Vector2(55, 80)),
	"dueno": Rect2(BASE + Vector2(140, 0), Vector2(55, 80)),
	"camara": Rect2(BASE + Vector2(195, 0), Vector2(80, 80)),
}
const ROOM_NAMES: Dictionary = {
	"comedor": "Comedor", "cocina": "Cocina", "reservado": "Reservado", "bodega": "Bodega",
	"dueno": "Despacho del dueño", "camara": "Cámara frigorífica",
}
## Pasos entre salas: «h» = hueco en un tabique horizontal (se cruza en vertical), «v» = en uno vertical.
const OPENINGS: Array = [
	{"a": "comedor", "b": "reservado", "pos": BASE + Vector2(42, 80), "axis": "h"},
	{"a": "comedor", "b": "bodega", "pos": BASE + Vector2(112, 80), "axis": "h"},
	{"a": "comedor", "b": "dueno", "pos": BASE + Vector2(167, 80), "axis": "h"},
	{"a": "comedor", "b": "cocina", "pos": BASE + Vector2(195, 135), "axis": "v"},
	{"a": "cocina", "b": "camara", "pos": BASE + Vector2(235, 80), "axis": "h"},
]

## Terraza exterior y acceso directo desde la Calle Mayor (camino principal hacia la Plaza).
const TERRACE: Rect2 = Rect2(BASE + Vector2(0, 196), Vector2(275, 40))
## Sitios con uso: son marcas de la escena del edificio (mapa/edificios/building_restaurant.tscn → «Marcas»), no
## números aquí. Se piden con sitio(M_…), dining_tables() y terrace_tables(); llegan en el mapa original, como
## esperan las funciones que colocan cosas y vecinos.
const M_FOGONES: String = "fogones"        ## donde trabaja el cocinero
const M_ENCIMERA: String = "encimera"
const M_COLGADERO: String = "colgadero"    ## colgadero de carne en la cámara
const M_BARRA: String = Marca.PUESTO       ## barra y caja del comedor (gestionar el negocio)
const M_PIANO: String = "piano"
const M_RESERVADO: String = "mesa_reservado"
const M_CAMA_DUENO: String = Marca.CAMA_1
const M_CAMA_2: String = Marca.CAMA_2
const M_COFRE: String = Marca.COFRE
const M_BOTELLERO: String = "botellero"
const M_MESA: String = "mesa_%d"           ## mesas del comedor, de la 1 a MESAS_COMEDOR
const M_MESA_TERRAZA: String = "mesa_terraza_%d"
const MESAS_COMEDOR: int = 5
const MESAS_TERRAZA: int = 5
const MESA_FAMILIA: int = 3 ## (contando desde 0) la mesa de la familia del cocinero: no se ofrece a clientes
const MESA_JEFE: int = 4    ## (contando desde 0) la mesa del rincón, donde almuerza el jefe de la Familia

static var _mesas: Dictionary = {} ## nombre de marca con %d → lista de sitios (se leen una vez)

const PROPS: String = "res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/"

static func sitio(marca: String) -> Vector2:
	return Marca.sitio(BUILDING_ID, marca)

static func dining_tables() -> Array[Vector2]:
	return _lista_de_mesas(M_MESA, MESAS_COMEDOR)

static func terrace_tables() -> Array[Vector2]:
	return _lista_de_mesas(M_MESA_TERRAZA, MESAS_TERRAZA)

static func _lista_de_mesas(marca: String, cuantas: int) -> Array[Vector2]:
	if not _mesas.has(marca):
		var lista: Array[Vector2] = []
		for i in range(1, cuantas + 1):
			lista.append(sitio(marca % i))
		_mesas[marca] = lista
	return _mesas[marca]

# ---------------------------------------------------------------- montaje
static func setup_world(vm) -> void:
	var role: int = int(VillageNPC.TradeRole.RESTAURATEUR)
	vm.trade_configs[role] = {
		"family_id": FAMILY_ID, "family_name": FAMILY_NAME, "shop_title": TITLE,
		"shop_center": RECT.get_center(), "is_mixed_building": true,
		"house_title": TITLE, "house_center": RECT.get_center(),
		"title": "Cocinero", "tex": vm._load_tex("res://assests/world/village/villager_innkeeper.png"),
		"stock": {"pasta_dish": 3, "braised_meat": 1}, "work_pos": sitio(M_FOGONES), "bed1_pos": sitio(M_CAMA_DUENO),
		"bed2_pos": sitio(M_CAMA_2), "table_pos": dining_tables()[MESA_FAMILIA],
	}
	if not vm.house_pantry.has(FAMILY_ID):
		vm.house_pantry[FAMILY_ID] = 2

static func build(vm) -> void:
	var c: Vector2 = RECT.get_center()
	vm._construct_solid_building(BUILDING_ID, TITLE, c,
		"res://assests/world/village/floor_wood_planks.png", "res://assests/world/village/wall_stone_h.png", "res://assests/world/village/wall_stone_v.png")
	_build_furniture(vm)
	_build_terrace(vm)
	vm._add_prop_collider(sitio(M_BARRA), vm.COLISOR_PUESTO)
	vm._register_shop_business_stall(int(VillageNPC.TradeRole.RESTAURATEUR), TITLE, FAMILY_ID, sitio(M_BARRA))
	vm._spawn_house_chest(sitio(M_COFRE), "Cofre de " + TITLE, FAMILY_ID)

static func _build_furniture(vm) -> void:
	for t in dining_tables():
		vm._spawn_decor_prop(PROPS + "table_chairs_0.png", t)
	vm._spawn_decor_prop(PROPS + "piano.png", sitio(M_PIANO))
	vm._spawn_decor_prop(PROPS + "drinks_shelf_0.png", sitio(M_BARRA) + Vector2(0, 12))
	vm._spawn_decor_prop(PROPS + "plants_3.png", BASE + Vector2(8, 88))
	vm._spawn_decor_prop(PROPS + "plants_5.png", BASE + Vector2(187, 88))
	# Cocina
	vm._spawn_decor_prop(PROPS + "stove.png", sitio(M_FOGONES))
	vm._spawn_decor_prop(PROPS + "storage_countertop2_0.png", sitio(M_ENCIMERA))
	vm._spawn_decor_prop(PROPS + "kitchen_props_3.png", BASE + Vector2(210, 116))
	vm._spawn_decor_prop(PROPS + "pots_pack_0.png", BASE + Vector2(266, 146))
	# Cámara frigorífica
	vm._spawn_decor_prop(PROPS + "crates_3.png", BASE + Vector2(264, 56))
	# Bodega
	vm._spawn_decor_prop(PROPS + "drinks_shelf_1.png", sitio(M_BOTELLERO))
	vm._spawn_decor_prop(PROPS + "barrels3_0.png", BASE + Vector2(96, 48))
	vm._spawn_decor_prop(PROPS + "barrels_2.png", BASE + Vector2(130, 48))
	# Reservado y despacho del dueño
	vm._spawn_decor_prop(PROPS + "big_round_table_chairs_0.png", sitio(M_RESERVADO))
	vm._spawn_decor_prop(PROPS + "fireplace_0.png", BASE + Vector2(10, 12))
	vm._spawn_decor_prop(PROPS + "table_chairs_0.png", sitio(M_CAMA_DUENO))
	vm._spawn_decor_prop(PROPS + "storage_countertop_0.png", BASE + Vector2(154, 8))

static func _build_terrace(vm) -> void:
	# Terraza: mesas y macetas (pasan a 3D)
	for t in terrace_tables():
		vm._spawn_decor_prop(PROPS + "round_table_0.png", t)
	for pp in [BASE + Vector2(4, 232), BASE + Vector2(80, 232), BASE + Vector2(120, 232), BASE + Vector2(270, 232)]:
		vm._spawn_decor_prop(PROPS + "plants_8.png", pp)

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

# ==========================================================================
# R1b: vida en el restaurante. Los vecinos con dinero salen a comer o a cenar (13–22 h) cuando el cocinero está
# trabajando; se sientan en una mesa del comedor o de la terraza y pagan su plato al cocinero (suma cero: el plato
# sale de su existencia y el oro pasa de uno a otro). Si no queda nada en la cocina, se van a cenar a casa.
# El cocinero baja a la cámara fría a por la carne antes de cada estofado.
# ==========================================================================
const OPEN_FROM: int = 12
const OPEN_TO: int = 23
const MENU_PRICES: Dictionary = {"braised_meat": 18, "pasta_dish": 12}
const MIN_GOLD_TO_DINE: int = 30

static func cook(vm):
	if vm == null or not ("trade_npcs" in vm):
		return null
	var c = vm.trade_npcs.get(int(VillageNPC.TradeRole.RESTAURATEUR))
	if c == null or not is_instance_valid(c) or c.is_dead:
		return null
	return c

## El local sirve si el cocinero está trabajando dentro (en los fogones, en la cámara o en la barra).
static func is_serving(vm) -> bool:
	var c = cook(vm)
	if c == null or c.is_incapacitated() or c.is_sleeping or c.is_hostile:
		return false
	if int(c.current_activity) != int(VillageNPC.ActivityState.WORKING):
		return false
	if vm.has_method("is_trade_sabotaged") and bool(vm.call("is_trade_sabotaged", int(VillageNPC.TradeRole.RESTAURATEUR))):
		return false
	return room_of(_AN_SITIOS.desmover(c.global_position)) != ""

static func has_food(vm) -> bool:
	var c = cook(vm)
	if c == null:
		return false
	for k in MENU_PRICES:
		if int(c.shop_stock.get(k, 0)) > 0:
			return true
	return false

## Sitios para sentarse: dos sillas enfrentadas junto a cada mesa del comedor (menos la de la familia del cocinero) y de la terraza (sincronizadas con las sillas 3D de _restaurant_table_3d).
static func indoor_seats() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var mesas: Array[Vector2] = dining_tables()
	for i in mesas.size():
		if i == MESA_FAMILIA:
			continue
		out.append(mesas[i] + Vector2(-14.5, 0.0))
		out.append(mesas[i] + Vector2(14.5, 0.0))
	var act: Array[Vector2] = [] # plan de sitios: en su sitio actual (sigue al restaurante movido)
	act.assign(_AN_SITIOS.mover_lista("restaurante_comedor", out))
	return act

static func terrace_seats() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for t in terrace_tables():
		out.append(t + Vector2(-12.5, 0.0))
		out.append(t + Vector2(12.5, 0.0))
	var act: Array[Vector2] = []
	act.assign(_AN_SITIOS.mover_lista("restaurante_terraza", out))
	return act

static func seats() -> Array[Vector2]:
	var out: Array[Vector2] = indoor_seats()
	out.append_array(terrace_seats())
	return out

## Recibe y devuelve sitios actuales.
static func table_center_for_seat(seat: Vector2) -> Vector2:
	for t in _AN_SITIOS.mover_lista("restaurante_mesas_terraza", terrace_tables()):
		if seat.distance_to(t) <= 18.0:
			return t
	for t in _AN_SITIOS.mover_lista("restaurante_mesas", dining_tables()):
		if seat.distance_to(t) <= 20.0:
			return t
	return _AN_SITIOS.mover(RECT.get_center())

static func is_at_seat(pos: Vector2) -> bool:
	if not RECT.grow(6.0).has_point(_AN_SITIOS.desmover(pos)) and not TERRACE.grow(10.0).has_point(_AN_SITIOS.desmover(pos)):
		return false
	for s in seats():
		if pos.distance_to(s) <= 6.5:
			return true
	return false

static func snap_seat_pos(pos: Vector2) -> Vector2:
	for s in seats():
		if pos.distance_to(s) <= 6.5:
			return s
	return pos

static func is_seat_taken(vm, pos: Vector2, ignore_npc = null) -> bool:
	if vm == null:
		return false
	for n in VillageNeeds.living(vm):
		if n == ignore_npc:
			continue
		if n.global_position.distance_to(pos) <= 9.0:
			return true
		var s = n.get("_restaurant_seat")
		if s is Vector2 and (s as Vector2).distance_to(pos) <= 4.0:
			return true
		if n.errand_kind != "" and n.errand_pos.distance_to(pos) <= 7.0:
			return true
	return false

static func pick_terrace_seat_for(vm, npc) -> Vector2:
	var free: Array[Vector2] = []
	for s in terrace_seats():
		if not is_seat_taken(vm, s, npc):
			free.append(s)
	if free.is_empty():
		return Vector2.ZERO
	return free[absi(npc.npc_name.hash() + VillageNeeds.total_hours()) % free.size()] # hora del juego, no reloj real

static func pick_indoor_seat_for(vm, npc) -> Vector2:
	var free: Array[Vector2] = []
	for s in indoor_seats():
		if not is_seat_taken(vm, s, npc):
			free.append(s)
	if free.is_empty():
		return Vector2.ZERO
	return free[absi(npc.npc_name.hash() + VillageNeeds.total_hours()) % free.size()] # hora del juego, no reloj real

## ¿Sale este vecino a comer al restaurante? Devuelve el sitio donde se sienta, o Vector2.ZERO si no.
static func pick_seat_for(vm, npc, force: bool = false) -> Vector2:
	if vm == null or npc == null or npc.is_dead:
		return Vector2.ZERO
	if int(npc.trade_role) in [int(VillageNPC.TradeRole.RESTAURATEUR), int(VillageNPC.TradeRole.INNKEEPER), int(VillageNPC.TradeRole.UNEMPLOYED), int(VillageNPC.TradeRole.CHILD)]:
		return Vector2.ZERO
	if str(npc.family_id) == FAMILY_ID or bool(npc.get("is_vagrant_camper")):
		return Vector2.ZERO
	var h: int = WorldClock.current_hour if WorldClock else 12
	if h < 12 or h >= 23 or int(npc.personal_gold) < MIN_GOLD_TO_DINE:
		return Vector2.ZERO
	if not is_serving(vm) or not has_food(vm):
		return Vector2.ZERO
	var chance: float = 0.35 if int(npc.personal_gold) >= 140 else 0.16
	if h >= 18:
		chance *= 1.75 # de cena salen más
	if not force and randf() >= chance:
		return Vector2.ZERO
	# Al atardecer y de noche prefieren la terraza iluminada si no llueve
	var raining: bool = WorldClock != null and int(WorldClock.current_weather) == 1
	if h >= 18 and not raining:
		var ts: Vector2 = pick_terrace_seat_for(vm, npc)
		if ts != Vector2.ZERO:
			return ts
	var free: Array[Vector2] = []
	for s in seats():
		if not is_seat_taken(vm, s, npc):
			free.append(s)
	if free.is_empty():
		return Vector2.ZERO # lleno
	return free[randi() % free.size()]

const TERRACE_CALLOUTS: Array[String] = [
	"🍷 «Qué buena noche hace en la terraza bajo las bombillas...»",
	"🍝 «Un plato caliente y una copa de vino después del jornal.»",
	"🕯️ «Aquí fuera se está de lujo viendo pasar a la gente.»",
	"🍷 «Brindemos por otra tarde tranquila en el valle.»",
]
static var _terrace_callout_cooldown: float = 6.0

## Al mediodía, tarde y noche (12:00 a 23:00), varios vecinos se sientan en las mesas de la terraza exterior y del comedor a comer y cenar.
static func on_hour(vm, hour: int) -> void:
	if vm == null:
		return
	if hour < OPEN_FROM or hour >= 24:
		return
	var raining: bool = WorldClock != null and int(WorldClock.current_weather) == 1
	var terrace_count: int = 0
	var hall_count: int = 0
	for n in VillageNeeds.living(vm):
		if n.errand_kind != "leisure":
			continue
		var lp: String = str(n.get_meta("leisure_place", ""))
		if lp == "restaurant_terrace":
			terrace_count += 1
		elif lp == "restaurant_hall":
			hall_count += 1

	var candidates: Array = []
	for n in VillageNeeds.living(vm):
		if n.is_vagrant_camper or n.is_sleeping or n.rite_pos != Vector2.ZERO or n.errand_kind != "":
			continue
		if int(n.trade_role) in [int(VillageNPC.TradeRole.RESTAURATEUR), int(VillageNPC.TradeRole.INNKEEPER), int(VillageNPC.TradeRole.WAITER), int(VillageNPC.TradeRole.CHILD), int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.ROYAL_INVESTIGATOR)]:
			continue
		var can_go: bool = VillageNeeds.is_free(n) or int(n.trade_role) in [int(VillageNPC.TradeRole.UNEMPLOYED), int(VillageNPC.TradeRole.FAMILY_MEMBER), int(VillageNPC.TradeRole.NOBLE)]
		if can_go and int(n.personal_gold) >= 8:
			candidates.append(n)
	candidates.shuffle()

	var target_terrace: int = 0 if raining else 5
	var target_hall: int = 3
	for cand in candidates:
		if hall_count < 2 and not vm.is_building_door_blocked(BUILDING_ID):
			var h_seat0: Vector2 = pick_indoor_seat_for(vm, cand)
			if h_seat0 != Vector2.ZERO:
				cand.set_meta("leisure_place", "restaurant_hall")
				cand.start_errand("leisure", h_seat0)
				cand.global_position = h_seat0
				cand.facing_direction = (table_center_for_seat(h_seat0) - h_seat0).normalized()
				cand.set_meta("leisure_since", VillageNeeds.total_hours())
				cand.errand_since = VillageNeeds.total_hours()
				hall_count += 1
				continue
		if terrace_count < target_terrace:
			var t_seat: Vector2 = pick_terrace_seat_for(vm, cand)
			if t_seat != Vector2.ZERO:
				cand.set_meta("leisure_place", "restaurant_terrace")
				cand.start_errand("leisure", t_seat)
				if terrace_count < 3:
					cand.global_position = t_seat
					cand.facing_direction = (table_center_for_seat(t_seat) - t_seat).normalized()
					cand.set_meta("leisure_since", VillageNeeds.total_hours())
					cand.errand_since = VillageNeeds.total_hours()
				terrace_count += 1
				continue
		if hall_count < target_hall and not vm.is_building_door_blocked(BUILDING_ID):
			var h_seat: Vector2 = pick_indoor_seat_for(vm, cand)
			if h_seat != Vector2.ZERO:
				cand.set_meta("leisure_place", "restaurant_hall")
				cand.start_errand("leisure", h_seat)
				hall_count += 1
		if terrace_count >= target_terrace and hall_count >= target_hall:
			break

static func tick(vm, delta: float) -> void:
	if vm == null:
		return
	var cur_h: int = int(WorldClock.current_hour) if WorldClock else 12
	var is_open_hours: bool = (cur_h >= OPEN_FROM and cur_h < 24)
	var seated_terrace: Array = []
	for n in VillageNeeds.living(vm):
		if int(n.elevation_level) == 0 and n.velocity.length_squared() < 4.0:
			if is_at_seat(n.global_position):
				var snapped: Vector2 = snap_seat_pos(n.global_position)
				if n.global_position.distance_to(snapped) > 0.2:
					n.global_position = snapped
				var tc: Vector2 = table_center_for_seat(snapped)
				if tc.distance_to(snapped) > 1.0:
					n.facing_direction = (tc - snapped).normalized()
				if TERRACE.grow(10.0).has_point(_AN_SITIOS.desmover(snapped)):
					seated_terrace.append(n)
	if is_open_hours and seated_terrace.is_empty():
		on_hour(vm, cur_h)
	_terrace_callout_cooldown = maxf(0.0, _terrace_callout_cooldown - delta)
	if seated_terrace.size() >= 1 and _terrace_callout_cooldown <= 0.0:
		_terrace_callout_cooldown = randf_range(9.0, 15.0)
		var speaker = seated_terrace[randi() % seated_terrace.size()]
		speaker._spawn_floating_text(TERRACE_CALLOUTS[randi() % TERRACE_CALLOUTS.size()], Color(1.0, 0.86, 0.58), -30.0)

## Sirve el plato al vecino sentado: uno al azar de los que queden y pueda pagar. Devuelve false si no hay plato o dinero.
static func serve_meal(vm, npc) -> bool:
	var c = cook(vm)
	if c == null or npc == null or not is_serving(vm):
		return false
	var order: Array = ["braised_meat", "pasta_dish"]
	order.shuffle() # cada uno pide lo que le apetece (si no puede pagarlo o no queda, el otro)
	for dish in order:
		var price: int = int(MENU_PRICES[dish])
		if int(c.shop_stock.get(dish, 0)) <= 0 or int(npc.personal_gold) < price:
			continue
		c.shop_stock[dish] = int(c.shop_stock[dish]) - 1
		c._sync_shop_stock_to_vm()
		npc.personal_gold -= price
		c.personal_gold += price
		var dname: String = str(SimpleInventory.CATALOG.get(dish, {}).get("name", dish))
		var where: String = "en la terraza" if TERRACE.grow(14.0).has_point(_AN_SITIOS.desmover(npc.global_position)) else "en el comedor"
		vm.set_meta("restaurant_meals", int(vm.get_meta("restaurant_meals", 0)) + 1) # para la sonda
		npc.add_thought("Comió %s en la casa de comidas (-%d Oro, +8)" % [dname, price], 8.0)
		npc._spawn_floating_text("🍲 %s %s (-%d Oro)" % [dname, where, price], Color(1.0, 0.82, 0.55), -32.0)
		return true
	return false

## Antes de un estofado el cocinero va a por la carne a la cámara fría. Devuelve true mientras está en ello.
static func cook_cold_room_trip(npc, rec: Dictionary, delta: float) -> bool:
	if str(rec.get("input", "")) != "raw_meat" or int(npc.workshop_materials.get("raw_meat", 0)) <= 0:
		return false
	if npc.has_meta("cold_room_fetched"):
		return false
	if npc.global_position.distance_to(_AN_SITIOS.mover(sitio(M_COLGADERO))) > 10.0:
		npc._update_craft_bar_visual(0.3, "🥩 A la cámara fría a por carne", Color(0.6, 0.85, 1.0, 0.9))
		npc._move_towards_point(_AN_SITIOS.mover(sitio(M_COLGADERO)), 46.0, delta)
		return true
	npc.velocity = Vector2.ZERO
	npc.set_meta("cold_room_fetched", true)
	npc.set_meta("cold_room_trips", int(npc.get_meta("cold_room_trips", 0)) + 1)
	npc._spawn_floating_text("🥩❄️ Descuelga una pieza de la cámara", Color(0.7, 0.9, 1.0), -38.0)
	return false
