extends Node
class_name HealthComponent

signal died
signal health_changed(current, max)
signal blood_changed(current, max)
signal weakness_changed(is_weak)
signal bleed_triggered(dps_amount)
signal anatomy_changed()

const REGION_ORDER: Array[String] = ["head", "torso", "left_arm", "right_arm", "left_leg", "right_leg"]
const REGION_DEFS: Dictionary = {
	"head": {"name": "Cabeza", "max_hp": 35.0, "weight": 0.12, "vital": true},
	"torso": {"name": "Torso", "max_hp": 65.0, "weight": 0.34, "vital": true},
	"left_arm": {"name": "Brazo Izq.", "max_hp": 40.0, "weight": 0.13, "vital": false},
	"right_arm": {"name": "Brazo Der.", "max_hp": 40.0, "weight": 0.14, "vital": false},
	"left_leg": {"name": "Pierna Izq.", "max_hp": 45.0, "weight": 0.13, "vital": false},
	"right_leg": {"name": "Pierna Der.", "max_hp": 45.0, "weight": 0.14, "vital": false}
}
const ORGAN_DEFS: Dictionary = {
	"brain": {"name": "Cerebro", "region": "head", "vital": true},
	"eyes": {"name": "Ojos", "region": "head", "vital": false},
	"heart": {"name": "Corazón", "region": "torso", "vital": true},
	"lungs": {"name": "Pulmones", "region": "torso", "vital": true},
	"stomach": {"name": "Estómago", "region": "torso", "vital": false},
	"liver": {"name": "Hígado", "region": "torso", "vital": false},
	"kidneys": {"name": "Riñones", "region": "torso", "vital": false}
}
const WOUND_NAMES: Dictionary = {
	"scratch": "Rasguño", "laceration": "Laceración", "deep_wound": "Corte Profundo",
	"bruise": "Contusión", "fracture": "Fractura Ósea", "lodged_arrow": "Flecha Clavada",
	"organ_damage": "Trauma Interno"
}

@export var max_health: float = 100.0
@export var max_blood: float = 100.0 ## Umbral máximo de acumulación para activar el sangrado
@export var bleed_decay_rate: float = 8.0 ## Qué tan rápido baja la acumulación si no estás sangrando
@export var bleed_duration: float = 5.0 ## Duración en segundos del desangrado activo
@export var bleed_damage_multiplier: float = 0.4 ## Daño por segundo de sangrado como proporción del daño del arma

var current_health: float
var current_blood: float = 0.0 ## Acumulación actual de sangrado (0 a max_blood)
var is_bleeding: bool = false
var is_weak: bool = false
var armor_defense: float = 0.0 ## Reducción porcentual de daño físico por armadura (0.0 a 0.75)
var armor_bleed_resistance: float = 0.0 ## Reducción de acumulación de sangrado (0.0 a 0.85)

var _bleed_timer: float = 0.0
var _bleed_dps: float = 0.0

var region_hp: Dictionary = {}
var organ_hp: Dictionary = {}
var wounds: Array[Dictionary] = []
var _next_wound_id: int = 1
var _med_tick_accum: float = 0.0

func _ready() -> void:
	current_health = max_health
	current_blood = 0.0
	_init_anatomy()
	if Engine.is_editor_hint():
		set_process(false)

func _init_anatomy() -> void:
	for r_id in REGION_ORDER:
		region_hp[r_id] = float(REGION_DEFS[r_id]["max_hp"])
	for o_id in ORGAN_DEFS.keys():
		organ_hp[o_id] = 100.0
	wounds.clear()

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or current_health <= 0.0 or (WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen()):
		return

	if is_bleeding:
		_bleed_timer -= delta
		var bleed_loss: float = _bleed_dps * delta
		current_health = max(0.0, current_health - bleed_loss)
		_drain_bleeding_region_hp(bleed_loss)
		health_changed.emit(current_health, max_health)

		# Reflejar el tiempo restante de sangrado en la barra
		current_blood = clamp((_bleed_timer / bleed_duration) * max_blood, 0.0, max_blood)
		blood_changed.emit(current_blood, max_blood)

		if current_health <= 0.0:
			is_bleeding = false
			died.emit()
			return

		if _bleed_timer <= 0.0:
			is_bleeding = false
			current_blood = 0.0
			_bleed_dps = 0.0
			blood_changed.emit(current_blood, max_blood)
			if is_weak:
				is_weak = false
				weakness_changed.emit(false)
	elif current_blood > 0.0:
		# Si no llegó al máximo, la acumulación baja poco a poco con el tiempo
		current_blood = max(0.0, current_blood - bleed_decay_rate * delta)
		blood_changed.emit(current_blood, max_blood)

	_med_tick_accum += delta
	if _med_tick_accum >= 1.0:
		var dt_m: float = _med_tick_accum
		_med_tick_accum = 0.0
		_tick_anatomical_recovery(dt_m)

