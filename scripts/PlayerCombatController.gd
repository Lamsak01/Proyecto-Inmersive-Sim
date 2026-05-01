extends Node
class_name PlayerCombatController

@onready var player: CharacterBody2D = get_parent()
@onready var interact_area: Area2D = $"../InteractArea"
@onready var stamina_comp: StaminaComponent = $"../StaminaComponent"

# Visuals
var weapon_pivot: Node2D
var weapon_sprite: Sprite2D
var hitbox_area: Hitbox
var hitbox_shape: CollisionShape2D

var current_prompt_target: Node2D = null
var attack_timer: float = 0.0

func _ready() -> void:
	_setup_visuals()
	_setup_hitbox()

func _process(delta: float) -> void:
	_update_weapon_visuals()
	_check_stealth_takedown()
	
	if attack_timer > 0:
		attack_timer -= delta

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		attack()

func _setup_visuals() -> void:
	weapon_pivot = Node2D.new()
	weapon_pivot.name = "WeaponPivot"
	weapon_pivot.position = Vector2(0, -10)
	player.call_deferred("add_child", weapon_pivot)
	
	weapon_sprite = Sprite2D.new()
	weapon_sprite.name = "WeaponSprite"
	weapon_sprite.centered = false
	weapon_sprite.offset = Vector2(0, -8)
	weapon_sprite.rotation_degrees = -45
	weapon_sprite.visible = false
	weapon_pivot.add_child(weapon_sprite)

func _setup_hitbox() -> void:
	hitbox_area = Hitbox.new()
	hitbox_area.name = "WeaponHitbox"
	# Typically set collision mask to enemies layers
	hitbox_area.collision_layer = 0
	hitbox_area.collision_mask = 4 # Assuming layer 3 is enemies, adjust as needed or use groups
	
	hitbox_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 35.0
	hitbox_shape.shape = circle
	hitbox_shape.position = Vector2(25, 0)
	hitbox_shape.disabled = true
	
	hitbox_area.add_child(hitbox_shape)
	weapon_pivot.add_child(hitbox_area)
	
	hitbox_area.area_entered.connect(_on_hitbox_entered)

func _update_weapon_visuals() -> void:
	if not is_instance_valid(weapon_pivot): return
	
	var last_dir = player.get("last_dir")
	match last_dir:
		"down": weapon_pivot.rotation_degrees = 90
		"up": weapon_pivot.rotation_degrees = -90
		"left": weapon_pivot.rotation_degrees = 180
		"right": weapon_pivot.rotation_degrees = 0
		
	if last_dir == "up":
		weapon_pivot.z_index = -1
	else:
		weapon_pivot.z_index = 0

func equip_weapon(weapon_data: WeaponData) -> void:
	player.set("equipped_weapon", weapon_data)
	if weapon_sprite and weapon_data.icon:
		weapon_sprite.texture = weapon_data.icon
		weapon_sprite.visible = true
		
		if weapon_data.name == "Hammer" or weapon_data.name == "Sledgehammer" or weapon_data.name == "War Hammer":
			weapon_sprite.modulate = Color(0.8, 0.8, 0.8)
			weapon_sprite.offset = Vector2(-16, -120)
			weapon_sprite.rotation_degrees = 0
		else:
			weapon_sprite.modulate = Color.WHITE
			weapon_sprite.offset = Vector2(8, -14)
			weapon_sprite.rotation_degrees = -45

func attack() -> void:
	var equipped = player.get("equipped_weapon")
	if not equipped: return
	if stamina_comp and stamina_comp.current_stamina < 15.0: return
	if attack_timer > 0: return
		
	if stamina_comp:
		stamina_comp.use_stamina(15.0)
		
	attack_timer = 0.4
	
	if weapon_sprite:
		var tween = create_tween()
		tween.tween_property(weapon_sprite, "rotation_degrees", 45, 0.1)
		tween.tween_property(weapon_sprite, "rotation_degrees", -45, 0.2)
		
	# Attack lunge
	var lunge_dir = Vector2.ZERO
	match player.get("last_dir"):
		"down": lunge_dir = Vector2.DOWN
		"up": lunge_dir = Vector2.UP
		"left": lunge_dir = Vector2.LEFT
		"right": lunge_dir = Vector2.RIGHT
	
	if lunge_dir != Vector2.ZERO:
		var lunge_tween = create_tween()
		lunge_tween.tween_property(player, "global_position", player.global_position + (lunge_dir * 15.0), 0.1)
	
	# Enable hitbox briefly
	hitbox_area.damage_data = equipped.damage_data.copy()
	hitbox_area.damage_data.source = player
	
	hitbox_shape.disabled = false
	await get_tree().create_timer(0.2).timeout
	hitbox_shape.disabled = true

func _on_hitbox_entered(area: Area2D) -> void:
	if area is Hurtbox:
		hitbox_area.apply_damage(area)
		_apply_hitstop()
		_apply_camera_shake()

func _apply_hitstop() -> void:
	Engine.time_scale = 0.1
	# Use ignore_time_scale = true so the timer isn't affected by the slowed time
	await get_tree().create_timer(0.05, true, false, true).timeout
	Engine.time_scale = 1.0

func _apply_camera_shake() -> void:
	var cam = get_viewport().get_camera_2d()
	if cam:
		var shake_tween = create_tween()
		shake_tween.tween_property(cam, "offset", Vector2(randf_range(-6, 6), randf_range(-6, 6)), 0.03)
		shake_tween.tween_property(cam, "offset", Vector2(randf_range(-6, 6), randf_range(-6, 6)), 0.03)
		shake_tween.tween_property(cam, "offset", Vector2.ZERO, 0.03)

func _check_stealth_takedown() -> void:
	if not interact_area: return
	var bodies = interact_area.get_overlapping_bodies()
	var new_target = null
	
	for b in bodies:
		if b.is_in_group("enemies") and b.has_method("knockout") and b.get_node_or_null("EnemyAI"):
			var ai = b.get_node("EnemyAI")
			if ai.current_state == 0 or ai.current_state == 4: # IDLE or SEARCH
				var enemy_facing = ai.facing_direction
				
				var dir_to_player = (player.global_position - b.global_position).normalized()
				if enemy_facing.dot(dir_to_player) < -0.5:
					new_target = b
					break
	
	if new_target != current_prompt_target:
		if current_prompt_target and current_prompt_target.has_method("hide_prompt"):
			current_prompt_target.hide_prompt()
		if new_target and new_target.has_method("show_prompt"):
			new_target.show_prompt()
		current_prompt_target = new_target
	else:
		if current_prompt_target and current_prompt_target.has_method("show_prompt"):
			current_prompt_target.show_prompt()

	if current_prompt_target:
		if Input.is_action_just_pressed("Interact"):
			current_prompt_target.knockout()
			current_prompt_target.hide_prompt()
			current_prompt_target = null
			if player.has_method("show_hint"):
				player.show_hint("Takedown!")
