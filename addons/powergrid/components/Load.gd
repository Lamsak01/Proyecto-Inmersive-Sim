extends Node2D
class_name PowerLoad

@export var enabled: bool = true
@export var required_kw: float = 10.0

@onready var input_port: PowerPort = get_node_or_null("PortIn")

var _is_powered: bool = false

func is_power_load() -> bool:
	return true

func set_powered(val: bool) -> void:
	if _is_powered != val:
		_is_powered = val
		queue_redraw()

func is_powered() -> bool:
	return _is_powered

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

func _draw():
	# Visual debug
	var color = Color.RED
	if _is_powered: color = Color.GREEN
	draw_rect(Rect2(-10, -10, 20, 20), color)
