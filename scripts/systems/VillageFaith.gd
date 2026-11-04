@tool
extends RefCounted

## Grupos y fe (bloques G, `docs/PLAN_GRUPOS_FE.md`).
## - G1: la Fe del Alba (religión inventada, provisional). Cada vecino tiene un grado de fe según sus rasgos.
## - G2: semana de 7 días; fin de semana con menos trabajo; el domingo por la mañana, el Oficio del Alba en la capilla.
## - G3: el sacerdote (oficio PRIEST) dirige el Oficio y su opinión pesa en los asistentes.
## - G4: bandos que se detectan solos (familias, pandillas y seguidores de un Líder) y defienden a los suyos.
## - G5/G6: tu reputación con los creyentes, los escépticos y cada bando; diálogo con el sacerdote.
## Estado guardado en `vm.faith_state`; los bandos se recalculan cada día en `vm.faith_bands`.

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")

const FAITH_NAME: String = "la Fe del Alba"
const RITE_NAME: String = "Oficio del Alba"
const LORE_TEXT: String = "«Creemos en el Hacedor, que encendió el primer Alba y puso una chispa de su luz en cada criatura.\n\nEl Libro del Alba nos pide tres cosas: compartir el pan con quien no lo tiene, perdonar a quien se arrepiente y no derramar sangre inocente. Su señal es el círculo del sol naciente.\n\nCada domingo por la mañana celebramos el Oficio del Alba aquí, en la capilla. Todo el que quiera es bienvenido, crea mucho o poco.»"

## Grados de fe (a partir de la tendencia «faith» de los rasgos)
const GRADE_FERVENT: String = "fervoroso"
const GRADE_BELIEVER: String = "creyente"
const GRADE_LUKEWARM: String = "tibio"
const GRADE_SKEPTIC: String = "escéptico"
const GRADE_LABEL: Dictionary = {"fervoroso": "🔥 Fervoroso", "creyente": "☀️ Creyente", "tibio": "🌫️ Tibio", "escéptico": "🤨 Escéptico"}
const FERVENT_MIN: float = 1.0
const BELIEVER_MIN: float = 0.4
const SKEPTIC_MAX: float = -0.5

## Oficio semanal (domingo): se llama a los fieles a las 8, empieza a las 9 y termina a las 11
const RITE_CALL_HOURS: Array[int] = [8, 9, 10]
const RITE_END_HOUR: int = 11
const ATTEND_CHANCE: Dictionary = {"fervoroso": 100, "creyente": 85, "tibio": 30, "escéptico": 0}
const ATTEND_RADIUS: float = 40.0
const PLAYER_RADIUS: float = 150.0
const RITE_BOND: int = 2 # Asistentes entre sí (+1 si los dos creen)
const ABSENT_NOTE: int = -2 # Lo que el fervoroso piensa del creyente que faltó
const SERMON_REL: int = -3 # Si el sacerdote habla mal de alguien en el Oficio
const SERMON_ENEMY_REL: int = -40
const PLAYER_ATTEND_AFF: int = 3
const PLAYER_ATTEND_REP: int = 5
const RITE_GOSSIP_TRIES: int = 6

## Roces y simpatías diarias por la fe
const FAITH_DAILY_CHANCE: float = 0.10
const FAITH_FRICTION: int = -2
const FAITH_KINSHIP: int = 1

## Bandos
const GANG_MIN_REL: int = 50 # Una pandilla: 3 o más que se aprecian así entre todos
const FOLLOW_MIN_REL: int = 40
const FOLLOW_FAN_REL: int = 70
const LEADER_MIN: float = 0.8
const BAND_DEFEND: int = -4 # Manía del bando contra quien daña a uno de los suyos
const BAND_DEFEND_MIN_REL: int = 30 # Solo si el miembro aprecia al afectado
const HARM_TYPES: Array[String] = ["fight", "npc_slander", "blackmail"]
const BAND_GOSSIP_BONUS: float = 0.15

