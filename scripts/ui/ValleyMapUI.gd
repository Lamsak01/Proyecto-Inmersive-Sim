extends Control
class_name ValleyMapUI

## Mapa Cartográfico Interactivo del Valle ([M]) + Minimapa en Vivo en la Esquina Superior Derecha
## Muestra en tiempo real las 4 grandes regiones (Llanura Salvaje/Ciénaga, Granja/Lago, Aldea de 10 Edificios
## y Bosque Profundo con 3 Hábitats), caminos, posición del jugador, aldeanos en vivo (incluyendo expediciones)
## y fauna activa.

var player: Node2D = null
var is_full_map_open: bool = false

var minimap_panel: PanelContainer = null
var minimap_canvas: Control = null

var full_map_panel: PanelContainer = null
var full_map_canvas: Control = null
var hover_info_label: Label = null
var census_label: Label = null

var _pulse_phase: float = 0.0
var _label_hits: Array[Dictionary] = [] # rectángulos del mapa grande con su nombre completo (para el cursor)
var _minimap_redraw_timer: float = 0.0
var _fullmap_redraw_timer: float = 0.0

const WORLD_RECT := Rect2(Vector2(-2150.0, -900.0), Vector2(3900.0, 3350.0)) # Paso 2: abarca Llanura/Ciénaga separadas al oeste y Bosque Profundo ampliado al sur
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const VillageRestaurant = preload("res://scripts/systems/VillageRestaurant.gd")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_minimap_ui()
	_build_full_map_ui()

func _process(delta: float) -> void:
	_pulse_phase += delta * 4.5
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	if minimap_canvas and minimap_panel and minimap_panel.visible:
		_minimap_redraw_timer -= delta
		if _minimap_redraw_timer <= 0.0:
			_minimap_redraw_timer = 0.18
			minimap_canvas.queue_redraw()
	if full_map_canvas and full_map_panel and full_map_panel.visible:
		_fullmap_redraw_timer -= delta
		if _fullmap_redraw_timer <= 0.0:
			_fullmap_redraw_timer = 0.08
			full_map_canvas.queue_redraw()
			_update_census_and_hover()

func toggle_full_map() -> void:
	is_full_map_open = not is_full_map_open
	if full_map_panel:
		full_map_panel.visible = is_full_map_open
	if is_full_map_open:
		_fit_full_map()
	if is_full_map_open and full_map_canvas:
		full_map_canvas.queue_redraw()
		_update_census_and_hover()

## El mapa grande ocupa casi toda la pantalla (antes, 900×550 fijos: los nombres se pisaban).
func _fit_full_map() -> void:
	if full_map_panel == null:
		return
	var half: Vector2 = get_viewport_rect().size * Vector2(0.47, 0.45)
	half = Vector2(maxf(half.x, 450.0), maxf(half.y, 275.0))
	full_map_panel.offset_left = -half.x
	full_map_panel.offset_right = half.x
	full_map_panel.offset_top = -half.y
	full_map_panel.offset_bottom = half.y

func close_full_map() -> void:
	is_full_map_open = false
	if full_map_panel:
		full_map_panel.visible = false

