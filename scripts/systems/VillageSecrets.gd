@tool
extends RefCounted

## Secretos: infidelidad y chantaje (bloques S, `docs/PLAN_SECRETOS.md`). Raro y orgánico; solo adultos; fuera de cámara.
## Vive en `VillageManager.secrets` (se guarda con la partida). Cada secreto:
##   {id, type:"affair", a (infiel), b (amante), partner, a_name, b_name, p_name, day, active, known_by{},
##    gossip_uid, blackmailed_by{}, player_knows, player_lover (a quién cree el jugador que es el amante),
##    player_deal ("" / "silence" / "blackmail"), player_told}

const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const GossipMemory = preload("res://scripts/systems/GossipMemory.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")

# --- Diales (ajustar con la sonda) ---
const MIN_AGE: int = 18
const AFFAIR_SPARK_SELF: int = 35 # Chispa del infiel hacia el amante
const AFFAIR_SPARK_OTHER: int = 20 # Chispa del amante hacia el infiel
const AFFAIR_CONTACT_DAYS: int = 3
const AFFAIR_DAILY: float = 0.12 # Por la «tentación» (0 Fiel … 0.55 Infiel)
const AFFAIR_END_SPARK: int = 15
const AFFAIR_COOLDOWN_DAYS: int = 30
const MEET_BIAS: float = 0.5 # Al quedar, el infiel elige al amante con esta probabilidad
const WITNESS_RADIUS: float = 170.0
const WITNESS_CHANCE: float = 0.5
const HEARD_REL_CHEATER: int = -4
const HEARD_REL_LOVER: int = -2
const PARTNER_REL_CHEATER: int = -30
const PARTNER_REL_LOVER: int = -20
const PARTNER_TENSION: int = 40
const PARTNER_BREAKUP_CHANCE: float = 0.7
const BLACKMAIL_MIN_MALICE: float = 0.5
const BLACKMAIL_DAILY: float = 0.15
const BLACKMAIL_MAX_GOLD: int = 30
const BLACKMAIL_PAY_CHANCE: float = 0.6
const PLAYER_BLACKMAIL_PAY_CHANCE: float = 0.65

static func temptation(npc: VillageNPC) -> float:
	return clampf(0.25 - 0.25 * TraitCatalog.npc_tendency(npc, "fidelity"), 0.0, 0.55)

static func _adult(n: VillageNPC) -> bool:
	return n != null and n.person_profile != null and int(n.person_profile.age) >= MIN_AGE

static func _same_family(a: VillageNPC, b: VillageNPC) -> bool:
	return a.family_id != "none" and a.family_id != "" and a.family_id != "family_police" and a.family_id == b.family_id

static func active_affair_of(vm: VillageManager, key: String) -> Dictionary:
	for s in vm.secrets:
		if bool(s.get("active", false)) and str(s.get("type", "")) == "affair" and str(s.get("a", "")) == key:
			return s
	return {}

static func affair_between(vm: VillageManager, k1: String, k2: String) -> Dictionary:
	for s in vm.secrets:
		if bool(s.get("active", false)) and str(s.get("type", "")) == "affair":
			if (str(s["a"]) == k1 and str(s["b"]) == k2) or (str(s["a"]) == k2 and str(s["b"]) == k1):
				return s
	return {}

static func _last_affair_end(vm: VillageManager, key: String) -> int:
	var d: int = -9999
	for s in vm.secrets:
		if str(s.get("a", "")) == key and not bool(s.get("active", false)):
			d = maxi(d, int(s.get("end_day", -9999)))
	return d

static func _today() -> int:
	return int(WorldClock.current_day) if WorldClock != null else 1

