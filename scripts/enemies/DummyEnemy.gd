extends CharacterBody2D

@onready var health_comp: HealthComponent = $HealthComponent
@onready var stun_comp: StunComponent = get_node_or_null("StunComponent")
@onready var ai: EnemyAI = $EnemyAI
@onready var alert_indicator: AlertIndicator = $AlertIndicator
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Hurtbox = get_node_or_null("Hurtbox")
@onready var vision_cone: VisionCone2D = $VisionCone2D
@onready var prompt_label: Label = $PromptLabel

const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

@export var weight: float = 10.0
@export var enemy_id: String = "generic_enemy"

var push_velocity: Vector2 = Vector2.ZERO
var is_stunned_flag: bool = false
var is_weak_flag: bool = false
var is_dead_flag: bool = false
var respawn_on_day: int = -1
var home_spawn_pos: Vector2 = Vector2.ZERO
var _player_ref: Node2D = null
var _last_stealth_state: int = -1 # -1 = uninitialized, 0 = normal, 1 = stealthing
var _death_tween: Tween = null
var _damaged_by_player: bool = false

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	home_spawn_pos = global_position
	add_to_group("enemies")
	add_to_group("plains_hostiles")

	if WorldClock and not WorldClock.day_passed.is_connected(_on_day_passed):
		WorldClock.day_passed.connect(_on_day_passed)
	
	# Setup Health & Bleed
	if health_comp:
		health_comp.died.connect(_on_died)
		health_comp.bleed_triggered.connect(_on_bleed_triggered)
		health_comp.weakness_changed.connect(_on_weakness_changed)
	
	# Setup Stun (create dynamically if not present in scene)
	if not stun_comp:
		stun_comp = StunComponent.new()
		stun_comp.name = "StunComponent"
		stun_comp.max_stun = 100.0
		stun_comp.recovery_rate = 10.0
		stun_comp.stun_duration = 3.0
		add_child(stun_comp)
	stun_comp.stunned.connect(_on_stunned)
	
	# Connect AI signals
	if ai:
		ai.attack_triggered.connect(_on_ai_attack)
		ai.state_changed.connect(_on_ai_state_changed)
		ai.awareness_changed.connect(_on_ai_awareness_changed)
	
	if hurtbox:
		hurtbox.hit_received.connect(take_damage)

func _physics_process(_delta: float) -> void:
	if is_stunned_flag:
		velocity = Vector2.ZERO
		return

	if not is_instance_valid(_player_ref):
		_player_ref = get_tree().get_first_node_in_group("player") as Node2D
	var far_offscreen: bool = is_instance_valid(_player_ref) and global_position.distance_squared_to(_player_ref.global_position) > 520.0 * 520.0

	if far_offscreen and velocity.length_squared() < 0.01:
		if vision_cone and vision_cone.visible:
			vision_cone.visible = false
		return

	if is_weak_flag:
		velocity *= 0.5

	if velocity.length_squared() > 0.01:
		move_and_slide()
	
	# Flip sprite based on movement direction
	if velocity.x != 0:
		anim.flip_h = velocity.x < 0
	
	# Animation State Management
	if anim.sprite_frames.has_animation("run"):
		if velocity.length_squared() > 25.0:
			if anim.animation != "run":
				anim.play("run")
		elif anim.sprite_frames.has_animation("idle"):
			if anim.animation != "idle":
				anim.play("idle")
	elif anim.sprite_frames.has_animation("fly"):
		if anim.animation != "fly":
			anim.play("fly")
	
	# Rotate vision cone to match AI facing direction
	if vision_cone and ai and is_instance_valid(ai):
		vision_cone.visible = not far_offscreen
		if not far_offscreen:
			var dir = ai.facing_direction
			if dir.length_squared() > 0.001:
				vision_cone.rotation = dir.angle()
				
			# Dynamic Cone Size based on Time of Day (WorldClock) & Player Stealth
			var stealth_now := 0
			if _player_ref and _player_ref.has_method("is_stealthing") and _player_ref.is_stealthing():
				stealth_now = 1
			vision_cone.radius = ai.get_effective_detection_range()
			if stealth_now != _last_stealth_state:
				_last_stealth_state = stealth_now
				vision_cone.angle_deg = 60.0 if stealth_now == 1 else 120.0

func show_prompt() -> void:
	if prompt_label and not prompt_label.visible:
		prompt_label.visible = true
		prompt_label.modulate = Color.YELLOW

func hide_prompt() -> void:
	if prompt_label and prompt_label.visible:
		prompt_label.visible = false

func apply_push(force: Vector2) -> void:
	push_velocity = force

