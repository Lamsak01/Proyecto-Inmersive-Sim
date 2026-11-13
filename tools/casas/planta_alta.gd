extends RefCounted

## Lo propio de una casa de dos plantas en el constructor (2026-11-13): el suelo de la planta alta (que es el techo de
## la baja) con el hueco de la escalera, la escalera maciza de peldaños, los muros que la cierran por debajo y la
## barandilla de arriba. Devuelve dónde van los choques de esos muros para que tools/casas/armar_casa.gd los ponga.
## La escalera es recta y va a lo largo de x o de z («ESCALERA»: pie, el primer peldaño, y cima, el borde de arriba).

const Piezas = preload("res://tools/casas/piezas_casa.gd")
const Cascaron = preload("res://tools/casas/cascaron_casa.gd")
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const PisosCasas = preload("res://scripts/fisica/PisosCasas.gd")

const LOSA_GROSOR_M: float = 0.2
const PELDANO_ALTO_M: float = 0.19
const BARANDILLA_ALTO_M: float = 1.0
const BARANDILLA_GROSOR_M: float = 0.08
const TINTE := Color(0.9, 0.86, 0.8)
const MADERA_ESCALERA := Color(0.5, 0.34, 0.2)
const MINIMO_M: float = 0.001         ## trozos de losa más finos que esto no se ponen


## ¿Tiene planta alta este plano?
static func tiene(plano: Dictionary) -> bool:
	return plano.has("ESCALERA")


## El hueco de la escalera (rectángulo en el plano, metros).
static func hueco(plano: Dictionary) -> Rect2:
	var pie: Vector2 = plano["ESCALERA"]["pie"]
	var cima: Vector2 = plano["ESCALERA"]["cima"]
	var ancho: float = PisosCasas.ESCALERA_ANCHO_PX * Mapa3D.ESCALA
	var lado: Vector2 = (cima - pie).normalized().orthogonal().abs() * ancho * 0.5
	return Rect2(pie, Vector2.ZERO).expand(cima).grow_individual(lado.x, lado.y, lado.x, lado.y)


## Suelo de arriba, escalera, muros de debajo y barandilla. Devuelve los choques: [[a, b, piso], …].
static func armar(interior: Node3D, piso_alto: Node3D, plano: Dictionary) -> Array:
	var h: Rect2 = hueco(plano)
	for cuarto: Dictionary in plano["CUARTOS_ARRIBA"]:
		var tam: Vector2 = cuarto["tam"]
		var r := Rect2((cuarto["centro"] as Vector2) - tam * 0.5, tam)
		for trozo: Rect2 in _menos(r, h):
			Piezas.caja(piso_alto, Vector3(trozo.get_center().x, Mapa3D.piso_alto_m() - LOSA_GROSOR_M, trozo.get_center().y), Vector3(trozo.size.x, LOSA_GROSOR_M, trozo.size.y), Piezas.material(cuarto["suelo"], TINTE))
	_peldanos(interior, plano)
	var pie: Vector2 = plano["ESCALERA"]["pie"]
	var lados: Dictionary = _lados(h, pie)
	var choques: Array = []
	var pared: Material = Piezas.material(plano["TABIQUE"], TINTE)
	for tramo: Array in lados["abajo"]: # bajo la escalera no se pasa: muros hasta el techo
		Piezas.muro(interior, tramo[0], tramo[1], Cascaron.SUELO_Y_M, Mapa3D.piso_alto_m() - Cascaron.SUELO_Y_M, Cascaron.MURO_GROSOR_M * 0.5, [], pared)
		if tramo != lados["cima"]: # el de la cima, sin choque: quien sube ya va por encima y en 3D lo pararía
			choques.append([tramo[0], tramo[1], 0])
	for tramo: Array in lados["arriba"]: # arriba no se cae por el hueco: barandilla
		Piezas.muro(piso_alto, tramo[0], tramo[1], Mapa3D.piso_alto_m(), BARANDILLA_ALTO_M, BARANDILLA_GROSOR_M, [], Piezas.material("", MADERA_ESCALERA))
		choques.append([tramo[0], tramo[1], 1])
	return choques


## Peldaños macizos del pie a la cima.
static func _peldanos(interior: Node3D, plano: Dictionary) -> void:
	var pie: Vector2 = plano["ESCALERA"]["pie"]
	var cima: Vector2 = plano["ESCALERA"]["cima"]
	var subida: float = Mapa3D.piso_alto_m() - Cascaron.SUELO_Y_M
	var n: int = ceili(subida / PELDANO_ALTO_M)
	var paso: Vector2 = (cima - pie) / float(n)
	var ancho: float = PisosCasas.ESCALERA_ANCHO_PX * Mapa3D.ESCALA
	var tam_paso: Vector2 = paso.abs() + paso.normalized().orthogonal().abs() * ancho
	var madera: Material = Piezas.material("floor_wood_planks.png", TINTE)
	for i in range(n):
		var c: Vector2 = pie + paso * (float(i) + 0.5)
		Piezas.caja(interior, Vector3(c.x, Cascaron.SUELO_Y_M, c.y), Vector3(tam_paso.x, subida * float(i + 1) / float(n), tam_paso.y), madera)


## Los lados del hueco: abajo se cierran los dos largos y el de la cima (el pie queda abierto para subir); arriba, la
## barandilla va por los dos largos y el del pie (la cima queda abierta para salir). «cima»: el lado de la cima.
static func _lados(h: Rect2, pie: Vector2) -> Dictionary:
	var esquinas: Array[Vector2] = [h.position, Vector2(h.end.x, h.position.y), h.end, Vector2(h.position.x, h.end.y)]
	var lados: Array = []
	for i in range(4):
		lados.append([esquinas[i], esquinas[(i + 1) % 4]])
	var lado_pie: int = 0 # el lado cuyo medio está más cerca del pie
	var mejor: float = INF
	for i in range(4):
		var d: float = (((lados[i][0] as Vector2) + (lados[i][1] as Vector2)) * 0.5).distance_to(pie)
		if d < mejor:
			mejor = d
			lado_pie = i
	var lado_cima: int = (lado_pie + 2) % 4
	var abajo: Array = []
	var arriba: Array = []
	for i in range(4):
		if i != lado_pie:
			abajo.append(lados[i])
		if i != lado_cima:
			arriba.append(lados[i])
	return {"abajo": abajo, "arriba": arriba, "cima": lados[lado_cima]}


## Un rectángulo menos otro (el hueco): hasta cuatro trozos que lo cubren sin él.
static func _menos(r: Rect2, h: Rect2) -> Array[Rect2]:
	var i: Rect2 = r.intersection(h)
	if not r.intersects(h) or i.get_area() <= 0.0:
		return [r]
	var trozos: Array[Rect2] = [
		Rect2(r.position, Vector2(r.size.x, i.position.y - r.position.y)),
		Rect2(Vector2(r.position.x, i.end.y), Vector2(r.size.x, r.end.y - i.end.y)),
		Rect2(Vector2(r.position.x, i.position.y), Vector2(i.position.x - r.position.x, i.size.y)),
		Rect2(Vector2(i.end.x, i.position.y), Vector2(r.end.x - i.end.x, i.size.y)),
	]
	var out: Array[Rect2] = []
	for t: Rect2 in trozos:
		if t.size.x > MINIMO_M and t.size.y > MINIMO_M:
			out.append(t)
	return out
