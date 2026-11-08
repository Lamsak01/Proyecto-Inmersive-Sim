extends Node
class_name HealthComponent

signal died
signal health_changed(current, max)
signal blood_changed(current, max)
signal weakness_changed(is_weak)
@warning_ignore("unused_signal")
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
var fever: float = 0.0 ## Fiebre sistémica (0..100%) por infección de heridas, miasma o intoxicación
var food_poisoning: float = 0.0 ## Intoxicación alimentaria / veneno digestivo (0..100%)
var swamp_sickness: float = 0.0 ## Fiebre del pantano / miasma cadavérico (0..100%)
var systemic_immunity: float = 0.0 ## Inmunidad sistémica desarrollada (0..100%) estilo RimWorld
var systemic_tend_quality: float = 0.0 ## Calidad del tratamiento médico sobre enfermedad sistémica (0..130%)
var is_resting_in_bed: bool = false ## Multiplica x1.45 la velocidad de ganancia de Inmunidad y regeneración de sangre
var last_sickness_cause: String = ""
var last_death_reason: String = ""
var _next_wound_id: int = 1
var _med_tick_accum: float = 0.0
var _bleed_notify_accum: float = 0.0

func _ready() -> void:
	current_health = max_health
	current_blood = 0.0
	_init_anatomy()
	if Engine.is_editor_hint():
		set_process(false)

## Tope de vida de un miembro amputado (0) o con prótesis (parte del máximo); si no está, manda REGION_DEFS
var region_max_override: Dictionary = {}

func region_max(r_id: String) -> float:
	if region_max_override.has(r_id):
		return float(region_max_override[r_id])
	return float(REGION_DEFS.get(r_id, {"max_hp": 45.0})["max_hp"])

func _init_anatomy() -> void:
	for r_id in REGION_ORDER:
		region_hp[r_id] = region_max(r_id)
	for o_id in ORGAN_DEFS.keys():
		organ_hp[o_id] = 100.0
	wounds.clear()
	fever = 0.0
	food_poisoning = 0.0
	swamp_sickness = 0.0
	systemic_immunity = 0.0
	systemic_tend_quality = 0.0
	last_sickness_cause = ""
	last_death_reason = ""

func get_total_wound_bleed_rate() -> float:
	var total_r: float = 0.0
	for w in wounds:
		if not bool(w.get("bandaged", false)) and not bool(w.get("stitched", false)):
			total_r += float(w.get("bleed_rate", 0.0))
	return total_r

func get_bleedout_eta_seconds() -> float:
	var rate: float = get_total_wound_bleed_rate()
	if rate <= 0.001:
		return -1.0
	return maxf(0.0, (max_blood - current_blood) / rate)

func get_blood_loss_stage_name() -> String:
	if current_blood < 15.0:
		return "Estable"
	elif current_blood < 30.0:
		return "Leve (Minor)"
	elif current_blood < 45.0:
		return "Moderada (Moderate)"
	elif current_blood < 60.0:
		return "Severa (Severe)"
	return "Extrema (Extreme)"

## En RimWorld, estar enfermo o con infección severa reduce simbólicamente tu tope de resistencia física (hasta un 50%),
## haciendo que aguantes menos golpes sin drenar tu vida a 0 por segundo; la infección solo mata si llega al 100% antes que la Inmunidad.
func get_effective_max_health() -> float:
	var max_inf: float = get_max_wound_infection()
	var sick_factor: float = maxf(max_inf, maxf(fever, maxf(food_poisoning * 0.85, swamp_sickness * 0.90))) / 100.0
	var cap_mult: float = clampf(1.0 - sick_factor * 0.50, 0.50, 1.0)
	return maxf(25.0, max_health * cap_mult)

## Porcentaje de salud actual (0..100) respecto al tope efectivo; lo usa el poder de pelea de `SocialDirector`.
func get_overall_health_pct() -> float:
	return clampf(current_health / get_effective_max_health() * 100.0, 0.0, 100.0)

func _is_player_test_mode() -> bool:
	var p := get_parent()
	return p != null and p.get("test_mode_active") == true

