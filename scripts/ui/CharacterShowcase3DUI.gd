extends Control

## Visor Interactivo de Maquetas 3D en Primer Plano (`[F8]`) — Fase 1 (Transición 3D)
## Permite inspeccionar de cerca todos los modelos 3D provisionales (jugador, oficios, armaduras,
## armas, herramientas, arcabuz con disparo/humo, prótesis mecánicas y animaciones) y alternar [F10] 3D/2D.

const CharacterRig3DScript = preload("res://scripts/visuals/CharacterRig3D.gd")
const CharacterAvatar3DScript = preload("res://scripts/visuals/CharacterAvatar3D.gd")

var panel_root: PanelContainer = null
var sub_viewport: SubViewport = null
var preview_rig: Node3D = null
var preview_cam: Camera3D = null
var status_lbl: Label = null

var _auto_rotate: bool = true
var _turntable_yaw: float = 0.35
var _cam_pitch: float = -18.0
var _cam_dist: float = 3.1
var _current_preset_idx: int = 0
var _current_anim_mode: String = "walk"
var _attack_demo_clock: float = 0.0
var _custom_cfg: Dictionary = {}

const ARCHETYPE_PRESETS: Array[Dictionary] = [
	{
		"title": "1. Forastero (Jugador)",
		"cfg": {
			"skin_color": Color(0.93, 0.76, 0.63),
			"hair_color": Color(0.22, 0.15, 0.10),
			"tunic_color": Color(0.22, 0.42, 0.64),
			"pants_color": Color(0.20, 0.22, 0.26),
			"is_female": false,
			"is_child": false,
			"has_beard": false,
			"has_apron": false,
			"has_skirt": false,
			"has_cape": true,
			"cape_color": Color(0.24, 0.42, 0.26),
			"headgear": "helm_t2",
			"chest_armor_tier": 2,
			"legs_armor_tier": 2,
			"boots_armor_tier": 2,
			"weapon": "sword",
			"weapon_tier": 2,
			"offhand": "lantern"
		}
	},
	{
		"title": "2. Herrero Maestro (Thoran)",
		"cfg": {
			"skin_color": Color(0.88, 0.70, 0.56),
			"hair_color": Color(0.24, 0.16, 0.10),
			"tunic_color": Color(0.28, 0.26, 0.28),
			"pants_color": Color(0.18, 0.17, 0.16),
			"is_female": false,
			"is_child": false,
			"has_beard": true,
			"has_apron": true,
			"apron_color": Color(0.42, 0.25, 0.13),
			"has_skirt": false,
			"has_cape": false,
			"headgear": "none",
			"chest_armor_tier": 0,
			"legs_armor_tier": 0,
			"boots_armor_tier": 1,
			"weapon": "hammer",
			"weapon_tier": 3,
			"offhand": "none"
		}
	},
	{
		"title": "3. Guardia / Comisario",
		"cfg": {
			"skin_color": Color(0.92, 0.75, 0.62),
			"hair_color": Color(0.32, 0.22, 0.14),
			"tunic_color": Color(0.22, 0.34, 0.56),
			"pants_color": Color(0.18, 0.22, 0.30),
			"is_female": false,
			"is_child": false,
			"has_beard": true,
			"has_apron": false,
			"has_skirt": false,
			"has_cape": true,
			"cape_color": Color(0.18, 0.24, 0.42),
			"headgear": "helm_t2",
			"chest_armor_tier": 2,
			"legs_armor_tier": 2,
			"boots_armor_tier": 2,
			"weapon": "guard_spear",
			"weapon_tier": 2,
			"offhand": "shield"
		}
	},
	{
		"title": "4. Señor Noble del Valle",
		"cfg": {
			"skin_color": Color(0.95, 0.80, 0.68),
			"hair_color": Color(0.68, 0.54, 0.26),
			"tunic_color": Color(0.68, 0.14, 0.20),
			"pants_color": Color(0.22, 0.18, 0.24),
			"is_female": false,
			"is_child": false,
			"has_beard": true,
			"has_apron": false,
			"has_skirt": false,
			"has_cape": true,
			"cape_color": Color(0.76, 0.14, 0.20),
			"headgear": "noble_crown",
			"chest_armor_tier": 0,
			"legs_armor_tier": 0,
			"boots_armor_tier": 1,
			"weapon": "sword",
			"weapon_tier": 3,
			"offhand": "none"
		}
	},
	{
		"title": "5. Tirador con Arcabuz",
		"cfg": {
			"skin_color": Color(0.90, 0.73, 0.59),
			"hair_color": Color(0.20, 0.14, 0.10),
			"tunic_color": Color(0.28, 0.38, 0.30),
			"pants_color": Color(0.22, 0.20, 0.18),
			"is_female": false,
			"is_child": false,
			"has_beard": false,
			"has_apron": false,
			"has_skirt": false,
			"has_cape": true,
			"cape_color": Color(0.26, 0.32, 0.22),
			"headgear": "sheriff_hat",
			"chest_armor_tier": 1,
			"legs_armor_tier": 1,
			"boots_armor_tier": 1,
			"weapon": "flintlock",
			"weapon_tier": 2,
			"offhand": "none"
		}
	},
	{
		"title": "6. Vecina con Prótesis Mecánica",
		"cfg": {
			"skin_color": Color(0.94, 0.78, 0.66),
			"hair_color": Color(0.52, 0.22, 0.14),
			"tunic_color": Color(0.26, 0.54, 0.38),
			"pants_color": Color(0.24, 0.22, 0.20),
			"is_female": true,
			"is_child": false,
			"has_beard": false,
			"has_apron": false,
			"has_skirt": true,
			"has_cape": false,
			"headgear": "straw_hat",
			"chest_armor_tier": 0,
			"legs_armor_tier": 0,
			"boots_armor_tier": 0,
			"left_arm_state": "prosthetic",
			"left_leg_state": "prosthetic",
			"weapon": "sickle",
			"weapon_tier": 2,
			"offhand": "none"
		}
	},
	{
		"title": "7. Sacerdote del Alba",
		"cfg": {
			"skin_color": Color(0.94, 0.79, 0.68),
			"hair_color": Color(0.78, 0.78, 0.82),
			"tunic_color": Color(0.92, 0.88, 0.76),
			"pants_color": Color(0.30, 0.28, 0.24),
			"is_female": false,
			"is_child": false,
			"has_beard": true,
			"has_apron": false,
			"has_skirt": true,
			"has_cape": false,
			"headgear": "priest_cap",
			"chest_armor_tier": 0,
			"legs_armor_tier": 0,
			"boots_armor_tier": 0,
			"weapon": "none",
			"weapon_tier": 1,
			"offhand": "book"
		}
	},
	{
		"title": "8. Niño / Escolar del Valle",
		"cfg": {
			"skin_color": Color(0.95, 0.80, 0.67),
			"hair_color": Color(0.42, 0.26, 0.14),
			"tunic_color": Color(0.36, 0.56, 0.74),
			"pants_color": Color(0.26, 0.24, 0.22),
			"is_female": false,
			"is_child": true,
			"has_beard": false,
			"has_apron": false,
			"has_skirt": false,
			"has_cape": false,
			"headgear": "none",
			"chest_armor_tier": 0,
			"legs_armor_tier": 0,
			"boots_armor_tier": 0,
			"weapon": "fishing_rod",
			"weapon_tier": 1,
			"offhand": "none"
		}
	}
]

