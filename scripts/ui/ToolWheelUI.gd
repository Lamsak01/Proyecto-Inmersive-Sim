extends Control
class_name ToolWheelUI

## Rueda Radial de Herramientas y Armas (Estilo Red Dead Redemption) — Fase 5.4
## - Separada de la Mochila [I]: se abre con [Tab] (funciona tanto manteniendo pulsado [Tab] y soltando
##   sobre la herramienta deseada, como pulsando [Tab] y haciendo Clic Izquierdo).
## - Contiene las 8 herramientas/armas del jugador:
##   [1] Espada, [2] Martillo, [3] Hacha, [4] Pico, [5] Arco, [6] Hoz, [7] Regadera, [8] Caña de Pescar.

var player: CharacterBody2D = null
var hovered_index: int = -1
var _open_timestamp: float = 0.0
var _last_wheel_mouse: Vector2 = Vector2.ZERO

const WHEEL_OUTER_RADIUS: float = 165.0
const WHEEL_INNER_RADIUS: float = 56.0
const SLOT_RING_RADIUS: float = 112.0
const SLOT_BOX_RADIUS: float = 34.0

var center_title_lbl: Label = null
var center_desc_lbl: Label = null
var footer_hint_lbl: Label = null

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	center_title_lbl = Label.new()
	center_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_title_lbl.add_theme_font_size_override("font_size", 14)
	center_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
	center_title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	center_title_lbl.add_theme_constant_override("outline_size", 3)
	add_child(center_title_lbl)

	center_desc_lbl = Label.new()
	center_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center_desc_lbl.add_theme_font_size_override("font_size", 10)
	center_desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 0.96))
	center_desc_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	center_desc_lbl.add_theme_constant_override("outline_size", 2)
	add_child(center_desc_lbl)

	footer_hint_lbl = Label.new()
	footer_hint_lbl.text = "☸ Rueda de Herramientas [A/D o Flechas ←/→ para girar | Espacio/Enter/Clic para elegir | 1-8 Rápido]"
	footer_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_hint_lbl.add_theme_font_size_override("font_size", 11)
	footer_hint_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68))
	footer_hint_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	footer_hint_lbl.add_theme_constant_override("outline_size", 3)
	add_child(footer_hint_lbl)

func open_wheel() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	visible = true
	_open_timestamp = float(Time.get_ticks_msec()) / 1000.0
	_last_wheel_mouse = get_local_mouse_position()
	hovered_index = _get_equipped_index()
	_update_labels()
	queue_redraw()

func close_wheel(apply_selection: bool = true) -> void:
	if not visible:
		return
	if apply_selection and hovered_index >= 0 and player and player.has_method("equip_tool_by_index"):
		player.call("equip_tool_by_index", hovered_index)
	visible = false

func _process(_delta: float) -> void:
	if not visible:
		return
	var center: Vector2 = size * 0.5
	var mouse_pos: Vector2 = get_local_mouse_position()

	# Solo actualizar con el ratón si el cursor se ha movido físicamente desde que se abrió la rueda
	if mouse_pos.distance_squared_to(_last_wheel_mouse) > 4.0:
		_last_wheel_mouse = mouse_pos
		var diff: Vector2 = mouse_pos - center
		if diff.length() >= 32.0:
			var ang: float = fposmod(diff.angle() + PI * 0.5 + PI / 8.0, TAU)
			hovered_index = int(floor(ang / (TAU / 8.0))) % 8

	_update_labels()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_RIGHT or event.physical_keycode == KEY_D or event.keycode == KEY_DOWN or event.physical_keycode == KEY_S:
			hovered_index = (hovered_index + 1) % 8
			_update_labels()
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_LEFT or event.physical_keycode == KEY_A or event.keycode == KEY_UP or event.physical_keycode == KEY_W:
			hovered_index = (hovered_index + 7) % 8
			_update_labels()
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			close_wheel(true)
			get_viewport().set_input_as_handled()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_8:
			hovered_index = int(event.keycode - KEY_1)
			close_wheel(true)
			get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			close_wheel(true)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			close_wheel(false)
			accept_event()

func handle_tab_release() -> void:
	if not visible:
		return
	var elapsed: float = (float(Time.get_ticks_msec()) / 1000.0) - _open_timestamp
	var center: Vector2 = size * 0.5
	var moved_to_sector: bool = get_local_mouse_position().distance_to(center) >= 36.0
	# Si el jugador mantuvo pulsado TAB (>0.22s) o ya apuntó a un sector con el ratón, equipa al soltar TAB (estilo RDR2)
	if elapsed >= 0.22 or moved_to_sector:
		close_wheel(true)

