extends Node2D

## Puente de Renderizado 3D en Vivo para Jugador y Vecinos — Fase 1 (Transición 3D)
## Envuelve un `CharacterRig3D` dentro de un `SubViewport` transparente por personaje (desactivado automáticamente
## fuera de cámara o en modo headless para mantener 0 ms de sobrecarga en tests y 100 vecinos).
## Permite alternar en caliente con [F9] entre las nuevas Maquetas 3D Articuladas y los Sprites 2D originales.

const CharacterRig3DScript = preload("res://scripts/visuals/CharacterRig3D.gd")

static var use_3d_characters: bool = true

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

	sub_viewport = SubViewport.new()
	sub_viewport.name = "AvatarSubViewport"
	sub_viewport.size = Vector2i(96, 96)
	sub_viewport.transparent_bg = true
	sub_viewport.own_world_3d = true
	sub_viewport.msaa_3d = Viewport.MSAA_2X
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub_viewport)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.88, 0.90, 0.96)
	env.ambient_light_energy = 0.78
	env_node.environment = env
	sub_viewport.add_child(env_node)

	dir_light = DirectionalLight3D.new()
	dir_light.rotation_degrees = Vector3(-48.0, 32.0, 0.0)
	dir_light.light_energy = 1.15
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
	display_sprite.scale = Vector2(0.46, 0.46)
	display_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(display_sprite)

	_sync_appearance_now()
	_apply_2d_vs_3d_visibility()

func trigger_muzzle_flash() -> void:
	if rig_3d and rig_3d.has_method("trigger_muzzle_flash"):
		rig_3d.call("trigger_muzzle_flash")

func mark_appearance_dirty() -> void:
	_appearance_dirty = true

func _process(delta: float) -> void:
	if not is_instance_valid(target_entity) or rig_3d == null:
		return

	if _last_was_3d != use_3d_characters:
		_last_was_3d = use_3d_characters
		_apply_2d_vs_3d_visibility()

	if not use_3d_characters:
		if sub_viewport:
			sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return

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

func _is_entity_near_camera() -> bool:
	var vp := get_viewport()
	if vp == null:
		return true
	var cam2d := vp.get_camera_2d()
	if cam2d == null:
		return true
	var center: Vector2 = cam2d.get_screen_center_position()
	var zoom_val: float = maxf(0.25, cam2d.zoom.x)
	var half_ext: Vector2 = (vp.get_visible_rect().size / zoom_val) * 0.55 + Vector2(90.0, 90.0)
	return absf(target_entity.global_position.x - center.x) <= half_ext.x and absf(target_entity.global_position.y - center.y) <= half_ext.y

func _apply_2d_vs_3d_visibility() -> void:
	if display_sprite:
		display_sprite.visible = use_3d_characters
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
		return "%s|%s|%s|%s" % [w_name, arm_str, t_tier_str, amp_str]
	else:
		var role_i: int = int(target_entity.get("trade_role"))
		var work_b: bool = bool(target_entity.get("_is_actively_crafting"))
		var hr: int = int(WorldClock.current_hour) if WorldClock != null else 12
		var night_b: bool = (hr >= 20 or hr < 6)
		var amp_npc: String = _get_limb_signature_for_entity(target_entity)
		return "%d|%s|%s|%s" % [role_i, str(work_b), str(night_b), amp_npc]

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
				var reg: String = str(rec.get("region", "left_leg")).to_lower()
				var has_prost: bool = bool(rec.get("has_prosthetic", false))
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
		Color(0.96, 0.83, 0.72)
	]
	var hair_palette: Array[Color] = [
		Color(0.20, 0.13, 0.08),
		Color(0.38, 0.22, 0.12),
		Color(0.68, 0.52, 0.26),
		Color(0.52, 0.22, 0.14),
		Color(0.14, 0.14, 0.16)
	]
	var hair_col: Color = Color(0.76, 0.76, 0.80) if age_val >= 54 else hair_palette[h_val % hair_palette.size()]
	var skin_col: Color = skin_palette[(h_val / 3) % skin_palette.size()]

	var tunic_col := Color(0.36, 0.48, 0.38)
	var pants_col := Color(0.24, 0.22, 0.20)
	var has_apron := false
	var apron_col := Color(0.52, 0.34, 0.18)
	var has_cape := false
	var cape_col := Color(0.58, 0.14, 0.18)
	var headgear := "none"
	var chest_tier := 0
	var weapon_k := "none"
	var offhand_k := "none"
	var has_beard: bool = (not is_fem and not is_child) and (role_id in [3, 4, 5, 7, 11] or (h_val % 3 == 0))

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
			weapon_k = "sword"
		10: # GUARD
			tunic_col = Color(0.25, 0.36, 0.56)
			headgear = "helm_t2"
			chest_tier = 2
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
			weapon_k = "sword"
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
		_:
			var fallback_tunics: Array[Color] = [
				Color(0.34, 0.50, 0.42),
				Color(0.52, 0.38, 0.28),
				Color(0.38, 0.44, 0.58),
				Color(0.58, 0.46, 0.32)
			]
			tunic_col = fallback_tunics[h_val % fallback_tunics.size()]

	var is_working_now: bool = bool(target_entity.get("_is_actively_crafting")) or int(target_entity.get("current_activity")) == 0
	var is_guard_role: bool = role_id in [9, 10, 12]
	if not is_working_now and not is_guard_role and not bool(target_entity.get("is_hostile")):
		weapon_k = "none"

	var hr_now: int = int(WorldClock.current_hour) if WorldClock != null else 12
	if (hr_now >= 20 or hr_now < 6) and offhand_k == "none" and not bool(target_entity.get("is_sleeping")):
		offhand_k = "lantern"

	var cfg := {
		"skin_color": skin_col,
		"hair_color": hair_col,
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

	if is_player_avatar:
		var m_ctrl = target_entity.get_node_or_null("PlayerMovementController")
		if m_ctrl != null:
			is_stealth = bool(m_ctrl.get("is_stealthing"))
			is_sprinting = bool(m_ctrl.get("is_sprinting"))
		var c_ctrl = target_entity.get_node_or_null("PlayerCombatController")
		if c_ctrl != null:
			var aim_d: Vector2 = c_ctrl.get("current_aim_dir")
			if aim_d.length_squared() > 0.01:
				facing = aim_d.normalized()
			if bool(c_ctrl.get("is_drawing_bow")):
				bow_draw = float(c_ctrl.get("bow_tension"))
			var atk_t: float = float(c_ctrl.get("attack_timer"))
			if atk_t > 0.0:
				atk_prog = clampf(1.0 - (atk_t / 0.36), 0.0, 1.0)
		if vel.length_squared() > 9.0 and atk_prog <= 0.0 and bow_draw <= 0.0:
			facing = vel.normalized()
		if target_entity.has_method("is_stunned") and bool(target_entity.call("is_stunned")):
			is_downed = true
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

	var state_dict := {
		"facing": facing,
		"speed_ratio": clampf(spd / 110.0, 0.0, 1.6),
		"is_stealth": is_stealth,
		"is_sprinting": is_sprinting,
		"is_working": is_working,
		"is_fighting": is_fighting,
		"is_hostile": is_hostile,
		"is_sleeping": is_sleeping,
		"is_downed": is_downed,
		"is_dead": is_dead,
		"bow_draw": bow_draw,
		"attack_progress": atk_prog
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