func _ready() -> void:
	name = "CharacterShowcase3DUI"
	top_level = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event.keycode == KEY_F9 or event.keycode == KEY_F10) and event.shift_pressed:
			toggle_panel()
			get_viewport().set_input_as_handled()
		elif (event.keycode == KEY_F9 or event.keycode == KEY_F10) and not event.shift_pressed:
			var vm = get_tree().get_first_node_in_group("village_manager")
			var st3d = vm.get("world_stage_3d") if vm != null else null
			if st3d != null and st3d.get("first_person_active") == true:
				st3d.call("set_first_person", false)
			CharacterAvatar3DScript.use_3d_characters = not CharacterAvatar3DScript.use_3d_characters
			var p = get_tree().get_first_node_in_group("player")
			if p and p.has_method("show_hint"):
				var mode_txt := "Mundo, Edificios y Personajes 3D ACTIVADOS" if CharacterAvatar3DScript.use_3d_characters else "Mapa y Sprites 2D Clásicos ACTIVADOS"
				p.call("show_hint", "🎥 [F9] %s ([P]/[F6] 1.ª Persona · [Mayús+F9] Visor 3D)" % mode_txt)
			_update_status_text()
			get_viewport().set_input_as_handled()
		elif visible and event.keycode == KEY_ESCAPE:
			visible = false
			if sub_viewport:
				sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
			get_viewport().set_input_as_handled()

