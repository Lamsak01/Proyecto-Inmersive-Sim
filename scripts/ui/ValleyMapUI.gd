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
var _minimap_redraw_timer: float = 0.0
var _fullmap_redraw_timer: float = 0.0

const WORLD_RECT := Rect2(Vector2(-920.0, -340.0), Vector2(1920.0, 1640.0))

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
	if is_full_map_open and full_map_canvas:
		full_map_canvas.queue_redraw()
		_update_census_and_hover()

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
	minimap_panel.offset_left = -202.0
	minimap_panel.offset_top = 10.0
	minimap_panel.offset_right = -12.0
	minimap_panel.offset_bottom = 154.0
	minimap_panel.add_theme_stylebox_override("panel", _make_map_style(Color(0.06, 0.08, 0.11, 0.90), Color(0.72, 0.60, 0.34, 0.92), 6, 6, 5))
	add_child(minimap_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	minimap_panel.add_child(vbox)

	var header_btn := Button.new()
	header_btn.text = "🗺️ Mapa del Valle [M]"
	header_btn.flat = true
	header_btn.add_theme_font_size_override("font_size", 11)
	header_btn.add_theme_color_override("font_color", Color(0.96, 0.88, 0.62))
	header_btn.pressed.connect(func():
		if _can_open_full_map():
			toggle_full_map()
	)
	vbox.add_child(header_btn)

	minimap_canvas = Control.new()
	minimap_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	minimap_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	minimap_canvas.custom_minimum_size = Vector2(174, 112)
	minimap_canvas.clip_contents = true
	minimap_canvas.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and _can_open_full_map():
			toggle_full_map()
	)
	minimap_canvas.draw.connect(func(): _draw_valley_cartography(minimap_canvas, false))
	vbox.add_child(minimap_canvas)

