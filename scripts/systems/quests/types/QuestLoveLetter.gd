@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M12 «¿Me corresponde?»: alguien tímido te da una carta para quien le gusta. Distinto de «Averigua qué piensa»:
## aquí sí actúas. Si el otro ya sentía algo, la carta aviva la chispa; si no, le rechaza con amabilidad. Nunca se
## fuerza una pareja. Puedes también leerla (y saber algo de quien la escribió) o romperla.
## Toca la chispa de SocialDirector y los rasgos.

const PersonProfile = preload("res://scripts/data/PersonProfile.gd")
const TraitDiscovery = preload("res://scripts/systems/TraitDiscovery.gd")
const MIN_SPARK: int = 14
const OTHER_MIN_SPARK: int = 7
const LETTER_SPARK: int = 8

func _init() -> void:
	id = "love_letter"
	priority = 32
	gold = 15
	affinity = 12

func find_daily_offer(vm: VillageManager, giver: VillageNPC, npcs: Array, _ctx: Dictionary) -> Dictionary:
	var sd = vm.social_director
	if sd == null or giver.person_profile == null or str(giver.person_profile.romance_status) != PersonProfile.ROMANCE_SINGLE:
		return {}
	if not has_trait(giver, ["Tímido", "Romántico"]):
		return {}
	for other in npcs:
		if other == giver or other.is_dead or other.person_profile == null or str(other.person_profile.romance_status) != PersonProfile.ROMANCE_SINGLE:
			continue
		if sd.get_spark(giver.get_person_key(), other.get_person_key()) >= MIN_SPARK:
			return {"target_key": other.get_person_key(), "target_name": other.npc_name}
	return {}

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", ""))
	return {
		"title": "¿Me corresponde?",
		"ask": "«No me salen las palabras cuando %s me mira... Así que lo he escrito. ¿Se la darías tú? Y no la leas, ¿eh?»" % tn,
		"desc": "%s te ha dado una carta para %s. Entrégasela (💌) y vuelve con la respuesta. También podrías leerla... o romperla." % [str(off.get("giver_name", "")), tn],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, _off: Dictionary) -> Dictionary:
	return {"answer": "", "read": false}

func is_done(_vm: VillageManager, q: Dictionary) -> bool:
	return str(q["data"].get("answer", "")) != ""

func progress_hint(q: Dictionary) -> String:
	return "«¿Le has dado ya la carta a %s? ¿Qué cara puso?»" % str(q.get("target_name", ""))

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	if is_done(vm, q):
		return
	var qid: String = str(q["id"])
	if npc.get_person_key() == str(q.get("target_key", "")):
		ch_arr.insert(0, {"label": "💌 Darle la carta de %s" % str(q.get("giver_name", "")), "next": "END", "action": "quest_letter_give:" + qid})
		ch_arr.insert(1, {"label": "🔥 Guardarte la carta y romperla luego", "next": "END", "action": "quest_letter_tear:" + qid})
		if not bool(q["data"].get("read", false)):
			ch_arr.insert(2, {"label": "📖 (Antes de dársela) Leerla a escondidas", "next": "END", "action": "quest_letter_read:" + qid})

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if not action_id.begins_with("quest_letter_"):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	if q.is_empty():
		return true
	var giver: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("giver_key", "")), null)
	var sd = vm.social_director
	if action_id.begins_with("quest_letter_read:"):
		q["data"]["read"] = true
		if giver != null:
			TraitDiscovery.reveal_next(giver, "lo dejó ver en su carta")
		qm.add_note(str(q["id"]), "Leíste la carta. Habla de paseos junto al río y de lo mucho que le cuesta hablar.")
		return true
	if action_id.begins_with("quest_letter_tear:"):
		q["data"]["answer"] = "lost"
		qm.add_note(str(q["id"]), "Rompiste la carta. %s nunca la leerá." % str(q.get("target_name", "")))
		return true
	# Entregar: solo aviva lo que ya había
	var other_spark: int = sd.get_spark(npc.get_person_key(), str(q.get("giver_key", ""))) if sd != null else 0
	var rel: int = npc.get_relationship_with_npc(str(q.get("giver_key", "")))
	if other_spark >= OTHER_MIN_SPARK or (rel >= 25 and other_spark > 0):
		q["data"]["answer"] = "yes"
		if sd != null:
			sd.add_spark_one_way(npc.get_person_key(), str(q.get("giver_key", "")), LETTER_SPARK)
		npc._spawn_floating_text("😳 «¿Esto... lo ha escrito para mí? Dile que... que sí, que me gustaría dar ese paseo.»", Color(1.0, 0.75, 0.85), -46.0)
	else:
		q["data"]["answer"] = "no"
		npc._spawn_floating_text("😔 «Es muy bonito... pero yo no siento lo mismo. Díselo con cariño.»", Color(0.85, 0.85, 0.95), -46.0)
	qm.add_note(str(q["id"]), "Entregaste la carta a %s." % npc.npc_name)
	return true

func done_dialogue(_vm: VillageManager, q: Dictionary) -> Dictionary:
	var a: String = str(q["data"].get("answer", ""))
	var choices: Array = []
	if a == "yes":
		choices.append({"label": "💞 «Le ha gustado. Quiere dar ese paseo contigo.»", "next": "END", "action": "quest_turn_in:yes"})
	elif a == "no":
		choices.append({"label": "💔 La verdad, con tacto: «No siente lo mismo.»", "next": "END", "action": "quest_turn_in:no"})
		choices.append({"label": "🤥 Mentir: «Dice que quizá, que le des tiempo.»", "next": "END", "action": "quest_turn_in:maybe"})
	else:
		choices.append({"label": "🤷 «Se me perdió la carta... Lo siento.»", "next": "END", "action": "quest_turn_in:lost"})
	return {"text": "«¿Y bien? ¿Qué te ha dicho %s?»" % str(q.get("target_name", "")), "choices": choices}

func on_turn_in(vm: VillageManager, qm: Node, giver: VillageNPC, player: Node, q: Dictionary, action_full: String) -> void:
	var mode: String = action_full.get_slice(":", 1)
	var sd = vm.social_director
	match mode:
		"yes":
			giver.add_thought("¡Me corresponde! (+10)", 10.0)
			pay_and_complete(qm, giver, player, q, gold, affinity, "Le diste la buena noticia.")
		"no":
			giver.add_thought("No le gusto... al menos lo sé (-6)", -6.0)
			if sd != null:
				sd.add_spark_one_way(giver.get_person_key(), str(q.get("target_key", "")), -6)
			pay_and_complete(qm, giver, player, q, gold, int(float(affinity) / 2.0), "Le dijiste la verdad.")
		"maybe":
			giver.add_thought("Quizá... tengo que esperar (+3)", 3.0)
			pay_and_complete(qm, giver, player, q, gold, affinity, "Le diste falsas esperanzas.")
		_:
			giver.modify_affinity(-8)
			giver._spawn_floating_text("😞 «Vaya... era lo único que me atrevía a decir.»", Color(0.85, 0.85, 0.95), -46.0)
			qm.complete_quest(str(q["id"]), "La carta nunca llegó.")
