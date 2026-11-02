extends RefCounted

## Director Social central (B0.7): gestiona hasta un máximo estricto de escenas simultáneas (`max_concurrent_scenes = 3`),
## mantiene las 4 medidas de relación por par (`affinity`, `familiarity`, `spark`, `tension`) y concentra todos los diales
## de ajuste en una única tabla (`DIALS`) para la calibración automática (B0.9).
## Cargado mediante preload("res://scripts/systems/SocialDirector.gd").

const PersonProfile = preload("res://scripts/data/PersonProfile.gd")
const SocialDialogueData = preload("res://scripts/data/SocialDialogueData.gd")

## Tabla única de diales de calibración.
const DIALS: Dictionary = {
	"max_concurrent_scenes": 3,
	"tick_interval_sec": 4.0,
	"interaction_radius": 85.0,
	"default_scene_duration_sec": 6.0,
	"drama_cooldown_days": 2,
	"max_fights_per_pair": 2,
	# Enfriamiento diario cuando dos vecinos no tienen contacto ese día
	"decay_familiarity_no_contact": 1,
	"decay_spark_no_contact": 1,
	"decay_tension_no_contact": 2,
	# Pesos de compatibilidad (sobre 100)
	"compat_base": 45,
	"compat_age_close_bonus": 15,     # <= 8 años de diferencia
	"compat_age_far_penalty": -18,    # >= 18 años de diferencia
	"compat_shared_like_bonus": 14,
	"compat_like_vs_dislike_penalty": -16,
	"compat_shared_trait_bonus": 10,
	"compat_opposite_trait_penalty": -22,
	# Umbrales y probabilidades diarias para parejas y peleas (usados en B0.9 y Fases 3-4)
	"daily_interactions_per_day": 22,
	"max_new_couples_per_60d": 3,
	"max_total_fights_per_60d": 5,
	"affinity_drift_neutral_target": 12,
	"spark_min_affinity": 16,
	"spark_min_familiarity": 14,
	"spark_daily_gain_max": 8,
	"stage_advance_base_chance": 0.36,
	"fight_tension_threshold": 36,
	"fight_daily_base_chance": 0.38,
	# B2.1: Pasar tiempo juntos (quedadas entre amigos / parejas) y evitar rivales
	"max_concurrent_hangouts": 2,
	"hangout_min_affinity": 25,
	"hangout_min_spark": 18,
	"hangout_social_hours": [12, 18, 19, 20, 21],  # Comida (12h) y tarde libre (18-21h)
	"hangout_max_per_person_per_day": 1,
	"hangout_travel_timeout_sec": 60.0,
	"hangout_together_sec": 45.0,
	"hangout_bonus_affinity_min": 3,
	"hangout_bonus_affinity_max": 6,
	"hangout_bonus_familiarity_min": 4,
	"hangout_bonus_familiarity_max": 7,
	"hangout_bonus_spark_min": 2,
	"hangout_bonus_spark_max": 4,
	"hangout_tension_relief_min": 3,
	"hangout_tension_relief_max": 6,
	"avoid_affinity_threshold": -25,
	"avoid_tension_threshold": 30,
	# B3.1: Chispa y etapas en vivo (solo avanzan si hubo contacto reciente; sin plazos ni cupos)
	"stage_spark_interest": 14,
	"stage_spark_flirt": 28,
	"stage_spark_dating": 44,
	"stage_spark_couple": 60,
	"stage_couple_min_affinity": 24,
	"live_stage_advance_chance": 0.24,   # Probabilidad diaria base (x compatibilidad/50)
	"live_stage_contact_window_days": 1, # Debe haber contacto hoy o ayer para avanzar
	"stage_fizzle_spark": 8,             # Si la chispa cae por debajo, el cortejo se apaga
	"romance_min_compat": 40,
	"spark_daily_gain_cap": 10,          # Máximo de chispa que un par puede ganar en un mismo día (charlas + quedadas)
	# B3.3: Celos, rupturas y reconciliación
	"jealousy_tension_gain_base": 14,
	"jealousy_trait_bonus": 10,
	"jealousy_rival_tension_gain": 12,
	"jealousy_base_chance": 0.65,
	"breakup_min_tension": 62,
	"breakup_max_affinity": 12,
	"breakup_daily_chance": 0.28,
	"reconcile_ex_min_spark": 35,
	"reconcile_ex_max_tension": 18,
	"reconcile_ex_chance": 0.35,
}

const STAGE_NONE := "none"
const STAGE_INTEREST := "interest"
const STAGE_FLIRT := "flirt"
const STAGE_DATING := "dating"
const STAGE_COUPLE := "couple"

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var dials: Dictionary = DIALS.duplicate(true)
var pair_metrics: Dictionary = {}      # "idA|idB" -> {affinity, familiarity, spark, tension, stage, fights_count, last_contact_day}
var active_scenes: Array[Dictionary] = [] # [{id, type, actor_a_id, actor_b_id, remaining_sec}]
var last_drama_day: int = -10
var total_new_couples_formed: int = 0
var total_fights_triggered: int = 0
var _tick_accum: float = 0.0
var _scene_seq: int = 0
# B2.1: Quedadas activas (transitorias, no se guardan) y contador diario por persona (se guarda)
const HANGOUT_PHASE_TRAVEL := "travel"
const HANGOUT_PHASE_TOGETHER := "together"
var active_hangouts: Array[Dictionary] = []   # [{id, actor_a_id, actor_b_id, spot_id, spot_kind, spot_pos, phase, arrived_a, arrived_b, travel_remaining, together_remaining, started_day}]
var finished_hangouts: Array[Dictionary] = [] # Resultados pendientes de recoger con pop_finished_hangouts()
var hangout_day_counts: Dictionary = {}       # person_id -> {"day": int, "count": int}
var _hangout_seq: int = 0

func _init(seed_val: int = 20261101) -> void:
	rng.seed = seed_val

static func make_pair_key(id_a: String, id_b: String) -> String:
	var a: String = id_a.strip_edges()
	var b: String = id_b.strip_edges()
	if a == "" or b == "" or a == b:
		return ""
	return "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]

func get_pair_entry(id_a: String, id_b: String, initial_affinity: int = 0) -> Dictionary:
	var k: String = make_pair_key(id_a, id_b)
	if k == "":
		return {}
	if not pair_metrics.has(k):
		pair_metrics[k] = {
			"affinity": clampi(initial_affinity, -100, 100),
			"familiarity": clampi(maxi(0, initial_affinity / 2), 0, 100),
			"spark": 0,
			"tension": clampi(maxi(0, -initial_affinity / 2), 0, 100),
			"stage": STAGE_NONE,
			"fights_count": 0,
			"last_contact_day": 1,
		}
	return pair_metrics[k]

func set_pair_metrics(id_a: String, id_b: String, affinity_val: int, familiarity_val: int, spark_val: int, tension_val: int, stage_str: String = STAGE_NONE) -> void:
	var entry: Dictionary = get_pair_entry(id_a, id_b, affinity_val)
	if entry.is_empty():
		return
	entry["affinity"] = clampi(affinity_val, -100, 100)
	entry["familiarity"] = clampi(familiarity_val, 0, 100)
	entry["spark"] = clampi(spark_val, 0, 100)
	entry["tension"] = clampi(tension_val, 0, 100)
	entry["stage"] = stage_str

func purge_deceased(dead_id: String) -> void:
	if dead_id == "":
		return
	var to_remove: Array[String] = []
	for k in pair_metrics.keys():
		var parts: PackedStringArray = str(k).split("|")
		if parts.size() == 2 and (parts[0] == dead_id or parts[1] == dead_id):
			to_remove.append(str(k))
	for k_rem in to_remove:
		pair_metrics.erase(k_rem)
	for i in range(active_scenes.size() - 1, -1, -1):
		var sc: Dictionary = active_scenes[i]
		if str(sc.get("actor_a_id", "")) == dead_id or str(sc.get("actor_b_id", "")) == dead_id:
			active_scenes.remove_at(i)
	for j in range(active_hangouts.size() - 1, -1, -1):
		var hg: Dictionary = active_hangouts[j]
		if str(hg.get("actor_a_id", "")) == dead_id or str(hg.get("actor_b_id", "")) == dead_id:
			active_hangouts.remove_at(j)
	hangout_day_counts.erase(dead_id)

