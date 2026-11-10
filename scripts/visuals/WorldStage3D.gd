@tool
extends "res://scripts/visuals/WorldStageTerrain3D.gd"
const _AN_SITIOS = preload("res://mapa/anclas.gd") # plan de sitios: zonas fijas siguen a lo movido

## Escenario 3D principal: ciclo de vida, cámara en 1.ª persona y vista superior, brazos/armas 3D, HUD y cutaway.

func set_detective_topdown(active: bool, world_pos_2d: Vector2 = Vector2.ZERO, ortho_size: float = 4.2) -> Texture2D:
	detective_topdown_active = active
	detective_topdown_pos = world_pos_2d
	detective_topdown_size = ortho_size
	if stage_root_3d != null and is_instance_valid(stage_root_3d):
		var chars := stage_root_3d.get_node_or_null("Characters3D") as Node3D
		if chars != null:
			chars.visible = not active
	if not _is_headless:
		if active:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif first_person_active:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if cam_3d != null and not active and not first_person_active:
		cam_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam_3d.rotation_degrees = Vector3(-PITCH_DEG, 0.0, 0.0)
	_update_roof_cutaways_and_lighting()
	_sync_camera_with_2d()
	return sub_viewport.get_texture() if sub_viewport != null else null


func setup_stage(village_manager: Node2D) -> void:
	vm = village_manager
	name = "WorldStage3D"
	_active_stage_instance = self
	_is_headless = DisplayServer.get_name() == "headless" or Engine.is_editor_hint()
	first_person_active = false
	fp_yaw = 0.0
	fp_pitch = 0.0

	stage_root_3d = Node3D.new()
	stage_root_3d.name = "StageRoot3D"

	terrain_root_3d = Node3D.new()
	terrain_root_3d.name = "Terrain3D"
	stage_root_3d.add_child(terrain_root_3d)

	buildings_root_3d = Node3D.new()
	buildings_root_3d.name = "Buildings3D"
	stage_root_3d.add_child(buildings_root_3d)

	lots_root_3d = Node3D.new()
	lots_root_3d.name = "Lots3D"
	stage_root_3d.add_child(lots_root_3d)

	streetlights_root_3d = Node3D.new()
	streetlights_root_3d.name = "Streetlights3D"
	stage_root_3d.add_child(streetlights_root_3d)

	sewers_root_3d = Node3D.new()
	sewers_root_3d.name = "Sewers3D"
	sewers_root_3d.visible = false
	stage_root_3d.add_child(sewers_root_3d)

	outpost_root_3d = Node3D.new()
	outpost_root_3d.name = "Outpost3D"
	stage_root_3d.add_child(outpost_root_3d)

	graves_root_3d = Node3D.new()
	graves_root_3d.name = "Graves3D"
	stage_root_3d.add_child(graves_root_3d)

	nature_root_3d = Node3D.new()
	nature_root_3d.name = "Nature3D"
	stage_root_3d.add_child(nature_root_3d)

	if not _is_headless:
		sub_viewport = SubViewport.new()
		sub_viewport.name = "WorldSubViewport3D"
		sub_viewport.size = Vector2i(VIEWPORT_W, VIEWPORT_H)
		sub_viewport.transparent_bg = true
		sub_viewport.own_world_3d = true
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sub_viewport.msaa_3d = Viewport.MSAA_DISABLED
		add_child(sub_viewport)

		sub_viewport.add_child(stage_root_3d)

		var env := Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		var sky_sh := Shader.new()
		sky_sh.code = SKY_CLOUD_SHADER_CODE
		_sky_mat = ShaderMaterial.new()
		_sky_mat.shader = sky_sh
		_sky_res = Sky.new()
		_sky_res.sky_material = _sky_mat
		env.sky = _sky_res
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.84, 0.86, 0.90)
		env.ambient_light_energy = 0.58
		world_env = WorldEnvironment.new()
		world_env.environment = env
		stage_root_3d.add_child(world_env)

		sun_light = DirectionalLight3D.new()
		sun_light.name = "SunLight3D"
		# Sol desde arriba a la izquierda: las sombras caen hacia abajo a la derecha, delante de las fachadas, donde se ven.
		sun_light.rotation_degrees = Vector3(-50.0, -135.0, 0.0)
		sun_light.light_energy = 0.96
		sun_light.light_color = Color(1.0, 0.95, 0.86)
		sun_light.shadow_enabled = true
		sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		sun_light.directional_shadow_max_distance = 140.0
		sun_light.shadow_bias = 0.03
		sun_light.shadow_normal_bias = 1.0
		sun_light.shadow_opacity = 0.78
		stage_root_3d.add_child(sun_light)
		if not Ajustes.cambiados.is_connected(_aplicar_ajustes_graficos):
			Ajustes.cambiados.connect(_aplicar_ajustes_graficos)
		_aplicar_ajustes_graficos.call_deferred()

		fill_light = DirectionalLight3D.new()
		fill_light.name = "FillLight3D"
		fill_light.rotation_degrees = Vector3(-35.0, 145.0, 0.0)
		fill_light.light_energy = 0.30
		fill_light.light_color = Color(0.72, 0.80, 0.94)
		fill_light.shadow_enabled = false
		stage_root_3d.add_child(fill_light)

		cam_3d = Camera3D.new()
		cam_3d.name = "WorldCamera3D"
		cam_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam_3d.rotation_degrees = Vector3(-PITCH_DEG, 0.0, 0.0)
		cam_3d.near = 0.1
		cam_3d.far = 250.0
		cam_3d.size = 12.0
		cam_3d.current = true
		stage_root_3d.add_child(cam_3d)

		fp_lantern_light = OmniLight3D.new()
		fp_lantern_light.name = "FPLanternLight3D"
		fp_lantern_light.light_color = Color(1.0, 0.84, 0.56)
		fp_lantern_light.light_energy = 0.0
		fp_lantern_light.omni_range = 4.2
		fp_lantern_light.visible = false
		cam_3d.add_child(fp_lantern_light)
		_setup_fp_viewmodel()

		stage_sprite = Sprite2D.new()
		stage_sprite.name = "WorldStageSprite2D"
		stage_sprite.top_level = true
		stage_sprite.z_as_relative = false
		# Por debajo de los objetos 2D del suelo con z = -1 (huertos, camas, pozos…), por encima de los decorados planos
		# (bordes, césped del bosque), que el suelo 3D sustituye.
		stage_sprite.z_index = -2
		stage_sprite.centered = true
		stage_sprite.texture = sub_viewport.get_texture()
		stage_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(stage_sprite)

		_setup_fp_hud_layer()
	else:
		cam_3d = Camera3D.new()
		cam_3d.name = "WorldCamera3D"
		cam_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam_3d.rotation_degrees = Vector3(-PITCH_DEG, 0.0, 0.0)
		cam_3d.near = 0.1
		cam_3d.far = 250.0
		cam_3d.size = 12.0
		stage_root_3d.add_child(cam_3d)
		add_child(stage_root_3d)

	_preparar_escena_editor()
	_construyendo_estatico = true
	_build_static_terrain_3d()
	_construyendo_estatico = false
	_separar_decorado()
	_cargar_decoracion_editor()
	_merge_terrain_by_chunks()
	_build_sewers_3d()
	_build_streetlights_3d()
	rebuild_all_3d()
	_sync_2d_flat_visuals(CharacterAvatar3DScript.use_3d_characters)


func rebuild_all_3d() -> void:
	if vm == null:
		return
	rebuild_buildings_3d()
	rebuild_lots_3d()
	rebuild_outpost_3d()
	rebuild_graves_3d()
	_sync_2d_flat_visuals(CharacterAvatar3DScript.use_3d_characters)


# ==============================================================================
# 6. SINCRONIZACIÓN EN VIVO (CÁMARA 3D, PUERTAS, TEJADOS CUTAWAY Y TECLA [F10])
# ==============================================================================
func _setup_fp_hud_layer() -> void:
	if _is_headless:
		return
	fp_hud_layer = CanvasLayer.new()
	fp_hud_layer.name = "FirstPersonHUDLayer"
	fp_hud_layer.layer = 2
	fp_hud_layer.visible = false
	add_child(fp_hud_layer)

	var root_ctrl := Control.new()
	root_ctrl.name = "FPHUDRoot"
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fp_hud_layer.add_child(root_ctrl)

	_fp_damage_vignette = ColorRect.new()
	_fp_damage_vignette.name = "FPDamageVignette"
	_fp_damage_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fp_damage_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fp_damage_vignette.color = Color(0.75, 0.08, 0.06, 0.0)
	_fp_damage_vignette.visible = false
	root_ctrl.add_child(_fp_damage_vignette)

	_fp_hit_flash_rect = ColorRect.new()
	_fp_hit_flash_rect.name = "FPHitConfirmFlash"
	_fp_hit_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fp_hit_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_fp_hit_flash_rect.position = Vector2(-14, -14)
	_fp_hit_flash_rect.size = Vector2(28, 28)
	_fp_hit_flash_rect.color = Color(1.0, 0.88, 0.42, 0.0)
	_fp_hit_flash_rect.visible = false
	root_ctrl.add_child(_fp_hit_flash_rect)

	fp_crosshair = Control.new()
	fp_crosshair.name = "FPCrosshair"
	fp_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fp_crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	root_ctrl.add_child(fp_crosshair)
	for rect_def in [
		[Rect2(-7, -1.5, 14, 3), Color(0.05, 0.06, 0.08, 0.85)],
		[Rect2(-1.5, -7, 3, 14), Color(0.05, 0.06, 0.08, 0.85)],
		[Rect2(-6, -0.5, 12, 1), Color(0.98, 0.96, 0.86, 0.95)],
		[Rect2(-0.5, -6, 1, 12), Color(0.98, 0.96, 0.86, 0.95)],
	]:
		var cr := ColorRect.new()
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cr.position = rect_def[0].position
		cr.size = rect_def[0].size
		cr.color = rect_def[1]
		fp_crosshair.add_child(cr)

	fp_interact_label = Label.new()
	fp_interact_label.name = "FPInteractLabel"
	fp_interact_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fp_interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fp_interact_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	fp_interact_label.position = Vector2(-220, 18)
	fp_interact_label.custom_minimum_size = Vector2(440, 24)
	fp_interact_label.add_theme_font_size_override("font_size", 14)
	fp_interact_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.72))
	fp_interact_label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06, 0.95))
	fp_interact_label.add_theme_constant_override("outline_size", 4)
	fp_interact_label.visible = false
	root_ctrl.add_child(fp_interact_label)

	fp_mode_badge = Label.new()
	fp_mode_badge.name = "FPModeBadge"
	fp_mode_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fp_mode_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fp_mode_badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	fp_mode_badge.position = Vector2(-260, 40)
	fp_mode_badge.custom_minimum_size = Vector2(520, 20)
	fp_mode_badge.add_theme_font_size_override("font_size", 11)
	fp_mode_badge.add_theme_color_override("font_color", Color(0.86, 0.92, 0.98, 0.88))
	fp_mode_badge.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06, 0.92))
	fp_mode_badge.add_theme_constant_override("outline_size", 3)
	fp_mode_badge.text = ""
	fp_mode_badge.visible = false
	root_ctrl.add_child(fp_mode_badge)