func _get_tool_tier(tool_id: String) -> int:
	if player and player.has_method("get_tool_tier"):
		return int(player.call("get_tool_tier", tool_id))
	return 1

func _get_tier_badge(tier: int) -> String:
	match tier:
		2: return " [Nv.2 Hierro]"
		3: return " [Nv.3 Acero★]"
		_: return " [Nv.1]"

func _get_tool_entries() -> Array[Dictionary]:
	var water_charges: int = 6
	var max_water: int = 6
	if player and "watering_can_charges" in player:
		water_charges = int(player.watering_can_charges)
	if player and "max_water_charges" in player:
		max_water = int(player.max_water_charges)

	var t_sword: int = _get_tool_tier("Sword")
	var t_hammer: int = _get_tool_tier("Hammer")
	var t_axe: int = _get_tool_tier("Axe")
	var t_pick: int = _get_tool_tier("Pickaxe")
	var t_bow: int = _get_tool_tier("Bow")
	var t_sickle: int = _get_tool_tier("Sickle")
	var t_can: int = _get_tool_tier("WateringCan")
	var t_rod: int = _get_tool_tier("FishingRod")

	var sickle_bonus: int = 1
	if player and player.has_method("get_sickle_bonus"):
		sickle_bonus = int(player.call("get_sickle_bonus"))

	return [
		{
			"key": "1",
			"tier": t_sword,
			"title": "Espada" + _get_tier_badge(t_sword),
			"desc": "Arma de filo: corte rápido y acumulación de sangrado.\nMejorable en la Herrería de Thoran.",
			"weapon": player.get("sword_weapon") if player else null
		},
		{
			"key": "2",
			"tier": t_hammer,
			"title": "Martillo" + _get_tier_badge(t_hammer),
			"desc": "Arma contundente: alto empuje y aturdimiento (KO).\nMejorable en la Herrería de Thoran.",
			"weapon": player.get("hammer_weapon") if player else null
		},
		{
			"key": "3",
			"tier": t_axe,
			"title": "Hacha" + _get_tier_badge(t_axe),
			"desc": "Herramienta especialista en Tala de Árboles.\nEficiencia de tala: %d%%" % int(round((1.8 if t_axe == 1 else (2.7 if t_axe == 2 else 3.8)) * 100.0)),
			"weapon": player.get("axe_weapon") if player else null
		},
		{
			"key": "4",
			"tier": t_pick,
			"title": "Pico" + _get_tier_badge(t_pick),
			"desc": "Herramienta especialista en Minería de Rocas y Hierro.\nEficiencia minera: %d%%" % int(round((1.8 if t_pick == 1 else (2.7 if t_pick == 2 else 3.8)) * 100.0)),
			"weapon": player.get("pickaxe_weapon") if player else null
		},
		{
			"key": "5",
			"tier": t_bow,
			"title": "Arco de Caza" + _get_tier_badge(t_bow),
			"desc": "Disparo a distancia silencioso para cazar sin espantar.\nMantén Clic Izquierdo para tensar.",
			"weapon": player.get("bow_weapon") if player else null
		},
		{
			"key": "6",
			"tier": t_sickle,
			"title": "Hoz" + _get_tier_badge(t_sickle),
			"desc": "Herramienta de cosecha agrícola.\nOtorga +%d cultivo(s) extra al cosechar plantas maduras." % sickle_bonus,
			"weapon": player.get("sickle_weapon") if player else null
		},
		{
			"key": "7",
			"tier": t_can,
			"title": "Regadera (%d/%d)%s" % [water_charges, max_water, _get_tier_badge(t_can)],
			"desc": "Herramienta de riego agrícola (Agua: %d/%d).\nRecárgala en el Pozo o en el Lago del Oeste." % [water_charges, max_water],
			"weapon": player.get("watering_can_weapon") if player else null
		},
		{
			"key": "8",
			"tier": t_rod,
			"title": "Caña de Pescar" + _get_tier_badge(t_rod),
			"desc": "Herramienta de pesca con barra de precisión.\nTamaño de barra: %d%%." % int(round((1.0 if t_rod == 1 else (1.28 if t_rod == 2 else 1.55)) * 100.0)),
			"weapon": player.get("fishing_rod_weapon") if player else null
		}
	]

