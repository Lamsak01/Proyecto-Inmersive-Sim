@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M10 «El testigo con miedo»: quien halló el cadáver del caso abierto teme ser el siguiente. Pides al comisario
## que le proteja (🛡️): el testigo se calma y recuerda algo más, que va al expediente y apunta al asesino real.
## Toca VillageJustice (expediente del comisario, sospechosos) y VillageDesires (quién mató de verdad).

const VillageDesires = preload("res://scripts/systems/VillageDesires.gd")
const SUSPECT_BOOST: int = 15

func _init() -> void:
	id = "scared_witness"
	priority = 5
	gold = 15
	affinity = 18
	needs_alive_target = false

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	var inv: Dictionary = vm.active_sheriff_investigation
	if not bool(inv.get("active", false)) or str(inv.get("reporter_name", "")) != giver.npc_name:
		return {}
	return {"target_key": "", "target_name": str(inv.get("victim_name", "")), "victim": str(inv.get("victim_name", ""))}

func texts(off: Dictionary) -> Dictionary:
	var vn: String = str(off.get("target_name", ""))
	return {
		"title": "El testigo con miedo",
		"ask": "«Fui yo quien encontró a %s... Desde entonces no duermo. Si el que lo hizo sabe que hablé, voy yo detrás. ¿Puedes pedirle al alguacil que me proteja?»" % vn,
		"desc": "%s halló el cuerpo de %s y teme por su vida. Pide protección al alguacil (🛡️ en su diálogo). Más tranquilo/a, quizá recuerde algo." % [str(off.get("giver_name", "")), vn],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, off: Dictionary) -> Dictionary:
	return {"victim": str(off.get("victim", "")), "protected": false}

func is_done(_vm: VillageManager, q: Dictionary) -> bool:
	return bool(q["data"].get("protected", false))

func progress_hint(_q: Dictionary) -> String:
	return "«¿Has hablado con el alguacil? Cada ruido de noche me parece un paso...»"

func failure_reason(vm: VillageManager, q: Dictionary, by_key: Dictionary) -> String:
	var base: String = super.failure_reason(vm, q, by_key)
	if base != "" or is_done(vm, q):
		return base
	var inv: Dictionary = vm.active_sheriff_investigation
	if not bool(inv.get("active", false)) or str(inv.get("victim_name", "")) != str(q["data"].get("victim", "")):
		return "El caso de %s ya se cerró." % str(q["data"].get("victim", ""))
	return ""

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	if int(npc.trade_role) != int(VillageNPC.TradeRole.SHERIFF) or is_done(vm, q):
		return
	ch_arr.insert(0, {"label": "🛡️ Pedir protección para %s, el/la testigo" % str(q.get("giver_name", "")), "next": "END", "action": "quest_witness_protect:" + str(q["id"])})

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if not action_id.begins_with("quest_witness_protect:"):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	if q.is_empty():
		return true
	q["data"]["protected"] = true
	var inv: Dictionary = vm.active_sheriff_investigation
	var gn: String = str(q.get("giver_name", ""))
	var killer: String = VillageDesires.killer_of(vm, str(q["data"].get("victim", "")))
	var clue: String
	if killer != "" and (inv.get("suspects", {}) as Dictionary).has(killer):
		var s: Dictionary = inv["suspects"][killer]
		s["score"] = int(s.get("score", 10)) + SUSPECT_BOOST
		clue = "%s, ya bajo protección, recordó haber visto a %s rondando por allí aquella noche." % [gn, killer]
	else:
		clue = "%s, ya bajo protección, confirmó la hora del hallazgo, pero no vio a nadie más." % gn
	if inv.has("clues_log"):
		(inv["clues_log"] as Array).append(clue)
	qm.add_note(str(q["id"]), clue)
	npc._spawn_floating_text("🛡️ «Pondré un guardia cerca de su casa. Y dile que venga a contarme lo que sepa.»", Color(0.7, 0.85, 1.0), -46.0)
	return true

func done_dialogue(_vm: VillageManager, _q: Dictionary) -> Dictionary:
	return {"text": "«Gracias... ya respiro mejor. Y he recordado algo; se lo he contado al alguacil.»", "choices": [{"label": "💰 Cobrar", "next": "END", "action": "quest_turn_in"}]}
