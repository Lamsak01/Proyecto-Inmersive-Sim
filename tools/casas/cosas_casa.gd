extends RefCounted

## Cosas de casa que no tienen modelo comprado (2026-11-13): se arman con cajas y cilindros, toscas y de época
## tecnofeudal (hierro, cinc, madera, baquelita). Cada función dibuja la cosa con su base en (0, 0, 0) dentro de
## `padre` (un mueble de la escena, mapa/mueble.gd, que pone su choque). Medidas en metros.

const Piezas = preload("res://tools/casas/piezas_casa.gd")
const PARTES = preload("res://scripts/visuals/PartesEdificio3D.gd")

const HIERRO := Color(0.16, 0.16, 0.17)
const CINC := Color(0.62, 0.64, 0.66)
const PIEDRA := Color(0.55, 0.53, 0.5)
const MADERA := Color(0.42, 0.28, 0.16)
const BAQUELITA := Color(0.28, 0.16, 0.09)
const DIAL := Color(0.95, 0.8, 0.45)
const AGUA := Color(0.3, 0.42, 0.5)
const LUZ_BOMBILLA := Color(1.0, 0.82, 0.55)
const TECHO_M: float = 3.0                 ## altura del techo de la casa (el cable de la bombilla cuelga de él)
const ALCANCE_BOMBILLA_M: float = 6.0
const ENERGIA_BOMBILLA: float = 1.4


static func _mat(color: Color, metal: float = 0.0) -> Material:
	return Piezas.material("", color, metal)


static func _cilindro(padre: Node3D, base: Vector3, radio: float, alto: float, mat: Material) -> void:
	var forma := CylinderMesh.new()
	forma.top_radius = radio
	forma.bottom_radius = radio
	forma.height = alto
	var mi := MeshInstance3D.new()
	mi.mesh = forma
	mi.material_override = mat
	mi.position = base + Vector3(0.0, alto * 0.5, 0.0)
	padre.add_child(mi)


## Estufa de hierro con su tubo de humos hasta el techo (cocina de artesano).
static func estufa(padre: Node3D) -> void:
	Piezas.caja(padre, Vector3.ZERO, Vector3(0.8, 0.8, 0.6), _mat(HIERRO, 0.6))
	Piezas.caja(padre, Vector3(0.0, 0.8, 0.0), Vector3(0.86, 0.05, 0.66), _mat(HIERRO, 0.7))
	_cilindro(padre, Vector3(0.2, 0.85, -0.15), 0.07, TECHO_M - 0.85, _mat(HIERRO, 0.6))


## Pila de piedra con bomba de agua de palanca (agua del pozo sin salir de casa).
static func pila_con_bomba(padre: Node3D) -> void:
	Piezas.caja(padre, Vector3.ZERO, Vector3(1.0, 0.85, 0.55), _mat(PIEDRA))
	Piezas.caja(padre, Vector3(0.0, 0.85, 0.0), Vector3(0.8, 0.02, 0.4), _mat(AGUA))
	_cilindro(padre, Vector3(0.3, 0.85, -0.18), 0.05, 0.6, _mat(HIERRO, 0.6))
	Piezas.caja(padre, Vector3(0.18, 1.35, -0.18), Vector3(0.28, 0.05, 0.05), _mat(HIERRO, 0.6))
	Piezas.caja(padre, Vector3(0.45, 1.4, -0.18), Vector3(0.05, 0.05, 0.4), _mat(HIERRO, 0.6), 30.0)


## Bañera de cinc con algo de agua (se llena a cubos).
static func banera(padre: Node3D) -> void:
	var cinc: Material = _mat(CINC, 0.8)
	Piezas.caja(padre, Vector3.ZERO, Vector3(1.5, 0.06, 0.7), cinc)
	for lado: float in [-1.0, 1.0]:
		Piezas.caja(padre, Vector3(lado * 0.725, 0.0, 0.0), Vector3(0.05, 0.55, 0.7), cinc)
		Piezas.caja(padre, Vector3(0.0, 0.0, lado * 0.325), Vector3(1.5, 0.55, 0.05), cinc)
	Piezas.caja(padre, Vector3(0.0, 0.06, 0.0), Vector3(1.4, 0.24, 0.6), _mat(AGUA))


