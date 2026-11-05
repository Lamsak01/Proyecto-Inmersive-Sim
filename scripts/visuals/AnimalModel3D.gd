extends Node2D

## Modelo 3D de un animal (2026-11-05): pone un modelo quieto (sin animar) dentro del escenario 3D, encima del animal 2D.
## Solo es visual: no toca su comportamiento. El modelo sigue la posición del animal, mira hacia donde camina y se
## tumba de lado cuando el sprite 2D se tumba (cadáver o aturdido). En modo headless (pruebas) no hace nada.
## Con F9 (vista 2D) se esconde y vuelve el sprite.

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


static func attach(entity: Node2D, rel_path: String, h_px: float, foot_px: float) -> void:
	if DisplayServer.get_name() == "headless" or Engine.is_editor_hint() or entity == null:
		return
	if not AssetLib.has_curated_assets():
		return
	var n = load("res://scripts/visuals/AnimalModel3D.gd").new()
	n.name = "AnimalModel3D"
	n.model_rel = rel_path
	n.height_px = h_px
	n.foot_offset_px = foot_px
	entity.add_child(n)


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
	var model := AssetLib.instantiate_model(model_rel, Vector3.ZERO, maxf(0.05, height_px * ws), true, true)
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
	chars.add_child(_holder)
	return true


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
	if not show:
		_last_pos = Vector2.INF
		return
	var pos: Vector2 = _entity.global_position
	_holder.position = _stage.call("to_3d", pos + Vector2(0.0, foot_offset_px), 0.0)
	# Mira hacia donde camina (los modelos miran hacia +Z, que en el mapa es «hacia abajo»).
	if _last_pos != Vector2.INF:
		var mv: Vector2 = pos - _last_pos
		if mv.length_squared() > 0.0004:
			var target: float = atan2(mv.x, mv.y)
			_cur_yaw = lerp_angle(_cur_yaw, target, clampf(delta * 8.0, 0.0, 1.0))
	_last_pos = pos
	_yaw.rotation.y = _cur_yaw
	# Tumbado de lado si el sprite 2D está tumbado (muerto o aturdido).
	var spr = _entity.get("sprite")
	var lying: bool = spr is Node2D and absf((spr as Node2D).rotation_degrees) > 45.0
	_model.rotation_degrees.z = 90.0 if lying else 0.0
	_model.position.y = height_px * WORLD_SCALE * 0.3 if lying else 0.0


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
	var zoom_val: float = maxf(0.25, cam2d.zoom.x)
	var half_ext: Vector2 = (vp.get_visible_rect().size / zoom_val) * 0.55 + Vector2(90.0, 90.0)
	var p: Vector2 = _entity.global_position
	return absf(p.x - center.x) <= half_ext.x and absf(p.y - center.y) <= half_ext.y