func _build_full_map_ui() -> void:
	full_map_panel = PanelContainer.new()
	full_map_panel.name = "FullValleyMapPanel"
	full_map_panel.visible = false
	full_map_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	full_map_panel.offset_left = -450.0
	full_map_panel.offset_top = -275.0
	full_map_panel.offset_right = 450.0
	full_map_panel.offset_bottom = 275.0
	full_map_panel.add_theme_stylebox_override("panel", _make_map_style(Color(0.07, 0.09, 0.12, 0.97), Color(0.84, 0.70, 0.36, 1.0), 8, 16, 12))
	add_child(full_map_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	full_map_panel.add_child(vbox)

	var top_bar := HBoxContainer.new()
	vbox.add_child(top_bar)
	top_bar.add_child(_make_map_lbl("🗺️ Mapa Cartográfico del Valle — Regiones, Aldeanos en Vivo y Ecosistema", 16, Color(0.98, 0.90, 0.64), true))

	var close_btn := Button.new()
	close_btn.text = "✖ [M / ESC] Cerrar"
	close_btn.pressed.connect(close_full_map)
	top_bar.add_child(close_btn)

	census_label = _make_map_lbl("", 11, Color(0.76, 0.88, 0.98))
	vbox.add_child(census_label)

	full_map_canvas = Control.new()
	full_map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	full_map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	full_map_canvas.clip_contents = true
	full_map_canvas.draw.connect(func(): _draw_valley_cartography(full_map_canvas, true))
	vbox.add_child(full_map_canvas)

	hover_info_label = _make_map_lbl("💡 Pasa el cursor sobre cualquier punto del mapa para inspeccionar Aldeanos, Edificios o Hábitats.", 12, Color(0.95, 0.92, 0.72))
	vbox.add_child(hover_info_label)

func _world_to_map(world_pos: Vector2, canvas_size: Vector2) -> Vector2:
	var nx: float = (world_pos.x - WORLD_RECT.position.x) / WORLD_RECT.size.x
	var ny: float = (world_pos.y - WORLD_RECT.position.y) / WORLD_RECT.size.y
	return Vector2(nx * canvas_size.x, ny * canvas_size.y)

func _world_rect_to_map(w_rect: Rect2, canvas_size: Vector2) -> Rect2:
	var tl := _world_to_map(w_rect.position, canvas_size)
	var br := _world_to_map(w_rect.end, canvas_size)
	return Rect2(tl, br - tl)

func _draw_valley_cartography(canvas: Control, detailed: bool) -> void:
	var csize := canvas.size
	if csize.x <= 4.0 or csize.y <= 4.0:
		return

	# 1. Fondo general de pradera del valle
	canvas.draw_rect(Rect2(Vector2.ZERO, csize), Color(0.14, 0.24, 0.15, 0.96), true)

	# 2. Bioma Oeste: Llanura Salvaje y Ciénaga de Ranas
	var plains_r := _world_rect_to_map(Rect2(Vector2(-860, -210), Vector2(470, 360)), csize)
	canvas.draw_rect(plains_r, Color(0.46, 0.40, 0.22, 0.75), true)
	canvas.draw_rect(plains_r, Color(0.75, 0.64, 0.34, 0.85), false, 1.5)

	var marsh_r := _world_rect_to_map(Rect2(Vector2(-700, 42), Vector2(185, 88)), csize)
	canvas.draw_rect(marsh_r, Color(0.16, 0.44, 0.42, 0.88), true)

	var bandit_r := _world_rect_to_map(Rect2(Vector2(-730, -125), Vector2(235, 105)), csize)
	canvas.draw_rect(bandit_r, Color(0.42, 0.26, 0.20, 0.80), true)

	# 3. Bioma Sur: Bosque Profundo y sus 3 Hábitats Separados
	var forest_r := _world_rect_to_map(Rect2(Vector2(-520, 575), Vector2(1380, 665)), csize)
	canvas.draw_rect(forest_r, Color(0.09, 0.19, 0.11, 0.92), true)
	canvas.draw_rect(forest_r, Color(0.28, 0.55, 0.32, 0.85), false, 1.5)

	# Sub-hábitat 1: Pradera de Conejos (Oeste)
	var rab_r := _world_rect_to_map(Rect2(Vector2(-470, 600), Vector2(340, 300)), csize)
	canvas.draw_rect(rab_r, Color(0.18, 0.38, 0.22, 0.55), true)
	# Sub-hábitat 2: Claros de Venados (Centro-Sur)
	var deer_r := _world_rect_to_map(Rect2(Vector2(-50, 800), Vector2(370, 380)), csize)
	canvas.draw_rect(deer_r, Color(0.16, 0.33, 0.20, 0.55), true)
	# Sub-hábitat 3: Cantera y Zorros (Este)
	var fox_r := _world_rect_to_map(Rect2(Vector2(460, 610), Vector2(370, 350)), csize)
	canvas.draw_rect(fox_r, Color(0.32, 0.28, 0.24, 0.60), true)

	# 4. Red de Caminos y Plaza Central
	var road_col := Color(0.54, 0.42, 0.28, 0.90)
	for r_rect in [
		Rect2(Vector2(-465, 36), Vector2(1400, 26)),
		Rect2(Vector2(448, -135), Vector2(34, 765)),
		Rect2(Vector2(140, 130), Vector2(24, 194)),
		Rect2(Vector2(140, 310), Vector2(312, 24)),
		Rect2(Vector2(-380, 606), Vector2(1040, 24)),
		Rect2(Vector2(130, 626), Vector2(26, 260)),
		Rect2(Vector2(660, -135), Vector2(280, 24)),
		Rect2(Vector2(660, -135), Vector2(24, 185))
	]:
		canvas.draw_rect(_world_rect_to_map(r_rect, csize), road_col, true)

	var plaza_r := _world_rect_to_map(Rect2(Vector2(395, 10), Vector2(140, 78)), csize)
	canvas.draw_rect(plaza_r, Color(0.56, 0.58, 0.62, 0.95), true)

	# 5. Lago de Pesca, Gallinero, Huerto y Campamento del Jugador
	var lake_r := _world_rect_to_map(Rect2(Vector2(-120, 65), Vector2(95, 80)), csize)
	canvas.draw_rect(lake_r, Color(0.18, 0.52, 0.78, 0.92), true)

	var coop_r := _world_rect_to_map(Rect2(Vector2(4, 69), Vector2(76, 60)), csize)
	canvas.draw_rect(coop_r, Color(0.68, 0.48, 0.26, 0.90), true)

	var farm_r := _world_rect_to_map(Rect2(Vector2(100, 60), Vector2(82, 82)), csize)
	canvas.draw_rect(farm_r, Color(0.36, 0.62, 0.24, 0.90), true)

	# 6. Los 12 Edificios de la Aldea (incluyendo Hospital/Morgue y Comisaría/Cárcel)
	var buildings: Array[Dictionary] = [
		{"rect": Rect2(Vector2(310, -280), Vector2(260, 145)), "col": Color(0.68, 0.34, 0.20), "label": "🍺 Posada y Casino"},
		{"rect": Rect2(Vector2(277, -74), Vector2(116, 76)), "col": Color(0.48, 0.52, 0.60), "label": "⚒️ Herrería"},
		{"rect": Rect2(Vector2(527, -74), Vector2(116, 76)), "col": Color(0.65, 0.28, 0.26), "label": "🥩 Carnicería"},
		{"rect": Rect2(Vector2(527, 110), Vector2(116, 76)), "col": Color(0.62, 0.44, 0.24), "label": "🪚 Carpintería"},
		{"rect": Rect2(Vector2(407, 110), Vector2(116, 76)), "col": Color(0.28, 0.54, 0.68), "label": "🐟 Pescadería"},
		{"rect": Rect2(Vector2(261, 107), Vector2(128, 96)), "col": Color(0.32, 0.58, 0.34), "label": "🌿 Botica-Casa"},
		{"rect": Rect2(Vector2(689, -234), Vector2(112, 78)), "col": Color(0.52, 0.38, 0.26), "label": "🏠 Casa Herrero"},
		{"rect": Rect2(Vector2(849, -234), Vector2(112, 78)), "col": Color(0.52, 0.38, 0.26), "label": "🏠 Casa Carnicero"},
		{"rect": Rect2(Vector2(689, -75), Vector2(112, 78)), "col": Color(0.52, 0.38, 0.26), "label": "🏠 Casa Carpintero"},
		{"rect": Rect2(Vector2(849, -75), Vector2(112, 78)), "col": Color(0.52, 0.38, 0.26), "label": "🏠 Casa Pescador"},
		{"rect": Rect2(Vector2(676, 100), Vector2(138, 96)), "col": Color(0.22, 0.64, 0.58), "label": "🏥 Hospital y Morgue"},
		{"rect": Rect2(Vector2(844, 100), Vector2(142, 96)), "col": Color(0.26, 0.42, 0.72), "label": "🚓 Comisaría y Cárcel"},
		{"rect": Rect2(Vector2(679, 266), Vector2(132, 92)), "col": Color(0.52, 0.36, 0.68), "label": "⛪ Capilla San Cipriano"},
		{"rect": Rect2(Vector2(826, 262), Vector2(166, 98)), "col": Color(0.32, 0.42, 0.36), "label": "🪦 Cementerio Parroquial"}
	]
	var font: Font = ThemeDB.fallback_font
	for b in buildings:
		var br := _world_rect_to_map(b["rect"], csize)
		canvas.draw_rect(br, b["col"], true)
		canvas.draw_rect(br, Color(0.92, 0.85, 0.65, 0.85), false, 1.0)
		if detailed and font:
			canvas.draw_string(font, br.position + Vector2(2, -3), str(b["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.98, 0.94, 0.78))

	# Etiquetas de Regiones en el Mapa Completo
	if detailed and font:
		canvas.draw_string(font, _world_to_map(Vector2(-830, -225), csize), "🌾 LLANURA SALVAJE Y CIÉNAGA (OESTE)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.84, 0.45))
		canvas.draw_string(font, _world_to_map(Vector2(-690, -135), csize), "⚔️ Ruinas Bandidos", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.65, 0.55))
		canvas.draw_string(font, _world_to_map(Vector2(-685, 34), csize), "🐸 Ciénaga de Ranas", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.58, 0.98, 0.68))
		canvas.draw_string(font, _world_to_map(Vector2(-115, 50), csize), "🎣 Lago | 🐔 Corral | 🌱 Huerto", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.75, 0.94, 1.0))
		canvas.draw_string(font, _world_to_map(Vector2(-455, 592), csize), "🐇 Pradera de Conejos y Hierbas", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.72, 0.98, 0.75))
		canvas.draw_string(font, _world_to_map(Vector2(-35, 792), csize), "🦌 Claros de Venados y Hongos", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.96, 0.72))
		canvas.draw_string(font, _world_to_map(Vector2(475, 592), csize), "🦊 Cantera de Hierro y Zorros", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.78, 0.58))

	# 7. Puntos en Vivo de Fauna del Bosque
	for animal in get_tree().get_nodes_in_group("wild_animals"):
		if animal is WildAnimal and animal.is_alive_in_ecosystem() and animal.visible:
			var ap := _world_to_map(animal.global_position, csize)
			var acol := Color(0.75, 0.95, 0.75)
			if animal.species == WildAnimal.SpeciesType.DEER:
				acol = Color(0.90, 0.76, 0.48)
			elif animal.species == WildAnimal.SpeciesType.FOX:
				acol = Color(1.0, 0.48, 0.28)
			elif animal.species == WildAnimal.SpeciesType.BOAR:
				acol = Color(0.76, 0.42, 0.62)
			canvas.draw_circle(ap, 2.8 if detailed else 1.6, acol)

	# 8. Puntos en Vivo de Enemigos Hostiles de la Llanura
	for h in get_tree().get_nodes_in_group("plains_hostiles"):
		if h is Node2D and h.visible and not bool(h.get("is_dead_flag")):
			var hp := _world_to_map(h.global_position, csize)
			canvas.draw_circle(hp, 3.8 if detailed else 2.0, Color(1.0, 0.25, 0.25))

	# 9. Puntos en Vivo de Aldeanos (VillageNPC)
	for npc in get_tree().get_nodes_in_group("village_npcs"):
		if npc is VillageNPC and not npc.is_dead:
			var np := _world_to_map(npc.global_position, csize)
			var ncol := Color(1.0, 0.86, 0.32)
			if npc.trade_role == VillageNPC.TradeRole.FAMILY_MEMBER:
				ncol = Color(0.45, 0.92, 0.58)
			elif npc.trade_role == VillageNPC.TradeRole.UNEMPLOYED:
				ncol = Color(0.55, 0.82, 1.0)
			canvas.draw_circle(np, 4.2 if detailed else 2.2, ncol)
			if detailed:
				canvas.draw_circle(np, 4.2, Color.BLACK, false, 1.0)

	# 10. Marcador Pulsante del Jugador
	if is_instance_valid(player):
		var pp := _world_to_map(player.global_position, csize)
		var pulse_r: float = (6.0 if detailed else 3.5) + sin(_pulse_phase) * 1.5
		canvas.draw_circle(pp, pulse_r + 2.0, Color(0.15, 0.95, 1.0, 0.38))
		canvas.draw_circle(pp, 4.8 if detailed else 2.8, Color(0.20, 1.0, 1.0))
		canvas.draw_circle(pp, 4.8 if detailed else 2.8, Color.BLACK, false, 1.2)
		if detailed and font:
			canvas.draw_string(font, pp + Vector2(7, 4), "★ TÚ", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.35, 1.0, 1.0))

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
		if h is Node2D and not bool(h.get("is_dead_flag")):
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
					n.npc_name, n.npc_role, n.get_activity_description(), int(round(n.mood)), ", ".join(n.traits)
				]

	hover_info_label.text = best_txt
