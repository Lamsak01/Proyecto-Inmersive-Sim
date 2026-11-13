@tool
extends Marker3D
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Anclas = preload("res://mapa/anclas.gd")

## Sitio al aire libre en el editor del mapa 3D (mapa/Mundo3D.tscn → «Sitios»), 2026-11-12: un punto sin dibujo que usa
## la lógica de los vecinos fuera de los edificios (dónde pasean, dónde esperan, dónde trabajan los jornaleros, por dónde
## entran los asaltantes…). Muévelo con el ratón: los vecinos irán ahí. A diferencia de casi todo lo demás, su posición
## es ya la del mundo: nadie la traduce. Paso 3 de docs/PLAN_MUNDO_DESDE_EDITOR.md.

const ESCENA := "res://mapa/Mundo3D.tscn"
const CARPETA := "Sitios"
const SERIE := "%s_%d"                    ## sitios numerados de una misma lista: paseo_1, paseo_2…
const LETRERO_ALTURA_M: float = 1.6
const LETRERO_TAM_PIXEL: float = 0.012
const LETRERO_VISTO_HASTA_M: float = 120.0

## Nombre interno del sitio (no lo cambies): el juego lo busca por este nombre.
@export var id_sitio: String = ""

static var _sitios: Dictionary = {} ## id del sitio → posición en el mundo (px del mapa)
static var _giros: Dictionary = {}  ## id del sitio → giro en grados (eje vertical), para lo que se pone mirando a un lado
static var _leidos: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		add_child(_letrero()) # sin «owner»: no se guarda en la escena


## El nombre del sitio flotando encima (solo en el editor), para saber cuál es cada cruz.
func _letrero() -> Label3D:
	var letrero := Label3D.new()
	letrero.text = id_sitio
	letrero.pixel_size = LETRERO_TAM_PIXEL
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.no_depth_test = true
	letrero.visibility_range_end = LETRERO_VISTO_HASTA_M
	letrero.position = Vector3(0.0, LETRERO_ALTURA_M, 0.0)
	return letrero


static func hay(id: String) -> bool:
	return _todos().has(id)


## Posición del sitio en el mundo. No se traduce: úsala tal cual.
static func mundo(id: String) -> Vector2:
	var sitios: Dictionary = _todos()
	if not sitios.has(id):
		push_error("SITIOS: falta el sitio «%s» en la carpeta «Sitios» del mapa" % id)
		return Vector2.ZERO
	return sitios[id]


## Giro de la cruz en grados (eje vertical, como en el editor): un poste o un banco miran hacia donde la gires.
static func giro(id: String) -> float:
	_todos()
	return float(_giros.get(id, 0.0))


## Todos los sitios numerados de una lista (paseo_1, paseo_2…), en orden, en el mundo.
static func serie(nombre: String) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var sitios: Dictionary = _todos()
	while sitios.has(SERIE % [nombre, out.size() + 1]):
		out.append(sitios[SERIE % [nombre, out.size() + 1]])
	return out


## El mismo sitio en el mapa ORIGINAL, para las funciones antiguas que todavía traducen lo que reciben (al crear un
## vecino, por ejemplo). Desaparecerá con la traducción (paso 4 del plan).
static func original(id: String) -> Vector2:
	return Anclas.desmover(mundo(id))


static func _todos() -> Dictionary:
	if _leidos:
		return _sitios
	_leidos = true
	if not ResourceLoader.exists(ESCENA):
		return _sitios
	var estado: SceneState = (load(ESCENA) as PackedScene).get_state()
	for i in range(estado.get_node_count()):
		if not str(estado.get_node_path(i)).begins_with("./" + CARPETA + "/"):
			continue
		var id: String = ""
		var en_escena := Transform3D.IDENTITY
		for k in range(estado.get_node_property_count(i)):
			match String(estado.get_node_property_name(i, k)):
				"id_sitio": id = String(estado.get_node_property_value(i, k))
				"transform": en_escena = estado.get_node_property_value(i, k)
		if not id.is_empty():
			_sitios[id] = Mapa3D.a_mapa(en_escena.origin)
			_giros[id] = rad_to_deg(en_escena.basis.orthonormalized().get_euler().y)
	return _sitios
