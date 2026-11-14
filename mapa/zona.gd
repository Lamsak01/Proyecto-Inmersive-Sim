@tool
extends Node3D

## Zona de terreno en el editor del mapa 3D (mapa/Mundo3D.tscn → «Zonas»): la plaza, el lago o la ciénaga.
## Muévela con el ratón: su suelo o su agua, la hondonada del terreno y lo que el juego pone encima salen ahí
## directamente en coordenadas reales del mundo, sin factor de estirado.

const CARPETA := "Zonas"
const ESCENA := "res://mapa/Mundo3D.tscn"
const METROS_POR_UNIDAD: float = 0.056
const VISTA_COLOR := Color(0.3, 0.6, 0.95, 0.25)
const VISTA_ALTO_M: float = 0.1
const LETRERO_ALTURA_M: float = 6.0
const LETRERO_TAM_PIXEL: float = 0.04
const LETRERO_VISTO_HASTA_M: float = 800.0
const CENTROS_FABRICA_M: Dictionary = {
	"plaza": Vector2(130.2, 13.72),
	"lago": Vector2(-242.9, 46.2),
	"cienaga": Vector2(-447.3, 93.8),
}

## Nombre interno de la zona en el juego (no lo cambies).
@export var id_zona: String = ""
## Tamaño de la zona en el mundo: ancho (este-oeste) × fondo (norte-sur), en metros.
@export var terreno_m: Vector2 = Vector2.ZERO

## Las zonas leídas de la escena en coordenadas reales del mundo: {"id", "centro", "rect", "rect_fabrica", "d"}.
static var _zonas: Array[Dictionary] = []
static var _leidas: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		_poner_vista()


## Losa azul translúcida con el nombre de la zona (solo en el editor; jugando no se dibuja).
func _poner_vista() -> void:
	var losa := BoxMesh.new()
	losa.size = Vector3(terreno_m.x, VISTA_ALTO_M, terreno_m.y)
	var material := StandardMaterial3D.new()
	material.albedo_color = VISTA_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	losa.material = material
	var vista := MeshInstance3D.new()
	vista.mesh = losa
	add_child(vista)
	var letrero := Label3D.new()
	letrero.text = "Zona: " + id_zona
	letrero.pixel_size = LETRERO_TAM_PIXEL
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.no_depth_test = true
	letrero.visibility_range_end = LETRERO_VISTO_HASTA_M
	letrero.position = Vector3(0.0, LETRERO_ALTURA_M, 0.0)
	add_child(letrero)


## Todas las zonas (las lee una vez de la escena del mapa).
static func todas() -> Array[Dictionary]:
	if not _leidas:
		_leer()
	return _zonas


## Rectángulo de la zona `id` en el mundo (vacío si no existe).
static func rect_mundo(id: String) -> Rect2:
	for zona: Dictionary in todas():
		if zona["id"] == id:
			return zona["rect"] as Rect2
	return Rect2()


## Centro actual de la zona `id` en el mundo.
static func centro_mundo(id: String) -> Vector2:
	for zona: Dictionary in todas():
		if zona["id"] == id:
			return zona["centro"] as Vector2
	return Vector2.ZERO


## Cuánto se ha desplazado la zona `id` respecto a su sitio de fábrica en la escena 3D.
static func desplazamiento(id: String) -> Vector2:
	for zona: Dictionary in todas():
		if zona["id"] == id:
			return zona["d"] as Vector2
	return Vector2.ZERO


## Compatibilidad temporal para sistemas de vecinos aún no migrados (VillageManager* y VillageNPCSocial).
static func estirar(p: Vector2) -> Vector2:
	var p_mundo: Vector2 = p * 5.0
	for zona: Dictionary in todas():
		if (zona["rect_fabrica"] as Rect2).has_point(p_mundo):
			return p_mundo + (zona["d"] as Vector2)
	return p_mundo


static func _leer() -> void:
	_leidas = true
	var estado: SceneState = (load(ESCENA) as PackedScene).get_state()
	for i in range(estado.get_node_count()):
		var ruta: String = str(estado.get_node_path(i))
		if not ruta.begins_with("./" + CARPETA + "/") or ruta.count("/") != 2:
			continue
		var datos: Dictionary = {}
		for k in range(estado.get_node_property_count(i)):
			datos[estado.get_node_property_name(i, k)] = estado.get_node_property_value(i, k)
		var id: String = String(datos.get("id_zona", ""))
		var tam_m: Vector2 = datos.get("terreno_m", Vector2.ZERO)
		var origen: Vector3 = (datos.get("transform", Transform3D.IDENTITY) as Transform3D).origin
		var centro: Vector2 = Vector2(origen.x, origen.z) / METROS_POR_UNIDAD
		var tam: Vector2 = tam_m / METROS_POR_UNIDAD
		var fab_m: Vector2 = CENTROS_FABRICA_M.get(id, Vector2(origen.x, origen.z))
		var fab: Vector2 = fab_m / METROS_POR_UNIDAD
		_zonas.append({
			"id": id,
			"centro": centro,
			"rect": Rect2(centro - tam * 0.5, tam),
			"rect_fabrica": Rect2(fab - tam * 0.5, tam),
			"d": centro - fab,
		})
