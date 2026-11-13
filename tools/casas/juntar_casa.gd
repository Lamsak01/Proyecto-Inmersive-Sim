extends RefCounted

## Junta las cajas quietas de un grupo de la casa (muros, interior, tejado) en una sola malla «Juntado», guardada aparte
## en mapa/edificios/comun/ (2026-11-13). Cada pieza suelta es una orden de dibujo; un pueblo con 30 casas de 100
## piezas iría muy lento en el portátil. Lo que se mueve (puertas, postigos, luces: lo que lleva «rol») queda suelto.

const PARTES = preload("res://scripts/visuals/PartesEdificio3D.gd")

const CARPETA := "res://mapa/edificios/comun/"
const NOMBRE := "Juntado"


static func juntar(grupo: Node3D, id_edificio: String) -> void:
	var sueltas: Array[MeshInstance3D] = []
	_buscar(grupo, sueltas)
	if sueltas.is_empty():
		return
	var por_material: Dictionary = {} ## material → SurfaceTool
	for mi: MeshInstance3D in sueltas:
		var mat: Material = mi.material_override
		if not por_material.has(mat):
			por_material[mat] = SurfaceTool.new()
		(por_material[mat] as SurfaceTool).append_from(mi.mesh, 0, _relativa(mi, grupo))
		mi.get_parent().remove_child(mi)
		mi.free()
	var malla := ArrayMesh.new()
	for mat: Material in por_material:
		(por_material[mat] as SurfaceTool).commit(malla)
		malla.surface_set_material(malla.get_surface_count() - 1, mat)
	var ruta: String = CARPETA + "casa_%s_%s.res" % [id_edificio, String(grupo.name).to_lower()]
	ResourceSaver.save(malla, ruta, ResourceSaver.FLAG_COMPRESS)
	var juntado := MeshInstance3D.new()
	juntado.name = NOMBRE
	juntado.mesh = load(ruta) as ArrayMesh
	grupo.add_child(juntado)


## Las cajas quietas: ni las que llevan «rol» ni las que cuelgan de una pieza con «rol».
static func _buscar(nodo: Node, out: Array[MeshInstance3D]) -> void:
	for hijo: Node in nodo.get_children():
		if hijo.has_meta(PARTES.ROL):
			continue
		if hijo is MeshInstance3D and (hijo as MeshInstance3D).visible:
			out.append(hijo as MeshInstance3D)
		_buscar(hijo, out)


## Dónde está la pieza respecto al grupo (la escena no está en el árbol: no hay posiciones globales).
static func _relativa(nodo: Node3D, hasta: Node3D) -> Transform3D:
	var xf: Transform3D = nodo.transform
	var padre: Node = nodo.get_parent()
	while padre != hasta and padre is Node3D:
		xf = (padre as Node3D).transform * xf
		padre = padre.get_parent()
	return xf
