@tool
extends Node2D
class_name FishingSpot

## Lago y Muelle de Pesca Sistémico — Fase 4.5 (Pesca e Hidrología)
## - Permite pescar con [E] en el muelle (equipa automáticamente la Caña de Pescar [8] si la tienes).
## - Minijuego ágil de reacción: Lanzar línea -> Esperar picada (1.3s - 2.3s) -> ¡PICÓ! Pulsar [E] en la ventana (1.6s).
## - Especies según la hora de WorldClock:
##   * Día (06:00 - 17:59): Trucha de Río (65%) y Carpa Dorada (35%).
##   * Atardecer / Noche (18:00 - 05:59): Siluro Nocturno (70%) y Carpa Dorada (30%).
## - También permite rellenar la Regadera [7] al 100% en la orilla del lago.

enum FishState { IDLE, WAITING_BITE, BITE_ACTIVE, MINIGAME }

var state: FishState = FishState.IDLE
var _timer: float = 0.0
var _wave_time: float = 0.0
var _active_fisher: Node2D = null

# Variables del Minijuego de Precisión (Estilo Stardew Valley)
var _hooked_fish_id: String = "river_trout"
var _fish_pos: float = 0.5
var _fish_target: float = 0.5
var _fish_vel: float = 0.0
var _fish_ai_timer: float = 0.0
var _bar_pos: float = 0.35
var _bar_vel: float = 0.0
var _bar_size: float = 0.30
var _catch_progress: float = 0.35
var _is_fish_inside: bool = false

var dock_pos: Vector2 = Vector2(36, 0)
var is_river_spot: bool = false
var spot_title: String = "🎣 Lago del Oeste"

## Río y arroyo que cruza el pueblo de norte a sur (Caso I: molino viejo abandonado, claro del arroyo y puente viejo).
const ABANDONED_MILL_CENTER := Vector2(188.0, -1060.0)
const ABANDONED_MILL_SIZE := Vector2(124.0, 92.0)
const ABANDONED_MILL_RECT := Rect2(Vector2(126.0, -1106.0), Vector2(124.0, 92.0))
const CASE1_CLEARING_POS := Vector2(138.0, -860.0)
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
	if not (d["cruces"] as Array).is_empty():
		_cruces.assign(d["cruces"])
	_rio_propio = not es_rio_original(d)

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

## Orilla del agua del Lago del Oeste en coordenadas del MAPA (2026-11-05: unas tres veces más grande, hacia el oeste y el sur).
## Orilla del agua del Lago del Oeste en coordenadas del MAPA (Paso 2: alejado al oeste junto al campamento inicial, un solo muelle al este).
## La usa también el escenario 3D (`WorldStage3D._build_lake_3d`).
## Posición del nodo del lago en el mapa (la pone World.gd después de _ready).
const LAKE_NODE_POS := Vector2(-715, 105)
const LAKE_WATER_WORLD: Array[Vector2] = [
	Vector2(-710, 76), Vector2(-672, 82), Vector2(-665, 105), Vector2(-675, 142), Vector2(-720, 164),
	Vector2(-785, 186), Vector2(-855, 214), Vector2(-925, 238), Vector2(-1005, 242), Vector2(-1065, 206),
	Vector2(-1082, 150), Vector2(-1058, 102), Vector2(-990, 82), Vector2(-910, 80), Vector2(-835, 82),
	Vector2(-760, 80),
]


## Polígono escalado respecto a su centro (para la orilla de arena y la zona honda).
static func lake_scaled(factor: float, grow_px: float = 0.0) -> PackedVector2Array:
	var c := Vector2.ZERO
	for v in LAKE_WATER_WORLD:
		c += v
	c /= float(LAKE_WATER_WORLD.size())
	var out := PackedVector2Array()
	for v in LAKE_WATER_WORLD:
		var d: Vector2 = v - c
		out.append(c + d * factor + d.normalized() * grow_px)
	return out
var interact_area: Area2D = null
var status_label: Label = null
var bobber_poly: Polygon2D = null
var fishing_line: Line2D = null
var ripple_sprites: Array[Sprite2D] = []
var ripple_base_positions: Array[Vector2] = []

