extends SceneTree

## Sonda de mecánicas PF–PQ: deja correr la partida <días> días SIN que el jugador haga nada y cuenta cuántas veces
## ocurre cada cosa nueva por sí sola (entradas de la crónica y estado interno).
## Uso: flatpak run org.godotengine.Godot --headless --path . --fixed-fps 60 -s tools/tests/feature_probe.gd -- <días> <semilla>

const WATCH_TYPES: Array = [
	"master_artisan", "obsession_started", "school_graduate", "amputation", "prosthetic",
	"raid_warning", "raid_repelled", "raid_suffered", "tech_unlocked", "house_expanded",
	"companion_left", "player_shop_robbed", "animal_bred", "animal_starved", "grid_sabotage",
	"trade_route", "main_story", "theft_caught", "fight", "construction",
]

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
	vm.social_director.rng.seed = seed_v
	wc.set_persistent_time_scale(8.0)
	var t_start: int = Time.get_ticks_msec()
	var start_day: int = int(wc.current_day)
	var seen: Dictionary = {}
	var counts: Dictionary = {}
	var examples: Dictionary = {}
	var last_day: int = start_day
	print("START day=%d pop=%d" % [start_day, mig.population(vm)])
	while int(wc.current_day) < start_day + days:
		await create_timer(1.0).timeout
		if int(wc.current_day) != last_day:
			last_day = int(wc.current_day)
			for ce in vm.chronicle:
				var key: String = "%s|%s|%s" % [str(ce.get("day", "")), str(ce.get("type", "")), str(ce.get("text", ""))]
				if seen.has(key):
					continue
				seen[key] = true
				var t: String = str(ce.get("type", ""))
				counts[t] = int(counts.get(t, 0)) + 1
				if not examples.has(t):
					examples[t] = str(ce.get("text", ""))
			print("DAY %d pop=%d" % [last_day, mig.population(vm)])
	print("---- CRONICA (veces en %d días) ----" % days)
	for t in WATCH_TYPES:
		print("EV %s=%d %s" % [t, int(counts.get(t, 0)), ("«" + str(examples[t]) + "»") if examples.has(t) else ""])
	var other: Array = []
	for t in counts.keys():
		if not (t in WATCH_TYPES):
			other.append("%s=%d" % [t, int(counts[t])])
	other.sort()
	print("OTROS %s" % ", ".join(other))
	# ---- estado interno
	var fame = vm.VillageFame.state(vm)
	var tiers: Dictionary = {}
	var top: Array = []
	for k in (fame["scores"] as Dictionary).keys():
		var sc: int = int(fame["scores"][k])
		var tl: String = vm.VillageFame.tier_label(sc)
		tiers[tl if tl != "" else "corriente"] = int(tiers.get(tl if tl != "" else "corriente", 0)) + 1
		top.append(sc)
	top.sort()
	print("FAMA con_puntos=%d niveles=%s max=%s min=%s maestros=%d obsesiones_activas=%d" % [(fame["scores"] as Dictionary).size(), str(tiers), str(top.back() if not top.is_empty() else 0), str(top.front() if not top.is_empty() else 0), (fame["masters"] as Dictionary).size(), (fame["obsessions"] as Dictionary).size()])
	var stocks: Array = []
	for mk in (fame["masters"] as Dictionary).keys():
		stocks.append(int(fame["masters"][mk].get("stock", 0)))
	print("MAESTROS stock=%s" % str(stocks))
	var cu = vm.VillageCulture
	var rd: Dictionary = cu.raids_state(vm)
	print("INCURSIONES amenaza=%d activa=%s rechazadas=%d sufridas=%d" % [int(rd["threat"]), str(not (rd["active_raid"] as Dictionary).is_empty()), int(rd["raids_repelled"]), int(rd["raids_suffered"])])
	print("INVESTIGACION activa=%s desbloqueadas=%s" % [str(cu.research_state(vm)["active_tech"]), str((cu.research_state(vm)["unlocked"] as Dictionary).keys())])
	var active_routes: int = 0
	for r in cu.trade_routes_of(vm).values():
		if bool(r.get("active", false)):
			active_routes += 1
	print("RUTAS activas=%d BOSQUE=%s" % [active_routes, str(cu.forest_state(vm))])
	var hs: Dictionary = vm.VillageHousing.state(vm)
	var herd: Array = []
	for a in (hs["ranch_herd"] as Array):
		herd.append(str(a.get("stage", "")))
	print("RANCHO rebaño=%s" % str(herd))
	print("AMPUTACIONES %d" % (vm.VillageIllness.amputations_of(vm) as Dictionary).size())
	print("ALCANTARILLAS monedas_perdidas=%d" % int(vm.VillageUnderworld.sewers_state(vm).get("lost_coins_pool", 0)))
	print("ESCUELA clases_por_alumno=%s" % str(vm.VillageFamily.state(vm).get("pupil_lessons", {})))
	print("POBLACION %d tesoro=%d" % [mig.population(vm), int(vm.town_state.get("treasury", 0))])
	print("PROBE DONE days=%d real_seconds=%.0f" % [days, float(Time.get_ticks_msec() - t_start) / 1000.0])
	quit()
