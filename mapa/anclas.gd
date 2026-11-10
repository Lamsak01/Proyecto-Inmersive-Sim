extends RefCounted

## Anclas del editor del mapa 3D (Claude Code, 2026-11-10). Cuando el usuario mueve en mapa/Mundo3D.tscn un edificio, un
## objeto de «Objetos» marcado como ancla o un objeto de «Decorado», todo lo que el juego crea en el mapa 2D dentro de su
## zona original (dibujos, zonas de uso, paredes invisibles, letreros, polígonos) se crea desplazado lo mismo. Así la
## lógica sigue a lo que se ve sin tocar cada sitio del código. Lo usan las funciones _add_* de VillageManagerBase.

const ESCENA := "res://mapa/Mundo3D.tscn"
const WORLD_SCALE: float = 0.02
const PITCH_DEG: float = 58.0

static var _anclas: Array = [] # {"rect": Rect2} o {"centro": Vector2, "radio": float}, con "c", "d": Vector2, "g": grados, "m": Transform2D
static var _leidas: bool = false
static var pausa: int = 0 # mientras se construye un edificio (ya se desplaza solo) no se aplican
static var grabar: bool = false # tools/hornear_objetos.gd: anota lo que se crea para hacer piezas
static var grabado: Array = [] # [tipo, nombre, pos]


static var _muebles: Array = [] # muebles movidos dentro de su edificio (mapa/mueble.gd), en coordenadas originales


static func _leer() -> void:
	_leidas = true
	for a in load("res://mapa/mueble.gd").anclas():
		var am: Dictionary = (a as Dictionary).duplicate()
		am["m"] = matriz(float(am["g"]))
		_muebles.append(am)
	if not ResourceLoader.exists(ESCENA):
		return
	var st: SceneState = (load(ESCENA) as PackedScene).get_state()
	var sin_p: float = sin(deg_to_rad(PITCH_DEG))
	for i in range(st.get_node_count()):
		var ruta := str(st.get_node_path(i))
		var es_obj := ruta.begins_with("./Objetos/")
		var es_dec := ruta.begins_with("./Decorado/") and ruta.count("/") == 3 # Decorado/Zona/Objeto
		if not (es_obj or es_dec):
			continue
		var orig := Vector2.INF
		var radio := 0.0
		var ancla := false
		var xf := Transform3D.IDENTITY
		for k in range(st.get_node_property_count(i)):
			var nombre: String = st.get_node_property_name(i, k)
			var v = st.get_node_property_value(i, k)
			match nombre:
				"transform": xf = v
				"pos_original", "metadata/pos_original": orig = v
				"radio_ancla", "metadata/radio": radio = float(v)
				"es_ancla": ancla = bool(v)
		if orig == Vector2.INF:
			continue
		var d := Vector2(xf.origin.x / WORLD_SCALE, xf.origin.z * sin_p / WORLD_SCALE) - orig
		var g := rad_to_deg(xf.basis.orthonormalized().get_euler().y)
		if es_obj and not ancla:
			# Objeto con nombre (pozo, tablón, farola…): el juego ya lo pone en su sitio nuevo; aquí solo se gira lo suyo
			if absf(g) > 0.5:
				_anclas.append({"centro": orig + d, "radio": 10.0, "c": orig + d, "d": Vector2.ZERO, "g": g, "m": matriz(g)})
			continue
		if d.length() > 0.5 or absf(g) > 0.5:
			_anclas.append({"centro": orig, "radio": maxf(radio, 6.0), "c": orig, "d": d, "g": g, "m": matriz(g)})


## Edificio movido (lo registra VillageManagerBase al construirlo): todo lo que caiga en su planta original se desplaza.
static func registrar_edificio(rect_original: Rect2, d: Vector2, g: float = 0.0) -> void:
	if d.length() > 0.5 or absf(g) > 0.5:
		_anclas.append({"rect": rect_original.grow(3.0), "c": rect_original.get_center(), "d": d, "g": g, "m": matriz(g)})


## Giro 3D (grados, eje vertical) → cómo se transforma un vector del mapa 2D (y del mapa = z 3D · seno de la inclinación).
static func matriz(g: float) -> Transform2D:
	var s := sin(deg_to_rad(PITCH_DEG))
	var c := cos(deg_to_rad(g))
	var n := sin(deg_to_rad(g))
	return Transform2D(Vector2(c, -s * n), Vector2(n / s, c), Vector2.ZERO)


