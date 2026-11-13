extends SceneTree

## Recorrido fijo de comprobación en 3D y 1.ª persona.
## Uso (con ventana para guardar capturas 3D reales):
##   timeout 180 flatpak run org.godotengine.Godot --path . -s tools/tests/recorrido_fijo.gd
## Visita siempre los mismos 8 sitios:
##   1) Entrada del pueblo, 2) Plaza, 3) Taberna por dentro, 4) Una casa,
##   5) Comisaría, 6) Cementerio, 7) Bosque, 8) Borde del lago.
## En cada sitio guarda captura en `docs/capturas_arreglos/recorrido/` y comprueba:
##   - que no hay errores en consola,
##   - que el jugador no cae al vacío ni queda atascado,
##   - que nadie (ni jugador ni vecinos) está metido en una pared.

const OUT_DIR: String = "docs/capturas_arreglos/recorrido"

const SITES: Array[Dictionary] = [
	{
		"id": "01_entrada_pueblo",
		"label": "Entrada del pueblo",
		"pos": Vector2(225.0, 50.0),
		"yaw": 0.0,
		"pitch": -0.04,
		"walk_dir": Vector2(1.0, 0.0),
	},
	{
		"id": "02_plaza",
		"label": "Plaza central",
		"pos": Vector2(420.0, 56.0),
		"yaw": -0.35,
		"pitch": -0.05,
		"walk_dir": Vector2(1.0, 0.0),
	},
	{
		"id": "03_taberna_interior",
		"label": "Taberna por dentro",
		"pos": Vector2(442.0, -184.0),
		"yaw": -2.45,
		"pitch": -0.06,
		"walk_dir": Vector2(-1.0, 0.0),
	},
	{
		"id": "04_una_casa",
		"label": "Una casa (Residencia Yunque Gris)",
		"pos": Vector2(745.0, -170.0),
		"yaw": -PI * 0.5,
		"pitch": -0.08,
		"walk_dir": Vector2(1.0, 0.0),
	},
	{
		"id": "05_comisaria",
		"label": "Comisaría de Policía",
		"pos": Vector2(922.0, 122.0),
		"yaw": 2.15,
		"pitch": -0.08,
		"walk_dir": Vector2(1.0, 0.0),
	},
	{
		"id": "06_cementerio",
		"label": "Cementerio Parroquial",
		"pos": Vector2(888.0, 290.0),
		"yaw": 1.05,
		"pitch": -0.08,
		"walk_dir": Vector2(0.0, 1.0),
	},
	{
		"id": "07_bosque",
		"label": "Bosque del Sur",
		"pos": Vector2(465.0, 690.0),
		"yaw": PI * 0.5,
		"pitch": -0.05,
		"walk_dir": Vector2(0.0, 1.0),
	},
	{
		"id": "08_borde_lago",
		"label": "Borde del lago",
		"pos": Vector2(-648.0, 108.0),
		"yaw": 3.05,
		"pitch": -0.06,
		"walk_dir": Vector2(0.0, 1.0),
	},
	{
		"id": "09_puente_viejo",
		"label": "Puente Viejo en el centro del pueblo",
		"pos": Vector2(82.0, 26.0),
		"yaw": 0.52,
		"pitch": -0.10,
		"walk_dir": Vector2(0.0, 1.0),
	},
	{
		"id": "10_claro_arroyo",
		"label": "Claro del arroyo (Caso I)",
		"pos": Vector2(142.0, -836.0),
		"yaw": -2.05,
		"pitch": -0.14,
		"walk_dir": Vector2(0.0, -1.0),
	},
	{
		"id": "11_molino_viejo",
		"label": "Molino Viejo Abandonado",
		"pos": Vector2(188.0, -1022.0),
		"yaw": -1.57,
		"pitch": -0.15,
		"walk_dir": Vector2(0.0, -1.0),
	},
]

class ConsoleErrorTracker extends Logger:
	var errors: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		var msg: String = "%s:%d (%s): %s %s" % [file, line, function, code, rationale]
		errors.append(msg.strip_edges())

	func _log_message(message: String, error: bool) -> void:
		if error:
			errors.append(message.strip_edges())

var _tracker: ConsoleErrorTracker = null

