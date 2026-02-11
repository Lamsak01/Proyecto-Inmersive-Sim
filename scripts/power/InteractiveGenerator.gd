extends PowerGenerator

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	super._ready() # Initialize PowerGenerator logic
	update_visuals()

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
