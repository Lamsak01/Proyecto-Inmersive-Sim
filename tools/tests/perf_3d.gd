extends SceneTree

## B3: qué cuesta del 3D, con ventana (~4 min). Uso:
##   flatpak run org.godotengine.Godot --path . -s tools/tests/perf_3d.gd
## Mide el tiempo de dibujo (procesador y tarjeta) del escenario 3D y de la ventana, apagando cada capa por separado,
## las sombras y la resolución; y el coste directo por fotograma de los muñecos 3D y del escenario.

const WARM: int = 240
const MEASURE: int = 240

var stage = null
var main_rid: RID
var s3d_rid: RID

func _initialize() -> void:
	seed(7)
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(WARM * 2):
		await process_frame
	root.get_node("/root/WorldClock").current_hour = 14
	var pl = get_first_node_in_group("player")
	if pl != null:
		pl.global_position = Vector2(412, 54)
	for _i in range(WARM):
		await process_frame
	for n in _all_nodes(root):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("WorldStage3D.gd"):
			stage = n
	main_rid = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(main_rid, true)
	if stage != null and stage.sub_viewport != null:
		s3d_rid = stage.sub_viewport.get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(s3d_rid, true)
	print("PERF3D_INFO npcs=%d size=%s window=%s" % [get_nodes_in_group("village_npcs").size(), str(stage.sub_viewport.size) if stage else "-", str(root.size)])
	_print("base", await _measure())
	# Partes del escenario y de los muñecos (cronómetro interno), en ms por fotograma
	var S = load("res://scripts/visuals/WorldStage3D.gd")
	var A = load("res://scripts/visuals/CharacterAvatar3D.gd")
	S.perf_usec.clear()
	A.perf_usec.clear()
	S.perf_on = true
	A.perf_on = true
	for _i in range(MEASURE):
		await process_frame
	S.perf_on = false
	A.perf_on = false
	for pair in [["stage", S.perf_usec], ["avatar", A.perf_usec]]:
		for k in (pair[1] as Dictionary).keys():
			print("PERF3D_PART %s %s %.3fms" % [pair[0], k, float(pair[1][k]) / 1000.0 / float(MEASURE)])
	if "parts" in OS.get_cmdline_user_args():
		quit(0)
		return
	# Capas del escenario, una a una
	if stage != null:
		for layer in stage.stage_root_3d.get_children():
			if not (layer is Node3D) or not layer.visible:
				continue
			layer.visible = false
			_print("off_" + str(layer.name) + "(%d)" % _count(layer), await _measure())
			layer.visible = true
			for _i in range(20):
				await process_frame
	# Sombras y luces
	var lights: Array = []
	for n in _all_nodes(root):
		if n is Light3D and n.shadow_enabled:
			lights.append(n)
	for l in lights:
		l.shadow_enabled = false
	_print("no_shadows(%d)" % lights.size(), await _measure())
	for l in lights:
		l.shadow_enabled = true
	# Resolución del escenario 3D a la mitad
	if stage != null:
		var sz: Vector2i = stage.sub_viewport.size
		stage.sub_viewport.size = sz / 2
		_print("half_res", await _measure())
		stage.sub_viewport.size = sz
	# Coste directo (procesador) de los scripts del 3D, restando una vuelta vacía
	var REPS: int = 20
	var t_empty: int = Time.get_ticks_usec()
	for _r in range(REPS):
		await process_frame
	var empty_ms: float = float(Time.get_ticks_usec() - t_empty) / 1000.0 / float(REPS)
	var groups: Dictionary = {}
	for n in _all_nodes(root):
		var sc = n.get_script()
		if sc == null or not n.is_processing():
			continue
		var f: String = str(sc.resource_path).get_file()
		if f in ["CharacterAvatar3D.gd", "AnimalModel3D.gd", "BanditModel3D.gd", "WorldStage3D.gd", "RetroPostFX.gd"]:
			if not groups.has(f):
				groups[f] = []
			groups[f].append(n)
	for f in groups.keys():
		var tt: int = Time.get_ticks_usec()
		for _r in range(REPS):
			for n in groups[f]:
				if is_instance_valid(n):
					n._process(1.0 / 60.0)
			await process_frame
		print("PERF3D_SCRIPT %s count=%d ms_per_frame=%.2f" % [f, groups[f].size(), float(Time.get_ticks_usec() - tt) / 1000.0 / float(REPS) - empty_ms])
	quit(0)

func _measure() -> Dictionary:
	var mc: float = 0.0
	var mg: float = 0.0
	var sc: float = 0.0
	var sg: float = 0.0
	var t0: int = Time.get_ticks_usec()
	for _f in range(MEASURE):
		await process_frame
		mc += RenderingServer.viewport_get_measured_render_time_cpu(main_rid)
		mg += RenderingServer.viewport_get_measured_render_time_gpu(main_rid)
		if s3d_rid.is_valid():
			sc += RenderingServer.viewport_get_measured_render_time_cpu(s3d_rid)
			sg += RenderingServer.viewport_get_measured_render_time_gpu(s3d_rid)
	var wall: float = float(Time.get_ticks_usec() - t0) / 1000.0 / float(MEASURE)
	return {"wall": wall, "mc": mc / MEASURE, "mg": mg / MEASURE, "sc": sc / MEASURE, "sg": sg / MEASURE,
		"draws": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}

func _print(tag: String, m: Dictionary) -> void:
	print("PERF3D %s wall=%.2fms fps=%.0f window_cpu=%.2f window_gpu=%.2f stage3d_cpu=%.2f stage3d_gpu=%.2f draws=%d" % [tag, m["wall"], 1000.0 / maxf(0.01, m["wall"]), m["mc"], m["mg"], m["sc"], m["sg"], int(m["draws"])])

func _count(n: Node) -> int:
	var c: int = 0
	for x in _all_nodes(n):
		if x is VisualInstance3D:
			c += 1
	return c

func _all_nodes(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_all_nodes(c))
	return out
