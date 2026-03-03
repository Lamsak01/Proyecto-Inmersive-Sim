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
@export var search_duration: float = 2.0

var current_state: State = State.IDLE
var target: Node2D = null
var attack_timer: float = 0.0
var awareness_level: float = 0.0 # 0.0 to 1.0
var spawn_position: Vector2
var last_known_position: Vector2
var search_timer: float = 0.0
var roam_target: Vector2
var ray_directions: Array[Vector2] = []
var interest_map: Array[float] = []
var danger_map: Array[float] = []
var num_rays: int = 8
var look_ahead: float = 50.0

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

var facing_direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	# Update facing direction
	if parent.velocity.length() > 0.1:
		facing_direction = parent.velocity.normalized()
	elif target != null and (current_state == State.CHASE or current_state == State.ATTACK or current_state == State.FLEE):
		# Turn towards target even if standing still (essential for attacking)
		# In FLEE, we want to look away? Handled by movement naturally.
		var diff = (target.global_position - parent.global_position) if target else Vector2.ZERO
		if diff.length_squared() > 1.0: # Prevent jitter when extremely close
			if current_state == State.FLEE:
				facing_direction = -diff.normalized() # Face away when fleeing
			else:
				facing_direction = diff.normalized()

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
			_process_attack()
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
	# Look for player
	var player = _find_player_in_range(detection_range)
	if player:
		# Check FOV (unless very close)
		var distance = parent.global_position.distance_to(player.global_position)
		var in_fov = _is_in_fov(player)
		
		# Hearing Range (e.g. 50.0) -> Detects 360
		# If stealthing, hearing is disabled (Silent)
		var can_hear = distance < 50.0
		if player.has_method("is_stealthing") and player.is_stealthing():
			can_hear = false
			
		if (in_fov or can_hear) and _has_line_of_sight(player):
			target = player
			_change_state(State.ALERT)

func _is_in_fov(target_node: Node2D) -> bool:
	if not target_node: return false
	var dir_to_target = (target_node.global_position - parent.global_position).normalized()
	# Dot > 0.5 is 60 degrees either side (120 total)
	# Dot > 0 is 90 degrees either side (180 total)
	return facing_direction.dot(dir_to_target) > 0.0 # Wide 180 FOV for now based on user request "forward" cone

func _process_alert(delta: float) -> void:
	parent.velocity = Vector2.ZERO
	if not target:
		_change_state(State.IDLE)
		return
		
	var has_los = _has_line_of_sight(target)
	var distance = parent.global_position.distance_to(target.global_position)
	
	# If player visible within range, increase awareness
	if has_los and distance <= detection_range:
		awareness_level += delta / awareness_fill_time
	else:
		# Drain awareness if hidden or out of range
		awareness_level -= delta / awareness_drain_time
	
	# Clamp and signal
	awareness_level = clamp(awareness_level, 0.0, 1.0)
	awareness_changed.emit(awareness_level, true)
	
	# Check thresholds
	if awareness_level >= 1.0:
		_change_state(State.CHASE)
	elif awareness_level <= 0.0:
		target = null
		_change_state(State.IDLE)


func _process_chase() -> void:
	if not target:
		_change_state(State.IDLE)
		return
	
	var distance = parent.global_position.distance_to(target.global_position)
	
	# Check if lost line of sight
	if not _has_line_of_sight(target):

		target = null
		# Set initial search target to last known position
		roam_target = last_known_position
		_change_state(State.SEARCH)
		return
	
	# Check if lost target
	if distance > detection_range * 1.2: # 20% hysteresis
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
	parent.velocity = final_direction * chase_speed

	# Update last known position continuously while chasing
	last_known_position = target.global_position

func _process_attack() -> void:
	if not target:
		_change_state(State.IDLE)
		return
	
	var distance = parent.global_position.distance_to(target.global_position)
	
	# Check if target moved out of attack range
	if distance > attack_range * 1.3: # Hysteresis
		_change_state(State.CHASE)
		return
	
	# Stop moving
	parent.velocity = Vector2.ZERO
	
	# Try to attack
	if attack_timer <= 0:
		_perform_attack()
		attack_timer = attack_cooldown

