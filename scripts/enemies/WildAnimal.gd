@tool
extends CharacterBody2D
class_name WildAnimal

## Fauna Silvestre con Simulación de Vida (Estilo RDR2), Sigilo/Salto de Cazador y Saciedad de 2 Niveles — Fase 3.5
## - Saciedad y Día de Reserva: Cada animal puede comer hasta 2 veces al día (meals_eaten = 2/2).
##   Con 1 comida sobrevive el día; al comer 2 veces queda 100% Saciado, gana 1 Día de Reserva sin comer
##   al día siguiente (dejando crecer las plantas o descansar a las presas) y puede buscar pareja.
## - Reproducción Realista (SEEK_MATE): Dos animales de la misma especie que hayan comido 2 veces (2/2)
##   el mismo día se buscan, se juntan y tienen probabilidad de engendrar una cría al amanecer.
## - Caza de Zorros: Acecho en sigilo (STALK_PREY) + Salto de Takedown (POUNCE) con 50% de probabilidad
##   de que el conejo escape la primera vez que lo atrapan.

enum SpeciesType { RABBIT, DEER, FOX, BOAR }
enum AnimalState {
	GRAZE,
	SEEK_FOOD,
	STALK_PREY,
	POUNCE,
	CHASE_PREY,
	CHARGE_ATTACK,
	EATING,
	SEEK_MATE,
	RETURN_HOME,
	SLEEP,
	IN_BURROW,
	FLEE,
	CARCASS,
	BUTCHERED
}

const MAX_MEALS: int = 2

@export var species: SpeciesType = SpeciesType.DEER
@export var animal_name: String = "Venado del Valle"
@export var max_hp: float = 25.0
@export var graze_speed: float = 24.0
@export var flee_speed: float = 115.0
@export var alert_radius: float = 95.0
@export var meat_drop: int = 2
@export var leather_drop: int = 1
@export var pelt_item_id: String = "leather"
@export var respawn_days: int = 2
@export var persistence_id: String = ""
@export var managed_by_ecosystem: bool = true

## Despiece anatómico completo activado (huesos, astas, vísceras/tendones y grasa animal) + Genética (Nv.1..Nv.3)
@export var enable_advanced_anatomy: bool = true
@export var bones_drop: int = 1
@export var antlers_drop: int = 0
@export var viscera_drop: int = 1
@export var fat_drop: int = 0
@export var genetics_tier: int = 1
var offspring_genetics_tier: int = 1

var current_hp: float = 25.0
var respawn_on_day: int = -1

# Simulación de Vida, Saciedad (0..2), Día de Reserva y Reproducción
var state: AnimalState = AnimalState.GRAZE
var meals_eaten: int = 0
var fed_today: bool = false
var has_reserve_day: bool = false
var is_on_reserve_day: bool = false
var mated_today: bool = false
var pending_offspring: bool = false
var days_hungry: int = 0
var is_raiding_farm: bool = false
var farm_target_pos: Vector2 = Vector2(139, 99)

# Mecánica de Emboscada (Zorro), 50% Escape Inicial (Conejo) y Embestida Agresiva (Jabalí)
var escaped_first_pounce: bool = false
var pounce_timer: float = 0.0
var pounce_duration: float = 0.24
var pounce_dir: Vector2 = Vector2.RIGHT
var pounce_recovery_timer: float = 0.0

@export var max_damage_per_hit: float = 0.0
var hits_taken_count: int = 0
var boar_aggressor: Node2D = null
var boar_aggro_timer: float = 0.0
var boar_charge_windup: float = 0.0
var boar_charge_timer: float = 0.0
var boar_charge_dir: Vector2 = Vector2.RIGHT

var home_position: Vector2 = Vector2.ZERO
var wander_dir: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var flee_timer: float = 0.0
var flee_dir: Vector2 = Vector2.RIGHT
var eat_timer: float = 0.0
var mate_timer: float = 0.0
var burrow_hide_timer: float = 0.0
var attack_cooldown: float = 0.0
var _ai_tick_timer: float = 0.0
var _hop_phase: float = 0.0

var food_target: Node2D = null
var mate_target: WildAnimal = null

var sprite: Sprite2D = null
var body_col: CollisionShape2D = null
var hurtbox: Hurtbox = null
var butcher_area: Area2D = null
var status_label: Label = null

func _ready() -> void:
	set_physics_process(not Engine.is_editor_hint())
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	# Sin Body Block contra el jugador (layer 0), manteniendo Hurtbox en layer 4 para combate/caza
	collision_layer = 0
	collision_mask = 1
	if home_position == Vector2.ZERO:
		home_position = global_position
	current_hp = max_hp
	_ai_tick_timer = randf_range(0.05, 0.35)

	if persistence_id == "":
		persistence_id = "animal_" + name + "_" + str(int(home_position.x)) + "_" + str(int(home_position.y))

	add_to_group("wild_animals")
	match species:
		SpeciesType.RABBIT:
			add_to_group("ecosystem_rabbits")
			add_to_group("herbivore_prey")
		SpeciesType.DEER:
			add_to_group("ecosystem_deer")
		SpeciesType.FOX:
			add_to_group("ecosystem_foxes")
			add_to_group("predators")
		SpeciesType.BOAR:
			add_to_group("ecosystem_boars")

	if not Engine.is_editor_hint():
		if WorldClock:
			WorldClock.day_passed.connect(_on_day_passed)
		if GameManager:
			GameManager.game_loaded.connect(_on_game_loaded)

func setup_animal(tex: Texture2D, spr_scale: Vector2 = Vector2.ONE, col_radius: float = 8.0) -> void:
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = tex
	sprite.scale = spr_scale
	add_child(sprite)

	body_col = CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = col_radius
	body_col.shape = c
	add_child(body_col)

	hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 0
	var hcol := CollisionShape2D.new()
	var hcircle := CircleShape2D.new()
	hcircle.radius = col_radius + 4.0
	hcol.shape = hcircle
	hurtbox.add_child(hcol)
	hurtbox.hit_received.connect(take_damage)
	add_child(hurtbox)

	# Área de interacción para Desollar el cadáver con [E] (solo activa cuando `state == AnimalState.CARCASS`)
	butcher_area = Area2D.new()
	butcher_area.name = "ButcherArea"
	butcher_area.collision_layer = 1
	butcher_area.collision_mask = 2
	butcher_area.add_to_group("interactable")
	var bcol := CollisionShape2D.new()
	var bcircle := CircleShape2D.new()
	bcircle.radius = col_radius + 16.0
	bcol.shape = bcircle
	bcol.disabled = (state != AnimalState.CARCASS)
	butcher_area.add_child(bcol)
	butcher_area.body_entered.connect(_on_butcher_body_entered)
	butcher_area.body_exited.connect(_on_butcher_body_exited)
	add_child(butcher_area)

	status_label = Label.new()
	status_label.visible = false
	status_label.text = ""
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-105, -34)
	status_label.custom_minimum_size = Vector2(210, 20)
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.add_theme_color_override("font_color", Color.ORANGE_RED)
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 3)
	add_child(status_label)

	_check_saved_state()