## Contusión leve de una pelea: sin fracturas, órganos ni sangrado, y nunca baja de `floor_ratio` de la salud. Devuelve el daño real.
func apply_minor_bruise(amount: float, floor_ratio: float = 0.35, cause: String = "Pelea a puñetazos") -> float:
	if _is_player_test_mode():
		return 0.0
	var dealt: float = minf(amount, current_health - get_effective_max_health() * floor_ratio)
	if dealt <= 0.0:
		return 0.0
	current_health -= dealt
	var r_id: String = ["torso", "left_arm", "right_arm"][randi() % 3]
	region_hp[r_id] = maxf(1.0, float(region_hp.get(r_id, 40.0)) - dealt)
	wounds.append({
		"id": _next_wound_id, "region": r_id, "organ": "", "type": "bruise",
		"name": str(WOUND_NAMES["bruise"]), "severity": 18.0, "bleed_rate": 0.0, "pain": 6.0,
		"bandaged": false, "bandage_dirty": 0.0, "stitched": false, "splinted": false, "clean": false,
		"infection": 0.0, "immunity": 0.0, "tend_quality": 0.0, "tend_tier": "none", "weapon_cause": cause,
	})
	_next_wound_id += 1
	while wounds.size() > 14:
		wounds.pop_front()
	health_changed.emit(current_health, max_health)
	anatomy_changed.emit()
	return dealt

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or current_health <= 0.0 or (WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen()):
		return
	if _is_player_test_mode():
		var changed_tm := false
		if current_health < max_health:
			current_health = max_health
			health_changed.emit(current_health, max_health)
		if current_blood > 0.0 or is_bleeding:
			current_blood = 0.0
			is_bleeding = false
			_bleed_timer = 0.0
			_bleed_dps = 0.0
			blood_changed.emit(current_blood, max_blood)
			changed_tm = true
		if is_weak:
			is_weak = false
			weakness_changed.emit(false)
		if fever > 0.0 or food_poisoning > 0.0 or swamp_sickness > 0.0:
			fever = 0.0
			food_poisoning = 0.0
			swamp_sickness = 0.0
			changed_tm = true
		for w in wounds:
			if float(w.get("bleed_rate", 0.0)) > 0.0 or float(w.get("infection", 0.0)) > 0.0:
				w["bleed_rate"] = 0.0
				w["infection"] = 0.0
				changed_tm = true
		if changed_tm:
			anatomy_changed.emit()
		return

	if _bleed_timer > 0.0:
		_bleed_timer = maxf(0.0, _bleed_timer - delta)
		if _bleed_timer <= 0.0:
			_bleed_dps = 0.0

	var wound_bleed_rate: float = get_total_wound_bleed_rate()

	if wound_bleed_rate > 0.0:
		is_bleeding = true
		current_blood = clampf(current_blood + wound_bleed_rate * delta, 0.0, max_blood)
		blood_changed.emit(current_blood, max_blood)
		if current_blood >= 30.0 and not is_weak:
			is_weak = true
			weakness_changed.emit(true)

		_bleed_notify_accum += delta
		if _bleed_notify_accum >= 6.0:
			_bleed_notify_accum = 0.0
			var parent_n := get_parent()
			if is_instance_valid(parent_n) and parent_n.has_method("_spawn_floating_text"):
				var eta_s: int = int(ceil(get_bleedout_eta_seconds()))
				var is_p: bool = parent_n.is_in_group("player")
				var msg: String = ("🩸 Pérdida de Sangre: %d%% (%s — Desangrado en %ds)" % [int(round(current_blood)), get_blood_loss_stage_name(), eta_s]) if is_p else ("🩸 Sangrando (%d%% — %ds)" % [int(round(current_blood)), eta_s])
				parent_n.call("_spawn_floating_text", msg, Color(1.0, 0.28, 0.32), -38.0)

		# Muerte fisiológica por Exsanguinación al llegar al 100% de Pérdida de Sangre (RimWorld)
		if current_blood >= max_blood:
			is_bleeding = false
			last_death_reason = "Exsanguinación (100% Pérdida de Sangre)"
			current_health = 0.0
			health_changed.emit(current_health, max_health)
			died.emit()
			return
	else:
		_bleed_notify_accum = 0.0
		if is_bleeding:
			is_bleeding = false
			_bleed_dps = 0.0
			anatomy_changed.emit()
		if current_blood > 0.0:
			# Recuperación hematopoyética realista (~36% por día de juego, o x1.8 descansando en cama)
			var regen_rate: float = 0.10 * (1.8 if is_resting_in_bed else 1.0)
			current_blood = maxf(0.0, current_blood - regen_rate * delta)
			blood_changed.emit(current_blood, max_blood)
			if current_blood < 30.0 and is_weak:
				is_weak = false
				weakness_changed.emit(false)

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
	var changed := false
	var filt: float = clampf((float(organ_hp.get("liver", 100.0)) + float(organ_hp.get("kidneys", 100.0))) / 200.0, 0.25, 1.0)
	var bed_imm_mult: float = 1.45 if is_resting_in_bed else 1.0
	var max_wound_inf: float = 0.0
	var max_wound_imm: float = 0.0

	for i in range(wounds.size() - 1, -1, -1):
		var w: Dictionary = wounds[i]
		var w_type: String = str(w.get("type", "scratch"))
		var is_bandaged: bool = bool(w.get("bandaged", false))
		var is_stitched: bool = bool(w.get("stitched", false))
		var is_splinted: bool = bool(w.get("splinted", false))
		var is_clean: bool = bool(w.get("clean", false))
		var tend_q: float = float(w.get("tend_quality", 0.0))
		var tend_tier: String = str(w.get("tend_tier", "none"))
		if is_bandaged:
			var dirty_spd: float = 0.55 if tend_tier == "makeshift" else 0.25
			w["bandage_dirty"] = minf(100.0, float(w.get("bandage_dirty", 0.0)) + dt * dirty_spd)
		var dirty_band: bool = is_bandaged and float(w.get("bandage_dirty", 0.0)) >= 55.0

		# Carrera Infección vs Inmunidad estilo RimWorld:
		# - Sin tratar (o vendaje rudimentario sucio), la infección avanza (~0.28%/s -> ~6 min reales = 1 día de juego).
		# - Tratar la herida frena el avance de la infección según la Calidad del Tratamiento (`tend_quality`),
		#   dando tiempo a que la Inmunidad (`immunity`) llegue al 100% y venza la infección.
		if w_type in ["scratch", "laceration", "deep_wound", "lodged_arrow"]:
			var cur_inf: float = float(w.get("infection", 0.0))
			var cur_imm: float = float(w.get("immunity", 0.0))
			var can_infect: bool = (not is_bandaged and not is_stitched and not is_clean) or dirty_band or tend_tier == "makeshift" or w_type == "lodged_arrow" or cur_inf > 0.0
			if can_infect:
				var tend_slow: float = lerpf(1.0, 0.20, clampf(tend_q / 100.0, 0.0, 1.0))
				if dirty_band:
					tend_slow = maxf(tend_slow, 0.78)
				var base_inf_spd: float = 0.28 if (not is_clean or dirty_band) else 0.16
				var inf_gain: float = (base_inf_spd * tend_slow) / maxf(0.40, filt)
				cur_inf = minf(100.0, cur_inf + inf_gain * dt)
				if cur_inf >= 5.0:
					var imm_gain: float = 0.33 * filt * bed_imm_mult * (1.15 if is_clean else 0.92)
					cur_imm = minf(100.0, cur_imm + imm_gain * dt)
					if cur_imm >= 100.0:
						# ¡Ganó la carrera de Inmunidad! La infección desaparece (RimWorld)
						cur_inf = 0.0
						cur_imm = 100.0
						w["clean"] = true
						w["bandage_dirty"] = 0.0
						changed = true
					elif cur_inf >= 100.0:
						# La infección llegó al 100% antes que la Inmunidad -> Muerte por Sepsis
						w["infection"] = 100.0
						last_death_reason = "Sepsis / Infección Letal (100%% en %s)" % str(w.get("name", "Herida"))
						current_health = 0.0
						health_changed.emit(current_health, max_health)
						died.emit()
						return
			if absf(cur_inf - float(w.get("infection", 0.0))) > 0.4 or absf(cur_imm - float(w.get("immunity", 0.0))) > 0.4:
				changed = true
			w["infection"] = cur_inf
			w["immunity"] = cur_imm
			max_wound_inf = maxf(max_wound_inf, cur_inf)
			max_wound_imm = maxf(max_wound_imm, cur_imm)

		if w_type == "lodged_arrow" or (not is_bandaged and not is_stitched and not is_splinted):
			continue
		var rate: float = 0.14
		if is_bandaged:
			rate = 0.12 if (dirty_band or tend_tier == "makeshift") else lerpf(0.24, 0.55, clampf(tend_q / 100.0, 0.0, 1.0))
		if is_stitched:
			rate = 0.68
		if w_type == "fracture":
			rate = 0.28 if is_splinted else 0.0
		if float(w.get("infection", 0.0)) >= 40.0:
			rate *= 0.45
		if is_resting_in_bed:
			rate *= 1.35
		if rate <= 0.0:
			continue
		var new_sev: float = float(w.get("severity", 10.0)) - rate * dt
		var r_key: String = str(w.get("region", "torso"))
		var m_hp2: float = region_max(r_key) if REGION_DEFS.has(r_key) else 50.0
		region_hp[r_key] = minf(m_hp2, float(region_hp.get(r_key, m_hp2)) + rate * dt * 0.35)
		if new_sev <= 0.0 and float(w.get("infection", 0.0)) < 15.0:
			wounds.remove_at(i)
			changed = true
		else:
			w["severity"] = maxf(1.0, new_sev)
			w["pain"] = maxf(1.0, float(w.get("pain", 6.0)) - rate * dt * 0.30)

	# Evolución de intoxicación alimentaria, fiebre del pantano/miasma y carrera de inmunidad sistémica
	var sys_sick: float = maxf(food_poisoning, swamp_sickness)
	if sys_sick > 0.0 or fever > 0.0:
		var sys_slow: float = lerpf(1.0, 0.25, clampf(systemic_tend_quality / 100.0, 0.0, 1.0))
		if sys_sick > 0.0 and systemic_immunity < 100.0:
			systemic_immunity = minf(100.0, systemic_immunity + 0.34 * filt * bed_imm_mult * dt)
			if systemic_tend_quality < 20.0 and not is_resting_in_bed:
				fever = minf(100.0, fever + 0.22 * sys_slow / maxf(0.4, filt) * dt)
		if systemic_immunity >= 100.0:
			food_poisoning = maxf(0.0, food_poisoning - 1.2 * dt)
			swamp_sickness = maxf(0.0, swamp_sickness - 1.2 * dt)
			fever = maxf(0.0, fever - 1.4 * dt)
			if food_poisoning <= 0.1 and swamp_sickness <= 0.1 and fever <= 0.1:
				systemic_immunity = 0.0
				systemic_tend_quality = 0.0
			changed = true
		else:
			if food_poisoning > 0.0:
				food_poisoning = maxf(0.0, food_poisoning - 0.18 * filt * dt)
			if swamp_sickness > 0.0:
				swamp_sickness = maxf(0.0, swamp_sickness - 0.15 * filt * dt)

	var target_fever: float = maxf(max_wound_inf * 0.88, maxf(food_poisoning * 0.65, swamp_sickness * 0.80))
	if target_fever > fever + 1.5:
		fever = minf(100.0, fever + (0.28 / maxf(0.35, filt)) * dt)
		changed = true
	elif fever > 0.0 and target_fever < fever - 1.0:
		fever = maxf(0.0, fever - 0.35 * filt * dt)
		changed = true

	# Reducción simbólica del tope de resistencia física mientras está enfermo/infectado (RimWorld: aguantas menos golpes, pero solo mueres si la infección llega al 100%)
	var eff_max: float = get_effective_max_health()
	if current_health > eff_max:
		current_health = eff_max
		health_changed.emit(current_health, max_health)

	if fever >= 100.0 and systemic_immunity < 100.0 and max_wound_imm < 100.0:
		last_death_reason = "Fiebre / Sepsis Sistémica Letal (100%% — %s)" % (last_sickness_cause if last_sickness_cause != "" else "Infección")
		current_health = 0.0
		health_changed.emit(current_health, max_health)
		died.emit()
		return

	if changed:
		anatomy_changed.emit()

