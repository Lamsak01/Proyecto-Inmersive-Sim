extends Node
class_name PlayerCombatController

@onready var player: CharacterBody2D = get_parent()
@onready var interact_area: Area2D = $"../InteractArea"
@onready var stamina_comp: StaminaComponent = $"../StaminaComponent"

# Visuals
var weapon_pivot: Node2D
var weapon_sprite: Sprite2D
var crosshair: Crosshair2D
var hitbox_area: Hitbox
var hitbox_shape: CollisionShape2D

var current_prompt_target: Node2D = null
var attack_timer: float = 0.0
var _takedown_check_timer: float = 0.0
var current_aim_dir: Vector2 = Vector2.RIGHT

# Sistema de Tensión del Arco (Hold-to-Draw)
var is_drawing_bow: bool = false
var bow_tension: float = 0.0
const BOW_DRAW_DURATION: float = 0.85

func _ready() -> void:
	_setup_visuals()
	_setup_hitbox()

func _process(delta: float) -> void:
	_update_weapon_visuals()
	
	if is_drawing_bow:
		var equipped: WeaponData = player.equipped_weapon
		if not equipped or not equipped.is_ranged:
			_cancel_bow_draw()
		else:
			bow_tension = clampf(bow_tension + (delta / BOW_DRAW_DURATION), 0.0, 1.0)
			if stamina_comp:
				stamina_comp.use_stamina(6.0 * delta)
				if stamina_comp.current_stamina <= 0.5:
					_release_bow_shot()
			if is_drawing_bow:
				if weapon_sprite:
					weapon_sprite.visible = true
					weapon_sprite.rotation_degrees = 0
					weapon_sprite.offset = Vector2(lerpf(6.0, 3.2, bow_tension), -10)
				if crosshair:
					crosshair.is_drawing_bow = true
					crosshair.bow_tension = bow_tension
				# Si el jugador soltó el botón fuera de foco, disparar igualmente
				if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_action_pressed("ui_accept"):
					_release_bow_shot()

	if _takedown_check_timer > 0.0:
		_takedown_check_timer -= delta
	else:
		_takedown_check_timer = 0.08
		_check_stealth_takedown()
	
	if attack_timer > 0.0:
		attack_timer -= delta

func _unhandled_input(event: InputEvent) -> void:
	var dm = player.get("dialogue_manager") if player else null
	if dm and dm.has_method("is_active") and dm.call("is_active"):
		if is_drawing_bow:
			_cancel_bow_draw()
		return

	# Si hay un objetivo válido de Sigilo por la Espalda (Civil o Enemigo):
	# - Opción NO LETAL (Aturdir): [E] (Interact) o [Q]
	# - Opción LETAL (Asesinar): [Clic Izq.], [ui_accept] o [V]
	if is_instance_valid(current_prompt_target):
		var is_non_lethal_key: bool = event.is_action_pressed("Interact") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_Q)
		var is_lethal_key: bool = event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_V)
		if is_non_lethal_key:
			_execute_stealth_takedown(current_prompt_target, false)
			get_viewport().set_input_as_handled()
			return
		elif is_lethal_key:
			_execute_stealth_takedown(current_prompt_target, true)
			get_viewport().set_input_as_handled()
			return

	var equipped: WeaponData = player.equipped_weapon
	var is_bow: bool = equipped != null and equipped.is_ranged

	if is_bow:
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or event.is_action("ui_accept"):
			if event.is_pressed() and not event.is_echo():
				_start_bow_draw()
			elif not event.is_pressed() and is_drawing_bow:
				_release_bow_shot()
			return

	if event.is_action_pressed("ui_accept"):
		attack(false)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		attack(true)

