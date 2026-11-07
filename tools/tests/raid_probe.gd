extends SceneTree

## B5: equilibrio de los asaltos sin el jugador. Uso (sin ventana, unos minutos):
##   flatpak run org.godotengine.Godot --headless --fixed-fps 60 --path . -s tools/tests/raid_probe.gd -- 40 3
## (vecinos, repeticiones por caso). 1) Frecuencia: cuánto sube la amenaza al día según lo que atrae a los bandidos.
## 2) Peleas: asaltos de fuerza 3–6, bandidos y jabalíes, con el jugador lejos; quién gana y cuántos defensores caen.

const MAX_FRAMES: int = 60 * 240 # 4 min de juego en tiempo real por asalto como mucho

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var target: int = int(args[0]) if args.size() > 0 else 40
	var reps: int = int(args[1]) if args.size() > 1 else 3
	seed(11)
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	await process_frame
	await process_frame
	var vm = root.find_child("VillageManager", true, false)
	var wc = root.get_node("/root/WorldClock")
	var cu = vm.VillageCulture
	var mig = vm.VillageMigration
	if target > 0:
		mig.seed_start_population(vm, target)
	for _i in range(60):
		await process_frame
	var pl = get_first_node_in_group("player")
	if pl != null:
		pl.global_position = Vector2(-700, 48) # lejos: no se mete
	print("RAID_INFO npcs=%d defenders=%d volunteers=%d defense_power=%d" % [vm.VillageNeeds.living(vm).size(), cu.raid_defenders(vm).size(), cu.raid_volunteers(vm).size(), cu.defense_power(vm)])
	# 1) Frecuencia
	var tr0: int = int(vm.town_state.get("treasury", 0))
	for tr in [tr0, 350, 600, 1000]:
		vm.town_state["treasury"] = tr
		var lure: int = cu.raid_lure(vm)
		var det: int = int(float(cu.defense_power(vm)) / 3.0)
		var per_day: int = lure - 1 - det
		print("RAID_FREQ treasury=%d routes_active=%d lure=%d deterrent=%d threat_per_day=%d days_to_warn=%s" % [tr, _active_routes(cu, vm), lure, det, per_day, str(ceili(float(cu.RAID_THREAT_WARN) / float(per_day))) if per_day > 0 else "nunca"])
	vm.town_state["treasury"] = tr0
	# 2) Peleas
	for kind in ["bandits", "boars"]:
		for strength in [3, 4, 5, 6]:
			for rep in range(reps):
				await _one_raid(vm, wc, cu, kind, strength, rep)
	quit(0)

func _active_routes(cu, vm) -> int:
	var c: int = 0
	for r in cu.trade_routes_of(vm).values():
		if bool(r.get("active", false)):
			c += 1
	return c

func _one_raid(vm, wc, cu, kind: String, strength: int, rep: int) -> void:
	# Defensores sanos y en su sitio antes de cada asalto
	for n in vm.VillageNeeds.living(vm):
		if n.health_comp != null:
			n.health_comp.heal(999.0, true)
		n.is_downed = false
	var rd: Dictionary = cu.raids_state(vm)
	var raids_rep0: int = int(rd.get("raids_repelled", 0))
	var dead0: int = _dead(vm)
	wc.current_hour = 16
	wc.current_minute = 0
	cu.start_raid_warning(vm, kind)
	rd["active_raid"]["strength"] = strength
	cu.raid_on_hour(vm, 16)
	for _i in range(60 * 20): # 20 s para que lleguen a la entrada
		await physics_frame
	wc.current_hour = 18
	cu.raid_on_hour(vm, 18)
	var ctl = get_first_node_in_group("raid_controller")
	var frames: int = 0
	var downed_max: int = 0
	while ctl != null and is_instance_valid(ctl) and not ctl.is_queued_for_deletion() and frames < MAX_FRAMES:
		await physics_frame
		frames += 1
		if frames % 30 == 0:
			downed_max = maxi(downed_max, _downed(vm))
	var undecided: bool = ctl != null and is_instance_valid(ctl) and not ctl.is_queued_for_deletion()
	if undecided:
		wc.current_hour = 23
		ctl.check_outcome()
		await physics_frame
	var won: bool = int(rd.get("raids_repelled", 0)) > raids_rep0
	print("RAID_FIGHT kind=%s strength=%d rep=%d result=%s seconds=%.0f defenders_downed_max=%d villagers_died=%d%s" % [kind, strength, rep, "rechazado" if won else "saqueo", float(frames) / 60.0, downed_max, _dead(vm) - dead0, " (sin decidir en 4 min; se retiran a las 23 h)" if undecided else ""])
	for r in get_nodes_in_group("raiders"):
		if is_instance_valid(r):
			r.queue_free()
	for _i in range(30):
		await physics_frame

func _dead(vm) -> int:
	var c: int = 0
	for n in get_nodes_in_group("village_npcs"):
		if n.is_dead:
			c += 1
	return c

func _downed(vm) -> int:
	var c: int = 0
	for n in vm.VillageNeeds.living(vm):
		if n.is_downed or not n.is_conscious():
			c += 1
	return c