const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

func _ready() -> void:
	set_process(not Engine.is_editor_hint())
	add_to_group("fishing_spots")
	_build_lake_visuals()
	_build_water_collision()
	_build_interaction_zone()

func _add_poly(pts: Array[Vector2], col: Color, z: int) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array(pts)
	p.color = col
	p.z_index = z
	add_child(p)
	return p

func _make_lbl(txt: String, pos: Vector2, min_sz: Vector2, col: Color, z: int = 0) -> Label:
	var l := Label.new()
	l.text = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = pos
	l.custom_minimum_size = min_sz
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	l.z_index = z
	add_child(l)
	return l

func _build_lake_visuals() -> void:
	if is_river_spot:
		var p_dock_r := _add_poly([Vector2(0, -6), Vector2(18, -6), Vector2(18, 6), Vector2(0, 6)], Color(0.46, 0.30, 0.16, 1.0), -1)
		if p_dock_r != null:
			p_dock_r.add_to_group("ranch_fence_2d")
		_make_lbl(spot_title, Vector2(-60, -24), Vector2(140, 16), Color(0.65, 0.92, 1.0))
	else:
		var to_local_pts := func(pts: PackedVector2Array) -> Array[Vector2]:
			var arr: Array[Vector2] = []
			for v in pts:
				arr.append(v - LAKE_NODE_POS)
			return arr
		var p_sand := _add_poly(to_local_pts.call(lake_scaled(1.0, 9.0)), Color(0.56, 0.48, 0.34, 0.88), -3)
		var p_water := _add_poly(to_local_pts.call(lake_scaled(1.0, 0.0)), Color(0.14, 0.42, 0.68, 0.94), -2)
		var p_deep := _add_poly(to_local_pts.call(lake_scaled(0.62, 0.0)), Color(0.09, 0.30, 0.54, 0.92), -2)
		var p_dock := _add_poly([Vector2(14, -9), Vector2(50, -9), Vector2(50, 9), Vector2(14, 9)], Color(0.46, 0.30, 0.16, 1.0), -1)

		var dock_border := Line2D.new()
		dock_border.width = 2.0
		dock_border.default_color = Color(0.28, 0.18, 0.09, 1.0)
		dock_border.points = PackedVector2Array([Vector2(14, -9), Vector2(50, -9), Vector2(50, 9), Vector2(14, 9), Vector2(14, -9)])
		dock_border.z_index = -1
		add_child(dock_border)
		for ci_2d in [p_sand, p_water, p_deep, p_dock, dock_border]:
			if ci_2d != null:
				ci_2d.add_to_group("ranch_fence_2d")

		_make_lbl("🎣 Lago del Oeste", Vector2(-265, 57), Vector2(160, 18), Color(0.65, 0.92, 1.0))

	# 6. Ondas y sombras de peces animadas
	var tex_ripples := _load_tex("res://assests/world/fishing/fish_spot_ripples.png")
	ripple_base_positions.clear()
	if is_river_spot:
		ripple_base_positions.append_array([Vector2(-8, -6), Vector2(-12, 6)])
	else:
		ripple_base_positions.append_array([Vector2(-12, -10), Vector2(-26, 10), Vector2(2, 14)])
	for pos in ripple_base_positions:
		var spr := Sprite2D.new()
		spr.texture = tex_ripples
		spr.position = pos
		spr.scale = Vector2(0.85, 0.85) if is_river_spot else Vector2(1.15, 1.15)
		spr.z_index = -1
		spr.add_to_group("ranch_fence_2d")
		add_child(spr)
		ripple_sprites.append(spr)

	# 7. Sedal y Boya (visibles al lanzar la caña)
	fishing_line = Line2D.new()
	fishing_line.width = 1.2
	fishing_line.default_color = Color(0.92, 0.95, 1.0, 0.85)
	fishing_line.visible = false
	fishing_line.z_index = 4
	add_child(fishing_line)

	bobber_poly = _add_poly([Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)], Color(1.0, 0.25, 0.20, 1.0), 5)
	bobber_poly.position = Vector2(-8, 0)
	bobber_poly.visible = false

