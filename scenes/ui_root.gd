extends Control

@export var player: CharacterBody2D
@export var health_bar: ProgressBar
@export var stamina_bar: ProgressBar

func _ready() -> void:
	# 1. Find Player if not assigned
	if not player:
		player = get_tree().get_first_node_in_group("player")
	if not player:
		# Try looking at root
		player = get_node_or_null("/root/World/Player")
	
	if not player:
		print("UI: Player not found!")
		return

	# 2. Setup Bars if not assigned (Fallback for immediate testing)
	if not health_bar:
		health_bar = _create_fallback_bar(Color.RED, Vector2(20, 20))
		add_child(health_bar)
	
	if not stamina_bar:
		stamina_bar = _create_fallback_bar(Color.GREEN, Vector2(20, 50))
		add_child(stamina_bar)

	# 3. Connect Signals
	if player.has_node("HealthComponent"):
		var health: HealthComponent = player.get_node("HealthComponent")
		health.health_changed.connect(_on_health_changed)
		# Initialize
		health_bar.max_value = health.max_health
		health_bar.value = health.current_health
	
	if player.has_node("StaminaComponent"):
		var stamina: StaminaComponent = player.get_node("StaminaComponent")
		stamina.stamina_changed.connect(_on_stamina_changed)
		stamina.exhausted.connect(_on_exhausted)
		# Initialize
		stamina_bar.max_value = stamina.max_stamina
		stamina_bar.value = stamina.current_stamina
	
	setup_hint_label()

func setup_hint_label() -> void:
	var hint = get_node_or_null("HintLabel")
	if hint:
		hint.layout_mode = 1 # Anchors
		hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		hint.position.y += 60 # Margin from top
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Ensure it doesn't wrap weirdly
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD
		hint.custom_minimum_size = Vector2(300, 50)
		hint.grow_horizontal = Control.GROW_DIRECTION_BOTH

func _on_health_changed(current: float, max_val: float) -> void:
	health_bar.value = current
	health_bar.max_value = max_val

func _on_stamina_changed(current: float, max_val: float) -> void:
	stamina_bar.value = current
	stamina_bar.max_value = max_val

func _on_exhausted() -> void:
	stamina_bar.modulate = Color.GRAY
	get_tree().create_timer(1.0).timeout.connect(func(): stamina_bar.modulate = Color.GREEN)

func _create_fallback_bar(color: Color, pos: Vector2) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.position = pos
	bar.size = Vector2(200, 20)
	bar.modulate = color
	bar.show_percentage = false
	return bar
