extends Node3D

## ChoquesCercanos3D: copias sólidas en 3D de las paredes invisibles del mapa (2D) que hay cerca de un cuerpo 3D.
## Paso del mundo a 3D, paso 1 (docs/PLAN_MUNDO_3D.md), 2026-11-10.
##
## Por qué así: el pueblo ya tiene ajustadas sus paredes invisibles (muros con hueco de puerta, muebles, rocas, vallas,
## vecinos, puertas que se abren y se cierran, paredes que solo cuentan en la planta alta…). En vez de rehacerlas, cada
## paso se pregunta al mapa qué choques hay alrededor (con la misma máscara que usaba el protagonista) y se mantiene una
## copia 3D de cada uno, levantada como un muro desde el suelo. Lo que se apaga, aparece o se mueve en el mapa se copia
## solo.
## Paso 2: los choques de un solo piso (Suelo.piso_de_choque) se levantan solo a la altura de su piso; así en la posada
## los tabiques de abajo no estorban arriba y las barandillas de arriba no estorban abajo.
## Paso 3: el agua del río y del lago (grupo «agua_2d») no se copia: el cuerpo 3D entra en ella (vadea o nada). Para los
## vecinos, que aún andan por el mapa, sigue siendo un muro.
## Paso 4b: los vecinos tampoco: tienen su propio cuerpo de contacto (CuerposCercanos3D).
## Paso 2c: las barandillas (Suelo.es_barandilla) llegan a la cintura: se pueden saltar.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Suelo = preload("res://scripts/fisica/Suelo.gd")
const VillageTavern = preload("res://scripts/systems/VillageTavern.gd")

const RADIO_PX: float = 110.0      ## se copian los choques a esta distancia del cuerpo (píxeles del mapa)
const MAX_CHOQUES: int = 256
const BAJO_SUELO_M: float = 1.0    ## los muros empiezan este trozo por debajo del suelo de la calle…
const ALTO_MURO_M: float = 9.0     ## …y suben hasta aquí (dos plantas; no se puede saltar por encima, igual que antes)
const ALTO_PISO_M: float = 4.0     ## lo que sube un choque de la Planta +1 desde su suelo
const ALTO_BARANDILLA_M: float = 1.0 ## las barandillas: a la cintura (se pueden saltar)
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
## del propio actor. `calle_y` = altura 3D del suelo de abajo (la calle o la Planta 0) bajo el cuerpo: los muros se
## levantan desde ahí.
func actualizar(espacio: PhysicsDirectSpaceState2D, centro: Vector2, mascara: int, excluir: Array[RID], calle_y: float) -> void:
	_consulta.transform = Transform2D(0.0, centro)
	_consulta.collision_mask = mascara
	_consulta.exclude = excluir
	var vistos := {}
	for r in espacio.intersect_shape(_consulta, MAX_CHOQUES):
		if r["collider"] is Node and ((r["collider"] as Node).is_in_group("agua_2d") or (r["collider"] as Node).is_in_group("village_npcs")):
			continue
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
		_colocar(copia, rid, idx, calle_y)
	for clave in _copias.keys():
		if not vistos.has(clave):
			(_copias[clave] as Node).queue_free()
			_copias.erase(clave)


func cuantas() -> int:
	return _copias.size()


func _crear_copia(rid: RID, idx: int) -> StaticBody3D:
	var nodo: Object = instance_from_id(PhysicsServer2D.body_get_object_instance_id(rid))
	var banda: Vector2 = _banda(Suelo.piso_de_choque(nodo))
	if Suelo.es_barandilla(nodo):
		banda.y = ALTO_BARANDILLA_M + 0.05
	var forma := _forma_3d(PhysicsServer2D.body_get_shape(rid, idx), banda.y)
	if forma == null:
		return null
	var cuerpo := StaticBody3D.new()
	cuerpo.set_meta("banda", banda)
	var cs := CollisionShape3D.new()
	cs.shape = forma
	cuerpo.add_child(cs)
	add_child(cuerpo)
	return cuerpo


