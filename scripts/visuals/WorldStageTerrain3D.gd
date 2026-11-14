@tool
extends "res://scripts/visuals/WorldStageBuildings3D.gd"

## Terreno 3D, relieve suave (Fases A y B), caminos, plaza, lago, ciénaga, barrios y vegetación.

const Sitio = preload("res://mapa/sitio.gd") ## cruces del mapa (barro rojo del molino y claro del Caso I)
## Barro del Caso I en las orillas: rojo junto al molino y pardo en el claro del cuerpo (medidas en píxeles del mundo).
const BARRO_ROJO_MEDIO_LARGO_PX: float = 400.0 ## ~22 m de orilla roja a cada lado de su cruz
const BARRO_ROJO_ANCHO_PX: float = 60.0        ## la lengua roja llega ~3,4 m tierra adentro junto a la cruz
const CLARO_MEDIO_LARGO_PX: float = 245.0      ## ~14 m de barro pardo a cada lado del claro
const SECTORES_SUELO_X: int = 8
const SECTORES_SUELO_Y: int = 6
const LOTE_NATURALEZA_M: float = 96.0
const TROZO_TERRENO_M: float = 72.0
const TAM_MAX_JUNTAR_FACTOR: float = 0.65
const TAM_SOMBRA_MIN_M: float = 0.62
const TRAMO_RIO_CORTE_UNIDADES: float = 1600.0
const PASO_RIO_FINO: float = 6.0
const PASO_RIO_RECTO: float = 10.0
const MARGEN_CRUCE_FINO: float = 90.0
const ALCANCE_MATA_LOTE_1P_M: float = 48.0

# ==============================================================================
# SUELO 3D Y NATURALEZA (2026-11-05): sustituyen a la hierba y a los pinos dibujados en 2D
# ==============================================================================
## Agua con movimiento (2026-11-11): material con el efecto `shaders/agua.gdshader` para el río y el lago. Sin ventana
## (pruebas), un material normal.
func _mat_agua(key: String, col: Color) -> Material:
	if _mat_cache.has(key):
		return _mat_cache[key]
	if _is_headless:
		return _mat(key + "_hl", col, 0.12, 0.14)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/agua.gdshader")
	sm.set_shader_parameter("tex", AssetLib.load_texture("town_textures/floor_ground_water.png"))
	sm.set_shader_parameter("tinte", col)
	_mat_cache[key] = sm
	return sm


func _make_ground_shader_mat(key: String, c_prim: Color, c_sec: Color, c_earth: Color, dirt_b: float) -> Material:
	if _mat_cache.has(key):
		return _mat_cache[key]
	if _is_headless:
		return _mat(key + "_hl", c_prim, 0.95, 0.0)
	var sh := Shader.new()
	sh.code = GROUND_TERRAIN_SHADER_CODE
	var sm := ShaderMaterial.new()
	sm.shader = sh
	sm.set_shader_parameter("escala_mundo", Mapa3D.K)
	var t_grass := AssetLib.load_texture("town_textures/floor_ground_grass.png")
	var t_over := AssetLib.load_texture("town_textures/floor_ground_grass_overlay.png")
	var t_dirt := AssetLib.load_texture("town_textures/floor_ground_dirt.png")
	if t_grass != null:
		sm.set_shader_parameter("tex_grass", t_grass)
	if t_over != null:
		sm.set_shader_parameter("tex_overlay", t_over)
	if t_dirt != null:
		sm.set_shader_parameter("tex_dirt", t_dirt)
	sm.set_shader_parameter("tint_primary", c_prim)
	sm.set_shader_parameter("tint_secondary", c_sec)
	sm.set_shader_parameter("tint_earth", c_earth)
	sm.set_shader_parameter("dirt_blend", dirt_b)
	_mat_cache[key] = sm
	return sm

## Suelo opaco 3D con malla de relieve continuo repartida por sectores indexados (solo se dibujan los que caen en cámara
## y el suelo recibe sombras sin proyectarlas sobre sí mismo).
func _build_ground_3d() -> void:
	var m_terrain: Material = _make_ground_shader_mat("ground_terrain_heightfield_sh", Color(0.28, 0.40, 0.21), Color(0.20, 0.30, 0.15), Color(0.37, 0.29, 0.19), 0.26)
	if m_terrain is ShaderMaterial:
		(m_terrain as ShaderMaterial).set_shader_parameter("use_vertex_biomes", 1.0)
	var min_x: float = -3450.0 * Mapa3D.E
	var max_x: float = 3050.0 * Mapa3D.E
	var min_y: float = -1850.0 * Mapa3D.E
	var max_y: float = 3250.0 * Mapa3D.E
	var step: float = 34.0 * maxf(1.0, Mapa3D.E * 0.4)
	var nx: int = int(ceil((max_x - min_x) / step))
	var ny: int = int(ceil((max_y - min_y) / step))
	var cols_total: int = nx + 1
	var rows_total: int = ny + 1
	var grid_v := PackedVector3Array()
	var grid_n := PackedVector3Array()
	var grid_c := PackedColorArray()
	grid_v.resize(cols_total * rows_total)
	grid_n.resize(cols_total * rows_total)
	grid_c.resize(cols_total * rows_total)
	for gy in range(rows_total):
		var py: float = minf(max_y, min_y + float(gy) * step)
		var base_row: int = gy * cols_total
		for gx in range(cols_total):
			var px: float = minf(max_x, min_x + float(gx) * step)
			var p2 := Vector2(px, py)
			var nrm: Vector3 = terrain_normal_3d(p2, step * 0.5)
			var gi: int = base_row + gx
			grid_v[gi] = to_3d(p2, 0.0)
			grid_n[gi] = nrm
			grid_c[gi] = _terrain_biome_color(p2, nrm)
	for sy in range(SECTORES_SUELO_Y):
		var y_ini: int = (ny * sy) / SECTORES_SUELO_Y
		var y_fin: int = (ny * (sy + 1)) / SECTORES_SUELO_Y
		for sx in range(SECTORES_SUELO_X):
			var x_ini: int = (nx * sx) / SECTORES_SUELO_X
			var x_fin: int = (nx * (sx + 1)) / SECTORES_SUELO_X
			_crear_sector_suelo_3d(terrain_root_3d, m_terrain, grid_v, grid_n, grid_c, cols_total, x_ini, x_fin, y_ini, y_fin, sx, sy)
	# Árboles perimetrales en el horizonte oeste y norte para cerrar el horizonte visual
	var horizon_trees := [
		Vector2(-2180, -680), Vector2(-2260, -480), Vector2(-2320, -260), Vector2(-2280, -80),
		Vector2(-2340, 120), Vector2(-2290, 340), Vector2(-2220, 560), Vector2(-1980, -820),
		Vector2(-1720, -890), Vector2(-1460, -920), Vector2(-1180, -940), Vector2(-880, -960),
	]
	for hti in range(horizon_trees.size()):
		var htp: Vector2 = horizon_trees[hti]
		var ht_file: String = "nature/PineTree_1.obj" if (hti % 2) == 0 else "nature/CommonTree_2.obj"
		var ht_node := _add_model_2d(terrain_root_3d, ht_file, htp, -1.2, Vector2.ZERO, 54.0 + float(hti % 4) * 6.0, float(hti * 47))
		if ht_node != null and nature_root_3d != null:
			_absorb_into_batches(ht_node, htp)
	# Matas de hierba, tréboles, helechos y flores silvestres 3D repartidas por praderas, cunetas, campamento y linde del bosque
	_build_ground_foliage_3d()


