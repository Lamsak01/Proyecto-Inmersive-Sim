extends RefCounted

## Primitivas 3D y ajustes comunes para hornear fuera de partida las mallas NavigationMesh del valle y los edificios.
## Lee las medidas reales de TallaCuerpo3D.PERSONA (radio 0,28 m, alto 1,74 m) sin usar nodos 2D ni píxeles.

const TallaCuerpo3D = preload("res://scripts/fisica/TallaCuerpo3D.gd")

const CELDA_TAM_M: float = 0.07
const CELDA_ALTO_M: float = 0.06
const SUBIDA_MAX_M: float = 0.42
const PENDIENTE_MAX_GRADOS: float = 52.0
const BORDE_SECTOR_M: float = 0.56
const MARGEN_UNION_M: float = 0.45
const NOMBRE_REGION: String = "Navegacion"
const CARPETA_SALIDA: String = "res://mapa/navegacion/"
const GROSOR_LOSA_M: float = 0.18
const GROSOR_RAMPA_M: float = 0.24
const ENCOGER_MUEBLE_M: float = 0.34
const MUEBLE_MINIMO_M: float = 0.16
const MIN_TROZO_M: float = 0.01


static func crear_malla(caja_recorte: AABB = AABB(), con_borde: bool = false) -> NavigationMesh:
	var nm := NavigationMesh.new()
	var persona: Vector2 = TallaCuerpo3D.PERSONA
	nm.cell_size = CELDA_TAM_M
	nm.cell_height = CELDA_ALTO_M
	nm.agent_radius = persona.x
	nm.agent_height = persona.y
	nm.agent_max_climb = SUBIDA_MAX_M
	nm.agent_max_slope = PENDIENTE_MAX_GRADOS
	nm.edge_max_length = 23.8 if con_borde else 11.9
	nm.edge_max_error = 5.5 if con_borde else 1.15
	nm.region_min_size = 2.0
	nm.region_merge_size = 20.0
	if con_borde and caja_recorte.size != Vector3.ZERO:
		nm.border_size = BORDE_SECTOR_M
		nm.filter_baking_aabb = AABB(
			caja_recorte.position - Vector3(BORDE_SECTOR_M, 0.0, BORDE_SECTOR_M),
			caja_recorte.size + Vector3(BORDE_SECTOR_M * 2.0, 0.0, BORDE_SECTOR_M * 2.0)
		)
	elif caja_recorte.size != Vector3.ZERO:
		nm.filter_baking_aabb = caja_recorte
	return nm


static func agregar_caja(fuente: NavigationMeshSourceGeometryData3D, centro: Vector3, tam: Vector3, giro_y_rad: float = 0.0) -> void:
	if tam.x <= MIN_TROZO_M or tam.y <= MIN_TROZO_M or tam.z <= MIN_TROZO_M:
		return
	var caja := BoxMesh.new()
	caja.size = tam
	var base := Basis(Vector3.UP, giro_y_rad)
	fuente.add_faces(caja.get_faces(), Transform3D(base, centro))


static func agregar_losa(fuente: NavigationMeshSourceGeometryData3D, centro_xz: Vector2, tam_xz: Vector2, y_sup: float, grosor: float = GROSOR_LOSA_M) -> void:
	agregar_caja(fuente, Vector3(centro_xz.x, y_sup - grosor * 0.5, centro_xz.y), Vector3(tam_xz.x, grosor, tam_xz.y))


static func agregar_muro_tramo(fuente: NavigationMeshSourceGeometryData3D, a_xz: Vector2, b_xz: Vector2, y_base: float, alto: float, grosor: float) -> void:
	var d: Vector2 = b_xz - a_xz
	var largo: float = d.length()
	if largo <= MIN_TROZO_M:
		return
	var medio: Vector2 = (a_xz + b_xz) * 0.5
	var giro: float = -atan2(d.y, d.x)
	agregar_caja(fuente, Vector3(medio.x, y_base + alto * 0.5, medio.y), Vector3(largo, alto, grosor), giro)


