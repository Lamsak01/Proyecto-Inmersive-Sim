class_name InventoryUI
extends Control

@export var grid_inventory: GridInventory
@export var cell_size: int = 32

var grid_container: Control
var item_uis: Dictionary = {}  # Maps item_instance to InventoryItemUI

func _ready() -> void:
	if grid_inventory == null:
		push_error("GridInventory not assigned to InventoryUI!")
		return
	
	_setup_grid()
	
	# Connect to inventory signals
	grid_inventory.item_placed.connect(_on_item_placed)
	grid_inventory.item_removed.connect(_on_item_removed)
	
	# Initially hide the inventory
	visible = false
	
	# Update position when visibility changes
	visibility_changed.connect(_update_grid_position)

func _update_grid_position() -> void:
	# Force InventoryUI to fill the screen so we catch drag events everywhere
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	if grid_container == null:
		return
	
	var viewport_size = get_viewport_rect().size
	var grid_size = Vector2(
		grid_inventory.width * cell_size,
		grid_inventory.height * cell_size
	)
	grid_container.position = (viewport_size - grid_size) / 2.0
	
	# Debug Sizes
	print("InventoryUI Debug: Viewport: ", viewport_size, " | GridContainer Pos: ", grid_container.position, " | My Size: ", size, " | Parent Size: ", get_parent().size if get_parent() is Control else "N/A")
	
	queue_redraw()

func _setup_grid() -> void:
	grid_container = Control.new()
	grid_container.name = "GridContainer"
	grid_container.mouse_filter = Control.MOUSE_FILTER_IGNORE # Let events pass to InventoryUI
	add_child(grid_container)
	
	# Set size based on grid dimensions
	var grid_size = Vector2(
		grid_inventory.width * cell_size,
		grid_inventory.height * cell_size
	)
	grid_container.custom_minimum_size = grid_size
	grid_container.size = grid_size
	
	# Center the grid on viewport
	var viewport_size = get_viewport_rect().size
	grid_container.position = (viewport_size - grid_size) / 2.0

func _draw() -> void:
	if grid_inventory == null or grid_container == null:
		return
	
	var offset = grid_container.position
	print("InventoryUI _draw called. Offset: ", offset, " Visible: ", visible)
	
	# Draw grid background
	var grid_rect = Rect2(offset, Vector2(
		grid_inventory.width * cell_size,
		grid_inventory.height * cell_size
	))
	draw_rect(grid_rect, Color(0.1, 0.1, 0.1, 0.9))
	
	# Draw grid lines
	for x in range(grid_inventory.width + 1):
		var start = Vector2(x * cell_size, 0) + offset
		var end = Vector2(x * cell_size, grid_inventory.height * cell_size) + offset
		draw_line(start, end, Color(0.3, 0.3, 0.3), 1.0)
	
	for y in range(grid_inventory.height + 1):
		var start = Vector2(0, y * cell_size) + offset
		var end = Vector2(grid_inventory.width * cell_size, y * cell_size) + offset
		draw_line(start, end, Color(0.3, 0.3, 0.3), 1.0)

func _on_item_placed(item: InventoryItem, grid_pos: Vector2i) -> void:
	# Find the item instance
	var item_instance = null
	for instance in grid_inventory.placed_items.values():
		if instance["item"] == item and instance["position"] == grid_pos:
			item_instance = instance
			break
	
	if item_instance == null:
		return
	
	# Create UI for the item
	var item_ui = preload("res://scripts/ui/InventoryItemUI.gd").new()
	item_ui.setup(item, item_instance, self)
	grid_container.add_child(item_ui)
	
	# Position the item UI
	var ui_position = Vector2(grid_pos.x * cell_size, grid_pos.y * cell_size)
	item_ui.position = ui_position
	
	item_uis[item_instance] = item_ui
	queue_redraw()

func _on_item_removed(item: InventoryItem) -> void:
	# Find and remove the UI
	var to_remove = []
	for instance in item_uis.keys():
		if item_uis[instance].item_data == item:
			to_remove.append(instance)
	
	for instance in to_remove:
		if item_uis.has(instance):
			item_uis[instance].queue_free()
			item_uis.erase(instance)
	
	queue_redraw()

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# print("Can drop data check...") # Verbose debug
	if not (data is Dictionary and data.has("item_instance")):
		return false
	
	var item_instance = data["item_instance"]
	var item: InventoryItem = item_instance["item"]
	var rotated: bool = item_instance.get("rotated", false)
	
	# Calculate grid position relative to the grid container
	# We also need to account for where *inside* the item we clicked (drag_offset)
	# so that the item's top-left corner snaps to the grid, not the mouse cursor.
	var drag_offset = Vector2.ZERO
	if data.has("drag_offset"):
		drag_offset = data["drag_offset"]
		
	var local_pos = at_position - grid_container.position - drag_offset
	var grid_pos = Vector2i(
		floor(local_pos.x / cell_size), # Use floor for correct top-left alignment
		floor(local_pos.y / cell_size)
	)
	
	# Temporarily remove the item if it's already in this inventory
	# Optimization: Don't remove/add, just check collision ignoring self
	var can_place = grid_inventory.can_place_item(item, grid_pos, rotated, item_instance)
	
	return can_place

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var item_instance = data["item_instance"]
	var item: InventoryItem = item_instance["item"]
	var rotated: bool = item_instance.get("rotated", false)
	
	# Calculate grid position relative to the grid container
	var drag_offset = Vector2.ZERO
	if data.has("drag_offset"):
		drag_offset = data["drag_offset"]
		
	var local_pos = at_position - grid_container.position - drag_offset
	var grid_pos = Vector2i(
		floor(local_pos.x / cell_size),
		floor(local_pos.y / cell_size)
	)
	
	# Remove from current position
	var removed = grid_inventory.remove_item(item_instance)
	print("Drop: Removed item first? ", removed)
	
	# Try to place at new position
	if grid_inventory.try_place_item(item, grid_pos, rotated):
		print("Drop: Placed successfully at ", grid_pos)
	else:
		print("Drop: Failed to place at ", grid_pos, ". Reverting to ", item_instance["position"])
		# If placement fails, try to put it back where it was
		grid_inventory.try_place_item(item, item_instance["position"], rotated)

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):  # ESC key
		visible = false
		get_viewport().set_input_as_handled()
		
	# Handle Quick Slot assignment (1-9)
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var slot_index = event.keycode - KEY_0
			var hovered_item = _get_hovered_item_ui()
			
			if hovered_item:
				print("Assigning slot ", slot_index, " to ", hovered_item.item_data.name)
				grid_inventory.assign_quick_slot(slot_index, hovered_item.item_instance)
				refresh_quick_slots()
				get_viewport().set_input_as_handled()

func _get_hovered_item_ui() -> InventoryItemUI:
	var mouse_pos = get_global_mouse_position()
	for item_ui in item_uis.values():
		if item_ui.get_global_rect().has_point(mouse_pos):
			return item_ui
	return null

func refresh_quick_slots() -> void:
	for item_ui in item_uis.values():
		item_ui._update_slot_display()
