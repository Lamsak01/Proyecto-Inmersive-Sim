@tool
extends Node3D

## Objeto con uso en el juego (farola, pozo, tablón…) en el editor del mapa 3D (mapa/Mundo3D.tscn → «Objetos»), 2026-11-10.
## Muévelo con el ratón: el juego crea el objeto en el sitio nuevo con todo lo suyo (luz, sacar agua, misiones…).
## Girarlo (eje vertical) también lo gira en el juego, con sus paredes invisibles y lo que le sigue.

const AssetLib = preload("res://scripts/visuals/AssetLibrary3D.gd")
const ESCENA := "res://mapa/Mundo3D.tscn"
const WORLD_SCALE: float = 0.02
const PITCH_DEG: float = 58.0

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
	var cos_p: float = cos(deg_to_rad(PITCH_DEG))
	if not modelo.is_empty():
		var m: Node3D = AssetLib.instantiate_model(modelo, Vector3.ZERO, (alto * WORLD_SCALE) / cos_p, true, true)
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
	l.position = Vector3(0, ((alto + 6.0) * WORLD_SCALE) / cos_p, 0)
	add_child(l)


## Posición del objeto en el mapa 2D: la de siempre, o la nueva si el usuario lo movió en el editor.
static var _cache: Dictionary = {}
static var _leido: bool = false

static func pos(clave_obj: String, por_defecto: Vector2) -> Vector2:
	if not _leido:
		_leido = true
		_cache = _leer()
	if not _cache.has(clave_obj):
		return por_defecto
	return por_defecto + (_cache[clave_obj] as Vector2)


static func _leer() -> Dictionary:
	var out := {}
	if not ResourceLoader.exists(ESCENA):
		return out
	var st: SceneState = (load(ESCENA) as PackedScene).get_state()
	var sin_p: float = sin(deg_to_rad(PITCH_DEG))
	for i in range(st.get_node_count()):
		if not str(st.get_node_path(i)).begins_with("./Objetos/"):
			continue
		var k := ""
		var orig := Vector2.ZERO
		var xf := Transform3D.IDENTITY
		for j in range(st.get_node_property_count(i)):
			match st.get_node_property_name(i, j):
				"clave": k = String(st.get_node_property_value(i, j))
				"pos_original": orig = st.get_node_property_value(i, j)
				"transform": xf = st.get_node_property_value(i, j)
		if k.is_empty():
			continue
		var d := Vector2(xf.origin.x / WORLD_SCALE, xf.origin.z * sin_p / WORLD_SCALE) - orig
		if d.length() > 0.5:
			out[k] = d
	return out
