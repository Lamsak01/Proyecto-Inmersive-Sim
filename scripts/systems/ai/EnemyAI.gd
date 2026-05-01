extends Node
class_name EnemyAI

enum State { IDLE, ALERT, CHASE, ATTACK, SEARCH, RETURN, FLEE }

signal attack_triggered(damage_data: DamageData)
signal state_changed(new_state: State)
signal awareness_changed(level: float, is_alerted: bool)

@export var detection_range: float = 150.0
@export var attack_range: float = 20.0 # Reduced from 30.0 to fix "far away" attack feel
@export var chase_speed: float = 80.0
@export var flee_health_threshold: float = 0.0 # 0.0 = Never flee, 0.3 = Flee at 30% health
@export var attack_cooldown: float = 1.5
@export var attack_damage: float = 5.0
@export var awareness_fill_time: float = 2.0
@export var awareness_drain_time: float = 3.0
@export var search_duration: float = 5.0
@export var hearing_range: float = 60.0
@export var separation_weight: float = 40.0
@export var attack_windup_time: float = 0.4 # New telegraph delay

var current_state: State = State.IDLE
var target: Node2D = null
var attack_timer: float = 0.0
var awareness_level: float = 0.0 # 0.0 to 1.0
var spawn_position: Vector2
var last_known_position: Vector2
var search_timer: float = 0.0
var roam_target: Vector2
var is_winding_up: bool = false
var wind_up_timer: float = 0.0
var ray_directions: Array[Vector2] = []
var interest_map: Array[float] = []
var danger_map: Array[float] = []
var num_rays: int = 8
var look_ahead: float = 50.0

# Performance Optimization Caches
var vision_timer: float = 0.0
var avoidance_timer: float = 0.0
var cached_los_result: bool = false
var cached_avoidance_dir: Vector2 = Vector2.ZERO
var cached_los_target: Node2D = null
var cached_avoidance_input_dir: Vector2 = Vector2.ZERO

var ghost_instance: Sprite2D = null
var on_screen_notifier: VisibleOnScreenNotifier2D = null

# Cooldown para _broadcast_alert
var alert_cooldown_timer: float = 0.0
const ALERT_COOLDOWN_MAX: float = 3.0

# Timer de gracia tras recibir alerta por radio (evita caer a SEARCH por falta de LOS)
var broadcast_chase_timer: float = 0.0
const BROADCAST_CHASE_GRACE: float = 5.0

@onready var parent: CharacterBody2D = get_parent() as CharacterBody2D
@onready var nav_agent: NavigationAgent2D = get_node_or_null("../NavigationAgent2D")
@onready var detection_area: DetectionArea = get_node_or_null("../DetectionArea")

func _ready() -> void:
	if parent == null:
		push_error("EnemyAI must be child of CharacterBody2D")
	spawn_position = parent.global_position
	
	# Pre-calculate ray directions
	ray_directions.resize(num_rays)
	interest_map.resize(num_rays)
	danger_map.resize(num_rays)
	
	for i in range(num_rays):
		var angle = i * 2 * PI / num_rays
		ray_directions[i] = Vector2.RIGHT.rotated(angle)

	# Configure NavigationAgent
	if nav_agent:
		nav_agent.path_desired_distance = 16.0
		nav_agent.target_desired_distance = 16.0
		nav_agent.max_speed = chase_speed
	
	# Connect to parent's HealthComponent if available
	var health_comp = parent.get_node_or_null("HealthComponent")
	if health_comp:
		health_comp.health_changed.connect(_on_health_changed)

	# Optimization: Create Visibility Notifier to disable raycasts when off-screen
	on_screen_notifier = VisibleOnScreenNotifier2D.new()
	on_screen_notifier.rect = Rect2(-30, -30, 60, 60) # Cover common enemy sizes
	parent.add_child.call_deferred(on_screen_notifier)