var _cached_player: Node2D = null

func is_alive_in_ecosystem() -> bool:
	return state != AnimalState.CARCASS and state != AnimalState.BUTCHERED

func is_fully_satiated() -> bool:
	return is_on_reserve_day or meals_eaten >= MAX_MEALS

func can_mate_today() -> bool:
	return is_alive_in_ecosystem() and visible and state != AnimalState.IN_BURROW and meals_eaten >= MAX_MEALS and not mated_today

func _physics_process(delta: float) -> void:
	if state == AnimalState.CARCASS or state == AnimalState.BUTCHERED:
		return

	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if pounce_recovery_timer > 0.0:
		pounce_recovery_timer -= delta
		velocity = Vector2.ZERO
		return

	if state == AnimalState.IN_BURROW:
		_process_in_burrow(delta)
		return

	if not is_instance_valid(_cached_player):
		_cached_player = get_tree().get_first_node_in_group("player") as Node2D
	var far_offscreen: bool = is_instance_valid(_cached_player) and global_position.distance_squared_to(_cached_player.global_position) > 500.0 * 500.0

	if state == AnimalState.POUNCE:
		_process_pounce(delta)
		if far_offscreen:
			global_position += velocity * delta
		else:
			move_and_slide()
			_update_sprite_motion(delta)
		return

	_ai_tick_timer -= delta
	if _ai_tick_timer <= 0.0:
		_ai_tick_timer = 0.45 if far_offscreen else 0.16
		_check_threats()
		_evaluate_life_schedule()
		if far_offscreen:
			if status_label and status_label.visible:
				status_label.visible = false
		else:
			_update_observation_label()

	match state:
		AnimalState.GRAZE:
			_process_graze(delta)
		AnimalState.SEEK_FOOD:
			_process_seek_food(delta)
		AnimalState.STALK_PREY:
			_process_stalk_prey(delta)
		AnimalState.CHASE_PREY:
			_process_chase_prey(delta)
		AnimalState.CHARGE_ATTACK:
			_process_boar_charge_attack(delta)
		AnimalState.EATING:
			_process_eating(delta)
		AnimalState.SEEK_MATE:
			_process_seek_mate(delta)
		AnimalState.RETURN_HOME:
			_process_return_home(delta)
		AnimalState.SLEEP:
			_process_sleep(delta)
		AnimalState.FLEE:
			_process_flee(delta)

	if far_offscreen:
		if velocity.length_squared() > 0.1:
			global_position += velocity * delta
	else:
		if state != AnimalState.SLEEP and is_instance_valid(_cached_player):
			var min_r: float = 15.0 if (species == SpeciesType.RABBIT or species == SpeciesType.FOX) else 18.0
			var d_sq: float = global_position.distance_squared_to(_cached_player.global_position)
			if d_sq < min_r * min_r:
				var d: float = sqrt(d_sq)
				var away: Vector2 = (global_position - _cached_player.global_position) / maxf(0.01, d) if d >= 0.01 else Vector2.RIGHT
				var push_spd: float = 60.0 if (species == SpeciesType.RABBIT or species == SpeciesType.FOX) else 38.0
				velocity += away * ((min_r - d) / min_r) * push_spd
		move_and_slide()
		_update_sprite_motion(delta)

func _update_sprite_motion(delta: float) -> void:
	if not sprite:
		return

	if state == AnimalState.POUNCE:
		# Arco parabólico de salto del zorro en el aire
		var progress: float = 1.0 - clampf(pounce_timer / maxf(0.01, pounce_duration), 0.0, 1.0)
		sprite.position.y = -sin(progress * PI) * 11.5
		sprite.scale.y = 1.22
		sprite.modulate = Color.WHITE
		if abs(velocity.x) > 2.0:
			sprite.flip_h = velocity.x > 0.0
		return

	if state == AnimalState.SLEEP:
		sprite.position = Vector2(0, 2.5)
		sprite.scale.y = lerpf(sprite.scale.y, 0.82, 8.0 * delta)
		sprite.modulate = Color.WHITE
		return
	elif state == AnimalState.STALK_PREY:
		# Sigilo del zorro: cuerpo agachado pegado al suelo y tinte sigiloso
		sprite.scale.y = lerpf(sprite.scale.y, 0.78, 10.0 * delta)
		sprite.modulate = Color(0.84, 0.86, 0.94, 0.92)
	else:
		var base_sy: float = 1.15 if species != SpeciesType.RABBIT else 1.1
		sprite.scale.y = lerpf(sprite.scale.y, base_sy, 8.0 * delta)
		sprite.modulate = Color.WHITE

	if abs(velocity.x) > 2.0:
		sprite.flip_h = velocity.x > 0.0
	if velocity.length_squared() > 16.0:
		var hop_freq: float = 18.0 if (state == AnimalState.FLEE or state == AnimalState.CHASE_PREY) else (6.5 if state == AnimalState.STALK_PREY else 9.0)
		_hop_phase += delta * hop_freq
		var hop_amp: float = 1.0 if state == AnimalState.STALK_PREY else (3.2 if state == AnimalState.FLEE else 2.2)
		sprite.position.y = -abs(sin(_hop_phase)) * hop_amp
	else:
		sprite.position.y = 0.0

