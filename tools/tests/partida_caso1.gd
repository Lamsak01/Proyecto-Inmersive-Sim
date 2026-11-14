extends SceneTree
const MapaViejo = preload("res://tools/tests/mapa_viejo.gd") ## posiciones escritas en el mapa original → mundo

## Partida automática completa del Caso I (a pie, sin teletransportar ni atravesar paredes).
## Uso:
##   timeout 180 flatpak run org.godotengine.Godot --path . -s tools/tests/partida_caso1.gd

const Marca = preload("res://mapa/marca.gd")
const Sitio = preload("res://mapa/sitio.gd")
const Zona = preload("res://mapa/zona.gd")
const EdificioEditor = preload("res://mapa/edificio.gd")
const MOLINO_ID: String = "building_abandoned_mill"
const COMISARIA_ID: String = "building_police"
const BIBLIOTECA_ID: String = "building_library"
const HOSPITAL_ID: String = "building_hospital"
const BOTICA_ID: String = "mixed_family_herbalist"
const MANSION_ID: String = "building_mansion"
const PUERTA_FUERA_M: float = 1.6     ## a cuánto del portón, por fuera, se para antes de abrirlo
const CERCA_PX: float = 14.0          ## a cuánto de la pista se para (cada pista se ofrece en su zona, de ~1,5 m)
const EN_ZONA_PX: float = 24.0        ## ya dentro de la zona de la pista, aunque un mueble no deje llegar más
const RUTA_TRAMOS_MAX: int = 40
const TRAMO_LLEGA_PX: float = 3.0     ## cada tramo de la ruta, hasta casi pisarlo (los tramos de un paso son cortos)
const TRAMO_FRAMES_MAX: int = 900
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const PX_POR_M: float = 1.0 / Mapa3D.ESCALA ## píxeles del mapa por metro (el molino: 14 m = 250 px)
const OUT_DIR: String = "docs/capturas_arreglos/caso1/partida"

var _results: Array[String] = []
var _failures: Array[String] = []

func _record(step_id: String, ok: bool, detail: String) -> void:
	var prefix: String = "✅" if ok else "❌"
	var line: String = "%s %s: %s" % [prefix, step_id, detail]
	_results.append(line)
	print("[CASO1] " + line)
	if not ok:
		_failures.append(line)

func _has_note_with_source(det_ui: Node, source_key: String) -> bool:
	if det_ui == null:
		return false
	var notes: Array = det_ui.get("notebook_notes")
	for n in notes:
		if n is Dictionary and str(n.get("source_key", "")) == source_key:
			return true
	return false

func _walk_to_waypoints(pl: CharacterBody2D, stage: Node, waypoints: Array[Vector2], arrive_dist: float = 8.0, max_frames_per_seg: int = 6000, ya_mundo: bool = false) -> bool:
	for wp0 in waypoints:
		var wp: Vector2 = wp0 if ya_mundo else MapaViejo.a_mundo(wp0) # los puntos de paso están en el mapa original (mapa ×E)
		var frames: int = 0
		var stuck_count: int = 0
		var side_sign: float = 1.0
		while pl.global_position.distance_to(wp) > arrive_dist and frames < max_frames_per_seg:
			var pos_before: Vector2 = pl.global_position
			var diff: Vector2 = wp - pos_before
			var dir: Vector2 = diff.normalized()
			if stuck_count > 10:
				var perp := Vector2(-dir.y, dir.x) * side_sign
				dir = (dir * 0.75 + perp * 0.65).normalized()
			if stage != null and (frames % 10) == 0:
				stage.set("fp_yaw", dir.angle())
				stage.set("fp_pitch", -0.08)
				stage.call("_update_fp_camera_transform")
			for _sub in range(8):
				if pl.global_position.distance_to(wp) <= arrive_dist:
					break
				var sub_dir: Vector2 = (wp - pl.global_position).normalized()
				if stuck_count > 10:
					var perp2 := Vector2(-sub_dir.y, sub_dir.x) * side_sign
					sub_dir = (sub_dir * 0.75 + perp2 * 0.65).normalized()
				pl.velocity = sub_dir * 320.0
				pl.move_and_slide()
			if pl.global_position.distance_to(pos_before) < 0.5:
				stuck_count += 1
				if (stuck_count % 8) == 0:
					side_sign = -side_sign
			else:
				stuck_count = 0
			frames += 1
			if (frames % 10) == 0:
				await physics_frame
		pl.velocity = Vector2.ZERO
		if pl.global_position.distance_to(wp) > maxf(10.0, arrive_dist + 3.0):
			var col_name: String = "none"
			if pl.get_slide_collision_count() > 0:
				var col := pl.get_slide_collision(0)
				if col != null and col.get_collider() != null:
					col_name = str(col.get_collider().name)
			print("[WALK_BLOCKED] wp=%s pos=%s collider=%s" % [str(wp), str(pl.global_position.round()), col_name])
			return false
	await physics_frame
	await physics_frame
	return true

## El punto de fuera de un portón: a PUERTA_FUERA_M, del lado contrario al centro del edificio.
func _fuera_de(id: String) -> Vector2:
	var puerta: Vector2 = Marca.mundo(id, "puerta")
	var centro: Vector2 = EdificioEditor.a_mundo(id, EdificioEditor.centro_de_fabrica(id))
	return puerta + (puerta - centro).normalized() * PUERTA_FUERA_M * PX_POR_M


