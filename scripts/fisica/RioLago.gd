@tool
extends Node2D
class_name RioLago

## Forma del río y del Lago del Oeste: orillas, puentes, vados y contorno del agua (lo usan el terreno 3D, el agua para
## nadar, los vecinos y el editor del mapa). Como nodo, solo pone el choque del agua del lago para los vecinos.
## Antes vivía dentro de la pesca; la pesca se borró el 2026-11-12 (se rehará en 3D tras el Caso I).

const MUELLE_LARGO: float = 38.0   ## hueco del choque para pisar el muelle: lo que entra en el agua
const MUELLE_ANCHO: float = 12.0   ## medio ancho del hueco
const MUELLE_FUERA: float = 8.0    ## lo que el hueco sale del agua hacia la orilla

## Río y arroyo que cruza el pueblo de norte a sur (Caso I: molino viejo abandonado, claro del arroyo y puente viejo).
const ABANDONED_MILL_CENTER := Vector2(188.0, -1060.0)
const ABANDONED_MILL_SIZE := Vector2(124.0, 92.0)
const ABANDONED_MILL_RECT := Rect2(Vector2(126.0, -1106.0), Vector2(124.0, 92.0))

## Editor del mapa (2026-11-09; en 3D desde el 2026-11-12): el río y sus puentes se leen de mapa/Mundo3D.tscn
## (carpetas «Rio» y «Cruces», mapa/rio_forma.gd). Mientras el usuario arrastra un punto, el editor pasa lo vivo
## con `usar_datos` para rehacer el agua de la maqueta.
const MAPA_ESCENA := "res://mapa/Mundo3D.tscn"
const RioForma = preload("res://mapa/rio_forma.gd")
const SIN_RIO: Dictionary = {"pts": [], "hw": [], "natural": 1.0, "cruces": []}
const CRUCE_SOBRA_PX: float = 8.0 ## un puente o vado sobresale algo de cada orilla
static var _mapa_cargado: bool = false
static var _rio: Dictionary = SIN_RIO
static var _cruces: Array[Dictionary] = []

static func _cargar_mapa() -> void:
	if _mapa_cargado:
		return
	var d: Dictionary = RioForma.leer_escena(MAPA_ESCENA)
	if d.is_empty() or (d["pts"] as Array).size() < 2:
		push_error("RIO: el editor del mapa no tiene río (carpeta «Rio» de mapa/Mundo3D.tscn)")
		d = SIN_RIO
	usar_datos(d)

## Usa este río (el leído de la escena, o el que el usuario está moviendo en el editor).
static func usar_datos(d: Dictionary) -> void:
	_mapa_cargado = true
	_rio = d
	load("res://scripts/visuals/WorldStageBase3D.gd").olvidar_relieve() # el relieve se allana en el cauce: su memoria ya no vale
	_cruces.assign(d["cruces"])
	# Un puente o vado abarca siempre el agua de orilla a orilla, aunque el editor guarde un largo más corto (río ensanchado)
	for cr in _cruces:
		var b: Vector2 = river_banks_at(float((cr["pos"] as Vector2).y))
		cr["half_w"] = maxf(float(cr["half_w"]), (b.y - b.x) * 0.5 + CRUCE_SOBRA_PX)

## Puntos del río de norte a sur.
static func river_waypoints() -> Array[Vector2]:
	_cargar_mapa()
	var out: Array[Vector2] = []
	out.assign(_rio["pts"])
	return out

static func river_crossings() -> Array[Dictionary]:
	_cargar_mapa()
	return _cruces

static func river_y_start() -> float:
	var w: Array[Vector2] = river_waypoints()
	return 0.0 if w.is_empty() else w[0].y

static func river_y_end() -> float:
	var w: Array[Vector2] = river_waypoints()
	return 0.0 if w.is_empty() else w[w.size() - 1].y

static func river_center_x(y: float) -> float:
	_cargar_mapa()
	return RioForma.center_x(_rio, y)

static func river_half_width(y: float) -> float:
	_cargar_mapa()
	return RioForma.half_width(_rio, y)

static func river_banks_at(y: float) -> Vector2:
	_cargar_mapa()
	return RioForma.banks_at(_rio, y)

static func is_in_river_crossing(pos: Vector2, margin_y: float = 0.0) -> bool:
	for cr in river_crossings():
		var cpos: Vector2 = cr["pos"]
		var hh: float = float(cr["half_h"]) + margin_y
		var hw: float = float(cr["half_w"]) + 10.0
		if absf(pos.y - cpos.y) <= hh and absf(pos.x - cpos.x) <= hw:
			return true
	return false

static func is_point_in_river_water(pos: Vector2, extra_margin: float = 0.0) -> bool:
	if pos.y < river_y_start() - 5.0 or pos.y > river_y_end() + 5.0:
		return false
	if is_in_river_crossing(pos, -1.0):
		return false
	var banks: Vector2 = river_banks_at(pos.y)
	return pos.x >= (banks.x - extra_margin) and pos.x <= (banks.y + extra_margin)

static func nearest_river_crossing(from_pos: Vector2, to_pos: Vector2) -> Dictionary:
	var crs: Array[Dictionary] = river_crossings()
	var best: Dictionary = crs[0] if not crs.is_empty() else {}
	var best_cost: float = INF
	for cr in crs:
		var cpos: Vector2 = cr["pos"]
		var cost: float = from_pos.distance_to(cpos) + cpos.distance_to(to_pos)
		if str(cr["id"]) == "old_bridge":
			cost -= 18.0 # Ligera preferencia natural por el Puente Viejo en el centro del pueblo
		if cost < best_cost:
			best_cost = cost
			best = cr
	return best