func take_damage(data: DamageData) -> void:
	if _is_player_test_mode():
		current_health = max_health
		health_changed.emit(current_health, max_health)
		return
	if current_health <= 0.0:
		return

	# 1. Aplicar daño directo a la resistencia física (limitada por `get_effective_max_health()` si está enfermo/infectado)
	var dmg_mult: float = clampf(1.0 - armor_defense, 0.20, 1.0)
	var final_damage: float = maxf(1.0, data.amount * dmg_mult) if data.amount > 0.0 else 0.0
	if final_damage > 0.0:
		_inflict_anatomical_wound(data, final_damage)
	current_health = clampf(current_health - final_damage, 0.0, get_effective_max_health())
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0.0:
		is_bleeding = false
		last_death_reason = "Trauma Físico Letal"
		died.emit()
		return
	
	# 2. En RimWorld, los impactos cortantes aumentan levemente la pérdida inicial de sangre (`current_blood`),
	# mientras que la hemorragia continua depende de la tasa de sangrado (`bleed_rate`) de las heridas abiertas.
	var buildup: float = data.bleed_buildup
	if buildup <= 0.0 and data.type == CombatConstants.DamageType.CUT and data.bleed_chance > 0.0:
		buildup = data.amount * 1.5

	buildup *= clampf(1.0 - armor_bleed_resistance, 0.10, 1.0)
	if buildup > 0.0:
		add_bleed_buildup(buildup * 0.16, final_damage)

