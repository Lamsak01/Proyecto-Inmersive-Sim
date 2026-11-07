extends SceneTree

## Sonda: busca huecos libres grandes en el mapa (para edificios nuevos grandes). Sin ventana:
##   flatpak run org.godotengine.Godot --headless --path . -s tools/tests/free_space_probe.gd -- 300 260
## Imprime los edificios y los mejores huecos (ancho × alto) que no pisan edificios, solares, calles ni muros.

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var W: float = float(args[0]) if args.size() > 0 else 300.0
	var H: float = float(args[1]) if args.size() > 1 else 260.0
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(30):
		await process_frame
	var vm = root.find_child("VillageManager", true, false)
	var lots = load("res://scripts/systems/VillageLots.gd")
	var blocks: Array[Rect2] = []
	for b in vm.building_footprints:
		var r: Rect2 = b["rect"]
		blocks.append(r.grow(14.0))
		print("BUILDING %s | %s | %s" % [str(b["id"]), str(b["title"]), str(r)])
	for l in lots.LOTS:
		var d: Dictionary = lots.lot_def(str(l["id"]))
		blocks.append(Rect2(Vector2(d["center"]) - Vector2(d["size"]) * 0.5, Vector2(d["size"])).grow(8.0))
	for r in lots.ROADS:
		blocks.append((r as Rect2).grow(6.0))
	for road in lots.CURVED_ROADS:
		var pts: PackedVector2Array = lots.curved_road_points(road)
		for p in pts:
			blocks.append(Rect2(p - Vector2(30, 22), Vector2(60, 44)))
	var n_static: int = 0
	for c in vm.entities_root.get_children():
		if c is StaticBody2D:
			for s in c.get_children():
				if s is CollisionShape2D and s.shape is RectangleShape2D:
					var sz: Vector2 = (s.shape as RectangleShape2D).size
					blocks.append(Rect2((c as Node2D).global_position + (s as Node2D).position - sz * 0.5, sz).grow(4.0))
					n_static += 1
				elif s is CollisionShape2D and s.shape is CircleShape2D:
					var rad: float = (s.shape as CircleShape2D).radius
					blocks.append(Rect2((c as Node2D).global_position - Vector2(rad, rad), Vector2(rad, rad) * 2.0).grow(4.0))
					n_static += 1
	print("STATIC_SHAPES %d" % n_static)
	# Suelos pintados, campos, cementerio, vallas (sin colisión): también ocupan sitio
	var n_poly: int = 0
	for c in vm.entities_root.get_children():
		var pts: PackedVector2Array = PackedVector2Array()
		if c is Polygon2D:
			pts = (c as Polygon2D).polygon
		elif c is Line2D:
			pts = (c as Line2D).points
		if pts.size() >= 2:
			var r := Rect2(pts[0], Vector2.ZERO)
			for q in pts:
				r = r.expand(q)
			r.position += (c as Node2D).global_position
			if r.size.x * r.size.y > 400.0 or r.size.x > 30.0 or r.size.y > 30.0:
				blocks.append(r.grow(10.0))
				n_poly += 1
	print("POLYS %d" % n_poly)
	var found: Array = []
	var y: float = -950.0
	while y < 1100.0:
		var x: float = -900.0
		while x < 1900.0:
			var cand := Rect2(Vector2(x, y), Vector2(W, H))
			var ok: bool = true
			for bl in blocks:
				if bl.intersects(cand):
					ok = false
					break
			if ok:
				found.append(cand)
			x += 20.0
		y += 20.0
	# Agrupar: quedarnos con candidatos que no se pisen entre sí, los más cercanos al centro del pueblo (700, -100)
	found.sort_custom(func(a, b): return a.get_center().distance_to(Vector2(700, -150)) < b.get_center().distance_to(Vector2(700, -150)))
	var picked: Array = []
	for f in found:
		var clash: bool = false
		for p in picked:
			if (p as Rect2).grow(80.0).intersects(f):
				clash = true
				break
		if not clash:
			picked.append(f)
		if picked.size() >= 10:
			break
	for p in picked:
		var near: String = ""
		var best: float = INF
		for b in vm.building_footprints:
			var dd: float = (b["rect"] as Rect2).get_center().distance_to((p as Rect2).get_center())
			if dd < best:
				best = dd
				near = str(b["title"])
		print("FREE %s center=%s nearest=%s (%.0f px)" % [str(p), str((p as Rect2).get_center()), near, best])
	quit()
