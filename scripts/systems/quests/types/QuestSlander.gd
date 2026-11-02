@tool
extends "res://scripts/systems/quests/QuestType.gd"

## «Ensúciale el nombre»: un vecino rencoroso pide que hables mal de su rival a otros vecinos.

const LISTENERS_NEEDED: int = 2

func _init() -> void:
	id = "slander"
	priority = 10
	gold = 25
	affinity = 12

func find_daily_offer(_vm: VillageManager, _giver: VillageNPC, _npcs: Array, ctx: Dictionary) -> Dictionary:
	if str(ctx.get("enmity_choice", "")) != "slander":
		return {}
	var rival: VillageNPC = ctx["worst"]
	return {"target_key": rival.get_person_key(), "target_name": rival.npc_name}

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", "ese vecino"))
	return {
		"title": "Ensúciale el nombre a %s" % tn,
		"ask": "«Mira, no aguanto más a %s. Todo el pueblo le ríe las gracias... Si fueras contando por ahí lo que es de verdad, te lo pagaría bien.»" % tn,
		"desc": "%s quiere que hables mal de %s a otros vecinos (al menos %d distintos). Cuidado: los rumores corren y, si le pasa algo a %s, tendrás un móvil." % [str(off.get("giver_name", "")), tn, LISTENERS_NEEDED, tn],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, _off: Dictionary) -> Dictionary:
	return {"slandered_to": []}

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	var rival: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("target_key", "")), null)
	return rival != null and not rival.is_dead and (q["data"].get("slandered_to", []) as Array).size() >= LISTENERS_NEEDED

func progress_hint(q: Dictionary) -> String:
	return "«Todavía no he oído a nadie hablar mal de %s. Sigue en ello.»" % str(q.get("target_name", ""))

func on_player_influence(_vm: VillageManager, qm: Node, q: Dictionary, listener: VillageNPC, target: VillageNPC, mode: String) -> void:
	var lk: String = listener.get_person_key()
	if mode != "bad" or target.get_person_key() != str(q.get("target_key", "")) or lk == str(q.get("giver_key", "")):
		return
	var lst: Array = q["data"].get("slandered_to", [])
	if lk in lst:
		return
	lst.append(lk)
	q["data"]["slandered_to"] = lst
	qm.add_note(str(q["id"]), "Hablaste mal de %s a %s (%d/%d)." % [target.npc_name, listener.npc_name, mini(lst.size(), LISTENERS_NEEDED), LISTENERS_NEEDED])
