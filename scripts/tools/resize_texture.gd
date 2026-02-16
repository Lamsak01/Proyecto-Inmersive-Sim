extends Node

func _ready():
	var image = Image.load_from_file("res://temp_weak_source.png")
	if image:
		image.resize(32, 96, Image.INTERPOLATE_BILINEAR)
		image.save_png("res://assests/world/weak_wall.png")
		print("Resize Success: Saved to assests/world/weak_wall.png")
	else:
		print("Error: Could not load temp_weak_source.png")
	get_tree().quit()
