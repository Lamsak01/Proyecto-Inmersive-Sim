extends SceneTree

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
	var ws: float = WB.WORLD_SCALE
	var s: float = sin(deg_to_rad(WB.PITCH_DEG))
	var c: float = cos(deg_to_rad(WB.PITCH_DEG))
	var n := 0
	for r in T3.CALLES_PRINCIPALES + lots.ROADS:
		if not (r is Rect2):
			continue
		var rr := r as Rect2
		var cen := rr.get_center()
		var t := Node3D.new()
		t.set_script(load("res://mapa/camino.gd"))
		n += 1
		t.name = "Tramo_%d" % n
		t.position = Vector3(cen.x * ws, (WB.terrain_height_px(cen) * ws) / c, (cen.y * ws) / s)
		if rr.size.x >= rr.size.y:
			t.scale = Vector3(rr.size.x * ws, 1.0, rr.size.y * ws / s)
		else:
			t.rotation_degrees.y = 90.0
			t.scale = Vector3(rr.size.y * ws / s, 1.0, rr.size.x * ws)
		cam.add_child(t)
		t.owner = actual
	var ps := PackedScene.new()
	var err := ps.pack(actual)
	if err == OK:
		err = ResourceSaver.save(ps, ESCENA)
	print("HORNEAR_CAM: %d tramos (error %d)" % [n, err])
	quit(0 if err == OK else 1)
