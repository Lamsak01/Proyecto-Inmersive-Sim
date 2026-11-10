extends SceneTree

## Editor del mapa 3D (Claude Code, 2026-11-10): pasa a mapa/Mundo3D.tscn → «Vegetacion» los árboles, rocas, plantas y
## troncos que hasta ahora colocaba el código del terreno. Se ejecuta UNA vez (luego se editan a mano en Godot):
##   flatpak run org.godotengine.Godot --headless --path . -s tools/hornear_vegetacion.gd
## Conserva lo que haya en «Decoracion». Si «Vegetacion» ya tiene piezas, no hace nada (para no pisar cambios a mano),
## salvo que se pase «-- forzar».

var WB = null
const ESCENA := "res://mapa/Mundo3D.tscn"


func _initialize() -> void:
	WB = load("res://scripts/visuals/WorldStageBase3D.gd")
	if "vetas" in OS.get_cmdline_user_args():
		await _anadir_vetas()
		return
	if "talables" in OS.get_cmdline_user_args():
		await _anadir_talables()
		return
	var forzar: bool = "forzar" in OS.get_cmdline_user_args()
	var actual: Node = (load(ESCENA) as PackedScene).instantiate()
	var veg_vieja: Node = actual.get_node_or_null("Vegetacion")
	if veg_vieja != null and veg_vieja.get_child_count() > 0 and not forzar:
		print("HORNEAR: «Vegetacion» ya tiene piezas; no se toca (usa «-- forzar» para rehacerla)")
		quit(1)
		return
	WB.grabar_vegetacion = true
	WB.vegetacion_grabada.clear()
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(20):
		await process_frame
	var lista: Array = WB.vegetacion_grabada.duplicate()
	WB.grabar_vegetacion = false
	print("HORNEAR: %d piezas anotadas" % lista.size())

	var sin_p: float = sin(deg_to_rad(WB.PITCH_DEG))
	var cos_p: float = cos(deg_to_rad(WB.PITCH_DEG))
	var pieza_script = load("res://mapa/pieza.gd")
	var veg := Node3D.new()
	veg.name = "Vegetacion"
	var grupos := {}
	for nombre_g in ["Arboles", "Rocas", "Troncos", "Plantas"]:
		var g := Node3D.new()
		g.name = nombre_g
		veg.add_child(g)
		grupos[nombre_g] = g
	var cuenta := {}
	for r in lista:
		var f: String = String(r["modelo"]).get_file().get_basename()
		var g_n := "Plantas"
		if "Tree" in f or "Willow" in f:
			g_n = "Arboles"
		elif "Rock" in f:
			g_n = "Rocas"
		elif "WoodLog" in f or "Stump" in f:
			g_n = "Troncos"
		var p: Vector2 = r["pos"]
		var h: float = float(r["base"])
		if h > -40.0:
			h += WB.terrain_height_px(p)
		var n := Node3D.new()
		n.set_script(pieza_script)
		cuenta[f] = int(cuenta.get(f, 0)) + 1
		n.name = "%s_%d" % [f, cuenta[f]]
		n.position = Vector3(p.x * WB.WORLD_SCALE, (h * WB.WORLD_SCALE) / cos_p, (p.y * WB.WORLD_SCALE) / sin_p)
		n.rotation_degrees.y = float(r["giro"])
		n.set("alto", float(r["alto"]))
		n.set("tam", r["tam"])
		n.set("modelo", String(r["modelo"]))
		(grupos[g_n] as Node3D).add_child(n)

	if veg_vieja != null:
		actual.remove_child(veg_vieja)
		veg_vieja.free()
	actual.add_child(veg)
	veg.owner = actual
	_poner_dueno(veg, actual)
	var ps := PackedScene.new()
	var err := ps.pack(actual)
	if err == OK:
		err = ResourceSaver.save(ps, ESCENA)
	print("HORNEAR: guardado %s (error %d) · %s" % [ESCENA, err, str(cuenta)])
	quit(0 if err == OK else 1)


## Solo se guardan los nodos con dueño; los modelos que dibuja cada pieza no lo tienen (no se guardan).
func _poner_dueno(n: Node, dueno: Node) -> void:
	for c in n.get_children():
		if c.has_meta("pieza_modelo"):
			continue
		c.owner = dueno
		_poner_dueno(c, dueno)


