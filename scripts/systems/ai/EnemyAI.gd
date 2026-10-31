extends Node
class_name EnemyAI

enum State { IDLE, ALERT, CHASE, ATTACK, SEARCH, RETURN, FLEE }

signal attack_triggered(damage_data: DamageData)
signal state_changed(new_state: State)
signal awareness_changed(level: float, is_alerted: bool)

const GHOST_SHADER = preload("res://shaders/ghost_outline.gdshader")

@export var detection_range: float = 150.0
@export var attack_range: float = 20.0
@export var chase_speed: float = 80.0
@export var flee_health_threshold: float = 0.0
@export var attack_cooldown: float = 1.5
@export var attack_damage: float = 5.0
@export var awareness_fill_time: float = 2.0
@export var awareness_drain_time: float = 3.0
@export var search_duration: float = 5.0
@export var hearing_range: float = 60.0
@export var separation_weight: float = 40.0
@export var attack_windup_time: float = 0.4

var current_state: State = State.IDLE
var target: Node2D = null
var attack_timer: float = 0.0
var awareness_level: float = 0.0
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
var _cached_player: Node2D = null
var vision_timer: float = 0.0
var hearing_timer: float = 0.0
var avoidance_timer: float = 0.0
var nav_timer: float = 0.0
var cached_los_result: bool = false
var cached_effective_hearing: float = 0.0
var cached_avoidance_dir: Vector2 = Vector2.ZERO
var cached_los_target: Node2D = null
var cached_avoidance_input_dir: Vector2 = Vector2.ZERO
var _last_nav_target: Vector2 = Vector2.INF

var ghost_instance: Sprite2D = null
var on_screen_notifier: VisibleOnScreenNotifier2D = null

# Cooldown para _broadcast_alert
var alert_cooldown_timer: float = 0.0
const ALERT_COOLDOWN_MAX: float = 3.0

# Timer de gracia tras recibir alerta por radio
var broadcast_chase_timer: float = 0.0
const BROADCAST_CHASE_GRACE: float = 5.0

@onready var parent: CharacterBody2D = get_parent() as CharacterBody2D
@onready var nav_agent: NavigationAgent2D = get_node_or_null("../NavigationAgent2D")
@onready var detection_area: DetectionArea = get_node_or_null("../DetectionArea")

var facing_direction: Vector2 = Vector2.RIGHT
var target_facing_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	if parent == null:
		push_error("EnemyAI must be child of CharacterBody2D")
		return
	spawn_position = parent.global_position
	ray_directions.resize(num_rays)
	interest_map.resize(num_rays)
	danger_map.resize(num_rays)
	for i in range(num_rays):
		ray_directions[i] = Vector2.RIGHT.rotated(i * TAU / num_rays)
	if nav_agent:
		nav_agent.path_desired_distance = 16.0
		nav_agent.target_desired_distance = 16.0
		nav_agent.max_speed = chase_speed
	var health_comp = parent.get_node_or_null("HealthComponent")
	if health_comp:
		health_comp.health_changed.connect(_on_health_changed)
	on_screen_notifier = VisibleOnScreenNotifier2D.new()
	on_screen_notifier.rect = Rect2(-30, -30, 60, 60)
	parent.add_child.call_deferred(on_screen_notifier)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or (WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen()):
		if parent: parent.velocity = Vector2.ZERO
		return
	vision_timer = maxf(0.0, vision_timer - delta)
	hearing_timer = maxf(0.0, hearing_timer - delta)
	avoidance_timer = maxf(0.0, avoidance_timer - delta)
	nav_timer = maxf(0.0, nav_timer - delta)
	alert_cooldown_timer = maxf(0.0, alert_cooldown_timer - delta)
	broadcast_chase_timer = maxf(0.0, broadcast_chase_timer - delta)
	attack_timer = maxf(0.0, attack_timer - delta)
	if parent.velocity.length_squared() > 0.01:
		target_facing_direction = parent.velocity.normalized()
	elif target != null and current_state in [State.CHASE, State.ATTACK, State.FLEE]:
		var diff := target.global_position - parent.global_position
		if diff.length_squared() > 1.0:
			target_facing_direction = -diff.normalized() if current_state == State.FLEE else diff.normalized()

	if target_facing_direction.length_squared() > 0.001:
		facing_direction = Vector2.RIGHT.rotated(lerp_angle(facing_direction.angle(), target_facing_direction.angle(), 4.0 * delta))
	match current_state:
		State.IDLE: _process_idle(delta)
		State.ALERT: _process_alert(delta)
		State.CHASE: _process_chase()
		State.ATTACK: _process_attack(delta)
		State.SEARCH: _process_search(delta)
		State.RETURN: _process_return()
		State.FLEE: _process_flee()
	if parent.velocity.length_squared() > chase_speed * chase_speed:
		parent.velocity = parent.velocity.limit_length(chase_speed)

