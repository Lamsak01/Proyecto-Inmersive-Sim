extends Control
class_name DetectiveUI

const DetectiveCaseDataScript = preload("res://scripts/systems/DetectiveCaseData.gd")

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
var lbl_apparent_cause: RichTextLabel = null
var apparent_cause_str: String = "sin determinar"
var decay_phase_panels: Array[PanelContainer] = []
var lbl_decay_status: Label = null

# Vista D2: Autopsia en la morgue
var morgue_tests_def: Dictionary = {}
var morgue_tests_state: Dictionary = {} # test_id -> {step, log: Array, state: "", vials: int, dud: bool, hint_asked: Dictionary}
var selected_morgue_test: String = "sangre"
var morgue_list_vbox: VBoxContainer = null
var lbl_morgue_sub: Label = null
var lbl_real_cause: RichTextLabel = null
var lbl_bench_title: Label = null
var bench_vials_hbox: HBoxContainer = null
var bench_body_vbox: VBoxContainer = null
var bench_doc_panel: PanelContainer = null
var lbl_bench_doc: RichTextLabel = null
var morgue_status_banner: PanelContainer = null
var lbl_morgue_banner: Label = null
var btn_morgue_transfer: Button = null

# Vista D3: Escena del crimen (farol + pistas físicas + testigos cercanos)
var scene_sketch_tex_rect: TextureRect = null
var scene_sketch_mat: ShaderMaterial = null
var crime_scene_canvas: CrimeSceneCanvas = null
var lbl_scene_ground: Label = null
var scene_clues: Array[Dictionary] = []
var scene_clues_found: Dictionary = {} # idx (int) -> true
var scene_witnesses: Array[Dictionary] = [] # [{name, npc_ref, ask_text, press_ok_text, press_bad_text, can_press_succeed, log: Array}]
var scene_finds_vbox: VBoxContainer = null
var scene_witnesses_vbox: VBoxContainer = null

# Vista D4: Cuaderno y tablero del caso (corcho, fichas arrastrables e hilos rojos)
var corkboard_canvas: CorkboardCanvas = null
var board_suspects: Array[Dictionary] = []
var board_positions: Dictionary = {} # pin_id -> Vector2(x, y)
var board_links: Array = []          # [[id_a, id_b], ...]
var board_link_from: String = ""

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

		# 0. Fondo esquemático limpio de dónde yace el cuerpo (pocas líneas, colores planos, sin ruido)
		_draw_body_site_schematic(ui._get_corpse_site_kind())

		# 1. Óvalo oscuro de suelo bajo el cuerpo (idéntico al boceto HTML)
		_draw_poly_scaled(PackedVector2Array([
			Vector2(52, 24), Vector2(168, 24), Vector2(192, 118), Vector2(188, 260),
			Vector2(158, 446), Vector2(62, 446), Vector2(32, 260), Vector2(28, 118)
		]), Color(0.07, 0.09, 0.07, 0.55), Color(0.22, 0.25, 0.20, 0.35), 1.2)

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

	func _draw_body_site_schematic(site_kind: String) -> void:
		if size.x <= 2.0 or size.y <= 2.0:
			return
		var w: float = size.x
		var h: float = size.y
		if site_kind == "morgue":
			draw_rect(Rect2(0, 0, w, h), Color("#171d22"), true)
			var slab := Rect2(w * 0.16, h * 0.03, w * 0.68, h * 0.94)
			draw_rect(slab, Color("#222b32"), true)
			draw_rect(slab, Color("#35424c"), false, 2.0)
			draw_line(Vector2(slab.position.x + 14, slab.position.y + 18), Vector2(slab.end.x - 14, slab.position.y + 18), Color("#2c3740"), 1.5)
			draw_line(Vector2(slab.position.x + 14, slab.end.y - 18), Vector2(slab.end.x - 14, slab.end.y - 18), Color("#2c3740"), 1.5)
			return
		if site_kind == "lake":
			draw_rect(Rect2(0, 0, w, h), Color("#1d261c"), true)
			# Orilla y agua del lago a la izquierda
			var water_pts := PackedVector2Array([
				Vector2(0, 0), Vector2(w * 0.30, 0), Vector2(w * 0.24, h * 0.45),
				Vector2(w * 0.32, h), Vector2(0, h)
			])
			draw_colored_polygon(water_pts, Color("#1d3240"))
			draw_polyline(PackedVector2Array([Vector2(w * 0.30, 0), Vector2(w * 0.24, h * 0.45), Vector2(w * 0.32, h)]), Color("#354d5c"), 2.0)
			# Pasarela de madera arriba a la izquierda
			draw_rect(Rect2(w * 0.08, h * 0.12, w * 0.28, h * 0.09), Color("#382b1e"), true)
			draw_rect(Rect2(w * 0.08, h * 0.12, w * 0.28, h * 0.09), Color("#4e3c2a"), false, 1.5)
			# Juncos y piedras planas en la orilla
			draw_circle(Vector2(w * 0.34, h * 0.28), 11.0, Color("#263322"))
			draw_circle(Vector2(w * 0.78, h * 0.22), 14.0, Color("#282a26"))
			draw_circle(Vector2(w * 0.82, h * 0.76), 18.0, Color("#162012"))
			return
		if site_kind == "town":
			draw_rect(Rect2(0, 0, w, h), Color("#1f2327"), true)
			# Calzada empedrada con bordillos limpios
			draw_rect(Rect2(w * 0.08, 0, w * 0.84, h), Color("#262a2e"), true)
			draw_line(Vector2(w * 0.08, 0), Vector2(w * 0.08, h), Color("#363b40"), 2.0)
			draw_line(Vector2(w * 0.92, 0), Vector2(w * 0.92, h), Color("#363b40"), 2.0)
			for ry in [0.22, 0.50, 0.78]:
				draw_line(Vector2(w * 0.12, h * ry), Vector2(w * 0.88, h * ry), Color("#1c2024"), 1.2)
			return
		if site_kind == "ranch":
			draw_rect(Rect2(0, 0, w, h), Color("#232018"), true)
			# Sendero de tierra y valla de madera arriba
			draw_rect(Rect2(0, h * 0.06, w, h * 0.05), Color("#3c2b1b"), true)
			draw_circle(Vector2(w * 0.18, h * 0.30), 22.0, Color("#1d2617"))
			draw_circle(Vector2(w * 0.82, h * 0.72), 26.0, Color("#1d2617"))
			return
		# Por defecto ("forest" / Caso 1): claro de bosque con sendero arriba, arroyo abajo y copas oscuras
		draw_rect(Rect2(0, 0, w, h), Color("#1c2519"), true)
		var path_pts := PackedVector2Array([
			Vector2(0, h * 0.05), Vector2(w, h * 0.02), Vector2(w, h * 0.14), Vector2(0, h * 0.17)
		])
		draw_colored_polygon(path_pts, Color("#2f281f"))
		var stream_pts := PackedVector2Array([
			Vector2(0, h * 0.82), Vector2(w * 0.52, h * 0.88), Vector2(w * 0.65, h), Vector2(0, h)
		])
		draw_colored_polygon(stream_pts, Color("#1e323f"))
		draw_circle(Vector2(w * 0.12, h * 0.28), 32.0, Color("#141d10"))
		draw_circle(Vector2(w * 0.88, h * 0.24), 36.0, Color("#141d10"))
		draw_circle(Vector2(w * 0.86, h * 0.80), 30.0, Color("#141d10"))
		draw_circle(Vector2(w * 0.22, h * 0.66), 8.0, Color("#2b2923"))
		draw_circle(Vector2(w * 0.76, h * 0.54), 7.0, Color("#2b2923"))

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
# Subclase de dibujo para la escena del crimen (Bloque D3): farol + silueta de tiza + pistas
# ==============================================================================
class CrimeSceneCanvas extends Control:
	var ui: DetectiveUI = null
	# Coordenadas base en espacio 520x560 (idéntico al viewBox="0 0 520 560" de #csvg en el boceto HTML)
	const BASE_W := 520.0
	const BASE_H := 560.0
	const LANTERN_RADIUS := 72.0
	var lantern_base_pos := Vector2(260.0, 280.0)
	var hovered_clue_idx: int = -1

	func _gui_input(event: InputEvent) -> void:
		if ui == null:
			return
		if event is InputEventMouseMotion:
			var bpos := _from_canvas(event.position)
			ui.set_lantern_canvas_pos(bpos, event.position, size)
			var hit_idx := _clue_at(bpos)
			if hit_idx != hovered_clue_idx:
				hovered_clue_idx = hit_idx
				mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hit_idx >= 0 else Control.CURSOR_CROSS
			queue_redraw()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var bpos := _from_canvas(event.position)
			ui.set_lantern_canvas_pos(bpos, event.position, size)
			var hit_idx := _clue_at(bpos)
			if hit_idx >= 0:
				ui.crime_find_clue(hit_idx)
				accept_event()
			queue_redraw()

	func _to_canvas(pt: Vector2) -> Vector2:
		var scale_f: float = minf(size.x / BASE_W, size.y / BASE_H)
		var off := (size - Vector2(BASE_W, BASE_H) * scale_f) * 0.5
		return off + pt * scale_f

	func _from_canvas(pos: Vector2) -> Vector2:
		var scale_f: float = maxf(0.01, minf(size.x / BASE_W, size.y / BASE_H))
		var off := (size - Vector2(BASE_W, BASE_H) * scale_f) * 0.5
		return (pos - off) / scale_f

	func _clue_at(bpos: Vector2) -> int:
		if ui == null:
			return -1
		for i in range(ui.scene_clues.size()):
			var c: Dictionary = ui.scene_clues[i]
			var cpos := Vector2(float(c.get("x", 260.0)), float(c.get("y", 280.0)))
			var r: float = float(c.get("r", 16.0)) + 12.0
			if bpos.distance_to(cpos) <= r and lantern_base_pos.distance_to(cpos) <= 82.0:
				return i
		return -1

	func _draw_bpoly(pts: Array, col: Color) -> void:
		var scaled := PackedVector2Array()
		for p in pts:
			scaled.append(_to_canvas(p as Vector2))
		draw_colored_polygon(scaled, col)

	func _draw() -> void:
		if ui == null:
			return
		var scale_f: float = minf(size.x / BASE_W, size.y / BASE_H)
		var site_kind: String = ui._get_corpse_site_kind()
		var l_px := _to_canvas(lantern_base_pos)
		var l_rad := LANTERN_RADIUS * scale_f

		# 0. Fondo cenital esquemático limpio de la escena (exacto a #csvg del boceto HTML)
		draw_rect(Rect2(Vector2.ZERO, size), Color("#0b0e11"), true)
		# Suelo bajo el círculo del farol e iluminación tenue exterior
		draw_circle(l_px, l_rad * 1.18, Color("#151c14"))
		draw_circle(l_px, l_rad, Color("#1f2a1d") if site_kind != "town" else Color("#24282c"))

		if site_kind == "lake":
			# Orilla del Lago del Oeste: agua al oeste y abajo, pasarela de madera arriba
			_draw_bpoly([Vector2(0, 120), Vector2(185, 160), Vector2(165, 420), Vector2(520, 445), Vector2(520, 560), Vector2(0, 560)], Color("#233846"))
			_draw_bpoly([Vector2(140, 40), Vector2(360, 40), Vector2(360, 92), Vector2(140, 92)], Color("#3a3226"))
			for tr in [Vector2(88, 92), Vector2(435, 120), Vector2(440, 380)]:
				var d_tr: float = lantern_base_pos.distance_to(tr)
				var c_tr := Color("#16200f").lightened(0.08 if d_tr < 110.0 else 0.0)
				draw_circle(_to_canvas(tr), 40.0 * scale_f, c_tr)
		elif site_kind == "town":
			# Calle / plaza empedrada
			_draw_bpoly([Vector2(0, 40), Vector2(520, 40), Vector2(520, 110), Vector2(0, 110)], Color("#31353b"))
			_draw_bpoly([Vector2(60, 110), Vector2(460, 110), Vector2(460, 460), Vector2(60, 460)], Color("#262a30"))
			_draw_bpoly([Vector2(0, 460), Vector2(520, 460), Vector2(520, 530), Vector2(0, 530)], Color("#1f2e38"))
		else:
			# Claro del bosque junto al arroyo (idéntico al boceto HTML #csvg)
			# Camino del norte arriba
			_draw_bpoly([Vector2(0, 40), Vector2(520, 22), Vector2(520, 92), Vector2(0, 110)], Color("#3a3226"))
			# Arroyo abajo
			_draw_bpoly([Vector2(0, 455), Vector2(220, 438), Vector2(360, 472), Vector2(520, 448), Vector2(520, 532), Vector2(360, 548), Vector2(200, 514), Vector2(0, 530)], Color("#233846"))
			# Árboles del claro
			for tr_info in [
				[Vector2(70, 180), 42.0], [Vector2(440, 160), 48.0],
				[Vector2(90, 360), 38.0], [Vector2(430, 340), 44.0], [Vector2(170, 260), 30.0]
			]:
				var tpos: Vector2 = tr_info[0]
				var trad: float = float(tr_info[1])
				draw_circle(_to_canvas(tpos), trad * scale_f, Color("#16200f"))
				if lantern_base_pos.distance_to(tpos) <= LANTERN_RADIUS + trad:
					draw_arc(_to_canvas(tpos), trad * scale_f, 0.0, TAU, 24, Color("#2c3c20"), 1.5, true)

		# 1. Silueta discontinua de tiza donde yacía el cuerpo (exacta a #csvg en el boceto HTML)
		var chalk_col := Color("#d9d2c2")
		var dist_chalk := lantern_base_pos.distance_to(Vector2(250, 295))
		chalk_col.a = clampf(1.05 - dist_chalk / 160.0, 0.28, 0.86)
		var chalk_head := _to_canvas(Vector2(250, 232))
		var head_r: float = 14.0 * scale_f
		for s in range(10):
			var a0: float = (TAU * float(s)) / 10.0
			var a1: float = a0 + (TAU / 10.0) * 0.55
			draw_arc(chalk_head, head_r, a0, a1, 3, chalk_col, 2.0, true)

		var chalk_pts := [
			Vector2(232, 300), Vector2(230, 268), Vector2(238, 250), Vector2(250, 246),
			Vector2(262, 250), Vector2(270, 268), Vector2(268, 300), Vector2(276, 370),
			Vector2(262, 372), Vector2(256, 330), Vector2(244, 330), Vector2(238, 372),
			Vector2(224, 370), Vector2(232, 300)
		]
		for pi in range(chalk_pts.size() - 1):
			var p0 := _to_canvas(chalk_pts[pi])
			var p1 := _to_canvas(chalk_pts[pi + 1])
			var mid := p0.lerp(p1, 0.65)
			draw_line(p0, mid, chalk_col, 2.0, true)

		# 2. Pistas físicas en el suelo: solo se ven bajo la luz del farol (o quedan tenues si ya se hallaron)
		for i in range(ui.scene_clues.size()):
			var c: Dictionary = ui.scene_clues[i]
			var cpos := Vector2(float(c.get("x", 260.0)), float(c.get("y", 280.0)))
			var dist_lamp: float = lantern_base_pos.distance_to(cpos)
			var is_found: bool = (ui.scene_clues_found.get(i) == true)
			if dist_lamp > 80.0 and not is_found:
				continue
			var vis_alpha: float = clampf(1.0 - (dist_lamp / 82.0), 0.25 if is_found else 0.0, 1.0)
			var center_px := _to_canvas(cpos)
			var kind: String = str(c.get("draw_kind", "circle"))

			if kind == "drag":
				var col_d := Color("#9a8666")
				col_d.a = vis_alpha
				draw_line(_to_canvas(cpos + Vector2(-18, -28)), _to_canvas(cpos + Vector2(-4, 22)), col_d, 3.0, true)
				draw_line(_to_canvas(cpos + Vector2(0, -30)), _to_canvas(cpos + Vector2(12, 22)), col_d, 3.0, true)
			elif kind == "prints":
				var col_p := Color("#8b7356")
				col_p.a = vis_alpha
				draw_circle(_to_canvas(cpos + Vector2(-6, -6)), 6.5 * scale_f, col_p)
				draw_circle(_to_canvas(cpos + Vector2(8, 10)), 6.5 * scale_f, col_p)
			elif kind == "wheels":
				var col_w := Color("#7a654a")
				col_w.a = vis_alpha
				draw_line(_to_canvas(cpos + Vector2(-22, -20)), _to_canvas(cpos + Vector2(-22, 28)), col_w, 3.5, true)
				draw_line(_to_canvas(cpos + Vector2(4, -20)), _to_canvas(cpos + Vector2(4, 28)), col_w, 3.5, true)
			elif kind == "herb":
				var col_h := Color("#a9b86a")
				col_h.a = vis_alpha
				draw_circle(center_px, 5.0 * scale_f, col_h)
				draw_line(_to_canvas(cpos + Vector2(-6, -6)), _to_canvas(cpos + Vector2(8, 8)), col_h, 2.2, true)
			elif kind == "mud":
				var col_m := Color("#c9c2b0")
				col_m.a = vis_alpha * 0.85
				draw_circle(center_px, 9.0 * scale_f, col_m)
			elif kind == "blood":
				var col_b := COL_BLOOD
				col_b.a = vis_alpha * 0.90
				draw_circle(center_px, 10.0 * scale_f, col_b)
			else:
				var col_c := Color("#8a8a74")
				col_c.a = vis_alpha
				draw_arc(center_px, 11.0 * scale_f, 0.0, TAU, 18, col_c, 1.6, true)

			# Anillo indicador bajo el farol
			var ring_col := COL_GREEN_OK if is_found else COL_LAMP
			ring_col.a = vis_alpha * (0.90 if hovered_clue_idx == i else 0.55)
			draw_arc(center_px, (float(c.get("r", 15.0)) + 4.0) * scale_f, 0.0, TAU, 24, ring_col, 1.5, true)

		# 3. Halo cálido y anillo del farol del jugador (#lampring)
		draw_circle(l_px, l_rad, Color(0.906, 0.706, 0.353, 0.10))
		draw_arc(l_px, l_rad, 0.0, TAU, 40, Color(0.906, 0.706, 0.353, 0.65), 1.6, true)


