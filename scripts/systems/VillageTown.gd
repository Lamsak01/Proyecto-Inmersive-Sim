@tool
extends RefCounted

## Instituciones y corrupción (bloques I, `docs/PLAN_INSTITUCIONES.md`).
## - I1: arcas del pueblo; impuesto cada sábado; ayuda a los pobres y sueldo del alcalde.
## - I2: alcalde elegido por votación al empezar y cada 28 días.
## - I3: corrupción del alcalde (desfalco) y de la policía (sobornos de ladrones y del jugador).
## - I5: lo que puede hacer el jugador (pedir votos, sobornar, denunciar).
## Estado en `vm.town_state` (se guarda).

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageFaith = preload("res://scripts/systems/VillageFaith.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")

const TERM_DAYS: int = 28
const CANDIDATES: int = 3
const BAND_VOTE_BONUS: int = 15
const PLEDGE_MIN_AFF: int = 30
const VOTE_PRICE: int = 10
const TAX_FREE_GOLD: int = 20
const TAX_RATE: float = 0.05
const TAX_RATE_RICH: float = 0.08
const SHOP_TAX: float = 0.05
const MAYOR_PAY: int = 5
const RELIEF_EACH: int = 5
const EMBEZZLE_SHARE: Vector2 = Vector2(0.3, 0.6)
const EMBEZZLE_NOTICE: float = 0.25
const EXPOSE_KNOWERS: int = 5
const EXPOSE_REL: int = -10
const CORRUPT_MIN: float = 0.5
const BRIBE_MIN: int = 20
const BRIBE_FAIL_FINE: int = 10

static func state(vm) -> Dictionary:
	if not (vm.town_state is Dictionary):
		vm.town_state = {}
	for k in ["pledges", "history"]:
		if not vm.town_state.has(k):
			vm.town_state[k] = {} if k == "pledges" else []
	for k in ["treasury", "taxed_total", "embezzled_total", "bribes", "elections"]:
		if not vm.town_state.has(k):
			vm.town_state[k] = 0
	return vm.town_state

# ---------------------------------------------------------------- I3 corrupción

## 0 = incorruptible … 1 = se vende por nada.
static func corruptibility(npc) -> float:
	var p: Array = npc.person_profile.personality if npc.person_profile != null else []
	if "Íntegro" in p:
		return 0.0
	var c: float = 0.35 - 0.35 * TraitCatalog.npc_tendency(npc, "honesty") - 0.25 * TraitCatalog.npc_tendency(npc, "law") + 0.15 * maxf(0.0, TraitCatalog.npc_tendency(npc, "ambition")) - 0.15 * TraitCatalog.npc_tendency(npc, "generosity")
	if "Sobornable" in p:
		c += 0.3
	return clampf(c, 0.0, 1.0)

static func is_corrupt(npc) -> bool:
	return npc != null and corruptibility(npc) >= CORRUPT_MIN

# ---------------------------------------------------------------- I2 alcalde

static func mayor_of(vm):
	var key: String = str(state(vm).get("mayor", ""))
	if key == "":
		return null
	var n = vm._get_npcs_by_person_key().get(key, null)
	return n if n != null and not n.is_dead else null

static func is_mayor(vm, npc) -> bool:
	return npc != null and str(state(vm).get("mayor", "")) == npc.get_person_key()

static func eligible(npc) -> bool:
	if npc.is_dead or VillageNeeds.is_outsider(npc) or npc.is_vagrant_camper:
		return false
	return not (int(npc.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.DOCTOR), int(VillageNPC.TradeRole.PRIEST)])

static func candidate_score(npc) -> float:
	return 2.0 * TraitCatalog.npc_tendency(npc, "leadership") + TraitCatalog.npc_tendency(npc, "ambition") + float(npc.personal_gold) / 100.0

