@tool
extends "res://scripts/visuals/WorldStageBuildings3D.gd"

## Terreno 3D, relieve suave (Fases A y B), caminos, plaza, lago, ciénaga, barrios y vegetación.

# ==============================================================================
# SUELO 3D Y NATURALEZA (2026-11-05): sustituyen a la hierba y a los pinos dibujados en 2D
# ==============================================================================
func _make_ground_shader_mat(key: String, c_prim: Color, c_sec: Color, c_earth: Color, dirt_b: float) -> Material:
	if _mat_cache.has(key):
		return _mat_cache[key]
	if _is_headless:
		return _mat(key + "_hl", c_prim, 0.95, 0.0)
	var sh := Shader.new()
	sh.code = GROUND_TERRAIN_SHADER_CODE
	var sm := ShaderMaterial.new()
	sm.shader = sh
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

## Suelo opaco 3D con malla de relieve continuo (Fase A: lomas en la llanura, desniveles en el bosque y cuencas hundidas
## en el lago y la ciénaga; plano dentro del pueblo), normales suaves para el sombreado solar y mezcla de biomas por vértice.
func _build_ground_3d() -> void:
	var m_terrain := _make_ground_shader_mat("ground_terrain_heightfield_sh", Color(0.28, 0.40, 0.21), Color(0.20, 0.30, 0.15), Color(0.37, 0.29, 0.19), 0.26)
	if m_terrain is ShaderMaterial:
		(m_terrain as ShaderMaterial).set_shader_parameter("use_vertex_biomes", 1.0)
	var min_x: float = -3450.0
	var max_x: float = 3050.0
	var min_y: float = -1850.0
	var max_y: float = 3250.0
	var step: float = 34.0
	var nx: int = int(ceil((max_x - min_x) / step))
	var ny: int = int(ceil((max_y - min_y) / step))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iy in range(ny):
		var y0: float = min_y + float(iy) * step
		var y1: float = minf(max_y, y0 + step)
		for ix in range(nx):
			var x0: float = min_x + float(ix) * step
			var x1: float = minf(max_x, x0 + step)
			var p00 := Vector2(x0, y0)
			var p10 := Vector2(x1, y0)
			var p01 := Vector2(x0, y1)
			var p11 := Vector2(x1, y1)
			var v00: Vector3 = to_3d(p00, 0.0)
			var v10: Vector3 = to_3d(p10, 0.0)
			var v01: Vector3 = to_3d(p01, 0.0)
			var v11: Vector3 = to_3d(p11, 0.0)
			var n00: Vector3 = terrain_normal_3d(p00, step * 0.5)
			var n10: Vector3 = terrain_normal_3d(p10, step * 0.5)
			var n01: Vector3 = terrain_normal_3d(p01, step * 0.5)
			var n11: Vector3 = terrain_normal_3d(p11, step * 0.5)
			var c00: Color = _terrain_biome_color(p00, n00)
			var c10: Color = _terrain_biome_color(p10, n10)
			var c01: Color = _terrain_biome_color(p01, n01)
			var c11: Color = _terrain_biome_color(p11, n11)
			# Triángulo 1 (p00, p10, p11)
			st.set_color(c00); st.set_normal(n00); st.add_vertex(v00)
			st.set_color(c10); st.set_normal(n10); st.add_vertex(v10)
			st.set_color(c11); st.set_normal(n11); st.add_vertex(v11)
			# Triángulo 2 (p00, p11, p01)
			st.set_color(c00); st.set_normal(n00); st.add_vertex(v00)
			st.set_color(c11); st.set_normal(n11); st.add_vertex(v11)
			st.set_color(c01); st.set_normal(n01); st.add_vertex(v01)
	var ground_mi := MeshInstance3D.new()
	ground_mi.name = "TerrainHeightfield3D"
	ground_mi.mesh = st.commit()
	ground_mi.material_override = m_terrain
	ground_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	terrain_root_3d.add_child(ground_mi)
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

