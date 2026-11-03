@tool
extends RefCounted

## La secta secreta (bloques O, `docs/PLAN_SECTA.md`). Nombres, lore y rangos son PROVISIONALES (ver docs/APORTES_CREATIVOS.md).
## Nada está programado por fecha: una secta nace solo si se juntan un pueblo que lo pasa mal (o ricos aburridos)
## y alguien con poder de convencimiento y un motivo. Crece despacio, tiene un techo (~13) y se apaga poco a poco si
## la crisis pasa. Puede no nacer nunca.
## - O1: nacimiento (clima del pueblo × labia del líder × su motivo). Dos clases: «desesperados» y «ricos aburridos».
## - O2: captación lenta según la labia de quien capta y el mal momento (o el aburrimiento) del otro.
## - O3: reunión semanal que elige el líder (los desesperados, de madrugada en el cementerio; los ricos, en su casa).
## - O4: diezmo, votan juntos, se encubren (bando oculto), profanan la capilla y, muy raramente, un rito de sangre.
## - O5: las pistas suben la sospecha; si llega al tope o la denuncias, se destapa y se disuelve.
## - O6: el jugador puede descubrirla, chantajear, denunciar o unirse (rangos).
## Estado en `vm.sect_state` (se guarda).

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageFaith = preload("res://scripts/systems/VillageFaith.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")

const KIND_DESPERATE: String = "desperate"
const KIND_RICH: String = "rich"
const NAMES: Dictionary = {"desperate": "los Hijos del Ocaso", "rich": "el Círculo de la Luna Velada"}
const NAMES_CAP: Dictionary = {"desperate": "Los Hijos del Ocaso", "rich": "El Círculo de la Luna Velada"}
const SECT_SIGN: String = "sol negro"
const RANK_NAMES: Array[String] = ["Iniciado", "Hermano de la Sombra", "Mano del Ocaso"]
const RANK_MEETINGS: Array[int] = [0, 3, 6]
const LORE: Dictionary = {
	"desperate": "«El Alba es una mentira para tenernos quietos. Antes del Hacedor estaba la Noche, y la Noche volverá. Los que la esperan con los ojos abiertos no tendrán que temerla.\n\nNos vemos de madrugada, en el cementerio. Nadie debe saberlo. Nadie.»",
	"rich": "«Los demás rezan al Alba porque no conocen nada mejor. Nosotros sí: hay saberes antiguos que no son para cualquiera, y placeres que el Libro prohíbe.\n\nNos reunimos de noche, en mi casa. Solo gente de nuestra posición. Discreción absoluta.»",
}
const WEEKDAY_NAMES: Array[String] = ["los lunes", "los martes", "los miércoles", "los jueves", "los viernes", "los sábados", "los domingos"]

## Nacimiento
const PERSUADE_MIN: float = 0.45
const FOUND_BASE: float = 0.03
const CRISIS_MIN: float = 0.18
const BOREDOM_MIN: float = 0.25
const DISCREDIT: float = 0.6
const MIN_AGE: int = 16

## Crecimiento y declive (lentos)
const MAX_MEMBERS: int = 13
const RECRUIT_TRY_BASE: float = 0.12
const RECRUIT_TRY_PER_MEMBER: float = 0.015
const RECRUIT_MIN_REL: int = 10
const REFUSAL_REL: int = -5
const LEAVE_NEED: float = 0.12
const LEAVE_CHANCE: float = 0.008
const LOYAL_DAYS: float = 60.0
const GIVE_UP_CHANCE: float = 0.004

## Reunión
const MEETING_RADIUS: float = 50.0
const PLAYER_SPOT_RADIUS: float = 200.0
const MEETING_BOND: int = 3
const MEETING_PRIEST_REL: int = -2
const NIGHT_WITNESS_CHANCE: float = 0.2
const TITHE_MAX: Dictionary = {"desperate": 3, "rich": 10}
const POOR_HELP: int = 5
const PLAYER_RANK_PAY: int = 8

## Sospecha del pueblo (0..100): al tope el sacerdote los señala
const SUSPICION_REFUSAL: int = 8
const SUSPICION_NIGHT: int = 3
const SUSPICION_PROFANE: int = 15
const SUSPICION_LEAK: int = 10
const SUSPICION_RITE: int = 30
const SUSPICION_DECAY: int = 2
const SUSPICION_MAX: int = 100
const PROFANE_CHANCE: Dictionary = {"desperate": 0.3, "rich": 0.08}
const PROFANE_MIN_MEMBERS: int = 3
const PROFANE_SHOW_DAYS: int = 3

## Rito de sangre: muy raro, con señales antes
const RITE_MIN_AGE_DAYS: int = 21
const RITE_MIN_MEMBERS: int = 4
const RITE_DARKNESS: float = 1.0
const RITE_PLAN_CHANCE: float = 0.25
const RITE_GLOBAL_GAP: int = 10
const RITE_LEAK_CHANCE: float = 0.3
const RITE_MAX_TRIES: int = 2

const EXPOSE_REL: int = -15
const EXPOSE_FINE: int = 20
const BLACKMAIL_GOLD: int = 15
const PLAYER_JOIN_AFF: int = 45
const PLAYER_ASK_AFF: int = 30
const PLAYER_MISS_LIMIT: int = 3

static func state(vm) -> Dictionary:
	if not (vm.sect_state is Dictionary):
		vm.sect_state = {}
	var st: Dictionary = vm.sect_state
	for k in ["members", "known", "player_attend", "discredited", "seen"]:
		if not st.has(k) or not (st[k] is Dictionary):
			st[k] = {}
	for k in ["gold", "suspicion", "meetings", "recruits", "refusals", "leavers", "profanations", "rites", "exposed", "foundings", "player_meetings", "player_misses", "crisis_events"]:
		if not st.has(k):
			st[k] = 0
	for k in ["founder", "founder_name", "plan_victim", "plan_victim_name", "invite_by"]:
		if not st.has(k):
			st[k] = ""
	if not st.has("kind"):
		st["kind"] = KIND_DESPERATE
	return st

static func kind_of(vm) -> String:
	return str(state(vm)["kind"])

static func sect_name(vm) -> String:
	return str(NAMES.get(kind_of(vm), NAMES[KIND_DESPERATE]))

static func sect_name_cap(vm) -> String:
	return str(NAMES_CAP.get(kind_of(vm), NAMES_CAP[KIND_DESPERATE]))

static func active(vm) -> bool:
	return str(state(vm)["founder"]) != ""