func _is_ui_blocking_fp() -> bool:
	if not is_inside_tree():
		return false
	var pl := get_tree().get_first_node_in_group("player")
	if is_instance_valid(pl):
		if pl.has_method("is_any_ui_modal_open") and pl.call("is_any_ui_modal_open") == true:
			return true
		var dm = pl.get("dialogue_manager")
		if dm and dm.has_method("is_active") and dm.call("is_active") == true:
			return true
	return false

func toggle_first_person() -> bool:
	set_first_person(not first_person_active)
	return first_person_active

func set_first_person(enable: bool) -> void:
	if enable:
		if not CharacterAvatar3DScript.use_3d_characters:
			CharacterAvatar3DScript.use_3d_characters = true
			_last_use_3d = true
			_sync_2d_flat_visuals(true)
		first_person_active = true
		fp_pitch = 0.0
		_fp_shake_timer = 0.0
		_fp_shake_amp = 0.0
		_fp_camera_punch_pitch = 0.0
		_fp_camera_punch_roll = 0.0
		var pl := get_tree().get_first_node_in_group("player") as Node2D if is_inside_tree() else null
		if is_instance_valid(pl):
			var c_ctrl = pl.get_node_or_null("PlayerCombatController")
			if c_ctrl != null and c_ctrl.get("current_aim_dir") is Vector2 and (c_ctrl.get("current_aim_dir") as Vector2).length_squared() > 0.01:
				fp_yaw = (c_ctrl.get("current_aim_dir") as Vector2).angle()
			else:
				match str(pl.get("last_dir")):
					"right": fp_yaw = 0.0
					"left": fp_yaw = PI
					"up": fp_yaw = -PI * 0.5
					_: fp_yaw = PI * 0.5
		_sync_player_aim_from_fp()
		_update_fp_camera_transform()
		_update_roof_cutaways_and_lighting()
		if not _is_headless:
			if is_instance_valid(sub_viewport):
				sub_viewport.transparent_bg = false
			if is_instance_valid(stage_sprite):
				stage_sprite.z_index = 120
			if is_instance_valid(fp_hud_layer):
				fp_hud_layer.visible = true
			if not _is_ui_blocking_fp():
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if is_instance_valid(pl) and pl.has_method("show_hint"):
			pl.call("show_hint", "👁️ Vista en 1.ª persona activada ([P] para salir)")
	else:
		first_person_active = false
		fp_pitch = 0.0
		if is_instance_valid(_fp_viewmodel_root):
			_fp_viewmodel_root.visible = false
		if cam_3d != null:
			cam_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
			cam_3d.rotation_degrees = Vector3(-PITCH_DEG, 0.0, 0.0)
			cam_3d.near = 0.1
			cam_3d.far = 250.0
		if not _is_headless:
			if is_instance_valid(sub_viewport):
				sub_viewport.transparent_bg = true
			if is_instance_valid(world_env) and world_env.environment != null:
				world_env.environment.background_mode = Environment.BG_CLEAR_COLOR
				world_env.environment.fog_enabled = false
			if is_instance_valid(stage_sprite):
				stage_sprite.z_index = -2
			if is_instance_valid(fp_hud_layer):
				fp_hud_layer.visible = false
			if is_instance_valid(fp_lantern_light):
				fp_lantern_light.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if _is_ui_blocking_fp() else Input.MOUSE_MODE_HIDDEN)
		_sync_player_aim_from_fp()
		_sync_camera_with_2d()
		_update_roof_cutaways_and_lighting()
		var pl2 := get_tree().get_first_node_in_group("player") as Node2D if is_inside_tree() else null
		if is_instance_valid(pl2) and pl2.has_method("show_hint"):
			pl2.call("show_hint", "🎥 [P] Vista superior 2.5D restaurada ([F9] alterna 3D/2D)")

func rotate_first_person_view(delta_x_px: float, delta_y_px: float = 0.0) -> void:
	var sens: float = FP_MOUSE_SENS * float(Ajustes.get_valor("sensibilidad")) # Ajustes → Juego
	var inv_y: float = -1.0 if bool(Ajustes.get_valor("invertir_y")) else 1.0
	fp_yaw = wrapf(fp_yaw + delta_x_px * sens, -PI, PI)
	fp_pitch = clampf(fp_pitch - delta_y_px * sens * inv_y, -FP_MAX_PITCH, FP_MAX_PITCH)
	_sync_player_aim_from_fp()
	_update_fp_camera_transform()

func _sync_player_aim_from_fp() -> void:
	if not is_inside_tree():
		return
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(pl):
		return
	var av = pl.get("avatar_3d")
	if av != null and is_instance_valid(av.get("_holder")):
		(av.get("_holder") as Node3D).visible = not first_person_active
	if not first_person_active:
		return
	var dir_2d: Vector2 = get_fp_forward_2d()
	var c_ctrl = pl.get_node_or_null("PlayerCombatController")
	if c_ctrl != null and not (c_ctrl.get("_swing_locked") == true):
		c_ctrl.current_aim_dir = dir_2d
		var wp = c_ctrl.get("weapon_pivot")
		if is_instance_valid(wp):
			(wp as Node2D).rotation = dir_2d.angle()
	var ch = pl.get_node_or_null("Crosshair2D")
	if ch != null:
		var dist: float = 75.0 if (ch.get("is_ranged_mode") == true) else 42.0
		ch.aim_offset = dir_2d * dist
		ch.global_position = pl.global_position + Vector2(0, -10) + dir_2d * dist
	if absf(dir_2d.x) >= absf(dir_2d.y):
		pl.last_dir = "right" if dir_2d.x >= 0.0 else "left"
	else:
		pl.last_dir = "down" if dir_2d.y >= 0.0 else "up"


func _add_fp_arm_limb(arm_root: Node3D, is_right: bool, mat_sleeve: Material, mat_cuff: Material, mat_skin: Material, mat_gold: Material) -> void:
	# Antebrazo redondeado con manga de paño y codo suave (compacto tras la muñeca para no invadir la vista al girar)
	var sleeve_mi := MeshInstance3D.new()
	var sleeve_cyl := CylinderMesh.new()
	sleeve_cyl.top_radius = 0.026
	sleeve_cyl.bottom_radius = 0.033
	sleeve_cyl.height = 0.16
	sleeve_cyl.radial_segments = 16
	sleeve_mi.mesh = sleeve_cyl
	sleeve_mi.position = Vector3(0.0, -0.004, 0.055)
	sleeve_mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	sleeve_mi.material_override = mat_sleeve
	sleeve_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(sleeve_mi)

	var elbow_mi := MeshInstance3D.new()
	var elbow_sph := SphereMesh.new()
	elbow_sph.radius = 0.032
	elbow_sph.height = 0.064
	elbow_mi.mesh = elbow_sph
	elbow_mi.position = Vector3(0.0, -0.004, 0.135)
	elbow_mi.material_override = mat_sleeve
	elbow_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(elbow_mi)

	# Muñequera / puño de cuero redondeado con pasador de latón
	var cuff_mi := MeshInstance3D.new()
	var cuff_cyl := CylinderMesh.new()
	cuff_cyl.top_radius = 0.026
	cuff_cyl.bottom_radius = 0.030
	cuff_cyl.height = 0.052
	cuff_cyl.radial_segments = 16
	cuff_mi.mesh = cuff_cyl
	cuff_mi.position = Vector3(0.0, -0.003, -0.022)
	cuff_mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	cuff_mi.material_override = mat_cuff
	cuff_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(cuff_mi)

	var ring_mi := MeshInstance3D.new()
	var ring_cyl := CylinderMesh.new()
	ring_cyl.top_radius = 0.0285
	ring_cyl.bottom_radius = 0.0285
	ring_cyl.height = 0.008
	ring_cyl.radial_segments = 16
	ring_mi.mesh = ring_cyl
	ring_mi.position = Vector3(0.0, -0.003, -0.040)
	ring_mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	ring_mi.material_override = mat_gold
	ring_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(ring_mi)

	# Muñeca y palma orgánica (esfera achatada / cápsula anatómica, no caja)
	var wrist_mi := MeshInstance3D.new()
	var wrist_sph := SphereMesh.new()
	wrist_sph.radius = 0.023
	wrist_sph.height = 0.046
	wrist_mi.mesh = wrist_sph
	wrist_mi.position = Vector3(0.0, -0.002, -0.054)
	wrist_mi.material_override = mat_skin
	wrist_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(wrist_mi)

	var palm_mi := MeshInstance3D.new()
	var palm_sph := SphereMesh.new()
	palm_sph.radius = 0.029
	palm_sph.height = 0.058
	palm_mi.mesh = palm_sph
	palm_mi.position = Vector3(0.0, -0.002, -0.084)
	palm_mi.scale = Vector3(1.08, 0.72, 1.24)
	palm_mi.material_override = mat_skin
	palm_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(palm_mi)

	# Pulgar e hilera de 4 dedos articulados con cápsulas redondeadas
	var s_dir: float = -1.0 if is_right else 1.0
	var thumb_mi := MeshInstance3D.new()
	var thumb_cap := CapsuleMesh.new()
	thumb_cap.radius = 0.0082
	thumb_cap.height = 0.036
	thumb_mi.mesh = thumb_cap
	thumb_mi.position = Vector3(s_dir * 0.024, 0.010, -0.092)
	thumb_mi.rotation_degrees = Vector3(32.0, s_dir * -24.0, s_dir * -36.0)
	thumb_mi.material_override = mat_skin
	thumb_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(thumb_mi)

	var finger_x_offsets: Array[float] = [-0.019, -0.006, 0.007, 0.019]
	var finger_lengths: Array[float] = [0.032, 0.035, 0.033, 0.028]
	for f_idx in range(4):
		var fx: float = finger_x_offsets[f_idx] * (-1.0 if is_right else 1.0)
		var flen: float = finger_lengths[f_idx]
		var f_mi := MeshInstance3D.new()
		var f_cap := CapsuleMesh.new()
		f_cap.radius = 0.0068
		f_cap.height = flen
		f_mi.mesh = f_cap
		if is_right:
			# Dedos cerrados empuñando el mango
			f_mi.position = Vector3(fx, 0.006, -0.114)
			f_mi.rotation_degrees = Vector3(18.0, 0.0, -68.0)
		else:
			# Dedos semicurvados de la mano izquierda de apoyo
			f_mi.position = Vector3(fx, 0.002, -0.116)
			f_mi.rotation_degrees = Vector3(52.0, 0.0, 22.0)
		f_mi.material_override = mat_skin
		f_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arm_root.add_child(f_mi)

