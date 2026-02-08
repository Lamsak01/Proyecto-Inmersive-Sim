extends Node
class_name Inventory

signal item_added(item: String)
signal item_removed(item: String)

@export var items: Array[String] = []

func add_item(item: String) -> void:
	items.append(item)
	item_added.emit(item)
	print("Item added: ", item)

func remove_item(item: String) -> bool:
	var index = items.find(item)
	if index != -1:
		items.remove_at(index)
		item_removed.emit(item)
		print("Item removed: ", item)
		return true
	return false

func has_item(item: String) -> bool:
	return items.has(item)

func get_items() -> Array[String]:
	return items
