extends Area2D

@export var requires_key: bool = true
@export var required_key_id: String = "key_house_01"

@onready var blocker: CollisionShape2D = $"../DoorBody/DoorBlockCollision"
@onready var sprite: Node = $"../DoorSprite"

func interact(player: Node) -> void:
	if requires_key:
		if not player.has_method("has_key") or not player.has_key(required_key_id):
			if player.has_method("show_hint"):
				player.show_hint("La puerta está cerrada. Necesitas la llave correcta.")
			return

	blocker.disabled = true
	sprite.visible = false
	if player.has_method("show_hint"):
		player.show_hint("Puerta abierta.")
