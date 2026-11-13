extends RefCounted

## Cosas armadas a mano propias de un oficio (2026-11-13), para lo que no hay modelo comprado: el horno de pan, la
## reja corredera del calabozo de la comisaría, la pizarra de la escuela y las mesas de la morgue con su cuerpo bajo la sábana.
## Metros respecto a la pieza (tools/casas/armar_casa.gd las dibuja); el suelo de la pieza es y = 0; la boca del
## horno mira al sur (+z) sin giro.

const Piezas = preload("res://tools/casas/piezas_casa.gd")
const Cosas = preload("res://tools/casas/cosas_casa.gd")
const PARTES = preload("res://scripts/visuals/PartesEdificio3D.gd")
const Marca = preload("res://mapa/marca.gd")

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
const HIERRO := Color(0.2, 0.21, 0.23)
const BARROTE_GROSOR_M: float = 0.04
const BARROTE_PASO_M: float = 0.15     ## de barrote a barrote
const REJA_ALTO_M: float = 2.2
const TRAVESANO_ALTO_M: float = 0.05
const ACERO := Color(0.62, 0.64, 0.66)
const SABANA := Color(0.88, 0.88, 0.84)
const MADERA_MARCO := Color(0.4, 0.26, 0.14)
const PIZARRA_VERDE := Color(0.12, 0.2, 0.16)
const PIZARRA_TAM := Vector3(2.2, 1.1, 0.04)   ## colgada de la pared, de cara al sur (+z) sin giro
const PIZARRA_ALTO_M: float = 0.95           ## altura de su borde de abajo
const MARCO_M: float = 0.06
const MESA_MORGUE_TAM := Vector3(0.8, 0.85, 1.9)  ## tablero de acero sobre cuatro patas (su choque lo pone el juego)
const TABLERO_GROSOR_M: float = 0.05
const PATA_GROSOR_M: float = 0.06
const CUERPO_TAM := Vector3(0.5, 0.22, 1.7)       ## el bulto bajo la sábana…
const CABEZA_TAM := Vector3(0.24, 0.18, 0.26)     ## …y la cabeza, más alta, hacia el norte


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


## Reja corredera del calabozo («REJA» del plano: centro del hueco y ancho): barrotes de hierro con tres travesaños. Su
## pivote queda en la punta oeste del hueco; el juego la desliza hacia el oeste al abrirla (rol «reja_celda»).
static func reja_celda(interior: Node3D, reja: Dictionary, suelo_y: float) -> void:
	var en: Vector2 = reja["en"]
	var ancho: float = reja["ancho"]
	var pivote := Node3D.new()
	pivote.name = "RejaCelda"
	pivote.position = Vector3(en.x - ancho * 0.5, suelo_y, en.y)
	pivote.set_meta(PARTES.ROL, PARTES.REJA_CELDA)
	interior.add_child(pivote)
	var hierro: Material = Piezas.material("", HIERRO, 0.7)
	var x: float = BARROTE_PASO_M * 0.5
	while x < ancho:
		Piezas.caja(pivote, Vector3(x, 0.0, 0.0), Vector3(BARROTE_GROSOR_M, REJA_ALTO_M, BARROTE_GROSOR_M), hierro)
		x += BARROTE_PASO_M
	for alto: float in [0.0, REJA_ALTO_M * 0.5, REJA_ALTO_M - TRAVESANO_ALTO_M]:
		Piezas.caja(pivote, Vector3(ancho * 0.5, alto, 0.0), Vector3(ancho, TRAVESANO_ALTO_M, BARROTE_GROSOR_M * 1.5), hierro)


## Mesa de autopsias de acero, a lo largo de z (la cosa «mesa_morgue» de un plano).
static func mesa_morgue(padre: Node3D) -> void:
	var acero: Material = Piezas.material("", ACERO, 0.8)
	var t: Vector3 = MESA_MORGUE_TAM
	Piezas.caja(padre, Vector3(0.0, t.y - TABLERO_GROSOR_M, 0.0), Vector3(t.x, TABLERO_GROSOR_M, t.z), acero)
	for esquina: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var en := Vector3(esquina.x * (t.x - PATA_GROSOR_M) * 0.5, 0.0, esquina.y * (t.z - PATA_GROSOR_M) * 0.5)
		Piezas.caja(padre, en, Vector3(PATA_GROSOR_M, t.y - TABLERO_GROSOR_M, PATA_GROSOR_M), acero)


## Un cuerpo bajo la sábana sobre cada mesa de la morgue (marcas «mesa_morgue_1», «_2»…, en orden): escondidos; el juego
## enseña tantos como muertos haya (rol «cuerpo_morgue»).
static func cuerpos_morgue(interior: Node3D, marcas: Dictionary, suelo_y: float) -> void:
	var sabana: Material = Piezas.material("", SABANA)
	var i: int = 1
	while marcas.has(Marca.MESA_MORGUE % i):
		var en: Vector2 = marcas[Marca.MESA_MORGUE % i]
		var cuerpo := Node3D.new()
		cuerpo.name = "CuerpoMorgue%d" % i
		cuerpo.position = Vector3(en.x, suelo_y + MESA_MORGUE_TAM.y, en.y)
		cuerpo.visible = false
		cuerpo.set_meta(PARTES.ROL, PARTES.CUERPO_MORGUE)
		interior.add_child(cuerpo)
		Piezas.caja(cuerpo, Vector3.ZERO, CUERPO_TAM, sabana)
		Piezas.caja(cuerpo, Vector3(0.0, 0.0, -(CUERPO_TAM.z - CABEZA_TAM.z) * 0.5), CABEZA_TAM + Vector3(0.0, CUERPO_TAM.y, 0.0), sabana)
		i += 1


## La pizarra de la escuela: un marco de madera con la losa verde delante, pegada a la pared.
static func pizarra(padre: Node3D) -> void:
	var marco := PIZARRA_TAM + Vector3(MARCO_M, MARCO_M, 0.0) * 2.0
	Piezas.caja(padre, Vector3(0.0, PIZARRA_ALTO_M - MARCO_M, 0.0), marco, Cosas.mat(MADERA_MARCO))
	Piezas.caja(padre, Vector3(0.0, PIZARRA_ALTO_M, PIZARRA_TAM.z), PIZARRA_TAM, Cosas.mat(PIZARRA_VERDE))
