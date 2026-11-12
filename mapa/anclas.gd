extends RefCounted
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Anclas del editor del mapa 3D (Claude Code, 2026-11-10). Cuando el usuario mueve en mapa/Mundo3D.tscn un edificio, un
## objeto de «Objetos» marcado como ancla, un objeto de «Decorado» o un solar de «Solares», todo lo que el juego crea en el mapa 2D dentro de su
## zona original (dibujos, zonas de uso, paredes invisibles, letreros, polígonos) se crea desplazado lo mismo. Así la
## lógica sigue a lo que se ve sin tocar cada sitio del código. Lo usan las funciones _add_* de VillageManagerBase.
##
## Mapa ×E (2026-11-11, docs/specs/PLAN_MAPA_X3.md): la misma capa estira el mapa. Un punto `p` del mapa original va a:
## - dentro de una pieza (edificio, objeto, decorado, grupo compacto) de centro `c`: E·c + d + giro·(p − c), o sea la
##   pieza se aleja E veces del centro del mapa pero conserva su tamaño y lo que lleva dentro;
## - en campo abierto: E·p (las zonas de terreno se estiran enteras).
## Con E = 1 todo queda como siempre. `desmover` es la operación contraria (mundo actual → mapa original).

const ESCENA := "res://mapa/Mundo3D.tscn"
const E: float = Mapa3D.E
const CELDA: float = 256.0    ## tamaño de las celdas del índice de anclas (mapa original y mundo)
const CERCA_PX: float = 40.0  ## lo que hay pegado a un edificio (terraza, puesto, letrero) se queda con él

## Grupos compactos: trozos del mapa hechos por código, sin pieza en el editor, que deben estirarse como una pieza
## (conservan su forma por dentro): coordenadas del mapa original.
const GRUPOS: Dictionary = {
	"campamento": Rect2(-935.0, -215.0, 295.0, 287.0),  ## tu casa, huerto y gallinero
	"cementerio": Rect2(822.0, 260.0, 268.0, 168.0),
	"claro_caso1": Rect2(96.0, -900.0, 84.0, 70.0),      ## cuerpo, orilla y pistas del claro
	"corral_rancho": Rect2(300.0, 396.0, 120.0, 150.0),
}

static var _anclas: Array = [] # {"rect": Rect2} o {"centro": Vector2, "radio": float}, con "c", "d": Vector2, "g": grados, "m": Transform2D
static var _leidas: bool = false
static var pausa: int = 0 # mientras se construye un edificio (ya se desplaza solo) no se aplican
static var grabar: bool = false # tools/hornear_objetos.gd: anota lo que se crea para hacer piezas
static var grabado: Array = [] # [tipo, nombre, pos]

static var _muebles: Array = [] # muebles movidos dentro de su edificio (mapa/mueble.gd), en coordenadas originales
static var _rej: Dictionary = {}   # celda (mapa original) -> anclas que la tocan
static var _rej_m: Dictionary = {} # celda (mundo actual) -> anclas que la tocan


