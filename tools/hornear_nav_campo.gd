extends RefCounted

## Hornea por sectores (112 × 112 m) la NavigationMesh del valle abierto con recortes de edificios,
## umbrales de puerta alineados, árboles, rocas y mobiliario exterior, y los cuelga de Mundo3D.tscn.

const C = preload("res://tools/hornear_nav_comun.gd")
const AguaNav = preload("res://tools/hornear_nav_agua.gd")
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Edificio = preload("res://mapa/edificio.gd")
const Sitio = preload("res://mapa/sitio.gd")

const ESCENA_MAPA: String = "res://mapa/Mundo3D.tscn"
const LADO_SECTOR_M: float = 112.0
const RANGO_VALLE_M: Rect2 = Rect2(Vector2(-560.0, -448.0), Vector2(1120.0, 1232.0))


static func hornear_campo() -> Dictionary:
	var agua: Dictionary = AguaNav.preparar_datos_agua()
	var obstaculos: Array[Dictionary] = _recoger_obstaculos()
	var sectores: Array[Dictionary] = []
	var nx: int = int(roundf(RANGO_VALLE_M.size.x / LADO_SECTOR_M))
	var nz: int = int(roundf(RANGO_VALLE_M.size.y / LADO_SECTOR_M))
	for sz: int in range(nz):
		for sx: int in range(nx):
			var orig: Vector2 = RANGO_VALLE_M.position + Vector2(float(sx), float(sz)) * LADO_SECTOR_M
			var rect_s := Rect2(orig, Vector2(LADO_SECTOR_M, LADO_SECTOR_M))
			var fuente := NavigationMeshSourceGeometryData3D.new()
			var ry: Vector2 = AguaNav.agregar_terreno_sector(fuente, rect_s, agua)
			_agregar_obstaculos_sector(fuente, rect_s.grow(4.0), obstaculos)
			var nm: NavigationMesh = C.crear_malla(AABB(Vector3(orig.x, ry.x - 1.5, orig.y), Vector3(LADO_SECTOR_M, (ry.y - ry.x) + 6.5, LADO_SECTOR_M)), true)
			var ruta_res: String = "%ssector_%d_%d.res" % [C.CARPETA_SALIDA, sx, sz]
			if C.hornear_y_guardar(fuente, nm, ruta_res) == OK and nm.get_polygon_count() > 0:
				sectores.append({"nombre": "Sector_%d_%d" % [sx, sz], "ruta": ruta_res})
	return {"err": _guardar_en_mundo(sectores), "sectores": sectores.size()}


static func _recoger_obstaculos() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_obstaculos_edificios(out)
	var mundo: Node = (load(ESCENA_MAPA) as PackedScene).instantiate()
	var dec: Node = mundo.get_node_or_null("Decorado")
	if dec != null:
		_obstaculos_decorado(dec, Transform3D.IDENTITY, out)
	for g_nom: String in ["Vegetacion", "Decoracion"]:
		var g: Node = mundo.get_node_or_null(g_nom)
		if g != null:
			_obstaculos_piezas(g, Transform3D.IDENTITY, out)
	var obj: Node = mundo.get_node_or_null("Objetos")
	for ch: Node in (obj.get_children() if obj != null else []):
		if ch is Node3D:
			var n3 := ch as Node3D
			var clave: String = (String(n3.get("clave")) if n3.get("clave") != null else n3.name).to_lower()
			_anadir_obs(out, Vector2(n3.position.x, n3.position.z), Vector2(1.50, 1.50) if "pozo" in clave else (Vector2(0.56, 0.20) if "tablon" in clave else Vector2(0.20, 0.20)), n3.rotation.y)
	var pozo_r: Vector3 = Mapa3D.a_3d(Sitio.mundo("pozo_ronda"))
	_anadir_obs(out, Vector2(pozo_r.x, pozo_r.z), Vector2(1.50, 1.50), 0.0)
	mundo.free()
	return out

static func _obstaculos_edificios(out: Array[Dictionary]) -> void:
	var escenas: Dictionary = Edificio.escenas()
	for id_e: String in escenas:
		if id_e == "bajo_alcantarillas":
			continue
		var raiz: Node3D = (escenas[id_e] as PackedScene).instantiate() as Node3D
		var planta: Vector2 = raiz.get("planta_m")
		var ancho_p: float = float(raiz.get("puerta_ancho_m"))
		var p_nodo: Node3D = raiz.get_node_or_null("Marcas/puerta") as Node3D
		var p_xz: Vector2 = Vector2(p_nodo.position.x, p_nodo.position.z) if p_nodo != null else Vector2(0.0, planta.y * 0.5)
		raiz.free()
		var es_rest: bool = id_e == "building_restaurant"
		var base := Rect2(-planta * 0.5, planta).grow_individual(0.125, 0.125, 0.125, 2.570 if es_rest else 0.125)
		var paso_c: Vector2 = Vector2(-2.100, planta.y * 0.5 + 2.500) if es_rest else p_xz
		var paso_a: float = 2.400 if es_rest else ancho_p
		var muesca: Vector2 = Vector2(paso_a, 0.40) if absf(paso_c.y) / planta.y >= absf(paso_c.x) / planta.x else Vector2(0.40, paso_a)
		var c_m: Vector3 = Mapa3D.a_3d(Edificio.a_mundo(id_e, Edificio.centro_de_fabrica(id_e)))
		var g_rad: float = deg_to_rad(Edificio.giro(id_e))
		for r: Rect2 in C.restar_rect(base, Rect2(paso_c - muesca * 0.5, muesca)):
			_anadir_obs(out, Vector2(c_m.x, c_m.z) + r.get_center().rotated(-g_rad), r.size, g_rad, 4.5)

