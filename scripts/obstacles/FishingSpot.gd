@tool
extends Node2D
class_name FishingSpot

## Lago y Muelle de Pesca Sistémico — Fase 4.5 (Pesca e Hidrología)
## - Permite pescar con [E] en el muelle (equipa automáticamente la Caña de Pescar [8] si la tienes).
## - Minijuego ágil de reacción: Lanzar línea -> Esperar picada (1.3s - 2.3s) -> ¡PICÓ! Pulsar [E] en la ventana (1.6s).
## - Especies según la hora de WorldClock:
##   * Día (06:00 - 17:59): Trucha de Río (65%) y Carpa Dorada (35%).
##   * Atardecer / Noche (18:00 - 05:59): Siluro Nocturno (70%) y Carpa Dorada (30%).
## - También permite rellenar la Regadera [7] al 100% en la orilla del lago.

enum FishState { IDLE, WAITING_BITE, BITE_ACTIVE, MINIGAME }

var state: FishState = FishState.IDLE
var _timer: float = 0.0
var _wave_time: float = 0.0
var _active_fisher: Node2D = null

# Variables del Minijuego de Precisión (Estilo Stardew Valley)
var _hooked_fish_id: String = "river_trout"
var _fish_pos: float = 0.5
var _fish_target: float = 0.5
var _fish_vel: float = 0.0
var _fish_ai_timer: float = 0.0
var _bar_pos: float = 0.35
var _bar_vel: float = 0.0
var _bar_size: float = 0.30
var _catch_progress: float = 0.35
var _is_fish_inside: bool = false

var dock_pos: Vector2 = Vector2(36, 0)
var interact_area: Area2D = null
var status_label: Label = null
var bobber_poly: Polygon2D = null
var fishing_line: Line2D = null
var ripple_sprites: Array[Sprite2D] = []
var ripple_base_positions: Array[Vector2] = []

const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

func _ready() -> void:
	set_process(not Engine.is_editor_hint())
	add_to_group("fishing_spots")
	_build_lake_visuals()
	_build_interaction_zone()

func _build_lake_visuals() -> void:
	# 1. Orilla de arena húmeda
	var shore_poly := Polygon2D.new()
	shore_poly.polygon = PackedVector2Array([
		Vector2(-52, -36), Vector2(-18, -46), Vector2(24, -40), Vector2(46, -18),
		Vector2(48, 18), Vector2(26, 42), Vector2(-20, 46), Vector2(-54, 32),
		Vector2(-64, 0)
	])
	shore_poly.color = Color(0.56, 0.48, 0.34, 0.88)
	shore_poly.z_index = -3
	add_child(shore_poly)

	# 2. Agua exterior del lago
	var water_poly := Polygon2D.new()
	water_poly.polygon = PackedVector2Array([
		Vector2(-46, -30), Vector2(-16, -40), Vector2(18, -34), Vector2(38, -14),
		Vector2(40, 14), Vector2(20, 35), Vector2(-18, 39), Vector2(-48, 26),
		Vector2(-56, 0)
	])
	water_poly.color = Color(0.14, 0.42, 0.68, 0.94)
	water_poly.z_index = -2
	add_child(water_poly)

	# 3. Agua profunda interior
	var deep_poly := Polygon2D.new()
	deep_poly.polygon = PackedVector2Array([
		Vector2(-32, -20), Vector2(-10, -27), Vector2(10, -22), Vector2(24, -8),
		Vector2(24, 9), Vector2(10, 23), Vector2(-12, 26), Vector2(-34, 16),
		Vector2(-40, 0)
	])
	deep_poly.color = Color(0.09, 0.30, 0.54, 0.92)
	deep_poly.z_index = -2
	add_child(deep_poly)

	# 4. Muelle de madera al Este (hacia el gallinero/huerto)
	var dock_poly := Polygon2D.new()
	dock_poly.polygon = PackedVector2Array([
		Vector2(14, -9), Vector2(50, -9), Vector2(50, 9), Vector2(14, 9)
	])
	dock_poly.color = Color(0.46, 0.30, 0.16, 1.0)
	dock_poly.z_index = -1
	add_child(dock_poly)

	var dock_border := Line2D.new()
	dock_border.width = 2.0
	dock_border.default_color = Color(0.28, 0.18, 0.09, 1.0)
	dock_border.points = PackedVector2Array([
		Vector2(14, -9), Vector2(50, -9), Vector2(50, 9), Vector2(14, 9), Vector2(14, -9)
	])
	dock_border.z_index = -1
	add_child(dock_border)

	# 5. Cartel del Lago
	var sign_lbl := Label.new()
	sign_lbl.text = "🎣 Lago del Oeste"
	sign_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_lbl.position = Vector2(-80, -60)
	sign_lbl.custom_minimum_size = Vector2(160, 18)
	sign_lbl.add_theme_font_size_override("font_size", 9)
	sign_lbl.add_theme_color_override("font_color", Color(0.65, 0.92, 1.0))
	sign_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	sign_lbl.add_theme_constant_override("outline_size", 3)
	add_child(sign_lbl)

	# 6. Ondas y sombras de peces animadas
	var tex_ripples := _load_tex("res://assests/world/fishing/fish_spot_ripples.png")
	ripple_base_positions = [
		Vector2(-12, -10),
		Vector2(-26, 10),
		Vector2(2, 14)
	]
	for pos in ripple_base_positions:
		var spr := Sprite2D.new()
		spr.texture = tex_ripples
		spr.position = pos
		spr.scale = Vector2(1.15, 1.15)
		spr.z_index = -1
		add_child(spr)
		ripple_sprites.append(spr)

	# 7. Sedal y Boya (visibles al lanzar la caña)
	fishing_line = Line2D.new()
	fishing_line.width = 1.2
	fishing_line.default_color = Color(0.92, 0.95, 1.0, 0.85)
	fishing_line.visible = false
	fishing_line.z_index = 4
	add_child(fishing_line)

	bobber_poly = Polygon2D.new()
	bobber_poly.polygon = PackedVector2Array([
		Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)
	])
	bobber_poly.color = Color(1.0, 0.25, 0.20, 1.0)
	bobber_poly.position = Vector2(-8, 0)
	bobber_poly.visible = false
	bobber_poly.z_index = 5
	add_child(bobber_poly)