static func is_member(vm, npc) -> bool:
	return npc != null and vm != null and "sect_state" in vm and vm.sect_state is Dictionary and (vm.sect_state.get("members", {}) as Dictionary).has(npc.get_person_key())

static func player_member(vm) -> bool:
	return bool(state(vm).get("player_member", false))

static func player_knows_sect(vm) -> bool:
	return bool(state(vm).get("player_knows", false)) or player_member(vm)

## El jugador sabe que este vecino es de la secta.
static func known_member(vm, npc) -> bool:
	if not is_member(vm, npc):
		return false
	return player_member(vm) or (state(vm)["known"] as Dictionary).has(npc.get_person_key())

static func member_nodes(vm) -> Array:
	var out: Array = []
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for k in (state(vm)["members"] as Dictionary).keys():
		var n = by_key.get(k, null)
		if n != null and is_instance_valid(n) and not n.is_dead:
			out.append(n)
	return out

static func founder_of(vm):
	var n = vm._get_npcs_by_person_key().get(str(state(vm)["founder"]), null)
	return n if n != null and is_instance_valid(n) and not n.is_dead else null

static func _protected_role(npc) -> bool:
	return int(npc.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.PRIEST),
		int(VillageNPC.TradeRole.ROYAL_INVESTIGATOR), int(VillageNPC.TradeRole.TRAVELING_MERCHANT)]

static func _can_be_member(npc) -> bool:
	if npc == null or npc.is_dead or VillageNeeds.is_outsider(npc) or _protected_role(npc) or npc.person_profile == null:
		return false
	return int(npc.person_profile.age) >= MIN_AGE

static func _has(npc, trait_name: String) -> bool:
	return npc.person_profile != null and trait_name in npc.person_profile.personality

static func darkness(npc) -> float:
	return TraitCatalog.npc_tendency(npc, "malice") + TraitCatalog.npc_tendency(npc, "aggression") - TraitCatalog.npc_tendency(npc, "honesty")

# ---------------------------------------------------------------- O1 cómo nace

## Lo mal que lo pasa un vecino ahora mismo (0..1): ánimo, pobreza, enfermedad, vicio, soledad, rencor, duelo, hambre.
static func crisis_of(vm, npc) -> float:
	var c: float = 0.0
	c += clampf((55.0 - float(npc.mood)) / 55.0, 0.0, 1.0) * 0.35
	match VillageNeeds.class_of(npc):
		"pobre": c += 0.15
		"mendigo": c += 0.25
	var key: String = npc.get_person_key()
	if not (VillageNeeds.state(vm)["ill"].get(key, {}) as Dictionary).is_empty():
		c += 0.12
	if VillageNeeds.is_addicted(vm, key, "drink") or VillageNeeds.is_addicted(vm, key, "gamble"):
		c += 0.12
	var friends: int = 0
	var worst: int = 100
	for o in VillageNeeds.living(vm):
		if o == npc:
			continue
		var r: int = npc.get_relationship_with_npc(o.get_person_key())
		if r >= 40:
			friends += 1
		worst = mini(worst, r)
	if friends < 2:
		c += 0.1
	if worst <= -50:
		c += 0.08
	if npc.person_profile != null and str(npc.person_profile.get("deceased_partner_name")) not in ["", "<null>"]:
		c += 0.12
	if npc.need_hunger < 25.0:
		c += 0.08
	if _has(npc, "Melancólico"):
		c += 0.05
	return clampf(c, 0.0, 1.0)

## El aburrimiento del rico satisfecho (0..1).
static func boredom_of(npc) -> float:
	if not (VillageNeeds.class_of(npc) in ["rico", "acomodado"]) or float(npc.mood) < 50.0:
		return 0.0
	var b: float = 0.2 if VillageNeeds.class_of(npc) == "rico" else 0.08
	for t in ["Aventurero", "Tahúr", "Noctámbulo", "Místico", "Vanidoso", "Curioso"]:
		if _has(npc, t):
			b += 0.08
	b += 0.1 * maxf(0.0, TraitCatalog.npc_tendency(npc, "ambition"))
	b -= 0.1 * maxf(0.0, TraitCatalog.npc_tendency(npc, "diligence"))
	return clampf(b, 0.0, 1.0)

## El clima del pueblo: media de malestar más los golpes recientes (muertes, robos, escándalos, epidemias).
static func town_crisis(vm) -> float:
	var tot: float = 0.0
	var n: int = 0
	for v in VillageNeeds.living(vm):
		if VillageNeeds.is_outsider(v):
			continue
		tot += crisis_of(vm, v)
		n += 1
	return clampf((tot / float(maxi(1, n))) + float(state(vm)["crisis_events"]), 0.0, 1.0)

static func town_boredom(vm) -> float:
	var tot: float = 0.0
	var n: int = 0
	for v in VillageNeeds.living(vm):
		if VillageNeeds.class_of(v) in ["rico", "acomodado"] and not VillageNeeds.is_outsider(v):
			tot += boredom_of(v)
			n += 1
	return tot / float(maxi(1, n)) if n >= 3 else 0.0

## Los golpes recientes del pueblo suben el malestar general y se olvidan poco a poco.
static func _track_crisis_events(vm) -> void:
	var st: Dictionary = state(vm)
	var seen: Dictionary = st["seen"]
	var ns: Dictionary = VillageNeeds.state(vm)
	var ts: Dictionary = vm.town_state if ("town_state" in vm and vm.town_state is Dictionary) else {}
	var now: Dictionary = {
		"deaths": int(ns.get("illness_deaths", 0)) + (vm.npc_murders as Dictionary).size(),
		"thefts": (ns.get("thefts", []) as Array).size(),
		"infections": int(ns.get("infections", 0)),
		"scandals": int(ts.get("exposed", 0)),
	}
	var weight: Dictionary = {"deaths": 0.06, "thefts": 0.015, "infections": 0.008, "scandals": 0.04}
	var ev: float = float(st["crisis_events"]) * 0.94
	for k in now.keys():
		var d: int = int(now[k]) - int(seen.get(k, now[k]))
		if d > 0:
			ev += float(d) * float(weight[k])
		seen[k] = now[k]
	st["crisis_events"] = minf(0.4, ev)