func _perform_attack() -> void:
	var damage = DamageData.new()
	damage.amount = attack_damage
	damage.type = CombatConstants.DamageType.CUT
	damage.bleed_chance = 0.0
	
	attack_triggered.emit(damage)

func _process_search(delta: float) -> void:
	# Check if player reappears
	var player = _find_player_in_range(detection_range)
	if player:
		# Same FOV/Hearing check as Idle
		var in_fov = _is_in_fov(player)
		var distance = parent.global_position.distance_to(player.global_position)
		var can_hear = distance < 50.0
		if player.has_method("is_stealthing") and player.is_stealthing():
			can_hear = false
			
		if (in_fov or can_hear) and _has_line_of_sight(player):
			target = player
			# 1 Second Delay before Chase (Awareness starts at 0.5, takes 1s to reach 1.0)
			_change_state(State.ALERT)
			awareness_level = 0.5 
			return

	# Move towards roam target (last known or random point nearby)
	if nav_agent.is_navigation_finished():
		# Reached point, wait or pick new point
		parent.velocity = Vector2.ZERO
	else:
		_set_movement_target(roam_target) # Fixed: Make sure target is set before moving
		var next_path_pos = nav_agent.get_next_path_position()
		var dir = (next_path_pos - parent.global_position).normalized()
		var final_dir = _get_avoidance_direction(dir)
		parent.velocity = final_dir * (chase_speed * 0.5) # Search slower
	
	# Update timer
	search_timer -= delta
	if search_timer <= 0:
		_change_state(State.RETURN)
		return
		
	# Occasionally pick new random point near last known position
	if parent.velocity == Vector2.ZERO and randf() < 0.02:
		var random_offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		roam_target = last_known_position + random_offset

func _process_return() -> void:
	# Check if player reappears
	var player = _find_player_in_range(detection_range)
	if player:
		var in_fov = _is_in_fov(player)
		var distance = parent.global_position.distance_to(player.global_position)
		var can_hear = distance < 50.0
		if player.has_method("is_stealthing") and player.is_stealthing():
			can_hear = false

		if (in_fov or can_hear) and _has_line_of_sight(player):
			target = player
			# 1 Second Delay
			_change_state(State.ALERT) 
			awareness_level = 0.5
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
		# Fallback if detection area not assigned, wait, we MUST assign it
		return null
	
	var closest = detection_area.get_closest_target(parent.global_position)
	if closest and parent.global_position.distance_to(closest.global_position) <= max_range:
		return closest
	
	return null

func _has_line_of_sight(target_node: Node2D) -> bool:
	"""Check if there's a clear line of sight to target (no walls)"""
	if not target_node:
		return false
	
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
	return result.is_empty()

func _get_avoidance_direction(desired_dir: Vector2) -> Vector2:
	"""Context Steering: 8 rays, Interest - Danger"""
	
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
			
	return chosen_dir.normalized()

func _change_state(new_state: State) -> void:
	if current_state != new_state:
		print("AI State: ", State.keys()[current_state], " -> ", State.keys()[new_state])
		current_state = new_state
		state_changed.emit(new_state)
		
		# Reset awareness when entering/leaving relevant states
		if new_state == State.IDLE:
			awareness_level = 0.0
			awareness_changed.emit(0.0, false)
		elif new_state == State.CHASE or new_state == State.ATTACK:
			awareness_level = 1.0
			awareness_changed.emit(1.0, true)
		elif new_state == State.SEARCH:
			search_timer = search_duration
			last_known_position = parent.global_position if last_known_position == Vector2.ZERO else last_known_position
			roam_target = last_known_position

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
	
	if current_state != State.CHASE and current_state != State.ATTACK:
		_change_state(State.CHASE)