func _drain_bleeding_region_hp(loss: float) -> void:
	for w in wounds:
		if float(w.get("bleed_rate", 0.0)) > 0.0 and not bool(w.get("bandaged", false)) and not bool(w.get("stitched", false)):
			var rk: String = str(w.get("region", "torso"))
			region_hp[rk] = maxf(1.0, float(region_hp.get(rk, 40.0)) - loss * 0.85)
			return
	region_hp["torso"] = maxf(1.0, float(region_hp.get("torso", 65.0)) - loss * 0.75)

func _tick_anatomical_recovery(dt: float) -> void:
	if wounds.is_empty():
		return
	var changed := false
	for i in range(wounds.size() - 1, -1, -1):
		var w: Dictionary = wounds[i]
		var w_type: String = str(w.get("type", "scratch"))
		if w_type == "lodged_arrow":
			continue
		var is_bandaged: bool = bool(w.get("bandaged", false))
		var is_stitched: bool = bool(w.get("stitched", false))
		var is_splinted: bool = bool(w.get("splinted", false))
		if is_bandaged:
			w["bandage_dirty"] = minf(100.0, float(w.get("bandage_dirty", 0.0)) + dt * 0.45)
		# Estilo Project Zomboid: las heridas sin tratar NO desaparecen solas mágicamente en segundos
		if not is_bandaged and not is_stitched and not is_splinted:
			continue
		var rate: float = 0.22
		if is_bandaged:
			rate = 0.48
		if is_stitched:
			rate = 0.72
		if w_type == "fracture":
			rate = 0.32 if is_splinted else 0.0
		if rate <= 0.0:
			continue
		var new_sev: float = float(w.get("severity", 10.0)) - rate * dt
		var r_key: String = str(w.get("region", "torso"))
		var m_hp2: float = float(REGION_DEFS.get(r_key, {"max_hp": 50.0})["max_hp"])
		region_hp[r_key] = minf(m_hp2, float(region_hp.get(r_key, m_hp2)) + rate * dt * 0.35)
		if new_sev <= 0.0:
			wounds.remove_at(i)
			changed = true
		else:
			w["severity"] = new_sev
			w["pain"] = maxf(1.0, float(w.get("pain", 6.0)) - rate * dt * 0.30)
	if changed:
		anatomy_changed.emit()

func take_damage(data: DamageData) -> void:
	if current_health <= 0.0:
		return

	# 1. Aplicar daño directo a la vida (mitigado por la armadura equipada)
	var dmg_mult: float = clampf(1.0 - armor_defense, 0.20, 1.0)
	var final_damage: float = maxf(1.0, data.amount * dmg_mult) if data.amount > 0.0 else 0.0
	if final_damage > 0.0:
		_inflict_anatomical_wound(data, final_damage)
	current_health = max(0.0, current_health - final_damage)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0.0:
		is_bleeding = false
		died.emit()
		return
	
	# 2. Acumular sangrado según la estadística del arma (mitigado por resistencia al sangrado de armadura)
	var buildup: float = data.bleed_buildup
	if buildup <= 0.0 and data.type == CombatConstants.DamageType.CUT and data.bleed_chance > 0.0:
		buildup = data.amount * 3.0

	buildup *= clampf(1.0 - armor_bleed_resistance, 0.10, 1.0)
	if buildup > 0.0:
		add_bleed_buildup(buildup, final_damage)

