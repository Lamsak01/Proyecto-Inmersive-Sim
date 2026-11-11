extends RefCounted

## Puertas interiores (cuartos de la posada; fallo visible del usuario, 2026-11-11): hojas de madera 3D que giran solas
## cuando alguien (el protagonista o un vecino del mismo piso) se acerca al hueco. Solo se ven: no chocan ni tocan el
## mapa, así los vecinos pasan por los huecos como hasta ahora. Las hojas quedan fuera de la unión de mallas.

const RADIO_PX: float = 16.0           ## a esta distancia del hueco la puerta se abre
const GIRO_GRADOS: float = 82.0        ## cuánto gira la hoja al abrirse
const VELOCIDAD_GRADOS_S: float = 260.0

var _puertas: Array[Dictionary] = []   ## {"pivote": Node3D, "pos": Vector2 (mapa), "nivel": int}


func anadir(pivote: Node3D, pos: Vector2, nivel: int) -> void:
	_puertas.append({"pivote": pivote, "pos": pos, "nivel": nivel})


func limpiar() -> void:
	_puertas.clear()


func pivotes() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for p in _puertas:
		out.append(p["pivote"] as Node3D)
	return out


## Gira cada hoja hacia abierta o cerrada según haya gente cerca. `vm` da el piso del protagonista.
func sincronizar(arbol: SceneTree, vm: Node, delta: float) -> void:
	if _puertas.is_empty():
		return
	var gente: Array = _gente_con_piso(arbol, vm)
	for p in _puertas:
		var pivote: Node3D = p["pivote"]
		if not is_instance_valid(pivote):
			continue
		var objetivo: float = GIRO_GRADOS if _alguien_cerca(p["pos"], int(p["nivel"]), gente) else 0.0
		pivote.rotation_degrees.y = move_toward(pivote.rotation_degrees.y, objetivo, VELOCIDAD_GRADOS_S * delta)


## Posiciones y pisos de quienes pueden abrir puertas: [[Vector2, int], ...].
func _gente_con_piso(arbol: SceneTree, vm: Node) -> Array:
	var out: Array = []
	var jugador := arbol.get_first_node_in_group("player") as Node2D
	if jugador != null:
		out.append([jugador.global_position, int(vm.get("player_elevation_level"))])
	for v in arbol.get_nodes_in_group("village_npcs"):
		if v is Node2D and not (v.get("is_dead") == true):
			out.append([(v as Node2D).global_position, int(v.get("elevation_level"))])
	return out


func _alguien_cerca(pos: Vector2, nivel: int, gente: Array) -> bool:
	for g in gente:
		if int(g[1]) == nivel and (g[0] as Vector2).distance_squared_to(pos) <= RADIO_PX * RADIO_PX:
			return true
	return false