## Reputación del jugador por grupo
const DONATION_GOLD: int = 10
const DONATION_REP: int = 4
const MOCK_AFF: int = -12
const MOCK_REP: int = -8
const MOCK_SKEPTIC_REP: int = 4
const MOCK_WITNESS_AFF: int = -4
const BAND_REP_DIV: int = 4

static func _state(vm) -> Dictionary:
	if not (vm.faith_state is Dictionary):
		vm.faith_state = {}
	for k in ["rep", "seen"]:
		if not vm.faith_state.has(k):
			vm.faith_state[k] = {}
	return vm.faith_state

# ---------------------------------------------------------------- G1: fe

static func faith_score(npc) -> float:
	return TraitCatalog.npc_tendency(npc, "faith")

static func grade_of(npc) -> String:
	if is_priest(npc):
		return GRADE_FERVENT
	var f: float = faith_score(npc)
	if f >= FERVENT_MIN:
		return GRADE_FERVENT
	if f >= BELIEVER_MIN:
		return GRADE_BELIEVER
	if f <= SKEPTIC_MAX:
		return GRADE_SKEPTIC
	return GRADE_LUKEWARM

static func is_believer(npc) -> bool:
	return grade_of(npc) in [GRADE_FERVENT, GRADE_BELIEVER]

static func is_priest(npc) -> bool:
	return npc != null and int(npc.trade_role) == int(VillageNPC.TradeRole.PRIEST)

## El jugador conoce su fe si sabe uno de sus rasgos de fe, le vio en el Oficio o se lo preguntó.
static func grade_known(vm, npc) -> bool:
	if is_priest(npc):
		return true
	if bool(_state(vm)["seen"].get(npc.get_person_key(), false)):
		return true
	for t in npc.known_traits:
		if TraitCatalog.axis_of(str(t)) == "fe" or str(t) in ["Místico", "Supersticioso"]:
			return true
	return false

static func grade_text(vm, npc) -> String:
	return str(GRADE_LABEL.get(grade_of(npc), "❓")) if grade_known(vm, npc) else "❓"

static func priest_of(vm):
	for n in _living(vm):
		if is_priest(n):
			return n
	return null

## El sacerdote siempre tiene fe: si llega uno nuevo sin ella, se le da el rasgo Devoto.
static func ensure_priest_faith(npc) -> void:
	if npc == null or npc.person_profile == null or faith_score(npc) >= FERVENT_MIN:
		return
	var keep: Array[String] = []
	for t in npc.person_profile.personality:
		if TraitCatalog.axis_of(str(t)) != "fe" and not TraitCatalog.conflicts(str(t), "Devoto"):
			keep.append(str(t))
	while keep.size() >= 6:
		keep.pop_back()
	keep.append("Devoto")
	npc.person_profile.personality.assign(keep)

# ---------------------------------------------------------------- G2: semana y Oficio

static func is_rite_day() -> bool:
	return WorldClock != null and WorldClock.has_method("is_rite_day") and bool(WorldClock.call("is_rite_day"))

static func _week() -> int:
	return int(float(int(WorldClock.current_day) - 1) / 7.0) if WorldClock else 0

## Decide si va esta semana (fijo por semana para que no cambie de idea cada hora).
static func wants_attend(npc, week: int) -> bool:
	if is_priest(npc):
		return true
	var vm_s = npc._get_vm() if npc.has_method("_get_vm") else null
	if vm_s != null and vm_s.VillageConfession.is_excommunicated(vm_s, npc):
		return false # P4.8: excomulgado no va al Oficio
	if npc.has_meta("rite_invited_week") and int(npc.get_meta("rite_invited_week")) == week and grade_of(npc) != GRADE_SKEPTIC:
		return true # M7: el jugador le invitó a venir este domingo
	var ch: int = int(ATTEND_CHANCE.get(grade_of(npc), 0))
	if vm_s != null and "sect_state" in vm_s and vm_s.sect_state is Dictionary and (vm_s.sect_state.get("members", {}) as Dictionary).has(npc.get_person_key()):
		ch = int(ch * 0.4) # O4: los de la secta van poco al Oficio (solo para disimular)
	return ch > 0 and (abs(("%s#%d" % [npc.get_person_key(), week]).hash()) % 100) < ch

