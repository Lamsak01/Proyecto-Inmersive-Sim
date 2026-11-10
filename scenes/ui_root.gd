extends Control

@export var player: CharacterBody2D
@export var health_bar: ProgressBar
@export var stamina_bar: ProgressBar
@export var blood_bar: ProgressBar
@export var stun_bar: ProgressBar
var hunger_bar: ProgressBar = null
var hygiene_bar: ProgressBar = null
var sleep_bar: ProgressBar = null

var clock_panel: PanelContainer = null
var clock_label: Label = null
var clock_weather_label: Label = null
var clock_speed_badge: PanelContainer = null
var clock_speed_label: Label = null
var clock_sub_label: Label = null
var test_mode_badge: PanelContainer = null
var test_mode_label: Label = null

var toast_box: VBoxContainer = null
var _last_hint_text: String = ""
var prompt_card: PanelContainer = null
var prompt_target_label: Label = null
var prompt_state_label: Label = null
var prompt_cycle_label: Label = null
var prompt_actions_box: VBoxContainer = null
var prompt_footer_label: Label = null
var hands_box: HBoxContainer = null
var _hand_slot_panels: Array[PanelContainer] = []
var _hand_slot_key_labels: Array[Label] = []
var _hand_slot_icon_labels: Array[Label] = []
var _hand_slot_icon_rects: Array[TextureRect] = []
var corner_right_box: HBoxContainer = null
var hud_gold_label: Label = null

var inv_panel: PanelContainer = null
var controls_panel: PanelContainer = null
var hiring_letter_panel: Control = null
var inv_gold_label: Label = null
var inv_armor_stats_label: Label = null
var inv_armor_slots_box: HBoxContainer = null
var inv_items_box: VBoxContainer = null
var inv_recipes_box: VBoxContainer = null
const ValleyMapUIScript = preload("res://scripts/ui/ValleyMapUI.gd")
const MedicalPanelUIScript = preload("res://scripts/ui/MedicalPanelUI.gd")
const SocialGlossaryUIScript = preload("res://scripts/ui/SocialGlossaryUI.gd")
const SkillsPanelUIScript = preload("res://scripts/ui/SkillsPanelUI.gd")
const QuestLogUIScript = preload("res://scripts/ui/QuestLogUI.gd")
const ChronicleUIScript = preload("res://scripts/ui/ChronicleUI.gd")
const CharacterShowcase3DUIScript = preload("res://scripts/ui/CharacterShowcase3DUI.gd")
const DetectiveUIScript = preload("res://scripts/ui/DetectiveUI.gd")

var tool_wheel: ToolWheelUI = null
var tavern_games: TavernGamesUI = null
var valley_map: Control = null
var medical_panel: Control = null
var social_glossary: Control = null
var skills_panel: Control = null
var quest_log: Control = null
var chronicle_panel: Control = null
var showcase_3d_panel: Control = null
var detective_ui: Control = null

func _ready() -> void:
	add_to_group("game_ui")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 1. Find Player if not assigned
	if not player:
		player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_node_or_null("/root/World/Player")
	
	if not player:
		print("UI: Player not found!")
		return

	# 2. Setup Bars if not assigned (papel y tinta, arriba a la izquierda)
	var stats_box: VBoxContainer = _create_stats_box()
	if not health_bar:
		health_bar = _create_paper_bar_row(stats_box, "❤", Color(0.710, 0.278, 0.247, 1.0), true)

	if not stamina_bar:
		stamina_bar = _create_paper_bar_row(stats_box, "⚡", Color(0.435, 0.604, 0.353, 1.0), true)

	if not blood_bar:
		blood_bar = _create_paper_bar_row(stats_box, "🩸", Color(0.70, 0.10, 0.16, 1.0), false)
		blood_bar.value = 0.0
		blood_bar.visible = false

	if not stun_bar:
		stun_bar = _create_paper_bar_row(stats_box, "💫", Color(0.95, 0.80, 0.25, 1.0), false)
		stun_bar.value = 0.0
		stun_bar.visible = false

	if not hunger_bar:
		hunger_bar = _create_paper_bar_row(stats_box, "🍞", Color(0.788, 0.541, 0.235, 1.0), false)
		hunger_bar.value = 100.0
		hunger_bar.visible = false

	if not sleep_bar:
		sleep_bar = _create_paper_bar_row(stats_box, "☾", Color(0.373, 0.498, 0.651, 1.0), false)
		sleep_bar.value = 100.0
		sleep_bar.visible = false

	if not hygiene_bar:
		hygiene_bar = _create_paper_bar_row(stats_box, "🧼", Color(0.373, 0.561, 0.651, 1.0), false)
		hygiene_bar.value = 100.0
		hygiene_bar.visible = false

	# 3. Connect Signals
	if player.has_node("HealthComponent"):
		var health: HealthComponent = player.get_node("HealthComponent")
		health.health_changed.connect(_on_health_changed)
		health.blood_changed.connect(_on_blood_changed)
		health_bar.max_value = health.max_health
		health_bar.value = health.current_health
		blood_bar.max_value = health.max_blood
		blood_bar.value = health.current_blood
	
	if player.has_node("StaminaComponent"):
		var stamina: StaminaComponent = player.get_node("StaminaComponent")
		stamina.stamina_changed.connect(_on_stamina_changed)
		stamina.exhausted.connect(_on_exhausted)
		stamina_bar.max_value = stamina.max_stamina
		stamina_bar.value = stamina.current_stamina

	if player.has_node("StunComponent"):
		var stun: StunComponent = player.get_node("StunComponent")
		stun.stun_changed.connect(_on_stun_changed)
		stun_bar.max_value = stun.max_stun
		stun_bar.value = stun.current_stun

	call_deferred("_bind_survival_component")
	
	setup_hint_label()
	_setup_clock_ui()
	_setup_toast_ui()
	_setup_bottom_hud_ui()
	_setup_inventory_ui()
	_setup_tool_wheel_ui()
	_setup_tavern_games_ui()
	_setup_valley_map_ui()
	_setup_medical_panel_ui()
	_setup_social_glossary_ui()
	_setup_skills_panel_ui()
	_setup_quest_log_ui()
	chronicle_panel = ChronicleUIScript.new()
	add_child(chronicle_panel)
	showcase_3d_panel = CharacterShowcase3DUIScript.new()
	add_child(showcase_3d_panel)
	detective_ui = DetectiveUIScript.new()
	detective_ui.set("player", player)
	add_child(detective_ui)
	_setup_controls_panel_ui()
	_setup_hiring_letter_panel_ui()
	if GameManager and not GameManager.game_loaded.is_connected(_on_game_loaded):
		GameManager.game_loaded.connect(_on_game_loaded)
	_init_default_objectives()
	if "inventory" in player and player.inventory:
		_bind_player_inventory()
	else:
		call_deferred("_bind_player_inventory")
	if player and player.has_signal("test_mode_changed") and not player.is_connected("test_mode_changed", _on_player_test_mode_changed):
		player.connect("test_mode_changed", _on_player_test_mode_changed)
	_on_player_test_mode_changed(player.get("test_mode_active") == true if player else false)

func _bind_player_inventory() -> void:
	if player and "inventory" in player and player.inventory:
		if not player.inventory.inventory_changed.is_connected(_on_inventory_changed):
			player.inventory.inventory_changed.connect(_on_inventory_changed)
		if not player.inventory.armor_changed.is_connected(_on_inventory_changed):
			player.inventory.armor_changed.connect(_on_inventory_changed)
		if not player.inventory.gold_changed.is_connected(_on_gold_changed):
			player.inventory.gold_changed.connect(_on_gold_changed)
		_on_inventory_changed()

func _on_gold_changed(_new_gold: int) -> void:
	_on_inventory_changed()

func _bind_survival_component() -> void:
	if player and player.has_node("SurvivalComponent"):
		var surv: SurvivalComponent = player.get_node("SurvivalComponent")
		if not surv.hunger_changed.is_connected(_on_hunger_changed):
			surv.hunger_changed.connect(_on_hunger_changed)
		if not surv.sleep_changed.is_connected(_on_sleep_changed):
			surv.sleep_changed.connect(_on_sleep_changed)
		if not surv.hygiene_changed.is_connected(_on_hygiene_changed):
			surv.hygiene_changed.connect(_on_hygiene_changed)
		surv._emit_all()

