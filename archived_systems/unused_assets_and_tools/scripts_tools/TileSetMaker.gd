extends Node

func _ready() -> void:
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(32, 32)
	tileset.add_physics_layer(0)
	tileset.set_physics_layer_collision_layer(0, 1) # Layer 1
	tileset.set_physics_layer_collision_mask(0, 0) # Mask nothing? Or Mask 1? StaticBody usually Layer 1.
	
	# --- Define Sources ---
	var sources = [
		{ "id": 0, "path": "res://assests/world/house_wall.png", "is_side": false },
		{ "id": 1, "path": "res://assests/world/house_wall_int.png", "is_side": false },
		{ "id": 2, "path": "res://assests/world/house_wall_side.png", "is_side": true }
	]
	
	for s in sources:
		var source = TileSetAtlasSource.new()
		var texture = load(s.path)
		source.texture = texture
		source.texture_region_size = Vector2i(32, 96)
		
		# Create the tile at (0,0) of the Atlas
		source.create_tile(Vector2i(0, 0))
		
		# --- TEXTURE OFFSET ---
		# Texture is 96px tall. Tile is 32px tall.
		# Default alignment: Center?
		# We want the Bottom 32px of the texture to align with the Tile.
		# So we need to shift texture UP by 32px.
		# texture_origin is Vector2i.
		source.set_tile_texture_origin(Vector2i(0, 0), Vector2i(0, 32)) 
		
		# --- COLLISION ---
		# Polygon relative to Tile Center (0,0) -> 16x16 extent.
		# Top-Left: (-16, -16). Bottom-Right: (16, 16).
		# We want a thin line at the BOTTOM.
		# Y: From 14 to 16.
		# X: From -16 to 16 (for 32px width).
		var polygon = PackedVector2Array()
		if s.is_side:
			# Side Wall: 10px wide, -20 to +1 high (based on recent fix)
			# Centered X.
			# X: -5 to 5.
			# Y: Bottom is 16? (Tile Bottom).
			# We want Bottom to be +1 pixel below tile base?
			# Tile Base Y=16. +1 = 17.
			# Top Y = 17 - 20 = -3.
			# polygon = [Vector2(-5, -3), Vector2(5, -3), Vector2(5, 17), Vector2(-5, 17)]
			polygon.append(Vector2(-5, -3))
			polygon.append(Vector2(5, -3))
			polygon.append(Vector2(5, 17))
			polygon.append(Vector2(-5, 17))
		else:
			# Front Wall: 30px wide, 2px high at bottom.
			# X: -15 to 15.
			# Y: 14 to 16 (Tile Bottom).
			# Actually, we used Y=-1 in Node2D (relative to origin).
			# In TileMap, "Origin" is usually center? Or Top-Left?
			# If TileMap Y-Sort Origin is 0.
			# We want collision at Y=-1 relative to Y-Sort Origin.
			# We want collision at -17 relative to base (Y=16).
			# Base Y = 16.
			# Target Collision Center = 16 - 17 = -1.
			# Height 2. Top -2, Bottom 0.
			polygon.append(Vector2(-16, -2))
			polygon.append(Vector2(16, -2))
			polygon.append(Vector2(16, 0)) 
			polygon.append(Vector2(-16, 0))
			
		# Add polygon to Physics Layer 0
		var tile_data = source.get_tile_data(Vector2i(0, 0), 0)
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(0, 0, polygon)
		
		# --- Y SORT ---
		# We want the sort point to be the bottom of the tile.
		# Default sort origin is 0 (Center?).
		# If we set y_sort_origin = 16 (Bottom).
		tile_data.y_sort_origin = 16
		
		tileset.add_source(source, s.id)
	
	# Save
	var result = ResourceSaver.save(tileset, "res://resources/tilesets/HouseTileSet.tres")
	if result == OK:
		print("SUCCESS: HouseTileSet.tres generated!")
		get_tree().quit()
	else:
		print("FAILED: Error code ", result)
		get_tree().quit(1)
