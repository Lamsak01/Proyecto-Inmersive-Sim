extends SceneTree

## Fotos fijas del mundo en 1.ª persona (y una desde arriba, «arriba_plaza») para comparar antes y después de un cambio (Claude Code, 2026-11-10;
## paso del mundo a 3D, docs/PLAN_MUNDO_3D.md). Con ventana, ~2 min. Siempre los mismos sitios, mediodía, cielo
## despejado y SIN personajes (se mueven y estropearían la comparación).
## Uso: flatpak run org.godotengine.Godot --path . -s tools/tests/capturas_fijas.gd -- <carpeta> [carpeta_referencia]
## Con carpeta_referencia, compara foto a foto e imprime el % de píxeles distintos (CAPTURA <sitio> distinto=…%).

## Sitios en coordenadas del mundo (2026-11-12, corte final: ya no se traducen). Si se mueve una pieza del editor,
## la foto de ese sitio cambia: es lo esperado; se toma una referencia nueva.
const SITIOS: Array = [
	["plaza", Vector2(2110, 328), 0.0],
	["rio", Vector2(1930, 252), PI],
	["bosque", Vector2(690, -4310), -PI / 2.0],
	["molino", Vector2(942, -5280), -PI / 2.0],
	["mansion", Vector2(6575, -1650), -PI / 2.0],
	["taberna_dentro", Vector2(2156, -1094), 0.0],
	["capilla_altar", Vector2(3725, 1544), PI / 2.0],
	["capilla_fondo", Vector2(3722, 1564), -PI / 2.0],
	["casa_fuera", Vector2(1650, -2050), -PI / 2.0],
	["casa_dentro", Vector2(1650, -2098), -PI / 2.0],
	["casita_dentro", Vector2(930, -2105), -PI / 2.0],
	["casa_norte_fuera", Vector2(-3000, 3930), PI / 2.0],
	["casa_norte_dentro", Vector2(-3000, 3976), PI / 2.0],
	["puesto_paso", Vector2(7090, -94), 0.0],
	["lago", Vector2(-3200, 525), PI],
]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://capturas_fijas"
	var ref: String = args[1] if args.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(out)
	seed(7)
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(60):
		await process_frame
	var ui_root = get_first_node_in_group("game_ui")
	if ui_root != null:
		for m in ["close_hiring_letter_panel", "close_controls_panel"]:
			if ui_root.has_method(m):
				ui_root.call(m)
	var wc = root.get_node("/root/WorldClock")
	wc.current_hour = 12
	wc.current_minute = 0
	wc.set_weather(0)
	var stage = null
	for n in _todos(root):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("WorldStage3D.gd"):
			stage = n
	stage.call("set_first_person", true)
	var pl = get_first_node_in_group("player") as Node2D
	var total_dist: float = 0.0
	for s in SITIOS:
		pl.global_position = s[1]
		for _i in range(40):
			stage.set("fp_yaw", s[2])
			stage.set("fp_pitch", -0.05)
			var chars = stage.stage_root_3d.get_node_or_null("Characters3D")
			if chars:
				chars.visible = false
			await process_frame
		var img: Image = root.get_texture().get_image()
		img.save_png(out + "/" + str(s[0]) + ".png")
		if ref != "" and FileAccess.file_exists(ref + "/" + str(s[0]) + ".png"):
			var d: float = _distinto(img, Image.load_from_file(ref + "/" + str(s[0]) + ".png"))
			total_dist = maxf(total_dist, d)
			print("CAPTURA %s distinto=%.2f%% (protagonista en %s)" % [s[0], d, str(pl.global_position.round())])
		else:
			print("CAPTURA %s guardada" % s[0])
	# Vista desde arriba (paso 0b): el 3D debe cuadrar con el mapa del pueblo (casas, caminos, letreros)
	stage.call("set_first_person", false)
	pl.global_position = SITIOS[0][1]
	for _i in range(40):
		await process_frame
	var img_arriba: Image = root.get_texture().get_image()
	img_arriba.save_png(out + "/arriba_plaza.png")
	if ref != "" and FileAccess.file_exists(ref + "/arriba_plaza.png"):
		var d2: float = _distinto(img_arriba, Image.load_from_file(ref + "/arriba_plaza.png"))
		total_dist = maxf(total_dist, d2)
		print("CAPTURA arriba_plaza distinto=%.2f%%" % d2)
	else:
		print("CAPTURA arriba_plaza guardada")
	print("CAPTURAS_FIN peor=%.2f%%" % total_dist)
	quit(0)

## % de píxeles que cambian de forma apreciable (más de 24/255 en algún canal).
func _distinto(a: Image, b: Image) -> float:
	if a.get_size() != b.get_size():
		return 100.0
	var n: int = 0
	var paso: int = 4
	var total: int = 0
	for y in range(0, a.get_height(), paso):
		for x in range(0, a.get_width(), paso):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			total += 1
			if absf(ca.r - cb.r) > 0.094 or absf(ca.g - cb.g) > 0.094 or absf(ca.b - cb.b) > 0.094:
				n += 1
	return 100.0 * float(n) / float(maxi(1, total))

func _todos(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_todos(c))
	return out
