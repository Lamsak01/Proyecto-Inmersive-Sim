extends SceneTree

## Qué parte de la lógica (_process) pesa, con ventana, 1.ª persona y modo demo (Claude Code, 2026-11-10).
## Uso: timeout 600 flatpak run org.godotengine.Godot --path . -s tools/tests/perf_proceso.gd -- [x y]
## Agrupa los nodos que tienen _process activo por script, apaga cada grupo y mide cuánto baja el tiempo de lógica.

const WARM: int = 90
const MEASURE: int = 90

func _initialize() -> void:
	seed(7)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(60):
		await process_frame
	var ui_root = get_first_node_in_group("game_ui")
	if ui_root != null:
		for m in ["close_hiring_letter_panel", "close_controls_panel"]:
			if ui_root.has_method(m):
				ui_root.call(m)
	var pl = get_first_node_in_group("player") as Node2D
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		pl.global_position = Vector2(float(args[0]), float(args[1]))
	else:
		pl.global_position = Vector2(138, -850)
	var stage = null
	for n in _all(root):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("WorldStage3D.gd"):
			stage = n
	if stage:
		stage.call("set_first_person", true)
	for _i in range(WARM):
		await process_frame
	var grupos: Dictionary = {}
	for n in _all(root):
		if n.is_processing() or n.is_physics_processing():
			var k: String = str(n.get_script().resource_path.get_file()) if n.get_script() else n.get_class()
			if not grupos.has(k):
				grupos[k] = []
			grupos[k].append(n)
	var base: Dictionary = await _medir()
	print("PROC base ms=%.2f logica=%.2f fisica=%.2f nodos_activos=%d grupos=%d" % [base["ms"], base["proc"], base["phys"], _cuenta(grupos), grupos.size()])
	var res: Array = []
	for k in grupos.keys():
		var lista: Array = grupos[k]
		var estado: Array = []
		for n in lista:
			estado.append([n.is_processing(), n.is_physics_processing()])
			n.set_process(false)
			n.set_physics_process(false)
		for _i in range(20):
			await process_frame
		var m: Dictionary = await _medir()
		for i in lista.size():
			if is_instance_valid(lista[i]):
				lista[i].set_process(estado[i][0])
				lista[i].set_physics_process(estado[i][1])
		res.append([base["proc"] - m["proc"], base["phys"] - m["phys"], k, lista.size(), m["ms"]])
		for _i in range(10):
			await process_frame
	res.sort_custom(func(a, b): return a[0] + a[1] > b[0] + b[1])
	for r in res.slice(0, 25):
		print("PROC ahorro_logica=%.2f ahorro_fisica=%.2f ms_sin=%.2f  %s (x%d)" % [r[0], r[1], r[4], r[2], r[3]])
	print("PROC_FIN")
	quit(0)

func _cuenta(g: Dictionary) -> int:
	var c := 0
	for k in g.keys():
		c += g[k].size()
	return c

func _medir() -> Dictionary:
	var p := 0.0
	var f := 0.0
	var t0 := Time.get_ticks_usec()
	for _i in range(MEASURE):
		await process_frame
		p += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		f += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	return {"ms": float(Time.get_ticks_usec() - t0) / 1000.0 / MEASURE, "proc": p / MEASURE, "phys": f / MEASURE}

func _all(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out