## Detecta amenazas (los conejos casi no detectan al zorro si este se acerca en modo sigilo STALK_PREY; los jabalíes no huyen salvo ser provocados)
func _check_threats() -> void:
	if state in [AnimalState.IN_BURROW, AnimalState.CARCASS, AnimalState.BUTCHERED, AnimalState.POUNCE, AnimalState.CHARGE_ATTACK, AnimalState.EATING]:
		return
	if species == SpeciesType.BOAR:
		# Baja probabilidad (~1.5%) de disputa territorial entre Jabalíes y Zorros cercanos
		if attack_cooldown <= 0.0 and randf() < 0.015:
			for fx in get_tree().get_nodes_in_group("ecosystem_foxes"):
				if fx is WildAnimal and fx.is_alive_in_ecosystem() and fx.visible and global_position.distance_squared_to(fx.global_position) <= 54.0 * 54.0:
					_start_boar_aggro(fx)
					if randf() < 0.55 and fx.attack_cooldown <= 0.0:
						var bite := DamageData.new()
						bite.amount = 10.0
						bite.type = CombatConstants.DamageType.BLUNT
						bite.source = fx
						take_damage(bite)
					break
		return

	# 1. Los conejos detectan a los Zorros cercanos (si el zorro acecha en STALK_PREY, tienen margen de alerta de 46 px para intentar escapar)
	if species == SpeciesType.RABBIT:
		var predators := get_tree().get_nodes_in_group("predators")
		for pred in predators:
			if pred is WildAnimal and pred.is_alive_in_ecosystem() and pred.visible:
				if pred.is_fully_satiated() and pred.state == AnimalState.GRAZE:
					continue
				var d_sq := global_position.distance_squared_to(pred.global_position)
				var pred_alert: float = 46.0 if pred.state == AnimalState.STALK_PREY else (alert_radius * 0.95)
				if d_sq <= pred_alert * pred_alert:
					_start_flee_from(pred.global_position)
					return

	# 2. Detección del Jugador según sigilo, ruido y hora del día
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var dist_sq := global_position.distance_squared_to(player.global_position)
	var eff_alert := alert_radius
	if WorldClock:
		eff_alert *= WorldClock.get_vision_multiplier()
	if state == AnimalState.SLEEP:
		eff_alert *= 0.38

	if player.has_method("is_stealthing") and player.is_stealthing():
		eff_alert *= 0.35
		if player.has_method("get_stealth_detection_multiplier"):
			eff_alert *= float(player.call("get_stealth_detection_multiplier"))
	elif player.has_method("get_noise_multiplier"):
		var noise: float = player.get_noise_multiplier()
		if noise > 1.2:
			eff_alert *= 1.55

	if dist_sq <= eff_alert * eff_alert:
		_start_flee_from(player.global_position)

## Rutina de vida conectada al WorldClock, Saciedad (2 comidas) y Reproducción (SEEK_MATE)
func _evaluate_life_schedule() -> void:
	if state in [AnimalState.FLEE, AnimalState.EATING, AnimalState.POUNCE, AnimalState.CHARGE_ATTACK, AnimalState.CARCASS, AnimalState.BUTCHERED, AnimalState.IN_BURROW]:
		return

	var is_night_time := false
	if WorldClock:
		var h: int = WorldClock.current_hour
		if species == SpeciesType.FOX:
			is_night_time = (h >= 1 and h < 6)
		else:
			is_night_time = (h >= 20 or h < 6)

	if is_night_time:
		# Si un zorro no logró comer durante el día, sale de noche a asaltar el Gallinero solo si quedan gallinas vivas
		var coop_node = get_tree().get_first_node_in_group("chicken_coop") if species == SpeciesType.FOX else null
		if species == SpeciesType.FOX and not fed_today and not is_on_reserve_day and coop_node is ChickenCoop and coop_node.has_live_chickens():
			pass
		else:
			var dist_home := global_position.distance_to(home_position)
			if dist_home > 18.0:
				state = AnimalState.RETURN_HOME
			else:
				if species == SpeciesType.RABBIT:
					_enter_burrow(0.0)
				else:
					state = AnimalState.SLEEP
			return
	else:
		if state == AnimalState.SLEEP:
			state = AnimalState.GRAZE
		elif state == AnimalState.RETURN_HOME and global_position.distance_to(home_position) <= 85.0:
			state = AnimalState.GRAZE

	# 1. Si ya comió sus 2 raciones hoy (meals_eaten >= 2) y aún no se ha emparejado hoy, buscar pareja con 2/2
	if can_mate_today():
		var potential_mate := _find_ready_mate()
		if is_instance_valid(potential_mate):
			mate_target = potential_mate
			state = AnimalState.SEEK_MATE
			return

	# 2. Si está Saciado (2/2 comidas hoy) o en su Día de Reserva, regresa a su propio hábitat y pasea allí sin mezclarse
	if is_fully_satiated():
		if state in [AnimalState.SEEK_FOOD, AnimalState.STALK_PREY, AnimalState.CHASE_PREY]:
			food_target = null
			state = AnimalState.GRAZE
		if state == AnimalState.GRAZE and global_position.distance_to(home_position) > 115.0:
			state = AnimalState.RETURN_HOME
		return

	# 3. Si aún no llega a 2/2 comidas y no está en día de reserva, busca su siguiente ración
	if state == AnimalState.GRAZE:
		var target := _find_best_food_target()
		if is_instance_valid(target):
			food_target = target
			if species == SpeciesType.FOX and target is WildAnimal and target.state != AnimalState.CARCASS:
				state = AnimalState.STALK_PREY
			else:
				state = AnimalState.SEEK_FOOD
		elif species != SpeciesType.FOX and not fed_today and days_hungry >= 1:
			is_raiding_farm = true
			state = AnimalState.SEEK_FOOD
		elif global_position.distance_to(home_position) > 135.0:
			is_raiding_farm = false
			state = AnimalState.RETURN_HOME

func _find_ready_mate() -> WildAnimal:
	var group_name := "ecosystem_rabbits"
	if species == SpeciesType.DEER:
		group_name = "ecosystem_deer"
	elif species == SpeciesType.FOX:
		group_name = "ecosystem_foxes"
	elif species == SpeciesType.BOAR:
		group_name = "ecosystem_boars"

	var best_mate: WildAnimal = null
	var best_dist_sq: float = 380.0 * 380.0
	for node in get_tree().get_nodes_in_group(group_name):
		if node != self and node is WildAnimal and node.can_mate_today():
			var d_sq := global_position.distance_squared_to(node.global_position)
			if d_sq < best_dist_sq:
				best_dist_sq = d_sq
				best_mate = node
	return best_mate

