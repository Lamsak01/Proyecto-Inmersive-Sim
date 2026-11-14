extends RefCounted

## Ayudante en metros para las herramientas de horneado (tools/hornear_*.gd), 2026-11-14:
## convierte una sola vez las piezas escritas antes por código a nodos 3D reales con nombre,
## texturas pixeladas del proyecto, luces y modelos de mapa/pieza.gd.

const ESCALA: float = 0.056
const ALTO: float = ESCALA / 0.5299192642332049
const K: float = ESCALA / 0.02
const PROFUNDIDAD_SOTANO_PX: float = -30.0
const CURATED: String = "res://assests/curated_3d/"
const ESCALA_TEX_PUEBLO: float = 0.42

static var _cache_mat: Dictionary = {}


static func mat(clave: String, col: Color, rugosidad: float = 0.82, metal: float = 0.05, emit_col: Color = Color(0.0, 0.0, 0.0, 0.0), emit_e: float = 0.0, tex_rel: String = "", norm_rel: String = "", escala_trip: float = 0.65) -> StandardMaterial3D:
	if _cache_mat.has(clave):
		return _cache_mat[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rugosidad
	m.metallic = metal
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	if not tex_rel.is_empty():
		var tex := load(CURATED + tex_rel) as Texture2D
		if tex != null:
			m.albedo_texture = tex
			m.albedo_color = col.lerp(Color.WHITE, 0.55)
			m.uv1_triplanar = true
			var ts: float = (ESCALA_TEX_PUEBLO if tex_rel.begins_with("town_textures/") else escala_trip) / K
			m.uv1_scale = Vector3(ts, ts, ts)
		if not norm_rel.is_empty():
			var ntex := load(CURATED + norm_rel) as Texture2D
			if ntex != null:
				m.normal_enabled = true
				m.normal_texture = ntex
				m.normal_scale = 0.75
	if col.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit_e > 0.0:
		m.emission_enabled = true
		m.emission = emit_col
		m.emission_energy_multiplier = emit_e
	_cache_mat[clave] = m
	return m


static func tam_m(tam_px: Vector2, alto_px: float) -> Vector3:
	return Vector3(tam_px.x * ESCALA, alto_px * ALTO, tam_px.y * ESCALA).max(Vector3(0.02, 0.01, 0.02) * K)

static func pos_m(pos_px: Vector2, alto_px: float) -> Vector3:
	return Vector3(pos_px.x * ESCALA, alto_px * ALTO, pos_px.y * ESCALA)

static func grupo(padre: Node3D, nombre: String, pos_px: Vector2 = Vector2.ZERO, alto_px: float = 0.0) -> Node3D:
	var n := Node3D.new()
	n.name = nombre
	n.position = pos_m(pos_px, alto_px)
	padre.add_child(n, true)
	return n


static func caja(padre: Node3D, nombre: String, pos_px: Vector2, tam_px: Vector2, base_px: float, alto_px: float, material: Material, giro_y: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nombre
	var bm := BoxMesh.new()
	bm.size = tam_m(tam_px, alto_px)
	mi.mesh = bm
	mi.material_override = material
	mi.position = pos_m(pos_px, base_px + alto_px * 0.5)
	if absf(giro_y) > 0.01:
		mi.rotation_degrees.y = giro_y
	padre.add_child(mi, true)
	return mi


static func cilindro(padre: Node3D, nombre: String, pos_px: Vector2, radio_px: float, base_px: float, alto_px: float, material: Material, radio_sup_px: float = -1.0, segs: int = 12) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nombre
	var cm := CylinderMesh.new()
	cm.bottom_radius = maxf(0.01, radio_px * ESCALA)
	cm.top_radius = maxf(0.0, (radio_px if radio_sup_px < 0.0 else radio_sup_px) * ESCALA)
	cm.height = maxf(0.01, alto_px * ALTO)
	cm.radial_segments = segs
	mi.mesh = cm
	mi.material_override = material
	mi.position = pos_m(pos_px, base_px + alto_px * 0.5)
	padre.add_child(mi, true)
	return mi


static func prisma(padre: Node3D, nombre: String, pos_px: Vector2, tam_px: Vector2, base_px: float, alto_px: float, material: Material, cumbrera_x: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nombre
	var pm := PrismMesh.new()
	var s3: Vector3 = tam_m(tam_px, alto_px)
	pm.size = Vector3(s3.z, s3.y, s3.x) if cumbrera_x else s3
	if cumbrera_x:
		mi.rotation_degrees.y = 90.0
	mi.mesh = pm
	mi.material_override = material
	mi.position = pos_m(pos_px, base_px + alto_px * 0.5)
	padre.add_child(mi, true)
	return mi


static func modelo(padre: Node3D, nombre: String, ruta_rel: String, pos_px: Vector2, base_px: float, tam_px: Vector2, alto_px: float, giro_y: float = 0.0) -> Node3D:
	var n := Node3D.new()
	n.set_script(load("res://mapa/pieza.gd"))
	n.name = nombre
	n.position = pos_m(pos_px, base_px)
	n.rotation_degrees.y = giro_y
	n.set("choque", "ninguno")
	n.set("tam", tam_px)
	n.set("alto", alto_px)
	n.set("modelo", ruta_rel)
	padre.add_child(n, true)
	return n


static func luz_omni(padre: Node3D, nombre: String, pos_px: Vector2, alto_px: float, color: Color, energia: float, alcance_viejo: float) -> OmniLight3D:
	var lt := OmniLight3D.new()
	lt.name = nombre
	lt.position = pos_m(pos_px, alto_px)
	lt.light_color = color
	lt.light_energy = energia
	lt.omni_range = alcance_viejo * K
	padre.add_child(lt, true)
	return lt


static func guardar_escena(raiz: Node3D, ruta: String) -> Error:
	_dar_dueno(raiz, raiz)
	var ps := PackedScene.new()
	var err: Error = ps.pack(raiz)
	if err == OK:
		err = ResourceSaver.save(ps, ruta)
	return err

static func _dar_dueno(nodo: Node, dueno: Node) -> void:
	for c: Node in nodo.get_children():
		if c.has_meta("pieza_modelo"):
			continue
		c.owner = dueno
		if c.scene_file_path.is_empty():
			_dar_dueno(c, dueno)
