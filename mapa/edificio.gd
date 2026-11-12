@tool
extends Node3D
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Edificio en el editor del mapa 3D (mapa/Mundo3D.tscn → «Edificios»), 2026-11-10.
## Desde 2026-11-11 cada edificio fijo es una escena propia (mapa/edificios/<id>.tscn) con sus grupos «Muros»,
## «Interior», «PisoAlto», «Tejado», «Muebles» y «Marcas»: el juego la carga tal cual donde esté esta pieza. Las casas
## de recién llegados son copias de tres casas modelo (mapa/casa_modelo.gd) y no tienen pieza: salen en su solar
## (mapa/solar.gd). Lo de bajo tierra enseña una «foto» (mapa/edificios_vista/).
## Muévelo con el ratón: el edificio sale ahí. Girarlo (eje vertical) lo gira en el juego de 90 en 90 grados (se
## redondea al más cercano: las paredes del mapa son rectángulos rectos).

const VISTA_DIR := "res://mapa/edificios_vista/"
const ESCENA := "res://mapa/Mundo3D.tscn"
const REFERENCIA := "res://mapa/referencia_mapa.json"
const GRUPO_MUROS := "Muros" ## lo tienen los edificios con escena propia (scripts/visuals/PartesEdificio3D.gd)
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
## Planta que se pisa y choca en el juego: ancho (este-oeste) × fondo (norte-sur), en metros (mapa/planta.gd).
## La puerta y la ventana del juego están donde las marcas «puerta» y «ventana»; aquí, el ancho del hueco de la puerta.
@export var planta_m: Vector2 = Vector2.ZERO
@export var puerta_ancho_m: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		_poner_vista()


func _poner_vista() -> void:
	for c in get_children():
		if c.has_meta("vista_edificio"):
			c.queue_free()
	if has_node(GRUPO_MUROS): # edificio con escena propia: ya se ve entero; solo falta el letrero
		if get_tree().edited_scene_root != self: # al editar su escena no se toca nada, o se guardaría el cambio
			_quitar_luces(self)
			add_child(_letrero())
		return
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
## lo de bajo tierra no tiene título.
static func nombre_legible(id: String) -> String:
	if _nombres.is_empty() and FileAccess.file_exists(REFERENCIA):
		var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(REFERENCIA))
		if datos is Dictionary:
			for e: Variant in (datos as Dictionary).get("edificios", []):
				if e is Dictionary:
					_nombres[String(e.get("id", ""))] = String(e.get("nombre", ""))
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


## ¿Tiene ese edificio pieza propia en el valle? (Las casas levantadas en un solar no: van con su solar.)
static func tiene_pieza(id: String) -> bool:
	return escenas().has(id)


## La escena propia de un edificio (mapa/edificios/<id>.tscn), o null si no tiene pieza en el valle.
static var _escenas: Dictionary = {}
static var _escenas_leidas: bool = false

static func escena(id: String) -> PackedScene:
	return escenas().get(id, null) as PackedScene


## id → escena de todos los edificios que ya la tienen.
static func escenas() -> Dictionary:
	if not _escenas_leidas:
		_escenas_leidas = true
		for pieza: Dictionary in _piezas():
			if pieza.has(CLAVE_ESCENA):
				_escenas[String(pieza["id_edificio"])] = pieza[CLAVE_ESCENA]
	return _escenas


const CLAVE_ESCENA := "_escena"

## Las piezas de «Edificios» y «BajoTierra» con sus propiedades: las de su escena propia (si la tiene) y, encima, las
## cambiadas en el valle (el sitio y el giro).
static func _piezas() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not ResourceLoader.exists(ESCENA):
		return out
	var st: SceneState = (load(ESCENA) as PackedScene).get_state()
	for i in range(st.get_node_count()):
		var ruta := str(st.get_node_path(i))
		if not ((ruta.begins_with("./Edificios/") or ruta.begins_with("./BajoTierra/")) and ruta.count("/") == 2):
			continue
		var pieza: Dictionary = {}
		var propia: PackedScene = st.get_node_instance(i)
		if propia != null:
			pieza[CLAVE_ESCENA] = propia
			var sp: SceneState = propia.get_state()
			for k in range(sp.get_node_property_count(0)):
				pieza[String(sp.get_node_property_name(0, k))] = sp.get_node_property_value(0, k)
		for k in range(st.get_node_property_count(i)):
			pieza[String(st.get_node_property_name(i, k))] = st.get_node_property_value(i, k)
		if not String(pieza.get("id_edificio", "")).is_empty():
			out.append(pieza)
	return out


static func _leer_escena() -> Dictionary:
	var out := {}
	for pieza: Dictionary in _piezas():
		var id := String(pieza["id_edificio"])
		var centro: Vector2 = pieza.get("centro_original", Vector2.ZERO)
		var xf: Transform3D = pieza.get("transform", Transform3D.IDENTITY)
		var ahora := Mapa3D.a_mapa(xf.origin)
		var d := ahora - centro * Mapa3D.E # mapa estirado: lo que el usuario movió la pieza, aparte del estirado
		var g := fposmod(roundf(rad_to_deg(xf.basis.orthonormalized().get_euler().y) / 90.0) * 90.0, 360.0)
		if d.length() > 0.5 or g > 0.5:
			out[id] = [d, g]
	return out
