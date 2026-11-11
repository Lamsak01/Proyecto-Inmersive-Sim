extends SceneTree
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Editor del mapa 3D (Claude Code, 2026-11-10): crea en mapa/Mundo3D.tscn la carpeta «Caminos» con un tramo movible
## (mapa/camino.gd) por cada calle recta de siempre. Las callejas curvas del norte ya están en «Decorado».
##   flatpak run org.godotengine.Godot --headless --path . -s tools/hornear_caminos.gd
## No hace nada si «Caminos» ya existe.

const ESCENA := "res://mapa/Mundo3D.tscn"


func _initialize() -> void:
	var WB = load("res://scripts/visuals/WorldStageBase3D.gd")
	var T3 = load("res://scripts/visuals/WorldStageTerrain3D.gd")
	var lots = load("res://scripts/systems/VillageLots.gd")
	var actual: Node = (load(ESCENA) as PackedScene).instantiate()
	if actual.get_node_or_null("Caminos") != null:
		print("HORNEAR_CAM: «Caminos» ya existe; no se toca"); quit(1); return
	var cam := Node3D.new()
	cam.name = "Caminos"
	actual.add_child(cam)
	cam.owner = actual
	var n := 0
	for r in T3.CALLES_PRINCIPALES + lots.ROADS:
		if not (r is Rect2):
			continue
		var rr0 := r as Rect2
		# Mapa ×E: las calles se alargan E veces y se ensanchan (el doble a ×5), como el río
		var E: float = Mapa3D.E
		var ancho_x: float = 1.0 + (E - 1.0) * 0.25
		var rr := Rect2(rr0.position * E, rr0.size * E) if rr0.size.x >= rr0.size.y else Rect2(rr0.position * E, rr0.size * E)
		if rr0.size.x >= rr0.size.y:
			rr = Rect2(Vector2(rr.position.x, rr.get_center().y - rr0.size.y * ancho_x * 0.5), Vector2(rr.size.x, rr0.size.y * ancho_x))
		else:
			rr = Rect2(Vector2(rr.get_center().x - rr0.size.x * ancho_x * 0.5, rr.position.y), Vector2(rr0.size.x * ancho_x, rr.size.y))
		var cen := rr.get_center()
		var t := Node3D.new()
		t.set_script(load("res://mapa/camino.gd"))
		n += 1
		t.name = "Tramo_%d" % n
		t.position = Mapa3D.a_3d(cen, WB.terrain_height_px(cen))
		if rr.size.x >= rr.size.y:
			t.scale = Mapa3D.tam_a_3d(rr.size, 0.0) + Vector3(0, 1, 0)
		else:
			t.rotation_degrees.y = 90.0
			var tz := Mapa3D.tam_a_3d(rr.size, 0.0)
			t.scale = Vector3(tz.z, 1.0, tz.x)
		cam.add_child(t)
		t.owner = actual
	var ps := PackedScene.new()
	var err := ps.pack(actual)
	if err == OK:
		err = ResourceSaver.save(ps, ESCENA)
	print("HORNEAR_CAM: %d tramos (error %d)" % [n, err])
	quit(0 if err == OK else 1)