## El ancla que mueve el punto p (o {} si ninguna).
static func buscar(p: Vector2) -> Dictionary:
	if not _leidas:
		_leer()
	if pausa > 0:
		return {}
	var f: Dictionary = {}
	for am in _muebles:
		if p.distance_to(am["centro"]) <= float(am["radio"]):
			f = am
			break
	for a in _anclas:
		if a.has("rect"):
			if (a["rect"] as Rect2).has_point(p):
				return _componer(a, f)
		elif p.distance_to(a["centro"]) <= float(a["radio"]):
			return _componer(a, f)
	return f


## Primero el mueble dentro de su edificio (f), luego el edificio (a).
static func _componer(a: Dictionary, f: Dictionary) -> Dictionary:
	if f.is_empty():
		return a
	var ma: Transform2D = a["m"]
	var cf: Vector2 = f["c"]
	var ca: Vector2 = a["c"]
	return {"c": cf, "d": ca + a["d"] + ma.basis_xform(cf + f["d"] - ca) - cf, "g": float(a["g"]) + float(f["g"]), "m": ma * (f["m"] as Transform2D)}


static func aplicar(a: Dictionary, p: Vector2) -> Vector2:
	if a.is_empty():
		return p
	var c: Vector2 = a["c"]
	return c + a["d"] + (a["m"] as Transform2D).basis_xform(p - c)


## Rectángulo que sigue al ancla a (si gira, el rectángulo recto que lo contiene).
static func rect_con(a: Dictionary, r: Rect2) -> Rect2:
	if a.is_empty():
		return r
	var out := Rect2(aplicar(a, r.position), Vector2.ZERO)
	for q in [r.end, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y)]:
		out = out.expand(aplicar(a, q))
	return out


## Giro (grados 3D) del ancla que mueve p; 0 si no gira.
static func giro(p: Vector2) -> float:
	var a := buscar(p)
	return 0.0 if a.is_empty() else float(a["g"])


## Pared invisible rectangular (pos original p) que sigue a un ancla girada: tamaño y giro en el mapa 2D.
static func girar_choque(a: Dictionary, sb: Node2D, sz: Vector2) -> void:
	if a.is_empty() or absf(float(a["g"])) < 0.5 or sb == null:
		return
	var m: Transform2D = a["m"]
	sb.rotation = m.x.angle()
	for ch in sb.get_children():
		if ch is CollisionShape2D and ch.shape is RectangleShape2D:
			(ch.shape as RectangleShape2D).size = Vector2(sz.x * m.x.length(), sz.y * m.y.length())


static func desplazamiento(p: Vector2) -> Vector2:
	return aplicar(buscar(p), p) - p


static func mover(p: Vector2, tipo: String = "", nombre: String = "") -> Vector2:
	if grabar and pausa == 0 and not tipo.is_empty():
		grabado.append([tipo, nombre, p])
	return p + desplazamiento(p)


static func mover_puntos(pts: PackedVector2Array) -> PackedVector2Array:
	if pts.is_empty():
		return pts
	var c := Vector2.ZERO
	for q in pts:
		c += q
	var a := buscar(c / float(pts.size()))
	if a.is_empty():
		return pts
	var out := PackedVector2Array()
	for q in pts:
		out.append(aplicar(a, q))
	return out


## Plan de sitios, paso 2 (Claude Code, 2026-11-10): lo contrario de mover. Un punto del mundo ACTUAL (un vecino, el
## jugador) → dónde estaría en el mapa ORIGINAL. Sirve para comparar con zonas y puntos fijos escritos en el código
## (p. ej. «¿está dentro de la taberna?» con VillageTavern.RECT) sin tener que traducir cada zona.
static func desmover(p: Vector2) -> Vector2:
	if not _leidas:
		_leer()
	for a in _anclas:
		var m: Transform2D = a["m"]
		var c: Vector2 = a["c"]
		var d: Vector2 = a["d"]
		var q: Vector2 = c + m.affine_inverse().basis_xform(p - c - d)
		if a.has("rect"):
			if (a["rect"] as Rect2).has_point(q):
				return q
		elif q.distance_to(a["centro"]) <= float(a["radio"]):
			return q
	return p


static var _cache_listas: Dictionary = {} # clave -> [version, Array]

## Lista de puntos originales → actuales, guardada mientras no cambien las anclas (asientos que se miran a menudo).
static func mover_lista(clave: String, lista: Array) -> Array:
	if not _leidas:
		_leer()
	var ver: int = _anclas.size() * 1000 + _muebles.size()
	var c = _cache_listas.get(clave)
	if c != null and int(c[0]) == ver and (c[1] as Array).size() == lista.size():
		return c[1]
	var out: Array = []
	for q in lista:
		out.append(mover(q))
	_cache_listas[clave] = [ver, out]
	return out
