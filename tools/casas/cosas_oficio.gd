extends RefCounted

## Cosas armadas a mano propias de un oficio (2026-11-13), para lo que no hay modelo comprado: el horno de pan.
## Metros respecto a la pieza (tools/casas/armar_casa.gd las dibuja); el suelo de la pieza es y = 0; la boca del
## horno mira al sur (+z) sin giro.

const Piezas = preload("res://tools/casas/piezas_casa.gd")
const Cosas = preload("res://tools/casas/cosas_casa.gd")

const LADRILLO := "wall_brick_small_sand.png"
const TINTE_LADRILLO := Color(0.85, 0.6, 0.45)
const BOCA := Color(0.08, 0.06, 0.05)
const BRASA := Color(0.6, 0.22, 0.06)
const HORNO_TAM := Vector3(1.4, 0.9, 1.1)     ## la base de obra donde se apoya la bóveda
const BOVEDA_RADIO_M: float = 0.6
const BOCA_TAM := Vector3(0.5, 0.3, 0.05)
const BRASAS_TAM := Vector3(0.4, 0.06, 0.06)
const CHIMENEA_RADIO_M: float = 0.1
const CHIMENEA_ALTO_M: float = 1.4
const PALA_LARGO_M: float = 1.6


## Horno de leña de ladrillo: base de obra, bóveda redonda, boca con brasas y su chimenea; la pala de pie al lado.
static func horno(padre: Node3D) -> void:
	var ladrillo: Material = Piezas.material(LADRILLO, TINTE_LADRILLO)
	Piezas.caja(padre, Vector3.ZERO, HORNO_TAM, ladrillo)
	var forma := SphereMesh.new()
	forma.radius = BOVEDA_RADIO_M
	forma.height = BOVEDA_RADIO_M # media esfera: la altura es el radio
	forma.is_hemisphere = true
	var boveda := MeshInstance3D.new()
	boveda.mesh = forma
	boveda.material_override = ladrillo
	boveda.position = Vector3(0.0, HORNO_TAM.y, 0.0)
	padre.add_child(boveda)
	var brasa := Cosas.mat(BRASA)
	(brasa as StandardMaterial3D).emission_enabled = true
	(brasa as StandardMaterial3D).emission = BRASA
	Piezas.caja(padre, Vector3(0.0, HORNO_TAM.y, BOVEDA_RADIO_M - 0.02), BOCA_TAM, Cosas.mat(BOCA))
	Piezas.caja(padre, Vector3(0.0, HORNO_TAM.y, BOVEDA_RADIO_M + 0.01), BRASAS_TAM, brasa)
	Cosas.cilindro(padre, Vector3(0.0, HORNO_TAM.y + BOVEDA_RADIO_M * 0.6, -0.25), CHIMENEA_RADIO_M, CHIMENEA_ALTO_M, ladrillo)
	Piezas.caja(padre, Vector3(HORNO_TAM.x * 0.5 + 0.06, 0.0, 0.3), Vector3(0.04, PALA_LARGO_M, 0.04), Cosas.mat(Cosas.MADERA))
	Piezas.caja(padre, Vector3(HORNO_TAM.x * 0.5 + 0.06, PALA_LARGO_M, 0.3), Vector3(0.03, 0.35, 0.3), Cosas.mat(Cosas.MADERA))
