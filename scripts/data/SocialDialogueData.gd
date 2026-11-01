extends RefCounted

## Catálogo procedural de frases y acciones sociales para conversaciones entre vecinos (B1.1).
## Se carga con preload("res://scripts/data/SocialDialogueData.gd") para evitar problemas de caché de class_name en headless.

const ACTION_SMALL_TALK := "small_talk"
const ACTION_SHARED_TASTE := "shared_taste"
const ACTION_COMPLIMENT := "compliment"
const ACTION_VENT := "vent"
const ACTION_JOKE := "joke"
const ACTION_FRICTION := "friction"
const ACTION_TASTE_CLASH := "taste_clash"
const ACTION_APOLOGY := "apology"
const ACTION_FLIRT := "flirt"
const ACTION_AFFECTION := "affection"
const ACTION_JEALOUSY := "jealousy"

const ALL_ACTIONS: Array[String] = [
	ACTION_SMALL_TALK,
	ACTION_SHARED_TASTE,
	ACTION_COMPLIMENT,
	ACTION_VENT,
	ACTION_JOKE,
	ACTION_FRICTION,
	ACTION_TASTE_CLASH,
	ACTION_APOLOGY,
	ACTION_FLIRT,
	ACTION_AFFECTION,
	ACTION_JEALOUSY,
]

## Etiquetas naturales en español para los 16 temas de gustos de PersonProfile.TASTE_TOPICS.
const TASTE_LABELS: Dictionary = {
	"pescado": "el pescado del río",
	"carne_asada": "la carne asada al fuego",
	"pan_caliente": "el pan recién salido del horno",
	"estofado": "el estofado casero",
	"hierbas": "el aroma de las hierbas del monte",
	"forja": "el oficio de la fragua",
	"carpinteria": "la madera bien trabajada",
	"caza": "salir de caza al bosque",
	"pesca": "echar la caña junto al agua",
	"cartas": "las partidas de cartas en la posada",
	"historias": "los relatos antiguos del valle",
	"silencio": "la calma de las horas tranquilas",
	"lluvia": "los días de lluvia sobre los tejados",
	"musica": "la música al caer la tarde",
	"reliquias": "las reliquias y curiosidades antiguas",
	"animales": "cuidar de los animales del pueblo",
}

## Metadatos visuales y de memoria para cada tipo de acción social.
const ACTION_META: Dictionary = {
	ACTION_SMALL_TALK: {
		"icon": "💬",
		"label": "Charla cotidiana",
		"color": Color(0.76, 0.95, 1.0),
		"note": "Charlaron un rato al cruzarse en el pueblo",
	},
	ACTION_SHARED_TASTE: {
		"icon": "✨💬",
		"label": "Gusto compartido",
		"color": Color(0.62, 1.0, 0.80),
		"note": "Conectaron hablando de su gusto común por %s",
	},
	ACTION_COMPLIMENT: {
		"icon": "😊🤝",
		"label": "Cumplido",
		"color": Color(0.68, 1.0, 0.74),
		"note": "Intercambiaron palabras de aprecio sincero",
	},
	ACTION_VENT: {
		"icon": "😮‍💨💬",
		"label": "Desahogo",
		"color": Color(0.84, 0.90, 1.0),
		"note": "Se desahogaron sobre el cansancio de la jornada",
	},
	ACTION_JOKE: {
		"icon": "😄💬",
		"label": "Broma amistosa",
		"color": Color(0.95, 0.96, 0.64),
		"note": "Rieron juntos con una broma durante el descanso",
	},
	ACTION_FRICTION: {
		"icon": "😒💬",
		"label": "Roce de carácter",
		"color": Color(1.0, 0.74, 0.42),
		"note": "Tuvieron un roce de carácter al conversar",
	},
	ACTION_TASTE_CLASH: {
		"icon": "😠💬",
		"label": "Choque de gustos",
		"color": Color(1.0, 0.62, 0.40),
		"note": "Discutieron por sus opiniones opuestas sobre %s",
	},
	ACTION_APOLOGY: {
		"icon": "🍻🤝",
		"label": "Disculpa sincera",
		"color": Color(0.55, 1.0, 0.72),
		"note": "Limaron asperezas con una disculpa inesperada",
	},
	ACTION_FLIRT: {
		"icon": "💘",
		"label": "Coqueteo",
		"color": Color(1.0, 0.68, 0.86),
		"note": "Coquetearon con complicidad al encontrarse",
	},
	ACTION_AFFECTION: {
		"icon": "💑",
		"label": "Cariño de pareja",
		"color": Color(1.0, 0.56, 0.76),
		"note": "Compartieron un momento cariñoso en pareja",
	},
	ACTION_JEALOUSY: {
		"icon": "💢💔",
		"label": "Reproche de celos",
		"color": Color(1.0, 0.50, 0.45),
		"note": "Tuvieron una escena de celos y desconfianza",
	},
}

