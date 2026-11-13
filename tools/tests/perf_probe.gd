extends SceneTree

## V1: mide cuánto cuesta cada fotograma con más vecinos. Uso:
##   flatpak run org.godotengine.Godot --headless --path . -s tools/tests/perf_probe.gd -- 18,30,50,70
## Sin pantalla no se mide el dibujado; solo la lógica (proceso y físicas), que es lo que crece con la población.

const FRAMES: int = 600
const WARMUP: int = 120

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var targets: Array = []
	for t in (args[0] if args.size() > 0 else "18,30,50,70").split(","):
		targets.append(int(t))
	seed(7)
	var packed: PackedScene = load("uid://dsoiuct8kdsk3")
	root.add_child(packed.instantiate())
	await process_frame
	await process_frame
	var vm = root.find_child("VillageManager", true, false)
	var wc = root.get_node("/root/WorldClock")
	wc.current_hour = 14 # Tarde: trabajan, comen y charlan (lo más caro)
	var tex: Texture2D = vm._load_tex("res://assests/world/village/villager_innkeeper.png")
	var beds: Array = [Vector2(342, -252), Vector2(400, -252), Vector2(435, -252), Vector2(468, -252), Vector2(502, -252)].map(func(b: Vector2) -> Vector2: return vm.VillageTavern.al_mundo(b)) # al mundo
	var spots: Array = [Vector2(412, 54), Vector2(745, 312), Vector2(300, 120), Vector2(560, 80), Vector2(200, -60), Vector2(650, -40)].map(func(q: Vector2) -> Vector2: return q * vm.Mapa3D.E) # al mundo
	for target in targets:
		var living: int = _living()
		var i: int = 0
		while living < target:
			var n = vm._spawn_generated_newcomer("NPC_Perf_", 0, 0, "Forastero (prueba)", tex, spots[i % spots.size()], beds[i % beds.size()], {}, spots[0], "none", "")
			n.global_position = spots[i % spots.size()] + Vector2(float(i % 7) * 9.0, float(i % 5) * 9.0)
			living += 1
			i += 1
		for cfg in [[false, Vector2(-700, 48)], [true, Vector2(-700, 48)], [false, Vector2(412, 54)], [true, Vector2(412, 54)], [false, Vector2(412, 54), "npcs_off"], [false, Vector2(-700, 48), "npcs_off"], [false, Vector2(412, 54)]]:
			var lod: bool = cfg[0]
			wc.current_hour = 14
			wc.current_minute = 0
			load("res://scripts/enemies/VillageNPC.gd").lod_enabled = lod
			var pl = get_first_node_in_group("player")
			if pl != null:
				pl.global_position = cfg[1] # En la plaza (casi todo cerca) o en el borde oeste (casi todo lejos)
			for nn in get_nodes_in_group("village_npcs"):
				nn.process_mode = Node.PROCESS_MODE_DISABLED if (cfg.size() > 2 and cfg[2] == "npcs_off") else Node.PROCESS_MODE_INHERIT
			for _w2 in range(240):
				await process_frame
			var tl: int = Time.get_ticks_usec()
			for _f2 in range(300):
				await process_frame
			var far: int = 0
			for nn in get_nodes_in_group("village_npcs"):
				if not nn.is_dead and nn._lod_far():
					far += 1
			print("PERF_LOD npcs=%d lod=%s far=%d %s frame_wall=%.2fms" % [_living(), str(lod), far, str(cfg[2]) if cfg.size() > 2 else "", float(Time.get_ticks_usec() - tl) / 1000.0 / 300.0])
		for _w in range(WARMUP):
			await process_frame
		var proc_tot: float = 0.0
		var phys_tot: float = 0.0
		var worst: float = 0.0
		var t0: int = Time.get_ticks_usec()
		var f0: int = Engine.get_process_frames()
		var g0: float = float(wc.current_hour) * 60.0 + float(wc.current_minute)
		for _f in range(FRAMES):
			await process_frame
			var p: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			var ph: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
			proc_tot += p
			phys_tot += ph
			worst = maxf(worst, p + ph)
		var wall_ms: float = float(Time.get_ticks_usec() - t0) / 1000.0 / float(FRAMES)
		var frames_real: int = Engine.get_process_frames() - f0
		var game_min: float = float(wc.current_hour) * 60.0 + float(wc.current_minute) - g0
		print("PERF_CHECK engine_frames=%d game_minutes=%.0f" % [frames_real, game_min])
		# Qué cuesta cada cosa por separado (llamadas directas, en ms)
		var day: int = int(wc.current_day)
		var tt: int = Time.get_ticks_usec()
		for _h in range(3):
			vm._on_hour_passed(day, int(wc.current_hour))
		var hour_ms: float = float(Time.get_ticks_usec() - tt) / 3000.0
		tt = Time.get_ticks_usec()
		vm._process(1.0 / 60.0)
		var vm_ms: float = float(Time.get_ticks_usec() - tt) / 1000.0
		tt = Time.get_ticks_usec()
		for nn in get_nodes_in_group("village_npcs"):
			if not nn.is_dead:
				nn._physics_process(1.0 / 60.0)
		var npc_ms: float = float(Time.get_ticks_usec() - tt) / 1000.0
		tt = Time.get_ticks_usec()
		vm._on_day_passed(day)
		var day_first_ms: float = float(Time.get_ticks_usec() - tt) / 1000.0
		tt = Time.get_ticks_usec()
		vm._on_day_passed(day)
		var day_ms: float = float(Time.get_ticks_usec() - tt) / 1000.0
		print("PERF_DAYS first=%.1fms second=%.1fms" % [day_first_ms, day_ms])
		var parts: Dictionary = {}
		var calls: Array = [
			["romances", func(): vm._advance_live_romances(day)],
			["director", func(): vm.social_director.on_day_passed(day)],
			["reciprocity", func(): vm.VillageSocialLife.daily_reciprocity(vm)],
			["cooling", func(): vm.VillageSocialLife.daily_distance_cooling(vm, day)],
			["friend_scan", func(): vm.VillageChronicle.daily_friendship_scan(vm)],
			["gossip_decay", func(): vm.VillageSocialLife.GossipMemory.daily_decay(vm)],
			["secrets", func(): vm.VillageSecrets.daily(vm)],
			["desires", func(): vm.VillageDesires.daily(vm)],
			["faith", func(): vm.VillageFaith.daily(vm)],
			["sect", func(): vm.VillageSect.daily(vm)],
			["needs", func(): vm.VillageNeeds.daily(vm)],
			["illness", func(): vm.VillageIllness.daily(vm)],
			["crime", func(): vm.VillageCrime.daily(vm)],
			["town", func(): vm.VillageTown.daily(vm)],
			["quests", func(): vm.VillageQuests.on_day_passed(vm)],
		]
		for c in calls:
			var tc: int = Time.get_ticks_usec()
			(c[1] as Callable).call()
			parts[c[0]] = snappedf(float(Time.get_ticks_usec() - tc) / 1000.0, 0.1)
		print("PERF_DAY npcs=%d %s" % [_living(), str(parts)])
		print("PERF_PARTS npcs=%d hour=%.1fms day=%.1fms vm_frame=%.2fms npcs_frame=%.2fms" % [_living(), hour_ms, day_ms, vm_ms, npc_ms])
		print("PERF npcs=%d frame_wall=%.2fms process=%.2fms physics=%.2fms worst=%.2fms fps_equiv=%.0f" % [_living(), wall_ms, proc_tot / FRAMES, phys_tot / FRAMES, worst, 1000.0 / maxf(0.01, wall_ms)])
	quit(0)

func _living() -> int:
	var c: int = 0
	for n in get_nodes_in_group("village_npcs"):
		if not n.is_dead:
			c += 1
	return c
