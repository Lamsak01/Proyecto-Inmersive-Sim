@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M1 «La carta sin firmar»: alguien nota rara a su pareja (que de verdad le engaña) y te pide que lo averigües.
## Preguntas a los vecinos (🕵️); quien vio algo te lo cuenta. Al volver eliges: la verdad, mentir o cobrarle
## al infiel por tu silencio. Toca VillageSecrets (aventuras, reacción de la pareja, chantaje).

const VillageSecrets = preload("res://scripts/systems/VillageSecrets.gd")

func _init() -> void:
	id = "affair_doubt"
	priority = 20
	gold = 25
	affinity = 12

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	if giver.person_profile == null or str(giver.person_profile.partner_id) == "":
		return {}
	var pk: String = str(giver.person_profile.partner_id)
	var s: Dictionary = VillageSecrets.active_affair_of(vm, pk)
	var kn: Dictionary = s.get("known_by", {}) as Dictionary if not s.is_empty() else {}
	if s.is_empty() or kn.is_empty() or kn.has(giver.get_person_key()):
		return {}
	return {"target_key": pk, "target_name": str(s["a_name"]), "secret_id": int(s["id"])}

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", "mi pareja"))
	return {
		"title": "¿Me engaña %s?" % tn,
		"ask": "«Últimamente %s llega tarde, no me mira a los ojos... Seguro que son tonterías mías. ¿Podrías averiguar, con discreción, si hay alguien más?»" % tn,
		"desc": "%s sospecha que %s le engaña. Pregunta a los vecinos (🕵️ en su diálogo) si han visto algo; luego vuelve y decide qué le cuentas." % [str(off.get("giver_name", "")), tn],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, off: Dictionary) -> Dictionary:
	return {"secret_id": int(off.get("secret_id", -1)), "found": false}

static func _secret(vm: VillageManager, q: Dictionary) -> Dictionary:
	for s in vm.secrets:
		if int(s.get("id", -2)) == int(q["data"].get("secret_id", -1)):
			return s
	return {}

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	var s: Dictionary = _secret(vm, q)
	return bool(q["data"].get("found", false)) or (not s.is_empty() and bool(s.get("player_knows", false)))

func progress_hint(q: Dictionary) -> String:
	return "«¿Has averiguado algo de %s? Estoy que no duermo...»" % str(q.get("target_name", ""))

func failure_reason(vm: VillageManager, q: Dictionary, by_key: Dictionary) -> String:
	var base: String = super.failure_reason(vm, q, by_key)
	if base != "":
		return base
	var s: Dictionary = _secret(vm, q)
	if (s.is_empty() or not bool(s.get("active", false))) and not is_done(vm, q):
		return "Lo que hubiera entre %s y otra persona se acabó antes de que lo averiguaras." % str(q.get("target_name", ""))
	return ""

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	var k: String = npc.get_person_key()
	if is_done(vm, q) or k == str(q.get("giver_key", "")) or k == str(q.get("target_key", "")):
		return
	ch_arr.insert(0, {"label": "🕵️ Preguntar si ha visto algo raro en %s" % str(q.get("target_name", "")), "next": "END", "action": "quest_affair_ask:" + str(q["id"])})

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if not action_id.begins_with("quest_affair_ask:"):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	if q.is_empty():
		return true
	var s: Dictionary = _secret(vm, q)
	if not s.is_empty() and (s.get("known_by", {}) as Dictionary).has(npc.get_person_key()):
		q["data"]["found"] = true
		VillageSecrets.player_learns(vm, s, str(s["b_name"]), "te lo contó %s" % npc.npc_name)
		qm.add_note(str(q["id"]), "%s los vio juntos: %s se ve con %s. Vuelve con %s." % [npc.npc_name, s["a_name"], s["b_name"], str(q.get("giver_name", ""))])
		npc._spawn_floating_text("🤫 «No le digas que te lo dije yo... los vi juntos.»", Color(1.0, 0.75, 0.85), -46.0)
	else:
		npc._spawn_floating_text("«¿%s? No he visto nada raro.»" % str(q.get("target_name", "")), Color(0.85, 0.85, 0.85), -46.0)
	return true

func done_dialogue(vm: VillageManager, q: Dictionary) -> Dictionary:
	var s: Dictionary = _secret(vm, q)
	var lover: String = str(s.get("b_name", "alguien"))
	var cheater: String = str(q.get("target_name", ""))
	return {"text": "«¿Y bien? Dímelo sin rodeos: ¿me engaña %s?»" % cheater, "choices": [
		{"label": "🗣️ La verdad: «Sí. Se ve con %s.»" % lover, "next": "END", "action": "quest_turn_in:truth"},
		{"label": "🤥 Mentir: «No, son imaginaciones tuyas.»", "next": "END", "action": "quest_turn_in:lie"},
		{"label": "🤫 Callar, y cobrarle a %s por tu silencio" % cheater, "next": "END", "action": "quest_turn_in:hush"},
	]}

func on_turn_in(vm: VillageManager, qm: Node, giver: VillageNPC, player: Node, q: Dictionary, action_full: String) -> void:
	var mode: String = action_full.get_slice(":", 1) if action_full.contains(":") else "truth"
	var s: Dictionary = _secret(vm, q)
	var cheater: VillageNPC = vm._get_npcs_by_person_key().get(str(q.get("target_key", "")), null)
	if mode == "truth":
		if not s.is_empty():
			VillageSecrets.partner_reaction(vm, s, giver, str(s["a_name"]), str(s["b_name"]), "se lo contó el forastero")
		pay_and_complete(qm, giver, player, q, gold, affinity, "Le contaste la verdad.")
	elif mode == "lie":
		giver.add_thought("Me quedo más tranquilo/a: eran tonterías mías (+4)", 4.0)
		pay_and_complete(qm, giver, player, q, gold, int(float(affinity) / 2.0), "Le mentiste para no hacerle daño.")
	else:
		var took: int = 0
		if cheater != null and not cheater.is_dead:
			took = mini(20, maxi(0, cheater.personal_gold))
			cheater.personal_gold -= took
			cheater.modify_affinity(-12)
			cheater._spawn_floating_text("😰 «Toma... y ni una palabra.»", Color.ORANGE, -46.0)
			if took > 0 and player != null and "inventory" in player and player.inventory:
				player.inventory.add_gold(took)
		pay_and_complete(qm, giver, player, q, 0, 0, "Callaste y le sacaste %d de oro a %s." % [took, str(q.get("target_name", ""))])
