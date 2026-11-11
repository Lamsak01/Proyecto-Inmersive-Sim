extends Node3D

## CuerposVecinos3D: un cuerpo 3D «de contacto» para cada vecino que el protagonista tiene cerca, para que no se le
## pueda atravesar. Paso del mundo a 3D, paso 4b (docs/PLAN_MUNDO_3D.md), 2026-11-10; opción A del usuario.
## - El vecino sigue andando como siempre por el mapa (sus «vías»); su cuerpo solo le sigue, a la altura del suelo que
##   pisa (Suelo.gd), así un vecino de la planta de arriba no estorba abajo.
## - El cuerpo 3D del protagonista choca con ellos; si un vecino anda hacia él, lo aparta un poco.
## - No tienen cuerpo los vecinos dormidos, muertos o en el suelo (se puede pasar por encima).
## - Más adelante (opción B) los vecinos tendrán su propio cuerpo completo y un buscador de caminos 3D.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Suelo = preload("res://scripts/fisica/Suelo.gd")
const WorldStageBase3D = preload("res://scripts/visuals/WorldStageBase3D.gd")

const RADIO_M: float = 0.28        ## igual que el protagonista
const ALTO_M: float = 1.74
const CERCA_PX: float = 110.0      ## tienen cuerpo los vecinos a esta distancia del protagonista (como las paredes copiadas)
const MAX_CUERPOS: int = 16

var _cuerpos: Array[AnimatableBody3D] = []
var _de_quien: Dictionary = {}     ## vecino → cuerpo


func _init() -> void:
	name = "CuerposVecinos3D"


## Pone al día los cuerpos alrededor de `centro` (sitio del protagonista en el mapa).
func actualizar(centro: Vector2, vm: Node) -> void:
	var cerca: Array = _vecinos_cerca(centro)
	var siguen := {}
	for n in cerca:
		siguen[n] = true
	for n in _de_quien.keys():
		if not siguen.has(n):
			_soltar(n)
	for n in cerca:
		var c: AnimatableBody3D = _de_quien.get(n)
		if c == null:
			c = _coger()
			if c == null:
				break
			_de_quien[n] = c
		_colocar(c, n, vm)


func cuantos() -> int:
	return _de_quien.size()


## ¿Tiene ahora cuerpo este vecino?
func tiene_cuerpo(n: Node) -> bool:
	return _de_quien.has(n)


## Los vecinos que deben tener cuerpo, del más cercano al más lejano (como mucho MAX_CUERPOS).
func _vecinos_cerca(centro: Vector2) -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group("village_npcs"):
		var v := n as Node2D
		if v == null or not v.is_inside_tree() or v.global_position.distance_squared_to(centro) > CERCA_PX * CERCA_PX:
			continue
		if bool(v.get("is_dead")) or bool(v.get("is_downed")) or bool(v.get("is_sleeping")):
			continue
		out.append(v)
	out.sort_custom(func(a, b): return a.global_position.distance_squared_to(centro) < b.global_position.distance_squared_to(centro))
	return out.slice(0, MAX_CUERPOS)


## Pone el cuerpo de `n` donde está en el mapa, de pie sobre el suelo de su piso.
func _colocar(c: AnimatableBody3D, n: Node2D, vm: Node) -> void:
	var p: Vector2 = n.global_position
	var nivel: int = int(n.get("elevation_level"))
	var alto_px: float = WorldStageBase3D.terrain_height_px(p) + Suelo.altura_px(p, nivel, vm)
	c.global_position = Mapa3D.a_3d(p, alto_px)
	(c.get_child(0) as CollisionShape3D).disabled = false


## Un cuerpo libre (o uno nuevo). null si ya hay MAX_CUERPOS en uso.
func _coger() -> AnimatableBody3D:
	for c in _cuerpos:
		if not _de_quien.values().has(c):
			return c
	if _cuerpos.size() >= MAX_CUERPOS:
		return null
	var c := AnimatableBody3D.new()
	c.name = "CuerpoVecino%d" % _cuerpos.size()
	c.sync_to_physics = false
	var forma := CapsuleShape3D.new()
	forma.radius = RADIO_M
	forma.height = ALTO_M
	var cs := CollisionShape3D.new()
	cs.shape = forma
	cs.position.y = ALTO_M * 0.5
	c.add_child(cs)
	add_child(c)
	_cuerpos.append(c)
	return c


## El vecino ya no está cerca (o se ha dormido, caído…): su cuerpo queda libre y apagado.
func _soltar(n: Node) -> void:
	var c: AnimatableBody3D = _de_quien[n]
	_de_quien.erase(n)
	(c.get_child(0) as CollisionShape3D).disabled = true
	c.global_position = Vector3(0.0, -500.0, 0.0)
