extends Node2D
class_name CampSite

## Campamento Completo del Jugador (Tienda de Campaña + Hoguera con Cacerola + Tronco para Sentarse AFK) — Fase 4.1b
## 1. ⛺ Tienda de Campaña: Exclusiva para dormir de noche (20:00 - 06:00). Al pulsar [E] abre un cuadro de
##    confirmación ("¿Quieres ir a dormir?") con opciones [Sí] / [No].
## 2. 🍲 Hoguera con Cacerola: Al pulsar [E] cocina Carne Cruda -> Carne Cocida, Verdura -> Verdura Cocida y Huevo -> Huevo Cocido.
## 3. 🪵 Tronco para Sentarse: Área de acción pequeña y precisa. Al pulsar [E] el personaje únicamente se sienta
##    a descansar (modo AFK: el hambre y el sueño bajan un 85% más lento sin saltar el tiempo).

const TENT_OFFSET := Vector2(-34, -8)
const POT_OFFSET := Vector2(0, 4)
const SEAT_OFFSET := Vector2(24, 4)

var tent_sprite: Sprite2D = null
var pot_sprite: Sprite2D = null
var seat_sprite: Sprite2D = null

var tent_label: Label = null
var pot_label: Label = null
var seat_label: Label = null

var _near_tent: bool = false
var _near_pot: bool = false
var _near_seat: bool = false
var _flame_phase: float = 0.0

var is_player_sitting: bool = false
var _sitting_player: Node2D = null
var _sit_grace_timer: float = 0.0

var sleep_confirm_layer: CanvasLayer = null
var sleep_confirm_panel: PanelContainer = null

func _ready() -> void:
	_setup_tent()
	_setup_campfire_pot()
	_setup_log_seat()
	_setup_sleep_confirm_ui()

func _process(delta: float) -> void:
	_flame_phase += delta * 7.5
	if pot_sprite:
		var pulse := 1.0 + sin(_flame_phase) * 0.03
		pot_sprite.scale = Vector2(1.25 * pulse, 1.25 * pulse)

	# Control del modo Sentado / AFK en el tronco
	if is_player_sitting and is_instance_valid(_sitting_player):
		if _sit_grace_timer > 0.0:
			_sit_grace_timer -= delta
		else:
			var vel: Vector2 = _sitting_player.get("velocity") if "velocity" in _sitting_player else Vector2.ZERO
			if vel.length_squared() > 25.0:
				_stand_up_player()

	var mouse_pos := get_global_mouse_position()
	var player = get_tree().get_first_node_in_group("player") as Node2D
	var tent_world := global_position + TENT_OFFSET + Vector2(0, 6)
	var pot_world := global_position + POT_OFFSET
	var seat_world := global_position + SEAT_OFFSET

	_near_tent = player != null and player.global_position.distance_squared_to(tent_world) <= 22.0 * 22.0
	_near_pot = player != null and player.global_position.distance_squared_to(pot_world) <= 20.0 * 20.0
	_near_seat = player != null and player.global_position.distance_squared_to(seat_world) <= 15.0 * 15.0

	if tent_label:
		var m_tent := tent_world.distance_squared_to(mouse_pos) <= 14.0 * 14.0
		if _near_tent or m_tent:
			tent_label.text = _get_tent_prompt()
			tent_label.visible = true
		else:
			tent_label.visible = false

	if pot_label:
		var m_pot := pot_world.distance_squared_to(mouse_pos) <= 12.0 * 12.0
		if _near_pot or m_pot:
			pot_label.text = _get_pot_prompt()
			pot_label.visible = true
		else:
			pot_label.visible = false

	if seat_label:
		var m_seat := seat_world.distance_squared_to(mouse_pos) <= 10.0 * 10.0
		if _near_seat or m_seat or is_player_sitting:
			seat_label.text = _get_seat_prompt()
			seat_label.visible = true
		else:
			seat_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if sleep_confirm_panel and sleep_confirm_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_1, KEY_Y, KEY_S, KEY_ENTER, KEY_KP_ENTER]:
				_on_sleep_confirmed()
				get_viewport().set_input_as_handled()
			elif event.keycode in [KEY_2, KEY_N, KEY_ESCAPE]:
				_on_sleep_cancelled()
				get_viewport().set_input_as_handled()