func _setup_fp_viewmodel() -> void:
	if cam_3d == null or _is_headless:
		return
	_fp_viewmodel_root = Node3D.new()
	_fp_viewmodel_root.name = "FPViewmodelRoot"
	_fp_viewmodel_root.visible = false
	cam_3d.add_child(_fp_viewmodel_root)

	var mat_sleeve := _mat("fp_vm_sleeve", Color(0.24, 0.22, 0.19), 0.90)
	var mat_cuff := _mat("fp_vm_cuff", Color(0.36, 0.26, 0.17), 0.85)
	var mat_skin := _mat("fp_vm_skin", Color(0.84, 0.67, 0.54), 0.78)
	var mat_steel := _mat("fp_vm_steel", Color(0.74, 0.77, 0.82), 0.35, 0.65)
	var mat_dark_iron := _mat("fp_vm_iron", Color(0.26, 0.28, 0.31), 0.50, 0.55)
	var mat_wood := _mat("fp_vm_wood", Color(0.44, 0.29, 0.16), 0.86)
	var mat_gold := _mat("fp_vm_gold", Color(0.76, 0.62, 0.26), 0.42, 0.55)

	# Brazo izquierdo (guardia / equilibrio / arco) con antebrazo cilíndrico, palma redondeada y dedos
	_fp_left_arm = Node3D.new()
	_fp_left_arm.name = "FPLeftArm"
	_fp_left_arm.position = Vector3(-0.22, -0.21, -0.34)
	_fp_left_arm.rotation_degrees = Vector3(18.0, 16.0, -14.0)
	_fp_viewmodel_root.add_child(_fp_left_arm)
	_add_fp_arm_limb(_fp_left_arm, false, mat_sleeve, mat_cuff, mat_skin, mat_gold)

	# Brazo derecho (empuña el arma activa) con antebrazo cilíndrico, palma redondeada y dedos
	_fp_right_arm = Node3D.new()
	_fp_right_arm.name = "FPRightArm"
	_fp_right_arm.position = Vector3(0.23, -0.20, -0.36)
	_fp_right_arm.rotation_degrees = Vector3(14.0, -14.0, 10.0)
	_fp_viewmodel_root.add_child(_fp_right_arm)
	_add_fp_arm_limb(_fp_right_arm, true, mat_sleeve, mat_cuff, mat_skin, mat_gold)

	_fp_weapon_mount = Node3D.new()
	_fp_weapon_mount.name = "FPWeaponMount"
	_fp_weapon_mount.position = Vector3(0.0, 0.01, -0.11)
	_fp_right_arm.add_child(_fp_weapon_mount)

	# Estela fina y semitransparente de filo (solo visible durante la fase "active" del golpe)
	_fp_swing_trail = MeshInstance3D.new()
	var tr_prism := BoxMesh.new()
	tr_prism.size = Vector3(0.052, 0.39, 0.0022)
	_fp_swing_trail.mesh = tr_prism
	_fp_swing_trail.position = Vector3(0.032, 0.26, 0.014)
	_fp_swing_trail.rotation_degrees = Vector3(0.0, -18.0, 0.0)
	var mat_trail := StandardMaterial3D.new()
	mat_trail.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_trail.albedo_color = Color(0.84, 0.92, 1.0, 0.26)
	mat_trail.emission_enabled = true
	mat_trail.emission = Color(0.80, 0.90, 1.0)
	mat_trail.emission_energy_multiplier = 0.32
	mat_trail.cull_mode = BaseMaterial3D.CULL_DISABLED
	_fp_swing_trail.material_override = mat_trail
	_fp_swing_trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fp_swing_trail.visible = false
	# Cinta secundaria aún más tenue en el borde de salida del tajo
	var mat_trail_soft := StandardMaterial3D.new()
	mat_trail_soft.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_trail_soft.albedo_color = Color(0.84, 0.92, 1.0, 0.12)
	mat_trail_soft.cull_mode = BaseMaterial3D.CULL_DISABLED
	var trail_wisp := MeshInstance3D.new()
	var wisp_prism := BoxMesh.new()
	wisp_prism.size = Vector3(0.044, 0.35, 0.0016)
	trail_wisp.mesh = wisp_prism
	trail_wisp.position = Vector3(0.038, -0.01, 0.010)
	trail_wisp.material_override = mat_trail_soft
	trail_wisp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fp_swing_trail.add_child(trail_wisp)
	_fp_weapon_mount.add_child(_fp_swing_trail)

	# 1. Espada ("sword")
	var w_sword := Node3D.new()
	_add_box(w_sword, Vector3(0.028, 0.11, 0.032), Vector3(0.0, -0.02, 0.0), mat_wood)
	_add_box(w_sword, Vector3(0.038, 0.028, 0.038), Vector3(0.0, -0.08, 0.0), mat_gold)
	_add_box(w_sword, Vector3(0.14, 0.024, 0.038), Vector3(0.0, 0.04, 0.0), mat_gold)
	_add_box(w_sword, Vector3(0.016, 0.42, 0.044), Vector3(0.0, 0.26, 0.0), mat_steel)
	_add_box(w_sword, Vector3(0.020, 0.05, 0.026), Vector3(0.0, 0.49, 0.0), mat_steel)
	_fp_weapon_mount.add_child(w_sword)
	_fp_weapon_meshes["sword"] = w_sword

	# 2. Martillo ("hammer")
	var w_hammer := Node3D.new()
	_add_box(w_hammer, Vector3(0.032, 0.38, 0.032), Vector3(0.0, 0.14, 0.0), mat_wood)
	_add_box(w_hammer, Vector3(0.09, 0.10, 0.19), Vector3(0.0, 0.34, 0.0), mat_dark_iron)
	_add_box(w_hammer, Vector3(0.096, 0.092, 0.03), Vector3(0.0, 0.34, -0.095), mat_steel)
	_fp_weapon_mount.add_child(w_hammer)
	_fp_weapon_meshes["hammer"] = w_hammer

	# 3. Hacha ("axe")
	var w_axe := Node3D.new()
	_add_box(w_axe, Vector3(0.030, 0.36, 0.032), Vector3(0.0, 0.13, 0.0), mat_wood)
	_add_box(w_axe, Vector3(0.036, 0.11, 0.13), Vector3(0.0, 0.29, -0.04), mat_dark_iron)
	_add_box(w_axe, Vector3(0.018, 0.14, 0.05), Vector3(0.0, 0.29, -0.11), mat_steel)
	_fp_weapon_mount.add_child(w_axe)
	_fp_weapon_meshes["axe"] = w_axe

	# 4. Pico ("pickaxe")
	var w_pick := Node3D.new()
	_add_box(w_pick, Vector3(0.030, 0.36, 0.030), Vector3(0.0, 0.13, 0.0), mat_wood)
	_add_box(w_pick, Vector3(0.034, 0.045, 0.24), Vector3(0.0, 0.31, 0.0), mat_dark_iron)
	_add_box(w_pick, Vector3(0.022, 0.032, 0.06), Vector3(0.0, 0.30, -0.14), mat_steel)
	_fp_weapon_mount.add_child(w_pick)
	_fp_weapon_meshes["pickaxe"] = w_pick

	# 5. Hoz ("sickle")
	var w_sickle := Node3D.new()
	_add_box(w_sickle, Vector3(0.028, 0.14, 0.028), Vector3(0.0, 0.02, 0.0), mat_wood)
	_add_box(w_sickle, Vector3(0.016, 0.16, 0.04), Vector3(0.0, 0.16, -0.02), mat_steel)
	_add_box(w_sickle, Vector3(0.016, 0.05, 0.13), Vector3(0.0, 0.23, -0.08), mat_steel)
	_fp_weapon_mount.add_child(w_sickle)
	_fp_weapon_meshes["sickle"] = w_sickle

	# 6. Arco ("bow")
	var w_bow := Node3D.new()
	_add_box(w_bow, Vector3(0.026, 0.42, 0.032), Vector3(-0.08, 0.14, -0.04), mat_wood)
	_add_box(w_bow, Vector3(0.006, 0.40, 0.006), Vector3(-0.08, 0.14, 0.02), _mat("fp_vm_bowstring", Color(0.86, 0.82, 0.72), 0.8))
	_fp_weapon_mount.add_child(w_bow)
	_fp_weapon_meshes["bow"] = w_bow

	# 7. Pistola de Cartuchos ("flintlock" / "pistol")
	var w_gun := Node3D.new()
	var pistol_obj: Node3D = AssetLib.instantiate_model("weapons/Pistol_1.obj", Vector3.ZERO, 0.095, true, false)
	if pistol_obj != null:
		pistol_obj.position = Vector3(0.0, 0.02, -0.05)
		pistol_obj.rotation_degrees = Vector3(0.0, 180.0, 0.0)
		w_gun.add_child(pistol_obj)
	_add_box(w_gun, Vector3(0.036, 0.11, 0.065), Vector3(0.0, 0.00, 0.02), mat_wood) # Empuñadura de nogal
	_add_box(w_gun, Vector3(0.042, 0.056, 0.24), Vector3(0.0, 0.058, -0.09), mat_dark_iron) # Armazón pavonado
	var p_barrel := MeshInstance3D.new()
	var p_cyl := CylinderMesh.new()
	p_cyl.top_radius = 0.015
	p_cyl.bottom_radius = 0.016
	p_cyl.height = 0.29
	p_barrel.mesh = p_cyl
	p_barrel.position = Vector3(0.0, 0.076, -0.145)
	p_barrel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	p_barrel.material_override = mat_steel
	w_gun.add_child(p_barrel)
	_add_box(w_gun, Vector3(0.012, 0.026, 0.018), Vector3(0.0, 0.095, 0.01), mat_gold) # Martillo percutor
	_add_box(w_gun, Vector3(0.008, 0.016, 0.012), Vector3(-0.011, 0.092, -0.02), mat_dark_iron) # Alza izq
	_add_box(w_gun, Vector3(0.008, 0.016, 0.012), Vector3(0.011, 0.092, -0.02), mat_dark_iron) # Alza der
	_add_box(w_gun, Vector3(0.008, 0.020, 0.012), Vector3(0.0, 0.096, -0.27), mat_gold) # Punto de mira
	_fp_weapon_mount.add_child(w_gun)
	_fp_weapon_meshes["flintlock"] = w_gun

	# 8. Fusil de Cartuchos del Paso ("rifle")
	var w_rifle := Node3D.new()
	_add_box(w_rifle, Vector3(0.040, 0.095, 0.22), Vector3(0.0, 0.01, 0.10), mat_wood) # Culata de madera
	_add_box(w_rifle, Vector3(0.036, 0.10, 0.055), Vector3(0.0, -0.02, 0.01), mat_wood) # Pistolete de nogal
	_add_box(w_rifle, Vector3(0.044, 0.064, 0.34), Vector3(0.0, 0.056, -0.12), mat_dark_iron) # Cajón de mecanismos
	_add_box(w_rifle, Vector3(0.040, 0.048, 0.26), Vector3(0.0, 0.045, -0.24), mat_wood) # Guardamanos delantero
	_add_box(w_rifle, Vector3(0.044, 0.052, 0.022), Vector3(0.0, 0.052, -0.32), mat_gold) # Abrazadera de latón
	_add_box(w_rifle, Vector3(0.032, 0.13, 0.055), Vector3(0.0, -0.028, -0.14), mat_dark_iron) # Cargador de petaca
	var r_barrel := MeshInstance3D.new()
	var r_cyl := CylinderMesh.new()
	r_cyl.top_radius = 0.013
	r_cyl.bottom_radius = 0.015
	r_cyl.height = 0.52
	r_barrel.mesh = r_cyl
	r_barrel.position = Vector3(0.0, 0.075, -0.35)
	r_barrel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	r_barrel.material_override = mat_steel
	w_rifle.add_child(r_barrel)
	_add_box(w_rifle, Vector3(0.024, 0.018, 0.045), Vector3(0.032, 0.064, -0.06), mat_gold) # Maneta del cerrojo
	_add_box(w_rifle, Vector3(0.008, 0.018, 0.014), Vector3(-0.012, 0.094, -0.04), mat_dark_iron) # Alza trasera izq
	_add_box(w_rifle, Vector3(0.008, 0.018, 0.014), Vector3(0.012, 0.094, -0.04), mat_dark_iron) # Alza trasera der
	_add_box(w_rifle, Vector3(0.008, 0.024, 0.012), Vector3(0.0, 0.096, -0.56), mat_gold) # Punto de mira delantero
	_fp_weapon_mount.add_child(w_rifle)
	_fp_weapon_meshes["rifle"] = w_rifle

	# Fogonazo 3D en la boca del cañón al disparar
	var mat_mflash := StandardMaterial3D.new()
	mat_mflash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_mflash.albedo_color = Color(1.0, 0.90, 0.42, 0.92)
	mat_mflash.emission_enabled = true
	mat_mflash.emission = Color(1.0, 0.78, 0.22)
	mat_mflash.emission_energy_multiplier = 2.4
	_fp_muzzle_flash_mesh = _add_box(_fp_weapon_mount, Vector3(0.045, 0.045, 0.08), Vector3(0.0, 0.075, -0.42), mat_mflash)
	_fp_muzzle_flash_mesh.visible = false
	_fp_muzzle_light = OmniLight3D.new()
	_fp_muzzle_light.light_color = Color(1.0, 0.82, 0.38)
	_fp_muzzle_light.light_energy = 1.25
	_fp_muzzle_light.omni_range = 3.2
	_fp_muzzle_light.position = Vector3(0.0, 0.08, -0.45)
	_fp_muzzle_light.visible = false
	_fp_weapon_mount.add_child(_fp_muzzle_light)

	# 9. Puños / herramienta genérica ("fists")
	var w_fists := Node3D.new()
	_fp_weapon_mount.add_child(w_fists)
	_fp_weapon_meshes["fists"] = w_fists