var facing_direction: Vector2 = Vector2.RIGHT
var target_facing_direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	# Update timers
	if vision_timer > 0:
		vision_timer -= delta
	if avoidance_timer > 0:
		avoidance_timer -= delta
	if alert_cooldown_timer > 0:
		alert_cooldown_timer -= delta
	if broadcast_chase_timer > 0:
		broadcast_chase_timer -= delta
		
	# Update target facing direction based on movement
	if parent.velocity.length() > 0.1:
		target_facing_direction = parent.velocity.normalized()
	elif target != null and (current_state == State.CHASE or current_state == State.ATTACK or current_state == State.FLEE):
		# Turn towards target even if standing still
		var diff = (target.global_position - parent.global_position) if target else Vector2.ZERO
		if diff.length_squared() > 1.0:
			if current_state == State.FLEE:
				target_facing_direction = -diff.normalized()
			else:
				target_facing_direction = diff.normalized()

	# Smoothly rotate facing_direction towards target_facing_direction
	if target_facing_direction.length_squared() > 0.001:
		var current_angle = facing_direction.angle()
		var target_angle = target_facing_direction.angle()
		var new_angle = lerp_angle(current_angle, target_angle, 4.0 * delta)
		facing_direction = Vector2.RIGHT.rotated(new_angle)

	# Update attack cooldown
	if attack_timer > 0:
		attack_timer -= delta
	
	# State machine logic
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.ALERT:
			_process_alert(delta)
		State.CHASE:
			_process_chase()
		State.ATTACK:
			_process_attack(delta)
		State.SEARCH:
			_process_search(delta)
		State.RETURN:
			_process_return()
		State.FLEE:
			_process_flee()
	
	# Safety clamp
	if parent.velocity.length() > chase_speed:
		parent.velocity = parent.velocity.limit_length(chase_speed)

func _process_idle(_delta: float) -> void:
	parent.velocity = Vector2.ZERO
	
	var player = _get_global_player()
	if not player: return

	# 1. Visual Detection
	var distance = parent.global_position.distance_to(player.global_position)
	if distance <= detection_range:
		if _is_in_fov(player) and _has_line_of_sight(player):
			target = player
			_change_state(State.ALERT)
			return

	# 2. Auditory Detection (With Physical Raycast Occlusion)
	if not (player.has_method("is_stealthing") and player.is_stealthing()):
		# Integración del nuevo método de oclusión acústica
		var effective_hearing = calculate_auditory_radius(player.global_position)
		
		if distance <= effective_hearing:
			# Heard something! Smoothly snap to face it. Next frame visual detection will catch it.
			target_facing_direction = (player.global_position - parent.global_position).normalized()
			# We don't change state yet, we just look at them so the vision cone catches them

func _get_global_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")

func _is_in_fov(target_node: Node2D) -> bool:
	if not target_node: return false
	var dir_to_target = (target_node.global_position - parent.global_position).normalized()
	# Dot > 0.5 is 60 degrees either side (120 degrees total visual cone)
	# This fixes enemies seeing you when you are standing far to their sides/back
	return facing_direction.dot(dir_to_target) > 0.5

func _process_alert(delta: float) -> void:
	parent.velocity = Vector2.ZERO
	if not target:
		_change_state(State.IDLE)
		return
		
	var distance = parent.global_position.distance_to(target.global_position)
	var has_los = _has_line_of_sight(target) and distance <= detection_range and _is_in_fov(target)
	
	# If player visible within range AND FOV, increase awareness
	if has_los:
		awareness_level += delta / awareness_fill_time
		last_known_position = target.global_position # Update last known pos while we see them
	else:
		# Drain awareness if hidden, out of range, or out of FOV
		awareness_level -= delta / awareness_drain_time
	
	# Clamp and signal
	awareness_level = clamp(awareness_level, 0.0, 1.0)
	awareness_changed.emit(awareness_level, true)
	
	# Check thresholds
	if awareness_level >= 1.0:
		_change_state(State.CHASE)
	elif awareness_level <= 0.0:
		# Lost completely before chase, but they were disturbed. Investigate last spot
		if last_known_position != Vector2.ZERO:
			_spawn_ghost(last_known_position, target)
			roam_target = last_known_position
			target = null
			_change_state(State.SEARCH)
		else:
			target = null
			_change_state(State.IDLE)