func _find_best_food_target() -> Node2D:
	var best_node: Node2D = null
	var best_dist_sq: float = 1250.0 * 1250.0

	if species in [SpeciesType.RABBIT, SpeciesType.DEER, SpeciesType.BOAR]:
		# Primero priorizar la flora dentro de su propio hábitat (<= 270 px de su madriguera/claro) para que las especies no se mezclen
		var local_habitat_sq: float = 270.0 * 270.0
		var best_local_sq: float = 1250.0 * 1250.0
		for node in get_tree().get_nodes_in_group("wild_flora"):
			if node is HarvestableNode and not node.is_depleted:
				if home_position.distance_squared_to(node.global_position) <= local_habitat_sq:
					var d_sq := global_position.distance_squared_to(node.global_position)
					if d_sq < best_local_sq:
						best_local_sq = d_sq
						best_node = node
		# Solo si la flora local de su zona se agotó busca en el resto del bosque
		if not best_node:
			for node in get_tree().get_nodes_in_group("wild_flora"):
				if node is HarvestableNode and not node.is_depleted:
					var d_sq := global_position.distance_squared_to(node.global_position)
					if d_sq < best_dist_sq:
						best_dist_sq = d_sq
						best_node = node
		if not best_node:
			for crop in get_tree().get_nodes_in_group("farm_crops"):
				if crop is Node2D and crop.visible:
					var d_sq := global_position.distance_squared_to(crop.global_position)
					if d_sq < best_dist_sq:
						best_dist_sq = d_sq
						best_node = crop
						is_raiding_farm = true
	elif species == SpeciesType.FOX:
		var best_prey_sq: float = 1850.0 * 1850.0
		var live_rabbits: int = 0
		for node in get_tree().get_nodes_in_group("ecosystem_rabbits"):
			if node is WildAnimal:
				if node.state == AnimalState.CARCASS and node.visible:
					var d_sq := global_position.distance_squared_to(node.global_position)
					if d_sq < best_prey_sq:
						best_prey_sq = d_sq
						best_node = node
				elif node.is_alive_in_ecosystem():
					live_rabbits += 1
		if best_node:
			return best_node

		if live_rabbits > 4:
			var all_foxes := get_tree().get_nodes_in_group("ecosystem_foxes")
			for rab in get_tree().get_nodes_in_group("herbivore_prey"):
				if rab is WildAnimal and rab.is_alive_in_ecosystem() and rab.state != AnimalState.IN_BURROW and rab.visible:
					var d_sq := global_position.distance_squared_to(rab.global_position)
					for fx in all_foxes:
						if fx != self and fx is WildAnimal and fx.food_target == rab:
							d_sq += 260.0 * 260.0
					if d_sq < best_prey_sq:
						best_prey_sq = d_sq
						best_node = rab

		var h_now: int = WorldClock.current_hour if WorldClock else 12
		var is_coop_raid_window: bool = (h_now >= 20 or h_now < 6) and not fed_today
		if not best_node and is_coop_raid_window:
			var coop = get_tree().get_first_node_in_group("chicken_coop")
			if coop is ChickenCoop and coop.has_live_chickens():
				best_node = coop
				is_raiding_farm = true
			else:
				is_raiding_farm = false
				for poultry in get_tree().get_nodes_in_group("livestock_prey"):
					if poultry is Node2D and poultry.visible:
						var d_sq := global_position.distance_squared_to(poultry.global_position)
						if d_sq < best_dist_sq:
							best_dist_sq = d_sq
							best_node = poultry
							is_raiding_farm = true
		elif not best_node:
			is_raiding_farm = false

	return best_node

func _start_flee_from(danger_pos: Vector2) -> void:
	if state in [AnimalState.CARCASS, AnimalState.BUTCHERED, AnimalState.IN_BURROW]:
		return
	var away := (global_position - danger_pos).normalized()
	if away.length_squared() < 0.01:
		away = Vector2.LEFT
	if species == SpeciesType.RABBIT:
		var to_burrow := (home_position - global_position)
		if to_burrow.length() < 190.0 and to_burrow.normalized().dot(away) > -0.25:
			away = to_burrow.normalized()
	flee_dir = away
	flee_timer = 3.2
	state = AnimalState.FLEE

