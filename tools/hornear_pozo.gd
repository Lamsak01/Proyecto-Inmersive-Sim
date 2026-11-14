extends SceneTree

## Construye el pozo clásico (brocal redondo de piedra, agua oscura, dos postes, rodillo con manivela, cuerda y cubo) y
## lo guarda como pieza en assests/curated_3d/exterior/pozo_clasico.tscn. Sustituye al pozo cuadrado con tejadillo,
## que no se reconocía como pozo (usuario, 2026-11-13). Uso: godot --headless --path . -s tools/hornear_pozo.gd

const SALIDA: String = "res://assests/curated_3d/exterior/pozo_clasico.tscn"
const TEX_PIEDRA: String = "res://assests/curated_3d/town_textures/rf_cobblestone.png"
const TEX_MADERA: String = "res://assests/curated_3d/town_textures/rf_planks.png"

const BROCAL_RADIO_M: float = 0.75
const BROCAL_ALTO_M: float = 0.8
const BOCA_RADIO_M: float = 0.55        ## el agujero, con el agua oscura dentro
const LABIO_GROSOR_M: float = 0.12      ## el remate redondo de piedra encima del brocal
const POSTE_LADO_M: float = 0.14
const POSTE_ALTO_M: float = 2.2
const POSTE_SEPARACION_M: float = 0.72  ## cada poste, a esta distancia del centro (justo sobre el brocal)
const RODILLO_RADIO_M: float = 0.07
const RODILLO_ALTO_M: float = 1.95
const MANIVELA_LARGO_M: float = 0.3
const CUERDA_RADIO_M: float = 0.015
const CUBO_ALTO_M: float = 0.28
const CUBO_RADIO_M: float = 0.17
const CUBO_ALTURA_M: float = 1.15       ## colgado sobre la boca, a media cuerda
const COLOR_AGUA: Color = Color(0.06, 0.09, 0.10)
const COLOR_CUERDA: Color = Color(0.62, 0.52, 0.34)
const COLOR_HIERRO: Color = Color(0.30, 0.31, 0.33)

func _initialize() -> void:
	var raiz := Node3D.new()
	raiz.name = "PozoClasico"
	var piedra: StandardMaterial3D = _material_textura(TEX_PIEDRA)
	var madera: StandardMaterial3D = _material_textura(TEX_MADERA)
	_brocal(raiz, piedra)
	_armazon(raiz, madera)
	_cuerda_y_cubo(raiz, madera)
	for n in raiz.find_children("*", "", true, false):
		n.owner = raiz
	var paquete := PackedScene.new()
	var err: Error = paquete.pack(raiz)
	if err == OK:
		err = ResourceSaver.save(paquete, SALIDA)
	print("HORNEAR POZO: %s" % ["OK " + SALIDA if err == OK else "ERROR %d" % err])
	raiz.free()
	quit(0 if err == OK else 1)

## Brocal redondo de piedra con un remate y el agua oscura asomando en la boca.
func _brocal(raiz: Node3D, piedra: StandardMaterial3D) -> void:
	var muro := CylinderMesh.new()
	muro.top_radius = BROCAL_RADIO_M
	muro.bottom_radius = BROCAL_RADIO_M
	muro.height = BROCAL_ALTO_M
	_pieza(raiz, "Brocal", muro, piedra, Vector3(0.0, BROCAL_ALTO_M * 0.5, 0.0))
	var labio := TorusMesh.new()
	labio.inner_radius = BOCA_RADIO_M
	labio.outer_radius = BROCAL_RADIO_M + LABIO_GROSOR_M * 0.5
	_pieza(raiz, "Remate", labio, piedra, Vector3(0.0, BROCAL_ALTO_M, 0.0))
	var agua := CylinderMesh.new()
	agua.top_radius = BOCA_RADIO_M
	agua.bottom_radius = BOCA_RADIO_M
	agua.height = 0.02
	_pieza(raiz, "Agua", agua, _material_color(COLOR_AGUA), Vector3(0.0, BROCAL_ALTO_M + 0.005, 0.0))

## Dos postes de madera sobre el brocal y el rodillo entre ellos, con su manivela de hierro.
func _armazon(raiz: Node3D, madera: StandardMaterial3D) -> void:
	var poste := BoxMesh.new()
	poste.size = Vector3(POSTE_LADO_M, POSTE_ALTO_M, POSTE_LADO_M)
	for lado in [-1.0, 1.0]:
		_pieza(raiz, "Poste", poste, madera, Vector3(lado * POSTE_SEPARACION_M, POSTE_ALTO_M * 0.5, 0.0))
	var rodillo := CylinderMesh.new()
	rodillo.top_radius = RODILLO_RADIO_M
	rodillo.bottom_radius = RODILLO_RADIO_M
	rodillo.height = POSTE_SEPARACION_M * 2.0 + POSTE_LADO_M * 2.0
	var r: MeshInstance3D = _pieza(raiz, "Rodillo", rodillo, madera, Vector3(0.0, RODILLO_ALTO_M, 0.0))
	r.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	var hierro: StandardMaterial3D = _material_color(COLOR_HIERRO)
	var brazo := BoxMesh.new()
	brazo.size = Vector3(0.04, MANIVELA_LARGO_M, 0.04)
	var x_brazo: float = POSTE_SEPARACION_M + POSTE_LADO_M + 0.03
	_pieza(raiz, "Manivela", brazo, hierro, Vector3(x_brazo, RODILLO_ALTO_M - MANIVELA_LARGO_M * 0.5, 0.0))
	var asa := BoxMesh.new()
	asa.size = Vector3(0.16, 0.04, 0.04)
	_pieza(raiz, "Asa", asa, hierro, Vector3(x_brazo + 0.08, RODILLO_ALTO_M - MANIVELA_LARGO_M, 0.0))

## Cuerda desde el rodillo y el cubo de madera colgando sobre la boca.
func _cuerda_y_cubo(raiz: Node3D, madera: StandardMaterial3D) -> void:
	var largo: float = RODILLO_ALTO_M - (CUBO_ALTURA_M + CUBO_ALTO_M * 0.5)
	var cuerda := CylinderMesh.new()
	cuerda.top_radius = CUERDA_RADIO_M
	cuerda.bottom_radius = CUERDA_RADIO_M
	cuerda.height = largo
	_pieza(raiz, "Cuerda", cuerda, _material_color(COLOR_CUERDA), Vector3(0.0, RODILLO_ALTO_M - largo * 0.5, 0.0))
	var cubo := CylinderMesh.new()
	cubo.top_radius = CUBO_RADIO_M
	cubo.bottom_radius = CUBO_RADIO_M * 0.85
	cubo.height = CUBO_ALTO_M
	_pieza(raiz, "Cubo", cubo, madera, Vector3(0.0, CUBO_ALTURA_M, 0.0))

func _pieza(raiz: Node3D, nombre: String, malla: Mesh, mat: Material, sitio: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nombre
	mi.mesh = malla
	mi.material_override = mat
	mi.position = sitio
	raiz.add_child(mi, true)
	return mi

func _material_textura(ruta: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(ruta) as Texture2D
	m.uv1_triplanar = true # la textura se repite igual en todas las caras, sin estirarse en el cilindro
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST # píxeles nítidos, como el resto del pueblo
	m.roughness = 0.9
	return m

func _material_color(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	return m
