@tool
extends Node3D
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Solar del pueblo en el editor del mapa 3D (mapa/Mundo3D.tscn → «Solares»), 2026-11-11: una parcela donde el juego
## levanta una casa, una tienda o un edificio público. Muévelo con el ratón: la obra, la casa que se construya en él,
## su letrero y sus campos salen ahí. Girarlo (eje vertical) gira lo construido de 90 en 90 grados.
## Paso 2 de docs/PLAN_MUNDO_DESDE_EDITOR.md. Lo lee mapa/anclas.gd.

const CARPETA := "Solares"
const NINGUNA := "ninguna"
const ESCENA := "res://mapa/Mundo3D.tscn"
const VISTA_COLOR := Color(0.95, 0.8, 0.25, 0.3)
const VISTA_ALTO_M: float = 0.1
const LETRERO_ALTURA_M: float = 3.0
const LETRERO_TAM_PIXEL: float = 0.02
const LETRERO_VISTO_HASTA_M: float = 400.0

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
	if _leida:
		return _lista
	_leida = true
	var estado: SceneState = (load(ESCENA) as PackedScene).get_state()
	for i in range(estado.get_node_count()):
		var ruta: String = str(estado.get_node_path(i))
		if ruta.begins_with("./" + CARPETA + "/") and ruta.count("/") == 2:
			_anadir(_propiedades(estado, i))
	return _lista


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
