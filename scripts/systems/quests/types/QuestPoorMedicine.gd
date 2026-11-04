@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M6 «Medicina para el pobre»: un vecino pobre y enfermo no puede pagar al médico. Puedes pagarle tú el
## tratamiento (🩺 al médico) o pedir que lo pague la parroquia (🙏 al sacerdote). Toca VillageIllness y la fe.

const VillageIllness = preload("res://scripts/systems/VillageIllness.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const CURE_COST: int = 8

func _init() -> void:
	id = "poor_medicine"
	priority = 10
	gold = 0
	affinity = 25
	needs_alive_target = false

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	var ill: Dictionary = VillageIllness.ill_of(vm, giver.get_person_key())
	if ill.is_empty() or bool(ill.get("treated", false)) or not (VillageNeeds.class_of(giver) in ["pobre", "mendigo"]):
		return {}
	return {"target_key": "", "target_name": ""}

func texts(off: Dictionary) -> Dictionary:
	return {
		"title": "Medicina para %s" % str(off.get("giver_name", "")),
		"ask": "«*tose* El médico dice que sin %d de oro no hay hierbas... y no tengo ni para pan. ¿Me echas una mano?»" % CURE_COST,
		"desc": "%s está enfermo/a y es pobre. Paga tú al médico (🩺, %d de oro) o pide al sacerdote que lo pague la parroquia (🙏)." % [str(off.get("giver_name", "")), CURE_COST],
	}

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	var ill: Dictionary = VillageIllness.ill_of(vm, str(q.get("giver_key", "")))
	return ill.is_empty() or bool(ill.get("treated", false))

func progress_hint(_q: Dictionary) -> String:
	return "«*tose* Cada día me cuesta más levantarme...»"

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	if is_done(vm, q):
		return
	var gn: String = str(q.get("giver_name", ""))
	if int(npc.trade_role) == int(VillageNPC.TradeRole.DOCTOR):
		ch_arr.insert(0, {"label": "🩺 Pagar el tratamiento de %s (%d de oro)" % [gn, CURE_COST], "next": "END", "action": "quest_medicine_pay:" + str(q["id"])})
	elif vm.VillageFaith.is_priest(npc):
		ch_arr.insert(0, {"label": "🙏 Pedir que la parroquia pague las medicinas de %s" % gn, "next": "END", "action": "quest_medicine_church:" + str(q["id"])})

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	var pay: bool = action_id.begins_with("quest_medicine_pay:")
	if not (pay or action_id.begins_with("quest_medicine_church:")):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	if q.is_empty():
		return true
	var player: Node = player_of(npc)
	if pay:
		if not charge_player(player, npc, CURE_COST):
			return true
		npc.personal_gold += CURE_COST
		VillageIllness.treat(vm, str(q.get("giver_key", "")))
		npc._spawn_floating_text("🩺 «Iré a verle hoy mismo.»", Color(0.7, 1.0, 0.8), -46.0)
		qm.add_note(str(q["id"]), "Pagaste tú las medicinas.")
		return true
	# La parroquia paga si el cura te aprecia o le convences; sale de su bolsa y gana fama de caritativa
	var doctor = null
	for n in VillageNeeds.living(vm):
		if int(n.trade_role) == int(VillageNPC.TradeRole.DOCTOR):
			doctor = n
			break
	if (npc.affinity >= 10 or charisma(player) >= 1) and npc.personal_gold >= CURE_COST and doctor != null:
		npc.personal_gold -= CURE_COST
		doctor.personal_gold += CURE_COST
		VillageIllness.treat(vm, str(q.get("giver_key", "")))
		vm.VillageFaith.add_rep(vm, "faith", 2)
		npc._spawn_floating_text("⛪ «La caridad es nuestro deber. La parroquia lo pagará.»", Color(1.0, 0.95, 0.7), -46.0)
		qm.add_note(str(q["id"]), "La parroquia de %s pagó las medicinas." % npc.npc_name)
	elif doctor == null:
		npc._spawn_floating_text("«Pagaría, pero no hay médico en el valle...»", Color(0.85, 0.85, 0.85), -46.0)
	else:
		npc._spawn_floating_text("«La parroquia anda escasa... Rezaré por él/ella.»", Color(0.85, 0.85, 0.85), -46.0)
	return true

func done_dialogue(_vm: VillageManager, _q: Dictionary) -> Dictionary:
	return {"text": "«Ya me encuentro mejor... No tengo oro para darte, pero no olvidaré esto nunca.»", "choices": [{"label": "🤝 «No hay de qué.»", "next": "END", "action": "quest_turn_in"}]}