# ==============================================================================
# Subclases de dibujo para el tablero de corcho e hilos rojos (Bloque D4)
# ==============================================================================
class StringsOverlay extends Control:
	var board: CorkboardCanvas = null

	func _draw() -> void:
		if board == null or board.ui == null:
			return
		var ui_ref: DetectiveUI = board.ui
		for l in ui_ref.board_links:
			if not (l is Array) or (l as Array).size() < 2:
				continue
			var id_a: String = str(l[0])
			var id_b: String = str(l[1])
			if not ui_ref.board_positions.has(id_a) or not ui_ref.board_positions.has(id_b):
				continue
			var pa: Vector2 = ui_ref.board_positions[id_a] + Vector2(84.0, 2.0)
			var pb: Vector2 = ui_ref.board_positions[id_b] + Vector2(84.0, 2.0)
			draw_line(pa + Vector2(0, 2), pb + Vector2(0, 2), Color(0, 0, 0, 0.35), 3.0, true)
			draw_line(pa, pb, COL_RED_PIN, 2.6, true)


class PinsOverlay extends Control:
	var board: CorkboardCanvas = null

	func _draw() -> void:
		if board == null or board.ui == null:
			return
		var ui_ref: DetectiveUI = board.ui
		for pid in board.card_nodes.keys():
			if not ui_ref.board_positions.has(pid):
				continue
			var p: Vector2 = ui_ref.board_positions[pid] + Vector2(84.0, 2.0)
			draw_circle(p + Vector2(0, 1.5), 6.5, Color(0, 0, 0, 0.38))
			draw_circle(p, 5.8, COL_RED_PIN)
			draw_circle(p + Vector2(-1.6, -1.6), 1.8, Color(1.0, 0.78, 0.78, 0.65))


class CorkboardCanvas extends Control:
	var ui: DetectiveUI = null
	var strings_overlay: StringsOverlay = null
	var pins_overlay: PinsOverlay = null
	var card_nodes: Dictionary = {} # pin_id -> Control
	var dragging_id: String = ""
	var drag_start_mouse: Vector2 = Vector2.ZERO
	var drag_start_pos: Vector2 = Vector2.ZERO
	var drag_moved: bool = false

	func _ready() -> void:
		clip_contents = true
		strings_overlay = StringsOverlay.new()
		strings_overlay.board = self
		strings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		strings_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strings_overlay.z_index = 1
		add_child(strings_overlay)

		pins_overlay = PinsOverlay.new()
		pins_overlay.board = self
		pins_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pins_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pins_overlay.z_index = 10
		add_child(pins_overlay)

	func _gui_input(event: InputEvent) -> void:
		if ui == null:
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var hit_link := _find_link_near(event.position)
			if hit_link >= 0:
				ui.remove_board_link_at(hit_link)
				accept_event()

	func _find_link_near(pt: Vector2) -> int:
		if ui == null:
			return -1
		for i in range(ui.board_links.size()):
			var l = ui.board_links[i]
			if not (l is Array) or (l as Array).size() < 2:
				continue
			var id_a: String = str(l[0])
			var id_b: String = str(l[1])
			if not ui.board_positions.has(id_a) or not ui.board_positions.has(id_b):
				continue
			var pa: Vector2 = ui.board_positions[id_a] + Vector2(84.0, 2.0)
			var pb: Vector2 = ui.board_positions[id_b] + Vector2(84.0, 2.0)
			var closest := Geometry2D.get_closest_point_to_segment(pt, pa, pb)
			if pt.distance_to(closest) <= 9.0:
				return i
		return -1

	func on_card_gui_input(event: InputEvent, pin_id: String) -> void:
		if ui == null:
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging_id = pin_id
				drag_start_mouse = get_local_mouse_position()
				drag_start_pos = ui.board_positions.get(pin_id, Vector2(30, 30))
				drag_moved = false
			else:
				if dragging_id == pin_id:
					var was_moved := drag_moved
					dragging_id = ""
					if not was_moved:
						ui.click_board_pin(pin_id)
					else:
						ui.save_detective_state()
		elif event is InputEventMouseMotion and dragging_id == pin_id:
			var cur_m := get_local_mouse_position()
			var delta := cur_m - drag_start_mouse
			if absf(delta.x) + absf(delta.y) > 4.0:
				drag_moved = true
			ui.move_board_pin(pin_id, drag_start_pos + delta)

	func redraw_links() -> void:
		if strings_overlay != null:
			strings_overlay.queue_redraw()
		if pins_overlay != null:
			pins_overlay.queue_redraw()

	func _draw() -> void:
		# Fondo de corcho (#9a7147) con motas de corcho (#a57c4f y #8a643c) como en el boceto HTML
		draw_rect(Rect2(Vector2.ZERO, size), Color("#9a7147"), true)
		var col_light := Color("#a57c4f")
		var col_dark := Color("#8a643c")
		var step_x := 28.0
		var step_y := 24.0
		var y := 8.0
		var row := 0
		while y < size.y:
			var x := 10.0 + float((row * 13) % 19)
			while x < size.x:
				draw_rect(Rect2(Vector2(x, y), Vector2(2, 2)), col_light, true)
				draw_rect(Rect2(Vector2(x + 11.0, y + 9.0), Vector2(2, 2)), col_dark, true)
				x += step_x
			y += step_y
			row += 1


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
			_build_case_from_corpse(current_corpse)
			_render_morgue_view()
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

	view_morgue = _build_morgue_view()
	views_holder.add_child(view_morgue)

	view_scene = _build_scene_view()
	views_holder.add_child(view_scene)

	view_board = _build_board_view()
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

	# Imagen cenital 3D desactivada: usamos dibujo esquemático limpio en SilhouetteCanvas._draw()
	body_sketch_tex_rect = TextureRect.new()
	body_sketch_tex_rect.visible = false
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
	lbl_corner_right.offset_left = -330
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

	# Barra de estado del cadáver en 4 fases (Reciente -> Enfriándose -> Rígido -> Deteriorado)
	var decay_box := VBoxContainer.new()
	decay_box.add_theme_constant_override("separation", 4)
	nb_vbox.add_child(decay_box)

	lbl_decay_status = Label.new()
	lbl_decay_status.text = "ESTADO DEL CUERPO · RECIENTE"
	lbl_decay_status.add_theme_font_size_override("font_size", 11)
	lbl_decay_status.add_theme_color_override("font_color", Color("#5a5244"))
	decay_box.add_child(lbl_decay_status)

	var decay_row := HBoxContainer.new()
	decay_row.add_theme_constant_override("separation", 4)
	decay_box.add_child(decay_row)
	decay_phase_panels.clear()
	for ph_name in ["1 · Reciente", "2 · Enfriándose", "3 · Rígido", "4 · Deteriorado"]:
		var ph_p := PanelContainer.new()
		ph_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ph_p.add_theme_stylebox_override("panel", _style_box(Color("#d8ceba"), COL_PAPER_EDGE, 1, 0, 4, 3))
		var ph_l := Label.new()
		ph_l.name = "PhaseLbl"
		ph_l.text = ph_name
		ph_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ph_l.add_theme_font_size_override("font_size", 10)
		ph_l.add_theme_color_override("font_color", Color("#5a5244"))
		ph_p.add_child(ph_l)
		decay_row.add_child(ph_p)
		decay_phase_panels.append(ph_p)

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

	var cause_box := PanelContainer.new()
	cause_box.add_theme_stylebox_override("panel", _style_box(COL_PAPER_INK, COL_PAPER_INK, 0, 0, 12, 8))
	nb_vbox.add_child(cause_box)

	lbl_apparent_cause = RichTextLabel.new()
	lbl_apparent_cause.bbcode_enabled = true
	lbl_apparent_cause.fit_content = true
	lbl_apparent_cause.scroll_active = false
	lbl_apparent_cause.add_theme_font_size_override("normal_font_size", 12)
	lbl_apparent_cause.add_theme_font_size_override("bold_font_size", 12)
	lbl_apparent_cause.add_theme_color_override("default_color", COL_PAPER)
	lbl_apparent_cause.text = "Causa aparente: [color=#e7b45a][b]sin determinar[/b][/color]"
	cause_box.add_child(lbl_apparent_cause)

	return split


# ==============================================================================
# Vista 2 (Bloque D2): Autopsia en la morgue (Mesa de autopsias con el Dr. Valen)
# ==============================================================================
func _build_morgue_view() -> Control:
	var split := HBoxContainer.new()
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	split.add_theme_constant_override("separation", 14)
	split.visible = false

	# Columna izquierda (.tlist): Lista de pruebas y causa real
	var left_panel := PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 0.82
	left_panel.add_theme_stylebox_override("panel", _style_box(COL_PANEL, COL_EDGE, 1, 0, 16, 16))
	split.add_child(left_panel)

	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 10)
	left_panel.add_child(left_vbox)

	var lbl_morgue_h := Label.new()
	lbl_morgue_h.text = "Mesa de autopsias"
	lbl_morgue_h.add_theme_font_size_override("font_size", 19)
	lbl_morgue_h.add_theme_color_override("font_color", COL_INK)
	left_vbox.add_child(lbl_morgue_h)

	lbl_morgue_sub = Label.new()
	lbl_morgue_sub.text = "Con el Dr. Valen. Si te equivocas, la muestra se pierde."
	lbl_morgue_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_morgue_sub.add_theme_font_size_override("font_size", 12)
	lbl_morgue_sub.add_theme_color_override("font_color", COL_DIM)
	left_vbox.add_child(lbl_morgue_sub)

	morgue_list_vbox = VBoxContainer.new()
	morgue_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	morgue_list_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	morgue_list_vbox.add_theme_constant_override("separation", 6)
	left_vbox.add_child(morgue_list_vbox)

	var real_cause_box := PanelContainer.new()
	real_cause_box.add_theme_stylebox_override("panel", _style_box(COL_PAPER_INK, COL_EDGE, 1, 0, 12, 10))
	left_vbox.add_child(real_cause_box)

	lbl_real_cause = RichTextLabel.new()
	lbl_real_cause.bbcode_enabled = true
	lbl_real_cause.fit_content = true
	lbl_real_cause.scroll_active = false
	lbl_real_cause.add_theme_font_size_override("normal_font_size", 13)
	lbl_real_cause.add_theme_font_size_override("bold_font_size", 13)
	lbl_real_cause.add_theme_color_override("default_color", COL_PAPER)
	lbl_real_cause.text = "Causa real: [color=#e7b45a][b]sin determinar[/b][/color]"
	real_cause_box.add_child(lbl_real_cause)

	# Columna derecha (.bench): Banco de pruebas sobre papel, muestras de sangre, pasos y consejo del Dr. Valen
	var bench_panel := PanelContainer.new()
	bench_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bench_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bench_panel.size_flags_stretch_ratio = 1.40
	bench_panel.add_theme_stylebox_override("panel", _style_box(COL_PAPER, COL_PAPER_EDGE, 1, 0, 20, 16))
	split.add_child(bench_panel)

	var bench_vbox := VBoxContainer.new()
	bench_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bench_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bench_vbox.add_theme_constant_override("separation", 12)
	bench_panel.add_child(bench_vbox)

	# Aviso superior si el cadáver aún no está en la morgue o si el forense no está disponible
	morgue_status_banner = PanelContainer.new()
	morgue_status_banner.add_theme_stylebox_override("panel", _style_box(Color("#3a2622"), COL_BLOOD, 1, 0, 12, 8))
	morgue_status_banner.visible = false
	bench_vbox.add_child(morgue_status_banner)

	var banner_hbox := HBoxContainer.new()
	banner_hbox.add_theme_constant_override("separation", 10)
	morgue_status_banner.add_child(banner_hbox)

	lbl_morgue_banner = Label.new()
	lbl_morgue_banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_morgue_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_morgue_banner.add_theme_font_size_override("font_size", 12)
	lbl_morgue_banner.add_theme_color_override("font_color", COL_INK)
	banner_hbox.add_child(lbl_morgue_banner)

	btn_morgue_transfer = Button.new()
	btn_morgue_transfer.text = "⚰️ Trasladar a la morgue"
	btn_morgue_transfer.focus_mode = Control.FOCUS_NONE
	btn_morgue_transfer.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_morgue_transfer.add_theme_font_size_override("font_size", 11)
	btn_morgue_transfer.add_theme_color_override("font_color", Color("#18140d"))
	btn_morgue_transfer.add_theme_stylebox_override("normal", _style_box(COL_LAMP, COL_LAMP, 1, 0, 10, 5))
	btn_morgue_transfer.pressed.connect(func():
		if is_instance_valid(current_corpse):
			if current_corpse.has_method("report_corpse_by_player") and current_corpse.get("corpse_reported") != true:
				current_corpse.call("report_corpse_by_player", player)
			current_corpse.set("corpse_in_morgue", true)
			_build_case_from_corpse(current_corpse)
			_render_morgue_view()
			_update_header_meta()
	)
	banner_hbox.add_child(btn_morgue_transfer)

	var bench_hdr := HBoxContainer.new()
	bench_hdr.add_theme_constant_override("separation", 12)
	bench_vbox.add_child(bench_hdr)

	lbl_bench_title = Label.new()
	lbl_bench_title.text = "Elige una prueba"
	lbl_bench_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_bench_title.add_theme_font_size_override("font_size", 19)
	lbl_bench_title.add_theme_color_override("font_color", COL_PAPER_INK)
	bench_hdr.add_child(lbl_bench_title)

	bench_vials_hbox = HBoxContainer.new()
	bench_vials_hbox.add_theme_constant_override("separation", 6)
	bench_hdr.add_child(bench_vials_hbox)

	var bench_sep := HSeparator.new()
	bench_vbox.add_child(bench_sep)

	var bench_scroll := ScrollContainer.new()
	bench_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bench_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bench_vbox.add_child(bench_scroll)

	bench_body_vbox = VBoxContainer.new()
	bench_body_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bench_body_vbox.add_theme_constant_override("separation", 10)
	bench_scroll.add_child(bench_body_vbox)

	bench_doc_panel = PanelContainer.new()
	bench_doc_panel.add_theme_stylebox_override("panel", _style_box(COL_PAPER_INK, COL_PAPER_INK, 0, 0, 12, 10))
	bench_doc_panel.visible = false
	bench_vbox.add_child(bench_doc_panel)

	lbl_bench_doc = RichTextLabel.new()
	lbl_bench_doc.bbcode_enabled = true
	lbl_bench_doc.fit_content = true
	lbl_bench_doc.scroll_active = false
	lbl_bench_doc.add_theme_font_size_override("normal_font_size", 12)
	lbl_bench_doc.add_theme_font_size_override("bold_font_size", 12)
	lbl_bench_doc.add_theme_color_override("default_color", COL_PAPER)
	bench_doc_panel.add_child(lbl_bench_doc)

	return split


