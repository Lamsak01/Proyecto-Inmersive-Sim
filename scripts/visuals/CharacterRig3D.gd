class_name CharacterRig3D
extends Node3D

## Muñeco 3D articulado para el Jugador y los Vecinos del valle.
## Si existen los modelos reales filtrados en `res://assests/curated_3d/` (Quaternius Universal Base
## Characters + Modular Fantasy Outfits + Armas/Herramientas 3D), construye el personaje con mallas
## humanas reales esculpidas, texturas PBR, peinados/barba 3D y armas reales ancladas al esqueleto.

const AssetLib = preload("res://scripts/visuals/AssetLibrary3D.gd")

enum AnimState {
	IDLE,
	WALK,
	ATTACK,
	WORK,
	CARRY,
	PRAY,
	SLEEP,
	KO,
	AIM_GUN,
	MOUNTED,
	ROLL,
	BLOCK
}

# Nodos de articulación (fallback procedural o pivotes auxiliares)
var pelvis: Node3D
var torso_pivot: Node3D
var head_pivot: Node3D
var arm_l_pivot: Node3D
var forearm_l_pivot: Node3D
var hand_l_socket: Node3D
var arm_r_pivot: Node3D
var forearm_r_pivot: Node3D
var hand_r_socket: Node3D
var leg_l_pivot: Node3D
var shin_l_pivot: Node3D
var leg_r_pivot: Node3D
var shin_r_pivot: Node3D

# Esqueleto real Quaternius (65 huesos)
var _skeleton: Skeleton3D = null
var _using_real_mesh: bool = false
var _bone_idx: Dictionary = {} # bone_name -> int
var _bone_rest_q: Dictionary = {} # bone_name -> Quaternion

# Contenedores de piezas intercambiables
var hair_root: Node3D
var hat_root: Node3D
var beard_root: Node3D
var armor_torso_root: Node3D
var cape_root: Node3D
var skirt_root: Node3D
var tool_r_root: Node3D
var tool_l_root: Node3D
var muzzle_flash_node: Node3D

# Estado visual cacheado
var _is_female: bool = false
var _is_child: bool = false
var _skin_color: Color = Color(0.92, 0.76, 0.63)
var _hair_color: Color = Color(0.24, 0.16, 0.10)
var _tunic_color: Color = Color(0.32, 0.44, 0.62)
var _pants_color: Color = Color(0.22, 0.20, 0.18)
var _apron_color: Color = Color(0.85, 0.82, 0.75, 0.0)
var _hat_style: String = "none"
var _hair_style: String = "short"
var _has_beard: bool = false
var _has_skirt: bool = false
var _has_cape: bool = false
var _cape_color: Color = Color(0.55, 0.16, 0.16)
var _outfit_kind: String = "peasant" # "peasant" | "ranger"
var _outfit_tex_variant: int = 0
var _hair_tex_variant: int = 0
var _is_dark_skin: bool = false

# Equipo y prótesis
var _weapon_id: String = "none"
var _helmet_tier: int = 0
var _chest_tier: int = 0
var _legs_tier: int = 0
var _boots_tier: int = 0
var _missing_arm_r: bool = false
var _missing_leg_r: bool = false
var _prosthetic_arm_r: bool = false
var _prosthetic_leg_r: bool = false
var _carrying_lantern: bool = false

# Animación
var _anim_state: int = AnimState.IDLE
var _anim_time: float = 0.0
var _attack_swing_t: float = 0.0
var _muzzle_flash_t: float = 0.0
var _is_rolling: bool = false
var _roll_progress: float = 0.0
var _is_parrying: bool = false
var _facing_yaw: float = 0.0
var _target_yaw: float = 0.0

# Animaciones reales (Quaternius Universal Animation Library, CC0), adaptadas por tools/bake_character_animations.gd
const ANIM_LIB_MALE := "res://assests/curated_3d/animations/ual_male.res"
const ANIM_LIB_FEMALE := "res://assests/curated_3d/animations/ual_female.res"
# Calibración de zancada medida en el esqueleto real a escala de escenario (STAGE_K = 0.40 -> 20 px/unidad, char_root = 0.88):
# - "walk" (Walk_Loop, 1.333 s): zancada de ciclo completo = 1.443 u_rig = 28.86 px -> velocidad nativa = 21.65 px/s
# - "run"  (Jog_Fwd_Loop, 0.933 s): zancada de ciclo completo = 2.620 u_rig = 52.40 px -> velocidad nativa = 56.15 px/s
# - "carry" (Carry_Walk_Loop, 2.000 s): zancada de ciclo completo = 1.437 u_rig = 28.74 px -> velocidad nativa = 14.37 px/s
const WALK_CYCLE_PX: float = 28.86
const WALK_BASE_PX_S: float = 21.65
const RUN_CYCLE_PX: float = 52.40
const RUN_BASE_PX_S: float = 56.15
const CARRY_BASE_PX_S: float = 14.37
static var _anim_lib_cache: Dictionary = {} # ruta -> AnimationLibrary
var _anim_player: AnimationPlayer = null
var _current_clip: String = ""
var _speed_ratio: float = 1.0


func _ready() -> void:
	_build_skeleton()
	_rebuild_meshes()