func _spawn_floating_text(text: String, color: Color, offset_y: float = -40.0) -> void:
	if FloatingTextScene:
		var floating_text = FloatingTextScene.instantiate()
		floating_text.start_text = text
		floating_text.text_color = color
		floating_text.global_position = global_position + Vector2(0, offset_y)
		get_tree().current_scene.add_child(floating_text)

func take_damage(data: DamageData) -> void:
	if is_dead_flag:
		return
	var dmg = data.copy()
	if dmg.source and (dmg.source.is_in_group("player") or dmg.source.is_in_group("player_trap") or dmg.source.is_in_group("companion_pets")):
		_damaged_by_player = true
	
	# Stealth Critical Hit
	if ai and dmg.source and dmg.source.is_in_group("player") and (ai.current_state == EnemyAI.State.IDLE or ai.current_state == EnemyAI.State.SEARCH):
		dmg.amount *= 3.0
		_spawn_floating_text("CRITICAL!", Color.YELLOW, -40.0)

	if health_comp:
		health_comp.take_damage(dmg)
		
	if stun_comp and health_comp and health_comp.current_health > 0:
		stun_comp.take_damage(dmg)
		
	# Notify AI of attack
	if ai and dmg.source and not is_stunned_flag:
		if ai.has_method("notify_damage"):
			var notify_target: Node2D = get_tree().get_first_node_in_group("player") as Node2D if dmg.source.is_in_group("player_trap") else (dmg.source as Node2D)
			ai.notify_damage(notify_target)
	
	# Visual Flash
	modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and health_comp and health_comp.current_health > 0:
		modulate = Color(0.5, 0.5, 1.0) if is_stunned_flag else (Color(1.0, 0.55, 0.55) if is_weak_flag else Color.WHITE)

func _on_bleed_triggered(_dps_amount: float) -> void:
	_spawn_floating_text("BLEEDING!", Color.CRIMSON, -28.0)

func _on_weakness_changed(weak: bool) -> void:
	is_weak_flag = weak
	if not is_stunned_flag:
		modulate = Color(1.0, 0.55, 0.55) if weak else Color.WHITE

func _on_stunned(stunned: bool) -> void:
	if is_dead_flag:
		return
	is_stunned_flag = stunned
	if ai:
		ai.set_physics_process(not stunned)
	if vision_cone:
		vision_cone.visible = not stunned
	if stunned:
		anim.stop()
		hide_prompt()
		rotation_degrees = 90
		modulate = Color(0.5, 0.6, 1.0)
		_spawn_floating_text("STUNNED!", Color.AQUA, -45.0)
	else:
		rotation_degrees = 0
		modulate = Color(1.0, 0.55, 0.55) if is_weak_flag else Color.WHITE
		if ai and health_comp and health_comp.current_health > 0:
			ai.on_noise_heard(global_position)

func knockout() -> void:
	"""Takedown no letal desde sigilo: deja inconsciente al enemigo durante 10 segundos."""
	if stun_comp:
		stun_comp.apply_knockout(10.0)
		_spawn_floating_text("KO!", Color.ORANGE, -58.0)

func _on_ai_attack(damage_data: DamageData) -> void:
	if ai.target and ai.target.has_method("take_damage"):
		ai.target.take_damage(damage_data)

func _on_ai_state_changed(new_state: EnemyAI.State) -> void:
	if vision_cone:
		match new_state:
			EnemyAI.State.IDLE:
				vision_cone.color = Color(0, 1, 0, 0.2)
			EnemyAI.State.ALERT, EnemyAI.State.SEARCH, EnemyAI.State.RETURN:
				vision_cone.color = Color(1, 1, 0, 0.2)
			EnemyAI.State.CHASE, EnemyAI.State.ATTACK:
				vision_cone.color = Color(1, 0, 0, 0.2)

func _on_ai_awareness_changed(level: float, is_alerted: bool) -> void:
	if alert_indicator:
		alert_indicator.update_awareness(level, is_alerted)

