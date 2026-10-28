@tool
extends Node2D
class_name VisionCone2D

@export var radius: float = 150.0:
	set(value):
		if is_equal_approx(radius, value):
			return
		radius = value
		queue_redraw()

@export var angle_deg: float = 60.0:
	set(value):
		if is_equal_approx(angle_deg, value):
			return
		angle_deg = value
		queue_redraw()

@export var color: Color = Color(0, 1, 0, 0.2):
	set(value):
		if color.is_equal_approx(value):
			return
		color = value
		queue_redraw()

func _draw() -> void:
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)
	
	var num_points = 20
	var start_angle = deg_to_rad(-angle_deg * 0.5)
	var end_angle = deg_to_rad(angle_deg * 0.5)
	var step = (end_angle - start_angle) / num_points
	
	for i in range(num_points + 1):
		var angle = start_angle + i * step
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	points.append(Vector2.ZERO)
	
	draw_polygon(points, [color])
	draw_polyline(points, color.lightened(0.5), 1.0)
