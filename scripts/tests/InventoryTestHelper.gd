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

func _create_colored_texture(width: int, height: int, color: Color) -> ImageTexture:
	# Keep this function in case we need it later
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
