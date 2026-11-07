class_name AssetLibrary3D
extends RefCounted

## Cargador y catálogo central de modelos 3D reales filtrados en `res://assests/curated_3d/`.
## Soporta `.gltf`, `.glb` (vía GLTFDocument en tiempo de ejecución) y `.obj`+`.mtl` con caché estática.

const CURATED_ROOT := "res://assests/curated_3d/"
const RETRO_MAX_TEX := 256

static var _gltf_cache: Dictionary = {} # rel_path -> Node3D template
static var _obj_cache: Dictionary = {}  # rel_path -> ArrayMesh
static var _aabb_cache: Dictionary = {} # rel_path -> AABB
static var _head_mesh_cache: Dictionary = {} # key -> ArrayMesh
static var _tex_cache: Dictionary = {}  # abs_or_res_path -> ImageTexture


static func has_curated_assets() -> bool:
	var probe := ProjectSettings.globalize_path(CURATED_ROOT + "characters/Male_Peasant.gltf")
	return FileAccess.file_exists(probe)


static func load_texture(rel_path: String) -> Texture2D:
	if _tex_cache.has(rel_path):
		return _tex_cache[rel_path]
	var full_res := rel_path if rel_path.begins_with("res://") else CURATED_ROOT + rel_path
	var abs_p := ProjectSettings.globalize_path(full_res)
	if not FileAccess.file_exists(abs_p):
		return null
	var img := Image.load_from_file(abs_p)
	if img == null or img.is_empty():
		return null
	# Estética retro (tipo PS1): las texturas grandes de los packs se reducen a 256 px como máximo,
	# y se dibujan con filtrado pixelado (ver `make_retro`). Así todo el valle comparte densidad de píxel.
	var max_dim := maxi(img.get_width(), img.get_height())
	# No se reducen: los personajes (sus atlas de UV sangrarían colores entre piezas) ni las paletas «colormap» de Kenney.
	var keep_full := rel_path.begins_with("characters/") or rel_path.find("colormap") != -1 or rel_path.find("_Normal") != -1
	if max_dim > RETRO_MAX_TEX and not keep_full:
		var f := float(RETRO_MAX_TEX) / float(max_dim)
		if img.is_compressed():
			img.decompress()
		img.resize(maxi(8, int(img.get_width() * f)), maxi(8, int(img.get_height() * f)), Image.INTERPOLATE_LANCZOS)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[rel_path] = tex
	return tex


static func load_gltf_template(rel_path: String) -> Node3D:
	if _gltf_cache.has(rel_path):
		var cached: Node3D = _gltf_cache[rel_path]
		if is_instance_valid(cached):
			return cached
	var full_res := rel_path if rel_path.begins_with("res://") else CURATED_ROOT + rel_path
	var abs_p := ProjectSettings.globalize_path(full_res)
	if not FileAccess.file_exists(abs_p):
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(abs_p, state)
	if err != OK:
		return null
	var scene: Node = doc.generate_scene(state)
	if not (scene is Node3D):
		return null
	var node3d := scene as Node3D
	_bind_known_pack_textures(rel_path, node3d)
	_gltf_cache[rel_path] = node3d
	_aabb_cache[rel_path] = compute_node_aabb(node3d)
	return node3d


static func _bind_known_pack_textures(rel_path: String, root: Node) -> void:
	if rel_path.begins_with("graveyard/"):
		var cmap := load_texture("graveyard/Textures/colormap.png")
		if cmap != null:
			_apply_pack_colormap(root, cmap, Color(0.60, 0.58, 0.55), 0.88)
	elif rel_path.begins_with("fantasy_town/"):
		var cmap2 := load_texture("fantasy_town/Textures/colormap.png")
		if cmap2 != null:
			_apply_pack_colormap(root, cmap2, Color(0.92, 0.90, 0.86), 0.84)
	elif rel_path.begins_with("props/"):
		_apply_props_megakit_textures(root)
	elif rel_path.begins_with("characters/"):
		_apply_character_megakit_textures(root)