# ==============================================================================
# S1: aventuras (una vez al día)
# ==============================================================================
static func daily(vm: VillageManager) -> void:
	if vm.social_director == null:
		return
	var sd = vm.social_director
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var today: int = _today()
	# Fin de aventuras: ya sin pareja, sin chispa o alguien muerto
	for s in vm.secrets:
		if not bool(s.get("active", false)) or str(s.get("type", "")) != "affair":
			continue
		var a: VillageNPC = by_key.get(str(s["a"]), null)
		var b: VillageNPC = by_key.get(str(s["b"]), null)
		if a == null or b == null or a.is_dead or b.is_dead or a.person_profile == null or str(a.person_profile.partner_id) != str(s["partner"]) \
				or sd.get_spark(str(s["a"]), str(s["b"])) < AFFAIR_END_SPARK:
			_end(s, today)
	# Nuevas aventuras
	for ka in by_key.keys():
		var a2: VillageNPC = by_key[ka]
		if a2.is_dead or not _adult(a2) or str(a2.person_profile.partner_id) == "" or not active_affair_of(vm, str(ka)).is_empty():
			continue
		if today - _last_affair_end(vm, str(ka)) < AFFAIR_COOLDOWN_DAYS:
			continue
		var t: float = temptation(a2)
		if t <= 0.0:
			continue
		var pk: String = str(a2.person_profile.partner_id)
		var best: VillageNPC = null
		var best_spk: int = AFFAIR_SPARK_SELF - 1
		for kb in by_key.keys():
			var c: VillageNPC = by_key[kb]
			if c == a2 or str(kb) == pk or c.is_dead or not _adult(c) or _same_family(a2, c):
				continue
			var s_ac: int = sd.get_spark(str(ka), str(kb))
			if s_ac <= best_spk or sd.get_spark(str(kb), str(ka)) < AFFAIR_SPARK_OTHER:
				continue
			if int(sd.get_pair_entry(str(ka), str(kb)).get("last_contact_day", -999)) < today - AFFAIR_CONTACT_DAYS:
				continue
			best = c
			best_spk = s_ac
		if best != null and sd.rng.randf() < AFFAIR_DAILY * t:
			start_affair(vm, a2, best)
	daily_blackmail(vm)

static func start_affair(vm: VillageManager, a: VillageNPC, b: VillageNPC) -> Dictionary:
	var p: VillageNPC = vm._get_npcs_by_person_key().get(str(a.person_profile.partner_id), null)
	vm.secret_uid += 1
	var s: Dictionary = {"id": vm.secret_uid, "type": "affair", "a": a.get_person_key(), "b": b.get_person_key(),
		"partner": str(a.person_profile.partner_id), "a_name": a.npc_name, "b_name": b.npc_name, "p_name": p.npc_name if p else "su pareja",
		"day": _today(), "active": true, "known_by": {a.get_person_key(): true, b.get_person_key(): true}, "gossip_uid": -1,
		"blackmailed_by": {}, "player_knows": false, "player_lover": "", "player_deal": "", "player_told": false}
	vm.secrets.append(s)
	VillageChronicle.add(vm, "affair_start", "%s empezó a verse a escondidas con %s, a espaldas de %s" % [s["a_name"], s["b_name"], s["p_name"]], false)
	return s

static func _end(s: Dictionary, day: int) -> void:
	s["active"] = false
	s["end_day"] = day

## Al planear una quedada: el infiel, a veces, elige al amante (si está disponible).
static func bias_hangout_candidates(vm: VillageManager, initiator: VillageNPC, cand_ids: Array) -> Array:
	var s: Dictionary = active_affair_of(vm, initiator.get_person_key())
	if s.is_empty() or not (str(s["b"]) in cand_ids) or vm.social_director.rng.randf() >= MEET_BIAS:
		return cand_ids
	return [str(s["b"])]

# ==============================================================================
# S2: descubrirlo en un encuentro
# ==============================================================================
static func on_meeting(vm: VillageManager, a: VillageNPC, b: VillageNPC) -> void:
	var s: Dictionary = affair_between(vm, a.get_person_key(), b.get_person_key())
	if s.is_empty():
		return
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var cheater: VillageNPC = by_key.get(str(s["a"]), a)
	var rng = vm.social_director.rng
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n == a or n == b or not (n is VillageNPC) or n.is_dead or n.is_sleeping:
			continue
		if (n as VillageNPC).global_position.distance_to(cheater.global_position) <= WITNESS_RADIUS and rng.randf() < WITNESS_CHANCE:
			discover(vm, s, n)
	var pl = vm.get_tree().get_first_node_in_group("player")
	if pl != null and (pl as Node2D).global_position.distance_to(cheater.global_position) <= WITNESS_RADIUS:
		player_learns(vm, s, str(s["b_name"]), "los viste")

