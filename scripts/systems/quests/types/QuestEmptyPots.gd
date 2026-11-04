@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M11 «Ollas vacías»: al Albergue no le llegan las gachas para todos los pobres. El sacerdote te pide reunir
## donativos: pides a los vecinos con dinero (🥣) o pones tú el oro. Cada 2 de oro es una ración más hoy.
## Toca las gachas del Albergue (VillageCivic), las clases sociales y la generosidad.

const VillageCivic = preload("res://scripts/systems/VillageCivic.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const GOAL: int = 20
const ASK: int = 8

func _init() -> void:
	id = "empty_pots"
	priority = 20
	gold = 0
	affinity = 15
	needs_alive_target = false

static func poor_count(vm: VillageManager) -> int:
	var n: int = 0
	for o in VillageNeeds.living(vm):
		if VillageNeeds.class_of(o) in ["pobre", "mendigo"]:
			n += 1
	return n

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	if not vm.VillageFaith.is_priest(giver) or str(VillageCivic.VillageLots.lot(vm, VillageCivic.SHELTER_LOT).get("status", "")) != "built":
		return {}
	if poor_count(vm) < 3 or int(vm.town_state.get("treasury", 0)) >= VillageCivic.RATION_COST_TOWN * VillageCivic.RATION_MAX * 3:
		return {} # Solo si hay pobres de verdad y las arcas van justas
	return {"target_key": "", "target_name": ""}

func texts(off: Dictionary) -> Dictionary:
	return {
		"title": "Ollas vacías",
		"ask": "«Las arcas del pueblo apenas dan para gachas, y cada mañana hay más bocas en la puerta del Albergue. ¿Me ayudas a pedir a quien tiene de sobra?»",
		"desc": "%s necesita %d de oro en donativos para las gachas del Albergue. Pide a los vecinos acomodados (🥣 en su diálogo; los generosos dan más) o pon tú el oro al sacerdote." % [str(off.get("giver_name", "")), GOAL],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, _off: Dictionary) -> Dictionary:
	return {"raised": 0, "asked": []}

func is_done(_vm: VillageManager, q: Dictionary) -> bool:
	return int(q["data"].get("raised", 0)) >= GOAL

func progress_hint(q: Dictionary) -> String:
	return "«Llevamos %d de %d de oro. Cada moneda es un cuenco más.»" % [int(q["data"].get("raised", 0)), GOAL]

## Lo donado va a las arcas y se cocina enseguida (2 de oro por ración).
static func donate(vm: VillageManager, q: Dictionary, amount: int) -> void:
	q["data"]["raised"] = int(q["data"].get("raised", 0)) + amount
	vm.town_state["shelter_rations"] = int(vm.town_state.get("shelter_rations", 0)) + int(amount / VillageCivic.RATION_COST_TOWN)

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	if is_done(vm, q):
		return
	var qid: String = str(q["id"])
	if npc.get_person_key() == str(q.get("giver_key", "")):
		ch_arr.insert(0, {"label": "🪙 Donar yo %d de oro para las gachas" % ASK, "next": "END", "action": "quest_pots_give:" + qid})
	elif VillageNeeds.class_of(npc) in ["rico", "acomodado"] and not npc.get_person_key() in (q["data"].get("asked", []) as Array):
		ch_arr.insert(0, {"label": "🥣 Pedirle un donativo para las gachas del Albergue", "next": "END", "action": "quest_pots_ask:" + qid})

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	var own: bool = action_id.begins_with("quest_pots_give:")
	if not (own or action_id.begins_with("quest_pots_ask:")):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	if q.is_empty():
		return true
	if own:
		if charge_player(player_of(npc), npc, ASK):
			donate(vm, q, ASK)
			vm.VillageFaith.add_rep(vm, "poor", 2)
			npc._spawn_floating_text("🙏 «Que Dios te lo pague.»", Color(1.0, 0.95, 0.7), -46.0)
		return true
	(q["data"]["asked"] as Array).append(npc.get_person_key())
	var gen: float = preload("res://scripts/data/TraitCatalog.gd").npc_tendency(npc, "generosity")
	var give: int = 0
	if gen >= 0.3 or npc.affinity >= 25:
		give = 10
	elif gen > -0.2 and (npc.affinity >= 5 or charisma(player_of(npc)) >= 1):
		give = 5
	give = mini(give, maxi(0, npc.personal_gold - 20))
	if give > 0:
		npc.personal_gold -= give
		donate(vm, q, give)
		npc.add_thought("Di %d de oro para los pobres (+3)" % give, 3.0)
		npc._spawn_floating_text("🥣 «Toma, %d de oro. Que no se diga.»" % give, Color.SPRING_GREEN, -46.0)
		qm.add_note(str(q["id"]), "%s donó %d de oro." % [npc.npc_name, give])
	else:
		npc._spawn_floating_text("«¿Y por qué tengo que pagar yo la comida de los vagos?»", Color.CORAL, -46.0)
	return true

func done_dialogue(_vm: VillageManager, _q: Dictionary) -> Dictionary:
	return {"text": "«¡Las ollas vuelven a estar llenas! Esta noche nadie se acostará con el estómago vacío.»", "choices": [{"label": "🙏 «Me alegro, padre.»", "next": "END", "action": "quest_turn_in"}]}