static func agregar_rampa(fuente: NavigationMeshSourceGeometryData3D, a_xz: Vector2, y_a: float, b_xz: Vector2, y_b: float, ancho: float) -> void:
	var a3 := Vector3(a_xz.x, y_a, a_xz.y)
	var b3 := Vector3(b_xz.x, y_b, b_xz.y)
	var v: Vector3 = b3 - a3
	var hip: float = v.length()
	var plano := Vector3(v.x, 0.0, v.z)
	if hip <= MIN_TROZO_M or plano.length() <= MIN_TROZO_M:
		return
	var dir_plano: Vector3 = plano.normalized()
	var eje_z: Vector3 = v / hip
	var eje_x := Vector3(-dir_plano.z, 0.0, dir_plano.x)
	var eje_y: Vector3 = eje_z.cross(eje_x).normalized()
	var caja := BoxMesh.new()
	caja.size = Vector3(ancho, GROSOR_RAMPA_M, hip)
	var centro: Vector3 = (a3 + b3) * 0.5 - eje_y * (GROSOR_RAMPA_M * 0.5)
	fuente.add_faces(caja.get_faces(), Transform3D(Basis(eje_x, eje_y, eje_z), centro))


static func encoger_mueble(tam_xz: Vector2) -> Vector2:
	return Vector2(
		maxf(MUEBLE_MINIMO_M, tam_xz.x - ENCOGER_MUEBLE_M * 2.0),
		maxf(MUEBLE_MINIMO_M, tam_xz.y - ENCOGER_MUEBLE_M * 2.0)
	)


static func restar_rect(base: Rect2, hueco: Rect2) -> Array[Rect2]:
	var inter: Rect2 = base.intersection(hueco)
	if not base.intersects(hueco) or inter.get_area() <= 0.0:
		return [base]
	var candidatos: Array[Rect2] = [
		Rect2(base.position, Vector2(base.size.x, inter.position.y - base.position.y)),
		Rect2(Vector2(base.position.x, inter.end.y), Vector2(base.size.x, base.end.y - inter.end.y)),
		Rect2(Vector2(base.position.x, inter.position.y), Vector2(inter.position.x - base.position.x, inter.size.y)),
		Rect2(Vector2(inter.end.x, inter.position.y), Vector2(base.end.x - inter.end.x, inter.size.y)),
	]
	var out: Array[Rect2] = []
	for r: Rect2 in candidatos:
		if r.size.x > MIN_TROZO_M and r.size.y > MIN_TROZO_M:
			out.append(r)
	return out


static func hornear_y_guardar(fuente: NavigationMeshSourceGeometryData3D, nm: NavigationMesh, ruta_res: String) -> Error:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CARPETA_SALIDA))
	NavigationServer3D.bake_from_source_geometry_data(nm, fuente)
	nm.take_over_path(ruta_res)
	return ResourceSaver.save(nm, ruta_res, ResourceSaver.FLAG_COMPRESS)


static func poner_region_en_escena(ruta_escena: String, nm: NavigationMesh) -> Error:
	var ps: PackedScene = load(ruta_escena) as PackedScene
	if ps == null:
		return ERR_CANT_OPEN
	var raiz: Node = ps.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var vieja: Node = raiz.get_node_or_null(NOMBRE_REGION)
	if vieja != null:
		vieja.owner = null
		raiz.remove_child(vieja)
		vieja.free()
	var reg := NavigationRegion3D.new()
	reg.name = NOMBRE_REGION
	reg.navigation_mesh = nm
	raiz.add_child(reg)
	reg.owner = raiz
	var nuevo := PackedScene.new()
	var err: Error = nuevo.pack(raiz)
	if err == OK:
		nuevo.take_over_path(ruta_escena)
		err = ResourceSaver.save(nuevo, ruta_escena)
	raiz.free()
	return err
