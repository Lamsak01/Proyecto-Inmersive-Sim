extends SceneTree

## Convierte las animaciones de Quaternius «Universal Animation Library» 1 y 2 (CC0) al esqueleto de los
## personajes del juego (Universal Base Characters + Modular Outfits) y las guarda como una AnimationLibrary.
## Solo hace falta volver a ejecutarlo si cambian los packs de origen.
## Uso: flatpak run org.godotengine.Godot --headless --path . -s tools/bake_character_animations.gd
##
## Reasignación (retargeting): rotación final = reposo_personaje * inverso(reposo_animación) * rotación_animación.
## Solo la pelvis conserva su posición, escalada a la altura del personaje.

const SRC_DIR := "res://assests/Assets 3d/descargas_claude/x/"
const SRC_UAL1 := SRC_DIR + "Animation Library[Standard]/Unreal Engine/AL_Standard.fbx"
const SRC_UAL2 := SRC_DIR + "Universal Animation Library 2 [Standard]/Unreal-Godot/UAL2_Standard.glb"
const OUT_DIR := "res://assests/curated_3d/animations/"
const TARGET_SKEL_PATH := "Armature/Skeleton3D"

## nombre en el juego -> [pack, nombre original, ¿en bucle?]
const PICK := {
	"idle": [1, "Idle_Loop", true],
	"walk": [1, "Walk_Loop", true],
	"run": [1, "Jog_Fwd_Loop", true],
	"talk": [1, "Idle_Talking_Loop", true],
	"torch": [1, "Idle_Torch_Loop", true],
	"sit": [1, "Sitting_Idle_Loop", true],
	"crouch": [1, "Crouch_Idle_Loop", true],
	"kneel_fix": [1, "Fixing_Kneeling", true],
	"death": [1, "Death01", false],
	"hit": [1, "Hit_Chest", false],
	"sword": [1, "Sword_Attack", false],
	"punch": [1, "Punch_Jab", false],
	"aim": [1, "Pistol_Aim_Neutral", true],
	"shoot": [1, "Pistol_Shoot", false],
	"pickup": [1, "PickUp_Table", false],
	"interact": [1, "Interact", false],
	"dance": [1, "Dance_Loop", true],
	"chop": [2, "TreeChopping_Loop", true],
	"harvest": [2, "Farm_Harvest", true],
	"water": [2, "Farm_Watering", true],
	"carry": [2, "Walk_Carry_Loop", true],
	"lantern": [2, "Idle_Lantern_Loop", true],
	"fold_arms": [2, "Idle_FoldArms_Loop", true],
	"lay": [2, "LayToIdle", false],
	"drink": [2, "Consume", false],
	"no": [2, "Idle_No_Loop", true],
	"yes": [2, "Yes", false],
	"zombie_walk": [2, "Zombie_Walk_Fwd_Loop", true],
}


func _load_scene(path: String) -> Node:
	var abs_p := ProjectSettings.globalize_path(path)
	var doc: Variant = FBXDocument.new() if path.ends_with(".fbx") else GLTFDocument.new()
	var st: Variant = FBXState.new() if path.ends_with(".fbx") else GLTFState.new()
	if doc.append_from_file(abs_p, st) != OK:
		push_error("No se pudo cargar " + abs_p)
		return null
	return doc.generate_scene(st)


func _rests(sk: Skeleton3D) -> Dictionary:
	var d := {}
	for i in range(sk.get_bone_count()):
		d[sk.get_bone_name(i)] = sk.get_bone_rest(i)
	return d


func _find_anim(ap: AnimationPlayer, wanted: String) -> Animation:
	for n in ap.get_animation_list():
		var short := String(n).get_slice("|", String(n).get_slice_count("|") - 1)
		if short == wanted:
			return ap.get_animation(n)
	return null


func _retarget(src: Animation, src_rest: Dictionary, dst_rest: Dictionary, looped: bool) -> Animation:
	var out := Animation.new()
	out.length = src.length
	out.loop_mode = Animation.LOOP_LINEAR if looped else Animation.LOOP_NONE
	var h_src: float = maxf(0.0001, (src_rest["pelvis"] as Transform3D).origin.length())
	var h_dst: float = (dst_rest["pelvis"] as Transform3D).origin.length()
	var ratio: float = h_dst / h_src
	for t in range(src.get_track_count()):
		var path_s := String(src.track_get_path(t))
		var bone := path_s.get_slice(":", 1)
		if not dst_rest.has(bone) or not src_rest.has(bone):
			continue
		var ty := src.track_get_type(t)
		var s_rest: Transform3D = src_rest[bone]
		var d_rest: Transform3D = dst_rest[bone]
		if ty == Animation.TYPE_ROTATION_3D:
			var nt := out.add_track(Animation.TYPE_ROTATION_3D)
			out.track_set_path(nt, NodePath(TARGET_SKEL_PATH + ":" + bone))
			var sq := s_rest.basis.get_rotation_quaternion()
			var dq := d_rest.basis.get_rotation_quaternion()
			for k in range(src.track_get_key_count(t)):
				var q: Quaternion = src.track_get_key_value(t, k)
				out.rotation_track_insert_key(nt, src.track_get_key_time(t, k), (dq * sq.inverse() * q).normalized())
		elif ty == Animation.TYPE_POSITION_3D and bone == "pelvis":
			var nt2 := out.add_track(Animation.TYPE_POSITION_3D)
			out.track_set_path(nt2, NodePath(TARGET_SKEL_PATH + ":" + bone))
			for k in range(src.track_get_key_count(t)):
				var p: Vector3 = src.track_get_key_value(t, k)
				out.position_track_insert_key(nt2, src.track_get_key_time(t, k), d_rest.origin + (p - s_rest.origin) * ratio)
	return out


func _initialize() -> void:
	var src1 := _load_scene(SRC_UAL1)
	var src2 := _load_scene(SRC_UAL2)
	if src1 == null or src2 == null:
		quit(1)
		return
	var ap1 := src1.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var ap2 := src2.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var r1 := _rests(src1.find_child("Skeleton3D", true, false) as Skeleton3D)
	var r2 := _rests(src2.find_child("Skeleton3D", true, false) as Skeleton3D)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for target in [["male", "res://assests/curated_3d/characters/Male_Peasant.gltf"], ["female", "res://assests/curated_3d/characters/Female_Peasant.gltf"]]:
		var tgt := _load_scene(target[1])
		var tsk := tgt.find_child("Skeleton3D", true, false) as Skeleton3D
		if String(tgt.get_path_to(tsk)) != TARGET_SKEL_PATH:
			push_error("Ruta de esqueleto inesperada: " + String(tgt.get_path_to(tsk)))
		var tr := _rests(tsk)
		var lib := AnimationLibrary.new()
		for key in PICK.keys():
			var spec: Array = PICK[key]
			var ap: AnimationPlayer = ap1 if int(spec[0]) == 1 else ap2
			var src_a := _find_anim(ap, String(spec[1]))
			if src_a == null:
				push_error("Falta la animación " + String(spec[1]))
				continue
			lib.add_animation(key, _retarget(src_a, r1 if int(spec[0]) == 1 else r2, tr, bool(spec[2])))
		var out_p: String = OUT_DIR + "ual_%s.res" % target[0]
		var err := ResourceSaver.save(lib, out_p, ResourceSaver.FLAG_COMPRESS)
		print("BAKED ", out_p, " anims=", lib.get_animation_list().size(), " err=", err)
		tgt.free()
	src1.free()
	src2.free()
	quit(0)
