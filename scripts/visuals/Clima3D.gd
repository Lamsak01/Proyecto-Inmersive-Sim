extends Node3D

## Clima 3D del valle (lluvia con gotas y salpicaduras reales en metros).
## Cada columna de agua comprueba las cajas orientadas de los tejados en 3D: bajo techo o bajo tierra no cae ni una gota,
## mientras que por puertas y ventanas abiertas se sigue viendo llover afuera en la calle.

const TOTAL_GOTAS: int = 620
const TOTAL_SALPICADURAS: int = 120
const RADIO_BASE_M: float = 15.0
const ALTURA_COLUMNA_M: float = 15.0
const VELOCIDAD_CAIDA_M_S: float = 14.2
const INCLINACION_VIENTO := Vector3(-0.11, 0.0, 0.06)
const TAM_GOTA := Vector3(0.026, 0.76, 0.026)
const OCULTO_XF := Transform3D(Basis(Vector3(0.0001, 0.0, 0.0), Vector3(0.0, 0.0001, 0.0), Vector3(0.0, 0.0, 0.0001)), Vector3(0.0, -500.0, 0.0))

var _gotas_mmi: MultiMeshInstance3D = null
var _salpicaduras_mmi: MultiMeshInstance3D = null
var _base_gota: Basis = Basis.IDENTITY
var _semillas: PackedFloat32Array = PackedFloat32Array()
var _techos_3d: Array[Dictionary] = []
var _tiempo: float = 0.0


func _ready() -> void:
	name = "Clima3D"
	var eje_y: Vector3 = (Vector3.UP - INCLINACION_VIENTO).normalized()
	var eje_x: Vector3 = eje_y.cross(Vector3.BACK).normalized()
	var eje_z: Vector3 = eje_x.cross(eje_y).normalized()
	_base_gota = Basis(eje_x, eje_y, eje_z)
	_semillas.resize(TOTAL_GOTAS * 3)
	for i: int in range(TOTAL_GOTAS):
		var fi: float = float(i + 1)
		_semillas[i * 3] = fposmod(fi * 0.7548776662 + sin(fi * 12.9898) * 0.17, 1.0)
		_semillas[i * 3 + 1] = fposmod(fi * 0.5698402910 + cos(fi * 78.233) * 0.17, 1.0)
		_semillas[i * 3 + 2] = fposmod(sin(fi * 91.3458) * 47453.5453, 1.0)
	_crear_multimallas()
	visible = false


func _crear_multimallas() -> void:
	var mat_gota := StandardMaterial3D.new()
	mat_gota.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_gota.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_gota.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_gota.albedo_color = Color(0.78, 0.87, 0.96, 0.52)
	var malla_gota := BoxMesh.new()
	malla_gota.size = TAM_GOTA
	malla_gota.material = mat_gota
	var mm_gotas := MultiMesh.new()
	mm_gotas.transform_format = MultiMesh.TRANSFORM_3D
	mm_gotas.mesh = malla_gota
	mm_gotas.instance_count = TOTAL_GOTAS
	_gotas_mmi = MultiMeshInstance3D.new()
	_gotas_mmi.name = "GotasLluvia3D"
	_gotas_mmi.multimesh = mm_gotas
	_gotas_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_gotas_mmi.custom_aabb = AABB(Vector3(-900.0, -60.0, -900.0), Vector3(1800.0, 220.0, 1800.0))
	add_child(_gotas_mmi)

	var mat_salp := StandardMaterial3D.new()
	mat_salp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_salp.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_salp.albedo_color = Color(0.84, 0.92, 0.99, 0.50)
	var malla_salp := CylinderMesh.new()
	malla_salp.top_radius = 0.12
	malla_salp.bottom_radius = 0.16
	malla_salp.height = 0.018
	malla_salp.radial_segments = 6
	malla_salp.material = mat_salp
	var mm_salp := MultiMesh.new()
	mm_salp.transform_format = MultiMesh.TRANSFORM_3D
	mm_salp.mesh = malla_salp
	mm_salp.instance_count = TOTAL_SALPICADURAS
	_salpicaduras_mmi = MultiMeshInstance3D.new()
	_salpicaduras_mmi.name = "Salpicaduras3D"
	_salpicaduras_mmi.multimesh = mm_salp
	_salpicaduras_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_salpicaduras_mmi.custom_aabb = AABB(Vector3(-900.0, -60.0, -900.0), Vector3(1800.0, 220.0, 1800.0))
	add_child(_salpicaduras_mmi)


## Registra los volúmenes 3D cubiertos por tejado (edificios, casas en solares y porches) en metros reales.
## Acumula las transformaciones locales hasta `stage_root_3d` para funcionar incluso antes de entrar al árbol.
func registrar_techos(contenedores: Array[Node3D]) -> void:
	_techos_3d.clear()
	var raiz_escenario := get_parent() as Node3D
	for cont: Node3D in contenedores:
		if not is_instance_valid(cont):
			continue
		for hijo: Node in cont.get_children():
			if not (hijo is Node3D):
				continue
			var edificio := hijo as Node3D
			var xf_edificio: Transform3D = _transform_relativo(edificio, raiz_escenario)
			var nodo_tejado := edificio.get_node_or_null("Tejado") as Node3D
			var nodo_muros := edificio.get_node_or_null("Muros") as Node3D
			var estado := {"ok": false, "caja": AABB()}
			for fuente: Node3D in [nodo_tejado, nodo_muros]:
				if fuente != null:
					estado = _acumular_caja_relativa(fuente, edificio, estado)
			if not bool(estado["ok"]):
				estado = _acumular_caja_relativa(edificio, edificio, estado)
			var caja_local: AABB = estado["caja"] as AABB
			if not bool(estado["ok"]) or caja_local.size.x < 0.8 or caja_local.size.z < 0.8 or caja_local.size.y < 1.2:
				continue
			var techo_y: float = (xf_edificio * Vector3(0.0, caja_local.position.y + caja_local.size.y * 0.82, 0.0)).y
			_techos_3d.append({
				"inv": xf_edificio.affine_inverse(),
				"min_x": caja_local.position.x + 0.06,
				"max_x": caja_local.position.x + caja_local.size.x - 0.06,
				"min_z": caja_local.position.z + 0.06,
				"max_z": caja_local.position.z + caja_local.size.z - 0.06,
				"techo_y": techo_y,
			})