func _add_road_strip_3d(parent: Node3D, rect: Rect2, height_px: float, mat: Material) -> MeshInstance3D:
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
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _build_ground_foliage_3d() -> void:
	if _is_headless or not AssetLib.has_curated_assets():
		return
	var foliage_models: Array[String] = [
		"nature/Plant_1.obj", "nature/Plant_2.obj", "nature/Plant_3.obj",
		"nature/Flowers.obj", "nature/Plant_1.obj", "nature/Wheat.obj",
	]
	var lake_poly_guard: PackedVector2Array = FishingSpotScript.lake_scaled(1.18, 12.0)
	var marsh_poly_guard := PackedVector2Array([
		Vector2(-1890, 195), Vector2(-1620, 150), Vector2(-1325, 165), Vector2(-1180, 240),
		Vector2(-1200, 405), Vector2(-1345, 485), Vector2(-1660, 500), Vector2(-1875, 435),
		Vector2(-1930, 310)
	])
	var idx: int = 0
	for gx in range(-2050, 1480, 95):
		for gy in range(-520, 1280, 95):
			idx += 1
			var jx: float = float(((idx * 73) % 59) - 29)
			var jy: float = float(((idx * 41) % 59) - 29)
			var fp := Vector2(float(gx) + jx, float(gy) + jy)
			# Saltar calzadas principales, plaza central, lago, ciénaga y huellas de edificios
			if absf(fp.y - 50.0) < 30.0 or (fp.x > 375.0 and fp.x < 555.0 and fp.y > 0.0 and fp.y < 95.0):
				continue
			if Geometry2D.is_point_in_polygon(fp, lake_poly_guard) or Geometry2D.is_point_in_polygon(fp, marsh_poly_guard):
				continue
			if fp.distance_to(FishingSpotScript.LAKE_NODE_POS) < 95.0 or terrain_height_px(fp) < -0.8:
				continue
			if VillageRestaurant.RECT.grow(16.0).has_point(fp) or VillageTavern.RECT.grow(16.0).has_point(fp):
				continue
			if fp.x > 160.0 and fp.x < 1380.0 and fp.y > -480.0 and fp.y < 360.0 and ((idx % 3) != 0):
				continue
			var mdl: String = foliage_models[idx % foliage_models.size()]
			var h_f: float = 4.2 + float(idx % 4) * 1.1
			var node_f := _add_model_2d(terrain_root_3d, mdl, fp, -0.8, Vector2.ZERO, h_f, float((idx * 53) % 360))
			if node_f != null and nature_root_3d != null:
				_absorb_into_batches(node_f, fp)
	_flush_batches()


