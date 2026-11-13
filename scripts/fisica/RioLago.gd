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
const OLD_BRIDGE_POS := Vector2(126.0, 50.0)

const RIVER_WAYPOINTS: Array[Vector2] = [
	Vector2(108.0, -1180.0),
	Vector2(114.0, -1060.0),
	Vector2(106.0, -960.0),
	Vector2(102.0, -860.0),
	Vector2(82.0, -785.0),
	Vector2(88.0, -700.0),
	Vector2(174.0, -615.0),
	Vector2(182.0, -510.0),
	Vector2(76.0, -430.0),
	Vector2(96.0, -351.0),
	Vector2(158.0, -295.0),
	Vector2(66.0, -218.0),
	Vector2(164.0, -138.0),
	Vector2(78.0, -58.0),
	Vector2(130.0, 15.0),
	Vector2(126.0, 50.0),
	Vector2(132.0, 88.0),
	Vector2(44.0, 165.0),
	Vector2(96.0, 242.0),
	Vector2(48.0, 312.0),
	Vector2(152.0, 372.0),
	Vector2(158.0, 408.0),
	Vector2(158.0, 535.0),
	Vector2(132.0, 610.0),
	Vector2(88.0, 695.0),
	Vector2(112.0, 772.0),
	Vector2(138.0, 855.0),
	Vector2(96.0, 940.0),
]

## Puentes y vados por los que cruzan vecinos y jugador (el resto del cauce es agua profunda bloqueada).
const RIVER_CROSSINGS: Array[Dictionary] = [
	{"id": "ford_clearing", "label": "Vado del Claro", "pos": Vector2(102.0, -860.0), "half_h": 18.0, "half_y": 18.0, "half_w": 26.0, "kind": "ford", "arch_h": 0.35},
	{"id": "bridge_north", "label": "Pasarela del Arroyo Norte", "pos": Vector2(96.0, -351.0), "half_h": 16.0, "half_y": 16.0, "half_w": 42.0, "kind": "wood_bridge", "arch_h": 1.1},
	{"id": "old_bridge", "label": "Puente Viejo", "pos": Vector2(126.0, 50.0), "half_h": 21.0, "half_y": 21.0, "half_w": 52.0, "kind": "stone_wood_bridge", "arch_h": 2.4},
	{"id": "south_fields_bridge", "label": "Puente de los Campos", "pos": Vector2(152.0, 372.0), "half_h": 17.0, "half_y": 17.0, "half_w": 36.0, "kind": "wood_bridge", "arch_h": 1.2},
	{"id": "forest_ford", "label": "Vado del Bosque", "pos": Vector2(112.0, 772.0), "half_h": 19.0, "half_y": 19.0, "half_w": 38.0, "kind": "ford", "arch_h": 0.35},
]

## Editor del mapa (Claude Code, 2026-11-09): el río y sus puentes se leen de res://mapa/EditorMapa.tscn.
## Mientras los puntos del río sigan como el mapa original, se usa la forma antigua de siempre (con sus ajustes
## a mano junto a edificios); en cuanto el usuario mueve, añade o quita un punto, manda lo dibujado en el editor.
const MAPA_ESCENA := "res://mapa/EditorMapa.tscn"
const RioForma = preload("res://mapa/rio_forma.gd")
static var _mapa_cargado: bool = false
static var _rio_propio: bool = false
static var _rio: Dictionary = {}
static var _cruces: Array[Dictionary] = []

