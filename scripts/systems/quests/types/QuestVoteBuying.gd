@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M4 «Votos a la venta»: un candidato con pocos escrúpulos te paga por conseguirle votos antes de las elecciones.
## Usa el «🏛️ Hablar de las elecciones → 🗳️ Que vote a…» de siempre: quien te aprecia te hace caso y el corrupto
## vende su voto por 10 de oro. Al volver puedes cobrar o contarlo todo. Toca VillageTown (promesas de voto).

const VillageTown = preload("res://scripts/systems/VillageTown.gd")
const PLEDGES_NEEDED: int = 3
const DAYS_BEFORE: int = 8
const MIN_CORRUPT: float = 0.25

func _init() -> void:
	id = "vote_buying"
	priority = 30
	gold = 35
	affinity = 10
	needs_alive_target = false

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	var st: Dictionary = VillageTown.state(vm)
	var left: int = int(st.get("next_election", 0)) - VillageTown.VillageNeeds.today()
	if left <= 1 or left > DAYS_BEFORE or VillageTown.corruptibility(giver) < MIN_CORRUPT or VillageTown.is_mayor(vm, giver):
		return {}
	if not VillageTown.candidates(vm).has(giver):
		return {}
	return {"target_key": "", "target_name": "", "election_day": int(st.get("next_election", 0))}

func texts(off: Dictionary) -> Dictionary:
	return {
		"title": "Votos para %s" % str(off.get("giver_name", "")),
		"ask": "«Las elecciones del día %d están muy reñidas. Tú hablas con todo el mundo... Consígueme %d votos, como sea, y te lo pagaré bien.»" % [int(off.get("election_day", 0)), PLEDGES_NEEDED],
		"desc": "%s se presenta a alcalde y quiere %d promesas de voto antes del día %d. Habla con los vecinos de las elecciones (🗳️): los que te aprecian te harán caso; los corruptos venden su voto. Luego decide si cobras... o lo cuentas." % [str(off.get("giver_name", "")), PLEDGES_NEEDED, int(off.get("election_day", 0))],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, off: Dictionary) -> Dictionary:
	return {"election_day": int(off.get("election_day", 0))}

static func pledges_for(vm: VillageManager, key: String) -> int:
	var n: int = 0
	for v in (VillageTown.state(vm).get("pledges", {}) as Dictionary).values():
		if str(v) == key:
			n += 1
	return n

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	return pledges_for(vm, str(q.get("giver_key", ""))) >= PLEDGES_NEEDED

func progress_hint(_q: Dictionary) -> String:
	return "«¿Cómo van esos votos? Me hacen falta %d, y el tiempo corre.»" % PLEDGES_NEEDED

func failure_reason(vm: VillageManager, q: Dictionary, by_key: Dictionary) -> String:
	var base: String = super.failure_reason(vm, q, by_key)
	if base != "":
		return base
	if VillageTown.VillageNeeds.today() > int(q["data"].get("election_day", 0)) and not is_done(vm, q):
		return "Las elecciones ya pasaron."
	return ""

func done_dialogue(_vm: VillageManager, _q: Dictionary) -> Dictionary:
	return {"text": "«¡%d votos! Con eso gano seguro. Aquí tienes lo tuyo... y ni una palabra a nadie.»" % PLEDGES_NEEDED, "choices": [
		{"label": "💰 Cobrar y callar", "next": "END", "action": "quest_turn_in:take"},
		{"label": "📢 «No. Voy a contar a todos que compras votos.»", "next": "END", "action": "quest_turn_in:expose"},
	]}

func on_turn_in(vm: VillageManager, qm: Node, giver: VillageNPC, player: Node, q: Dictionary, action_full: String) -> void:
	if action_full.ends_with(":expose"):
		var st: Dictionary = VillageTown.state(vm)
		var gk: String = giver.get_person_key()
		for vk in (st.get("pledges", {}) as Dictionary).keys():
			if str(st["pledges"][vk]) == gk:
				st["pledges"].erase(vk)
		for n in VillageTown.VillageNeeds.living(vm):
			if n != giver and randf() < 0.5:
				n.modify_npc_relationship(giver, -8, "Compraba votos", true)
		giver.modify_affinity(-30)
		vm.VillageFaith.add_rep(vm, "law", 4)
		vm.VillageChronicle.add(vm, "embezzle_exposed", "Se supo que %s compraba votos para ser alcalde" % giver.npc_name, true)
		qm.complete_quest(str(q["id"]), "Destapaste la compra de votos de %s." % giver.npc_name)
		return
	vm.VillageFaith.add_rep(vm, "law", -3)
	pay_and_complete(qm, giver, player, q, gold, affinity)
