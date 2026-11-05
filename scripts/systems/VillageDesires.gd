@tool
extends RefCounted

## Deseos propios (bloques D, `docs/PLAN_DESEOS.md`). Algunos vecinos quieren algo y dan pasos durante días.
## Vive en `VillageManager.desires` (se guarda). Un deseo activo por vecino, con final y descanso entre deseos.
## Cada deseo: {id, type: "revenge" | "ambition" | "against_player" | "murder", holder, holder_name, target ("player" si
##   es contra el jugador), target_name, reason, day, step, next_day, open, known_by{}, player_knows, gossip_uid, active,
##   end_day, outcome, prep_until (asesinato), refuse_trade (contra el jugador)}
## Se descubren: hablando con aprecio suficiente («¿Qué te ronda la cabeza?»), por chismes, o porque el vecino lo dice
## abiertamente (`open`): entonces él mismo lo va contando.

const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageSecrets = preload("res://scripts/systems/VillageSecrets.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

# --- Diales ---
const COOLDOWN_DAYS: int = 10 # Descanso entre deseos del mismo vecino
const STEP_MIN_DAYS: int = 2
const STEP_MAX_DAYS: int = 4
const REVENGE_REL: int = -50 # Odio que despierta la venganza
const REVENGE_KEEP_REL: int = -30 # Si se le pasa por encima, lo deja
const REVENGE_DAILY: float = 0.10
const REVENGE_BASE_DAYS: int = 20 # + 15 por punto de rencor
const AMBITION_MIN: float = 0.8
const AMBITION_DAILY: float = 0.05
const AMBITION_SAVE_GOLD: int = 8
const PLAYER_HATE: int = -50
const PLAYER_HATE_DAYS: int = 7
const PLAYER_DAILY: float = 0.20
const PLAYER_KEEP: int = -30
const PLAYER_BADMOUTH_AFF: int = -2
const PLAYER_SECRET_AFF: int = -3
const REPORT_BOUNTY_TRUE: int = 15
const REPORT_BOUNTY_FALSE: int = 10
const MURDER_REL: int = -80
const MURDER_MIN_DAYS: int = 10 # Días de venganza antes de pensar en matar
const MURDER_DARKNESS: float = 1.5 # malicia + agresividad − honestidad
const MURDER_DAILY: float = 0.05
const MURDER_GLOBAL_GAP: int = 30 # Como mucho un asesinato entre vecinos al mes
const MURDER_SIGN_CHANCE: float = 0.35
## V8: la venganza por celos (infidelidad) llega antes a la idea de matar, pero sigue siendo muy rara
const PASSION_MURDER_REL: int = -60
const PASSION_MURDER_DARKNESS: float = 0.9
const PASSION_MURDER_MIN_DAYS: int = 5
const MURDER_THREAT_FOIL: float = 0.5 # Si la amenaza llega a la víctima, se pone en guardia
const WITNESS_RADIUS: float = 170.0
const TELL_OPEN_AFF: int = 10
const TELL_SECRET_AFF: int = 50
const CALM_MIN_AFF: int = 40
const CALM_CHANCE: float = 0.5

const TYPE_TEXT: Dictionary = {
	"revenge": "quiere vengarse de %s",
	"ambition": "quiere llegar a tener más que %s",
	"against_player": "no soporta al forastero y quiere hacérselo pagar",
	"murder": "planea matar a %s",
}

static func _today() -> int:
	return int(WorldClock.current_day) if WorldClock != null else 1

static func _tend(n: VillageNPC, k: String) -> float:
	return TraitCatalog.npc_tendency(n, k)

static func describe(d: Dictionary) -> String:
	var t: String = str(TYPE_TEXT.get(str(d.get("type", "")), "quiere algo"))
	return "%s %s" % [d.get("holder_name", "?"), t % str(d.get("target_name", "")) if t.contains("%s") else t]

static func active_of(vm: VillageManager, key: String) -> Dictionary:
	for d in vm.desires:
		if bool(d.get("active", false)) and str(d.get("holder", "")) == key:
			return d
	return {}

static func _by_id(vm: VillageManager, id: int) -> Dictionary:
	for d in vm.desires:
		if int(d.get("id", -1)) == id:
			return d
	return {}

static func _last_end(vm: VillageManager, key: String) -> int:
	var e: int = -9999
	for d in vm.desires:
		if str(d.get("holder", "")) == key and not bool(d.get("active", false)):
			e = maxi(e, int(d.get("end_day", -9999)))
	return e

static func _next_step_day(vm: VillageManager) -> int:
	return _today() + vm.social_director.rng.randi_range(STEP_MIN_DAYS, STEP_MAX_DAYS)

static func create(vm: VillageManager, type_str: String, holder: VillageNPC, target_key: String, target_name: String, reason: String, open: bool) -> Dictionary:
	vm.desire_uid += 1
	var d: Dictionary = {"id": vm.desire_uid, "type": type_str, "holder": holder.get_person_key(), "holder_name": holder.npc_name,
		"target": target_key, "target_name": target_name, "reason": reason, "day": _today(), "step": 0, "next_day": _next_step_day(vm),
		"open": open, "known_by": {holder.get_person_key(): true}, "player_knows": false, "gossip_uid": -1, "active": true,
		"end_day": -1, "outcome": "", "prep_until": -1, "refuse_trade": false}
	vm.desires.append(d)
	VillageChronicle.add(vm, "desire_" + type_str, "%s (%s)" % [describe(d), reason] if reason != "" else describe(d), false)
	return d

static func finish(vm: VillageManager, d: Dictionary, outcome: String) -> void:
	if not bool(d.get("active", false)):
		return
	d["active"] = false
	d["end_day"] = _today()
	d["outcome"] = outcome
	d["refuse_trade"] = false
	var why: Dictionary = {"satisfied": "se dio por satisfecho/a", "reconciled": "se le pasó el enfado", "forgot": "lo fue dejando con el tiempo",
		"foiled": "le pararon los pies", "calmed": "le convenciste de dejarlo", "done": "lo llevó a cabo", "gone": "ya no tiene sentido"}
	VillageChronicle.add(vm, "desire_end", "%s: %s" % [describe(d), str(why.get(outcome, outcome))], bool(d.get("player_knows", false)))

# ==============================================================================
# Cada día
# ==============================================================================
static func daily(vm: VillageManager) -> void:
	if vm.social_director == null:
		return
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var today: int = _today()
	for d in vm.desires.duplicate():
		if bool(d.get("active", false)):
			_advance(vm, d, by_key, today)
	for k in by_key.keys():
		var n: VillageNPC = by_key[k]
		if n.is_dead or n.trade_role == VillageNPC.TradeRole.ROYAL_INVESTIGATOR:
			continue
		_track_player_hate(vm, n, today)
		if active_of(vm, str(k)).is_empty() and today - _last_end(vm, str(k)) >= COOLDOWN_DAYS:
			_maybe_new_desire(vm, n, by_key, today)
	for d2 in vm.desires:
		if bool(d2.get("active", false)) and bool(d2.get("open", false)):
			_ensure_open_rumor(vm, d2, by_key)

static func _track_player_hate(vm: VillageManager, n: VillageNPC, today: int) -> void:
	var k: String = n.get_person_key()
	if n.affinity <= PLAYER_HATE:
		if not vm.desire_hate_since.has(k):
			vm.desire_hate_since[k] = today
	else:
		vm.desire_hate_since.erase(k)

static func _maybe_new_desire(vm: VillageManager, n: VillageNPC, by_key: Dictionary, today: int) -> void:
	var rng = vm.social_director.rng
	var k: String = n.get_person_key()
	# D4: contra el jugador
	if vm.desire_hate_since.has(k) and today - int(vm.desire_hate_since[k]) >= PLAYER_HATE_DAYS and rng.randf() < PLAYER_DAILY:
		create(vm, "against_player", n, "player", "el forastero", "le tiene un odio profundo", _tend(n, "aggression") > 0.3 or _tend(n, "honesty") >= 0.5)
		return
	# D2: venganza contra quien más odia
	var worst: VillageNPC = null
	var worst_rel: int = REVENGE_REL + 1
	for ok in by_key.keys():
		var o: VillageNPC = by_key[ok]
		if o == n or o.is_dead:
			continue
		var r: int = n.get_relationship_with_npc(str(ok))
		if r < worst_rel:
			worst_rel = r
			worst = o
	if worst != null and rng.randf() < clampf(REVENGE_DAILY * (1.0 + 0.5 * _tend(n, "grudge")), 0.02, 0.25):
		var note: String = str(n.npc_relationship_notes.get(worst.get_person_key(), ""))
		create(vm, "revenge", n, worst.get_person_key(), worst.npc_name, note, _tend(n, "honesty") >= 0.5)
		return
	# D3: ambición / envidia del que más tiene
	var amb: float = _tend(n, "ambition")
	var envious: bool = n.person_profile != null and ("Envidioso" in n.person_profile.personality or "Codicioso" in n.person_profile.personality)
	if (amb >= AMBITION_MIN or envious) and rng.randf() < AMBITION_DAILY:
		var rich: VillageNPC = null
		for ok2 in by_key.keys():
			var o2: VillageNPC = by_key[ok2]
			if o2 == n or o2.is_dead or (n.family_id != "none" and n.family_id == o2.family_id):
				continue
			if rich == null or o2.personal_gold > rich.personal_gold:
				rich = o2
		if rich != null:
			create(vm, "ambition", n, rich.get_person_key(), rich.npc_name, "envidia lo que tiene" if envious else "quiere prosperar", true)

static func _advance(vm: VillageManager, d: Dictionary, by_key: Dictionary, today: int) -> void:
	var h: VillageNPC = by_key.get(str(d["holder"]), null)
	if h == null or h.is_dead:
		finish(vm, d, "gone")
		return
	var t: VillageNPC = null
	if str(d["target"]) != "player":
		t = by_key.get(str(d["target"]), null)
		if t == null or t.is_dead:
			finish(vm, d, "gone")
			return
	match str(d["type"]):
		"murder":
			_advance_murder(vm, d, h, t, today)
			return
		"revenge":
			if h.get_relationship_with_npc(str(d["target"])) > REVENGE_KEEP_REL:
				finish(vm, d, "reconciled")
				return
			if today - int(d["day"]) > REVENGE_BASE_DAYS + int(15.0 * _tend(h, "grudge")):
				finish(vm, d, "forgot")
				return
			if _maybe_turn_murder(vm, d, h, t, today):
				return
		"against_player":
			if h.affinity > PLAYER_KEEP:
				finish(vm, d, "reconciled")
				return
	if today < int(d.get("next_day", 0)):
		return
	d["next_day"] = _next_step_day(vm)
	d["step"] = int(d["step"]) + 1
	match str(d["type"]):
		"revenge":
			_revenge_step(vm, d, h, t)
		"ambition":
			_ambition_step(vm, d, h, t)
		"against_player":
			_player_step(vm, d, h)

# ==============================================================================
# D2: venganza
# ==============================================================================
static func _revenge_step(vm: VillageManager, d: Dictionary, h: VillageNPC, t: VillageNPC) -> void:
	var step: int = int(d["step"])
	if step == 1:
		_badmouth(vm, h, t)
	elif step == 2:
		if not _tell_secret(vm, h, t):
			d["step"] = 3
			if not _sabotage(vm, h, t):
				_seek_fight(vm, h, t)
	elif step == 3:
		if not _sabotage(vm, h, t):
			_seek_fight(vm, h, t)
	elif step == 4:
		_seek_fight(vm, h, t)
	else:
		finish(vm, d, "satisfied")

static func _badmouth(vm: VillageManager, h: VillageNPC, t: VillageNPC) -> void:
	vm.record_social_event("npc_slander", h, t, "%s va diciendo cosas feas de %s" % [h.npc_name, t.npc_name])

## Cuenta a la pareja de `t` la aventura de `t`, si la sabe.
static func _tell_secret(vm: VillageManager, h: VillageNPC, t: VillageNPC) -> bool:
	for s in vm.secrets:
		if bool(s.get("active", false)) and str(s.get("a", "")) == t.get_person_key() and (s["known_by"] as Dictionary).has(h.get_person_key()):
			var p: VillageNPC = vm._get_npcs_by_person_key().get(str(s["partner"]), null)
			if p != null and not p.is_dead and p != h:
				VillageSecrets.partner_reaction(vm, s, p, str(s["a_name"]), str(s["b_name"]), "se lo contó %s para vengarse" % h.npc_name)
				return true
	return false

## Le estropea el negocio a `t`, si tiene uno.
static func _sabotage(vm: VillageManager, h: VillageNPC, t: VillageNPC) -> bool:
	var role: int = int(t.trade_role)
	if not vm.shop_businesses.has(role) or vm.trade_npcs.get(role) != t:
		return false
	var biz: Dictionary = vm.shop_businesses[role]
	biz["sabotaged_days"] = maxi(int(biz.get("sabotaged_days", 0)), 2)
	vm._refresh_shop_stall_visual(role)
	t.add_thought("Alguien me ha destrozado el puesto (-10)", -10.0)
	VillageChronicle.add(vm, "sabotage", "%s le destrozó el puesto a %s" % [h.npc_name, t.npc_name], false)
	return true

static func _seek_fight(vm: VillageManager, h: VillageNPC, t: VillageNPC) -> void:
	var pe: Dictionary = vm.social_director.get_pair_entry(h.get_person_key(), t.get_person_key())
	pe["tension"] = clampi(int(pe.get("tension", 0)) + 30, 0, 100)
	h.modify_npc_relationship(t, -5, "Le busca las cosquillas", true)
	h.add_thought("Como vea a %s, se va a enterar (-4)" % t.npc_name, -4.0)

# ==============================================================================
# D3: ambición
# ==============================================================================
static func _ambition_step(vm: VillageManager, d: Dictionary, h: VillageNPC, t: VillageNPC) -> void:
	var step: int = int(d["step"])
	if step == 1:
		# Regla 1: ahorrar es apartar, no crear oro: no cambia su bolsillo.
		h.add_thought("Estoy ahorrando para llegar a más (+3)", 3.0)
	elif step == 2:
		_badmouth(vm, h, t)
	elif step == 3:
		if not _sabotage(vm, h, t):
			h.add_thought("No me atreví; seguiré ahorrando", 1.0)
	else:
		finish(vm, d, "satisfied")

# ==============================================================================
# D4: contra el jugador
# ==============================================================================
const PLAYER_STEPS: Array[String] = ["badmouth", "refuse", "report", "secret"]
static func _player_step(vm: VillageManager, d: Dictionary, h: VillageNPC) -> void:
	var step: int = int(d["step"])
	if step > PLAYER_STEPS.size():
		finish(vm, d, "satisfied")
		return
	match PLAYER_STEPS[step - 1]:
		"badmouth":
			_player_rumor(vm, h, "player_badmouth", "%s va diciendo que el forastero no es de fiar" % h.npc_name)
		"refuse":
			d["refuse_trade"] = true
			h.add_thought("No pienso venderle nada al forastero (+2)", 2.0)
		"report":
			report_player(vm, h)
		"secret":
			var secret_txt: String = player_secret_known_by(vm, h)
			if secret_txt != "":
				_player_rumor(vm, h, "player_secret", "%s va contando que el forastero %s" % [h.npc_name, secret_txt])
			else:
				_player_rumor(vm, h, "player_badmouth", "%s va diciendo que el forastero es un peligro" % h.npc_name)

static func _player_rumor(vm: VillageManager, h: VillageNPC, type_str: String, summary: String) -> void:
	var ev: Dictionary = vm.record_social_event(type_str, h, null, summary)
	ev["known_by"] = {h.get_person_key(): true}
	ev["heard_from"] = {}

## Algo turbio del jugador que sabe `h` (hoy: que le chantajeó), o "".
static func player_secret_known_by(vm: VillageManager, h: VillageNPC) -> String:
	for s in vm.secrets:
		if str(s.get("player_deal", "")) == "blackmail" and str(s.get("a", "")) == h.get_person_key():
			return "chantajea a la gente"
	return ""

## Te denuncia al comisario: con algo cierto si tienes antecedentes; inventado si es mentiroso.
static func report_player(vm: VillageManager, h: VillageNPC) -> void:
	var msg: String = ""
	if not vm.crime_history.is_empty():
		vm.bounty_gold += REPORT_BOUNTY_TRUE
		msg = "🗣️🚨 %s fue a la comisaría a contar lo que sabe de tus delitos (+%d Oro de multa)" % [h.npc_name, REPORT_BOUNTY_TRUE]
	elif _tend(h, "honesty") <= -0.3:
		vm.bounty_gold += REPORT_BOUNTY_FALSE
		msg = "🗣️🚨 %s te denunció en la comisaría por algo que no hiciste (+%d Oro de multa)" % [h.npc_name, REPORT_BOUNTY_FALSE]
	else:
		return
	vm.crime_history.push_front(msg)
	vm._notify_inquisitor_of_police_crime(msg, 8)
	VillageChronicle.add(vm, "player_reported", msg, true)

static func refuses_trade(vm: VillageManager, npc: VillageNPC) -> bool:
	var d: Dictionary = active_of(vm, npc.get_person_key())
	return not d.is_empty() and bool(d.get("refuse_trade", false))

## Quita las compras del diálogo de quien se niega a venderte.
static func filter_dialogue(vm: VillageManager, npc: VillageNPC, diag: Dictionary) -> void:
	if vm == null or not refuses_trade(vm, npc):
		return
	for node_k in diag.keys():
		var node = diag[node_k]
		if typeof(node) != TYPE_DICTIONARY or not (node as Dictionary).has("choices"):
			continue
		var kept: Array = []
		for c in node["choices"]:
			if typeof(c) == TYPE_DICTIONARY and (str(c.get("action", "")).begins_with("buy") or str(c.get("label", "")).contains("Comprar")):
				continue
			kept.append(c)
		node["choices"] = kept
	if diag.has("start"):
		diag["start"]["text"] = "«A ti no te vendo nada. Búscate a otro.»\n" + str(diag["start"].get("text", ""))

# ==============================================================================
# D5: planes de asesinato
# ==============================================================================
static func darkness(n: VillageNPC) -> float:
	return _tend(n, "malice") + _tend(n, "aggression") - _tend(n, "honesty")

static func _maybe_turn_murder(vm: VillageManager, d: Dictionary, h: VillageNPC, t: VillageNPC, today: int) -> bool:
	if t.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.ROYAL_INVESTIGATOR] or h.trade_role == VillageNPC.TradeRole.SHERIFF:
		return false
	var passion: bool = bool(d.get("passion", false))
	if h.get_relationship_with_npc(t.get_person_key()) > (PASSION_MURDER_REL if passion else MURDER_REL) or today - int(d["day"]) < (PASSION_MURDER_MIN_DAYS if passion else MURDER_MIN_DAYS) or darkness(h) < (PASSION_MURDER_DARKNESS if passion else MURDER_DARKNESS):
		return false
	if today - vm.last_npc_murder_day < MURDER_GLOBAL_GAP or vm.social_director.rng.randf() >= MURDER_DAILY:
		return false
	d["type"] = "murder"
	d["open"] = false
	d["prep_until"] = today + vm.social_director.rng.randi_range(3, 5)
	VillageChronicle.add(vm, "desire_murder", describe(d), false)
	return true

