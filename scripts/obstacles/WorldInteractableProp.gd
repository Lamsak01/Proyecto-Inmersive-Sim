class_name WorldInteractableProp
extends Node2D

## Objeto físico interactivo del mundo («La Placa de Petri» - Bloques FIS2 y FIS3):
## - `"terminal"`: Terminal Lógica Electromecánica sobre mesa dentro del Taller de Reparaciones (`solar e5`).
## - `"grid_panel"`: Cuadro Eléctrico en la pared exterior del Taller de Reparaciones (`solar e5`).
## - `"heist_target"`: Objeto físico de los 3 grandes robos (`sello_noble`, `caliz_capilla`, `libro_gremial`).
## - `"sewer_grate"`: Trampilla/rejilla de calle para bajar a las alcantarillas (`cistern`, `smuggler_tunnel`, `flooded_vault`).
## - `"sewer_ladder"`: Escalerilla subterránea para subir a la trampilla correspondiente de la calle.
## - `"sewer_chest"`: Cofre de contrabando subterráneo (1 por cámara, 1 vez al día).
## Tiene dibujo 2D propio (oculto automáticamente en vista 3D y visible al pulsar [F10]),
## `Area2D` en el grupo `"interactable"` con su letrero contextual `[E] ...`, y acción directa al pulsar [E].

const VillageCulture = preload("res://scripts/systems/VillageCulture.gd")
const VillageUnderworld = preload("res://scripts/systems/VillageUnderworld.gd")
const VillageHousing = preload("res://scripts/systems/VillageHousing.gd")
const VillageCollections = preload("res://scripts/systems/VillageCollections.gd")
const VillageClub = preload("res://scripts/systems/VillageClub.gd")
const VillageTavern = preload("res://scripts/systems/VillageTavern.gd")
const VillageFame = preload("res://scripts/systems/VillageFame.gd")
const CharacterAvatar3DScript = preload("res://scripts/visuals/CharacterAvatar3D.gd")

var vm: Node2D = null
var prop_kind: String = "terminal"
var heist_id: String = ""
var heist_label: String = ""
var sewer_loc_id: String = ""
var npc_name: String = "Objeto"
var npc_role: String = "Mecanismo del Taller"
var interact_area: Area2D = null
var visual_2d: Node2D = null