func _spawn_3d_hit_effect(pos_2d: Vector2, dir_2d: Vector2, power: float = 1.0) -> void:
	if stage_root_3d == null or _is_headless:
		return
	var elev_h: float = 8.5
	if vm != null:
		elev_h += VillageTavern.elevation_height_for(pos_2d, int(vm.player_elevation_level))
	var hit_3d: Vector3 = to_3d(pos_2d - dir_2d.normalized() * 3.0, elev_h)
	var fx_root := Node3D.new()
	fx_root.name = "HitSpark3D"
	fx_root.position = hit_3d
	stage_root_3d.add_child(fx_root)

	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.86, 0.44)
	flash.light_energy = 0.85 * clampf(power, 0.9, 1.4)
	flash.omni_range = 1.1
	fx_root.add_child(flash)

	var spark_mat := StandardMaterial3D.new()
	spark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_mat.albedo_color = Color(1.0, 0.90, 0.58, 0.42)
	spark_mat.emission_enabled = true
	spark_mat.emission = Color(1.0, 0.80, 0.36)
	spark_mat.emission_energy_multiplier = 0.55
	var dirs: Array[Vector3] = [
		Vector3(0.06, 0.05, -0.03),
		Vector3(-0.05, 0.06, 0.03),
		Vector3(0.03, -0.04, 0.05),
		Vector3(-0.04, 0.03, -0.05),
		Vector3(0.07, 0.02, 0.04),
	]
	var spark_nodes: Array[MeshInstance3D] = []
	for d_v in dirs:
		var sm := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.0055 * clampf(power, 0.9, 1.3)
		sph.height = sph.radius * 2.0
		sm.mesh = sph
		sm.position = d_v * 0.25
		sm.material_override = spark_mat
		sm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fx_root.add_child(sm)
		spark_nodes.append(sm)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "light_energy", 0.0, 0.14)
	for idx in range(spark_nodes.size()):
		var sn: MeshInstance3D = spark_nodes[idx]
		tw.tween_property(sn, "position", dirs[idx] * 1.6, 0.14)
		tw.tween_property(sn, "scale", Vector3.ONE * 0.15, 0.14)
	tw.chain().tween_callback(fx_root.queue_free)

