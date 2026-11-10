extends SceneTree
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Editor del mapa 3D (Claude Code, 2026-11-10): añade a mapa/Mundo3D.tscn → «Objetos» una pieza por cada objeto con uso
## que el juego ya sabe colocar donde diga el editor (mapa/objeto.gd: ObjetoEditor.pos). Solo añade las claves que falten,
## así que se puede volver a ejecutar cuando se pasen objetos nuevos:
##   flatpak run org.godotengine.Godot --headless --path . -s tools/hornear_objetos.gd

const ESCENA := "res://mapa/Mundo3D.tscn"


func _initialize() -> void:
	var WB = load("res://scripts/visuals/WorldStageBase3D.gd")
	var AN = load("res://mapa/anclas.gd")
	AN.grabar = true
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

	AN.grabar = false
	# Todo lo demás que el juego crea suelto (zonas de uso, dibujos, letreros, casas de animales, setas…) fuera de los
	# edificios (lo de dentro va con su edificio): una pieza-ancla por grupo de cosas a menos de 14 px.
	var plantas: Array = []
	for fp in vm.get("building_footprints"):
		plantas.append((fp["rect"] as Rect2).grow(4.0))
	var usados: Array = []
	for e in lista:
		usados.append(e[1])
	var grupos: Array = [] # [centro, [registros]]
	for r in AN.grabado:
		var p: Vector2 = r[2]
		var dentro := false
		for pl in plantas:
			if (pl as Rect2).has_point(p):
				dentro = true
				break
		for u in usados:
			if p.distance_to(u) < 14.0:
				dentro = true
				break
		if dentro:
			continue
		var g_hit = null
		for g in grupos:
			if p.distance_to(g[0]) < 14.0:
				g_hit = g
				break
		if g_hit == null:
			grupos.append([p, [r]])
		else:
			(g_hit[1] as Array).append(r)
	var n_anc := 0
	for g in grupos:
		var recs: Array = g[1]
		var c2: Vector2 = g[0]
		var radio := 12.0
		for r in recs:
			radio = maxf(radio, c2.distance_to(r[2]) + 10.0)
		var nombre := ""
		var modelo := ""
		for r in recs:
			var nm := String(r[1])
			if nombre.is_empty() or r[0] == "zona" or r[0] == "letrero":
				nombre = nm
			if "Mushroom" in nm: modelo = "nature/kenney/mushroom_red.glb"
			elif "Herb" in nm: modelo = "nature/Plant_4.obj"
			elif "well" in nm.to_lower(): modelo = "exterior/Well.obj"
		n_anc += 1
		var limpio := nombre.strip_edges()
		for ch in ["/", ":", "@", ".", "%", "\"", "\n", "[", "]"]:
			limpio = limpio.replace(ch, " ")
		limpio = limpio.substr(0, 40).strip_edges()
		lista.append(["ancla_%d" % n_anc, c2, modelo, 8.0 if modelo != "" else 10.0, ("%s (%d)" % [limpio, n_anc]) if limpio != "" else "Objeto %d" % n_anc, true, radio])
	print("HORNEAR_OBJ: %d registros, %d grupos-ancla" % [AN.grabado.size(), n_anc])

	var actual: Node = (load(ESCENA) as PackedScene).instantiate()
	# Decorado: cada objeto guarda su sitio original y su tamaño, para que las paredes invisibles y lo demás lo sigan
	var dec: Node = actual.get_node_or_null("Decorado")
	if dec != null:
		for z in dec.get_children():
			for o in z.get_children():
				if o.has_meta("pos_original"):
					continue
				var o3 := o as Node3D
				var p2 := Mapa3D.a_mapa(o3.position)
				var rad := 8.0
				for ch in o3.get_children():
					if ch is Node3D:
						var q := Mapa3D.a_mapa((ch as Node3D).position)
						rad = maxf(rad, q.length() + 8.0)
				o.set_meta("pos_original", p2)
				o.set_meta("radio", minf(rad, 60.0))
	var objs: Node = actual.get_node_or_null("Objetos")
	if objs == null:
		objs = Node3D.new()
		objs.name = "Objetos"
		actual.add_child(objs)
		objs.owner = actual
	var ya := {}
	for c in objs.get_children():
		ya[String(c.get("clave"))] = true
	var script_o = load("res://mapa/objeto.gd")
	var n := 0
	for e in lista:
		if ya.has(e[0]):
			continue
		var p: Vector2 = e[1]
		var h: float = WB.terrain_height_px(p)
		var o := Node3D.new()
		o.set_script(script_o)
		o.name = String(e[4]).replace(" ", "_").validate_node_name()
		o.set("clave", e[0])
		o.set("pos_original", p)
		o.set("modelo", e[2])
		o.set("alto", e[3])
		o.set("nombre_visible", e[4])
		if e.size() > 6:
			o.set("es_ancla", true)
			o.set("radio_ancla", e[6])
		o.position = Mapa3D.a_3d(p, h)
		objs.add_child(o)
		o.owner = actual
		n += 1
	var ps := PackedScene.new()
	var err := ps.pack(actual)
	if err == OK:
		err = ResourceSaver.save(ps, ESCENA)
	print("HORNEAR_OBJ: %d objetos añadidos (error %d)" % [n, err])
	quit(0 if err == OK else 1)