func setup_prop(village_manager: Node2D, kind: String, h_id: String = "", h_label: String = "") -> void:
	vm = village_manager
	prop_kind = kind
	heist_id = h_id
	heist_label = h_label
	sewer_loc_id = h_id
	match prop_kind:
		"terminal":
			npc_name = heist_label if not heist_label.is_empty() else "Terminal Lógica Electromecánica"
			npc_role = "Comisaría del Alguacil" if heist_id == "police" else ("Ayuntamiento del Valle" if heist_id == "town_hall" else "Taller de Reparaciones")
			if heist_id.is_empty():
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
		"sewer_grate":
			npc_name = heist_label if not heist_label.is_empty() else "Rejilla de Alcantarilla"
			npc_role = "Acceso a las Alcantarillas"
			add_to_group("sewer_grate")
			add_to_group("sewer_station")
		"sewer_ladder":
			npc_name = "Escalerilla a la Calle"
			npc_role = heist_label if not heist_label.is_empty() else "Salida de Alcantarilla"
			add_to_group("sewer_ladder")
			add_to_group("sewer_station")
		"sewer_chest":
			npc_name = "Cofre de Contrabando"
			npc_role = heist_label if not heist_label.is_empty() else "Alijo Subterráneo"
			add_to_group("sewer_chest")
			add_to_group("sewer_station")
		"home_workbench":
			npc_name = "Banco de Trabajo y Alquimia"
			npc_role = heist_label if not heist_label.is_empty() else "Interior de tu Casa"
			add_to_group("home_workbench")
			add_to_group("home_prop")
		"home_table":
			npc_name = "Mesa del Comedor"
			npc_role = heist_label if not heist_label.is_empty() else "Interior de tu Casa"
			add_to_group("home_table")
			add_to_group("home_prop")
		"home_stash":
			npc_name = "Escondite bajo las Tablas"
			npc_role = heist_label if not heist_label.is_empty() else "Suelo de tu Casa"
			add_to_group("home_stash")
			add_to_group("home_prop")
		"home_stairs":
			npc_name = "Escalera y Trampilla de Casa"
			npc_role = heist_label if not heist_label.is_empty() else "Cambio de Planta"
			add_to_group("home_stairs")
			add_to_group("home_prop")
		"home_garden":
			npc_name = "Huerto Doméstico"
			npc_role = heist_label if not heist_label.is_empty() else "Solar de tu Casa"
			add_to_group("home_garden")
			add_to_group("home_prop")
		"player_shop_counter":
			npc_name = heist_label if not heist_label.is_empty() else "Bazar del Forastero"
			npc_role = "Mostrador y Caja de tu Tienda"
			add_to_group("player_shop_counter")
			add_to_group("home_prop")
		"collect_point": # P5: cobro de renta o «protección» en el local (invisible: basta el letrero)
			npc_name = "Cobro en el local"
			npc_role = "Lo que te deben"
			add_to_group("collect_point")
		"town_coffers": # P5: desviar oro del cofre de las arcas (siendo alcalde)
			npc_name = "Arcas del Pueblo"
			npc_role = "Ayuntamiento"
			add_to_group("town_coffers_prop")
		"town_ledger": # P5: libro de cuentas sobre la mesa del ayuntamiento
			npc_name = "Libro de Cuentas"
			npc_role = "Mesa del Ayuntamiento"
			add_to_group("town_ledger_prop")
		"masterwork_counter": # A1: mostrador del taller del maestro artesano (invisible: basta el letrero)
			npc_name = "Mostrador del Maestro"
			npc_role = "Obras Maestras"
			add_to_group("masterwork_counter")
		"club_trapdoor", "club_ladder", "club_ring", "club_bet": # P6: club de pelea en el sótano de la taberna
			npc_name = {"club_trapdoor": "Trampilla", "club_ladder": "Escalerilla a la Taberna", "club_ring": "Corro de Cuerda", "club_bet": "Apuestas"}[prop_kind]
			npc_role = "Sótano de la Taberna"
			add_to_group("club_prop")
		"tavern_stairs":
			npc_name = "Escalera de la Posada"
			npc_role = "Cambio de Planta (0 / +1)"
			add_to_group("tavern_stairs")
	_rebuild_visual_and_area()


func _ready() -> void:
	if visual_2d == null:
		_rebuild_visual_and_area()


func _process(_delta: float) -> void:
	if is_instance_valid(visual_2d):
		var show_2d: bool = not CharacterAvatar3DScript.use_3d_characters
		if show_2d and vm != null:
			if prop_kind in ["sewer_ladder", "sewer_chest"]:
				show_2d = VillageUnderworld.is_player_in_sewers(vm)
			elif prop_kind in ["club_ladder", "club_ring", "club_bet"]:
				show_2d = VillageClub.is_player_in_club(vm)
			elif prop_kind in ["sewer_grate", "club_trapdoor"]:
				show_2d = (int(vm.player_elevation_level) == 0)
				if prop_kind == "club_trapdoor":
					var open_now: bool = VillageClub.is_open_now(vm)
					var n_closed := visual_2d.get_node_or_null("ClosedTrapdoor2D") as CanvasItem
					var n_open := visual_2d.get_node_or_null("OpenTrapdoor2D") as CanvasItem
					if is_instance_valid(n_closed):
						n_closed.visible = not open_now
					if is_instance_valid(n_open):
						n_open.visible = open_now
		visual_2d.visible = show_2d


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
		"sewer_grate":
			_draw_sewer_grate_2d()
		"sewer_ladder":
			_draw_sewer_ladder_2d()
		"sewer_chest":
			_draw_sewer_chest_2d()
		"home_workbench":
			_draw_home_workbench_2d()
		"home_table":
			_draw_home_table_2d()
		"home_stash":
			_draw_home_stash_2d()
		"home_stairs":
			_draw_home_stairs_2d()
		"home_garden":
			_draw_home_garden_2d()
		"player_shop_counter":
			_draw_player_shop_counter_2d()
		"town_ledger":
			_draw_town_ledger_2d()
		"club_trapdoor":
			_draw_club_trapdoor_2d()
		"club_ladder":
			_draw_sewer_ladder_2d()
		"tavern_stairs":
			_draw_home_stairs_2d()

	if interact_area == null or not is_instance_valid(interact_area):
		interact_area = Area2D.new()
		interact_area.name = "InteractArea"
		interact_area.collision_layer = 1
		interact_area.collision_mask = 2
		interact_area.add_to_group("interactable")
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 48.0 if prop_kind == "tavern_stairs" else (14.0 if prop_kind == "sewer_grate" else 20.0)
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


