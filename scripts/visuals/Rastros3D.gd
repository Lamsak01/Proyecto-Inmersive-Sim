extends RefCounted

## Rastros del suelo en 3D (2026-11-12): charcos de sangre, huellas ensangrentadas y campamentos de vagabundos.
## Antes solo eran dibujo plano y en primera persona no se veían (malo para investigar). Se leen de los datos del pueblo
## (vm.blood_puddles con sus "footprints", vm.vagrant_camp_nodes) y se rehacen solo cuando cambian.
## Lo llama WorldStageProps3D._sync_dynamic_props_3d.

const COLOR_SANGRE := Color(0.30, 0.02, 0.03)  ## sangre oscura, casi seca
const CHARCO_RADIO_PX: float = 9.0
const CHARCO_GROSOR_PX: float = 0.15     ## una lámina sobre el suelo
## Manchas que se salen del charco [desplazamiento, radio]: así no es un círculo perfecto.
const CHARCO_SALPICONES: Array = [[Vector2(6.0, 3.0), 5.0], [Vector2(-7.0, -2.0), 4.0], [Vector2(2.0, -7.0), 3.0]]
const HUELLA_TAM_PX := Vector2(4.4, 2.4)
const HUELLA_GROSOR_PX: float = 0.1
const HUELLA_TONOS: int = 10             ## materiales de huella según lo reciente (más vieja, más clara)
const SACO_TAM_PX := Vector2(16.0, 7.0)  ## campamento: petate en el suelo
const SACO_ALTO_PX: float = 1.2
const TIENDA_RADIO_PX: float = 10.0      ## lona en pirámide
const TIENDA_ALTO_PX: float = 9.0
const TIENDA_LADOS: int = 4
const TIENDA_DESPLAZ := Vector2(-8.0, -3.0)
const FUEGO_DESPLAZ := Vector2(14.0, 1.0)
const PIEDRAS_RADIO_PX: float = 4.0
const PIEDRAS_ALTO_PX: float = 1.0
const LLAMA_RADIO_PX: float = 2.4
const LLAMA_ALTO_PX: float = 4.0
const LLAMA_BRILLO: float = 2.0

var _raiz: Node3D = null
var _firma: String = ""
var _huellas_mat: Array[StandardMaterial3D] = []


func sincronizar(stage: Node) -> void:
	var vm = stage.get("vm")
	if vm == null:
		return
	var firma: String = _firma_de(vm)
	if firma == _firma and is_instance_valid(_raiz):
		return
	_firma = firma
	var raiz_mundo: Node3D = stage.get("stage_root_3d")
	if raiz_mundo == null:
		return
	if not is_instance_valid(_raiz):
		_raiz = Node3D.new()
		_raiz.name = "Rastros3D"
		raiz_mundo.add_child(_raiz)
	for c in _raiz.get_children():
		c.queue_free()
	var m_charco: Material = stage.call("_mat", "rastro_sangre", COLOR_SANGRE, 0.25, 0.0)
	for pud: Dictionary in vm.blood_puddles:
		var centro: Vector2 = pud.get("pos", Vector2.ZERO)
		stage.call("_add_cyl_2d", _raiz, centro, CHARCO_RADIO_PX, 0.0, CHARCO_GROSOR_PX, m_charco)
		for sal: Array in CHARCO_SALPICONES:
			stage.call("_add_cyl_2d", _raiz, centro + (sal[0] as Vector2), float(sal[1]), 0.0, CHARCO_GROSOR_PX, m_charco)
		for h: Dictionary in (pud.get("footprints", []) as Array):
			var ang: float = float(h.get("angle", 0.0))
			stage.call("_add_box_2d", _raiz, h.get("pos", Vector2.ZERO), HUELLA_TAM_PX, 0.0, HUELLA_GROSOR_PX, _material_huella(float(h.get("alpha", 1.0))), -rad_to_deg(ang))
	for camp in (vm.vagrant_camp_nodes as Dictionary).values():
		if is_instance_valid(camp) and (camp as Node2D).visible:
			_campamento(stage, (camp as Node2D).global_position)


## Cambia si aparece o se limpia un charco, se pisa una huella o se monta/levanta un campamento.
func _firma_de(vm) -> String:
	var huellas: int = 0
	for pud: Dictionary in vm.blood_puddles:
		huellas += (pud.get("footprints", []) as Array).size()
	var camps: PackedStringArray = []
	for camp in (vm.vagrant_camp_nodes as Dictionary).values():
		if is_instance_valid(camp) and (camp as Node2D).visible:
			camps.append(str((camp as Node2D).global_position.round()))
	return "%d|%d|%s" % [vm.blood_puddles.size(), huellas, ",".join(camps)]


func _material_huella(alpha: float) -> StandardMaterial3D:
	if _huellas_mat.is_empty():
		for i in range(HUELLA_TONOS + 1):
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(COLOR_SANGRE, float(i) / float(HUELLA_TONOS))
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.4
			_huellas_mat.append(m)
	return _huellas_mat[clampi(roundi(alpha * HUELLA_TONOS), 0, HUELLA_TONOS)]


## Petate, lona en pirámide y hoguera con su anillo de piedras.
func _campamento(stage: Node, pos: Vector2) -> void:
	var m_saco: Material = stage.call("_mat", "vagabundo_saco", Color(0.45, 0.52, 0.36), 0.95, 0.0)
	var m_lona: Material = stage.call("_mat", "vagabundo_lona", Color(0.56, 0.46, 0.32), 0.92, 0.0)
	var m_piedra: Material = stage.call("_mat", "vagabundo_piedra", Color(0.40, 0.39, 0.37), 0.95, 0.0)
	var m_llama: Material = stage.call("_mat", "vagabundo_llama", Color(1.0, 0.58, 0.18), 0.6, 0.0, Color(1.0, 0.5, 0.15), LLAMA_BRILLO)
	stage.call("_add_box_2d", _raiz, pos, SACO_TAM_PX, 0.0, SACO_ALTO_PX, m_saco)
	stage.call("_add_cyl_2d", _raiz, pos + TIENDA_DESPLAZ, TIENDA_RADIO_PX, 0.0, TIENDA_ALTO_PX, m_lona, 0.0, TIENDA_LADOS)
	stage.call("_add_cyl_2d", _raiz, pos + FUEGO_DESPLAZ, PIEDRAS_RADIO_PX, 0.0, PIEDRAS_ALTO_PX, m_piedra)
	stage.call("_add_cyl_2d", _raiz, pos + FUEGO_DESPLAZ, LLAMA_RADIO_PX, PIEDRAS_ALTO_PX, LLAMA_ALTO_PX, m_llama, 0.0, TIENDA_LADOS)