func _build_water_collision() -> void:
	if is_river_spot:
		return
	var body := StaticBody2D.new()
	body.name = "LakeWaterBody"
	body.add_to_group("agua_2d") # el protagonista (cuerpo 3D) entra en el agua; los vecinos no (paso a 3D, paso 3)
	body.collision_layer = 1
	body.collision_mask = 0
	var col_poly := CollisionPolygon2D.new()
	var pts := PackedVector2Array()
	for i in range(LAKE_WATER_WORLD.size()):
		var lp: Vector2 = LAKE_WATER_WORLD[i] - LAKE_NODE_POS
		if i == 2:
			# Hueco para poder caminar sobre el muelle de madera (x: 12..50, y: -11..11) sin pisar el agua
			pts.append(Vector2(42, -12))
			pts.append(Vector2(12, -12))
			pts.append(Vector2(12, 12))
			pts.append(Vector2(40, 12))
		else:
			pts.append(lp)
	col_poly.polygon = pts
	body.add_child(col_poly)
	add_child(body)

func _build_interaction_zone() -> void:
	interact_area = Area2D.new()
	interact_area.name = "FishingInteractArea"
	interact_area.position = dock_pos
	interact_area.collision_layer = 1
	interact_area.collision_mask = 2
	interact_area.add_to_group("interactable")
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 28.0
	col.shape = c
	interact_area.add_child(col)
	add_child(interact_area)

	status_label = _make_lbl("", Vector2(-125, -42), Vector2(250, 22), Color(0.75, 0.95, 1.0), 25)
	status_label.visible = false

func _process(delta: float) -> void:
	_wave_time += delta * 2.6
	for i in range(ripple_sprites.size()):
		var spr: Sprite2D = ripple_sprites[i]
		var base_p: Vector2 = ripple_base_positions[i]
		spr.position = base_p + Vector2(sin(_wave_time + float(i) * 1.7) * 3.0, cos(_wave_time * 0.8 + float(i)) * 2.0)
		var s_pulse: float = 1.10 + sin(_wave_time * 1.5 + float(i)) * 0.12
		spr.scale = Vector2(s_pulse, s_pulse)

	var player = get_tree().get_first_node_in_group("player") as Node2D
	var dock_world: Vector2 = global_position + dock_pos

	if state != FishState.IDLE:
		# Si el jugador se aleja demasiado del muelle, cancelar la pesca
		if not is_instance_valid(_active_fisher) or _active_fisher.global_position.distance_squared_to(dock_world) > 56.0 * 56.0:
			_cancel_fishing("🎣 Línea recogida (te alejaste de la orilla)")
			return

		if fishing_line and bobber_poly:
			var fisher_local: Vector2 = to_local(_active_fisher.global_position + Vector2(0, -6))
			fishing_line.points = PackedVector2Array([fisher_local, bobber_poly.position])

		_timer -= delta
		if state == FishState.WAITING_BITE:
			bobber_poly.position = Vector2(-10, sin(_wave_time * 3.0) * 2.0)
			bobber_poly.color = Color(1.0, 0.30, 0.25, 1.0)
			if _timer <= 0.0:
				state = FishState.BITE_ACTIVE
				_timer = 1.65
				_spawn_floating_text("💦 ¡PICÓ! ¡Pulsa [E]!", Color.GOLD, -24.0)
		elif state == FishState.BITE_ACTIVE:
			bobber_poly.position = Vector2(-10 + sin(_wave_time * 18.0) * 3.5, cos(_wave_time * 18.0) * 3.5)
			bobber_poly.color = Color(0.35, 1.0, 0.45, 1.0)
			if _timer <= 0.0:
				_cancel_fishing("💨 ¡El pez se soltó del anzuelo!")
				return
		elif state == FishState.MINIGAME:
			bobber_poly.position = Vector2(-10 + sin(_wave_time * 14.0) * 2.5, cos(_wave_time * 12.0) * 2.5)
			bobber_poly.color = Color(0.30, 0.90, 1.0, 1.0)
			_update_minigame(delta)
			queue_redraw()

	_update_status_label(player, dock_world)

func _set_status(txt: String, col: Color) -> void:
	status_label.text = txt
	status_label.add_theme_color_override("font_color", col)
	status_label.visible = true

