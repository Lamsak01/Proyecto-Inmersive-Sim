@tool
extends Node2D

## Escenario 3D Low-Poly / Greybox Estilizado del Valle («La Placa de Petri» - Fase 2)
## - Renderiza terreno, caminos, plaza, pozos, parque, mirador del lago, ciénaga, lavadero,
##   cementerio parroquial, farolas con luz real, todos los edificios y solares, interiores 3D,
##   puertas abatibles, postigos de ventanas, tejados con apertura automática (Cutaway),
##   altillos (+1), alcantarillas (-1) y el asentamiento fronterizo «Puesto del Paso».
## - Se sincroniza 1:1 con las coordenadas 2D de colisión y navegación, permitiendo alternar
##   en vivo entre 2D y 3D con la tecla [F10] sin alterar ni una sola regla ni test del juego.

const CharacterAvatar3DScript = preload("res://scripts/visuals/CharacterAvatar3D.gd")
const AssetLib = preload("res://scripts/visuals/AssetLibrary3D.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const VillageCulture = preload("res://scripts/systems/VillageCulture.gd")
const VillageWorkScript = preload("res://scripts/systems/VillageWork.gd")
const VillageUnderworldScript = preload("res://scripts/systems/VillageUnderworld.gd")
const VillageHousingScript = preload("res://scripts/systems/VillageHousing.gd")
const FishingSpotScript = preload("res://scripts/obstacles/FishingSpot.gd")

const WORLD_SCALE: float = 0.02
const PITCH_DEG: float = 58.0
## Resolución interna: suficiente para que el 3D se lea como 3D (aristas, sombras); las texturas siguen pixeladas.
const VIEWPORT_W: int = 1280
const VIEWPORT_H: int = 720
const RETRO_TRIPLANAR_SCALE: float = 0.78

var vm: Node2D = null
var _is_headless: bool = false
var _sin_p: float = sin(deg_to_rad(PITCH_DEG))
var _cos_p: float = cos(deg_to_rad(PITCH_DEG))

var sub_viewport: SubViewport = null
var stage_sprite: Sprite2D = null
var stage_root_3d: Node3D = null
var cam_3d: Camera3D = null
var sun_light: DirectionalLight3D = null
var fill_light: DirectionalLight3D = null
var world_env: WorldEnvironment = null

var terrain_root_3d: Node3D = null
var buildings_root_3d: Node3D = null
var lots_root_3d: Node3D = null
var streetlights_root_3d: Node3D = null
var sewers_root_3d: Node3D = null
var outpost_root_3d: Node3D = null
var graves_root_3d: Node3D = null

var _mat_cache: Dictionary = {}
var _building_records_3d: Array[Dictionary] = []
var _door_nodes_3d: Array[Dictionary] = []
var _window_nodes_3d: Array[Dictionary] = []
var _chest_nodes_3d: Array[Dictionary] = []
var _morgue_body_nodes_3d: Array[Node3D] = []
var _jail_gate_pivot_3d: Node3D = null
var _streetlight_nodes_3d: Array[Dictionary] = []
var _last_buried_count: int = -1
var _last_use_3d: bool = true
var _cutaway_accum: float = 0.0
var nature_root_3d: Node3D = null
var _nature_accum: float = 10.0
var _nature_scan_accum: float = 10.0
var _nature_sources: Array = [] # [{"node": Node2D, "kind": "pine"|"rock"|"deco_pine", "sprite": CanvasItem}]
var _nature_nodes: Dictionary = {} # instance_id -> {"tree": Node3D, "stump": Node3D}
## Rendimiento: árboles y rocas iguales se dibujan juntos por zonas (una sola orden a la tarjeta por modelo y zona).
const BATCH_CHUNK_PX: float = 512.0
var _batches: Dictionary = {} # clave -> {"mmi": MultiMeshInstance3D, "entries": [{"xf": Transform3D, "vis": bool}]}
var _batch_dirty: Dictionary = {}
var _prop_sources: Array = [] # [{"sprite": Sprite2D, "kind": String}] objetos quietos 2D con su versión 3D
var _prop_nodes: Dictionary = {} # instance_id del sprite -> {"root": Node3D, "variant": String}
var _extra_hidden_2d: Array = [] # Piezas 2D (suelos, muros, cercas) que se esconden en 3D: casa del jugador y gallinero
var _camp_node: Node2D = null
var _player_house_3d: Node3D = null
var _player_house_roof: Node3D = null
var _player_house_rect: Rect2 = Rect2()
var _player_house_tier: int = -1
var _coop_node: Node2D = null
var _coop_3d: Node3D = null
var _coop_gap_3d: Node3D = null
var _grid_panel_bulb_3d: MeshInstance3D = null
var _heist_prop_3d: Node3D = null
var _last_heist_sig: String = ""
var _town_ledger_3d: Node3D = null # P5: libro de cuentas en la mesa del ayuntamiento
var _home_props_3d: Node3D = null
var _last_home_props_sig: String = ""

func setup_stage(village_manager: Node2D) -> void:
	vm = village_manager
	name = "WorldStage3D"
	_is_headless = DisplayServer.get_name() == "headless" or Engine.is_editor_hint()

	stage_root_3d = Node3D.new()
	stage_root_3d.name = "StageRoot3D"

	terrain_root_3d = Node3D.new()
	terrain_root_3d.name = "Terrain3D"
	stage_root_3d.add_child(terrain_root_3d)

	buildings_root_3d = Node3D.new()
	buildings_root_3d.name = "Buildings3D"
	stage_root_3d.add_child(buildings_root_3d)

	lots_root_3d = Node3D.new()
	lots_root_3d.name = "Lots3D"
	stage_root_3d.add_child(lots_root_3d)

	streetlights_root_3d = Node3D.new()
	streetlights_root_3d.name = "Streetlights3D"
	stage_root_3d.add_child(streetlights_root_3d)

	sewers_root_3d = Node3D.new()
	sewers_root_3d.name = "Sewers3D"
	sewers_root_3d.visible = false
	stage_root_3d.add_child(sewers_root_3d)

	outpost_root_3d = Node3D.new()
	outpost_root_3d.name = "Outpost3D"
	stage_root_3d.add_child(outpost_root_3d)

	graves_root_3d = Node3D.new()
	graves_root_3d.name = "Graves3D"
	stage_root_3d.add_child(graves_root_3d)

	nature_root_3d = Node3D.new()
	nature_root_3d.name = "Nature3D"
	stage_root_3d.add_child(nature_root_3d)

	if not _is_headless:
		sub_viewport = SubViewport.new()
		sub_viewport.name = "WorldSubViewport3D"
		sub_viewport.size = Vector2i(VIEWPORT_W, VIEWPORT_H)
		sub_viewport.transparent_bg = true
		sub_viewport.own_world_3d = true
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sub_viewport.msaa_3d = Viewport.MSAA_DISABLED
		add_child(sub_viewport)

		sub_viewport.add_child(stage_root_3d)

		var env := Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.84, 0.86, 0.90)
		env.ambient_light_energy = 0.58
		world_env = WorldEnvironment.new()
		world_env.environment = env
		stage_root_3d.add_child(world_env)

		sun_light = DirectionalLight3D.new()
		sun_light.name = "SunLight3D"
		# Sol desde arriba a la izquierda: las sombras caen hacia abajo a la derecha, delante de las fachadas, donde se ven.
		sun_light.rotation_degrees = Vector3(-50.0, -135.0, 0.0)
		sun_light.light_energy = 0.96
		sun_light.light_color = Color(1.0, 0.95, 0.86)
		sun_light.shadow_enabled = true
		sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		sun_light.directional_shadow_max_distance = 140.0
		sun_light.shadow_bias = 0.03
		sun_light.shadow_normal_bias = 1.0
		sun_light.shadow_opacity = 0.78
		stage_root_3d.add_child(sun_light)

		fill_light = DirectionalLight3D.new()
		fill_light.name = "FillLight3D"
		fill_light.rotation_degrees = Vector3(-35.0, 145.0, 0.0)
		fill_light.light_energy = 0.30
		fill_light.light_color = Color(0.72, 0.80, 0.94)
		fill_light.shadow_enabled = false
		stage_root_3d.add_child(fill_light)

		cam_3d = Camera3D.new()
		cam_3d.name = "WorldCamera3D"
		cam_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam_3d.rotation_degrees = Vector3(-PITCH_DEG, 0.0, 0.0)
		cam_3d.near = 0.1
		cam_3d.far = 250.0
		cam_3d.size = 12.0
		cam_3d.current = true
		stage_root_3d.add_child(cam_3d)

		stage_sprite = Sprite2D.new()
		stage_sprite.name = "WorldStageSprite2D"
		stage_sprite.top_level = true
		stage_sprite.z_as_relative = false
		# Por debajo de los objetos 2D del suelo con z = -1 (huertos, camas, pozos…), por encima de los decorados planos
		# (bordes, césped del bosque), que el suelo 3D sustituye.
		stage_sprite.z_index = -2
		stage_sprite.centered = true
		stage_sprite.texture = sub_viewport.get_texture()
		stage_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(stage_sprite)
	else:
		add_child(stage_root_3d)

	_build_static_terrain_3d()
	_build_sewers_3d()
	_build_streetlights_3d()
	rebuild_all_3d()
	_sync_2d_flat_visuals(CharacterAvatar3DScript.use_3d_characters)

func to_3d(pos_2d: Vector2, h_px: float = 0.0) -> Vector3:
	return Vector3(
		pos_2d.x * WORLD_SCALE,
		(h_px * WORLD_SCALE) / _cos_p,
		(pos_2d.y * WORLD_SCALE) / _sin_p
	)

func size_3d(sz_2d: Vector2, h_px: float) -> Vector3:
	return Vector3(
		maxf(0.02, sz_2d.x * WORLD_SCALE),
		maxf(0.01, (h_px * WORLD_SCALE) / _cos_p),
		maxf(0.02, (sz_2d.y * WORLD_SCALE) / _sin_p)
	)

func _mat(key: String, col: Color, rough: float = 0.82, metal: float = 0.05, emit_col: Color = Color(0, 0, 0, 0), emit_energy: float = 0.0, tex_rel: String = "", norm_rel: String = "", triplanar_scale: float = 0.65) -> StandardMaterial3D:
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	if not _is_headless and not tex_rel.is_empty():
		var tex := AssetLib.load_texture(tex_rel)
		if tex != null:
			m.albedo_texture = tex
			# Estética retro: la textura pixelada manda; el color del edificio solo la tiñe un poco.
			m.albedo_color = col.lerp(Color.WHITE, 0.55)
			m.uv1_triplanar = true
			# Texturas de 64 px: una repetición cada ~64 px del mapa 2D (densidad parecida al pixel art).
			var ts := RETRO_TRIPLANAR_SCALE if tex_rel.begins_with("town_textures/") else triplanar_scale
			m.uv1_scale = Vector3(ts, ts, ts)
		if not norm_rel.is_empty():
			var ntex := AssetLib.load_texture(norm_rel)
			if ntex != null:
				m.normal_enabled = true
				m.normal_texture = ntex
				m.normal_scale = 0.75
	if col.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit_energy > 0.0:
		m.emission_enabled = true
		m.emission = emit_col
		m.emission_energy_multiplier = emit_energy
	_mat_cache[key] = m
	return m

func _add_model_2d(parent: Node3D, rel_path: String, center_2d: Vector2, bottom_h_px: float, sz_2d: Vector2 = Vector2.ZERO, height_px: float = 24.0, rot_y_deg: float = 0.0) -> Node3D:
	if _is_headless or not AssetLib.has_curated_assets():
		return null
	var target_sz := Vector3.ZERO
	var fit_h := -1.0
	if sz_2d != Vector2.ZERO:
		target_sz = size_3d(sz_2d, height_px)
	else:
		fit_h = maxf(0.05, (height_px * WORLD_SCALE) / _cos_p)
	var inst := AssetLib.instantiate_model(rel_path, target_sz, fit_h, true, true)
	if inst == null:
		return null
	inst.position = to_3d(center_2d, bottom_h_px)
	if absf(rot_y_deg) > 0.01:
		inst.rotation_degrees.y = rot_y_deg
	parent.add_child(inst)
	return inst

