@tool
extends Node2D

var ambient_modulate: CanvasModulate = null
var ecosystem_manager: EcosystemManager = null
var village_manager: VillageManager = null
var _weather_layer: CanvasLayer = null
var _weather_canvas: Control = null
var _weather_anim_time: float = 0.0
var _weather_redraw_timer: float = 0.0

func _ready() -> void:
	var in_editor := Engine.is_editor_hint()
	set_process_unhandled_input(not in_editor)

	# 0. Asegurar que al maximizar o poner Pantalla Completa el juego ocupe el 100% del monitor sin bordes ni recortes
	if not in_editor:
		var win := get_window()
		if win:
			win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
			win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
			win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL

		# 1. Setup Day/Night Ambient Lighting (CanvasModulate)
		ambient_modulate = get_node_or_null("AmbientLight") as CanvasModulate
		if not ambient_modulate:
			ambient_modulate = CanvasModulate.new()
			ambient_modulate.name = "AmbientLight"
			add_child(ambient_modulate)
		
		if WorldClock:
			ambient_modulate.color = WorldClock.get_ambient_color()
			WorldClock.time_updated.connect(_on_world_time_updated)

	# 2. Ajustar fondo de hierba al tamaño real del valle (-920..1000 x -340..1300) con margen de cámara
	# (Evita generar 81 millones de píxeles en mosaico que saturan la GPU integrada de laptops)
	var parallax := get_node_or_null("Environment/Parallax2D") as Parallax2D
	if parallax:
		parallax.repeat_size = Vector2.ZERO
	var grass_rect := get_node_or_null("Environment/Parallax2D/TextureRect") as TextureRect
	if grass_rect:
		grass_rect.offset_left = -2250.0
		grass_rect.offset_top = -950.0
		grass_rect.offset_right = 1650.0
		grass_rect.offset_bottom = 2250.0
		var sh_2d := Shader.new()
		sh_2d.code = """
shader_type canvas_item;

float h2(vec2 p) {
	p = fract(p * vec2(234.17, 567.89));
	p += dot(p, p + 34.56);
	return fract(p.x * p.y);
}

float n2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(h2(i), h2(i + vec2(1.0, 0.0)), f.x),
		mix(h2(i + vec2(0.0, 1.0)), h2(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

void fragment() {
	vec2 px = UV * vec2(3900.0, 3200.0);
	float macro = n2(px * 0.008);
	float meso = n2(px * 0.032 + vec2(5.4, 2.7));
	float micro = n2(px * 0.14 + vec2(macro, meso) * 3.0);
	float blade = n2(px * 0.48 + vec2(meso, macro) * 5.0);
	vec3 c_light = vec3(0.35, 0.54, 0.25);
	vec3 c_mid = vec3(0.28, 0.46, 0.20);
	vec3 c_dark = vec3(0.22, 0.38, 0.16);
	vec3 c_earth = vec3(0.38, 0.32, 0.22);
	vec3 col = mix(c_light, c_mid, smoothstep(0.25, 0.75, macro * 0.65 + meso * 0.35));
	col = mix(col, c_dark, smoothstep(0.55, 0.88, meso * 0.6 + micro * 0.4) * 0.55);
	col = mix(col, c_earth, smoothstep(0.74, 0.92, macro * 0.5 + meso * 0.5) * 0.35);
	col *= mix(0.91, 1.09, micro * 0.5 + blade * 0.5);
	COLOR = vec4(col, 1.0);
}
"""
		var sm_2d := ShaderMaterial.new()
		sm_2d.shader = sh_2d
		grass_rect.material = sm_2d
	var obs_small := get_node_or_null("Environment/Obstacles Small") as TileMapLayer
	if obs_small:
		obs_small.clear()
		obs_small.add_to_group("ranch_fence_2d")
	var obs_large := get_node_or_null("Environment/Obstacles Large") as TileMapLayer
	if obs_large:
		for cell in obs_large.get_used_cells():
			var src_id: int = obs_large.get_cell_source_id(cell)
			if src_id == 13 or (cell.x >= -6 and cell.y >= 8) or (cell.x <= -20 and cell.y >= 8):
				obs_large.erase_cell(cell)
		obs_large.add_to_group("ranch_fence_2d")

	# Ajustar zoom inicial de la cámara para ver un área más amplia y cómoda en pantalla completa
	if not in_editor:
		var player_cam := get_node_or_null("Entities/PlayerGood/Camera2D") as Camera2D
		if player_cam:
			player_cam.zoom = Vector2(2.4, 2.4)

		# 3. Create NavigationRegion2D dynamically
		var nav_region = NavigationRegion2D.new()
		nav_region.name = "RuntimeNavigationRegion"
		add_child(nav_region)
		
		# Setup NavigationPolygon ajustado a los límites reales del Valle
		var nav_poly = NavigationPolygon.new()
		nav_poly.agent_radius = 16.0 # Approximate enemy radius
		
		var outline = PackedVector2Array([
			Vector2(-1250, -650),
			Vector2(1350, -650),
			Vector2(1350, 1550),
			Vector2(-1250, 1550)
		])
		nav_poly.vertices = outline
		nav_poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
		
		nav_region.navigation_polygon = nav_poly

	if not in_editor:
		# 4. Inicializar el Huerto, Campamento, Gallinero y Lago de Pesca del Jugador
		var entities_root: Node = get_node_or_null("Entities")
		if not entities_root:
			entities_root = self
		_spawn_player_garden(entities_root)

		# 5. Inicializar la Aldea Viva (Los 5 Oficios + Taberna Aparte con Habitaciones + 3 NPCs sin Oficio + Sucesión)
		village_manager = VillageManager.new()
		village_manager.name = "VillageManager"
		add_child(village_manager)
		village_manager.setup_village(entities_root)

		# 6. Inicializar el Ecosistema del Bosque Profundo (alejado al Sur de la zona inicial)
		ecosystem_manager = EcosystemManager.new()
		ecosystem_manager.name = "EcosystemManager"
		add_child(ecosystem_manager)
		ecosystem_manager.setup_ecosystem(entities_root)

		set_process(true)
		_setup_weather_overlay()
		_setup_retro_post_fx()