func get_effective_detection_range() -> float:
	var eff: float = detection_range * (WorldClock.get_vision_multiplier() if WorldClock else 1.0)
	var player := _get_global_player()
	if player and player.has_method("is_stealthing") and player.is_stealthing():
		eff *= 0.5 * (float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0)
	return eff

func _check_player_detection(min_noise_for_search: float) -> Node2D:
	var player := _get_global_player()
	if not player: return null
	var eff_range := get_effective_detection_range()
	var distance_sq := parent.global_position.distance_squared_to(player.global_position)
	if distance_sq <= eff_range * eff_range and _is_in_fov(player) and _has_line_of_sight(player):
		return player
	var noise_mult: float = player.get_noise_multiplier() if player.has_method("get_noise_multiplier") else (0.0 if (player.has_method("is_stealthing") and player.is_stealthing()) else 1.0)
	if noise_mult > 0.0 and distance_sq <= pow(hearing_range * noise_mult, 2):
		if distance_sq <= pow(calculate_auditory_radius(player.global_position) * noise_mult, 2):
			target_facing_direction = (player.global_position - parent.global_position).normalized()
			if noise_mult > min_noise_for_search:
				on_noise_heard(player.global_position)
	return null

func _process_idle(_delta: float) -> void:
	parent.velocity = Vector2.ZERO
	var detected := _check_player_detection(1.2)
	if detected:
		target = detected
		_change_state(State.ALERT)

func _get_global_player() -> Node2D:
	if not is_instance_valid(_cached_player):
		_cached_player = get_tree().get_first_node_in_group("player")
	return _cached_player

func _is_in_fov(target_node: Node2D) -> bool:
	return target_node != null and facing_direction.dot((target_node.global_position - parent.global_position).normalized()) > 0.5

func _process_alert(delta: float) -> void:
	parent.velocity = Vector2.ZERO
	if not target:
		_change_state(State.IDLE)
		return
	var eff_range := get_effective_detection_range()
	var has_los := parent.global_position.distance_squared_to(target.global_position) <= eff_range * eff_range and _is_in_fov(target) and _has_line_of_sight(target)
	if has_los:
		awareness_level += delta / awareness_fill_time
		last_known_position = target.global_position
	else:
		awareness_level -= delta / awareness_drain_time
	awareness_level = clamp(awareness_level, 0.0, 1.0)
	awareness_changed.emit(awareness_level, true)
	if awareness_level >= 1.0:
		_change_state(State.CHASE)
	elif awareness_level <= 0.0:
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
	
	var distance_sq = parent.global_position.distance_squared_to(target.global_position)
	var los_ok = broadcast_chase_timer > 0.0 or _has_line_of_sight(target)
	
	if los_ok and distance_sq <= detection_range * detection_range * 2.25:
		last_known_position = target.global_position
		if not parent.is_in_group("has_los_to_player"):
			parent.add_to_group("has_los_to_player")
	else:
		parent.remove_from_group("has_los_to_player")
		
		var last_pos = last_known_position if last_known_position != Vector2.ZERO else target.global_position
		roam_target = last_pos
		
		var still_tracking = get_tree().get_nodes_in_group("has_los_to_player")
		if still_tracking.is_empty() and distance_sq <= detection_range * detection_range * 6.25:
			_spawn_ghost(last_pos, target)
			
			for ally in get_tree().get_nodes_in_group("enemies"):
				if ally == parent: continue
				var dist_sq = parent.global_position.distance_squared_to(ally.global_position)
				if dist_sq <= 360000.0:
					var ai = ally.get_node_or_null("EnemyAI")
					if ai and (ai.current_state == State.CHASE or ai.current_state == State.SEARCH):
						ai.roam_target = last_pos
						if dist_sq <= 100000.0:
							ai._spawn_ghost(last_pos, target)
						if ai.current_state == State.CHASE:
							ai.target = null
							ai.broadcast_chase_timer = 0.0
							ai._change_state(State.SEARCH)
		
		target = null
		_change_state(State.SEARCH)
		return
	
	if distance_sq <= attack_range * attack_range:
		var dir_to_target = (target.global_position - parent.global_position).normalized()
		var is_facing = facing_direction.dot(dir_to_target) > 0.5
		if is_facing:
			_change_state(State.ATTACK)
			return
	
	_set_movement_target(target.global_position)
	
	var desired_direction := Vector2.ZERO
	if nav_agent:
		var next_path_pos = nav_agent.get_next_path_position()
		desired_direction = (next_path_pos - parent.global_position).normalized()
	
	if desired_direction == Vector2.ZERO:
		desired_direction = (target.global_position - parent.global_position).normalized()
	
	var final_direction = _get_avoidance_direction(desired_direction)
	var separation = _calculate_separation_vector()
	parent.velocity = final_direction * chase_speed + separation * separation_weight

	last_known_position = target.global_position