func _process_graze(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = randf_range(1.8, 3.8)
		if randf() < 0.45:
			wander_dir = Vector2.ZERO
		else:
			var anchor := home_position
			if species == SpeciesType.DEER:
				anchor = _get_herd_anchor()
			var to_anchor := anchor - global_position
			if to_anchor.length() > 90.0:
				wander_dir = to_anchor.normalized()
			else:
				wander_dir = Vector2.RIGHT.rotated(randf() * TAU)
	velocity = wander_dir * graze_speed

func _get_herd_anchor() -> Vector2:
	var sum_pos := home_position
	var count := 1
	for d in get_tree().get_nodes_in_group("ecosystem_deer"):
		if d != self and d is WildAnimal and d.is_alive_in_ecosystem():
			if global_position.distance_squared_to(d.global_position) < 220.0 * 220.0:
				sum_pos += d.global_position
				count += 1
	return sum_pos / float(count)

func _process_seek_food(_delta: float) -> void:
	if is_fully_satiated():
		food_target = null
		state = AnimalState.GRAZE
		return

	if not is_instance_valid(food_target) or not food_target.visible:
		if species == SpeciesType.FOX:
			is_raiding_farm = false
		if is_raiding_farm:
			var to_farm := farm_target_pos - global_position
			if to_farm.length() > 35.0:
				velocity = to_farm.normalized() * (graze_speed * 1.25)
			else:
				is_raiding_farm = false
				state = AnimalState.GRAZE
			return
		food_target = _find_best_food_target()
		if not is_instance_valid(food_target):
			state = AnimalState.RETURN_HOME if global_position.distance_to(home_position) > 95.0 else AnimalState.GRAZE
			velocity = Vector2.ZERO
			return

	if food_target is HarvestableNode and food_target.is_depleted:
		food_target = null
		state = AnimalState.GRAZE
		return

	# Si el zorro hambriento va a asaltar el Gallinero: primero abre un agujero en la cerca y luego entra
	if food_target is ChickenCoop:
		if not food_target.has_live_chickens():
			food_target = null
			is_raiding_farm = false
			state = AnimalState.RETURN_HOME
			return
		if not food_target.is_breached:
			var breach_pos: Vector2 = food_target.get_breach_world_position()
			var to_breach := breach_pos - global_position
			if to_breach.length() <= 16.0:
				velocity = Vector2.ZERO
				if attack_cooldown <= 0.0:
					attack_cooldown = 1.0
					food_target.damage_fence_by_fox(1.0)
			else:
				velocity = to_breach.normalized() * (graze_speed * 1.35)
			return
		else:
			var to_inside := food_target.global_position - global_position
			if to_inside.length() <= 16.0:
				velocity = Vector2.ZERO
				eat_timer = 2.6
				state = AnimalState.EATING
			else:
				velocity = to_inside.normalized() * (graze_speed * 1.4)
			return

	var to_food := food_target.global_position - global_position
	var dist := to_food.length()
	if dist <= 15.0:
		velocity = Vector2.ZERO
		eat_timer = 2.6
		state = AnimalState.EATING
	else:
		velocity = to_food.normalized() * (graze_speed * 1.25)

## El zorro se acerca en sigilo (STALK_PREY) para cortar distancia antes de que el conejo corra
func _process_stalk_prey(_delta: float) -> void:
	if is_fully_satiated():
		food_target = null
		state = AnimalState.GRAZE
		return
	if not is_instance_valid(food_target) or not (food_target is WildAnimal) or not food_target.visible or food_target.state == AnimalState.IN_BURROW:
		food_target = null
		state = AnimalState.GRAZE
		return
	if food_target.state == AnimalState.CARCASS:
		state = AnimalState.SEEK_FOOD
		return

	var to_prey := food_target.global_position - global_position
	var dist := to_prey.length()

	# Si está a distancia de salto (<= 40 px), lanza el Salto de Takedown (POUNCE)
	if dist <= 40.0 and attack_cooldown <= 0.0:
		_start_pounce(food_target)
		return

	# Si el conejo ya descubrió al zorro y está corriendo, el zorro intenta perseguirlo brevemente
	if food_target.state == AnimalState.FLEE and dist > 52.0:
		state = AnimalState.CHASE_PREY
		return

	# Avanza agachado en sigilo recortando distancia
	velocity = to_prey.normalized() * (graze_speed * 1.38)

func _start_pounce(target: WildAnimal) -> void:
	state = AnimalState.POUNCE
	pounce_duration = 0.24
	pounce_timer = pounce_duration
	pounce_dir = (target.global_position - global_position).normalized()
	if pounce_dir.length_squared() < 0.01:
		pounce_dir = Vector2.RIGHT

func _process_pounce(delta: float) -> void:
	pounce_timer -= delta
	if is_instance_valid(food_target) and food_target is WildAnimal and food_target.visible and food_target.state != AnimalState.IN_BURROW:
		var to_prey := food_target.global_position - global_position
		if to_prey.length_squared() > 4.0:
			pounce_dir = to_prey.normalized()
		if to_prey.length() <= 16.5:
			_resolve_pounce_hit(food_target)
			return

	velocity = pounce_dir * 245.0
	if pounce_timer <= 0.0:
		velocity = Vector2.ZERO
		if is_instance_valid(food_target) and food_target is WildAnimal and global_position.distance_to(food_target.global_position) <= 20.0:
			_resolve_pounce_hit(food_target)
		else:
			pounce_recovery_timer = 0.45
			state = AnimalState.GRAZE

## Resuelve el Salto de Takedown del Zorro sobre el Conejo (con 50% de escape la primera vez)
func _resolve_pounce_hit(prey: WildAnimal) -> void:
	velocity = Vector2.ZERO
	if sprite:
		sprite.position.y = 0.0

	if not is_instance_valid(prey) or not prey.is_alive_in_ecosystem() or prey.state == AnimalState.IN_BURROW:
		state = AnimalState.GRAZE
		return

	# 50% de probabilidad de que el conejo se zafe del agarre la primera vez que lo atrapan
	if not prey.escaped_first_pounce and randf() < 0.50:
		prey.escaped_first_pounce = true
		prey._start_flee_from(global_position)
		prey.global_position += prey.flee_dir * 10.0
		if prey.status_label:
			prey.status_label.text = "¡Se zafó!"
			prey.status_label.add_theme_color_override("font_color", Color.SPRING_GREEN)
			prey.status_label.visible = true
		# El zorro queda 0.65s recuperándose del salto fallido mientras el conejo corre más rápido
		attack_cooldown = 1.2
		pounce_recovery_timer = 0.65
		state = AnimalState.GRAZE
		return

	# ¡Takedown exitoso! El zorro sujeta y abate al conejo en el acto
	prey.take_pounce_takedown()
	eat_timer = 3.0
	state = AnimalState.EATING

func _process_chase_prey(_delta: float) -> void:
	if is_fully_satiated():
		food_target = null
		state = AnimalState.GRAZE
		return
	if not is_instance_valid(food_target) or not (food_target is WildAnimal) or not food_target.visible or food_target.state == AnimalState.IN_BURROW:
		food_target = null
		state = AnimalState.GRAZE
		return
	if food_target.state == AnimalState.CARCASS:
		state = AnimalState.SEEK_FOOD
		return

	var to_prey := food_target.global_position - global_position
	var dist := to_prey.length()
	if dist <= 36.0 and attack_cooldown <= 0.0:
		_start_pounce(food_target)
		return
	# Como el conejo corre más rápido (132 vs 122), si se aleja demasiado el zorro desiste y vuelve a acechar
	if dist > 145.0:
		food_target = null
		state = AnimalState.GRAZE
		return
	velocity = to_prey.normalized() * flee_speed

func _process_eating(delta: float) -> void:
	velocity = Vector2.ZERO
	eat_timer -= delta
	if eat_timer <= 0.0:
		var ate_successfully := false
		if is_instance_valid(food_target):
			if food_target is HarvestableNode and food_target.has_method("consume_by_animal"):
				if food_target.consume_by_animal():
					ate_successfully = true
			elif food_target is WildAnimal and food_target.state in [AnimalState.CARCASS, AnimalState.BUTCHERED]:
				if food_target.state == AnimalState.CARCASS:
					food_target.consume_by_predator()
				ate_successfully = true
			elif food_target is ChickenCoop:
				if food_target.steal_chicken_by_fox():
					ate_successfully = true
			elif food_target.is_in_group("farm_crops") or food_target.is_in_group("livestock_prey"):
				if food_target.has_method("consume_by_animal"):
					food_target.call("consume_by_animal")
				ate_successfully = true

		if ate_successfully:
			_register_meal_eaten()

		food_target = null
		state = AnimalState.RETURN_HOME if global_position.distance_to(home_position) > 120.0 else AnimalState.GRAZE

func _register_meal_eaten() -> void:
	meals_eaten = MAX_MEALS if species == SpeciesType.FOX else (meals_eaten + 1)
	fed_today = true
	days_hungry = 0
	is_raiding_farm = false
	if meals_eaten >= MAX_MEALS:
		# ¡Estómago lleno (2/2)! Gana 1 Día de Reserva sin necesidad de comer mañana
		has_reserve_day = true

## Encuentro de dos animales de la misma especie que comieron 2 veces hoy (2/2 + 2/2 -> Cría)
func _process_seek_mate(delta: float) -> void:
	if not is_instance_valid(mate_target) or not mate_target.can_mate_today():
		mate_target = null
		state = AnimalState.GRAZE
		return

	var to_mate := mate_target.global_position - global_position
	var dist := to_mate.length()
	if dist <= 20.0:
		velocity = Vector2.ZERO
		mate_timer += delta
		if status_label:
			status_label.text = "%s [Cortejo ♥]" % animal_name
			status_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.82))
			status_label.visible = true
		if mate_timer >= 1.6:
			mate_timer = 0.0
			mated_today = true
			mate_target.mated_today = true
			var next_gen: int = mini(3, maxi(genetics_tier, mate_target.genetics_tier) + 1)
			offspring_genetics_tier = next_gen
			# 75% de probabilidad de tener una cría al haber comido 2 veces ambos padres
			if randf() <= 0.75:
				pending_offspring = true
			mate_target = null
			state = AnimalState.GRAZE
	else:
		velocity = to_mate.normalized() * (graze_speed * 1.15)