func _make_map_style(bg: Color, border: Color, radius: int, mx: int, my: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.content_margin_left = mx
	s.content_margin_right = mx
	s.content_margin_top = my
	s.content_margin_bottom = my
	return s

func _make_map_lbl(txt: String, f_sz: int, col: Color, expand_h: bool = false) -> Label:
	var l := Label.new()
	l.text = txt
	if expand_h:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", f_sz)
	l.add_theme_color_override("font_color", col)
	return l

func _can_open_full_map() -> bool:
	return is_full_map_open or not (is_instance_valid(player) and player.has_method("is_any_ui_modal_open") and bool(player.call("is_any_ui_modal_open")))

func _build_minimap_ui() -> void:
	minimap_panel = PanelContainer.new()
	minimap_panel.name = "MinimapPanel"
	minimap_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	minimap_panel.offset_left = -138.0
	minimap_panel.offset_top = 14.0
	minimap_panel.offset_right = -16.0
	minimap_panel.offset_bottom = 160.0
	var empty_sb := StyleBoxEmpty.new()
	minimap_panel.add_theme_stylebox_override("panel", empty_sb)
	add_child(minimap_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	minimap_panel.add_child(vbox)

	var circle_holder := CenterContainer.new()
	vbox.add_child(circle_holder)

	minimap_canvas = Control.new()
	minimap_canvas.custom_minimum_size = Vector2(118, 118)
	minimap_canvas.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and _can_open_full_map():
			toggle_full_map()
	)
	minimap_canvas.draw.connect(func(): _draw_round_paper_minimap(minimap_canvas))
	circle_holder.add_child(minimap_canvas)

	var tag_holder := HBoxContainer.new()
	tag_holder.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(tag_holder)

	var header_btn := Button.new()
	header_btn.text = "Valle · [M] mapa"
	header_btn.focus_mode = Control.FOCUS_NONE
	header_btn.add_theme_font_size_override("font_size", 11)
	header_btn.add_theme_color_override("font_color", Color(0.149, 0.129, 0.106, 1.0))
	header_btn.add_theme_color_override("font_hover_color", Color(0.561, 0.176, 0.149, 1.0))
	var tag_sb := StyleBoxFlat.new()
	tag_sb.bg_color = Color(0.945, 0.910, 0.831, 0.94)
	tag_sb.border_color = Color(0.227, 0.196, 0.157, 1.0)
	tag_sb.set_border_width_all(1)
	tag_sb.set_corner_radius_all(2)
	tag_sb.content_margin_left = 7
	tag_sb.content_margin_right = 7
	tag_sb.content_margin_top = 2
	tag_sb.content_margin_bottom = 2
	tag_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	tag_sb.shadow_size = 1
	tag_sb.shadow_offset = Vector2(2, 2)
	header_btn.add_theme_stylebox_override("normal", tag_sb)
	header_btn.add_theme_stylebox_override("hover", tag_sb)
	header_btn.add_theme_stylebox_override("pressed", tag_sb)
	header_btn.pressed.connect(func():
		if _can_open_full_map():
			toggle_full_map()
	)
	tag_holder.add_child(header_btn)

func _clip_rect_to_circle(r: Rect2, center: Vector2, max_rad: float) -> Rect2:
	var min_x: float = maxf(r.position.x, center.x - max_rad)
	var min_y: float = maxf(r.position.y, center.y - max_rad)
	var max_x: float = minf(r.end.x, center.x + max_rad)
	var max_y: float = minf(r.end.y, center.y + max_rad)
	if max_x <= min_x or max_y <= min_y:
		return Rect2()
	var clipped := Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	if clipped.get_center().distance_to(center) > max_rad - 2.0:
		return Rect2()
	return clipped

func _draw_round_paper_minimap(canvas: Control) -> void:
	var csize: Vector2 = canvas.size
	if csize.x <= 8.0 or csize.y <= 8.0:
		return
	var center: Vector2 = csize * 0.5
	var rad: float = minf(csize.x, csize.y) * 0.5 - 2.0
	var p_world: Vector2 = player.global_position if is_instance_valid(player) else Vector2(450.0, 40.0)
	var scale_px: float = rad / 540.0 # ~540 px de radio del mundo alrededor del jugador

	# Sombra dura estilo papel + fondo pergamino redondo
	canvas.draw_circle(center + Vector2(3.0, 3.0), rad, Color(0.0, 0.0, 0.0, 0.45))
	canvas.draw_circle(center, rad, Color(0.875, 0.820, 0.698, 1.0)) # #dfd1b2

	var to_mini := func(wpos: Vector2) -> Vector2:
		return center + (wpos - p_world) * scale_px

	# Agua (lago y ciénaga)
	for w_rect in [Rect2(Vector2(-1078, 78), Vector2(412, 162)), Rect2(Vector2(-2020, 110), Vector2(920, 450))]:
		var mr := Rect2(to_mini.call(w_rect.position), w_rect.size * scale_px)
		var cr := _clip_rect_to_circle(mr, center, rad - 3.0)
		if cr.size.x > 0.5:
			canvas.draw_rect(cr, Color(0.498, 0.639, 0.678, 0.90), true)

	# Caminos y plaza en tono pergamino tostado (#b9a882)
	var road_col := Color(0.725, 0.659, 0.510, 0.95)
	for r_rect in [
		Rect2(Vector2(-1950, 36), Vector2(2960, 28)),
		Rect2(Vector2(-688, -88), Vector2(18, 124)),
		Rect2(Vector2(448, -135), Vector2(34, 920)),
		Rect2(Vector2(140, 130), Vector2(24, 248)),
		Rect2(Vector2(140, 356), Vector2(312, 22)),
		Rect2(Vector2(660, -135), Vector2(280, 24)),
		Rect2(Vector2(660, -135), Vector2(24, 185)),
		Rect2(Vector2(395, 10), Vector2(140, 78))
	] + VillageLots.ROADS:
		var mr2 := Rect2(to_mini.call(r_rect.position), r_rect.size * scale_px)
		var cr2 := _clip_rect_to_circle(mr2, center, rad - 3.0)
		if cr2.size.x > 0.5:
			canvas.draw_rect(cr2, road_col, true)

	# Edificios (#8a7356 con borde de tinta #3a3228)
	var b_rects: Array[Rect2] = [
		VillageRestaurant.RECT,
		Rect2(Vector2(260, -316), Vector2(348, 184)),
		Rect2(Vector2(277, -74), Vector2(116, 76)),
		Rect2(Vector2(527, -74), Vector2(116, 76)),
		Rect2(Vector2(527, 110), Vector2(116, 76)),
		Rect2(Vector2(407, 110), Vector2(116, 76)),
		Rect2(Vector2(261, 107), Vector2(128, 96)),
		Rect2(Vector2(689, -234), Vector2(112, 78)),
		Rect2(Vector2(849, -234), Vector2(112, 78)),
		Rect2(Vector2(689, -75), Vector2(112, 78)),
		Rect2(Vector2(849, -75), Vector2(112, 78)),
		Rect2(Vector2(676, 100), Vector2(138, 96)),
		Rect2(Vector2(844, 100), Vector2(142, 96)),
		Rect2(Vector2(679, 266), Vector2(132, 92)),
		Rect2(Vector2(822, 260), Vector2(268, 168))
	]
	for br_w in b_rects:
		var mr3 := Rect2(to_mini.call(br_w.position), br_w.size * scale_px)
		var cr3 := _clip_rect_to_circle(mr3, center, rad - 4.0)
		if cr3.size.x > 1.5 and cr3.size.y > 1.5:
			canvas.draw_rect(cr3, Color(0.541, 0.451, 0.337, 0.96), true)
			canvas.draw_rect(cr3, Color(0.227, 0.196, 0.157, 0.95), false, 1.0)

	# Vecinos vivos (#5a5042) y cadáveres (#8f2d26)
	for npc in get_tree().get_nodes_in_group("village_npcs"):
		if npc is VillageNPC and (npc as Node2D).visible and not bool(npc.get("corpse_buried")):
			var np: Vector2 = to_mini.call((npc as Node2D).global_position)
			if np.distance_to(center) <= rad - 5.0:
				var col_n: Color = Color(0.561, 0.176, 0.149, 1.0) if npc.is_dead else Color(0.353, 0.314, 0.259, 0.95)
				canvas.draw_circle(np, 2.3 if npc.is_dead else 2.0, col_n)

	# Punto del jugador en el centro (#26211b con halo papel #f1e8d4)
	canvas.draw_circle(center, 4.2, Color(0.945, 0.910, 0.831, 0.95))
	canvas.draw_circle(center, 2.8, Color(0.149, 0.129, 0.106, 1.0))

	# Borde interior suave y aro de tinta exterior (#3a3228)
	canvas.draw_arc(center, rad - 2.0, 0.0, TAU, 48, Color(0.149, 0.129, 0.106, 0.18), 3.0)
	canvas.draw_arc(center, rad, 0.0, TAU, 48, Color(0.227, 0.196, 0.157, 1.0), 2.5)

	# Marca cardinal "N" arriba al centro
	var font: Font = ThemeDB.fallback_font
	if font:
		var n_rect := Rect2(Vector2(center.x - 6.0, 2.0), Vector2(12.0, 11.0))
		canvas.draw_rect(n_rect, Color(0.945, 0.910, 0.831, 0.96), true)
		canvas.draw_rect(n_rect, Color(0.227, 0.196, 0.157, 0.85), false, 1.0)
		canvas.draw_string(font, Vector2(center.x - 3.5, 11.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.149, 0.129, 0.106, 1.0))

func _build_full_map_ui() -> void:
	full_map_panel = PanelContainer.new()
	full_map_panel.name = "FullValleyMapPanel"
	full_map_panel.visible = false
	full_map_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	full_map_panel.offset_left = -450.0
	full_map_panel.offset_top = -275.0
	full_map_panel.offset_right = 450.0
	full_map_panel.offset_bottom = 275.0
	var panel_sb := _make_map_style(Color(0.945, 0.910, 0.831, 0.98), Color(0.227, 0.196, 0.157, 1.0), 3, 18, 14)
	panel_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	panel_sb.shadow_size = 2
	panel_sb.shadow_offset = Vector2(4, 4)
	full_map_panel.add_theme_stylebox_override("panel", panel_sb)
	add_child(full_map_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	full_map_panel.add_child(vbox)

	var top_bar := HBoxContainer.new()
	vbox.add_child(top_bar)
	top_bar.add_child(_make_map_lbl("Mapa Cartográfico del Valle — Regiones, Aldeanos y Ecosistema", 16, Color(0.149, 0.129, 0.106, 1.0), true))

	var close_btn := Button.new()
	close_btn.text = "[M / Esc] Cerrar"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 12)
	close_btn.add_theme_color_override("font_color", Color(0.149, 0.129, 0.106, 1.0))
	close_btn.add_theme_color_override("font_hover_color", Color(0.561, 0.176, 0.149, 1.0))
	var close_sb := _make_map_style(Color(0.882, 0.831, 0.722, 1.0), Color(0.227, 0.196, 0.157, 1.0), 2, 10, 4)
	close_btn.add_theme_stylebox_override("normal", close_sb)
	close_btn.add_theme_stylebox_override("hover", close_sb)
	close_btn.add_theme_stylebox_override("pressed", close_sb)
	close_btn.pressed.connect(close_full_map)
	top_bar.add_child(close_btn)

	var sep_top := ColorRect.new()
	sep_top.custom_minimum_size = Vector2(0, 1)
	sep_top.color = Color(0.227, 0.196, 0.157, 0.55)
	vbox.add_child(sep_top)

	census_label = _make_map_lbl("", 11, Color(0.353, 0.314, 0.259, 1.0))
	vbox.add_child(census_label)

	full_map_canvas = Control.new()
	full_map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	full_map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	full_map_canvas.clip_contents = true
	full_map_canvas.draw.connect(func(): _draw_valley_cartography(full_map_canvas, true))
	vbox.add_child(full_map_canvas)

	hover_info_label = _make_map_lbl("Pasa el cursor sobre cualquier punto del mapa para inspeccionar vecinos, edificios o hábitats.", 12, Color(0.180, 0.153, 0.122, 1.0))
	vbox.add_child(hover_info_label)

func _world_to_map(world_pos: Vector2, canvas_size: Vector2) -> Vector2:
	var nx: float = (world_pos.x - WORLD_RECT.position.x) / WORLD_RECT.size.x
	var ny: float = (world_pos.y - WORLD_RECT.position.y) / WORLD_RECT.size.y
	return Vector2(nx * canvas_size.x, ny * canvas_size.y)

func _world_rect_to_map(w_rect: Rect2, canvas_size: Vector2) -> Rect2:
	var tl := _world_to_map(w_rect.position, canvas_size)
	var br := _world_to_map(w_rect.end, canvas_size)
	return Rect2(tl, br - tl)

func _draw_ink_tag(canvas: Control, font: Font, pos: Vector2, txt: String, f_sz: int, fg: Color) -> void:
	var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz).x
	var bg_r := Rect2(pos - Vector2(3.0, float(f_sz) - 1.0), Vector2(tw + 6.0, float(f_sz) + 4.0))
	canvas.draw_rect(bg_r, Color(0.945, 0.910, 0.831, 0.86), true)
	canvas.draw_rect(bg_r, Color(0.227, 0.196, 0.157, 0.45), false, 1.0)
	canvas.draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, fg)

