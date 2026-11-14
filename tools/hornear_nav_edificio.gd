extends RefCounted

## Hornea la NavigationMesh local de un edificio de superficie (1 o 2 plantas, posada y restaurante incluidos)
## y guarda tanto el recurso en mapa/navegacion/<id>.res como su nodo NavigationRegion3D dentro del .tscn.

const C = preload("res://tools/hornear_nav_comun.gd")
const Posada = preload("res://tools/hornear_nav_posada.gd")
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

const SUELO_CASA_M: float = 0.270
const SUELO_POSADA_M: float = 0.312
const SUELO_TERRAZA_M: float = 0.190
const SUELO_CALLE_M: float = 0.020
const MURO_GROSOR_M: float = 0.250
const MURO_ALTO_M: float = 7.200
const TABIQUE_ALTO_BAJO_M: float = 3.100
const TABIQUE_ALTO_ARRIBA_M: float = 2.800
const UMBRAL_FUERA_M: float = 0.710
const ESC_CASA_ANCHO_M: float = 1.008
const REST_TERRAZA_FONDO_M: float = 2.500
const REST_PASO_X_M: float = -2.100
const REST_PASO_ANCHO_M: float = 2.400


static func hornear_edificio(id_edif: String, ruta_escena: String) -> Error:
	var ps: PackedScene = load(ruta_escena) as PackedScene
	if ps == null:
		return ERR_CANT_OPEN
	var raiz: Node3D = ps.instantiate() as Node3D
	var planta: Vector2 = raiz.get("planta_m") if raiz.get("planta_m") != null else Vector2.ZERO
	var puerta_ancho: float = float(raiz.get("puerta_ancho_m")) if raiz.get("puerta_ancho_m") != null else 1.4
	if planta == Vector2.ZERO:
		raiz.free()
		return ERR_INVALID_DATA
	var marcas: Dictionary = _leer_marcas_xz(raiz)
	var suelo_bajo: float = SUELO_POSADA_M if id_edif == "building_tavern" else SUELO_CASA_M
	var suelo_alto: float = Mapa3D.piso_alto_m()
	var fuente := NavigationMeshSourceGeometryData3D.new()
	C.agregar_losa(fuente, Vector2.ZERO, planta, suelo_bajo)
	_muros_y_umbral(fuente, id_edif, planta, puerta_ancho, marcas, suelo_bajo)
	_tabiques(fuente, raiz, suelo_bajo, suelo_alto)
	if marcas.has("escalera_pie") and marcas.has("escalera_cima"):
		_planta_alta_casa(fuente, planta, marcas["escalera_pie"], marcas["escalera_cima"], suelo_bajo, suelo_alto)
	elif id_edif == "building_tavern":
		Posada.armar_posada(fuente, planta, marcas, suelo_bajo, suelo_alto)
	_muebles(fuente, raiz, id_edif, planta, marcas, suelo_bajo, suelo_alto)
	raiz.free()
	var nm: NavigationMesh = C.crear_malla()
	var ruta_res: String = C.CARPETA_SALIDA + id_edif + ".res"
	var err: Error = C.hornear_y_guardar(fuente, nm, ruta_res)
	return C.poner_region_en_escena(ruta_escena, load(ruta_res) as NavigationMesh) if err == OK else err


static func _leer_marcas_xz(raiz: Node3D) -> Dictionary:
	var out: Dictionary = {}
	var carpeta: Node = raiz.get_node_or_null("Marcas")
	if carpeta == null:
		return out
	for m: Node in carpeta.get_children():
		var id_m: String = String(m.get("id_marca")) if m.get("id_marca") != null else ""
		if not id_m.is_empty() and m is Node3D:
			out[id_m] = Vector2((m as Node3D).position.x, (m as Node3D).position.z)
	return out