func _add_box_2d(parent: Node3D, center_2d: Vector2, sz_2d: Vector2, bottom_h_px: float, height_px: float, mat: Material, rot_y_deg: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size_3d(sz_2d, height_px)
	mi.mesh = bm
	mi.material_override = mat
	mi.position = to_3d(center_2d, bottom_h_px + height_px * 0.5)
	if absf(rot_y_deg) > 0.01:
		mi.rotation_degrees.y = rot_y_deg
	parent.add_child(mi)
	return mi

func _add_cyl_2d(parent: Node3D, center_2d: Vector2, radius_px: float, bottom_h_px: float, height_px: float, mat: Material, top_radius_px: float = -1.0, radial_segs: int = 12) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.bottom_radius = maxf(0.01, radius_px * WORLD_SCALE)
	cm.top_radius = maxf(0.0, (radius_px if top_radius_px < 0.0 else top_radius_px) * WORLD_SCALE)
	cm.height = maxf(0.01, (height_px * WORLD_SCALE) / _cos_p)
	cm.radial_segments = radial_segs
	mi.mesh = cm
	mi.material_override = mat
	mi.position = to_3d(center_2d, bottom_h_px + height_px * 0.5)
	parent.add_child(mi)
	return mi

## Tejado a dos aguas: prisma triangular cuya cumbrera va a lo largo de X (ridge_x) o de Y del mapa 2D.
func _add_prism_2d(parent: Node3D, center_2d: Vector2, sz_2d: Vector2, bottom_h_px: float, height_px: float, mat: Material, ridge_x: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	var s3 := size_3d(sz_2d, height_px)
	if ridge_x:
		pm.size = Vector3(s3.z, s3.y, s3.x)
		mi.rotation_degrees.y = 90.0
	else:
		pm.size = s3
	mi.mesh = pm
	mi.material_override = mat
	mi.position = to_3d(center_2d, bottom_h_px + height_px * 0.5)
	parent.add_child(mi)
	return mi

## Chapitel de cuatro caras (pirámide) para torres.
func _add_pyramid_2d(parent: Node3D, center_2d: Vector2, sz_2d: Vector2, bottom_h_px: float, height_px: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	var s3 := size_3d(sz_2d, height_px)
	cm.top_radius = 0.0
	cm.bottom_radius = 0.5
	cm.height = 1.0
	cm.radial_segments = 4
	cm.rings = 1
	mi.mesh = cm
	mi.scale = Vector3(s3.x * 1.41, s3.y, s3.z * 1.41)
	mi.rotation_degrees.y = 45.0
	mi.material_override = mat
	mi.position = to_3d(center_2d, bottom_h_px + height_px * 0.5)
	parent.add_child(mi)
	return mi

## Panel con una textura pixelada entera en su cara frontal y trasera (puertas, ventanas).
## Las caras laterales quedan del color medio de la textura.
func _make_texture_panel(w_px: float, h_px: float, depth_px: float, mat: Material) -> Node3D:
	var root := Node3D.new()
	var sz := size_3d(Vector2(w_px, depth_px), h_px)
	var core := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sz.x * 0.98, sz.y * 0.98, sz.z * 0.9)
	core.mesh = bm
	core.material_override = _mat("panel_core", Color(0.30, 0.20, 0.12), 0.9, 0.0)
	root.add_child(core)
	for side in [1.0, -1.0]:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(sz.x, sz.y)
		q.mesh = qm
		q.material_override = mat
		q.position = Vector3(0.0, 0.0, sz.z * 0.5 * side + 0.002 * side)
		if side < 0.0:
			q.rotation_degrees.y = 180.0
		q.name = "Face" if side > 0.0 else "FaceBack"
		root.add_child(q)
	return root

## Material para paneles: textura completa (sin repetir), filtrado pixelado y opcionalmente brillante (ventanas de noche).
func _panel_mat(key: String, tex_rel: String, lit: bool) -> StandardMaterial3D:
	var k := "panel_" + key
	if _mat_cache.has(k):
		return _mat_cache[k]
	var m := StandardMaterial3D.new()
	m.roughness = 0.9
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	var tex := AssetLib.load_texture(tex_rel)
	if tex != null:
		m.albedo_texture = tex
		if lit:
			m.emission_enabled = true
			m.emission_texture = tex
			m.emission = Color(1.0, 0.78, 0.45)
			m.emission_energy_multiplier = 1.6
	if tex_rel.find("window") != -1 or tex_rel.find("door") != -1:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
	_mat_cache[k] = m
	return m

func _clear_children(n: Node3D) -> void:
	if n == null:
		return
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()

func rebuild_all_3d() -> void:
	if vm == null:
		return
	rebuild_buildings_3d()
	rebuild_lots_3d()
	rebuild_outpost_3d()
	rebuild_graves_3d()
	_sync_2d_flat_visuals(CharacterAvatar3DScript.use_3d_characters)

# ==============================================================================
# 1. TERRENO, CAMINOS, PLAZA, POZOS, PARQUE, LAGO, CIÉNAGA Y CEMENTERIO 3D
# ==============================================================================
func _build_static_terrain_3d() -> void:
	_clear_children(terrain_root_3d)
	_build_ground_3d()
	var m_road := _mat("road_dirt", Color(0.56, 0.46, 0.34), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.55)
	var m_curb := _mat("road_curb", Color(0.62, 0.58, 0.52), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/wall_stone.png", "", 0.70)
	var m_plaza := _mat("plaza_stone", Color(0.66, 0.62, 0.56), 0.85, 0.05, Color.BLACK, 0.0, "town_textures/rf_cobblestone.png", "", 0.65)
	var m_plaza_trim := _mat("plaza_trim", Color(0.72, 0.68, 0.60), 0.80, 0.08, Color.BLACK, 0.0, "town_textures/floor_stone_trimsheet.png", "", 0.75)
	var m_wood := _mat("prop_wood", Color(0.54, 0.36, 0.20), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_dark_wood := _mat("prop_dark_wood", Color(0.38, 0.24, 0.13), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_stone := _mat("prop_stone", Color(0.66, 0.68, 0.72), 0.85, 0.05, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.70)
	var m_water := _mat("water_blue", Color(0.18, 0.52, 0.74, 0.90), 0.20, 0.15)
	var m_marsh := _mat("water_marsh", Color(0.20, 0.42, 0.30, 0.92), 0.28, 0.10)
	var m_grass_park := _mat("grass_park", Color(0.24, 0.48, 0.22), 0.92, 0.0)
	var m_pine := _mat("pine_leaf", Color(0.16, 0.38, 0.18), 0.88, 0.0)
	var m_pine_top := _mat("pine_leaf_top", Color(0.22, 0.46, 0.22), 0.86, 0.0)
	var m_iron := _mat("wrought_iron", Color(0.22, 0.24, 0.28), 0.45, 0.75)
	var m_shingle := _mat("roof_shingle_brown", Color(0.56, 0.30, 0.18), 0.82, 0.04, Color.BLACK, 0.0, "town_textures/roof_clay_red_center.png", "", 0.75)

	# Caminos principales y calles con relieve 3D
	var road_rects: Array[Rect2] = [
		Rect2(Vector2(-940, 36), Vector2(2485, 28)),
		Rect2(Vector2(-38, -88), Vector2(18, 124)),
		Rect2(Vector2(-38, 64), Vector2(18, 32)),
		Rect2(Vector2(452, -310), Vector2(26, 350)),
		Rect2(Vector2(452, 62), Vector2(26, 280)),
		Rect2(Vector2(822, -230), Vector2(24, 520)),
		Rect2(Vector2(215, -310), Vector2(20, 620)),
		Rect2(Vector2(1078, -230), Vector2(20, 480)),
		Rect2(Vector2(1318, -230), Vector2(20, 480)),
		Rect2(Vector2(215, 232), Vector2(1120, 20)),
	]
	for rr in road_rects:
		_add_box_2d(terrain_root_3d, rr.get_center(), rr.size, 0.0, 1.2, m_road)
	for lr in VillageLots.ROADS:
		if lr is Rect2:
			var r_lot: Rect2 = lr
			_add_box_2d(terrain_root_3d, r_lot.get_center(), r_lot.size, 0.0, 1.2, m_road)
	_build_barrios_3d(m_wood)
	# Callejas curvas del norte: un tramo de camino por segmento, girado, con una losa en cada codo
	for cr in VillageLots.CURVED_ROADS:
		var cpts: PackedVector2Array = VillageLots.curved_road_points(cr)
		var cw: float = float(cr["w"])
		for i in range(cpts.size() - 1):
			var a: Vector2 = cpts[i]
			var b: Vector2 = cpts[i + 1]
			_add_box_2d(terrain_root_3d, (a + b) * 0.5, Vector2(a.distance_to(b) + 2.0, cw), 0.0, 1.2, m_road, -rad_to_deg((b - a).angle()))

	# Plaza Central Empedrada con bordillos 3D
	var plaza_r := Rect2(Vector2(388, 12), Vector2(154, 72))
	_add_box_2d(terrain_root_3d, plaza_r.get_center(), plaza_r.size, 0.0, 1.8, m_plaza)
	_add_box_2d(terrain_root_3d, Vector2(plaza_r.get_center().x, plaza_r.position.y), Vector2(plaza_r.size.x, 4.0), 1.8, 1.8, m_plaza_trim)
	_add_box_2d(terrain_root_3d, Vector2(plaza_r.get_center().x, plaza_r.end.y), Vector2(plaza_r.size.x, 4.0), 1.8, 1.8, m_plaza_trim)

	# Bancos reales 3D de la Plaza Central
	for bp in [Vector2(436, 76), Vector2(494, 76)]:
		_build_bench_3d(terrain_root_3d, bp, m_wood, m_iron)

	# Tablón de Encargos 3D en la Plaza (Vector2(465, 24))
	var nb: Vector2 = vm._notice_board_pos if vm != null else Vector2(465, 24)
	_add_box_2d(terrain_root_3d, nb + Vector2(-9, 0), Vector2(2.5, 2.5), 0.0, 18.0, m_dark_wood)
	_add_box_2d(terrain_root_3d, nb + Vector2(9, 0), Vector2(2.5, 2.5), 0.0, 18.0, m_dark_wood)
	_add_box_2d(terrain_root_3d, nb, Vector2(22.0, 2.5), 7.0, 10.0, m_wood)
	_add_box_2d(terrain_root_3d, nb, Vector2(25.0, 6.0), 17.0, 3.0, m_shingle)
	var m_paper := _mat("parchment", Color(0.95, 0.90, 0.76), 0.90, 0.0)
	for px in [-6.0, 0.0, 6.0]:
		_add_box_2d(terrain_root_3d, nb + Vector2(px, 1.5), Vector2(4.0, 0.8), 9.5, 5.0, m_paper)

	# (2026-11-06) Los pozos ya no van fijos aquí: los pone _sync_props_3d donde esté cada pozo 2D (también los de solares nuevos).

	# Compostador, carretas y barriles de la Granja y Rancho Sur
	# (2026-11-05) Quitados el carro, las cajas, el compostador 3D duplicado y los animales de adorno del «rancho»:
	# estaban encima de la granja del jugador o en un cruce de caminos y no eran objetos del juego.

	# Corral 3D de madera y tierra del Rancho del Sur (x = 310..397, y = 400..540; el ganado vivo lo sincroniza VillageHousing.sync_livestock)
	var ranch_floor_r := Rect2(Vector2(310.0, 400.0), Vector2(87.0, 140.0))
	_add_box_2d(terrain_root_3d, ranch_floor_r.get_center(), ranch_floor_r.size, 0.0, 0.8, m_road)
	for r_side in [
		[Vector2(310.0, 400.0), Vector2(397.0, 400.0)],
		[Vector2(397.0, 400.0), Vector2(397.0, 540.0)],
		[Vector2(397.0, 540.0), Vector2(310.0, 540.0)],
		[Vector2(310.0, 540.0), Vector2(310.0, 400.0)],
	]:
		_build_fence_run_3d(terrain_root_3d, r_side[0] as Vector2, r_side[1] as Vector2, m_wood)

	# Parque del Roble (Vector2(105, -55)) con árboles 3D reales
	var park_c := Vector2(105, -55)
	_add_box_2d(terrain_root_3d, park_c, Vector2(92, 68), 0.0, 1.6, m_grass_park)
	_add_box_2d(terrain_root_3d, park_c + Vector2(0, -34), Vector2(94, 3), 0.0, 5.0, m_curb)
	_add_box_2d(terrain_root_3d, park_c + Vector2(0, 34), Vector2(94, 3), 0.0, 5.0, m_curb)
	var tree_idx := 0
	for tp in [Vector2(-32, -18), Vector2(32, -18), Vector2(-34, 18), Vector2(34, 18), Vector2(0, -6)]:
		_build_tree_3d(terrain_root_3d, park_c + tp, m_dark_wood, m_pine, m_pine_top, 1.25 if tp == Vector2(0, -6) else 0.95, tree_idx)
		tree_idx += 1
	_build_bench_3d(terrain_root_3d, park_c + Vector2(-16, 12), m_wood, m_iron)
	_build_bench_3d(terrain_root_3d, park_c + Vector2(16, 12), m_wood, m_iron)

	# Lavadero Municipal, en su sitio real (orilla norte del lago)
	var wash_c: Vector2 = VillageWorkScript.LAVADERO_POS
	_add_box_2d(terrain_root_3d, wash_c, Vector2(46, 32), 0.0, 2.0, m_stone)
	_add_box_2d(terrain_root_3d, wash_c, Vector2(32, 14), 2.0, 5.5, m_curb)
	_add_box_2d(terrain_root_3d, wash_c, Vector2(28, 10), 2.5, 4.8, m_water)
	for wp_off in [Vector2(-19, -12), Vector2(19, -12), Vector2(-19, 12), Vector2(19, 12)]:
		_add_box_2d(terrain_root_3d, wash_c + wp_off, Vector2(2.5, 2.5), 2.0, 18.0, m_dark_wood)
	_add_box_2d(terrain_root_3d, wash_c, Vector2(50, 36), 20.0, 4.5, m_shingle)
	_add_model_2d(terrain_root_3d, "props/Bucket_Wooden_1.gltf", wash_c + Vector2(-14, 10), 2.0, Vector2.ZERO, 6.5)
	_add_model_2d(terrain_root_3d, "props/Barrel.gltf", wash_c + Vector2(16, -10), 2.0, Vector2.ZERO, 10.0)

	# Lago del Oeste (el de verdad, donde se pesca), ampliado; sauces en la orilla
	_build_lake_3d()
	_add_model_2d(terrain_root_3d, "nature/Willow_1.obj", Vector2(-300, 82), 0.0, Vector2.ZERO, 40.0)
	_add_model_2d(terrain_root_3d, "nature/Willow_2.obj", Vector2(-440, 190), 0.0, Vector2.ZERO, 38.0, 70.0)
	_add_model_2d(terrain_root_3d, "nature/Willow_1.obj", Vector2(-190, 210), 0.0, Vector2.ZERO, 34.0, 140.0)

	# Ciénaga de las Ranas del Oeste (Rect2(Vector2(-692, 52), Vector2(170, 66)))
	var marsh_r := Rect2(Vector2(-692, 52), Vector2(170, 66))
	_add_box_2d(terrain_root_3d, marsh_r.get_center(), marsh_r.size, 0.0, 1.2, m_marsh)
	_add_box_2d(terrain_root_3d, marsh_r.get_center() + Vector2(0, -18), Vector2(68, 8), 1.2, 2.0, m_wood)
	for rp in [Vector2(-665, 66), Vector2(-630, 102), Vector2(-585, 74), Vector2(-545, 98)]:
		if _add_model_2d(terrain_root_3d, "nature/Bush_1.obj", rp, 1.0, Vector2.ZERO, 10.0) == null:
			_add_cyl_2d(terrain_root_3d, rp, 4.0, 1.0, 8.0, m_pine, 1.5, 6)
	_add_model_2d(terrain_root_3d, "nature/Willow_2.obj", Vector2(-678, 56), 0.0, Vector2.ZERO, 30.0)
	_add_model_2d(terrain_root_3d, "nature/Rock_2.obj", Vector2(-540, 62), 0.0, Vector2.ZERO, 11.0)

	# Cercado del Cementerio Parroquial (Rect2(Vector2(822, 258), Vector2(174, 108))) con Cripta y Verjas 3D reales
	var cem_r := Rect2(Vector2(822, 258), Vector2(174, 108))
	var cem_c := cem_r.get_center()
	_add_box_2d(terrain_root_3d, cem_c, cem_r.size, 0.0, 1.0, _mat("cem_ground", Color(0.28, 0.31, 0.26), 0.95, 0.0))
	_add_box_2d(terrain_root_3d, Vector2(cem_c.x, cem_r.end.y), Vector2(cem_r.size.x, 3.5), 0.0, 11.0, m_iron)
	_add_box_2d(terrain_root_3d, Vector2(cem_r.position.x, cem_c.y), Vector2(3.5, cem_r.size.y), 0.0, 11.0, m_iron)
	_add_box_2d(terrain_root_3d, Vector2(cem_r.end.x, cem_c.y), Vector2(3.5, cem_r.size.y), 0.0, 11.0, m_iron)
	_add_box_2d(terrain_root_3d, Vector2(848, cem_r.position.y), Vector2(52, 3.5), 0.0, 11.0, m_iron)
	_add_box_2d(terrain_root_3d, Vector2(950, cem_r.position.y), Vector2(92, 3.5), 0.0, 11.0, m_iron)
	_add_model_2d(terrain_root_3d, "graveyard/iron-fence.glb", Vector2(888, cem_r.position.y), 0.0, Vector2.ZERO, 18.0)
	_add_model_2d(terrain_root_3d, "graveyard/crypt.glb", Vector2(972, 282), 1.0, Vector2.ZERO, 26.0, -90.0)
	_add_model_2d(terrain_root_3d, "graveyard/altar-stone.glb", Vector2(968, 336), 1.0, Vector2.ZERO, 12.0)

	# Bloque FIS3: Trampillas / rejillas físicas de acceso a las Alcantarillas (-1) en sus posiciones reales de la calle
	var m_sewer_dark := _mat("sewer_dark", Color(0.06, 0.10, 0.08), 0.9, 0.2)
	var m_sewer_brass := _mat("sewer_lock_brass", Color(0.88, 0.72, 0.26), 0.30, 0.85)
	for loc_id in VillageUnderworldScript.SEWER_LOCATIONS.keys():
		var sdef: Dictionary = VillageUnderworldScript.SEWER_LOCATIONS[loc_id]
		var gp: Vector2 = sdef["pos"]
		_add_box_2d(terrain_root_3d, gp, Vector2(18.0, 18.0), 0.0, 1.4, m_curb)
		_add_box_2d(terrain_root_3d, gp, Vector2(14.5, 14.5), 1.4, 1.2, m_iron)
		_add_box_2d(terrain_root_3d, gp, Vector2(11.5, 11.5), 2.0, 0.6, m_sewer_dark)
		for gx in [-3.6, -1.2, 1.2, 3.6]:
			_add_box_2d(terrain_root_3d, gp + Vector2(gx, 0.0), Vector2(0.9, 11.5), 2.1, 1.0, m_iron)
		_add_box_2d(terrain_root_3d, gp, Vector2(11.5, 0.9), 2.1, 1.0, m_iron)
		_add_cyl_2d(terrain_root_3d, gp + Vector2(4.2, 0.0), 1.4, 2.3, 1.4, m_sewer_brass, 1.4, 8)

func _build_tree_3d(parent: Node3D, pos_2d: Vector2, m_trunk: Material, m_leaf1: Material, m_leaf2: Material, scale_f: float = 1.0, variant: int = 0) -> void:
	var tree_files := ["nature/CommonTree_1.obj", "nature/CommonTree_2.obj", "nature/BirchTree_1.obj", "nature/PineTree_1.obj", "nature/CommonTree_3.obj"]
	var t_file: String = tree_files[posmod(variant, tree_files.size())]
	if _add_model_2d(parent, t_file, pos_2d, 0.0, Vector2.ZERO, 34.0 * scale_f, float(variant * 67)) != null:
		return
	_add_cyl_2d(parent, pos_2d, 3.2 * scale_f, 0.0, 11.0 * scale_f, m_trunk, 2.4 * scale_f, 8)
	_add_cyl_2d(parent, pos_2d, 12.0 * scale_f, 8.0 * scale_f, 14.0 * scale_f, m_leaf1, 2.0 * scale_f, 9)
	_add_cyl_2d(parent, pos_2d, 9.0 * scale_f, 16.0 * scale_f, 12.0 * scale_f, m_leaf2, 0.8 * scale_f, 9)

func _build_bench_3d(parent: Node3D, pos_2d: Vector2, m_wood: Material, m_iron: Material, rot_y: float = 0.0) -> void:
	if _add_model_2d(parent, "props/Bench.gltf", pos_2d, 0.0, Vector2(18.0, 7.0), 8.5, rot_y) != null:
		return
	_add_box_2d(parent, pos_2d, Vector2(18.0, 6.0), 2.5, 2.0, m_wood)
	_add_box_2d(parent, pos_2d + Vector2(0, -2.5), Vector2(18.0, 1.5), 4.5, 4.5, m_wood)
	_add_box_2d(parent, pos_2d + Vector2(-7, 0), Vector2(2.0, 6.0), 0.0, 3.0, m_iron)
	_add_box_2d(parent, pos_2d + Vector2(7, 0), Vector2(2.0, 6.0), 0.0, 3.0, m_iron)

# ==============================================================================
# 2. EDIFICIOS SÓLIDOS, INTERIORES, PUERTAS, VENTANAS, ALTILLOS (+1) Y CUTAWAY
# ==============================================================================
func _style_for_building(b_id: String) -> Dictionary:
	var wall_col := Color(0.82, 0.76, 0.64)
	var roof_col := Color(0.68, 0.32, 0.22)
	var floor_col := Color(0.56, 0.40, 0.25)
	var trim_col := Color(0.42, 0.28, 0.16)
	var wall_tex := "town_textures/timber_square_clay.png"
	var wall_norm := ""
	var roof_tex := "town_textures/roof_clay_red_center.png"
	var floor_tex := "town_textures/floor_wood_planks.png"
	if b_id in ["building_church", "building_police", "shop_family_smith", "building_tinker", "building_town_hall"]:
		floor_tex = "town_textures/floor_stone_pattern.png"
	elif b_id == "building_hospital":
		floor_tex = "town_textures/floor_tiles_sand_large.png"
	var roof_norm := ""
	var wall_h: float = 28.0
	var roof_h: float = 14.0

	if b_id == "building_tavern":
		wall_tex = "town_textures/wall_timber_structure_cross.png"
		wall_col = Color(0.86, 0.74, 0.56)
		roof_col = Color(0.66, 0.24, 0.20)
		floor_col = Color(0.52, 0.34, 0.20)
		wall_h = 32.0
		roof_h = 16.0
	elif b_id == "building_hospital":
		wall_tex = "town_textures/wall_brick_small_sand.png"
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.90, 0.94, 0.96)
		roof_col = Color(0.28, 0.54, 0.58)
		floor_col = Color(0.80, 0.86, 0.88)
		trim_col = Color(0.48, 0.58, 0.62)
		wall_h = 30.0
	elif b_id == "building_police":
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.64, 0.68, 0.74)
		roof_col = Color(0.26, 0.34, 0.48)
		floor_col = Color(0.50, 0.52, 0.56)
		trim_col = Color(0.34, 0.38, 0.46)
		wall_tex = "town_textures/wall_brick_stone_center.png"
		wall_norm = ""
		wall_h = 30.0
	elif b_id == "building_church":
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.88, 0.84, 0.78)
		roof_col = Color(0.44, 0.34, 0.58)
		floor_col = Color(0.66, 0.62, 0.58)
		trim_col = Color(0.52, 0.46, 0.42)
		wall_tex = "town_textures/wall_brick_sand_center.png"
		wall_norm = ""
		wall_h = 34.0
		roof_h = 18.0
	elif b_id == "building_town_hall":
		wall_col = Color(0.88, 0.82, 0.72)
		roof_col = Color(0.28, 0.42, 0.62)
		floor_col = Color(0.58, 0.42, 0.26)
		wall_tex = "town_textures/wall_brick_sand_center.png"
		wall_norm = ""
		wall_h = 32.0
		roof_h = 16.0
	elif b_id == "building_candil":
		wall_col = Color(0.56, 0.38, 0.48)
		roof_col = Color(0.58, 0.22, 0.38)
		floor_col = Color(0.44, 0.24, 0.32)
	elif b_id == "building_manor" or b_id == "building_townhouse":
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.84, 0.82, 0.78)
		roof_col = Color(0.26, 0.46, 0.38)
		floor_col = Color(0.56, 0.40, 0.24)
		wall_tex = "town_textures/wall_brick_sand_center.png"
		wall_norm = ""
		wall_h = 32.0
	elif b_id == "building_library":
		wall_tex = "town_textures/timber_square_frame.png"
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.80, 0.70, 0.56)
		roof_col = Color(0.30, 0.44, 0.64)
	elif b_id == "building_school":
		wall_col = Color(0.86, 0.78, 0.62)
		roof_col = Color(0.68, 0.36, 0.24)
	elif b_id == "shop_family_smith" or b_id == "building_tinker":
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.60, 0.58, 0.56)
		roof_col = Color(0.36, 0.34, 0.34)
		floor_col = Color(0.46, 0.44, 0.42)
		wall_tex = "town_textures/wall_stone.png"
		wall_norm = ""
	elif b_id.begins_with("shop_") or b_id.begins_with("mixed_"):
		if (b_id.hash() % 2) == 0:
			wall_tex = "town_textures/wall_timber_structure_cross.png"
		if (b_id.hash() % 3) == 0:
			roof_tex = "town_textures/roof_thatch_center.png"
		wall_col = Color(0.84, 0.74, 0.56)
		roof_col = Color(0.68, 0.34, 0.22)
	elif b_id.begins_with("player_house_"):
		wall_tex = "town_textures/timber_square_planks.png"
		roof_tex = "town_textures/roof_thatch_center.png"
		wall_col = Color(0.86, 0.76, 0.58)
		roof_col = Color(0.28, 0.52, 0.36)

	return {
		"wall_mat": _mat("wall_" + b_id, wall_col, 0.86, 0.04, Color.BLACK, 0.0, wall_tex, wall_norm, 0.70),
		"roof_mat": _mat("roof_" + b_id, roof_col, 0.80, 0.06, Color.BLACK, 0.0, roof_tex, roof_norm, 0.75),
		"floor_mat": _mat("floor_" + b_id, floor_col, 0.88, 0.02, Color.BLACK, 0.0, floor_tex, "", 0.85),
		"trim_mat": _mat("trim_" + b_id, trim_col, 0.84, 0.05, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.85),
		"wall_h": wall_h,
		"roof_h": roof_h,
	}

