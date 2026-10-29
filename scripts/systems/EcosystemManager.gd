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

var burrow_positions: Array[Vector2] = [
	Vector2(-390, 665),
	Vector2(-220, 680),
	Vector2(-310, 825)
]
var deer_clearing_positions: Array[Vector2] = [
	Vector2(55, 895),
	Vector2(215, 1045)
]
var fox_den_positions: Array[Vector2] = [
	Vector2(575, 685),
	Vector2(715, 845)
]
var boar_rooting_positions: Array[Vector2] = [
	Vector2(-345, 995),
	Vector2(-195, 1075)
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

func _load_tex(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var t = load(res_path)
		if t is Texture2D:
			return t
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
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

	# 0. Suelo del Bioma de Bosque Profundo (y = 575..1240, claramente separado de la aldea y la granja)
	var forest_turf := Polygon2D.new()
	forest_turf.polygon = PackedVector2Array([
		Vector2(-520, 575), Vector2(860, 575),
		Vector2(860, 1240), Vector2(-520, 1240)
	])
	forest_turf.color = Color(0.11, 0.25, 0.14, 0.42)
	forest_turf.z_index = -4
	entities_root.add_child(forest_turf)

	var forest_border := Line2D.new()
	forest_border.width = 2.5
	forest_border.default_color = Color(0.22, 0.42, 0.25, 0.65)
	forest_border.points = PackedVector2Array([
		Vector2(-520, 575), Vector2(860, 575),
		Vector2(860, 1240), Vector2(-520, 1240), Vector2(-520, 575)
	])
	forest_border.z_index = -3
	entities_root.add_child(forest_border)

	# Carteles de Entrada al Bosque y de los 4 Hábitats Separados
	_spawn_forest_sign(Vector2(465, 590), "🌲 Entrada al Bosque Profundo — ⬅️ Conejos y Jabalíes | ⬇️ Venados | ➡️ Cantera y Zorros")
	_spawn_forest_sign(Vector2(-290, 595), "🐇 Pradera de Madrigueras y Hierbas (Hábitat de Conejos)")
	_spawn_forest_sign(Vector2(-270, 945), "🐗 Robledal de Raíces y Trufas (Hábitat de Jabalíes — ⚠️ Embisten si los atacas)")
	_spawn_forest_sign(Vector2(142, 785), "🦌 Claros de Pinos y Hongos (Hábitat de Venados)")
	_spawn_forest_sign(Vector2(615, 595), "🦊 Cantera de Hierro y Guaridas (Hábitat de Zorros)")

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

	# 2. Pinos del Bosque Profundo (22 árboles distribuidos en el Bosque Sur, y = 610..1180)
	var tree_positions: Array[Vector2] = [
		# Borde de entrada y Pradera Oeste
		Vector2(-465, 635), Vector2(-150, 640), Vector2(-475, 760), Vector2(-145, 790),
		Vector2(-435, 880), Vector2(-185, 895),
		# Claros Centrales y Profundos de Venados (Centro-Sur)
		Vector2(-45, 720), Vector2(65, 740), Vector2(245, 735), Vector2(355, 745),
		Vector2(-55, 855), Vector2(145, 850), Vector2(315, 865),
		Vector2(-35, 985), Vector2(130, 995), Vector2(310, 1005),
		Vector2(20, 1135), Vector2(165, 1150), Vector2(295, 1140),
		# Borde de la Cantera Este
		Vector2(475, 725), Vector2(815, 715), Vector2(645, 935)
	]
	for i in range(tree_positions.size()):
		var tree := HarvestableNode.new()
		tree.name = "ForestTree_%d" % i
		tree.global_position = tree_positions[i]
		tree.harvest_type = HarvestableNode.HarvestType.LOGGING
		tree.node_title = "Pino del Valle"
		tree.primary_item_id = "wood"
		tree.primary_amount = 3
		tree.bonus_item_id = "crop_seeds"
		tree.bonus_amount = 1
		tree.max_hp = 30.0
		tree.respawn_days = 2
		entities_root.add_child(tree)
		tree.setup_visuals(tex_tree, tex_stump, Color.WHITE, Vector2(0.85, 0.85), 12.0)

	# 3. Cantera y Vetas de Hierro (8 vetas rocosas concentradas en el Barranco Este de los Zorros, x = 510..795, y = 640..920)
	var rock_positions: Array[Vector2] = [
		Vector2(515, 648), Vector2(635, 645), Vector2(755, 660), Vector2(530, 755),
		Vector2(655, 765), Vector2(785, 780), Vector2(585, 885), Vector2(755, 905)
	]
	for i in range(rock_positions.size()):
		var vein := HarvestableNode.new()
		vein.name = "OreVein_%d" % i
		vein.global_position = rock_positions[i]
		vein.harvest_type = HarvestableNode.HarvestType.MINING
		vein.node_title = "Veta de Hierro y Piedra"
		vein.primary_item_id = "stone"
		vein.primary_amount = 2
		vein.bonus_item_id = "iron_ore"
		vein.bonus_amount = 2
		vein.max_hp = 35.0
		vein.respawn_days = 2
		entities_root.add_child(vein)
		vein.setup_visuals(tex_rock, tex_rock_depleted, Color.WHITE, Vector2(1.15, 1.15), 12.0)

	# 4. Flora Silvestre Separada por Hábitat (12 Hierbas en la Pradera de Conejos + 10 Hongos en los Claros de Venados)
	var herb_positions: Array[Vector2] = [
		Vector2(-435, 650), Vector2(-345, 645), Vector2(-265, 655), Vector2(-180, 665),
		Vector2(-420, 725), Vector2(-325, 730), Vector2(-235, 735), Vector2(-175, 745),
		Vector2(-405, 810), Vector2(-345, 855), Vector2(-260, 835), Vector2(-195, 825)
	]
	for i in range(herb_positions.size()):
		var herb := HarvestableNode.new()
		herb.name = "WildHerb_%d" % i
		herb.global_position = herb_positions[i]
		herb.harvest_type = HarvestableNode.HarvestType.FORAGE
		herb.node_title = "Hierbas Medicinales"
		herb.primary_item_id = "herbs"
		herb.primary_amount = 2
		herb.max_animal_bites = 2
		herb.respawn_days = 1
		entities_root.add_child(herb)
		herb.setup_visuals(tex_herb, null, Color.WHITE, Vector2(1.1, 1.1), 8.0)

	var mush_positions: Array[Vector2] = [
		Vector2(-10, 835), Vector2(85, 830), Vector2(195, 840), Vector2(275, 855),
		Vector2(15, 935), Vector2(115, 945), Vector2(235, 955),
		Vector2(45, 1065), Vector2(165, 1085), Vector2(265, 1075),
		# 4 Trufas / Hongos en el Robledal Suroeste para el hábitat de Jabalíes (26 plantas en total = 52 raciones/día)
		Vector2(-385, 975), Vector2(-285, 1015), Vector2(-225, 1055), Vector2(-145, 1095)
	]
	for i in range(mush_positions.size()):
		var mush := HarvestableNode.new()
		mush.name = "WildMushroom_%d" % i
		mush.global_position = mush_positions[i]
		mush.harvest_type = HarvestableNode.HarvestType.FORAGE
		mush.node_title = "Hongos Silvestres"
		mush.primary_item_id = "mushroom"
		mush.primary_amount = 2
		mush.max_animal_bites = 2
		mush.respawn_days = 1
		entities_root.add_child(mush)
		mush.setup_visuals(tex_mushroom, null, Color.WHITE, Vector2(1.1, 1.1), 8.0)

	# 5. Población de Conejos Silvestres (Capacidad máx: 16 | Inicialmente vivos: 10)
	var max_rabbits := 16
	var initial_rabbits := 10
	for i in range(max_rabbits):
		var burrow_pos: Vector2 = burrow_positions[i % burrow_positions.size()]
		var spawn_offset := Vector2.RIGHT.rotated((TAU / float(max_rabbits)) * float(i)) * randf_range(18.0, 65.0)
		var rab := WildAnimal.new()
		rab.name = "WildRabbit_%d" % i
		rab.species = WildAnimal.SpeciesType.RABBIT
		rab.home_position = burrow_pos
		rab.global_position = burrow_pos + spawn_offset
		rab.animal_name = "Conejo Silvestre"
		rab.max_hp = 12.0
		rab.graze_speed = 28.0
		rab.flee_speed = 134.0
		rab.alert_radius = 85.0
		rab.meat_drop = 1
		rab.leather_drop = 1
		rab.pelt_item_id = "leather"
		rab.bones_drop = 1
		rab.antlers_drop = 0
		rab.viscera_drop = 0
		rab.fat_drop = 1
		rab.managed_by_ecosystem = true
		entities_root.add_child(rab)
		rab.setup_animal(tex_rabbit, Vector2(1.1, 1.1), 6.0)
		if i >= initial_rabbits:
			rab._finish_butchering()
		rabbit_pool.append(rab)

	# 6. Manadas de Venados del Valle (Capacidad máx: 9 | Inicialmente vivos: 6)
	var max_deer := 9
	var initial_deer := 6
	for i in range(max_deer):
		var clearing_pos: Vector2 = deer_clearing_positions[i % deer_clearing_positions.size()]
		var spawn_offset := Vector2.RIGHT.rotated((TAU / float(max_deer)) * float(i)) * randf_range(22.0, 60.0)
		var deer := WildAnimal.new()
		deer.name = "WildDeer_%d" % i
		deer.species = WildAnimal.SpeciesType.DEER
		deer.home_position = clearing_pos
		deer.global_position = clearing_pos + spawn_offset
		deer.animal_name = "Venado del Valle"
		deer.max_hp = 26.0
		deer.graze_speed = 22.0
		deer.flee_speed = 118.0
		deer.alert_radius = 95.0
		deer.meat_drop = 2
		deer.leather_drop = 1
		deer.pelt_item_id = "leather"
		deer.bones_drop = 2
		deer.antlers_drop = 1
		deer.viscera_drop = 1
		deer.fat_drop = 1
		deer.managed_by_ecosystem = true
		entities_root.add_child(deer)
		deer.setup_animal(tex_deer, Vector2(1.15, 1.15), 9.0)
		if i >= initial_deer:
			deer._finish_butchering()
		deer_pool.append(deer)

	# 7. Depredadores: Zorros del Bosque (Capacidad máx: 6 | Inicialmente vivos: 3)
	var max_foxes := 6
	var initial_foxes := 3
	for i in range(max_foxes):
		var den_pos: Vector2 = fox_den_positions[i % fox_den_positions.size()]
		var spawn_offset := Vector2.RIGHT.rotated((TAU / float(max_foxes)) * float(i)) * randf_range(20.0, 50.0)
		var fox := WildAnimal.new()
		fox.name = "WildFox_%d" % i
		fox.species = WildAnimal.SpeciesType.FOX
		fox.home_position = den_pos
		fox.global_position = den_pos + spawn_offset
		fox.animal_name = "Zorro del Bosque"
		fox.max_hp = 20.0
		fox.graze_speed = 32.0
		fox.flee_speed = 122.0 # Corre menos que el conejo (134), pero caza con sigilo + salto (245)
		fox.alert_radius = 78.0
		fox.meat_drop = 1
		fox.leather_drop = 1
		fox.pelt_item_id = "fox_pelt"
		fox.bones_drop = 1
		fox.antlers_drop = 0
		fox.viscera_drop = 1
		fox.fat_drop = 0
		fox.managed_by_ecosystem = true
		entities_root.add_child(fox)
		fox.setup_animal(tex_fox, Vector2(1.15, 1.15), 7.5)
		if i >= initial_foxes:
			fox._finish_butchering()
		fox_pool.append(fox)

	# 8. Manada de Jabalíes del Robledal (Capacidad máx: 7 | Inicialmente vivos: 5 | Aguantan >= 3 golpes y embisten si los atacas)
	var max_boars := 7
	var initial_boars := 5
	for i in range(max_boars):
		var root_pos: Vector2 = boar_rooting_positions[i % boar_rooting_positions.size()]
		var spawn_offset := Vector2.RIGHT.rotated((TAU / float(max_boars)) * float(i)) * randf_range(22.0, 55.0)
		var boar := WildAnimal.new()
		boar.name = "WildBoar_%d" % i
		boar.species = WildAnimal.SpeciesType.BOAR
		boar.home_position = root_pos
		boar.global_position = root_pos + spawn_offset
		boar.animal_name = "Jabalí del Bosque"
		boar.max_hp = 66.0
		boar.max_damage_per_hit = 22.0 # Garantiza que aguante al menos 3 golpes incluso con armas mejoradas
		boar.graze_speed = 24.0
		boar.flee_speed = 138.0
		boar.alert_radius = 85.0
		boar.meat_drop = 3
		boar.leather_drop = 2
		boar.pelt_item_id = "leather"
		boar.bones_drop = 2
		boar.antlers_drop = 0
		boar.viscera_drop = 1
		boar.fat_drop = 2
		boar.managed_by_ecosystem = true
		entities_root.add_child(boar)
		boar.setup_animal(tex_boar, Vector2(1.22, 1.22), 9.5)
		if i >= initial_boars:
			boar._finish_butchering()
		boar_pool.append(boar)

## Evaluación ecológica cada nuevo día (06:00 AM)
func _on_day_passed(_new_day: int) -> void:
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
	if boar_surplus > 0:
		candidates.append_array(live_boars)
	if rabbit_surplus > 0:
		candidates.append_array(live_rabbits)

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

func to_save_dict() -> Dictionary:
	var r_data: Array[Dictionary] = []
	for a in rabbit_pool:
		if is_instance_valid(a):
			r_data.append(a.to_save_dict())
	var d_data: Array[Dictionary] = []
	for a in deer_pool:
		if is_instance_valid(a):
			d_data.append(a.to_save_dict())
	var f_data: Array[Dictionary] = []
	for a in fox_pool:
		if is_instance_valid(a):
			f_data.append(a.to_save_dict())
	var b_data: Array[Dictionary] = []
	for a in boar_pool:
		if is_instance_valid(a):
			b_data.append(a.to_save_dict())
	return {
		"rabbit_extinct_days": rabbit_extinct_days,
		"deer_extinct_days": deer_extinct_days,
		"fox_extinct_days": fox_extinct_days,
		"boar_extinct_days": boar_extinct_days,
		"rabbits": r_data,
		"deer": d_data,
		"foxes": f_data,
		"boars": b_data
	}

func from_save_dict(data: Dictionary) -> void:
	rabbit_extinct_days = int(data.get("rabbit_extinct_days", 0))
	deer_extinct_days = int(data.get("deer_extinct_days", 0))
	fox_extinct_days = int(data.get("fox_extinct_days", 0))
	boar_extinct_days = int(data.get("boar_extinct_days", 0))
	if data.has("rabbits") and typeof(data["rabbits"]) == TYPE_ARRAY:
		var r_arr: Array = data["rabbits"]
		for i in range(mini(r_arr.size(), rabbit_pool.size())):
			if is_instance_valid(rabbit_pool[i]) and typeof(r_arr[i]) == TYPE_DICTIONARY:
				rabbit_pool[i].from_save_dict(r_arr[i])
	if data.has("deer") and typeof(data["deer"]) == TYPE_ARRAY:
		var d_arr: Array = data["deer"]
		for i in range(mini(d_arr.size(), deer_pool.size())):
			if is_instance_valid(deer_pool[i]) and typeof(d_arr[i]) == TYPE_DICTIONARY:
				deer_pool[i].from_save_dict(d_arr[i])
	if data.has("foxes") and typeof(data["foxes"]) == TYPE_ARRAY:
		var f_arr: Array = data["foxes"]
		for i in range(mini(f_arr.size(), fox_pool.size())):
			if is_instance_valid(fox_pool[i]) and typeof(f_arr[i]) == TYPE_DICTIONARY:
				fox_pool[i].from_save_dict(f_arr[i])
	if data.has("boars") and typeof(data["boars"]) == TYPE_ARRAY:
		var b_arr: Array = data["boars"]
		for i in range(mini(b_arr.size(), boar_pool.size())):
			if is_instance_valid(boar_pool[i]) and typeof(b_arr[i]) == TYPE_DICTIONARY:
				boar_pool[i].from_save_dict(b_arr[i])
