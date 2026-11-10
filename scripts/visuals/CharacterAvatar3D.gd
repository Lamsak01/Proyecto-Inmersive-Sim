extends Node2D
const _AN_SITIOS = preload("res://mapa/anclas.gd") # plan de sitios: zonas fijas siguen a lo movido

## Puente de Renderizado 3D en Vivo para Jugador y Vecinos — Fase 1 (Transición 3D)
## Envuelve un `CharacterRig3D` dentro de un `SubViewport` transparente por personaje (desactivado automáticamente
## fuera de cámara o en modo headless para mantener 0 ms de sobrecarga en tests y 100 vecinos).
## Permite alternar en caliente con [F10] entre las nuevas Maquetas 3D Articuladas y los Sprites 2D originales.

const CharacterRig3DScript = preload("res://scripts/visuals/CharacterRig3D.gd")

static var use_3d_characters: bool = true
const AVATAR_RES: int = 64
const OUTLINE_SHADER := preload("res://shaders/pixel_outline.gdshader")

var is_player_avatar: bool = false
var target_entity: Node2D = null
var sub_viewport: SubViewport = null
var rig_3d: Node3D = null
var display_sprite: Sprite2D = null
var dir_light: DirectionalLight3D = null

var _appearance_dirty: bool = true
var _appearance_sync_timer: float = 0.0
var _last_equipped_sig: String = ""
var _last_was_3d: bool = true

# --- Modo «dentro del escenario» (2026-11-05): el muñeco 3D vive en el mismo mundo 3D que los edificios ---
# Así le tapan las paredes, proyecta sombra y le ilumina el sol y las farolas, en vez de pegarse encima como una pegatina.
## Escala del muñeco en el escenario (1 unidad del muñeco ≈ 20 px del mapa).
const STAGE_K: float = 0.40
## Los pies del muñeco quedan unos píxeles por debajo del origen de la entidad (donde estaba la sombra 2D).
const FOOT_OFFSET_PX: float = 4.0
## Altura del asiento sobre el lomo del caballo (px del mapa).
const MOUNT_SEAT_PX: float = 11.5
static var _stage_ref: Node = null
var _holder: Node3D = null
var _stage: Node = null
var _in_stage_mode: bool = false
var _applied_alpha: float = 1.0

func setup_for_entity(entity: Node2D, is_player: bool = false) -> void:
	target_entity = entity
	is_player_avatar = is_player
	name = "CharacterAvatar3D"
	z_index = 1

	rig_3d = CharacterRig3DScript.new()
	rig_3d.name = "CharacterRig3D"

	# En modo headless (batería de tests automáticos) no creamos SubViewports de GPU para no gastar memoria ni tiempo,
	# pero mantenemos `rig_3d` en el árbol para que su estado, equipo y prótesis sean verificables.
	if DisplayServer.get_name() == "headless" or Engine.is_editor_hint():
		add_child(rig_3d)
		_sync_appearance_now()
		return

	# Con ventana: el muñeco se mete en el escenario 3D compartido (ver `_attach_to_stage`).
	_in_stage_mode = true
	if _attach_to_stage():
		_sync_appearance_now()
	_apply_2d_vs_3d_visibility()


## Antiguo modo (un SubViewport por personaje, pegado encima del mapa). Solo se usa si no hay escenario 3D.
func _setup_own_viewport() -> void:
	_in_stage_mode = false
	sub_viewport = SubViewport.new()
	sub_viewport.name = "AvatarSubViewport"
	# Resolución baja + filtrado pixelado (estética retro): 64 px en vez de 96, escalado para ocupar lo mismo.
	sub_viewport.size = Vector2i(AVATAR_RES, AVATAR_RES)
	sub_viewport.transparent_bg = true
	sub_viewport.own_world_3d = true
	sub_viewport.msaa_3d = Viewport.MSAA_DISABLED
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub_viewport)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.88, 0.90, 0.96)
	env.ambient_light_energy = 0.92
	env_node.environment = env
	sub_viewport.add_child(env_node)

	dir_light = DirectionalLight3D.new()
	dir_light.rotation_degrees = Vector3(-48.0, 32.0, 0.0)
	dir_light.light_energy = 1.30
	dir_light.light_color = Color(1.0, 0.97, 0.90)
	sub_viewport.add_child(dir_light)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.35
	cam.position = Vector3(0.0, 2.25, 2.55)
	cam.rotation_degrees = Vector3(-36.0, 0.0, 0.0)
	sub_viewport.add_child(cam)

	sub_viewport.add_child(rig_3d)

	display_sprite = Sprite2D.new()
	display_sprite.name = "Avatar3DSprite"
	display_sprite.texture = sub_viewport.get_texture()
	display_sprite.position = Vector2(0.0, -13.0)
	display_sprite.scale = Vector2(0.46 * 96.0 / AVATAR_RES, 0.46 * 96.0 / AVATAR_RES)
	display_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var outline_mat := ShaderMaterial.new()
	outline_mat.shader = OUTLINE_SHADER
	display_sprite.material = outline_mat
	add_child(display_sprite)

	_sync_appearance_now()
	_apply_2d_vs_3d_visibility()

static func _find_stage(tree: SceneTree) -> Node:
	if _stage_ref != null and is_instance_valid(_stage_ref) and _stage_ref.is_inside_tree() and not _stage_ref.is_queued_for_deletion():
		return _stage_ref
	_stage_ref = null
	var st := tree.root.find_child("WorldStage3D", true, false)
	if st != null and st.get("stage_root_3d") != null and not st.is_queued_for_deletion():
		_stage_ref = st
	return _stage_ref