## Calcula la compatibilidad romántica (0..100) entre dos fichas. Devuelve 0 si son del mismo hogar/familia o mismo género con orientación heterosexual.
func compute_compatibility(prof_a, prof_b, same_family: bool = false) -> int:
	if prof_a == null or prof_b == null or same_family:
		return 0
	if str(prof_a.person_id) == str(prof_b.person_id):
		return 0
	# Por ahora todos heterosexuales ("H"): requiere géneros distintos
	if str(prof_a.orientation) == "H" or str(prof_b.orientation) == "H":
		if str(prof_a.gender) == str(prof_b.gender):
			return 0
	var score: int = int(dials.get("compat_base", 45))
	var age_diff: int = abs(int(prof_a.age) - int(prof_b.age))
	if age_diff <= 8:
		score += int(dials.get("compat_age_close_bonus", 15))
	elif age_diff >= 18:
		score += int(dials.get("compat_age_far_penalty", -18))
	for lk in prof_a.likes:
		if lk in prof_b.likes:
			score += int(dials.get("compat_shared_like_bonus", 14))
		if lk in prof_b.dislikes:
			score += int(dials.get("compat_like_vs_dislike_penalty", -16))
	for dl in prof_a.dislikes:
		if dl in prof_b.likes:
			score += int(dials.get("compat_like_vs_dislike_penalty", -16))
	for tr in prof_a.personality:
		if tr in prof_b.personality:
			score += int(dials.get("compat_shared_trait_bonus", 10))
		var opp: String = str(PersonProfile.OPPOSITE_TRAITS.get(tr, ""))
		if opp != "" and (opp in prof_b.personality):
			score += int(dials.get("compat_opposite_trait_penalty", -22))
	return clampi(score, 0, 100)

func is_person_in_scene(person_id: String) -> bool:
	for sc in active_scenes:
		if str(sc.get("actor_a_id", "")) == person_id or str(sc.get("actor_b_id", "")) == person_id:
			return true
	return false

func can_start_scene(actor_a_id: String = "", actor_b_id: String = "") -> bool:
	var max_sc: int = int(dials.get("max_concurrent_scenes", 3))
	if active_scenes.size() >= max_sc:
		return false
	if actor_a_id != "" and is_person_in_scene(actor_a_id):
		return false
	if actor_b_id != "" and is_person_in_scene(actor_b_id):
		return false
	return true

func start_scene(scene_type: String, actor_a_id: String, actor_b_id: String, duration_sec: float = -1.0, current_day: int = 1) -> Dictionary:
	if actor_a_id == "" or actor_b_id == "" or actor_a_id == actor_b_id:
		return {}
	if not can_start_scene(actor_a_id, actor_b_id):
		return {}
	_scene_seq += 1
	var dur: float = duration_sec if duration_sec > 0.0 else float(dials.get("default_scene_duration_sec", 6.0))
	var sc: Dictionary = {
		"id": _scene_seq,
		"type": scene_type,
		"actor_a_id": actor_a_id,
		"actor_b_id": actor_b_id,
		"remaining_sec": dur,
	}
	active_scenes.append(sc)
	var pe: Dictionary = get_pair_entry(actor_a_id, actor_b_id)
	if not pe.is_empty():
		pe["last_contact_day"] = current_day
	return sc

func end_scene(scene_id: int) -> void:
	for i in range(active_scenes.size() - 1, -1, -1):
		if int(active_scenes[i].get("id", -1)) == scene_id:
			active_scenes.remove_at(i)
			return

