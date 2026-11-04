@tool
extends RefCounted

## E2: enfermedades que se contagian (`docs/PLAN_ECONOMIA_NECESIDADES.md`).
## Dos males: el **resfriado** (leve) y la **fiebre gris** (seria: guarda cama y, sin médico, muy raramente mata).
## Aparecen por suciedad, lluvia o miasma y se pegan a quien está cerca. El médico cura cada día a unos cuantos.
## Estado en `vm.needs_state.ill` (clave -> {id, name, day, end, treated}) e `immune`. La clave "player" es el jugador.

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")

const DISEASES: Dictionary = {
	"cold": {"name": "Resfriado", "min_days": 3, "max_days": 5, "contagion": 0.06, "level": 1, "death": 0.0, "death_after": 99},
	"fever": {"name": "Fiebre gris", "min_days": 6, "max_days": 10, "contagion": 0.04, "level": 2, "death": 0.04, "death_after": 5},
}
const ONSET_BASE: float = 0.006
const ONSET_DIRTY: float = 0.03
const ONSET_RAIN: float = 0.006
const FEVER_SHARE: float = 0.2
const CONTAGION_RADIUS: float = 60.0
const DAILY_INFECTION_CAP: int = 2
const IMMUNE_DAYS: int = 20
const DOCTOR_PER_DAY: int = 3
const PLAYER_CURE_COST: int = 8
const PLAYER_FEVER_HP: float = 12.0
const PROSTHETIC_COST: int = 25
const LIMB_LABELS: Dictionary = {
	"left_arm": "Brazo Izq.",
	"right_arm": "Brazo Der.",
	"left_leg": "Pierna Izq.",
	"right_leg": "Pierna Der.",
}

static func amputations_of(vm) -> Dictionary:
	var st: Dictionary = VillageNeeds.state(vm)
	if not (st.get("amputations", null) is Dictionary):
		st["amputations"] = {}
	return st["amputations"]

static func get_amputation(vm, key: String) -> Dictionary:
	return amputations_of(vm).get(key, {})

static func has_amputation(vm, key: String) -> bool:
	return not get_amputation(vm, key).is_empty()

static func has_prosthetic(vm, key: String) -> bool:
	return str(get_amputation(vm, key).get("prosthetic", "")) != ""

static func _health_comp_of(vm, key: String):
	if key == "player":
		var pl = VillageNeeds.player_of(vm)
		return pl.get_node_or_null("HealthComponent") if pl != null else null
	var n = vm._get_npcs_by_person_key().get(key, null)
	return n.health_comp if n != null else null

static func amputate(vm, key: String, limb_id: String = "left_arm", reason: String = "gangrena por infección") -> bool:
	if vm == null:
		return false
	var limb_key: String = limb_id if LIMB_LABELS.has(limb_id) else "left_arm"
	var limb_lbl: String = str(LIMB_LABELS[limb_key])
	amputations_of(vm)[key] = {
		"limb": limb_key,
		"limb_label": limb_lbl,
		"prosthetic": "",
		"day": VillageNeeds.today(),
		"reason": reason,
	}
	var hc = _health_comp_of(vm, key)
	if hc != null:
		for i in range(hc.wounds.size() - 1, -1, -1):
			if str(hc.wounds[i].get("region", "")) == limb_key:
				hc.wounds.remove_at(i)
		hc.region_hp[limb_key] = 0.0
		hc.anatomy_changed.emit()
	if key != "player":
		var n = vm._get_npcs_by_person_key().get(key, null)
		if n != null:
			n.add_thought("Perdí mi %s (%s) (-15)" % [limb_lbl, reason], 8.0)
			n._spawn_floating_text("🪚 Amputación: %s" % limb_lbl, Color(0.95, 0.45, 0.35), -40.0)
			VillageChronicle.add(vm, "amputation", "El médico amputó el %s de %s (%s)" % [limb_lbl, n.npc_name, reason], true)
	return true

static func install_prosthetic(vm, key: String, prosthetic_name: String = "Prótesis articulada de hierro y cuero") -> bool:
	if vm == null or not has_amputation(vm, key):
		return false
	var amp: Dictionary = get_amputation(vm, key)
	var limb_key: String = str(amp.get("limb", "left_arm"))
	var limb_lbl: String = str(amp.get("limb_label", "Brazo Izq."))
	amp["prosthetic"] = prosthetic_name
	amputations_of(vm)[key] = amp
	var hc = _health_comp_of(vm, key)
	if hc != null:
		hc.region_hp[limb_key] = 40.0 if limb_key.ends_with("arm") else 45.0
		hc.anatomy_changed.emit()
	if key != "player":
		var n = vm._get_npcs_by_person_key().get(key, null)
		if n != null:
			n.add_thought("Tengo una prótesis (%s) que me devuelve a la vida (+12)" % prosthetic_name, 8.0)
			n._spawn_floating_text("🦾 %s" % prosthetic_name, Color.AQUAMARINE, -40.0)
			VillageChronicle.add(vm, "prosthetic", "%s recibió una %s para su %s" % [n.npc_name, prosthetic_name, limb_lbl], true)
	return true

