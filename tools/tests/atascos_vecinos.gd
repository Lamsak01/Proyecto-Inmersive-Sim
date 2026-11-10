extends SceneTree

## Vecinos atascados (Claude Code, 2026-11-09): simula unas horas del pueblo sin ventana y apunta a quien intenta andar
## (velocidad > 5) pero en 6 s no avanza ni 4 px. Uso:
##   timeout 590 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/atascos_vecinos.gd -- [horas]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var hours: float = float(args[0]) if args.size() > 0 else 6.0
	seed(11)
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(30):
		await process_frame
	var gm = root.get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("set_demo_mode"):
		gm.call("set_demo_mode", true)
	var wc = root.get_node("/root/WorldClock")
	wc.current_hour = 7
	var FS = load("res://scripts/obstacles/FishingSpot.gd")
	var spg: float = float(wc.real_seconds_per_game_hour)
	var total_s: float = hours * spg
	var dt: float = 1.0 / 60.0
	var t: float = 0.0
	var last: Dictionary = {}
	var stuck_s: Dictionary = {}
	var reports: Dictionary = {}
	var sample: float = 0.0
	var phys0 := Engine.get_physics_frames()
	while t < total_s:
		await physics_frame
		t += dt
		sample += dt
		if sample < 1.0:
			continue
		sample = 0.0
		for n in get_nodes_in_group("village_npcs"):
			if not is_instance_valid(n) or n.is_dead or n.is_downed or n.is_sleeping:
				continue
			var k: String = str(n.npc_name)
			var p: Vector2 = n.global_position
			var trying: bool = n.velocity.length() > 5.0
			if last.has(k) and trying and p.distance_to(last[k]) < 0.7:
				stuck_s[k] = float(stuck_s.get(k, 0.0)) + 1.0
			else:
				if float(stuck_s.get(k, 0.0)) >= 6.0:
					_note(reports, k, n, last[k], float(stuck_s[k]), FS, wc)
				stuck_s[k] = 0.0
			last[k] = p
	for n in get_nodes_in_group("village_npcs"):
		var k2: String = str(n.npc_name)
		if float(stuck_s.get(k2, 0.0)) >= 6.0:
			_note(reports, k2, n, n.global_position, float(stuck_s[k2]), FS, wc)
	print("ATASCOS horas=%.1f pasos=%d vecinos=%d atascos=%d" % [hours, Engine.get_physics_frames() - phys0, get_nodes_in_group("village_npcs").size(), reports.size()])
	for k3 in reports.keys():
		print("ATASCO %s" % reports[k3])
	quit(0)


func _note(reports: Dictionary, k: String, n, p: Vector2, secs: float, FS, wc) -> void:
	var b: Vector2 = FS.river_banks_at(p.y)
	var near_river: bool = p.x > b.x - 25.0 and p.x < b.y + 25.0 and p.y > -1185.0 and p.y < 945.0
	var key: String = "%s@%d,%d" % [k, int(p.x / 20.0), int(p.y / 20.0)]
	var near: Array = []
	for o in n.get_tree().get_nodes_in_group("village_npcs"):
		if o != n and is_instance_valid(o) and o.global_position.distance_to(n.global_position) < 22.0:
			near.append("%s(%.0fpx,v=%.0f)" % [o.npc_name, o.global_position.distance_to(n.global_position), o.velocity.length()])
	var vm = n.get_tree().get_first_node_in_group("village_manager")
	var door: bool = vm != null and (vm.get_doorway_clearance_nudge(n.global_position, 22.0) as Vector2).length_squared() > 0.01
	reports[key] = "%s pos=%s seg=%d rio=%s act=%s destino=%s vel=%s puerta=%s cerca=[%s] hora=%d:%02d" % [k, str(p.round()), int(secs), str(near_river), str(n.get("current_activity")), str(n.get("_cached_nav_waypoint")), str(n.velocity.round()), str(door), ", ".join(near), int(wc.current_hour), int(wc.current_minute)]
