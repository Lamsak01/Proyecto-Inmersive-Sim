@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M14 «La última copa» (sustituye a «¿Quién lo ha dicho?», que repetía la misión del rumor): la pareja de alguien
## enganchado a la bebida o al juego te pide ayuda. Hablas con él/ella (🗣️, si te aprecia afloja el vicio) o pides
## al tabernero que no le sirva unos días (🚫, quizá a cambio de oro). Toca los vicios de VillageNeeds.

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const DONE_BELOW: float = 40.0
const BAN_DAYS: int = 6
const BAN_PRICE: int = 10
const TALK_CUT: float = 15.0

func _init() -> void:
	id = "last_drink"
	priority = 28
	gold = 20
	affinity = 15

static func vice_of(vm: VillageManager, key: String) -> String:
	if VillageNeeds.is_addicted(vm, key, "drink"):
		return "drink"
	if VillageNeeds.is_addicted(vm, key, "gamble"):
		return "gamble"
	return ""

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	if giver.person_profile == null or str(giver.person_profile.partner_id) == "":
		return {}
	var pk: String = str(giver.person_profile.partner_id)
	var v: String = vice_of(vm, pk)
	var p: VillageNPC = vm._get_npcs_by_person_key().get(pk, null)
	if v == "" or p == null or p.is_dead:
		return {}
	return {"target_key": pk, "target_name": p.npc_name, "vice": v}

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", ""))
	var what: String = "la bebida" if str(off.get("vice", "drink")) == "drink" else "los dados"
	return {
		"title": "La última copa",
		"ask": "«%s se deja en la taberna lo que no tenemos. Dice que lo controla... pero cada noche vuelve peor. Por favor, haz algo.»" % tn,
		"desc": "%s está enganchado/a a %s. Habla con %s (🗣️; funciona si te aprecia) o pide al tabernero que no le atienda unos días (🚫)." % [tn, what, tn],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, off: Dictionary) -> Dictionary:
	return {"vice": str(off.get("vice", "drink")), "talked": false}

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	return VillageNeeds.addiction(vm, str(q.get("target_key", "")), str(q["data"].get("vice", "drink"))) < DONE_BELOW

func progress_hint(q: Dictionary) -> String:
	return "«Anoche %s volvió otra vez tarde y sin un cobre...»" % str(q.get("target_name", ""))

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	if is_done(vm, q):
		return
	var qid: String = str(q["id"])
	if npc.get_person_key() == str(q.get("target_key", "")) and not bool(q["data"].get("talked", false)):
		ch_arr.insert(0, {"label": "🗣️ Hablarle de lo que se gasta en la taberna", "next": "END", "action": "quest_drink_talk:" + qid})
	elif npc == vm._innkeeper_npc or int(npc.trade_role) == int(VillageNPC.TradeRole.LODGEKEEPER):
		ch_arr.insert(0, {"label": "🚫 Pedirle que no atienda a %s unos días" % str(q.get("target_name", "")), "next": "END", "action": "quest_drink_ban:" + qid})

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	var talk: bool = action_id.begins_with("quest_drink_talk:")
	if not (talk or action_id.begins_with("quest_drink_ban:")):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	if q.is_empty():
		return true
	var key: String = str(q.get("target_key", ""))
	var vice: String = str(q["data"].get("vice", "drink"))
	if talk:
		q["data"]["talked"] = true
		if npc.affinity >= 20 or charisma(player_of(npc)) >= 2:
			VillageNeeds._add_addiction(vm, key, vice, -TALK_CUT)
			npc.add_thought("Tiene razón, se me está yendo de las manos (-2)", -2.0)
			npc._spawn_floating_text("😔 «Lo sé... Lo intentaré. De verdad.»", Color(0.8, 0.9, 1.0), -46.0)
			qm.add_note(str(q["id"]), "%s ha prometido intentarlo." % npc.npc_name)
		else:
			npc.modify_affinity(-6)
			npc._spawn_floating_text("😠 «¿Y tú quién eres para decirme lo que hago?»", Color.CORAL, -46.0)
		return true
	# El tabernero pierde un cliente: si no te aprecia, pide algo a cambio
	var player: Node = player_of(npc)
	var free: bool = npc.affinity >= 25 or charisma(player) >= 2
	if not free and not charge_player(player, npc, BAN_PRICE):
		return true
	if not free:
		npc.personal_gold += BAN_PRICE
	var ns: Dictionary = VillageNeeds.state(vm).get("no_serve", {})
	ns[key] = VillageNeeds.today() + BAN_DAYS
	VillageNeeds.state(vm)["no_serve"] = ns
	npc._spawn_floating_text("🍺 «Vale. %d días sin servirle nada. Pero no le digas que fue cosa tuya.»" % BAN_DAYS, Color(1.0, 0.9, 0.6), -46.0)
	qm.add_note(str(q["id"]), "El tabernero no atenderá a %s en %d días%s." % [str(q.get("target_name", "")), BAN_DAYS, "" if free else " (le pagaste %d)" % BAN_PRICE])
	return true

func done_dialogue(_vm: VillageManager, q: Dictionary) -> Dictionary:
	return {"text": "«%s ya no pasa las noches en la taberna. Hasta ha vuelto a reírse en casa. Gracias.»" % str(q.get("target_name", "")), "choices": [{"label": "💰 Cobrar", "next": "END", "action": "quest_turn_in"}]}
