extends Node3D

## CuerposCercanos3D: un cuerpo 3D «de contacto» para cada vecino, bandido o animal grande que el protagonista tiene
## cerca, para que no se le pueda atravesar. Paso del mundo a 3D, pasos 4b y 4c (docs/PLAN_MUNDO_3D.md), 2026-11-10;
## opción A del usuario.
## - Cada uno sigue andando como siempre por el mapa; su cuerpo solo le sigue, a la altura del suelo que pisa (Suelo.gd),
##   así un vecino de la planta de arriba no estorba abajo.
## - El cuerpo 3D del protagonista choca con ellos; si alguien anda hacia él, lo aparta un poco.
## - Tienen cuerpo (decisión del usuario): vecinos, bandidos y enemigos, jabalíes, ciervos y el ganado grande. Los
##   pequeños (conejos, zorros, mascotas, gallinas y crías) se siguen atravesando. Tu caballo no: va contigo.
## - No tienen cuerpo los dormidos, muertos, caídos o sentados (se puede pasar por encima; la silla sí estorba).
## - Si el protagonista anda contra alguien, lo aparta poco a poco (Cuerpo3D._apartar): cada cuerpo sabe de quién es.
## - Más adelante (opción B) los vecinos tendrán su propio cuerpo completo y un buscador de caminos 3D.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Suelo = preload("res://scripts/fisica/Suelo.gd")
const WorldStageBase3D = preload("res://scripts/visuals/WorldStageBase3D.gd")

const PERSONA: Vector2 = Vector2(0.28, 1.74)   ## radio y alto (m), como el protagonista
const ANIMAL: Vector2 = Vector2(0.4, 1.3)      ## jabalí, ciervo, oveja, vaca…
const CERCA_PX: float = 110.0      ## tienen cuerpo los que están a esta distancia (como las paredes copiadas)
const MAX_CUERPOS: int = 16
const GRUPOS: Array[String] = ["village_npcs", "raiders", "enemies", "wild_animals", "livestock_animals"]
const GANADO_GRANDE: Array[String] = ["sheep", "cow", "bull", "donkey", "horse"]

var _cuerpos: Array[AnimatableBody3D] = []
var _de_quien: Dictionary = {}     ## quién → cuerpo


func _init() -> void:
	name = "CuerposCercanos3D"


## Pone al día los cuerpos alrededor de `centro` (sitio del protagonista en el mapa).
func actualizar(centro: Vector2, vm: Node) -> void:
	var cerca: Array = _cercanos(centro)
	var siguen := {}
	for n in cerca:
		siguen[n] = true
	for n in _de_quien.keys():
		if not is_instance_valid(n) or not siguen.has(n): # (un bandido muerto o huido desaparece del árbol)
			_soltar(n)
	for n in cerca:
		var c: AnimatableBody3D = _de_quien.get(n)
		if c == null:
			c = _coger()
			if c == null:
				break
			_de_quien[n] = c
			c.set_meta("quien", n)
		_colocar(c, n, vm)


func cuantos() -> int:
	return _de_quien.size()


## ¿Tiene ahora cuerpo `n`?
func tiene_cuerpo(n: Node) -> bool:
	return _de_quien.has(n)


## Tamaño (radio, alto en m) del cuerpo de contacto de `n`, o Vector2.ZERO si no debe tenerlo: pequeño, dormido,
## muerto, caído, o con cuerpo completo (opción B; ese cuerpo usa `tamano_de_pie` para apagarse cuando no está de pie).
static func tamano(n: Node) -> Vector2:
	if n.has_meta("cuerpo3d") and not n.is_in_group("player"):
		return Vector2.ZERO
	return tamano_de_pie(n)


