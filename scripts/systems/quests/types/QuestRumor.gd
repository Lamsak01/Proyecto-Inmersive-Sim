@tool
extends "res://scripts/systems/quests/QuestType.gd"

## «¿Quién va contando eso de mí?»: una calumnia le llega al afectado de segunda mano y no sabe quién la empezó.
## Se sigue la cadena preguntando «¿quién te lo contó?» y al final se señala a alguien (sea verdad o no) o se confiesa.

const OFFER_CHANCE: float = 0.5

func _init() -> void:
	id = "rumor"
	trigger = "event"
	gold = 25
	affinity = 10
	needs_alive_target = false # No hay objetivo conocido

## Oferta para el afectado a partir del evento de calumnia que le ha llegado.
func make_offer(ev: Dictionary, teller: VillageNPC) -> Dictionary:
	var origin: String = "player" if str(ev.get("type", "")) == "player_slander" else str(ev.get("actor_id", ""))
	return {"target_key": "", "target_name": "",
		"rumor": {"origin": origin, "heard_from": (ev.get("heard_from", {}) as Dictionary).duplicate(), "first_teller": teller.get_person_key(), "first_teller_name": teller.npc_name}}

func texts(off: Dictionary) -> Dictionary:
	var ft: String = str((off.get("rumor", {}) as Dictionary).get("first_teller_name", "alguien"))
	return {
		"title": "¿Quién va contando eso de %s?" % str(off.get("giver_name", "")),
		"ask": "«Me ha dicho %s que por ahí se cuentan cosas horribles de mí. Quiero saber quién empezó. ¿Me ayudas a averiguarlo?»" % ft,
		"desc": "Alguien va hablando mal de %s. Se lo contó %s: pregunta a cada uno «¿quién te lo contó?» hasta dar con el origen y vuelve a decírselo. Puedes decir la verdad... o señalar a otro." % [str(off.get("giver_name", "")), ft],
	}

func init_data(_vm: VillageManager, _giver: VillageNPC, off: Dictionary) -> Dictionary:
	return {"rumor": off.get("rumor", {}), "asked": {}}

func is_done(_vm: VillageManager, q: Dictionary) -> bool:
	return not (q["data"].get("asked", {}) as Dictionary).is_empty()

func progress_hint(_q: Dictionary) -> String:
	return "«¿Sabes ya quién lo empezó?»"

## Respuesta de `npc` a «¿quién te contó lo que se dice de...?».
func answer(vm: VillageManager, npc: VillageNPC, rumor: Dictionary) -> Dictionary:
	var nk: String = npc.get_person_key()
	if npc.affinity < 0:
		return {"text": "«Eso no es asunto tuyo.»", "source": ""}
	if str(rumor.get("origin", "")) == nk:
		return {"text": "«¿Yo? Nadie me lo contó... ¿Por qué lo preguntas?» (Se pone nervioso/a.)", "source": "self"}
	var src: String = str((rumor.get("heard_from", {}) as Dictionary).get(nk, ""))
	if src == "player":
		return {"text": "«¡Pero si me lo contaste tú!»", "source": "player"}
	var src_npc: VillageNPC = vm._get_npcs_by_person_key().get(src, null)
	if src_npc == null:
		return {"text": "«Ya no me acuerdo de quién me lo dijo.»", "source": ""}
	return {"text": "«Me lo contó %s.»" % src_npc.npc_name, "source": src}

## Quién puede ser señalado: los que se pusieron nerviosos y los que contaron el chisme.
static func suspects(q: Dictionary) -> Array[String]:
	var res: Array[String] = []
	var asked: Dictionary = q["data"].get("asked", {})
	for k in asked.keys():
		var v: String = str(asked[k])
		var cand: String = str(k) if v == "self" else v
		if cand != "" and cand != "player" and cand != str(q.get("giver_key", "")) and not cand in res:
			res.append(cand)
	return res

func done_dialogue(vm: VillageManager, q: Dictionary) -> Dictionary:
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var choices: Array = []
	for sk in suspects(q):
		if by_key.has(sk):
			choices.append({"label": "👉 «Fue %s.»" % (by_key[sk] as VillageNPC).npc_name, "next": "END", "action": "quest_turn_in:accuse:" + sk})
	choices.append({"label": "✋ «Fui yo. Lo siento.»", "next": "END", "action": "quest_turn_in:confess"})
	choices.append({"label": "⬅️ «Aún no lo sé.»", "next": "start"})
	return {"text": "«¿Has averiguado quién va diciendo esas cosas de mí?»", "choices": choices}

func on_turn_in(vm: VillageManager, qm: Node, giver: VillageNPC, player: Node, q: Dictionary, action_full: String) -> void:
	if action_full.get_slice(":", 1) == "accuse":
		var accused: VillageNPC = vm._get_npcs_by_person_key().get(action_full.get_slice(":", 2), null)
		if accused == null:
			return
		giver.modify_npc_relationship(accused, -15, "El forastero le contó que %s iba hablando mal de él/ella" % accused.npc_name)
		q["data"]["accused"] = accused.get_person_key()
		pay_and_complete(qm, giver, player, q, gold, affinity, "Señalaste a %s." % accused.npc_name)
		giver._spawn_floating_text("😠 «¡Así que fue %s!»" % accused.npc_name, Color.ORANGE, -46.0)
	else:
		q["data"]["accused"] = "player"
		pay_and_complete(qm, giver, player, q, 0, -10, "Confesaste que fuiste tú.")
		giver._spawn_floating_text("😞 «No me lo esperaba de ti...»", Color(0.75, 0.80, 1.0), -46.0)

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, diag: Dictionary, ch_arr: Array) -> void:
	var gk: String = npc.get_person_key()
	var rumor: Dictionary = q["data"].get("rumor", {})
	if str(q.get("giver_key", "")) == gk or (not (rumor.get("heard_from", {}) as Dictionary).has(gk) and str(rumor.get("origin", "")) != gk):
		return
	var node_id: String = "quest_rumor_%s" % str(q["id"])
	ch_arr.insert(0, {"label": "🔎 ¿Quién te contó lo que se dice de %s?" % str(q.get("giver_name", "")), "next": node_id, "action": "quest_rumor_ask:%s" % str(q["id"])})
	diag[node_id] = {"text": str(answer(vm, npc, rumor)["text"]), "choices": [{"label": "⬅️ Volver a la conversación", "next": "start"}]}

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if not action_id.begins_with("quest_rumor_ask:"):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	if q.is_empty() or str(q.get("status", "")) != "active":
		return true
	var gk: String = npc.get_person_key()
	var ans: Dictionary = answer(vm, npc, q["data"].get("rumor", {}))
	var asked: Dictionary = q["data"].get("asked", {})
	if str(ans["source"]) != "" and not asked.has(gk):
		asked[gk] = str(ans["source"])
		q["data"]["asked"] = asked
		qm.add_note(str(q["id"]), "%s: %s" % [npc.npc_name, str(ans["text"])])
	return true
