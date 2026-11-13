@tool
extends Node3D
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Objeto con uso en el juego (farola, pozo, tablón…) en el editor del mapa 3D (mapa/Mundo3D.tscn → «Objetos»), 2026-11-10.
## Muévelo con el ratón: el juego crea el objeto en el sitio nuevo con todo lo suyo (luz, sacar agua, misiones…).
## Girarlo (eje vertical) también lo gira en el juego, con sus paredes invisibles y lo que le sigue.

const AssetLib = preload("res://scripts/visuals/AssetLibrary3D.gd")
const ESCENA := "res://mapa/Mundo3D.tscn"

## Nombre interno del objeto en el juego (no lo cambies).
@export var clave: String = ""
## Dónde estaba en el mapa 2D cuando se creó esta pieza (no lo cambies).
@export var pos_original: Vector2 = Vector2.ZERO
## Modelo que se enseña en el editor (solo para verlo; el juego usa el suyo).
@export var modelo: String = ""
@export var alto: float = 24.0
@export var nombre_visible: String = ""
## Si está marcada, todo lo que el juego crea alrededor de su sitio original (dibujo, zona de uso, letrero…) la sigue.
@export var es_ancla: bool = false
@export var radio_ancla: float = 14.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	for c in get_children():
		if c.has_meta("vista_objeto"):
			c.queue_free()
	if not modelo.is_empty():
		var m: Node3D = AssetLib.instantiate_model(modelo, Vector3.ZERO, Mapa3D.alto_a_3d(alto), true, true)
		if m != null:
			m.set_meta("vista_objeto", true)
			add_child(m)
	if get_child_count() == 0 or modelo.is_empty():
		var bola := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.12
		sm.height = 0.24
		bola.mesh = sm
		bola.set_meta("vista_objeto", true)
		bola.position = Vector3(0, 0.12, 0)
		add_child(bola)
	var l := Label3D.new()
	l.set_meta("vista_objeto", true)
	l.text = nombre_visible if not nombre_visible.is_empty() else clave
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.pixel_size = 0.003
	l.position = Vector3(0, Mapa3D.alto_a_3d(alto + 6.0), 0)
	add_child(l)


## Sitio y giro de cada objeto con clave, ya en el mundo: donde lo dejó el usuario en el editor. Nadie los traduce.
static var _sitios: Dictionary = {} ## clave → posición en el mundo (px del mapa)
static var _giros: Dictionary = {}  ## clave → giro en grados (eje vertical)
static var _leido: bool = false

static func mundo(clave_obj: String) -> Vector2:
	_leer()
	if not _sitios.has(clave_obj):
		push_error("OBJETOS: falta la pieza con clave «%s» en la carpeta «Objetos» del mapa" % clave_obj)
		return Vector2.ZERO
	return _sitios[clave_obj]


static func giro(clave_obj: String) -> float:
	_leer()
	return float(_giros.get(clave_obj, 0.0))


static func _leer() -> void:
	if _leido:
		return
	_leido = true
	if not ResourceLoader.exists(ESCENA):
		return
	var st: SceneState = (load(ESCENA) as PackedScene).get_state()
	for i in range(st.get_node_count()):
		if not str(st.get_node_path(i)).begins_with("./Objetos/"):
			continue
		var k := ""
		var xf := Transform3D.IDENTITY
		for j in range(st.get_node_property_count(i)):
			match st.get_node_property_name(i, j):
				"clave": k = String(st.get_node_property_value(i, j))
				"transform": xf = st.get_node_property_value(i, j)
		if not k.is_empty():
			_sitios[k] = Mapa3D.a_mapa(xf.origin)
			_giros[k] = rad_to_deg(xf.basis.orthonormalized().get_euler().y)