## B1.2: Resuelve una conversación en vivo de 2 turnos entre dos vecinos respetando `max_concurrent_scenes = 3`.
## Actualiza las 4 métricas del par (`affinity`, `familiarity`, `spark`, `tension`) y devuelve las frases `line_a` y `line_b`.
func resolve_live_conversation(npc_a, npc_b, current_day: int = 1) -> Dictionary:
	if npc_a == null or npc_b == null or npc_a == npc_b:
		return {"allowed": false, "reason": "invalid_actors"}

	var prof_a = npc_a.get("person_profile")
	var prof_b = npc_b.get("person_profile")
	var name_a: String = str(npc_a.get("npc_name"))
	var name_b: String = str(npc_b.get("npc_name"))
	if prof_a == null:
		prof_a = PersonProfile.make_fallback_for_name(name_a if name_a != "" else "Vecino A")
	if prof_b == null:
		prof_b = PersonProfile.make_fallback_for_name(name_b if name_b != "" else "Vecino B")

	var id_a: String = str(prof_a.person_id)
	var id_b: String = str(prof_b.person_id)
	if not can_start_scene(id_a, id_b):
		return {"allowed": false, "reason": "max_scenes_or_busy"}

	var sc: Dictionary = start_scene("conversation", id_a, id_b, 3.2, current_day)
	if sc.is_empty():
		return {"allowed": false, "reason": "scene_rejected"}

	var fam_a: String = str(npc_a.get("family_id")) if "family_id" in npc_a else "none"
	var fam_b: String = str(npc_b.get("family_id")) if "family_id" in npc_b else "none"
	var same_fam: bool = (fam_a != "none" and fam_a != "" and fam_a != "family_police" and fam_a == fam_b)

	var cur_rel: int = 0
	if npc_a is Object and npc_a.has_method("get_relationship_with_npc"):
		cur_rel = int(npc_a.call("get_relationship_with_npc", id_b))
	else:
		cur_rel = int(get_pair_entry(id_a, id_b).get("affinity", 0))

	var pe: Dictionary = get_pair_entry(id_a, id_b, cur_rel)
	pe["last_contact_day"] = current_day
	pe["familiarity"] = clampi(int(pe.get("familiarity", 0)) + rng.randi_range(2, 4), 0, 100)

	var dict_a: Dictionary = prof_a.to_dict()
	var dict_b: Dictionary = prof_b.to_dict()
	var shared_like: String = SocialDialogueData.find_shared_like(dict_a, dict_b)
	var clash_topic: String = SocialDialogueData.find_clashing_taste(dict_a, dict_b)

	var action_id: String = SocialDialogueData.ACTION_SMALL_TALK
	var topic_used: String = ""
	var delta_rel: int = 0
	var roll: float = rng.randf()
	var pair_stage: String = str(pe.get("stage", STAGE_NONE))
	var is_couple_pair: bool = (pair_stage == STAGE_COUPLE) or (str(prof_a.partner_id) != "" and str(prof_a.partner_id) == id_b)
	var is_courting_pair: bool = not is_couple_pair and (pair_stage in [STAGE_INTEREST, STAGE_FLIRT, STAGE_DATING])

	if is_couple_pair and int(pe.get("tension", 0)) >= 28:
		var reconciliatory: bool = ("Pacífico" in prof_a.personality) or ("Leal" in prof_a.personality) or ("Bondadoso" in prof_a.personality)
		if reconciliatory and rng.randf() < 0.38:
			action_id = SocialDialogueData.ACTION_APOLOGY
			delta_rel = rng.randi_range(10, 18)
			pe["tension"] = clampi(int(pe.get("tension", 0)) - rng.randi_range(12, 20), 0, 100)
		elif rng.randf() < 0.65:
			action_id = SocialDialogueData.ACTION_JEALOUSY
			delta_rel = rng.randi_range(-12, -5)
			pe["tension"] = clampi(int(pe.get("tension", 0)) + rng.randi_range(6, 12), 0, 100)
		else:
			action_id = SocialDialogueData.ACTION_VENT
			delta_rel = rng.randi_range(4, 9)
			pe["tension"] = clampi(int(pe.get("tension", 0)) - rng.randi_range(6, 12), 0, 100)
	elif is_couple_pair and cur_rel > -10 and roll >= 0.08:
		if rng.randf() < 0.72:
			action_id = SocialDialogueData.ACTION_AFFECTION
		elif shared_like != "" and rng.randf() < 0.60:
			action_id = SocialDialogueData.ACTION_SHARED_TASTE
			topic_used = shared_like
		else:
			action_id = SocialDialogueData.ACTION_COMPLIMENT
		delta_rel = rng.randi_range(6, 12)
		pe["tension"] = clampi(int(pe.get("tension", 0)) - rng.randi_range(3, 6), 0, 100)
	elif is_courting_pair and cur_rel > -10 and roll >= 0.12:
		var flirt_prob: float = 0.50 if pair_stage == STAGE_INTEREST else 0.72
		if rng.randf() < flirt_prob:
			action_id = SocialDialogueData.ACTION_FLIRT
		elif shared_like != "" and rng.randf() < 0.55:
			action_id = SocialDialogueData.ACTION_SHARED_TASTE
			topic_used = shared_like
		else:
			action_id = SocialDialogueData.ACTION_COMPLIMENT
		delta_rel = rng.randi_range(8, 14)
		pe["tension"] = clampi(int(pe.get("tension", 0)) - rng.randi_range(2, 5), 0, 100)
	elif cur_rel <= -20:
		if roll < 0.32:
			action_id = SocialDialogueData.ACTION_APOLOGY
			delta_rel = rng.randi_range(18, 28)
			pe["tension"] = clampi(int(pe.get("tension", 0)) - rng.randi_range(8, 16), 0, 100)
		else:
			if clash_topic != "" and rng.randf() < 0.55:
				action_id = SocialDialogueData.ACTION_TASTE_CLASH
				topic_used = clash_topic
			else:
				action_id = SocialDialogueData.ACTION_FRICTION
			delta_rel = rng.randi_range(-10, -5)
			pe["tension"] = clampi(int(pe.get("tension", 0)) + rng.randi_range(6, 12), 0, 100)
	elif cur_rel >= 35:
		if not same_fam and roll < 0.14:
			if clash_topic != "" and rng.randf() < 0.55:
				action_id = SocialDialogueData.ACTION_TASTE_CLASH
				topic_used = clash_topic
			else:
				action_id = SocialDialogueData.ACTION_FRICTION
			delta_rel = rng.randi_range(-14, -8)
			pe["tension"] = clampi(int(pe.get("tension", 0)) + rng.randi_range(5, 10), 0, 100)
		else:
			if shared_like != "" and rng.randf() < 0.44:
				action_id = SocialDialogueData.ACTION_SHARED_TASTE
				topic_used = shared_like
			else:
				var friend_actions: Array[String] = [
					SocialDialogueData.ACTION_COMPLIMENT,
					SocialDialogueData.ACTION_JOKE,
					SocialDialogueData.ACTION_VENT,
					SocialDialogueData.ACTION_SMALL_TALK,
				]
				action_id = friend_actions[rng.randi_range(0, friend_actions.size() - 1)]
			delta_rel = rng.randi_range(6, 12)
			pe["tension"] = clampi(int(pe.get("tension", 0)) - rng.randi_range(2, 5), 0, 100)
	else:
		var pos_threshold: float = 0.72 + (0.08 if shared_like != "" else 0.0) - (0.08 if clash_topic != "" else 0.0)
		if roll < clampf(pos_threshold, 0.45, 0.88):
			if shared_like != "" and rng.randf() < 0.48:
				action_id = SocialDialogueData.ACTION_SHARED_TASTE
				topic_used = shared_like
			else:
				var neutral_actions: Array[String] = [
					SocialDialogueData.ACTION_SMALL_TALK,
					SocialDialogueData.ACTION_JOKE,
					SocialDialogueData.ACTION_VENT,
					SocialDialogueData.ACTION_COMPLIMENT,
				]
				action_id = neutral_actions[rng.randi_range(0, neutral_actions.size() - 1)]
			delta_rel = rng.randi_range(8, 15)
			pe["tension"] = clampi(int(pe.get("tension", 0)) - rng.randi_range(1, 4), 0, 100)
		else:
			if clash_topic != "" and rng.randf() < 0.60:
				action_id = SocialDialogueData.ACTION_TASTE_CLASH
				topic_used = clash_topic
			else:
				action_id = SocialDialogueData.ACTION_FRICTION
			delta_rel = rng.randi_range(-12, -6)
			pe["tension"] = clampi(int(pe.get("tension", 0)) + rng.randi_range(6, 12), 0, 100)

	pe["affinity"] = clampi(cur_rel + delta_rel, -100, 100)

	var rom_compat: int = compute_compatibility(prof_a, prof_b, same_fam)
	var both_single: bool = (str(prof_a.romance_status) == PersonProfile.ROMANCE_SINGLE and str(prof_b.romance_status) == PersonProfile.ROMANCE_SINGLE)
	if delta_rel > 0 and both_single and rom_compat >= 40 and int(pe["affinity"]) >= int(dials.get("spark_min_affinity", 14)) and int(pe["familiarity"]) >= int(dials.get("spark_min_familiarity", 12)):
		_add_spark_capped(pe, rng.randi_range(2, 5), current_day)

	var ex: Dictionary = SocialDialogueData.build_exchange(action_id, dict_a, name_a, dict_b, name_b, topic_used, rng)
	ex["allowed"] = true
	ex["scene_id"] = int(sc.get("id", 0))
	ex["stage"] = str(pe.get("stage", STAGE_NONE))
	ex["delta_rel"] = delta_rel
	ex["affinity"] = int(pe["affinity"])
	ex["familiarity"] = int(pe["familiarity"])
	ex["spark"] = int(pe["spark"])
	ex["tension"] = int(pe["tension"])
	return ex

func tick(delta: float, _vm: Node = null) -> void:
	for i in range(active_scenes.size() - 1, -1, -1):
		var rem: float = float(active_scenes[i].get("remaining_sec", 0.0)) - delta
		if rem <= 0.0:
			active_scenes.remove_at(i)
		else:
			active_scenes[i]["remaining_sec"] = rem
	_tick_hangouts(delta)
	_tick_accum += delta
	var interval: float = maxf(0.5, float(dials.get("tick_interval_sec", 4.0)))
	if _tick_accum < interval:
		return
	_tick_accum = 0.0

# ==============================================================================
# B2.1: PASAR TIEMPO JUNTOS — selección de compañero, punto de encuentro y gestión de quedadas
# ==============================================================================

## ¿Es hora libre/social? (comida y tarde tras el turno laboral 08-18h)
func is_social_hour(hour: int) -> bool:
	var hours: Array = dials.get("hangout_social_hours", [12, 18, 19, 20, 21])
	return hour in hours

## Los rivales se evitan: afinidad muy baja o tensión alta.
func should_avoid(id_a: String, id_b: String) -> bool:
	var k: String = make_pair_key(id_a, id_b)
	if k == "" or not pair_metrics.has(k):
		return false
	var pe: Dictionary = pair_metrics[k]
	return int(pe.get("affinity", 0)) <= int(dials.get("avoid_affinity_threshold", -25)) \
		or int(pe.get("tension", 0)) >= int(dials.get("avoid_tension_threshold", 30))

## Devuelve los ids de `candidate_ids` a los que `person_id` debería evitar.
func get_avoid_ids(person_id: String, candidate_ids: Array) -> Array[String]:
	var out: Array[String] = []
	for cid in candidate_ids:
		var c: String = str(cid)
		if c != person_id and should_avoid(person_id, c):
			out.append(c)
	return out

## Cuántas quedadas lleva hoy una persona.
func get_hangouts_today(person_id: String, current_day: int) -> int:
	var rec: Dictionary = hangout_day_counts.get(person_id, {})
	return int(rec.get("count", 0)) if int(rec.get("day", -1)) == current_day else 0

func _register_hangout_today(person_id: String, current_day: int) -> void:
	hangout_day_counts[person_id] = {"day": current_day, "count": get_hangouts_today(person_id, current_day) + 1}

