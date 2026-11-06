extends Node2D

## Carreta de carga del jugador (Bloque P2, 2026-11-06). Regla 2 «Todo es físico»:
## - Existe en el mapa (grupo `player_cart`), aparcada inicialmente junto al Rancho del Sur (`Vector2(385, 470)`).
## - Se puede tirar de ella a mano (velocidad ×0,55; sin correr, sin sigilo y sin rodar) o engancharla a tu caballo
##   de silla (velocidad del caballo ×0,80; sin sigilo).
## - Sigue el rastro del jugador a 22 px por detrás sin cuerpo de choque (no corta esquinas ni se atasca).
## - Se suelta sola al entrar en un edificio (queda fuera junto a la puerta), al acostarte o si vas escoltado/preso.
##   Si bajas del caballo con la carreta enganchada, se queda enganchada al caballo y quieta donde esté.
## - Parada, ofrece un segundo letrero de [E]: «Abrir la caja de carga (X/40)» con ventana de dos columnas (mochila ↔ caja).
## - Su posición, modo (`"parked"`, `"hand"`, `"horse"`) y carga (`cart_cargo`) se guardan en `VillageCulture.mounts_state`.

const AnimalModel3DScript = preload("res://scripts/visuals/AnimalModel3D.gd")
const CharacterAvatar3DScript = preload("res://scripts/visuals/CharacterAvatar3D.gd")
const SimpleInventoryScript = preload("res://scripts/systems/SimpleInventory.gd")

const CART_RANGE: float = 26.0
const TRAIL_DIST: float = 22.0
const TRAIL_STEP: float = 2.0
const CARGO_CAPACITY: int = 40

var vm: Node = null
var sprite: Node2D = null
var interact_area: Area2D = null
var cargo_area: Area2D = null
var model_3d: Node = null
var _player: Node2D = null
var _last_outside_pos: Vector2 = Vector2.ZERO
var _trail: Array[Vector2] = []
var _facing_dir: Vector2 = Vector2.DOWN

var cargo_layer: CanvasLayer = null
var cargo_panel: PanelContainer = null
var _title_lbl: Label = null
var _inv_list: ItemList = null
var _cargo_list: ItemList = null
var _inv_ids: Array[String] = []
var _cargo_ids: Array[String] = []


class CartSprite2D extends Node2D:
	func _draw() -> void:
		# Dibujo 2D provisional (visible con F10): rectángulo marrón de madera con varales y dos ruedas.
		draw_rect(Rect2(Vector2(-9.0, -11.0), Vector2(18.0, 22.0)), Color(0.08, 0.06, 0.04, 0.45), true)
		draw_rect(Rect2(Vector2(-10.5, -6.0), Vector2(2.5, 10.0)), Color(0.22, 0.14, 0.08), true)
		draw_rect(Rect2(Vector2(8.0, -6.0), Vector2(2.5, 10.0)), Color(0.22, 0.14, 0.08), true)
		draw_rect(Rect2(Vector2(-5.5, 6.0), Vector2(1.8, 8.0)), Color(0.46, 0.30, 0.16), true)
		draw_rect(Rect2(Vector2(3.7, 6.0), Vector2(1.8, 8.0)), Color(0.46, 0.30, 0.16), true)
		draw_rect(Rect2(Vector2(-8.0, -10.0), Vector2(16.0, 17.0)), Color(0.42, 0.27, 0.14), true)
		draw_rect(Rect2(Vector2(-6.5, -8.5), Vector2(13.0, 14.0)), Color(0.56, 0.37, 0.20), true)
		draw_rect(Rect2(Vector2(-8.0, -10.0), Vector2(16.0, 17.0)), Color(0.28, 0.18, 0.09), false, 1.2)


class CartCargoArea extends Area2D:
	var cart: Node2D = null

	func get_interact_label(player: Node2D) -> String:
		if cart != null and is_instance_valid(cart):
			return cart.get_cargo_interact_label(player)
		return ""

	func interact(player: Node2D) -> void:
		if cart != null and is_instance_valid(cart):
			cart.interact_cargo(player)