func _process_chase() -> void:
	if not target:
		_change_state(State.IDLE)
		return
	
	var distance = parent.global_position.distance_to(target.global_position)
	
	# Mantener registro de quién tiene LOS activo al jugador
	var los_ok = broadcast_chase_timer > 0 or _has_line_of_sight(target)
	
	if los_ok and distance <= detection_range * 1.5:
		# Tenemos LOS real: actualizar posición conocida y registrarse en el grupo global
		last_known_position = target.global_position
		if not parent.is_in_group("has_los_to_player"):
			parent.add_to_group("has_los_to_player")
	else:
		# Perdimos LOS o el jugador está demasiado lejos
		parent.remove_from_group("has_los_to_player")
		
		var last_pos = last_known_position if last_known_position != Vector2.ZERO else target.global_position
		roam_target = last_pos
		
		# ¿Somos el último enemigo con LOS? Solo entonces generamos el fantasma compartido
		var still_tracking = get_tree().get_nodes_in_group("has_los_to_player")
		if still_tracking.is_empty() and distance <= detection_range * 2.5:
			# Generar fantasma único en la última posición conocida
			_spawn_ghost(last_pos, target)
			
			# Notificar a todos los aliados en CHASE o SEARCH con la misma posición
			for ally in get_tree().get_nodes_in_group("enemies"):
				if ally == parent: continue
				var ally_ai = ally.get_node_or_null("EnemyAI")
				if ally_ai and ally_ai is EnemyAI:
					if ally_ai.current_state in [State.CHASE, State.SEARCH]:
						ally_ai.last_known_position = last_pos
						ally_ai.roam_target = last_pos
						# Si estaban persiguiendo con un blanco inválido, mandamos a SEARCH
						if ally_ai.current_state == State.CHASE:
							ally_ai.target = null
							ally_ai.broadcast_chase_timer = 0.0
							ally_ai._change_state(State.SEARCH)
		
		target = null
		_change_state(State.SEARCH)
		return
	
	# Check if in attack range
	if distance <= attack_range:
		# Only switch to attack if we are actually facing the target
		var dir_to_target = (target.global_position - parent.global_position).normalized()
		var is_facing = facing_direction.dot(dir_to_target) > 0.5
		
		if is_facing:
			_change_state(State.ATTACK)
			return
		# If not facing, continue chasing (which will rotate us via movement)
	
	_set_movement_target(target.global_position)
	
	var next_path_pos = nav_agent.get_next_path_position()
	var desired_direction = (next_path_pos - parent.global_position).normalized()
	
	# FALLBACK: If navigation is broken/missing (returns current pos), move directly to target
	if desired_direction == Vector2.ZERO:
		desired_direction = (target.global_position - parent.global_position).normalized()
	
	var final_direction = _get_avoidance_direction(desired_direction)
	var separation = _calculate_separation_vector()
	parent.velocity = final_direction * chase_speed + separation * separation_weight

	# Update last known position continuously while chasing
	last_known_position = target.global_position

func _process_attack(delta: float) -> void:
	if not target:
		is_winding_up = false
		_change_state(State.IDLE)
		return
	
	var distance = parent.global_position.distance_to(target.global_position)
	
	# Check if target moved out of attack range
	if distance > attack_range * 1.5 and not is_winding_up:
		_change_state(State.CHASE)
		return
	elif distance > attack_range * 2.5 and is_winding_up:
		# Player escaped the attack entirely during windup
		is_winding_up = false
		_change_state(State.CHASE)
		return
	
	# Stop moving
	parent.velocity = Vector2.ZERO
	
	# Try to attack
	if is_winding_up:
		wind_up_timer -= delta
		if wind_up_timer <= 0:
			is_winding_up = false
			_perform_attack()
			attack_timer = attack_cooldown
	else:
		if attack_timer <= 0:
			is_winding_up = true
			wind_up_timer = attack_windup_time
			if parent.has_method("play_attack_anticipation"):
				parent.play_attack_anticipation(attack_windup_time)

func _perform_attack() -> void:
	var damage = DamageData.new()
	damage.amount = attack_damage
	damage.type = CombatConstants.DamageType.CUT
	damage.bleed_chance = 0.0
	
	attack_triggered.emit(damage)

