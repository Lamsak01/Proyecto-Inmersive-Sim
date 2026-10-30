extends Node2D
class_name Crosshair2D

## Punto de Mira Dinámico Híbrido (Ratón 360° + Modo ThinkPad/Teclado sin ratón)
## - Si mueves el ratón/TrackPoint, apunta exactamente al cursor en el mundo.
## - Si juegas solo con teclado (sin tocar el ratón):
##   * Al moverte con W/A/S/D (incluyendo diagonales), el punto de mira acompaña automáticamente
##     la dirección en la que caminas/miras.
##   * Puedes ajustar el apuntado con precisión usando las Flechas del Teclado (↑ ↓ ← →).
## - Muestra el cursor del sistema automáticamente al abrir la Mochila [I], Rueda [Tab] o Diálogos.

var player: CharacterBody2D = null
var current_gap: float = 4.0
var target_gap: float = 4.0
var recoil_impulse: float = 0.0
var reticle_color: Color = Color(0.98, 0.96, 0.88, 0.95)
var is_ranged_mode: bool = false
var is_drawing_bow: bool = false
var bow_tension: float = 0.0 # 0.0 (sin tensar) a 1.0 (máxima tensión)

var aim_offset: Vector2 = Vector2(0, 48)
var _last_screen_mouse: Vector2 = Vector2.ZERO
var _mouse_active_timer: float = 0.0
var _arrow_active_timer: float = 0.0

var _cached_inv_panel: Control = null
var _cached_wheel_panel: Control = null
var _cached_games_panel: Control = null
var _ui_lookup_cooldown: float = 0.0
var _target_color_timer: float = 0.0

var _last_drawn_gap: float = -1.0
var _last_drawn_color: Color = Color.TRANSPARENT
var _last_drawn_ranged: bool = false
var _last_drawn_bow: bool = false
var _last_drawn_tension: float = -1.0

func _ready() -> void:
	z_index = 100
	top_level = true
	if get_viewport():
		_last_screen_mouse = get_viewport().get_mouse_position()

func add_recoil(amount: float = 5.0) -> void:
	recoil_impulse = min(10.0, recoil_impulse + amount)

func get_aim_world_position() -> Vector2:
	if is_instance_valid(player):
		return player.global_position + Vector2(0, -10) + aim_offset
	return global_position