func _draw_sewer_grate_2d() -> void:
	# Trampilla / rejilla de hierro forjado sobre brocal de piedra en la calle
	_rect(Vector2(0, 1), Vector2(9.5, 9.5), Color(0.10, 0.12, 0.10, 0.65)) # Sombra
	_rect(Vector2(0, 0), Vector2(9.0, 9.0), Color(0.52, 0.50, 0.46)) # Brocal de piedra
	_rect(Vector2(0, 0), Vector2(7.4, 7.4), Color(0.22, 0.25, 0.28)) # Marco de hierro
	_rect(Vector2(0, 0), Vector2(6.0, 6.0), Color(0.06, 0.10, 0.08)) # Pozo oscuro
	for gx in [-3.8, -1.3, 1.3, 3.8]:
		_rect(Vector2(gx, 0), Vector2(0.6, 6.0), Color(0.32, 0.36, 0.40)) # Barrotes
	_rect(Vector2(0, 0), Vector2(6.0, 0.6), Color(0.32, 0.36, 0.40)) # Travesaño
	_rect(Vector2(4.2, 0), Vector2(1.3, 1.3), Color(0.84, 0.68, 0.26)) # Cerradura / argolla de latón


func _draw_sewer_ladder_2d() -> void:
	# Escalerilla de hierro adosada al muro de ladrillo del túnel
	_rect(Vector2(0, 0), Vector2(6.5, 8.5), Color(0.14, 0.18, 0.16, 0.75)) # Hueco vertical
	_rect(Vector2(-4.2, 0), Vector2(1.0, 8.0), Color(0.56, 0.42, 0.24)) # Larguero izq
	_rect(Vector2(4.2, 0), Vector2(1.0, 8.0), Color(0.56, 0.42, 0.24)) # Larguero der
	for ry in [-5.5, -2.0, 1.5, 5.0]:
		_rect(Vector2(0, ry), Vector2(4.2, 0.8), Color(0.76, 0.64, 0.38)) # Peldaños