func _draw_valley_cartography(canvas: Control, detailed: bool) -> void:
	var csize := canvas.size
	if csize.x <= 4.0 or csize.y <= 4.0:
		return

	# 1. Fondo general de pergamino cartográfico con marco de tinta
	canvas.draw_rect(Rect2(Vector2.ZERO, csize), Color(0.875, 0.820, 0.698, 1.0), true)

	# 2. Bioma Oeste: Llanura Salvaje (Noroeste) y Ciénaga de Ranas (Suroeste), en aguadas de tinta sobre papel
	var plains_r := _world_rect_to_map(Rect2(Vector2(-2060, -560), Vector2(980, 540)), csize)
	canvas.draw_rect(plains_r, Color(0.81, 0.75, 0.58, 0.72), true)
	canvas.draw_rect(plains_r, Color(0.42, 0.35, 0.25, 0.78), false, 1.5)

	var bandit_r := _world_rect_to_map(Rect2(Vector2(-1760, -390), Vector2(470, 230)), csize)
	canvas.draw_rect(bandit_r, Color(0.73, 0.56, 0.48, 0.72), true)
	canvas.draw_rect(bandit_r, Color(0.48, 0.26, 0.22, 0.78), false, 1.0)

	var marsh_r := _world_rect_to_map(Rect2(Vector2(-2020, 110), Vector2(920, 450)), csize)
	canvas.draw_rect(marsh_r, Color(0.58, 0.69, 0.64, 0.82), true)
	canvas.draw_rect(marsh_r, Color(0.30, 0.42, 0.38, 0.85), false, 1.2)

	# 3. Bioma Sur: Bosque Profundo con aguada salvia y borde de tinta
	var forest_pts := PackedVector2Array()
	for fp in EcosystemManager.FOREST_POLY:
		forest_pts.append(_world_to_map(fp, csize))
	if forest_pts.size() >= 3:
		canvas.draw_colored_polygon(forest_pts, Color(0.71, 0.76, 0.60, 0.78))
		var border_pts := PackedVector2Array(forest_pts)
		border_pts.append(forest_pts[0])
		canvas.draw_polyline(border_pts, Color(0.32, 0.39, 0.26, 0.85), 1.5)

	# Sub-hábitat 1: Soto de Conejos (Noroeste del Bosque)
	var rab_r := _world_rect_to_map(Rect2(Vector2(-1050, 800), Vector2(720, 520)), csize)
	canvas.draw_rect(rab_r, Color(0.65, 0.73, 0.55, 0.48), true)
	# Sub-hábitat 2: Claros de Venados (Centro-Sur del Bosque)
	var deer_r := _world_rect_to_map(Rect2(Vector2(-220, 960), Vector2(820, 1180)), csize)
	canvas.draw_rect(deer_r, Color(0.67, 0.74, 0.56, 0.48), true)
	# Sub-hábitat 3: Riscos y Zorros (Este del Bosque)
	var fox_r := _world_rect_to_map(Rect2(Vector2(700, 820), Vector2(760, 920)), csize)
	canvas.draw_rect(fox_r, Color(0.72, 0.66, 0.55, 0.52), true)
	# Sub-hábitat 4: Robledal de Jabalíes (Suroeste del Bosque)
	var boar_r := _world_rect_to_map(Rect2(Vector2(-1060, 1380), Vector2(760, 740)), csize)
	canvas.draw_rect(boar_r, Color(0.68, 0.63, 0.52, 0.48), true)

	# 4. Red de Caminos y Plaza Central en tono pergamino tostado (#b9a882)
	var road_col := Color(0.725, 0.659, 0.510, 0.96)
	for r_rect in [
		Rect2(Vector2(-1950, 36), Vector2(2960, 28)),
		Rect2(Vector2(-688, -88), Vector2(18, 124)),
		Rect2(Vector2(-688, 64), Vector2(18, 36)),
		Rect2(Vector2(448, -135), Vector2(34, 920)),
		Rect2(Vector2(140, 130), Vector2(24, 248)),
		Rect2(Vector2(140, 356), Vector2(312, 22)),
		Rect2(Vector2(-380, 760), Vector2(1040, 24)),
		Rect2(Vector2(130, 780), Vector2(26, 260)),
		Rect2(Vector2(660, -135), Vector2(280, 24)),
		Rect2(Vector2(660, -135), Vector2(24, 185))
	] + VillageLots.ROADS:
		canvas.draw_rect(_world_rect_to_map(r_rect, csize), road_col, true)
	for cr in VillageLots.CURVED_ROADS: # Bloque AB: callejas curvas del norte
		var cpts := PackedVector2Array()
		for p in VillageLots.curved_road_points(cr):
			cpts.append(_world_rect_to_map(Rect2(p, Vector2.ZERO), csize).position)
		var cw: float = _world_rect_to_map(Rect2(Vector2.ZERO, Vector2(float(cr["w"]), float(cr["w"]))), csize).size.x
		canvas.draw_polyline(cpts, road_col, maxf(1.0, cw))

	var plaza_r := _world_rect_to_map(Rect2(Vector2(395, 10), Vector2(140, 78)), csize)
	canvas.draw_rect(plaza_r, Color(0.67, 0.62, 0.52, 0.95), true)
	canvas.draw_rect(plaza_r, Color(0.227, 0.196, 0.157, 0.70), false, 1.0)

	# 5. Lago del Oeste, Río de Norte a Sur, Puente Viejo, Campamento del Jugador y Gallinero/Huerto
	var lake_r := _world_rect_to_map(Rect2(Vector2(-1082, 76), Vector2(418, 166)), csize)
	canvas.draw_rect(lake_r, Color(0.498, 0.639, 0.678, 0.94), true)
	canvas.draw_rect(lake_r, Color(0.24, 0.35, 0.39, 0.90), false, 1.2)

	var riv_pts := PackedVector2Array()
	for wp in FishingSpot.river_waypoints():
		riv_pts.append(_world_to_map(wp, csize))
	if riv_pts.size() >= 2:
		canvas.draw_polyline(riv_pts, Color(0.32, 0.54, 0.68, 0.92), 4.0)
	var ob_map_r := _world_rect_to_map(Rect2(Vector2(82, 32), Vector2(88, 36)), csize)
	canvas.draw_rect(ob_map_r, Color(0.56, 0.44, 0.30, 0.96), true)

	var camp_r := _world_rect_to_map(Rect2(Vector2(-782, -124), Vector2(88, 46)), csize)
	canvas.draw_rect(camp_r, Color(0.66, 0.54, 0.36, 0.90), true)
	canvas.draw_rect(camp_r, Color(0.227, 0.196, 0.157, 0.85), false, 1.0)

	var coop_node := get_tree().get_first_node_in_group("chicken_coop") as Node2D
	if coop_node != null and coop_node.visible:
		var coop_r := _world_rect_to_map(Rect2(Vector2(-886, -51), Vector2(76, 60)), csize)
		canvas.draw_rect(coop_r, Color(0.62, 0.46, 0.30, 0.90), true)

	var plots := get_tree().get_nodes_in_group("farm_plots")
	if not plots.is_empty() and (plots[0] as Node2D).visible:
		var farm_r := _world_rect_to_map(Rect2(Vector2(-792, -62), Vector2(82, 82)), csize)
		canvas.draw_rect(farm_r, Color(0.52, 0.64, 0.38, 0.90), true)

	# 6. Edificios de la Aldea en tonos teja/madera y borde de tinta
	var buildings: Array[Dictionary] = [
		{"rect": VillageRestaurant.RECT, "col": Color(0.68, 0.42, 0.32), "label": "Casa de Comidas El Fogón"},
		{"rect": Rect2(Vector2(260, -316), Vector2(348, 184)), "col": Color(0.64, 0.40, 0.28), "label": "Posada El Jabalí"},
		{"rect": Rect2(Vector2(277, -74), Vector2(116, 76)), "col": Color(0.52, 0.48, 0.44), "label": "Herrería"},
		{"rect": Rect2(Vector2(527, -74), Vector2(116, 76)), "col": Color(0.62, 0.38, 0.34), "label": "Carnicería"},
		{"rect": Rect2(Vector2(527, 110), Vector2(116, 76)), "col": Color(0.58, 0.46, 0.32), "label": "Carpintería"},
		{"rect": Rect2(Vector2(407, 110), Vector2(116, 76)), "col": Color(0.42, 0.54, 0.58), "label": "Pescadería"},
		{"rect": Rect2(Vector2(261, 107), Vector2(128, 96)), "col": Color(0.46, 0.56, 0.42), "label": "Botica"},
		{"rect": Rect2(Vector2(689, -234), Vector2(112, 78)), "col": Color(0.56, 0.46, 0.35), "label": "Casa Herrero"},
		{"rect": Rect2(Vector2(849, -234), Vector2(112, 78)), "col": Color(0.56, 0.46, 0.35), "label": "Casa Carnicero"},
		{"rect": Rect2(Vector2(689, -75), Vector2(112, 78)), "col": Color(0.56, 0.46, 0.35), "label": "Casa Carpintero"},
		{"rect": Rect2(Vector2(849, -75), Vector2(112, 78)), "col": Color(0.56, 0.46, 0.35), "label": "Casa Pescador"},
		{"rect": Rect2(Vector2(676, 100), Vector2(138, 96)), "col": Color(0.44, 0.56, 0.52), "label": "Hospital"},
		{"rect": Rect2(Vector2(844, 100), Vector2(142, 96)), "col": Color(0.42, 0.48, 0.58), "label": "Comisaría"},
		{"rect": Rect2(Vector2(679, 266), Vector2(132, 92)), "col": Color(0.56, 0.46, 0.54), "label": "Capilla"},
		{"rect": Rect2(Vector2(822, 260), Vector2(268, 168)), "col": Color(0.48, 0.52, 0.46), "label": "Cementerio"},
		{"rect": Rect2(Vector2(126, -1106), Vector2(124, 92)), "col": Color(0.46, 0.36, 0.28), "label": "Molino Viejo"}
	]
	var vm_lots = get_tree().get_first_node_in_group("village_manager")
	if vm_lots and "lots_state" in vm_lots:
		for l in VillageLots.LOTS: # V4: solares (libres, en obra o construidos)
			var lst: Dictionary = VillageLots.lot(vm_lots, str(l["id"]))
			var lsz: Vector2 = l["size"]
			var lc: Vector2 = VillageLots.lot_def(str(l["id"]))["center"]
			match str(lst["status"]):
				"built":
					var bsz: Vector2 = Vector2(128, 96) if str(lst["kind"]) in ["shop_house", "civic", "inn"] else Vector2(112, 78)
					if str(lst["kind"]) == "fields":
						buildings.append({"rect": Rect2(lc - lsz * 0.5, lsz), "col": Color(0.58, 0.64, 0.42, 0.85), "label": str(lst["title"])})
					else:
						buildings.append({"rect": Rect2(VillageLots.building_center(str(l["id"])) - bsz * 0.5, bsz), "col": Color(0.56, 0.46, 0.35), "label": str(lst["title"])})
				"building":
					buildings.append({"rect": Rect2(lc - lsz * 0.5, lsz), "col": Color(0.70, 0.56, 0.34, 0.80), "label": "Obra"})
				_:
					canvas.draw_rect(_world_rect_to_map(Rect2(lc - lsz * 0.5, lsz), csize), Color(0.35, 0.30, 0.24, 0.32), false, 1.0)
	var font: Font = ThemeDB.fallback_font
	for b in buildings:
		var br := _world_rect_to_map(b["rect"], csize)
		canvas.draw_rect(br, b["col"], true)
		canvas.draw_rect(br, Color(0.227, 0.196, 0.157, 0.92), false, 1.0)
	if detailed and font:
		_draw_building_labels(canvas, font, buildings, csize)

	# Etiquetas de Regiones en tinta cartográfica exactamente sobre cada accidente geográfico
	var ink_main := Color(0.149, 0.129, 0.106, 1.0)
	var ink_sub := Color(0.28, 0.23, 0.18, 1.0)
	if detailed and font:
		_draw_ink_tag(canvas, font, _world_to_map(Vector2(-1980, -490), csize), "Llanura Salvaje", 11, ink_main)
		_draw_ink_tag(canvas, font, _world_to_map(Vector2(-1710, -290), csize), "Ruinas Bandidos", 10, Color(0.48, 0.18, 0.15, 1.0))
		_draw_ink_tag(canvas, font, _world_to_map(Vector2(-1940, 290), csize), "Ciénaga de las Ranas", 11, ink_main)
		_draw_ink_tag(canvas, font, _world_to_map(Vector2(-910, -145), csize), "Campamento y Huerto", 10, ink_sub)
		_draw_ink_tag(canvas, font, _world_to_map(Vector2(-1035, 165), csize), "Lago del Oeste", 10, Color(0.14, 0.26, 0.32, 1.0))
		_draw_ink_tag(canvas, font, _world_to_map(Vector2(-980, 960), csize), "Soto de Conejos", 10, ink_sub)
		_draw_ink_tag(canvas, font, _world_to_map(Vector2(-980, 1620), csize), "Robledal de Jabalíes", 10, ink_sub)
		_draw_ink_tag(canvas, font, _world_to_map(Vector2(-120, 1280), csize), "Claros de Venados", 10, ink_sub)
		_draw_ink_tag(canvas, font, _world_to_map(Vector2(740, 1120), csize), "Riscos y Zorros", 10, ink_sub)

	# 7. Puntos en Vivo de Fauna del Bosque
	for animal in get_tree().get_nodes_in_group("wild_animals"):
		if animal is WildAnimal and animal.is_alive_in_ecosystem() and animal.visible:
			var ap := _world_to_map(animal.global_position, csize)
			var acol := Color(0.28, 0.52, 0.28)
			if animal.species == WildAnimal.SpeciesType.DEER:
				acol = Color(0.58, 0.42, 0.22)
			elif animal.species == WildAnimal.SpeciesType.FOX:
				acol = Color(0.76, 0.32, 0.18)
			elif animal.species == WildAnimal.SpeciesType.BOAR:
				acol = Color(0.42, 0.28, 0.36)
			canvas.draw_circle(ap, 2.8 if detailed else 1.6, acol)

	# 8. Puntos en Vivo de Enemigos Hostiles de la Llanura
	for h in get_tree().get_nodes_in_group("plains_hostiles"):
		if h is Node2D and h.visible and h.get("is_dead_flag") != true and h.get("is_dead") != true:
			var hp := _world_to_map(h.global_position, csize)
			canvas.draw_circle(hp, 3.6 if detailed else 2.0, Color(0.68, 0.18, 0.15))

	# 9. Puntos en Vivo de Aldeanos (VillageNPC)
	for npc in get_tree().get_nodes_in_group("village_npcs"):
		if npc is VillageNPC and not npc.is_dead:
			var np := _world_to_map(npc.global_position, csize)
			var ncol := Color(0.72, 0.52, 0.16)
			if npc.trade_role == VillageNPC.TradeRole.FAMILY_MEMBER:
				ncol = Color(0.26, 0.54, 0.32)
			elif npc.trade_role == VillageNPC.TradeRole.UNEMPLOYED:
				ncol = Color(0.28, 0.46, 0.62)
			canvas.draw_circle(np, 3.8 if detailed else 2.2, ncol)
			if detailed:
				canvas.draw_circle(np, 3.8, Color(0.149, 0.129, 0.106, 0.95), false, 1.0)

	# 10. Marcador Pulsante del Jugador en azul cobalto de tinta
	if is_instance_valid(player):
		var pp := _world_to_map(player.global_position, csize)
		var pulse_r: float = (5.8 if detailed else 3.5) + sin(_pulse_phase) * 1.4
		var p_blue := Color(0.16, 0.38, 0.68, 1.0)
		canvas.draw_circle(pp, pulse_r + 2.0, Color(0.16, 0.38, 0.68, 0.28))
		canvas.draw_circle(pp, 4.6 if detailed else 2.8, p_blue)
		canvas.draw_circle(pp, 4.6 if detailed else 2.8, Color(0.945, 0.910, 0.831, 1.0), false, 1.2)
		if detailed and font:
			_draw_ink_tag(canvas, font, pp + Vector2(7, 4), "Tú", 10, p_blue)

	# Marco interior de tinta del lienzo cartográfico
	canvas.draw_rect(Rect2(Vector2.ZERO, csize), Color(0.227, 0.196, 0.157, 0.95), false, 2.0)

