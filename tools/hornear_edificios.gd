extends SceneTree

## Editor del mapa 3D (Claude Code, 2026-11-10): guarda una «foto» 3D de cada edificio tal como lo construye el juego
## (mapa/edificios_vista/<id>.scn) y crea en mapa/Mundo3D.tscn → «Edificios» una pieza movible por edificio.
## Necesita ventana (sin ella no se dibujan los modelos):
##   flatpak run org.godotengine.Godot --path . -s tools/hornear_edificios.gd
## Si ya hay piezas en «Edificios», solo rehace las fotos (no mueve las piezas que el usuario haya colocado).
## Muebles (2026-11-10): las fotos salen sin muebles y cada edificio recibe una carpeta «Muebles» con una pieza movible por
## mueble (mapa/mueble.gd). Solo se crea en los edificios que aún no la tengan.

const ESCENA := "res://mapa/Mundo3D.tscn"
const VISTA_DIR := "res://mapa/edificios_vista/"


func _initialize() -> void:
	var WB = load("res://scripts/visuals/WorldStageBase3D.gd")
	WB.grabar_muebles = true
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(60):
		await process_frame
	var stage: Node = null
	for c in root.find_children("*", "", true, false):
		if c.has_method("rebuild_buildings_3d"):
			stage = c
			break
	var vm: Node = get_first_node_in_group("village_manager")
	if stage == null or vm == null:
		print("HORNEAR_ED: no encuentro el escenario 3D o el pueblo"); quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(VISTA_DIR))
	var broot: Node = stage.get("buildings_root_3d")
	var fotos := 0
	for b in broot.get_children():
		if not String(b.name).begins_with("B3D_"):
			continue
		var id := String(b.name).substr(4)
		var copia: Node = b.duplicate()
		_poner_dueno(copia, copia)
		_texturas_por_ruta(copia)
		var ps := PackedScene.new()
		if ps.pack(copia) == OK and ResourceSaver.save(ps, VISTA_DIR + id + ".scn", ResourceSaver.FLAG_COMPRESS) == OK:
			fotos += 1
		copia.free()
	print("HORNEAR_ED: %d fotos guardadas" % fotos)

	var actual: Node = (load(ESCENA) as PackedScene).instantiate()
	var eds: Node = actual.get_node_or_null("Edificios")
	if eds != null and eds.get_child_count() > 0:
		print("HORNEAR_ED: ya hay piezas en «Edificios»; no se mueven")
		_muebles(actual, eds, stage.get("muebles_grabados"))
		return
	if eds == null:
		eds = Node3D.new()
		eds.name = "Edificios"
		actual.add_child(eds)
		eds.owner = actual
	var sin_p: float = sin(deg_to_rad(WB.PITCH_DEG))
	var cos_p: float = cos(deg_to_rad(WB.PITCH_DEG))
	var script_ed = load("res://mapa/edificio.gd")
	var n := 0
	for fp in vm.get("building_footprints"):
		var id := String(fp.get("id", ""))
		if id.is_empty():
			continue
		var c2: Vector2 = (fp["rect"] as Rect2).get_center()
		var h: float = WB.terrain_height_px(c2)
		var p3 := Vector3(c2.x * WB.WORLD_SCALE, (h * WB.WORLD_SCALE) / cos_p, (c2.y * WB.WORLD_SCALE) / sin_p)
		var e := Node3D.new()
		e.set_script(script_ed)
		e.name = id
		e.set("id_edificio", id)
		e.set("centro_original", c2)
		e.set("origen_3d", p3)
		e.position = p3
		eds.add_child(e)
		e.owner = actual
		n += 1
	print("HORNEAR_ED: %d piezas de edificio" % n)
	_muebles(actual, eds, stage.get("muebles_grabados"))


