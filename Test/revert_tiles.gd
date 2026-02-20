@tool
extends SceneTree

func _init():
	print("Starting revert...")
	var scene_path = "res://scenes/Buildings/House1Interior.tscn"
	var packed_scene = ResourceLoader.load(scene_path)
	if not packed_scene:
		print("Failed to load scene.")
		quit()
		return
		
	var scene_root = packed_scene.instantiate()
	
	var destructibles = scene_root.get_node_or_null("Destructibles")
	if destructibles:
		print("Removing Destructibles node...")
		destructibles.queue_free()
		# We must wait for queue_free or just remove_child
		scene_root.remove_child(destructibles)
		destructibles.free()
	else:
		print("No Destructibles node found to remove.")
		
	# Unfortunately the TileMapLayer data was cleared and saved. 
	# Without a backup, recovering the exact tile placement requires manual repainting 
	# or pulling from a local Godot backup if it exists.
	print("Note: The 'Misc' TileMapLayer was cleared in the previous step.")
	
	var pack = PackedScene.new()
	pack.pack(scene_root)
	ResourceSaver.save(pack, scene_path)
	print("Scene reverted successfully (Destructibles removed).")
	
	quit()
