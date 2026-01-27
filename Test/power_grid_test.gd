extends Node2D

func _ready():
	var gen: PowerGenerator = $Generator
	var t1: PowerTransformer = $Transformer1
	var t2: PowerTransformer = $Transformer2
	var device: PowerLoad = $Load

	var c1 = PowerCable.new()
	add_child(c1)
	var c2 = PowerCable.new()
	add_child(c2)
	var c3 = PowerCable.new()
	add_child(c3)

	print("c1", c1.set_endpoints(gen.get_output_port(), t1.port_in))
	print("c2", c2.set_endpoints(t1.port_out, t2.port_in))
	print("c3", c3.set_endpoints(t2.port_out, device.get_input_port()))

	get_node("/root/PowerManager").recalc_network()
	print("Load powered? ", device.is_powered())