func _muebles(actual: Node, eds: Node, lista: Array) -> void:
	var script_m = load("res://mapa/mueble.gd")
	var n := 0
	for e in eds.get_children():
		if e.get_node_or_null("Muebles") != null:
			continue
		var carpeta := Node3D.new()
		carpeta.name = "Muebles"
		e.add_child(carpeta)
		carpeta.owner = actual
		var o3: Vector3 = e.get("origen_3d")
		for r in lista:
			if String(r["id"]) != String(e.get("id_edificio")):
				continue
			var m := Node3D.new()
			m.set_script(script_m)
			m.name = ("%s_%s" % [String(r["modelo"]).get_file().get_basename(), "piso1" if int(r["piso"]) == 1 else ""]).trim_suffix("_").validate_node_name()
			m.set("clave", r["clave"])
			m.set("pos_original", r["pos"])
			m.set("local_original", (r["p3"] as Vector3) - o3)
			m.set("giro_original", float(r["giro"]))
			m.set("modelo", r["modelo"])
			m.set("tam3", r["tam3"])
			m.position = (r["p3"] as Vector3) - o3
			m.rotation_degrees.y = float(r["giro"])
			carpeta.add_child(m, true)
			m.owner = actual
			n += 1
	var ps2 := PackedScene.new()
	var err := ps2.pack(actual)
	if err == OK:
		err = ResourceSaver.save(ps2, ESCENA)
	print("HORNEAR_ED: %d muebles de %d anotados (error %d)" % [n, lista.size(), err])
	quit(0 if err == OK else 1)


func _poner_dueno(n: Node, dueno: Node) -> void:
	for c in n.get_children():
		c.owner = dueno
		_poner_dueno(c, dueno)


## Texturas y mallas que el juego crea en caliente (sin archivo) se guardan UNA vez en mapa/edificios_vista/comun/ y las
## fotos apuntan a ellas; si no, cada foto llevaría dentro su copia (~7 MB por edificio).
var _hechos := {}
var _n_res := 0
func _texturas_por_ruta(n: Node) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(VISTA_DIR + "comun"))
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh != null:
			_externo(mi.mesh, "malla")
		var mats: Array = [mi.material_override]
		for si in range(mi.get_surface_override_material_count()):
			mats.append(mi.get_surface_override_material(si))
		if mi.mesh != null:
			for si in range(mi.mesh.get_surface_count()):
				mats.append(mi.mesh.surface_get_material(si))
		for m in mats:
			if m == null or _hechos.has(m.get_instance_id()):
				continue
			_hechos[m.get_instance_id()] = true
			if m is ShaderMaterial and m.shader != null:
				for u in m.shader.get_shader_uniform_list():
					var t = m.get_shader_parameter(u["name"])
					if t is Texture2D:
						_externo(t, "tex")
			else:
				for pr in m.get_property_list():
					if pr["type"] == TYPE_OBJECT and m.get(pr["name"]) is Texture2D:
						_externo(m.get(pr["name"]), "tex")


func _externo(r: Resource, tipo: String) -> void:
	if r == null or not r.resource_path.is_empty() or _hechos.has(r.get_instance_id()):
		return
	_hechos[r.get_instance_id()] = true
	_n_res += 1
	var path := VISTA_DIR + "comun/%s_%s.res" % [tipo, _huella(r)]
	if ResourceSaver.save(r, path, ResourceSaver.FLAG_COMPRESS) == OK:
		r.take_over_path(path)


## Nombre según el contenido: volver a hornear no cambia el contenido de un archivo que otra foto ya usa (2026-11-10).
func _huella(r: Resource) -> String:
	if r is ImageTexture:
		var img: Image = (r as ImageTexture).get_image()
		return "%x" % hash([img.get_size(), img.get_format(), img.get_data().hash()])
	if r is ArrayMesh:
		var partes: Array = []
		for i in range((r as ArrayMesh).get_surface_count()):
			partes.append(var_to_bytes((r as ArrayMesh).surface_get_arrays(i)).hash())
		return "%x" % hash(partes)
	return "%x" % r.get_instance_id()
