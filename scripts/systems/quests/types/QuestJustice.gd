@tool
extends "res://scripts/systems/quests/QuestType.gd"

## «Encuentra a quien lo mató»: tras un asesinato, alguien muy cercano a la víctima pide justicia.
## Se crea al abrirse el caso (`on_case_opened`) y se resuelve con el veredicto (`on_case_resolved`).

const OFFER_CHANCE: float = 0.6
const MIN_REL: int = 40 # Cercanía con la víctima para pedir justicia

func _init() -> void:
	id = "justice"
	trigger = "event"
	gold = 40
	affinity = 20
	needs_alive_target = false # El objetivo es la víctima

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", "la víctima"))
	return {
		"title": "Encuentra a quien mató a %s" % tn,
		"ask": "«No puedo dormir desde lo de %s. Alguien de este pueblo lo hizo y anda por ahí como si nada... Ayúdame a que pague por ello.»" % tn,
		"desc": "%s quiere que el asesino de %s sea juzgado. La misión se resuelve con el veredicto de la investigación; puedes aportar pistas, presionar a testigos... o dirigir las sospechas. Si te culpan a ti o el caso se archiva, fallará." % [str(off.get("giver_name", "")), tn],
	}

func is_done(_vm: VillageManager, q: Dictionary) -> bool:
	return str(q["data"].get("verdict", "")) != ""

func progress_hint(q: Dictionary) -> String:
	return "«¿Se sabe ya quién mató a %s?»" % str(q.get("target_name", ""))

func done_dialogue(_vm: VillageManager, q: Dictionary) -> Dictionary:
	return {"text": "«Al menos se ha hecho justicia por %s. Gracias.»" % str(q.get("target_name", "")), "choices": [{"label": "💰 Cobrar", "next": "END", "action": "quest_turn_in"}]}

## Devuelve la oferta para el vecino más cercano a la víctima, o {} (una sola vez por víctima).
func on_case_opened(vm: VillageManager, qm: Node, victim: VillageNPC, chance: float, is_available: Callable) -> Dictionary:
	var vkey: String = victim.get_person_key()
	var mark: String = "justice:" + vkey
	if qm.giver_cooldowns.has(mark):
		return {}
	qm.giver_cooldowns[mark] = 999999 # Un solo intento por víctima
	var best: VillageNPC = null
	var best_rel: int = MIN_REL - 1
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if not n is VillageNPC or n == victim:
			continue
		var g := n as VillageNPC
		var gk: String = g.get_person_key()
		if not bool(is_available.call(g)) or qm.offers.has(gk) or not qm.get_active_quest_by_giver(gk).is_empty():
			continue
		var r: int = g.get_relationship_with_npc(vkey)
		if r > best_rel:
			best_rel = r
			best = g
	if best == null or vm.social_director == null or vm.social_director.rng.randf() >= chance:
		return {}
	return {"giver": best, "target_key": vkey, "target_name": victim.npc_name}

func on_case_resolved(qm: Node, victim_name: String, note: String) -> void:
	for gk in qm.offers.keys().duplicate():
		if str(qm.offers[gk].get("type", "")) == id and str(qm.offers[gk].get("target_name", "")) == victim_name:
			qm.remove_offer(gk)
	for q in qm.get_active_quests("side"):
		if str(q.get("type", "")) != id or str(q.get("target_name", "")) != victim_name:
			continue
		if note.begins_with("Jugador"):
			qm.fail_quest(str(q["id"]), "Te declararon culpable a ti de la muerte de %s." % victim_name)
		elif note.contains("Archivado") or note.contains("Fianza") or note.contains("Indult"):
			qm.fail_quest(str(q["id"]), "El caso se cerró sin culpable: %s." % note)
		else:
			q["data"]["verdict"] = note
			qm.add_note(str(q["id"]), "Veredicto: %s. Vuelve con %s." % [note, str(q.get("giver_name", ""))])
