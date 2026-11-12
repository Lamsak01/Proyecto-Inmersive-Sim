extends Node

## Gestor Global de Estado y Sistema de Guardado/Cargado desde Cero — Fase 2.2
## Guarda y restaura el estado completo de la aldea (Reloj, Jugador, Inventario, NPCs y Objetos Destruidos) en JSON limpio.

signal game_saved(filepath: String)
signal game_loaded(filepath: String)

const SAVE_FILE_PATH: String = "user://village_save.json"

## Interruptor único del «MODO DEMO» (Caso I — `docs/PLAN_BETA_MISTERIO.md` §5 y §5b).
## Encendido por defecto (`true`) mientras dure la preparación de la demo.
## Cuando está activo, quedan en pausa los sistemas secundarios que podrían estropear el caso
## (crímenes espontáneos, bajos fondos, secta, migración/linaje/enfermedades, política/préstamos/fama/clanes,
## ecosistema del bosque, escuela y mercado semanal).
## Al apagarlo (`GameManager.set_demo_mode(false)` o `DEMO_MODE_DEFAULT = false`), todo vuelve a funcionar igual.
const DEMO_MODE_DEFAULT: bool = true
var demo_mode: bool = DEMO_MODE_DEFAULT:
	set(value):
		if demo_mode == value:
			return
		demo_mode = value
		if is_inside_tree() and get_tree():
			var vm_d = get_tree().get_first_node_in_group("village_manager")
			if vm_d and "demo_mode" in vm_d and bool(vm_d.get("demo_mode")) != value:
				vm_d.set("demo_mode", value)
			var eco_d = get_tree().get_first_node_in_group("ecosystem_manager")
			if eco_d and eco_d.has_method("_on_demo_mode_changed"):
				eco_d.call("_on_demo_mode_changed", value)

func is_demo_mode() -> bool:
	return demo_mode

func set_demo_mode(enabled: bool) -> void:
	demo_mode = enabled

var game_data: Dictionary = {}
var workplaces_data: Dictionary = {} # Listo para Paso 2.3 (Puestos de Trabajo y Sucesión)

## Huecos de guardado (menú principal, 2026-11-10). «rapida» es la de F5/F12; «auto» se guarda sola al empezar
## cada día de juego. Junto a cada partida se escribe un «.info.json» pequeño (día, hora, fecha real) para el menú.
const RANURAS: Dictionary = {
	"auto": "user://partida_auto.json",
	"rapida": SAVE_FILE_PATH,
	"1": "user://partida_1.json",
	"2": "user://partida_2.json",
	"3": "user://partida_3.json",
}
const NOMBRE_RANURA: Dictionary = {"auto": "Autoguardado", "rapida": "Guardado rápido", "1": "Partida 1", "2": "Partida 2", "3": "Partida 3"}
## Partida que hay que cargar en cuanto el pueblo termine de montarse (la pide el menú principal).
var carga_pendiente: String = ""
var _autoguardado_pendiente: bool = false
var _espera_autoguardado: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if WorldClock and not WorldClock.day_passed.is_connected(_on_dia_nuevo):
		WorldClock.day_passed.connect(_on_dia_nuevo)

func _on_dia_nuevo(_dia: int) -> void:
	# Las pruebas automáticas no deben pisar el autoguardado del jugador.
	if DisplayServer.get_name() != "headless":
		_autoguardado_pendiente = true

func _process(delta: float) -> void:
	if not _autoguardado_pendiente or get_tree().paused:
		return
	_espera_autoguardado -= delta
	if _espera_autoguardado > 0.0:
		return
	_espera_autoguardado = 2.0
	if _se_puede_guardar_ahora() and get_tree().get_first_node_in_group("player") != null:
		_autoguardado_pendiente = false
		save_game(RANURAS["auto"], "💾 Autoguardado")

