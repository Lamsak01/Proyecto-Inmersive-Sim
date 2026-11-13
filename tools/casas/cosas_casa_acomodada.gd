extends RefCounted

## Cosas armadas a mano para las casas acomodadas (nivel 3, 2026-11-13): agua corriente (retrete de cisterna, lavabo y
## fregadero con grifo), ventilador de techo y gramola; y lo del taller del Arreglador: la terminal de pantalla verde,
## el generador diésel que da luz al pueblo y su cuadro eléctrico (el piloto lo colorea el juego por su «rol»).
## Metros respecto a la pieza (tools/casas/armar_casa.gd las dibuja); el suelo de la pieza es y = 0; sin giro, lo
## que tiene frente mira al sur (+z).

const Piezas = preload("res://tools/casas/piezas_casa.gd")
const Cosas = preload("res://tools/casas/cosas_casa.gd")
const PARTES = preload("res://scripts/visuals/PartesEdificio3D.gd")

const LOZA := Color(0.92, 0.92, 0.88)
const LATON := Color(0.78, 0.62, 0.3)
const VERDE_PANTALLA := Color(0.32, 0.96, 0.82)   ## el mismo verde que pinta el juego en las pantallas
const PINTURA_MAQUINA := Color(0.25, 0.32, 0.24)
const ASPAS: int = 4
const ASPA_LARGO_M: float = 0.55
const CABLE_RADIO_M: float = 0.02


## Retrete de loza con su cisterna alta y la cadena.
static func inodoro(padre: Node3D) -> void:
	var loza: Material = Cosas.mat(LOZA)
	Cosas.cilindro(padre, Vector3(0.0, 0.0, 0.05), 0.2, 0.42, loza)
	Piezas.caja(padre, Vector3(0.0, 0.42, 0.05), Vector3(0.42, 0.04, 0.46), Cosas.mat(Cosas.MADERA))
	Piezas.caja(padre, Vector3(0.0, 1.7, -0.2), Vector3(0.45, 0.28, 0.18), Cosas.mat(Cosas.HIERRO, 0.5))
	Cosas.cilindro(padre, Vector3(0.0, 0.42, -0.2), 0.025, 1.28, Cosas.mat(Cosas.HIERRO, 0.5))
	Cosas.cilindro(padre, Vector3(0.15, 1.25, -0.12), 0.006, 0.45, Cosas.mat(LATON, 0.8))


## Lavabo de loza sobre su pie, con grifo de latón y espejo.
static func lavabo(padre: Node3D) -> void:
	var loza: Material = Cosas.mat(LOZA)
	Cosas.cilindro(padre, Vector3.ZERO, 0.09, 0.75, loza)
	Piezas.caja(padre, Vector3(0.0, 0.75, 0.0), Vector3(0.55, 0.12, 0.4), loza)
	Cosas.cilindro(padre, Vector3(0.0, 0.87, -0.15), 0.02, 0.15, Cosas.mat(LATON, 0.8))
	Piezas.caja(padre, Vector3(0.0, 1.15, -0.19), Vector3(0.4, 0.5, 0.02), Cosas.mat(Cosas.CINC, 0.9))


## Fregadero de piedra con grifo de agua corriente (la cocina acomodada no saca agua a bomba).
static func fregadero(padre: Node3D) -> void:
	Piezas.caja(padre, Vector3.ZERO, Vector3(1.0, 0.85, 0.55), Cosas.mat(Cosas.PIEDRA))
	Piezas.caja(padre, Vector3(0.0, 0.85, 0.0), Vector3(0.6, 0.02, 0.35), Cosas.mat(Cosas.AGUA))
	Cosas.cilindro(padre, Vector3(0.0, 0.85, -0.22), 0.025, 0.3, Cosas.mat(LATON, 0.8))


## Ventilador de techo de la red del pueblo: eje, motor y cuatro aspas de madera. `alto`: del suelo al techo.
static func ventilador(padre: Node3D, alto: float) -> void:
	Cosas.cilindro(padre, Vector3(0.0, alto - 0.5, 0.0), 0.015, 0.5, Cosas.mat(LATON, 0.8))
	Cosas.cilindro(padre, Vector3(0.0, alto - 0.62, 0.0), 0.1, 0.12, Cosas.mat(LATON, 0.8))
	for i: int in range(ASPAS):
		var aspa: MeshInstance3D = Piezas.caja(padre, Vector3(0.0, alto - 0.6, 0.0), Vector3(ASPA_LARGO_M * 2.0, 0.015, 0.12), Cosas.mat(Cosas.MADERA))
		aspa.rotation_degrees.y = 180.0 / float(ASPAS) * float(i)