static func _obstaculos_decorado(nodo: Node, xf_p: Transform3D, out: Array[Dictionary]) -> void:
	for hijo: Node in nodo.get_children():
		if not (hijo is Node3D):
			continue
		var n3 := hijo as Node3D
		var xf: Transform3D = xf_p * n3.transform
		if n3.has_meta("choque"):
			var g2: float = -xf.basis.orthonormalized().get_euler().y
			var c2: Vector2 = Mapa3D.a_mapa(xf.origin) + (n3.get_meta("choque_desplaz", Vector2.ZERO) as Vector2).rotated(g2)
			var sz_m: Vector2 = (n3.get_meta("choque") as Vector2) * Mapa3D.ESCALA
			var nom: String = n3.name.to_lower()
			var tam_f: Vector2 = Vector2(0.14, 0.14) if "lapida" in nom else (C.encoger_mueble(sz_m) if ("banco" in nom or "mesa" in nom) else sz_m)
			_anadir_obs(out, c2 * Mapa3D.ESCALA, tam_f, -(g2 + deg_to_rad(float(n3.get_meta("choque_giro", 0.0)))))
		if n3.get_child_count() > 0:
			_obstaculos_decorado(n3, xf, out)

static func _obstaculos_piezas(nodo: Node, xf_p: Transform3D, out: Array[Dictionary]) -> void:
	for ch: Node in nodo.get_children():
		var n3 := ch as Node3D
		if n3 == null:
			continue
		var xf: Transform3D = xf_p * n3.transform
		var es_pieza: bool = n3.has_method("tipo_choque") or n3 is VisualInstance3D or not n3.scene_file_path.is_empty()
		if not es_pieza:
			_obstaculos_piezas(n3, xf, out)
			continue
		var tipo: String = String(n3.call("tipo_choque")) if n3.has_method("tipo_choque") else ("ninguno" if bool(n3.get_meta("atravesable", false)) else "forma")
		if tipo != "ninguno":
			var t2: Variant = n3.get("tam")
			var sz_m: Vector2 = Vector2(0.392, 0.392) if tipo == "tronco" else ((t2 as Vector2) * Mapa3D.ESCALA if t2 is Vector2 else Vector2(0.90, 0.90))
			_anadir_obs(out, Vector2(xf.origin.x, xf.origin.z), sz_m, xf.basis.orthonormalized().get_euler().y)


static func _anadir_obs(out: Array[Dictionary], xz: Vector2, tam: Vector2, giro: float, alto: float = 2.2) -> void:
	var r_max: float = tam.length() * 0.5
	out.append({"xz": xz, "y": AguaNav.cota_suelo_m(xz), "tam": tam, "giro": giro, "alto": alto, "caja": Rect2(xz - Vector2.ONE * r_max, Vector2.ONE * (r_max * 2.0))})


static func _agregar_obstaculos_sector(fuente: NavigationMeshSourceGeometryData3D, rect_m: Rect2, obs: Array[Dictionary]) -> void:
	for o: Dictionary in obs:
		if rect_m.intersects(o["caja"]):
			var xz: Vector2 = o["xz"]
			var h: float = float(o["alto"])
			C.agregar_caja(fuente, Vector3(xz.x, float(o["y"]) + h * 0.5 - 0.2, xz.y), Vector3((o["tam"] as Vector2).x, h, (o["tam"] as Vector2).y), float(o["giro"]))


static func _guardar_en_mundo(sectores: Array[Dictionary]) -> Error:
	var mundo: Node = (load(ESCENA_MAPA) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var vieja: Node = mundo.get_node_or_null(C.NOMBRE_REGION)
	if vieja != null:
		vieja.owner = null
		mundo.remove_child(vieja)
		vieja.free()
	var carpeta := Node3D.new()
	carpeta.name = C.NOMBRE_REGION
	mundo.add_child(carpeta)
	carpeta.owner = mundo
	for s: Dictionary in sectores:
		var reg := NavigationRegion3D.new()
		reg.name = String(s["nombre"])
		reg.navigation_mesh = load(String(s["ruta"])) as NavigationMesh
		carpeta.add_child(reg)
		reg.owner = mundo
	var ps := PackedScene.new()
	var err: Error = ps.pack(mundo)
	if err == OK:
		ps.take_over_path(ESCENA_MAPA)
		err = ResourceSaver.save(ps, ESCENA_MAPA)
	mundo.free()
	return err
