extends RefCounted

## Lee un plano de casa (tools/casas/plano_*.gd) como diccionario para el constructor (2026-11-13). Un mismo plano
## sirve para varias casas: `id` pone otro dueño y `espejo` da la vuelta este-oeste (los dormitorios al otro lado),
## así dos casas vecinas hechas por el mismo albañil no son calcadas. `POR_OFICIO` (opcional) añade los muebles propios
## del oficio de cada casa; `girar` da media vuelta a la casa (puerta al norte).
## Casas de dos plantas: la alta va en los campos «…_ARRIBA» y la escalera en «ESCALERA» (pie y cima), opcionales.
## «REJA» (opcional): la reja corredera de un calabozo, con el centro de su hueco («en») y su ancho.

const CAMPOS: Array[String] = [
	"ID", "PLANTA_M", "PUERTA_X_M", "PUERTA_ANCHO_M", "VENTANA_X_M", "CARTEL_M", "FACHADA", "TABIQUE", "MADERA",
	"BALDOSA", "TEJADO", "ZOCALO", "TEJADO_CHAPA", "CUARTOS", "TABIQUES", "VENTANAS", "MUEBLES", "MARCAS",
	"CUARTOS_ARRIBA", "TABIQUES_ARRIBA", "VENTANAS_ARRIBA", "MUEBLES_ARRIBA", "MARCAS_ARRIBA", "ESCALERA", "REJA",
]
## Los mismos campos en una y otra planta (la alta solo si la casa la tiene).
const PLANTAS: Array[String] = ["", "_ARRIBA"]
const LADO_CONTRARIO: Dictionary = {"este": "oeste", "oeste": "este", "sur": "norte", "norte": "sur"}
const MEDIA_VUELTA_GRADOS: float = 180.0


static func leer(guion: GDScript, id: String = "", espejo: bool = false, girar: bool = false) -> Dictionary:
	var constantes: Dictionary = guion.get_script_constant_map()
	var plano: Dictionary = {}
	for campo: String in CAMPOS:
		if not constantes.has(campo):
			continue # campo opcional que este plano no usa (p. ej. TEJADO_CHAPA)
		var valor: Variant = constantes[campo]
		plano[campo] = valor.duplicate(true) if valor is Array or valor is Dictionary else valor # el plano no se toca
	if not id.is_empty():
		plano["ID"] = id
	var por_oficio: Dictionary = constantes.get("POR_OFICIO", {})
	for extra: Dictionary in por_oficio.get(plano["ID"], []):
		(plano["MUEBLES"] as Array).append(extra.duplicate(true)) # lo propio del oficio de esta casa (horno, maniquí…)
	if espejo: # x por −x: los muros sur y norte no cambian de lado; este y oeste se cambian
		_mover(plano, func(p: Vector2) -> Vector2: return Vector2(-p.x, p.y), func(g: float) -> float: return -g, ["este", "oeste"])
	if girar: # media vuelta (casas con la puerta al norte): todo al lado contrario y los muebles giran 180°
		_mover(plano, func(p: Vector2) -> Vector2: return -p, func(g: float) -> float: return g + MEDIA_VUELTA_GRADOS, LADO_CONTRARIO.keys())
		plano["PUERTA_LADO"] = "norte"
	return plano


## Lleva todo el plano a su nuevo sitio: `punto` mueve cada sitio, `giro` cada mueble, y las ventanas de los `lados`
## que cambian pasan al contrario (las demás cambian de punta a lo largo de su muro).
static func _mover(plano: Dictionary, punto: Callable, giro: Callable, lados: Array) -> void:
	var cartel: Vector3 = plano["CARTEL_M"]
	var cartel_plano: Vector2 = punto.call(Vector2(cartel.x, cartel.z))
	plano["CARTEL_M"] = Vector3(cartel_plano.x, cartel.y, cartel_plano.y)
	plano["PUERTA_X_M"] = (punto.call(Vector2(float(plano["PUERTA_X_M"]), 0.0)) as Vector2).x
	plano["VENTANA_X_M"] = (punto.call(Vector2(float(plano["VENTANA_X_M"]), 0.0)) as Vector2).x
	for planta: String in PLANTAS:
		if not plano.has("CUARTOS" + planta):
			continue
		for cuarto: Dictionary in plano["CUARTOS" + planta]:
			cuarto["centro"] = punto.call(cuarto["centro"])
			if cuarto.has("paso"):
				cuarto["paso"] = punto.call(cuarto["paso"])
		var tabiques: Array = []
		for t: Array in plano["TABIQUES" + planta]:
			tabiques.append([punto.call(t[0]), punto.call(t[1])])
		plano["TABIQUES" + planta] = tabiques
		for v: Dictionary in plano["VENTANAS" + planta]:
			_mover_ventana(v, lados)
		for m: Dictionary in plano["MUEBLES" + planta]:
			m["pos"] = punto.call(m["pos"])
			m["giro"] = giro.call(float(m.get("giro", 0.0)))
		for marca: String in plano["MARCAS" + planta]:
			plano["MARCAS" + planta][marca] = punto.call(plano["MARCAS" + planta][marca])
	if plano.has("REJA"):
		plano["REJA"]["en"] = punto.call(plano["REJA"]["en"])
	if plano.has("ESCALERA"):
		for punta: String in plano["ESCALERA"]:
			plano["ESCALERA"][punta] = punto.call(plano["ESCALERA"][punta])


static func _mover_ventana(v: Dictionary, lados: Array) -> void:
	if v["lado"] in lados:
		v["lado"] = LADO_CONTRARIO[v["lado"]]
	var a_lo_largo_x: bool = v["lado"] in ["sur", "norte"]
	var espejo_este_oeste: bool = not lados.has("sur")
	if a_lo_largo_x or not espejo_este_oeste:
		v["en"] = -float(v["en"])
