@tool
extends RefCounted

## Q2: Misiones secundarias que nacen de la vida social de los vecinos.
## Un vecino con una enemistad larga puede pedir ayuda al jugador (❗ sobre la cabeza). Se acepta o rechaza
## hablando con él, y se cobra volviendo a hablar con él cuando se ha conseguido.
## Tipos: "peace" (Haz las paces por mí) y "slander" (Ensúciale el nombre).

const OFFER_DAILY_CHANCE: float = 0.12 # Por vecino que cumple las condiciones, cada día
const MAX_OPEN_SOCIAL: int = 3 # Ofertas + misiones activas de vecinos a la vez
const OFFER_EXPIRE_DAYS: int = 4 # Si no le haces caso, se le pasa
const GIVER_COOLDOWN_DAYS: int = 10 # Tras rechazar, cobrar o fallar
const MIN_ENMITY_DAYS: int = 5
const ENMITY_REL: int = -30
const SLANDER_REL: int = -40
const PEACE_DONE_REL: int = -15 # El rival ya ve al que pidió ayuda así o mejor
const PEACE_DONE_GAIN: int = 12 # ...o ha mejorado al menos esto desde que aceptaste
const SLANDER_LISTENERS_NEEDED: int = 2
const SPITEFUL_TRAITS: Array[String] = ["Rencoroso", "Orgulloso", "Celoso", "Frío", "Codicioso"]
const PEACEFUL_TRAITS: Array[String] = ["Pacífico", "Bondadoso", "Leal", "Paciente", "Honrado", "Alegre"]

static func _qm(vm: Node) -> Node:
	return vm.get_node_or_null("/root/QuestManager")

static func _day() -> int:
	return int(WorldClock.current_day) if WorldClock else 1

static func _open_social_count(qm: Node) -> int:
	return qm.offers.size() + qm.get_active_quests("side").size()

static func _has_trait(npc: VillageNPC, traits: Array[String]) -> bool:
	if npc.person_profile == null:
		return false
	for t in npc.person_profile.personality:
		if str(t) in traits:
			return true
	return false

## Qué misión pediría `giver` sobre `rival`, o "" si ninguna.
static func pick_offer_type(vm: VillageManager, giver: VillageNPC, rival: VillageNPC) -> String:
	var rel: int = giver.get_relationship_with_npc(rival.get_person_key())
	if rel > ENMITY_REL:
		return ""
	var sd = vm.social_director
	var pe: Dictionary = sd.pair_metrics.get(sd.make_pair_key(giver.get_person_key(), rival.get_person_key()), {}) if sd != null else {}
	if int(pe.get("enmity_days", 0)) < MIN_ENMITY_DAYS and int(pe.get("fights_count", 0)) <= 0:
		return ""
	var spiteful: bool = _has_trait(giver, SPITEFUL_TRAITS)
	var peaceful: bool = _has_trait(giver, PEACEFUL_TRAITS)
	if spiteful and not peaceful:
		return "slander" if rel <= SLANDER_REL else ""
	if peaceful and not spiteful:
		return "peace"
	if rel <= SLANDER_REL and sd != null and sd.rng.randf() < 0.5:
		return "slander"
	return "peace"

static func _is_available_giver(vm: VillageManager, npc: VillageNPC) -> bool:
	return is_instance_valid(npc) and not npc.is_dead and not npc.is_downed and npc.trade_role != VillageNPC.TradeRole.ROYAL_INVESTIGATOR

## Una vez al día: caducan ofertas, fallan misiones imposibles y quizá algún vecino pide ayuda.
static func on_day_passed(vm: VillageManager, chance: float = OFFER_DAILY_CHANCE) -> void:
	var qm := _qm(vm)
	if qm == null:
		return
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var today: int = _day()
	for gk in qm.offers.keys().duplicate():
		var off: Dictionary = qm.offers[gk]
		var giver: VillageNPC = by_key.get(gk, null)
		var rival: VillageNPC = by_key.get(str(off.get("target_key", "")), null)
		if today - int(off.get("day_offered", today)) >= OFFER_EXPIRE_DAYS or not _is_available_giver(vm, giver) or rival == null or rival.is_dead:
			qm.remove_offer(gk)
	check_failures(vm)
	if _open_social_count(qm) >= MAX_OPEN_SOCIAL:
		return
	var npcs: Array = by_key.values()
	npcs.shuffle()
	for giver in npcs:
		if _open_social_count(qm) >= MAX_OPEN_SOCIAL:
			break
		var gk: String = giver.get_person_key()
		if not _is_available_giver(vm, giver) or qm.offers.has(gk) or not qm.get_active_quest_by_giver(gk).is_empty() or int(qm.giver_cooldowns.get(gk, -1)) > today:
			continue
		var best: VillageNPC = null
		var best_rel: int = 999
		for other in npcs:
			if other == giver or other.is_dead:
				continue
			var r: int = giver.get_relationship_with_npc(other.get_person_key())
			if r < best_rel:
				best_rel = r
				best = other
		if best == null:
			continue
		var t: String = pick_offer_type(vm, giver, best)
		if t == "" or vm.social_director == null or vm.social_director.rng.randf() >= chance:
			continue
		qm.set_offer(gk, {"type": t, "giver_name": giver.npc_name, "target_key": best.get_person_key(), "target_name": best.npc_name, "day_offered": today})

