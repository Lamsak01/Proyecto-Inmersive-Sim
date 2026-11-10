extends SceneTree

## Qué cuesta dibujar la ventana (2D, interfaz) en 1.ª persona, con ventana (Claude Code, 2026-11-10; ~2 min).
## Uso: timeout 400 flatpak run org.godotengine.Godot --path . -s tools/tests/perf_ventana.gd -- [x y]
## Esconde por turnos cada hijo del pueblo 2D y la interfaz, y mide el tiempo de tarjeta gráfica de la ventana.

const MEASURE: int = 90
var main_rid: RID
var s3d_rid: RID

func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var world: Node = load("uid://dsoiuct8kdsk3").instantiate()
	root.add_child(world)
	for _i in range(60):
		await process_frame
	var ui_root = get_first_node_in_group("game_ui")
	if ui_root != null:
		for m in ["close_hiring_letter_panel", "close_controls_panel"]:
			if ui_root.has_method(m):
				ui_root.call(m)
	var pl = get_first_node_in_group("player") as Node2D
	var args := OS.get_cmdline_user_args()
	pl.global_position = Vector2(float(args[0]), float(args[1])) if args.size() >= 2 else Vector2(138, -850)
	var stage = null
	for n in _all(root):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("WorldStage3D.gd"):
			stage = n
	stage.call("set_first_person", true)
	main_rid = root.get_viewport_rid()
	s3d_rid = stage.sub_viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(main_rid, true)
	RenderingServer.viewport_set_measure_render_time(s3d_rid, true)
	for _i in range(90):
		await process_frame
	print("PV ventana=%s" % str(root.size))
	_p("base", await _medir())
	if args.size() >= 3:
		root.get_texture().get_image().save_png(args[2] + "/fp_bosque.png")
		pl.global_position = Vector2(412, 54)
		for _i in range(60):
			await process_frame
		_p("plaza", await _medir())
		root.get_texture().get_image().save_png(args[2] + "/fp_plaza.png")
		var aj = root.get_node("/root/Ajustes")
		for cfg in [["sombras", 1], ["sombras", 0], ["nitidez", 0.75], ["nitidez", 0.5]]:
			var antes = aj.valores.get(cfg[0])
			aj.valores[cfg[0]] = cfg[1]
			aj.aplicar()
			_p("plaza_%s_%s" % [cfg[0], str(cfg[1])], await _medir())
			if cfg[0] == "nitidez" and is_equal_approx(float(cfg[1]), 0.5):
				root.get_texture().get_image().save_png(args[2] + "/fp_nitidez50.png")
			aj.valores[cfg[0]] = antes
			aj.aplicar()
		var ui2 = get_first_node_in_group("game_ui")
		if ui2 and ui2.has_method("abrir_menu_pausa"):
			ui2.call("abrir_menu_pausa")
			for _i in range(10):
				await process_frame
			root.get_texture().get_image().save_png(args[2] + "/fp_pausa.png")
			var mp = root.get_node_or_null("MenuPausa")
			if mp:
				mp.call("cerrar")
		print("PV_FIN")
		quit(0)
		return
	for c in world.get_children():
		if c is CanvasItem and c.visible and c != stage:
			c.visible = false
			_p("sin_" + str(c.name), await _medir())
			c.visible = true
		elif c is CanvasLayer and c.visible:
			c.visible = false
			_p("sin_capa_" + str(c.name), await _medir())
			c.visible = true
	var ocultos: Array = []
	for c in world.get_children():
		if c is CanvasItem and c.visible and c != stage and c != stage.get_parent():
			c.visible = false
			ocultos.append(c)
	_p("solo_escenario_e_interfaz", await _medir())
	for c in ocultos:
		c.visible = true
	print("PV_FIN")
	quit(0)

func _p(tag: String, m: Dictionary) -> void:
	print("PV %-28s ms=%.2f ventana_gpu=%.2f ventana_cpu=%.2f 3d_gpu=%.2f" % [tag, m["ms"], m["mg"], m["mc"], m["sg"]])

func _medir() -> Dictionary:
	for _i in range(15):
		await process_frame
	var a := {"mg": 0.0, "mc": 0.0, "sg": 0.0}
	var t0 := Time.get_ticks_usec()
	for _i in range(MEASURE):
		await process_frame
		a["mg"] += RenderingServer.viewport_get_measured_render_time_gpu(main_rid)
		a["mc"] += RenderingServer.viewport_get_measured_render_time_cpu(main_rid)
		a["sg"] += RenderingServer.viewport_get_measured_render_time_gpu(s3d_rid)
	return {"ms": float(Time.get_ticks_usec() - t0) / 1000.0 / MEASURE, "mg": a["mg"] / MEASURE, "mc": a["mc"] / MEASURE, "sg": a["sg"] / MEASURE}

func _all(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out
