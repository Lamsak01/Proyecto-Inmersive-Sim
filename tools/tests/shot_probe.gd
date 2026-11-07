extends SceneTree

## Sonda con ventana: lleva al jugador a un punto, pone una hora y guarda capturas. Uso:
##   flatpak run org.godotengine.Godot --path . -s tools/tests/shot_probe.gd -- X Y HORA SALIDA.png [X2 Y2 SALIDA2.png ...]
func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(40):
		await process_frame
	var wc = root.get_node_or_null("/root/WorldClock")
	if wc != null and a.size() > 2:
		wc.set("current_hour", int(a[2]))
		wc.set("current_minute", 0)
	for n in root.find_children("*", "", true, false):
		if n.has_method("close_controls_panel"):
			n.call("close_controls_panel")
	var pl = get_first_node_in_group("player")
	var i: int = 0
	while i + 2 < a.size():
		var pos := Vector2(float(a[i]), float(a[i + 1]))
		var out: String = a[i + 3] if i == 0 else a[i + 2]
		if i == 0:
			i = 4
		else:
			i += 3
		if pl != null:
			pl.global_position = pos
		for _k in range(90):
			await process_frame
		var img: Image = root.get_viewport().get_texture().get_image()
		img.save_png(out)
		print("SHOT ", out)
	quit()