## Puntuación de "ganas de quedar" de un par (-1 si no es elegible: rivales, poca relación o sin chispa).
func get_hangout_score(id_a: String, id_b: String) -> int:
	var k: String = make_pair_key(id_a, id_b)
	if k == "" or not pair_metrics.has(k) or should_avoid(id_a, id_b):
		return -1
	var pe: Dictionary = pair_metrics[k]
	var aff: int = int(pe.get("affinity", 0))
	var spk: int = int(pe.get("spark", 0))
	var stage: String = str(pe.get("stage", STAGE_NONE))
	var romantic: bool = stage in [STAGE_INTEREST, STAGE_FLIRT, STAGE_DATING, STAGE_COUPLE]
	if aff < int(dials.get("hangout_min_affinity", 25)) and spk < int(dials.get("hangout_min_spark", 18)) and not romantic:
		return -1
	var score: int = aff + int(float(spk) * 0.8)
	match stage:
		STAGE_COUPLE: score += 55
		STAGE_DATING: score += 38
		STAGE_FLIRT: score += 24
		STAGE_INTEREST: score += 12
	return maxi(1, score)

func is_person_in_hangout(person_id: String) -> bool:
	return not get_active_hangout_for(person_id).is_empty()

func get_active_hangout_for(person_id: String) -> Dictionary:
	for hg in active_hangouts:
		if str(hg.get("actor_a_id", "")) == person_id or str(hg.get("actor_b_id", "")) == person_id:
			return hg
	return {}

## Elige con quién quedar entre `candidate_ids` (amigos o vecinos con chispa, libres y sin cupo diario agotado).
## Selección ponderada por puntuación para que no salga siempre el mismo. Devuelve "" si nadie encaja.
func pick_hangout_partner(person_id: String, candidate_ids: Array, hour: int, current_day: int) -> String:
	if person_id == "" or not is_social_hour(hour):
		return ""
	var max_per_day: int = int(dials.get("hangout_max_per_person_per_day", 1))
	if is_person_in_hangout(person_id) or get_hangouts_today(person_id, current_day) >= max_per_day:
		return ""
	var pool: Array[String] = []
	var weights: Array[int] = []
	var total: int = 0
	for cid in candidate_ids:
		var c: String = str(cid)
		if c == "" or c == person_id or is_person_in_hangout(c) or get_hangouts_today(c, current_day) >= max_per_day:
			continue
		var sc: int = get_hangout_score(person_id, c)
		if sc <= 0:
			continue
		pool.append(c)
		weights.append(sc)
		total += sc
	if pool.is_empty():
		return ""
	var r: int = rng.randi_range(1, total)
	for i in range(pool.size()):
		r -= weights[i]
		if r <= 0:
			return pool[i]
	return pool[pool.size() - 1]

## Elige el punto de encuentro compartido entre los `spots` ofrecidos por el mundo: [{id, pos: Vector2, kind}].
## kinds: "tavern" (mejor por la tarde), "plaza"/"well" (mejor de día), "bench"/"campfire" (preferidos por parejas).
## Penaliza la distancia total de ambos y descarta los puntos ya ocupados por otra quedada.
func pick_shared_hangout_spot(spots: Array, pos_a: Vector2, pos_b: Vector2, hour: int, stage: String = STAGE_NONE) -> Dictionary:
	var best: Dictionary = {}
	var best_score: float = -INF
	var romantic: bool = stage in [STAGE_FLIRT, STAGE_DATING, STAGE_COUPLE]
	for sp in spots:
		if typeof(sp) != TYPE_DICTIONARY or not sp.has("pos"):
			continue
		var sid: String = str(sp.get("id", ""))
		var occupied: bool = false
		for hg in active_hangouts:
			if str(hg.get("spot_id", "")) == sid and sid != "":
				occupied = true
				break
		if occupied:
			continue
		var p: Vector2 = sp["pos"]
		var kind: String = str(sp.get("kind", "plaza"))
		var s: float = -(pos_a.distance_to(p) + pos_b.distance_to(p)) * 0.05
		match kind:
			"tavern": s += 14.0 if hour >= 18 else 2.0
			"plaza", "well": s += 10.0 if hour < 18 else 4.0
			"bench", "campfire": s += 12.0 if romantic else 5.0
		s += rng.randf_range(0.0, 6.0)
		if s > best_score:
			best_score = s
			best = sp
	return best

## Abre una quedada (fase de viaje). Respeta `max_concurrent_hangouts` y el cupo diario de cada uno.
func start_hangout(id_a: String, id_b: String, spot: Dictionary, current_day: int) -> Dictionary:
	if make_pair_key(id_a, id_b) == "" or spot.is_empty() or not spot.has("pos"):
		return {}
	if active_hangouts.size() >= int(dials.get("max_concurrent_hangouts", 2)):
		return {}
	if is_person_in_hangout(id_a) or is_person_in_hangout(id_b) or should_avoid(id_a, id_b):
		return {}
	var max_per_day: int = int(dials.get("hangout_max_per_person_per_day", 1))
	if get_hangouts_today(id_a, current_day) >= max_per_day or get_hangouts_today(id_b, current_day) >= max_per_day:
		return {}
	_hangout_seq += 1
	var hg: Dictionary = {
		"id": _hangout_seq,
		"actor_a_id": id_a,
		"actor_b_id": id_b,
		"spot_id": str(spot.get("id", "")),
		"spot_kind": str(spot.get("kind", "plaza")),
		"spot_pos": spot["pos"],
		"phase": HANGOUT_PHASE_TRAVEL,
		"arrived_a": false,
		"arrived_b": false,
		"travel_remaining": float(dials.get("hangout_travel_timeout_sec", 60.0)),
		"together_remaining": float(dials.get("hangout_together_sec", 45.0)),
		"started_day": current_day,
	}
	active_hangouts.append(hg)
	_register_hangout_today(id_a, current_day)
	_register_hangout_today(id_b, current_day)
	var pe: Dictionary = get_pair_entry(id_a, id_b)
	if not pe.is_empty():
		pe["last_contact_day"] = current_day
	return hg

## Atajo: elige compañero + punto y abre la quedada en un solo paso. `positions` = {person_id: Vector2}.
func try_plan_hangout(person_id: String, candidate_ids: Array, positions: Dictionary, spots: Array, hour: int, current_day: int) -> Dictionary:
	var partner: String = pick_hangout_partner(person_id, candidate_ids, hour, current_day)
	if partner == "":
		return {}
	var stage: String = str(get_pair_entry(person_id, partner).get("stage", STAGE_NONE))
	var spot: Dictionary = pick_shared_hangout_spot(spots, positions.get(person_id, Vector2.ZERO), positions.get(partner, Vector2.ZERO), hour, stage)
	if spot.is_empty():
		return {}
	return start_hangout(person_id, partner, spot, current_day)

## Marca la llegada de un participante al punto. Cuando llegan ambos, pasa a fase "together". Devuelve true si ya están juntos.
func mark_hangout_arrival(hangout_id: int, person_id: String) -> bool:
	for hg in active_hangouts:
		if int(hg.get("id", -1)) != hangout_id:
			continue
		if str(hg.get("actor_a_id", "")) == person_id:
			hg["arrived_a"] = true
		elif str(hg.get("actor_b_id", "")) == person_id:
			hg["arrived_b"] = true
		if bool(hg.get("arrived_a", false)) and bool(hg.get("arrived_b", false)):
			hg["phase"] = HANGOUT_PHASE_TOGETHER
		return str(hg.get("phase", "")) == HANGOUT_PHASE_TOGETHER
	return false

func cancel_hangout(hangout_id: int, reason: String = "cancelled") -> void:
	for i in range(active_hangouts.size() - 1, -1, -1):
		if int(active_hangouts[i].get("id", -1)) == hangout_id:
			var hg: Dictionary = active_hangouts[i]
			active_hangouts.remove_at(i)
			finished_hangouts.append({"id": hangout_id, "actor_a_id": hg.get("actor_a_id", ""), "actor_b_id": hg.get("actor_b_id", ""), "success": false, "reason": reason})
			return

