extends Control
class_name DetectiveUI

## Herramientas del Detective (Bloques D1–D5)
## Copia fiel en Godot del boceto aprobado en `docs/bocetos/examen_cuerpo.html`.
## D1: Examen del cuerpo en la escena (7 zonas, acciones superficiales, silueta plana M/F, fondo 3D cenital en esquema).

const COL_NIGHT := Color("#12161a")
const COL_PANEL := Color("#1b2126")
const COL_EDGE := Color("#313a41")
const COL_INK := Color("#e6dfd2")
const COL_DIM := Color("#8f948f")
const COL_LAMP := Color("#e7b45a")
const COL_BLOOD := Color("#a8433b")
const COL_BRUISE := Color("#7d5aa6")
const COL_COLD := Color("#6b8ea6")
const COL_PAPER := Color("#e9e0cc")
const COL_PAPER_EDGE := Color("#b8ad94")
const COL_PAPER_INK := Color("#2a2620")
const COL_GREEN_OK := Color("#2f6b3b")
const COL_RED_PIN := Color("#b3261e")

const SKETCH_SHADER_CODE := """
shader_type canvas_item;

uniform float lantern_mode : hint_range(0.0, 1.0) = 0.0;
uniform vec2 lantern_uv = vec2(0.5, 0.5);
uniform float lantern_radius_uv = 0.14;
uniform vec2 aspect_fix = vec2(1.45, 1.0);

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * 1.4;
	float tl = luma(texture(TEXTURE, UV + vec2(-px.x, -px.y)).rgb);
	float tc = luma(texture(TEXTURE, UV + vec2(0.0, -px.y)).rgb);
	float tr = luma(texture(TEXTURE, UV + vec2(px.x, -px.y)).rgb);
	float ml = luma(texture(TEXTURE, UV + vec2(-px.x, 0.0)).rgb);
	float mc = luma(texture(TEXTURE, UV).rgb);
	float mr = luma(texture(TEXTURE, UV + vec2(px.x, 0.0)).rgb);
	float bl = luma(texture(TEXTURE, UV + vec2(-px.x, px.y)).rgb);
	float bc = luma(texture(TEXTURE, UV + vec2(0.0, px.y)).rgb);
	float br = luma(texture(TEXTURE, UV + vec2(px.x, px.y)).rgb);

	float gx = -tl - 2.0 * ml - bl + tr + 2.0 * mr + br;
	float gy = -tl - 2.0 * tc - tr + bl + 2.0 * bc + br;
	float edge = clamp(sqrt(gx * gx + gy * gy) * 2.5, 0.0, 1.0);

	float tone = floor(mc * 4.0) / 4.0;
	vec3 base_col = mix(vec3(0.071, 0.086, 0.102), vec3(0.145, 0.176, 0.204), tone * 0.72);
	vec3 ink_col = vec3(0.38, 0.42, 0.45);
	vec3 sketch = mix(base_col, ink_col, smoothstep(0.11, 0.46, edge));

	float hatch = step(0.84, fract((FRAGCOORD.x + FRAGCOORD.y) * 0.18));
	sketch = mix(sketch, vec3(0.048, 0.058, 0.070), (1.0 - tone) * hatch * 0.24);

	float vig = smoothstep(0.86, 0.20, length((UV - vec2(0.5)) * vec2(1.25, 1.0)));
	sketch *= mix(0.40, 1.0, vig);

	if (lantern_mode > 0.5) {
		float d = length((UV - lantern_uv) * aspect_fix);
		float lit = 1.0 - smoothstep(lantern_radius_uv * 0.55, lantern_radius_uv, d);
		vec3 warm_sketch = mix(sketch * vec3(1.42, 1.22, 0.90), vec3(0.906, 0.706, 0.353), smoothstep(0.20, 0.62, edge) * 0.48);
		sketch = mix(sketch * 0.08, warm_sketch, lit);
	}

	COLOR = vec4(sketch, 1.0);
}
"""

var player: Node2D = null
var current_corpse: Node2D = null
var current_case_id: String = "default"
var current_mode: String = "body" # "body" | "morgue" | "scene" | "board"
var selected_zone: String = ""
var is_female_model: bool = true

# Estado persistente por víctima / caso
var elapsed_minutes: int = 0
var findings_count: int = 0
var done_actions: Dictionary = {}      # "zone:act_id" -> true
var revealed_marks: Dictionary = {}    # "m-neck" -> true
var dynamic_wound_marks: Array[Dictionary] = [] # [{zone, type, label}]
var zone_data: Dictionary = {}         # zone_id -> {title, acts: [{id, name, cost, locked, find, tag, mark, note}]}
var current_finding: Dictionary = {}   # último hallazgo mostrado en el cuaderno derecho
var notebook_notes: Array[Dictionary] = [] # [{title, text, tag, source_key}]

# Nodos de cabecera y pestañas
var lbl_hdr_title: Label = null
var lbl_hdr_sub: Label = null
var lbl_meta_time: Label = null
var lbl_meta_finds: Label = null
var lbl_meta_light: Label = null
var btn_report_guard: Button = null
var btn_gender_toggle: Button = null
var tab_buttons: Dictionary = {}

# Contenedores de las 4 vistas
var view_body: Control = null
var view_morgue: Control = null
var view_scene: Control = null
var view_board: Control = null

# Vista D1: Examen del cuerpo
var body_sketch_tex_rect: TextureRect = null
var body_sketch_mat: ShaderMaterial = null
var lbl_corner_left: Label = null
var lbl_corner_right: Label = null
var silhouette_canvas: SilhouetteCanvas = null
var nb_zone_title: Label = null
var nb_zone_sub: Label = null
var nb_actions_grid: GridContainer = null
var nb_findings_box: VBoxContainer = null

# Tira inferior: Cuaderno del caso
var strip_notes_hbox: HBoxContainer = null
var lbl_strip_empty: Label = null


