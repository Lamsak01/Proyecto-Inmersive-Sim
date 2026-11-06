class_name WorldInteractableProp
extends Node2D

## Objeto físico interactivo del mundo («La Placa de Petri» - Bloque FIS2):
## - `"terminal"`: Terminal Lógica Electromecánica sobre mesa dentro del Taller de Reparaciones (`solar e5`).
## - `"grid_panel"`: Cuadro Eléctrico en la pared exterior del Taller de Reparaciones (`solar e5`).
## - `"heist_target"`: Objeto físico de los 3 grandes robos (`sello_noble`, `caliz_capilla`, `libro_gremial`).
## Tiene dibujo 2D propio (oculto automáticamente en vista 3D y visible al pulsar [F10]),
## `Area2D` en el grupo `"interactable"` con su letrero contextual `[E] ...`, y acción directa al pulsar [E].

const VillageCulture = preload("res://scripts/systems/VillageCulture.gd")
const VillageUnderworld = preload("res://scripts/systems/VillageUnderworld.gd")
const CharacterAvatar3DScript = preload("res://scripts/visuals/CharacterAvatar3D.gd")

var vm: Node2D = null
var prop_kind: String = "terminal"
var heist_id: String = ""
var heist_label: String = ""
var npc_name: String = "Objeto"
var npc_role: String = "Mecanismo del Taller"
var interact_area: Area2D = null
var visual_2d: Node2D = null


func setup_prop(village_manager: Node2D, kind: String, h_id: String = "", h_label: String = "") -> void:
	vm = village_manager
	prop_kind = kind
	heist_id = h_id
	heist_label = h_label
	match prop_kind:
		"terminal":
			npc_name = "Terminal Lógica Electromecánica"
			npc_role = "Taller de Reparaciones"
			add_to_group("tinker_terminal")
			add_to_group("tinker_station")
		"grid_panel":
			npc_name = "Cuadro Eléctrico General"
			npc_role = "Pared Exterior del Taller"
			add_to_group("tinker_grid_panel")
			add_to_group("tinker_station")
		"heist_target":
			npc_name = heist_label if not heist_label.is_empty() else "Objetivo del Encargo"
			npc_role = "Encargo del Perista"
			add_to_group("heist_target_prop")
	_rebuild_visual_and_area()


func _ready() -> void:
	if visual_2d == null:
		_rebuild_visual_and_area()


func _process(_delta: float) -> void:
	if is_instance_valid(visual_2d):
		visual_2d.visible = not CharacterAvatar3DScript.use_3d_characters


func _rebuild_visual_and_area() -> void:
	if is_instance_valid(visual_2d):
		visual_2d.queue_free()
	visual_2d = Node2D.new()
	visual_2d.name = "Visual2D"
	visual_2d.z_index = 1
	visual_2d.visible = not CharacterAvatar3DScript.use_3d_characters
	visual_2d.set_meta("flat_2d_building_visual", true)
	add_child(visual_2d)

	match prop_kind:
		"terminal":
			_draw_terminal_2d()
		"grid_panel":
			_draw_grid_panel_2d()
		"heist_target":
			_draw_heist_target_2d()

	if interact_area == null or not is_instance_valid(interact_area):
		interact_area = Area2D.new()
		interact_area.name = "InteractArea"
		interact_area.collision_layer = 1
		interact_area.collision_mask = 2
		interact_area.add_to_group("interactable")
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 20.0
		shape.shape = circle
		interact_area.add_child(shape)
		add_child(interact_area)


func _poly(pts: PackedVector2Array, col: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = col
	p.set_meta("flat_2d_building_visual", true)
	visual_2d.add_child(p)


func _rect(center: Vector2, half: Vector2, col: Color) -> void:
	_poly(PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	]), col)


func _draw_terminal_2d() -> void:
	# Mesa de taller de madera y herrajes + consola electromecánica de latón, visor fosforescente y tambor de tarjetas
	_rect(Vector2(0, 2), Vector2(12, 8), Color(0.18, 0.12, 0.08, 0.55)) # Sombra
	_rect(Vector2(0, 0), Vector2(11, 7), Color(0.46, 0.31, 0.18)) # Tablero de la mesa
	_rect(Vector2(0, 0), Vector2(9.5, 5.5), Color(0.54, 0.37, 0.22)) # Superficie
	_rect(Vector2(0, -1), Vector2(7.0, 4.5), Color(0.24, 0.26, 0.30)) # Carcasa de acero
	_rect(Vector2(0, -1), Vector2(6.0, 3.6), Color(0.76, 0.58, 0.26)) # Marco de latón
	_rect(Vector2(-1.2, -1.5), Vector2(3.4, 2.0), Color(0.12, 0.32, 0.28)) # Visor oscuro
	_rect(Vector2(-1.2, -1.5), Vector2(2.6, 1.3), Color(0.32, 0.94, 0.78)) # Pantalla de relés encendida
	_rect(Vector2(3.6, -1.4), Vector2(1.4, 2.2), Color(0.88, 0.82, 0.68)) # Rodillo de tarjetas perforadas
	_rect(Vector2(-2.5, 1.8), Vector2(3.0, 1.0), Color(0.18, 0.20, 0.22)) # Teclado mecánico