## Sigue a pie la ruta de los vecinos (cuartos y pasos del edificio) hasta `meta`, tramo a tramo. ¿Llegó a su zona?
func _andar_por_ruta(pl: CharacterBody2D, stage: Node, vm: Node, meta: Vector2, cerca: float = CERCA_PX) -> bool:
	for _i in range(RUTA_TRAMOS_MAX):
		if pl.global_position.distance_to(meta) <= cerca + TRAMO_LLEGA_PX:
			break
		var wp: Vector2 = vm.call("get_navigation_waypoint", pl.global_position, meta, pl)
		if wp.distance_to(meta) < cerca: # el último tramo: parar delante de la pista, para poder mirarla
			wp = meta + (pl.global_position - meta).normalized() * cerca
		await _walk_to_waypoints(pl, stage, [wp], TRAMO_LLEGA_PX, TRAMO_FRAMES_MAX, true)
	return pl.global_position.distance_to(meta) <= EN_ZONA_PX


## Hasta el portón por fuera, abrirlo y entrar por la ruta hasta `meta` (una pista, ya en el mundo).
func _entrar_y_andar(pl: CharacterBody2D, stage: Node, vm: Node, id: String, meta: Vector2) -> bool:
	var llega: bool = await _walk_to_waypoints(pl, stage, [_fuera_de(id)], 5.0, 6000, true)
	var d: Dictionary = vm.call("_find_nearest_door", Marca.mundo(id, "puerta"), 25.0)
	if not d.is_empty():
		vm.call("_set_door_state", d, true, false, true)
	return await _andar_por_ruta(pl, stage, vm, meta) and llega


## Salir por la ruta hasta fuera del portón.
func _salir(pl: CharacterBody2D, stage: Node, vm: Node, id: String) -> bool:
	return await _andar_por_ruta(pl, stage, vm, _fuera_de(id), 6.0)


## Una marca del molino (ya en el mundo), con un desfase en metros (x al este, z al sur, como en su plano).
func _molino(marca: String, desfase_m: Vector2 = Vector2.ZERO) -> Vector2:
	return Marca.mundo(MOLINO_ID, marca, desfase_m * PX_POR_M)


func _aim_and_press_e(pl: CharacterBody2D, stage: Node, look_target: Vector2, pitch: float = -0.24, want_substr: String = "", ya_mundo: bool = false) -> Dictionary:
	if not ya_mundo:
		look_target = MapaViejo.a_mundo(look_target) # mapa original → mundo (mapa ×E)
	var dir: Vector2 = look_target - pl.global_position
	if dir.length_squared() > 0.001 and stage != null:
		stage.set("fp_yaw", dir.angle())
	if stage != null:
		stage.set("fp_pitch", pitch)
		stage.call("_update_fp_camera_transform")
	var sel: Node = pl.get("interaction_selector")
	for _i in range(4):
		await physics_frame
		await process_frame
		if stage != null:
			if dir.length_squared() > 0.001:
				stage.set("fp_yaw", dir.angle())
			stage.set("fp_pitch", pitch)
			stage.call("_update_fp_camera_transform")
		if sel != null and sel.has_method("refresh"):
			sel.call("refresh")
	var chosen: Dictionary = {}
	if sel != null and sel.has_method("selected"):
		var cands: Array = sel.get("candidates")
		if want_substr != "":
			for idx in range(cands.size()):
				var c_lbl: String = str(cands[idx].get("label", ""))
				if want_substr.to_lower() in c_lbl.to_lower():
					sel.set("_index", idx)
					chosen = cands[idx]
					break
		if chosen.is_empty():
			chosen = sel.call("selected")
	var used_ok: bool = false
	var chosen_lbl: String = str(chosen.get("label", ""))
	if not chosen.is_empty() and (want_substr == "" or want_substr.to_lower() in chosen_lbl.to_lower()):
		pl.call("_handle_interactions")
		used_ok = true
	if paused:
		paused = false
	for _i in range(3):
		await process_frame
	return {"ok": used_ok, "label": chosen_lbl}

## Caso I: ¿ofrece el vecino con ese papel la opción del caso en su diálogo? Si la ofrece, la elige (anota en el cuaderno).
func _case_dialogue(_c1, _vm, npc_name: String, action_id: String) -> Dictionary:
	var out := {"npc": npc_name, "offered": false}
	if npc_name == "":
		return out
	var npc = null
	for n in get_nodes_in_group("village_npcs"):
		if is_instance_valid(n) and str(n.get("npc_name")) == npc_name:
			npc = n
			break
	if npc == null:
		return out
	var diag: Dictionary = npc.call("_inject_character_lore_into_dialogue", npc.call("_build_dialogue"))
	out["offered"] = action_id in str(diag)
	if bool(out["offered"]):
		npc.call("on_dialogue_action", action_id)
	return out