## Cierra una quedada completada y aplica el bono suave al par (afinidad, familiaridad, chispa si procede, alivio de tensión).
func _complete_hangout(hg: Dictionary) -> Dictionary:
	var id_a: String = str(hg.get("actor_a_id", ""))
	var id_b: String = str(hg.get("actor_b_id", ""))
	var pe: Dictionary = get_pair_entry(id_a, id_b)
	var res: Dictionary = {"id": int(hg.get("id", 0)), "actor_a_id": id_a, "actor_b_id": id_b, "spot_kind": str(hg.get("spot_kind", "")), "spot_id": str(hg.get("spot_id", "")), "success": true, "reason": "completed"}
	if pe.is_empty():
		return res
	var d_aff: int = rng.randi_range(int(dials.get("hangout_bonus_affinity_min", 3)), int(dials.get("hangout_bonus_affinity_max", 6)))
	var d_fam: int = rng.randi_range(int(dials.get("hangout_bonus_familiarity_min", 4)), int(dials.get("hangout_bonus_familiarity_max", 7)))
	var d_ten: int = rng.randi_range(int(dials.get("hangout_tension_relief_min", 3)), int(dials.get("hangout_tension_relief_max", 6)))
	var d_spk: int = 0
	if int(pe.get("spark", 0)) > 0 or str(pe.get("stage", STAGE_NONE)) != STAGE_NONE:
		d_spk = rng.randi_range(int(dials.get("hangout_bonus_spark_min", 2)), int(dials.get("hangout_bonus_spark_max", 4)))
	pe["affinity"] = clampi(int(pe.get("affinity", 0)) + d_aff, -100, 100)
	pe["familiarity"] = clampi(int(pe.get("familiarity", 0)) + d_fam, 0, 100)
	pe["tension"] = clampi(int(pe.get("tension", 0)) - d_ten, 0, 100)
	d_spk = _add_spark_capped(pe, d_spk, int(hg.get("started_day", 1)))
	res["delta_affinity"] = d_aff
	res["delta_familiarity"] = d_fam
	res["delta_spark"] = d_spk
	res["delta_tension"] = -d_ten
	res["affinity"] = int(pe["affinity"])
	return res

func _tick_hangouts(delta: float) -> void:
	for i in range(active_hangouts.size() - 1, -1, -1):
		var hg: Dictionary = active_hangouts[i]
		if str(hg.get("phase", "")) == HANGOUT_PHASE_TOGETHER:
			var rem_t: float = float(hg.get("together_remaining", 0.0)) - delta
			hg["together_remaining"] = rem_t
			if rem_t <= 0.0:
				active_hangouts.remove_at(i)
				finished_hangouts.append(_complete_hangout(hg))
		else:
			var rem_v: float = float(hg.get("travel_remaining", 0.0)) - delta
			hg["travel_remaining"] = rem_v
			if rem_v <= 0.0:
				active_hangouts.remove_at(i)
				finished_hangouts.append({"id": int(hg.get("id", 0)), "actor_a_id": hg.get("actor_a_id", ""), "actor_b_id": hg.get("actor_b_id", ""), "success": false, "reason": "travel_timeout"})

## Devuelve y vacía los resultados de quedadas terminadas (para que el mundo muestre burbujas / humor en B2.2).
func pop_finished_hangouts() -> Array[Dictionary]:
	var out: Array[Dictionary] = finished_hangouts.duplicate()
	finished_hangouts.clear()
	return out

# ==============================================================================
# B3.1: CHISPA Y ETAPAS EN VIVO — Interés → Coqueteo → Citas → Pareja
# ==============================================================================
const STAGE_ORDER: Array[String] = [STAGE_NONE, STAGE_INTEREST, STAGE_FLIRT, STAGE_DATING, STAGE_COUPLE]
const STAGE_LABELS: Dictionary = {
	STAGE_NONE: "",
	STAGE_INTEREST: "💭 Interés",
	STAGE_FLIRT: "💘 Coqueteo",
	STAGE_DATING: "💞 Citas",
	STAGE_COUPLE: "💑 Pareja",
}

## Suma chispa respetando un tope diario por par (`spark_daily_gain_cap`) para que los cortejos tarden varios días. Devuelve lo sumado.
func _add_spark_capped(pe: Dictionary, amount: int, current_day: int) -> int:
	if amount <= 0:
		return 0
	if int(pe.get("spark_gain_day", -1)) != current_day:
		pe["spark_gain_day"] = current_day
		pe["spark_gain_today"] = 0
	var cap: int = int(dials.get("spark_daily_gain_cap", 10))
	var add: int = mini(amount, maxi(0, cap - int(pe.get("spark_gain_today", 0))))
	pe["spark_gain_today"] = int(pe.get("spark_gain_today", 0)) + add
	pe["spark"] = clampi(int(pe.get("spark", 0)) + add, 0, 100)
	return add

static func get_stage_label(stage: String) -> String:
	return str(STAGE_LABELS.get(stage, ""))

func get_pair_stage(id_a: String, id_b: String) -> String:
	var k: String = make_pair_key(id_a, id_b)
	if k == "" or not pair_metrics.has(k):
		return STAGE_NONE
	return str(pair_metrics[k].get("stage", STAGE_NONE))

## Devuelve el cortejo más avanzado (sin contar pareja formada) de una persona: {"other_id", "stage"} o {}.
func get_courtship_of(person_id: String) -> Dictionary:
	var best: Dictionary = {}
	var best_idx: int = 0
	for k in pair_metrics.keys():
		var parts: PackedStringArray = str(k).split("|")
		if parts.size() != 2 or not (person_id in parts):
			continue
		var st: String = str(pair_metrics[k].get("stage", STAGE_NONE))
		var idx: int = STAGE_ORDER.find(st)
		if st == STAGE_COUPLE or idx <= best_idx:
			continue
		best_idx = idx
		best = {"other_id": parts[1] if parts[0] == person_id else parts[0], "stage": st}
	return best

func _stage_threshold(stage_next: String) -> int:
	match stage_next:
		STAGE_INTEREST: return int(dials.get("stage_spark_interest", 14))
		STAGE_FLIRT: return int(dials.get("stage_spark_flirt", 28))
		STAGE_DATING: return int(dials.get("stage_spark_dating", 44))
		STAGE_COUPLE: return int(dials.get("stage_spark_couple", 60))
	return 999

