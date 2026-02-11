extends Node
# Test script to populate the inventory with some sample items
# Attach this to the World node or any node that runs at startup

@export var grid_inventory: GridInventory

func _ready() -> void:
	if not grid_inventory:
		print("GridInventory not assigned to InventoryTestHelper!")
		return
	
	# Wait a frame for everything to initialize
	await get_tree().process_frame
	
	# Create test items
	_create_test_items()
	
	# Verify Power System
	_verify_power_system()

func _verify_power_system() -> void:
	await get_tree().process_frame
	await get_tree().process_frame # Wait for network recalc
	
	var generator = get_node_or_null("../PowerSystem/Generator")
	var door = get_node_or_null("../PowerSystem/PoweredDoor")
	
	if generator and door:
		print("Power System Verified:")
		print("- Generator Enabled: ", generator.enabled)
		print("- Door Powered: ", door.is_powered())
		
		# Test toggle
		print("Simulating Generator Toggle...")
		generator.enabled = !generator.enabled
		# Force update (or mark dirty)
		var pm = get_node_or_null("/root/PowerManager")
		if pm: pm.mark_dirty()
		
		await get_tree().process_frame
		await get_tree().process_frame
		
		print("- New Generator Enabled: ", generator.enabled)
		print("- New Door Powered: ", door.is_powered())
		
		if generator.enabled != door.is_powered():
			print("WARNING: Generator and Door state mismatch! Cable might be disconnected.")
		else:
			print("SUCCESS: Power state synced.")

func _create_test_items() -> void:
	# Load pre-created item resources
	var health_potion = load("res://resources/items/health_potion.tres") as InventoryItem
	var iron_sword = load("res://resources/items/iron_sword.tres") as InventoryItem
	var war_hammer = load("res://resources/items/war_hammer.tres") as InventoryItem
	var iron_shield = load("res://resources/items/iron_shield.tres") as InventoryItem
	
	# Try to place items in inventory
	if health_potion:
		grid_inventory.try_place_item(health_potion, Vector2i(0, 0))
	
	if iron_sword:
		grid_inventory.try_place_item(iron_sword, Vector2i(2, 0))
	
	if war_hammer:
		grid_inventory.try_place_item(war_hammer, Vector2i(4, 0))
	
	if iron_shield:
		grid_inventory.try_place_item(iron_shield, Vector2i(0, 4))
	
	print("Test items loaded from resources!")
	
	# Start Test Objective
	var objective = load("res://resources/objectives/obj_find_sword.tres")
	if objective:
		ObjectiveManager.add_objective(objective)
		
	# Connect to inventory to check for completion
	if grid_inventory:
		if not grid_inventory.item_placed.is_connected(_on_item_placed):
			grid_inventory.item_placed.connect(_on_item_placed)

func _on_item_placed(item: InventoryItem, _pos: Vector2i) -> void:
	if item.name == "Iron Sword": # Verify exact name in resource
		ObjectiveManager.complete_objective("obj_find_sword")
		print("Objective 'Find Sword' Completed!")

func _create_colored_texture(width: int, height: int, color: Color) -> ImageTexture:
	# Keep this function in case we need it later
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
