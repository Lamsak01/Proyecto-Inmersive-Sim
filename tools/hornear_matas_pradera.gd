extends SceneTree

## Hornea una sola vez en Vegetacion/MatasPradera de res://mapa/Mundo3D.tscn las matas de hierba,
## flores y trigo que antes creaba por código WorldStageTerrain3D._build_ground_foliage_3d().

const ESCENA_JUEGO: String = "uid://dsoiuct8kdsk3"
const ESCENA_MAPA: String = "res://mapa/Mundo3D.tscn"
const MODELOS_MATAS: Array[String] = [
	"nature/Plant_1.obj", "nature/Plant_2.obj", "nature/Plant_3.obj",
	"nature/Flowers.obj", "nature/Plant_1.obj", "nature/Wheat.obj",
]
const NOMBRES_MATAS: Array[String] = [
	"MataHierba", "MataTrebol", "MataHelecho",
	"MataFlores", "MataHierba", "MataEspigas",
]


func _initialize() -> void:
	var mundo_juego: Node = (load(ESCENA_JUEGO) as PackedScene).instantiate()
	root.add_child(mundo_juego)
	await physics_frame
	await physics_frame
	var vm: Node = get_first_node_in_group("village_manager")
	var stage: Node = mundo_juego.find_child("WorldStage3D", true, false)
	var Rio = load("res://scripts/fisica/RioLago.gd")
	var Zona = load("res://mapa/zona.gd")
	var Rest = load("res://scripts/systems/VillageRestaurant.gd")
	var Tav = load("res://scripts/systems/VillageTavern.gd")
	var lake_guard: PackedVector2Array = Rio.lake_scaled(1.18, 12.0)
	var marsh_guard := PackedVector2Array([
		Vector2(-1890, 195), Vector2(-1620, 150), Vector2(-1325, 165), Vector2(-1180, 240),
		Vector2(-1200, 405), Vector2(-1345, 485), Vector2(-1660, 500), Vector2(-1875, 435),
		Vector2(-1930, 310),
	])
	var plaza_guard: Rect2 = Zona.rect_mundo("plaza").grow(65.0)
	var huellas: Array = vm.get("building_footprints") if vm != null else []
	var matas: Array[Dictionary] = []
	var idx: int = 0
	for gx: int in range(-2050, 1480, 95):
		for gy: int in range(-520, 1280, 95):
			idx += 1
			var fp := Vector2(float(gx) + float(((idx * 73) % 59) - 29), float(gy) + float(((idx * 41) % 59) - 29))
			var fp_mundo: Vector2 = Zona.estirar(fp)
			if not _mata_permitida(fp, fp_mundo, idx, plaza_guard, lake_guard, marsh_guard, Rio, Rest, Tav, stage, huellas):
				continue
			var k: int = idx % MODELOS_MATAS.size()
			var p3: Vector3 = stage.call("to_3d", fp_mundo, -0.8)
			matas.append({
				"pos": p3,
				"mdl": MODELOS_MATAS[k],
				"pref": NOMBRES_MATAS[k],
				"alto": 4.2 + float(idx % 4) * 1.1,
				"giro": float((idx * 53) % 360),
			})
	mundo_juego.free()
	var err: Error = _guardar_en_escena_mapa(matas)
	print("HORNEAR_MATAS_PRADERA: %d matas guardadas (err=%d)" % [matas.size(), err])
	quit(0 if err == OK else 1)


func _mata_permitida(fp: Vector2, fp_mundo: Vector2, idx: int, plaza: Rect2, lago: PackedVector2Array, cienaga: PackedVector2Array, Rio: Variant, Rest: Variant, Tav: Variant, stage: Node, huellas: Array) -> bool:
	if absf(fp.y - 50.0) < 30.0 or plaza.has_point(fp_mundo):
		return false
	if Geometry2D.is_point_in_polygon(fp, lago) or Geometry2D.is_point_in_polygon(fp, cienaga):
		return false
	if (fp - (Rio.LAKE_NODE_POS as Vector2)).length() < 95.0 or float(stage.call("terrain_height_px", fp_mundo)) < -0.8:
		return false
	if bool(stage.call("en_cauce_del_rio", fp_mundo, 18.0)):
		return false
	if fp.y >= float(Rio.river_y_start()) and fp.y <= float(Rio.river_y_end()) and absf(fp.x - float(Rio.river_center_x(fp.y))) < float(Rio.river_half_width(fp.y)) + 18.0:
		return false
	if Rect2(Vector2(85.0, -915.0), Vector2(95.0, 100.0)).has_point(fp) or (Rio.ABANDONED_MILL_RECT as Rect2).grow(18.0).has_point(fp):
		return false
	if (Rest.RECT as Rect2).grow(16.0).has_point(fp) or (Tav.RECT as Rect2).grow(16.0).has_point(fp):
		return false
	if Rect2(Vector2(822.0, 260.0), Vector2(268.0, 168.0)).grow(10.0).has_point(fp):
		return false
	if fp.x > 160.0 and fp.x < 1380.0 and fp.y > -480.0 and fp.y < 360.0 and ((idx % 3) != 0):
		return false
	for b_fp: Dictionary in huellas:
		if (b_fp["rect"] as Rect2).grow(12.0).has_point(fp_mundo):
			return false
	return true


func _guardar_en_escena_mapa(matas: Array[Dictionary]) -> Error:
	var escena: Node = (load(ESCENA_MAPA) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var veg: Node3D = escena.get_node("Vegetacion") as Node3D
	var viejo: Node = veg.get_node_or_null("MatasPradera")
	if viejo != null:
		viejo.owner = null
		veg.remove_child(viejo)
		viejo.free()
	var carpeta := Node3D.new()
	carpeta.name = "MatasPradera"
	veg.add_child(carpeta)
	carpeta.owner = escena
	var script_pieza: Script = load("res://mapa/pieza.gd") as Script
	var n: int = 0
	for m: Dictionary in matas:
		n += 1
		var p := Node3D.new()
		p.set_script(script_pieza)
		p.name = "%s_%d" % [String(m["pref"]), n]
		p.position = m["pos"] as Vector3
		p.rotation_degrees.y = float(m["giro"])
		p.set("choque", "ninguno")
		p.set("alto", float(m["alto"]))
		p.set("modelo", String(m["mdl"]))
		carpeta.add_child(p)
		p.owner = escena
	var ps := PackedScene.new()
	var err: Error = ps.pack(escena)
	if err == OK:
		err = ResourceSaver.save(ps, ESCENA_MAPA)
	escena.free()
	return err