func _pick_hit_region(data: DamageData) -> String:
	var roll: float = randf()
	var acc: float = 0.0
	if data and data.stun_buildup >= 35.0 and randf() < 0.38:
		return "head"
	for r_id in REGION_ORDER:
		acc += float(REGION_DEFS[r_id]["weight"])
		if roll <= acc:
			return r_id
	return "torso"

func _inflict_anatomical_wound(data: DamageData, final_damage: float) -> void:
	var r_id: String = _pick_hit_region(data)
	var max_r: float = float(REGION_DEFS[r_id]["max_hp"])
	var cur_r: float = float(region_hp.get(r_id, max_r))
	var reg_loss: float = maxf(2.0, final_damage * 1.15)
	if cur_r - reg_loss < 0.0 and r_id != "torso":
		var overflow: float = reg_loss - cur_r
		region_hp[r_id] = 0.0
		var max_t: float = float(REGION_DEFS["torso"]["max_hp"])
		region_hp["torso"] = maxf(0.0, float(region_hp.get("torso", max_t)) - overflow)
	else:
		region_hp[r_id] = maxf(0.0, cur_r - reg_loss)

	var w_tag: String = str(data.weapon_tag) if data else ""
	if w_tag == "" and data and is_instance_valid(data.source):
		if "equipped_weapon" in data.source and data.source.get("equipped_weapon") != null:
			var ew: Variant = data.source.get("equipped_weapon")
			w_tag = str(ew.get("weapon_name") if "weapon_name" in ew else "Arma")
		elif "npc_name" in data.source:
			w_tag = str(data.source.get("npc_name"))
		else:
			w_tag = str(data.source.name)
	if w_tag == "":
		w_tag = "Impacto Cortante" if (data and data.type == CombatConstants.DamageType.CUT) else "Golpe Contundente"

	var w_type := "scratch"
	var custom_w_name := ""
	var bleed_r: float = 0.0
	var pain_v: float = clampf(final_damage * 0.95, 6.0, 42.0)
	var sev_v: float = clampf(final_damage * 2.1, 18.0, 98.0)
	var low_tag := w_tag.to_lower()
	var is_bullet: bool = ("pistola" in low_tag or "disparo" in low_tag or "bala" in low_tag)
	var is_arrow: bool = ("arco" in low_tag or "flecha" in low_tag)

	if data and data.type == CombatConstants.DamageType.CUT:
		if is_bullet:
			w_type = "deep_wound"
			custom_w_name = "Herida de Bala"
			bleed_r = 2.2
			pain_v = maxf(pain_v, 24.0)
			sev_v = maxf(sev_v, 48.0)
		elif is_arrow:
			w_type = "lodged_arrow"
			bleed_r = 1.5
			pain_v = maxf(pain_v, 20.0)
			sev_v = maxf(sev_v, 42.0)
		elif final_damage >= 14.0 or data.bleed_buildup >= 32.0:
			w_type = "deep_wound"
			bleed_r = 2.4
			pain_v = maxf(pain_v, 22.0)
		elif final_damage >= 5.5 or data.bleed_buildup >= 12.0:
			w_type = "laceration"
			bleed_r = 1.2
		else:
			w_type = "scratch"
			bleed_r = 0.5
	else:
		var new_ratio: float = float(region_hp.get(r_id, max_r)) / maxf(1.0, max_r)
		if final_damage >= 15.0 or (new_ratio < 0.68 and final_damage >= 8.0 and randf() < 0.50) or (r_id in ["left_leg", "right_leg", "left_arm", "right_arm"] and final_damage >= 10.0 and randf() < 0.42):
			w_type = "fracture"
			if r_id == "head":
				custom_w_name = "Conmoción / Fisura Craneal"
			pain_v = maxf(pain_v, 24.0)
			sev_v = maxf(sev_v, 48.0)
		else:
			w_type = "bruise"

	var organ_hit := ""
	var organ_chance: float = 0.55 if (is_bullet or is_arrow) else (0.38 if final_damage >= 8.0 else 0.18)
	if r_id in ["head", "torso"] and randf() < organ_chance:
		var cand_organs: Array = ["eyes", "brain"] if r_id == "head" else ["lungs", "stomach", "liver", "kidneys", "heart"]
		organ_hit = str(cand_organs[randi() % cand_organs.size()])
		var o_loss: float = clampf(final_damage * 1.45, 14.0, 52.0)
		organ_hp[organ_hit] = maxf(10.0, float(organ_hp.get(organ_hit, 100.0)) - o_loss)

	var w_entry: Dictionary = {
		"id": _next_wound_id,
		"region": r_id,
		"organ": organ_hit,
		"type": w_type,
		"name": custom_w_name if custom_w_name != "" else str(WOUND_NAMES.get(w_type, "Herida")),
		"severity": sev_v,
		"bleed_rate": bleed_r,
		"pain": pain_v,
		"bandaged": false,
		"bandage_dirty": 0.0,
		"stitched": false,
		"splinted": false,
		"clean": false,
		"infection": 0.0,
		"weapon_cause": w_tag
	}
	_next_wound_id += 1
	wounds.append(w_entry)
	while wounds.size() > 14:
		wounds.pop_front()
	anatomy_changed.emit()

