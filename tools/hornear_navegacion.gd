extends SceneTree

## Herramienta fuera de partida para hornear una sola vez las mallas NavigationMesh 3D del valle y edificios.
## Uso completo: flatpak run org.godotengine.Godot --headless --path . -s tools/hornear_navegacion.gd
## Un solo edificio: flatpak run org.godotengine.Godot --headless --path . -s tools/hornear_navegacion.gd -- <id_edificio>

const MODELOS_SOLAR: Dictionary = {
	"modelo_casita": "res://mapa/edificios/modelo_casita.tscn",
	"modelo_casa": "res://mapa/edificios/modelo_casa.tscn",
	"modelo_casona": "res://mapa/edificios/modelo_casona.tscn",
}


func _initialize() -> void:
	await process_frame
	var t0: int = Time.get_ticks_msec()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var Edif = load("res://tools/hornear_nav_edificio.gd")
	var Sub = load("res://tools/hornear_nav_subsuelo.gd")
	var Campo = load("res://tools/hornear_nav_campo.gd")
	var Edificio = load("res://mapa/edificio.gd")
	if not args.is_empty() and args[0] != "--campo" and args[0] != "--edificios":
		var ok_uno: bool = _hornear_uno(String(args[0]), Edif, Sub, Edificio)
		var dt_uno: int = Time.get_ticks_msec() - t0
		print("HORNEAR_NAVEGACION [%s]: %s (%d ms)" % [args[0], "OK" if ok_uno else "ERROR", dt_uno])
		quit(0 if ok_uno else 1)
		return
	var fallos: int = 0
	var n_edif: int = 0
	if args.is_empty() or args[0] == "--edificios":
		var escenas: Dictionary = Edificio.escenas()
		for id_e: String in escenas:
			if id_e == "bajo_alcantarillas":
				continue
			n_edif += 1
			var ruta_e: String = (escenas[id_e] as PackedScene).resource_path
			if Edif.hornear_edificio(id_e, ruta_e) != OK:
				push_error("HORNEAR_NAVEGACION: falló %s" % id_e)
				fallos += 1
		for id_m: String in MODELOS_SOLAR:
			n_edif += 1
			if Edif.hornear_edificio(id_m, String(MODELOS_SOLAR[id_m])) != OK:
				push_error("HORNEAR_NAVEGACION: falló %s" % id_m)
				fallos += 1
		if Sub.hornear_alcantarillas() != OK:
			fallos += 1
		if Sub.hornear_sotano_club() != OK:
			fallos += 1
		n_edif += 2
	var t_edif: int = Time.get_ticks_msec() - t0
	var res_campo: Dictionary = Campo.hornear_campo() if (args.is_empty() or args[0] == "--campo") else {"err": OK, "sectores": 0}
	if int(res_campo.get("err", ERR_BUG)) != OK:
		fallos += 1
	var dt_total: int = Time.get_ticks_msec() - t0
	print("HORNEAR_NAVEGACION: edificios=%d (%d ms), sectores=%d (%d ms), total=%d ms (%.2f s), fallos=%d" % [
		n_edif, t_edif, int(res_campo.get("sectores", 0)), dt_total - t_edif, dt_total, float(dt_total) / 1000.0, fallos
	])
	quit(0 if fallos == 0 else 1)


func _hornear_uno(id_obj: String, edif_mod: Variant, sub_mod: Variant, edificio_mod: Variant) -> bool:
	if id_obj == "bajo_alcantarillas":
		return sub_mod.hornear_alcantarillas() == OK
	if id_obj == "sotano_club_pelea":
		return sub_mod.hornear_sotano_club() == OK
	if MODELOS_SOLAR.has(id_obj):
		return edif_mod.hornear_edificio(id_obj, String(MODELOS_SOLAR[id_obj])) == OK
	var escenas: Dictionary = edificio_mod.escenas()
	if not escenas.has(id_obj):
		push_error("HORNEAR_NAVEGACION: edificio desconocido «%s»" % id_obj)
		return false
	return edif_mod.hornear_edificio(id_obj, (escenas[id_obj] as PackedScene).resource_path) == OK
