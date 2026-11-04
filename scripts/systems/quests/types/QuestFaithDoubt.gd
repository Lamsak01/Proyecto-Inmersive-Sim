@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M7 «Fe que tambalea»: el sacerdote te pide que traigas al Oficio a un vecino tibio. Le invitas (⛪) y tiene
## que venir de verdad el domingo. Toca VillageFaith (grados de fe, asistencia, `rite_invited_week`).

const VillageFaith = preload("res://scripts/systems/VillageFaith.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")

func _init() -> void:
	id = "faith_doubt"
	priority = 35
	gold = 15
	affinity = 12

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	if not VillageFaith.is_priest(giver):
		return {}
	var pool: Array = []
	for n in VillageNeeds.living(vm):
		if n != giver and not VillageNeeds.is_outsider(n) and VillageFaith.grade_of(n) == VillageFaith.GRADE_LUKEWARM:
			pool.append(n)
	if pool.is_empty():
		return {}
	var t = pool[randi() % pool.size()]
	return {"target_key": t.get_person_key(), "target_name": t.npc_name}

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", ""))
	return {
		"title": "Fe que tambalea",
		"ask": "«%s ya casi no viene al Oficio. No le pido que sea un santo... solo que vuelva un domingo. A ti te escuchará.»" % tn,
		"desc": "%s quiere que %s vuelva al Oficio. Invítale (⛪ en su diálogo; ayuda que te aprecie o el Carisma) y que venga de verdad el domingo." % [str(off.get("giver_name", "")), tn],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, _off: Dictionary) -> Dictionary:
	return {"invited_week": -1, "came": false}

## Semana del próximo Oficio: si hoy ya acabó, la que viene.
static func next_rite_week() -> int:
	var w: int = VillageFaith._week()
	if VillageFaith.is_rite_day() and WorldClock and int(WorldClock.current_hour) >= VillageFaith.RITE_END_HOUR:
		w += 1
	return w

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	if bool(q["data"].get("came", false)):
		return true
	var wk: int = int(q["data"].get("invited_week", -1))
	if wk < 0:
		return false
	var st: Dictionary = VillageFaith._state(vm)
	if int(float(int(st.get("last_rite_day", -1)) - 1) / 7.0) == wk and (st.get("last_attendees", []) as Array).has(str(q.get("target_key", ""))):
		q["data"]["came"] = true
	return bool(q["data"].get("came", false))

func progress_hint(q: Dictionary) -> String:
	if int(q["data"].get("invited_week", -1)) >= 0:
		return "«Dices que vendrá el domingo... Ya veremos. Rezaré para que así sea.»"
	return "«¿Has hablado ya con %s?»" % str(q.get("target_name", ""))

func failure_reason(vm: VillageManager, q: Dictionary, by_key: Dictionary) -> String:
	var base: String = super.failure_reason(vm, q, by_key)
	if base != "":
		return base
	var wk: int = int(q["data"].get("invited_week", -1))
	if wk >= 0 and not is_done(vm, q) and VillageFaith._week() > wk:
		return "%s dijo que vendría... pero no apareció por el Oficio." % str(q.get("target_name", ""))
	return ""

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	if npc.get_person_key() != str(q.get("target_key", "")) or is_done(vm, q) or int(q["data"].get("invited_week", -1)) >= 0:
		return
	ch_arr.insert(0, {"label": "⛪ Invitarle a venir al Oficio este domingo", "next": "END", "action": "quest_faith_invite:" + str(q["id"])})

func on_extra_action(_vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if not action_id.begins_with("quest_faith_invite:"):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	if q.is_empty():
		return true
	if npc.affinity >= 10 or charisma(player_of(npc)) >= 1:
		var wk: int = next_rite_week()
		q["data"]["invited_week"] = wk
		npc.set_meta("rite_invited_week", wk)
		npc._spawn_floating_text("🙂 «Bueno... por una vez. Allí estaré el domingo.»", Color(1.0, 0.95, 0.7), -46.0)
		qm.add_note(str(q["id"]), "%s ha prometido ir al próximo Oficio." % npc.npc_name)
	else:
		npc.modify_affinity(-2)
		npc._spawn_floating_text("«¿Y a ti qué te importa si voy o no?»", Color.CORAL, -46.0)
	return true

func done_dialogue(_vm: VillageManager, q: Dictionary) -> Dictionary:
	return {"text": "«¡Vi a %s en el banco del fondo! Gracias, hijo/a. Que la luz te acompañe.»" % str(q.get("target_name", "")), "choices": [{"label": "💰 Aceptar la limosna", "next": "END", "action": "quest_turn_in"}]}
