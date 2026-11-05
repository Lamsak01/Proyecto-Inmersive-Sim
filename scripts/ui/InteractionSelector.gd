extends Node2D

## Selector de la tecla [E] (2026-11-05). Antes, con varias cosas cerca (puerta, mostrador, vecino, cofre, caballo…),
## el juego elegía una por su cuenta. Ahora:
## 1. Encima de lo que se va a usar sale un letrero «[E] …», así sabes qué pasará antes de pulsar.
## 2. Manda el ratón: si el puntero está sobre una de las opciones, esa es la que se usa.
## 3. Si hay varias, [Mayús + rueda] o [G] pasa a la siguiente (el letrero dice «1/3»).
## Solo elige el objetivo: lo que hace cada cosa al usarla no cambia.

const REFRESH_S: float = 0.1
const MOUSE_PICK_PX: float = 16.0
const MOUSE_REACH_PX: float = 55.0

const STATION_LABELS: Dictionary = {
	"well": "Sacar agua del pozo",
	"tavern_games": "Mesa de juego de la posada",
	"tavern_pool": "Mesa de billar",
	"tavern_bed": "Alquilar cama de la posada (8 Oro)",
	"hospital_bed": "Cama de urgencias (10 Oro)",
	"morgue_table": "Mesa de autopsias",
	"police_jail": "Celda y fianza de la comisaría",
	"church_altar": "Altar de la capilla",
	"cemetery_gate": "Puerta del cementerio",
	"notice_board": "Tablón de encargos",
	"compost": "Compostador",
	"building_window": "Abrir o cerrar el postigo",
	"house_chest": "Abrir el cofre",
	"shop_business_stall": "Gestionar el negocio",
}

var player: Node2D = null
var candidates: Array = [] # [{key, area, target, pos, label}] ordenadas por distancia
var _index: int = 0
var _last_keys: String = ""
var _refresh_t: float = 0.0
var _label: Label = null


func setup(p: Node2D) -> void:
	player = p
	name = "InteractionSelector"
	top_level = true
	z_index = 100
	_label = Label.new()
	_label.name = "PromptLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(220, 14)
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 3)
	_label.visible = false
	add_child(_label)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_refresh_t -= delta
	if _refresh_t <= 0.0:
		_refresh_t = REFRESH_S
		refresh()
	_update_label()


func _unhandled_input(event: InputEvent) -> void:
	if candidates.size() < 2:
		return
	var step: int = 0
	if event is InputEventMouseButton and event.pressed and event.shift_pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			step = 1
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			step = -1
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G:
		step = 1
	if step != 0:
		_index = posmod(_index + step, candidates.size())
		_update_label()
		get_viewport().set_input_as_handled()


## Recalcula qué cosas se pueden usar ahora mismo con [E].
func refresh() -> void:
	var out: Array = []
	var ia = player.get("interact_area")
	if ia is Area2D and is_instance_valid(ia):
		for a in (ia as Area2D).get_overlapping_areas():
			if not a.is_in_group("interactable") or not a.is_visible_in_tree():
				continue
			var tgt: Node = _resolve_target(a)
			if tgt == null:
				continue
			var lbl: String = _label_for(a, tgt)
			if lbl == "":
				continue
			out.append({"key": str(a.get_instance_id()), "area": a, "target": tgt, "pos": (a as Node2D).global_position, "label": lbl})
	var pp: Vector2 = player.global_position
	# Montado, «bajar del caballo» va la última: así puedes hablar o abrir puertas sin bajarte.
	var rank := func(c: Dictionary) -> float:
		var d: float = pp.distance_squared_to(c["pos"])
		if (c["target"] as Node).is_in_group("player_horse") and bool(player.get("is_mounted")):
			d += 1000000.0
		return d
	out.sort_custom(func(x, y): return rank.call(x) < rank.call(y))
	var keys: String = ",".join(out.map(func(c): return c["key"]))
	if keys != _last_keys:
		_last_keys = keys
		_index = 0
	candidates = out