func _execute_stealth_takedown(target: Node2D, lethal: bool) -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("hide_prompt"):
		target.hide_prompt()
	current_prompt_target = null

	if lethal:
		if target.has_method("stealth_assassinate"):
			target.call("stealth_assassinate", player)
		elif target.has_method("take_damage"):
			var kill_dmg := DamageData.new()
			kill_dmg.amount = 999.0
			kill_dmg.type = CombatConstants.DamageType.CUT
			kill_dmg.source = player
			target.call("take_damage", kill_dmg)
			if player and player.has_method("show_hint"):
				player.show_hint("🗡️ ¡Eliminación letal en sigilo!")
	else:
		if target.has_method("stealth_knockout"):
			target.call("stealth_knockout", player)
		elif target.has_method("knockout"):
			target.call("knockout")
			if player and player.has_method("show_hint"):
				player.show_hint("💤 ¡Derribo no letal en sigilo!")
	_apply_hitstop()
	_apply_camera_shake()

func _setup_visuals() -> void:
	weapon_pivot = Node2D.new()
	weapon_pivot.name = "WeaponPivot"
	weapon_pivot.position = Vector2(0, -10)
	player.call_deferred("add_child", weapon_pivot)
	
	# Punto de mira dinámico en el cursor (estilo Enter the Gungeon / Zero Sievert)
	crosshair = Crosshair2D.new()
	crosshair.name = "Crosshair2D"
	crosshair.player = player
	player.call_deferred("add_child", crosshair)

	weapon_sprite = Sprite2D.new()
	weapon_sprite.name = "WeaponSprite"
	weapon_sprite.centered = false
	weapon_sprite.offset = Vector2(6, -10)
	weapon_sprite.rotation_degrees = -45
	weapon_sprite.visible = false
	weapon_pivot.add_child(weapon_sprite)

func _setup_hitbox() -> void:
	hitbox_area = Hitbox.new()
	hitbox_area.name = "WeaponHitbox"
	hitbox_area.collision_layer = 0
	hitbox_area.collision_mask = 5 # Layers 1 (destructibles/environment) + 3 (enemies/hurtboxes)
	
	hitbox_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 30.0
	hitbox_shape.shape = circle
	hitbox_shape.position = Vector2(22, 0)
	hitbox_shape.disabled = true
	
	hitbox_area.add_child(hitbox_shape)
	weapon_pivot.add_child(hitbox_area)
	
	hitbox_area.area_entered.connect(_on_hitbox_entered)
	hitbox_area.body_entered.connect(_on_hitbox_body_entered)

func _update_weapon_visuals() -> void:
	if not is_instance_valid(weapon_pivot) or not is_instance_valid(player):
		return
	
	# Apuntado 360° continuo hacia el Punto de Mira
	var pivot_global := player.global_position + Vector2(0, -10)
	var aim_pos := crosshair.get_aim_world_position() if is_instance_valid(crosshair) else player.get_global_mouse_position()
	var diff := aim_pos - pivot_global
	if diff.length_squared() > 4.0:
		current_aim_dir = diff.normalized()
	
	weapon_pivot.rotation = current_aim_dir.angle()
	weapon_pivot.z_index = -1 if current_aim_dir.y < -0.35 else 1

func equip_weapon(weapon_data: WeaponData) -> void:
	if is_drawing_bow:
		_cancel_bow_draw()
	player.equipped_weapon = weapon_data
	if weapon_sprite and weapon_data and weapon_data.icon:
		weapon_sprite.texture = weapon_data.icon
		weapon_sprite.modulate = Color.WHITE
		weapon_sprite.scale = Vector2(1.0, 1.0)
		weapon_sprite.offset = Vector2(6, -10)
		weapon_sprite.rotation_degrees = 0 if weapon_data.is_ranged else -45
		weapon_sprite.visible = false

	if crosshair and weapon_data:
		crosshair.is_ranged_mode = weapon_data.is_ranged
		crosshair.is_drawing_bow = false
		crosshair.bow_tension = 0.0

func _start_bow_draw() -> void:
	var equipped: WeaponData = player.equipped_weapon
	if not equipped or not equipped.is_ranged:
		return
	if attack_timer > 0.0:
		return
	if stamina_comp and stamina_comp.current_stamina < 6.0:
		return

	is_drawing_bow = true
	bow_tension = 0.05
	if weapon_sprite:
		weapon_sprite.visible = true
		weapon_sprite.rotation_degrees = 0
		weapon_sprite.offset = Vector2(6, -10)
	if crosshair:
		crosshair.is_drawing_bow = true
		crosshair.bow_tension = bow_tension

