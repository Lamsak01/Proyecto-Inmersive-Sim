@tool
extends RefCounted

## Bloque P4: Confesión, secretos de la capilla y fe (10 mecánicas).
## 1) Confesión entre semana (martes y jueves 17–19 h: creyentes con secretos van a confesarse con el sacerdote).
## 2) Espiar el confesionario en sigilo (escuchar el pecado si estás oculto cerca del altar).
## 3) Sacerdote corrupto que vende secretos de confesión (si es corruptible o cayó en crisis de fe).
## 4) Penitencias visibles (donar a los pobres del Albergue o pedir perdón a un enemigo al día siguiente).
## 5) Excomunión y vacío de los fieles (prohibido ir al Oficio y rechazo de los creyentes tras falta grave).
## 6) Confesarte tú mismo (pagar penitencia para subir reputación con creyentes y que el cura interceda por ti).
## 7) Indulgencias pagadas con oro por nobles y ricos (evitan penitencia pero indignan a los pobres).
## 8) Sermón dominical con indirectas sobre los pecados confesados esa semana (los culpables se ponen nerviosos).
## 9) Crisis de fe del sacerdote (puedes consolarlo para reforzar su fe o empujarlo a la corrupción).
## 10) Derecho de santuario en la capilla (refugio y mediación ante delitos menores o persecuciones).
## Estado en `vm.faith_state["confession"]` (se guarda automáticamente con `faith_state`).

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageSecrets = preload("res://scripts/systems/VillageSecrets.gd")
const VillageDesires = preload("res://scripts/systems/VillageDesires.gd")
const VillageCrime = preload("res://scripts/systems/VillageCrime.gd")
const VillageTown = preload("res://scripts/systems/VillageTown.gd")

const CONFESS_DAYS: Array[int] = [1, 3] # Martes y jueves
const CONFESS_HOURS: Array[int] = [17, 18]
const EAVESDROP_RADIUS: float = 115.0
const PENANCE_DONATION: int = 8
const INDULGENCE_COST: int = 25
const SECRET_BUY_COST: int = 20
const PLAYER_PENANCE_COST: int = 12
const SANCTUARY_COST: int = 15

static func state(vm) -> Dictionary:
	if not (vm.faith_state is Dictionary):
		vm.faith_state = {}
	if not vm.faith_state.has("confession") or not (vm.faith_state["confession"] is Dictionary):
		vm.faith_state["confession"] = {}
	var st: Dictionary = vm.faith_state["confession"]
	for k in ["priest_secrets", "penances", "excommunicated", "sanctuary_npcs"]:
		if not st.has(k) or not (st[k] is Dictionary):
			st[k] = {}
	if not st.has("priest_doubt"):
		st["priest_doubt"] = 0
	if not st.has("priest_corrupted"):
		st["priest_corrupted"] = false
	if not st.has("indulgences"):
		st["indulgences"] = 0
	if not st.has("week_sin_counts") or not (st["week_sin_counts"] is Dictionary):
		st["week_sin_counts"] = {}
	return st

static func today() -> int:
	return int(WorldClock.current_day) if WorldClock else 1

# ==============================================================================
# P4.1, P4.2, P4.4 y P4.7: Confesión entre semana, espiar, penitencias e indulgencias
# ==============================================================================
static func find_sin_of(vm, npc) -> Dictionary:
	var key: String = npc.get_person_key()
	# 1. ¿Tiene una aventura activa?
	var aff: Dictionary = VillageSecrets.active_affair_of(vm, key)
	if not aff.is_empty():
		return {"kind": "adulterio", "desc": "%s engaña a su pareja con %s" % [npc.npc_name, str(aff["b_name"])], "secret_id": int(aff["id"]), "raw": "affair"}
	# 2. ¿Cometió un robo sin atrapar?
	for t in VillageNeeds.state(vm).get("thefts", []):
		if str(t.get("thief", "")) == key and str(t.get("status", "")) == "open":
			return {"kind": "robo", "desc": "%s le robó %d de oro a %s" % [npc.npc_name, int(t["amount"]), str(t["victim_name"])], "theft_id": int(t["id"]), "raw": "theft"}
	# 3. ¿Tiene un deseo de venganza o asesinato activo?
	var d: Dictionary = VillageDesires.active_of(vm, key)
	if not d.is_empty() and str(d.get("type", "")) in ["revenge", "murder"]:
		return {"kind": "rencor", "desc": "%s alimenta un deseo oscuro contra %s" % [npc.npc_name, str(d["target_name"])], "desire_id": int(d["id"]), "raw": "desire"}
	return {}