static func _advance_murder(vm: VillageManager, d: Dictionary, h: VillageNPC, t: VillageNPC, today: int) -> void:
	if today < int(d.get("prep_until", 0)):
		if vm.social_director.rng.randf() < MURDER_SIGN_CHANCE:
			murder_sign(vm, d, h, t)
		return
	if not try_commit_murder(vm, d, h, t):
		d["prep_until"] = today + 1 # Había alguien despierto cerca: lo intenta otra noche

## Señal del plan: lo dice entre dientes. Quien esté cerca (y tú) se entera.
static func murder_sign(vm: VillageManager, d: Dictionary, h: VillageNPC, t: VillageNPC) -> void:
	h._spawn_floating_text("😠 «...%s me las pagará. Con su vida.»" % t.npc_name, Color(1.0, 0.45, 0.40), -46.0)
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n == h or n == t or not (n is VillageNPC) or n.is_dead or n.is_sleeping:
			continue
		if (n as VillageNPC).global_position.distance_to(h.global_position) <= WITNESS_RADIUS:
			learn(vm, d, n)
	var pl = vm.get_tree().get_first_node_in_group("player")
	if pl != null and (pl as Node2D).global_position.distance_to(h.global_position) <= WITNESS_RADIUS:
		player_learns(vm, d, "se lo oíste decir")

