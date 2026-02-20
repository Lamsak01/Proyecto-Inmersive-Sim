@tool
extends SceneTree

func _init():
	print("Creating Village TileSet (Fixed)...")
	
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(16, 16)
	
	# Paths to extracted images
	var tiles_path = "res://assests/Comprados/extracted/Epic RPG World - The Village V2.1/tilesets and props/tilesets.png"
	var props_path = "res://assests/Comprados/extracted/Epic RPG World - The Village V2.1/tilesets and props/props.png"
	
	_add_atlas_source(tileset, tiles_path)
	_add_atlas_source(tileset, props_path)
	
	var err = ResourceSaver.save(tileset, "res://resources/Village_TileSet.tres")
	if err == OK:
		print("Success! Saved to res://resources/Village_TileSet.tres")
	else:
		print("Error saving resource: ", err)
		
	quit()

func _add_atlas_source(tileset: TileSet, path: String) -> void:
	var tex = load(path)
	if not tex:
		print("Error loading texture: ", path)
		return
		
	var source = TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(16, 16)
	source.separation = Vector2i(1, 1) # IMPORTANT: The 1px gap!
	
	var tex_width = tex.get_width()
	var tex_height = tex.get_height()
	var tile_size = 16
	var separation = 1
	
	# Calculate how many tiles fit
	# Stride is the distance from the start of one tile to the start of the next (16 + 1)
	var stride = tile_size + separation
	
	var cols = floor(tex_width / stride)
	var rows = floor(tex_height / stride)
	
	# Double check bounds just in case (e.g. if last tile has no separation after it)
	if (cols * stride) - separation > tex_width:
		cols -= 1
	if (rows * stride) - separation > tex_height:
		rows -= 1
		
	print("Processing ", path, " | Grid: ", cols, "x", rows)
	
	for y in range(rows):
		for x in range(cols):
			# Note: create_tile(grid_coords) automatically assumes 
			# pixel_pos = grid_coords * (region_size + separation) + margins
			source.create_tile(Vector2i(x, y))
			
	tileset.add_source(source)