func _crear_sector_suelo_3d(
	parent: Node3D, mat: Material,
	grid_v: PackedVector3Array, grid_n: PackedVector3Array, grid_c: PackedColorArray,
	cols_total: int, x_ini: int, x_fin: int, y_ini: int, y_fin: int, sx: int, sy: int
) -> void:
	var w_q: int = x_fin - x_ini
	var h_q: int = y_fin - y_ini
	if w_q <= 0 or h_q <= 0:
		return
	var cols_s: int = w_q + 1
	var rows_s: int = h_q + 1
	var sv := PackedVector3Array()
	var sn := PackedVector3Array()
	var sc := PackedColorArray()
	var si_arr := PackedInt32Array()
	sv.resize(cols_s * rows_s)
	sn.resize(cols_s * rows_s)
	sc.resize(cols_s * rows_s)
	si_arr.resize(w_q * h_q * 6)
	for ly in range(rows_s):
		var g_row: int = (y_ini + ly) * cols_total
		var l_row: int = ly * cols_s
		for lx in range(cols_s):
			var gi: int = g_row + x_ini + lx
			var li: int = l_row + lx
			sv[li] = grid_v[gi]
			sn[li] = grid_n[gi]
			sc[li] = grid_c[gi]
	var ii: int = 0
	for ly in range(h_q):
		var r0: int = ly * cols_s
		var r1: int = (ly + 1) * cols_s
		for lx in range(w_q):
			var i00: int = r0 + lx
			var i10: int = i00 + 1
			var i01: int = r1 + lx
			var i11: int = i01 + 1
			si_arr[ii] = i00; si_arr[ii + 1] = i10; si_arr[ii + 2] = i11
			si_arr[ii + 3] = i00; si_arr[ii + 4] = i11; si_arr[ii + 5] = i01
			ii += 6
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = sv
	arrays[Mesh.ARRAY_NORMAL] = sn
	arrays[Mesh.ARRAY_COLOR] = sc
	arrays[Mesh.ARRAY_INDEX] = si_arr
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var sector_mi := MeshInstance3D.new()
	sector_mi.name = "TerrenoSuelo_%d_%d" % [sx, sy]
	sector_mi.mesh = am
	sector_mi.material_override = mat
	sector_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(sector_mi)

func _add_road_strip_3d(parent: Node3D, rect: Rect2, height_px: float, mat: Material) -> MeshInstance3D:
	if estirar_terreno:
		var tam: Vector2 = rect.size * Mapa3D.E
		rect = Rect2(Zona.estirar(rect.get_center()) - tam * 0.5, tam)
	var step: float = 20.0
	var nx: int = maxi(1, int(ceil(rect.size.x / step)))
	var ny: int = maxi(1, int(ceil(rect.size.y / step)))
	var dx: float = rect.size.x / float(nx)
	var dy: float = rect.size.y / float(ny)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iy in range(ny):
		var y0: float = rect.position.y + float(iy) * dy
		var y1: float = y0 + dy
		for ix in range(nx):
			var x0: float = rect.position.x + float(ix) * dx
			var x1: float = x0 + dx
			var mid_p := Vector2((x0 + x1) * 0.5, (y0 + y1) * 0.5)
			if mid_p.y >= RioLagoScript.river_y_start() and mid_p.y <= RioLagoScript.river_y_end() and absf(mid_p.x - RioLagoScript.river_center_x(mid_p.y)) <= RioLagoScript.river_half_width(mid_p.y) + 6.0:
				continue
			var p00 := Vector2(x0, y0)
			var p10 := Vector2(x1, y0)
			var p01 := Vector2(x0, y1)
			var p11 := Vector2(x1, y1)
			var v00: Vector3 = to_3d(p00, height_px)
			var v10: Vector3 = to_3d(p10, height_px)
			var v01: Vector3 = to_3d(p01, height_px)
			var v11: Vector3 = to_3d(p11, height_px)
			var n00: Vector3 = terrain_normal_3d(p00, 12.0)
			var n10: Vector3 = terrain_normal_3d(p10, 12.0)
			var n01: Vector3 = terrain_normal_3d(p01, 12.0)
			var n11: Vector3 = terrain_normal_3d(p11, 12.0)
			st.set_normal(n00); st.add_vertex(v00)
			st.set_normal(n10); st.add_vertex(v10)
			st.set_normal(n11); st.add_vertex(v11)
			st.set_normal(n00); st.add_vertex(v00)
			st.set_normal(n11); st.add_vertex(v11)
			st.set_normal(n01); st.add_vertex(v01)
	st.index()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

func _build_ground_foliage_3d() -> void:
	if _is_headless or not AssetLib.has_curated_assets():
		return
	var foliage_models: Array[String] = [
		"nature/Plant_1.obj", "nature/Plant_2.obj", "nature/Plant_3.obj",
		"nature/Flowers.obj", "nature/Plant_1.obj", "nature/Wheat.obj",
	]
	var lake_poly_guard: PackedVector2Array = RioLagoScript.lake_scaled(1.18, 12.0)
	var marsh_poly_guard := PackedVector2Array([
		Vector2(-1890, 195), Vector2(-1620, 150), Vector2(-1325, 165), Vector2(-1180, 240),
		Vector2(-1200, 405), Vector2(-1345, 485), Vector2(-1660, 500), Vector2(-1875, 435),
		Vector2(-1930, 310)
	])
	# La plaza va con su pieza del editor: se mira en el mundo, donde caerá la mata
	var plaza_guard: Rect2 = Zona.rect_mundo(ZONA_PLAZA_ID).grow(MATAS_MARGEN_PLAZA_PX)
	var idx: int = 0
	for gx in range(-2050, 1480, 95):
		for gy in range(-520, 1280, 95):
			idx += 1
			var jx: float = float(((idx * 73) % 59) - 29)
			var jy: float = float(((idx * 41) % 59) - 29)
			var fp := Vector2(float(gx) + jx, float(gy) + jy)
			var fp_mundo: Vector2 = Zona.estirar(fp) # donde la pone _add_model_2d (mapa ×E, zonas con su pieza)
			# Saltar calzadas principales, plaza central, lago, ciénaga y huellas de edificios
			if absf(fp.y - 50.0) < 30.0 or plaza_guard.has_point(fp_mundo):
				continue
			if Geometry2D.is_point_in_polygon(fp, lake_poly_guard) or Geometry2D.is_point_in_polygon(fp, marsh_poly_guard):
				continue
			if fp.distance_to(RioLagoScript.LAKE_NODE_POS) < 95.0 or terrain_height_px(fp) < -0.8:
				continue
			if fp.y >= RioLagoScript.river_y_start() and fp.y <= RioLagoScript.river_y_end() and absf(fp.x - RioLagoScript.river_center_x(fp.y)) < RioLagoScript.river_half_width(fp.y) + 18.0:
				continue
			if Rect2(Vector2(85.0, -915.0), Vector2(95.0, 100.0)).has_point(fp) or RioLagoScript.ABANDONED_MILL_RECT.grow(18.0).has_point(fp):
				continue
			if VillageRestaurant.RECT.grow(16.0).has_point(fp) or VillageTavern.RECT.grow(16.0).has_point(fp):
				continue
			if Rect2(Vector2(822.0, 260.0), Vector2(268.0, 168.0)).grow(10.0).has_point(fp):
				continue
			if vm != null and "building_footprints" in vm:
				var inside_b: bool = false
				for b_fp in vm.building_footprints: # huellas ya en el mundo: se comparan con el sitio real de la mata
					if (b_fp["rect"] as Rect2).grow(MATAS_MARGEN_EDIFICIO_PX).has_point(fp_mundo):
						inside_b = true
						break
				if inside_b:
					continue
			if fp.x > 160.0 and fp.x < 1380.0 and fp.y > -480.0 and fp.y < 360.0 and ((idx % 3) != 0):
				continue
			var mdl: String = foliage_models[idx % foliage_models.size()]
			var h_f: float = 4.2 + float(idx % 4) * 1.1
			var node_f := _add_model_2d(terrain_root_3d, mdl, fp, -0.8, Vector2.ZERO, h_f, float((idx * 53) % 360))
			if node_f != null and nature_root_3d != null:
				_marcar_mata_sin_sombra(node_f)
				_absorb_into_batches(node_f, fp)
	_flush_batches()


## Las matas de hierba y setas minúsculas reciben sombra pero no la proyectan (ahorra cientos de pasadas de sombra).
func _marcar_mata_sin_sombra(nodo: Node) -> void:
	for c: Node in nodo.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.set_meta(&"mata_baja", true)


