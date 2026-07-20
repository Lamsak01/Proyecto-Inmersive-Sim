class_name InventoryItemUI
extends Control

var item_data: InventoryItem
var item_instance  # Reference to the instance in GridInventory
var inventory_ui: Control  # Reference to parent InventoryUI

var texture_rect: TextureRect
var slot_label: Label

func setup(item: InventoryItem, instance, ui: Control) -> void:
	item_data = item
	item_instance = instance
	inventory_ui = ui
	
	# Set size based on grid size
	var item_size = Vector2(item.grid_size.x * 32, item.grid_size.y * 32)
	custom_minimum_size = item_size
	size = item_size
	
	# Create TextureRect
	texture_rect = TextureRect.new()
	texture_rect.name = "TextureRect"
	texture_rect.texture = item.texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let parent handle mouse
	add_child(texture_rect)
	
	# Make TextureRect fill the entire control
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# texture_rect.size = item_size # Removed to avoid warning, anchors handle size
	
	# Create Slot Label
	slot_label = Label.new()
	slot_label.name = "SlotLabel"
	slot_label.text = ""
	slot_label.add_theme_color_override("font_color", Color.YELLOW)
	slot_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	slot_label.position = Vector2(2, 2)
	slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE # Important! Don't block clicks
	add_child(slot_label)
	
	# Ensure it's visible and on top
	texture_rect.visible = true
	texture_rect.z_index = 10
	visible = true
	z_index = 5
	
	# ENABLE MOUSE INPUT
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Check if already assigned
	_update_slot_display()

func _update_slot_display() -> void:
	if not inventory_ui or not inventory_ui.grid_inventory:
		return
		
	var quick_slots = inventory_ui.grid_inventory.quick_slots
	var found_slot = -1
	
	for slot in quick_slots.keys():
		if quick_slots[slot] == item_instance:
			found_slot = slot
			break
			
	if found_slot != -1:
		slot_label.text = str(found_slot)
	else:
		slot_label.text = ""


func _get_drag_data(at_position: Vector2) -> Variant:
	print("Starting drag for: ", item_data.name)
	
	# Create a container for the preview that will help with positioning
	# To fix the "giant" issue, we ensurei the size is explicitly set.
	var preview_texture = TextureRect.new()
	preview_texture.texture = item_data.texture
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_texture.size = size # Match the current item size
	preview_texture.modulate.a = 0.8
	
	# Create a control to hold the texture and offset it
	var preview_control = Control.new()
	preview_control.add_child(preview_texture)
	# Center the texture on the control so the mouse is in the middle
	preview_texture.position = -0.5 * size 
	
	set_drag_preview(preview_control)
	
	# Return the item instance and UI reference
	return {
		"item_instance": item_instance,
		"item_ui": self,
		"source_ui": inventory_ui,
		"drag_offset": at_position # Save where we clicked inside the item for grid snapping
	}

# Removed _can_drop_data and _drop_data to allow drag events to propagate to InventoryUI
