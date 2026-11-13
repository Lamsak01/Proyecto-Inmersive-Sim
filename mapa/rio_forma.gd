@tool
extends RefCounted

## Editor del mapa (Claude Code, 2026-11-09; en 3D desde el 2026-11-12): forma del río a partir de los puntos que
## el usuario coloca en mapa/Mundo3D.tscn («Rio» y «Cruces»). La usan el propio editor (para dibujar el río mientras
## lo mueves) y el juego (RioLago), así lo que ves en el editor es lo que hay en el juego: agua, orillas, choque y río 3D.
## «datos» es un diccionario: {"pts": Array[Vector2], "hw": Array[float] (medio ancho), "natural": float, "cruces": Array[Dictionary]}

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const TIPOS_CRUCE: Array[String] = ["ford", "wood_bridge", "stone_wood_bridge", "log"]
const CARPETA_RIO := "Rio"
const CARPETA_CRUCES := "Cruces"
const RIO := "res://mapa/rio.gd"
const PUNTO := "res://mapa/punto_rio.gd"
const CRUCE := "res://mapa/cruce_rio.gd"
const CAMPOS_PUNTO: Array[String] = ["ancho_m"]
const CAMPOS_CRUCE: Array[String] = ["nombre", "tipo", "ancho_m", "largo_m", "altura_arco", "id_interno"]
const PRECISION_PX: float = 0.001
const MIN_MEDIO_ANCHO_PX: float = 4.5  ## el río más estrecho: un arroyo de 9 px
const MIN_MEDIO_PASO_PX: float = 6.0
const MIN_MEDIO_LARGO_PX: float = 10.0


## Lee el río guardado en la escena del editor (carpetas «Rio» y «Cruces») sin cargarla entera: el mundo es grande.
## Devuelve {} si no hay río. Lo que la escena no guarda es el valor por defecto de su script.
static func leer_escena(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		return {}
	var estado: SceneState = (load(path) as PackedScene).get_state()
	var natural: Variant = null
	var puntos: Array[Dictionary] = []
	var cruces: Array[Dictionary] = []
	for i in range(estado.get_node_count()):
		var ruta: String = str(estado.get_node_path(i))
		var props: Dictionary = {}
		for k in range(estado.get_node_property_count(i)):
			props[estado.get_node_property_name(i, k)] = estado.get_node_property_value(i, k)
		if ruta == "./" + CARPETA_RIO:
			natural = props.get("curvas_naturales", null)
		elif ruta.begins_with("./%s/" % CARPETA_RIO) and ruta.count("/") == 2:
			puntos.append(_con_defectos(props, PUNTO, CAMPOS_PUNTO))
		elif ruta.begins_with("./%s/" % CARPETA_CRUCES) and ruta.count("/") == 2:
			cruces.append(_con_defectos(props, CRUCE, CAMPOS_CRUCE))
	if puntos.is_empty():
		return {}
	var rio_guion: Script = load(RIO)
	return _armar(puntos, float(natural if natural != null else rio_guion.get_property_default_value("curvas_naturales")), cruces)


## Lo mismo desde los nodos vivos del editor (mientras el usuario arrastra un punto).
static func datos_desde_nodos(rio: Node, cruces_node: Node) -> Dictionary:
	var puntos: Array[Dictionary] = []
	for c: Node in rio.get_children():
		if c is Node3D and c.get("ancho_m") != null:
			puntos.append({"transform": (c as Node3D).transform, "ancho_m": c.get("ancho_m")})
	var cruces: Array[Dictionary] = []
	if cruces_node != null:
		for c: Node in cruces_node.get_children():
			if c is Node3D and c.get("tipo") != null:
				var props: Dictionary = {"transform": (c as Node3D).transform}
				for campo: String in CAMPOS_CRUCE:
					props[campo] = c.get(campo)
				cruces.append(props)
	return _armar(puntos, float(rio.get("curvas_naturales")), cruces)


static func _con_defectos(props: Dictionary, guion_ruta: String, campos: Array[String]) -> Dictionary:
	var guion: Script = load(guion_ruta)
	var out: Dictionary = props.duplicate()
	for campo: String in campos:
		if not out.has(campo):
			out[campo] = guion.get_property_default_value(campo)
	return out


## Metros del editor → píxeles del mapa, con decimales de sobra pero sin el ruido de la conversión.
static func _px(m: float) -> float:
	return snappedf(m / Mapa3D.ESCALA, PRECISION_PX)


static func _sitio(props: Dictionary) -> Vector2:
	var v: Vector2 = Mapa3D.a_mapa((props.get("transform", Transform3D.IDENTITY) as Transform3D).origin)
	return Vector2(snappedf(v.x, PRECISION_PX), snappedf(v.y, PRECISION_PX))


static func _armar(puntos: Array[Dictionary], natural: float, cruces_props: Array[Dictionary]) -> Dictionary:
	# El río va siempre de norte a sur: si un punto queda por encima del anterior, se ordena.
	puntos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _sitio(a).y < _sitio(b).y)
	var spts: Array[Vector2] = []
	var shw: Array[float] = []
	for p: Dictionary in puntos:
		spts.append(_sitio(p))
		shw.append(maxf(MIN_MEDIO_ANCHO_PX, _px(float(p["ancho_m"])) * 0.5))
	var cr: Array[Dictionary] = []
	var used: Dictionary = {}
	var n: int = 0
	for c: Dictionary in cruces_props:
		n += 1
		var cid: String = str(c["id_interno"])
		if cid == "" or used.has(cid):
			cid = "cruce_%d" % n
		used[cid] = true
		var half_h: float = maxf(MIN_MEDIO_PASO_PX, _px(float(c["ancho_m"])) * 0.5)
		cr.append({
			"id": cid, "label": str(c["nombre"]), "pos": _sitio(c),
			"half_h": half_h, "half_y": half_h, "half_w": maxf(MIN_MEDIO_LARGO_PX, _px(float(c["largo_m"])) * 0.5),
			"kind": TIPOS_CRUCE[clampi(int(c["tipo"]), 0, TIPOS_CRUCE.size() - 1)],
			"arch_h": float(c["altura_arco"]),
		})
	cr.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["pos"].y < b["pos"].y)
	return {"pts": spts, "hw": shw, "natural": clampf(natural, 0.0, 1.0), "cruces": cr}


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