## Coloca el muñeco dentro del escenario 3D. Devuelve false si el escenario aún no existe (se reintenta luego).
## Si el escenario se reconstruye (al cargar partida), el muñeco antiguo muere con él y aquí se crea otro.
func _attach_to_stage() -> bool:
	if not is_inside_tree():
		return false
	var st := _find_stage(get_tree())
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
	_holder.name = "Avatar_" + str(target_entity.name) if is_instance_valid(target_entity) else "Avatar"
	# El escenario estira la altura (1/cos del ángulo de cámara) para que el 3D cuadre con el mapa 2D;
	# el muñeco se estira igual para verse con sus proporciones. Girar sobre el eje vertical no lo deforma.
	var cos_p: float = float(st.get("_cos_p"))
	_holder.scale = Vector3(STAGE_K, STAGE_K / maxf(0.1, cos_p), STAGE_K)
	chars.add_child(_holder)
	if rig_3d == null or not is_instance_valid(rig_3d) or rig_3d.is_queued_for_deletion():
		rig_3d = CharacterRig3DScript.new()
		rig_3d.name = "CharacterRig3D"
		_appearance_dirty = true
	if rig_3d.get_parent() != null:
		rig_3d.get_parent().remove_child(rig_3d)
	_holder.add_child(rig_3d)
	_applied_alpha = 1.0
	_sync_holder_position()
	return true


## Vecinos lejanos (2026-11-09): con la simulación simplificada se mueven a saltos de 4 pasos; el muñeco 3D los sigue
## suavizado para que no se vea a tirones. El jugador y los saltos grandes (teletransporte, cambio de piso) van directos.
var _smooth_pos: Vector2 = Vector2.INF
var _smooth_usec: int = 0

func _smoothed_entity_pos() -> Vector2:
	var real: Vector2 = target_entity.global_position
	if is_player_avatar:
		return real
	var now: int = Time.get_ticks_usec()
	var dt: float = clampf(float(now - _smooth_usec) / 1000000.0, 0.0, 0.1)
	_smooth_usec = now
	if _smooth_pos == Vector2.INF or _smooth_pos.distance_squared_to(real) > 30.0 * 30.0:
		_smooth_pos = real
	else:
		_smooth_pos = _smooth_pos.lerp(real, 1.0 - exp(-dt * 18.0))
	return _smooth_pos

func _sync_holder_position() -> void:
	if _holder == null or not is_instance_valid(target_entity) or _stage == null:
		return
	# A caballo, el muñeco va sentado sobre el lomo (más alto).
	var seat_h: float = MOUNT_SEAT_PX if (is_player_avatar and bool(target_entity.get("is_mounted"))) else 0.0
	var elev_lvl: int = 0
	var vm_node = target_entity.get_tree().get_first_node_in_group("village_manager") if target_entity.is_inside_tree() else null
	if is_player_avatar:
		if vm_node != null:
			elev_lvl = int(vm_node.player_elevation_level)
	elif "elevation_level" in target_entity:
		elev_lvl = int(target_entity.get("elevation_level"))
	var pos_2d: Vector2 = _smoothed_entity_pos()
	var tav_gd = preload("res://scripts/systems/VillageTavern.gd")
	var rest_gd = preload("res://scripts/systems/VillageRestaurant.gd")
	var tav_h: float = tav_gd.elevation_height_for(pos_2d, elev_lvl)
	if tav_h > 0.0:
		seat_h += tav_h
	elif elev_lvl == 0 and vm_node != null and vm_node.has_method("_is_pos_inside_any_building") and bool(vm_node.call("_is_pos_inside_any_building", pos_2d)):
		seat_h += 2.65
	elif elev_lvl == 0 and rest_gd.TERRACE.grow(6.0).has_point(pos_2d):
		seat_h += 1.8
	elif elev_lvl == 0 and _stage != null and _stage.has_method("surface_elevation_offset_px"):
		seat_h += float(_stage.call("surface_elevation_offset_px", pos_2d))
	var foot_off := Vector2(0.0, FOOT_OFFSET_PX)
	if not is_player_avatar and (tav_gd.is_at_seat(pos_2d) or rest_gd.is_at_seat(pos_2d)):
		var v_chk: Vector2 = target_entity.get("velocity") if "velocity" in target_entity else Vector2.ZERO
		if v_chk.length_squared() < 4.0:
			foot_off = Vector2(0.0, 1.0)
	if is_player_avatar and target_entity.has_method("get_jump_height"):
		seat_h += float(target_entity.call("get_jump_height"))
	var base_pos_3d: Vector3 = _stage.call("to_3d", pos_2d + foot_off, seat_h)
	var rec_rot := Vector3.ZERO
	if target_entity.has_meta("hit_recoil_3d_until_ms"):
		var rem_ms: int = int(target_entity.get_meta("hit_recoil_3d_until_ms")) - Time.get_ticks_msec()
		var dur_ms: int = maxi(1, int(target_entity.get_meta("hit_recoil_3d_dur_ms", 240)))
		if rem_ms > 0:
			var k_rec: float = sin(clampf(float(rem_ms) / float(dur_ms), 0.0, 1.0) * PI)
			var r_dir: Vector2 = target_entity.get_meta("hit_recoil_3d_dir", Vector2.RIGHT)
			base_pos_3d += Vector3(r_dir.x, 0.0, r_dir.y) * (0.14 * k_rec)
			rec_rot = Vector3(r_dir.y * 0.36 * k_rec, 0.0, -r_dir.x * 0.36 * k_rec)
	_holder.position = base_pos_3d
	_holder.rotation = rec_rot


func _exit_tree() -> void:
	if _holder != null and is_instance_valid(_holder):
		_holder.queue_free()
	_holder = null