# --- 1. TIENDA DE CAMPAÑA (Exclusiva para dormir de noche con pregunta Sí/No) ---
func _setup_tent() -> void:
	var tent_body := StaticBody2D.new()
	tent_body.name = "TentBody"
	tent_body.position = TENT_OFFSET
	add_child(tent_body)

	tent_sprite = Sprite2D.new()
	tent_sprite.texture = _load_tex("res://assests/world/camp/camp_tent.png")
	tent_sprite.scale = Vector2(1.3, 1.3)
	tent_body.add_child(tent_sprite)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 16)
	col.shape = rect
	col.position = Vector2(0, 2)
	tent_body.add_child(col)

	var area := Area2D.new()
	area.name = "TentInteractArea"
	area.position = TENT_OFFSET + Vector2(0, 6)
	area.collision_layer = 1
	area.collision_mask = 2
	area.add_to_group("interactable")
	var acol := CollisionShape2D.new()
	var ac := CircleShape2D.new()
	ac.radius = 5.0
	acol.shape = ac
	area.add_child(acol)
	add_child(area)

	tent_label = _create_label(TENT_OFFSET + Vector2(-115, -30), Color(0.95, 0.92, 0.72))
	add_child(tent_label)

# --- 2. HOGUERA CON CACEROLA (Cocinar Carne / Verduras / Huevos) ---
func _setup_campfire_pot() -> void:
	var pot_node := StaticBody2D.new()
	pot_node.name = "CampfirePotBody"
	pot_node.position = POT_OFFSET
	add_child(pot_node)

	pot_sprite = Sprite2D.new()
	pot_sprite.texture = _load_tex("res://assests/world/camp/campfire_pot.png")
	pot_sprite.scale = Vector2(1.25, 1.25)
	pot_node.add_child(pot_sprite)

	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 8.0
	col.shape = c
	pot_node.add_child(col)

	var area := Area2D.new()
	area.name = "PotInteractArea"
	area.position = POT_OFFSET
	area.collision_layer = 1
	area.collision_mask = 2
	area.add_to_group("interactable")
	var acol := CollisionShape2D.new()
	var ac := CircleShape2D.new()
	ac.radius = 5.0
	acol.shape = ac
	area.add_child(acol)
	add_child(area)

	pot_label = _create_label(POT_OFFSET + Vector2(-115, -32), Color(1.0, 0.85, 0.45))
	add_child(pot_label)

# --- 3. TRONCO PARA SENTARSE (Área pequeña; solo sentarse en modo descanso/AFK) ---
func _setup_log_seat() -> void:
	seat_sprite = Sprite2D.new()
	seat_sprite.name = "LogSeatSprite"
	seat_sprite.texture = _load_tex("res://assests/world/camp/camp_log_seat.png")
	seat_sprite.position = SEAT_OFFSET
	seat_sprite.scale = Vector2(1.15, 1.15)
	add_child(seat_sprite)

	var area := Area2D.new()
	area.name = "SeatInteractArea"
	area.position = SEAT_OFFSET
	area.collision_layer = 1
	area.collision_mask = 2
	area.add_to_group("interactable")
	var acol := CollisionShape2D.new()
	var ac := CircleShape2D.new()
	ac.radius = 4.0 # Área de acción muy reducida y precisa
	acol.shape = ac
	area.add_child(acol)
	add_child(area)

	seat_label = _create_label(SEAT_OFFSET + Vector2(-115, -26), Color(0.72, 0.92, 1.0))
	add_child(seat_label)