static func on_hour(vm, hour: int) -> void:
	var wk: int = int(WorldClock.get_weekday()) if WorldClock != null and WorldClock.has_method("get_weekday") else -1
	if not (wk in CONFESS_DAYS) or not (hour in CONFESS_HOURS):
		return
	var priest = vm.VillageFaith.priest_of(vm)
	if priest == null or not priest.is_conscious():
		return
	var st: Dictionary = state(vm)
	for n in VillageNeeds.living(vm):
		if n == priest or not VillageNeeds.is_free(n) or is_excommunicated(vm, n):
			continue
		if vm.VillageFaith.grade_of(n) == vm.VillageFaith.GRADE_SKEPTIC:
			continue
		var sin: Dictionary = find_sin_of(vm, n)
		if sin.is_empty() or (st["priest_secrets"] as Dictionary).has(n.get_person_key()):
			continue
		if randf() < 0.45:
			n.start_errand("confess", vm._church_altar_pos + Vector2(0, 10))

static func on_errand_arrived(vm, npc) -> void:
	if npc.errand_kind != "confess":
		return
	npc.end_errand()
	perform_confession(vm, npc)

static func perform_confession(vm, npc) -> Dictionary:
	var priest = vm.VillageFaith.priest_of(vm)
	var sin: Dictionary = find_sin_of(vm, npc)
	if priest == null or sin.is_empty():
		return {}
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key()
	var sin_kind: String = str(sin["kind"])
	st["priest_secrets"][key] = {
		"sinner_key": key, "sinner_name": npc.npc_name, "kind": sin_kind,
		"desc": str(sin["desc"]), "day": today(), "raw": str(sin.get("raw", "")),
		"secret_id": int(sin.get("secret_id", -1)), "theft_id": int(sin.get("theft_id", -1)), "desire_id": int(sin.get("desire_id", -1))
	}
	st["week_sin_counts"][sin_kind] = int(st["week_sin_counts"].get(sin_kind, 0)) + 1
	st["priest_doubt"] = mini(100, int(st.get("priest_doubt", 0)) + (8 if sin_kind == "adulterio" else 6))
	npc.add_thought("Me confesé en la Capilla del Alba (+6)", 6.0)
	npc._spawn_floating_text("🙏 «Perdóname, padre, porque he pecado...»", Color(0.95, 0.90, 0.72), -36.0)
	# P4.7: ¿Es rico o noble y compra una bula de indulgencia en vez de hacer penitencia?
	if (int(npc.personal_gold) >= 140 or int(npc.trade_role) == int(VillageNPC.TradeRole.NOBLE)) and TraitCatalog.npc_tendency(npc, "generosity") <= 0.2:
		buy_indulgence(vm, npc, priest)
	else:
		# P4.4: Penitencia normal para el día siguiente
		st["penances"][key] = {"sinner_key": key, "sinner_name": npc.npc_name, "kind": "donate" if int(npc.personal_gold) >= 15 else "apologize", "day": today()}
	# P4.2: ¿Está el jugador espiando cerca en sigilo?
	var pl = VillageNeeds.player_of(vm)
	if pl is Node2D and (pl as Node2D).global_position.distance_to(vm._church_altar_pos) <= EAVESDROP_RADIUS:
		var in_stealth: bool = pl.has_method("is_stealthing") and bool(pl.call("is_stealthing"))
		if in_stealth or not vm.has_line_of_sight(priest.global_position, (pl as Node2D).global_position):
			_player_learns_confessed_sin(vm, st["priest_secrets"][key], "espiando en el confesionario")
			if pl.has_method("add_skill_xp"):
				pl.call("add_skill_xp", "stealth", 4)
			if pl.has_method("show_hint"):
				pl.show_hint("👂⛪ Escuchaste en secreto la confesión de %s: %s." % [npc.npc_name, str(sin["desc"])])
	VillageChronicle.add(vm, "confession", "%s acudió a confesarse en privado con el sacerdote" % npc.npc_name, false)
	return st["priest_secrets"][key]

