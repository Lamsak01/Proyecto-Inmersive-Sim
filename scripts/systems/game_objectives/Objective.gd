extends Resource
class_name Objective

signal completed
signal updated

@export var id: String
@export var description: String
@export var is_optional: bool = false

enum ObjectiveType { KILL, COLLECT, INTERACT, REACH, CUSTOM }

@export var type: ObjectiveType = ObjectiveType.CUSTOM
@export var target_id: String
@export var target_count: int = 1
@export var current_count: int = 0:
	set(value):
		if current_count != value:
			current_count = value
			updated.emit()
			if current_count >= target_count and not is_completed:
				complete()

var is_completed: bool = false:
	set(value):
		if is_completed != value:
			is_completed = value
			updated.emit()
			if is_completed:
				completed.emit()

func complete() -> void:
	is_completed = true
