extends SceneTree

## Editor del mapa 3D (Claude Code, 2026-11-10): añade a mapa/Mundo3D.tscn → «Objetos» una pieza por cada objeto con uso
## que el juego ya sabe colocar donde diga el editor (mapa/objeto.gd: ObjetoEditor.pos). Solo añade las claves que falten,
## así que se puede volver a ejecutar cuando se pasen objetos nuevos:
##   flatpak run org.godotengine.Godot --headless --path . -s tools/hornear_objetos.gd

const ESCENA := "res://mapa/Mundo3D.tscn"


func _initialize() -> void:
	var WB = load("res://scripts/visuals/WorldStageBase3D.gd")
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(20):
		await process_frame
	var vm: Node = get_first_node_in_group("village_manager")
	# clave, posición actual en el mapa 2D, modelo para verlo en el editor, alto, nombre
	var lista: Array = []
	var sl: Array = vm.get("streetlights")
	for i in range(sl.size()):
		lista.append(["farola_%d" % i, sl[i]["pos"], "graveyard/lightpost-single.glb", 29.0, "Farola %d" % (i + 1)])
	lista.append(["pozo_granja", vm.get("_well_pos"), "exterior/Well.obj", 24.0, "Pozo de la granja"])
	lista.append(["pozo_taberna", vm.get("_tavern_well_pos"), "exterior/Well.obj", 24.0, "Pozo de la taberna"])
	lista.append(["pozo_plaza", vm.get("_plaza_well_pos"), "exterior/Well.obj", 24.0, "Pozo de la plaza"])
	lista.append(["tablon_plaza", vm.get("_notice_board_pos"), "", 14.0, "Tablón de encargos"])

	var actual: Node = (load(ESCENA) as PackedScene).instantiate()
	var objs: Node = actual.get_node_or_null("Objetos")
	if objs == null:
		objs = Node3D.new()
		objs.name = "Objetos"
		actual.add_child(objs)
		objs.owner = actual
	var ya := {}
	for c in objs.get_children():
		ya[String(c.get("clave"))] = true
	var sin_p: float = sin(deg_to_rad(WB.PITCH_DEG))
	var cos_p: float = cos(deg_to_rad(WB.PITCH_DEG))
	var script_o = load("res://mapa/objeto.gd")
	var n := 0
	for e in lista:
		if ya.has(e[0]):
			continue
		var p: Vector2 = e[1]
		var h: float = WB.terrain_height_px(p)
		var o := Node3D.new()
		o.set_script(script_o)
		o.name = String(e[4]).replace(" ", "_")
		o.set("clave", e[0])
		o.set("pos_original", p)
		o.set("modelo", e[2])
		o.set("alto", e[3])
		o.set("nombre_visible", e[4])
		o.position = Vector3(p.x * WB.WORLD_SCALE, (h * WB.WORLD_SCALE) / cos_p, (p.y * WB.WORLD_SCALE) / sin_p)
		objs.add_child(o)
		o.owner = actual
		n += 1
	var ps := PackedScene.new()
	var err := ps.pack(actual)
	if err == OK:
		err = ResourceSaver.save(ps, ESCENA)
	print("HORNEAR_OBJ: %d objetos añadidos (error %d)" % [n, err])
	quit(0 if err == OK else 1)
