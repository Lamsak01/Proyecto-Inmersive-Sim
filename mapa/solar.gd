@tool
extends Node3D
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Solar del pueblo en el editor del mapa 3D (mapa/Mundo3D.tscn → «Solares»), 2026-11-11: una parcela donde el juego
## levanta una casa, una tienda o un edificio público. Muévelo con el ratón: la obra, la casa que se construya en él,
## su letrero y sus campos salen ahí. Girarlo (eje vertical) gira lo construido de 90 en 90 grados.
## Puede llevar marcas (grupo «Marcas», cruces de mapa/marca.gd) para sitios del solar: van con él.
## Paso 2 de docs/PLAN_MUNDO_DESDE_EDITOR.md. Lo lee mapa/anclas.gd.

const CARPETA := "Solares"
const NINGUNA := "ninguna"
const ESCENA := "res://mapa/Mundo3D.tscn"
const VISTA_COLOR := Color(0.95, 0.8, 0.25, 0.3)
const VISTA_ALTO_M: float = 0.1
const LETRERO_ALTURA_M: float = 3.0
const LETRERO_TAM_PIXEL: float = 0.02
const LETRERO_VISTO_HASTA_M: float = 400.0
const GIRO_RECTO: float = 90.0 ## lo construido en un solar gira de 90 en 90 grados (paredes rectas)
const VUELTA: float = 360.0

## Nombre interno del solar en el juego (no lo cambies).
@export var id_solar: String = ""
## Dónde estaba su centro en el mapa 2D cuando se creó la pieza (no lo cambies).
@export var centro_original: Vector2 = Vector2.ZERO
## Tamaño del terreno: ancho (este-oeste) × fondo (norte-sur), en metros. Lo que el juego crea dentro va con el solar.
@export var terreno_m: Vector2 = Vector2.ZERO
## Qué solar es: «borde» (junto al pueblo), «barrio» (casitas apartadas), «afueras» (granjas, rancho, cantera) o
## «apartado» (mansiones). «ninguna»: no es un solar para construir (el del Puesto del Paso, que levanta su propio sistema).
@export_enum("ninguna", "borde", "barrio", "afueras", "apartado") var zona: String = NINGUNA
## Nombre del barrio, solo en los de zona «barrio» (Barrio del Lago, Caseríos del Bosque…).
@export var barrio: String = ""
## Tamaño de la casa que se levanta aquí: casita (small), casa (medium) o casona (large).
@export_enum("small", "medium", "large") var casa: String = "medium"
## La puerta de lo que se construya mira al sur (si no, al norte).
@export var puerta_al_sur: bool = true
## En los solares grandes el edificio va a un lado para dejar sitio a campos o corrales: cuánto se aparta del centro,
## en metros (x hacia el este, y hacia el sur).
@export var edificio_apartado_m: Vector2 = Vector2.ZERO

static var _lista: Array[Dictionary] = []
static var _marcas: Dictionary = {} ## id del solar → {id de la marca → sitio en el mapa original}
static var _piezas: Dictionary = {} ## id del solar → [centro original, desplazamiento en el mundo, giro en grados]
static var _leida: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		_poner_vista()


## Losa translúcida con el nombre del solar (solo en el editor; jugando no se dibuja).
func _poner_vista() -> void:
	var losa := BoxMesh.new()
	losa.size = Vector3(terreno_m.x, VISTA_ALTO_M, terreno_m.y)
	var material := StandardMaterial3D.new()
	material.albedo_color = VISTA_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	losa.material = material
	var vista := MeshInstance3D.new()
	vista.mesh = losa
	add_child(vista) # sin «owner»: no se guarda en la escena
	var letrero := Label3D.new()
	letrero.text = "Solar " + id_solar.to_upper()
	letrero.pixel_size = LETRERO_TAM_PIXEL
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.no_depth_test = true
	letrero.visibility_range_end = LETRERO_VISTO_HASTA_M
	letrero.position = Vector3(0.0, LETRERO_ALTURA_M, 0.0)
	add_child(letrero)


## Los solares para construir, en el orden de la carpeta (es el orden en que se ocupan). Cada uno, en el mapa ORIGINAL:
## {id, zone, center, size, door_south, plot} y, si los tiene, barrio y offset. Se lee de la escena sin crearla.
static func lista() -> Array[Dictionary]:
	_leer()
	return _lista