func _process_attack(delta: float) -> void:
	if not target:
		is_winding_up = false
		_change_state(State.IDLE)
		return
	
	var distance = parent.global_position.distance_to(target.global_position)
	
	if distance > attack_range * 1.5 and not is_winding_up:
		_change_state(State.CHASE)
		return
	elif distance > attack_range * 2.5 and is_winding_up:
		is_winding_up = false
		_change_state(State.CHASE)
		return
	
	parent.velocity = Vector2.ZERO
	
	if is_winding_up:
		wind_up_timer -= delta
		if wind_up_timer <= 0.0:
			is_winding_up = false
			_perform_attack()
			attack_timer = attack_cooldown
	else:
		if attack_timer <= 0.0:
			is_winding_up = true
			wind_up_timer = attack_windup_time
			if parent.has_method("play_attack_anticipation"):
				parent.play_attack_anticipation(attack_windup_time)

func _perform_attack() -> void:
	var damage = DamageData.new()
	damage.amount = attack_damage
	damage.type = CombatConstants.DamageType.CUT
	damage.bleed_buildup = 35.0
	
	attack_triggered.emit(damage)

func _steer_towards(dest: Vector2, fallback_dir: Vector2 = Vector2.ZERO) -> Vector2:
	_set_movement_target(dest)
	var dir := (nav_agent.get_next_path_position() - parent.global_position).normalized() if nav_agent else Vector2.ZERO
	if dir == Vector2.ZERO:
		dir = fallback_dir if fallback_dir != Vector2.ZERO else (dest - parent.global_position).normalized()
	return _get_avoidance_direction(dir)

func _process_search(delta: float) -> void:
	var detected := _check_player_detection(0.0)
	if detected:
		target = detected
		_clear_ghost()
		awareness_level = 1.0
		_change_state(State.CHASE)
		return
	var arrived := (nav_agent and nav_agent.is_navigation_finished()) or parent.global_position.distance_squared_to(roam_target) < 576.0
	if arrived:
		var point_index := int((search_duration - search_timer) / (search_duration / 6.0)) % 6
		var angle := point_index * (TAU / 6.0) + PI / 4.0
		roam_target = last_known_position + Vector2(cos(angle), sin(angle)) * 80.0
		target_facing_direction = (roam_target - parent.global_position).normalized()
	else:
		parent.velocity = _steer_towards(roam_target) * (chase_speed * 0.5)
	search_timer -= delta
	if search_timer <= 0.0:
		_clear_ghost()
		_change_state(State.RETURN)

func _process_return() -> void:
	var detected := _check_player_detection(0.0)
	if detected:
		target = detected
		_change_state(State.ALERT)
		awareness_level = 0.5
		return
	if current_state != State.RETURN:
		return
	_set_movement_target(spawn_position)
	if (nav_agent and nav_agent.is_navigation_finished()) or parent.global_position.distance_squared_to(spawn_position) <= 256.0:
		parent.velocity = Vector2.ZERO
		parent.global_position = spawn_position
		_change_state(State.IDLE)
		return
	var fallback := (spawn_position - parent.global_position).normalized()
	var final_dir := _steer_towards(spawn_position, fallback)
	parent.velocity = (final_dir if final_dir != Vector2.ZERO else fallback) * (chase_speed * 0.5)

func _process_flee() -> void:
	if not target:
		target = _find_player_in_range(detection_range * 1.5)
	if not target:
		_change_state(State.RETURN)
		return
	var dir_away := (parent.global_position - target.global_position).normalized()
	parent.velocity = _steer_towards(parent.global_position + dir_away * 300.0, dir_away) * (chase_speed * 1.2)

