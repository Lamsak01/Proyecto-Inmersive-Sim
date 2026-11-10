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
