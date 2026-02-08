extends CharacterBody2D

@export var dialogue_manager: Node
@export var hint_label: Label
@export var speed := 120.0
@onready var interact_area: Area2D = $InteractArea
@onready var anim: AnimatedSprite2D = $Animations

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



func _physics_process(_delta: float) -> void:
	
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

func _ready() -> void:
	if hint_label:
		hint_label.text = ""
	
	# Initialize Inventory
	inventory = Inventory.new()
	inventory.name = "Inventory"
	add_child(inventory)



#Proceso De Interactuar
func _process(_delta: float) -> void:
	# 1) Si el diálogo está activo, bloquea interacción con el mundo
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

	if hint_label:
		hint_label.text = "No hay nada cerca"
	await get_tree().create_timer(1.2).timeout
	if hint_label:
		hint_label.text = ""



func add_item(item_name: String) -> void:
	inventory.add_item(item_name)
	print("Inventario:", inventory.items)

func has_item(item_name: String) -> bool:
	return inventory.has_item(item_name)

func show_hint(text: String) -> void:
	if hint_label:
		hint_label.text = text
		
#LLaves Id		
func add_key(id: String) -> void:
	if not keys.has(id):
		keys.append(id)

func has_key(id: String) -> bool:
	return keys.has(id)