# ==============================================================================
# Vista 3 (Bloque D3): Escena del crimen (farol + pistas físicas + testigos cercanos)
# ==============================================================================
func _build_scene_view() -> Control:
	var split := HBoxContainer.new()
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	split.add_theme_constant_override("separation", 14)
	split.visible = false

	# Izquierda (#cstage): Fondo 3D cenital en esquema a oscuras + farol que sigue al ratón + pistas en el suelo
	var stage_panel := PanelContainer.new()
	stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_panel.size_flags_stretch_ratio = 1.25
	stage_panel.add_theme_stylebox_override("panel", _style_box(COL_PANEL, COL_EDGE, 1, 0, 0, 0))
	split.add_child(stage_panel)

	var stage_overlay := Control.new()
	stage_overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_overlay.clip_contents = true
	stage_panel.add_child(stage_overlay)

	scene_sketch_tex_rect = TextureRect.new()
	scene_sketch_tex_rect.visible = false
	stage_overlay.add_child(scene_sketch_tex_rect)

	crime_scene_canvas = CrimeSceneCanvas.new()
	crime_scene_canvas.ui = self
	crime_scene_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_overlay.add_child(crime_scene_canvas)

	var lbl_scene_hint := Label.new()
	lbl_scene_hint.text = "Mueve el farol para buscar\nPulsa sobre lo que veas"
	lbl_scene_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lbl_scene_hint.offset_left = -220
	lbl_scene_hint.offset_right = -12
	lbl_scene_hint.offset_top = 10
	lbl_scene_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_scene_hint.add_theme_font_size_override("font_size", 11)
	lbl_scene_hint.add_theme_color_override("font_color", COL_DIM)
	stage_overlay.add_child(lbl_scene_hint)

	lbl_scene_ground = Label.new()
	lbl_scene_ground.text = "CLARO JUNTO AL ARROYO · CAMINO DEL NORTE ARRIBA"
	lbl_scene_ground.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	lbl_scene_ground.offset_left = 12
	lbl_scene_ground.offset_right = 460
	lbl_scene_ground.offset_top = -26
	lbl_scene_ground.offset_bottom = -8
	lbl_scene_ground.add_theme_font_size_override("font_size", 11)
	lbl_scene_ground.add_theme_color_override("font_color", COL_DIM)
	stage_overlay.add_child(lbl_scene_ground)

	# Derecha (.book): Pistas encontradas en el suelo + Testigos cercanos (Preguntar / Presionar)
	var book_panel := PanelContainer.new()
	book_panel.custom_minimum_size = Vector2(390, 0)
	book_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book_panel.add_theme_stylebox_override("panel", _style_box(COL_PAPER, COL_PAPER_EDGE, 1, 0, 18, 14))
	split.add_child(book_panel)

	var book_vbox := VBoxContainer.new()
	book_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	book_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book_vbox.add_theme_constant_override("separation", 10)
	book_panel.add_child(book_vbox)

	var lbl_sc_title := Label.new()
	lbl_sc_title.text = "Busca en la escena"
	lbl_sc_title.add_theme_font_size_override("font_size", 18)
	lbl_sc_title.add_theme_color_override("font_color", COL_PAPER_INK)
	book_vbox.add_child(lbl_sc_title)

	var lbl_sc_sub := Label.new()
	lbl_sc_sub.text = "Las pistas solo se ven bajo la luz del farol. Buscar gasta tiempo."
	lbl_sc_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_sc_sub.add_theme_font_size_override("font_size", 12)
	lbl_sc_sub.add_theme_color_override("font_color", Color("#6b6253"))
	book_vbox.add_child(lbl_sc_sub)

	var sc_scroll := ScrollContainer.new()
	sc_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book_vbox.add_child(sc_scroll)

	var sc_content := VBoxContainer.new()
	sc_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc_content.add_theme_constant_override("separation", 12)
	sc_scroll.add_child(sc_content)

	scene_finds_vbox = VBoxContainer.new()
	scene_finds_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_finds_vbox.add_theme_constant_override("separation", 8)
	sc_content.add_child(scene_finds_vbox)

	var wit_sep := HSeparator.new()
	sc_content.add_child(wit_sep)

	var lbl_wit_hdr := Label.new()
	lbl_wit_hdr.text = "Testigos"
	lbl_wit_hdr.add_theme_font_size_override("font_size", 16)
	lbl_wit_hdr.add_theme_color_override("font_color", COL_PAPER_INK)
	sc_content.add_child(lbl_wit_hdr)

	scene_witnesses_vbox = VBoxContainer.new()
	scene_witnesses_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_witnesses_vbox.add_theme_constant_override("separation", 10)
	sc_content.add_child(scene_witnesses_vbox)

	return split


# ==============================================================================
# Vista 4 (Bloque D4): Tablero del caso (tablero de corcho con sospechosos, fichas e hilos rojos)
# ==============================================================================
func _build_board_view() -> Control:
	var board_vbox := VBoxContainer.new()
	board_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_vbox.add_theme_constant_override("separation", 8)
	board_vbox.visible = false

	var hdr_hb := HBoxContainer.new()
	hdr_hb.add_theme_constant_override("separation", 12)
	board_vbox.add_child(hdr_hb)

	var lbl_bh := Label.new()
	lbl_bh.text = "Tablero del caso"
	lbl_bh.add_theme_font_size_override("font_size", 19)
	lbl_bh.add_theme_color_override("font_color", COL_INK)
	hdr_hb.add_child(lbl_bh)

	var lbl_bsub := Label.new()
	lbl_bsub.text = "Arrastra las fichas. Pulsa una y luego otra para unirlas con hilo rojo. Pulsa un hilo para quitarlo."
	lbl_bsub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_bsub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_bsub.add_theme_font_size_override("font_size", 12)
	lbl_bsub.add_theme_color_override("font_color", COL_DIM)
	hdr_hb.add_child(lbl_bsub)

	var btn_clear_links := _make_header_btn("Quitar todos los hilos", func(): clear_all_board_links())
	hdr_hb.add_child(btn_clear_links)

	var cork_frame := PanelContainer.new()
	cork_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cork_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cork_frame.add_theme_stylebox_override("panel", _style_box(Color("#9a7147"), Color("#4a3523"), 8, 0, 0, 0))
	board_vbox.add_child(cork_frame)

	corkboard_canvas = CorkboardCanvas.new()
	corkboard_canvas.ui = self
	corkboard_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	corkboard_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cork_frame.add_child(corkboard_canvas)

	return board_vbox


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

	load_detective_state()
	_build_case_from_corpse(corpse_node)
	_refresh_3d_topdown_sketch()
	switch_mode(initial_mode)
	if selected_zone == "":
		select_zone("cuello")
	else:
		_render_notebook_zone()
	_render_morgue_view()
	_render_scene_view()
	_render_board_view()
	_render_strip_notes()
	_update_header_meta()


func close_panel() -> void:
	if not visible:
		return
	save_detective_state()
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
	if mode_id == "morgue":
		_render_morgue_view()
	elif mode_id == "scene":
		_render_scene_view()
	elif mode_id == "board":
		_render_board_view()
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


func _get_corpse_site_kind() -> String:
	if is_instance_valid(current_corpse):
		if current_corpse.get("corpse_in_morgue") == true:
			return "morgue"
		if not current_corpse.has_meta("scripted_case_zones") and not current_corpse.has_meta("scripted_case_id"):
			var dpos: Vector2 = current_corpse.global_position
			var raw_dp = current_corpse.get("death_world_pos")
			if raw_dp is Vector2 and (raw_dp as Vector2) != Vector2.ZERO:
				dpos = raw_dp
			if dpos.x < -280.0 and dpos.y >= -130.0 and dpos.y <= 260.0:
				return "lake"
			if dpos.y > 380.0 and dpos.x > -660.0 and dpos.x < 480.0:
				return "ranch"
			if dpos.x >= -270.0 and dpos.x <= 1350.0 and dpos.y >= -520.0 and dpos.y <= 430.0:
				return "town"
			return "forest"
	return "forest"


func _describe_world_site(dpos: Vector2) -> String:
	if dpos.x < -280.0 and dpos.y >= -130.0 and dpos.y <= 260.0:
		return "la orilla del Lago del Oeste"
	if dpos.y > 380.0 and dpos.x > 180.0 and dpos.x < 480.0:
		return "el Rancho del Sur"
	if dpos.y > 380.0 and dpos.x > -660.0 and dpos.x <= 180.0:
		return "los campos de la Granja del Sur"
	if dpos.x >= -270.0 and dpos.x <= 40.0 and dpos.y >= -220.0 and dpos.y <= 55.0:
		return "las inmediaciones de la Trattoria «Il Corvo»"
	if dpos.x >= 180.0 and dpos.x <= 430.0 and dpos.y >= 200.0 and dpos.y <= 360.0:
		return "el Parque del Roble"
	if dpos.x >= -270.0 and dpos.x <= 1350.0 and dpos.y >= -520.0 and dpos.y <= 430.0:
		return "las calles del pueblo"
	return "los senderos de las afueras"


func _refresh_3d_topdown_sketch() -> void:
	var st := _find_world_stage_3d()
	if st != null and st.has_method("set_detective_topdown"):
		st.call("set_detective_topdown", false)
	if silhouette_canvas != null:
		silhouette_canvas.queue_redraw()
	if crime_scene_canvas != null:
		crime_scene_canvas.queue_redraw()


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
	_update_decay_bar()


func _update_decay_bar() -> void:
	if decay_phase_panels.size() != 4:
		return
	var base_rot: float = float(current_corpse.get("corpse_rot_hours")) if is_instance_valid(current_corpse) else 1.8
	var total_h: float = base_rot + float(elapsed_minutes) / 60.0
	var phase_idx: int = 0
	var phase_desc: String = "RECIENTE (rastro fresco)"
	if total_h >= 12.0:
		phase_idx = 3
		phase_desc = "DETERIORADO (%.1f h · se pierden rastros finos)" % total_h
	elif total_h >= 5.0:
		phase_idx = 2
		phase_desc = "RÍGIDO (%.1f h · rigor mortis completo)" % total_h
	elif total_h >= 1.5:
		phase_idx = 1
		phase_desc = "ENFRIÁNDOSE (%.1f h · livideces fijándose)" % total_h
	else:
		phase_desc = "RECIENTE (%.1f h · aún conserva calor)" % maxf(0.2, total_h)
	if lbl_decay_status != null:
		lbl_decay_status.text = "ESTADO DEL CUERPO · %s" % phase_desc
	var active_cols: Array[Color] = [Color("#4a7043"), Color("#b5862c"), Color("#a6582a"), Color("#8e2a23")]
	for i in range(4):
		var p: PanelContainer = decay_phase_panels[i]
		if not is_instance_valid(p):
			continue
		var is_act: bool = (i == phase_idx)
		var bg: Color = active_cols[i] if is_act else (Color("#cfc3ac") if i < phase_idx else Color("#dfd5c2"))
		p.add_theme_stylebox_override("panel", _style_box(bg, COL_PAPER_INK if is_act else COL_PAPER_EDGE, 1, 0, 4, 3))
		var lbl := p.get_node_or_null("PhaseLbl") as Label
		if lbl != null:
			lbl.add_theme_color_override("font_color", COL_PAPER if is_act else Color("#5a5244"))