func _update_status_label(player: Node2D, dock_world: Vector2) -> void:
	if not status_label:
		return
	var near_player: bool = player != null and player.global_position.distance_squared_to(dock_world) <= 38.0 * 38.0
	var near_mouse: bool = global_position.distance_squared_to(get_global_mouse_position()) <= 48.0 * 48.0

	if state == FishState.WAITING_BITE:
		_set_status("🎣 Esperando picada... (Atento para pulsar [E])", Color(0.65, 0.95, 1.0))
		return
	elif state == FishState.BITE_ACTIVE:
		_set_status("🐟 ¡¡PICÓ UN PEZ!! ¡Pulsa [E] para enganchar! (%.1fs)" % maxf(0.0, _timer), Color(0.40, 1.0, 0.45))
		return
	elif state == FishState.MINIGAME:
		var fish_title: String = "Carpa Dorada" if _hooked_fish_id == "golden_carp" else ("Siluro Nocturno" if _hooked_fish_id == "night_catfish" else "Trucha")
		_set_status("🎣 [%s] Mantén [E / Espacio / Clic] para subir la barra (%d%%)" % [fish_title, int(round(_catch_progress * 100.0))], Color(0.45, 1.0, 0.65) if _is_fish_inside else Color(1.0, 0.72, 0.35))
		return

	if near_player or near_mouse:
		var is_stained: bool = player != null and player.has_method("is_bloodstained") and bool(player.call("is_bloodstained"))
		var wc := get_node_or_null("/root/WorldClock")
		var cur_h: int = int(wc.get("current_hour")) if wc != null else 12
		var time_hint := "Noche: Siluro/Carpa" if (cur_h >= 18 or cur_h < 6) else "Día: Trucha/Carpa"
		var place_lbl: String = "Ribera del Río" if is_river_spot else "Lago del Oeste"
		var dock_lbl: String = "Ribera de Pesca del Río" if is_river_spot else "Muelle de Pesca"
		if is_stained:
			_set_status("🩸🌊 %s [E: Lavarse la Sangre y Llenar Regadera]" % place_lbl, Color(1.0, 0.58, 0.58))
		else:
			_set_status("🎣 %s [%s | E: Pescar / Llenar Regadera]" % [dock_lbl, time_hint], Color(0.85, 0.95, 1.0))
	else:
		status_label.visible = false

func interact(player: Node2D) -> void:
	if not player:
		return

	# Si el jugador lleva algún Recipiente Vacío ("empty_flask") o está manchado de sangre, llenarlo y lavarse primero
	var p_inv: SimpleInventory = player.get("inventory") if "inventory" in player else null
	if (p_inv and p_inv.has_item("empty_flask", 1)) or (player.has_method("is_bloodstained") and bool(player.call("is_bloodstained"))):
		if player.has_method("refill_watering_can"):
			player.call("refill_watering_can")
		elif player.has_method("wash_bloodstains"):
			player.call("wash_bloodstains", true, true)
		return

	# Si el jugador lleva la Regadera equipada y no está llena, llenarla primero
	if "equipped_weapon" in player and player.equipped_weapon and player.equipped_weapon.name == "WateringCan":
		if "watering_can_charges" in player and "max_water_charges" in player:
			if int(player.watering_can_charges) < int(player.max_water_charges):
				if player.has_method("refill_watering_can"):
					player.call("refill_watering_can")
					return

	if state == FishState.IDLE:
		# Equipar automáticamente la Caña de Pescar [8] para comodidad visual
		if "fishing_rod_weapon" in player and player.fishing_rod_weapon and player.has_method("equip_weapon"):
			player.call("equip_weapon", player.fishing_rod_weapon)
		_active_fisher = player
		state = FishState.WAITING_BITE
		_timer = randf_range(1.25, 2.25)
		if bobber_poly:
			bobber_poly.visible = true
		if fishing_line:
			fishing_line.visible = true
		_spawn_floating_text("🎣 Línea lanzada...", Color.AQUA, -22.0)
		return

	if state == FishState.WAITING_BITE:
		_cancel_fishing("💨 Recogiste el anzuelo demasiado pronto")
		return

	if state == FishState.BITE_ACTIVE:
		_start_minigame(player)
		return

	if state == FishState.MINIGAME:
		# Durante el minijuego, mantener [E] impulsa la barra hacia arriba (no cancela)
		return

