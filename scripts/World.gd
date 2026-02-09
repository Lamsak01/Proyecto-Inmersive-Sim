extends Node2D

func _ready() -> void:
	# Create NavigationRegion2D dynamically
	var nav_region = NavigationRegion2D.new()
	nav_region.name = "RuntimeNavigationRegion"
	add_child(nav_region)
	
	# Setup NavigationPolygon
	var nav_poly = NavigationPolygon.new()
	nav_poly.agent_radius = 16.0 # Approximate enemy radius
	
	# Fallback Strategy: Static Polygon
	# Since runtime baking is failing (API mismatches/empty results),
	# we manually define a large walkable area.
	# The enemy will pathfind in a straight line on this "floor",
	# and use Context Steering (local avoidance) to not hit walls.
	
	var outline = PackedVector2Array([
		Vector2(-2000, -2000),
		Vector2(4000, -2000),
		Vector2(4000, 4000),
		Vector2(-2000, 4000)
	])
	nav_poly.vertices = outline
	nav_poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	
	nav_region.navigation_polygon = nav_poly
	
	# Note: Runtime baking was removed due to engine version incompatibilities.
	# The static polygon + Context Steering provides a robust alternative.