static func _player_learns_confessed_sin(vm, rec: Dictionary, how: String) -> void:
	var raw: String = str(rec.get("raw", ""))
	if raw == "affair":
		for s in vm.secrets:
			if int(s.get("id", -2)) == int(rec.get("secret_id", -1)):
				VillageSecrets.player_learns(vm, s, str(s.get("b_name", "")), how)
	elif raw == "theft":
		var t: Dictionary = VillageCrime.by_id(vm, int(rec.get("theft_id", -1)))
		if not t.is_empty():
			t["player_knows"] = true
	elif raw == "desire":
		for d in vm.desires:
			if int(d.get("id", -2)) == int(rec.get("desire_id", -1)):
				VillageDesires.player_learns(vm, d, how)
	VillageChronicle.add(vm, "confession_heard", "Supiste (%s) que %s" % [how, str(rec.get("desc", ""))], true)

static func buy_indulgence(vm, rich_npc, priest) -> void:
	var st: Dictionary = state(vm)
	var pay: int = mini(INDULGENCE_COST, int(rich_npc.personal_gold))
	rich_npc.personal_gold -= pay
	if priest != null:
		priest.personal_gold += int(pay * 0.4)
	vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + (pay - int(pay * 0.4))
	st["indulgences"] = int(st.get("indulgences", 0)) + 1
	# Indigna a los pobres y alimenta la crisis para la secta
	for n in VillageNeeds.living(vm):
		if VillageNeeds.class_of(n) in ["pobre", "mendigo"]:
			n.modify_npc_relationship(rich_npc, -3, "Compró el perdón en la capilla con su oro", true)
	if "sect_state" in vm and vm.sect_state is Dictionary and vm.sect_state.has("crisis_events"):
		(vm.sect_state["crisis_events"] as Array).append({"day": today(), "w": 0.06})
	VillageChronicle.add(vm, "indulgence", "%s compró una bula de perdón en la capilla por %d de oro, indignando a los humildes" % [rich_npc.npc_name, pay], true)

# ==============================================================================
# P4.5 y P4.8: Excomunión y Sermón dominical con indirectas
# ==============================================================================
static func excommunicate(vm, npc, reason: String) -> void:
	if vm == null or npc == null:
		return
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key()
	if (st["excommunicated"] as Dictionary).has(key):
		return
	st["excommunicated"][key] = {"name": npc.npc_name, "reason": reason, "day": today()}
	npc.leave_rite()
	npc.add_thought("El sacerdote me ha apartado de la capilla (-14)", -14.0)
	for o in VillageNeeds.living(vm):
		if o != npc and vm.VillageFaith.is_believer(o):
			o.modify_npc_relationship(npc, -4, "Apartado de la capilla por %s" % reason, true)
	VillageChronicle.add(vm, "excommunicated", "El sacerdote apartó de la Capilla del Alba a %s por %s" % [npc.npc_name, reason], true)

static func is_excommunicated(vm, npc) -> bool:
	return npc != null and (state(vm)["excommunicated"] as Dictionary).has(npc.get_person_key())

static func lift_excommunication(vm, npc, how: String) -> void:
	if vm == null or npc == null:
		return
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key()
	if not (st["excommunicated"] as Dictionary).has(key):
		return
	st["excommunicated"].erase(key)
	for o in VillageNeeds.living(vm):
		if o != npc and vm.VillageFaith.is_believer(o):
			o.modify_npc_relationship(npc, 3, "Volvió a ser admitido en la capilla", true)
	VillageChronicle.add(vm, "excomm_lifted", "%s fue readmitido en la Capilla del Alba (%s)" % [npc.npc_name, how], true)