func add_bleed_buildup(buildup_amount: float, weapon_damage: float) -> void:
	var weapon_bleed_dps = max(1.5, weapon_damage * bleed_damage_multiplier)

	if is_bleeding:
		# Si ya está sangrando, refresca parcialmente el sangrado y mantiene el mayor DPS
		_bleed_dps = max(_bleed_dps, weapon_bleed_dps)
		_bleed_timer = min(bleed_duration, _bleed_timer + bleed_duration * 0.35)
		return

	current_blood = min(max_blood, current_blood + buildup_amount)
	blood_changed.emit(current_blood, max_blood)

	if current_blood >= max_blood:
		# Se llenó la barra: activar estado de sangrado
		is_bleeding = true
		_bleed_timer = bleed_duration
		_bleed_dps = weapon_bleed_dps
		if not is_weak:
			is_weak = true
			weakness_changed.emit(true)
		bleed_triggered.emit(_bleed_dps)

func heal(amount: float, clear_all_wounds: bool = false) -> void:
	current_health = clamp(current_health + amount, 0.0, max_health)
	if clear_all_wounds:
		_init_anatomy()
		health_changed.emit(current_health, max_health)
		anatomy_changed.emit()
		return
	var missing_regions: Array[String] = []
	for r_id in REGION_ORDER:
		var m_r: float = float(REGION_DEFS[r_id]["max_hp"])
		if float(region_hp.get(r_id, m_r)) < m_r - 0.1:
			missing_regions.append(r_id)
	if not missing_regions.is_empty():
		var share: float = (amount * 1.1) / float(missing_regions.size())
		for r_id in missing_regions:
			var m_r2: float = float(REGION_DEFS[r_id]["max_hp"])
			region_hp[r_id] = minf(m_r2, float(region_hp.get(r_id, m_r2)) + share)
	for i in range(wounds.size() - 1, -1, -1):
		var w: Dictionary = wounds[i]
		# Solo las heridas tratadas reducen su severidad al curarse con comida/descanso
		if bool(w.get("bandaged", false)) or bool(w.get("stitched", false)) or bool(w.get("splinted", false)):
			var s_after: float = float(w.get("severity", 10.0)) - amount * 0.35
			if s_after <= 0.0:
				wounds.remove_at(i)
			else:
				w["severity"] = s_after
				w["pain"] = maxf(1.0, float(w.get("pain", 5.0)) - amount * 0.15)
	health_changed.emit(current_health, max_health)
	anatomy_changed.emit()

## Estabiliza al personaje tras caer abatido por la Guardia (sin borrar sus heridas, fracturas ni daño a órganos)
func stabilize_after_knockout(target_ratio: float = 0.45) -> void:
	is_bleeding = false
	_bleed_timer = 0.0
	_bleed_dps = 0.0
	current_blood = 0.0
	blood_changed.emit(current_blood, max_blood)
	if is_weak:
		is_weak = false
		weakness_changed.emit(false)
	current_health = maxf(current_health, max_health * target_ratio)
	for r_id in REGION_ORDER:
		var m_r: float = float(REGION_DEFS[r_id]["max_hp"])
		region_hp[r_id] = maxf(float(region_hp.get(r_id, m_r)), m_r * 0.30)
	health_changed.emit(current_health, max_health)
	anatomy_changed.emit()