static func can_join(npc) -> bool:
	if npc.is_dead or npc.is_downed or npc.is_hostile or not npc.is_conscious():
		return false
	if npc.hangout_id >= 0 or npc.is_in_live_fight() or npc.is_busy_with_player():
		return false
	if int(npc.trade_role) in [int(VillageNPC.TradeRole.TRAVELING_MERCHANT), int(VillageNPC.TradeRole.ROYAL_INVESTIGATOR), int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)]:
		return false
	if not (int(npc.current_activity) in [int(VillageNPC.ActivityState.WORKING), int(VillageNPC.ActivityState.SOCIALIZING)]):
		return false
	return npc.need_energy > 15.0 and npc.need_hunger > 30.0

static func _pew_spot(vm, i: int) -> Vector2:
	var side: float = -36.0 if i % 2 == 0 else 36.0
	var row: int = int(float(i) / 2.0) % 4
	return vm._church_center + Vector2(side + float((int(float(i) / 8.0) % 2) * 8 - 4), -18.0 + float(row) * 8.0)

static func on_hour(vm, hour: int) -> void:
	if not is_rite_day():
		return
	if hour in RITE_CALL_HOURS:
		call_to_rite(vm)
	elif hour == RITE_END_HOUR:
		finish_rite(vm)

static func call_to_rite(vm) -> int:
	var week: int = _week()
	var idx: int = 0
	var called: int = 0
	for n in _living(vm):
		if n.rite_pos != Vector2.ZERO:
			idx += 1
			continue
		if not wants_attend(n, week) or not can_join(n):
			continue
		var spot: Vector2 = (vm._church_altar_pos + Vector2(0, -12)) if is_priest(n) else _pew_spot(vm, idx)
		if not is_priest(n):
			idx += 1
		n.join_rite(spot)
		called += 1
	return called

## Fin del Oficio: los que llegaron cuentan como asistentes. Devuelve un resumen (para tests y sonda).
static func finish_rite(vm) -> Dictionary:
	var st: Dictionary = _state(vm)
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	var att: Array = []
	for n in _living(vm):
		if n.rite_pos == Vector2.ZERO:
			continue
		if n.global_position.distance_to(n.rite_pos) <= ATTEND_RADIUS:
			att.append(n)
		n.leave_rite()
	var res: Dictionary = {"attendees": att.size(), "absent_noted": 0, "sermon": "", "player": false}
	if int(st.get("last_rite_day", -1)) == today:
		return res
	st["last_rite_day"] = today
	st["last_attendees"] = att.map(func(x): return x.get_person_key()) # M7: quién vino
	st["rites"] = int(st.get("rites", 0)) + 1
	st["attend_total"] = int(st.get("attend_total", 0)) + att.size()
	if att.is_empty():
		return res
	# Los asistentes congenian
	for i in range(att.size()):
		for j in range(i + 1, att.size()):
			var both: bool = is_believer(att[i]) and is_believer(att[j])
			att[i].modify_npc_relationship(att[j], RITE_BOND + (1 if both else 0), "Coincidimos en el %s" % RITE_NAME)
	# Y se cuentan las novedades
	if att.size() >= 2:
		for _k in range(RITE_GOSSIP_TRIES):
			var a = att[randi() % att.size()]
			var b = att[randi() % att.size()]
			if a != b:
				vm.spread_gossip(a, b)
	# Los fervorosos se fijan en qué creyentes faltaron
	var absent: Array = []
	for n in _living(vm):
		if not (n in att) and is_believer(n) and not is_priest(n):
			absent.append(n)
	for m in att:
		if grade_of(m) != GRADE_FERVENT or is_priest(m):
			continue
		for x in absent:
			m.modify_npc_relationship(x, ABSENT_NOTE, "No vino al %s" % RITE_NAME, true)
			res["absent_noted"] = int(res["absent_noted"]) + 1
	# El sermón: si el sacerdote detesta a alguien, los asistentes le miran peor
	vm.VillageConfession.apply_sunday_indirect_sermon(vm, att) # P4.3: sermón con indirectas sobre pecados confesados
	var priest = priest_of(vm)
	if priest != null and priest in att:
		var worst = null
		var worst_rel: int = SERMON_ENEMY_REL + 1
		for n in _living(vm):
			if n == priest:
				continue
			var r: int = priest.get_relationship_with_npc(n.get_person_key())
			if r < worst_rel:
				worst_rel = r
				worst = n
		if worst != null:
			for m in att:
				if m != priest and m != worst:
					m.modify_npc_relationship(worst, SERMON_REL, "El sacerdote habló mal de %s en el %s" % [worst.npc_name, RITE_NAME], true)
			res["sermon"] = worst.npc_name
	# El jugador
	var pl = vm.get_tree().get_first_node_in_group("player") if vm.is_inside_tree() else null
	var player_here: bool = pl is Node2D and (pl as Node2D).global_position.distance_to(vm._church_altar_pos) <= PLAYER_RADIUS
	res["player"] = player_here
	if player_here:
		for m in att:
			st["seen"][m.get_person_key()] = true
			if is_believer(m):
				m.modify_affinity(PLAYER_ATTEND_AFF)
		add_rep(vm, "faith", PLAYER_ATTEND_REP)
	var who: String = (" con %s" % priest.npc_name) if priest != null and priest in att else ""
	var txt: String = "%s%s: %d vecinos en la capilla" % [RITE_NAME, who, att.size()]
	if str(res["sermon"]) != "":
		txt += "; en el sermón se habló mal de %s" % res["sermon"]
	VillageChronicle.add(vm, "rite", txt, true)
	return res