# ==============================================================================
# Subclase de dibujo para la silueta anatómica plana (Mujer / Hombre) + marcas + zonas
# ==============================================================================
class SilhouetteCanvas extends Control:
	var ui: DetectiveUI = null
	var hovered_zone: String = ""

	# Coordenadas base en espacio 220x460 (idéntico al viewBox="0 0 220 460" del boceto HTML)
	const BASE_W := 220.0
	const BASE_H := 460.0

	const ZONE_RECTS_F := {
		"cabeza": [Rect2(80, 18, 60, 62)],
		"cuello": [Rect2(93, 76, 34, 24)],
		"torso": [Rect2(66, 98, 88, 128)],
		"brazos": [Rect2(36, 102, 28, 126), Rect2(156, 102, 28, 126)],
		"manos": [Rect2(32, 228, 28, 38), Rect2(160, 228, 28, 38)],
		"bolsillos": [Rect2(64, 210, 32, 34), Rect2(124, 210, 32, 34)],
		"piernas": [Rect2(68, 244, 84, 198)],
	}
	const ZONE_RECTS_M := {
		"cabeza": [Rect2(80, 18, 60, 62)],
		"cuello": [Rect2(90, 76, 40, 24)],
		"torso": [Rect2(58, 98, 104, 128)],
		"brazos": [Rect2(28, 102, 30, 126), Rect2(162, 102, 30, 126)],
		"manos": [Rect2(24, 228, 30, 38), Rect2(166, 228, 30, 38)],
		"bolsillos": [Rect2(64, 210, 32, 34), Rect2(124, 210, 32, 34)],
		"piernas": [Rect2(68, 244, 84, 198)],
	}

	func _gui_input(event: InputEvent) -> void:
		if ui == null:
			return
		if event is InputEventMouseMotion:
			var z := _zone_at(event.position)
			if z != hovered_zone:
				hovered_zone = z
				mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if z != "" else Control.CURSOR_ARROW
				queue_redraw()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var z := _zone_at(event.position)
			if z != "":
				ui.select_zone(z)
				accept_event()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_EXIT:
			if hovered_zone != "":
				hovered_zone = ""
				queue_redraw()

	func _to_canvas(pt: Vector2) -> Vector2:
		var scale_f: float = minf(size.x / BASE_W, size.y / BASE_H)
		var off := (size - Vector2(BASE_W, BASE_H) * scale_f) * 0.5
		return off + pt * scale_f

	func _from_canvas(pos: Vector2) -> Vector2:
		var scale_f: float = maxf(0.01, minf(size.x / BASE_W, size.y / BASE_H))
		var off := (size - Vector2(BASE_W, BASE_H) * scale_f) * 0.5
		return (pos - off) / scale_f

	func _zone_at(pos: Vector2) -> String:
		var p := _from_canvas(pos)
		var rects: Dictionary = ZONE_RECTS_F if (ui == null or ui.is_female_model) else ZONE_RECTS_M
		# Priorizar bolsillos sobre torso/piernas cuando se solapan
		for z_id in ["bolsillos", "cabeza", "cuello", "manos", "brazos", "torso", "piernas"]:
			for r in rects.get(z_id, []):
				if (r as Rect2).has_point(p):
					return z_id
		return ""

	func _draw() -> void:
		if ui == null:
			return
		var fem: bool = ui.is_female_model
		var skin_fill := Color("#cfc6b4")
		var skin_stroke := Color("#5a5347")
		var hair_fill := Color("#4a3a2c")
		var hair_stroke := Color("#2e2319")

		# 1. Sombra suave bajo el cuerpo
		_draw_poly_scaled(PackedVector2Array([
			Vector2(56, 28), Vector2(164, 28), Vector2(188, 120), Vector2(184, 255),
			Vector2(154, 444), Vector2(66, 444), Vector2(36, 255), Vector2(32, 120)
		]), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 0.0)

		# 2. Pelo largo detrás de la cabeza y hombros (solo en modelo femenino, igual al SVG del boceto)
		if fem:
			var hair_pts := PackedVector2Array([
				Vector2(82, 34), Vector2(74, 52), Vector2(73, 76), Vector2(76, 98),
				Vector2(82, 108), Vector2(92, 110), Vector2(128, 110), Vector2(138, 108),
				Vector2(144, 98), Vector2(147, 76), Vector2(146, 52), Vector2(138, 34),
				Vector2(124, 22), Vector2(96, 22)
			])
			_draw_poly_scaled(hair_pts, hair_fill, hair_stroke, 1.5)

		# 3. Silueta anatómica plana de una pieza (sin líneas interiores ni cara)
		var body_pts: PackedVector2Array
		if fem:
			body_pts = PackedVector2Array([
				# Cabeza superior-derecha
				Vector2(110, 22), Vector2(124, 24), Vector2(134, 34), Vector2(135, 50),
				Vector2(134, 65), Vector2(128, 75), Vector2(120, 79),
				# Cuello derecho y hombro derecho más estrecho
				Vector2(121, 93), Vector2(136, 96), Vector2(154, 99), Vector2(162, 107),
				# Brazo derecho y mano derecha
				Vector2(170, 116), Vector2(174, 146), Vector2(177, 184), Vector2(180, 226),
				Vector2(183, 244), Vector2(177, 259), Vector2(167, 257), Vector2(163, 242),
				Vector2(163, 226), Vector2(160, 186), Vector2(155, 146), Vector2(148, 124),
				# Pecho, cintura marcada y cadera redondeada derecha
				Vector2(148, 142), Vector2(145, 160), Vector2(140, 178), Vector2(146, 196),
				Vector2(154, 214), Vector2(156, 232), Vector2(151, 252),
				# Pierna derecha exterior y pie derecho
				Vector2(148, 304), Vector2(145, 360), Vector2(142, 412),
				Vector2(146, 428), Vector2(142, 439), Vector2(126, 439), Vector2(121, 427),
				# Interior pierna derecha hasta entrepierna
				Vector2(121, 368), Vector2(118, 304), Vector2(115, 252),
				Vector2(110, 247), Vector2(105, 252),
				# Interior pierna izquierda y pie izquierdo
				Vector2(102, 304), Vector2(99, 368), Vector2(99, 427),
				Vector2(94, 439), Vector2(78, 439), Vector2(74, 428), Vector2(78, 412),
				# Pierna izquierda exterior, cadera y cintura izquierda
				Vector2(75, 360), Vector2(72, 304), Vector2(69, 252),
				Vector2(64, 232), Vector2(66, 214), Vector2(74, 196), Vector2(80, 178),
				Vector2(75, 160), Vector2(72, 142), Vector2(72, 124),
				# Brazo izquierdo y mano izquierda
				Vector2(65, 146), Vector2(60, 186), Vector2(57, 226), Vector2(57, 242),
				Vector2(53, 257), Vector2(43, 259), Vector2(37, 244), Vector2(40, 226),
				Vector2(43, 184), Vector2(46, 146), Vector2(50, 116),
				# Hombro izquierdo, cuello y cabeza izquierda
				Vector2(58, 107), Vector2(66, 99), Vector2(84, 96), Vector2(99, 93),
				Vector2(100, 79), Vector2(92, 75), Vector2(86, 65), Vector2(85, 50),
				Vector2(86, 34), Vector2(96, 24)
			])
		else:
			# Modelo masculino: hombros más anchos, torso recto, cadera estrecha, brazos más gruesos, sin melena
			body_pts = PackedVector2Array([
				Vector2(110, 22), Vector2(125, 24), Vector2(135, 34), Vector2(136, 50),
				Vector2(135, 65), Vector2(129, 75), Vector2(122, 79),
				# Cuello y hombro masculino ancho
				Vector2(124, 92), Vector2(146, 95), Vector2(166, 99), Vector2(174, 108),
				# Brazo derecho y mano derecha
				Vector2(180, 120), Vector2(183, 152), Vector2(185, 190), Vector2(187, 226),
				Vector2(190, 244), Vector2(183, 259), Vector2(171, 257), Vector2(167, 242),
				Vector2(167, 226), Vector2(164, 188), Vector2(160, 148), Vector2(156, 126),
				# Torso masculino recto y cadera estrecha
				Vector2(154, 154), Vector2(150, 184), Vector2(149, 214), Vector2(148, 248),
				# Pierna derecha
				Vector2(146, 304), Vector2(144, 360), Vector2(142, 412),
				Vector2(146, 428), Vector2(142, 439), Vector2(125, 439), Vector2(120, 427),
				Vector2(120, 368), Vector2(118, 304), Vector2(115, 252),
				Vector2(110, 248), Vector2(105, 252),
				# Pierna izquierda
				Vector2(102, 304), Vector2(100, 368), Vector2(100, 427),
				Vector2(95, 439), Vector2(78, 439), Vector2(74, 428), Vector2(78, 412),
				Vector2(76, 360), Vector2(74, 304), Vector2(72, 248),
				Vector2(71, 214), Vector2(70, 184), Vector2(66, 154), Vector2(64, 126),
				# Brazo izquierdo
				Vector2(60, 148), Vector2(56, 188), Vector2(53, 226), Vector2(53, 242),
				Vector2(49, 257), Vector2(37, 259), Vector2(30, 244), Vector2(33, 226),
				Vector2(35, 190), Vector2(37, 152), Vector2(40, 120),
				Vector2(46, 108), Vector2(54, 99), Vector2(74, 95), Vector2(96, 92),
				Vector2(98, 79), Vector2(91, 75), Vector2(85, 65), Vector2(84, 50),
				Vector2(85, 34), Vector2(95, 24)
			])
		_draw_poly_scaled(body_pts, skin_fill, skin_stroke, 2.0)

		# 4. Marcas descubiertas al inspeccionar (exactas al boceto HTML + heridas reales)
		if ui.revealed_marks.get("m-neck") == true:
			_draw_rect_scaled(Rect2(96, 83, 28, 7), Color(0.49, 0.35, 0.65, 0.72), Color(0, 0, 0, 0), 0.0)
			_draw_circle_outline_scaled(Vector2(110, 86), 16.0, COL_BRUISE, 1.4, true)
		if ui.revealed_marks.get("m-wrist") == true:
			var lx: float = 42.0 if fem else 34.0
			var rx: float = 164.0 if fem else 172.0
			_draw_line_scaled(Vector2(lx, 232), Vector2(lx + 14.0, 235), COL_BLOOD, 2.2)
			_draw_line_scaled(Vector2(rx, 235), Vector2(rx + 14.0, 232), COL_BLOOD, 2.2)
		if ui.revealed_marks.get("m-heel") == true:
			_draw_circle_filled_scaled(Vector2(85, 432), 7.5, Color(0.36, 0.27, 0.20, 0.78))
			_draw_circle_filled_scaled(Vector2(135, 432), 7.5, Color(0.36, 0.27, 0.20, 0.78))
		if ui.revealed_marks.get("m-pocket") == true:
			_draw_circle_outline_scaled(Vector2(140, 224), 9.0, COL_LAMP, 1.6, false)

		for wm in ui.dynamic_wound_marks:
			if ui.revealed_marks.get(str(wm.get("mark_id", ""))) != true:
				continue
			var wz: String = str(wm.get("zone", "torso"))
			var wtype: String = str(wm.get("type", "cut"))
			var center_pt := Vector2(110, 155)
			match wz:
				"cabeza": center_pt = Vector2(118, 48)
				"cuello": center_pt = Vector2(110, 86)
				"torso": center_pt = Vector2(102, 150)
				"brazos": center_pt = Vector2(52, 165)
				"manos": center_pt = Vector2(48, 242)
				"piernas": center_pt = Vector2(88, 330)
			if wtype == "bruise":
				_draw_circle_filled_scaled(center_pt, 10.0, Color(0.49, 0.35, 0.65, 0.68))
				_draw_circle_outline_scaled(center_pt, 12.0, COL_BRUISE, 1.3, true)
			else:
				_draw_line_scaled(center_pt + Vector2(-9, -5), center_pt + Vector2(9, 6), COL_BLOOD, 2.5)
				_draw_circle_outline_scaled(center_pt, 12.0, COL_BLOOD, 1.3, true)

		# 5. Resaltado de zona bajo el ratón o zona seleccionada
		var rects_map: Dictionary = ZONE_RECTS_F if fem else ZONE_RECTS_M
		if hovered_zone != "" and hovered_zone != ui.selected_zone:
			for r in rects_map.get(hovered_zone, []):
				_draw_rect_scaled(r as Rect2, Color(0.906, 0.706, 0.353, 0.08), COL_LAMP, 1.4, true)
		if ui.selected_zone != "":
			for r in rects_map.get(ui.selected_zone, []):
				_draw_rect_scaled(r as Rect2, Color(0.906, 0.706, 0.353, 0.16), COL_LAMP, 1.8, false)

	func _draw_poly_scaled(pts: PackedVector2Array, fill_c: Color, stroke_c: Color, width: float) -> void:
		var scaled := PackedVector2Array()
		for p in pts:
			scaled.append(_to_canvas(p))
		if fill_c.a > 0.01:
			draw_colored_polygon(scaled, fill_c)
		if stroke_c.a > 0.01 and width > 0.0:
			var closed := scaled.duplicate()
			closed.append(scaled[0])
			draw_polyline(closed, stroke_c, width, true)

	func _draw_rect_scaled(r: Rect2, fill_c: Color, stroke_c: Color, width: float, dashed: bool = false) -> void:
		var p0 := _to_canvas(r.position)
		var p1 := _to_canvas(r.position + r.size)
		var sr := Rect2(p0, p1 - p0)
		if fill_c.a > 0.01:
			draw_rect(sr, fill_c, true)
		if stroke_c.a > 0.01 and width > 0.0:
			if dashed:
				_draw_dashed_rect(sr, stroke_c, width)
			else:
				draw_rect(sr, stroke_c, false, width)

	func _draw_dashed_rect(sr: Rect2, col: Color, width: float) -> void:
		var corners := [
			sr.position,
			Vector2(sr.end.x, sr.position.y),
			sr.end,
			Vector2(sr.position.x, sr.end.y)
		]
		for i in range(4):
			draw_dashed_line(corners[i], corners[(i + 1) % 4], col, width, 5.0)

	func _draw_line_scaled(a: Vector2, b: Vector2, col: Color, width: float) -> void:
		draw_line(_to_canvas(a), _to_canvas(b), col, width, true)

	func _draw_circle_filled_scaled(c: Vector2, radius: float, col: Color) -> void:
		var scale_f: float = minf(size.x / BASE_W, size.y / BASE_H)
		draw_circle(_to_canvas(c), radius * scale_f, col)

	func _draw_circle_outline_scaled(c: Vector2, radius: float, col: Color, width: float, dashed: bool) -> void:
		var scale_f: float = minf(size.x / BASE_W, size.y / BASE_H)
		var center := _to_canvas(c)
		var rad := radius * scale_f
		if not dashed:
			draw_arc(center, rad, 0.0, TAU, 28, col, width, true)
		else:
			var segs := 12
			for i in range(segs):
				var a0 := (TAU * float(i)) / float(segs)
				var a1 := a0 + (TAU / float(segs)) * 0.55
				draw_arc(center, rad, a0, a1, 4, col, width, true)


