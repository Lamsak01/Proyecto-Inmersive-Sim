extends CharacterBody2D

@export var dialogue_manager: Node
@export var hint_label: Label
@export var speed := 120.0
@export var weight: float = 50.0

@onready var interact_area: Area2D = $InteractArea
@onready var anim: AnimatedSprite2D = $Animations
@onready var grid_inventory: GridInventory = $GridInventory

# Components
@onready var health_comp: HealthComponent = $HealthComponent
@onready var stun_comp: StunComponent = $StunComponent
@onready var armor_comp: ArmorComponent = $ArmorComponent
@onready var equipment_comp: EquipmentComponent = $EquipmentComponent
@onready var hurtbox: Hurtbox = $Hurtbox

var last_dir := "down"
var keys: Array[String] = []
var inventory: Inventory
var equipped_weapon: WeaponData

# Status variables for controllers
var is_weak: bool = false
var is_stunned_flag: bool = false

func _ready() -> void:
	add_to_group("player")
	
	if hint_label:
		hint_label.text = ""
	
	inventory = Inventory.new()
	inventory.name = "Inventory"
	add_child(inventory)
	
	health_comp.died.connect(_on_died)
	health_comp.weakness_changed.connect(_on_weakness_changed)
	stun_comp.stunned.connect(_on_stunned)
	
	if hurtbox:
		hurtbox.hit_received.connect(take_damage)
	
	GameState.restore_player_state(self)

func _process(_delta: float) -> void:
	_handle_interactions()

func _handle_interactions() -> void:
	if dialogue_manager and dialogue_manager.call("is_active"):
		return

	if Input.is_action_just_pressed("Interact"):
		var overlaps := interact_area.get_overlapping_areas()
		for a in overlaps:
			if a.is_in_group("interactable"):
				if a.has_method("interact"):
					a.interact(self)
					return
				elif a.get_parent().has_method("interact"):
					a.get_parent().interact(self)
					return

func show_hint(_text: String) -> void:
	pass

func add_key(id: String) -> void:
	if not keys.has(id):
		keys.append(id)

func has_key(id: String) -> bool:
	return keys.has(id)

func has_item(item_name: String) -> bool:
	return inventory.has_item(item_name)

func add_item(item_name: String) -> void:
	inventory.add_item(item_name)

func add_inventory_item(item: InventoryItem) -> void:
	if item == null: return
	if grid_inventory:
		for y in range(grid_inventory.height):
			for x in range(grid_inventory.width):
				if grid_inventory.try_place_item(item, Vector2i(x, y)):
					return

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var slot_index = event.keycode - KEY_0
			_try_equip_quick_slot(slot_index)

	if event.is_action_pressed("Interact"):
		_handle_interactions()

func _try_equip_quick_slot(index: int) -> void:
	if not grid_inventory: return
	var item_instance = grid_inventory.get_quick_slot(index)
	var combat_ctrl = get_node_or_null("PlayerCombatController")
	
	if item_instance:
		var item_name = item_instance["item"].name
		if item_name == "Iron Sword":
			if combat_ctrl: combat_ctrl.equip_weapon(load("res://resources/weapons/Sword.tres"))
		elif item_name == "Sledgehammer" or item_name == "War Hammer":
			if combat_ctrl: combat_ctrl.equip_weapon(load("res://resources/weapons/Hammer.tres"))
		elif item_name == "Health Potion":
			if health_comp.current_health < health_comp.max_health:
				health_comp.heal(25.0)
				grid_inventory.remove_item(item_instance)
	else:
		if index == 1 and inventory.has_item("Sword"):
			if combat_ctrl: combat_ctrl.equip_weapon(load("res://resources/weapons/Sword.tres"))
		elif index == 2 and inventory.has_item("Hammer"):
			if combat_ctrl: combat_ctrl.equip_weapon(load("res://resources/weapons/Hammer.tres"))

func _on_died() -> void:
	set_physics_process(false)
	var move_ctrl = get_node_or_null("PlayerMovementController")
	if move_ctrl: move_ctrl.set_physics_process(false)
	var combat_ctrl = get_node_or_null("PlayerCombatController")
	if combat_ctrl: combat_ctrl.set_process(false)
	anim.stop()

func _on_weakness_changed(weak: bool) -> void:
	is_weak = weak

func _on_stunned(stunned: bool) -> void:
	is_stunned_flag = stunned
	if stunned:
		anim.stop()

func is_stunned() -> bool:
	return is_stunned_flag

func is_stealthing() -> bool:
	var move_ctrl = get_node_or_null("PlayerMovementController")
	if move_ctrl:
		return move_ctrl.is_stealthing
	return false

func take_damage(data: DamageData) -> void:
	var mitigated_data = armor_comp.calculate_mitigation(data)
	health_comp.take_damage(mitigated_data)
	stun_comp.take_damage(mitigated_data)