## C7 fase 4a: la zona herida depende de desde dónde llega el golpe. Pesos por zona para este golpe:
## - Atacantes bajos (animales, mascotas, jabalíes): sobre todo piernas.
## - Por la espalda (el herido mira hacia otro lado): espalda y nuca; los brazos no llegan a cubrir.
## - Por un costado: el brazo y la pierna de ese lado.
## - Herido en el suelo: la cabeza queda a tiro.
var last_hit_context: String = "" ## "espalda", "bajo", "costado" o "" (para el nombre de la herida)

func _owner_facing() -> Vector2:
	var o: Node = get_parent()
	if o == null:
		return Vector2.ZERO
	var f = o.get("facing_dir")
	if f is Vector2:
		return f
	var cc: Node = o.get_node_or_null("PlayerCombatController")
	if cc != null and cc.get("current_aim_dir") is Vector2:
		return cc.get("current_aim_dir")
	return Vector2.ZERO

func hit_region_weights(data: DamageData) -> Dictionary:
	var w: Dictionary = {}
	for r_id in REGION_ORDER:
		w[r_id] = float(REGION_DEFS[r_id]["weight"])
	last_hit_context = ""
	var o: Node = get_parent()
	if data == null or not is_instance_valid(data.source) or not (data.source is Node2D) or not (o is Node2D):
		return w
	var src: Node2D = data.source as Node2D
	var low: bool = src.is_in_group("wild_animals") or src.is_in_group("domestic_pets") or (src.is_in_group("raiders") and str(src.get("kind")) == "boar")
	if low:
		w["left_leg"] *= 3.0
		w["right_leg"] *= 3.0
		w["left_arm"] *= 0.7
		w["right_arm"] *= 0.7
		w["head"] *= 0.15
		last_hit_context = "bajo"
	var to_src: Vector2 = src.global_position - (o as Node2D).global_position
	var facing: Vector2 = _owner_facing()
	if to_src.length_squared() > 1.0 and facing.length_squared() > 0.01:
		var d: Vector2 = to_src.normalized()
		var fwd: float = facing.normalized().dot(d)
		var right_side: float = facing.normalized().rotated(PI / 2.0).dot(d) # >0: le llega por su derecha
		if fwd < -0.35:
			w["torso"] *= 1.5
			w["head"] *= 1.3
			w["left_arm"] *= 0.5
			w["right_arm"] *= 0.5
			if last_hit_context == "":
				last_hit_context = "espalda"
		elif absf(right_side) > 0.6:
			var side: String = "right" if right_side > 0.0 else "left"
			w[side + "_arm"] *= 1.8
			w[side + "_leg"] *= 1.8
			if last_hit_context == "":
				last_hit_context = "costado"
	if o.get("is_downed") == true:
		w["head"] *= 2.5
	if data.is_aimed_shot:
		w["torso"] *= 2.2
		w["head"] *= 2.0
	return w

func _pick_hit_region(data: DamageData) -> String:
	if data and data.stun_buildup >= 35.0 and randf() < 0.38:
		hit_region_weights(data) # deja el contexto (espalda, bajo…) para el nombre de la herida
		return "head"
	var w: Dictionary = hit_region_weights(data)
	var total: float = 0.0
	for r_id in REGION_ORDER:
		total += float(w[r_id])
	var roll: float = randf() * total
	var acc: float = 0.0
	for r_id in REGION_ORDER:
		acc += float(w[r_id])
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
	var is_bullet: bool = (data != null and data.is_firearm_bullet) or ("pistola" in low_tag or "disparo" in low_tag or "bala" in low_tag or "arcabuz" in low_tag or "fusil" in low_tag or "cartucho" in low_tag)
	var is_arrow: bool = ("arco" in low_tag or "flecha" in low_tag)

	if (data and data.type == CombatConstants.DamageType.CUT) or is_bullet:
		if is_bullet:
			w_type = "deep_wound"
			custom_w_name = "Herida de Bala"
			bleed_r = 1.05 # Hemorragia severa por proyectil de arma de fuego
			pain_v = maxf(pain_v, 30.0)
			sev_v = maxf(sev_v, 60.0)
		elif is_arrow:
			w_type = "lodged_arrow"
			bleed_r = 0.55 # ~180s (3 min reales / 12h de juego)
			pain_v = maxf(pain_v, 20.0)
			sev_v = maxf(sev_v, 42.0)
		elif final_damage >= 14.0 or data.bleed_buildup >= 32.0:
			w_type = "deep_wound"
			bleed_r = 0.78 # ~128s (2.1 min reales / 8.5h de juego)
			pain_v = maxf(pain_v, 22.0)
			sev_v = maxf(sev_v, 45.0)
		elif final_damage >= 5.5 or data.bleed_buildup >= 12.0:
			w_type = "laceration"
			bleed_r = 0.42 # ~238s (4 min reales / 16h de juego por un corte en brazo)
		else:
			w_type = "scratch"
			bleed_r = 0.18 # ~550s (9 min reales)
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
		"immunity": 0.0,
		"tend_quality": 0.0,
		"tend_tier": "none",
		"weapon_cause": w_tag + (" (por la espalda)" if last_hit_context == "espalda" else "")
	}
	_next_wound_id += 1
	wounds.append(w_entry)
	if is_bullet and final_damage >= 22.0:
		var frac_name: String = "Conmoción / Fisura Craneal por Bala" if r_id == "head" else "Fractura Ósea por Bala"
		var frac_entry: Dictionary = {
			"id": _next_wound_id,
			"region": r_id,
			"organ": "",
			"type": "fracture",
			"name": frac_name,
			"severity": clampf(final_damage * 1.4, 38.0, 85.0),
			"bleed_rate": 0.0,
			"pain": 22.0,
			"bandaged": false,
			"bandage_dirty": 0.0,
			"stitched": false,
			"splinted": false,
			"clean": true,
			"infection": 0.0,
			"immunity": 0.0,
			"tend_quality": 0.0,
			"tend_tier": "none",
			"weapon_cause": w_tag
		}
		_next_wound_id += 1
		wounds.append(frac_entry)
	while wounds.size() > 14:
		wounds.pop_front()
	if bleed_r > 0.0:
		is_bleeding = true
		blood_changed.emit(current_blood, max_blood)
	anatomy_changed.emit()

