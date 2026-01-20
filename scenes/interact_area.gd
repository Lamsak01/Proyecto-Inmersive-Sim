extends Area2D

func interact(player: Node) -> void:
	get_parent().interact(player)