func setup(p_vm: Node, pos: Vector2) -> void:
	vm = p_vm
	name = "PlayerCart"
	global_position = pos
	_last_outside_pos = pos
	add_to_group("player_cart")

	sprite = CartSprite2D.new()
	sprite.name = "Sprite2D"
	add_child(sprite)

	interact_area = Area2D.new()
	interact_area.name = "InteractArea"
	interact_area.collision_layer = 1
	interact_area.collision_mask = 2
	interact_area.add_to_group("interactable")
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 22.0
	col.shape = c
	interact_area.add_child(col)
	add_child(interact_area)

	cargo_area = CartCargoArea.new()
	cargo_area.name = "CargoInteractArea"
	cargo_area.cart = self
	cargo_area.position = Vector2(0, -4)
	cargo_area.collision_layer = 1
	cargo_area.collision_mask = 2
	cargo_area.add_to_group("interactable")
	var col_cargo := CollisionShape2D.new()
	var c_cargo := CircleShape2D.new()
	c_cargo.radius = 20.0
	col_cargo.shape = c_cargo
	cargo_area.add_child(col_cargo)
	add_child(cargo_area)

	# En 3D: fantasy_town/cart.glb escalado para medir ~26 px de largo (como el caballo).
	model_3d = AnimalModel3DScript.attach(self, "fantasy_town/cart.glb", 10.5, 4.0)
	_setup_cargo_ui()


func _mstate() -> Dictionary:
	return vm.VillageCulture.mounts_state(vm)


func get_cart_mode() -> String:
	if vm == null:
		return "parked"
	return str(_mstate().get("cart_mode", "parked"))


func is_following_player() -> bool:
	var mode: String = get_cart_mode()
	if mode == "hand":
		return true
	if mode == "horse":
		var pl: Node2D = _resolve_player()
		return pl != null and bool(pl.get("is_mounted"))
	return false


func is_stopped(player: Node2D = null) -> bool:
	var mode: String = get_cart_mode()
	if mode == "parked":
		return true
	if mode == "horse":
		var pl: Node2D = player if player != null else _resolve_player()
		return pl == null or not bool(pl.get("is_mounted"))
	return false


func _resolve_player() -> Node2D:
	if is_instance_valid(_player):
		return _player
	if vm != null and "VillageNeeds" in vm and vm.VillageNeeds != null:
		_player = vm.VillageNeeds.player_of(vm) as Node2D
	return _player


## Primer letrero de [E]: agarrar/soltar a pie o enganchar/desenganchar a caballo.
func get_interact_label(player: Node2D) -> String:
	var mode: String = get_cart_mode()
	if mode == "hand":
		return "Soltar la carreta"
	if mode == "horse":
		return "Desenganchar"
	if player != null and bool(player.get("is_mounted")):
		return "Enganchar la carreta al caballo"
	return "Agarrar la carreta"


## Segundo letrero de [E]: abrir la caja de carga cuando la carreta está parada.
func get_cargo_interact_label(player: Node2D) -> String:
	if not is_stopped(player):
		return ""
	return "Abrir la caja de carga (%d/%d)" % [get_cargo_total(), CARGO_CAPACITY]


func interact(player: Node2D) -> void:
	if player == null:
		return
	var mode: String = get_cart_mode()
	if mode == "hand":
		release_cart(player)
		return
	if mode == "horse":
		unhitch_from_horse(player)
		return
	if player.global_position.distance_to(global_position) > CART_RANGE:
		return
	if vm != null and _is_inside_building(player.global_position):
		_say(player, "🛒 Aquí dentro no se puede llevar la carreta")
		return
	if bool(player.get("is_mounted")):
		hitch_to_horse(player)
	else:
		grab_by_hand(player)


func interact_cargo(player: Node2D) -> void:
	if player == null or not is_stopped(player):
		return
	if player.global_position.distance_to(global_position) > CART_RANGE:
		return
	_player = player
	open_cargo_ui(player)