func _build_interaction_zone() -> void:
	interact_area = Area2D.new()
	interact_area.name = "FishingInteractArea"
	interact_area.position = dock_pos
	interact_area.collision_layer = 1
	interact_area.collision_mask = 2
	interact_area.add_to_group("interactable")
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 28.0
	col.shape = c
	interact_area.add_child(col)
	add_child(interact_area)

	status_label = Label.new()
	status_label.visible = false
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-125, -42)
	status_label.custom_minimum_size = Vector2(250, 22)
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0))
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 3)
	status_label.z_index = 25
	add_child(status_label)

func _process(delta: float) -> void:
	_wave_time += delta * 2.6
	for i in range(ripple_sprites.size()):
		var spr: Sprite2D = ripple_sprites[i]
		var base_p: Vector2 = ripple_base_positions[i]
		spr.position = base_p + Vector2(sin(_wave_time + float(i) * 1.7) * 3.0, cos(_wave_time * 0.8 + float(i)) * 2.0)
		var s_pulse: float = 1.10 + sin(_wave_time * 1.5 + float(i)) * 0.12
		spr.scale = Vector2(s_pulse, s_pulse)

	var player = get_tree().get_first_node_in_group("player") as Node2D
	var dock_world: Vector2 = global_position + dock_pos

	if state != FishState.IDLE:
		# Si el jugador se aleja demasiado del muelle, cancelar la pesca
		if not is_instance_valid(_active_fisher) or _active_fisher.global_position.distance_squared_to(dock_world) > 56.0 * 56.0:
			_cancel_fishing("🎣 Línea recogida (te alejaste de la orilla)")
			return

		if fishing_line and bobber_poly:
			var fisher_local: Vector2 = to_local(_active_fisher.global_position + Vector2(0, -6))
			fishing_line.points = PackedVector2Array([fisher_local, bobber_poly.position])

		_timer -= delta
		if state == FishState.WAITING_BITE:
			bobber_poly.position = Vector2(-10, sin(_wave_time * 3.0) * 2.0)
			bobber_poly.color = Color(1.0, 0.30, 0.25, 1.0)
			if _timer <= 0.0:
				state = FishState.BITE_ACTIVE
				_timer = 1.65
				_spawn_floating_text("💦 ¡PICÓ! ¡Pulsa [E]!", Color.GOLD, -24.0)
		elif state == FishState.BITE_ACTIVE:
			bobber_poly.position = Vector2(-10 + sin(_wave_time * 18.0) * 3.5, cos(_wave_time * 18.0) * 3.5)
			bobber_poly.color = Color(0.35, 1.0, 0.45, 1.0)
			if _timer <= 0.0:
				_cancel_fishing("💨 ¡El pez se soltó del anzuelo!")
				return
		elif state == FishState.MINIGAME:
			bobber_poly.position = Vector2(-10 + sin(_wave_time * 14.0) * 2.5, cos(_wave_time * 12.0) * 2.5)
			bobber_poly.color = Color(0.30, 0.90, 1.0, 1.0)
			_update_minigame(delta)
			queue_redraw()

	_update_status_label(player, dock_world)