## `w` los ha pillado. Si es la pareja, reacciona; si no, se convierte en chisme que empieza en `w`.
static func discover(vm: VillageManager, s: Dictionary, w: VillageNPC) -> void:
	var wk: String = w.get_person_key()
	s["known_by"][wk] = true
	if wk == str(s["partner"]):
		partner_reaction(vm, s, w, str(s["a_name"]), str(s["b_name"]), "los pilló juntos")
		return
	var ev: Dictionary = _gossip_event(vm, s)
	if ev.is_empty():
		var by_key: Dictionary = vm._get_npcs_by_person_key()
		ev = vm.record_social_event("affair", by_key.get(str(s["a"]), null), by_key.get(str(s["b"]), null),
			"%s engaña a %s con %s" % [s["a_name"], s["p_name"], s["b_name"]])
		ev["known_by"] = {}
		ev["heard_from"] = {}
		ev["partner_id"] = str(s["partner"])
		ev["secret_id"] = int(s["id"])
		ev["swap_only"] = "target" # Al deformarse, cambia el amante, nunca el infiel
		s["gossip_uid"] = int(ev.get("uid", -1))
	ev["known_by"][wk] = true
	if ev.has("forgot"):
		(ev["forgot"] as Dictionary).erase(wk)
	w._spawn_floating_text("😳 ¡%s y %s...!" % [s["a_name"], s["b_name"]], Color(1.0, 0.75, 0.85), -46.0)

static func _gossip_event(vm: VillageManager, s: Dictionary) -> Dictionary:
	var uid: int = int(s.get("gossip_uid", -1))
	if uid < 0:
		return {}
	for ev in vm._get_live_gossip():
		if int(ev.get("uid", -1)) == uid:
			return ev
	return {}

static func secret_of_event(vm: VillageManager, ev: Dictionary) -> Dictionary:
	var sid: int = int(ev.get("secret_id", -1))
	for s in vm.secrets:
		if int(s.get("id", -2)) == sid:
			return s
	return {}

## Los amantes no van contando lo suyo.
static func keeps_quiet(ev: Dictionary, teller_key: String) -> bool:
	var quiet: bool = teller_key in (ev.get("quiet", []) as Array) # D5: quien planea algo no lo va contando
	if not quiet:
		quiet = str(ev.get("type", "")) == "affair" and (teller_key == str(ev.get("actor_id", "")) or teller_key == str(ev.get("target_id", "")))
	if quiet and VillageNeeds.is_drunk_key(teller_key) and randf() < VillageNeeds.DRUNK_TELL_CHANCE:
		return false # E5: bebido habla de más
	return quiet

# ==============================================================================
# S3: consecuencias al oírlo
# ==============================================================================
## `listener` acaba de oír el chisme (su versión ya está en GossipMemory).
static func on_heard(vm: VillageManager, ev: Dictionary, teller: VillageNPC, listener: VillageNPC) -> void:
	if str(ev.get("type", "")) != "affair":
		return
	var s: Dictionary = secret_of_event(vm, ev)
	if s.is_empty():
		return
	var lk: String = listener.get_person_key()
	s["known_by"][lk] = true
	var lover_name: String = GossipMemory.render(ev, str(s["b_name"]), lk)
	if lk == str(s["partner"]):
		partner_reaction(vm, s, listener, str(s["a_name"]), lover_name, "se lo contó %s" % teller.npc_name)
		return
	var by_name: Dictionary = _npcs_by_name(vm)
	var cheater: VillageNPC = by_name.get(str(s["a_name"]), null)
	var lover: VillageNPC = by_name.get(lover_name, null)
	if cheater != null and cheater != listener:
		listener.modify_npc_relationship(cheater, HEARD_REL_CHEATER, "Dicen que engaña a %s" % s["p_name"], true)
	if lover != null and lover != listener:
		listener.modify_npc_relationship(lover, HEARD_REL_LOVER, "Dicen que se ve a escondidas con %s" % s["a_name"], true) # Puede ser un inocente

static func _npcs_by_name(vm: VillageManager) -> Dictionary:
	var res: Dictionary = {}
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and not n.is_dead:
			res[n.npc_name] = n
	return res

