@tool
extends Node2D
class_name VisionCone2D

@export var radius: float = 150.0:
	set(value):
		radius = value
		queue_redraw()

@export var angle_deg: float = 60.0:
	set(value):
		angle_deg = value
		queue_redraw()

@export var color: Color = Color(0, 1, 0, 0.2):
	set(value):
		color = value
		queue_redraw()

func _draw() -> void:
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)
	
	var num_points = 30
	var start_angle = deg_to_rad(-angle_deg / 2)
	var end_angle = deg_to_rad(angle_deg / 2)
	var step = (end_angle - start_angle) / num_points
	
	for i in range(num_points + 1):
		var angle = start_angle + i * step
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	points.append(Vector2.ZERO)
	
	draw_polygon(points, [color])
	# Optional: Draw outline
	draw_polyline(points, color.lightened(0.5), 1.0)
