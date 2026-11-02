@tool
extends RefCounted

## Misiones secundarias que nacen de la vida de los vecinos: reglas comunes a todos los tipos.
## Cada tipo vive en `scripts/systems/quests/types/` y se registra en `QuestRegistry.gd` (guía en `docs/MISIONES.md`).
## Ciclo: oferta (❗) → aceptar hablando → misión activa (panel L) → hecha → volver y cobrar. Falla si pasa algo en el mundo.

const QuestRegistry = preload("res://scripts/systems/quests/QuestRegistry.gd")

const OFFER_DAILY_CHANCE: float = 0.12 # Por vecino que tiene algo que pedir, cada día
const MAX_OPEN_SOCIAL: int = 3 # Ofertas + misiones activas de vecinos a la vez
const OFFER_EXPIRE_DAYS: int = 4 # Si no le haces caso, se le pasa
const GIVER_COOLDOWN_DAYS: int = 10 # Tras rechazar, cobrar o fallar
const MIN_ENMITY_DAYS: int = 5
const ENMITY_REL: int = -30
const SLANDER_REL: int = -40
const SPITEFUL_TRAITS: Array[String] = ["Rencoroso", "Orgulloso", "Celoso", "Frío", "Codicioso"]
const PEACEFUL_TRAITS: Array[String] = ["Pacífico", "Bondadoso", "Leal", "Paciente", "Honrado", "Alegre"]

static func _qm(vm: Node) -> Node:
	return vm.get_node_or_null("/root/QuestManager")

static func _day() -> int:
	return int(WorldClock.current_day) if WorldClock else 1

static func _open_social_count(qm: Node) -> int:
	return qm.offers.size() + qm.get_active_quests("side").size()

static func _is_available_giver(_vm: VillageManager, npc: VillageNPC) -> bool:
	return is_instance_valid(npc) and not npc.is_dead and not npc.is_downed and npc.trade_role != VillageNPC.TradeRole.ROYAL_INVESTIGATOR

static func _can_ask(qm: Node, npc: VillageNPC, today: int) -> bool:
	var gk: String = npc.get_person_key()
	return not qm.offers.has(gk) and qm.get_active_quest_by_giver(gk).is_empty() and int(qm.giver_cooldowns.get(gk, -1)) <= today

static func _set_offer(qm: Node, type_id: String, giver: VillageNPC, off: Dictionary) -> void:
	var o: Dictionary = off.duplicate()
	o.erase("giver")
	o["type"] = type_id
	o["giver_name"] = giver.npc_name
	o["day_offered"] = _day()
	qm.set_offer(giver.get_person_key(), o)

## Qué pediría `giver` por su enemistad con `rival`: "peace", "slander" o "" (lo comparten ambos tipos).
static func pick_offer_type(vm: VillageManager, giver: VillageNPC, rival: VillageNPC) -> String:
	var rel: int = giver.get_relationship_with_npc(rival.get_person_key())
	if rel > ENMITY_REL:
		return ""
	var sd = vm.social_director
	var pe: Dictionary = sd.pair_metrics.get(sd.make_pair_key(giver.get_person_key(), rival.get_person_key()), {}) if sd != null else {}
	if int(pe.get("enmity_days", 0)) < MIN_ENMITY_DAYS and int(pe.get("fights_count", 0)) <= 0:
		return ""
	var spiteful: bool = QuestRegistry.get_type("peace").has_trait(giver, SPITEFUL_TRAITS)
	var peaceful: bool = QuestRegistry.get_type("peace").has_trait(giver, PEACEFUL_TRAITS)
	if spiteful and not peaceful:
		return "slander" if rel <= SLANDER_REL else ""
	if peaceful and not spiteful:
		return "peace"
	if rel <= SLANDER_REL and sd != null and sd.rng.randf() < 0.5:
		return "slander"
	return "peace"

## Cálculos que comparten varios tipos en el sorteo diario (se hacen una vez por vecino).
static func _build_ctx(vm: VillageManager, giver: VillageNPC, npcs: Array) -> Dictionary:
	var worst: VillageNPC = null
	var worst_rel: int = 999
	for other in npcs:
		if other == giver or other.is_dead:
			continue
		var r: int = giver.get_relationship_with_npc(other.get_person_key())
		if r < worst_rel:
			worst_rel = r
			worst = other
	return {"worst": worst, "enmity_choice": pick_offer_type(vm, giver, worst) if worst != null else ""}