func _update_status_label(player: Node2D, dock_world: Vector2) -> void:
	if not status_label:
		return
	var near_player: bool = player != null and player.global_position.distance_squared_to(dock_world) <= 38.0 * 38.0
	var near_mouse: bool = global_position.distance_squared_to(get_global_mouse_position()) <= 48.0 * 48.0

	if state == FishState.WAITING_BITE:
		status_label.text = "🎣 Esperando picada... (Atento para pulsar [E])"
		status_label.add_theme_color_override("font_color", Color(0.65, 0.95, 1.0))
		status_label.visible = true
		return
	elif state == FishState.BITE_ACTIVE:
		status_label.text = "🐟 ¡¡PICÓ UN PEZ!! ¡Pulsa [E] para enganchar! (%.1fs)" % maxf(0.0, _timer)
		status_label.add_theme_color_override("font_color", Color(0.40, 1.0, 0.45))
		status_label.visible = true
		return
	elif state == FishState.MINIGAME:
		var fish_title: String = "Trucha"
		if _hooked_fish_id == "golden_carp":
			fish_title = "Carpa Dorada"
		elif _hooked_fish_id == "night_catfish":
			fish_title = "Siluro Nocturno"
		status_label.text = "🎣 [%s] Mantén [E / Espacio / Clic] para subir la barra (%d%%)" % [fish_title, int(round(_catch_progress * 100.0))]
		status_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.65) if _is_fish_inside else Color(1.0, 0.72, 0.35))
		status_label.visible = true
		return

	if near_player or near_mouse:
		var time_hint := "Día: Trucha/Carpa"
		if WorldClock and (WorldClock.current_hour >= 18 or WorldClock.current_hour < 6):
			time_hint = "Noche: Siluro/Carpa"
		status_label.text = "🎣 Muelle de Pesca [%s | E: Pescar / Llenar Regadera]" % time_hint
		status_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
		status_label.visible = true
	else:
		status_label.visible = false

func interact(player: Node2D) -> void:
	if not player:
		return

	# Si el jugador lleva la Regadera equipada y no está llena, llenarla primero
	if "equipped_weapon" in player and player.equipped_weapon and player.equipped_weapon.name == "WateringCan":
		if "watering_can_charges" in player and "max_water_charges" in player:
			if int(player.watering_can_charges) < int(player.max_water_charges):
				if player.has_method("refill_watering_can"):
					player.call("refill_watering_can")
					return

	if state == FishState.IDLE:
		# Equipar automáticamente la Caña de Pescar [8] para comodidad visual
		if "fishing_rod_weapon" in player and player.fishing_rod_weapon and player.has_method("equip_weapon"):
			player.call("equip_weapon", player.fishing_rod_weapon)
		_active_fisher = player
		state = FishState.WAITING_BITE
		_timer = randf_range(1.25, 2.25)
		if bobber_poly:
			bobber_poly.visible = true
		if fishing_line:
			fishing_line.visible = true
		_spawn_floating_text("🎣 Línea lanzada...", Color.AQUA, -22.0)
		return

	if state == FishState.WAITING_BITE:
		_cancel_fishing("💨 Recogiste el anzuelo demasiado pronto")
		return

	if state == FishState.BITE_ACTIVE:
		_start_minigame(player)
		return

	if state == FishState.MINIGAME:
		# Durante el minijuego, mantener [E] impulsa la barra hacia arriba (no cancela)
		return