## Plantillas de apertura (A) y respuesta (B) por acción, con variantes por rasgo cuando aplica.
const OPENERS_BY_ACTION: Dictionary = {
	ACTION_SMALL_TALK: {
		"default": [
			"¡Buenas, {b}! Hoy el día avanza rápido en el valle.",
			"Qué tal va la jornada, {b}? Se agradece un respiro.",
			"Siempre viene bien parar un momento a saludar, {b}.",
		],
		"Alegre": [
			"¡Ey, {b}! ¡Qué alegría cruzarte hoy por aquí!",
			"¡Buen día, {b}! Hoy tengo el ánimo por las nubes.",
		],
		"Trabajador": [
			"{b}, vengo con las manos cansadas pero la faena al día.",
			"Un minuto de charla y vuelvo al tajo, {b}.",
		],
		"Curioso": [
			"Oye {b}, ¿has notado movimiento nuevo hoy por la plaza?",
			"{b}, ¿qué se comenta hoy por tu rincón del pueblo?",
		],
		"Pacífico": [
			"Qué paz se respira cuando el pueblo está tranquilo, ¿verdad {b}?",
		],
		"Desconfiado": [
			"Conviene andar con ojo hoy, {b}, nunca se sabe.",
		],
		"Noctámbulo": [
			"Bostecé toda la mañana, {b}... yo rindo mejor de noche.",
		],
	},
	ACTION_SHARED_TASTE: {
		"default": [
			"Dicen que nada alegra tanto el día como {topic}, ¿no crees, {b}?",
			"Estaba pensando en {topic}... pocos aquí lo aprecian como tú, {b}.",
			"Oye {b}, cuando quieras hablamos de {topic}, sé que te encanta.",
		],
		"Alegre": [
			"¡{b}! Solo pensar en {topic} ya me pone de buen humor.",
		],
		"Curioso": [
			"{b}, siempre descubro algo nuevo sobre {topic} cuando charlamos.",
		],
	},
	ACTION_COMPLIMENT: {
		"default": [
			"Da gusto tener gente como tú en el pueblo, {b}.",
			"Oye {b}, se nota el empeño que pones cada día.",
			"Quería decirte que valoro mucho tu palabra, {b}.",
		],
		"Bondadoso": [
			"{b}, si algún día necesitas una mano, cuenta conmigo sin dudar.",
		],
		"Honrado": [
			"En este valle hace falta gente recta como tú, {b}.",
		],
		"Leal": [
			"Con vecinos de fiar como tú da tranquilidad vivir aquí, {b}.",
		],
	},
	ACTION_VENT: {
		"default": [
			"Uf, {b}... hoy siento que las horas pesan el doble.",
			"No te imaginas el trajín que llevo encima hoy, {b}.",
			"A veces uno solo necesita que alguien le escuche un momento, {b}.",
		],
		"Trabajador": [
			"Llevo desde el alba sin parar, {b}, tengo la espalda molida.",
		],
		"Orgulloso": [
			"No suelo quejarme, {b}, pero hoy me han puesto a prueba.",
		],
	},
	ACTION_JOKE: {
		"default": [
			"¡Si cobraran por suspirar en este pueblo nos arruinábamos, {b}!",
			"Oye {b}, a este paso las ranas trabajarán menos que nosotros.",
			"¿Apostamos a que hoy la posada se llena antes del anochecer, {b}?",
		],
		"Tahúr": [
			"¡{b}, te juego una ronda imaginaria a que adivino en qué piensas!",
		],
		"Alegre": [
			"¡Pon buena cara, {b}, que hasta el sol salió a vernos hoy!",
		],
		"Chismoso": [
			"Si las paredes del pueblo hablaran, {b}, no dormiría nadie.",
		],
	},
	ACTION_FRICTION: {
		"default": [
			"A ver si miras por dónde caminas, {b}, no estás solo en la calle.",
			"No todos tenemos tanta paciencia para tus modos, {b}.",
			"Guárdate tus consejos para quien te los pida, {b}.",
		],
		"Orgulloso": [
			"Cuida el tono conmigo, {b}, que no somos iguales.",
		],
		"Rencoroso": [
			"Yo no olvido tan fácil los desaires del pasado, {b}.",
		],
		"Frío": [
			"Di lo que tengas que decir rápido, {b}, me quitas tiempo.",
		],
		"Celoso": [
			"Últimamente te metes donde nadie te llama, {b}.",
		],
	},
	ACTION_TASTE_CLASH: {
		"default": [
			"Nunca entenderé cómo puedes soportar {topic}, {b}.",
			"De verdad te gusta {topic}, {b}? A mí me saca de quicio.",
			"Otra vez con {topic}, {b}... qué manía la tuya.",
		],
	},
	ACTION_APOLOGY: {
		"default": [
			"Oye {b}... estuve brusco la otra vez. Empecemos de nuevo.",
			"{b}, la vida en el valle es corta para andar a malas contigo.",
			"Reconozco que me equivoqué contigo, {b}. ¿Lo dejamos atrás?",
		],
		"Honrado": [
			"Es de justos admitir un error, {b}. Te pido disculpas.",
		],
		"Pacífico": [
			"Prefiero la paz entre vecinos, {b}. Olvidemos nuestros roces.",
		],
	},
	ACTION_FLIRT: {
		"default": [
			"No sé si es impresión mía, {b}, pero el día mejora en cuanto apareces.",
			"Siempre busco una excusa para cruzarme contigo a esta hora, {b}.",
			"Oye {b}... me encanta cuando nos quedamos charlando los dos solos.",
		],
		"Alegre": [
			"¡Con esa sonrisa tuya me alegras toda la tarde, {b}!",
		],
		"Bondadoso": [
			"Tienes una forma de ser que hace que uno se sienta en casa, {b}.",
		],
		"Orgulloso": [
			"Poca gente en este valle me llama la atención como tú, {b}.",
		],
	},
	ACTION_AFFECTION: {
		"default": [
			"Lo mejor de terminar la jornada es pasar este rato contigo, {b}.",
			"Contigo a mi lado hasta los días duros en el valle se hacen ligeros, {b}.",
			"Me alegra tanto que compartamos la vida aquí, {b}.",
		],
		"Leal": [
			"Pase lo que pase en el pueblo, siempre estaré a tu lado, {b}.",
		],
		"Bondadoso": [
			"Verte bien es todo lo que necesito hoy, {b}.",
		],
		"Pacífico": [
			"Qué paz siento cada vez que estamos juntos, {b}.",
		],
	},
	ACTION_JEALOUSY: {
		"default": [
			"Últimamente pasas demasiado tiempo con otra gente y apenas me miras, {b}.",
			"No me gusta nada tanta risita y confianzas que te traes por el pueblo, {b}.",
			"Oye {b}, ¿se puede saber por qué me esquivas cuando te pregunto con quién estabas?",
		],
		"Celoso": [
			"¡Te he visto muy sonriente por la plaza, {b}, y no soy tonto!",
			"Conmigo no juegues a dos bandas, {b}, que lo noto todo.",
		],
		"Orgulloso": [
			"No pienso quedar en ridículo delante de todo el valle por tu culpa, {b}.",
		],
	},
}

