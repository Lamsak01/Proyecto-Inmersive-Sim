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
var saved_scene_path: String = ""
var player_health: float = 100.0

# Track states of interactive objects in the world (Generators, Doors, etc.)
var saved_world_states: Dictionary = {}

const SAVE_PATH = "user://savegame.json"

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
		var item: InventoryItem = load(saved["resource_path"])
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

# --- Disk Serialization ---

func save_to_disk() -> void:
	var save_dict = {
		"player_health": player_health,
		"saved_inventory": saved_inventory,
		"saved_quick_slots": saved_quick_slots,
		"world_objects": []
	}
	
	for node in get_tree().get_nodes_in_group("saveable"):
		if node.scene_file_path == "":
			continue
			
		var node_data = {
			"scene_file_path": node.scene_file_path,
			"parent_path": str(node.get_parent().get_path()),
			"pos_x": node.global_position.x,
			"pos_y": node.global_position.y,
			"rot": node.global_rotation
		}
		
		if node.has_method("save_state"):
			node_data["custom_state"] = node.save_state()
			
		save_dict["world_objects"].append(node_data)
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict, "\t"))
		file.close()
		print("GameState: Successfully saved to " + SAVE_PATH)

func load_from_disk() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("GameState: No save file found at " + SAVE_PATH)
		return false
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		push_error("GameState: JSON Parse Error in save file!")
		return false
		
	var data = json.get_data()
	
	# Restore memory variables
	player_health = data.get("player_health", 100.0)
	saved_inventory = data.get("saved_inventory", []) as Array[Dictionary]
	saved_quick_slots = data.get("saved_quick_slots", {}) as Dictionary
	
	# Clean up current saveables
	for node in get_tree().get_nodes_in_group("saveable"):
		node.queue_free()
		
	# Reinstantiate saved objects
	for obj_data in data.get("world_objects", []):
		var scene_res = load(obj_data["scene_file_path"])
		if scene_res:
			var node = scene_res.instantiate()
			var parent = get_node_or_null(obj_data["parent_path"])
			if parent:
				parent.add_child(node)
				node.global_position = Vector2(obj_data["pos_x"], obj_data["pos_y"])
				node.global_rotation = obj_data["rot"]
				node.add_to_group("saveable")
				
				if node.has_method("load_state") and obj_data.has("custom_state"):
					node.load_state(obj_data["custom_state"])
					
	has_saved_data = true
	print("GameState: Successfully loaded from disk!")
	return true
