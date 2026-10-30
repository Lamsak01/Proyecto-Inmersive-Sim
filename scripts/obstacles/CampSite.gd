@tool
extends Node2D
class_name CampSite

## Campamento y Casa Propia Expandible del Jugador + Tecnología Anacrónica (Pasos 6 y 10)
## 1. ⛺ -> 🛖 -> 🏡 Vivienda del Jugador (Nv.1 Tienda de Campaña -> Nv.2 Cabaña de Madera -> Nv.3 Casa de Piedra con Cofre):
##    - Con paredes sólidas (`StaticBody2D`), suelo texturizado, cama interior y Cofre Personal (Nv.3).
##    - Se puede mejorar en la Carpintería de Bram o directamente en el Cartel de Obra (`UpgradeSign`) del campamento.
## 2. 🍲 Hoguera con Cacerola: Cocina Carne, Pollo, Ancas de Rana, Pescado, Verduras y Huevos.
## 3. 🪵 Tronco para Sentarse: Modo descanso AFK (Hambre y Sueño bajan un 85% más lento).
## 4. ⚡ Generador Antiguo y Aspersor Automático (Paso 10):
##    - Alimenta la red eléctrica del campamento y del pueblo, y activa el Aspersor Automático en el huerto 3x3 (`Vector2(139, 99)`).

const TENT_OFFSET := Vector2(-46, -18)
const POT_OFFSET := Vector2(4, 6)
const SEAT_OFFSET := Vector2(28, 6)
const UPGRADE_SIGN_OFFSET := Vector2(-6, -24)
const GENERATOR_OFFSET := Vector2(36, -20)
const SPRINKLER_OFFSET := Vector2(-29, 75) # Global Vector2(139, 99) -> centro del Huerto 3x3 relativo a (168, 24)
const CHEST_OFFSET := Vector2(-64, -30)

var house_tier: int = 1 # 1 = Tienda, 2 = Cabaña de Madera, 3 = Casa de Piedra con Cofre
var generator_active: bool = false
var sprinkler_installed: bool = false
var chest_gold_stored: int = 0

var tent_body: StaticBody2D = null
var tent_sprite: Sprite2D = null
var house_root: Node2D = null
var chest_sprite: Sprite2D = null
var pot_sprite: Sprite2D = null
var seat_sprite: Sprite2D = null
var sign_sprite: Sprite2D = null
var generator_sprite: Sprite2D = null
var sprinkler_sprite: Sprite2D = null

var tent_label: Label = null
var pot_label: Label = null
var seat_label: Label = null
var sign_label: Label = null
var generator_label: Label = null
var chest_label: Label = null

var _near_tent: bool = false
var _near_pot: bool = false
var _near_seat: bool = false
var _near_sign: bool = false
var _near_generator: bool = false
var _near_chest: bool = false
var _flame_phase: float = 0.0

var is_player_sitting: bool = false
var _sitting_player: Node2D = null
var _sit_grace_timer: float = 0.0

var sleep_confirm_layer: CanvasLayer = null
var sleep_confirm_panel: PanelContainer = null
var upgrade_panel: PanelContainer = null
var upgrade_desc_lbl: Label = null
var chest_panel: PanelContainer = null
var chest_info_lbl: Label = null

