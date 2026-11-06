extends Node
class_name PlayerMovementController

@export var max_walk_speed: float = 120.0
## Velocidad extra yendo a caballo y freno al tirar de la carreta (a mano o con caballo).
const MOUNT_SPEED_MULT: float = 1.45
const CART_HAND_SPEED_MULT: float = 0.55
const CART_HORSE_SPEED_MULT: float = 0.80
@export var sprint_speed: float = 200.0
@export var stealth_speed: float = 60.0
@export var acceleration: float = 1400.0
@export var friction: float = 1600.0

var is_sprinting: bool = false
var is_stealthing: bool = false
var current_speed: float = 120.0

## Rodar con Espacio (COMBATE-1): distancia ~50 px en 0.35 s, invulnerable los primeros 0.25 s.
const ROLL_DURATION: float = 0.35
const ROLL_INVULN_DURATION: float = 0.25
const ROLL_DISTANCE: float = 50.0
const ROLL_COOLDOWN: float = 0.60
const ROLL_STAMINA_COST: float = 18.0

var roll_timer: float = 0.0
var roll_invuln_timer: float = 0.0
var roll_cooldown_timer: float = 0.0
var roll_direction: Vector2 = Vector2.DOWN

@onready var player: CharacterBody2D = get_parent()
@onready var anim: AnimatedSprite2D = $"../Animations"
@onready var cam: Camera2D = get_node_or_null("../Camera2D")
@onready var stamina_comp: StaminaComponent = $"../StaminaComponent"
@onready var dialogue_manager: Node = player.get("dialogue_manager")

@export var camera_look_ahead_ratio: float = 0.28 ## Qué tanto se desplaza la cámara hacia el punto de mira
@export var max_camera_offset: float = 55.0       ## Desplazamiento máximo normal de la cámara
@export var max_aim_camera_offset: float = 95.0   ## Desplazamiento al mantener Clic Derecho (Apuntar lejos)
@export var camera_smooth_speed: float = 8.0      ## Velocidad de suavizado de la cámara

func is_rolling() -> bool:
	return roll_timer > 0.0

func is_roll_invulnerable() -> bool:
	return roll_invuln_timer > 0.0

func get_roll_progress() -> float:
	if roll_timer <= 0.0:
		return 0.0
	return clampf(1.0 - (roll_timer / ROLL_DURATION), 0.0, 1.0)

