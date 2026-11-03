extends Control

## Panel de misiones (tecla L). Pestañas: Secundarias y Principal.
## A la izquierda la lista (activas primero); a la derecha el detalle de la misión elegida.

const TABS: Array[String] = ["side", "main"]
const STATUS_ICON: Dictionary = {"active": "🟡", "completed": "✅", "failed": "❌"}
const STATUS_TEXT: Dictionary = {"active": "En curso", "completed": "Completada", "failed": "Fallida"}

var _tab_bar: TabBar = null
var _list: ItemList = null
var _detail: RichTextLabel = null
var _shown_ids: Array[String] = []
var _selected_id: String = ""

func _ready() -> void:
	name = "QuestLogUI"
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 115
	_build_ui()
	var qm = get_node_or_null("/root/QuestManager")
	if qm and not qm.quest_changed.is_connected(_on_quest_changed):
		qm.quest_changed.connect(_on_quest_changed)

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
	main_panel.custom_minimum_size = Vector2(760, 420)
	main_panel.add_theme_stylebox_override("panel", _make_box_style(Color(0.07, 0.09, 0.13, 0.98), Color(0.76, 0.62, 0.34, 0.95), 2, 8))
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
	title.text = "📜 MISIONES"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.58))
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "✖ Cerrar [L / ESC]"
	close_btn.custom_minimum_size = Vector2(138, 28)
	close_btn.pressed.connect(close_panel)
	header.add_child(close_btn)

	_tab_bar = TabBar.new()
	_tab_bar.add_tab("🗺️ Secundarias")
	_tab_bar.add_tab("👑 Principal")
	_tab_bar.tab_changed.connect(func(_i: int) -> void:
		_selected_id = ""
		refresh_ui()
	)
	root_vbox.add_child(_tab_bar)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root_vbox.add_child(body)

	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(250, 0)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(func(idx: int) -> void:
		if idx >= 0 and idx < _shown_ids.size():
			_selected_id = _shown_ids[idx]
			_show_detail()
	)
	body.add_child(_list)

	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_stylebox_override("panel", _make_box_style(Color(0.05, 0.06, 0.09, 0.96), Color(0.28, 0.34, 0.44, 0.85), 1, 6))
	body.add_child(right)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = false
	_detail.scroll_active = true
	_detail.add_theme_font_size_override("normal_font_size", 13)
	right.add_child(_detail)

func _current_category() -> String:
	return TABS[clampi(_tab_bar.current_tab if _tab_bar else 0, 0, TABS.size() - 1)]

func refresh_ui() -> void:
	if not _list:
		return
	var qm = get_node_or_null("/root/QuestManager")
	_list.clear()
	_shown_ids.clear()
	var quests: Array = qm.get_quests(_current_category()) if qm else []
	for q in quests:
		var st: String = str(q.get("status", "active"))
		_list.add_item("%s %s" % [STATUS_ICON.get(st, "•"), str(q.get("title", "Misión"))])
		_shown_ids.append(str(q.get("id", "")))
	if _selected_id == "" or not (_selected_id in _shown_ids):
		_selected_id = _shown_ids[0] if not _shown_ids.is_empty() else ""
	if _selected_id != "":
		_list.select(_shown_ids.find(_selected_id))
	_show_detail()

func _show_detail() -> void:
	if not _detail:
		return
	var qm = get_node_or_null("/root/QuestManager")
	var q: Dictionary = qm.get_quest(_selected_id) if (qm and _selected_id != "") else {}
	if q.is_empty():
		if _current_category() == "main":
			_detail.text = "[color=#9aa4b5]La historia principal aún no ha comenzado.[/color]"
		else:
			_detail.text = "[color=#9aa4b5]No tienes misiones secundarias.\nHabla con los vecinos: a veces alguien necesita ayuda (lo verás con un ❗ sobre su cabeza).[/color]"
		return
	var st: String = str(q.get("status", "active"))
	var lines: Array[String] = []
	lines.append("[b][color=#ffe594]%s[/color][/b]" % str(q.get("title", "Misión")))
	lines.append("%s %s · desde el día %d" % [STATUS_ICON.get(st, "•"), STATUS_TEXT.get(st, st), int(q.get("day_started", 1))])
	if str(q.get("giver_name", "")) != "":
		lines.append("Te lo pidió: [b]%s[/b]" % str(q.get("giver_name", "")))
	lines.append("")
	lines.append(str(q.get("description", "")))
	var notes: Array = q.get("notes", [])
	if not notes.is_empty():
		lines.append("")
		lines.append("[b]Registro[/b]")
		for n in notes:
			lines.append("• " + str(n))
	_detail.text = "\n".join(lines)

func _on_quest_changed(_qid: String) -> void:
	if visible:
		refresh_ui()

## V8: ocupa la pantalla entera (el `ui_root` es más pequeño), para que el panel salga centrado, como la crónica.
func _fit_to_screen() -> void:
	top_level = true
	global_position = Vector2.ZERO
	size = get_viewport_rect().size

func open_panel() -> void:
	_fit_to_screen()
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