func _draw_club_trapdoor_2d() -> void:
	var add_r := func(parent_n: Node2D, center: Vector2, half: Vector2, col: Color) -> void:
		var p := Polygon2D.new()
		p.polygon = PackedVector2Array([
			center + Vector2(-half.x, -half.y),
			center + Vector2(half.x, -half.y),
			center + Vector2(half.x, half.y),
			center + Vector2(-half.x, half.y),
		])
		p.color = col
		p.set_meta("flat_2d_building_visual", true)
		parent_n.add_child(p)
	var closed_n := Node2D.new()
	closed_n.name = "ClosedTrapdoor2D"
	visual_2d.add_child(closed_n)
	add_r.call(closed_n, Vector2(0, 1), Vector2(9.5, 8.5), Color(0.10, 0.08, 0.06, 0.60)) # Sombra
	add_r.call(closed_n, Vector2(0, 0), Vector2(8.5, 7.5), Color(0.32, 0.20, 0.10)) # Marco de roble
	add_r.call(closed_n, Vector2(0, 0), Vector2(7.2, 6.2), Color(0.48, 0.31, 0.16)) # Tablas cerradas
	add_r.call(closed_n, Vector2(0, -3.4), Vector2(7.0, 0.9), Color(0.24, 0.27, 0.32)) # Herraje norte
	add_r.call(closed_n, Vector2(0, 3.4), Vector2(7.0, 0.9), Color(0.24, 0.27, 0.32)) # Herraje sur
	add_r.call(closed_n, Vector2(4.2, 0), Vector2(1.4, 1.4), Color(0.86, 0.68, 0.24)) # Candado cerrado

	var open_n := Node2D.new()
	open_n.name = "OpenTrapdoor2D"
	open_n.visible = vm != null and VillageClub.is_open_now(vm)
	closed_n.visible = not open_n.visible
	visual_2d.add_child(open_n)
	add_r.call(open_n, Vector2(0, 0), Vector2(12.0, 10.5), Color(1.0, 0.68, 0.22, 0.38)) # Resplandor cálido de antorchas del sótano
	add_r.call(open_n, Vector2(0, -9.2), Vector2(7.8, 3.4), Color(0.50, 0.33, 0.17)) # Hoja de madera abierta hacia atrás
	add_r.call(open_n, Vector2(0, -9.2), Vector2(7.2, 0.8), Color(0.24, 0.27, 0.32)) # Bisagra de hierro
	add_r.call(open_n, Vector2(0, 0), Vector2(8.5, 7.5), Color(0.34, 0.21, 0.11)) # Brocal de madera
	add_r.call(open_n, Vector2(0, 0), Vector2(6.8, 5.8), Color(0.06, 0.05, 0.04)) # Pozo abierto al sótano (-1)
	add_r.call(open_n, Vector2(-3.6, 0.5), Vector2(0.8, 5.2), Color(0.58, 0.42, 0.24)) # Larguero escalera izq
	add_r.call(open_n, Vector2(3.6, 0.5), Vector2(0.8, 5.2), Color(0.58, 0.42, 0.24)) # Larguero escalera der
	for ry in [-3.2, -0.4, 2.4, 4.8]:
		add_r.call(open_n, Vector2(0, ry), Vector2(3.6, 0.75), Color(0.82, 0.66, 0.38)) # Peldaños iluminados


func _draw_sewer_chest_2d() -> void:
	# Cofre de contrabando reforzado con cinchas de hierro sobre losa seca
	_rect(Vector2(0, 1.5), Vector2(8.0, 6.0), Color(0.08, 0.10, 0.08, 0.65)) # Sombra
	_rect(Vector2(0, 0), Vector2(7.0, 5.0), Color(0.42, 0.26, 0.14)) # Caja de madera
	_rect(Vector2(0, -1.2), Vector2(7.0, 2.2), Color(0.50, 0.32, 0.18)) # Tapa
	_rect(Vector2(-4.2, 0), Vector2(1.0, 5.0), Color(0.26, 0.30, 0.34)) # Herraje izq
	_rect(Vector2(4.2, 0), Vector2(1.0, 5.0), Color(0.26, 0.30, 0.34)) # Herraje der
	_rect(Vector2(0, 0.6), Vector2(1.6, 1.6), Color(0.92, 0.76, 0.26)) # Candado de latón


func _draw_home_workbench_2d() -> void:
	# Banco de trabajo y alquimia de roble con mortero de hierbas y alambique de vidrio
	_rect(Vector2(0, 1.5), Vector2(10.0, 6.5), Color(0.14, 0.10, 0.06, 0.55)) # Sombra
	_rect(Vector2(0, 0), Vector2(9.2, 5.5), Color(0.48, 0.32, 0.18)) # Tablero del banco
	_rect(Vector2(0, 0), Vector2(8.0, 4.4), Color(0.56, 0.38, 0.22)) # Superficie
	_rect(Vector2(-3.8, -0.6), Vector2(2.2, 2.2), Color(0.36, 0.42, 0.34)) # Mortero de piedra
	_rect(Vector2(-3.8, -0.8), Vector2(1.4, 1.4), Color(0.32, 0.78, 0.38)) # Cataplasma verde
	_rect(Vector2(3.2, -0.8), Vector2(2.0, 2.6), Color(0.68, 0.42, 0.88)) # Matraz de alambique violeta
	_rect(Vector2(3.2, -2.6), Vector2(0.8, 1.2), Color(0.84, 0.68, 0.28)) # Cuello de latón


