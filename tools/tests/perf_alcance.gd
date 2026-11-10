extends SceneTree

## ¿Cuántos objetos 3D pequeños o lejanos se dibujan? Y cuánto se gana si los pequeños dejan de dibujarse a lo lejos.
## Con ventana, 1.ª persona (Claude Code, 2026-11-10; ~3 min). Uso: flatpak run org.godotengine.Godot --path . -s tools/tests/perf_alcance.gd

const MEASURE: int = 90
var s3d_rid: RID
var stage = null

func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(60):
		await process_frame
	var ui_root = get_first_node_in_group("game_ui")
	if ui_root != null:
		for m in ["close_hiring_letter_panel", "close_controls_panel"]:
			if ui_root.has_method(m):
				ui_root.call(m)
	for n in _all(root):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("WorldStage3D.gd"):
			stage = n
	stage.call("set_first_person", true)
	s3d_rid = stage.sub_viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(s3d_rid, true)
	var pl = get_first_node_in_group("player") as Node2D
	var geos: Array = []
	for n in _all(stage.stage_root_3d):
		if n is GeometryInstance3D and not str(n.get_path()).contains("Characters3D") and not str(n.get_path()).contains("WorldCamera3D"):
			geos.append(n)
	var cubos := {"<1m": 0, "1-3m": 0, "3-10m": 0, ">10m": 0}
	for g in geos:
		var e: float = _extension(g)
		var k: String = "<1m" if e < 0.2 else ("1-3m" if e < 0.6 else ("3-10m" if e < 2.0 else ">10m"))
		cubos[k] += 1
	print("PA geometrias=%d tamaños(unidades 3D, 1 u = 5 m)=%s" % [geos.size(), str(cubos)])
	for zona in [["plaza", Vector2(412, 54), 0.0], ["afueras", Vector2(-1180, 50), 0.0], ["rio", Vector2(250, 0), 0.0]]:
		pl.global_position = zona[1]
		stage.set("fp_yaw", zona[2])
		for _i in range(60):
			await process_frame
		_p(zona[0] + "_base", await _medir())
		geos = geos.filter(func(g): return is_instance_valid(g))
		for cfg in [[0.2, 5.0, 0.6, 10.0], [0.2, 3.0, 0.6, 7.0]]:
			var antes: Array = []
			for g in geos:
				antes.append(g.visibility_range_end)
				var e: float = _extension(g)
				if e < cfg[0]:
					g.visibility_range_end = cfg[1]
				elif e < cfg[2]:
					g.visibility_range_end = cfg[3]
			_p("%s_peq_hasta_%dm_med_hasta_%dm" % [zona[0], int(cfg[1] * 5), int(cfg[3] * 5)], await _medir())
			if zona[0] == "plaza":
				root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "/alcance_%d.png" % int(cfg[1])) if OS.get_cmdline_user_args().size() > 0 else null
			for i in geos.size():
				if is_instance_valid(geos[i]):
					geos[i].visibility_range_end = antes[i]
	print("PA_FIN")
	quit(0)

func _extension(g: GeometryInstance3D) -> float:
	var ab: AABB = g.get_aabb()
	var s: Vector3 = ab.size * g.global_transform.basis.get_scale().abs()
	return maxf(s.x, maxf(s.y, s.z))

func _p(tag: String, m: Dictionary) -> void:
	print("PA %-42s ms=%.2f 3d_cpu=%.2f 3d_gpu=%.2f draws=%d" % [tag, m["ms"], m["sc"], m["sg"], int(m["d"])])

func _medir() -> Dictionary:
	for _i in range(15):
		await process_frame
	var a := {"sc": 0.0, "sg": 0.0, "d": 0.0}
	var t0 := Time.get_ticks_usec()
	for _i in range(MEASURE):
		await process_frame
		a["sc"] += RenderingServer.viewport_get_measured_render_time_cpu(s3d_rid)
		a["sg"] += RenderingServer.viewport_get_measured_render_time_gpu(s3d_rid)
		a["d"] += RenderingServer.viewport_get_render_info(s3d_rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
	return {"ms": float(Time.get_ticks_usec() - t0) / 1000.0 / MEASURE, "sc": a["sc"] / MEASURE, "sg": a["sg"] / MEASURE, "d": a["d"] / MEASURE}

func _all(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out
