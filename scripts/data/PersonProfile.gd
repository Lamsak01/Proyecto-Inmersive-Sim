extends RefCounted

## Ficha social de un habitante del valle (fijo o generado proceduralmente).
## Cargada mediante preload("res://scripts/data/PersonProfile.gd") para evitar fallos de caché de class_name en modo headless.

const AGE_GROUP_YOUNG := "young"   # 18–29
const AGE_GROUP_ADULT := "adult"   # 30–49
const AGE_GROUP_SENIOR := "senior" # 50+

const ROMANCE_SINGLE := "single"
const ROMANCE_PARTNERED := "partnered"
const ROMANCE_WIDOWED := "widowed"

## Catálogo de rasgos personales (compatibles con la evaluación policial de VillageManager).
const PERSONALITY_TRAITS: Array[String] = [
	"Leal", "Honrado", "Pacífico", "Bondadoso", "Alegre", "Curioso",
	"Trabajador", "Paciente", "Valiente", "Orgulloso", "Desconfiado",
	"Celoso", "Rencoroso", "Codicioso", "Frío", "Tahúr", "Noctámbulo", "Chismoso"
]

## Pares de rasgos opuestos que no deben coincidir en la misma persona y restan compatibilidad.
const OPPOSITE_TRAITS: Dictionary = {
	"Leal": "Tahúr", "Tahúr": "Leal",
	"Honrado": "Codicioso", "Codicioso": "Honrado",
	"Pacífico": "Rencoroso", "Rencoroso": "Pacífico",
	"Bondadoso": "Frío", "Frío": "Bondadoso",
	"Alegre": "Desconfiado", "Desconfiado": "Alegre",
	"Paciente": "Celoso", "Celoso": "Paciente",
}

## Catálogo de gustos y disgustos (comidas, oficios y aficiones del valle).
const TASTE_TOPICS: Array[String] = [
	"pescado", "carne_asada", "pan_caliente", "estofado", "hierbas",
	"forja", "carpinteria", "caza", "pesca", "cartas",
	"historias", "silencio", "lluvia", "musica", "reliquias", "animales"
]

var person_id: String = ""
var gender: String = "M"          # "M" o "F"
var orientation: String = "H"     # "H" (heterosexual por ahora; previsto para ampliar)
var age: int = 30
var personality: Array[String] = [] # 3 rasgos de PERSONALITY_TRAITS
var likes: Array[String] = []       # 2 gustos de TASTE_TOPICS
var dislikes: Array[String] = []    # 1 disgusto de TASTE_TOPICS
var favorite_item: String = "bread"
var romance_status: String = ROMANCE_SINGLE
var partner_id: String = ""

func get_age_group() -> String:
	return age_group_for(age)

static func age_group_for(age_val: int) -> String:
	if age_val < 30:
		return AGE_GROUP_YOUNG
	elif age_val < 50:
		return AGE_GROUP_ADULT
	return AGE_GROUP_SENIOR

static func from_dict(d: Dictionary):
	var script_ref: Script = load("res://scripts/data/PersonProfile.gd")
	var p = script_ref.new()
	p.person_id = str(d.get("person_id", d.get("id", "")))
	p.gender = str(d.get("gender", "M"))
	p.orientation = str(d.get("orientation", "H"))
	p.age = int(d.get("age", 30))
	p.personality.clear()
	for t in d.get("personality", []):
		p.personality.append(str(t))
	p.likes.clear()
	for l in d.get("likes", []):
		p.likes.append(str(l))
	p.dislikes.clear()
	for dl in d.get("dislikes", []):
		p.dislikes.append(str(dl))
	p.favorite_item = str(d.get("favorite_item", "bread"))
	p.romance_status = str(d.get("romance_status", ROMANCE_SINGLE))
	p.partner_id = str(d.get("partner_id", ""))
	return p

func to_dict() -> Dictionary:
	return {
		"person_id": person_id,
		"gender": gender,
		"orientation": orientation,
		"age": age,
		"age_group": get_age_group(),
		"personality": personality.duplicate(),
		"likes": likes.duplicate(),
		"dislikes": dislikes.duplicate(),
		"favorite_item": favorite_item,
		"romance_status": romance_status,
		"partner_id": partner_id,
	}

## Construye una ficha determinista a partir del nombre cuando un NPC aún no está en la tabla fija (puente hasta B0.3).
static func make_fallback_for_name(npc_name_str: String):
	var clean := npc_name_str.strip_edges()
	var h: int = abs(clean.hash())
	var is_fem: bool = clean.ends_with("a") or clean.begins_with("Dra.") or clean.begins_with("Comisaria") or clean.begins_with("Inspectora")
	var traits_picked: Array[String] = []
	var idx: int = h % PERSONALITY_TRAITS.size()
	var step: int = 5
	while traits_picked.size() < 3:
		var cand: String = PERSONALITY_TRAITS[idx % PERSONALITY_TRAITS.size()]
		var opp: String = str(OPPOSITE_TRAITS.get(cand, ""))
		if not (cand in traits_picked) and (opp == "" or not (opp in traits_picked)):
			traits_picked.append(cand)
		idx += step
		step += 1
	var l1: String = TASTE_TOPICS[h % TASTE_TOPICS.size()]
	var l2: String = TASTE_TOPICS[(h + 5) % TASTE_TOPICS.size()]
	var dl1: String = TASTE_TOPICS[(h + 11) % TASTE_TOPICS.size()]
	var fav_pool: Array[String] = ["bread", "cooked_meat", "roasted_chicken", "country_stew", "cooked_fish"]
	var slug: String = clean.to_lower().replace(" ", "_").replace(".", "")
	return from_dict({
		"person_id": "npc_" + slug,
		"gender": "F" if is_fem else "M",
		"orientation": "H",
		"age": 22 + (h % 34),
		"personality": traits_picked,
		"likes": [l1, l2],
		"dislikes": [dl1],
		"favorite_item": fav_pool[h % fav_pool.size()],
		"romance_status": ROMANCE_SINGLE,
		"partner_id": "",
	})