## Mata a `t` esta noche si nadie despierto está cerca. Devuelve si lo hizo.
static func try_commit_murder(vm: VillageManager, d: Dictionary, h: VillageNPC, t: VillageNPC) -> bool:
	if vm._find_conscious_witness_near(t.global_position, 165.0, t) != null:
		return false
	vm.npc_murders[t.npc_name] = h.npc_name
	vm.last_npc_murder_day = _today()
	VillageChronicle.add(vm, "murder", "%s mató a %s" % [h.npc_name, t.npc_name], false)
	finish(vm, d, "done")
	t.last_hit_by_player = false
	t.last_hit_weapon_name = "Puñalada (cuchillo)"
	vm.VillageForensics.on_npc_murder_committed(vm, h, t, d) # P2: método según oficio, pista falsa o veneno lento
	t._confirm_true_death()
	t.murder_witness_name = ""
	# P1.1: la familia NO sabe aún quién fue; el rencor de clan llega al cerrarse el caso (_mark_morgue_case_resolved)
	return true

## Pista para el comisario al abrir el caso (VillageJustice).
static func killer_of(vm: VillageManager, victim_name: String) -> String:
	return str(vm.npc_murders.get(victim_name, ""))

# ==============================================================================
# Cómo se descubren
# ==============================================================================
static func learn(vm: VillageManager, d: Dictionary, n: VillageNPC) -> void:
	d["known_by"][n.get_person_key()] = true
	var ev: Dictionary = _rumor_event(vm, d)
	if ev.is_empty():
		var by_key: Dictionary = vm._get_npcs_by_person_key()
		var typ: String = "murder_threat" if str(d["type"]) == "murder" else "desire_rumor"
		var summary: String = "%s va diciendo que %s lo pagará con su vida" % [d["holder_name"], d["target_name"]] if typ == "murder_threat" else describe(d)
		ev = vm.record_social_event(typ, by_key.get(str(d["holder"]), null), by_key.get(str(d["target"]), null), summary)
		ev["known_by"] = {}
		ev["heard_from"] = {}
		ev["desire_id"] = int(d["id"])
		if typ == "murder_threat":
			ev["quiet"] = [str(d["holder"])] # El que lo planea no lo va contando
		d["gossip_uid"] = int(ev.get("uid", -1))
	ev["known_by"][n.get_person_key()] = true
	if ev.has("forgot"):
		(ev["forgot"] as Dictionary).erase(n.get_person_key())

