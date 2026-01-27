extends Node2D
class_name PowerTransformer

enum Type { HV_TO_MV, MV_TO_LV }

@export var enabled: bool = true
@export var type: Type = Type.HV_TO_MV

@onready var port_in: PowerPort = get_node_or_null("PortIn")
@onready var port_out: PowerPort = get_node_or_null("PortOut")

func is_power_transformer() -> bool:
	return true

func _pm():
	return get_node_or_null("/root/PowerManager")

func _ready():
	# Si no existen puertos en escena, créalos
	if port_in == null:
		port_in = PowerPort.new()
		port_in.name = "PortIn"
		add_child(port_in)
	if port_out == null:
		port_out = PowerPort.new()
		port_out.name = "PortOut"
		add_child(port_out)

	port_in.set_owner_component(self)
	port_out.set_owner_component(self)
	_apply_levels()

	var pm = _pm()
	if pm: pm.register_component(self)

func _apply_levels():
	if type == Type.HV_TO_MV:
		port_in.level = PowerPort.Level.HV
		port_out.level = PowerPort.Level.MV
	else:
		port_in.level = PowerPort.Level.MV
		port_out.level = PowerPort.Level.LV

func get_output_port_if_input(p: PowerPort) -> PowerPort:
	if not enabled: return null
	if p == port_in:
		return port_out
	return null

func _exit_tree():
	var pm = _pm()
	if pm: pm.unregister_component(self)