func toggle_panel() -> void:
	visible = not visible
	if sub_viewport:
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
	if visible:
		_apply_preset(_current_preset_idx)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08, 0.84)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel_root = PanelContainer.new()
	panel_root.custom_minimum_size = Vector2(920, 560)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.16, 0.98)
	sb.border_color = Color(0.82, 0.68, 0.34, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(14)
	panel_root.add_theme_stylebox_override("panel", sb)
	center.add_child(panel_root)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	panel_root.add_child(main_vbox)

	# Cabecera
	var header := HBoxContainer.new()
	main_vbox.add_child(header)
	var title_lbl := Label.new()
	title_lbl.text = "🧊 VISOR DE MAQUETAS 3D ARTICULADAS — FASE 1 (Personajes, Equipo, Armas y Prótesis)"
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)

	var toggle_live_btn := Button.new()
	toggle_live_btn.text = "🎥 Alternar 3D/2D en Partida [F10]"
	toggle_live_btn.pressed.connect(func():
		CharacterAvatar3DScript.use_3d_characters = not CharacterAvatar3DScript.use_3d_characters
		_update_status_text()
	)
	header.add_child(toggle_live_btn)

	var close_btn := Button.new()
	close_btn.text = "✖ Cerrar [F8 / Esc]"
	close_btn.pressed.connect(func(): toggle_panel())
	header.add_child(close_btn)

	# Cuerpo dividido: Izquierda (Visor 3D grande) | Derecha (Controles de Arquetipo, Equipo, Prótesis y Animación)
	var body_hbox := HBoxContainer.new()
	body_hbox.add_theme_constant_override("separation", 14)
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(body_hbox)

	var vp_frame := PanelContainer.new()
	vp_frame.custom_minimum_size = Vector2(420, 440)
	var vp_sb := StyleBoxFlat.new()
	vp_sb.bg_color = Color(0.14, 0.17, 0.23, 1.0)
	vp_sb.border_color = Color(0.35, 0.42, 0.54, 1.0)
	vp_sb.set_border_width_all(1)
	vp_sb.set_corner_radius_all(6)
	vp_frame.add_theme_stylebox_override("panel", vp_sb)
	body_hbox.add_child(vp_frame)

	if DisplayServer.get_name() != "headless":
		var vpc := SubViewportContainer.new()
		vpc.stretch = true
		vpc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vpc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vp_frame.add_child(vpc)

		sub_viewport = SubViewport.new()
		sub_viewport.size = Vector2i(420, 440)
		sub_viewport.own_world_3d = true
		sub_viewport.msaa_3d = Viewport.MSAA_4X
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		vpc.add_child(sub_viewport)

		var env_n := WorldEnvironment.new()
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.14, 0.17, 0.23)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.85, 0.88, 0.96)
		env.ambient_light_energy = 0.75
		env_n.environment = env
		sub_viewport.add_child(env_n)

		var key_light := DirectionalLight3D.new()
		key_light.rotation_degrees = Vector3(-42.0, 35.0, 0.0)
		key_light.light_energy = 1.25
		key_light.light_color = Color(1.0, 0.96, 0.88)
		sub_viewport.add_child(key_light)

		var rim_light := DirectionalLight3D.new()
		rim_light.rotation_degrees = Vector3(-25.0, -145.0, 0.0)
		rim_light.light_energy = 0.55
		rim_light.light_color = Color(0.55, 0.75, 1.0)
		sub_viewport.add_child(rim_light)

		# Pedestal circular debajo del muñeco
		var ped := MeshInstance3D.new()
		var ped_cyl := CylinderMesh.new()
		ped_cyl.top_radius = 0.72
		ped_cyl.bottom_radius = 0.82
		ped_cyl.height = 0.12
		ped.mesh = ped_cyl
		ped.position = Vector3(0.0, -0.06, 0.0)
		var ped_mat := StandardMaterial3D.new()
		ped_mat.albedo_color = Color(0.26, 0.28, 0.34)
		ped_mat.roughness = 0.65
		ped.material_override = ped_mat
		sub_viewport.add_child(ped)

		preview_cam = Camera3D.new()
		preview_cam.fov = 38.0
		sub_viewport.add_child(preview_cam)

		preview_rig = CharacterRig3DScript.new()
		sub_viewport.add_child(preview_rig)

	# Panel derecho de controles
	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_child(right_scroll)

	var ctrl_vbox := VBoxContainer.new()
	ctrl_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ctrl_vbox.add_theme_constant_override("separation", 8)
	right_scroll.add_child(ctrl_vbox)

	_add_section_header(ctrl_vbox, "👤 1. Arquetipos del Valle")
	var arch_grid := GridContainer.new()
	arch_grid.columns = 2
	arch_grid.add_theme_constant_override("h_separation", 6)
	arch_grid.add_theme_constant_override("v_separation", 6)
	ctrl_vbox.add_child(arch_grid)
	for i in range(ARCHETYPE_PRESETS.size()):
		var idx: int = i
		var b := Button.new()
		b.text = str(ARCHETYPE_PRESETS[i]["title"])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): _apply_preset(idx))
		arch_grid.add_child(b)

	_add_section_header(ctrl_vbox, "⚔️ 2. Armas, Herramientas y Arcabuz en Mano")
	var weap_grid := GridContainer.new()
	weap_grid.columns = 3
	weap_grid.add_theme_constant_override("h_separation", 6)
	weap_grid.add_theme_constant_override("v_separation", 6)
	ctrl_vbox.add_child(weap_grid)
	var weapons_list: Array = [
		["🗡️ Espada", "sword"],
		["🔨 Martillo", "hammer"],
		["🪓 Hacha", "axe"],
		["⛏️ Pico", "pickaxe"],
		["🏹 Arco", "bow"],
		["🌾 Hoz", "sickle"],
		["💧 Regadera", "watering_can"],
		["🎣 Caña", "fishing_rod"],
		["🔫 Arcabuz Chispa", "flintlock"],
		["🔱 Lanza Guardia", "guard_spear"],
		["✋ Mano vacía", "none"]
	]
	for w_pair in weapons_list:
		var wk: String = w_pair[1]
		var wb := Button.new()
		wb.text = w_pair[0]
		wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wb.pressed.connect(func():
			_custom_cfg["weapon"] = wk
			_refresh_custom_cfg()
			if wk == "flintlock":
				_current_anim_mode = "shoot_flintlock"
				_attack_demo_clock = 0.0
				if preview_rig and preview_rig.has_method("trigger_muzzle_flash"):
					preview_rig.call("trigger_muzzle_flash")
		)
		weap_grid.add_child(wb)

	_add_section_header(ctrl_vbox, "🛡️ 3. Nivel de Armadura, Mano Izquierda y Prótesis")
	var arm_grid := GridContainer.new()
	arm_grid.columns = 3
	arm_grid.add_theme_constant_override("h_separation", 6)
	arm_grid.add_theme_constant_override("v_separation", 6)
	ctrl_vbox.add_child(arm_grid)

	var armor_btns: Array = [
		["👕 Sin Armadura", 0, "none"],
		["🧥 Cuero (Nv.1)", 1, "helm_t1"],
		["⛓️ Hierro (Nv.2)", 2, "helm_t2"],
		["💎 Acero Maestro (Nv.3)", 3, "helm_t3"],
		["🛡️ Escudo Izq.", -1, "shield"],
		["🏮 Farol Nocturno", -1, "lantern"],
		["🦾 Prótesis Brazo", -2, "prost_arm"],
		["🦿 Prótesis Pierna", -2, "prost_leg"],
		["🩼 Amputado + Muleta", -2, "stump_leg"]
	]
	for ab in armor_btns:
		var mode_i: int = ab[1]
		var tag_s: String = ab[2]
		var btn_a := Button.new()
		btn_a.text = ab[0]
		btn_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_a.pressed.connect(func():
			if mode_i >= 0:
				_custom_cfg["chest_armor_tier"] = mode_i
				_custom_cfg["legs_armor_tier"] = mode_i
				_custom_cfg["boots_armor_tier"] = mode_i
				_custom_cfg["headgear"] = tag_s
			elif mode_i == -1:
				_custom_cfg["offhand"] = tag_s if str(_custom_cfg.get("offhand", "none")) != tag_s else "none"
			elif mode_i == -2:
				if tag_s == "prost_arm":
					_custom_cfg["left_arm_state"] = "prosthetic" if str(_custom_cfg.get("left_arm_state", "normal")) != "prosthetic" else "normal"
				elif tag_s == "prost_leg":
					_custom_cfg["left_leg_state"] = "prosthetic" if str(_custom_cfg.get("left_leg_state", "normal")) != "prosthetic" else "normal"
					if _custom_cfg["left_leg_state"] == "prosthetic" and str(_custom_cfg.get("offhand", "")) == "crutch":
						_custom_cfg["offhand"] = "none"
				elif tag_s == "stump_leg":
					_custom_cfg["left_leg_state"] = "amputated" if str(_custom_cfg.get("left_leg_state", "normal")) != "amputated" else "normal"
					_custom_cfg["offhand"] = "crutch" if _custom_cfg["left_leg_state"] == "amputated" else "none"
			_refresh_custom_cfg()
		)
		arm_grid.add_child(btn_a)

	_add_section_header(ctrl_vbox, "🎬 4. Probar Animaciones y Cámara")
	var anim_grid := GridContainer.new()
	anim_grid.columns = 3
	anim_grid.add_theme_constant_override("h_separation", 6)
	anim_grid.add_theme_constant_override("v_separation", 6)
	ctrl_vbox.add_child(anim_grid)

	var anim_list: Array = [
		["🧍 Reposo", "idle"],
		["🚶 Caminar", "walk"],
		["🏃 Correr", "sprint"],
		["🕵️ Sigilo", "stealth"],
		["⚔️ Atacar / Talar", "attack"],
		["🔫 Disparar Arcabuz", "shoot_flintlock"],
		["⚒️ Trabajar Taller", "work"],
		["🥊 Pelea Callejera", "fight"],
		["🛌 Dormir / Caído", "sleep"]
	]
	for an in anim_list:
		var a_key: String = an[1]
		var btn_an := Button.new()
		btn_an.text = an[0]
		btn_an.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_an.pressed.connect(func():
			_current_anim_mode = a_key
			_attack_demo_clock = 0.0
			if a_key == "shoot_flintlock":
				_custom_cfg["weapon"] = "flintlock"
				_refresh_custom_cfg()
				if preview_rig and preview_rig.has_method("trigger_muzzle_flash"):
					preview_rig.call("trigger_muzzle_flash")
			_update_status_text()
		)
		anim_grid.add_child(btn_an)

	var cam_hbox := HBoxContainer.new()
	ctrl_vbox.add_child(cam_hbox)
	var rot_left_btn := Button.new()
	rot_left_btn.text = "⟲ Girar Izq."
	rot_left_btn.pressed.connect(func():
		_auto_rotate = false
		_turntable_yaw -= 0.45
	)
	cam_hbox.add_child(rot_left_btn)

	var auto_rot_btn := Button.new()
	auto_rot_btn.text = "🔄 Giro Automático"
	auto_rot_btn.pressed.connect(func(): _auto_rotate = not _auto_rotate)
	cam_hbox.add_child(auto_rot_btn)

	var rot_right_btn := Button.new()
	rot_right_btn.text = "⟳ Girar Der."
	rot_right_btn.pressed.connect(func():
		_auto_rotate = false
		_turntable_yaw += 0.45
	)
	cam_hbox.add_child(rot_right_btn)

	var view_top_btn := Button.new()
	view_top_btn.text = "📐 Vista Cenital / Frontal"
	view_top_btn.pressed.connect(func():
		_cam_pitch = -38.0 if _cam_pitch > -28.0 else -16.0
	)
	cam_hbox.add_child(view_top_btn)

	status_lbl = Label.new()
	status_lbl.add_theme_font_size_override("font_size", 12)
	status_lbl.add_theme_color_override("font_color", Color(0.80, 0.88, 0.98))
	main_vbox.add_child(status_lbl)

	_apply_preset(0)