func _start_minigame(player: Node2D) -> void:
	state = FishState.MINIGAME
	_active_fisher = player

	var is_night_fish := false
	if WorldClock:
		var h: int = WorldClock.current_hour
		is_night_fish = (h >= 18 or h < 6)

	var roll := randf()
	if is_night_fish:
		_hooked_fish_id = "night_catfish" if roll < 0.70 else "golden_carp"
	else:
		_hooked_fish_id = "river_trout" if roll < 0.65 else "golden_carp"

	var rod_mult: float = 1.0
	if player and player.has_method("get_fishing_bar_multiplier"):
		rod_mult = float(player.call("get_fishing_bar_multiplier"))
	_bar_size = clampf(0.28 * rod_mult, 0.24, 0.52)
	_bar_pos = 0.30
	_bar_vel = 0.0
	_fish_pos = 0.35
	_fish_target = 0.65
	_fish_vel = 0.0
	_fish_ai_timer = 0.4
	_catch_progress = 0.36
	_is_fish_inside = true
	_spawn_floating_text("🎣 ¡Enganchado! ¡Mantén al pez en la barra verde!", Color.SPRING_GREEN, -26.0)
	queue_redraw()

func _update_minigame(delta: float) -> void:
	# 1. Control de la Barra Verde por el jugador (Mantener [E], [Espacio] o Clic Izquierdo)
	var thrust_pressed: bool = (
		Input.is_key_pressed(KEY_E)
		or Input.is_key_pressed(KEY_SPACE)
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	)
	var accel: float = 1.85 if thrust_pressed else -1.55
	_bar_vel = clampf(_bar_vel + accel * delta, -1.15, 1.15)
	_bar_pos += _bar_vel * delta

	var half_bar: float = _bar_size * 0.5
	if _bar_pos < half_bar:
		_bar_pos = half_bar
		_bar_vel = maxf(0.0, -_bar_vel * 0.28)
	elif _bar_pos > 1.0 - half_bar:
		_bar_pos = 1.0 - half_bar
		_bar_vel = minf(0.0, -_bar_vel * 0.25)

	# 2. Movimiento del Pez según su especie
	_fish_ai_timer -= delta
	if _fish_ai_timer <= 0.0:
		match _hooked_fish_id:
			"river_trout":
				_fish_ai_timer = randf_range(0.75, 1.35)
				_fish_target = clampf(_fish_pos + randf_range(-0.32, 0.32), 0.10, 0.90)
			"golden_carp":
				_fish_ai_timer = randf_range(0.48, 0.95)
				_fish_target = randf_range(0.12, 0.88)
			"night_catfish":
				_fish_ai_timer = randf_range(0.32, 0.72)
				_fish_target = randf_range(0.08, 0.92)

	var fish_speed: float = 0.58
	if _hooked_fish_id == "golden_carp":
		fish_speed = 0.82
	elif _hooked_fish_id == "night_catfish":
		fish_speed = 1.12

	_fish_pos = move_toward(_fish_pos, _fish_target, fish_speed * delta)

	# 3. Comprobar si el pez está dentro de la barra verde
	_is_fish_inside = absf(_fish_pos - _bar_pos) <= (half_bar + 0.03)
	if _is_fish_inside:
		_catch_progress += 0.42 * delta
	else:
		_catch_progress -= 0.20 * delta

	_catch_progress = clampf(_catch_progress, 0.0, 1.0)
	if _catch_progress >= 1.0:
		_complete_catch(_active_fisher)
	elif _catch_progress <= 0.0:
		_cancel_fishing("💨 ¡El pez se escapó de la barra!")

