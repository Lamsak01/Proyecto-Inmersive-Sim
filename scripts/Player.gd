extends CharacterBody2D

@export var dialogue_manager: Node
@export var hint_label: Label
@export var speed := 120.0
@onready var interact_area: Area2D = $InteractArea
@onready var anim: AnimatedSprite2D = $Animations
@export var weight: float = 50.0
var last_dir := "down"
var keys: Array[String] = []
var inventory: Inventory

func _play_walk(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			anim.play("walk_right")
			last_dir = "right"
		else:
			anim.play("walk_left")
			last_dir = "left"
	else:
		if dir.y > 0:
			anim.play("walk_down")
			last_dir = "down"
		else:
			anim.play("walk_up")
			last_dir = "up"

func _play_idle() -> void:
	anim.play("idle_" + last_dir)



func _physics_process(delta: float) -> void:
	handle_sprint(delta)
	
	var input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

		
	if input != Vector2.ZERO:
		velocity = input.normalized() * speed
		_play_walk(input)
	else:
		velocity = Vector2.ZERO
		_play_idle()
	
	move_and_slide()
	
	# Push lighter objects
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		if collider is CharacterBody2D and "weight" in collider and collider.has_method("apply_push"):
			if weight > collider.weight:
				var push_dir = (collider.global_position - global_position).normalized()
				collider.apply_push(push_dir * 150) # Tuned push force

	_check_stealth_takedown()

var current_prompt_target: Node2D = null

func _check_stealth_takedown() -> void:
	var bodies = interact_area.get_overlapping_bodies()
	var new_target = null
	
	for b in bodies:
		if b.is_in_group("enemies") and b.has_method("knockout") and b.get_node_or_null("EnemyAI"):
			var ai = b.get_node("EnemyAI")
			# Check stealth conditions: Unaware + Behind
			if ai.current_state == 0 or ai.current_state == 4: # IDLE (0) or SEARCH (4) - assuming enum order
				# Check direction (Behind)
				# Enemy facing vector (approximate based on velocity or sprite)
				var enemy_facing = Vector2.DOWN
				if b.velocity.length() > 0:
					enemy_facing = b.velocity.normalized()
				
				var dir_to_player = (global_position - b.global_position).normalized()
				# If dot product is negative, player is behind (opposite to facing)
				if enemy_facing.dot(dir_to_player) < -0.5:
					new_target = b
					break
	
	# Handle Prompt Switching
	if new_target != current_prompt_target:
		if current_prompt_target and current_prompt_target.has_method("hide_prompt"):
			current_prompt_target.hide_prompt()
		
		if new_target and new_target.has_method("show_prompt"):
			new_target.show_prompt()
		
		current_prompt_target = new_target
	else:
		# If target is same, ensure prompt is visible (optional, mostly needed if new target wasn't set)
		if current_prompt_target and current_prompt_target.has_method("show_prompt"):
			current_prompt_target.show_prompt()

	# Input Handling
	if current_prompt_target:
		# show_hint("[E] Knockout") # Removed text hint in favor of overhead prompt
		if Input.is_action_just_pressed("Interact"): # 'interact' or 'Interact' check casing
			current_prompt_target.knockout()
			current_prompt_target.hide_prompt()
			current_prompt_target = null
			show_hint("Takedown!")
	else:
		pass
		# show_hint("")

func _ready() -> void:
	# Add to group for enemy detection
	add_to_group("player")
	
	if hint_label:
		hint_label.text = ""
	
	# Initialize Inventory
	inventory = Inventory.new()
	inventory.name = "Inventory"
	add_child(inventory)
	
	_ready_combat_components()
	_ready_visuals()



#Proceso Global
func _process(_delta: float) -> void:
	# 1) Visuals always update
	_update_weapon_visuals()
	
	# 2) Interactions
	_handle_interactions()

func _update_weapon_visuals() -> void:
	if weapon_pivot:
		match last_dir:
			"down": weapon_pivot.rotation_degrees = 90
			"up": weapon_pivot.rotation_degrees = -90
			"left": weapon_pivot.rotation_degrees = 180
			"right": weapon_pivot.rotation_degrees = 0
			
		# Z-Index sorting
		if last_dir == "up":
			weapon_pivot.z_index = -1
		else:
			weapon_pivot.z_index = 0

func _handle_interactions() -> void:
	# 1) Si el diálogo está activo, bloquea interacción
	if dialogue_manager and dialogue_manager.call("is_active"):
		return

	# 2) Solo interactúa cuando presionas la tecla
	if not Input.is_action_just_pressed("Interact"):
		return

	var overlaps := interact_area.get_overlapping_areas()
	for a in overlaps:
		if a.is_in_group("interactable") and a.has_method("interact"):
			a.interact(self)
			return

func show_hint(_text: String) -> void:
	pass

func add_key(id: String) -> void:
	if not keys.has(id):
		keys.append(id)

func has_key(id: String) -> bool:
	return keys.has(id)


# --- Systemic Combat Integration ---
@onready var health_comp: HealthComponent = HealthComponent.new()
@onready var stun_comp: StunComponent = StunComponent.new()
@onready var armor_comp: ArmorComponent = ArmorComponent.new()
@onready var equipment_comp: EquipmentComponent = EquipmentComponent.new()

func _ready_combat_components() -> void:
	health_comp.name = "HealthComponent"
	add_child(health_comp)
	
	stun_comp.name = "StunComponent"
	add_child(stun_comp)
	
	armor_comp.name = "ArmorComponent"
	add_child(armor_comp)
	
	equipment_comp.name = "EquipmentComponent"
	add_child(equipment_comp)
	
	setup_stamina()
	
	health_comp.died.connect(_on_died)
	health_comp.weakness_changed.connect(_on_weakness_changed)
	stun_comp.stunned.connect(_on_stunned)

# --- Stamina Integration ---
@onready var stamina_comp: StaminaComponent = StaminaComponent.new()
var is_sprinting: bool = false
var is_stealth_active: bool = false
var _c_pressed_last_frame: bool = false

func setup_stamina() -> void:
	stamina_comp.name = "StaminaComponent"
	add_child(stamina_comp)
	stamina_comp.exhausted.connect(_on_exhausted)

func _on_exhausted() -> void:
	is_sprinting = false
	speed = 120.0 # Reset to normal walk speed
	print("Stamina Exhausted!")

func handle_sprint(delta: float) -> void:
	var is_sprint_pressed = Input.is_action_pressed("sprint")
	stamina_comp.is_input_blocking = is_sprint_pressed
	
	# Stealth Input (Toggle C)
	if Input.is_key_pressed(KEY_C) and not _c_pressed_last_frame:
		is_stealth_active = !is_stealth_active
	_c_pressed_last_frame = Input.is_key_pressed(KEY_C)
	
	if is_stealth_active:
		is_sprinting = false
		speed = 60.0 # Stealth speed
		modulate.a = 0.6 # Ghostly visual
	else:
		modulate.a = 1.0 # Normal visual
		if is_sprint_pressed and velocity != Vector2.ZERO:
			if stamina_comp.use_stamina(stamina_comp.sprint_cost * delta):
				is_sprinting = true
				speed = 200.0 # Sprint speed
				anim.speed_scale = 1.5 # Faster animation
			else:
				is_sprinting = false
				speed = 120.0
				anim.speed_scale = 1.0
		else:
			is_sprinting = false
			speed = 120.0
			anim.speed_scale = 1.0
			
func is_stealthing() -> bool:
	return is_stealth_active
	
	# Debug/Verify Setup
	# verify_systemic_combat() # Removed to prevent infinite damage loop

var equipped_weapon: WeaponData

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_1:
			if inventory.has_item("Sword"):
				equip_weapon("Sword")
		if event.pressed and event.keycode == KEY_2:
			equip_weapon("Hammer")

	if event.is_action_pressed("ui_accept"): # Space bar by default
		attack()

# --- Visuals ---
var weapon_pivot: Node2D
var weapon_sprite: Sprite2D

func _ready_visuals() -> void:
	# Create nodes dynamically
	weapon_pivot = Node2D.new()
	weapon_pivot.name = "WeaponPivot"
	weapon_pivot.position = Vector2(0, -5) # Adjust based on character center
	add_child(weapon_pivot)
	
	weapon_sprite = Sprite2D.new()
	weapon_sprite.name = "WeaponSprite"
	weapon_sprite.centered = false
	weapon_sprite.offset = Vector2(0, -8) # Adjust pivot point
	weapon_sprite.rotation_degrees = -45 # Rest pose
	weapon_sprite.visible = false
	weapon_pivot.add_child(weapon_sprite)


func equip_weapon(weapon_name: String) -> void:
	if weapon_name == "Sword":
		equipped_weapon = load("res://resources/weapons/Sword.tres")
	elif weapon_name == "Hammer":
		equipped_weapon = load("res://resources/weapons/Hammer.tres")
		
	if equipped_weapon:
		print("Equipped: ", equipped_weapon.name)
		
		# Visual Update
		if weapon_sprite and equipped_weapon.icon:
			weapon_sprite.texture = equipped_weapon.icon
			weapon_sprite.visible = true
			
			# Color feedback requested by user
			if weapon_name == "Hammer":
				weapon_sprite.modulate = Color(0.2, 0.2, 1.0) # Blue for Hammer
			else:
				weapon_sprite.modulate = Color.WHITE # Normal for others

func attack() -> void:
	if not equipped_weapon: return
	if stamina_comp.current_stamina < 15.0: return
		
	stamina_comp.use_stamina(15.0)
	print("Attacking with ", equipped_weapon.name)
	
	# Swing Animation (Tween)
	if weapon_sprite:
		var tween = create_tween()
		tween.tween_property(weapon_sprite, "rotation_degrees", 45, 0.1) # Swing out
		tween.tween_property(weapon_sprite, "rotation_degrees", -45, 0.2) # Return
	
	# Detect enemies
	var bodies = interact_area.get_overlapping_bodies()
	for b in bodies:
		if b != self and b.has_method("take_damage"):
			# Directional Check
			var dir_to_target = (b.global_position - global_position).normalized()
			var facing_dir = Vector2.DOWN
			
			match last_dir:
				"up": facing_dir = Vector2.UP
				"down": facing_dir = Vector2.DOWN
				"left": facing_dir = Vector2.LEFT
				"right": facing_dir = Vector2.RIGHT
			
			# Dot product > 0.5 means within ~60 degrees cone in front
			if dir_to_target.dot(facing_dir) > 0.5:
				b.take_damage(equipped_weapon.damage_data)

func _on_died() -> void:
	print("Player Died!")
	set_physics_process(false)
	anim.stop()

func _on_weakness_changed(is_weak: bool) -> void:
	if is_weak:
		print("Player is Weak! Slowing down.")
		speed = 60.0
	else:
		print("Player recovered from weakness.")
		speed = 120.0

func _on_stunned(is_stunned: bool) -> void:
	if is_stunned:
		print("Player Stunned! Input locked.")
		set_physics_process(false)
		anim.stop()
	else:
		print("Player recovered from Stun.")
		set_physics_process(true)

func take_damage(data: DamageData) -> void:
	var mitigated_data = armor_comp.calculate_mitigation(data)
	health_comp.take_damage(mitigated_data)
	stun_comp.take_damage(mitigated_data)
	print("Took damage: ", mitigated_data.amount, " (Original: ", data.amount, ") | Blood: ", health_comp.current_blood)

func verify_systemic_combat() -> void:
	print("--- Verifying Player Combat System ---")
	armor_comp.equip(CombatConstants.ArmorSlot.BODY, CombatConstants.ArmorMaterial.METAL)
	print("Equipped Metal Armor on Body.")
	var dmg = DamageData.new()
	dmg.amount = 20.0
	dmg.type = CombatConstants.DamageType.CUT
	print("Simulating 20 CUT damage (vs Metal Armor)...")
	take_damage(dmg) 

func has_item(item_name: String) -> bool:
	return inventory.has_item(item_name)

func add_item(item_name: String) -> void:
	inventory.add_item(item_name)
	print("Inventario:", inventory.items)
