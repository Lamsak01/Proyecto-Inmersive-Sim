extends Node

var items: Dictionary = {}

func _ready() -> void:
	_scan_directory("res://resources/items/")

func _scan_directory(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".res")):
				var res_path = path + file_name
				# Handling for exported games where .tres might be remapped to .tres.remap
				if file_name.ends_with(".remap"):
					res_path = path + file_name.replace(".remap", "")
					
				var resource = load(res_path)
				if resource and resource is InventoryItem:
					if resource.id != "":
						items[resource.id] = resource
					else:
						# Fallback id
						var fallback_id = file_name.get_basename()
						items[fallback_id] = resource
						
			file_name = dir.get_next()
	else:
		push_error("ItemDatabase: Could not open directory " + path)

func get_item(id: String) -> InventoryItem:
	return items.get(id, null)