func _update_fp_viewmodel(delta: float, pl: Node2D) -> void:
	if _fp_viewmodel_root == null:
		return
	if not first_person_active or not is_instance_valid(pl) or _is_ui_blocking_fp():
		_fp_viewmodel_root.visible = false
		return
	_fp_viewmodel_root.visible = true

	var c_ctrl = pl.get_node_or_null("PlayerCombatController")
	var eq = pl.get("equipped_weapon")
	var w_key: String = str(eq.get("name")).to_lower() if eq != null else "fists"
	if w_key in ["pistol", "flintlock_pistol"]:
		w_key = "flintlock"
	elif w_key in ["assault_rifle", "rifle_weapon"]:
		w_key = "rifle"
	var mesh_key: String = w_key if _fp_weapon_meshes.has(w_key) else "sword"
	for k in _fp_weapon_meshes.keys():
		var wn: Node3D = _fp_weapon_meshes[k]
		if is_instance_valid(wn):
			wn.visible = (k == mesh_key)

	if _fp_gun_recoil_kick > 0.0:
		_fp_gun_recoil_kick = maxf(0.0, _fp_gun_recoil_kick - delta * 4.8)
	if _fp_muzzle_flash_timer > 0.0:
		_fp_muzzle_flash_timer = maxf(0.0, _fp_muzzle_flash_timer - delta)
	if is_instance_valid(_fp_muzzle_flash_mesh):
		_fp_muzzle_flash_mesh.visible = (_fp_muzzle_flash_timer > 0.0) and (mesh_key in ["flintlock", "rifle"])
		_fp_muzzle_flash_mesh.position = Vector3(0.0, 0.075, -0.58 if mesh_key == "rifle" else -0.34)
	if is_instance_valid(_fp_muzzle_light):
		_fp_muzzle_light.visible = (_fp_muzzle_flash_timer > 0.0) and (mesh_key in ["flintlock", "rifle"])
		_fp_muzzle_light.position = Vector3(0.0, 0.08, -0.62 if mesh_key == "rifle" else -0.38)

	# Balanceo al caminar y respirar
	var vel_2d: Vector2 = pl.get("velocity") if "velocity" in pl else Vector2.ZERO
	var spd_ratio: float = clampf(vel_2d.length() / 120.0, 0.0, 1.35)
	_fp_walk_bob_t += delta * (2.2 + spd_ratio * 6.8)
	var bob_x: float = sin(_fp_walk_bob_t) * (0.004 + 0.014 * spd_ratio)
	var bob_y: float = absf(cos(_fp_walk_bob_t)) * (0.003 + 0.012 * spd_ratio)

	# Peso visual según el arma (martillo y hacha descansan algo más bajos y pesados)
	var heavy_off_y: float = -0.025 if mesh_key in ["hammer", "axe", "pickaxe"] else 0.0
	var r_pos := Vector3(0.23 + bob_x, -0.20 - bob_y + heavy_off_y, -0.36)
	var r_rot := Vector3(14.0, -14.0, 10.0)
	var l_pos := Vector3(-0.22 - bob_x * 0.7, -0.22 - bob_y * 0.8, -0.34)
	var l_rot := Vector3(18.0, 16.0, -14.0)
	var show_trail: bool = false
	var ads_blend: float = 0.0

	if c_ctrl != null:
		var phase: String = str(c_ctrl.get("swing_phase"))
		var p_el: float = float(c_ctrl.get("swing_phase_elapsed"))
		var p_dur: float = maxf(0.01, float(c_ctrl.get("swing_phase_duration")))
		var prog: float = clampf(p_el / p_dur, 0.0, 1.0)
		var c_step: int = int(c_ctrl.get("combo_step"))
		var charging: bool = bool(c_ctrl.get("is_charging"))
		var charge_ratio: float = clampf(float(c_ctrl.get("charge_t")) / 0.65, 0.0, 1.0)
		var parrying: bool = c_ctrl.has_method("is_parrying") and bool(c_ctrl.call("is_parrying"))
		var blocking: bool = bool(c_ctrl.get("is_blocking"))
		var drawing_bow: bool = bool(c_ctrl.get("is_drawing_bow"))
		var bow_tens: float = float(c_ctrl.get("bow_tension"))
		ads_blend = clampf(float(c_ctrl.get("aim_down_sights_blend")) if "aim_down_sights_blend" in c_ctrl else 0.0, 0.0, 1.0)
		var rel_step: int = int(c_ctrl.get("reload_step")) if "reload_step" in c_ctrl else 0
		var rel_prog: float = clampf(float(c_ctrl.get("reload_step_progress")) if "reload_step_progress" in c_ctrl else 0.0, 0.0, 1.0)

		if mesh_key in ["flintlock", "rifle"]:
			# Posición base con arma de fuego (mano izquierda sujeta guardamanos en fusil)
			r_pos = Vector3(0.18 + bob_x * 0.5, -0.17 - bob_y * 0.5, -0.34)
			r_rot = Vector3(4.0, -6.0, 2.0)
			if mesh_key == "rifle":
				l_pos = Vector3(0.04, -0.19 - bob_y * 0.5, -0.44)
				l_rot = Vector3(12.0, 28.0, -18.0)
			# Apuntando al centro (Clic Derecho / ADS): encare preciso alineado con la cruceta central
			if ads_blend > 0.01 and rel_step == 0:
				r_pos = r_pos.lerp(Vector3(0.0, -0.095 if mesh_key == "rifle" else -0.105, -0.28), ads_blend)
				r_rot = r_rot.lerp(Vector3(0.0, 0.0, 0.0), ads_blend)
				l_pos = l_pos.lerp(Vector3(-0.04, -0.14, -0.38), ads_blend)
				l_rot = l_rot.lerp(Vector3(8.0, 18.0, -12.0), ads_blend)
			# Recarga manual en 3 pasos (5c: 1. sacar cargador, 2. meter cargador, 3. montar cerrojo)
			if rel_step == 1:
				r_pos = Vector3(0.10, -0.16, -0.32)
				r_rot = Vector3(18.0, 16.0, -28.0)
				l_pos = Vector3(0.06, -0.16, -0.36).lerp(Vector3(-0.14, -0.34, -0.26), rel_prog)
				l_rot = Vector3(24.0, 32.0, -24.0)
			elif rel_step == 2:
				r_pos = Vector3(0.10, -0.16, -0.32)
				r_rot = Vector3(18.0, 16.0, -28.0)
				l_pos = Vector3(-0.14, -0.34, -0.26).lerp(Vector3(0.06, -0.15, -0.36), rel_prog)
				l_rot = Vector3(28.0, 36.0, -18.0)
			elif rel_step == 3:
				r_pos = Vector3(0.12, -0.15, -0.30 + sin(rel_prog * PI) * 0.04)
				r_rot = Vector3(10.0, 8.0, -12.0)
				l_pos = Vector3(0.08, -0.10, -0.28 + sin(rel_prog * PI) * 0.08)
				l_rot = Vector3(32.0, 42.0, -32.0)
			# Retroceso que levanta el arma tras disparar (5b)
			if _fp_gun_recoil_kick > 0.0:
				r_pos += Vector3(0.0, 0.036 * _fp_gun_recoil_kick, 0.085 * _fp_gun_recoil_kick)
				r_rot += Vector3(26.0 * _fp_gun_recoil_kick, 0.0, 0.0)
				l_pos += Vector3(0.0, 0.025 * _fp_gun_recoil_kick, 0.065 * _fp_gun_recoil_kick)
		elif parrying or blocking:
			# Parada (Q) o guardia alta sostenida: hoja cruzada frente al pecho y antebrazo izquierdo reforzando
			var guard_lift: float = 0.03 if parrying else 0.0
			r_pos = Vector3(0.08, -0.11 + guard_lift, -0.31)
			r_rot = Vector3(8.0, -32.0, 58.0)
			l_pos = Vector3(-0.10, -0.13 + guard_lift, -0.29)
			l_rot = Vector3(28.0, 28.0, -38.0)
		elif drawing_bow:
			l_pos = Vector3(-0.06, -0.14, -0.40)
			l_rot = Vector3(6.0, 6.0, -4.0)
			r_pos = Vector3(0.16, -0.16, lerpf(-0.34, -0.20, bow_tens))
			r_rot = Vector3(10.0, -18.0, 8.0)
		elif charging:
			# Cargando golpe pesado (martillo / hacha): arma alzada atrás con temblor de tensión
			var jitter: float = sin(Time.get_ticks_msec() * 0.045) * 0.006 * charge_ratio
			r_pos = Vector3(0.28 + jitter, lerpf(-0.18, -0.05, charge_ratio), lerpf(-0.34, -0.25, charge_ratio))
			r_rot = Vector3(lerpf(14.0, 54.0, charge_ratio), lerpf(-14.0, -34.0, charge_ratio), lerpf(10.0, -28.0, charge_ratio))
			l_pos = Vector3(-0.20, lerpf(-0.22, -0.16, charge_ratio), -0.32)
			l_rot = Vector3(24.0, 20.0, -20.0)
		elif phase == "windup":
			var e_w: float = 1.0 - pow(1.0 - prog, 2.0)
			if c_step == 2:
				# 2.º golpe de cadena: prepara desde el costado izquierdo
				r_pos = r_pos.lerp(Vector3(-0.12, -0.10, -0.30), e_w)
				r_rot = r_rot.lerp(Vector3(24.0, 32.0, 48.0), e_w)
			elif c_step == 3 or mesh_key in ["hammer", "axe", "pickaxe"]:
				# 3.º golpe o arma pesada: alza sobre la cabeza con peso
				r_pos = r_pos.lerp(Vector3(0.18, -0.03, -0.26), e_w)
				r_rot = r_rot.lerp(Vector3(58.0, -24.0, -22.0), e_w)
			else:
				# 1.er golpe: echa el brazo atrás y arriba a la derecha
				r_pos = r_pos.lerp(Vector3(0.31, -0.08, -0.27), e_w)
				r_rot = r_rot.lerp(Vector3(44.0, -32.0, -26.0), e_w)
			l_pos = l_pos.lerp(Vector3(-0.24, -0.18, -0.30), e_w)
		elif phase == "active":
			show_trail = true
			var e_a: float = pow(prog, 0.65)
			if c_step == 2:
				# Revés de izquierda a derecha
				r_pos = Vector3(-0.12, -0.10, -0.32).lerp(Vector3(0.26, -0.22, -0.44), e_a)
				r_rot = Vector3(12.0, 28.0, 46.0).lerp(Vector3(-38.0, -36.0, -48.0), e_a)
			elif c_step == 3 or mesh_key in ["hammer", "axe", "pickaxe"]:
				# Descarga vertical pesada hacia delante
				r_pos = Vector3(0.14, -0.02, -0.30).lerp(Vector3(0.04, -0.28, -0.48), e_a)
				r_rot = Vector3(54.0, -16.0, -14.0).lerp(Vector3(-64.0, 8.0, 18.0), e_a)
			else:
				# Tajo diagonal de derecha a izquierda hacia el centro manteniendo mano y antebrazo visibles
				r_pos = Vector3(0.26, -0.10, -0.32).lerp(Vector3(-0.04, -0.16, -0.40), e_a)
				r_rot = Vector3(32.0, -24.0, -18.0).lerp(Vector3(-18.0, 22.0, 44.0), e_a)
			l_pos = Vector3(-0.22, -0.19, -0.32)
		elif phase == "recovery":
			var e_r: float = smoothstep(0.0, 1.0, prog)
			var start_p := Vector3(-0.12, -0.25, -0.44) if c_step != 2 else Vector3(0.24, -0.24, -0.42)
			var start_r := Vector3(-44.0, 26.0, 44.0) if c_step != 2 else Vector3(-36.0, -32.0, -42.0)
			r_pos = start_p.lerp(r_pos, e_r)
			r_rot = start_r.lerp(r_rot, e_r)
		elif phase == "shove":
			var e_s: float = sin(prog * PI)
			l_pos = l_pos.lerp(Vector3(-0.04, -0.14, -0.52), e_s)
			l_rot = l_rot.lerp(Vector3(-12.0, 8.0, -42.0), e_s)
			r_pos = r_pos.lerp(Vector3(0.26, -0.24, -0.30), e_s)

	if _fp_hurt_flash_timer > 0.0:
		var hk: float = clampf(_fp_hurt_flash_timer / 0.35, 0.0, 1.0)
		r_pos += Vector3(0.03 * hk, -0.04 * hk, 0.05 * hk)
		l_pos += Vector3(-0.04 * hk, -0.02 * hk, 0.05 * hk)

	if pl != null and pl.has_method("get_jump_height"):
		var jh_vm: float = clampf(float(pl.call("get_jump_height")) / 11.2, 0.0, 1.0)
		if jh_vm > 0.001:
			r_pos.y += 0.018 * jh_vm
			l_pos.y += 0.022 * jh_vm
			r_rot.x -= 6.0 * jh_vm
			l_rot.x -= 8.0 * jh_vm

	_fp_right_arm.position = r_pos
	_fp_right_arm.rotation_degrees = r_rot
	_fp_left_arm.position = l_pos
	_fp_left_arm.rotation_degrees = l_rot
	if is_instance_valid(_fp_swing_trail):
		_fp_swing_trail.visible = show_trail