static func ill_of(vm, key: String) -> Dictionary:
	return VillageNeeds.state(vm)["ill"].get(key, {})

static func is_ill(vm, key: String) -> bool:
	return not ill_of(vm, key).is_empty()

static func infect(vm, key: String, disease_id: String, from_name: String = "") -> bool:
	var st: Dictionary = VillageNeeds.state(vm)
	if st["ill"].has(key) or int(st["immune"].get("%s:%s" % [key, disease_id], -1)) >= VillageNeeds.today():
		return false
	var d: Dictionary = DISEASES[disease_id]
	var t: int = VillageNeeds.today()
	st["ill"][key] = {"id": disease_id, "name": d["name"], "day": t, "end": t + randi_range(int(d["min_days"]), int(d["max_days"])), "treated": false}
	st["infections"] = int(st.get("infections", 0)) + 1
	var who: String = "Has" if key == "player" else ""
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var n = by_key.get(key, null)
	if key == "player":
		var pl = VillageNeeds.player_of(vm)
		if pl != null and pl.has_method("show_hint"):
			pl.show_hint("🤒 %s cogido: %s%s. Descansa o pide al médico que te cure." % [who, d["name"], (" (te lo pegó %s)" % from_name) if from_name != "" else ""])
	elif n != null:
		n._spawn_floating_text("🤒 %s" % d["name"], Color(0.8, 0.95, 0.6), -36.0)
		VillageChronicle.add(vm, "illness", "%s cayó enfermo: %s%s" % [n.npc_name, d["name"], (" (se lo pegó %s)" % from_name) if from_name != "" else ""], true)
	apply_levels(vm)
	return true

static func recover(vm, key: String) -> void:
	var st: Dictionary = VillageNeeds.state(vm)
	var ill: Dictionary = st["ill"].get(key, {})
	if ill.is_empty():
		return
	st["immune"]["%s:%s" % [key, str(ill["id"])]] = VillageNeeds.today() + IMMUNE_DAYS
	st["ill"].erase(key)
	apply_levels(vm)

## Refleja la enfermedad en el vecino (sick_level: 2 = guarda cama) y en el jugador.
static func apply_levels(vm) -> void:
	var st: Dictionary = VillageNeeds.state(vm)
	for n in VillageNeeds.living(vm):
		var ill: Dictionary = st["ill"].get(n.get_person_key(), {})
		n.sick_level = int(DISEASES[str(ill["id"])]["level"]) if not ill.is_empty() else 0
	var pl = VillageNeeds.player_of(vm)
	if pl != null and pl.get("survival_comp") != null:
		var pill: Dictionary = st["ill"].get("player", {})
		pl.survival_comp.sick_level = int(DISEASES[str(pill["id"])]["level"]) if not pill.is_empty() else 0

## Cada hora: contagio entre quienes están cerca.
static func on_hour(vm, _hour: int) -> int:
	var st: Dictionary = VillageNeeds.state(vm)
	if int(st.get("inf_day", -1)) != VillageNeeds.today():
		st["inf_day"] = VillageNeeds.today()
		st["inf_count"] = 0
	var bodies: Array = [] # [key, pos, name, hygiene]
	for n in VillageNeeds.living(vm):
		if not n.is_downed:
			bodies.append([n.get_person_key(), n.global_position, n.npc_name, n.need_hygiene])
	var pl = VillageNeeds.player_of(vm)
	if pl is Node2D:
		bodies.append(["player", (pl as Node2D).global_position, "el forastero", VillageNeeds.player_hygiene(vm)])
	var new_cases: int = 0
	for src in bodies:
		var ill: Dictionary = st["ill"].get(src[0], {})
		if ill.is_empty():
			continue
		var d: Dictionary = DISEASES[str(ill["id"])]
		for dst in bodies:
			if int(st["inf_count"]) >= DAILY_INFECTION_CAP:
				return new_cases
			if dst[0] == src[0] or st["ill"].has(dst[0]) or (src[1] as Vector2).distance_to(dst[1]) > CONTAGION_RADIUS:
				continue
			var ch: float = float(d["contagion"]) * (1.5 if float(dst[3]) < 30.0 else 1.0)
			if randf() < ch and infect(vm, str(dst[0]), str(ill["id"]), str(src[2])):
				st["inf_count"] = int(st["inf_count"]) + 1
				new_cases += 1
	return new_cases

