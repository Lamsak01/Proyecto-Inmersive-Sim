extends Area2D

@export_file("*.tscn") var target_scene_path: String
@export var target_position: Vector2 = Vector2.ZERO 

var player_in_range: Node2D = null

func _ready() -> void:
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
	
	call_deferred("_deferred_change_scene")

func _deferred_change_scene() -> void:
	get_tree().change_scene_to_file(target_scene_path)

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

