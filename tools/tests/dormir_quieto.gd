extends SceneTree

## Al dormir el mundo va acelerado y el jugador no se puede mover; si algo le hiere, se despierta. Uso (~40 s):
##   timeout 120 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/dormir_quieto.gd 2>&1 | grep "DORMIR QUIETO"

const ESCENA_JUEGO: String = "uid://dsoiuct8kdsk3"
const FRAMES_ARRANQUE: int = 35
const FRAMES_DORMIDO: int = 30
const GOLPE: float = 5.0

func _initialize() -> void:
	root.add_child((load(ESCENA_JUEGO) as PackedScene).instantiate())
	for _i in range(FRAMES_ARRANQUE):
		await process_frame
	var reloj: Node = root.get_node("/root/WorldClock")
	var jugador: Node = get_first_node_in_group("player")
	reloj.call("sleep_until_morning")
	for _i in range(FRAMES_DORMIDO):
		await physics_frame
	var quieto: bool = bool(jugador.call("is_any_ui_modal_open"))
	var salud: Node = jugador.get("health_comp")
	salud.set("current_health", float(salud.get("current_health")) - GOLPE)
	salud.emit_signal("health_changed", salud.get("current_health"), salud.get("max_health"))
	await physics_frame
	var despierto: bool = not bool(reloj.get("is_fast_forwarding")) and not bool(jugador.call("is_any_ui_modal_open"))
	print("[DORMIR] quieto al dormir=%s despierta con un golpe=%s" % [quieto, despierto])
	print("DORMIR QUIETO: %s" % ["PASSED" if quieto and despierto else "FAILED"])
	quit(0 if quieto and despierto else 1)
