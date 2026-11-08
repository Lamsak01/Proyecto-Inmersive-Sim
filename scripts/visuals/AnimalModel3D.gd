extends Node2D

## Modelo 3D de un animal (2026-11-05): pone un modelo dentro del escenario 3D, encima del animal 2D.
## Solo es visual: no toca su comportamiento. El modelo sigue la posición del animal y mira hacia donde camina.
## Si el modelo trae animaciones (.glb de Quaternius) anda, galopa, está quieto o pace según su velocidad, y hace
## «Death» cuando el sprite 2D se tumba (cadáver o aturdido). Un modelo sin animaciones (.obj) se tumba de lado.
## En modo headless (pruebas) no hace nada.
## Con F10 (vista 2D) se esconde y vuelve el sprite.

const CharacterAvatar3DScript = preload("res://scripts/visuals/CharacterAvatar3D.gd")
const AssetLib = preload("res://scripts/visuals/AssetLibrary3D.gd")

## Igual que en el escenario 3D: 1 px del mapa = 0,02 unidades 3D.
const WORLD_SCALE: float = 0.02

var model_rel: String = ""
var height_px: float = 12.0
## Los pies del modelo quedan estos píxeles por debajo del centro del animal 2D.
var foot_offset_px: float = 4.0

var _entity: Node2D = null
var _stage: Node = null
var _holder: Node3D = null
var _yaw: Node3D = null
var _model: Node3D = null
var _cur_yaw: float = 0.0
var _last_pos: Vector2 = Vector2.INF
var _sprite_hidden: bool = false
var _disabled: bool = false
var _anim: AnimationPlayer = null
var _speed: float = 0.0
var _still_time: float = 0.0
var _cur_anim: String = ""
## Velocidad (px/s) a la que el paso «Walk» encaja con el suelo; por encima de run_px_s galopa.
var walk_px_s: float = 28.0
var run_px_s: float = 70.0
var tint_color: Color = Color.WHITE
var dim_omni_light: bool = false


static func attach(entity: Node2D, rel_path: String, h_px: float, foot_px: float, p_tint: Color = Color.WHITE, p_dim_light: bool = false) -> Node:
	if DisplayServer.get_name() == "headless" or Engine.is_editor_hint() or entity == null:
		return null
	if not AssetLib.has_curated_assets():
		return null
	var n = load("res://scripts/visuals/AnimalModel3D.gd").new()
	n.name = "AnimalModel3D"
	n.model_rel = rel_path
	n.height_px = h_px
	n.foot_offset_px = foot_px
	n.tint_color = p_tint
	n.dim_omni_light = p_dim_light
	entity.add_child(n)
	return n


## Hacia dónde mira el modelo, en coordenadas del mapa (el modelo mira hacia +Z = «abajo» con giro 0).
func get_facing_2d() -> Vector2:
	return Vector2(sin(_cur_yaw), cos(_cur_yaw))


func set_model_config(rel_path: String, h_px: float) -> void:
	if model_rel == rel_path and is_equal_approx(height_px, h_px):
		return
	model_rel = rel_path
	height_px = h_px
	_disabled = false
	if _holder != null and is_instance_valid(_holder):
		_holder.queue_free()
	_holder = null


func _ready() -> void:
	_entity = get_parent() as Node2D
	_cur_yaw = randf_range(0.0, TAU)


func _exit_tree() -> void:
	if _holder != null and is_instance_valid(_holder):
		_holder.queue_free()
	_holder = null


