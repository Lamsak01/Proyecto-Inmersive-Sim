extends RefCounted

## Vista: ¿puede alguien ver a otro, con las alturas de verdad? Paso del mundo a 3D, paso 5a (docs/PLAN_MUNDO_3D.md),
## 2026-11-10. Un solo sitio para testigos, guardias y vecinos.
## - Las paredes y las puertas cerradas tapan como siempre (vm.has_line_of_sight, en el mapa).
## - Los suelos tapan de verdad: una losa (Suelo.losas) entre los ojos de uno y los del otro corta la mirada. Por eso
##   desde el salón de la posada se ve a quien está en el borde de la galería, pero no a quien está encima de ti.
## - Bajo tierra (nivel −1) nunca se ve desde la calle ni al revés.
## - Donde aún no hay alturas conocidas (pisos de las casas, hasta el paso 2e), dos niveles distintos no se ven, como antes.

const Suelo = preload("res://scripts/fisica/Suelo.gd")
const Anclas = preload("res://mapa/anclas.gd")
const WorldStageBase3D = preload("res://scripts/visuals/WorldStageBase3D.gd")

const ALTO_OJOS_PX: float = WorldStageBase3D.FP_EYE_HEIGHT_PX


## ¿Desde `a` (en el piso `nivel_a`) se ve `b` (en el piso `nivel_b`)?
static func ve(vm: Node, a: Vector2, nivel_a: int, b: Vector2, nivel_b: int) -> bool:
	if (nivel_a == -1) != (nivel_b == -1):
		return false
	if nivel_a != nivel_b and Suelo.pisos_en(a).is_empty() and Suelo.pisos_en(b).is_empty():
		return false
	if not vm.has_line_of_sight(a, b):
		return false
	return not _tapa_un_suelo(a, altura_ojos(a, nivel_a, vm), b, altura_ojos(b, nivel_b, vm))


## Altura de los ojos de alguien de pie en `pos` (px de altura, con relieve).
static func altura_ojos(pos: Vector2, nivel: int, vm: Node) -> float:
	return WorldStageBase3D.terrain_height_px(pos) + Suelo.altura_px(pos, nivel, vm) + ALTO_OJOS_PX


## ¿Alguna losa corta la recta entre los ojos de `a` (a `ha` px) y los de `b` (a `hb` px)?
static func _tapa_un_suelo(a: Vector2, ha: float, b: Vector2, hb: float) -> bool:
	for losa in Suelo.losas():
		var h: float = losa["h"]
		if (ha - h) * (hb - h) >= 0.0:
			continue # los dos ojos al mismo lado de la losa
		var cruce: Vector2 = Anclas.desmover(a.lerp(b, (h - ha) / (hb - ha)))
		if (losa["rect"] as Rect2).has_point(cruce) and not (losa["hueco"] as Rect2).has_point(cruce):
			return true
	return false
