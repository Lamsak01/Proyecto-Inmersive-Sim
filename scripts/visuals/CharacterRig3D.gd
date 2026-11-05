@tool
extends Node3D

## Maqueta 3D Articulada ("Greybox / Low-Poly Figurine") para Jugador y Vecinos — Fase 1 (Transición 3D)
## Construye un muñeco 3D completo por piezas con articulaciones reales:
## - Cabeza (ojos, cejas expresivas, peinado según género/edad, barba y conector de cascos/sombreros de oficio).
## - Torso (túnica, delantal de oficio, cinturón, capa física y peto/hombreras de armadura por nivel).
## - Brazos izquierdo y derecho articulados (hombro, codo, mano, conector de armas/herramientas/farol/escudo, y soporte de amputación o prótesis mecánica de hierro y cobre).
## - Piernas izquierda y derecha articuladas (cadera, muslo, espinilla con grebas, botas y soporte de amputación con muleta o prótesis mecánica articulada).

var root_pivot: Node3D = null
var hips_pivot: Node3D = null
var torso_pivot: Node3D = null
var head_pivot: Node3D = null
var left_shoulder_pivot: Node3D = null
var left_forearm_pivot: Node3D = null
var right_shoulder_pivot: Node3D = null
var right_forearm_pivot: Node3D = null
var left_hip_pivot: Node3D = null
var right_hip_pivot: Node3D = null

var right_hand_socket: Node3D = null
var left_hand_socket: Node3D = null
var head_socket: Node3D = null
var cape_pivot: Node3D = null

# Nodos de anatomía / prótesis / amputación
var left_arm_natural: Node3D = null
var left_arm_prosthetic: Node3D = null
var left_arm_stump: Node3D = null
var right_arm_natural: Node3D = null
var right_arm_prosthetic: Node3D = null
var right_arm_stump: Node3D = null

var left_leg_natural: Node3D = null
var left_leg_prosthetic: Node3D = null
var left_leg_stump: Node3D = null
var right_leg_natural: Node3D = null
var right_leg_prosthetic: Node3D = null
var right_leg_stump: Node3D = null

# Nodos de armadura y vestimenta
var chest_mesh: MeshInstance3D = null
var pelvis_mesh: MeshInstance3D = null
var skirt_mesh: MeshInstance3D = null
var apron_mesh: MeshInstance3D = null
var cape_mesh: MeshInstance3D = null
var chest_armor_root: Node3D = null
var left_pauldron_mesh: MeshInstance3D = null
var right_pauldron_mesh: MeshInstance3D = null
var left_greave_mesh: MeshInstance3D = null
var right_greave_mesh: MeshInstance3D = null
var left_boot_mesh: MeshInstance3D = null
var right_boot_mesh: MeshInstance3D = null

# Nodos faciales y cabello
var head_mesh: MeshInstance3D = null
var left_brow_mesh: MeshInstance3D = null
var right_brow_mesh: MeshInstance3D = null
var hair_top_mesh: MeshInstance3D = null
var hair_back_mesh: MeshInstance3D = null
var hair_bun_mesh: MeshInstance3D = null
var beard_mesh: MeshInstance3D = null

# Diccionario de modelos 3D de armas/herramientas y sombreros
var _weapon_models: Dictionary = {}
var _offhand_models: Dictionary = {}
var _headgear_models: Dictionary = {}

# Efectos de disparo de arcabuz (fogonazo y humo 3D)
var _muzzle_flash_node: Node3D = null
var _smoke_puff_nodes: Array[MeshInstance3D] = []
var _muzzle_flash_timer: float = 0.0

# Materiales reutilizables por instancia
var _mat_skin: StandardMaterial3D = null
var _mat_hair: StandardMaterial3D = null
var _mat_tunic: StandardMaterial3D = null
var _mat_pants: StandardMaterial3D = null
var _mat_apron: StandardMaterial3D = null
var _mat_cape: StandardMaterial3D = null
var _mat_boots: StandardMaterial3D = null
var _mat_chest_armor: StandardMaterial3D = null
var _mat_leg_armor: StandardMaterial3D = null
var _mat_weapon_metal: StandardMaterial3D = null

# Estado de animación
var _anim_clock: float = 0.0
var _walk_cycle: float = 0.0
var _current_yaw: float = 0.0
var _target_yaw: float = 0.0
var _active_weapon_key: String = "none"
var _active_offhand_key: String = "none"
var _active_headgear_key: String = "none"
var _bow_draw_ratio: float = 0.0
var _attack_swing_timer: float = 0.0
var _attack_swing_duration: float = 0.32
var _is_built: bool = false

func _ready() -> void:
	_ensure_built()

func _ensure_built() -> void:
	if _is_built:
		return
	_is_built = true
	_init_materials()
	_build_skeleton_and_body()
	_build_headgear_catalog()
	_build_weapon_and_tool_catalog()
	_build_offhand_catalog()

