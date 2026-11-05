@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M19 «El forastero raro»: un vecino desconfiado no se fía de alguien recién llegado. Charlas con el forastero (🔎)
## y descubres sus rasgos. Al volver: lo defiendes (y quien desconfiaba se calma) o le das la razón y el pueblo le
## hace el vacío hasta que se marche. Toca las llegadas (VillageMigration) y el descubrimiento de rasgos.

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageMigration = preload("res://scripts/systems/VillageMigration.gd")
const TraitDiscovery = preload("res://scripts/systems/TraitDiscovery.gd")
const RECENT_DAYS: int = 6
const TRAITS_NEEDED: int = 2

func _init() -> void:
	id = "strange_newcomer"
	priority = 34
	gold = 15
	affinity = 10

func find_daily_offer(_vm: VillageManager, giver: VillageNPC, npcs: Array, _ctx: Dictionary) -> Dictionary:
	if giver.has_meta("arrived_day") or VillageNeeds.is_outsider(giver):
		return {}
	var wary: bool = has_trait(giver, ["Desconfiado"])
	for n in npcs:
		if n == giver or n.is_dead or not n.has_meta("arrived_day") or day() - int(n.get_meta("arrived_day")) > RECENT_DAYS:
			continue
		if TraitDiscovery.unknown_traits(n).size() < TRAITS_NEEDED:
			continue
		if wary or giver.get_relationship_with_npc(n.get_person_key()) <= -10:
			return {"target_key": n.get_person_key(), "target_name": n.npc_name}
	return {}

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", ""))
	return {
		"title": "El forastero raro",
		"ask": "«Ese %s que acaba de llegar... no me gusta. Nadie sabe de dónde viene ni por qué. Averigua quién es de verdad.»" % tn,
		"desc": "%s desconfía de %s, recién llegado/a al valle. Charla con %s (🔎) hasta conocer %d rasgos suyos. Luego decide: defenderle o darle la razón a %s." % [str(off.get("giver_name", "")), tn, tn, TRAITS_NEEDED, str(off.get("giver_name", ""))],
	}

func init_data(vm: VillageManager, _giver: VillageNPC, off: Dictionary) -> Dictionary:
	var t: VillageNPC = vm._get_npcs_by_person_key().get(str(off.get("target_key", "")), null)
	return {"found": 0, "talk_day": -1, "start_known": t.known_traits.size() if t != null else 0}

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	var t: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("target_key", "")), null)
	var gained: int = (t.known_traits.size() - int(q["data"].get("start_known", t.known_traits.size()))) if t != null else 0
	return int(q["data"].get("found", 0)) >= TRAITS_NEEDED or gained >= TRAITS_NEEDED or (t != null and TraitDiscovery.unknown_traits(t).is_empty())

func progress_hint(q: Dictionary) -> String:
	return "«¿Qué has sacado de %s? Yo sigo sin fiarme.»" % str(q.get("target_name", ""))

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	if is_done(vm, q) or npc.get_person_key() != str(q.get("target_key", "")) or int(q["data"].get("talk_day", -1)) == day():
		return
	ch_arr.insert(0, {"label": "🔎 Charlar con calma: de dónde viene y qué busca aquí", "next": "END", "action": "quest_stranger_talk:" + str(q["id"])})

func on_extra_action(_vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if not action_id.begins_with("quest_stranger_talk:"):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	if q.is_empty():
		return true
	q["data"]["talk_day"] = day() # Una charla al día (dos si tienes Carisma)
	var n_reveal: int = 2 if charisma(player_of(npc)) >= 2 else 1
	for i in range(n_reveal):
		if TraitDiscovery.reveal_next(npc, "charlando con calma"):
			q["data"]["found"] = int(q["data"].get("found", 0)) + 1
	npc.modify_affinity(3)
	npc._spawn_floating_text("🙂 «Vengo de lejos. Buscaba un sitio tranquilo... ¿Por qué lo preguntas?»", Color(0.9, 0.9, 1.0), -46.0)
	qm.add_note(str(q["id"]), "Hablaste con %s: ya conoces %d de sus rasgos." % [npc.npc_name, int(q["data"]["found"])])
	return true

func done_dialogue(vm: VillageManager, q: Dictionary) -> Dictionary:
	var t: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("target_key", "")), null)
	var traits: String = TraitDiscovery.known_traits_text(t) if t != null else ""
	return {"text": "«¿Y bien? ¿Qué clase de persona es %s?»%s" % [str(q.get("target_name", "")), ("\n(Sabes: %s)" % traits) if traits != "" else ""], "choices": [
		{"label": "🛡️ Defenderle: «Es buena gente. Dale una oportunidad.»", "next": "END", "action": "quest_turn_in:defend"},
		{"label": "👉 Darle la razón: «Tienes razón, aquí no pinta nada.»", "next": "END", "action": "quest_turn_in:shun"},
	]}

func on_turn_in(vm: VillageManager, qm: Node, giver: VillageNPC, player: Node, q: Dictionary, action_full: String) -> void:
	var t: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("target_key", "")), null)
	if action_full.ends_with(":defend"):
		if t != null:
			giver.modify_npc_relationship(t, 15, "El forastero me habló bien de él/ella")
			t.modify_affinity(5)
		pay_and_complete(qm, giver, player, q, gold, int(float(affinity) / 2.0), "Defendiste a %s." % str(q.get("target_name", "")))
		return
	# El vacío: quien aprecia al que desconfiaba le imita; si no tiene casa ni lazos, acabará marchándose
	if t != null:
		for n in VillageNeeds.living(vm):
			if n != t and n != giver and n.get_relationship_with_npc(giver.get_person_key()) >= 20:
				n.modify_npc_relationship(t, -10, "Dicen que no es de fiar", true)
		giver.modify_npc_relationship(t, -10, "Ahora sé que no es de fiar", true)
		t.add_thought("En este pueblo me miran como a un apestado (-8)", -8.0)
		if VillageMigration.leave_chance(vm, t, -1.0) > 0.0:
			VillageMigration.start_leaving(vm, t)
	vm.VillageFaith.add_rep(vm, "poor", -2)
	pay_and_complete(qm, giver, player, q, gold, affinity, "Le diste la razón: %s no es bienvenido/a." % str(q.get("target_name", "")))
