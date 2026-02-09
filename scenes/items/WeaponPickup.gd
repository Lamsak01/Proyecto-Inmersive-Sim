extends Area2D

@export var weapon_name: String = "Sword"
var player_in_range: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("Interact"): # 'E' Key
		if player_in_range.has_method("add_item"):
			player_in_range.add_item(weapon_name)
			print("Picked up: ", weapon_name)
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = body
		print("Press 'E' to pick up ", weapon_name)

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