func _is_external_world_modal_open() -> bool:
	if WorldClock and bool(WorldClock.get("is_fast_forwarding")):
		return true
	if player and player.has_method("is_stunned") and bool(player.call("is_stunned")):
		return true
	var vm = get_tree().get_first_node_in_group("village_manager")
	if vm:
		if bool(vm.get("player_being_escorted_to_jail")):
			return true
		for p_name in ["business_panel", "morgue_panel", "jail_panel", "board_panel", "police_panel", "pantry_panel", "church_panel"]:
			var p_ctrl = vm.get(p_name)
			if p_ctrl is Control and p_ctrl.visible:
				return true
	var camp = get_tree().current_scene.find_child("PlayerCampSite", true, false) if get_tree().current_scene else null
	if camp:
		for c_panel in ["sleep_confirm_panel", "upgrade_panel", "chest_panel"]:
			var cp = camp.get(c_panel)
			if cp is Control and cp.visible:
				return true
	var coop = get_tree().get_first_node_in_group("chicken_coop")
	if coop:
		var coop_p = coop.get("chicken_action_panel")
		if coop_p is Control and coop_p.visible:
			return true
	return false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed and event.physical_keycode == KEY_QUOTELEFT: # modo pruebas: Ctrl+º
		if player and player.has_method("toggle_test_mode"):
			player.call("toggle_test_mode")
			get_viewport().set_input_as_handled()
			return
	if hiring_letter_panel and hiring_letter_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E] or event.physical_keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
				close_hiring_letter_panel()
				get_viewport().set_input_as_handled()
				return
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close_hiring_letter_panel()
			get_viewport().set_input_as_handled()
			return
	if controls_panel and controls_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER] or event.physical_keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER] or Teclas.es(event, "ayuda"):
				close_controls_panel()
				get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close_controls_panel()
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if (hiring_letter_panel and hiring_letter_panel.visible) or (controls_panel and controls_panel.visible):
		return
	var dm = player.get("dialogue_manager") if player else null
	if (dm and dm.has_method("is_active") and bool(dm.call("is_active"))) or (tavern_games and tavern_games.visible) or _is_external_world_modal_open():
		return
	if event is InputEventKey and not event.echo:
		if Teclas.es(event, "rueda"):
			if event.pressed:
				if tool_wheel and tool_wheel.visible:
					tool_wheel.close_wheel(true)
				elif tool_wheel:
					if inv_panel and inv_panel.visible:
						inv_panel.visible = false
					if medical_panel and medical_panel.visible:
						medical_panel.call("close_panel")
					if social_glossary and social_glossary.visible:
						social_glossary.call("close_panel")
					_close_skills_panel()
					if valley_map and bool(valley_map.get("is_full_map_open")):
						valley_map.call("close_full_map")
					tool_wheel.open_wheel()
			else:
				if tool_wheel and tool_wheel.visible:
					tool_wheel.handle_tab_release()
			get_viewport().set_input_as_handled()
			return

		if event.pressed:
			if Teclas.es(event, "mochila"):
				_close_skills_panel()
				if tool_wheel and tool_wheel.visible:
					tool_wheel.close_wheel(false)
				if medical_panel and medical_panel.visible:
					medical_panel.call("close_panel")
				if social_glossary and social_glossary.visible:
					social_glossary.call("close_panel")
				if valley_map and bool(valley_map.get("is_full_map_open")):
					valley_map.call("close_full_map")
				_toggle_inventory()
				get_viewport().set_input_as_handled()
			elif Teclas.es(event, "ayuda"):
				_close_skills_panel()
				if tool_wheel and tool_wheel.visible:
					tool_wheel.close_wheel(false)
				if inv_panel and inv_panel.visible:
					inv_panel.visible = false
				if social_glossary and social_glossary.visible:
					social_glossary.call("close_panel")
				if medical_panel and medical_panel.visible:
					medical_panel.call("close_panel")
				if valley_map and bool(valley_map.get("is_full_map_open")):
					valley_map.call("close_full_map")
				if controls_panel and controls_panel.visible:
					close_controls_panel()
				else:
					open_controls_panel()
				get_viewport().set_input_as_handled()
			elif Teclas.es(event, "salud"):
				_close_skills_panel()
				if tool_wheel and tool_wheel.visible:
					tool_wheel.close_wheel(false)
				if inv_panel and inv_panel.visible:
					inv_panel.visible = false
				if social_glossary and social_glossary.visible:
					social_glossary.call("close_panel")
				if valley_map and bool(valley_map.get("is_full_map_open")):
					valley_map.call("close_full_map")
				if medical_panel and medical_panel.has_method("toggle_panel"):
					medical_panel.call("toggle_panel")
				get_viewport().set_input_as_handled()
			elif Teclas.es(event, "mapa"):
				_close_skills_panel()
				if tool_wheel and tool_wheel.visible:
					tool_wheel.close_wheel(false)
				if inv_panel and inv_panel.visible:
					inv_panel.visible = false
				if medical_panel and medical_panel.visible:
					medical_panel.call("close_panel")
				if social_glossary and social_glossary.visible:
					social_glossary.call("close_panel")
				if valley_map and valley_map.has_method("toggle_full_map"):
					valley_map.call("toggle_full_map")
				get_viewport().set_input_as_handled()
			elif Teclas.es(event, "vecinos"):
				_close_skills_panel()
				if tool_wheel and tool_wheel.visible:
					tool_wheel.close_wheel(false)
				if inv_panel and inv_panel.visible:
					inv_panel.visible = false
				if medical_panel and medical_panel.visible:
					medical_panel.call("close_panel")
				if valley_map and bool(valley_map.get("is_full_map_open")):
					valley_map.call("close_full_map")
				if social_glossary and social_glossary.has_method("toggle_panel"):
					social_glossary.call("toggle_panel")
				get_viewport().set_input_as_handled()
			elif Teclas.es(event, "habilidades"):
				_close_quest_log()
				if tool_wheel and tool_wheel.visible:
					tool_wheel.close_wheel(false)
				if inv_panel and inv_panel.visible:
					inv_panel.visible = false
				if medical_panel and medical_panel.visible:
					medical_panel.call("close_panel")
				if social_glossary and social_glossary.visible:
					social_glossary.call("close_panel")
				if valley_map and bool(valley_map.get("is_full_map_open")):
					valley_map.call("close_full_map")
				if skills_panel and skills_panel.has_method("toggle_panel"):
					skills_panel.call("toggle_panel")
				get_viewport().set_input_as_handled()
			elif Teclas.es(event, "encargos"):
				var was_open: bool = quest_log != null and quest_log.visible
				_close_skills_panel()
				if tool_wheel and tool_wheel.visible:
					tool_wheel.close_wheel(false)
				if inv_panel and inv_panel.visible:
					inv_panel.visible = false
				if medical_panel and medical_panel.visible:
					medical_panel.call("close_panel")
				if social_glossary and social_glossary.visible:
					social_glossary.call("close_panel")
				if valley_map and bool(valley_map.get("is_full_map_open")):
					valley_map.call("close_full_map")
				if quest_log and not was_open:
					quest_log.call("open_panel")
				get_viewport().set_input_as_handled()
			elif Teclas.es(event, "cronica"):
				var chron_open: bool = chronicle_panel != null and chronicle_panel.visible
				_close_skills_panel()
				if tool_wheel and tool_wheel.visible:
					tool_wheel.close_wheel(false)
				if inv_panel and inv_panel.visible:
					inv_panel.visible = false
				if medical_panel and medical_panel.visible:
					medical_panel.call("close_panel")
				if social_glossary and social_glossary.visible:
					social_glossary.call("close_panel")
				if valley_map and bool(valley_map.get("is_full_map_open")):
					valley_map.call("close_full_map")
				if chronicle_panel and not chron_open:
					chronicle_panel.call("open_panel")
				get_viewport().set_input_as_handled()
			elif Teclas.es(event, "caso"):
				if detective_ui and detective_ui.visible:
					if str(detective_ui.get("current_mode")) == "board":
						detective_ui.call("close_panel")
					else:
						detective_ui.call("switch_mode", "board")
				else:
					var active_c: Node2D = detective_ui.get("current_corpse") if detective_ui else null
					open_detective_ui(active_c, "board")
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_ESCAPE:
				if detective_ui and detective_ui.visible:
					detective_ui.call("close_panel")
					get_viewport().set_input_as_handled()
					return
				if chronicle_panel and chronicle_panel.visible:
					chronicle_panel.call("close_panel")
					get_viewport().set_input_as_handled()
					return
				if quest_log and quest_log.visible:
					quest_log.call("close_panel")
					get_viewport().set_input_as_handled()
					return
				if skills_panel and skills_panel.visible:
					skills_panel.call("close_panel")
					get_viewport().set_input_as_handled()
					return
				if tool_wheel and tool_wheel.visible:
					tool_wheel.close_wheel(false)
					get_viewport().set_input_as_handled()
				elif social_glossary and social_glossary.visible:
					social_glossary.call("close_panel")
					get_viewport().set_input_as_handled()
				elif medical_panel and medical_panel.visible:
					medical_panel.call("close_panel")
					get_viewport().set_input_as_handled()
				elif valley_map and bool(valley_map.get("is_full_map_open")):
					valley_map.call("close_full_map")
					get_viewport().set_input_as_handled()
				elif inv_panel and inv_panel.visible:
					inv_panel.visible = false
					get_viewport().set_input_as_handled()
				elif event.pressed and not WorldClock.is_fast_forwarding:
					# Nada abierto: menú de pausa (menú principal, 2026-11-10).
					abrir_menu_pausa()
					get_viewport().set_input_as_handled()

