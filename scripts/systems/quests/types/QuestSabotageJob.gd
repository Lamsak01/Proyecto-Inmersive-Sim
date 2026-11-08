@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M9 «Sabotaje por encargo»: un dueño de taller que odia a otro te paga por sabotearle el puesto (el sabotaje
## nocturno de siempre). O puedes ir al comisario y denunciar el encargo. Toca el sabotaje de tiendas y la ley.

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const HATE: int = -25

func _init() -> void:
	id = "sabotage_job"
	priority = 40
	gold = 40
	affinity = 10

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	if not (giver.trade_role in VillageNPC.SHOP_ROLES):
		return {}
	var worst = null
	var worst_v: int = HATE
	for o in VillageNeeds.living(vm):
		if o == giver or not (o.trade_role in VillageNPC.SHOP_ROLES) or int(o.trade_role) == int(giver.trade_role):
			continue
		if not vm.shop_businesses.has(int(o.trade_role)) or vm.is_trade_sabotaged(int(o.trade_role)):
			continue
		var v: int = giver.get_relationship_with_npc(o.get_person_key())
		if v <= worst_v:
			worst_v = v
			worst = o
	if worst == null:
		return {}
	return {"target_key": worst.get_person_key(), "target_name": worst.npc_name, "role": int(worst.trade_role)}

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", ""))
	return {
		"title": "Sabotaje por encargo",
		"ask": "«%s me está hundiendo el negocio. Una noche, nadie mirando, un par de golpes a su puesto... Te pagaré bien. ¿Hay trato?»" % tn,
		"desc": "%s te paga por sabotear el puesto de %s (de noche, cuando no haya nadie). O ve al alguacil y denuncia el encargo (🚨)." % [str(off.get("giver_name", "")), tn],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, off: Dictionary) -> Dictionary:
	return {"role": int(off.get("role", -1)), "reported": false}

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	return bool(q["data"].get("reported", false)) or vm.is_trade_sabotaged(int(q["data"].get("role", -1)))

func progress_hint(_q: Dictionary) -> String:
	return "«Baja la voz... ¿Aún no lo has hecho? Que sea de noche.»"

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	if int(npc.trade_role) != int(VillageNPC.TradeRole.SHERIFF) or is_done(vm, q):
		return
	ch_arr.insert(0, {"label": "🚨 Denunciar que %s quiere sabotear a %s" % [str(q.get("giver_name", "")), str(q.get("target_name", ""))], "next": "END", "action": "quest_sabotage_report:" + str(q["id"])})

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if not action_id.begins_with("quest_sabotage_report:"):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	if q.is_empty():
		return true
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var giver: VillageNPC = by_key.get(str(q.get("giver_key", "")), null)
	var victim: VillageNPC = by_key.get(str(q.get("target_key", "")), null)
	if giver != null:
		giver.modify_affinity(-35)
		giver.add_thought("El forastero me ha delatado al alguacil (-10)", -10.0)
		npc.modify_npc_relationship(giver, -15, "Encargó un sabotaje", true)
		if victim != null:
			victim.modify_npc_relationship(giver, -20, "Quiso sabotearme el puesto", true)
			victim.modify_affinity(15)
	npc.modify_affinity(8)
	vm.VillageFaith.add_rep(vm, "law", 3)
	vm.VillageChronicle.add(vm, "feud","%s fue denunciado/a por encargar un sabotaje contra %s" % [str(q.get("giver_name", "")), str(q.get("target_name", ""))], true)
	npc._spawn_floating_text("🚔 «Bien hecho. Le tendré vigilado/a.»", Color(0.7, 0.85, 1.0), -46.0)
	qm.complete_quest(str(q["id"]), "Denunciaste el encargo al alguacil.")
	return true

func done_dialogue(_vm: VillageManager, q: Dictionary) -> Dictionary:
	return {"text": "«Me han dicho que el puesto de %s está hecho un desastre... Toma, lo prometido. Nunca hemos hablado.»" % str(q.get("target_name", "")), "choices": [{"label": "💰 Cobrar", "next": "END", "action": "quest_turn_in"}]}

func on_turn_in(vm: VillageManager, qm: Node, giver: VillageNPC, player: Node, q: Dictionary, _action_full: String) -> void:
	vm.VillageFaith.add_rep(vm, "law", -2)
	pay_and_complete(qm, giver, player, q, gold, affinity)
