@tool
extends Node3D
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Mueble de un edificio en el editor del mapa 3D (grupo «Muebles» de la escena de su edificio, mapa/edificios/<id>.tscn;
## en las casas de recién llegados, «Edificios» → <casa> → «Muebles» de mapa/Mundo3D.tscn), 2026-11-10.
## Muévelo o gíralo (eje vertical) con el ratón: el juego lo pone ahí, y lo que el juego crea donde estaba (su pared
## invisible, su zona de uso…) le sigue. Como está dentro de su edificio, si mueves el edificio el mueble va con él.

const AssetLib = preload("res://scripts/visuals/AssetLibrary3D.gd")
const ESCENA := "res://mapa/Mundo3D.tscn"
const CARPETA := "Muebles" ## grupo que contiene los muebles de un edificio

## Nombre interno del mueble en el juego (no lo cambies).
@export var clave: String = ""
## Dónde estaba en el mapa 2D y en su edificio cuando se creó esta pieza (no lo cambies).
@export var pos_original: Vector2 = Vector2.ZERO
@export var local_original: Vector3 = Vector3.ZERO
@export var giro_original: float = 0.0
## Modelo y tamaño con que lo dibuja el juego (solo para verlo aquí).
@export var modelo: String = ""
@export var tam3: Vector3 = Vector3.ZERO
@export var alto3: float = -1.0
## Planta en la que está (0 = baja, 1 = alta).
@export var piso: int = 0


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	for c in get_children():
		if c.has_meta("vista_mueble"):
			c.queue_free()
	var m: Node3D = AssetLib.instantiate_model(modelo, tam3, alto3, true, true)
	if m != null:
		m.set_meta("vista_mueble", true)
		add_child(m) # sin «owner»: no se guarda en la escena


## clave → [desplazamiento en el mapa 2D (sin girar el edificio), giro en grados] de los muebles que el usuario cambió.
static var _cache: Dictionary = {}
static var _anclas: Array = []
static var _leido: bool = false


static func ajuste(k: String) -> Array:
	_leer()
	return _cache.get(k, [])


## Para mapa/anclas.gd: {"centro", "radio", "c", "d", "g"} de cada mueble cambiado (en coordenadas originales).
static func anclas() -> Array:
	_leer()
	return _anclas


static func _leer() -> void:
	if _leido:
		return
	_leido = true
	if not ResourceLoader.exists(ESCENA):
		return
	_leer_estado((load(ESCENA) as PackedScene).get_state()) # casas de recién llegados: sus muebles cuelgan del valle
	for propia: PackedScene in load("res://mapa/edificio.gd").escenas().values():
		_leer_estado(propia.get_state())


## Apunta los muebles de una escena (el valle o la de un edificio) que el usuario movió o giró.
static func _leer_estado(st: SceneState) -> void:
	for i in range(st.get_node_count()):
		if not (CARPETA + "/") in str(st.get_node_path(i)):
			continue
		var k := ""
		var orig := Vector2.ZERO
		var loc := Vector3.ZERO
		var g0 := 0.0
		var t3 := Vector3.ZERO
		var xf := Transform3D.IDENTITY
		for j in range(st.get_node_property_count(i)):
			var v = st.get_node_property_value(i, j)
			match st.get_node_property_name(i, j):
				"clave": k = String(v)
				"pos_original": orig = v
				"local_original": loc = v
				"giro_original": g0 = float(v)
				"tam3": t3 = v
				"transform": xf = v
		if k.is_empty():
			continue
		var dl := xf.origin - loc
		var d := Mapa3D.a_mapa(dl)
		var g := wrapf(rad_to_deg(xf.basis.orthonormalized().get_euler().y) - g0, -180.0, 180.0)
		if d.length() > 0.5 or absf(g) > 0.5:
			_cache[k] = [d, g]
			var tm := Mapa3D.a_mapa(t3)
			var r := maxf(tm.x, tm.y) * 0.5 + 2.0
			_anclas.append({"centro": orig, "radio": clampf(r, 4.0, 40.0), "c": orig, "d": d, "g": g})
