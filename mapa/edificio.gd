@tool
extends Node3D

## Edificio en el editor del mapa 3D (mapa/Mundo3D.tscn → «Edificios»), 2026-11-10.
## En Godot enseña el edificio tal como lo construye el juego (una «foto» guardada en mapa/edificios_vista/).
## Muévelo con el ratón: el juego construirá ahí el edificio (muros, puerta, suelo y tejado). Girarlo (eje vertical) lo
## gira en el juego de 90 en 90 grados (se redondea al más cercano: las paredes del mapa 2D son rectángulos rectos). Lo que el código pone en sitios fijos del mapa (algunos muebles, pistas del Caso I,
## rutas de vecinos) habrá que recolocarlo después; eso es «arreglar la lógica» (decisión del usuario, 2026-11-10).

const VISTA_DIR := "res://mapa/edificios_vista/"
const ESCENA := "res://mapa/Mundo3D.tscn"
const WORLD_SCALE: float = 0.02
const PITCH_DEG: float = 58.0

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
	add_child(v) # sin «owner»: no se guarda en la escena


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
	var sin_p: float = sin(deg_to_rad(PITCH_DEG))
	for i in range(st.get_node_count()):
		if not str(st.get_node_path(i)).begins_with("./Edificios/"):
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
		var ahora := Vector2(xf.origin.x / WORLD_SCALE, xf.origin.z * sin_p / WORLD_SCALE)
		var d := ahora - centro
		var g := fposmod(roundf(rad_to_deg(xf.basis.orthonormalized().get_euler().y) / 90.0) * 90.0, 360.0)
		if d.length() > 0.5 or g > 0.5:
			out[id] = [d, g]
	return out