## Roces y simpatías diarias: un fervoroso y un escéptico chocan; dos creyentes se entienden.
static func daily(vm) -> void:
	var p = priest_of(vm)
	if p != null:
		ensure_priest_faith(p)
	refresh_bands(vm)
	var people: Array = _living(vm)
	for i in range(people.size()):
		for j in range(i + 1, people.size()):
			var a = people[i]
			var b = people[j]
			var ga: String = grade_of(a)
			var gb: String = grade_of(b)
			if (ga == GRADE_FERVENT and gb == GRADE_SKEPTIC) or (ga == GRADE_SKEPTIC and gb == GRADE_FERVENT):
				if randf() < FAITH_DAILY_CHANCE:
					var sk = a if ga == GRADE_SKEPTIC else b
					var fv = b if sk == a else a
					fv.modify_npc_relationship(sk, FAITH_FRICTION, "Se burla de la fe", true)
					sk.modify_npc_relationship(fv, FAITH_FRICTION, "Su fe no admite dudas", true)
			elif is_believer(a) and is_believer(b) and randf() < FAITH_DAILY_CHANCE:
				a.modify_npc_relationship(b, FAITH_KINSHIP, "Compartimos la fe")

# ---------------------------------------------------------------- G4: bandos

static func refresh_bands(vm) -> Array:
	var people: Array = _living(vm)
	var bands: Array = []
	# Familias (dos o más vivos)
	var fams: Dictionary = {}
	for n in people:
		var fid: String = str(n.family_id)
		if fid in ["", "none"]:
			continue
		if not fams.has(fid):
			fams[fid] = {"id": "fam:" + fid, "kind": "family", "name": str(n.family_name), "members": [], "leader": ""}
		fams[fid]["members"].append(n.get_person_key())
	for f in fams.values():
		if (f["members"] as Array).size() >= 2:
			bands.append(f)
	# Pandillas: grupos de 3+ que se aprecian mucho entre todos
	var seen_sets: Dictionary = {}
	for n in people:
		var group: Array = [n]
		for c in people:
			if c == n:
				continue
			var ok: bool = true
			for g in group:
				if g.get_relationship_with_npc(c.get_person_key()) < GANG_MIN_REL or c.get_relationship_with_npc(g.get_person_key()) < GANG_MIN_REL:
					ok = false
					break
			if ok:
				group.append(c)
		if group.size() < 3:
			continue
		var keys: Array = []
		for g in group:
			keys.append(g.get_person_key())
		keys.sort()
		var sig: String = ",".join(keys)
		if seen_sets.has(sig):
			continue
		seen_sets[sig] = true
		bands.append({"id": "gang:" + str(keys[0]), "kind": "gang", "name": "Pandilla de %s" % n.npc_name, "members": keys, "leader": ""})
	# Seguidores de un Líder
	for l in people:
		if TraitCatalog.npc_tendency(l, "leadership") < LEADER_MIN:
			continue
		var members: Array = [l.get_person_key()]
		for f in people:
			if f == l:
				continue
			var r: int = f.get_relationship_with_npc(l.get_person_key())
			if r >= FOLLOW_FAN_REL or (r >= FOLLOW_MIN_REL and TraitCatalog.npc_tendency(f, "leadership") <= -0.5):
				members.append(f.get_person_key())
		if members.size() >= 3:
			bands.append({"id": "lead:" + l.get_person_key(), "kind": "followers", "name": "Seguidores de %s" % l.npc_name, "members": members, "leader": l.get_person_key()})
	vm.faith_bands = bands
	return bands