## Poder de convencimiento: mando, trato, labia (Manipulador), misticismo, y lo que le aprecia el pueblo.
static func persuasion(vm, npc) -> float:
	var p: float = 0.5 * maxf(0.0, TraitCatalog.npc_tendency(npc, "leadership"))
	p += 0.25 * TraitCatalog.npc_tendency(npc, "sociability")
	p += 0.15 * maxf(0.0, TraitCatalog.npc_tendency(npc, "ambition"))
	p += 0.5 if _has(npc, "Manipulador") else 0.0
	p += 0.3 if _has(npc, "Místico") else 0.0
	p += 0.3 if _has(npc, "Fanático") else 0.0
	var tot: int = 0
	var n: int = 0
	for o in VillageNeeds.living(vm):
		if o != npc and not VillageNeeds.is_outsider(o):
			tot += o.get_relationship_with_npc(npc.get_person_key())
			n += 1
	p += float(tot) / float(maxi(1, n)) / 200.0
	if (state(vm)["discredited"] as Dictionary).has(npc.get_person_key()):
		p -= DISCREDIT
	return p

## Por qué querría alguien fundar una secta: lo pasa mal, se aburre, ambiciona o está resentido con el Alba.
static func motive(vm, npc) -> float:
	var m: float = maxf(crisis_of(vm, npc), boredom_of(npc))
	if TraitCatalog.npc_tendency(npc, "ambition") >= 0.5:
		m = maxf(m, 0.4)
	if _has(npc, "Manipulador") or _has(npc, "Codicioso"):
		m = maxf(m, 0.4) # El oportunista ve en la desesperación ajena una ocasión de poder y dinero
	var priest = VillageFaith.priest_of(vm)
	if VillageFaith.grade_of(npc) == VillageFaith.GRADE_SKEPTIC or (priest != null and npc.get_person_key() != priest.get_person_key() and npc.get_relationship_with_npc(priest.get_person_key()) <= -30):
		m = maxf(m, 0.3)
	if _has(npc, "Íntegro") or VillageFaith.grade_of(npc) == VillageFaith.GRADE_FERVENT and not _has(npc, "Fanático"):
		m *= 0.3
	return m

## Probabilidad de que `npc` funde hoy una secta, y de qué clase. {"p": float, "kind": String}
static func found_chance(vm, npc, crisis: float, boredom: float) -> Dictionary:
	if not _can_be_member(npc):
		return {"p": 0.0, "kind": ""}
	var pers: float = persuasion(vm, npc)
	if pers < PERSUADE_MIN:
		return {"p": 0.0, "kind": ""}
	var skill: float = clampf(0.5 + (pers - PERSUADE_MIN), 0.5, 1.5)
	var mot: float = motive(vm, npc)
	var p_d: float = FOUND_BASE * clampf((crisis - CRISIS_MIN) / 0.2, 0.0, 1.5) * skill * mot
	var p_r: float = 0.0
	if VillageNeeds.class_of(npc) in ["rico", "acomodado"]:
		p_r = FOUND_BASE * clampf((boredom - BOREDOM_MIN) / 0.2, 0.0, 1.5) * skill * maxf(boredom_of(npc), mot * 0.5)
	return {"p": p_d, "kind": KIND_DESPERATE} if p_d >= p_r else {"p": p_r, "kind": KIND_RICH}

static func try_found(vm) -> bool:
	var crisis: float = town_crisis(vm)
	var boredom: float = town_boredom(vm)
	var best = null
	var best_c: Dictionary = {"p": 0.0, "kind": ""}
	for n in VillageNeeds.living(vm):
		var c: Dictionary = found_chance(vm, n, crisis, boredom)
		if float(c["p"]) > float(best_c["p"]):
			best_c = c
			best = n
	if best == null or randf() >= float(best_c["p"]):
		return false
	return found(vm, best, str(best_c["kind"]))

static func found(vm, founder, kind: String = KIND_DESPERATE) -> bool:
	if founder == null:
		return false
	var st: Dictionary = state(vm)
	st["kind"] = kind
	st["founder"] = founder.get_person_key()
	st["founder_name"] = founder.npc_name
	st["members"] = {founder.get_person_key(): VillageNeeds.today()}
	st["founded_on"] = VillageNeeds.today()
	st["foundings"] = int(st["foundings"]) + 1
	st["suspicion"] = 0
	st["gold"] = 0
	st["plan_victim"] = ""
	st["plan_tries"] = 0
	# El líder elige su día de reunión (nunca el domingo del Oficio)
	st["meet_day"] = abs(founder.get_person_key().hash()) % 6
	founder.add_thought("He encontrado la verdad que los demás no ven (+6)", 6.0)
	VillageChronicle.add(vm, "sect_found", "%s fundó en secreto %s (%s)" % [founder.npc_name, sect_name(vm),
		"en tiempos difíciles" if kind == KIND_DESPERATE else "entre la gente acomodada y aburrida"], false)
	_update_band(vm)
	return true

# ---------------------------------------------------------------- O2 captación

## Lo que empuja a alguien a escuchar al que capta: su mal momento (o su aburrimiento, en el círculo de ricos).
static func need_of(vm, npc) -> float:
	if kind_of(vm) == KIND_RICH:
		return boredom_of(npc) + (0.15 if _has(npc, "Místico") else 0.0)
	return crisis_of(vm, npc) + (0.2 if (_has(npc, "Místico") or _has(npc, "Supersticioso")) else 0.0)

static func resistance(npc) -> float:
	var r: float = 0.0
	match VillageFaith.grade_of(npc):
		VillageFaith.GRADE_FERVENT: r += 0.6
		VillageFaith.GRADE_BELIEVER: r += 0.25
	if _has(npc, "Íntegro"):
		r += 0.5
	r += 0.15 * TraitCatalog.npc_tendency(npc, "honesty")
	return r

static func recruit_chance(vm, recruiter, target) -> float:
	if not _can_be_member(target) or is_member(vm, target):
		return 0.0
	if kind_of(vm) == KIND_RICH and not (VillageNeeds.class_of(target) in ["rico", "acomodado"]):
		return 0.0 # El círculo solo admite a gente de su posición
	var size: int = (state(vm)["members"] as Dictionary).size()
	var c: float = 0.02 + 0.45 * need_of(vm, target) + 0.3 * maxf(0.0, persuasion(vm, recruiter)) + float(target.get_relationship_with_npc(recruiter.get_person_key())) / 250.0
	c -= resistance(target) + 0.25 * float(size) / float(MAX_MEMBERS) # Cuanto más grande, más cuesta guardar el secreto
	return clampf(c, 0.0, 0.6)

