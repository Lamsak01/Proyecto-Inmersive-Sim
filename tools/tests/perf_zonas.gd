extends SceneTree

## Rendimiento por zonas en 1.ª persona y modo demo, con ventana (~5 min). Uso:
##   timeout 600 flatpak run org.godotengine.Godot --path . -s tools/tests/perf_zonas.gd   (añade «-- zonas» para medir solo las zonas)
## (Claude Code, 2026-11-09). Para cada zona: tiempo por fotograma, lógica (scripts) frente a dibujo, llamadas de
## dibujo y objetos visibles. Luego, en la peor zona, apaga cada capa del escenario, las sombras y los vecinos por
## separado: lo que más baja es lo que más pesa.

const WARM: int = 150
const MEASURE: int = 180

var stage = null
var main_rid: RID
var s3d_rid: RID
var pl: Node2D = null


func _initialize() -> void:
	seed(7)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(60):
		await process_frame
	var gm = root.get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("set_demo_mode"):
		gm.call("set_demo_mode", true)
	var ui_root = get_first_node_in_group("game_ui")
	if ui_root != null:
		for m in ["close_hiring_letter_panel", "close_controls_panel"]:
			if ui_root.has_method(m):
				ui_root.call(m)
	pl = get_first_node_in_group("player") as Node2D
	for n in _all_nodes(root):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("WorldStage3D.gd"):
			stage = n
			break
	if stage != null:
		stage.call("set_first_person", true)
	root.get_node("/root/WorldClock").current_hour = 14
	main_rid = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(main_rid, true)
	if stage != null and stage.sub_viewport != null:
		s3d_rid = stage.sub_viewport.get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(s3d_rid, true)
	var FS = load("res://scripts/obstacles/FishingSpot.gd")
	var rb: Vector2 = FS.river_banks_at(0.0) if FS != null and FS.has_method("river_banks_at") else Vector2(300, 300)
	var zones: Array = [
		["afueras", Vector2(-1180, 50), 0.0],
		["plaza", Vector2(412, 54), 0.0],
		["rio_pueblo", Vector2(rb.x - 30.0, 0.0), 0.0],
		["bosque_claro", Vector2(138, -850), -PI / 2.0],
		["molino", Vector2(190, -1040), -PI / 2.0],
		["mansion", Vector2(1315, -330), -PI / 2.0],
	]
	print("PERFZ_INFO npcs=%d nodos=%d vis3d=%d ventana=%s escenario3d=%s" % [
		get_nodes_in_group("village_npcs").size(), _all_nodes(root).size(), _count_vis(root),
		str(root.size), str(stage.sub_viewport.size) if stage else "-"])
	if stage != null:
		for layer in stage.stage_root_3d.get_children():
			print("PERFZ_CAPA %s vis3d=%d" % [str(layer.name), _count_vis(layer)])
	var worst := ""
	var worst_ms := 0.0
	for z in zones:
		await _go(z[1], z[2])
		var m: Dictionary = await _measure()
		_print("zona_" + str(z[0]), m)
		if float(m["wall"]) > worst_ms:
			worst_ms = float(m["wall"])
			worst = str(z[0])
	if "zonas" in OS.get_cmdline_user_args():
		print("PERFZ_FIN")
		quit(0)
		return
	# Desglose en la peor zona
	for z in zones:
		if str(z[0]) == worst:
			await _go(z[1], z[2])
	print("PERFZ_PEOR %s %.2fms" % [worst, worst_ms])
	_print("peor_base", await _measure())
	if stage != null:
		for layer in stage.stage_root_3d.get_children():
			if not (layer is Node3D) or not layer.visible:
				continue
			layer.visible = false
			_print("sin_" + str(layer.name), await _measure())
			layer.visible = true
			for _i in range(20):
				await process_frame
	var lights: Array = []
	for n in _all_nodes(root):
		if n is Light3D and n.shadow_enabled:
			lights.append(n)
	for l in lights:
		l.shadow_enabled = false
	_print("sin_sombras(%d)" % lights.size(), await _measure())
	for l in lights:
		l.shadow_enabled = true
	# Vecinos: parar su lógica (no su dibujo)
	var npcs: Array = get_nodes_in_group("village_npcs")
	for n in npcs:
		n.process_mode = Node.PROCESS_MODE_DISABLED
	_print("sin_logica_vecinos(%d)" % npcs.size(), await _measure())
	for n in npcs:
		n.process_mode = Node.PROCESS_MODE_INHERIT
	if stage != null:
		var sz: Vector2i = stage.sub_viewport.size
		stage.sub_viewport.size = sz / 2
		_print("mitad_resolucion", await _measure())
		stage.sub_viewport.size = sz
	print("PERFZ_FIN")
	quit(0)


func _go(pos: Vector2, yaw: float) -> void:
	pl.global_position = pos
	if stage != null:
		stage.set("fp_yaw", yaw)
		stage.set("fp_pitch", -0.05)
		stage.call("_update_fp_camera_transform")
	for _i in range(WARM):
		await process_frame
		if stage != null:
			stage.set("fp_yaw", yaw)


func _measure() -> Dictionary:
	var acc := {"mc": 0.0, "mg": 0.0, "sc": 0.0, "sg": 0.0, "proc": 0.0, "phys": 0.0, "draws": 0.0, "objs": 0.0, "prims": 0.0}
	var worst_frame: float = 0.0
	var t0: int = Time.get_ticks_usec()
	var tl: int = t0
	for _f in range(MEASURE):
		await process_frame
		var now: int = Time.get_ticks_usec()
		worst_frame = maxf(worst_frame, float(now - tl) / 1000.0)
		tl = now
		acc["mc"] += RenderingServer.viewport_get_measured_render_time_cpu(main_rid)
		acc["mg"] += RenderingServer.viewport_get_measured_render_time_gpu(main_rid)
		acc["proc"] += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		acc["phys"] += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		if s3d_rid.is_valid():
			acc["sc"] += RenderingServer.viewport_get_measured_render_time_cpu(s3d_rid)
			acc["sg"] += RenderingServer.viewport_get_measured_render_time_gpu(s3d_rid)
			acc["draws"] += RenderingServer.viewport_get_render_info(s3d_rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
			acc["objs"] += RenderingServer.viewport_get_render_info(s3d_rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME)
			acc["prims"] += RenderingServer.viewport_get_render_info(s3d_rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME)
	var out := {"wall": float(Time.get_ticks_usec() - t0) / 1000.0 / float(MEASURE), "worst": worst_frame}
	for k in acc.keys():
		out[k] = float(acc[k]) / float(MEASURE)
	return out


func _print(tag: String, m: Dictionary) -> void:
	print("PERFZ %s ms=%.2f fps=%.0f peor=%.1fms | logica=%.2f fisica=%.2f | 3d_cpu=%.2f 3d_gpu=%.2f ventana_cpu=%.2f ventana_gpu=%.2f | draws=%d objetos=%d triangulos=%dk" % [
		tag, m["wall"], 1000.0 / maxf(0.01, m["wall"]), m["worst"], m["proc"], m["phys"], m["sc"], m["sg"], m["mc"], m["mg"],
		int(m["draws"]), int(m["objs"]), int(m["prims"] / 1000.0)])


func _count_vis(n: Node) -> int:
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