## B3.3: Evalúa si una interacción cercana o quedada entre `actor_a_id` y `actor_b_id` (que no son pareja entre sí)
## despierta celos en la pareja actual de alguno de ellos.
## Devuelve Array de episodios: `[{"partner_id", "cheater_id", "rival_id", "couple_tension", "rival_tension"}]`.
func trigger_jealousy_if_any(actor_a_id: String, actor_b_id: String, profiles_by_id: Dictionary, families_by_id: Dictionary = {}, current_day: int = 1) -> Array:
	var events: Array = []
	var prof_a = profiles_by_id.get(actor_a_id, null)
	var prof_b = profiles_by_id.get(actor_b_id, null)
	if prof_a == null or prof_b == null or actor_a_id == actor_b_id:
		return events
	if str(prof_a.partner_id) == actor_b_id or str(prof_b.partner_id) == actor_a_id:
		return events
	var fam_a: String = str(families_by_id.get(actor_a_id, "none"))
	var fam_b: String = str(families_by_id.get(actor_b_id, "none"))
	var same_fam: bool = (fam_a != "none" and fam_a != "" and fam_a != "family_police" and fam_a == fam_b)
	if compute_compatibility(prof_a, prof_b, same_fam) < int(dials.get("romance_min_compat", 40)):
		return events
	var pe_ab: Dictionary = get_pair_entry(actor_a_id, actor_b_id)
	if int(pe_ab.get("affinity", 0)) < 26 and int(pe_ab.get("spark", 0)) < 14:
		return events
	for pair_info in [[actor_a_id, actor_b_id, prof_a], [actor_b_id, actor_a_id, prof_b]]:
		var cheater_id: String = str(pair_info[0])
		var rival_id: String = str(pair_info[1])
		var prof_c = pair_info[2]
		var partner_id: String = str(prof_c.partner_id)
		if partner_id == "" or partner_id == rival_id or not profiles_by_id.has(partner_id):
			continue
		var prof_p = profiles_by_id[partner_id]
		if prof_p == null:
			continue
		var chance: float = float(dials.get("jealousy_base_chance", 0.65))
		if ("Celoso" in prof_p.personality) or ("Desconfiado" in prof_p.personality):
			chance += 0.25
		if "Pacífico" in prof_p.personality:
			chance -= 0.25
		if rng.randf() >= clampf(chance, 0.15, 0.95):
			continue
		var pe_couple: Dictionary = get_pair_entry(partner_id, cheater_id, 65)
		var ten_add: int = int(dials.get("jealousy_tension_gain_base", 14))
		if "Celoso" in prof_p.personality:
			ten_add += int(dials.get("jealousy_trait_bonus", 10))
		pe_couple["tension"] = clampi(int(pe_couple.get("tension", 0)) + ten_add, 0, 100)
		pe_couple["affinity"] = clampi(int(pe_couple.get("affinity", 65)) - 8, -100, 100)
		pe_couple["last_contact_day"] = current_day
		var pe_rival: Dictionary = get_pair_entry(partner_id, rival_id, 0)
		var r_ten_add: int = int(dials.get("jealousy_rival_tension_gain", 12))
		pe_rival["tension"] = clampi(int(pe_rival.get("tension", 0)) + r_ten_add, 0, 100)
		pe_rival["affinity"] = clampi(int(pe_rival.get("affinity", 0)) - 8, -100, 100)
		events.append({
			"partner_id": partner_id,
			"cheater_id": cheater_id,
			"rival_id": rival_id,
			"couple_tension": int(pe_couple["tension"]),
			"rival_tension": int(pe_rival["tension"]),
		})
	return events

## Paso diario de cortejos en vivo. `profiles_by_id`: {person_id: PersonProfile} de los vivos; `families_by_id`: {person_id: family_id}.
## Solo avanza quien tuvo contacto hoy/ayer (charlas o quedadas), con probabilidad, sin plazos. Si la chispa se apaga, el cortejo se pierde.
## También evalúa rupturas por alta tensión/baja afinidad y reconciliación de ex-parejas (B3.3).
## Devuelve {"advanced", "new_couples", "fizzled", "breakups", "reconciled"}.
func advance_live_romance_day(current_day: int, profiles_by_id: Dictionary, families_by_id: Dictionary = {}) -> Dictionary:
	var advanced: Array = []
	var new_couples: Array = []
	var fizzled: Array = []
	var breakups: Array = []
	var reconciled: Array = []
	var keys: Array = pair_metrics.keys()
	keys.sort()
	var window: int = int(dials.get("live_stage_contact_window_days", 1))
	var min_compat: int = int(dials.get("romance_min_compat", 40))
	for k in keys:
		var pe: Dictionary = pair_metrics[k]
		var parts: PackedStringArray = str(k).split("|")
		if parts.size() != 2:
			continue
		var id_a: String = parts[0]
		var id_b: String = parts[1]
		var prof_a = profiles_by_id.get(id_a, null)
		var prof_b = profiles_by_id.get(id_b, null)
		if prof_a == null or prof_b == null:
			continue
		var stage: String = str(pe.get("stage", STAGE_NONE))
		if stage == STAGE_COUPLE:
			if int(pe.get("tension", 0)) >= int(dials.get("breakup_min_tension", 62)) and int(pe.get("affinity", 0)) <= int(dials.get("breakup_max_affinity", 12)):
				if rng.randf() < float(dials.get("breakup_daily_chance", 0.28)):
					pe["stage"] = STAGE_NONE
					pe["ex_couple"] = true
					pe["spark"] = maxi(20, int(pe.get("spark", 0)) - 25)
					pe["tension"] = clampi(int(pe.get("tension", 0)) - 20, 0, 100)
					if str(prof_a.partner_id) == id_b:
						prof_a.romance_status = PersonProfile.ROMANCE_SINGLE
						prof_a.partner_id = ""
					if str(prof_b.partner_id) == id_a:
						prof_b.romance_status = PersonProfile.ROMANCE_SINGLE
						prof_b.partner_id = ""
					breakups.append({"id_a": id_a, "id_b": id_b})
			continue
		var spk: int = int(pe.get("spark", 0))
		if stage != STAGE_NONE and spk < int(dials.get("stage_fizzle_spark", 8)):
			pe["stage"] = STAGE_NONE
			fizzled.append({"id_a": id_a, "id_b": id_b, "from": stage})
			continue
		if spk <= 0 or int(pe.get("last_contact_day", 0)) < current_day - window:
			continue
		var both_single: bool = str(prof_a.romance_status) == PersonProfile.ROMANCE_SINGLE and str(prof_b.romance_status) == PersonProfile.ROMANCE_SINGLE
		if not both_single:
			continue
		# B3.3: Reconciliación de ex-parejas si siguen teniendo chispa, baja tensión y buena afinidad tras hablar
		if bool(pe.get("ex_couple", false)) and spk >= int(dials.get("reconcile_ex_min_spark", 35)) and int(pe.get("tension", 0)) <= int(dials.get("reconcile_ex_max_tension", 18)) and int(pe.get("affinity", 0)) >= 28:
			if rng.randf() < float(dials.get("reconcile_ex_chance", 0.35)):
				pe["stage"] = STAGE_COUPLE
				pe["ex_couple"] = false
				pe["affinity"] = maxi(int(pe.get("affinity", 0)), 62)
				prof_a.romance_status = PersonProfile.ROMANCE_PARTNERED
				prof_a.partner_id = id_b
				prof_b.romance_status = PersonProfile.ROMANCE_PARTNERED
				prof_b.partner_id = id_a
				reconciled.append({"id_a": id_a, "id_b": id_b})
				continue
		var fam_a: String = str(families_by_id.get(id_a, "none"))
		var fam_b: String = str(families_by_id.get(id_b, "none"))
		var same_fam: bool = (fam_a != "none" and fam_a != "" and fam_a != "family_police" and fam_a == fam_b)
		var compat: int = compute_compatibility(prof_a, prof_b, same_fam)
		if compat < min_compat:
			continue
		var idx: int = STAGE_ORDER.find(stage)
		if idx < 0 or idx >= STAGE_ORDER.size() - 1:
			continue
		var next_stage: String = STAGE_ORDER[idx + 1]
		if spk < _stage_threshold(next_stage):
			continue
		if next_stage == STAGE_COUPLE and (int(pe.get("affinity", 0)) < int(dials.get("stage_couple_min_affinity", 24)) or total_new_couples_formed >= int(dials.get("max_new_couples_per_60d", 3))):
			continue
		var chance: float = float(dials.get("live_stage_advance_chance", 0.30)) * (float(compat) / 50.0)
		if rng.randf() >= chance:
			continue
		pe["stage"] = next_stage
		advanced.append({"id_a": id_a, "id_b": id_b, "from": stage, "to": next_stage})
		if next_stage == STAGE_COUPLE:
			prof_a.romance_status = PersonProfile.ROMANCE_PARTNERED
			prof_a.partner_id = id_b
			prof_b.romance_status = PersonProfile.ROMANCE_PARTNERED
			prof_b.partner_id = id_a
			pe["affinity"] = maxi(int(pe.get("affinity", 0)), 68)
			total_new_couples_formed += 1
			new_couples.append({"id_a": id_a, "id_b": id_b})
	return {"advanced": advanced, "new_couples": new_couples, "fizzled": fizzled, "breakups": breakups, "reconciled": reconciled}

# ==============================================================================
# B4.1: PELEAS DISCRETAS POR DADOS — poder ponderado y resolución sin muerte
# ==============================================================================
const ROLE_FIGHT_BONUS: Dictionary = {
	0: 2,  # UNEMPLOYED
	1: 1,  # FAMILY_MEMBER
	2: 2,  # INNKEEPER
	3: 4,  # BUTCHER
	4: 4,  # BLACKSMITH
	5: 3,  # CARPENTER
	6: 1,  # HERBALIST
	7: 2,  # FISHMONGER
	8: 1,  # DOCTOR
	9: 5,  # SHERIFF
	10: 5, # GUARD
}