## La pareja engañada se entera (o cree enterarse: `lover_name` puede ser el de un inocente).
static func partner_reaction(vm: VillageManager, s: Dictionary, partner: VillageNPC, cheater_name: String, lover_name: String, how: String) -> void:
	if not bool(s.get("active", false)):
		return
	var by_name: Dictionary = _npcs_by_name(vm)
	var cheater: VillageNPC = by_name.get(cheater_name, null)
	var lover: VillageNPC = by_name.get(lover_name, null)
	s["known_by"][partner.get_person_key()] = true
	_end(s, _today())
	if cheater == null:
		return
	partner.modify_npc_relationship(cheater, PARTNER_REL_CHEATER, "💔 Le engañó con %s" % lover_name, true)
	if lover != null and lover != partner:
		partner.modify_npc_relationship(lover, PARTNER_REL_LOVER, "Se veía a escondidas con %s" % cheater_name, true)
	partner.add_thought("Me enteré de que %s me engaña (-20)" % cheater_name, -20.0)
	_maybe_passion_revenge(vm, partner, cheater, lover)
	var sd = vm.social_director
	var pe: Dictionary = sd.get_pair_entry(partner.get_person_key(), cheater.get_person_key())
	pe["tension"] = clampi(int(pe.get("tension", 0)) + PARTNER_TENSION, 0, 100)
	var p_break: float = clampf(PARTNER_BREAKUP_CHANCE + 0.1 * TraitCatalog.npc_tendency(partner, "grudge"), 0.0, 0.95)
	if sd.rng.randf() < p_break:
		breakup(vm, partner, cheater, "%s dejó a %s al enterarse de que le engañaba con %s" % [partner.npc_name, cheater.npc_name, lover_name])
	else:
		partner._spawn_floating_text("💔 «%s... ¿cómo has podido?»" % cheater.npc_name, Color(1.0, 0.45, 0.50), -46.0)
		vm.record_social_event("affair_forgiven", partner, cheater, "%s descubrió que %s le engañaba (%s), pero siguen juntos" % [partner.npc_name, cheater.npc_name, how])

## V8: el engañado puede jurar venganza «por celos»: contra el amante o, si es muy celoso, contra quien le engañó.
## Es una venganza normal (D2) marcada `passion`, que puede acabar antes en un plan de asesinato (muy raro, con señales).
static func _maybe_passion_revenge(vm: VillageManager, partner: VillageNPC, cheater: VillageNPC, lover: VillageNPC) -> void:
	var desires = load("res://scripts/systems/VillageDesires.gd")
	if not desires.active_of(vm, partner.get_person_key()).is_empty():
		return
	var jealous: bool = partner.person_profile != null and "Celoso" in partner.person_profile.personality
	var ch: float = clampf(0.15 + (0.2 if jealous else 0.0) + 0.15 * TraitCatalog.npc_tendency(partner, "grudge") + 0.1 * TraitCatalog.npc_tendency(partner, "aggression"), 0.0, 0.6)
	if vm.social_director.rng.randf() >= ch:
		return
	var target: VillageNPC = cheater if (jealous or lover == null or lover == partner) else lover
	var d: Dictionary = desires.create(vm, "revenge", partner, target.get_person_key(), target.npc_name, "por celos: la infidelidad de %s" % cheater.npc_name, false)
	d["passion"] = true

static func breakup(vm: VillageManager, p: VillageNPC, c: VillageNPC, summary: String) -> void:
	var sd = vm.social_director
	var pe: Dictionary = sd.get_pair_entry(p.get_person_key(), c.get_person_key())
	pe["stage"] = "none" # SocialDirector.STAGE_NONE
	pe["ex_couple"] = true
	for pair in [[p, c], [c, p]]:
		var x: VillageNPC = pair[0]
		if x.person_profile != null and str(x.person_profile.partner_id) == (pair[1] as VillageNPC).get_person_key():
			x.person_profile.romance_status = "single" # PersonProfile.ROMANCE_SINGLE
			x.person_profile.partner_id = ""
	c.add_thought("%s me dejó (-14)" % p.npc_name, -14.0)
	p._spawn_floating_text("💔 ¡%s ha dejado a %s!" % [p.npc_name, c.npc_name], Color(1.0, 0.38, 0.45), -46.0)
	vm.record_social_event("breakup", p, c, summary)