func _process_return_home(_delta: float) -> void:
	var to_home := home_position - global_position
	if to_home.length() <= 14.0:
		velocity = Vector2.ZERO
		var is_night: bool = WorldClock != null and (WorldClock.current_hour >= 20 or WorldClock.current_hour < 6)
		if not is_night:
			state = AnimalState.GRAZE
		elif species == SpeciesType.RABBIT:
			_enter_burrow(0.0)
		else:
			state = AnimalState.SLEEP
	else:
		velocity = to_home.normalized() * (graze_speed * 1.15)

func _process_sleep(_delta: float) -> void:
	velocity = Vector2.ZERO

func _enter_burrow(duration: float = 0.0) -> void:
	state = AnimalState.IN_BURROW
	burrow_hide_timer = duration
	velocity = Vector2.ZERO
	visible = false
	if body_col:
		body_col.set_deferred("disabled", true)
	if hurtbox and hurtbox.get_child_count() > 0:
		var hcol := hurtbox.get_child(0) as CollisionShape2D
		if hcol:
			hcol.set_deferred("disabled", true)

func _exit_burrow() -> void:
	if state != AnimalState.IN_BURROW:
		return
	state = AnimalState.GRAZE
	global_position = home_position + Vector2.RIGHT.rotated(randf() * TAU) * 10.0
	visible = true
	if not is_in_group("wild_animals"):
		add_to_group("wild_animals")
	if body_col:
		body_col.set_deferred("disabled", false)
	if hurtbox and hurtbox.get_child_count() > 0:
		var hcol := hurtbox.get_child(0) as CollisionShape2D
		if hcol:
			hcol.set_deferred("disabled", false)

func _process_in_burrow(delta: float) -> void:
	if burrow_hide_timer > 0.0:
		burrow_hide_timer -= delta
		if burrow_hide_timer <= 0.0:
			_exit_burrow()
		return
	if WorldClock:
		var h: int = WorldClock.current_hour
		if h >= 6 and h < 20:
			_exit_burrow()

func _process_flee(delta: float) -> void:
	flee_timer -= delta
	velocity = flee_dir * flee_speed
	if species == SpeciesType.RABBIT and global_position.distance_squared_to(home_position) <= 18.0 * 18.0:
		_enter_burrow(7.0)
		return
	if get_slide_collision_count() > 0:
		flee_dir = flee_dir.rotated(randf_range(1.0, 2.2))
	if flee_timer <= 0.0:
		state = AnimalState.GRAZE
		velocity = Vector2.ZERO

## Provocación y Embestida Agresiva del Jabalí (`SpeciesType.BOAR`) al ser atacado
func _start_boar_aggro(attacker: Node2D) -> void:
	if state in [AnimalState.CARCASS, AnimalState.BUTCHERED, AnimalState.IN_BURROW]:
		return
	boar_aggressor = attacker
	boar_aggro_timer = 11.5
	boar_charge_windup = 0.25
	boar_charge_timer = 0.0
	if is_instance_valid(attacker):
		var dir := (attacker.global_position - global_position).normalized()
		boar_charge_dir = dir if dir.length_squared() > 0.01 else Vector2.RIGHT
	state = AnimalState.CHARGE_ATTACK
	if status_label:
		status_label.text = "🐗💢 ¡Jabalí Enfurecido!"
		status_label.add_theme_color_override("font_color", Color.ORANGE_RED)
		status_label.visible = true

func _process_boar_charge_attack(delta: float) -> void:
	boar_aggro_timer -= delta
	var target_dead: bool = (not is_instance_valid(boar_aggressor)) or ("is_dead" in boar_aggressor and bool(boar_aggressor.get("is_dead"))) or (boar_aggressor is WildAnimal and not (boar_aggressor as WildAnimal).is_alive_in_ecosystem())
	if boar_aggro_timer <= 0.0 or target_dead or global_position.distance_to(boar_aggressor.global_position) > 275.0:
		boar_aggressor = null
		boar_charge_windup = 0.0
		boar_charge_timer = 0.0
		velocity = Vector2.ZERO
		state = AnimalState.GRAZE
		return

	var to_target: Vector2 = boar_aggressor.global_position - global_position
	var dist: float = to_target.length()

	# 1. Fase de Embestida a toda velocidad
	if boar_charge_timer > 0.0:
		boar_charge_timer -= delta
		velocity = boar_charge_dir * 168.0
		if dist <= 22.0 and attack_cooldown <= 0.0:
			_deliver_boar_ram_hit(boar_aggressor)
			boar_charge_timer = 0.0
			velocity = Vector2.ZERO
		return

	# 2. Fase de Preparación (escarbando el suelo antes de embestir)
	if boar_charge_windup > 0.0:
		boar_charge_windup -= delta
		velocity = Vector2.ZERO
		if dist > 1.0:
			boar_charge_dir = to_target.normalized()
		if boar_charge_windup <= 0.0:
			boar_charge_timer = 0.50
			if status_label:
				status_label.text = "🐗💥 ¡EMBESTIDA!"
				status_label.add_theme_color_override("font_color", Color(1.0, 0.30, 0.20))
				status_label.visible = true
		return

	# 3. Persecución agresiva hasta entrar en rango de embestida
	if dist <= 20.0 and attack_cooldown <= 0.0:
		_deliver_boar_ram_hit(boar_aggressor)
		return
	elif dist <= 115.0 and attack_cooldown <= 0.0:
		boar_charge_windup = 0.26
		boar_charge_dir = to_target.normalized() if dist > 1.0 else Vector2.RIGHT
		velocity = Vector2.ZERO
		return

	velocity = (to_target.normalized() if dist > 1.0 else Vector2.ZERO) * 86.0

func _deliver_boar_ram_hit(target: Node2D) -> void:
	attack_cooldown = 1.35
	if not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		var dmg := DamageData.new()
		dmg.amount = 18.0
		dmg.type = CombatConstants.DamageType.BLUNT
		dmg.stun_buildup = 32.0
		dmg.source = self
		target.call("take_damage", dmg)
	if target.has_method("apply_push"):
		target.call("apply_push", boar_charge_dir * 180.0)