## Transparencia de todo el muñeco (sigilo, fantasmas…). Solo recorre las mallas cuando cambia.
func _set_rig_alpha(alpha: float) -> void:
	if absf(alpha - _applied_alpha) < 0.01 or rig_3d == null:
		return
	_applied_alpha = alpha
	for gi in rig_3d.find_children("*", "GeometryInstance3D", true, false):
		(gi as GeometryInstance3D).transparency = 1.0 - alpha


func trigger_muzzle_flash() -> void:
	if rig_3d and rig_3d.has_method("trigger_muzzle_flash"):
		rig_3d.call("trigger_muzzle_flash")

func mark_appearance_dirty() -> void:
	_appearance_dirty = true

func _process(delta: float) -> void:
	if not is_instance_valid(target_entity) or rig_3d == null:
		return

	if _in_stage_mode:
		_process_in_stage(delta)
		return

	if _last_was_3d != use_3d_characters:
		_last_was_3d = use_3d_characters
		_apply_2d_vs_3d_visibility()

	if not use_3d_characters:
		if sub_viewport:
			sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return

	# Al volver de 2D a 3D (F10), reactivar el SubViewport del jugador: antes se quedaba congelado y parecía que
	# sus animaciones dejaban de funcionar.
	if sub_viewport and is_player_avatar:
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Optimización para 100 vecinos: si un NPC está fuera de la cámara actual, pausar su SubViewport 3D
	if sub_viewport and not is_player_avatar:
		var on_screen: bool = _is_entity_near_camera()
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if on_screen else SubViewport.UPDATE_DISABLED
		if not on_screen:
			return

	_appearance_sync_timer -= delta
	if _appearance_dirty or _appearance_sync_timer <= 0.0:
		_appearance_sync_timer = 0.25 if is_player_avatar else 0.65
		_check_and_sync_appearance()

	_sync_pose_and_tint(delta)
	_apply_2d_vs_3d_visibility()

## B3 (medición): cronómetro por partes; solo lo enciende `tools/tests/perf_3d.gd`. No cambia el comportamiento.
static var perf_on: bool = false
static var perf_usec: Dictionary = {}

static func _perf_add(part: String, since: int) -> int:
	var now: int = Time.get_ticks_usec()
	perf_usec[part] = int(perf_usec.get(part, 0)) + (now - since)
	return now

func _process_in_stage(delta: float) -> void:
	var _pt: int = Time.get_ticks_usec() if perf_on else 0
	if _holder == null or not is_instance_valid(_holder) or _holder.is_queued_for_deletion() or rig_3d == null or not is_instance_valid(rig_3d):
		_holder = null
		if not _attach_to_stage():
			return
		_sync_appearance_now()
	if _last_was_3d != use_3d_characters:
		_last_was_3d = use_3d_characters
		_apply_2d_vs_3d_visibility()
	var fp_on: bool = _stage != null and _stage.get("first_person_active") == true
	var show := use_3d_characters and target_entity.is_visible_in_tree()
	if is_player_avatar and fp_on:
		show = false
	elif show and not is_player_avatar:
		var vm_elev_chk = target_entity.get_tree().get_first_node_in_group("village_manager") if target_entity.is_inside_tree() else null
		if vm_elev_chk != null and "elevation_level" in target_entity:
			var pl_el: int = int(vm_elev_chk.player_elevation_level)
			var ent_el: int = int(target_entity.get("elevation_level"))
			if pl_el == 1 and ent_el == 0 and preload("res://scripts/systems/VillageTavern.gd").RECT.grow(6.0).has_point(_AN_SITIOS.desmover(target_entity.global_position)):
				show = false
		if show:
			show = _is_entity_near_camera()
	if perf_on: _pt = _perf_add("visibility_check", _pt)
	if not show:
		_holder.visible = false
		rig_3d.process_mode = Node.PROCESS_MODE_DISABLED
		if is_player_avatar and fp_on:
			_apply_2d_vs_3d_visibility()
		return
	rig_3d.process_mode = Node.PROCESS_MODE_INHERIT
	_holder.visible = true
	var cos_p_eff: float = 1.0 if fp_on else float(_stage.get("_cos_p"))
	_holder.scale = Vector3(STAGE_K, STAGE_K / maxf(0.1, cos_p_eff), STAGE_K)
	_sync_holder_position()
	if perf_on: _pt = _perf_add("holder_position", _pt)
	_appearance_sync_timer -= delta
	if _appearance_dirty or _appearance_sync_timer <= 0.0:
		_appearance_sync_timer = 0.25 if is_player_avatar else 0.65
		_check_and_sync_appearance()
	if perf_on: _pt = _perf_add("appearance_check", _pt)
	_sync_pose_and_tint(delta)
	if perf_on: _pt = _perf_add("pose_and_tint", _pt)
	# Al recibir daño el muñeco parpadea (destello retro), en vez del tinte rojo del sprite antiguo.
	var alpha := 1.0
	if is_player_avatar:
		if bool(_read_stealth()):
			alpha = 0.55
		if float(target_entity.get("_hit_flash_timer")) > 0.0:
			_holder.visible = int(Time.get_ticks_msec() / 70) % 2 == 0
	else:
		var spr_orig = target_entity.get("sprite")
		if spr_orig is CanvasItem:
			alpha = clampf((spr_orig as CanvasItem).modulate.a, 0.0, 1.0)
		if target_entity is CanvasItem:
			alpha *= clampf((target_entity as CanvasItem).modulate.a, 0.0, 1.0)
	if alpha <= 0.02:
		_holder.visible = false
	_set_rig_alpha(alpha)
	if perf_on: _pt = _perf_add("rig_alpha", _pt)
	_apply_2d_vs_3d_visibility()
	if perf_on: _perf_add("vis_2d_vs_3d", _pt)


