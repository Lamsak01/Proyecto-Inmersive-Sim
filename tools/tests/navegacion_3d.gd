extends SceneTree

## Prueba sin ventana de la malla de navegación 3D del valle, edificios y alcantarillas (Tarea 6d).
## Desde la plaza pide camino 3D a las 29 puertas, todas las marcas de edificio y todos los sitios exteriores.
## Uso: timeout 300 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/navegacion_3d.gd

const TOLERANCIA_M: float = 0.50


func _initialize() -> void:
	root.add_child((load("uid://dsoiuct8kdsk3") as PackedScene).instantiate())
	for _i: int in range(18):
		await physics_frame
		await process_frame
	var vm: Node = get_first_node_in_group("village_manager")
	var stage: Node = vm.get("world_stage_3d") as Node
	var map_rid: RID = (stage.get("stage_root_3d") as Node3D).get_world_3d().navigation_map
	await _esperar_mapa(map_rid)
	var Mapa3D = load("res://scripts/fisica/Mapa3D.gd")
	var Suelo = load("res://scripts/fisica/Suelo.gd")
	var Base3D = load("res://scripts/visuals/WorldStageBase3D.gd")
	var Edificio = load("res://mapa/edificio.gd")
	var Marca = load("res://mapa/marca.gd")
	var Sitio = load("res://mapa/sitio.gd")
	var Zona = load("res://mapa/zona.gd")
	var origen_3d: Vector3 = _punto_3d(Zona.centro_mundo("plaza"), 0, vm, Mapa3D, Suelo, Base3D)
	var alcanzables: int = 0
	var total: int = 0
	var fallos: Array[String] = []
	for d: Variant in vm.get("building_doors"):
		var dd: Dictionary = d as Dictionary
		var id_p: String = "puerta:" + String(dd.get("building_id", "?"))
		var dest_p: Vector3 = _punto_3d(dd["pos"] as Vector2, 0, vm, Mapa3D, Suelo, Base3D)
		total += 1
		if _probar_camino(map_rid, origen_3d, dest_p, id_p, fallos):
			alcanzables += 1
	var escenas: Dictionary = Edificio.escenas()
	var ids_edif: Array = escenas.keys()
	ids_edif.sort()
	for id_b_var: Variant in ids_edif:
		var id_b: String = String(id_b_var)
		var marcas_b: Dictionary = Marca.de_escena(escenas[id_b] as PackedScene)
		var nombres_m: Array = marcas_b.keys()
		nombres_m.sort()
		for nom_var: Variant in nombres_m:
			var nom_m: String = String(nom_var)
			var p_mundo: Vector2 = Marca.mundo(id_b, nom_m)
			var piso: int = 1 if (Suelo.es_arriba(p_mundo) or nom_m == "escalera_cima") else 0
			var dest_m: Vector3 = _punto_3d(p_mundo, piso, vm, Mapa3D, Suelo, Base3D)
			total += 1
			if _probar_camino(map_rid, origen_3d, dest_m, "marca:%s.%s" % [id_b, nom_m], fallos):
				alcanzables += 1
	var sitios: Dictionary = Sitio._todos()
	var ids_s: Array = sitios.keys()
	ids_s.sort()
	for id_s_var: Variant in ids_s:
		var id_s: String = String(id_s_var)
		var dest_s: Vector3 = _punto_3d(sitios[id_s] as Vector2, 0, vm, Mapa3D, Suelo, Base3D)
		total += 1
		if _probar_camino(map_rid, origen_3d, dest_s, "sitio:" + id_s, fallos):
			alcanzables += 1
	var alc_res: Vector2i = _probar_alcantarillas(map_rid, Mapa3D, Suelo)
	print("REGIONES ACTIVAS 3D: %d" % NavigationServer3D.map_get_regions(map_rid).size())
	print("ALCANTARILLAS 3D: %d/%d" % [alc_res.x, alc_res.y])
	for f: String in fallos:
		print("  INALCANZABLE  " + f)
	print("NAVEGACION 3D: %d/%d" % [alcanzables, total])
	quit(0)


func _esperar_mapa(map_rid: RID) -> void:
	var ult: int = -1
	var quietos: int = 0
	var pasos: int = 0
	while (ult < 2 or quietos < 45) and pasos < 450:
		await physics_frame
		await process_frame
		pasos += 1
		var act: int = NavigationServer3D.map_get_iteration_id(map_rid)
		quietos = (quietos + 1) if (act == ult and act >= 2) else 0
		ult = act


func _punto_3d(p: Vector2, piso: int, vm: Node, mapa3d: Variant, suelo: Variant, base3d: Variant) -> Vector3:
	var cota_px: float = float(base3d.terrain_height_px(p)) + float(suelo.altura_px(p, piso, vm))
	return mapa3d.a_3d(p, cota_px)


func _probar_camino(map_rid: RID, origen: Vector3, destino: Vector3, etiqueta: String, fallos: Array[String]) -> bool:
	var ruta: PackedVector3Array = NavigationServer3D.map_get_path(map_rid, origen, destino, true)
	if ruta.size() < 2:
		fallos.append("%s -> sin ruta hacia (%.2f, %.2f, %.2f)" % [etiqueta, destino.x, destino.y, destino.z])
		return false
	var final_p: Vector3 = ruta[ruta.size() - 1]
	var dist_m: float = final_p.distance_to(destino)
	if dist_m > TOLERANCIA_M:
		fallos.append("%s -> queda a %.2f m (fin=(%.2f, %.2f, %.2f), dest=(%.2f, %.2f, %.2f))" % [
			etiqueta, dist_m, final_p.x, final_p.y, final_p.z, destino.x, destino.y, destino.z
		])
		return false
	return true


func _probar_alcantarillas(map_rid: RID, mapa3d: Variant, suelo: Variant) -> Vector2i:
	var Under = load("res://scripts/systems/VillageUnderworld.gd")
	var locs: Dictionary = Under.SEWER_LOCATIONS
	var y_anden: float = float(mapa3d.alto_a_3d(suelo.PROFUNDIDAD_SOTANO_PX + 4.6))
	var orig: Vector3 = mapa3d.a_3d((locs["flooded_vault"] as Dictionary)["tunnel_pos"] as Vector2) + Vector3(-0.6, 0.0, 0.0)
	orig.y = y_anden
	var ok_n: int = 0
	var tot_n: int = 0
	var descartados: Array[String] = []
	for k_var: Variant in locs:
		var d: Dictionary = locs[k_var] as Dictionary
		for campo: String in ["tunnel_pos", "ladder_pos", "chest_pos"]:
			var pt: Vector3 = mapa3d.a_3d(d[campo] as Vector2)
			pt.y = y_anden
			tot_n += 1
			if _probar_camino(map_rid, orig, pt, "alcantarilla:%s.%s" % [String(k_var), campo], descartados):
				ok_n += 1
	for s: String in descartados:
		print("  FALLO_ALCANTARILLA  " + s)
	return Vector2i(ok_n, tot_n)