const REPLIES_BY_ACTION: Dictionary = {
	ACTION_SMALL_TALK: {
		"default": [
			"Igualmente, {a}. Que te sea leve el resto del día.",
			"Tienes razón, {a}, charlar un minuto despeja la cabeza.",
			"¡Eso es, {a}! Paso a paso sale todo adelante.",
		],
		"Alegre": [
			"¡Así se habla, {a}! Nos vemos luego en la plaza.",
		],
		"Paciente": [
			"Con calma todo llega a buen puerto, {a}.",
		],
		"Frío": [
			"Sí, {a}. Todo en orden por mi parte.",
		],
	},
	ACTION_SHARED_TASTE: {
		"default": [
			"¡Tal cual, {a}! Pocas cosas superan {topic}.",
			"Me alegra coincidir en eso contigo, {a}, {topic} es lo mejor.",
			"¡Sabía que tenías buen gusto, {a}! Viva {topic}.",
		],
		"Bondadoso": [
			"La próxima vez compartimos {topic} con calma, {a}.",
		],
	},
	ACTION_COMPLIMENT: {
		"default": [
			"Gracias de corazón, {a}. Lo mismo digo de ti.",
			"Tus palabras me animan el día, {a}, se agradece.",
			"Es mutuo, {a}; da gusto tratar contigo.",
		],
		"Orgulloso": [
			"Me alegra que alguien por fin reconozca el mérito, {a}.",
		],
		"Leal": [
			"Cuenta siempre conmigo cuando haga falta, {a}.",
		],
	},
	ACTION_VENT: {
		"default": [
			"Te entiendo bien, {a}... ánimo, que ya queda menos para descansar.",
			"Respira hondo, {a}, no cargues con todo el peso tú solo.",
			"Todos tenemos días cuesta arriba, {a}. Aquí me tienes para charlar.",
		],
		"Paciente": [
			"Cada cosa a su tiempo, {a}. Mañana se verá más claro.",
		],
		"Bondadoso": [
			"Ojalá pudiera quitarte parte del cansancio, {a}. Cuídate hoy.",
		],
	},
	ACTION_JOKE: {
		"default": [
			"¡Ja, ja! Qué ocurrencia la tuya, {a}, me hiciste reír.",
			"¡Buena esa, {a}! Me hacía falta reírme un rato.",
			"No tienes remedio, {a}, siempre sacas una sonrisa.",
		],
		"Alegre": [
			"¡Ja, ja, esa estuvo genial, {a}!",
		],
		"Tahúr": [
			"¡Hecho, {a}! Pero la próxima apuesta la gano yo.",
		],
	},
	ACTION_FRICTION: {
		"default": [
			"Baja esos humos, {a}, que nadie te debe pleitesía.",
			"Con ese carácter no sé quién te aguanta, {a}.",
			"Mejor sigo mi camino antes de perder la paciencia contigo, {a}.",
		],
		"Orgulloso": [
			"A mí no me hables en ese tono, {a}.",
		],
		"Rencoroso": [
			"Apuntado queda, {a}. Ya veremos quién ríe último.",
		],
		"Pacífico": [
			"No voy a entrar en tu juego, {a}. Buenas tardes.",
		],
	},
	ACTION_TASTE_CLASH: {
		"default": [
			"Pues a mí {topic} me parece excelente, {a}, qué sabrás tú.",
			"Para gustos los colores, {a}, pero no te metas con {topic}.",
			"Qué exagerado eres con {topic}, {a}, no hay quien coincida contigo.",
		],
	},
	ACTION_APOLOGY: {
		"default": [
			"Acepto tus palabras, {a}. Mejor llevarnos en paz.",
			"Me alegra oír eso, {a}. Borrón y cuenta nueva.",
			"Trato hecho, {a}. Dejemos las viejas rencillas atrás.",
		],
		"Leal": [
			"Hace falta valor para pedir disculpas, {a}. Aquí tienes mi mano.",
		],
		"Rencoroso": [
			"Está bien, {a}... lo dejaremos pasar por esta vez.",
		],
	},
	ACTION_FLIRT: {
		"default": [
			"Vas a hacer que me sonroje en mitad del pueblo, {a}...",
			"Yo también estaba esperando verte hoy, {a}.",
			"Contigo el tiempo se pasa volando, {a}.",
		],
		"Alegre": [
			"¡Ja, ja! Qué cosas dices, {a}... pero no dejes de decirlas.",
		],
		"Leal": [
			"Siempre tienes un hueco en mi día, {a}.",
		],
	},
	ACTION_AFFECTION: {
		"default": [
			"Y a mí contigo, {a}. Eres mi rincón favorito del valle.",
			"Ven aquí, {a}... qué suerte la nuestra de habernos encontrado.",
			"No cambiaría estas tardes contigo por nada del mundo, {a}.",
		],
		"Bondadoso": [
			"Siempre sabes cómo abrigarme el corazón, {a}.",
		],
		"Leal": [
			"Juntos en las buenas y en las malas, {a}.",
		],
	},
	ACTION_JEALOUSY: {
		"default": [
			"Estás viendo fantasmas donde no los hay, {a}, solo estábamos charlando.",
			"No me vengas con escenas en mitad de la calle, {a}.",
			"Si no confías en mí después de todo, {a}, tenemos un problema.",
		],
		"Pacífico": [
			"Cálmate, por favor, {a}... sabes que solo tengo ojos para ti.",
		],
		"Orgulloso": [
			"Yo hablo con quien quiero en este pueblo, {a}, no me controles.",
		],
		"Leal": [
			"Jamás te faltaría al respeto, {a}, te doy mi palabra.",
		],
	},
}

