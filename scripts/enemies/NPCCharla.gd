extends RefCounted

## Charla provisional de los vecinos (2026-11-13): saludo según la hora, el trato y el tiempo, y una charla de 2 o 3
## intercambios sobre su oficio, el pueblo (el crimen, si ya ha pasado) y cómo está. Las frases viven en
## resources/dialogos/frases_vecinos.json para reescribirlas sin tocar código. Sin preloads de otros sistemas.

const ARCHIVO_FRASES: String = "res://resources/dialogos/frases_vecinos.json"
const OFICIO_GENERICO: String = "_cualquiera"
const AFINIDAD_FRIA: int = -10   ## por debajo, saluda seco
const AFINIDAD_AMIGA: int = 45   ## desde aquí, saluda con alegría
const ANIMO_BAJO: float = 35.0
const NECESIDAD_BAJA: float = 25.0
const HORA_ALBA: int = 7
const HORA_MEDIODIA: int = 13
const HORA_NOCHE: int = 20
const PROB_COMENTA_TIEMPO: float = 0.5

static var _frases: Dictionary = {}

static func _datos() -> Dictionary:
	if _frases.is_empty():
		var bruto: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARCHIVO_FRASES))
		_frases = bruto if bruto is Dictionary else {"_vacio": true}
	return _frases

## Azar fijo durante una hora para cada vecino: si el diálogo se rehace tras comprar, no cambia lo que dijo.
static func _azar(npc, sal: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var dia: int = int(WorldClock.current_day) if WorldClock != null else 0
	var hora: int = int(WorldClock.current_hour) if WorldClock != null else 0
	rng.seed = hash("%s|%d|%d|%s" % [str(npc.npc_name), dia, hora, sal])
	return rng

static func _una(lista: Variant, rng: RandomNumberGenerator, nombre: String = "") -> String:
	if not (lista is Array) or (lista as Array).is_empty():
		return ""
	return str((lista as Array)[rng.randi() % (lista as Array).size()]).replace("{nombre}", nombre)

static func _frase(lista: Array, i: int, nombre: String) -> String:
	return str(lista[i % lista.size()]).replace("{nombre}", nombre) if not lista.is_empty() else ""

static func _oficio(npc) -> Dictionary:
	var oficios: Dictionary = _datos().get("oficios", {})
	var claves: Array = VillageNPC.TradeRole.keys()
	var rol: int = int(npc.trade_role)
	var clave: String = str(claves[rol]) if rol >= 0 and rol < claves.size() else OFICIO_GENERICO
	return oficios.get(clave, oficios.get(OFICIO_GENERICO, {}))

## Primera frase al acercarte: según el trato, la hora y, a veces, el tiempo.
static func saludo(npc) -> String:
	var d: Dictionary = _datos()
	var rng := _azar(npc, "saludo")
	var linea: String
	if int(npc.affinity) <= AFINIDAD_FRIA:
		linea = _una(d.get("saludos_frios"), rng)
	elif int(npc.affinity) >= AFINIDAD_AMIGA:
		linea = _una(d.get("saludos_amigos"), rng)
	else:
		linea = _una((d.get("saludos", {}) as Dictionary).get(_momento()), rng)
	if rng.randf() < PROB_COMENTA_TIEMPO:
		linea += " " + _una((d.get("tiempo", {}) as Dictionary).get(_tiempo()), rng)
	return "«%s»" % linea.strip_edges()

## Lo que dice al abrir la tienda.
static func frase_tienda(npc) -> String:
	return str(_oficio(npc).get("tienda", ""))

## Añade al diálogo la charla: «charla» → oficio / pueblo / ánimo, y vuelta al principio.
static func anadir(npc, diag: Dictionary, hay_crimen: bool) -> void:
	var d: Dictionary = _datos()
	var r: Dictionary = d.get("respuestas", {})
	var rng := _azar(npc, "charla")
	var frases_oficio: Array = _oficio(npc).get("charla", [])
	var pueblo: Dictionary = d.get("pueblo", {})
	var irse: Dictionary = {"label": str(r.get("irse", "Te dejo seguir.")), "next": "start"}
	var a_pueblo: Dictionary = {"label": str(r.get("pueblo", "¿Qué se cuenta?")), "next": "charla_pueblo"}
	var a_animo: Dictionary = {"label": str(r.get("animo", "¿Y tú qué tal?")), "next": "charla_animo"}
	var primera: int = rng.randi() % maxi(1, frases_oficio.size())
	diag["charla"] = {"text": "«%s»" % _frase(frases_oficio, primera, str(npc.npc_name)),
		"choices": [{"label": str(r.get("oficio", "¿Qué tal el trabajo?")), "next": "charla_oficio"}, a_pueblo, irse]}
	diag["charla_oficio"] = {"text": "«%s»" % _frase(frases_oficio, primera + 1, str(npc.npc_name)), "choices": [a_pueblo, a_animo, irse]} # otra distinta
	var lista_pueblo: Variant = pueblo.get("crimen") if hay_crimen else pueblo.get("normal")
	diag["charla_pueblo"] = {"text": "«%s»" % _una(lista_pueblo, rng), "choices": [a_animo, irse]}
	diag["charla_animo"] = {"text": "«%s»" % _una((d.get("animo", {}) as Dictionary).get(_animo(npc)), rng),
		"choices": [{"label": str(r.get("despedida", "Cuídate.")), "next": "start"}]}

static func _momento() -> String:
	var h: int = int(WorldClock.current_hour) if WorldClock != null else 12
	if h < HORA_ALBA:
		return "madrugada"
	if h < HORA_MEDIODIA:
		return "manana"
	return "tarde" if h < HORA_NOCHE else "noche"

static func _tiempo() -> String:
	if WorldClock == null:
		return "despejado"
	match int(WorldClock.current_weather):
		WorldClock.WeatherType.RAIN:
			return "lluvia"
		WorldClock.WeatherType.FOG:
			return "niebla"
	return "despejado"

static func _animo(npc) -> String:
	if float(npc.need_hunger) < NECESIDAD_BAJA:
		return "hambre"
	if float(npc.need_energy) < NECESIDAD_BAJA:
		return "sueno"
	return "mal" if float(npc.mood) < ANIMO_BAJO else "bien"
