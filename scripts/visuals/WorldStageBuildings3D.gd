@tool
extends "res://scripts/visuals/WorldStageProps3D.gd"

## Edificios 3D: todos se cargan de una escena del editor (mapa/edificios/<id>.tscn; las casas de recién llegados, de
## la casa modelo de su tamaño). Aquí no se dibuja ningún edificio. También cofres, solares vacíos y obras.

const Partes = preload("res://scripts/visuals/PartesEdificio3D.gd")
const EdificioEditor = preload("res://mapa/edificio.gd")
const CasaModelo = preload("res://mapa/casa_modelo.gd")

func rebuild_buildings_3d() -> void:
	_clear_children(buildings_root_3d)
	_building_records_3d.clear()
	_building_furniture_rects.clear()
	_edificios_de_escena.clear()
	_current_building_id = ""
	_current_building_floor = 0
	_door_nodes_3d.clear()
	_puertas_interiores.limpiar()
	_window_nodes_3d.clear()
	_chest_nodes_3d.clear()
	_morgue_body_nodes_3d.clear()
	_restaurant_night_nodes.clear()
	_jail_gate_pivot_3d = null
	if vm == null:
		return
	for b: Dictionary in vm.building_footprints:
		var propia: PackedScene = _escena_de(str(b.get("id", "")))
		if propia == null: # todo edificio sale de una escena del editor; sin ella no hay nada que poner
			push_error("EDIFICIOS: «%s» no tiene escena en mapa/edificios/" % str(b.get("id", "")))
			continue
		_poner_edificio_de_escena(b, propia)
	_poner_cofres_3d()
	check_furniture_overlaps(true)


## La escena de un edificio: la suya o, si es una casa de recién llegados, la casa modelo de su tamaño. Sin ella, null.
func _escena_de(b_id: String) -> PackedScene:
	if CasaModelo.es_casa_de_solar(b_id):
		return CasaModelo.escena(VillageLots.plot_of(CasaModelo.solar_de(b_id)))
	return EdificioEditor.escena(b_id)


## Cofres de las casas (lista del pueblo): modelo y tapa, que se esconde el día que el cofre se saquea.
func _poner_cofres_3d() -> void:
	var m_gold := _mat("brass_gold", Color(0.85, 0.68, 0.24), 0.35, 0.82)
	for ch: Dictionary in vm.house_chests:
		var c_pos: Vector2 = ch.get("pos", Vector2.ZERO)
		var is_tavern_upper: bool = str(ch.get("family_id", "")) == VillageTavern.FAMILY_ID
		var base_h: float = VillageTavern.FLOOR_1_H if is_tavern_upper else 2.0
		var parent_node: Node3D = buildings_root_3d
		_current_building_id = ""
		_current_building_floor = 1 if is_tavern_upper else 0
		for rec: Dictionary in _building_records_3d:
			if not (rec["rect"] as Rect2).grow(8.0).has_point(c_pos):
				continue
			_current_building_id = str(rec["id"])
			if is_tavern_upper and is_instance_valid(rec.get("loft_root")):
				parent_node = rec["loft_root"]
			break
		var ch_root := Node3D.new()
		ch_root.set_meta(Partes.ROL, Partes.COFRE)
		parent_node.add_child(ch_root)
		ch_root.global_transform = Transform3D.IDENTITY # el cofre viene en coordenadas del mundo, cuelgue de quien cuelgue
		_add_model_2d(ch_root, "props/Chest_Wood.gltf", c_pos, base_h, Vector2(12.0, 8.5), 7.5)
		var lid := _add_box_2d(ch_root, c_pos, Vector2(11.4, 7.8), base_h + 5.5, 1.8, m_gold)
		_chest_nodes_3d.append({"entry": ch, "lid": lid})
	_current_building_id = ""
	_current_building_floor = 0


## Edificio con escena propia (mapa/edificios/<id>.tscn): se cuelga tal cual, en el sitio y con el giro de su planta.
func _poner_edificio_de_escena(b: Dictionary, propia: PackedScene) -> void:
	var b_id: String = str(b["id"])
	var rect: Rect2 = b["rect"]
	var raiz: Node3D = propia.instantiate()
	raiz.name = "B3D_" + b_id
	buildings_root_3d.add_child(raiz)
	var giro: float = float(b.get("giro", 0.0))
	var puerta_sur: bool = bool(b.get("door_south_orig", b["door_south"]))
	if CasaModelo.es_casa_de_solar(b_id): # hecha con la puerta al sur: si el solar mira al norte, media vuelta
		giro += CasaModelo.giro_de_fabrica(puerta_sur)
		puerta_sur = true
	raiz.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(giro)), to_3d(rect.get_center()))
	_edificios_de_escena[b_id] = true
	_poner_muebles_de_escena(raiz, b_id)
	_registrar_edificio_3d(raiz, b_id, rect, puerta_sur)