func _process_search(delta: float) -> void:
	# 1. Visual Detection Check
	var player = _get_global_player()
	if player:
		var distance = parent.global_position.distance_to(player.global_position)
		if distance <= detection_range and _is_in_fov(player) and _has_line_of_sight(player):
			target = player
			_clear_ghost()
			# Ya estaba buscando; volver a ver al jugador = persecución inmediata
			awareness_level = 1.0
			_change_state(State.CHASE)
			return

	# 2. Auditory Detection Check (With Physical Raycast Occlusion)
	var distance_to_player = parent.global_position.distance_to(player.global_position) if player else INF
	if player and not (player.has_method("is_stealthing") and player.is_stealthing()):
		# Integración del nuevo método de oclusión acústica
		var effective_hearing = calculate_auditory_radius(player.global_position)
		
		if distance_to_player <= effective_hearing:
			target_facing_direction = (player.global_position - parent.global_position).normalized()
			roam_target = player.global_position # Go investigate noise
			_clear_ghost() # Noise overrides ghost

	# Mover hacia el punto de búsqueda actual
	var arrived = nav_agent.is_navigation_finished() or \
				  parent.global_position.distance_to(roam_target) < 24.0
	
	if arrived:
		# Elegir el siguiente punto de patrulla alrededor de la última posición conocida
		# Generamos puntos en un abanico para cubrir el área (N, NE, E, SE, etc.)
		var search_radius: float = 80.0
		var points_count: int = 6
		var angle_step = TAU / points_count
		
		# Usar el search_timer como índice de qué punto visitar
		var point_index = int((search_duration - search_timer) / (search_duration / points_count)) % points_count
		var angle = point_index * angle_step + PI / 4.0  # Desfase de 45° para que no sea simétrico
		var offset = Vector2(cos(angle), sin(angle)) * search_radius
		
		roam_target = last_known_position + offset
		target_facing_direction = (roam_target - parent.global_position).normalized()
	else:
		_set_movement_target(roam_target)
		var next_path_pos = nav_agent.get_next_path_position()
		var dir = (next_path_pos - parent.global_position).normalized()
		if dir == Vector2.ZERO:
			dir = (roam_target - parent.global_position).normalized()
		var final_dir = _get_avoidance_direction(dir)
		parent.velocity = final_dir * (chase_speed * 0.5)
	
	# Update timer
	search_timer -= delta
	if search_timer <= 0:
		_clear_ghost()
		_change_state(State.RETURN)
		return

func _process_return() -> void:
	# 1. Visual Detection Check
	var player = _get_global_player()
	if player:
		var distance = parent.global_position.distance_to(player.global_position)
		if distance <= detection_range and _is_in_fov(player) and _has_line_of_sight(player):
			target = player
			_change_state(State.ALERT) 
			awareness_level = 0.5
			return

	# 2. Auditory Detection Check (With Physical Raycast Occlusion)
	var distance_to_player = parent.global_position.distance_to(player.global_position) if player else INF
	if player and not (player.has_method("is_stealthing") and player.is_stealthing()):
		# Integración del nuevo método de oclusión acústica
		var effective_hearing = calculate_auditory_radius(player.global_position)
		
		if distance_to_player <= effective_hearing:
			target_facing_direction = (player.global_position - parent.global_position).normalized()
			# We hear them! Turn around and let vision pick them up next frame
			return

	if current_state == State.RETURN: # Optimization: Only check if in return state
		_set_movement_target(spawn_position)
	
	if nav_agent.is_navigation_finished():
		print("Return finished. Snapping to spawn.")
		parent.velocity = Vector2.ZERO
		parent.global_position = spawn_position # Snap to exact pos
		_change_state(State.IDLE)
		return
	
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = (next_path_pos - parent.global_position).normalized()
	
	# Fallback: If NavAgent returns current pos (stuck?), move direct to spawn
	if dir == Vector2.ZERO and parent.global_position.distance_to(spawn_position) > nav_agent.target_desired_distance:
		dir = (spawn_position - parent.global_position).normalized()
	
	var final_dir = _get_avoidance_direction(dir)
	
	# Double Fallback: If avoidance returns zero (trapped?), force movement
	if final_dir == Vector2.ZERO:
		final_dir = dir
		
	parent.velocity = final_dir * (chase_speed * 0.5) # Return slower