static func _rumor_event(vm: VillageManager, d: Dictionary) -> Dictionary:
	var uid: int = int(d.get("gossip_uid", -1))
	if uid < 0:
		return {}
	for ev in vm._get_live_gossip():
		if int(ev.get("uid", -1)) == uid:
			return ev
	return {}

## Los deseos que se dicen abiertamente: el propio vecino lo va contando.
static func _ensure_open_rumor(vm: VillageManager, d: Dictionary, by_key: Dictionary) -> void:
	if not _rumor_event(vm, d).is_empty():
		return
	var h: VillageNPC = by_key.get(str(d["holder"]), null)
	if h != null:
		learn(vm, d, h)

static func desire_of_event(vm: VillageManager, ev: Dictionary) -> Dictionary:
	return _by_id(vm, int(ev.get("desire_id", -1))) if ev.has("desire_id") else {}

## Alguien oye un chisme (desde `spread_gossip`).
static func on_heard(vm: VillageManager, ev: Dictionary, _teller: VillageNPC, listener: VillageNPC) -> void:
	var typ: String = str(ev.get("type", ""))
	if typ == "player_badmouth":
		listener.modify_affinity(PLAYER_BADMOUTH_AFF)
	elif typ == "player_secret":
		listener.modify_affinity(PLAYER_SECRET_AFF)
	var d: Dictionary = desire_of_event(vm, ev)
	if d.is_empty():
		return
	d["known_by"][listener.get_person_key()] = true
	if bool(d.get("active", false)) and listener.get_person_key() == str(d["target"]):
		var h: VillageNPC = vm._get_npcs_by_person_key().get(str(d["holder"]), null)
		if h != null:
			listener.modify_npc_relationship(h, -20, "Dicen que va a por mí", true)
		if str(d["type"]) == "murder" and vm.social_director.rng.randf() < MURDER_THREAT_FOIL:
			finish(vm, d, "foiled") # La víctima se pone en guardia

