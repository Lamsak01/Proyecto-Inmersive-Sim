extends Control

@export var player: CharacterBody2D
@export var health_bar: ProgressBar
@export var stamina_bar: ProgressBar
@export var blood_bar: ProgressBar
@export var stun_bar: ProgressBar

func _ready() -> void:
	# 1. Find Player if not assigned
	if not player:
		player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_node_or_null("/root/World/Player")
	
	if not player:
		print("UI: Player not found!")
		return

	# 2. Setup Bars if not assigned
	if not health_bar:
		health_bar = _create_fallback_bar(Color.RED, Vector2(20, 20), "HP")
		add_child(health_bar)
	
	if not stamina_bar:
		stamina_bar = _create_fallback_bar(Color.GREEN, Vector2(20, 46), "STM")
		add_child(stamina_bar)

	if not blood_bar:
		blood_bar = _create_fallback_bar(Color.CRIMSON, Vector2(20, 72), "BLD")
		blood_bar.value = 0.0
		add_child(blood_bar)

	if not stun_bar:
		stun_bar = _create_fallback_bar(Color.GOLD, Vector2(20, 98), "STN")
		stun_bar.value = 0.0
		add_child(stun_bar)

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
	
	setup_hint_label()
	_init_default_objectives()

func _init_default_objectives() -> void:
	if not ObjectiveManager:
		return
	var find_sword = load("res://resources/objectives/obj_find_sword.tres")
	if find_sword:
		ObjectiveManager.add_objective(find_sword)
	var kill_frogs = load("res://resources/objectives/obj_kill_frogs.tres")
	if kill_frogs:
		ObjectiveManager.add_objective(kill_frogs)

func setup_hint_label() -> void:
	var hint = get_node_or_null("HintLabel")
	if hint:
		hint.layout_mode = 1
		hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		hint.position.y += 60
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

func _on_blood_changed(current: float, max_val: float) -> void:
	blood_bar.value = current
	blood_bar.max_value = max_val

func _on_stun_changed(current: float, max_val: float) -> void:
	stun_bar.value = current
	stun_bar.max_value = max_val

func _on_exhausted() -> void:
	stamina_bar.modulate = Color.GRAY
	get_tree().create_timer(1.0).timeout.connect(func(): stamina_bar.modulate = Color.GREEN)

func _create_fallback_bar(color: Color, pos: Vector2, label_text: String = "") -> ProgressBar:
	var bar = ProgressBar.new()
	bar.position = pos
	bar.size = Vector2(180, 20)
	bar.modulate = color
	bar.show_percentage = false
	if label_text != "":
		var lbl = Label.new()
		lbl.text = label_text
		lbl.position = Vector2(6, 0)
		lbl.add_theme_font_size_override("font_size", 12)
		bar.add_child(lbl)
	return bar