# ==============================================================================
# Construcción de las 7 zonas anatómicas (datos reales del cadáver o caso guionizado)
# ==============================================================================
func _build_case_from_corpse(corpse_node: Node2D) -> void:
	dynamic_wound_marks.clear()
	var has_lupa: bool = _player_has_magnifying_glass()

	# Si no hay cadáver específico o tiene metadato de caso guionizado (Bloque D5), cargar desde DetectiveCaseData
	if corpse_node == null or not is_instance_valid(corpse_node) or corpse_node.has_meta("scripted_case_zones") or corpse_node.has_meta("scripted_case_id"):
		var sc_id: String = str(corpse_node.get_meta("scripted_case_id", DetectiveCaseDataScript.CASE_01_ID)) if (corpse_node != null and is_instance_valid(corpse_node)) else DetectiveCaseDataScript.CASE_01_ID
		var cdef: Dictionary = DetectiveCaseDataScript.get_case_def(sc_id)
		set_body_gender(str(cdef.get("victim_gender", "F")) == "F")
		if lbl_hdr_sub != null:
			lbl_hdr_sub.text = str(cdef.get("subtitle", cdef.get("title", "")))
		if lbl_corner_left != null:
			lbl_corner_left.text = str(cdef.get("corner_left", "CADÁVER EN EL SUELO · NO MOVIDO"))
		if lbl_corner_right != null:
			lbl_corner_right.text = str(cdef.get("corner_right", "TEMPERATURA AMBIENTE · FRÍO DE MADRUGADA"))
		zone_data = DetectiveCaseDataScript.get_body_zones(sc_id, has_lupa)
		_build_morgue_tests_for_corpse(corpse_node)
		_build_scene_data_for_corpse(corpse_node)
		_build_board_suspects_for_corpse(corpse_node)
		return

	var v_name: String = str(corpse_node.get("npc_name"))
	var v_role: String = str(corpse_node.get("npc_role"))
	var prof = corpse_node.get("person_profile")
	var fem: bool = (prof != null and str(prof.get("gender")) == "F") or (prof == null and v_name.ends_with("a"))
	set_body_gender(fem)

	var vm = get_tree().get_first_node_in_group("village_manager") if is_inside_tree() else null
	var f_state: Dictionary = vm.VillageForensics.state(vm) if (vm != null and "VillageForensics" in vm) else {}
	var is_moved: bool = (f_state.get("moved", {}) as Dictionary).has(v_name)
	var is_poisoned: bool = (f_state.get("poisoned", {}) as Dictionary).has(v_name)
	var is_tampered_time: bool = (f_state.get("tampered_time", {}) as Dictionary).has(v_name)
	var planted_info: Dictionary = (f_state.get("planted", {}) as Dictionary).get(v_name, {})
	var weapon_cause: String = str(corpse_node.get("last_hit_weapon_name"))
	var rot_h: float = float(corpse_node.get("corpse_rot_hours"))
	var dpos: Vector2 = corpse_node.global_position
	var raw_dp = corpse_node.get("death_world_pos")
	if raw_dp is Vector2 and (raw_dp as Vector2) != Vector2.ZERO:
		dpos = raw_dp
	var site_desc: String = _describe_world_site(dpos)

	if lbl_hdr_sub != null:
		var hallado_str: String = "hallada sin vida" if fem else "hallado sin vida"
		lbl_hdr_sub.text = "Caso · %s (%s) — %s en %s" % [v_name, v_role if v_role != "" else "Vecino", hallado_str, site_desc]
	if lbl_corner_left != null:
		if corpse_node.get("corpse_in_morgue") == true:
			lbl_corner_left.text = "CAMILLA DE LA MORGUE · %s" % v_name.to_upper()
		elif is_moved:
			lbl_corner_left.text = "CADÁVER EN EL SUELO · MOVIDO TRAS CAER"
		else:
			lbl_corner_left.text = "CADÁVER EN EL SUELO · %s" % site_desc.to_upper()
	if lbl_corner_right != null:
		var w_str: String = WorldClock.get_weather_name() if (WorldClock != null and WorldClock.has_method("get_weather_name")) else "FRÍO"
		lbl_corner_right.text = "CLIMA · %s (%.1f H SIN VIDA)" % [w_str.to_upper(), maxf(0.2, rot_h)]

	# Recopilar heridas reales por región desde HealthComponent (`part`, `type`, `source_tag`)
	var hc = corpse_node.get("health_comp")
	var wounds_by_zone: Dictionary = {"cabeza": [], "cuello": [], "torso": [], "brazos": [], "piernas": []}
	var total_wounds: int = 0
	if hc != null and hc.get("wounds") is Array:
		for w in (hc.get("wounds") as Array):
			if not (w is Dictionary):
				continue
			var part_raw: String = str(w.get("part", w.get("region", "Torso"))).to_lower()
			var target_z := "torso"
			if part_raw in ["head", "cabeza", "skull", "jaw", "lefteye", "righteye", "nose"]:
				target_z = "cabeza"
			elif part_raw in ["neck", "cuello"]:
				target_z = "cuello"
			elif part_raw in ["leftarm", "rightarm", "left_arm", "right_arm", "brazos"]:
				target_z = "brazos"
			elif part_raw in ["leftleg", "rightleg", "left_leg", "right_leg", "piernas"]:
				target_z = "piernas"
			wounds_by_zone[target_z].append(w)
			total_wounds += 1
			var w_t_low: String = str(w.get("type", "")).to_lower()
			var w_type: String = "bruise" if (w_t_low.find("contus") != -1 or w_t_low.find("bruise") != -1 or w_t_low.find("fract") != -1) else "cut"
			dynamic_wound_marks.append({
				"mark_id": "m-dyn-%s" % target_z,
				"zone": target_z,
				"type": w_type
			})

	# Si murió por golpe directo sin herida registrada en HealthComponent, añadir la marca en la zona correspondiente
	var wc_low := weapon_cause.to_lower()
	if total_wounds == 0 and weapon_cause != "" and not is_poisoned and wc_low.find("inanición") == -1:
		var fallback_z := "torso"
		if wc_low.find("martillo") != -1 or wc_low.find("contundente") != -1:
			fallback_z = "cabeza"
		elif wc_low.find("espalda") != -1 or wc_low.find("cuello") != -1:
			fallback_z = "cuello"
		var synt_w := {"type": "Contusión Severa" if fallback_z == "cabeza" else "Herida Letal", "source_tag": weapon_cause}
		wounds_by_zone[fallback_z].append(synt_w)
		dynamic_wound_marks.append({
			"mark_id": "m-dyn-%s" % fallback_z,
			"zone": fallback_z,
			"type": "bruise" if fallback_z == "cabeza" else "cut"
		})
		total_wounds = 1

	var head_wounds_txt: String = _describe_zone_wounds(wounds_by_zone["cabeza"], weapon_cause, "Rostro pálido y sin fracturas ni golpes abiertos en el cráneo.")
	var neck_wounds_txt: String = _describe_zone_wounds(wounds_by_zone["cuello"], weapon_cause, "Cuello y garganta intactos: no hay surcos de cuerda ni marcas de estrangulamiento.")
	var torso_wounds_txt: String = _describe_zone_wounds(wounds_by_zone["torso"], weapon_cause, "Ropa de %s sin desgarros de arma blanca en el pecho." % (v_role.to_lower() if v_role != "" else "vecino"))
	var arm_wounds_txt: String = _describe_zone_wounds(wounds_by_zone["brazos"], weapon_cause, "Antebrazos y muñecas libres de ataduras, sin nada fuera de lo normal; el ataque no le dio tiempo a cubrirse." if total_wounds <= 1 else "Contusiones defensivas en los antebrazos producidas durante el forcejeo.")
	var leg_wounds_txt: String = _describe_zone_wounds(wounds_by_zone["piernas"], weapon_cause, ("Talones rozados por el suelo: arrastraron el cuerpo hasta %s." % site_desc) if is_moved else ("Calzado completo y en su sitio; cayó desplomad%s en %s sin ser arrastrad%s." % ["a" if fem else "o", site_desc, "a" if fem else "o"]))

	var rigor_txt: String = "Dedos aún tibios y flexibles (murió hace menos de 1 hora)."
	if rot_h >= 4.0:
		rigor_txt = "Dedos rígidos y fríos (lleva unas %.1f horas sin vida)." % rot_h
	elif rot_h >= 1.0:
		rigor_txt = "Rigidez incipiente en mandíbula y dedos (unas %.1f horas sin vida)." % rot_h

	var pocket_summary: String = corpse_node.call("get_pocket_summary_text") if corpse_node.has_method("get_pocket_summary_text") else "Sin objetos en los bolsillos"
	if not planted_info.is_empty() and planted_info.get("debunked") != true:
		pocket_summary += ". Además asoma un objeto personal de %s colocado a propósito." % str(planted_info.get("framed_name", "otro vecino"))

	zone_data = {
		"cabeza": {
			"title": "Cabeza y rostro",
			"acts": [
				{"id": "mirar", "name": "Mirar de cerca", "cost": 2, "find": head_wounds_txt, "mark": "m-dyn-cabeza" if not wounds_by_zone["cabeza"].is_empty() else "", "tag": ("Herida en cabeza: %s" % weapon_cause) if not wounds_by_zone["cabeza"].is_empty() else "", "note": "Cabeza (%s): %s" % [v_name, head_wounds_txt]},
				{"id": "oler", "name": "Oler boca y nariz", "cost": 2, "find": "Un olor amargo sale todavía de la boca." if (is_poisoned or wc_low.find("veneno") != -1) else "No hay olor a veneno ni a brebajes extraños en boca ni nariz.", "tag": "Olor: tóxico amargo" if is_poisoned else "", "note": "Aliento (%s): %s" % [v_name, "olor amargo en la boca (posible tóxico ingerido)." if is_poisoned else "sin rastro de veneno oral."]},
				{"id": "palpar", "name": "Palpar cráneo", "cost": 3, "find": ("Hundimiento y fractura ósea compatibles con %s." % weapon_cause) if not wounds_by_zone["cabeza"].is_empty() else "Hueso craneal entero, sin hundimientos ni fracturas."},
				{"id": "lupa", "name": "Usar lupa en el pelo", "cost": 4, "locked": not has_lupa, "find": ("Con la lupa ves polvo y restos del suelo de %s adheridos al pelo tras caer." % site_desc) if has_lupa else "Hace falta llevar una Lupa de Latón en el inventario para examinar fibras y polvo."}
			]
		},
		"cuello": {
			"title": "Cuello y garganta",
			"acts": [
				{"id": "mirar", "name": "Mirar la piel", "cost": 2, "find": neck_wounds_txt, "mark": "m-dyn-cuello" if not wounds_by_zone["cuello"].is_empty() else "", "tag": ("Lesión en cuello: %s" % weapon_cause) if not wounds_by_zone["cuello"].is_empty() else "", "note": "Cuello (%s): %s" % [v_name, neck_wounds_txt]},
				{"id": "palpar", "name": "Palpar garganta", "cost": 3, "find": ("Tejido desgarrado en la zona cervical por %s." % weapon_cause) if not wounds_by_zone["cuello"].is_empty() else "Tráquea y cartílagos del cuello enteros, sin señales de asfixia mecánica."},
				{"id": "lupa", "name": "Usar lupa en el cuello", "cost": 5, "locked": not has_lupa, "find": (("Bordes limpios producidos por %s." % weapon_cause) if not wounds_by_zone["cuello"].is_empty() else "La epidermis del cuello no presenta marcas de cuerda ni arañazos.") if has_lupa else "Hace falta llevar una Lupa de Latón para revisar la epidermis.", "tag": ("Trauma cervical: %s" % weapon_cause) if not wounds_by_zone["cuello"].is_empty() else "", "note": "Detalle del cuello (%s): %s" % [v_name, weapon_cause if not wounds_by_zone["cuello"].is_empty() else "sin surcos ni estrangulamiento."]},
				{"id": "interna", "name": "Abrir tráquea", "cost": 0, "locked": true, "find": "Hace falta trasladar el cuerpo a la morgue para realizar la disección interna."}
			]
		},
		"torso": {
			"title": "Pecho y ropa",
			"acts": [
				{"id": "mirar", "name": "Mirar la ropa", "cost": 2, "find": torso_wounds_txt, "mark": "m-dyn-torso" if not wounds_by_zone["torso"].is_empty() else "", "tag": ("Lesión en torso: %s" % weapon_cause) if not wounds_by_zone["torso"].is_empty() else "", "note": "Torso (%s): %s" % [v_name, torso_wounds_txt]},
				{"id": "palpar", "name": "Palpar costillas y espalda", "cost": 4, "find": "La piel está anormalmente fría para el tiempo transcurrido: alguien enfrió el cuerpo para trucar la hora de la muerte." if is_tampered_time else ("Lividez desplazada en dos costados: movieron el cadáver horas después de morir." if is_moved else ("El cuerpo cayó en %s hace %.1f h; la lividez coincide con la postura actual." % [site_desc, maxf(0.2, rot_h)])), "tag": "Cuerpo manipulado tras morir" if (is_moved or is_tampered_time) else "", "note": "Lividez (%s): %s" % [v_name, "manipularon el cadáver tras morir." if (is_moved or is_tampered_time) else ("postura original en %s." % site_desc)]},
				{"id": "interna", "name": "Examinar estómago", "cost": 0, "locked": true, "find": "Hace falta abrir el cuerpo en la morgue para analizar el contenido gástrico."}
			]
		},
		"brazos": {
			"title": "Brazos y muñecas",
			"acts": [
				{"id": "mirar", "name": "Mirar muñecas", "cost": 2, "find": arm_wounds_txt, "mark": "m-dyn-brazos" if not wounds_by_zone["brazos"].is_empty() else "", "note": "Brazos (%s): %s" % [v_name, arm_wounds_txt]},
				{"id": "lupa", "name": "Usar lupa en mangas", "cost": 4, "locked": not has_lupa, "find": ("Las mangas muestran el desgaste habitual de su oficio (%s), sin restos de cuerdas." % (v_role if v_role != "" else "vecino")) if has_lupa else "Necesitas una Lupa de Latón para revisar las fibras de las mangas."}
			]
		},
		"manos": {
			"title": "Manos y uñas",
			"acts": [
				{"id": "mirar", "name": "Abrir los dedos", "cost": 3, "find": "%s %s" % [rigor_txt, "No llegó a empuñar arma ni defenderse." if total_wounds <= 1 else "Nudillos marcados por el forcejeo."], "note": "Manos (%s): %s" % [v_name, rigor_txt]},
				{"id": "lupa", "name": "Mirar bajo las uñas", "cost": 4, "locked": not has_lupa, "find": ("Uñas limpias de fibras ajenas: el ataque (%s) fue rápido y por sorpresa." % (weapon_cause if weapon_cause != "" else "letal")) if has_lupa else "Necesitas una Lupa de Latón para examinar debajo de las uñas."}
			]
		},
		"piernas": {
			"title": "Piernas y calzado",
			"acts": [
				{"id": "mirar", "name": "Mirar pies y bajos", "cost": 2, "find": leg_wounds_txt, "mark": "m-dyn-piernas" if not wounds_by_zone["piernas"].is_empty() else ("m-heel" if is_moved else ""), "tag": "Arrastrado tras morir" if is_moved else "", "note": "Calzado (%s): %s" % [v_name, leg_wounds_txt]},
				{"id": "oler", "name": "Examinar suelas", "cost": 2, "find": "Las suelas solo tienen tierra y humedad propias de %s." % site_desc}
			]
		},
		"bolsillos": {
			"title": "Bolsillos y zurrón",
			"acts": [
				{"id": "palpar", "name": "Palpar desde fuera", "cost": 2, "find": "Al palpar la ropa de %s notas su contenido actual: %s." % [v_name, pocket_summary]},
				{"id": "registrar", "name": "Vaciar bolsillo (10 min)", "cost": 10, "find": "Registras las pertenencias reales de %s (%s): %s." % [v_name, v_role if v_role != "" else "Vecino", pocket_summary], "tag": "Pertenencias de " + v_name, "note": "Bolsillos (%s): %s." % [v_name, pocket_summary], "loot_corpse": true}
			]
		}
	}
	_build_morgue_tests_for_corpse(corpse_node)
	_build_scene_data_for_corpse(corpse_node)
	_build_board_suspects_for_corpse(corpse_node)


func _describe_zone_wounds(w_arr: Array, weapon_cause: String, fallback_txt: String) -> String:
	if w_arr.is_empty():
		return fallback_txt
	var parts: Array[String] = []
	for w in w_arr:
		var wn: String = str(w.get("type", w.get("name", "Herida")))
		var wc: String = str(w.get("source_tag", w.get("weapon_cause", weapon_cause)))
		if wc != "" and wc != wn:
			parts.append("%s (%s)" % [wn, wc])
		else:
			parts.append(wn if wn != "" else weapon_cause)
	return "Se aprecian lesiones visibles: " + ", ".join(parts) + "."


