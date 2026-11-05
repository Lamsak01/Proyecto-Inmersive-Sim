@tool
extends Node2D

## Escenario 3D Low-Poly / Greybox Estilizado del Valle («La Placa de Petri» - Fase 2)
## - Renderiza terreno, caminos, plaza, pozos, parque, mirador del lago, ciénaga, lavadero,
##   cementerio parroquial, farolas con luz real, todos los edificios y solares, interiores 3D,
##   puertas abatibles, postigos de ventanas, tejados con apertura automática (Cutaway),
##   altillos (+1), alcantarillas (-1) y el asentamiento fronterizo «Puesto del Paso».
## - Se sincroniza 1:1 con las coordenadas 2D de colisión y navegación, permitiendo alternar
##   en vivo entre 2D y 3D con la tecla [F9] sin alterar ni una sola regla ni test del juego.

const CharacterAvatar3DScript = preload("res://scripts/visuals/CharacterAvatar3D.gd")
const AssetLib = preload("res://scripts/visuals/AssetLibrary3D.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const VillageCulture = preload("res://scripts/systems/VillageCulture.gd")

const WORLD_SCALE: float = 0.02
const PITCH_DEG: float = 58.0
## Resolución interna baja + filtrado pixelado: el 3D se ve con píxeles gruesos, como el pixel art 2D.
const VIEWPORT_W: int = 640
const VIEWPORT_H: int = 360
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
		sun_light.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
		sun_light.light_energy = 0.96
		sun_light.light_color = Color(1.0, 0.95, 0.86)
		sun_light.shadow_enabled = false
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
		stage_sprite.z_index = -1
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

	# Los 3 Pozos de Agua 3D reales (Granja, Taberna, Plaza)
	var wells: Array[Vector2] = [Vector2(184, 82), Vector2(440, -306), Vector2(412, 54)]
	for wp in wells:
		if _add_model_2d(terrain_root_3d, "exterior/Well.obj", wp, 0.0, Vector2.ZERO, 24.0) == null:
			_add_cyl_2d(terrain_root_3d, wp, 8.5, 0.0, 7.5, m_stone, 8.5, 14)
			_add_cyl_2d(terrain_root_3d, wp, 6.5, 0.5, 6.2, m_water, 6.5, 12)

	# Compostador, carretas y barriles de la Granja y Rancho Sur
	var cp: Vector2 = vm._compost_pos if vm != null else Vector2(184, 114)
	_add_box_2d(terrain_root_3d, cp, Vector2(14.0, 12.0), 0.0, 9.0, m_dark_wood)
	_add_box_2d(terrain_root_3d, cp, Vector2(11.0, 9.0), 1.0, 7.5, _mat("compost_soil", Color(0.28, 0.20, 0.12), 0.95, 0.0))
	_add_model_2d(terrain_root_3d, "props/Stall_Cart_Empty.gltf", Vector2(204, 108), 0.0, Vector2.ZERO, 16.0, 25.0)
	_add_model_2d(terrain_root_3d, "props/FarmCrate_Apple.gltf", Vector2(168, 92), 0.0, Vector2.ZERO, 8.0)
	_add_model_2d(terrain_root_3d, "props/FarmCrate_Carrot.gltf", Vector2(168, 104), 0.0, Vector2.ZERO, 8.0)

	# Animales 3D reales en el Rancho del Sur
	_add_model_2d(terrain_root_3d, "animals/Cow.obj", Vector2(145, 290), 0.0, Vector2.ZERO, 16.0, 35.0)
	_add_model_2d(terrain_root_3d, "animals/Horse.obj", Vector2(185, 298), 0.0, Vector2.ZERO, 19.0, -40.0)
	_add_model_2d(terrain_root_3d, "animals/Donkey.obj", Vector2(118, 305), 0.0, Vector2.ZERO, 15.0, 110.0)
	_add_model_2d(terrain_root_3d, "exterior/Hay.obj", Vector2(162, 276), 0.0, Vector2.ZERO, 11.0)

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

	# Lavadero Municipal (Vector2(98, 72))
	var wash_c := Vector2(98, 72)
	_add_box_2d(terrain_root_3d, wash_c, Vector2(46, 32), 0.0, 2.0, m_stone)
	_add_box_2d(terrain_root_3d, wash_c, Vector2(32, 14), 2.0, 5.5, m_curb)
	_add_box_2d(terrain_root_3d, wash_c, Vector2(28, 10), 2.5, 4.8, m_water)
	for wp_off in [Vector2(-19, -12), Vector2(19, -12), Vector2(-19, 12), Vector2(19, 12)]:
		_add_box_2d(terrain_root_3d, wash_c + wp_off, Vector2(2.5, 2.5), 2.0, 18.0, m_dark_wood)
	_add_box_2d(terrain_root_3d, wash_c, Vector2(50, 36), 20.0, 4.5, m_shingle)
	_add_model_2d(terrain_root_3d, "props/Bucket_Wooden_1.gltf", wash_c + Vector2(-14, 10), 2.0, Vector2.ZERO, 6.5)
	_add_model_2d(terrain_root_3d, "props/Barrel.gltf", wash_c + Vector2(16, -10), 2.0, Vector2.ZERO, 10.0)

	# Mirador del Lago (Vector2(-250, -140)) con Glorieta 3D real
	var lake_c := Vector2(-250, -140)
	_add_cyl_2d(terrain_root_3d, lake_c + Vector2(-42, 0), 44.0, 0.0, 1.5, m_water, 44.0, 20)
	_add_box_2d(terrain_root_3d, lake_c + Vector2(8, 0), Vector2(36, 26), 0.0, 3.0, m_stone)
	_add_model_2d(terrain_root_3d, "exterior/Gazebo.obj", lake_c + Vector2(10, 0), 3.0, Vector2.ZERO, 26.0)
	_build_bench_3d(terrain_root_3d, lake_c + Vector2(12, 0), m_wood, m_iron)
	_add_model_2d(terrain_root_3d, "nature/Willow_1.obj", lake_c + Vector2(-14, -26), 0.0, Vector2.ZERO, 32.0)

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

	# Rejillas superficiales de acceso a las Alcantarillas (-1)
	for gp in [Vector2(345, -158), Vector2(898, 168), Vector2(-610, 82)]:
		_add_box_2d(terrain_root_3d, gp, Vector2(14, 14), 0.0, 1.8, m_iron)
		_add_box_2d(terrain_root_3d, gp, Vector2(10, 10), 1.8, 0.6, _mat("sewer_dark", Color(0.08, 0.12, 0.10), 0.9, 0.2))

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
		var wall_h: float = float(style["wall_h"])
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

		# Muro cerrado (opuesto a la puerta)
		var closed_y: float = (center.y - half.y) if door_south else (center.y + half.y)
		_add_box_2d(b_root, Vector2(center.x, closed_y), Vector2(sz.x, wall_t), 2.0, wall_h, m_wall)

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

		# 7. Cornisa perimetral 3D (siempre visible) + Tejado central con apertura automática (Cutaway)
		var eave_h: float = 3.2
		_add_box_2d(b_root, Vector2(center.x, rect.position.y), Vector2(sz.x + 8.0, 7.0), wall_h + 2.0, eave_h, m_roof)
		_add_box_2d(b_root, Vector2(center.x, rect.end.y), Vector2(sz.x + 8.0, 7.0), wall_h + 2.0, eave_h, m_roof)
		_add_box_2d(b_root, Vector2(rect.position.x, center.y), Vector2(7.0, sz.y + 8.0), wall_h + 2.0, eave_h, m_roof)
		_add_box_2d(b_root, Vector2(rect.end.x, center.y), Vector2(7.0, sz.y + 8.0), wall_h + 2.0, eave_h, m_roof)
		# Frontón sobre la puerta
		_add_box_2d(b_root, Vector2(door_pos.x, door_y), Vector2(door_w + 8.0, 8.0), wall_h + 5.0, 4.5, m_roof)

		var roof_cap := Node3D.new()
		roof_cap.name = "RoofCap_" + b_id
		b_root.add_child(roof_cap)
		_add_box_2d(roof_cap, center, sz + Vector2(4.0, 4.0), wall_h + 4.5, roof_h * 0.45, m_roof)
		_add_box_2d(roof_cap, center, sz * 0.72, wall_h + 4.5 + roof_h * 0.45, roof_h * 0.35, m_roof)
		_add_box_2d(roof_cap, center, Vector2(sz.x * 0.48, sz.y * 0.38), wall_h + 4.5 + roof_h * 0.80, roof_h * 0.22, m_trim)
		# Superestructura 3D esculpida sobre el tejado (se oculta limpiamente en modo Cutaway)
		if b_id == "building_church":
			_add_model_2d(roof_cap, "buildings/Bell_Tower.obj", center + Vector2(0, -half.y + 18.0), wall_h + 4.0, Vector2(28.0, 28.0), 38.0)
		elif b_id == "building_tavern":
			_add_model_2d(roof_cap, "buildings/Inn.obj", center, wall_h + 4.0, sz * 0.65, roof_h + 14.0)
			_add_model_2d(roof_cap, "fantasy_town/chimney.glb", center + Vector2(half.x * 0.45, -half.y * 0.35), wall_h + 4.0, Vector2(10.0, 10.0), roof_h + 12.0)
		elif b_id == "shop_family_smith":
			_add_model_2d(roof_cap, "buildings/Blacksmith.obj", center, wall_h + 4.0, sz * 0.68, roof_h + 12.0)
			_add_model_2d(roof_cap, "fantasy_town/chimney.glb", center + Vector2(-half.x * 0.35, -half.y * 0.30), wall_h + 4.0, Vector2(12.0, 12.0), roof_h + 16.0)
		else:
			_add_model_2d(roof_cap, "fantasy_town/chimney.glb", center + Vector2(half.x * 0.45, -half.y * 0.35), wall_h + 4.0, Vector2(9.0, 9.0), roof_h + 10.0)

		_building_records_3d.append({
			"id": b_id,
			"rect": rect,
			"root": b_root,
			"roof_cap": roof_cap,
			"loft_root": loft_root,
		})

	# Cofres domésticos 3D sincronizados con `vm.house_chests`
	for ch in vm.house_chests:
		var c_pos: Vector2 = ch.get("pos", Vector2.ZERO)
		var ch_root := Node3D.new()
		buildings_root_3d.add_child(ch_root)
		_add_model_2d(ch_root, "props/Chest_Wood.gltf", c_pos, 2.0, Vector2(12.0, 8.5), 7.5)
		var lid := _add_box_2d(ch_root, c_pos, Vector2(11.4, 7.8), 7.5, 1.8, m_gold)
		_chest_nodes_3d.append({"entry": ch, "lid": lid})

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
		var c: Vector2 = l_dict["center"]
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
	var m_brick := _mat("sewer_brick", Color(0.28, 0.34, 0.30), 0.90, 0.05, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.35)
	var m_water := _mat("sewer_water", Color(0.14, 0.46, 0.36, 0.92), 0.25, 0.15, Color(0.10, 0.42, 0.30), 0.35)

	# Cámaras subterráneas bajo Posada, Comisaría y Ciénaga + galería de conexión
	var chambers: Array[Vector2] = [Vector2(345, -158), Vector2(898, 168), Vector2(-610, 82)]
	for ch_p in chambers:
		_add_box_2d(sewers_root_3d, ch_p, Vector2(96, 72), 0.0, 2.0, m_brick)
		_add_box_2d(sewers_root_3d, ch_p, Vector2(36, 26), 2.0, 1.2, m_water)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(0, -34), Vector2(96, 6), 2.0, 22.0, m_brick)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(0, 34), Vector2(96, 6), 2.0, 22.0, m_brick)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(-46, 0), Vector2(6, 72), 2.0, 22.0, m_brick)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(46, 0), Vector2(6, 72), 2.0, 22.0, m_brick)
		_add_model_2d(sewers_root_3d, "props/Crate_Wooden.gltf", ch_p + Vector2(26, -18), 2.0, Vector2(12, 12), 9.0)
		_add_model_2d(sewers_root_3d, "props/Barrel.gltf", ch_p + Vector2(-26, 18), 2.0, Vector2(9, 9), 9.5)

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
# 6. SINCRONIZACIÓN EN VIVO (CÁMARA 3D, PUERTAS, TEJADOS CUTAWAY Y TECLA [F9])
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
		sewers_root_3d.visible = (vm.player_elevation_level == -1)

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
		# Un vecino dentro solo abre el tejado si el jugador anda cerca (≈ media pantalla); así el resto del pueblo
		# conserva sus tejados y se ve como un pueblo, no como una maqueta destapada.
		if not open_roof and rect.grow(150.0).has_point(pl_pos):
			for n in get_tree().get_nodes_in_group("village_npcs"):
				if n is Node2D and is_instance_valid(n) and not bool(n.get("is_dead")):
					if r_inside.has_point((n as Node2D).global_position):
						open_roof = true
						break
		roof_cap.visible = not open_roof
		if is_instance_valid(loft_root):
			loft_root.visible = (elev == 1 and r_near.has_point(pl_pos))

	# Luz diurna/nocturna y farolas eléctricas 3D
	var wc2 = get_node_or_null("/root/WorldClock")
	var gm2 = get_node_or_null("/root/GameManager")
	var hour: int = int(wc2.current_hour) if wc2 != null else 12
	var is_night: bool = (hour >= 19 or hour < 6)
	var is_dusk: bool = (hour in [6, 7, 17, 18])
	var grid_on: bool = gm2 != null and bool(gm2.get_flag("electric_grid_active", false)) and VillageCulture.is_lamps_powered(vm)

	if is_instance_valid(sun_light):
		if is_night:
			sun_light.light_energy = 0.38
			sun_light.light_color = Color(0.58, 0.68, 0.95)
		elif is_dusk:
			sun_light.light_energy = 0.82
			sun_light.light_color = Color(1.0, 0.78, 0.56)
		else:
			sun_light.light_energy = 1.14
			sun_light.light_color = Color(1.0, 0.96, 0.88)

	var lamps_lit: bool = is_night or grid_on
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

## Oculta las tiras planas 2D de muros/puertas/suelos cuando el 3D está activo (usando `self_modulate.a`
## en lugar de `.visible`, de modo que ningún test de estado de puertas o ventanas se vea afectado).
func _sync_2d_flat_visuals(use_3d: bool) -> void:
	if vm == null or not is_instance_valid(vm.entities_root):
		return
	var target_a: float = 0.0 if use_3d else 1.0
	for child in vm.entities_root.get_children():
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