func _build_skeleton() -> void:
	for c in get_children():
		c.queue_free()

	pelvis = Node3D.new()
	pelvis.name = "Pelvis"
	pelvis.position = Vector3(0.0, 0.72, 0.0)
	add_child(pelvis)

	torso_pivot = Node3D.new()
	torso_pivot.name = "TorsoPivot"
	pelvis.add_child(torso_pivot)

	head_pivot = Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0.0, 0.56, 0.0)
	torso_pivot.add_child(head_pivot)

	hair_root = Node3D.new()
	hair_root.name = "HairRoot"
	head_pivot.add_child(hair_root)

	hat_root = Node3D.new()
	hat_root.name = "HatRoot"
	head_pivot.add_child(hat_root)

	beard_root = Node3D.new()
	beard_root.name = "BeardRoot"
	head_pivot.add_child(beard_root)

	armor_torso_root = Node3D.new()
	armor_torso_root.name = "ArmorTorsoRoot"
	torso_pivot.add_child(armor_torso_root)

	cape_root = Node3D.new()
	cape_root.name = "CapeRoot"
	cape_root.position = Vector3(0.0, 0.50, -0.14)
	torso_pivot.add_child(cape_root)

	skirt_root = Node3D.new()
	skirt_root.name = "SkirtRoot"
	pelvis.add_child(skirt_root)

	arm_l_pivot = Node3D.new()
	arm_l_pivot.name = "ArmLPivot"
	arm_l_pivot.position = Vector3(-0.27, 0.48, 0.0)
	torso_pivot.add_child(arm_l_pivot)

	forearm_l_pivot = Node3D.new()
	forearm_l_pivot.name = "ForearmLPivot"
	forearm_l_pivot.position = Vector3(0.0, -0.24, 0.0)
	arm_l_pivot.add_child(forearm_l_pivot)

	hand_l_socket = Node3D.new()
	hand_l_socket.name = "HandLSocket"
	hand_l_socket.position = Vector3(0.0, -0.22, 0.04)
	forearm_l_pivot.add_child(hand_l_socket)

	tool_l_root = Node3D.new()
	tool_l_root.name = "ToolLRoot"
	hand_l_socket.add_child(tool_l_root)

	arm_r_pivot = Node3D.new()
	arm_r_pivot.name = "ArmRPivot"
	arm_r_pivot.position = Vector3(0.27, 0.48, 0.0)
	torso_pivot.add_child(arm_r_pivot)

	forearm_r_pivot = Node3D.new()
	forearm_r_pivot.name = "ForearmRPivot"
	forearm_r_pivot.position = Vector3(0.0, -0.24, 0.0)
	arm_r_pivot.add_child(forearm_r_pivot)

	hand_r_socket = Node3D.new()
	hand_r_socket.name = "HandRSocket"
	hand_r_socket.position = Vector3(0.0, -0.22, 0.04)
	forearm_r_pivot.add_child(hand_r_socket)

	tool_r_root = Node3D.new()
	tool_r_root.name = "ToolRRoot"
	hand_r_socket.add_child(tool_r_root)

	leg_l_pivot = Node3D.new()
	leg_l_pivot.name = "LegLPivot"
	leg_l_pivot.position = Vector3(-0.12, 0.0, 0.0)
	pelvis.add_child(leg_l_pivot)

	shin_l_pivot = Node3D.new()
	shin_l_pivot.name = "ShinLPivot"
	shin_l_pivot.position = Vector3(0.0, -0.34, 0.0)
	leg_l_pivot.add_child(shin_l_pivot)

	leg_r_pivot = Node3D.new()
	leg_r_pivot.name = "LegRPivot"
	leg_r_pivot.position = Vector3(0.12, 0.0, 0.0)
	pelvis.add_child(leg_r_pivot)

	shin_r_pivot = Node3D.new()
	shin_r_pivot.name = "ShinRPivot"
	shin_r_pivot.position = Vector3(0.0, -0.34, 0.0)
	leg_r_pivot.add_child(shin_r_pivot)


func apply_appearance(config: Dictionary) -> void:
	apply_character_appearance(config)


func apply_character_appearance(config: Dictionary) -> void:
	_is_female = bool(config.get("is_female", _is_female))
	_is_child = bool(config.get("is_child", _is_child))
	_skin_color = config.get("skin_color", _skin_color)
	_hair_color = config.get("hair_color", _hair_color)
	_tunic_color = config.get("tunic_color", _tunic_color)
	_pants_color = config.get("pants_color", _pants_color)
	_apron_color = config.get("apron_color", _apron_color)
	_has_beard = bool(config.get("has_beard", _has_beard))
	_has_skirt = bool(config.get("has_skirt", _has_skirt))
	_has_cape = bool(config.get("has_cape", _has_cape))
	_cape_color = config.get("cape_color", _cape_color)
	_hair_style = str(config.get("hair_style", _hair_style))
	_outfit_kind = str(config.get("outfit_kind", _outfit_kind))
	_outfit_tex_variant = int(config.get("outfit_tex_variant", _outfit_tex_variant))
	_hair_tex_variant = int(config.get("hair_tex_variant", _hair_tex_variant))
	_is_dark_skin = bool(config.get("is_dark_skin", (_skin_color.r + _skin_color.g + _skin_color.b) <= 2.15))

	# Soporte tanto para claves de CharacterAvatar3D/Showcase ("headgear", "weapon", "chest_armor_tier") como directas
	if config.has("headgear"):
		var hg := str(config.get("headgear", "none"))
		match hg:
			"helm_t1":
				_hat_style = "helmet"
				_helmet_tier = 1
			"helm_t2":
				_hat_style = "helmet"
				_helmet_tier = 2
			"helm_t3":
				_hat_style = "helmet"
				_helmet_tier = 3
			"sheriff_hat":
				_hat_style = "inquisitor"
				_helmet_tier = 0
			"priest_cap":
				_hat_style = "hood"
				_helmet_tier = 0
			"baker_hat":
				_hat_style = "chef"
				_helmet_tier = 0
			"straw_hat":
				_hat_style = "straw"
				_helmet_tier = 0
			"noble_crown":
				_hat_style = "crown"
				_helmet_tier = 0
			_:
				_hat_style = "none"
				_helmet_tier = 0
	else:
		_hat_style = str(config.get("hat_style", _hat_style))
		_helmet_tier = int(config.get("helmet_tier", _helmet_tier))

	_chest_tier = int(config.get("chest_armor_tier", config.get("chest_tier", _chest_tier)))
	_legs_tier = int(config.get("legs_armor_tier", config.get("legs_tier", _legs_tier)))
	_boots_tier = int(config.get("boots_armor_tier", config.get("boots_tier", _boots_tier)))

	if config.has("weapon"):
		_weapon_id = str(config.get("weapon", "none"))
	else:
		_weapon_id = str(config.get("weapon_id", _weapon_id))

	var offhand_val := str(config.get("offhand", "none"))
	_carrying_lantern = (offhand_val == "lantern") or bool(config.get("carrying_lantern", false))
	set_meta("offhand_id", offhand_val)

	if config.has("left_arm_state") or config.has("right_arm_state"):
		var arm_st := str(config.get("right_arm_state", "normal"))
		if arm_st == "normal":
			arm_st = str(config.get("left_arm_state", "normal"))
		_missing_arm_r = (arm_st == "amputated" or arm_st == "prosthetic")
		_prosthetic_arm_r = (arm_st == "prosthetic")
	else:
		_missing_arm_r = bool(config.get("missing_arm_r", _missing_arm_r))
		_prosthetic_arm_r = bool(config.get("prosthetic_arm_r", _prosthetic_arm_r))

	if config.has("left_leg_state") or config.has("right_leg_state"):
		var leg_st := str(config.get("right_leg_state", "normal"))
		if leg_st == "normal":
			leg_st = str(config.get("left_leg_state", "normal"))
		_missing_leg_r = (leg_st == "amputated" or leg_st == "prosthetic")
		_prosthetic_leg_r = (leg_st == "prosthetic")
	else:
		_missing_leg_r = bool(config.get("missing_leg_r", _missing_leg_r))
		_prosthetic_leg_r = bool(config.get("prosthetic_leg_r", _prosthetic_leg_r))

	if is_inside_tree():
		_rebuild_meshes()