func grab_by_hand(player: Node2D, silent: bool = false) -> void:
	if player == null:
		return
	_player = player
	if cargo_panel != null:
		cargo_panel.visible = false
	player.set("is_pulling_cart", true)
	player.set("is_cart_hitched", false)
	var mc = player.get_node_or_null("PlayerMovementController")
	if mc != null:
		mc.set("is_stealthing", false)
		mc.set("is_sprinting", false)
		if "max_walk_speed" in mc and "CART_HAND_SPEED_MULT" in mc:
			mc.set("current_speed", float(mc.get("max_walk_speed")) * float(mc.get("CART_HAND_SPEED_MULT")))
	var m: Dictionary = _mstate()
	m["cart_mode"] = "hand"
	_init_trail(player.global_position)
	_place_behind_leader(player.global_position)
	if not silent:
		_say(player, "🛒 Agarras la carreta ([E] para soltarla)")


func release_cart(player: Node2D = null, stay_at: Vector2 = Vector2.INF, custom_msg: String = "") -> void:
	var pl: Node2D = player if player != null else _resolve_player()
	if pl != null:
		pl.set("is_pulling_cart", false)
		pl.set("is_cart_hitched", false)
		var mc = pl.get_node_or_null("PlayerMovementController")
		if mc != null and "max_walk_speed" in mc:
			mc.set("current_speed", float(mc.get("max_walk_speed")))
	if stay_at != Vector2.INF:
		global_position = stay_at
	_trail.clear()
	var m: Dictionary = _mstate()
	m["cart_mode"] = "parked"
	m["cart_x"] = global_position.x
	m["cart_y"] = global_position.y
	if pl != null:
		_say(pl, custom_msg if custom_msg != "" else "🛒 Sueltas la carreta; queda aparcada aquí")


func hitch_to_horse(player: Node2D, silent: bool = false) -> void:
	if player == null:
		return
	_player = player
	if cargo_panel != null:
		cargo_panel.visible = false
	player.set("is_pulling_cart", false)
	player.set("is_cart_hitched", true)
	var mc = player.get_node_or_null("PlayerMovementController")
	if mc != null:
		mc.set("is_stealthing", false)
	var m: Dictionary = _mstate()
	m["cart_mode"] = "horse"
	_init_trail(player.global_position)
	if bool(player.get("is_mounted")):
		_place_behind_leader(player.global_position)
	if not silent:
		_say(player, "🐎🛒 Enganchas la carreta al caballo ([E] para desenganchar)")


func unhitch_from_horse(player: Node2D = null, stay_at: Vector2 = Vector2.INF, custom_msg: String = "") -> void:
	var pl: Node2D = player if player != null else _resolve_player()
	if pl != null:
		pl.set("is_pulling_cart", false)
		pl.set("is_cart_hitched", false)
	if stay_at != Vector2.INF:
		global_position = stay_at
	_trail.clear()
	var m: Dictionary = _mstate()
	m["cart_mode"] = "parked"
	m["cart_x"] = global_position.x
	m["cart_y"] = global_position.y
	if pl != null:
		_say(pl, custom_msg if custom_msg != "" else "🐎🛒 Desenganchas la carreta del caballo")


func _init_trail(leader_pos: Vector2) -> void:
	_trail.clear()
	_trail.append(leader_pos)
	if global_position.distance_to(leader_pos) > 1.0:
		_trail.append(global_position)
	else:
		_trail.append(leader_pos + Vector2(0, TRAIL_DIST))


func _place_behind_leader(leader_pos: Vector2) -> void:
	if _trail.is_empty():
		_init_trail(leader_pos)
	elif leader_pos.distance_to(_trail[0]) >= TRAIL_STEP:
		_trail.push_front(leader_pos)

	var acc: float = 0.0
	var prev: Vector2 = leader_pos
	var target_pos: Vector2 = global_position
	var placed: bool = false
	var keep_until: int = _trail.size()

	for i in range(_trail.size()):
		var pt: Vector2 = _trail[i]
		var seg: float = prev.distance_to(pt)
		if acc + seg >= TRAIL_DIST:
			var rem: float = TRAIL_DIST - acc
			var t: float = rem / maxf(0.001, seg)
			target_pos = prev.lerp(pt, t)
			keep_until = i + 2
			placed = true
			break
		acc += seg
		prev = pt

	if not placed:
		var tail: Vector2 = _trail[_trail.size() - 1]
		var diff: Vector2 = tail - leader_pos
		if diff.length_squared() > 0.01:
			target_pos = leader_pos + diff.normalized() * TRAIL_DIST
		else:
			target_pos = leader_pos + Vector2(0, TRAIL_DIST)

	if _trail.size() > keep_until:
		_trail.resize(keep_until)

	var mv: Vector2 = target_pos - global_position
	if mv.length_squared() > 0.01:
		_facing_dir = mv.normalized()
		if sprite != null:
			sprite.rotation = atan2(_facing_dir.x, _facing_dir.y)
	elif leader_pos.distance_squared_to(target_pos) > 0.01:
		_facing_dir = (leader_pos - target_pos).normalized()
		if sprite != null:
			sprite.rotation = atan2(_facing_dir.x, _facing_dir.y)

	global_position = target_pos
	if not _is_inside_building(global_position):
		_last_outside_pos = global_position
	var m: Dictionary = _mstate()
	m["cart_x"] = global_position.x
	m["cart_y"] = global_position.y


