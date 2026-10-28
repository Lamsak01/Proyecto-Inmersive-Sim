extends Node2D
class_name PowerPort

enum Level { LV, MV, HV }

@export var level: Level = Level.LV

var _connected_ports: Array[PowerPort] = []
var _owner_component: Node
var _energized: bool = false

func set_owner_component(c: Node) -> void:
	_owner_component = c
	var pm = _pm()
	if pm: pm.register_port(self)

func get_owner_component() -> Node:
	return _owner_component

func connect_to(other: PowerPort) -> void:
	if other != null and not _connected_ports.has(other):
		_connected_ports.append(other)

func disconnect_from(other: PowerPort) -> void:
	if _connected_ports.has(other):
		_connected_ports.erase(other)

func get_connected_ports() -> Array[PowerPort]:
	return _connected_ports

func set_energized(val: bool) -> void:
	if _energized != val:
		_energized = val
		queue_redraw()

func is_energized() -> bool:
	return _energized

func _pm():
	return get_node_or_null("/root/PowerManager")

func _exit_tree():
	var pm = _pm()
	if pm: pm.unregister_port(self)

func _draw():
	# Simple debug visual
	var color = Color.RED
	if _energized: color = Color.GREEN
	draw_circle(Vector2.ZERO, 5, color)
