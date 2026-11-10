@tool
extends Node2D
class_name EcosystemManager

## Simulador de Ecosistema del Bosque ("La Cadena Trófica") — Fase 3.5
## - Ubica el Bosque Profundo alejado de la zona inicial (al Sur/Suroeste de la aldea, y = 350..1050).
## - Cada planta silvestre ofrece 2 brotes/bocados antes de agotarse (22 plantas x 2 = 44 raciones).
## - Regla de Saciedad y Día de Reserva: Comer 1 vez cubre la supervivencia del día; comer 2 veces (2/2)
##   llena al animal, le otorga 1 Día de Reserva sin comer al día siguiente y le permite buscar pareja.
## - Regla de Reproducción: Dos animales de la misma especie con 2/2 de comida deben encontrarse (SEEK_MATE)
##   para engendrar una cría que nace al amanecer.

var entities_root: Node = null

var rabbit_pool: Array[WildAnimal] = []
var deer_pool: Array[WildAnimal] = []
var fox_pool: Array[WildAnimal] = []
var boar_pool: Array[WildAnimal] = []

## Umbrales Matemáticos de Conservación Ecológica (N_min):
## Si la población activa es <= N_min, los aldeanos suspenden la extracción/caza de ese recurso ese día
## para no alterar la cadena trófica ni sobrecazar el bosque.
const MIN_SAFE_TREES: int = 16
const MIN_SAFE_ORE_VEINS: int = 5
const MIN_SAFE_WILD_FLORA: int = 16
const MIN_SAFE_RABBITS: int = 10
const MIN_SAFE_DEER: int = 5
const MIN_SAFE_BOARS: int = 4

## Polígono orgánico e irregular del Bosque Profundo (Paso 2: ~3.5 veces más grande y más al sur, sin bordes rectos).
const FOREST_POLY: Array[Vector2] = [
	Vector2(-1180, 790), Vector2(-920, 745), Vector2(-640, 775), Vector2(-360, 735),
	Vector2(-80, 765), Vector2(180, 740), Vector2(465, 730), Vector2(740, 760),
	Vector2(1040, 735), Vector2(1340, 795), Vector2(1580, 940), Vector2(1640, 1240),
	Vector2(1560, 1580), Vector2(1620, 1920), Vector2(1440, 2240), Vector2(1120, 2360),
	Vector2(720, 2310), Vector2(340, 2390), Vector2(-80, 2330), Vector2(-480, 2380),
	Vector2(-880, 2290), Vector2(-1220, 2140), Vector2(-1340, 1820), Vector2(-1280, 1440),
	Vector2(-1360, 1080)
]

var burrow_positions: Array[Vector2] = [
	Vector2(-920, 880),
	Vector2(-640, 850),
	Vector2(-420, 960),
	Vector2(-780, 1120),
	Vector2(-520, 1180)
]
var deer_clearing_positions: Array[Vector2] = [
	Vector2(40, 1060),
	Vector2(360, 1180),
	Vector2(120, 1520),
	Vector2(480, 1680),
	Vector2(-120, 1840),
	Vector2(280, 2020)
]
var fox_den_positions: Array[Vector2] = [
	Vector2(780, 900),
	Vector2(1140, 980),
	Vector2(960, 1340),
	Vector2(1280, 1520)
]
var boar_rooting_positions: Array[Vector2] = [
	Vector2(-880, 1460),
	Vector2(-520, 1580),
	Vector2(-740, 1860),
	Vector2(-380, 1980)
]

var rabbit_extinct_days: int = 0
var deer_extinct_days: int = 0
var fox_extinct_days: int = 0
var boar_extinct_days: int = 0

func setup_ecosystem(target_entities_root: Node) -> void:
	entities_root = target_entities_root if target_entities_root else self
	add_to_group("ecosystem_manager")
	_spawn_distant_forest()
	if not Engine.is_editor_hint() and WorldClock and not WorldClock.day_passed.is_connected(_on_day_passed):
		WorldClock.day_passed.connect(_on_day_passed)
	if not Engine.is_editor_hint() and GameManager != null and GameManager.has_method("is_demo_mode"):
		_on_demo_mode_changed(GameManager.is_demo_mode())

func _on_demo_mode_changed(enabled: bool) -> void:
	for pool in [rabbit_pool, deer_pool, fox_pool, boar_pool]:
		for a in pool:
			if is_instance_valid(a):
				if enabled:
					a.velocity = Vector2.ZERO
				a.set_physics_process(not enabled)