func _add_section_header(parent: VBoxContainer, txt: String) -> void:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
	parent.add_child(lbl)

func _apply_preset(idx: int) -> void:
	_current_preset_idx = clampi(idx, 0, ARCHETYPE_PRESETS.size() - 1)
	_custom_cfg = (ARCHETYPE_PRESETS[_current_preset_idx]["cfg"] as Dictionary).duplicate(true)
	_refresh_custom_cfg()

func _refresh_custom_cfg() -> void:
	if preview_rig and preview_rig.has_method("apply_character_appearance"):
		preview_rig.call("apply_character_appearance", _custom_cfg)
	_update_status_text()

func _update_status_text() -> void:
	if not status_lbl:
		return
	var preset_title: String = str(ARCHETYPE_PRESETS[_current_preset_idx]["title"])
	var mode_str: String = "ACTIVO en el mapa (pulsa [F10] para volver a Sprites 2D)" if CharacterAvatar3DScript.use_3d_characters else "PAUSADO en el mapa (mostrando Sprites 2D originales; pulsa [F10] para activar 3D)"
	status_lbl.text = "Arquetipo: %s | Arma: %s | Animación: %s | Estado en partida: %s" % [
		preset_title,
		str(_custom_cfg.get("weapon", "none")),
		_current_anim_mode,
		mode_str
	]