func _process_flee() -> void:
	# If no target, try to find one to flee FROM
	if not target:
		target = _find_player_in_range(detection_range * 1.5)
	
	if not target:
		# If still no target, we are safe? Return to IDLE or SEARCH?
		# Let's just keep running blindly or return if nothing near.
		_change_state(State.RETURN)
		return
		
	# Move AWAY from target
	var dir_away = (parent.global_position - target.global_position).normalized()
	
	# Use navigation to find a path away? 
	# For simplicity: Set target position far away in the opposite direction
	var flee_dest = parent.global_position + (dir_away * 300.0)
	
	_set_movement_target(flee_dest)
	
	var next_path_pos = nav_agent.get_next_path_position()
	var desired_direction = (next_path_pos - parent.global_position).normalized()
	
	# If nav fails, just run straight away
	if desired_direction == Vector2.ZERO:
		desired_direction = dir_away
		
	var final_direction = _get_avoidance_direction(desired_direction)
	# Flee fast!
	parent.velocity = final_direction * (chase_speed * 1.2) 

func _on_health_changed(current: float, max_health: float) -> void:
	if flee_health_threshold > 0.0:
		var percent = current / max_health
		if percent <= flee_health_threshold:
			# Trigger Flee State
			if current_state != State.FLEE and current_state != State.IDLE: # Only flee if active? Or always?
				# Find player to flee from if we don't have one
				if not target:
					target = _find_player_in_range(detection_range)
				_change_state(State.FLEE)

func _find_player_in_range(max_range: float) -> Node2D:
	if not detection_area:
		return null
	
	# The DetectionArea physically handles overlaps based on its collision shape (radius 30)
	# So if `get_closest_target()` returns anything, it means they are physically touching the hearing zone!
	var closest = detection_area.get_closest_target(parent.global_position)
	if closest:
		# Adding leniency (max_range overrides or extends it if needed, but area is primary)
		if max_range <= 0.0 or parent.global_position.distance_to(closest.global_position) <= max_range * 1.5:
			return closest
	
	return null

func _calculate_separation_vector() -> Vector2:
	"""Soft flocking separation: repels this enemy from nearby allies."""
	const SEPARATION_RADIUS: float = 50.0
	var separation = Vector2.ZERO
	
	for ally in get_tree().get_nodes_in_group("enemies"):
		if ally == parent: continue
		
		var diff = parent.global_position - ally.global_position
		var dist = diff.length()
		
		if dist < SEPARATION_RADIUS and dist > 0.001:
			# Más separación cuanto más cerca (inverso proporcional a la distancia)
			separation += diff.normalized() / dist
			
	if separation.length_squared() > 0.001:
		return separation.normalized()
	return Vector2.ZERO

func _has_line_of_sight(target_node: Node2D) -> bool:
	"""Check if there's a clear line of sight to target (no walls). Throttled for performance."""
	if not target_node:
		return false
	
	if target_node == cached_los_target and vision_timer > 0:
		return cached_los_result
		
	cached_los_target = target_node
	vision_timer = 0.1 # Throttle: Check 10 times a second max
	
	var space_state = parent.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		parent.global_position,
		target_node.global_position
	)
	
	# Exclude self and target from collision
	query.exclude = [parent.get_rid(), target_node.get_rid()]
	
	# Only check for walls/obstacles (layer 1 typically)
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	
	# If no collision, we have clear LOS
	cached_los_result = result.is_empty()
	return cached_los_result

func calculate_auditory_radius(sound_origin: Vector2) -> float:
	"""
	Calcula el radio efectivo de audición evaluando si existe oclusión directa.
	Se usa un raycast exclusivo contra la capa de entorno.
	"""
	var query = PhysicsRayQueryParameters2D.create(parent.global_position, sound_origin)
	
	# Excluir el propio cuerpo del enemigo por seguridad
	query.exclude = [parent.get_rid()]
	
	# Asignar estrictamente la máscara para la capa de entorno estático (paredes)
	# Layer 1 es usualmente la arquitectura/mundo solido
	query.collision_mask = 1 
	
	var space_state = parent.get_world_2d().direct_space_state
	var result = space_state.intersect_ray(query)
	
	# Si hubo impacto con una pared, el entorno bloquea y ahoga el sonido
	if not result.is_empty():
		return 20.0 # Radio atenuado gravemente
		
	# Si no hubo impacto, hay línea de audición limpia
	return hearing_range # Máximo alcance normal (e.g. 60.0)