## Radio de válvulas de baquelita sobre su mesita: el dial se ve encendido.
static func radio(padre: Node3D) -> void:
	Piezas.caja(padre, Vector3.ZERO, Vector3(0.6, 0.7, 0.45), _mat(MADERA))
	Piezas.caja(padre, Vector3(0.0, 0.7, 0.0), Vector3(0.5, 0.32, 0.24), _mat(BAQUELITA))
	var dial: MeshInstance3D = Piezas.caja(padre, Vector3(-0.08, 0.8, 0.121), Vector3(0.22, 0.1, 0.01), _mat(DIAL))
	(dial.material_override as StandardMaterial3D).emission_enabled = true
	(dial.material_override as StandardMaterial3D).emission = DIAL
	for x: float in [0.12, 0.19]:
		_cilindro(padre, Vector3(x, 0.8, 0.12), 0.025, 0.04, _mat(HIERRO))


## Bombilla desnuda colgada del techo, de la red del pueblo: se enciende al caer la tarde. `alto`: del suelo al techo.
static func bombilla(padre: Node3D, alto: float = TECHO_M) -> void:
	_cilindro(padre, Vector3(0.0, alto - 0.6, 0.0), 0.006, 0.6, _mat(HIERRO))
	var luz := Node3D.new()
	luz.position = Vector3(0.0, alto - 0.66, 0.0)
	luz.set_meta(PARTES.ROL, PARTES.LUZ_NOCHE)
	padre.add_child(luz)
	var vidrio := _mat(LUZ_BOMBILLA)
	(vidrio as StandardMaterial3D).emission_enabled = true
	(vidrio as StandardMaterial3D).emission = LUZ_BOMBILLA
	var forma := SphereMesh.new()
	forma.radius = 0.05
	forma.height = 0.1
	var bulbo := MeshInstance3D.new()
	bulbo.mesh = forma
	bulbo.material_override = vidrio
	luz.add_child(bulbo)
	var omni := OmniLight3D.new()
	omni.light_color = LUZ_BOMBILLA
	omni.omni_range = ALCANCE_BOMBILLA_M
	omni.light_energy = ENERGIA_BOMBILLA
	luz.add_child(omni)


## Palangana de cinc sobre un taburete (lavarse cara y manos).
static func palangana(padre: Node3D) -> void:
	Piezas.caja(padre, Vector3.ZERO, Vector3(0.4, 0.65, 0.4), _mat(MADERA))
	_cilindro(padre, Vector3(0.0, 0.65, 0.0), 0.2, 0.1, _mat(CINC, 0.8))


## Alfombra de lana (solo se ve; se pisa).
static func alfombra(padre: Node3D, tam: Vector2, color: Color) -> void:
	Piezas.caja(padre, Vector3.ZERO, Vector3(tam.x, 0.02, tam.y), _mat(color))


## Letrina de tablas en el patio, con su puerta y una media luna (las casas sin retrete dentro).
static func letrina(padre: Node3D) -> void:
	var tablas: Material = Piezas.material("wall_timber.png", Color(0.75, 0.65, 0.55))
	Piezas.caja(padre, Vector3.ZERO, Vector3(1.2, 2.2, 1.2), tablas)
	Piezas.caja(padre, Vector3(0.0, 2.2, 0.0), Vector3(1.4, 0.08, 1.4), _mat(MADERA), 0.0)
	Piezas.caja(padre, Vector3(0.0, 0.05, 0.61), Vector3(0.7, 1.9, 0.04), _mat(MADERA))
	Piezas.caja(padre, Vector3(0.0, 1.6, 0.635), Vector3(0.14, 0.1, 0.01), _mat(HIERRO))
