extends Node

signal network_recalculated

var _dirty := false
var _ports: Array = []
var _loads: Array = []
var _generators: Array = []
var _transformers: Array = []
var _cables: Array = []

func register_component(c):
	if c == null: return
	if c.has_method("is_power_port"):
		return
	if c.has_method("is_power_load") and not _loads.has(c):
		_loads.append(c)
	if c.has_method("is_power_generator") and not _generators.has(c):
		_generators.append(c)
	if c.has_method("is_power_transformer") and not _transformers.has(c):
		_transformers.append(c)
	if c.has_method("is_power_cable") and not _cables.has(c):
		_cables.append(c)
	mark_dirty()

func unregister_component(c):
	_loads.erase(c)
	_generators.erase(c)
	_transformers.erase(c)
	_cables.erase(c)
	mark_dirty()

func register_port(p):
	if p == null: return
	if not _ports.has(p):
		_ports.append(p)
		mark_dirty()

func unregister_port(p):
	_ports.erase(p)
	mark_dirty()

func mark_dirty():
	if _dirty: return
	_dirty = true
	call_deferred("_recalc_if_dirty")

func _recalc_if_dirty():
	if not _dirty: return
	_dirty = false
	recalc_network()

func recalc_network():
	for p in _ports:
		if p and p.has_method("set_energized"):
			p.set_energized(false)

	for l in _loads:
		if l and l.has_method("set_powered"):
			l.set_powered(false)

	for g in _generators:
		if g == null: continue
		if not g.has_method("is_enabled") or not g.is_enabled():
			continue
		var out_port = g.get_output_port()
		if out_port == null: continue
		_bfs_from_port(out_port)

	emit_signal("network_recalculated")

func _bfs_from_port(start_port):
	var q: Array = [start_port]
	var visited := {}
	while q.size() > 0:
		var p = q.pop_front()
		if p == null: continue
		var id = p.get_instance_id()
		if visited.has(id): continue
		visited[id] = true

		p.set_energized(true)

		var owner = p.get_owner_component()
		if owner and owner.has_method("is_power_transformer") and owner.is_power_transformer():
			var out_p = owner.get_output_port_if_input(p)
			if out_p != null:
				q.append(out_p)

		if owner and owner.has_method("is_power_load") and owner.is_power_load():
			owner.set_powered(true)

		for n in p.get_connected_ports():
			if n != null:
				q.append(n)