## Nombres de edificios sin pisarse en etiquetas de papel y tinta.
func _draw_building_labels(canvas: Control, font: Font, buildings: Array, csize: Vector2) -> void:
	var placed: Array[Rect2] = []
	var fs: int = 10
	_label_hits.clear()
	for b in buildings:
		var br := _world_rect_to_map(b["rect"], csize)
		var full: String = str(b["label"])
		_label_hits.append({"rect": br, "label": full})
		var options: Array[String] = [full]
		var words: PackedStringArray = full.split(" ", false)
		if words.size() > 1:
			options.append(words[0])
		for txt in options:
			var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			if tw > br.size.x + 24.0 and txt != options[options.size() - 1]:
				continue # demasiado largo para su edificio: probamos la versión corta
			var done: bool = false
			for pos in [br.position + Vector2(0, -13), Vector2(br.position.x, br.end.y + 1)]:
				var lr := Rect2(pos, Vector2(tw + 6.0, 13.0))
				if placed.any(func(r): return r.intersects(lr)):
					continue
				placed.append(lr)
				canvas.draw_rect(lr, Color(0.945, 0.910, 0.831, 0.92), true)
				canvas.draw_rect(lr, Color(0.227, 0.196, 0.157, 0.72), false, 1.0)
				canvas.draw_string(font, lr.position + Vector2(3, 10), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.149, 0.129, 0.106, 1.0))
				done = true
				break
			if done:
				break