func _se_puede_guardar_ahora() -> bool:
	var vm = get_tree().get_first_node_in_group("village_manager")
	if WorldClock and bool(WorldClock.get("is_fast_forwarding")):
		return false
	if vm and bool(vm.get("player_being_escorted_to_jail")):
		return false
	var player = get_tree().get_first_node_in_group("player")
	var dm = player.get("dialogue_manager") if player else null
	if dm and dm.has_method("is_active") and bool(dm.call("is_active")):
		return false
	return true

func ruta_info(filepath: String) -> String:
	return filepath.get_basename() + ".info.json"

## {existe, dia, hora, fecha} de un hueco. Si falta el «.info.json» (partidas antiguas) se lee la partida entera.
func info_ranura(id: String) -> Dictionary:
	var ruta: String = str(RANURAS.get(id, ""))
	var info: Dictionary = {"existe": false, "dia": 0, "hora": "", "fecha": "", "ruta": ruta, "nombre": str(NOMBRE_RANURA.get(id, id))}
	if ruta == "" or not FileAccess.file_exists(ruta):
		return info
	info["existe"] = true
	var datos: Variant = null
	if FileAccess.file_exists(ruta_info(ruta)):
		datos = JSON.parse_string(FileAccess.get_file_as_string(ruta_info(ruta)))
	if typeof(datos) == TYPE_DICTIONARY:
		info["dia"] = int(datos.get("dia", 0))
		info["hora"] = str(datos.get("hora", ""))
		info["fecha"] = str(datos.get("fecha", ""))
	else:
		var todo: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
		if typeof(todo) == TYPE_DICTIONARY:
			var wc: Dictionary = todo.get("world_clock", {})
			info["dia"] = int(wc.get("day", 0))
			info["hora"] = "%02d:%02d" % [int(wc.get("hour", 0)), int(wc.get("minute", 0))]
			info["fecha"] = str(todo.get("saved_at", ""))
	info["fecha"] = str(info["fecha"]).replace("T", " ").left(16)
	info["mtime"] = FileAccess.get_modified_time(ruta)
	return info

## El hueco guardado más reciente (para «Continuar»), o "" si no hay ninguno.
func ranura_mas_reciente() -> String:
	var mejor: String = ""
	var t_mejor: int = -1
	for id in RANURAS.keys():
		var ruta: String = RANURAS[id]
		if FileAccess.file_exists(ruta):
			var t: int = FileAccess.get_modified_time(ruta)
			if t > t_mejor:
				t_mejor = t
				mejor = id
	return mejor

func borrar_ranura(id: String) -> void:
	var ruta: String = str(RANURAS.get(id, ""))
	for r in [ruta, ruta_info(ruta)]:
		if r != "" and FileAccess.file_exists(r):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(r))

