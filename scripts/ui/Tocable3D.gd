class_name Tocable3D
extends Area3D

## Tocable3D: la zona del mundo 3D donde algo se puede usar con [E] (paso a 3D, tanda 7-E, 2026-11-14).
## La pone quien se deja usar (hoy, el animal muerto que se despieza; después mascotas, vecinos, puertas…) y la busca
## el selector de la E: lo que hay al alcance del protagonista en la vista desde arriba y, en 1.ª persona, lo que
## cruza un rayo desde sus ojos hacia donde mira, a su altura de verdad. Sustituye, cosa a cosa, a las áreas
## «interactable» del mapa plano y a las reglas de ángulos con las que se adivinaba a qué apuntaba la cruz.

const Capas3D = preload("res://scripts/fisica/Capas3D.gd")

const MAX_A_LA_VEZ: int = 16      ## cosas que se miran en una misma búsqueda

var duenio: Node = null           ## a quién le llega el [E]: debe saber `interact(player)`


## Pone en `padre` una zona redonda de `radio` metros, apoyada en el suelo, para usar a `p_duenio`.
static func poner(padre: Node3D, p_duenio: Node, radio: float) -> Tocable3D:
	var t := Tocable3D.new()
	t.name = "Tocable3D"
	t.duenio = p_duenio
	t.collision_layer = Capas3D.TOCABLES
	t.collision_mask = 0
	t.monitoring = false
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = radio
	forma.shape = esfera
	forma.position.y = radio
	t.add_child(forma)
	padre.add_child(t)
	return t


## Las zonas que tocan una esfera (lo que el protagonista tiene al alcance).
static func cerca(mundo: World3D, centro: Vector3, radio: float) -> Array[Tocable3D]:
	var consulta := PhysicsShapeQueryParameters3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = radio
	consulta.shape = esfera
	consulta.transform = Transform3D(Basis.IDENTITY, centro)
	consulta.collision_mask = Capas3D.TOCABLES
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false
	var out: Array[Tocable3D] = []
	for r: Dictionary in mundo.direct_space_state.intersect_shape(consulta, MAX_A_LA_VEZ):
		var t: Tocable3D = r["collider"] as Tocable3D
		if t != null and is_instance_valid(t.duenio):
			out.append(t)
	return out


## La primera zona que cruza la mirada: un rayo desde `ojos` hacia `hacia`, de `alcance` metros. Las paredes la tapan.
static func en_la_mira(mundo: World3D, ojos: Vector3, hacia: Vector3, alcance: float) -> Tocable3D:
	var rayo := PhysicsRayQueryParameters3D.create(ojos, ojos + hacia.normalized() * alcance, Capas3D.TOCABLES | Capas3D.MUROS)
	rayo.collide_with_areas = true
	rayo.collide_with_bodies = true
	rayo.hit_from_inside = true
	return mundo.direct_space_state.intersect_ray(rayo).get("collider") as Tocable3D
