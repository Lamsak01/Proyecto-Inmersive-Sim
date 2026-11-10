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
			var mid_p := Vector2((x0 + x1) * 0.5, (y0 + y1) * 0.5)
			if mid_p.y >= FishingSpotScript.river_y_start() and mid_p.y <= FishingSpotScript.river_y_end() and absf(mid_p.x - FishingSpotScript.river_center_x(mid_p.y)) <= FishingSpotScript.river_half_width(mid_p.y) + 6.0:
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
			if fp.y >= FishingSpotScript.river_y_start() and fp.y <= FishingSpotScript.river_y_end() and absf(fp.x - FishingSpotScript.river_center_x(fp.y)) < FishingSpotScript.river_half_width(fp.y) + 18.0:
				continue
			if Rect2(Vector2(85.0, -915.0), Vector2(95.0, 100.0)).has_point(fp) or FishingSpotScript.ABANDONED_MILL_RECT.grow(18.0).has_point(fp):
				continue
			if VillageRestaurant.RECT.grow(16.0).has_point(fp) or VillageTavern.RECT.grow(16.0).has_point(fp):
				continue
			if Rect2(Vector2(822.0, 260.0), Vector2(268.0, 168.0)).grow(10.0).has_point(fp):
				continue
			if vm != null and "building_footprints" in vm:
				var inside_b: bool = false
				for b_fp in vm.building_footprints:
					if (b_fp["rect"] as Rect2).grow(12.0).has_point(fp):
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
			if en_cauce_del_rio((n as Node2D).global_position, 2.0):
				(n as Node2D).visible = false # árbol talable que quedó dentro del río redibujado
				continue
			kind = "pine"
			tree_positions_seen.append((n as Node2D).global_position)
		elif ht == 2:
			kind = "rock"
		elif ht == 0:
			# Setas y hierbas que se recogen (2026-11-10): modelos 3D en vez del dibujo 2D
			kind = "forage_mushroom" if String(n.get("primary_item_id")) == "mushroom" else "forage_herb"
		if kind.is_empty():
			continue
		_nature_sources.append({"node": n, "kind": kind, "sprite": n.get("sprite")})
	# Setas y hierbas que se recogen (grupo «wild_flora», no «destructible»)
	for n in get_tree().get_nodes_in_group("wild_flora"):
		if n is Node2D and n.get("harvest_type") != null and int(n.get("harvest_type")) == 0:
			var fk: String = "forage_mushroom" if String(n.get("primary_item_id")) == "mushroom" else "forage_herb"
			_nature_sources.append({"node": n, "kind": fk, "sprite": n.get("sprite")})
	var parents: Array = [vm.entities_root]
	for eco in get_tree().get_nodes_in_group("ecosystem_manager"):
		parents.append(eco)
	for par in parents:
		for c in (par as Node).get_children():
			if c is Sprite2D and _is_pine_texture((c as Sprite2D).texture):
				var tp: Vector2 = (c as Sprite2D).global_position
				# Evitar que árboles decorativos se solapen con muros de edificios, bancos del parque u otros árboles
				var overlaps := en_cauce_del_rio(tp, 2.0)
				if not overlaps and "building_footprints" in vm:
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
	if kind == "forage_mushroom":
		# Kenney Nature Kit (CC0): seta roja o parda, sola, alta o en grupo
		var mfiles := ["nature/kenney/mushroom_redGroup.glb", "nature/kenney/mushroom_tan.glb", "nature/kenney/mushroom_red.glb",
			"nature/kenney/mushroom_tanGroup.glb", "nature/kenney/mushroom_redTall.glb", "nature/kenney/mushroom_tanTall.glb"]
		var mf: String = mfiles[hv % mfiles.size()]
		var m := _add_model_2d(nature_root_3d, mf, pos, -0.3, Vector2.ZERO, 7.5 if "Tall" in mf else 5.5, rot)
		return {"tree": m, "stump": null}
	if kind == "forage_herb":
		var hfiles := ["nature/Plant_4.obj", "nature/Plant_5.obj"]
		var hb := _add_model_2d(nature_root_3d, hfiles[hv % hfiles.size()], pos, -0.3, Vector2.ZERO, 8.5, rot)
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