func _initialize() -> void:
	var t_start: int = Time.get_ticks_msec()
	_tracker = ConsoleErrorTracker.new()
	OS.add_logger(_tracker)
	seed(42)

	var abs_out_dir: String = ProjectSettings.globalize_path("res://" + OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_out_dir)

	var packed: PackedScene = load("uid://dsoiuct8kdsk3")
	root.add_child(packed.instantiate())
	for _i in range(35):
		await process_frame

	var gm = root.get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("set_demo_mode"):
		gm.call("set_demo_mode", true)

	var wc = root.get_node_or_null("/root/WorldClock")
	if wc != null:
		wc.set("current_hour", 13)
		wc.set("current_minute", 30)
		if wc.has_signal("time_updated"):
			wc.emit_signal("time_updated", int(wc.get("current_day")), 13, 30)

	for n in root.find_children("*", "", true, false):
		if n.has_method("close_controls_panel"):
			n.call("close_controls_panel")

	var vm = root.find_child("VillageManager", true, false)
	var pl = get_first_node_in_group("player") as CharacterBody2D
	var stage = null
	for n in root.find_children("*", "", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("WorldStage3D.gd"):
			stage = n
			break

	var failures: Array[String] = []
	if vm == null:
		failures.append("No se encontró VillageManager en la escena.")
	if pl == null:
		failures.append("No se encontró al jugador (grupo 'player') en la escena.")
	if stage == null:
		failures.append("No se encontró WorldStage3D en la escena.")
	else:
		stage.call("set_first_person", true)

	var is_headless: bool = DisplayServer.get_name() == "headless"

	for site in SITES:
		if pl == null or vm == null or stage == null:
			break
		var site_id: String = str(site["id"])
		var site_label: String = str(site["label"])
		var target_pos: Vector2 = site["pos"]
		var yaw: float = float(site["yaw"])
		var pitch: float = float(site["pitch"])
		var walk_dir: Vector2 = (site["walk_dir"] as Vector2).normalized()
		var err_count_before: int = _tracker.errors.size()

		# Colocar al jugador en primera persona 3D mirando hacia el punto de interés
		vm.call("set_player_elevation_level", 0)
		pl.velocity = Vector2.ZERO
		pl.global_position = target_pos
		if not bool(stage.get("first_person_active")):
			stage.call("set_first_person", true)
		stage.set("fp_yaw", yaw)
		stage.set("fp_pitch", pitch)
		stage.call("_update_fp_camera_transform")

		# Dejar estabilizar físicas, luces, tejados e IA durante 35 fotogramas
		for _f in range(35):
			await process_frame
		stage.set("fp_yaw", yaw)
		stage.set("fp_pitch", pitch)
		stage.call("_update_fp_camera_transform")
		await process_frame
		await process_frame

		# 1. Guardar captura en docs/capturas_arreglos/recorrido/
		var shot_path: String = "%s/%s.png" % [OUT_DIR, site_id]
		if not is_headless:
			var img: Image = root.get_viewport().get_texture().get_image()
			if img == null or img.is_empty() or img.get_width() < 64 or img.get_height() < 64:
				failures.append("[%s] Captura inválida o vacía." % site_id)
			else:
				var save_err: Error = img.save_png(shot_path)
				if save_err != OK:
					failures.append("[%s] Error al guardar captura en %s (err=%d)." % [site_id, shot_path, int(save_err)])

		# 2. Comprobar que el jugador no cae al vacío
		var p_pos: Vector2 = pl.global_position
		if not is_finite(p_pos.x) or not is_finite(p_pos.y):
			failures.append("[%s] Posición 2D del jugador no finita: %s" % [site_id, str(p_pos)])
		elif p_pos.distance_to(target_pos) > 28.0:
			failures.append("[%s] El jugador fue desplazado anormalmente de %s a %s" % [site_id, str(target_pos), str(p_pos)])

		var cam_3d: Camera3D = stage.get("cam_3d")
		if cam_3d == null or not is_instance_valid(cam_3d):
			failures.append("[%s] Cámara 3D inexistente." % site_id)
		else:
			var c_pos: Vector3 = cam_3d.global_position
			if not is_finite(c_pos.x) or not is_finite(c_pos.y) or not is_finite(c_pos.z):
				failures.append("[%s] Posición 3D de cámara no finita: %s" % [site_id, str(c_pos)])
			elif c_pos.y < -0.5 or c_pos.y > 10.0:
				failures.append("[%s] El jugador/cámara 3D cayó al vacío o fuera de cota (y=%.2f)." % [site_id, c_pos.y])

		if stage.has_method("ground_height_px"):
			var gh: float = float(stage.call("ground_height_px", p_pos))
			if not is_finite(gh) or gh < -8.0 or gh > 35.0:
				failures.append("[%s] Cota de terreno inválida en %s: gh=%.2f" % [site_id, str(p_pos), gh])

		# 3. Comprobar que el jugador no está metido en una pared ni queda atascado al caminar
		var pl_wall_issue: String = _check_point_in_walls(vm, p_pos, int(vm.get("player_elevation_level")), "Jugador")
		if pl_wall_issue != "":
			failures.append("[%s] %s" % [site_id, pl_wall_issue])

		var before_walk: Vector2 = pl.global_position
		for _step in range(18):
			pl.velocity = walk_dir * 85.0
			pl.move_and_slide()
			await physics_frame
		var walked_dist: float = pl.global_position.distance_to(before_walk)
		pl.velocity = Vector2.ZERO
		pl.global_position = target_pos
		await physics_frame
		if walked_dist < 5.0:
			failures.append("[%s] El jugador queda atascado al intentar caminar en %s (desplazamiento=%.2f px)." % [site_id, site_label, walked_dist])

		# 4. Comprobar que ningún vecino está metido en una pared
		var wall_issues: Array[String] = _check_all_npcs_not_in_walls(vm)
		for wi in wall_issues:
			failures.append("[%s] %s" % [site_id, wi])

		# 5. Comprobar errores en consola durante la visita a este sitio
		if _tracker.errors.size() > err_count_before:
			for e_idx in range(err_count_before, _tracker.errors.size()):
				failures.append("[%s] Error en consola: %s" % [site_id, _tracker.errors[e_idx]])

		print("RECORRIDO_SITE %s (%s) pos=%s walk=%.1fpx wall_issues=%d console_errs=%d shot=%s" % [
			site_id, site_label, str(target_pos), walked_dist, wall_issues.size(),
			_tracker.errors.size() - err_count_before, shot_path
		])

	var elapsed_sec: float = float(Time.get_ticks_msec() - t_start) / 1000.0
	print("RECORRIDO_TIME %.2fs" % elapsed_sec)
	if failures.is_empty():
		print("RECORRIDO PASSED")
		quit(0)
	else:
		print("RECORRIDO FAILED (%d fallos):" % failures.size())
		for f in failures:
			print(" - ", f)
		quit(1)

func _check_point_in_walls(vm: Node, pos: Vector2, elev: int, who: String, is_sleeping_npc: bool = false) -> String:
	if not is_finite(pos.x) or not is_finite(pos.y):
		return "%s tiene coordenadas no finitas: %s" % [who, str(pos)]
	if is_sleeping_npc:
		return ""
	var near_door: bool = false
	for d_entry in vm.get("building_doors"):
		var d_pos: Vector2 = d_entry.get("pos", Vector2.ZERO)
		var d_w: float = float(d_entry.get("width", 36.0))
		if pos.distance_to(d_pos) <= d_w * 0.5 + 8.0:
			near_door = true
			break
	if elev == 0:
		if vm.has_method("is_point_in_river_water") and bool(vm.call("is_point_in_river_water", pos)):
			return "%s está metido dentro del agua del río/arroyo en %s" % [who, str(pos.round())]
		var wall_rects: Array = vm.get("_wall_occluder_rects")
		for wr in wall_rects:
			var r: Rect2 = wr as Rect2
			if r.grow(1.5).has_point(pos) and not near_door:
				return "%s está metido en un muro/tabique en %s (muro=%s)" % [who, str(pos.round()), str(r)]
		for b in vm.get("building_footprints"):
			var br: Rect2 = b["rect"]
			var outer_r: Rect2 = br.grow(2.5)
			var inner_r: Rect2 = br.grow(-2.5)
			if outer_r.has_point(pos) and not inner_r.has_point(pos) and not near_door:
				return "%s está metido en la pared perimetral de %s en %s" % [who, str(b.get("id", "?")), str(pos.round())]
	elif elev == 1:
		for n in get_nodes_in_group("choques_piso_1"):
			if n is StaticBody2D and is_instance_valid(n):
				var sb := n as StaticBody2D
				for ch in sb.get_children():
					if ch is CollisionShape2D and ch.shape is RectangleShape2D:
						var sz: Vector2 = (ch.shape as RectangleShape2D).size
						var ur := Rect2(sb.global_position - sz * 0.5, sz)
						if ur.grow(1.5).has_point(pos):
							return "%s (planta 1) está metido en un tabique superior en %s (muro=%s)" % [who, str(pos.round()), str(ur)]
	return ""

func _check_all_npcs_not_in_walls(vm: Node) -> Array[String]:
	var issues: Array[String] = []
	for n in get_nodes_in_group("village_npcs"):
		if n == null or not is_instance_valid(n):
			continue
		if bool(n.get("is_dead")):
			continue
		var npc_name: String = str(n.get("npc_name"))
		var n_pos: Vector2 = (n as Node2D).global_position
		var elev: int = int(n.get("elevation_level"))
		var sleeping: bool = bool(n.get("is_sleeping"))
		var issue: String = _check_point_in_walls(vm, n_pos, elev, "Vecino '%s'" % npc_name, sleeping)
		if issue != "":
			issues.append(issue)
	return issues
