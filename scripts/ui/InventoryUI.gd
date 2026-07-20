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
	
	# Load any already existing items (e.g., restored by GameState)
	for item_instance in grid_inventory.placed_items.values():
		_on_item_placed(item_instance["item"], item_instance["position"])
		
	# Refresh UI for quick slots restored by GameState
	refresh_quick_slots()
		
	# Initially hide the inventory
	visible = false
	
	# Update position when visibility changes
	visibility_changed.connect(_update_grid_position)

func _exit_tree() -> void:
	cleanup_drag()

func cleanup_drag() -> void:
	if is_inside_tree():
		var vp = get_viewport()
		if vp and vp.gui_is_dragging():
			vp.gui_cancel_drag()
			print("InventoryUI: Cancelled active drag during cleanup to prevent memory leaks.")

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
	if not grid_inventory or not grid_container: return
	
	var offset = grid_container.position
	
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
	
	# If we already have a UI for this instance, just update its position and slot display
	if item_uis.has(item_instance):
		var item_ui = item_uis[item_instance]
		var is_rot = item_instance.get("rotated", false)
		var item_size = Vector2(item.grid_size.x * cell_size, item.grid_size.y * cell_size) if not is_rot else Vector2(item.grid_size.y * cell_size, item.grid_size.x * cell_size)
		item_ui.custom_minimum_size = item_size
		item_ui.size = item_size
		if item_ui.texture_rect:
			item_ui.texture_rect.size = item_size
		item_ui.position = Vector2(grid_pos.x * cell_size, grid_pos.y * cell_size)
		item_ui._update_slot_display()
		queue_redraw()
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
	# Find and remove the UI for the instance that is no longer in grid_inventory.placed_items
	var to_remove = []
	for instance in item_uis.keys():
		if not grid_inventory.placed_items.has(instance):
			to_remove.append(instance)
	
	for instance in to_remove:
		if item_uis.has(instance):
			item_uis[instance].queue_free()
			item_uis.erase(instance)
	
	queue_redraw()

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("item_instance")):
		return false
	
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
	
	var can_place = grid_inventory.can_place_item(item, grid_pos, rotated, item_instance)
	return can_place

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var item_instance = data["item_instance"]
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
	
	# Move the item in-place
	if grid_inventory.move_item(item_instance, grid_pos, rotated):
		print("Drop: Moved successfully to ", grid_pos)
	else:
		print("Drop: Failed to move to ", grid_pos)

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