static func player_learns(vm: VillageManager, d: Dictionary, how: String) -> void:
	if bool(d.get("player_knows", false)):
		return
	d["player_knows"] = true
	VillageChronicle.add(vm, "desire_known", "Sabes que %s (%s)" % [describe(d), how], true)

## Al preguntar por novedades: lo que te cuentan de deseos ajenos.
static func on_player_news(vm: VillageManager, npc: VillageNPC) -> void:
	for ev in vm.get_news_known_by(npc):
		var d: Dictionary = desire_of_event(vm, ev)
		if not d.is_empty() and bool(d.get("active", false)):
			player_learns(vm, d, "te lo contó %s" % npc.npc_name)

## ¿Te lo cuenta si le preguntas?
static func would_tell(npc: VillageNPC, d: Dictionary) -> bool:
	if d.is_empty() or str(d["type"]) == "murder":
		return false
	if str(d["target"]) == "player":
		return bool(d.get("open", false)) # O te lo dice a la cara, o no te lo dice
	return npc.affinity >= (TELL_OPEN_AFF if bool(d.get("open", false)) else TELL_SECRET_AFF)

# ==============================================================================
# Diálogo
# ==============================================================================
static func add_dialogue_choices(vm: VillageManager, npc: VillageNPC, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null:
		return
	var d: Dictionary = active_of(vm, npc.get_person_key())
	var ans: String = "«Nada en especial, la verdad.»"
	if not d.is_empty():
		if would_tell(npc, d):
			match str(d["type"]):
				"revenge": ans = "«%s me las va a pagar. No pienso dejarlo pasar.»" % d["target_name"]
				"ambition": ans = "«Algún día tendré más que %s. Ya lo verás.»" % d["target_name"]
				"against_player": ans = "«¿Tú? Tú eres lo que me ronda la cabeza. Aléjate de mí.»"
		elif str(d["type"]) == "murder" and npc.affinity >= 60:
			ans = "«Nada... cosas mías.»\n(Le notas algo raro en la mirada cuando sale el nombre de %s.)" % d["target_name"]
		else:
			ans = "«Cosas mías. No es asunto tuyo.»"
	ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "💭 Preguntar qué le ronda la cabeza", "next": "desire_ask", "action": "desire_ask"})
	var back: Array = [{"label": "⬅️ Volver a la conversación", "next": "start"}]
	if not d.is_empty() and bool(d.get("player_knows", false)) and str(d["type"]) in ["revenge", "ambition"] and npc.affinity >= CALM_MIN_AFF:
		back.push_front({"label": "🕊️ Intentar convencerle de que lo deje", "next": "END", "action": "desire_calm:%d" % int(d["id"])})
	diag["desire_ask"] = {"text": ans, "choices": back}
	# Avisar a una víctima o al comisario de un plan de asesinato que conoces
	for m in vm.desires:
		if not bool(m.get("active", false)) or str(m.get("type", "")) != "murder" or not bool(m.get("player_knows", false)):
			continue
		if str(m["target"]) == npc.get_person_key():
			ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "⚠️ Avisarle de que %s quiere hacerle daño" % m["holder_name"], "next": "END", "action": "desire_warn:%d" % int(m["id"])})
		elif npc.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD] and str(m["holder"]) != npc.get_person_key():
			ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🚨 Denunciar que %s planea matar a %s" % [m["holder_name"], m["target_name"]], "next": "END", "action": "desire_report:%d" % int(m["id"])})

