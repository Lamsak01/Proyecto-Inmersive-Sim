extends Area2D

@export_file("*.tscn") var target_scene_path: String
@export var target_position: Vector2 = Vector2.ZERO 

var player_in_range: Node2D = null

func _ready() -> void:
	# Connect signals slightly differently for Area2D vs Body
	# If Player is CharacterBody2D, use body_entered
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Also connect area_entered in case Player uses an Area for detection (redundancy)
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
	
	call_deferred("_deferred_change_scene")

func _deferred_change_scene() -> void:
	get_tree().change_scene_to_file(target_scene_path)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = body
		print("DEBUG: Player entered teleporter: ", name)

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		print("DEBUG: Player exited teleporter: ", name)

func _on_area_entered(area: Area2D) -> void:
	# Check if the area belongs to the player
	var parent = area.get_parent()
	if parent and (parent.is_in_group("player") or parent.name == "Player"):
		player_in_range = parent
		print("DEBUG: Player Area entered teleporter: ", name)

func _on_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent == player_in_range:
		# Double check we aren't clearing it if the Body is still there
		# But simple logic for now:
		player_in_range = null