func add_bleed_buildup(buildup_amount: float, _weapon_damage: float) -> void:
	if _is_player_test_mode():
		return
	current_blood = clampf(current_blood + buildup_amount, 0.0, max_blood)
	blood_changed.emit(current_blood, max_blood)
	if current_blood >= 30.0 and not is_weak:
		is_weak = true
		weakness_changed.emit(true)
	if current_blood >= max_blood and current_health > 0.0:
		is_bleeding = false
		last_death_reason = "Exsanguinación (100% Pérdida de Sangre)"
		current_health = 0.0
		health_changed.emit(current_health, max_health)
		died.emit()

func heal(amount: float, clear_all_wounds: bool = false) -> void:
	current_health = clamp(current_health + amount, 0.0, max_health)
	if clear_all_wounds:
		_init_anatomy()
		health_changed.emit(current_health, max_health)
		anatomy_changed.emit()
		return
	var missing_regions: Array[String] = []
	for r_id in REGION_ORDER:
		var m_r: float = region_max(r_id)
		if float(region_hp.get(r_id, m_r)) < m_r - 0.1:
			missing_regions.append(r_id)
	if not missing_regions.is_empty():
		var share: float = (amount * 1.1) / float(missing_regions.size())
		for r_id in missing_regions:
			var m_r2: float = region_max(r_id)
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
	for w in wounds:
		if float(w.get("bleed_rate", 0.0)) > 0.0:
			w["bandaged"] = true
			w["bleed_rate"] = 0.0
	blood_changed.emit(current_blood, max_blood)
	if is_weak:
		is_weak = false
		weakness_changed.emit(false)
	current_health = maxf(current_health, max_health * target_ratio)
	for r_id in REGION_ORDER:
		var m_r: float = region_max(r_id)
		region_hp[r_id] = minf(m_r, maxf(float(region_hp.get(r_id, m_r)), m_r * 0.30))
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
	# Penalización de Conciencia por etapas de Pérdida de Sangre (RimWorld: Minor -10%, Moderate -20%, Severe -40%, Extreme max 15%)
	var blood_pen: float = 0.0
	if current_blood >= 60.0:
		blood_pen = 0.65
	elif current_blood >= 45.0:
		blood_pen = 0.40
	elif current_blood >= 30.0:
		blood_pen = 0.20
	elif current_blood >= 15.0:
		blood_pen = 0.10
	var fever_pen: float = clampf(fever / 100.0, 0.0, 1.0) * 0.32
	var poison_pen: float = clampf(food_poisoning / 100.0, 0.0, 1.0) * 0.22
	var swamp_pen: float = clampf(swamp_sickness / 100.0, 0.0, 1.0) * 0.22
	var brain_r: float = clampf(float(organ_hp.get("brain", 100.0)) / 100.0, 0.1, 1.0)
	var consciousness: float = clampf(brain_r * (1.0 - pain_pen * 0.85 - blood_pen - fever_pen - poison_pen * 0.5), 0.10, 1.0)
	if current_blood >= 60.0:
		consciousness = minf(consciousness, 0.20)

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
	var moving: float = clampf(((l_leg + r_leg) * 0.5) * (1.0 - leg_frac_pen - pain_pen * 0.4 - fever_pen * 0.6 - poison_pen * 0.5), 0.32, 1.0)

	var l_arm: float = get_region_ratio("left_arm")
	var r_arm: float = get_region_ratio("right_arm")
	var manipulation: float = clampf(((l_arm + r_arm) * 0.5) * (1.0 - arm_frac_pen - pain_pen * 0.35 - fever_pen * 0.6 - poison_pen * 0.5), 0.35, 1.0)

	var heart_r: float = float(organ_hp.get("heart", 100.0)) / 100.0
	var lungs_r: float = float(organ_hp.get("lungs", 100.0)) / 100.0
	var breathing: float = clampf((heart_r + lungs_r) * 0.5 * (1.0 - swamp_pen * 0.6), 0.20, 1.0)

	var liver_r: float = float(organ_hp.get("liver", 100.0)) / 100.0
	var kidneys_r: float = float(organ_hp.get("kidneys", 100.0)) / 100.0
	var filtration: float = clampf((liver_r + kidneys_r) * 0.5 * (1.0 - poison_pen * 0.5 - swamp_pen * 0.4), 0.20, 1.0)

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

## Devuelve el ID de la herida más urgente para que el Dr. Valen o un NPC se trate herida por herida (priorizando mayor tasa de sangrado)
func get_most_urgent_untreated_wound_id(include_makeshift_for_upgrade: bool = false) -> int:
	var best_id: int = -1
	var best_score: float = -1.0
	for w in wounds:
		var wid: int = int(w.get("id", -1))
		var b_rate: float = float(w.get("bleed_rate", 0.0))
		var is_band: bool = bool(w.get("bandaged", false))
		var is_stit: bool = bool(w.get("stitched", false))
		var is_spl: bool = bool(w.get("splinted", false))
		var t_tier: String = str(w.get("tend_tier", "none"))
		var w_type: String = str(w.get("type", "scratch"))
		var inf_v: float = float(w.get("infection", 0.0))
		if b_rate > 0.0 and not is_band and not is_stit:
			var sc: float = 1000.0 + b_rate * 500.0 + float(w.get("severity", 10.0))
			if sc > best_score:
				best_score = sc
				best_id = wid
		elif w_type == "fracture" and not is_spl:
			var sc2: float = 400.0 + float(w.get("severity", 20.0))
			if sc2 > best_score:
				best_score = sc2
				best_id = wid
		elif (not is_band and not is_stit) or (include_makeshift_for_upgrade and (t_tier == "makeshift" or float(w.get("bandage_dirty", 0.0)) >= 50.0 or inf_v >= 20.0)):
			var sc3: float = 100.0 + inf_v * 3.0 + float(w.get("severity", 10.0))
			if sc3 > best_score:
				best_score = sc3
				best_id = wid
	return best_id