func _merge_terrain_by_chunks() -> void:
	if _is_headless or terrain_root_3d == null:
		return
	var found: Array = []
	_collect_merge_meshes(terrain_root_3d, terrain_root_3d, {}, found)
	var chunk: float = TERRAIN_MERGE_CHUNK_PX * WORLD_SCALE
	var groups: Dictionary = {}
	for mi in found:
		if not _plain_static_materials(mi):
			continue
		var aabb: AABB = mi.global_transform * mi.mesh.get_aabb()
		if aabb.size.x > chunk * 0.5 or aabb.size.z > chunk * 0.5:
			continue
		var c3: Vector3 = aabb.get_center()
		var key := Vector2i(floori(c3.x / chunk), floori(c3.z / chunk))
		if not groups.has(key):
			groups[key] = []
		groups[key].append(mi)
	for key in groups.keys():
		if (groups[key] as Array).size() < 2:
			continue
		var holder := Node3D.new()
		holder.name = "TerrenoJuntado_%d_%d" % [key.x, key.y]
		terrain_root_3d.add_child(holder)
		_merge_mesh_list(holder, groups[key])

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

	# Caminos principales y calles con relieve 3D (divididos en el cruce del Puente Viejo en x = 92..144)
	var road_rects: Array = CALLES_PRINCIPALES
	# Editor del mapa 3D (2026-11-10): si mapa/Mundo3D.tscn tiene «Caminos», esos tramos sustituyen a las calles rectas
	var tramos_ed: Array = load("res://mapa/camino.gd").tramos()
	if not tramos_ed.is_empty():
		road_rects = []
		for t in tramos_ed:
			_add_tramo_3d(terrain_root_3d, t["a"], t["b"], float(t["ancho"]), 0.25, m_road)
	for rr in road_rects:
		_add_road_strip_3d(terrain_root_3d, rr, 0.25, m_road)
	for lr in (VillageLots.ROADS if tramos_ed.is_empty() else []):
		if lr is Rect2:
			_add_road_strip_3d(terrain_root_3d, lr as Rect2, 0.25, m_road)
	_build_barrios_3d(m_wood)
	# Camino de entrada al valle en las afueras occidentales (x = -1320..-720, y = 50):
	# pinos, robles, matorrales, mojón de piedra y poste indicador de madera flanqueando la entrada
	for entry_tree in [
		[Vector2(-1285.0, 8.0), "nature/PineTree_1.obj", 44.0, 25.0],
		[Vector2(-1230.0, 12.0), "nature/CommonTree_1.obj", 38.0, 90.0],
		[Vector2(-1160.0, 10.0), "nature/PineTree_2.obj", 42.0, 145.0],
		[Vector2(-1095.0, 12.0), "nature/BirchTree_1.obj", 36.0, 210.0],
		[Vector2(-1010.0, 6.0), "nature/PineTree_1.obj", 44.0, 15.0],
		[Vector2(-955.0, 12.0), "nature/PineTree_2.obj", 38.0, 110.0],
		[Vector2(-885.0, 8.0), "nature/CommonTree_1.obj", 36.0, 45.0],
		[Vector2(-825.0, 10.0), "nature/PineTree_3.obj", 42.0, 195.0],
		[Vector2(-760.0, 12.0), "nature/BirchTree_1.obj", 34.0, 75.0],
		[Vector2(-1270.0, 88.0), "nature/PineTree_2.obj", 42.0, 170.0],
		[Vector2(-1205.0, 86.0), "nature/CommonTree_2.obj", 38.0, 60.0],
		[Vector2(-1138.0, 90.0), "nature/PineTree_3.obj", 44.0, 130.0],
		[Vector2(-1070.0, 86.0), "nature/CommonTree_1.obj", 38.0, 250.0],
		[Vector2(-1000.0, 92.0), "nature/PineTree_2.obj", 42.0, 160.0],
		[Vector2(-938.0, 86.0), "nature/CommonTree_2.obj", 38.0, 230.0],
		[Vector2(-872.0, 88.0), "nature/PineTree_1.obj", 40.0, 85.0],
	]:
		_add_model_2d(terrain_root_3d, str(entry_tree[1]), entry_tree[0] as Vector2, -0.4, Vector2.ZERO, float(entry_tree[2]), float(entry_tree[3]))
	for entry_bush in [
		Vector2(-1210.0, 24.0), Vector2(-1145.0, 25.0), Vector2(-1080.0, 24.0),
		Vector2(-1200.0, 76.0), Vector2(-1135.0, 75.0), Vector2(-1065.0, 75.0),
		Vector2(-945.0, 24.0), Vector2(-898.0, 25.0), Vector2(-848.0, 23.0),
		Vector2(-950.0, 76.0), Vector2(-890.0, 75.0), Vector2(-835.0, 74.0),
	]:
		_add_model_2d(terrain_root_3d, "nature/Bush_1.obj", entry_bush, -0.2, Vector2.ZERO, 8.5, fmod(absf(entry_bush.x) * 19.0, 360.0))
	# Mojón de piedra e indicador de madera a la vera del camino de entrada (x = -1152, y = 30)
	_add_box_2d(terrain_root_3d, Vector2(-1152.0, 30.0), Vector2(4.5, 4.5), 0.0, 7.5, m_stone)
	_add_cyl_2d(terrain_root_3d, Vector2(-1146.0, 30.0), 1.0, 0.0, 14.0, m_dark_wood, 1.0, 6)
	_add_box_2d(terrain_root_3d, Vector2(-1143.5, 30.0), Vector2(8.0, 1.4), 10.5, 3.0, m_wood, -8.0)
	# Callejas curvas del norte: un tramo de camino por segmento, girado, con una losa en cada codo
	for cr in VillageLots.CURVED_ROADS:
		var cpts: PackedVector2Array = VillageLots.curved_road_points(cr)
		var cw: float = float(cr["w"])
		for i in range(cpts.size() - 1):
			var a: Vector2 = cpts[i]
			var b: Vector2 = cpts[i + 1]
			_add_box_2d(terrain_root_3d, (a + b) * 0.5, Vector2(a.distance_to(b) + 2.0, cw), -0.35, 0.60, m_road, -rad_to_deg((b - a).angle()))

	# Plaza Central Empedrada en plataforma ligeramente elevada (+2.4 px en terreno) con bordillos a ras de calzada y rampa empedrada suave en los 4 accesos
	var plaza_r := Rect2(Vector2(388, 12), Vector2(154, 72))
	_add_road_strip_3d(terrain_root_3d, plaza_r, 0.35, m_plaza)
	_add_box_2d(terrain_root_3d, Vector2(plaza_r.get_center().x, plaza_r.position.y), Vector2(plaza_r.size.x, 4.0), -1.0, 1.45, m_plaza_trim)
	_add_box_2d(terrain_root_3d, Vector2(plaza_r.get_center().x, plaza_r.end.y), Vector2(plaza_r.size.x, 4.0), -1.0, 1.45, m_plaza_trim)
	# Bordillos de piedra de la rampa de subida en los 4 accesos de la Plaza y en la subida al barrio del Este
	for access_curb in [
		[Vector2(374.0, 34.0), Vector2(24.0, 2.8)],
		[Vector2(374.0, 66.0), Vector2(24.0, 2.8)],
		[Vector2(556.0, 34.0), Vector2(24.0, 2.8)],
		[Vector2(556.0, 66.0), Vector2(24.0, 2.8)],
		[Vector2(662.0, 34.0), Vector2(28.0, 2.8)],
		[Vector2(662.0, 66.0), Vector2(28.0, 2.8)],
	]:
		_add_box_2d(terrain_root_3d, access_curb[0] as Vector2, access_curb[1] as Vector2, -0.8, 1.25, m_curb)

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
		_add_model_2d(terrain_root_3d, "nature/WoodLog_Moss.obj" if li % 2 == 0 else "nature/WoodLog.obj", fallen_logs[li], -0.8, Vector2.ZERO, 16.0, float((li * 63) % 360))
		_add_model_2d(terrain_root_3d, "nature/TreeStump_Moss.obj", fallen_logs[li] + Vector2(34, -22), -0.5, Vector2.ZERO, 9.0, float(li * 51))
		# Que no se atraviesen (2026-11-10): WoodLog.obj mide 0.63 × 0.75 × 2.67 (largo en su eje Z = «y» del mapa)
		_colision_solida(fallen_logs[li], Vector2(16.0 * 0.84 / _cos_p, 16.0 * 3.56 * tan(deg_to_rad(PITCH_DEG))), float((li * 63) % 360))
		_colision_solida(fallen_logs[li] + Vector2(34, -22), Vector2(9.0, 9.0), 0.0)
	# Plantas del bosque (2026-11-10, mismo pack que los árboles): helechos y hierba alrededor de cada mata
	var forest_plants := ["nature/Plant_4.obj", "nature/Plant_5.obj", "nature/Plant_1.obj", "nature/Grass.obj", "nature/Grass_Short.obj"]
	for bi in range(forest_bushes.size()):
		for k in range(3):
			var ang: float = float(bi * 3 + k) * 2.39
			var fp: Vector2 = forest_bushes[bi] + Vector2(cos(ang), sin(ang)) * (14.0 + float(k) * 9.0)
			var pf: String = forest_plants[(bi + k * 2) % forest_plants.size()]
			_add_model_2d(terrain_root_3d, pf, fp, -0.2, Vector2.ZERO, 5.0 if "Grass" in pf else 8.0, float((bi * 37 + k * 91) % 360))

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

	# Río de norte a sur, Puente Viejo en el centro del pueblo, arroyo del bosque norte, Claro (barro pardo) y Molino Viejo (barro rojo / arcilla)
	_build_river_and_arroyo_3d(m_road, m_wood, m_dark_wood, m_stone, m_iron, m_pine, m_pine_top)

