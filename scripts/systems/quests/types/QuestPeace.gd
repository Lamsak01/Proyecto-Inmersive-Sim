@tool
extends "res://scripts/systems/quests/QuestType.gd"

## «Haz las paces por mí»: un vecino pacífico enemistado pide que convenzas a su rival.

const DONE_REL: int = -15 # El rival ya ve al que pidió ayuda así o mejor
const DONE_GAIN: int = 12 # ...o ha mejorado al menos esto desde que aceptaste

func _init() -> void:
	id = "peace"
	priority = 10
	gold = 30
	affinity = 15

func find_daily_offer(_vm: VillageManager, _giver: VillageNPC, _npcs: Array, ctx: Dictionary) -> Dictionary:
	if str(ctx.get("enmity_choice", "")) != "peace":
		return {}
	var rival: VillageNPC = ctx["worst"]
	return {"target_key": rival.get_person_key(), "target_name": rival.npc_name}

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", "ese vecino"))
	return {
		"title": "Haz las paces por mí con %s" % tn,
		"ask": "«Llevo tiempo a malas con %s y ya no sé cómo arreglarlo. A mí no me escucha... ¿Hablarías tú con él/ella de mi parte?»" % tn,
		"desc": "%s quiere hacer las paces con %s. Habla con %s y pídele que le dé otra oportunidad (Opiniones de los vecinos → 🕊️). Puede hacer falta más de un intento." % [str(off.get("giver_name", "")), tn, tn],
	}

func init_data(vm: VillageManager, giver: VillageNPC, off: Dictionary) -> Dictionary:
	var rival: VillageNPC = vm._get_npcs_by_person_key().get(str(off.get("target_key", "")), null)
	return {"start_rel": rival.get_relationship_with_npc(giver.get_person_key())} if rival != null else {}

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	var rival: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("target_key", "")), null)
	if rival == null or rival.is_dead:
		return false
	var rel: int = rival.get_relationship_with_npc(str(q.get("giver_key", "")))
	return rel >= DONE_REL or rel - int(q["data"].get("start_rel", rel)) >= DONE_GAIN

func progress_hint(q: Dictionary) -> String:
	return "«¿Has hablado ya con %s? Sigue igual conmigo...»" % str(q.get("target_name", ""))

func on_player_influence(_vm: VillageManager, qm: Node, q: Dictionary, listener: VillageNPC, target: VillageNPC, mode: String) -> void:
	if mode == "peace" and listener.get_person_key() == str(q.get("target_key", "")) and target.get_person_key() == str(q.get("giver_key", "")):
		qm.add_note(str(q["id"]), "Convenciste a %s de darle otra oportunidad a %s." % [listener.npc_name, target.npc_name])