func stop_bleeding() -> void:
	is_bleeding = false
	_bleed_timer = 0.0
	_bleed_dps = 0.0
	current_blood = 0.0
	for w in wounds:
		if float(w.get("bleed_rate", 0.0)) > 0.0:
			w["bandaged"] = true
			w["bleed_rate"] = 0.0
	blood_changed.emit(current_blood, max_blood)
	if is_weak:
		is_weak = false
		weakness_changed.emit(false)
	anatomy_changed.emit()

func modify_blood(amount: float) -> void:
	if amount > 0.0:
		stop_bleeding()
	else:
		add_bleed_buildup(-amount, 10.0)

func get_region_ratio(r_id: String) -> float:
	var m_r: float = float(REGION_DEFS.get(r_id, {"max_hp": 45.0})["max_hp"])
	return clampf(float(region_hp.get(r_id, m_r)) / maxf(1.0, m_r), 0.0, 1.0)

func get_total_pain() -> float:
	var p: float = 0.0
	for w in wounds:
		var mult: float = 0.65 if (bool(w.get("bandaged", false)) or bool(w.get("stitched", false)) or bool(w.get("splinted", false))) else 1.0
		p += float(w.get("pain", 0.0)) * mult
	return clampf(p, 0.0, 100.0)

func get_capacities() -> Dictionary:
	var pain_pen: float = clampf(get_total_pain() / 160.0, 0.0, 0.45)
	var blood_pen: float = 0.20 if is_bleeding else clampf((current_blood / maxf(1.0, max_blood)) * 0.15, 0.0, 0.15)
	var brain_r: float = clampf(float(organ_hp.get("brain", 100.0)) / 100.0, 0.1, 1.0)
	var consciousness: float = clampf(brain_r * (1.0 - pain_pen * 0.85 - blood_pen), 0.15, 1.0)

	var l_leg: float = get_region_ratio("left_leg")
	var r_leg: float = get_region_ratio("right_leg")
	var leg_frac_pen: float = 0.0
	var arm_frac_pen: float = 0.0
	for w in wounds:
		var wt: String = str(w.get("type", ""))
		var wr: String = str(w.get("region", ""))
		if wt == "fracture":
			var fp: float = 0.14 if bool(w.get("splinted", false)) else 0.30
			if wr in ["left_leg", "right_leg"]:
				leg_frac_pen += fp
			elif wr in ["left_arm", "right_arm"]:
				arm_frac_pen += fp
	var moving: float = clampf(((l_leg + r_leg) * 0.5) * (1.0 - leg_frac_pen - pain_pen * 0.4), 0.32, 1.0)

	var l_arm: float = get_region_ratio("left_arm")
	var r_arm: float = get_region_ratio("right_arm")
	var manipulation: float = clampf(((l_arm + r_arm) * 0.5) * (1.0 - arm_frac_pen - pain_pen * 0.35), 0.35, 1.0)

	var heart_r: float = float(organ_hp.get("heart", 100.0)) / 100.0
	var lungs_r: float = float(organ_hp.get("lungs", 100.0)) / 100.0
	var breathing: float = clampf((heart_r + lungs_r) * 0.5, 0.20, 1.0)

	var liver_r: float = float(organ_hp.get("liver", 100.0)) / 100.0
	var kidneys_r: float = float(organ_hp.get("kidneys", 100.0)) / 100.0
	var filtration: float = clampf((liver_r + kidneys_r) * 0.5, 0.20, 1.0)

	return {
		"consciousness": consciousness,
		"moving": moving,
		"manipulation": manipulation,
		"breathing": breathing,
		"filtration": filtration
	}

func get_moving_capacity() -> float:
	return float(get_capacities().get("moving", 1.0))

func get_manipulation_capacity() -> float:
	return float(get_capacities().get("manipulation", 1.0))

