extends Node2D

var ambient_modulate: CanvasModulate = null
var ecosystem_manager: EcosystemManager = null

func _ready() -> void:
	# 1. Setup Day/Night Ambient Lighting (CanvasModulate)
	ambient_modulate = get_node_or_null("AmbientLight") as CanvasModulate
	if not ambient_modulate:
		ambient_modulate = CanvasModulate.new()
		ambient_modulate.name = "AmbientLight"
		add_child(ambient_modulate)
	
	if WorldClock:
		ambient_modulate.color = WorldClock.get_ambient_color()
		WorldClock.time_updated.connect(_on_world_time_updated)

	# 2. Ampliar fondo de hierba para cubrir tanto la aldea como el Bosque Profundo al Sur/Suroeste
	var grass_rect := get_node_or_null("Environment/Parallax2D/TextureRect") as TextureRect
	if grass_rect:
		grass_rect.offset_left = -2500.0
		grass_rect.offset_top = -2500.0
		grass_rect.offset_right = 4500.0
		grass_rect.offset_bottom = 4500.0

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

	# 4. Inicializar el Huerto del Jugador (3x3 parcelas de cultivo cerca de tu zona inicial)
	var entities_root: Node = get_node_or_null("Entities")
	if not entities_root:
		entities_root = self
	_spawn_player_garden(entities_root)

	# 5. Inicializar el Ecosistema del Bosque Profundo (alejado al Sur de la zona inicial)
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

	# B. Campamento (Hoguera con Cacerola para cocinar + Tronco para sentarse/dormir)
	var camp := CampSite.new()
	camp.name = "PlayerCampSite"
	camp.global_position = Vector2(168, 24)
	entities_root.add_child(camp)

	# C. Gallinero Cuadrado (Comedero de 2 toques, Nido de Huevos y defensa contra Zorros nocturnos)
	var coop := ChickenCoop.new()
	coop.name = "PlayerChickenCoop"
	coop.global_position = Vector2(42, 99)
	entities_root.add_child(coop)

func _on_world_time_updated(_day: int, _hour: int, _minute: int) -> void:
	if ambient_modulate and WorldClock:
		ambient_modulate.color = WorldClock.get_ambient_color()