static func get_taste_label(topic_key: String) -> String:
	var clean := topic_key.strip_edges()
	return str(TASTE_LABELS.get(clean, clean.replace("_", " ")))

static func find_shared_like(profile_a: Dictionary, profile_b: Dictionary) -> String:
	var likes_a: Array = profile_a.get("likes", [])
	var likes_b: Array = profile_b.get("likes", [])
	for t in likes_a:
		if t in likes_b:
			return str(t)
	return ""

static func find_clashing_taste(profile_a: Dictionary, profile_b: Dictionary) -> String:
	var likes_a: Array = profile_a.get("likes", [])
	var dislikes_a: Array = profile_a.get("dislikes", [])
	var likes_b: Array = profile_b.get("likes", [])
	var dislikes_b: Array = profile_b.get("dislikes", [])
	for t in likes_a:
		if t in dislikes_b:
			return str(t)
	for t in likes_b:
		if t in dislikes_a:
			return str(t)
	return ""

static func _pick_from_pool(pool_by_trait: Dictionary, traits: Array, rng: RandomNumberGenerator = null) -> String:
	var candidates: Array[String] = []
	for tr in traits:
		var tr_str := str(tr)
		if pool_by_trait.has(tr_str):
			for line in pool_by_trait[tr_str]:
				candidates.append(str(line))
	if candidates.is_empty() or (_randf(rng) < 0.42 and pool_by_trait.has("default")):
		for line in pool_by_trait.get("default", []):
			candidates.append(str(line))
	if candidates.is_empty():
		return "..."
	var idx: int = _randi_range(rng, 0, candidates.size() - 1)
	return candidates[idx]

