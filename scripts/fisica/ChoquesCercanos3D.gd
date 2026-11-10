extends Node3D

## ChoquesCercanos3D: copias sólidas en 3D de las paredes invisibles del mapa (2D) que hay cerca de un cuerpo 3D.
## Paso del mundo a 3D, paso 1 (docs/PLAN_MUNDO_3D.md), 2026-11-10.
##
## Por qué así: el pueblo ya tiene ajustadas sus paredes invisibles (muros con hueco de puerta, muebles, rocas, vallas,
## vecinos, puertas que se abren y se cierran, paredes que solo cuentan en la planta alta…). En vez de rehacerlas, cada
## paso se pregunta al mapa qué choques hay alrededor (con la misma máscara que usaba el protagonista) y se mantiene una
## copia 3D de cada uno, levantada como un muro desde el suelo. Lo que se apaga, aparece o se mueve en el mapa se copia
## solo. En el paso 2 los suelos y alturas pasan a ser geometría de verdad.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

const RADIO_PX: float = 110.0      ## se copian los choques a esta distancia del cuerpo (píxeles del mapa)
const MAX_CHOQUES: int = 256
const BAJO_SUELO_M: float = 1.0    ## los muros empiezan este trozo por debajo del suelo…
const ALTO_MURO_M: float = 4.0     ## …y suben hasta aquí (no se puede saltar por encima, igual que antes)
const SEGMENTOS_CIRCULO: int = 12

var _copias: Dictionary = {}       ## clave «rid:forma» → StaticBody3D
var _consulta := PhysicsShapeQueryParameters2D.new()
var _circulo := CircleShape2D.new()


func _init() -> void:
	name = "ChoquesCercanos3D"
	_circulo.radius = RADIO_PX
	_consulta.shape = _circulo
	_consulta.collide_with_areas = false
	_consulta.collide_with_bodies = true


## Pone al día las copias alrededor de `centro` (mapa). `mascara` = capas 2D con las que choca el cuerpo; `excluir` = RIDs
## del propio actor. `suelo_y` = altura 3D del suelo bajo el cuerpo (los muros se levantan desde ahí).
func actualizar(espacio: PhysicsDirectSpaceState2D, centro: Vector2, mascara: int, excluir: Array[RID], suelo_y: float) -> void:
	_consulta.transform = Transform2D(0.0, centro)
	_consulta.collision_mask = mascara
	_consulta.exclude = excluir
	var vistos := {}
	for r in espacio.intersect_shape(_consulta, MAX_CHOQUES):
		var rid: RID = r["rid"]
		var idx: int = int(r["shape"])
		var clave := "%d:%d" % [rid.get_id(), idx]
		vistos[clave] = true
		var copia: StaticBody3D = _copias.get(clave)
		if copia == null:
			copia = _crear_copia(rid, idx)
			if copia == null:
				continue
			_copias[clave] = copia
		_colocar(copia, rid, idx, suelo_y)
	for clave in _copias.keys():
		if not vistos.has(clave):
			(_copias[clave] as Node).queue_free()
			_copias.erase(clave)


func cuantas() -> int:
	return _copias.size()


func _crear_copia(rid: RID, idx: int) -> StaticBody3D:
	var forma := _forma_3d(PhysicsServer2D.body_get_shape(rid, idx))
	if forma == null:
		return null
	var cuerpo := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = forma
	cuerpo.add_child(cs)
	add_child(cuerpo)
	return cuerpo


## Coloca la copia donde está ahora el choque del mapa (por si se mueve: vecinos, carros, puertas…).
func _colocar(copia: StaticBody3D, rid: RID, idx: int, suelo_y: float) -> void:
	var t2: Transform2D = (PhysicsServer2D.body_get_state(rid, PhysicsServer2D.BODY_STATE_TRANSFORM) as Transform2D) \
		* PhysicsServer2D.body_get_shape_transform(rid, idx)
	var o3 := Mapa3D.a_3d(t2.origin)
	o3.y = suelo_y - BAJO_SUELO_M
	var x3 := Mapa3D.dir_a_3d(t2.x)
	var z3 := Mapa3D.dir_a_3d(t2.y)
	var t3 := Transform3D(Basis(x3, Vector3.UP, z3), o3)
	if not copia.global_transform.is_equal_approx(t3):
		copia.global_transform = t3


## Forma 2D (del servidor de física) → muro 3D: la misma planta, levantada ALTO_MURO_M. Las medidas en metros, con el eje
## «y» del mapa como z del 3D; la base queda en y = 0 local.
func _forma_3d(forma2: RID) -> Shape3D:
	var d = PhysicsServer2D.shape_get_data(forma2)
	match PhysicsServer2D.shape_get_type(forma2):
		PhysicsServer2D.SHAPE_RECTANGLE:
			var e: Vector2 = d
			return _prisma(PackedVector2Array([Vector2(-e.x, -e.y), Vector2(e.x, -e.y), Vector2(e.x, e.y), Vector2(-e.x, e.y)]))
		PhysicsServer2D.SHAPE_CIRCLE:
			return _prisma(_circulo_puntos(float(d), Vector2.ZERO))
		PhysicsServer2D.SHAPE_CAPSULE:
			var c: Vector2 = d # (radio, alto total)
			var pts := _circulo_puntos(c.x, Vector2(0, -(c.y * 0.5 - c.x)))
			pts.append_array(_circulo_puntos(c.x, Vector2(0, c.y * 0.5 - c.x)))
			return _prisma(pts)
		PhysicsServer2D.SHAPE_CONVEX_POLYGON:
			return _prisma(d)
		PhysicsServer2D.SHAPE_CONCAVE_POLYGON, PhysicsServer2D.SHAPE_SEGMENT:
			var segs := PackedVector2Array()
			if d is Rect2:
				segs.append((d as Rect2).position)
				segs.append((d as Rect2).size)
			else:
				segs = d
			return _paredes(segs)
	return null


func _circulo_puntos(r: float, c: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(SEGMENTOS_CIRCULO):
		pts.append(c + Vector2.RIGHT.rotated(TAU * i / SEGMENTOS_CIRCULO) * r)
	return pts


func _prisma(pts2: PackedVector2Array) -> ConvexPolygonShape3D:
	var pts3 := PackedVector3Array()
	for p in pts2:
		var b := Mapa3D.a_3d(p)
		pts3.append(Vector3(b.x, 0.0, b.z))
		pts3.append(Vector3(b.x, ALTO_MURO_M + BAJO_SUELO_M, b.z))
	var s := ConvexPolygonShape3D.new()
	s.points = pts3
	return s


## Segmentos sueltos (bordes de polígonos cóncavos): una pared fina por segmento.
func _paredes(segs: PackedVector2Array) -> ConcavePolygonShape3D:
	var tris := PackedVector3Array()
	var h := ALTO_MURO_M + BAJO_SUELO_M
	for i in range(0, segs.size() - 1, 2):
		var a := Mapa3D.a_3d(segs[i])
		var b := Mapa3D.a_3d(segs[i + 1])
		var a1 := a + Vector3(0, h, 0)
		var b1 := b + Vector3(0, h, 0)
		tris.append_array([a, b, b1, a, b1, a1])
	var s := ConcavePolygonShape3D.new()
	s.backface_collision = true
	s.set_faces(tris)
	return s
