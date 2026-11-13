extends RefCounted

## Vista: ¿puede alguien ver a otro, y cuánto le oye, con las alturas de verdad? Paso del mundo a 3D, pasos 5a y 5b
## (docs/PLAN_MUNDO_3D.md), 2026-11-10. Un solo sitio para testigos, guardias y vecinos.
## - Las paredes y las puertas cerradas tapan como siempre (vm.has_line_of_sight, en el mapa).
## - Los suelos tapan de verdad: una losa (Suelo.losas) entre los ojos de uno y los del otro corta la mirada. Por eso
##   desde el salón de la posada se ve a quien está en el borde de la galería, pero no a quien está encima de ti.
## - Bajo tierra (nivel −1) nunca se ve desde la calle ni al revés.
## - Oído (5b): a través de un suelo se oye a un tercio, como a través de una pared; entre la calle y bajo tierra, casi nada.
## - Golpes (5c): `alcanza` dice si dos personas están a altura de golpearse (pies a menos de ALCANCE_VERTICAL_PX).
## - Donde aún no hay alturas conocidas (pisos de las casas, hasta el paso 2e), dos niveles distintos no se ven, como antes.

const Suelo = preload("res://scripts/fisica/Suelo.gd")
const WorldStageBase3D = preload("res://scripts/visuals/WorldStageBase3D.gd")

const ALTO_OJOS_PX: float = WorldStageBase3D.FP_EYE_HEIGHT_PX
const SORDINA_SUELO: float = 0.35  ## lo que queda de un ruido al pasar por un suelo (igual que por una pared)
const SORDINA_TIERRA: float = 0.1  ## entre la calle y el club o las alcantarillas
const ALCANCE_VERTICAL_PX: float = 12.0 ## ~1,3 m: hasta esa diferencia de altura de los pies llega un golpe
const ALTO_CUERPO_PX: float = 17.0  ## lo que mide alguien de pie (una flecha por encima no le da)


## ¿Desde `a` (en el piso `nivel_a`) se ve `b` (en el piso `nivel_b`)?
static func ve(vm: Node, a: Vector2, nivel_a: int, b: Vector2, nivel_b: int) -> bool:
	if (nivel_a == -1) != (nivel_b == -1):
		return false
	if nivel_a != nivel_b and Suelo.pisos_en(a).is_empty() and Suelo.pisos_en(b).is_empty():
		return false
	if not vm.has_line_of_sight(a, b):
		return false
	return not tapa_un_suelo(a, altura_ojos(a, nivel_a, vm), b, altura_ojos(b, nivel_b, vm))


## Cuánto llega (0..1) de un ruido hecho en `a` (piso `nivel_a`) a alguien en `b` (piso `nivel_b`), por suelos y tierra.
## Las paredes las descuenta aparte quien lo llama (AudioManager).
static func oye(vm: Node, a: Vector2, nivel_a: int, b: Vector2, nivel_b: int) -> float:
	if (nivel_a == -1) != (nivel_b == -1):
		return SORDINA_TIERRA
	if nivel_a != nivel_b and Suelo.pisos_en(a).is_empty() and Suelo.pisos_en(b).is_empty():
		return SORDINA_SUELO
	return SORDINA_SUELO if tapa_un_suelo(a, altura_ojos(a, nivel_a, vm), b, altura_ojos(b, nivel_b, vm)) else 1.0


## ¿Alguien en `a` (piso `nivel_a`) llega a golpear a quien está en `b` (piso `nivel_b`)? Por altura; el alcance en el
## mapa lo mira quien golpea.
static func alcanza(vm: Node, a: Vector2, nivel_a: int, b: Vector2, nivel_b: int) -> bool:
	return absf(altura_pies(a, nivel_a, vm) - altura_pies(b, nivel_b, vm)) <= ALCANCE_VERTICAL_PX


## Altura de los pies de alguien en `pos` (px de altura, con relieve).
static func altura_pies(pos: Vector2, nivel: int, vm: Node) -> float:
	return WorldStageBase3D.terrain_height_px(pos) + Suelo.altura_px(pos, nivel, vm)


## Altura de los ojos de alguien de pie en `pos` (px de altura, con relieve).
static func altura_ojos(pos: Vector2, nivel: int, vm: Node) -> float:
	return altura_pies(pos, nivel, vm) + ALTO_OJOS_PX


## ¿Alguna losa corta la recta entre el punto `a` (a `ha` px de altura) y el punto `b` (a `hb` px)?
static func tapa_un_suelo(a: Vector2, ha: float, b: Vector2, hb: float) -> bool:
	for losa in Suelo.losas():
		var h: float = losa["h"]
		if (ha - h) * (hb - h) >= 0.0:
			continue # los dos ojos al mismo lado de la losa
		if Suelo.en_losa(losa, a.lerp(b, (h - ha) / (hb - ha))):
			return true
	return false