## Un miembro intenta captar a alguien. Devuelve "joined", "refused" o "" si no había a quién.
static func try_recruit(vm, recruiter, target = null, mult: float = 1.0) -> String:
	var st: Dictionary = state(vm)
	if (st["members"] as Dictionary).size() >= MAX_MEMBERS:
		return ""
	if target == null:
		var best_c: float = 0.0
		for n in VillageNeeds.living(vm):
			if n == recruiter or is_member(vm, n) or not _can_be_member(n):
				continue
			if recruiter.get_relationship_with_npc(n.get_person_key()) < RECRUIT_MIN_REL or n.get_relationship_with_npc(recruiter.get_person_key()) < 0:
				continue
			var c: float = recruit_chance(vm, recruiter, n)
			if c > best_c:
				best_c = c
				target = n
	if target == null:
		return ""
	if randf() < recruit_chance(vm, recruiter, target) * mult:
		join(vm, target, recruiter)
		return "joined"
	st["refusals"] = int(st["refusals"]) + 1
	target.modify_npc_relationship(recruiter, REFUSAL_REL, "Quiso meterme en algo raro", true)
	# Quien se escandaliza (creyente u honrado) lo va contando
	if VillageFaith.is_believer(target) or TraitCatalog.npc_tendency(target, "honesty") >= 0.3:
		var ev: Dictionary = vm.record_social_event("sect_rumor", recruiter, target, "%s intentó meter a %s en una secta secreta que se reúne de noche" % [recruiter.npc_name, target.npc_name])
		ev["quiet"] = [recruiter.get_person_key()]
		_add_suspicion(vm, SUSPICION_REFUSAL)
	return "refused"

static func join(vm, npc, recruiter = null) -> void:
	var st: Dictionary = state(vm)
	st["members"][npc.get_person_key()] = VillageNeeds.today()
	st["recruits"] = int(st["recruits"]) + 1
	npc.add_thought("Ahora soy de %s (+5)" % sect_name(vm), 5.0)
	if recruiter != null:
		npc.modify_npc_relationship(recruiter, 10, "Me abrió los ojos")
		recruiter.modify_npc_relationship(npc, 6, "Se ha unido a nosotros")
	VillageChronicle.add(vm, "sect_join", "%s se unió en secreto a %s%s" % [npc.npc_name, sect_name(vm), (" (le convenció %s)" % recruiter.npc_name) if recruiter != null else ""], false)
	_update_band(vm)

static func leave(vm, npc, why: String) -> void:
	var st: Dictionary = state(vm)
	(st["members"] as Dictionary).erase(npc.get_person_key())
	st["leavers"] = int(st["leavers"]) + 1
	VillageChronicle.add(vm, "sect_join", "%s dejó %s (%s)" % [npc.npc_name, sect_name(vm), why], false)
	_update_band(vm)

## La secta es un bando oculto: sus miembros se encubren y se defienden (G4) y se votan entre ellos (I2).
static func _update_band(vm) -> void:
	if not ("faith_bands" in vm):
		return
	var keep: Array = []
	for b in vm.faith_bands:
		if str(b.get("kind", "")) != "sect":
			keep.append(b)
	var keys: Array = []
	for n in member_nodes(vm):
		keys.append(n.get_person_key())
	if keys.size() >= 2:
		keep.append({"id": "sect", "kind": "sect", "name": sect_name_cap(vm), "members": keys, "leader": str(state(vm)["founder"]), "hidden": true})
	vm.faith_bands = keep

# ---------------------------------------------------------------- relojes

static func daily(vm) -> void:
	var st: Dictionary = state(vm)
	var t: int = VillageNeeds.today()
	st["suspicion"] = maxi(0, int(st["suspicion"]) - SUSPICION_DECAY)
	_track_crisis_events(vm)
	var cr: float = town_crisis(vm)
	var bo: float = town_boredom(vm)
	st["crisis_now"] = snappedf(cr, 0.01)
	st["max_crisis"] = maxf(float(st.get("max_crisis", 0.0)), snappedf(cr, 0.01))
	st["max_boredom"] = maxf(float(st.get("max_boredom", 0.0)), snappedf(bo, 0.01))
	if not active(vm):
		try_found(vm)
		return
	# Muertos y fundador
	for k in (st["members"] as Dictionary).keys():
		var n = vm._get_npcs_by_person_key().get(k, null)
		if n == null or not is_instance_valid(n) or n.is_dead:
			(st["members"] as Dictionary).erase(k)
	if founder_of(vm) == null:
		var heir = null
		var best_s: float = PERSUADE_MIN * 0.5
		for m in member_nodes(vm):
			var s: float = persuasion(vm, m)
			if s > best_s:
				best_s = s
				heir = m
		if heir == null:
			dissolve(vm, "se quedaron sin nadie capaz de guiarlos")
			return
		st["founder"] = heir.get_person_key()
		st["founder_name"] = heir.npc_name
		VillageChronicle.add(vm, "sect_found", "%s toma el mando de %s" % [heir.npc_name, sect_name(vm)], false)
	# Declive lento: quien ya no lo pasa mal (o ya no se aburre) puede irse; los veteranos casi nunca
	var f = founder_of(vm)
	for m in member_nodes(vm):
		if m == f or need_of(vm, m) >= LEAVE_NEED:
			continue
		var loyal: float = clampf(float(t - int(st["members"].get(m.get_person_key(), t))) / LOYAL_DAYS, 0.0, 0.9)
		if randf() < LEAVE_CHANCE * (1.0 - loyal):
			leave(vm, m, "las cosas le van mejor y ya no lo necesita")
	if member_nodes(vm).size() <= 1 and need_of(vm, f) < LEAVE_NEED and randf() < GIVE_UP_CHANCE:
		dissolve(vm, "%s se cansó de predicar sin que nadie le siguiera" % f.npc_name)
		return
	# Captación lenta: como mucho un intento al día, más probable cuantos más son
	var mems: Array = member_nodes(vm)
	if not mems.is_empty() and randf() < RECRUIT_TRY_BASE + RECRUIT_TRY_PER_MEMBER * float(mems.size()):
		try_recruit(vm, mems[randi() % mems.size()])
	# El sol negro se borra a los pocos días
	if int(st.get("profane_day", -99)) + PROFANE_SHOW_DAYS <= t:
		_set_sign_visible(vm, false)
	# Señales del rito de sangre en preparación
	if str(st["plan_victim"]) != "" and randf() < RITE_LEAK_CHANCE:
		_leak_plan(vm)
	_update_band(vm)
	check_player_invite(vm)
	if int(st["suspicion"]) >= SUSPICION_MAX:
		var priest = VillageFaith.priest_of(vm)
		if priest != null and not is_member(vm, priest):
			expose(vm, "el sacerdote %s los señaló delante de todo el pueblo" % priest.npc_name)