func treat_wound(wound_id: int, action: String) -> bool:
	for i in range(wounds.size()):
		var w: Dictionary = wounds[i]
		if int(w.get("id", -1)) != wound_id:
			continue
		match action:
			"wash":
				w["clean"] = true
				w["bandage_dirty"] = 0.0
				w["infection"] = maxf(0.0, float(w.get("infection", 0.0)) - 20.0)
			"bandage":
				w["bandaged"] = true
				w["bandage_dirty"] = 0.0
				w["bleed_rate"] = 0.0
				w["pain"] = maxf(1.0, float(w.get("pain", 6.0)) * 0.72)
				heal(8.0)
			"poultice":
				w["clean"] = true
				w["bandaged"] = true
				w["bandage_dirty"] = 0.0
				w["bleed_rate"] = 0.0
				w["infection"] = 0.0
				w["severity"] = maxf(2.0, float(w.get("severity", 20.0)) * 0.55)
				w["pain"] = maxf(1.0, float(w.get("pain", 8.0)) * 0.50)
				heal(16.0)
			"stitch":
				if str(w.get("type", "")) == "lodged_arrow":
					w["type"] = "laceration"
					w["name"] = "Laceración (Flecha Extraída)"
				w["stitched"] = true
				w["bandaged"] = true
				w["clean"] = true
				w["bleed_rate"] = 0.0
				w["severity"] = maxf(2.0, float(w.get("severity", 25.0)) * 0.45)
				w["pain"] = maxf(1.0, float(w.get("pain", 10.0)) * 0.55)
				heal(24.0)
			"splint":
				w["splinted"] = true
				w["pain"] = maxf(2.0, float(w.get("pain", 18.0)) * 0.60)
		var any_bleed := false
		for cw in wounds:
			if float(cw.get("bleed_rate", 0.0)) > 0.0 and not bool(cw.get("bandaged", false)) and not bool(cw.get("stitched", false)):
				any_bleed = true
				break
		if not any_bleed and is_bleeding:
			stop_bleeding()
		anatomy_changed.emit()
		return true
	return false

func get_forensic_autopsy_summary() -> String:
	if wounds.is_empty():
		return "Sin traumatismos externos registrados"
	var parts: Array[String] = []
	for i in range(maxi(0, wounds.size() - 3), wounds.size()):
		var w: Dictionary = wounds[i]
		var r_name: String = str(REGION_DEFS.get(str(w.get("region", "torso")), {"name": "Torso"})["name"])
		var o_id: String = str(w.get("organ", ""))
		var o_tag: String = (" [Órgano: %s]" % str(ORGAN_DEFS[o_id]["name"])) if (o_id != "" and ORGAN_DEFS.has(o_id)) else ""
		parts.append("%s en %s%s (%s)" % [str(w.get("name", "Herida")), r_name, o_tag, str(w.get("weapon_cause", "Arma"))])
	return "; ".join(parts)

func to_medical_dict() -> Dictionary:
	var w_copy: Array = []
	for w in wounds:
		w_copy.append(w.duplicate())
	return {
		"region_hp": region_hp.duplicate(),
		"organ_hp": organ_hp.duplicate(),
		"wounds": w_copy,
		"next_id": _next_wound_id
	}

func from_medical_dict(data: Dictionary) -> void:
	_init_anatomy()
	if data.is_empty():
		return
	if data.has("region_hp") and typeof(data["region_hp"]) == TYPE_DICTIONARY:
		var r_in: Dictionary = data["region_hp"]
		for k in REGION_ORDER:
			if r_in.has(k):
				region_hp[k] = clampf(float(r_in[k]), 0.0, float(REGION_DEFS[k]["max_hp"]))
	if data.has("organ_hp") and typeof(data["organ_hp"]) == TYPE_DICTIONARY:
		var o_in: Dictionary = data["organ_hp"]
		for ok in ORGAN_DEFS.keys():
			if o_in.has(ok):
				organ_hp[ok] = clampf(float(o_in[ok]), 0.0, 100.0)
	if data.has("wounds") and typeof(data["wounds"]) == TYPE_ARRAY:
		for raw_w in (data["wounds"] as Array):
			if typeof(raw_w) == TYPE_DICTIONARY:
				wounds.append((raw_w as Dictionary).duplicate())
	_next_wound_id = maxi(1, int(data.get("next_id", wounds.size() + 1)))
	anatomy_changed.emit()
