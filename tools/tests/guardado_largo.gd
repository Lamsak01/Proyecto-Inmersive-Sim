extends SceneTree

## Prueba de estabilidad de guardado/cierre/carga largo (7 días simulados).
## Uso:
##   timeout 540 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/guardado_largo.gd

const TEST_SAVE_PATH: String = "user://test_guardado_largo.save"
const SIM_DAYS: int = 7
const FRAMES_PER_HOUR: int = 12

class ConsoleErrorWatcher extends Logger:
	var errors: PackedStringArray = PackedStringArray()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array) -> void:
		var msg: String = "%s:%d (%s): %s | %s" % [file, line, function, code, rationale]
		errors.append(msg)

	func _log_message(message: String, error: bool) -> void:
		if error or message.begins_with("ERROR:") or message.begins_with("SCRIPT ERROR:"):
			errors.append(message.strip_edges())

var _logger: ConsoleErrorWatcher = null
var _failures: Array[String] = []
var _memory_samples: Array[Dictionary] = []

func _initialize() -> void:
	_logger = ConsoleErrorWatcher.new()
	OS.add_logger(_logger)
	call_deferred("_run_test")

func _fail(msg: String) -> void:
	print("  ❌ FALLO: " + msg)
	_failures.append(msg)

func _run_test() -> void:
	var t_start: int = Time.get_ticks_msec()
	print("==================================================================")
	print("💾 INICIANDO GUARDADO/CARGADO LARGO (7 DÍAS)")
	print("==================================================================")

	seed(12345)
	var packed: PackedScene = load("uid://dsoiuct8kdsk3")
	if packed == null:
		_fail("No se pudo cargar la escena principal (uid://dsoiuct8kdsk3)")
		_finish_and_quit(t_start)
		return

	var world: Node = packed.instantiate()
	root.add_child(world)
	for _i in range(25):
		await physics_frame
		await process_frame

	var vm = root.find_child("VillageManager", true, false)
	var player = get_first_node_in_group("player")
	var wc = root.get_node_or_null("/root/WorldClock")
	var gm = root.get_node_or_null("/root/GameManager")
	var qm = root.get_node_or_null("/root/QuestManager")
	var det_ui = root.find_child("DetectiveUI", true, false)

	if vm == null or player == null or wc == null or gm == null or qm == null or det_ui == null:
		_fail("Faltan nodos esenciales (vm=%s, player=%s, wc=%s, gm=%s, qm=%s, det_ui=%s)" % [
			str(vm != null), str(player != null), str(wc != null), str(gm != null), str(qm != null), str(det_ui != null)
		])
		_finish_and_quit(t_start)
		return

	if not bool(vm.get("demo_mode")):
		_fail("VillageManager.demo_mode debería estar activo (true)")

	# En modo headless, poblar también los ~40 vecinos iniciales para poner a prueba NPCs dinámicos y casas nuevas
	var mig = load("res://scripts/systems/VillageMigration.gd")
	if mig != null and mig.population(vm) < 35:
		mig.seed_start_population(vm)
		for _i in range(10):
			await physics_frame
			await process_frame

	# Preparar estado inicial variado: inventario, caso de detective, tablero y misiones
	_seed_initial_test_state(vm, player, qm, det_ui)

	var player_spots: Array[Vector2] = [
		Vector2(412.0, 54.0),    # Día 1: Plaza
		Vector2(442.0, -184.0),  # Día 2: Taberna interior
		Vector2(70.0, 44.0),     # Día 3: Casa del herrero
		Vector2(692.0, -172.0),  # Día 4: Comisaría
		Vector2(1070.0, 224.0),  # Día 5: Cementerio
		Vector2(1800.0, 380.0),  # Día 6: Bosque
		Vector2(-1155.0, -20.0)  # Día 7: Borde del lago
	]

	for day_idx in range(1, SIM_DAYS + 1):
		var err_before_day: int = _logger.errors.size()
		print("\n--- Simulando Día %d / %d ---" % [day_idx, SIM_DAYS])

		# Avanzar 24 horas en tramos de 1 hora con frames físicos entre medias para que los vecinos hagan su vida
		for h_step in range(24):
			wc.advance_hours(1)
			for _f in range(FRAMES_PER_HOUR):
				await physics_frame
			await process_frame

		# Asegurar que no haya avance rápido activo ni escolta policial antes de guardar
		if wc.is_fast_forwarding:
			wc.stop_organic_fast_forward(false)
		vm.player_being_escorted_to_jail = false
		if "is_sleeping_in_bed" in player and player.is_sleeping_in_bed:
			player.wake_up_from_bed()

		# Actualizar posición, oro, inventario, caso/tablero y misiones del día antes de guardar
		_apply_daily_state_mutations(day_idx, vm, player, qm, det_ui, player_spots[(day_idx - 1) % player_spots.size()])
		for _f in range(4):
			await physics_frame
			await process_frame

		# Capturar estado completo antes de guardar
		var pre_snap: Dictionary = _capture_important_state(vm, player, wc, qm, det_ui)

		# Guardar partida
		var saved_ok: bool = gm.save_game(TEST_SAVE_PATH)
		if not saved_ok:
			_fail("[Día %d] GameManager.save_game devolvió false" % day_idx)
			continue

		# Ensuciar el estado en memoria antes de cargar para comprobar que load_game de verdad restaura todo
		_dirty_state_before_load(vm, player, wc, qm, det_ui)

		# Cargar partida
		var loaded_ok: bool = gm.load_game(TEST_SAVE_PATH)
		if not loaded_ok:
			_fail("[Día %d] GameManager.load_game devolvió false" % day_idx)
			continue

		# Capturar estado inmediatamente después de cargar (sin avanzar más minutos del reloj) y comparar con pre_snap
		var post_snap: Dictionary = _capture_important_state(vm, player, wc, qm, det_ui)
		_compare_snapshots(day_idx, pre_snap, post_snap)

		for _f in range(2):
			await physics_frame
			await process_frame

		# Comprobar que no hay duplicados de vecinos ni objetos tras cargar el día
		_check_no_duplicates(day_idx, vm)

		# Comprobar errores de consola durante el día y el ciclo guardar/cargar
		if _logger.errors.size() > err_before_day:
			for e_i in range(err_before_day, _logger.errors.size()):
				_fail("[Día %d] Error en consola: %s" % [day_idx, _logger.errors[e_i]])

		# Registrar métricas de memoria y objetos
		var mem_sample: Dictionary = _record_memory_sample(day_idx, vm)
		_memory_samples.append(mem_sample)
		print("  📊 [Día %d] mem=%.2f MB | objs=%d | nodes=%d | orphans=%d | vivos=%d | cofres=%d | solares=%d" % [
			day_idx,
			float(mem_sample["static_mem_mb"]),
			int(mem_sample["objects"]),
			int(mem_sample["nodes"]),
			int(mem_sample["orphans"]),
			int(mem_sample["living_npcs"]),
			int(mem_sample["chests"]),
			int(mem_sample["footprints"])
		])

	# Comprobación final tras los 7 días: memoria acotada y sin fugas descontroladas
	_check_memory_growth()

	# Limpiar archivo temporal de guardado
	var abs_save: String = ProjectSettings.globalize_path(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(abs_save)

	_finish_and_quit(t_start)

func _seed_initial_test_state(vm: Node, player: Node, qm: Node, det_ui: Node) -> void:
	# 1. Oro e inventario del jugador
	if player.get("inventory") != null:
		player.inventory.gold = 250
		player.inventory.add_item("Pan", 3)
		player.inventory.add_item("Poción de Salud", 2)

	# 2. Caso de detective y registro forense
	vm.active_sheriff_investigation = {
		"active": true,
		"victim_name": "Aldric",
		"victim_key": "aldric",
		"weapon_name": "Daga",
		"reporter_name": "Garrick",
		"stage": "INTERVIEWS",
		"stage_timer": 12.5,
		"crime_pos_x": 420.0,
		"crime_pos_y": 60.0,
		"suspects": {
			"Garrick": {"score": 35, "motive": "Deuda pendiente", "alibi": "Carnicería"},
			"Bram": {"score": 20, "motive": "Discusión previa", "alibi": "Carpintería"}
		}
	}
	if vm.corpse_records.is_empty():
		vm.corpse_records.append({
			"victim_name": "Aldric",
			"cause": "Puñalada",
			"day": 1,
			"hour": 8,
			"pos_x": 420.0,
			"pos_y": 60.0
		})

	# 3. Tablero del detective y libreta
	det_ui.notebook_notes.clear()
	det_ui.notebook_notes.append({"title": "Pista Día 1", "body": "Huellas junto a la fuente de la plaza.", "day": 1})
	det_ui.board_positions = {
		"suspect:Garrick": Vector2(180.0, 120.0),
		"suspect:Bram": Vector2(420.0, 210.0)
	}
	det_ui.board_links.clear()
	det_ui.board_links.append({"from": "suspect:Garrick", "to": "suspect:Bram", "kind": "grudge"})
	det_ui.elapsed_minutes = 45
	det_ui.findings_count = 3
	if det_ui.has_method("save_detective_state"):
		det_ui.save_detective_state()

	# 4. Misiones en QuestManager
	qm.clear_all()
	var q1: String = qm.add_quest({
		"category": "errand",
		"type": "delivery",
		"title": "Entregar hierro a Thoran",
		"giver_key": "thoran",
		"giver_name": "Thoran",
		"target_key": "kael",
		"target_name": "Kael",
		"summary": "Lleva el lingote al taller.",
		"reward_gold": 40
	})
	qm.add_note(q1, "Thoran pidió prisa.")
	qm.set_offer("marta", {"type": "LostItem", "title": "Buscar jarra perdida", "reward_gold": 25})

func _apply_daily_state_mutations(day_idx: int, vm: Node, player: Node, qm: Node, det_ui: Node, target_pos: Vector2) -> void:
	# Mover jugador y ajustar oro/inventario de forma determinista por día
	vm.set_player_elevation_level(0)
	player.global_position = target_pos
	player.velocity = Vector2.ZERO
	if player.get("inventory") != null:
		player.inventory.gold = 200 + day_idx * 37
		player.inventory.add_item("Pan", 1)
		if day_idx == 3:
			player.inventory.add_item("Manzana", 4)
		elif day_idx == 5:
			player.inventory.remove_item("Pan", 2)

	# Evolucionar el caso de detective y el tablero cada día (sin llamar manualmente a save_detective_state
	# para verificar que GameManager.save_game sincroniza DetectiveUI automáticamente)
	vm.active_sheriff_investigation["stage_timer"] = float(day_idx * 10 + 3)
	var susp: Dictionary = vm.active_sheriff_investigation.get("suspects", {})
	if susp.has("Garrick"):
		susp["Garrick"]["score"] = 30 + day_idx * 5

	det_ui.notebook_notes.append({
		"title": "Nota Día %d" % day_idx,
		"body": "Observación anotada al cierre del día %d." % day_idx,
		"day": day_idx
	})
	det_ui.board_positions["clue:day_%d" % day_idx] = Vector2(100.0 + float(day_idx * 35), 140.0 + float(day_idx * 18))
	det_ui.board_links.append({
		"from": "suspect:Garrick",
		"to": "clue:day_%d" % day_idx,
		"kind": "evidence"
	})
	det_ui.elapsed_minutes = 45 + day_idx * 20
	det_ui.findings_count = 3 + day_idx

	# Evolucionar misiones
	if day_idx == 2:
		var q2: String = qm.add_quest({
			"category": "investigation",
			"type": "witness",
			"title": "Interrogar a Garrick (Día 2)",
			"giver_key": "comisario_vane",
			"giver_name": "Comisario Vane",
			"summary": "Pregunta por la noche anterior.",
			"reward_gold": 60
		})
		qm.add_note(q2, "Pista recibida en comisaría.")
	elif day_idx == 4:
		var active_q: Array = qm.get_active_quests()
		if not active_q.is_empty():
			var first_id: String = str(active_q[0].get("id", ""))
			if first_id != "":
				qm.complete_quest(first_id, "Completada en el día 4.")

func _dirty_state_before_load(vm: Node, player: Node, wc: Node, qm: Node, det_ui: Node) -> void:
	# Modificar el estado en memoria tras guardar para garantizar que load_game realmente lo pisa
	wc.current_hour = (wc.current_hour + 5) % 24
	wc.current_minute = (wc.current_minute + 27) % 60
	player.global_position += Vector2(123.0, -87.0)
	if player.get("inventory") != null:
		player.inventory.gold += 9999
		player.inventory.add_item("ObjetoFantasmaNoGuardado", 7)
	vm.active_sheriff_investigation["victim_name"] = "FANTASMA_NO_GUARDADO"
	for npc in get_nodes_in_group("village_npcs"):
		if is_instance_valid(npc) and not bool(npc.get("is_dead")):
			npc.global_position += Vector2(55.0, -45.0)
			if "elevation_level" in npc:
				npc.elevation_level = 1
			break
	det_ui.notebook_notes.append({"title": " basura ", "body": "no guardada", "day": 999})
	det_ui.board_positions["basura_key"] = Vector2(999.0, 999.0)
	det_ui.board_links.append({"from": "a", "to": "b", "kind": "fake"})
	qm.add_quest({"title": "Misión Fantasma Post-Save", "giver_key": "ghost"})

func _capture_important_state(vm: Node, player: Node, wc: Node, qm: Node, det_ui: Node) -> Dictionary:
	var inv_items: Dictionary = {}
	var gold: int = 0
	if player.get("inventory") != null:
		gold = int(player.inventory.gold)
		for k in player.inventory.items.keys():
			var cnt: int = int(player.inventory.items[k])
			if cnt > 0:
				inv_items[str(k)] = cnt

	var living_npcs: Dictionary = {}
	for npc in get_nodes_in_group("village_npcs"):
		if not is_instance_valid(npc) or npc.is_queued_for_deletion():
			continue
		if bool(npc.get("is_dead")):
			continue
		var key: String = npc.get_person_key() if npc.has_method("get_person_key") else ""
		if key == "":
			key = str(npc.npc_name) if "npc_name" in npc and str(npc.npc_name) != "" else str(npc.name)
		living_npcs[key] = {
			"node_name": str(npc.name),
			"npc_name": str(npc.npc_name),
			"pos": npc.global_position,
			"elevation": int(npc.elevation_level) if "elevation_level" in npc else 0,
			"work_pos": npc.work_position if "work_position" in npc else Vector2.ZERO,
			"bed_pos": npc.bed_position if "bed_position" in npc else Vector2.ZERO,
			"trade_role": int(npc.trade_role) if "trade_role" in npc else 0,
			"gold": int(npc.personal_gold) if "personal_gold" in npc else 0
		}

	var board_pos_copy: Dictionary = {}
	for bk in det_ui.board_positions.keys():
		board_pos_copy[str(bk)] = det_ui.board_positions[bk]

	return {
		"day": int(wc.current_day),
		"hour": int(wc.current_hour),
		"minute": int(wc.current_minute),
		"player_pos": player.global_position,
		"player_elevation": int(vm.player_elevation_level),
		"player_gold": gold,
		"inventory": inv_items,
		"living_npcs": living_npcs,
		"sheriff_case": vm.active_sheriff_investigation.duplicate(true),
		"corpse_records_count": vm.corpse_records.size(),
		"det_notes": det_ui.notebook_notes.duplicate(true),
		"det_positions": board_pos_copy,
		"det_links": det_ui.board_links.duplicate(true),
		"det_elapsed": int(det_ui.elapsed_minutes),
		"det_findings": int(det_ui.findings_count),
		"quests": qm.to_save_dict()
	}

func _compare_snapshots(day_idx: int, pre: Dictionary, post: Dictionary) -> void:
	var tag: String = "[Día %d]" % day_idx

	# 1. Hora y día
	if int(pre["day"]) != int(post["day"]) or int(pre["hour"]) != int(post["hour"]) or int(pre["minute"]) != int(post["minute"]):
		_fail("%s Hora/día distinto tras cargar: antes=%d %02d:%02d vs después=%d %02d:%02d" % [
			tag, int(pre["day"]), int(pre["hour"]), int(pre["minute"]),
			int(post["day"]), int(post["hour"]), int(post["minute"])
		])

	# 2. Posición, planta y dinero del jugador
	var p_pre: Vector2 = pre["player_pos"]
	var p_post: Vector2 = post["player_pos"]
	if p_pre.distance_to(p_post) > 0.5:
		_fail("%s Posición del jugador distinta: antes=%s vs después=%s" % [tag, str(p_pre), str(p_post)])
	if int(pre["player_elevation"]) != int(post["player_elevation"]):
		_fail("%s Planta del jugador distinta: antes=%d vs después=%d" % [tag, int(pre["player_elevation"]), int(post["player_elevation"])])
	if int(pre["player_gold"]) != int(post["player_gold"]):
		_fail("%s Oro del jugador distinto: antes=%d vs después=%d" % [tag, int(pre["player_gold"]), int(post["player_gold"])])

	# 3. Inventario
	var inv_pre: Dictionary = pre["inventory"]
	var inv_post: Dictionary = post["inventory"]
	if inv_pre.size() != inv_post.size():
		_fail("%s Inventario con distinto número de objetos: antes=%s vs después=%s" % [tag, str(inv_pre), str(inv_post)])
	else:
		for ik in inv_pre.keys():
			if not inv_post.has(ik) or int(inv_pre[ik]) != int(inv_post[ik]):
				_fail("%s Objeto '%s' distinto en inventario: antes=%s vs después=%s" % [
					tag, str(ik), str(inv_pre.get(ik)), str(inv_post.get(ik))
				])

	# 4. Vecinos vivos y su sitio
	var npcs_pre: Dictionary = pre["living_npcs"]
	var npcs_post: Dictionary = post["living_npcs"]
	if npcs_pre.size() != npcs_post.size():
		_fail("%s Número de vecinos vivos distinto: antes=%d vs después=%d" % [tag, npcs_pre.size(), npcs_post.size()])
	for nk in npcs_pre.keys():
		if not npcs_post.has(nk):
			_fail("%s Vecino vivo '%s' desapareció tras cargar" % [tag, str(nk)])
			continue
		var a: Dictionary = npcs_pre[nk]
		var b: Dictionary = npcs_post[nk]
		var pos_a: Vector2 = a["pos"]
		var pos_b: Vector2 = b["pos"]
		if pos_a.distance_to(pos_b) > 1.5:
			_fail("%s Vecino '%s' cambió de posición al cargar: antes=%s vs después=%s" % [
				tag, str(a["npc_name"]), str(pos_a), str(pos_b)
			])
		if int(a["elevation"]) != int(b["elevation"]):
			_fail("%s Vecino '%s' cambió de planta (elevation_level) al cargar: antes=%d vs después=%d" % [
				tag, str(a["npc_name"]), int(a["elevation"]), int(b["elevation"])
			])
		if int(a["trade_role"]) != int(b["trade_role"]):
			_fail("%s Vecino '%s' cambió de oficio al cargar: antes=%d vs después=%d" % [
				tag, str(a["npc_name"]), int(a["trade_role"]), int(b["trade_role"])
			])
		if int(a["gold"]) != int(b["gold"]):
			_fail("%s Vecino '%s' cambió de oro al cargar: antes=%d vs después=%d" % [
				tag, str(a["npc_name"]), int(a["gold"]), int(b["gold"])
			])
	for nk_post in npcs_post.keys():
		if not npcs_pre.has(nk_post):
			_fail("%s Vecino extra '%s' apareció tras cargar" % [tag, str(nk_post)])

	# 5. Caso de detective y tablero
	var sc_pre: Dictionary = pre["sheriff_case"]
	var sc_post: Dictionary = post["sheriff_case"]
	if JSON.stringify(sc_pre) != JSON.stringify(sc_post):
		_fail("%s Estado del caso de detective distinto tras cargar: antes=%s vs después=%s" % [
			tag, JSON.stringify(sc_pre), JSON.stringify(sc_post)
		])
	if int(pre["corpse_records_count"]) != int(post["corpse_records_count"]):
		_fail("%s Número de cadáveres forenses distinto: antes=%d vs después=%d" % [
			tag, int(pre["corpse_records_count"]), int(post["corpse_records_count"])
		])
	if JSON.stringify(pre["det_notes"]) != JSON.stringify(post["det_notes"]):
		_fail("%s Notas de DetectiveUI distintas tras cargar: antes=%s vs después=%s" % [
			tag, JSON.stringify(pre["det_notes"]), JSON.stringify(post["det_notes"])
		])
	if JSON.stringify(pre["det_links"]) != JSON.stringify(post["det_links"]):
		_fail("%s Vínculos del tablero de DetectiveUI distintos tras cargar: antes=%s vs después=%s" % [
			tag, JSON.stringify(pre["det_links"]), JSON.stringify(post["det_links"])
		])
	var dp_pre: Dictionary = pre["det_positions"]
	var dp_post: Dictionary = post["det_positions"]
	if dp_pre.size() != dp_post.size():
		_fail("%s Posiciones del tablero de DetectiveUI con distinto tamaño: antes=%d vs después=%d" % [
			tag, dp_pre.size(), dp_post.size()
		])
	else:
		for pk in dp_pre.keys():
			if not dp_post.has(pk) or (dp_pre[pk] as Vector2).distance_to(dp_post[pk] as Vector2) > 0.5:
				_fail("%s Pin '%s' del tablero de DetectiveUI distinto: antes=%s vs después=%s" % [
					tag, str(pk), str(dp_pre.get(pk)), str(dp_post.get(pk))
				])
	if int(pre["det_elapsed"]) != int(post["det_elapsed"]) or int(pre["det_findings"]) != int(post["det_findings"]):
		_fail("%s Contadores de DetectiveUI distintos: antes=(%d, %d) vs después=(%d, %d)" % [
			tag, int(pre["det_elapsed"]), int(pre["det_findings"]), int(post["det_elapsed"]), int(post["det_findings"])
		])

	# 6. Misiones (QuestManager)
	if JSON.stringify(pre["quests"]) != JSON.stringify(post["quests"]):
		_fail("%s Misiones en QuestManager distintas tras cargar: antes=%s vs después=%s" % [
			tag, JSON.stringify(pre["quests"]), JSON.stringify(post["quests"])
		])

func _check_no_duplicates(day_idx: int, vm: Node) -> void:
	var tag: String = "[Día %d]" % day_idx
	var seen_person_keys: Dictionary = {}
	var seen_npc_names: Dictionary = {}
	for npc in get_nodes_in_group("village_npcs"):
		if not is_instance_valid(npc) or npc.is_queued_for_deletion() or bool(npc.get("is_dead")):
			continue
		var pk: String = npc.get_person_key() if npc.has_method("get_person_key") else ""
		if pk != "":
			if seen_person_keys.has(pk):
				_fail("%s Vecino duplicado con person_key '%s' (%s y %s)" % [tag, pk, str(seen_person_keys[pk]), str(npc.name)])
			seen_person_keys[pk] = npc.name
		var nm: String = str(npc.npc_name)
		if nm != "":
			if seen_npc_names.has(nm):
				_fail("%s Vecino duplicado con nombre '%s' (%s y %s)" % [tag, nm, str(seen_npc_names[nm]), str(npc.name)])
			seen_npc_names[nm] = npc.name

	# Comprobar que no se duplican cofres ni puertas de edificios
	var seen_chests: Dictionary = {}
	for ch in vm.house_chests:
		var pos: Vector2 = ch.get("pos", Vector2.ZERO)
		var ck: String = "%d_%d" % [int(round(pos.x)), int(round(pos.y))]
		if seen_chests.has(ck):
			_fail("%s Cofre duplicado en %s (%s)" % [tag, ck, str(ch.get("title", ""))])
		seen_chests[ck] = true

	var seen_doors: Dictionary = {}
	for d in vm.building_doors:
		var pos_d: Vector2 = d.get("pos", Vector2.ZERO)
		var dk: String = "%d_%d" % [int(round(pos_d.x)), int(round(pos_d.y))]
		if seen_doors.has(dk):
			_fail("%s Puerta duplicada en %s (%s)" % [tag, dk, str(d.get("building_id", ""))])
		seen_doors[dk] = true

func _record_memory_sample(day_idx: int, vm: Node) -> Dictionary:
	var living_count: int = 0
	for npc in get_nodes_in_group("village_npcs"):
		if is_instance_valid(npc) and not npc.is_queued_for_deletion() and not bool(npc.get("is_dead")):
			living_count += 1
	return {
		"day": day_idx,
		"static_mem_mb": float(OS.get_static_memory_usage()) / (1024.0 * 1024.0),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"living_npcs": living_count,
		"chests": vm.house_chests.size(),
		"footprints": vm.building_footprints.size()
	}

func _check_memory_growth() -> void:
	if _memory_samples.size() < 2:
		return
	var s_day2: Dictionary = _memory_samples[1]
	var s_last: Dictionary = _memory_samples[_memory_samples.size() - 1]
	var mem_diff_mb: float = float(s_last["static_mem_mb"]) - float(s_day2["static_mem_mb"])
	var node_diff: int = int(s_last["nodes"]) - int(s_day2["nodes"])
	var orphan_diff: int = int(s_last["orphans"]) - int(s_day2["orphans"])

	print("\n📈 RESUMEN DE MEMORIA (Día 1 -> Día 7):")
	for s in _memory_samples:
		print("  Día %d: %.2f MB | nodos=%d | objetos=%d | huérfanos=%d | vecinos=%d" % [
			int(s["day"]), float(s["static_mem_mb"]), int(s["nodes"]), int(s["objects"]), int(s["orphans"]), int(s["living_npcs"])
		])
	print("  Variación Día 2 -> Día 7: %+.2f MB | nodos=%+d | huérfanos=%+d" % [mem_diff_mb, node_diff, orphan_diff])

	if mem_diff_mb > 35.0:
		_fail("La memoria estática creció demasiado entre el Día 2 y el Día 7 (+%.2f MB)" % mem_diff_mb)
	if orphan_diff > 20:
		_fail("Los nodos huérfanos crecieron entre el Día 2 y el Día 7 (+%d)" % orphan_diff)
	if node_diff > 600:
		_fail("El número de nodos en escena creció sin control entre el Día 2 y el Día 7 (+%d)" % node_diff)

func _finish_and_quit(t_start: int) -> void:
	var elapsed_sec: float = float(Time.get_ticks_msec() - t_start) / 1000.0
	print("==================================================================")
	if _failures.is_empty():
		print("GUARDADO LARGO PASSED (%.1fs)" % elapsed_sec)
		quit(0)
	else:
		print("GUARDADO LARGO FAILED (%d fallos en %.1fs):" % [_failures.size(), elapsed_sec])
		for f in _failures:
			print(" - " + f)
		quit(1)