## Lo llama el pueblo al terminar de montarse: si el menú pidió cargar una partida, se carga ahora.
func al_entrar_en_el_mundo() -> void:
	if carga_pendiente == "":
		return
	var ruta: String = carga_pendiente
	carga_pendiente = ""
	for _i in range(30):
		await get_tree().physics_frame
		await get_tree().process_frame
	load_game(ruta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if Teclas.es(event, "guardado_rapido"):
			save_game()
		elif Teclas.es(event, "carga_rapida"):
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

func save_game(filepath: String = SAVE_FILE_PATH, aviso: String = "") -> bool:
	var player = get_tree().get_first_node_in_group("player")
	var vm = get_tree().get_first_node_in_group("village_manager")
	if (WorldClock and bool(WorldClock.get("is_fast_forwarding"))) or (vm and bool(vm.get("player_being_escorted_to_jail"))):
		if player and player.has_method("show_hint"):
			player.show_hint("⏳ Espera a que termine la escolta o el descanso antes de guardar [F5].")
		return false
	var scene_root := get_tree().current_scene
	if scene_root:
		var ui := scene_root.get_node_or_null("UI/UIRoot")
		if not ui:
			ui = scene_root.get_node_or_null("UIRoot")
		if ui:
			var tg = ui.get("tavern_games")
			if tg and tg.visible and tg.has_method("close_games"):
				tg.call("close_games")
	for plot in get_tree().get_nodes_in_group("farm_plots"):
		if is_instance_valid(plot) and plot.has_method("_save_state"):
			plot.call("_save_state")
	for coop in get_tree().get_nodes_in_group("chicken_coop"):
		if is_instance_valid(coop) and coop.has_method("_save_state"):
			coop.call("_save_state")
	for camp in get_tree().get_nodes_in_group("campsite"):
		if is_instance_valid(camp) and camp.has_method("_save_state"):
			camp.call("_save_state")
	var det_ui_save := get_tree().root.find_child("DetectiveUI", true, false)
	if det_ui_save and det_ui_save.has_method("save_detective_state"):
		det_ui_save.call("save_detective_state")
	if vm:
		set_flag("village_crime_state", {
			"wanted_level": int(vm.get("wanted_level")),
			"bounty_gold": int(vm.get("bounty_gold")),
			"player_in_jail": bool(vm.get("player_in_jail")),
			"is_resisting_arrest": bool(vm.get("is_resisting_arrest")),
			"jail_mandatory_stay_timer": float(vm.get("jail_mandatory_stay_timer")),
			"crime_history": vm.get("crime_history"),
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
		"objectives": ObjectiveManager.to_save_dict() if (ObjectiveManager and ObjectiveManager.has_method("to_save_dict")) else {},
		"quests": QuestManager.to_save_dict() if QuestManager else {}
	}

	var file := FileAccess.open(filepath, FileAccess.WRITE)
	if not file:
		push_error("GameManager: No se pudo abrir para guardar: " + filepath)
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	var wc_d: Dictionary = payload["world_clock"]
	var info_f := FileAccess.open(ruta_info(filepath), FileAccess.WRITE)
	if info_f:
		info_f.store_string(JSON.stringify({
			"dia": int(wc_d.get("day", 0)),
			"hora": "%02d:%02d" % [int(wc_d.get("hour", 0)), int(wc_d.get("minute", 0))],
			"fecha": str(payload["saved_at"]),
		}))
		info_f.close()

	if player and player.has_method("show_hint"):
		var time_str := WorldClock.get_formatted_time() if WorldClock else ""
		player.show_hint("%s — %s" % [aviso if aviso != "" else "💾 Partida Guardada", time_str])

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
			var med_p = ui_root.get("medical_panel")
			if med_p is Control:
				med_p.visible = false
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
		for vp_name in ["business_panel", "morgue_panel", "jail_panel", "board_panel", "police_panel", "pantry_panel", "church_panel"]:
			var vp = vm_pre.get(vp_name)
			if vp is Control:
				vp.visible = false
	if WorldClock and WorldClock.has_method("set_activity_pause"):
		WorldClock.set_activity_pause(false)

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
	var vm = get_tree().get_first_node_in_group("village_manager")
	var saved_npcs: Dictionary = data.get("npcs", {})
	var matched_npc_keys: Dictionary = {}
	for npc in get_tree().get_nodes_in_group("npcs"):
		if is_instance_valid(npc) and npc.has_method("from_save_dict"):
			var path_key := str(npc.get_path())
			if saved_npcs.has(path_key):
				matched_npc_keys[path_key] = true
				npc.from_save_dict(saved_npcs[path_key])
			else:
				var n_str := str(npc.name)
				if n_str.begins_with("NPC_Newcomer_") or n_str.begins_with("NPC_Hired_") or n_str.begins_with("NPC_Traveler_") or n_str.begins_with("NPC_Rehired_") or n_str.begins_with("NPC_Innkeeper_") or n_str.begins_with("NPC_Royal_Investigator_") or n_str.begins_with("NPC_Merchant_") or n_str.begins_with("NPC_Noble_") or n_str.begins_with("NPC_Child_"): # V6/V9: nobles y niños también se guardan
					npc.remove_from_group("village_npcs")
					npc.remove_from_group("npcs")
					npc.remove_from_group("enemies")
					npc.name = "_freed_npc_" + str(npc.get_instance_id())
					if npc.get_parent():
						npc.get_parent().remove_child(npc)
					npc.queue_free()

	if vm and vm.has_method("spawn_dynamic_npc_from_save"):
		for s_key in saved_npcs.keys():
			var sk_str := str(s_key)
			if not matched_npc_keys.has(sk_str) and typeof(saved_npcs[s_key]) == TYPE_DICTIONARY:
				var n_name := sk_str.get_file()
				if n_name.begins_with("NPC_Newcomer_") or n_name.begins_with("NPC_Hired_") or n_name.begins_with("NPC_Traveler_") or n_name.begins_with("NPC_Rehired_") or n_name.begins_with("NPC_Innkeeper_") or n_name.begins_with("NPC_Royal_Investigator_") or n_name.begins_with("NPC_Merchant_") or n_name.begins_with("NPC_Noble_") or n_name.begins_with("NPC_Child_"): # V6/V9: nobles y niños también se guardan
					vm.call("spawn_dynamic_npc_from_save", n_name, saved_npcs[s_key])

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
	if QuestManager and data.has("quests") and typeof(data["quests"]) == TYPE_DICTIONARY:
		QuestManager.from_save_dict(data["quests"])
	elif QuestManager:
		QuestManager.clear_all() # Partida guardada antes de existir las misiones
	var c_state: Variant = get_flag("village_crime_state", null)
	if vm and typeof(c_state) == TYPE_DICTIONARY:
		vm.player_being_escorted_to_jail = false
		vm.escorting_officer = null
		vm.is_resisting_arrest = bool(c_state.get("is_resisting_arrest", false))
		vm.wanted_level = int(c_state.get("wanted_level", 0))
		vm.bounty_gold = int(c_state.get("bounty_gold", 0))
		vm.player_in_jail = bool(c_state.get("player_in_jail", false))
		vm.jail_mandatory_stay_timer = float(c_state.get("jail_mandatory_stay_timer", 0.0))
		if vm.has_method("set_jail_cell_gate_locked"):
			vm.call("set_jail_cell_gate_locked", vm.player_in_jail)
		for arr_k in ["crime_history", "sighting_log", "corpse_records", "morgue_active_corpses", "buried_graves"]:
			if c_state.has(arr_k) and typeof(c_state[arr_k]) == TYPE_ARRAY:
				var dst: Array = vm.get(arr_k)
				dst.clear()
				for item in c_state[arr_k]:
					if arr_k == "crime_history": dst.append(str(item))
					elif typeof(item) == TYPE_DICTIONARY: dst.append(item)
		if vm.has_method("_refresh_morgue_table_sprites"): vm.call("_refresh_morgue_table_sprites")
		if c_state.has("completed_contracts_today") and typeof(c_state["completed_contracts_today"]) == TYPE_DICTIONARY:
			vm.completed_contracts_today.clear()
			var saved_c: Dictionary = c_state["completed_contracts_today"]
			for ck in saved_c.keys():
				vm.completed_contracts_today[int(str(ck))] = int(saved_c[ck])
		if c_state.has("economy") and typeof(c_state["economy"]) == TYPE_DICTIONARY and vm.has_method("load_economy_save_dict"):
			vm.load_economy_save_dict(c_state["economy"])
		var det_ui_load := get_tree().root.find_child("DetectiveUI", true, false)
		if det_ui_load and det_ui_load.has_method("load_detective_state"):
			det_ui_load.call("load_detective_state")

	if player and player.has_method("show_hint"):
		var time_str := WorldClock.get_formatted_time() if WorldClock else ""
		player.show_hint("📂 Partida Cargada — %s" % time_str)

	game_loaded.emit(filepath)
	return true
