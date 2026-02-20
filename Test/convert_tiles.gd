@tool
extends SceneTree

func _init():
	print("Starting TileMap conversion...")
	var scene_path = "res://scenes/Buildings/House1Interior.tscn"
	var packed_scene = ResourceLoader.load(scene_path)
	if not packed_scene:
		print("Failed to load scene.")
		quit()
		return
		
	var scene_root = packed_scene.instantiate()
	
	var tiles_node = scene_root.get_node_or_null("Tiles")
	if not tiles_node:
		print("Tiles node not found.")
		quit()
		return
		
	var misc_layer = tiles_node.get_node_or_null("Misc")
	if not misc_layer or not misc_layer is TileMapLayer:
		print("Misc TileMapLayer not found.")
		quit()
		return
		
	var tile_set = misc_layer.tile_set
	if not tile_set:
		print("No TileSet found on Misc layer.")
		quit()
		return
		
	var tile_size = tile_set.tile_size
	print("Tile size: ", tile_size)
	
	var destructibles_root = Node2D.new()
	destructibles_root.name = "Destructibles"
	scene_root.add_child(destructibles_root)
	destructibles_root.owner = scene_root
	
	var used_cells = misc_layer.get_used_cells()
	var count = 0
	
	for cell in used_cells:
		var source_id = misc_layer.get_cell_source_id(cell)
		var atlas_coords = misc_layer.get_cell_atlas_coords(cell)
		var alt_tile = misc_layer.get_cell_alternative_tile(cell)
		
		var source = tile_set.get_source(source_id) as TileSetAtlasSource
		if not source: continue
		
		var texture = source.texture
		var region_size = source.texture_region_size
		var region_rect = Rect2(
			Vector2(atlas_coords.x * region_size.x, atlas_coords.y * region_size.y),
			region_size
		)
		
		# Create nodes
		var static_body = StaticBody2D.new()
		static_body.name = "Prop_%d_%d" % [cell.x, cell.y]
		
		# Calculate position correctly based on TileMapLayer transform and tile size
		# Cell local to map local
		var local_pos = misc_layer.map_to_local(cell)
		static_body.position = misc_layer.position + local_pos
		
		var sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.texture = texture
		sprite.region_enabled = true
		sprite.region_rect = region_rect
		# We must make sure Y sort or Z index is fine. But for now just set texture.
		static_body.add_child(sprite)
		
		var collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape = RectangleShape2D.new()
		shape.size = Vector2(region_size.x, region_size.y)
		collision.shape = shape
		static_body.add_child(collision)
		
		destructibles_root.add_child(static_body)
		
		# Set owners for saving
		static_body.owner = scene_root
		sprite.owner = scene_root
		collision.owner = scene_root
		
		count += 1
		
	print("Converted %d tiles to StaticBody2D props." % count)
	
	# Optional: Remove the original layer or clear it
	misc_layer.clear()
	print("Cleared 'Misc' TileMapLayer.")
	
	var pack = PackedScene.new()
	pack.pack(scene_root)
	ResourceSaver.save(pack, scene_path)
	print("Scene saved successfully.")
	
	quit()
