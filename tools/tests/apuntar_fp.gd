extends SceneTree

## En 1.ª persona, la cruz alcanza el tablón de encargos apuntando a su centro (no solo a una esquina) y una trampilla
## del suelo a ~1,6 m mirando hacia abajo. Uso (~40 s):
##   timeout 120 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/apuntar_fp.gd 2>&1 | grep "APUNTAR FP"

const ESCENA_JUEGO: String = "uid://dsoiuct8kdsk3"
const FRAMES_ARRANQUE: int = 35
const CENTRO_TABLON_M: Vector2 = Vector2(131.04, 3.92) ## centro medido del dibujo del tablón (x, z en metros)
const ESCALA_M_POR_PX: float = 0.056
const DELANTE_PX: float = 25.0      ## ~1,4 m delante del tablón
const TRAMPILLA_PX: float = 29.0    ## ~1,6 m de la trampilla
const MIRAR_ABAJO: float = -0.6

func _initialize() -> void:
	root.add_child((load(ESCENA_JUEGO) as PackedScene).instantiate())
	for _i in range(FRAMES_ARRANQUE):
		await process_frame
	var jugador: Node2D = get_first_node_in_group("player") as Node2D
	jugador.get_node("PlayerMovementController").set_physics_process(false)
	var stage: Node = _buscar_stage()
	stage.call("set_first_person", true)
	var centro: Vector2 = CENTRO_TABLON_M / ESCALA_M_POR_PX
	var tablon: bool = await _apunta(jugador, stage, centro + Vector2(0.0, DELANTE_PX), centro, 0.0, "notice_board")
	var rejilla: Node2D = get_first_node_in_group("sewer_grate") as Node2D
	var trampilla: bool = rejilla != null and await _apunta(jugador, stage, rejilla.global_position + Vector2(0.0, TRAMPILLA_PX), rejilla.global_position, MIRAR_ABAJO, "")
	print("[APUNTAR] tablón por el centro=%s trampilla a 1,6 m=%s" % [tablon, trampilla])
	print("APUNTAR FP: %s" % ["PASSED" if tablon and trampilla else "FAILED"])
	quit(0 if tablon and trampilla else 1)

## Coloca al jugador, le hace mirar al punto y dice si la cruz elige algo (con esa etiqueta de puesto, si se pide).
func _apunta(jugador: Node2D, stage: Node, desde: Vector2, hacia: Vector2, pitch: float, puesto: String) -> bool:
	jugador.global_position = desde
	stage.set("fp_yaw", (hacia - desde).angle())
	stage.set("fp_pitch", pitch)
	for _i in range(4):
		await physics_frame
	var sel: Node = jugador.get("interaction_selector")
	sel.call("refresh")
	var elegido: Dictionary = sel.call("selected")
	if elegido.is_empty():
		return false
	return puesto == "" or str(elegido.get("station", "")) == puesto

func _buscar_stage() -> Node:
	for n in root.find_children("*", "", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("WorldStage3D.gd"):
			return n
	return null