## `roll` para los tests (−1 = al azar).
static func on_player_action(vm: VillageManager, npc: VillageNPC, action_id: String, roll: float = -1.0) -> void:
	if action_id == "desire_ask":
		var d0: Dictionary = active_of(vm, npc.get_person_key())
		if would_tell(npc, d0):
			player_learns(vm, d0, "te lo dijo %s" % npc.npc_name)
		return
	var d: Dictionary = _by_id(vm, int(action_id.get_slice(":", 1)))
	if d.is_empty() or not bool(d.get("active", false)):
		return
	var r: float = roll if roll >= 0.0 else randf()
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var h: VillageNPC = by_key.get(str(d["holder"]), null)
	if action_id.begins_with("desire_calm:"):
		if r < CALM_CHANCE:
			npc._spawn_floating_text("😮‍💨 «Quizá tengas razón... no merece la pena.»", Color(0.75, 1.0, 0.80), -46.0)
			npc.modify_affinity(5)
			finish(vm, d, "calmed")
		else:
			npc._spawn_floating_text("😤 «No me pidas eso.»", Color.ORANGE, -46.0)
			npc.modify_affinity(-3)
	elif action_id.begins_with("desire_warn:"):
		npc.modify_affinity(15)
		if h != null:
			npc.modify_npc_relationship(h, -30, "Me avisaron de que quería matarme", true)
		npc._spawn_floating_text("😨 «¿%s? Tendré cuidado... gracias.»" % d["holder_name"], Color(1.0, 0.85, 0.55), -46.0)
		VillageChronicle.add(vm, "player_foiled", "Avisaste a %s de que %s quería matarle" % [npc.npc_name, d["holder_name"]], true)
		finish(vm, d, "foiled")
	elif action_id.begins_with("desire_report:"):
		npc._spawn_floating_text("👮 «Le tendremos vigilado.»", Color(0.65, 0.82, 1.0), -46.0)
		if h != null:
			h.modify_affinity(-40)
		VillageChronicle.add(vm, "player_foiled", "Denunciaste ante %s que %s planeaba matar a %s" % [npc.npc_name, d["holder_name"], d["target_name"]], true)
		finish(vm, d, "foiled")