func set_weapon(weapon_id: String) -> void:
	if _weapon_id == weapon_id:
		return
	_weapon_id = weapon_id
	if is_inside_tree():
		_rebuild_tools()


func set_carrying_lantern(active: bool) -> void:
	if _carrying_lantern == active:
		return
	_carrying_lantern = active
	if is_inside_tree():
		_rebuild_tools()


func set_prosthetics(missing_arm: bool, prosth_arm: bool, missing_leg: bool, prosth_leg: bool) -> void:
	if _missing_arm_r == missing_arm and _prosthetic_arm_r == prosth_arm and _missing_leg_r == missing_leg and _prosthetic_leg_r == prosth_leg:
		return
	_missing_arm_r = missing_arm
	_prosthetic_arm_r = prosth_arm
	_missing_leg_r = missing_leg
	_prosthetic_leg_r = prosth_leg
	if is_inside_tree():
		_rebuild_meshes()


func trigger_attack_swing() -> void:
	_attack_swing_t = 0.34


func trigger_muzzle_flash() -> void:
	_muzzle_flash_t = 0.18
	_attack_swing_t = 0.28
	if muzzle_flash_node != null and is_instance_valid(muzzle_flash_node):
		muzzle_flash_node.visible = true


static func _make_mat(col: Color, rough: float = 0.82, metal: float = 0.0, emission_col: Color = Color(0, 0, 0, 0)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if emission_col.a > 0.01:
		m.emission_enabled = true
		m.emission = Color(emission_col.r, emission_col.g, emission_col.b)
		m.emission_energy_multiplier = emission_col.a * 2.5
	return m


func _clear_tagged(parent: Node) -> void:
	for c in parent.get_children():
		if c.has_meta("rig_mesh"):
			c.queue_free()


func _add_part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO, sc: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = sc
	mi.set_meta("rig_mesh", true)
	parent.add_child(mi)
	return mi


func _rebuild_meshes() -> void:
	var s := 0.72 if _is_child else 1.0
	scale = Vector3(s, s, s)

	if AssetLib.has_curated_assets():
		if _rebuild_real_quaternius_character():
			_rebuild_tools()
			AssetLib.make_retro(self)
			return

	_using_real_mesh = false
	_skeleton = null
	_rebuild_procedural_fallback()
	_rebuild_tools()


func _rebuild_real_quaternius_character() -> bool:
	# Limpiar modelo previo
	for c in get_children():
		if c.has_meta("real_char_root"):
			c.queue_free()
	pelvis.visible = false

	var use_ranger := (_outfit_kind == "ranger" or _chest_tier >= 1 or _hat_style in ["helmet", "inquisitor", "hood", "crown"])
	var outfit_file := ""
	if _is_female:
		outfit_file = "characters/Female_Ranger.gltf" if use_ranger else "characters/Female_Peasant.gltf"
	else:
		outfit_file = "characters/Male_Ranger.gltf" if use_ranger else "characters/Male_Peasant.gltf"

	var tmpl := AssetLib.load_gltf_template(outfit_file)
	if tmpl == null:
		return false

	var char_root := tmpl.duplicate() as Node3D
	char_root.name = "RealCharRoot"
	char_root.set_meta("real_char_root", true)
	# Ajustar escala para que el personaje mida ~1.55 unidades de alto en nuestro mundo
	char_root.scale = Vector3(0.88, 0.88, 0.88)
	add_child(char_root)

	_skeleton = char_root.find_child("Skeleton3D", true, false) as Skeleton3D
	if _skeleton == null:
		char_root.queue_free()
		return false

	_using_real_mesh = true
	_bone_idx.clear()
	_bone_rest_q.clear()
	for i in range(_skeleton.get_bone_count()):
		var bname := _skeleton.get_bone_name(i)
		_bone_idx[bname] = i
		_bone_rest_q[bname] = _skeleton.get_bone_rest(i).basis.get_rotation_quaternion()
	_setup_anim_player(char_root)

	# 1. Añadir cabeza esculpida, ojos y cejas desde Universal Base Characters
	var base_file := "characters/Superhero_Female_FullBody.gltf" if _is_female else "characters/Superhero_Male_FullBody.gltf"
	var base_tmpl := AssetLib.load_gltf_template(base_file)
	if base_tmpl != null:
		var base_skel := base_tmpl.find_child("Skeleton3D", true, false) as Skeleton3D
		if base_skel != null:
			for bc in base_skel.get_children():
				if not (bc is MeshInstance3D):
					continue
				var bmi := bc as MeshInstance3D
				if bmi.mesh == null:
					continue
				var bname_low := bmi.name.to_lower()
				if bname_low.find("superhero") != -1:
					var head_key := "female_head" if _is_female else "male_head"
					var head_mesh := AssetLib.extract_head_only_mesh(head_key, bmi.mesh, 1.45, 0.135)
					if head_mesh != null:
						var h_mi := MeshInstance3D.new()
						h_mi.name = "SculptedHead"
						h_mi.mesh = head_mesh
						h_mi.skin = bmi.skin
						h_mi.skeleton = NodePath("..")
						_apply_skin_material_override(h_mi)
						_skeleton.add_child(h_mi)
				elif bname_low.find("eye") != -1:
					var eye_dup := bmi.duplicate() as MeshInstance3D
					eye_dup.skeleton = NodePath("..")
					if bname_low.find("brow") != -1:
						eye_dup.material_override = _make_mat(_hair_color.darkened(0.15), 0.85, 0.0)
					_skeleton.add_child(eye_dup)

	var outfit_alt_tex: Texture2D = null
	if _outfit_tex_variant == 1:
		var alt_tex_path := "characters/T_Ranger_3_BaseColor.png" if use_ranger else "characters/T_Peasant_2_BaseColor.png"
		outfit_alt_tex = AssetLib.load_texture(alt_tex_path)

	# 2. Teñir ropa y piel sobre las texturas PBR reales del traje
	for sc in _skeleton.get_children():
		if not (sc is MeshInstance3D):
			continue
		var smi := sc as MeshInstance3D
		var nm := smi.name.to_lower()
		# Capucha incluida en el traje Ranger: mostrar solo si lleva capucha/casco o es arquero/explorador
		if nm.find("head_hood") != -1:
			smi.visible = (_hat_style in ["hood", "helmet", "inquisitor"] or _helmet_tier >= 1)
			if smi.visible:
				_tint_textured_mesh(smi, _tunic_color.darkened(0.15), 0.75, 0.15 if _helmet_tier == 0 else 0.65, outfit_alt_tex)
			continue
		if nm.find("pauldron") != -1:
			smi.visible = (_chest_tier >= 1 or _hat_style in ["helmet", "inquisitor", "crown"])
			if smi.visible:
				var p_col := Color(0.72, 0.75, 0.80) if _chest_tier >= 2 else _tunic_color.lightened(0.12)
				_tint_textured_mesh(smi, p_col, 0.45, 0.55 if _chest_tier >= 2 else 0.15, outfit_alt_tex)
			continue
		if nm.find("body") != -1 and nm.find("belt") == -1:
			var body_col := _tunic_color.lerp(Color(1, 1, 1), 0.25)
			if _apron_color.a > 0.1:
				body_col = body_col.lerp(_apron_color, 0.22)
			if _chest_tier == 2:
				body_col = Color(0.68, 0.71, 0.76)
			elif _chest_tier >= 3:
				body_col = Color(0.84, 0.86, 0.92)
			_tint_textured_mesh(smi, body_col, 0.78 if _chest_tier < 2 else 0.35, 0.05 if _chest_tier < 2 else 0.70, outfit_alt_tex)
		elif nm.find("legs") != -1:
			var leg_col := (_tunic_color.darkened(0.18) if _has_skirt else _pants_color).lerp(Color(1, 1, 1), 0.28)
			if _legs_tier >= 2:
				leg_col = Color(0.65, 0.68, 0.74)
			_tint_textured_mesh(smi, leg_col, 0.82, 0.05 if _legs_tier < 2 else 0.60, outfit_alt_tex)
		elif nm.find("feet") != -1:
			var boot_col := Color(0.32, 0.22, 0.15) if _boots_tier < 2 else Color(0.58, 0.60, 0.66)
			_tint_textured_mesh(smi, boot_col, 0.75, 0.08 if _boots_tier < 2 else 0.62, outfit_alt_tex)
		elif nm.find("arms") != -1 and nm.find("bracer") == -1:
			_tint_arms_mesh(smi, (_cape_color if _has_cape else _tunic_color).lerp(Color(1, 1, 1), 0.30), outfit_alt_tex)

	# 3. Peinado y barba 3D reales anclados al esqueleto
	if _helmet_tier == 0 and not (_hat_style in ["hood", "helmet"]):
		var hair_gltf := _pick_real_hair_file()
		if not hair_gltf.is_empty():
			_attach_rigged_part_to_skeleton(hair_gltf, _hair_color.lerp(Color(1, 1, 1), 0.18))
	if _has_beard and not _is_female and not _is_child:
		_attach_rigged_part_to_skeleton("characters/Hair_Beard.gltf", _hair_color.lerp(Color(1, 1, 1), 0.15))

	# 4. BoneAttachments para cabeza (sombreros/cascos), mano derecha (armas/herramientas), mano izquierda y prótesis
	var head_att := BoneAttachment3D.new()
	head_att.name = "HeadAttachment"
	head_att.bone_name = "Head"
	_skeleton.add_child(head_att)

	hat_root = Node3D.new()
	hat_root.name = "HatRoot"
	hat_root.position = Vector3(0.0, 0.14, 0.0)
	head_att.add_child(hat_root)
	_build_real_hat_or_helmet(hat_root)

	var hand_r_att := BoneAttachment3D.new()
	hand_r_att.name = "HandRAttachment"
	hand_r_att.bone_name = "hand_r"
	_skeleton.add_child(hand_r_att)

	tool_r_root = Node3D.new()
	tool_r_root.name = "ToolRRoot"
	hand_r_att.add_child(tool_r_root)

	var hand_l_att := BoneAttachment3D.new()
	hand_l_att.name = "HandLAttachment"
	hand_l_att.bone_name = "hand_l"
	_skeleton.add_child(hand_l_att)

	tool_l_root = Node3D.new()
	tool_l_root.name = "ToolLRoot"
	hand_l_att.add_child(tool_l_root)

	# 5. Prótesis mecánicas visibles sobre el hueso correspondiente
	if (_missing_arm_r or _prosthetic_arm_r):
		var arm_att := BoneAttachment3D.new()
		arm_att.name = "ProsthArmAttachment"
		arm_att.bone_name = "lowerarm_r"
		_skeleton.add_child(arm_att)
		if _prosthetic_arm_r:
			var p_mat := _make_mat(Color(0.74, 0.50, 0.24), 0.30, 0.85)
			var s_mat := _make_mat(Color(0.55, 0.58, 0.64), 0.28, 0.88)
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.055
			cyl.bottom_radius = 0.048
			cyl.height = 0.28
			_add_part(arm_att, cyl, p_mat, Vector3(0.0, 0.12, 0.0))
			var ring := CylinderMesh.new()
			ring.top_radius = 0.065
			ring.bottom_radius = 0.065
			ring.height = 0.04
			_add_part(arm_att, ring, s_mat, Vector3(0.0, 0.04, 0.0))

	if (_missing_leg_r or _prosthetic_leg_r):
		var leg_att := BoneAttachment3D.new()
		leg_att.name = "ProsthLegAttachment"
		leg_att.bone_name = "calf_r"
		_skeleton.add_child(leg_att)
		if _prosthetic_leg_r:
			var p_mat := _make_mat(Color(0.74, 0.50, 0.24), 0.30, 0.85)
			var s_mat := _make_mat(Color(0.55, 0.58, 0.64), 0.28, 0.88)
			var rod := CylinderMesh.new()
			rod.top_radius = 0.055
			rod.bottom_radius = 0.042
			rod.height = 0.38
			_add_part(leg_att, rod, s_mat, Vector3(0.0, 0.18, 0.0))
			var knee := SphereMesh.new()
			knee.radius = 0.068
			knee.height = 0.136
			_add_part(leg_att, knee, p_mat, Vector3(0.0, 0.02, 0.0))

	if _anim_player != null:
		_apply_real_animation()
	else:
		_apply_skeleton_pose(0.0)
	return true


func _pick_real_hair_file() -> String:
	if _hair_style in ["bald", "none"]:
		return ""
	match _hair_style:
		"bun", "buns":
			return "characters/Hair_Buns.gltf"
		"buzzed_female", "short_female":
			return "characters/Hair_BuzzedFemale.gltf"
		"long", "ponytail":
			return "characters/Hair_Long.gltf"
		"tonsure", "buzzed":
			return "characters/Hair_Buzzed.gltf"
		"parted":
			return "characters/Hair_SimpleParted.gltf"
		"short":
			return "characters/Hair_BuzzedFemale.gltf" if _is_female else "characters/Hair_SimpleParted.gltf"
		_:
			return "characters/Hair_Long.gltf" if _is_female else "characters/Hair_SimpleParted.gltf"


func _attach_rigged_part_to_skeleton(rel_path: String, tint_col: Color) -> void:
	var tmpl := AssetLib.load_gltf_template(rel_path)
	if tmpl == null or _skeleton == null:
		return
	var hair_alt_tex: Texture2D = null
	if _hair_tex_variant == 1:
		hair_alt_tex = AssetLib.load_texture("characters/T_Hair_2_BaseColor.png")
	var src_skel := tmpl.find_child("Skeleton3D", true, false) as Skeleton3D
	if src_skel != null:
		for c in src_skel.get_children():
			if c is MeshInstance3D:
				var dup := c.duplicate() as MeshInstance3D
				dup.skeleton = NodePath("..")
				_tint_textured_mesh(dup, tint_col, 0.85, 0.0, hair_alt_tex)
				_skeleton.add_child(dup)


func _apply_skin_material_override(mi: MeshInstance3D) -> void:
	if mi.mesh == null or mi.mesh.get_surface_count() == 0:
		return
	var orig := mi.mesh.surface_get_material(0)
	var sm := StandardMaterial3D.new()
	if orig is StandardMaterial3D:
		sm = (orig as StandardMaterial3D).duplicate() as StandardMaterial3D
	var light_skin := not _is_dark_skin and (_skin_color.r + _skin_color.g + _skin_color.b) > 2.1
	var tex_file := ""
	if _is_female:
		tex_file = "characters/T_Superhero_Female_Light_BaseColor.png" if light_skin else "characters/T_Female_Simple_Dark_BaseColor.png"
	else:
		tex_file = "characters/T_Superhero_Male_Ligh.png" if light_skin else "characters/T_Superhero_Simple_Dark_BaseColor.png"
	var stex := AssetLib.load_texture(tex_file)
	if stex != null:
		sm.albedo_texture = stex
	sm.albedo_color = _skin_color.lerp(Color.WHITE, 0.55 if light_skin else 0.72)
	sm.roughness = 0.82
	mi.set_surface_override_material(0, sm)


func _tint_textured_mesh(mi: MeshInstance3D, tint: Color, rough: float = 0.80, metal: float = 0.05, override_tex: Texture2D = null) -> void:
	if mi.mesh == null:
		return
	for s in range(mi.mesh.get_surface_count()):
		var orig := mi.mesh.surface_get_material(s)
		var sm := StandardMaterial3D.new()
		if orig is StandardMaterial3D:
			sm = (orig as StandardMaterial3D).duplicate() as StandardMaterial3D
		if override_tex != null:
			sm.albedo_texture = override_tex
		sm.albedo_color = tint
		sm.roughness = rough
		sm.metallic = metal
		mi.set_surface_override_material(s, sm)


func _tint_arms_mesh(mi: MeshInstance3D, sleeve_tint: Color, override_tex: Texture2D = null) -> void:
	if mi.mesh == null:
		return
	for s in range(mi.mesh.get_surface_count()):
		var orig := mi.mesh.surface_get_material(s)
		var sm := StandardMaterial3D.new()
		if orig is StandardMaterial3D:
			sm = (orig as StandardMaterial3D).duplicate() as StandardMaterial3D
		var mname := sm.resource_name.to_lower()
		if mname.find("regular") != -1 or mname.find("superhero") != -1:
			var light_skin := not _is_dark_skin and (_skin_color.r + _skin_color.g + _skin_color.b) > 2.1
			var tex_file := ("characters/T_Superhero_Female_Light_BaseColor.png" if light_skin else "characters/T_Regular_Female_Dark_BaseColor.png") if _is_female else ("characters/T_Superhero_Male_Ligh.png" if light_skin else "characters/T_Regular_Male_Dark_BaseColor.png")
			var stex := AssetLib.load_texture(tex_file)
			if stex != null:
				sm.albedo_texture = stex
			sm.albedo_color = _skin_color.lerp(Color.WHITE, 0.55 if light_skin else 0.72)
		else:
			if override_tex != null:
				sm.albedo_texture = override_tex
			sm.albedo_color = sleeve_tint
		mi.set_surface_override_material(s, sm)


func _build_real_hat_or_helmet(parent: Node3D) -> void:
	var cloth_dark := _make_mat(_tunic_color.darkened(0.25), 0.85, 0.0)
	var gold_mat := _make_mat(Color(0.92, 0.76, 0.22), 0.28, 0.85)
	if _hat_style == "crown":
		var crown := CylinderMesh.new()
		crown.top_radius = 0.11
		crown.bottom_radius = 0.095
		crown.height = 0.075
		_add_part(parent, crown, gold_mat, Vector3(0.0, 0.04, 0.0))
	elif _hat_style == "straw":
		var straw_mat := _make_mat(Color(0.86, 0.74, 0.42), 0.90, 0.0)
		var brim := CylinderMesh.new()
		brim.top_radius = 0.22
		brim.bottom_radius = 0.23
		brim.height = 0.02
		_add_part(parent, brim, straw_mat, Vector3(0.0, 0.02, 0.0))
		var top := CylinderMesh.new()
		top.top_radius = 0.10
		top.bottom_radius = 0.12
		top.height = 0.08
		_add_part(parent, top, straw_mat, Vector3(0.0, 0.06, 0.0))
	elif _hat_style == "chef":
		var white_mat := _make_mat(Color(0.96, 0.95, 0.92), 0.85, 0.0)
		var puff := SphereMesh.new()
		puff.radius = 0.13
		puff.height = 0.22
		_add_part(parent, puff, white_mat, Vector3(0.0, 0.08, 0.0))
	elif _hat_style == "inquisitor":
		var black_mat := _make_mat(Color(0.14, 0.12, 0.15), 0.80, 0.1)
		var brim := CylinderMesh.new()
		brim.top_radius = 0.22
		brim.bottom_radius = 0.22
		brim.height = 0.02
		_add_part(parent, brim, black_mat, Vector3(0.0, 0.02, 0.0))
		var cone := CylinderMesh.new()
		cone.top_radius = 0.06
		cone.bottom_radius = 0.11
		cone.height = 0.16
		_add_part(parent, cone, black_mat, Vector3(0.0, 0.10, 0.0))
	elif _hat_style == "goggles":
		var brass_mat := _make_mat(Color(0.76, 0.56, 0.22), 0.30, 0.80)
		var strap := BoxMesh.new()
		strap.size = Vector3(0.19, 0.035, 0.19)
		_add_part(parent, strap, cloth_dark, Vector3(0.0, 0.0, 0.0))
		var lens := CylinderMesh.new()
		lens.top_radius = 0.032
		lens.bottom_radius = 0.032
		lens.height = 0.03
		_add_part(parent, lens, brass_mat, Vector3(-0.045, 0.0, 0.095), Vector3(90, 0, 0))
		_add_part(parent, lens, brass_mat, Vector3(0.045, 0.0, 0.095), Vector3(90, 0, 0))


func _rebuild_procedural_fallback() -> void:
	pelvis.visible = true
	for node in [pelvis, torso_pivot, head_pivot, hair_root, hat_root, beard_root, armor_torso_root, cape_root, skirt_root, arm_l_pivot, forearm_l_pivot, arm_r_pivot, forearm_r_pivot, leg_l_pivot, shin_l_pivot, leg_r_pivot, shin_r_pivot]:
		if node != null:
			_clear_tagged(node)
	var skin_mat := _make_mat(_skin_color, 0.78, 0.0)
	var tunic_mat := _make_mat(_tunic_color, 0.85, 0.0)
	var chest_mesh := BoxMesh.new()
	chest_mesh.size = Vector3(0.38, 0.44, 0.22)
	_add_part(torso_pivot, chest_mesh, tunic_mat, Vector3(0.0, 0.28, 0.0))
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.17
	head_mesh.height = 0.34
	_add_part(head_pivot, head_mesh, skin_mat, Vector3(0.0, 0.16, 0.0))


func _rebuild_tools() -> void:
	if tool_r_root == null or tool_l_root == null:
		return
	for c in tool_r_root.get_children():
		c.queue_free()
	for c in tool_l_root.get_children():
		c.queue_free()
	muzzle_flash_node = null

	if _missing_arm_r and not _prosthetic_arm_r:
		return

	# Si tenemos los modelos 3D reales en curated_3d, usar las armas/herramientas reales
	if AssetLib.has_curated_assets() and _using_real_mesh:
		_build_real_curated_tools()
		return


func _build_real_curated_tools() -> void:
	# En el esqueleto Quaternius, hand_r tiene su eje +Y a lo largo de los dedos y +Z hacia delante.
	# Con (0, 90, 90), el eje +Y del modelo (asta/hoja desde la empuñadura) apunta hacia +Z de hand_r (delante/arriba)
	# y el eje +X del modelo (filo de hacha/hoz/pico o cañón de arcabuz) apunta hacia +Y de hand_r (frente de golpeo).
	var weapon_Holder := Node3D.new()
	weapon_Holder.name = "WeaponHolder"
	weapon_Holder.position = Vector3(0.0, 0.08, 0.02)
	weapon_Holder.rotation_degrees = Vector3(0.0, 90.0, 90.0)
	tool_r_root.add_child(weapon_Holder)

	var model_node: Node3D = null
	match _weapon_id:
		"sword", "blade":
			model_node = AssetLib.instantiate_model("weapons/Sword.obj", Vector3.ZERO, 0.92, true, true)
		"dagger", "knife":
			model_node = AssetLib.instantiate_model("weapons/Dagger.obj", Vector3.ZERO, 0.52, true, true)
		"hammer", "sledgehammer", "smith_hammer":
			model_node = AssetLib.instantiate_model("weapons/Hammer_Small.obj", Vector3.ZERO, 0.68, true, true)
		"axe", "wood_axe":
			model_node = AssetLib.instantiate_model("weapons/Axe.obj", Vector3.ZERO, 0.78, true, true)
		"pickaxe":
			model_node = AssetLib.instantiate_model("props/Pickaxe_Bronze.gltf", Vector3.ZERO, 0.78, true, true)
		"bow":
			model_node = AssetLib.instantiate_model("weapons/Bow_Wooden.obj", Vector3.ZERO, 0.95, true, false)
			if model_node != null:
				model_node.rotation_degrees = Vector3(0.0, 180.0, 0.0)
		"scythe", "sickle", "hoe":
			model_node = AssetLib.instantiate_model("weapons/Scythe.obj", Vector3.ZERO, 1.05, true, true)
		"flintlock", "pistol", "arquebus", "rifle":
			var is_rf: bool = (_weapon_id == "rifle")
			model_node = AssetLib.instantiate_model("weapons/Pistol_1.obj", Vector3.ZERO, 0.24 if is_rf else 0.20, true, false)
			if is_rf:
				var rf_barrel := BoxMesh.new()
				rf_barrel.size = Vector3(0.38, 0.026, 0.026)
				_add_part(weapon_Holder, rf_barrel, _make_mat(Color(0.22, 0.24, 0.27), 0.35, 0.8), Vector3(0.22, 0.075, 0.0))
			var flash_mat := _make_mat(Color(1.0, 0.82, 0.25), 0.1, 0.0, Color(1.0, 0.65, 0.15, 1.0))
			var flash_sphere := SphereMesh.new()
			flash_sphere.radius = 0.06
			flash_sphere.height = 0.12
			muzzle_flash_node = _add_part(weapon_Holder, flash_sphere, flash_mat, Vector3(0.43 if is_rf else 0.22, 0.075, 0.0))
			muzzle_flash_node.visible = false
		"book", "ledger":
			model_node = AssetLib.instantiate_model("props/Book_5.gltf", Vector3(0.18, 0.04, 0.22), -1.0, true, false)
		"mug", "chalice":
			model_node = AssetLib.instantiate_model("props/Mug.gltf", Vector3.ZERO, 0.26, true, true)
		"crate", "sack":
			model_node = AssetLib.instantiate_model("props/Bag.gltf", Vector3.ZERO, 0.42, true, true)
		"lantern":
			model_node = AssetLib.instantiate_model("props/Lantern_Wall.gltf", Vector3.ZERO, 0.38, true, true)
			if model_node != null:
				model_node.rotation_degrees = Vector3(0.0, 0.0, 90.0)
				model_node.position = Vector3(0.28, 0.0, 0.0)
		"watering_can":
			model_node = AssetLib.instantiate_model("props/Bucket_Metal.gltf", Vector3.ZERO, 0.34, true, true)
			if model_node != null:
				model_node.rotation_degrees = Vector3(0.0, 0.0, 90.0)
				model_node.position = Vector3(0.26, 0.0, 0.0)
		"fishing_rod", "staff", "guard_spear", "spear":
			model_node = AssetLib.instantiate_model("weapons/Spear.obj", Vector3.ZERO, 1.25, true, true)

	if model_node != null:
		weapon_Holder.add_child(model_node)

	var offhand_id := str(get_meta("offhand_id", "none")) if has_meta("offhand_id") else "none"
	if _carrying_lantern and offhand_id == "none":
		offhand_id = "lantern"
	if offhand_id != "none" and offhand_id != "":
		var l_holder := Node3D.new()
		l_holder.position = Vector3(0.0, 0.08, 0.02)
		l_holder.rotation_degrees = Vector3(0.0, -90.0, -90.0)
		tool_l_root.add_child(l_holder)
		var l_node: Node3D = null
		match offhand_id:
			"lantern":
				l_node = AssetLib.instantiate_model("props/Lantern_Wall.gltf", Vector3.ZERO, 0.35, true, true)
				if l_node != null:
					l_node.rotation_degrees = Vector3(0.0, 0.0, -90.0)
					l_node.position = Vector3(-0.28, 0.0, 0.0)
			"shield":
				l_node = AssetLib.instantiate_model("weapons/Shield_Heater.obj", Vector3.ZERO, 0.58, true, false)
			"book":
				l_node = AssetLib.instantiate_model("props/Book_5.gltf", Vector3(0.18, 0.04, 0.22), -1.0, true, false)
			"crutch":
				l_node = AssetLib.instantiate_model("weapons/Spear.obj", Vector3.ZERO, 1.05, true, true)
			"torch":
				l_node = AssetLib.instantiate_model("props/Torch_Metal.gltf", Vector3.ZERO, 0.45, true, true)
		if l_node != null:
			l_holder.add_child(l_node)


func set_facing_direction(dir_2d: Vector2) -> void:
	if dir_2d.length_squared() < 0.001:
		return
	_target_yaw = atan2(dir_2d.x, dir_2d.y)


func update_pose(delta: float, state: Dictionary) -> void:
	var facing_v: Vector2 = state.get("facing", Vector2.DOWN)
	if facing_v.length_squared() > 0.001:
		set_facing_direction(facing_v)
	var spd: float = float(state.get("speed_ratio", 0.0))
	var atk_prog: float = float(state.get("attack_progress", 0.0))
	var bow_dr: float = float(state.get("bow_draw", 0.0))
	_is_rolling = bool(state.get("is_rolling", false))
	_roll_progress = float(state.get("roll_progress", 0.0))
	_is_parrying = bool(state.get("is_parrying", false))
	if atk_prog > 0.01:
		_attack_swing_t = maxf(_attack_swing_t, (1.0 - atk_prog) * 0.34)
	elif bow_dr > 0.05:
		_attack_swing_t = maxf(_attack_swing_t, 0.18)

	var st_enum: int = AnimState.IDLE
	if bool(state.get("is_dead", false)) or bool(state.get("is_downed", false)):
		st_enum = AnimState.KO
	elif bool(state.get("is_sleeping", false)):
		st_enum = AnimState.SLEEP
	elif _is_rolling:
		st_enum = AnimState.ROLL
	elif _is_parrying:
		st_enum = AnimState.BLOCK
	elif bool(state.get("is_mounted", false)) and atk_prog <= 0.01 and bow_dr <= 0.05:
		st_enum = AnimState.MOUNTED
	elif _weapon_id in ["flintlock", "pistol", "arquebus", "rifle"] and (atk_prog > 0.01 or _muzzle_flash_t > 0.0):
		st_enum = AnimState.AIM_GUN
	elif atk_prog > 0.01 or bow_dr > 0.05 or bool(state.get("is_fighting", false)):
		st_enum = AnimState.ATTACK
	elif bool(state.get("is_working", false)):
		st_enum = AnimState.WORK
	elif spd > 0.08:
		st_enum = AnimState.WALK

	update_animation(delta, st_enum, maxf(0.15, spd))


func update_animation(delta: float, state: int, speed_ratio: float = 1.0) -> void:
	_anim_state = state
	_speed_ratio = speed_ratio
	_anim_time += delta * maxf(0.4, speed_ratio)

	var diff := wrapf(_target_yaw - _facing_yaw, -PI, PI)
	_facing_yaw = wrapf(_facing_yaw + diff * minf(1.0, delta * 14.0), -PI, PI)
	rotation.y = _facing_yaw

	if _muzzle_flash_t > 0.0:
		_muzzle_flash_t = maxf(0.0, _muzzle_flash_t - delta)
		if _muzzle_flash_t <= 0.0 and muzzle_flash_node != null and is_instance_valid(muzzle_flash_node):
			muzzle_flash_node.visible = false

	if _attack_swing_t > 0.0:
		_attack_swing_t = maxf(0.0, _attack_swing_t - delta)

	if _using_real_mesh and _skeleton != null and is_instance_valid(_skeleton):
		if _anim_player != null and is_instance_valid(_anim_player):
			_apply_real_animation()
		else:
			_apply_skeleton_pose(delta)


static func _get_anim_lib(path: String) -> AnimationLibrary:
	if _anim_lib_cache.has(path):
		return _anim_lib_cache[path]
	var lib: AnimationLibrary = null
	if ResourceLoader.exists(path):
		lib = load(path) as AnimationLibrary
	_anim_lib_cache[path] = lib
	return lib


func _setup_anim_player(char_root: Node3D) -> void:
	_anim_player = null
	_current_clip = ""
	var lib := _get_anim_lib(ANIM_LIB_FEMALE if _is_female else ANIM_LIB_MALE)
	if lib == null:
		return
	var ap := AnimationPlayer.new()
	ap.name = "CharAnimPlayer"
	char_root.add_child(ap)
	ap.root_node = NodePath("..")
	ap.add_animation_library("", lib)
	_anim_player = ap


## Elige la animación real según el estado. Devuelve [clip, velocidad].
func _pick_clip() -> Array:
	if _is_rolling or _anim_state == AnimState.ROLL:
		return ["roll", 1.85]
	if _is_parrying or _anim_state == AnimState.BLOCK:
		return ["block", 1.25]
	var gun := _weapon_id in ["flintlock", "pistol", "arquebus", "rifle"]
	if _attack_swing_t > 0.0:
		if gun:
			return ["shoot", 1.0]
		if _weapon_id == "none" or _weapon_id.is_empty():
			return ["punch", 1.4]
		return ["sword", 1.6]
	match _anim_state:
		AnimState.WALK:
			var real_px_s: float = _speed_ratio * 110.0
			var scale_k: float = 0.72 if _is_child else 1.0
			if _speed_ratio > 1.35:
				return ["run", clampf(real_px_s / (RUN_BASE_PX_S * scale_k), 0.6, 4.0)]
			return ["walk", clampf(real_px_s / (WALK_BASE_PX_S * scale_k), 0.5, 5.5)]
		AnimState.WORK:
			match _weapon_id:
				"scythe", "sickle", "hoe":
					return ["harvest", 1.0]
				"bucket", "watering_can":
					return ["water", 1.0]
				"book", "mug", "bag":
					return ["kneel_fix", 1.0]
			return ["chop", 1.0]
		AnimState.CARRY:
			var carry_px_s: float = _speed_ratio * 110.0
			var carry_k: float = 0.72 if _is_child else 1.0
			return ["carry", clampf(carry_px_s / (CARRY_BASE_PX_S * carry_k), 0.5, 5.5)]
		AnimState.PRAY:
			return ["crouch", 0.6]
		AnimState.SLEEP:
			return ["lay", 0.0]
		AnimState.MOUNTED:
			return ["sit", 1.0]
		AnimState.KO:
			return ["death", 1.0]
		AnimState.AIM_GUN:
			return ["aim", 1.0]
	if _carrying_lantern:
		return ["lantern", 1.0]
	if gun:
		return ["aim", 0.0]
	return ["idle", 1.0]


func _apply_real_animation() -> void:
	var char_root := get_node_or_null("RealCharRoot") as Node3D
	if char_root != null:
		char_root.rotation_degrees = Vector3.ZERO
		char_root.position = Vector3.ZERO
	var pick := _pick_clip()
	var clip: String = pick[0]
	var spd: float = pick[1]
	if not _anim_player.has_animation(clip):
		clip = "idle"
	if clip != _current_clip:
		_current_clip = clip
		_anim_player.play(clip, 0.18)
		if clip == "lay":
			_anim_player.seek(0.0, true)
	_anim_player.speed_scale = spd


func _set_bone_delta_euler(bname: String, rx_deg: float, ry_deg: float, rz_deg: float) -> void:
	if not _bone_idx.has(bname):
		return
	var idx: int = _bone_idx[bname]
	var rest_q: Quaternion = _bone_rest_q[bname]
	var dq := Quaternion.from_euler(Vector3(deg_to_rad(rx_deg), deg_to_rad(ry_deg), deg_to_rad(rz_deg)))
	_skeleton.set_bone_pose_rotation(idx, rest_q * dq)


func _apply_skeleton_pose(_delta: float) -> void:
	if _skeleton == null:
		return
	var char_root := get_node_or_null("RealCharRoot") as Node3D
	if char_root != null:
		char_root.rotation_degrees = Vector3.ZERO
		char_root.position = Vector3.ZERO

	# Postura base relajada bajando los brazos desde la T-pose:
	# En el esqueleto Quaternius:
	# - upperarm_l baja hacia el costado con rz = -72° y balancea adelante/atrás con ry
	# - upperarm_r baja hacia el costado con rz = +72° y balancea adelante/atrás con ry
	# - thigh_l / thigh_r y calf_l / calf_r rotan adelante/atrás con rx
	var ul_rz := -72.0
	var ur_rz := 72.0
	var ul_ry := 0.0
	var ur_ry := 0.0
	var ll_rz := -12.0
	var lr_rz := 12.0
	var tl_rx := 0.0
	var tr_rx := 0.0
	var cl_rx := 0.0
	var cr_rx := 0.0
	var spine_rx := 0.0
	var spine_ry := 0.0
	var head_rx := 0.0

	match _anim_state:
		AnimState.IDLE:
			var breath := sin(_anim_time * 2.4)
			spine_rx = breath * 1.8
			ul_rz = -71.0 - breath * 1.5
			ur_rz = 71.0 + breath * 1.5
			if _carrying_lantern:
				ul_ry = -35.0
				ll_rz = -40.0

		AnimState.WALK:
			var w := _anim_time * 8.5
			var swing := sin(w)
			tl_rx = swing * 32.0
			tr_rx = -swing * 32.0
			cl_rx = maxf(0.0, -swing) * 28.0
			cr_rx = maxf(0.0, swing) * 28.0
			ul_ry = swing * 24.0
			ur_ry = -swing * 24.0
			spine_rx = 4.0
			spine_ry = swing * 4.0
			if _carrying_lantern:
				ul_ry = -40.0
				ll_rz = -35.0

		AnimState.WORK:
			var wk := sin(_anim_time * 7.5)
			spine_rx = 12.0 + wk * 6.0
			ur_rz = 42.0
			ur_ry = -48.0 + wk * 38.0
			lr_rz = 28.0
			ul_ry = -18.0

		AnimState.CARRY:
			ul_rz = -48.0
			ur_rz = 48.0
			ul_ry = -45.0
			ur_ry = 45.0
			ll_rz = -35.0
			lr_rz = 35.0
			var cw := sin(_anim_time * 7.0)
			tl_rx = cw * 22.0
			tr_rx = -cw * 22.0

		AnimState.PRAY:
			tl_rx = -55.0
			tr_rx = -55.0
			cl_rx = 95.0
			cr_rx = 95.0
			head_rx = 18.0
			ul_rz = -52.0
			ur_rz = 52.0
			ul_ry = -42.0
			ur_ry = 42.0
			ll_rz = -45.0
			lr_rz = 45.0
			if char_root != null:
				char_root.position.y = -0.26

		AnimState.SLEEP, AnimState.KO:
			if char_root != null:
				char_root.rotation_degrees.x = -88.0
				char_root.position = Vector3(0.0, 0.14, 0.55)

		AnimState.MOUNTED:
			tl_rx = -82.0
			tr_rx = -82.0
			cl_rx = 82.0
			cr_rx = 82.0
			ul_rz = -58.0
			ur_rz = 58.0
			ul_ry = -24.0
			ur_ry = 24.0
			ll_rz = -28.0
			lr_rz = 28.0

		AnimState.AIM_GUN:
			ur_rz = 15.0
			ur_ry = 72.0
			lr_rz = 5.0
			ul_rz = -55.0
			ul_ry = -30.0

		AnimState.ROLL:
			tl_rx = -65.0
			tr_rx = -65.0
			cl_rx = 110.0
			cr_rx = 110.0
			spine_rx = 45.0
			if char_root != null:
				char_root.position.y = -0.22
				char_root.rotation_degrees.x = _roll_progress * 360.0

		AnimState.BLOCK:
			ur_rz = 25.0
			ur_ry = 55.0
			lr_rz = 65.0
			ul_rz = -35.0
			ul_ry = -45.0
			ll_rz = -55.0
			spine_rx = 8.0

	if _attack_swing_t > 0.0:
		var p := 1.0 - (_attack_swing_t / 0.34)
		var arc := sin(p * PI)
		if _weapon_id in ["flintlock", "pistol", "arquebus", "rifle"]:
			ur_rz = 18.0
			ur_ry = 75.0 - arc * 22.0
		else:
			ur_rz = 35.0
			ur_ry = 65.0 - arc * 125.0
			lr_rz = 25.0
			spine_ry = -arc * 18.0

	_set_bone_delta_euler("spine_01", spine_rx, spine_ry, 0.0)
	_set_bone_delta_euler("Head", head_rx, 0.0, 0.0)
	_set_bone_delta_euler("upperarm_l", 0.0, ul_ry, ul_rz)
	_set_bone_delta_euler("lowerarm_l", 0.0, 0.0, ll_rz)
	_set_bone_delta_euler("upperarm_r", 0.0, ur_ry, ur_rz)
	_set_bone_delta_euler("lowerarm_r", 0.0, 0.0, lr_rz)
	_set_bone_delta_euler("thigh_l", tl_rx, 0.0, 0.0)
	_set_bone_delta_euler("calf_l", cl_rx, 0.0, 0.0)
	_set_bone_delta_euler("thigh_r", tr_rx, 0.0, 0.0)
	_set_bone_delta_euler("calf_r", cr_rx, 0.0, 0.0)