func _ready() -> void:
	add_to_group("campsite")
	var in_editor := Engine.is_editor_hint()
	set_process(not in_editor)
	set_process_unhandled_input(not in_editor)
	_setup_tent_and_house()
	_setup_campfire_pot()
	_setup_log_seat()
	_setup_upgrade_sign()
	_setup_generator_and_sprinkler()
	if not in_editor:
		_setup_sleep_confirm_ui()
		_setup_upgrade_ui()
		_setup_chest_ui()
		if WorldClock:
			WorldClock.day_passed.connect(_on_day_passed)
		if GameManager:
			GameManager.game_loaded.connect(_on_game_loaded)
		_load_saved_state()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_flame_phase += delta * 7.5
	if pot_sprite:
		var pulse := 1.0 + sin(_flame_phase) * 0.03
		pot_sprite.scale = Vector2(1.25 * pulse, 1.25 * pulse)

	if generator_sprite and generator_active:
		var g_pulse := 1.0 + sin(_flame_phase * 1.8) * 0.035
		generator_sprite.scale = Vector2(1.15 * g_pulse, 1.15 * g_pulse)
		generator_sprite.modulate = Color(0.88, 1.05, 1.18, 1.0)
	elif generator_sprite:
		generator_sprite.scale = Vector2(1.1, 1.1)
		generator_sprite.modulate = Color(0.75, 0.75, 0.78, 1.0)

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
	var sign_world := global_position + UPGRADE_SIGN_OFFSET
	var gen_world := global_position + GENERATOR_OFFSET
	var chest_world := global_position + CHEST_OFFSET

	_near_tent = player != null and player.global_position.distance_squared_to(tent_world) <= 24.0 * 24.0
	_near_pot = player != null and player.global_position.distance_squared_to(pot_world) <= 20.0 * 20.0
	_near_seat = player != null and player.global_position.distance_squared_to(seat_world) <= 15.0 * 15.0
	_near_sign = player != null and player.global_position.distance_squared_to(sign_world) <= 20.0 * 20.0
	_near_generator = player != null and player.global_position.distance_squared_to(gen_world) <= 22.0 * 22.0
	_near_chest = house_tier >= 3 and player != null and player.global_position.distance_squared_to(chest_world) <= 22.0 * 22.0

	if tent_label:
		var m_tent := tent_world.distance_squared_to(mouse_pos) <= 16.0 * 16.0
		tent_label.visible = _near_tent or m_tent
		if tent_label.visible:
			tent_label.text = _get_tent_prompt()

	if pot_label:
		var m_pot := pot_world.distance_squared_to(mouse_pos) <= 12.0 * 12.0
		pot_label.visible = _near_pot or m_pot
		if pot_label.visible:
			pot_label.text = _get_pot_prompt()

	if seat_label:
		var m_seat := seat_world.distance_squared_to(mouse_pos) <= 10.0 * 10.0
		seat_label.visible = _near_seat or m_seat or is_player_sitting
		if seat_label.visible:
			seat_label.text = _get_seat_prompt()

	if sign_label:
		var m_sign := sign_world.distance_squared_to(mouse_pos) <= 14.0 * 14.0
		sign_label.visible = _near_sign or m_sign
		if sign_label.visible:
			sign_label.text = _get_sign_prompt()

	if generator_label:
		var m_gen := gen_world.distance_squared_to(mouse_pos) <= 14.0 * 14.0
		generator_label.visible = _near_generator or m_gen
		if generator_label.visible:
			generator_label.text = _get_generator_prompt()

	if chest_label:
		var m_chest := house_tier >= 3 and chest_world.distance_squared_to(mouse_pos) <= 14.0 * 14.0
		chest_label.visible = _near_chest or m_chest
		if chest_label.visible:
			chest_label.text = "📦 Cofre Propio (%d Oro guardado) [E: Abrir]" % chest_gold_stored

func _unhandled_input(event: InputEvent) -> void:
	if sleep_confirm_panel and sleep_confirm_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_1, KEY_Y, KEY_S, KEY_ENTER, KEY_KP_ENTER]:
				_on_sleep_confirmed()
				get_viewport().set_input_as_handled()
			elif event.keycode in [KEY_2, KEY_N, KEY_ESCAPE]:
				_on_sleep_cancelled()
				get_viewport().set_input_as_handled()
		return

	if upgrade_panel and upgrade_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_1:
				_on_upgrade_house_pressed()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_2:
				_on_build_generator_pressed()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_3:
				_on_build_sprinkler_pressed()
				get_viewport().set_input_as_handled()
			elif event.keycode in [KEY_4, KEY_ESCAPE]:
				upgrade_panel.visible = false
				get_viewport().set_input_as_handled()
		return

	if chest_panel and chest_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_1:
				_on_chest_deposit_gold()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_2:
				_on_chest_withdraw_gold()
				get_viewport().set_input_as_handled()
			elif event.keycode in [KEY_3, KEY_ESCAPE]:
				chest_panel.visible = false
				get_viewport().set_input_as_handled()