## Lago 3D con abundante agua azul a cota -1.5 px, orillas suaves de hierba con juncos y piedras, y un único muelle a ras del agua.
func _build_lake_3d() -> void:
	var m_lake := _mat_agua("lake_water", Color(0.24, 0.54, 0.82, 0.92))
	var m_deep := _mat_agua("lake_deep", Color(0.14, 0.34, 0.60, 0.95))
	var mi_lago: MeshInstance3D = _add_flat_poly_2d(terrain_root_3d, RioLagoScript.lake_scaled(1.12, 8.0), -1.0, m_lake, true)
	if mi_lago != null and mi_lago.mesh != null and terrain_root_3d != null:
		var c_lago: AABB = mi_lago.mesh.get_aabb()
		var cx_l: float = c_lago.position.x + c_lago.size.x * 0.5
		var cz_l: float = c_lago.position.z + c_lago.size.z * 0.5
		var rx_l: float = c_lago.size.x * 0.44
		var rz_l: float = c_lago.size.z * 0.44
		var pts_lago := PackedVector3Array()
		for k_l: int in range(13):
			var ang_l: float = TAU * float(k_l) / 12.0
			pts_lago.append(Vector3(cx_l + cos(ang_l) * rx_l, c_lago.position.y, cz_l + sin(ang_l) * rz_l))
		terrain_root_3d.set_meta("puntos_lago_3d", pts_lago)
	_add_flat_poly_2d(terrain_root_3d, RioLagoScript.lake_scaled(0.66, 0.0), -0.8, m_deep, true)
	# El muelle y las piedras y plantas de la orilla son piezas de «Decorado» (editor del mapa)


## Superficie plana con la forma de un polígono del mapa 2D, a una altura dada (si absolute_h es true, no suma el relieve).
func _add_flat_poly_2d(parent: Node3D, pts: PackedVector2Array, h_px: float, mat: Material, absolute_h: bool = false) -> MeshInstance3D:
	if estirar_terreno:
		pts = Zona.estirar_puntos(pts)
	var idx := Geometry2D.triangulate_polygon(pts)
	if idx.is_empty():
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for i in idx:
		st.add_vertex(to_3d_flat(pts[i], h_px) if absolute_h else to_3d(pts[i], h_px))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


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
			if en_cauce_del_rio((n as Node2D).global_position, 2.0):
				(n as Node2D).visible = false # árbol talable que quedó dentro del río redibujado
				continue
			kind = "pine"
		elif ht == 2:
			kind = "rock"
		elif ht == 0:
			# Setas y hierbas que se recogen (2026-11-10): modelos 3D en vez del dibujo 2D
			kind = "forage_mushroom" if String(n.get("primary_item_id")) == "mushroom" else "forage_herb"
		if kind.is_empty():
			continue
		_nature_sources.append({"node": n, "kind": kind})
	# Setas y hierbas que se recogen (grupo «wild_flora», no «destructible»)
	for n in get_tree().get_nodes_in_group("wild_flora"):
		if n is Node2D and n.get("harvest_type") != null and int(n.get("harvest_type")) == 0:
			var fk: String = "forage_mushroom" if String(n.get("primary_item_id")) == "mushroom" else "forage_herb"
			_nature_sources.append({"node": n, "kind": fk})
	_sync_nature_3d(false)
	_scan_props_sources()


## Crea o actualiza el modelo 3D de cada elemento natural y oculta su dibujo 2D mientras el 3D esté activo.
func _sync_nature_3d(only_update: bool) -> void:
	if nature_root_3d == null:
		return
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
			(spr as CanvasItem).self_modulate.a = 0.0
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


## Pasa las mallas de un árbol, roca o seta a su lote por sector en metros; el nodo queda vacío y guarda dónde están sus copias.
func _absorb_into_batches(node: Node3D, _pos_2d: Vector2) -> void:
	var refs: Array = []
	var inv: Transform3D = nature_root_3d.global_transform.affine_inverse()
	var p3: Vector3 = node.global_position
	var cell := Vector2i(floori(p3.x / LOTE_NATURALEZA_M), floori(p3.z / LOTE_NATURALEZA_M))
	for c: Node in node.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if mi.mesh == null:
			continue
		var mat_ov: Material = mi.material_override
		var surfs: int = mi.mesh.get_surface_count()
		if mat_ov == null and surfs == 1:
			mat_ov = mi.get_surface_override_material(0)
		elif mat_ov == null and surfs > 1:
			var tiene_ov: bool = false
			for si in range(surfs):
				if mi.get_surface_override_material(si) != null:
					tiene_ov = true
					break
			if tiene_ov:
				continue
		var es_mata_baja: bool = mi.has_meta(&"mata_baja")
		var mat_id: int = mat_ov.get_instance_id() if mat_ov != null else 0
		var key := "%d_%d_%d_%d_%d_%d" % [mi.mesh.get_instance_id(), mat_id, int(mi.cast_shadow), int(es_mata_baja), cell.x, cell.y]
		var b: Dictionary = _batches.get(key, {})
		if b.is_empty():
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "Lote_" + key
			mmi.cast_shadow = mi.cast_shadow
			if mat_ov != null:
				mmi.material_override = mat_ov
			if es_mata_baja:
				mmi.set_meta(&"lote_mata_baja", true)
				if bool(get("first_person_active")):
					mmi.visibility_range_end = ALCANCE_MATA_LOTE_1P_M
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


func _make_nature_3d(n: Node2D, kind: String) -> Dictionary:
	var hv: int = absi(int(n.global_position.x * 13.0 + n.global_position.y * 7.0))
	var pos := n.global_position
	var rot: float = float(hv % 360)
	if kind == "pine":
		# Árboles variados por zona: robles/hayas frondosos, abedules de corteza blanca y pinos altos
		var village_trees := [
			"nature/CommonTree_1.obj", "nature/CommonTree_2.obj", "nature/BirchTree_1.obj",
			"nature/CommonTree_3.obj", "nature/BirchTree_2.obj", "nature/PineTree_1.obj",
			"nature/CommonTree_4.obj", "nature/BirchTree_3.obj", "nature/PineTree_2.obj",
		]
		var forest_trees := [
			"nature/PineTree_1.obj", "nature/CommonTree_1.obj", "nature/PineTree_2.obj",
			"nature/BirchTree_1.obj", "nature/PineTree_3.obj", "nature/CommonTree_2.obj",
			"nature/PineTree_4.obj", "nature/CommonTree_3.obj", "nature/BirchTree_2.obj",
			"nature/CommonTree_4.obj", "nature/BirchTree_3.obj",
		]
		var files: Array = forest_trees if pos.y >= 680.0 else village_trees
		var h: float = 52.0 + float(hv % 6) * 6.0
		var t := _add_model_2d(nature_root_3d, files[hv % files.size()], pos, -1.4, Vector2.ZERO, h, rot)
		var stump: Node3D = _add_cyl_2d(nature_root_3d, pos, 5.0, -1.2, 6.2, _mat("tree_stump", Color(0.45, 0.32, 0.20), 0.9, 0.0, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78), 4.5, 8)
		stump.visible = false
		return {"tree": t, "stump": stump}
	if kind == "forage_mushroom":
		# Kenney Nature Kit (CC0): seta roja o parda, sola, alta o en grupo
		var mfiles := ["nature/kenney/mushroom_redGroup.glb", "nature/kenney/mushroom_tan.glb", "nature/kenney/mushroom_red.glb",
			"nature/kenney/mushroom_tanGroup.glb", "nature/kenney/mushroom_redTall.glb", "nature/kenney/mushroom_tanTall.glb"]
		var mf: String = mfiles[hv % mfiles.size()]
		var m := _add_model_2d(nature_root_3d, mf, pos, -0.3, Vector2.ZERO, 7.5 if "Tall" in mf else 5.5, rot)
		if m != null:
			_marcar_mata_sin_sombra(m)
		return {"tree": m, "stump": null}
	if kind == "forage_herb":
		var hfiles := ["nature/Plant_4.obj", "nature/Plant_5.obj"]
		var hb := _add_model_2d(nature_root_3d, hfiles[hv % hfiles.size()], pos, -0.3, Vector2.ZERO, 8.5, rot)
		if hb != null:
			_marcar_mata_sin_sombra(hb)
		return {"tree": hb, "stump": null}
	if kind == "rock":
		var rfiles := ["nature/Rock_1.obj", "nature/Rock_2.obj", "nature/Rock_3.obj", "nature/Rock_4.obj", "nature/Rock_5.obj"]
		var r := _add_model_2d(nature_root_3d, rfiles[hv % rfiles.size()], pos, -1.4, Vector2.ZERO, 16.0, rot)
		var low := _add_model_2d(nature_root_3d, rfiles[(hv + 2) % rfiles.size()], pos, -1.2, Vector2.ZERO, 6.0, rot + 40.0)
		if low != null:
			low.visible = false
		return {"tree": r, "stump": low}
	return {}



