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
	"spark_min_affinity": 14,
	"spark_min_familiarity": 12,
	"spark_daily_gain_max": 12,
	"stage_advance_base_chance": 0.36,
	"fight_tension_threshold": 36,
	"fight_daily_base_chance": 0.38,
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

	if cur_rel <= -20:
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
		pe["spark"] = clampi(int(pe.get("spark", 0)) + rng.randi_range(2, 5), 0, 100)

	var ex: Dictionary = SocialDialogueData.build_exchange(action_id, dict_a, name_a, dict_b, name_b, topic_used, rng)
	ex["allowed"] = true
	ex["scene_id"] = int(sc.get("id", 0))
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
	_tick_accum += delta
	var interval: float = maxf(0.5, float(dials.get("tick_interval_sec", 4.0)))
	if _tick_accum < interval:
		return
	_tick_accum = 0.0

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
	}

func from_save_dict(d: Dictionary) -> void:
	if d.has("rng_state"):
		rng.state = int(d["rng_state"])
	last_drama_day = int(d.get("last_drama_day", -10))
	if d.has("pair_metrics") and typeof(d["pair_metrics"]) == TYPE_DICTIONARY:
		pair_metrics = (d["pair_metrics"] as Dictionary).duplicate(true)
	active_scenes.clear()

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
		if same_fam:
			pe["affinity"] = clampi(cur_aff + rng.randi_range(0, 2), 55, 95)
			pe["tension"] = clampi(int(pe.get("tension", 0)) - 3, 0, 25)
		elif roll < clampf(0.68 + float(social_harmony) * 0.06 + (0.14 if cur_aff >= 20 else (-0.18 if cur_aff <= -25 else 0.0)), 0.22, 0.88):
			# Charla cordial: amortiguada arriba de +35 para mantener la mayoría en el rango natural (-20..+40)
			var gain: int = rng.randi_range(2, 5) if cur_aff < 30 else rng.randi_range(0, 1)
			pe["affinity"] = clampi(cur_aff + gain, -100, 100)
			pe["tension"] = clampi(int(pe.get("tension", 0)) - rng.randi_range(1, 3), 0, 100)
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

		# Evaluación de chispa y etapas de pareja (solo solteros heterosexuales de distinta familia)
		var both_single: bool = (str(prof_a.romance_status) == PersonProfile.ROMANCE_SINGLE and str(prof_b.romance_status) == PersonProfile.ROMANCE_SINGLE)
		var rom_compat: int = compute_compatibility(prof_a, prof_b, same_fam)
		var max_couples: int = int(dials.get("max_new_couples_per_60d", 3))
		if both_single and total_new_couples_formed < max_couples and rom_compat >= 40 and int(pe["affinity"]) >= int(dials.get("spark_min_affinity", 14)) and int(pe["familiarity"]) >= int(dials.get("spark_min_familiarity", 12)):
			var spk_gain: int = rng.randi_range(4, int(dials.get("spark_daily_gain_max", 12)))
			if rom_compat >= 60:
				spk_gain += 3
			pe["spark"] = clampi(int(pe.get("spark", 0)) + spk_gain, 0, 100)
			var cur_stage: String = str(pe.get("stage", STAGE_NONE))
			var spk: int = int(pe["spark"])
			var adv_chance: float = float(dials.get("stage_advance_base_chance", 0.36)) * (float(rom_compat) / 50.0)
			if cur_stage == STAGE_NONE and spk >= 14 and rng.randf() < adv_chance:
				pe["stage"] = STAGE_INTEREST
			elif cur_stage == STAGE_INTEREST and spk >= 28 and rng.randf() < adv_chance:
				pe["stage"] = STAGE_FLIRT
			elif cur_stage == STAGE_FLIRT and spk >= 44 and rng.randf() < adv_chance:
				pe["stage"] = STAGE_DATING
			elif cur_stage == STAGE_DATING and spk >= 60 and int(pe["affinity"]) >= 24 and rng.randf() < adv_chance:
				pe["stage"] = STAGE_COUPLE
				prof_a.romance_status = PersonProfile.ROMANCE_PARTNERED
				prof_a.partner_id = id_b
				prof_b.romance_status = PersonProfile.ROMANCE_PARTNERED
				prof_b.partner_id = id_a
				pe["affinity"] = maxi(int(pe["affinity"]), 68)
				total_new_couples_formed += 1
				new_couples.append(make_pair_key(id_a, id_b))

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

	on_day_passed(current_day)
	return {"new_couples": new_couples, "fights": fights}