func _draw() -> void:
	if state != FishState.MINIGAME:
		return
	var panel_pos := Vector2(56, -56)
	var col_w: float = 16.0
	var col_h: float = 104.0

	# Marco exterior
	draw_rect(Rect2(panel_pos - Vector2(4, 4), Vector2(col_w + 18.0, col_h + 8.0)), Color(0.08, 0.09, 0.13, 0.95), true)
	draw_rect(Rect2(panel_pos - Vector2(4, 4), Vector2(col_w + 18.0, col_h + 8.0)), Color(0.78, 0.64, 0.34, 1.0), false, 1.6)

	# Columna de agua
	draw_rect(Rect2(panel_pos, Vector2(col_w, col_h)), Color(0.10, 0.26, 0.46, 0.95), true)

	# Barra verde del jugador (invertida en Y: 0.0 abajo, 1.0 arriba)
	var bar_h: float = _bar_size * col_h
	var bar_center_y: float = panel_pos.y + (1.0 - _bar_pos) * col_h
	var bar_rect := Rect2(Vector2(panel_pos.x + 1.0, bar_center_y - bar_h * 0.5), Vector2(col_w - 2.0, bar_h))
	var bar_col: Color = Color(0.32, 0.95, 0.45, 0.88) if _is_fish_inside else Color(0.85, 0.72, 0.28, 0.75)
	draw_rect(bar_rect, bar_col, true)
	draw_rect(bar_rect, Color(0.92, 1.0, 0.92, 0.95), false, 1.2)

	# Icono del pez dentro de la columna
	var fish_y: float = panel_pos.y + (1.0 - _fish_pos) * col_h
	var fish_center := Vector2(panel_pos.x + col_w * 0.5, fish_y)
	var fish_col: Color = Color(0.95, 0.78, 0.22) if _hooked_fish_id == "golden_carp" else (Color(0.68, 0.45, 0.95) if _hooked_fish_id == "night_catfish" else Color(1.0, 0.52, 0.32))
	draw_circle(fish_center, 4.5, fish_col)
	draw_circle(fish_center + Vector2(1.5, -1.0), 1.2, Color.BLACK)

	# Barra lateral de progreso de captura (0% a 100%)
	var prog_x: float = panel_pos.x + col_w + 4.0
	var prog_w: float = 6.0
	draw_rect(Rect2(Vector2(prog_x, panel_pos.y), Vector2(prog_w, col_h)), Color(0.18, 0.18, 0.22, 0.95), true)
	var fill_h: float = _catch_progress * col_h
	var prog_col: Color = Color(0.25, 0.95, 0.42) if _catch_progress >= 0.6 else (Color(0.95, 0.80, 0.25) if _catch_progress >= 0.3 else Color(0.95, 0.32, 0.28))
	draw_rect(Rect2(Vector2(prog_x, panel_pos.y + col_h - fill_h), Vector2(prog_w, fill_h)), prog_col, true)

func _complete_catch(player: Node2D) -> void:
	state = FishState.IDLE
	_active_fisher = null
	queue_redraw()
	if bobber_poly:
		bobber_poly.visible = false
	if fishing_line:
		fishing_line.visible = false

	var inv: SimpleInventory = player.get("inventory") if player else null
	if not inv:
		return

	var caught_id: String = _hooked_fish_id if _hooked_fish_id != "" else "river_trout"
	inv.add_item(caught_id, 1)
	var fish_name: String = inv.get_item_name(caught_id)
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🐟 ¡Pescaste: %s!" % fish_name, Color.GOLD, -42.0)
	if player.has_method("show_hint"):
		player.show_hint("🎣 ¡Captura perfecta! Has pescado 1 %s. Puedes cocinarlo en la Hoguera o vendérselo a Marlo." % fish_name)

func _cancel_fishing(msg: String) -> void:
	state = FishState.IDLE
	_active_fisher = null
	queue_redraw()
	if bobber_poly:
		bobber_poly.visible = false
	if fishing_line:
		fishing_line.visible = false
	if msg != "":
		_spawn_floating_text(msg, Color(0.95, 0.75, 0.45), -22.0)

func cancel_fishing() -> void:
	if state != FishState.IDLE:
		_cancel_fishing("")

func _spawn_floating_text(text: String, color: Color, offset_y: float = -28.0) -> void:
	if FloatingTextScene:
		var ft = FloatingTextScene.instantiate()
		ft.start_text = text
		ft.text_color = color
		ft.global_position = global_position + Vector2(0, offset_y)
		get_tree().current_scene.add_child(ft)

func _load_tex(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var t = load(res_path)
		if t is Texture2D:
			return t
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null