static func _muros_y_umbral(fuente: NavigationMeshSourceGeometryData3D, id_edif: String, planta: Vector2, ancho_p: float, marcas: Dictionary, suelo_y: float) -> void:
	var m: Vector2 = planta * 0.5
	var p_xz: Vector2 = marcas.get("puerta", Vector2(0.0, m.y))
	var horiz: bool = absf(p_xz.y) / m.y >= absf(p_xz.x) / m.x
	var lado: String = ("sur" if p_xz.y > 0.0 else "norte") if horiz else ("este" if p_xz.x > 0.0 else "oeste")
	var tramos: Dictionary = {
		"norte": [Vector2(-m.x, -m.y), Vector2(m.x, -m.y)], "sur": [Vector2(-m.x, m.y), Vector2(m.x, m.y)],
		"oeste": [Vector2(-m.x, -m.y), Vector2(-m.x, m.y)], "este": [Vector2(m.x, -m.y), Vector2(m.x, m.y)],
	}
	for clave: String in tramos:
		var a: Vector2 = tramos[clave][0]
		var b: Vector2 = tramos[clave][1]
		if clave != lado:
			C.agregar_muro_tramo(fuente, a, b, 0.0, MURO_ALTO_M, MURO_GROSOR_M)
			continue
		var dir: Vector2 = (b - a).normalized()
		var off: float = (p_xz - a).dot(dir)
		C.agregar_muro_tramo(fuente, a, a + dir * (off - ancho_p * 0.5), 0.0, MURO_ALTO_M, MURO_GROSOR_M)
		C.agregar_muro_tramo(fuente, a + dir * (off + ancho_p * 0.5), b, 0.0, MURO_ALTO_M, MURO_GROSOR_M)
	if id_edif == "building_restaurant":
		var z_sur: float = m.y + REST_TERRAZA_FONDO_M
		C.agregar_losa(fuente, Vector2(0.0, m.y + REST_TERRAZA_FONDO_M * 0.5), Vector2(planta.x, REST_TERRAZA_FONDO_M), SUELO_TERRAZA_M)
		C.agregar_muro_tramo(fuente, Vector2(-m.x, m.y), Vector2(-m.x, z_sur), 0.0, 1.2, 0.14)
		C.agregar_muro_tramo(fuente, Vector2(m.x, m.y), Vector2(m.x, z_sur), 0.0, 1.2, 0.14)
		C.agregar_muro_tramo(fuente, Vector2(-m.x, z_sur), Vector2(REST_PASO_X_M - REST_PASO_ANCHO_M * 0.5, z_sur), 0.0, 1.2, 0.14)
		C.agregar_muro_tramo(fuente, Vector2(REST_PASO_X_M + REST_PASO_ANCHO_M * 0.5, z_sur), Vector2(m.x, z_sur), 0.0, 1.2, 0.14)
		_agregar_umbral(fuente, Vector2(REST_PASO_X_M, z_sur), Vector2(0.0, 1.0), REST_PASO_ANCHO_M, SUELO_TERRAZA_M)
		return
	var dir_fuera: Vector2 = Vector2(0.0, signf(p_xz.y)) if horiz else Vector2(signf(p_xz.x), 0.0)
	_agregar_umbral(fuente, p_xz, dir_fuera, ancho_p, suelo_y)


static func _agregar_umbral(fuente: NavigationMeshSourceGeometryData3D, centro: Vector2, fuera: Vector2, ancho: float, y_dentro: float) -> void:
	var medio: Vector2 = centro + fuera * 0.42
	var tope: Vector2 = centro + fuera * UMBRAL_FUERA_M
	C.agregar_rampa(fuente, centro - fuera * 0.16, y_dentro, medio, SUELO_CALLE_M, ancho)
	var tam: Vector2 = (fuera.abs() * (UMBRAL_FUERA_M - 0.36)) + (Vector2(-fuera.y, fuera.x).abs() * ancho)
	C.agregar_losa(fuente, (medio + tope) * 0.5 - fuera * 0.03, tam, SUELO_CALLE_M)


