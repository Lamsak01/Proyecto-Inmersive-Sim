extends SceneTree

## Qué pesa en la lógica por fotograma (_physics_process/_process) por tipo de script, en la plaza, 1.ª persona,
## modo demo (~4 min). Uso: timeout 590 flatpak run org.godotengine.Godot --path . -s tools/tests/perf_fisica.gd
## (Claude Code, 2026-11-09)

const MEASURE: int = 40

func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(60):
		await process_frame
	var gm = root.get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("set_demo_mode"):
		gm.call("set_demo_mode", true)
	var pl = get_first_node_in_group("player") as Node2D
	pl.global_position = Vector2(412, 54)
	for _i in range(60):
		await process_frame
	print("PERFF fisica_ticks_por_seg=%d max_pasos=%d" % [Engine.physics_ticks_per_second, Engine.max_physics_steps_per_frame])
	var groups: Dictionary = {}
	var bodies := 0
	var shapes := 0
	var areas := 0
	for n in _all(root):
		if n is CollisionShape2D or n is CollisionPolygon2D:
			shapes += 1
		if n is PhysicsBody2D:
			bodies += 1
		if n is Area2D:
			areas += 1
		var sc = n.get_script()
		if sc == null:
			continue
		if not (n.is_physics_processing() or n.is_processing()):
			continue
		var f: String = str(sc.resource_path).get_file()
		if not groups.has(f):
			groups[f] = []
		groups[f].append(n)
	print("PERFF cuerpos=%d formas=%d areas=%d" % [bodies, shapes, areas])
	var base := await _m()
	print("PERFF base %s" % _fmt(base))
	var keys: Array = groups.keys()
	keys.sort_custom(func(a, b): return groups[a].size() > groups[b].size())
	for f in keys:
		var arr: Array = groups[f]
		var saved: Array = []
		for n in arr:
			saved.append([n.is_physics_processing(), n.is_processing()])
			n.set_physics_process(false)
			n.set_process(false)
		var m := await _m()
		print("PERFF sin %s(x%d) %s  ahorro_fisica=%.2f ahorro_logica=%.2f" % [f, arr.size(), _fmt(m), base["phys"] - m["phys"], base["proc"] - m["proc"]])
		for i in range(arr.size()):
			if is_instance_valid(arr[i]):
				arr[i].set_physics_process(saved[i][0])
				arr[i].set_process(saved[i][1])
	print("PERFF_FIN")
	quit(0)

func _m() -> Dictionary:
	for _i in range(8):
		await process_frame
	var p := 0.0
	var q := 0.0
	var t0 := Time.get_ticks_usec()
	for _i in range(MEASURE):
		await process_frame
		p += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		q += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	return {"phys": p / MEASURE, "proc": q / MEASURE, "wall": float(Time.get_ticks_usec() - t0) / 1000.0 / MEASURE}

func _fmt(m: Dictionary) -> String:
	return "ms=%.1f fisica=%.2f logica=%.2f" % [m["wall"], m["phys"], m["proc"]]

func _all(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out