## Horario de la reunión según la clase: los desesperados, de madrugada; los ricos, al caer la noche.
static func meeting_hours(vm) -> Dictionary:
	if kind_of(vm) == KIND_RICH:
		return {"call": [20, 21], "end": 23}
	return {"call": [0, 1], "end": 3}

static func meeting_place_name(vm) -> String:
	return ("en casa de %s" % state(vm)["founder_name"]) if kind_of(vm) == KIND_RICH else "en el cementerio"

static func on_hour(vm, hour: int) -> void:
	if not active(vm) or WorldClock == null or not WorldClock.has_method("get_weekday") or int(WorldClock.get_weekday()) != int(state(vm).get("meet_day", 4)):
		return
	var h: Dictionary = meeting_hours(vm)
	if hour in (h["call"] as Array):
		call_meeting(vm)
	elif hour == int(h["end"]):
		finish_meeting(vm)

static func meeting_base(vm) -> Vector2:
	var f = founder_of(vm)
	if kind_of(vm) == KIND_RICH and f != null and f.bed_position != Vector2.ZERO:
		return f.bed_position
	return vm._cemetery_burial_pos

static func meeting_spot(vm, i: int) -> Vector2:
	var base: Vector2 = meeting_base(vm)
	return base + Vector2(cos(float(i) * 1.3) * 22.0, sin(float(i) * 1.3) * 14.0)

static func _can_attend(npc) -> bool:
	if npc.is_dead or npc.is_downed or npc.is_hostile or not npc.is_conscious() or npc.sick_level >= 2:
		return false
	if npc.is_in_live_fight() or npc.is_busy_with_player() or npc.rite_pos != Vector2.ZERO:
		return false
	return npc.need_energy > 15.0 and npc.need_hunger > 30.0

static func call_meeting(vm) -> int:
	var st: Dictionary = state(vm)
	var called: int = 0
	var i: int = 0
	for m in member_nodes(vm):
		if m.rite_kind == "sect":
			i += 1
			continue
		if not _can_attend(m):
			continue
		var was_in_bed: bool = m.is_sleeping
		m.join_rite(meeting_spot(vm, i), "sect")
		i += 1
		called += 1
		if was_in_bed or kind_of(vm) == KIND_RICH:
			_night_witness(vm, m)
	# La víctima elegida, engañada para acudir
	var victim = vm._get_npcs_by_person_key().get(str(st["plan_victim"]), null)
	if victim != null and not victim.is_dead and victim.rite_kind == "" and _can_attend(victim) and not bool(st.get("plan_warned", false)):
		victim.join_rite(meeting_spot(vm, 9), "sect_lure")
	if player_member(vm) and called > 0:
		var pl = VillageNeeds.player_of(vm)
		if pl != null and pl.has_method("show_hint") and int(WorldClock.current_hour) == int(meeting_hours(vm)["call"][0]):
			pl.show_hint("🌑 Esta noche se reúnen %s %s." % [sect_name(vm), meeting_place_name(vm)])
	return called

## Alguien de su casa le oye salir a medianoche (o, en el círculo de ricos, un vecino ve las visitas nocturnas).
static func _night_witness(vm, m) -> void:
	var rich: bool = kind_of(vm) == KIND_RICH
	if randf() >= NIGHT_WITNESS_CHANCE * (0.5 if rich else 1.0):
		return
	var w = null
	for o in VillageNeeds.living(vm):
		if o == m or is_member(vm, o):
			continue
		if rich or (str(o.family_id) == str(m.family_id) and str(m.family_id) not in ["", "none"]):
			w = o
			break
	if w == null:
		return
	var day_txt: String = WEEKDAY_NAMES[int(state(vm).get("meet_day", 4)) % 7]
	var summary: String = ("%s va de noche a casa de %s %s, con otra gente bien, y cierran las contraventanas" % [m.npc_name, state(vm)["founder_name"], day_txt]) if rich else ("%s sale de casa a medianoche %s y no dice adónde va" % [m.npc_name, day_txt])
	var ev: Dictionary = vm.record_social_event("sect_night", m, null, summary)
	ev["known_by"][w.get_person_key()] = true
	ev["quiet"] = [m.get_person_key()]
	_add_suspicion(vm, SUSPICION_NIGHT)