func rebuild_buildings_3d() -> void:
	_clear_children(buildings_root_3d)
	_building_records_3d.clear()
	_door_nodes_3d.clear()
	_window_nodes_3d.clear()
	_chest_nodes_3d.clear()
	_morgue_body_nodes_3d.clear()
	_jail_gate_pivot_3d = null
	if vm == null:
		return

	var m_wood := _mat("prop_wood", Color(0.45, 0.29, 0.16), 0.85, 0.02)
	var m_dark_wood := _mat("prop_dark_wood", Color(0.32, 0.20, 0.11), 0.88, 0.02)
	var m_iron := _mat("wrought_iron", Color(0.22, 0.24, 0.28), 0.45, 0.75)
	var m_gold := _mat("brass_gold", Color(0.85, 0.68, 0.24), 0.35, 0.82)
	var m_glass := _mat("win_glass", Color(0.56, 0.82, 0.96, 0.75), 0.15, 0.25)

	for b in vm.building_footprints:
		var b_id: String = str(b.get("id", ""))
		var rect: Rect2 = b["rect"]
		var center: Vector2 = rect.get_center()
		var sz: Vector2 = rect.size
		var half: Vector2 = sz * 0.5
		var door_pos: Vector2 = b["door_pos"]
		var door_south: bool = bool(b["door_south"])
		var style: Dictionary = _style_for_building(b_id)
		# Altura de muro algo mayor y distinta en cada edificio (+0..10 px), para que no parezcan clones.
		var wall_h: float = float(style["wall_h"]) + 4.0 + float(absi(b_id.hash()) % 6) * 2.0
		var roof_h: float = float(style["roof_h"])
		var m_wall: Material = style["wall_mat"]
		var m_roof: Material = style["roof_mat"]
		var m_floor: Material = style["floor_mat"]
		var m_trim: Material = style["trim_mat"]

		var b_root := Node3D.new()
		b_root.name = "B3D_" + b_id
		buildings_root_3d.add_child(b_root)

		# 1. Losa de suelo 3D y zócalo exterior
		_add_box_2d(b_root, center, sz + Vector2(4, 4), 0.0, 1.5, m_trim)
		_add_box_2d(b_root, center, sz - Vector2(2, 2), 1.5, 1.0, m_floor)

		# 2. Muros perimetrales 3D con hueco de puerta y dintel superior
		var wall_t: float = 6.5
		var door_w: float = 40.0
		for d_entry in vm.building_doors:
			if str(d_entry.get("building_id", "")) == b_id:
				door_w = float(d_entry.get("width", 40.0))
				break

		# Muro izquierdo y derecho + pilares de esquina
		_add_box_2d(b_root, Vector2(rect.position.x, center.y), Vector2(wall_t, sz.y), 2.0, wall_h, m_wall)
		_add_box_2d(b_root, Vector2(rect.end.x, center.y), Vector2(wall_t, sz.y), 2.0, wall_h, m_wall)
		for c_pt in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
			_add_box_2d(b_root, c_pt, Vector2(wall_t + 2.0, wall_t + 2.0), 2.0, wall_h + 1.0, m_trim)

		# Muro cerrado (opuesto a la puerta): si es el muro sur (más cercano a la cámara), se rebaja al abrir el tejado (Cutaway)
		var closed_y: float = (center.y - half.y) if door_south else (center.y + half.y)
		if door_south:
			_add_box_2d(b_root, Vector2(center.x, closed_y), Vector2(sz.x, wall_t), 2.0, wall_h, m_wall)
		else:
			_add_box_2d(b_root, Vector2(center.x, closed_y), Vector2(sz.x, wall_t), 2.0, 9.0, m_wall)

		# Muro de la fachada con hueco de puerta + dintel sobre la puerta
		var door_y: float = door_pos.y
		var door_left_x: float = door_pos.x - door_w * 0.5
		var door_right_x: float = door_pos.x + door_w * 0.5
		var left_w: float = maxf(6.0, door_left_x - rect.position.x)
		var right_w: float = maxf(6.0, rect.end.x - door_right_x)
		_add_box_2d(b_root, Vector2(rect.position.x + left_w * 0.5, door_y), Vector2(left_w, wall_t), 2.0, wall_h, m_wall)
		_add_box_2d(b_root, Vector2(rect.end.x - right_w * 0.5, door_y), Vector2(right_w, wall_t), 2.0, wall_h, m_wall)
		# Jambas y dintel de la puerta
		_add_box_2d(b_root, Vector2(door_left_x, door_y), Vector2(3.5, wall_t + 2.0), 2.0, wall_h, m_trim)
		_add_box_2d(b_root, Vector2(door_right_x, door_y), Vector2(3.5, wall_t + 2.0), 2.0, wall_h, m_trim)
		_add_box_2d(b_root, Vector2(door_pos.x, door_y), Vector2(door_w + 4.0, wall_t + 1.5), 2.0 + wall_h * 0.72, wall_h * 0.28, m_trim)

		# 3. Puerta abatible 3D sincronizada con `vm.building_doors`
		for d_entry in vm.building_doors:
			if str(d_entry.get("building_id", "")) == b_id:
				var hinge_pos := Vector2(door_left_x + 2.0, door_y)
				var pivot := Node3D.new()
				pivot.name = "DoorPivot_" + b_id
				pivot.position = to_3d(hinge_pos, 2.0)
				b_root.add_child(pivot)
				var leaf_w: float = maxf(18.0, door_w - 4.0)
				var leaf_h: float = wall_h * 0.70
				if not _is_headless:
					var door_leaf := _make_texture_panel(leaf_w, leaf_h, 3.0, _panel_mat("door_wood", "town_textures/door_wood.png", false))
					door_leaf.position = Vector3((leaf_w * 0.5) * WORLD_SCALE, (leaf_h * 0.5 * WORLD_SCALE) / _cos_p, 0.0)
					pivot.add_child(door_leaf)
				var lock_badge := MeshInstance3D.new()
				var lb_bm := BoxMesh.new()
				lb_bm.size = size_3d(Vector2(3.5, 4.2), 3.5)
				lock_badge.mesh = lb_bm
				lock_badge.material_override = m_gold
				lock_badge.position = Vector3((leaf_w - 4.0) * WORLD_SCALE, (leaf_h * 0.48 * WORLD_SCALE) / _cos_p, 0.0)
				pivot.add_child(lock_badge)
				_door_nodes_3d.append({"entry": d_entry, "pivot": pivot, "lock_badge": lock_badge, "door_south": door_south})
				break

		# 4. Ventana 3D con postigos sincronizada con `vm.building_windows`
		for w_entry in vm.building_windows:
			if str(w_entry.get("building_id", "")) == b_id:
				var w_pos: Vector2 = w_entry.get("pos", Vector2.ZERO)
				var pane: Node3D = null
				if not _is_headless:
					pane = _make_texture_panel(13.0, 12.0, wall_t + 2.4, _panel_mat("win_day", "town_textures/window_square_divided.png", false))
					pane.position = to_3d(w_pos, 10.0 + 6.0)
					b_root.add_child(pane)
				else:
					pane = _add_box_2d(b_root, w_pos, Vector2(11.0, wall_t + 2.4), 12.0, 8.0, m_glass)
				var shutter := _add_box_2d(b_root, w_pos, Vector2(12.0, wall_t + 2.8), 12.0, 8.2, m_dark_wood)
				_window_nodes_3d.append({"entry": w_entry, "pane": pane, "shutter": shutter})
				break

		# 5. Mobiliario interior 3D específico de cada edificio
		_populate_building_interior_3d(b_root, b_id, rect, door_south, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)

		# 6. Altillo / Primer Piso (+1) 3D (visible cuando estás en nivel +1 o cerca)
		var loft_root := Node3D.new()
		loft_root.name = "Loft3D_" + b_id
		loft_root.visible = false
		b_root.add_child(loft_root)
		var loft_y: float = center.y + (-half.y * 0.42 if door_south else half.y * 0.42)
		_add_box_2d(loft_root, Vector2(center.x, loft_y), Vector2(sz.x - 10.0, sz.y * 0.42), wall_h - 3.0, 2.0, m_wood)
		_add_box_2d(loft_root, Vector2(center.x, loft_y + (sz.y * 0.20 if door_south else -sz.y * 0.20)), Vector2(sz.x - 12.0, 2.5), wall_h - 1.0, 6.0, m_dark_wood)
		_add_model_2d(loft_root, "props/Chest_Wood.gltf", Vector2(center.x - sz.x * 0.22, loft_y), wall_h - 1.0, Vector2(12.0, 8.0), 6.5)

		# 7. Tejado a dos aguas con alero (se retira en modo Cutaway). Cada edificio varía según su id:
		#    orientación de la cumbrera, altura, ala más baja en los edificios anchos, porche sobre la puerta y chimenea.
		var roof_cap := Node3D.new()
		roof_cap.name = "RoofCap_" + b_id
		b_root.add_child(roof_cap)
		var hv: int = absi(b_id.hash())
		var ov: float = 6.0
		var short_side: float = minf(sz.x, sz.y)
		var rh: float = clampf(short_side * (0.40 + float(hv % 5) * 0.04), 16.0, 46.0)
		var ridge_x: bool = sz.x >= sz.y
		if absf(sz.x - sz.y) < 12.0:
			ridge_x = (hv % 2) == 0
		var roof_base_h: float = wall_h + 2.0
		if sz.x > 118.0 and not (b_id in ["building_church"]):
			# Cuerpo principal + ala más baja (rompe la caja: silueta en L vista desde arriba)
			var main_w: float = sz.x * 0.60
			var wing_w: float = sz.x - main_w
			var main_left: bool = (hv % 2) == 0
			var main_cx: float = rect.position.x + (main_w * 0.5 if main_left else wing_w + main_w * 0.5)
			var wing_cx: float = rect.position.x + (main_w + wing_w * 0.5 if main_left else wing_w * 0.5)
			_add_prism_2d(roof_cap, Vector2(main_cx, center.y), Vector2(main_w + ov * 2.0, sz.y + ov * 2.0), roof_base_h, rh, m_roof, false)
			_add_prism_2d(roof_cap, Vector2(wing_cx, center.y), Vector2(wing_w + ov, sz.y * 0.86 + ov), roof_base_h - 2.0, rh * 0.62, m_roof, true)
		else:
			_add_prism_2d(roof_cap, center, sz + Vector2(ov * 2.0, ov * 2.0), roof_base_h, rh, m_roof, ridge_x)
		# Remate de madera bajo el alero (se ve con el tejado puesto y quitado)
		if not door_south:
			_add_box_2d(roof_cap, Vector2(center.x, closed_y), Vector2(sz.x, wall_t), 11.0, wall_h - 9.0, m_wall)
			_add_box_2d(roof_cap, Vector2(center.x, rect.end.y), Vector2(sz.x + 2.0, 3.0), wall_h, 2.5, m_trim)
		else:
			_add_box_2d(b_root, Vector2(center.x, rect.end.y), Vector2(sz.x + 2.0, 3.0), wall_h, 2.5, m_trim)
		_add_box_2d(b_root, Vector2(center.x, rect.position.y), Vector2(sz.x + 2.0, 3.0), wall_h, 2.5, m_trim)
		# Porche sobre la puerta en tiendas y casas (tejadillo inclinado sobre dos postes)
		if (hv % 3) != 0 and not (b_id in ["building_church", "building_police", "building_hospital"]):
			var porch_dir: float = 1.0 if door_south else -1.0
			var porch_c := Vector2(door_pos.x, door_y + porch_dir * 9.0)
			_add_box_2d(b_root, porch_c, Vector2(door_w + 16.0, 18.0), wall_h * 0.70, 2.5, m_roof)
			for px in [-1.0, 1.0]:
				_add_box_2d(b_root, Vector2(door_pos.x + px * (door_w * 0.5 + 6.0), door_y + porch_dir * 16.0), Vector2(2.5, 2.5), 2.0, wall_h * 0.70 - 2.0, m_trim)
		# Chimenea sobre la cumbrera
		var ch_off := Vector2(half.x * (0.30 if (hv % 2) == 0 else -0.30), -half.y * 0.15)
		_add_model_2d(roof_cap, "fantasy_town/chimney.glb", center + ch_off, roof_base_h + rh * 0.35, Vector2(9.0, 9.0), rh * 0.9)
		# Campanario de la iglesia: torre de piedra con chapitel junto a la fachada
		if b_id == "building_church":
			var tower_c := Vector2(center.x, (rect.end.y - 16.0) if door_south else (rect.position.y + 16.0))
			_add_box_2d(roof_cap, tower_c, Vector2(26.0, 22.0), roof_base_h, rh + 22.0, m_wall)
			_add_pyramid_2d(roof_cap, tower_c, Vector2(32.0, 28.0), roof_base_h + rh + 22.0, 34.0, m_roof)

		_building_records_3d.append({
			"id": b_id,
			"rect": rect,
			"root": b_root,
			"roof_cap": roof_cap,
			"loft_root": loft_root,
		})

	_merge_building_meshes()

	# Cofres domésticos 3D sincronizados con `vm.house_chests`
	for ch in vm.house_chests:
		var c_pos: Vector2 = ch.get("pos", Vector2.ZERO)
		var ch_root := Node3D.new()
		buildings_root_3d.add_child(ch_root)
		_add_model_2d(ch_root, "props/Chest_Wood.gltf", c_pos, 2.0, Vector2(12.0, 8.5), 7.5)
		var lid := _add_box_2d(ch_root, c_pos, Vector2(11.4, 7.8), 7.5, 1.8, m_gold)
		_chest_nodes_3d.append({"entry": ch, "lid": lid})

## Rendimiento: junta en una sola malla por material las piezas quietas de cada edificio (muros, suelos, muebles).
## Quedan aparte y se siguen moviendo: puertas, ventanas y postigos, cuerpos de la morgue, reja del calabozo, el tejado
## (que se abre) y el altillo (que aparece), estos dos juntados cada uno por su lado.
func _merge_building_meshes() -> void:
	if _is_headless:
		return
	var excl: Dictionary = {}
	for d in _door_nodes_3d:
		for k in ["pivot", "lock_badge"]:
			if d.get(k) is Node:
				excl[d[k]] = true
	for w in _window_nodes_3d:
		for k in ["pane", "shutter"]:
			if w.get(k) is Node:
				excl[w[k]] = true
	for mb in _morgue_body_nodes_3d:
		excl[mb] = true
	if _jail_gate_pivot_3d != null:
		excl[_jail_gate_pivot_3d] = true
	for rec in _building_records_3d:
		var sub: Array = [rec["roof_cap"], rec["loft_root"]]
		var ex_b: Dictionary = excl.duplicate()
		for sn in sub:
			ex_b[sn] = true
		_merge_meshes_under(rec["root"], ex_b)
		for sn in sub:
			_merge_meshes_under(sn, excl)

func _merge_meshes_under(root: Node3D, excl: Dictionary) -> void:
	var found: Array = []
	_collect_merge_meshes(root, root, excl, found)
	if found.size() < 2:
		return
	var inv: Transform3D = root.global_transform.affine_inverse()
	var tools: Dictionary = {} # clave -> {"st": SurfaceTool, "mat": Material, "shadow": int}
	for mi in found:
		var xf: Transform3D = inv * mi.global_transform
		for si in range(mi.mesh.get_surface_count()):
			var mat: Material = mi.material_override
			if mat == null:
				mat = mi.get_surface_override_material(si)
			if mat == null:
				mat = mi.mesh.surface_get_material(si)
			var fmt: int = 0
			var arrs: Array = mi.mesh.surface_get_arrays(si)
			for ai in range(arrs.size()):
				if arrs[ai] != null:
					fmt |= 1 << ai
			var key := "%d_%d_%d" % [mat.get_instance_id() if mat != null else 0, fmt, int(mi.cast_shadow)]
			if not tools.has(key):
				tools[key] = {"st": SurfaceTool.new(), "mat": mat, "shadow": int(mi.cast_shadow)}
			(tools[key]["st"] as SurfaceTool).append_from(mi.mesh, si, xf)
		mi.mesh = null # el nodo se queda (por si tiene hijos), pero ya no se dibuja
	var by_shadow: Dictionary = {}
	for key in tools:
		var t: Dictionary = tools[key]
		var am: ArrayMesh = by_shadow.get(t["shadow"], null)
		if am == null:
			am = ArrayMesh.new()
			by_shadow[t["shadow"]] = am
		(t["st"] as SurfaceTool).commit(am)
		am.surface_set_material(am.get_surface_count() - 1, t["mat"])
	for sh in by_shadow:
		var out := MeshInstance3D.new()
		out.name = "Juntado"
		out.mesh = by_shadow[sh]
		out.cast_shadow = sh
		root.add_child(out)

func _collect_merge_meshes(n: Node, root: Node, excl: Dictionary, out: Array) -> void:
	for c in n.get_children():
		if excl.has(c):
			continue
		if c is Node3D and not (c as Node3D).visible:
			continue
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			var ok: bool = mi.mesh != null and mi.skin == null and not (mi.mesh is ArrayMesh and (mi.mesh as ArrayMesh).get_blend_shape_count() > 0)
			if ok:
				for si in range(mi.mesh.get_surface_count()):
					if mi.mesh is ArrayMesh and (mi.mesh as ArrayMesh).surface_get_primitive_type(si) != Mesh.PRIMITIVE_TRIANGLES:
						ok = false
			if ok:
				out.append(mi)
		_collect_merge_meshes(c, root, excl, out)

