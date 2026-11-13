extends RefCounted

## Cascarón de una casa del constructor (tools/casas/construir_casa.gd), 2026-11-13: zócalo, suelos de cada cuarto,
## los cuatro muros con su puerta y ventanas, y el tejado a dos aguas con sus hastiales.
## Metros respecto al centro de la casa; x al este, z al sur; la puerta de la calle en el muro sur.

const Piezas = preload("res://tools/casas/piezas_casa.gd")
const PARTES = preload("res://scripts/visuals/PartesEdificio3D.gd")

const SUELO_Y_M: float = 0.27          ## tarima de dentro de los edificios (Suelo.TARIMA_EDIFICIO_PX)
const MURO_ALTO_M: float = 3.3         ## de la calle al alero
const MURO_GROSOR_M: float = 0.25
const PUERTA_HUECO_ALTO_M: float = 2.2 ## sobre la tarima
const VENTANA_BASE_M: float = 1.0      ## del suelo de dentro al alféizar
const VENTANA_ALTO_M: float = 1.1
const ZOCALO_HONDO_M: float = 0.3
const ZOCALO_SOBRA_M: float = 0.15
const SUELO_GROSOR_M: float = 0.05
const TEJADO_ALTO_M: float = 1.8
const ALERO_M: float = 0.5
const TEJADO_GROSOR_M: float = 0.15
const CANDADO_TAM := Vector3(0.15, 0.3, 0.18)
const PIEDRA := Color(0.75, 0.73, 0.7)
const TINTE := Color(0.88, 0.84, 0.8)
const HIERRO := Color(0.22, 0.24, 0.28)


static func armar(muros: Node3D, tejado: Node3D, plano: GDScript) -> void:
	var medio: Vector2 = (plano.PLANTA_M as Vector2) * 0.5
	var zocalo_tam := Vector3(medio.x * 2.0 + ZOCALO_SOBRA_M * 2.0, ZOCALO_HONDO_M + SUELO_Y_M - SUELO_GROSOR_M, medio.y * 2.0 + ZOCALO_SOBRA_M * 2.0)
	Piezas.caja(muros, Vector3(0.0, -ZOCALO_HONDO_M, 0.0), zocalo_tam, Piezas.material(plano.ZOCALO, PIEDRA))
	for cuarto: Dictionary in plano.CUARTOS:
		var c: Vector2 = cuarto["centro"]
		var t: Vector2 = cuarto["tam"]
		Piezas.caja(muros, Vector3(c.x, SUELO_Y_M - SUELO_GROSOR_M, c.y), Vector3(t.x, SUELO_GROSOR_M, t.y), Piezas.material(cuarto["suelo"], TINTE))
	_muros(muros, plano, medio)
	_puerta(muros, plano, medio)
	_tejado(tejado, plano, medio)


## Los cuatro muros. Los del norte y el sur llegan hasta la cara de fuera de los otros dos (esquinas cerradas).
static func _muros(muros: Node3D, plano: GDScript, medio: Vector2) -> void:
	var fachada: Material = Piezas.material(plano.FACHADA, TINTE)
	var g: float = MURO_GROSOR_M * 0.5
	var lados: Dictionary = {
		"sur": [Vector2(-medio.x - g, medio.y), Vector2(medio.x + g, medio.y), medio.x + g],
		"norte": [Vector2(-medio.x - g, -medio.y), Vector2(medio.x + g, -medio.y), medio.x + g],
		"oeste": [Vector2(-medio.x, -medio.y), Vector2(-medio.x, medio.y), medio.y],
		"este": [Vector2(medio.x, -medio.y), Vector2(medio.x, medio.y), medio.y],
	}
	for lado: String in lados:
		var huecos: Array = []
		if lado == "sur":
			huecos.append({"en": plano.PUERTA_X_M + lados[lado][2], "ancho": plano.PUERTA_ANCHO_M, "alto": SUELO_Y_M + PUERTA_HUECO_ALTO_M})
		for v: Dictionary in plano.VENTANAS:
			if v["lado"] != lado:
				continue
			huecos.append({"en": float(v["en"]) + float(lados[lado][2]), "ancho": v["ancho"], "base": SUELO_Y_M + VENTANA_BASE_M, "alto": VENTANA_ALTO_M})
			_ventana(muros, plano, lado, v, medio)
		Piezas.muro(muros, lados[lado][0], lados[lado][1], 0.0, MURO_ALTO_M, MURO_GROSOR_M, huecos, fachada)


