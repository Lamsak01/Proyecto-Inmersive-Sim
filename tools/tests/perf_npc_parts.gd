extends SceneTree

## B3: cuánto cuesta cada parte de un vecino, sin ventana (la lógica del vecino es la misma con o sin ella). Uso:
##   flatpak run org.godotengine.Godot --headless --path . -s tools/tests/perf_npc_parts.gd -- 45
## Los nombres «a_*» van dentro de «movimiento hacia un punto» (que cuenta dentro de la actividad), «m_*» dentro
## del movimiento final; por eso no se suman con sus padres.

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var target: int = int(args[0]) if args.size() > 0 else 45
	seed(7)
	var packed: PackedScene = load("uid://dsoiuct8kdsk3")
	root.add_child(packed.instantiate())
	await process_frame
	await process_frame
	var vm = root.find_child("VillageManager", true, false)
	var wc = root.get_node("/root/WorldClock")
	wc.current_hour = 14
	var tex: Texture2D = vm._load_tex("res://assests/world/village/villager_innkeeper.png")
	var beds: Array = [Vector2(342, -252), Vector2(400, -252), Vector2(435, -252), Vector2(468, -252), Vector2(502, -252)].map(func(b: Vector2) -> Vector2: return vm.VillageTavern.al_mundo(b)) # al mundo
	var spots: Array = [Vector2(412, 54), Vector2(745, 312), Vector2(300, 120), Vector2(560, 80), Vector2(200, -60), Vector2(650, -40)].map(func(q: Vector2) -> Vector2: return q * vm.Mapa3D.E) # al mundo
	var i: int = 0
	while get_nodes_in_group("village_npcs").size() < target:
		var n = vm._spawn_generated_newcomer("NPC_Perf_", 0, 0, "Forastero (prueba)", tex, spots[i % spots.size()], beds[i % beds.size()], {}, spots[0], "none", "")
		n.global_position = spots[i % spots.size()] + Vector2(float(i % 7) * 9.0, float(i % 5) * 9.0)
		i += 1
	var pl = get_first_node_in_group("player")
	if pl != null:
		pl.global_position = Vector2(412, 54)
	var NPC = load("res://scripts/enemies/VillageNPC.gd")
	for lod in [true, false]:
		NPC.lod_enabled = lod
		for _w in range(240):
			await physics_frame
		NPC.perf_usec.clear()
		NPC.perf_on = true
		var steps: int = 600
		for _f in range(steps):
			await physics_frame
		NPC.perf_on = false
		var parts: Array = []
		var total: float = 0.0
		for k in NPC.perf_usec.keys():
			var ms: float = float(NPC.perf_usec[k]) / 1000.0 / float(steps)
			parts.append([k, ms])
		parts.sort_custom(func(a, b): return a[1] > b[1])
		for p in parts:
			print("PERF_PART lod=%s %s %.3fms" % [str(lod), p[0], p[1]])
	quit(0)