func _physics_process(_delta: float) -> void:
	if vm == null:
		return
	var mode: String = get_cart_mode()
	if mode == "parked":
		return
	var pl: Node2D = _resolve_player()
	if pl == null:
		return

	if mode == "hand" and bool(pl.get("is_mounted")):
		# Si montas a caballo mientras tirabas a mano, se suelta de la mano.
		release_cart(pl, _last_outside_pos)
		return

	if mode == "horse":
		pl.set("is_cart_hitched", true)
		pl.set("is_pulling_cart", false)
		# Si bajas del caballo con la carreta enganchada, se queda enganchada al caballo, quieta donde esté.
		if not bool(pl.get("is_mounted")):
			return
	else:
		pl.set("is_pulling_cart", true)
		pl.set("is_cart_hitched", false)

	var p: Vector2 = pl.global_position
	var hc = pl.get_node_or_null("HealthComponent")
	if _is_inside_building(p):
		if mode == "hand":
			release_cart(pl, _last_outside_pos, "🛒 La carreta no cabe dentro; te espera junto a la puerta")
		else:
			global_position = _last_outside_pos
			var m_out: Dictionary = _mstate()
			m_out["cart_x"] = global_position.x
			m_out["cart_y"] = global_position.y
		return
	if (hc != null and bool(hc.get("is_resting_in_bed"))) or bool(vm.get("player_being_escorted_to_jail")) or bool(vm.get("player_in_jail")):
		if mode == "hand":
			release_cart(pl, _last_outside_pos)
		else:
			global_position = _last_outside_pos
			var m_bed: Dictionary = _mstate()
			m_bed["cart_x"] = global_position.x
			m_bed["cart_y"] = global_position.y
		return

	_place_behind_leader(p)


func _process(_delta: float) -> void:
	if sprite != null and is_instance_valid(sprite):
		sprite.visible = not CharacterAvatar3DScript.use_3d_characters


func _unhandled_input(event: InputEvent) -> void:
	if cargo_panel == null or not cargo_panel.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			cargo_panel.visible = false
			get_viewport().set_input_as_handled()


func _is_inside_building(p: Vector2) -> bool:
	if vm == null or not ("building_footprints" in vm):
		return false
	for b in vm.building_footprints:
		if (b["rect"] as Rect2).grow(-3.0).has_point(p):
			return true
	return false


func get_facing_2d() -> Vector2:
	if model_3d != null and model_3d.has_method("get_facing_2d"):
		return model_3d.get_facing_2d()
	return _facing_dir


# ==============================================================================
# Caja de carga (40 unidades máx., sin oro) y ventana de dos columnas
# ==============================================================================

func get_cargo() -> Dictionary:
	if vm == null:
		return {}
	var m: Dictionary = _mstate()
	if not (m.get("cart_cargo", null) is Dictionary):
		m["cart_cargo"] = {}
	return m["cart_cargo"]


func get_cargo_total() -> int:
	var c: Dictionary = get_cargo()
	var total: int = 0
	for k in c.keys():
		total += maxi(0, int(c[k]))
	return total


