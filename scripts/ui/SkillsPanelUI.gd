extends Control
class_name SkillsPanelUI

const SkillCatalog = preload("res://scripts/systems/SkillCatalog.gd")

## Panel de Habilidades RPG del Jugador (tecla [K]): nivel, experiencia y efecto de cada habilidad.
## Los nodos se crean UNA sola vez y luego solo se actualizan textos/barras (sin lag).

var player: Node = null
var _rows: Dictionary = {} # skill_id -> {"title": Label, "bar": ProgressBar, "xp": Label}
var _refresh_timer: float = 0.0

func _ready() -> void:
	name = "SkillsPanelUI"
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 115
	_build_ui()

func _process(delta: float) -> void:
	if not visible:
		return
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_timer += delta
	if _refresh_timer >= 1.0:
		_refresh_timer = 0.0
		refresh_ui()

func _box(bg: Color, border: Color, bw: int = 1, radius: int = 6) -> StyleBoxFlat:
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

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 420)
	panel.add_theme_stylebox_override("panel", _box(Color(0.07, 0.09, 0.13, 0.98), Color(0.76, 0.62, 0.34, 0.95), 2, 8))
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "⭐ HABILIDADES DEL FORASTERO"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.58))
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "✖ Cerrar [K / ESC]"
	close_btn.pressed.connect(close_panel)
	header.add_child(close_btn)

	root.add_child(HSeparator.new())

	for sid in SkillCatalog.skill_ids():
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", _box(Color(0.09, 0.11, 0.15, 0.94), Color(0.24, 0.30, 0.38, 0.75), 1, 4))
		root.add_child(box)
		var bm := MarginContainer.new()
		for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
			bm.add_theme_constant_override(side, 5)
		box.add_child(bm)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		bm.add_child(v)
		var top := HBoxContainer.new()
		v.add_child(top)
		var t_lbl := Label.new()
		t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t_lbl.add_theme_font_size_override("font_size", 13)
		t_lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72))
		top.add_child(t_lbl)
		var xp_lbl := Label.new()
		xp_lbl.add_theme_font_size_override("font_size", 11)
		xp_lbl.add_theme_color_override("font_color", Color(0.76, 0.88, 0.98))
		top.add_child(xp_lbl)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 8)
		v.add_child(bar)
		var d_lbl := Label.new()
		d_lbl.text = "%s  ·  Se entrena: %s" % [str(SkillCatalog.SKILLS[sid]["desc"]), str(SkillCatalog.SKILLS[sid]["xp_hint"])]
		d_lbl.add_theme_font_size_override("font_size", 10)
		d_lbl.add_theme_color_override("font_color", Color(0.76, 0.80, 0.88))
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(d_lbl)
		_rows[sid] = {"title": t_lbl, "bar": bar, "xp": xp_lbl}

func refresh_ui() -> void:
	if not is_instance_valid(player) or not player.has_method("get_skill_level"):
		return
	for sid in _rows.keys():
		var lvl: int = int(player.call("get_skill_level", sid))
		var xp: int = int(player.call("get_skill_xp", sid)) if player.has_method("get_skill_xp") else 0
		var row: Dictionary = _rows[sid]
		var bonus_pct: int = int(round(float(player.call("get_skill_bonus", sid)) * 100.0))
		(row["title"] as Label).text = "%s %s — Nivel %d / %d  (bono +%d%%)" % [SkillCatalog.skill_icon(sid), SkillCatalog.skill_name(sid), lvl, SkillCatalog.MAX_LEVEL, bonus_pct]
		var bar: ProgressBar = row["bar"]
		if lvl >= SkillCatalog.MAX_LEVEL:
			bar.max_value = 1.0
			bar.value = 1.0
			(row["xp"] as Label).text = "NIVEL MÁXIMO"
		else:
			var need: int = SkillCatalog.xp_for_next(lvl)
			bar.max_value = float(need)
			bar.value = float(xp)
			(row["xp"] as Label).text = "XP %d / %d" % [xp, need]

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
