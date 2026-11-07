extends RefCounted

## Ficha social de un habitante del valle (fijo o generado proceduralmente).
## Cargada mediante preload("res://scripts/data/PersonProfile.gd") para evitar fallos de caché de class_name en modo headless.

const AGE_GROUP_YOUNG := "young"   # 18–29
const AGE_GROUP_ADULT := "adult"   # 30–49
const AGE_GROUP_SENIOR := "senior" # 50+

const ROMANCE_SINGLE := "single"
const ROMANCE_PARTNERED := "partnered"
const ROMANCE_WIDOWED := "widowed"

## T2: los rasgos viven en `TraitCatalog.gd` (140, con ejes de opuestos). Cada persona tiene 6.
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

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
var personality: Array[String] = [] # 6 rasgos de TraitCatalog
var likes: Array[String] = []       # 2 gustos de TASTE_TOPICS
var dislikes: Array[String] = []    # 1 disgusto de TASTE_TOPICS
var favorite_item: String = "bread"
var romance_status: String = ROMANCE_SINGLE
var partner_id: String = ""
var bereavement_days_left: int = 0
var deceased_partner_name: String = ""

func start_bereavement(dead_name: String, days: int = 5) -> void:
	romance_status = ROMANCE_WIDOWED
	partner_id = ""
	bereavement_days_left = maxi(1, days)
	deceased_partner_name = dead_name.strip_edges()

## Descuenta 1 día de luto. Cuando llega a 0, la persona supera el duelo agudo (`romance_status = ROMANCE_SINGLE` conservando `deceased_partner_name`). Devuelve true si hoy terminó el luto.
func tick_bereavement_day() -> bool:
	if bereavement_days_left <= 0:
		return false
	bereavement_days_left = maxi(0, bereavement_days_left - 1)
	if bereavement_days_left == 0 and romance_status == ROMANCE_WIDOWED:
		romance_status = ROMANCE_SINGLE
		return true
	return false

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
	p.complete_personality()
	p.likes.clear()
	for l in d.get("likes", []):
		p.likes.append(str(l))
	p.dislikes.clear()
	for dl in d.get("dislikes", []):
		p.dislikes.append(str(dl))
	p.favorite_item = str(d.get("favorite_item", "bread"))
	p.romance_status = str(d.get("romance_status", ROMANCE_SINGLE))
	p.partner_id = str(d.get("partner_id", ""))
	p.bereavement_days_left = int(d.get("bereavement_days_left", 0))
	p.deceased_partner_name = str(d.get("deceased_partner_name", ""))
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
		"bereavement_days_left": bereavement_days_left,
		"deceased_partner_name": deceased_partner_name,
	}

## Construye una ficha determinista a partir del nombre cuando un NPC aún no está en la tabla fija (puente hasta B0.3).
## T2: completa hasta 6 rasgos (fichas fijas de 3 y partidas antiguas). Determinista: misma persona, mismos rasgos.
func complete_personality() -> void:
	if personality.size() >= TraitCatalog.TRAITS_PER_PERSON:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(("traits:" + person_id + ":" + ",".join(personality)).hash())
	var full: Array[String] = TraitCatalog.roll_balanced(rng, personality)
	# Conserva siempre los que ya tenía, aunque choquen entre sí (no se pierde nada de la partida)
	for t in personality:
		if not (t in full):
			full.push_front(t)
	personality.assign(full)

static func make_fallback_for_name(npc_name_str: String):
	var clean := npc_name_str.strip_edges()
	var h: int = abs(clean.hash())
	var is_fem: bool = clean.ends_with("a") or clean.begins_with("Dra.") or clean.begins_with("Comisaria") or clean.begins_with("Inspectora")
	var fb_rng := RandomNumberGenerator.new()
	fb_rng.seed = h
	var traits_picked: Array[String] = TraitCatalog.roll_balanced(fb_rng)
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

const NPCNames = preload("res://scripts/data/NPCNames.gd")

## Rangos de edad (Vector2i(min, max)), rasgos afines, gustos afines y plato/objeto favorito según el oficio (int de VillageNPC.TradeRole).
const ROLE_GENERATION_HINTS: Dictionary = {
	0: {"age": Vector2i(20, 38), "traits": ["Curioso", "Alegre", "Tahúr", "Noctámbulo", "Valiente"], "likes": ["historias", "cartas", "reliquias", "musica"], "fav": "bread"}, # UNEMPLOYED
	1: {"age": Vector2i(19, 36), "traits": ["Leal", "Paciente", "Curioso", "Trabajador"], "likes": ["musica", "animales", "historias"], "fav": "bread"}, # FAMILY_MEMBER
	2: {"age": Vector2i(28, 52), "traits": ["Alegre", "Trabajador", "Chismoso", "Orgulloso"], "likes": ["estofado", "pan_caliente", "cartas", "historias"], "fav": "roasted_chicken"}, # INNKEEPER
	3: {"age": Vector2i(26, 50), "traits": ["Valiente", "Trabajador", "Desconfiado", "Orgulloso"], "likes": ["caza", "carne_asada", "animales"], "fav": "fox_pelt"}, # BUTCHER
	4: {"age": Vector2i(28, 56), "traits": ["Trabajador", "Orgulloso", "Honrado", "Paciente"], "likes": ["forja", "carne_asada", "estofado"], "fav": "iron_ore"}, # BLACKSMITH
	5: {"age": Vector2i(26, 54), "traits": ["Trabajador", "Paciente", "Honrado", "Curioso"], "likes": ["carpinteria", "estofado", "silencio"], "fav": "wood"}, # CARPENTER
	6: {"age": Vector2i(24, 52), "traits": ["Pacífico", "Bondadoso", "Paciente", "Curioso"], "likes": ["hierbas", "lluvia", "animales"], "fav": "herbs"}, # HERBALIST
	7: {"age": Vector2i(25, 56), "traits": ["Paciente", "Alegre", "Bondadoso", "Trabajador"], "likes": ["pesca", "pescado", "historias"], "fav": "night_catfish"}, # FISHMONGER
	8: {"age": Vector2i(30, 58), "traits": ["Curioso", "Paciente", "Honrado", "Frío"], "likes": ["hierbas", "silencio", "reliquias"], "fav": "surgical_kit"}, # DOCTOR
	9: {"age": Vector2i(34, 58), "traits": ["Honrado", "Valiente", "Desconfiado", "Frío"], "likes": ["carne_asada", "silencio", "caza"], "fav": "cooked_meat"}, # SHERIFF
	10: {"age": Vector2i(20, 35), "traits": ["Leal", "Valiente", "Honrado", "Trabajador"], "likes": ["pan_caliente", "caza", "animales"], "fav": "bread"}, # GUARD
	26: {"age": Vector2i(19, 36), "traits": ["Alegre", "Trabajador", "Chismoso", "Paciente"], "likes": ["estofado", "pan_caliente", "musica", "historias"], "fav": "country_stew"}, # WAITER
}