## Coloca la copia donde está ahora el choque del mapa (por si se mueve: vecinos, carros, puertas…).
func _colocar(copia: StaticBody3D, rid: RID, idx: int, calle_y: float) -> void:
	var t2: Transform2D = (PhysicsServer2D.body_get_state(rid, PhysicsServer2D.BODY_STATE_TRANSFORM) as Transform2D) \
		* PhysicsServer2D.body_get_shape_transform(rid, idx)
	var o3 := Mapa3D.a_3d(t2.origin)
	o3.y = calle_y + (copia.get_meta("banda") as Vector2).x
	var x3 := Mapa3D.dir_a_3d(t2.x)
	var z3 := Mapa3D.dir_a_3d(t2.y)
	var t3 := Transform3D(Basis(x3, Vector3.UP, z3), o3)
	if not copia.global_transform.is_equal_approx(t3):
		copia.global_transform = t3


## Desde dónde (x) y cuánto sube (y) un choque de `piso`, en metros sobre el suelo de la calle.
func _banda(piso: int) -> Vector2:
	var planta_1: float = Mapa3D.alto_a_3d(VillageTavern.FLOOR_1_SURFACE_H - VillageTavern.FLOOR_0_SURFACE_H)
	match piso:
		0:
			return Vector2(-BAJO_SUELO_M, planta_1 + BAJO_SUELO_M)
		1:
			return Vector2(planta_1 - 0.05, ALTO_PISO_M)
	return Vector2(-BAJO_SUELO_M, ALTO_MURO_M + BAJO_SUELO_M)


## Forma 2D (del servidor de física) → muro 3D: la misma planta, levantada `alto` metros. Las medidas en metros, con el
## eje «y» del mapa como z del 3D; la base queda en y = 0 local.
func _forma_3d(forma2: RID, alto: float) -> Shape3D:
	var d = PhysicsServer2D.shape_get_data(forma2)
	match PhysicsServer2D.shape_get_type(forma2):
		PhysicsServer2D.SHAPE_RECTANGLE:
			var e: Vector2 = d
			return _prisma(PackedVector2Array([Vector2(-e.x, -e.y), Vector2(e.x, -e.y), Vector2(e.x, e.y), Vector2(-e.x, e.y)]), alto)
		PhysicsServer2D.SHAPE_CIRCLE:
			return _prisma(_circulo_puntos(float(d), Vector2.ZERO), alto)
		PhysicsServer2D.SHAPE_CAPSULE:
			var c: Vector2 = d # (radio, alto total)
			var pts := _circulo_puntos(c.x, Vector2(0, -(c.y * 0.5 - c.x)))
			pts.append_array(_circulo_puntos(c.x, Vector2(0, c.y * 0.5 - c.x)))
			return _prisma(pts, alto)
		PhysicsServer2D.SHAPE_CONVEX_POLYGON:
			return _prisma(d, alto)
		PhysicsServer2D.SHAPE_CONCAVE_POLYGON, PhysicsServer2D.SHAPE_SEGMENT:
			var segs := PackedVector2Array()
			if d is Rect2:
				segs.append((d as Rect2).position)
				segs.append((d as Rect2).size)
			else:
				segs = d
			return _paredes(segs, alto)
	return null


func _circulo_puntos(r: float, c: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(SEGMENTOS_CIRCULO):
		pts.append(c + Vector2.RIGHT.rotated(TAU * i / SEGMENTOS_CIRCULO) * r)
	return pts


func _prisma(pts2: PackedVector2Array, alto: float) -> ConvexPolygonShape3D:
	var pts3 := PackedVector3Array()
	for p in pts2:
		var b := Mapa3D.a_3d(p)
		pts3.append(Vector3(b.x, 0.0, b.z))
		pts3.append(Vector3(b.x, alto, b.z))
	var s := ConvexPolygonShape3D.new()
	s.points = pts3
	return s


## Segmentos sueltos (bordes de polígonos cóncavos): una pared fina por segmento.
func _paredes(segs: PackedVector2Array, h: float) -> ConcavePolygonShape3D:
	var tris := PackedVector3Array()
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
