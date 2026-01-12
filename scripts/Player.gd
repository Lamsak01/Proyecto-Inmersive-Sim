extends CharacterBody2D

@export var speed := 120.0

func _physics_process(delta):
	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	if dir != Vector2.ZERO:
		dir = dir.normalized()

	velocity = dir * speed
	move_and_slide()
