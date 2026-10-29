@tool
extends Node2D

var ambient_modulate: CanvasModulate = null
var ecosystem_manager: EcosystemManager = null
var village_manager: VillageManager = null
var _weather_layer: CanvasLayer = null
var _weather_canvas: Control = null
var _weather_anim_time: float = 0.0

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

	# 2. Ampliar fondo de hierba sin el recorte de 320x192 de Parallax2D para cubrir toda la pantalla y todo el mapa
	var parallax := get_node_or_null("Environment/Parallax2D") as Parallax2D
	if parallax:
		parallax.repeat_size = Vector2.ZERO
	var grass_rect := get_node_or_null("Environment/Parallax2D/TextureRect") as TextureRect
	if grass_rect:
		grass_rect.offset_left = -3500.0
		grass_rect.offset_top = -3500.0
		grass_rect.offset_right = 5500.0
		grass_rect.offset_bottom = 5500.0

	# Ajustar zoom inicial de la cámara para ver un área más amplia y cómoda en pantalla completa
	if not in_editor:
		var player_cam := get_node_or_null("Entities/PlayerGood/Camera2D") as Camera2D
		if player_cam:
			player_cam.zoom = Vector2(2.4, 2.4)

		# 3. Create NavigationRegion2D dynamically
		var nav_region = NavigationRegion2D.new()
		nav_region.name = "RuntimeNavigationRegion"
		add_child(nav_region)
		
		# Setup NavigationPolygon
		var nav_poly = NavigationPolygon.new()
		nav_poly.agent_radius = 16.0 # Approximate enemy radius
		
		var outline = PackedVector2Array([
			Vector2(-2500, -2500),
			Vector2(4500, -2500),
			Vector2(4500, 4500),
			Vector2(-2500, 4500)
		])
		nav_poly.vertices = outline
		nav_poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
		
		nav_region.navigation_polygon = nav_poly

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

	if not in_editor:
		set_process(true)
		_setup_weather_overlay()

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
		_weather_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.76, 0.82, 0.86, 0.18), true)
		for b in range(6):
			var band_y: float = (sz.y / 6.0) * float(b) + sin(_weather_anim_time * 0.6 + float(b)) * 18.0
			_weather_canvas.draw_rect(Rect2(Vector2(0.0, band_y), Vector2(sz.x, 38.0)), Color(0.84, 0.88, 0.92, 0.08), true)

func _spawn_player_garden(entities_root: Node) -> void:
	# A. Huerto de 3x3 parcelas
	var start_pos := Vector2(115, 75)
	var spacing := 24.0
	var idx := 0
	for row in range(3):
		for col in range(3):
			var plot := FarmPlot.new()
			plot.name = "FarmPlot_%d" % idx
			plot.global_position = start_pos + Vector2(col * spacing, row * spacing)
			entities_root.add_child(plot)
			idx += 1

	# B. Campamento (Hoguera con Cacerola para cocinar + Tronco para sentarse + Tienda de Campaña)
	var camp := CampSite.new()
	camp.name = "PlayerCampSite"
	camp.global_position = Vector2(168, 24)
	entities_root.add_child(camp)

	# C. Gallinero Cuadrado (Comedero de 2 toques, Nido de Huevos y defensa contra Zorros nocturnos)
	var coop := ChickenCoop.new()
	coop.name = "PlayerChickenCoop"
	coop.global_position = Vector2(42, 99)
	entities_root.add_child(coop)

	# D. Lago y Muelle de Pesca al Oeste del Gallinero
	var lake := FishingSpot.new()
	lake.name = "WestFishingLake"
	lake.global_position = Vector2(-65, 105)
	entities_root.add_child(lake)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			var win := get_window()
			if win:
				if win.mode == Window.MODE_FULLSCREEN or win.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
					win.mode = Window.MODE_WINDOWED
				else:
					win.mode = Window.MODE_FULLSCREEN
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_PLUS or event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD or event.keycode == KEY_PAGEUP:
			_adjust_camera_zoom(0.20)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT or event.keycode == KEY_PAGEDOWN:
			_adjust_camera_zoom(-0.20)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var delta_z: float = 0.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -0.15
			_adjust_camera_zoom(delta_z)

func _adjust_camera_zoom(delta_z: float) -> void:
	var player_cam := get_node_or_null("Entities/PlayerGood/Camera2D") as Camera2D
	if player_cam:
		var next_z: float = clampf(player_cam.zoom.x + delta_z, 1.4, 3.6)
		player_cam.zoom = Vector2(next_z, next_z)

func _on_world_time_updated(_day: int, _hour: int, _minute: int) -> void:
	if ambient_modulate and WorldClock:
		ambient_modulate.color = WorldClock.get_ambient_color()