func _refresh_cached_ui_panels(delta: float) -> void:
	if _ui_lookup_cooldown > 0.0:
		_ui_lookup_cooldown -= delta
		return
	if is_instance_valid(_cached_inv_panel) and is_instance_valid(_cached_wheel_panel) and is_instance_valid(_cached_games_panel):
		_ui_lookup_cooldown = 1.0
		return
	_ui_lookup_cooldown = 0.5
	var root_node: Window = get_tree().root
	if not root_node:
		return
	if not is_instance_valid(_cached_inv_panel):
		_cached_inv_panel = root_node.find_child("InventoryPanel", true, false) as Control
	if not is_instance_valid(_cached_wheel_panel):
		_cached_wheel_panel = root_node.find_child("ToolWheelUI", true, false) as Control
	if not is_instance_valid(_cached_games_panel):
		_cached_games_panel = root_node.find_child("TavernGamesUI", true, false) as Control

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	_refresh_cached_ui_panels(delta)

	# 1. Si hay un menú, rueda radial, mapa o diálogo abierto, mostrar el cursor del sistema y ocultar la cruceta
	var ui_open := false
	if player.has_method("is_any_ui_modal_open") and bool(player.call("is_any_ui_modal_open")):
		ui_open = true
	var dm = player.get("dialogue_manager")
	if dm and dm.has_method("is_active") and dm.call("is_active"):
		ui_open = true
	if is_instance_valid(_cached_inv_panel) and _cached_inv_panel.visible:
		ui_open = true
	if is_instance_valid(_cached_wheel_panel) and _cached_wheel_panel.visible:
		ui_open = true
	if is_instance_valid(_cached_games_panel) and _cached_games_panel.visible:
		ui_open = true

	if ui_open:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		visible = false
		return
	else:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_HIDDEN:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		visible = true

	if _mouse_active_timer > 0.0:
		_mouse_active_timer -= delta
	if _arrow_active_timer > 0.0:
		_arrow_active_timer -= delta

	# 2. Detectar si el jugador movió físicamente el ratón/touchpad en la pantalla
	var screen_mouse: Vector2 = get_viewport().get_mouse_position()
	if screen_mouse.distance_squared_to(_last_screen_mouse) > 2.0:
		_last_screen_mouse = screen_mouse
		_mouse_active_timer = 2.5
		var cur_mouse_local: Vector2 = player.get_local_mouse_position() - Vector2(0, -10)
		if cur_mouse_local.length_squared() > 4.0:
			aim_offset = cur_mouse_local

	# 3. Apuntado con Flechas del Teclado (↑ ↓ ← →) — Prioridad manual en teclado
	var arrow_input := Vector2(
		float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))
	)
	if arrow_input.length_squared() > 0.01:
		_arrow_active_timer = 3.0
		_mouse_active_timer = 0.0
		aim_offset += arrow_input.normalized() * 145.0 * delta
		aim_offset = aim_offset.limit_length(150.0)
		if aim_offset.length() < 18.0:
			aim_offset = arrow_input.normalized() * 24.0

	# 4. Modo ThinkPad sin ratón: si no estás moviendo el ratón ni las flechas, orientar con W/A/S/D
	elif _mouse_active_timer <= 0.0 and _arrow_active_timer <= 0.0:
		var wasd_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var target_dist: float = 75.0 if is_ranged_mode else 42.0
		if wasd_dir.length_squared() > 0.04:
			var desired_offset: Vector2 = wasd_dir.normalized() * target_dist
			aim_offset = aim_offset.lerp(desired_offset, clampf(14.0 * delta, 0.0, 1.0))
		elif "last_dir" in player:
			var facing_vec := Vector2.DOWN
			match str(player.last_dir):
				"up": facing_vec = Vector2.UP
				"down": facing_vec = Vector2.DOWN
				"left": facing_vec = Vector2.LEFT
				"right": facing_vec = Vector2.RIGHT
			if aim_offset.length_squared() < 100.0:
				aim_offset = facing_vec * target_dist

	global_position = get_aim_world_position()

	# 5. Apertura dinámica de la cruceta según tensión del arco, movimiento y retroceso
	var base_gap: float = 4.0 if is_ranged_mode else 3.0
	if is_drawing_bow:
		base_gap = lerpf(7.0, 1.8, bow_tension)
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		base_gap = 2.0
	elif player.velocity.length_squared() > 100.0:
		base_gap += 2.2

	recoil_impulse = move_toward(recoil_impulse, 0.0, 22.0 * delta)
	target_gap = base_gap + recoil_impulse
	current_gap = lerpf(current_gap, target_gap, clampf(18.0 * delta, 0.0, 1.0))

	# 6. Detectar si el punto de mira está sobre un enemigo, animal o recurso (throttled a ~12 Hz)
	_target_color_timer -= delta
	if _target_color_timer <= 0.0:
		_target_color_timer = 0.08
		reticle_color = _detect_target_color()

	var rounded_gap := roundf(current_gap)
	if rounded_gap != _last_drawn_gap or not reticle_color.is_equal_approx(_last_drawn_color) or is_ranged_mode != _last_drawn_ranged or is_drawing_bow != _last_drawn_bow or absf(bow_tension - _last_drawn_tension) > 0.01:
		_last_drawn_gap = rounded_gap
		_last_drawn_color = reticle_color
		_last_drawn_ranged = is_ranged_mode
		_last_drawn_bow = is_drawing_bow
		_last_drawn_tension = bow_tension
		queue_redraw()

func _detect_target_color() -> Color:
	var mouse_pos := global_position
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy is Node2D:
			if enemy.global_position.distance_squared_to(mouse_pos) <= 256.0:
				return Color(1.0, 0.28, 0.28, 0.98)
	for animal in get_tree().get_nodes_in_group("wild_animals"):
		if is_instance_valid(animal) and animal is Node2D and animal.visible:
			if animal.global_position.distance_squared_to(mouse_pos) <= 225.0:
				return Color(1.0, 0.35, 0.25, 0.98)
	for res in get_tree().get_nodes_in_group("destructible"):
		if is_instance_valid(res) and res is Node2D and res.visible:
			if res.global_position.distance_squared_to(mouse_pos) <= 324.0:
				return Color(1.0, 0.85, 0.35, 0.95)
	return Color(0.55, 0.95, 1.0, 0.95) if is_ranged_mode else Color(0.98, 0.96, 0.88, 0.92)

func _draw() -> void:
	var outline := Color(0.05, 0.06, 0.08, 0.92)
	var g := roundf(current_gap)
	var tick_len: float = 4.0 if is_ranged_mode else 3.0

	draw_rect(Rect2(-1.5, -1.5, 3.0, 3.0), outline)
	draw_rect(Rect2(-0.5, -0.5, 1.0, 1.0), reticle_color)

	var dirs := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for d in dirs:
		var start: Vector2 = d * g
		var end_pt: Vector2 = d * (g + tick_len)
		draw_line(start, end_pt, outline, 3.0)
		draw_line(start, end_pt, reticle_color, 1.2)

	if is_drawing_bow:
		var bar_w := 16.0
		var bar_h := 2.5
		var bar_pos := Vector2(-bar_w * 0.5, g + tick_len + 3.0)
		draw_rect(Rect2(bar_pos - Vector2(1, 1), Vector2(bar_w + 2, bar_h + 2)), outline)
		var tension_col := Color(1.0, 0.72, 0.25).lerp(Color(0.35, 1.0, 0.65), bow_tension)
		draw_rect(Rect2(bar_pos, Vector2(bar_w * bow_tension, bar_h)), tension_col)

func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
