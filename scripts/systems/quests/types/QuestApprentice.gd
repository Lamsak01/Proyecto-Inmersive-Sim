@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M8 «El aprendiz»: un joven sin oficio te pide que le recomiendes a un dueño de taller que no tiene ayudante.
## Si el dueño te aprecia (o le convences), lo toma como ayudante: cobra su parte cada día y heredará el negocio.
## Toca VillageFamily (ayudantes, `family_npcs`) y el empleo.

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const MAX_AGE: int = 30

func _init() -> void:
	id = "apprentice"
	priority = 30
	gold = 10
	affinity = 20

static func _free_shop_owners(vm: VillageManager) -> Array:
	var out: Array = []
	for o in VillageNeeds.living(vm):
		if not (o.trade_role in VillageNPC.SHOP_ROLES) or VillageNeeds.is_outsider(o):
			continue
		var kin = vm.family_npcs.get(int(o.trade_role))
		if kin == null or not is_instance_valid(kin) or kin.is_dead:
			out.append(o)
	return out

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	if int(giver.trade_role) != int(VillageNPC.TradeRole.UNEMPLOYED) or giver.person_profile == null or int(giver.person_profile.age) > MAX_AGE or VillageNeeds.is_outsider(giver):
		return {}
	var owners: Array = _free_shop_owners(vm)
	if owners.is_empty():
		return {}
	var o = owners[randi() % owners.size()]
	return {"target_key": o.get_person_key(), "target_name": o.npc_name, "role": int(o.trade_role)}

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", ""))
	return {
		"title": "El aprendiz",
		"ask": "«Me paso el día sin nada que hacer... %s no tiene quien le ayude en el taller. Si le hablas bien de mí, quizá me coja de aprendiz.»" % tn,
		"desc": "%s busca oficio. Recomiéndale a %s (🧑‍🔧 en su diálogo); acepta si te aprecia o tienes Carisma." % [str(off.get("giver_name", "")), tn],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, off: Dictionary) -> Dictionary:
	return {"role": int(off.get("role", -1))}

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	var g: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("giver_key", "")), null)
	return g != null and int(g.trade_role) == int(VillageNPC.TradeRole.FAMILY_MEMBER)

func progress_hint(q: Dictionary) -> String:
	return "«¿Has hablado ya con %s? Aprendo rápido, de verdad.»" % str(q.get("target_name", ""))

func failure_reason(vm: VillageManager, q: Dictionary, by_key: Dictionary) -> String:
	var base: String = super.failure_reason(vm, q, by_key)
	if base != "" or is_done(vm, q):
		return base
	var g: VillageNPC = by_key.get(str(q.get("giver_key", "")), null)
	if g != null and int(g.trade_role) != int(VillageNPC.TradeRole.UNEMPLOYED):
		return "%s ya encontró trabajo por su cuenta." % str(q.get("giver_name", ""))
	var kin = vm.family_npcs.get(int(q["data"].get("role", -1)))
	if kin != null and is_instance_valid(kin) and not kin.is_dead:
		return "%s ya tiene ayudante." % str(q.get("target_name", ""))
	return ""

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	if npc.get_person_key() != str(q.get("target_key", "")) or is_done(vm, q):
		return
	ch_arr.insert(0, {"label": "🧑‍🔧 Recomendarle a %s como aprendiz" % str(q.get("giver_name", "")), "next": "END", "action": "quest_apprentice:" + str(q["id"])})

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if not action_id.begins_with("quest_apprentice:"):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	var g: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("giver_key", "")), null) if not q.is_empty() else null
	if g == null or g.is_dead:
		return true
	var liking: int = npc.get_relationship_with_npc(g.get_person_key())
	if npc.affinity >= 15 or charisma(player_of(npc)) >= 2 or (npc.affinity >= 0 and liking >= 20):
		hire(vm, npc, g)
		npc._spawn_floating_text("🧑‍🔧 «Está bien, que venga mañana temprano. Y que no llegue tarde.»", Color.SPRING_GREEN, -46.0)
		qm.add_note(str(q["id"]), "%s tomó a %s de aprendiz." % [npc.npc_name, g.npc_name])
	elif liking <= -20:
		npc._spawn_floating_text("«¿%s? Ni loco/a. No lo quiero en mi taller.»" % g.npc_name, Color.CORAL, -46.0)
	else:
		npc.modify_affinity(-2)
		npc._spawn_floating_text("«No te conozco tanto como para fiarme de quien me recomiendas.»", Color(0.85, 0.85, 0.85), -46.0)
	return true

## Igual que el hijo que se queda en el negocio familiar (VillageFamily.grow_up).
static func hire(vm: VillageManager, owner: VillageNPC, n: VillageNPC) -> void:
	var role: int = int(owner.trade_role)
	n.trade_role = VillageNPC.TradeRole.FAMILY_MEMBER
	n.linked_trade = role as VillageNPC.TradeRole
	n.npc_role = "Aprendiz"
	n.work_position = owner.work_position + Vector2(-24, 4)
	vm.family_npcs[role] = n
	vm.unemployed_npcs.erase(n)
	n.add_thought("¡Por fin tengo oficio! (+8)", 8.0)
	n.modify_npc_relationship(owner, 10, "Me tomó de aprendiz")
	vm.VillageChronicle.add(vm, "grown_up", "%s entró de aprendiz con %s" % [n.npc_name, owner.npc_name], true)

func done_dialogue(_vm: VillageManager, _q: Dictionary) -> Dictionary:
	return {"text": "«¡Ya tengo oficio! Toma, es lo poco que tengo... pero te lo debo.»", "choices": [{"label": "💰 Cobrar", "next": "END", "action": "quest_turn_in"}]}
