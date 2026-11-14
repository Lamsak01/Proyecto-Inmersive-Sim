extends RefCounted

## Piezas 3D propias de la Casa de Comidas / Trattoria «Il Corvo» (2026-11-14, Tarea 4): terraza empedrada con toldo y
## guirnalda de luces nocturnas, veladores redondos con sombrilla, manteles con botella de Chianti, piano vertical,
## fogones industriales con campana extractora, cámara fría con reses colgadas y bloques de hielo, y mesa del reservado.

const Piezas = preload("res://tools/casas/piezas_casa.gd")
const Cosas = preload("res://tools/casas/cosas_casa.gd")

const CAOBA := Color(0.26, 0.13, 0.08)
const ROBLE := Color(0.38, 0.24, 0.13)
const CREMA := Color(0.93, 0.89, 0.79)
const VERDE_TOLDO := Color(0.16, 0.38, 0.23)
const ROJO_VINO := Color(0.56, 0.13, 0.14)
const COBRE := Color(0.74, 0.43, 0.24)
const HIELO := Color(0.76, 0.89, 0.96)
const CARNE := Color(0.54, 0.17, 0.16)
const BARRO := Color(0.66, 0.34, 0.20)
const CIPRES := Color(0.18, 0.36, 0.18)
const LUZ_CALIDA := Color(1.0, 0.84, 0.52)


static func _cono(padre: Node3D, base: Vector3, r_abajo: float, r_arriba: float, alto: float, mat: Material, lados: int = 8) -> void:
	var forma := CylinderMesh.new()
	forma.bottom_radius = r_abajo
	forma.top_radius = r_arriba
	forma.height = alto
	forma.radial_segments = lados
	var mi := MeshInstance3D.new()
	mi.mesh = forma
	mi.material_override = mat
	mi.position = base + Vector3(0.0, alto * 0.5, 0.0)
	padre.add_child(mi)


static func _botella_vela(padre: Node3D, base: Vector3) -> void:
	Cosas.cilindro(padre, base, 0.055, 0.16, Cosas.mat(VERDE_TOLDO))
	Cosas.cilindro(padre, base + Vector3(0.0, 0.16, 0.0), 0.022, 0.08, Cosas.mat(VERDE_TOLDO))
	Cosas.cilindro(padre, base + Vector3(0.0, 0.24, 0.0), 0.015, 0.11, Cosas.mat(CREMA))


## Losa de piedra de la terraza sur (15,4 × 2,30 × 0,19 m), escalón de entrada, toldo italiano, cipreses y guirnalda nocturna.
static func terraza_trattoria(padre: Node3D) -> void:
	var losa: Material = Piezas.material("floor_stone_pattern.png", Color(0.86, 0.80, 0.72))
	var hierro: Material = Cosas.mat(Cosas.HIERRO, 0.65)
	var verde: Material = Cosas.mat(VERDE_TOLDO)
	var crema: Material = Cosas.mat(CREMA)
	Piezas.caja(padre, Vector3.ZERO, Vector3(15.4, 0.19, 2.30), losa)
	Piezas.caja(padre, Vector3(-2.1, 0.0, 1.38), Vector3(2.4, 0.10, 0.48), losa)
	Piezas.caja(padre, Vector3(-2.1, 2.62, -0.92), Vector3(2.8, 0.09, 1.12), verde)
	Piezas.caja(padre, Vector3(-2.1, 2.44, -0.37), Vector3(2.8, 0.20, 0.06), crema)
	for x: float in [-7.35, -2.65, 2.25, 7.35]:
		Cosas.cilindro(padre, Vector3(x, 0.19, 1.02), 0.038, 2.55, hierro)
	Piezas.caja(padre, Vector3(0.0, 2.71, 1.02), Vector3(14.7, 0.025, 0.025), hierro)
	for bx: float in [-5.8, -3.1, -0.3, 2.5, 5.4]:
		Cosas.luz(padre, Vector3(bx, 2.63, 1.02), LUZ_CALIDA, 0.06, 5.5, 1.05)
	for cx: float in [-7.25, 7.25]:
		_cono(padre, Vector3(cx, 0.19, 0.82), 0.18, 0.24, 0.42, Cosas.mat(BARRO))
		_cono(padre, Vector3(cx, 0.61, 0.82), 0.27, 0.05, 0.78, Cosas.mat(CIPRES))


## Velador redondo de terraza con sombrilla verde o crema y botella con vela.
static func mesa_terraza(padre: Node3D, verde: bool) -> void:
	var hierro: Material = Cosas.mat(Cosas.HIERRO, 0.6)
	var madera: Material = Cosas.mat(ROBLE)
	Cosas.cilindro(padre, Vector3.ZERO, 0.25, 0.03, hierro)
	Cosas.cilindro(padre, Vector3(0.0, 0.03, 0.0), 0.045, 0.70, hierro)
	Cosas.cilindro(padre, Vector3(0.0, 0.73, 0.0), 0.47, 0.05, madera)
	Cosas.cilindro(padre, Vector3(0.0, 0.78, 0.0), 0.024, 1.38, hierro)
	_cono(padre, Vector3(0.0, 2.02, 0.0), 1.02, 0.07, 0.34, Cosas.mat(VERDE_TOLDO if verde else CREMA))
	_botella_vela(padre, Vector3(0.10, 0.78, -0.06))


## Camino de mesa de trattoria con franja vino y botella con vela encima del tablero de madera.
static func mantel_trattoria(padre: Node3D) -> void:
	Piezas.caja(padre, Vector3.ZERO, Vector3(0.96, 0.018, 0.72), Cosas.mat(CREMA))
	Piezas.caja(padre, Vector3(0.0, 0.018, 0.0), Vector3(0.96, 0.008, 0.22), Cosas.mat(ROJO_VINO))
	_botella_vela(padre, Vector3(0.0, 0.026, 0.0))