func _start_minigame(player: Node2D) -> void:
	state = FishState.MINIGAME
	_active_fisher = player

	var wc_m := get_node_or_null("/root/WorldClock")
	var cur_h_m: int = int(wc_m.get("current_hour")) if wc_m != null else 12
	var is_night_fish := (cur_h_m >= 18 or cur_h_m < 6)
	var roll := randf()
	if is_night_fish:
		_hooked_fish_id = "night_catfish" if roll < 0.70 else "golden_carp"
	else:
		_hooked_fish_id = "river_trout" if roll < 0.65 else "golden_carp"

	var rod_mult: float = float(player.call("get_fishing_bar_multiplier")) if (player and player.has_method("get_fishing_bar_multiplier")) else 1.0
	_bar_size = clampf(0.28 * rod_mult, 0.24, 0.52)
	_bar_pos = 0.30
	_bar_vel = 0.0
	_fish_pos = 0.35
	_fish_target = 0.65
	_fish_vel = 0.0
	_fish_ai_timer = 0.4
	_catch_progress = 0.36
	_is_fish_inside = true
	_spawn_floating_text("🎣 ¡Enganchado! ¡Mantén al pez en la barra verde!", Color.SPRING_GREEN, -26.0)
	queue_redraw()

func _update_minigame(delta: float) -> void:
	# 1. Control de la Barra Verde por el jugador (Mantener [E], [Espacio] o Clic Izquierdo)
	var thrust_pressed: bool = Input.is_physical_key_pressed(Teclas.tecla("accion") as Key) or Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var accel: float = 1.85 if thrust_pressed else -1.55
	_bar_vel = clampf(_bar_vel + accel * delta, -1.15, 1.15)
	_bar_pos += _bar_vel * delta

	var half_bar: float = _bar_size * 0.5
	if _bar_pos < half_bar:
		_bar_pos = half_bar
		_bar_vel = maxf(0.0, -_bar_vel * 0.28)
	elif _bar_pos > 1.0 - half_bar:
		_bar_pos = 1.0 - half_bar
		_bar_vel = minf(0.0, -_bar_vel * 0.25)

	# 2. Movimiento del Pez según su especie
	_fish_ai_timer -= delta
	if _fish_ai_timer <= 0.0:
		match _hooked_fish_id:
			"river_trout":
				_fish_ai_timer = randf_range(0.75, 1.35)
				_fish_target = clampf(_fish_pos + randf_range(-0.32, 0.32), 0.10, 0.90)
			"golden_carp":
				_fish_ai_timer = randf_range(0.48, 0.95)
				_fish_target = randf_range(0.12, 0.88)
			"night_catfish":
				_fish_ai_timer = randf_range(0.32, 0.72)
				_fish_target = randf_range(0.08, 0.92)

	var fish_speed: float = 0.82 if _hooked_fish_id == "golden_carp" else (1.12 if _hooked_fish_id == "night_catfish" else 0.58)
	_fish_pos = move_toward(_fish_pos, _fish_target, fish_speed * delta)

	# 3. Comprobar si el pez está dentro de la barra verde
	_is_fish_inside = absf(_fish_pos - _bar_pos) <= (half_bar + 0.03)
	_catch_progress = clampf(_catch_progress + (0.42 if _is_fish_inside else -0.20) * delta, 0.0, 1.0)
	if _catch_progress >= 1.0:
		_complete_catch(_active_fisher)
	elif _catch_progress <= 0.0:
		_cancel_fishing("💨 ¡El pez se escapó de la barra!")