func _setup_sleep_confirm_ui() -> void:
	sleep_confirm_layer = CanvasLayer.new()
	sleep_confirm_layer.layer = 30
	add_child(sleep_confirm_layer)

	sleep_confirm_panel = PanelContainer.new()
	sleep_confirm_panel.visible = false
	sleep_confirm_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	sleep_confirm_panel.offset_left = -165.0
	sleep_confirm_panel.offset_top = -65.0
	sleep_confirm_panel.offset_right = 165.0
	sleep_confirm_panel.offset_bottom = 65.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.13, 0.96)
	style.border_color = Color(0.82, 0.68, 0.36, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	sleep_confirm_panel.add_theme_stylebox_override("panel", style)
	sleep_confirm_layer.add_child(sleep_confirm_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sleep_confirm_panel.add_child(vbox)

	var question_lbl := Label.new()
	question_lbl.text = "⛺ ¿Quieres ir a dormir?\n(Amanecerá a las 06:00 AM)"
	question_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_lbl.add_theme_font_size_override("font_size", 14)
	question_lbl.add_theme_color_override("font_color", Color(0.96, 0.94, 0.84))
	vbox.add_child(question_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var yes_btn := Button.new()
	yes_btn.text = "  [1] Sí, dormir  "
	yes_btn.pressed.connect(_on_sleep_confirmed)
	btn_row.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "  [2] No  "
	no_btn.pressed.connect(_on_sleep_cancelled)
	btn_row.add_child(no_btn)

func interact(player: Node2D) -> void:
	if not player:
		return
	var tent_world: Vector2 = global_position + TENT_OFFSET + Vector2(0, 6)
	var pot_world: Vector2 = global_position + POT_OFFSET
	var seat_world: Vector2 = global_position + SEAT_OFFSET

	var d_tent: float = player.global_position.distance_squared_to(tent_world)
	var d_pot: float = player.global_position.distance_squared_to(pot_world)
	var d_seat: float = player.global_position.distance_squared_to(seat_world)

	if is_player_sitting:
		_stand_up_player()
		return

	if d_tent <= d_pot and d_tent <= d_seat and d_tent <= 24.0 * 24.0:
		_interact_tent(player)
	elif d_seat < d_pot and d_seat <= 16.0 * 16.0:
		_interact_seat(player)
	elif d_pot <= 22.0 * 22.0:
		_interact_pot(player)

func _interact_tent(player: Node2D) -> void:
	var is_night := false
	if WorldClock:
		var h: int = WorldClock.current_hour
		is_night = (h >= 20 or h < 6)

	if not is_night:
		if player.has_method("show_hint"):
			player.show_hint("⛺ Aún es de día. Solo puedes dormir en la tienda de campaña por la noche (20:00 - 06:00).")
		return

	if sleep_confirm_panel:
		sleep_confirm_panel.visible = true

func _on_sleep_confirmed() -> void:
	if sleep_confirm_panel:
		sleep_confirm_panel.visible = false
	var player = get_tree().get_first_node_in_group("player")
	if is_player_sitting:
		_stand_up_player()
	if player:
		var surv: SurvivalComponent = player.get_node_or_null("SurvivalComponent")
		var stam: StaminaComponent = player.get_node_or_null("StaminaComponent")
		var health: HealthComponent = player.get_node_or_null("HealthComponent")
		if surv:
			surv.restore_sleep(100.0)
		if stam:
			stam.current_stamina = stam.max_stamina
			stam.stamina_changed.emit(stam.current_stamina, stam.max_stamina)
		if health:
			health.heal(25.0)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("☀️ Has dormido hasta el amanecer (+100% Sueño)", Color.SKY_BLUE, -44.0)
	if WorldClock:
		WorldClock.sleep_until_morning()

func _on_sleep_cancelled() -> void:
	if sleep_confirm_panel:
		sleep_confirm_panel.visible = false

func _interact_seat(player: Node2D) -> void:
	if is_player_sitting:
		_stand_up_player()
		return

	is_player_sitting = true
	_sitting_player = player
	_sit_grace_timer = 0.25
	player.global_position = global_position + SEAT_OFFSET + Vector2(0, 1)
	if "velocity" in player:
		player.velocity = Vector2.ZERO

	var surv: SurvivalComponent = player.get_node_or_null("SurvivalComponent")
	if surv:
		surv.is_sitting_resting = true

	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🪵 Sentado descansando (Modo AFK)", Color.SKY_BLUE, -42.0)
	if player.has_method("show_hint"):
		player.show_hint("🪵 Estás sentado junto al fuego: tus barras de Hambre y Sueño bajan un 85% más lento. Muévete o pulsa [E] para levantarte.")

func _stand_up_player() -> void:
	if not is_player_sitting:
		return
	is_player_sitting = false
	if is_instance_valid(_sitting_player):
		var surv: SurvivalComponent = _sitting_player.get_node_or_null("SurvivalComponent")
		if surv:
			surv.is_sitting_resting = false
		if _sitting_player.has_method("_spawn_floating_text"):
			_sitting_player._spawn_floating_text("Te has levantado", Color.WHITE, -38.0)
	_sitting_player = null

func _interact_pot(player: Node2D) -> void:
	if not ("inventory" in player) or not player.inventory:
		return
	var inv: SimpleInventory = player.inventory

	if inv.has_item("raw_meat", 1):
		inv.remove_item("raw_meat", 1)
		inv.add_item("cooked_meat", 1)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🍲 Cacerola: +1 Carne Cocida", Color.ORANGE, -42.0)
		return

	for fish_id in ["night_catfish", "golden_carp", "river_trout"]:
		if inv.has_item(fish_id, 1):
			var f_name := inv.get_item_name(fish_id)
			inv.remove_item(fish_id, 1)
			inv.add_item("cooked_fish", 1)
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🍲 Cacerola (%s): +1 Pescado Cocido" % f_name, Color.AQUA, -42.0)
			return

	for veg_id in ["cabbage", "carrot", "mushroom"]:
		if inv.has_item(veg_id, 1):
			var v_name := inv.get_item_name(veg_id)
			inv.remove_item(veg_id, 1)
			inv.add_item("cooked_vegetable", 1)
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🍲 Cacerola (%s): +1 Verdura Cocida" % v_name, Color.SPRING_GREEN, -42.0)
			return

	if inv.has_item("egg", 1):
		inv.remove_item("egg", 1)
		inv.add_item("cooked_egg", 1)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🍲 Cacerola: +1 Huevo Cocido", Color.GOLD, -42.0)
		return

	if player.has_method("show_hint"):
		player.show_hint("🍲 La cacerola hierve. Necesitas Carne Cruda, Verduras (Zanahoria/Col/Hongo) o Huevos para cocinar.")

func _get_tent_prompt() -> String:
	if WorldClock and (WorldClock.current_hour >= 20 or WorldClock.current_hour < 6):
		return "⛺ Tienda de Campaña [E: Ir a dormir]"
	return "⛺ Tienda de Campaña [Dormir disponible de noche: 20:00]"

func _get_pot_prompt() -> String:
	var player = get_tree().get_first_node_in_group("player")
	var inv: SimpleInventory = player.get("inventory") if player else null
	if inv:
		if inv.has_item("raw_meat", 1):
			return "🍲 Hoguera [E: Cocinar Carne Cruda]"
		for fish_id in ["night_catfish", "golden_carp", "river_trout"]:
			if inv.has_item(fish_id, 1):
				return "🍲 Hoguera [E: Cocinar %s]" % inv.get_item_name(fish_id)
		for veg_id in ["cabbage", "carrot", "mushroom"]:
			if inv.has_item(veg_id, 1):
				return "🍲 Hoguera [E: Cocinar %s]" % inv.get_item_name(veg_id)
		if inv.has_item("egg", 1):
			return "🍲 Hoguera [E: Cocinar Huevo Fresco]"
	return "🍲 Hoguera con Cacerola [E: Cocinar Carne / Verdura / Huevo]"

func _get_seat_prompt() -> String:
	if is_player_sitting:
		return "🪵 Sentado (Modo AFK) [E o Moverse: Levantarse]"
	return "🪵 Tronco [E: Sentarse a descansar]"

func _create_label(pos: Vector2, col: Color) -> Label:
	var lbl := Label.new()
	lbl.visible = false
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = pos
	lbl.custom_minimum_size = Vector2(230, 20)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.z_index = 20
	return lbl

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
