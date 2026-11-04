@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M13 «La herencia»: murió el dueño de un taller y lo heredó otro; un pariente del muerto que se quedó sin nada
## reclama su parte. Hablas con el heredero (⚖️): que le dé una parte, que le tome de ayudante o le dices al pariente
## que lo deje estar. Toca la sucesión de talleres (VillageManager), los ayudantes y la familia.

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageFamily = preload("res://scripts/systems/VillageFamily.gd")
const RECENT_DAYS: int = 5
const SHARE: int = 15

func _init() -> void:
	id = "inheritance"
	priority = 18
	gold = 20
	affinity = 15

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	if VillageFamily.is_child(giver) or not (int(giver.trade_role) in [int(VillageNPC.TradeRole.UNEMPLOYED), int(VillageNPC.TradeRole.FAMILY_MEMBER)]):
		return {}
	for h in VillageNeeds.living(vm):
		if h == giver or not h.has_meta("inherited_day") or day() - int(h.get_meta("inherited_day")) > RECENT_DAYS:
			continue
		var fam: String = str(h.get_meta("inherited_family", ""))
		if fam == "" or fam == "none" or giver.family_id != fam:
			continue
		return {"target_key": h.get_person_key(), "target_name": h.npc_name, "dead_name": str(h.get_meta("inherited_from", "")), "role": int(h.trade_role)}
	return {}

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", ""))
	var dn: String = str(off.get("dead_name", "mi familiar"))
	return {
		"title": "La herencia de %s" % dn,
		"ask": "«%s aún no se ha enfriado en su tumba y %s ya se ha quedado con todo el taller. ¡Yo soy de su sangre! Algo me corresponde, ¿no crees?»" % [dn, tn],
		"desc": "%s reclama parte de la herencia de %s, que se quedó %s. Habla con el heredero (⚖️): que le dé una parte o que le tome de ayudante. O dile a %s que lo deje estar." % [str(off.get("giver_name", "")), dn, tn, str(off.get("giver_name", ""))],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, off: Dictionary) -> Dictionary:
	return {"dead_name": str(off.get("dead_name", "")), "role": int(off.get("role", -1)), "result": ""}

func is_done(_vm: VillageManager, q: Dictionary) -> bool:
	return str(q["data"].get("result", "")) != ""

func progress_hint(q: Dictionary) -> String:
	return "«¿Has hablado con %s? No pienso quedarme de brazos cruzados.»" % str(q.get("target_name", ""))

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	if is_done(vm, q):
		return
	if npc.get_person_key() == str(q.get("giver_key", "")):
		ch_arr.insert(0, {"label": "🕊️ «El taller es suyo. Déjalo estar y sigue adelante.»", "next": "END", "action": "quest_inherit_drop:" + str(q["id"])})
		return
	if npc.get_person_key() != str(q.get("target_key", "")):
		return
	var gn: String = str(q.get("giver_name", ""))
	var qid: String = str(q["id"])
	ch_arr.insert(0, {"label": "⚖️ Pedirle que le dé a %s una parte (%d de oro)" % [gn, SHARE], "next": "END", "action": "quest_inherit_share:" + qid})
	var kin = vm.family_npcs.get(int(npc.trade_role))
	if (kin == null or not is_instance_valid(kin) or kin.is_dead) and int(vm._get_npcs_by_person_key().get(str(q.get("giver_key", "")), npc).trade_role) == int(VillageNPC.TradeRole.UNEMPLOYED):
		ch_arr.insert(1, {"label": "🧑‍🔧 Proponerle que tome a %s de ayudante en el taller" % gn, "next": "END", "action": "quest_inherit_hire:" + qid})

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if action_id.begins_with("quest_inherit_drop:"):
		var qd: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
		if not qd.is_empty():
			npc.modify_affinity(-5)
			npc.add_thought("Me tocará tragarme lo de la herencia (-4)", -4.0)
			npc._spawn_floating_text("😤 «Muy fácil decirlo cuando no es tu familia...»", Color(0.85, 0.85, 0.85), -46.0)
			qm.complete_quest(str(qd["id"]), "Le convenciste de que lo dejara estar.")
		return true
	var share: bool = action_id.begins_with("quest_inherit_share:")
	if not (share or action_id.begins_with("quest_inherit_hire:")):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	var g: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("giver_key", "")), null) if not q.is_empty() else null
	if g == null:
		return true
	var gen: float = preload("res://scripts/data/TraitCatalog.gd").npc_tendency(npc, "generosity")
	var ok: bool = npc.affinity >= 15 or charisma(player_of(npc)) >= 2 or gen >= 0.3 or npc.get_relationship_with_npc(g.get_person_key()) >= 20
	if not ok:
		npc.modify_affinity(-4)
		npc.modify_npc_relationship(g, -6, "Quiere quitarme lo que heredé", true)
		npc._spawn_floating_text("😠 «El taller me lo gané yo. Que se busque la vida.»", Color.CORAL, -46.0)
		return true
	if share:
		var amt: int = mini(SHARE, maxi(0, npc.personal_gold - 10))
		if amt <= 0:
			npc._spawn_floating_text("«Le daría algo, pero no tengo ni para mí.»", Color(0.85, 0.85, 0.85), -46.0)
			return true
		npc.personal_gold -= amt
		g.personal_gold += amt
		q["data"]["result"] = "share"
		npc._spawn_floating_text("😮‍💨 «Está bien... toma, dale esto. Era su familia también.»", Color(0.8, 0.95, 1.0), -46.0)
		qm.add_note(str(q["id"]), "%s dio %d de oro a %s." % [npc.npc_name, amt, g.npc_name])
	else:
		preload("res://scripts/systems/quests/types/QuestApprentice.gd").hire(vm, npc, g)
		q["data"]["result"] = "hired"
		npc._spawn_floating_text("🤝 «Que venga a ayudarme. Así queda en la familia.»", Color.SPRING_GREEN, -46.0)
		qm.add_note(str(q["id"]), "%s entró de ayudante en el taller." % g.npc_name)
	g.modify_npc_relationship(npc, 12, "Me dio mi parte de la herencia")
	return true

func done_dialogue(_vm: VillageManager, q: Dictionary) -> Dictionary:
	var txt: String = "«Bueno... no es todo lo que quería, pero es justo. Gracias.»"
	return {"text": txt, "choices": [{"label": "💰 Cobrar", "next": "END", "action": "quest_turn_in"}]}

func failure_reason(vm: VillageManager, q: Dictionary, by_key: Dictionary) -> String:
	var base: String = super.failure_reason(vm, q, by_key)
	if base != "":
		return base
	var h: VillageNPC = by_key.get(str(q.get("target_key", "")), null)
	if h != null and int(h.trade_role) != int(q["data"].get("role", -1)):
		return "%s ya no lleva el taller." % str(q.get("target_name", ""))
	return ""
