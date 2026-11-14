extends RefCounted

## Prismas3D: convierte la forma de un choque del mapa plano en un muro 3D de la misma planta, levantado `alto` metros
## (base en y = 0 local). Lo usa ChoquesMundo3D mientras queden choques que nacen en el mapa plano (paso a 3D, tanda 3a).
## Sin estado y sin preloads de otros sistemas.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

const SEGMENTOS_CIRCULO: int = 12


## Forma 2D (del servidor de física) → forma 3D. Devuelve null si el tipo no se conoce.
static func forma(forma2: RID, alto: float) -> Shape3D:
	var d: Variant = PhysicsServer2D.shape_get_data(forma2)
	match PhysicsServer2D.shape_get_type(forma2):
		PhysicsServer2D.SHAPE_RECTANGLE:
			var e: Vector2 = d
			return _prisma(PackedVector2Array([Vector2(-e.x, -e.y), Vector2(e.x, -e.y), Vector2(e.x, e.y), Vector2(-e.x, e.y)]), alto)
		PhysicsServer2D.SHAPE_CIRCLE:
			return _prisma(_circulo(float(d), Vector2.ZERO), alto)
		PhysicsServer2D.SHAPE_CAPSULE:
			var c: Vector2 = d # (radio, alto total)
			var pts: PackedVector2Array = _circulo(c.x, Vector2(0.0, -(c.y * 0.5 - c.x)))
			pts.append_array(_circulo(c.x, Vector2(0.0, c.y * 0.5 - c.x)))
			return _prisma(pts, alto)
		PhysicsServer2D.SHAPE_CONVEX_POLYGON:
			return _prisma(d, alto)
		PhysicsServer2D.SHAPE_CONCAVE_POLYGON, PhysicsServer2D.SHAPE_SEGMENT:
			return _paredes(_segmentos(d), alto)
	return null


## Punto del mapa que representa a la forma (para saber a qué altura está su suelo): su centro, o el centro de sus
## puntos si es un polígono suelto (el agua del río es un solo choque con el origen lejos de la orilla).
static func centro(forma2: RID) -> Vector2:
	var d: Variant = PhysicsServer2D.shape_get_data(forma2)
	var pts := PackedVector2Array()
	match PhysicsServer2D.shape_get_type(forma2):
		PhysicsServer2D.SHAPE_CONVEX_POLYGON:
			pts = d
		PhysicsServer2D.SHAPE_CONCAVE_POLYGON, PhysicsServer2D.SHAPE_SEGMENT:
			pts = _segmentos(d)
	if pts.is_empty():
		return Vector2.ZERO
	var suma := Vector2.ZERO
	for p in pts:
		suma += p
	return suma / float(pts.size())


static func _segmentos(d: Variant) -> PackedVector2Array:
	if d is Rect2: # un solo segmento llega como (origen, fin)
		return PackedVector2Array([(d as Rect2).position, (d as Rect2).size])
	return d


static func _circulo(r: float, c: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(SEGMENTOS_CIRCULO):
		pts.append(c + Vector2.RIGHT.rotated(TAU * i / SEGMENTOS_CIRCULO) * r)
	return pts


static func _prisma(pts2: PackedVector2Array, alto: float) -> ConvexPolygonShape3D:
	var pts3 := PackedVector3Array()
	for p in pts2:
		var b: Vector3 = Mapa3D.a_3d(p)
		pts3.append(Vector3(b.x, 0.0, b.z))
		pts3.append(Vector3(b.x, alto, b.z))
	var s := ConvexPolygonShape3D.new()
	s.points = pts3
	return s


## Segmentos sueltos (bordes de polígonos cóncavos): una pared fina por segmento.
static func _paredes(segs: PackedVector2Array, alto: float) -> ConcavePolygonShape3D:
	var tris := PackedVector3Array()
	for i in range(0, segs.size() - 1, 2):
		var a: Vector3 = Mapa3D.a_3d(segs[i])
		var b: Vector3 = Mapa3D.a_3d(segs[i + 1])
		var a1: Vector3 = a + Vector3(0.0, alto, 0.0)
		var b1: Vector3 = b + Vector3(0.0, alto, 0.0)
		tris.append_array([a, b, b1, a, b1, a1])
	var s := ConcavePolygonShape3D.new()
	s.backface_collision = true
	s.set_faces(tris)
	return s
