extends SceneTree

## Editor del mapa (Claude Code, 2026-11-09): comprueba que el juego arranca con el río del editor (~30 s, sin ventana).
##   timeout 120 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/rio_editor_juego.gd -- [mover]
## Sin «mover»: el río debe ser idéntico al original. Con «mover»: un punto desplazado y el juego usa el río nuevo.

func _initialize() -> void:
	var FS = load("res://scripts/obstacles/FishingSpot.gd")
	var mover: bool = "mover" in OS.get_cmdline_user_args()
	var ok := true
	if mover:
		var RF = load("res://mapa/rio_forma.gd")
		var d: Dictionary = RF.leer_escena(FS.MAPA_ESCENA)
		d["pts"][13] = d["pts"][13] + Vector2(140, 0)
		FS._mapa_cargado = true
		FS._rio = d
		FS._cruces.assign(d["cruces"])
		FS._rio_propio = true
		var b: Vector2 = FS.river_banks_at(-58.0)
		print("RIOJ banks(-58)=%s" % str(b))
		ok = ok and b.x > 150.0
	else:
		var maxd := 0.0
		var y := -1180.0
		while y <= 940.0:
			maxd = maxf(maxd, FS.river_banks_at(y).distance_to(FS._antiguo_banks_at(y)))
			y += 3.0
		print("RIOJ propio=%s diferencia_max=%.4f cruces=%d" % [str(FS._rio_propio), maxd, FS.river_crossings().size()])
		ok = ok and maxd < 0.001 and not FS._rio_propio and FS.river_crossings().size() == 5
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(90):
		await physics_frame
	var body = root.find_child("RiverWaterCollisionBody", true, false)
	var segs: int = body.get_child_count() if body != null else -1
	print("RIOJ tramos_agua=%d vecinos=%d" % [segs, get_nodes_in_group("village_npcs").size()])
	ok = ok and segs == 6
	print("RIOJ " + ("OK" if ok else "FALLO"))
	quit(0)
