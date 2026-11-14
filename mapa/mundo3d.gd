@tool
extends Node3D
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Editor del mapa en 3D (mapa/Mundo3D.tscn). Ábrelo en Godot y pulsa «3D» arriba.
## - «Vista» es una maqueta del mundo para orientarse (suelo con relieve, río, lago y plaza):
##   se rehace sola al abrir la escena y NO se guarda ni sale en el juego.
## - «Decoracion»: lo que arrastres aquí aparece en el juego en ese mismo sitio, y es sólido salvo que lo marques
##   como atravesable (Inspector → Metadata → atravesable = true).

const WB = preload("res://scripts/visuals/WorldStageBase3D.gd")
const FS = preload("res://scripts/fisica/RioLago.gd")
const TERRENO := "res://scripts/visuals/WorldStageTerrain3D.gd"
const COLOR_CAMINO := Color(0.62, 0.52, 0.38)
const PASO_SUELO: float = 40.0
const SOL_GIRO := Vector3(-50.0, 35.0, 0.0)
const SOL_FUERZA: float = 1.3
const LUZ_AMBIENTE: float = 0.8
const CIELO_ARRIBA := Color(0.36, 0.54, 0.80)
const CIELO_HORIZONTE := Color(0.72, 0.80, 0.88)

## Marca esta casilla para rehacer la maqueta (por ejemplo, para que el suelo siga al río tras moverlo en «Rio»).
@export var regenerar: bool = false:
	set(v):
		regenerar = false
		if v and is_inside_tree():
			_construir()


func _ready() -> void:
	if Engine.is_editor_hint():
		_construir()


## Posición 3D de un punto del mundo a una altura h.
func a_3d(p: Vector2, h: float) -> Vector3:
	return Mapa3D.a_3d(p, h)


func _construir() -> void:
	var vieja: Node = get_node_or_null("Vista")
	if vieja != null:
		remove_child(vieja)
		vieja.free()
	var vista := Node3D.new()
	vista.name = "Vista"
	add_child(vista)
	_suelo(vista)
	_rio(vista)
	_poligonos(vista, [_plaza()], COLOR_CAMINO, 0.35)
	_poligonos(vista, [FS.lake_outline_world()], Color(0.20, 0.45, 0.75), 0.6, true)
	_luz_y_cielo(vista)


## Sol y cielo solo para el editor (dentro de «Vista»: no se guardan ni salen en el juego).
func _luz_y_cielo(vista: Node3D) -> void:
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = SOL_GIRO
	luz.light_energy = SOL_FUERZA
	vista.add_child(luz)
	var cielo := ProceduralSkyMaterial.new()
	cielo.sky_top_color = CIELO_ARRIBA
	cielo.sky_horizon_color = CIELO_HORIZONTE
	cielo.ground_horizon_color = CIELO_HORIZONTE
	cielo.ground_bottom_color = CIELO_HORIZONTE
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = cielo
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = LUZ_AMBIENTE
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	vista.add_child(we)


## Plaza Central en coordenadas reales del mundo (sigue a su pieza en «Zonas»).
func _plaza() -> PackedVector2Array:
	var r: Rect2 = load(TERRENO).plaza_rect_mundo()
	return PackedVector2Array([
		r.position,
		Vector2(r.end.x, r.position.y),
		r.end,
		Vector2(r.position.x, r.end.y),
	])


func _mat(c: Color, vertex: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.vertex_color_use_as_albedo = vertex
	m.roughness = 0.95
	return m


## Suelo con el mismo relieve que el juego, con choque para poder soltar modelos encima.
func _suelo(vista: Node3D) -> void:
	var x0: float = -12000.0
	var x1: float = 14000.0
	var y0: float = -10000.0
	var y1: float = maxf(13500.0, FS.river_y_end() + 200.0)
	var nx: int = int((x1 - x0) / PASO_SUELO) + 1
	var ny: int = int((y1 - y0) / PASO_SUELO) + 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var alturas := PackedFloat32Array()
	alturas.resize(nx * ny)
	for j in range(ny):
		for i in range(nx):
			alturas[j * nx + i] = WB.terrain_height_px(Vector2(x0 + float(i) * PASO_SUELO, y0 + float(j) * PASO_SUELO))
	for j in range(ny - 1):
		for i in range(nx - 1):
			var q: Array[Vector3] = []
			var cols: Array[Color] = []
			for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var h: float = alturas[(j + d.y) * nx + i + d.x]
				q.append(a_3d(Vector2(x0 + float(i + d.x) * PASO_SUELO, y0 + float(j + d.y) * PASO_SUELO), h))
				cols.append(Color(0.30, 0.46, 0.22).lerp(Color(0.42, 0.40, 0.28), clampf(h / 14.0, 0.0, 1.0)))
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_color(cols[k])
				st.add_vertex(q[k])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Suelo"
	mi.mesh = st.commit()
	mi.material_override = _mat(Color.WHITE, true)
	vista.add_child(mi)
	mi.create_trimesh_collision()


## El río de la maqueta otra vez (lo pide mapa/rio.gd al mover un punto o un puente); el suelo no se rehace (tarda).
func rehacer_rio() -> void:
	var vista: Node3D = get_node_or_null("Vista")
	if vista == null:
		return
	var viejo: Node = vista.get_node_or_null("Rio")
	if viejo != null:
		vista.remove_child(viejo)
		viejo.free()
	_rio(vista)


func _rio(vista: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y: float = FS.river_y_start()
	var y_fin: float = FS.river_y_end()
	while y < y_fin:
		var y2: float = minf(y_fin, y + 8.0)
		var b0: Vector2 = FS.river_banks_at(y)
		var b1: Vector2 = FS.river_banks_at(y2)
		var h0: float = WB._river_bank_terrace_height_px(y) + 0.34
		var h1: float = WB._river_bank_terrace_height_px(y2) + 0.34
		var a: Vector3 = a_3d(Vector2(b0.x, y), h0)
		var b: Vector3 = a_3d(Vector2(b0.y, y), h0)
		var c: Vector3 = a_3d(Vector2(b1.y, y2), h1)
		var d: Vector3 = a_3d(Vector2(b1.x, y2), h1)
		for v in [a, b, c, a, c, d]:
			st.add_vertex(v)
		y = y2
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Rio"
	mi.mesh = st.commit()
	mi.material_override = _mat(Color(0.20, 0.45, 0.75))
	vista.add_child(mi)


## Polígonos planos sobre el suelo (plaza, lago) en coordenadas reales del mundo.
func _poligonos(vista: Node3D, lista: Array, col: Color, alto: float, plano: bool = false) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for poly in lista:
		var pts := PackedVector2Array(poly)
		if pts.size() < 3:
			continue
		var tri: PackedInt32Array = Geometry2D.triangulate_polygon(pts)
		for idx in tri:
			var p2: Vector2 = pts[idx]
			var h: float = 0.0 if plano else WB.terrain_height_px(p2)
			st.add_vertex(a_3d(p2, h + alto))
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _mat(col)
	mi.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	vista.add_child(mi)
