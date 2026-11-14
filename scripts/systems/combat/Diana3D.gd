class_name Diana3D
extends Area3D

## Diana3D: la zona del cuerpo 3D de un personaje donde se le puede herir (paso a 3D, tanda 7a, 2026-11-14).
## Sustituye a la «Hurtbox» del mapa plano: la espada y las flechas buscan dianas en el mundo 3D, a su altura de
## verdad, así que ya no hace falta preguntar en qué piso está cada uno.
## - La pone el cuerpo 3D de todo personaje que sepa recibir daño (`take_damage`); mide lo que su cuerpo más un margen.
## - Quien la tiene la apaga y la enciende con `poner_activa` (muerto, escondido en la madriguera, fuera de juego…).

signal golpe_recibido(dano: DamageData)

const CAPA: int = 32              ## capa 3D de las dianas (solo las miran las búsquedas de golpes)
const MARGEN_M: float = 0.12      ## lo que la diana sobresale del cuerpo
const RADIO_MIN_M: float = 0.3    ## un conejo no mide más de 15 cm de radio: con esto aún se le puede acertar
const META: String = "diana3d"    ## cada personaje guarda aquí su diana
const META_ACTIVA: String = "diana_activa" ## y aquí si la quiere encendida (por si aún no tiene cuerpo)
const MAX_POR_GOLPE: int = 16     ## dianas que puede tocar un mismo tajo
const GROSOR_CORTINA_M: float = 0.1 ## ancho de la «cortina» de una flecha (ver en_cortina)

var duenio: Node = null           ## a quién se hiere al acertar
var _forma: CollisionShape3D = null


## Pone una diana en `cuerpo` para herir a `p_duenio` (que debe saber `take_damage`).
static func poner(cuerpo: Node3D, p_duenio: Node) -> Diana3D:
	var d := Diana3D.new()
	d.name = "Diana3D"
	d.duenio = p_duenio
	d.collision_layer = CAPA
	d.collision_mask = 0
	d.monitoring = false
	d._forma = CollisionShape3D.new()
	d._forma.shape = CapsuleShape3D.new()
	d.add_child(d._forma)
	d.golpe_recibido.connect(Callable(p_duenio, "take_damage"))
	p_duenio.set_meta(META, d)
	cuerpo.add_child(d)
	d._aplicar_activa(bool(p_duenio.get_meta(META_ACTIVA, true)))
	return d


## La diana de `quien` (null si no tiene o aún no tiene cuerpo).
static func de(quien: Node) -> Diana3D:
	var d: Variant = quien.get_meta(META) if quien.has_meta(META) else null
	return d as Diana3D if is_instance_valid(d) else null


## Enciende o apaga la diana de `quien`. Si su cuerpo aún no existe, se recuerda para cuando la tenga.
static func poner_activa(quien: Node, activa: bool) -> void:
	quien.set_meta(META_ACTIVA, activa)
	var d: Diana3D = de(quien)
	if d != null:
		d._aplicar_activa(activa)


## Las dianas que toca una esfera (un tajo de espada). `mundo`: el espacio 3D donde viven los cuerpos.
static func en_esfera(mundo: World3D, centro: Vector3, radio: float) -> Array[Diana3D]:
	var consulta := PhysicsShapeQueryParameters3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = radio
	consulta.shape = esfera
	consulta.transform = Transform3D(Basis.IDENTITY, centro)
	consulta.collision_mask = CAPA
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false
	var out: Array[Diana3D] = []
	for r: Dictionary in mundo.direct_space_state.intersect_shape(consulta, MAX_POR_GOLPE):
		if r["collider"] is Diana3D:
			out.append(r["collider"] as Diana3D)
	return out


## La primera diana que cruza el tramo de `a` a `b` (el vuelo de una flecha en un paso), sin contar la de `tirador`.
static func en_tramo(mundo: World3D, a: Vector3, b: Vector3, tirador: Node) -> Diana3D:
	var rayo := PhysicsRayQueryParameters3D.create(a, b, CAPA)
	rayo.collide_with_areas = true
	rayo.collide_with_bodies = false
	rayo.hit_from_inside = true
	var suya: Diana3D = de(tirador) if is_instance_valid(tirador) else null
	if suya != null:
		rayo.exclude = [suya.get_rid()]
	var r: Dictionary = mundo.direct_space_state.intersect_ray(rayo)
	return r.get("collider") as Diana3D


## Como `en_tramo`, pero el tramo alcanza también lo que tiene debajo hasta `caida_m` metros: una «cortina». Es para
## quien no puede apuntar hacia abajo (la vista desde arriba): su flecha da a un conejo aunque salga a la altura del pecho.
static func en_cortina(mundo: World3D, a: Vector3, b: Vector3, caida_m: float, tirador: Node) -> Diana3D:
	var largo: float = a.distance_to(b)
	if largo < 0.001:
		return null
	var caja := BoxShape3D.new()
	caja.size = Vector3(GROSOR_CORTINA_M, caida_m, largo)
	var consulta := PhysicsShapeQueryParameters3D.new()
	consulta.shape = caja
	var centro: Vector3 = (a + b) * 0.5 - Vector3.UP * caida_m * 0.5
	consulta.transform = Transform3D(Basis.looking_at((b - a) * Vector3(1.0, 0.0, 1.0) + Vector3(0.0, 0.0, 0.0001), Vector3.UP), centro)
	consulta.collision_mask = CAPA
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false
	var mejor: Diana3D = null
	for r: Dictionary in mundo.direct_space_state.intersect_shape(consulta, MAX_POR_GOLPE):
		var d: Diana3D = r["collider"] as Diana3D
		if d == null or d.duenio == tirador:
			continue
		if mejor == null or d.global_position.distance_squared_to(a) < mejor.global_position.distance_squared_to(a):
			mejor = d
	return mejor


## Le llega un golpe: avisa a su dueño.
func recibir(dano: DamageData) -> void:
	golpe_recibido.emit(dano)


## Tamaño de la diana a partir del cuerpo (`radio` y `alto` en metros), con su margen.
func medir(radio: float, alto: float) -> void:
	var capsula := _forma.shape as CapsuleShape3D
	var r: float = maxf(RADIO_MIN_M, radio + MARGEN_M)
	var h: float = maxf(alto + MARGEN_M, r * 2.0)
	if capsula.radius == r and capsula.height == h:
		return
	capsula.radius = r
	capsula.height = h
	_forma.position.y = h * 0.5


func _aplicar_activa(activa: bool) -> void:
	_forma.set_deferred("disabled", not activa)