func _draw() -> void:
	if state != FishState.MINIGAME:
		return
	var panel_pos := Vector2(56, -56)
	var col_w: float = 16.0
	var col_h: float = 104.0

	# Marco exterior
	draw_rect(Rect2(panel_pos - Vector2(4, 4), Vector2(col_w + 18.0, col_h + 8.0)), Color(0.08, 0.09, 0.13, 0.95), true)
	draw_rect(Rect2(panel_pos - Vector2(4, 4), Vector2(col_w + 18.0, col_h + 8.0)), Color(0.78, 0.64, 0.34, 1.0), false, 1.6)

	# Columna de agua
	draw_rect(Rect2(panel_pos, Vector2(col_w, col_h)), Color(0.10, 0.26, 0.46, 0.95), true)

	# Barra verde del jugador (invertida en Y: 0.0 abajo, 1.0 arriba)
	var bar_h: float = _bar_size * col_h
	var bar_center_y: float = panel_pos.y + (1.0 - _bar_pos) * col_h
	var bar_rect := Rect2(Vector2(panel_pos.x + 1.0, bar_center_y - bar_h * 0.5), Vector2(col_w - 2.0, bar_h))
	var bar_col: Color = Color(0.32, 0.95, 0.45, 0.88) if _is_fish_inside else Color(0.85, 0.72, 0.28, 0.75)
	draw_rect(bar_rect, bar_col, true)
	draw_rect(bar_rect, Color(0.92, 1.0, 0.92, 0.95), false, 1.2)

	# Icono del pez dentro de la columna
	var fish_y: float = panel_pos.y + (1.0 - _fish_pos) * col_h
	var fish_center := Vector2(panel_pos.x + col_w * 0.5, fish_y)
	var fish_col: Color = Color(0.95, 0.78, 0.22) if _hooked_fish_id == "golden_carp" else (Color(0.68, 0.45, 0.95) if _hooked_fish_id == "night_catfish" else Color(1.0, 0.52, 0.32))
	draw_circle(fish_center, 4.5, fish_col)
	draw_circle(fish_center + Vector2(1.5, -1.0), 1.2, Color.BLACK)

	# Barra lateral de progreso de captura (0% a 100%)
	var prog_x: float = panel_pos.x + col_w + 4.0
	var prog_w: float = 6.0
	draw_rect(Rect2(Vector2(prog_x, panel_pos.y), Vector2(prog_w, col_h)), Color(0.18, 0.18, 0.22, 0.95), true)
	var fill_h: float = _catch_progress * col_h
	var prog_col: Color = Color(0.25, 0.95, 0.42) if _catch_progress >= 0.6 else (Color(0.95, 0.80, 0.25) if _catch_progress >= 0.3 else Color(0.95, 0.32, 0.28))
	draw_rect(Rect2(Vector2(prog_x, panel_pos.y + col_h - fill_h), Vector2(prog_w, fill_h)), prog_col, true)

func _reset_fishing_state() -> void:
	state = FishState.IDLE
	_active_fisher = null
	queue_redraw()
	if bobber_poly:
		bobber_poly.visible = false
	if fishing_line:
		fishing_line.visible = false

func _complete_catch(player: Node2D) -> void:
	_reset_fishing_state()
	var inv: SimpleInventory = player.get("inventory") if player else null
	if not inv:
		return
	var caught_id: String = _hooked_fish_id if _hooked_fish_id != "" else "river_trout"
	inv.add_item(caught_id, 1)
	var fish_name: String = inv.get_item_name(caught_id)
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🐟 ¡Pescaste: %s!" % fish_name, Color.GOLD, -42.0)
	if player.has_method("show_hint"):
		player.show_hint("🎣 ¡Captura perfecta! Has pescado 1 %s. Puedes cocinarlo en la Hoguera o vendérselo a Marlo." % fish_name)

func _cancel_fishing(msg: String) -> void:
	_reset_fishing_state()
	if msg != "":
		_spawn_floating_text(msg, Color(0.95, 0.75, 0.45), -22.0)

func cancel_fishing() -> void:
	if state != FishState.IDLE:
		_cancel_fishing("")

func _spawn_floating_text(text: String, color: Color, offset_y: float = -28.0) -> void:
	if FloatingTextScene:
		var ft = FloatingTextScene.instantiate()
		ft.start_text = text
		ft.text_color = color
		ft.global_position = global_position + Vector2(0, offset_y)
		get_tree().current_scene.add_child(ft)

func _load_tex(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var t = load(res_path)
		if t is Texture2D:
			return t
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null
