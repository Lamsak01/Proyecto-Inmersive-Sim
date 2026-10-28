extends Area2D

@export_file("*.tscn") var target_scene_path: String
@export var target_position: Vector2 = Vector2.ZERO 
@export var spawn_direction: String = ""

var player_in_range: Node2D = null
var _is_loading: bool = false

func _ready() -> void:
	set_process(false)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("Interact"):
		print("DEBUG: Teleport triggered by input on ", name)
		change_scene()

func change_scene() -> void:
	if target_scene_path == "":
		push_error("SceneTeleporter: No target scene path set!")
		return
		
	# Force cancel any active drag operations before saving/changing scene to prevent memory leaks
	var vp = get_viewport()
	if vp and vp.gui_is_dragging():
		vp.gui_cancel_drag()
		print("SceneTeleporter: Cancelled active UI drag.")
	
	# Save player state BEFORE changing scene
	if player_in_range:
		var player = player_in_range
		if player.has_node("GridInventory"):
			print("DEBUG: Saving player state from: ", player.name)
			GameState.save_player_state(player)
		elif player.get_parent() and player.get_parent().has_node("GridInventory"):
			print("DEBUG: Saving player state from parent: ", player.get_parent().name)
			GameState.save_player_state(player.get_parent())
		else:
			print("DEBUG: Could not find GridInventory on player!")
	
	# Setup target direction based on export var
	if spawn_direction != "":
		GameState.next_spawn_direction = spawn_direction

	call_deferred("_deferred_change_scene")

func _deferred_change_scene() -> void:
	if ResourceLoader.has_cached(target_scene_path):
		get_tree().change_scene_to_file(target_scene_path)
	else:
		ResourceLoader.load_threaded_request(target_scene_path)
		_is_loading = true
		set_process(true)
		
		var overlay = CanvasLayer.new()
		overlay.layer = 100
		var color_rect = ColorRect.new()
		color_rect.color = Color(0, 0, 0, 1)
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.add_child(color_rect)
		add_child(overlay)

func _process(_delta: float) -> void:
	if _is_loading:
		var status = ResourceLoader.load_threaded_get_status(target_scene_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_is_loading = false
			set_process(false)
			var packed_scene = ResourceLoader.load_threaded_get(target_scene_path)
			get_tree().change_scene_to_packed(packed_scene)
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("SceneTeleporter: Failed to load scene asynchronously.")
			_is_loading = false
			set_process(false)

func _is_player(node: Node) -> bool:
	return node.is_in_group("player") or node.name == "Player" or node.name == "PlayerGood"

func _on_body_entered(body: Node2D) -> void:
	if _is_player(body):
		player_in_range = body
		print("DEBUG: Player entered teleporter: ", name)

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		print("DEBUG: Player exited teleporter: ", name)

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and _is_player(parent):
		player_in_range = parent
		print("DEBUG: Player Area entered teleporter: ", name)

func _on_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent == player_in_range:
		player_in_range = null
