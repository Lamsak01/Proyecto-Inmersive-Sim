extends Node

## Gestor Global de Estado y Sistema de Guardado/Cargado desde Cero — Fase 2.2
## Guarda y restaura el estado completo de la aldea (Reloj, Jugador, Inventario, NPCs y Objetos Destruidos) en JSON limpio.

signal game_saved(filepath: String)
signal game_loaded(filepath: String)

const SAVE_FILE_PATH: String = "user://village_save.json"

var game_data: Dictionary = {}
var workplaces_data: Dictionary = {} # Listo para Paso 2.3 (Puestos de Trabajo y Sucesión)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			save_game()
		elif event.keycode == KEY_F9:
			load_game()

func set_flag(id: String, value: Variant) -> void:
	game_data[id] = value

func get_flag(id: String, default: Variant = null) -> Variant:
	return game_data.get(id, default)

func reset_save() -> void:
	game_data.clear()
	workplaces_data.clear()

func has_save_file(filepath: String = SAVE_FILE_PATH) -> bool:
	return FileAccess.file_exists(filepath)

func save_game(filepath: String = SAVE_FILE_PATH) -> bool:
	var player = get_tree().get_first_node_in_group("player")
	for plot in get_tree().get_nodes_in_group("farm_plots"):
		if is_instance_valid(plot) and plot.has_method("_save_state"):
			plot.call("_save_state")
	for coop in get_tree().get_nodes_in_group("chicken_coop"):
		if is_instance_valid(coop) and coop.has_method("_save_state"):
			coop.call("_save_state")
	for camp in get_tree().get_nodes_in_group("campsite"):
		if is_instance_valid(camp) and camp.has_method("_save_state"):
			camp.call("_save_state")
	var vm = get_tree().get_first_node_in_group("village_manager")
	if vm:
		set_flag("village_crime_state", {
			"wanted_level": int(vm.get("wanted_level")),
			"bounty_gold": int(vm.get("bounty_gold")),
			"player_in_jail": bool(vm.get("player_in_jail")),
			"jail_mandatory_stay_timer": float(vm.get("jail_mandatory_stay_timer")),
			"sighting_log": vm.get("sighting_log"),
			"completed_contracts_today": vm.get("completed_contracts_today"),
			"corpse_records": vm.get("corpse_records"),
			"morgue_active_corpses": vm.get("morgue_active_corpses"),
			"buried_graves": vm.get("buried_graves"),
			"economy": vm.get_economy_save_dict() if vm.has_method("get_economy_save_dict") else {}
		})

	var npcs_dict: Dictionary = {}
	for npc in get_tree().get_nodes_in_group("npcs"):
		if is_instance_valid(npc) and npc.has_method("to_save_dict"):
			npcs_dict[str(npc.get_path())] = npc.to_save_dict()

	var pets_dict: Dictionary = {}
	for pet in get_tree().get_nodes_in_group("domestic_pets"):
		if is_instance_valid(pet) and pet.has_method("to_save_dict"):
			pets_dict[str(pet.get_path())] = pet.to_save_dict()

	var hostiles_dict: Dictionary = {}
	for h in get_tree().get_nodes_in_group("plains_hostiles"):
		if is_instance_valid(h) and h.has_method("to_save_dict"):
			hostiles_dict[str(h.get_path())] = h.to_save_dict()

	var eco = get_tree().get_first_node_in_group("ecosystem_manager")
	var eco_dict: Dictionary = eco.to_save_dict() if (eco and eco.has_method("to_save_dict")) else {}

	var payload: Dictionary = {
		"version": 3,
		"saved_at": Time.get_datetime_string_from_system(),
		"world_clock": WorldClock.to_dict() if WorldClock else {},
		"world_flags": game_data.duplicate(),
		"workplaces": workplaces_data.duplicate(true),
		"player": player.to_save_dict() if (player and player.has_method("to_save_dict")) else {},
		"npcs": npcs_dict,
		"domestic_pets": pets_dict,
		"plains_hostiles": hostiles_dict,
		"ecosystem": eco_dict,
		"objectives": ObjectiveManager.to_save_dict() if (ObjectiveManager and ObjectiveManager.has_method("to_save_dict")) else {}
	}

	var file := FileAccess.open(filepath, FileAccess.WRITE)
	if not file:
		push_error("GameManager: No se pudo abrir para guardar: " + filepath)
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

	if player and player.has_method("show_hint"):
		var time_str := WorldClock.get_formatted_time() if WorldClock else ""
		player.show_hint("💾 Partida Guardada — %s" % time_str)

	game_saved.emit(filepath)
	return true