## Elige género ("F" o "M") equilibrando la proporción actual de residentes vivos.
static func pick_balanced_gender(rng: RandomNumberGenerator, living_females: int, living_males: int) -> String:
	var fem_prob: float = 0.50
	if living_females < living_males:
		var diff: int = living_males - living_females
		fem_prob = clampf(0.58 + float(diff) * 0.05, 0.58, 0.78)
	elif living_females > living_males:
		var diff2: int = living_females - living_males
		fem_prob = clampf(0.42 - float(diff2) * 0.05, 0.22, 0.42)
	return "F" if rng.randf() < fem_prob else "M"

## Genera un vecino nuevo completo: devuelve {"profile": PersonProfile, "first_name": String, "surname": String, "full_name": String}.
## Actualiza in-place `used_first_names` y `used_ids` para garantizar que jamás se repitan.
static func generate_newcomer(
	role_id: int,
	counter: int,
	rng: RandomNumberGenerator,
	used_first_names: Array,
	used_ids: Dictionary,
	living_females: int = 6,
	living_males: int = 11
) -> Dictionary:
	var g: String = pick_balanced_gender(rng, living_females, living_males)
	var name_info: Dictionary = NPCNames.make_person_name(g, rng, used_first_names)
	var first_nm: String = str(name_info["first"])
	var full_nm: String = str(name_info["full"])
	used_first_names.append(first_nm)

	var slug: String = first_nm.to_lower().replace(" ", "_")
	var pid: String = "npc_%d_%s" % [counter, slug]
	while used_ids.has(pid):
		counter += 1
		pid = "npc_%d_%s" % [counter, slug]
	used_ids[pid] = true

	var hint: Dictionary = ROLE_GENERATION_HINTS.get(role_id, ROLE_GENERATION_HINTS[0])
	var age_range: Vector2i = hint.get("age", Vector2i(22, 48))
	var age_val: int = rng.randi_range(age_range.x, age_range.y)

	# 6 rasgos: 1 afín al oficio + el resto repartidos con equilibrio (sin opuestos, como mucho 1 raro)
	var role_keep: Array = []
	var role_traits: Array = hint.get("traits", [])
	if not role_traits.is_empty():
		role_keep.append(str(role_traits[rng.randi_range(0, role_traits.size() - 1)]))
	var traits_picked: Array[String] = TraitCatalog.roll_balanced(rng, role_keep)

	# 2 gustos y 1 disgusto sin solaparse
	var likes_picked: Array[String] = []
	var role_likes: Array = hint.get("likes", [])
	if not role_likes.is_empty():
		likes_picked.append(str(role_likes[rng.randi_range(0, role_likes.size() - 1)]))
	while likes_picked.size() < 2:
		var l_cand: String = TASTE_TOPICS[rng.randi_range(0, TASTE_TOPICS.size() - 1)]
		if not (l_cand in likes_picked):
			likes_picked.append(l_cand)
	var dislike_picked: String = "silencio"
	for _i in range(30):
		var dl_cand: String = TASTE_TOPICS[rng.randi_range(0, TASTE_TOPICS.size() - 1)]
		if not (dl_cand in likes_picked):
			dislike_picked = dl_cand
			break

	var fav_pool: Array[String] = ["bread", "cooked_meat", "roasted_chicken", "country_stew", "cooked_fish"]
	var fav_item: String = str(hint.get("fav", "bread"))
	if role_id in [0, 1]:
		fav_item = fav_pool[rng.randi_range(0, fav_pool.size() - 1)]

	var prof = from_dict({
		"person_id": pid,
		"gender": g,
		"orientation": "H",
		"age": age_val,
		"personality": traits_picked,
		"likes": likes_picked,
		"dislikes": [dislike_picked],
		"favorite_item": fav_item,
		"romance_status": ROMANCE_SINGLE,
		"partner_id": "",
	})
	return {
		"profile": prof,
		"first_name": first_nm,
		"surname": str(name_info["last"]),
		"full_name": full_nm,
	}
