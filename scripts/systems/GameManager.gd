extends Node

var game_data: Dictionary = {}
const SAVE_PATH = "user://game_flags.json"
var _is_dirty: bool = false

func _ready():
	load_game()

func set_flag(id: String, value: Variant):
	game_data[id] = value
	if not _is_dirty:
		_is_dirty = true
		call_deferred("save_game")

func get_flag(id: String, default: Variant = null) -> Variant:
	return game_data.get(id, default)

func save_game():
	_is_dirty = false
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(game_data)
		file.store_string(json_string)
		file.close()
		print("Game Saved: ", game_data)

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found.")
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			game_data = json.data
			print("Game Loaded: ", game_data)
func reset_save():
	game_data.clear()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	print("Save File Deleted. Game State Reset.")