func _attach_to_stage() -> bool:
	var st: Node = CharacterAvatar3DScript._find_stage(get_tree())
	if st == null:
		return false
	var root3d: Node3D = st.get("stage_root_3d")
	if root3d == null or not is_instance_valid(root3d):
		return false
	var chars := root3d.get_node_or_null("Characters3D") as Node3D
	if chars == null:
		chars = Node3D.new()
		chars.name = "Characters3D"
		root3d.add_child(chars)
	var ws: float = WORLD_SCALE
	var cos_p: float = float(st.get("_cos_p"))
	var fit_h: float = maxf(0.05, height_px * ws)
	var model: Node3D = null
	if model_rel == "procedural:chicken":
		model = _build_procedural_chicken(fit_h)
	else:
		model = AssetLib.instantiate_model(model_rel, Vector3.ZERO, fit_h, true, true)
	if model == null:
		_disabled = true
		return false
	_stage = st
	_holder = Node3D.new()
	_holder.name = "Animal_" + str(_entity.name)
	# Igual que los vecinos: el escenario estira la altura (1/cos del ángulo de cámara) para cuadrar con el mapa 2D.
	_holder.scale = Vector3(1.0, 1.0 / maxf(0.1, cos_p), 1.0)
	_yaw = Node3D.new()
	_holder.add_child(_yaw)
	_model = model
	_yaw.add_child(_model)
	if tint_color != Color.WHITE:
		_apply_tint_recursive(_model, tint_color)
	if dim_omni_light:
		var omni := OmniLight3D.new()
		omni.name = "DimLanternLight3D"
		omni.light_color = Color(1.0, 0.68, 0.32)
		omni.light_energy = 0.16
		omni.omni_range = 1.2
		omni.position = Vector3(0.0, fit_h * 0.65, 0.0)
		_holder.add_child(omni)
	chars.add_child(_holder)
	_anim = null
	_cur_anim = ""
	var players := _model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim = players[0] as AnimationPlayer
		for an in ["Walk", "Gallop", "Idle", "Idle_2", "Eating"]:
			if _anim.has_animation(an):
				_anim.get_animation(an).loop_mode = Animation.LOOP_LINEAR
		_anim.playback_default_blend_time = 0.2
	return true


