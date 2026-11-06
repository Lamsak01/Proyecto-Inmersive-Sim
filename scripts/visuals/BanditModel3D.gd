extends Node2D

## Muñeco 3D de un bandido de incursión (2026-11-05). Usa el mismo esqueleto animado que los vecinos (CharacterRig3D),
## con capucha, ropa oscura y espada, dentro del escenario 3D. Sigue al asaltante, anda, ataca y cae al morir.
## En modo headless (pruebas) no hace nada. Con F10 (vista 2D) se esconde y vuelve el sprite.

const CharacterAvatar3DScript = preload("res://scripts/visuals/CharacterAvatar3D.gd")
const CharacterRig3DScript = preload("res://scripts/visuals/CharacterRig3D.gd")

var _entity: Node2D = null
var _stage: Node = null
var _holder: Node3D = null
var _rig: Node3D = null
var _sprite_hidden: bool = false


static func attach(entity: Node2D) -> Node:
	if DisplayServer.get_name() == "headless" or Engine.is_editor_hint() or entity == null:
		return null
	var n = load("res://scripts/visuals/BanditModel3D.gd").new()
	n.name = "BanditModel3D"
	entity.add_child(n)
	return n


func _ready() -> void:
	_entity = get_parent() as Node2D


func _exit_tree() -> void:
	if _holder != null and is_instance_valid(_holder):
		_holder.queue_free()
	_holder = null


func _attach() -> bool:
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
	_stage = st
	_holder = Node3D.new()
	_holder.name = "Bandit_" + str(_entity.name)
	var cos_p: float = float(st.get("_cos_p"))
	var k: float = CharacterAvatar3DScript.STAGE_K
	_holder.scale = Vector3(k, k / maxf(0.1, cos_p), k)
	chars.add_child(_holder)
	_rig = CharacterRig3DScript.new()
	_rig.name = "CharacterRig3D"
	_holder.add_child(_rig)
	_rig.call("apply_character_appearance", {
		"skin_color": Color(0.80, 0.64, 0.52), "hair_color": Color(0.12, 0.09, 0.07),
		"tunic_color": Color(0.32, 0.10, 0.10), "pants_color": Color(0.10, 0.10, 0.12),
		"has_beard": true, "has_cape": true, "cape_color": Color(0.14, 0.12, 0.12),
		"headgear": "priest_cap", "weapon": "sword", "outfit_kind": "ranger",
	})
	return true


func _process(delta: float) -> void:
	if not is_instance_valid(_entity):
		return
	if _holder == null or not is_instance_valid(_holder):
		_holder = null
		if not _attach():
			return
	var use_3d: bool = CharacterAvatar3DScript.use_3d_characters
	if use_3d != _sprite_hidden:
		var spr = _entity.get("sprite")
		if spr is CanvasItem and is_instance_valid(spr):
			(spr as CanvasItem).self_modulate.a = 0.0 if use_3d else 1.0
		_sprite_hidden = use_3d
	_holder.visible = use_3d and _entity.is_visible_in_tree()
	if not _holder.visible:
		return
	_holder.position = _stage.call("to_3d", _entity.global_position + Vector2(0.0, CharacterAvatar3DScript.FOOT_OFFSET_PX), 0.0)
	var vel: Vector2 = _entity.get("velocity") if "velocity" in _entity else Vector2.ZERO
	var facing: Vector2 = vel.normalized() if vel.length_squared() > 4.0 else Vector2(_entity.get("facing"))
	_rig.call("update_pose", delta, {
		"facing": facing,
		"speed_ratio": clampf(vel.length() / 110.0, 0.0, 2.5),
		"is_dead": bool(_entity.get("is_dead")),
		"attack_progress": float(_entity.get("attack_anim")),
		"is_hostile": true,
	})