static func _tabiques(fuente: NavigationMeshSourceGeometryData3D, raiz: Node3D, y_bajo: float, y_alto: float) -> void:
	var carpeta: Node = raiz.get_node_or_null("Tabiques")
	if carpeta == null:
		return
	for t: Node in carpeta.get_children():
		if not (t is Node3D):
			continue
		var p: Vector3 = (t as Node3D).position
		var tam: Vector2 = t.get("tam_m") if t.get("tam_m") != null else Vector2.ZERO
		var base: float = y_alto if p.y > 2.0 else y_bajo
		var alto: float = TABIQUE_ALTO_ARRIBA_M if p.y > 2.0 else TABIQUE_ALTO_BAJO_M
		C.agregar_caja(fuente, Vector3(p.x, base + alto * 0.5, p.z), Vector3(tam.x, alto, tam.y))


static func _planta_alta_casa(fuente: NavigationMeshSourceGeometryData3D, planta: Vector2, pie: Vector2, cima: Vector2, y_bajo: float, y_alto: float) -> void:
	var dir: Vector2 = (cima - pie).normalized()
	var lat: Vector2 = dir.orthogonal().abs() * (ESC_CASA_ANCHO_M * 0.5)
	var hueco: Rect2 = Rect2(pie, Vector2.ZERO).expand(cima).grow_individual(lat.x, lat.y, lat.x, lat.y)
	for r: Rect2 in C.restar_rect(Rect2(-planta * 0.5, planta), hueco):
		C.agregar_losa(fuente, r.get_center(), r.size, y_alto)
	C.agregar_rampa(fuente, pie - dir * 0.06, y_bajo, cima + dir * 0.06, y_alto, ESC_CASA_ANCHO_M)


static func _muebles(fuente: NavigationMeshSourceGeometryData3D, raiz: Node3D, id_edif: String, planta: Vector2, marcas: Dictionary, y_bajo: float, y_alto: float) -> void:
	var carpeta: Node = raiz.get_node_or_null("Muebles")
	var limite := Rect2(-planta * 0.5, planta).grow_individual(0.1, 0.1, 0.1, REST_TERRAZA_FONDO_M if id_edif == "building_restaurant" else 0.1)
	if carpeta != null:
		for n: Node in carpeta.get_children():
			var m3 := n as Node3D
			if m3 == null or not limite.has_point(Vector2(m3.position.x, m3.position.z)):
				continue
			var modelo: String = String(m3.get("modelo")) if m3.get("modelo") != null else ""
			var clave: String = String(m3.get("clave")) if m3.get("clave") != null else ""
			var ch: Vector2 = m3.get("choque") if m3.get("choque") != null else Vector2.ZERO
			if ch == Vector2.ZERO and not ("Bed_" in modelo or "Table_" in modelo or "Workbench" in modelo or "mesa_morgue" in clave):
				continue
			var tam3: Vector3 = m3.get("tam3") if m3.get("tam3") != null else Vector3.ZERO
			var enc: Vector2 = C.encoger_mueble(Vector2(tam3.x, tam3.z) if tam3 != Vector3.ZERO else ch * Mapa3D.ESCALA)
			var arriba: bool = (int(m3.get("piso")) > 0 if m3.get("piso") != null else false) or m3.position.y > 2.0
			var y_piso: float = y_alto if arriba else (SUELO_TERRAZA_M if m3.position.z > planta.y * 0.5 else y_bajo)
			C.agregar_caja(fuente, Vector3(m3.position.x, y_piso + 0.55, m3.position.z), Vector3(enc.x, 1.1, enc.y), m3.rotation.y)
	for par: Array in [["cofre", Vector2(0.68, 0.48)], ["puesto", Vector2(0.78, 0.56)]]:
		if (par[0] != "puesto" or id_edif == "building_restaurant") and marcas.has(par[0]):
			var tam_m: Vector2 = C.encoger_mueble(par[1])
			C.agregar_caja(fuente, Vector3((marcas[par[0]] as Vector2).x, y_bajo + 0.55, (marcas[par[0]] as Vector2).y), Vector3(tam_m.x, 1.1, tam_m.y))
