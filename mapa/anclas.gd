extends RefCounted

## Anclas del editor del mapa 3D (Claude Code, 2026-11-10). Cuando el usuario mueve en mapa/Mundo3D.tscn un edificio, un
## objeto de «Objetos» marcado como ancla o un objeto de «Decorado», todo lo que el juego crea en el mapa 2D dentro de su
## zona original (dibujos, zonas de uso, paredes invisibles, letreros, polígonos) se crea desplazado lo mismo. Así la
## lógica sigue a lo que se ve sin tocar cada sitio del código. Lo usan las funciones _add_* de VillageManagerBase.

const ESCENA := "res://mapa/Mundo3D.tscn"
const WORLD_SCALE: float = 0.02
const PITCH_DEG: float = 58.0

static var _anclas: Array = [] # {"rect": Rect2} o {"centro": Vector2, "radio": float}, con "d": Vector2
static var _leidas: bool = false
static var pausa: int = 0 # mientras se construye un edificio (ya se desplaza solo) no se aplican
static var grabar: bool = false # tools/hornear_objetos.gd: anota lo que se crea para hacer piezas
static var grabado: Array = [] # [tipo, nombre, pos]


static func _leer() -> void:
	_leidas = true
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
		if orig == Vector2.INF or (es_obj and not ancla):
			continue
		var d := Vector2(xf.origin.x / WORLD_SCALE, xf.origin.z * sin_p / WORLD_SCALE) - orig
		if d.length() > 0.5:
			_anclas.append({"centro": orig, "radio": maxf(radio, 6.0), "d": d})


## Edificio movido (lo registra VillageManagerBase al construirlo): todo lo que caiga en su planta original se desplaza.
static func registrar_edificio(rect_original: Rect2, d: Vector2) -> void:
	if d.length() > 0.5:
		_anclas.append({"rect": rect_original.grow(3.0), "d": d})


static func desplazamiento(p: Vector2) -> Vector2:
	if not _leidas:
		_leer()
	if pausa > 0:
		return Vector2.ZERO
	for a in _anclas:
		if a.has("rect"):
			if (a["rect"] as Rect2).has_point(p):
				return a["d"]
		elif p.distance_to(a["centro"]) <= float(a["radio"]):
			return a["d"]
	return Vector2.ZERO


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
	var d := desplazamiento(c / float(pts.size()))
	if d == Vector2.ZERO:
		return pts
	var out := PackedVector2Array()
	for q in pts:
		out.append(q + d)
	return out