func _populate_building_interior_3d(b_root: Node3D, b_id: String, rect: Rect2, door_south: bool, wall_h: float, m_wall: Material, m_trim: Material, m_wood: Material, m_dark_wood: Material, m_iron: Material, m_gold: Material) -> void:
	var c: Vector2 = rect.get_center()
	var m_bed := _mat("bed_linen", Color(0.84, 0.28, 0.24), 0.85, 0.0)
	var m_pillow := _mat("bed_pillow", Color(0.94, 0.92, 0.86), 0.85, 0.0)
	var m_steel := _mat("morgue_steel", Color(0.74, 0.80, 0.84), 0.30, 0.78)
	var m_shroud := _mat("corpse_shroud", Color(0.82, 0.84, 0.78), 0.90, 0.0)
	var m_felt := _mat("green_felt", Color(0.16, 0.48, 0.26), 0.85, 0.0)
	var m_ember := _mat("forge_ember", Color(1.0, 0.42, 0.12), 0.4, 0.0, Color(1.0, 0.38, 0.08), 2.2)

	match b_id:
		"building_tavern":
			# Tabique divisorio de habitaciones y barra de la posada
			_add_box_2d(b_root, Vector2(362, -222), Vector2(96, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_box_2d(b_root, Vector2(502, -222), Vector2(116, 5.5), 2.0, wall_h * 0.85, m_wall)
			# Barra del tabernero y barriles reales 3D
			_add_box_2d(b_root, Vector2(358, -196), Vector2(48, 9), 2.0, 9.5, m_dark_wood)
			_add_model_2d(b_root, "props/Mug.gltf", Vector2(350, -196), 11.5, Vector2(4.0, 4.0), 4.0)
			_add_model_2d(b_root, "props/Chalice.gltf", Vector2(366, -196), 11.5, Vector2(4.0, 4.0), 4.5)
			for bx in [-18.0, 0.0, 18.0]:
				_add_model_2d(b_root, "props/Barrel.gltf", Vector2(358 + bx, -210), 2.0, Vector2(9.5, 9.5), 10.5)
			# Mesa de póker y mesa de billar + sillas 3D
			_add_model_2d(b_root, "props/Table_Large.gltf", vm._tavern_games_pos, 2.0, Vector2(22, 16), 6.8)
			_add_box_2d(b_root, vm._tavern_games_pos, Vector2(18, 12), 8.5, 0.8, m_felt)
			_add_model_2d(b_root, "props/Chair_1.gltf", vm._tavern_games_pos + Vector2(-14, 0), 2.0, Vector2(6.5, 6.5), 8.5, 90.0)
			_add_model_2d(b_root, "props/Chair_1.gltf", vm._tavern_games_pos + Vector2(14, 0), 2.0, Vector2(6.5, 6.5), 8.5, -90.0)
			_add_model_2d(b_root, "props/Table_Large.gltf", vm._tavern_pool_pos, 2.0, Vector2(26, 16), 6.8)
			_add_box_2d(b_root, vm._tavern_pool_pos, Vector2(22, 12), 8.8, 0.8, m_felt)
			# Camas de huéspedes y cama de alquiler
			for bp in [Vector2(435, -252), Vector2(468, -252), Vector2(502, -252), vm._tavern_bed_pos]:
				_build_bed_3d(b_root, bp, m_wood, m_bed, m_pillow)
		"building_hospital":
			# Tabique entre Urgencias y Morgue Forense
			_add_box_2d(b_root, Vector2(704, 152), Vector2(56, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_box_2d(b_root, Vector2(786, 152), Vector2(56, 5.5), 2.0, wall_h * 0.85, m_wall)
			_build_bed_3d(b_root, vm._hospital_bed_pos, m_steel, _mat("hosp_sheet", Color(0.32, 0.72, 0.78), 0.8, 0.0), m_pillow)
			_add_model_2d(b_root, "props/Shelf_Small_Bottles.gltf", vm._hospital_bed_pos + Vector2(-18, -10), 2.0, Vector2(12.0, 6.0), 13.0)
			# 3 Camillas de acero inoxidable de la Morgue + cuerpos cubiertos
			for mp in vm._morgue_table_positions:
				_add_box_2d(b_root, mp, Vector2(14.0, 22.0), 2.0, 7.5, m_steel)
				var body_n := Node3D.new()
				body_n.visible = false
				b_root.add_child(body_n)
				_add_box_2d(body_n, mp, Vector2(9.0, 17.0), 9.5, 4.2, m_shroud)
				_add_box_2d(body_n, mp + Vector2(0, -6.0), Vector2(5.5, 5.5), 13.5, 3.0, m_shroud)
				_morgue_body_nodes_3d.append(body_n)
		"building_police":
			# Tabique de barrotes de acero del calabozo y puerta de reja en Vector2(902, 152)
			_add_model_2d(b_root, "graveyard/iron-fence.glb", Vector2(874, 152), 2.0, Vector2(36, 4.5), wall_h * 0.85)
			_add_model_2d(b_root, "graveyard/iron-fence.glb", Vector2(940, 152), 2.0, Vector2(52, 4.5), wall_h * 0.85)
			_jail_gate_pivot_3d = Node3D.new()
			_jail_gate_pivot_3d.position = to_3d(Vector2(892, 152), 2.0)
			b_root.add_child(_jail_gate_pivot_3d)
			var gate_mesh := MeshInstance3D.new()
			var gm_box := BoxMesh.new()
			gm_box.size = size_3d(Vector2(20.0, 3.0), wall_h * 0.75)
			gate_mesh.mesh = gm_box
			gate_mesh.material_override = m_iron
			gate_mesh.position = Vector3(10.0 * WORLD_SCALE, (wall_h * 0.375 * WORLD_SCALE) / _cos_p, 0.0)
			_jail_gate_pivot_3d.add_child(gate_mesh)
			# Camastro del calabozo, jaula y escritorio del comisario
			_build_bed_3d(b_root, vm._jail_cell_pos + Vector2(-14, 8), m_iron, m_dark_wood, m_pillow)
			_add_model_2d(b_root, "props/Cage_Small.gltf", vm._jail_cell_pos + Vector2(16, 6), 2.0, Vector2(9.0, 9.0), 10.0)
			_add_model_2d(b_root, "props/Workbench_Drawers.gltf", vm._police_center + Vector2(18, -18), 2.0, Vector2(22, 12), 8.5)
			_add_model_2d(b_root, "props/WeaponStand.gltf", vm._police_center + Vector2(-24, -18), 2.0, Vector2(14, 7), 11.0)
		"building_church":
			# Altar mayor con velas y bancos de madera 3D
			_add_model_2d(b_root, "graveyard/altar-stone.glb", vm._church_altar_pos, 2.0, Vector2(32.0, 14.0), 11.0)
			_add_model_2d(b_root, "props/CandleStick_Triple.gltf", vm._church_altar_pos + Vector2(-10, 0), 12.0, Vector2(5.0, 5.0), 6.0)
			_add_model_2d(b_root, "props/CandleStick_Triple.gltf", vm._church_altar_pos + Vector2(10, 0), 12.0, Vector2(5.0, 5.0), 6.0)
			for py in [-12.0, 4.0]:
				for px in [-26.0, 26.0]:
					_add_model_2d(b_root, "props/Bench.gltf", c + Vector2(px, py), 2.0, Vector2(26.0, 7.0), 6.5)
		"building_library":
			var m_dir: float = -1.0 if door_south else 1.0
			for sx in [-40.0, -14.0, 14.0, 40.0]:
				_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(sx, 34.0 * m_dir), 2.0, Vector2(22.0, 8.0), 22.0)
			_add_model_2d(b_root, "props/Table_Large.gltf", VillageCulture.reading_spot(), 2.0, Vector2(24.0, 14.0), 7.5)
			_add_model_2d(b_root, "props/BookStand.gltf", VillageCulture.reading_spot() + Vector2(-18, -8), 2.0, Vector2(8.0, 8.0), 11.0)
		"building_school":
			var m_dir2: float = -1.0 if door_south else 1.0
			for p in [Vector2(-30, 6), Vector2(0, 6), Vector2(30, 6), Vector2(-30, 26), Vector2(0, 26), Vector2(30, 26)]:
				_add_model_2d(b_root, "props/Bench.gltf", c + Vector2(p.x, p.y * m_dir2), 2.0, Vector2(16.0, 9.0), 6.5)
			_add_box_2d(b_root, c + Vector2(0, -26.0 * m_dir2), Vector2(54.0, 4.0), 8.0, 14.0, _mat("chalkboard", Color(0.14, 0.28, 0.18), 0.9, 0.0))
		"shop_family_smith":
			# Fragua encendida, yunque real sobre tronco, piedra de afilar, soporte de armas y mostrador
			_add_box_2d(b_root, c + Vector2(-36, -16), Vector2(22.0, 18.0), 2.0, 18.0, m_trim)
			_add_box_2d(b_root, c + Vector2(-36, -14), Vector2(12.0, 10.0), 5.0, 6.0, m_ember)
			_add_model_2d(b_root, "props/Anvil_Log.gltf", c + Vector2(-14, -12), 2.0, Vector2(11.0, 9.0), 9.0)
			_add_model_2d(b_root, "props/Whetstone.gltf", c + Vector2(26, -14), 2.0, Vector2(10.0, 8.0), 9.5)
			_add_model_2d(b_root, "props/WeaponStand.gltf", c + Vector2(36, 12), 2.0, Vector2(16.0, 8.0), 12.0)
			_add_model_2d(b_root, "props/Workbench.gltf", c + Vector2(0, -16), 2.0, Vector2(26.0, 11.0), 8.5)
		"mixed_family_herbalist":
			_add_box_2d(b_root, c + Vector2(-42, 4), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_box_2d(b_root, c + Vector2(42, 4), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_model_2d(b_root, "props/Workbench_Drawers.gltf", c + Vector2(0, -10), 2.0, Vector2(26.0, 11.0), 8.5)
			_add_model_2d(b_root, "props/Cauldron.gltf", c + Vector2(-24, -14), 2.0, Vector2(11.0, 11.0), 9.0)
			_add_model_2d(b_root, "props/Shelf_Small_Bottles.gltf", c + Vector2(24, -16), 2.0, Vector2(14.0, 6.0), 13.0)
			_build_bed_3d(b_root, c + Vector2(-36, 26), m_wood, m_bed, m_pillow)
			_build_bed_3d(b_root, c + Vector2(36, 26), m_wood, m_bed, m_pillow)
			_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, 24), 2.0, Vector2(18.0, 12.0), 7.0)
		"mixed_family_tinker":
			# Tabiques internos, banco de trabajo, camas traseras y mesa
			_add_box_2d(b_root, c + Vector2(-42, 4), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_box_2d(b_root, c + Vector2(42, 4), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_model_2d(b_root, "props/Workbench_Drawers.gltf", c + Vector2(0, -10), 2.0, Vector2(26.0, 11.0), 8.5)
			_add_model_2d(b_root, "props/Anvil.gltf", c + Vector2(22, -16), 2.0, Vector2(9.0, 7.0), 7.5)
			_build_bed_3d(b_root, c + Vector2(-36, 26), m_wood, m_bed, m_pillow)
			_build_bed_3d(b_root, c + Vector2(36, 26), m_wood, m_bed, m_pillow)
			_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, 24), 2.0, Vector2(18.0, 12.0), 7.0)
			# Bloque FIS2 (§2.1): Terminal Lógica Electromecánica física sobre una mesa dentro del taller (TINKER_TERMINAL_POS)
			var t_pos: Vector2 = VillageCulture.TINKER_TERMINAL_POS
			var m_copper := _mat("tinker_copper", Color(0.84, 0.48, 0.22), 0.35, 0.78)
			var m_screen := _mat("tinker_screen", Color(0.32, 0.96, 0.82), 0.2, 0.0, Color(0.24, 0.92, 0.76), 2.8)
			var m_card := _mat("tinker_card", Color(0.92, 0.86, 0.70), 0.85, 0.0)
			if _add_model_2d(b_root, "props/Table_Large.gltf", t_pos, 2.0, Vector2(24.0, 15.0), 8.0) == null:
				_add_box_2d(b_root, t_pos, Vector2(24.0, 15.0), 2.0, 8.0, m_dark_wood)
			_add_box_2d(b_root, t_pos + Vector2(0, -1.0), Vector2(18.0, 10.5), 10.0, 12.5, m_iron) # Chasis de acero alto
			_add_box_2d(b_root, t_pos + Vector2(0, -1.0), Vector2(16.0, 8.8), 11.2, 11.8, m_gold) # Bastidor de latón
			_add_box_2d(b_root, t_pos + Vector2(-1.6, 3.8), Vector2(10.5, 2.6), 12.5, 8.2, m_screen) # Visor fosforescente grande hacia cámara
			_add_box_2d(b_root, t_pos + Vector2(0, 4.6), Vector2(13.0, 3.8), 10.0, 2.4, m_iron) # Teclado mecánico frontal
			_add_cyl_2d(b_root, t_pos + Vector2(4.8, -1.2), 2.8, 22.8, 6.0, m_card, 2.8, 10) # Tambor de tarjetas perforadas
			_add_cyl_2d(b_root, t_pos + Vector2(-4.8, -1.6), 2.2, 22.8, 5.5, m_copper, 2.2, 8) # Bobina de relés
			if not _is_headless:
				var term_lt := OmniLight3D.new()
				term_lt.position = to_3d(t_pos + Vector2(0, 2.0), 18.0)
				term_lt.light_color = Color(0.35, 0.96, 0.82)
				term_lt.light_energy = 0.95
				term_lt.omni_range = 1.8
				b_root.add_child(term_lt)
			# Bloque FIS2 (§2.2): Cuadro Eléctrico físico en la pared exterior norte del taller (TINKER_GRID_PANEL_POS)
			var gp_pos: Vector2 = VillageCulture.TINKER_GRID_PANEL_POS
			_add_cyl_2d(b_root, gp_pos + Vector2(5.5, 0.0), 1.2, 2.0, 34.0, m_iron, 1.2, 8) # Tubo de acometida vertical
			_add_box_2d(b_root, gp_pos + Vector2(0, 1.5), Vector2(16.0, 7.0), 22.0, 16.0, m_iron) # Armario metálico en el muro norte
			_add_box_2d(b_root, gp_pos + Vector2(0, 3.0), Vector2(13.6, 5.5), 23.5, 13.0, m_dark_wood) # Placa aislante
			_add_cyl_2d(b_root, gp_pos + Vector2(-4.4, 5.2), 2.2, 25.0, 11.5, m_copper, 2.2, 8) # Bobina izq
			_add_cyl_2d(b_root, gp_pos + Vector2(4.4, 5.2), 2.2, 25.0, 11.5, m_copper, 2.2, 8) # Bobina der
			for sx in [-2.6, 0.0, 2.6]:
				_add_box_2d(b_root, gp_pos + Vector2(sx, 6.2), Vector2(1.5, 3.5), 27.0, 6.5, m_gold) # 3 palancas seccionadoras
			if is_instance_valid(_grid_panel_bulb_3d):
				_grid_panel_bulb_3d.queue_free()
			_grid_panel_bulb_3d = _add_cyl_2d(buildings_root_3d, gp_pos + Vector2(0, 4.5), 2.6, 38.0, 4.5, m_screen, 2.0, 8)
		"building_mansion":
			# Mansión señorial (f1): estudio con escritorio en (1275, -444), salón y alcoba
			var study_p := Vector2(1275.0, -444.0)
			if _add_model_2d(b_root, "props/Workbench_Drawers.gltf", study_p, 2.0, Vector2(24.0, 14.0), 8.2) == null:
				_add_box_2d(b_root, study_p, Vector2(24.0, 14.0), 2.0, 8.2, m_dark_wood)
			_add_model_2d(b_root, "props/Chair_1.gltf", study_p + Vector2(0, -12), 2.0, Vector2(6.5, 6.5), 8.5)
			_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, -8), 2.0, Vector2(30.0, 14.0), 7.5)
			_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(-36, -38), 2.0, Vector2(20.0, 9.0), 16.0)
			_build_bed_3d(b_root, c + Vector2(56, -24), m_wood, m_bed, m_pillow)
			_build_bed_3d(b_root, c + Vector2(56, 18), m_wood, m_bed, m_pillow)
		"building_town_hall":
			# Ayuntamiento (n4): mesa municipal en (764, -444), urna y estanterías
			var desk_p: Vector2 = c + Vector2(0, -24)
			if _add_model_2d(b_root, "props/Table_Large.gltf", desk_p, 2.0, Vector2(28.0, 14.0), 8.2) == null:
				_add_box_2d(b_root, desk_p, Vector2(28.0, 14.0), 2.0, 8.2, m_dark_wood)
			_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-42, 6), 2.0, Vector2(16.0, 10.0), 12.0)
			_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(36, -18), 2.0, Vector2(18.0, 10.0), 15.0)
		_:
			if b_id.begins_with("shop_"):
				var stall_y: float = -14.0 if door_south else 14.0
				_add_model_2d(b_root, "props/Workbench_Drawers.gltf", c + Vector2(0, stall_y), 2.0, Vector2(28.0, 11.0), 8.5)
				_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-28, stall_y), 2.0, Vector2(14.0, 10.0), 13.0)
				_add_model_2d(b_root, "props/Barrel_Apples.gltf", c + Vector2(26, stall_y), 2.0, Vector2(9.5, 9.5), 9.5)
			elif b_id.begins_with("house_") or b_id.begins_with("player_house_"):
				_build_bed_3d(b_root, c + Vector2(-30, -18), m_wood, m_bed, m_pillow)
				if not b_id.begins_with("player_house_"):
					_build_bed_3d(b_root, c + Vector2(30, -18), m_wood, m_bed, m_pillow)
				_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, -2), 2.0, Vector2(20.0, 13.0), 7.0)
				_add_model_2d(b_root, "props/Chair_1.gltf", c + Vector2(-14, -2), 2.0, Vector2(6.5, 6.5), 8.5, 90.0)
				_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(0, -24), 2.0, Vector2(16.0, 7.0), 16.0)
			else:
				# Edificios cívicos, gremios de solares (panadería, sastrería, taller, albergue, El Candil, mansión)
				_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, -10 if door_south else 10), 2.0, Vector2(28.0, 12.0), 7.5)
				_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-32, 12 if door_south else -12), 2.0, Vector2(18.0, 10.0), 13.0)
				_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(32, 12 if door_south else -12), 2.0, Vector2(18.0, 10.0), 15.0)