func _update_fp_camera_transform() -> void:
	if cam_3d == null or not first_person_active:
		if _fp_viewmodel_root != null:
			_fp_viewmodel_root.visible = false
		return
	var dt: float = get_process_delta_time()
	if _fp_shake_timer > 0.0:
		_fp_shake_timer = maxf(0.0, _fp_shake_timer - dt)
		if _fp_shake_timer <= 0.0:
			_fp_shake_amp = 0.0
	_fp_camera_punch_pitch = move_toward(_fp_camera_punch_pitch, 0.0, dt * 0.32)
	_fp_camera_punch_roll = move_toward(_fp_camera_punch_roll, 0.0, dt * 0.36)

	var pl := get_tree().get_first_node_in_group("player") as Node2D if is_inside_tree() else null
	var pl_pos: Vector2 = pl.global_position if is_instance_valid(pl) else Vector2(465, 48)
	var eye_h: float = FP_EYE_HEIGHT_PX
	if FishingSpotScript.is_in_river_crossing(pl_pos, 3.0):
		eye_h += surface_elevation_offset_px(pl_pos)
	if is_instance_valid(pl):
		if pl.get("is_mounted") == true:
			eye_h += 6.0
		else:
			var m_ctrl = pl.get_node_or_null("PlayerMovementController")
			if m_ctrl != null and m_ctrl.get("is_stealthing") == true:
				eye_h -= 3.5
		if pl.has_method("get_jump_height"):
			eye_h += float(pl.call("get_jump_height"))
	if vm != null:
		var tav_eye_h: float = VillageTavern.elevation_height_for(pl_pos, int(vm.player_elevation_level))
		if tav_eye_h > 3.0:
			eye_h += (tav_eye_h - 2.95)
		if int(vm.player_elevation_level) == 1 and VillageTavern.RECT.grow(8.0).has_point(_AN_SITIOS.desmover(pl_pos)):
			eye_h = minf(eye_h, 54.5)
		elif vm.has_method("_is_pos_inside_any_building") and bool(vm.call("_is_pos_inside_any_building", pl_pos)):
			eye_h = minf(eye_h, 23.5)
	var eye_3d: Vector3 = to_3d(pl_pos, eye_h)
	if _fp_shake_timer > 0.0 and _fp_shake_amp > 0.0:
		eye_3d += Vector3(
			randf_range(-_fp_shake_amp, _fp_shake_amp),
			randf_range(-_fp_shake_amp, _fp_shake_amp),
			randf_range(-_fp_shake_amp, _fp_shake_amp)
		)
	var dir_2d: Vector2 = get_fp_forward_2d()
	var horiz_3d: Vector3 = Vector3(dir_2d.x, 0.0, dir_2d.y / maxf(0.1, _sin_p)).normalized()
	var eff_pitch: float = clampf(fp_pitch + _fp_camera_punch_pitch, -FP_MAX_PITCH, FP_MAX_PITCH)
	var look_dir_3d: Vector3 = (horiz_3d * cos(eff_pitch) + Vector3(0.0, sin(eff_pitch), 0.0)).normalized()
	cam_3d.projection = Camera3D.PROJECTION_PERSPECTIVE
	var ads_fov_blend: float = 0.0
	if is_instance_valid(pl):
		var c_ctrl_f = pl.get_node_or_null("PlayerCombatController")
		if c_ctrl_f != null and "aim_down_sights_blend" in c_ctrl_f:
			ads_fov_blend = clampf(float(c_ctrl_f.get("aim_down_sights_blend")), 0.0, 1.0)
	var fov_base: float = float(Ajustes.get_valor("campo_vision")) # Ajustes → Juego (70 por defecto)
	cam_3d.fov = lerpf(fov_base, fov_base * 0.786, ads_fov_blend)
	cam_3d.near = 0.03
	cam_3d.far = 250.0
	cam_3d.global_position = eye_3d
	if cam_3d.is_inside_tree():
		cam_3d.look_at(eye_3d + look_dir_3d * 10.0, Vector3.UP)
	else:
		cam_3d.transform = cam_3d.transform.looking_at(eye_3d + look_dir_3d * 10.0, Vector3.UP)
	if absf(_fp_camera_punch_roll) > 0.0005:
		cam_3d.rotate_object_local(Vector3.FORWARD, _fp_camera_punch_roll)
	_update_fp_viewmodel(dt, pl)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if Teclas.es(event, "primera_persona") and not _is_ui_blocking_fp(): # sin F6, que en el editor de Godot lanza la escena
			toggle_first_person()
			get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not first_person_active or _is_headless:
		return
	if _is_ui_blocking_fp():
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		rotate_first_person_view(mm.relative.x, mm.relative.y)

func _update_fp_hud() -> void:
	if fp_hud_layer == null:
		return
	if not first_person_active or not CharacterAvatar3DScript.use_3d_characters:
		fp_hud_layer.visible = false
		return
	var ui_blocked: bool = _is_ui_blocking_fp()
	fp_hud_layer.visible = not ui_blocked
	var dt: float = get_process_delta_time()
	if _fp_hurt_flash_timer > 0.0:
		_fp_hurt_flash_timer = maxf(0.0, _fp_hurt_flash_timer - dt)
	if _fp_hit_confirm_timer > 0.0:
		_fp_hit_confirm_timer = maxf(0.0, _fp_hit_confirm_timer - dt)
	if _fp_block_flash_timer > 0.0:
		_fp_block_flash_timer = maxf(0.0, _fp_block_flash_timer - dt)
	if is_instance_valid(_fp_damage_vignette):
		if _fp_hurt_flash_timer > 0.0:
			_fp_damage_vignette.visible = true
			_fp_damage_vignette.color = Color(0.82, 0.08, 0.06, clampf(_fp_hurt_flash_timer * 0.95, 0.0, 0.42))
		elif _fp_block_flash_timer > 0.0:
			_fp_damage_vignette.visible = true
			_fp_damage_vignette.color = Color(0.42, 0.78, 1.0, clampf(_fp_block_flash_timer * 0.90, 0.0, 0.26))
		else:
			_fp_damage_vignette.visible = false
	if is_instance_valid(_fp_hit_flash_rect):
		if _fp_hit_confirm_timer > 0.0:
			_fp_hit_flash_rect.visible = true
			_fp_hit_flash_rect.color = Color(1.0, 0.88, 0.36, clampf(_fp_hit_confirm_timer * 2.2, 0.0, 0.48))
		else:
			_fp_hit_flash_rect.visible = false
	if fp_interact_label != null:
		fp_interact_label.text = ""
		fp_interact_label.visible = false
	if fp_mode_badge != null:
		var pl_hud := get_tree().get_first_node_in_group("player") if is_inside_tree() else null
		var c_ctrl_hud = pl_hud.get_node_or_null("PlayerCombatController") if is_instance_valid(pl_hud) else null
		var eq_hud = pl_hud.get("equipped_weapon") if is_instance_valid(pl_hud) else null
		var eq_name_hud: String = str(eq_hud.name).to_lower() if (eq_hud != null and "name" in eq_hud) else ""
		if c_ctrl_hud != null and (eq_name_hud == "flintlock" or eq_name_hud == "rifle"):
			var is_rf_hud: bool = (eq_name_hud == "rifle")
			var rel_step_hud: int = int(c_ctrl_hud.get("reload_step"))
			var mag_hud: int = int(c_ctrl_hud.get("rifle_mag_loaded" if is_rf_hud else "pistol_mag_loaded"))
			var cap_hud: int = 5 if is_rf_hud else 6
			var ads_hud: bool = float(c_ctrl_hud.get("aim_down_sights_blend")) >= 0.5
			if rel_step_hud > 0:
				var step_txt: String = "Sacando cargador vacío" if rel_step_hud == 1 else ("Metiendo cargador nuevo" if rel_step_hud == 2 else "Montando el cerrojo")
				fp_mode_badge.text = "🔄 RECARGA MANUAL [Paso %d/3]: %s..." % [rel_step_hud, step_txt]
				fp_mode_badge.add_theme_color_override("font_color", Color(1.0, 0.88, 0.36, 0.96))
			else:
				var w_lbl: String = "🎯 Fusil del Paso" if is_rf_hud else "🔫 Pistola de Chispa"
				var aim_lbl: String = " [MIRA ALZADA]" if ads_hud else " [Clic der. apuntar | R recargar]"
				fp_mode_badge.text = "%s — Cargador: %d/%d%s" % [w_lbl, mag_hud, cap_hud, aim_lbl]
				fp_mode_badge.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 0.92))
			fp_mode_badge.visible = true
		else:
			fp_mode_badge.text = ""
			fp_mode_badge.visible = false
	return

func _process(delta: float) -> void:
	if _is_headless or vm == null:
		return

	var use_3d: bool = CharacterAvatar3DScript.use_3d_characters
	if not use_3d and first_person_active:
		set_first_person(false)
	if use_3d != _last_use_3d:
		_last_use_3d = use_3d
		_sync_2d_flat_visuals(use_3d)

	if is_instance_valid(stage_sprite):
		stage_sprite.visible = use_3d
	if not use_3d:
		return

	if first_person_active and not _is_ui_blocking_fp():
		var arrow_turn := Vector2(
			float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT)),
			float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))
		)
		if arrow_turn.length_squared() > 0.01:
			rotate_first_person_view(arrow_turn.x * 520.0 * delta, arrow_turn.y * 360.0 * delta)
		_sync_player_aim_from_fp()
	_update_fp_hud()

	if vm.buried_graves.size() != _last_buried_count:
		rebuild_graves_3d()

	var _pt: int = Time.get_ticks_usec() if perf_on else 0
	_sync_camera_with_2d()
	if perf_on: _pt = _perf_add("camera", _pt)
	_sync_dynamic_props_3d()
	if perf_on: _pt = _perf_add("dynamic_props", _pt)

	_nature_scan_accum += delta
	if _nature_scan_accum >= 4.0:
		_nature_scan_accum = 0.0
		_scan_nature_sources()
		_sync_2d_flat_visuals(use_3d)
	if perf_on: _pt = _perf_add("nature_scan_4s", _pt)
	_nature_accum += delta
	if _nature_accum >= 0.5:
		_nature_accum = 0.0
		_sync_nature_3d(true)
		if perf_on: _pt = _perf_add("nature_sync_05s", _pt)
		_sync_props_3d(true)
		if perf_on: _pt = _perf_add("props_sync_05s", _pt)

	_cutaway_accum += delta
	if _cutaway_accum >= 0.08:
		_cutaway_accum = 0.0
		_update_roof_cutaways_and_lighting()
	if perf_on: _perf_add("roofs_lighting_008s", _pt)

## B3 (medición): cronómetro por partes; solo lo enciende `tools/tests/perf_3d.gd`. No cambia el comportamiento.