func _update_census_and_hover() -> void:
	if not full_map_canvas:
		return
	var r_alive := 0
	var d_alive := 0
	var f_alive := 0
	var b_alive := 0
	for a in get_tree().get_nodes_in_group("wild_animals"):
		if a is WildAnimal and a.is_alive_in_ecosystem():
			match a.species:
				WildAnimal.SpeciesType.RABBIT: r_alive += 1
				WildAnimal.SpeciesType.DEER: d_alive += 1
				WildAnimal.SpeciesType.FOX: f_alive += 1
				WildAnimal.SpeciesType.BOAR: b_alive += 1

	var h_alive := 0
	for h in get_tree().get_nodes_in_group("plains_hostiles"):
		if h is Node2D and h.get("is_dead_flag") != true and h.get("is_dead") != true:
			h_alive += 1

	var npc_alive := 0
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and not n.is_dead:
			npc_alive += 1

	if census_label:
		census_label.text = "👥 Aldeanos: %d  |  🐇 Conejos: %d  |  🦌 Venados: %d  |  🦊 Zorros: %d  |  🐗 Jabalíes: %d  |  ⚔️ Hostiles Llanura: %d" % [
			npc_alive, r_alive, d_alive, f_alive, b_alive, h_alive
		]

	if not hover_info_label:
		return
	var mpos := full_map_canvas.get_local_mouse_position()
	var csize := full_map_canvas.size
	var best_txt := "💡 Leyenda: 🔵 Tú | 🟡 Maestro Artesano | 🟢 Familiar | 🔹 Huésped | 🔴 Hostil Llanura | 🐇🦌🦊🐗 Fauna del Bosque"
	var best_d2: float = 14.0 * 14.0

	for hit in _label_hits:
		if (hit["rect"] as Rect2).has_point(mpos):
			best_txt = "🏛️ " + str(hit["label"])
	var vm = get_tree().get_first_node_in_group("village_manager")
	if vm and "shop_businesses" in vm:
		var shop_rects: Array[Dictionary] = [
			{"role": int(VillageNPC.TradeRole.BLACKSMITH), "rect": Rect2(Vector2(277, -74), Vector2(116, 76))},
			{"role": int(VillageNPC.TradeRole.BUTCHER), "rect": Rect2(Vector2(527, -74), Vector2(116, 76))},
			{"role": int(VillageNPC.TradeRole.CARPENTER), "rect": Rect2(Vector2(527, 110), Vector2(116, 76))},
			{"role": int(VillageNPC.TradeRole.FISHMONGER), "rect": Rect2(Vector2(407, 110), Vector2(116, 76))},
			{"role": int(VillageNPC.TradeRole.HERBALIST), "rect": Rect2(Vector2(261, 107), Vector2(128, 96))}
		]
		for sr in shop_rects:
			var r_id: int = int(sr["role"])
			var mr: Rect2 = _world_rect_to_map(sr["rect"], csize)
			if mr.has_point(mpos) and vm.shop_businesses.has(r_id):
				var b: Dictionary = vm.shop_businesses[r_id]
				var own_mode: String = str(b.get("owner_mode", "NPC"))
				var own_str: String = "Gremio Familiar"
				if own_mode == "PARTNER":
					own_str = "🤝 Eres Socio"
				elif own_mode == "SOLE_OWNER":
					own_str = "👑 Dueño Único"
				var vault_g: int = int(b.get("vault_gold", 0))
				var m_stat: String = str(vm.call("get_trade_market_status_text", r_id)) if vm.has_method("get_trade_market_status_text") else "Estable"
				var stk_tot: int = int(vm.call("get_trade_total_stock", r_id)) if vm.has_method("get_trade_total_stock") else 0
				best_txt = "🏪 %s — Propiedad: %s | %s | Stock: %d | 💰 Caja: %d Oro" % [
					str(b.get("title", "Negocio")), own_str, m_stat, stk_tot, vault_g
				]

	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and not n.is_dead:
			var np := _world_to_map(n.global_position, csize)
			var d2 := mpos.distance_squared_to(np)
			if d2 < best_d2:
				best_d2 = d2
				best_txt = "👤 %s (%s) — %s | Humor: %d%% | Rasgos: %s" % [
					n.npc_name, n.npc_role, n.get_activity_description(), int(round(n.mood)), n.get_known_traits_text()
				]

	hover_info_label.text = best_txt