func abrir_menu_pausa() -> void:
	if get_tree().root.get_node_or_null("MenuPausa") != null:
		return
	var m: CanvasLayer = load("res://scripts/ui/menu/MenuPausa.gd").new()
	m.name = "MenuPausa"
	get_tree().root.add_child(m)

func _setup_skills_panel_ui() -> void:
	skills_panel = SkillsPanelUIScript.new()
	skills_panel.name = "SkillsPanelUI"
	skills_panel.set("player", player)
	add_child(skills_panel)

func _close_quest_log() -> void:
	if quest_log and quest_log.visible:
		quest_log.call("close_panel")
	if chronicle_panel and chronicle_panel.visible:
		chronicle_panel.call("close_panel")
	if detective_ui and detective_ui.visible:
		detective_ui.call("close_panel")

func open_detective_ui(corpse_node: Node2D = null, initial_mode: String = "body") -> void:
	_close_skills_panel()
	if tool_wheel and tool_wheel.visible:
		tool_wheel.close_wheel(false)
	if inv_panel and inv_panel.visible:
		inv_panel.visible = false
	if medical_panel and medical_panel.visible:
		medical_panel.call("close_panel")
	if social_glossary and social_glossary.visible:
		social_glossary.call("close_panel")
	if valley_map and bool(valley_map.get("is_full_map_open")):
		valley_map.call("close_full_map")
	if detective_ui and detective_ui.has_method("open_for_corpse"):
		detective_ui.call("open_for_corpse", corpse_node, initial_mode)

func _setup_quest_log_ui() -> void:
	quest_log = QuestLogUIScript.new()
	add_child(quest_log)

func _close_skills_panel() -> void:
	_close_quest_log()
	if skills_panel and skills_panel.visible:
		skills_panel.call("close_panel")

func _setup_social_glossary_ui() -> void:
	social_glossary = SocialGlossaryUIScript.new()
	social_glossary.name = "SocialGlossaryUI"
	add_child(social_glossary)

func _setup_medical_panel_ui() -> void:
	medical_panel = MedicalPanelUIScript.new()
	medical_panel.name = "MedicalPanelUI"
	medical_panel.set("player", player)
	add_child(medical_panel)
	if player and player.has_node("HealthComponent"):
		var hc: HealthComponent = player.get_node("HealthComponent")
		if not hc.anatomy_changed.is_connected(Callable(medical_panel, "refresh_ui")):
			hc.anatomy_changed.connect(Callable(medical_panel, "refresh_ui"))

func _setup_tool_wheel_ui() -> void:
	tool_wheel = ToolWheelUI.new()
	tool_wheel.name = "ToolWheelUI"
	tool_wheel.player = player
	add_child(tool_wheel)

func _setup_tavern_games_ui() -> void:
	tavern_games = TavernGamesUI.new()
	tavern_games.name = "TavernGamesUI"
	tavern_games.player = player
	add_child(tavern_games)

func _setup_valley_map_ui() -> void:
	valley_map = ValleyMapUIScript.new()
	valley_map.name = "ValleyMapUI"
	valley_map.set("player", player)
	add_child(valley_map)

func open_tavern_games() -> void:
	if inv_panel and inv_panel.visible:
		inv_panel.visible = false
	if tool_wheel and tool_wheel.visible:
		tool_wheel.close_wheel(false)
	if valley_map and bool(valley_map.get("is_full_map_open")):
		valley_map.call("close_full_map")
	if tavern_games:
		tavern_games.open_games()

func _toggle_inventory() -> void:
	if not inv_panel:
		return
	inv_panel.visible = not inv_panel.visible
	if inv_panel.visible:
		_refresh_inventory_list()

func _on_inventory_changed() -> void:
	if WorldClock:
		_on_clock_time_updated(WorldClock.current_day, WorldClock.current_hour, WorldClock.current_minute)
	if inv_panel and inv_panel.visible:
		_refresh_inventory_list()

