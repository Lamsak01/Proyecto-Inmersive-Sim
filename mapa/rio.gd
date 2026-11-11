@tool
extends Node2D

## El río del valle, de norte (arriba) a sur (abajo). Sus hijos son los puntos del cauce, en orden de arriba abajo.
## Lo que se dibuja aquí es exactamente el agua que tendrá el juego. En rojo: edificios que el agua pisa.

const RioForma = preload("res://mapa/rio_forma.gd")
const COL_AGUA := Color(0.20, 0.50, 0.80, 0.80)
const COL_ORILLA := Color(0.10, 0.25, 0.45, 1.0)

## 1 = orillas irregulares y curvas naturales como el río de siempre; 0 = el cauce pasa justo por tus puntos.
@export_range(0.0, 1.0, 0.05) var curvas_naturales: float = 1.0:
	set(v):
		curvas_naturales = v
		redibujar()

var _pendiente: bool = false


func _ready() -> void:
	if not child_order_changed.is_connected(redibujar):
		child_order_changed.connect(redibujar)
	queue_redraw()


func redibujar() -> void:
	queue_redraw()


func datos() -> Dictionary:
	return RioForma.datos_desde_nodos(self, get_node_or_null("../Cruces"))


func _draw() -> void:
	var d: Dictionary = datos()
	var pts: Array = d["pts"]
	if pts.size() < 2:
		return
	# Mientras el río siga como el original, el juego usa su forma de siempre: dibujo esa misma.
	var FS = load("res://scripts/obstacles/FishingSpot.gd")
	var original: bool = FS.es_rio_original(d)
	var orillas := func(yy: float) -> Vector2:
		return FS._antiguo_banks_at(yy) if original else RioForma.banks_at(d, yy)
	var y0: float = pts[0].y
	var y1: float = pts[pts.size() - 1].y
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var y: float = y0
	while true:
		var b: Vector2 = orillas.call(y)
		left.append(Vector2(b.x, y))
		right.append(Vector2(b.y, y))
		if y >= y1:
			break
		y = minf(y + 6.0, y1)
	var poly := PackedVector2Array(left)
	for i in range(right.size() - 1, -1, -1):
		poly.append(right[i])
	if poly.size() >= 3 and Geometry2D.triangulate_polygon(poly).size() > 0:
		draw_colored_polygon(poly, COL_AGUA)
	draw_polyline(left, COL_ORILLA, 1.5)
	draw_polyline(right, COL_ORILLA, 1.5)
	# Línea que une los puntos (la «espina» del río) y su orden
	var spine := PackedVector2Array()
	for p in pts:
		spine.append(p)
	draw_polyline(spine, Color(1, 1, 1, 0.35), 1.0)
	# Puentes y vados
	for c in d["cruces"]:
		var cp: Vector2 = c["pos"]
		var bk0: Vector2 = orillas.call(cp.y)
		# El juego alarga cada paso hasta las orillas (FishingSpot); aquí se dibuja igual para que no salga rojo sin motivo
		var hw: float = maxf(float(c["half_w"]), (bk0.y - bk0.x) * 0.5 + 8.0)
		var r := Rect2(cp - Vector2(hw, c["half_h"]), Vector2(hw, c["half_h"]) * 2.0)
		var col := Color(0.55, 0.38, 0.20, 0.9) if c["kind"] != "ford" else Color(0.70, 0.65, 0.50, 0.8)
		draw_rect(r, col, true)
		draw_rect(r, Color(0.2, 0.12, 0.05), false, 1.5)
		var bk: Vector2 = orillas.call(cp.y)
		if r.position.x > bk.x - 2.0 or r.end.x < bk.y + 2.0:
			draw_rect(r.grow(3.0), Color(1, 0.1, 0.1), false, 2.0) # no llega de orilla a orilla
	# Edificios que pisa el agua
	var ref := get_node_or_null("../Referencia")
	if ref != null and ref.has_method("edificios"):
		for e in ref.call("edificios"):
			var er: Rect2 = e["rect"]
			if str(e["id"]) == "building_abandoned_mill":
				continue # el molino está junto al agua a propósito
			var yy: float = maxf(er.position.y, y0)
			while yy <= minf(er.end.y, y1):
				var bb: Vector2 = orillas.call(yy)
				if bb.y > er.position.x and bb.x < er.end.x:
					draw_rect(er.grow(4.0), Color(1, 0.05, 0.05), false, 3.0)
					break
				yy += 6.0
