extends Node3D

## CuerposDelPueblo3D: reparte cuerpos 3D completos (Cuerpo3D) a los vecinos que el protagonista tiene cerca y se los
## quita cuando se alejan. Paso del mundo a 3D, opción B (paso 4), noche del 2026-11-11.
## - Híbrido por rendimiento (decisión del usuario): solo los vecinos a menos de CERCA_PX llevan cuerpo completo; los
##   lejanos siguen andando por el mapa como siempre (y con la simulación simplificada que ya tenían).
## - Cada vecino sabe si tiene cuerpo por su meta «cuerpo3d»; su movimiento lo usa (VillageNPCSocial).
## - Red de seguridad: si un vecino con cuerpo intenta andar y no avanza durante ATASCO_S, se le quita el cuerpo un rato
##   (SIN_CUERPO_S) y vuelve a las rutas de siempre, que lo recolocan; así un rincón raro no lo deja clavado.

const Cuerpo3D = preload("res://scripts/fisica/Cuerpo3D.gd")

const CERCA_PX: float = 150.0      ## a esta distancia del protagonista un vecino lleva cuerpo completo
const LEJOS_PX: float = 190.0      ## y a esta lo pierde (margen para no ponerlo y quitarlo sin parar)
const MAX_CUERPOS: int = 24
const GRUPOS: Array[String] = ["village_npcs"]
const ATASCO_S: float = 5.0
const SIN_CUERPO_S: float = 10.0

var _con_cuerpo: Array = []        ## vecinos que ahora tienen cuerpo
var _ultima_pos: Dictionary = {}   ## vecino → dónde estaba hace un momento (para ver si avanza)
var _parado_s: Dictionary = {}     ## vecino → segundos seguidos intentando andar sin avanzar


func _init() -> void:
	name = "CuerposDelPueblo3D"


## Pone al día quién tiene cuerpo alrededor de `centro` (sitio del protagonista en el mapa).
func actualizar(centro: Vector2) -> void:
	var ahora: float = Time.get_ticks_msec() / 1000.0
	for n in _con_cuerpo.duplicate():
		if not is_instance_valid(n) or (n as Node2D).global_position.distance_to(centro) > LEJOS_PX or bool(n.get("is_dead")):
			_quitar(n)
		elif _atascado(n):
			_quitar(n)
			n.set_meta("sin_cuerpo_hasta", ahora + SIN_CUERPO_S)
	if _con_cuerpo.size() >= MAX_CUERPOS:
		return
	for g in GRUPOS:
		for n in get_tree().get_nodes_in_group(g):
			if n is CharacterBody2D and not n.has_meta("cuerpo3d") and not bool(n.get("is_dead")) and (n as Node2D).global_position.distance_to(centro) <= CERCA_PX:
				if n.has_meta("sin_cuerpo_hasta") and float(n.get_meta("sin_cuerpo_hasta")) > ahora:
					continue
				_dar(n)
				if _con_cuerpo.size() >= MAX_CUERPOS:
					return


func cuantos() -> int:
	return _con_cuerpo.size()


## ¿Lleva ATASCO_S intentando andar (velocidad > 5 px/s) sin avanzar ni un cuarto de lo que debería?
func _atascado(n: Node2D) -> bool:
	var v: float = (n.get("velocity") as Vector2).length()
	var antes: Vector2 = _ultima_pos.get(n, n.global_position)
	var dt: float = get_physics_process_delta_time()
	_ultima_pos[n] = n.global_position
	if v > 5.0 and n.global_position.distance_to(antes) < v * dt * 0.25:
		_parado_s[n] = float(_parado_s.get(n, 0.0)) + dt
	else:
		_parado_s[n] = 0.0
	return float(_parado_s[n]) >= ATASCO_S


func _dar(n: CharacterBody2D) -> void:
	n.set_meta("cuerpo3d", Cuerpo3D.crear(n, get_parent()))
	_con_cuerpo.append(n)


func _quitar(n) -> void:
	_con_cuerpo.erase(n)
	_ultima_pos.erase(n)
	_parado_s.erase(n)
	if is_instance_valid(n):
		var c = n.get_meta("cuerpo3d") if n.has_meta("cuerpo3d") else null
		n.remove_meta("cuerpo3d")
		if is_instance_valid(c):
			c.queue_free()