# ==============================================================================
# Construcción de la interfaz
# ==============================================================================
func _ready() -> void:
	name = "DetectiveUI"
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()

func _style_box(bg: Color, border: Color, border_w: int = 1, radius: int = 0, pad_x: int = 12, pad_y: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad_x
	s.content_margin_right = pad_x
	s.content_margin_top = pad_y
	s.content_margin_bottom = pad_y
	return s

func _build_ui() -> void:
	var bg_panel := PanelContainer.new()
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_panel.add_theme_stylebox_override("panel", _style_box(COL_NIGHT, COL_EDGE, 0, 0, 18, 14))
	add_child(bg_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 10)
	bg_panel.add_child(root_vbox)

	# 1. Cabecera superior (Título, subtítulo, metadatos y cierre)
	var hdr_panel := PanelContainer.new()
	var hdr_style := _style_box(COL_NIGHT, COL_EDGE, 0, 0, 4, 6)
	hdr_style.border_width_bottom = 1
	hdr_panel.add_theme_stylebox_override("panel", hdr_style)
	root_vbox.add_child(hdr_panel)

	var hdr_hbox := HBoxContainer.new()
	hdr_hbox.add_theme_constant_override("separation", 18)
	hdr_panel.add_child(hdr_hbox)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 2)
	hdr_hbox.add_child(title_vbox)

	lbl_hdr_title = Label.new()
	lbl_hdr_title.text = "Examen del cuerpo"
	lbl_hdr_title.add_theme_font_size_override("font_size", 20)
	lbl_hdr_title.add_theme_color_override("font_color", COL_INK)
	title_vbox.add_child(lbl_hdr_title)

	lbl_hdr_sub = Label.new()
	lbl_hdr_sub.text = "Caso I · «La mujer del bosque» — hallada al alba junto al arroyo del norte"
	lbl_hdr_sub.add_theme_font_size_override("font_size", 12)
	lbl_hdr_sub.add_theme_color_override("font_color", COL_DIM)
	title_vbox.add_child(lbl_hdr_sub)

	lbl_meta_time = _make_meta_label(hdr_hbox, "Tiempo en la escena  0 min")
	lbl_meta_finds = _make_meta_label(hdr_hbox, "Hallazgos  0")
	lbl_meta_light = _make_meta_label(hdr_hbox, "Luz  Farol")

	btn_report_guard = _make_header_btn("📢 Avisar a la guardia", func():
		if is_instance_valid(current_corpse) and current_corpse.has_method("report_corpse_by_player"):
			current_corpse.call("report_corpse_by_player", player)
			_update_header_meta()
	)
	hdr_hbox.add_child(btn_report_guard)

	var btn_close := _make_header_btn("[Esc] Cerrar", func(): close_panel())
	hdr_hbox.add_child(btn_close)

	# 2. Barra de modos (4 pestañas + selector de silueta Mujer/Hombre)
	var mode_hbox := HBoxContainer.new()
	mode_hbox.add_theme_constant_override("separation", 8)
	root_vbox.add_child(mode_hbox)

	var tabs_def := [
		{"id": "body", "label": "1 · En la escena"},
		{"id": "morgue", "label": "2 · Autopsia en la morgue"},
		{"id": "scene", "label": "3 · Escena del crimen"},
		{"id": "board", "label": "4 · Tablero del caso"},
	]
	for td in tabs_def:
		var tid: String = td["id"]
		var b := Button.new()
		b.text = td["label"]
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(func(): switch_mode(tid))
		mode_hbox.add_child(b)
		tab_buttons[tid] = b

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_hbox.add_child(spacer)

	var lbl_body_model := Label.new()
	lbl_body_model.text = "Cuerpo:"
	lbl_body_model.add_theme_font_size_override("font_size", 11)
	lbl_body_model.add_theme_color_override("font_color", COL_DIM)
	mode_hbox.add_child(lbl_body_model)

	btn_gender_toggle = _make_header_btn("Mujer", func():
		set_body_gender(not is_female_model)
	)
	mode_hbox.add_child(btn_gender_toggle)

	# 3. Contenedor central de vistas
	var views_holder := Control.new()
	views_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	views_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(views_holder)

	view_body = _build_body_view()
	views_holder.add_child(view_body)

	view_morgue = _build_placeholder_view("Autopsia en la morgue (Bloque D2)")
	views_holder.add_child(view_morgue)

	view_scene = _build_placeholder_view("Escena del crimen (Bloque D3)")
	views_holder.add_child(view_scene)

	view_board = _build_placeholder_view("Tablero del caso (Bloque D4)")
	views_holder.add_child(view_board)

	# 4. Tira inferior: Cuaderno del caso (fichas clavadas con chincheta roja)
	var strip_panel := PanelContainer.new()
	strip_panel.custom_minimum_size = Vector2(0, 88)
	strip_panel.add_theme_stylebox_override("panel", _style_box(COL_PANEL, COL_EDGE, 1, 0, 12, 8))
	root_vbox.add_child(strip_panel)

	var strip_vbox := VBoxContainer.new()
	strip_vbox.add_theme_constant_override("separation", 6)
	strip_panel.add_child(strip_vbox)

	var strip_title := Label.new()
	strip_title.text = "CUADERNO DEL CASO (PISTAS QUE HAS DECIDIDO GUARDAR)"
	strip_title.add_theme_font_size_override("font_size", 10)
	strip_title.add_theme_color_override("font_color", COL_DIM)
	strip_vbox.add_child(strip_title)

	var strip_scroll := ScrollContainer.new()
	strip_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	strip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip_vbox.add_child(strip_scroll)

	strip_notes_hbox = HBoxContainer.new()
	strip_notes_hbox.add_theme_constant_override("separation", 10)
	strip_scroll.add_child(strip_notes_hbox)

	lbl_strip_empty = Label.new()
	lbl_strip_empty.text = "Todavía no has anotado nada. No todo lo que veas importa: anota solo lo que quieras llevar al juicio o cruzar con testigos."
	lbl_strip_empty.add_theme_font_size_override("font_size", 12)
	lbl_strip_empty.add_theme_color_override("font_color", COL_DIM)
	strip_notes_hbox.add_child(lbl_strip_empty)

	_refresh_tab_styles()