## Cada día: nuevos casos, el médico cura, se recuperan o (muy raramente) mueren.
static func daily(vm) -> void:
	var st: Dictionary = VillageNeeds.state(vm)
	var t: int = VillageNeeds.today()
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for k in st["immune"].keys():
		if int(st["immune"][k]) < t:
			st["immune"].erase(k)
	# Se recuperan o empeoran
	for key in st["ill"].keys():
		var ill: Dictionary = st["ill"][key]
		var d: Dictionary = DISEASES[str(ill["id"])]
		if t >= int(ill["end"]):
			recover(vm, key)
			continue
		if bool(ill["treated"]) or t - int(ill["day"]) < int(d["death_after"]) or float(d["death"]) <= 0.0:
			continue
		if key == "player":
			_hurt_player(vm, str(d["name"]))
		elif randf() < float(d["death"]):
			var n = by_key.get(key, null)
			if n != null:
				die(vm, n, str(d["name"]))
	# El médico atiende primero a los graves
	var doc = null
	for n in by_key.values():
		if int(n.trade_role) == int(VillageNPC.TradeRole.DOCTOR) and n.is_conscious() and not st["ill"].has(n.get_person_key()):
			doc = n
			break
	if doc != null:
		var keys: Array = st["ill"].keys()
		keys.sort_custom(func(a, b): return int(DISEASES[str(st["ill"][a]["id"])]["level"]) > int(DISEASES[str(st["ill"][b]["id"])]["level"]))
		var done: int = 0
		for key in keys:
			if done >= DOCTOR_PER_DAY or key == "player":
				continue
			treat(vm, key)
			done += 1
		# PJ.1: Amputaciones de urgencia por gangrena e implantes protésicos con el Arreglador
		var tinker = vm.trade_npcs.get(VillageNPC.TradeRole.TINKER)
		for n in VillageNeeds.living(vm):
			var n_key: String = n.get_person_key()
			if not has_amputation(vm, n_key) and n.health_comp != null:
				for w in n.health_comp.wounds:
					var w_reg: String = str(w.get("region", ""))
					if LIMB_LABELS.has(w_reg) and float(w.get("infection", 0.0)) >= 65.0:
						amputate(vm, n_key, w_reg, "gangrena por infección")
						break
			if has_amputation(vm, n_key) and not has_prosthetic(vm, n_key) and n.personal_gold >= PROSTHETIC_COST:
				if tinker != null and is_instance_valid(tinker) and not tinker.is_dead and int(tinker.shop_stock.get("repair_kit", 0)) > 0:
					n.personal_gold -= PROSTHETIC_COST
					doc.personal_gold += 15
					tinker.personal_gold += PROSTHETIC_COST - 15
					tinker.shop_stock["repair_kit"] = int(tinker.shop_stock["repair_kit"]) - 1
					tinker._sync_shop_stock_to_vm()
					install_prosthetic(vm, n_key, "Prótesis articulada de hierro y cuero")
	# Casos nuevos
	var raining: bool = WorldClock != null and int(WorldClock.current_weather) == 1
	for n in VillageNeeds.living(vm):
		if VillageNeeds.is_outsider(n):
			continue
		var ch: float = ONSET_BASE + (ONSET_DIRTY if n.need_hygiene < 30.0 else 0.0) + (ONSET_RAIN if raining else 0.0)
		var miasma: bool = n.health_comp != null and float(n.health_comp.swamp_sickness) > 0.0
		if randf() < ch:
			infect(vm, n.get_person_key(), "fever" if (miasma or randf() < FEVER_SHARE) else "cold")
	if VillageNeeds.player_hygiene(vm) < 30.0 and randf() < ONSET_DIRTY:
		infect(vm, "player", "cold")
	apply_levels(vm)

static func treat(vm, key: String) -> void:
	var ill: Dictionary = ill_of(vm, key)
	if ill.is_empty() or bool(ill["treated"]):
		return
	var t: int = VillageNeeds.today()
	ill["treated"] = true
	ill["end"] = maxi(t + 1, t + int(float(int(ill["end"]) - t) / 2.0))

static func die(vm, n, disease_name: String) -> void:
	recover(vm, n.get_person_key())
	VillageNeeds.state(vm)["illness_deaths"] = int(VillageNeeds.state(vm).get("illness_deaths", 0)) + 1
	VillageChronicle.add(vm, "illness_death", "%s murió de %s sin que nadie le tratara" % [n.npc_name, disease_name], true)
	n.last_hit_by_player = false
	n.last_hit_weapon_name = "Enfermedad (%s sin tratar)" % disease_name
	n._confirm_true_death()