## Piano vertical de caoba con teclado de marfil, atril con partitura y pedales de latón (de cara a +z).
static func piano_vertical(padre: Node3D) -> void:
	var caoba: Material = Cosas.mat(CAOBA)
	Piezas.caja(padre, Vector3(0.0, 0.0, -0.06), Vector3(1.36, 1.16, 0.44), caoba)
	Piezas.caja(padre, Vector3(0.0, 0.68, 0.16), Vector3(1.32, 0.10, 0.26), caoba)
	Piezas.caja(padre, Vector3(0.0, 0.78, 0.18), Vector3(1.18, 0.03, 0.16), Cosas.mat(CREMA))
	Piezas.caja(padre, Vector3(0.0, 0.81, 0.13), Vector3(1.10, 0.02, 0.07), Cosas.mat(Cosas.HIERRO))
	Piezas.caja(padre, Vector3(0.0, 0.86, 0.02), Vector3(0.36, 0.24, 0.02), Cosas.mat(CREMA))
	for px: float in [-0.56, 0.56]:
		Piezas.caja(padre, Vector3(px, 0.0, 0.18), Vector3(0.08, 0.68, 0.08), caoba)
	for pd: float in [-0.08, 0.08]:
		Piezas.caja(padre, Vector3(pd, 0.03, 0.18), Vector3(0.04, 0.03, 0.12), Cosas.mat(COBRE, 0.75))


## Fogones industriales de hierro con fuegos encendidos, olla de cobre, sartén y campana extractora de cinc hasta el techo.
static func fogones_trattoria(padre: Node3D) -> void:
	var hierro: Material = Cosas.mat(Cosas.HIERRO, 0.65)
	var cinc: Material = Cosas.mat(Cosas.CINC, 0.75)
	var brasa: Material = Cosas.mat(Color(0.95, 0.42, 0.10))
	(brasa as StandardMaterial3D).emission_enabled = true
	(brasa as StandardMaterial3D).emission = Color(0.95, 0.42, 0.10)
	Piezas.caja(padre, Vector3.ZERO, Vector3(1.56, 0.86, 0.72), hierro)
	Piezas.caja(padre, Vector3(0.0, 0.86, 0.0), Vector3(1.60, 0.04, 0.76), cinc)
	for fx: float in [-0.46, 0.0, 0.46]:
		Cosas.cilindro(padre, Vector3(fx, 0.90, 0.10), 0.13, 0.02, brasa)
	Cosas.cilindro(padre, Vector3(-0.46, 0.92, 0.10), 0.17, 0.24, Cosas.mat(COBRE, 0.7))
	Cosas.cilindro(padre, Vector3(0.46, 0.92, 0.10), 0.15, 0.07, hierro)
	Piezas.caja(padre, Vector3(0.0, 1.92, 0.0), Vector3(1.68, 0.30, 0.82), cinc)
	Piezas.caja(padre, Vector3(0.0, 2.22, -0.10), Vector3(0.36, 0.80, 0.32), cinc)


## Cámara frigorífica: barra de acero con cuatro piezas de carne colgadas y bloques de hielo sobre palé de madera.
static func camara_fria(padre: Node3D) -> void:
	var acero: Material = Cosas.mat(Cosas.CINC, 0.85)
	var hielo: Material = Cosas.mat(HIELO)
	for x: float in [-1.05, 1.05]:
		Piezas.caja(padre, Vector3(x, 0.0, -0.10), Vector3(0.06, 2.10, 0.06), acero)
	Piezas.caja(padre, Vector3(0.0, 2.04, -0.10), Vector3(2.20, 0.05, 0.05), acero)
	for mx: float in [-0.72, -0.24, 0.24, 0.72]:
		Piezas.caja(padre, Vector3(mx, 1.88, -0.10), Vector3(0.02, 0.18, 0.02), acero)
		_cono(padre, Vector3(mx, 1.18, -0.10), 0.11, 0.16, 0.70, Cosas.mat(CARNE))
	Piezas.caja(padre, Vector3(-1.35, 0.0, 0.45), Vector3(0.76, 0.08, 0.95), Cosas.mat(ROBLE))
	Piezas.caja(padre, Vector3(-1.35, 0.08, 0.22), Vector3(0.56, 0.38, 0.38), hielo)
	Piezas.caja(padre, Vector3(-1.35, 0.08, 0.66), Vector3(0.56, 0.38, 0.38), hielo)
	Piezas.caja(padre, Vector3(-1.35, 0.46, 0.44), Vector3(0.52, 0.34, 0.40), hielo)


## Mesa redonda del reservado con mantel blanco y candelabro encendido para las reuniones nocturnas.
static func mesa_reservado(padre: Node3D) -> void:
	Cosas.cilindro(padre, Vector3.ZERO, 0.32, 0.05, Cosas.mat(CAOBA))
	Cosas.cilindro(padre, Vector3(0.0, 0.05, 0.0), 0.10, 0.68, Cosas.mat(CAOBA))
	Cosas.cilindro(padre, Vector3(0.0, 0.73, 0.0), 0.64, 0.05, Cosas.mat(CAOBA))
	Cosas.cilindro(padre, Vector3(0.0, 0.78, 0.0), 0.60, 0.02, Cosas.mat(CREMA))
	Cosas.cilindro(padre, Vector3(0.0, 0.80, 0.0), 0.04, 0.18, Cosas.mat(COBRE, 0.8))
	Cosas.luz(padre, Vector3(0.0, 1.02, 0.0), LUZ_CALIDA, 0.04, 4.5, 0.95)