func _get_equipped_index() -> int:
	if not player or not ("equipped_weapon" in player) or not player.equipped_weapon:
		return 0
	var entries := _get_tool_entries()
	for i in range(entries.size()):
		if entries[i]["weapon"] == player.equipped_weapon:
			return i
	return 0

func _update_labels() -> void:
	var center: Vector2 = size * 0.5
	var entries := _get_tool_entries()
	var idx: int = clampi(hovered_index if hovered_index >= 0 else _get_equipped_index(), 0, entries.size() - 1)
	var item: Dictionary = entries[idx]

	if center_title_lbl:
		center_title_lbl.text = "[%s] %s" % [str(item["key"]), str(item["title"])]
		center_title_lbl.size = Vector2(200, 24)
		center_title_lbl.position = center + Vector2(-100, -28)

	if center_desc_lbl:
		center_desc_lbl.text = str(item["desc"])
		center_desc_lbl.size = Vector2(210, 48)
		center_desc_lbl.position = center + Vector2(-105, -4)

	if footer_hint_lbl:
		footer_hint_lbl.size = Vector2(560, 24)
		footer_hint_lbl.position = center + Vector2(-280, WHEEL_OUTER_RADIUS + 18.0)

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var entries := _get_tool_entries()
	var equipped_idx: int = _get_equipped_index()
	var font: Font = ThemeDB.fallback_font

	# Fondo semitransparente oscuro
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.05, 0.52), true)

	# Círculo exterior de la rueda
	draw_circle(center, WHEEL_OUTER_RADIUS, Color(0.07, 0.08, 0.11, 0.90))
	draw_arc(center, WHEEL_OUTER_RADIUS, 0.0, TAU, 64, Color(0.55, 0.46, 0.28, 0.95), 2.5)

	# Líneas divisorias de los 8 sectores
	for i in range(8):
		var sep_angle: float = -PI * 0.5 - PI / 8.0 + float(i) * (TAU / 8.0)
		var dir := Vector2(cos(sep_angle), sin(sep_angle))
		draw_line(center + dir * WHEEL_INNER_RADIUS, center + dir * WHEEL_OUTER_RADIUS, Color(0.32, 0.28, 0.22, 0.55), 1.2)

	# Círculo central informativo
	draw_circle(center, WHEEL_INNER_RADIUS, Color(0.11, 0.12, 0.16, 0.96))
	draw_arc(center, WHEEL_INNER_RADIUS, 0.0, TAU, 48, Color(0.78, 0.64, 0.34, 0.95), 2.0)

	# Dibujar cada uno de los 8 slots
	for i in range(entries.size()):
		var angle: float = -PI * 0.5 + float(i) * (TAU / 8.0)
		var slot_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * SLOT_RING_RADIUS
		var is_hovered: bool = (i == hovered_index)
		var is_equipped: bool = (i == equipped_idx)

		var slot_tier: int = int(entries[i].get("tier", 1))
		var bg_col := Color(0.15, 0.17, 0.22, 0.95)
		var border_col := Color(0.55, 0.45, 0.34, 0.85)
		if slot_tier == 2:
			border_col = Color(0.68, 0.78, 0.92, 0.92)
		elif slot_tier >= 3:
			border_col = Color(0.35, 0.90, 1.0, 0.98)
		var border_w: float = 1.8 if slot_tier == 1 else 2.2

		if is_hovered:
			bg_col = Color(0.30, 0.25, 0.14, 0.98)
			border_col = Color(1.0, 0.84, 0.32, 1.0)
			border_w = 2.8
		elif is_equipped:
			bg_col = Color(0.18, 0.24, 0.18, 0.96)
			border_col = Color(0.45, 0.88, 0.52, 0.95)
			border_w = 2.2

		draw_circle(slot_pos, SLOT_BOX_RADIUS, bg_col)
		draw_arc(slot_pos, SLOT_BOX_RADIUS, 0.0, TAU, 36, border_col, border_w)

		var w_data: WeaponData = entries[i]["weapon"]
		if w_data and w_data.icon:
			var icon_size := Vector2(32, 32)
			draw_texture_rect(w_data.icon, Rect2(slot_pos - icon_size * 0.5 + Vector2(0, -3), icon_size), false)

		if font:
			var key_txt := "[%s]" % str(entries[i]["key"])
			draw_string(font, slot_pos + Vector2(-10, 24), key_txt, HORIZONTAL_ALIGNMENT_CENTER, 24, 10, Color(0.96, 0.90, 0.65))
