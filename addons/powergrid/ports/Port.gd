extends Marker2D
class_name PowerPort

enum Level { HV, MV, LV }

@export var level: Level = Level.LV
var _energized := false
var _connected_ports: Array = []
var _owner_component: Node = null

func is_power_port() -> bool:
	return true

func set_owner_component(n: Node) -> void:
	_owner_component = n

func get_owner_component() -> Node:
	return _owner_component

func set_energized(v: bool) -> void:
	_energized = v

func is_energized() -> bool:
	return _energized

func connect_to(other: PowerPort) -> void:
	if other == null or other == self: return
	if not _connected_ports.has(other):
		_connected_ports.append(other)

func disconnect_from(other: PowerPort) -> void:
	_connected_ports.erase(other)

func get_connected_ports() -> Array:
	return _connected_ports

func _pm():
	return get_node_or_null("/root/PowerManager")

func _ready():
	var pm = _pm()
	if pm: pm.register_port(self)

func _exit_tree():
	var pm = _pm()
	if pm: pm.unregister_port(self)