func _read_stealth() -> bool:
	var m_ctrl = target_entity.get_node_or_null("PlayerMovementController")
	return m_ctrl != null and bool(m_ctrl.get("is_stealthing"))


func _is_entity_near_camera() -> bool:
	var vp := get_viewport()
	if vp == null:
		return true
	var cam2d := vp.get_camera_2d()
	if cam2d == null:
		return true
	var center: Vector2 = cam2d.get_screen_center_position()
	if _stage != null and _stage.get("first_person_active") == true:
		return target_entity.global_position.distance_squared_to(center) <= 950.0 * 950.0
	var zoom_val: float = maxf(0.25, cam2d.zoom.x)
	var half_ext: Vector2 = (vp.get_visible_rect().size / zoom_val) * 0.55 + Vector2(90.0, 90.0)
	return absf(target_entity.global_position.x - center.x) <= half_ext.x and absf(target_entity.global_position.y - center.y) <= half_ext.y

func _apply_2d_vs_3d_visibility() -> void:
	var fp_on: bool = _stage != null and _stage.get("first_person_active") == true
	if display_sprite:
		display_sprite.visible = use_3d_characters and not (is_player_avatar and fp_on)
	if not is_instance_valid(target_entity):
		return
	if is_player_avatar:
		var anim_2d := target_entity.get_node_or_null("Animations") as CanvasItem
		if anim_2d:
			anim_2d.self_modulate.a = 0.0 if use_3d_characters else 1.0
		var armor_ov := target_entity.get_node_or_null("ArmorPlaceholderOverlay") as CanvasItem
		if armor_ov:
			armor_ov.modulate.a = 0.0 if use_3d_characters else 1.0
		var c_ctrl := target_entity.get_node_or_null("PlayerCombatController")
		if c_ctrl and "weapon_sprite" in c_ctrl and c_ctrl.weapon_sprite is CanvasItem:
			(c_ctrl.weapon_sprite as CanvasItem).self_modulate.a = 0.0 if use_3d_characters else 1.0
	else:
		var spr_2d = target_entity.get("sprite")
		if spr_2d is CanvasItem:
			(spr_2d as CanvasItem).self_modulate.a = 0.0 if use_3d_characters else 1.0

func _check_and_sync_appearance() -> void:
	var sig: String = _compute_equipment_signature()
	if _appearance_dirty or sig != _last_equipped_sig:
		_last_equipped_sig = sig
		_appearance_dirty = false
		_sync_appearance_now()

func _compute_equipment_signature() -> String:
	if not is_instance_valid(target_entity):
		return ""
	if is_player_avatar:
		var w_name: String = ""
		var eq = target_entity.get("equipped_weapon")
		if eq != null and "name" in eq:
			w_name = str(eq.name)
		var arm_str: String = ""
		var inv = target_entity.get("inventory")
		if inv != null and "equipped_armor" in inv:
			arm_str = str(inv.equipped_armor) + "|" + str(inv.has_item("ranger_camo_cloak", 1))
		var t_tier_str: String = str(target_entity.get("tool_tiers"))
		var amp_str: String = _get_limb_signature_for_entity(target_entity)
		# Incluye la noche para que el farol aparezca en la mano a las 20:00 sin esperar a cambiar de herramienta.
		var night_p: bool = bool(target_entity.get("is_carrying_lantern"))
		return "%s|%s|%s|%s|%s" % [w_name, arm_str, t_tier_str, amp_str, str(night_p)]
	else:
		var role_i: int = int(target_entity.get("trade_role"))
		var work_b: bool = bool(target_entity.get("_is_actively_crafting"))
		var hr: int = int(WorldClock.current_hour) if WorldClock != null else 12
		var night_b: bool = (hr >= 20 or hr < 6)
		var amp_npc: String = _get_limb_signature_for_entity(target_entity)
		var hooded_b: bool = str(target_entity.get("errand_kind")) == "fence_alley"
		var carries_rifle_b: bool = target_entity.has_method("carries_police_rifle") and bool(target_entity.call("carries_police_rifle"))
		return "%d|%s|%s|%s|%s|%s" % [role_i, str(work_b), str(night_b), amp_npc, str(hooded_b), str(carries_rifle_b)]

func _get_limb_signature_for_entity(ent: Node2D) -> String:
	var states: Dictionary = _resolve_entity_limb_states(ent)
	return "%s,%s,%s,%s" % [
		str(states.get("left_arm_state", "normal")),
		str(states.get("right_arm_state", "normal")),
		str(states.get("left_leg_state", "normal")),
		str(states.get("right_leg_state", "normal"))
	]