static func finish_meeting(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	var att: Array = []
	var lured = null
	for n in VillageNeeds.living(vm):
		if n.rite_kind == "sect" and n.global_position.distance_to(n.rite_pos) <= MEETING_RADIUS:
			att.append(n)
		if n.rite_kind == "sect_lure" and n.global_position.distance_to(n.rite_pos) <= MEETING_RADIUS:
			lured = n
		if n.rite_kind in ["sect", "sect_lure"]:
			n.leave_rite()
	var res: Dictionary = {"attendees": att.size(), "profaned": false, "rite": "", "player": false}
	var today: int = VillageNeeds.today()
	if int(st.get("last_meeting_day", -1)) == today:
		return res
	st["last_meeting_day"] = today
	st["meetings"] = int(st["meetings"]) + 1
	# Lazos, diezmo y manía al sacerdote
	var priest = VillageFaith.priest_of(vm)
	for i in range(att.size()):
		for j in range(i + 1, att.size()):
			att[i].modify_npc_relationship(att[j], MEETING_BOND, "Compartimos el secreto de la Noche")
			att[j].modify_npc_relationship(att[i], MEETING_BOND, "Compartimos el secreto de la Noche")
		if priest != null and not is_member(vm, priest):
			att[i].modify_npc_relationship(priest, MEETING_PRIEST_REL, "Predica la mentira del Alba", true)
		var tithe: int = mini(int(TITHE_MAX.get(kind_of(vm), 3)), int(att[i].personal_gold / 10))
		if tithe > 0:
			att[i].personal_gold -= tithe
			st["gold"] = int(st["gold"]) + tithe
	for m in att:
		if kind_of(vm) == KIND_DESPERATE and VillageNeeds.class_of(m) in ["pobre", "mendigo"] and int(st["gold"]) >= POOR_HELP:
			st["gold"] = int(st["gold"]) - POOR_HELP
			m.personal_gold += POOR_HELP
			m.add_thought("La Noche cuida de los suyos (+4)", 4.0)
	# El jugador
	var pl = VillageNeeds.player_of(vm)
	var here: bool = pl is Node2D and (pl as Node2D).global_position.distance_to(meeting_base(vm)) <= PLAYER_SPOT_RADIUS
	res["player"] = here
	if here and not att.is_empty():
		if player_member(vm):
			st["player_meetings"] = int(st["player_meetings"]) + 1
			st["player_misses"] = 0
			for m in att:
				m.modify_affinity(3)
			VillageFaith.add_rep(vm, "sect", 5)
			if player_rank(vm) >= 1 and int(st["gold"]) >= PLAYER_RANK_PAY and pl.get("inventory") != null:
				st["gold"] = int(st["gold"]) - PLAYER_RANK_PAY
				pl.inventory.add_gold(PLAYER_RANK_PAY)
		else:
			st["player_knows"] = true
			var names: Array[String] = []
			for m in att:
				st["known"][m.get_person_key()] = true
				names.append(m.npc_name)
				m.modify_affinity(-6)
			if pl.has_method("show_hint"):
				pl.show_hint("👀 Has visto una reunión secreta %s: %s." % [meeting_place_name(vm), ", ".join(names)])
	elif player_member(vm) and not att.is_empty():
		st["player_misses"] = int(st["player_misses"]) + 1
		if int(st["player_misses"]) >= PLAYER_MISS_LIMIT:
			st["player_misses"] = 0
			for m in member_nodes(vm):
				m.modify_affinity(-5)
			if pl != null and pl.has_method("show_hint"):
				pl.show_hint("🌑 %s empiezan a desconfiar de ti: faltas a las reuniones." % sect_name_cap(vm))
	# El rito de sangre, si estaba preparado y la víctima acudió
	if lured != null and str(st["plan_victim"]) == lured.get_person_key() and att.size() >= 2:
		res["rite"] = blood_rite(vm, lured, att)
	elif str(st["plan_victim"]) != "":
		st["plan_tries"] = int(st.get("plan_tries", 0)) + 1
		if int(st["plan_tries"]) >= RITE_MAX_TRIES:
			_drop_plan(vm, "la víctima nunca acudió")
	else:
		_maybe_plan_rite(vm)
	# Profanación de la capilla
	if att.size() >= PROFANE_MIN_MEMBERS and randf() < float(PROFANE_CHANCE.get(kind_of(vm), 0.3)):
		profane(vm)
		res["profaned"] = true
	VillageChronicle.add(vm, "sect_meeting", "%s se reunieron en secreto %s (%d)" % [sect_name_cap(vm), meeting_place_name(vm), att.size()], here)
	return res

# ---------------------------------------------------------------- O4 lo que hace

static func profane(vm) -> void:
	var st: Dictionary = state(vm)
	st["profanations"] = int(st["profanations"]) + 1
	st["profane_day"] = VillageNeeds.today()
	_set_sign_visible(vm, true)
	var priest = VillageFaith.priest_of(vm)
	if priest != null:
		priest.add_thought("Han profanado la capilla (-10)", -10.0)
	for n in VillageNeeds.living(vm):
		if VillageFaith.is_believer(n) and not is_member(vm, n):
			n.add_thought("Han pintado un %s en la capilla (-4)" % SECT_SIGN, -4.0)
	_add_suspicion(vm, SUSPICION_PROFANE)
	VillageChronicle.add(vm, "sect_profane", "Amaneció un %s pintado en la puerta de la capilla" % SECT_SIGN, true)

static func _set_sign_visible(vm, on: bool) -> void:
	if not vm.is_inside_tree():
		return
	var lbl = vm.get_node_or_null("SectSign")
	if on and lbl == null:
		lbl = Label.new()
		lbl.name = "SectSign"
		lbl.text = "🌑 %s pintado" % SECT_SIGN
		lbl.add_theme_font_size_override("font_size", 7)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.2, 0.25))
		lbl.position = vm._church_center + Vector2(-24, 30)
		lbl.z_index = 50
		vm.add_child(lbl)
	elif not on and lbl != null:
		lbl.queue_free()

static func _maybe_plan_rite(vm) -> void:
	var st: Dictionary = state(vm)
	var f = founder_of(vm)
	if f == null or member_nodes(vm).size() < RITE_MIN_MEMBERS or VillageNeeds.today() - int(st.get("founded_on", 0)) < RITE_MIN_AGE_DAYS:
		return
	if darkness(f) < RITE_DARKNESS and not _has(f, "Cruel") and not _has(f, "Fanático"):
		return
	if VillageNeeds.today() - int(vm.last_npc_murder_day) < RITE_GLOBAL_GAP or randf() >= RITE_PLAN_CHANCE:
		return
	var victim = null
	var worst: float = INF
	for n in VillageNeeds.living(vm):
		if is_member(vm, n) or _protected_role(n) or int(n.trade_role) == int(VillageNPC.TradeRole.DOCTOR):
			continue
		var s: float = float(f.get_relationship_with_npc(n.get_person_key())) - (30.0 if VillageNeeds.class_of(n) == "mendigo" else 0.0)
		if s < worst:
			worst = s
			victim = n
	if victim == null:
		return
	start_plan(vm, victim)

static func start_plan(vm, victim) -> void:
	var st: Dictionary = state(vm)
	st["plan_victim"] = victim.get_person_key()
	st["plan_victim_name"] = victim.npc_name
	st["plan_tries"] = 0
	st["plan_warned"] = false
	VillageChronicle.add(vm, "sect_plan", "%s preparan un rito de sangre: la víctima será %s" % [sect_name_cap(vm), victim.npc_name], player_member(vm))
	if player_member(vm):
		st["player_knows_plan"] = true
		var pl = VillageNeeds.player_of(vm)
		if pl != null and pl.has_method("show_hint"):
			pl.show_hint("🩸 En la reunión se habló de un sacrificio. La víctima: %s, el próximo viernes." % victim.npc_name)

## Un miembro con reparos murmura lo que se prepara.
static func _leak_plan(vm) -> void:
	var st: Dictionary = state(vm)
	var soft = null
	var least: float = INF
	for m in member_nodes(vm):
		if m.get_person_key() == str(st["founder"]):
			continue
		if darkness(m) < least:
			least = darkness(m)
			soft = m
	if soft == null:
		return
	var ev: Dictionary = vm.record_social_event("sect_rumor", soft, null, "%s murmura, asustado, que los de la secta preparan un sacrificio contra %s" % [soft.npc_name, st["plan_victim_name"]])
	ev["quiet"] = []
	_add_suspicion(vm, SUSPICION_LEAK)

static func _drop_plan(vm, why: String) -> void:
	var st: Dictionary = state(vm)
	if str(st["plan_victim"]) == "":
		return
	VillageChronicle.add(vm, "sect_plan", "%s renuncian al rito contra %s (%s)" % [sect_name_cap(vm), st["plan_victim_name"], why], player_member(vm) or bool(st.get("player_knows_plan", false)))
	st["plan_victim"] = ""
	st["plan_victim_name"] = ""
	st["plan_tries"] = 0
	st["plan_warned"] = false
	st["player_knows_plan"] = false

