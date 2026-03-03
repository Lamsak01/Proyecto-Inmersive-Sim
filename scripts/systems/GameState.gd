extends Node
## Autoload singleton that persists inventory data across scene changes.
## Registered in project.godot as "GameState"

func _ready() -> void:
	print(">>> GameState Autoload READY <<<")

# Stored inventory items: Array of {resource_path, position, rotated}
var saved_inventory: Array[Dictionary] = []
var saved_quick_slots: Dictionary = {}
var saved_keys: Array[String] = []
var saved_equipped_weapon: String = ""
var next_spawn_direction: String = ""
var has_saved_data: bool = false

func save_player_state(player: Node) -> void:
	saved_inventory.clear()
	saved_quick_slots.clear()
	
	# Save GridInventory
	var grid_inv = player.get_node_or_null("GridInventory")
	if grid_inv and grid_inv is GridInventory:
		for item_instance in grid_inv.placed_items.values():
			var item: InventoryItem = item_instance["item"]
			var path = item.resource_path
			if path == "":
				print("GameState WARNING: Item '", item.name, "' has no resource_path, skipping!")
				continue
			saved_inventory.append({
				"resource_path": path,
				"position_x": item_instance["position"].x,
				"position_y": item_instance["position"].y,
				"rotated": item_instance["rotated"]
			})
			print("GameState: Saved item '", item.name, "' at ", item_instance["position"])
		
		# Save quick slots
		for slot_idx in grid_inv.quick_slots.keys():
			var qi = grid_inv.quick_slots[slot_idx]
			if qi and qi.has("item") and qi["item"].resource_path != "":
				saved_quick_slots[slot_idx] = qi["item"].resource_path
	else:
		print("GameState WARNING: GridInventory not found on player!")
	
	# Save keys
	if "keys" in player:
		saved_keys = player.keys.duplicate()
	
	# Save equipped weapon
	if "equipped_weapon" in player and player.equipped_weapon:
		saved_equipped_weapon = player.equipped_weapon.resource_path
	else:
		saved_equipped_weapon = ""
	
	has_saved_data = true
	print("GameState: Player state saved. Items: ", saved_inventory.size())

func restore_player_state(player: Node) -> void:
	if not has_saved_data:
		print("GameState: No saved data to restore.")
		return
	
	if saved_inventory.size() == 0:
		print("GameState: Saved data exists but inventory is empty.")
		return
	
	var grid_inv = player.get_node_or_null("GridInventory")
	if not grid_inv or not grid_inv is GridInventory:
		print("GameState WARNING: GridInventory not found on player for restore!")
		return
	
	# Restore items
	for saved in saved_inventory:
		var item: InventoryItem = load(saved["resource_path"]).duplicate()
		var pos = Vector2i(saved["position_x"], saved["position_y"])
		if item:
			var placed = grid_inv.try_place_item(item, pos, saved["rotated"])
			print("GameState: Restored item '", item.name, "' at ", pos, " -> ", placed)
		else:
			print("GameState WARNING: Could not load item: ", saved["resource_path"])
	
	# Restore quick slots
	for slot_idx in saved_quick_slots.keys():
		var item_path = saved_quick_slots[slot_idx]
		for item_instance in grid_inv.placed_items.values():
			if item_instance["item"].resource_path == item_path:
				grid_inv.assign_quick_slot(slot_idx, item_instance)
				break
	
	# Restore keys
	if "keys" in player:
		player.keys = saved_keys.duplicate()
	
	# Restore equipped weapon
	if saved_equipped_weapon != "" and player.has_method("equip_weapon"):
		var weapon_data = load(saved_equipped_weapon)
		if weapon_data:
			player.equipped_weapon = weapon_data
			
	if next_spawn_direction != "":
		player.set("last_dir", next_spawn_direction)
		next_spawn_direction = ""
	
	print("GameState: Player state restored. Items: ", saved_inventory.size())