func _apply_tint_recursive(node: Node, col: Color) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				var base_mat: Material = mi.get_surface_override_material(s)
				if base_mat == null:
					base_mat = mi.mesh.surface_get_material(s)
				if base_mat is StandardMaterial3D:
					var dup := (base_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
					dup.albedo_color = dup.albedo_color * col
					mi.set_surface_override_material(s, dup)
	for ch in node.get_children():
		_apply_tint_recursive(ch, col)


func _process(delta: float) -> void:
	if _disabled or not is_instance_valid(_entity):
		return
	if _holder == null or not is_instance_valid(_holder) or _holder.is_queued_for_deletion():
		_holder = null
		if not _attach_to_stage():
			return
	var use_3d: bool = CharacterAvatar3DScript.use_3d_characters
	_set_sprite_hidden(use_3d)
	var show: bool = use_3d and _entity.is_visible_in_tree() and _near_camera()
	_holder.visible = show
	if _anim != null:
		_anim.active = show
	if not show:
		_last_pos = Vector2.INF
		return
	var pos: Vector2 = _entity.global_position
	_holder.position = _stage.call("to_3d", pos + Vector2(0.0, foot_offset_px), 0.0)
	# Mira hacia donde camina (los modelos miran hacia +Z, que en el mapa es «hacia abajo»).
	var just_shown: bool = _last_pos == Vector2.INF
	if not just_shown and delta > 0.0:
		var mv: Vector2 = pos - _last_pos
		_speed = lerpf(_speed, mv.length() / delta, clampf(delta * 6.0, 0.0, 1.0))
		if mv.length_squared() > 0.0004:
			var target: float = atan2(mv.x, mv.y)
			_cur_yaw = lerp_angle(_cur_yaw, target, clampf(delta * 8.0, 0.0, 1.0))
	_last_pos = pos
	_yaw.rotation.y = _cur_yaw
	if _stage != null and _stage.has_method("terrain_height_px"):
		var fwd_2d := Vector2(sin(_cur_yaw), cos(_cur_yaw))
		var h_front: float = float(_stage.call("terrain_height_px", pos + fwd_2d * 8.0))
		var h_back: float = float(_stage.call("terrain_height_px", pos - fwd_2d * 8.0))
		var slope_pitch: float = clampf(-atan2(h_front - h_back, 16.0) * 0.65, -0.42, 0.42)
		_yaw.rotation.x = lerpf(_yaw.rotation.x, slope_pitch, clampf(delta * 8.0, 0.0, 1.0))
	# Tumbado de lado si el sprite 2D está tumbado (muerto o aturdido).
	var spr = _entity.get("sprite")
	var lying: bool = spr is Node2D and absf((spr as Node2D).rotation_degrees) > 45.0
	if _anim == null:
		if model_rel == "procedural:chicken" and not lying:
			var hp := _model.get_node_or_null("HeadPivot") as Node3D
			if _speed > 2.0:
				_still_time = 0.0
				var t_w: float = float(Time.get_ticks_msec()) * 0.015 + float(get_instance_id() % 11)
				_model.position.y = absf(sin(t_w)) * height_px * WORLD_SCALE * 0.10
				_model.rotation_degrees.z = sin(t_w) * 5.0
				if hp != null:
					hp.rotation_degrees.x = 10.0
			else:
				_still_time += delta
				_model.position.y = 0.0
				_model.rotation_degrees.z = 0.0
				if hp != null:
					var peck: bool = (int((_still_time + float(get_instance_id() % 7)) * 1.8) % 4) == 2
					hp.rotation_degrees.x = (36.0 + sin(_still_time * 18.0) * 8.0) if peck else 0.0
			return
		_model.rotation_degrees.z = 90.0 if lying else 0.0
		_model.position.y = height_px * WORLD_SCALE * 0.3 if lying else 0.0
		return
	_update_animation(delta, lying, just_shown)


func _build_procedural_chicken(fit_h: float) -> Node3D:
	var root := Node3D.new()
	root.name = "ProceduralChicken3D"
	root.scale = Vector3.ONE * fit_h
	var is_chick: bool = height_px < 7.2
	var mk_mat := func(col: Color) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.roughness = 0.88
		m.metallic = 0.02
		return m
	var m_feather: StandardMaterial3D = mk_mat.call(Color(0.96, 0.86, 0.42) if is_chick else Color(0.95, 0.92, 0.84))
	var m_wing: StandardMaterial3D = mk_mat.call(Color(0.90, 0.76, 0.32) if is_chick else Color(0.84, 0.76, 0.64))
	var m_tail: StandardMaterial3D = mk_mat.call(Color(0.66, 0.30, 0.16))
	var m_comb: StandardMaterial3D = mk_mat.call(Color(0.86, 0.16, 0.16))
	var m_beak: StandardMaterial3D = mk_mat.call(Color(0.94, 0.60, 0.14))
	var m_eye: StandardMaterial3D = mk_mat.call(Color(0.10, 0.10, 0.10))
	var add_box := func(parent: Node3D, pos: Vector3, sz: Vector3, mat: StandardMaterial3D, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = sz
		mi.mesh = bm
		mi.material_override = mat
		mi.position = pos
		mi.rotation_degrees = rot_deg
		parent.add_child(mi)
		return mi
	# Patas y dedos
	add_box.call(root, Vector3(-0.12, 0.15, 0.0), Vector3(0.06, 0.30, 0.06), m_beak)
	add_box.call(root, Vector3(0.12, 0.15, 0.0), Vector3(0.06, 0.30, 0.06), m_beak)
	add_box.call(root, Vector3(-0.12, 0.02, 0.04), Vector3(0.10, 0.04, 0.16), m_beak)
	add_box.call(root, Vector3(0.12, 0.02, 0.04), Vector3(0.10, 0.04, 0.16), m_beak)
	# Cuerpo, pecho, alas y cola
	add_box.call(root, Vector3(0.0, 0.46, -0.02), Vector3(0.46, 0.38, 0.56), m_feather)
	add_box.call(root, Vector3(0.0, 0.48, 0.22), Vector3(0.38, 0.30, 0.16), m_feather)
	add_box.call(root, Vector3(-0.26, 0.47, -0.02), Vector3(0.08, 0.24, 0.36), m_wing)
	add_box.call(root, Vector3(0.26, 0.47, -0.02), Vector3(0.08, 0.24, 0.36), m_wing)
	if not is_chick:
		add_box.call(root, Vector3(0.0, 0.62, -0.32), Vector3(0.18, 0.28, 0.20), m_tail, Vector3(-25.0, 0.0, 0.0))
	# Cabeza articulada (picoteo), pico, cresta, barbilla y ojos
	var head_piv := Node3D.new()
	head_piv.name = "HeadPivot"
	head_piv.position = Vector3(0.0, 0.62, 0.18)
	root.add_child(head_piv)
	add_box.call(head_piv, Vector3(0.0, 0.13, 0.0), Vector3(0.28, 0.26, 0.28), m_feather)
	add_box.call(head_piv, Vector3(0.0, 0.11, 0.19), Vector3(0.12, 0.09, 0.14), m_beak)
	if not is_chick:
		add_box.call(head_piv, Vector3(0.0, 0.30, 0.02), Vector3(0.08, 0.12, 0.22), m_comb)
		add_box.call(head_piv, Vector3(0.0, 0.02, 0.15), Vector3(0.07, 0.10, 0.08), m_comb)
	add_box.call(head_piv, Vector3(-0.145, 0.16, 0.06), Vector3(0.02, 0.05, 0.05), m_eye)
	add_box.call(head_piv, Vector3(0.145, 0.16, 0.06), Vector3(0.02, 0.05, 0.05), m_eye)
	return root


func _update_animation(delta: float, lying: bool, just_shown: bool) -> void:
	if lying:
		if _cur_anim != "Death":
			_play("Death", 1.0)
			# Si ya estaba tumbado antes de verlo, sale ya caído (sin repetir la caída).
			if just_shown:
				_anim.seek(_anim.current_animation_length, true)
		return
	var in_windup: bool = false
	if is_instance_valid(_entity):
		for w_prop in ["_bite_windup_timer", "boar_charge_windup", "boar_melee_windup", "_windup_t"]:
			if w_prop in _entity and float(_entity.get(w_prop)) > 0.0:
				in_windup = true
				break
	if in_windup and _anim.has_animation("Attack"):
		_still_time = 0.0
		_play("Attack", 1.35)
		return
	if _speed > run_px_s:
		_still_time = 0.0
		_play("Gallop", clampf(_speed / (run_px_s * 1.6), 0.7, 1.6))
	elif _speed > 4.0:
		_still_time = 0.0
		_play("Walk", clampf(_speed / walk_px_s, 0.5, 1.8))
	else:
		_still_time += delta
		# Quieto un rato: alterna entre mirar alrededor y pacer (cada ~6 s, distinto en cada animal).
		var phase: int = int((_still_time + float(get_instance_id() % 7)) / 6.0) % 3
		_play("Eating" if phase == 2 and _anim.has_animation("Eating") else "Idle", 1.0)


func _play(an: String, spd: float) -> void:
	if not _anim.has_animation(an):
		return
	_anim.speed_scale = spd
	if _cur_anim != an:
		_cur_anim = an
		_anim.play(an)


func _set_sprite_hidden(want_hidden: bool) -> void:
	if want_hidden == _sprite_hidden:
		return
	var spr = _entity.get("sprite")
	if not (spr is CanvasItem) or not is_instance_valid(spr):
		return
	_sprite_hidden = want_hidden
	(spr as CanvasItem).self_modulate.a = 0.0 if want_hidden else 1.0


func _near_camera() -> bool:
	var vp := get_viewport()
	if vp == null:
		return true
	var cam2d := vp.get_camera_2d()
	if cam2d == null:
		return true
	var center: Vector2 = cam2d.get_screen_center_position()
	var p: Vector2 = _entity.global_position
	if _stage != null and _stage.get("first_person_active") == true:
		return p.distance_squared_to(center) <= 980.0 * 980.0
	var zoom_val: float = maxf(0.25, cam2d.zoom.x)
	var half_ext: Vector2 = (vp.get_visible_rect().size / zoom_val) * 0.55 + Vector2(90.0, 90.0)
	return absf(p.x - center.x) <= half_ext.x and absf(p.y - center.y) <= half_ext.y
