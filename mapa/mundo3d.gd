@tool
extends Node3D
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Editor del mapa en 3D (Claude Code, 2026-11-10). Ábrelo en Godot (mapa/Mundo3D.tscn) y pulsa «3D» arriba.
## - «Vista» es una maqueta del mundo para orientarse (suelo con relieve, río, lago, caminos, edificios, árboles):
##   se rehace sola al abrir la escena y NO se guarda ni sale en el juego.
## - «Decoracion»: lo que arrastres aquí desde la carpeta «mis_recursos» (o cualquier modelo) aparece en el juego en ese
##   mismo sitio, y es sólido salvo que lo marques como atravesable (Inspector → Metadata → atravesable = true).
## Las coordenadas son las mismas que usa el juego (WorldStageBase3D.to_3d), por eso coincide lo que ves con el juego.

const WB = preload("res://scripts/visuals/WorldStageBase3D.gd")
const FS = preload("res://scripts/obstacles/FishingSpot.gd")
const REFERENCIA := "res://mapa/referencia_mapa.json"
const PASO_SUELO: float = 40.0

## Marca esta casilla para rehacer la maqueta (por ejemplo, después de mover el río en el editor 2D).
@export var regenerar: bool = false:
	set(v):
		regenerar = false
		if v and is_inside_tree():
			_construir()



func _ready() -> void:
	if Engine.is_editor_hint():
		_construir()


## Posición 3D de un punto del mapa 2D a una altura h (en las mismas unidades que el juego).
func a_3d(p: Vector2, h: float) -> Vector3:
	return Mapa3D.a_3d(p, h)


func _construir() -> void:
	var vieja := get_node_or_null("Vista")
	if vieja != null:
		remove_child(vieja)
		vieja.free()
	var vista := Node3D.new()
	vista.name = "Vista"
	add_child(vista) # sin «owner»: no se guarda en la escena
	var ref: Dictionary = {}
	if FileAccess.file_exists(REFERENCIA):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(REFERENCIA))
		if parsed is Dictionary:
			ref = parsed
	# Mapa ×E: la referencia está en el mapa original; el campo abierto se estira E veces y los edificios van a E·centro
	var E: float = Mapa3D.E
	_suelo(vista)
	_rio(vista)
	_poligonos(vista, _escalar_polis(ref.get("caminos", []), E), Color(0.62, 0.52, 0.38), 0.35)
	if ref.get("lago", []) is Array and (ref["lago"] as Array).size() > 2:
		_poligonos(vista, [FS.lake_outline_world()], Color(0.20, 0.45, 0.75), 0.6, true)
	var ed := get_node_or_null("Edificios")
	if ed == null or ed.get_child_count() == 0:
		_edificios(vista, ref.get("edificios", [])) # cajas, solo hasta que existan las fotos de los edificios
	var veg := get_node_or_null("Vegetacion")
	if veg == null or veg.get_child_count() == 0: # con la vegetación en la escena no hacen falta los conos de la referencia
		for t in ref.get("arboles", []):
			_cono(vista, Vector2(t[0], t[1]) * E, 9.0, 46.0, Color(0.18, 0.45, 0.20))
		for r in ref.get("rocas", []):
			_cono(vista, Vector2(r[0], r[1]) * E, 7.0, 8.0, Color(0.5, 0.5, 0.5))
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, 35, 0)
	vista.add_child(luz)


## Polígonos de la referencia (mapa original) estirados E veces.
func _escalar_polis(lista: Array, E: float) -> Array:
	var out: Array = []
	for poly in lista:
		var q: Array = []
		for p in poly:
			q.append([float(p[0]) * E, float(p[1]) * E])
		out.append(q)
	return out