func _get_avoidance_direction(desired_dir: Vector2) -> Vector2:
	"""Context Steering: 8 rays, Interest - Danger. Throttled for performance."""
	
	if is_instance_valid(on_screen_notifier) and not on_screen_notifier.is_on_screen():
		# Optimization: If off-screen, skip context steering completely and just move directly
		return desired_dir

	if desired_dir == cached_avoidance_input_dir and avoidance_timer > 0:
		return cached_avoidance_dir
		
	cached_avoidance_input_dir = desired_dir
	avoidance_timer = 0.1 # Throttle avoidance checks
	
	# 1. Reset maps
	for i in range(num_rays):
		interest_map[i] = 0.0
		danger_map[i] = 0.0
	
	# 2. Populate Interest Map (Dot product with desired direction)
	for i in range(num_rays):
		var d = ray_directions[i].dot(desired_dir)
		interest_map[i] = max(0, d)
	
	# 3. Populate Danger Map (Raycasts)
	var space_state = parent.get_world_2d().direct_space_state
	
	for i in range(num_rays):
		var query = PhysicsRayQueryParameters2D.create(
			parent.global_position,
			parent.global_position + ray_directions[i] * look_ahead
		)
		query.exclude = [parent.get_rid()]
		if target:
			query.exclude.append(target.get_rid())
		query.collision_mask = 1 # Walls
		
		var result = space_state.intersect_ray(query)
		if not result.is_empty():
			danger_map[i] = 1.0
			# Spill danger to neighbors (optional smoothing)
			var prev = (i - 1 + num_rays) % num_rays
			var next = (i + 1) % num_rays
			danger_map[prev] = max(danger_map[prev], 0.5)
			danger_map[next] = max(danger_map[next], 0.5)

	# 4. Choose Best Direction
	var chosen_dir = Vector2.ZERO
	
	for i in range(num_rays):
		var value = interest_map[i] - danger_map[i]
		if value > 0:
			chosen_dir += ray_directions[i] * value
			
	cached_avoidance_dir = chosen_dir.normalized()
	return cached_avoidance_dir

func _change_state(new_state: State) -> void:
	if current_state != new_state:
		print("AI State: ", State.keys()[current_state], " -> ", State.keys()[new_state])
		var prev_state = current_state
		current_state = new_state
		is_winding_up = false # Cancel any windup if state changes
		state_changed.emit(new_state)
		
		# Reset awareness when entering/leaving relevant states
		if new_state == State.IDLE:
			awareness_level = 0.0
			awareness_changed.emit(0.0, false)
			parent.remove_from_group("has_los_to_player")
		elif new_state == State.CHASE or new_state == State.ATTACK:
			awareness_level = 1.0
			awareness_changed.emit(1.0, true)
			
			if new_state == State.CHASE and prev_state != State.ATTACK:
				_broadcast_alert()
				
		elif new_state == State.SEARCH:
			parent.remove_from_group("has_los_to_player")
			search_timer = search_duration
			last_known_position = parent.global_position if last_known_position == Vector2.ZERO else last_known_position
			roam_target = last_known_position