## Etalonaje retro (día nostálgico / noche inquietante con charcos de luz). Solo con ventana real.
func _setup_retro_post_fx() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var fx: CanvasLayer = load("res://scripts/visuals/RetroPostFX.gd").new()
	fx.setup(village_manager)
	add_child(fx)
	var ui := get_node_or_null("UI")
	if ui != null:
		move_child(fx, ui.get_index())

func _setup_weather_overlay() -> void:
	_weather_layer = CanvasLayer.new()
	_weather_layer.name = "WeatherCanvasLayer"
	_weather_layer.layer = 5
	add_child(_weather_layer)

	_weather_canvas = Control.new()
	_weather_canvas.name = "WeatherOverlayControl"
	_weather_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_weather_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_weather_canvas.draw.connect(_draw_weather_overlay)
	_weather_layer.add_child(_weather_canvas)

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not _weather_canvas:
		return
	var w_mode: int = int(WorldClock.get("current_weather")) if WorldClock else 0
	if w_mode == 0:
		if _weather_canvas.visible:
			_weather_canvas.visible = false
		return
	_weather_canvas.visible = true
	_weather_anim_time += delta
	_weather_redraw_timer -= delta
	if _weather_redraw_timer <= 0.0:
		_weather_redraw_timer = 0.035
		_weather_canvas.queue_redraw()

func _draw_weather_overlay() -> void:
	if not _weather_canvas or not WorldClock:
		return
	var w_mode: int = int(WorldClock.get("current_weather"))
	var sz: Vector2 = _weather_canvas.size
	if w_mode == 1: # RAIN
		_weather_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.12, 0.22, 0.36, 0.10), true)
		var drop_col := Color(0.68, 0.85, 1.0, 0.42)
		for i in range(55):
			var seed_x: float = fmod(float(i) * 97.3 + _weather_anim_time * 180.0, maxf(100.0, sz.x))
			var seed_y: float = fmod(float(i) * 63.7 + _weather_anim_time * 520.0, maxf(100.0, sz.y))
			var p1 := Vector2(seed_x, seed_y)
			var p2 := p1 + Vector2(-6.0, 18.0)
			_weather_canvas.draw_line(p1, p2, drop_col, 1.4)
	elif w_mode == 2: # FOG
		_weather_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.76, 0.82, 0.86, 0.07), true)

func _spawn_player_garden(entities_root: Node) -> void:
	# A. Huerto de 3x3 parcelas (en el claro oeste bien alejado de la Trattoria y del pueblo, frente al lago)
	var start_pos := Vector2(-775, -45)
	var spacing := 24.0
	var idx := 0
	for row in range(3):
		for col in range(3):
			var plot := FarmPlot.new()
			plot.name = "FarmPlot_%d" % idx
			entities_root.add_child(plot)
			plot.global_position = start_pos + Vector2(col * spacing, row * spacing)
			plot.set_plot_enabled(false)
			idx += 1

	# B. Campamento (Hoguera con Cacerola para cocinar + Tronco para sentarse + Tienda de Campaña + Tendedero)
	var camp := CampSite.new()
	camp.name = "PlayerCampSite"
	entities_root.add_child(camp)
	camp.global_position = Vector2(-722, -96)

	# C. Gallinero Cuadrado (Comedero de 2 toques, Nido de Huevos y defensa contra Zorros nocturnos)
	var coop := ChickenCoop.new()
	coop.name = "PlayerChickenCoop"
	entities_root.add_child(coop)
	coop.global_position = Vector2(-848, -21)
	coop.set_coop_built(false)

	# D. Lago y Muelle de Pesca al Sur del Campamento
	var lake := FishingSpot.new()
	lake.name = "WestFishingLake"
	entities_root.add_child(lake)
	lake.global_position = FishingSpot.LAKE_NODE_POS

func _unhandled_input(event: InputEvent) -> void:
	var player := get_node_or_null("Entities/PlayerGood")
	var modal_open: bool = player != null and player.has_method("is_any_ui_modal_open") and bool(player.call("is_any_ui_modal_open"))
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			var win := get_window()
			if win:
				if win.mode == Window.MODE_FULLSCREEN or win.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
					win.mode = Window.MODE_WINDOWED
				else:
					win.mode = Window.MODE_FULLSCREEN
			get_viewport().set_input_as_handled()
		elif not modal_open and (event.keycode == KEY_PLUS or event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD or event.keycode == KEY_PAGEUP):
			_adjust_camera_zoom(0.20)
			get_viewport().set_input_as_handled()
		elif not modal_open and (event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT or event.keycode == KEY_PAGEDOWN):
			_adjust_camera_zoom(-0.20)
			get_viewport().set_input_as_handled()
	elif not modal_open and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var delta_z: float = 0.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -0.15
			_adjust_camera_zoom(delta_z)
			get_viewport().set_input_as_handled()

func _adjust_camera_zoom(delta_z: float) -> void:
	var player_cam := get_node_or_null("Entities/PlayerGood/Camera2D") as Camera2D
	if player_cam:
		var next_z: float = clampf(player_cam.zoom.x + delta_z, 1.4, 3.6)
		player_cam.zoom = Vector2(next_z, next_z)

func _on_world_time_updated(_day: int, _hour: int, _minute: int) -> void:
	if ambient_modulate and WorldClock:
		ambient_modulate.color = WorldClock.get_ambient_color()