## Rendimiento (Claude Code, 2026-11-09): las piezas quietas del terreno (sotobosque, rocas, barro y grava de las orillas,
## bancos, vallas…) se juntan por zonas de 256 px: muchas menos llamadas de dibujo y las zonas fuera de cámara siguen sin
## dibujarse. No se tocan las piezas grandes (suelo, caminos, agua), las de shader propio ni las que miran a cámara.
const TERRAIN_MERGE_CHUNK_PX: float = 256.0
## Las sondas (tools/tests/inventario_mundo.gd) lo apagan para ver cada pieza por separado y saber de dónde sale.
static var juntar_por_zonas: bool = true

func _merge_terrain_by_chunks() -> void:
	if _is_headless or terrain_root_3d == null or not juntar_por_zonas:
		return
	var found: Array = []
	_collect_merge_meshes(terrain_root_3d, terrain_root_3d, {}, found)
	var chunk: float = TROZO_TERRENO_M
	var max_pieza: float = chunk * TAM_MAX_JUNTAR_FACTOR
	var mats_canon: Dictionary = {}
	var groups_grandes: Dictionary = {}
	var groups_chicos: Dictionary = {}
	for mi_v in found:
		var mi := mi_v as MeshInstance3D
		if mi.has_meta(&"malla_cauce") or not _plain_static_materials(mi):
			continue
		var aabb: AABB = mi.global_transform * mi.mesh.get_aabb()
		if aabb.size.x > max_pieza or aabb.size.z > max_pieza:
			continue
		_canonizar_materiales_malla(mi, mats_canon)
		var tam_max: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
		var c3: Vector3 = aabb.get_center()
		var key := Vector2i(floori(c3.x / chunk), floori(c3.z / chunk))
		if tam_max < TAM_SOMBRA_MIN_M:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if not groups_chicos.has(key):
				groups_chicos[key] = []
			(groups_chicos[key] as Array).append(mi)
		else:
			if not groups_grandes.has(key):
				groups_grandes[key] = []
			(groups_grandes[key] as Array).append(mi)
	for key: Vector2i in groups_grandes.keys():
		var lista: Array = groups_grandes[key]
		if lista.size() < 2:
			continue
		var holder := Node3D.new()
		holder.name = "TerrenoJuntado_%d_%d" % [key.x, key.y]
		terrain_root_3d.add_child(holder)
		_merge_mesh_list(holder, lista)
	for key_c: Vector2i in groups_chicos.keys():
		var lista_c: Array = groups_chicos[key_c]
		if lista_c.size() < 2:
			continue
		var holder_c := Node3D.new()
		holder_c.name = "TerrenoChico_%d_%d" % [key_c.x, key_c.y]
		terrain_root_3d.add_child(holder_c)
		_merge_mesh_list(holder_c, lista_c)
		for ch: Node in holder_c.get_children():
			if ch is GeometryInstance3D:
				(ch as GeometryInstance3D).set_meta(&"juntado_chico", true)
	for mi_v in found:
		var mi_limpio := mi_v as MeshInstance3D
		if is_instance_valid(mi_limpio) and mi_limpio.mesh == null and mi_limpio.get_child_count() == 0 and mi_limpio.get_meta_list().is_empty():
			var p: Node = mi_limpio.get_parent()
			if p != null:
				p.remove_child(mi_limpio)
			mi_limpio.free()


## Unifica materiales StandardMaterial3D idénticos del decorado horneado para que entren en una sola superficie por trozo.
func _canonizar_materiales_malla(mi: MeshInstance3D, tabla: Dictionary) -> void:
	if mi.material_override is StandardMaterial3D:
		mi.material_override = _material_estatico_unico(mi.material_override as StandardMaterial3D, tabla)
		return
	if mi.material_override != null:
		return
	for si in range(mi.mesh.get_surface_count()):
		var ov: Material = mi.get_surface_override_material(si)
		if ov is StandardMaterial3D:
			mi.set_surface_override_material(si, _material_estatico_unico(ov as StandardMaterial3D, tabla))
		elif ov == null:
			var sm: Material = mi.mesh.surface_get_material(si)
			if sm is StandardMaterial3D:
				mi.set_surface_override_material(si, _material_estatico_unico(sm as StandardMaterial3D, tabla))


func _material_estatico_unico(m: StandardMaterial3D, tabla: Dictionary) -> StandardMaterial3D:
	var tex_id: int = m.albedo_texture.get_instance_id() if m.albedo_texture != null else 0
	var nrm_id: int = m.normal_texture.get_instance_id() if (m.normal_enabled and m.normal_texture != null) else 0
	var firma: String = "%d|%s|%.3f|%.3f|%d|%d|%d|%d|%s|%d|%d" % [
		tex_id, m.albedo_color.to_html(), m.roughness, m.metallic, int(m.cull_mode),
		int(m.transparency), nrm_id, int(m.uv1_triplanar), str(m.uv1_scale),
		int(m.shading_mode), int(m.vertex_color_use_as_albedo)
	]
	if tabla.has(firma):
		return tabla[firma] as StandardMaterial3D
	tabla[firma] = m
	return m

func _plain_static_materials(mi: MeshInstance3D) -> bool:
	for si in range(mi.mesh.get_surface_count()):
		var mat: Material = mi.material_override
		if mat == null:
			mat = mi.get_surface_override_material(si)
		if mat == null:
			mat = mi.mesh.surface_get_material(si)
		if mat == null:
			continue
		if not (mat is BaseMaterial3D):
			return false
		if (mat as BaseMaterial3D).billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
			return false
	return true

# ==============================================================================
# 1. TERRENO, CAMINOS, PLAZA, POZOS, PARQUE, LAGO, CIÉNAGA Y CEMENTERIO 3D
# ==============================================================================
## Lo que el terreno dibuja por código: suelo, caminos, plaza empedrada y agua (lago, ciénaga y río). Son mallas
## hechas aquí (se juntan por zonas). Todo lo demás —puentes, bancos, vallas, campos, cementerio, adornos— es una pieza
## de «Decorado» en mapa/Mundo3D.tscn y se coloca desde el editor (2026-11-12).
func _build_static_terrain_3d() -> void:
	_clear_children(terrain_root_3d)
	estirar_terreno = true # mapa ×E: las listas del código están en el mapa original (ver WorldStageBase3D)
	_build_ground_3d()
	var m_road := _mat("road_dirt", Color(0.56, 0.46, 0.34), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.55)
	var m_plaza := _mat("plaza_stone", Color(0.66, 0.62, 0.56), 0.85, 0.05, Color.BLACK, 0.0, "town_textures/rf_cobblestone.png", "", 0.65)
	var m_marsh := _mat("water_marsh", Color(0.20, 0.42, 0.30, 0.92), 0.28, 0.10)

	# Caminos principales y calles con relieve 3D (divididos en el cruce del Puente Viejo en x = 92..144)
	var road_rects: Array = CALLES_PRINCIPALES
	# Editor del mapa 3D (2026-11-10): si mapa/Mundo3D.tscn tiene «Caminos», esos tramos sustituyen a las calles rectas
	var tramos_ed: Array = load("res://mapa/camino.gd").tramos()
	if not tramos_ed.is_empty():
		road_rects = []
		estirar_terreno = false # los tramos del editor ya están en el mundo actual
		for t in tramos_ed:
			_add_tramo_3d(terrain_root_3d, t["a"], t["b"], float(t["ancho"]), 0.25, m_road)
		estirar_terreno = true
	for rr in road_rects:
		_add_road_strip_3d(terrain_root_3d, rr, 0.25, m_road)
	for lr in (VillageLots.ROADS if tramos_ed.is_empty() else []):
		if lr is Rect2:
			_add_road_strip_3d(terrain_root_3d, lr as Rect2, 0.25, m_road)

	# Plaza Central Empedrada en plataforma ligeramente elevada (+2.4 px en terreno); sus bordillos son piezas de «Decorado»
	_add_road_strip_3d(terrain_root_3d, PLAZA_RECT, 0.35, m_plaza)
	if terrain_root_3d != null and terrain_root_3d.get_child_count() > 0:
		var mi_plaza := terrain_root_3d.get_child(terrain_root_3d.get_child_count() - 1) as MeshInstance3D
		if mi_plaza != null and mi_plaza.mesh != null:
			terrain_root_3d.set_meta("caja_plaza_3d", mi_plaza.mesh.get_aabb())

	# Lago del Oeste y Ciénaga de las Ranas del Suroeste (lámina de agua a -1.4 px; sus orillas son piezas de «Decorado»)
	_build_lake_3d()
	_add_flat_poly_2d(terrain_root_3d, MARSH_WATER_PTS, -1.4, m_marsh, true)

	# Río de norte a sur, Puente Viejo en el centro del pueblo, arroyo del bosque norte, Claro (barro pardo) y Molino Viejo (barro rojo / arcilla)
	_build_river_and_arroyo_3d()
	estirar_terreno = false