func _draw_home_stash_2d() -> void:
	# Tablas sueltas del suelo con argolla de hierro y destello de monedas ocultas
	_rect(Vector2(0, 0), Vector2(7.5, 5.5), Color(0.26, 0.16, 0.08)) # Hueco oscuro entre vigas
	_rect(Vector2(-2.2, 0), Vector2(2.2, 4.8), Color(0.46, 0.30, 0.16)) # Tabla entreabierta izq
	_rect(Vector2(2.4, -0.5), Vector2(2.2, 4.8), Color(0.52, 0.34, 0.18)) # Tabla levantada der
	_rect(Vector2(-0.2, 1.2), Vector2(1.6, 1.6), Color(0.95, 0.78, 0.24)) # Brillo de oro oculto
	_rect(Vector2(3.2, 0.5), Vector2(1.1, 1.1), Color(0.72, 0.58, 0.26)) # Argolla secreta


func _draw_home_stairs_2d() -> void:
	# Escalera de madera al altillo (+1) y trampilla con bisagras hacia el sótano (-1)
	_rect(Vector2(0, 0.5), Vector2(7.5, 8.5), Color(0.20, 0.14, 0.08, 0.70)) # Hueco de escalera
	_rect(Vector2(0, 0), Vector2(6.8, 7.8), Color(0.44, 0.28, 0.15)) # Marco de madera
	for sy in [-4.8, -1.6, 1.6, 4.8]:
		_rect(Vector2(0, sy), Vector2(5.4, 1.1), Color(0.62, 0.42, 0.24)) # Peldaños de roble
	_rect(Vector2(3.8, 0), Vector2(1.2, 1.2), Color(0.82, 0.68, 0.28)) # Argolla de trampilla


func _draw_home_garden_2d() -> void:
	# Huerto doméstico cercado con surcos de tierra húmeda y brotes verdes
	_rect(Vector2(0, 1.0), Vector2(12.5, 9.0), Color(0.22, 0.15, 0.08, 0.50)) # Sombra
	_rect(Vector2(0, 0), Vector2(11.8, 8.2), Color(0.50, 0.34, 0.18)) # Bordillo de madera
	_rect(Vector2(0, 0), Vector2(10.4, 6.8), Color(0.32, 0.22, 0.12)) # Tierra labrada
	var ready_crop: bool = vm == null or VillageHousing.can_harvest_home_garden(vm, heist_id)
	var leaf_col: Color = Color(0.32, 0.78, 0.34) if ready_crop else Color(0.42, 0.54, 0.30)
	for gy in [-2.8, 2.8]:
		_rect(Vector2(0, gy), Vector2(9.2, 1.4), Color(0.24, 0.16, 0.09)) # Surco
		for gx in [-6.0, -2.0, 2.0, 6.0]:
			_rect(Vector2(gx, gy - 0.5), Vector2(1.6, 1.6), leaf_col) # Matas del huerto


func _draw_player_shop_counter_2d() -> void:
	# Mostrador comercial de madera con paño de exposición de mercancía y caja de recaudación con herrajes
	_rect(Vector2(0, 1.5), Vector2(11.0, 6.2), Color(0.14, 0.10, 0.06, 0.55)) # Sombra
	_rect(Vector2(0, 0), Vector2(10.2, 5.2), Color(0.46, 0.30, 0.16)) # Mueble del mostrador
	_rect(Vector2(0, 0), Vector2(9.0, 4.1), Color(0.58, 0.40, 0.22)) # Tablero superior
	_rect(Vector2(-3.4, 0), Vector2(4.4, 3.0), Color(0.72, 0.18, 0.20)) # Paño de exposición
	var ps: Dictionary = VillageHousing.state(vm).get("player_shop", {}) if vm != null else {}
	var stk: int = int(ps.get("stock", 0))
	var till_g: int = int(ps.get("till_gold", 0))
	if stk > 0:
		_rect(Vector2(-5.0, -0.4), Vector2(1.8, 1.8), Color(0.86, 0.68, 0.34)) # Fardo / mercancía 1
		if stk >= 2:
			_rect(Vector2(-1.8, 0.4), Vector2(1.8, 1.8), Color(0.38, 0.76, 0.42)) # Fardo / mercancía 2
	_rect(Vector2(4.6, -0.2), Vector2(2.8, 2.6), Color(0.26, 0.30, 0.34)) # Caja de caudales de hierro
	_rect(Vector2(4.6, -0.2), Vector2(2.0, 1.8), Color(0.95, 0.78, 0.24) if till_g > 0 else Color(0.52, 0.44, 0.26)) # Monedas / cerradura


