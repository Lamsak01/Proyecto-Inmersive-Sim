extends RefCounted

## Solo para las pruebas (Claude Code, 2026-11-12, corte final del paso 4 de docs/PLAN_MUNDO_DESDE_EDITOR.md): muchas
## pruebas escriben sus posiciones en el mapa ORIGINAL (el de antes del ×5). Esto las lleva al mundo con la pieza que
## las contiene: edificio, solar o zona del editor; fuera de todo, campo abierto estirado ×E. El juego no lo usa: cada
## sistema pide ya sus sitios a su pieza (`EdificioEditor.a_mundo`, `Solar.a_mundo`, `Zona.estirar`, `Sitio.mundo`).

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const EdificioEditor = preload("res://mapa/edificio.gd")
const Planta = preload("res://mapa/planta.gd")
const Solar = preload("res://mapa/solar.gd")
const Zona = preload("res://mapa/zona.gd")
const CERCA_PX: float = 40.0 ## lo pegado a un edificio (terraza, puerta, letrero) va con él
const SIN_PLANTA: Array[String] = ["bajo_alcantarillas"]

static var _rects: Dictionary = {} ## id del edificio → su planta en el mapa original, con lo pegado


## Punto del mapa original → mundo.
static func a_mundo(p: Vector2) -> Vector2:
	var edificio: String = _edificio_de(p)
	if not edificio.is_empty():
		return EdificioEditor.a_mundo(edificio, p)
	var solar: String = Solar.con_punto(p)
	return Zona.estirar(p) if solar.is_empty() else Solar.a_mundo(solar, p)


## Punto del mundo → mapa original (lo contrario, para funciones que miran salas con medidas de fábrica).
static func a_original(p_mundo: Vector2) -> Vector2:
	for id: String in _plantas():
		var q: Vector2 = EdificioEditor.a_plano(id, p_mundo)
		if (_plantas()[id] as Rect2).has_point(q):
			return q
	for zona: Dictionary in Zona.todas():
		if (zona["rect"] as Rect2).has_point(p_mundo):
			return (p_mundo - (zona["d"] as Vector2)) * 0.2
	return p_mundo * 0.2


## El edificio más pequeño cuya planta (con lo pegado) contiene p ("" si ninguno).
static func _edificio_de(p: Vector2) -> String:
	var mejor: String = ""
	var area: float = INF
	for id: String in _plantas():
		var r: Rect2 = _plantas()[id]
		if r.has_point(p) and r.get_area() < area:
			area = r.get_area()
			mejor = id
	return mejor


static func _plantas() -> Dictionary:
	if _rects.is_empty():
		for id: String in EdificioEditor.escenas():
			if id in SIN_PLANTA:
				continue
			var tam: Vector2 = Planta.de_edificio(id).get("size", Vector2.ZERO)
			var c: Vector2 = EdificioEditor.centro_de_fabrica(id)
			_rects[id] = Rect2(c - tam * 0.5, tam).grow(CERCA_PX)
	return _rects
