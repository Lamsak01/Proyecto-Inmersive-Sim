extends Node

signal network_recalculated

var _dirty := false
var _ports: Array[PowerPort] = []
var _loads: Array[PowerLoad] = []
var _generators: Array[PowerGenerator] = []
var _transformers: Array[Node] = []
var _cables: Array[PowerCable] = []

func register_component(c: Node) -> void:
	if c == null: return
	
	if c is PowerPort:
		return 
		
	if c is PowerLoad and not _loads.has(c):
		_loads.append(c)
	elif c is PowerGenerator and not _generators.has(c):
		_generators.append(c)
	elif c is PowerTransformer and not _transformers.has(c):
		_transformers.append(c)
	elif c is PowerCable and not _cables.has(c):
		_cables.append(c)
		
	mark_dirty()

func unregister_component(c: Node) -> void:
	if c is PowerLoad:
		_loads.erase(c)
	elif c is PowerGenerator:
		_generators.erase(c)
	elif c.has_method("is_power_transformer"):
		_transformers.erase(c)
	elif c is PowerCable:
		_cables.erase(c)
	mark_dirty()

func register_port(p: PowerPort) -> void:
	if p == null: return
	if not _ports.has(p):
		_ports.append(p)
		mark_dirty()

func unregister_port(p: PowerPort) -> void:
	_ports.erase(p)
	mark_dirty()

func mark_dirty() -> void:
	if _dirty: return
	_dirty = true
	call_deferred("_recalc_if_dirty")

func _recalc_if_dirty() -> void:
	if not _dirty: return
	_dirty = false
	recalc_network()

func recalc_network() -> void:
	for p in _ports:
		p.set_energized(false)

	for l in _loads:
		l.set_powered(false)

	for g in _generators:
		if not g.is_enabled():
			continue
		var out_port = g.get_output_port()
		if out_port == null: continue
		_bfs_from_port(out_port)

	network_recalculated.emit()

func _bfs_from_port(start_port: PowerPort) -> void:
	if start_port.is_energized(): return
	
	var q: Array[PowerPort] = [start_port]
	start_port.set_energized(true)
	
	while not q.is_empty():
		var p = q.pop_front()
		
		var owner = p.get_owner_component()
		if owner:
			if owner.has_method("is_power_transformer") and owner.is_power_transformer():
				var out_p = owner.get_output_port_if_input(p)
				if out_p and not out_p.is_energized():
					out_p.set_energized(true)
					q.append(out_p)
			
			if owner is PowerLoad:
				owner.set_powered(true)

		for n in p.get_connected_ports():
			if n and not n.is_energized():
				n.set_energized(true)
				q.append(n)
