extends CharacterBody2D

@onready var health_comp: HealthComponent = $HealthComponent
@onready var armor_comp: ArmorComponent = $ArmorComponent
@onready var ai: EnemyAI = $EnemyAI
@onready var alert_indicator: AlertIndicator = $AlertIndicator
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Hurtbox = get_node_or_null("Hurtbox")

const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

func _ready() -> void:
	# Add to player detection group
	add_to_group("enemies")
	
	# Setup components
	if health_comp:
		health_comp.died.connect(_on_died)
	
	# Initial armor setup for testing
	if armor_comp:
		armor_comp.equip(CombatConstants.ArmorSlot.BODY, CombatConstants.ArmorMaterial.CLOTH)
	
	# Connect AI signals
	if ai:
		ai.attack_triggered.connect(_on_ai_attack)
		ai.state_changed.connect(_on_ai_state_changed)
		ai.awareness_changed.connect(_on_ai_awareness_changed)
	
	if hurtbox:
		hurtbox.hit_received.connect(take_damage)

@export var weight: float = 10.0
var push_velocity: Vector2 = Vector2.ZERO

@onready var vision_cone: VisionCone2D = $VisionCone2D
@onready var prompt_label: Label = $PromptLabel

func _physics_process(delta: float) -> void:
	# Apply push decay
	if push_velocity.length() > 0:
		push_velocity = push_velocity.move_toward(Vector2.ZERO, 500 * delta)
		
	# Combine AI velocity with push velocity
	# Note: AI sets velocity. We add push on top.
	velocity += push_velocity
	
	move_and_slide()
	
	# Flip sprite based on movement direction
	if velocity.x != 0:
		anim.flip_h = velocity.x < 0
	
	# Animation State Management
	if anim.sprite_frames.has_animation("run"):
		if velocity.length() > 5.0:
			if anim.animation != "run":
				anim.play("run")
		elif anim.sprite_frames.has_animation("idle"): # Only switch to idle if we have it
			if anim.animation != "idle":
				anim.play("idle")
	elif anim.sprite_frames.has_animation("fly"):
		if anim.animation != "fly":
			anim.play("fly")
	
	# Rotate vision cone to match AI facing direction
	# Rotate vision cone to match AI facing direction
	if vision_cone and ai and is_instance_valid(ai):
		# Default to right if zero (avoid weird angles)
		var dir = ai.facing_direction
		if dir.length_squared() > 0.001:
			vision_cone.rotation = dir.angle()
			
	# Dynamic Cone Size based on Player Stealth (Always update)
	if vision_cone and ai:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("is_stealthing"):
			if player.is_stealthing():
				# Agachado: radio y ángulo reducidos
				vision_cone.radius = ai.detection_range * 0.5
				vision_cone.angle_deg = 60.0
			else:
				# Normal: ángulo real de _is_in_fov (dot > 0.5 = 120° total)
				vision_cone.radius = ai.detection_range
				vision_cone.angle_deg = 120.0
		else:
			vision_cone.radius = ai.detection_range
			vision_cone.angle_deg = 120.0

func show_prompt() -> void:
	if prompt_label:
		prompt_label.visible = true
		prompt_label.modulate = Color.YELLOW

func hide_prompt() -> void:
	if prompt_label:
		prompt_label.visible = false

func apply_push(force: Vector2) -> void:
	push_velocity = force

func take_damage(data: DamageData) -> void:
	if armor_comp:
		data = armor_comp.calculate_mitigation(data)
	
	# Stealth Critical Hit
	if ai and (ai.current_state == EnemyAI.State.IDLE or ai.current_state == EnemyAI.State.SEARCH):
		data.amount *= 3.0
		# Visual Critical Feedback
		if FloatingTextScene:
			var floating_text = FloatingTextScene.instantiate()
			floating_text.start_text = "CRITICAL!"
			floating_text.text_color = Color.YELLOW
			floating_text.global_position = global_position + Vector2(0, -40)
			get_tree().current_scene.add_child(floating_text)

	if health_comp:
		health_comp.take_damage(data)
		
	# Notify AI of attack
	if ai and data.source:
		if ai.has_method("notify_damage"):
			ai.notify_damage(data.source)

	# Knockback
	if "knockback_force" in data and data.source:
		var knockback_dir = (global_position - data.source.global_position).normalized()
		apply_push(knockback_dir * data.knockback_force)
	
	# Visual Flash
	modulate = Color(10, 10, 10) # Flash White
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 0, 0) # Return to Red

func knockout() -> void:
	# Instantly disable AI to prevent alerting others during the same frame
	if is_instance_valid(ai):
		ai.set_physics_process(false)
		ai.current_state = EnemyAI.State.IDLE

	if health_comp:
		# Instant kill
		var data = DamageData.new()
		data.amount = health_comp.max_health * 10
		data.type = CombatConstants.DamageType.BLUNT
		health_comp.take_damage(data)
		# Optional: Play special animation or sound here

func _on_ai_attack(damage_data: DamageData) -> void:
	"""Called when AI wants to attack"""
	if ai.target and ai.target.has_method("take_damage"):
		ai.target.take_damage(damage_data)

func _on_ai_state_changed(new_state: EnemyAI.State) -> void:
	"""Called when AI changes state"""
	if vision_cone:
		match new_state:
			EnemyAI.State.IDLE:
				vision_cone.color = Color(0, 1, 0, 0.2) # Green
			EnemyAI.State.ALERT, EnemyAI.State.SEARCH, EnemyAI.State.RETURN:
				vision_cone.color = Color(1, 1, 0, 0.2) # Yellow
			EnemyAI.State.CHASE, EnemyAI.State.ATTACK:
				vision_cone.color = Color(1, 0, 0, 0.2) # Red

func _on_ai_awareness_changed(level: float, is_alerted: bool) -> void:
	if alert_indicator:
		alert_indicator.update_awareness(level, is_alerted)

@export var enemy_id: String = "generic_enemy"

func _on_died() -> void:
	# Quest Progress
	if ObjectiveManager:
		ObjectiveManager.progress_objective(0, enemy_id, 1) # 0 = KILL

	# Disable logic
	set_physics_process(false)
	ai.set_physics_process(false)
	
	# Visuals: Fall and Gray
	anim.stop()
	rotation_degrees = 90
	modulate = Color.GRAY
	
	# Cleanup UI
	if vision_cone: vision_cone.queue_free()
	if prompt_label: prompt_label.queue_free()
	if alert_indicator: alert_indicator.queue_free()
	
	# Disable Collision (become a corpse)
	collision_layer = 0
	collision_mask = 0
	
	# Remove from groups
	remove_from_group("enemies")
	
	# Optional: Fade out after time
	var tween = create_tween()
	tween.tween_interval(10.0) # Stay as corpse for 10s
	tween.tween_property(self, "modulate:a", 0.0, 2.0)
	tween.tween_callback(queue_free)

func play_attack_anticipation(duration: float) -> void:
	var original_modulate = modulate
	modulate = Color(1.0, 0.5, 0.0) # Orange warning color
	
	# Little scale bump for anticipation
	var tween = create_tween()
	var orig_scale = scale
	tween.tween_property(self, "scale", orig_scale * 1.1, duration * 0.5)
	tween.tween_property(self, "scale", orig_scale, duration * 0.5)
	
	await get_tree().create_timer(duration).timeout
	if modulate == Color(1.0, 0.5, 0.0): # Revert if not changed by damage
		modulate = original_modulate
