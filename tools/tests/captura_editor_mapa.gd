extends SceneTree

## Captura del editor del mapa (Claude Code, 2026-11-09). Uso (ventana, ~10 s):
##   timeout 60 flatpak run org.godotengine.Godot --path . -s tools/tests/captura_editor_mapa.gd -- [mover]
## «mover» desplaza un punto del río en el pueblo para ver el modo «río propio» y los avisos en rojo.

func _initialize() -> void:
	var sc: Node2D = load("res://mapa/EditorMapa.tscn").instantiate()
	root.add_child(sc)
	if "mover" in OS.get_cmdline_user_args():
		var p: Node2D = sc.get_node("Rio/Punto14")
		p.position += Vector2(140, 0)
		p.set("ancho", 70.0)
		sc.get_node("Rio").queue_redraw()
		print("CAPT original=", load("res://scripts/obstacles/FishingSpot.gd").es_rio_original(sc.get_node("Rio").call("datos")))
	var shots := [["entero", Vector2(250, -100), 2600.0], ["pueblo", Vector2(300, 0), 1100.0], ["molino", Vector2(150, -980), 500.0]]
	for s in shots:
		# Encuadre: «ancho visible» en píxeles del mundo centrado en el punto dado
		var vis: Vector2 = Vector2(root.get_visible_rect().size)
		var z: float = vis.x / float(s[2])
		root.canvas_transform = Transform2D(0.0, Vector2(z, z), 0.0, vis * 0.5 - Vector2(s[1]) * z)
		for _i in range(8):
			await process_frame
		var img := root.get_texture().get_image()
		var suf := "_mover" if "mover" in OS.get_cmdline_user_args() else ""
		img.save_png("/home/lamsaktp/.claude/jobs/0d925c22/tmp/editor_%s%s.png" % [s[0], suf])
	print("CAPT_FIN")
	quit(0)
