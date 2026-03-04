extends Node
## Autoload for managing audio events and spatial acoustic occlusion
## Registered in project.godot as "AudioManager"

# Cache for bus indexes
var sfx_bus_idx: int = -1

func _ready() -> void:
	# Attempt to find or create an SFX bus
	sfx_bus_idx = AudioServer.get_bus_index("SFX")
	
	if sfx_bus_idx == -1:
		print("AudioManager: 'SFX' bus not found. Creating it.")
		AudioServer.add_bus()
		sfx_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_bus_idx, "SFX")
		
		# Ensure it routes to Master
		var master_idx = AudioServer.get_bus_index("Master")
		if master_idx != -1:
			AudioServer.set_bus_send(sfx_bus_idx, "Master")
	
	print(">>> AudioManager Autoload READY <<<")

func play_sound_at(stream: AudioStream, global_pos: Vector2, pitch_variance: float = 0.1, base_volume_db: float = 0.0) -> void:
	if not stream: return
	
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.global_position = global_pos
	player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	player.volume_db = base_volume_db
	player.bus = "SFX"
	
	# Auto-destroy when finished
	player.finished.connect(player.queue_free)
	
	get_tree().current_scene.add_child(player)
	player.play()
	
func get_acoustic_occlusion_multiplier(source_pos: Vector2, listener_pos: Vector2, space_state: PhysicsDirectSpaceState2D) -> float:
	"""
	Casts a ray from source to listener. 
	Returns a multiplier to apply to the hearing radius (e.g. 1.0 if clear, 0.3 if occluded).
	"""
	if not space_state:
		return 1.0
		
	var query = PhysicsRayQueryParameters2D.create(source_pos, listener_pos)
	# Only check environment/wall layer (layer 1)
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		return 1.0 # Clear Line of Sight, full volume
	else:
		return 0.3 # Occluded by wall, drastically reduce hearing radius
		
func calculate_effective_hearing_range(base_range: float, source_pos: Vector2, listener_pos: Vector2, space_state: PhysicsDirectSpaceState2D) -> float:
	var multiplier = get_acoustic_occlusion_multiplier(source_pos, listener_pos, space_state)
	return base_range * multiplier