static func _apply_pack_colormap(node: Node, tex: Texture2D, tint: Color, rough: float) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				var sm := StandardMaterial3D.new()
				sm.albedo_texture = tex
				sm.albedo_color = tint
				sm.roughness = rough
				sm.metallic = 0.04
				sm.cull_mode = BaseMaterial3D.CULL_DISABLED
				mi.mesh.surface_set_material(s, sm)
				mi.set_surface_override_material(s, sm)
	for c in node.get_children():
		_apply_pack_colormap(c, tex, tint, rough)


static func _apply_props_megakit_textures(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				var orig := mi.mesh.surface_get_material(s)
				var mname := orig.resource_name.to_lower() if orig != null else ""
				var base_rel := "props/T_Trim_Props_BaseColor.png"
				var norm_rel := "props/T_Trim_Props_Normal.png"
				var rough := 0.80
				var metal := 0.06
				if mname.find("furniture") != -1:
					base_rel = "props/T_Trim_Furniture_BaseColor.png"
					norm_rel = "props/T_Trim_Furniture_Normal.png"
					rough = 0.82
				elif mname.find("metal") != -1:
					base_rel = "props/T_Trim_Metal_BaseColor.png"
					norm_rel = "props/T_Trim_Metal_Normal.png"
					rough = 0.42
					metal = 0.58
				elif mname.find("cloth") != -1:
					base_rel = "props/T_Trim_Cloth_BaseColor.png"
					norm_rel = "props/T_Trim_Cloth_Normal.png"
					rough = 0.88
				elif mname.find("page") != -1:
					base_rel = "props/T_Page_Noise.png"
					norm_rel = ""
					rough = 0.90
				var btex := load_texture(base_rel)
				if btex != null:
					var sm := StandardMaterial3D.new()
					sm.resource_name = orig.resource_name if orig != null else "PropMat"
					sm.albedo_texture = btex
					sm.roughness = rough
					sm.metallic = metal
					sm.cull_mode = BaseMaterial3D.CULL_DISABLED
					if not norm_rel.is_empty():
						var ntex := load_texture(norm_rel)
						if ntex != null:
							sm.normal_enabled = true
							sm.normal_texture = ntex
							sm.normal_scale = 0.65
					mi.mesh.surface_set_material(s, sm)
					mi.set_surface_override_material(s, sm)
	for c in node.get_children():
		_apply_props_megakit_textures(c)


static func _apply_character_megakit_textures(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				var orig := mi.mesh.surface_get_material(s)
				var mname := orig.resource_name.to_lower() if orig != null else ""
				var base_rel := ""
				var norm_rel := ""
				if mname.find("peasant") != -1:
					base_rel = "characters/T_Peasant_BaseColor.png"
					norm_rel = "characters/T_Peasant_Normal.png"
				elif mname.find("ranger") != -1:
					base_rel = "characters/T_Ranger_BaseColor.png"
					norm_rel = "characters/T_Ranger_Normal.png"
				elif mname.find("hair_1") != -1:
					base_rel = "characters/T_Hair_1_BaseColor.png"
					norm_rel = "characters/T_Hair_1_Normal.png"
				elif mname.find("hair_2") != -1:
					base_rel = "characters/T_Hair_2_BaseColor.png"
					norm_rel = "characters/T_Hair_2_Normal.png"
				if not base_rel.is_empty():
					var btex := load_texture(base_rel)
					if btex != null:
						var sm := StandardMaterial3D.new()
						sm.resource_name = orig.resource_name if orig != null else "CharMat"
						sm.albedo_texture = btex
						sm.roughness = 0.82
						sm.cull_mode = BaseMaterial3D.CULL_DISABLED
						if not norm_rel.is_empty():
							var ntex := load_texture(norm_rel)
							if ntex != null:
								sm.normal_enabled = true
								sm.normal_texture = ntex
								sm.normal_scale = 0.60
						mi.mesh.surface_set_material(s, sm)
	for c in node.get_children():
		_apply_character_megakit_textures(c)


## Pasa todos los materiales de un modelo a la estética retro del juego:
## filtrado pixelado, sin mapas de relieve (normal maps), mates y con poco brillo metálico.
## Es idempotente: se puede llamar varias veces sobre el mismo árbol.
static func make_retro(node: Node) -> void:
	if node is GeometryInstance3D:
		var gi := node as GeometryInstance3D
		if gi.material_override is BaseMaterial3D:
			_retro_mat(gi.material_override as BaseMaterial3D)
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				var ov := mi.get_surface_override_material(s)
				if ov is BaseMaterial3D:
					_retro_mat(ov as BaseMaterial3D)
				var mm := mi.mesh.surface_get_material(s)
				if mm is BaseMaterial3D:
					_retro_mat(mm as BaseMaterial3D)
	for c in node.get_children():
		make_retro(c)


static func _retro_mat(m: BaseMaterial3D) -> void:
	if m.has_meta("retro_done"):
		return
	m.set_meta("retro_done", true)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.normal_enabled = false
	m.roughness = maxf(m.roughness, 0.78)
	m.metallic = minf(m.metallic, 0.35)
	m.metallic_specular = 0.25


static func load_obj_mesh(rel_path: String) -> ArrayMesh:
	if _obj_cache.has(rel_path):
		return _obj_cache[rel_path]
	var full_res := rel_path if rel_path.begins_with("res://") else CURATED_ROOT + rel_path
	var abs_obj := ProjectSettings.globalize_path(full_res)
	if not FileAccess.file_exists(abs_obj):
		return null
	var abs_mtl := abs_obj.get_basename() + ".mtl"
	var mats: Dictionary = _parse_mtl_file(abs_mtl)

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	# mat_name -> Array of [v_idx, vt_idx, vn_idx] triplets
	var groups: Dictionary = {}
	var current_mat := "default"

	var f := FileAccess.open(abs_obj, FileAccess.READ)
	if f == null:
		return null
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if line.begins_with("v "):
			var p := line.substr(2).strip_edges().split(" ", false)
			if p.size() >= 3:
				verts.append(Vector3(p[0].to_float(), p[1].to_float(), p[2].to_float()))
		elif line.begins_with("vn "):
			var p := line.substr(3).strip_edges().split(" ", false)
			if p.size() >= 3:
				norms.append(Vector3(p[0].to_float(), p[1].to_float(), p[2].to_float()))
		elif line.begins_with("vt "):
			var p := line.substr(3).strip_edges().split(" ", false)
			if p.size() >= 2:
				uvs.append(Vector2(p[0].to_float(), 1.0 - p[1].to_float()))
		elif line.begins_with("usemtl "):
			current_mat = line.substr(7).strip_edges()
			if current_mat.is_empty():
				current_mat = "default"
		elif line.begins_with("f "):
			var tokens := line.substr(2).strip_edges().split(" ", false)
			if tokens.size() < 3:
				continue
			if not groups.has(current_mat):
				groups[current_mat] = []
			var face_list: Array = groups[current_mat]
			var parsed_corners: Array = []
			for tok in tokens:
				var sub := tok.split("/")
				var vi := sub[0].to_int()
				vi = (vi - 1) if vi > 0 else (verts.size() + vi)
				var ti := -1
				if sub.size() > 1 and not sub[1].is_empty():
					ti = sub[1].to_int()
					ti = (ti - 1) if ti > 0 else (uvs.size() + ti)
				var ni := -1
				if sub.size() > 2 and not sub[2].is_empty():
					ni = sub[2].to_int()
					ni = (ni - 1) if ni > 0 else (norms.size() + ni)
				parsed_corners.append(Vector3i(vi, ti, ni))
			# Fan triangulation (OBJ usa orden antihorario CCW; Godot SurfaceTool espera horario CW)
			for i in range(1, parsed_corners.size() - 1):
				face_list.append(parsed_corners[0])
				face_list.append(parsed_corners[i + 1])
				face_list.append(parsed_corners[i])

	var mesh := ArrayMesh.new()
	for mat_name in groups.keys():
		var face_list: Array = groups[mat_name]
		if face_list.is_empty():
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var has_normals := false
		for corner in face_list:
			var c: Vector3i = corner
			if c.x < 0 or c.x >= verts.size():
				continue
			if c.y >= 0 and c.y < uvs.size():
				st.set_uv(uvs[c.y])
			if c.z >= 0 and c.z < norms.size():
				st.set_normal(norms[c.z])
				has_normals = true
			st.add_vertex(verts[c.x])
		if not has_normals:
			st.generate_normals()
		var mat: StandardMaterial3D = mats.get(mat_name, null)
		if mat == null:
			mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.68, 0.64, 0.58)
			mat.roughness = 0.85
		st.set_material(mat)
		st.commit(mesh)

	_obj_cache[rel_path] = mesh
	_aabb_cache[rel_path] = mesh.get_aabb()
	return mesh


static func _parse_mtl_file(abs_mtl: String) -> Dictionary:
	var result: Dictionary = {}
	if not FileAccess.file_exists(abs_mtl):
		return result
	var f := FileAccess.open(abs_mtl, FileAccess.READ)
	if f == null:
		return result
	var cur_name := ""
	var cur_mat: StandardMaterial3D = null
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if line.begins_with("newmtl "):
			cur_name = line.substr(7).strip_edges()
			cur_mat = StandardMaterial3D.new()
			cur_mat.resource_name = cur_name
			cur_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			cur_mat.roughness = 0.85
			cur_mat.metallic = 0.03
			var low := cur_name.to_lower()
			if low.find("steel") != -1 or low.find("metal") != -1 or low.find("iron") != -1 or low.find("gold") != -1 or low.find("bronze") != -1 or low.find("blade") != -1 or low.find("silver") != -1:
				cur_mat.metallic = 0.62
				cur_mat.roughness = 0.36
			elif low.find("glass") != -1 or low.find("water") != -1:
				cur_mat.roughness = 0.18
			result[cur_name] = cur_mat
		elif line.begins_with("Kd ") and cur_mat != null:
			var p := line.substr(3).strip_edges().split(" ", false)
			if p.size() >= 3:
				var lin := Color(p[0].to_float(), p[1].to_float(), p[2].to_float(), 1.0)
				var srgb := lin.linear_to_srgb()
				var low_m := cur_name.to_lower()
				if low_m == "wood":
					srgb = Color(0.40, 0.27, 0.16, 1.0)
				elif low_m == "darkwood":
					srgb = Color(0.28, 0.19, 0.11, 1.0)
				elif low_m == "green":
					srgb = Color(0.22, 0.48, 0.20, 1.0)
				elif low_m == "darkgreen":
					srgb = Color(0.15, 0.36, 0.15, 1.0)
				cur_mat.albedo_color = srgb
		elif line.begins_with("Ke ") and cur_mat != null:
			var p := line.substr(3).strip_edges().split(" ", false)
			if p.size() >= 3:
				var er := p[0].to_float()
				var eg := p[1].to_float()
				var eb := p[2].to_float()
				if er + eg + eb > 0.05:
					cur_mat.emission_enabled = true
					cur_mat.emission = Color(er, eg, eb).linear_to_srgb()
					cur_mat.emission_energy_multiplier = 1.6
	return result


static func compute_node_aabb(root: Node3D) -> AABB:
	var accum := AABB()
	var first := true
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh != null:
				var local_aabb := mi.mesh.get_aabb()
				var xform := _transform_relative_to(mi, root)
				var world_aabb := xform * local_aabb
				if first:
					accum = world_aabb
					first = false
				else:
					accum = accum.merge(world_aabb)
		for c in n.get_children():
			stack.append(c)
	if first:
		return AABB(Vector3(-0.5, 0.0, -0.5), Vector3(1.0, 1.0, 1.0))
	return accum


static func _transform_relative_to(node: Node3D, ancestor: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node3D = node
	while cur != null and cur != ancestor:
		xf = cur.transform * xf
		cur = cur.get_parent() as Node3D
	return xf


static func instantiate_model(
	rel_path: String,
	target_size: Vector3 = Vector3.ZERO,
	fit_height_only: float = -1.0,
	center_xz: bool = true,
	ground_y: bool = true,
	preserve_aspect: bool = true
) -> Node3D:
	var wrapper := Node3D.new()
	wrapper.name = rel_path.get_file().get_basename()
	var model_node: Node3D = null
	var aabb := AABB(Vector3(-0.5, 0.0, -0.5), Vector3(1.0, 1.0, 1.0))

	if rel_path.ends_with(".obj"):
		var mesh := load_obj_mesh(rel_path)
		if mesh == null:
			return null
		var mi := MeshInstance3D.new()
		mi.name = "Mesh"
		mi.mesh = mesh
		model_node = mi
		aabb = mesh.get_aabb()
	else:
		var tmpl := load_gltf_template(rel_path)
		if tmpl == null:
			return null
		model_node = tmpl.duplicate() as Node3D
		aabb = _aabb_cache.get(rel_path, compute_node_aabb(model_node))

	wrapper.add_child(model_node)
	var sz := aabb.size
	var scale_vec := Vector3.ONE
	if target_size != Vector3.ZERO:
		var sx := target_size.x / maxf(0.01, sz.x)
		var sy := target_size.y / maxf(0.01, sz.y)
		var sz_f := target_size.z / maxf(0.01, sz.z)
		if preserve_aspect:
			var u := minf(sy, maxf(sx, sz_f) * 1.15)
			scale_vec = Vector3(u, u, u)
		else:
			scale_vec = Vector3(sx, sy, sz_f)
	elif fit_height_only > 0.0:
		var max_dim := maxf(0.01, sz.y)
		var s := fit_height_only / max_dim
		scale_vec = Vector3(s, s, s)

	model_node.scale = scale_vec
	var offset := Vector3.ZERO
	if center_xz:
		offset.x = -(aabb.position.x + sz.x * 0.5) * scale_vec.x
		offset.z = -(aabb.position.z + sz.z * 0.5) * scale_vec.z
	if ground_y:
		offset.y = -aabb.position.y * scale_vec.y
	model_node.position = offset
	make_retro(wrapper)
	return wrapper


static func extract_head_only_mesh(key: String, full_mesh: Mesh, min_y: float = 1.44, max_abs_x: float = 0.135) -> ArrayMesh:
	var cache_key := "%s_v2_%.3f_%.3f" % [key, min_y, max_abs_x]
	if _head_mesh_cache.has(cache_key):
		return _head_mesh_cache[cache_key]
	if full_mesh == null or full_mesh.get_surface_count() == 0:
		return null
	var arrays := full_mesh.surface_get_arrays(0)
	if arrays.is_empty():
		return null
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if verts.is_empty() or indices.is_empty():
		return null
	var new_indices := PackedInt32Array()
	var tri_count: int = int(float(indices.size()) / 3.0)
	for t in range(tri_count):
		var i0 := indices[t * 3]
		var i1 := indices[t * 3 + 1]
		var i2 := indices[t * 3 + 2]
		var v0 := verts[i0]
		var v1 := verts[i1]
		var v2 := verts[i2]
		if v0.y >= min_y and v1.y >= min_y and v2.y >= min_y and absf(v0.x) <= max_abs_x and absf(v1.x) <= max_abs_x and absf(v2.x) <= max_abs_x:
			new_indices.append(i0)
			new_indices.append(i1)
			new_indices.append(i2)
	if new_indices.is_empty():
		return null
	var new_arrays := []
	new_arrays.resize(Mesh.ARRAY_MAX)
	new_arrays[Mesh.ARRAY_VERTEX] = arrays[Mesh.ARRAY_VERTEX]
	if arrays[Mesh.ARRAY_NORMAL] != null:
		new_arrays[Mesh.ARRAY_NORMAL] = arrays[Mesh.ARRAY_NORMAL]
	if arrays[Mesh.ARRAY_TANGENT] != null:
		new_arrays[Mesh.ARRAY_TANGENT] = arrays[Mesh.ARRAY_TANGENT]
	if arrays[Mesh.ARRAY_TEX_UV] != null:
		new_arrays[Mesh.ARRAY_TEX_UV] = arrays[Mesh.ARRAY_TEX_UV]
	if arrays[Mesh.ARRAY_BONES] != null:
		new_arrays[Mesh.ARRAY_BONES] = arrays[Mesh.ARRAY_BONES]
	if arrays[Mesh.ARRAY_WEIGHTS] != null:
		new_arrays[Mesh.ARRAY_WEIGHTS] = arrays[Mesh.ARRAY_WEIGHTS]
	new_arrays[Mesh.ARRAY_INDEX] = new_indices
	var out_mesh := ArrayMesh.new()
	out_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_arrays)
	var orig_mat := full_mesh.surface_get_material(0)
	if orig_mat != null:
		out_mesh.surface_set_material(0, orig_mat)
	_head_mesh_cache[cache_key] = out_mesh
	return out_mesh