## Una vez al día: caducan ofertas, fallan misiones imposibles y quizá algún vecino pide ayuda.
static func on_day_passed(vm: VillageManager, chance: float = OFFER_DAILY_CHANCE) -> void:
	var qm := _qm(vm)
	if qm == null:
		return
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var today: int = _day()
	for gk in qm.offers.keys().duplicate():
		var off: Dictionary = qm.offers[gk]
		var qt = QuestRegistry.get_type(str(off.get("type", "")))
		var tgt: VillageNPC = by_key.get(str(off.get("target_key", "")), null)
		var target_gone: bool = qt == null or (qt.needs_alive_target and (tgt == null or tgt.is_dead))
		var expired: bool = today - int(off.get("day_offered", today)) >= OFFER_EXPIRE_DAYS
		if expired or not _is_available_giver(vm, by_key.get(gk, null)) or target_gone:
			qm.remove_offer(gk)
			if expired:
				qm.giver_cooldowns[gk] = today + GIVER_COOLDOWN_DAYS # Se le pasó; no lo vuelve a pedir enseguida
	check_failures(vm)
	if vm.social_director == null:
		return
	var npcs: Array = by_key.values()
	npcs.shuffle()
	for giver in npcs:
		if _open_social_count(qm) >= MAX_OPEN_SOCIAL:
			break
		if not _is_available_giver(vm, giver) or not _can_ask(qm, giver, today):
			continue
		var ctx: Dictionary = _build_ctx(vm, giver, npcs)
		for qt in QuestRegistry.daily_types():
			var off: Dictionary = qt.find_daily_offer(vm, giver, npcs, ctx)
			if off.is_empty():
				continue
			if vm.social_director.rng.randf() < chance:
				_set_offer(qm, qt.id, giver, off)
			break

## Falla las misiones que ya no pueden cumplirse (cada tipo decide por qué).
static func check_failures(vm: VillageManager) -> void:
	var qm := _qm(vm)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for q in qm.get_active_quests("side"):
		var qt = QuestRegistry.get_type(str(q.get("type", "")))
		if qt == null:
			continue
		var reason: String = qt.failure_reason(vm, q, by_key)
		if reason != "":
			qm.fail_quest(str(q["id"]), reason)
			qm.giver_cooldowns[str(q.get("giver_key", ""))] = _day() + GIVER_COOLDOWN_DAYS

# --- Sucesos del mundo que crean o resuelven misiones ----------------------------------------

## Al abrirse un caso de asesinato (VillageJustice): alguien cercano a la víctima puede pedir justicia.
static func on_murder_case_opened(vm: VillageManager, victim: VillageNPC, chance: float = -1.0) -> void:
	var qm := _qm(vm)
	var qt = QuestRegistry.get_type("justice")
	if qm == null or victim == null or qt == null:
		return
	var off: Dictionary = qt.on_case_opened(vm, qm, victim, qt.OFFER_CHANCE if chance < 0.0 else chance, func(n): return _is_available_giver(vm, n))
	if not off.is_empty():
		_set_offer(qm, "justice", off["giver"], off)

## Al cerrarse un caso (VillageManager._mark_morgue_case_resolved).
static func on_case_resolved(vm: VillageManager, victim_name: String, note: String) -> void:
	var qm := _qm(vm)
	var qt = QuestRegistry.get_type("justice")
	if qm == null or qt == null:
		return
	var before: Dictionary = {}
	for q in qm.get_active_quests("side"):
		before[str(q["id"])] = str(q.get("giver_key", ""))
	qt.on_case_resolved(qm, victim_name, note)
	for qid in before.keys():
		if str(qm.get_quest(qid).get("status", "")) == "failed":
			qm.giver_cooldowns[before[qid]] = _day() + GIVER_COOLDOWN_DAYS

## Una calumnia le llega al afectado de segunda mano (VillageSocialLife).
static func on_rumor_reached_target(vm: VillageManager, ev: Dictionary, teller: VillageNPC, listener: VillageNPC, chance: float = -1.0) -> void:
	var qm := _qm(vm)
	var qt = QuestRegistry.get_type("rumor")
	if qm == null or qt == null or not _is_available_giver(vm, listener) or not _can_ask(qm, listener, _day()):
		return
	if _open_social_count(qm) >= MAX_OPEN_SOCIAL or vm.social_director == null or vm.social_director.rng.randf() >= (qt.OFFER_CHANCE if chance < 0.0 else chance):
		return
	_set_offer(qm, "rumor", listener, qt.make_offer(ev, teller))

## El jugador acaba de convencer a un vecino de algo (NPCDialogue._player_gossip).
static func on_player_influence(vm: VillageManager, listener: VillageNPC, target: VillageNPC, mode: String) -> void:
	var qm := _qm(vm)
	if qm == null:
		return
	for q in qm.get_active_quests("side"):
		var qt = QuestRegistry.get_type(str(q.get("type", "")))
		if qt != null:
			qt.on_player_influence(vm, qm, q, listener, target, mode)

# --- Diálogo ---------------------------------------------------------------------------------