func _build_bed_3d(parent: Node3D, pos_2d: Vector2, m_frame: Material, m_blanket: Material, m_pillow: Material) -> void:
	if not _is_headless:
		var bed := _add_model_2d(parent, "props/Bed_Twin1.gltf", pos_2d, 2.0, Vector2(15.0, 21.0), 8.5)
		if bed != null:
			return
	_add_box_2d(parent, pos_2d, Vector2(15.0, 21.0), 2.0, 4.5, m_frame)
	_add_box_2d(parent, pos_2d + Vector2(0, 2.0), Vector2(13.5, 15.0), 6.5, 2.0, m_blanket)
	_add_box_2d(parent, pos_2d + Vector2(0, -6.5), Vector2(11.0, 4.5), 6.5, 2.2, m_pillow)

# ==============================================================================
# 3. SOLARES VACÍOS Y OBRAS EN CONSTRUCCIÓN (`VillageLots.LOTS`)
# ==============================================================================
func rebuild_lots_3d() -> void:
	_clear_children(lots_root_3d)
	if vm == null:
		return
	var m_stake := _mat("lot_stake", Color(0.54, 0.36, 0.18), 0.88, 0.02)
	var m_scaffold := _mat("lot_scaffold", Color(0.68, 0.50, 0.28), 0.85, 0.02)
	var m_found := _mat("lot_foundation", Color(0.52, 0.50, 0.46), 0.90, 0.02)

	for l_entry in VillageLots.LOTS:
		var l_dict: Dictionary = l_entry
		var id: String = str(l_dict["id"])
		var st: Dictionary = VillageLots.lot(vm, id)
		var status: String = str(st.get("status", "empty"))
		if status == "built":
			continue
		var c: Vector2 = VillageLots.lot_def(id)["center"]
		var sz_l: Vector2 = l_dict["size"]
		var h: Vector2 = sz_l * 0.5 - Vector2(6, 6)
		if status == "empty":
			for p in [Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)]:
				_add_box_2d(lots_root_3d, c + p, Vector2(3.5, 3.5), 0.0, 9.0, m_stake)
		elif status == "building":
			var prog: float = clampf(float(st.get("progress", 0.0)), 0.05, 1.0)
			_add_box_2d(lots_root_3d, c, Vector2(124, 92), 0.0, 2.5, m_found)
			var cur_h: float = 8.0 + 20.0 * prog
			for sx in [-56.0, 0.0, 56.0]:
				for sy in [-40.0, 40.0]:
					_add_box_2d(lots_root_3d, c + Vector2(sx, sy), Vector2(3.5, 3.5), 2.5, cur_h, m_scaffold)
			_add_box_2d(lots_root_3d, c + Vector2(0, -40.0), Vector2(118.0, 3.0), cur_h * 0.6, 2.5, m_scaffold)
			_add_box_2d(lots_root_3d, c + Vector2(0, 40.0), Vector2(118.0, 3.0), cur_h * 0.6, 2.5, m_scaffold)
			_add_model_2d(lots_root_3d, "props/Workbench.gltf", c + Vector2(-28.0, 0.0), 2.5, Vector2(24.0, 14.0), 8.0)

# ==============================================================================
# 4. ASENTAMIENTO FRONTERIZO «PUESTO DEL PASO» (EN EL LINDERO ESTE)
# ==============================================================================
func rebuild_outpost_3d() -> void:
	_clear_children(outpost_root_3d)
	if vm == null:
		return
	var op: Dictionary = VillageCulture.outpost_state(vm)
	var founded: bool = bool(op.get("founded", false))
	var upgs: Dictionary = op.get("upgrades", {})
	var c: Vector2 = VillageCulture.OUTPOST_CENTER
	var gate_p: Vector2 = VillageCulture.OUTPOST_GATE_POS

	var m_road := _mat("road_dirt", Color(0.46, 0.37, 0.25), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.35)
	var m_log := _mat("outpost_log", Color(0.55, 0.40, 0.26), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/floor_wood_planks.png", "", 0.45)
	var m_plank := _mat("outpost_plank", Color(0.68, 0.50, 0.32), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/floor_wood_planks.png", "", 0.45)
	var m_stone := _mat("outpost_stone", Color(0.65, 0.64, 0.60), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.35)

	# Extensión del camino del este hasta el Puesto del Paso
	_add_box_2d(outpost_root_3d, Vector2(1512, 50), Vector2(72, 26), 0.0, 1.2, m_road)

	if not founded:
		# Solar fronterizo con estacas, mesa de planos y cartel
		for p in [Vector2(-64, -68), Vector2(64, -68), Vector2(64, 68), Vector2(-64, 68)]:
			_add_cyl_2d(outpost_root_3d, c + p, 2.5, 0.0, 11.0, m_log, 2.0, 8)
		_add_box_2d(outpost_root_3d, gate_p, Vector2(4.0, 4.0), 0.0, 16.0, m_log)
		_add_box_2d(outpost_root_3d, gate_p + Vector2(0, -2), Vector2(16.0, 3.0), 11.0, 5.0, m_plank)
		return

	# Explanada fortificada y empalizada de troncos 3D
	_add_box_2d(outpost_root_3d, c, Vector2(152, 164), 0.0, 1.5, m_stone)
	_add_box_2d(outpost_root_3d, c + Vector2(0, -80), Vector2(152, 6), 1.5, 22.0, m_log)
	_add_box_2d(outpost_root_3d, c + Vector2(0, 80), Vector2(152, 6), 1.5, 22.0, m_log)
	_add_box_2d(outpost_root_3d, c + Vector2(74, 0), Vector2(6, 164), 1.5, 22.0, m_log)
	_add_box_2d(outpost_root_3d, c + Vector2(-74, -50), Vector2(6, 60), 1.5, 22.0, m_log)
	_add_box_2d(outpost_root_3d, c + Vector2(-74, 50), Vector2(6, 60), 1.5, 22.0, m_log)
	# Pórtico de entrada en Vector2(1542, 50)
	_add_cyl_2d(outpost_root_3d, gate_p + Vector2(0, -20), 4.0, 1.5, 28.0, m_log, 3.5, 8)
	_add_cyl_2d(outpost_root_3d, gate_p + Vector2(0, 20), 4.0, 1.5, 28.0, m_log, 3.5, 8)
	_add_box_2d(outpost_root_3d, gate_p, Vector2(8.0, 44.0), 25.0, 5.0, m_plank)

	# Cabaña de mando 3D, Arca del asentamiento y Hoguera central encendida
	_add_model_2d(outpost_root_3d, "buildings/House_2.obj", c + Vector2(34, 0), 1.5, Vector2(50, 42), 34.0, -90.0)
	_add_model_2d(outpost_root_3d, "props/Chest_Wood.gltf", c + Vector2(6, 0), 1.5, Vector2(13, 9), 8.0, -90.0)
	_add_model_2d(outpost_root_3d, "exterior/Bonfire_Lit.obj", c + Vector2(-18, 0), 1.5, Vector2(16, 16), 11.0)
	_add_model_2d(outpost_root_3d, "props/Crate_Wooden.gltf", c + Vector2(14, 24), 1.5, Vector2(10, 10), 8.0)
	_add_model_2d(outpost_root_3d, "props/Barrel.gltf", c + Vector2(14, -24), 1.5, Vector2(9, 9), 9.5)
	if not _is_headless:
		var fire_lt := OmniLight3D.new()
		fire_lt.position = to_3d(c + Vector2(-18, 0), 12.0)
		fire_lt.light_color = Color(1.0, 0.65, 0.25)
		fire_lt.light_energy = 1.6
		fire_lt.omni_range = 3.2
		outpost_root_3d.add_child(fire_lt)

	# Mejora 1: Aserradero Fronterizo
	if bool(upgs.get("sawmill", false)):
		var sm_p := c + Vector2(-26, -50)
		_add_model_2d(outpost_root_3d, "buildings/Sawmill.obj", sm_p, 1.5, Vector2(48, 32), 28.0)
		_add_model_2d(outpost_root_3d, "nature/WoodLog.obj", sm_p + Vector2(22, 10), 1.5, Vector2(14, 8), 6.0)

	# Mejora 2: Granero / Molino del Paso
	if bool(upgs.get("granary", false)):
		var gr_p := c + Vector2(-26, 50)
		_add_model_2d(outpost_root_3d, "buildings/Mill.obj", gr_p, 1.5, Vector2(38, 38), 36.0)

	# Mejora 3: Atalaya de Guardia
	if bool(upgs.get("watchtower", false)):
		var wt_p := c + Vector2(-56, -56)
		_add_model_2d(outpost_root_3d, "buildings/Bell_Tower.obj", wt_p, 1.5, Vector2(30, 30), 48.0)

# ==============================================================================
# 5. TUMBAS DEL CEMENTERIO, ALCANTARILLAS (-1) Y FAROLAS CON LUZ REAL
# ==============================================================================
func rebuild_graves_3d() -> void:
	_clear_children(graves_root_3d)
	if vm == null:
		return
	_last_buried_count = vm.buried_graves.size()
	var m_mound := _mat("grave_earth", Color(0.36, 0.25, 0.16), 0.95, 0.0)
	var grave_models: Array[String] = [
		"graveyard/gravestone-cross.glb",
		"graveyard/gravestone-decorative.glb",
		"graveyard/gravestone-round.glb",
		"graveyard/cross-column.glb",
	]

	for i in range(vm.buried_graves.size()):
		var g_pos: Vector2 = vm._cemetery_burial_pos
		if i < vm._cemetery_grave_positions.size():
			g_pos = vm._cemetery_grave_positions[i]
		else:
			g_pos = Vector2(844.0 + float(i % 6) * 26.0, 282.0 + float(int(float(i) / 6.0) % 3) * 28.0)
		_add_box_2d(graves_root_3d, g_pos + Vector2(0, 4), Vector2(14.0, 12.0), 1.0, 3.2, m_mound)
		var g_mdl: String = grave_models[i % grave_models.size()]
		_add_model_2d(graves_root_3d, g_mdl, g_pos + Vector2(0, -5), 1.0, Vector2(11.0, 6.0), 14.0)

func _build_sewers_3d() -> void:
	_clear_children(sewers_root_3d)
	var m_bedrock := _mat("sewer_bedrock", Color(0.08, 0.10, 0.09), 0.96, 0.0)
	var m_brick := _mat("sewer_brick", Color(0.28, 0.34, 0.30), 0.90, 0.05, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.35)
	var m_walkway := _mat("sewer_walkway", Color(0.36, 0.40, 0.38), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/rf_cobblestone.png", "", 0.45)
	var m_water := _mat("sewer_water", Color(0.14, 0.46, 0.36, 0.92), 0.25, 0.15, Color(0.10, 0.42, 0.30), 0.35)
	var m_iron := _mat("sewer_iron", Color(0.24, 0.27, 0.32), 0.42, 0.78)
	var m_wood := _mat("sewer_wood", Color(0.46, 0.30, 0.16), 0.85, 0.04)
	var m_brass := _mat("sewer_brass", Color(0.90, 0.74, 0.26), 0.28, 0.85, Color(0.85, 0.68, 0.20), 0.45)
	var m_torch := _mat("sewer_torch", Color(1.0, 0.76, 0.32), 0.20, 0.0, Color(1.0, 0.68, 0.22), 2.8)

	# Losa oscura de roca subterránea para cubrir la hierba exterior alrededor de la red de túneles (y = 1520)
	_add_box_2d(sewers_root_3d, Vector2(420.0, 1520.0), Vector2(560.0, 200.0), 0.0, 1.0, m_bedrock)

	# 3 cámaras conectadas: Bóveda Inundada (260, 1520), Pasadizo del Contrabandista (420, 1520) y Cisterna (580, 1520)
	for loc_id in ["flooded_vault", "smuggler_tunnel", "cistern"]:
		var def: Dictionary = VillageUnderworldScript.SEWER_LOCATIONS[loc_id]
		var ch_p: Vector2 = def["chamber_center"]
		var lad_p: Vector2 = def["ladder_pos"]
		var chs_p: Vector2 = def["chest_pos"]

		# Suelo de piedra, andén seco norte y canal de aguas turbias al sur
		_add_box_2d(sewers_root_3d, ch_p, Vector2(110.0, 80.0), 1.0, 1.4, m_brick)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(0.0, -8.0), Vector2(106.0, 56.0), 2.4, 1.2, m_walkway)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(0.0, 26.0), Vector2(106.0, 18.0), 1.6, 1.0, m_water)

		# Muro norte alto y zócalo sur bajo (para que la cámara isométrica vea el interior sin tapar al jugador)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(0.0, -43.0), Vector2(116.0, 6.0), 2.0, 20.0, m_brick)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(0.0, 43.0), Vector2(116.0, 6.0), 2.0, 5.0, m_brick)

		# Escalerilla 3D de salida a la calle junto a la boca del túnel
		_add_box_2d(sewers_root_3d, lad_p + Vector2(0.0, -2.0), Vector2(11.0, 8.0), 3.6, 0.8, m_iron)
		_add_box_2d(sewers_root_3d, lad_p + Vector2(-4.0, -10.0), Vector2(1.4, 2.0), 3.6, 20.0, m_iron)
		_add_box_2d(sewers_root_3d, lad_p + Vector2(4.0, -10.0), Vector2(1.4, 2.0), 3.6, 20.0, m_iron)
		for rung_i in range(6):
			_add_box_2d(sewers_root_3d, lad_p + Vector2(0.0, -10.0), Vector2(8.0, 1.2), 5.5 + float(rung_i) * 3.0, 0.9, m_brass)

		# Antorcha mural subterránea junto a la escalerilla
		_add_cyl_2d(sewers_root_3d, lad_p + Vector2(12.0, -13.0), 1.4, 12.0, 5.0, m_wood, 1.0, 6)
		_add_cyl_2d(sewers_root_3d, lad_p + Vector2(12.0, -13.0), 2.2, 17.0, 3.0, m_torch, 1.4, 8)
		if not _is_headless:
			var t_light := OmniLight3D.new()
			t_light.position = to_3d(lad_p + Vector2(12.0, -8.0), 18.0)
			t_light.light_color = Color(1.0, 0.78, 0.42)
			t_light.light_energy = 1.35
			t_light.omni_range = 3.2
			sewers_root_3d.add_child(t_light)

		# Cofre de contrabando 3D sobre losa de piedra + barriles y cajas de alijo
		_add_box_2d(sewers_root_3d, chs_p, Vector2(16.0, 12.0), 3.6, 1.4, m_brick)
		if _add_model_2d(sewers_root_3d, "props/Chest_Wood.gltf", chs_p, 5.0, Vector2(13.0, 9.5), 8.5) == null:
			_add_box_2d(sewers_root_3d, chs_p, Vector2(13.0, 9.0), 5.0, 5.5, m_wood)
			_add_box_2d(sewers_root_3d, chs_p, Vector2(13.4, 9.4), 10.5, 2.5, m_iron)
		_add_box_2d(sewers_root_3d, chs_p + Vector2(0.0, 4.6), Vector2(2.4, 1.4), 7.5, 2.6, m_brass)
		_add_model_2d(sewers_root_3d, "props/Barrel.gltf", ch_p + Vector2(-38.0, 6.0), 3.6, Vector2(9.0, 9.0), 9.5)
		_add_model_2d(sewers_root_3d, "props/Crate_Wooden.gltf", ch_p + Vector2(38.0, 6.0), 3.6, Vector2(11.0, 11.0), 8.5)

	# 2 galerías de conexión entre las 3 cámaras (x = 340 y x = 500) y muros laterales de cierre
	for corr_x in [340.0, 500.0]:
		var cp := Vector2(corr_x, 1520.0)
		_add_box_2d(sewers_root_3d, cp, Vector2(56.0, 42.0), 1.0, 2.4, m_walkway)
		_add_box_2d(sewers_root_3d, cp + Vector2(0.0, 14.0), Vector2(56.0, 10.0), 1.6, 1.0, m_water)
		_add_box_2d(sewers_root_3d, cp + Vector2(0.0, -23.0), Vector2(56.0, 6.0), 2.0, 18.0, m_brick)
		_add_box_2d(sewers_root_3d, cp + Vector2(0.0, 23.0), Vector2(56.0, 6.0), 2.0, 5.0, m_brick)
	for sx in [315.0, 365.0, 475.0, 525.0]:
		_add_box_2d(sewers_root_3d, Vector2(sx, 1488.0), Vector2(6.0, 22.0), 2.0, 20.0, m_brick)
		_add_box_2d(sewers_root_3d, Vector2(sx, 1552.0), Vector2(6.0, 22.0), 2.0, 5.0, m_brick)
	_add_box_2d(sewers_root_3d, Vector2(202.0, 1520.0), Vector2(6.0, 86.0), 2.0, 20.0, m_brick)
	_add_box_2d(sewers_root_3d, Vector2(638.0, 1520.0), Vector2(6.0, 86.0), 2.0, 20.0, m_brick)

func _build_streetlights_3d() -> void:
	_clear_children(streetlights_root_3d)
	_streetlight_nodes_3d.clear()
	if vm == null:
		return
	var m_bulb_warm := _mat("bulb_warm", Color(1.0, 0.88, 0.52), 0.2, 0.0, Color(1.0, 0.82, 0.40), 2.4)
	var m_bulb_voltaic := _mat("bulb_voltaic", Color(0.55, 0.96, 1.0), 0.2, 0.0, Color(0.45, 0.92, 1.0), 3.2)

	for sl in vm.streetlights:
		var spr: Sprite2D = sl.get("sprite")
		var pos: Vector2 = spr.global_position if is_instance_valid(spr) else Vector2.ZERO
		_add_model_2d(streetlights_root_3d, "graveyard/lightpost-single.glb", pos, 0.0, Vector2(9.0, 9.0), 29.0)
		var bulb := _add_cyl_2d(streetlights_root_3d, pos + Vector2(3.5, 0), 2.2, 23.0, 3.6, m_bulb_warm, 1.6, 8)
		var omni: OmniLight3D = null
		if not _is_headless:
			omni = OmniLight3D.new()
			omni.position = to_3d(pos + Vector2(3.5, 0), 24.0)
			omni.omni_range = 3.6
			omni.light_energy = 1.2
			omni.light_color = Color(1.0, 0.86, 0.52)
			streetlights_root_3d.add_child(omni)
		_streetlight_nodes_3d.append({
			"bulb": bulb,
			"light": omni,
			"mat_warm": m_bulb_warm,
			"mat_voltaic": m_bulb_voltaic,
		})

# ==============================================================================
# 6. SINCRONIZACIÓN EN VIVO (CÁMARA 3D, PUERTAS, TEJADOS CUTAWAY Y TECLA [F10])
# ==============================================================================
func _process(delta: float) -> void:
	if _is_headless or vm == null:
		return

	var use_3d: bool = CharacterAvatar3DScript.use_3d_characters
	if use_3d != _last_use_3d:
		_last_use_3d = use_3d
		_sync_2d_flat_visuals(use_3d)

	if is_instance_valid(stage_sprite):
		stage_sprite.visible = use_3d
	if not use_3d:
		return

	if vm.buried_graves.size() != _last_buried_count:
		rebuild_graves_3d()

	_sync_camera_with_2d()
	_sync_dynamic_props_3d()

	_nature_scan_accum += delta
	if _nature_scan_accum >= 4.0:
		_nature_scan_accum = 0.0
		_scan_nature_sources()
		_sync_2d_flat_visuals(use_3d)
	_nature_accum += delta
	if _nature_accum >= 0.5:
		_nature_accum = 0.0
		_sync_nature_3d(true)
		_sync_props_3d(true)

	_cutaway_accum += delta
	if _cutaway_accum >= 0.08:
		_cutaway_accum = 0.0
		_update_roof_cutaways_and_lighting()

func _sync_camera_with_2d() -> void:
	if cam_3d == null or stage_sprite == null:
		return
	var vp := get_viewport()
	if vp == null:
		return
	var cam2d := vp.get_camera_2d()
	var vp_rect := vp.get_visible_rect()
	var center_2d: Vector2 = cam2d.get_screen_center_position() if cam2d != null else Vector2(465, 48)
	var zoom_2d: Vector2 = cam2d.zoom if cam2d != null else Vector2(3.0, 3.0)

	var world_vis_h: float = vp_rect.size.y / maxf(0.1, zoom_2d.y)
	cam_3d.size = maxf(1.0, world_vis_h * WORLD_SCALE)

	var target_3d: Vector3 = to_3d(center_2d, 0.0)
	var forward_vec: Vector3 = -cam_3d.global_transform.basis.z.normalized()
	cam_3d.global_position = target_3d - forward_vec * 65.0

	stage_sprite.global_position = center_2d
	stage_sprite.scale = Vector2(
		(vp_rect.size.x / maxf(0.1, zoom_2d.x)) / float(VIEWPORT_W),
		(vp_rect.size.y / maxf(0.1, zoom_2d.y)) / float(VIEWPORT_H)
	)

func _sync_dynamic_props_3d() -> void:
	# 1. Puertas abatibles 3D
	for d_node in _door_nodes_3d:
		var d_entry: Dictionary = d_node["entry"]
		var pivot: Node3D = d_node["pivot"]
		var badge: MeshInstance3D = d_node["lock_badge"]
		if not is_instance_valid(pivot):
			continue
		var eff_open: bool = bool(d_entry.get("is_open", false)) or float(d_entry.get("npc_pass_timer", 0.0)) > 0.0
		var door_south: bool = bool(d_node["door_south"])
		pivot.rotation_degrees.y = (-82.0 if door_south else 82.0) if eff_open else 0.0
		if is_instance_valid(badge):
			badge.visible = (not eff_open) and (bool(d_entry.get("is_locked", false)) or bool(d_entry.get("locked_by_player", false)))

	# 2. Postigos de ventanas 3D
	for w_node in _window_nodes_3d:
		var w_entry: Dictionary = w_node["entry"]
		var shutter: MeshInstance3D = w_node["shutter"]
		if is_instance_valid(shutter):
			shutter.visible = bool(w_entry.get("is_shuttered", false))

	# 3. Cofres abiertos / cerrados
	var wc = get_node_or_null("/root/WorldClock")
	var cur_d: int = int(wc.current_day) if wc != null else 1
	for ch_node in _chest_nodes_3d:
		var ch_entry: Dictionary = ch_node["entry"]
		var lid: MeshInstance3D = ch_node["lid"]
		if is_instance_valid(lid):
			lid.visible = (int(ch_entry.get("looted_day", -1)) != cur_d)

	# 4. Cuerpos en las 3 camillas de la Morgue
	var active_morgue: int = vm.morgue_active_corpses.size()
	for i in range(_morgue_body_nodes_3d.size()):
		if is_instance_valid(_morgue_body_nodes_3d[i]):
			_morgue_body_nodes_3d[i].visible = (i < active_morgue)

	# 5. Reja de la celda de la Comisaría
	if is_instance_valid(_jail_gate_pivot_3d):
		var gate_locked: bool = is_instance_valid(vm._jail_cell_gate_col) and not vm._jail_cell_gate_col.disabled
		_jail_gate_pivot_3d.rotation_degrees.y = 0.0 if gate_locked else -80.0

	# 6. Visibilidad de las alcantarillas (-1)
	if is_instance_valid(sewers_root_3d):
		sewers_root_3d.visible = VillageUnderworldScript.is_player_in_sewers(vm)

	# 7. Piloto luminoso del Cuadro Eléctrico del Taller y objeto físico del robo activo (Bloque FIS2)
	if is_instance_valid(_grid_panel_bulb_3d):
		var sab_on: bool = VillageCulture.is_grid_sabotaged(vm)
		_grid_panel_bulb_3d.material_override = _mat("grid_bulb_err", Color(1.0, 0.25, 0.18), 0.2, 0.0, Color(1.0, 0.20, 0.12), 2.8) if sab_on else _mat("tinker_screen", Color(0.32, 0.96, 0.82), 0.2, 0.0, Color(0.24, 0.92, 0.76), 2.4)
	_sync_heist_target_3d()
	_sync_town_ledger_3d()
	_sync_home_props_3d()

func _sync_home_props_3d() -> void:
	if vm == null or stage_root_3d == null:
		return
	var p_lots: Array[String] = VillageHousingScript.player_lots(vm, true)
	var hs: Dictionary = VillageHousingScript.state(vm)
	var prim_lot: String = VillageHousingScript.primary_player_lot(vm)
	var has_shop: bool = VillageHousingScript.has_player_shop(vm)
	var ps: Dictionary = hs.get("player_shop", {}) if has_shop else {}
	var shop_lot: String = VillageHousingScript.player_shop_lot(vm) if has_shop else ""
	var parts: PackedStringArray = PackedStringArray()
	for lid in p_lots:
		var st: Dictionary = VillageLots.lot(vm, lid)
		var up: Dictionary = st.get("upgrades", {})
		var wb: int = 1 if bool(up.get("workbench", false)) else 0
		var st_fl: int = 1 if (lid == prim_lot and bool(hs.get("has_stash", false))) else 0
		var up_fl: int = 1 if bool(up.get("upper_floor", false)) else 0
		var cel_fl: int = 1 if bool(up.get("hidden_cellar", false)) else 0
		var gd_fl: int = 1 if bool(st.get("has_garden", false)) else 0
		var gd_rdy: int = 1 if (gd_fl == 1 and VillageHousingScript.can_harvest_home_garden(vm, lid)) else 0
		var sh_fl: int = 1 if (has_shop and lid == shop_lot) else 0
		var sh_stk: int = clampi(int(ps.get("stock", 0)), 0, 4) if sh_fl == 1 else 0
		var sh_till: int = (1 if int(ps.get("till_gold", 0)) > 0 else 0) if sh_fl == 1 else 0
		parts.append("%s:%d:%d:%d:%d:%d:%d:%d:%d:%d" % [lid, wb, st_fl, up_fl, cel_fl, gd_fl, gd_rdy, sh_fl, sh_stk, sh_till])
	var sig: String = "|".join(parts)
	if sig == _last_home_props_sig and (sig.is_empty() or is_instance_valid(_home_props_3d)):
		return
	_last_home_props_sig = sig
	if is_instance_valid(_home_props_3d):
		_home_props_3d.queue_free()
		_home_props_3d = null
	if sig.is_empty():
		return
	var root: Node3D = Node3D.new()
	root.name = "HomeProps3D"
	stage_root_3d.add_child(root)
	_home_props_3d = root

	var m_oak: StandardMaterial3D = _mat("hp_oak", Color(0.46, 0.30, 0.16), 0.85, 0.05)
	var m_dark: StandardMaterial3D = _mat("hp_dark", Color(0.14, 0.10, 0.06), 0.95, 0.0)
	var m_iron: StandardMaterial3D = _mat("hp_iron", Color(0.28, 0.32, 0.36), 0.45, 0.75)
	var m_gold: StandardMaterial3D = _mat("hp_gold", Color(0.95, 0.78, 0.24), 0.25, 0.85, Color(0.92, 0.74, 0.20), 0.55)
	var m_herb: StandardMaterial3D = _mat("hp_herb", Color(0.30, 0.82, 0.38), 0.45, 0.10, Color(0.20, 0.65, 0.28), 0.35)
	var m_dust: StandardMaterial3D = _mat("hp_dust", Color(0.74, 0.44, 0.96), 0.30, 0.15, Color(0.66, 0.36, 0.90), 0.55)
	var m_soil: StandardMaterial3D = _mat("hp_soil", Color(0.30, 0.20, 0.12), 0.95, 0.0)

	for lid in p_lots:
		var st: Dictionary = VillageLots.lot(vm, lid)
		var up: Dictionary = st.get("upgrades", {})
		if bool(up.get("workbench", false)):
			var wb_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_workbench")
			if _add_model_2d(root, "props/Workbench_Drawers.gltf", wb_pos, 2.0, Vector2(18.0, 10.0), 8.2) == null:
				_add_box_2d(root, wb_pos, Vector2(18.0, 10.0), 2.0, 7.5, m_oak)
			_add_cyl_2d(root, wb_pos + Vector2(-4.0, -0.5), 2.2, 9.5, 2.6, m_herb, 1.8, 8) # Mortero con cataplasma
			_add_cyl_2d(root, wb_pos + Vector2(3.5, -0.5), 2.0, 9.5, 3.8, m_dust, 1.0, 10) # Alambique de polvo de ocaso
		if lid == prim_lot and bool(hs.get("has_stash", false)):
			var st_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_stash")
			_add_box_2d(root, st_pos, Vector2(13.0, 9.5), 1.8, 0.8, m_dark) # Hueco bajo el suelo
			_add_box_2d(root, st_pos + Vector2(-3.2, 0), Vector2(4.2, 8.8), 2.2, 1.2, m_oak) # Tabla izq
			_add_box_2d(root, st_pos + Vector2(3.4, -0.6), Vector2(4.2, 8.8), 2.6, 1.4, m_oak) # Tabla entreabierta der
			_add_cyl_2d(root, st_pos + Vector2(0, 0.8), 2.2, 2.2, 1.2, m_gold, 2.2, 8) # Monedas ocultas
		if bool(up.get("upper_floor", false)) or bool(up.get("hidden_cellar", false)):
			var sr_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_stairs")
			_add_box_2d(root, sr_pos, Vector2(13.0, 14.0), 1.8, 1.2, m_dark) # Trampilla / base
			_add_box_2d(root, sr_pos, Vector2(11.6, 12.6), 2.4, 1.4, m_oak)
			_add_box_2d(root, sr_pos + Vector2(4.0, 0), Vector2(1.8, 1.8), 3.6, 1.2, m_iron) # Argolla de hierro
			if bool(up.get("upper_floor", false)):
				for step_i in range(4):
					var sy: float = -4.5 + float(step_i) * 3.0
					var sh: float = 4.0 + float(step_i) * 4.2
					_add_box_2d(root, sr_pos + Vector2(0, sy), Vector2(10.0, 2.2), sh, 1.6, m_oak)
		if bool(st.get("has_garden", false)):
			var gd_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_garden")
			_add_box_2d(root, gd_pos, Vector2(22.0, 15.0), 0.2, 2.2, m_oak) # Cerco de madera
			_add_box_2d(root, gd_pos, Vector2(19.6, 12.6), 0.4, 2.4, m_soil) # Tierra labrada
			var crop_mat: StandardMaterial3D = m_herb if VillageHousingScript.can_harvest_home_garden(vm, lid) else m_oak
			for gy in [-3.2, 3.2]:
				for gx in [-6.5, -2.2, 2.2, 6.5]:
					_add_cyl_2d(root, gd_pos + Vector2(gx, gy), 2.0, 2.6, 2.6, crop_mat, 1.4, 7)
		if has_shop and lid == shop_lot:
			var sc_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "player_shop_counter")
			_add_box_2d(root, sc_pos, Vector2(18.0, 9.2), 2.0, 6.8, m_oak) # Cuerpo del mostrador
			_add_box_2d(root, sc_pos, Vector2(19.6, 10.4), 8.6, 1.2, m_oak) # Tablero del mostrador
			_add_box_2d(root, sc_pos + Vector2(4.6, -0.2), Vector2(5.2, 4.4), 9.8, 2.6, m_iron) # Caja de recaudación
			if int(ps.get("till_gold", 0)) > 0:
				_add_cyl_2d(root, sc_pos + Vector2(4.6, -0.2), 1.8, 12.2, 1.2, m_gold, 1.8, 8) # Monedas en la caja
			if int(ps.get("stock", 0)) > 0:
				_add_box_2d(root, sc_pos + Vector2(-4.8, -0.4), Vector2(3.8, 3.6), 9.8, 2.4, m_herb) # Mercancía expuesta 1
				if int(ps.get("stock", 0)) >= 2:
					_add_box_2d(root, sc_pos + Vector2(-1.2, 0.4), Vector2(3.6, 3.4), 9.8, 2.2, m_gold) # Mercancía expuesta 2