static func bands_of(vm, key: String) -> Array:
	var out: Array = []
	for b in vm.faith_bands:
		if key in (b["members"] as Array):
			out.append(b)
	return out

static func same_band(vm, a, b) -> bool:
	if vm == null or a == null or b == null:
		return false
	var kb: String = b.get_person_key()
	for band in bands_of(vm, a.get_person_key()):
		if kb in (band["members"] as Array):
			return true
	return false

## Un bando defiende a los suyos: los que aprecian al dañado cogen manía al que le dañó (una vez por suceso).
static func on_social_event(vm, ev: Dictionary, actor, target) -> int:
	if not (str(ev.get("type", "")) in HARM_TYPES) or actor == null or target == null:
		return 0
	var tk: String = target.get_person_key()
	var ak: String = actor.get_person_key()
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var done: Dictionary = {}
	for band in bands_of(vm, tk):
		if ak in (band["members"] as Array):
			continue # Riñas dentro del mismo bando: no se toma partido
		for mk in band["members"]:
			if mk == tk or mk == ak or done.has(mk):
				continue
			var m = by_key.get(mk, null)
			if m == null or m.is_dead or m.get_relationship_with_npc(tk) < BAND_DEFEND_MIN_REL:
				continue
			done[mk] = true
			m.modify_npc_relationship(actor, BAND_DEFEND, "Se metió con %s, de los nuestros" % target.npc_name, true)
	if not done.is_empty():
		VillageChronicle.add(vm, "band_defend", "%d del entorno de %s le cogen manía a %s" % [done.size(), target.npc_name, actor.npc_name], false)
	return done.size()

# ---------------------------------------------------------------- G5: reputación por grupo

static func add_rep(vm, group_id: String, delta: int) -> void:
	var rep: Dictionary = _state(vm)["rep"]
	rep[group_id] = clampi(int(rep.get(group_id, 0)) + delta, -100, 100)

static func rep_of(vm, group_id: String) -> int:
	return int(_state(vm)["rep"].get(group_id, 0))

## Ayudar o dañar a un vecino cuenta, un poco, con todos sus bandos.
static func on_affinity_change(vm, npc, delta: int) -> void:
	if vm == null or not ("faith_bands" in vm) or absi(delta) < 3:
		return
	var step: int = signi(delta) * maxi(1, int(float(absi(delta)) / float(BAND_REP_DIV)))
	for band in bands_of(vm, npc.get_person_key()):
		add_rep(vm, str(band["id"]), step)

## Línea del glosario social (J): fe del vecino, sus bandos y tu reputación con ellos.
static func glossary_line(vm, npc) -> String:
	var parts: Array[String] = []
	for band in bands_of(vm, npc.get_person_key()):
		if bool(band.get("hidden", false)):
			continue # O: la secta no se ve aquí (tiene su propia línea si la conoces)
		parts.append("%s (tú: %+d)" % [band["name"], rep_of(vm, str(band["id"]))])
	var band_txt: String = ", ".join(parts) if not parts.is_empty() else "ninguno"
	return "[color=#ffe08a][b]☀️ Fe:[/b][/color] %s   [color=#ffe08a][b]🛡️ Bandos:[/b][/color] %s   [color=#ffe08a][b]Tu fama:[/b][/color] creyentes %+d, escépticos %+d" % [
		grade_text(vm, npc), band_txt, rep_of(vm, "faith"), rep_of(vm, "skeptics")]