func _get_default_forest_woman_zones(has_lupa: bool) -> Dictionary:
	return DetectiveCaseDataScript.get_body_zones(DetectiveCaseDataScript.CASE_01_ID, has_lupa)


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
		if a_id == "mirar" and (z_id == "cuello" or str(act.get("mark", "")).begins_with("m-dyn-")):
			if is_instance_valid(current_corpse) and not current_corpse.has_meta("scripted_case_zones"):
				var wc: String = str(current_corpse.get("last_hit_weapon_name"))
				if wc != "":
					apparent_cause_str = "%s (sin confirmar)" % wc
				elif z_id == "cuello":
					apparent_cause_str = "Sin lesiones letales visibles en el cuello"
			elif z_id == "cuello":
				apparent_cause_str = "Estrangulamiento con las manos (sin confirmar)"
			if lbl_apparent_cause != null:
				lbl_apparent_cause.text = "Causa aparente: [color=#e7b45a][b]%s[/b][/color]" % apparent_cause_str
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
		pin_btn.add_theme_color_override("font_disabled_color", COL_GREEN_OK)
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
	var pin_id: String = source_key if source_key != "" else ("n_%d" % notebook_notes.size())
	notebook_notes.append({
		"id": pin_id,
		"title": title,
		"text": text,
		"tag": tag,
		"source_key": source_key
	})
	_render_strip_notes()
	if current_mode == "board":
		_render_board_view()
	save_detective_state()


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


# ==============================================================================
# Bloque D2 — Autopsia en la morgue (4 pruebas por pasos, muestras limitadas, consejo del forense)
# ==============================================================================
func _build_morgue_tests_for_corpse(corpse_node: Node2D) -> void:
	morgue_tests_def = _get_default_morgue_tests(corpse_node)
	var target_key: String = str(corpse_node.get("npc_name")) if (corpse_node != null and is_instance_valid(corpse_node) and not corpse_node.has_meta("scripted_case_zones")) else "scripted_forest_woman"
	if current_case_id != target_key or morgue_tests_state.is_empty():
		current_case_id = target_key
		morgue_tests_state.clear()
		for k in ["sangre", "cuello", "estomago", "piel"]:
			var d: Dictionary = morgue_tests_def.get(k, {})
			morgue_tests_state[k] = {
				"step": 0,
				"log": [],
				"state": "",
				"vials": int(d.get("vials", 0)),
				"dud": false,
				"hint_asked": {}
			}
	if selected_morgue_test == "" or not morgue_tests_def.has(selected_morgue_test):
		selected_morgue_test = "sangre"


func _get_default_morgue_tests(corpse_node: Node2D) -> Dictionary:
	var is_scripted: bool = (corpse_node == null or not is_instance_valid(corpse_node) or corpse_node.has_meta("scripted_case_zones") or corpse_node.has_meta("scripted_case_id"))
	if is_scripted:
		var sc_id: String = str(corpse_node.get_meta("scripted_case_id", DetectiveCaseDataScript.CASE_01_ID)) if (corpse_node != null and is_instance_valid(corpse_node)) else DetectiveCaseDataScript.CASE_01_ID
		return DetectiveCaseDataScript.get_morgue_tests(sc_id)
	var v_name: String = str(corpse_node.get("npc_name"))
	var fem: bool = is_female_model
	var vm = get_tree().get_first_node_in_group("village_manager") if is_inside_tree() else null
	var f_state: Dictionary = vm.VillageForensics.state(vm) if (vm != null and "VillageForensics" in vm) else {}
	var is_poisoned: bool = (f_state.get("poisoned", {}) as Dictionary).has(v_name)
	var is_moved: bool = (f_state.get("moved", {}) as Dictionary).has(v_name)
	var is_tampered_time: bool = (f_state.get("tampered_time", {}) as Dictionary).has(v_name)
	var weapon_cause: String = str(corpse_node.get("last_hit_weapon_name"))
	var rot_h: float = float(corpse_node.get("corpse_rot_hours"))

	var blood_cause: String = ("envenenada con tóxico lento" if fem else "envenenado con tóxico lento") if is_poisoned else ("hemorragia aguda (%s)" % (weapon_cause.to_lower() if weapon_cause != "" else "trauma físico"))
	var blood_note_tag: String = "Sangre: tóxico lento" if is_poisoned else "Sangre: limpia de veneno"
	var trauma_cause: String = "lesión mortal por %s" % (weapon_cause.to_lower() if weapon_cause != "" else "impacto")
	var skin_cause: String = ("movida tras morir" if fem else "movido tras morir") if is_moved else (("enfriada artificialmente" if fem else "enfriado artificialmente") if is_tampered_time else ("fallecid%s en el acto hace %.1f h" % ["a" if fem else "o", maxf(0.2, rot_h)]))

	return {
		"sangre": {
			"name": "Sangre",
			"vials": 2,
			"steps": [
				{
					"q": "¿De dónde sacas la sangre?",
					"hint": "«Del corazón. La del brazo ya se ha posado.»",
					"opts": [
						["Del corazón", "ok", "Sangre oscura y homogénea: buena muestra."],
						["Del brazo", "dud", "Apenas sale. Muestra pobre: lo que veas será dudoso."]
					]
				},
				{
					"q": "Elige el reactivo toxicológico",
					"hint": "«La tintura de corteza revela alcaloides y venenos vegetales.»",
					"opts": [
						["Sal de plata", "fail", "No reacciona. Gastas parte de la muestra."],
						["Tintura de corteza", "ok", "La gota vira a verde oscuro: hay veneno en sangre." if is_poisoned else "La gota permanece rojiza sin virar: no hay veneno en la sangre."],
						["Vinagre de cobre", "fail", "Sin reacción útil. Gastas parte de la muestra."]
					]
				},
				{
					"q": "¿Qué concluyes del análisis de sangre?",
					"chart": true,
					"hint": "«Si no vira de color, la muerte fue por el golpe o la herida, no por veneno.»",
					"opts": [
						["Tóxico vegetal en sangre" if is_poisoned else "Sangre sin veneno (muerte traumática)", "ok", "Confirmas envenenamiento en la sangre de %s." % v_name if is_poisoned else "Descartas veneno: %s murió por %s." % [v_name, weapon_cause if weapon_cause != "" else "herida traumática"]],
						["Resultado inconcluso", "dud", "Anotas duda sobre la muestra."]
					]
				}
			],
			"cause": blood_cause,
			"note_title": "Autopsia · Sangre",
			"note_tag": blood_note_tag
		},
		"cuello": {
			"name": "Lesión mortal",
			"vials": 0,
			"steps": [
				{
					"q": "¿Cómo disecas la zona de la herida principal?",
					"hint": "«Despacio, por planos. Si cortas deprisa destrozas el rastro del arma.»",
					"opts": [
						["Corte lento, por capas", "ok", "Expones limpiamente el plano muscular y óseo de la lesión."],
						["Corte rápido", "ruin", "Destrozas los bordes internos al cortar: ya no se distingue el arma."]
					]
				},
				{
					"q": "Examina la lesión interna",
					"hint": "",
					"opts": [
						["Inspeccionar", "ok", "Traumatismo interno letal producido por %s." % (weapon_cause if weapon_cause != "" else "un golpe directo")]
					]
				}
			],
			"cause": trauma_cause,
			"note_title": "Autopsia · Lesión mortal",
			"note_tag": "Arma: " + (weapon_cause if weapon_cause != "" else "trauma")
		},
		"estomago": {
			"name": "Estómago",
			"vials": 0,
			"steps": [
				{
					"q": "Abre el estómago",
					"hint": "",
					"opts": [
						["Abrir y vaciar en un cuenco", "ok", "Líquido amargo y verdoso de un tóxico recién ingerido." if is_poisoned else "Restos normales de su última comida en el pueblo, sin rastro de veneno."]
					]
				},
				{
					"q": "¿Qué haces con la muestra gástrica?",
					"hint": "«Séllala en un frasco para dejar constancia en el informe.»",
					"opts": [
						["Guardarla en un frasco sellado", "ok", "Muestra gástrica de %s sellada y etiquetada." % v_name],
						["Descartarla", "ruin", "Tiras el contenido sin conservar muestra."]
					]
				}
			],
			"cause": "",
			"note_title": "Autopsia · Estómago",
			"note_tag": "Estómago: tóxico" if is_poisoned else "Estómago: comida normal"
		},
		"piel": {
			"name": "Piel y rigidez",
			"vials": 0,
			"steps": [
				{
					"q": "Gira el cuerpo y revisa las livideces",
					"hint": "",
					"opts": [
						["Girar el cuerpo", "ok", "Doble marca de lividez: movieron a %s horas después de morir." % v_name if is_moved else "Lividez única y asentada: el cuerpo no fue movido del sitio donde cayó."]
					]
				},
				{
					"q": "Comprueba la rigidez articular",
					"hint": "",
					"opts": [
						["Doblar codos y rodillas", "ok", "Enfriamiento artificial para falsear la hora de la muerte." if is_tampered_time else ("Rigidez acorde a %.1f horas desde el fallecimiento." % maxf(0.2, rot_h))]
					]
				}
			],
			"cause": skin_cause,
			"note_title": "Autopsia · Piel y rigidez",
			"note_tag": "Lividez doble (movido)" if is_moved else ("Hora muerte: ~%.1f h" % maxf(0.2, rot_h))
		}
	}


func _check_morgue_status() -> Dictionary:
	var doc_name := "Dr. Valen"
	var doc_ok := true
	var in_morgue := true
	var is_scripted: bool = (current_corpse == null or not is_instance_valid(current_corpse) or current_corpse.has_meta("scripted_case_zones"))
	if not is_scripted:
		in_morgue = (current_corpse.get("corpse_in_morgue") == true)
		var vm = get_tree().get_first_node_in_group("village_manager") if is_inside_tree() else null
		if vm != null:
			if not in_morgue and "morgue_active_corpses" in vm:
				var vn: String = str(current_corpse.get("npc_name"))
				for rec in vm.morgue_active_corpses:
					if str(rec.get("victim_name", "")) == vn:
						in_morgue = true
						break
			if "trade_npcs" in vm:
				var doc_npc = vm.trade_npcs.get(12, null) # TradeRole.DOCTOR == 12
				if doc_npc == null and "village_npcs" in vm:
					for n in vm.village_npcs:
						if is_instance_valid(n) and int(n.get("trade_role")) == 12:
							doc_npc = n
							break
				if doc_npc != null and is_instance_valid(doc_npc):
					doc_name = str(doc_npc.get("npc_name"))
					if not doc_name.begins_with("Dr."):
						doc_name = "Dr. " + doc_name
					if doc_npc.get("is_dead") == true or doc_npc.get("is_downed") == true:
						doc_ok = false
	return {
		"can_autopsy": in_morgue and doc_ok,
		"in_morgue": in_morgue,
		"doc_ok": doc_ok,
		"doc_name": doc_name
	}


func _morgue_status_badge(test_id: String) -> Dictionary:
	var t: Dictionary = morgue_tests_state.get(test_id, {})
	var st: String = str(t.get("state", ""))
	var d: Dictionary = morgue_tests_def.get(test_id, {})
	var steps: Array = d.get("steps", [])
	if st == "ruin":
		return {"text": "estropeada", "color": COL_BLOOD}
	if st == "done":
		if t.get("dud") == true:
			return {"text": "dudosa", "color": COL_LAMP}
		return {"text": "hecha", "color": Color("#9cc28a")}
	var step_idx: int = int(t.get("step", 0))
	if step_idx > 0:
		return {"text": "paso %d/%d" % [step_idx + 1, steps.size()], "color": COL_DIM}
	return {"text": "sin hacer", "color": COL_DIM}


func get_real_cause_text() -> String:
	var parts: Array[String] = []
	var tc: Dictionary = morgue_tests_state.get("cuello", {})
	if str(tc.get("state", "")) == "done":
		var c1: String = str(morgue_tests_def.get("cuello", {}).get("cause", ""))
		if c1 != "":
			parts.append(c1)
	var ts: Dictionary = morgue_tests_state.get("sangre", {})
	if str(ts.get("state", "")) == "done" and ts.get("dud") != true:
		var c2: String = str(morgue_tests_def.get("sangre", {}).get("cause", ""))
		if c2 != "":
			parts.append(c2)
	var tp: Dictionary = morgue_tests_state.get("piel", {})
	if str(tp.get("state", "")) == "done":
		var c3: String = str(morgue_tests_def.get("piel", {}).get("cause", ""))
		if c3 != "":
			parts.append(c3)
	return ", ".join(parts) if not parts.is_empty() else "sin determinar"


func select_morgue_test(test_id: String) -> void:
	if not morgue_tests_def.has(test_id):
		return
	selected_morgue_test = test_id
	_render_morgue_view()


func ask_morgue_doctor(test_id: String) -> void:
	if not morgue_tests_def.has(test_id) or not morgue_tests_state.has(test_id):
		return
	var mst := _check_morgue_status()
	if mst.get("can_autopsy") != true:
		return
	var t: Dictionary = morgue_tests_state[test_id]
	var d: Dictionary = morgue_tests_def[test_id]
	var steps: Array = d.get("steps", [])
	var step_idx: int = int(t.get("step", 0))
	if str(t.get("state", "")) != "" or step_idx >= steps.size():
		return
	var st_dict: Dictionary = steps[step_idx]
	var hint_txt: String = str(st_dict.get("hint", ""))
	if hint_txt == "":
		return
	var asked_map: Dictionary = t.get("hint_asked", {})
	if asked_map.get(step_idx) != true:
		asked_map[step_idx] = true
		t["hint_asked"] = asked_map
		_advance_investigation_minutes(5)
	_render_morgue_view()


func choose_morgue_option(test_id: String, opt_idx: int) -> void:
	if not morgue_tests_def.has(test_id) or not morgue_tests_state.has(test_id):
		return
	var mst := _check_morgue_status()
	if mst.get("can_autopsy") != true:
		return
	var t: Dictionary = morgue_tests_state[test_id]
	var d: Dictionary = morgue_tests_def[test_id]
	var steps: Array = d.get("steps", [])
	var step_idx: int = int(t.get("step", 0))
	if str(t.get("state", "")) != "" or step_idx >= steps.size():
		return
	var st_dict: Dictionary = steps[step_idx]
	var opts: Array = st_dict.get("opts", [])
	if opt_idx < 0 or opt_idx >= opts.size():
		return
	var op: Array = opts[opt_idx]
	var outcome: String = str(op[1])
	var msg: String = str(op[2])

	_advance_investigation_minutes(10)
	var log_arr: Array = t.get("log", [])

	if outcome == "fail":
		var v_left: int = int(t.get("vials", 0)) - 1
		t["vials"] = v_left
		log_arr.append(["bad", msg])
		if v_left <= 0:
			t["state"] = "ruin"
			log_arr.append(["bad", "Muestra agotada. Esta prueba ya no se puede repetir."])
	elif outcome == "ruin":
		log_arr.append(["bad", msg])
		t["state"] = "ruin"
	else:
		if outcome == "dud":
			t["dud"] = true
		log_arr.append(["dud" if outcome == "dud" else "ok", msg])
		step_idx += 1
		t["step"] = step_idx
		if step_idx >= steps.size():
			t["state"] = "done"
			findings_count += 1
			_apply_real_forensics_on_morgue_done(test_id, t.get("dud") == true)

	t["log"] = log_arr
	_update_header_meta()
	_render_morgue_view()


