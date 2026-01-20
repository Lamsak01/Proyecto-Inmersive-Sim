extends Node2D

@onready var layer: TileMapLayer = $Obstacles

func _ready() -> void:
	var ts := layer.tile_set
	for cell in layer.get_used_cells():
		var source_id := layer.get_cell_source_id(cell)
		if source_id < 0:
			continue

		var src := ts.get_source(source_id)
		if src is TileSetAtlasSource:
			var atlas_coords := layer.get_cell_atlas_coords(cell)
			if not src.has_tile(atlas_coords):
				layer.erase_cell(cell)

	print("Limpieza lista (celdas inválidas borradas).")