func _make_style(bg: Color, border: Color, bw: int, cr: int, mx: int, my: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(cr)
	s.content_margin_left = mx
	s.content_margin_right = mx
	s.content_margin_top = my
	s.content_margin_bottom = my
	return s

func _make_lbl(parent: Node, txt: String, f_sz: int, col: Color, expand_h: bool = false, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = txt
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = align as HorizontalAlignment
	if expand_h:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", f_sz)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l

func _make_btn(parent: Node, txt: String, cb: Callable, dis: bool = false) -> Button:
	var b := Button.new()
	b.text = txt
	b.disabled = dis
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _add_item_icon(parent: Node, tex: Texture2D, sz: float) -> void:
	if not tex:
		return
	var r := TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = Vector2(sz, sz)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(r)

func _setup_inventory_ui() -> void:
	inv_panel = PanelContainer.new()
	inv_panel.name = "InventoryPanel"
	inv_panel.visible = false
	inv_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	inv_panel.offset_left = -430.0
	inv_panel.offset_top = -250.0
	inv_panel.offset_right = 430.0
	inv_panel.offset_bottom = 250.0
	inv_panel.add_theme_stylebox_override("panel", _make_style(Color(0.07, 0.08, 0.11, 0.96), Color(0.75, 0.63, 0.35, 1.0), 2, 8, 18, 14))

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	inv_panel.add_child(main_vbox)

	var header := HBoxContainer.new()
	main_vbox.add_child(header)
	_make_lbl(header, "🎒 Mochila, Armadura y Taller de Crafteo", 18, Color(0.96, 0.88, 0.65), true)
	inv_gold_label = _make_lbl(header, "💰 25 Oro", 16, Color.GOLD)

	var armor_panel := PanelContainer.new()
	armor_panel.add_theme_stylebox_override("panel", _make_style(Color(0.11, 0.13, 0.18, 0.95), Color(0.45, 0.55, 0.72, 0.85), 1, 6, 10, 6))
	main_vbox.add_child(armor_panel)

	var armor_vbox := VBoxContainer.new()
	armor_vbox.add_theme_constant_override("separation", 4)
	armor_panel.add_child(armor_vbox)
	inv_armor_stats_label = _make_lbl(armor_vbox, "🛡️ Armadura Equipada: Sin armadura (0% Defensa)", 12, Color(0.75, 0.90, 1.0))
	inv_armor_slots_box = HBoxContainer.new()
	inv_armor_slots_box.add_theme_constant_override("separation", 8)
	armor_vbox.add_child(inv_armor_slots_box)
	main_vbox.add_child(HSeparator.new())

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	main_vbox.add_child(columns)

	# Columna Izquierda: Inventario
	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_stretch_ratio = 1.0
	columns.add_child(left_col)
	_make_lbl(left_col, "📦 Recursos y Objetos", 14, Color(0.80, 0.88, 0.98))

	var scroll_items := ScrollContainer.new()
	scroll_items.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_col.add_child(scroll_items)
	inv_items_box = VBoxContainer.new()
	inv_items_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_items_box.add_theme_constant_override("separation", 6)
	scroll_items.add_child(inv_items_box)

	columns.add_child(VSeparator.new())

	# Columna Derecha: Taller de Crafteo
	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_stretch_ratio = 1.05
	columns.add_child(right_col)
	_make_lbl(right_col, "🔨 Recetas de Crafteo", 14, Color(0.95, 0.82, 0.55))

	var scroll_recipes := ScrollContainer.new()
	scroll_recipes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_child(scroll_recipes)
	inv_recipes_box = VBoxContainer.new()
	inv_recipes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_recipes_box.add_theme_constant_override("separation", 6)
	scroll_recipes.add_child(inv_recipes_box)

	main_vbox.add_child(HSeparator.new())

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 12)
	main_vbox.add_child(footer)
	_make_btn(footer, "🩺 [H] Panel Clínico", func():
		inv_panel.visible = false
		if medical_panel and medical_panel.has_method("open_panel"):
			medical_panel.call("open_panel")
	)
	_make_btn(footer, "💾 [F5] Guardar", func(): if GameManager: GameManager.save_game())
	_make_btn(footer, "📂 [F9] Cargar", func(): if GameManager: GameManager.load_game())
	_make_btn(footer, "Controles", func():
		inv_panel.visible = false
		open_controls_panel()
	)
	_make_btn(footer, "✖ [I / ESC] Cerrar", func(): inv_panel.visible = false)
	add_child(inv_panel)

func _setup_controls_panel_ui() -> void:
	controls_panel = PanelContainer.new()
	controls_panel.name = "ControlsPanel"
	controls_panel.visible = false
	controls_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	controls_panel.offset_left = -260.0
	controls_panel.offset_top = -182.0
	controls_panel.offset_right = 260.0
	controls_panel.offset_bottom = 182.0
	var cp_style := _make_style(Color(0.945, 0.910, 0.831, 0.98), Color(0.227, 0.196, 0.157, 1.0), 2, 2, 20, 16)
	cp_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	cp_style.shadow_size = 1
	cp_style.shadow_offset = Vector2(5, 5)
	controls_panel.add_theme_stylebox_override("panel", cp_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	controls_panel.add_child(main_vbox)

	var title_row := HBoxContainer.new()
	main_vbox.add_child(title_row)
	var t_lbl := _make_lbl(title_row, "Teclas", 16, Color(0.149, 0.129, 0.106, 1.0), true)
	t_lbl.add_theme_color_override("font_color", Color(0.149, 0.129, 0.106, 1.0))
	var close_hint := _make_lbl(title_row, "[H / Esc] cerrar", 11, Color(0.353, 0.314, 0.259, 1.0))
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var sep_line := ColorRect.new()
	sep_line.custom_minimum_size = Vector2(0, 1)
	sep_line.color = Color(0.227, 0.196, 0.157, 0.65)
	main_vbox.add_child(sep_line)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 22)
	main_vbox.add_child(columns)

	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.add_theme_constant_override("separation", 4)
	columns.add_child(left_col)
	_make_lbl(left_col, "MOVERSE Y PELEAR", 11, Color(0.561, 0.176, 0.149, 1.0))
	var basic_pairs: Array = [
		["Caminar", "WASD"],
		["Correr", "Mayús"],
		["Saltar", "Espacio"],
		["Rodar", "V"],
		["Sigilo", "Ctrl / C"],
		["Atacar", "Clic izq."],
		["Bloquear / parar", "Q"],
		["Empujar", "X"],
	]
	for pair in basic_pairs:
		_add_help_key_row(left_col, str(pair[0]), str(pair[1]))

	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 4)
	columns.add_child(right_col)
	_make_lbl(right_col, "MUNDO Y PANELES", 11, Color(0.561, 0.176, 0.149, 1.0))
	var more_pairs: Array = [
		["Acción / hablar", "E"],
		["Otra acción / objetivo", "Rueda / G"],
		["Mochila", "I"],
		["Rueda de herramientas", "Tab"],
		["Mapa del valle", "M"],
		["Vecinos / Caso", "J / N"],
		["Salud / heridas", "U"],
		["Cámara 2D / 3D", "F9"],
		["Vista en 1.ª persona", "P"],
		["Zoom de la cámara", "+ / −"],
		["Guardar / cargar", "F5 / F12"],
		["Ver esta ayuda", "H"],
	]
	for pair in more_pairs:
		_add_help_key_row(right_col, str(pair[0]), str(pair[1]))

	add_child(controls_panel)

