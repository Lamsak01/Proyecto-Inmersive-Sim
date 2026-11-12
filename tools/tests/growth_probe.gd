extends SceneTree

## V7: sonda de crecimiento y rendimiento. Uso:
##   flatpak run org.godotengine.Godot --headless --path . --fixed-fps 60 -s tools/tests/growth_probe.gd -- <días> <semilla>
## Fase 1: deja correr la partida <días> días (sin jugador activo) y apunta cada día la población, llegadas, marchas,
##   casas, nacimientos, niños y el atractivo del pueblo.
## Fase 2: si no se llegó a 50 vecinos, completa hasta 50 con las reglas del juego (casas en solares libres y
##   recién llegados que se mudan a ellas) y mide cuánto cuesta cada fotograma con el jugador en la plaza y lejos.
## Sin pantalla no se mide el dibujado; solo la lógica (proceso y físicas).

const TARGET: int = 50

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var days: int = int(args[0]) if args.size() > 0 else 30
	var seed_v: int = int(args[1]) if args.size() > 1 else 11
	seed(seed_v)
	var packed: PackedScene = load("uid://dsoiuct8kdsk3")
	root.add_child(packed.instantiate())
	await process_frame
	await process_frame
	var vm = root.find_child("VillageManager", true, false)
	var wc = root.get_node("/root/WorldClock")
	var mig = load("res://scripts/systems/VillageMigration.gd")
	var fam = load("res://scripts/systems/VillageFamily.gd")
	var lots = load("res://scripts/systems/VillageLots.gd")
	vm.social_director.rng.seed = seed_v
	wc.set_persistent_time_scale(8.0)
	var t_start: int = Time.get_ticks_msec()
	var start_day: int = int(wc.current_day)
	print("START day=%d pop=%d" % [start_day, mig.population(vm)])
	# ---------------------------------------------------------------- fase 1
	var last_day: int = start_day
	var max_pop: int = 0
	while int(wc.current_day) < start_day + days:
		await create_timer(1.0).timeout
		if int(wc.current_day) != last_day:
			last_day = int(wc.current_day)
			var ms: Dictionary = mig.state(vm)
			var fs: Dictionary = fam.state(vm)
			var kids: int = mig.residents(vm).filter(func(n): return fam.is_child(n)).size()
			var built: int = 0
			for l in lots.lots():
				var st: Dictionary = lots.lot(vm, str(l["id"]))
				if str(st["kind"]) == "house" and str(st["status"]) == "built":
					built += 1
			var pop: int = mig.population(vm)
			max_pop = maxi(max_pop, pop)
			print("DAY %d pop=%d arrivals=%d departures=%d houses_built=%d site=%s free_beds=%d pregnant=%d births=%d kids=%d grown=%d teacher=%s score=%.2f parts=%s" % [
				last_day, pop, int(ms["arrivals"]), int(ms["departures"]), built, lots.active_site(vm), mig.free_house_beds(vm),
				(fs["pregnancies"] as Dictionary).size(), int(fs["births"]), kids, int(fs["grown_up"]), str(fam.teacher_of(vm) != null),
				float(ms["last_score"]), _fmt(ms["last_parts"])])
	print("MEAL_FAILS %s" % str(mig.state(vm).get("meal_fails", {})))
	var loans_open: Array = []
	for l in lots.lots():
		var lst: Dictionary = lots.lot(vm, str(l["id"]))
		if lst.has("loan"):
			loans_open.append("%s:%s debe %d (impagos %d)" % [str(l["id"]), str(lst["loan"]["lender_name"]), int(lst["loan"]["owed"]), int(lst["loan"]["missed"])])
	var deaths: Array = []
	for ce in vm.chronicle:
		if str(ce.get("type", "")) in ["death_found", "illness_death"]:
			deaths.append(str(ce.get("text", "")))
	print("DEATHS %d %s rations_served=%d" % [deaths.size(), str(deaths), int(vm.town_state.get("rations_served", 0))])
	print("TREASURY %d houses_ordered=%d loans_given=%d open=%s" % [int(vm.town_state.get("treasury", 0)), int(mig.state(vm)["houses_ordered"]), int(mig.state(vm).get("loans_given", 0)), str(loans_open)])
	print("PHASE1 days=%d max_pop=%d real_seconds=%.0f" % [days, max_pop, float(Time.get_ticks_msec() - t_start) / 1000.0])
	# ---------------------------------------------------------------- fase 2
	wc.set_persistent_time_scale(1.0)
	var added: int = 0
	while mig.population(vm) < TARGET:
		if mig.free_house_beds(vm) <= 0:
			var free: Array = lots.free_lots(vm, "house")
			if free.is_empty():
				break
			var st: Dictionary = lots.lot(vm, str(free[0]))
			st["status"] = "built"
			st["kind"] = "house"
			st["progress"] = 1.0
			st["title"] = "🏠 Casa (sonda)"
			st["payer"] = "town"
			st["beds"] = lots._house_beds(str(free[0]))
			st["residents"] = []
			lots._draw_lot(vm, str(free[0]), st)
		var n = mig._spawn_one(vm, mig.SETTLER_KINDS[0], added)
		if not mig.move_into_house(vm, n):
			n.bed_position = mig.tavern_guest_beds()[added % 3]
		n.global_position = n.bed_position + Vector2(0, 20)
		added += 1
	print("PHASE2 topped_up=%d pop=%d" % [added, mig.population(vm)])
	for cfg in [["plaza", Vector2(412, 54)], ["far", Vector2(-700, 48)]]:
		wc.current_hour = 14
		wc.current_minute = 0
		var pl = get_first_node_in_group("player")
		if pl != null:
			pl.global_position = cfg[1]
		for _w in range(240):
			await process_frame
		var proc_tot: float = 0.0
		var phys_tot: float = 0.0
		var worst: float = 0.0
		var worst_at: String = ""
		var slow: int = 0
		var t0: int = Time.get_ticks_usec()
		var tf: int = Time.get_ticks_usec()
		for _f in range(600):
			await process_frame
			var p: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			var ph: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
			var wall_f: float = float(Time.get_ticks_usec() - tf) / 1000.0
			tf = Time.get_ticks_usec()
			proc_tot += p
			phys_tot += ph
			if wall_f > 33.0:
				slow += 1
			if wall_f > worst:
				worst = wall_f
				worst_at = "frame %d, %02d:%02d" % [_f, int(wc.current_hour), int(wc.current_minute)]
		print("PERF50 where=%s npcs=%d frame_wall=%.2fms process=%.2fms physics=%.2fms worst_wall=%.2fms (%s) frames_over_33ms=%d" % [cfg[0], mig.population(vm),
			float(Time.get_ticks_usec() - t0) / 1000.0 / 600.0, proc_tot / 600.0, phys_tot / 600.0, worst, worst_at, slow])
	var day: int = int(wc.current_day)
	var tt: int = Time.get_ticks_usec()
	for _h in range(3):
		vm._on_hour_passed(day, int(wc.current_hour))
	print("PERF50 hour_tick=%.2fms" % (float(Time.get_ticks_usec() - tt) / 3000.0))
	print("GROWTH PROBE DONE")
	quit(0)

func _fmt(d) -> String:
	if not d is Dictionary:
		return "{}"
	var parts: Array[String] = []
	for k in (d as Dictionary).keys():
		parts.append("%s:%.2f" % [str(k), float(d[k])])
	return "{" + ",".join(parts) + "}"