func _sync_camera_with_2d() -> void:
	if cam_3d == null:
		return
	if detective_topdown_active:
		if is_instance_valid(_fp_viewmodel_root):
			_fp_viewmodel_root.visible = false
		cam_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam_3d.rotation_degrees = Vector3(-86.0, 0.0, 0.0)
		cam_3d.near = 0.1
		cam_3d.far = 250.0
		cam_3d.size = maxf(1.5, detective_topdown_size)
		var target_top_3d: Vector3 = to_3d(detective_topdown_pos, 0.0)
		var fwd_top: Vector3 = -cam_3d.global_transform.basis.z.normalized()
		cam_3d.global_position = target_top_3d - fwd_top * 65.0
		return
	if first_person_active:
		_update_fp_camera_transform()
	elif is_instance_valid(_fp_viewmodel_root):
		_fp_viewmodel_root.visible = false
	if stage_sprite == null:
		return
	var vp := get_viewport()
	if vp == null:
		return
	var cam2d := vp.get_camera_2d()
	var vp_rect := vp.get_visible_rect()
	var center_2d: Vector2 = cam2d.get_screen_center_position() if cam2d != null else Vector2(465, 48)
	var zoom_2d: Vector2 = cam2d.zoom if cam2d != null else Vector2(3.0, 3.0)

	if not first_person_active:
		if cam_3d.projection != Camera3D.PROJECTION_ORTHOGONAL or not is_equal_approx(cam_3d.rotation_degrees.x, -PITCH_DEG):
			cam_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
			cam_3d.rotation_degrees = Vector3(-PITCH_DEG, 0.0, 0.0)
			cam_3d.near = 0.1
			cam_3d.far = 250.0
		var world_vis_h: float = vp_rect.size.y / maxf(0.1, zoom_2d.y)
		cam_3d.size = maxf(1.0, world_vis_h * WORLD_SCALE)

		var target_3d: Vector3 = to_3d(center_2d, 0.0)
		var forward_vec: Vector3 = -cam_3d.global_transform.basis.z.normalized()
		cam_3d.global_position = target_3d - forward_vec * 65.0

	stage_sprite.global_position = center_2d
	stage_sprite.scale = Vector2(
		(vp_rect.size.x / maxf(0.1, zoom_2d.x)) / float(VIEWPORT_W),
		(vp_rect.size.y / maxf(0.1, zoom_2d.y)) / float(VIEWPORT_H)
	)


func _update_roof_cutaways_and_lighting() -> void:
	var pl := get_tree().get_first_node_in_group("player") as Node2D if is_inside_tree() else null
	var pl_pos: Vector2 = pl.global_position if is_instance_valid(pl) else Vector2.INF
	var mouse_pos: Vector2 = get_global_mouse_position() if is_inside_tree() else Vector2.INF
	var elev: int = vm.player_elevation_level if vm != null else 0

	for rec in _building_records_3d:
		var rect: Rect2 = rec["rect"]
		var b_root_node: Node3D = rec.get("root") as Node3D
		var roof_cap: Node3D = rec["roof_cap"]
		var loft_root: Node3D = rec["loft_root"]
		if str(rec.get("id", "")) == "building_tavern" and is_instance_valid(b_root_node):
			b_root_node.visible = (elev != -1)
		if not is_instance_valid(roof_cap):
			continue
		var r_near: Rect2 = rect.grow(38.0)
		var r_inside: Rect2 = rect.grow(8.0)
		# B7: En primera persona los tejados y muros altos NO se retiran al entrar: ves el techo encima y las paredes enteras.
		# D1/D3: En la vista cenital del detective, si el cadáver está dentro de un edificio, se retira su tejado.
		var open_roof: bool = r_near.has_point(detective_topdown_pos) if detective_topdown_active else (false if first_person_active else (r_near.has_point(pl_pos) or r_inside.has_point(mouse_pos)))
		roof_cap.visible = not open_roof
		if is_instance_valid(loft_root):
			var is_tav: bool = str(rec.get("id", "")) == "building_tavern"
			var on_tavern_stairs: bool = is_tav and VillageTavern.elevation_height_for(pl_pos, elev) > 6.0
			loft_root.visible = is_tav and (first_person_active or elev == 1 or on_tavern_stairs)

	# Casa mejorada del jugador: en primera persona conserva el tejado cerrado
	if is_instance_valid(_player_house_roof):
		_player_house_roof.visible = true if first_person_active else not (_player_house_rect.grow(38.0).has_point(pl_pos) or _player_house_rect.grow(8.0).has_point(mouse_pos))

	# Luz diurna/nocturna, cielo con nubes según la hora, niebla atmosférica y farolas eléctricas 3D
	var wc2 = get_node_or_null("/root/WorldClock") if is_inside_tree() else null
	var gm2 = get_node_or_null("/root/GameManager") if is_inside_tree() else null
	var hour: int = int(wc2.current_hour) if wc2 != null else 12
	var minute: int = int(wc2.current_minute) if wc2 != null and "current_minute" in wc2 else 0
	var hour_f: float = float(hour) + float(minute) / 60.0
	var weather_str: String = str(wc2.get_weather_name()).to_lower() if (wc2 != null and wc2.has_method("get_weather_name")) else (str(wc2.current_weather).to_lower() if wc2 != null and "current_weather" in wc2 else "clear")
	var weather_id: int = int(wc2.current_weather) if wc2 != null and "current_weather" in wc2 else 0
	var is_foggy_weather: bool = weather_id in [1, 2] or weather_str in ["fog", "rain", "storm", "lluvia", "niebla", "tormenta"]
	var is_night: bool = (hour >= 19 or hour < 6)
	var is_dusk: bool = (hour in [6, 7, 17, 18])
	var is_dawn_mist: bool = (hour_f >= 5.0 and hour_f <= 8.0)
	var grid_on: bool = gm2 != null and gm2.get_flag("electric_grid_active", false) == true and VillageCulture.is_lamps_powered(vm)
	var pl_indoors: bool = vm != null and is_finite(pl_pos.x) and vm.has_method("_is_pos_inside_any_building") and bool(vm._is_pos_inside_any_building(pl_pos))

	# Interpolación continua de colores del cielo, nubes, sol/luna y niebla según la hora del día y el clima (§3b.2: ambiente más oscuro, sucio y nublado)
	var zenith_col := Color(0.24, 0.34, 0.46)
	var horizon_col := Color(0.54, 0.59, 0.64)
	var sun_col := Color(0.94, 0.88, 0.74)
	var cloud_lit := Color(0.82, 0.80, 0.77)
	var cloud_shade := Color(0.40, 0.44, 0.50)
	var star_vis: float = 0.0
	var sun_ang: float = clampf((hour_f - 6.0) / 13.0, 0.0, 1.0) * PI
	var sun_dir := Vector3(-cos(sun_ang) * 0.78, maxf(0.16, sin(sun_ang) * 0.86), -0.46).normalized()
	if hour_f >= 5.5 and hour_f < 8.0: # Amanecer plomizo-ámbar
		var t_dawn: float = clampf((hour_f - 5.5) / 2.5, 0.0, 1.0)
		zenith_col = Color(0.05, 0.09, 0.18).lerp(Color(0.24, 0.34, 0.46), t_dawn)
		horizon_col = Color(0.68, 0.42, 0.30).lerp(Color(0.54, 0.59, 0.64), t_dawn)
		sun_col = Color(0.92, 0.60, 0.36).lerp(Color(0.94, 0.88, 0.74), t_dawn)
		cloud_lit = Color(0.84, 0.64, 0.50).lerp(Color(0.82, 0.80, 0.77), t_dawn)
		cloud_shade = Color(0.34, 0.28, 0.38).lerp(Color(0.40, 0.44, 0.50), t_dawn)
		star_vis = 1.0 - t_dawn
	elif hour_f >= 17.0 and hour_f < 19.8: # Atardecer ocre-pizarra
		var t_dusk: float = clampf((hour_f - 17.0) / 2.8, 0.0, 1.0)
		zenith_col = Color(0.22, 0.32, 0.44).lerp(Color(0.03, 0.05, 0.10), t_dusk)
		horizon_col = Color(0.72, 0.40, 0.24).lerp(Color(0.07, 0.09, 0.15), t_dusk)
		sun_col = Color(0.92, 0.54, 0.28).lerp(Color(0.52, 0.62, 0.80), t_dusk)
		cloud_lit = Color(0.84, 0.56, 0.38).lerp(Color(0.18, 0.22, 0.32), t_dusk)
		cloud_shade = Color(0.34, 0.22, 0.30).lerp(Color(0.06, 0.08, 0.14), t_dusk)
		star_vis = t_dusk * 0.70
	elif is_night: # Noche cerrada con nubes bajas oscuras
		zenith_col = Color(0.015, 0.024, 0.052)
		horizon_col = Color(0.042, 0.058, 0.10)
		sun_col = Color(0.52, 0.60, 0.78)
		cloud_lit = Color(0.14, 0.18, 0.26)
		cloud_shade = Color(0.04, 0.06, 0.10)
		sun_dir = Vector3(0.42, 0.68, -0.58).normalized()
		star_vis = 0.75

	var cloud_cov: float = 0.88 if is_foggy_weather else (0.72 if (is_dusk or is_dawn_mist) else 0.64)
	if is_foggy_weather:
		horizon_col = horizon_col.lerp(Color(0.48, 0.52, 0.55), 0.55)
		zenith_col = zenith_col.lerp(Color(0.38, 0.42, 0.46), 0.45)

	if _sky_mat != null:
		_sky_mat.set_shader_parameter("zenith_col", zenith_col)
		_sky_mat.set_shader_parameter("horizon_col", horizon_col)
		_sky_mat.set_shader_parameter("sun_dir", sun_dir)
		_sky_mat.set_shader_parameter("sun_col", sun_col)
		_sky_mat.set_shader_parameter("cloud_lit_col", cloud_lit)
		_sky_mat.set_shader_parameter("cloud_shade_col", cloud_shade)
		_sky_mat.set_shader_parameter("cloud_coverage", cloud_cov)
		_sky_mat.set_shader_parameter("star_visibility", star_vis)

	var pl_in_lib_secret: bool = first_person_active and is_finite(pl_pos.x) and Rect2(Vector2(932.0, -468.0), Vector2(44.0, 48.0)).has_point(pl_pos)
	if is_instance_valid(world_env) and world_env.environment != null:
		var env: Environment = world_env.environment
		if first_person_active:
			env.background_mode = Environment.BG_SKY if _sky_res != null else Environment.BG_COLOR
			env.background_color = horizon_col
			if pl_in_lib_secret:
				env.ambient_light_color = Color(0.10, 0.08, 0.06)
				env.ambient_light_energy = 0.03
			else:
				env.ambient_light_color = Color(0.22, 0.26, 0.38) if is_night else (Color(0.76, 0.64, 0.54) if is_dusk else Color(0.72, 0.74, 0.76))
				env.ambient_light_energy = 0.20 if is_night else (0.45 if is_dusk else 0.52)
			env.fog_enabled = not pl_indoors
			env.fog_light_color = Color(0.05, 0.07, 0.11) if is_night else horizon_col.lerp(Color(0.46, 0.48, 0.50), 0.35)
			env.fog_light_energy = 0.72 if not is_night else 0.26
			env.fog_sun_scatter = 0.18 if (is_dusk or is_dawn_mist) else 0.06
			env.fog_sky_affect = 0.62
			var base_fog: float = 0.022 if is_night else (0.0135 if (is_dusk or is_dawn_mist) else 0.0095)
			if is_foggy_weather:
				base_fog *= 2.1
			env.fog_density = base_fog
		else:
			env.background_mode = Environment.BG_CLEAR_COLOR
			env.ambient_light_color = Color(0.74, 0.76, 0.78)
			env.ambient_light_energy = 0.52
			env.fog_enabled = (is_foggy_weather or is_dawn_mist) and not pl_indoors
			env.fog_light_color = horizon_col
			env.fog_density = 0.0055 if is_foggy_weather else 0.0028

	if is_instance_valid(fp_lantern_light):
		if first_person_active:
			var carrying_lantern: bool = is_instance_valid(pl) and pl.get("is_carrying_lantern") == true
			fp_lantern_light.visible = carrying_lantern if pl_in_lib_secret else (is_night or is_dusk or carrying_lantern)
			fp_lantern_light.light_energy = 1.25 if carrying_lantern else (0.60 if is_night else 0.30)
			fp_lantern_light.omni_range = 5.6 if carrying_lantern else 3.4
		else:
			fp_lantern_light.visible = false

	if is_instance_valid(sun_light):
		var yaw_deg: float = lerpf(-115.0, -155.0, clampf((hour_f - 6.0) / 13.0, 0.0, 1.0))
		var pitch_deg: float = -38.0 - 18.0 * sin(sun_ang) if not is_night else -48.0
		sun_light.rotation_degrees = Vector3(pitch_deg, yaw_deg, 0.0)
		if pl_in_lib_secret:
			sun_light.light_energy = 0.015
			sun_light.light_color = Color(0.30, 0.25, 0.20)
		elif is_night:
			sun_light.light_energy = 0.22 # noches más oscuras para que destaquen los charcos de luz de farolas y focos
			sun_light.light_color = Color(0.46, 0.54, 0.76)
		elif is_dusk or is_dawn_mist:
			sun_light.light_energy = 0.74
			sun_light.light_color = sun_col
		else:
			sun_light.light_energy = 0.96
			sun_light.light_color = Color(0.94, 0.89, 0.79)

	# R1: la terraza de la casa de comidas enciende su guirnalda de bombillas al caer la tarde (17:00–2:00)
	var terrace_on: bool = hour >= 17 or hour < 2
	for rn in _restaurant_night_nodes:
		if is_instance_valid(rn):
			(rn as Node3D).visible = terrace_on

	# Con el circuito de farolas cortado (sabotaje), las calles y los focos quedan a oscuras también de noche.
	var lamps_lit: bool = VillageCulture.is_lamps_powered(vm) and (is_night or grid_on)
	for sl_node in _streetlight_nodes_3d:
		var bulb: MeshInstance3D = sl_node["bulb"]
		var lt: OmniLight3D = sl_node["light"]
		if is_instance_valid(bulb):
			bulb.visible = lamps_lit
			bulb.material_override = sl_node["mat_voltaic"] if grid_on else sl_node["mat_warm"]
		if is_instance_valid(lt):
			lt.visible = lamps_lit
			lt.light_color = Color(0.55, 0.96, 1.0) if grid_on else Color(1.0, 0.82, 0.42)
			lt.light_energy = 2.35 if grid_on else 1.75
	for fl_node in _floodlight_nodes_3d:
		var f_bulb: MeshInstance3D = fl_node.get("bulb")
		var f_spot: SpotLight3D = fl_node.get("spot")
		var f_pool: OmniLight3D = fl_node.get("pool")
		if is_instance_valid(f_bulb):
			f_bulb.visible = lamps_lit
			f_bulb.material_override = fl_node["mat_voltaic"] if grid_on else fl_node["mat_warm"]
		if is_instance_valid(f_spot):
			f_spot.visible = lamps_lit
			f_spot.light_color = Color(0.62, 0.96, 1.0) if grid_on else Color(1.0, 0.90, 0.62)
			f_spot.light_energy = 3.2 if grid_on else 2.6
		if is_instance_valid(f_pool):
			f_pool.visible = lamps_lit
			f_pool.light_color = Color(0.62, 0.96, 1.0) if grid_on else Color(1.0, 0.88, 0.56)
			f_pool.light_energy = 2.1 if grid_on else 1.65



