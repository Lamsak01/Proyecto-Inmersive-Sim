extends Node

func _ready():
	var gen = PowerGenerator.new()
	add_child(gen)

	var t1 = PowerTransformer.new()
	t1.type = PowerTransformer.Type.HV_TO_MV
	add_child(t1)

	var t2 = PowerTransformer.new()
	t2.type = PowerTransformer.Type.MV_TO_LV
	add_child(t2)

	var load = PowerLoad.new()
	add_child(load)

	var c_hv = PowerCable.new()
	add_child(c_hv)

	var c_mv = PowerCable.new()
	add_child(c_mv)

	var c_lv = PowerCable.new()
	add_child(c_lv)

	var ok1 = c_hv.set_endpoints(gen.get_output_port(), t1.port_in)
	var ok2 = c_mv.set_endpoints(t1.port_out, t2.port_in)
	var ok3 = c_lv.set_endpoints(t2.port_out, load.get_input_port())

	print("Cable HV:", ok1, " Cable MV:", ok2, " Cable LV:", ok3)

	var pm = get_node("/root/PowerManager")
	pm.recalc_network()

	print("Load powered? ", load.is_powered())