func _on_health_changed(current: float, max_health: float) -> void:
	if flee_health_threshold > 0.0 and (current / max_health) <= flee_health_threshold and current_state not in [State.FLEE, State.IDLE]:
		if not target:
			target = _find_player_in_range(detection_range)
		_change_state(State.FLEE)

func _find_player_in_range(max_range: float) -> Node2D:
	if not detection_area: return null
	var closest := detection_area.get_closest_target(parent.global_position)
	return closest if (closest and (max_range <= 0.0 or parent.global_position.distance_to(closest.global_position) <= max_range * 1.5)) else null

func _calculate_separation_vector() -> Vector2:
	var separation := Vector2.ZERO
	for ally in get_tree().get_nodes_in_group("enemies"):
		if ally == parent: continue
		var diff: Vector2 = parent.global_position - ally.global_position
		var dist_sq := diff.length_squared()
		if dist_sq < 2500.0 and dist_sq > 0.0001:
			separation += diff / dist_sq
	return separation.normalized() if separation.length_squared() > 0.0001 else Vector2.ZERO

func _has_line_of_sight(target_node: Node2D) -> bool:
	if not target_node: return false
	if target_node == cached_los_target and vision_timer > 0.0:
		return cached_los_result
	cached_los_target = target_node
	vision_timer = 0.1
	var query := PhysicsRayQueryParameters2D.create(parent.global_position, target_node.global_position, 1)
	query.exclude = [parent.get_rid(), target_node.get_rid()] if target_node is CollisionObject2D else [parent.get_rid()]
	cached_los_result = parent.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
	return cached_los_result

func calculate_auditory_radius(sound_origin: Vector2) -> float:
	if hearing_timer > 0.0:
		return cached_effective_hearing
	hearing_timer = 0.15
	var query := PhysicsRayQueryParameters2D.create(parent.global_position, sound_origin, 1, [parent.get_rid()])
	cached_effective_hearing = 20.0 if not parent.get_world_2d().direct_space_state.intersect_ray(query).is_empty() else hearing_range
	return cached_effective_hearing

func _get_avoidance_direction(desired_dir: Vector2) -> Vector2:
	if is_instance_valid(on_screen_notifier) and not on_screen_notifier.is_on_screen():
		return desired_dir
	if avoidance_timer > 0.0 and desired_dir.dot(cached_avoidance_input_dir) > 0.98:
		return cached_avoidance_dir
	cached_avoidance_input_dir = desired_dir
	avoidance_timer = 0.12
	var space_state := parent.get_world_2d().direct_space_state
	var exclude_rids: Array[RID] = [parent.get_rid(), target.get_rid()] if target is CollisionObject2D else [parent.get_rid()]
	for i in range(num_rays):
		interest_map[i] = max(0.0, ray_directions[i].dot(desired_dir))
		danger_map[i] = 0.0
	for i in range(num_rays):
		var query := PhysicsRayQueryParameters2D.create(parent.global_position, parent.global_position + ray_directions[i] * look_ahead, 1, exclude_rids)
		if not space_state.intersect_ray(query).is_empty():
			danger_map[i] = 1.0
			danger_map[(i - 1 + num_rays) % num_rays] = max(danger_map[(i - 1 + num_rays) % num_rays], 0.5)
			danger_map[(i + 1) % num_rays] = max(danger_map[(i + 1) % num_rays], 0.5)
	var chosen_dir := Vector2.ZERO
	for i in range(num_rays):
		var value := interest_map[i] - danger_map[i]
		if value > 0.0:
			chosen_dir += ray_directions[i] * value
	cached_avoidance_dir = chosen_dir.normalized()
	return cached_avoidance_dir

