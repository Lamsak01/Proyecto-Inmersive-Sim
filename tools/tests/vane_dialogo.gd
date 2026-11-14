extends SceneTree

## Caso I: al preguntar a Vane «¿Para qué me ha mandado llamar?», la respuesta sale en la caja de diálogo, la charla
## sigue abierta y el encargo queda en el cuaderno (antes se cerraba y salía en la esquina). Uso (~40 s):
##   timeout 120 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/vane_dialogo.gd 2>&1 | grep "VANE DIALOGO"

const ESCENA_JUEGO: String = "uid://dsoiuct8kdsk3"
const FRAMES_ARRANQUE: int = 35
const RUTA_CASO1: String = "res://scripts/systems/VillageCase1.gd" ## con load() tras arrancar: usa autoloads
const PREGUNTA: String = "Para qué me ha mandado llamar"
const NODO_RESPUESTA: String = "case1_encargo_vane"

func _initialize() -> void:
	root.add_child((load(ESCENA_JUEGO) as PackedScene).instantiate())
	for _i in range(FRAMES_ARRANQUE):
		await process_frame
	var reloj: Node = root.get_node("/root/WorldClock")
	reloj.set("current_day", 2)
	reloj.set("current_hour", 8)
	var vm: Node = get_first_node_in_group("village_manager")
	var caso1 = load(RUTA_CASO1)
	caso1.sync(vm)
	caso1.state(vm)["aviso"] = "dado"
	var vane: Node = vm.entities_root.get_node("NPC_Sheriff_Vane")
	var dm: Node = get_first_node_in_group("player").get("dialogue_manager")
	dm.call("start_dialogue", vane.call("_inject_character_lore_into_dialogue", vane.call("_build_dialogue")), "start", vane)
	await process_frame
	var indice: int = -1
	var opciones: Array = dm.get("current_choices")
	for i in range(opciones.size()):
		if str((opciones[i] as Dictionary).get("label", "")).contains(PREGUNTA):
			indice = i
	dm.set("_espera", 0.0)
	if indice >= 0:
		dm.call("_on_choice_pressed", indice)
	await process_frame
	var abierta: bool = bool(dm.call("is_active")) and str(dm.get("current_id")) == NODO_RESPUESTA
	var apuntado: bool = caso1.state(vm).get("encargo_vane") == true
	print("[VANE] pregunta=%s respuesta_en_caja=%s encargo_apuntado=%s" % [indice >= 0, abierta, apuntado])
	var ok: bool = indice >= 0 and abierta and apuntado
	print("VANE DIALOGO: %s" % ["PASSED" if ok else "FAILED"])
	quit(0 if ok else 1)