## «-- talables»: añade a Vegetacion/Arboles los árboles talables que aún estaban en la lista de EcosystemManager
## (mismo modelo, altura y giro que les daba el juego). Después EcosystemManager deja de crearlos.
func _anadir_talables() -> void:
	var EM = load("res://scripts/systems/EcosystemManager.gd")
	EM.ignorar_escena = true
	var actual: Node = (load(ESCENA) as PackedScene).instantiate()
	var arboles: Node = actual.get_node_or_null("Vegetacion/Arboles")
	if arboles == null:
		print("HORNEAR: falta Vegetacion/Arboles"); quit(1); return
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(20):
		await process_frame
	var village := ["nature/CommonTree_1.obj", "nature/CommonTree_2.obj", "nature/BirchTree_1.obj", "nature/CommonTree_3.obj", "nature/BirchTree_2.obj", "nature/PineTree_1.obj", "nature/CommonTree_4.obj", "nature/BirchTree_3.obj", "nature/PineTree_2.obj"]
	var forest := ["nature/PineTree_1.obj", "nature/CommonTree_1.obj", "nature/PineTree_2.obj", "nature/BirchTree_1.obj", "nature/PineTree_3.obj", "nature/CommonTree_2.obj", "nature/PineTree_4.obj", "nature/CommonTree_3.obj", "nature/BirchTree_2.obj", "nature/CommonTree_4.obj", "nature/BirchTree_3.obj"]
	var sin_p: float = sin(deg_to_rad(WB.PITCH_DEG))
	var cos_p: float = cos(deg_to_rad(WB.PITCH_DEG))
	var pieza_script = load("res://mapa/pieza.gd")
	var n := 0
	for t in get_nodes_in_group("destructible"):
		if not String(t.name).begins_with("ForestTree_"):
			continue
		var pos: Vector2 = (t as Node2D).global_position
		var hv: int = absi(int(pos.x * 13.0 + pos.y * 7.0))
		var files: Array = forest if pos.y >= 680.0 else village
		var pz := Node3D.new()
		pz.set_script(pieza_script)
		n += 1
		pz.name = "Talable_%d" % n
		var h: float = WB.terrain_height_px(pos) - 1.4
		pz.position = Vector3(pos.x * WB.WORLD_SCALE, (h * WB.WORLD_SCALE) / cos_p, (pos.y * WB.WORLD_SCALE) / sin_p)
		pz.rotation_degrees.y = float(hv % 360)
		pz.set("alto", 52.0 + float(hv % 6) * 6.0)
		pz.set("modelo", String(files[hv % files.size()]))
		arboles.add_child(pz)
		pz.owner = actual
	var ps := PackedScene.new()
	var err := ps.pack(actual)
	if err == OK:
		err = ResourceSaver.save(ps, ESCENA)
	print("HORNEAR: %d árboles talables añadidos (error %d)" % [n, err])
	quit(0 if err == OK else 1)


## «-- vetas»: crea Vegetacion/Vetas con las vetas de mineral de EcosystemManager (mismo modelo, altura y giro).
func _anadir_vetas() -> void:
	var EM = load("res://scripts/systems/EcosystemManager.gd")
	EM.ignorar_escena = true
	var actual: Node = (load(ESCENA) as PackedScene).instantiate()
	var veg: Node = actual.get_node_or_null("Vegetacion")
	if veg == null or veg.get_node_or_null("Vetas") != null:
		print("HORNEAR: falta Vegetacion o ya hay Vetas"); quit(1); return
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(20):
		await process_frame
	var vetas := Node3D.new()
	vetas.name = "Vetas"
	veg.add_child(vetas)
	vetas.owner = actual
	var rfiles := ["nature/Rock_1.obj", "nature/Rock_2.obj", "nature/Rock_3.obj", "nature/Rock_4.obj", "nature/Rock_5.obj"]
	var sin_p: float = sin(deg_to_rad(WB.PITCH_DEG))
	var cos_p: float = cos(deg_to_rad(WB.PITCH_DEG))
	var pieza_script = load("res://mapa/pieza.gd")
	var n := 0
	for t in get_nodes_in_group("destructible"):
		if not String(t.name).begins_with("OreVein_"):
			continue
		var pos: Vector2 = (t as Node2D).global_position
		var hv: int = absi(int(pos.x * 13.0 + pos.y * 7.0))
		var pz := Node3D.new()
		pz.set_script(pieza_script)
		n += 1
		pz.name = "Veta_%d" % n
		var h: float = WB.terrain_height_px(pos) - 1.4
		pz.position = Vector3(pos.x * WB.WORLD_SCALE, (h * WB.WORLD_SCALE) / cos_p, (pos.y * WB.WORLD_SCALE) / sin_p)
		pz.rotation_degrees.y = float(hv % 360)
		pz.set("alto", 16.0)
		pz.set("modelo", String(rfiles[hv % rfiles.size()]))
		vetas.add_child(pz)
		pz.owner = actual
	var ps := PackedScene.new()
	var err := ps.pack(actual)
	if err == OK:
		err = ResourceSaver.save(ps, ESCENA)
	print("HORNEAR: %d vetas añadidas (error %d)" % [n, err])
	quit(0 if err == OK else 1)