## P5: libro de cuentas abierto sobre la mesa del ayuntamiento (se construye una vez).
func _sync_town_ledger_3d() -> void:
	if vm == null or stage_root_3d == null or is_instance_valid(_town_ledger_3d):
		return
	var pos: Vector2 = load("res://scripts/systems/VillageCollections.gd").ledger_pos()
	var root := Node3D.new()
	root.name = "TownLedger3D"
	stage_root_3d.add_child(root)
	_town_ledger_3d = root
	var m_leather := _mat("ledger_leather", Color(0.40, 0.20, 0.10), 0.82, 0.05)
	var m_page := _mat("heist_page", Color(0.95, 0.90, 0.76), 0.85, 0.0)
	_add_box_2d(root, pos, Vector2(12.0, 8.0), 10.2, 1.0, m_leather) # Tapas abiertas
	_add_box_2d(root, pos + Vector2(-2.9, 0), Vector2(5.4, 6.8), 11.2, 0.8, m_page) # Página izquierda
	_add_box_2d(root, pos + Vector2(2.9, 0), Vector2(5.4, 6.8), 11.2, 0.8, m_page) # Página derecha

func _sync_heist_target_3d() -> void:
	if vm == null or stage_root_3d == null:
		return
	var ah: Dictionary = VillageUnderworldScript.state(vm).get("active_heist", {})
	var active: bool = (not ah.is_empty()) and (not bool(ah.get("stolen", false)))
	var sig: String = "%s|%d|%d" % [str(ah.get("id", "")), int(ah.get("pos_x", 0)), int(ah.get("pos_y", 0))] if active else ""
	if sig == _last_heist_sig and (not active or is_instance_valid(_heist_prop_3d)):
		return
	_last_heist_sig = sig
	if is_instance_valid(_heist_prop_3d):
		_heist_prop_3d.queue_free()
		_heist_prop_3d = null
	if not active:
		return
	var h_id: String = str(ah.get("id", "sello_noble"))
	var h_pos := Vector2(float(ah.get("pos_x", 0.0)), float(ah.get("pos_y", 0.0)))
	var root := Node3D.new()
	root.name = "HeistTarget3D_" + h_id
	stage_root_3d.add_child(root)
	_heist_prop_3d = root

	var m_gold := _mat("heist_gold", Color(0.96, 0.80, 0.28), 0.25, 0.85, Color(0.95, 0.76, 0.22), 0.65)
	var m_silver := _mat("heist_silver", Color(0.88, 0.92, 0.98), 0.20, 0.90, Color(0.75, 0.85, 1.0), 0.55)
	var m_crimson := _mat("heist_crimson", Color(0.76, 0.14, 0.20), 0.75, 0.05)
	var m_leather := _mat("heist_leather", Color(0.42, 0.22, 0.12), 0.82, 0.05)
	var m_page := _mat("heist_page", Color(0.95, 0.90, 0.76), 0.85, 0.0)

	match h_id:
		"sello_noble":
			# Sobre el escritorio del estudio de la Mansión (altura base ~10.2 px)
			_add_box_2d(root, h_pos, Vector2(11.0, 9.0), 10.2, 2.2, m_crimson) # Cojín de terciopelo
			_add_cyl_2d(root, h_pos + Vector2(-2.0, 0.5), 2.6, 12.4, 1.4, m_crimson, 2.6, 10) # Lacre real
			_add_cyl_2d(root, h_pos + Vector2(1.8, -0.5), 2.2, 12.4, 5.2, m_gold, 1.5, 10) # Matriz de oro del sello
			_add_model_2d(root, "props/Scroll_1.gltf", h_pos + Vector2(-5.0, -2.0), 10.2, Vector2(7.0, 5.0), 3.5)
		"caliz_capilla":
			# Sobre el altar de piedra de la Capilla (altura base ~13.0 px)
			if _add_model_2d(root, "props/Chalice.gltf", h_pos, 13.0, Vector2(8.0, 8.0), 8.5) == null:
				_add_cyl_2d(root, h_pos, 3.2, 13.0, 1.8, m_silver, 2.4, 10)
				_add_cyl_2d(root, h_pos, 1.4, 14.8, 3.2, m_silver, 1.4, 10)
				_add_cyl_2d(root, h_pos, 2.6, 18.0, 3.6, m_gold, 3.8, 12)
			else:
				_add_cyl_2d(root, h_pos, 4.4, 12.4, 0.8, m_gold, 4.4, 12) # Patena dorada bajo el cáliz
		_:
			# Libro Mayor de los Gremios sobre la mesa del Ayuntamiento (altura base ~10.2 px)
			if _add_model_2d(root, "props/Book_5.gltf", h_pos, 10.2, Vector2(13.0, 10.0), 4.5) == null:
				_add_box_2d(root, h_pos, Vector2(13.0, 10.0), 10.2, 1.6, m_leather)
				_add_box_2d(root, h_pos, Vector2(11.4, 8.6), 11.8, 1.8, m_page)
			_add_box_2d(root, h_pos + Vector2(-5.8, 0), Vector2(1.4, 8.8), 10.2, 3.6, m_gold)
			_add_box_2d(root, h_pos + Vector2(5.8, 0), Vector2(1.4, 8.8), 10.2, 3.6, m_gold)