func _draw_town_ledger_2d() -> void:
	# Libro de cuentas abierto sobre la mesa
	_rect(Vector2(0, 0.8), Vector2(6.4, 4.4), Color(0.14, 0.10, 0.06, 0.5)) # Sombra
	_rect(Vector2(0, 0), Vector2(6.0, 4.0), Color(0.40, 0.20, 0.10)) # Tapas de cuero
	_rect(Vector2(-2.9, 0), Vector2(2.7, 3.4), Color(0.94, 0.89, 0.74)) # Página izquierda
	_rect(Vector2(2.9, 0), Vector2(2.7, 3.4), Color(0.94, 0.89, 0.74)) # Página derecha
	_rect(Vector2(0, 0), Vector2(0.4, 3.6), Color(0.30, 0.16, 0.08)) # Lomo


func _draw_home_table_2d() -> void:
	# Mesa de comedor de madera con mantel y 6 taburetes alrededor
	_rect(Vector2(0, 1.5), Vector2(10.5, 6.8), Color(0.14, 0.10, 0.06, 0.55)) # Sombra
	_rect(Vector2(0, 0), Vector2(9.6, 5.8), Color(0.48, 0.32, 0.18)) # Tablero de roble
	_rect(Vector2(0, 0), Vector2(8.4, 4.6), Color(0.58, 0.40, 0.24)) # Superficie pulida
	_rect(Vector2(0, 0), Vector2(4.2, 3.4), Color(0.86, 0.80, 0.68)) # Camino de mesa de lino
	var rations: int = int(VillageHousing.state(vm).get("table_rations", 0)) if vm != null else 0
	if rations > 0:
		_rect(Vector2(-2.2, -0.4), Vector2(1.6, 1.6), Color(0.88, 0.66, 0.28)) # Hogaza / plato
		_rect(Vector2(2.2, 0.4), Vector2(1.6, 1.6), Color(0.76, 0.28, 0.22)) # Estofado / jarra


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
		"sewer_grate":
			if vm != null and int(vm.player_elevation_level) != 0:
				return ""
			if vm != null and _player != null and vm.has_method("_is_pos_inside_any_building") and bool(vm.call("_is_pos_inside_any_building", _player.global_position)):
				return ""
			var unlocked: bool = vm != null and bool(VillageUnderworld.sewers_state(vm).get("unlocked", false))
			if not unlocked:
				return "Cerrada: el perista vende la llave"
			return "Bajar a las alcantarillas (%s)" % (heist_label if not heist_label.is_empty() else "acceso")
		"sewer_ladder":
			if vm != null and not VillageUnderworld.is_player_in_sewers(vm):
				return ""
			return "Subir a la calle (%s)" % (heist_label if not heist_label.is_empty() else "superficie")
		"sewer_chest":
			if vm != null and not VillageUnderworld.is_player_in_sewers(vm):
				return ""
			if vm != null and VillageUnderworld.is_sewer_chest_looted_today(vm, sewer_loc_id):
				return "Cofre de contrabando (vacío hoy)"
			return "Abrir cofre de contrabando (%s)" % (heist_label if not heist_label.is_empty() else "alijo")
		"home_workbench":
			return "Usar banco de trabajo y alquimia"
		"home_table":
			return VillageHousing.get_home_table_label(vm) if vm != null else "Mesa del comedor"
		"home_stash":
			var hidden_g: int = int(VillageHousing.state(vm).get("stash_gold", 0)) if vm != null else 0
			return "Escondite bajo las tablas (%d Oro oculto)" % hidden_g
		"home_stairs":
			return VillageHousing.get_home_stairs_label(vm, heist_id) if vm != null else "Usar escalera / trampilla"
		"home_garden":
			return VillageHousing.get_home_garden_label(vm, heist_id) if vm != null else "Cosechar el huerto de casa"
		"player_shop_counter":
			return VillageHousing.get_player_shop_counter_label(vm) if vm != null else "Mostrador y caja de tu tienda"
		"collect_point":
			var cp: PackedStringArray = heist_id.split(":")
			return VillageCollections.collect_label(vm, cp[0], int(cp[1])) if vm != null and cp.size() == 2 else ""
		"town_coffers":
			return VillageCollections.embezzle_label(vm) if vm != null else ""
		"town_ledger":
			return VillageCollections.ledger_label(vm) if vm != null else ""
		"masterwork_counter":
			return VillageFame.masterwork_counter_label(vm, vm._get_npcs_by_person_key().get(heist_id, null)) if vm != null else ""
		"club_trapdoor":
			return VillageClub.trapdoor_label(vm) if vm != null else ""
		"club_ladder":
			return "Subir a la taberna" if vm != null and VillageClub.is_player_in_club(vm) else ""
		"club_ring":
			return VillageClub.ring_label(vm, _player) if vm != null else ""
		"club_bet":
			return VillageClub.bet_label(vm, VillageClub.fighter_key_at(vm, heist_id)) if vm != null else ""
		"tavern_stairs":
			return VillageTavern.stairs_label(vm)
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
		"sewer_grate":
			VillageUnderworld.interact_sewer_grate(vm, sewer_loc_id, player)
		"sewer_ladder":
			VillageUnderworld.exit_sewer_ladder(vm, sewer_loc_id, player)
		"sewer_chest":
			var inv = player.get("inventory")
			VillageUnderworld.interact_sewer_chest(vm, sewer_loc_id, player, inv)
		"home_workbench":
			VillageHousing.open_home_workbench_menu(vm, self, player)
		"home_table":
			VillageHousing.open_home_table_menu(vm, self, player)
		"home_stash":
			VillageHousing.open_home_stash_menu(vm, self, player)
		"home_stairs":
			VillageHousing.interact_home_stairs(vm, heist_id, self, player)
		"home_garden":
			VillageHousing.interact_home_garden(vm, heist_id, player)
		"player_shop_counter":
			VillageHousing.open_player_shop_counter_menu(vm, self, player)
		"collect_point":
			var cp: PackedStringArray = heist_id.split(":")
			if cp.size() == 2:
				VillageCollections.collect(vm, cp[0], int(cp[1]), player)
		"town_coffers":
			VillageCollections.embezzle(vm, player)
		"town_ledger":
			VillageCollections.cook_books(vm, player)
		"masterwork_counter":
			VillageFame.buy_at_counter(vm, vm._get_npcs_by_person_key().get(heist_id, null), player)
		"club_trapdoor":
			VillageClub.go_down(vm, player)
		"club_ladder":
			VillageClub.go_up(vm, player)
		"club_ring":
			VillageClub.start_player_bout(vm, player)
		"club_bet":
			VillageClub.place_bet(vm, player, VillageClub.fighter_key_at(vm, heist_id))
		"tavern_stairs":
			VillageTavern.use_stairs(vm, player)


func on_dialogue_action(action_id: String) -> void:
	if vm == null:
		return
	var player: Node2D = null
	if is_inside_tree():
		player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		player = vm.VillageNeeds.player_of(vm)
	var inv = player.get("inventory") if player != null else null
	if action_id.begins_with("housing_"):
		VillageHousing.on_player_action(vm, null, action_id, inv)
	elif action_id.begins_with("underworld_"):
		VillageUnderworld.on_player_action(vm, null, action_id, inv)
	else:
		VillageCulture.on_player_action(vm, null, action_id, inv)