func _change_state(new_state: State) -> void:
	if current_state != new_state:
		var prev_state = current_state
		current_state = new_state
		is_winding_up = false
		_last_nav_target = Vector2.INF
		nav_timer = 0.0
		state_changed.emit(new_state)
		
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
	if alert_cooldown_timer > 0.0:
		return
	alert_cooldown_timer = ALERT_COOLDOWN_MAX
	var alert_radius: float = 300.0
	for ally in get_tree().get_nodes_in_group("enemies"):
		if ally == parent or not ally.is_physics_processing(): continue
		var distance := parent.global_position.distance_to(ally.global_position)
		if distance > alert_radius: continue
		var ally_ai := ally.get_node_or_null("EnemyAI") as EnemyAI
		if not ally_ai or ally_ai.current_state in [State.CHASE, State.ATTACK, State.FLEE] or ally_ai.alert_cooldown_timer > 0.0:
			continue
		var query := PhysicsRayQueryParameters2D.create(parent.global_position, ally.global_position, 1, [parent.get_rid(), ally.get_rid()])
		var effective_range := alert_radius if parent.get_world_2d().direct_space_state.intersect_ray(query).is_empty() else 100.0
		if distance <= effective_range or ally_ai._has_line_of_sight(parent):
			ally_ai.target_facing_direction = (parent.global_position - ally.global_position).normalized()
			if target:
				ally_ai.target = target
				ally_ai.last_known_position = target.global_position
				ally_ai.roam_target = target.global_position
				ally_ai.awareness_level = 1.0
				ally_ai.broadcast_chase_timer = BROADCAST_CHASE_GRACE
				ally_ai._change_state(State.CHASE)
			else:
				ally_ai.last_known_position = parent.global_position
				ally_ai.roam_target = parent.global_position
				ally_ai.awareness_level = 0.5
				ally_ai._change_state(State.SEARCH)

func _spawn_ghost(pos: Vector2, target_node: Node2D) -> void:
	_clear_ghost()
	if not target_node: return
	var anim_node := target_node.get_node_or_null("Animations")
	var texture: Texture2D = null
	if anim_node is AnimatedSprite2D:
		texture = anim_node.sprite_frames.get_frame_texture(anim_node.animation, anim_node.frame)
	elif anim_node is Sprite2D:
		texture = anim_node.texture
	if not texture: return
	ghost_instance = Sprite2D.new()
	ghost_instance.texture = texture
	if anim_node is Sprite2D:
		ghost_instance.hframes = anim_node.hframes
		ghost_instance.vframes = anim_node.vframes
		ghost_instance.frame = anim_node.frame
	ghost_instance.z_index = 100
	ghost_instance.scale = target_node.scale
	ghost_instance.global_position = pos
	if anim_node is AnimatedSprite2D or anim_node is Sprite2D:
		ghost_instance.flip_h = anim_node.flip_h
		ghost_instance.flip_v = anim_node.flip_v
	if GHOST_SHADER:
		var mat := ShaderMaterial.new()
		mat.shader = GHOST_SHADER
		mat.set_shader_parameter("line_color", Color(0.5, 0.8, 1.0, 0.8))
		mat.set_shader_parameter("line_thickness", 2.0)
		ghost_instance.material = mat
	else:
		ghost_instance.modulate = Color(0.5, 0.8, 1.0, 0.5)
	get_tree().current_scene.add_child(ghost_instance)
	get_tree().create_timer(3.0).timeout.connect(_clear_ghost)

func _clear_ghost() -> void:
	if is_instance_valid(ghost_instance):
		ghost_instance.queue_free()
	ghost_instance = null

func get_move_direction() -> Vector2:
	if parent.velocity != Vector2.ZERO:
		return parent.velocity.normalized()
	return Vector2.ZERO

func _set_movement_target(target_pos: Vector2) -> void:
	if not nav_agent:
		return
	# Throttle NavigationServer path queries to every 0.2s or when target moved >16px
	if nav_timer <= 0.0 or _last_nav_target.distance_squared_to(target_pos) > 256.0:
		_last_nav_target = target_pos
		nav_timer = 0.2
		nav_agent.target_position = target_pos

func notify_damage(attacker: Node2D) -> void:
	if not attacker: return
	
	target = attacker
	awareness_level = 1.0
	awareness_changed.emit(awareness_level, true)
	
	if current_state != State.CHASE and current_state != State.ATTACK and current_state != State.FLEE:
		_change_state(State.CHASE)

func on_noise_heard(noise_pos: Vector2) -> void:
	"""Llamado cuando el enemigo escucha un sonido cercano (correr, romper objetos, etc.)."""
	if current_state in [State.CHASE, State.ATTACK, State.FLEE]:
		return
	target_facing_direction = (noise_pos - parent.global_position).normalized()
	last_known_position = noise_pos
	roam_target = noise_pos
	_clear_ghost()
	if current_state != State.SEARCH:
		awareness_level = max(awareness_level, 0.4)
		awareness_changed.emit(awareness_level, true)
		_change_state(State.SEARCH)
	else:
		search_timer = search_duration
