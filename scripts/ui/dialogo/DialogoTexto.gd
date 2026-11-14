extends RefCounted

## Diálogos: deja limpio lo que se lee (sin emojis, sin «+8 Relación», sin corchetes de datos) y parte las frases
## largas en trozos que se pasan con clic. Solo cambia cómo se ve; las opciones y sus acciones no se tocan.
## Sin preloads: lo usan la ventana de diálogo y la tienda.

const MAX_CARACTERES_TROZO: int = 240 ## unas tres líneas de la caja; más largo se parte por frases
const PALABRA_DINERO: String = "monedas"

static var _re_parentesis: RegEx
static var _re_corchetes: RegEx
static var _re_oro: RegEx
static var _re_espacios: RegEx
static var _re_existencias: RegEx

static func _preparar() -> void:
	if _re_parentesis != null:
		return
	_re_parentesis = RegEx.create_from_string("\\s*\\(([^()]*)\\)")
	_re_corchetes = RegEx.create_from_string("\\s*\\[([^\\[\\]]*)\\]")
	_re_oro = RegEx.create_from_string("([+-]?)\\s*(\\d+)\\s*Oro")
	_re_espacios = RegEx.create_from_string("[ \\t]{2,}")
	_re_existencias = RegEx.create_from_string("Stock:\\s*(\\d+)")

## ¿Es un emoji o un símbolo de adorno? (bloques de pictogramas, flechas decoradas, variaciones y uniones de emoji)
static func _es_adorno(c: int) -> bool:
	return c >= 0x1F000 or (c >= 0x2190 and c <= 0x21FF) or (c >= 0x2300 and c <= 0x23FF) \
		or (c >= 0x2600 and c <= 0x27BF) or (c >= 0x2B00 and c <= 0x2BFF) or c == 0xFE0F or c == 0x200D or c == 0x20E3

static func sin_emojis(t: String) -> String:
	var out: String = ""
	for i in range(t.length()):
		if not _es_adorno(t.unicode_at(i)):
			out += t[i]
	return out

## Dinero que cuesta o da una opción («-15 Oro» → 15), o -1 si no habla de dinero.
static func dinero(t: String) -> int:
	_preparar()
	var m: RegExMatch = _re_oro.search(t)
	return int(m.get_string(2)) if m != null else -1

## Existencias que anuncia una opción de tienda («[Stock: 3]» → 3), o -1.
static func existencias(t: String) -> int:
	_preparar()
	var m: RegExMatch = _re_existencias.search(t)
	return int(m.get_string(1)) if m != null else -1

## Etiqueta de una opción tal como se lee: los paréntesis y corchetes de datos se quitan; si hablaban de dinero,
## queda un «· 15 monedas» discreto, porque pagar sin saber cuánto sería peor.
static func limpiar_etiqueta(t: String) -> String:
	_preparar()
	var coste: int = -1
	for re: RegEx in [_re_parentesis, _re_corchetes]:
		for m: RegExMatch in re.search_all(t):
			var dentro: String = m.get_string(1)
			if coste < 0 and _re_oro.search(dentro) != null:
				coste = dinero(dentro)
		t = re.sub(t, "", true)
	t = _re_espacios.sub(sin_emojis(t), " ", true).strip_edges()
	t = t.trim_prefix("/ ").trim_prefix("· ").trim_prefix(": ").strip_edges()
	if coste >= 0:
		t += " · %d %s" % [coste, PALABRA_DINERO]
	return t

## Texto de un vecino tal como se lee: sin emojis y sin las líneas de datos entre corchetes (van a «Ver ficha»).
static func limpiar_texto(t: String) -> String:
	var lineas: PackedStringArray = []
	for linea in sin_emojis(t).split("\n"):
		var l: String = linea.strip_edges()
		if l.begins_with("[") and l.ends_with("]"):
			continue
		lineas.append(l)
	_preparar()
	return _re_espacios.sub("\n".join(lineas), " ", true).strip_edges()

## Parte un texto largo en trozos de como mucho MAX_CARACTERES_TROZO, cortando por párrafos y luego por frases.
static func trozos(t: String) -> Array[String]:
	var out: Array[String] = []
	for parrafo in t.split("\n\n", false):
		var actual: String = ""
		for frase in _frases(parrafo.strip_edges()):
			if actual != "" and actual.length() + frase.length() + 1 > MAX_CARACTERES_TROZO:
				out.append(actual)
				actual = ""
			actual = frase if actual == "" else actual + " " + frase
		if actual != "":
			out.append(actual)
	if out.is_empty():
		out.append("")
	return out

## Frases de un párrafo: corta tras «. », «! » o «? » (o «.» » al cerrar una cita), nunca dentro de unas comillas.
static func _frases(p: String) -> Array[String]:
	var out: Array[String] = []
	var actual: String = ""
	for i in range(p.length()):
		actual += p[i]
		var cierra_cita: bool = p[i] == "»" and i > 0 and p[i - 1] in [".", "!", "?"]
		var fin: bool = (p[i] in [".", "!", "?"] or cierra_cita) and (i + 1 >= p.length() or p[i + 1] == " ")
		if fin and actual.strip_edges().length() > 0:
			out.append(actual.strip_edges())
			actual = ""
	if actual.strip_edges() != "":
		out.append(actual.strip_edges())
	return out