func _apply_real_forensics_on_morgue_done(test_id: String, is_dud: bool) -> void:
	if current_corpse == null or not is_instance_valid(current_corpse) or current_corpse.has_meta("scripted_case_zones"):
		return
	var vm = get_tree().get_first_node_in_group("village_manager") if is_inside_tree() else null
	if vm == null or not ("VillageForensics" in vm):
		return
	var v_name: String = str(current_corpse.get("npc_name"))
	var st: Dictionary = vm.VillageForensics.state(vm)
	if test_id == "sangre" and not is_dud:
		if (st.get("poisoned", {}) as Dictionary).has(v_name):
			var p_info: Dictionary = st["poisoned"][v_name]
			if p_info.get("autopsied") != true:
				p_info["autopsied"] = true
				current_corpse.set("last_hit_weapon_name", "Envenenamiento lento confirmado")
				if vm.has_method("start_sheriff_investigation"):
					vm.call("start_sheriff_investigation", current_corpse, current_corpse.get("death_world_pos"), "Envenenamiento lento confirmado", "Jugador")
				if vm.active_sheriff_investigation.get("active") == true:
					var susp2: Dictionary = vm.active_sheriff_investigation.get("suspects", {})
					var kn: String = str(p_info.get("killer_name", ""))
					if susp2.has(kn):
						susp2[kn]["score"] = int(susp2[kn].get("score", 10)) + 30
	elif test_id == "piel":
		if (st.get("tampered_time", {}) as Dictionary).has(v_name):
			var tt: Dictionary = st["tampered_time"][v_name]
			if tt.get("examined") != true:
				tt["examined"] = true
				if vm.active_sheriff_investigation.get("active") == true:
					var susp_t: Dictionary = vm.active_sheriff_investigation.get("suspects", {})
					var kn_t: String = str(tt.get("killer_name", ""))
					if susp_t.has(kn_t):
						susp_t[kn_t]["score"] = int(susp_t[kn_t].get("score", 15)) + 25


func _render_morgue_view() -> void:
	if morgue_list_vbox == null or bench_body_vbox == null:
		return
	if morgue_tests_def.is_empty():
		_build_morgue_tests_for_corpse(current_corpse)

	var mst := _check_morgue_status()
	var can_autopsy: bool = mst.get("can_autopsy") == true
	var doc_name: String = str(mst.get("doc_name", "Dr. Valen"))

	if lbl_morgue_sub != null:
		lbl_morgue_sub.text = "Con el %s. Si te equivocas, la muestra se pierde." % doc_name

	if morgue_status_banner != null:
		morgue_status_banner.visible = not can_autopsy
		if not can_autopsy:
			if mst.get("in_morgue") != true:
				lbl_morgue_banner.text = "El cuerpo aún yace en la escena del crimen. Trasládalo a la camilla de la morgue para realizar la autopsia."
				btn_morgue_transfer.visible = true
			else:
				lbl_morgue_banner.text = "El forense (%s) se encuentra incapacitado o ausente y no puede asistir en la mesa de autopsias." % doc_name
				btn_morgue_transfer.visible = false

	# 1. Renderizar lista de las 4 pruebas a la izquierda
	for c in morgue_list_vbox.get_children():
		c.queue_free()

	for k in ["sangre", "cuello", "estomago", "piel"]:
		if not morgue_tests_def.has(k):
			continue
		var d: Dictionary = morgue_tests_def[k]
		var badge := _morgue_status_badge(k)
		var is_sel: bool = (selected_morgue_test == k)

		var row_btn := Button.new()
		row_btn.custom_minimum_size = Vector2(0, 40)
		row_btn.focus_mode = Control.FOCUS_NONE
		row_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var b_border := COL_LAMP if is_sel else COL_EDGE
		var b_bg := Color("#232b31") if is_sel else Color("#181d22")
		row_btn.add_theme_stylebox_override("normal", _style_box(b_bg, b_border, 1, 0, 12, 8))
		row_btn.add_theme_stylebox_override("hover", _style_box(Color("#273038"), COL_LAMP, 1, 0, 12, 8))
		row_btn.add_theme_stylebox_override("pressed", _style_box(Color("#2c363f"), COL_LAMP, 1, 0, 12, 8))
		row_btn.pressed.connect(func(): select_morgue_test(k))
		morgue_list_vbox.add_child(row_btn)

		var hb := HBoxContainer.new()
		hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hb.offset_left = 12
		hb.offset_right = -12
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_btn.add_child(hb)

		var nl := Label.new()
		nl.text = str(d.get("name", k))
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nl.add_theme_font_size_override("font_size", 14)
		nl.add_theme_color_override("font_color", COL_INK)
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(nl)

		var sl := Label.new()
		sl.text = str(badge.get("text", "sin hacer"))
		sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sl.add_theme_font_size_override("font_size", 11)
		sl.add_theme_color_override("font_color", badge.get("color", COL_DIM))
		sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(sl)

	# 2. Actualizar Causa real abajo a la izquierda
	if lbl_real_cause != null:
		lbl_real_cause.text = "Causa real: [color=#e7b45a][b]%s[/b][/color]" % get_real_cause_text()

	# 3. Renderizar banco de pruebas a la derecha (.bench)
	for c in bench_vials_hbox.get_children():
		c.queue_free()
	for c in bench_body_vbox.get_children():
		c.queue_free()
	bench_doc_panel.visible = false

	if selected_morgue_test == "" or not morgue_tests_def.has(selected_morgue_test):
		lbl_bench_title.text = "Elige una prueba"
		var empty_l := Label.new()
		empty_l.text = "Cada prueba tiene varios pasos. Algunas elecciones estropean lo que querías ver; otras solo dan un resultado dudoso."
		empty_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_l.add_theme_font_size_override("font_size", 13)
		empty_l.add_theme_color_override("font_color", Color("#6a6254"))
		bench_body_vbox.add_child(empty_l)
		return

	var k_cur: String = selected_morgue_test
	var d_cur: Dictionary = morgue_tests_def[k_cur]
	var t_cur: Dictionary = morgue_tests_state[k_cur]
	lbl_bench_title.text = str(d_cur.get("name", k_cur))

	# Indicador de viales de muestra ("Muestras de sangre: X / 2" + iconos de tubo)
	var max_vials: int = int(d_cur.get("vials", 0))
	var cur_vials: int = int(t_cur.get("vials", 0))
	if max_vials > 0:
		var vl := Label.new()
		vl.text = "muestra (%d/%d)" % [cur_vials, max_vials]
		vl.add_theme_font_size_override("font_size", 11)
		vl.add_theme_color_override("font_color", Color("#7b6f5a"))
		bench_vials_hbox.add_child(vl)
		for vi in range(max_vials):
			var vial_panel := PanelContainer.new()
			vial_panel.custom_minimum_size = Vector2(12, 24)
			var is_full: bool = (vi < cur_vials)
			var v_bg := COL_BLOOD if is_full else Color(0, 0, 0, 0)
			var v_st := _style_box(v_bg, COL_PAPER_INK, 1, 3, 0, 0)
			vial_panel.add_theme_stylebox_override("panel", v_st)
			bench_vials_hbox.add_child(vial_panel)

	var st_str: String = str(t_cur.get("state", ""))
	var step_idx: int = int(t_cur.get("step", 0))
	var steps: Array = d_cur.get("steps", [])

	# Si la prueba sigue en curso, mostrar pregunta del paso actual, tabla de colores, opciones y botón del Dr. Valen
	if st_str == "" and step_idx < steps.size():
		var st_dict: Dictionary = steps[step_idx]
		var q_lbl := Label.new()
		q_lbl.text = str(st_dict.get("q", ""))
		q_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q_lbl.add_theme_font_size_override("font_size", 16)
		q_lbl.add_theme_color_override("font_color", COL_PAPER_INK)
		bench_body_vbox.add_child(q_lbl)

		# Tabla de colores de referencia (paso 3 de Sangre)
		if st_dict.get("chart") == true:
			var chart_flow := HFlowContainer.new()
			chart_flow.add_theme_constant_override("h_separation", 12)
			chart_flow.add_theme_constant_override("v_separation", 6)
			bench_body_vbox.add_child(chart_flow)
			var swatches := [
				[Color("#2f4a2a"), "verde oscuro"],
				[Color("#8a7a2a"), "pardo"],
				[Color("#6a3a6a"), "morado"],
				[Color("#cfc7b5"), "sin cambio"]
			]
			for sw in swatches:
				var sw_hb := HBoxContainer.new()
				sw_hb.add_theme_constant_override("separation", 6)
				var sq := PanelContainer.new()
				sq.custom_minimum_size = Vector2(18, 18)
				sq.add_theme_stylebox_override("panel", _style_box(sw[0], COL_PAPER_INK, 1, 0, 0, 0))
				sw_hb.add_child(sq)
				var sw_l := Label.new()
				sw_l.text = str(sw[1])
				sw_l.add_theme_font_size_override("font_size", 12)
				sw_l.add_theme_color_override("font_color", COL_PAPER_INK)
				sw_hb.add_child(sw_l)
				chart_flow.add_child(sw_hb)

		# Botones de elección del paso
		var opts_flow := HFlowContainer.new()
		opts_flow.add_theme_constant_override("h_separation", 6)
		opts_flow.add_theme_constant_override("v_separation", 6)
		bench_body_vbox.add_child(opts_flow)

		var opts: Array = st_dict.get("opts", [])
		for oi in range(opts.size()):
			var op: Array = opts[oi]
			var opt_btn := Button.new()
			opt_btn.text = str(op[0])
			opt_btn.disabled = not can_autopsy
			opt_btn.focus_mode = Control.FOCUS_NONE
			opt_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can_autopsy else Control.CURSOR_FORBIDDEN
			opt_btn.add_theme_font_size_override("font_size", 13)
			opt_btn.add_theme_color_override("font_color", COL_PAPER)
			opt_btn.add_theme_color_override("font_hover_color", COL_LAMP)
			opt_btn.add_theme_stylebox_override("normal", _style_box(COL_PAPER_INK, COL_PAPER_INK, 1, 0, 12, 7))
			opt_btn.add_theme_stylebox_override("hover", _style_box(Color("#3b352d"), COL_LAMP, 1, 0, 12, 7))
			opt_btn.add_theme_stylebox_override("disabled", _style_box(Color("#b7ab92"), Color("#8e836d"), 1, 0, 12, 7))
			var captured_oi: int = oi
			opt_btn.pressed.connect(func(): choose_morgue_option(k_cur, captured_oi))
			opts_flow.add_child(opt_btn)

		# Botón «Preguntar al Dr. Valen (+5 min)» o consejo ya revelado
		var hint_txt: String = str(st_dict.get("hint", ""))
		if hint_txt != "":
			var asked_map: Dictionary = t_cur.get("hint_asked", {})
			if asked_map.get(step_idx) == true:
				bench_doc_panel.visible = true
				lbl_bench_doc.text = "[color=#e7b45a][b]%s:[/b][/color] %s" % [doc_name, hint_txt]
			else:
				var ask_btn := Button.new()
				ask_btn.text = "Preguntar al %s (+5 min)" % doc_name
				ask_btn.disabled = not can_autopsy
				ask_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				ask_btn.focus_mode = Control.FOCUS_NONE
				ask_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can_autopsy else Control.CURSOR_FORBIDDEN
				ask_btn.add_theme_font_size_override("font_size", 12)
				ask_btn.add_theme_color_override("font_color", COL_PAPER_INK)
				ask_btn.add_theme_stylebox_override("normal", _style_box(Color(0, 0, 0, 0), COL_PAPER_INK, 1, 0, 10, 5))
				ask_btn.add_theme_stylebox_override("hover", _style_box(Color("#dcd0b6"), COL_PAPER_INK, 1, 0, 10, 5))
				ask_btn.pressed.connect(func(): ask_morgue_doctor(k_cur))
				bench_body_vbox.add_child(ask_btn)

	# Registro de pasos realizados en esta prueba (.log)
	var log_arr: Array = t_cur.get("log", [])
	for entry in log_arr:
		var e_kind: String = str(entry[0])
		var e_txt: String = str(entry[1])
		var step_card := PanelContainer.new()
		var st_box := _style_box(Color("#f3ecdc"), COL_PAPER_EDGE, 1, 0, 10, 7)
		st_box.border_width_left = 3
		if e_kind == "bad":
			st_box.border_color = Color("#8a2f2a")
		elif e_kind == "dud":
			st_box.border_color = Color("#7a5a1e")
		else:
			st_box.border_color = COL_GREEN_OK
		step_card.add_theme_stylebox_override("panel", st_box)
		bench_body_vbox.add_child(step_card)

		var pl := Label.new()
		pl.text = e_txt
		pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pl.add_theme_font_size_override("font_size", 13)
		var p_col := Color("#8a2f2a") if e_kind == "bad" else (Color("#7a5a1e") if e_kind == "dud" else COL_PAPER_INK)
		pl.add_theme_color_override("font_color", p_col)
		step_card.add_child(pl)

	# Si la prueba ha concluido con éxito ("done"), mostrar botón para anotar en el cuaderno
	if st_str == "done" and not log_arr.is_empty():
		var last_entry: Array = log_arr[log_arr.size() - 1]
		var last_txt: String = str(last_entry[1])
		var note_key: String = "m_%s" % k_cur
		var already_pinned: bool = _has_note_with_key(note_key)
		var note_btn := Button.new()
		note_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		note_btn.focus_mode = Control.FOCUS_NONE
		note_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		note_btn.text = "✓ En el cuaderno" if already_pinned else "📌 Anotar en el cuaderno"
		note_btn.disabled = already_pinned
		note_btn.add_theme_font_size_override("font_size", 12)
		note_btn.add_theme_color_override("font_color", COL_GREEN_OK if already_pinned else Color("#f3ecdc"))
		note_btn.add_theme_color_override("font_disabled_color", COL_GREEN_OK)
		var p_bg := Color("#dfd4bc") if already_pinned else COL_PAPER_INK
		note_btn.add_theme_stylebox_override("normal", _style_box(p_bg, COL_PAPER_INK, 1, 0, 10, 5))
		note_btn.add_theme_stylebox_override("disabled", _style_box(Color("#dfd4bc"), COL_GREEN_OK, 1, 0, 10, 5))
		note_btn.pressed.connect(func():
			var n_title: String = str(d_cur.get("note_title", "Autopsia · " + str(d_cur.get("name", k_cur))))
			var n_tag: String = str(d_cur.get("note_tag", n_title))
			add_notebook_note(n_title, last_txt, n_tag, note_key)
			_render_morgue_view()
		)
		bench_body_vbox.add_child(note_btn)


# ==============================================================================
# Bloque D3 — Escena del crimen (farol + pistas reales de VillageForensics + testigos cercanos)
# ==============================================================================
func set_lantern_canvas_pos(bpos: Vector2, raw_px: Vector2 = Vector2.ZERO, canvas_sz: Vector2 = Vector2.ZERO) -> void:
	var clamped := Vector2(clampf(bpos.x, 12.0, 508.0), clampf(bpos.y, 12.0, 548.0))
	if crime_scene_canvas != null:
		crime_scene_canvas.lantern_base_pos = clamped
		crime_scene_canvas.queue_redraw()
	if scene_sketch_mat != null:
		var uv: Vector2
		if crime_scene_canvas != null and crime_scene_canvas.size.x > 1.0 and crime_scene_canvas.size.y > 1.0:
			var c_pt: Vector2 = crime_scene_canvas._to_canvas(clamped)
			uv = Vector2(clampf(c_pt.x / crime_scene_canvas.size.x, 0.0, 1.0), clampf(c_pt.y / crime_scene_canvas.size.y, 0.0, 1.0))
		elif canvas_sz.x > 1.0 and canvas_sz.y > 1.0:
			uv = Vector2(clampf(raw_px.x / canvas_sz.x, 0.0, 1.0), clampf(raw_px.y / canvas_sz.y, 0.0, 1.0))
		else:
			uv = Vector2(clamped.x / 520.0, clamped.y / 560.0)
		scene_sketch_mat.set_shader_parameter("lantern_uv", uv)