## Lago del Oeste en coordenadas reales del mundo y orilla del agua (un solo muelle al este; sigue a su pieza en «Zonas»).
const LAKE_NODE_POS := Vector2(-715, 105) ## compatibilidad con World.gd:97 mientras coloca LagoOeste
const LAGO_NODO_BASE := Vector2(-3575.0, 525.0)
const MUELLE_ENTRADA: float = 18.0 ## lo que el muelle se mete en el agua desde la orilla este
const Zona = preload("res://mapa/zona.gd")
const CONTORNO_LAGO_BASE: Array[Vector2] = [
	Vector2(-3550.0, 380.0), Vector2(-3360.0, 410.0), Vector2(-3325.0, 525.0), Vector2(-3375.0, 710.0),
	Vector2(-3600.0, 820.0), Vector2(-3925.0, 930.0), Vector2(-4275.0, 1070.0), Vector2(-4625.0, 1190.0),
	Vector2(-5025.0, 1210.0), Vector2(-5325.0, 1030.0), Vector2(-5410.0, 750.0), Vector2(-5290.0, 510.0),
	Vector2(-4950.0, 410.0), Vector2(-4550.0, 400.0), Vector2(-4175.0, 410.0), Vector2(-3800.0, 400.0),
]


## Contorno redondeado del lago en coordenadas reales del mundo (sigue a su pieza en «Zonas»).
static func lake_outline_world() -> PackedVector2Array:
	var base := PackedVector2Array(CONTORNO_LAGO_BASE)
	for _k in range(2):
		var suave := PackedVector2Array()
		for i in range(base.size()):
			var a: Vector2 = base[i]
			var b: Vector2 = base[(i + 1) % base.size()]
			suave.append(a.lerp(b, 0.25))
			suave.append(a.lerp(b, 0.75))
		base = suave
	var desplaz: Vector2 = Zona.desplazamiento("lago")
	if desplaz == Vector2.ZERO:
		return base
	var out := PackedVector2Array()
	for v: Vector2 in base:
		out.append(v + desplaz)
	return out


## El agua del lago que cuenta para nadar, chocar y situar el muelle (coordenadas reales del mundo).
static func lake_water_world() -> PackedVector2Array:
	return lake_outline_world()


## Orilla este del agua del lago a la altura `y_mundo`: la x mayor donde aún hay agua.
static func orilla_este_lago_x(y_mundo: float) -> float:
	var poli: PackedVector2Array = lake_water_world()
	var mejor: float = -INF
	for i in range(poli.size()):
		var a: Vector2 = poli[i]
		var b: Vector2 = poli[(i + 1) % poli.size()]
		if (a.y <= y_mundo and b.y >= y_mundo) or (b.y <= y_mundo and a.y >= y_mundo):
			var x_corte: float = maxf(a.x, b.x) if absf(b.y - a.y) < 0.001 else a.x + (b.x - a.x) * (y_mundo - a.y) / (b.y - a.y)
			mejor = maxf(mejor, x_corte)
	return mejor if mejor > -INF else (CONTORNO_LAGO_BASE[2].x + Zona.desplazamiento("lago").x)


## Centro del muelle del lago en el mundo: en la orilla este del agua, metido hacia dentro.
static func lake_dock_center() -> Vector2:
	var y_nodo: float = LAGO_NODO_BASE.y + Zona.desplazamiento("lago").y
	return Vector2(orilla_este_lago_x(y_nodo) - MUELLE_ENTRADA, y_nodo)


## Polígono del lago escalado respecto a su centro en coordenadas reales del mundo (lámina exterior y zona honda).
static func lake_scaled_world(factor: float, margen_mundo: float = 0.0) -> PackedVector2Array:
	var base: PackedVector2Array = lake_outline_world()
	var c := Vector2.ZERO
	for v: Vector2 in base:
		c += v
	c /= float(base.size())
	var out := PackedVector2Array()
	for v: Vector2 in base:
		var d: Vector2 = v - c
		out.append(c + d * factor + d.normalized() * margen_mundo)
	return out


## Compatibilidad temporal para VillageManagerSocial.gd:477 (multiplica el resultado por 5).
static func lake_scaled(factor: float, margen_viejo: float = 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v: Vector2 in lake_scaled_world(factor, margen_viejo * 5.0):
		out.append(v * 0.2)
	return out


func _ready() -> void:
	if not Engine.is_editor_hint():
		_poner_choque_del_agua()


## Los vecinos no entran en el lago; el protagonista (cuerpo 3D) sí, porque busca el grupo «agua_2d» para nadar.
func _poner_choque_del_agua() -> void:
	var body := StaticBody2D.new()
	body.name = "LakeWaterBody"
	body.add_to_group("agua_2d")
	body.collision_layer = 1
	body.collision_mask = 0
	var nodo_mundo: Vector2 = LAGO_NODO_BASE + Zona.desplazamiento("lago")
	var pts := PackedVector2Array()
	for v: Vector2 in lake_water_world():
		pts.append(v - nodo_mundo)
	# Hueco para caminar sobre el muelle de madera sin pisar el agua
	var sx: float = orilla_este_lago_x(nodo_mundo.y) - nodo_mundo.x
	var x0: float = sx - MUELLE_LARGO
	var x1: float = sx + MUELLE_FUERA
	var hueco := PackedVector2Array([Vector2(x0, -MUELLE_ANCHO), Vector2(x1, -MUELLE_ANCHO), Vector2(x1, MUELLE_ANCHO), Vector2(x0, MUELLE_ANCHO)])
	var recorte: Array[PackedVector2Array] = Geometry2D.clip_polygons(pts, hueco)
	if not recorte.is_empty():
		pts = recorte[0]
	var col_poly := CollisionPolygon2D.new()
	col_poly.polygon = pts
	body.add_child(col_poly)
	add_child(body)
