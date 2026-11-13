extends RefCounted
## Lo que el mapa del valle ([M] y minimapa) dibuja del pueblo, leído de las piezas del editor del mapa 3D
## (mapa/Mundo3D.tscn): edificios, solares, cementerio, plaza y agua salen donde estén, ya en el mundo.
## Sustituye a la lista de rectángulos del mapa viejo, que no seguía a lo movido (paso 4 de docs/PLAN_MUNDO_DESDE_EDITOR.md).

const EdificioEditor = preload("res://mapa/edificio.gd")
const Planta = preload("res://mapa/planta.gd")
const Solar = preload("res://mapa/solar.gd")
const Sitio = preload("res://mapa/sitio.gd")
const Zona = preload("res://mapa/zona.gd")

const SIN_DIBUJO: Array[String] = ["bajo_alcantarillas"] ## bajo tierra: no se ve en un mapa de superficie
const COLOR_CASA := Color(0.56, 0.46, 0.35)
const COLOR_POR_EDIFICIO: Dictionary = {
	"building_restaurant": Color(0.68, 0.42, 0.32), "building_tavern": Color(0.64, 0.40, 0.28),
	"shop_family_smith": Color(0.52, 0.48, 0.44), "shop_family_butcher": Color(0.62, 0.38, 0.34),
	"shop_family_carpenter": Color(0.58, 0.46, 0.32), "shop_family_fishmonger": Color(0.42, 0.54, 0.58),
	"mixed_family_herbalist": Color(0.46, 0.56, 0.42), "building_hospital": Color(0.44, 0.56, 0.52),
	"building_police": Color(0.42, 0.48, 0.58), "building_church": Color(0.56, 0.46, 0.54),
	"building_abandoned_mill": Color(0.46, 0.36, 0.28),
}
const COLOR_CEMENTERIO := Color(0.48, 0.52, 0.46)
const ZONA_PLAZA := "plaza"
const CUARTO_DE_VUELTA: float = 90.0
const ZONAS_AGUA: Array[String] = ["lago", "cienaga"]


## {"rect" (mundo), "col", "label"} de cada edificio con pieza y del cementerio.
static func edificios() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in EdificioEditor.escenas():
		if id in SIN_DIBUJO:
			continue
		var tam: Vector2 = Planta.de_edificio(id).get("size", Vector2.ZERO)
		out.append({"rect": _caja_girada(id, tam), "col": COLOR_POR_EDIFICIO.get(id, COLOR_CASA),
			"label": EdificioEditor.nombre_legible(id)})
	var cementerio: Rect2 = Sitio.cementerio()
	if cementerio.has_area():
		out.append({"rect": cementerio, "col": COLOR_CEMENTERIO, "label": "Cementerio"})
	return out


## Rectángulo de algo construido en un solar, dado en el plano del solar (mapa original) → mundo, ya girado.
static func en_solar(id_solar: String, r_plano: Rect2) -> Rect2:
	var caja := Rect2(Solar.a_mundo(id_solar, r_plano.position), Vector2.ZERO)
	for esquina: Vector2 in [r_plano.end, Vector2(r_plano.end.x, r_plano.position.y), Vector2(r_plano.position.x, r_plano.end.y)]:
		caja = caja.expand(Solar.a_mundo(id_solar, esquina))
	return caja


static func plaza() -> Rect2:
	return Zona.rect_mundo(ZONA_PLAZA)


static func agua() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for id: String in ZONAS_AGUA:
		out.append(Zona.rect_mundo(id))
	return out


## La planta del edificio en el mundo: su centro de fábrica llevado a la pieza, con el ancho y el fondo cambiados
## si la pieza está girada un cuarto de vuelta.
static func _caja_girada(id: String, tam: Vector2) -> Rect2:
	var centro: Vector2 = EdificioEditor.a_mundo(id, EdificioEditor.centro_de_fabrica(id))
	var cuarto: bool = int(roundf(EdificioEditor.giro(id) / CUARTO_DE_VUELTA)) % 2 == 1
	var lado: Vector2 = Vector2(tam.y, tam.x) if cuarto else tam
	return Rect2(centro - lado * 0.5, lado)