func _load_tex(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var t = load(res_path)
		if t is Texture2D:
			return t
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img and not img.is_empty():
			var itex := ImageTexture.create_from_image(img)
			itex.set_meta("src_path", res_path) # la usa el escenario 3D para reconocer, p. ej., los pinos
			return itex
	return null

func _spawn_distant_forest() -> void:
	var tex_tree: Texture2D = _load_tex("res://assests/Comprados/Epic RPG World - The Village V2.1/tilesets and props/props-sprites/pine-tree_0.png")
	if not tex_tree:
		tex_tree = _load_tex("res://assests/world/tree.png")
	var tex_stump: Texture2D = _load_tex("res://assests/Comprados/Epic RPG World - The Village V2.1/tilesets and props/props-sprites/logs_0.png")
	var tex_rock: Texture2D = _load_tex("res://assests/world/harvest/rock_iron_vein.png")
	var tex_rock_depleted: Texture2D = _load_tex("res://assests/world/harvest/rock_depleted.png")
	var tex_herb: Texture2D = _load_tex("res://assests/world/harvest/wild_herb.png")
	var tex_mushroom: Texture2D = _load_tex("res://assests/world/harvest/wild_mushroom.png")
	var tex_deer: Texture2D = _load_tex("res://assests/world/harvest/wild_deer.png")
	var tex_rabbit: Texture2D = _load_tex("res://assests/world/harvest/wild_rabbit.png")
	var tex_fox: Texture2D = _load_tex("res://assests/world/harvest/wild_fox.png")
	var tex_boar: Texture2D = _load_tex("res://assests/world/harvest/wild_boar.png")
	var tex_burrow: Texture2D = _load_tex("res://assests/world/harvest/rabbit_burrow.png")
	var tex_den: Texture2D = _load_tex("res://assests/world/harvest/fox_den.png")

	# 0. Suelo orgánico del Bioma de Bosque Profundo (y = 730..2390, ~3.5x más grande y sin línea recta perimetral)
	var forest_turf := Polygon2D.new()
	forest_turf.polygon = PackedVector2Array(FOREST_POLY)
	forest_turf.color = Color(0.11, 0.25, 0.14, 0.42)
	forest_turf.z_index = -4
	entities_root.add_child(forest_turf)

	# Carteles de Entrada al Bosque y de los 4 Hábitats Separados
	_spawn_forest_sign(Vector2(465, 745), "🌲 Entrada al Bosque Profundo — ⬅️ Conejos y Jabalíes | ⬇️ Venados | ➡️ Cantera y Zorros")
	_spawn_forest_sign(Vector2(-620, 810), "🐇 Soto de Madrigueras y Hierbas (Hábitat de Conejos)")
	_spawn_forest_sign(Vector2(-640, 1410), "🐗 Robledal Profundo de Raíces y Trufas (Hábitat de Jabalíes)")
	_spawn_forest_sign(Vector2(160, 990), "🦌 Claros del Bosque y Hongos (Hábitat de Venados)")
	_spawn_forest_sign(Vector2(780, 815), "🦊 Riscos de Hierro y Guaridas (Hábitat de Zorros)")

	# 1. Madrigueras de Conejos y Guaridas de Zorro (Props visuales en el suelo del bosque)
	for i in range(burrow_positions.size()):
		var b_spr := Sprite2D.new()
		b_spr.name = "RabbitBurrow_%d" % i
		b_spr.texture = tex_burrow
		b_spr.global_position = burrow_positions[i]
		b_spr.scale = Vector2(1.25, 1.25)
		b_spr.z_index = -1
		entities_root.add_child(b_spr)

	for i in range(fox_den_positions.size()):
		var d_spr := Sprite2D.new()
		d_spr.name = "FoxDen_%d" % i
		d_spr.texture = tex_den
		d_spr.global_position = fox_den_positions[i]
		d_spr.scale = Vector2(1.35, 1.35)
		d_spr.z_index = -1
		entities_root.add_child(d_spr)

	# 2. Árboles del Bosque Profundo (60 árboles repartidos de forma irregular con claros naturales)
	var tree_positions: Array[Vector2] = [
		# Linde norte irregular y Soto Noroeste
		Vector2(-1080, 840), Vector2(-840, 810), Vector2(-540, 820), Vector2(-310, 795),
		Vector2(-1020, 980), Vector2(-740, 970), Vector2(-340, 910), Vector2(-210, 860),
		Vector2(-1140, 1150), Vector2(-890, 1180), Vector2(-640, 1080), Vector2(-380, 1120),
		Vector2(-1060, 1320), Vector2(-780, 1310), Vector2(-460, 1290), Vector2(-240, 1240),
		# Robledal Suroeste y Sur Profundo (Jabalíes)
		Vector2(-1180, 1520), Vector2(-980, 1560), Vector2(-680, 1510), Vector2(-390, 1480),
		Vector2(-1120, 1740), Vector2(-860, 1720), Vector2(-590, 1740), Vector2(-310, 1690),
		Vector2(-1040, 1960), Vector2(-780, 2020), Vector2(-510, 1920), Vector2(-260, 1950),
		Vector2(-860, 2180), Vector2(-560, 2190), Vector2(-240, 2210),
		# Claros Centrales y Bosquete Sur (Venados)
		Vector2(-95, 850), Vector2(85, 835), Vector2(290, 825), Vector2(540, 830),
		Vector2(-140, 1020), Vector2(210, 980), Vector2(460, 1010), Vector2(620, 990),
		Vector2(-80, 1240), Vector2(190, 1260), Vector2(490, 1280), Vector2(680, 1220),
		Vector2(-160, 1460), Vector2(280, 1440), Vector2(580, 1480),
		Vector2(-40, 1680), Vector2(240, 1710), Vector2(620, 1720),
		Vector2(60, 1940), Vector2(420, 1960), Vector2(680, 1950),
		Vector2(-60, 2180), Vector2(190, 2220), Vector2(520, 2190), Vector2(820, 2160),
		# Linde Este y Riscos (Zorros y Cantera)
		Vector2(920, 840), Vector2(1220, 870), Vector2(1420, 990),
		Vector2(880, 1140), Vector2(1360, 1180), Vector2(1460, 1420),
		Vector2(860, 1580), Vector2(1140, 1680), Vector2(1420, 1760),
		Vector2(980, 1980), Vector2(1280, 2060)
	]
	# Editor del mapa 3D (2026-11-10): si los árboles están en mapa/Mundo3D.tscn, salen de ahí (todos talables)
	if not arboles_en_escena():
		_spawn_harvest_batch("ForestTree", tree_positions, HarvestableNode.HarvestType.LOGGING, "Pino del Valle", "wood", 3, "crop_seeds", 1, 30.0, 2, 0, tex_tree, tex_stump, Vector2(0.85, 0.85), 12.0)

	var rock_positions: Array[Vector2] = [
		Vector2(740, 860), Vector2(880, 880), Vector2(1040, 860), Vector2(1180, 910),
		Vector2(790, 1040), Vector2(980, 1060), Vector2(1160, 1090), Vector2(1310, 1060),
		Vector2(840, 1260), Vector2(1060, 1250), Vector2(1240, 1290),
		Vector2(920, 1460), Vector2(1140, 1480), Vector2(1340, 1560)
	]
	_spawn_harvest_batch("OreVein", rock_positions, HarvestableNode.HarvestType.MINING, "Veta de Hierro y Piedra", "stone", 2, "iron_ore", 2, 35.0, 2, 0, tex_rock, tex_rock_depleted, Vector2(1.15, 1.15), 12.0)

	var herb_positions: Array[Vector2] = [
		Vector2(-980, 860), Vector2(-780, 840), Vector2(-580, 870), Vector2(-410, 850),
		Vector2(-910, 1020), Vector2(-690, 1010), Vector2(-490, 1030), Vector2(-310, 1010),
		Vector2(-840, 1180), Vector2(-610, 1210), Vector2(-430, 1190), Vector2(-260, 1150),
		Vector2(-720, 1360), Vector2(-520, 1380), Vector2(-180, 920), Vector2(140, 910),
		Vector2(380, 920), Vector2(-60, 1360), Vector2(340, 1360), Vector2(740, 1380)
	]
	_spawn_harvest_batch("WildHerb", herb_positions, HarvestableNode.HarvestType.FORAGE, "Hierbas Medicinales", "herbs", 2, "", 0, 15.0, 1, 2, tex_herb, null, Vector2(1.1, 1.1), 8.0)

	var mush_positions: Array[Vector2] = [
		Vector2(-40, 1020), Vector2(120, 1040), Vector2(290, 1080), Vector2(440, 1120),
		Vector2(-20, 1180), Vector2(160, 1190), Vector2(350, 1220),
		Vector2(60, 1460), Vector2(210, 1510), Vector2(420, 1560),
		Vector2(-80, 1760), Vector2(140, 1810), Vector2(360, 1840), Vector2(220, 2060),
		Vector2(-940, 1440), Vector2(-760, 1490), Vector2(-580, 1540), Vector2(-440, 1620),
		Vector2(-820, 1790), Vector2(-640, 1840), Vector2(-460, 1890), Vector2(-320, 2020)
	]
	_spawn_harvest_batch("WildMushroom", mush_positions, HarvestableNode.HarvestType.FORAGE, "Hongos Silvestres", "mushroom", 2, "", 0, 15.0, 1, 2, tex_mushroom, null, Vector2(1.1, 1.1), 8.0)

	_spawn_animal_pool(rabbit_pool, "WildRabbit", WildAnimal.SpeciesType.RABBIT, "Conejo Silvestre", 16, 10, burrow_positions, 45.0, 175.0, 12.0, 999.0, 28.0, 134.0, 85.0, [1, 1, "leather", 1, 0, 0, 1], tex_rabbit, Vector2(1.1, 1.1), 6.0)
	_spawn_animal_pool(deer_pool, "WildDeer", WildAnimal.SpeciesType.DEER, "Venado del Valle", 9, 6, deer_clearing_positions, 55.0, 210.0, 26.0, 999.0, 22.0, 118.0, 95.0, [2, 1, "leather", 2, 1, 1, 1], tex_deer, Vector2(1.15, 1.15), 9.0)
	_spawn_animal_pool(fox_pool, "WildFox", WildAnimal.SpeciesType.FOX, "Zorro del Bosque", 6, 3, fox_den_positions, 50.0, 190.0, 20.0, 999.0, 32.0, 122.0, 78.0, [1, 1, "fox_pelt", 1, 0, 1, 0], tex_fox, Vector2(1.15, 1.15), 7.5)
	_spawn_animal_pool(boar_pool, "WildBoar", WildAnimal.SpeciesType.BOAR, "Jabalí del Bosque", 7, 5, boar_rooting_positions, 55.0, 195.0, 66.0, 22.0, 24.0, 138.0, 85.0, [3, 2, "leather", 2, 0, 1, 2], tex_boar, Vector2(1.22, 1.22), 9.5)

func _spawn_harvest_batch(prefix: String, positions: Array[Vector2], h_type: HarvestableNode.HarvestType, title: String, p_id: String, p_amt: int, b_id: String, b_amt: int, hp: float, r_days: int, bites: int, tex_main: Texture2D, tex_dep: Texture2D, sc: Vector2, rad: float) -> void:
	for i in range(positions.size()):
		# Editor del mapa (2026-11-09): nada de setas, hierbas ni árboles dentro del agua del río redibujado
		if h_type != HarvestableNode.HarvestType.MINING and _en_cauce_del_rio(positions[i]):
			continue
		var node := HarvestableNode.new()
		node.name = "%s_%d" % [prefix, i]
		node.global_position = positions[i]
		node.harvest_type = h_type
		node.node_title = title
		node.primary_item_id = p_id
		node.primary_amount = p_amt
		node.bonus_item_id = b_id
		node.bonus_amount = b_amt
		node.max_hp = hp
		node.respawn_days = r_days
		if bites > 0:
			node.max_animal_bites = bites
		entities_root.add_child(node)
		node.setup_visuals(tex_main, tex_dep, Color.WHITE, sc, rad)

## Editor del mapa 3D (2026-11-10): ¿hay árboles en mapa/Mundo3D.tscn → Vegetacion/Arboles? Entonces los talables salen
## de la escena (WorldStageTerrain3D los hace talables con crear_arbol_talable) y no de la lista de este archivo.
static var ignorar_escena: bool = false # lo usa el horneado para ver los árboles de la lista
static var _arboles_escena: int = -1
static func arboles_en_escena() -> bool:
	if ignorar_escena:
		return false
	if _arboles_escena == -1:
		_arboles_escena = 0
		if ResourceLoader.exists("res://mapa/Mundo3D.tscn"):
			var st: SceneState = (load("res://mapa/Mundo3D.tscn") as PackedScene).get_state()
			for i in range(st.get_node_count()):
				if str(st.get_node_path(i)).begins_with("./Vegetacion/Arboles/"):
					_arboles_escena = 1
					break
	return _arboles_escena == 1


## Un árbol talable (mismos valores que los «Pino del Valle» de siempre) en un punto del mapa 2D.
func crear_arbol_talable(pos: Vector2, nombre: String) -> Node2D:
	if entities_root == null or not is_instance_valid(entities_root):
		return null
	var tex_tree: Texture2D = _load_tex("res://assests/Comprados/Epic RPG World - The Village V2.1/tilesets and props/props-sprites/pine-tree_0.png")
	if tex_tree == null:
		tex_tree = _load_tex("res://assests/world/tree.png")
	var tex_stump: Texture2D = _load_tex("res://assests/Comprados/Epic RPG World - The Village V2.1/tilesets and props/props-sprites/logs_0.png")
	var node := HarvestableNode.new()
	node.name = nombre
	node.global_position = pos
	node.harvest_type = HarvestableNode.HarvestType.LOGGING
	node.node_title = "Árbol del Valle"
	node.primary_item_id = "wood"
	node.primary_amount = 3
	node.bonus_item_id = "crop_seeds"
	node.bonus_amount = 1
	node.max_hp = 30.0
	node.respawn_days = 2
	entities_root.add_child(node)
	node.setup_visuals(tex_tree, tex_stump, Color.WHITE, Vector2(0.85, 0.85), 7.0)
	return node

## Un matorral destructible (2026-11-10, orden del usuario): se corta con arma u hacha y da ramas; vuelve a crecer.
func crear_matorral(pos: Vector2, nombre: String) -> Node2D:
	if entities_root == null or not is_instance_valid(entities_root):
		return null
	var node := HarvestableNode.new()
	node.name = nombre
	node.global_position = pos
	node.harvest_type = HarvestableNode.HarvestType.LOGGING
	node.node_title = "Matorral"
	node.primary_item_id = "branches"
	node.primary_amount = 2
	node.max_hp = 8.0
	node.respawn_days = 3
	entities_root.add_child(node)
	node.setup_visuals(_load_tex("res://assests/world/tree.png"), null, Color(0.55, 0.8, 0.5), Vector2(0.45, 0.45), 6.0)
	return node

static func _en_cauce_del_rio(p: Vector2) -> bool:
	if p.y < FishingSpot.river_y_start() - 5.0 or p.y > FishingSpot.river_y_end() + 5.0:
		return false
	var b: Vector2 = FishingSpot.river_banks_at(p.y)
	return p.x >= b.x - 4.0 and p.x <= b.y + 4.0

func _spawn_animal_pool(pool: Array[WildAnimal], prefix: String, sp: WildAnimal.SpeciesType, a_name: String, max_cnt: int, init_cnt: int, homes: Array[Vector2], r_min: float, r_max: float, hp: float, max_hit: float, g_spd: float, f_spd: float, alert_r: float, drops: Array, tex: Texture2D, sc: Vector2, rad: float) -> void:
	for i in range(max_cnt):
		var home_pos: Vector2 = homes[i % homes.size()]
		var offset := Vector2.RIGHT.rotated((TAU / float(max_cnt)) * float(i)) * randf_range(r_min, r_max)
		var a := WildAnimal.new()
		a.name = "%s_%d" % [prefix, i]
		a.species = sp
		a.home_position = home_pos
		a.global_position = home_pos + offset
		a.animal_name = a_name
		a.max_hp = hp
		if max_hit < 500.0:
			a.max_damage_per_hit = max_hit
		a.graze_speed = g_spd
		a.flee_speed = f_spd
		a.alert_radius = alert_r
		a.meat_drop = int(drops[0])
		a.leather_drop = int(drops[1])
		a.pelt_item_id = str(drops[2])
		a.bones_drop = int(drops[3])
		a.antlers_drop = int(drops[4])
		a.viscera_drop = int(drops[5])
		a.fat_drop = int(drops[6])
		a.managed_by_ecosystem = true
		entities_root.add_child(a)
		a.setup_animal(tex, sc, rad)
		if i >= init_cnt:
			a._finish_butchering()
		pool.append(a)

## Evaluación ecológica cada nuevo día (06:00 AM)
func _on_day_passed(_new_day: int) -> void:
	if GameManager != null and GameManager.has_method("is_demo_mode") and GameManager.is_demo_mode():
		return
	rabbit_extinct_days = _process_species_daily_cycle(rabbit_pool, 2, rabbit_extinct_days, 2)
	deer_extinct_days = _process_species_daily_cycle(deer_pool, 3, deer_extinct_days, 2)
	fox_extinct_days = _process_species_daily_cycle(fox_pool, 2, fox_extinct_days, 1)
	boar_extinct_days = _process_species_daily_cycle(boar_pool, 3, boar_extinct_days, 2)
	_notify_ecological_shift()

## Devuelve el nodo de recurso (`HarvestableNode`) más cercano SOLO si extraerlo hoy respeta el equilibrio matemático del bosque (N_actual > N_min).
## Si extraer 1 unidad comprometería la regeneración o la comida de los herbívoros, devuelve `null`.
func find_sustainable_harvest_node(h_type: int, from_pos: Vector2) -> HarvestableNode:
	var active_nodes: Array[HarvestableNode] = []
	var root_search: Node = entities_root if entities_root else get_tree().current_scene
	if not root_search:
		return null
	for child in root_search.get_children():
		if child is HarvestableNode:
			var hn := child as HarvestableNode
			if int(hn.harvest_type) == h_type and not hn.is_depleted:
				active_nodes.append(hn)

	var min_safe: int = MIN_SAFE_TREES
	if h_type == int(HarvestableNode.HarvestType.MINING):
		min_safe = MIN_SAFE_ORE_VEINS
	elif h_type == int(HarvestableNode.HarvestType.FORAGE):
		min_safe = MIN_SAFE_WILD_FLORA

	# Si el número actual de nodos vivos es <= N_min, el aldeano respeta el equilibrio y NO extrae hoy
	if active_nodes.size() <= min_safe:
		return null

	var best_node: HarvestableNode = null
	var best_d2: float = INF
	for hn in active_nodes:
		var d2: float = from_pos.distance_squared_to(hn.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best_node = hn
	return best_node

## Devuelve una presa (`WildAnimal`) para que el Carnicero cace SOLO si esa especie tiene superávit sobre su umbral de equilibrio (N_actual > N_min).
## También devuelve un cadáver (`CARCASS`) existente si ya hay uno en el bosque para aprovecharlo sin matar otro animal.
func find_sustainable_hunt_prey(from_pos: Vector2) -> WildAnimal:
	if GameManager != null and GameManager.has_method("is_demo_mode") and GameManager.is_demo_mode():
		return null
	# 1º Prioridad ecológica: si ya hay algún cadáver de animal sin desollar en el bosque, aprovecharlo primero
	for pool in [deer_pool, boar_pool, rabbit_pool]:
		for a in pool:
			if is_instance_valid(a) and a.state == WildAnimal.AnimalState.CARCASS and a.visible:
				return a

	# 2º Evaluar qué especies tienen excedente real sobre su umbral mínimo de equilibrio (N_live > N_min)
	var live_rabbits := _get_live_animals(rabbit_pool)
	var live_deer := _get_live_animals(deer_pool)
	var live_boars := _get_live_animals(boar_pool)

	var candidates: Array[WildAnimal] = []
	var rabbit_surplus: int = live_rabbits.size() - MIN_SAFE_RABBITS
	var deer_surplus: int = live_deer.size() - MIN_SAFE_DEER
	var boar_surplus: int = live_boars.size() - MIN_SAFE_BOARS

	# Elegir de las especies que superen estrictamente su umbral de seguridad ecológica
	if deer_surplus > 0:
		candidates.append_array(live_deer)
	if rabbit_surplus > 0:
		candidates.append_array(live_rabbits)
	# J1: el jabalí embiste si se le hiere; un cazador prudente solo va a por él si no queda otra presa
	if boar_surplus > 0 and candidates.filter(func(a): return a.state != WildAnimal.AnimalState.IN_BURROW and a.visible).is_empty():
		candidates.append_array(live_boars)

	if candidates.is_empty():
		return null

	var best_prey: WildAnimal = null
	var best_d2: float = INF
	for a in candidates:
		if a.state == WildAnimal.AnimalState.IN_BURROW or not a.visible:
			continue
		var d2: float = from_pos.distance_squared_to(a.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best_prey = a
	return best_prey

func _process_species_daily_cycle(pool: Array[WildAnimal], max_starvation_days: int, extinct_days: int, migrant_count: int) -> int:
	var live_list := _get_live_animals(pool)
	var births_to_spawn := 0
	var inherited_gen := 1

	for animal in live_list:
		if animal.pending_offspring:
			births_to_spawn += 1
			inherited_gen = maxi(inherited_gen, animal.offspring_genetics_tier)

		if animal.is_on_reserve_day:
			# Terminó su día de reserva: hoy vuelve a tener apetito normal
			animal.is_on_reserve_day = false
			animal.has_reserve_day = false
			animal.meals_eaten = 0
			animal.fed_today = false
			animal.days_hungry = 0
		elif animal.has_reserve_day or animal.meals_eaten >= WildAnimal.MAX_MEALS:
			# Ayer comió 2 veces (2/2): ¡hoy disfruta de su Día de Reserva sin necesidad de comer!
			animal.is_on_reserve_day = true
			animal.has_reserve_day = false
			animal.meals_eaten = 0
			animal.fed_today = true
			animal.days_hungry = 0
		elif animal.fed_today or animal.meals_eaten >= 1:
			# Ayer comió 1 vez (1/2): sobrevive bien, pero hoy sí necesita buscar comida
			animal.is_on_reserve_day = false
			animal.has_reserve_day = false
			animal.meals_eaten = 0
			animal.fed_today = false
			animal.days_hungry = 0
		else:
			# Ayer no comió nada (0/2)
			animal.days_hungry += 1
			if animal.days_hungry >= max_starvation_days:
				animal._finish_butchering()

		animal.mated_today = false
		animal.pending_offspring = false
		animal.escaped_first_pounce = false

	# Nacimiento de crías de las parejas que comieron 2 veces (2/2) y se juntaron ayer
	if births_to_spawn > 0:
		_spawn_from_pool(pool, births_to_spawn, inherited_gen)

	# Control de extinción y migración tras 5 días
	var remaining := _get_live_animals(pool)
	if remaining.is_empty():
		extinct_days += 1
		if extinct_days >= 5:
			_spawn_from_pool(pool, migrant_count, 1)
			extinct_days = 0
	else:
		extinct_days = 0

	return extinct_days

func _get_live_animals(pool: Array[WildAnimal]) -> Array[WildAnimal]:
	var res: Array[WildAnimal] = []
	for a in pool:
		if is_instance_valid(a) and a.is_alive_in_ecosystem():
			res.append(a)
	return res

func _spawn_from_pool(pool: Array[WildAnimal], count: int, gen_tier: int = 1) -> int:
	var spawned := 0
	for a in pool:
		if spawned >= count:
			break
		if is_instance_valid(a) and a.state == WildAnimal.AnimalState.BUTCHERED:
			a.respawn_from_ecosystem(gen_tier)
			spawned += 1
	return spawned

func _notify_ecological_shift() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.has_method("show_hint"):
		return
	var r_count := _get_live_animals(rabbit_pool).size()
	var d_count := _get_live_animals(deer_pool).size()
	var f_count := _get_live_animals(fox_pool).size()

	if r_count <= 2 and f_count > 0:
		player.show_hint("⚠️ Escasez de conejos: los Zorros hambrientos merodean hacia la aldea.")
	elif f_count == 0 and r_count >= 12:
		player.show_hint("⚠️ Sin zorros en el bosque: sobrepoblación de Conejos (%d)." % r_count)
	elif r_count == 0 and d_count == 0:
		player.show_hint("⚠️ La sobre-caza ha dejado el bosque sin herbívoros.")

func _spawn_forest_sign(pos: Vector2, txt: String) -> void:
	var post := Polygon2D.new()
	post.polygon = PackedVector2Array([
		Vector2(-2, -10), Vector2(2, -10), Vector2(2, 4), Vector2(-2, 4)
	])
	post.color = Color(0.42, 0.27, 0.14, 1.0)
	post.global_position = pos
	post.z_index = -1
	entities_root.add_child(post)

	var board := Polygon2D.new()
	board.polygon = PackedVector2Array([
		Vector2(-9, -12), Vector2(9, -12), Vector2(9, -5), Vector2(-9, -5)
	])
	board.color = Color(0.58, 0.39, 0.20, 1.0)
	board.global_position = pos
	board.z_index = -1
	entities_root.add_child(board)

	var lbl := Label.new()
	lbl.text = txt
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = pos + Vector2(-150, -28)
	lbl.custom_minimum_size = Vector2(300, 16)
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color(0.78, 0.96, 0.70))
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 3)
	entities_root.add_child(lbl)

func _save_pool(pool: Array[WildAnimal]) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []
	for a in pool:
		if is_instance_valid(a):
			arr.append(a.to_save_dict())
	return arr

func _load_pool(pool: Array[WildAnimal], data: Dictionary, key: String) -> void:
	if data.has(key) and typeof(data[key]) == TYPE_ARRAY:
		var arr: Array = data[key]
		for i in range(mini(arr.size(), pool.size())):
			if is_instance_valid(pool[i]) and typeof(arr[i]) == TYPE_DICTIONARY:
				pool[i].from_save_dict(arr[i])

func to_save_dict() -> Dictionary:
	return {
		"rabbit_extinct_days": rabbit_extinct_days, "deer_extinct_days": deer_extinct_days,
		"fox_extinct_days": fox_extinct_days, "boar_extinct_days": boar_extinct_days,
		"rabbits": _save_pool(rabbit_pool), "deer": _save_pool(deer_pool),
		"foxes": _save_pool(fox_pool), "boars": _save_pool(boar_pool)
	}

func from_save_dict(data: Dictionary) -> void:
	rabbit_extinct_days = int(data.get("rabbit_extinct_days", 0))
	deer_extinct_days = int(data.get("deer_extinct_days", 0))
	fox_extinct_days = int(data.get("fox_extinct_days", 0))
	boar_extinct_days = int(data.get("boar_extinct_days", 0))
	_load_pool(rabbit_pool, data, "rabbits")
	_load_pool(deer_pool, data, "deer")
	_load_pool(fox_pool, data, "foxes")
	_load_pool(boar_pool, data, "boars")

func count_live_trees() -> int:
	var root_search: Node = entities_root if entities_root else get_tree().current_scene
	if not root_search:
		return 0
	var cnt: int = 0
	for child in root_search.get_children():
		if child is HarvestableNode:
			var hn := child as HarvestableNode
			if int(hn.harvest_type) == int(HarvestableNode.HarvestType.LOGGING) and not hn.is_depleted:
				cnt += 1
	return cnt

func count_planted_pines() -> int:
	var root_search: Node = entities_root if entities_root else get_tree().current_scene
	if not root_search:
		return 0
	var cnt: int = 0
	for child in root_search.get_children():
		if str(child.name).begins_with("PlantedPine_"):
			cnt += 1
	return cnt

## side_effects = false: solo vuelve a poner el pino (al cargar partida), sin traer fauna ni hierbas nuevas.
func plant_sapling(world_pos: Vector2 = Vector2.ZERO, side_effects: bool = true) -> HarvestableNode:
	var root_search: Node = entities_root if entities_root else get_tree().current_scene
	if not root_search:
		return null
	if not side_effects:
		return _place_planted_pine(root_search, world_pos)
	# Rebrota primero una hierba o seta agotada por el enriquecimiento del suelo forestal
	for child in root_search.get_children():
		if child is HarvestableNode:
			var f_node := child as HarvestableNode
			if int(f_node.harvest_type) == int(HarvestableNode.HarvestType.FORAGE) and f_node.is_depleted:
				f_node._regrow_node()
				break
	# Atrae fauna herbívora (venado o conejo) si hay hueco en la manada
	if _get_live_animals(deer_pool).size() < deer_pool.size():
		_spawn_from_pool(deer_pool, 1)
	elif _get_live_animals(rabbit_pool).size() < rabbit_pool.size():
		_spawn_from_pool(rabbit_pool, 1)
	return _place_planted_pine(root_search, world_pos)

func _place_planted_pine(root_search: Node, world_pos: Vector2) -> HarvestableNode:
	var tex_tree: Texture2D = _load_tex("res://assests/Comprados/Epic RPG World - The Village V2.1/tilesets and props/props-sprites/pine-tree_0.png")
	if not tex_tree:
		tex_tree = _load_tex("res://assests/world/tree.png")
	var tex_stump: Texture2D = _load_tex("res://assests/Comprados/Epic RPG World - The Village V2.1/tilesets and props/props-sprites/logs_0.png")
	var idx: int = count_planted_pines()
	var pos: Vector2 = world_pos if world_pos != Vector2.ZERO else Vector2(-360.0 + float((idx % 6) * 65), 670.0 + float(int(float(idx) / 6.0) * 55))
	var node := HarvestableNode.new()
	node.name = "PlantedPine_%d_%d" % [idx, randi() % 1000]
	node.global_position = pos
	node.harvest_type = HarvestableNode.HarvestType.LOGGING
	node.node_title = "Pino Joven Reforestado"
	node.primary_item_id = "wood"
	node.primary_amount = 3
	node.bonus_item_id = "" # Sin semilla de regalo: la semilla que gastas no vuelve sola
	node.bonus_amount = 0
	node.max_hp = 30.0
	node.respawn_days = 2
	root_search.add_child(node)
	node.setup_visuals(tex_tree, tex_stump, Color(0.88, 1.05, 0.88), Vector2(0.82, 0.82), 12.0)
	return node