## La opción que se usará al pulsar [E]: la que está bajo el ratón, o la elegida con la rueda.
func selected() -> Dictionary:
	if candidates.is_empty():
		return {}
	var mp: Vector2 = player.get_global_mouse_position()
	if player.global_position.distance_to(mp) <= MOUSE_REACH_PX:
		var best: Dictionary = {}
		var best_d: float = MOUSE_PICK_PX
		for c in candidates:
			var d: float = (c["pos"] as Vector2).distance_to(mp)
			if d < best_d:
				best_d = d
				best = c
		if not best.is_empty():
			return best
	return candidates[clampi(_index, 0, candidates.size() - 1)]


## Usa la opción elegida. Devuelve false si no había ninguna.
func use_selected() -> bool:
	refresh()
	var c: Dictionary = selected()
	if c.is_empty() or not is_instance_valid(c["target"]):
		return false
	var tgt: Node = c["target"]
	var area: Area2D = c["area"]
	var vm = player.get_tree().get_first_node_in_group("village_manager")
	if tgt == vm and area.has_meta("village_station"):
		_use_station(vm, area)
	else:
		tgt.call("interact", player)
	_refresh_t = 0.0
	return true


func _use_station(vm, area: Area2D) -> void:
	var tag: String = str(area.get_meta("village_station"))
	var ap: Vector2 = area.global_position
	match tag:
		"building_door":
			var d: Dictionary = vm._find_nearest_door(ap, 18.0)
			if not d.is_empty():
				vm._interact_building_door(player, d)
				return
		"building_window":
			var w: Dictionary = vm._find_nearest_window(ap, 16.0)
			if not w.is_empty():
				vm._interact_building_window(player, w)
				return
		"house_chest":
			for ch in vm.house_chests:
				if (ch["pos"] as Vector2).distance_to(ap) <= 4.0:
					vm._interact_house_chest(player, ch)
					return
		"shop_business_stall":
			var s: Dictionary = vm._find_nearest_business_stall(ap, 18.0)
			if not s.is_empty():
				vm.open_business_management_ui(int(s.get("role", -1)))
				return
	vm.interact(player)


func _resolve_target(a: Node) -> Node:
	if a.has_method("interact"):
		return a
	var p: Node = a.get_parent()
	if p != null and p.has_method("interact"):
		return p
	if p != null and p.get_parent() != null and p.get_parent().has_method("interact"):
		return p.get_parent()
	return null


func _label_for(a: Node, tgt: Node) -> String:
	if a.has_meta("village_station"):
		var tag: String = str(a.get_meta("village_station"))
		if tag == "building_door":
			var vm = player.get_tree().get_first_node_in_group("village_manager")
			var d: Dictionary = vm._find_nearest_door((a as Node2D).global_position, 18.0) if vm != null else {}
			var opened: bool = bool(d.get("is_open", false))
			return ("Cerrar la puerta" if opened else "Abrir la puerta") + ((" · " + str(d.get("title", ""))) if str(d.get("title", "")) != "" else "")
		if tag == "shop_business_stall":
			return "Gestionar el negocio"
		return str(STATION_LABELS.get(tag, "Usar"))
	if tgt.has_method("get_interact_label"):
		return str(tgt.call("get_interact_label", player))
	if tgt is VillageNPC:
		var n: VillageNPC = tgt
		if n.is_dead:
			return "Examinar el cuerpo de %s" % n.npc_name
		if n.is_downed or n.is_stunned_flag or n.sedated_timer > 0.0:
			return "Registrar a %s" % n.npc_name
		return "Hablar con %s" % n.npc_name
	if "animal_name" in tgt:
		return "Despiezar: %s" % str(tgt.get("animal_name"))
	if "pet_name" in tgt:
		return "%s (mascota)" % str(tgt.get("pet_name"))
	if "node_title" in tgt:
		return "Recoger: %s" % str(tgt.get("node_title"))
	return "Usar"


func _update_label() -> void:
	if _label == null:
		return
	var c: Dictionary = selected()
	if c.is_empty():
		_label.visible = false
		return
	var txt: String = "[E] " + str(c["label"])
	if candidates.size() > 1:
		txt += "   (%d/%d · Mayús+rueda o G)" % [candidates.find(c) + 1, candidates.size()]
	_label.text = txt
	_label.visible = true
	_label.position = (c["pos"] as Vector2) + Vector2(-110.0, -34.0)
