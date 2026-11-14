extends SceneTree

## Caso I: el día de llegada (día 1) el zapato del Puente Viejo no se ve ni se puede examinar; el día 2 sí. Uso (~1 min):
##   timeout 150 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/pistas_dia1.gd 2>&1 | grep "PISTAS DIA1"

const ESCENA_JUEGO: String = "uid://dsoiuct8kdsk3"
const FRAMES_ARRANQUE: int = 35
const RUTA_CASO1: String = "res://scripts/systems/VillageCase1.gd" ## con load() tras arrancar: usa autoloads
const DELANTE_PX: float = 18.0
const MIRAR_ABAJO: float = -0.6

func _initialize() -> void:
	root.add_child((load(ESCENA_JUEGO) as PackedScene).instantiate())
	for _i in range(FRAMES_ARRANQUE):
		await process_frame
	var reloj: Node = root.get_node("/root/WorldClock")
	var vm: Node = get_first_node_in_group("village_manager")
	var jugador: Node2D = get_first_node_in_group("player") as Node2D
	jugador.get_node("PlayerMovementController").set_physics_process(false)
	_buscar_stage().call("set_first_person", true)
	var caso1 = load(RUTA_CASO1)
	reloj.set("current_day", 1)
	caso1.sync(vm)
	var dia1_visible: bool = _zapato_visible()
	var dia1_examina: bool = await _apunta_zapato(vm, jugador)
	reloj.set("current_day", 2)
	reloj.set("current_hour", 7)
	caso1.sync(vm)
	var dia2_visible: bool = _zapato_visible()
	var dia2_examina: bool = await _apunta_zapato(vm, jugador)
	print("[PISTAS] día 1: se ve=%s se examina=%s · día 2: se ve=%s se examina=%s" % [dia1_visible, dia1_examina, dia2_visible, dia2_examina])
	var ok: bool = not dia1_visible and not dia1_examina and dia2_visible and dia2_examina
	print("PISTAS DIA1: %s" % ["PASSED" if ok else "FAILED"])
	quit(0 if ok else 1)

func _zapato_visible() -> bool:
	var pistas: Array[Node] = get_nodes_in_group("pista_caso1")
	return not pistas.is_empty() and (pistas[0] as Node3D).is_visible_in_tree()

func _apunta_zapato(vm: Node, jugador: Node2D) -> bool:
	var zona: Node2D = vm.get_node("OldBridgeVictimShoeArea") as Node2D
	jugador.global_position = zona.global_position + Vector2(0.0, DELANTE_PX)
	var stage: Node = _buscar_stage()
	stage.set("fp_yaw", Vector2.UP.angle())
	stage.set("fp_pitch", MIRAR_ABAJO)
	for _i in range(4):
		await physics_frame
	var sel: Node = jugador.get("interaction_selector")
	sel.call("refresh")
	for c in sel.get("candidates"):
		if str((c as Dictionary).get("station", "")) == "old_bridge_left_shoe":
			return true
	return false

func _buscar_stage() -> Node:
	for n in root.find_children("*", "", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("WorldStage3D.gd"):
			return n
	return null
