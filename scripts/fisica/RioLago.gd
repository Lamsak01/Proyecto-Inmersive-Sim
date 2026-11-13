@tool
extends Node2D
class_name RioLago
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd") # mapa ×E (sin ciclos: Mapa3D no carga nada)

## Forma del río y del Lago del Oeste: orillas, puentes, vados y contorno del agua (lo usan el terreno 3D, el agua para
## nadar, los vecinos y el editor del mapa). Como nodo, solo pone el choque del agua del lago para los vecinos.
## Antes vivía dentro de la pesca; la pesca se borró el 2026-11-12 (se rehará en 3D tras el Caso I).

const MUELLE_LARGO_PX: float = 38.0   ## hueco del choque para pisar el muelle: lo que entra en el agua (mapa ×E)
const MUELLE_ANCHO_PX: float = 12.0   ## medio ancho del hueco
const MUELLE_FUERA_PX: float = 8.0    ## lo que el hueco sale del agua hacia la orilla

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

## Lago del Oeste: posición del nodo en el mapa original (World.gd lo coloca) y orilla del agua (un solo muelle al este).
const LAKE_NODE_POS := Vector2(-715, 105)
const DOCK_INSET_PX: float = 18.0 ## lo que el muelle se mete en el agua desde la orilla este
const Zona = preload("res://mapa/zona.gd")
const LAKE_WATER_WORLD: Array[Vector2] = [
	Vector2(-710, 76), Vector2(-672, 82), Vector2(-665, 105), Vector2(-675, 142), Vector2(-720, 164),
	Vector2(-785, 186), Vector2(-855, 214), Vector2(-925, 238), Vector2(-1005, 242), Vector2(-1065, 206),
	Vector2(-1082, 150), Vector2(-1058, 102), Vector2(-990, 82), Vector2(-910, 80), Vector2(-835, 82),
	Vector2(-760, 80),
]


## Contorno del lago en el mapa original. Con el mapa ×E se redondea (dos pasadas de cortar esquinas): los 16 vértices
## estirados ×5 se verían como un bloque de lados rectos.
static func lake_outline() -> PackedVector2Array:
	var out := PackedVector2Array(LAKE_WATER_WORLD)
	if Mapa3D.E == 1.0:
		return out
	for _k in range(2):
		var suave := PackedVector2Array()
		for i in range(out.size()):
			var a: Vector2 = out[i]
			var b: Vector2 = out[(i + 1) % out.size()]
			suave.append(a.lerp(b, 0.25))
			suave.append(a.lerp(b, 0.75))
		out = suave
	return out


## El mismo contorno en el mundo (mapa ×E).
static func lake_outline_world() -> PackedVector2Array:
	return Zona.estirar_puntos(lake_outline()) # va con la pieza del lago («Zonas» del editor)


## El agua del lago que se ve: la cuenca del relieve se hunde hasta el contorno (factor 1); la lámina dibujada un poco
## más grande (1,12) queda tapada por la hierba. Es la que cuenta para nadar, chocar y el muelle.
static func lake_water() -> PackedVector2Array:
	return lake_outline()

static func lake_water_world() -> PackedVector2Array:
	return Zona.estirar_puntos(lake_water())

## Orilla este del agua dibujada a la altura `y` (coordenadas del mapa original): la x mayor donde aún hay agua.
static func lake_east_shore_x(y: float) -> float:
	var poli: PackedVector2Array = lake_water()
	var mejor: float = -INF
	for i in range(poli.size()):
		var a: Vector2 = poli[i]
		var b: Vector2 = poli[(i + 1) % poli.size()]
		if (a.y <= y and b.y >= y) or (b.y <= y and a.y >= y):
			if absf(b.y - a.y) < 0.001:
				mejor = maxf(mejor, maxf(a.x, b.x))
			else:
				mejor = maxf(mejor, a.x + (b.x - a.x) * (y - a.y) / (b.y - a.y))
	return mejor if mejor > -INF else LAKE_WATER_WORLD[2].x

## Centro del muelle del lago en el mundo: en la orilla este del agua dibujada, a la altura del nodo, metido 18 px.
static func lake_dock_center() -> Vector2:
	return Zona.estirar(Vector2(lake_east_shore_x(LAKE_NODE_POS.y), LAKE_NODE_POS.y)) - Vector2(DOCK_INSET_PX, 0.0)


## Polígono escalado respecto a su centro (para la orilla de arena y la zona honda).
static func lake_scaled(factor: float, grow_px: float = 0.0) -> PackedVector2Array:
	var base: PackedVector2Array = lake_outline()
	var c := Vector2.ZERO
	for v in base:
		c += v
	c /= float(base.size())
	var out := PackedVector2Array()
	for v in base:
		var d: Vector2 = v - c
		out.append(c + d * factor + d.normalized() * grow_px)
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
	var pts := PackedVector2Array()
	for v in lake_water():
		pts.append((v - LAKE_NODE_POS) * Mapa3D.E)
	# Hueco para caminar sobre el muelle de madera sin pisar el agua
	var sx: float = (lake_east_shore_x(LAKE_NODE_POS.y) - LAKE_NODE_POS.x) * Mapa3D.E
	var x0: float = sx - MUELLE_LARGO_PX
	var x1: float = sx + MUELLE_FUERA_PX
	var hueco := PackedVector2Array([Vector2(x0, -MUELLE_ANCHO_PX), Vector2(x1, -MUELLE_ANCHO_PX), Vector2(x1, MUELLE_ANCHO_PX), Vector2(x0, MUELLE_ANCHO_PX)])
	var recorte: Array[PackedVector2Array] = Geometry2D.clip_polygons(pts, hueco)
	if not recorte.is_empty():
		pts = recorte[0]
	var col_poly := CollisionPolygon2D.new()
	col_poly.polygon = pts
	body.add_child(col_poly)
	add_child(body)
