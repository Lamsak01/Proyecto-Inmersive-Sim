@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M18 «Sin techo»: a alguien le acaban de quitar la casa por deudas y duerme al raso. Le buscas sitio: un amigo
## con cama libre que le acoja (🏠), el prestamista que le deje volver de alquiler (🙏), o le das tú para la posada
## (💰). Toca los desahucios de VillageLoans, las casas de VillageMigration y la posada.

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const VillageMigration = preload("res://scripts/systems/VillageMigration.gd")
const RECENT_DAYS: int = 4
const INN_GIFT: int = 18

func _init() -> void:
	id = "homeless"
	priority = 8
	gold = 0
	affinity = 25
	needs_alive_target = false

static func is_homeless(n: VillageNPC) -> bool:
	return n.is_vagrant_camper and not n.in_shelter

func find_daily_offer(_vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	if not giver.has_meta("evicted_day") or day() - int(giver.get_meta("evicted_day")) > RECENT_DAYS or not is_homeless(giver):
		return {}
	return {"target_key": "", "target_name": "", "lot": str(giver.get_meta("evicted_lot", ""))}

func texts(off: Dictionary) -> Dictionary:
	return {
		"title": "Sin techo",
		"ask": "«Me echaron de mi casa. Llevo noches durmiendo al raso y el frío no perdona... ¿Conoces a alguien que me deje un rincón?»",
		"desc": "A %s le quitaron la casa por deudas. Pide a un amigo suyo con cama libre que le acoja (🏠), al prestamista que le deje volver de alquiler (🙏), o dale %d de oro para la posada (💰)." % [str(off.get("giver_name", "")), INN_GIFT],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, off: Dictionary) -> Dictionary:
	return {"lot": str(off.get("lot", ""))}

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	var g: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("giver_key", "")), null)
	return g != null and not is_homeless(g)

func progress_hint(_q: Dictionary) -> String:
	return "«Otra noche en el suelo... Me duelen hasta los huesos.»"

static func _free_bed(vm: VillageManager, lot_id: String) -> bool:
	var st: Dictionary = VillageLots.lot(vm, lot_id)
	return str(st.get("kind", "")) == "house" and (st.get("residents", []) as Array).size() < (st.get("beds", []) as Array).size()

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	if is_done(vm, q):
		return
	var qid: String = str(q["id"])
	var gk: String = str(q.get("giver_key", ""))
	var gn: String = str(q.get("giver_name", ""))
	if npc.get_person_key() == gk:
		ch_arr.insert(0, {"label": "💰 Darle %d de oro para la posada" % INN_GIFT, "next": "END", "action": "quest_home_inn:" + qid})
		return
	var h: String = VillageMigration.house_of(npc)
	if h != "" and _free_bed(vm, h):
		ch_arr.insert(0, {"label": "🏠 Pedirle que acoja a %s en su casa" % gn, "next": "END", "action": "quest_home_friend:" + qid})
	var st: Dictionary = VillageLots.lot(vm, str(q["data"].get("lot", "")))
	var owner: String = str(st.get("payer", ""))
	if (owner == npc.get_person_key() or (owner == "town" and vm.VillageTown.is_mayor(vm, npc))) and _free_bed(vm, str(q["data"].get("lot", ""))):
		ch_arr.insert(0, {"label": "🙏 Pedirle que deje a %s volver a su casa, de alquiler" % gn, "next": "END", "action": "quest_home_lender:" + qid})

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if not action_id.begins_with("quest_home_"):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	var g: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("giver_key", "")), null) if not q.is_empty() else null
	if g == null:
		return true
	var player: Node = player_of(npc)
	if action_id.begins_with("quest_home_inn:"):
		if charge_player(player, npc, INN_GIFT):
			g.personal_gold += INN_GIFT
			g.is_vagrant_camper = false
			g.in_shelter = false
			g.lodging = ""
			var free_b = VillageMigration.free_tavern_bed(vm)
			if free_b != null:
				g.bed_position = free_b
			if vm.vagrant_camp_nodes.has(g.npc_name) and is_instance_valid(vm.vagrant_camp_nodes[g.npc_name]):
				vm.vagrant_camp_nodes[g.npc_name].visible = false
			npc._spawn_floating_text("🥹 «Esta noche dormiré bajo techo. Gracias.»", Color.SPRING_GREEN, -46.0)
			qm.add_note(str(q["id"]), "Le diste %d de oro: vuelve a tener cama en la posada." % INN_GIFT)
		return true
	if action_id.begins_with("quest_home_friend:"):
		var rel: int = npc.get_relationship_with_npc(g.get_person_key())
		if rel >= 25 or (rel >= 5 and (npc.affinity >= 20 or charisma(player) >= 2)):
			if VillageMigration.move_into_house(vm, g, VillageMigration.house_of(npc)):
				npc.modify_npc_relationship(g, 6, "Le acogí en mi casa")
				g.modify_npc_relationship(npc, 15, "Me acogió cuando no tenía nada")
				npc._spawn_floating_text("🏠 «Que venga. Donde comen dos, comen tres.»", Color.SPRING_GREEN, -46.0)
				qm.add_note(str(q["id"]), "%s le acogió en su casa." % npc.npc_name)
		else:
			npc._spawn_floating_text("«¿En mi casa? Bastante tengo con lo mío.»", Color.CORAL, -46.0)
		return true
	# Prestamista: le deja volver pagando alquiler (las casas de otro ya cobran 2 de oro por noche a su dueño)
	if npc.affinity >= 30 or charisma(player) >= 2:
		if VillageMigration.move_into_house(vm, g, str(q["data"].get("lot", ""))):
			npc.modify_affinity(-3)
			npc._spawn_floating_text("😮‍💨 «Que vuelva... pero el alquiler, puntual. Una sola noche sin pagar y fuera.»", Color(0.8, 0.95, 1.0), -46.0)
			qm.add_note(str(q["id"]), "%s le deja volver de alquiler." % npc.npc_name)
	else:
		npc.modify_affinity(-5)
		npc._spawn_floating_text("«Tuvo su oportunidad. Una deuda es una deuda.»", Color.CORAL, -46.0)
	return true

func done_dialogue(_vm: VillageManager, _q: Dictionary) -> Dictionary:
	return {"text": "«Vuelvo a tener un techo. No tengo nada que darte... salvo mi palabra de que te lo devolveré algún día.»", "choices": [{"label": "🤝 «Con eso me basta.»", "next": "END", "action": "quest_turn_in"}]}