func _update_observation_label() -> void:
	if not status_label or state in [AnimalState.CARCASS, AnimalState.BUTCHERED, AnimalState.IN_BURROW]:
		return

	var mouse_pos := get_global_mouse_position()
	var cursor_near := global_position.distance_squared_to(mouse_pos) <= 32.0 * 32.0

	if state == AnimalState.FLEE and not cursor_near:
		status_label.text = "!"
		status_label.add_theme_color_override("font_color", Color.ORANGE_RED)
		status_label.visible = true
		return

	if state == AnimalState.SLEEP and not cursor_near:
		status_label.text = "Zzz"
		status_label.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0, 0.85))
		status_label.visible = true
		return

	if not cursor_near:
		status_label.visible = false
		return

	var food_badge: String = "Reserva" if is_on_reserve_day else ("%d/%d" % [meals_eaten, MAX_MEALS])
	var action_txt := "Pastando"
	match state:
		AnimalState.GRAZE:
			if is_on_reserve_day or meals_eaten >= MAX_MEALS:
				action_txt = "Saciado - Descansando"
			else:
				action_txt = "En manada" if species == SpeciesType.DEER else ("Merodeando" if species == SpeciesType.FOX else "Pastando")
		AnimalState.SEEK_FOOD:
			if food_target is ChickenCoop and not food_target.is_breached:
				action_txt = "Abriendo agujero en Gallinero"
			elif is_raiding_farm:
				action_txt = "Hambriento (Asaltando Gallinero)"
			else:
				action_txt = "Buscando presa" if species == SpeciesType.FOX else "Buscando plantas"
		AnimalState.STALK_PREY:
			action_txt = "Acechando en sigilo"
		AnimalState.POUNCE:
			action_txt = "¡Salto de caza!"
		AnimalState.CHASE_PREY:
			action_txt = "Persiguiendo presa"
		AnimalState.CHARGE_ATTACK:
			action_txt = "¡Embistiendo agresivo!"
		AnimalState.EATING:
			action_txt = "Devorando presa" if species == SpeciesType.FOX else "Comiendo brotes"
		AnimalState.SEEK_MATE:
			action_txt = "Buscando pareja ♥"
		AnimalState.RETURN_HOME:
			action_txt = "Volviendo a su refugio"
		AnimalState.SLEEP:
			action_txt = "Durmiendo (Zzz)"
		AnimalState.FLEE:
			action_txt = "Huyendo asustado"

	var gen_tag: String = (" | 🧬Nv.%d" % genetics_tier) if genetics_tier >= 2 else ""
	status_label.text = "%s [%s | %s%s]" % [animal_name, action_txt, food_badge, gen_tag]
	status_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45) if genetics_tier >= 2 else Color(0.95, 0.92, 0.72))
	status_label.visible = true

func take_pounce_takedown() -> void:
	if state in [AnimalState.CARCASS, AnimalState.BUTCHERED, AnimalState.IN_BURROW]:
		return
	current_hp = 0.0
	_become_carcass()

func take_damage(data: DamageData) -> void:
	if state in [AnimalState.CARCASS, AnimalState.BUTCHERED, AnimalState.IN_BURROW]:
		return
	var raw_dmg: float = data.amount if data else 10.0
	var eff_dmg: float = minf(raw_dmg, max_damage_per_hit) if max_damage_per_hit > 0.0 else raw_dmg
	hits_taken_count += 1
	current_hp -= eff_dmg

	# Garantía de resistencia para Jabalíes: deben aguantar al menos 3 golpes antes de caer abatidos
	if species == SpeciesType.BOAR and hits_taken_count < 3 and current_hp <= 0.0:
		current_hp = maxf(4.0, max_hp * float(3 - hits_taken_count) * 0.25)

	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(3.0, 1.0, 1.0), 0.06)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.08)

	if current_hp <= 0.0:
		_become_carcass()
	else:
		if data and data.stun_buildup >= 50.0:
			pounce_recovery_timer = maxf(pounce_recovery_timer, 3.0)
		var attacker_node: Node2D = data.source as Node2D if (data and is_instance_valid(data.source) and data.source is Node2D and not data.source.is_in_group("player_trap")) else (get_tree().get_first_node_in_group("player") as Node2D)
		if species == SpeciesType.BOAR and is_instance_valid(attacker_node):
			_start_boar_aggro(attacker_node)
		else:
			var danger_pos: Vector2 = attacker_node.global_position if is_instance_valid(attacker_node) else global_position
			_start_flee_from(danger_pos)

func _become_carcass() -> void:
	state = AnimalState.CARCASS
	velocity = Vector2.ZERO
	remove_from_group("wild_animals")

	if body_col:
		body_col.set_deferred("disabled", true)
	if hurtbox and hurtbox.get_child_count() > 0:
		var hcol := hurtbox.get_child(0) as CollisionShape2D
		if hcol:
			hcol.set_deferred("disabled", true)
	if butcher_area and butcher_area.get_child_count() > 0:
		var bcol := butcher_area.get_child(0) as CollisionShape2D
		if bcol:
			bcol.set_deferred("disabled", false)

	if sprite:
		sprite.position = Vector2(0, 3)
		sprite.rotation_degrees = 90.0
		sprite.modulate = Color(0.75, 0.68, 0.68, 0.95)

	if status_label:
		status_label.text = "[E] Desollar %s" % animal_name
		status_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.65))
		var player = get_tree().get_first_node_in_group("player")
		status_label.visible = (player != null and global_position.distance_squared_to(player.global_position) <= 900.0)

func consume_by_predator() -> void:
	if state != AnimalState.CARCASS:
		return
	_finish_butchering()

func _on_butcher_body_entered(body: Node) -> void:
	if state == AnimalState.CARCASS and body.is_in_group("player") and status_label:
		status_label.text = "[E] Desollar %s" % animal_name
		status_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.65))
		status_label.visible = true

func _on_butcher_body_exited(body: Node) -> void:
	if state == AnimalState.CARCASS and body.is_in_group("player") and status_label:
		status_label.visible = false

func get_anatomy_yields() -> Dictionary:
	var gen_bonus: int = maxi(0, genetics_tier - 1)
	var yields: Dictionary = {
		"raw_meat": meat_drop + gen_bonus,
		pelt_item_id: leather_drop + (1 if genetics_tier >= 3 else 0)
	}
	if enable_advanced_anatomy:
		if bones_drop > 0:
			yields["bones"] = bones_drop + (1 if genetics_tier >= 2 else 0)
		if antlers_drop > 0:
			yields["antlers"] = antlers_drop
		if viscera_drop > 0:
			yields["sinew_viscera"] = viscera_drop
		if fat_drop > 0:
			yields["animal_fat"] = fat_drop + (1 if genetics_tier >= 2 else 0)
	return yields

