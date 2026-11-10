extends SceneTree

## Editor del mapa (Claude Code, 2026-11-09): carga el juego sin ventana y guarda en res://mapa/referencia_mapa.json
## lo que hay hoy en el mapa (edificios, caminos, árboles y rocas, lago) para dibujarlo de fondo en el editor.
## Uso: timeout 120 flatpak run org.godotengine.Godot --headless --path . -s tools/volcar_referencia_mapa.gd

func _initialize() -> void:
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(40):
		await process_frame
	var vm = get_first_node_in_group("village_manager")
	if vm == null:
		vm = root.find_child("VillageManager", true, false)
	var out := {"edificios": [], "caminos": [], "arboles": [], "rocas": [], "lago": []}
	if vm != null:
		for b in vm.get("building_footprints"):
			var r: Rect2 = b["rect"]
			out["edificios"].append({"id": str(b.get("id", "")), "nombre": str(b.get("title", "")), "r": [r.position.x, r.position.y, r.size.x, r.size.y]})
		var er = vm.get("entities_root")
		for c in (er.get_children() if er != null else vm.get_children()):
			if c is Polygon2D and c.z_index == -3 and c.polygon.size() == 4:
				var pts: Array = []
				for p in c.polygon:
					pts.append([p.x + c.position.x, p.y + c.position.y])
				out["caminos"].append(pts)
	for n in _all(root):
		if n is Node2D and n.get_script() != null and str(n.get_script().resource_path).ends_with("HarvestableNode.gd"):
			var t: int = int(n.get("harvest_type"))
			if t == 0:
				continue
			var key := "arboles" if t == 1 else "rocas"
			out[key].append([roundf(n.global_position.x), roundf(n.global_position.y)])
	var FS = load("res://scripts/obstacles/FishingSpot.gd")
	for p in FS.LAKE_WATER_WORLD:
		out["lago"].append([p.x, p.y])
	var f := FileAccess.open("res://mapa/referencia_mapa.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("REF edificios=%d caminos=%d arboles=%d rocas=%d vm=%s" % [out["edificios"].size(), out["caminos"].size(), out["arboles"].size(), out["rocas"].size(), str(vm != null)])
	quit(0)


func _all(n: Node) -> Array:
	var o: Array = [n]
	for c in n.get_children():
		o.append_array(_all(c))
	return o