static func _leer() -> void:
	_leidas = true
	for a in load("res://mapa/mueble.gd").anclas():
		var am: Dictionary = (a as Dictionary).duplicate()
		am["m"] = matriz(float(am["g"]))
		_muebles.append(am)
	if E != 1.0:
		for nombre in GRUPOS.keys():
			_anadir({"rect": (GRUPOS[nombre] as Rect2), "c": (GRUPOS[nombre] as Rect2).get_center(), "d": Vector2.ZERO, "g": 0.0, "m": Transform2D.IDENTITY})
	if not ResourceLoader.exists(ESCENA):
		return
	var st: SceneState = (load(ESCENA) as PackedScene).get_state()
	for i in range(st.get_node_count()):
		var ruta := str(st.get_node_path(i))
		var es_obj := ruta.begins_with("./Objetos/")
		var es_dec := ruta.begins_with("./Decorado/") and ruta.count("/") == 3 # Decorado/Zona/Objeto
		var es_bajo := ruta.begins_with("./BajoTierra/") and ruta.count("/") == 2
		var es_solar := ruta.begins_with("./Solares/") and ruta.count("/") == 2
		if not (es_obj or es_dec or es_bajo or es_solar):
			continue
		var orig := Vector2.INF
		var radio := 0.0
		var ancla := false
		var terreno := Vector2.ZERO
		var xf := Transform3D.IDENTITY
		for k in range(st.get_node_property_count(i)):
			var nombre: String = st.get_node_property_name(i, k)
			var v = st.get_node_property_value(i, k)
			match nombre:
				"transform": xf = v
				"pos_original", "metadata/pos_original", "centro_original": orig = v
				"radio_ancla", "metadata/radio": radio = float(v)
				"es_ancla": ancla = bool(v)
				"terreno_m": terreno = Mapa3D.a_mapa(Vector3((v as Vector2).x, 0.0, (v as Vector2).y))
		if orig == Vector2.INF:
			continue
		var d := Mapa3D.a_mapa(xf.origin) - orig * E
		var g := rad_to_deg(xf.basis.orthonormalized().get_euler().y)
		if es_solar:
			# Solar (mapa/solar.gd): todo lo que el juego crea en su terreno va con él; lo construido gira de 90 en 90
			var g_solar: float = fposmod(roundf(g / 90.0) * 90.0, 360.0)
			_anadir({"rect": Rect2(orig - terreno * 0.5, terreno), "c": orig, "d": d, "g": g_solar, "m": matriz(g_solar), "solar": true})
			continue
		if es_bajo:
			# Las alcantarillas enteras (zona de VillageUnderworld) se estiran como una pieza
			_anadir({"rect": Rect2(orig - Vector2(360.0, 160.0), Vector2(720.0, 320.0)), "c": orig, "d": d, "g": 0.0, "m": Transform2D.IDENTITY})
			continue
		if es_obj and not ancla:
			# Objeto con nombre (pozo, tablón, farola…). Mapa de siempre: el juego ya lo pone en su sitio nuevo
			# (mapa/objeto.gd) y aquí solo se gira lo suyo. Mapa estirado: objeto.gd da el sitio original y este ancla
			# (radio pequeño) lo lleva a su sitio, con lo que tenga pegado
			if E == 1.0:
				if absf(g) > 0.5:
					_anadir({"centro": orig + d, "radio": 10.0, "c": orig + d, "d": Vector2.ZERO, "g": g, "m": matriz(g)})
			else:
				_anadir({"centro": orig, "radio": 12.0, "c": orig, "d": d, "g": g, "m": matriz(g)})
			continue
		if E != 1.0 or d.length() > 0.5 or absf(g) > 0.5:
			_anadir({"centro": orig, "radio": maxf(radio, 6.0), "c": orig, "d": d, "g": g, "m": matriz(g)})


## Edificio (lo registra VillageManagerBase al construirlo): todo lo que caiga en su planta original se desplaza con él,
## y lo que tenga pegado (hasta CERCA_PX) también, si no cae dentro de otro edificio.
static func registrar_edificio(rect_original: Rect2, d: Vector2, g: float = 0.0) -> void:
	if E != 1.0 or d.length() > 0.5 or absf(g) > 0.5:
		_anadir({"rect": rect_original.grow(3.0), "cerca": rect_original.grow(CERCA_PX), "c": rect_original.get_center(), "d": d, "g": g, "m": matriz(g)})


static func _anadir(a: Dictionary) -> void:
	if not _leidas:
		_leer()
	_anclas.append(a)
	var r_orig: Rect2 = (a["cerca"] if a.has("cerca") else a["rect"]) if (a.has("rect")) else Rect2((a["centro"] as Vector2) - Vector2.ONE * float(a["radio"]), Vector2.ONE * float(a["radio"]) * 2.0)
	_indexar(_rej, r_orig, a)
	_indexar(_rej_m, rect_con(a, r_orig), a)


static func _indexar(rej: Dictionary, r: Rect2, a: Dictionary) -> void:
	for cx in range(floori(r.position.x / CELDA), floori(r.end.x / CELDA) + 1):
		for cy in range(floori(r.position.y / CELDA), floori(r.end.y / CELDA) + 1):
			var k := Vector2i(cx, cy)
			if not rej.has(k):
				rej[k] = []
			(rej[k] as Array).append(a)


static func _celda(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELDA), floori(p.y / CELDA))


## Giro 3D (grados, eje vertical) → el mismo giro en el mapa 2D (desde el paso 0b el 3D no está estirado: es un giro normal).
static func matriz(g: float) -> Transform2D:
	var c := cos(deg_to_rad(g))
	var n := sin(deg_to_rad(g))
	return Transform2D(Vector2(c, -n), Vector2(n, c), Vector2.ZERO)


## ¿El ancla `a` abarca el punto original `q`? `holgura`: también lo pegado al edificio (su «cerca»).
static func _abarca(a: Dictionary, q: Vector2, holgura: bool) -> bool:
	if a.has("rect"):
		var r: Rect2 = a["cerca"] if (holgura and a.has("cerca")) else a["rect"]
		return r.has_point(q)
	return q.distance_to(a["centro"]) <= float(a["radio"])


## Pasadas de búsqueda, por orden: [¿vale lo pegado al edificio?, ¿se miran los solares?]. Un solar solo manda sobre
## lo que no pertenece a ningún edificio u objeto (ni dentro ni pegado).
const PASADAS: Array = [[false, false], [true, false], [false, true]]