## Lago 3D con abundante agua azul a cota -1.5 px, orillas suaves de hierba con juncos y piedras, y un único muelle a ras del agua.
func _build_lake_3d() -> void:
	var m_lake := _mat("lake_water", Color(0.24, 0.54, 0.82, 0.92), 0.12, 0.14, Color.BLACK, 0.0, "town_textures/floor_ground_water.png", "", 0.55)
	var m_deep := _mat("lake_deep", Color(0.14, 0.34, 0.60, 0.95), 0.10, 0.12, Color.BLACK, 0.0, "town_textures/floor_ground_water.png", "", 0.55)
	for lm in [m_lake, m_deep]:
		(lm as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_flat_poly_2d(terrain_root_3d, FishingSpotScript.lake_scaled(1.12, 8.0), -1.0, m_lake, true)
	_add_flat_poly_2d(terrain_root_3d, FishingSpotScript.lake_scaled(0.66, 0.0), -0.8, m_deep, true)
	# Un único muelle de madera en la orilla este del lago, a ras del agua (-1.0 px) y sin tablón suelto
	var m_dock := _mat("dock_wood", Color(0.62, 0.44, 0.28), 0.9, 0.0, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78)
	var dock_c: Vector2 = FishingSpotScript.LAKE_NODE_POS + Vector2(32.0, 0.0)
	var dock_mi := MeshInstance3D.new()
	var dock_bm := BoxMesh.new()
	dock_bm.size = size_3d(Vector2(44.0, 16.0), 1.6)
	dock_mi.mesh = dock_bm
	dock_mi.material_override = m_dock
	dock_mi.position = to_3d_flat(dock_c, 0.1)
	terrain_root_3d.add_child(dock_mi)
	for px in [-15.0, 0.0, 15.0]:
		for py in [-7.0, 7.0]:
			var post_mi := MeshInstance3D.new()
			var post_bm := BoxMesh.new()
			post_bm.size = size_3d(Vector2(2.4, 2.4), 5.2)
			post_mi.mesh = post_bm
			post_mi.material_override = m_dock
			post_mi.position = to_3d_flat(dock_c + Vector2(px, py), -1.8)
			terrain_root_3d.add_child(post_mi)
	# Juncos, matas ribereñas y piedras a lo largo de la orilla exterior del lago
	var shore_pts: PackedVector2Array = FishingSpotScript.lake_scaled(1.15, 8.0)
	for si in range(shore_pts.size()):
		var sp: Vector2 = shore_pts[si]
		if sp.distance_to(dock_c) < 28.0:
			continue
		if (si % 3) == 0:
			_add_model_2d(terrain_root_3d, "nature/Rock_1.obj" if (si % 2) == 0 else "nature/Rock_2.obj", sp, -0.6, Vector2.ZERO, 7.5, float(si * 53))
		_add_model_2d(terrain_root_3d, "nature/Plant_1.obj" if (si % 2) == 0 else "nature/Plant_3.obj", sp + Vector2(3.0, -2.0), -0.5, Vector2.ZERO, 7.2, float(si * 37))


## Superficie plana con la forma de un polígono del mapa 2D, a una altura dada (si absolute_h es true, no suma el relieve).
func _add_flat_poly_2d(parent: Node3D, pts: PackedVector2Array, h_px: float, mat: Material, absolute_h: bool = false) -> MeshInstance3D:
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


## Bloque AA: detalles fijos de los barrios apartados (molino de viento y leñeros de los caseríos; el lago solo tiene un muelle).
func _build_barrios_3d(m_wood: Material) -> void:
	var mp: Vector2 = VillageLots.EAST_MILL_POS
	# (El molino de Kenney es casi solo aspas y desde arriba parece un palo: va el de Quaternius, con su casa de piedra.)
	_add_model_2d(terrain_root_3d, "buildings/Mill.obj", mp, 0.0, Vector2(40, 40), 52.0)
	for wp in [Vector2(-532, 820), Vector2(-522, 920), Vector2(-528, 1020)]:
		for k in range(3):
			var lg := _add_cyl_2d(terrain_root_3d, wp + Vector2(0, k * 5.0 - 5.0), 2.4, 0.0, 16.0, m_wood, 2.4, 7)
			lg.rotation_degrees.z = 90.0
			lg.position = to_3d(wp + Vector2(0, k * 5.0 - 5.0), 2.4 + (3.6 if k == 1 else 0.0))


## Busca árboles talables, vetas de mineral y pinos decorativos 2D (cada pocos segundos, por si se plantan nuevos).
func _scan_nature_sources() -> void:
	if vm == null or not is_instance_valid(vm.entities_root):
		return
	_nature_sources.clear()
	var tree_positions_seen: Array[Vector2] = []
	for n in get_tree().get_nodes_in_group("destructible"):
		if not (n is Node2D) or n.get("harvest_type") == null:
			continue
		var ht: int = int(n.get("harvest_type"))
		var kind := ""
		if ht == 1:
			kind = "pine"
			tree_positions_seen.append((n as Node2D).global_position)
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
				var tp: Vector2 = (c as Sprite2D).global_position
				# Evitar que árboles decorativos se solapen con muros de edificios, bancos del parque u otros árboles
				var overlaps := false
				if "building_footprints" in vm:
					for b_fp in vm.building_footprints:
						if (b_fp["rect"] as Rect2).grow(12.0).has_point(tp):
							overlaps = true
							break
				if not overlaps:
					for existing_tp in tree_positions_seen:
						if existing_tp.distance_squared_to(tp) < 18.0 * 18.0:
							overlaps = true
							break
				if overlaps:
					(c as Sprite2D).visible = false
					continue
				tree_positions_seen.append(tp)
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
		var stump: Node3D = null
		if kind == "pine":
			stump = _add_cyl_2d(nature_root_3d, pos, 5.0, -1.2, 6.2, _mat("tree_stump", Color(0.45, 0.32, 0.20), 0.9, 0.0, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78), 4.5, 8)
			stump.visible = false
		return {"tree": t, "stump": stump}
	if kind == "rock":
		var rfiles := ["nature/Rock_1.obj", "nature/Rock_2.obj", "nature/Rock_3.obj", "nature/Rock_4.obj", "nature/Rock_5.obj"]
		var r := _add_model_2d(nature_root_3d, rfiles[hv % rfiles.size()], pos, -1.4, Vector2.ZERO, 16.0, rot)
		var low := _add_model_2d(nature_root_3d, rfiles[(hv + 2) % rfiles.size()], pos, -1.2, Vector2.ZERO, 6.0, rot + 40.0)
		if low != null:
			low.visible = false
		return {"tree": r, "stump": low}
	return {}



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
	var m_grass_park := _make_ground_shader_mat("ground_park_sh", Color(0.31, 0.48, 0.23), Color(0.23, 0.38, 0.17), Color(0.42, 0.34, 0.23), 0.10)
	var m_pine := _mat("pine_leaf", Color(0.16, 0.38, 0.18), 0.88, 0.0)
	var m_pine_top := _mat("pine_leaf_top", Color(0.22, 0.46, 0.22), 0.86, 0.0)
	var m_iron := _mat("wrought_iron", Color(0.22, 0.24, 0.28), 0.45, 0.75)
	var m_shingle := _mat("roof_shingle_brown", Color(0.56, 0.30, 0.18), 0.82, 0.04, Color.BLACK, 0.0, "town_textures/roof_clay_red_center.png", "", 0.75)

	# Caminos principales y calles con relieve 3D
	var road_rects: Array[Rect2] = [
		Rect2(Vector2(-1950, 36), Vector2(3288, 28)),
		Rect2(Vector2(-688, -88), Vector2(18, 124)),
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
	for rr in road_rects:
		_add_road_strip_3d(terrain_root_3d, rr, 1.2, m_road)
	for lr in VillageLots.ROADS:
		if lr is Rect2:
			_add_road_strip_3d(terrain_root_3d, lr as Rect2, 1.2, m_road)
	_build_barrios_3d(m_wood)
	# Callejas curvas del norte: un tramo de camino por segmento, girado, con una losa en cada codo
	for cr in VillageLots.CURVED_ROADS:
		var cpts: PackedVector2Array = VillageLots.curved_road_points(cr)
		var cw: float = float(cr["w"])
		for i in range(cpts.size() - 1):
			var a: Vector2 = cpts[i]
			var b: Vector2 = cpts[i + 1]
			_add_box_2d(terrain_root_3d, (a + b) * 0.5, Vector2(a.distance_to(b) + 2.0, cw), 0.0, 1.2, m_road, -rad_to_deg((b - a).angle()))

	# Plaza Central Empedrada en plataforma ligeramente elevada (+2.4 px en terreno) con bordillos y rampa empedrada suave en los 4 accesos
	var plaza_r := Rect2(Vector2(388, 12), Vector2(154, 72))
	_add_road_strip_3d(terrain_root_3d, plaza_r, 1.5, m_plaza)
	_add_box_2d(terrain_root_3d, Vector2(plaza_r.get_center().x, plaza_r.position.y), Vector2(plaza_r.size.x, 4.0), 1.5, 1.6, m_plaza_trim)
	_add_box_2d(terrain_root_3d, Vector2(plaza_r.get_center().x, plaza_r.end.y), Vector2(plaza_r.size.x, 4.0), 1.5, 1.6, m_plaza_trim)
	# Bordillos de piedra de la rampa de subida en los 4 accesos de la Plaza y en la subida al barrio del Este
	for access_curb in [
		[Vector2(374.0, 34.0), Vector2(24.0, 2.8)],
		[Vector2(374.0, 66.0), Vector2(24.0, 2.8)],
		[Vector2(556.0, 34.0), Vector2(24.0, 2.8)],
		[Vector2(556.0, 66.0), Vector2(24.0, 2.8)],
		[Vector2(662.0, 34.0), Vector2(28.0, 2.8)],
		[Vector2(662.0, 66.0), Vector2(28.0, 2.8)],
	]:
		_add_box_2d(terrain_root_3d, access_curb[0] as Vector2, access_curb[1] as Vector2, 0.2, 1.6, m_curb)

	# Bancos reales 3D de la Plaza Central
	for bp in [Vector2(468, 82), Vector2(516, 82)]:
		_build_bench_3d(terrain_root_3d, bp, m_wood, m_iron)

	# Tablón de Encargos 3D detallado en la Plaza (Vector2(476, 14)) con 3 pliegos legibles desde fuera
	var nb: Vector2 = vm._notice_board_pos if vm != null else Vector2(476, 14)
	_add_box_2d(terrain_root_3d, nb + Vector2(-10.0, 0.0), Vector2(3.6, 3.6), 0.0, 2.2, m_curb)
	_add_box_2d(terrain_root_3d, nb + Vector2(10.0, 0.0), Vector2(3.6, 3.6), 0.0, 2.2, m_curb)
	_add_box_2d(terrain_root_3d, nb + Vector2(-10.0, 0.0), Vector2(2.6, 2.6), 2.0, 17.5, m_dark_wood)
	_add_box_2d(terrain_root_3d, nb + Vector2(10.0, 0.0), Vector2(2.6, 2.6), 2.0, 17.5, m_dark_wood)
	_add_box_2d(terrain_root_3d, nb, Vector2(24.0, 2.6), 6.2, 11.2, m_dark_wood)
	var m_cork := _mat("notice_cork", Color(0.56, 0.39, 0.23), 0.92, 0.0)
	_add_box_2d(terrain_root_3d, nb + Vector2(0.0, 0.4), Vector2(21.6, 2.2), 7.0, 9.6, m_cork)
	_add_box_2d(terrain_root_3d, nb, Vector2(26.5, 6.2), 17.2, 2.8, m_shingle)
	_add_box_2d(terrain_root_3d, nb + Vector2(0.0, 1.4), Vector2(19.0, 1.0), 15.6, 2.0, m_dark_wood)
	var hdr_lbl := Label3D.new()
	hdr_lbl.text = "ENCARGOS DEL VALLE"
	hdr_lbl.font_size = 22
	hdr_lbl.pixel_size = 0.00075
	hdr_lbl.modulate = Color(0.96, 0.88, 0.62)
	hdr_lbl.outline_size = 2
	hdr_lbl.outline_modulate = Color(0.14, 0.10, 0.06)
	hdr_lbl.shaded = false
	hdr_lbl.double_sided = true
	hdr_lbl.position = to_3d(nb + Vector2(0.0, 2.05), 16.6)
	terrain_root_3d.add_child(hdr_lbl)
	var m_paper := _mat("parchment", Color(0.95, 0.90, 0.76), 0.90, 0.0)
	var m_wax := _mat("notice_wax_seal", Color(0.76, 0.18, 0.16), 0.55, 0.1)
	var sheet_defs := [
		[-6.8, "GREMIOS\n2 Maderas o\n1 Hierro\n28 ORO"],
		[0.0, "HOSPITAL\n2 Hierbas o\nCataplasma\n26 ORO"],
		[6.8, "ALGUACIL\nChatarra o\nAncas Rana\n34 ORO"],
	]
	for s_def in sheet_defs:
		var px: float = float(s_def[0])
		_add_box_2d(terrain_root_3d, nb + Vector2(px, 1.4), Vector2(5.8, 0.5), 7.5, 7.8, m_paper)
		_add_box_2d(terrain_root_3d, nb + Vector2(px, 1.75), Vector2(0.9, 0.4), 14.3, 0.8, m_wax)
		var s_lbl := Label3D.new()
		s_lbl.text = str(s_def[1])
		s_lbl.font_size = 20
		s_lbl.line_spacing = -2.0
		s_lbl.pixel_size = 0.00060
		s_lbl.modulate = Color(0.16, 0.11, 0.06)
		s_lbl.outline_size = 1
		s_lbl.outline_modulate = Color(0.95, 0.90, 0.76)
		s_lbl.shaded = false
		s_lbl.double_sided = true
		s_lbl.position = to_3d(nb + Vector2(px, 2.08), 11.1)
		terrain_root_3d.add_child(s_lbl)

	# (2026-11-06) Los pozos ya no van fijos aquí: los pone _sync_props_3d donde esté cada pozo 2D (también los de solares nuevos).

	# Campos arados 3D de la Granja del Sur (s1: x = -200..-113, s2: x = -77..137, y = 400..540) y explanada de roca de la Cantera (w1: x = -210..-123, y = -400..-260)
	var m_plowed := _mat("farm_plowed_soil", Color(0.38, 0.28, 0.17), 0.94, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.45)
	var m_furrow := _mat("farm_wheat_furrow", Color(0.68, 0.72, 0.26), 0.88, 0.0)
	for f_rect in [Rect2(Vector2(-200.0, 400.0), Vector2(87.0, 140.0)), Rect2(Vector2(-77.0, 400.0), Vector2(214.0, 140.0))]:
		_add_box_2d(terrain_root_3d, f_rect.get_center(), f_rect.size, 0.0, 0.8, m_plowed)
		var fy: float = f_rect.position.y + 10.0
		while fy < f_rect.end.y - 4.0:
			_add_box_2d(terrain_root_3d, Vector2(f_rect.get_center().x, fy), Vector2(f_rect.size.x - 8.0, 4.0), 0.8, 1.4, m_furrow)
			fy += 14.0
	var quarry_r := Rect2(Vector2(-210.0, -400.0), Vector2(87.0, 140.0))
	var m_quarry_rock := _mat("quarry_slab_3d", Color(0.50, 0.48, 0.44), 0.90, 0.04, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.42)
	_add_box_2d(terrain_root_3d, quarry_r.get_center(), quarry_r.size, 0.0, 1.0, m_quarry_rock)

	# Corral 3D de madera y tierra del Rancho del Sur (x = 304..416, y = 398..544; el ganado vivo lo sincroniza VillageHousing.sync_livestock)
	var ranch_floor_r := Rect2(Vector2(304.0, 398.0), Vector2(112.0, 146.0))
	_add_box_2d(terrain_root_3d, ranch_floor_r.get_center(), ranch_floor_r.size, 0.0, 0.8, m_road)
	for r_side in [
		[Vector2(304.0, 398.0), Vector2(416.0, 398.0)],
		[Vector2(416.0, 398.0), Vector2(416.0, 544.0)],
		[Vector2(416.0, 544.0), Vector2(304.0, 544.0)],
		[Vector2(304.0, 544.0), Vector2(304.0, 398.0)],
	]:
		_build_fence_run_3d(terrain_root_3d, r_side[0] as Vector2, r_side[1] as Vector2, m_wood)
	# Abrevadero de madera con agua y pacas de heno en el corral del Rancho del Sur
	var m_hay := _mat("ranch_hay", Color(0.84, 0.72, 0.34), 0.92, 0.0)
	var m_trough_w := _mat("ranch_trough_water", Color(0.24, 0.52, 0.68), 0.25, 0.1)
	_add_box_2d(terrain_root_3d, Vector2(316.0, 412.0), Vector2(16.0, 6.0), 0.8, 4.2, m_dark_wood)
	_add_box_2d(terrain_root_3d, Vector2(316.0, 412.0), Vector2(13.6, 4.0), 3.6, 1.6, m_trough_w)
	_add_box_2d(terrain_root_3d, Vector2(404.0, 414.0), Vector2(9.0, 7.0), 0.8, 5.2, m_hay)
	_add_box_2d(terrain_root_3d, Vector2(404.0, 423.0), Vector2(8.0, 6.5), 0.8, 4.4, m_hay)

	# Parque del Roble ampliado (Rect2(168, 208, 272, 146)) con césped natural texturizado, bordillo bajo de piedra y bancos despejados
	var park_r := Rect2(Vector2(168.0, 208.0), Vector2(272.0, 146.0))
	var park_c: Vector2 = park_r.get_center()
	_add_box_2d(terrain_root_3d, park_c, park_r.size, 0.0, 0.25, m_grass_park)
	_add_box_2d(terrain_root_3d, Vector2(park_c.x, park_r.position.y), Vector2(park_r.size.x, 3.0), 0.0, 1.4, m_curb)
	_add_box_2d(terrain_root_3d, Vector2(park_c.x, park_r.end.y), Vector2(park_r.size.x, 3.0), 0.0, 1.4, m_curb)
	_add_box_2d(terrain_root_3d, Vector2(park_r.position.x, park_c.y), Vector2(3.0, park_r.size.y), 0.0, 1.4, m_curb)
	_add_box_2d(terrain_root_3d, Vector2(park_r.end.x, park_c.y), Vector2(3.0, park_r.size.y), 0.0, 1.4, m_curb)
	_add_box_2d(terrain_root_3d, Vector2(park_c.x, 280.0), Vector2(park_r.size.x - 16.0, 18.0), 0.0, 0.8, m_road)
	_add_box_2d(terrain_root_3d, park_c, Vector2(18.0, park_r.size.y - 16.0), 0.0, 0.8, m_road)
	var tree_idx := 0
	for tp in [Vector2(188.0, 224.0), Vector2(420.0, 224.0), Vector2(188.0, 338.0), Vector2(420.0, 338.0), Vector2(304.0, 228.0)]:
		_build_tree_3d(terrain_root_3d, tp, m_dark_wood, m_pine, m_pine_top, 1.22 if tp == Vector2(304.0, 228.0) else 0.95, tree_idx)
		tree_idx += 1
	_build_bench_3d(terrain_root_3d, Vector2(236.0, 260.0), m_wood, m_iron)
	_build_bench_3d(terrain_root_3d, Vector2(372.0, 260.0), m_wood, m_iron)
	for fp in [Vector2(248.0, 226.0), Vector2(360.0, 226.0), Vector2(248.0, 334.0), Vector2(360.0, 334.0), Vector2(304.0, 316.0)]:
		_add_cyl_2d(terrain_root_3d, fp, 4.5, 0.0, 4.5, _mat("terracotta_pot", Color(0.68, 0.34, 0.20), 0.85, 0.0), 3.2, 8)
		_add_cyl_2d(terrain_root_3d, fp, 5.2, 4.0, 4.5, m_pine_top, 3.5, 8)
	# Mirador del Lago en 3D
	var lv_pos := Vector2(-715.0, 184.0)
	_build_fence_run_3d(terrain_root_3d, lv_pos + Vector2(-34.0, -12.0), lv_pos + Vector2(34.0, -12.0), m_wood)
	_build_bench_3d(terrain_root_3d, lv_pos + Vector2(0.0, -2.0), m_wood, m_iron)

	# Lavadero Municipal, recolocado junto a una fuente/acequia del pueblo (al oeste de la Botica y al norte del Parque)
	var wash_c: Vector2 = VillageWorkScript.LAVADERO_POS
	_add_box_2d(terrain_root_3d, wash_c, Vector2(46, 32), 0.0, 2.0, m_stone)
	_add_box_2d(terrain_root_3d, wash_c, Vector2(32, 14), 2.0, 5.5, m_curb)
	_add_box_2d(terrain_root_3d, wash_c, Vector2(28, 10), 2.5, 4.8, m_water)
	for wp_off in [Vector2(-19, -12), Vector2(19, -12), Vector2(-19, 12), Vector2(19, 12)]:
		_add_box_2d(terrain_root_3d, wash_c + wp_off, Vector2(2.5, 2.5), 2.0, 18.0, m_dark_wood)
	_add_box_2d(terrain_root_3d, wash_c, Vector2(50, 36), 20.0, 4.5, m_shingle)
	_add_model_2d(terrain_root_3d, "props/Bucket_Wooden_1.gltf", wash_c + Vector2(-14, 10), 2.0, Vector2.ZERO, 6.5)
	_add_model_2d(terrain_root_3d, "props/Barrel.gltf", wash_c + Vector2(16, -10), 2.0, Vector2.ZERO, 10.0)

	# Lago del Oeste (junto al campamento inicial, un solo muelle a ras del agua, sin lavadero); sauces en la orilla exterior
	_build_lake_3d()
	_add_model_2d(terrain_root_3d, "nature/Willow_1.obj", Vector2(-955, 72), -0.6, Vector2.ZERO, 40.0)
	_add_model_2d(terrain_root_3d, "nature/Willow_2.obj", Vector2(-1105, 195), -0.6, Vector2.ZERO, 38.0, 70.0)
	_add_model_2d(terrain_root_3d, "nature/Willow_1.obj", Vector2(-840, 238), -0.6, Vector2.ZERO, 34.0, 140.0)

	# Ciénaga de las Ranas del Suroeste (cuenca baja con lámina de agua a -1.4 px y arbustos/sauces solo en las orillas secas)
	var marsh_water_pts := PackedVector2Array([
		Vector2(-1860, 210), Vector2(-1620, 165), Vector2(-1340, 180), Vector2(-1200, 250),
		Vector2(-1220, 390), Vector2(-1360, 470), Vector2(-1650, 485), Vector2(-1850, 420),
		Vector2(-1910, 310)
	])
	_add_flat_poly_2d(terrain_root_3d, marsh_water_pts, -1.4, m_marsh, true)
	for rp in [
		Vector2(-1880, 198), Vector2(-1710, 152), Vector2(-1480, 155), Vector2(-1310, 166),
		Vector2(-1185, 255), Vector2(-1205, 415), Vector2(-1560, 500), Vector2(-1865, 435)
	]:
		if _add_model_2d(terrain_root_3d, "nature/Bush_1.obj", rp, -0.5, Vector2.ZERO, 12.0) == null:
			_add_cyl_2d(terrain_root_3d, rp, 4.0, -0.5, 8.0, m_pine, 1.5, 6)
	_add_model_2d(terrain_root_3d, "nature/Willow_2.obj", Vector2(-1895, 205), -0.6, Vector2.ZERO, 36.0)
	_add_model_2d(terrain_root_3d, "nature/Willow_1.obj", Vector2(-1195, 395), -0.6, Vector2.ZERO, 34.0, 110.0)
	_add_model_2d(terrain_root_3d, "nature/Rock_2.obj", Vector2(-1360, 162), -0.6, Vector2.ZERO, 13.0)

	# Matorral, arbustos de bayas y troncos caídos repartidos por el Bosque Profundo ampliado (y = 780..2300)
	var forest_bushes: Array[Vector2] = [
		Vector2(-960, 910), Vector2(-680, 920), Vector2(-460, 870), Vector2(-820, 1080),
		Vector2(-520, 1140), Vector2(-940, 1380), Vector2(-640, 1420), Vector2(-380, 1380),
		Vector2(-820, 1640), Vector2(-480, 1660), Vector2(-720, 1920), Vector2(-380, 2060),
		Vector2(-120, 920), Vector2(180, 910), Vector2(420, 930), Vector2(40, 1140),
		Vector2(340, 1140), Vector2(-40, 1380), Vector2(260, 1360), Vector2(540, 1390),
		Vector2(140, 1620), Vector2(440, 1640), Vector2(-80, 1860), Vector2(280, 1880),
		Vector2(120, 2120), Vector2(460, 2110), Vector2(820, 960), Vector2(1120, 1040),
		Vector2(940, 1220), Vector2(1220, 1360), Vector2(980, 1640), Vector2(1180, 1840)
	]
	var bush_models := ["nature/Bush_1.obj", "nature/Bush_2.obj", "nature/BushBerries_1.obj", "nature/BushBerries_2.obj"]
	for bi in range(forest_bushes.size()):
		var bm: String = bush_models[bi % bush_models.size()]
		_add_model_2d(terrain_root_3d, bm, forest_bushes[bi], -1.0, Vector2.ZERO, 12.5, float((bi * 47) % 360))
	var fallen_logs: Array[Vector2] = [
		Vector2(-860, 1040), Vector2(-490, 1240), Vector2(-740, 1560), Vector2(-560, 1820),
		Vector2(-20, 1090), Vector2(290, 1310), Vector2(80, 1580), Vector2(380, 1810),
		Vector2(180, 2040), Vector2(890, 1180), Vector2(1080, 1490), Vector2(1120, 1920)
	]
	for li in range(fallen_logs.size()):
		_add_model_2d(terrain_root_3d, "nature/WoodLog.obj", fallen_logs[li], -0.8, Vector2.ZERO, 16.0, float((li * 63) % 360))

	# Cercado del Cementerio Parroquial ampliado (Rect2(Vector2(822, 260), Vector2(268, 168))) con caminos en cruz, verja de hierro y piedra y 24 tumbas en filas
	var cem_r := Rect2(Vector2(822.0, 260.0), Vector2(268.0, 168.0))
	var cem_c := cem_r.get_center()
	var m_cem_curb := _mat("cem_curb_stone", Color(0.48, 0.50, 0.54), 0.88, 0.05)
	var m_cem_mound := _mat("cem_mound_earth", Color(0.34, 0.24, 0.16), 0.95, 0.0)
	_add_box_2d(terrain_root_3d, cem_c, cem_r.size, 0.0, 1.0, _mat("cem_ground", Color(0.24, 0.32, 0.22), 0.95, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.45))
	# Caminos interiores de losas de piedra en cruz (Norte-Sur en x = 888 y Este-Oeste en y = 344)
	_add_box_2d(terrain_root_3d, Vector2(888.0, cem_c.y), Vector2(16.0, cem_r.size.y - 6.0), 1.0, 0.45, m_stone)
	_add_box_2d(terrain_root_3d, Vector2(cem_c.x, 344.0), Vector2(cem_r.size.x - 8.0, 14.0), 1.0, 0.45, m_stone)
	# Zócalo de piedra y verja perimetral de hierro forjado con pilares
	_add_box_2d(terrain_root_3d, Vector2(cem_c.x, cem_r.end.y), Vector2(cem_r.size.x, 3.5), 0.0, 4.0, m_cem_curb)
	_add_box_2d(terrain_root_3d, Vector2(cem_c.x, cem_r.end.y), Vector2(cem_r.size.x, 2.2), 4.0, 8.0, m_iron)
	_add_box_2d(terrain_root_3d, Vector2(cem_r.position.x, cem_c.y), Vector2(3.5, cem_r.size.y), 0.0, 4.0, m_cem_curb)
	_add_box_2d(terrain_root_3d, Vector2(cem_r.position.x, cem_c.y), Vector2(2.2, cem_r.size.y), 4.0, 8.0, m_iron)
	_add_box_2d(terrain_root_3d, Vector2(cem_r.end.x, cem_c.y), Vector2(3.5, cem_r.size.y), 0.0, 4.0, m_cem_curb)
	_add_box_2d(terrain_root_3d, Vector2(cem_r.end.x, cem_c.y), Vector2(2.2, cem_r.size.y), 4.0, 8.0, m_iron)
	_add_box_2d(terrain_root_3d, Vector2(846.0, cem_r.position.y), Vector2(48.0, 3.5), 0.0, 4.0, m_cem_curb)
	_add_box_2d(terrain_root_3d, Vector2(846.0, cem_r.position.y), Vector2(48.0, 2.2), 4.0, 8.0, m_iron)
	_add_box_2d(terrain_root_3d, Vector2(998.0, cem_r.position.y), Vector2(184.0, 3.5), 0.0, 4.0, m_cem_curb)
	_add_box_2d(terrain_root_3d, Vector2(998.0, cem_r.position.y), Vector2(184.0, 2.2), 4.0, 8.0, m_iron)
	for pil_p in [Vector2(822, 260), Vector2(870, 260), Vector2(906, 260), Vector2(998, 260), Vector2(1090, 260), Vector2(822, 344), Vector2(1090, 344), Vector2(822, 428), Vector2(956, 428), Vector2(1090, 428)]:
		_add_box_2d(terrain_root_3d, pil_p, Vector2(6.5, 6.5), 0.0, 14.0, m_cem_curb)
	_add_model_2d(terrain_root_3d, "graveyard/iron-fence.glb", Vector2(888.0, cem_r.position.y), 0.0, Vector2.ZERO, 18.0)

	# 4 filas × 6 columnas = 24 tumbas con bordillo, túmulo de tierra y lápidas/cruces variadas (sin los 2 bloques enormes de piedra)
	var stone_models: Array[String] = [
		"graveyard/gravestone-cross.glb",
		"graveyard/gravestone-round.glb",
		"graveyard/gravestone-decorative.glb",
		"graveyard/gravestone-wide.glb",
		"graveyard/cross-column.glb",
		"graveyard/cross-wood.glb",
	]
	var row_ys_3d: Array[float] = [286.0, 316.0, 372.0, 402.0]
	var col_xs_3d: Array[float] = [852.0, 924.0, 954.0, 984.0, 1014.0, 1044.0]
	var g_i3d: int = 0
	for ry in row_ys_3d:
		for cx in col_xs_3d:
			var gp_cem := Vector2(cx, ry)
			_add_box_2d(terrain_root_3d, gp_cem + Vector2(0, 2.5), Vector2(12.0, 13.0), 1.0, 1.2, m_cem_curb)
			_add_box_2d(terrain_root_3d, gp_cem + Vector2(0, 2.5), Vector2(9.2, 10.2), 2.2, 1.4, m_cem_mound)
			var mdl_path: String = stone_models[g_i3d % stone_models.size()]
			_add_model_2d(terrain_root_3d, mdl_path, gp_cem + Vector2(0, -4.5), 1.5, Vector2(7.5, 3.6), 9.6)
			g_i3d += 1

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
	var tree_files := [
		"nature/CommonTree_1.obj", "nature/CommonTree_2.obj", "nature/BirchTree_1.obj",
		"nature/CommonTree_3.obj", "nature/BirchTree_2.obj", "nature/CommonTree_4.obj",
		"nature/PineTree_1.obj", "nature/BirchTree_3.obj",
	]
	var t_file: String = tree_files[posmod(variant, tree_files.size())]
	if _add_model_2d(parent, t_file, pos_2d, 0.0, Vector2.ZERO, 36.0 * scale_f, float(variant * 67)) != null:
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

