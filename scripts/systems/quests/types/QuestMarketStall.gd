@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M15 «El puesto del miércoles»: un artesano quiere montar puesto en el mercado, pero no tiene género de sobra.
## Le adelantas el oro para material (💰) o convences a un productor de que le fíe (🪵/🪨). Se cumple si de verdad
## monta puesto el miércoles. Toca el mercado de VillageCulture y el stock de las tiendas.

const VillageCulture = preload("res://scripts/systems/VillageCulture.gd")
const LOAN: int = 15
const PRODUCER_ROLES: Array = ["QUARRYMAN", "WOODCUTTER", "FARMER", "RANCHER"]

func _init() -> void:
	id = "market_stall"
	priority = 38
	gold = 20
	affinity = 12
	needs_alive_target = false

static func days_to_market() -> int:
	var wd: int = int(WorldClock.get_weekday()) if WorldClock and WorldClock.has_method("get_weekday") else 0
	return (VillageCulture.MARKET_WEEKDAY - wd + 7) % 7

func find_daily_offer(_vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	var left: int = days_to_market()
	if not (giver.trade_role in VillageNPC.SHOP_ROLES) or left < 1 or left > 3 or giver.shop_stock.is_empty():
		return {}
	if VillageCulture._surplus(giver) >= VillageCulture.MARKET_MIN_STOCK:
		return {}
	return {"target_key": "", "target_name": "", "market_day": day() + left}

func texts(off: Dictionary) -> Dictionary:
	return {
		"title": "El puesto del miércoles",
		"ask": "«Este miércoles quiero bajar al mercado, que allí se vende el doble. Pero con lo poco que tengo no lleno ni media mesa...»",
		"desc": "%s quiere montar puesto en el Mercado del Miércoles (día %d) y le falta género. Adelántale %d de oro para material (💰) o pide a un productor de las afueras que le fíe (🤝)." % [str(off.get("giver_name", "")), int(off.get("market_day", 0)), LOAN],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, off: Dictionary) -> Dictionary:
	return {"market_day": int(off.get("market_day", 0)), "stocked": false, "sold": false}

static func _top_item(n: VillageNPC) -> String:
	var best: String = ""
	var bv: int = -1
	for k in n.shop_stock.keys():
		if int(n.shop_stock[k]) > bv:
			bv = int(n.shop_stock[k])
			best = str(k)
	return best

static func restock(n: VillageNPC) -> void:
	var it: String = _top_item(n)
	if it != "":
		n.shop_stock[it] = maxi(int(n.shop_stock[it]), VillageCulture.MARKET_MIN_STOCK + 2)

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	if not bool(q["data"].get("sold", false)) and (VillageCulture.state(vm)["market_sellers"] as Dictionary).has(str(q.get("giver_key", ""))):
		q["data"]["sold"] = true
	return bool(q["data"].get("sold", false))

func progress_hint(q: Dictionary) -> String:
	if bool(q["data"].get("stocked", false)):
		return "«¡Ya tengo género! Nos vemos el miércoles en la plaza.»"
	return "«El miércoles se acerca y sigo con la mesa medio vacía...»"

func failure_reason(vm: VillageManager, q: Dictionary, by_key: Dictionary) -> String:
	var base: String = super.failure_reason(vm, q, by_key)
	if base != "":
		return base
	if day() > int(q["data"].get("market_day", 0)) and not is_done(vm, q):
		return "Pasó el miércoles y %s no llegó a montar puesto." % str(q.get("giver_name", ""))
	return ""

static func _is_producer(npc: VillageNPC) -> bool:
	for r in PRODUCER_ROLES:
		if int(npc.trade_role) == int(VillageNPC.TradeRole[r]):
			return true
	return false

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	if is_done(vm, q) or bool(q["data"].get("stocked", false)):
		return
	var qid: String = str(q["id"])
	if npc.get_person_key() == str(q.get("giver_key", "")):
		ch_arr.insert(0, {"label": "💰 Adelantarle %d de oro para material" % LOAN, "next": "END", "action": "quest_market_lend:" + qid})
	elif _is_producer(npc):
		ch_arr.insert(0, {"label": "🤝 Pedirle que fíe material a %s para el mercado" % str(q.get("giver_name", "")), "next": "END", "action": "quest_market_credit:" + qid})

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	var lend: bool = action_id.begins_with("quest_market_lend:")
	if not (lend or action_id.begins_with("quest_market_credit:")):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	var g: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("giver_key", "")), null) if not q.is_empty() else null
	if g == null:
		return true
	if lend:
		if not charge_player(player_of(npc), npc, LOAN):
			return true
		q["data"]["lent"] = LOAN
		npc._spawn_floating_text("🧺 «¡Gracias! Te lo devuelvo en cuanto venda.»", Color.SPRING_GREEN, -46.0)
	else:
		if not (npc.affinity >= 10 or charisma(player_of(npc)) >= 1 or npc.get_relationship_with_npc(g.get_person_key()) >= 15):
			npc._spawn_floating_text("«¿Fiar? Aquí se paga por adelantado, como todo el mundo.»", Color.CORAL, -46.0)
			return true
		npc.modify_npc_relationship(g, 4, "Le fié material para el mercado")
		npc._spawn_floating_text("🤝 «Bueno, por esta vez. Que me pague después del mercado.»", Color(0.8, 0.95, 1.0), -46.0)
	restock(g)
	q["data"]["stocked"] = true
	qm.add_note(str(q["id"]), "%s ya tiene género para el mercado." % g.npc_name)
	return true

func done_dialogue(_vm: VillageManager, q: Dictionary) -> Dictionary:
	var lent: int = int(q["data"].get("lent", 0))
	var txt: String = "«¡Qué día de mercado! Lo vendí casi todo.»" + (" Toma, lo que me adelantaste y un poco más." if lent > 0 else " Toma, te lo has ganado.")
	return {"text": txt, "choices": [{"label": "💰 Cobrar", "next": "END", "action": "quest_turn_in"}]}

func on_turn_in(_vm: VillageManager, qm: Node, giver: VillageNPC, player: Node, q: Dictionary, _action_full: String) -> void:
	pay_and_complete(qm, giver, player, q, gold + int(q["data"].get("lent", 0)), affinity)
