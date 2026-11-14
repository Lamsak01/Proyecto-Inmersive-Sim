extends SceneTree

## Mientras hablas con un vecino en primera persona el reloj del pueblo se para, la frase sale entera y, al despedirte,
## el reloj vuelve a andar. Uso (~1 min) → «PAUSA DIALOGO: PASSED»:
##   timeout 180 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/pausa_dialogo.gd

const ESCENA_JUEGO: String = "uid://dsoiuct8kdsk3"
const FRAMES_ARRANQUE: int = 35
const ESPERA_CHARLA_MS: int = 3000 ## tiempo real con la caja abierta
const FRASE: String = "Buenos días, forastero. El molino lleva cerrado desde la riada, y nadie quiere acercarse."

func _initialize() -> void:
	root.add_child((load(ESCENA_JUEGO) as PackedScene).instantiate())
	for _i in range(FRAMES_ARRANQUE):
		await process_frame
	var reloj: Node = root.get_node_or_null("WorldClock")
	var jugador: Node = get_first_node_in_group("player")
	var stage: Node = _buscar_stage()
	if stage != null:
		stage.call("set_first_person", true)
	var dm: Node = jugador.get("dialogue_manager") if jugador != null else null
	var vecinos: Array[Node] = get_nodes_in_group("npcs")
	if dm == null or reloj == null or vecinos.is_empty():
		print("[PAUSA] ❌ falta algo: gestor=%s reloj=%s vecinos=%d" % [dm != null, reloj != null, vecinos.size()])
		quit(1)
		return
	var hablante: Node = vecinos[0]
	var grafo: Dictionary = {"start": {"text": FRASE, "choices": [{"text": "Adiós", "next": "fin"}]}}
	var hora_antes: int = int(reloj.get("current_hour")) * 60 + int(reloj.get("current_minute"))
	var pos_antes: Array[Vector2] = _posiciones(vecinos)
	dm.call("start_dialogue", grafo, "start", hablante)
	var inicio: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - inicio < ESPERA_CHARLA_MS:
		await process_frame
	var hora_despues: int = int(reloj.get("current_hour")) * 60 + int(reloj.get("current_minute"))
	var movidos: int = _contar_movidos(vecinos, pos_antes)
	var ventana: Node = dm.get("_ventana")
	var entera: bool = ventana != null and not bool(ventana.call("revelando"))
	print("[PAUSA] primera persona: %s" % [stage != null])
	print("[PAUSA] juego pausado: %s" % [paused])
	print("[PAUSA] reloj parado: %s (minutos que pasaron: %d)" % [bool(reloj.call("is_time_frozen")), hora_despues - hora_antes])
	print("[PAUSA] vecinos que se movieron: %d de %d" % [movidos, vecinos.size()])
	print("[PAUSA] frase entera tras %d s: %s" % [ESPERA_CHARLA_MS / 1000, entera])
	var parado: bool = bool(reloj.call("is_time_frozen")) and hora_despues == hora_antes
	dm.call("end_dialogue")
	var suelto: bool = not bool(reloj.call("is_time_frozen"))
	print("[PAUSA] reloj suelto al despedirte: %s" % [suelto])
	var ok: bool = parado and entera and suelto and not paused
	print("PAUSA DIALOGO: %s" % ["PASSED" if ok else "FAILED"])
	quit(0 if ok else 1)

func _buscar_stage() -> Node:
	for n in root.find_children("*", "", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("WorldStage3D.gd"):
			return n
	return null

func _posiciones(vecinos: Array[Node]) -> Array[Vector2]:
	var res: Array[Vector2] = []
	for v in vecinos:
		res.append((v as Node2D).global_position if v is Node2D else Vector2.ZERO)
	return res

func _contar_movidos(vecinos: Array[Node], antes: Array[Vector2]) -> int:
	var n: int = 0
	for i in range(vecinos.size()):
		if vecinos[i] is Node2D and (vecinos[i] as Node2D).global_position.distance_to(antes[i]) > 1.0:
			n += 1
	return n