func _add_help_key_row(parent: VBoxContainer, action_txt: String, key_txt: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	_make_lbl(row, action_txt, 11, Color(0.149, 0.129, 0.106, 1.0), true)
	var k_panel := PanelContainer.new()
	var k_sb := _make_style(Color(0.882, 0.831, 0.722, 1.0), Color(0.227, 0.196, 0.157, 1.0), 1, 1, 5, 1)
	k_panel.add_theme_stylebox_override("panel", k_sb)
	row.add_child(k_panel)
	_make_lbl(k_panel, key_txt, 10, Color(0.149, 0.129, 0.106, 1.0))

func open_controls_panel() -> void:
	if not controls_panel:
		return
	controls_panel.visible = true
	if WorldClock and WorldClock.has_method("set_activity_pause"):
		WorldClock.set_activity_pause(true)

func close_controls_panel() -> void:
	if hiring_letter_panel and hiring_letter_panel.visible:
		hiring_letter_panel.visible = false
	if not controls_panel or not controls_panel.visible:
		return
	controls_panel.visible = false
	if WorldClock and WorldClock.has_method("set_activity_pause"):
		WorldClock.set_activity_pause(false)

func _setup_hiring_letter_panel_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "HiringLetterPanel"
	var show_at_start: bool = (GameManager == null) or (GameManager.has_method("is_demo_mode") and bool(GameManager.call("is_demo_mode")))
	backdrop.visible = show_at_start
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.05, 0.04, 0.03, 0.72)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	hiring_letter_panel = backdrop

	var card := PanelContainer.new()
	card.name = "LetterSheet"
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.offset_left = -280.0
	card.offset_top = -140.0
	card.offset_right = 280.0
	card.offset_bottom = 140.0
	var sheet_style := _make_style(Color(0.945, 0.910, 0.831, 0.99), Color(0.227, 0.196, 0.157, 1.0), 2, 2, 32, 28)
	sheet_style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	sheet_style.shadow_size = 8
	sheet_style.shadow_offset = Vector2(6, 6)
	card.add_theme_stylebox_override("panel", sheet_style)
	backdrop.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	card.add_child(vbox)

	var top_rule := ColorRect.new()
	top_rule.custom_minimum_size = Vector2(0, 1)
	top_rule.color = Color(0.227, 0.196, 0.157, 0.55)
	vbox.add_child(top_rule)

	var body_lbl := _make_lbl(
		vbox,
		"«Carta de contratación — texto pendiente del autor»",
		18,
		Color(0.149, 0.129, 0.106, 1.0),
		true,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var bot_rule := ColorRect.new()
	bot_rule.custom_minimum_size = Vector2(0, 1)
	bot_rule.color = Color(0.227, 0.196, 0.157, 0.55)
	vbox.add_child(bot_rule)

	var hint_lbl := _make_lbl(
		vbox,
		"[E / Enter / Esc / Clic] Continuar hacia el valle",
		11,
		Color(0.353, 0.314, 0.259, 1.0),
		false,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	add_child(backdrop)

func open_hiring_letter_panel() -> void:
	if hiring_letter_panel:
		hiring_letter_panel.visible = true

func close_hiring_letter_panel() -> void:
	if hiring_letter_panel:
		hiring_letter_panel.visible = false

func _on_game_loaded(_filepath: String) -> void:
	close_controls_panel()
	close_hiring_letter_panel()

func _refresh_inventory_list() -> void:
	if not inv_items_box or not player or not ("inventory" in player) or not player.inventory:
		return
	var inv: SimpleInventory = player.inventory
	if inv_gold_label:
		inv_gold_label.text = "💰 %d Oro" % inv.gold

	# Actualizar panel de 4 Slots de Armadura
	if inv_armor_stats_label:
		var a_stats: Dictionary = inv.get_total_armor_stats()
		var def_pct: int = int(round(float(a_stats.get("defense", 0.0)) * 100.0))
		var bleed_pct: int = int(round(float(a_stats.get("bleed_res", 0.0)) * 100.0))
		var stun_pct: int = int(round(float(a_stats.get("stun_res", 0.0)) * 100.0))
		var spd_pct: int = int(round((1.0 + float(a_stats.get("speed_bonus", 0.0))) * 100.0))
		inv_armor_stats_label.text = "🛡️ Armadura Equipada — Defensa: -%d%% Daño | Res. Sangrado: -%d%% | Res. Stun: -%d%% | Velocidad: %d%%" % [def_pct, bleed_pct, stun_pct, spd_pct]

	if inv_armor_slots_box:
		for child in inv_armor_slots_box.get_children():
			child.queue_free()
		var slot_titles: Dictionary = {"HEAD": "🪖 Casco", "CHEST": "🦺 Pecho", "LEGS": "👖 Piernas", "BOOTS": "🥾 Botas"}
		for slot_key in SimpleInventory.ARMOR_SLOTS:
			var eq_id: String = str(inv.equipped_armor.get(slot_key, ""))
			var slot_card := PanelContainer.new()
			slot_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slot_card.add_theme_stylebox_override("panel", _make_style(
				Color(0.16, 0.20, 0.26, 0.95) if eq_id != "" else Color(0.09, 0.10, 0.13, 0.85),
				Color(0.55, 0.78, 0.95, 0.9) if eq_id != "" else Color(0.28, 0.30, 0.36, 0.6), 1, 4, 6, 4))

			var sc_hbox := HBoxContainer.new()
			sc_hbox.add_theme_constant_override("separation", 6)
			slot_card.add_child(sc_hbox)
			if eq_id != "":
				_add_item_icon(sc_hbox, inv.get_item_icon(eq_id), 22.0)

			_make_lbl(sc_hbox, "%s:\n%s" % [str(slot_titles.get(slot_key, slot_key)), inv.get_item_name(eq_id) if eq_id != "" else "Vacío"], 10, Color(0.95, 0.95, 0.85) if eq_id != "" else Color(0.55, 0.58, 0.65), true)

			if eq_id != "":
				var cap_slot: String = str(slot_key)
				var un_btn := _make_btn(sc_hbox, "✖", func(): inv.unequip_armor_slot(cap_slot, player))
				un_btn.tooltip_text = "Desequipar"

			inv_armor_slots_box.add_child(slot_card)

	for child in inv_items_box.get_children():
		child.queue_free()

	if inv.items.is_empty():
		_make_lbl(inv_items_box, "Tu mochila está vacía.\nTala árboles ([3]), pica rocas ([4]), pesca ([8]) o recoge plantas ([E]).", 13, Color(0.65, 0.65, 0.7), false, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		for item_id in inv.items.keys():
			var count: int = int(inv.items[item_id])
			if count <= 0:
				continue
			var info: Dictionary = inv.get_item_info(str(item_id))
			var row := PanelContainer.new()
			row.add_theme_stylebox_override("panel", _make_style(Color(0.13, 0.15, 0.20, 0.9), Color.TRANSPARENT, 0, 4, 10, 6))

			var hbox := HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 10)
			row.add_child(hbox)
			_add_item_icon(hbox, inv.get_item_icon(str(item_id)), 28.0)

			var text_vbox := VBoxContainer.new()
			text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(text_vbox)
			_make_lbl(text_vbox, "%s  x%d   [%s]" % [info.get("name", item_id), count, info.get("category", "Objeto")], 13, Color(0.95, 0.95, 0.98))
			var desc_lbl := _make_lbl(text_vbox, str(info.get("desc", "")), 11, Color(0.70, 0.75, 0.82))
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

			if info.get("usable", false):
				var cat_str: String = str(info.get("category", ""))
				var btn_txt := "🔫 Equipar" if info.get("is_weapon_item", false) else ("🛡️ Equipar" if (info.has("armor_slot") or cat_str.begins_with("Armadura")) else ("🌱 Semilla" if info.get("is_seed", false) else "🍽️ Usar"))
				var captured_id := str(item_id)
				_make_btn(hbox, btn_txt, func():
					inv.use_item(captured_id, player)
					_refresh_hand_slots()
				)

			inv_items_box.add_child(row)

	# Poblar Recetas de Crafteo con Iconos Visuales
	if inv_recipes_box:
		for child in inv_recipes_box.get_children():
			child.queue_free()

		for recipe in SimpleInventory.RECIPES:
			var res_id: String = str(recipe.get("result", ""))
			var res_amt: int = int(recipe.get("amount", 1))
			var craftable: bool = inv.can_craft(recipe)

			var r_row := PanelContainer.new()
			r_row.add_theme_stylebox_override("panel", _make_style(
				Color(0.14, 0.18, 0.15, 0.92) if craftable else Color(0.12, 0.12, 0.15, 0.85),
				Color(0.35, 0.75, 0.45, 0.8) if craftable else Color(0.25, 0.25, 0.30, 0.5), 1, 4, 10, 6))

			var r_hbox := HBoxContainer.new()
			r_hbox.add_theme_constant_override("separation", 10)
			r_row.add_child(r_hbox)
			_add_item_icon(r_hbox, inv.get_item_icon(res_id), 28.0)

			var r_vbox := VBoxContainer.new()
			r_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r_hbox.add_child(r_vbox)
			_make_lbl(r_vbox, "%s x%d" % [inv.get_item_name(res_id), res_amt], 13, Color(0.95, 0.92, 0.72) if craftable else Color(0.75, 0.75, 0.78))

			var ing_dict: Dictionary = recipe.get("ingredients", {})
			var ing_parts: Array[String] = []
			for ing_id in ing_dict.keys():
				ing_parts.append("%s (%d/%d)" % [inv.get_item_name(str(ing_id)), inv.get_count(str(ing_id)), int(ing_dict[ing_id])])

			var r_ing_lbl := _make_lbl(r_vbox, "Requiere: " + ", ".join(ing_parts), 11, Color(0.65, 0.92, 0.70) if craftable else Color(0.85, 0.55, 0.55))
			r_ing_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

			var captured_recipe: Dictionary = recipe
			_make_btn(r_hbox, "Fabricar", func(): inv.craft_recipe(captured_recipe, player), not craftable)
			inv_recipes_box.add_child(r_row)

func _setup_clock_ui() -> void:
	clock_panel = PanelContainer.new()
	clock_panel.name = "WorldClockPanel"
	clock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	clock_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	clock_panel.offset_left = -95.0
	clock_panel.offset_top = 12.0
	clock_panel.offset_right = 95.0
	clock_panel.offset_bottom = 38.0
	var clk_style := _make_style(Color(0.945, 0.910, 0.831, 0.95), Color(0.227, 0.196, 0.157, 1.0), 2, 2, 12, 4)
	clk_style.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
	clk_style.shadow_size = 1
	clk_style.shadow_offset = Vector2(2, 2)
	clock_panel.add_theme_stylebox_override("panel", clk_style)

	var top_hbox := HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_theme_constant_override("separation", 8)
	clock_panel.add_child(top_hbox)

	clock_label = _make_lbl(top_hbox, "", 13, Color(0.149, 0.129, 0.106, 1.0), false, HORIZONTAL_ALIGNMENT_CENTER)
	clock_weather_label = _make_lbl(top_hbox, "despejado", 11, Color(0.353, 0.314, 0.259, 1.0), false, HORIZONTAL_ALIGNMENT_CENTER)

	clock_speed_badge = PanelContainer.new()
	clock_speed_badge.visible = false
	var sp_style := _make_style(Color(0.882, 0.831, 0.722, 1.0), Color(0.227, 0.196, 0.157, 1.0), 1, 1, 4, 0)
	clock_speed_badge.add_theme_stylebox_override("panel", sp_style)
	top_hbox.add_child(clock_speed_badge)
	clock_speed_label = _make_lbl(clock_speed_badge, "×2", 10, Color(0.149, 0.129, 0.106, 1.0), false, HORIZONTAL_ALIGNMENT_CENTER)

	clock_sub_label = Label.new()
	clock_sub_label.visible = false
	add_child(clock_sub_label)
	add_child(clock_panel)

	test_mode_badge = PanelContainer.new()
	test_mode_badge.name = "TestModeBadge"
	test_mode_badge.visible = (player.get("test_mode_active") == true) if player else false
	test_mode_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	test_mode_badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	test_mode_badge.grow_horizontal = Control.GROW_DIRECTION_BOTH
	test_mode_badge.offset_left = -64.0
	test_mode_badge.offset_top = 42.0
	test_mode_badge.offset_right = 64.0
	test_mode_badge.offset_bottom = 62.0
	var tm_style := _make_style(Color(0.561, 0.176, 0.149, 0.98), Color(0.227, 0.196, 0.157, 1.0), 1, 2, 8, 2)
	tm_style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	tm_style.shadow_size = 1
	tm_style.shadow_offset = Vector2(2, 2)
	test_mode_badge.add_theme_stylebox_override("panel", tm_style)
	test_mode_label = _make_lbl(test_mode_badge, "MODO PRUEBAS", 10, Color(0.953, 0.918, 0.839, 1.0), true, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(test_mode_badge)

	if WorldClock:
		WorldClock.time_updated.connect(_on_clock_time_updated)
		if WorldClock.has_signal("weather_changed") and not WorldClock.weather_changed.is_connected(_on_clock_weather_changed):
			WorldClock.weather_changed.connect(_on_clock_weather_changed)
		_on_clock_time_updated(WorldClock.current_day, WorldClock.current_hour, WorldClock.current_minute)

func _setup_toast_ui() -> void:
	toast_box = VBoxContainer.new()
	toast_box.name = "ToastBox"
	toast_box.position = Vector2(16, 96)
	toast_box.custom_minimum_size = Vector2(228, 0)
	toast_box.add_theme_constant_override("separation", 5)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_box)

func push_toast(raw_txt: String, force_bad: bool = false) -> void:
	if not toast_box:
		return
	var clean_t: String = raw_txt.strip_edges()
	if clean_t == "":
		return
	if clean_t.length() > 74:
		clean_t = clean_t.substr(0, 71) + "…"
	var lower_t: String = clean_t.to_lower()
	var is_bad: bool = force_bad or lower_t.find("testigo") != -1 or lower_t.find("crimen") != -1 or lower_t.find("sangr") != -1 or lower_t.find("herid") != -1 or lower_t.find("cerrad") != -1 or lower_t.find("vacía") != -1 or lower_t.find("necesitas") != -1 or lower_t.find("alerta") != -1 or lower_t.find("❌") != -1 or lower_t.find("⚠️") != -1
	while toast_box.get_child_count() >= 3:
		var oldest := toast_box.get_child(0)
		toast_box.remove_child(oldest)
		oldest.queue_free()
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t_sb := StyleBoxFlat.new()
	t_sb.bg_color = Color(0.945, 0.910, 0.831, 0.94)
	t_sb.border_color = Color(0.561, 0.176, 0.149, 1.0) if is_bad else Color(0.722, 0.537, 0.180, 1.0)
	t_sb.border_width_left = 4
	t_sb.border_width_top = 1
	t_sb.border_width_right = 1
	t_sb.border_width_bottom = 1
	t_sb.content_margin_left = 8
	t_sb.content_margin_right = 8
	t_sb.content_margin_top = 4
	t_sb.content_margin_bottom = 4
	t_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	t_sb.shadow_size = 1
	t_sb.shadow_offset = Vector2(2, 2)
	card.add_theme_stylebox_override("panel", t_sb)
	var lbl := _make_lbl(card, clean_t, 11, Color(0.149, 0.129, 0.106, 1.0), true)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.add_child(card)
	var tw := card.create_tween()
	tw.tween_interval(2.8)
	tw.tween_property(card, "modulate:a", 0.0, 0.5)
	tw.tween_callback(card.queue_free)

func _setup_bottom_hud_ui() -> void:
	# 1. Abajo a la izquierda: manos / ranuras rápidas (1, 2, 3)
	hands_box = HBoxContainer.new()
	hands_box.name = "HandsBox"
	hands_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hands_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hands_box.offset_left = 16.0
	hands_box.offset_top = -52.0
	hands_box.offset_right = 142.0
	hands_box.offset_bottom = -14.0
	hands_box.add_theme_constant_override("separation", 5)
	add_child(hands_box)

	_hand_slot_panels.clear()
	_hand_slot_key_labels.clear()
	_hand_slot_icon_labels.clear()
	_hand_slot_icon_rects.clear()
	var default_icons: Array[String] = ["⚔", "🔨", "🪓"]
	for i in range(3):
		var slot_p := PanelContainer.new()
		slot_p.custom_minimum_size = Vector2(38, 38)
		var captured_idx: int = i
		slot_p.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				if player and player.has_method("equip_tool_by_index"):
					player.call("equip_tool_by_index", captured_idx)
					_refresh_hand_slots()
		)
		hands_box.add_child(slot_p)
		_hand_slot_panels.append(slot_p)

		var overlay := Control.new()
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_p.add_child(overlay)

		var k_lbl := Label.new()
		k_lbl.text = str(i + 1)
		k_lbl.position = Vector2(3, 1)
		k_lbl.add_theme_font_size_override("font_size", 9)
		k_lbl.add_theme_color_override("font_color", Color(0.353, 0.314, 0.259, 1.0))
		k_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(k_lbl)
		_hand_slot_key_labels.append(k_lbl)

		var ic_rect := TextureRect.new()
		ic_rect.position = Vector2(9, 10)
		ic_rect.size = Vector2(20, 20)
		ic_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(ic_rect)
		_hand_slot_icon_rects.append(ic_rect)

		var ic_lbl := Label.new()
		ic_lbl.text = default_icons[i]
		ic_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ic_lbl.offset_top = 4.0
		ic_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ic_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ic_lbl.add_theme_font_size_override("font_size", 15)
		ic_lbl.add_theme_color_override("font_color", Color(0.149, 0.129, 0.106, 1.0))
		ic_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(ic_lbl)
		_hand_slot_icon_labels.append(ic_lbl)

	# 2. Abajo a la derecha: oro y [H] teclas
	corner_right_box = HBoxContainer.new()
	corner_right_box.name = "CornerRightBox"
	corner_right_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner_right_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	corner_right_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	corner_right_box.offset_left = -220.0
	corner_right_box.offset_top = -42.0
	corner_right_box.offset_right = -16.0
	corner_right_box.offset_bottom = -14.0
	corner_right_box.alignment = BoxContainer.ALIGNMENT_END
	corner_right_box.add_theme_constant_override("separation", 8)
	add_child(corner_right_box)

	var gold_panel := PanelContainer.new()
	gold_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g_sb := _make_style(Color(0.945, 0.910, 0.831, 0.95), Color(0.227, 0.196, 0.157, 1.0), 1, 2, 9, 4)
	g_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	g_sb.shadow_size = 1
	g_sb.shadow_offset = Vector2(2, 2)
	gold_panel.add_theme_stylebox_override("panel", g_sb)
	corner_right_box.add_child(gold_panel)

	var g_hbox := HBoxContainer.new()
	g_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	g_hbox.add_theme_constant_override("separation", 6)
	gold_panel.add_child(g_hbox)

	var coin_dot := PanelContainer.new()
	coin_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_dot.custom_minimum_size = Vector2(10, 10)
	coin_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var c_sb := _make_style(Color(0.847, 0.663, 0.243, 1.0), Color(0.227, 0.196, 0.157, 1.0), 1, 5, 0, 0)
	coin_dot.add_theme_stylebox_override("panel", c_sb)
	g_hbox.add_child(coin_dot)

	hud_gold_label = _make_lbl(g_hbox, "45 oro", 12, Color(0.149, 0.129, 0.106, 1.0))

	var help_btn := Button.new()
	help_btn.text = "[H] teclas"
	help_btn.focus_mode = Control.FOCUS_NONE
	help_btn.add_theme_font_size_override("font_size", 11)
	help_btn.add_theme_color_override("font_color", Color(0.945, 0.910, 0.831, 1.0))
	var h_sb := _make_style(Color(0.094, 0.082, 0.067, 0.78), Color(0.227, 0.196, 0.157, 1.0), 1, 2, 8, 4)
	help_btn.add_theme_stylebox_override("normal", h_sb)
	help_btn.add_theme_stylebox_override("hover", h_sb)
	help_btn.add_theme_stylebox_override("pressed", h_sb)
	help_btn.pressed.connect(func():
		if controls_panel and controls_panel.visible:
			close_controls_panel()
		else:
			open_controls_panel()
	)
	corner_right_box.add_child(help_btn)

	# 3. Abajo al centro: tarjeta de papel de interacción [E]
	prompt_card = PanelContainer.new()
	prompt_card.name = "InteractionPromptCard"
	prompt_card.visible = false
	prompt_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt_card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	prompt_card.custom_minimum_size = Vector2(256, 0)
	prompt_card.offset_left = -140.0
	prompt_card.offset_right = 140.0
	prompt_card.offset_top = -120.0
	prompt_card.offset_bottom = -14.0
	var p_sb := _make_style(Color(0.945, 0.910, 0.831, 0.97), Color(0.227, 0.196, 0.157, 1.0), 2, 2, 12, 8)
	p_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	p_sb.shadow_size = 1
	p_sb.shadow_offset = Vector2(3, 3)
	prompt_card.add_theme_stylebox_override("panel", p_sb)
	add_child(prompt_card)

	var p_vbox := VBoxContainer.new()
	p_vbox.add_theme_constant_override("separation", 4)
	p_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_card.add_child(p_vbox)

	var p_head := HBoxContainer.new()
	p_head.add_theme_constant_override("separation", 8)
	p_head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p_vbox.add_child(p_head)
	prompt_target_label = _make_lbl(p_head, "Objetivo", 13, Color(0.149, 0.129, 0.106, 1.0))
	prompt_state_label = _make_lbl(p_head, "", 11, Color(0.353, 0.314, 0.259, 1.0), true)
	prompt_cycle_label = _make_lbl(p_head, "", 10, Color(0.353, 0.314, 0.259, 1.0), false, HORIZONTAL_ALIGNMENT_RIGHT)

	var p_line := ColorRect.new()
	p_line.custom_minimum_size = Vector2(0, 1)
	p_line.color = Color(0.796, 0.741, 0.620, 1.0)
	p_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p_vbox.add_child(p_line)

	prompt_actions_box = VBoxContainer.new()
	prompt_actions_box.add_theme_constant_override("separation", 3)
	prompt_actions_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p_vbox.add_child(prompt_actions_box)

	prompt_footer_label = _make_lbl(p_vbox, "", 10, Color(0.353, 0.314, 0.259, 1.0))
	prompt_footer_label.visible = false

	_refresh_hand_slots()

func _refresh_hand_slots() -> void:
	if _hand_slot_panels.size() < 3:
		return
	var active_slot: int = 0
	var slot3_key: String = "3"
	var slot3_icon: String = "🪓"
	var slot_weapons: Array = [null, null, null]
	if player:
		slot_weapons[0] = player.get("sword_weapon")
		slot_weapons[1] = player.get("hammer_weapon")
		slot_weapons[2] = player.get("axe_weapon")
		var eq = player.get("equipped_weapon")
		if eq == player.get("sword_weapon"):
			active_slot = 0
		elif eq == player.get("hammer_weapon"):
			active_slot = 1
		elif eq == player.get("axe_weapon"):
			active_slot = 2
			slot3_key = "3"
			slot3_icon = "🪓"
		elif eq == player.get("pickaxe_weapon"):
			active_slot = 2
			slot3_key = "4"
			slot3_icon = "⛏"
			slot_weapons[2] = eq
		elif eq == player.get("bow_weapon"):
			active_slot = 2
			slot3_key = "5"
			slot3_icon = "🏹"
			slot_weapons[2] = eq
		elif eq == player.get("sickle_weapon"):
			active_slot = 2
			slot3_key = "6"
			slot3_icon = "🌾"
			slot_weapons[2] = eq
		elif eq == player.get("watering_can_weapon"):
			active_slot = 2
			slot3_key = "7"
			slot3_icon = "💧"
			slot_weapons[2] = eq
		elif eq == player.get("fishing_rod_weapon"):
			active_slot = 2
			slot3_key = "8"
			slot3_icon = "🎣"
			slot_weapons[2] = eq
		elif eq == player.get("flintlock_weapon"):
			active_slot = 2
			slot3_key = "9"
			slot3_icon = "🔫"
			slot_weapons[2] = eq
		elif eq == player.get("rifle_weapon"):
			active_slot = 2
			slot3_key = "0"
			slot3_icon = "🎯"
			slot_weapons[2] = eq
	_hand_slot_key_labels[2].text = slot3_key
	_hand_slot_icon_labels[2].text = slot3_icon
	for i in range(3):
		var w_obj = slot_weapons[i]
		var w_tex: Texture2D = w_obj.get("icon") if (w_obj != null and "icon" in w_obj) else null
		if i < _hand_slot_icon_rects.size() and _hand_slot_icon_rects[i]:
			_hand_slot_icon_rects[i].texture = w_tex
			_hand_slot_icon_rects[i].visible = (w_tex != null)
		if i < _hand_slot_icon_labels.size() and _hand_slot_icon_labels[i]:
			_hand_slot_icon_labels[i].visible = (w_tex == null)
		var is_act: bool = (i == active_slot)
		var sb := _make_style(
			Color(0.945, 0.910, 0.831, 0.98) if is_act else Color(0.945, 0.910, 0.831, 0.88),
			Color(0.722, 0.537, 0.180, 1.0) if is_act else Color(0.227, 0.196, 0.157, 1.0),
			2 if is_act else 1, 2, 0, 0
		)
		sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(2, 2)
		_hand_slot_panels[i].add_theme_stylebox_override("panel", sb)

func _process(_delta: float) -> void:
	_refresh_hand_slots()
	var hint := get_node_or_null("HintLabel") as Label
	if hint:
		hint.modulate.a = 0.0
		if hint.text != _last_hint_text:
			_last_hint_text = hint.text
			if _last_hint_text.strip_edges() != "":
				push_toast(_last_hint_text)
	_update_prompt_card()

func _update_prompt_card() -> void:
	if not prompt_card:
		return
	if not player or not is_instance_valid(player):
		prompt_card.visible = false
		return
	var isel = player.get("interaction_selector")
	if isel == null or not is_instance_valid(isel) or not isel.has_method("get_prompt_card_data"):
		prompt_card.visible = false
		return
	var data: Dictionary = isel.call("get_prompt_card_data")
	if data.is_empty():
		prompt_card.visible = false
		return
	prompt_card.visible = true
	if prompt_target_label:
		prompt_target_label.text = str(data.get("target_name", "Objetivo"))
	if prompt_state_label:
		prompt_state_label.text = str(data.get("target_state", ""))
	if prompt_cycle_label:
		prompt_cycle_label.text = str(data.get("cycle_text", ""))
	if prompt_actions_box:
		for ch in prompt_actions_box.get_children():
			prompt_actions_box.remove_child(ch)
			ch.queue_free()
		var acts: Array = data.get("actions", [])
		for a_entry in acts:
			if not (a_entry is Dictionary):
				continue
			var is_sel: bool = bool(a_entry.get("selected", false))
			var row_p := PanelContainer.new()
			row_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var r_sb := _make_style(
				Color(0.882, 0.831, 0.722, 1.0) if is_sel else Color(0, 0, 0, 0),
				Color(0, 0, 0, 0), 0, 1, 4, 2
			)
			row_p.add_theme_stylebox_override("panel", r_sb)
			prompt_actions_box.add_child(row_p)

			var r_hbox := HBoxContainer.new()
			r_hbox.add_theme_constant_override("separation", 7)
			r_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row_p.add_child(r_hbox)

			var k_box := PanelContainer.new()
			k_box.custom_minimum_size = Vector2(16, 16)
			k_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var k_sb := _make_style(
				Color(0.149, 0.129, 0.106, 1.0) if is_sel else Color(0.882, 0.831, 0.722, 0.8),
				Color(0.227, 0.196, 0.157, 1.0), 1, 1, 3, 0
			)
			k_box.add_theme_stylebox_override("panel", k_sb)
			r_hbox.add_child(k_box)
			_make_lbl(k_box, str(a_entry.get("key", "E")), 10, Color(0.945, 0.910, 0.831, 1.0) if is_sel else Color(0.353, 0.314, 0.259, 1.0), false, HORIZONTAL_ALIGNMENT_CENTER)

			_make_lbl(r_hbox, str(a_entry.get("text", "Usar")), 12 if is_sel else 11, Color(0.149, 0.129, 0.106, 1.0) if is_sel else Color(0.353, 0.314, 0.259, 1.0), true)

	if prompt_footer_label:
		var ft: String = str(data.get("footer", ""))
		prompt_footer_label.text = ft
		prompt_footer_label.visible = (ft != "")
	prompt_card.reset_size()
	var min_sz: Vector2 = prompt_card.get_combined_minimum_size()
	var w_half: float = maxf(140.0, min_sz.x * 0.5)
	prompt_card.offset_left = -w_half
	prompt_card.offset_right = w_half
	prompt_card.offset_bottom = -16.0
	prompt_card.offset_top = -16.0 - min_sz.y

func _on_player_test_mode_changed(active: bool) -> void:
	if test_mode_badge:
		test_mode_badge.visible = active
	if WorldClock:
		_on_clock_time_updated(WorldClock.current_day, WorldClock.current_hour, WorldClock.current_minute)

func _on_clock_weather_changed(_weather_type: int, _weather_name: String) -> void:
	if WorldClock:
		_on_clock_time_updated(WorldClock.current_day, WorldClock.current_hour, WorldClock.current_minute)

func _on_clock_time_updated(_day: int, _hour: int, _minute: int) -> void:
	_init_default_objectives()
	if not clock_label or not WorldClock:
		return
	var icon := "☀" if (WorldClock.current_hour >= 6 and WorldClock.current_hour < 20) else "☾"
	var day_names: Array[String] = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
	var d_name: String = day_names[posmod(int(WorldClock.current_day) - 1, 7)]
	clock_label.text = "%s  %s · %02d:%02d" % [icon, d_name, int(WorldClock.current_hour), int(WorldClock.current_minute)]
	if clock_weather_label:
		var w_txt: String = "despejado"
		var w_str: String = ""
		if WorldClock.has_method("get_weather_name"):
			w_str = str(WorldClock.get_weather_name()).to_lower()
		elif WorldClock.has_method("get_weather_label"):
			w_str = str(WorldClock.get_weather_label()).to_lower()
		var w_enum: int = int(WorldClock.current_weather) if "current_weather" in WorldClock else 0
		if w_str.find("tormenta") != -1:
			w_txt = "tormenta"
		elif w_str.find("lluvia") != -1 or w_enum == 1:
			w_txt = "lluvia"
		elif w_str.find("niebla") != -1 or w_enum == 2:
			w_txt = "niebla"
		clock_weather_label.text = w_txt
	var cur_sp: float = float(WorldClock.get("persistent_time_scale")) if "persistent_time_scale" in WorldClock else 1.0
	if clock_speed_badge and clock_speed_label:
		clock_speed_badge.visible = not is_equal_approx(cur_sp, 1.0)
		clock_speed_label.text = "×%d" % int(round(cur_sp))
	var gold_val := 45
	if player and "inventory" in player and player.inventory:
		gold_val = player.inventory.gold
	if hud_gold_label:
		hud_gold_label.text = "%d oro" % gold_val

func _init_default_objectives() -> void:
	var old_hud: Control = get_node_or_null("ObjectiveHUD") as Control
	if old_hud:
		old_hud.visible = false

func setup_hint_label() -> void:
	var hint = get_node_or_null("HintLabel")
	if hint:
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint.layout_mode = 1
		hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		hint.position.y += 72
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD
		hint.custom_minimum_size = Vector2(300, 50)
		hint.grow_horizontal = Control.GROW_DIRECTION_BOTH

func _on_health_changed(current: float, max_val: float) -> void:
	health_bar.value = current
	health_bar.max_value = max_val

func _on_stamina_changed(current: float, max_val: float) -> void:
	stamina_bar.value = current
	stamina_bar.max_value = max_val

func _set_bar_row_visible(bar: ProgressBar, vis: bool) -> void:
	if not bar:
		return
	bar.visible = vis
	var p := bar.get_parent() as CanvasItem
	if p:
		p.visible = vis

func _on_blood_changed(current: float, max_val: float) -> void:
	blood_bar.value = current
	blood_bar.max_value = max_val
	_set_bar_row_visible(blood_bar, current > 0.5)

func _on_stun_changed(current: float, max_val: float) -> void:
	stun_bar.value = current
	stun_bar.max_value = max_val
	_set_bar_row_visible(stun_bar, current > 0.5)

func _on_hygiene_changed(current: float, max_val: float) -> void:
	if hygiene_bar:
		hygiene_bar.max_value = max_val
		hygiene_bar.value = current
		_set_bar_row_visible(hygiene_bar, current < 65.0)
		_shrink_stats_box()

func _on_hunger_changed(current: float, max_val: float) -> void:
	if hunger_bar:
		hunger_bar.max_value = max_val
		hunger_bar.value = current
		_set_bar_row_visible(hunger_bar, current < 75.0)
		_shrink_stats_box()

func _on_sleep_changed(current: float, max_val: float) -> void:
	if sleep_bar:
		sleep_bar.max_value = max_val
		sleep_bar.value = current
		_set_bar_row_visible(sleep_bar, current < 75.0)
		_shrink_stats_box()

func _shrink_stats_box() -> void:
	var sb: PanelContainer = get_node_or_null("StatsBox") as PanelContainer
	if sb:
		sb.size = Vector2.ZERO

func _ensure_compact_bars() -> void:
	pass

func _on_exhausted() -> void:
	stamina_bar.modulate = Color.GRAY
	get_tree().create_timer(1.0).timeout.connect(func(): stamina_bar.modulate = Color.WHITE)

func _create_stats_box() -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = "StatsBox"
	panel.position = Vector2(16, 14)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(col)
	return col

func _create_paper_bar_row(stats_box: VBoxContainer, icon_txt: String, fill_color: Color, start_visible: bool) -> ProgressBar:
	var row := HBoxContainer.new()
	row.visible = start_visible
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_box.add_child(row)

	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(20, 14)
	icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic_sb := _make_style(Color(0.945, 0.910, 0.831, 0.94), Color(0.227, 0.196, 0.157, 1.0), 1, 1, 2, 0)
	ic_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	ic_sb.shadow_size = 1
	ic_sb.shadow_offset = Vector2(2, 2)
	icon_panel.add_theme_stylebox_override("panel", ic_sb)
	row.add_child(icon_panel)
	_make_lbl(icon_panel, icon_txt, 10, Color(0.149, 0.129, 0.106, 1.0), true, HORIZONTAL_ALIGNMENT_CENTER)

	var bar := ProgressBar.new()
	bar.visible = start_visible
	bar.custom_minimum_size = Vector2(138, 11)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.094, 0.082, 0.067, 0.82)
	bg.border_color = Color(0.106, 0.094, 0.078, 1.0)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(1)
	bg.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	bg.shadow_size = 1
	bg.shadow_offset = Vector2(2, 2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.border_color = Color(0.847, 0.800, 0.706, 0.45)
	fill.border_width_top = 1
	fill.set_corner_radius_all(1)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)

	bar.visibility_changed.connect(func():
		if is_instance_valid(row):
			row.visible = bar.visible
	)
	return bar