## Calcula el poder de pelea interno de un vecino ponderado por oficio, edad, salud (0.4..1.0) y personalidad.
func compute_fight_power(prof, role_id: int = 0, health_ratio: float = 1.0) -> int:
	var score: int = 10 + int(ROLE_FIGHT_BONUS.get(role_id, 1))
	if prof != null:
		var age_v: int = int(prof.age)
		if age_v < 30:
			score += 2
		elif age_v <= 48:
			score += 3
		elif age_v >= 55:
			score -= 2
		for tr in prof.personality:
			match str(tr):
				"Valiente": score += 3
				"Rencoroso": score += 2
				"Trabajador", "Orgulloso": score += 1
				"Pacífico": score -= 3
				"Bondadoso": score -= 1
	var mult: float = clampf(health_ratio, 0.40, 1.0)
	return maxi(2, int(round(float(score) * mult)))

## Comprueba si un par cumple las condiciones de tensión, cupo por par (`max_fights_per_pair = 2`) y enfriamiento global (`drama_cooldown_days`).
func can_pair_fight(id_a: String, id_b: String, current_day: int, same_family: bool = false) -> bool:
	if same_family or id_a == "" or id_b == "" or id_a == id_b:
		return false
	if (current_day - last_drama_day) < int(dials.get("drama_cooldown_days", 2)):
		return false
	var k: String = make_pair_key(id_a, id_b)
	if k == "" or not pair_metrics.has(k):
		return false
	var pe: Dictionary = pair_metrics[k]
	if int(pe.get("fights_count", 0)) >= int(dials.get("max_fights_per_pair", 2)):
		return false
	return int(pe.get("tension", 0)) >= int(dials.get("fight_tension_threshold", 36))

## B4.1: Evalúa y resuelve con dados internos (`2d6` + poder) una pelea discreta en vivo entre dos vecinos.
## Devuelve `{"triggered": false, "reason": ...}` o el diccionario completo del resultado con `winner_id` y `loser_id`.
func try_resolve_live_fight(npc_a, npc_b, current_day: int = 1, force_roll: bool = false) -> Dictionary:
	if npc_a == null or npc_b == null or npc_a == npc_b:
		return {"triggered": false, "reason": "invalid_actors"}
	var prof_a = npc_a.get("person_profile")
	var prof_b = npc_b.get("person_profile")
	var name_a: String = str(npc_a.get("npc_name"))
	var name_b: String = str(npc_b.get("npc_name"))
	if prof_a == null:
		prof_a = PersonProfile.make_fallback_for_name(name_a if name_a != "" else "Vecino A")
	if prof_b == null:
		prof_b = PersonProfile.make_fallback_for_name(name_b if name_b != "" else "Vecino B")
	var id_a: String = str(prof_a.person_id)
	var id_b: String = str(prof_b.person_id)
	var fam_a: String = str(npc_a.get("family_id")) if "family_id" in npc_a else "none"
	var fam_b: String = str(npc_b.get("family_id")) if "family_id" in npc_b else "none"
	var same_fam: bool = (fam_a != "none" and fam_a != "" and fam_a != "family_police" and fam_a == fam_b)
	if not can_pair_fight(id_a, id_b, current_day, same_fam):
		return {"triggered": false, "reason": "conditions_not_met"}
	if not can_start_scene(id_a, id_b):
		return {"triggered": false, "reason": "max_scenes_or_busy"}
	var has_pacifist: bool = ("Pacífico" in prof_a.personality) or ("Pacífico" in prof_b.personality)
	var f_chance: float = float(dials.get("fight_daily_base_chance", 0.38))
	if has_pacifist:
		f_chance *= 0.15
	if not force_roll and rng.randf() >= f_chance:
		return {"triggered": false, "reason": "dice_skipped"}
	var sc: Dictionary = start_scene("fight", id_a, id_b, 3.5, current_day)
	if sc.is_empty():
		return {"triggered": false, "reason": "scene_rejected"}
	var role_a: int = int(npc_a.get("trade_role")) if "trade_role" in npc_a else 0
	var role_b: int = int(npc_b.get("trade_role")) if "trade_role" in npc_b else 0
	var hp_a: float = 1.0
	var hp_b: float = 1.0
	if "health_comp" in npc_a and npc_a.get("health_comp") != null and npc_a.get("health_comp").has_method("get_overall_health_pct"):
		hp_a = float(npc_a.get("health_comp").call("get_overall_health_pct")) / 100.0
	if "health_comp" in npc_b and npc_b.get("health_comp") != null and npc_b.get("health_comp").has_method("get_overall_health_pct"):
		hp_b = float(npc_b.get("health_comp").call("get_overall_health_pct")) / 100.0
	var pwr_a: int = compute_fight_power(prof_a, role_a, hp_a)
	var pwr_b: int = compute_fight_power(prof_b, role_b, hp_b)
	var dice_a: int = rng.randi_range(1, 6) + rng.randi_range(1, 6)
	var dice_b: int = rng.randi_range(1, 6) + rng.randi_range(1, 6)
	var total_a: int = pwr_a + dice_a
	var total_b: int = pwr_b + dice_b
	var a_wins: bool = total_a > total_b if total_a != total_b else (rng.randf() < 0.5)
	var winner_id: String = id_a if a_wins else id_b
	var loser_id: String = id_b if a_wins else id_a
	var winner_name: String = name_a if a_wins else name_b
	var loser_name: String = name_b if a_wins else name_a
	var pe: Dictionary = get_pair_entry(id_a, id_b)
	pe["fights_count"] = int(pe.get("fights_count", 0)) + 1
	pe["tension"] = clampi(int(pe.get("tension", 0)) - 26, 0, 100)
	pe["affinity"] = clampi(int(pe.get("affinity", 0)) - 14, -100, 100)
	pe["last_contact_day"] = current_day
	last_drama_day = current_day
	total_fights_triggered += 1
	return {
		"triggered": true,
		"scene_id": int(sc.get("id", 0)),
		"winner_id": winner_id,
		"loser_id": loser_id,
		"winner_name": winner_name,
		"loser_name": loser_name,
		"power_a": pwr_a,
		"power_b": pwr_b,
		"roll_a": total_a,
		"roll_b": total_b,
		"fights_count": int(pe["fights_count"]),
		"tension_after": int(pe["tension"]),
		"affinity_after": int(pe["affinity"]),
	}

## Enfriamiento diario para pares sin contacto en `current_day`.
func on_day_passed(current_day: int) -> void:
	var fam_dec: int = int(dials.get("decay_familiarity_no_contact", 1))
	var spk_dec: int = int(dials.get("decay_spark_no_contact", 1))
	var ten_dec: int = int(dials.get("decay_tension_no_contact", 2))
	for k in pair_metrics.keys():
		var pe: Dictionary = pair_metrics[k]
		if int(pe.get("last_contact_day", 0)) < current_day - 1:
			pe["familiarity"] = clampi(int(pe.get("familiarity", 0)) - fam_dec, 0, 100)
			if str(pe.get("stage", STAGE_NONE)) != STAGE_COUPLE:
				pe["spark"] = clampi(int(pe.get("spark", 0)) - spk_dec, 0, 100)
			pe["tension"] = clampi(int(pe.get("tension", 0)) - ten_dec, 0, 100)

func to_save_dict() -> Dictionary:
	return {
		"rng_state": rng.state,
		"last_drama_day": last_drama_day,
		"pair_metrics": pair_metrics.duplicate(true),
		"hangout_day_counts": hangout_day_counts.duplicate(true),
	}