func _draw_grid_panel_2d() -> void:
	# Armario eléctrico metálico en la fachada exterior con bobinas de cobre, 3 palancas y piloto
	_rect(Vector2(0, 1), Vector2(8.0, 6.0), Color(0.10, 0.12, 0.15, 0.60)) # Sombra en pared
	_rect(Vector2(0, 0), Vector2(7.0, 5.2), Color(0.26, 0.29, 0.34)) # Caja de hierro
	_rect(Vector2(0, 0), Vector2(5.8, 4.0), Color(0.18, 0.20, 0.24)) # Interior del cuadro
	_rect(Vector2(-3.5, -1.5), Vector2(1.3, 2.2), Color(0.82, 0.48, 0.22)) # Bobina de cobre izq
	_rect(Vector2(3.5, -1.5), Vector2(1.3, 2.2), Color(0.82, 0.48, 0.22)) # Bobina de cobre der
	for sx in [-2.0, 0.0, 2.0]:
		_rect(Vector2(sx, 1.2), Vector2(0.6, 1.8), Color(0.88, 0.74, 0.30)) # 3 interruptores de cuchilla
	_rect(Vector2(0, -2.6), Vector2(1.4, 1.0), Color(0.38, 0.96, 1.0)) # Piloto voltaico


func _draw_heist_target_2d() -> void:
	match heist_id:
		"sello_noble":
			# Cojín carmesí con el Sello de Lacre Noble (lacre rojo + matriz de oro/bronce)
			_rect(Vector2(0, 1), Vector2(6.5, 5.0), Color(0.55, 0.10, 0.16))
			_rect(Vector2(0, 0.5), Vector2(5.2, 3.8), Color(0.78, 0.16, 0.22))
			_rect(Vector2(-1.8, 0.5), Vector2(2.2, 2.2), Color(0.90, 0.18, 0.18)) # Lacre
			_rect(Vector2(1.6, -1.0), Vector2(2.0, 3.0), Color(0.95, 0.78, 0.26)) # Matriz de oro
		"caliz_capilla":
			# Cáliz de Plata de la Capilla con destello sobre el altar
			_rect(Vector2(0, 3.2), Vector2(3.4, 1.2), Color(0.76, 0.82, 0.90)) # Pie
			_rect(Vector2(0, 0.8), Vector2(1.2, 2.4), Color(0.84, 0.88, 0.96)) # Fuste
			_poly(PackedVector2Array([
				Vector2(-3.8, -3.4), Vector2(3.8, -3.4),
				Vector2(2.4, 0.2), Vector2(-2.4, 0.2)
			]), Color(0.90, 0.94, 1.0)) # Copa de plata
			_rect(Vector2(0, -3.4), Vector2(4.0, 0.8), Color(0.98, 0.84, 0.32)) # Borde dorado
		_:
			# Libro Mayor de los Gremios (gran tomo encuadernado con cierres de oro)
			_rect(Vector2(0, 0.5), Vector2(7.2, 5.2), Color(0.38, 0.20, 0.12)) # Cubierta de cuero
			_rect(Vector2(-3.1, 0.2), Vector2(2.8, 4.2), Color(0.95, 0.90, 0.76)) # Página izq
			_rect(Vector2(3.1, 0.2), Vector2(2.8, 4.2), Color(0.92, 0.86, 0.72)) # Página der
			_rect(Vector2(0, 0.2), Vector2(0.7, 4.4), Color(0.28, 0.14, 0.08)) # Lomo central
			_rect(Vector2(1.2, 3.5), Vector2(0.8, 2.2), Color(0.86, 0.18, 0.20)) # Cinta marcapáginas
			_rect(Vector2(-6.6, -3.8), Vector2(1.0, 1.0), Color(0.95, 0.78, 0.26)) # Herraje de oro
			_rect(Vector2(6.6, -3.8), Vector2(1.0, 1.0), Color(0.95, 0.78, 0.26))


func get_interact_label(_player: Node2D = null) -> String:
	match prop_kind:
		"terminal":
			return "Usar la Terminal Lógica"
		"grid_panel":
			return "Manipular el cuadro eléctrico"
		"heist_target":
			var lbl: String = heist_label
			if lbl.is_empty() and vm != null:
				lbl = str(VillageUnderworld.state(vm).get("active_heist", {}).get("label", "el objetivo"))
			return "Robar %s" % (lbl if not lbl.is_empty() else "el objetivo")
	return "Usar"


func interact(player: Node2D) -> void:
	if vm == null or player == null:
		return
	match prop_kind:
		"terminal":
			VillageCulture.open_terminal_menu(vm, self, player)
		"grid_panel":
			VillageCulture.open_grid_panel_menu(vm, self, player)
		"heist_target":
			VillageUnderworld.try_interact(vm, player, global_position)


func on_dialogue_action(action_id: String) -> void:
	if vm == null:
		return
	var player: Node2D = null
	if is_inside_tree():
		player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		player = vm.VillageNeeds.player_of(vm)
	var inv = player.get("inventory") if player != null else null
	VillageCulture.on_player_action(vm, null, action_id, inv)
