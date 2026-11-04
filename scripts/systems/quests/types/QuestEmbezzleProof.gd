@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M5 «Las cuentas del alcalde»: quien vio al alcalde quedarse impuestos te pide pruebas. Preguntas a otros que
## lo saben (🧾) y al volver eliges: destaparlo (elecciones anticipadas) o chantajear tú al alcalde.
## Toca VillageTown (desfalco, quién lo sabe, `expose`).

const VillageTown = preload("res://scripts/systems/VillageTown.gd")
const PROOFS: int = 2
const BLACKMAIL_GOLD: int = 50

func _init() -> void:
	id = "embezzle_proof"
	priority = 20
	gold = 30
	affinity = 15

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	var mayor = VillageTown.mayor_of(vm)
	var kn: Dictionary = VillageTown.embezzle_knowers(vm)
	if mayor == null or mayor == giver or not kn.has(giver.get_person_key()) or kn.size() < PROOFS + 1:
		return {}
	return {"target_key": mayor.get_person_key(), "target_name": mayor.npc_name}

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", "el alcalde"))
	return {
		"title": "Las cuentas de %s" % tn,
		"ask": "«Vi con mis propios ojos cómo %s se guardaba parte de los impuestos. Pero si lo digo yo solo/a, nadie me creerá... Busca a alguien más que lo sepa.»" % tn,
		"desc": "%s asegura que el alcalde %s roba de las arcas. Consigue %d testigos más (🧾 en su diálogo) y vuelve: podrás destaparlo... o sacarle tú el dinero." % [str(off.get("giver_name", "")), tn, PROOFS],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, _off: Dictionary) -> Dictionary:
	return {"proofs": []}

func is_done(_vm: VillageManager, q: Dictionary) -> bool:
	return (q["data"].get("proofs", []) as Array).size() >= PROOFS

func progress_hint(q: Dictionary) -> String:
	return "«¿Has encontrado a alguien más que lo sepa? Llevas %d de %d.»" % [(q["data"].get("proofs", []) as Array).size(), PROOFS]

func failure_reason(vm: VillageManager, q: Dictionary, by_key: Dictionary) -> String:
	var base: String = super.failure_reason(vm, q, by_key)
	if base != "":
		return base
	var mayor = VillageTown.mayor_of(vm)
	if mayor == null or mayor.get_person_key() != str(q.get("target_key", "")):
		return "%s ya no es alcalde." % str(q.get("target_name", ""))
	return ""

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	var k: String = npc.get_person_key()
	if is_done(vm, q) or k in [str(q.get("giver_key", "")), str(q.get("target_key", ""))] or k in (q["data"].get("proofs", []) as Array):
		return
	ch_arr.insert(0, {"label": "🧾 Preguntar qué sabe de las cuentas del alcalde", "next": "END", "action": "quest_embezzle_ask:" + str(q["id"])})

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if not action_id.begins_with("quest_embezzle_ask:"):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	if q.is_empty():
		return true
	if VillageTown.embezzle_knowers(vm).has(npc.get_person_key()) and npc.affinity >= 0:
		(q["data"]["proofs"] as Array).append(npc.get_person_key())
		VillageTown.state(vm)["player_knows_embezzle"] = true
		qm.add_note(str(q["id"]), "%s también vio al alcalde quedarse el dinero." % npc.npc_name)
		npc._spawn_floating_text("🤐 «Sí... yo también lo vi. Pero no digas que fui yo.»", Color(1.0, 0.9, 0.6), -46.0)
	elif VillageTown.embezzle_knowers(vm).has(npc.get_person_key()):
		npc._spawn_floating_text("«No sé de qué me hablas.» (No se fía de ti)", Color(0.85, 0.85, 0.85), -46.0)
	else:
		npc._spawn_floating_text("«¿El alcalde? Ni idea, yo no me meto en eso.»", Color(0.85, 0.85, 0.85), -46.0)
	return true

func done_dialogue(_vm: VillageManager, q: Dictionary) -> Dictionary:
	var tn: String = str(q.get("target_name", "el alcalde"))
	return {"text": "«¡Ya no estoy solo/a! ¿Qué hacemos ahora?»", "choices": [
		{"label": "📢 Destaparlo ante todo el pueblo", "next": "END", "action": "quest_turn_in:expose"},
		{"label": "💰 Callar... y pedirle a %s %d de oro por mi silencio" % [tn, BLACKMAIL_GOLD], "next": "END", "action": "quest_turn_in:blackmail"},
	]}

func on_turn_in(vm: VillageManager, qm: Node, giver: VillageNPC, player: Node, q: Dictionary, action_full: String) -> void:
	if action_full.ends_with(":blackmail"):
		var mayor = VillageTown.mayor_of(vm)
		var took: int = 0
		if mayor != null:
			took = mini(BLACKMAIL_GOLD, maxi(0, mayor.personal_gold))
			mayor.personal_gold -= took
			mayor.modify_affinity(-20)
			if took > 0 and player != null and "inventory" in player and player.inventory:
				player.inventory.add_gold(took)
		giver.modify_affinity(-20)
		giver._spawn_floating_text("😠 «¿Te has vendido? Eres igual que él.»", Color.ORANGE_RED, -46.0)
		qm.complete_quest(str(q["id"]), "Le sacaste %d de oro al alcalde a cambio de callar." % took)
		return
	VillageTown.expose(vm, "con las pruebas que reuniste")
	pay_and_complete(qm, giver, player, q, gold, affinity, "El desfalco salió a la luz.")
