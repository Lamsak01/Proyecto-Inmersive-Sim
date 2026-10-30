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
@onready var cam: Camera2D = get_node_or_null("../Camera2D")
@onready var stamina_comp: StaminaComponent = $"../StaminaComponent"
@onready var dialogue_manager: Node = player.get("dialogue_manager")

@export var camera_look_ahead_ratio: float = 0.28 ## Qué tanto se desplaza la cámara hacia el punto de mira
@export var max_camera_offset: float = 55.0       ## Desplazamiento máximo normal de la cámara
@export var max_aim_camera_offset: float = 95.0   ## Desplazamiento al mantener Clic Derecho (Apuntar lejos)
@export var camera_smooth_speed: float = 8.0      ## Velocidad de suavizado de la cámara

var _aim_screen_offset: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(anim):
		return

	# Block movement if dialogue active, modal open, tavern minigame time freeze, sitting on camp log, or in fishing minigame
	var lake = get_tree().current_scene.find_child("WestFishingLake", true, false) if get_tree().current_scene else null
	var in_fishing_minigame: bool = lake != null and int(lake.get("state")) == 3
	var camp = get_tree().current_scene.find_child("PlayerCampSite", true, false) if get_tree().current_scene else null
	var sitting_on_log: bool = camp != null and bool(camp.get("is_player_sitting"))
	if (dialogue_manager and dialogue_manager.has_method("is_active") and dialogue_manager.call("is_active")) or (WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen()) or (player.has_method("is_any_ui_modal_open") and bool(player.call("is_any_ui_modal_open"))) or in_fishing_minigame or sitting_on_log:
		if is_instance_valid(stamina_comp):
			stamina_comp.is_input_blocking = false
		player.velocity = Vector2.ZERO
		_play_idle()
		player.move_and_slide()
		return

	# Block movement if stunned
	if player.has_method("is_stunned") and player.is_stunned():
		if is_instance_valid(stamina_comp):
			stamina_comp.is_input_blocking = false
		player.velocity = Vector2.ZERO
		player.move_and_slide()
		_update_visual_state()
		return

	_update_aim_and_camera(delta)
	_handle_input(delta)
	player.move_and_slide()
	_update_visual_state()

func _update_aim_and_camera(delta: float) -> void:
	var pivot_pos: Vector2 = player.global_position + Vector2(0, -10)
	var ch: Crosshair2D = player.get_node_or_null("Crosshair2D")
	var aim_world: Vector2 = ch.get_aim_world_position() if ch else player.get_global_mouse_position()
	var aim_vec: Vector2 = aim_world - pivot_pos

	# Actualizar hacia dónde mira el personaje según el Punto de Mira
	if aim_vec.length_squared() > 4.0:
		if abs(aim_vec.x) >= abs(aim_vec.y):
			player.last_dir = "right" if aim_vec.x >= 0.0 else "left"
		else:
			player.last_dir = "down" if aim_vec.y >= 0.0 else "up"

	# Desplazar suavemente la cámara hacia donde estás mirando/apuntando (estilo Enter the Gungeon / Zero Sievert)
	# Funciona en todo momento, incluso mientras caminas con WASD en cualquier dirección.
	if is_instance_valid(cam):
		var is_peeking: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		var look_mult: float = (camera_look_ahead_ratio * 1.65) if is_peeking else camera_look_ahead_ratio
		var limit_dist: float = max_aim_camera_offset if is_peeking else max_camera_offset
		var desired_offset: Vector2 = (aim_vec * look_mult).limit_length(limit_dist)
		cam.offset = cam.offset.lerp(desired_offset, clampf(camera_smooth_speed * delta, 0.0, 1.0))

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(player):
		return
	if (player.has_method("is_stunned") and player.is_stunned()) or (player.has_method("is_any_ui_modal_open") and bool(player.call("is_any_ui_modal_open"))):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			is_stealthing = not is_stealthing

func apply_impulse(force: Vector2) -> void:
	if is_instance_valid(player):
		player.velocity += force

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

	if "armor_speed_multiplier" in player:
		current_speed *= float(player.get("armor_speed_multiplier"))

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

func _play_walk(_dir: Vector2) -> void:
	var facing: String = player.last_dir if player.last_dir != "" else "down"
	var target_anim := "walk_" + facing
	if anim.animation != target_anim or not anim.is_playing():
		anim.play(target_anim)

func _play_idle() -> void:
	var dir = player.last_dir
	if dir != null:
		var target_anim = "idle_" + dir
		if anim.animation != target_anim or not anim.is_playing():
			anim.play(target_anim)
