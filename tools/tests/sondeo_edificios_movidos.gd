extends SceneTree

## Sondeo (Claude Code, 2026-11-10): mueve TODOS los edificios un poco (sin tocar la escena) y mira qué sitios de los
## vecinos se quedan en el sitio viejo. ~40 s sin ventana:
##   timeout 150 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/sondeo_edificios_movidos.gd

var D := Vector2(37, 23)

func _initialize() -> void:
	if "quieto" in OS.get_cmdline_user_args():
		D = Vector2.ZERO
	seed(11)
	var ref: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://mapa/referencia_mapa.json"))
	var ED = load("res://mapa/edificio.gd")
	var cache := {}
	var viejos := {}
	for e in ref["edificios"]:
		cache[str(e["id"])] = [D, 0.0]
		var r: Array = e["r"]
		viejos[str(e["id"])] = Rect2(r[0], r[1], r[2], r[3])
	ED._leido = true
	ED._cache = cache
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(60):
		await physics_frame
	var vm = get_first_node_in_group("village_manager")
	var nuevos := {}
	for b in vm.building_footprints:
		nuevos[str(b["id"])] = b["rect"]
	var movidos := 0
	for id in viejos.keys():
		if nuevos.has(id) and (nuevos[id] as Rect2).position.distance_to((viejos[id] as Rect2).position + D) < 2.0:
			movidos += 1
	print("SONDEO edificios movidos bien: %d de %d" % [movidos, viejos.size()])
	var volcado := {}
	for n in get_nodes_in_group("village_npcs"):
		for campo in ["bed_position", "home_table_pos", "work_position"]:
			var pv: Vector2 = n.get(campo)
			volcado[str(n.get("npc_name")) + "." + campo] = [pv.x, pv.y]
	var tag := "quieto" if D == Vector2.ZERO else "movido"
	var f := FileAccess.open("user://sondeo_%s.json" % tag, FileAccess.WRITE)
	f.store_string(JSON.stringify(volcado))
	f.close()
	print("SONDEO volcado ", ProjectSettings.globalize_path("user://sondeo_%s.json" % tag))
	var ok := 0
	var mal: Array[String] = []
	var fuera := 0
	for n in get_nodes_in_group("village_npcs"):
		for campo in ["bed_position", "home_table_pos", "work_position"]:
			var p: Vector2 = n.get(campo)
			if p == Vector2.ZERO:
				continue
			var en_nuevo := ""
			var en_viejo := ""
			for id in nuevos.keys():
				if (nuevos[id] as Rect2).grow(4).has_point(p):
					en_nuevo = id
			for id in viejos.keys():
				if (viejos[id] as Rect2).grow(4).has_point(p):
					en_viejo = id
			if en_nuevo != "":
				ok += 1
			elif en_viejo != "":
				mal.append("%s.%s en sitio viejo de %s" % [str(n.get("npc_name")), campo, en_viejo])
			else:
				fuera += 1
	print("SONDEO sitios de vecinos: bien=%d viejos=%d al_aire_libre=%d" % [ok, mal.size(), fuera])
	for m in mal:
		print("SONDEO  ✗ " + m)
	quit(0)