func _build_scene_data_for_corpse(corpse_node: Node2D) -> void:
	var is_scripted: bool = (corpse_node == null or not is_instance_valid(corpse_node) or corpse_node.has_meta("scripted_case_zones") or corpse_node.has_meta("scripted_case_id"))
	if is_scripted:
		var sc_id: String = str(corpse_node.get_meta("scripted_case_id", DetectiveCaseDataScript.CASE_01_ID)) if (corpse_node != null and is_instance_valid(corpse_node)) else DetectiveCaseDataScript.CASE_01_ID
		var cdef: Dictionary = DetectiveCaseDataScript.get_case_def(sc_id)
		if lbl_scene_ground != null:
			lbl_scene_ground.text = str(cdef.get("scene_ground_label", "CLARO JUNTO AL ARROYO · CAMINO DEL NORTE ARRIBA"))
		scene_clues = DetectiveCaseDataScript.get_scene_clues(sc_id)
		if scene_witnesses.is_empty():
			scene_witnesses = DetectiveCaseDataScript.get_scene_witnesses(sc_id)
		return

	var v_name: String = str(corpse_node.get("npc_name"))
	var d_pos: Vector2 = corpse_node.global_position
	var raw_dpos = corpse_node.get("death_world_pos")
	if raw_dpos is Vector2 and (raw_dpos as Vector2) != Vector2.ZERO:
		d_pos = raw_dpos

	var vm = get_tree().get_first_node_in_group("village_manager") if is_inside_tree() else null
	var f_state: Dictionary = vm.VillageForensics.state(vm) if (vm != null and "VillageForensics" in vm) else {}
	var is_moved: bool = (f_state.get("moved", {}) as Dictionary).has(v_name)
	var is_poisoned: bool = (f_state.get("poisoned", {}) as Dictionary).has(v_name)
	var planted_info: Dictionary = (f_state.get("planted", {}) as Dictionary).get(v_name, {})
	var tampered_wit: Dictionary = (f_state.get("tampered", {}) as Dictionary).get(v_name, {})
	var weapon_cause: String = str(corpse_node.get("last_hit_weapon_name"))

	var has_blood_puddle := false
	if vm != null and "blood_puddles" in vm:
		for pud in vm.blood_puddles:
			var ppos: Vector2 = pud.get("pos", Vector2.INF)
			if ppos.distance_to(d_pos) <= 110.0:
				has_blood_puddle = true
				break

	if lbl_scene_ground != null:
		lbl_scene_ground.text = ("ESCENA DEL CRIMEN · %s (POSICIÓN (%.0f, %.0f))" % [v_name.to_upper(), d_pos.x, d_pos.y])

	var drag_txt: String = "Dos surcos paralelos en la tierra hasta el cuerpo: mataron a %s en otro sitio y lo trajeron a rastras." % v_name if is_moved else "Tierra pisoteada en torno a donde cayó %s, sin surcos de arrastre largo." % v_name
	var item_txt: String = "Una ramita seca y restos del forcejeo (%s) junto al costado." % (weapon_cause if weapon_cause != "" else "golpe")
	if not planted_info.is_empty():
		item_txt = "Un objeto personal de %s dejado muy a la vista sobre la tierra limpia: parece plantado a propósito." % str(planted_info.get("framed_name", "un vecino"))
	elif is_poisoned:
		item_txt = "Gotas secas de un brebaje verdoso y amargo derramadas junto a la mano."

	var blood_txt: String = "Ni una gota de sangre en el suelo. No murió de una herida abierta aquí."
	var blood_draw: String = "circle"
	if has_blood_puddle:
		blood_txt = "Un charco de sangre oscura empapa la tierra bajo el cuerpo: la herida mortal se produjo aquí mismo."
		blood_draw = "blood"
	elif not is_poisoned and not is_moved:
		blood_txt = "Las piedras bajo el cuerpo huelen a lejía y tierra barrida: alguien fregó la sangre antes de que llegaran."

	scene_clues = [
		{"x": 300.0, "y": 150.0, "r": 16.0, "draw_kind": "drag", "k": "Rastro en el suelo", "t": drag_txt, "m": 10, "forensic_action": "track_drag" if is_moved else ""},
		{"x": 214.0, "y": 196.0, "r": 14.0, "draw_kind": "prints", "k": "Huellas", "t": "Huellas profundas junto al cuerpo que se alejan con prisa hacia la calleja.", "m": 10},
		{"x": 258.0, "y": 60.0, "r": 16.0, "draw_kind": "wheels", "k": "Camino de acceso", "t": "Marcas de espera tras el muro cercano antes de cometerse el crimen.", "m": 10},
		{"x": 330.0, "y": 300.0, "r": 12.0, "draw_kind": "herb", "k": "Junto al cuerpo", "t": item_txt, "m": 5, "forensic_action": "debunk_planted" if not planted_info.is_empty() else ""},
		{"x": 250.0, "y": 400.0, "r": 18.0, "draw_kind": blood_draw, "k": "Bajo el cuerpo", "t": blood_txt, "m": 5},
		{"x": 200.0, "y": 480.0, "r": 14.0, "draw_kind": "mud", "k": "Alrededores", "t": "Barro removido junto al desagüe, como si alguien se hubiera limpiado las manos con prisa.", "m": 10}
	]

	# Construir lista de testigos reales cercanos
	scene_witnesses.clear()
	if vm != null and "village_npcs" in vm:
		var candidates: Array = []
		for n in vm.village_npcs:
			if not is_instance_valid(n) or n == corpse_node or n.get("is_dead") == true:
				continue
			if int(n.get("trade_role")) == 22: # CHILD
				continue
			candidates.append(n)
		candidates.sort_custom(func(a, b):
			return a.global_position.distance_squared_to(d_pos) < b.global_position.distance_squared_to(d_pos)
		)
		var count_w: int = mini(2, candidates.size())
		for wi in range(count_w):
			var w_npc = candidates[wi]
			var w_name: String = str(w_npc.get("npc_name"))
			var w_role: String = str(w_npc.get("npc_role"))
			var aff: int = int(w_npc.get("affinity"))
			var pride_val: float = 0.0
			var aggr_val: float = 0.0
			if "TraitCatalog" in vm:
				pride_val = float(vm.TraitCatalog.npc_tendency(w_npc, "pride"))
				aggr_val = float(vm.TraitCatalog.npc_tendency(w_npc, "aggression"))
			var can_press: bool = (aff >= 15) or ((pride_val + aggr_val) < 0.42 and aff >= -5)
			var is_tampered_w: bool = (str(tampered_wit.get("witness_name", "")) == w_name)

			var ask_str: String = "«Pasé cerca hace un rato y vi movimiento extraño junto a %s, pero estaba oscuro.»" % v_name
			var press_ok: String = "«Está bien, lo diré: vi a alguien merodeando a %s poco antes y escapando hacia los callejones.»" % v_name
			if is_tampered_w:
				ask_str = "«Yo… no vi nada, déjeme tranquilo, no quiero problemas con nadie.»"
				press_ok = "«¡Me amenazaron para que callara! Vi cómo discutían con %s antes del crimen.»" % v_name

			scene_witnesses.append({
				"name": "%s (%s)" % [w_name, w_role if w_role != "" else "Vecino"],
				"npc_ref": w_npc,
				"raw_name": w_name,
				"ask_text": ask_str,
				"press_ok_text": press_ok,
				"press_bad_text": "«¡Ya te he dicho lo que sé! No me presiones más.»",
				"can_press_succeed": can_press,
				"log": []
			})


func crime_find_clue(idx: int) -> bool:
	if idx < 0 or idx >= scene_clues.size():
		return false
	var c: Dictionary = scene_clues[idx]
	var cpos := Vector2(float(c.get("x", 260.0)), float(c.get("y", 280.0)))
	var lpos := crime_scene_canvas.lantern_base_pos if crime_scene_canvas != null else Vector2(260.0, 280.0)
	if lpos.distance_to(cpos) > 82.0:
		return false
	if scene_clues_found.get(idx) != true:
		scene_clues_found[idx] = true
		_advance_investigation_minutes(int(c.get("m", 5)))
		findings_count += 1
		_apply_real_forensics_on_scene_clue(c)
	if crime_scene_canvas != null:
		crime_scene_canvas.queue_redraw()
	_update_header_meta()
	_render_scene_view()
	return true


func _apply_real_forensics_on_scene_clue(c: Dictionary) -> void:
	if current_corpse == null or not is_instance_valid(current_corpse) or current_corpse.has_meta("scripted_case_zones"):
		return
	var f_act: String = str(c.get("forensic_action", ""))
	if f_act == "":
		return
	var vm = get_tree().get_first_node_in_group("village_manager") if is_inside_tree() else null
	if vm == null or not ("VillageForensics" in vm):
		return
	var v_name: String = str(current_corpse.get("npc_name"))
	var st: Dictionary = vm.VillageForensics.state(vm)
	if f_act == "track_drag" and (st.get("moved", {}) as Dictionary).has(v_name):
		st["moved"][v_name]["tracked"] = true
	elif f_act == "debunk_planted" and (st.get("planted", {}) as Dictionary).has(v_name):
		st["planted"][v_name]["debunked"] = true


func ask_scene_witness(w_idx: int) -> void:
	if w_idx < 0 or w_idx >= scene_witnesses.size():
		return
	var w: Dictionary = scene_witnesses[w_idx]
	var log_arr: Array = w.get("log", [])
	if not log_arr.is_empty():
		return
	log_arr.append([str(w.get("ask_text", "")), ""])
	w["log"] = log_arr
	_advance_investigation_minutes(10)
	_render_scene_view()


func press_scene_witness(w_idx: int) -> void:
	if w_idx < 0 or w_idx >= scene_witnesses.size():
		return
	var w: Dictionary = scene_witnesses[w_idx]
	var log_arr: Array = w.get("log", [])
	if log_arr.size() != 1:
		return
	var npc_ref = w.get("npc_ref", null)
	var ok: bool = (w.get("can_press_succeed") == true)
	if npc_ref != null and is_instance_valid(npc_ref):
		var aff: int = int(npc_ref.get("affinity"))
		var vm = get_tree().get_first_node_in_group("village_manager") if is_inside_tree() else null
		var pride_v: float = float(vm.TraitCatalog.npc_tendency(npc_ref, "pride")) if (vm != null and "TraitCatalog" in vm) else 0.0
		var aggr_v: float = float(vm.TraitCatalog.npc_tendency(npc_ref, "aggression")) if (vm != null and "TraitCatalog" in vm) else 0.0
		ok = (aff >= 15) or ((pride_v + aggr_v) < 0.42 and aff >= -5)
		if not ok and npc_ref.has_method("modify_affinity"):
			npc_ref.call("modify_affinity", -4)
		elif ok and is_instance_valid(current_corpse) and vm != null and "VillageForensics" in vm:
			var st: Dictionary = vm.VillageForensics.state(vm)
			var vn: String = str(current_corpse.get("npc_name"))
			if (st.get("tampered", {}) as Dictionary).has(vn):
				var tm: Dictionary = st["tampered"][vn]
				if str(tm.get("witness_name", "")) == str(w.get("raw_name", "")):
					tm["reassured"] = true

	if ok:
		log_arr.append([str(w.get("press_ok_text", "")), "ok"])
		findings_count += 1
	else:
		log_arr.append([str(w.get("press_bad_text", "")), "bad"])
	w["log"] = log_arr
	_advance_investigation_minutes(10)
	_update_header_meta()
	_render_scene_view()


