extends CharacterBody2D

@export var dialogue_manager: Node
@export var hint_label: Label
@export var speed := 120.0
@export var weight: float = 50.0

@onready var interact_area: Area2D = $InteractArea
@onready var anim: AnimatedSprite2D = $Animations

# Components
@onready var health_comp: HealthComponent = $HealthComponent
@onready var stun_comp: StunComponent = $StunComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var combat_ctrl: PlayerCombatController = get_node_or_null("PlayerCombatController")
@onready var move_ctrl: PlayerMovementController = get_node_or_null("PlayerMovementController")

const SWORD_WEAPON: WeaponData = preload("res://resources/weapons/Sword.tres")
const HAMMER_WEAPON: WeaponData = preload("res://resources/weapons/Hammer.tres")
const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

var last_dir := "down"
var equipped_weapon: WeaponData

# Status variables for controllers
var is_weak: bool = false
var is_stunned_flag: bool = false

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	
	if hint_label:
		hint_label.text = ""
	
	if health_comp:
		health_comp.died.connect(_on_died)
		health_comp.weakness_changed.connect(_on_weakness_changed)
		health_comp.bleed_triggered.connect(_on_bleed_triggered)
	if stun_comp:
		stun_comp.stunned.connect(_on_stunned)
	
	if hurtbox:
		hurtbox.hit_received.connect(take_damage)
	
	# Equip default weapon so combat works out of the box (1 = Sword, 2 = Hammer)
	call_deferred("equip_weapon", SWORD_WEAPON)

func equip_weapon(weapon_data: WeaponData) -> void:
	if not weapon_data:
		return
	equipped_weapon = weapon_data
	if not combat_ctrl:
		combat_ctrl = get_node_or_null("PlayerCombatController")
	if combat_ctrl and combat_ctrl.has_method("equip_weapon"):
		combat_ctrl.equip_weapon(weapon_data)

func _handle_interactions() -> void:
	if dialogue_manager and dialogue_manager.call("is_active"):
		return

	var overlaps := interact_area.get_overlapping_areas()
	for a in overlaps:
		if a.is_in_group("interactable"):
			if a.has_method("interact"):
				a.interact(self)
				get_viewport().set_input_as_handled()
				return
			elif a.get_parent().has_method("interact"):
				a.get_parent().interact(self)
				get_viewport().set_input_as_handled()
				return

func show_hint(text: String) -> void:
	if hint_label:
		hint_label.text = text
		get_tree().create_timer(3.0).timeout.connect(func(): 
			if hint_label and hint_label.text == text:
				hint_label.text = "")

func _unhandled_input(event: InputEvent) -> void:
	if dialogue_manager and dialogue_manager.has_method("is_active") and dialogue_manager.call("is_active"):
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			equip_weapon(SWORD_WEAPON)
			show_hint("Arma: Espada (Corte / Sangrado)")
		elif event.keycode == KEY_2:
			equip_weapon(HAMMER_WEAPON)
			show_hint("Arma: Martillo (Contundente / Stun)")
			
	if event.is_action_pressed("Interact"):
		_handle_interactions()

func _on_died() -> void:
	set_physics_process(false)
	if move_ctrl: move_ctrl.set_physics_process(false)
	if combat_ctrl: combat_ctrl.set_process(false)
	anim.stop()

func _on_weakness_changed(weak: bool) -> void:
	is_weak = weak

func _on_bleed_triggered(_dps: float) -> void:
	_spawn_floating_text("BLEEDING!", Color.CRIMSON, -34.0)

func _on_stunned(stunned: bool) -> void:
	is_stunned_flag = stunned
	if stunned:
		anim.stop()
		_spawn_floating_text("STUNNED!", Color.AQUA, -44.0)

func apply_push(force: Vector2) -> void:
	if not move_ctrl:
		move_ctrl = get_node_or_null("PlayerMovementController")
	if move_ctrl and move_ctrl.has_method("apply_impulse"):
		move_ctrl.apply_impulse(force)

func _spawn_floating_text(text: String, color: Color, offset_y: float = -36.0) -> void:
	if FloatingTextScene:
		var ft = FloatingTextScene.instantiate()
		ft.start_text = text
		ft.text_color = color
		ft.global_position = global_position + Vector2(0, offset_y)
		get_tree().current_scene.add_child(ft)

func is_stunned() -> bool:
	return is_stunned_flag

func is_stealthing() -> bool:
	if not move_ctrl:
		move_ctrl = get_node_or_null("PlayerMovementController")
	if move_ctrl:
		return move_ctrl.is_stealthing
	return false

func get_noise_multiplier() -> float:
	"""Devuelve el multiplicador de ruido actual según el movimiento (0 = silencio, 1 = caminar, 1.8 = correr)."""
	if velocity.length_squared() < 4.0:
		return 0.0
	if not move_ctrl:
		move_ctrl = get_node_or_null("PlayerMovementController")
	if move_ctrl:
		if move_ctrl.is_stealthing:
			return 0.0
		if move_ctrl.is_sprinting:
			return 1.8
	return 1.0

func take_damage(data: DamageData) -> void:
	if health_comp:
		health_comp.take_damage(data)
	if stun_comp:
		stun_comp.take_damage(data)
