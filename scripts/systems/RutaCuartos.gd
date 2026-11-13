extends RefCounted

## Rutas dentro de las casas hechas por cuartos (2026-11-13, interiores de tamaño real): un vecino que va de un cuarto
## a otro sale por el hueco de su cuarto a la sala (el cuarto «central») y entra por el hueco del cuarto de destino.
## Los cuartos salen de la escena del edificio (mapa/cuarto.gd). Todo en el plano del edificio (medidas de fábrica):
## quien llama lo pasa al mundo.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Marca = preload("res://mapa/marca.gd")

const EDIFICIO := "res://mapa/edificio.gd"
const CARPETA := "Cuartos"
const MARGEN_PASO_PX: float = 9.0  ## puntos a cada lado del hueco (dentro del cuarto y en la sala), ~0,5 m
const ALINEADO_PX: float = 4.0     ## a esta distancia de la línea del hueco ya se puede cruzar en recto
const CERCA_PASO_PX: float = 14.0  ## y a esta del centro del hueco

static var _por_edificio: Dictionary = {} ## id del edificio → Array[Dictionary] de cuartos
static var _por_escena: Dictionary = {}   ## ruta de una escena sin pieza (casa modelo) → sus cuartos


## ¿Tiene ese edificio cuartos (y por tanto rutas por sus huecos)?
static func tiene(id_edificio: String) -> bool:
	return not _cuartos(id_edificio).is_empty()


## Siguiente punto para ir de `desde` a `hasta` (ambos en el plano del edificio y en la planta `piso`: en las casas de
## dos plantas los cuartos de arriba están encima de los de abajo; scripts/fisica/PisosCasas.gd).
static func siguiente(id_edificio: String, desde: Vector2, hasta: Vector2, piso: int = 0) -> Vector2:
	return _siguiente(_cuartos(id_edificio), desde, hasta, piso)


## Lo mismo en una escena sin pieza en el mapa (las casas modelo de los solares, mapa/casa_modelo.gd): puntos
## respecto al centro de la casa, con la puerta al sur.
static func siguiente_en_escena(escena: PackedScene, desde: Vector2, hasta: Vector2) -> Vector2:
	if not _por_escena.has(escena.resource_path):
		_por_escena[escena.resource_path] = _leer(escena)
	return _siguiente(_por_escena[escena.resource_path], desde, hasta)


static func _siguiente(cuartos: Array[Dictionary], desde: Vector2, hasta: Vector2, piso: int = 0) -> Vector2:
	var origen: int = _cuarto_con(cuartos, desde, piso)
	var destino: int = _cuarto_con(cuartos, hasta, piso)
	if origen == destino:
		return hasta
	# Primero se sale del cuarto en que se está (si no es la sala) y luego se entra en el de destino
	if origen >= 0 and not bool(cuartos[origen]["central"]):
		return _cruzar(cuartos[origen], desde, true)
	if destino < 0 or bool(cuartos[destino]["central"]):
		return hasta
	return _cruzar(cuartos[destino], desde, false)


## Ir al punto de este lado del hueco y, ya delante de él, al del otro lado.
static func _cruzar(cuarto: Dictionary, desde: Vector2, saliendo: bool) -> Vector2:
	var antes: Vector2 = cuarto["dentro"] if saliendo else cuarto["fuera"]
	var despues: Vector2 = cuarto["fuera"] if saliendo else cuarto["dentro"]
	var normal: Vector2 = cuarto["normal"]
	var al_paso: Vector2 = desde - (cuarto["paso"] as Vector2)
	var alineado: bool = absf(al_paso.cross(normal)) <= ALINEADO_PX and al_paso.length() <= CERCA_PASO_PX
	return despues if alineado else antes


static func _cuarto_con(cuartos: Array[Dictionary], p: Vector2, piso: int) -> int:
	for i in range(cuartos.size()):
		if int(cuartos[i]["piso"]) == piso and (cuartos[i]["rect"] as Rect2).has_point(p):
			return i
	return -1


static func _cuartos(id_edificio: String) -> Array[Dictionary]:
	if not _por_edificio.has(id_edificio):
		var escena: PackedScene = load(EDIFICIO).call("escena", id_edificio) as PackedScene
		_por_edificio[id_edificio] = _leer(escena)
	return _por_edificio[id_edificio]


## Cada cuarto: su rectángulo, el centro de su hueco y los puntos a uno y otro lado (en el plano del edificio).
static func _leer(escena: PackedScene) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if escena == null:
		return out
	var estado: SceneState = escena.get_state()
	var centro: Vector2 = Marca.propiedades(estado, 0).get("centro_original", Vector2.ZERO)
	for i in range(estado.get_node_count()):
		if not str(estado.get_node_path(i)).begins_with("./" + CARPETA + "/"):
			continue
		var pieza: Dictionary = Marca.propiedades(estado, i)
		var en_edificio: Transform3D = pieza.get("transform", Transform3D.IDENTITY)
		var c: Vector2 = centro + Mapa3D.a_mapa(en_edificio.origin)
		var tam_m: Vector2 = pieza.get("tam_m", Vector2.ONE)
		var tam: Vector2 = Mapa3D.a_mapa(Vector3(tam_m.x, 0.0, tam_m.y))
		var paso_rel: Vector2 = Mapa3D.a_mapa(pieza.get("paso_m", Vector3.ZERO) as Vector3)
		var normal: Vector2 = _normal_hacia_fuera(paso_rel, tam * 0.5)
		var paso: Vector2 = c + paso_rel
		out.append({
			"rect": Rect2(c - tam * 0.5, tam), "central": bool(pieza.get("central", false)), "paso": paso,
			"normal": normal, "dentro": paso - normal * MARGEN_PASO_PX, "fuera": paso + normal * MARGEN_PASO_PX,
			"piso": Mapa3D.piso_de_altura(en_edificio.origin.y),
		})
	return out


## Hacia fuera del cuarto por el lado en que está el hueco (el lado al que el hueco está más pegado).
static func _normal_hacia_fuera(paso: Vector2, medio: Vector2) -> Vector2:
	if absf(paso.x) / maxf(medio.x, 0.001) >= absf(paso.y) / maxf(medio.y, 0.001):
		return Vector2(signf(paso.x), 0.0)
	return Vector2(0.0, signf(paso.y))