## Llamado desde `VillageFaith.finish_rite` cada domingo.
static func apply_sunday_indirect_sermon(vm, attendees: Array) -> String:
	var st: Dictionary = state(vm)
	var counts: Dictionary = st.get("week_sin_counts", {})
	if counts.is_empty() or attendees.is_empty():
		return ""
	var top_sin: String = ""
	var top_n: int = 0
	for k in counts.keys():
		if int(counts[k]) > top_n:
			top_n = int(counts[k])
			top_sin = str(k)
	st["week_sin_counts"] = {}
	if top_sin == "":
		return ""
	var nervous_names: Array[String] = []
	for m in attendees:
		var m_key: String = m.get_person_key()
		if (st["priest_secrets"] as Dictionary).has(m_key) and str(st["priest_secrets"][m_key].get("kind", "")) == top_sin:
			m.add_thought("El sacerdote predicó justo contra mi pecado (-4)", -4.0)
			m._spawn_floating_text("😓 ...", Color(1.0, 0.80, 0.65), -34.0)
			nervous_names.append(m.npc_name)
	var msg: String = "El sacerdote predicó en el Oficio contra el %s" % top_sin
	if not nervous_names.is_empty():
		msg += " (%s bajó la mirada con nerviosismo)" % nervous_names[0]
	VillageChronicle.add(vm, "indirect_sermon", msg, true)
	return top_sin

# ==============================================================================
# Paso diario: cumplir penitencias, santuario y chantajes de cura corrupto
# ==============================================================================
static func daily(vm) -> void:
	var st: Dictionary = state(vm)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	# P4.4: Cumplir penitencias asignadas el día anterior
	for pk in (st["penances"] as Dictionary).keys():
		var pen: Dictionary = st["penances"][pk]
		if today() <= int(pen.get("day", 0)):
			continue
		var sinner = by_key.get(pk, null)
		st["penances"].erase(pk)
		if sinner == null or sinner.is_dead:
			continue
		if str(pen.get("kind", "")) == "donate" and int(sinner.personal_gold) >= PENANCE_DONATION:
			sinner.personal_gold -= PENANCE_DONATION
			vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + PENANCE_DONATION
			sinner.add_thought("Cumplí mi penitencia dando limosna (+4)", 4.0)
			VillageChronicle.add(vm, "penance_done", "%s cumplió su penitencia donando %d de oro para el Albergue" % [sinner.npc_name, PENANCE_DONATION], true)
		else:
			# Pide perdón al vecino con quien peor se lleva
			var worst = null
			var worst_r: int = -10
			for o in VillageNeeds.living(vm):
				if o != sinner and sinner.get_relationship_with_npc(o.get_person_key()) < worst_r:
					worst_r = sinner.get_relationship_with_npc(o.get_person_key())
					worst = o
			if worst != null:
				sinner.modify_npc_relationship(worst, 8, "Me pidió perdón por penitencia", false)
				VillageChronicle.add(vm, "penance_done", "%s pidió perdón a %s como penitencia de la capilla" % [sinner.npc_name, worst.npc_name], true)
	# P4.3: Si el sacerdote está corrompido, chantajea él mismo a un pecador rico
	var priest = vm.VillageFaith.priest_of(vm)
	if priest != null and (bool(st.get("priest_corrupted", false)) or VillageTown.corruptibility(priest) >= 0.45):
		for sk in (st["priest_secrets"] as Dictionary).keys():
			var sinner2 = by_key.get(sk, null)
			if sinner2 != null and int(sinner2.personal_gold) >= 50 and randf() < 0.15:
				var cut: int = 12
				sinner2.personal_gold -= cut
				priest.personal_gold += cut
				sinner2.modify_npc_relationship(priest, -15, "Usa mi confesión para sacarme oro", true)
				break
	# P4.5: Si alguien profanó una tumba y se sabe, el sacerdote lo excomulga
	var clans_st: Dictionary = vm.VillageClans.state(vm)
	for v_name in (clans_st.get("desecrated_graves", {}) as Dictionary).keys():
		var dg: Dictionary = clans_st["desecrated_graves"][v_name]
		var culprit = by_key.get(str(dg.get("culprit", "")), null)
		if culprit != null and not is_excommunicated(vm, culprit):
			excommunicate(vm, culprit, "profanar una tumba del cementerio")

