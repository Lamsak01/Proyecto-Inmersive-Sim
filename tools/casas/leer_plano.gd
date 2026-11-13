extends RefCounted

## Lee un plano de casa (tools/casas/plano_*.gd) como diccionario para el constructor (2026-11-13). Un mismo plano
## sirve para varias casas: `id` pone otro dueño y `espejo` da la vuelta este-oeste (los dormitorios al otro lado),
## así dos casas vecinas hechas por el mismo albañil no son calcadas.

const CAMPOS: Array[String] = [
	"ID", "PLANTA_M", "PUERTA_X_M", "PUERTA_ANCHO_M", "VENTANA_X_M", "CARTEL_M", "FACHADA", "TABIQUE", "MADERA",
	"BALDOSA", "TEJADO", "ZOCALO", "CUARTOS", "TABIQUES", "VENTANAS", "MUEBLES", "MARCAS",
]
const LADO_CONTRARIO: Dictionary = {"este": "oeste", "oeste": "este"}


static func leer(guion: GDScript, id: String = "", espejo: bool = false) -> Dictionary:
	var constantes: Dictionary = guion.get_script_constant_map()
	var plano: Dictionary = {}
	for campo: String in CAMPOS:
		var valor: Variant = constantes[campo]
		plano[campo] = valor.duplicate(true) if valor is Array or valor is Dictionary else valor # el plano no se toca
	if not id.is_empty():
		plano["ID"] = id
	if espejo:
		_dar_la_vuelta(plano)
	return plano


## Cambia x por −x en todo (los muros sur y norte no cambian de lado; este y oeste se cambian).
static func _dar_la_vuelta(plano: Dictionary) -> void:
	plano["PUERTA_X_M"] = -float(plano["PUERTA_X_M"])
	plano["VENTANA_X_M"] = -float(plano["VENTANA_X_M"])
	plano["CARTEL_M"] = (plano["CARTEL_M"] as Vector3) * Vector3(-1.0, 1.0, 1.0)
	for cuarto: Dictionary in plano["CUARTOS"]:
		cuarto["centro"] = _x(cuarto["centro"])
		if cuarto.has("paso"):
			cuarto["paso"] = _x(cuarto["paso"])
	var tabiques: Array = []
	for t: Array in plano["TABIQUES"]:
		tabiques.append([_x(t[0]), _x(t[1])])
	plano["TABIQUES"] = tabiques
	for v: Dictionary in plano["VENTANAS"]:
		if LADO_CONTRARIO.has(v["lado"]):
			v["lado"] = LADO_CONTRARIO[v["lado"]]
		else:
			v["en"] = -float(v["en"])
	for m: Dictionary in plano["MUEBLES"]:
		m["pos"] = _x(m["pos"])
		m["giro"] = -float(m.get("giro", 0.0)) # el que miraba al este mira al oeste
	for marca: String in plano["MARCAS"]:
		plano["MARCAS"][marca] = _x(plano["MARCAS"][marca])


static func _x(p: Vector2) -> Vector2:
	return Vector2(-p.x, p.y)