func _process(delta: float) -> void:
	if not visible or preview_rig == null:
		return
	if _auto_rotate:
		_turntable_yaw += delta * 0.75
	_attack_demo_clock += delta

	if preview_cam:
		var pitch_rad := deg_to_rad(_cam_pitch)
		var horiz := cos(-pitch_rad) * _cam_dist
		var vert := sin(-pitch_rad) * _cam_dist
		preview_cam.position = Vector3(0.0, 0.90 + vert, horiz)
		preview_cam.look_at(Vector3(0.0, 0.88, 0.0), Vector3.UP)

	var facing_vec := Vector2(sin(_turntable_yaw), cos(_turntable_yaw))
	var state := {
		"facing": facing_vec,
		"speed_ratio": 0.0,
		"is_stealth": false,
		"is_sprinting": false,
		"is_working": false,
		"is_fighting": false,
		"is_hostile": false,
		"is_sleeping": false,
		"is_downed": false,
		"is_dead": false,
		"bow_draw": 0.0,
		"attack_progress": 0.0
	}
	match _current_anim_mode:
		"walk":
			state["speed_ratio"] = 0.85
		"sprint":
			state["speed_ratio"] = 1.45
			state["is_sprinting"] = true
		"stealth":
			state["speed_ratio"] = 0.55
			state["is_stealth"] = true
		"attack":
			state["attack_progress"] = fmod(_attack_demo_clock * 1.4, 1.0)
		"shoot_flintlock":
			var cyc := fmod(_attack_demo_clock, 1.4)
			if cyc < 0.35:
				state["attack_progress"] = cyc / 0.35
			if absf(cyc - 0.04) < delta * 1.5 and preview_rig.has_method("trigger_muzzle_flash"):
				preview_rig.call("trigger_muzzle_flash")
		"work":
			state["is_working"] = true
		"fight":
			state["is_fighting"] = true
		"sleep":
			state["is_sleeping"] = true

	if str(_custom_cfg.get("weapon", "")) == "bow" and _current_anim_mode == "attack":
		state["bow_draw"] = 0.85
		state["attack_progress"] = 0.0

	preview_rig.call("update_pose", delta, state)
