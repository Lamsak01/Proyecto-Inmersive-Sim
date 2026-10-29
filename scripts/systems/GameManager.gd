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
			"corpse_records": vm.get("corpse_records")
		})

	var npcs_dict: Dictionary = {}
	for npc in get_tree().get_nodes_in_group("npcs"):
		if is_instance_valid(npc) and npc.has_method("to_save_dict"):
			npcs_dict[str(npc.get_path())] = npc.to_save_dict()

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
		"plains_hostiles": hostiles_dict,
		"ecosystem": eco_dict
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

	# 1. Restaurar flags del mundo y objetos destructibles
	game_data = data.get("world_flags", {}).duplicate()
	workplaces_data = data.get("workplaces", {}).duplicate(true)

	for obj in get_tree().get_nodes_in_group("destructible"):
		if is_instance_valid(obj) and not (obj is HarvestableNode) and "persistence_id" in obj and obj.persistence_id != "":
			var flag_val = get_flag(obj.persistence_id, false)
			if typeof(flag_val) == TYPE_BOOL and flag_val == true:
				obj.queue_free()

	# 2. Restaurar Reloj del Mundo e iluminación
	if WorldClock and data.has("world_clock"):
		WorldClock.from_dict(data["world_clock"])

	# 3. Restaurar Jugador e Inventario
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("from_save_dict") and data.has("player"):
		player.from_save_dict(data["player"])

	# 4. Restaurar NPCs de la aldea
	var saved_npcs: Dictionary = data.get("npcs", {})
	for npc in get_tree().get_nodes_in_group("npcs"):
		if is_instance_valid(npc) and npc.has_method("from_save_dict"):
			var path_key := str(npc.get_path())
			if saved_npcs.has(path_key):
				npc.from_save_dict(saved_npcs[path_key])

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
	var vm = get_tree().get_first_node_in_group("village_manager")
	var c_state: Variant = get_flag("village_crime_state", null)
	if vm and typeof(c_state) == TYPE_DICTIONARY:
		vm.wanted_level = int(c_state.get("wanted_level", 0))
		vm.bounty_gold = int(c_state.get("bounty_gold", 0))
		if c_state.has("corpse_records") and typeof(c_state["corpse_records"]) == TYPE_ARRAY:
			vm.corpse_records.clear()
			for r in c_state["corpse_records"]:
				if typeof(r) == TYPE_DICTIONARY:
					vm.corpse_records.append(r)

	if player and player.has_method("show_hint"):
		var time_str := WorldClock.get_formatted_time() if WorldClock else ""
		player.show_hint("📂 Partida Cargada — %s" % time_str)

	game_loaded.emit(filepath)
	return true