func _make_meta_label(parent: Node, txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", COL_LAMP)
	parent.add_child(l)
	return l


func _make_header_btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", COL_INK)
	b.add_theme_stylebox_override("normal", _style_box(Color("#262e35"), COL_EDGE, 1, 0, 10, 5))
	b.add_theme_stylebox_override("hover", _style_box(Color("#303a43"), COL_LAMP, 1, 0, 10, 5))
	b.add_theme_stylebox_override("pressed", _style_box(COL_LAMP, COL_LAMP, 1, 0, 10, 5))
	b.pressed.connect(cb)
	return b


func _build_placeholder_view(title_txt: String) -> Control:
	var p := PanelContainer.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_theme_stylebox_override("panel", _style_box(COL_PANEL, COL_EDGE, 1, 0, 20, 20))
	p.visible = false
	var l := Label.new()
	l.text = title_txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", COL_DIM)
	p.add_child(l)
	return p


# ==============================================================================
# Vista 1 (Bloque D1): Examen del cuerpo en la escena
# ==============================================================================
func _build_body_view() -> Control:
	var split := HBoxContainer.new()
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	split.add_theme_constant_override("separation", 14)

	# Izquierda: Camilla / suelo con fondo 3D cenital en esquema + silueta plana interactiva
	var tray_panel := PanelContainer.new()
	tray_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tray_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tray_panel.size_flags_stretch_ratio = 1.25
	tray_panel.add_theme_stylebox_override("panel", _style_box(COL_PANEL, COL_EDGE, 1, 0, 0, 0))
	split.add_child(tray_panel)

	var tray_overlay := Control.new()
	tray_overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tray_overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tray_overlay.clip_contents = true
	tray_panel.add_child(tray_overlay)

	# Imagen cenital 3D en esquema del lugar donde yace el cadáver
	body_sketch_tex_rect = TextureRect.new()
	body_sketch_tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body_sketch_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	body_sketch_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var sh := Shader.new()
	sh.code = SKETCH_SHADER_CODE
	body_sketch_mat = ShaderMaterial.new()
	body_sketch_mat.shader = sh
	body_sketch_tex_rect.material = body_sketch_mat
	tray_overlay.add_child(body_sketch_tex_rect)

	# Etiquetas de esquina (CADÁVER EN EL SUELO / TEMPERATURA)
	lbl_corner_left = Label.new()
	lbl_corner_left.text = "CADÁVER EN EL SUELO · NO MOVIDO"
	lbl_corner_left.position = Vector2(12, 10)
	lbl_corner_left.add_theme_font_size_override("font_size", 11)
	lbl_corner_left.add_theme_color_override("font_color", COL_DIM)
	tray_overlay.add_child(lbl_corner_left)

	lbl_corner_right = Label.new()
	lbl_corner_right.text = "TEMPERATURA AMBIENTE · FRÍO"
	lbl_corner_right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lbl_corner_right.offset_left = -240
	lbl_corner_right.offset_right = -12
	lbl_corner_right.offset_top = 10
	lbl_corner_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_corner_right.add_theme_font_size_override("font_size", 11)
	lbl_corner_right.add_theme_color_override("font_color", COL_DIM)
	tray_overlay.add_child(lbl_corner_right)

	# Silueta anatómica plana (Mujer / Hombre)
	silhouette_canvas = SilhouetteCanvas.new()
	silhouette_canvas.ui = self
	silhouette_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	silhouette_canvas.offset_top = 28
	silhouette_canvas.offset_bottom = -34
	tray_overlay.add_child(silhouette_canvas)

	# Leyenda inferior de la bandeja del cuerpo
	var legend_hbox := HBoxContainer.new()
	legend_hbox.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	legend_hbox.offset_left = 14
	legend_hbox.offset_right = -14
	legend_hbox.offset_top = -28
	legend_hbox.offset_bottom = -8
	legend_hbox.add_theme_constant_override("separation", 16)
	tray_overlay.add_child(legend_hbox)

	_add_legend_dot(legend_hbox, COL_BRUISE, "Contusión / lividez")
	_add_legend_dot(legend_hbox, COL_BLOOD, "Herida / rozadura")
	_add_legend_dot(legend_hbox, COL_LAMP, "Objeto / resto")
	var leg_spacer := Control.new()
	leg_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legend_hbox.add_child(leg_spacer)
	var leg_hint := Label.new()
	leg_hint.text = "Haz clic en una parte del cuerpo"
	leg_hint.add_theme_font_size_override("font_size", 11)
	leg_hint.add_theme_color_override("font_color", COL_DIM)
	legend_hbox.add_child(leg_hint)

	# Derecha: Cuaderno de papel con zonas, acciones y hallazgos
	var nb_panel := PanelContainer.new()
	nb_panel.custom_minimum_size = Vector2(390, 0)
	nb_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nb_panel.add_theme_stylebox_override("panel", _style_box(COL_PAPER, COL_PAPER_EDGE, 1, 0, 16, 14))
	split.add_child(nb_panel)

	var nb_vbox := VBoxContainer.new()
	nb_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nb_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nb_vbox.add_theme_constant_override("separation", 10)
	nb_panel.add_child(nb_vbox)

	nb_zone_title = Label.new()
	nb_zone_title.text = "Selecciona una zona del cuerpo"
	nb_zone_title.add_theme_font_size_override("font_size", 17)
	nb_zone_title.add_theme_color_override("font_color", COL_PAPER_INK)
	nb_vbox.add_child(nb_zone_title)

	nb_zone_sub = Label.new()
	nb_zone_sub.text = "Cada inspección lleva unos minutos. La guardia y los curiosos no esperan eternamente."
	nb_zone_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nb_zone_sub.add_theme_font_size_override("font_size", 12)
	nb_zone_sub.add_theme_color_override("font_color", Color("#6a6254"))
	nb_vbox.add_child(nb_zone_sub)

	var sep := HSeparator.new()
	nb_vbox.add_child(sep)

	nb_actions_grid = GridContainer.new()
	nb_actions_grid.columns = 2
	nb_actions_grid.add_theme_constant_override("h_separation", 6)
	nb_actions_grid.add_theme_constant_override("v_separation", 6)
	nb_vbox.add_child(nb_actions_grid)

	var nb_scroll := ScrollContainer.new()
	nb_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nb_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nb_vbox.add_child(nb_scroll)

	nb_findings_box = VBoxContainer.new()
	nb_findings_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nb_findings_box.add_theme_constant_override("separation", 8)
	nb_scroll.add_child(nb_findings_box)

	return split


func _add_legend_dot(parent: Node, col: Color, txt: String) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 5)
	var dot := ColorRect.new()
	dot.color = col
	dot.custom_minimum_size = Vector2(9, 9)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(dot)
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", COL_DIM)
	hb.add_child(l)
	parent.add_child(hb)