static func _cargar_mapa() -> void:
	if _mapa_cargado:
		return
	_mapa_cargado = true
	_cruces = RIVER_CROSSINGS.duplicate(true)
	var d: Dictionary = RioForma.leer_escena(MAPA_ESCENA)
	if d.is_empty() or (d["pts"] as Array).size() < 2:
		return
	_rio = d
	load("res://scripts/visuals/WorldStageBase3D.gd").olvidar_relieve() # el relieve se allana en el cauce: su memoria ya no vale
	if not (d["cruces"] as Array).is_empty():
		_cruces.assign(d["cruces"])
	_rio_propio = not es_rio_original(d)
	# Un puente o vado abarca siempre el agua de orilla a orilla, aunque el editor guarde un largo más corto (río ensanchado)
	for cr in _cruces:
		var b: Vector2 = river_banks_at(float((cr["pos"] as Vector2).y))
		cr["half_w"] = maxf(float(cr["half_w"]), (b.y - b.x) * 0.5 + 8.0)

static func es_rio_original(d: Dictionary) -> bool:
	var pts: Array = d["pts"]
	if pts.size() != RIVER_WAYPOINTS.size() or absf(float(d["natural"]) - 1.0) > 0.01:
		return false
	for i in range(pts.size()):
		if pts[i].distance_to(RIVER_WAYPOINTS[i]) > 0.5:
			return false
		if absf(float(d["hw"][i]) - ancho_original(RIVER_WAYPOINTS[i].y) * 0.5) > 0.3:
			return false
	return true

## Ancho (de orilla a orilla) que tenía el río original en esa altura, redondeado como lo guarda el editor.
static func ancho_original(y: float) -> float:
	return roundf(_antiguo_half_width(y) * 4.0) * 0.5

## Puntos del río de norte a sur (los del editor si existen).
static func river_waypoints() -> Array[Vector2]:
	_cargar_mapa()
	if _rio_propio:
		var out: Array[Vector2] = []
		out.assign(_rio["pts"])
		return out
	return RIVER_WAYPOINTS

static func river_crossings() -> Array[Dictionary]:
	_cargar_mapa()
	return _cruces

static func river_y_start() -> float:
	return river_waypoints()[0].y

static func river_y_end() -> float:
	var w: Array[Vector2] = river_waypoints()
	return w[w.size() - 1].y

static func river_center_x(y: float) -> float:
	_cargar_mapa()
	return RioForma.center_x(_rio, y) if _rio_propio else _antiguo_center_x(y)

static func river_half_width(y: float) -> float:
	_cargar_mapa()
	return RioForma.half_width(_rio, y) if _rio_propio else _antiguo_half_width(y)

static func river_banks_at(y: float) -> Vector2:
	_cargar_mapa()
	return RioForma.banks_at(_rio, y) if _rio_propio else _antiguo_banks_at(y)

static func _antiguo_center_x(y: float) -> float:
	if y <= RIVER_WAYPOINTS[0].y:
		return RIVER_WAYPOINTS[0].x
	var last_idx: int = RIVER_WAYPOINTS.size() - 1
	if y >= RIVER_WAYPOINTS[last_idx].y:
		return RIVER_WAYPOINTS[last_idx].x
	for i in range(last_idx):
		var p0: Vector2 = RIVER_WAYPOINTS[i]
		var p1: Vector2 = RIVER_WAYPOINTS[i + 1]
		if y >= p0.y and y <= p1.y:
			var t: float = (y - p0.y) / maxf(0.001, p1.y - p0.y)
			var st: float = t * t * (3.0 - 2.0 * t)
			var base_x: float = lerpf(p0.x, p1.x, st)
			# Meandros orgánicos pronunciados en el pueblo para romper cualquier línea recta (atenuados en pasos estrechos y puentes)
			var narrow_damp: float = 0.20 if ((y >= -640.0 and y <= -480.0) or (y >= 390.0 and y <= 550.0) or absf(y - 50.0) < 28.0 or absf(y - (-351.0)) < 22.0 or absf(y - 372.0) < 24.0 or absf(y - (-1060.0)) < 45.0) else 1.0
			var town_meander_boost: float = 1.65 if (y >= -320.0 and y <= 340.0) else 1.0
			var meander: float = (sin(y * 0.037 + 0.6) * 7.8 + cos(y * 0.073 - 0.5) * 4.4 + sin(y * 0.119 + 1.4) * 2.2) * narrow_damp * town_meander_boost
			return base_x + meander
	return 126.0

