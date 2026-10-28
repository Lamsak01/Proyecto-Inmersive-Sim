extends Node
## Gestor ligero de estado en memoria para la sesión actual (ej. objetos destructibles).
## El sistema de guardado en disco anterior fue eliminado para rehacerlo desde cero más adelante.

var game_data: Dictionary = {}

func set_flag(id: String, value: Variant) -> void:
	game_data[id] = value

func get_flag(id: String, default: Variant = null) -> Variant:
	return game_data.get(id, default)

func reset_save() -> void:
	game_data.clear()