static func candidates(vm) -> Array:
	var c: Array = []
	var banned: String = str(state(vm).get("banned", ""))
	for n in VillageNeeds.living(vm):
		if eligible(n) and n.get_person_key() != banned:
			c.append(n)
	c.sort_custom(func(a, b): return candidate_score(a) > candidate_score(b))
	return c.slice(0, CANDIDATES)

static func vote_of(vm, voter, cands: Array):
	var pledged: String = str(state(vm)["pledges"].get(voter.get_person_key(), ""))
	for c in cands:
		if c.get_person_key() == pledged:
			return c
	if voter in cands:
		return voter # Cada candidato se vota a sí mismo
	var best = null
	var best_s: float = -INF
	for c in cands:
		var s: float = float(voter.get_relationship_with_npc(c.get_person_key()))
		if VillageFaith.same_band(vm, voter, c):
			s += BAND_VOTE_BONUS
		s += 5.0 * TraitCatalog.npc_tendency(c, "leadership")
		if s > best_s:
			best_s = s
			best = c
	return best

static func hold_election(vm, reason: String = "") -> Dictionary:
	var st: Dictionary = state(vm)
	var cands: Array = candidates(vm)
	if cands.is_empty():
		return {}
	var votes: Dictionary = {}
	for v in VillageNeeds.living(vm):
		if VillageNeeds.is_outsider(v):
			continue
		var choice = vote_of(vm, v, cands)
		if choice != null:
			votes[choice.get_person_key()] = int(votes.get(choice.get_person_key(), 0)) + 1
	var winner = cands[0]
	for c in cands:
		if int(votes.get(c.get_person_key(), 0)) > int(votes.get(winner.get_person_key(), 0)):
			winner = c
	var old: String = str(st.get("mayor", ""))
	st["mayor"] = winner.get_person_key()
	st["mayor_name"] = winner.npc_name
	st["term_start"] = VillageNeeds.today()
	st["next_election"] = VillageNeeds.today() + TERM_DAYS
	st["pledges"] = {}
	st["elections"] = int(st["elections"]) + 1
	if reason == "":
		st["banned"] = "" # El destituido puede volver a presentarse en las elecciones normales
	var parts: Array[String] = []
	for c in cands:
		parts.append("%s %d" % [c.npc_name, int(votes.get(c.get_person_key(), 0))])
	var txt: String = "%s es %s alcalde (%s)%s" % [winner.npc_name, "el nuevo" if old != winner.get_person_key() else "otra vez", ", ".join(parts), (" — " + reason) if reason != "" else ""]
	(st["history"] as Array).append({"day": VillageNeeds.today(), "mayor": winner.npc_name, "votes": votes.duplicate()})
	VillageChronicle.add(vm, "election", txt, true)
	winner.add_thought("¡Me han elegido alcalde! (+15)", 15.0)
	return {"winner": winner, "votes": votes}

# ---------------------------------------------------------------- I1 arcas

