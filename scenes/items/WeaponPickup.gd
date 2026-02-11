extends Area2D

@export var item_resource: InventoryItem
@export var weapon_name: String = "Sword" # Keep for compatibility or remove later
var player_in_range: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Auto-load resource if missing (for backward compatibility)
	if item_resource == null:
		if weapon_name == "Sword":
			item_resource = load("res://resources/items/iron_sword.tres")
		elif weapon_name == "Hammer":
			item_resource = load("res://resources/items/war_hammer.tres")
	
	# Update visual if resource is provided
	if item_resource and has_node("Sprite2D"):
		$Sprite2D.texture = item_resource.texture

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("Interact"): # 'E' Key
		if player_in_range.has_method("add_inventory_item") and item_resource != null:
			# Prefer new method
			player_in_range.add_inventory_item(item_resource)
			print("Picked up: ", item_resource.name if item_resource else weapon_name)
			
			# Quest Progress
			if ObjectiveManager:
				var obj_id = item_resource.name if item_resource else weapon_name
				ObjectiveManager.progress_objective(1, obj_id, 1) # 1 = COLLECT
				
			queue_free()
		elif player_in_range.has_method("add_item"):
			# Fallback
			player_in_range.add_item(weapon_name)
			print("Picked up: ", weapon_name)
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = body
		print("Press 'E' to pick up ", weapon_name)

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
