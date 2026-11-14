extends SceneTree

## Caso I, día 2: tras el aviso, el guardia se queda vigilando el cuerpo (su turno no lo saca de ahí) y el cuerpo cuenta
## las horas desde la muerte (~01:00), no desde que empezó la partida: a las 09:30 está «rígido», no «deteriorado».
## Uso (~2 min): timeout 300 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/custodia_cuerpo.gd 2>&1 | grep "CUSTODIA CUERPO"

const ESCENA_JUEGO: String = "uid://dsoiuct8kdsk3"
const FRAMES_ARRANQUE: int = 35
const RUTA_CASO1: String = "res://scripts/systems/VillageCase1.gd" ## con load() tras arrancar: usa autoloads
const HORA_DESDE: int = 7 * 60 + 30   ## desde aquí el guardia ya debería estar en su puesto
const HORA_FIN: int = 9 * 60 + 30
const CERCA_PX: float = 120.0         ## ~7 m del cuerpo cuenta como «vigilando»
const MIN_EN_PUESTO: float = 0.8      ## al menos el 80 % de las muestras, junto al cuerpo
const PODRE_MIN_H: float = 6.0        ## «rígido»
const PODRE_MAX_H: float = 12.0

func _initialize() -> void:
	root.add_child((load(ESCENA_JUEGO) as PackedScene).instantiate())
	for _i in range(FRAMES_ARRANQUE):
		await process_frame
	var reloj: Node = root.get_node("/root/WorldClock")
	reloj.set("current_day", 2)
	reloj.set("current_hour", 5)
	reloj.set("current_minute", 50)
	var vm: Node = get_first_node_in_group("village_manager")
	var jugador: Node = get_first_node_in_group("player")
	jugador.get_node("PlayerMovementController").set_physics_process(false)
	var dm: Node = jugador.get("dialogue_manager")
	var caso1 = load(RUTA_CASO1)
	var cuerpo: Node2D = vm.entities_root.get_node("NPC_Case1_Victim") as Node2D
	var muestras: int = 0
	var en_puesto: int = 0
	var ultimo: int = -1
	while _minutos(reloj) < HORA_FIN:
		await physics_frame
		if bool(dm.call("is_active")):
			dm.call("end_dialogue") # el recado del guardia: se escucha y se sigue
		var m: int = _minutos(reloj)
		if m < HORA_DESDE or m == ultimo or m % 10 != 0:
			continue
		ultimo = m
		var guardia: Node2D = _guardia(caso1.state(vm))
		muestras += 1
		if guardia != null and guardia.global_position.distance_to(cuerpo.global_position) <= CERCA_PX:
			en_puesto += 1
	var podre: float = float(cuerpo.get("corpse_rot_hours"))
	var vigila: bool = muestras > 0 and float(en_puesto) / float(muestras) >= MIN_EN_PUESTO
	var podre_ok: bool = podre >= PODRE_MIN_H and podre <= PODRE_MAX_H
	print("[CUSTODIA] junto al cuerpo %d de %d muestras · horas de muerte a las 09:30 = %.1f" % [en_puesto, muestras, podre])
	print("CUSTODIA CUERPO: %s" % ["PASSED" if vigila and podre_ok else "FAILED"])
	quit(0 if vigila and podre_ok else 1)

func _guardia(st: Dictionary) -> Node2D:
	for n in get_nodes_in_group("village_npcs"):
		if str(n.get("npc_name")) == str(st.get("guardia", "")):
			return n as Node2D
	return null

func _minutos(reloj: Node) -> int:
	return int(reloj.get("current_hour")) * 60 + int(reloj.get("current_minute"))
