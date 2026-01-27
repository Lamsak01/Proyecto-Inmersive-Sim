extends Node2D
class_name PowerLoad

@export var demand_kw: float = 1.0
@export var priority: int = 3

var _powered := false
@onready var input_port: PowerPort = get_node_or_null("PortIn")

func is_power_load() -> bool:
	return true

func set_powered(v: bool) -> void:
	_powered = v
	print(name, " powered=", _powered)

func is_powered() -> bool:
	return _powered

func get_input_port() -> PowerPort:
	return input_port

func _pm():
	return get_node_or_null("/root/PowerManager")

func _ready():
	if input_port == null:
		input_port = PowerPort.new()
		input_port.name = "PortIn"
		input_port.level = PowerPort.Level.LV
		add_child(input_port)

	input_port.set_owner_component(self)

	var pm = _pm()
	if pm: pm.register_component(self)

func _exit_tree():
	var pm = _pm()
	if pm: pm.unregister_component(self)