# --- 1. TIENDA DE CAMPAÑA Y CASA EXPANDIBLE DEL JUGADOR (Paso 6) ---
func _setup_tent_and_house() -> void:
	tent_body = StaticBody2D.new()
	tent_body.name = "TentBody"
	tent_body.position = TENT_OFFSET
	add_child(tent_body)

	tent_sprite = Sprite2D.new()
	tent_sprite.texture = _load_tex("res://assests/world/camp/camp_tent.png")
	tent_sprite.scale = Vector2(1.3, 1.3)
	tent_body.add_child(tent_sprite)

	var col := CollisionShape2D.new()
	col.name = "TentCol"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 16)
	col.shape = rect
	col.position = Vector2(0, 2)
	tent_body.add_child(col)

	house_root = Node2D.new()
	house_root.name = "PlayerHouseRoot"
	add_child(house_root)

	var area := Area2D.new()
	area.name = "TentInteractArea"
	area.position = TENT_OFFSET + Vector2(0, 6)
	area.collision_layer = 1
	area.collision_mask = 2
	area.add_to_group("interactable")
	var acol := CollisionShape2D.new()
	var ac := CircleShape2D.new()
	ac.radius = 8.0
	acol.shape = ac
	area.add_child(acol)
	add_child(area)

	tent_label = _create_label(TENT_OFFSET + Vector2(-115, -34), Color(0.95, 0.92, 0.72))
	add_child(tent_label)

	chest_label = _create_label(CHEST_OFFSET + Vector2(-115, -24), Color(1.0, 0.88, 0.42))
	add_child(chest_label)

	_rebuild_house_visuals()

func _rebuild_house_visuals() -> void:
	if not house_root:
		return
	for c in house_root.get_children():
		c.queue_free()

	var is_tent: bool = (house_tier <= 1)
	if tent_sprite:
		tent_sprite.visible = is_tent
	if tent_body:
		var tcol: CollisionShape2D = tent_body.get_node_or_null("TentCol")
		if tcol:
			tcol.disabled = not is_tent

	if is_tent:
		return

	# Dimensiones de la Casa del Jugador centrada en TENT_OFFSET + Vector2(-8, -8)
	var center := TENT_OFFSET + Vector2(-8, -8)
	var size := Vector2(68, 52) if house_tier == 2 else Vector2(82, 60)
	var half := size * 0.5
	var floor_tex_path: String = "res://assests/world/village/floor_wood_planks.png" if house_tier == 2 else "res://assests/world/village/floor_stone_forge.png"
	var wall_h_path: String = "res://assests/world/village/wall_timber_h.png" if house_tier == 2 else "res://assests/world/village/wall_stone_h.png"
	var wall_v_path: String = "res://assests/world/village/wall_timber_v.png" if house_tier == 2 else "res://assests/world/village/wall_stone_v.png"

	# Suelo texturizado en mosaico
	var floor_rect := TextureRect.new()
	floor_rect.texture = _load_tex(floor_tex_path)
	floor_rect.stretch_mode = TextureRect.STRETCH_TILE
	floor_rect.position = center - half
	floor_rect.size = size
	floor_rect.z_index = -3
	house_root.add_child(floor_rect)

	# Paredes sólidas con puerta Sur de 28 px
	var door_w: float = 28.0
	var wall_t: float = 6.0
	var left_w: float = (size.x - door_w) * 0.5
	var tex_h := _load_tex(wall_h_path)
	var tex_v := _load_tex(wall_v_path)

	# Norte
	_add_house_wall_segment(center + Vector2(0, -half.y), Vector2(size.x, wall_t), tex_h)
	# Oeste
	_add_house_wall_segment(center + Vector2(-half.x, 0), Vector2(wall_t, size.y), tex_v)
	# Este
	_add_house_wall_segment(center + Vector2(half.x, 0), Vector2(wall_t, size.y), tex_v)
	# Sur Izquierda y Derecha (dejando puerta abierta)
	_add_house_wall_segment(center + Vector2(-half.x + left_w * 0.5, half.y), Vector2(left_w, wall_t), tex_h)
	_add_house_wall_segment(center + Vector2(half.x - left_w * 0.5, half.y), Vector2(left_w, wall_t), tex_h)

	# Cama Cómoda en el interior
	var bed_spr := Sprite2D.new()
	bed_spr.texture = _load_tex("res://assests/world/village/hospital_bed.png")
	bed_spr.position = TENT_OFFSET + Vector2(0, -4)
	bed_spr.modulate = Color(1.0, 0.90, 0.78, 1.0)
	bed_spr.z_index = -1
	house_root.add_child(bed_spr)

	# Cofre Personal en Nivel 3
	if house_tier >= 3:
		chest_sprite = Sprite2D.new()
		chest_sprite.texture = _load_tex("res://assests/world/village/house_chest_closed.png")
		chest_sprite.position = CHEST_OFFSET
		chest_sprite.scale = Vector2(1.15, 1.15)
		chest_sprite.z_index = -1
		house_root.add_child(chest_sprite)

		var chest_area := Area2D.new()
		chest_area.position = CHEST_OFFSET
		chest_area.collision_layer = 1
		chest_area.collision_mask = 2
		chest_area.add_to_group("interactable")
		var ccol := CollisionShape2D.new()
		var cc := CircleShape2D.new()
		cc.radius = 8.0
		ccol.shape = cc
		chest_area.add_child(ccol)
		house_root.add_child(chest_area)

