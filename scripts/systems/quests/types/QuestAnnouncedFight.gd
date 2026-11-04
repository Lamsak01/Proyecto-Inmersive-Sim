@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M17 «Pelea anunciada»: dos enemigos están a punto de llegar a las manos (tensión alta tras muchos días de roce).
## Un amigo de uno de ellos te pide que lo evites. Calmas a uno y a otro (🕊️ baja la tensión) hasta que se enfríe.
## Si llegan a pelearse, falla. No provoca peleas: solo nace donde la pelea ya iba a llegar sola.
## Toca las peleas en vivo de SocialDirector (tensión, días de enemistad).

const CALM_DROP: int = 10
const DONE_TENSION: int = 14

func _init() -> void:
	id = "announced_fight"
	priority = 12
	gold = 20
	affinity = 12

static func _pair(vm: VillageManager, a: String, b: String) -> Dictionary:
	var sd = vm.social_director
	if sd == null:
		return {}
	return sd.pair_metrics.get(sd.make_pair_key(a, b), {})

func find_daily_offer(vm: VillageManager, giver: VillageNPC, npcs: Array, _ctx: Dictionary) -> Dictionary:
	var sd = vm.social_director
	if sd == null:
		return {}
	var thr: int = int(sd.dials.get("live_fight_tension_threshold", 28))
	var min_days: int = int(sd.dials.get("live_fight_min_enmity_days", 10))
	for friend in npcs:
		if friend == giver or friend.is_dead or giver.get_relationship_with_npc(friend.get_person_key()) < 30:
			continue
		for foe in npcs:
			if foe == friend or foe == giver or foe.is_dead:
				continue
			var pe: Dictionary = _pair(vm, friend.get_person_key(), foe.get_person_key())
			if pe.is_empty() or int(pe.get("enmity_days", 0)) < min_days - 3 or int(pe.get("tension", 0)) < thr - 8:
				continue
			if int(pe.get("fights_count", 0)) >= int(sd.dials.get("max_fights_per_pair", 2)):
				continue
			return {"target_key": friend.get_person_key(), "target_name": friend.npc_name, "foe_key": foe.get_person_key(), "foe_name": foe.npc_name, "fights": int(pe.get("fights_count", 0))}
	return {}

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", ""))
	var fn: String = str(off.get("foe_name", ""))
	return {
		"title": "Pelea anunciada",
		"ask": "«%s y %s ya no se pueden ni ver. Ayer casi se lían a golpes en la plaza. Si alguien no los calma, esto acaba mal...»" % [tn, fn],
		"desc": "%s y %s están a punto de pelearse. Habla con los dos (🕊️) para calmarlos hasta que se enfríe la cosa. Si llegan a las manos, habrás llegado tarde." % [tn, fn],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, off: Dictionary) -> Dictionary:
	return {"foe_key": str(off.get("foe_key", "")), "foe_name": str(off.get("foe_name", "")), "fights": int(off.get("fights", 0)), "calmed": []}

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	var pe: Dictionary = _pair(vm, str(q.get("target_key", "")), str(q["data"].get("foe_key", "")))
	return not pe.is_empty() and int(pe.get("tension", 0)) <= DONE_TENSION and int(pe.get("fights_count", 0)) == int(q["data"].get("fights", 0))

func progress_hint(_q: Dictionary) -> String:
	return "«Todavía se miran con ganas de matarse...»"

func failure_reason(vm: VillageManager, q: Dictionary, by_key: Dictionary) -> String:
	var base: String = super.failure_reason(vm, q, by_key)
	if base != "":
		return base
	var pe: Dictionary = _pair(vm, str(q.get("target_key", "")), str(q["data"].get("foe_key", "")))
	if int(pe.get("fights_count", 0)) > int(q["data"].get("fights", 0)):
		return "%s y %s acabaron a golpes." % [str(q.get("target_name", "")), str(q["data"].get("foe_name", ""))]
	return ""

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	var k: String = npc.get_person_key()
	if is_done(vm, q) or not (k in [str(q.get("target_key", "")), str(q["data"].get("foe_key", ""))]):
		return
	if k + "@" + str(day()) in (q["data"].get("calmed", []) as Array):
		return # Una vez al día por persona
	var other: String = str(q["data"].get("foe_name", "")) if k == str(q.get("target_key", "")) else str(q.get("target_name", ""))
	ch_arr.insert(0, {"label": "🕊️ «Déjalo estar con %s. No merece la pena.»" % other, "next": "END", "action": "quest_fight_calm:" + str(q["id"])})

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if not action_id.begins_with("quest_fight_calm:"):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	if q.is_empty():
		return true
	(q["data"]["calmed"] as Array).append(npc.get_person_key() + "@" + str(day()))
	var pe: Dictionary = _pair(vm, str(q.get("target_key", "")), str(q["data"].get("foe_key", "")))
	var agg: float = preload("res://scripts/data/TraitCatalog.gd").npc_tendency(npc, "aggression")
	var drop: int = CALM_DROP + (4 if npc.affinity >= 20 or charisma(player_of(npc)) >= 1 else 0) - (4 if agg > 0.3 else 0)
	if not pe.is_empty():
		pe["tension"] = maxi(0, int(pe.get("tension", 0)) - drop)
	npc._spawn_floating_text("😤 «...Vale. Por esta vez me aguanto.»", Color(0.8, 0.9, 1.0), -46.0)
	qm.add_note(str(q["id"]), "Calmaste a %s (tensión -%d)." % [npc.npc_name, drop])
	return true

func done_dialogue(_vm: VillageManager, _q: Dictionary) -> Dictionary:
	return {"text": "«Ya ni se gritan al cruzarse. No sé qué les dijiste, pero funcionó.»", "choices": [{"label": "💰 Cobrar", "next": "END", "action": "quest_turn_in"}]}