func load_game(filepath: String = SAVE_FILE_PATH) -> bool:
	if not FileAccess.file_exists(filepath):
		var p = get_tree().get_first_node_in_group("player")
		if p and p.has_method("show_hint"):
			p.show_hint("⚠ No existe partida guardada aún ([F5] para guardar).")
		return false

	var file := FileAccess.open(filepath, FileAccess.READ)
	if not file:
		return false

	var raw_text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameManager: Archivo de guardado corrupto.")
		return false

	var data: Dictionary = parsed

	# 0. Cerrar cualquier diálogo, juego de taberna o modal activo antes de restaurar la partida
	var scene_root := get_tree().current_scene
	if scene_root:
		var dm = scene_root.get_node_or_null("Systems/dialogue_manager")
		if dm and dm.has_method("is_active") and bool(dm.call("is_active")) and dm.has_method("end_dialogue"):
			dm.call("end_dialogue")
		var ui_root = scene_root.get_node_or_null("UI/UIRoot")
		if not ui_root:
			ui_root = scene_root.get_node_or_null("UI")
		if ui_root:
			var tg = ui_root.get("tavern_games")
			if tg and tg.visible and tg.has_method("close_games"):
				tg.call("close_games")
			var inv_p = ui_root.get("inv_panel")
			if inv_p is Control:
				inv_p.visible = false
			var v_map = ui_root.get("valley_map")
			if v_map:
				if bool(v_map.get("is_full_map_open")) and v_map.has_method("close_full_map"):
					v_map.call("close_full_map")
				elif "is_full_map_open" in v_map:
					v_map.is_full_map_open = false
			var tw = ui_root.get("tool_wheel")
			if tw:
				if tw.has_method("close_wheel"):
					tw.call("close_wheel", false)
				elif tw is Control:
					tw.visible = false
		var camp_node = scene_root.find_child("PlayerCampSite", true, false)
		if camp_node:
			if bool(camp_node.get("is_player_sitting")) and camp_node.has_method("_stand_up_player"):
				camp_node.call("_stand_up_player")
			elif "is_player_sitting" in camp_node:
				camp_node.is_player_sitting = false
			for cp_name in ["sleep_confirm_panel", "upgrade_panel", "chest_panel"]:
				var cp = camp_node.get(cp_name)
				if cp is Control:
					cp.visible = false
		var fish_node = scene_root.find_child("WestFishingLake", true, false)
		if fish_node and fish_node.has_method("cancel_fishing"):
			fish_node.call("cancel_fishing")
	var coop_node = get_tree().get_first_node_in_group("chicken_coop")
	if coop_node:
		var coop_p = coop_node.get("chicken_action_panel")
		if coop_p is Control:
			coop_p.visible = false
	var vm_pre = get_tree().get_first_node_in_group("village_manager")
	if vm_pre:
		for vp_name in ["business_panel", "morgue_panel", "board_panel", "police_panel", "church_panel"]:
			var vp = vm_pre.get(vp_name)
			if vp is Control:
				vp.visible = false
	if WorldClock and "_activity_pause_locks" in WorldClock:
		WorldClock._activity_pause_locks = 0

	# 1. Restaurar flags del mundo y objetos destructibles
	game_data = data.get("world_flags", {}).duplicate()
	workplaces_data = data.get("workplaces", {}).duplicate(true)

	for obj in get_tree().get_nodes_in_group("destructible"):
		if is_instance_valid(obj) and not (obj is HarvestableNode) and "persistence_id" in obj and obj.persistence_id != "":
			var flag_val = get_flag(obj.persistence_id, false)
			if obj.has_method("set_destroyed_state"):
				obj.call("set_destroyed_state", typeof(flag_val) == TYPE_BOOL and flag_val == true)
			elif typeof(flag_val) == TYPE_BOOL and flag_val == true:
				obj.queue_free()

	# 2. Restaurar Reloj del Mundo e iluminación
	if WorldClock and data.has("world_clock"):
		WorldClock.from_dict(data["world_clock"])

	# 3. Restaurar Jugador e Inventario
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("from_save_dict") and data.has("player"):
		player.from_save_dict(data["player"])

	# 4. Restaurar NPCs y Mascotas de la aldea
	var saved_npcs: Dictionary = data.get("npcs", {})
	for npc in get_tree().get_nodes_in_group("npcs"):
		if is_instance_valid(npc) and npc.has_method("from_save_dict"):
			var path_key := str(npc.get_path())
			if saved_npcs.has(path_key):
				npc.from_save_dict(saved_npcs[path_key])
			else:
				var n_str := str(npc.name)
				if n_str.begins_with("NPC_Newcomer_") or n_str.begins_with("NPC_Hired_") or n_str.begins_with("NPC_Traveler_") or n_str.begins_with("NPC_Rehired_") or n_str.begins_with("NPC_Innkeeper_"):
					npc.remove_from_group("village_npcs")
					npc.remove_from_group("npcs")
					npc.remove_from_group("enemies")
					npc.queue_free()

	var saved_pets: Dictionary = data.get("domestic_pets", {})
	for pet in get_tree().get_nodes_in_group("domestic_pets"):
		if is_instance_valid(pet) and pet.has_method("from_save_dict"):
			var p_key := str(pet.get_path())
			if saved_pets.has(p_key):
				pet.from_save_dict(saved_pets[p_key])

	# 5. Restaurar Enemigos de la Llanura Salvaje y Ciénaga
	var saved_hostiles: Dictionary = data.get("plains_hostiles", {})
	for h in get_tree().get_nodes_in_group("plains_hostiles"):
		if is_instance_valid(h) and h.has_method("from_save_dict"):
			var h_key := str(h.get_path())
			if saved_hostiles.has(h_key):
				h.from_save_dict(saved_hostiles[h_key])

	# 6. Restaurar Ecosistema del Bosque Profundo y Estado Policial/Morgue
	var eco = get_tree().get_first_node_in_group("ecosystem_manager")
	if eco and eco.has_method("from_save_dict") and data.has("ecosystem") and typeof(data["ecosystem"]) == TYPE_DICTIONARY:
		eco.from_save_dict(data["ecosystem"])
	if ObjectiveManager and ObjectiveManager.has_method("from_save_dict") and data.has("objectives") and typeof(data["objectives"]) == TYPE_DICTIONARY:
		ObjectiveManager.from_save_dict(data["objectives"])
	var vm = get_tree().get_first_node_in_group("village_manager")
	var c_state: Variant = get_flag("village_crime_state", null)
	if vm and typeof(c_state) == TYPE_DICTIONARY:
		if vm.has_method("clear_police_hostility"):
			vm.call("clear_police_hostility")
		vm.player_being_escorted_to_jail = false
		vm.escorting_officer = null
		vm.is_resisting_arrest = false
		vm.wanted_level = int(c_state.get("wanted_level", 0))
		vm.bounty_gold = int(c_state.get("bounty_gold", 0))
		vm.player_in_jail = bool(c_state.get("player_in_jail", false))
		vm.jail_mandatory_stay_timer = float(c_state.get("jail_mandatory_stay_timer", 0.0))
		if vm.has_method("set_jail_cell_gate_locked"):
			vm.call("set_jail_cell_gate_locked", vm.player_in_jail)
		if c_state.has("sighting_log") and typeof(c_state["sighting_log"]) == TYPE_ARRAY:
			vm.sighting_log.clear()
			for s_item in c_state["sighting_log"]:
				if typeof(s_item) == TYPE_DICTIONARY:
					vm.sighting_log.append(s_item)
		if c_state.has("completed_contracts_today") and typeof(c_state["completed_contracts_today"]) == TYPE_DICTIONARY:
			vm.completed_contracts_today.clear()
			var saved_c: Dictionary = c_state["completed_contracts_today"]
			for ck in saved_c.keys():
				vm.completed_contracts_today[int(str(ck))] = int(saved_c[ck])
		if c_state.has("corpse_records") and typeof(c_state["corpse_records"]) == TYPE_ARRAY:
			vm.corpse_records.clear()
			for r in c_state["corpse_records"]:
				if typeof(r) == TYPE_DICTIONARY:
					vm.corpse_records.append(r)
		if c_state.has("morgue_active_corpses") and typeof(c_state["morgue_active_corpses"]) == TYPE_ARRAY:
			vm.morgue_active_corpses.clear()
			for mr in c_state["morgue_active_corpses"]:
				if typeof(mr) == TYPE_DICTIONARY:
					vm.morgue_active_corpses.append(mr)
			if vm.has_method("_refresh_morgue_table_sprites"):
				vm.call("_refresh_morgue_table_sprites")
		if c_state.has("buried_graves") and typeof(c_state["buried_graves"]) == TYPE_ARRAY:
			vm.buried_graves.clear()
			for bg in c_state["buried_graves"]:
				if typeof(bg) == TYPE_DICTIONARY:
					vm.buried_graves.append(bg)
			if vm.has_method("_rebuild_cemetery_graves_from_save"):
				vm.call("_rebuild_cemetery_graves_from_save")
		if c_state.has("economy") and typeof(c_state["economy"]) == TYPE_DICTIONARY and vm.has_method("load_economy_save_dict"):
			vm.load_economy_save_dict(c_state["economy"])

	if player and player.has_method("show_hint"):
		var time_str := WorldClock.get_formatted_time() if WorldClock else ""
		player.show_hint("📂 Partida Cargada — %s" % time_str)

	game_loaded.emit(filepath)
	return true