func start_roll(dir_override: Vector2 = Vector2.ZERO) -> bool:
	if not is_instance_valid(player):
		return false
	var lake = get_tree().current_scene.find_child("WestFishingLake", true, false) if get_tree().current_scene else null
	var in_fishing_minigame: bool = lake != null and int(lake.get("state")) == 3
	var camp = get_tree().current_scene.find_child("PlayerCampSite", true, false) if get_tree().current_scene else null
	var sitting_on_log: bool = camp != null and bool(camp.get("is_player_sitting"))
	var vm = get_tree().get_first_node_in_group("village_manager")
	var being_escorted: bool = vm != null and bool(vm.get("player_being_escorted_to_jail"))
	if (dialogue_manager and dialogue_manager.has_method("is_active") and dialogue_manager.call("is_active")) or (WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen()) or (player.has_method("is_any_ui_modal_open") and bool(player.call("is_any_ui_modal_open"))) or in_fishing_minigame or sitting_on_log or being_escorted:
		return false
	if player.has_method("is_stunned") and player.is_stunned():
		return false
	if bool(player.get("is_mounted")):
		if player.has_method("show_hint"):
			player.show_hint("🐎 A caballo no puedes rodar: baja con [E]")
		return false
	if bool(player.get("is_pulling_cart")):
		if player.has_method("show_hint"):
			player.show_hint("🛒 Tirando de la carreta no puedes rodar: suéltala con [E]")
		return false
	if roll_timer > 0.0 or roll_cooldown_timer > 0.0:
		return false
	if not is_instance_valid(stamina_comp) or stamina_comp.current_stamina < ROLL_STAMINA_COST or not stamina_comp.use_stamina(ROLL_STAMINA_COST):
		return false

	var dir: Vector2 = Vector2.ZERO
	if dir_override.length_squared() > 0.001:
		dir = dir_override.normalized()
	else:
		var inp := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if inp.length_squared() > 0.001:
			dir = inp.normalized()
		elif player.velocity.length_squared() > 9.0:
			dir = player.velocity.normalized()
		else:
			var c_ctrl = player.get_node_or_null("PlayerCombatController")
			if c_ctrl != null and c_ctrl.get("current_aim_dir") is Vector2 and (c_ctrl.get("current_aim_dir") as Vector2).length_squared() > 0.01:
				dir = (c_ctrl.get("current_aim_dir") as Vector2).normalized()
			else:
				match str(player.get("last_dir")):
					"right":
						dir = Vector2.RIGHT
					"left":
						dir = Vector2.LEFT
					"up":
						dir = Vector2.UP
					_:
						dir = Vector2.DOWN

	is_stealthing = false
	is_sprinting = false
	roll_direction = dir
	roll_timer = ROLL_DURATION
	roll_invuln_timer = ROLL_INVULN_DURATION
	roll_cooldown_timer = ROLL_COOLDOWN
	player.velocity = roll_direction * (ROLL_DISTANCE / ROLL_DURATION)
	return true

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(anim):
		return

	if roll_cooldown_timer > 0.0:
		roll_cooldown_timer = maxf(0.0, roll_cooldown_timer - delta)
	if roll_invuln_timer > 0.0:
		roll_invuln_timer = maxf(0.0, roll_invuln_timer - delta)

	# Block movement if dialogue active, modal open, tavern minigame time freeze, sitting on camp log, in fishing minigame, or handcuffed in police escort
	var lake = get_tree().current_scene.find_child("WestFishingLake", true, false) if get_tree().current_scene else null
	var in_fishing_minigame: bool = lake != null and int(lake.get("state")) == 3
	var camp = get_tree().current_scene.find_child("PlayerCampSite", true, false) if get_tree().current_scene else null
	var sitting_on_log: bool = camp != null and bool(camp.get("is_player_sitting"))
	var vm = get_tree().get_first_node_in_group("village_manager")
	var being_escorted: bool = vm != null and bool(vm.get("player_being_escorted_to_jail"))
	if (dialogue_manager and dialogue_manager.has_method("is_active") and dialogue_manager.call("is_active")) or (WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen()) or (player.has_method("is_any_ui_modal_open") and bool(player.call("is_any_ui_modal_open"))) or in_fishing_minigame or sitting_on_log or being_escorted:
		if is_instance_valid(stamina_comp):
			stamina_comp.is_input_blocking = false
		if being_escorted:
			is_stealthing = false
			is_sprinting = false
		roll_timer = 0.0
		roll_invuln_timer = 0.0
		anim.rotation = 0.0
		player.velocity = Vector2.ZERO
		_play_idle()
		if not being_escorted:
			player.move_and_slide()
		return

	# Block movement if stunned
	if player.has_method("is_stunned") and player.is_stunned():
		if is_instance_valid(stamina_comp):
			stamina_comp.is_input_blocking = false
		roll_timer = 0.0
		roll_invuln_timer = 0.0
		anim.rotation = 0.0
		player.velocity = Vector2.ZERO
		player.move_and_slide()
		_update_visual_state()
		return

	if roll_timer > 0.0:
		roll_timer = maxf(0.0, roll_timer - delta)
		if is_instance_valid(stamina_comp):
			stamina_comp.is_input_blocking = true
		player.velocity = roll_direction * (ROLL_DISTANCE / ROLL_DURATION)
		player.move_and_slide()
		_update_aim_and_camera(delta)
		_update_visual_state()
		if roll_timer > 0.0:
			var prog: float = get_roll_progress()
			anim.rotation = prog * TAU * (1.0 if roll_direction.x >= 0.0 else -1.0)
		else:
			anim.rotation = 0.0
		return
	elif anim.rotation != 0.0:
		anim.rotation = 0.0

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
	var vm = get_tree().get_first_node_in_group("village_manager")
	if (player.has_method("is_stunned") and player.is_stunned()) or (player.has_method("is_any_ui_modal_open") and bool(player.call("is_any_ui_modal_open"))) or (vm != null and bool(vm.get("player_being_escorted_to_jail"))):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE:
			if start_roll():
				get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_C:
			if bool(player.get("is_mounted")):
				if player.has_method("show_hint"):
					player.show_hint("🐎 A caballo no puedes ir en sigilo: baja con [E]")
				return
			if bool(player.get("is_pulling_cart")):
				if player.has_method("show_hint"):
					player.show_hint("🛒 Tirando de la carreta no puedes ir en sigilo: suéltala con [E]")
				return
			is_stealthing = not is_stealthing

func apply_impulse(force: Vector2) -> void:
	if is_instance_valid(player):
		player.velocity += force

func _handle_input(delta: float) -> void:
	var is_sprint_pressed = Input.is_action_pressed("sprint")
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var pulling_hand: bool = bool(player.get("is_pulling_cart")) and not bool(player.get("is_mounted"))
	if pulling_hand or bool(player.get("is_mounted")):
		is_stealthing = false

	# Pressing sprint while moving breaks stealth automatically for fluid responsiveness
	if is_stealthing and is_sprint_pressed and input != Vector2.ZERO:
		is_stealthing = false

	var wants_sprint = is_sprint_pressed and not is_stealthing and not pulling_hand and input != Vector2.ZERO
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

	# Weakness (active bleeding) and anatomical leg capacity (Project Zomboid / RimWorld parity)
	if player.is_weak:
		current_speed *= 0.6
		target_anim_scale *= 0.7
	var hc: HealthComponent = player.get_node_or_null("HealthComponent")
	if hc:
		var mov_cap: float = hc.get_moving_capacity()
		current_speed *= mov_cap
		target_anim_scale *= lerpf(0.65, 1.0, mov_cap)

	if "armor_speed_multiplier" in player:
		current_speed *= float(player.get("armor_speed_multiplier"))
	# Caballo de silla (PlayerHorse) y carreta de carga (PlayerCart)
	if bool(player.get("is_mounted")):
		current_speed *= MOUNT_SPEED_MULT
		if bool(player.get("is_cart_hitched")):
			current_speed *= CART_HORSE_SPEED_MULT
	elif bool(player.get("is_pulling_cart")):
		current_speed *= CART_HAND_SPEED_MULT

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