## Gramola: mueble de madera, plato con su disco y la bocina de latón.
static func tocadiscos(padre: Node3D) -> void:
	Piezas.caja(padre, Vector3.ZERO, Vector3(0.5, 0.75, 0.45), Cosas.mat(Cosas.MADERA))
	Cosas.cilindro(padre, Vector3(0.0, 0.75, 0.0), 0.16, 0.02, Cosas.mat(Cosas.HIERRO))
	var bocina := CylinderMesh.new()
	bocina.top_radius = 0.18
	bocina.bottom_radius = 0.03
	bocina.height = 0.45
	var cono := MeshInstance3D.new()
	cono.mesh = bocina
	cono.material_override = Cosas.mat(LATON, 0.8)
	cono.position = Vector3(0.12, 1.05, -0.08)
	cono.rotation_degrees.x = 35.0 # la boca hacia la sala
	padre.add_child(cono)


## Terminal de pantalla verde sobre su mesa (la única pantalla de la época, siempre encendida).
static func terminal(padre: Node3D) -> void:
	Piezas.caja(padre, Vector3.ZERO, Vector3(1.0, 0.75, 0.6), Cosas.mat(Cosas.MADERA))
	Piezas.caja(padre, Vector3(0.0, 0.75, -0.05), Vector3(0.5, 0.42, 0.42), Cosas.mat(PINTURA_MAQUINA, 0.3))
	var pantalla := Cosas.mat(VERDE_PANTALLA)
	(pantalla as StandardMaterial3D).emission_enabled = true
	(pantalla as StandardMaterial3D).emission = VERDE_PANTALLA
	Piezas.caja(padre, Vector3(0.0, 0.82, 0.165), Vector3(0.38, 0.28, 0.01), pantalla)
	Piezas.caja(padre, Vector3(0.0, 0.75, 0.24), Vector3(0.45, 0.04, 0.16), Cosas.mat(PINTURA_MAQUINA, 0.3))


## Generador diésel en su bancada, con el tubo de escape y el cable que entra en la casa (al este de la pieza).
static func generador(padre: Node3D) -> void:
	var maquina: Material = Cosas.mat(PINTURA_MAQUINA, 0.4)
	Piezas.caja(padre, Vector3.ZERO, Vector3(0.85, 0.12, 1.2), Cosas.mat(Cosas.HIERRO, 0.6))
	Piezas.caja(padre, Vector3(0.0, 0.12, 0.15), Vector3(0.75, 0.65, 0.8), maquina)
	Cosas.cilindro(padre, Vector3(0.0, 0.12, -0.42), 0.18, 0.5, maquina)
	Cosas.cilindro(padre, Vector3(-0.25, 0.77, 0.3), 0.04, 0.6, Cosas.mat(Cosas.HIERRO, 0.6))
	Piezas.caja(padre, Vector3(0.65, 0.5, 0.0), Vector3(0.9, CABLE_RADIO_M, CABLE_RADIO_M), Cosas.mat(Cosas.HIERRO))


## Un tramo recto del cable grueso que va por la fachada del generador al cuadro: `medida` es la caja del tramo y
## `alto`, a qué altura empieza (cada tramo del recorrido es una línea del plano).
static func cable(padre: Node3D, medida: Vector3, alto: float) -> void:
	Piezas.caja(padre, Vector3(0.0, alto, 0.0), medida, Cosas.mat(Cosas.HIERRO))


## Cuadro eléctrico en la fachada: caja de chapa, dos seccionadores de cobre y el piloto que el juego pone verde o rojo.
static func cuadro_electrico(padre: Node3D) -> void:
	Piezas.caja(padre, Vector3(0.0, 1.1, 0.0), Vector3(0.6, 0.8, 0.14), Cosas.mat(Cosas.HIERRO, 0.5))
	for x: float in [-0.13, 0.13]:
		Piezas.caja(padre, Vector3(x, 1.4, 0.075), Vector3(0.06, 0.2, 0.04), Cosas.mat(LATON, 0.8))
	var piloto: MeshInstance3D = Piezas.caja(padre, Vector3(0.0, 1.2, 0.075), Vector3(0.08, 0.08, 0.03), Cosas.mat(VERDE_PANTALLA))
	piloto.set_meta(PARTES.ROL, PARTES.BOMBILLA_CUADRO)
