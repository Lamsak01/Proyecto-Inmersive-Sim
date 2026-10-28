extends Node2D
class_name Crosshair2D

## Punto de Mira Dinámico (Estilo Enter the Gungeon / Zero Sievert / Nuclear Throne)
## Sigue al cursor del ratón en el mundo (y también soporta las Flechas del teclado por si se juega con Touchpad en Linux),
## reacciona al movimiento/disparo (spread) y cambia de color al apuntar sobre enemigos, animales o recursos.

var player: CharacterBody2D = null
var current_gap: float = 4.0
var target_gap: float = 4.0
var recoil_impulse: float = 0.0
var reticle_color: Color = Color(0.98, 0.96, 0.88, 0.95)
var is_ranged_mode: bool = false
var is_drawing_bow: bool = false
var bow_tension: float = 0.0 # 0.0 (sin tensar) a 1.0 (máxima tensión)

# Offset relativo al jugador para que el punto de mira acompañe al jugador al caminar
var aim_offset: Vector2 = Vector2(45, 0)
var _last_mouse_local: Vector2 = Vector2.ZERO

func _ready() -> void:
	z_index = 100
	top_level = true
	if is_instance_valid(player):
		_last_mouse_local = player.get_local_mouse_position()
		if _last_mouse_local.length_squared() > 4.0:
			aim_offset = _last_mouse_local

func add_recoil(amount: float = 5.0) -> void:
	recoil_impulse = min(10.0, recoil_impulse + amount)

func get_aim_world_position() -> Vector2:
	if is_instance_valid(player):
		return player.global_position + Vector2(0, -10) + aim_offset
	return global_position

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	# Si hay un menú o diálogo abierto, mostrar el cursor del sistema y ocultar el punto de mira
	var ui_open := false
	var dm = player.get("dialogue_manager")
	if dm and dm.has_method("is_active") and dm.call("is_active"):
		ui_open = true
	var inv_panel = get_tree().root.find_child("InventoryPanel", true, false)
	if inv_panel and inv_panel.visible:
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

	# 1. Seguir movimiento del ratón (relativo al jugador para que no se quede atrás al caminar)
	var cur_mouse_local: Vector2 = player.get_local_mouse_position() - Vector2(0, -10)
	if cur_mouse_local.distance_squared_to(_last_mouse_local) > 0.5:
		_last_mouse_local = cur_mouse_local
		aim_offset = cur_mouse_local

	# 2. Soporte adicional con Flechas del Teclado (por si el Touchpad de Linux bloquea el ratón al pulsar WASD)
	var arrow_input := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if arrow_input.length_squared() > 0.01:
		aim_offset += arrow_input.normalized() * 160.0 * delta
		aim_offset = aim_offset.limit_length(150.0)

	global_position = get_aim_world_position()

	# 3. Calcular apertura dinámica de la cruceta según tensión del arco, movimiento, clic derecho y retroceso
	var base_gap: float = 4.0 if is_ranged_mode else 3.0
	if is_drawing_bow:
		# Al tensar el arco, la cruceta empieza abierta (7.0) y se cierra al máximo (1.8) al llegar al 100% de tensión
		base_gap = lerpf(7.0, 1.8, bow_tension)
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		base_gap = 2.0 # Mayor precisión al apuntar con Clic Derecho
	elif player.velocity.length_squared() > 100.0:
		base_gap += 2.2

	recoil_impulse = move_toward(recoil_impulse, 0.0, 22.0 * delta)
	target_gap = base_gap + recoil_impulse
	current_gap = lerpf(current_gap, target_gap, clampf(18.0 * delta, 0.0, 1.0))

	# 4. Detectar si el punto de mira está sobre un enemigo/animal o recurso para cambiar de color
	reticle_color = _detect_target_color()
	queue_redraw()

func _detect_target_color() -> Color:
	var mouse_pos := global_position
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy is Node2D:
			if enemy.global_position.distance_squared_to(mouse_pos) <= 256.0:
				return Color(1.0, 0.28, 0.28, 0.98) # Rojo sobre enemigos
	for animal in get_tree().get_nodes_in_group("wild_animals"):
		if is_instance_valid(animal) and animal is Node2D and animal.visible:
			if animal.global_position.distance_squared_to(mouse_pos) <= 225.0:
				return Color(1.0, 0.35, 0.25, 0.98) # Rojo/Naranja sobre animales de caza
	for res in get_tree().get_nodes_in_group("destructible"):
		if is_instance_valid(res) and res is Node2D and res.visible:
			if res.global_position.distance_squared_to(mouse_pos) <= 324.0:
				return Color(1.0, 0.85, 0.35, 0.95) # Dorado sobre árboles/rocas/cajas
	return Color(0.55, 0.95, 1.0, 0.95) if is_ranged_mode else Color(0.98, 0.96, 0.88, 0.92)

func _draw() -> void:
	var outline := Color(0.05, 0.06, 0.08, 0.92)
	var g := roundf(current_gap)
	var tick_len: float = 4.0 if is_ranged_mode else 3.0

	# 1. Punto central nítido (con borde oscuro)
	draw_rect(Rect2(-1.5, -1.5, 3.0, 3.0), outline)
	draw_rect(Rect2(-0.5, -0.5, 1.0, 1.0), reticle_color)

	# 2. Las 4 patillas de la cruceta (Arriba, Abajo, Izquierda, Derecha)
	var dirs := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for d in dirs:
		var start: Vector2 = d * g
		var end_pt: Vector2 = d * (g + tick_len)
		draw_line(start, end_pt, outline, 3.0)
		draw_line(start, end_pt, reticle_color, 1.2)

	# 3. Barra de Tensión del Arco bajo el Punto de Mira mientras tensas la cuerda
	if is_drawing_bow:
		var bar_w := 16.0
		var bar_h := 2.5
		var bar_pos := Vector2(-bar_w * 0.5, g + tick_len + 3.0)
		draw_rect(Rect2(bar_pos - Vector2(1, 1), Vector2(bar_w + 2, bar_h + 2)), outline)
		var tension_col := Color(1.0, 0.72, 0.25).lerp(Color(0.35, 1.0, 0.65), bow_tension)
		draw_rect(Rect2(bar_pos, Vector2(bar_w * bow_tension, bar_h)), tension_col)

func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