## Tamaño del cuerpo de `n` si está de pie; Vector2.ZERO si es pequeño o está dormido, muerto, caído o sentado.
static func tamano_de_pie(n: Node) -> Vector2:
	if _si(n, "is_dead") or _si(n, "is_downed") or _si(n, "is_sleeping") or _si(n, "is_at_poker_table"):
		return Vector2.ZERO
	# Sentado solo si está quieto: las sillas del salón quedan bajo la galería de la posada y el mapa no distingue pisos
	var quieto: bool = not ("velocity" in n) or (n.get("velocity") as Vector2).length_squared() < 4.0
	if quieto and n.has_method("_is_seated_on_furniture") and bool(n.call("_is_seated_on_furniture", (n as Node2D).global_position)):
		return Vector2.ZERO
	if n.is_in_group("wild_animals"):
		var vivo: bool = n.has_method("is_alive_in_ecosystem") and bool(n.call("is_alive_in_ecosystem"))
		var grande: bool = int(n.get("species")) in [1, 3] # WildAnimal.SpeciesType: DEER, BOAR
		return ANIMAL if vivo and grande else Vector2.ZERO
	if n.is_in_group("livestock_animals"):
		return ANIMAL if str(n.get("species")) in GANADO_GRANDE and not (str(n.get("stage")) in ["chick", "juvenile"]) else Vector2.ZERO
	if n.is_in_group("raiders") and str(n.get("kind")) == "boar":
		return ANIMAL
	return PERSONA


## ¿Tiene `n` la propiedad `prop` y está a true? (no todos tienen las mismas: el ganado no duerme ni cae)
static func _si(n: Node, prop: String) -> bool:
	return prop in n and bool(n.get(prop))


## Los que deben tener cuerpo, del más cercano al más lejano (como mucho MAX_CUERPOS).
func _cercanos(centro: Vector2) -> Array:
	var out: Array = []
	var vistos := {}
	for g in GRUPOS:
		for n in get_tree().get_nodes_in_group(g):
			var v := n as Node2D
			if v == null or vistos.has(v) or not v.visible or v.global_position.distance_squared_to(centro) > CERCA_PX * CERCA_PX:
				continue
			vistos[v] = true
			if tamano(v) != Vector2.ZERO:
				out.append(v)
	out.sort_custom(func(a, b): return a.global_position.distance_squared_to(centro) < b.global_position.distance_squared_to(centro))
	return out.slice(0, MAX_CUERPOS)


## Pone el cuerpo de `n` donde está en el mapa, de pie sobre el suelo de su piso y con su tamaño.
func _colocar(c: AnimatableBody3D, n: Node2D, vm: Node) -> void:
	var p: Vector2 = n.global_position
	var nivel: int = int(n.get("elevation_level")) if "elevation_level" in n else 0
	var alto_px: float = WorldStageBase3D.terrain_height_px(p) + Suelo.altura_px(p, nivel, vm)
	c.global_position = Mapa3D.a_3d(p, alto_px)
	var cs := c.get_child(0) as CollisionShape3D
	var t: Vector2 = tamano(n)
	var forma := cs.shape as CapsuleShape3D
	if forma.radius != t.x or forma.height != t.y:
		forma.radius = t.x
		forma.height = t.y
		cs.position.y = t.y * 0.5
	cs.disabled = false


## Un cuerpo libre (o uno nuevo). null si ya hay MAX_CUERPOS en uso.
func _coger() -> AnimatableBody3D:
	for c in _cuerpos:
		if not _de_quien.values().has(c):
			return c
	if _cuerpos.size() >= MAX_CUERPOS:
		return null
	var c := AnimatableBody3D.new()
	c.name = "CuerpoCercano%d" % _cuerpos.size()
	c.sync_to_physics = false
	var cs := CollisionShape3D.new()
	cs.shape = CapsuleShape3D.new()
	c.add_child(cs)
	add_child(c)
	_cuerpos.append(c)
	return c


## Ya no está cerca (o se ha dormido, caído, o ya no existe): su cuerpo queda libre y apagado.
func _soltar(n) -> void:
	var c: AnimatableBody3D = _de_quien[n]
	_de_quien.erase(n)
	(c.get_child(0) as CollisionShape3D).disabled = true
	c.global_position = Vector3(0.0, -500.0, 0.0)