func _broadcast_alert() -> void:
	if alert_cooldown_timer > 0:
		return
		
	alert_cooldown_timer = ALERT_COOLDOWN_MAX
	
	var alert_radius: float = 300.0
	var allies = get_tree().get_nodes_in_group("enemies")
	
	for ally in allies:
		if ally == parent: continue
		
		# Skip stunned/dead allies (basic check, assume if physics is off they are dead/stunned)
		if not ally.is_physics_processing(): continue
		
		var distance = parent.global_position.distance_to(ally.global_position)
		if distance > alert_radius: continue
		
		var ally_ai = ally.get_node_or_null("EnemyAI")
		if ally_ai and ally_ai is EnemyAI:
			# Evitar thrashing o interrupción de rutinas críticas
			if ally_ai.current_state in [State.CHASE, State.ATTACK, State.FLEE]:
				continue
			
			# Si el aliado también acaba de gritar o tiene bloqueo, no lo forcemos en bucle
			if ally_ai.alert_cooldown_timer > 0:
				continue
				
			# Check occlusion from shouting enemy to ally
			var space_state = parent.get_world_2d().direct_space_state
			var query = PhysicsRayQueryParameters2D.create(parent.global_position, ally.global_position)
			query.collision_mask = 1 # Environment layer
			query.exclude = [parent.get_rid(), ally.get_rid()]
			
			var result = space_state.intersect_ray(query)
			var effective_range = alert_radius if result.is_empty() else 100.0 # Occluded shout is muffled
			
			if distance <= effective_range or ally_ai._has_line_of_sight(parent):
				ally_ai.target_facing_direction = (parent.global_position - ally.global_position).normalized()
				if target:
					ally_ai.target = target
					ally_ai.last_known_position = target.global_position
					ally_ai.roam_target = target.global_position
					ally_ai.awareness_level = 1.0
					ally_ai.broadcast_chase_timer = BROADCAST_CHASE_GRACE # <-- gracia de persecución
					ally_ai._change_state(State.CHASE)
				else:
					ally_ai.last_known_position = parent.global_position
					ally_ai.roam_target = parent.global_position
					ally_ai.awareness_level = 0.5
					ally_ai._change_state(State.SEARCH)


func _spawn_ghost(pos: Vector2, target_node: Node2D) -> void:
	_clear_ghost() # Only one ghost at a time
	if not target_node: return
	
	# Try to find the visual representation of the player
	var anim_node = target_node.get_node_or_null("Animations")
	var texture = null
	var hframes = 1
	var vframes = 1
	var frame = 0
	
	if anim_node is AnimatedSprite2D:
		texture = anim_node.sprite_frames.get_frame_texture(anim_node.animation, anim_node.frame)
	elif anim_node is Sprite2D:
		texture = anim_node.texture
		hframes = anim_node.hframes
		vframes = anim_node.vframes
		frame = anim_node.frame
		
	if texture:
		ghost_instance = Sprite2D.new()
		ghost_instance.texture = texture
		if anim_node is Sprite2D:
			ghost_instance.hframes = hframes
			ghost_instance.vframes = vframes
			ghost_instance.frame = frame
		
		ghost_instance.z_index = 100 # Ensure it draws above background
		ghost_instance.scale = target_node.scale # Match target scale
		ghost_instance.global_position = pos
		
		if anim_node is AnimatedSprite2D or anim_node is Sprite2D:
			ghost_instance.flip_h = anim_node.flip_h
			ghost_instance.flip_v = anim_node.flip_v
		
		# Apply Ghost Outline Shader
		var shader = load("res://shaders/ghost_outline.gdshader")
		if shader:
			var mat = ShaderMaterial.new()
			mat.shader = shader
			mat.set_shader_parameter("line_color", Color(0.5, 0.8, 1.0, 0.8)) # Blueish outline
			mat.set_shader_parameter("line_thickness", 2.0)
			ghost_instance.material = mat
		else:
			# Fallback if shader fails
			ghost_instance.modulate = Color(0.5, 0.8, 1.0, 0.5)
		
		# Add to the world
		get_tree().current_scene.add_child(ghost_instance)
		
		# Auto-destroy after 3 seconds
		get_tree().create_timer(3.0).timeout.connect(_clear_ghost)

func _clear_ghost() -> void:
	if is_instance_valid(ghost_instance):
		ghost_instance.queue_free()
	ghost_instance = null

func get_move_direction() -> Vector2:
	"""Returns the direction the enemy should move this frame"""
	if parent.velocity != Vector2.ZERO:
		return parent.velocity.normalized()
	return Vector2.ZERO

func _set_movement_target(target_pos: Vector2) -> void:
	if nav_agent:
		nav_agent.target_position = target_pos

func notify_damage(attacker: Node2D) -> void:
	"""Called when the enemy takes damage. Instantly aggro."""
	if not attacker: return
	
	target = attacker
	awareness_level = 1.0
	awareness_changed.emit(awareness_level, true)
	
	if current_state != State.CHASE and current_state != State.ATTACK and current_state != State.FLEE:
		_change_state(State.CHASE)