# ==============================================================================
# Apertura, cierre y sincronización con datos reales del cadáver y del mundo
# ==============================================================================
func open_for_corpse(corpse_node: Node2D, initial_mode: String = "body") -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
	current_corpse = corpse_node
	visible = true
	if WorldClock != null:
		WorldClock.set_activity_pause(true)

	_build_case_from_corpse(corpse_node)
	_refresh_3d_topdown_sketch()
	switch_mode(initial_mode)
	if selected_zone == "":
		select_zone("cuello")
	else:
		_render_notebook_zone()
	_render_strip_notes()
	_update_header_meta()


func close_panel() -> void:
	if not visible:
		return
	visible = false
	var st := _find_world_stage_3d()
	if st != null and st.has_method("set_detective_topdown"):
		st.call("set_detective_topdown", false)
	if WorldClock != null:
		WorldClock.set_activity_pause(false)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			close_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_1:
			switch_mode("body")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2:
			switch_mode("morgue")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3:
			switch_mode("scene")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_4:
			switch_mode("board")
			get_viewport().set_input_as_handled()


func switch_mode(mode_id: String) -> void:
	current_mode = mode_id
	view_body.visible = (mode_id == "body")
	view_morgue.visible = (mode_id == "morgue")
	view_scene.visible = (mode_id == "scene")
	view_board.visible = (mode_id == "board")
	_refresh_tab_styles()
	_refresh_3d_topdown_sketch()
	_update_header_meta()


func _refresh_tab_styles() -> void:
	for tid in tab_buttons.keys():
		var b: Button = tab_buttons[tid]
		var act: bool = (tid == current_mode)
		var bg := COL_LAMP if act else Color("#262e35")
		var fg := Color("#18140d") if act else COL_INK
		b.add_theme_color_override("font_color", fg)
		b.add_theme_color_override("font_hover_color", fg)
		b.add_theme_color_override("font_pressed_color", fg)
		b.add_theme_stylebox_override("normal", _style_box(bg, COL_LAMP if act else COL_EDGE, 1, 0, 12, 6))
		b.add_theme_stylebox_override("hover", _style_box(bg.lightened(0.08), COL_LAMP, 1, 0, 12, 6))
		b.add_theme_stylebox_override("pressed", _style_box(COL_LAMP, COL_LAMP, 1, 0, 12, 6))


func set_body_gender(female: bool) -> void:
	is_female_model = female
	if btn_gender_toggle != null:
		btn_gender_toggle.text = "Mujer" if female else "Hombre"
	if silhouette_canvas != null:
		silhouette_canvas.queue_redraw()


func _find_world_stage_3d() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.find_child("WorldStage3D", true, false)


func _refresh_3d_topdown_sketch() -> void:
	var st := _find_world_stage_3d()
	if st == null or not st.has_method("set_detective_topdown"):
		return
	if not visible or current_mode not in ["body", "scene"]:
		st.call("set_detective_topdown", false)
		return
	var target_pos := Vector2(465, 48)
	if is_instance_valid(current_corpse):
		var d_pos = current_corpse.get("death_world_pos")
		if d_pos is Vector2 and (d_pos as Vector2) != Vector2.ZERO and current_mode == "scene":
			target_pos = d_pos
		else:
			target_pos = current_corpse.global_position
	elif player != null and is_instance_valid(player):
		target_pos = player.global_position
	var ortho_sz: float = 3.6 if current_mode == "body" else 5.2
	var tex: Texture2D = st.call("set_detective_topdown", true, target_pos, ortho_sz)
	if body_sketch_tex_rect != null and tex != null:
		body_sketch_tex_rect.texture = tex
	if body_sketch_mat != null:
		body_sketch_mat.set_shader_parameter("lantern_mode", 0.0)


func _player_has_magnifying_glass() -> bool:
	if player == null or not is_instance_valid(player):
		return true
	var inv = player.get("inventory")
	if inv != null and inv.has_method("has_item"):
		return bool(inv.call("has_item", "magnifying_glass", 1))
	return true


func _advance_investigation_minutes(mins: int) -> void:
	if mins <= 0:
		return
	elapsed_minutes += mins
	if WorldClock != null and WorldClock.has_method("_advance_one_minute"):
		for _i in range(mins):
			WorldClock.call("_advance_one_minute")
	_update_header_meta()


func _update_header_meta() -> void:
	if lbl_hdr_title != null:
		match current_mode:
			"body": lbl_hdr_title.text = "Examen del cuerpo"
			"morgue": lbl_hdr_title.text = "Autopsia en la morgue"
			"scene": lbl_hdr_title.text = "Escena del crimen"
			"board": lbl_hdr_title.text = "Tablero del caso"
	if lbl_meta_time != null:
		lbl_meta_time.text = "Tiempo en la escena  %d min" % elapsed_minutes
	if lbl_meta_finds != null:
		lbl_meta_finds.text = "Hallazgos  %d" % findings_count
	if lbl_meta_light != null:
		var is_morgue: bool = (current_mode == "morgue") or (is_instance_valid(current_corpse) and current_corpse.get("corpse_in_morgue") == true)
		lbl_meta_light.text = "Luz  Lámpara médica" if is_morgue else "Luz  Farol"
	if btn_report_guard != null:
		var can_rep: bool = is_instance_valid(current_corpse) and current_corpse.get("is_dead") == true and current_corpse.get("corpse_in_morgue") != true and current_corpse.get("corpse_reported") != true
		btn_report_guard.visible = can_rep