# ==============================================================================
# Diálogos con el sacerdote y los fieles (P4.3, P4.5, P4.6, P4.9, P4.10)
# ==============================================================================
static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null or npc == null:
		return
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key()
	var opts: Array = []

	if vm.VillageFaith.is_priest(npc):
		# P4.6: Confesarte tú mismo
		opts.append({"label": "🙏🕯️ Confesar tus faltas y hacer penitencia (-%d Oro para los pobres)" % PLAYER_PENANCE_COST, "next": "END", "action": "faith_player_confess"})
		# P4.10: Derecho de santuario si tienes búsqueda menor (wanted_level == 1 y sin asesinato)
		if int(vm.wanted_level) == 1 and int(vm.player_murder_warrants_count) == 0:
			opts.append({"label": "⛪🛡️ Acogerse a derecho de santuario en la capilla (-%d Oro)" % SANCTUARY_COST, "next": "END", "action": "faith_sanctuary"})
		# P4.9: Crisis de fe del sacerdote
		if int(st.get("priest_doubt", 0)) >= 25 and not bool(st.get("priest_corrupted", false)):
			opts.append({"label": "☀️🤝 Consolar al sacerdote en su crisis de fe y devolverle la esperanza", "next": "END", "action": "faith_console_priest"})
			opts.append({"label": "🌑🐍 Tentarlo en su crisis de fe para que saque provecho de los secretos", "next": "END", "action": "faith_corrupt_priest"})
		# P4.3: Comprar secreto de confesión si el sacerdote es corruptible o fue corrompido
		if (bool(st.get("priest_corrupted", false)) or VillageTown.corruptibility(npc) >= 0.35) and not (st["priest_secrets"] as Dictionary).is_empty():
			opts.append({"label": "🤫💰 Comprarle un secreto de confesión del pueblo (-%d Oro)" % SECRET_BUY_COST, "next": "END", "action": "faith_buy_confession"})
		# P4.5: Pedir que levante la excomunión a un vecino
		for ek in (st["excommunicated"] as Dictionary).keys():
			var ex_name: String = str(st["excommunicated"][ek]["name"])
			opts.append({"label": "🕊️⛪ Interceder para que perdone y readmita en la capilla a %s (-15 Oro)" % ex_name, "next": "END", "action": "faith_lift_excomm:" + ek})
	elif is_excommunicated(vm, npc):
		opts.append({"label": "⛪🙏 Aconsejarle que haga penitencia para volver a la capilla", "next": "END", "action": "faith_urge_penance:" + key})

	if not opts.is_empty():
		opts.append({"label": "⬅️ Volver", "next": "start"})
		diag["faith_confess_menu"] = {"text": "🕯️ Confesionario, penitencias y amparo de la Capilla del Alba:", "choices": opts}
		ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🕯️ Confesión, penitencia y santuario…", "next": "faith_confess_menu"})

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	var st: Dictionary = state(vm)
	var arg: String = action_id.get_slice(":", 1)

	if action_id == "faith_player_confess":
		if inv == null or int(inv.gold) < PLAYER_PENANCE_COST:
			npc._spawn_floating_text("Necesitas %d de oro para la limosna de penitencia" % PLAYER_PENANCE_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-PLAYER_PENANCE_COST)
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + PLAYER_PENANCE_COST
		npc.modify_affinity(8)
		vm.VillageFaith.add_rep(vm, "believers", 8)
		# El sacerdote intercede ante el vecino con quien peor te llevas
		var worst = null
		var worst_aff: int = 100
		for o in VillageNeeds.living(vm):
			if o != npc and int(o.affinity) < worst_aff:
				worst_aff = int(o.affinity)
				worst = o
		if worst != null:
			worst.modify_affinity(10)
		VillageChronicle.add(vm, "player_confession", "Te confesaste en la Capilla del Alba y cumpliste penitencia por los pobres", true)
		npc._spawn_floating_text("🙏 «Tus faltas quedan perdonadas, hijo. Hablaré bien de ti en el pueblo.»", Color.SPRING_GREEN, -46.0)

	elif action_id == "faith_sanctuary":
		if inv == null or int(inv.gold) < SANCTUARY_COST:
			npc._spawn_floating_text("Necesitas %d de oro" % SANCTUARY_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-SANCTUARY_COST)
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + SANCTUARY_COST
		vm.wanted_level = 0
		VillageChronicle.add(vm, "chapel_sanctuary", "Te acogiste a santuario en la Capilla del Alba y el sacerdote medió para levantar tus cargos menores", true)
		npc._spawn_floating_text("⛪🛡️ «Bajo este techo nadie te pondrá la mano encima. He mediado con el comisario.»", Color.SPRING_GREEN, -46.0)

	elif action_id == "faith_console_priest":
		st["priest_doubt"] = 0
		st["priest_corrupted"] = false
		npc.modify_affinity(18)
		vm.VillageFaith.add_rep(vm, "believers", 10)
		VillageChronicle.add(vm, "priest_consoled", "Ayudaste al sacerdote a superar su crisis de fe en la capilla", true)
		npc._spawn_floating_text("☀️ «Gracias... tus palabras me devuelven la fuerza para guiar al pueblo.»", Color.SPRING_GREEN, -46.0)

	elif action_id == "faith_corrupt_priest":
		st["priest_corrupted"] = true
		npc.modify_affinity(12)
		VillageChronicle.add(vm, "priest_corrupted", "El sacerdote cedió a la tentación y empezó a sacar tajada de los pecados del pueblo", false)
		npc._spawn_floating_text("🌑 «Tienes razón... tanto pecado ajeno bien vale un precio.»", Color(0.85, 0.72, 1.0), -46.0)

	elif action_id == "faith_buy_confession":
		if inv == null or int(inv.gold) < SECRET_BUY_COST:
			npc._spawn_floating_text("Necesitas %d de oro" % SECRET_BUY_COST, Color.ORANGE_RED, -44.0)
			return
		var keys: Array = (st["priest_secrets"] as Dictionary).keys()
		if keys.is_empty():
			return
		inv.add_gold(-SECRET_BUY_COST)
		npc.personal_gold += SECRET_BUY_COST
		var sk: String = str(keys[0])
		var rec: Dictionary = st["priest_secrets"][sk]
		_player_learns_confessed_sin(vm, rec, "te lo vendió el sacerdote")
		st["priest_secrets"].erase(sk)
		npc._spawn_floating_text("🤫 «No oíste esto de mí: %s.»" % str(rec.get("desc", "")), Color.GOLD, -46.0)

	elif action_id.begins_with("faith_lift_excomm:"):
		if inv == null or int(inv.gold) < 15:
			npc._spawn_floating_text("Necesitas 15 de oro para la ofrenda de reconciliación", Color.ORANGE_RED, -44.0)
			return
		var target = vm._get_npcs_by_person_key().get(arg, null)
		if target == null:
			return
		inv.add_gold(-15)
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + 15
		lift_excommunication(vm, target, "gracias a tu intercesión")
		target.modify_affinity(18)
		npc._spawn_floating_text("🕊️ «Sea: %s puede volver al Oficio del domingo.»" % target.npc_name, Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("faith_urge_penance:"):
		if int(npc.personal_gold) >= PENANCE_DONATION:
			npc.personal_gold -= PENANCE_DONATION
			vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + PENANCE_DONATION
		lift_excommunication(vm, npc, "cumplió penitencia")
		npc.modify_affinity(12)
		npc._spawn_floating_text("🙏 «Tienes razón, haré penitencia hoy mismo.»", Color.SPRING_GREEN, -46.0)