func _render_scene_view() -> void:
	if scene_finds_vbox == null or scene_witnesses_vbox == null:
		return
	if scene_clues.is_empty():
		_build_scene_data_for_corpse(current_corpse)

	for c in scene_finds_vbox.get_children():
		c.queue_free()
	for c in scene_witnesses_vbox.get_children():
		c.queue_free()

	# 1. Pistas encontradas bajo el farol
	if scene_clues_found.is_empty():
		var empty_l := Label.new()
		empty_l.text = "Aún no has encontrado nada."
		empty_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_l.add_theme_font_size_override("font_size", 13)
		empty_l.add_theme_color_override("font_color", Color("#7b6f5a"))
		scene_finds_vbox.add_child(empty_l)
	else:
		for idx in range(scene_clues.size()):
			if scene_clues_found.get(idx) != true:
				continue
			var cl: Dictionary = scene_clues[idx]
			var key_c: String = "c_%d" % idx
			var card := PanelContainer.new()
			var st_c := _style_box(Color("#f3ecdc"), COL_PAPER_EDGE, 1, 0, 10, 8)
			st_c.border_width_left = 3
			st_c.border_color = COL_LAMP
			card.add_theme_stylebox_override("panel", st_c)
			scene_finds_vbox.add_child(card)

			var vb := VBoxContainer.new()
			vb.add_theme_constant_override("separation", 4)
			card.add_child(vb)

			var kl := Label.new()
			kl.text = str(cl.get("k", "Pista")).to_upper()
			kl.add_theme_font_size_override("font_size", 11)
			kl.add_theme_color_override("font_color", Color("#7b6f5a"))
			vb.add_child(kl)

			var tl := Label.new()
			tl.text = str(cl.get("t", ""))
			tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			tl.add_theme_font_size_override("font_size", 13)
			tl.add_theme_color_override("font_color", COL_PAPER_INK)
			vb.add_child(tl)

			var already_n: bool = _has_note_with_key(key_c)
			var nbtn := Button.new()
			nbtn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			nbtn.focus_mode = Control.FOCUS_NONE
			nbtn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			nbtn.text = "✓ En el cuaderno" if already_n else "📌 Anotar en el cuaderno"
			nbtn.disabled = already_n
			nbtn.add_theme_font_size_override("font_size", 11)
			nbtn.add_theme_color_override("font_color", COL_GREEN_OK if already_n else Color("#f3ecdc"))
			nbtn.add_theme_color_override("font_disabled_color", COL_GREEN_OK)
			var bg_n := Color("#dfd4bc") if already_n else COL_PAPER_INK
			nbtn.add_theme_stylebox_override("normal", _style_box(bg_n, COL_PAPER_INK, 1, 0, 9, 4))
			nbtn.add_theme_stylebox_override("disabled", _style_box(Color("#dfd4bc"), COL_GREEN_OK, 1, 0, 9, 4))
			var cap_k: String = str(cl.get("k", "Escena"))
			var cap_t: String = str(cl.get("t", ""))
			var cap_key: String = key_c
			nbtn.pressed.connect(func():
				add_notebook_note("Escena · " + cap_k, cap_t, "Escena: " + cap_k, cap_key)
				_render_scene_view()
			)
			vb.add_child(nbtn)

	# 2. Testigos cercanos (Preguntar / Presionar)
	for wi in range(scene_witnesses.size()):
		var w: Dictionary = scene_witnesses[wi]
		var w_box := VBoxContainer.new()
		w_box.add_theme_constant_override("separation", 5)
		scene_witnesses_vbox.add_child(w_box)

		var w_lbl := Label.new()
		w_lbl.text = str(w.get("name", "Testigo"))
		w_lbl.add_theme_font_size_override("font_size", 13)
		w_lbl.add_theme_color_override("font_color", COL_PAPER_INK)
		w_box.add_child(w_lbl)

		var log_arr: Array = w.get("log", [])
		for l_entry in log_arr:
			var ql := Label.new()
			ql.text = str(l_entry[0])
			ql.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ql.add_theme_font_size_override("font_size", 13)
			var is_bad: bool = (str(l_entry[1]) == "bad")
			ql.add_theme_color_override("font_color", Color("#8a2f2a") if is_bad else COL_PAPER_INK)
			w_box.add_child(ql)

		var acts_hb := HFlowContainer.new()
		acts_hb.add_theme_constant_override("h_separation", 6)
		acts_hb.add_theme_constant_override("v_separation", 6)
		w_box.add_child(acts_hb)

		var st_len: int = log_arr.size()
		var cap_wi: int = wi
		if st_len == 0:
			var ask_b := Button.new()
			ask_b.text = "Preguntar  [10 min]"
			ask_b.focus_mode = Control.FOCUS_NONE
			ask_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			ask_b.add_theme_font_size_override("font_size", 12)
			ask_b.add_theme_color_override("font_color", COL_PAPER)
			ask_b.add_theme_stylebox_override("normal", _style_box(COL_PAPER_INK, COL_PAPER_INK, 1, 0, 10, 5))
			ask_b.pressed.connect(func(): ask_scene_witness(cap_wi))
			acts_hb.add_child(ask_b)
		elif st_len == 1:
			var press_b := Button.new()
			press_b.text = "Presionar  [puede cerrarse]"
			press_b.focus_mode = Control.FOCUS_NONE
			press_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			press_b.add_theme_font_size_override("font_size", 12)
			press_b.add_theme_color_override("font_color", COL_PAPER)
			press_b.add_theme_stylebox_override("normal", _style_box(COL_PAPER_INK, COL_PAPER_INK, 1, 0, 10, 5))
			press_b.pressed.connect(func(): press_scene_witness(cap_wi))
			acts_hb.add_child(press_b)

			var key_w1: String = "w_%d" % wi
			var pinned_w1: bool = _has_note_with_key(key_w1)
			var nb1 := Button.new()
			nb1.text = "✓ En el cuaderno" if pinned_w1 else "📌 Anotar"
			nb1.disabled = pinned_w1
			nb1.focus_mode = Control.FOCUS_NONE
			nb1.add_theme_font_size_override("font_size", 11)
			nb1.add_theme_color_override("font_color", COL_GREEN_OK if pinned_w1 else COL_PAPER_INK)
			nb1.add_theme_stylebox_override("normal", _style_box(Color(0, 0, 0, 0), COL_PAPER_INK, 1, 0, 9, 4))
			var cap_wn1: String = str(w.get("name", "Testigo"))
			var cap_wt1: String = str(w.get("ask_text", ""))
			nb1.pressed.connect(func():
				add_notebook_note("Testigo · " + cap_wn1, cap_wt1, "Testigo: " + cap_wn1, key_w1)
				_render_scene_view()
			)
			acts_hb.add_child(nb1)
		elif st_len >= 2 and str(log_arr[1][1]) != "bad":
			var key_w2: String = "w2_%d" % wi
			var pinned_w2: bool = _has_note_with_key(key_w2)
			var nb2 := Button.new()
			nb2.text = "✓ En el cuaderno" if pinned_w2 else "📌 Anotar confesión"
			nb2.disabled = pinned_w2
			nb2.focus_mode = Control.FOCUS_NONE
			nb2.add_theme_font_size_override("font_size", 11)
			nb2.add_theme_color_override("font_color", COL_GREEN_OK if pinned_w2 else COL_PAPER_INK)
			nb2.add_theme_stylebox_override("normal", _style_box(Color(0, 0, 0, 0), COL_PAPER_INK, 1, 0, 9, 4))
			var cap_wn2: String = str(w.get("name", "Testigo"))
			var cap_wt2: String = str(log_arr[1][0])
			nb2.pressed.connect(func():
				add_notebook_note("Testigo · " + cap_wn2, cap_wt2, "Testigo: " + cap_wn2, key_w2)
				_render_scene_view()
			)
			acts_hb.add_child(nb2)


# ==============================================================================
# Bloque D4 — Cuaderno y tablero del caso (sospechosos, fichas, hilos rojos y persistencia)
# ==============================================================================
func _build_board_suspects_for_corpse(corpse_node: Node2D) -> void:
	var is_scripted: bool = (corpse_node == null or not is_instance_valid(corpse_node) or corpse_node.has_meta("scripted_case_zones") or corpse_node.has_meta("scripted_case_id"))
	var sc_id: String = str(corpse_node.get_meta("scripted_case_id", DetectiveCaseDataScript.CASE_01_ID)) if (corpse_node != null and is_instance_valid(corpse_node)) else DetectiveCaseDataScript.CASE_01_ID
	var default_suspects: Array[Dictionary] = DetectiveCaseDataScript.get_board_suspects(sc_id)
	if is_scripted:
		board_suspects = default_suspects
		return

	board_suspects.clear()
	var vm = get_tree().get_first_node_in_group("village_manager") if is_inside_tree() else null
	if vm != null and "active_sheriff_investigation" in vm:
		var inv: Dictionary = vm.active_sheriff_investigation
		if inv.get("active") == true and inv.get("suspects") is Dictionary:
			var susp_dict: Dictionary = inv["suspects"]
			var sorted_names: Array = susp_dict.keys()
			sorted_names.sort_custom(func(a, b):
				return int(susp_dict[a].get("score", 0)) > int(susp_dict[b].get("score", 0))
			)
			for i in range(mini(4, sorted_names.size())):
				var s_name: String = str(sorted_names[i])
				var s_info: Dictionary = susp_dict[s_name]
				var motive_txt: String = str(s_info.get("motive", "Visto cerca del lugar del crimen"))
				var alibi_txt: String = str(s_info.get("alibi", ""))
				var full_txt: String = "%s — %s%s" % [s_name, motive_txt, (" (" + alibi_txt + ")") if alibi_txt != "" else ""]
				board_suspects.append({
					"id": "s_real_%d" % i,
					"k": "Sospechoso",
					"t": full_txt
				})
	if board_suspects.is_empty():
		var v_name: String = str(corpse_node.get("npc_name"))
		var v_role: String = str(corpse_node.get("npc_role"))
		var wc: String = str(corpse_node.get("last_hit_weapon_name"))
		var dpos: Vector2 = corpse_node.global_position
		var raw_dp = corpse_node.get("death_world_pos")
		if raw_dp is Vector2 and (raw_dp as Vector2) != Vector2.ZERO:
			dpos = raw_dp
		board_suspects.append({
			"id": "s_victim",
			"k": "Víctima",
			"t": "%s (%s) — Hallad%s en %s. Causa preliminar: %s." % [v_name, v_role if v_role != "" else "Vecino", "a" if is_female_model else "o", _describe_world_site(dpos), wc if wc != "" else "por determinar"]
		})
		for wi in range(mini(3, scene_witnesses.size())):
			var w: Dictionary = scene_witnesses[wi]
			board_suspects.append({
				"id": "s_wit_%d" % wi,
				"k": "Vecino cercano",
				"t": "%s — Estaba por las inmediaciones cuando se halló el cuerpo." % str(w.get("name", "Vecino"))
			})


func get_board_items() -> Array[Dictionary]:
	if board_suspects.is_empty():
		_build_board_suspects_for_corpse(current_corpse)
	var items: Array[Dictionary] = []
	for s in board_suspects:
		items.append({
			"id": str(s.get("id", "")),
			"k": str(s.get("k", "Sospechoso")),
			"t": str(s.get("t", "")),
			"suspect": true
		})
	for i in range(notebook_notes.size()):
		var n: Dictionary = notebook_notes[i]
		var pid: String = str(n.get("id", n.get("source_key", "n_%d" % i)))
		if pid == "":
			pid = "n_%d" % i
		items.append({
			"id": pid,
			"k": str(n.get("title", "Pista")),
			"t": str(n.get("text", "")),
			"suspect": false
		})
	return items


func _ensure_board_positions(items: Array[Dictionary]) -> void:
	for idx in range(items.size()):
		var it: Dictionary = items[idx]
		var pid: String = str(it.get("id", ""))
		if not board_positions.has(pid):
			var col: int = idx % 4
			var row: int = int(idx / 4)
			var stagger_y: float = 16.0 if (col % 2 == 1) else 0.0
			board_positions[pid] = Vector2(26.0 + float(col) * 195.0, 22.0 + float(row) * 150.0 + stagger_y)


func _render_board_view() -> void:
	if corkboard_canvas == null:
		return
	var items := get_board_items()
	_ensure_board_positions(items)

	for child in corkboard_canvas.get_children():
		if child != corkboard_canvas.strings_overlay and child != corkboard_canvas.pins_overlay:
			child.queue_free()
	corkboard_canvas.card_nodes.clear()

	for it in items:
		var pid: String = str(it.get("id", ""))
		var is_susp: bool = (it.get("suspect") == true)
		var is_linked_sel: bool = (board_link_from == pid)
		var pos: Vector2 = board_positions.get(pid, Vector2(26, 26))

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(168, 72)
		card.position = pos
		card.z_index = 4
		card.mouse_default_cursor_shape = Control.CURSOR_MOVE

		var bg_col := Color("#f5e3df") if is_susp else COL_PAPER
		var border_col := COL_RED_PIN if is_linked_sel else COL_PAPER_INK
		var border_w := 2 if is_linked_sel else 1
		var st := _style_box(bg_col, border_col, border_w, 0, 10, 11)
		st.shadow_color = Color(0, 0, 0, 0.35)
		st.shadow_size = 5
		st.shadow_offset = Vector2(0, 3)
		card.add_theme_stylebox_override("panel", st)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 4)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(vb)

		var top_hb := HBoxContainer.new()
		top_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(top_hb)

		var kl := Label.new()
		kl.text = str(it.get("k", "Pista")).to_upper()
		kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		kl.add_theme_font_size_override("font_size", 10)
		kl.add_theme_color_override("font_color", Color("#7a1f1b") if is_susp else Color("#7b6f5a"))
		kl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_hb.add_child(kl)

		var tl := Label.new()
		tl.text = str(it.get("t", ""))
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tl.custom_minimum_size = Vector2(146, 0)
		tl.add_theme_font_size_override("font_size", 12)
		tl.add_theme_color_override("font_color", COL_PAPER_INK)
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(tl)

		var cap_id: String = pid
		card.gui_input.connect(func(ev: InputEvent):
			corkboard_canvas.on_card_gui_input(ev, cap_id)
		)
		corkboard_canvas.add_child(card)
		corkboard_canvas.card_nodes[pid] = card

	# Los hilos rojos van por detrás de las tarjetas (z_index = 1) y las cabezas de chincheta arriba al centro (z_index = 10)
	if corkboard_canvas.strings_overlay != null:
		corkboard_canvas.move_child(corkboard_canvas.strings_overlay, 0)
	if corkboard_canvas.pins_overlay != null:
		corkboard_canvas.move_child(corkboard_canvas.pins_overlay, -1)
	corkboard_canvas.redraw_links()


func click_board_pin(pin_id: String) -> void:
	if board_link_from == "":
		board_link_from = pin_id
	elif board_link_from == pin_id:
		board_link_from = ""
	else:
		var id_a := board_link_from
		var id_b := pin_id
		var exists := false
		for i in range(board_links.size() - 1, -1, -1):
			var l = board_links[i]
			if l is Array and l.size() >= 2:
				if (str(l[0]) == id_a and str(l[1]) == id_b) or (str(l[0]) == id_b and str(l[1]) == id_a):
					board_links.remove_at(i)
					exists = true
		if not exists:
			board_links.append([id_a, id_b])
		board_link_from = ""
		save_detective_state()
	_render_board_view()


func move_board_pin(pin_id: String, new_pos: Vector2) -> void:
	var max_x := 640.0
	var max_y := 440.0
	if corkboard_canvas != null and corkboard_canvas.size.x > 180.0:
		max_x = corkboard_canvas.size.x - 172.0
		max_y = corkboard_canvas.size.y - 78.0
	var clamped := Vector2(clampf(new_pos.x, 8.0, maxf(8.0, max_x)), clampf(new_pos.y, 8.0, maxf(8.0, max_y)))
	board_positions[pin_id] = clamped
	if corkboard_canvas != null and corkboard_canvas.card_nodes.has(pin_id):
		var c_node: Control = corkboard_canvas.card_nodes[pin_id]
		if is_instance_valid(c_node):
			c_node.position = clamped
		corkboard_canvas.redraw_links()


func remove_board_link_at(link_idx: int) -> void:
	if link_idx < 0 or link_idx >= board_links.size():
		return
	board_links.remove_at(link_idx)
	save_detective_state()
	if corkboard_canvas != null:
		corkboard_canvas.redraw_links()


func remove_board_link(id_a: String, id_b: String) -> void:
	for i in range(board_links.size() - 1, -1, -1):
		var l = board_links[i]
		if l is Array and l.size() >= 2:
			if (str(l[0]) == id_a and str(l[1]) == id_b) or (str(l[0]) == id_b and str(l[1]) == id_a):
				board_links.remove_at(i)
	save_detective_state()
	if corkboard_canvas != null:
		corkboard_canvas.redraw_links()


func clear_all_board_links() -> void:
	board_links.clear()
	board_link_from = ""
	save_detective_state()
	_render_board_view()


func save_detective_state() -> void:
	var vm = get_tree().get_first_node_in_group("village_manager") if is_inside_tree() else null
	if vm == null or not ("VillageForensics" in vm):
		return
	var st: Dictionary = vm.VillageForensics.state(vm)
	var pos_serialized: Dictionary = {}
	for k in board_positions.keys():
		var v: Vector2 = board_positions[k]
		pos_serialized[str(k)] = [v.x, v.y]
	st["detective_board"] = {
		"notes": notebook_notes.duplicate(true),
		"positions": pos_serialized,
		"links": board_links.duplicate(true),
		"elapsed_minutes": elapsed_minutes,
		"findings_count": findings_count
	}


func load_detective_state() -> void:
	var vm = get_tree().get_first_node_in_group("village_manager") if is_inside_tree() else null
	if vm == null or not ("VillageForensics" in vm):
		return
	var st: Dictionary = vm.VillageForensics.state(vm)
	var db = st.get("detective_board", {})
	if not (db is Dictionary) or (db as Dictionary).is_empty():
		return
	var saved_notes = db.get("notes", [])
	if saved_notes is Array and not (saved_notes as Array).is_empty():
		notebook_notes.clear()
		for n in saved_notes:
			if n is Dictionary:
				notebook_notes.append((n as Dictionary).duplicate(true))
	var saved_pos = db.get("positions", {})
	if saved_pos is Dictionary:
		for k in (saved_pos as Dictionary).keys():
			var arr = saved_pos[k]
			if arr is Array and (arr as Array).size() >= 2:
				board_positions[str(k)] = Vector2(float(arr[0]), float(arr[1]))
			elif arr is Vector2:
				board_positions[str(k)] = arr
	var saved_links = db.get("links", [])
	if saved_links is Array:
		board_links = (saved_links as Array).duplicate(true)
	if db.has("elapsed_minutes"):
		elapsed_minutes = int(db.get("elapsed_minutes", elapsed_minutes))
	if db.has("findings_count"):
		findings_count = int(db.get("findings_count", findings_count))