# ==============================================================================
# Construcción de las 7 zonas anatómicas (datos reales del cadáver o caso guionizado)
# ==============================================================================
func _build_case_from_corpse(corpse_node: Node2D) -> void:
	dynamic_wound_marks.clear()
	var has_lupa: bool = _player_has_magnifying_glass()

	# Si no hay cadáver específico o tiene el metadato del Caso I («La mujer del bosque»), usar los datos de referencia
	if corpse_node == null or not is_instance_valid(corpse_node) or corpse_node.has_meta("scripted_case_zones"):
		set_body_gender(true)
		if lbl_hdr_sub != null:
			lbl_hdr_sub.text = "Caso I · «La mujer del bosque» — hallada al alba junto al arroyo del norte"
		if lbl_corner_left != null:
			lbl_corner_left.text = "CADÁVER EN EL SUELO · NO MOVIDO"
		if lbl_corner_right != null:
			lbl_corner_right.text = "TEMPERATURA AMBIENTE · FRÍO DE MADRUGADA"
		zone_data = _get_default_forest_woman_zones(has_lupa)
		return

	var v_name: String = str(corpse_node.get("npc_name"))
	var v_role: String = str(corpse_node.get("npc_role"))
	var prof = corpse_node.get("person_profile")
	var fem: bool = (prof != null and str(prof.get("gender")) == "F") or (prof == null and v_name.ends_with("a"))
	set_body_gender(fem)

	var vm = get_tree().get_first_node_in_group("village_manager")
	var f_state: Dictionary = vm.VillageForensics.state(vm) if (vm != null and "VillageForensics" in vm) else {}
	var is_moved: bool = (f_state.get("moved", {}) as Dictionary).has(v_name)
	var is_poisoned: bool = (f_state.get("poisoned", {}) as Dictionary).has(v_name)
	var is_tampered_time: bool = (f_state.get("tampered_time", {}) as Dictionary).has(v_name)
	var planted_info: Dictionary = (f_state.get("planted", {}) as Dictionary).get(v_name, {})
	var weapon_cause: String = str(corpse_node.get("last_hit_weapon_name"))
	var rot_h: float = float(corpse_node.get("corpse_rot_hours"))

	if lbl_hdr_sub != null:
		var hallado_str: String = "hallada" if fem else "hallado"
		lbl_hdr_sub.text = "Caso · %s (%s) — %s en el valle" % [v_name, v_role if v_role != "" else "Vecino", hallado_str]
	if lbl_corner_left != null:
		if corpse_node.get("corpse_in_morgue") == true:
			lbl_corner_left.text = "CAMILLA DE LA MORGUE · %s" % v_name.to_upper()
		elif is_moved:
			lbl_corner_left.text = "CADÁVER EN EL SUELO · POSICIÓN EXTRAÑA"
		else:
			lbl_corner_left.text = "CADÁVER EN EL SUELO · NO MOVIDO"
	if lbl_corner_right != null:
		var w_str: String = WorldClock.get_weather_name() if (WorldClock != null and WorldClock.has_method("get_weather_name")) else "FRÍO"
		lbl_corner_right.text = "CLIMA · %s (%.1f H SIN VIDA)" % [w_str.to_upper(), maxf(0.2, rot_h)]

	# Recopilar heridas reales por región desde HealthComponent
	var hc = corpse_node.get("health_comp")
	var wounds_by_zone: Dictionary = {"cabeza": [], "torso": [], "brazos": [], "piernas": []}
	if hc != null and hc.get("wounds") is Array:
		var w_idx: int = 0
		for w in (hc.get("wounds") as Array):
			if not (w is Dictionary):
				continue
			var reg: String = str(w.get("region", "torso"))
			var target_z := "torso"
			if reg == "head":
				target_z = "cabeza"
			elif reg in ["left_arm", "right_arm"]:
				target_z = "brazos"
			elif reg in ["left_leg", "right_leg"]:
				target_z = "piernas"
			wounds_by_zone[target_z].append(w)
			var w_type: String = "bruise" if str(w.get("type", "")) in ["bruise", "fracture"] else "cut"
			dynamic_wound_marks.append({
				"mark_id": "m-dyn-%s" % target_z,
				"zone": target_z,
				"type": w_type
			})
			w_idx += 1

	# Construir las 7 zonas combinando los datos reales del cuerpo y el formato forense de D1
	var head_wounds_txt: String = _describe_zone_wounds(wounds_by_zone["cabeza"], weapon_cause, "No hay golpe abierto en el cráneo. Ojos vidriosos y labios amoratados.")
	var torso_wounds_txt: String = _describe_zone_wounds(wounds_by_zone["torso"], weapon_cause, "Ropa húmeda pegada al pecho. Sin cortes ni agujeros de hoja en la tela.")
	var arm_wounds_txt: String = _describe_zone_wounds(wounds_by_zone["brazos"], weapon_cause, "Dos marcas rojas estrechas rodean las muñecas, como si la hubieran sujetado con fuerza o atado con cuerda fina.")
	var leg_wounds_txt: String = _describe_zone_wounds(wounds_by_zone["piernas"], weapon_cause, "Falta el zapato izquierdo. Los dos talones tienen barro oscuro por detrás, como si hubieran arrastrado el cuerpo." if is_moved else "Calzado puesto; manchas de tierra húmeda del lugar donde cayó.")

	var pocket_summary: String = corpse_node.call("get_pocket_summary_text") if corpse_node.has_method("get_pocket_summary_text") else "Bolsillos con pertenencias"
	if not planted_info.is_empty() and planted_info.get("debunked") != true:
		pocket_summary += ". Además asoma un objeto personal de %s que parece colocado a propósito." % str(planted_info.get("framed_name", "otro vecino"))

	zone_data = {
		"cabeza": {
			"title": "Cabeza y rostro",
			"acts": [
				{"id": "mirar", "name": "Mirar de cerca", "cost": 2, "find": head_wounds_txt, "mark": "m-dyn-cabeza" if not wounds_by_zone["cabeza"].is_empty() else "", "note": "Cabeza (%s): %s" % [v_name, head_wounds_txt]},
				{"id": "oler", "name": "Oler boca y nariz", "cost": 2, "find": "Un olor suave y amargo, como a almendra machacada o hierba cocida, sale todavía de la boca." if (is_poisoned or weapon_cause.to_lower().find("veneno") != -1) else "No huele a alcohol ni a brebaje amargo en los labios.", "tag": "Olor: almendra amarga" if is_poisoned else "", "note": "Aliento (%s): %s" % [v_name, "olor amargo en la boca (posible tóxico ingerido)." if is_poisoned else "sin rastro de veneno oral ni licor."]},
				{"id": "palpar", "name": "Palpar cráneo", "cost": 3, "find": "Se nota crepitación ósea o hematoma en la sien." if not wounds_by_zone["cabeza"].is_empty() else "Hueso entero, sin hundimientos. No murió de una pedrada ni de un porrazo en la cabeza."},
				{"id": "lupa", "name": "Usar lupa en el pelo", "cost": 4, "locked": not has_lupa, "find": "Entre el pelo hay polen amarillo de sauce y briznas del lugar donde cayó." if has_lupa else "Hace falta llevar una Lupa de Latón en el inventario para examinar fibras y polen."}
			]
		},
		"cuello": {
			"title": "Cuello y garganta",
			"acts": [
				{"id": "mirar", "name": "Mirar la piel", "cost": 2, "find": "Una franja morada cruza la garganta, pero está borrosa: la sangre se ha ido hacia la nuca horas después." if (is_moved or weapon_cause == "") else ("Herida visible causada por %s." % weapon_cause), "mark": "m-neck", "note": "Cuello (%s): surco morado en la garganta y lividez desplazada." % v_name},
				{"id": "palpar", "name": "Palpar garganta", "cost": 3, "find": "Desde fuera se nota el cartílago rígido, pero sin abrir en la morgue no puedes saber si el hueso interno está roto o si apretaron antes o después de morir."},
				{"id": "lupa", "name": "Usar lupa en el surco", "cost": 5, "locked": not has_lupa, "find": "En los bordes del surco no hay pellejos levantados ni sangre coagulada: apretaron cuando el corazón ya latía muy débil o estaba parado." if has_lupa else "Hace falta llevar una Lupa de Latón para revisar la epidermis del surco.", "tag": "Surco sin sangrado", "note": "Surco del cuello (%s): sin sangrado en los bordes; posible simulación." % v_name},
				{"id": "interna", "name": "Abrir tráquea", "cost": 0, "locked": true, "find": "Hace falta llevar el cuerpo a la morgue para abrir y ver si el hueso del cuello está roto."}
			]
		},
		"torso": {
			"title": "Pecho y vestido",
			"acts": [
				{"id": "mirar", "name": "Mirar la ropa", "cost": 2, "find": torso_wounds_txt, "mark": "m-dyn-torso" if not wounds_by_zone["torso"].is_empty() else "", "note": "Torso (%s): %s" % [v_name, torso_wounds_txt]},
				{"id": "palpar", "name": "Palpar costillas y espalda", "cost": 4, "find": "La piel está anormalmente fría para el tiempo transcurrido: alguien enfrió el cuerpo para trucar la hora de la muerte." if is_tampered_time else "Costillas enteras. Al girar un poco el hombro, ves que la sangre acumulada (lividez) está fijada en el costado derecho, aunque el cuerpo yace boca arriba.", "tag": "Cuerpo movido tras morir" if (is_moved or is_tampered_time) else "", "note": "Lividez (%s): %s" % [v_name, "la temperatura y lividez indican que manipularon el cadáver tras morir." if (is_moved or is_tampered_time) else "costillas enteras, lividez asentada."]},
				{"id": "interna", "name": "Examinar estómago", "cost": 0, "locked": true, "find": "Hace falta abrir el cuerpo en la morgue para ver qué comió o bebió antes de morir."}
			]
		},
		"brazos": {
			"title": "Brazos y muñecas",
			"acts": [
				{"id": "mirar", "name": "Mirar muñecas", "cost": 2, "find": arm_wounds_txt, "mark": "m-wrist", "note": "Muñecas (%s): %s" % [v_name, arm_wounds_txt]},
				{"id": "lupa", "name": "Usar lupa en las marcas", "cost": 4, "locked": not has_lupa, "find": "Hay pelusa de cáñamo encerado clavada en la piel: el cordel que usan en el almacén de grano y en las barcas." if has_lupa else "Necesitas una Lupa de Latón para identificar las fibras en las muñecas.", "tag": "Fibra: cáñamo encerado", "note": "Fibra en muñecas (%s): cáñamo encerado." % v_name}
			]
		},
		"manos": {
			"title": "Manos y uñas",
			"acts": [
				{"id": "mirar", "name": "Abrir los dedos", "cost": 3, "find": "Los dedos están rígidos (entre 6 y 10 horas muerta). No tiene cortes de haberse defendido de un cuchillo."},
				{"id": "lupa", "name": "Mirar bajo las uñas", "cost": 4, "locked": not has_lupa, "find": "Bajo dos uñas de la mano derecha hay hebras de lana teñida de azul oscuro, arrancadas de una manga o capote." if has_lupa else "Necesitas una Lupa de Latón para examinar debajo de las uñas.", "tag": "Fibra: lana azul oscuro", "note": "Bajo las uñas (%s): lana azul oscuro arrancada de la ropa de otra persona." % v_name}
			]
		},
		"piernas": {
			"title": "Piernas y calzado",
			"acts": [
				{"id": "mirar", "name": "Mirar pies y bajos", "cost": 2, "find": leg_wounds_txt, "mark": "m-heel", "tag": "Arrastrada hasta aquí" if is_moved else "", "note": "Pies (%s): %s" % [v_name, leg_wounds_txt]},
				{"id": "oler", "name": "Oler el barro del vestido", "cost": 2, "find": "El barro de las rodillas huele a ceniza de carbón vegetal, no al lodo limpio del arroyo.", "tag": "Barro con ceniza de carbón", "note": "Barro en rodillas (%s): mezclado con ceniza de carbón vegetal." % v_name}
			]
		},
		"bolsillos": {
			"title": "Bolsillos del delantal",
			"acts": [
				{"id": "palpar", "name": "Palpar desde fuera", "cost": 2, "find": "En el bolsillo derecho suena vidrio pequeño y un papel doblado (%s)." % pocket_summary},
				{"id": "registrar", "name": "Vaciar bolsillo (10 min)", "cost": 10, "find": "Sacas el contenido de los bolsillos (%s): un frasco pequeño vacío sin etiqueta (huele igual que su boca, a almendra amarga) y una nota húmeda donde solo se lee «…después del toque de queda en el puente viejo — V.»." % pocket_summary, "mark": "m-pocket", "tag": "Objeto: frasco vacío + nota «V.»", "note": "Bolsillo (%s): %s + frasco vacío con olor amargo y nota firmada «V.»." % [v_name, pocket_summary], "loot_corpse": true}
			]
		}
	}


