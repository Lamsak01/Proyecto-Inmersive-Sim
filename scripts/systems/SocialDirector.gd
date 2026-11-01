extends RefCounted

## Director Social central (B0.7): gestiona hasta un máximo estricto de escenas simultáneas (`max_concurrent_scenes = 3`),
## mantiene las 4 medidas de relación por par (`affinity`, `familiarity`, `spark`, `tension`) y concentra todos los diales
## de ajuste en una única tabla (`DIALS`) para la calibración automática (B0.9).
## Cargado mediante preload("res://scripts/systems/SocialDirector.gd").

const PersonProfile = preload("res://scripts/data/PersonProfile.gd")

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
	"spark_min_affinity": 28,
	"spark_min_familiarity": 20,
	"spark_daily_gain_max": 6,
	"stage_advance_base_chance": 0.14,
	"fight_tension_threshold": 55,
	"fight_daily_base_chance": 0.12,
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
