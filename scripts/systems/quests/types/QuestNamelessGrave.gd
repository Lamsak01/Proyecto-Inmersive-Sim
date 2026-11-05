@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M20 «La tumba sin nombre»: el comisario archivó sin culpable la muerte de alguien; su familia no se resigna.
## Preguntas a los vecinos (🕯️) qué recuerdan de aquella noche; quien odia al asesino o le vio, habla. Con 2
## testimonios eliges: señalar al verdadero asesino o cargarle el muerto a un enemigo de la familia (cobras más).
## Toca el archivo de la morgue (`corpse_records`) y quién mató de verdad (VillageDesires.killer_of).

const VillageDesires = preload("res://scripts/systems/VillageDesires.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageFamily = preload("res://scripts/systems/VillageFamily.gd")
const WITNESSES: int = 2
const SCAPEGOAT_BONUS: int = 15

func _init() -> void:
	id = "nameless_grave"
	priority = 6
	gold = 35
	affinity = 20
	needs_alive_target = false

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	if VillageFamily.is_child(giver):
		return {}
	var by_name: Dictionary = {}
	for n in VillageNeeds.living(vm):
		by_name[n.npc_name] = n
	for rec in vm.corpse_records:
		if not "Archivado" in str(rec.get("suspect", "")) or bool(rec.get("grave_quest", false)):
			continue
		if str(rec.get("family_name", "")) != giver.family_name or giver.family_name == "":
			continue
		var vn: String = str(rec.get("victim_name", ""))
		var killer: String = VillageDesires.killer_of(vm, vn)
		if killer == "" or not by_name.has(killer) or killer == giver.npc_name:
			continue
		return {"target_key": by_name[killer].get_person_key(), "target_name": vn, "killer": killer}
	return {}

func texts(off: Dictionary) -> Dictionary:
	var vn: String = str(off.get("target_name", ""))
	return {
		"title": "La tumba sin nombre",
		"ask": "«El comisario cerró lo de %s sin más: ‹sin pruebas›, dijo. Pero alguien lo hizo, y sigue paseando por el valle. Yo no puedo dormir así.»" % vn,
		"desc": "La muerte de %s se archivó sin culpable. Pregunta a los vecinos qué recuerdan de aquella noche (🕯️) hasta reunir %d testimonios. Luego dile a %s quién fue... o a quién culpar." % [vn, WITNESSES, str(off.get("giver_name", ""))],
	}

func init_data(vm: VillageManager, _giver: VillageNPC, off: Dictionary) -> Dictionary:
	for rec in vm.corpse_records:
		if str(rec.get("victim_name", "")) == str(off.get("target_name", "")):
			rec["grave_quest"] = true # No se vuelve a pedir por la misma tumba
	return {"killer": str(off.get("killer", "")), "witnesses": [], "asked": []}

func is_done(_vm: VillageManager, q: Dictionary) -> bool:
	return (q["data"].get("witnesses", []) as Array).size() >= WITNESSES

func progress_hint(q: Dictionary) -> String:
	return "«¿Alguien recuerda algo de la noche en que murió %s?»" % str(q.get("target_name", ""))

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	var k: String = npc.get_person_key()
	if is_done(vm, q) or k in [str(q.get("giver_key", "")), str(q.get("target_key", ""))] or k in (q["data"].get("asked", []) as Array):
		return
	ch_arr.insert(0, {"label": "🕯️ Preguntar qué recuerda de la noche en que murió %s" % str(q.get("target_name", "")), "next": "END", "action": "quest_grave_ask:" + str(q["id"])})

func on_extra_action(_vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if not action_id.begins_with("quest_grave_ask:"):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	if q.is_empty():
		return true
	(q["data"]["asked"] as Array).append(npc.get_person_key())
	var killer_key: String = str(q.get("target_key", ""))
	var hates: bool = npc.get_relationship_with_npc(killer_key) <= -15
	var saw: bool = abs(("%s#%s" % [npc.get_person_key(), q["id"]]).hash()) % 100 < 30
	if (hates or saw) and npc.affinity >= -10:
		(q["data"]["witnesses"] as Array).append(npc.get_person_key())
		var kn: String = str(q["data"].get("killer", ""))
		npc._spawn_floating_text("🕯️ «Aquella noche vi a %s volver a casa muy tarde, con prisa... y nunca dijo dónde había estado.»" % kn, Color(1.0, 0.85, 0.7), -46.0)
		qm.add_note(str(q["id"]), "%s vio a %s aquella noche." % [npc.npc_name, kn])
	else:
		npc._spawn_floating_text("«Esa noche dormí como un tronco. No sé nada.»", Color(0.85, 0.85, 0.85), -46.0)
	return true

## El peor enemigo de quien pide (que no sea el asesino): el chivo expiatorio posible.
static func scapegoat_of(vm: VillageManager, giver: VillageNPC, killer_key: String) -> VillageNPC:
	var worst: VillageNPC = null
	var wv: int = -10
	for n in VillageNeeds.living(vm):
		if n == giver or n.get_person_key() == killer_key or VillageFamily.is_child(n):
			continue
		var v: int = giver.get_relationship_with_npc(n.get_person_key())
		if v < wv:
			wv = v
			worst = n
	return worst

func done_dialogue(vm: VillageManager, q: Dictionary) -> Dictionary:
	var choices: Array = [{"label": "⚖️ La verdad: «Fue %s. Hay dos testigos.»" % str(q["data"].get("killer", "")), "next": "END", "action": "quest_turn_in:truth"}]
	var giver: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("giver_key", "")), null)
	var sg: VillageNPC = scapegoat_of(vm, giver, str(q.get("target_key", ""))) if giver != null else null
	if sg != null:
		choices.append({"label": "😈 Mentir: «Fue %s.» (A quien ya odia; te pagará más)" % sg.npc_name, "next": "END", "action": "quest_turn_in:scapegoat"})
	return {"text": "«Dime que sabes quién fue...»", "choices": choices}

func on_turn_in(vm: VillageManager, qm: Node, giver: VillageNPC, player: Node, q: Dictionary, action_full: String) -> void:
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var vn: String = str(q.get("target_name", ""))
	var accused: VillageNPC = by_key.get(str(q.get("target_key", "")), null)
	var lie: bool = action_full.ends_with(":scapegoat")
	if lie:
		accused = scapegoat_of(vm, giver, str(q.get("target_key", "")))
	if accused != null:
		giver.modify_npc_relationship(accused, -40, "Mató a %s" % vn, true)
		for n in VillageNeeds.living(vm):
			if n != accused and n.family_name == giver.family_name:
				n.modify_npc_relationship(accused, -25, "Mató a %s" % vn, true)
		accused.add_thought("La familia de %s me señala como su asesino (-10)" % vn, -10.0)
		vm.VillageChronicle.add(vm, "feud", "La familia de %s acusa a %s de su muerte" % [vn, accused.npc_name], true)
	vm.VillageFaith.add_rep(vm, "law", -3 if lie else 3)
	if lie:
		pay_and_complete(qm, giver, player, q, gold + SCAPEGOAT_BONUS, affinity, "Culpaste a %s, que era inocente." % (accused.npc_name if accused != null else "otro"))
	else:
		pay_and_complete(qm, giver, player, q, gold, affinity, "Señalaste al verdadero asesino.")