# ==============================================================================
# S4: chantaje entre vecinos
# ==============================================================================
static func daily_blackmail(vm: VillageManager) -> void:
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var rng = vm.social_director.rng
	for s in vm.secrets.duplicate():
		if not bool(s.get("active", false)):
			continue
		var a: VillageNPC = by_key.get(str(s["a"]), null)
		if a == null:
			continue
		for wk in (s["known_by"] as Dictionary).keys():
			if str(wk) in [str(s["a"]), str(s["b"]), str(s["partner"])] or (s["blackmailed_by"] as Dictionary).has(wk):
				continue
			var w: VillageNPC = by_key.get(str(wk), null)
			if w == null or w.is_dead or TraitCatalog.npc_tendency(w, "malice") < BLACKMAIL_MIN_MALICE or w.get_relationship_with_npc(str(s["a"])) >= 10:
				continue
			if rng.randf() < BLACKMAIL_DAILY:
				blackmail(vm, s, w, a, rng.randf())
				if not bool(s.get("active", false)):
					break

## `roll` < probabilidad de pagar → paga. Si no, `w` se lo cuenta a la pareja.
static func blackmail(vm: VillageManager, s: Dictionary, w: VillageNPC, a: VillageNPC, roll: float) -> void:
	s["blackmailed_by"][w.get_person_key()] = true
	var amount: int = clampi(int(float(maxi(0, a.personal_gold)) / 2.0), 0, BLACKMAIL_MAX_GOLD)
	if amount >= 5 and roll < BLACKMAIL_PAY_CHANCE:
		a.personal_gold -= amount
		w.personal_gold = maxi(0, w.personal_gold) + amount
		a.modify_npc_relationship(w, -30, "Me chantajea", true)
		a.add_thought("%s me chantajea (-12)" % w.npc_name, -12.0)
		vm.record_social_event("blackmail", w, a, "%s chantajea a %s: le pagó %d de oro por su silencio" % [w.npc_name, a.npc_name, amount])
		return
	a.modify_npc_relationship(w, -30, "Intentó chantajearme", true)
	vm.record_social_event("blackmail", w, a, "%s intentó chantajear a %s; no pagó y se lo contó a %s" % [w.npc_name, a.npc_name, s["p_name"]])
	var p: VillageNPC = vm._get_npcs_by_person_key().get(str(s["partner"]), null)
	if p != null:
		var ev: Dictionary = _gossip_event(vm, s)
		var lover_name: String = GossipMemory.render(ev, str(s["b_name"]), w.get_person_key()) if not ev.is_empty() else str(s["b_name"])
		partner_reaction(vm, s, p, str(s["a_name"]), lover_name, "se lo contó %s" % w.npc_name)

# ==============================================================================
# S5: el jugador
# ==============================================================================
static func player_learns(vm: VillageManager, s: Dictionary, lover_name: String, how: String) -> void:
	if bool(s.get("player_knows", false)):
		return
	s["player_knows"] = true
	s["player_lover"] = lover_name
	VillageChronicle.add(vm, "affair_known", "Sabes que %s engaña a %s con %s (%s)" % [s["a_name"], s["p_name"], lover_name, how], true)

## Al preguntar a `npc` por novedades: si te cuenta una aventura, ya la sabes (con su versión del amante).
static func on_player_news(vm: VillageManager, npc: VillageNPC) -> void:
	var nk: String = npc.get_person_key()
	for ev in vm.get_news_known_by(npc):
		if str(ev.get("type", "")) != "affair":
			continue
		var s: Dictionary = secret_of_event(vm, ev)
		if not s.is_empty() and bool(s.get("active", false)):
			player_learns(vm, s, GossipMemory.render(ev, str(s["b_name"]), nk), "te lo contó %s" % npc.npc_name)

