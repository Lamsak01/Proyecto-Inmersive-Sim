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

var burrow_positions: Array[Vector2] = [
	Vector2(-240, 540),
	Vector2(40, 640),
	Vector2(-110, 840)
]
var deer_clearing_positions: Array[Vector2] = [
	Vector2(-320, 740),
	Vector2(180, 860)
]
var fox_den_positions: Array[Vector2] = [
	Vector2(290, 560),
	Vector2(-380, 920)
]

var rabbit_extinct_days: int = 0
var deer_extinct_days: int = 0
var fox_extinct_days: int = 0

func setup_ecosystem(target_entities_root: Node) -> void:
	entities_root = target_entities_root if target_entities_root else self
	_spawn_distant_forest()
	if WorldClock and not WorldClock.day_passed.is_connected(_on_day_passed):
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
	var tex_burrow: Texture2D = _load_tex("res://assests/world/harvest/rabbit_burrow.png")
	var tex_den: Texture2D = _load_tex("res://assests/world/harvest/fox_den.png")

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

	# 2. Pinos del Bosque Profundo (20 árboles distribuidos desde el sendero sur hacia el bosque profundo)
	var tree_positions: Array[Vector2] = [
		Vector2(135, 355), Vector2(245, 365), Vector2(60, 410), Vector2(310, 420),
		Vector2(-190, 470), Vector2(-310, 495), Vector2(-430, 560), Vector2(-280, 620),
		Vector2(-390, 690), Vector2(-210, 770), Vector2(-450, 830), Vector2(-310, 950),
		Vector2(-75, 485), Vector2(95, 510), Vector2(-30, 695), Vector2(125, 735),
		Vector2(-145, 920), Vector2(45, 960),
		Vector2(230, 630), Vector2(355, 720), Vector2(265, 890), Vector2(390, 910)
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
		tree.setup_visuals(tex_tree, tex_stump, Color.WHITE, Vector2(0.8, 0.8), 12.0)

	# 3. Cantera y Vetas de Hierro (8 vetas rocosas al Este/Sureste del bosque)
	var rock_positions: Array[Vector2] = [
		Vector2(330, 480), Vector2(385, 520), Vector2(345, 585), Vector2(415, 610),
		Vector2(295, 670), Vector2(375, 665), Vector2(-355, 880), Vector2(-415, 945)
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

	# 4. Flora Silvestre con 2 Bocados por Planta (12 Hierbas + 10 Hongos = 22 plantas -> 44 raciones vegetales)
	var herb_positions: Array[Vector2] = [
		Vector2(-195, 525), Vector2(-285, 565), Vector2(-150, 610), Vector2(10, 585),
		Vector2(85, 660), Vector2(-65, 780), Vector2(-165, 855), Vector2(-275, 785),
		Vector2(145, 815), Vector2(215, 775), Vector2(-335, 715), Vector2(165, 695)
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
		Vector2(-225, 490), Vector2(-345, 640), Vector2(65, 545), Vector2(-20, 645),
		Vector2(-115, 735), Vector2(105, 895), Vector2(-240, 895), Vector2(255, 600),
		Vector2(-85, 560), Vector2(25, 835)
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
		fox.managed_by_ecosystem = true
		entities_root.add_child(fox)
		fox.setup_animal(tex_fox, Vector2(1.15, 1.15), 7.5)
		if i >= initial_foxes:
			fox._finish_butchering()
		fox_pool.append(fox)

## Evaluación ecológica cada nuevo día (06:00 AM)
func _on_day_passed(_new_day: int) -> void:
	rabbit_extinct_days = _process_species_daily_cycle(rabbit_pool, 2, rabbit_extinct_days, 2)
	deer_extinct_days = _process_species_daily_cycle(deer_pool, 3, deer_extinct_days, 2)
	fox_extinct_days = _process_species_daily_cycle(fox_pool, 2, fox_extinct_days, 1)
	_notify_ecological_shift()

func _process_species_daily_cycle(pool: Array[WildAnimal], max_starvation_days: int, extinct_days: int, migrant_count: int) -> int:
	var live_list := _get_live_animals(pool)
	var births_to_spawn := 0

	for animal in live_list:
		if animal.pending_offspring:
			births_to_spawn += 1

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
		_spawn_from_pool(pool, births_to_spawn)

	# Control de extinción y migración tras 5 días
	var remaining := _get_live_animals(pool)
	if remaining.is_empty():
		extinct_days += 1
		if extinct_days >= 5:
			_spawn_from_pool(pool, migrant_count)
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

func _spawn_from_pool(pool: Array[WildAnimal], count: int) -> int:
	var spawned := 0
	for a in pool:
		if spawned >= count:
			break
		if is_instance_valid(a) and a.state == WildAnimal.AnimalState.BUTCHERED:
			a.respawn_from_ecosystem()
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
