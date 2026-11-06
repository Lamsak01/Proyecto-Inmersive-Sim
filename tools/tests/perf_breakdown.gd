extends SceneTree

## B3: qué hace lento cada fotograma, con ventana (así cuenta también el 3D). Uso (abre una ventana ~3 min):
##   flatpak run org.godotengine.Godot --path . -s tools/tests/perf_breakdown.gd
## 1) Fotograma normal con los vecinos de arranque. 2) Lo mismo apagando cada tipo de objeto por separado
## (solo su _process/_physics_process, no sus hijos): lo que baja es lo que cuesta. 3) Dentro del vecino, cuánto
## cuesta cada parte. 4) Con y sin la simulación «a ratos» de los vecinos lejanos.

const WARM: int = 240
const MEASURE: int = 240

func _initialize() -> void:
	seed(7)
	var packed: PackedScene = load("uid://dsoiuct8kdsk3")
	root.add_child(packed.instantiate())
	for _i in range(WARM * 2):
		await process_frame
	var wc = root.get_node("/root/WorldClock")
	wc.current_hour = 14
	var pl = get_first_node_in_group("player")
	if pl != null:
		pl.global_position = Vector2(412, 54) # la plaza: casi todo el pueblo cerca
	for _i in range(WARM):
		await process_frame
	print("PERF_INFO npcs=%d nodes=%d" % [get_nodes_in_group("village_npcs").size(), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	var base: Dictionary = await _measure()
	_print("base", base)
	# Cada tipo de objeto con proceso propio, por separado
	var buckets: Dictionary = {}
	for n in _all_nodes(root):
		var sc = n.get_script()
		if sc == null:
			continue
		if not (n.is_processing() or n.is_physics_processing()):
			continue
		var key: String = str(sc.resource_path).get_file()
		if key == "":
			key = "(script interno)"
		if not buckets.has(key):
			buckets[key] = []
		buckets[key].append(n)
	# Coste directo de cada tipo: se llama a su _process y _physics_process a mano (media de REPS veces)
	var REPS: int = 12
	var costs: Array = []
	# Vuelta vacía (solo esperar un fotograma), para restarla: si no, cada coste incluye el fotograma entero
	var t_empty: int = Time.get_ticks_usec()
	for _r in range(REPS):
		await process_frame
	var empty_ms: float = float(Time.get_ticks_usec() - t_empty) / 1000.0 / float(REPS)
	for key in buckets.keys():
		var arr: Array = buckets[key]
		var tt: int = Time.get_ticks_usec()
		for _r in range(REPS):
			for n in arr:
				if not is_instance_valid(n):
					continue
				if n.is_processing() and n.has_method("_process"):
					n._process(1.0 / 60.0)
				if n.is_physics_processing() and n.has_method("_physics_process"):
					n._physics_process(1.0 / 60.0)
			await process_frame
		costs.append([key, arr.size(), float(Time.get_ticks_usec() - tt) / 1000.0 / float(REPS) - empty_ms])
	costs.sort_custom(func(a, b): return a[2] > b[2])
	for c in costs:
		print("PERF_COST %s count=%d ms_per_call_round=%.2f" % [c[0], c[1], c[2]])
	# Dibujado: tiempo de CPU y de tarjeta del dibujo de la ventana
	var vp_rid: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	var rc: float = 0.0
	var rg: float = 0.0
	for _i in range(MEASURE):
		await process_frame
		rc += RenderingServer.viewport_get_measured_render_time_cpu(vp_rid) + RenderingServer.get_frame_setup_time_cpu()
		rg += RenderingServer.viewport_get_measured_render_time_gpu(vp_rid)
	print("PERF_RENDER cpu=%.2fms gpu=%.2fms" % [rc / MEASURE, rg / MEASURE])
	var stage = null
	for n_s in _all_nodes(root):
		if n_s.get_script() != null and str(n_s.get_script().resource_path).ends_with("WorldStage3D.gd"):
			stage = n_s
	if stage != null and stage.get("sub_viewport") != null:
		var svp: RID = stage.sub_viewport.get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(svp, true)
		rc = 0.0
		rg = 0.0
		for _i in range(MEASURE):
			await process_frame
			rc += RenderingServer.viewport_get_measured_render_time_cpu(svp)
			rg += RenderingServer.viewport_get_measured_render_time_gpu(svp)
		print("PERF_RENDER_3D cpu=%.2fms gpu=%.2fms" % [rc / MEASURE, rg / MEASURE])
	# Partes del vecino
	var NPC = load("res://scripts/enemies/VillageNPC.gd")
	NPC.perf_usec.clear()
	NPC.perf_on = true
	var calls: int = 0
	for _i in range(MEASURE):
		await physics_frame
		calls += 1
	NPC.perf_on = false
	var parts: Array = []
	for k in NPC.perf_usec.keys():
		parts.append([k, float(NPC.perf_usec[k]) / 1000.0 / float(calls)])
	parts.sort_custom(func(a, b): return a[1] > b[1])
	for p in parts:
		print("PERF_NPC_PART %s %.2fms_per_physics_frame" % [p[0], p[1]])
	# Con y sin simulación a ratos
	NPC.lod_enabled = false
	for _i in range(60):
		await process_frame
	_print("lod_off", await _measure())
	NPC.lod_enabled = true
	for _i in range(60):
		await process_frame
	_print("lod_on", await _measure())
	quit(0)

func _measure() -> Dictionary:
	var proc: float = 0.0
	var phys: float = 0.0
	var t0: int = Time.get_ticks_usec()
	for _f in range(MEASURE):
		await process_frame
		proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var wall: float = float(Time.get_ticks_usec() - t0) / 1000.0 / float(MEASURE)
	return {"wall": wall, "proc": proc / MEASURE, "phys": phys / MEASURE,
		"draws": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"objs": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)}

func _print(tag: String, m: Dictionary) -> void:
	print("PERF_%s wall=%.2fms fps=%.0f process=%.2fms physics=%.2fms draws=%d objects=%d" % [tag.to_upper(), m["wall"], 1000.0 / maxf(0.01, m["wall"]), m["proc"], m["phys"], int(m["draws"]), int(m["objs"])])

func _all_nodes(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_all_nodes(c))
	return out