func has_fresh_combat_wounds_or_makeshift() -> bool:
	if current_blood >= 14.0 or not wounds.is_empty():
		return true
	return false

func treat_wound(wound_id: int, action: String, doctor_quality_bonus: float = 0.0) -> bool:
	for i in range(wounds.size()):
		var w: Dictionary = wounds[i]
		if int(w.get("id", -1)) != wound_id:
			continue
		match action:
			"tend_makeshift":
				# Tratamiento Rudimentario de Supervivencia (Sin medicina / Manos desnudas — RimWorld ~25% Tend Quality):
				# Corta la hemorragia para poder llegar vivo al pueblo, pero deja vendaje improvisado/sucio con riesgo de infección.
				w["bandaged"] = true
				w["bandage_dirty"] = 38.0
				w["clean"] = false
				w["bleed_rate"] = 0.0
				w["tend_quality"] = clampf(25.0 + doctor_quality_bonus, 15.0, 45.0)
				w["tend_tier"] = "makeshift"
				w["pain"] = maxf(2.0, float(w.get("pain", 6.0)) * 0.88)
			"wash":
				w["clean"] = true
				w["bandage_dirty"] = 0.0
				w["infection"] = maxf(0.0, float(w.get("infection", 0.0)) - 12.0)
				w["pain"] = maxf(1.0, float(w.get("pain", 6.0)) * 0.85)
				if str(w.get("tend_tier", "")) == "makeshift":
					w["tend_tier"] = "washed_makeshift"
					w["tend_quality"] = maxf(float(w.get("tend_quality", 0.0)), 48.0)
				elif not bool(w.get("bandaged", false)) and not bool(w.get("stitched", false)):
					w["tend_quality"] = maxf(float(w.get("tend_quality", 0.0)), 35.0)
					w["bleed_rate"] = float(w.get("bleed_rate", 0.0)) * 0.85
			"bandage":
				w["bandaged"] = true
				w["clean"] = true
				w["bandage_dirty"] = 0.0
				w["bleed_rate"] = 0.0
				w["tend_quality"] = clampf(82.0 + doctor_quality_bonus, 50.0, 100.0)
				w["tend_tier"] = "bandage"
				w["pain"] = maxf(1.0, float(w.get("pain", 6.0)) * 0.70)
				heal(4.0)
			"poultice":
				w["clean"] = true
				w["bandaged"] = true
				w["bandage_dirty"] = 0.0
				w["bleed_rate"] = 0.0
				w["tend_quality"] = clampf(68.0 + doctor_quality_bonus, 45.0, 88.0)
				w["tend_tier"] = "herbal"
				w["severity"] = maxf(2.0, float(w.get("severity", 20.0)) * 0.75)
				w["pain"] = maxf(1.0, float(w.get("pain", 8.0)) * 0.60)
				heal(6.0)
			"stitch":
				if str(w.get("type", "")) == "lodged_arrow":
					w["type"] = "laceration"
					w["name"] = "Laceración (Flecha Extraída)"
				w["stitched"] = true
				w["bandaged"] = true
				w["clean"] = true
				w["bandage_dirty"] = 0.0
				w["bleed_rate"] = 0.0
				w["tend_quality"] = clampf(115.0 + doctor_quality_bonus, 90.0, 130.0)
				w["tend_tier"] = "surgical"
				w["severity"] = maxf(2.0, float(w.get("severity", 25.0)) * 0.60)
				w["pain"] = maxf(1.0, float(w.get("pain", 10.0)) * 0.55)
				heal(10.0)
			"splint":
				w["splinted"] = true
				w["tend_quality"] = maxf(float(w.get("tend_quality", 0.0)), 75.0 + doctor_quality_bonus)
				w["pain"] = maxf(2.0, float(w.get("pain", 18.0)) * 0.60)
		var any_bleed := (get_total_wound_bleed_rate() > 0.0)
		if not any_bleed:
			is_bleeding = false
		anatomy_changed.emit()
		return true
	return false

func wash_all_wounds() -> int:
	var washed_count: int = 0
	for w in wounds:
		if not bool(w.get("clean", false)) or float(w.get("bandage_dirty", 0.0)) > 0.0 or float(w.get("infection", 0.0)) > 0.0 or str(w.get("tend_tier", "")) == "makeshift":
			w["clean"] = true
			w["bandage_dirty"] = 0.0
			w["infection"] = maxf(0.0, float(w.get("infection", 0.0)) - 12.0)
			w["pain"] = maxf(1.0, float(w.get("pain", 6.0)) * 0.85)
			if str(w.get("tend_tier", "")) == "makeshift":
				w["tend_tier"] = "washed_makeshift"
				w["tend_quality"] = maxf(float(w.get("tend_quality", 0.0)), 48.0)
			elif not bool(w.get("bandaged", false)) and not bool(w.get("stitched", false)):
				w["tend_quality"] = maxf(float(w.get("tend_quality", 0.0)), 35.0)
				w["bleed_rate"] = float(w.get("bleed_rate", 0.0)) * 0.85
			washed_count += 1
	if washed_count > 0:
		anatomy_changed.emit()
	return washed_count

func add_food_poisoning(amount: float, cause: String = "Comida en mal estado") -> void:
	if _is_player_test_mode():
		return
	food_poisoning = clampf(food_poisoning + amount, 0.0, 100.0)
	fever = clampf(fever + amount * 0.45, 0.0, 96.0)
	if systemic_immunity <= 0.0:
		systemic_immunity = 8.0
	last_sickness_cause = cause
	organ_hp["stomach"] = maxf(25.0, float(organ_hp.get("stomach", 100.0)) - amount * 0.22)
	organ_hp["liver"] = maxf(30.0, float(organ_hp.get("liver", 100.0)) - amount * 0.16)
	var eff_max: float = get_effective_max_health()
	if current_health > eff_max:
		current_health = eff_max
		health_changed.emit(current_health, max_health)
	anatomy_changed.emit()

