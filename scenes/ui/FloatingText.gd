extends Label
class_name FloatingText

@export var float_speed: float = 60.0
@export var duration: float = 1.0
@export var text_color: Color = Color.WHITE
@export var start_text: String = ""

func _ready() -> void:
	text = start_text
	modulate = text_color
	
	var tween = create_tween().set_parallel(true)
	# Float up
	tween.tween_property(self, "position:y", position.y - 40.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
