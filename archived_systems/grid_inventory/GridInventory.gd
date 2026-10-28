class_name GridInventory
extends Node

signal item_placed(item: InventoryItem, position: Vector2i)
signal item_removed(item: InventoryItem)

@export var width: int = 6
@export var height: int = 10

# Dictionary to store placed items: {item_instance: {item: InventoryItem, position: Vector2i, rotated: bool}}
var placed_items: Dictionary = {}
# 2D grid to track occupied cells
var grid: Array[Array] = []

func _ready() -> void:
	_initialize_grid()

func _initialize_grid() -> void:
	grid.clear()
	for y in range(height):
		var row: Array = []
		row.resize(width)
		for x in range(width):
			row[x] = null
		grid.append(row)

# Check if an item can be placed at the given position
func can_place_item(item: InventoryItem, position: Vector2i, rotated: bool = false, ignore_instance = null) -> bool:
	var size = item.grid_size if not rotated else Vector2i(item.grid_size.y, item.grid_size.x)
	
	# Check bounds
	if position.x < 0 or position.y < 0:
		return false
	if position.x + size.x > width or position.y + size.y > height:
		return false
	
	# Check collision with existing items
	for y in range(position.y, position.y + size.y):
		for x in range(position.x, position.x + size.x):
			var occupant = grid[y][x]
			if occupant != null:
				if ignore_instance != null and occupant == ignore_instance:
					continue # Ignore self
				return false
	
	return true

# Place an item in the inventory
func try_place_item(item: InventoryItem, position: Vector2i, rotated: bool = false) -> bool:
	if not can_place_item(item, position, rotated):
		return false
	
	var size = item.grid_size if not rotated else Vector2i(item.grid_size.y, item.grid_size.x)
	var item_instance = {
		"item": item,
		"position": position,
		"rotated": rotated
	}
	
	# Mark grid cells as occupied
	for y in range(position.y, position.y + size.y):
		for x in range(position.x, position.x + size.x):
			grid[y][x] = item_instance
	
	placed_items[item_instance] = item_instance
	item_placed.emit(item, position)
	return true

# Move an item in-place in the inventory
func move_item(item_instance, new_position: Vector2i, rotated: bool = false) -> bool:
	if not placed_items.has(item_instance):
		return false
	
	var item: InventoryItem = item_instance["item"]
	var old_position: Vector2i = item_instance["position"]
	var old_rotated: bool = item_instance["rotated"]
	
	# 1. Temporarily clear old cells
	var old_size = item.grid_size if not old_rotated else Vector2i(item.grid_size.y, item.grid_size.x)
	for y in range(old_position.y, old_position.y + old_size.y):
		for x in range(old_position.x, old_position.x + old_size.x):
			grid[y][x] = null
			
	# 2. Check if it can be placed at the new position (ignoring itself)
	if not can_place_item(item, new_position, rotated, item_instance):
		# Revert to old position
		for y in range(old_position.y, old_position.y + old_size.y):
			for x in range(old_position.x, old_position.x + old_size.x):
				grid[y][x] = item_instance
		return false
		
	# 3. Update the existing dictionary in-place
	item_instance["position"] = new_position
	item_instance["rotated"] = rotated
	
	# 4. Mark new grid cells as occupied
	var new_size = item.grid_size if not rotated else Vector2i(item.grid_size.y, item.grid_size.x)
	for y in range(new_position.y, new_position.y + new_size.y):
		for x in range(new_position.x, new_position.x + new_size.x):
			grid[y][x] = item_instance
			
	item_placed.emit(item, new_position)
	return true


# Remove an item from the inventory
func remove_item(item_instance) -> bool:
	if not placed_items.has(item_instance):
		return false
	
	var data = placed_items[item_instance]
	var item: InventoryItem = data["item"]
	var position: Vector2i = data["position"]
	var rotated: bool = data["rotated"]
	var size = item.grid_size if not rotated else Vector2i(item.grid_size.y, item.grid_size.x)
	
	# Clear grid cells
	for y in range(position.y, position.y + size.y):
		for x in range(position.x, position.x + size.x):
			grid[y][x] = null
	
	placed_items.erase(item_instance)
	remove_quick_slot_by_instance(item_instance)
	item_removed.emit(item)
	return true

# Get the item at a specific grid position
func get_item_at(position: Vector2i):
	if position.x < 0 or position.y < 0 or position.x >= width or position.y >= height:
		return null
	return grid[position.y][position.x]

func has_item_by_name(item_name: String) -> bool:
	for item_instance in placed_items.values():
		if item_instance["item"].name == item_name:
			return true
	return false

# Quick Slot System
var quick_slots: Dictionary = {} # { 1: item_instance, 2: item_instance, ... }

func assign_quick_slot(slot_index: int, item_instance) -> void:
	# Clear previous assignment for this slot
	quick_slots[slot_index] = item_instance
	print("Assigned slot ", slot_index, " to ", item_instance["item"].name)

func get_quick_slot(slot_index: int):
	return quick_slots.get(slot_index)

func remove_quick_slot_by_instance(item_instance) -> void:
	for slot in quick_slots.keys():
		if quick_slots[slot] == item_instance:
			quick_slots.erase(slot)

# Get all placed items
func get_all_items() -> Array:
	return placed_items.values()
