extends SceneTree

## Caso I, día 2 al alba: el guardia mensajero llega hasta el jugador (quieto donde empieza) en menos de una hora de
## juego y le da el recado de Vane con la caja de diálogo, no con una línea suelta. Uso (~1–2 min):
##   timeout 240 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/aviso_caso1.gd 2>&1 | grep "AVISO CASO1"

const ESCENA_JUEGO: String = "uid://dsoiuct8kdsk3"
const FRAMES_ARRANQUE: int = 35
const MINUTOS_MAX: int = 60 ## de juego, desde las 06:00
const RUTA_CASO1: String = "res://scripts/systems/VillageCase1.gd" ## con load() tras arrancar: usa autoloads

func _initialize() -> void:
	root.add_child((load(ESCENA_JUEGO) as PackedScene).instantiate())
	for _i in range(FRAMES_ARRANQUE):
		await process_frame
	var reloj: Node = root.get_node("/root/WorldClock")
	reloj.set("current_day", 2)
	reloj.set("current_hour", 5)
	reloj.set("current_minute", 50)
	var jugador: Node = get_first_node_in_group("player")
	jugador.get_node("PlayerMovementController").set_physics_process(false)
	var dm: Node = jugador.get("dialogue_manager")
	var vm: Node = get_first_node_in_group("village_manager")
	var limite: int = 6 * 60 + MINUTOS_MAX
	while _minutos(reloj) < limite and not bool(dm.call("is_active")):
		await physics_frame
	var st: Dictionary = load(RUTA_CASO1).state(vm)
	var hablante: Node = dm.get("current_speaker")
	var guardia_habla: bool = bool(dm.call("is_active")) and is_instance_valid(hablante) and str(hablante.get("npc_name")) == str(st.get("guardia", ""))
	print("[AVISO] %02d:%02d aviso=%s guardia=%s habla=%s" % [reloj.get("current_hour"), reloj.get("current_minute"), st.get("aviso", "-"), st.get("guardia", "-"), guardia_habla])
	var ok: bool = str(st.get("aviso", "")) == "dado" and guardia_habla
	print("AVISO CASO1: %s" % ["PASSED" if ok else "FAILED"])
	quit(0 if ok else 1)

func _minutos(reloj: Node) -> int:
	return int(reloj.get("current_hour")) * 60 + int(reloj.get("current_minute"))