const ZONA_PLAZA_ID := "plaza"            ## pieza de «Zonas» que lleva la plaza
const MATAS_MARGEN_PLAZA_PX: float = 65.0  ## 13 px del mapa original ×5: las matas no asoman en el empedrado
const MATAS_MARGEN_EDIFICIO_PX: float = 12.0 ## pasillo sin hierba alrededor de cada casa

## Plaza Central (mapa original) y lámina de agua de la ciénaga: mallas de suelo que aún dibuja el código.
const PLAZA_RECT: Rect2 = Rect2(Vector2(388, 12), Vector2(154, 72))
const MARSH_WATER_PTS: PackedVector2Array = [
	Vector2(-1860, 210), Vector2(-1620, 165), Vector2(-1340, 180), Vector2(-1200, 250),
	Vector2(-1220, 390), Vector2(-1360, 470), Vector2(-1650, 485), Vector2(-1850, 420),
	Vector2(-1910, 310),
]

## Río de norte a sur y arroyo del bosque: lámina de agua, cauce hondo y orillas de tierra y barro repartidos en tramos
## indexados (los kilómetros fuera de cámara no se dibujan y los vértices compartidos se calculan una sola vez).
func _build_river_and_arroyo_3d() -> void:
	var m_riv_water: Material = _mat_agua("river_water_3d", Color(0.18, 0.48, 0.76, 0.92))
	var m_riv_deep: Material = _mat_agua("river_deep_3d", Color(0.09, 0.28, 0.52, 0.96))
	var m_bank_earth: Material = _mat("river_bank_earth", Color(0.40, 0.31, 0.20), 0.94, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.65)
	var m_wet_mud: Material = _mat("river_wet_mud", Color(0.25, 0.18, 0.12), 0.44, 0.08, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.72)
	var m_brown_mud: Material = _mat("arroyo_brown_mud", Color(0.36, 0.24, 0.14), 0.62, 0.06, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.72)
	var m_red_clay: Material = _mat("mill_red_clay_mud", Color(0.84, 0.16, 0.08), 0.56, 0.04, Color(0.26, 0.04, 0.02), 1.0, "town_textures/floor_ground_dirt.png", "town_textures/wall_stone_n.png", 0.78)
	var y_barro_rojo: float = Sitio.mundo("barro_rojo_molino").y
	var y_claro: float = Sitio.mundo("claro_caso1").y
	var cruces_rio: Array[Dictionary] = RioLagoScript.river_crossings()
	var y_ini_rio: float = RioLagoScript.river_y_start()
	var y_end_riv: float = RioLagoScript.river_y_end()

	var pts_rio_3d := PackedVector3Array()
	var seg_y0: float = y_ini_rio
	var idx_seg: int = 0
	while seg_y0 < y_end_riv - 0.01:
		var seg_y1: float = minf(y_end_riv, seg_y0 + TRAMO_RIO_CORTE_UNIDADES)
		_construir_tramo_rio_3d(
			terrain_root_3d, idx_seg, seg_y0, seg_y1, y_barro_rojo, y_claro, cruces_rio,
			m_riv_water, m_riv_deep, m_bank_earth, m_wet_mud, m_brown_mud, m_red_clay, pts_rio_3d
		)
		seg_y0 = seg_y1
		idx_seg += 1
	if terrain_root_3d != null and not pts_rio_3d.is_empty():
		terrain_root_3d.set_meta("puntos_rio_3d", pts_rio_3d)


func _paso_rio_en(y_val: float, y_barro_rojo: float, y_claro: float, cruces_rio: Array[Dictionary]) -> float:
	if absf(y_val - y_barro_rojo) <= BARRO_ROJO_MEDIO_LARGO_PX + MARGEN_CRUCE_FINO:
		return PASO_RIO_FINO
	if absf(y_val - y_claro) <= CLARO_MEDIO_LARGO_PX + MARGEN_CRUCE_FINO:
		return PASO_RIO_FINO
	for cr: Dictionary in cruces_rio:
		var cpos: Vector2 = cr["pos"]
		if absf(y_val - cpos.y) <= float(cr["half_h"]) + MARGEN_CRUCE_FINO:
			return PASO_RIO_FINO
	return PASO_RIO_RECTO