## Al jugador la fiebre sin tratar le quita salud, pero nunca por debajo de 5 (no te mata por ahora).
static func _hurt_player(vm, disease_name: String) -> void:
	var pl = VillageNeeds.player_of(vm)
	if pl == null:
		return
	var hc = pl.get_node_or_null("HealthComponent")
	if hc != null and hc.current_health > 5.0:
		hc.current_health = maxf(5.0, hc.current_health - PLAYER_FEVER_HP)
		hc.health_changed.emit(hc.current_health, hc.max_health)
	if pl.has_method("show_hint"):
		pl.show_hint("🤒 La %s empeora. Ve al médico." % disease_name)

static func add_dialogue_choices(vm, npc, _diag: Dictionary, ch_arr: Array) -> void:
	if vm == null or int(npc.trade_role) != int(VillageNPC.TradeRole.DOCTOR):
		return
	if is_ill(vm, "player"):
		ch_arr.insert(0, {"label": "🩺 Pedir que te cure (%d de oro)" % PLAYER_CURE_COST, "next": "END", "action": "illness_cure"})
	if has_amputation(vm, "player") and not has_prosthetic(vm, "player"):
		ch_arr.insert(0, {"label": "🦾🩺 Implantar prótesis articulada de hierro y cuero (-%d Oro)" % PROSTHETIC_COST, "next": "END", "action": "illness_prosthetic_self"})
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for k in amputations_of(vm).keys():
		if str(k) == "player" or has_prosthetic(vm, str(k)):
			continue
		var amp_npc = by_key.get(str(k), null)
		if amp_npc != null and is_instance_valid(amp_npc) and not amp_npc.is_dead:
			ch_arr.insert(0, {"label": "🦾🤝 Costear prótesis médica para %s (-%d Oro)" % [amp_npc.npc_name, PROSTHETIC_COST], "next": "END", "action": "illness_prosthetic_npc:" + str(k)})

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	if action_id == "illness_cure":
		if inv == null or int(inv.gold) < PLAYER_CURE_COST:
			npc._spawn_floating_text("«Sin oro no tengo con qué comprar las hierbas.»", Color.CORAL, -46.0)
			return
		inv.add_gold(-PLAYER_CURE_COST)
		npc.personal_gold += PLAYER_CURE_COST
		recover(vm, "player")
		npc._spawn_floating_text("🩺 «Bebe esto y descansa. Mañana estarás mejor.»", Color(0.7, 1.0, 0.8), -46.0)
	elif action_id == "illness_prosthetic_self" or action_id.begins_with("illness_prosthetic_npc:"):
		var target_key: String = "player" if action_id == "illness_prosthetic_self" else action_id.substr("illness_prosthetic_npc:".length())
		if not has_amputation(vm, target_key) or has_prosthetic(vm, target_key):
			npc._spawn_floating_text("«No hace falta ninguna prótesis ahora mismo.»", Color.LIGHT_GRAY, -46.0)
			return
		if inv == null or int(inv.gold) < PROSTHETIC_COST:
			npc._spawn_floating_text("«Necesito %d de oro para encargar los engranajes y ajustar la prótesis.»" % PROSTHETIC_COST, Color.CORAL, -46.0)
			return
		inv.add_gold(-PROSTHETIC_COST)
		var tinker = vm.trade_npcs.get(VillageNPC.TradeRole.TINKER)
		if tinker != null and is_instance_valid(tinker) and not tinker.is_dead:
			npc.personal_gold += 15
			tinker.personal_gold += PROSTHETIC_COST - 15
			if int(tinker.shop_stock.get("repair_kit", 0)) > 0:
				tinker.shop_stock["repair_kit"] = int(tinker.shop_stock["repair_kit"]) - 1
				tinker._sync_shop_stock_to_vm()
		else:
			npc.personal_gold += PROSTHETIC_COST
		install_prosthetic(vm, target_key, "Prótesis articulada de hierro y cuero")
		if target_key != "player":
			var amp_npc = vm._get_npcs_by_person_key().get(target_key, null)
			if amp_npc != null:
				amp_npc.affinity = clampi(amp_npc.affinity + 18, -100, 100)
				amp_npc.modify_npc_relationship(npc, 10, "Me implantó una prótesis gracias al forastero", true)
		npc._spawn_floating_text("🦾 «Las correas y articulaciones encajan a la perfección.»", Color.AQUAMARINE, -46.0)
