extends Node

## Asalto físico (2026-11-05, Regla «todo es físico»). Al atardecer aparecen de verdad los atacantes por el camino del
## este (Raider). Los defensores reunidos (guardias y vecinos con arrojo) van a por el asaltante más cercano y le pegan
## cuando lo tienen al lado; el jugador puede pelear con sus armas. El asalto se decide por lo que pasa en el mapa:
## - todos abatidos o huidos → rechazado (recompensa si el jugador hirió a alguno);
## - uno llega a la plaza → saqueo;
## - a las 23:00 los que quedan se retiran: si queda al menos la mitad, se llevan botín.

const RaiderScript = preload("res://scripts/enemies/Raider.gd")

const SPAWN_POS: Vector2 = Vector2(1760, 50) # camino del este, más allá de la entrada
const DEFENDER_HIT_RANGE: float = 24.0
const GIVE_UP_HOUR: int = 23

var vm: Node = null
var raiders: Array = []
var total: int = 0
var killed: int = 0
var fled: int = 0
var looted: bool = false
var player_fought: bool = false
var _resolved: bool = false
var _tick: float = 0.0
var _def_hit_t: Dictionary = {} # instance_id del defensor -> segundos hasta su próximo golpe


## Crea los atacantes según el tipo de incursión. Devuelve cuántos salen.
func start(p_vm: Node, kind: String, strength: int, militia_bonus: int) -> int:
	vm = p_vm
	name = "RaidController"
	add_to_group("raid_controller")
	var r_kind: String = "boar" if kind == "boars" else "bandit"
	total = clampi(strength, 3, 6) if r_kind == "bandit" else clampi(strength, 3, 5)
	# Las barricadas pagadas los frenan: llegan más cansados (menos vida)
	var hp_mult: float = clampf(1.0 - 0.08 * float(militia_bonus), 0.6, 1.0)
	var parent: Node = vm.entities_root if ("entities_root" in vm and is_instance_valid(vm.entities_root)) else vm
	for i in range(total):
		var r = RaiderScript.new()
		parent.add_child(r)
		r.setup(r_kind, load("res://mapa/anclas.gd").mover(SPAWN_POS) + Vector2(float(i) * 16.0, float(i % 3) * 14.0 - 14.0), hp_mult)
		r.gone.connect(_on_raider_gone)
		raiders.append(r)
	return total


func alive_raiders() -> Array:
	return raiders.filter(func(r): return is_instance_valid(r) and not r.is_dead and not r._done)


func _on_raider_gone(r: Node, outcome: String) -> void:
	if bool(r.get("hit_by_player")):
		player_fought = true
	match outcome:
		"killed":
			killed += 1
		"fled":
			fled += 1
		"looted":
			looted = true
	check_outcome()


## Mira si el asalto ya está decidido por lo que ha pasado en el mapa.
func check_outcome() -> void:
	if _resolved or vm == null:
		return
	if looted:
		_resolve(false)
		return
	if alive_raiders().is_empty():
		_resolve(true)
		return
	if WorldClock != null and int(WorldClock.current_hour) >= GIVE_UP_HOUR:
		# Se retiran: si aún queda al menos la mitad, se llevan algo
		var left: int = alive_raiders().size()
		for r in alive_raiders():
			r.fleeing = true
		_resolve(left * 2 < total)


func _resolve(won: bool) -> void:
	_resolved = true
	var pl = vm.VillageNeeds.player_of(vm) if "VillageNeeds" in vm else null
	var inv = pl.get("inventory") if pl != null else null
	vm.VillageCulture.resolve_raid(vm, player_fought, inv if player_fought else null, 1 if won else -1)
	for r in alive_raiders():
		r.fleeing = true
	queue_free()


func _process(delta: float) -> void:
	if _resolved or vm == null:
		return
	_tick -= delta
	var retarget: bool = _tick <= 0.0
	if retarget:
		_tick = 0.5
	var alive: Array = alive_raiders()
	if alive.is_empty():
		check_outcome()
		return
	for n in vm.VillageCulture.raid_defenders(vm):
		if n.is_dead or n.is_downed or not n.is_conscious():
			continue
		var best = null
		var best_d: float = INF
		for r in alive:
			var d: float = n.global_position.distance_to(r.global_position)
			if d < best_d:
				best_d = d
				best = r
		if best == null:
			continue
		if retarget:
			if n.errand_kind != "raid_defend":
				n.start_errand("raid_defend", best.global_position)
			else:
				n.errand_pos = best.global_position
		var key: int = n.get_instance_id()
		var t: float = float(_def_hit_t.get(key, 0.8)) - delta
		if best_d <= DEFENDER_HIT_RANGE and t <= 0.0:
			t = 1.2
			var dmg := DamageData.new()
			var is_guard: bool = int(n.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)]
			dmg.amount = 12.0 if is_guard else 8.0
			dmg.source = n
			best.take_damage(dmg)
			if n.has_method("trigger_action_animation"):
				n.trigger_action_animation(0.6)
		_def_hit_t[key] = t
	if retarget and WorldClock != null and int(WorldClock.current_hour) >= GIVE_UP_HOUR:
		check_outcome()