func add_swamp_or_miasma_exposure(amount: float, cause: String = "Miasma / Fiebre del Pantano") -> void:
	if _is_player_test_mode():
		return
	swamp_sickness = clampf(swamp_sickness + amount, 0.0, 100.0)
	if swamp_sickness >= 25.0:
		fever = clampf(fever + amount * 0.45, 0.0, 96.0)
		if systemic_immunity <= 0.0:
			systemic_immunity = 8.0
		last_sickness_cause = cause
	var eff_max: float = get_effective_max_health()
	if current_health > eff_max:
		current_health = eff_max
		health_changed.emit(current_health, max_health)
	anatomy_changed.emit()

const ORGAN_ITEM_MAP: Dictionary = {
	"heart": "organ_heart",
	"lungs": "organ_lung",
	"kidneys": "organ_kidney",
	"liver": "organ_liver",
	"stomach": "organ_stomach",
	"eyes": "organ_eye"
}

func cure_sickness(amount: float, clear_wound_infections: bool = true) -> void:
	systemic_tend_quality = clampf(maxf(systemic_tend_quality, amount), 0.0, 130.0)
	systemic_immunity = clampf(systemic_immunity + amount * 0.38, 0.0, 100.0)
	fever = maxf(0.0, fever - amount * 0.55)
	food_poisoning = maxf(0.0, food_poisoning - amount * 0.60)
	swamp_sickness = maxf(0.0, swamp_sickness - amount * 0.60)
	if clear_wound_infections:
		for w in wounds:
			if float(w.get("infection", 0.0)) > 0.0:
				w["tend_quality"] = maxf(float(w.get("tend_quality", 0.0)), amount)
				w["immunity"] = clampf(float(w.get("immunity", 0.0)) + amount * 0.42, 0.0, 100.0)
				w["infection"] = maxf(0.0, float(w.get("infection", 0.0)) - amount * 0.50)
				if float(w["immunity"]) >= 100.0 or float(w["infection"]) <= 1.0:
					w["infection"] = 0.0
			w["clean"] = true
			w["bandage_dirty"] = 0.0
	for ok in ["stomach", "liver", "kidneys", "lungs"]:
		if float(organ_hp.get(ok, 100.0)) > 40.0:
			organ_hp[ok] = minf(100.0, float(organ_hp.get(ok, 100.0)) + amount * 0.22)
	anatomy_changed.emit()

func extract_organ(organ_id: String, surgeon_cause: String = "Bisturí Quirúrgico (Extracción de Órgano)") -> String:
	if not ORGAN_ITEM_MAP.has(organ_id):
		return ""
	var cur_o: float = float(organ_hp.get(organ_id, 100.0))
	if cur_o < 35.0:
		return ""
	var o_name: String = str(ORGAN_DEFS[organ_id]["name"])
	if organ_id in ["lungs", "kidneys", "eyes"] and cur_o > 55.0:
		organ_hp[organ_id] = 45.0
	else:
		organ_hp[organ_id] = 0.0
	var r_id: String = "head" if organ_id == "eyes" else "torso"
	var max_r: float = float(REGION_DEFS[r_id]["max_hp"])
	region_hp[r_id] = maxf(5.0, float(region_hp.get(r_id, max_r)) - 22.0)
	wounds.append({
		"id": _next_wound_id,
		"region": r_id,
		"organ": organ_id,
		"type": "deep_wound",
		"name": "Incisión Quirúrgica (%s Extraído)" % o_name,
		"severity": 46.0,
		"bleed_rate": 1.6,
		"pain": 26.0,
		"bandaged": true,
		"bandage_dirty": 0.0,
		"stitched": false,
		"splinted": false,
		"clean": true,
		"infection": 0.0,
		"weapon_cause": surgeon_cause
	})
	_next_wound_id += 1
	if float(organ_hp.get(organ_id, 0.0)) <= 0.0 and organ_id in ["heart", "liver", "lungs", "kidneys"]:
		current_health = 0.0
		is_bleeding = false
		health_changed.emit(current_health, max_health)
		anatomy_changed.emit()
		died.emit()
	else:
		current_health = maxf(12.0, current_health - 24.0)
		health_changed.emit(current_health, max_health)
		anatomy_changed.emit()
	return str(ORGAN_ITEM_MAP[organ_id])

func transplant_organ(organ_id: String) -> bool:
	if not ORGAN_DEFS.has(organ_id):
		return false
	if float(organ_hp.get(organ_id, 100.0)) >= 98.0:
		return false
	var o_name: String = str(ORGAN_DEFS[organ_id]["name"])
	organ_hp[organ_id] = 100.0
	var r_id: String = "head" if organ_id == "eyes" else "torso"
	wounds.append({
		"id": _next_wound_id,
		"region": r_id,
		"organ": organ_id,
		"type": "deep_wound",
		"name": "Sutura de Trasplante (%s)" % o_name,
		"severity": 16.0,
		"bleed_rate": 0.0,
		"pain": 8.0,
		"bandaged": true,
		"bandage_dirty": 0.0,
		"stitched": true,
		"splinted": false,
		"clean": true,
		"infection": 0.0,
		"weapon_cause": "Cirugía de Trasplante"
	})
	_next_wound_id += 1
	anatomy_changed.emit()
	return true

func get_max_wound_infection() -> float:
	var m: float = 0.0
	for w in wounds:
		m = maxf(m, float(w.get("infection", 0.0)))
	return m

func get_max_wound_immunity() -> float:
	var m: float = 0.0
	for w in wounds:
		if float(w.get("infection", 0.0)) > 0.0:
			m = maxf(m, float(w.get("immunity", 0.0)))
	return m

