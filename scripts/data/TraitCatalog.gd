@tool
extends RefCounted

## T1: Catálogo central de rasgos de personalidad y sus «tendencias».
## Cada rasgo sube o baja unas pocas tendencias; la tendencia de un vecino es la suma de las de sus rasgos
## (0 = normal, positivo = más, negativo = menos). Los sistemas consultan la tendencia, no rasgos sueltos.
## Hoy contiene los 18 rasgos de `PersonProfile.PERSONALITY_TRAITS`; el borrador hasta 100 está en `docs/RASGOS_BORRADOR.md`.

## Tendencias disponibles (de momento solo "malice" se usa en el juego; el resto se conectará en T4).
const TENDENCIES: Dictionary = {
	"malice": "Malicia: hablar mal de otros a sus espaldas",
	"grudge": "Rencor: cuánto le dura una enemistad",
	"gossip": "Chismorreo: contar novedades",
	"aggression": "Agresividad: llegar a las manos",
	"honesty": "Honestidad: decir la verdad, rechazar sobornos",
	"trust": "Confianza: creerse lo que le cuentan",
	"diligence": "Laboriosidad",
	"generosity": "Generosidad",
	"sociability": "Sociabilidad: buscar compañía",
}

## id del rasgo (el mismo texto que se guarda en las partidas) -> descripción y tendencias.
const TRAITS: Dictionary = {
	"Leal": {"desc": "Defiende a los suyos y no les da la espalda.", "tend": {"malice": -0.6, "trust": 0.3, "honesty": 0.3}},
	"Honrado": {"desc": "Dice la verdad aunque le cueste.", "tend": {"malice": -0.6, "honesty": 1.0}},
	"Pacífico": {"desc": "Evita los conflictos.", "tend": {"malice": -0.5, "aggression": -1.0, "grudge": -0.5}},
	"Bondadoso": {"desc": "Piensa bien de los demás y ayuda sin pedir nada.", "tend": {"malice": -1.0, "generosity": 1.0, "aggression": -0.3}},
	"Alegre": {"desc": "Optimista y fácil de tratar.", "tend": {"malice": -0.3, "sociability": 0.6, "grudge": -0.4}},
	"Curioso": {"desc": "Quiere saberlo todo.", "tend": {"gossip": 0.6, "sociability": 0.3}},
	"Trabajador": {"desc": "No para quieto.", "tend": {"diligence": 1.0}},
	"Paciente": {"desc": "No pierde los nervios.", "tend": {"malice": -0.3, "aggression": -0.5, "grudge": -0.4}},
	"Valiente": {"desc": "No se arruga ante el peligro.", "tend": {"aggression": 0.5}},
	"Orgulloso": {"desc": "Le cuesta reconocer un error.", "tend": {"malice": 0.3, "grudge": 0.5, "aggression": 0.3}},
	"Desconfiado": {"desc": "Sospecha de todo el mundo.", "tend": {"malice": 0.2, "trust": -1.0}},
	"Celoso": {"desc": "Le corroe lo que tienen los demás.", "tend": {"malice": 0.8, "grudge": 0.4}},
	"Rencoroso": {"desc": "Nunca olvida una ofensa.", "tend": {"malice": 1.0, "grudge": 1.0}},
	"Codicioso": {"desc": "Todo lo mide en oro.", "tend": {"malice": 0.4, "honesty": -0.5, "generosity": -1.0}},
	"Frío": {"desc": "Distante; los sentimientos le estorban.", "tend": {"malice": 0.3, "sociability": -0.6, "gossip": -0.4}},
	"Tahúr": {"desc": "Vive del juego y de las apuestas.", "tend": {"malice": 0.2, "honesty": -0.6}},
	"Noctámbulo": {"desc": "Hace su vida de noche.", "tend": {}},
	"Chismoso": {"desc": "No sabe guardar un secreto.", "tend": {"malice": 0.6, "gossip": 1.0}},
}

## T2 (preparado, sin conectar aún a PersonProfile): ejes de opuestos. Un vecino nunca tiene dos rasgos del mismo eje.
## De momento reproduce los pares de `PersonProfile.OPPOSITE_TRAITS`; con la lista de 100 cada rasgo llevará su eje.
const AXES: Dictionary = {
	"Leal": "lealtad", "Tahúr": "lealtad",
	"Honrado": "honradez", "Codicioso": "honradez",
	"Pacífico": "perdon", "Rencoroso": "perdon",
	"Bondadoso": "calidez", "Frío": "calidez",
	"Alegre": "animo", "Desconfiado": "animo",
	"Paciente": "paciencia", "Celoso": "paciencia",
}
## Rasgos raros (como mucho `max_rare` por vecino). Vacío hasta T2.
const RARE: Array[String] = []

static func axis_of(trait_id: String) -> String:
	return str(AXES.get(trait_id, ""))

static func conflicts(a: String, b: String) -> bool:
	if a == b:
		return true
	var ax: String = axis_of(a)
	return ax != "" and ax == axis_of(b)

static func conflicts_with_any(trait_id: String, traits: Array) -> bool:
	for t in traits:
		if conflicts(trait_id, str(t)):
			return true
	return false

## Reparte hasta `count` rasgos sin choques de eje y con como mucho `max_rare` raros.
## `keep`: rasgos que ya tiene y se conservan (para completar partidas guardadas). `pool`: candidatos (todos por defecto).
## Con la misma semilla en `rng` el resultado es siempre el mismo.
static func roll_traits(rng: RandomNumberGenerator, count: int, keep: Array = [], pool: Array = [], max_rare: int = 1) -> Array[String]:
	var res: Array[String] = []
	var rare_n: int = 0
	for t in keep:
		var ts: String = str(t)
		if res.size() < count and not conflicts_with_any(ts, res):
			res.append(ts)
			if ts in RARE:
				rare_n += 1
	var cands: Array = (pool if not pool.is_empty() else TRAITS.keys()).duplicate()
	cands.sort() # Orden fijo antes de barajar con la semilla
	for i in range(cands.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = cands[i]
		cands[i] = cands[j]
		cands[j] = tmp
	for c in cands:
		if res.size() >= count:
			break
		var cs: String = str(c)
		if conflicts_with_any(cs, res) or (cs in RARE and rare_n >= max_rare):
			continue
		res.append(cs)
		if cs in RARE:
			rare_n += 1
	return res

static func has_trait_id(trait_id: String) -> bool:
	return TRAITS.has(trait_id)

static func describe(trait_id: String) -> String:
	return str((TRAITS.get(trait_id, {}) as Dictionary).get("desc", ""))

## Suma de una tendencia para una lista de rasgos (los rasgos desconocidos no cuentan).
static func tendency(traits: Array, key: String) -> float:
	var total: float = 0.0
	for t in traits:
		total += float(((TRAITS.get(str(t), {}) as Dictionary).get("tend", {}) as Dictionary).get(key, 0.0))
	return total

## Tendencia de un vecino (0 si no tiene perfil).
static func npc_tendency(npc: Object, key: String) -> float:
	if npc == null or not ("person_profile" in npc) or npc.person_profile == null:
		return 0.0
	return tendency(npc.person_profile.personality, key)