func from_save_dict(d: Dictionary) -> void:
	if d.has("rng_state"):
		rng.state = int(d["rng_state"])
	last_drama_day = int(d.get("last_drama_day", -10))
	if d.has("pair_metrics") and typeof(d["pair_metrics"]) == TYPE_DICTIONARY:
		pair_metrics = (d["pair_metrics"] as Dictionary).duplicate(true)
	if d.has("hangout_day_counts") and typeof(d["hangout_day_counts"]) == TYPE_DICTIONARY:
		hangout_day_counts = (d["hangout_day_counts"] as Dictionary).duplicate(true)
	active_scenes.clear()
	active_hangouts.clear()
	finished_hangouts.clear()

## B0.9: Simula un día completo de interacciones sociales entre un conjunto de fichas (`id -> PersonProfile`) y familias (`id -> family_id`).
## Devuelve las novedades ocurridas en el día: `{"new_couples": Array, "fights": Array}`.
func simulate_social_day(current_day: int, profiles_by_id: Dictionary, families_by_id: Dictionary = {}) -> Dictionary:
	var ids: Array = profiles_by_id.keys()
	ids.sort()
	var new_couples: Array = []
	var fights: Array = []
	if ids.size() < 2:
		return {"new_couples": new_couples, "fights": fights}

	var interactions_count: int = int(dials.get("daily_interactions_per_day", 14))
	for _step in range(interactions_count):
		var idx_a: int = rng.randi_range(0, ids.size() - 1)
		var idx_b: int = rng.randi_range(0, ids.size() - 2)
		if idx_b >= idx_a:
			idx_b += 1
		var id_a: String = str(ids[idx_a])
		var id_b: String = str(ids[idx_b])
		var prof_a = profiles_by_id[id_a]
		var prof_b = profiles_by_id[id_b]
		var fam_a: String = str(families_by_id.get(id_a, "none"))
		var fam_b: String = str(families_by_id.get(id_b, "none"))
		var same_fam: bool = (fam_a != "none" and fam_a != "" and fam_a != "family_police" and fam_a == fam_b)

		var pe: Dictionary = get_pair_entry(id_a, id_b, 85 if same_fam else 0)
		pe["last_contact_day"] = current_day
		pe["familiarity"] = clampi(int(pe.get("familiarity", 0)) + rng.randi_range(2, 5), 0, 100)

		# Compatibilidad general de trato (compartir gustos/rasgos aunque sean del mismo género)
		var social_harmony: int = 0
		for lk in prof_a.likes:
			if lk in prof_b.likes: social_harmony += 1
			if lk in prof_b.dislikes: social_harmony -= 1
		for tr in prof_a.personality:
			if tr in prof_b.personality: social_harmony += 1
			var opp: String = str(PersonProfile.OPPOSITE_TRAITS.get(tr, ""))
			if opp != "" and (opp in prof_b.personality): social_harmony -= 2

		var cur_aff: int = int(pe.get("affinity", 0))
		var roll: float = rng.randf()
		var cordial_chat: bool = false
		if same_fam:
			pe["affinity"] = clampi(cur_aff + rng.randi_range(0, 2), 55, 95)
			pe["tension"] = clampi(int(pe.get("tension", 0)) - 3, 0, 25)
		elif roll < clampf(0.68 + float(social_harmony) * 0.06 + (0.14 if cur_aff >= 20 else (-0.18 if cur_aff <= -25 else 0.0)), 0.22, 0.88):
			# Charla cordial: amortiguada arriba de +35 para mantener la mayoría en el rango natural (-20..+40)
			var gain: int = rng.randi_range(2, 5) if cur_aff < 30 else rng.randi_range(0, 1)
			pe["affinity"] = clampi(cur_aff + gain, -100, 100)
			pe["tension"] = clampi(int(pe.get("tension", 0)) - rng.randi_range(1, 3), 0, 100)
			cordial_chat = true
		else:
			# Roce vecinal
			var drop: int = rng.randi_range(2, 5) if cur_aff > -35 else rng.randi_range(0, 2)
			pe["affinity"] = clampi(cur_aff - drop, -100, 100)
			var ten_add: int = rng.randi_range(8, 15)
			if ("Rencoroso" in prof_a.personality) or ("Rencoroso" in prof_b.personality) or ("Celoso" in prof_a.personality) or ("Celoso" in prof_b.personality):
				ten_add += 6
			if ("Pacífico" in prof_a.personality) or ("Pacífico" in prof_b.personality):
				ten_add = maxi(2, ten_add - 6)
			pe["tension"] = clampi(int(pe.get("tension", 0)) + ten_add, 0, 100)

		# Evaluación de chispa en vivo (solo solteros compatibles en charla cordial, con tope diario _add_spark_capped)
		var both_single: bool = (str(prof_a.romance_status) == PersonProfile.ROMANCE_SINGLE and str(prof_b.romance_status) == PersonProfile.ROMANCE_SINGLE)
		var rom_compat: int = compute_compatibility(prof_a, prof_b, same_fam)
		if cordial_chat and both_single and rom_compat >= int(dials.get("romance_min_compat", 40)) and int(pe["affinity"]) >= int(dials.get("spark_min_affinity", 16)) and int(pe["familiarity"]) >= int(dials.get("spark_min_familiarity", 14)):
			var spk_gain: int = rng.randi_range(3, int(dials.get("spark_daily_gain_max", 8)))
			if rom_compat >= 60:
				spk_gain += 2
			_add_spark_capped(pe, spk_gain, current_day)

		# Evaluación de pelea discreta por tensión (sin muerte, respetando drama_cooldown_days y max_fights_per_pair)
		var ten_now: int = int(pe.get("tension", 0))
		var f_count: int = int(pe.get("fights_count", 0))
		var max_f: int = int(dials.get("max_fights_per_pair", 2))
		var max_tot_f: int = int(dials.get("max_total_fights_per_60d", 5))
		var drama_cd: int = int(dials.get("drama_cooldown_days", 2))
		var has_pacifist: bool = ("Pacífico" in prof_a.personality) or ("Pacífico" in prof_b.personality)
		if not same_fam and total_fights_triggered < max_tot_f and ten_now >= int(dials.get("fight_tension_threshold", 36)) and f_count < max_f and (current_day - last_drama_day) >= drama_cd:
			var f_chance: float = float(dials.get("fight_daily_base_chance", 0.38))
			if has_pacifist:
				f_chance *= 0.15
			if rng.randf() < f_chance:
				pe["fights_count"] = f_count + 1
				pe["tension"] = clampi(ten_now - 26, 0, 100)
				pe["affinity"] = clampi(int(pe["affinity"]) - 12, -100, 100)
				last_drama_day = current_day
				total_fights_triggered += 1
				fights.append(make_pair_key(id_a, id_b))

	# B3.5: En el juego en vivo, los pares en cortejo (Interés/Coqueteo/Citas) se buscan activamente en la tarde libre
	var sorted_pkeys: Array = pair_metrics.keys()
	sorted_pkeys.sort()
	for pk in sorted_pkeys:
		var pe_c: Dictionary = pair_metrics[pk]
		var st_c: String = str(pe_c.get("stage", STAGE_NONE))
		if st_c in [STAGE_INTEREST, STAGE_FLIRT, STAGE_DATING]:
			var pts: PackedStringArray = str(pk).split("|")
			if pts.size() == 2 and profiles_by_id.has(pts[0]) and profiles_by_id.has(pts[1]):
				var pa = profiles_by_id[pts[0]]
				var pb = profiles_by_id[pts[1]]
				if str(pa.romance_status) == PersonProfile.ROMANCE_SINGLE and str(pb.romance_status) == PersonProfile.ROMANCE_SINGLE and rng.randf() < 0.48:
					pe_c["last_contact_day"] = current_day
					_add_spark_capped(pe_c, rng.randi_range(3, 5), current_day)

	var max_couples: int = int(dials.get("max_new_couples_per_60d", 3))
	if total_new_couples_formed < max_couples:
		var rom_res: Dictionary = advance_live_romance_day(current_day, profiles_by_id, families_by_id)
		for nc in rom_res.get("new_couples", []):
			new_couples.append(make_pair_key(str(nc.get("id_a", "")), str(nc.get("id_b", ""))))
	on_day_passed(current_day)
	return {"new_couples": new_couples, "fights": fights}