## Dibuja el modelo de cada pieza del grupo «Muebles» (mapa/mueble.gd) donde la dejó el usuario y los junta en una
## malla. Los de la planta alta pasan al grupo «PisoAlto», para esconderse con él.
func _poner_muebles_de_escena(raiz: Node3D, b_id: String) -> void:
	var muebles: Node3D = raiz.get_node_or_null(Partes.MUEBLES)
	if muebles == null:
		return
	var altos: Node3D = _grupo_3d(raiz.get_node(Partes.PISO_ALTO) as Node3D, Partes.MUEBLES)
	_current_building_id = b_id
	for pieza: Node in muebles.get_children():
		var mueble := pieza as Node3D
		var modelo: String = String(mueble.get("modelo"))
		var tam3: Vector3 = mueble.get("tam3")
		_current_building_floor = int(mueble.get("piso"))
		if _current_building_floor > 0:
			mueble.reparent(altos, false)
		_register_furniture_rect(modelo.get_file().get_basename(), Mapa3D.a_mapa(mueble.global_position), Mapa3D.a_mapa(tam3), mueble.global_rotation_degrees.y)
		if _is_headless or not AssetLib.has_curated_assets():
			continue
		var dibujo: Node3D = AssetLib.instantiate_model(modelo, tam3, float(mueble.get("alto3")), true, true)
		if dibujo != null:
			mueble.add_child(dibujo)
	_current_building_id = ""
	_current_building_floor = 0
	if not _is_headless:
		_merge_meshes_under(muebles, {})
		_merge_meshes_under(altos, {})


## Apunta un edificio ya montado (por código o desde su escena) y sus partes móviles, que reconoce por su etiqueta.
func _registrar_edificio_3d(raiz: Node3D, b_id: String, rect_real: Rect2, door_south: bool) -> void:
	_building_records_3d.append({
		"id": b_id,
		"rect": rect_real, # dónde está de verdad (para abrir el tejado al entrar)
		"root": raiz,
		"roof_cap": raiz.get_node_or_null(Partes.TEJADO),
		"loft_root": raiz.get_node_or_null(Partes.PISO_ALTO),
	})
	for parte: Node in Partes.con_rol(raiz):
		match String(parte.get_meta(Partes.ROL)):
			Partes.PUERTA:
				var entrada: Dictionary = _entrada_del_edificio(vm.building_doors, b_id)
				if not entrada.is_empty():
					_door_nodes_3d.append({"entry": entrada, "pivot": parte, "lock_badge": Partes.hijo_con_rol(parte, Partes.CANDADO), "door_south": door_south})
			Partes.POSTIGO:
				var ventana: Dictionary = _entrada_del_edificio(vm.building_windows, b_id)
				if not ventana.is_empty():
					_window_nodes_3d.append({"entry": ventana, "shutter": parte})
			Partes.LUZ_NOCHE:
				_restaurant_night_nodes.append(parte)
			Partes.CUERPO_MORGUE:
				_morgue_body_nodes_3d.append(parte as Node3D)
			Partes.REJA_CELDA:
				_jail_gate_pivot_3d = parte as Node3D
				_reja_celda_cerrada = _jail_gate_pivot_3d.position
			Partes.BOMBILLA_CUADRO:
				_grid_panel_bulb_3d = parte as MeshInstance3D
			Partes.PUERTA_CUARTO:
				var hueco: Vector3 = raiz.global_transform * (parte.get_meta(Partes.HUECO) as Vector3)
				_puertas_interiores.anadir(parte as Node3D, Mapa3D.a_mapa(hueco), int(parte.get_meta(Partes.NIVEL, 0)))


## La puerta o la ventana (de las listas del pueblo) que pertenece a ese edificio; {} si no tiene.
func _entrada_del_edificio(lista: Array, b_id: String) -> Dictionary:
	for entrada: Dictionary in lista:
		if str(entrada.get("building_id", "")) == b_id:
			return entrada
	return {}


## Nodo vacío con nombre fijo, hijo de `padre` (los grupos de un edificio).
func _grupo_3d(padre: Node3D, nombre: String) -> Node3D:
	var grupo := Node3D.new()
	grupo.name = nombre
	padre.add_child(grupo)
	return grupo

func _merge_meshes_under(root: Node3D, excl: Dictionary) -> void:
	var found: Array = []
	_collect_merge_meshes(root, root, excl, found)
	_merge_mesh_list(root, found)

## Junta en `root` las mallas de `found` (una malla por sombra, una superficie por material). Las originales dejan de dibujarse.
func _merge_mesh_list(root: Node3D, found: Array) -> void:
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
		if excl.has(c) or c.has_meta(Partes.ROL): # lo etiquetado (puertas, postigos, luces de noche…) se mueve: no se junta
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

var _restaurant_night_nodes: Array = [] ## luces y bombillas que se encienden al caer la tarde (terraza de la casa de comidas)


# ==============================================================================
# 3. SOLARES VACÍOS Y OBRAS EN CONSTRUCCIÓN (`VillageLots.LOTS`)
# ==============================================================================
func rebuild_lots_3d() -> void:
	_clear_children(lots_root_3d)
	if vm == null:
		return
	var m_stake := _mat("lot_stake", Color(0.52, 0.36, 0.22), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_scaffold := _mat("lot_scaffold", Color(0.64, 0.48, 0.30), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_found := _mat("lot_foundation", Color(0.56, 0.54, 0.50), 0.90, 0.02, Color.BLACK, 0.0, "town_textures/wall_stone.png", "", 0.70)

	mover_posiciones = true
	for l_entry in VillageLots.LOTS:
		var l_dict: Dictionary = l_entry
		var id: String = str(l_dict["id"])
		var st: Dictionary = VillageLots.lot(vm, id)
		var status: String = str(st.get("status", "empty"))
		if status == "built":
			continue
		var c: Vector2 = VillageLots.lot_def(id)["center"] # en el mapa original: las estacas y la obra van con la pieza del solar
		var h: Vector2 = (l_dict["size"] as Vector2) * 0.5 - Vector2(6, 6)
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
	mover_posiciones = false

