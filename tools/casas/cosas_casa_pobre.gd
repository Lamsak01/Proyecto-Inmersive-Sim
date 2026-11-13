extends RefCounted

## Cosas armadas a mano para las casas pobres (nivel 1, 2026-11-13): lumbre baja de piedra, leña, velas, tina de
## madera, y su poco de técnica: linterna de dinamo y radio de galena con auriculares (no hay luz de la red en casa).
## Metros respecto a la pieza (tools/casas/armar_casa.gd las dibuja); el suelo de la pieza es y = 0.

const Piezas = preload("res://tools/casas/piezas_casa.gd")
const Cosas = preload("res://tools/casas/cosas_casa.gd")

const PIEDRA := Color(0.5, 0.48, 0.45)
const HOLLIN := Color(0.12, 0.11, 0.1)
const TRONCO := Color(0.4, 0.27, 0.15)
const CERA := Color(0.92, 0.88, 0.75)
const COBRE := Color(0.72, 0.42, 0.22)
const LLAMA := Color(1.0, 0.62, 0.3)
const LUMBRE_ALCANCE_M: float = 5.0
const LUMBRE_ENERGIA: float = 1.6
const VELA_ALCANCE_M: float = 3.0
const VELA_ENERGIA: float = 0.5
const TECHO_M: float = 3.0                 ## campana de la lumbre hasta el techo (igual que el tubo de la estufa)
const TRONCOS_FILA: int = 4
const TRONCO_RADIO_M: float = 0.08
const TRONCO_LARGO_M: float = 0.6


## Lumbre de piedra contra la pared, con su olla y la campana de humos hasta el techo: cocina y calefacción a la vez.
static func hogar(padre: Node3D) -> void:
	var piedra: Material = Piezas.material("wall_stone.png", PIEDRA)
	Piezas.caja(padre, Vector3.ZERO, Vector3(1.4, 0.25, 0.8), piedra)
	Piezas.caja(padre, Vector3(0.0, 0.25, -0.35), Vector3(1.4, 1.2, 0.1), Cosas.mat(HOLLIN))
	for lado: float in [-1.0, 1.0]:
		Piezas.caja(padre, Vector3(lado * 0.65, 0.25, 0.0), Vector3(0.1, 1.2, 0.8), piedra)
	Piezas.caja(padre, Vector3(0.0, 1.45, -0.05), Vector3(1.5, 0.3, 0.9), piedra)
	Piezas.caja(padre, Vector3(0.0, 1.75, -0.15), Vector3(0.8, TECHO_M - 1.75, 0.6), piedra)
	Cosas.cilindro(padre, Vector3(0.0, 0.25, 0.0), 0.22, 0.3, Cosas.mat(HOLLIN, 0.5))
	Cosas.luz(padre, Vector3(0.0, 0.3, 0.15), LLAMA, 0.12, LUMBRE_ALCANCE_M, LUMBRE_ENERGIA)


## Montón de leña partida, en dos filas.
static func lena(padre: Node3D) -> void:
	var madera: Material = Cosas.mat(TRONCO)
	for fila: int in range(2):
		for i: int in range(TRONCOS_FILA - fila):
			var x: float = (float(i) - float(TRONCOS_FILA - fila - 1) * 0.5) * TRONCO_RADIO_M * 2.0
			_tronco(padre, Vector3(x, TRONCO_RADIO_M * (1.0 + 1.7 * float(fila)), 0.0), madera)


static func _tronco(padre: Node3D, centro: Vector3, madera: Material) -> void:
	var forma := CylinderMesh.new()
	forma.top_radius = TRONCO_RADIO_M
	forma.bottom_radius = TRONCO_RADIO_M
	forma.height = TRONCO_LARGO_M
	var mi := MeshInstance3D.new()
	mi.mesh = forma
	mi.material_override = madera
	mi.position = centro
	mi.rotation_degrees.x = 90.0 # tumbado, a lo largo de z
	padre.add_child(mi)


## Vela en su palmatoria a la altura `alto` (sobre una mesa o un taburete); solo se enciende de noche.
static func vela(padre: Node3D, alto: float) -> void:
	Cosas.cilindro(padre, Vector3(0.0, alto, 0.0), 0.06, 0.02, Cosas.mat(Cosas.HIERRO, 0.6))
	Cosas.cilindro(padre, Vector3(0.0, alto + 0.02, 0.0), 0.02, 0.14, Cosas.mat(CERA))
	Cosas.luz(padre, Vector3(0.0, alto + 0.19, 0.0), LLAMA, 0.015, VELA_ALCANCE_M, VELA_ENERGIA)


## Tajo: tocón grueso donde se parte la leña (o se desbasta la piedra).
static func tajo(padre: Node3D) -> void:
	Cosas.cilindro(padre, Vector3.ZERO, 0.3, 0.5, Cosas.mat(TRONCO))
	Cosas.cilindro(padre, Vector3(0.0, 0.5, 0.0), 0.28, 0.01, Cosas.mat(CERA))


## Tina de madera para bañarse (se llena a cubos desde el pozo).
static func tina(padre: Node3D) -> void:
	Cosas.cilindro(padre, Vector3.ZERO, 0.55, 0.5, Cosas.mat(TRONCO))
	Cosas.cilindro(padre, Vector3(0.0, 0.5, 0.0), 0.5, 0.01, Cosas.mat(Cosas.AGUA))
	for alto: float in [0.08, 0.38]:
		Cosas.cilindro(padre, Vector3(0.0, alto, 0.0), 0.56, 0.04, Cosas.mat(Cosas.HIERRO, 0.6))


## Radio de galena sobre un taburete: cajita de madera, bobina de cobre y auriculares (sin altavoz ni enchufe).
static func radio_galena(padre: Node3D) -> void:
	Piezas.caja(padre, Vector3.ZERO, Vector3(0.4, 0.55, 0.4), Cosas.mat(Cosas.MADERA))
	Piezas.caja(padre, Vector3(0.0, 0.55, 0.0), Vector3(0.3, 0.08, 0.2), Cosas.mat(TRONCO))
	Cosas.cilindro(padre, Vector3(-0.07, 0.63, 0.0), 0.04, 0.1, Cosas.mat(COBRE, 0.7))
	for x: float in [0.06, 0.13]:
		Cosas.cilindro(padre, Vector3(x, 0.63, 0.04), 0.03, 0.02, Cosas.mat(Cosas.BAQUELITA))


## Linterna de dinamo (se carga dando a la manivela) sobre un taburete junto a la cama.
static func linterna(padre: Node3D) -> void:
	Piezas.caja(padre, Vector3.ZERO, Vector3(0.35, 0.5, 0.35), Cosas.mat(Cosas.MADERA))
	Piezas.caja(padre, Vector3(0.0, 0.5, 0.0), Vector3(0.1, 0.08, 0.16), Cosas.mat(Cosas.HIERRO, 0.6))
	Cosas.cilindro(padre, Vector3(0.0, 0.53, 0.09), 0.035, 0.02, Cosas.mat(Cosas.CINC, 0.8))
	Piezas.caja(padre, Vector3(0.07, 0.54, 0.0), Vector3(0.03, 0.02, 0.08), Cosas.mat(Cosas.HIERRO, 0.6))
