extends Label
class_name FloatingText

@export var float_speed: float = 22.0
@export var duration: float = 1.2
@export var text_color: Color = Color.WHITE
@export var start_text: String = ""

func _ready() -> void:
	var clean_txt := start_text.strip_edges()
	if clean_txt.length() > 46:
		clean_txt = clean_txt.substr(0, 44) + "…"
	text = clean_txt
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 7)
	add_theme_color_override("font_color", text_color)
	add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.05, 0.95))
	add_theme_constant_override("outline_size", 2)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.094, 0.082, 0.067, 0.86)
	sb.border_color = Color(0.227, 0.196, 0.157, 0.95)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	add_theme_stylebox_override("normal", sb)
	scale = Vector2(0.68, 0.68)
	z_index = 24
	reset_size()
	position.x -= (size.x * scale.x) * 0.5

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 16.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	tween.set_parallel(false)
	tween.tween_callback(queue_free)
