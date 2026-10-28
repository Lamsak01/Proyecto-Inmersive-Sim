extends PowerGenerator

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	super._ready() # Initialize PowerGenerator logic
	add_to_group("saveable")
	update_visuals()

func save_state() -> Dictionary:
	return { "enabled": enabled }

func load_state(data: Dictionary) -> void:
	if data.has("enabled"):
		enabled = data["enabled"]
		update_visuals()
		var pm = _pm()
		if pm: pm.mark_dirty()

func interact(_player) -> void:
	enabled = !enabled
	print("Generator Toggled: ", enabled)
	update_visuals()
	
	# Force network update
	var pm = _pm()
	if pm: pm.mark_dirty()

func update_visuals() -> void:
	if sprite:
		if enabled:
			sprite.modulate = Color(1.5, 1.5, 1.5) # Glow
		else:
			sprite.modulate = Color(0.5, 0.5, 0.5) # Dim