func _on_died() -> void:
	if is_dead_flag:
		return
	is_dead_flag = true
	var cur_day: int = WorldClock.current_day if WorldClock else 1
	respawn_on_day = cur_day + 2

	var player_involved: bool = _damaged_by_player or (is_instance_valid(_player_ref) and global_position.distance_to(_player_ref.global_position) <= 240.0)
	if player_involved:
		if ObjectiveManager:
			ObjectiveManager.progress_objective(0, enemy_id, 1) # 0 = KILL
		_grant_plains_loot()

	set_physics_process(false)
	if ai:
		ai.set_physics_process(false)
		ai._clear_ghost()

	anim.stop()
	rotation_degrees = 90
	modulate = Color.GRAY

	if vision_cone:
		vision_cone.visible = false
	if prompt_label:
		prompt_label.visible = false
	if alert_indicator:
		alert_indicator.visible = false

	collision_layer = 0
	collision_mask = 0
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

	remove_from_group("enemies")
	remove_from_group("has_los_to_player")

	if _death_tween and _death_tween.is_valid():
		_death_tween.kill()
	_death_tween = create_tween()
	_death_tween.tween_interval(6.0)
	_death_tween.tween_property(self, "modulate:a", 0.0, 1.5)
	_death_tween.tween_callback(func():
		if is_dead_flag:
			visible = false
	)

func _grant_plains_loot() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not ("inventory" in player) or not player.inventory:
		return
	var inv: SimpleInventory = player.inventory
	var is_frog: bool = (enemy_id == "frog" or name.begins_with("Frog"))
	if is_frog:
		inv.add_item("frog_legs", 2)
		inv.add_gold(6)
		_spawn_floating_text("🐸 Botín Ciénaga: +2 Ancas de Rana, +6 Oro", Color.SPRING_GREEN, -46.0)
	else:
		inv.add_item("bandit_scrap", 1)
		inv.add_gold(15)
		_spawn_floating_text("⚔️ Botín Llanura: +1 Chatarra/Reliquia, +15 Oro", Color.GOLD, -46.0)

func _on_day_passed(new_day: int) -> void:
	if is_dead_flag and respawn_on_day > 0 and new_day >= respawn_on_day:
		_respawn_enemy()

func _respawn_enemy() -> void:
	if _death_tween and _death_tween.is_valid():
		_death_tween.kill()
		_death_tween = null
	is_dead_flag = false
	_damaged_by_player = false
	is_stunned_flag = false
	is_weak_flag = false
	respawn_on_day = -1
	global_position = home_spawn_pos
	rotation_degrees = 0
	modulate = Color.WHITE
	visible = true
	collision_layer = 4
	collision_mask = 3
	if hurtbox:
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
	if not is_in_group("enemies"):
		add_to_group("enemies")
	if health_comp:
		health_comp.current_health = health_comp.max_health
		health_comp.stop_bleeding()
	if stun_comp:
		stun_comp.clear_stun()
	if vision_cone:
		vision_cone.visible = true
	if alert_indicator:
		alert_indicator.visible = true
	if ai:
		ai.current_state = EnemyAI.State.IDLE
		ai.target = null
		ai.awareness_level = 0.0
		if ai.has_method("_clear_ghost"):
			ai._clear_ghost()
		ai.set_physics_process(true)
	set_physics_process(true)
	if anim and anim.sprite_frames:
		if anim.sprite_frames.has_animation("idle"):
			anim.play("idle")
		elif anim.sprite_frames.has_animation("fly"):
			anim.play("fly")

func to_save_dict() -> Dictionary:
	return {
		"dead": is_dead_flag,
		"respawn_day": respawn_on_day,
		"hp": health_comp.current_health if health_comp else 50.0,
		"pos_x": global_position.x,
		"pos_y": global_position.y
	}

func from_save_dict(data: Dictionary) -> void:
	is_dead_flag = bool(data.get("dead", false))
	respawn_on_day = int(data.get("respawn_day", -1))
	if is_dead_flag:
		set_physics_process(false)
		if ai:
			if ai.has_method("_clear_ghost"):
				ai._clear_ghost()
			ai.set_physics_process(false)
		if hurtbox:
			hurtbox.set_deferred("monitoring", false)
			hurtbox.set_deferred("monitorable", false)
		visible = false
		collision_layer = 0
		collision_mask = 0
		remove_from_group("enemies")
		remove_from_group("has_los_to_player")
	else:
		_respawn_enemy()
		if data.has("pos_x") and data.has("pos_y"):
			global_position = Vector2(float(data["pos_x"]), float(data["pos_y"]))
		if health_comp and data.has("hp"):
			health_comp.current_health = clampf(float(data["hp"]), 1.0, health_comp.max_health)

func play_attack_anticipation(duration: float) -> void:
	var original_modulate = modulate
	modulate = Color(1.0, 0.5, 0.0)
	
	var tween = create_tween()
	var orig_scale = scale
	tween.tween_property(self, "scale", orig_scale * 1.1, duration * 0.5)
	tween.tween_property(self, "scale", orig_scale, duration * 0.5)
	
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self) and modulate == Color(1.0, 0.5, 0.0):
		modulate = original_modulate