func _save_shot(id_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for _i in range(6):
		await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	if img != null:
		var abs_path: String = ProjectSettings.globalize_path("res://" + OUT_DIR + "/" + id_name + ".png")
		img.save_png(abs_path)

func _initialize() -> void:
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

	var vm = root.find_child("VillageManager", true, false)
	# Día de margen (2026-11-11): el caso empieza el día 2; la partida de prueba arranca ya en ese día
	var reloj: Node = root.get_node_or_null("WorldClock")
	if reloj != null:
		reloj.set("current_day", 2)
	var caso1 = load("res://scripts/systems/VillageCase1.gd")
	caso1.sync(vm)
	# El guardia ya te ha dado el recado de Vane (sin él, el panel del detective no se abre: no hay caso)
	caso1.state(vm)["aviso"] = "dado"
	var pl = get_first_node_in_group("player") as CharacterBody2D
	var ui_root = get_first_node_in_group("game_ui")
	var det_ui = ui_root.get("detective_ui") if ui_root != null else null
	var stage = null
	for n in root.find_children("*", "", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("WorldStage3D.gd"):
			stage = n
			break

	if stage != null:
		stage.call("set_first_person", true)

	# =========================================================================
	# BLOQUE A: Inicio en las afueras con la carta -> Ir al claro -> Cuerpo y pistas del claro
	# =========================================================================
	var start_pos: Vector2 = pl.global_position
	var letter_panel: Control = ui_root.get("hiring_letter_panel") if ui_root != null else null
	var letter_open_ok: bool = letter_panel != null and letter_panel.visible
	if ui_root != null and ui_root.has_method("close_hiring_letter_panel"):
		ui_root.call("close_hiring_letter_panel")
	if ui_root != null and ui_root.has_method("close_controls_panel"):
		ui_root.call("close_controls_panel")
	var letter_closed_ok: bool = letter_panel != null and not letter_panel.visible
	_record("A1_carta_inicio_afueras", start_pos.distance_to(MapaViejo.a_mundo(Vector2(-1180.0, 50.0))) < 35.0 and letter_open_ok and letter_closed_ok,
		"pos=%s carta_abierta=%s cerrada_con_E=%s" % [str(start_pos.round()), str(letter_open_ok), str(letter_closed_ok)])

	# Caminar a pie desde las afueras (-1180, 50) hasta el Claro del arroyo (138, -854)
	var path_to_clearing: Array[Vector2] = [
		Vector2(-750.0, 50.0),
		Vector2(-250.0, 50.0),
		Vector2(118.0, 50.0),
		Vector2(420.0, 50.0),
		Vector2(682.0, 50.0),
		Vector2(682.0, -351.0),
		Vector2(682.0, -815.0),
		Vector2(138.0, -815.0),
		Vector2(138.0, -854.0),
	]
	var walked_clearing: bool = await _walk_to_waypoints(pl, stage, path_to_clearing)
	_record("A2_caminar_al_claro", walked_clearing, "pos_final=%s" % str(pl.global_position.round()))

	# Examinar Orilla del arroyo con [E]
	var claro: Vector2 = Sitio.mundo("claro_caso1") # el claro y el cuerpo son cruces de «Sitios», ya en el mundo
	await _walk_to_waypoints(pl, stage, [claro], 8.0, 6000, true)
	var e_clearing: Dictionary = await _aim_and_press_e(pl, stage, claro, -0.20, "orilla", true)
	var note_clearing: bool = _has_note_with_source(det_ui, "clue_case1_clearing")
	_record("A3_pista_orilla_claro", bool(e_clearing["ok"]) and note_clearing,
		"prompt='%s' anotada=%s" % [str(e_clearing["label"]), str(note_clearing)])

	# Caminar unos pasos hasta el cuerpo en el claro (138, -870) y examinarlo con [E]
	var cuerpo: Vector2 = Sitio.mundo("cuerpo_caso1")
	await _walk_to_waypoints(pl, stage, [cuerpo + (pl.global_position - cuerpo).normalized() * CERCA_PX], 4.0, 6000, true)
	var e_corpse: Dictionary = await _aim_and_press_e(pl, stage, cuerpo, -0.22, "cuerpo", true)
	var det_opened: bool = det_ui != null and bool(det_ui.visible)
	var body_notes_before: int = (det_ui.get("notebook_notes") as Array).size() if det_ui != null else 0
	if det_opened:
		# Dar Lupa al jugador o examinar todas las zonas del cuerpo y las 6 pistas de la escena del claro
		if pl.get("inventory") != null and pl.get("inventory").has_method("add_item"):
			pl.get("inventory").call("add_item", "magnifying_glass", 1)
			det_ui.call("_build_case_from_corpse", det_ui.get("current_corpse"))
		for z_id in ["cabeza", "cuello", "torso", "brazos", "manos", "piernas", "bolsillos"]:
			det_ui.call("select_zone", z_id)
			var z_dict: Dictionary = (det_ui.get("zone_data") as Dictionary).get(z_id, {})
			var acts: Array = z_dict.get("acts", [])
			for act in acts:
				if act is Dictionary and not bool(act.get("locked", false)):
					det_ui.call("_do_zone_action", z_id, act)
					var cur_f: Dictionary = det_ui.get("current_finding")
					var f_note: String = str(cur_f.get("note", ""))
					if f_note != "":
						det_ui.call("add_notebook_note", str(cur_f.get("zone_title", "Pista")), f_note, str(cur_f.get("tag", "Hallazgo")), str(cur_f.get("key", "")))
		det_ui.call("switch_mode", "scene")
		var s_clues: Array = det_ui.get("scene_clues")
		var cs_canvas = det_ui.get("crime_scene_canvas")
		for c_idx in range(s_clues.size()):
			var cl: Dictionary = s_clues[c_idx]
			if cs_canvas != null:
				cs_canvas.set("lantern_base_pos", Vector2(float(cl.get("x", 260.0)), float(cl.get("y", 280.0))))
			if bool(det_ui.call("crime_find_clue", c_idx)):
				var cap_k: String = str(cl.get("k", "Escena"))
				var cap_t: String = str(cl.get("t", ""))
				det_ui.call("add_notebook_note", "Escena · " + cap_k, cap_t, "Escena: " + cap_k, "s_%d" % c_idx)
		det_ui.call("close_panel")
	var body_notes_after: int = (det_ui.get("notebook_notes") as Array).size() if det_ui != null else 0
	var added_clearing_notes: int = body_notes_after - body_notes_before
	_record("A4_cuerpo_y_pistas_claro", bool(e_corpse["ok"]) and det_opened and added_clearing_notes >= 10,
		"prompt='%s' ui_abierta=%s notas_nuevas=%d" % [str(e_corpse["label"]), str(det_opened), added_clearing_notes])

	var wc: Node = root.get_node_or_null("WorldClock")
	if wc != null:
		wc.set("current_hour", 11)
		wc.set("current_minute", 0)

	# =========================================================================
	# BLOQUE B: Molino Viejo (barro rojo, sótano/reja, 4 pistas interiores) y Puente Viejo (zapato)
	# =========================================================================
	# Molino a tamaño real (2026-11-13): se anda y se apunta con sus marcas y su sitio (puntos ya del mundo); `_molino`
	# da una marca con un desfase en metros (a menos de ~1 m: cada pista se ofrece dentro de su zona, de ~1,5 m de radio). El primer punto, en el campo abierto, sigue en el mapa original estirado.
	var a_la_ribera: Vector2 = Zona.estirar(Vector2(142.0, -945.0))
	var barro: Vector2 = Sitio.mundo("barro_rojo_molino")
	var walked_clay: bool = await _walk_to_waypoints(pl, stage, [a_la_ribera, barro + Vector2(0.0, 0.8) * PX_POR_M], 4.0, 6000, true)
	var e_clay: Dictionary = await _aim_and_press_e(pl, stage, barro, -0.22, "arcilla", true)
	var note_clay: bool = _has_note_with_source(det_ui, "clue_mill_red_clay")
	_record("B1_molino_barro_rojo", walked_clay and bool(e_clay["ok"]) and note_clay,
		"walk=%s prompt='%s' anotada=%s" % [str(walked_clay), str(e_clay["label"]), str(note_clay)])

	# Entrar al Molino Viejo por su portón (al sur) y bajar junto al foso del sótano, al lado del muro de la rueda
	await _walk_to_waypoints(pl, stage, [_molino("puerta", Vector2(0.0, 1.6))], 4.0, 6000, true)
	var d_mill: Dictionary = vm.call("_find_nearest_door", _molino("puerta"), 20.0)
	if not bool(d_mill.get("is_open", false)):
		await _aim_and_press_e(pl, stage, _molino("puerta"), -0.05, "puerta", true)
	var walked_mill_in: bool = await _walk_to_waypoints(pl, stage, [_molino("puerta", Vector2(0.0, -1.2)), _molino("sotano", Vector2(1.0, 0.0))], 5.0, 6000, true)
	var e_grate: Dictionary = await _aim_and_press_e(pl, stage, _molino("sotano"), -0.5, "reja", true)
	var note_grate: bool = _has_note_with_source(det_ui, "clue_mill_cellar_grate")
	_record("B2_molino_sotano_reja", walked_mill_in and bool(e_grate["ok"]) and note_grate,
		"walk=%s prompt='%s' anotada=%s" % [str(walked_mill_in), str(e_grate["label"]), str(note_grate)])

	# Al granero por el hueco del tabique: el pajar (noroeste) y el hogar frío (norte)
	var al_granero: Vector2 = _molino("puerta", Vector2(0.0, -6.5))
	var w_hay: bool = await _walk_to_waypoints(pl, stage, [_molino("puerta", Vector2(0.0, -5.0)), al_granero, _molino("pajar", Vector2(0.0, 0.9))], 5.0, 6000, true)
	var e_hay: Dictionary = await _aim_and_press_e(pl, stage, _molino("pajar"), -0.22, "pajar", true)
	var note_hay: bool = _has_note_with_source(det_ui, "clue_mill_hayloft")
	_record("B3_molino_pajar", w_hay and bool(e_hay["ok"]) and note_hay,
		"prompt='%s' anotada=%s" % [str(e_hay["label"]), str(note_hay)])

	var w_hearth: bool = await _walk_to_waypoints(pl, stage, [_molino("hogar", Vector2(0.0, 1.0))], 4.0, 6000, true)
	var e_hearth: Dictionary = await _aim_and_press_e(pl, stage, _molino("hogar"), -0.22, "hogar", true)
	var note_hearth: bool = _has_note_with_source(det_ui, "clue_mill_hearth")
	_record("B4_molino_hogar_ceniza", w_hearth and bool(e_hearth["ok"]) and note_hearth,
		"prompt='%s' anotada=%s" % [str(e_hearth["label"]), str(note_hearth)])

	# De vuelta a la sala: el banco del cordel (suroeste) y la mesa del papel
	var w_cord: bool = await _walk_to_waypoints(pl, stage, [al_granero, _molino("puerta", Vector2(0.0, -3.0)), _molino("cordel", Vector2(1.1, 0.0))], 4.0, 6000, true)
	var e_cord: Dictionary = await _aim_and_press_e(pl, stage, _molino("cordel"), -0.3, "cordel", true)
	var note_cord: bool = _has_note_with_source(det_ui, "clue_mill_hemp_cord")
	_record("B5_molino_cordel", w_cord and bool(e_cord["ok"]) and note_cord,
		"prompt='%s' anotada=%s" % [str(e_cord["label"]), str(note_cord)])

	var w_paper: bool = await _andar_por_ruta(pl, stage, vm, _molino("mesa_papel"))
	var e_paper: Dictionary = await _aim_and_press_e(pl, stage, _molino("mesa_papel"), -0.3, "papel", true)
	var note_paper: bool = _has_note_with_source(det_ui, "clue_mill_table_paper")
	_record("B6_molino_mesa_papel", w_paper and bool(e_paper["ok"]) and note_paper,
		"prompt='%s' anotada=%s" % [str(e_paper["label"]), str(note_paper)])

	# Salir del molino y bajar a pie hasta el Puente Viejo (zapato izquierdo)
	# Mapa ×E: el zapato lo coloca el juego junto al cruce del río del editor; se apunta a donde esté de verdad (en el mapa original)
	var shoe_area: Node2D = root.find_child("OldBridgeVictimShoeArea", true, false) as Node2D
	var shoe_mundo: Vector2 = shoe_area.global_position if shoe_area != null else MapaViejo.a_mundo(Vector2(95.0, 38.0))
	await _walk_to_waypoints(pl, stage, [_molino("puerta", Vector2(0.0, -1.2)), _molino("puerta", Vector2(0.0, 1.8)), a_la_ribera], 8.0, 6000, true)
	var path_to_bridge: Array[Vector2] = [
		Vector2(138.0, -860.0),
		Vector2(138.0, -815.0),
		Vector2(682.0, -815.0),
		Vector2(682.0, 50.0),
		Vector2(150.0, 50.0),
		Vector2(105.0, 50.0),
	]
	var walked_bridge: bool = await _walk_to_waypoints(pl, stage, path_to_bridge)
	# hasta donde esté el zapato de verdad (el cruce del río lo decide el editor): punto ya del mundo
	walked_bridge = await _walk_to_waypoints(pl, stage, [shoe_mundo + Vector2(0.0, 14.0)], 8.0, 6000, true) and walked_bridge
	var e_shoe: Dictionary = await _aim_and_press_e(pl, stage, shoe_mundo, -0.22, "zapato", true)
	var note_shoe: bool = _has_note_with_source(det_ui, "clue_old_bridge_left_shoe")
	_record("B7_puente_viejo_zapato", walked_bridge and bool(e_shoe["ok"]) and note_shoe,
		"walk=%s prompt='%s' anotada=%s" % [str(walked_bridge), str(e_shoe["label"]), str(note_shoe)])

	# =========================================================================
	# BLOQUE C: Comisaría (denuncia archivada) y Biblioteca (libro-palanca, sala oculta, cuaderno, libro arrancado)
	# =========================================================================
	var path_to_police: Array[Vector2] = [
		Vector2(150.0, 50.0),
		Vector2(420.0, 50.0),
		Vector2(672.0, 50.0),
		Vector2(672.0, 86.0),
	]
	var walked_pol_door: bool = await _walk_to_waypoints(pl, stage, path_to_police)
	var archivo: Vector2 = Marca.mundo(COMISARIA_ID, "archivo")
	var walked_pol_in: bool = await _entrar_y_andar(pl, stage, vm, COMISARIA_ID, archivo)
	var e_pol: Dictionary = await _aim_and_press_e(pl, stage, archivo, -0.22, "carpeta", true)
	var note_pol: bool = _has_note_with_source(det_ui, "clue_police_archived_report")
	_record("C1_comisaria_denuncia_archivada", walked_pol_door and walked_pol_in and bool(e_pol["ok"]) and note_pol,
		"walk=%s prompt='%s' anotada=%s" % [str(walked_pol_in), str(e_pol["label"]), str(note_pol)])

	# Salir de la Comisaría y caminar hasta la Biblioteca (910, -420; puerta sur en 910, -372)
	await _salir(pl, stage, vm, COMISARIA_ID)
	var path_to_library: Array[Vector2] = [
		Vector2(672.0, 82.0),
		Vector2(672.0, -351.0),
	]
	var walked_lib_door: bool = await _walk_to_waypoints(pl, stage, path_to_library, 4.0)
	var palanca: Vector2 = Marca.mundo(BIBLIOTECA_ID, "palanca")
	var walked_lib_lever: bool = await _entrar_y_andar(pl, stage, vm, BIBLIOTECA_ID, palanca)
	var e_lever: Dictionary = await _aim_and_press_e(pl, stage, palanca, -0.18, "estantería", true)
	var note_lever: bool = _has_note_with_source(det_ui, "clue_library_book_lever")
	_record("C2_biblioteca_libro_palanca", walked_lib_door and walked_lib_lever and bool(e_lever["ok"]) and note_lever,
		"walk=%s prompt='%s' anotada=%s" % [str(walked_lib_lever), str(e_lever["label"]), str(note_lever)])

	# Entrar a pie a la sala oculta (tras la estantería del archivo) y examinar el cuaderno de firmas
	var libro_mayor: Vector2 = Marca.mundo(BIBLIOTECA_ID, "libro_mayor")
	var walked_secret_room: bool = await _andar_por_ruta(pl, stage, vm, libro_mayor)
	var e_ledger: Dictionary = await _aim_and_press_e(pl, stage, libro_mayor, -0.22, "cuaderno", true)
	var note_ledger: bool = _has_note_with_source(det_ui, "clue_library_secret_ledger")
	_record("C3_biblioteca_cuaderno_firmas", walked_secret_room and bool(e_ledger["ok"]) and note_ledger,
		"walk=%s prompt='%s' anotada=%s" % [str(walked_secret_room), str(e_ledger["label"]), str(note_ledger)])

	# Examinar el libro antiguo con la página arrancada, en la misma mesa
	var libro_roto: Vector2 = Marca.mundo(BIBLIOTECA_ID, "libro_roto")
	var walked_torn: bool = await _andar_por_ruta(pl, stage, vm, libro_roto)
	var e_torn: Dictionary = await _aim_and_press_e(pl, stage, libro_roto, -0.22, "libro", true)
	var note_torn: bool = _has_note_with_source(det_ui, "clue_library_torn_book")
	_record("C4_biblioteca_libro_pagina_arrancada", walked_torn and bool(e_torn["ok"]) and note_torn,
		"walk=%s prompt='%s' anotada=%s" % [str(walked_torn), str(e_torn["label"]), str(note_torn)])

	# =========================================================================
	# BLOQUE D: Resto de pistas del Caso I (Autopsia en Morgue, Testigos, Diálogos/Casas/Secuestradores) y Acusación final
	# =========================================================================
	# D1: Caminar de la Biblioteca a la Morgue del Hospital (745, 148; puerta norte en 745, 100; mesa en 745, 174)
	await _salir(pl, stage, vm, BIBLIOTECA_ID)
	var path_to_morgue: Array[Vector2] = [
		Vector2(672.0, -351.0),
		Vector2(672.0, 84.0),
	]
	var walked_hosp_door: bool = await _walk_to_waypoints(pl, stage, path_to_morgue, 4.0)
	var mesa_autopsia: Vector2 = Marca.mundo(HOSPITAL_ID, "mesa_morgue_2") # la del medio: ahí se abre la autopsia
	var walked_morgue_in: bool = await _entrar_y_andar(pl, stage, vm, HOSPITAL_ID, mesa_autopsia)
	var e_morgue: Dictionary = await _aim_and_press_e(pl, stage, mesa_autopsia, -0.22, "autopsia", true)
	var morgue_opened: bool = det_ui != null and bool(det_ui.visible) and str(det_ui.get("current_mode")) == "morgue"
	if morgue_opened:
		# Sangre: Del corazón (0) -> Tintura de corteza (1) -> Una hierba de embalsamar (0)
		det_ui.call("select_morgue_test", "sangre")
		det_ui.call("choose_morgue_option", "sangre", 0)
		det_ui.call("choose_morgue_option", "sangre", 1)
		det_ui.call("choose_morgue_option", "sangre", 0)
		# Cuello: Corte lento, por capas (0) -> Mirar (0)
		det_ui.call("select_morgue_test", "cuello")
		det_ui.call("choose_morgue_option", "cuello", 0)
		det_ui.call("choose_morgue_option", "cuello", 0)
		# Estómago: Abrir y vaciar (0) -> Guardarlo en un frasco sellado (0)
		det_ui.call("select_morgue_test", "estomago")
		det_ui.call("choose_morgue_option", "estomago", 0)
		det_ui.call("choose_morgue_option", "estomago", 0)
		# Piel y rigidez: Girar el cuerpo (0) -> Doblar codos y rodillas (0)
		det_ui.call("select_morgue_test", "piel")
		det_ui.call("choose_morgue_option", "piel", 0)
		det_ui.call("choose_morgue_option", "piel", 0)
		var m_defs: Dictionary = det_ui.get("morgue_tests_def")
		var m_states: Dictionary = det_ui.get("morgue_tests_state")
		for tid in ["sangre", "cuello", "estomago", "piel"]:
			var t_st: Dictionary = m_states.get(tid, {})
			var t_df: Dictionary = m_defs.get(tid, {})
			if str(t_st.get("state", "")) == "done":
				var logs: Array = t_st.get("log", [])
				var l_txt: String = str(logs[logs.size() - 1][1]) if not logs.is_empty() else ""
				det_ui.call("add_notebook_note", str(t_df.get("note_title", tid)), l_txt, str(t_df.get("note_tag", tid)), "m_" + tid)
		# Testigos de la escena (El leñador y La pastora)
		det_ui.call("switch_mode", "scene")
		det_ui.call("ask_scene_witness", 0)
		det_ui.call("ask_scene_witness", 1)
		det_ui.call("press_scene_witness", 1)
		var s_wits: Array = det_ui.get("scene_witnesses")
		if s_wits.size() >= 2:
			det_ui.call("add_notebook_note", "Testigo · El leñador", str(s_wits[0].get("ask_text", "")), "Testigo: El leñador", "w1_0")
			det_ui.call("add_notebook_note", "Testigo · La pastora", str(s_wits[1].get("ask_text", "")), "Testigo: La pastora", "w1_1")
			det_ui.call("add_notebook_note", "Testigo · La pastora", str(s_wits[1].get("press_ok_text", "")), "Testigo: La pastora", "w2_1")
		det_ui.call("close_panel")
	var morgue_notes_ok: bool = (
		_has_note_with_source(det_ui, "m_sangre")
		and _has_note_with_source(det_ui, "m_cuello")
		and _has_note_with_source(det_ui, "m_estomago")
		and _has_note_with_source(det_ui, "m_piel")
		and _has_note_with_source(det_ui, "w1_0")
		and _has_note_with_source(det_ui, "w1_1")
		and _has_note_with_source(det_ui, "w2_1")
	)
	_record("D1_morgue_autopsia_y_testigos", walked_hosp_door and walked_morgue_in and bool(e_morgue["ok"]) and morgue_opened and morgue_notes_ok,
		"walk=%s prompt='%s' autopsia_4_pruebas_y_2_testigos=%s" % [str(walked_morgue_in), str(e_morgue["label"]), str(morgue_notes_ok)])

	# D2–D4 (Claude Code, 2026-11-09): papeles del caso, diálogos, gabinete, hoja arrancada y secuestradores
	var C1 = load("res://scripts/systems/VillageCase1.gd")
	var roles_before: bool = not (C1.roles(vm) as Dictionary).is_empty()
	C1.sync(vm) # lo mismo que hace cada hora del reloj
	var roles: Dictionary = C1.roles(vm)
	_record("D1b_papeles_del_caso_repartidos", roles.has("alchemist") and roles.has("apparent_culprit_relative") and roles.has("kidnapper_blue_wool"),
		"ya_por_la_hora=%s papeles=%s" % [str(roles_before), str(roles)])

	# D2: Botica (325, 132; puerta norte en 325, 108): el boticario analiza el líquido del estómago
	await _salir(pl, stage, vm, HOSPITAL_ID)
	var path_to_apothecary: Array[Vector2] = [
		Vector2(672.0, 84.0),
		Vector2(672.0, 50.0),
		Vector2(325.0, 50.0),
	]
	var walked_apoth: bool = await _walk_to_waypoints(pl, stage, path_to_apothecary, 4.0)
	var walked_apoth_in: bool = await _entrar_y_andar(pl, stage, vm, BOTICA_ID, Marca.mundo(BOTICA_ID, "puerta", Vector2.ZERO).lerp(EdificioEditor.a_mundo(BOTICA_ID, EdificioEditor.centro_de_fabrica(BOTICA_ID)), 0.5))
	var alch_ok: Dictionary = _case_dialogue(C1, vm, str(roles.get("alchemist", "")), "case1:alchemist_analyze_flask")
	var note_alch: bool = _has_note_with_source(det_ui, "clue_case1_alchemist_analyze_flask")
	await _save_shot("01_botica_dialogo_caso1_v2")
	_record("D2_botica_alquimista_belladama", walked_apoth and walked_apoth_in and bool(alch_ok["offered"]) and note_alch,
		"walk=%s npc=%s opcion_en_dialogo=%s anotada=%s" % [str(walked_apoth_in), str(alch_ok["npc"]), str(alch_ok["offered"]), str(note_alch)])

	# D3: Mansión del Señor del Valle (puerta sur 1315, -364): gabinete forzado y criada
	await _salir(pl, stage, vm, BOTICA_ID)
	var path_to_mansion: Array[Vector2] = [
		Vector2(325.0, 50.0),
		Vector2(672.0, 50.0),
		Vector2(672.0, -342.0),
		Vector2(1315.0, -342.0),
	]
	var walked_mansion: bool = await _walk_to_waypoints(pl, stage, path_to_mansion, 5.0)
	var cab: Vector2 = C1.cabinet_pos()
	var walked_cab: bool = await _entrar_y_andar(pl, stage, vm, MANSION_ID, cab)
	var e_cab: Dictionary = await _aim_and_press_e(pl, stage, cab, -0.20, "gabinete", true)
	var note_cab: bool = _has_note_with_source(det_ui, "clue_case1_forced_cabinet")
	await _save_shot("02_mansion_gabinete_forzado_v2")
	_record("D3_mansion_gabinete_forzado", walked_mansion and walked_cab and bool(e_cab["ok"]) and note_cab,
		"walk=%s prompt='%s' anotada=%s" % [str(walked_cab), str(e_cab["label"]), str(note_cab)])
	var maid_ok: Dictionary = _case_dialogue(C1, vm, str(roles.get("noble_maid", "")), "case1:noble_maid_recognize_vial")
	_record("D3b_criada_reconoce_frasco", bool(maid_ok["offered"]) and _has_note_with_source(det_ui, "clue_case1_noble_maid_recognize_vial"),
		"npc=%s opcion_en_dialogo=%s (necesita haber vaciado el bolsillo del cuerpo)" % [str(maid_ok["npc"]), str(maid_ok["offered"])])

	# D4: hoja arrancada junto a la cama del familiar (su casa varía según el reparto: se comprueba en el sitio)
	var pp = C1.state(vm).get("page_pos", null)
	var page_ok: bool = false
	var page_label: String = ""
	if pp is Array and (pp as Array).size() >= 2:
		var page_pos := Vector2(float(pp[0]), float(pp[1]))
		var pos_before: Vector2 = pl.global_position
		pl.global_position = page_pos + Vector2(0.0, 18.0) # (sin ruta a pie fija: la casa depende del reparto)
		await process_frame
		var e_page: Dictionary = await _aim_and_press_e(pl, stage, page_pos, -0.25, "hoja", true) # page_pos ya es del mundo
		page_label = str(e_page["label"])
		page_ok = bool(e_page["ok"]) and _has_note_with_source(det_ui, "clue_case1_relative_page")
		await _save_shot("03_casa_familiar_hoja_arrancada_v2")
		pl.global_position = pos_before
		await process_frame
	_record("D4_hoja_arrancada_casa_familiar", page_ok, "pos=%s prompt='%s' (colocado junto a ella, sin caminar)" % [str(pp), page_label])
	var rel_ok: Dictionary = _case_dialogue(C1, vm, str(roles.get("apparent_culprit_relative", "")), "case1:relative_confession")
	_record("D4b_confesion_del_familiar", bool(rel_ok["offered"]), "npc=%s opcion_en_dialogo=%s" % [str(rel_ok["npc"]), str(rel_ok["offered"])])
	var wool_ok: Dictionary = _case_dialogue(C1, vm, str(roles.get("kidnapper_blue_wool", "")), "case1:blue_wool")
	_record("D4c_vecino_lana_azul", bool(wool_ok["offered"]) and _has_note_with_source(det_ui, "clue_case1_blue_wool"),
		"npc=%s opcion_en_dialogo=%s" % [str(wool_ok["npc"]), str(wool_ok["offered"])])
	var kds: Array = get_nodes_in_group("case1_kidnappers")
	var near_mill: int = 0
	for kd in kds:
		if is_instance_valid(kd) and Lugar.en_mapa(kd).distance_to(MapaViejo.a_mundo(Vector2(188.0, -1060.0))) < 80.0:
			near_mill += 1
	_record("D4d_secuestradores_en_el_molino", near_mill == 2, "forasteros_en_el_molino=%d (el tercero es el vecino de la lana azul)" % near_mill)
	await _salir(pl, stage, vm, MANSION_ID)
	await _walk_to_waypoints(pl, stage, [Vector2(1315.0, -342.0), Vector2(672.0, -342.0), Vector2(672.0, -195.0)], 5.0)

	# D5: Informe del caso en la comisaría (bandeja del alguacil): eliges culpable y queda guardado para el final
	var walked_accuse: bool = await _walk_to_waypoints(pl, stage, [Vector2(672.0, 86.0)], 5.0)
	walked_accuse = await _entrar_y_andar(pl, stage, vm, COMISARIA_ID, C1.report_pos()) and walked_accuse
	print("[CASO1] D5 junto a la bandeja: pos=%s ok=%s" % [str(pl.global_position.round()), str(walked_accuse)])
	var rep_e: Dictionary = await _aim_and_press_e(pl, stage, C1.report_pos(), -0.30, "informe", true)
	var dm = root.find_child("dialogue_manager", true, false)
	var form_open: bool = dm != null and bool(dm.call("is_active")) and (dm.get("graph") as Dictionary).has("confirm_young")
	await _save_shot("05_informe_caso_comisaria_1p")
	if dm != null and bool(dm.call("is_active")):
		dm.call("end_dialogue")
	C1.on_report_action(vm, "case1_report:young")
	var rep = C1.state(vm).get("report", null)
	var rep_ok: bool = rep is Dictionary and str(rep.get("verdict", "")) == "perfect"
	var locked: bool = not C1.submit_report(vm, "relative") and str(C1.state(vm)["report"].get("culprit", "")) == "young"
	_record("D5_informe_caso1", walked_accuse and bool(rep_e.get("ok", false)) and form_open and rep_ok and locked,
		"walk=%s E=%s(%s) formulario=%s informe_guardado=%s no_se_cambia=%s pruebas=%s" % [str(walked_accuse), str(rep_e.get("ok", false)), str(rep_e.get("label", "")), str(form_open), str(rep_ok), str(locked), str(rep.get("evidence", []).size() if rep is Dictionary else 0)])

	print("PARTIDA_CASO1 COMPLETA TERMINADA (%d pasos comprobados, %d pendientes de sistemas nuevos)" % [_results.size(), _failures.size()])
	quit(0)
