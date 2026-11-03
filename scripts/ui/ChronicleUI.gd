extends Control

## Crónica del pueblo (tecla O). Pestañas por tema; lista por días, lo más nuevo arriba.
## Solo muestra lo que el jugador sabe, salvo en modo pruebas (`VillageChronicle.SHOW_ALL_DEBUG`).

const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")

var _tab_bar: TabBar = null
var _text: RichTextLabel = null
var _debug_lbl: Label = null

func _ready() -> void:
	name = "ChronicleUI"
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 115
	_build_ui()

func _make_box_style(bg: Color, border: Color, bw: int = 1, radius: int = 6) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(bw)
	st.set_corner_radius_all(radius)
	return st

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.02, 0.03, 0.05, 0.80)
	add_child(dimmer)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var main_panel := PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(760, 440)
	main_panel.add_theme_stylebox_override("panel", _make_box_style(Color(0.08, 0.07, 0.06, 0.98), Color(0.70, 0.55, 0.32, 0.95), 2, 8))
	center.add_child(main_panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	main_panel.add_child(margin)
	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(root_vbox)
	var header := HBoxContainer.new()
	root_vbox.add_child(header)
	var title := Label.new()
	title.text = "📖 CRÓNICA DEL PUEBLO"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.60))
	header.add_child(title)
	_debug_lbl = Label.new()
	_debug_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.35))
	_debug_lbl.add_theme_font_size_override("font_size", 11)
	header.add_child(_debug_lbl)
	var close_btn := Button.new()
	close_btn.text = "✖ Cerrar [O / ESC]"
	close_btn.custom_minimum_size = Vector2(138, 28)
	close_btn.pressed.connect(close_panel)
	header.add_child(close_btn)
	_tab_bar = TabBar.new()
	for cat in VillageChronicle.CATEGORIES:
		_tab_bar.add_tab(str(VillageChronicle.CATEGORY_NAMES.get(cat, cat)))
	_tab_bar.tab_changed.connect(func(_i: int) -> void: refresh_ui())
	root_vbox.add_child(_tab_bar)
	var body := PanelContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_stylebox_override("panel", _make_box_style(Color(0.05, 0.05, 0.05, 0.96), Color(0.30, 0.26, 0.20, 0.85), 1, 6))
	root_vbox.add_child(body)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = true
	_text.add_theme_font_size_override("normal_font_size", 13)
	body.add_child(_text)

func _vm() -> VillageManager:
	return get_tree().get_first_node_in_group("village_manager") as VillageManager

func current_category() -> String:
	return VillageChronicle.CATEGORIES[clampi(_tab_bar.current_tab if _tab_bar else 0, 0, VillageChronicle.CATEGORIES.size() - 1)]

func refresh_ui() -> void:
	if not _text:
		return
	_debug_lbl.text = "🔧 Modo pruebas: se ve todo (🔒 = no lo sabrías)  " if VillageChronicle.SHOW_ALL_DEBUG else ""
	var entries: Array = VillageChronicle.visible_entries(_vm(), current_category())
	if entries.is_empty():
		_text.text = "[color=#9aa4b5]Aún no hay nada escrito aquí. La crónica se llena con lo que pasa en el pueblo y con lo que vas descubriendo.[/color]"
		return
	var lines: Array[String] = []
	var last_day: int = -1
	for e in entries:
		var d: int = int(e.get("day", 1))
		if d != last_day:
			if last_day != -1:
				lines.append("")
			lines.append("[b][color=#ffd98a]Día %d[/color][/b]" % d)
			last_day = d
		var col: String = "#d8d8d8" if bool(e.get("known", false)) else "#8a8f99"
		lines.append("[color=%s]%s[/color]" % [col, VillageChronicle.line_text(e)])
	_text.text = "\n".join(lines)

func open_panel() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	refresh_ui()

func close_panel() -> void:
	visible = false

func toggle_panel() -> void:
	if visible:
		close_panel()
	else:
		open_panel()
