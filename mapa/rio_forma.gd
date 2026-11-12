@tool
extends RefCounted

## Editor del mapa (Claude Code, 2026-11-09): forma del río a partir de los puntos que el usuario coloca en
## res://mapa/EditorMapa.tscn. La usan el propio editor (para dibujar el río mientras lo mueves) y el juego
## (RioLago), así lo que ves en el editor es lo que hay en el juego: agua, orillas, choque y río 3D.
## «datos» es un diccionario: {"pts": Array[Vector2], "hw": Array[float] (medio ancho), "natural": float, "cruces": Array[Dictionary]}

const TIPOS_CRUCE: Array[String] = ["ford", "wood_bridge", "stone_wood_bridge", "log"]


## Lee la escena del editor del mapa sin meterla en el juego. Devuelve {} si no existe o está vacía.
static func leer_escena(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		return {}
	var ps = load(path)
	if not (ps is PackedScene):
		return {}
	var root: Node = ps.instantiate()
	var d: Dictionary = {}
	var rio: Node = root.get_node_or_null("Rio")
	var cruces: Node = root.get_node_or_null("Cruces")
	if rio != null and cruces != null:
		d = datos_desde_nodos(rio, cruces)
	root.free()
	return d


static func datos_desde_nodos(rio: Node, cruces_node: Node) -> Dictionary:
	var pts: Array[Vector2] = []
	var hw: Array[float] = []
	for c in rio.get_children():
		if c is Node2D and c.get("ancho") != null:
			pts.append((c as Node2D).position)
			hw.append(maxf(4.5, float(c.get("ancho")) * 0.5))
	# El río va siempre de norte (arriba) a sur (abajo): si un punto queda por encima del anterior, se ordena.
	var idx: Array = range(pts.size())
	idx.sort_custom(func(a, b): return pts[a].y < pts[b].y)
	var spts: Array[Vector2] = []
	var shw: Array[float] = []
	for i in idx:
		spts.append(pts[i])
		shw.append(hw[i])
	var cr: Array[Dictionary] = []
	var used: Dictionary = {}
	var n: int = 0
	if cruces_node != null:
		for c in cruces_node.get_children():
			if not (c is Node2D) or c.get("tipo") == null:
				continue
			n += 1
			var cid: String = str(c.get("id_interno"))
			if cid == "" or used.has(cid):
				cid = "cruce_%d" % n
			used[cid] = true
			var half_h: float = maxf(6.0, float(c.get("ancho")) * 0.5)
			cr.append({
				"id": cid, "label": str(c.get("nombre")), "pos": (c as Node2D).position,
				"half_h": half_h, "half_y": half_h, "half_w": maxf(10.0, float(c.get("largo")) * 0.5),
				"kind": TIPOS_CRUCE[clampi(int(c.get("tipo")), 0, TIPOS_CRUCE.size() - 1)],
				"arch_h": float(c.get("altura_arco")),
			})
	cr.sort_custom(func(a, b): return a["pos"].y < b["pos"].y)
	return {"pts": spts, "hw": shw, "natural": clampf(float(rio.get("curvas_naturales")), 0.0, 1.0), "cruces": cr}


static func _seg(pts: Array, y: float) -> Array:
	# Devuelve [i, t suavizado] del tramo entre los puntos i e i+1 que contiene y.
	var last: int = pts.size() - 1
	if y <= pts[0].y:
		return [0, 0.0]
	if y >= pts[last].y:
		return [maxi(0, last - 1), 1.0]
	for i in range(last):
		if y >= pts[i].y and y <= pts[i + 1].y:
			var t: float = (y - pts[i].y) / maxf(0.001, pts[i + 1].y - pts[i].y)
			return [i, t * t * (3.0 - 2.0 * t)]
	return [0, 0.0]


static func _calma_cruces(d: Dictionary, y: float, extra: float) -> float:
	for c in d["cruces"]:
		if absf(y - float(c["pos"].y)) < float(c["half_h"]) + extra:
			return 0.25
	return 1.0


static func center_x(d: Dictionary, y: float) -> float:
	var pts: Array = d["pts"]
	if pts.size() < 2:
		return 0.0 if pts.is_empty() else pts[0].x
	var s: Array = _seg(pts, y)
	var i: int = s[0]
	var base_x: float = lerpf(pts[i].x, pts[i + 1].x, s[1])
	var nat: float = float(d["natural"]) * _calma_cruces(d, y, 8.0)
	return base_x + (sin(y * 0.037 + 0.6) * 7.8 + cos(y * 0.073 - 0.5) * 4.4 + sin(y * 0.119 + 1.4) * 2.2) * nat


static func half_width(d: Dictionary, y: float) -> float:
	var pts: Array = d["pts"]
	var hw: Array = d["hw"]
	if pts.size() < 2:
		return 10.0 if hw.is_empty() else float(hw[0])
	var s: Array = _seg(pts, y)
	var i: int = s[0]
	var base_hw: float = lerpf(float(hw[i]), float(hw[i + 1]), s[1])
	var ripple: float = (sin(y * 0.053 + 1.1) * 3.2 + cos(y * 0.097 + 2.0) * 2.1) * float(d["natural"])
	ripple *= clampf(base_hw / 25.0, 0.28, 1.0) * _calma_cruces(d, y, 4.0)
	return maxf(4.5, base_hw + ripple)


static func banks_at(d: Dictionary, y: float) -> Vector2:
	var cx: float = center_x(d, y)
	var hw: float = half_width(d, y)
	var irr: float = clampf(hw / 29.5, 0.24, 1.0) * float(d["natural"]) * _calma_cruces(d, y, 2.0)
	var left_irr: float = (sin(y * 0.049 + 0.5) * 5.8 + cos(y * 0.089 - 1.1) * 4.2 + sin(y * 0.163 + 2.0) * 2.1) * irr
	var right_irr: float = (cos(y * 0.041 - 0.8) * 6.2 + sin(y * 0.097 + 1.6) * 4.5 + cos(y * 0.157 - 0.4) * 2.2) * irr
	var lb: float = cx - hw + left_irr
	var rb: float = cx + hw + right_irr
	if rb - lb < 9.0:
		var mid: float = (lb + rb) * 0.5
		lb = mid - 4.5
		rb = mid + 4.5
	return Vector2(lb, rb)