func _update_roof_cutaways_and_lighting() -> void:
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	var pl_pos: Vector2 = pl.global_position if is_instance_valid(pl) else Vector2.INF
	var mouse_pos: Vector2 = get_global_mouse_position()
	var elev: int = vm.player_elevation_level

	for rec in _building_records_3d:
		var rect: Rect2 = rec["rect"]
		var roof_cap: Node3D = rec["roof_cap"]
		var loft_root: Node3D = rec["loft_root"]
		if not is_instance_valid(roof_cap):
			continue
		var r_near: Rect2 = rect.grow(38.0)
		var r_inside: Rect2 = rect.grow(8.0)
		var open_roof: bool = r_near.has_point(pl_pos) or r_inside.has_point(mouse_pos)
		# (2026-11-05, 2ª noche) Ya no se abre porque haya un vecino dentro: los muñecos 3D están dentro del escenario
		# y el pueblo debe verse con sus tejados. Solo lo abren el jugador (dentro o pegado) y el ratón encima.
		roof_cap.visible = not open_roof
		if is_instance_valid(loft_root):
			loft_root.visible = (elev == 1 and r_near.has_point(pl_pos))

	# Casa mejorada del jugador: el tejado se abre igual que en los demás edificios
	if is_instance_valid(_player_house_roof):
		_player_house_roof.visible = not (_player_house_rect.grow(38.0).has_point(pl_pos) or _player_house_rect.grow(8.0).has_point(mouse_pos))

	# Luz diurna/nocturna y farolas eléctricas 3D
	var wc2 = get_node_or_null("/root/WorldClock")
	var gm2 = get_node_or_null("/root/GameManager")
	var hour: int = int(wc2.current_hour) if wc2 != null else 12
	var is_night: bool = (hour >= 19 or hour < 6)
	var is_dusk: bool = (hour in [6, 7, 17, 18])
	var grid_on: bool = gm2 != null and bool(gm2.get_flag("electric_grid_active", false)) and VillageCulture.is_lamps_powered(vm)

	if is_instance_valid(sun_light):
		if is_night:
			sun_light.light_energy = 0.55 # luz de luna: fría, pero deja ver las siluetas
			sun_light.light_color = Color(0.58, 0.68, 0.95)
		elif is_dusk:
			sun_light.light_energy = 0.82
			sun_light.light_color = Color(1.0, 0.78, 0.56)
		else:
			sun_light.light_energy = 1.14
			sun_light.light_color = Color(1.0, 0.96, 0.88)

	# Con el circuito de farolas cortado (sabotaje), las calles quedan a oscuras también de noche.
	var lamps_lit: bool = VillageCulture.is_lamps_powered(vm) and (is_night or grid_on)
	for sl_node in _streetlight_nodes_3d:
		var bulb: MeshInstance3D = sl_node["bulb"]
		var lt: OmniLight3D = sl_node["light"]
		if is_instance_valid(bulb):
			bulb.visible = lamps_lit
			bulb.material_override = sl_node["mat_voltaic"] if grid_on else sl_node["mat_warm"]
		if is_instance_valid(lt):
			lt.visible = lamps_lit
			lt.light_color = Color(0.55, 0.96, 1.0) if grid_on else Color(1.0, 0.85, 0.45)
			lt.light_energy = 1.65 if grid_on else 1.10

