extends RefCounted

## Mallas y texturas que el juego fabrica en caliente (sin archivo) o que vienen metidas dentro de un modelo: se
## guardan UNA vez en una carpeta común y las escenas apuntan a ellas. Si no, cada escena llevaría dentro su copia.
## El nombre del archivo sale del contenido, así volver a guardar lo mismo no cambia nada en disco.

var _carpeta: String
var _vistos: Dictionary = {} ## id del recurso → true (ya mirado)


func _init(carpeta: String) -> void:
	_carpeta = carpeta
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(carpeta))


## Saca a la carpeta común las mallas juntadas y las texturas sin archivo de todo lo que cuelga de `raiz`.
func sacar_de(raiz: Node) -> void:
	for malla_nodo: MeshInstance3D in raiz.find_children("*", "MeshInstance3D", true, false):
		if malla_nodo.mesh is ArrayMesh:
			_sacar(malla_nodo.mesh, "malla")
		for material: Material in _materiales(malla_nodo):
			_sacar_texturas(material)


func _materiales(malla_nodo: MeshInstance3D) -> Array[Material]:
	var out: Array[Material] = []
	var candidatos: Array = [malla_nodo.material_override]
	for i in range(malla_nodo.get_surface_override_material_count()):
		candidatos.append(malla_nodo.get_surface_override_material(i))
	if malla_nodo.mesh != null:
		for i in range(malla_nodo.mesh.get_surface_count()):
			candidatos.append(malla_nodo.mesh.surface_get_material(i))
	for candidato: Variant in candidatos:
		if candidato is Material and not _vistos.has((candidato as Material).get_instance_id()):
			_vistos[(candidato as Material).get_instance_id()] = true
			out.append(candidato)
	return out


func _sacar_texturas(material: Material) -> void:
	if material is ShaderMaterial and (material as ShaderMaterial).shader != null:
		for uniforme: Dictionary in (material as ShaderMaterial).shader.get_shader_uniform_list():
			var valor: Variant = (material as ShaderMaterial).get_shader_parameter(uniforme["name"])
			if valor is Texture2D:
				_sacar(valor, "tex")
		return
	for propiedad: Dictionary in material.get_property_list():
		if propiedad["type"] == TYPE_OBJECT and material.get(propiedad["name"]) is Texture2D:
			_sacar(material.get(propiedad["name"]), "tex")


## Guarda el recurso en la carpeta común si no tiene archivo propio (vacío, o metido dentro de otro: «archivo::id»).
func _sacar(recurso: Resource, tipo: String) -> void:
	if recurso == null or _vistos.has(recurso.get_instance_id()):
		return
	_vistos[recurso.get_instance_id()] = true
	if not recurso.resource_path.is_empty() and not "::" in recurso.resource_path:
		return
	var ruta := "%s%s_%s.res" % [_carpeta, tipo, _huella(recurso)]
	if ResourceSaver.save(recurso, ruta, ResourceSaver.FLAG_COMPRESS) == OK:
		recurso.take_over_path(ruta)


func _huella(recurso: Resource) -> String:
	if recurso is ImageTexture:
		var imagen: Image = (recurso as ImageTexture).get_image()
		return "%x" % hash([imagen.get_size(), imagen.get_format(), hash(imagen.get_data())])
	if recurso is ArrayMesh:
		var partes: Array = []
		for i in range((recurso as ArrayMesh).get_surface_count()):
			partes.append(hash(var_to_bytes((recurso as ArrayMesh).surface_get_arrays(i))))
		return "%x" % hash(partes)
	if recurso is Texture2D:
		var imagen2: Image = (recurso as Texture2D).get_image()
		return "%x" % hash([imagen2.get_size(), imagen2.get_format(), hash(imagen2.get_data())])
	return "%x" % recurso.get_instance_id()