func _cancel_bow_draw() -> void:
	is_drawing_bow = false
	bow_tension = 0.0
	if weapon_sprite:
		weapon_sprite.offset = Vector2(6, -10)
		weapon_sprite.visible = false
	if crosshair:
		crosshair.is_drawing_bow = false
		crosshair.bow_tension = 0.0

func _release_bow_shot() -> void:
	if not is_drawing_bow:
		return
	var equipped: WeaponData = player.equipped_weapon
	var final_tension: float = clampf(bow_tension, 0.12, 1.0)
	is_drawing_bow = false
	bow_tension = 0.0

	if crosshair:
		crosshair.is_drawing_bow = false
		crosshair.bow_tension = 0.0
		crosshair.add_recoil(lerpf(2.5, 5.5, final_tension))

	if not equipped or not equipped.is_ranged:
		if weapon_sprite:
			weapon_sprite.visible = false
		return

	if stamina_comp:
		stamina_comp.use_stamina(4.0)

	attack_timer = 0.25
	var pivot_global := player.global_position + Vector2(0, -10)
	var aim_pos := crosshair.get_aim_world_position() if is_instance_valid(crosshair) else player.get_global_mouse_position()
	var diff := aim_pos - pivot_global
	if diff.length_squared() > 4.0:
		current_aim_dir = diff.normalized()
		weapon_pivot.rotation = current_aim_dir.angle()

	_fire_bow(equipped, final_tension)

func attack(_aim_with_mouse: bool = true) -> void:
	var equipped: WeaponData = player.equipped_weapon
	if not equipped: return
	var stam_cost: float = 10.0 if equipped.is_ranged else 14.0
	if stamina_comp and stamina_comp.current_stamina < stam_cost: return
	if attack_timer > 0.0: return
		
	if stamina_comp:
		stamina_comp.use_stamina(stam_cost)
		
	attack_timer = 0.36
	if crosshair:
		crosshair.add_recoil(4.5)
	
	# Actualizar dirección exacta hacia el punto de mira en el instante del ataque
	var pivot_global := player.global_position + Vector2(0, -10)
	var aim_pos := crosshair.get_aim_world_position() if is_instance_valid(crosshair) else player.get_global_mouse_position()
	var diff := aim_pos - pivot_global
	if diff.length_squared() > 4.0:
		current_aim_dir = diff.normalized()
		weapon_pivot.rotation = current_aim_dir.angle()

	if equipped.is_ranged:
		_fire_bow(equipped, 0.5)
		return

	if weapon_sprite:
		weapon_sprite.visible = true
		weapon_sprite.rotation_degrees = -45
		var tween = create_tween()
		tween.tween_property(weapon_sprite, "rotation_degrees", 45, 0.12)
		tween.tween_property(weapon_sprite, "rotation_degrees", -45, 0.12)
		tween.tween_callback(func():
			if is_instance_valid(weapon_sprite):
				weapon_sprite.visible = false
		)
	
	# Enable hitbox briefly in the exact 360° mouse aim direction
	hitbox_area.damage_data = equipped.damage_data.copy()
	if "paralytic_venom_timer" in player and float(player.get("paralytic_venom_timer")) > 0.0:
		hitbox_area.damage_data.stun_buildup += 50.0
	hitbox_area.damage_data.source = player
	
	hitbox_shape.disabled = false
	await get_tree().create_timer(0.18).timeout
	if is_instance_valid(hitbox_shape):
		hitbox_shape.disabled = true

