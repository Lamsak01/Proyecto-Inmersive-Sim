@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M3 «El jabalí del claro»: el carnicero (o quien caza) teme a los jabalíes y te pide que abatas uno.
## Ojo: si cazas de más y el bosque baja de su mínimo de jabalíes, nadie podrá cazarlos (EcosystemManager).

func _init() -> void:
	id = "boar_hunt"
	priority = 25
	gold = 30
	affinity = 12
	needs_alive_target = false

static func _eco(vm: VillageManager):
	return vm.get_tree().get_first_node_in_group("ecosystem_manager")

static func live_boars(vm: VillageManager) -> int:
	var eco = _eco(vm)
	return eco._get_live_animals(eco.boar_pool).size() if eco != null else 0

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	if int(giver.trade_role) != int(VillageNPC.TradeRole.BUTCHER):
		return {}
	var eco = _eco(vm)
	if eco == null or live_boars(vm) <= int(eco.MIN_SAFE_BOARS) + 1:
		return {}
	return {"target_key": "", "target_name": "un jabalí"}

func texts(off: Dictionary) -> Dictionary:
	return {
		"title": "El jabalí del claro",
		"ask": "«Hay un jabalí en el bosque que casi me abre en canal la última vez. No vuelvo a salir a cazar hasta que alguien se ocupe de él. ¿Te atreves?»",
		"desc": "%s quiere que abatas un jabalí del bosque del sur. Si le hieres, embiste: retírate a tiempo. Y no caces de más: si quedan pocos, el bosque dejará de dar jabalíes." % str(off.get("giver_name", "")),
	}

func init_data(vm: VillageManager, _giver: VillageNPC, _off: Dictionary) -> Dictionary:
	return {"start_boars": live_boars(vm)}

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	return live_boars(vm) < int(q["data"].get("start_boars", 0))

func progress_hint(_q: Dictionary) -> String:
	return "«¿Sigue ese bicho suelto? Hoy tampoco salgo a cazar...»"

func done_dialogue(vm: VillageManager, _q: Dictionary) -> Dictionary:
	var eco = _eco(vm)
	var few: bool = eco != null and live_boars(vm) <= int(eco.MIN_SAFE_BOARS)
	var txt: String = "«¡Así que ya no está! Toma, te lo has ganado.»"
	if few:
		txt += "\n«Aunque... quedan tan pocos jabalíes que me da que este año no habrá caza de jabalí para nadie.»"
	return {"text": txt, "choices": [{"label": "💰 Cobrar", "next": "END", "action": "quest_turn_in"}]}
