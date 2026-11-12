extends SceneTree

## Mapa ×E (docs/specs/PLAN_MAPA_X3.md, 2026-11-11): al estirar el mapa los árboles quedan a E veces de distancia y el
## bosque se vuelve ralo. Esta herramienta añade, junto a cada árbol de mapa/Mundo3D.tscn → Vegetacion/Arboles, unos
## cuantos árboles más del mismo tipo (tamaño y giro al azar), sin pisar el río, los edificios ni otros árboles.
## Se ejecuta UNA vez: flatpak run org.godotengine.Godot --headless --path . -s tools/repoblar_bosque.gd -- [por_arbol] [sep_px]

const ESCENA := "res://mapa/Mundo3D.tscn"
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var por_arbol: int = int(args[0]) if args.size() > 0 else 3
	var sep: float = float(args[1]) if args.size() > 1 else 26.0
	var AN = load("res://mapa/anclas.gd")
	var FS = load("res://scripts/fisica/RioLago.gd")
	var escena: Node = (load(ESCENA) as PackedScene).instantiate()
	var arboles: Node = escena.get_node("Vegetacion/Arboles")
	var puestos: Array[Vector2] = []
	var originales: Array = []
	for a in arboles.get_children():
		puestos.append(Mapa3D.a_mapa((a as Node3D).position))
		originales.append(a)
	seed(17)
	var nuevos := 0
	for a in originales:
		var p0: Vector2 = Mapa3D.a_mapa((a as Node3D).position)
		var intentos := 0
		var hechos := 0
		while hechos < por_arbol and intentos < por_arbol * 6:
			intentos += 1
			var p: Vector2 = p0 + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(sep * 1.4, sep * 5.0)
			if FS.is_point_in_river_water(p, 14.0) or _pegado(p, puestos, sep) or AN.buscar(AN.desmover(p)).has("rect"):
				continue
			var t := Node3D.new()
			t.set_script(a.get_script())
			t.name = "%s_r%d" % [a.name, hechos + 1]
			t.position = Vector3(p.x * Mapa3D.ESCALA, (a as Node3D).position.y, p.y * Mapa3D.ESCALA)
			t.rotation_degrees.y = randf() * 360.0
			t.set("modelo", a.get("modelo"))
			t.set("alto", float(a.get("alto")) * randf_range(0.85, 1.15))
			t.set("choque", a.get("choque"))
			arboles.add_child(t)
			t.owner = escena
			puestos.append(p)
			hechos += 1
			nuevos += 1
	var ps := PackedScene.new()
	var err := ps.pack(escena)
	if err == OK:
		err = ResourceSaver.save(ps, ESCENA)
	print("REPOBLAR: %d árboles nuevos junto a %d (error %d)" % [nuevos, originales.size(), err])
	quit(0 if err == OK else 1)


func _pegado(p: Vector2, puestos: Array[Vector2], sep: float) -> bool:
	for q in puestos:
		if q.distance_squared_to(p) < sep * sep:
			return true
	return false