func _fire_bow(equipped: WeaponData, tension: float = 1.0) -> void:
	var shoot_dir := current_aim_dir
	var pivot_global := player.global_position + Vector2(0, -10)

	if weapon_sprite:
		weapon_sprite.visible = true
		weapon_sprite.rotation_degrees = 0
		weapon_sprite.offset = Vector2(6, -10)
		get_tree().create_timer(0.16).timeout.connect(func():
			if is_instance_valid(weapon_sprite) and not is_drawing_bow:
				weapon_sprite.visible = false
		)

	var arrow := ArrowProjectile.new()
	arrow.global_position = pivot_global + shoot_dir * 12.0
	arrow.direction = shoot_dir
	# El alcance y la velocidad dependen directamente de cuánto tensaste el arco (hasta el doble de largo: 330 px)
	arrow.max_range = lerpf(55.0, 330.0, tension)
	arrow.speed = lerpf(190.0, 380.0, tension)
	arrow.shooter = player
	arrow.damage_data = equipped.damage_data.copy()
	arrow.damage_data.amount = equipped.damage_data.amount * lerpf(0.55, 1.4, tension)
	if "paralytic_venom_timer" in player and float(player.get("paralytic_venom_timer")) > 0.0:
		arrow.damage_data.stun_buildup += 50.0
	arrow.damage_data.source = player
	player.get_tree().current_scene.add_child(arrow)

func _on_hitbox_entered(area: Area2D) -> void:
	if area is Hurtbox:
		hitbox_area.apply_damage(area)
		_apply_hitstop()
		_apply_camera_shake()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body != player and (body.is_in_group("destructible") or body.is_in_group("wild_animals")) and body.has_method("take_damage"):
		body.take_damage(hitbox_area.damage_data)
		_apply_hitstop()
		_apply_camera_shake()

func _apply_hitstop() -> void:
	Engine.time_scale = 0.1
	await get_tree().create_timer(0.05, true, false, true).timeout
	Engine.time_scale = 1.0

func _apply_camera_shake() -> void:
	var cam = get_viewport().get_camera_2d()
	if cam:
		var shake_tween = create_tween()
		shake_tween.tween_property(cam, "position", Vector2(randf_range(-4, 4), randf_range(-4, 4)), 0.03)
		shake_tween.tween_property(cam, "position", Vector2(randf_range(-4, 4), randf_range(-4, 4)), 0.03)
		shake_tween.tween_property(cam, "position", Vector2.ZERO, 0.03)

func _check_stealth_takedown() -> void:
	if not interact_area or not is_instance_valid(player):
		return
	var new_target: Node2D = null

	# 1. Comprobar civiles / NPCs de la aldea cuando el jugador va en Sigilo ([C]) por su espalda
	if player.has_method("is_stealthing") and bool(player.call("is_stealthing")):
		var best_dist_sq: float = 29.0 * 29.0
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is Node2D and n.has_method("can_be_stealth_targeted"):
				var npc_node := n as Node2D
				if bool(npc_node.call("can_be_stealth_targeted", player)):
					var d2: float = player.global_position.distance_squared_to(npc_node.global_position)
					if d2 <= best_dist_sq:
						best_dist_sq = d2
						new_target = npc_node

	# 2. Comprobar enemigos de bosque (EnemyAI) por la espalda
	if new_target == null:
		var bodies = interact_area.get_overlapping_bodies()
		for b in bodies:
			if b.is_in_group("enemies") and b.has_method("knockout") and b.get_node_or_null("EnemyAI"):
				if b.get("is_stunned_flag") == true:
					continue
				var ai = b.get_node("EnemyAI")
				if ai.current_state == EnemyAI.State.IDLE or ai.current_state == EnemyAI.State.SEARCH:
					var enemy_facing = ai.facing_direction
					var dir_to_player = (player.global_position - b.global_position).normalized()
					if enemy_facing.dot(dir_to_player) < -0.5:
						new_target = b
						break

	if new_target != current_prompt_target:
		if is_instance_valid(current_prompt_target) and current_prompt_target.has_method("hide_prompt"):
			current_prompt_target.hide_prompt()
		if is_instance_valid(new_target) and new_target.has_method("show_prompt"):
			new_target.show_prompt()
		current_prompt_target = new_target