func _mat(c: Color, vertex: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.vertex_color_use_as_albedo = vertex
	m.roughness = 0.95
	return m


## Suelo con el mismo relieve que el juego, con choque para poder soltar modelos encima.
func _suelo(vista: Node3D) -> void:
	var E: float = Mapa3D.E
	var x0 := -2400.0 * E
	var x1 := 2800.0 * E
	var y0 := -2000.0 * E
	var y1 := maxf(2700.0 * E, FS.river_y_end() + 200.0)
	var nx := int((x1 - x0) / PASO_SUELO) + 1
	var ny := int((y1 - y0) / PASO_SUELO) + 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var alturas := PackedFloat32Array()
	alturas.resize(nx * ny)
	for j in range(ny):
		for i in range(nx):
			alturas[j * nx + i] = WB.terrain_height_px(Vector2(x0 + i * PASO_SUELO, y0 + j * PASO_SUELO))
	for j in range(ny - 1):
		for i in range(nx - 1):
			var q: Array[Vector3] = []
			var cols: Array[Color] = []
			for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var h: float = alturas[(j + d.y) * nx + i + d.x]
				q.append(a_3d(Vector2(x0 + (i + d.x) * PASO_SUELO, y0 + (j + d.y) * PASO_SUELO), h))
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


func _rio(vista: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := FS.river_y_start()
	var y_fin := FS.river_y_end()
	while y < y_fin:
		var y2 := minf(y_fin, y + 8.0)
		var b0: Vector2 = FS.river_banks_at(y)
		var b1: Vector2 = FS.river_banks_at(y2)
		var h0: float = WB._river_bank_terrace_height_px(y) + 0.34
		var h1: float = WB._river_bank_terrace_height_px(y2) + 0.34
		var a := a_3d(Vector2(b0.x, y), h0)
		var b := a_3d(Vector2(b0.y, y), h0)
		var c := a_3d(Vector2(b1.y, y2), h1)
		var d := a_3d(Vector2(b1.x, y2), h1)
		for v in [a, b, c, a, c, d]:
			st.add_vertex(v)
		y = y2
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Rio"
	mi.mesh = st.commit()
	mi.material_override = _mat(Color(0.20, 0.45, 0.75))
	vista.add_child(mi)


## Polígonos planos sobre el suelo (caminos, lago). Se triangulan en abanico (son cuadriláteros o figuras convexas).
func _poligonos(vista: Node3D, lista: Array, col: Color, alto: float, plano: bool = false) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for poly in lista:
		if not (poly is Array) or (poly as Array).size() < 3:
			continue
		var pts: PackedVector2Array = PackedVector2Array()
		for p in poly:
			pts.append(Vector2(p[0], p[1]))
		var tri := Geometry2D.triangulate_polygon(pts)
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


func _edificios(vista: Node3D, lista: Array) -> void:
	for e in lista:
		var r: Array = e.get("r", [])
		if r.size() < 4:
			continue
		var centro := Vector2(r[0] + r[2] * 0.5, r[1] + r[3] * 0.5) * Mapa3D.E # mapa ×E: el edificio va a E·centro con su tamaño
		var alto := 40.0
		var base := WB.terrain_height_px(centro)
		var caja := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Mapa3D.tam_a_3d(Vector2(r[2], r[3]), alto)
		caja.mesh = bm
		caja.material_override = _mat(Color(0.55, 0.36, 0.26, 0.85))
		caja.position = a_3d(centro, base + alto * 0.5)
		vista.add_child(caja)
		var nombre := Label3D.new()
		nombre.text = String(e.get("nombre", ""))
		nombre.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		nombre.pixel_size = 0.004 * Mapa3D.K
		nombre.position = a_3d(centro, base + alto + 8.0)
		vista.add_child(nombre)


func _cono(vista: Node3D, p: Vector2, radio: float, alto: float, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = radio * WB.WORLD_SCALE
	cm.height = Mapa3D.alto_a_3d(alto)
	cm.radial_segments = 6
	mi.mesh = cm
	mi.material_override = _mat(col)
	mi.position = a_3d(p, WB.terrain_height_px(p) + alto * 0.5)
	vista.add_child(mi)
