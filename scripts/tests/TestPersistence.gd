extends SceneTree

func _init():
	print("Starting Persistence Test...")
	
	# Check GameManager Autoload
	if not root.has_node("GameManager"):
		# In a standalone script run via --script, Autoloads might not be loaded automatically 
		# unless we run the MainScene or manually load them. 
		# However, --script runs a script on SceneTree. 
		# Let's try to load it manually if not present, to test the logic.
		print("GameManager not found in root (expected in --script mode). Loading manually...")
		var gm_script = load("res://scripts/systems/GameManager.gd")
		var gm = gm_script.new()
		root.add_child(gm)
		gm.name = "GameManager"
	
	var gm = root.get_node("GameManager")
	
	# Test Set/Save
	print("Setting flag 'test_wall' to true...")
	gm.set_flag("test_wall", true)
	
	# Verify File
	var save_path = "user://game_flags.json"
	if FileAccess.file_exists(save_path):
		print("Save file created successfully.")
		var file = FileAccess.open(save_path, FileAccess.READ)
		print("File content: ", file.get_as_text())
	else:
		print("ERROR: Save file creation failed.")
		quit(1)
		return

	print("Persistence Test Passed.")
	quit(0)
