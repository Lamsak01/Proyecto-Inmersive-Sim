@tool
extends RefCounted
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Núcleo del pincel del mapa (Claude Code, 2026-11-10): siembra y borra piezas en mapa/Mundo3D.tscn. Lo usa el panel
## del pincel (addons/pincel_mapa) y la prueba tools/tests/pincel_mapa.gd (sin editor).

const Mezclas = preload("res://mapa/pincel_mezclas.gd")
const WB = preload("res://scripts/visuals/WorldStageBase3D.gd")
const FS = preload("res://scripts/fisica/RioLago.gd")
const PIEZA = preload("res://mapa/pieza.gd")
const REFERENCIA := "res://mapa/referencia_mapa.json"

var raiz: Node3D = null
var mezcla: Dictionary = {} # vacía = usar «plantillas» (lo seleccionado)
var plantillas: Array[Node3D] = []
var radio: float = 120.0
var densidad: float = 0.5
var nuevos: Array[Node] = []
var borrados: Array = [] # [nodo, padre, índice]
var aviso: String = ""
var _ocupados: Dictionary = {}
var _celda: float = 32.0
var _edificios_ref: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()
	_leer_referencia()


func sembrar(semilla: int) -> void:
	_rng.seed = semilla


func empezar() -> void:
	nuevos.clear()
	borrados.clear()
	aviso = ""
	_rehacer_ocupados()


func pintar(c: Vector2) -> void:
	var m := mezcla
	var usa_sel: bool = m.is_empty()
	if usa_sel:
		plantillas = plantillas.filter(func(n): return is_instance_valid(n) and n.is_inside_tree())
		if plantillas.is_empty():
			aviso = "Primero selecciona uno o más objetos en la escena y pulsa «Usar lo seleccionado»."
			return
	var sep: float = float(m.get("separacion", 24.0))
	if usa_sel:
		sep = 24.0
	var r: float = radio
	# Cuántas intenta: con «apretado» al 100 %, el pincel llena el círculo hasta la separación mínima
	var cabe: float = (PI * r * r) / (sep * sep * 1.2)
	var intentos: int = int(ceil(cabe * densidad * float(m.get("densidad", 1.0)) * 0.6)) + 1
	for _i in range(intentos):
		var ang: float = _rng.randf() * TAU
		var p: Vector2 = c + Vector2(cos(ang), sin(ang)) * r * sqrt(_rng.randf())
		if _ocupado(p, sep) or _prohibido(p):
			continue
		var n: Node3D = _plantar(p, m, usa_sel)
		if n != null:
			_marcar(p)
			nuevos.append(n)


func _plantar(p: Vector2, m: Dictionary, usa_sel: bool) -> Node3D:
	var n: Node3D
	var padre: Node
	if usa_sel:
		var plantilla: Node3D = plantillas[_rng.randi() % plantillas.size()]
		n = plantilla.duplicate() as Node3D
		padre = plantilla.get_parent()
		var esc: float = _rng.randf_range(0.85, 1.15)
		n.scale = plantilla.scale * esc
	else:
		var mods: Array = m["modelos"]
		var total: float = 0.0
		for md in mods:
			total += float(md.get("peso", 1))
		var tirada: float = _rng.randf() * total
		var elegido: Dictionary = mods[0]
		for md in mods:
			tirada -= float(md.get("peso", 1))
			if tirada <= 0.0:
				elegido = md
				break
		padre = _carpeta(raiz, str(m["carpeta"]))
		n = Node3D.new()
		n.set_script(PIEZA)
		n.set("modelo", str(elegido["modelo"]))
		var alto: Array = elegido.get("alto", [24, 24])
		n.set("alto", roundf(_rng.randf_range(float(alto[0]), float(alto[1]))))
		n.name = str(elegido["modelo"]).get_file().get_basename() + "_p"
	padre.add_child(n, true)
	n.position = padre.global_transform.affine_inverse() * _a_3d(p, WB.terrain_height_px(p))
	n.rotate_y(_rng.randf() * TAU)
	poner_dueno(n, raiz)
	return n


func _carpeta(raiz: Node, ruta: String) -> Node:
	var actual: Node = raiz
	for parte in ruta.split("/"):
		var sig: Node = actual.get_node_or_null(parte)
		if sig == null:
			sig = Node3D.new()
			sig.name = parte
			actual.add_child(sig)
			sig.owner = raiz
		actual = sig
	return actual


