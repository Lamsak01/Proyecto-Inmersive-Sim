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
		_que_hay_cerca(pl, id)
	pl.global_position = pos - fuera * DESDE_PX
	await _andar(pl, mc, vm, d, fuera)
	var fuera_px: float = (pl.global_position - pos).dot(fuera)
	if fuera_px < 10.0:
		_fallos.append("%s: no sale (se queda en %s, %.0f px fuera)" % [id, str(pl.global_position.round()), fuera_px])
		_que_hay_cerca(pl, id)
	else:
		print("  OK  %s" % id)


## Al fallar: qué choques del mapa y qué vecinos hay pegados al protagonista (para saber qué lo para).
func _que_hay_cerca(pl, id: String) -> void:
	var q := PhysicsShapeQueryParameters2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 14.0
	q.shape = circ
	q.transform = Transform2D(0.0, pl.global_position)
	q.collision_mask = 1 | (1 << 19)
	for r in pl.get_world_2d().direct_space_state.intersect_shape(q, 12):
		var col = r["collider"]
		print("    DBG %s: choque %s grupos %s en %s" % [id, col.name, str(col.get_groups()), str((col as Node2D).global_position.round()) if col is Node2D else "?"])
	for n in get_nodes_in_group("village_npcs"):
		if n.global_position.distance_to(pl.global_position) < 30.0:
			print("    DBG %s: vecino %s en %s vel %s cuerpo %s" % [id, n.npc_name, str(n.global_position.round()), str(n.velocity.round()), str(n.has_meta("cuerpo3d"))])
	var c = pl.get_node("PlayerMovementController").cuerpo()
	print("    DBG %s: cuerpo 3D en %s suelo %.2f copias %d" % [id, str(c.global_position), c._suelo_y, c.choques_copiados()])
	for n3 in _todos(c.get_parent()):
		if n3 is CollisionObject3D and n3 != c and (n3 as Node3D).global_position.distance_to(c.global_position) < 1.0:
			var forma = n3.get_child(0) if n3.get_child_count() > 0 else null
			var padre: Node = n3.get_parent()
			var guion: String = str(padre.get_script().resource_path).get_file() if padre.get_script() != null else "sin guion"
			var origen: String = "?"
			if padre.get("_copias") is Dictionary:
				for k in (padre.get("_copias") as Dictionary).keys():
					if (padre.get("_copias") as Dictionary)[k] == n3:
						var rid_id: int = int(str(k).split(":")[0])
						for cand in _todos(get_root()):
							if cand is CollisionObject2D and (cand as CollisionObject2D).get_rid().get_id() == rid_id:
								origen = "%s grupos %s en %s capa %d" % [cand.name, str(cand.get_groups()), str((cand as Node2D).global_position.round()), cand.collision_layer]
			print("    DBG %s: pieza 3D %s (padre %s [%s]) a %.2f m, copia de: %s" % [id, n3.name, padre.name, guion, (n3 as Node3D).global_position.distance_to(c.global_position), origen])


func _todos(n: Node) -> Array:
	var out: Array = [n]
	for ch in n.get_children():
		out.append_array(_todos(ch))
	return out


func _andar(pl, mc, vm, d: Dictionary, dir: Vector2) -> void:
	for _i in range(int(SEGUNDOS * 60.0)):
		if not bool(d.get("is_open", false)):
			vm._set_door_state(d, true, false, true)
		pl.velocity = dir * VEL
		mc._mover()
		await physics_frame
