extends SceneTree

## Editor del mapa 3D (Claude Code, 2026-11-10): crea en mapa/Mundo3D.tscn la carpeta «BajoTierra» (oculta; se enseña
## con el ojo) con la pieza «Alcantarillas»: una foto 3D de los túneles que se mueve entera (mapa/edificio.gd, id
## «bajo_alcantarillas»). El club de pelea no tiene pieza: va con la taberna. Necesita ventana:
##   flatpak run org.godotengine.Godot --path . -s tools/hornear_bajo_tierra.gd
## Si la pieza ya existe solo rehace la foto.

const ESCENA := "res://mapa/Mundo3D.tscn"
const FOTO := "res://mapa/edificios_vista/bajo_alcantarillas.scn"
const CENTRO := Vector2(420.0, 63.0)


func _initialize() -> void:
	var WB = load("res://scripts/visuals/WorldStageBase3D.gd")
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(60):
		await process_frame
	var stage: Node = null
	for c in root.find_children("*", "", true, false):
		if c.has_method("_build_sewers_3d"):
			stage = c
			break
	var red: Node3D = stage.get("sewers_root_3d")
	var copia: Node3D = red.duplicate()
	copia.visible = true
	copia.position = Vector3.ZERO
	for n in copia.find_children("*", "", true, false):
		n.owner = copia
	_externos(copia)
	var ps := PackedScene.new()
	var err := ps.pack(copia)
	if err == OK:
		err = ResourceSaver.save(ps, FOTO, ResourceSaver.FLAG_COMPRESS)
	print("HORNEAR_BT: foto (error %d)" % err)
	var actual: Node = (load(ESCENA) as PackedScene).instantiate()
	var bt: Node3D = actual.get_node_or_null("BajoTierra")
	if bt == null:
		bt = Node3D.new()
		bt.name = "BajoTierra"
		bt.visible = false
		actual.add_child(bt)
		bt.owner = actual
	if bt.get_node_or_null("Alcantarillas") == null:
		var h: float = WB.terrain_height_px(CENTRO)
		var p3 := Vector3(CENTRO.x * WB.WORLD_SCALE, (h * WB.WORLD_SCALE) / cos(deg_to_rad(WB.PITCH_DEG)), (CENTRO.y * WB.WORLD_SCALE) / sin(deg_to_rad(WB.PITCH_DEG)))
		var e := Node3D.new()
		e.set_script(load("res://mapa/edificio.gd"))
		e.name = "Alcantarillas"
		e.set("id_edificio", "bajo_alcantarillas")
		e.set("centro_original", CENTRO)
		e.set("origen_3d", p3)
		e.position = p3
		bt.add_child(e)
		e.owner = actual
		var ps2 := PackedScene.new()
		err = ps2.pack(actual)
		if err == OK:
			err = ResourceSaver.save(ps2, ESCENA)
		print("HORNEAR_BT: pieza añadida (error %d)" % err)
	quit(0 if err == OK else 1)


var _hechos := {}
var _n := 0
func _externos(n: Node) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var mats: Array = [mi.material_override]
		if mi.mesh is ArrayMesh:
			_ext(mi.mesh)
		for m in mats:
			if m == null:
				continue
			for pr in m.get_property_list():
				if pr["type"] == TYPE_OBJECT and m.get(pr["name"]) is ImageTexture:
					_ext(m.get(pr["name"]))


func _ext(r: Resource) -> void:
	if r == null or not r.resource_path.is_empty() or _hechos.has(r.get_instance_id()):
		return
	_hechos[r.get_instance_id()] = true
	_n += 1
	var path := "res://mapa/edificios_vista/comun/bajo_%d.res" % _n
	if ResourceSaver.save(r, path, ResourceSaver.FLAG_COMPRESS) == OK:
		r.take_over_path(path)