func borrar(c: Vector2) -> void:
	var carpetas: Array[Node] = []
	var m := mezcla
	if m.is_empty():
		for pl in plantillas:
			if is_instance_valid(pl) and pl.get_parent() not in carpetas:
				carpetas.append(pl.get_parent())
	else:
		var cp := raiz.get_node_or_null(str(m["carpeta"]))
		if cp != null:
			carpetas.append(cp)
	var r2: float = radio * radio
	for cp in carpetas:
		for n in cp.get_children():
			if not (n is Node3D) or n in plantillas:
				continue
			if _a_2d((n as Node3D).global_position).distance_squared_to(c) <= r2:
				borrados.append([n, cp, n.get_index()])
				cp.remove_child(n)


# ---------------------------------------------------------------- dónde no se siembra

func _prohibido(p: Vector2) -> bool:
	if FS.is_point_in_river_water(p, 8.0):
		return true
	var lago := PackedVector2Array(FS.LAKE_WATER_WORLD)
	if Geometry2D.is_point_in_polygon(p, lago):
		return true
	var p3: Vector3 = _a_3d(p, WB.terrain_height_px(p))
	var caminos := raiz.get_node_or_null("Caminos")
	if caminos != null:
		for t in caminos.get_children():
			if t is Node3D:
				var loc: Vector3 = (t as Node3D).global_transform.affine_inverse() * p3
				if absf(loc.x) <= 0.6 and absf(loc.z) <= 0.75:
					return true
	var eds := raiz.get_node_or_null("Edificios")
	if eds != null:
		for e in eds.get_children():
			var r = _edificios_ref.get(str(e.get("id_edificio")), null)
			if r == null or not (e is Node3D):
				continue
			var centro_nuevo: Vector2 = _a_2d((e as Node3D).global_position - (e.get("origen_3d") as Vector3)) + (e.get("centro_original") as Vector2)
			var rr: Rect2 = r
			var rect := Rect2(centro_nuevo - rr.size * 0.5, rr.size).grow(10.0)
			if rect.has_point(p):
				return true
	return false


func _leer_referencia() -> void:
	_edificios_ref.clear()
	if not FileAccess.file_exists(REFERENCIA):
		return
	var j = JSON.parse_string(FileAccess.get_file_as_string(REFERENCIA))
	if not (j is Dictionary):
		return
	for e in j.get("edificios", []):
		var r: Array = e["r"]
		var big: float = maxf(r[2], r[3])
		_edificios_ref[str(e["id"])] = Rect2(r[0], r[1], r[2], r[3]) if big > 0 else Rect2()


func _rehacer_ocupados() -> void:
	_ocupados.clear()
	var veg := raiz.get_node_or_null("Vegetacion")
	if veg != null:
		_marcar_todo(veg)
	var dec := raiz.get_node_or_null("Decoracion")
	if dec != null:
		_marcar_todo(dec)


func _marcar_todo(n: Node) -> void:
	for c in n.get_children():
		if c is Node3D and (c.get_script() == PIEZA or n.name == "Decoracion"):
			_marcar(_a_2d((c as Node3D).global_position))
		elif c.get_child_count() > 0 and not c.has_meta("pieza_modelo"):
			_marcar_todo(c)


func _clave(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / _celda), floori(p.y / _celda))


func _marcar(p: Vector2) -> void:
	var k := _clave(p)
	if not _ocupados.has(k):
		_ocupados[k] = []
	_ocupados[k].append(p)


func _ocupado(p: Vector2, sep: float) -> bool:
	var k := _clave(p)
	var alcance: int = int(ceil(sep / _celda))
	for dx in range(-alcance, alcance + 1):
		for dy in range(-alcance, alcance + 1):
			for q in _ocupados.get(k + Vector2i(dx, dy), []):
				if (q as Vector2).distance_to(p) < sep:
					return true
	return false


func _a_2d(p: Vector3) -> Vector2:
	return Mapa3D.a_mapa(p)


func _a_3d(p: Vector2, h: float) -> Vector3:
	return Mapa3D.a_3d(p, h)



static func poner_dueno(n: Node, r: Node) -> void:
	n.owner = r
	for c in n.get_children():
		if c.owner == null and not c.has_meta("pieza_modelo") and not c.has_meta("vista_edificio"):
			poner_dueno(c, r)
