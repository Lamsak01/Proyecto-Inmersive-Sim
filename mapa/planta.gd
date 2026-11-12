extends RefCounted
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Marca = preload("res://mapa/marca.gd")

## Planta de un edificio leída de su escena (2026-11-11, paso 1 de docs/PLAN_MUNDO_DESDE_EDITOR.md): el tamaño que se
## pisa y choca, por qué lado se entra, el ancho de la puerta y dónde están puerta y ventana. Sale de las propiedades
## «Planta m» y «Puerta ancho m» de la pieza y de sus marcas «puerta» y «ventana». El lado de la puerta es el muro que
## la marca tiene más cerca; la ventana va en ese mismo muro.

const EDIFICIO := "res://mapa/edificio.gd"
const LADOS_HORIZONTALES: Array[String] = ["south", "north"]
const PRECISION_PX: float = 0.001 ## los metros guardados vuelven a píxeles de mapa con decimales de sobra

static var _por_escena: Dictionary = {} ## ruta de la escena → planta


## Planta del edificio con ese id: {"size", "door_dir", "door_width", "door_offset", "window_offset"}, en píxeles del
## mapa original y con el edificio sin girar. Los dos «offset» se miden a lo largo del muro, desde su centro.
static func de_edificio(id_edificio: String) -> Dictionary:
	return de_escena(load(EDIFICIO).call("escena", id_edificio) as PackedScene)


static func de_escena(escena: PackedScene) -> Dictionary:
	if escena == null:
		push_error("PLANTA: edificio sin escena")
		return {}
	if not _por_escena.has(escena.resource_path):
		_por_escena[escena.resource_path] = _leer(escena)
	return _por_escena[escena.resource_path]


## La misma planta con el edificio girado media vuelta (casas modelo en solares que miran al norte).
static func con_media_vuelta(planta: Dictionary) -> Dictionary:
	var contrario: Dictionary = {"south": "north", "north": "south", "east": "west", "west": "east"}
	var out: Dictionary = planta.duplicate()
	out["door_dir"] = contrario[planta["door_dir"]]
	out["door_offset"] = -float(planta["door_offset"])
	out["window_offset"] = -float(planta["window_offset"])
	return out


static func _leer(escena: PackedScene) -> Dictionary:
	var raiz: Dictionary = Marca.propiedades(escena.get_state(), 0)
	var marcas: Dictionary = Marca.de_escena(escena)
	var metros: Vector2 = raiz.get("planta_m", Vector2.ZERO)
	if metros == Vector2.ZERO or not marcas.has(Marca.PUERTA) or not marcas.has(Marca.VENTANA):
		push_error("PLANTA: a «%s» le falta la planta o las marcas de puerta y ventana" % escena.resource_path)
		return {}
	var centro: Vector2 = raiz.get("centro_original", Vector2.ZERO)
	var tam: Vector2 = _redondo(Mapa3D.a_mapa(Vector3(metros.x, 0.0, metros.y)))
	var puerta: Vector2 = _redondo((marcas[Marca.PUERTA] as Vector2) - centro)
	var ventana: Vector2 = _redondo((marcas[Marca.VENTANA] as Vector2) - centro)
	var lado: String = _lado_mas_cercano(puerta, tam * 0.5)
	var horizontal: bool = lado in LADOS_HORIZONTALES
	return {
		"size": tam,
		"door_dir": lado,
		"door_width": snappedf(Mapa3D.a_mapa(Vector3(float(raiz.get("puerta_ancho_m", 0.0)), 0.0, 0.0)).x, PRECISION_PX),
		"door_offset": puerta.x if horizontal else puerta.y,
		"window_offset": ventana.x if horizontal else ventana.y,
	}


## Redondea cada número por separado (hacerlo con el vector entero deja restos como 96,00001).
static func _redondo(v: Vector2) -> Vector2:
	return Vector2(snappedf(v.x, PRECISION_PX), snappedf(v.y, PRECISION_PX))


## El muro (sur, norte, este u oeste) al que está más pegado ese punto, medido desde el centro de la planta.
static func _lado_mas_cercano(punto: Vector2, media_planta: Vector2) -> String:
	if absf(punto.y) / media_planta.y >= absf(punto.x) / media_planta.x:
		return "south" if punto.y > 0.0 else "north"
	return "east" if punto.x > 0.0 else "west"
