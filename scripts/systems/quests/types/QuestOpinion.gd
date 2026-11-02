@tool
extends "res://scripts/systems/quests/QuestType.gd"

## «Averigua qué piensa de mí»: alguien con chispa hacia otro soltero quiere saber qué opina de él/ella.
## Solo información: lo que le cuentes puede apagarle la ilusión, nunca crear una pareja.

const PersonProfile = preload("res://scripts/data/PersonProfile.gd")
const MIN_SPARK: int = 14 # Igual que la etapa "interés"

func _init() -> void:
	id = "opinion"
	priority = 30
	gold = 20
	affinity = 8

func find_daily_offer(vm: VillageManager, giver: VillageNPC, npcs: Array, _ctx: Dictionary) -> Dictionary:
	var sd = vm.social_director
	if sd == null or giver.person_profile == null or str(giver.person_profile.romance_status) != PersonProfile.ROMANCE_SINGLE:
		return {}
	var best: VillageNPC = null
	var best_spark: int = MIN_SPARK - 1
	for other in npcs:
		if other == giver or other.is_dead or other.person_profile == null or str(other.person_profile.romance_status) != PersonProfile.ROMANCE_SINGLE:
			continue
		var pe: Dictionary = sd.pair_metrics.get(sd.make_pair_key(giver.get_person_key(), other.get_person_key()), {})
		if str(pe.get("stage", "none")) in ["none", "interest"] and int(pe.get("spark", 0)) > best_spark:
			best_spark = int(pe.get("spark", 0))
			best = other
	return {"target_key": best.get_person_key(), "target_name": best.npc_name} if best != null else {}

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", "ese vecino"))
	return {
		"title": "Averigua qué piensa %s" % tn,
		"ask": "«Esto es un poco embarazoso... ¿Podrías averiguar qué piensa %s de mí? Sin que se note que te lo he pedido, por favor.»" % tn,
		"desc": "%s quiere saber qué opina %s de él/ella. Habla con %s y pregúntale qué opina de los vecinos; luego vuelve y cuéntaselo (o no)." % [str(off.get("giver_name", "")), tn, tn],
	}

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	var tgt: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("target_key", "")), null)
	return tgt != null and not tgt.is_dead and q["data"].has("learned_rel")

func progress_hint(q: Dictionary) -> String:
	return "«¿Has podido hablar con %s? No le digas que te lo pedí yo...»" % str(q.get("target_name", ""))

static func describe_answer(rel: int) -> String:
	if rel >= 40: return "Habla muy bien de ti."
	if rel >= 15: return "Le caes bien."
	if rel > -15: return "Le eres indiferente."
	return "No le caes nada bien."

func done_dialogue(_vm: VillageManager, q: Dictionary) -> Dictionary:
	var truth: String = describe_answer(int(q["data"].get("learned_rel", 0)))
	return {"text": "«¿Y bien? ¿Qué te dijo %s?»" % str(q.get("target_name", "")), "choices": [
		{"label": "🗣️ La verdad: «%s»" % truth, "next": "END", "action": "quest_turn_in:truth"},
		{"label": "😊 Mentir: «Le caes muy bien.»", "next": "END", "action": "quest_turn_in:lie_good"},
		{"label": "😞 Mentir: «No le interesas.»", "next": "END", "action": "quest_turn_in:lie_bad"},
	]}

func on_turn_in(vm: VillageManager, qm: Node, giver: VillageNPC, player: Node, q: Dictionary, action_full: String) -> void:
	var mode: String = action_full.get_slice(":", 1) if action_full.contains(":") else "truth"
	q["data"]["told"] = mode
	var told_bad: bool = mode == "lie_bad" or (mode == "truth" and int(q["data"].get("learned_rel", 0)) < 0)
	if told_bad and vm.social_director != null:
		var pe: Dictionary = vm.social_director.get_pair_entry(giver.get_person_key(), str(q.get("target_key", "")))
		if not pe.is_empty():
			pe["spark"] = maxi(0, int(pe.get("spark", 0)) - 6)
		giver._spawn_floating_text("💔 %s se queda cabizbajo/a" % giver.npc_name, Color(0.75, 0.80, 1.0), -46.0)
	pay_and_complete(qm, giver, player, q, gold, affinity)

## Acción del menú de opiniones: "quest_opinion_seen:<clave de quien preguntas>" (la añade NPCDialogue).
func on_extra_action(_vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if not action_id.begins_with("quest_opinion_seen:"):
		return false
	var about_key: String = action_id.get_slice(":", 1)
	for q in qm.get_active_quests("side"):
		if str(q.get("type", "")) == id and str(q.get("target_key", "")) == npc.get_person_key() and str(q.get("giver_key", "")) == about_key and not q["data"].has("learned_rel"):
			var rel: int = npc.get_relationship_with_npc(about_key)
			q["data"]["learned_rel"] = rel
			qm.add_note(str(q["id"]), "%s: «%s». Vuelve con %s." % [npc.npc_name, describe_answer(rel), str(q.get("giver_name", ""))])
	return true
