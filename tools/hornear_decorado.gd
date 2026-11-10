extends SceneTree

## Editor del mapa 3D (Claude Code, 2026-11-10): pasa a mapa/Mundo3D.tscn → «Decorado» todo lo que el código del terreno
## colocaba aparte del suelo, el agua y las orillas: puentes, pozos, muelle, vallas, corrales, caminos, bancos, plantas y
## piedras del río, adornos… Las piezas creadas seguidas y juntas (las partes de un pozo, de un puente…) quedan en un mismo
## «objeto» para moverlas de una vez; los objetos se ordenan por zonas del mapa. Necesita ventana:
##   flatpak run org.godotengine.Godot --path . -s tools/hornear_decorado.gd
## No hace nada si «Decorado» ya tiene piezas (para no pisar cambios a mano).

const ESCENA := "res://mapa/Mundo3D.tscn"
const COMUN := "res://mapa/decorado_comun/"
const RADIO_OBJETO: float = 22.0
const ZONA: float = 384.0

var WB = null


func _initialize() -> void:
	WB = load("res://scripts/visuals/WorldStageBase3D.gd")
	var actual: Node = (load(ESCENA) as PackedScene).instantiate()
	var viejo: Node = actual.get_node_or_null("Decorado")
	if viejo != null and viejo.get_child_count() > 0:
		print("HORNEAR_DEC: «Decorado» ya tiene piezas; no se toca"); quit(1); return
	WB.grabar_decorado = true
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(40):
		await process_frame
	var stage: Node = null
	for c in root.find_children("*", "", true, false):
		if c.has_method("_separar_decorado"):
			stage = c
			break
	var lista: Array = stage.get("decorado_grabado")
	WB.grabar_decorado = false
	print("HORNEAR_DEC: %d piezas sueltas" % lista.size())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(COMUN))

	var sin_p: float = sin(deg_to_rad(WB.PITCH_DEG))
	var dec := Node3D.new()
	dec.name = "Decorado"
	var zonas := {}
	var objeto: Node3D = null
	var ancla := Vector2.INF
	var n_obj := 0
	for c in lista:
		if not is_instance_valid(c) or not (c is Node3D):
			continue
		var n3 := c as Node3D
		var gxf: Transform3D = n3.global_transform
		var p2 := Vector2(gxf.origin.x / WB.WORLD_SCALE, gxf.origin.z * sin_p / WB.WORLD_SCALE)
		if objeto == null or p2.distance_to(ancla) > RADIO_OBJETO or objeto.get_child_count() >= 40:
			var zk := Vector2i(floori(p2.x / ZONA), floori(p2.y / ZONA))
			if not zonas.has(zk):
				var z := Node3D.new()
				z.name = "Zona_%d_%d" % [zk.x, zk.y]
				dec.add_child(z)
				zonas[zk] = z
			n_obj += 1
			objeto = Node3D.new()
			objeto.name = "%s_%d" % [_nombre(n3), n_obj]
			objeto.position = gxf.origin
			(zonas[zk] as Node3D).add_child(objeto)
			ancla = p2
		n3.get_parent().remove_child(n3)
		objeto.add_child(n3)
		n3.transform = objeto.transform.affine_inverse() * gxf
	if viejo != null:
		actual.remove_child(viejo)
		viejo.free()
	actual.add_child(dec)
	_dueno(dec, actual)
	_externos(dec)
	var ps := PackedScene.new()
	var err := ps.pack(actual)
	if err == OK:
		err = ResourceSaver.save(ps, ESCENA)
	print("HORNEAR_DEC: %d objetos en %d zonas (error %d)" % [n_obj, zonas.size(), err])
	quit(0 if err == OK else 1)


func _nombre(n: Node) -> String:
	if n is MeshInstance3D:
		var m = (n as MeshInstance3D).mesh
		if m is BoxMesh: return "Caja"
		if m is CylinderMesh: return "Cilindro"
		if m is PrismMesh: return "Tejadillo"
		return "Pieza"
	if n is Light3D: return "Luz"
	if n is Label3D: return "Letrero"
	return String(n.name).get_slice("@", 0).replace("@", "")


func _dueno(n: Node, d: Node) -> void:
	n.owner = d
	for c in n.get_children():
		_dueno(c, d)


## Mallas y texturas creadas en caliente se guardan una vez en mapa/decorado_comun/ (las primitivas van dentro de la escena).
var _hechos := {}
var _n := 0
func _externos(n: Node) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var mesh = mi.mesh
		if mesh is ArrayMesh:
			_ext(mesh, "malla")
		var mats: Array = [mi.material_override]
		if mesh != null:
			for si in range(mesh.get_surface_count()):
				mats.append(mesh.surface_get_material(si))
		for m in mats:
			if m == null or _hechos.has(m.get_instance_id()):
				continue
			_hechos[m.get_instance_id()] = true
			if m is ShaderMaterial and m.shader != null:
				for u in m.shader.get_shader_uniform_list():
					if m.get_shader_parameter(u["name"]) is ImageTexture:
						_ext(m.get_shader_parameter(u["name"]), "tex")
			else:
				for pr in m.get_property_list():
					if pr["type"] == TYPE_OBJECT and m.get(pr["name"]) is ImageTexture:
						_ext(m.get(pr["name"]), "tex")


func _ext(r: Resource, tipo: String) -> void:
	if r == null or not r.resource_path.is_empty() or _hechos.has(r.get_instance_id()):
		return
	_hechos[r.get_instance_id()] = true
	_n += 1
	var path := COMUN + "%s_%s.res" % [tipo, _huella(r)]
	if ResourceSaver.save(r, path, ResourceSaver.FLAG_COMPRESS) == OK:
		r.take_over_path(path)


## Nombre según el contenido: volver a hornear no cambia el contenido de un archivo que otra foto ya usa (2026-11-10).
func _huella(r: Resource) -> String:
	if r is ImageTexture:
		var img: Image = (r as ImageTexture).get_image()
		return "%x" % hash([img.get_size(), img.get_format(), hash(img.get_data())])
	if r is ArrayMesh:
		var partes: Array = []
		for i in range((r as ArrayMesh).get_surface_count()):
			partes.append(hash(var_to_bytes((r as ArrayMesh).surface_get_arrays(i))))
		return "%x" % hash(partes)
	return "%x" % r.get_instance_id()
