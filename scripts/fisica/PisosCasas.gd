extends RefCounted

## Casas de dos plantas (2026-11-13): las que tienen escalera en su escena (marcas «escalera_pie», al pie del primer
## peldaño en la planta baja, y «escalera_cima», en el borde de arriba). Dice qué suelos hay en cada punto (tarima, rampa
## de la escalera o planta alta), qué losa tapa la vista, si un sitio es de arriba (sus marcas están a la altura de la
## planta alta) y el siguiente paso de un vecino que sube o baja. Lo usan Suelo.gd, Vista.gd (por Suelo) y la
## navegación de los vecinos; la posada sigue con su sistema propio (scripts/systems/VillageTavern.gd).
## Todo se calcula en el plano del edificio (el mapa original sin girar) y se devuelve en el mundo.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Marca = preload("res://mapa/marca.gd")
const Edificio = preload("res://mapa/edificio.gd")
const Planta = preload("res://mapa/planta.gd")
const RutaCuartos = preload("res://scripts/systems/RutaCuartos.gd")

const PIE := "escalera_pie"
const CIMA := "escalera_cima"
const ESCALERA_ANCHO_PX: float = 18.0  ## ~1 m: lo que se pisa de ancho en la rampa
const MARGEN_CASA_PX: float = 2.0      ## lo que se cuenta como dentro más allá de los muros
const CERCA_PIE_PX: float = 4.0        ## a esta distancia del extremo de la escalera ya se puede subir en recto
const LLEGADA_PX: float = 3.0          ## a esta del otro extremo ya se ha subido (o bajado)
const CERCA_MARCA_PX: float = 3.5      ## un destino a esta distancia de una marca de arriba es de arriba
const MITAD_RAMPA: float = 0.5         ## a partir de aquí el que está en la escalera cuenta como de arriba

static var _datos: Dictionary = {}     ## id del edificio → {rect, pie, cima, arriba}
static var _leidos: bool = false


## ¿Tiene ese edificio planta alta?
static func tiene(id: String) -> bool:
	return _todos().has(id)


## El edificio de dos plantas que hay en ese punto del mundo («» si ninguno).
static func de(p_mundo: Vector2) -> String:
	for id: String in _todos():
		if (_todos()[id]["rect"] as Rect2).grow(MARGEN_CASA_PX).has_point(Edificio.a_plano(id, p_mundo)):
			return id
	return ""


## Suelos que hay en `p_mundo`, de abajo arriba (px sobre el relieve): la tarima y encima la rampa o la planta alta.
static func pisos_en(p_mundo: Vector2) -> Array[float]:
	var out: Array[float] = []
	var id: String = de(p_mundo)
	if id.is_empty():
		return out
	var p: Vector2 = Edificio.a_plano(id, p_mundo)
	out.append(Mapa3D.TARIMA_PX)
	var t: float = _en_rampa(_todos()[id], p)
	out.append(_altura_rampa(t) if t >= 0.0 else Mapa3D.PISO_ALTO_PX)
	return out


## Altura del suelo para alguien del piso `nivel` (-1 si este punto no es de una casa de dos plantas o es la planta
## baja fuera de la escalera, que ya resuelve Suelo.gd).
static func altura_px(p_mundo: Vector2, nivel: int) -> float:
	var id: String = de(p_mundo)
	if id.is_empty():
		return -1.0
	var t: float = _en_rampa(_todos()[id], Edificio.a_plano(id, p_mundo))
	if t >= 0.0:
		return _altura_rampa(t)
	return Mapa3D.PISO_ALTO_PX if nivel == 1 else -1.0


## Losas de las plantas altas (tapan la vista; Vista.gd): la casa entera salvo el hueco de la escalera.
static func losas() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in _todos():
		out.append({"edificio": id, "rect": _todos()[id]["rect"], "h": Mapa3D.PISO_ALTO_PX})
	return out


static func en_losa(losa: Dictionary, p_mundo: Vector2) -> bool:
	var id: String = losa["edificio"]
	var p: Vector2 = Edificio.a_plano(id, p_mundo)
	return (losa["rect"] as Rect2).has_point(p) and _en_rampa(_todos()[id], p) < 0.0


## ¿Es ese sitio del mundo de la planta alta (una cama, una mesa… de arriba)?
static func es_arriba(p_mundo: Vector2) -> bool:
	var id: String = de(p_mundo)
	if id.is_empty():
		return false
	var p: Vector2 = Edificio.a_plano(id, p_mundo)
	for m: Vector2 in _todos()[id]["arriba"]:
		if p.distance_to(m) <= CERCA_MARCA_PX:
			return true
	return false