func _resolve_entity_limb_states(ent: Node2D) -> Dictionary:
	var res := {
		"left_arm_state": "normal",
		"right_arm_state": "normal",
		"left_leg_state": "normal",
		"right_leg_state": "normal"
	}
	if not is_instance_valid(ent):
		return res
	# 1. Consultar registro de amputaciones y prótesis en VillageNeeds / VillageIllness
	var vm = ent.get_tree().get_first_node_in_group("village_manager") if ent.is_inside_tree() else null
	if vm != null and "needs_state" in vm and vm.needs_state is Dictionary:
		var amps: Dictionary = vm.needs_state.get("amputations", {})
		var keys_to_try: Array[String] = []
		if is_player_avatar:
			keys_to_try.append("player")
		else:
			if ent.has_method("get_person_key"):
				keys_to_try.append(str(ent.call("get_person_key")))
			if "npc_name" in ent:
				keys_to_try.append(str(ent.get("npc_name")))
		for k in keys_to_try:
			if k != "" and amps.has(k) and amps[k] is Dictionary:
				var rec: Dictionary = amps[k]
				var reg: String = str(rec.get("limb", rec.get("region", "left_leg"))).to_lower()
				var has_prost: bool = str(rec.get("prosthetic", "")) != "" or bool(rec.get("has_prosthetic", false))
				var st_val: String = "prosthetic" if has_prost else "amputated"
				if reg.find("arm") != -1 or reg.find("brazo") != -1:
					if reg.find("right") != -1 or reg.find("der") != -1:
						res["right_arm_state"] = st_val
					else:
						res["left_arm_state"] = st_val
				else:
					if reg.find("right") != -1 or reg.find("der") != -1:
						res["right_leg_state"] = st_val
					else:
						res["left_leg_state"] = st_val
	# 2. Comprobar también metas directas por si el jugador instaló una prótesis ("has_prosthetic")
	if ent.has_meta("has_prosthetic") and bool(ent.get_meta("has_prosthetic")):
		if res["left_leg_state"] == "normal" and res["right_leg_state"] == "normal" and res["left_arm_state"] == "normal" and res["right_arm_state"] == "normal":
			res["left_leg_state"] = "prosthetic"
	return res

func _sync_appearance_now() -> void:
	if rig_3d == null or not is_instance_valid(rig_3d) or not rig_3d.is_inside_tree():
		return
	if not is_instance_valid(target_entity) or rig_3d == null:
		return
	var cfg: Dictionary = _build_player_appearance_cfg() if is_player_avatar else _build_npc_appearance_cfg()
	rig_3d.call("apply_character_appearance", cfg)

func _build_player_appearance_cfg() -> Dictionary:
	var cfg := {
		"skin_color": Color(0.93, 0.76, 0.63),
		"hair_color": Color(0.22, 0.15, 0.10),
		"tunic_color": Color(0.22, 0.42, 0.64),
		"pants_color": Color(0.20, 0.22, 0.26),
		"is_female": false,
		"is_child": false,
		"has_beard": false,
		"has_apron": false,
		"has_skirt": false,
		"has_cape": false,
		"cape_color": Color(0.24, 0.42, 0.26),
		"headgear": "none",
		"chest_armor_tier": 0,
		"legs_armor_tier": 0,
		"boots_armor_tier": 0,
		"weapon": "sword",
		"weapon_tier": 1,
		"offhand": "none"
	}
	var inv = target_entity.get("inventory")
	if inv != null:
		if inv.has_method("has_item") and bool(inv.call("has_item", "ranger_camo_cloak", 1)):
			cfg["has_cape"] = true
		if "equipped_armor" in inv and inv.equipped_armor is Dictionary:
			var eq_arm: Dictionary = inv.equipped_armor
			var head_id: String = str(eq_arm.get("HEAD", ""))
			if head_id != "":
				var h_tier: int = int(inv.call("get_item_info", head_id).get("armor_tier", 1))
				cfg["headgear"] = "helm_t%d" % clampi(h_tier, 1, 3)
			var chest_id: String = str(eq_arm.get("CHEST", ""))
			if chest_id != "":
				cfg["chest_armor_tier"] = int(inv.call("get_item_info", chest_id).get("armor_tier", 1))
			var legs_id: String = str(eq_arm.get("LEGS", ""))
			if legs_id != "":
				cfg["legs_armor_tier"] = int(inv.call("get_item_info", legs_id).get("armor_tier", 1))
			var boots_id: String = str(eq_arm.get("BOOTS", ""))
			if boots_id != "":
				cfg["boots_armor_tier"] = int(inv.call("get_item_info", boots_id).get("armor_tier", 1))

	var eq_w = target_entity.get("equipped_weapon")
	if eq_w != null and "name" in eq_w:
		var wn: String = str(eq_w.name).to_lower()
		var w_key := "sword"
		if wn.find("hammer") != -1 or wn.find("martillo") != -1:
			w_key = "hammer"
		elif wn.find("axe") != -1 or wn.find("hacha") != -1:
			w_key = "axe"
		elif wn.find("pick") != -1 or wn.find("pico") != -1:
			w_key = "pickaxe"
		elif wn.find("bow") != -1 or wn.find("arco") != -1:
			w_key = "bow"
		elif wn.find("sickle") != -1 or wn.find("hoz") != -1:
			w_key = "sickle"
		elif wn.find("water") != -1 or wn.find("regadera") != -1:
			w_key = "watering_can"
		elif wn.find("fish") != -1 or wn.find("caña") != -1:
			w_key = "fishing_rod"
		elif wn.find("flintlock") != -1 or wn.find("arcabuz") != -1:
			w_key = "flintlock"
		cfg["weapon"] = w_key
		if target_entity.has_method("get_tool_tier"):
			cfg["weapon_tier"] = int(target_entity.call("get_tool_tier", w_key))

	var hr: int = int(WorldClock.current_hour) if WorldClock != null else 12
	if hr >= 20 or hr < 6:
		cfg["offhand"] = "lantern"

	var limbs: Dictionary = _resolve_entity_limb_states(target_entity)
	for k in limbs.keys():
		cfg[k] = limbs[k]
	return cfg

