extends Area2D

# This script detects if the player is "behind" the wall (overlapping this area)
# and fades the parent sprite to allow visibility.

@export var fade_duration: float = 0.2
@export var transparency: float = 0.4

var _tween: Tween
var _parent_sprite: Sprite2D

func _ready():
	# Assume the parent is the StaticBody or Node2D holding the Sprite
	# Actually, let's look for the sprite sibling or parent.
	# Best structure: StaticBody -> [Sprite, Collision, Area2D(this)]
	var parent = get_parent()
	if parent is Node2D:
		# Look for a Sprite2D child
		for child in parent.get_children():
			if child is Sprite2D:
				_parent_sprite = child
				break
	
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		fade_to(transparency)

func _on_body_exited(body):
	if body.is_in_group("player"):
		fade_to(1.0)

func fade_to(target_alpha: float):
	if not _parent_sprite: return
	
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_property(_parent_sprite, "modulate:a", target_alpha, fade_duration)
