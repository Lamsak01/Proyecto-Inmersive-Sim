extends SceneTree

## Renombra y agrupa por objeto real las 416 piezas de «Decorado» en mapa/Mundo3D.tscn
## (las 305 «Caja_N», 96 «Cilindro_N» y 3 «_N»), conservando exactamente su Transform3D en el mundo,
## metadatos (choque, radio) y grupos («pista_caso1»). Uso:
##   flatpak run org.godotengine.Godot --headless --path . -s tools/hornear_nombres_decorado.gd

const Datos = preload("res://tools/hornear_nombres_datos.gd")
const ESCENA: String = "res://mapa/Mundo3D.tscn"


func _initialize() -> void:
	var ps_in: PackedScene = load(ESCENA) as PackedScene
	var raiz: Node = ps_in.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var dec: Node3D = raiz.get_node_or_null("Decorado") as Node3D
	if dec == null:
		push_error("HORNEAR_NOMBRES: no existe Decorado en " + ESCENA)
		quit(1)
		return
	var zonas: Dictionary = {}
	for z: Node in dec.get_children():
		if z is Node3D:
			zonas[String(z.name)] = z
	var piezas_planas: Array[Array] = _recoger_piezas(dec)
	var grupos_creados: Dictionary = {}
	var miembros_grupo: Dictionary = {}
	for entrada: Array in piezas_planas:
		var pieza: Node3D = entrada[0] as Node3D
		var zona_orig: String = String(entrada[1])
		var xf_mundo: Transform3D = entrada[2] as Transform3D
		var clasif: Array[String] = Datos.clasificar(String(pieza.name))
		var nom_grupo: String = clasif[0]
		var nom_pieza: String = clasif[1]
		var nom_zona: String = clasif[2] if not clasif[2].is_empty() else zona_orig
		var nodo_zona: Node3D = _asegurar_zona(dec, zonas, nom_zona, raiz)
		_desasignar_dueno_recursivo(pieza)
		pieza.get_parent().remove_child(pieza)
		pieza.name = nom_pieza
		_nombrar_mallas_internas(pieza)
		if nom_grupo.is_empty():
			nodo_zona.add_child(pieza)
			pieza.transform = xf_mundo
			_asignar_dueno_recursivo(pieza, raiz)
		else:
			var clave_g: String = nom_zona + "/" + nom_grupo
			if not grupos_creados.has(clave_g):
				var grp := Node3D.new()
				grp.name = nom_grupo
				nodo_zona.add_child(grp)
				grp.owner = raiz
				grupos_creados[clave_g] = grp
				miembros_grupo[clave_g] = []
			(miembros_grupo[clave_g] as Array).append([pieza, xf_mundo])
	_centrar_grupos(grupos_creados, miembros_grupo, raiz)
	_limpiar_zonas_vacias(dec)
	var ps_out := PackedScene.new()
	var err: Error = ps_out.pack(raiz)
	if err == OK:
		err = ResourceSaver.save(ps_out, ESCENA)
	print("HORNEAR_NOMBRES: %d piezas renombradas en %d grupos (err=%d)" % [piezas_planas.size(), grupos_creados.size(), err])
	raiz.free()
	quit(0 if err == OK else 1)


func _recoger_piezas(dec: Node3D) -> Array[Array]:
	var out: Array[Array] = []
	for z: Node in dec.get_children():
		if not (z is Node3D):
			continue
		var z3: Node3D = z as Node3D
		for p: Node in z3.get_children():
			if p is Node3D:
				var p3: Node3D = p as Node3D
				out.append([p3, String(z3.name), z3.transform * p3.transform])
	return out


func _asegurar_zona(dec: Node3D, zonas: Dictionary, nombre: String, raiz: Node) -> Node3D:
	if zonas.has(nombre):
		return zonas[nombre] as Node3D
	var z := Node3D.new()
	z.name = nombre
	dec.add_child(z)
	z.owner = raiz
	zonas[nombre] = z
	return z


func _centrar_grupos(grupos: Dictionary, miembros: Dictionary, raiz: Node) -> void:
	for clave: String in grupos.keys():
		var grp: Node3D = grupos[clave] as Node3D
		var lista: Array = miembros[clave] as Array
		var suma := Vector3.ZERO
		for par: Variant in lista:
			suma += ((par as Array)[1] as Transform3D).origin
		var centro: Vector3 = suma / float(maxi(1, lista.size()))
		grp.transform = Transform3D(Basis.IDENTITY, centro)
		var inv: Transform3D = grp.transform.affine_inverse()
		for par: Variant in lista:
			var arr: Array = par as Array
			var pieza: Node3D = arr[0] as Node3D
			var xf_mundo: Transform3D = arr[1] as Transform3D
			grp.add_child(pieza)
			pieza.transform = inv * xf_mundo
			_asignar_dueno_recursivo(pieza, raiz)


func _nombrar_mallas_internas(nodo: Node) -> void:
	var idx: int = 0
	for c: Node in nodo.get_children():
		var actual: String = String(c.name)
		if actual.begins_with("@") or actual.begins_with("MeshInstance3D") or actual.begins_with("Label3D"):
			idx += 1
			if c is Label3D:
				c.name = "Texto_%d" % idx
			elif c is MeshInstance3D:
				var m: Mesh = (c as MeshInstance3D).mesh
				var pref: String = "TramoRedondo" if m is CylinderMesh else ("Bloque" if m is BoxMesh else "Malla")
				c.name = "%s_%d" % [pref, idx]
			else:
				c.name = "Modelo_%d" % idx
		if c.scene_file_path == "" and c.get_child_count() > 0:
			_nombrar_mallas_internas(c)


func _desasignar_dueno_recursivo(nodo: Node) -> void:
	nodo.owner = null
	if nodo.scene_file_path != "":
		return
	for c: Node in nodo.get_children():
		_desasignar_dueno_recursivo(c)


func _asignar_dueno_recursivo(nodo: Node, raiz: Node) -> void:
	nodo.owner = raiz
	if nodo.scene_file_path != "":
		return
	for c: Node in nodo.get_children():
		_asignar_dueno_recursivo(c, raiz)


func _limpiar_zonas_vacias(dec: Node3D) -> void:
	var vacias: Array[Node] = []
	for z: Node in dec.get_children():
		if z.get_child_count() == 0:
			vacias.append(z)
	for z: Node in vacias:
		dec.remove_child(z)
		z.free()