func interact(player: Node) -> void:
	if state != AnimalState.CARCASS or not player:
		return

	var yields := get_anatomy_yields()
	var summary_parts: Array[String] = []

	if "inventory" in player and player.inventory:
		for item_id in yields.keys():
			var qty: int = int(yields[item_id])
			if qty > 0:
				player.inventory.add_item(str(item_id), qty)
				summary_parts.append("+%d %s" % [qty, player.inventory.get_item_name(str(item_id))])

	if player.has_method("_spawn_floating_text") and not summary_parts.is_empty():
		player._spawn_floating_text("🔪 Desollado: " + ", ".join(summary_parts), Color.GOLD, -44.0)

	_finish_butchering()

func _finish_butchering() -> void:
	state = AnimalState.BUTCHERED
	if not Engine.is_editor_hint():
		var cur_day: int = WorldClock.current_day if WorldClock else 1
		respawn_on_day = cur_day + max(1, respawn_days)
		if GameManager and persistence_id != "":
			GameManager.set_flag(persistence_id, respawn_on_day)
	_apply_hidden_state(true)

func _apply_hidden_state(hidden_state: bool) -> void:
	visible = not hidden_state
	set_physics_process(not hidden_state and not Engine.is_editor_hint())
	if hidden_state and state == AnimalState.BUTCHERED:
		remove_from_group("wild_animals")
	if status_label:
		status_label.visible = false
	if body_col:
		body_col.set_deferred("disabled", hidden_state)
	if hurtbox and hurtbox.get_child_count() > 0:
		var hcol := hurtbox.get_child(0) as CollisionShape2D
		if hcol:
			hcol.set_deferred("disabled", hidden_state)
	if butcher_area and butcher_area.get_child_count() > 0:
		var bcol_h := butcher_area.get_child(0) as CollisionShape2D
		if bcol_h:
			bcol_h.set_deferred("disabled", hidden_state or state != AnimalState.CARCASS)

func respawn_from_ecosystem(new_genetics: int = 1) -> void:
	genetics_tier = clampi(new_genetics, 1, 3)
	_respawn_animal()

func _respawn_animal() -> void:
	state = AnimalState.GRAZE
	respawn_on_day = -1
	current_hp = max_hp + float((genetics_tier - 1) * 5)
	hits_taken_count = 0
	boar_aggressor = null
	boar_aggro_timer = 0.0
	boar_charge_windup = 0.0
	boar_charge_timer = 0.0
	meals_eaten = 0
	fed_today = false
	has_reserve_day = false
	is_on_reserve_day = false
	mated_today = false
	pending_offspring = false
	escaped_first_pounce = false
	days_hungry = 0
	is_raiding_farm = false
	global_position = home_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(6.0, 20.0)
	if not is_in_group("wild_animals"):
		add_to_group("wild_animals")
	if sprite:
		sprite.position = Vector2.ZERO
		sprite.rotation_degrees = 0.0
		sprite.modulate = Color(1.08, 1.04, 0.88) if genetics_tier >= 2 else Color.WHITE
	if GameManager and persistence_id != "":
		GameManager.set_flag(persistence_id, -1)
	_apply_hidden_state(false)

func _on_day_passed(new_day: int) -> void:
	if not managed_by_ecosystem:
		if state == AnimalState.BUTCHERED and respawn_on_day > 0 and new_day >= respawn_on_day:
			_respawn_animal()

func _on_game_loaded(_filepath: String) -> void:
	_check_saved_state()

func _check_saved_state() -> void:
	if Engine.is_editor_hint() or managed_by_ecosystem or not GameManager or persistence_id == "":
		return
	var saved_val: Variant = GameManager.get_flag(persistence_id, -1)
	var saved_day: int = int(saved_val) if typeof(saved_val) in [TYPE_INT, TYPE_FLOAT] else -1
	var cur_day: int = WorldClock.current_day if WorldClock else 1
	if saved_day > cur_day:
		state = AnimalState.BUTCHERED
		respawn_on_day = saved_day
		_apply_hidden_state(true)
	elif not managed_by_ecosystem and state == AnimalState.BUTCHERED:
		_respawn_animal()

func to_save_dict() -> Dictionary:
	return {
		"state": int(state),
		"hp": current_hp,
		"genetics_tier": genetics_tier,
		"meals_eaten": meals_eaten,
		"fed_today": fed_today,
		"has_reserve_day": has_reserve_day,
		"is_on_reserve_day": is_on_reserve_day,
		"mated_today": mated_today,
		"pending_offspring": pending_offspring,
		"offspring_genetics_tier": offspring_genetics_tier,
		"days_hungry": days_hungry,
		"respawn_on_day": respawn_on_day,
		"pos_x": global_position.x,
		"pos_y": global_position.y
	}

func from_save_dict(data: Dictionary) -> void:
	var st: int = int(data.get("state", int(AnimalState.GRAZE)))
	genetics_tier = clampi(int(data.get("genetics_tier", 1)), 1, 3)
	current_hp = float(data.get("hp", max_hp))
	meals_eaten = int(data.get("meals_eaten", 0))
	fed_today = bool(data.get("fed_today", false))
	has_reserve_day = bool(data.get("has_reserve_day", false))
	is_on_reserve_day = bool(data.get("is_on_reserve_day", false))
	mated_today = bool(data.get("mated_today", false))
	pending_offspring = bool(data.get("pending_offspring", false))
	offspring_genetics_tier = clampi(int(data.get("offspring_genetics_tier", 1)), 1, 3)
	days_hungry = int(data.get("days_hungry", 0))
	respawn_on_day = int(data.get("respawn_on_day", -1))

	if st == int(AnimalState.BUTCHERED):
		state = AnimalState.BUTCHERED
		_apply_hidden_state(true)
	elif st == int(AnimalState.CARCASS):
		if data.has("pos_x") and data.has("pos_y"):
			global_position = Vector2(float(data["pos_x"]), float(data["pos_y"]))
		_apply_hidden_state(false)
		_become_carcass()
	else:
		if state == AnimalState.IN_BURROW:
			_exit_burrow()
		state = AnimalState.GRAZE
		if data.has("pos_x") and data.has("pos_y"):
			global_position = Vector2(float(data["pos_x"]), float(data["pos_y"]))
		boar_aggressor = null
		boar_aggro_timer = 0.0
		boar_charge_windup = 0.0
		boar_charge_timer = 0.0
		pounce_timer = 0.0
		pounce_recovery_timer = 0.0
		flee_timer = 0.0
		eat_timer = 0.0
		mate_timer = 0.0
		is_raiding_farm = false
		hits_taken_count = 0
		food_target = null
		mate_target = null
		if not is_in_group("wild_animals"):
			add_to_group("wild_animals")
		if sprite:
			sprite.position = Vector2.ZERO
			sprite.rotation_degrees = 0.0
			sprite.modulate = Color(1.08, 1.04, 0.88) if genetics_tier >= 2 else Color.WHITE
		_apply_hidden_state(false)
