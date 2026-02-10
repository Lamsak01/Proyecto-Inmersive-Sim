extends Resource
class_name Objective

signal completed
signal updated

@export var id: String
@export var description: String
@export var is_optional: bool = false

var is_completed: bool = false:
	set(value):
		if is_completed != value:
			is_completed = value
			updated.emit()
			if is_completed:
				completed.emit()

func complete() -> void:
	is_completed = true