## Siguiente punto (en el mundo) para que `agente` vaya de `desde` a `hasta` dentro de la casa `id`, subiendo o bajando
## por la escalera si el destino está en la otra planta. A media escalera le cambia el piso (`vm`): así el que sube ya
## no choca con el muro que la cierra por debajo, ni el que baja con la barandilla de arriba.
static func ruta(id: String, desde: Vector2, hasta: Vector2, agente: Node2D, vm: Node) -> Vector2:
	var d: Dictionary = _todos()[id]
	var a: Vector2 = Edificio.a_plano(id, desde)
	var b: Vector2 = Edificio.a_plano(id, hasta)
	var de_piso: int = int(agente.get("elevation_level")) if agente != null and "elevation_level" in agente else 0
	var a_piso: int = 1 if es_arriba(hasta) else 0
	var t: float = _en_rampa(d, a)
	var en_escalera: int = (1 if t > MITAD_RAMPA else 0) if t >= 0.0 else de_piso
	if en_escalera != de_piso: # pasada la mitad de la escalera ya es del otro piso (como Suelo.nivel_de para el jugador)
		_cambiar_piso(agente, vm, en_escalera)
		de_piso = en_escalera
	var r: Vector2 = _ruta_plano(id, d, a, b, de_piso, a_piso)
	return hasta if r == b else Edificio.a_mundo(id, r)


static func _ruta_plano(id: String, d: Dictionary, a: Vector2, b: Vector2, de_piso: int, a_piso: int) -> Vector2:
	if de_piso == a_piso and _en_rampa(d, a) < 0.0:
		return RutaCuartos.siguiente(id, a, b, de_piso)
	var fin: Vector2 = _fin_escalera(d, a_piso)
	if _en_rampa(d, a) >= 0.0 or a.distance_to(_fin_escalera(d, de_piso)) <= CERCA_PIE_PX:
		return fin if a.distance_to(fin) > LLEGADA_PX else RutaCuartos.siguiente(id, a, b, a_piso)
	return RutaCuartos.siguiente(id, a, _fin_escalera(d, de_piso), de_piso)


## El extremo de la escalera que da a ese piso: el pie abajo, la cima arriba.
static func _fin_escalera(d: Dictionary, piso: int) -> Vector2:
	return d["cima"] if piso == 1 else d["pie"]


static func _cambiar_piso(agente: Node2D, vm: Node, piso: int) -> void:
	if agente != null and vm != null and vm.has_method("set_npc_elevation_level") and agente.get("elevation_level") != null:
		vm.call("set_npc_elevation_level", agente, piso)


## Cuánto se ha subido (0 al pie, 1 en la cima) si `p` está sobre la rampa; -1 si no.
static func _en_rampa(d: Dictionary, p: Vector2) -> float:
	var eje: Vector2 = (d["cima"] as Vector2) - (d["pie"] as Vector2)
	var rel: Vector2 = p - (d["pie"] as Vector2)
	var t: float = rel.dot(eje) / eje.length_squared()
	if t < 0.0 or t > 1.0 or absf(rel.cross(eje.normalized())) > ESCALERA_ANCHO_PX * 0.5:
		return -1.0
	return t


static func _altura_rampa(t: float) -> float:
	return lerpf(Mapa3D.TARIMA_PX, Mapa3D.PISO_ALTO_PX, t)


## Las casas con escalera, leídas una vez de sus escenas (sin crearlas).
static func _todos() -> Dictionary:
	if _leidos:
		return _datos
	_leidos = true
	var escenas: Dictionary = Edificio.escenas()
	for id: String in escenas:
		var marcas: Dictionary = Marca.de_escena(escenas[id])
		if not (marcas.has(PIE) and marcas.has(CIMA)):
			continue
		var tam: Vector2 = Planta.de_escena(escenas[id])["size"]
		var centro: Vector2 = Marca.propiedades((escenas[id] as PackedScene).get_state(), 0).get("centro_original", Vector2.ZERO)
		_datos[id] = {"rect": Rect2(centro - tam * 0.5, tam), "pie": marcas[PIE], "cima": marcas[CIMA], "arriba": _marcas_de_arriba(escenas[id])}
	return _datos


## Las marcas que están a la altura de la planta alta, en el plano.
static func _marcas_de_arriba(escena: PackedScene) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var estado: SceneState = escena.get_state()
	var centro: Vector2 = Marca.propiedades(estado, 0).get("centro_original", Vector2.ZERO)
	for i in range(estado.get_node_count()):
		if not str(estado.get_node_path(i)).begins_with("./" + Marca.CARPETA + "/"):
			continue
		var sitio: Transform3D = Marca.propiedades(estado, i).get("transform", Transform3D.IDENTITY)
		if Mapa3D.piso_de_altura(sitio.origin.y) == 1:
			out.append(centro + Mapa3D.a_mapa(sitio.origin))
	return out