# ==============================================================================
# CASO I (Claude Code, 2026-11-09): gabinete forzado de la mansión y hoja arrancada junto a la cama del familiar.
# Van en su propia raíz (hermana de los edificios) para que reconstruir los edificios no los borre.
# ==============================================================================
var _case1_props_root_3d: Node3D = null
var _case1_props_key: String = ""

func sync_case1_props_3d() -> void:
	if vm == null or not is_instance_valid(buildings_root_3d) or buildings_root_3d.get_parent() == null:
		return
	var C1 = load("res://scripts/systems/VillageCase1.gd")
	var cab: Vector2 = C1.cabinet_pos()
	var pp = C1.state(vm).get("page_pos", null)
	var page: Vector2 = Vector2(float(pp[0]), float(pp[1])) if pp is Array and (pp as Array).size() >= 2 else Vector2.INF
	var key: String = "%s|%s" % [str(cab), str(page)]
	if key == _case1_props_key and is_instance_valid(_case1_props_root_3d):
		return
	_case1_props_key = key
	if is_instance_valid(_case1_props_root_3d):
		_case1_props_root_3d.queue_free()
	_case1_props_root_3d = Node3D.new()
	_case1_props_root_3d.name = "Case1Props3D"
	buildings_root_3d.get_parent().add_child(_case1_props_root_3d)
	var m_walnut := _mat("case1_walnut", Color(0.30, 0.19, 0.11), 0.72, 0.05)
	var m_brass := _mat("case1_brass", Color(0.74, 0.58, 0.26), 0.35, 0.8)
	var m_velvet := _mat("case1_velvet", Color(0.36, 0.08, 0.10), 0.95, 0.0)
	var m_shaving := _mat("case1_shaving", Color(0.62, 0.46, 0.28), 0.9, 0.0)
	var m_paper := _mat("case1_old_paper", Color(0.88, 0.82, 0.66), 0.95, 0.0)
	var m_ink := _mat("case1_ink", Color(0.12, 0.10, 0.10), 0.9, 0.0)
	# Gabinete de nogal con la puerta entreabierta, la placa de la cerradura doblada y virutas en el suelo
	_add_box_2d(_case1_props_root_3d, cab, Vector2(16.0, 9.0), 2.0, 18.0, m_walnut)
	_add_box_2d(_case1_props_root_3d, cab + Vector2(0.0, 3.6), Vector2(13.0, 1.6), 11.0, 0.8, m_velvet) # estante de terciopelo
	var door := _add_box_2d(_case1_props_root_3d, cab + Vector2(5.0, 6.2), Vector2(7.6, 0.9), 3.0, 15.0, m_walnut, 28.0)
	door.name = "Case1CabinetDoor"
	_add_box_2d(_case1_props_root_3d, cab + Vector2(1.4, 5.4), Vector2(1.6, 0.6), 9.0, 2.6, m_brass, -18.0) # placa doblada
	for i in range(5):
		_add_box_2d(_case1_props_root_3d, cab + Vector2(-3.0 + i * 1.6, 8.0 + float(i % 2) * 1.2), Vector2(0.9, 0.5), 2.0, 0.25, m_shaving, float(i * 37))
	# Hoja arrancada sobre una mesita junto a la cama del familiar
	if page != Vector2.INF:
		_add_box_2d(_case1_props_root_3d, page, Vector2(6.0, 5.0), 2.0, 7.0, m_walnut)
		_add_box_2d(_case1_props_root_3d, page + Vector2(0.3, -0.2), Vector2(4.2, 3.0), 9.0, 0.2, m_paper, 12.0)
		for j in range(3):
			_add_box_2d(_case1_props_root_3d, page + Vector2(-0.4, -1.0 + j * 0.9), Vector2(2.6, 0.18), 9.2, 0.05, m_ink, 12.0)
	# Bandeja de informes de la comisaría: atril de madera con una bandeja y papeles en blanco
	var rp: Vector2 = C1.REPORT_POS
	_add_box_2d(_case1_props_root_3d, rp, Vector2(7.0, 5.0), 2.0, 9.0, m_walnut)
	_add_box_2d(_case1_props_root_3d, rp, Vector2(6.0, 4.2), 11.0, 0.8, m_brass)
	for j2 in range(3):
		_add_box_2d(_case1_props_root_3d, rp + Vector2(0.2 * j2, -0.1 * j2), Vector2(4.4, 3.2), 11.8 + 0.2 * j2, 0.15, m_paper, float(j2 * 6 - 4))


## Ajustes → Gráficos (2026-11-10): sombras del sol, nitidez de la imagen 3D y suavizado de bordes.
## Las sombras del sol son lo que más pesa (duplican el dibujo).
func _aplicar_ajustes_graficos() -> void:
	if is_instance_valid(sun_light):
		var q: int = int(Ajustes.get_valor("sombras"))
		sun_light.shadow_enabled = q > 0
		sun_light.directional_shadow_max_distance = 140.0 if q >= 2 else 70.0
		RenderingServer.directional_shadow_atlas_set_size(4096 if q >= 2 else 2048, true)
	if is_instance_valid(sub_viewport):
		sub_viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		sub_viewport.scaling_3d_scale = clampf(float(Ajustes.get_valor("nitidez")), 0.5, 1.0)
		var msaa: int = int(Ajustes.get_valor("suavizado"))
		sub_viewport.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][clampi(msaa, 0, 2)]