func put_item(inv, item_id: String, qty: int = 1) -> int:
	if inv == null or item_id == "" or item_id == "gold" or qty <= 0:
		return 0
	var have: int = int(inv.get_count(item_id)) if inv.has_method("get_count") else int(inv.items.get(item_id, 0))
	var free_cap: int = maxi(0, CARGO_CAPACITY - get_cargo_total())
	var move_qty: int = mini(qty, mini(have, free_cap))
	if move_qty <= 0:
		return 0
	inv.remove_item(item_id, move_qty)
	var cargo: Dictionary = get_cargo()
	cargo[item_id] = int(cargo.get(item_id, 0)) + move_qty
	_refresh_cargo_ui()
	return move_qty


func put_all_from_inventory(inv, item_id: String = "") -> int:
	if inv == null:
		return 0
	if item_id != "":
		var cnt: int = int(inv.get_count(item_id)) if inv.has_method("get_count") else int(inv.items.get(item_id, 0))
		return put_item(inv, item_id, cnt)
	var total_added: int = 0
	var keys: Array = inv.items.keys().duplicate()
	for k in keys:
		var id_str: String = str(k)
		var cnt_k: int = int(inv.items.get(id_str, 0))
		if cnt_k > 0:
			total_added += put_item(inv, id_str, cnt_k)
			if get_cargo_total() >= CARGO_CAPACITY:
				break
	return total_added


func take_item(inv, item_id: String, qty: int = 1) -> int:
	if inv == null or item_id == "" or qty <= 0:
		return 0
	var cargo: Dictionary = get_cargo()
	var have: int = int(cargo.get(item_id, 0))
	var move_qty: int = mini(qty, have)
	if move_qty <= 0:
		return 0
	var left: int = have - move_qty
	if left <= 0:
		cargo.erase(item_id)
	else:
		cargo[item_id] = left
	inv.add_item(item_id, move_qty)
	_refresh_cargo_ui()
	return move_qty


func _setup_cargo_ui() -> void:
	cargo_layer = CanvasLayer.new()
	cargo_layer.name = "CartCargoLayer"
	cargo_layer.layer = 22
	add_child(cargo_layer)

	cargo_panel = PanelContainer.new()
	cargo_panel.name = "CartCargoPanel"
	cargo_panel.visible = false
	cargo_panel.position = Vector2(140, 60)
	cargo_panel.custom_minimum_size = Vector2(360, 230)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.08, 0.12, 0.96)
	sb.border_color = Color(0.86, 0.68, 0.32, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	cargo_panel.add_theme_stylebox_override("panel", sb)
	cargo_layer.add_child(cargo_panel)

	var root_vb := VBoxContainer.new()
	root_vb.add_theme_constant_override("separation", 6)
	cargo_panel.add_child(root_vb)

	_title_lbl = Label.new()
	_title_lbl.add_theme_font_size_override("font_size", 12)
	_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72))
	root_vb.add_child(_title_lbl)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vb.add_child(cols)

	# Columna izquierda: Mochila
	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left_vb)
	var l_hdr := Label.new()
	l_hdr.text = "🎒 Tu mochila"
	l_hdr.add_theme_font_size_override("font_size", 11)
	left_vb.add_child(l_hdr)
	_inv_list = ItemList.new()
	_inv_list.custom_minimum_size = Vector2(155, 120)
	_inv_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_inv_list.add_theme_font_size_override("font_size", 10)
	left_vb.add_child(_inv_list)
	var l_btns := HBoxContainer.new()
	left_vb.add_child(l_btns)
	var btn_put_one := Button.new()
	btn_put_one.text = "Meter 1"
	btn_put_one.add_theme_font_size_override("font_size", 10)
	btn_put_one.pressed.connect(_on_put_one_pressed)
	l_btns.add_child(btn_put_one)
	var btn_put_all := Button.new()
	btn_put_all.text = "Meter todo"
	btn_put_all.add_theme_font_size_override("font_size", 10)
	btn_put_all.pressed.connect(_on_put_all_pressed)
	l_btns.add_child(btn_put_all)

	# Columna derecha: Caja de la carreta
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right_vb)
	var r_hdr := Label.new()
	r_hdr.text = "🛒 Caja de carga"
	r_hdr.add_theme_font_size_override("font_size", 11)
	right_vb.add_child(r_hdr)
	_cargo_list = ItemList.new()
	_cargo_list.custom_minimum_size = Vector2(155, 120)
	_cargo_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cargo_list.add_theme_font_size_override("font_size", 10)
	right_vb.add_child(_cargo_list)
	var r_btns := HBoxContainer.new()
	right_vb.add_child(r_btns)
	var btn_take_one := Button.new()
	btn_take_one.text = "Sacar 1"
	btn_take_one.add_theme_font_size_override("font_size", 10)
	btn_take_one.pressed.connect(_on_take_one_pressed)
	r_btns.add_child(btn_take_one)

	var btn_close := Button.new()
	btn_close.text = "[ESC] Cerrar caja de carga"
	btn_close.add_theme_font_size_override("font_size", 10)
	btn_close.pressed.connect(func(): cargo_panel.visible = false)
	root_vb.add_child(btn_close)


