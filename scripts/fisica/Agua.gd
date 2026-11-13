extends RefCounted

## Agua: dónde hay agua (río y lago), a qué altura está su superficie y cuánto cubre en cada punto.
## Paso del mundo a 3D, paso 3 (docs/PLAN_MUNDO_3D.md), 2026-11-10.
## - La superficie es la misma lámina que dibuja el escenario 3D (río: altura de la orilla; lago: cota fija).
## - El fondo no se dibuja todavía: la hondura es de juego (más hondo en el centro, poco en las orillas; el arroyo del
##   norte casi se vadea). El cuerpo 3D la usa para vadear o nadar.

const RioLagoScript = preload("res://scripts/fisica/RioLago.gd")
const WorldStageBase3D = preload("res://scripts/visuals/WorldStageBase3D.gd")
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Zona = preload("res://mapa/zona.gd")

const SUPERFICIE_LAGO_PX: float = -0.8 ## la lámina honda del lago (WorldStageTerrain3D._build_lake_3d)
const HONDO_RIO_M: float = 2.2         ## en el centro del río ancho (pueblo): ahí no se hace pie
const HONDO_ARROYO_M: float = 0.6      ## en el centro del arroyo estrecho (bosque norte): se vadea
const HONDO_LAGO_M: float = 3.5        ## en el centro del lago
const ORILLA_LAGO_PX: float = 60.0     ## distancia a la orilla a la que el lago ya es hondo del todo
const MUELLE_LAGO: Rect2 = Rect2(Vector2(-703.0, 94.0), Vector2(38.0, 22.0)) ## el muelle de madera no es agua (mapa original)

## El muelle en coordenadas del mapa original, donde esté la orilla este del agua dibujada (mapa ×E).
static func muelle_lago() -> Rect2:
	if Mapa3D.E == 1.0:
		return MUELLE_LAGO
	var c: Vector2 = Zona.desestirar(RioLagoScript.lake_dock_center())
	return Rect2(c - Vector2(22.0, 8.0) / Mapa3D.E, Vector2(44.0, 16.0) / Mapa3D.E).grow(2.0)


static func en_lago(pos: Vector2) -> bool:
	var o: Vector2 = Zona.desestirar(pos) # el lago está escrito en el mapa original y va con su pieza de «Zonas»
	return Geometry2D.is_point_in_polygon(o, RioLagoScript.lake_water()) and not muelle_lago().has_point(o)


static func en_rio(pos: Vector2) -> bool:
	return RioLagoScript.is_point_in_river_water(pos)


static func en_agua(pos: Vector2) -> bool:
	return en_rio(pos) or en_lago(pos)


## Altura 3D (metros) de la superficie del agua en `pos`. Solo vale donde `en_agua(pos)`.
static func superficie_y(pos: Vector2) -> float:
	if en_lago(pos):
		return Mapa3D.alto_a_3d(SUPERFICIE_LAGO_PX)
	return Mapa3D.alto_a_3d(WorldStageBase3D.superficie_rio_px(pos.y))


## Cuánta agua hay en `pos` (metros de la superficie al fondo). 0 fuera del agua.
static func hondura_m(pos: Vector2) -> float:
	if en_lago(pos):
		var poli: PackedVector2Array = RioLagoScript.lake_water_world() # mapa ×E, el agua tal como se dibuja
		var a_orilla: float = INF
		for i in range(poli.size()):
			var cerca: Vector2 = Geometry2D.get_closest_point_to_segment(pos, poli[i], poli[(i + 1) % poli.size()])
			a_orilla = minf(a_orilla, pos.distance_to(cerca))
		return maxf(0.2, HONDO_LAGO_M * smoothstep(0.0, ORILLA_LAGO_PX, a_orilla))
	if en_rio(pos):
		var orillas: Vector2 = RioLagoScript.river_banks_at(pos.y)
		var medio: float = (orillas.x + orillas.y) * 0.5
		var semiancho: float = maxf(1.0, (orillas.y - orillas.x) * 0.5)
		var centro: float = 1.0 - pow(clampf(absf(pos.x - medio) / semiancho, 0.0, 1.0), 2.0)
		var maximo: float = lerpf(HONDO_ARROYO_M, HONDO_RIO_M, smoothstep(12.0, 24.0, semiancho))
		return maxf(0.15, maximo * centro)
	return 0.0