## Falla las misiones cuyo protagonista ha muerto.
static func check_failures(vm: VillageManager) -> void:
	var qm := _qm(vm)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for q in qm.get_active_quests("side"):
		if not str(q.get("type", "")) in ["peace", "slander"]:
			continue
		var giver: VillageNPC = by_key.get(str(q.get("giver_key", "")), null)
		var rival: VillageNPC = by_key.get(str(q.get("target_key", "")), null)
		if giver == null or giver.is_dead:
			qm.fail_quest(str(q["id"]), "%s ha muerto." % str(q.get("giver_name", "Quien te lo pidió")))
			qm.giver_cooldowns[str(q.get("giver_key", ""))] = _day() + GIVER_COOLDOWN_DAYS
		elif rival == null or rival.is_dead:
			qm.fail_quest(str(q["id"]), "%s ha muerto; ya no hay nada que hacer." % str(q.get("target_name", "El otro vecino")))
			qm.giver_cooldowns[str(q.get("giver_key", ""))] = _day() + GIVER_COOLDOWN_DAYS

static func _offer_texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", "ese vecino"))
	if str(off.get("type", "")) == "slander":
		return {
			"title": "Ensúciale el nombre a %s" % tn,
			"ask": "«Mira, no aguanto más a %s. Todo el pueblo le ríe las gracias... Si fueras contando por ahí lo que es de verdad, te lo pagaría bien.»" % tn,
			"desc": "%s quiere que hables mal de %s a otros vecinos (al menos %d distintos). Cuidado: los rumores corren y, si le pasa algo a %s, tendrás un móvil." % [str(off.get("giver_name", "")), tn, SLANDER_LISTENERS_NEEDED, tn],
		}
	return {
		"title": "Haz las paces por mí con %s" % tn,
		"ask": "«Llevo tiempo a malas con %s y ya no sé cómo arreglarlo. A mí no me escucha... ¿Hablarías tú con él/ella de mi parte?»" % tn,
		"desc": "%s quiere hacer las paces con %s. Habla con %s y pídele que le dé otra oportunidad (Opiniones de los vecinos → 🕊️). Puede hacer falta más de un intento." % [str(off.get("giver_name", "")), tn, tn],
	}

## Opciones de diálogo: oferta pendiente o misión en curso de este vecino.
static func add_quest_dialogue(vm: VillageManager, npc: VillageNPC, diag: Dictionary, ch_arr: Array) -> void:
	var qm := _qm(vm)
	if qm == null:
		return
	var gk: String = npc.get_person_key()
	if qm.offers.has(gk):
		var tx: Dictionary = _offer_texts(qm.offers[gk])
		ch_arr.insert(0, {"label": "❗ «Te noto preocupado. ¿Pasa algo?»", "next": "quest_offer"})
		diag["quest_offer"] = {"text": str(tx["ask"]), "choices": [
			{"label": "✅ «Cuenta conmigo.»", "next": "END", "action": "quest_accept"},
			{"label": "❌ «No es asunto mío.»", "next": "start", "action": "quest_decline"},
		]}
		return
	var q: Dictionary = qm.get_active_quest_by_giver(gk)
	if q.is_empty():
		return
	ch_arr.insert(0, {"label": "📜 Sobre lo que me pediste (%s)" % str(q.get("target_name", "")), "next": "quest_progress"})
	if is_quest_done(vm, q):
		diag["quest_progress"] = {"text": "«¿De verdad? ¡Gracias! Sabía que podía contar contigo.»", "choices": [{"label": "💰 Cobrar", "next": "END", "action": "quest_turn_in"}]}
	else:
		var hint: String = "«¿Has hablado ya con %s? Sigue igual conmigo...»" % str(q.get("target_name", "")) if str(q.get("type", "")) == "peace" else "«Todavía no he oído a nadie hablar mal de %s. Sigue en ello.»" % str(q.get("target_name", ""))
		diag["quest_progress"] = {"text": hint, "choices": [
			{"label": "⬅️ «Sigo en ello.»", "next": "start"},
			{"label": "🚫 «Lo dejo, no puedo hacerlo.»", "next": "start", "action": "quest_abandon"},
		]}

static func is_quest_done(vm: VillageManager, q: Dictionary) -> bool:
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var rival: VillageNPC = by_key.get(str(q.get("target_key", "")), null)
	if rival == null or rival.is_dead:
		return false
	var data: Dictionary = q.get("data", {})
	if str(q.get("type", "")) == "peace":
		var rel: int = rival.get_relationship_with_npc(str(q.get("giver_key", "")))
		return rel >= PEACE_DONE_REL or rel - int(data.get("start_rel", rel)) >= PEACE_DONE_GAIN
	if str(q.get("type", "")) == "slander":
		return (data.get("slandered_to", []) as Array).size() >= SLANDER_LISTENERS_NEEDED
	return false