func _construir_tramo_rio_3d(
	parent: Node3D, idx_seg: int, seg_y0: float, seg_y1: float,
	y_barro_rojo: float, y_claro: float, cruces_rio: Array[Dictionary],
	m_riv_water: Material, m_riv_deep: Material, m_bank_earth: Material,
	m_wet_mud: Material, m_brown_mud: Material, m_red_clay: Material,
	pts_rio_3d: PackedVector3Array
) -> void:
	var st_water := SurfaceTool.new(); st_water.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_deep := SurfaceTool.new(); st_deep.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_banks := SurfaceTool.new(); st_banks.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_wet_mud := SurfaceTool.new(); st_wet_mud.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_brown_mud := SurfaceTool.new(); st_brown_mud.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_red_clay := SurfaceTool.new(); st_red_clay.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_banks: int = 0
	var n_wet: int = 0
	var n_brown: int = 0
	var n_red: int = 0
	var n_water: int = 0

	var y_cur: float = seg_y0
	while y_cur < seg_y1 - 0.01:
		var step_y: float = _paso_rio_en(y_cur, y_barro_rojo, y_claro, cruces_rio)
		var y_nxt: float = minf(seg_y1, y_cur + step_y)
		var b0: Vector2 = RioLagoScript.river_banks_at(y_cur)
		var b1: Vector2 = RioLagoScript.river_banks_at(y_nxt)
		var h0: float = superficie_rio_px(y_cur)
		var h1: float = superficie_rio_px(y_nxt)
		var wl0: Vector3 = to_3d_flat(Vector2(b0.x - 1.5, y_cur), h0)
		var wr0: Vector3 = to_3d_flat(Vector2(b0.y + 1.5, y_cur), h0)
		var wl1: Vector3 = to_3d_flat(Vector2(b1.x - 1.5, y_nxt), h1)
		var wr1: Vector3 = to_3d_flat(Vector2(b1.y + 1.5, y_nxt), h1)
		st_water.set_normal(Vector3.UP)
		st_water.add_vertex(wl0); st_water.add_vertex(wr0); st_water.add_vertex(wr1)
		st_water.add_vertex(wl0); st_water.add_vertex(wr1); st_water.add_vertex(wl1)
		if (n_water % 18) == 0:
			pts_rio_3d.append((wl0 + wr0) * 0.5)
		n_water += 1

		var cx0: float = (b0.x + b0.y) * 0.5
		var hw0: float = (b0.y - b0.x) * 0.33
		var cx1: float = (b1.x + b1.y) * 0.5
		var hw1: float = (b1.y - b1.x) * 0.33
		var dl0: Vector3 = to_3d_flat(Vector2(cx0 - hw0, y_cur), h0 + 0.04)
		var dr0: Vector3 = to_3d_flat(Vector2(cx0 + hw0, y_cur), h0 + 0.04)
		var dl1: Vector3 = to_3d_flat(Vector2(cx1 - hw1, y_nxt), h1 + 0.04)
		var dr1: Vector3 = to_3d_flat(Vector2(cx1 + hw1, y_nxt), h1 + 0.04)
		st_deep.set_normal(Vector3.UP)
		st_deep.add_vertex(dl0); st_deep.add_vertex(dr0); st_deep.add_vertex(dr1)
		st_deep.add_vertex(dl0); st_deep.add_vertex(dr1); st_deep.add_vertex(dl1)

		var town_mud_boost0: float = lerpf(1.0, 1.95, smoothstep(-520.0, -180.0, y_cur) * (1.0 - smoothstep(260.0, 390.0, y_cur)))
		var town_mud_boost1: float = lerpf(1.0, 1.95, smoothstep(-520.0, -180.0, y_nxt) * (1.0 - smoothstep(260.0, 390.0, y_nxt)))
		var w_pad_l0: float = (7.2 + sin(y_cur * 0.057 + 0.3) * 3.4 + cos(y_cur * 0.119 - 0.8) * 2.1) * town_mud_boost0
		var w_pad_l1: float = (7.2 + sin(y_nxt * 0.057 + 0.3) * 3.4 + cos(y_nxt * 0.119 - 0.8) * 2.1) * town_mud_boost1
		var w_pad_r0: float = (7.2 + cos(y_cur * 0.051 - 0.5) * 3.4 + sin(y_cur * 0.113 + 1.1) * 2.1) * town_mud_boost0
		var w_pad_r1: float = (7.2 + cos(y_nxt * 0.051 - 0.5) * 3.4 + sin(y_nxt * 0.113 + 1.1) * 2.1) * town_mud_boost1
		var in_mill_zone: bool = absf(y_cur - y_barro_rojo) <= BARRO_ROJO_MEDIO_LARGO_PX
		var in_clearing_zone: bool = absf(y_cur - y_claro) <= CLARO_MEDIO_LARGO_PX
		if in_mill_zone:
			w_pad_l0 = 13.0 + sin(y_cur * 0.08) * 3.5
			w_pad_l1 = 13.0 + sin(y_nxt * 0.08) * 3.5
			var mill_r_reach0: float = BARRO_ROJO_ANCHO_PX if absf(y_cur - y_barro_rojo) <= BARRO_ROJO_MEDIO_LARGO_PX * 0.5 else 12.0
			var mill_r_reach1: float = BARRO_ROJO_ANCHO_PX if absf(y_nxt - y_barro_rojo) <= BARRO_ROJO_MEDIO_LARGO_PX * 0.5 else 12.0
			w_pad_r0 = mill_r_reach0 + cos(y_cur * 0.07) * 3.8
			w_pad_r1 = mill_r_reach1 + cos(y_nxt * 0.07) * 3.8
		elif in_clearing_zone:
			w_pad_r0 = 30.0 + sin((y_cur + 860.0) * 0.06) * 5.0
			w_pad_r1 = 30.0 + sin((y_nxt + 860.0) * 0.06) * 5.0

		var st_left_target: SurfaceTool = st_red_clay if in_mill_zone else st_banks
		var st_right_target: SurfaceTool = st_red_clay if in_mill_zone else (st_brown_mud if in_clearing_zone else st_banks)
		if in_mill_zone:
			n_red += 1
		elif in_clearing_zone:
			n_banks += 1
			n_brown += 1
		else:
			n_banks += 1

		var bl_in0: Vector3 = to_3d_flat(Vector2(b0.x + 1.0, y_cur), h0 - 0.06)
		var bl_lip0: Vector3 = to_3d_flat(Vector2(b0.x - 1.8, y_cur), h0 + 0.24)
		var bl_out0: Vector3 = to_3d(Vector2(b0.x - w_pad_l0, y_cur), 0.16)
		var bl_in1: Vector3 = to_3d_flat(Vector2(b1.x + 1.0, y_nxt), h1 - 0.06)
		var bl_lip1: Vector3 = to_3d_flat(Vector2(b1.x - 1.8, y_nxt), h1 + 0.24)
		var bl_out1: Vector3 = to_3d(Vector2(b1.x - w_pad_l1, y_nxt), 0.16)
		st_left_target.set_normal(Vector3.UP)
		st_left_target.add_vertex(bl_out0); st_left_target.add_vertex(bl_lip0); st_left_target.add_vertex(bl_lip1)
		st_left_target.add_vertex(bl_out0); st_left_target.add_vertex(bl_lip1); st_left_target.add_vertex(bl_out1)
		st_left_target.add_vertex(bl_lip0); st_left_target.add_vertex(bl_in0); st_left_target.add_vertex(bl_in1)
		st_left_target.add_vertex(bl_lip0); st_left_target.add_vertex(bl_in1); st_left_target.add_vertex(bl_lip1)

		var br_in0: Vector3 = to_3d_flat(Vector2(b0.y - 1.0, y_cur), h0 - 0.06)
		var br_lip0: Vector3 = to_3d_flat(Vector2(b0.y + 1.8, y_cur), h0 + 0.24)
		var br_out0: Vector3 = to_3d(Vector2(b0.y + w_pad_r0, y_cur), 0.18)
		var br_in1: Vector3 = to_3d_flat(Vector2(b1.y - 1.0, y_nxt), h1 - 0.06)
		var br_lip1: Vector3 = to_3d_flat(Vector2(b1.y + 1.8, y_nxt), h1 + 0.24)
		var br_out1: Vector3 = to_3d(Vector2(b1.y + w_pad_r1, y_nxt), 0.18)
		st_right_target.set_normal(Vector3.UP)
		st_right_target.add_vertex(br_in0); st_right_target.add_vertex(br_lip0); st_right_target.add_vertex(br_lip1)
		st_right_target.add_vertex(br_in0); st_right_target.add_vertex(br_lip1); st_right_target.add_vertex(br_in1)
		st_right_target.add_vertex(br_lip0); st_right_target.add_vertex(br_out0); st_right_target.add_vertex(br_out1)
		st_right_target.add_vertex(br_lip0); st_right_target.add_vertex(br_out1); st_right_target.add_vertex(br_lip1)

		if not in_mill_zone and not in_clearing_zone:
			var wm_l_in0: float = 1.6 + maxf(0.0, sin(y_cur * 0.071 + 0.9)) * 3.8 * (town_mud_boost0 * 0.55)
			var wm_l_in1: float = 1.6 + maxf(0.0, sin(y_nxt * 0.071 + 0.9)) * 3.8 * (town_mud_boost1 * 0.55)
			var wm_l_out0: float = 3.2 + (sin(y_cur * 0.083) * 1.6 + 1.8) * town_mud_boost0
			var wm_l_out1: float = 3.2 + (sin(y_nxt * 0.083) * 1.6 + 1.8) * town_mud_boost1
			var wml_a0: Vector3 = to_3d_flat(Vector2(b0.x - wm_l_out0, y_cur), h0 + 0.27)
			var wml_b0: Vector3 = to_3d_flat(Vector2(b0.x + wm_l_in0, y_cur), h0 + 0.05)
			var wml_a1: Vector3 = to_3d_flat(Vector2(b1.x - wm_l_out1, y_nxt), h1 + 0.27)
			var wml_b1: Vector3 = to_3d_flat(Vector2(b1.x + wm_l_in1, y_nxt), h1 + 0.05)
			st_wet_mud.set_normal(Vector3.UP)
			st_wet_mud.add_vertex(wml_a0); st_wet_mud.add_vertex(wml_b0); st_wet_mud.add_vertex(wml_b1)
			st_wet_mud.add_vertex(wml_a0); st_wet_mud.add_vertex(wml_b1); st_wet_mud.add_vertex(wml_a1)

			var wm_r_in0: float = 1.6 + maxf(0.0, cos(y_cur * 0.067 - 0.6)) * 3.8 * (town_mud_boost0 * 0.55)
			var wm_r_in1: float = 1.6 + maxf(0.0, cos(y_nxt * 0.067 - 0.6)) * 3.8 * (town_mud_boost1 * 0.55)
			var wm_r_out0: float = 3.2 + (cos(y_cur * 0.079) * 1.6 + 1.8) * town_mud_boost0
			var wm_r_out1: float = 3.2 + (cos(y_nxt * 0.079) * 1.6 + 1.8) * town_mud_boost1
			var wmr_a0: Vector3 = to_3d_flat(Vector2(b0.y - wm_r_in0, y_cur), h0 + 0.05)
			var wmr_b0: Vector3 = to_3d_flat(Vector2(b0.y + wm_r_out0, y_cur), h0 + 0.27)
			var wmr_a1: Vector3 = to_3d_flat(Vector2(b1.y - wm_r_in1, y_nxt), h1 + 0.05)
			var wmr_b1: Vector3 = to_3d_flat(Vector2(b1.y + wm_r_out1, y_nxt), h1 + 0.27)
			st_wet_mud.set_normal(Vector3.UP)
			st_wet_mud.add_vertex(wmr_a0); st_wet_mud.add_vertex(wmr_b0); st_wet_mud.add_vertex(wmr_b1)
			st_wet_mud.add_vertex(wmr_a0); st_wet_mud.add_vertex(wmr_b1); st_wet_mud.add_vertex(wmr_a1)
			n_wet += 1

		y_cur = y_nxt

	if n_water == 0:
		return
	var sufijo: int = 0
	for pair_m: Array in [
		[st_banks, m_bank_earth, n_banks],
		[st_wet_mud, m_wet_mud, n_wet],
		[st_brown_mud, m_brown_mud, n_brown],
		[st_red_clay, m_red_clay, n_red],
		[st_water, m_riv_water, n_water],
		[st_deep, m_riv_deep, n_water],
	]:
		sufijo += 1
		if int(pair_m[2]) <= 0:
			continue
		var st_i := pair_m[0] as SurfaceTool
		st_i.index()
		var mi_s := MeshInstance3D.new()
		mi_s.name = "RioTramo_%d_%d" % [idx_seg, sufijo]
		mi_s.mesh = st_i.commit()
		mi_s.material_override = pair_m[1] as Material
		mi_s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi_s.set_meta(&"malla_cauce", true)
		parent.add_child(mi_s)


