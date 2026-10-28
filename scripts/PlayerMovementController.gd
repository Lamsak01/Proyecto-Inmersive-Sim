extends Node
class_name PlayerMovementController

@export var max_walk_speed: float = 120.0
@export var sprint_speed: float = 200.0
@export var stealth_speed: float = 60.0
@export var acceleration: float = 1400.0
@export var friction: float = 1600.0

var is_sprinting: bool = false
var is_stealthing: bool = false
var current_speed: float = 120.0

@onready var player: CharacterBody2D = get_parent()
@onready var anim: AnimatedSprite2D = $"../Animations"
@onready var stamina_comp: StaminaComponent = $"../StaminaComponent"
@onready var dialogue_manager: Node = player.get("dialogue_manager")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(anim):
		return

	# Block movement if dialogue active
	if dialogue_manager and dialogue_manager.has_method("is_active") and dialogue_manager.call("is_active"):
		player.velocity = Vector2.ZERO
		_play_idle()
		player.move_and_slide()
		return

	# Block movement if stunned
	if player.has_method("is_stunned") and player.is_stunned():
		player.velocity = Vector2.ZERO
		player.move_and_slide()
		_update_visual_state()
		return

	_handle_input(delta)
	player.move_and_slide()
	_update_visual_state()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			is_stealthing = not is_stealthing

func _handle_input(delta: float) -> void:
	var is_sprint_pressed = Input.is_action_pressed("sprint")
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Pressing sprint while moving breaks stealth automatically for fluid responsiveness
	if is_stealthing and is_sprint_pressed and input != Vector2.ZERO:
		is_stealthing = false

	var wants_sprint = is_sprint_pressed and not is_stealthing and input != Vector2.ZERO
	if is_instance_valid(stamina_comp):
		stamina_comp.is_input_blocking = wants_sprint

	var target_anim_scale: float = 1.0

	if is_stealthing:
		is_sprinting = false
		current_speed = stealth_speed
		target_anim_scale = 0.65
	elif wants_sprint and is_instance_valid(stamina_comp) and stamina_comp.use_stamina(stamina_comp.sprint_cost * delta):
		is_sprinting = true
		current_speed = sprint_speed
		target_anim_scale = 1.4
	else:
		is_sprinting = false
		current_speed = max_walk_speed
		target_anim_scale = 1.0

	# Weakness (active bleeding) penalty
	if player.is_weak:
		current_speed *= 0.6
		target_anim_scale *= 0.7

	anim.speed_scale = target_anim_scale

	if input != Vector2.ZERO:
		var target_vel = input * current_speed
		player.velocity = player.velocity.move_toward(target_vel, acceleration * delta)
		_play_walk(input)
	else:
		player.velocity = player.velocity.move_toward(Vector2.ZERO, friction * delta)
		_play_idle()

func _update_visual_state() -> void:
	var target_alpha := 0.6 if is_stealthing else 1.0
	if player.is_stunned():
		player.modulate = Color(0.5, 0.6, 1.0, target_alpha)
	elif player.is_weak:
		player.modulate = Color(1.0, 0.55, 0.55, target_alpha)
	else:
		player.modulate = Color(1.0, 1.0, 1.0, target_alpha)

func _play_walk(dir: Vector2) -> void:
	var target_anim: String
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0.0:
			target_anim = "walk_right"
			player.last_dir = "right"
		else:
			target_anim = "walk_left"
			player.last_dir = "left"
	else:
		if dir.y > 0.0:
			target_anim = "walk_down"
			player.last_dir = "down"
		else:
			target_anim = "walk_up"
			player.last_dir = "up"

	if anim.animation != target_anim or not anim.is_playing():
		anim.play(target_anim)

func _play_idle() -> void:
	var dir = player.last_dir
	if dir != null:
		var target_anim = "idle_" + dir
		if anim.animation != target_anim or not anim.is_playing():
			anim.play(target_anim)
