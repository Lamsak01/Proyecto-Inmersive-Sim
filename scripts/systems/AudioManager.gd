extends Node
## Autoload for managing audio events and spatial acoustic occlusion
## Registered in project.godot as "AudioManager"

var sfx_bus_idx: int = -1

func _ready() -> void:
	sfx_bus_idx = AudioServer.get_bus_index("SFX")
	
	if sfx_bus_idx == -1:
		AudioServer.add_bus()
		sfx_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_bus_idx, "SFX")
		
		var master_idx = AudioServer.get_bus_index("Master")
		if master_idx != -1:
			AudioServer.set_bus_send(sfx_bus_idx, "Master")

func play_sound_at(stream: AudioStream, global_pos: Vector2, pitch_variance: float = 0.1, base_volume_db: float = 0.0) -> void:
	if not stream: return
	
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.global_position = global_pos
	player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	player.volume_db = base_volume_db
	player.bus = "SFX"
	
	player.finished.connect(player.queue_free)
	
	get_tree().current_scene.add_child(player)
	player.play()

func emit_noise(origin: Vector2, base_radius: float) -> void:
	"""
	Emite un evento puntual de ruido en el mundo (ej. al romper una caja/muro o correr).
	Solo lanza raycast de oclusión hacia los enemigos que estén dentro de base_radius.
	"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	var base_radius_sq = base_radius * base_radius
	for enemy in enemies:
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
		var dist_sq = enemy.global_position.distance_squared_to(origin)
		if dist_sq > base_radius_sq:
			continue

		var ai = enemy.get_node_or_null("EnemyAI")
		if not ai or not ai.is_physics_processing():
			continue

		var space_state = (enemy as Node2D).get_world_2d().direct_space_state
		var eff_range = calculate_effective_hearing_range(base_radius, origin, enemy.global_position, space_state)
		if dist_sq <= eff_range * eff_range and ai.has_method("on_noise_heard"):
			ai.on_noise_heard(origin)

func get_acoustic_occlusion_multiplier(source_pos: Vector2, listener_pos: Vector2, space_state: PhysicsDirectSpaceState2D) -> float:
	if not space_state:
		return 1.0
		
	var query = PhysicsRayQueryParameters2D.create(source_pos, listener_pos)
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return 1.0
	else:
		return 0.35

func calculate_effective_hearing_range(base_range: float, source_pos: Vector2, listener_pos: Vector2, space_state: PhysicsDirectSpaceState2D) -> float:
	var multiplier = get_acoustic_occlusion_multiplier(source_pos, listener_pos, space_state)
	return base_range * multiplier