## El ancla que mueve el punto p (o {} si ninguna). Primero la que lo contiene de verdad (la más pequeña si hay
## varias), luego la que lo tiene pegado y, al final, el solar en el que cae.
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
	var cand: Array = _rej.get(_celda(p), [])
	for pasada: Array in PASADAS:
		var mejor: Dictionary = {}
		var area_mejor: float = INF
		for a in cand:
			if a.has("solar") != bool(pasada[1]) or not _abarca(a, p, pasada[0]):
				continue
			if E == 1.0: # mapa de siempre: manda la primera registrada (como hasta ahora)
				return _componer(a, f)
			var area: float = (a["rect"] as Rect2).get_area() if a.has("rect") else 0.0
			if area < area_mejor:
				area_mejor = area
				mejor = a
		if not mejor.is_empty():
			return _componer(mejor, f)
	return f


## Primero el mueble dentro de su edificio (f), luego el edificio (a).
static func _componer(a: Dictionary, f: Dictionary) -> Dictionary:
	if f.is_empty():
		return a
	var ma: Transform2D = a["m"]
	var cf: Vector2 = f["c"]
	var ca: Vector2 = a["c"]
	# El mueble se mueve dentro del edificio (sin estirar); el conjunto va luego donde vaya el edificio
	var d_total: Vector2 = ca * E + a["d"] + ma.basis_xform(cf + f["d"] - ca) - cf * E
	return {"c": cf, "d": d_total, "g": float(a["g"]) + float(f["g"]), "m": ma * (f["m"] as Transform2D)}


## Punto original → mundo actual según el ancla `a` ({}: campo abierto, se estira E veces).
static func aplicar(a: Dictionary, p: Vector2) -> Vector2:
	if a.is_empty():
		return p if pausa > 0 else p * E # en pausa (edificio en construcción) el punto ya está en el mundo
	var c: Vector2 = a["c"]
	return c * E + a["d"] + (a["m"] as Transform2D).basis_xform(p - c)


## Rectángulo que sigue al ancla a (si gira, el rectángulo recto que lo contiene). Sin ancla, estirado E veces.
static func rect_con(a: Dictionary, r: Rect2) -> Rect2:
	if a.is_empty():
		return r if pausa > 0 else Rect2(r.position * E, r.size * E)
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
	if a.is_empty() and E == 1.0:
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
	var cand: Array = _rej_m.get(_celda(p), [])
	for pasada: Array in PASADAS:
		var mejor := Vector2.INF
		var area_mejor: float = INF
		for a in cand:
			var c: Vector2 = a["c"]
			var q: Vector2 = c + (a["m"] as Transform2D).affine_inverse().basis_xform(p - c * E - a["d"])
			if a.has("solar") != bool(pasada[1]) or not _abarca(a, q, pasada[0]):
				continue
			if E == 1.0:
				return q
			var area: float = (a["rect"] as Rect2).get_area() if a.has("rect") else 0.0
			if area < area_mejor:
				area_mejor = area
				mejor = q
		if mejor != Vector2.INF:
			return mejor
	return _fuera_de_piezas(p / E)


## Campo abierto encogido E veces. Si ese punto cae dentro de la planta original de una pieza (en el mundo estirado
## alrededor de cada pieza queda hueco que, encogido, se solapa con ella), se saca al borde más cercano: así «¿está en
## la taberna?», los suelos altos y las salas solo dicen que sí cuando de verdad se está dentro.
static func _fuera_de_piezas(q: Vector2) -> Vector2:
	if E == 1.0:
		return q
	for _vuelta in range(3):
		var tocada: Dictionary = {}
		for a in _rej.get(_celda(q), []):
			if _abarca(a, q, true):
				tocada = a
				break
		if tocada.is_empty():
			return q
		if tocada.has("rect"):
			var r: Rect2 = (tocada["cerca"] if tocada.has("cerca") else tocada["rect"]) as Rect2
			r = r.grow(1.0)
			var dl: float = q.x - r.position.x
			var dr: float = r.end.x - q.x
			var du: float = q.y - r.position.y
			var dd: float = r.end.y - q.y
			var m: float = minf(minf(dl, dr), minf(du, dd))
			if m == dl:
				q.x = r.position.x
			elif m == dr:
				q.x = r.end.x
			elif m == du:
				q.y = r.position.y
			else:
				q.y = r.end.y
		else:
			var c: Vector2 = tocada["centro"]
			var dir: Vector2 = (q - c).normalized() if q.distance_squared_to(c) > 0.01 else Vector2.RIGHT
			q = c + dir * (float(tocada["radio"]) + 1.0)
	return q


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
