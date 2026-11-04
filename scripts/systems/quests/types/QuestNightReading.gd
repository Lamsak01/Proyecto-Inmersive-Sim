@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M16 «Lo que se lee de noche»: alguien que lee en la biblioteca ha visto vecinos salir de noche hacia el mismo sitio
## y quiere saber qué pasa. Es un gancho de la secta: se cumple cuando descubres la secta (por cualquier vía: espiar
## la reunión, rumores, que te inviten). Al volver eliges: contárselo todo (más sospechas en el pueblo) o callar.
## Toca VillageSect y la biblioteca (VillageCulture).

const VillageSect = preload("res://scripts/systems/VillageSect.gd")
const RECENT_READ: int = 7

func _init() -> void:
	id = "night_reading"
	priority = 26
	gold = 25
	affinity = 12
	needs_alive_target = false

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	if not VillageSect.active(vm) or VillageSect.player_knows_sect(vm) or VillageSect.is_member(vm, giver):
		return {}
	if not giver.has_meta("read_day") or day() - int(giver.get_meta("read_day")) > RECENT_READ:
		return {}
	var st: Dictionary = VillageSect.state(vm)
	return {"target_key": "", "target_name": "", "when": VillageSect.WEEKDAY_NAMES[int(st.get("meet_day", 4)) % 7], "where": VillageSect.meeting_place_name(vm)}

func texts(off: Dictionary) -> Dictionary:
	return {
		"title": "Lo que se lee de noche",
		"ask": "«Leyendo en la biblioteca encontré un libro viejo con unos símbolos... y luego vi esos mismos símbolos en una puerta. Hay gente que sale de noche %s. ¿Me ayudas a saber qué traman?»" % str(off.get("when", "")),
		"desc": "%s cree que algunos vecinos se reúnen en secreto %s por la noche (quizá %s). Averigua qué pasa: vigila esa noche o escucha los rumores. Luego decide qué le cuentas." % [str(off.get("giver_name", "")), str(off.get("when", "")), str(off.get("where", ""))],
	}

func is_done(vm: VillageManager, _q: Dictionary) -> bool:
	return VillageSect.player_knows_sect(vm)

func progress_hint(_q: Dictionary) -> String:
	return "«Anoche volví a oír pasos en la calle, tarde... ¿Has descubierto algo?»"

func failure_reason(vm: VillageManager, q: Dictionary, by_key: Dictionary) -> String:
	var base: String = super.failure_reason(vm, q, by_key)
	if base != "":
		return base
	if not VillageSect.active(vm) and not is_done(vm, q):
		return "Las reuniones nocturnas se acabaron sin que supieras qué eran."
	return ""

func done_dialogue(vm: VillageManager, _q: Dictionary) -> Dictionary:
	var choices: Array = [
		{"label": "🗣️ Contarle la verdad: es %s" % VillageSect.sect_name(vm), "next": "END", "action": "quest_turn_in:truth"},
		{"label": "🤐 «No era nada. Gente que juega a los dados a escondidas.»", "next": "END", "action": "quest_turn_in:hide"},
	]
	return {"text": "«¿Y bien? ¿Qué hacen de noche?»", "choices": choices}

func on_turn_in(vm: VillageManager, qm: Node, giver: VillageNPC, player: Node, q: Dictionary, action_full: String) -> void:
	if action_full.ends_with(":hide"):
		giver.add_thought("Solo eran jugadores de dados... qué alivio (+2)", 2.0)
		if VillageSect.player_member(vm):
			vm.VillageFaith.add_rep(vm, "sect", 3) # Protegiste a los tuyos
		pay_and_complete(qm, giver, player, q, int(float(gold) / 2.0), int(float(affinity) / 2.0), "Le ocultaste lo de la secta.")
		return
	# La verdad corre: sube la sospecha y quien pregunta mira mal a los miembros que conoces
	VillageSect._add_suspicion(vm, 15)
	for m in VillageSect.member_nodes(vm):
		if VillageSect.known_member(vm, m):
			giver.modify_npc_relationship(m, -15, "Es de %s" % VillageSect.sect_name(vm), true)
	giver.add_thought("En el valle hay una secta... (-4)", -4.0)
	pay_and_complete(qm, giver, player, q, gold, affinity, "Le contaste lo de la secta.")
