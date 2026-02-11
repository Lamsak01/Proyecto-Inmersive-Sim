extends PowerLoad

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var indicator: ColorRect = $PowerIndicator

# Override set_powered to handle door logic
func set_powered(val: bool) -> void:
	super.set_powered(val) # Update internal state
	_update_door_state()

func _ready() -> void:
	super._ready()
	_update_door_state()

func _update_door_state() -> void:
	if is_powered():
		open_door()
	else:
		close_door()

func open_door() -> void:
	if collision: collision.set_deferred("disabled", true)
	if sprite: sprite.modulate.a = 0.3 # Transparent/Open visual
	if indicator: indicator.color = Color.GREEN
	print("Door Opened!")

func close_door() -> void:
	if collision: collision.set_deferred("disabled", false)
	if sprite: sprite.modulate.a = 1.0 # Opaque/Closed visual
	if indicator: indicator.color = Color.RED
	print("Door Closed!")