static func _randf(rng: RandomNumberGenerator = null) -> float:
	return rng.randf() if rng != null else randf()

static func _randi_range(rng: RandomNumberGenerator, low: int, high: int) -> int:
	if high <= low:
		return low
	return rng.randi_range(low, high) if rng != null else randi_range(low, high)

## Construye un intercambio de 2 turnos (line_a -> line_b) adaptado a los rasgos y gustos de ambos vecinos.
static func build_exchange(
	action_id: String,
	profile_a: Dictionary,
	name_a: String,
	profile_b: Dictionary,
	name_b: String,
	topic_key: String = "",
	rng: RandomNumberGenerator = null
) -> Dictionary:
	var act: String = action_id if ACTION_META.has(action_id) else ACTION_SMALL_TALK
	var meta: Dictionary = ACTION_META[act]
	var traits_a: Array = profile_a.get("personality", [])
	var traits_b: Array = profile_b.get("personality", [])

	var chosen_topic: String = topic_key
	if chosen_topic == "":
		if act == ACTION_SHARED_TASTE:
			chosen_topic = find_shared_like(profile_a, profile_b)
		elif act == ACTION_TASTE_CLASH:
			chosen_topic = find_clashing_taste(profile_a, profile_b)
	if chosen_topic == "":
		var likes_a: Array = profile_a.get("likes", [])
		chosen_topic = str(likes_a[0]) if not likes_a.is_empty() else "pan_caliente"

	var topic_label: String = get_taste_label(chosen_topic)
	var raw_a: String = _pick_from_pool(OPENERS_BY_ACTION.get(act, OPENERS_BY_ACTION[ACTION_SMALL_TALK]), traits_a, rng)
	var raw_b: String = _pick_from_pool(REPLIES_BY_ACTION.get(act, REPLIES_BY_ACTION[ACTION_SMALL_TALK]), traits_b, rng)

	var line_a: String = raw_a.replace("{a}", name_a).replace("{b}", name_b).replace("{topic}", topic_label)
	var line_b: String = raw_b.replace("{a}", name_a).replace("{b}", name_b).replace("{topic}", topic_label)

	var note_tmpl: String = str(meta.get("note", "Charlaron en el pueblo"))
	var note_str: String = (note_tmpl % topic_label) if "%s" in note_tmpl else note_tmpl

	return {
		"action_id": act,
		"label": str(meta.get("label", "Charla")),
		"icon": str(meta.get("icon", "💬")),
		"color": meta.get("color", Color.WHITE),
		"topic": chosen_topic,
		"topic_label": topic_label,
		"line_a": line_a,
		"line_b": line_b,
		"note": note_str,
	}