## Opciones de diálogo con el infiel o con la pareja engañada.
static func add_dialogue_choices(vm: VillageManager, npc: VillageNPC, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null:
		return
	var nk: String = npc.get_person_key()
	for s in vm.secrets:
		if not bool(s.get("active", false)) or not bool(s.get("player_knows", false)):
			continue
		var sid: int = int(s["id"])
		if nk == str(s["a"]) and str(s.get("player_deal", "")) == "":
			var node: String = "secret_a_%d" % sid
			ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🤫 «Sé lo tuyo con %s»" % s["player_lover"], "next": node})
			var fem: bool = npc.person_profile != null and str(npc.person_profile.gender) == "F"
			diag[node] = {"text": "«¿Qué...? ¿De qué estás hablando?»\n(%s se ha puesto %s.)" % [npc.npc_name, "pálida" if fem else "pálido"], "choices": [
				{"label": "💰 Pedirle oro para callar", "next": "END", "action": "secret_blackmail:%d" % sid},
				{"label": "🤐 Prometerle que no diré nada", "next": "END", "action": "secret_silence:%d" % sid},
				{"label": "⬅️ Mejor lo dejo estar", "next": "start"}]}
		elif nk == str(s["partner"]) and not bool(s.get("player_told", false)):
			var node2: String = "secret_p_%d" % sid
			ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "💔 «Tengo algo que contarte sobre %s»" % s["a_name"], "next": node2})
			diag[node2] = {"text": "«¿Sobre %s? Me estás asustando... cuéntame.»" % s["a_name"], "choices": [
				{"label": "Contarle que se ve a escondidas con %s" % s["player_lover"], "next": "END", "action": "secret_tell:%d" % sid},
				{"label": "⬅️ No, nada, olvídalo", "next": "start"}]}

static func _by_id(vm: VillageManager, sid: int) -> Dictionary:
	for s in vm.secrets:
		if int(s.get("id", -1)) == sid:
			return s
	return {}

## Acciones del diálogo. `inv` = inventario del jugador. `roll` para los tests (−1 = al azar).
static func on_player_action(vm: VillageManager, npc: VillageNPC, action_id: String, inv: Object, roll: float = -1.0) -> void:
	var s: Dictionary = _by_id(vm, int(action_id.get_slice(":", 1)))
	if s.is_empty() or not bool(s.get("active", false)):
		return
	var r: float = roll if roll >= 0.0 else randf()
	var wrong: bool = str(s.get("player_lover", "")) != str(s["b_name"]) # El rumor que oíste señalaba a otra persona
	if action_id.begins_with("secret_blackmail:"):
		s["player_deal"] = "blackmail"
		if wrong:
			npc.modify_affinity(-15)
			npc._spawn_floating_text("😤 «¿Con %s? ¡No sé de qué me hablas!»" % s["player_lover"], Color.ORANGE, -46.0)
			return
		var amount: int = clampi(int(float(maxi(0, npc.personal_gold)) / 2.0), 0, BLACKMAIL_MAX_GOLD)
		if amount >= 5 and r < PLAYER_BLACKMAIL_PAY_CHANCE:
			npc.personal_gold -= amount
			inv.add_gold(amount)
			npc.modify_affinity(-30)
			npc.add_thought("Me chantajean (-12)", -12.0)
			npc._spawn_floating_text("😰 «Toma %d de oro... y ni una palabra.»" % amount, Color(1.0, 0.85, 0.40), -46.0)
			VillageChronicle.add(vm, "player_blackmail", "Chantajeaste a %s: te pagó %d de oro por callar lo de %s" % [npc.npc_name, amount, s["b_name"]], true)
		else:
			npc.modify_affinity(-20)
			npc._spawn_floating_text("😠 «¡Haz lo que quieras, no pienso pagarte!»", Color.ORANGE, -46.0)
			VillageChronicle.add(vm, "player_blackmail", "Intentaste chantajear a %s, pero se negó a pagar" % npc.npc_name, true)
	elif action_id.begins_with("secret_silence:"):
		s["player_deal"] = "silence"
		if wrong:
			npc._spawn_floating_text("🤨 «No sé de qué hablas... pero vale.»", Color(0.85, 0.85, 0.85), -46.0)
			return
		npc.modify_affinity(8)
		npc.add_thought("Me guardará el secreto (+6)", 6.0)
		npc._spawn_floating_text("🙏 «Gracias... de verdad.»", Color(0.75, 1.0, 0.80), -46.0)
	elif action_id.begins_with("secret_tell:"):
		s["player_told"] = true
		npc.modify_affinity(5)
		var by_key: Dictionary = vm._get_npcs_by_person_key()
		var cheater: VillageNPC = by_key.get(str(s["a"]), null)
		if cheater != null and str(s.get("player_deal", "")) == "silence":
			cheater.modify_affinity(-25) # Le prometiste callar
		VillageChronicle.add(vm, "player_told_secret", "Le contaste a %s que %s se ve a escondidas con %s" % [npc.npc_name, s["a_name"], s["player_lover"]], true)
		partner_reaction(vm, s, npc, str(s["a_name"]), str(s["player_lover"]), "se lo contaste tú")
