@tool
extends Node3D
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Zona de terreno en el editor del mapa 3D (mapa/Mundo3D.tscn → «Zonas»), 2026-11-11: la plaza, el lago o la ciénaga.
## Muévela con el ratón: su suelo o su agua, la hondonada del terreno y lo que el juego pone encima salen ahí.
## No gira ni cambia de forma. Paso 2 de docs/PLAN_MUNDO_DESDE_EDITOR.md. El terreno, el agua y el mapa del valle la
## leen con `estirar`, `estirar_puntos` y `desestirar` (abajo).

const CARPETA := "Zonas"
const ESCENA := "res://mapa/Mundo3D.tscn"
const VISTA_COLOR := Color(0.3, 0.6, 0.95, 0.25)
const VISTA_ALTO_M: float = 0.1
const LETRERO_ALTURA_M: float = 6.0
const LETRERO_TAM_PIXEL: float = 0.04
const LETRERO_VISTO_HASTA_M: float = 800.0

## Nombre interno de la zona en el juego (no lo cambies).
@export var id_zona: String = ""
## Dónde estaba su centro en el mapa 2D cuando se creó la pieza (no lo cambies).
@export var centro_original: Vector2 = Vector2.ZERO
## Tamaño de la zona en el mundo: ancho (este-oeste) × fondo (norte-sur), en metros (no lo cambies).
@export var terreno_m: Vector2 = Vector2.ZERO

## Las zonas leídas de la escena: {"id", "rect": Rect2 en el mapa original, "d": desplazamiento en el mundo}.
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
	add_child(vista) # sin «owner»: no se guarda en la escena
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


## Terreno hecho por código (suelos, agua, orillas): punto del mapa original → mundo. Fuera de una zona es campo
## abierto estirado E veces; dentro, se estira igual pero va a donde esté la pieza.
static func estirar(p: Vector2) -> Vector2:
	return _con_zona(_zona_de(p), p)


## Como `estirar` para un polígono entero: todos sus puntos van con la zona en la que cae su centro.
static func estirar_puntos(pts: PackedVector2Array) -> PackedVector2Array:
	var centro := Vector2.ZERO
	for q: Vector2 in pts:
		centro += q
	var zona: Dictionary = _zona_de(centro / maxf(1.0, float(pts.size())))
	var out := PackedVector2Array()
	for q: Vector2 in pts:
		out.append(_con_zona(zona, q))
	return out


## Lo contrario de `estirar` (mundo → mapa original), para el relieve y el agua. Un punto dentro de una zona movida da
## el interior de esa zona; el hueco que dejó la zona en su sitio viejo da su borde (ahí ya no hay lago ni plaza).
static func desestirar(p: Vector2) -> Vector2:
	for zona: Dictionary in todas():
		var q: Vector2 = (p - (zona["d"] as Vector2)) / Mapa3D.E
		if (zona["rect"] as Rect2).has_point(q):
			return q
	var o: Vector2 = p / Mapa3D.E
	for zona: Dictionary in todas():
		if (zona["rect"] as Rect2).has_point(o):
			return _al_borde(zona["rect"], o)
	return o


## Rectángulo de la zona `id` en el mundo (vacío si no existe): para preguntar «¿estoy en la ciénaga?».
static func rect_mundo(id: String) -> Rect2:
	for zona: Dictionary in todas():
		if zona["id"] == id:
			var r: Rect2 = zona["rect"]
			return Rect2(r.position * Mapa3D.E + (zona["d"] as Vector2), r.size * Mapa3D.E)
	return Rect2()


static func _con_zona(zona: Dictionary, p: Vector2) -> Vector2:
	return p * Mapa3D.E if zona.is_empty() else p * Mapa3D.E + (zona["d"] as Vector2)


static func _zona_de(p: Vector2) -> Dictionary:
	for zona: Dictionary in todas():
		if (zona["rect"] as Rect2).has_point(p):
			return zona
	return {}


## El punto del borde del rectángulo más cercano a q (q está dentro).
static func _al_borde(r: Rect2, q: Vector2) -> Vector2:
	var hasta: Array[float] = [q.x - r.position.x, r.end.x - q.x, q.y - r.position.y, r.end.y - q.y]
	var bordes: Array[Vector2] = [Vector2(r.position.x, q.y), Vector2(r.end.x, q.y), Vector2(q.x, r.position.y), Vector2(q.x, r.end.y)]
	return bordes[hasta.find(hasta.min())]


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
		var centro: Vector2 = datos.get("centro_original", Vector2.ZERO)
		var tam_m: Vector2 = datos.get("terreno_m", Vector2.ZERO)
		var tam: Vector2 = Mapa3D.a_mapa(Vector3(tam_m.x, 0.0, tam_m.y)) / Mapa3D.E
		var origen: Vector3 = (datos.get("transform", Transform3D.IDENTITY) as Transform3D).origin
		_zonas.append({"id": String(datos.get("id_zona", "")), "rect": Rect2(centro - tam * 0.5, tam),
			"d": Mapa3D.a_mapa(origen) - centro * Mapa3D.E})