func open_cargo_ui(player: Node2D = null) -> void:
	if player != null:
		_player = player
	if cargo_panel == null:
		return
	_refresh_cargo_ui()
	cargo_panel.visible = true


func _refresh_cargo_ui() -> void:
	if cargo_panel == null or _inv_list == null or _cargo_list == null:
		return
	_title_lbl.text = "📦🛒 Caja de carga de la carreta (%d/%d) · El oro no cabe" % [get_cargo_total(), CARGO_CAPACITY]
	_inv_list.clear()
	_inv_ids.clear()
	var pl: Node2D = _resolve_player()
	var inv = pl.get("inventory") if pl != null else null
	if inv != null and "items" in inv:
		for k in inv.items.keys():
			var cnt: int = int(inv.items[k])
			if cnt <= 0:
				continue
			var it_id: String = str(k)
			var it_name: String = str(SimpleInventoryScript.CATALOG.get(it_id, {}).get("name", it_id))
			_inv_ids.append(it_id)
			_inv_list.add_item("%s x%d" % [it_name, cnt])
	if _inv_ids.size() > 0:
		_inv_list.select(0)

	_cargo_list.clear()
	_cargo_ids.clear()
	var cargo: Dictionary = get_cargo()
	for k2 in cargo.keys():
		var cnt2: int = int(cargo[k2])
		if cnt2 <= 0:
			continue
		var it_id2: String = str(k2)
		var it_name2: String = str(SimpleInventoryScript.CATALOG.get(it_id2, {}).get("name", it_id2))
		_cargo_ids.append(it_id2)
		_cargo_list.add_item("%s x%d" % [it_name2, cnt2])
	if _cargo_ids.size() > 0:
		_cargo_list.select(0)


func _on_put_one_pressed() -> void:
	var pl: Node2D = _resolve_player()
	var inv = pl.get("inventory") if pl != null else null
	if inv == null or _inv_ids.is_empty():
		return
	var sel: PackedInt32Array = _inv_list.get_selected_items()
	var idx: int = sel[0] if not sel.is_empty() else 0
	if idx >= 0 and idx < _inv_ids.size():
		put_item(inv, _inv_ids[idx], 1)


func _on_put_all_pressed() -> void:
	var pl: Node2D = _resolve_player()
	var inv = pl.get("inventory") if pl != null else null
	if inv == null or _inv_ids.is_empty():
		return
	var sel: PackedInt32Array = _inv_list.get_selected_items()
	if not sel.is_empty() and sel[0] >= 0 and sel[0] < _inv_ids.size():
		put_all_from_inventory(inv, _inv_ids[sel[0]])
	else:
		put_all_from_inventory(inv)


func _on_take_one_pressed() -> void:
	var pl: Node2D = _resolve_player()
	var inv = pl.get("inventory") if pl != null else null
	if inv == null or _cargo_ids.is_empty():
		return
	var sel: PackedInt32Array = _cargo_list.get_selected_items()
	var idx: int = sel[0] if not sel.is_empty() else 0
	if idx >= 0 and idx < _cargo_ids.size():
		take_item(inv, _cargo_ids[idx], 1)


func _say(player: Node2D, txt: String) -> void:
	if player != null and player.has_method("show_hint"):
		player.show_hint(txt)