## Sitio de una marca de un solar (grupo «Marcas» dentro de su pieza: mapa/marca.gd), en el mapa ORIGINAL: como las
## de los edificios, está en metros respecto al centro del solar sin girar; mapa/anclas.gd la lleva a donde esté.
static func marca(id_solar: String, id_marca: String) -> Vector2:
	_leer()
	var marcas: Dictionary = _marcas.get(id_solar, {})
	if not marcas.has(id_marca):
		push_error("SOLARES: al solar «%s» le falta la marca «%s»" % [id_solar, id_marca])
		return Vector2.ZERO
	return marcas[id_marca]


## Del plano del solar (mapa original, sin girar) al mundo, donde está su pieza ahora: lo construido en él gira
## con ella de 90 en 90 grados. Es la misma cuenta que la capa de anclas hacía para cada solar.
static func a_mundo(id_solar: String, p_plano: Vector2) -> Vector2:
	_leer()
	if not _piezas.has(id_solar):
		push_error("SOLARES: no hay pieza del solar «%s»" % id_solar)
		return p_plano * Mapa3D.E
	var pieza: Array = _piezas[id_solar]
	var centro: Vector2 = pieza[0]
	return centro * Mapa3D.E + (pieza[1] as Vector2) + (p_plano - centro).rotated(-deg_to_rad(float(pieza[2])))


## Giro del solar como lo usa el mapa plano (radianes): el de las paredes invisibles de lo construido en él.
static func giro_plano(id_solar: String) -> float:
	_leer()
	return -deg_to_rad(float((_piezas.get(id_solar, [Vector2.ZERO, Vector2.ZERO, 0.0]) as Array)[2]))


static func _leer() -> void:
	if _leida:
		return
	_leida = true
	var estado: SceneState = (load(ESCENA) as PackedScene).get_state()
	var centros: Dictionary = {} ## ruta de la pieza → [id del solar, centro original]
	for i in range(estado.get_node_count()):
		var ruta: String = str(estado.get_node_path(i))
		if not ruta.begins_with("./" + CARPETA + "/"):
			continue
		var p: Dictionary = _propiedades(estado, i)
		if ruta.count("/") == 2:
			centros[ruta] = [String(p.get("id_solar", "")), p.get("centro_original", Vector2.ZERO)]
			_anadir(p)
			_anadir_pieza(p)
		elif p.has("id_marca") and centros.has(ruta.get_base_dir().get_base_dir()):
			_anadir_marca(centros[ruta.get_base_dir().get_base_dir()], p)


## Una marca del grupo «Marcas» de un solar (ruta …/solar_x/Marcas/marca: su solar está dos niveles arriba).
static func _anadir_marca(solar: Array, p: Dictionary) -> void:
	var id: String = solar[0]
	if not _marcas.has(id):
		_marcas[id] = {}
	var en_solar: Transform3D = p.get("transform", Transform3D.IDENTITY)
	(_marcas[id] as Dictionary)[String(p["id_marca"])] = (solar[1] as Vector2) + Mapa3D.a_mapa(en_solar.origin)


## Dónde quedó la pieza del solar: lo que se movió desde su centro original y su giro redondeado a 90 grados.
static func _anadir_pieza(p: Dictionary) -> void:
	var centro: Vector2 = p.get("centro_original", Vector2.ZERO)
	var xf: Transform3D = p.get("transform", Transform3D.IDENTITY)
	var giro: float = rad_to_deg(xf.basis.orthonormalized().get_euler().y)
	var giro_recto: float = fposmod(roundf(giro / GIRO_RECTO) * GIRO_RECTO, VUELTA)
	_piezas[String(p.get("id_solar", ""))] = [centro, Mapa3D.a_mapa(xf.origin) - centro * Mapa3D.E, giro_recto]


static func _anadir(p: Dictionary) -> void:
	if String(p.get("zona", NINGUNA)) == NINGUNA:
		return
	var d: Dictionary = {
		"id": String(p.get("id_solar", "")), "zone": String(p["zona"]), "center": p.get("centro_original", Vector2.ZERO),
		"size": (p.get("terreno_m", Vector2.ZERO) as Vector2) / Mapa3D.ESCALA, "door_south": bool(p.get("puerta_al_sur", true)),
		"plot": String(p.get("casa", "medium")),
	}
	if not String(p.get("barrio", "")).is_empty():
		d["barrio"] = String(p["barrio"])
	if p.has("edificio_apartado_m"):
		d["offset"] = (p["edificio_apartado_m"] as Vector2) / Mapa3D.ESCALA
	_lista.append(d)


static func _propiedades(estado: SceneState, nodo: int) -> Dictionary:
	var out: Dictionary = {}
	for k in range(estado.get_node_property_count(nodo)):
		out[String(estado.get_node_property_name(nodo, k))] = estado.get_node_property_value(nodo, k)
	return out