func has_active_sickness_or_infection() -> bool:
	return fever >= 18.0 or food_poisoning >= 18.0 or swamp_sickness >= 18.0 or get_max_wound_infection() >= 18.0

func get_sickness_summary_label() -> String:
	var tags: Array[String] = []
	var max_inf: float = get_max_wound_infection()
	if max_inf >= 12.0:
		tags.append("🦠Infección: %d%% vs 🛡️Inmunidad: %d%%" % [int(round(max_inf)), int(round(get_max_wound_immunity()))])
	if fever >= 15.0:
		tags.append("🌡️Fiebre: %d%% (Inm: %d%%)" % [int(round(fever)), int(round(maxf(systemic_immunity, get_max_wound_immunity())))])
	if food_poisoning >= 15.0:
		tags.append("🤢Intoxicación: %d%%" % int(round(food_poisoning)))
	if swamp_sickness >= 15.0:
		tags.append("🦟Miasma: %d%%" % int(round(swamp_sickness)))
	var eff_cap: int = int(round(get_effective_max_health()))
	if eff_cap < int(round(max_health)):
		tags.append("⚠️Tope Resistencia: %d%%" % eff_cap)
	return " · ".join(tags) if not tags.is_empty() else "🟢 Sin fiebre ni infecciones activas"

func get_forensic_autopsy_summary() -> String:
	var parts: Array[String] = []
	if last_death_reason != "":
		parts.append("Causa Fisiológica: " + last_death_reason)
	for i in range(maxi(0, wounds.size() - 3), wounds.size()):
		var w: Dictionary = wounds[i]
		var r_name: String = str(REGION_DEFS.get(str(w.get("region", "torso")), {"name": "Torso"})["name"])
		var o_id: String = str(w.get("organ", ""))
		var o_tag: String = (" [Órgano: %s]" % str(ORGAN_DEFS[o_id]["name"])) if (o_id != "" and ORGAN_DEFS.has(o_id)) else ""
		var inf_tag: String = (" [Infectada %d%%]" % int(round(float(w.get("infection", 0.0))))) if float(w.get("infection", 0.0)) >= 30.0 else ""
		parts.append("%s en %s%s%s (%s)" % [str(w.get("name", "Herida")), r_name, o_tag, inf_tag, str(w.get("weapon_cause", "Arma"))])
	if food_poisoning >= 40.0 or fever >= 50.0 or swamp_sickness >= 40.0:
		parts.append("Patología interna: %s (%s)" % [get_sickness_summary_label(), last_sickness_cause if last_sickness_cause != "" else "Sepsis/Toxinas"])
	if parts.is_empty():
		return "Sin traumatismos externos registrados"
	return "; ".join(parts)

func get_untreated_wound_count() -> int:
	var cnt: int = 0
	for w in wounds:
		var is_tended: bool = bool(w.get("bandaged", false)) or bool(w.get("stitched", false)) or bool(w.get("splinted", false))
		var is_makeshift_or_dirty: bool = str(w.get("tend_tier", "none")) == "makeshift" or float(w.get("bandage_dirty", 0.0)) >= 25.0
		if not is_tended or is_makeshift_or_dirty or float(w.get("bleed_rate", 0.0)) > 0.0 or float(w.get("infection", 0.0)) >= 12.0:
			cnt += 1
	return cnt

func to_medical_dict() -> Dictionary:
	var w_copy: Array = []
	for w in wounds:
		w_copy.append(w.duplicate())
	return {
		"region_hp": region_hp.duplicate(),
		"region_max_override": region_max_override.duplicate(),
		"organ_hp": organ_hp.duplicate(),
		"wounds": w_copy,
		"fever": fever,
		"food_poisoning": food_poisoning,
		"swamp_sickness": swamp_sickness,
		"systemic_immunity": systemic_immunity,
		"systemic_tend_quality": systemic_tend_quality,
		"last_sickness_cause": last_sickness_cause,
		"last_death_reason": last_death_reason,
		"next_id": _next_wound_id
	}

func from_medical_dict(data: Dictionary) -> void:
	region_max_override.clear()
	if data.get("region_max_override", null) is Dictionary:
		for ok_r in (data["region_max_override"] as Dictionary).keys():
			if REGION_DEFS.has(str(ok_r)):
				region_max_override[str(ok_r)] = float(data["region_max_override"][ok_r])
	_init_anatomy()
	if data.is_empty():
		return
	if data.has("region_hp") and typeof(data["region_hp"]) == TYPE_DICTIONARY:
		var r_in: Dictionary = data["region_hp"]
		for k in REGION_ORDER:
			if r_in.has(k):
				region_hp[k] = clampf(float(r_in[k]), 0.0, region_max(k))
	if data.has("organ_hp") and typeof(data["organ_hp"]) == TYPE_DICTIONARY:
		var o_in: Dictionary = data["organ_hp"]
		for ok in ORGAN_DEFS.keys():
			if o_in.has(ok):
				organ_hp[ok] = clampf(float(o_in[ok]), 0.0, 100.0)
	if data.has("wounds") and typeof(data["wounds"]) == TYPE_ARRAY:
		for raw_w in (data["wounds"] as Array):
			if typeof(raw_w) == TYPE_DICTIONARY:
				wounds.append((raw_w as Dictionary).duplicate())
	fever = clampf(float(data.get("fever", 0.0)), 0.0, 100.0)
	food_poisoning = clampf(float(data.get("food_poisoning", 0.0)), 0.0, 100.0)
	swamp_sickness = clampf(float(data.get("swamp_sickness", 0.0)), 0.0, 100.0)
	systemic_immunity = clampf(float(data.get("systemic_immunity", 0.0)), 0.0, 100.0)
	systemic_tend_quality = clampf(float(data.get("systemic_tend_quality", 0.0)), 0.0, 130.0)
	last_sickness_cause = str(data.get("last_sickness_cause", ""))
	last_death_reason = str(data.get("last_death_reason", ""))
	_next_wound_id = maxi(1, int(data.get("next_id", wounds.size() + 1)))
	anatomy_changed.emit()