func _add_house_wall_segment(pos: Vector2, sz: Vector2, tex: Texture2D) -> void:
	var sb := StaticBody2D.new()
	sb.position = pos
	sb.collision_layer = 1
	sb.collision_mask = 0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = sz
	col.shape = rect
	sb.add_child(col)

	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.position = -sz * 0.5
		tr.size = sz
		tr.z_index = 2
		sb.add_child(tr)
	house_root.add_child(sb)

# --- 2. HOGUERA CON CACEROLA ---
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

# --- 3. TRONCO PARA SENTARSE ---
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
	ac.radius = 4.0
	acol.shape = ac
	area.add_child(acol)
	add_child(area)

	seat_label = _create_label(SEAT_OFFSET + Vector2(-115, -26), Color(0.72, 0.92, 1.0))
	add_child(seat_label)

# --- 4. CARTEL DE MEJORA DE CASA Y TALLER ELÉCTRICO (Pasos 6 y 10) ---
func _setup_upgrade_sign() -> void:
	sign_sprite = Sprite2D.new()
	sign_sprite.name = "UpgradeSignSprite"
	sign_sprite.texture = _load_tex("res://assests/Comprados/ Packs/Cute_Fantasy/Buildings/House_Decor/sign_1.png")
	sign_sprite.position = UPGRADE_SIGN_OFFSET
	sign_sprite.scale = Vector2(0.95, 0.95)
	add_child(sign_sprite)

	var area := Area2D.new()
	area.name = "SignInteractArea"
	area.position = UPGRADE_SIGN_OFFSET
	area.collision_layer = 1
	area.collision_mask = 2
	area.add_to_group("interactable")
	var acol := CollisionShape2D.new()
	var ac := CircleShape2D.new()
	ac.radius = 6.0
	acol.shape = ac
	area.add_child(acol)
	add_child(area)

	sign_label = _create_label(UPGRADE_SIGN_OFFSET + Vector2(-115, -28), Color(0.95, 0.85, 0.52))
	add_child(sign_label)

# --- 5. GENERADOR ANTIGUO Y ASPERSOR AUTOMÁTICO (Paso 10) ---
func _setup_generator_and_sprinkler() -> void:
	generator_sprite = Sprite2D.new()
	generator_sprite.name = "AncientGeneratorSprite"
	generator_sprite.texture = _load_tex("res://assests/world/village/ancient_generator.png")
	generator_sprite.position = GENERATOR_OFFSET
	generator_sprite.scale = Vector2(1.1, 1.1)
	add_child(generator_sprite)

	var gen_area := Area2D.new()
	gen_area.name = "GeneratorInteractArea"
	gen_area.position = GENERATOR_OFFSET
	gen_area.collision_layer = 1
	gen_area.collision_mask = 2
	gen_area.add_to_group("interactable")
	var gcol := CollisionShape2D.new()
	var gc := CircleShape2D.new()
	gc.radius = 7.0
	gcol.shape = gc
	gen_area.add_child(gcol)
	add_child(gen_area)

	generator_label = _create_label(GENERATOR_OFFSET + Vector2(-115, -28), Color(0.55, 0.92, 1.0))
	add_child(generator_label)

	sprinkler_sprite = Sprite2D.new()
	sprinkler_sprite.name = "AutoSprinklerSprite"
	sprinkler_sprite.texture = _load_tex("res://assests/world/village/auto_sprinkler.png")
	sprinkler_sprite.position = SPRINKLER_OFFSET
	sprinkler_sprite.scale = Vector2(1.1, 1.1)
	sprinkler_sprite.visible = sprinkler_installed
	sprinkler_sprite.z_index = 4
	add_child(sprinkler_sprite)

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
	question_lbl.text = "🛏️ ¿Quieres ir a dormir?\n(Amanecerá a las 06:00 AM)"
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

