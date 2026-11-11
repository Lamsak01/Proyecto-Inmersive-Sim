@tool
extends Node3D
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Edificio en el editor del mapa 3D (mapa/Mundo3D.tscn → «Edificios»), 2026-11-10.
## En Godot enseña el edificio tal como lo construye el juego (una «foto» guardada en mapa/edificios_vista/).
## Muévelo con el ratón: el juego construirá ahí el edificio (muros, puerta, suelo y tejado). Girarlo (eje vertical) lo
## gira en el juego de 90 en 90 grados (se redondea al más cercano: las paredes del mapa 2D son rectángulos rectos). Lo que el código pone en sitios fijos del mapa (algunos muebles, pistas del Caso I,
## rutas de vecinos) habrá que recolocarlo después; eso es «arreglar la lógica» (decisión del usuario, 2026-11-10).

const VISTA_DIR := "res://mapa/edificios_vista/"
const ESCENA := "res://mapa/Mundo3D.tscn"
const REFERENCIA := "res://mapa/referencia_mapa.json"
const PREFIJO_SOLAR := "house_family_lot_"
const PRIMER_EMOJI: int = 0x2000 ## de aquí en adelante, símbolos y emojis que el letrero 3D no sabe dibujar
const LETRERO_ALTURA_M: float = 14.0 ## por encima del tejado de casi todos los edificios
const LETRERO_TAM_PIXEL: float = 0.03 ## metros por píxel de letra: letras de ~2 m, como el ancho de una casa
const LETRERO_TAM_LETRA: int = 64
const LETRERO_BORDE: int = 16
const LETRERO_VISTO_HASTA_M: float = 700.0 ## más lejos se esconden: desde muy arriba se amontonarían

static var _nombres: Dictionary = {}

## Nombre interno del edificio en el juego (no lo cambies).
@export var id_edificio: String = ""
## Dónde estaba el centro del edificio en el mapa 2D cuando se hizo la foto (no lo cambies).
@export var centro_original: Vector2 = Vector2.ZERO
## Dónde estaba esta pieza en 3D cuando se hizo la foto (no lo cambies).
@export var origen_3d: Vector3 = Vector3.ZERO


func _ready() -> void:
	if Engine.is_editor_hint():
		_poner_vista()


func _poner_vista() -> void:
	for c in get_children():
		if c.has_meta("vista_edificio"):
			c.queue_free()
	var ruta := VISTA_DIR + id_edificio + ".scn"
	if id_edificio.is_empty() or not ResourceLoader.exists(ruta):
		return
	var v: Node3D = (load(ruta) as PackedScene).instantiate()
	v.set_meta("vista_edificio", true)
	v.position = -origen_3d # la foto está en coordenadas del mundo; así queda pegada a la pieza
	_quitar_luces(v)
	add_child(v) # sin «owner»: no se guarda en la escena
	add_child(_letrero())


## Las luces de dentro de la foto el editor las dibuja como aros de colores que tapan el edificio visto desde
## arriba; en la foto no hacen falta (el juego pone sus propias luces).
func _quitar_luces(nodo: Node) -> void:
	for c in nodo.get_children():
		if c is Light3D:
			nodo.remove_child(c)
			c.free()
		else:
			_quitar_luces(c)


## Nombre flotando encima del edificio, con tamaño fijo en el mundo (de cerca grande, de lejos pequeño) (solo en el editor).
func _letrero() -> Label3D:
	var l := Label3D.new()
	l.set_meta("vista_edificio", true)
	l.text = nombre_legible(id_edificio)
	l.pixel_size = LETRERO_TAM_PIXEL
	l.font_size = LETRERO_TAM_LETRA
	l.outline_size = LETRERO_BORDE
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true # se lee aunque lo tape un árbol o el tejado
	l.visibility_range_end = LETRERO_VISTO_HASTA_M
	l.position = Vector3(0.0, LETRERO_ALTURA_M, 0.0)
	return l


## Nombre del edificio para las personas: el título del juego sin emojis (Godot no los dibuja en 3D);
## las casas de recién llegados y lo de bajo tierra no tienen título.
static func nombre_legible(id: String) -> String:
	if _nombres.is_empty() and FileAccess.file_exists(REFERENCIA):
		var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(REFERENCIA))
		if datos is Dictionary:
			for e: Variant in (datos as Dictionary).get("edificios", []):
				if e is Dictionary:
					_nombres[String(e.get("id", ""))] = String(e.get("nombre", ""))
	if id.begins_with(PREFIJO_SOLAR):
		return "Casa del solar " + id.trim_prefix(PREFIJO_SOLAR).to_upper()
	if id == "bajo_alcantarillas":
		return "Alcantarillas"
	var limpio := ""
	for ch: String in String(_nombres.get(id, id)):
		if ch.unicode_at(0) < PRIMER_EMOJI:
			limpio += ch
	return limpio.strip_edges()


## Cuánto se ha movido cada edificio en el mapa 2D (id → Vector2). Lo usa VillageManagerBase al construirlos.
static var _cache: Dictionary = {}
static var _leido: bool = false

static func desplazamiento(id: String) -> Vector2:
	if not _leido:
		_leido = true
		_cache = _leer_escena()
	return (_cache.get(id, [Vector2.ZERO, 0.0]) as Array)[0]


## Giro del edificio en el juego: 0, 90, 180 o 270 grados (el del editor redondeado).
static func giro(id: String) -> float:
	desplazamiento(id)
	return (_cache.get(id, [Vector2.ZERO, 0.0]) as Array)[1]


static func _leer_escena() -> Dictionary:
	var out := {}
	if not ResourceLoader.exists(ESCENA):
		return out
	var st: SceneState = (load(ESCENA) as PackedScene).get_state()
	for i in range(st.get_node_count()):
		var ruta := str(st.get_node_path(i))
		if not ((ruta.begins_with("./Edificios/") or ruta.begins_with("./BajoTierra/")) and ruta.count("/") == 2):
			continue
		var id := ""
		var centro := Vector2.ZERO
		var xf := Transform3D.IDENTITY
		for k in range(st.get_node_property_count(i)):
			match st.get_node_property_name(i, k):
				"id_edificio": id = String(st.get_node_property_value(i, k))
				"centro_original": centro = st.get_node_property_value(i, k)
				"transform": xf = st.get_node_property_value(i, k)
		if id.is_empty():
			continue
		var ahora := Mapa3D.a_mapa(xf.origin)
		var d := ahora - centro * Mapa3D.E # mapa estirado: lo que el usuario movió la pieza, aparte del estirado
		var g := fposmod(roundf(rad_to_deg(xf.basis.orthonormalized().get_euler().y) / 90.0) * 90.0, 360.0)
		if d.length() > 0.5 or g > 0.5:
			out[id] = [d, g]
	return out