## Editor del mapa 3D (2026-11-10): mapa/Mundo3D.tscn. «Vegetacion» (árboles, rocas, plantas y troncos horneados del
## código, editables a mano) y «Decoracion» (lo que coloque el usuario) se meten en el terreno antes de juntarlo por zonas
## (rendimiento) y se hacen sólidos en el mapa 2D según su tipo de choque.
const ESCENA_MUNDO_3D := "res://mapa/Mundo3D.tscn"
const META_CHOQUE := "choque"
const META_CHOQUE_GIRO := "choque_giro"
const META_CHOQUE_DESPLAZ := "choque_desplaz"
var _mundo_editor: Node = null

func _preparar_escena_editor() -> void:
	vegetacion_en_escena = false
	decorado_en_escena = false
	if grabar_vegetacion or not ResourceLoader.exists(ESCENA_MUNDO_3D):
		return
	var ps = load(ESCENA_MUNDO_3D)
	if not (ps is PackedScene):
		return
	_mundo_editor = (ps as PackedScene).instantiate()
	var veg: Node = _mundo_editor.get_node_or_null("Vegetacion")
	vegetacion_en_escena = veg != null and veg.get_child_count() > 0
	var dec: Node = _mundo_editor.get_node_or_null("Decorado")
	decorado_en_escena = dec != null and dec.get_child_count() > 0


## Separa el decorado del terreno: suelo, agua y orillas (mallas hechas por código) se quedan; lo demás que aún dibuja
## el código (adornos del río) se quita porque ya viene de la escena, como pieza de «Decorado».
func _separar_decorado() -> void:
	if terrain_root_3d == null or not decorado_en_escena:
		return
	var cand: Array = []
	for c in terrain_root_3d.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is ArrayMesh:
			continue
		cand.append(c)
	for c in cand:
		terrain_root_3d.remove_child(c)
		c.free()


func _cargar_decoracion_editor() -> void:
	if _mundo_editor == null or terrain_root_3d == null:
		return
	var dec: Node = _mundo_editor.get_node_or_null("Decorado")
	if dec != null and decorado_en_escena:
		_choques_del_decorado(dec)
		_mundo_editor.remove_child(dec)
		dec.owner = null # sin el aviso «owner inconsistent» al arrancar
		terrain_root_3d.add_child(dec)
	var piezas: Array = []
	for grupo in ["Vegetacion", "Decoracion"]:
		var g: Node = _mundo_editor.get_node_or_null(grupo)
		if g == null:
			continue
		_mundo_editor.remove_child(g)
		g.owner = null
		terrain_root_3d.add_child(g)
		_juntar_piezas(g, piezas)
	for c in piezas:
		var es_mata: bool = c.has_method("tipo_choque") and "Bush" in String(c.get("modelo")).get_file()
		var es_veta: bool = c.get_parent() != null and String(c.get_parent().name) == "Vetas"
		if c.has_method("tipo_choque") and (String(c.call("tipo_choque")) == "tronco" or es_mata or es_veta) and nature_root_3d != null:
			if es_veta:
				c.set_meta("es_veta", true)
			# Árbol: sale del terreno antes de juntarlo por zonas (tiene que poder ocultarse al talarlo)
			var xf := (c as Node3D).global_transform
			c.get_parent().remove_child(c)
			nature_root_3d.add_child(c)
			(c as Node3D).global_transform = xf
			_talables_pendientes.append(c)
		else:
			_choque_de_pieza(c as Node3D)
	_mundo_editor.free()
	# El bosque (EcosystemManager) se crea después que el escenario 3D: los talables se crean cuando ya existe
	if not _talables_pendientes.is_empty():
		call_deferred("_crear_talables_pendientes")


var _talables_pendientes: Array = []

func _crear_talables_pendientes() -> void:
	var eco: Node = get_tree().get_first_node_in_group("ecosystem_manager")
	if eco == null or not eco.has_method("crear_arbol_talable") or eco.get("entities_root") == null:
		for _i in range(300):
			await get_tree().process_frame
			eco = get_tree().get_first_node_in_group("ecosystem_manager")
			if eco != null and eco.get("entities_root") != null:
				break
	var n := 0
	for c in _talables_pendientes:
		if not is_instance_valid(c):
			continue
		n += 1
		if eco != null and eco.has_method("crear_arbol_talable"):
			if bool(c.get_meta("es_veta", false)):
				_hacer_veta(c as Node3D, eco, "VetaEscena_%d" % n)
			elif "Bush" in String(c.get("modelo")).get_file():
				_hacer_talable(c as Node3D, eco, "MatorralEscena_%d" % n, true)
			else:
				_hacer_talable(c as Node3D, eco, "ArbolEscena_%d" % n)
		else:
			_choque_de_pieza(c as Node3D)
	_talables_pendientes.clear()
	_mundo_editor = null
	_flush_batches()


## Árbol de la escena → árbol talable del juego (choque, madera, tocón al talarlo y vuelve a crecer). El modelo de la pieza
## pasa a la naturaleza 3D y se registra como su dibujo, para que se oculte al talarlo.
func _hacer_talable(pieza: Node3D, eco: Node, nombre: String, matorral: bool = false) -> void:
	var p2 := _a_mapa_2d(pieza.global_position)
	var h = eco.call("crear_matorral" if matorral else "crear_arbol_talable", p2, nombre)
	if not (h is Node2D) or nature_root_3d == null:
		_choque_de_pieza(pieza)
		return
	if matorral:
		var rec_m := {"tree": pieza, "stump": null}
		_absorb_into_batches(pieza, p2)
		_nature_nodes[(h as Node2D).get_instance_id()] = rec_m
		return
	var stump := _add_cyl_2d(nature_root_3d, p2, 5.0, -1.2, 6.2, _mat("tree_stump", Color(0.45, 0.32, 0.20), 0.9, 0.0, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78), 4.5, 8)
	stump.visible = false
	var rec := {"tree": pieza, "stump": stump}
	for k in ["tree", "stump"]:
		_absorb_into_batches(rec[k], p2)
	_nature_nodes[(h as Node2D).get_instance_id()] = rec


