extends SceneTree

## Prueba del paso a 3D, paso 1b (docs/PLAN_MUNDO_3D.md): el protagonista, con su cuerpo 3D, entra y sale andando
## por TODAS las puertas de edificio del pueblo (abiertas) sin quedarse atascado. Sin ventana, ~2 min.
## Uso: timeout 600 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/puertas_3d.gd
## Termina con «PUERTAS 3D: PASSED» o «FAILED» y la lista de puertas que fallan.

const VEL: float = 120.0      ## píxeles del mapa por segundo (andar normal)
const SEGUNDOS: float = 1.2   ## tiempo andando en cada sentido
const DESDE_PX: float = 30.0  ## se empieza a esta distancia de la puerta

var _fallos: Array[String] = []


func _initialize() -> void:
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(20):
		await physics_frame
		await process_frame
	var pl = get_first_node_in_group("player")
	var vm = get_first_node_in_group("village_manager")
	var mc = pl.get_node("PlayerMovementController")
	mc.set_physics_process(false) # lo movemos nosotros, paso a paso
	var n: int = 0
	for d in vm.building_doors:
		n += 1
		await _probar_puerta(pl, mc, vm, d)
	print("PUERTAS 3D: %d puertas, %d fallos" % [n, _fallos.size()])
	for f in _fallos:
		print("  FALLO  " + f)
	print("PUERTAS 3D: %s" % ("PASSED" if _fallos.is_empty() else "FAILED"))
	quit(1 if not _fallos.is_empty() else 0)


## Entra desde fuera y sale desde dentro, andando recto por el centro de la puerta.
func _probar_puerta(pl, mc, vm, d: Dictionary) -> void:
	var id: String = String(d.get("building_id", "?"))
	var fuera: Vector2 = vm.get_door_outward_dir(d)
	var rect: Rect2 = d["building_rect"]
	var pos: Vector2 = d["pos"]
	vm._set_door_state(d, true, false, true)
	d["manual_override_timer"] = 999.0
	pl.global_position = pos + fuera * DESDE_PX
	await _andar(pl, mc, vm, d, -fuera)
	var dentro: float = (pl.global_position - pos).dot(-fuera)
	if not (rect.has_point(pl.global_position) and dentro > 10.0):
		_fallos.append("%s: no entra (se queda en %s, %.0f px dentro)" % [id, str(pl.global_position.round()), dentro])
	pl.global_position = pos - fuera * DESDE_PX
	await _andar(pl, mc, vm, d, fuera)
	var fuera_px: float = (pl.global_position - pos).dot(fuera)
	if fuera_px < 10.0:
		_fallos.append("%s: no sale (se queda en %s, %.0f px fuera)" % [id, str(pl.global_position.round()), fuera_px])
	else:
		print("  OK  %s" % id)


func _andar(pl, mc, vm, d: Dictionary, dir: Vector2) -> void:
	for _i in range(int(SEGUNDOS * 60.0)):
		if not bool(d.get("is_open", false)):
			vm._set_door_state(d, true, false, true)
		pl.velocity = dir * VEL
		mc._mover()
		await physics_frame
