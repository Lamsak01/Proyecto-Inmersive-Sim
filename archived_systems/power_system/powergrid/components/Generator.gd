extends Node2D
class_name PowerGenerator

@export var enabled: bool = true
@export var max_kw: float = 50.0

@onready var output_port: PowerPort = get_node_or_null("PortOut")

func is_power_generator() -> bool:
	return true

func is_enabled() -> bool:
	return enabled

func get_output_port() -> PowerPort:
	return output_port

func _pm() -> Node:
	return get_node_or_null("/root/PowerManager")

func _ready() -> void:
	if output_port == null:
		output_port = PowerPort.new()
		output_port.name = "PortOut"
		output_port.level = PowerPort.Level.LV
		add_child(output_port)

	output_port.set_owner_component(self)

	var pm = _pm()
	if pm: pm.register_component(self)

func _exit_tree() -> void:
	var pm = _pm()
	if pm: pm.unregister_component(self)
