extends PowerLoad

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var indicator: ColorRect = $PowerIndicator

# Override set_powered to handle door logic
func set_powered(val: bool) -> void:
	super.set_powered(val) # Update internal state
	_update_door_state()

var is_broken: bool = false

func _ready() -> void:
	super._ready()
	add_to_group("saveable")
	_update_door_state()

func save_state() -> Dictionary:
	return { "is_broken": is_broken }

func load_state(data: Dictionary) -> void:
	if data.has("is_broken") and data["is_broken"]:
		break_door()

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

func take_damage(data: DamageData) -> void:
	# Allow breaking the door with BLUNT weapons (Hammer)
	if data.type == CombatConstants.DamageType.BLUNT:
		print("Door smashed open!")
		break_door()

func break_door() -> void:
	is_broken = true
	if collision: collision.set_deferred("disabled", true)
	if sprite: 
		sprite.modulate = Color(0.5, 0.5, 0.5, 1.0) # Greyed out / broken
		sprite.rotation_degrees = 15 # Skewed
	if indicator: indicator.color = Color.BLACK # No power/broken