static func blood_rite(vm, victim, att: Array) -> String:
	var st: Dictionary = state(vm)
	var f = founder_of(vm)
	var killer_name: String = f.npc_name if f != null else str(att[0].npc_name)
	var vname: String = victim.npc_name
	vm.npc_murders[vname] = killer_name
	vm.last_npc_murder_day = VillageNeeds.today()
	st["rites"] = int(st["rites"]) + 1
	_drop_plan(vm, "consumado")
	VillageChronicle.add(vm, "sect_rite", "%s sacrificaron a %s %s" % [sect_name_cap(vm), vname, meeting_place_name(vm)], player_member(vm))
	_add_suspicion(vm, SUSPICION_RITE)
	victim.last_hit_by_player = false
	victim.last_hit_weapon_name = "Daga ceremonial (rito de sangre)"
	victim._confirm_true_death()
	victim.murder_witness_name = ""
	return vname

# ---------------------------------------------------------------- O5 destaparla

static func _add_suspicion(vm, amount: int) -> void:
	var st: Dictionary = state(vm)
	st["suspicion"] = mini(SUSPICION_MAX, int(st["suspicion"]) + amount)

static func expose(vm, how: String) -> void:
	var st: Dictionary = state(vm)
	if not active(vm):
		return
	var members: Array = member_nodes(vm)
	var names: Array[String] = []
	for m in members:
		names.append(m.npc_name)
		m.add_thought("Todo el pueblo sabe que era de la secta (-12)", -12.0)
		for n in VillageNeeds.living(vm):
			if n != m and not is_member(vm, n) and not VillageNeeds.is_outsider(n):
				n.modify_npc_relationship(m, EXPOSE_REL, "Era de %s" % sect_name(vm), true)
	var f = founder_of(vm)
	var to_town: int = int(st["gold"])
	if f != null:
		var fine: int = mini(EXPOSE_FINE, maxi(0, f.personal_gold))
		f.personal_gold -= fine
		to_town += fine
	if "town_state" in vm and vm.town_state is Dictionary:
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + to_town
	if player_member(vm):
		VillageFaith.add_rep(vm, "faith", -20)
	st["exposed"] = int(st["exposed"]) + 1
	st["discredited"][str(st["founder"])] = true # Nadie vuelve a creer al fundador destapado
	VillageChronicle.add(vm, "sect_exposed", "Se destapó %s (%s): %s. El fundador, %s, pagó una multa y la secta se disolvió" % [sect_name(vm), how, ", ".join(names), st["founder_name"]], true)
	dissolve(vm, "destapada")

static func dissolve(vm, why: String) -> void:
	var st: Dictionary = state(vm)
	for n in VillageNeeds.living(vm):
		if n.rite_kind in ["sect", "sect_lure"]:
			n.leave_rite()
	if why != "destapada":
		VillageChronicle.add(vm, "sect_exposed", "%s se deshicieron (%s)" % [sect_name_cap(vm), why], false)
	st["founder"] = ""
	st["founder_name"] = ""
	st["members"] = {}
	st["known"] = {}
	st["gold"] = 0
	st["player_member"] = false
	st["invite_by"] = ""
	st["plan_victim"] = ""
	st["plan_victim_name"] = ""
	st["player_knows_plan"] = false
	_set_sign_visible(vm, false)
	_update_band(vm)

# ---------------------------------------------------------------- O6 el jugador

static func player_rank(vm) -> int:
	var n: int = int(state(vm)["player_meetings"])
	var r: int = 0
	for i in range(RANK_MEETINGS.size()):
		if n >= RANK_MEETINGS[i]:
			r = i
	return r

static func on_player_news(vm, npc) -> void:
	var key: String = npc.get_person_key()
	for ev in vm.social_event_log:
		if not (str(ev.get("type", "")) in ["sect_rumor", "sect_night"]) or not (ev.get("known_by", {}) as Dictionary).has(key):
			continue
		var st: Dictionary = state(vm)
		st["player_knows"] = true
		var actor = vm._get_npcs_by_person_key().get(str(ev.get("actor_id", "")), null)
		if actor != null and is_member(vm, actor):
			st["known"][actor.get_person_key()] = true
		if "sacrificio" in str(ev.get("summary", "")) and str(st["plan_victim"]) != "":
			st["player_knows_plan"] = true

static func _known_names(vm) -> Array[String]:
	var out: Array[String] = []
	for m in member_nodes(vm):
		if known_member(vm, m):
			out.append(m.npc_name)
	return out