func _make_mat(col: Color, rough: float = 0.72, metal: float = 0.0, emission_col: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if col.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = emission_col
		m.emission_energy_multiplier = emission_energy
	return m

func _init_materials() -> void:
	_mat_skin = _make_mat(Color(0.93, 0.76, 0.63), 0.78, 0.0)
	_mat_hair = _make_mat(Color(0.26, 0.17, 0.11), 0.85, 0.0)
	_mat_tunic = _make_mat(Color(0.28, 0.46, 0.68), 0.80, 0.0)
	_mat_pants = _make_mat(Color(0.24, 0.22, 0.20), 0.85, 0.0)
	_mat_apron = _make_mat(Color(0.55, 0.36, 0.20), 0.78, 0.05)
	_mat_cape = _make_mat(Color(0.58, 0.16, 0.18), 0.82, 0.0)
	_mat_boots = _make_mat(Color(0.22, 0.15, 0.10), 0.75, 0.08)
	_mat_chest_armor = _make_mat(Color(0.72, 0.76, 0.82), 0.35, 0.72)
	_mat_leg_armor = _make_mat(Color(0.68, 0.72, 0.78), 0.38, 0.68)
	_mat_weapon_metal = _make_mat(Color(0.80, 0.84, 0.90), 0.28, 0.82)

func _add_box(parent: Node3D, sz: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _add_cyl(parent: Node3D, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	cm.radial_segments = 14
	cm.rings = 1
	mi.mesh = cm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _add_sphere(parent: Node3D, r: float, h: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = h
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _build_skeleton_and_body() -> void:
	# Sombra suave en el suelo
	var mat_shadow := _make_mat(Color(0.04, 0.05, 0.07, 0.42), 1.0, 0.0)
	_add_cyl(self, 0.36, 0.36, 0.015, Vector3(0.0, 0.008, 0.0), mat_shadow)

	root_pivot = Node3D.new()
	root_pivot.name = "RootPivot"
	add_child(root_pivot)

	hips_pivot = Node3D.new()
	hips_pivot.name = "HipsPivot"
	hips_pivot.position = Vector3(0.0, 0.58, 0.0)
	root_pivot.add_child(hips_pivot)

	pelvis_mesh = _add_cyl(hips_pivot, 0.19, 0.18, 0.18, Vector3(0.0, 0.0, 0.0), _mat_pants)
	skirt_mesh = _add_cyl(hips_pivot, 0.18, 0.29, 0.36, Vector3(0.0, -0.14, 0.0), _mat_tunic)
	skirt_mesh.visible = false

	# Pierna Izquierda y Derecha
	left_hip_pivot = Node3D.new()
	left_hip_pivot.name = "LeftHipPivot"
	left_hip_pivot.position = Vector3(-0.11, -0.02, 0.0)
	hips_pivot.add_child(left_hip_pivot)
	_build_leg_hierarchy(left_hip_pivot, true)

	right_hip_pivot = Node3D.new()
	right_hip_pivot.name = "RightHipPivot"
	right_hip_pivot.position = Vector3(0.11, -0.02, 0.0)
	hips_pivot.add_child(right_hip_pivot)
	_build_leg_hierarchy(right_hip_pivot, false)

	# Torso
	torso_pivot = Node3D.new()
	torso_pivot.name = "TorsoPivot"
	torso_pivot.position = Vector3(0.0, 0.06, 0.0)
	hips_pivot.add_child(torso_pivot)

	chest_mesh = _add_cyl(torso_pivot, 0.22, 0.18, 0.44, Vector3(0.0, 0.22, 0.0), _mat_tunic)
	# Cinturón con hebilla de latón
	var mat_belt := _make_mat(Color(0.24, 0.15, 0.08), 0.70, 0.10)
	var mat_gold := _make_mat(Color(0.92, 0.76, 0.28), 0.32, 0.82)
	_add_cyl(torso_pivot, 0.195, 0.195, 0.07, Vector3(0.0, 0.04, 0.0), mat_belt)
	_add_box(torso_pivot, Vector3(0.09, 0.08, 0.04), Vector3(0.0, 0.04, 0.19), mat_gold)

	# Delantal de oficio (herrero, carnicero, carpintero, panadero, arreglador)
	apron_mesh = _add_box(torso_pivot, Vector3(0.30, 0.44, 0.04), Vector3(0.0, 0.12, 0.19), _mat_apron)
	apron_mesh.visible = false

	# Capa en la espalda (noble, inquisidor, explorador)
	cape_pivot = Node3D.new()
	cape_pivot.name = "CapePivot"
	cape_pivot.position = Vector3(0.0, 0.42, -0.18)
	torso_pivot.add_child(cape_pivot)
	cape_mesh = _add_box(cape_pivot, Vector3(0.42, 0.62, 0.035), Vector3(0.0, -0.30, -0.04), _mat_cape, Vector3(10.0, 0.0, 0.0))
	cape_mesh.visible = false

	# Armadura de pecho y hombreras
	chest_armor_root = Node3D.new()
	chest_armor_root.name = "ChestArmorRoot"
	chest_armor_root.visible = false
	torso_pivot.add_child(chest_armor_root)
	_add_cyl(chest_armor_root, 0.24, 0.20, 0.38, Vector3(0.0, 0.24, 0.0), _mat_chest_armor)
	_add_box(chest_armor_root, Vector3(0.26, 0.28, 0.10), Vector3(0.0, 0.25, 0.16), _mat_chest_armor)
	left_pauldron_mesh = _add_sphere(chest_armor_root, 0.13, 0.22, Vector3(-0.27, 0.39, 0.0), _mat_chest_armor)
	right_pauldron_mesh = _add_sphere(chest_armor_root, 0.13, 0.22, Vector3(0.27, 0.39, 0.0), _mat_chest_armor)

	# Cabeza
	head_pivot = Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0.0, 0.45, 0.0)
	torso_pivot.add_child(head_pivot)

	_add_cyl(head_pivot, 0.08, 0.09, 0.10, Vector3(0.0, 0.04, 0.0), _mat_skin)
	head_mesh = _add_sphere(head_pivot, 0.23, 0.45, Vector3(0.0, 0.24, 0.0), _mat_skin)
	# Nariz y orejas
	_add_sphere(head_pivot, 0.036, 0.07, Vector3(0.0, 0.22, 0.23), _mat_skin)
	_add_sphere(head_pivot, 0.045, 0.09, Vector3(-0.22, 0.23, 0.0), _mat_skin)
	_add_sphere(head_pivot, 0.045, 0.09, Vector3(0.22, 0.23, 0.0), _mat_skin)

	# Ojos con brillo y cejas
	var mat_eye := _make_mat(Color(0.08, 0.09, 0.12), 0.15, 0.1)
	var mat_shine := _make_mat(Color(1.0, 1.0, 1.0), 0.0, 0.0, Color.WHITE, 0.6)
	_add_sphere(head_pivot, 0.034, 0.068, Vector3(-0.085, 0.25, 0.205), mat_eye)
	_add_sphere(head_pivot, 0.034, 0.068, Vector3(0.085, 0.25, 0.205), mat_eye)
	_add_sphere(head_pivot, 0.012, 0.024, Vector3(-0.075, 0.262, 0.232), mat_shine)
	_add_sphere(head_pivot, 0.012, 0.024, Vector3(0.095, 0.262, 0.232), mat_shine)

	left_brow_mesh = _add_box(head_pivot, Vector3(0.075, 0.022, 0.025), Vector3(-0.085, 0.305, 0.21), _mat_hair)
	right_brow_mesh = _add_box(head_pivot, Vector3(0.075, 0.022, 0.025), Vector3(0.085, 0.305, 0.21), _mat_hair)

	# Cabello y barba
	hair_top_mesh = _add_sphere(head_pivot, 0.242, 0.32, Vector3(0.0, 0.31, -0.015), _mat_hair)
	hair_back_mesh = _add_box(head_pivot, Vector3(0.42, 0.24, 0.16), Vector3(0.0, 0.22, -0.15), _mat_hair)
	hair_bun_mesh = _add_sphere(head_pivot, 0.11, 0.20, Vector3(0.0, 0.26, -0.26), _mat_hair)
	hair_bun_mesh.visible = false
	beard_mesh = _add_Box_Beard(head_pivot)
	beard_mesh.visible = false

	# Conector de Sombreros y Cascos
	head_socket = Node3D.new()
	head_socket.name = "HeadSocket"
	head_socket.position = Vector3(0.0, 0.38, 0.0)
	head_pivot.add_child(head_socket)

	# Brazos articulados
	left_shoulder_pivot = Node3D.new()
	left_shoulder_pivot.name = "LeftShoulderPivot"
	left_shoulder_pivot.position = Vector3(-0.27, 0.38, 0.0)
	torso_pivot.add_child(left_shoulder_pivot)
	_build_arm_hierarchy(left_shoulder_pivot, true)

	right_shoulder_pivot = Node3D.new()
	right_shoulder_pivot.name = "RightShoulderPivot"
	right_shoulder_pivot.position = Vector3(0.27, 0.38, 0.0)
	torso_pivot.add_child(right_shoulder_pivot)
	_build_arm_hierarchy(right_shoulder_pivot, false)

func _add_Box_Beard(parent: Node3D) -> MeshInstance3D:
	return _add_box(parent, Vector3(0.28, 0.16, 0.16), Vector3(0.0, 0.13, 0.15), _mat_hair)

func _build_leg_hierarchy(hip_pivot: Node3D, is_left: bool) -> void:
	var nat := Node3D.new()
	nat.name = "NaturalLeg"
	hip_pivot.add_child(nat)
	_add_cyl(nat, 0.082, 0.072, 0.26, Vector3(0.0, -0.13, 0.0), _mat_pants)
	_add_cyl(nat, 0.070, 0.062, 0.24, Vector3(0.0, -0.35, 0.0), _mat_pants)
	var greave := _add_box(nat, Vector3(0.13, 0.24, 0.09), Vector3(0.0, -0.32, 0.04), _mat_leg_armor)
	greave.visible = false
	var boot := _add_box(nat, Vector3(0.14, 0.12, 0.23), Vector3(0.0, -0.50, 0.035), _mat_boots)

	# Prótesis mecánica de pierna (hierro forjado, pistón de latón y resorte de cobre)
	var prost := Node3D.new()
	prost.name = "ProstheticLeg"
	prost.visible = false
	hip_pivot.add_child(prost)
	var mat_iron := _make_mat(Color(0.32, 0.35, 0.40), 0.35, 0.85)
	var mat_copper := _make_mat(Color(0.85, 0.48, 0.24), 0.30, 0.88, Color(0.85, 0.45, 0.20), 0.15)
	var mat_leather := _make_mat(Color(0.42, 0.25, 0.14), 0.75, 0.1)
	_add_cyl(prost, 0.085, 0.075, 0.16, Vector3(0.0, -0.09, 0.0), mat_leather)
	_add_sphere(prost, 0.075, 0.15, Vector3(0.0, -0.22, 0.0), mat_copper)
	_add_cyl(prost, 0.042, 0.038, 0.26, Vector3(0.0, -0.36, 0.0), mat_iron)
	_add_box(prost, Vector3(0.13, 0.07, 0.24), Vector3(0.0, -0.52, 0.04), mat_iron)

	# Muñón vendado (amputación sin prótesis)
	var stump := Node3D.new()
	stump.name = "StumpLeg"
	stump.visible = false
	hip_pivot.add_child(stump)
	var mat_bandage := _make_mat(Color(0.92, 0.89, 0.82), 0.90, 0.0)
	_add_cyl(stump, 0.082, 0.072, 0.20, Vector3(0.0, -0.10, 0.0), _mat_pants)
	_add_sphere(stump, 0.078, 0.14, Vector3(0.0, -0.21, 0.0), mat_bandage)

	if is_left:
		left_leg_natural = nat
		left_leg_prosthetic = prost
		left_leg_stump = stump
		left_greave_mesh = greave
		left_boot_mesh = boot
	else:
		right_leg_natural = nat
		right_leg_prosthetic = prost
		right_leg_stump = stump
		right_greave_mesh = greave
		right_boot_mesh = boot

func _build_arm_hierarchy(shoulder_pivot: Node3D, is_left: bool) -> void:
	var nat := Node3D.new()
	nat.name = "NaturalArm"
	shoulder_pivot.add_child(nat)
	_add_cyl(nat, 0.072, 0.064, 0.22, Vector3(0.0, -0.10, 0.0), _mat_tunic)

	var forearm_piv := Node3D.new()
	forearm_piv.name = "ForearmPivot"
	forearm_piv.position = Vector3(0.0, -0.21, 0.0)
	shoulder_pivot.add_child(forearm_piv)

	_add_cyl(forearm_piv, 0.060, 0.052, 0.20, Vector3(0.0, -0.09, 0.0), _mat_skin)
	_add_sphere(forearm_piv, 0.065, 0.13, Vector3(0.0, -0.21, 0.0), _mat_skin)

	# Prótesis mecánica de brazo (articulación de cobre y pinza de hierro)
	var prost := Node3D.new()
	prost.name = "ProstheticArm"
	prost.visible = false
	shoulder_pivot.add_child(prost)
	var mat_iron := _make_mat(Color(0.34, 0.38, 0.44), 0.32, 0.86)
	var mat_copper := _make_mat(Color(0.86, 0.50, 0.24), 0.28, 0.88, Color(0.86, 0.45, 0.18), 0.15)
	_add_cyl(prost, 0.074, 0.065, 0.18, Vector3(0.0, -0.09, 0.0), _mat_apron)
	_add_sphere(prost, 0.070, 0.14, Vector3(0.0, -0.21, 0.0), mat_copper)
	_add_cyl(prost, 0.045, 0.040, 0.20, Vector3(0.0, -0.32, 0.0), mat_iron)
	_add_box(prost, Vector3(0.09, 0.09, 0.12), Vector3(0.0, -0.43, 0.03), mat_copper)

	# Muñón vendado de brazo
	var stump := Node3D.new()
	stump.name = "StumpArm"
	stump.visible = false
	shoulder_pivot.add_child(stump)
	var mat_bandage := _make_mat(Color(0.92, 0.89, 0.82), 0.90, 0.0)
	_add_cyl(stump, 0.072, 0.064, 0.16, Vector3(0.0, -0.08, 0.0), _mat_tunic)
	_add_sphere(stump, 0.068, 0.13, Vector3(0.0, -0.17, 0.0), mat_bandage)

	var sock := Node3D.new()
	sock.name = "LeftHandSocket" if is_left else "RightHandSocket"
	sock.position = Vector3(0.0, -0.22, 0.04)
	forearm_piv.add_child(sock)

	if is_left:
		left_forearm_pivot = forearm_piv
		left_arm_natural = nat
		left_arm_prosthetic = prost
		left_arm_stump = stump
		left_hand_socket = sock
	else:
		right_forearm_pivot = forearm_piv
		right_arm_natural = nat
		right_arm_prosthetic = prost
		right_arm_stump = stump
		right_hand_socket = sock

func _build_headgear_catalog() -> void:
	var mat_leather := _make_mat(Color(0.46, 0.29, 0.16), 0.76, 0.10)
	var mat_iron := _make_mat(Color(0.70, 0.74, 0.80), 0.32, 0.80)
	var mat_steel := _make_mat(Color(0.45, 0.78, 0.98), 0.22, 0.90, Color(0.25, 0.55, 0.85), 0.18)
	var mat_gold := _make_mat(Color(0.95, 0.78, 0.25), 0.28, 0.85)
	var mat_sheriff := _make_mat(Color(0.18, 0.16, 0.15), 0.80, 0.08)
	var mat_velvet := _make_mat(Color(0.68, 0.12, 0.18), 0.75, 0.05)
	var mat_white := _make_mat(Color(0.95, 0.95, 0.92), 0.85, 0.0)
	var mat_straw := _make_mat(Color(0.88, 0.74, 0.36), 0.88, 0.0)

	# 1. Casco Nivel 1 (Capucha de cuero)
	var h1 := Node3D.new()
	_add_sphere(h1, 0.255, 0.36, Vector3(0.0, -0.05, -0.01), mat_leather)
	_add_box(h1, Vector3(0.36, 0.05, 0.14), Vector3(0.0, -0.02, 0.16), mat_leather)
	_reg_headgear("helm_t1", h1)

	# 2. Casco Nivel 2 / Guardia (Celada de hierro con nasal)
	var h2 := Node3D.new()
	_add_sphere(h2, 0.26, 0.38, Vector3(0.0, -0.04, 0.0), mat_iron)
	_add_cyl(h2, 0.27, 0.27, 0.05, Vector3(0.0, -0.06, 0.0), mat_iron)
	_add_box(h2, Vector3(0.04, 0.16, 0.04), Vector3(0.0, -0.10, 0.25), mat_iron)
	_reg_headgear("helm_t2", h2)

	# 3. Casco Nivel 3 (Yelmo de Acero Maestro con cresta dorada)
	var h3 := Node3D.new()
	_add_sphere(h3, 0.265, 0.40, Vector3(0.0, -0.04, 0.0), mat_steel)
	_add_box(h3, Vector3(0.06, 0.18, 0.38), Vector3(0.0, 0.12, -0.02), mat_gold)
	_add_box(h3, Vector3(0.08, 0.22, 0.05), Vector3(-0.25, -0.04, 0.04), mat_gold, Vector3(0, 0, 22))
	_add_box(h3, Vector3(0.08, 0.22, 0.05), Vector3(0.25, -0.04, 0.04), mat_gold, Vector3(0, 0, -22))
	_reg_headgear("helm_t3", h3)

	# 4. Sombrero de Comisario / Inquisidor
	var h_sh := Node3D.new()
	_add_cyl(h_sh, 0.38, 0.38, 0.03, Vector3(0.0, -0.04, 0.0), mat_sheriff)
	_add_cyl(h_sh, 0.18, 0.22, 0.18, Vector3(0.0, 0.06, 0.0), mat_sheriff)
	_add_sphere(h_sh, 0.045, 0.09, Vector3(0.0, 0.03, 0.21), mat_gold)
	_reg_headgear("sheriff_hat", h_sh)

	# 5. Birrete / Corona Noble
	var h_nb := Node3D.new()
	_add_cyl(h_nb, 0.23, 0.21, 0.07, Vector3(0.0, -0.03, 0.0), mat_gold)
	_add_sphere(h_nb, 0.24, 0.22, Vector3(0.0, 0.04, 0.0), mat_velvet)
	_add_box(h_nb, Vector3(0.04, 0.22, 0.06), Vector3(0.16, 0.14, 0.10), mat_white, Vector3(-15, 0, -20))
	_reg_headgear("noble_crown", h_nb)

	# 6. Gorro de Panadero
	var h_bk := Node3D.new()
	_add_cyl(h_bk, 0.21, 0.20, 0.12, Vector3(0.0, 0.02, 0.0), mat_white)
	_add_sphere(h_bk, 0.25, 0.24, Vector3(0.0, 0.12, 0.0), mat_white)
	_reg_headgear("baker_hat", h_bk)

	# 7. Sombrero de Paja (Granjero / Ganadero)
	var h_st := Node3D.new()
	_add_cyl(h_st, 0.40, 0.40, 0.025, Vector3(0.0, -0.04, 0.0), mat_straw)
	_add_cyl(h_st, 0.19, 0.22, 0.13, Vector3(0.0, 0.03, 0.0), mat_straw)
	_reg_headgear("straw_hat", h_st)

	# 8. Mitra / Símbolo del Alba (Sacerdote)
	var h_pr := Node3D.new()
	_add_cyl(h_pr, 0.18, 0.22, 0.16, Vector3(0.0, 0.04, 0.0), mat_white)
	_add_sphere(h_pr, 0.06, 0.12, Vector3(0.0, 0.14, 0.16), mat_gold)
	_reg_headgear("priest_cap", h_pr)

func _reg_headgear(key: String, node: Node3D) -> void:
	node.visible = false
	head_socket.add_child(node)
	_headgear_models[key] = node

func _build_weapon_and_tool_catalog() -> void:
	var mat_wood := _make_mat(Color(0.48, 0.30, 0.15), 0.80, 0.05)
	var mat_dark_wood := _make_mat(Color(0.32, 0.18, 0.09), 0.72, 0.08)
	var mat_gold := _make_mat(Color(0.92, 0.75, 0.24), 0.30, 0.85)
	var mat_iron := _make_mat(Color(0.52, 0.56, 0.62), 0.38, 0.80)
	var mat_tin := _make_mat(Color(0.62, 0.68, 0.72), 0.42, 0.65)
	var mat_string := _make_mat(Color(0.90, 0.88, 0.80), 0.90, 0.0)

	# 1. Espada (Sword)
	var sw := Node3D.new()
	_add_cyl(sw, 0.026, 0.026, 0.22, Vector3(0.0, 0.0, 0.0), mat_dark_wood, Vector3(90, 0, 0))
	_add_sphere(sw, 0.045, 0.09, Vector3(0.0, 0.0, -0.12), mat_gold)
	_add_box(sw, Vector3(0.24, 0.04, 0.05), Vector3(0.0, 0.0, 0.11), mat_gold)
	_add_box(sw, Vector3(0.065, 0.022, 0.68), Vector3(0.0, 0.0, 0.46), _mat_weapon_metal)
	_reg_weapon("sword", sw)

	# 2. Martillo (Hammer)
	var hm := Node3D.new()
	_add_cyl(hm, 0.028, 0.028, 0.64, Vector3(0.0, 0.0, 0.22), mat_wood, Vector3(90, 0, 0))
	_add_box(hm, Vector3(0.28, 0.15, 0.16), Vector3(0.0, 0.0, 0.52), _mat_weapon_metal)
	_reg_weapon("hammer", hm)

	# 3. Hacha (Axe)
	var ax := Node3D.new()
	_add_cyl(ax, 0.026, 0.028, 0.62, Vector3(0.0, 0.0, 0.20), mat_wood, Vector3(90, 0, 0))
	_add_box(ax, Vector3(0.04, 0.24, 0.18), Vector3(0.0, -0.08, 0.46), _mat_weapon_metal)
	_reg_weapon("axe", ax)

	# 4. Pico (Pickaxe)
	var pk := Node3D.new()
	_add_cyl(pk, 0.026, 0.028, 0.62, Vector3(0.0, 0.0, 0.20), mat_wood, Vector3(90, 0, 0))
	_add_box(pk, Vector3(0.05, 0.42, 0.07), Vector3(0.0, 0.0, 0.48), _mat_weapon_metal)
	_reg_weapon("pickaxe", pk)

	# 5. Arco de Caza (Bow)
	var bw := Node3D.new()
	_add_box(bw, Vector3(0.04, 0.68, 0.06), Vector3(0.0, 0.0, 0.16), mat_wood)
	_add_cyl(bw, 0.008, 0.008, 0.66, Vector3(0.0, 0.0, 0.04), mat_string)
	var arrow_node := _add_cyl(bw, 0.012, 0.012, 0.56, Vector3(0.0, 0.0, 0.22), mat_wood, Vector3(90, 0, 0))
	arrow_node.name = "BowArrowMesh"
	_reg_weapon("bow", bw)

	# 6. Hoz (Sickle)
	var sk := Node3D.new()
	_add_cyl(sk, 0.025, 0.025, 0.24, Vector3(0.0, 0.0, 0.04), mat_wood, Vector3(90, 0, 0))
	_add_box(sk, Vector3(0.22, 0.025, 0.24), Vector3(0.08, 0.0, 0.24), _mat_weapon_metal, Vector3(0, -28, 0))
	_reg_weapon("sickle", sk)

	# 7. Regadera (Watering Can)
	var wc := Node3D.new()
	_add_cyl(wc, 0.13, 0.14, 0.24, Vector3(0.0, -0.04, 0.18), mat_tin)
	_add_cyl(wc, 0.025, 0.04, 0.24, Vector3(0.0, 0.02, 0.34), mat_tin, Vector3(55, 0, 0))
	_add_sphere(wc, 0.055, 0.08, Vector3(0.0, 0.09, 0.44), mat_gold)
	_reg_weapon("watering_can", wc)

	# 8. Caña de Pescar (Fishing Rod)
	var fr := Node3D.new()
	_add_cyl(fr, 0.010, 0.024, 1.05, Vector3(0.0, 0.0, 0.46), mat_wood, Vector3(90, 0, 0))
	_reg_weapon("fishing_rod", fr)

	# 9. Arcabuz / Pistola de Chispa (Flintlock Arquebus) + Fogonazo y Humo 3D
	var fl := Node3D.new()
	_add_box(fl, Vector3(0.06, 0.11, 0.38), Vector3(0.0, -0.02, 0.12), mat_dark_wood)
	_add_cyl(fl, 0.032, 0.028, 0.62, Vector3(0.0, 0.03, 0.42), mat_iron, Vector3(90, 0, 0))
	_add_cyl(fl, 0.048, 0.032, 0.08, Vector3(0.0, 0.03, 0.74), mat_gold, Vector3(90, 0, 0))
	_add_box(fl, Vector3(0.08, 0.07, 0.12), Vector3(0.0, 0.02, 0.22), mat_gold)

	_muzzle_flash_node = Node3D.new()
	_muzzle_flash_node.position = Vector3(0.0, 0.03, 0.84)
	_muzzle_flash_node.visible = false
	fl.add_child(_muzzle_flash_node)
	var mat_flash := _make_mat(Color(1.0, 0.82, 0.28, 0.92), 0.1, 0.0, Color(1.0, 0.65, 0.15), 3.8)
	_add_sphere(_muzzle_flash_node, 0.18, 0.36, Vector3.ZERO, mat_flash)
	var mat_smoke := _make_mat(Color(0.82, 0.84, 0.88, 0.68), 0.95, 0.0)
	for i in range(3):
		var sp := _add_sphere(_muzzle_flash_node, 0.12 + float(i) * 0.05, 0.24 + float(i) * 0.08, Vector3(0.0, 0.05 * float(i), 0.14 * float(i + 1)), mat_smoke)
		_smoke_puff_nodes.append(sp)
	_reg_weapon("flintlock", fl)

	# 10. Alabarda / Lanza de Guardia (Guard Spear)
	var sp_g := Node3D.new()
	_add_cyl(sp_g, 0.024, 0.024, 1.15, Vector3(0.0, 0.0, 0.35), mat_wood, Vector3(90, 0, 0))
	_add_box(sp_g, Vector3(0.05, 0.14, 0.26), Vector3(0.0, 0.0, 0.98), mat_iron)
	_reg_weapon("guard_spear", sp_g)

func _reg_weapon(key: String, node: Node3D) -> void:
	node.visible = false
	right_hand_socket.add_child(node)
	_weapon_models[key] = node

func _build_offhand_catalog() -> void:
	var mat_iron := _make_mat(Color(0.66, 0.70, 0.78), 0.35, 0.78)
	var mat_wood := _make_mat(Color(0.45, 0.28, 0.14), 0.82, 0.05)
	var mat_gold := _make_mat(Color(0.95, 0.78, 0.25), 0.28, 0.85)
	var mat_glow := _make_mat(Color(1.0, 0.85, 0.38, 0.92), 0.15, 0.0, Color(1.0, 0.72, 0.22), 2.6)

	# 1. Escudo de Guardia
	var sh := Node3D.new()
	_add_box(sh, Vector3(0.06, 0.44, 0.34), Vector3(-0.06, 0.0, 0.08), mat_iron)
	_add_sphere(sh, 0.07, 0.12, Vector3(-0.09, 0.0, 0.08), mat_gold)
	_reg_offhand("shield", sh)

	# 2. Farol Nocturno
	var ln := Node3D.new()
	_add_cyl(ln, 0.08, 0.07, 0.18, Vector3(0.0, -0.10, 0.06), mat_glow)
	_add_cyl(ln, 0.10, 0.09, 0.04, Vector3(0.0, -0.01, 0.06), mat_iron)
	_reg_offhand("lantern", ln)

	# 3. Libro del Alba / Tomo
	var bk := Node3D.new()
	_add_box(bk, Vector3(0.18, 0.06, 0.24), Vector3(0.04, 0.0, 0.10), mat_gold)
	_reg_offhand("book", bk)

	# 4. Muleta de madera (para amputados sin prótesis)
	var cr := Node3D.new()
	_add_cyl(cr, 0.022, 0.018, 0.78, Vector3(-0.06, -0.18, 0.06), mat_wood)
	_add_box(cr, Vector3(0.06, 0.05, 0.22), Vector3(-0.06, 0.20, 0.06), mat_wood)
	_reg_offhand("crutch", cr)

func _reg_offhand(key: String, node: Node3D) -> void:
	node.visible = false
	left_hand_socket.add_child(node)
	_offhand_models[key] = node

func trigger_muzzle_flash() -> void:
	_ensure_built()
	_muzzle_flash_timer = 0.22
	if _muzzle_flash_node:
		_muzzle_flash_node.visible = true
		_muzzle_flash_node.scale = Vector3.ONE

func set_active_weapon(key: String, tier: int = 1) -> void:
	_ensure_built()
	var norm_key := key.to_lower()
	if _active_weapon_key != norm_key:
		for k in _weapon_models.keys():
			var n: Node3D = _weapon_models[k]
			n.visible = (k == norm_key)
		_active_weapon_key = norm_key
	match clampi(tier, 1, 3):
		1:
			_mat_weapon_metal.albedo_color = Color(0.68, 0.70, 0.74)
			_mat_weapon_metal.emission_enabled = false
		2:
			_mat_weapon_metal.albedo_color = Color(0.84, 0.88, 0.95)
			_mat_weapon_metal.emission_enabled = false
		3:
			_mat_weapon_metal.albedo_color = Color(0.48, 0.84, 1.0)
			_mat_weapon_metal.emission_enabled = true
			_mat_weapon_metal.emission = Color(0.20, 0.55, 0.85)
			_mat_weapon_metal.emission_energy_multiplier = 0.25

func set_active_offhand(key: String) -> void:
	_ensure_built()
	var norm_key := key.to_lower()
	if _active_offhand_key != norm_key:
		for k in _offhand_models.keys():
			var n: Node3D = _offhand_models[k]
			n.visible = (k == norm_key)
		_active_offhand_key = norm_key

func set_active_headgear(key: String) -> void:
	_ensure_built()
	var norm_key := key.to_lower()
	if _active_headgear_key != norm_key:
		for k in _headgear_models.keys():
			var n: Node3D = _headgear_models[k]
			n.visible = (k == norm_key)
		_active_headgear_key = norm_key
		if hair_top_mesh:
			hair_top_mesh.visible = (norm_key == "" or norm_key == "none" or norm_key == "noble_crown")

## Configura colores, peinado, vestimenta, armadura y prótesis de un perfil de personaje.
func apply_character_appearance(cfg: Dictionary) -> void:
	_ensure_built()
	var skin_col: Color = cfg.get("skin_color", Color(0.93, 0.76, 0.63))
	var hair_col: Color = cfg.get("hair_color", Color(0.26, 0.17, 0.11))
	var tunic_col: Color = cfg.get("tunic_color", Color(0.28, 0.46, 0.68))
	var pants_col: Color = cfg.get("pants_color", Color(0.24, 0.22, 0.20))
	var is_female: bool = bool(cfg.get("is_female", false))
	var is_child: bool = bool(cfg.get("is_child", false))
	var has_beard: bool = bool(cfg.get("has_beard", false)) and not is_female and not is_child
	var has_apron: bool = bool(cfg.get("has_apron", false))
	var has_skirt: bool = bool(cfg.get("has_skirt", is_female))
	var has_cape: bool = bool(cfg.get("has_cape", false))
	var cape_col: Color = cfg.get("cape_color", Color(0.58, 0.16, 0.18))

	_mat_skin.albedo_color = skin_col
	_mat_hair.albedo_color = hair_col
	_mat_tunic.albedo_color = tunic_col
	_mat_pants.albedo_color = pants_col
	_mat_cape.albedo_color = cape_col

	root_pivot.scale = Vector3.ONE * (0.68 if is_child else 1.0)
	if hair_bun_mesh:
		hair_bun_mesh.visible = is_female
	if beard_mesh:
		beard_mesh.visible = has_beard
	if apron_mesh:
		apron_mesh.visible = has_apron
		if cfg.has("apron_color"):
			_mat_apron.albedo_color = cfg["apron_color"]
	if skirt_mesh:
		skirt_mesh.visible = has_skirt
	if cape_mesh:
		cape_mesh.visible = has_cape

	# Armaduras por pieza (HEAD, CHEST, LEGS, BOOTS)
	var chest_tier: int = int(cfg.get("chest_armor_tier", 0))
	var legs_tier: int = int(cfg.get("legs_armor_tier", 0))
	var boots_tier: int = int(cfg.get("boots_armor_tier", 0))
	var head_key: String = str(cfg.get("headgear", "none"))

	if chest_armor_root:
		chest_armor_root.visible = (chest_tier > 0)
		if chest_tier > 0:
			_mat_chest_armor.albedo_color = _armor_tier_color(chest_tier)
			_mat_chest_armor.metallic = 0.15 if chest_tier == 1 else 0.80
	if left_greave_mesh and right_greave_mesh:
		left_greave_mesh.visible = (legs_tier > 0)
		right_greave_mesh.visible = (legs_tier > 0)
		if legs_tier > 0:
			_mat_leg_armor.albedo_color = _armor_tier_color(legs_tier)
	if left_boot_mesh and right_boot_mesh:
		_mat_boots.albedo_color = _armor_tier_color(boots_tier) if boots_tier > 0 else Color(0.22, 0.15, 0.10)

	set_active_headgear(head_key)

	# Estado de extremidades: "normal", "prosthetic", "amputated"
	var l_arm_state: String = str(cfg.get("left_arm_state", "normal"))
	var r_arm_state: String = str(cfg.get("right_arm_state", "normal"))
	var l_leg_state: String = str(cfg.get("left_leg_state", "normal"))
	var r_leg_state: String = str(cfg.get("right_leg_state", "normal"))
	_apply_limb_state(left_arm_natural, left_arm_prosthetic, left_arm_stump, l_arm_state, left_forearm_pivot)
	_apply_limb_state(right_arm_natural, right_arm_prosthetic, right_arm_stump, r_arm_state, right_forearm_pivot)
	_apply_limb_state(left_leg_natural, left_leg_prosthetic, left_leg_stump, l_leg_state, null)
	_apply_limb_state(right_leg_natural, right_leg_prosthetic, right_leg_stump, r_leg_state, null)

	var weapon_k: String = str(cfg.get("weapon", "none"))
	var weapon_t: int = int(cfg.get("weapon_tier", 1))
	set_active_weapon(weapon_k, weapon_t)

	var offhand_k: String = str(cfg.get("offhand", "none"))
	if offhand_k == "none" and (l_leg_state == "amputated" or r_leg_state == "amputated"):
		offhand_k = "crutch"
	set_active_offhand(offhand_k)

func _apply_limb_state(nat: Node3D, prost: Node3D, stump: Node3D, state: String, forearm_piv: Node3D) -> void:
	if not nat or not prost or not stump:
		return
	match state:
		"prosthetic":
			nat.visible = false
			prost.visible = true
			stump.visible = false
			if forearm_piv:
				for ch in forearm_piv.get_children():
					if ch is MeshInstance3D:
						ch.visible = false
		"amputated":
			nat.visible = false
			prost.visible = false
			stump.visible = true
			if forearm_piv:
				for ch in forearm_piv.get_children():
					if ch is MeshInstance3D:
						ch.visible = false
		_:
			nat.visible = true
			prost.visible = false
			stump.visible = false
			if forearm_piv:
				for ch in forearm_piv.get_children():
					if ch is MeshInstance3D:
						ch.visible = true

func _armor_tier_color(tier: int) -> Color:
	match tier:
		1: return Color(0.62, 0.39, 0.21) # Cuero tachonado
		2: return Color(0.74, 0.78, 0.86) # Hierro forjado
		3: return Color(0.42, 0.80, 0.98) # Acero maestro
	return Color(0.22, 0.15, 0.10)

## Avanza las articulaciones 3D del personaje según su estado y dirección en 360 grados.
func update_pose(delta: float, state: Dictionary) -> void:
	_ensure_built()
	_anim_clock += delta

	if _muzzle_flash_timer > 0.0:
		_muzzle_flash_timer = maxf(0.0, _muzzle_flash_timer - delta)
		if _muzzle_flash_node:
			var prog: float = 1.0 - (_muzzle_flash_timer / 0.22)
			_muzzle_flash_node.scale = Vector3.ONE * lerpf(0.75, 1.85, prog)
			if _muzzle_flash_timer <= 0.0:
				_muzzle_flash_node.visible = false

	var facing_2d: Vector2 = state.get("facing", Vector2.DOWN)
	if facing_2d.length_squared() > 0.001:
		_target_yaw = atan2(facing_2d.x, facing_2d.y)
	_current_yaw = lerp_angle(_current_yaw, _target_yaw, clampf(delta * 14.0, 0.0, 1.0))

	var is_sleeping: bool = bool(state.get("is_sleeping", false))
	var is_downed: bool = bool(state.get("is_downed", false))
	var is_dead: bool = bool(state.get("is_dead", false))
	var is_stealth: bool = bool(state.get("is_stealth", false))
	var is_sprinting: bool = bool(state.get("is_sprinting", false))
	var is_working: bool = bool(state.get("is_working", false))
	var is_fighting: bool = bool(state.get("is_fighting", false))
	var is_hostile: bool = bool(state.get("is_hostile", false))
	var speed_ratio: float = clampf(float(state.get("speed_ratio", 0.0)), 0.0, 1.8)
	_bow_draw_ratio = clampf(float(state.get("bow_draw", 0.0)), 0.0, 1.0)
	var atk_prog: float = clampf(float(state.get("attack_progress", 0.0)), 0.0, 1.0)

	# Expresión de cejas
	if left_brow_mesh and right_brow_mesh:
		var angry: bool = is_hostile or is_fighting or atk_prog > 0.0
		left_brow_mesh.rotation_degrees.z = -16.0 if angry else 0.0
		right_brow_mesh.rotation_degrees.z = 16.0 if angry else 0.0

	# Estado tumbado (durmiendo, agonizando o cadáver)
	if is_dead or is_downed or is_sleeping:
		root_pivot.rotation = Vector3(-PI * 0.46, _current_yaw, 0.0)
		root_pivot.position = Vector3(0.0, 0.16, 0.0)
		left_hip_pivot.rotation = Vector3.ZERO
		right_hip_pivot.rotation = Vector3.ZERO
		left_shoulder_pivot.rotation = Vector3(0.15, 0.0, 0.12)
		right_shoulder_pivot.rotation = Vector3(0.15, 0.0, -0.12)
		return

	root_pivot.rotation = Vector3(0.0, _current_yaw, 0.0)
	root_pivot.position = Vector3.ZERO

	# Ciclo de paso al caminar o correr
	if speed_ratio > 0.05:
		var freq: float = 13.5 if is_sprinting else (7.0 if is_stealth else 10.0)
		_walk_cycle += delta * freq * clampf(speed_ratio, 0.5, 1.5)
	else:
		_walk_cycle = move_toward(_walk_cycle, round(_walk_cycle / PI) * PI, delta * 8.0)

	var stride: float = sin(_walk_cycle) * clampf(speed_ratio, 0.0, 1.25)
	var bounce: float = absf(sin(_walk_cycle)) * 0.055 * clampf(speed_ratio, 0.0, 1.2)
	var crouch_offset: float = -0.12 if is_stealth else 0.0
	hips_pivot.position.y = 0.58 + bounce + crouch_offset

	# Inclinación del torso al esprintar o ir en sigilo
	var torso_pitch: float = -0.24 if is_stealth else (-0.18 if is_sprinting and speed_ratio > 0.2 else 0.0)
	var breath: float = sin(_anim_clock * 2.6) * 0.025
	torso_pivot.rotation = Vector3(torso_pitch + breath, 0.0, 0.0)
	head_pivot.rotation = Vector3(-torso_pitch * 0.6, sin(_anim_clock * 1.1) * 0.06, 0.0)

	# Piernas en contrafase
	left_hip_pivot.rotation.x = stride * 0.68
	right_hip_pivot.rotation.x = -stride * 0.68

	# Ondulación de la capa
	if cape_pivot and cape_mesh and cape_mesh.visible:
		cape_pivot.rotation.x = 0.14 + clampf(speed_ratio * 0.38, 0.0, 0.55) + absf(sin(_walk_cycle)) * 0.10

	# Pose de brazos según acción (disparo, arco, ataque cuerpo a cuerpo, taller, pelea callejera o marcha)
	if _muzzle_flash_timer > 0.0 or (_active_weapon_key == "flintlock" and atk_prog > 0.0):
		var recoil: float = sin(atk_prog * PI) * 0.35
		right_shoulder_pivot.rotation = Vector3(PI * 0.48 + recoil, 0.0, -0.05)
		right_forearm_pivot.rotation = Vector3(0.10, 0.0, 0.0)
		left_shoulder_pivot.rotation = Vector3(PI * 0.42, 0.35, 0.15)
		left_forearm_pivot.rotation = Vector3(0.25, 0.0, 0.0)
	elif _bow_draw_ratio > 0.01 or (_active_weapon_key == "bow" and atk_prog > 0.0):
		right_shoulder_pivot.rotation = Vector3(PI * 0.48, 0.0, -0.06)
		right_forearm_pivot.rotation = Vector3(0.05, 0.0, 0.0)
		left_shoulder_pivot.rotation = Vector3(PI * 0.45, -0.25 * _bow_draw_ratio, 0.12)
		left_forearm_pivot.rotation = Vector3(0.35 * _bow_draw_ratio, 0.0, 0.0)
	elif atk_prog > 0.01:
		# Golpe / Tajo con giro de torso
		var swing_angle: float = lerpf(2.1, -0.85, sin(atk_prog * PI * 0.85))
		torso_pivot.rotation.y = sin(atk_prog * PI) * 0.42
		right_shoulder_pivot.rotation = Vector3(swing_angle, 0.0, -0.18)
		right_forearm_pivot.rotation = Vector3(0.35, 0.0, 0.0)
		left_shoulder_pivot.rotation = Vector3(-0.35, 0.0, 0.22)
		left_forearm_pivot.rotation = Vector3(0.25, 0.0, 0.0)
	elif is_fighting:
		# Guardia de boxeo / pelea callejera
		var jab_l: float = maxf(0.0, sin(_anim_clock * 11.0)) * 0.75
		var jab_r: float = maxf(0.0, -sin(_anim_clock * 11.0)) * 0.75
		left_shoulder_pivot.rotation = Vector3(1.1 + jab_l, 0.18, 0.12)
		left_forearm_pivot.rotation = Vector3(0.75 - jab_l * 0.5, 0.0, 0.0)
		right_shoulder_pivot.rotation = Vector3(1.1 + jab_r, -0.18, -0.12)
		right_forearm_pivot.rotation = Vector3(0.75 - jab_r * 0.5, 0.0, 0.0)
	elif is_working:
		# Martilleo / trabajo rítmico en el taller
		var work_swing: float = sin(_anim_clock * 8.5)
		right_shoulder_pivot.rotation = Vector3(1.05 + work_swing * 0.65, 0.0, -0.10)
		right_forearm_pivot.rotation = Vector3(0.45, 0.0, 0.0)
		left_shoulder_pivot.rotation = Vector3(0.55 - work_swing * 0.18, 0.20, 0.12)
		left_forearm_pivot.rotation = Vector3(0.35, 0.0, 0.0)
	else:
		# Marcha natural o reposo
		var arm_swing: float = -stride * 0.58
		left_shoulder_pivot.rotation = Vector3(arm_swing, 0.0, 0.08)
		left_forearm_pivot.rotation = Vector3(0.18 + maxf(0.0, arm_swing * 0.25), 0.0, 0.0)
		var carry_bias: float = 0.32 if _active_weapon_key != "none" else 0.0
		right_shoulder_pivot.rotation = Vector3(-arm_swing * 0.75 + carry_bias, 0.0, -0.08)
		right_forearm_pivot.rotation = Vector3(0.28 + carry_bias * 0.5, 0.0, 0.0)