static func _ventana(muros: Node3D, plano: GDScript, lado: String, v: Dictionary, medio: Vector2) -> void:
	var y: float = SUELO_Y_M + VENTANA_BASE_M + VENTANA_ALTO_M * 0.5
	var en: float = float(v["en"])
	var sitios: Dictionary = {"sur": Vector3(en, y, medio.y), "norte": Vector3(en, y, -medio.y), "oeste": Vector3(-medio.x, y, en), "este": Vector3(medio.x, y, en)}
	var giro: float = 0.0 if lado in ["sur", "norte"] else 90.0
	var marco: Material = Piezas.material("", Color(0.32, 0.2, 0.11))
	var vidrio: Material = Piezas.material("window_square_divided.png", Color(0.8, 0.9, 1.0))
	Piezas.ventana(muros, sitios[lado], float(v["ancho"]), VENTANA_ALTO_M, giro, marco, vidrio, bool(v.get("abre", false)))


## Puerta de la calle: hoja que gira sobre su bisagra (la mueve el juego) y el candado, que solo se ve con llave.
static func _puerta(muros: Node3D, plano: GDScript, medio: Vector2) -> void:
	var ancho: float = plano.PUERTA_ANCHO_M
	var bisagra := Vector3(float(plano.PUERTA_X_M) - ancho * 0.5, SUELO_Y_M, medio.y)
	var pivote: Node3D = Piezas.hoja(muros, bisagra, ancho, false, Piezas.material("door_wood.png", TINTE))
	pivote.name = "Puerta"
	pivote.set_meta(PARTES.ROL, PARTES.PUERTA)
	var candado: MeshInstance3D = Piezas.caja(pivote, Vector3(ancho * 0.8, 1.0, 0.05), CANDADO_TAM, Piezas.material("", HIERRO, 0.75))
	candado.visible = false
	candado.set_meta(PARTES.ROL, PARTES.CANDADO)


## Tejado a dos aguas con la cumbrera de este a oeste, y los dos hastiales (triángulos de pared bajo él).
static func _tejado(tejado: Node3D, plano: GDScript, medio: Vector2) -> void:
	var tejas: Material = Piezas.material(plano.TEJADO, TINTE)
	var vuelo: float = medio.y + ALERO_M
	var largo: float = sqrt(vuelo * vuelo + TEJADO_ALTO_M * TEJADO_ALTO_M)
	var pendiente: float = atan(TEJADO_ALTO_M / vuelo)
	for lado: float in [-1.0, 1.0]:
		var forma := BoxMesh.new()
		forma.size = Vector3(medio.x * 2.0 + ALERO_M * 2.0, TEJADO_GROSOR_M, largo)
		var faldon := MeshInstance3D.new()
		faldon.mesh = forma
		faldon.material_override = tejas
		faldon.position = Vector3(0.0, MURO_ALTO_M + TEJADO_ALTO_M * 0.5, lado * vuelo * 0.5)
		faldon.rotation.x = pendiente * lado
		tejado.add_child(faldon)
		var hastial := PrismMesh.new()
		hastial.size = Vector3(medio.y * 2.0, TEJADO_ALTO_M, MURO_GROSOR_M)
		var pared := MeshInstance3D.new()
		pared.mesh = hastial
		pared.material_override = Piezas.material(plano.FACHADA, TINTE)
		pared.position = Vector3(lado * medio.x, MURO_ALTO_M + TEJADO_ALTO_M * 0.5, 0.0)
		pared.rotation_degrees.y = 90.0
		tejado.add_child(pared)
