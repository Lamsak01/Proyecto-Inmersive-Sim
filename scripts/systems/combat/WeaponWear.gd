extends RefCounted

## C7 fase 4b: las armas del jugador se mellan con el uso y el herrero las arregla. Sin `class_name`: `preload`.
## Estado en `Player.weapon_wear` = {nombre del arma en minúsculas: estado 0–100}; sin entrada = 100 (como nueva).
## Mellada (< 60) pega y corta menos, hasta un 65 % en 0. Nunca se rompe: solo empeora.

const WORN_AT: float = 60.0 ## por debajo, «mellada»
const BADLY_WORN_AT: float = 25.0 ## por debajo, «muy mellada»
const MIN_MULT: float = 0.65 ## lo que pega un arma en estado 0
const WEAR_LIVING: float = 0.5 ## por golpe a una persona o un animal
const WEAR_PROPER_TOOL: float = 0.25 ## herramienta en su trabajo (hacha al árbol, pico a la roca…)
const WEAR_WRONG_USE: float = 1.2 ## espada contra madera o piedra
const PROPER_TOOLS: Array[String] = ["axe", "pickaxe", "hammer", "sickle"]
const REPAIR_GOLD_PER_POINT: float = 0.125 ## 8 puntos de estado = 1 de oro
const NAMES_ES: Dictionary = {"sword": "espada", "hammer": "martillo", "axe": "hacha", "pickaxe": "pico", "sickle": "hoz"}

static func _key(weapon) -> String:
	return str(weapon.get("name")).to_lower() if weapon != null else ""

static func condition(player, weapon) -> float:
	if player == null or weapon == null or not ("weapon_wear" in player):
		return 100.0
	return float(player.weapon_wear.get(_key(weapon), 100.0))

## Multiplicador de daño, sangrado y eficiencia según el estado.
static func damage_mult_for(cond: float) -> float:
	if cond >= WORN_AT:
		return 1.0
	return lerpf(MIN_MULT, 1.0, clampf(cond / WORN_AT, 0.0, 1.0))

static func damage_mult(player, weapon) -> float:
	return damage_mult_for(condition(player, weapon))

## Desgaste de un golpe que ha dado. Avisa al cruzar «mellada» y «muy mellada».
static func wear_on_hit(player, weapon, target: Node) -> void:
	if player == null or weapon == null or bool(weapon.get("is_ranged")) or not ("weapon_wear" in player):
		return
	var k: String = _key(weapon)
	if not NAMES_ES.has(k):
		return # puños, regadera, caña…: no se mellan
	var amount: float = WEAR_LIVING
	if target != null and target.is_in_group("destructible"):
		amount = WEAR_PROPER_TOOL if k in PROPER_TOOLS else WEAR_WRONG_USE
	var before: float = condition(player, weapon)
	var after: float = maxf(0.0, before - amount)
	player.weapon_wear[k] = after
	if player.has_method("show_hint"):
		if before >= WORN_AT and after < WORN_AT:
			player.show_hint("🗡️ Tu %s se ha mellado: pega menos. El herrero puede arreglarla." % NAMES_ES[k])
		elif before >= BADLY_WORN_AT and after < BADLY_WORN_AT:
			player.show_hint("🗡️ Tu %s está muy mellada." % NAMES_ES[k])

static func repair_cost(player) -> int:
	if player == null or not ("weapon_wear" in player):
		return 0
	var missing: float = 0.0
	for k in player.weapon_wear:
		missing += 100.0 - float(player.weapon_wear[k])
	if missing < 4.0:
		return 0
	return maxi(2, int(ceil(missing * REPAIR_GOLD_PER_POINT)))

static func armor_dent_repair_cost(player) -> int:
	if player == null:
		return 0
	var hc = player.get_node_or_null("HealthComponent")
	if hc == null or not ("armor_dents" in hc):
		return 0
	var dents: int = int(hc.armor_dents)
	return dents * 4 if dents > 0 else 0

static func add_dialogue_choices(vm, npc, _diag: Dictionary, ch_arr: Array) -> void:
	if npc == null or int(npc.trade_role) != int(VillageNPC.TradeRole.BLACKSMITH):
		return
	var pl = npc._get_player() if npc.has_method("_get_player") else null
	var dent_cost: int = armor_dent_repair_cost(pl)
	if dent_cost > 0:
		var hc_d = pl.get_node_or_null("HealthComponent")
		var n_dents: int = int(hc_d.armor_dents) if hc_d != null else 1
		ch_arr.insert(0, {"label": "🛡️⚒️ Desabollar coraza y casco (%d impacto(s) de bala, -%d Oro)" % [n_dents, dent_cost], "next": "END", "action": "weapon_wear_repair_dents"})
	var cost: int = repair_cost(pl)
	if cost > 0:
		ch_arr.insert(0, {"label": "⚒️ Afilar y enderezar tus armas (-%d Oro)" % cost, "next": "END", "action": "weapon_wear_repair"})

static func on_player_action(_vm, npc, action_id: String, inv) -> void:
	var pl = npc._get_player() if npc.has_method("_get_player") else null
	if action_id == "weapon_wear_repair_dents":
		var d_cost: int = armor_dent_repair_cost(pl)
		if d_cost <= 0:
			npc._spawn_floating_text("«Tu coraza no tiene abolladuras de bala.»", Color.LIGHT_GRAY, -46.0)
			return
		if inv == null or int(inv.gold) < d_cost:
			npc._spawn_floating_text("«Son %d de oro para sacar esos bollos de plomo en el yunque.»" % d_cost, Color.CORAL, -46.0)
			return
		inv.add_gold(-d_cost)
		npc.personal_gold += d_cost
		var hc = pl.get_node_or_null("HealthComponent") if pl != null else null
		if hc != null and hc.has_method("repair_armor_dents"):
			hc.call("repair_armor_dents")
		npc._spawn_floating_text("🛡️⚒️ «Coraza desabollada en el yunque: ni rastro de los balazos.»", Color(0.82, 0.92, 1.0), -46.0)
		return
	if action_id != "weapon_wear_repair":
		return
	var cost: int = repair_cost(pl)
	if cost <= 0:
		npc._spawn_floating_text("«Tus armas están bien. Vuelve cuando las hayas usado.»", Color.LIGHT_GRAY, -46.0)
		return
	if inv == null or int(inv.gold) < cost:
		npc._spawn_floating_text("«Son %d de oro. La piedra de afilar no gira sola.»" % cost, Color.CORAL, -46.0)
		return
	inv.add_gold(-cost)
	npc.personal_gold += cost
	pl.weapon_wear.clear()
	npc._spawn_floating_text("⚒️ «Listo: filo nuevo y el mango bien prieto.»", Color(1.0, 0.85, 0.5), -46.0)
