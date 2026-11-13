extends RefCounted

## Cosas armadas a mano del molino abandonado (Caso I, 2026-11-13), para lo que no hay modelo comprado: el foso del
## sótano con su reja al canal de la rueda, una muela de piedra rota, el rollo de cordel encerado y la hoja de papel de
## la mesa. Metros respecto a la pieza (tools/casas/armar_casa.gd las dibuja); el suelo de la pieza es y = 0.

const Piezas = preload("res://tools/casas/piezas_casa.gd")
const Cosas = preload("res://tools/casas/cosas_casa.gd")

const NEGRO := Color(0.04, 0.04, 0.05)
const HIERRO := Color(0.22, 0.2, 0.19)
const PIEDRA := Color(0.52, 0.5, 0.47)
const CANAMO := Color(0.66, 0.56, 0.36)
const PAPEL := Color(0.9, 0.87, 0.78)
const FOSO_TAM := Vector2(1.2, 1.2)
const BROCAL_M: float = 0.12          ## el reborde de tablas alrededor del foso
const BROCAL_ALTO_M: float = 0.05
const BARROTES: int = 6
const DOBLADOS: Array[int] = [2, 3]   ## los dos barrotes del medio
const DOBLEZ_GRADOS: float = -12.0
const BARROTE_GROSOR_M: float = 0.04
const MUELA_RADIO_M: float = 0.55
const MUELA_GRUESO_M: float = 0.22
const MUELA_TROZO_M: float = 0.35     ## lo que se separa el trozo partido de la muela
const TROZO_GIRO := Vector3(0.0, 30.0, 18.0)   ## el trozo partido, caído de canto
const CORDEL_RADIO_M: float = 0.12
const CORDEL_ALTO_M: float = 0.1
const PAPEL_TAM := Vector3(0.21, 0.005, 0.3)
const PAPEL_GIRO_GRADOS: float = 15.0


## El foso del sótano: un hueco negro con brocal de madera y la reja de hierro encima (dos barrotes doblados hacia arriba:
## por ahí salió alguien al canal).
static func foso_reja(padre: Node3D) -> void:
	Piezas.caja(padre, Vector3.ZERO, Vector3(FOSO_TAM.x, 0.01, FOSO_TAM.y), Cosas.mat(NEGRO))
	var madera: Material = Cosas.mat(Cosas.MADERA)
	for lado: float in [-1.0, 1.0]:
		var borde_z := Vector3(0.0, 0.0, lado * (FOSO_TAM.y + BROCAL_M) * 0.5)
		Piezas.caja(padre, borde_z, Vector3(FOSO_TAM.x + BROCAL_M * 2.0, BROCAL_ALTO_M, BROCAL_M), madera)
		var borde_x := Vector3(lado * (FOSO_TAM.x + BROCAL_M) * 0.5, 0.0, 0.0)
		Piezas.caja(padre, borde_x, Vector3(BROCAL_M, BROCAL_ALTO_M, FOSO_TAM.y), madera)
	var hierro: Material = Cosas.mat(HIERRO, 0.6)
	for i: int in range(BARROTES):
		var x: float = (float(i) + 0.5) / float(BARROTES) * FOSO_TAM.x - FOSO_TAM.x * 0.5
		var barrote: MeshInstance3D = Piezas.caja(padre, Vector3(x, BROCAL_ALTO_M, 0.0), Vector3(BARROTE_GROSOR_M, BARROTE_GROSOR_M, FOSO_TAM.y), hierro)
		if DOBLADOS.has(i):
			barrote.rotation_degrees.x = DOBLEZ_GRADOS   # doblados hacia arriba
	Piezas.caja(padre, Vector3(0.0, BROCAL_ALTO_M, 0.0), Vector3(FOSO_TAM.x, BARROTE_GROSOR_M, BARROTE_GROSOR_M), hierro)


## Una muela de piedra del molino, partida en dos y caída en el suelo.
static func muela_rota(padre: Node3D) -> void:
	var piedra: Material = Piezas.material("wall_stone.png", PIEDRA)
	Cosas.cilindro(padre, Vector3.ZERO, MUELA_RADIO_M, MUELA_GRUESO_M, piedra)
	var trozo := Node3D.new()
	trozo.position = Vector3(MUELA_RADIO_M + MUELA_TROZO_M, 0.0, 0.0)
	trozo.rotation_degrees = TROZO_GIRO
	padre.add_child(trozo)
	Cosas.cilindro(trozo, Vector3.ZERO, MUELA_RADIO_M * 0.6, MUELA_GRUESO_M, piedra)


## El rollo de cordel de cáñamo encerado, sobre el banco (`alto`: la altura del banco).
static func cordel(padre: Node3D, alto: float) -> void:
	Cosas.cilindro(padre, Vector3(0.0, alto, 0.0), CORDEL_RADIO_M, CORDEL_ALTO_M, Cosas.mat(CANAMO))
	Cosas.cilindro(padre, Vector3(0.0, alto, 0.0), CORDEL_RADIO_M * 0.4, CORDEL_ALTO_M + 0.01, Cosas.mat(NEGRO))


## La hoja doblada encima de la mesa (`alto`: la altura de la mesa).
static func papel(padre: Node3D, alto: float) -> void:
	Piezas.caja(padre, Vector3(0.0, alto, 0.0), PAPEL_TAM, Cosas.mat(PAPEL), PAPEL_GIRO_GRADOS)
