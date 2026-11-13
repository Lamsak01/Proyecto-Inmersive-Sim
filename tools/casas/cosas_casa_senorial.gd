extends RefCounted

## Cosas armadas a mano para las casas del señor y las autoridades (nivel 4, 2026-11-13): lo que solo tiene quien
## tiene generador propio y cobra rentas: teléfono de baquelita, nevera, lámpara de techo de varias bombillas,
## chimenea de piedra labrada, candelabro de latón y retratos de los antepasados.
## Metros respecto a la pieza (tools/casas/armar_casa.gd las dibuja); el suelo de la pieza es y = 0; sin giro, lo
## que tiene frente mira al sur (+z).

const Piezas = preload("res://tools/casas/piezas_casa.gd")
const Cosas = preload("res://tools/casas/cosas_casa.gd")
const Pobre = preload("res://tools/casas/cosas_casa_pobre.gd")

const LATON := Color(0.78, 0.62, 0.3)
const ESMALTE := Color(0.9, 0.9, 0.86)
const MARMOL := Color(0.82, 0.8, 0.76)
const LIENZO := Color(0.32, 0.22, 0.16)       ## el óleo oscuro de los retratos viejos
const BRAZOS_LAMPARA: int = 4
const RADIO_LAMPARA_M: float = 0.45
const LAMPARA_ALCANCE_M: float = 9.0          ## alumbra un salón entero, no un cuarto
const LAMPARA_ENERGIA: float = 1.8
const BRAZOS_CANDELABRO: Array[float] = [-0.12, 0.0, 0.12]


## Teléfono de baquelita con su disco y el auricular colgado. `alto`: la mesa en que está.
static func telefono(padre: Node3D, alto: float) -> void:
	var baquelita: Material = Cosas.mat(Cosas.BAQUELITA, 0.2)
	Piezas.caja(padre, Vector3(0.0, alto, 0.0), Vector3(0.2, 0.1, 0.22), baquelita)
	Cosas.cilindro(padre, Vector3(0.0, alto + 0.1, 0.04), 0.06, 0.01, Cosas.mat(Cosas.DIAL))
	Piezas.caja(padre, Vector3(0.0, alto + 0.12, -0.05), Vector3(0.24, 0.05, 0.06), baquelita)


## Nevera de esmalte blanco con tirador de latón (la enfría el generador de la casa).
static func nevera(padre: Node3D) -> void:
	Piezas.caja(padre, Vector3.ZERO, Vector3(0.75, 1.7, 0.7), Cosas.mat(ESMALTE, 0.3))
	Piezas.caja(padre, Vector3(0.0, 1.15, 0.36), Vector3(0.74, 0.01, 0.01), Cosas.mat(Cosas.HIERRO))
	Piezas.caja(padre, Vector3(0.28, 0.75, 0.37), Vector3(0.04, 0.3, 0.04), Cosas.mat(LATON, 0.8))


## Lámpara de techo: aro de latón con cuatro bombillas y una sola luz grande. `alto`: del suelo al techo.
static func lampara(padre: Node3D, alto: float) -> void:
	var laton: Material = Cosas.mat(LATON, 0.8)
	Cosas.cilindro(padre, Vector3(0.0, alto - 0.7, 0.0), 0.01, 0.7, laton)
	Cosas.cilindro(padre, Vector3(0.0, alto - 0.75, 0.0), RADIO_LAMPARA_M, 0.04, laton)
	for i: int in range(BRAZOS_LAMPARA):
		var brazo: Vector2 = Vector2.RIGHT.rotated(TAU / float(BRAZOS_LAMPARA) * float(i)) * RADIO_LAMPARA_M
		Cosas.cilindro(padre, Vector3(brazo.x, alto - 0.71, brazo.y), 0.03, 0.05, laton)
	Cosas.luz(padre, Vector3(0.0, alto - 0.8, 0.0), Cosas.LUZ_BOMBILLA, 0.08, LAMPARA_ALCANCE_M, LAMPARA_ENERGIA)


## Chimenea de piedra labrada con repisa de mármol y el fuego encendido; el tiro sube hasta el techo.
static func chimenea(padre: Node3D) -> void:
	var piedra: Material = Piezas.material("wall_brick_small_stone.png", Cosas.PIEDRA)
	var marmol: Material = Cosas.mat(MARMOL, 0.1)
	Piezas.caja(padre, Vector3.ZERO, Vector3(2.0, 0.15, 0.9), marmol)
	Piezas.caja(padre, Vector3(0.0, 0.15, -0.35), Vector3(1.6, 1.1, 0.1), Cosas.mat(Pobre.HOLLIN))
	for lado: float in [-1.0, 1.0]:
		Piezas.caja(padre, Vector3(lado * 0.85, 0.15, -0.05), Vector3(0.3, 1.1, 0.7), piedra)
	Piezas.caja(padre, Vector3(0.0, 1.25, -0.05), Vector3(2.2, 0.12, 0.8), marmol)
	Piezas.caja(padre, Vector3(0.0, 1.37, -0.2), Vector3(1.4, Cosas.TECHO_M - 1.37, 0.5), piedra)
	Pobre.lena(padre)
	Cosas.luz(padre, Vector3(0.0, 0.3, 0.1), Pobre.LLAMA, 0.14, Pobre.LUMBRE_ALCANCE_M, Pobre.LUMBRE_ENERGIA)


## Candelabro de latón de tres velas sobre la mesa de los banquetes. `alto`: la mesa.
static func candelabro(padre: Node3D, alto: float) -> void:
	Cosas.cilindro(padre, Vector3(0.0, alto, 0.0), 0.015, 0.3, Cosas.mat(LATON, 0.8))
	Piezas.caja(padre, Vector3(0.0, alto + 0.28, 0.0), Vector3(0.3, 0.02, 0.02), Cosas.mat(LATON, 0.8))
	for x: float in BRAZOS_CANDELABRO:
		_vela_en(padre, Vector3(x, alto + 0.3, 0.0))


## Retrato de un antepasado colgado en la pared: marco dorado y lienzo oscuro (mira al sur, hacia el cuarto).
static func retrato(padre: Node3D) -> void:
	Piezas.caja(padre, Vector3(0.0, 1.3, 0.0), Vector3(0.75, 0.95, 0.05), Cosas.mat(LATON, 0.7))
	Piezas.caja(padre, Vector3(0.0, 1.37, 0.026), Vector3(0.6, 0.8, 0.01), Cosas.mat(LIENZO))


static func _vela_en(padre: Node3D, en: Vector3) -> void:
	var sitio := Node3D.new()
	sitio.position = Vector3(en.x, 0.0, en.z)
	padre.add_child(sitio)
	Pobre.vela(sitio, en.y)