## Acciones del diálogo. Devuelve true si la acción era de misiones.
static func on_dialogue_action(vm: VillageManager, npc: VillageNPC, player: Node, action_id: String) -> bool:
	var qm := _qm(vm)
	if qm == null or not action_id.begins_with("quest_"):
		return false
	var gk: String = npc.get_person_key()
	match action_id:
		"quest_accept":
			if not qm.offers.has(gk):
				return true
			var off: Dictionary = qm.offers[gk]
			var tx: Dictionary = _offer_texts(off)
			var rival: VillageNPC = vm._get_npcs_by_person_key().get(str(off.get("target_key", "")), null)
			var data: Dictionary = {"slandered_to": []}
			if rival != null:
				data["start_rel"] = rival.get_relationship_with_npc(gk)
			qm.remove_offer(gk)
			qm.add_quest({"category": "side", "type": str(off["type"]), "title": tx["title"], "description": tx["desc"],
				"giver_key": gk, "giver_name": npc.npc_name, "target_key": str(off.get("target_key", "")), "target_name": str(off.get("target_name", "")), "data": data})
			npc._spawn_floating_text("📜 Nueva misión: %s [L]" % str(tx["title"]), Color(1.0, 0.90, 0.58), -36.0)
		"quest_decline":
			qm.remove_offer(gk)
			qm.giver_cooldowns[gk] = _day() + GIVER_COOLDOWN_DAYS
			npc.modify_affinity(-2)
		"quest_abandon":
			var qa: Dictionary = qm.get_active_quest_by_giver(gk)
			if not qa.is_empty():
				qm.fail_quest(str(qa["id"]), "Lo dejaste.")
				qm.giver_cooldowns[gk] = _day() + GIVER_COOLDOWN_DAYS
				npc.modify_affinity(-5)
		"quest_turn_in":
			var qt: Dictionary = qm.get_active_quest_by_giver(gk)
			if qt.is_empty() or not is_quest_done(vm, qt):
				return true
			var gold: int = 30 if str(qt.get("type", "")) == "peace" else 25
			if player != null and "inventory" in player and player.inventory:
				player.inventory.add_gold(gold)
			npc.modify_affinity(15 if str(qt.get("type", "")) == "peace" else 12)
			qm.complete_quest(str(qt["id"]), "%s te pagó %d de oro." % [npc.npc_name, gold])
			qm.giver_cooldowns[gk] = _day() + GIVER_COOLDOWN_DAYS
			npc._spawn_floating_text("✅ Misión completada (+%d Oro)" % gold, Color.SPRING_GREEN, -36.0)
	return true

## Avisa a las misiones de lo que el jugador ha contado a un vecino (llamado tras convencerle).
static func on_player_influence(vm: VillageManager, listener: VillageNPC, target: VillageNPC, mode: String) -> void:
	var qm := _qm(vm)
	if qm == null:
		return
	var lk: String = listener.get_person_key()
	var tk: String = target.get_person_key()
	for q in qm.get_active_quests("side"):
		var t: String = str(q.get("type", ""))
		if t == "peace" and mode == "peace" and lk == str(q.get("target_key", "")) and tk == str(q.get("giver_key", "")):
			qm.add_note(str(q["id"]), "Convenciste a %s de darle otra oportunidad a %s." % [listener.npc_name, target.npc_name])
		elif t == "slander" and mode == "bad" and tk == str(q.get("target_key", "")) and lk != str(q.get("giver_key", "")):
			var lst: Array = q["data"].get("slandered_to", [])
			if not lk in lst:
				lst.append(lk)
				q["data"]["slandered_to"] = lst
				qm.add_note(str(q["id"]), "Hablaste mal de %s a %s (%d/%d)." % [target.npc_name, listener.npc_name, mini(lst.size(), SLANDER_LISTENERS_NEEDED), SLANDER_LISTENERS_NEEDED])

## ❗ sobre la cabeza de quien tiene algo que pedirte.
static func refresh_markers(vm: VillageManager) -> void:
	var qm := _qm(vm)
	if qm == null:
		return
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if not n is VillageNPC:
			continue
		var npc := n as VillageNPC
		var show: bool = qm.offers.has(npc.get_person_key()) and not npc.is_dead
		var mk: Label = npc.get_node_or_null("QuestMarker")
		if mk == null:
			if not show:
				continue
			mk = Label.new()
			mk.name = "QuestMarker"
			mk.text = "❗"
			mk.position = Vector2(-8, -58)
			mk.z_index = 21
			mk.add_theme_font_size_override("font_size", 14)
			mk.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			mk.add_theme_color_override("font_outline_color", Color.BLACK)
			mk.add_theme_constant_override("outline_size", 3)
			npc.add_child(mk)
		mk.visible = show
