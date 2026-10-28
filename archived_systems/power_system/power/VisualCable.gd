extends Line2D

@export var port_a_path: NodePath
@export var port_b_path: NodePath

var cable: PowerCable
var port_a: PowerPort
var port_b: PowerPort

func _ready() -> void:
    cable = PowerCable.new()
    cable.name = "InternalCable"
    add_child(cable)
    
    if not port_a_path.is_empty():
        var node = get_node(port_a_path)
        if node and node.has_method("get_output_port"):
             port_a = node.get_output_port()
        elif node is PowerPort:
             port_a = node

    if not port_b_path.is_empty():
        var node = get_node(port_b_path)
        # Identify input port for Load
        if node and node.get("input_port"): 
             port_b = node.input_port
        elif node is PowerPort:
             port_b = node
             
    if port_a and port_b:
        cable.set_endpoints(port_a, port_b)
        # Draw line
        clear_points()
        add_point(to_local(port_a.global_position))
        add_point(to_local(port_b.global_position))
        
        print("Cable Connected!")
    else:
        print("Cable Failed to Connect: ", port_a, " -> ", port_b)

func get_power_cable() -> PowerCable:
    return cable

func _process(_delta: float) -> void:
    if not is_visible_in_tree(): return
    
    # Simple pulse effect
    var time = Time.get_ticks_msec() / 200.0
    var alpha = 0.5 + 0.5 * sin(time)
    default_color.a = alpha
    width = 5.0 + 2.0 * sin(time * 2.0)