static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null or not ("sect_state" in vm) or not active(vm):
		return
	var st: Dictionary = state(vm)
	var back: Dictionary = {"label": "⬅️ Volver a la conversación", "next": "start"}
	var law: bool = int(npc.trade_role) == int(VillageNPC.TradeRole.SHERIFF) or VillageFaith.is_priest(npc)
	var knowns: Array[String] = _known_names(vm)
	# Denunciar ante el comisario o el sacerdote
	if law and not is_member(vm, npc) and player_knows_sect(vm) and (knowns.size() >= 2 or known_member(vm, founder_of(vm))):
		ch_arr.insert(0, {"label": "🌑 Denunciar a %s (%s)" % [sect_name(vm), ", ".join(knowns)], "next": "END", "action": "sect_report"})
	# Avisar a la víctima
	if bool(st.get("player_knows_plan", false)) and str(st["plan_victim"]) == npc.get_person_key():
		ch_arr.insert(0, {"label": "⚠️ Avisarle de que la secta va a por %s" % npc.npc_name, "next": "END", "action": "sect_warn"})
	# Invitación a entrar
	if not player_member(vm) and is_member(vm, npc):
		if str(st["invite_by"]) == npc.get_person_key() or (known_member(vm, npc) and npc.affinity >= PLAYER_ASK_AFF):
			diag["sect_invite"] = {"text": str(LORE.get(kind_of(vm), LORE[KIND_DESPERATE])), "choices": [
				{"label": "🌑 Unirte a %s" % sect_name(vm), "next": "END", "action": "sect_join"},
				{"label": "🙅 Decir que no quieres saber nada", "next": "END", "action": "sect_refuse"}, back]}
			var lbl: String = "🌑 «Quiero enseñarte algo... si sabes guardar un secreto»" if str(st["invite_by"]) == npc.get_person_key() else "🌑 Pedirle entrar en %s" % sect_name(vm)
			ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": lbl, "next": "sect_invite"})
		elif known_member(vm, npc):
			diag["sect_know"] = {"text": "«...¿Quién te ha contado eso? Baja la voz.»", "choices": [
				{"label": "💰 Pedirle %d de oro por tu silencio" % BLACKMAIL_GOLD, "next": "END", "action": "sect_blackmail"},
				{"label": "🗣️ Que te diga quién más está", "next": "END", "action": "sect_who"}, back]}
			ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🤫 Decirle que sabes que es de %s" % sect_name(vm), "next": "sect_know"})
	# Ya eres de la secta: hablar con los tuyos
	if player_member(vm) and is_member(vm, npc):
		var txt: String = "«Hermano. Eres %s. Nos vemos %s %s.»" % [RANK_NAMES[player_rank(vm)], WEEKDAY_NAMES[int(st.get("meet_day", 4)) % 7], meeting_place_name(vm)]
		if str(st["plan_victim"]) != "":
			txt += "\n«La Noche pide sangre: %s.»" % st["plan_victim_name"]
		diag["sect_talk"] = {"text": txt, "choices": [{"label": "🚪 Dejar la secta", "next": "END", "action": "sect_quit"}, back]}
		ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🌑 Hablar de la Noche", "next": "sect_talk"})

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	var st: Dictionary = state(vm)
	var pl = VillageNeeds.player_of(vm)
	match action_id:
		"sect_report":
			if int(npc.trade_role) == int(VillageNPC.TradeRole.SHERIFF) and _sheriff_bought(vm, npc):
				npc._spawn_floating_text("🤨 «Cuentos de viejas. Vete a dormir.»", Color.ORANGE, -46.0)
				return
			VillageFaith.add_rep(vm, "faith", 6)
			VillageFaith.add_rep(vm, "law", 4)
			npc._spawn_floating_text("😨 «¿Aquí, en nuestro pueblo? Esto se acaba hoy.»", Color(0.7, 0.85, 1.0), -46.0)
			expose(vm, "lo denunciaste tú ante %s" % npc.npc_name)
		"sect_warn":
			st["plan_warned"] = true
			npc.modify_affinity(15)
			npc._spawn_floating_text("😨 «¿A mí? No saldré de casa de noche. Gracias.»", Color(1.0, 0.85, 0.6), -46.0)
			_add_suspicion(vm, SUSPICION_LEAK)
			_drop_plan(vm, "avisaste a %s" % npc.npc_name)
		"sect_join":
			st["player_member"] = true
			st["player_knows"] = true
			st["invite_by"] = ""
			st["player_meetings"] = 0
			npc.modify_affinity(8)
			npc._spawn_floating_text("🌑 «Bienvenido. Nos vemos %s %s.»" % [WEEKDAY_NAMES[int(st.get("meet_day", 4)) % 7], meeting_place_name(vm)], Color(0.75, 0.6, 1.0), -46.0)
			VillageChronicle.add(vm, "sect_player", "Te uniste en secreto a %s" % sect_name(vm), true)
		"sect_refuse":
			st["invite_by"] = ""
			st["player_knows"] = true
			st["known"][npc.get_person_key()] = true
			npc.modify_affinity(-5)
			npc._spawn_floating_text("😶 «Olvida lo que te he dicho.»", Color(0.8, 0.8, 0.8), -46.0)
		"sect_quit":
			st["player_member"] = false
			for m in member_nodes(vm):
				m.modify_affinity(-20)
				st["known"][m.get_person_key()] = true
			npc._spawn_floating_text("😠 «Nadie deja la Noche así como así.»", Color.ORANGE_RED, -46.0)
			VillageChronicle.add(vm, "sect_player", "Dejaste %s" % sect_name(vm), true)
		"sect_blackmail":
			if npc.personal_gold >= BLACKMAIL_GOLD and npc.affinity > -40:
				npc.personal_gold -= BLACKMAIL_GOLD
				if inv != null:
					inv.add_gold(BLACKMAIL_GOLD)
				npc.modify_affinity(-15)
				npc._spawn_floating_text("😒 «Toma. Y ni una palabra.»", Color.ORANGE, -46.0)
			else:
				npc.modify_affinity(-10)
				npc._spawn_floating_text("😠 «No tengo nada para ti. Cuidado con lo que dices.»", Color.ORANGE, -46.0)
		"sect_who":
			var other = null
			for m in member_nodes(vm):
				if m != npc and not known_member(vm, m):
					other = m
					break
			if other != null and npc.affinity >= 0:
				st["known"][other.get_person_key()] = true
				npc.modify_affinity(-8)
				npc._spawn_floating_text("😰 «...%s también viene. No le digas que te lo dije.»" % other.npc_name, Color(1.0, 0.85, 0.6), -46.0)
			else:
				npc._spawn_floating_text("🤐 «No sé de qué hablas.»", Color(0.8, 0.8, 0.8), -46.0)
	if pl != null and pl.has_method("show_hint") and action_id in ["sect_report", "sect_join"]:
		pl.show_hint("🌑 %s" % ("Has denunciado a la secta." if action_id == "sect_report" else "Ahora eres de %s." % sect_name(vm)))

## Con el oro de la secta compran al comisario corrupto para que no investigue.
static func _sheriff_bought(vm, sheriff) -> bool:
	if is_member(vm, sheriff):
		return true
	var st: Dictionary = state(vm)
	var town = load("res://scripts/systems/VillageTown.gd")
	if not town.is_corrupt(sheriff) or int(st["gold"]) < 20:
		return false
	st["gold"] = int(st["gold"]) - 20
	sheriff.personal_gold += 20
	return true

## Invitación al jugador: un miembro que le aprecia mucho se lo propone (se revisa cada día).
static func check_player_invite(vm) -> void:
	var st: Dictionary = state(vm)
	if player_member(vm) or str(st["invite_by"]) != "" or not active(vm) or VillageFaith.rep_of(vm, "faith") > 10:
		return
	for m in member_nodes(vm):
		if m.affinity >= PLAYER_JOIN_AFF:
			st["invite_by"] = m.get_person_key()
			return

static func glossary_line(vm, npc) -> String:
	if not active(vm) or not player_knows_sect(vm):
		return ""
	var txt: String = "[color=#b48cff][b]🌑 %s:[/b][/color] " % sect_name_cap(vm)
	if known_member(vm, npc):
		txt += "es miembro" + (" (fundador)" if npc.get_person_key() == str(state(vm)["founder"]) else "")
	else:
		txt += "no sabes si es de ellos"
	if player_member(vm):
		txt += "   Tú: %s" % RANK_NAMES[player_rank(vm)]
	return txt