func _transform_relativo(nodo: Node3D, ancestro: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = nodo
	while cur != null and cur != ancestro:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf


func _acumular_caja_relativa(nodo: Node, raiz_edificio: Node3D, estado: Dictionary) -> Dictionary:
	var ok: bool = bool(estado["ok"])
	var caja: AABB = estado["caja"] as AABB
	if nodo is MeshInstance3D:
		var mi := nodo as MeshInstance3D
		if mi.mesh != null:
			var xf_rel: Transform3D = _transform_relativo(mi, raiz_edificio)
			var c_malla: AABB = xf_rel * mi.mesh.get_aabb()
			if not ok:
				caja = c_malla
				ok = true
			else:
				caja = caja.merge(c_malla)
	var nuevo_estado := {"ok": ok, "caja": caja}
	for sub: Node in nodo.get_children():
		nuevo_estado = _acumular_caja_relativa(sub, raiz_edificio, nuevo_estado)
	return nuevo_estado


## Devuelve la altura 3D del tejado sobre `(wx, wz)`, o `INF` si está a cielo abierto.
func altura_techo_en_xz(wx: float, wz: float) -> float:
	var p := Vector3(wx, 0.0, wz)
	var mejor: float = INF
	for t: Dictionary in _techos_3d:
		var loc: Vector3 = (t["inv"] as Transform3D) * p
		if loc.x >= float(t["min_x"]) and loc.x <= float(t["max_x"]) and loc.z >= float(t["min_z"]) and loc.z <= float(t["max_z"]):
			var ty: float = float(t["techo_y"])
			if ty < mejor or mejor == INF:
				mejor = ty
	return mejor


## Indica si un punto 3D (ojos u oídos del jugador) queda resguardado bajo un tejado.
func bajo_techo_en_3d(punto_3d: Vector3) -> bool:
	var ty: float = altura_techo_en_xz(punto_3d.x, punto_3d.z)
	return ty < INF and punto_3d.y < ty + 0.35


func total_techos_registrados() -> int:
	return _techos_3d.size()


func actualizar(delta: float, lloviendo: bool, cam: Camera3D, primera_persona: bool, bajo_tierra: bool, bajo_agua: bool, foco_suelo_3d: Vector3) -> void:
	if not lloviendo or cam == null or bajo_tierra or bajo_agua or _gotas_mmi == null:
		visible = false
		return
	visible = true
	_tiempo += delta
	var centro: Vector3 = foco_suelo_3d
	var radio_m: float = RADIO_BASE_M
	if primera_persona:
		var adelante: Vector3 = -cam.global_transform.basis.z
		adelante.y = 0.0
		if adelante.length_squared() > 0.001:
			adelante = adelante.normalized()
		centro = cam.global_position + adelante * 5.5
		centro.y = foco_suelo_3d.y
	else:
		radio_m = clampf(cam.size * 0.72, RADIO_BASE_M, 38.0)

	var celda: float = radio_m * 2.0
	global_position = centro
	var cam_pos: Vector3 = cam.global_position
	var mm_g: MultiMesh = _gotas_mmi.multimesh
	var mm_s: MultiMesh = _salpicaduras_mmi.multimesh
	for i: int in range(TOTAL_GOTAS):
		var sx: float = _semillas[i * 3]
		var sz: float = _semillas[i * 3 + 1]
		var sf: float = _semillas[i * 3 + 2]
		var caida: float = fmod(_tiempo * VELOCIDAD_CAIDA_M_S + sf * ALTURA_COLUMNA_M, ALTURA_COLUMNA_M)
		var lx: float = fposmod(sx * celda + INCLINACION_VIENTO.x * caida - centro.x + radio_m, celda) - radio_m
		var lz: float = fposmod(sz * celda + INCLINACION_VIENTO.z * caida - centro.z + radio_m, celda) - radio_m
		var ly: float = ALTURA_COLUMNA_M - 1.5 - caida
		var wx: float = centro.x + lx
		var wz: float = centro.z + lz
		var wy: float = centro.y + ly
		var techo_y: float = altura_techo_en_xz(wx, wz)
		var muy_pegada: bool = primera_persona and (Vector3(wx, wy, wz) - cam_pos).length_squared() < 0.75
		if muy_pegada or ly < -0.6 or (techo_y < INF and wy - TAM_GOTA.y * 0.55 < techo_y + 0.40):
			mm_g.set_instance_transform(i, OCULTO_XF)
		else:
			mm_g.set_instance_transform(i, Transform3D(_base_gota, Vector3(lx, ly, lz)))
		if i < TOTAL_SALPICADURAS:
			var pulso: float = fmod(_tiempo * 3.4 + sf * 5.0, 1.0)
			if techo_y < INF:
				mm_s.set_instance_transform(i, OCULTO_XF)
			else:
				var esc: float = lerpf(0.35, 1.35, pulso) * (1.0 - pulso * 0.45)
				var b_salp := Basis(Vector3(esc, 0.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(0.0, 0.0, esc))
				mm_s.set_instance_transform(i, Transform3D(b_salp, Vector3(lx, 0.04, lz)))
