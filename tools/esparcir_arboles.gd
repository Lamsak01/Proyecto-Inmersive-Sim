extends SceneTree
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Fallo visible «árboles metidos unos dentro de otros» (usuario, 2026-11-09; arreglo 2026-11-12): quita de
## mapa/Mundo3D.tscn → Vegetacion/Arboles los árboles cuyo tronco está a menos de `sep` px de otro ya conservado.
## Solo mira dentro del rectángulo dado (coordenadas del mapa); sin rectángulo, todo el mapa. Se ejecuta una vez:
##   flatpak run org.godotengine.Godot --headless --path . -s tools/esparcir_arboles.gd -- 20 30,-1190,330,-730
const ESCENA := "res://mapa/Mundo3D.tscn"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var sep: float = float(args[0]) if args.size() > 0 else 20.0
	var zona := Rect2(-1e6, -1e6, 2e6, 2e6)
	if args.size() > 1:
		var v: PackedFloat64Array = args[1].split_floats(",")
		zona = Rect2(v[0], v[1], v[2] - v[0], v[3] - v[1])
	var escena: Node = (load(ESCENA) as PackedScene).instantiate()
	var arboles: Node = escena.get_node("Vegetacion/Arboles")
	var puestos: Array[Vector2] = []
	var quitados := 0
	for a in arboles.get_children():
		var p: Vector2 = Mapa3D.a_mapa((a as Node3D).position)
		if not zona.has_point(p):
			continue
		if _pegado(p, puestos, sep):
			arboles.remove_child(a)
			a.free()
			quitados += 1
		else:
			puestos.append(p)
	var ps := PackedScene.new()
	var err := ps.pack(escena)
	if err == OK:
		err = ResourceSaver.save(ps, ESCENA)
	print("ESPARCIR: %d árboles quitados de %d mirados (sep %.0f px) · guardado %s (error %d)" % [quitados, quitados + puestos.size(), sep, ESCENA, err])
	quit(0 if err == OK else 1)


func _pegado(p: Vector2, puestos: Array[Vector2], sep: float) -> bool:
	for q in puestos:
		if q.distance_squared_to(p) < sep * sep:
			return true
	return false
