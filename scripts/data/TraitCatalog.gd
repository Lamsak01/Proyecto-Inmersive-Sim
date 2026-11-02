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
