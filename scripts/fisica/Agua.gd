extends RefCounted

## Agua: dónde hay agua (río y lago), a qué altura está su superficie y cuánto cubre en cada punto.
## - La superficie es la misma lámina que dibuja el escenario 3D (río: altura de la orilla; lago: cota fija).
## - La hondura es más honda en el centro y somera en las orillas; el cuerpo 3D la usa para vadear o nadar.

const RioLagoScript = preload("res://scripts/fisica/RioLago.gd")
const WorldStageBase3D = preload("res://scripts/visuals/WorldStageBase3D.gd")
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

const SUPERFICIE_LAGO_COTA: float = -0.8 ## la lámina honda del lago (WorldStageTerrain3D._build_lake_3d)
const HONDO_RIO_M: float = 2.2           ## en el centro del río ancho (pueblo): ahí no se hace pie
const HONDO_ARROYO_M: float = 0.6        ## en el centro del arroyo estrecho (bosque norte): se vadea
const HONDO_LAGO_M: float = 3.5          ## en el centro del lago
const ORILLA_LAGO_DIST: float = 60.0     ## distancia a la orilla a la que el lago ya es hondo del todo


## Recinto del muelle de madera en coordenadas reales del mundo (sigue a la orilla este del lago).
static func muelle_lago_mundo() -> Rect2:
	var c: Vector2 = RioLagoScript.lake_dock_center()
	return Rect2(c - Vector2(22.0, 8.0), Vector2(44.0, 16.0)).grow(10.0)


static func en_lago(pos: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(pos, RioLagoScript.lake_water_world()) and not muelle_lago_mundo().has_point(pos)


static func en_rio(pos: Vector2) -> bool:
	return RioLagoScript.is_point_in_river_water(pos)


static func en_agua(pos: Vector2) -> bool:
	return en_rio(pos) or en_lago(pos)


## Altura 3D (metros) de la superficie del agua en `pos`. Solo vale donde `en_agua(pos)`.
static func superficie_y(pos: Vector2) -> float:
	if en_lago(pos):
		return Mapa3D.alto_a_3d(SUPERFICIE_LAGO_COTA)
	return Mapa3D.alto_a_3d(WorldStageBase3D.superficie_rio_px(pos.y))


## Cuánta agua hay en `pos` (metros de la superficie al fondo). 0 fuera del agua.
static func hondura_m(pos: Vector2) -> float:
	if en_lago(pos):
		var poli: PackedVector2Array = RioLagoScript.lake_water_world()
		var d2_orilla: float = INF
		for i in range(poli.size()):
			var cerca: Vector2 = Geometry2D.get_closest_point_to_segment(pos, poli[i], poli[(i + 1) % poli.size()])
			d2_orilla = minf(d2_orilla, pos.distance_squared_to(cerca))
		return maxf(0.2, HONDO_LAGO_M * smoothstep(0.0, ORILLA_LAGO_DIST, sqrt(d2_orilla)))
	if en_rio(pos):
		var orillas: Vector2 = RioLagoScript.river_banks_at(pos.y)
		var medio: float = (orillas.x + orillas.y) * 0.5
		var semiancho: float = maxf(1.0, (orillas.y - orillas.x) * 0.5)
		var centro: float = 1.0 - pow(clampf(absf(pos.x - medio) / semiancho, 0.0, 1.0), 2.0)
		var maximo: float = lerpf(HONDO_ARROYO_M, HONDO_RIO_M, smoothstep(12.0, 24.0, semiancho))
		return maxf(0.15, maximo * centro)
	return 0.0