func _build_npc_appearance_cfg() -> Dictionary:
	var n_name: String = str(target_entity.get("npc_name"))
	var h_val: int = abs(n_name.hash())
	var prof = target_entity.get("person_profile")
	var is_fem: bool = (prof != null and str(prof.get("gender")) == "F") or (prof == null and n_name.ends_with("a"))
	var age_val: int = int(prof.get("age")) if (prof != null and "age" in prof) else 32
	var role_id: int = int(target_entity.get("trade_role"))
	var is_child: bool = (role_id == 23) or (age_val > 0 and age_val < 16)

	var skin_palette: Array[Color] = [
		Color(0.95, 0.79, 0.66),
		Color(0.90, 0.72, 0.58),
		Color(0.84, 0.65, 0.50),
		Color(0.96, 0.83, 0.72),
		Color(0.68, 0.48, 0.35),
		Color(0.55, 0.38, 0.27)
	]
	var hair_palette: Array[Color] = [
		Color(0.20, 0.13, 0.08),
		Color(0.38, 0.22, 0.12),
		Color(0.68, 0.52, 0.26),
		Color(0.52, 0.22, 0.14),
		Color(0.14, 0.14, 0.16),
		Color(0.28, 0.18, 0.11),
		Color(0.76, 0.62, 0.34)
	]
	var skin_idx: int = int(float(h_val) / 3.0) % skin_palette.size()
	var is_dark_skin: bool = (skin_idx >= 4)
	var hair_col: Color = Color(0.76, 0.76, 0.80) if age_val >= 54 else hair_palette[h_val % hair_palette.size()]
	var skin_col: Color = skin_palette[skin_idx]

	var fem_hairs: Array[String] = ["buns", "long", "buzzed_female", "parted", "buns"]
	var male_hairs: Array[String] = ["parted", "buzzed", "long", "parted", "buzzed_female"]
	var hair_style: String = fem_hairs[(h_val / 2) % fem_hairs.size()] if is_fem else male_hairs[(h_val / 2) % male_hairs.size()]
	if not is_fem and age_val >= 50 and (h_val % 4 == 0):
		hair_style = "bald"
	if role_id == 13 and not is_fem:
		hair_style = "tonsure"

	var outfit_kind: String = "ranger" if (role_id in [6, 8, 9, 10, 11, 12, 15, 20, 21, 22, 24] or ((h_val / 5) % 2 == 1)) else "peasant"
	var outfit_tex_variant: int = (h_val / 3) % 2
	var hair_tex_variant: int = (h_val / 7) % 2

	var pants_palette: Array[Color] = [
		Color(0.24, 0.22, 0.20),
		Color(0.18, 0.22, 0.28),
		Color(0.30, 0.24, 0.18),
		Color(0.22, 0.26, 0.20),
		Color(0.28, 0.20, 0.22)
	]
	var tunic_col := Color(0.36, 0.48, 0.38)
	var pants_col: Color = pants_palette[(h_val / 4) % pants_palette.size()]
	var has_apron := false
	var apron_col := Color(0.52, 0.34, 0.18)
	var has_cape := false
	var cape_col := Color(0.58, 0.14, 0.18)
	var headgear := "none"
	var chest_tier := 0
	var weapon_k := "none"
	var offhand_k := "none"
	var has_beard: bool = (not is_fem and not is_child) and (role_id in [3, 4, 5, 7, 11] or (h_val % 2 == 0))

	match role_id:
		3: # BUTCHER
			tunic_col = Color(0.62, 0.22, 0.20)
			has_apron = true
			apron_col = Color(0.85, 0.80, 0.74)
			weapon_k = "axe"
		4: # BLACKSMITH
			tunic_col = Color(0.28, 0.26, 0.28)
			has_apron = true
			apron_col = Color(0.38, 0.23, 0.12)
			weapon_k = "hammer"
		5: # CARPENTER
			tunic_col = Color(0.58, 0.42, 0.22)
			has_apron = true
			weapon_k = "hammer"
		6: # HERBALIST
			tunic_col = Color(0.24, 0.56, 0.34)
			weapon_k = "sickle"
		7: # FISHMONGER
			tunic_col = Color(0.24, 0.48, 0.62)
			weapon_k = "fishing_rod"
		8: # DOCTOR
			tunic_col = Color(0.88, 0.92, 0.95)
			pants_col = Color(0.20, 0.24, 0.28)
		9: # SHERIFF
			tunic_col = Color(0.22, 0.28, 0.42)
			headgear = "sheriff_hat"
			chest_tier = 2
			has_cape = true
			cape_col = Color(0.18, 0.22, 0.34)
			weapon_k = "rifle" if (target_entity.has_method("carries_police_rifle") and bool(target_entity.call("carries_police_rifle"))) else "sword"
		10: # GUARD
			tunic_col = Color(0.25, 0.36, 0.56)
			headgear = "helm_t2"
			chest_tier = 2
			if target_entity.has_method("carries_police_rifle") and bool(target_entity.call("carries_police_rifle")):
				weapon_k = "rifle"
				offhand_k = "none"
			else:
				weapon_k = "guard_spear"
				offhand_k = "shield"
		11: # TRAVELING_MERCHANT
			tunic_col = Color(0.56, 0.32, 0.62)
			has_cape = true
			cape_col = Color(0.44, 0.22, 0.48)
		12: # ROYAL_INVESTIGATOR
			tunic_col = Color(0.16, 0.16, 0.20)
			headgear = "sheriff_hat"
			chest_tier = 3
			has_cape = true
			cape_col = Color(0.65, 0.12, 0.16)
			weapon_k = "rifle" if (target_entity.has_method("carries_police_rifle") and bool(target_entity.call("carries_police_rifle"))) else "sword"
		13: # PRIEST
			tunic_col = Color(0.92, 0.88, 0.76)
			headgear = "priest_cap"
			offhand_k = "book"
		14: # BAKER
			tunic_col = Color(0.82, 0.68, 0.46)
			has_apron = true
			apron_col = Color(0.95, 0.94, 0.90)
			headgear = "baker_hat"
		15: # TAILOR
			tunic_col = Color(0.64, 0.28, 0.48)
		17: # FARMER
			tunic_col = Color(0.46, 0.58, 0.26)
			headgear = "straw_hat"
			weapon_k = "sickle"
		18: # RANCHER
			tunic_col = Color(0.58, 0.38, 0.22)
			headgear = "straw_hat"
		19: # QUARRYMAN
			tunic_col = Color(0.44, 0.46, 0.50)
			weapon_k = "pickaxe"
		20: # WOODCUTTER
			tunic_col = Color(0.32, 0.46, 0.24)
			weapon_k = "axe"
		21: # TINKER
			tunic_col = Color(0.28, 0.50, 0.56)
			has_apron = true
			weapon_k = "hammer"
		22: # NOBLE
			tunic_col = Color(0.68, 0.16, 0.22)
			headgear = "noble_crown"
			has_cape = true
			cape_col = Color(0.75, 0.14, 0.20)
		24: # TEACHER
			tunic_col = Color(0.28, 0.34, 0.48)
			offhand_k = "book"
		25: # FRONTIER_SCOUT (Roldán, Vigía del Oeste)
			outfit_kind = "ranger"
			tunic_col = Color(0.24, 0.36, 0.22)
			pants_col = Color(0.22, 0.19, 0.16)
			has_cape = true
			cape_col = Color(0.20, 0.28, 0.18)
			chest_tier = 1
			has_beard = true
			hair_style = "parted"
			hair_col = Color(0.62, 0.62, 0.66)
			weapon_k = "sword"
			offhand_k = "none"
		_:
			var fallback_tunics: Array[Color] = [
				Color(0.34, 0.50, 0.42),
				Color(0.52, 0.38, 0.28),
				Color(0.38, 0.44, 0.58),
				Color(0.58, 0.46, 0.32),
				Color(0.64, 0.28, 0.32),
				Color(0.28, 0.48, 0.54),
				Color(0.54, 0.36, 0.52),
				Color(0.68, 0.54, 0.28)
			]
			tunic_col = fallback_tunics[h_val % fallback_tunics.size()]

	# Variación individual sutil de tono de ropa por vecino para evitar gemelos idénticos en la misma profesión
	if not (role_id in [9, 10, 12, 13]):
		var shift_h: float = float((h_val % 11) - 5) * 0.022
		var shift_v: float = float(((h_val / 11) % 7) - 3) * 0.035
		tunic_col = Color.from_hsv(fposmod(tunic_col.h + shift_h, 1.0), clampf(tunic_col.s, 0.15, 0.88), clampf(tunic_col.v + shift_v, 0.22, 0.92))

	var hr_now: int = int(WorldClock.current_hour) if WorldClock != null else 12
	var is_working_now: bool = bool(target_entity.get("_is_actively_crafting")) or (int(target_entity.get("current_activity")) == 0 and hr_now >= 6 and hr_now < 20 and target_entity.get("is_strolling_outside") != true)
	var is_guard_role: bool = role_id in [9, 10, 12, 25]
	if not is_working_now and not is_guard_role and not bool(target_entity.get("is_hostile")):
		weapon_k = "none"
	if offhand_k == "book" and not (is_working_now and target_entity.global_position.distance_to(target_entity.get("work_position")) <= 70.0):
		offhand_k = "none"

	if (hr_now >= 20 or hr_now < 6) and offhand_k == "none" and not bool(target_entity.get("is_sleeping")):
		offhand_k = "lantern"
	# P5b: el perista, de noche en el callejón, va con capa oscura y capucha y sin farol
	if str(target_entity.get("errand_kind")) == "fence_alley":
		tunic_col = Color(0.13, 0.13, 0.15)
		pants_col = Color(0.10, 0.10, 0.11)
		has_cape = true
		cape_col = Color(0.08, 0.08, 0.09)
		headgear = "priest_cap" # en el muñeco 3D es la capucha
		has_apron = false
		weapon_k = "none"
		offhand_k = "none"

	var cfg := {
		"skin_color": skin_col,
		"is_dark_skin": is_dark_skin,
		"hair_color": hair_col,
		"hair_style": hair_style,
		"hair_tex_variant": hair_tex_variant,
		"outfit_kind": outfit_kind,
		"outfit_tex_variant": outfit_tex_variant,
		"tunic_color": tunic_col,
		"pants_color": pants_col,
		"is_female": is_fem,
		"is_child": is_child,
		"has_beard": has_beard,
		"has_apron": has_apron,
		"apron_color": apron_col,
		"has_skirt": is_fem or role_id == 13,
		"has_cape": has_cape,
		"cape_color": cape_col,
		"headgear": headgear,
		"chest_armor_tier": chest_tier,
		"legs_armor_tier": chest_tier,
		"boots_armor_tier": 1 if chest_tier > 0 else 0,
		"weapon": weapon_k,
		"weapon_tier": 2 if chest_tier >= 2 else 1,
		"offhand": offhand_k
	}
	var limbs: Dictionary = _resolve_entity_limb_states(target_entity)
	for k in limbs.keys():
		cfg[k] = limbs[k]
	return cfg

