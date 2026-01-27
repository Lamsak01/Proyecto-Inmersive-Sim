extends Node
class_name PowerCable

@export var enabled: bool = true

var port_a: PowerPort
var port_b: PowerPort

func is_power_cable() -> bool:
	return true

func _pm():
	return get_node_or_null("/root/PowerManager")

func _ready():
	var pm = _pm()
	if pm: pm.register_component(self)

func set_endpoints(a: PowerPort, b: PowerPort) -> bool:
	if a == null or b == null:
		return false
	if a.level != b.level:
		return false
	port_a = a
	port_b = b
	_refresh_links()
	return true

func _refresh_links():
	if port_a and port_b:
		port_a.connect_to(port_b)
		port_b.connect_to(port_a)
	var pm = _pm()
	if pm: pm.mark_dirty()

func disconnect_endpoints():
	if port_a and port_b:
		port_a.disconnect_from(port_b)
		port_b.disconnect_from(port_a)
	port_a = null
	port_b = null
	var pm = _pm()
	if pm: pm.mark_dirty()

func _exit_tree():
	disconnect_endpoints()
	var pm = _pm()
	if pm: pm.unregister_component(self)