func _setup_upgrade_ui() -> void:
	upgrade_panel = PanelContainer.new()
	upgrade_panel.visible = false
	upgrade_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	upgrade_panel.offset_left = -235.0
	upgrade_panel.offset_top = -115.0
	upgrade_panel.offset_right = 235.0
	upgrade_panel.offset_bottom = 115.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.14, 0.97)
	style.border_color = Color(0.88, 0.72, 0.36, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	upgrade_panel.add_theme_stylebox_override("panel", style)
	sleep_confirm_layer.add_child(upgrade_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	upgrade_panel.add_child(vbox)

	upgrade_desc_lbl = Label.new()
	upgrade_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_desc_lbl.add_theme_font_size_override("font_size", 12)
	upgrade_desc_lbl.add_theme_color_override("font_color", Color(0.98, 0.94, 0.80))
	vbox.add_child(upgrade_desc_lbl)

	var b1 := Button.new()
	b1.text = "[1] 🏡 Mejorar Vivienda (Nv.2 Cabaña: 30 Oro | Nv.3 Casa Piedra+Cofre: 55 Oro)"
	b1.pressed.connect(_on_upgrade_house_pressed)
	vbox.add_child(b1)

	var b2 := Button.new()
	b2.text = "[2] ⚡ Activar/Alternar Generador Eléctrico Antiguo (1 Bobina Cobre o 18 Oro)"
	b2.pressed.connect(_on_build_generator_pressed)
	vbox.add_child(b2)

	var b3 := Button.new()
	b3.text = "[3] 💦 Instalar Aspersor Automático en Huerto 3x3 (1 Bobina Cobre o 15 Oro)"
	b3.pressed.connect(_on_build_sprinkler_pressed)
	vbox.add_child(b3)

	var b4 := Button.new()
	b4.text = "[4 / ESC] Cerrar"
	b4.pressed.connect(func(): upgrade_panel.visible = false)
	vbox.add_child(b4)

func _setup_chest_ui() -> void:
	chest_panel = PanelContainer.new()
	chest_panel.visible = false
	chest_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	chest_panel.offset_left = -195.0
	chest_panel.offset_top = -85.0
	chest_panel.offset_right = 195.0
	chest_panel.offset_bottom = 85.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.08, 0.12, 0.96)
	style.border_color = Color(0.92, 0.76, 0.34, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	chest_panel.add_theme_stylebox_override("panel", style)
	sleep_confirm_layer.add_child(chest_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	chest_panel.add_child(vbox)

	chest_info_lbl = Label.new()
	chest_info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chest_info_lbl.add_theme_font_size_override("font_size", 13)
	chest_info_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72))
	vbox.add_child(chest_info_lbl)

	var b1 := Button.new()
	b1.text = "[1] 💰 Guardar 20 Oro en tu Cofre Personal (Protegido de multas)"
	b1.pressed.connect(_on_chest_deposit_gold)
	vbox.add_child(b1)

	var b2 := Button.new()
	b2.text = "[2] 🪙 Retirar todo el Oro guardado"
	b2.pressed.connect(_on_chest_withdraw_gold)
	vbox.add_child(b2)

	var b3 := Button.new()
	b3.text = "[3 / ESC] Cerrar Cofre"
	b3.pressed.connect(func(): chest_panel.visible = false)
	vbox.add_child(b3)

func interact(player: Node2D) -> void:
	if not player:
		return
	var tent_world: Vector2 = global_position + TENT_OFFSET + Vector2(0, 6)
	var pot_world: Vector2 = global_position + POT_OFFSET
	var seat_world: Vector2 = global_position + SEAT_OFFSET
	var sign_world: Vector2 = global_position + UPGRADE_SIGN_OFFSET
	var gen_world: Vector2 = global_position + GENERATOR_OFFSET
	var chest_world: Vector2 = global_position + CHEST_OFFSET

	var d_tent: float = player.global_position.distance_squared_to(tent_world)
	var d_pot: float = player.global_position.distance_squared_to(pot_world)
	var d_seat: float = player.global_position.distance_squared_to(seat_world)
	var d_sign: float = player.global_position.distance_squared_to(sign_world)
	var d_gen: float = player.global_position.distance_squared_to(gen_world)
	var d_chest: float = player.global_position.distance_squared_to(chest_world) if house_tier >= 3 else 999999.0

	if is_player_sitting:
		_stand_up_player()
		return

	var min_d: float = minf(minf(d_tent, d_pot), minf(minf(d_seat, d_sign), minf(d_gen, d_chest)))
	if min_d == d_chest and d_chest <= 24.0 * 24.0:
		_open_chest_ui()
	elif min_d == d_gen and d_gen <= 24.0 * 24.0:
		_on_build_generator_pressed()
	elif min_d == d_sign and d_sign <= 24.0 * 24.0:
		_open_upgrade_ui()
	elif min_d == d_tent and d_tent <= 26.0 * 26.0:
		_interact_tent(player)
	elif min_d == d_seat and d_seat <= 16.0 * 16.0:
		_interact_seat(player)
	elif d_pot <= 22.0 * 22.0:
		_interact_pot(player)

func _open_upgrade_ui() -> void:
	if not upgrade_panel:
		return
	var tier_names: Array[String] = ["⛺ Nv.1 Tienda de Campaña", "🛖 Nv.2 Cabaña de Madera", "🏡 Nv.3 Casa de Piedra con Cofre"]
	var t_name: String = tier_names[clampi(house_tier - 1, 0, 2)]
	var gen_str: String = "⚡ ACTIVO" if generator_active else "⚪ Apagado"
	var spr_str: String = "💦 INSTALADO" if sprinkler_installed else "⚪ No instalado"
	upgrade_desc_lbl.text = "🔨 Mesa de Obras y Electrificación del Hogar\nVivienda actual: %s | Generador: %s | Aspersor: %s" % [t_name, gen_str, spr_str]
	upgrade_panel.visible = true

func _open_chest_ui() -> void:
	if not chest_panel:
		return
	chest_info_lbl.text = "📦 Cofre Personal de tu Casa de Piedra\nOro guardado bajo llave: %d Oro" % chest_gold_stored
	chest_panel.visible = true

func _on_chest_deposit_gold() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var inv: SimpleInventory = player.get("inventory") if player else null
	if inv and inv.gold >= 20:
		inv.add_gold(-20)
		chest_gold_stored += 20
		_save_state()
		_open_chest_ui()
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("📦 Guardado: 20 Oro en tu Cofre (%d total)" % chest_gold_stored, Color.GOLD, -42.0)
	elif player and player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("❌ Necesitas al menos 20 Monedas de Oro", Color.ORANGE_RED, -42.0)

func _on_chest_withdraw_gold() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var inv: SimpleInventory = player.get("inventory") if player else null
	if inv and chest_gold_stored > 0:
		var amt: int = chest_gold_stored
		chest_gold_stored = 0
		inv.add_gold(amt)
		_save_state()
		_open_chest_ui()
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🪙 Retirado: +%d Oro de tu Cofre" % amt, Color.GOLD, -42.0)

func upgrade_player_house(target_tier: int = -1) -> bool:
	var next_t: int = (house_tier + 1) if target_tier < 0 else target_tier
	if next_t <= house_tier or next_t > 3:
		return false
	house_tier = clampi(next_t, 1, 3)
	_rebuild_house_visuals()
	_save_state()
	return true

func _on_upgrade_house_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var inv: SimpleInventory = player.get("inventory") if player else null
	if house_tier >= 3:
		if player and player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🏡 Tu Casa de Piedra ya está al Nivel Máximo (Nv.3)", Color.GOLD, -42.0)
		return
	var cost_gold: int = 30 if house_tier == 1 else 55
	var wood_need: int = 3 if house_tier == 1 else 5
	var paid: bool = false
	if inv:
		if inv.has_item("wood", wood_need) and inv.gold >= (cost_gold - 15):
			inv.remove_item("wood", wood_need)
			inv.add_gold(-(cost_gold - 15))
			paid = true
		elif inv.gold >= cost_gold:
			inv.add_gold(-cost_gold)
			paid = true
	if not paid:
		if player and player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("❌ Necesitas %d Oro (o %dx Madera + %d Oro)" % [cost_gold, wood_need, cost_gold - 15], Color.ORANGE_RED, -42.0)
		return
	upgrade_player_house(house_tier + 1)
	if upgrade_panel and upgrade_panel.visible:
		_open_upgrade_ui()
	if player and player.has_method("_spawn_floating_text"):
		var label_str: String = "🛖 ¡Cabaña de Madera Propia construida!" if house_tier == 2 else "🏡 ¡Casa de Piedra con Cofre Propio construida!"
		player._spawn_floating_text(label_str, Color.SPRING_GREEN, -46.0)

func _on_build_generator_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var inv: SimpleInventory = player.get("inventory") if player else null
	if not generator_active:
		var can_power: bool = false
		if GameManager and bool(GameManager.get_flag("generator_unlocked", false)):
			can_power = true
		elif inv and inv.has_item("copper_coil", 1):
			inv.remove_item("copper_coil", 1)
			can_power = true
		elif inv and inv.gold >= 18:
			inv.add_gold(-18)
			can_power = true
		if not can_power:
			if player and player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("⚡ Necesitas 1 Bobina de Cobre o 18 Oro para activar el Generador", Color.ORANGE_RED, -42.0)
			return
		if GameManager:
			GameManager.set_flag("generator_unlocked", true)
		generator_active = true
		if sprinkler_installed:
			_run_auto_sprinkler()
		if player and player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("⚡ ¡Generador Antiguo ENCENDIDO! Red eléctrica y Aspersor activos", Color.CYAN, -44.0)
	else:
		generator_active = false
		if player and player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("⚪ Generador Antiguo apagado", Color.LIGHT_GRAY, -42.0)
	_save_state()
	if upgrade_panel and upgrade_panel.visible:
		_open_upgrade_ui()

func _on_build_sprinkler_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var inv: SimpleInventory = player.get("inventory") if player else null
	if sprinkler_installed:
		_run_auto_sprinkler()
		if player and player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("💦 Aspersor Automático: Riego manual ejecutado", Color.AQUA, -42.0)
		return
	var paid: bool = false
	if inv and inv.has_item("copper_coil", 1):
		inv.remove_item("copper_coil", 1)
		paid = true
	elif inv and inv.gold >= 15:
		inv.add_gold(-15)
		paid = true
	if not paid:
		if player and player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("💦 Necesitas 1 Bobina de Cobre o 15 Oro para instalar el Aspersor", Color.ORANGE_RED, -42.0)
		return
	sprinkler_installed = true
	if sprinkler_sprite:
		sprinkler_sprite.visible = true
	if generator_active:
		_run_auto_sprinkler()
	_save_state()
	if upgrade_panel and upgrade_panel.visible:
		_open_upgrade_ui()
	if player and player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("💦 ¡Aspersor Automático instalado en el Huerto 3x3!", Color.AQUA, -44.0)

func _run_auto_sprinkler() -> void:
	if not sprinkler_installed or not generator_active:
		return
	var watered_cnt: int = 0
	for plot in get_tree().get_nodes_in_group("farm_plots"):
		if plot and plot.has_method("water_from_rain_or_sprinkler"):
			plot.water_from_rain_or_sprinkler()
			watered_cnt += 1
	if watered_cnt > 0 and sprinkler_sprite:
		var tw := create_tween()
		tw.tween_property(sprinkler_sprite, "scale", Vector2(1.35, 1.35), 0.12)
		tw.tween_property(sprinkler_sprite, "scale", Vector2(1.1, 1.1), 0.14)

func _on_day_passed(_new_day: int) -> void:
	if sprinkler_installed and generator_active:
		_run_auto_sprinkler()

func _interact_tent(player: Node2D) -> void:
	var is_night := false
	if WorldClock:
		var h: int = WorldClock.current_hour
		is_night = (h >= 20 or h < 6)

	if not is_night:
		if player.has_method("show_hint"):
			var home_n: String = "la tienda" if house_tier == 1 else "tu cama"
			player.show_hint("🛏️ Aún es de día. Solo puedes dormir en %s por la noche (20:00 - 06:00)." % home_n)
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
			if house_tier >= 2:
				surv.restore_hunger(15.0 * float(house_tier - 1))
		if stam:
			stam.current_stamina = stam.max_stamina
			stam.stamina_changed.emit(stam.current_stamina, stam.max_stamina)
		if health:
			health.heal(25.0 * float(house_tier))
		if player.has_method("_spawn_floating_text"):
			var msg: String = "☀️ Has dormido hasta el amanecer (+100%% Sueño, +%d HP)" % (25 * house_tier)
			player._spawn_floating_text(msg, Color.SKY_BLUE, -44.0)
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

	if inv.has_item("raw_chicken", 1):
		inv.remove_item("raw_chicken", 1)
		inv.add_item("roasted_chicken", 1)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🍲 Cacerola: +1 Pollo Asado Crujiente", Color.GOLD, -42.0)
		return

	if inv.has_item("frog_legs", 1):
		inv.remove_item("frog_legs", 1)
		inv.add_item("fried_frog_legs", 1)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🍲 Cacerola: +1 Ancas de Rana al Ajillo", Color.SPRING_GREEN, -42.0)
		return

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
	var h_title: String = "⛺ Tienda de Campaña"
	if house_tier == 2:
		h_title = "🛖 Cabaña de Madera Propia"
	elif house_tier >= 3:
		h_title = "🏡 Casa de Piedra Propia"
	if WorldClock and (WorldClock.current_hour >= 20 or WorldClock.current_hour < 6):
		return "%s [E: Ir a dormir]" % h_title
	return "%s [Dormir disponible de noche: 20:00]" % h_title

func _get_sign_prompt() -> String:
	return "🔨 Mesa de Obras (Casa Nv.%d/3 | Electricidad) [E: Abrir]" % house_tier

func _get_generator_prompt() -> String:
	if generator_active:
		return "⚡ Generador Antiguo: ACTIVO [E: Apagar]"
	return "⚡ Generador Antiguo: APAGADO [E: Encender]"

func _get_pot_prompt() -> String:
	var player = get_tree().get_first_node_in_group("player")
	var inv: SimpleInventory = player.get("inventory") if player else null
	if inv:
		if inv.has_item("raw_chicken", 1):
			return "🍲 Hoguera [E: Asar Pollo Crudo]"
		if inv.has_item("frog_legs", 1):
			return "🍲 Hoguera [E: Cocinar Ancas de Rana]"
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

func _save_state() -> void:
	if Engine.is_editor_hint() or not GameManager:
		return
	GameManager.set_flag("electric_grid_active", generator_active)
	GameManager.set_flag("player_campsite_state", {
		"house_tier": house_tier,
		"generator_active": generator_active,
		"sprinkler_installed": sprinkler_installed,
		"chest_gold": chest_gold_stored
	})

func _load_saved_state() -> void:
	if not GameManager:
		return
	var saved: Variant = GameManager.get_flag("player_campsite_state", null)
	if typeof(saved) == TYPE_DICTIONARY:
		house_tier = clampi(int(saved.get("house_tier", 1)), 1, 3)
		generator_active = bool(saved.get("generator_active", false))
		sprinkler_installed = bool(saved.get("sprinkler_installed", false))
		chest_gold_stored = int(saved.get("chest_gold", 0))
		GameManager.set_flag("electric_grid_active", generator_active)
		if sprinkler_sprite:
			sprinkler_sprite.visible = sprinkler_installed
		_rebuild_house_visuals()

func _on_game_loaded(_filepath: String) -> void:
	if is_player_sitting:
		_stand_up_player()
	_load_saved_state()

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