## Roca de la carpeta «Vetas» → veta que se pica (piedra y mineral de hierro). Al agotarse queda una roca pequeña.
func _hacer_veta(pieza: Node3D, eco: Node, nombre: String) -> void:
	var p2 := _a_mapa_2d(pieza.global_position)
	var h = eco.call("crear_veta", p2, nombre)
	if not (h is Node2D):
		_choque_de_pieza(pieza)
		return
	var hv: int = absi(int(p2.x * 13.0 + p2.y * 7.0))
	var rfiles := ["nature/Rock_1.obj", "nature/Rock_2.obj", "nature/Rock_3.obj", "nature/Rock_4.obj", "nature/Rock_5.obj"]
	var low := _add_model_2d(nature_root_3d, rfiles[(hv + 2) % rfiles.size()], p2, -1.2, Vector2.ZERO, 6.0, float(hv % 360) + 40.0)
	if low != null:
		low.visible = false
	var rec := {"tree": pieza, "stump": low}
	for k in ["tree", "stump"]:
		if rec[k] != null:
			_absorb_into_batches(rec[k], p2)
	_nature_nodes[(h as Node2D).get_instance_id()] = rec


## Piezas de «Decorado» que chocan (bancos, verjas, tumbas, troncos…): llevan en sus metadatos «choque» (tamaño visto
## desde arriba) y, si hace falta, «choque_giro» (grados) y «choque_desplaz» (desde su centro). Van con la pieza.
func _choques_del_decorado(dec: Node) -> void:
	if vm == null or not vm.has_method("add_choque_mundo"):
		return
	_choques_recursivo(dec, Transform3D.IDENTITY)


func _choques_recursivo(nodo: Node, xf_padre: Transform3D) -> void:
	for hijo: Node in nodo.get_children():
		if not (hijo is Node3D):
			continue
		var n3: Node3D = hijo as Node3D
		var xf: Transform3D = xf_padre * n3.transform
		if n3.has_meta(META_CHOQUE):
			_choque_de_decorado(n3, xf)
		if n3.get_child_count() > 0:
			_choques_recursivo(n3, xf)


func _choque_de_decorado(pieza: Node3D, xf: Transform3D) -> void:
	var giro: float = -xf.basis.orthonormalized().get_euler().y # en el plano el giro va al revés que en 3D
	var desplaz: Vector2 = pieza.get_meta(META_CHOQUE_DESPLAZ, Vector2.ZERO)
	var centro: Vector2 = _a_mapa_2d(xf.origin) + desplaz.rotated(giro)
	giro += deg_to_rad(float(pieza.get_meta(META_CHOQUE_GIRO, 0.0)))
	vm.call("add_choque_mundo", centro, pieza.get_meta(META_CHOQUE) as Vector2, giro)


## Piezas = nodos 3D colocados (las carpetas de agrupar sin modelo propio se recorren por dentro).
func _juntar_piezas(n: Node, out: Array) -> void:
	for c in n.get_children():
		if not (c is Node3D):
			continue
		if c.has_method("tipo_choque") or c is VisualInstance3D or c.scene_file_path != "":
			out.append(c)
		else:
			_juntar_piezas(c, out)


const TRONCO_CHOQUE_TAM := Vector2(7.0, 7.0) ## solo el tronco choca: se pasa por debajo de la copa

func _choque_de_pieza(c: Node3D) -> void:
	if vm == null or not ("entities_root" in vm) or not is_instance_valid(vm.entities_root):
		return
	var tipo: String = String(c.call("tipo_choque")) if c.has_method("tipo_choque") else ("ninguno" if bool(c.get_meta("atravesable", false)) else "forma")
	if tipo == "ninguno":
		return
	var p2 := _a_mapa_2d(c.global_position)
	if tipo == "tronco":
		vm.call("add_choque_mundo", p2, TRONCO_CHOQUE_TAM, 0.0) # la pieza ya está en el mundo: sin traducir
		return
	# «forma»: lo que ocupa visto desde arriba (esquinas de sus mallas, ya giradas)
	var pts := PackedVector2Array()
	var mallas: Array = c.find_children("*", "VisualInstance3D", true, false)
	if c is VisualInstance3D:
		mallas.append(c)
	for mi in mallas:
		var bb: AABB = (mi as VisualInstance3D).get_aabb()
		var xf: Transform3D = (mi as VisualInstance3D).global_transform
		for k in range(8):
			pts.append(_a_mapa_2d(xf * bb.get_endpoint(k)))
	if pts.size() < 3:
		return
	var casco := Geometry2D.convex_hull(pts)
	if casco.size() < 4:
		return
	var sb := StaticBody2D.new()
	sb.name = "PiezaEditorCollider"
	sb.collision_layer = 1
	sb.collision_mask = 0
	sb.add_to_group("prop_collider")
	var cp := CollisionPolygon2D.new()
	cp.polygon = casco
	sb.add_child(cp)
	vm.entities_root.add_child(sb)


func _a_mapa_2d(v: Vector3) -> Vector2:
	return Mapa3D.a_mapa(v)


## Calles rectas de siempre (las usa tools/hornear_caminos.gd para crear los tramos del editor).
const CALLES_PRINCIPALES: Array = [
		Rect2(Vector2(-1950, 36), Vector2(2042, 28)),
		Rect2(Vector2(144, 36), Vector2(1194, 28)),
		Rect2(Vector2(-688, 64), Vector2(18, 36)),
		Rect2(Vector2(-1520, -140), Vector2(22, 176)),
		Rect2(Vector2(-1520, 64), Vector2(22, 120)),
		Rect2(Vector2(452, -132), Vector2(26, 172)),
		Rect2(Vector2(452, 62), Vector2(26, 700)),
		Rect2(Vector2(-380, 760), Vector2(1040, 24)),
		Rect2(Vector2(130, 780), Vector2(26, 260)),
		Rect2(Vector2(140, 130), Vector2(24, 248)),
		Rect2(Vector2(140, 356), Vector2(312, 22)),
		Rect2(Vector2(822, -230), Vector2(24, 466)),
		Rect2(Vector2(215, -310), Vector2(20, 515)),
		Rect2(Vector2(1078, -230), Vector2(20, 480)),
		Rect2(Vector2(1318, -230), Vector2(20, 480)),
		Rect2(Vector2(452, 232), Vector2(885, 20)),
]


## Tramo de camino de a a b (cualquier dirección), pegado al terreno como _add_road_strip_3d.
func _add_tramo_3d(parent: Node3D, a: Vector2, b: Vector2, ancho: float, height_px: float, mat: Material) -> MeshInstance3D:
	var largo: float = a.distance_to(b)
	if largo < 1.0:
		return null
	var dir: Vector2 = (b - a) / largo
	var nrm: Vector2 = -dir.orthogonal() * (ancho * 0.5) # como en _add_road_strip_3d: caras hacia arriba
	var n_l: int = maxi(1, int(ceil(largo / 20.0)))
	var n_w: int = maxi(1, int(ceil(ancho / 20.0)))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for il in range(n_l):
		for iw in range(n_w):
			var l0: Vector2 = a + dir * (largo * float(il) / float(n_l))
			var l1: Vector2 = a + dir * (largo * float(il + 1) / float(n_l))
			var w0: Vector2 = nrm * (2.0 * float(iw) / float(n_w) - 1.0)
			var w1: Vector2 = nrm * (2.0 * float(iw + 1) / float(n_w) - 1.0)
			var p00: Vector2 = l0 + w0
			var p10: Vector2 = l1 + w0
			var p01: Vector2 = l0 + w1
			var p11: Vector2 = l1 + w1
			var mid_p: Vector2 = (p00 + p11) * 0.5
			if mid_p.y >= RioLagoScript.river_y_start() and mid_p.y <= RioLagoScript.river_y_end() and absf(mid_p.x - RioLagoScript.river_center_x(mid_p.y)) <= RioLagoScript.river_half_width(mid_p.y) + 6.0:
				continue
			for p in [p00, p10, p11, p00, p11, p01]:
				st.set_normal(terrain_normal_3d(p, 12.0))
				st.add_vertex(to_3d(p, height_px))
	st.index()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi
