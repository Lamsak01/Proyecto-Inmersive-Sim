extends SceneTree

## Editor del mapa (Claude Code, 2026-11-09; río en mapa/Mundo3D.tscn desde 2026-11-12): comprueba que el juego
## arranca con el río del editor (~30 s, sin ventana).
##   timeout 120 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/rio_editor_juego.gd -- [mover]
## Sin «mover»: el juego usa el río y los puentes guardados en el editor.
## Con «mover»: un punto desplazado y el juego usa el río nuevo.

func _initialize() -> void:
	var FS = load("res://scripts/fisica/RioLago.gd")
	var mover: bool = "mover" in OS.get_cmdline_user_args()
	var ok := true
	if mover:
		var RF = load("res://mapa/rio_forma.gd")
		var d: Dictionary = RF.leer_escena(FS.MAPA_ESCENA)
		d["pts"][13] = d["pts"][13] + Vector2(140, 0)
		FS.usar_datos(d)
		var b: Vector2 = FS.river_banks_at(-58.0)
		print("RIOJ banks(-58)=%s" % str(b))
		ok = ok and b.x > 150.0
	else:
		var RF = load("res://mapa/rio_forma.gd")
		var d: Dictionary = RF.leer_escena(FS.MAPA_ESCENA)
		FS.river_banks_at(0.0) # fuerza la lectura del río del editor
		print("RIOJ puntos=%d cruces=%d (editor: %d)" % [FS.river_waypoints().size(), FS.river_crossings().size(), d["cruces"].size()])
		ok = ok and FS.river_waypoints().size() == d["pts"].size() and FS.river_crossings().size() == d["cruces"].size()
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(90):
		await physics_frame
	var body = root.find_child("RiverWaterCollisionBody", true, false)
	var segs: int = body.get_child_count() if body != null else -1
	print("RIOJ tramos_agua=%d vecinos=%d" % [segs, get_nodes_in_group("village_npcs").size()])
	ok = ok and segs == FS.river_crossings().size() + 1 # un tramo de agua entre cada dos cruces
	print("RIOJ " + ("OK" if ok else "FALLO"))
	quit(0)