func _sync_pose_and_tint(delta: float) -> void:
	var vel: Vector2 = target_entity.get("velocity") if "velocity" in target_entity else Vector2.ZERO
	var spd: float = vel.length()
	var facing := Vector2.DOWN
	var is_stealth := false
	var is_sprinting := false
	var is_working := false
	var is_fighting := false
	var is_hostile := false
	var is_sleeping := false
	var is_downed := false
	var is_dead := false
	var bow_draw := 0.0
	var atk_prog := 0.0
	var is_mounted_now := false
	var is_rolling_now := false
	var roll_prog_now := 0.0
	var is_parrying_now := false

	if is_player_avatar:
		var m_ctrl = target_entity.get_node_or_null("PlayerMovementController")
		if m_ctrl != null:
			is_stealth = bool(m_ctrl.get("is_stealthing"))
			is_sprinting = bool(m_ctrl.get("is_sprinting"))
			if m_ctrl.has_method("is_rolling") and bool(m_ctrl.call("is_rolling")):
				is_rolling_now = true
				roll_prog_now = float(m_ctrl.call("get_roll_progress"))
				var r_dir: Vector2 = m_ctrl.get("roll_direction")
				if r_dir.length_squared() > 0.01:
					facing = r_dir.normalized()
		var c_ctrl = target_entity.get_node_or_null("PlayerCombatController")
		if c_ctrl != null:
			if c_ctrl.has_method("is_parrying") and bool(c_ctrl.call("is_parrying")):
				is_parrying_now = true
			var aim_d: Vector2 = c_ctrl.get("current_aim_dir")
			if not is_rolling_now and aim_d.length_squared() > 0.01:
				facing = aim_d.normalized()
			if bool(c_ctrl.get("is_drawing_bow")):
				bow_draw = float(c_ctrl.get("bow_tension"))
			var atk_t: float = float(c_ctrl.get("attack_timer"))
			if atk_t > 0.0:
				atk_prog = clampf(1.0 - (atk_t / maxf(0.05, float(c_ctrl.get("swing_duration")) if c_ctrl.get("swing_duration") != null else 0.36)), 0.0, 1.0)
		if not is_rolling_now and vel.length_squared() > 9.0 and atk_prog <= 0.0 and bow_draw <= 0.0 and not is_parrying_now:
			facing = vel.normalized()
		if target_entity.has_method("is_stunned") and bool(target_entity.call("is_stunned")):
			is_downed = true
		# Montado: mira hacia donde mira el caballo y va sentado.
		if bool(target_entity.get("is_mounted")):
			is_mounted_now = true
			var horse = target_entity.get_tree().get_first_node_in_group("player_horse")
			if horse != null and horse.has_method("get_facing_2d") and atk_prog <= 0.0 and bow_draw <= 0.0:
				facing = horse.get_facing_2d()
	else:
		facing = target_entity.get("facing_direction") if "facing_direction" in target_entity else Vector2.DOWN
		if vel.length_squared() > 4.0:
			facing = vel.normalized()
		is_working = bool(target_entity.get("_is_actively_crafting")) or float(target_entity.get("_anim_action_timer")) > 0.0
		is_fighting = target_entity.has_method("is_in_live_fight") and bool(target_entity.call("is_in_live_fight"))
		is_hostile = bool(target_entity.get("is_hostile"))
		is_sleeping = bool(target_entity.get("is_sleeping"))
		is_downed = bool(target_entity.get("is_downed")) or bool(target_entity.get("is_stunned_flag"))
		is_dead = bool(target_entity.get("is_dead"))
		var w_t: float = maxf(float(target_entity.get("_melee_windup_timer")), float(target_entity.get("_police_baton_windup_timer")))
		if w_t > 0.0:
			atk_prog = clampf(1.0 - (w_t / 0.40), 0.05, 0.95)
			is_working = false
		if vel.length_squared() < 4.0 and not is_sleeping and not is_downed and not is_dead and not is_fighting and not is_working and not is_hostile:
			var tav_s = preload("res://scripts/systems/VillageTavern.gd")
			var rest_s = preload("res://scripts/systems/VillageRestaurant.gd")
			if tav_s.is_at_seat(target_entity.global_position):
				is_mounted_now = true
				var tc_t: Vector2 = tav_s.table_center_for_seat(target_entity.global_position)
				if tc_t.distance_to(target_entity.global_position) > 1.0:
					facing = (tc_t - target_entity.global_position).normalized()
			elif rest_s.is_at_seat(target_entity.global_position):
				is_mounted_now = true
				var tc_r: Vector2 = rest_s.table_center_for_seat(target_entity.global_position)
				if tc_r.distance_to(target_entity.global_position) > 1.0:
					facing = (tc_r - target_entity.global_position).normalized()

	var state_dict := {
		"facing": facing,
		"speed_ratio": clampf(spd / 110.0, 0.0, 2.5),
		"is_stealth": is_stealth,
		"is_sprinting": is_sprinting,
		"is_working": is_working,
		"is_fighting": is_fighting,
		"is_hostile": is_hostile,
		"is_sleeping": is_sleeping,
		"is_downed": is_downed,
		"is_dead": is_dead,
		"bow_draw": bow_draw,
		"attack_progress": atk_prog,
		"is_mounted": is_mounted_now,
		"is_rolling": is_rolling_now,
		"roll_progress": roll_prog_now,
		"is_parrying": is_parrying_now
	}
	rig_3d.call("update_pose", delta, state_dict)

	if display_sprite:
		if is_player_avatar:
			var alpha_p: float = 0.62 if is_stealth else 1.0
			var hit_fl: float = float(target_entity.get("_hit_flash_timer"))
			var blood_t: float = float(target_entity.get("bloodstained_timer"))
			if hit_fl > 0.0:
				display_sprite.modulate = Color(1.5, 0.4, 0.4, alpha_p)
			elif blood_t > 0.0:
				display_sprite.modulate = Color(1.0, 0.74, 0.74, alpha_p)
			else:
				display_sprite.modulate = Color(1.0, 1.0, 1.0, alpha_p)
		else:
			var spr_orig = target_entity.get("sprite")
			if spr_orig is Sprite2D:
				display_sprite.modulate = (spr_orig as Sprite2D).modulate