static func is_quest_done(vm: VillageManager, q: Dictionary) -> bool:
	var qt = QuestRegistry.get_type(str(q.get("type", "")))
	return qt != null and qt.is_done(vm, q)

## Opciones de diálogo: preguntas de misiones ajenas, oferta pendiente o misión en curso de este vecino.
static func add_quest_dialogue(vm: VillageManager, npc: VillageNPC, diag: Dictionary, ch_arr: Array) -> void:
	var qm := _qm(vm)
	if qm == null:
		return
	for oq in qm.get_active_quests("side"):
		var oqt = QuestRegistry.get_type(str(oq.get("type", "")))
		if oqt != null:
			oqt.add_world_dialogue(vm, npc, oq, diag, ch_arr)
	var gk: String = npc.get_person_key()
	if qm.offers.has(gk):
		var off_t = QuestRegistry.get_type(str(qm.offers[gk].get("type", "")))
		if off_t == null:
			return
		ch_arr.insert(0, {"label": "❗ «Te noto preocupado. ¿Pasa algo?»", "next": "quest_offer"})
		diag["quest_offer"] = {"text": str(off_t.texts(qm.offers[gk])["ask"]), "choices": [
			{"label": "✅ «Cuenta conmigo.»", "next": "END", "action": "quest_accept"},
			{"label": "❌ «No es asunto mío.»", "next": "start", "action": "quest_decline"},
		]}
		return
	var q: Dictionary = qm.get_active_quest_by_giver(gk)
	var qt = QuestRegistry.get_type(str(q.get("type", ""))) if not q.is_empty() else null
	if qt == null:
		return
	ch_arr.insert(0, {"label": "📜 Sobre lo que me pediste (%s)" % (str(q.get("target_name", "")) if str(q.get("target_name", "")) != "" else str(q.get("title", ""))), "next": "quest_progress"})
	if qt.is_done(vm, q):
		diag["quest_progress"] = qt.done_dialogue(vm, q)
	else:
		diag["quest_progress"] = {"text": qt.progress_hint(q), "choices": [
			{"label": "⬅️ «Sigo en ello.»", "next": "start"},
			{"label": "🚫 «Lo dejo, no puedo hacerlo.»", "next": "start", "action": "quest_abandon"},
		]}

## Acciones del diálogo. Devuelve true si la acción era de misiones.
static func on_dialogue_action(vm: VillageManager, npc: VillageNPC, player: Node, action_id: String) -> bool:
	var qm := _qm(vm)
	if qm == null or not action_id.begins_with("quest_"):
		return false
	var gk: String = npc.get_person_key()
	if action_id == "quest_accept":
		if not qm.offers.has(gk):
			return true
		var off: Dictionary = qm.offers[gk]
		var at = QuestRegistry.get_type(str(off.get("type", "")))
		if at == null:
			qm.remove_offer(gk)
			return true
		var tx: Dictionary = at.texts(off)
		var data: Dictionary = at.init_data(vm, npc, off)
		qm.remove_offer(gk)
		qm.add_quest({"category": "side", "type": at.id, "title": tx["title"], "description": tx["desc"],
			"giver_key": gk, "giver_name": npc.npc_name, "target_key": str(off.get("target_key", "")), "target_name": str(off.get("target_name", "")), "data": data})
		npc._spawn_floating_text("📜 Nueva misión: %s [L]" % str(tx["title"]), Color(1.0, 0.90, 0.58), -36.0)
		return true
	if action_id == "quest_decline":
		qm.remove_offer(gk)
		qm.giver_cooldowns[gk] = _day() + GIVER_COOLDOWN_DAYS
		npc.modify_affinity(-2)
		return true
	if action_id == "quest_abandon":
		var qa: Dictionary = qm.get_active_quest_by_giver(gk)
		if not qa.is_empty():
			qm.fail_quest(str(qa["id"]), "Lo dejaste.")
			qm.giver_cooldowns[gk] = _day() + GIVER_COOLDOWN_DAYS
			npc.modify_affinity(-5)
		return true
	if action_id.begins_with("quest_turn_in"):
		var qt_q: Dictionary = qm.get_active_quest_by_giver(gk)
		var tt = QuestRegistry.get_type(str(qt_q.get("type", ""))) if not qt_q.is_empty() else null
		if tt == null or not tt.is_done(vm, qt_q):
			return true
		tt.on_turn_in(vm, qm, npc, player, qt_q, action_id)
		if str(qm.get_quest(str(qt_q["id"])).get("status", "")) != "active":
			qm.giver_cooldowns[gk] = _day() + GIVER_COOLDOWN_DAYS
		return true
	for qt in QuestRegistry.all_types():
		if qt.on_extra_action(vm, qm, npc, action_id):
			return true
	return true

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
