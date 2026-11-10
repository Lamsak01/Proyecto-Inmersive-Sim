@tool
extends Node3D

## Tramo de camino en el editor del mapa 3D (mapa/Mundo3D.tscn → «Caminos»), 2026-11-10.
## Muévelo, gíralo (eje vertical) o estíralo con la herramienta de escalar: X = largo, Z = ancho. El juego dibuja el
## camino ahí (en 3D y en el mapa pequeño). Si «Caminos» tiene tramos, el juego deja de dibujar los caminos de siempre.

const ESCENA := "res://mapa/Mundo3D.tscn"
const WORLD_SCALE: float = 0.02
const PITCH_DEG: float = 58.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	for c in get_children():
		if c.has_meta("vista_camino"):
			c.queue_free()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.03, 1.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.52, 0.38)
	bm.material = mat
	mi.mesh = bm
	mi.position.y = 0.02
	mi.set_meta("vista_camino", true)
	add_child(mi) # sin «owner»: no se guarda


## Tramos del editor en el mapa 2D: [{"a": Vector2, "b": Vector2, "ancho": float}] (vacío si no hay «Caminos»).
static var _tramos: Array = []
static var _leido: bool = false


static func tramos() -> Array:
	if _leido:
		return _tramos
	_leido = true
	if not ResourceLoader.exists(ESCENA):
		return _tramos
	var st: SceneState = (load(ESCENA) as PackedScene).get_state()
	var s: float = sin(deg_to_rad(PITCH_DEG))
	var a2 := func(v: Vector3) -> Vector2: return Vector2(v.x / WORLD_SCALE, v.z * s / WORLD_SCALE)
	for i in range(st.get_node_count()):
		if not str(st.get_node_path(i)).begins_with("./Caminos/"):
			continue
		var es_tramo := false
		var xf := Transform3D.IDENTITY
		for j in range(st.get_node_property_count(i)):
			match st.get_node_property_name(i, j):
				"script": es_tramo = true
				"transform": xf = st.get_node_property_value(i, j)
		if not es_tramo:
			continue
		var w2: Vector2 = a2.call(xf.basis.z)
		_tramos.append({"a": a2.call(xf * Vector3(-0.5, 0, 0)), "b": a2.call(xf * Vector3(0.5, 0, 0)), "ancho": w2.length()})
	return _tramos