static func collect_taxes(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	var total: int = 0
	for n in VillageNeeds.living(vm):
		if VillageNeeds.is_outsider(n) or n.personal_gold <= TAX_FREE_GOLD:
			continue
		var rate: float = TAX_RATE_RICH if VillageNeeds.class_of(n) == "rico" else TAX_RATE
		var tax: int = int(float(n.personal_gold - TAX_FREE_GOLD) * rate)
		if tax > 0:
			n.personal_gold -= tax
			total += tax
	for r in vm.shop_businesses.keys():
		var b: Dictionary = vm.shop_businesses[r]
		var t: int = int(float(int(b.get("vault_gold", 0))) * SHOP_TAX)
		if t > 0:
			b["vault_gold"] = int(b["vault_gold"]) - t
			total += t
	var res: Dictionary = {"taxed": total, "embezzled": 0, "relief": 0}
	st["taxed_total"] = int(st["taxed_total"]) + total
	var mayor = mayor_of(vm)
	if mayor != null and is_corrupt(mayor) and total > 0:
		var cut: int = int(float(total) * randf_range(EMBEZZLE_SHARE.x, EMBEZZLE_SHARE.y))
		mayor.personal_gold += cut
		total -= cut
		res["embezzled"] = cut
		st["embezzled_total"] = int(st["embezzled_total"]) + cut
		st["embezzled_term"] = int(st.get("embezzled_term", 0)) + cut
		_maybe_noticed(vm, mayor, cut)
	st["treasury"] = int(st["treasury"]) + total
	# Sueldo del alcalde y ayuda a los pobres
	if mayor != null and int(st["treasury"]) >= MAYOR_PAY:
		st["treasury"] = int(st["treasury"]) - MAYOR_PAY
		mayor.personal_gold += MAYOR_PAY
	for n in VillageNeeds.living(vm):
		if int(st["treasury"]) < RELIEF_EACH:
			break
		if VillageNeeds.class_of(n) in ["pobre", "mendigo"] and not VillageNeeds.is_outsider(n):
			st["treasury"] = int(st["treasury"]) - RELIEF_EACH
			n.personal_gold += RELIEF_EACH
			res["relief"] = int(res["relief"]) + RELIEF_EACH
			if mayor != null:
				n.modify_npc_relationship(mayor, 1, "Repartió la ayuda del pueblo", true)
	VillageChronicle.add(vm, "taxes", "Se cobraron %d de oro de impuestos; %d para los pobres" % [res["taxed"], res["relief"]], true)
	return res

static func _maybe_noticed(vm, mayor, cut: int) -> void:
	if randf() >= EMBEZZLE_NOTICE:
		return
	var others: Array = []
	for n in VillageNeeds.living(vm):
		if n != mayor and not VillageNeeds.is_outsider(n) and n.is_conscious():
			others.append(n)
	if others.is_empty():
		return
	var w = others[randi() % others.size()]
	var ev: Dictionary = vm.record_social_event("embezzle", mayor, null, "El alcalde %s se queda parte de los impuestos" % mayor.npc_name)
	ev["known_by"] = {mayor.get_person_key(): true, w.get_person_key(): true}
	ev["heard_from"] = {}
	ev["quiet"] = [mayor.get_person_key()]
	state(vm)["embezzle_ev"] = int(ev.get("uid", -1))
	VillageChronicle.add(vm, "embezzle", "%s se dio cuenta de que el alcalde %s se queda %d de oro de los impuestos" % [w.npc_name, mayor.npc_name, cut], false)

## Cuántos saben del desfalco actual.
static func embezzle_knowers(vm) -> Dictionary:
	var uid: int = int(state(vm).get("embezzle_ev", -1))
	if uid < 0:
		return {}
	for ev in vm.social_event_log:
		if int(ev.get("uid", -2)) == uid:
			return ev.get("known_by", {})
	return {}

## Se destapa: el alcalde devuelve lo robado este mandato, todos le miran peor y hay elecciones anticipadas.
static func expose(vm, how: String) -> void:
	var st: Dictionary = state(vm)
	var mayor = mayor_of(vm)
	if mayor == null:
		return
	var back: int = mini(int(st.get("embezzled_term", 0)), maxi(0, mayor.personal_gold))
	mayor.personal_gold -= back
	st["treasury"] = int(st["treasury"]) + back
	st["embezzled_term"] = 0
	st["embezzle_ev"] = -1
	st["exposed"] = int(st.get("exposed", 0)) + 1
	for n in VillageNeeds.living(vm):
		if n != mayor and not VillageNeeds.is_outsider(n):
			n.modify_npc_relationship(mayor, EXPOSE_REL, "Robó al pueblo siendo alcalde", true)
	mayor.add_thought("Me han pillado robando las arcas (-20)", -20.0)
	VillageChronicle.add(vm, "embezzle_exposed", "Se destapó que el alcalde %s robaba de las arcas (%s); devolvió %d de oro" % [mayor.npc_name, how, back], true)
	st["pledges"] = {}
	st["mayor"] = ""
	st["banned"] = mayor.get_person_key() # No puede presentarse en estas elecciones anticipadas
	hold_election(vm, "elecciones anticipadas tras el escándalo")

# ---------------------------------------------------------------- relojes

static func daily(vm) -> void:
	var st: Dictionary = state(vm)
	if mayor_of(vm) == null or VillageNeeds.today() >= int(st.get("next_election", 0)):
		hold_election(vm)
	if WorldClock != null and WorldClock.has_method("get_weekday") and int(WorldClock.get_weekday()) == 5 and int(st.get("last_tax_day", -1)) != VillageNeeds.today():
		st["last_tax_day"] = VillageNeeds.today()
		collect_taxes(vm)
	if int(st.get("embezzle_ev", -1)) >= 0 and embezzle_knowers(vm).size() >= EXPOSE_KNOWERS:
		expose(vm, "lo sabía medio pueblo")

# ---------------------------------------------------------------- I3 policía corrupta (la llama VillageCrime)

## ¿El ladrón compra al comisario? Devuelve true si se libra.
static func police_takes_bribe(vm, thief, witness) -> bool:
	var sheriff = null
	for n in VillageNeeds.living(vm):
		if int(n.trade_role) == int(VillageNPC.TradeRole.SHERIFF):
			sheriff = n
			break
	if sheriff == null or not is_corrupt(sheriff) or thief.personal_gold < 10:
		return false
	var pay: int = mini(thief.personal_gold, 15)
	thief.personal_gold -= pay
	sheriff.personal_gold += pay
	state(vm)["bribes"] = int(state(vm)["bribes"]) + 1
	if witness != null:
		witness.modify_npc_relationship(sheriff, -10, "Dejó escapar a %s" % thief.npc_name, true)
	var ev: Dictionary = vm.record_social_event("police_bribe", sheriff, thief, "El comisario %s dejó ir a %s a cambio de %d de oro" % [sheriff.npc_name, thief.npc_name, pay])
	ev["known_by"] = {sheriff.get_person_key(): true, thief.get_person_key(): true}
	if witness != null:
		ev["known_by"][witness.get_person_key()] = true
	ev["heard_from"] = {}
	ev["quiet"] = [sheriff.get_person_key(), thief.get_person_key()]
	VillageChronicle.add(vm, "police_bribe", "El comisario %s aceptó %d de oro de %s para olvidar un robo" % [sheriff.npc_name, pay, thief.npc_name], false)
	return true

# ---------------------------------------------------------------- I5 diálogo

static func bribe_price(vm) -> int:
	return maxi(BRIBE_MIN, int(float(vm.bounty_gold) * 1.5))

static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null:
		return
	var st: Dictionary = state(vm)
	var law: bool = int(npc.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)]
	if law and (vm.wanted_level > 0 or vm.bounty_gold > 0) and not vm.player_in_jail:
		ch_arr.insert(0, {"label": "💰 Ofrecerle %d de oro para que olvide tus cargos" % bribe_price(vm), "next": "END", "action": "town_bribe"})
	if law and int(npc.trade_role) == int(VillageNPC.TradeRole.SHERIFF) and bool(st.get("player_knows_embezzle", false)) and mayor_of(vm) != null:
		ch_arr.insert(0, {"label": "🏛️ Denunciar que el alcalde %s roba de las arcas" % st.get("mayor_name", ""), "next": "END", "action": "town_report_mayor"})
	if eligible(npc) and not VillageNeeds.is_outsider(npc):
		var cands: Array = candidates(vm)
		if not cands.is_empty():
			var opts: Array = []
			for c in cands:
				if c != npc:
					opts.append({"label": "🗳️ Que vote a %s" % c.npc_name, "next": "END", "action": "town_pledge:%s" % c.get_person_key()})
			if not opts.is_empty():
				opts.append({"label": "⬅️ Volver a la conversación", "next": "start"})
				var m = mayor_of(vm)
				var txt: String = "«El alcalde es %s. Próximas elecciones el día %d.»" % [m.npc_name if m != null else "nadie", int(st.get("next_election", 0))]
				ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🏛️ Hablar de las elecciones", "next": "town_vote"})
				diag["town_vote"] = {"text": txt, "choices": opts}

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	var st: Dictionary = state(vm)
	if action_id == "town_bribe":
		var price: int = bribe_price(vm)
		if inv == null or int(inv.gold) < price:
			npc._spawn_floating_text("«¿Con qué oro, forastero?»", Color.CORAL, -46.0)
			return
		if is_corrupt(npc):
			inv.add_gold(-price)
			npc.personal_gold += price
			st["bribes"] = int(st["bribes"]) + 1
			vm.clear_police_hostility()
			vm.wanted_level = 0
			vm.bounty_gold = 0
			VillageFaith.add_rep(vm, "law", -5)
			npc._spawn_floating_text("🤫 «Aquí no ha pasado nada.»", Color(1.0, 0.9, 0.5), -46.0)
			VillageChronicle.add(vm, "player_bribe", "Sobornaste a %s para que olvidara tus cargos" % npc.npc_name, true)
		else:
			npc.modify_affinity(-15)
			vm.bounty_gold += BRIBE_FAIL_FINE
			npc._spawn_floating_text("😠 «¿Intentas comprarme? La multa acaba de subir.»", Color.ORANGE_RED, -46.0)
	elif action_id == "town_report_mayor":
		if is_corrupt(npc):
			npc._spawn_floating_text("🤨 «Eso son habladurías. Déjalo estar.»", Color.ORANGE, -46.0)
			return
		st["player_knows_embezzle"] = false
		VillageFaith.add_rep(vm, "law", 6)
		npc._spawn_floating_text("🚓 «Lo investigaré. Si es verdad, lo pagará.»", Color(0.7, 0.85, 1.0), -46.0)
		expose(vm, "lo denunciaste tú al comisario")
	elif action_id.begins_with("town_pledge:"):
		var ck: String = action_id.get_slice(":", 1)
		if npc.affinity >= PLEDGE_MIN_AFF:
			st["pledges"][npc.get_person_key()] = ck
			npc._spawn_floating_text("🗳️ «Si tú lo dices, le votaré.»", Color(0.8, 0.95, 1.0), -46.0)
		elif is_corrupt(npc) and inv != null and int(inv.gold) >= VOTE_PRICE:
			inv.add_gold(-VOTE_PRICE)
			npc.personal_gold += VOTE_PRICE
			st["pledges"][npc.get_person_key()] = ck
			npc._spawn_floating_text("💰 «Por %d de oro, le voto a quien quieras.»" % VOTE_PRICE, Color(1.0, 0.9, 0.5), -46.0)
		else:
			npc._spawn_floating_text("«Votaré a quien me parezca.»", Color(0.85, 0.85, 0.85), -46.0)

## El jugador se entera del desfalco escuchando chismes.
static func on_player_news(vm, npc) -> void:
	if embezzle_knowers(vm).has(npc.get_person_key()):
		state(vm)["player_knows_embezzle"] = true

static func glossary_line(vm, npc) -> String:
	var parts: Array[String] = []
	if is_mayor(vm, npc):
		parts.append("🏛️ Alcalde del pueblo")
	var m = mayor_of(vm)
	parts.append("Alcalde: %s · Arcas: %d de oro · Próximas elecciones: día %d" % [m.npc_name if m != null else "nadie", int(state(vm)["treasury"]), int(state(vm).get("next_election", 0))])
	return "[color=#d6c2ff][b]🏛️ Pueblo:[/b][/color] " + "   ".join(parts)
