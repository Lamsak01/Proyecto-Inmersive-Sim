extends Node2D
class_name PwCable

@export var enabled := true
@export var destroyed := false
@export var port_a_path: NodePath
@export var port_b_path: NodePath

var a: PowerPort
var b: PowerPort

func _pm(): return get_node_or_null("/root/PowerManager")
func is_power_cable() -> bool: return true

func _ready():
	var pm = _pm()
	if pm: pm.register_component(self)
	_apply()

func _exit_tree():
	_unlink()
	var pm = _pm()
	if pm: pm.unregister_component(self)

func _resolve():
	a = get_node_or_null(port_a_path) as PowerPort
	b = get_node_or_null(port_b_path) as PowerPort

func _unlink():
	if a and b:
		a.disconnect_from(b)
		b.disconnect_from(a)

func _apply():
	_unlink()
	_resolve()
	if not enabled or destroyed or not a or not b or a.level != b.level: return
	a.connect_to(b); b.connect_to(a)
	var pm = _pm()
	if pm: pm.mark_dirty()

func set_enabled(v: bool): enabled = v; _apply()
func set_destroyed(v: bool): destroyed = v; _apply()

func redirect_end_b(new_b: PowerPort):
	b = new_b
	port_b_path = get_path_to(new_b) if new_b else NodePath()
	_apply()
