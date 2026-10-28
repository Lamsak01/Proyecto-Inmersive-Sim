extends Area2D

@export var key_id: String = "key_house_01"
@export var item_name: String = "Key"

func interact(player: Node) -> void:
	if player.has_method("add_key"):
		player.add_key(key_id) #
	queue_free()