# ==============================================================================
# SUELO 3D Y NATURALEZA (2026-11-05): sustituyen a la hierba y a los pinos dibujados en 2D
# ==============================================================================
## Suelo opaco de hierba bajo todo el valle, con zonas: bosque profundo más oscuro, llanura oeste seca y ciénaga.
## Recibe las sombras del sol; tapa los decorados planos 2D con z <= -3 (bordes, césped del bosque).
func _build_ground_3d() -> void:
	var m_grass := _mat("ground_grass", Color(0.50, 0.74, 0.40), 0.95, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_grass.png", "", 0.78)
	var m_forest := _mat("ground_forest", Color(0.30, 0.50, 0.30), 0.95, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_grass.png", "", 0.78)
	var m_plains := _mat("ground_plains", Color(0.86, 0.80, 0.48), 0.95, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_grass.png", "", 0.78)
	var m_mud := _mat("ground_mud", Color(0.55, 0.46, 0.34), 0.95, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.78)
	var m_marsh := _mat("ground_marsh_water", Color(0.30, 0.42, 0.30), 0.35, 0.05, Color.BLACK, 0.0, "town_textures/floor_ground_water_green.png", "", 0.78)
	_add_box_2d(terrain_root_3d, Vector2(40, 480), Vector2(3600, 3000), -1.0, 1.0, m_grass)
	_add_box_2d(terrain_root_3d, Vector2(170, 907), Vector2(1380, 665), -0.6, 0.6, m_forest)
	_add_box_2d(terrain_root_3d, Vector2(-625, -30), Vector2(470, 360), -0.6, 0.6, m_plains)
	_add_box_2d(terrain_root_3d, Vector2(-612, -71), Vector2(235, 107), -0.4, 0.5, m_mud)
	_add_box_2d(terrain_root_3d, Vector2(-606, 85), Vector2(223, 98), -0.4, 0.5, m_marsh)


## Lago 3D a partir del mismo polígono que el lago 2D: orilla de arena, agua y zona honda más oscura.
func _build_lake_3d() -> void:
	var m_sand := _mat("lake_sand", Color(0.86, 0.78, 0.58), 0.95, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_sand.png", "", 0.78)
	var m_lake := _mat("lake_water", Color(0.36, 0.62, 0.86), 0.12, 0.10, Color.BLACK, 0.0, "town_textures/floor_ground_water.png", "", 0.55)
	var m_deep := _mat("lake_deep", Color(0.20, 0.38, 0.62), 0.10, 0.10, Color.BLACK, 0.0, "town_textures/floor_ground_water.png", "", 0.55)
	for lm in [m_sand, m_lake, m_deep]:
		(lm as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_flat_poly_2d(terrain_root_3d, FishingSpotScript.lake_scaled(1.0, 9.0), 0.25, m_sand)
	_add_flat_poly_2d(terrain_root_3d, FishingSpotScript.lake_scaled(1.0, 0.0), 0.55, m_lake)
	_add_flat_poly_2d(terrain_root_3d, FishingSpotScript.lake_scaled(0.62, 0.0), 0.7, m_deep)
	# Muelle de madera (mismo sitio que el 2D: 14..50 px al este del centro del lago)
	var m_dock := _mat("dock_wood", Color(0.62, 0.44, 0.28), 0.9, 0.0, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78)
	_add_box_2d(terrain_root_3d, Vector2(-65 + 32, 105), Vector2(38, 16), 1.0, 2.5, m_dock)
	for px in [-14.0, 0.0, 14.0]:
		for py in [-7.0, 7.0]:
			_add_box_2d(terrain_root_3d, Vector2(-65 + 32 + px, 105 + py), Vector2(2.5, 2.5), -0.5, 3.5, m_dock)


## Superficie plana con la forma de un polígono del mapa 2D, a una altura dada (agua, arena…).
func _add_flat_poly_2d(parent: Node3D, pts: PackedVector2Array, h_px: float, mat: Material) -> MeshInstance3D:
	var idx := Geometry2D.triangulate_polygon(pts)
	if idx.is_empty():
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for i in idx:
		st.add_vertex(to_3d(pts[i], h_px))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Bloque AA: detalles fijos de los barrios apartados (molino de viento, leñeros de los caseríos, embarcadero del lago).
func _build_barrios_3d(m_wood: Material) -> void:
	var mp: Vector2 = VillageLots.EAST_MILL_POS
	# (El molino de Kenney es casi solo aspas y desde arriba parece un palo: va el de Quaternius, con su casa de piedra.)
	_add_model_2d(terrain_root_3d, "buildings/Mill.obj", mp, 0.0, Vector2(40, 40), 52.0)
	for wp in [Vector2(-532, 690), Vector2(-522, 820), Vector2(-528, 950)]:
		for k in range(3):
			var lg := _add_cyl_2d(terrain_root_3d, wp + Vector2(0, k * 5.0 - 5.0), 2.4, 0.0, 16.0, m_wood, 2.4, 7)
			lg.rotation_degrees.z = 90.0
			lg.position = to_3d(wp + Vector2(0, k * 5.0 - 5.0), 2.4 + (3.6 if k == 1 else 0.0))
	# Embarcadero del Barrio del Lago: tablas que entran en el agua desde la orilla sur
	_add_box_2d(terrain_root_3d, Vector2(-100, 150), Vector2(14, 44), 1.4, 1.6, m_wood)
	for py in [132.0, 150.0, 168.0]:
		for px in [-106.0, -94.0]:
			_add_cyl_2d(terrain_root_3d, Vector2(px, py), 1.2, -2.0, 4.6, m_wood, 1.2, 6)


## Busca árboles talables, vetas de mineral y pinos decorativos 2D (cada pocos segundos, por si se plantan nuevos).
func _scan_nature_sources() -> void:
	if vm == null or not is_instance_valid(vm.entities_root):
		return
	_nature_sources.clear()
	for n in get_tree().get_nodes_in_group("destructible"):
		if not (n is Node2D) or n.get("harvest_type") == null:
			continue
		var ht: int = int(n.get("harvest_type"))
		var kind := ""
		if ht == 1:
			kind = "pine"
		elif ht == 2:
			kind = "rock"
		if kind.is_empty():
			continue
		_nature_sources.append({"node": n, "kind": kind, "sprite": n.get("sprite")})
	var parents: Array = [vm.entities_root]
	for eco in get_tree().get_nodes_in_group("ecosystem_manager"):
		parents.append(eco)
	for par in parents:
		for c in (par as Node).get_children():
			if c is Sprite2D and _is_pine_texture((c as Sprite2D).texture):
				_nature_sources.append({"node": c, "kind": "deco_pine", "sprite": c})
	_sync_nature_3d(false)
	_scan_props_sources()


## Crea o actualiza el modelo 3D de cada elemento natural y oculta su dibujo 2D mientras el 3D esté activo.
func _sync_nature_3d(only_update: bool) -> void:
	if nature_root_3d == null:
		return
	var use_3d: bool = CharacterAvatar3DScript.use_3d_characters
	var alive_ids: Dictionary = {}
	for src in _nature_sources:
		var n_v = src["node"]
		if not is_instance_valid(n_v):
			continue
		var n: Node2D = n_v
		var id := n.get_instance_id()
		alive_ids[id] = true
		var rec: Dictionary = _nature_nodes.get(id, {})
		if rec.is_empty() and not only_update:
			rec = _make_nature_3d(n, String(src["kind"]))
			for k in ["tree", "stump"]:
				var nd = rec.get(k)
				if nd is Node3D:
					_absorb_into_batches(nd as Node3D, n.global_position)
			_nature_nodes[id] = rec
		if rec.is_empty():
			continue
		var depleted: bool = bool(n.get("is_depleted")) if n.get("is_depleted") != null else false
		_set_vis3d(rec.get("tree"), n.is_visible_in_tree() and not depleted)
		_set_vis3d(rec.get("stump"), n.is_visible_in_tree() and depleted)
		var spr = src.get("sprite")
		if spr is CanvasItem and is_instance_valid(spr):
			(spr as CanvasItem).self_modulate.a = 0.0 if use_3d else 1.0
	if only_update:
		_flush_batches()
		return
	for id in _nature_nodes.keys():
		if not alive_ids.has(id):
			var r: Dictionary = _nature_nodes[id]
			for k in ["tree", "stump"]:
				var nd = r.get(k)
				if nd is Node3D and is_instance_valid(nd):
					_set_vis3d(nd, false)
					(nd as Node3D).queue_free()
			_nature_nodes.erase(id)
	_flush_batches()


## Pasa las mallas de un árbol o roca a su grupo por zona; el nodo queda vacío y guarda dónde están sus copias.
func _absorb_into_batches(node: Node3D, pos_2d: Vector2) -> void:
	var refs: Array = []
	var inv: Transform3D = nature_root_3d.global_transform.affine_inverse()
	var cell := Vector2i(floori(pos_2d.x / BATCH_CHUNK_PX), floori(pos_2d.y / BATCH_CHUNK_PX))
	for c in node.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if mi.mesh == null or mi.material_override != null:
			continue
		var plain := true
		for si in range(mi.mesh.get_surface_count()):
			if mi.get_surface_override_material(si) != null:
				plain = false
		if not plain:
			continue
		var key := "%d_%d_%d_%d" % [mi.mesh.get_instance_id(), int(mi.cast_shadow), cell.x, cell.y]
		var b: Dictionary = _batches.get(key, {})
		if b.is_empty():
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "Lote_" + key
			mmi.cast_shadow = mi.cast_shadow
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = mi.mesh
			mmi.multimesh = mm
			nature_root_3d.add_child(mmi)
			b = {"mmi": mmi, "entries": []}
			_batches[key] = b
		var entries: Array = b["entries"]
		entries.append({"xf": inv * mi.global_transform, "vis": node.visible})
		refs.append([key, entries.size() - 1])
		_batch_dirty[key] = true
		mi.get_parent().remove_child(mi)
		mi.queue_free()
	if not refs.is_empty():
		node.set_meta("batch_refs", refs)

func _set_vis3d(nd, vis: bool) -> void:
	if not (nd is Node3D) or not is_instance_valid(nd):
		return
	var n3 := nd as Node3D
	if n3.visible == vis:
		return
	n3.visible = vis
	if n3.has_meta("batch_refs"):
		for r in n3.get_meta("batch_refs"):
			var b: Dictionary = _batches.get(str(r[0]), {})
			if not b.is_empty():
				b["entries"][int(r[1])]["vis"] = vis
				_batch_dirty[str(r[0])] = true

func _flush_batches() -> void:
	for key in _batch_dirty.keys():
		var b: Dictionary = _batches.get(key, {})
		if b.is_empty() or not is_instance_valid(b["mmi"]):
			continue
		var mm: MultiMesh = (b["mmi"] as MultiMeshInstance3D).multimesh
		var entries: Array = b["entries"]
		mm.instance_count = 0
		mm.instance_count = entries.size()
		var gone := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, -1000, 0))
		for i in range(entries.size()):
			mm.set_instance_transform(i, entries[i]["xf"] if bool(entries[i]["vis"]) else gone)
	_batch_dirty.clear()


static func _is_pine_texture(t: Texture2D) -> bool:
	if t == null:
		return false
	var src: String = t.resource_path if not t.resource_path.is_empty() else String(t.get_meta("src_path", ""))
	return src.find("pine-tree") != -1 or src.ends_with("world/tree.png")


func _make_nature_3d(n: Node2D, kind: String) -> Dictionary:
	var hv: int = absi(int(n.global_position.x * 13.0 + n.global_position.y * 7.0))
	var pos := n.global_position
	var rot: float = float(hv % 360)
	if kind == "pine" or kind == "deco_pine":
		var files := ["nature/PineTree_1.obj", "nature/PineTree_2.obj", "nature/PineTree_3.obj", "nature/PineTree_4.obj"]
		var h: float = 58.0 + float(hv % 5) * 6.0
		var t := _add_model_2d(nature_root_3d, files[hv % files.size()], pos, 0.0, Vector2.ZERO, h, rot)
		var stump: Node3D = null
		if kind == "pine":
			stump = _add_cyl_2d(nature_root_3d, pos, 5.0, 0.0, 5.0, _mat("tree_stump", Color(0.45, 0.32, 0.20), 0.9, 0.0, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78), 4.5, 8)
			stump.visible = false
		return {"tree": t, "stump": stump}
	if kind == "rock":
		var rfiles := ["nature/Rock_1.obj", "nature/Rock_2.obj", "nature/Rock_3.obj", "nature/Rock_4.obj", "nature/Rock_5.obj"]
		var r := _add_model_2d(nature_root_3d, rfiles[hv % rfiles.size()], pos, 0.0, Vector2.ZERO, 16.0, rot)
		var low := _add_model_2d(nature_root_3d, rfiles[(hv + 2) % rfiles.size()], pos, 0.0, Vector2.ZERO, 6.0, rot + 40.0)
		if low != null:
			low.visible = false
		return {"tree": r, "stump": low}
	return {}


# ==============================================================================
# OBJETOS QUIETOS 2D -> 3D (pozos, farolas, tablón, campamento, huertos, compostador)
# ==============================================================================
## Qué versión 3D lleva cada dibujo 2D, según el nombre de su imagen. "hide" = ya tiene 3D propio, solo se esconde.
const PROP_KIND_BY_TEXTURE := {
	"water_well.png": "well",
	"compost_bin.png": "compost",
	"questboard_1.png": "hide",
	"lamp-post1.png": "hide",
	"camp_tent.png": "tent",
	"campfire_pot.png": "campfire",
	"camp_log_seat.png": "log_seat",
	"sign_1.png": "sign",
	"ancient_generator.png": "generator",
	"auto_sprinkler.png": "sprinkler",
	"soil_dry.png": "soil",
	"soil_wet.png": "soil",
	"coop_feeder_empty.png": "feeder",
	"coop_feeder_half.png": "feeder",
	"coop_feeder_full.png": "feeder",
	"coop_nest_empty.png": "nest",
	"coop_nest_eggs.png": "nest",
}

static func _tex_file(t: Texture2D) -> String:
	if t == null:
		return ""
	var src: String = t.resource_path if not t.resource_path.is_empty() else String(t.get_meta("src_path", ""))
	return src.get_file()


func _prop_kind_for(spr: Sprite2D) -> String:
	if spr.name == "CropSprite":
		return "crop"
	return String(PROP_KIND_BY_TEXTURE.get(_tex_file(spr.texture), ""))


## Busca los dibujos 2D de objetos quietos: hijos directos del pueblo y piezas del campamento y los huertos.
func _scan_props_sources() -> void:
	_prop_sources.clear()
	_extra_hidden_2d.clear()
	if vm == null or not is_instance_valid(vm.entities_root):
		return
	for c in vm.entities_root.get_children():
		if c is ChickenCoop:
			_coop_node = c
			for sub in c.get_children():
				if sub is Sprite2D and (sub.name == "FeederSprite" or sub.name == "NestSprite"):
					_add_prop_source(sub as Sprite2D)
				elif sub is Line2D or sub is Polygon2D:
					_extra_hidden_2d.append(sub)
			continue
		if c is Sprite2D:
			_add_prop_source(c as Sprite2D)
		elif c is FarmPlot:
			for sub in c.get_children():
				if sub is Sprite2D:
					_add_prop_source(sub as Sprite2D, true)
		elif c is CampSite:
			_camp_node = c
			_collect_camp_sprites(c)
			var hr: Node = c.get_node_or_null("PlayerHouseRoot")
			if hr != null:
				_collect_canvas_items(hr, _extra_hidden_2d)
	_sync_props_3d(false)


func _collect_canvas_items(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is CanvasItem and not (c is Area2D):
			out.append(c)
		if c.get_child_count() > 0:
			_collect_canvas_items(c, out)


func _add_prop_source(spr: Sprite2D, in_plot: bool = false) -> void:
	var kind := "crop" if in_plot and spr.name == "CropSprite" else _prop_kind_for(spr)
	if kind == "crop" and not in_plot:
		return
	if not kind.is_empty():
		_prop_sources.append({"sprite": spr, "kind": kind})


## La casa mejorada del jugador (cabaña o casa de piedra) aún no tiene 3D: sus piezas se quedan en 2D.
func _collect_camp_sprites(n: Node) -> void:
	for c in n.get_children():
		if c.name == "PlayerHouseRoot":
			continue
		if c is Sprite2D:
			_add_prop_source(c as Sprite2D)
		if c.get_child_count() > 0:
			_collect_camp_sprites(c)


func _sync_props_3d(only_update: bool) -> void:
	if nature_root_3d == null:
		return
	var use_3d: bool = CharacterAvatar3DScript.use_3d_characters
	var alive: Dictionary = {}
	for src in _prop_sources:
		var spr_v = src["sprite"]
		if not is_instance_valid(spr_v):
			continue # p. ej. el cartel de un solar que ya se construyó
		var spr: Sprite2D = spr_v
		var id := spr.get_instance_id()
		alive[id] = true
		var kind: String = src["kind"]
		var variant := _tex_file(spr.texture) if kind in ["soil", "crop", "feeder", "nest"] else kind
		var rec: Dictionary = _prop_nodes.get(id, {})
		var stale: bool = not rec.is_empty() and String(rec.get("variant", "")) != variant
		if stale:
			var old_root = rec.get("root")
			if old_root is Node3D and is_instance_valid(old_root):
				(old_root as Node3D).queue_free()
			rec = {}
		if rec.is_empty() and (not only_update or stale) and kind != "hide":
			var root := Node3D.new()
			root.name = "Prop3D_" + kind
			nature_root_3d.add_child(root)
			_build_prop_3d(root, kind, spr)
			rec = {"root": root, "variant": variant}
			_prop_nodes[id] = rec
		var r3 = rec.get("root")
		if r3 is Node3D and is_instance_valid(r3):
			(r3 as Node3D).visible = spr.is_visible_in_tree() and spr.texture != null
		spr.self_modulate.a = 0.0 if use_3d else 1.0
	for ci in _extra_hidden_2d:
		if is_instance_valid(ci):
			(ci as CanvasItem).self_modulate.a = 0.0 if use_3d else 1.0
	_sync_player_house_3d()
	_sync_coop_3d()
	if only_update:
		return
	for id in _prop_nodes.keys():
		if not alive.has(id):
			var r = _prop_nodes[id].get("root")
			if r is Node3D and is_instance_valid(r):
				(r as Node3D).queue_free()
			_prop_nodes.erase(id)


func _build_prop_3d(root: Node3D, kind: String, spr: Sprite2D) -> void:
	var pos: Vector2 = spr.global_position
	var m_wood := _mat("prop_wood", Color(0.62, 0.46, 0.30), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78)
	var m_dark := _mat("prop_dark_wood", Color(0.40, 0.28, 0.18), 0.9, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78)
	var m_iron := _mat("prop_iron", Color(0.30, 0.31, 0.33), 0.6, 0.5)
	match kind:
		"well":
			if _add_model_2d(root, "exterior/Well.obj", pos, 0.0, Vector2.ZERO, 24.0) == null:
				_add_cyl_2d(root, pos, 8.5, 0.0, 7.5, _mat("well_stone", Color(0.58, 0.57, 0.54), 0.9, 0.02), 8.5, 14)
		"compost":
			_add_box_2d(root, pos, Vector2(18, 13), 0.0, 9.0, m_wood)
			_add_box_2d(root, pos, Vector2(15, 10), 8.6, 1.2, _mat("compost_soil", Color(0.25, 0.18, 0.11), 0.98, 0.0))
		"tent":
			var m_canvas := _mat("tent_canvas", Color(0.80, 0.71, 0.52), 0.95, 0.0)
			_add_prism_2d(root, pos + Vector2(0, 2), Vector2(32, 22), 0.0, 17.0, m_canvas, false)
			_add_box_2d(root, pos + Vector2(0, 13.2), Vector2(7, 0.6), 0.0, 10.0, _mat("tent_door", Color(0.22, 0.17, 0.12), 0.95, 0.0))
		"campfire":
			_add_model_2d(root, "exterior/Bonfire_Lit.obj", pos, 0.0, Vector2(16, 16), 9.0)
			_add_model_2d(root, "exterior/Cauldron.obj", pos, 2.5, Vector2(10, 10), 7.0)
			if not _is_headless:
				var lt := OmniLight3D.new()
				lt.position = to_3d(pos, 10.0)
				lt.light_color = Color(1.0, 0.62, 0.28)
				lt.light_energy = 1.2
				lt.omni_range = 2.6
				root.add_child(lt)
		"log_seat":
			# Tronco tumbado: el modelo de leña sale de pie al encajarlo, así que va hecho a mano.
			var log_mi := _add_cyl_2d(root, pos, 3.2, 0.0, 22.0, m_dark, 3.2, 8)
			log_mi.rotation_degrees.z = 90.0
			log_mi.position = to_3d(pos, 3.2)
		"sign":
			_add_box_2d(root, pos + Vector2(0, 4), Vector2(2.2, 2.2), 0.0, 13.0, m_dark)
			_add_box_2d(root, pos + Vector2(0, 4.5), Vector2(15, 1.6), 7.0, 8.0, m_wood)
		"generator":
			if _add_model_2d(root, "props/Crate_Metal.gltf", pos, 0.0, Vector2(16, 14), 12.0) == null:
				_add_box_2d(root, pos, Vector2(16, 14), 0.0, 12.0, m_iron)
			_add_cyl_2d(root, pos + Vector2(4, -2), 1.6, 12.0, 6.0, m_iron, 1.6, 8)
		"sprinkler":
			_add_cyl_2d(root, pos, 1.4, 0.0, 7.0, m_iron, 1.4, 8)
			_add_cyl_2d(root, pos, 3.0, 7.0, 1.4, m_iron, 1.6, 8)
		"soil":
			var wet: bool = _tex_file(spr.texture) == "soil_wet.png"
			var m_soil := _mat("plot_soil_wet" if wet else "plot_soil_dry", Color(0.30, 0.21, 0.13) if wet else Color(0.50, 0.37, 0.24), 0.97, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.5)
			_add_box_2d(root, pos, Vector2(21, 21), 0.0, 1.6, m_soil)
			for fy in [-6.0, 0.0, 6.0]:
				_add_box_2d(root, pos + Vector2(0, fy), Vector2(19, 2.6), 1.6, 1.0, m_soil)
		"crop":
			_build_crop_3d(root, pos, _tex_file(spr.texture))
		"feeder":
			# Comedero: artesa de tablas con más o menos grano según lo lleno que esté
			var tf := _tex_file(spr.texture)
			_add_box_2d(root, pos, Vector2(18, 8), 0.0, 4.0, m_wood)
			if tf != "coop_feeder_empty.png":
				var grain_h: float = 1.0 if tf == "coop_feeder_half.png" else 2.2
				_add_box_2d(root, pos, Vector2(15, 5.5), 4.0, grain_h, _mat("coop_grain", Color(0.86, 0.72, 0.36), 0.95, 0.0))
		"nest":
			# Nido: caja baja con paja y, si hay, huevos
			_add_box_2d(root, pos, Vector2(16, 13), 0.0, 4.0, m_dark)
			_add_box_2d(root, pos, Vector2(13, 10), 4.0, 1.2, _mat("coop_straw", Color(0.84, 0.74, 0.42), 0.97, 0.0))
			if _tex_file(spr.texture) == "coop_nest_eggs.png":
				var m_egg := _mat("coop_egg", Color(0.96, 0.92, 0.82), 0.7, 0.0)
				for off in [Vector2(-2.5, -1), Vector2(2.5, 0.5), Vector2(0, 2.5)]:
					_add_cyl_2d(root, pos + off, 1.6, 5.0, 2.4, m_egg, 1.0, 6)


## Casa mejorada del jugador (nivel 2 = cabaña de madera, 3 = casa de piedra con cofre). Copia la planta de la 2D
## (CampSite._rebuild_house_visuals): mismo centro, tamaño y puerta de 28 px al sur. En nivel 1 es la tienda de campaña.
func _sync_player_house_3d() -> void:
	if not is_instance_valid(_camp_node) or nature_root_3d == null:
		return
	var tier: int = int(_camp_node.get("house_tier"))
	if tier == _player_house_tier and is_instance_valid(_player_house_3d):
		return
	_player_house_tier = tier
	if is_instance_valid(_player_house_3d):
		_player_house_3d.queue_free()
	_player_house_3d = null
	_player_house_roof = null
	if tier <= 1:
		return
	var root := Node3D.new()
	root.name = "PlayerHouse3D"
	nature_root_3d.add_child(root)
	_player_house_3d = root
	var stone: bool = tier >= 3
	var c: Vector2 = _camp_node.global_position + CampSite.TENT_OFFSET + Vector2(-8, -8)
	var size: Vector2 = Vector2(82, 60) if stone else Vector2(68, 52)
	var half: Vector2 = size * 0.5
	_player_house_rect = Rect2(c - half, size)
	var m_floor := _mat("ph_floor_stone" if stone else "ph_floor_wood", Color(0.62, 0.60, 0.56) if stone else Color(0.62, 0.46, 0.30), 0.9, 0.02, Color.BLACK, 0.0, "town_textures/floor_stone.png" if stone else "town_textures/floor_wood_planks.png", "", 0.55)
	var m_wall := _mat("ph_wall_stone" if stone else "ph_wall_timber", Color(0.70, 0.68, 0.64) if stone else Color(0.80, 0.70, 0.56), 0.9, 0.02, Color.BLACK, 0.0, "town_textures/wall_stone.png" if stone else "town_textures/wall_timber.png", "", 0.55)
	var m_roof := _mat("ph_roof_tile" if stone else "ph_roof_thatch", Color(0.72, 0.42, 0.32) if stone else Color(0.80, 0.68, 0.42), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/roof_clay_red_center.png" if stone else "town_textures/roof_thatch_center.png", "", 0.5)
	var wall_h: float = 30.0 if stone else 26.0
	var t: float = 6.0
	var door_w: float = 28.0
	var side_w: float = (size.x - door_w) * 0.5
	_add_box_2d(root, c, size, 0.0, 1.4, m_floor)
	_add_box_2d(root, c + Vector2(0, -half.y), Vector2(size.x, t), 0.0, wall_h, m_wall)
	_add_box_2d(root, c + Vector2(-half.x, 0), Vector2(t, size.y), 0.0, wall_h, m_wall)
	_add_box_2d(root, c + Vector2(half.x, 0), Vector2(t, size.y), 0.0, wall_h, m_wall)
	_add_box_2d(root, c + Vector2(-half.x + side_w * 0.5, half.y), Vector2(side_w, t), 0.0, wall_h, m_wall)
	_add_box_2d(root, c + Vector2(half.x - side_w * 0.5, half.y), Vector2(side_w, t), 0.0, wall_h, m_wall)
	_add_box_2d(root, c + Vector2(0, half.y), Vector2(door_w + 4.0, t), wall_h - 6.0, 6.0, m_wall) # dintel
	var roof := Node3D.new()
	roof.name = "PlayerHouseRoof"
	root.add_child(roof)
	_add_prism_2d(roof, c, size + Vector2(10, 10), wall_h, 22.0 if stone else 20.0, m_roof, true)
	_player_house_roof = roof
	var bed_p: Vector2 = _camp_node.global_position + CampSite.TENT_OFFSET + Vector2(0, -4)
	if _add_model_2d(root, "props/Bed_Twin1.gltf", bed_p, 1.4, Vector2(18, 28), 9.0) == null:
		_add_box_2d(root, bed_p, Vector2(18, 28), 1.4, 6.0, m_wall)
	if stone:
		_add_model_2d(root, "props/Chest_Wood.gltf", _camp_node.global_position + CampSite.CHEST_OFFSET, 1.4, Vector2(14, 10), 9.0)
	if not _is_headless:
		var lt := OmniLight3D.new()
		lt.position = to_3d(c, wall_h * 0.7)
		lt.light_color = Color(1.0, 0.80, 0.55)
		lt.light_energy = 0.6
		lt.omni_range = 2.0
		roof.add_child(lt)


## Gallinero: cerca de postes y travesaños 3D en el mismo cuadrado que la 2D (76 x 60 px). El tramo de en medio del
## lado sur desaparece cuando un zorro abre un agujero (`is_breached`) y vuelve al repararlo.
func _sync_coop_3d() -> void:
	if not is_instance_valid(_coop_node) or nature_root_3d == null:
		return
	if not is_instance_valid(_coop_3d):
		_coop_3d = Node3D.new()
		_coop_3d.name = "ChickenCoop3D"
		nature_root_3d.add_child(_coop_3d)
		var c: Vector2 = _coop_node.global_position
		var m_post := _mat("coop_post", Color(0.50, 0.34, 0.20), 0.9, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78)
		var m_floor := _mat("coop_floor", Color(0.46, 0.36, 0.22), 0.97, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.5)
		_add_box_2d(_coop_3d, c, Vector2(76, 60), 0.0, 0.8, m_floor)
		var sides: Array = [[Vector2(-38, -30), Vector2(38, -30)], [Vector2(-38, -30), Vector2(-38, 30)], [Vector2(38, -30), Vector2(38, 30)],
			[Vector2(-38, 30), Vector2(-12, 30)], [Vector2(12, 30), Vector2(38, 30)]]
		for sd in sides:
			_build_fence_run_3d(_coop_3d, c + (sd[0] as Vector2), c + (sd[1] as Vector2), m_post)
		_coop_gap_3d = Node3D.new()
		_coop_3d.add_child(_coop_gap_3d)
		_build_fence_run_3d(_coop_gap_3d, c + Vector2(-12, 30), c + Vector2(12, 30), m_post)
	_coop_3d.visible = _coop_node.is_visible_in_tree()
	if is_instance_valid(_coop_gap_3d):
		_coop_gap_3d.visible = not bool(_coop_node.get("is_breached"))


func _build_fence_run_3d(parent: Node3D, a: Vector2, b: Vector2, m: Material) -> void:
	var length: float = a.distance_to(b)
	var n_posts: int = maxi(2, int(ceil(length / 12.0)) + 1)
	for i in range(n_posts):
		_add_box_2d(parent, a.lerp(b, float(i) / float(n_posts - 1)), Vector2(2.4, 2.4), 0.0, 11.0, m)
	var mid: Vector2 = (a + b) * 0.5
	var horiz: bool = absf(b.x - a.x) > absf(b.y - a.y)
	var rail_sz: Vector2 = Vector2(length, 1.4) if horiz else Vector2(1.4, length)
	_add_box_2d(parent, mid, rail_sz, 4.0, 1.4, m)
	_add_box_2d(parent, mid, rail_sz, 8.5, 1.4, m)


## Brote, planta a medias o planta madura según la imagen del cultivo 2D.
func _build_crop_3d(root: Node3D, pos: Vector2, tex_name: String) -> void:
	var m_leaf := _mat("crop_leaf", Color(0.36, 0.62, 0.24), 0.9, 0.0)
	if tex_name.begins_with("sprout"):
		for off in [Vector2(-5, -5), Vector2(5, 0), Vector2(-2, 6)]:
			_add_cyl_2d(root, pos + off, 2.0, 1.6, 5.5, m_leaf, 0.3, 5)
		return
	var mature := tex_name.contains("mature")
	var file := "nature/Plant_2.obj"
	var h := 7.0
	if tex_name.begins_with("wheat"):
		file = "nature/Wheat.obj"
		h = 19.0 if mature else 11.0
	elif tex_name.begins_with("cabbage"):
		file = "nature/Bush_1.obj"
		h = 11.0 if mature else 8.0
	elif tex_name.begins_with("carrot"):
		file = "nature/Plant_1.obj"
		h = 12.0 if mature else 8.0
	if _add_model_2d(root, file, pos, 1.6, Vector2(20, 20), h) == null:
		_add_cyl_2d(root, pos, 5.0, 1.6, h, m_leaf, 2.0, 6)
	if mature and tex_name.begins_with("carrot"):
		var m_carrot := _mat("crop_carrot", Color(0.92, 0.48, 0.14), 0.85, 0.0)
		for off in [Vector2(-4, 3), Vector2(3, 4), Vector2(0, -4)]:
			_add_cyl_2d(root, pos + off, 1.4, 1.6, 1.5, m_carrot, 1.0, 6)


## Oculta las tiras planas 2D de muros/puertas/suelos cuando el 3D está activo (usando `self_modulate.a`
## en lugar de `.visible`, de modo que ningún test de estado de puertas o ventanas se vea afectado).
func _sync_2d_flat_visuals(use_3d: bool) -> void:
	if vm == null or not is_instance_valid(vm.entities_root):
		return
	var target_a: float = 0.0 if use_3d else 1.0
	# Pinos, rocas y objetos quietos con versión 3D: se esconden en 3D y vuelven al pasar a 2D (F10).
	for src in _nature_sources + _prop_sources:
		var spr_n = src.get("sprite")
		if spr_n is CanvasItem and is_instance_valid(spr_n):
			(spr_n as CanvasItem).self_modulate.a = target_a
	for ci in _extra_hidden_2d:
		if is_instance_valid(ci):
			(ci as CanvasItem).self_modulate.a = target_a
	var inner_rects: Array[Rect2] = []
	for b in vm.building_footprints:
		inner_rects.append((b["rect"] as Rect2).grow(-3.0))
	for child in vm.entities_root.get_children():
		# Muebles y suelos 2D dentro de los edificios (camas, mesas, alfombras…): el interior 3D ya los tiene.
		if (child is Sprite2D or child is TextureRect or child is Polygon2D) and (child as CanvasItem).z_index <= 0 and not child.has_meta("flat_2d_building_visual"):
			var cpos: Vector2 = (child as Node2D).global_position if child is Node2D else (child as Control).global_position + (child as Control).size * 0.5
			for ir in inner_rects:
				if ir.has_point(cpos):
					(child as CanvasItem).self_modulate.a = target_a
					break
		if child.has_meta("flat_2d_building_visual"):
			if child is CanvasItem:
				(child as CanvasItem).self_modulate.a = target_a
		elif child is StaticBody2D:
			for sub in child.get_children():
				if sub is TextureRect:
					(sub as TextureRect).self_modulate.a = target_a
	for d_entry in vm.building_doors:
		var sc: Sprite2D = d_entry.get("spr_closed")
		var so: Sprite2D = d_entry.get("spr_open")
		if is_instance_valid(sc):
			sc.self_modulate.a = target_a
		if is_instance_valid(so):
			so.self_modulate.a = target_a
	for w_entry in vm.building_windows:
		var sw: Sprite2D = w_entry.get("sprite")
		if is_instance_valid(sw):
			sw.self_modulate.a = target_a
	for sv in get_tree().get_nodes_in_group("sewer_visual_2d"):
		if sv is CanvasItem and is_instance_valid(sv):
			(sv as CanvasItem).visible = not use_3d
	for rf in get_tree().get_nodes_in_group("ranch_fence_2d"):
		if rf is CanvasItem and is_instance_valid(rf):
			(rf as CanvasItem).self_modulate.a = target_a