func _describe_zone_wounds(w_arr: Array, weapon_cause: String, fallback_txt: String) -> String:
	if w_arr.is_empty():
		return fallback_txt
	var parts: Array[String] = []
	for w in w_arr:
		var wn: String = str(w.get("name", "Herida"))
		var wc: String = str(w.get("weapon_cause", weapon_cause))
		parts.append("%s (%s)" % [wn, wc if wc != "" else "impacto físico"])
	return "Se aprecian lesiones visibles: " + ", ".join(parts) + "."


func _get_default_forest_woman_zones(has_lupa: bool) -> Dictionary:
	return {
		"cabeza": {
			"title": "Cabeza y rostro",
			"acts": [
				{"id": "mirar", "name": "Mirar de cerca", "cost": 2, "find": "No hay golpe en la frente ni sangre en el pelo. Los ojos tienen puntitos rojos en el blanco; los labios están azulados."},
				{"id": "oler", "name": "Oler boca y nariz", "cost": 2, "find": "Un olor suave y amargo, como a almendra machacada o hueso de melocotón, sale todavía de la boca.", "tag": "Olor: almendra amarga", "note": "Aliento: olor amargo a almendra en la boca (¿algo bebido antes de morir?)."},
				{"id": "palpar", "name": "Palpar cráneo", "cost": 3, "find": "Hueso entero, sin hundimientos. No murió de una pedrada ni de un porrazo en la cabeza."},
				{"id": "lupa", "name": "Usar lupa en el pelo", "cost": 4, "locked": not has_lupa, "find": "Entre el pelo hay polen amarillo de sauce y dos briznas de paja seca que no crecen junto al arroyo: vienen de un granero o establo."}
			]
		},
		"cuello": {
			"title": "Cuello y garganta",
			"acts": [
				{"id": "mirar", "name": "Mirar la piel", "cost": 2, "find": "Una franja morada cruza la garganta, pero está borrosa, como si la sangre no hubiera corrido hacia el golpe.", "mark": "m-neck", "note": "Cuello: marca morada horizontal en la garganta, extrañamente pálida por dentro."},
				{"id": "palpar", "name": "Palpar garganta", "cost": 3, "find": "Desde fuera se nota el cartílago duro, pero sin abrir en la morgue no puedes saber si el hueso interno está roto."},
				{"id": "lupa", "name": "Usar lupa en el surco", "cost": 5, "locked": not has_lupa, "find": "En los bordes del surco no hay pellejos levantados ni sangre coagulada: apretaron cuando el corazón ya latía muy débil o estaba parado.", "tag": "Surco sin sangrado", "note": "Surco del cuello: sin sangrado en los bordes; puede haberse hecho cuando ya se moría por otra causa."},
				{"id": "interna", "name": "Abrir tráquea", "cost": 0, "locked": true, "find": "Hace falta llevar el cuerpo a la morgue para abrir y ver si el hueso del cuello está roto."}
			]
		},
		"torso": {
			"title": "Pecho y vestido",
			"acts": [
				{"id": "mirar", "name": "Mirar la ropa", "cost": 2, "find": "El vestido de lana está húmedo por la espalda, pero seco en el pecho. No hay cortes ni agujeros de cuchillo."},
				{"id": "palpar", "name": "Palpar costillas y espalda", "cost": 4, "find": "Costillas enteras. Al girar un poco el hombro, ves que la sangre acumulada tras morir (lividez) está en el costado derecho, no en la espalda, aunque yace boca arriba.", "tag": "Cuerpo movido tras morir", "note": "Lividez en el costado derecho aunque yace boca arriba: estuvo horas tumbada de lado en otro sitio antes de traerla aquí."},
				{"id": "interna", "name": "Examinar estómago", "cost": 0, "locked": true, "find": "Hace falta abrir el cuerpo en la morgue para ver qué comió o bebió antes de morir."}
			]
		},
		"brazos": {
			"title": "Brazos y muñecas",
			"acts": [
				{"id": "mirar", "name": "Mirar muñecas", "cost": 2, "find": "Dos marcas rojas estrechas rodean las muñecas, como si la hubieran sujetado por detrás o atado con cuerda fina.", "mark": "m-wrist"},
				{"id": "lupa", "name": "Usar lupa en las marcas", "cost": 4, "locked": not has_lupa, "find": "Hay pelusa de cáñamo encerado clavada en la piel: el tipo de cordel que usan en el almacén de grano y en las barcas.", "tag": "Fibra: cáñamo encerado", "note": "Muñecas: restos de cordel de cáñamo encerado (usado en almacén de grano o barcas)."}
			]
		},
		"manos": {
			"title": "Manos y uñas",
			"acts": [
				{"id": "mirar", "name": "Abrir los dedos", "cost": 3, "find": "Los dedos están rígidos (entre 6 y 10 horas muerta). No tiene cortes de haberse defendido de un cuchillo."},
				{"id": "lupa", "name": "Mirar bajo las uñas", "cost": 4, "locked": not has_lupa, "find": "Bajo dos uñas de la mano derecha hay hebras de lana teñida de azul oscuro, arrancadas de una manga o capote.", "tag": "Fibra: lana azul oscuro", "note": "Bajo las uñas: lana azul oscuro arrancada de la ropa de otra persona."}
			]
		},
		"piernas": {
			"title": "Piernas y calzado",
			"acts": [
				{"id": "mirar", "name": "Mirar pies y bajos", "cost": 2, "find": "Falta el zapato izquierdo. Los dos talones tienen barro oscuro por detrás, como si la hubieran arrastrado sujetándola por las axilas.", "mark": "m-heel", "tag": "Arrastrada hasta aquí", "note": "Talones manchados por detrás y falta el zapato izquierdo: la arrastraron hasta el arroyo."},
				{"id": "oler", "name": "Oler el barro del vestido", "cost": 2, "find": "El barro de las rodillas huele a ceniza de carbón vegetal, no al lodo limpio del arroyo.", "tag": "Barro con ceniza de carbón", "note": "Barro en las rodillas mezclado con ceniza de carbón vegetal (¿carbonera, fragua o horno?)."}
			]
		},
		"bolsillos": {
			"title": "Bolsillos del delantal",
			"acts": [
				{"id": "palpar", "name": "Palpar desde fuera", "cost": 2, "find": "En el bolsillo derecho suena vidrio pequeño y un papel doblado."},
				{"id": "registrar", "name": "Vaciar bolsillo (10 min)", "cost": 10, "find": "Sacas un frasco pequeño vacío sin etiqueta (huele igual que su boca, a almendra amarga) y una nota húmeda donde solo se lee «…después del toque de queda en el puente viejo — V.».", "mark": "m-pocket", "tag": "Objeto: frasco vacío + nota «V.»", "note": "Bolsillo: frasco vacío con olor a almendra amarga y nota rota firmada «V.» citándola en el puente viejo tras el toque de queda.", "loot_corpse": true}
			]
		}
	}


