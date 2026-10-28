extends Node2D

var ambient_modulate: CanvasModulate = null
var ecosystem_manager: EcosystemManager = null
var village_manager: VillageManager = null

func _ready() -> void:
	# 0. Asegurar que al maximizar o poner Pantalla Completa el juego ocupe el 100% del monitor sin bordes ni recortes
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