# ---------------------------------------------------------------- G6: diálogo

static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null:
		return
	var pos: int = maxi(0, ch_arr.size() - 1)
	var back: Array = [{"label": "⬅️ Volver a la conversación", "next": "start"}]
	if is_priest(npc):
		ch_arr.insert(pos, {"label": "☀️ Preguntar por %s" % FAITH_NAME, "next": "faith_lore"})
		diag["faith_lore"] = {"text": LORE_TEXT, "choices": [
			{"label": "🪙 Donar %d de oro a la capilla" % DONATION_GOLD, "next": "END", "action": "faith_donate"},
			{"label": "😏 Burlarte de su fe", "next": "END", "action": "faith_mock"},
			back[0]]}
		return
	ch_arr.insert(pos, {"label": "☀️ Preguntar si va al %s" % RITE_NAME, "next": "faith_ask", "action": "faith_ask"})
	var ans: String = "«Eso es cosa mía.»"
	if npc.affinity >= 0:
		match grade_of(npc):
			GRADE_FERVENT: ans = "«¡Nunca falto! El Hacedor nos ve a todos, y yo no quiero que me vea tumbado un domingo.»"
			GRADE_BELIEVER: ans = "«Casi todos los domingos. Me hace bien.»"
			GRADE_LUKEWARM: ans = "«Alguna vez, cuando me pilla con ganas.»"
			GRADE_SKEPTIC: ans = "«¿Al Oficio? Prefiero dormir. Eso son cuentos.»"
	diag["faith_ask"] = {"text": ans, "choices": back}

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	match action_id:
		"faith_ask":
			if npc.affinity >= 0:
				_state(vm)["seen"][npc.get_person_key()] = true
		"faith_donate":
			if inv == null or int(inv.gold) < DONATION_GOLD:
				npc._spawn_floating_text("🙏 «Gracias, pero guarda tu oro; no te sobra.»", Color(1.0, 0.92, 0.65), -46.0)
				return
			inv.add_gold(-DONATION_GOLD)
			npc.personal_gold = maxi(0, npc.personal_gold) + DONATION_GOLD
			npc.modify_affinity(4)
			add_rep(vm, "faith", DONATION_REP)
			npc._spawn_floating_text("☀️ «Que el Alba te guarde. Irá para el pan de los pobres.»", Color(1.0, 0.92, 0.65), -46.0)
			VillageChronicle.add(vm, "faith_donation", "Donaste %d de oro a la capilla" % DONATION_GOLD, true)
		"faith_mock":
			npc.modify_affinity(MOCK_AFF)
			add_rep(vm, "faith", MOCK_REP)
			add_rep(vm, "skeptics", MOCK_SKEPTIC_REP)
			npc._spawn_floating_text("😠 «Que el Hacedor te perdone, porque yo no sé si podré.»", Color.ORANGE, -46.0)
			for n in _living(vm):
				if n == npc or not n.is_conscious() or n.global_position.distance_to(npc.global_position) > VillageChronicle.WITNESS_RADIUS:
					continue
				if is_believer(n):
					n.modify_affinity(MOCK_WITNESS_AFF)
				elif grade_of(n) == GRADE_SKEPTIC:
					n.modify_affinity(2)
			VillageChronicle.add(vm, "faith_mock", "Te burlaste de %s delante de %s" % [FAITH_NAME, npc.npc_name], true)

# ---------------------------------------------------------------- util

static func _living(vm) -> Array:
	var out: Array = []
	for n in vm._get_npcs_by_person_key().values():
		if is_instance_valid(n) and not n.is_dead:
			out.append(n)
	return out
