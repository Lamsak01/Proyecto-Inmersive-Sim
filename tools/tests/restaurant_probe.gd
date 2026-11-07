extends SceneTree

## Sonda R1b: deja correr la partida <días> días sin el jugador y cuenta quién lleva la trattoria, cuántos platos
## sirve y cuántas veces baja el cocinero a la cámara fría.
## Uso: flatpak run org.godotengine.Godot --headless --path . --fixed-fps 60 -s tools/tests/restaurant_probe.gd -- <días> <semilla>

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var days: int = int(args[0]) if args.size() > 0 else 4
	var seed_v: int = int(args[1]) if args.size() > 1 else 11
	seed(seed_v)
	root.add_child((load("uid://dsoiuct8kdsk3") as PackedScene).instantiate())
	await process_frame
	await process_frame
	var vm = root.find_child("VillageManager", true, false)
	var wc = root.get_node("/root/WorldClock")
	var rs = load("res://scripts/systems/VillageRestaurant.gd")
	vm.social_director.rng.seed = seed_v
	wc.set_persistent_time_scale(8.0)
	var start_day: int = int(wc.current_day)
	var last_h: int = -1
	while int(wc.current_day) < start_day + days:
		await create_timer(1.0).timeout
		if int(wc.current_hour) != last_h:
			last_h = int(wc.current_hour)
			var c = rs.cook(vm)
			var diners: int = 0
			for n in vm.VillageNeeds.living(vm):
				if n.get("_restaurant_seat") is Vector2 and n._restaurant_seat != Vector2.ZERO:
					diners += 1
			if last_h % 3 == 0 or diners > 0:
				print("D%d %02dh cocinero=%s sirve=%s stock=%s comensales=%d platos=%d" % [int(wc.current_day), last_h,
					(c.npc_name if c != null else "-"), str(rs.is_serving(vm)), (str(c.shop_stock) if c != null else "-"), diners, int(vm.get_meta("restaurant_meals", 0))])
	var c2 = rs.cook(vm)
	print("FIN platos=%d camara=%d cocinero=%s" % [int(vm.get_meta("restaurant_meals", 0)), (int(c2.get_meta("cold_room_trips", 0)) if c2 != null else -1), (c2.npc_name if c2 != null else "-")])
	quit(0)
