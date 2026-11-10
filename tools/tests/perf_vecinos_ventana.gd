extends SceneTree

## Coste de cada parte de los vecinos por paso de física, con ventana, modo demo y 1.ª persona (Claude Code, 2026-11-09).
## Uso: timeout 400 flatpak run org.godotengine.Godot --path . -s tools/tests/perf_vecinos_ventana.gd -- [x y]

func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(60):
		await process_frame
	var gm = root.get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("set_demo_mode"):
		gm.call("set_demo_mode", true)
	var args := OS.get_cmdline_user_args()
	var pl = get_first_node_in_group("player") as Node2D
	pl.global_position = Vector2(float(args[0]), float(args[1])) if args.size() >= 2 else Vector2(412, 54)
	for _i in range(120):
		await process_frame
	var NPC = load("res://scripts/enemies/VillageNPC.gd")
	NPC.perf_usec.clear()
	NPC.perf_on = true
	var f0 := Engine.get_physics_frames()
	var t0 := Time.get_ticks_usec()
	for _i in range(200):
		await process_frame
	var steps: int = Engine.get_physics_frames() - f0
	NPC.perf_on = false
	print("NW vecinos=%d ms_fotograma=%.1f pasos_por_fotograma=%.2f" % [get_nodes_in_group("village_npcs").size(), float(Time.get_ticks_usec() - t0) / 1000.0 / 200.0, float(steps) / 200.0])
	var top := ["inactive_states", "frame_upkeep", "self_tending", "player_attention", "duties", "needs_decisions", "hospital_care", "dynamic_activity", "movement", "live_fight", "hostile"]
	var tot := 0.0
	var parts: Array = []
	for k in NPC.perf_usec.keys():
		var ms: float = float(NPC.perf_usec[k]) / 1000.0 / float(maxi(1, steps))
		parts.append([k, ms])
		if k in top:
			tot += ms
	parts.sort_custom(func(a, b): return a[1] > b[1])
	for p in parts:
		print("NW %s %.3fms/paso" % [p[0], p[1]])
	print("NW TOTAL_por_paso %.2fms" % tot)
	quit(0)