static func _antiguo_half_width(y: float) -> float:
	# En el pueblo (y = -240..270) es un río caudaloso con remansos anchos y estrechamientos naturales.
	# Al subir hacia el norte (y = -240..-820) se estrecha poco a poco hasta ser un arroyo (~18..21 px)
	# junto al Claro del Caso I (y = -860) y el Molino Viejo Abandonado (y = -1060).
	var base_hw: float = 29.5
	if y <= -920.0:
		base_hw = lerpf(9.2, 10.2, smoothstep(-1150.0, -920.0, y))
	elif y <= -780.0:
		base_hw = lerpf(10.2, 12.2, smoothstep(-920.0, -780.0, y))
	elif y < -210.0:
		base_hw = lerpf(12.2, 29.5, smoothstep(-780.0, -210.0, y))
	elif y <= 255.0:
		base_hw = 29.0 + sin(y * 0.027 + 0.4) * 5.2 + cos(y * 0.063 - 0.8) * 3.4
	elif y < 395.0:
		base_hw = lerpf(28.5, 11.4, smoothstep(255.0, 395.0, y))
	elif y <= 550.0:
		base_hw = 11.2
	else:
		base_hw = lerpf(11.2, 23.5, smoothstep(550.0, 645.0, y))
	var ripple_w: float = (sin(y * 0.053 + 1.1) * 3.2 + cos(y * 0.097 + 2.0) * 2.1)
	if y < -780.0 or (y >= 385.0 and y <= 555.0) or (y >= -635.0 and y <= -485.0):
		ripple_w *= 0.28
	return base_hw + ripple_w

static func _antiguo_banks_at(y: float) -> Vector2:
	var cx: float = _antiguo_center_x(y)
	var hw: float = _antiguo_half_width(y)
	# Orillas izquierda y derecha claramente desiguales (recodos excavados a un lado y lenguas de barro/grava al otro, nunca paralelas)
	var irr_scale: float = lerpf(0.24, 1.0, smoothstep(-820.0, -240.0, y))
	var town_asym: float = 1.85 if (y >= -325.0 and y <= 345.0) else 1.0
	if (y >= 385.0 and y <= 555.0) or (y >= -635.0 and y <= -485.0):
		irr_scale *= 0.25
		town_asym = 1.0
	elif absf(y - 50.0) < 28.0 or absf(y - (-351.0)) < 22.0 or absf(y - 372.0) < 22.0:
		irr_scale *= 0.30
		town_asym = 1.0
	var left_irr: float = (sin(y * 0.049 + 0.5) * 5.8 + cos(y * 0.089 - 1.1) * 4.2 + sin(y * 0.163 + 2.0) * 2.1) * irr_scale * town_asym
	var right_irr: float = (cos(y * 0.041 - 0.8) * 6.2 + sin(y * 0.097 + 1.6) * 4.5 + cos(y * 0.157 - 0.4) * 2.2) * irr_scale * town_asym
	var lb: float = cx - hw + left_irr
	var rb: float = cx + hw + right_irr
	if y >= -1115.0 and y <= -1005.0:
		rb = minf(rb, 123.5)
	elif y >= -230.0 and y <= 14.0:
		lb = maxf(lb, 25.0)
		rb = minf(rb, 194.0)
	elif y >= 15.0 and y <= 55.0:
		lb = maxf(lb, 92.0)
	elif y >= 115.0 and y <= 345.0:
		rb = minf(rb, 125.0)
	if rb - lb < 18.0:
		var mid_b: float = (lb + rb) * 0.5
		lb = mid_b - 9.0
		rb = mid_b + 9.0
	return Vector2(lb, rb)

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
	var best: Dictionary = crs[0] if not crs.is_empty() else RIVER_CROSSINGS[2]
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
