extends SceneTree

## Captura fotos del juego en 3D (con ventana real, NO headless) para revisar la estética.
## Uso: flatpak run org.godotengine.Godot --path . -s tools/screenshot_3d.gd -- <carpeta_salida> [horas separadas por comas] [sitios]
## Sitios: plaza, iglesia, lago, cementerio, cerca (jugador de cerca), campamento. Por defecto: todos.
## En «campamento» siembra cultivos de muestra en el huerto (solo en memoria) para ver cada fase.
## Guarda <carpeta>/<sitio>_<hora>h.png. No toca la partida guardada.

var SPOTS := {
	"plaza": Vector2(465, 48),
	"iglesia": Vector2(650, 150),
	"lago": Vector2(-65, 140),
	"cementerio": Vector2(930, 300),
	"cerca": Vector2(470, 70),
	"retrato": Vector2(470, 60),
	"campamento": Vector2(150, 62),
}

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://shots"
	var hours: Array = [10, 18, 23]
	if args.size() > 1 and not args[1].is_empty():
		hours = []
		for h in args[1].split(","):
			hours.append(int(h))
	var spots: Array = SPOTS.keys()
	var grid_mode := false
	if args.size() > 2 and not args[2].is_empty():
		spots = Array(args[2].split(","))
		grid_mode = args[2] == "rejilla"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var packed: PackedScene = load("uid://dsoiuct8kdsk3")
	root.add_child(packed.instantiate())
	for i in range(30):
		await process_frame
	var wc = root.get_node("/root/WorldClock")
	if wc.has_method("set_activity_pause"):
		wc.set_activity_pause(true)
	var ui := root.find_child("UI", true, false)
	if ui is CanvasLayer:
		(ui as CanvasLayer).visible = false
	if spots.has("campamento"):
		var plots := get_nodes_in_group("farm_plots")
		for i in range(plots.size()):
			var fp = plots[i]
			if i % 4 == 3:
				continue
			fp.crop_type = 1 + (i % 3)
			fp.days_grown = int(i / 3.0)
			fp.is_watered = i % 2 == 0
			fp._refresh_visuals()
	var player := get_first_node_in_group("player") as Node2D
	var cam := player.get_node_or_null("Camera2D") as Camera2D if player != null else null
	SPOTS["inicio"] = player.global_position
	if grid_mode:
		# Recorre todo el valle (-920..1000 x -340..1300) con la cámara alejada al máximo, más la posición inicial.
		spots = ["inicio"]
		var gy := -150.0
		while gy <= 1250.0:
			var gx := -700.0
			while gx <= 1000.0:
				var key := "r_%d_%d" % [int(gx), int(gy)]
				SPOTS[key] = Vector2(gx, gy)
				spots.append(key)
				gx += 560.0
			gy += 400.0
	for h in hours:
		wc.current_hour = int(h)
		wc.current_minute = 0
		wc.time_updated.emit(wc.current_day, wc.current_hour, wc.current_minute)
		for s in spots:
			if player != null:
				player.global_position = SPOTS[s]
				if cam != null:
					cam.zoom = Vector2(8.0, 8.0) if s == "retrato" else (Vector2(4.0, 4.0) if s == "cerca" else Vector2(2.4, 2.4))
					if String(s).begins_with("r_") or s == "lago":
						cam.zoom = Vector2(1.4, 1.4)
					cam.reset_smoothing()
			for i in range(90):
				await process_frame
			var img: Image = root.get_texture().get_image()
			var p := "%s/%s_%02dh.png" % [out_dir, s, int(h)]
			img.save_png(p)
			print("SHOT ", p, " fps=", Engine.get_frames_per_second())
	quit(0)