func _build_river_and_arroyo_3d(
	m_road: Material, m_wood: Material, m_dark_wood: Material,
	m_stone: Material, m_iron: Material, m_pine: Material, m_pine_top: Material
) -> void:
	var m_riv_water := _mat("river_water_3d", Color(0.18, 0.48, 0.76, 0.92), 0.12, 0.16, Color.BLACK, 0.0, "town_textures/floor_ground_water.png", "", 0.62)
	var m_riv_deep := _mat("river_deep_3d", Color(0.09, 0.28, 0.52, 0.96), 0.10, 0.14, Color.BLACK, 0.0, "town_textures/floor_ground_water.png", "", 0.62)
	var m_riv_foam := _mat("river_foam_3d", Color(0.76, 0.88, 0.96, 0.72), 0.22, 0.05)
	for rm in [m_riv_water, m_riv_deep, m_riv_foam]:
		(rm as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED

	var m_bank_earth := _mat("river_bank_earth", Color(0.40, 0.31, 0.20), 0.94, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.65)
	var m_wet_mud := _mat("river_wet_mud", Color(0.25, 0.18, 0.12), 0.44, 0.08, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.72)
	# Barro pardo del Claro del Arroyo donde aparece el cuerpo del Caso I
	var m_brown_mud := _mat("arroyo_brown_mud", Color(0.36, 0.24, 0.14), 0.62, 0.06, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.72)
	# Barro rojo / arcilla junto al Molino Viejo Abandonado (arcilla rojiza viva bien diferenciada del barro pardo del claro)
	var m_red_clay := _mat("mill_red_clay_mud", Color(0.84, 0.16, 0.08), 0.56, 0.04, Color(0.26, 0.04, 0.02), 1.0, "town_textures/floor_ground_dirt.png", "town_textures/wall_stone_n.png", 0.78)
	var m_reed_stalk := _mat("river_reed_stalk", Color(0.24, 0.44, 0.18), 0.86, 0.02)
	var m_reed_head := _mat("river_reed_head", Color(0.30, 0.18, 0.10), 0.92, 0.01)
	var m_old_bridge_stone := _mat("old_bridge_stone", Color(0.50, 0.49, 0.46), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/wall_stone.png", "town_textures/wall_stone_n.png", 0.72)
	var m_old_bridge_moss := _mat("old_bridge_moss_stone", Color(0.40, 0.45, 0.36), 0.90, 0.03, Color.BLACK, 0.0, "town_textures/wall_stone.png", "", 0.72)
	var m_old_bridge_planks := _mat("old_bridge_planks", Color(0.38, 0.26, 0.16), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "town_textures/rf_planks_n.png", 0.80)

	# 1. Sendero forestal que sube junto al arroyo hasta el Claro y el Molino Viejo
	var trail_pts: Array[Vector2] = [
		Vector2(138.0, -351.0), Vector2(126.0, -435.0), Vector2(218.0, -545.0),
		Vector2(118.0, -695.0), Vector2(114.0, -785.0), Vector2(138.0, -860.0),
		Vector2(142.0, -945.0), Vector2(168.0, -996.0), Vector2(188.0, -1014.0),
	]
	for ti in range(trail_pts.size() - 1):
		var pa: Vector2 = trail_pts[ti]
		var pb: Vector2 = trail_pts[ti + 1]
		_add_box_2d(terrain_root_3d, (pa + pb) * 0.5, Vector2(pa.distance_to(pb) + 3.0, 14.0), -0.25, 0.45, m_road, -rad_to_deg((pb - pa).angle()))

	# 2. Cinta continua 3D de agua del arroyo y del río (y = -1180..940) + riberas 3D orgánicas e irregulares
	var st_water := SurfaceTool.new()
	st_water.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_deep := SurfaceTool.new()
	st_deep.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_banks := SurfaceTool.new()
	st_banks.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_wet_mud := SurfaceTool.new()
	st_wet_mud.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_brown_mud := SurfaceTool.new()
	st_brown_mud.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_red_clay := SurfaceTool.new()
	st_red_clay.begin(Mesh.PRIMITIVE_TRIANGLES)

	var step_y: float = 6.0
	var y_cur: float = FishingSpotScript.river_y_start()
	var y_end_riv: float = FishingSpotScript.river_y_end()
	while y_cur < y_end_riv - 0.01:
		var y_nxt: float = minf(y_end_riv, y_cur + step_y)
		var b0: Vector2 = FishingSpotScript.river_banks_at(y_cur)
		var b1: Vector2 = FishingSpotScript.river_banks_at(y_nxt)
		var h0: float = _river_bank_terrace_height_px(y_cur) + 0.34
		var h1: float = _river_bank_terrace_height_px(y_nxt) + 0.34
		var wl0: Vector3 = to_3d_flat(Vector2(b0.x - 1.5, y_cur), h0)
		var wr0: Vector3 = to_3d_flat(Vector2(b0.y + 1.5, y_cur), h0)
		var wl1: Vector3 = to_3d_flat(Vector2(b1.x - 1.5, y_nxt), h1)
		var wr1: Vector3 = to_3d_flat(Vector2(b1.y + 1.5, y_nxt), h1)
		st_water.set_normal(Vector3.UP)
		st_water.add_vertex(wl0); st_water.add_vertex(wr0); st_water.add_vertex(wr1)
		st_water.add_vertex(wl0); st_water.add_vertex(wr1); st_water.add_vertex(wl1)

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

		# Orillas naturales 3D con barro húmedo en el borde del agua, lenguas de lodo irregulares, barro rojo en el molino y barro pardo en el claro
		var town_mud_boost0: float = lerpf(1.0, 1.95, smoothstep(-520.0, -180.0, y_cur) * (1.0 - smoothstep(260.0, 390.0, y_cur)))
		var town_mud_boost1: float = lerpf(1.0, 1.95, smoothstep(-520.0, -180.0, y_nxt) * (1.0 - smoothstep(260.0, 390.0, y_nxt)))
		var w_pad_l0: float = (7.2 + sin(y_cur * 0.057 + 0.3) * 3.4 + cos(y_cur * 0.119 - 0.8) * 2.1) * town_mud_boost0
		var w_pad_l1: float = (7.2 + sin(y_nxt * 0.057 + 0.3) * 3.4 + cos(y_nxt * 0.119 - 0.8) * 2.1) * town_mud_boost1
		var w_pad_r0: float = (7.2 + cos(y_cur * 0.051 - 0.5) * 3.4 + sin(y_cur * 0.113 + 1.1) * 2.1) * town_mud_boost0
		var w_pad_r1: float = (7.2 + cos(y_nxt * 0.051 - 0.5) * 3.4 + sin(y_nxt * 0.113 + 1.1) * 2.1) * town_mud_boost1
		var in_mill_zone: bool = (y_cur >= -1140.0 and y_cur <= -978.0)
		var in_clearing_zone: bool = (y_cur >= -910.0 and y_cur <= -812.0)
		if in_mill_zone:
			w_pad_l0 = 13.0 + sin(y_cur * 0.08) * 3.5
			w_pad_l1 = 13.0 + sin(y_nxt * 0.08) * 3.5
			var mill_r_reach0: float = 46.0 if y_cur > -1012.0 else 12.0
			var mill_r_reach1: float = 46.0 if y_nxt > -1012.0 else 12.0
			w_pad_r0 = mill_r_reach0 + cos(y_cur * 0.07) * 3.8
			w_pad_r1 = mill_r_reach1 + cos(y_nxt * 0.07) * 3.8
		elif in_clearing_zone:
			w_pad_r0 = 30.0 + sin((y_cur + 860.0) * 0.06) * 5.0
			w_pad_r1 = 30.0 + sin((y_nxt + 860.0) * 0.06) * 5.0

		var st_left_target: SurfaceTool = st_red_clay if in_mill_zone else st_banks
		var st_right_target: SurfaceTool = st_red_clay if in_mill_zone else (st_brown_mud if in_clearing_zone else st_banks)

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

		# Franja de barro oscuro y húmedo (y bajíos de lodo en las curvas) junto a la lámina de agua fuera del molino y del claro
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

		y_cur = y_nxt

	for pair_m in [
		[st_banks, m_bank_earth],
		[st_wet_mud, m_wet_mud],
		[st_brown_mud, m_brown_mud],
		[st_red_clay, m_red_clay],
		[st_water, m_riv_water],
		[st_deep, m_riv_deep],
	]:
		var mi_s := MeshInstance3D.new()
		mi_s.mesh = (pair_m[0] as SurfaceTool).commit()
		mi_s.material_override = pair_m[1]
		mi_s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		terrain_root_3d.add_child(mi_s)

	# 5. Piedras ribereñas, cantos rodados en la orilla y matas densas de juncos y espadañas a lo largo de ambas riberas
	var bank_i: int = 0
	var by_sample: float = -1150.0
	while by_sample <= 915.0:
		bank_i += 1
		var in_town_reach: bool = (by_sample >= -340.0 and by_sample <= 355.0)
		var b_s: Vector2 = FishingSpotScript.river_banks_at(by_sample)
		var near_cross: bool = FishingSpotScript.is_in_river_crossing(Vector2((b_s.x + b_s.y) * 0.5, by_sample), 14.0)
		var near_dock: bool = absf(by_sample - 188.0) < 20.0
		var near_wheel: bool = absf(by_sample - (-1060.0)) < 28.0
		var h_bank_s: float = _river_bank_terrace_height_px(by_sample)
		if not near_cross and not near_dock:
			var side_l := Vector2(b_s.x - 1.8 + sin(float(bank_i) * 1.9) * 2.6, by_sample)
			var side_r := Vector2(b_s.y + 1.8 + cos(float(bank_i) * 1.7) * 2.6, by_sample + 5.0)
			if (bank_i % 2) == 0:
				_add_model_2d(terrain_root_3d, "nature/Rock_1.obj" if (bank_i % 4) == 0 else "nature/Rock_2.obj", side_l, 0.15, Vector2.ZERO, 6.8 if in_town_reach else 5.8, float(bank_i * 47))
				# Cantos rodados adicionales semihundidos en el barro de la orilla izquierda
				_add_box_2d(terrain_root_3d, side_l + Vector2(2.6, 2.2), Vector2(3.6, 2.8), h_bank_s + 0.05, 1.4, m_old_bridge_moss, float(bank_i * 29), true)
			else:
				_add_model_2d(terrain_root_3d, "nature/Plant_1.obj" if (bank_i % 3) == 0 else "nature/Plant_3.obj", side_l, 0.15, Vector2.ZERO, 7.2 if in_town_reach else 6.2, float(bank_i * 31))
			# Matas de juncos altos y espadañas (cattails) en las curvas húmedas
			if in_town_reach or (bank_i % 2) == 1:
				for r_idx in range(3):
					var r_off := Vector2(float(r_idx - 1) * 1.6 + sin(float(bank_i + r_idx)) * 0.9, float(r_idx) * 1.5 - 1.2)
					var reed_h: float = 5.4 + float((bank_i + r_idx) % 3) * 1.3
					_add_cyl_2d(terrain_root_3d, side_l + r_off, 0.34, 0.1, reed_h, m_reed_stalk, 0.24, 6)
					if (r_idx % 2) == 0:
						_add_cyl_2d(terrain_root_3d, side_l + r_off, 0.58, reed_h - 1.4, 1.3, m_reed_head, 0.52, 6)

			if not near_wheel and absf(by_sample - (-860.0)) > 24.0:
				if (bank_i % 3) == 0:
					_add_model_2d(terrain_root_3d, "nature/Rock_2.obj" if (bank_i % 2) == 0 else "nature/Rock_1.obj", side_r, 0.15, Vector2.ZERO, 6.6 if in_town_reach else 5.6, float(bank_i * 59))
					_add_box_2d(terrain_root_3d, side_r + Vector2(-2.4, -2.0), Vector2(3.4, 2.6), h_bank_s + 0.05, 1.3, m_old_bridge_stone, float(bank_i * 37), true)
				else:
					_add_model_2d(terrain_root_3d, "nature/Plant_3.obj" if (bank_i % 2) == 0 else "nature/Plant_1.obj", side_r, 0.15, Vector2.ZERO, 7.0 if in_town_reach else 6.0, float(bank_i * 41))
				if in_town_reach or (bank_i % 2) == 0:
					for r_idx2 in range(3):
						var r_off2 := Vector2(float(r_idx2 - 1) * 1.5 - cos(float(bank_i + r_idx2)) * 0.9, float(r_idx2) * 1.5 - 1.2)
						var reed_h2: float = 5.2 + float((bank_i + r_idx2) % 3) * 1.3
						_add_cyl_2d(terrain_root_3d, side_r + r_off2, 0.34, 0.1, reed_h2, m_reed_stalk, 0.24, 6)
						if (r_idx2 % 2) == 1:
							_add_cyl_2d(terrain_root_3d, side_r + r_off2, 0.58, reed_h2 - 1.4, 1.3, m_reed_head, 0.52, 6)
		by_sample += 15.0 if in_town_reach else 26.0

	# 5b. Lenguas de barro, bancos de grava y salientes asimétricos en los meandros del pueblo (y = -310..335)
	for spit_def in [
		[ -275.0, false, 14.0, 26.0, 12.0],
		[ -215.0, true,  15.0, 28.0, -14.0],
		[ -145.0, false, 16.0, 30.0, 15.0],
		[  -65.0, true,  14.0, 26.0, -11.0],
		[  105.0, false, 15.0, 26.0, 14.0],
		[  168.0, true,  16.0, 30.0, -16.0],
		[  238.0, false, 14.0, 26.0, 12.0],
		[  305.0, true,  15.0, 28.0, -13.0],
	]:
		var sy: float = float(spit_def[0])
		var on_left: bool = bool(spit_def[1])
		var sw: float = float(spit_def[2])
		var sl: float = float(spit_def[3])
		var srot: float = float(spit_def[4])
		var sbanks: Vector2 = FishingSpotScript.river_banks_at(sy)
		var sx: float = (sbanks.x + sw * 0.32) if on_left else (sbanks.y - sw * 0.32)
		var sh: float = _river_bank_terrace_height_px(sy)
		_add_box_2d(terrain_root_3d, Vector2(sx, sy), Vector2(sw, sl), sh - 1.5, 1.35, m_wet_mud, srot, true)
		_add_box_2d(terrain_root_3d, Vector2(sx + (2.0 if on_left else -2.0), sy), Vector2(sw * 0.65, sl * 0.65), sh - 1.1, 1.1, m_bank_earth, srot * 0.7, true)
		_add_model_2d(terrain_root_3d, "nature/Rock_2.obj", Vector2(sx + (3.2 if on_left else -3.2), sy - 3.0), 0.05, Vector2.ZERO, 6.8, srot * 3.0)
		_add_model_2d(terrain_root_3d, "nature/Plant_3.obj", Vector2(sx, sy + 4.0), 0.10, Vector2.ZERO, 7.4, srot * 2.0)

	# 6. Bosque denso y oscuro del norte flanqueando el arroyo, el Claro del Caso I y el Molino Viejo Abandonado
	# Suelo de humus oscuro, pinocha y musgo sombrío bajo la espesura + penumbra de copas para que el claro se sienta escondido
	var m_forest_humus := _mat("north_forest_humus", Color(0.14, 0.17, 0.10), 0.96, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.78)
	var m_forest_moss := _mat("north_forest_moss", Color(0.12, 0.21, 0.11), 0.95, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.74)
	var m_dark_canopy := _mat("north_dark_canopy", Color(0.07, 0.17, 0.09), 0.94, 0.0)
	var m_dark_canopy_top := _mat("north_dark_canopy_top", Color(0.10, 0.22, 0.12), 0.92, 0.0)
	var m_rotten_log := _mat("north_rotten_log", Color(0.22, 0.15, 0.10), 0.94, 0.0, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.82)
	for humus_patch in [
		[Vector2(28.0, -860.0), Vector2(96.0, 220.0), 6.0],
		[Vector2(-48.0, -920.0), Vector2(110.0, 290.0), -8.0],
		[Vector2(-118.0, -885.0), Vector2(95.0, 260.0), 11.0],
		[Vector2(34.0, -1045.0), Vector2(88.0, 190.0), -5.0],
		[Vector2(212.0, -855.0), Vector2(115.0, 210.0), -7.0],
		[Vector2(288.0, -915.0), Vector2(125.0, 280.0), 9.0],
		[Vector2(118.0, -760.0), Vector2(140.0, 74.0), 4.0],
		[Vector2(116.0, -942.0), Vector2(68.0, 66.0), -6.0],
	]:
		if vegetacion_en_escena:
			break # placas de tierra encima del suelo: en terreno irregular se veían como un «doble suelo» (usuario, 2026-11-10)
		_add_box_2d(terrain_root_3d, humus_patch[0] as Vector2, humus_patch[1] as Vector2, -0.32, 0.38, m_forest_humus, float(humus_patch[2]))
	for moss_patch in [
		[Vector2(54.0, -835.0), Vector2(36.0, 62.0), 14.0],
		[Vector2(50.0, -912.0), Vector2(38.0, 68.0), -12.0],
		[Vector2(174.0, -848.0), Vector2(44.0, 72.0), 9.0],
		[Vector2(168.0, -918.0), Vector2(42.0, 58.0), -15.0],
		[Vector2(116.0, -928.0), Vector2(32.0, 38.0), 18.0],
	]:
		if vegetacion_en_escena:
			break
		_add_box_2d(terrain_root_3d, moss_patch[0] as Vector2, moss_patch[1] as Vector2, -0.28, 0.36, m_forest_moss, float(moss_patch[2]))

	# Dosel alto de ramas entrelazadas que proyecta sombra real del sol sobre el arroyo y el claro (sin luces negativas que causen reflejos especulares en GLES3)
	for canopy_arch in [
		[Vector2(74.0, -848.0), 19.0, 22.0, 6.5],
		[Vector2(72.0, -892.0), 20.0, 23.0, 7.0],
		[Vector2(162.0, -852.0), 19.5, 22.0, 6.5],
		[Vector2(158.0, -896.0), 20.0, 23.0, 7.0],
		[Vector2(114.0, -935.0), 21.0, 24.0, 7.5],
		[Vector2(112.0, -782.0), 19.0, 22.0, 6.5],
	]:
		if vegetacion_en_escena:
			break # discos de copa flotando sobre el claro; la sombra la dan ya los árboles de la escena
		_add_cyl_2d(terrain_root_3d, canopy_arch[0] as Vector2, float(canopy_arch[1]), float(canopy_arch[2]), float(canopy_arch[3]), m_dark_canopy, float(canopy_arch[1]) * 0.65, 9)

	# Árboles densos con borde irregular (entrantes y salientes orgánicos, sin filas rectas) cerrando el horizonte y ocultando el molino desde el claro
	var north_forest_trees: Array[Vector2] = [
		# Ribera oeste inmediata del arroyo (x = 46..72): serpenteante y espesa
		Vector2(68.0, -722.0), Vector2(54.0, -746.0), Vector2(66.0, -768.0), Vector2(58.0, -792.0),
		Vector2(69.0, -814.0), Vector2(56.0, -836.0), Vector2(67.0, -858.0), Vector2(55.0, -878.0),
		Vector2(68.0, -898.0), Vector2(57.0, -918.0), Vector2(69.0, -938.0), Vector2(58.0, -962.0),
		Vector2(66.0, -986.0), Vector2(54.0, -1012.0), Vector2(65.0, -1038.0), Vector2(58.0, -1066.0),
		Vector2(67.0, -1094.0), Vector2(56.0, -1122.0), Vector2(68.0, -1148.0),
		# Segundo cinturón oeste (x = 12..44) con claros y salientes irregulares
		Vector2(38.0, -692.0), Vector2(22.0, -718.0), Vector2(42.0, -738.0), Vector2(16.0, -762.0),
		Vector2(34.0, -784.0), Vector2(19.0, -808.0), Vector2(39.0, -828.0), Vector2(14.0, -852.0),
		Vector2(36.0, -872.0), Vector2(21.0, -894.0), Vector2(41.0, -914.0), Vector2(15.0, -938.0),
		Vector2(33.0, -960.0), Vector2(18.0, -986.0), Vector2(38.0, -1010.0), Vector2(16.0, -1036.0),
		Vector2(35.0, -1064.0), Vector2(20.0, -1092.0), Vector2(38.0, -1120.0), Vector2(24.0, -1150.0),
		# Tercer y cuarto cinturón profundo al oeste (x = -165..8) para tapar por completo el horizonte izquierdo
		Vector2(-8.0, -708.0), Vector2(-28.0, -736.0), Vector2(-12.0, -768.0), Vector2(-36.0, -796.0),
		Vector2(-16.0, -824.0), Vector2(-38.0, -850.0), Vector2(-14.0, -878.0), Vector2(-34.0, -906.0),
		Vector2(-18.0, -934.0), Vector2(-42.0, -964.0), Vector2(-20.0, -994.0), Vector2(-36.0, -1026.0),
		Vector2(-16.0, -1058.0), Vector2(-38.0, -1090.0), Vector2(-18.0, -1124.0),
		Vector2(-58.0, -748.0), Vector2(-74.0, -782.0), Vector2(-54.0, -816.0), Vector2(-78.0, -848.0),
		Vector2(-60.0, -882.0), Vector2(-82.0, -916.0), Vector2(-58.0, -950.0), Vector2(-76.0, -986.0),
		Vector2(-62.0, -1024.0), Vector2(-84.0, -1064.0), Vector2(-64.0, -1108.0),
		Vector2(-108.0, -790.0), Vector2(-124.0, -835.0), Vector2(-104.0, -878.0), Vector2(-128.0, -922.0),
		Vector2(-112.0, -968.0), Vector2(-134.0, -1015.0), Vector2(-116.0, -1068.0),
		Vector2(-156.0, -855.0), Vector2(-168.0, -910.0), Vector2(-152.0, -965.0),
		# Estrangulamiento forestal al norte del claro (y = -975..-918) entre el claro y el molino para que el claro quede escondido
		Vector2(76.0, -922.0), Vector2(74.0, -946.0), Vector2(124.0, -942.0), Vector2(128.0, -968.0),
		Vector2(162.0, -912.0), Vector2(168.0, -930.0), Vector2(160.0, -948.0), Vector2(174.0, -966.0),
		# Borde sur irregular del claro (y = -818..-705) dejando solo el angosto sendero (x ~ 114..136)
		Vector2(94.0, -735.0), Vector2(98.0, -764.0), Vector2(94.0, -792.0), Vector2(96.0, -814.0),
		Vector2(138.0, -718.0), Vector2(148.0, -744.0), Vector2(136.0, -768.0), Vector2(152.0, -792.0),
		Vector2(162.0, -814.0),
		# Cinturón este del claro (x = 166..238): curvo y cerrado
		Vector2(172.0, -732.0), Vector2(186.0, -758.0), Vector2(174.0, -782.0), Vector2(188.0, -806.0),
		Vector2(174.0, -828.0), Vector2(184.0, -848.0), Vector2(176.0, -868.0), Vector2(186.0, -888.0),
		Vector2(174.0, -908.0), Vector2(188.0, -932.0), Vector2(182.0, -956.0), Vector2(196.0, -980.0),
		Vector2(204.0, -748.0), Vector2(218.0, -776.0), Vector2(202.0, -804.0), Vector2(222.0, -830.0),
		Vector2(206.0, -856.0), Vector2(224.0, -882.0), Vector2(208.0, -908.0), Vector2(226.0, -936.0),
		Vector2(212.0, -964.0), Vector2(232.0, -988.0),
		# Cinturón profundo al este (x = 242..365) para tapar por completo el horizonte derecho
		Vector2(246.0, -765.0), Vector2(262.0, -798.0), Vector2(244.0, -832.0), Vector2(266.0, -864.0),
		Vector2(248.0, -896.0), Vector2(268.0, -928.0), Vector2(254.0, -962.0), Vector2(272.0, -996.0),
		Vector2(264.0, -1032.0), Vector2(276.0, -1068.0), Vector2(266.0, -1104.0), Vector2(274.0, -1138.0),
		Vector2(292.0, -812.0), Vector2(308.0, -848.0), Vector2(288.0, -884.0), Vector2(312.0, -920.0),
		Vector2(296.0, -958.0), Vector2(316.0, -998.0), Vector2(302.0, -1042.0), Vector2(314.0, -1088.0),
		Vector2(336.0, -855.0), Vector2(352.0, -905.0), Vector2(338.0, -955.0), Vector2(354.0, -1010.0),
		# Cierre norte detrás del molino (y = -1135..-1175)
		Vector2(146.0, -1138.0), Vector2(174.0, -1146.0), Vector2(204.0, -1142.0), Vector2(234.0, -1148.0),
		Vector2(92.0, -1152.0), Vector2(122.0, -1160.0), Vector2(160.0, -1166.0), Vector2(218.0, -1164.0),
	]
	var dark_forest_models: Array[String] = [
		"nature/PineTree_1.obj", "nature/PineTree_2.obj", "nature/PineTree_3.obj", "nature/PineTree_4.obj",
		"nature/CommonTree_3.obj", "nature/PineTree_1.obj", "nature/Willow_1.obj", "nature/CommonTree_4.obj",
		"nature/PineTree_2.obj", "nature/PineTree_3.obj", "nature/Willow_2.obj", "nature/PineTree_4.obj",
	]
	for nti in range(north_forest_trees.size()):
		var t_pos: Vector2 = north_forest_trees[nti]
		var scale_f: float = 1.05 + float(nti % 5) * 0.13
		var m_file: String = dark_forest_models[nti % dark_forest_models.size()]
		_add_model_2d(terrain_root_3d, m_file, t_pos, -0.3, Vector2.ZERO, 38.0 * scale_f, float(nti * 53))
		# Copas bajas suplementarias de pino oscuro cada 2 árboles para cerrar huecos de visión a media altura
		if (nti % 2) == 0 and not vegetacion_en_escena: # con los árboles en la escena del editor, este relleno quedaría suelto
			_add_cyl_2d(terrain_root_3d, t_pos, 13.5 * scale_f, 5.5, 14.0 * scale_f, m_dark_canopy, 2.5 * scale_f, 8)
			_add_cyl_2d(terrain_root_3d, t_pos, 9.5 * scale_f, 13.5, 11.0 * scale_f, m_dark_canopy_top, 1.2 * scale_f, 8)

	# Sotobosque denso (arbustos, zarzas con bayas, helechos, troncos caídos musgosos y peñascos) rodeando el arroyo y el claro
	var undergrowth_bushes: Array[Vector2] = [
		Vector2(70.0, -755.0), Vector2(64.0, -778.0), Vector2(71.0, -802.0), Vector2(62.0, -824.0),
		Vector2(69.0, -846.0), Vector2(61.0, -868.0), Vector2(70.0, -888.0), Vector2(63.0, -908.0),
		Vector2(71.0, -928.0), Vector2(62.0, -948.0), Vector2(70.0, -972.0), Vector2(60.0, -996.0),
		Vector2(44.0, -798.0), Vector2(46.0, -842.0), Vector2(42.0, -884.0), Vector2(45.0, -926.0),
		Vector2(28.0, -818.0), Vector2(26.0, -864.0), Vector2(30.0, -906.0), Vector2(24.0, -948.0),
		Vector2(98.0, -748.0), Vector2(95.0, -778.0), Vector2(98.0, -806.0),
		Vector2(138.0, -756.0), Vector2(146.0, -780.0), Vector2(156.0, -804.0), Vector2(166.0, -822.0),
		Vector2(170.0, -838.0), Vector2(168.0, -856.0), Vector2(170.0, -874.0), Vector2(166.0, -892.0),
		Vector2(162.0, -908.0), Vector2(158.0, -924.0), Vector2(160.0, -940.0), Vector2(164.0, -956.0),
		Vector2(124.0, -936.0), Vector2(126.0, -954.0), Vector2(130.0, -970.0),
		Vector2(182.0, -818.0), Vector2(186.0, -862.0), Vector2(180.0, -902.0), Vector2(192.0, -942.0),
		Vector2(204.0, -840.0), Vector2(210.0, -886.0), Vector2(202.0, -924.0),
	]
	var bush_models: Array[String] = [
		"nature/Bush_1.obj", "nature/Bush_2.obj", "nature/BushBerries_1.obj", "nature/BushBerries_2.obj"
	]
	for ubi in range(undergrowth_bushes.size()):
		var b_pos: Vector2 = undergrowth_bushes[ubi]
		var b_scale: float = 8.5 + float(ubi % 4) * 1.8
		_add_model_2d(terrain_root_3d, bush_models[ubi % bush_models.size()], b_pos, -0.2, Vector2.ZERO, b_scale, float(ubi * 41))
		# Helechos y matas bajas junto a cada arbusto
		var f_off := Vector2(cos(float(ubi) * 1.7) * 4.5, sin(float(ubi) * 2.3) * 4.5)
		var ferns := ["nature/Plant_2.obj", "nature/Plant_3.obj", "nature/Plant_4.obj", "nature/Plant_5.obj"]
		_add_model_2d(terrain_root_3d, ferns[ubi % ferns.size()], b_pos + f_off, -0.15, Vector2.ZERO, 7.2 + float(ubi % 3) * 1.3, float(ubi * 67))
		if ubi % 3 == 0:
			_add_model_2d(terrain_root_3d, "nature/Grass_2.obj", b_pos - f_off * 1.3, -0.1, Vector2.ZERO, 4.5, float(ubi * 29))

	# Troncos caídos cubiertos de musgo y peñascos forestales en los bordes del claro y del arroyo
	for fallen_log in [
		[Vector2(62.0, -842.0), 32.0],
		[Vector2(56.0, -892.0), -24.0],
		[Vector2(170.0, -846.0), -38.0],
		[Vector2(166.0, -896.0), 28.0],
		[Vector2(162.0, -932.0), 14.0],
		[Vector2(95.0, -798.0), -18.0],
		[Vector2(154.0, -796.0), 42.0],
		[Vector2(38.0, -868.0), -12.0],
	]:
		var l_pos: Vector2 = fallen_log[0] as Vector2
		var l_rot: float = float(fallen_log[1])
		_add_box_2d(terrain_root_3d, l_pos, Vector2(14.0, 3.0), 0.0, 2.6, m_rotten_log, l_rot)
		_colision_solida(l_pos, Vector2(14.0, 4.0), l_rot, false)
		_add_box_2d(terrain_root_3d, l_pos + Vector2(0.0, -0.4), Vector2(10.0, 2.2), 2.3, 0.6, m_forest_moss, l_rot)
	for forest_rock in [
		[Vector2(68.0, -830.0), "nature/Rock_3.obj", 7.8, 20.0],
		[Vector2(66.0, -882.0), "nature/Rock_4.obj", 8.5, 85.0],
		[Vector2(168.0, -832.0), "nature/Rock_5.obj", 8.2, 140.0],
		[Vector2(166.0, -884.0), "nature/Rock_3.obj", 7.8, 210.0],
		[Vector2(124.0, -930.0), "nature/Rock_4.obj", 7.4, 55.0],
	]:
		_add_model_2d(terrain_root_3d, str(forest_rock[1]), forest_rock[0] as Vector2, -0.15, Vector2.ZERO, float(forest_rock[2]), float(forest_rock[3]))

	# 7. PUENTE VIEJO DE PIEDRA Y MADERA en el centro del pueblo (`OLD_BRIDGE_POS`, Calle Mayor)
	var ob_pos := FishingSpotScript.OLD_BRIDGE_POS
	var ob_banks: Vector2 = FishingSpotScript.river_banks_at(ob_pos.y)
	var ob_cx: float = (ob_banks.x + ob_banks.y) * 0.5
	var ob_span: float = (ob_banks.y - ob_banks.x) + 18.0
	var ob_w_y: float = 36.0
	var ob_base_h: float = _river_bank_terrace_height_px(ob_pos.y)
	# Estribos de piedra vieja en ambas orillas y dos pilares con tajamar en el cauce ancho
	_add_box_2d(terrain_root_3d, Vector2(ob_banks.x - 3.0, ob_pos.y), Vector2(10.0, ob_w_y + 4.0), ob_base_h - 3.2, 4.6, m_old_bridge_stone, 0.0, true)
	_add_box_2d(terrain_root_3d, Vector2(ob_banks.y + 3.0, ob_pos.y), Vector2(10.0, ob_w_y + 4.0), ob_base_h - 3.2, 4.6, m_old_bridge_stone, 0.0, true)
	for pier_t in [0.34, 0.66]:
		var pier_x: float = lerpf(ob_banks.x, ob_banks.y, pier_t)
		_add_box_2d(terrain_root_3d, Vector2(pier_x, ob_pos.y), Vector2(6.8, ob_w_y + 6.0), ob_base_h - 3.4, 4.4, m_old_bridge_moss, 0.0, true)
	# Arcos rebajados de piedra bajo las vigas del puente
	for arch_t in [0.17, 0.50, 0.83]:
		var arch_x: float = lerpf(ob_banks.x, ob_banks.y, arch_t)
		_add_box_2d(terrain_root_3d, Vector2(arch_x, ob_pos.y - ob_w_y * 0.5 + 1.5), Vector2(ob_span * 0.26, 3.0), ob_base_h - 0.2, 1.6, m_old_bridge_stone, 0.0, true)
		_add_box_2d(terrain_root_3d, Vector2(arch_x, ob_pos.y + ob_w_y * 0.5 - 1.5), Vector2(ob_span * 0.26, 3.0), ob_base_h - 0.2, 1.6, m_old_bridge_stone, 0.0, true)
	# Rampas de empedrado viejo en los accesos oeste y este y tablero de tablones gruesos de madera gastada
	_add_box_2d(terrain_root_3d, Vector2(ob_cx - ob_span * 0.5 - 4.0, ob_pos.y), Vector2(10.0, ob_w_y - 2.0), ob_base_h + 0.1, 0.9, m_old_bridge_stone, 0.0, true)
	_add_box_2d(terrain_root_3d, Vector2(ob_cx + ob_span * 0.5 + 4.0, ob_pos.y), Vector2(10.0, ob_w_y - 2.0), ob_base_h + 0.1, 0.9, m_old_bridge_stone, 0.0, true)
	_add_box_2d(terrain_root_3d, Vector2(ob_cx, ob_pos.y), Vector2(ob_span, ob_w_y - 2.0), ob_base_h + 0.8, 0.9, m_old_bridge_planks, 0.0, true)
	# Traviesas de madera vista sobre el tablero del Puente Viejo
	var plank_x: float = ob_cx - ob_span * 0.5 + 3.0
	while plank_x <= ob_cx + ob_span * 0.5 - 3.0:
		_add_box_2d(terrain_root_3d, Vector2(plank_x, ob_pos.y), Vector2(2.6, ob_w_y - 3.0), ob_base_h + 1.68, 0.22, m_dark_wood, 0.0, true)
		plank_x += 4.5
	# Pretiles bajos de mampostería de piedra y barandales de madera vieja a norte y sur del Puente Viejo
	for side_s in [-1.0, 1.0]:
		var py_rail: float = ob_pos.y + side_s * (ob_w_y * 0.5 + 0.5)
		_add_box_2d(terrain_root_3d, Vector2(ob_cx, py_rail), Vector2(ob_span + 4.0, 3.6), ob_base_h + 0.8, 4.2, m_old_bridge_stone, 0.0, true)
		_add_box_2d(terrain_root_3d, Vector2(ob_cx, py_rail), Vector2(ob_span + 2.0, 2.2), ob_base_h + 6.8, 1.5, m_old_bridge_planks, 0.0, true)
		for post_t in [-0.47, -0.28, -0.09, 0.09, 0.28, 0.47]:
			var px_post: float = ob_cx + post_t * ob_span
			var is_end: bool = absf(post_t) > 0.40
			_add_box_2d(
				terrain_root_3d,
				Vector2(px_post, py_rail),
				Vector2(5.2 if is_end else 3.4, 5.2 if is_end else 3.8),
				ob_base_h + 0.8,
				8.6 if is_end else 6.8,
				m_old_bridge_moss if is_end else m_dark_wood,
				0.0,
				true
			)
	# Punto 6 (Caso I): El zapato izquierdo de la víctima caído junto al pretil norte del Puente Viejo (`Vector2(110, 38)`)
	var shoe_pos := Vector2(ob_cx - 10.0, ob_pos.y - 12.0)
	var m_shoe_leather := _mat("victim_left_shoe_leather", Color(0.24, 0.14, 0.09), 0.78, 0.05)
	var m_shoe_sole := _mat("victim_left_shoe_sole", Color(0.12, 0.08, 0.06), 0.92, 0.0)
	var m_shoe_buckle := _mat("victim_left_shoe_buckle", Color(0.76, 0.62, 0.28), 0.35, 0.75)
	var shoe_h: float = ob_base_h + 1.92
	# Suela, tacón bajo, empeine y caña del zapato izquierdo volcado de costado tras el forcejeo
	_add_box_2d(terrain_root_3d, shoe_pos, Vector2(4.6, 2.1), shoe_h, 0.42, m_shoe_sole, -24.0, true)
	_add_box_2d(terrain_root_3d, shoe_pos + Vector2(-1.4, -0.6), Vector2(1.5, 2.0), shoe_h - 0.15, 0.75, m_shoe_sole, -24.0, true)
	var shoe_upper := _add_box_2d(terrain_root_3d, shoe_pos + Vector2(0.3, 0.1), Vector2(4.2, 1.9), shoe_h + 0.38, 1.45, m_shoe_leather, -24.0, true)
	shoe_upper.rotation.x = 0.28
	_add_box_2d(terrain_root_3d, shoe_pos + Vector2(-1.0, 0.4), Vector2(2.1, 1.8), shoe_h + 1.35, 1.35, m_shoe_leather, -24.0, true)
	_add_box_2d(terrain_root_3d, shoe_pos + Vector2(0.2, 0.9), Vector2(0.85, 0.55), shoe_h + 1.15, 0.55, m_shoe_buckle, -24.0, true)

	# 8. Puentes secundarios (Calle Norte en y = -351 y Senda de los Campos del Sur en y = 372) y vados de piedra
	for cr in FishingSpotScript.river_crossings():
		var cid: String = String(cr["id"])
		if cid == "old_bridge":
			continue
		var cpos: Vector2 = cr["pos"]
		var chy: float = float(cr["half_y"])
		var cb: Vector2 = FishingSpotScript.river_banks_at(cpos.y)
		var ccx: float = (cb.x + cb.y) * 0.5
		var cspan: float = (cb.y - cb.x) + 16.0
		var cbase: float = _river_bank_terrace_height_px(cpos.y)
		if String(cr.get("kind", "")) == "log":
			# Tronco caído de orilla a orilla: puente natural (el modelo es largo en su eje norte-sur; se gira 90°)
			# Se escala por el grosor (proporciones reales) y luego solo se alarga hasta apoyar en las dos orillas
			var grosor_px: float = 8.0
			_permitir_en_rio = true
			var lg: Node3D = _add_model_2d(terrain_root_3d, "nature/WoodLog.obj", Vector2(ccx, cpos.y), 0.0, Vector2.ZERO, grosor_px, 90.0)
			_permitir_en_rio = false
			if lg != null:
				var largo_modelo: float = ((grosor_px * WORLD_SCALE) / _cos_p) * (2.67 / 0.75) # WoodLog.obj: largo 2.67, alto 0.75
				lg.scale.z *= ((cspan + 10.0) * WORLD_SCALE) / maxf(0.01, largo_modelo)
				lg.position = to_3d_flat(Vector2(ccx, cpos.y), cbase - 3.0)
			continue
		if cid == "bridge_north" or cid == "south_fields_bridge":
			var bw_y: float = chy * 2.0
			_add_box_2d(terrain_root_3d, Vector2(cb.x - 2.0, cpos.y), Vector2(7.0, bw_y + 2.0), cbase - 2.8, 3.6, m_old_bridge_stone, 0.0, true)
			_add_box_2d(terrain_root_3d, Vector2(cb.y + 2.0, cpos.y), Vector2(7.0, bw_y + 2.0), cbase - 2.8, 3.6, m_old_bridge_stone, 0.0, true)
			_add_box_2d(terrain_root_3d, Vector2(ccx, cpos.y), Vector2(cspan, bw_y), cbase + 0.4, 0.8, m_old_bridge_planks, 0.0, true)
			for s_r in [-1.0, 1.0]:
				var ry_b: float = cpos.y + s_r * (chy + 0.4)
				_add_box_2d(terrain_root_3d, Vector2(ccx, ry_b), Vector2(cspan, 1.8), cbase + 4.8, 1.2, m_dark_wood, 0.0, true)
				for pt_b in [-0.42, 0.0, 0.42]:
					_add_box_2d(terrain_root_3d, Vector2(ccx + pt_b * cspan, ry_b), Vector2(2.4, 2.4), cbase + 0.4, 5.8, m_dark_wood, 0.0, true)
		else:
			# Vados de losas de piedra que cubren todo el cauce (Claro del Arroyo y Bosque del Sur)
			var fx: float = cb.x + 3.0
			var si_f: int = 0
			while fx <= cb.y - 2.0:
				var fy_off: float = float((si_f % 2) * 2 - 1) * 1.4
				_add_box_2d(terrain_root_3d, Vector2(fx, cpos.y + fy_off), Vector2(5.2, 8.5), cbase - 0.5, 0.88, m_old_bridge_stone, float((si_f % 3 - 1) * 9), true)
				fx += 6.2
				si_f += 1

	# 9. Tarima / Ribera de Pesca del Río en la orilla este dentro del pueblo (y = 188)
	var r_ebank: float = FishingSpotScript.river_banks_at(188.0).y
	var r_dock_pos := Vector2(r_ebank + 2.0, 188.0)
	var r_dock_base: float = _river_bank_terrace_height_px(r_dock_pos.y)
	_add_box_2d(terrain_root_3d, r_dock_pos - Vector2(4.0, 0.0), Vector2(18.0, 12.0), r_dock_base - 0.1, 1.1, m_old_bridge_planks, 0.0, true)
	for dpx in [-10.0, -2.0]:
		for dpy in [-5.0, 5.0]:
			_add_box_2d(terrain_root_3d, r_dock_pos + Vector2(dpx, dpy), Vector2(2.0, 2.0), r_dock_base - 2.6, 4.2, m_dark_wood, 0.0, true)

## Editor del mapa 3D (2026-11-10): mapa/Mundo3D.tscn. «Vegetacion» (árboles, rocas, plantas y troncos horneados del
## código, editables a mano) y «Decoracion» (lo que coloque el usuario) se meten en el terreno antes de juntarlo por zonas
## (rendimiento) y se hacen sólidos en el mapa 2D según su tipo de choque.
const ESCENA_MUNDO_3D := "res://mapa/Mundo3D.tscn"
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
	decorado_en_escena = not grabar_decorado and dec != null and dec.get_child_count() > 0


## Separa el decorado del terreno: suelo, agua y orillas (mallas hechas por código) se quedan; lo demás o se graba para la
## escena (tools/hornear_decorado.gd) o se quita porque ya viene de la escena.
func _separar_decorado() -> void:
	if terrain_root_3d == null or not (grabar_decorado or decorado_en_escena):
		return
	var cand: Array = []
	for c in terrain_root_3d.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is ArrayMesh:
			continue
		cand.append(c)
	if grabar_decorado:
		# Se apartan del terreno para que no se junten por zonas (eso les quita la malla) antes de guardarlos
		var aparte := Node3D.new()
		aparte.name = "DecoradoGrabado"
		terrain_root_3d.get_parent().add_child(aparte)
		aparte.transform = terrain_root_3d.transform
		for c in cand:
			terrain_root_3d.remove_child(c)
			aparte.add_child(c)
		decorado_grabado = cand
		return
	for c in cand:
		terrain_root_3d.remove_child(c)
		c.free()


func _cargar_decoracion_editor() -> void:
	if _mundo_editor == null or terrain_root_3d == null:
		return
	var dec: Node = _mundo_editor.get_node_or_null("Decorado")
	if dec != null and decorado_en_escena:
		# Sin choques nuevos: los obstáculos del decorado ya los pone el mapa 2D (se recolocarán con «la lógica»)
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


## Piezas = nodos 3D colocados (las carpetas de agrupar sin modelo propio se recorren por dentro).
func _juntar_piezas(n: Node, out: Array) -> void:
	for c in n.get_children():
		if not (c is Node3D):
			continue
		if c.has_method("tipo_choque") or c is VisualInstance3D or c.scene_file_path != "":
			out.append(c)
		else:
			_juntar_piezas(c, out)


func _choque_de_pieza(c: Node3D) -> void:
	if vm == null or not ("entities_root" in vm) or not is_instance_valid(vm.entities_root):
		return
	var tipo: String = String(c.call("tipo_choque")) if c.has_method("tipo_choque") else ("ninguno" if bool(c.get_meta("atravesable", false)) else "forma")
	if tipo == "ninguno":
		return
	var p2 := _a_mapa_2d(c.global_position)
	if tipo == "tronco":
		vm.call("_add_prop_collider", p2, Vector2(7.0, 7.0))
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


## Troncos y tocones del bosque sólidos en el mapa 2D (antes solo eran adorno 3D y se atravesaban).
## rot_3d_deg es el giro del modelo 3D; en el mapa 2D el giro equivalente va al revés.
func _colision_solida(pos_2d: Vector2, sz_2d: Vector2, rot_3d_deg: float, de_modelo: bool = true) -> void:
	if de_modelo and (grabar_vegetacion or vegetacion_en_escena):
		return # el choque sale de la pieza de la escena del editor 3D
	if vm == null or not vm.has_method("_add_prop_collider") or en_cauce_del_rio(pos_2d, 2.0):
		return
	var sb = vm.call("_add_prop_collider", pos_2d, sz_2d)
	if sb is Node2D:
		(sb as Node2D).rotation = -deg_to_rad(rot_3d_deg)


func _build_tree_3d(parent: Node3D, pos_2d: Vector2, m_trunk: Material, m_leaf1: Material, m_leaf2: Material, scale_f: float = 1.0, variant: int = 0) -> void:
	var tree_files := [
		"nature/CommonTree_1.obj", "nature/CommonTree_2.obj", "nature/BirchTree_1.obj",
		"nature/CommonTree_3.obj", "nature/BirchTree_2.obj", "nature/CommonTree_4.obj",
		"nature/PineTree_1.obj", "nature/BirchTree_3.obj",
	]
	var t_file: String = tree_files[posmod(variant, tree_files.size())]
	if es_vegetacion_en_rio(t_file, pos_2d):
		return
	if _add_model_2d(parent, t_file, pos_2d, 0.0, Vector2.ZERO, 36.0 * scale_f, float(variant * 67)) != null:
		return
	if _construyendo_estatico and (grabar_vegetacion or vegetacion_en_escena):
		return # el árbol está (o va a estar) en la escena del editor 3D
	_add_cyl_2d(parent, pos_2d, 3.2 * scale_f, 0.0, 11.0 * scale_f, m_trunk, 2.4 * scale_f, 8)
	_add_cyl_2d(parent, pos_2d, 12.0 * scale_f, 8.0 * scale_f, 14.0 * scale_f, m_leaf1, 2.0 * scale_f, 9)
	_add_cyl_2d(parent, pos_2d, 9.0 * scale_f, 16.0 * scale_f, 12.0 * scale_f, m_leaf2, 0.8 * scale_f, 9)

func _build_bench_3d(parent: Node3D, pos_2d: Vector2, m_wood: Material, m_iron: Material, rot_y: float = 0.0) -> void:
	var z_off: float = surface_elevation_offset_px(pos_2d)
	if _add_model_2d(parent, "props/Bench.gltf", pos_2d, z_off, Vector2(18.0, 7.0), 8.5, rot_y) != null:
		return
	_add_box_2d(parent, pos_2d, Vector2(18.0, 6.0), z_off + 2.5, 2.0, m_wood)
	_add_box_2d(parent, pos_2d + Vector2(0, -2.5), Vector2(18.0, 1.5), z_off + 4.5, 4.5, m_wood)
	_add_box_2d(parent, pos_2d + Vector2(-7, 0), Vector2(2.0, 6.0), z_off, 3.0, m_iron)
	_add_box_2d(parent, pos_2d + Vector2(7, 0), Vector2(2.0, 6.0), z_off, 3.0, m_iron)



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
			if mid_p.y >= FishingSpotScript.river_y_start() and mid_p.y <= FishingSpotScript.river_y_end() and absf(mid_p.x - FishingSpotScript.river_center_x(mid_p.y)) <= FishingSpotScript.river_half_width(mid_p.y) + 6.0:
				continue
			for p in [p00, p10, p11, p00, p11, p01]:
				st.set_normal(terrain_normal_3d(p, 12.0))
				st.add_vertex(to_3d(p, height_px))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	parent.add_child(mi)
	return mi