# ==============================================================================
# Interacción con zonas y acciones en D1
# ==============================================================================
func select_zone(zone_id: String) -> void:
	if not zone_data.has(zone_id):
		return
	selected_zone = zone_id
	current_finding = {}
	if silhouette_canvas != null:
		silhouette_canvas.queue_redraw()
	_render_notebook_zone()


func _render_notebook_zone() -> void:
	if nb_actions_grid == null or nb_findings_box == null:
		return
	for c in nb_actions_grid.get_children():
		c.queue_free()
	for c in nb_findings_box.get_children():
		c.queue_free()

	if selected_zone == "" or not zone_data.has(selected_zone):
		nb_zone_title.text = "Selecciona una zona del cuerpo"
		nb_zone_sub.text = "Cada inspección lleva unos minutos. La guardia y los curiosos no esperan eternamente."
		var empty_lbl := Label.new()
		empty_lbl.text = "Aún no has examinado esta parte. Puedes mirar a simple vista, palpar, oler o usar una herramienta si la llevas encima."
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color("#6a6254"))
		nb_findings_box.add_child(empty_lbl)
		return

	var z: Dictionary = zone_data[selected_zone]
	nb_zone_title.text = str(z.get("title", selected_zone.capitalize()))
	nb_zone_sub.text = "Elige qué hacer con esta zona"

	var acts: Array = z.get("acts", [])
	for act in acts:
		var a_id: String = str(act.get("id", ""))
		var key: String = "%s:%s" % [selected_zone, a_id]
		var is_done: bool = done_actions.get(key) == true
		var is_locked: bool = act.get("locked") == true
		var cost: int = int(act.get("cost", 0))
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if is_locked else Control.CURSOR_POINTING_HAND
		var badge: String = "✓" if is_done else ("🔒" if is_locked else ("%d min" % cost))
		btn.text = "%s  [%s]" % [str(act.get("name", a_id)), badge]
		btn.add_theme_font_size_override("font_size", 12)
		var fg := COL_GREEN_OK if is_done else (Color("#6a6254") if is_locked else COL_PAPER_INK)
		btn.add_theme_color_override("font_color", fg)
		btn.add_theme_color_override("font_hover_color", fg)
		var bg := Color("#dfd4bc") if not is_locked else Color("#d8ceba")
		btn.add_theme_stylebox_override("normal", _style_box(bg, COL_PAPER_EDGE, 1, 0, 8, 6))
		btn.add_theme_stylebox_override("hover", _style_box(Color("#d5c7aa"), COL_PAPER_INK, 1, 0, 8, 6))
		btn.add_theme_stylebox_override("pressed", _style_box(Color("#cbb996"), COL_PAPER_INK, 1, 0, 8, 6))
		btn.pressed.connect(func(): _do_zone_action(selected_zone, act))
		nb_actions_grid.add_child(btn)

	if current_finding.is_empty():
		var hint_lbl := Label.new()
		hint_lbl.text = "Elige una acción arriba para examinar esta zona."
		hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_lbl.add_theme_font_size_override("font_size", 12)
		hint_lbl.add_theme_color_override("font_color", Color("#6a6254"))
		nb_findings_box.add_child(hint_lbl)
	else:
		_render_finding_card(current_finding)


func _do_zone_action(z_id: String, act: Dictionary) -> void:
	var a_id: String = str(act.get("id", ""))
	var key: String = "%s:%s" % [z_id, a_id]
	var is_locked: bool = act.get("locked") == true
	if not is_locked and done_actions.get(key) != true:
		done_actions[key] = true
		_advance_investigation_minutes(int(act.get("cost", 0)))
		findings_count += 1
		var mk: String = str(act.get("mark", ""))
		if mk != "":
			revealed_marks[mk] = true
			if silhouette_canvas != null:
				silhouette_canvas.queue_redraw()
		if act.get("loot_corpse") == true and is_instance_valid(current_corpse) and current_corpse.has_method("loot_npc_pockets") and player != null:
			current_corpse.call("loot_npc_pockets", player)
	current_finding = {
		"key": key,
		"zone_title": str(zone_data[z_id].get("title", z_id)),
		"act_name": str(act.get("name", "")),
		"cost": int(act.get("cost", 0)),
		"locked": is_locked,
		"find": str(act.get("find", "")),
		"tag": str(act.get("tag", "")),
		"note": str(act.get("note", ""))
	}
	_update_header_meta()
	_render_notebook_zone()


func _render_finding_card(f: Dictionary) -> void:
	var card := PanelContainer.new()
	var is_locked: bool = f.get("locked") == true
	var c_style := _style_box(Color("#f3ecdc"), COL_PAPER_EDGE, 1, 0, 10, 9)
	c_style.border_width_left = 3
	c_style.border_color = Color("#7a7264") if is_locked else COL_BLOOD
	card.add_theme_stylebox_override("panel", c_style)
	nb_findings_box.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	var head_lbl := Label.new()
	var cost_txt: String = "Bloqueado aquí" if is_locked else ("+%d min" % int(f.get("cost", 0)))
	head_lbl.text = "%s · %s  (%s)" % [str(f.get("zone_title", "")).to_upper(), str(f.get("act_name", "")).to_upper(), cost_txt]
	head_lbl.add_theme_font_size_override("font_size", 11)
	head_lbl.add_theme_color_override("font_color", Color("#5a5244"))
	vb.add_child(head_lbl)

	var body_lbl := Label.new()
	body_lbl.text = str(f.get("find", ""))
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.add_theme_font_size_override("font_size", 13)
	body_lbl.add_theme_color_override("font_color", COL_PAPER_INK)
	vb.add_child(body_lbl)

	var note_txt: String = str(f.get("note", ""))
	if note_txt != "" and not is_locked:
		var src_key: String = str(f.get("key", ""))
		var already_pinned: bool = _has_note_with_key(src_key)
		var pin_btn := Button.new()
		pin_btn.focus_mode = Control.FOCUS_NONE
		pin_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		pin_btn.text = "✓ Anotado en el cuaderno" if already_pinned else "📌 Anotar en el cuaderno"
		pin_btn.disabled = already_pinned
		pin_btn.add_theme_font_size_override("font_size", 11)
		pin_btn.add_theme_color_override("font_color", COL_GREEN_OK if already_pinned else Color("#f3ecdc"))
		var p_bg := Color("#dfd4bc") if already_pinned else COL_PAPER_INK
		pin_btn.add_theme_stylebox_override("normal", _style_box(p_bg, COL_PAPER_INK, 1, 0, 9, 4))
		pin_btn.add_theme_stylebox_override("disabled", _style_box(Color("#dfd4bc"), COL_GREEN_OK, 1, 0, 9, 4))
		pin_btn.pressed.connect(func():
			add_notebook_note(str(f.get("zone_title", "Pista")), note_txt, str(f.get("tag", "Hallazgo")), src_key)
			_render_notebook_zone()
		)
		vb.add_child(pin_btn)


# ==============================================================================
# Tira inferior: Cuaderno del caso
# ==============================================================================
func _has_note_with_key(src_key: String) -> bool:
	if src_key == "":
		return false
	for n in notebook_notes:
		if str(n.get("source_key", "")) == src_key:
			return true
	return false


func add_notebook_note(title: String, text: String, tag: String = "", source_key: String = "") -> void:
	if source_key != "" and _has_note_with_key(source_key):
		return
	notebook_notes.append({
		"title": title,
		"text": text,
		"tag": tag,
		"source_key": source_key
	})
	_render_strip_notes()


func _render_strip_notes() -> void:
	if strip_notes_hbox == null:
		return
	for c in strip_notes_hbox.get_children():
		if c != lbl_strip_empty:
			c.queue_free()
	if lbl_strip_empty != null:
		lbl_strip_empty.visible = notebook_notes.is_empty()
	for n in notebook_notes:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(220, 52)
		var st := _style_box(COL_PAPER, COL_PAPER_EDGE, 1, 0, 10, 6)
		card.add_theme_stylebox_override("panel", st)
		strip_notes_hbox.add_child(card)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		card.add_child(hb)

		# Chincheta roja estilo boceto HTML
		var pin_dot := ColorRect.new()
		pin_dot.color = COL_RED_PIN
		pin_dot.custom_minimum_size = Vector2(8, 8)
		pin_dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		hb.add_child(pin_dot)

		var lbl := Label.new()
		var t_tag: String = str(n.get("tag", ""))
		lbl.text = ("%s — %s" % [t_tag, str(n.get("text", ""))]) if t_tag != "" else str(n.get("text", ""))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(195, 0)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", COL_PAPER_INK)
		hb.add_child(lbl)
