@tool
extends Node2D
class_name VillageManager

## Gestor Integral de Urbanismo Sólido, Hospital/Morgue Forense, Comisaría/Cárcel, Testigos,
## Sigilo Doméstico, Reputación Familiar, Tablón de Encargos y Red Eléctrica (10 Pasos de Expansión)

var entities_root: Node = null

var trade_npcs: Dictionary = {}    # TradeRole -> VillageNPC (Titular actual del oficio)
var family_npcs: Dictionary = {}   # TradeRole -> VillageNPC (Familiar directo de esa casa)
var unemployed_npcs: Array[VillageNPC] = []
var authority_npcs: Array[VillageNPC] = [] # Dr. Valen, Comisario Vane, Guardia Rodric
const AUTHORITY_REHIRE_TIME_SECONDS: float = 75.0
var _authority_slots: Array[Dictionary] = []
var _rehire_counter: int = 0
var trade_configs: Dictionary = {}
var domestic_pets: Array[DomesticPet] = []

# Registro de Edificios con Paredes Sólidas y Puertas para Navegación y Testigos
var building_footprints: Array[Dictionary] = []
var _wall_occluder_rects: Array[Rect2] = []

# Paso 1: Hospital de Urgencias y Morgue Forense
var _hospital_center := Vector2(745, 148)
var _hospital_bed_pos := Vector2(710, 132)
var _morgue_table_positions: Array[Vector2] = [
	Vector2(712, 174),
	Vector2(745, 174),
	Vector2(778, 174)
]
var _morgue_corpse_sprites: Array[Sprite2D] = []
var corpse_records: Array[Dictionary] = []
var _hospital_bed_label: Label = null
var _morgue_label: Label = null

# Paso 2: Comisaría, Cárcel y Sistema Realista de Testigos ("Me vieron entrar a la casa")
var _police_center := Vector2(915, 148)
var _jail_cell_pos := Vector2(886, 172)
var wanted_level: int = 0
var bounty_gold: int = 0
var player_in_jail: bool = false
var player_being_escorted_to_jail: bool = false
var escorting_officer: VillageNPC = null
const JAIL_MANDATORY_STAY_SECONDS: float = 10.0
var jail_mandatory_stay_timer: float = 0.0
var _last_confronting_officer: VillageNPC = null
var is_resisting_arrest: bool = false
var sighting_log: Array[Dictionary] = [] # [{building_id, building_title, witness_name, hour, minute, day, timestamp}]
var crime_history: Array[String] = []
var _last_player_building_id: String = ""
var _sighting_check_timer: float = 0.0
var _police_confront_cooldown: float = 0.0
var _jail_label: Label = null
var _jail_cell_gate_body: StaticBody2D = null
var _jail_cell_gate_col: CollisionShape2D = null
var _jail_cell_gate_spr_closed: Sprite2D = null
var _jail_cell_gate_spr_open: Sprite2D = null

# Paso 3: Cofres Domésticos, Puertas con Cerradura/Cerrojo y Ventanas Forzables
var house_chests: Array[Dictionary] = [] # [{pos, sprite, label, title, family_id, looted_day}]
var building_doors: Array[Dictionary] = []
var building_windows: Array[Dictionary] = []
var recent_breakins_count: int = 0

# Paso 5: Tablón de Encargos en la Plaza Central
var _notice_board_pos := Vector2(465, 24)
var _notice_board_label: Label = null
var completed_contracts_today: Dictionary = {}

# Paso 10: Farolas Eléctricas del Pueblo
var streetlights: Array[Dictionary] = []

var _well_label: Label = null
var _compost_label: Label = null
var _tavern_bed_label: Label = null
var _tavern_games_label: Label = null
var _tavern_pool_label: Label = null

var _tavern_bed_pos := Vector2(538, -252)
var _tavern_social_pos := Vector2(375, -182)
var _tavern_games_pos := Vector2(465, -172)
var _tavern_pool_pos := Vector2(526, -172)
var _well_pos := Vector2(184, 82)
var _compost_pos := Vector2(184, 114)

# Capas de Interfaz para Morgue Forense, Arresto/Cárcel y Tablón de Encargos
var ui_layer: CanvasLayer = null
var morgue_panel: PanelContainer = null
var morgue_info_lbl: Label = null
var police_panel: PanelContainer = null
var police_info_lbl: Label = null
var board_panel: PanelContainer = null
var board_info_lbl: Label = null

func get_poker_chair_positions() -> Array[Vector2]:
	return [
		_tavern_games_pos + Vector2(-24, 0),
		_tavern_games_pos + Vector2(24, 0),
		_tavern_games_pos + Vector2(0, -18)
	]

func setup_village(target_entities_root: Node) -> void:
	entities_root = target_entities_root if target_entities_root else self
	var in_editor := Engine.is_editor_hint()
	set_process(not in_editor)
	set_process_unhandled_input(not in_editor)
	add_to_group("village_manager")

	building_footprints.clear()
	_wall_occluder_rects.clear()
	house_chests.clear()
	building_doors.clear()
	building_windows.clear()
	streetlights.clear()
	_authority_slots.clear()

	_spawn_village_roads_and_plaza()
	_spawn_western_plains_and_frog_marsh()
	_spawn_tavern_and_rooms()
	_spawn_five_family_houses_and_trades()
	_spawn_hospital_and_morgue()
	_spawn_police_station_and_jail()
	_spawn_notice_board_in_plaza()
	_spawn_electric_streetlights()
	_spawn_unemployed_tavern_guests()
	_spawn_farm_well_and_compost()
	_spawn_domestic_pets()

	if not in_editor:
		_setup_Interactive_modals_ui()
		if WorldClock:
			if not WorldClock.day_passed.is_connected(_on_day_passed):
				WorldClock.day_passed.connect(_on_day_passed)
			if not WorldClock.hour_passed.is_connected(_on_hour_passed):
				WorldClock.hour_passed.connect(_on_hour_passed)
			_apply_hourly_door_security_schedule(WorldClock.current_hour)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _police_confront_cooldown > 0.0:
		_police_confront_cooldown -= delta

	var player = get_tree().get_first_node_in_group("player") as Node2D
	var mouse_pos := get_global_mouse_position()
	var real_delta: float = delta / maxf(1.0, Engine.time_scale)

	# Escolta física policial hacia la celda de la Comisaría (Estilo Kenshi / Red Dead Redemption 2)
	if player_being_escorted_to_jail and player:
		if is_instance_valid(escorting_officer) and not escorting_officer.is_dead and not escorting_officer.is_downed:
			var follow_pos: Vector2 = escorting_officer.global_position + Vector2(-10, 6)
			if player.global_position.distance_to(escorting_officer.global_position) > 30.0:
				player.global_position = follow_pos
			else:
				player.global_position = player.global_position.move_toward(follow_pos, 92.0 * delta)
			if "velocity" in player:
				player.velocity = Vector2.ZERO
			if escorting_officer.global_position.distance_to(_jail_cell_pos) <= 22.0:
				complete_police_escort_to_jail(player)
		else:
			var nav_wp: Vector2 = get_navigation_waypoint(player.global_position, _jail_cell_pos, player)
			player.global_position = player.global_position.move_toward(nav_wp, 74.0 * delta)
			if player.global_position.distance_to(_jail_cell_pos) <= 20.0:
				complete_police_escort_to_jail(player)

	# Si el jugador está cumpliendo condena dentro de la celda de la cárcel, mantenerlo dentro y descontar el tiempo mínimo en celda
	if player_in_jail and player:
		if jail_mandatory_stay_timer > 0.0:
			jail_mandatory_stay_timer = maxf(0.0, jail_mandatory_stay_timer - real_delta)
		var cell_rect := Rect2(_jail_cell_pos - Vector2(22, 16), Vector2(44, 32))
		if not cell_rect.has_point(player.global_position):
			player.global_position = _jail_cell_pos

	# Paso 2: Rastreo realista de entrada/salida a edificios por testigos
	_sighting_check_timer -= delta
	if _sighting_check_timer <= 0.0:
		_sighting_check_timer = 0.35
		_track_player_building_sightings(player)
		_update_streetlights_glow()

	if _tavern_bed_label:
		_tavern_bed_label.visible = _is_near(player, mouse_pos, _tavern_bed_pos, 24.0, 18.0)
	if _tavern_games_label:
		_tavern_games_label.visible = _is_near(player, mouse_pos, _tavern_games_pos, 26.0, 20.0)
	if _tavern_pool_label:
		_tavern_pool_label.visible = _is_near(player, mouse_pos, _tavern_pool_pos, 26.0, 20.0)
	if _well_label:
		_well_label.visible = _is_near(player, mouse_pos, _well_pos, 22.0, 16.0)
	if _compost_label:
		_compost_label.visible = _is_near(player, mouse_pos, _compost_pos, 22.0, 16.0)
	if _hospital_bed_label:
		_hospital_bed_label.visible = _is_near(player, mouse_pos, _hospital_bed_pos, 26.0, 18.0)
	if _morgue_label:
		var m_center := _morgue_table_positions[1]
		_morgue_label.visible = _is_near(player, mouse_pos, m_center, 34.0, 24.0)
		if _morgue_label.visible:
			_morgue_label.text = "⚰️ Morgue Forense (%d Cuerpos) [E: Examinar Autopsias]" % corpse_records.size()
	if _jail_label:
		_jail_label.visible = player_in_jail or player_being_escorted_to_jail or _is_near(player, mouse_pos, _jail_cell_pos, 30.0, 20.0)
		if _jail_label.visible:
			if player_being_escorted_to_jail:
				_jail_label.text = "🚔⛓️ Siendo escoltado físicamente hacia la Celda de la Comisaría..."
			elif player_in_jail and jail_mandatory_stay_timer > 0.0:
				_jail_label.text = "🔒 Celda Policial — Tiempo obligatorio en celda: %ds antes de usar el Camastro [E: Opciones]" % int(ceil(jail_mandatory_stay_timer))
			elif player_in_jail:
				_jail_label.text = "🔒🛏️ Camastro de la Celda Listo [E: Acostarse y cumplir condena orgánica hasta las 06:00 AM]"
			else:
				_jail_label.text = "🚓 Celda Policial (Nivel Búsqueda: %d | Multa: %d Oro) [E: Gestionar]" % [wanted_level, bounty_gold]
	if _notice_board_label:
		_notice_board_label.visible = _is_near(player, mouse_pos, _notice_board_pos, 26.0, 18.0)

	for ch in house_chests:
		var c_lbl: Label = ch.get("label")
		var c_pos: Vector2 = ch.get("pos", Vector2.ZERO)
		if c_lbl:
			c_lbl.visible = _is_near(player, mouse_pos, c_pos, 22.0, 14.0)

	_update_doors_and_windows(delta, player, mouse_pos)
	_update_authority_rehiring(delta)

func _is_near(player: Node2D, mouse_pos: Vector2, target_pos: Vector2, p_rad: float, m_rad: float) -> bool:
	return (player != null and player.global_position.distance_squared_to(target_pos) <= p_rad * p_rad) or (target_pos.distance_squared_to(mouse_pos) <= m_rad * m_rad)

func _unhandled_input(event: InputEvent) -> void:
	if morgue_panel and morgue_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_1, KEY_ESCAPE, KEY_ENTER, KEY_E]:
				morgue_panel.visible = false
				get_viewport().set_input_as_handled()
		return

	if police_panel and police_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			var player = get_tree().get_first_node_in_group("player") as Node2D
			if event.keycode == KEY_1:
				_on_police_serve_sentence(player)
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_2:
				pay_bounty_fine(player)
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_3:
				_on_police_jailbreak_or_resist(player)
				get_viewport().set_input_as_handled()
			elif event.keycode in [KEY_4, KEY_ESCAPE]:
				police_panel.visible = false
				get_viewport().set_input_as_handled()
		return

	if board_panel and board_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			var player = get_tree().get_first_node_in_group("player") as Node2D
			if event.keycode == KEY_1:
				_complete_board_contract(player, 1)
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_2:
				_complete_board_contract(player, 2)
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_3:
				_complete_board_contract(player, 3)
				get_viewport().set_input_as_handled()
			elif event.keycode in [KEY_4, KEY_ESCAPE]:
				board_panel.visible = false
				get_viewport().set_input_as_handled()
		return

	# Tecla [B]: Echar o quitar el cerrojo / bloquear la puerta más cercana
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		var player = get_tree().get_first_node_in_group("player") as Node2D
		if player and toggle_bar_door_by_player(player):
			get_viewport().set_input_as_handled()

	# Tecla [F]: Forzar cerradura de puerta cerrada con llave, postigo de ventana o barrotes de celda (Separada de [E])
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		var player = get_tree().get_first_node_in_group("player") as Node2D
		if player and force_lock_or_shutter_by_player(player):
			get_viewport().set_input_as_handled()

# ==============================================================================
# CONSTRUCCIÓN SÓLIDA DE EDIFICIOS CON TEXTURAS Y COLISIÓN (`StaticBody2D`)
# ==============================================================================
func _construct_solid_building(
	b_id: String,
	b_title: String,
	center: Vector2,
	size: Vector2,
	door_on_south: bool,
	floor_tex_path: String,
	wall_h_path: String,
	wall_v_path: String,
	door_width: float = 42.0,
	door_offset_x: float = 0.0,
	title_color: Color = Color(0.96, 0.90, 0.68)
) -> void:
	var half := size * 0.5
	var rect := Rect2(center - half, size)
	var door_y: float = (center.y + half.y) if door_on_south else (center.y - half.y)
	var door_pos := Vector2(center.x + door_offset_x, door_y)

	building_footprints.append({
		"id": b_id,
		"title": b_title,
		"rect": rect,
		"door_pos": door_pos,
		"door_south": door_on_south
	})

	# 1. Suelo en mosaico (`TextureRect` con STRETCH_TILE)
	var floor_tex := _load_tex(floor_tex_path)
	if floor_tex:
		var f_rect := TextureRect.new()
		f_rect.texture = floor_tex
		f_rect.stretch_mode = TextureRect.STRETCH_TILE
		f_rect.position = rect.position
		f_rect.size = size
		f_rect.z_index = -2
		entities_root.add_child(f_rect)

	var tex_h := _load_tex(wall_h_path)
	var tex_v := _load_tex(wall_v_path)
	var wall_t: float = 7.0

	# 2. Paredes laterales Oeste y Este completas
	_add_solid_wall_segment(Vector2(rect.position.x, center.y), Vector2(wall_t, size.y), tex_v)
	_add_solid_wall_segment(Vector2(rect.end.x, center.y), Vector2(wall_t, size.y), tex_v)

	# 3. Pared opuesta a la puerta (completa) y Pared de la puerta (dividida en 2 tramos dejando la puerta abierta)
	var closed_y: float = (center.y - half.y) if door_on_south else (center.y + half.y)
	_add_solid_wall_segment(Vector2(center.x, closed_y), Vector2(size.x, wall_t), tex_h)

	var door_left_x: float = (center.x + door_offset_x) - door_width * 0.5
	var door_right_x: float = (center.x + door_offset_x) + door_width * 0.5
	var left_seg_w: float = maxf(8.0, door_left_x - rect.position.x)
	var right_seg_w: float = maxf(8.0, rect.end.x - door_right_x)

	_add_solid_wall_segment(Vector2(rect.position.x + left_seg_w * 0.5, door_y), Vector2(left_seg_w, wall_t), tex_h)
	_add_solid_wall_segment(Vector2(rect.end.x - right_seg_w * 0.5, door_y), Vector2(right_seg_w, wall_t), tex_h)

	# Umbral de puerta de madera/piedra
	var thresh := Polygon2D.new()
	thresh.polygon = PackedVector2Array([
		Vector2(-door_width * 0.5, -3), Vector2(door_width * 0.5, -3),
		Vector2(door_width * 0.5, 3), Vector2(-door_width * 0.5, 3)
	])
	thresh.color = Color(0.72, 0.54, 0.30, 0.85)
	thresh.global_position = door_pos
	thresh.z_index = -2
	entities_root.add_child(thresh)

	# Letrero superior del edificio
	var lbl := Label.new()
	lbl.text = b_title
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = center + Vector2(-125, -half.y - 19.0)
	lbl.custom_minimum_size = Vector2(250, 16)
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", title_color)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 3)
	entities_root.add_child(lbl)

	# 4. Puerta Física Interactiva (Abrir/Cerrar/Bloquear con Cerrojo/Forzar Cerradura) y Ventana Forzable
	_spawn_building_door_and_window(b_id, b_title, rect, door_pos, door_on_south, door_width)

func _spawn_building_door_and_window(
	b_id: String,
	b_title: String,
	rect: Rect2,
	door_pos: Vector2,
	door_on_south: bool,
	door_width: float
) -> void:
	var tex_door_closed := _load_tex("res://assests/world/village/door_wood_closed.png")
	var tex_door_open := _load_tex("res://assests/world/village/door_wood_open.png")
	var tex_win_open := _load_tex("res://assests/world/village/window_glass_open.png")

	# Cuerpo de colisión físico de la puerta (activo cuando está cerrada)
	var d_body := StaticBody2D.new()
	d_body.name = "DoorBody_" + b_id
	d_body.global_position = door_pos
	d_body.collision_layer = 1
	d_body.collision_mask = 0
	var d_col := CollisionShape2D.new()
	var d_rect_shape := RectangleShape2D.new()
	d_rect_shape.size = Vector2(maxf(20.0, door_width - 4.0), 7.0)
	d_col.shape = d_rect_shape
	d_col.disabled = false # Las puertas permanecen cerradas por defecto y se abren solo al cruzar el umbral
	d_body.add_child(d_col)
	entities_root.add_child(d_body)

	# Sprite de puerta cerrada / con llave
	var spr_closed := Sprite2D.new()
	spr_closed.texture = tex_door_closed
	spr_closed.global_position = door_pos
	spr_closed.scale = Vector2(door_width / 42.0, 1.0)
	spr_closed.visible = true
	spr_closed.z_index = 3
	entities_root.add_child(spr_closed)

	# Sprite de hoja de puerta abierta hacia el interior del marco
	var spr_open := Sprite2D.new()
	spr_open.texture = tex_door_open
	spr_open.global_position = door_pos + Vector2(-door_width * 0.5 + 4.0, -15.0 if door_on_south else 15.0)
	spr_open.visible = false
	spr_open.z_index = 2
	entities_root.add_child(spr_open)

	_add_station_area("DoorArea_" + b_id, door_pos, 14.0, "building_door")
	var d_lbl := _make_station_label(door_pos + Vector2(-125, -26), "🚪 Puerta de %s" % b_title)
	entities_root.add_child(d_lbl)

	building_doors.append({
		"building_id": b_id,
		"building_title": b_title,
		"building_rect": rect,
		"pos": door_pos,
		"door_south": door_on_south,
		"width": door_width,
		"body": d_body,
		"col": d_col,
		"spr_closed": spr_closed,
		"spr_open": spr_open,
		"label": d_lbl,
		"occluder_rect": Rect2(door_pos - Vector2(door_width * 0.5, 4.0), Vector2(door_width, 8.0)),
		"is_open": false,
		"is_locked": false,
		"locked_by_player": false,
		"manual_override_timer": 0.0,
		"npc_pass_timer": 0.0,
		"police_breach_timer": 0.0
	})

	# Ventana Forzable en la fachada del edificio (al lado de la puerta)
	var win_x: float = door_pos.x - door_width * 0.5 - 18.0
	if win_x < rect.position.x + 15.0:
		win_x = door_pos.x + door_width * 0.5 + 18.0
	win_x = clampf(win_x, rect.position.x + 14.0, rect.end.x - 14.0)
	var win_pos := Vector2(win_x, door_pos.y)

	var spr_win := Sprite2D.new()
	spr_win.texture = tex_win_open
	spr_win.global_position = win_pos
	spr_win.z_index = 3
	entities_root.add_child(spr_win)

	_add_station_area("WindowArea_" + b_id, win_pos, 11.0, "building_window")
	var w_lbl := _make_station_label(win_pos + Vector2(-125, -24), "🪟 Ventana de %s" % b_title)
	entities_root.add_child(w_lbl)

	building_windows.append({
		"building_id": b_id,
		"building_title": b_title,
		"building_rect": rect,
		"pos": win_pos,
		"door_south": door_on_south,
		"sprite": spr_win,
		"label": w_lbl,
		"is_shuttered": false
	})

func _add_solid_wall_segment(pos: Vector2, sz: Vector2, tex: Texture2D, blocks_vision: bool = true) -> void:
	var sb := StaticBody2D.new()
	sb.global_position = pos
	sb.collision_layer = 1
	sb.collision_mask = 0
	sb.set_meta("blocks_vision", blocks_vision)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = sz
	col.shape = rect
	sb.add_child(col)

	if blocks_vision:
		_wall_occluder_rects.append(Rect2(pos - sz * 0.5, sz))

	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.position = -sz * 0.5
		tr.size = sz
		tr.z_index = 2
		sb.add_child(tr)
	entities_root.add_child(sb)

func _segment_intersects_rect(p1: Vector2, p2: Vector2, r: Rect2) -> bool:
	var min_x: float = minf(p1.x, p2.x)
	var max_x: float = maxf(p1.x, p2.x)
	var min_y: float = minf(p1.y, p2.y)
	var max_y: float = maxf(p1.y, p2.y)
	if max_x < r.position.x or min_x > r.end.x or max_y < r.position.y or min_y > r.end.y:
		return false
	if r.has_point(p1) or r.has_point(p2):
		return true
	var tl := r.position
	var tr := Vector2(r.end.x, r.position.y)
	var br := r.end
	var bl := Vector2(r.position.x, r.end.y)
	if Geometry2D.segment_intersects_segment(p1, p2, tl, tr) != null:
		return true
	if Geometry2D.segment_intersects_segment(p1, p2, tr, br) != null:
		return true
	if Geometry2D.segment_intersects_segment(p1, p2, br, bl) != null:
		return true
	if Geometry2D.segment_intersects_segment(p1, p2, bl, tl) != null:
		return true
	return false

## Comprueba si existe línea de visión directa sin paredes sólidas ni puertas cerradas interponiéndose entre `from_pos` y `to_pos`
func has_line_of_sight(from_pos: Vector2, to_pos: Vector2) -> bool:
	if from_pos.distance_squared_to(to_pos) <= 4.0:
		return true
	for w_rect in _wall_occluder_rects:
		if _segment_intersects_rect(from_pos, to_pos, w_rect):
			return false
	for d_entry in building_doors:
		if not bool(d_entry.get("is_open", true)):
			var d_rect: Rect2 = d_entry["occluder_rect"]
			if _segment_intersects_rect(from_pos, to_pos, d_rect):
				return false
	return true

## Navegación inteligente por pasillos de puertas y tabiques internos (sin atascos ni giros contra muros)
func get_navigation_waypoint(from_pos: Vector2, to_pos: Vector2, agent: Node2D = null) -> Vector2:
	var lane_shift: float = 0.0
	if agent != null:
		lane_shift = float((abs(agent.name.hash()) % 5) - 2) * 2.0

	# PASADA 1: Si el origen está dentro (o en el umbral de la puerta) de un edificio y el destino está fuera de él,
	# primero salir limpiamente por los tabiques internos y el pasillo de la puerta de ese edificio.
	for b in building_footprints:
		var r_interior: Rect2 = b["rect"].grow(1.5)
		var r_inner: Rect2 = b["rect"].grow(-4.0)
		var d_pos: Vector2 = b["door_pos"]
		var r_door_threshold := Rect2(d_pos - Vector2(16.0, 11.0), Vector2(32.0, 22.0))
		if (r_interior.has_point(from_pos) or r_door_threshold.has_point(from_pos)) and not r_inner.has_point(to_pos):
			var b_id: String = str(b.get("id", ""))
			var door_south: bool = bool(b["door_south"])
			var lane_x: float = d_pos.x + lane_shift
			var inside_pt := Vector2(lane_x, d_pos.y + (-15.0 if door_south else 15.0))
			var outside_pt := Vector2(lane_x, d_pos.y + (18.0 if door_south else -18.0))

			# Primero salvar cualquier tabique interno hacia la antesala de la puerta principal
			var part_wp: Vector2 = _route_internal_building_partitions(b_id, from_pos, inside_pt)
			if part_wp != inside_pt:
				return part_wp

			var still_inside_wall: bool = (from_pos.y < d_pos.y - 2.0) if door_south else (from_pos.y > d_pos.y + 2.0)
			if still_inside_wall and absf(from_pos.x - lane_x) > 8.5:
				return inside_pt
			return outside_pt

	# PASADA 2: Si el destino está dentro de un edificio, entrar limpiamente por el pasillo exterior -> puerta -> interior
	for b in building_footprints:
		var r_target: Rect2 = b["rect"].grow(2.0)
		var r_deep: Rect2 = b["rect"].grow(-10.0)
		if r_target.has_point(to_pos):
			var b_id: String = str(b.get("id", ""))
			if not r_deep.has_point(from_pos):
				var d_pos2: Vector2 = b["door_pos"]
				var door_south2: bool = bool(b["door_south"])
				var lane_x2: float = d_pos2.x + lane_shift
				var outside_pt2 := Vector2(lane_x2, d_pos2.y + (18.0 if door_south2 else -18.0))
				var inside_pt2 := Vector2(lane_x2, d_pos2.y + (-15.0 if door_south2 else 15.0))

				var aligned_x: bool = absf(from_pos.x - lane_x2) <= 10.0
				var in_door_funnel_y: bool = (from_pos.y >= d_pos2.y - 15.0 and from_pos.y <= d_pos2.y + 24.0) if door_south2 else (from_pos.y >= d_pos2.y - 24.0 and from_pos.y <= d_pos2.y + 15.0)
				if aligned_x and in_door_funnel_y:
					return inside_pt2
				return _avoid_outdoor_buildings(from_pos, outside_pt2, "")
			else:
				# Ya está dentro del edificio destino; comprobar tabiques internos (Posada, Botica Mixta, Hospital, Comisaría)
				return _route_internal_building_partitions(b_id, from_pos, to_pos)

	# PASADA 3: Navegación exterior esquivando edificios intermedios
	return _avoid_outdoor_buildings(from_pos, to_pos, "")

func _route_internal_building_partitions(b_id: String, from_pos: Vector2, target_pos: Vector2) -> Vector2:
	match b_id:
		"building_tavern":
			# Tabique horizontal en y = -222 con hueco de paso en x = 425 (entre dormitorios Norte y salón Sur)
			if from_pos.y < -219.0 and target_pos.y > -225.0:
				if absf(from_pos.x - 425.0) > 10.0:
					return Vector2(425.0, -234.0)
				return Vector2(425.0, -206.0)
			elif from_pos.y > -225.0 and target_pos.y < -219.0:
				if absf(from_pos.x - 425.0) > 10.0:
					return Vector2(425.0, -206.0)
				return Vector2(425.0, -234.0)
		"mixed_family_herbalist":
			# Tabique horizontal en y = 159 con puerta central en x = 325 (entre tienda Norte y vivienda Sur)
			if from_pos.y > 156.0 and target_pos.y < 162.0:
				if absf(from_pos.x - 325.0) > 9.0:
					return Vector2(325.0, 171.0)
				return Vector2(325.0, 145.0)
			elif from_pos.y < 162.0 and target_pos.y > 156.0:
				if absf(from_pos.x - 325.0) > 9.0:
					return Vector2(325.0, 145.0)
				return Vector2(325.0, 171.0)
		"building_hospital":
			# Tabique horizontal en y = 152 con puerta central en x = 745 (entre Urgencias Norte y Morgue Sur)
			if from_pos.y < 149.0 and target_pos.y > 155.0:
				if absf(from_pos.x - 745.0) > 10.0:
					return Vector2(745.0, 138.0)
				return Vector2(745.0, 165.0)
			elif from_pos.y > 155.0 and target_pos.y < 149.0:
				if absf(from_pos.x - 745.0) > 10.0:
					return Vector2(745.0, 165.0)
				return Vector2(745.0, 138.0)
		"building_police":
			# Rejas de celdas en y = 152 con pasillo central en x = 915
			if from_pos.y < 149.0 and target_pos.y > 155.0:
				if absf(from_pos.x - 915.0) > 9.0:
					return Vector2(915.0, 138.0)
				return Vector2(915.0, 165.0)
			elif from_pos.y > 155.0 and target_pos.y < 149.0:
				if absf(from_pos.x - 915.0) > 9.0:
					return Vector2(915.0, 165.0)
				return Vector2(915.0, 138.0)
	return target_pos

func clamp_point_to_building_interior(ref_pos: Vector2, candidate_pos: Vector2) -> Vector2:
	for b in building_footprints:
		var r: Rect2 = b["rect"]
		if r.has_point(ref_pos):
			var r_safe: Rect2 = r.grow(-16.0)
			return Vector2(
				clampf(candidate_pos.x, r_safe.position.x, r_safe.end.x),
				clampf(candidate_pos.y, r_safe.position.y, r_safe.end.y)
			)
	return candidate_pos

## Evita que el paseo aleatorio de un NPC exterior (`UNEMPLOYED` o `GUARD`) caiga por accidente dentro de una casa o sobre su puerta
func clamp_point_outside_buildings(ref_pos: Vector2, candidate_pos: Vector2) -> Vector2:
	for b in building_footprints:
		var r_ref: Rect2 = b["rect"]
		if r_ref.has_point(ref_pos):
			return candidate_pos
	for b in building_footprints:
		var r_avoid: Rect2 = b["rect"].grow(14.0)
		if r_avoid.has_point(candidate_pos):
			return ref_pos
	return candidate_pos

## Si un NPC está parado justo en el umbral de una puerta (`<= radius`), devuelve un vector hacia adentro/afuera para despejar el paso
func get_doorway_clearance_nudge(pos: Vector2, radius: float = 18.0) -> Vector2:
	for d_entry in building_doors:
		var d_pos: Vector2 = d_entry.get("pos", Vector2.ZERO)
		if pos.distance_to(d_pos) <= radius:
			var b_rect: Rect2 = d_entry.get("building_rect", Rect2())
			var door_south: bool = bool(d_entry.get("door_south", true))
			var is_inside: bool = b_rect.has_point(pos)
			if is_inside:
				return Vector2(0.0, -1.0 if door_south else 1.0)
			else:
				return Vector2(0.0, 1.0 if door_south else -1.0)
	return Vector2.ZERO

func _avoid_outdoor_buildings(from_pos: Vector2, target_pos: Vector2, ignore_b_id: String) -> Vector2:
	var cur_target: Vector2 = target_pos
	for _step in range(2):
		var blocking_b: Dictionary = {}
		var closest_d: float = INF
		for b in building_footprints:
			var b_id: String = str(b.get("id", ""))
			if b_id == ignore_b_id:
				continue
			var r_core: Rect2 = b["rect"].grow(4.0)
			var r_avoid: Rect2 = b["rect"].grow(8.5)
			if r_core.has_point(from_pos) or r_core.has_point(cur_target):
				continue
			if _segment_intersects_rect(from_pos, cur_target, r_avoid):
				var d_center: float = from_pos.distance_to(r_avoid.get_center())
				if d_center < closest_d:
					closest_d = d_center
					blocking_b = b

		if blocking_b.is_empty():
			break

		# Si hay edificios contiguos con una separación estrecha (< 18 px) por donde no cabe un NPC,
		# fusionar sus huellas en un único bloque de esquiva para rodear la manzana por las calles exteriores.
		var merged_rect: Rect2 = blocking_b["rect"]
		var merged_changed := true
		while merged_changed:
			merged_changed = false
			for b_other in building_footprints:
				var r_o: Rect2 = b_other["rect"]
				if not merged_rect.encloses(r_o) and merged_rect.grow(9.0).intersects(r_o.grow(9.0)):
					merged_rect = merged_rect.merge(r_o)
					merged_changed = true

		var r_inner: Rect2 = merged_rect.grow(6.5)
		var r_corners: Rect2 = merged_rect.grow(16.0)
		var corners: Array[Vector2] = [
			r_corners.position,
			Vector2(r_corners.end.x, r_corners.position.y),
			r_corners.end,
			Vector2(r_corners.position.x, r_corners.end.y)
		]

		# 1º Buscar esquinas directamente alcanzables desde `from_pos` que tengan línea limpia hacia `cur_target`
		var best_direct_c: Vector2 = Vector2.INF
		var best_direct_score: float = INF
		# 2º Si el destino está en la cara opuesta del edificio, elegir la esquina alcanzable más cercana al destino (sin oscilación)
		var best_step_c: Vector2 = cur_target
		var best_step_score: float = INF

		for c in corners:
			if from_pos.distance_squared_to(c) < 25.0:
				continue
			var reachable_from_here: bool = not _segment_intersects_rect(from_pos, c, r_inner)
			if not reachable_from_here:
				continue
			var clear_to_target: bool = not _segment_intersects_rect(c, cur_target, r_inner)
			if clear_to_target:
				var d_score: float = from_pos.distance_to(c) + c.distance_to(cur_target)
				if d_score < best_direct_score:
					best_direct_score = d_score
					best_direct_c = c
			else:
				var s_score: float = c.distance_to(cur_target) + from_pos.distance_to(c) * 0.2
				if s_score < best_step_score:
					best_step_score = s_score
					best_step_c = c

		if best_direct_c != Vector2.INF:
			cur_target = best_direct_c
		else:
			cur_target = best_step_c
	return cur_target

# ==============================================================================
# RED DE CAMINOS Y BIOMAS EXTERIORES
# ==============================================================================
func _spawn_village_roads_and_plaza() -> void:
	var dirt_col := Color(0.46, 0.36, 0.24, 0.65)
	var stone_col := Color(0.42, 0.43, 0.46, 0.72)

	# 1. Camino Largo Oeste-Este desde la Llanura Salvaje (-465, 36) hasta el Distrito Institucional Este (1000, 48)
	_add_road_rect(Rect2(Vector2(-465, 36), Vector2(1465, 28)), dirt_col)
	_add_road_rect(Rect2(Vector2(20, 48), Vector2(22, 80)), dirt_col)

	# 2. Plaza Central Empedrada (x = 395..535, y = 10..88)
	_add_road_rect(Rect2(Vector2(395, 10), Vector2(140, 78)), stone_col)
	var plaza_border := Line2D.new()
	plaza_border.width = 2.0
	plaza_border.default_color = Color(0.62, 0.58, 0.48, 0.75)
	plaza_border.points = PackedVector2Array([
		Vector2(395, 10), Vector2(535, 10), Vector2(535, 88), Vector2(395, 88), Vector2(395, 10)
	])
	plaza_border.z_index = -3
	entities_root.add_child(plaza_border)

	# 3. Avenida Norte-Sur desde la Gran Posada (-135) hasta el Bosque Profundo (+630)
	_add_road_rect(Rect2(Vector2(448, -135), Vector2(34, 765)), dirt_col)
	_add_road_rect(Rect2(Vector2(140, 130), Vector2(24, 194)), dirt_col)
	_add_road_rect(Rect2(Vector2(140, 310), Vector2(312, 24)), dirt_col)
	_add_road_rect(Rect2(Vector2(-380, 606), Vector2(1040, 24)), dirt_col)
	_add_road_rect(Rect2(Vector2(130, 626), Vector2(26, 260)), dirt_col)

	# 4. Calles del Barrio Residencial y Distrito Hospital/Comisaría Este
	_add_road_rect(Rect2(Vector2(660, -135), Vector2(310, 24)), dirt_col)
	_add_road_rect(Rect2(Vector2(660, -135), Vector2(24, 240)), dirt_col)
	_add_road_rect(Rect2(Vector2(660, 76), Vector2(325, 22)), stone_col)

	_spawn_world_signpost(Vector2(-245, 12), "⬅️ Camino a la Llanura Salvaje y Ciénaga de Ranas", Color(1.0, 0.86, 0.48))
	_spawn_world_signpost(Vector2(465, 345), "⬇️ Sendero al Bosque Profundo (A 250m al Sur)", Color(0.76, 0.96, 0.68))
	_spawn_world_signpost(Vector2(668, 72), "➡️ Este: 🏥 Hospital y Morgue Forense | 🚓 Comisaría y Cárcel", Color(0.68, 0.92, 1.0))

func _spawn_world_signpost(pos: Vector2, text_str: String, text_col: Color) -> void:
	var sign_spr := Sprite2D.new()
	sign_spr.texture = _load_tex("res://assests/Comprados/ Packs/Cute_Fantasy/Buildings/House_Decor/sign_1.png")
	sign_spr.global_position = pos
	sign_spr.scale = Vector2(0.9, 0.9)
	sign_spr.z_index = -1
	entities_root.add_child(sign_spr)

	var lbl := Label.new()
	lbl.text = text_str
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = pos + Vector2(-155, -28)
	lbl.custom_minimum_size = Vector2(310, 16)
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", text_col)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 3)
	entities_root.add_child(lbl)

func _spawn_western_plains_and_frog_marsh() -> void:
	var plains_poly := Polygon2D.new()
	plains_poly.polygon = PackedVector2Array([
		Vector2(-860, -210), Vector2(-390, -210),
		Vector2(-390, 150), Vector2(-860, 150)
	])
	plains_poly.color = Color(0.58, 0.50, 0.26, 0.44)
	plains_poly.z_index = -4
	entities_root.add_child(plains_poly)

	var plains_border := Line2D.new()
	plains_border.width = 2.5
	plains_border.default_color = Color(0.66, 0.56, 0.30, 0.65)
	plains_border.points = PackedVector2Array([
		Vector2(-860, -210), Vector2(-390, -210),
		Vector2(-390, 150), Vector2(-860, 150), Vector2(-860, -210)
	])
	plains_border.z_index = -3
	entities_root.add_child(plains_border)

	var camp_floor := Polygon2D.new()
	camp_floor.polygon = PackedVector2Array([
		Vector2(-730, -125), Vector2(-495, -125),
		Vector2(-495, -18), Vector2(-730, -18)
	])
	camp_floor.color = Color(0.42, 0.33, 0.22, 0.62)
	camp_floor.z_index = -3
	entities_root.add_child(camp_floor)

	var marsh_mud := Polygon2D.new()
	marsh_mud.polygon = PackedVector2Array([
		Vector2(-705, 36), Vector2(-510, 36),
		Vector2(-495, 85), Vector2(-515, 134),
		Vector2(-695, 134), Vector2(-718, 85)
	])
	marsh_mud.color = Color(0.26, 0.36, 0.24, 0.75)
	marsh_mud.z_index = -3
	entities_root.add_child(marsh_mud)

	var marsh_water := Polygon2D.new()
	marsh_water.polygon = PackedVector2Array([
		Vector2(-680, 52), Vector2(-535, 52),
		Vector2(-522, 85), Vector2(-540, 118),
		Vector2(-675, 118), Vector2(-692, 85)
	])
	marsh_water.color = Color(0.16, 0.44, 0.42, 0.82)
	marsh_water.z_index = -2
	entities_root.add_child(marsh_water)

	_spawn_world_signpost(
		Vector2(-415, -14),
		"🌾 Llanura Salvaje del Oeste — ⚠️ N: Ruinas Hostiles | S: Ciénaga de Ranas",
		Color(1.0, 0.78, 0.36)
	)
	_spawn_world_signpost(
		Vector2(-605, 34),
		"🐸 Ciénaga de las Ranas de la Llanura",
		Color(0.62, 0.96, 0.68)
	)

func _add_road_rect(rect: Rect2, col: Color) -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	])
	poly.color = col
	poly.z_index = -3
	entities_root.add_child(poly)

# ==============================================================================
# EDIFICIO MIXTO #1: GRAN POSADA, TABERNA Y SALA DE CASINO/BILLAR
# ==============================================================================
func _spawn_tavern_and_rooms() -> void:
	var tex_bed := _load_tex("res://assests/world/village/tavern_bed.png")
	var tex_stall := _load_tex("res://assests/world/village/work_stall.png")
	var tex_innkeeper := _load_tex("res://assests/world/village/villager_innkeeper.png")
	var tex_wall_h := _load_tex("res://assests/world/village/wall_timber_h.png")

	# Construcción sólida con suelo de tablones de madera y colisión de paredes (260x145 px, centro (440, -207.5))
	_construct_solid_building(
		"building_tavern",
		"🍺 Gran Posada, Taberna y Casino 'El Jabalí Dorado'",
		Vector2(440, -208),
		Vector2(260, 145),
		true,
		"res://assests/world/village/floor_wood_planks.png",
		"res://assests/world/village/wall_timber_h.png",
		"res://assests/world/village/wall_timber_v.png",
		50.0,
		20.0,
		Color(1.0, 0.88, 0.45)
	)

	# Alfombra roja del Salón de Casino
	var carpet_poly := Polygon2D.new()
	carpet_poly.polygon = PackedVector2Array([
		Vector2(435, -202), Vector2(556, -202), Vector2(556, -144), Vector2(435, -144)
	])
	carpet_poly.color = Color(0.55, 0.14, 0.14, 0.62)
	carpet_poly.z_index = -1
	entities_root.add_child(carpet_poly)

	# Tabique interior con puerta amplia de paso hacia los dormitorios (x = 400..450 abierta)
	_add_solid_wall_segment(Vector2(355, -222), Vector2(90, 6), tex_wall_h)
	_add_solid_wall_segment(Vector2(510, -222), Vector2(120, 6), tex_wall_h)

	# Decoración de interiores (Estanterías y macetas de Cute_Fantasy)
	_spawn_decor_prop("res://assests/Comprados/ Packs/Cute_Fantasy/Buildings/House_Decor/bookcase_1.png", Vector2(325, -268))
	_spawn_decor_prop("res://assests/Comprados/ Packs/Cute_Fantasy/Buildings/House_Decor/flower_pot_1.png", Vector2(555, -148))

	# Mostrador de Cocina y Barra de Marta (Oeste)
	var bar_spr := Sprite2D.new()
	bar_spr.texture = tex_stall
	bar_spr.global_position = Vector2(348, -172)
	bar_spr.scale = Vector2(1.4, 1.4)
	entities_root.add_child(bar_spr)

	# Mesa Social de Comedor
	var table_poly := Polygon2D.new()
	table_poly.polygon = PackedVector2Array([
		Vector2(-20, -9), Vector2(20, -9), Vector2(20, 9), Vector2(-20, 9)
	])
	table_poly.color = Color(0.54, 0.35, 0.18, 0.98)
	table_poly.global_position = _tavern_social_pos
	table_poly.z_index = -1
	entities_root.add_child(table_poly)

	# 1. Mesa Verde de Póker / Blackjack / Ruleta
	var games_rim := Polygon2D.new()
	games_rim.polygon = PackedVector2Array([
		Vector2(-20, -12), Vector2(20, -12), Vector2(20, 12), Vector2(-20, 12)
	])
	games_rim.color = Color(0.42, 0.26, 0.12, 1.0)
	games_rim.global_position = _tavern_games_pos
	games_rim.z_index = -1
	entities_root.add_child(games_rim)

	var games_felt := Polygon2D.new()
	games_felt.polygon = PackedVector2Array([
		Vector2(-16, -8), Vector2(16, -8), Vector2(16, 8), Vector2(-16, 8)
	])
	games_felt.color = Color(0.10, 0.50, 0.25, 1.0)
	games_felt.global_position = _tavern_games_pos
	games_felt.z_index = -1
	entities_root.add_child(games_felt)

	for chair_offset in [Vector2(-24, 0), Vector2(24, 0), Vector2(0, -16), Vector2(0, 16)]:
		var chair := Polygon2D.new()
		chair.polygon = PackedVector2Array([Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4)])
		chair.color = Color(0.55, 0.36, 0.18, 0.95)
		chair.global_position = _tavern_games_pos + chair_offset
		chair.z_index = -1
		entities_root.add_child(chair)

	_add_station_area("TavernGamesTableArea", _tavern_games_pos, 16.0, "tavern_games")
	_tavern_games_label = _make_station_label(_tavern_games_pos + Vector2(-120, -30), "🃏 Mesa de Póker y Casino [E: Jugar con Aldeanos]")
	entities_root.add_child(_tavern_games_label)

	# 2. Mesa de Billar de la Posada
	var pool_rim := Polygon2D.new()
	pool_rim.polygon = PackedVector2Array([
		Vector2(-22, -12), Vector2(22, -12), Vector2(22, 12), Vector2(-22, 12)
	])
	pool_rim.color = Color(0.38, 0.22, 0.10, 1.0)
	pool_rim.global_position = _tavern_pool_pos
	pool_rim.z_index = -1
	entities_root.add_child(pool_rim)

	var pool_felt := Polygon2D.new()
	pool_felt.polygon = PackedVector2Array([
		Vector2(-18, -8), Vector2(18, -8), Vector2(18, 8), Vector2(-18, 8)
	])
	pool_felt.color = Color(0.08, 0.42, 0.32, 1.0)
	pool_felt.global_position = _tavern_pool_pos
	pool_felt.z_index = -1
	entities_root.add_child(pool_felt)

	_add_station_area("TavernPoolTableArea", _tavern_pool_pos, 16.0, "tavern_pool")
	_tavern_pool_label = _make_station_label(_tavern_pool_pos + Vector2(-115, -30), "🎱 Mesa de Billar [E: Jugar Billar de Posada]")
	entities_root.add_child(_tavern_pool_label)

	# Camas de la Posada
	var bed_positions: Array[Vector2] = [
		Vector2(342, -252),
		Vector2(435, -252),
		Vector2(468, -252),
		Vector2(502, -252),
		_tavern_bed_pos
	]
	for i in range(bed_positions.size()):
		var b_spr := Sprite2D.new()
		b_spr.texture = tex_bed
		b_spr.global_position = bed_positions[i]
		b_spr.scale = Vector2(1.18, 1.18)
		b_spr.z_index = -1
		entities_root.add_child(b_spr)

	_add_station_area("TavernPlayerBedArea", _tavern_bed_pos, 11.0, "tavern_bed")
	_tavern_bed_label = _make_station_label(_tavern_bed_pos + Vector2(-115, -28), "🛌 Cama de Posada [E: Dormir hasta 06:00 (-8 Oro)]")
	entities_root.add_child(_tavern_bed_label)

	# Cofre privado de la Posada (en el cuarto de Marta)
	_spawn_house_chest(Vector2(372, -256), "Cofre de la Posada El Jabalí", "family_tavern")

	var marta := VillageNPC.new()
	marta.name = "NPC_Marta_Innkeeper"
	marta.npc_name = "Marta"
	marta.npc_role = "Chef y Posadera"
	marta.trade_role = VillageNPC.TradeRole.INNKEEPER
	marta.tavern_social_pos = _tavern_social_pos
	entities_root.add_child(marta)
	marta.setup_npc(
		tex_innkeeper,
		Vector2(348, -154),
		Vector2(342, -252),
		{"country_stew": 5, "bread": 7, "roasted_chicken": 3},
		_tavern_social_pos,
		"family_tavern",
		"Posada El Jabalí"
	)

# ==============================================================================
# 4 LOCALES COMERCIALES + 4 CASAS RESIDENCIALES + BOTICA-VIVIENDA MIXTA
# ==============================================================================
func _spawn_five_family_houses_and_trades() -> void:
	var tex_stall := _load_tex("res://assests/world/village/work_stall.png")
	var tex_bed := _load_tex("res://assests/world/village/tavern_bed.png")
	var tex_family := _load_tex("res://assests/world/village/villager_traveler.png")

	trade_configs = {
		VillageNPC.TradeRole.BLACKSMITH: {
			"family_id": "family_smith",
			"family_name": "Familia Yunque Gris",
			"shop_title": "⚒️ Herrería y Armería 'Yunque Gris'",
			"shop_center": Vector2(335, -36),
			"shop_door_south": true,
			"is_mixed_building": false,
			"house_title": "🏠 Residencia Familia Yunque Gris",
			"house_center": Vector2(745, -195),
			"name": "Thoran",
			"title": "Maestro Herrero y Armero",
			"tex": _load_tex("res://assests/world/village/villager_smith.png"),
			"stock": {"iron_ore": 4, "repair_kit": 3},
			"kin_name": "Kael",
			"kin_title": "Hijo y Aprendiz de Forja"
		},
		VillageNPC.TradeRole.BUTCHER: {
			"family_id": "family_butcher",
			"family_name": "Familia Colmillo",
			"shop_title": "🥩 Carnicería y Peletería 'El Colmillo'",
			"shop_center": Vector2(585, -36),
			"shop_door_south": true,
			"is_mixed_building": false,
			"house_title": "🏠 Residencia Familia Colmillo",
			"house_center": Vector2(905, -195),
			"name": "Garrick",
			"title": "Maestro Carnicero",
			"tex": _load_tex("res://assests/world/village/villager_butcher.png"),
			"stock": {"cooked_meat": 5, "leather": 4, "roasted_chicken": 2},
			"kin_name": "Lina",
			"kin_title": "Esposa y Curtidora"
		},
		VillageNPC.TradeRole.CARPENTER: {
			"family_id": "family_carpenter",
			"family_name": "Familia Roble Viejo",
			"shop_title": "🪚 Carpintería y Aserradero 'Roble Viejo'",
			"shop_center": Vector2(585, 148),
			"shop_door_south": false,
			"is_mixed_building": false,
			"house_title": "🏠 Residencia Familia Roble Viejo",
			"house_center": Vector2(745, -36),
			"name": "Bram",
			"title": "Maestro Carpintero",
			"tex": _load_tex("res://assests/world/village/villager_carpenter.png"),
			"stock": {"repair_kit": 5, "wood": 8},
			"kin_name": "Mila",
			"kin_title": "Hermana y Ebanista"
		},
		VillageNPC.TradeRole.FISHMONGER: {
			"family_id": "family_fishmonger",
			"family_name": "Familia Aguas Claras",
			"shop_title": "🐟 Pescadería y Molino 'Aguas Claras'",
			"shop_center": Vector2(465, 148),
			"shop_door_south": false,
			"is_mixed_building": false,
			"house_title": "🏠 Residencia Familia Aguas Claras",
			"house_center": Vector2(905, -36),
			"name": "Marlo",
			"title": "Pescador y Molinero",
			"tex": _load_tex("res://assests/world/village/villager_fishmonger.png"),
			"stock": {"bread": 6, "fertilizer": 5, "cooked_fish": 4},
			"kin_name": "Nora",
			"kin_title": "Hija y Redera"
		},
		VillageNPC.TradeRole.HERBALIST: {
			"family_id": "family_herbalist",
			"family_name": "Familia Raíz Verde",
			"shop_title": "🌿 Botica y Casa-Jardín 'Raíz Verde'",
			"shop_center": Vector2(325, 155),
			"shop_door_south": false,
			"is_mixed_building": true,
			"house_title": "🌿 Botica y Vivienda Raíz Verde",
			"house_center": Vector2(325, 155),
			"name": "Elena",
			"title": "Herborista y Alquimista",
			"tex": _load_tex("res://assests/world/village/villager_herbalist.png"),
			"stock": {"carrot_seeds": 8, "cabbage_seeds": 8, "wheat_seeds": 8, "herbal_poultice": 4},
			"kin_name": "Tomás",
			"kin_title": "Esposo y Hortelano"
		}
	}

	for role_key in trade_configs.keys():
		var cfg: Dictionary = trade_configs[role_key]
		var is_mixed: bool = bool(cfg.get("is_mixed_building", false))
		var sc: Vector2 = cfg["shop_center"]
		var hc: Vector2 = cfg["house_center"]
		var fam_id: String = str(cfg["family_id"])

		var shop_door_s: bool = bool(cfg.get("shop_door_south", true))
		var work_pos: Vector2 = sc + (Vector2(0, -6) if shop_door_s else Vector2(0, 8))
		var bed1_pos: Vector2 = hc + Vector2(-30, -18)
		var bed2_pos: Vector2 = hc + Vector2(30, -18)
		var table_pos: Vector2 = hc + Vector2(0, -2)
		var kin_work_pos: Vector2 = hc + Vector2(-20, -2)

		if is_mixed:
			work_pos = sc + Vector2(0, -18)
			bed1_pos = sc + Vector2(-36, 26)
			bed2_pos = sc + Vector2(36, 26)
			table_pos = sc + Vector2(0, 24)
			kin_work_pos = sc + Vector2(-24, -14)
			_build_mixed_shop_house_visuals(sc, str(cfg["shop_title"]), tex_bed, tex_stall, bed1_pos, bed2_pos, table_pos, work_pos, fam_id)
		else:
			var is_smithy: bool = (role_key == VillageNPC.TradeRole.BLACKSMITH)
			_build_enclosed_shop_visuals(sc, str(cfg["shop_title"]), tex_stall, work_pos, bool(cfg["shop_door_south"]), is_smithy, fam_id)
			_build_residential_house_visuals(hc, str(cfg["house_title"]), tex_bed, bed1_pos, bed2_pos, table_pos, fam_id)

		cfg["work_pos"] = work_pos
		cfg["bed1_pos"] = bed1_pos
		cfg["bed2_pos"] = bed2_pos
		cfg["table_pos"] = table_pos

		var master_npc := VillageNPC.new()
		master_npc.name = "NPC_" + str(cfg["name"])
		master_npc.npc_name = str(cfg["name"])
		master_npc.npc_role = str(cfg["title"])
		master_npc.trade_role = role_key
		master_npc.linked_trade = role_key
		master_npc.tavern_social_pos = _tavern_social_pos
		entities_root.add_child(master_npc)
		master_npc.setup_npc(
			cfg["tex"],
			work_pos,
			bed1_pos,
			cfg["stock"],
			table_pos,
			fam_id,
			str(cfg["family_name"])
		)
		trade_npcs[role_key] = master_npc

		var kin_npc := VillageNPC.new()
		kin_npc.name = "NPC_Kin_" + str(cfg["kin_name"])
		kin_npc.npc_name = str(cfg["kin_name"])
		kin_npc.npc_role = str(cfg["kin_title"])
		kin_npc.trade_role = VillageNPC.TradeRole.FAMILY_MEMBER
		kin_npc.linked_trade = role_key
		kin_npc.tavern_social_pos = _tavern_social_pos
		entities_root.add_child(kin_npc)
		kin_npc.setup_npc(
			tex_family,
			kin_work_pos,
			bed2_pos,
			{},
			table_pos,
			fam_id,
			str(cfg["family_name"])
		)
		family_npcs[role_key] = kin_npc

func _build_enclosed_shop_visuals(
	sc: Vector2,
	shop_title: String,
	tex_stall: Texture2D,
	work_pos: Vector2,
	door_on_south: bool,
	is_blacksmith: bool,
	fam_id: String
) -> void:
	var floor_p: String = "res://assests/world/village/floor_stone_forge.png" if is_blacksmith else "res://assests/world/village/floor_wood_planks.png"
	var wall_h_p: String = "res://assests/world/village/wall_stone_h.png" if is_blacksmith else "res://assests/world/village/wall_timber_h.png"
	var wall_v_p: String = "res://assests/world/village/wall_stone_v.png" if is_blacksmith else "res://assests/world/village/wall_timber_v.png"

	_construct_solid_building(
		"shop_" + fam_id,
		shop_title,
		sc,
		Vector2(116, 76),
		door_on_south,
		floor_p,
		wall_h_p,
		wall_v_p,
		40.0,
		0.0,
		Color(1.0, 0.88, 0.52) if is_blacksmith else Color(0.95, 0.90, 0.68)
	)

	var stall := Sprite2D.new()
	stall.texture = tex_stall
	stall.global_position = work_pos + (Vector2(0, -10) if door_on_south else Vector2(0, 10))
	stall.scale = Vector2(1.32, 1.32)
	stall.z_index = -1
	entities_root.add_child(stall)

	# Cofre comercial del local (Paso 3)
	var chest_pos: Vector2 = sc + (Vector2(38, -20) if door_on_south else Vector2(38, 20))
	_spawn_house_chest(chest_pos, "Cofre de " + shop_title, fam_id)

	if is_blacksmith:
		_spawn_decor_prop("res://assests/Comprados/ Packs/Cute_Fantasy/Buildings/House_Decor/furnace.png", sc + Vector2(-36, -16))
		_spawn_decor_prop("res://assests/Comprados/ Packs/Cute_Fantasy/Buildings/House_Decor/anvil.png", sc + Vector2(26, -12))

func _build_residential_house_visuals(
	hc: Vector2,
	house_title: String,
	tex_bed: Texture2D,
	bed1_pos: Vector2,
	bed2_pos: Vector2,
	table_pos: Vector2,
	fam_id: String
) -> void:
	_construct_solid_building(
		"house_" + fam_id,
		house_title,
		hc,
		Vector2(112, 78),
		true,
		"res://assests/world/village/floor_wood_planks.png",
		"res://assests/world/village/wall_timber_h.png",
		"res://assests/world/village/wall_timber_v.png",
		38.0,
		0.0,
		Color(0.92, 0.88, 0.72)
	)

	var rug_poly := Polygon2D.new()
	rug_poly.polygon = PackedVector2Array([
		hc + Vector2(-24, -8), hc + Vector2(24, -8),
		hc + Vector2(24, 18), hc + Vector2(-24, 18)
	])
	rug_poly.color = Color(0.52, 0.24, 0.20, 0.55)
	rug_poly.z_index = -1
	entities_root.add_child(rug_poly)

	for b_pos in [bed1_pos, bed2_pos]:
		var bed := Sprite2D.new()
		bed.texture = tex_bed
		bed.global_position = b_pos
		bed.scale = Vector2(1.12, 1.12)
		bed.z_index = -1
		entities_root.add_child(bed)

	_spawn_decor_prop("res://assests/Comprados/ Packs/Cute_Fantasy/Buildings/House_Decor/table_1.png", table_pos)
	_spawn_house_chest(hc + Vector2(0, -24), "Cofre Familiar (" + house_title + ")", fam_id)

func _build_mixed_shop_house_visuals(
	center: Vector2,
	title: String,
	tex_bed: Texture2D,
	tex_stall: Texture2D,
	bed1_pos: Vector2,
	bed2_pos: Vector2,
	table_pos: Vector2,
	work_pos: Vector2,
	fam_id: String
) -> void:
	_construct_solid_building(
		"mixed_" + fam_id,
		title,
		center,
		Vector2(128, 96),
		false,
		"res://assests/world/village/floor_wood_planks.png",
		"res://assests/world/village/wall_timber_h.png",
		"res://assests/world/village/wall_timber_v.png",
		42.0,
		0.0,
		Color(0.75, 0.96, 0.68)
	)

	var tex_wall_h := _load_tex("res://assests/world/village/wall_timber_h.png")
	_add_solid_wall_segment(center + Vector2(-42, 4), Vector2(40, 6), tex_wall_h)
	_add_solid_wall_segment(center + Vector2(42, 4), Vector2(40, 6), tex_wall_h)

	var stall := Sprite2D.new()
	stall.texture = tex_stall
	stall.global_position = work_pos + Vector2(0, 8)
	stall.scale = Vector2(1.3, 1.3)
	stall.z_index = -1
	entities_root.add_child(stall)

	for b_pos in [bed1_pos, bed2_pos]:
		var bed := Sprite2D.new()
		bed.texture = tex_bed
		bed.global_position = b_pos
		bed.scale = Vector2(1.12, 1.12)
		bed.z_index = -1
		entities_root.add_child(bed)

	_spawn_decor_prop("res://assests/Comprados/ Packs/Cute_Fantasy/Buildings/House_Decor/table_1.png", table_pos)
	_spawn_house_chest(center + Vector2(42, -26), "Cofre de la Botica Raíz Verde", fam_id)

# ==============================================================================
# PASO 1: 🏥 HOSPITAL DE URGENCIAS Y ⚰️ MORGUE FORENSE (`Vector2(745, 148)`)
# ==============================================================================
func _spawn_hospital_and_morgue() -> void:
	_construct_solid_building(
		"building_hospital",
		"🏥 Hospital de Urgencias y ⚰️ Morgue Forense",
		_hospital_center,
		Vector2(138, 96),
		false,
		"res://assests/world/village/floor_hospital_tile.png",
		"res://assests/world/village/wall_stone_h.png",
		"res://assests/world/village/wall_stone_v.png",
		44.0,
		0.0,
		Color(0.68, 0.98, 0.88)
	)

	var tex_wall_h := _load_tex("res://assests/world/village/wall_stone_h.png")
	# Tabique divisorio entre Sala de Urgencias (Norte) y Morgue Forense (Sur) con puerta central amplia
	_add_solid_wall_segment(_hospital_center + Vector2(-46, 4), Vector2(44, 6), tex_wall_h)
	_add_solid_wall_segment(_hospital_center + Vector2(46, 4), Vector2(44, 6), tex_wall_h)

	# 2 Camas Clínicas de Urgencias en la Sala Norte
	var tex_hbed := _load_tex("res://assests/world/village/hospital_bed.png")
	for b_pos in [_hospital_bed_pos, Vector2(780, 132)]:
		var hbed := Sprite2D.new()
		hbed.texture = tex_hbed
		hbed.global_position = b_pos
		hbed.scale = Vector2(1.15, 1.15)
		hbed.z_index = -1
		entities_root.add_child(hbed)

	_add_station_area("HospitalEmergencyBedArea", _hospital_bed_pos, 16.0, "hospital_bed")
	_hospital_bed_label = _make_station_label(_hospital_bed_pos + Vector2(-120, -28), "🏥 Cama de Urgencias [E: Curar Heridas (-10 Oro)]")
	entities_root.add_child(_hospital_bed_label)

	# 3 Mesas de Autopsia en la Sala Sur (Morgue Forense)
	var tex_mtable := _load_tex("res://assests/world/village/morgue_table.png")
	var tex_corpse := _load_tex("res://assests/world/village/morgue_corpse_sheet.png")
	_morgue_corpse_sprites.clear()
	for m_pos in _morgue_table_positions:
		var mt := Sprite2D.new()
		mt.texture = tex_mtable
		mt.global_position = m_pos
		mt.scale = Vector2(1.15, 1.15)
		mt.z_index = -1
		entities_root.add_child(mt)

		var c_spr := Sprite2D.new()
		c_spr.texture = tex_corpse
		c_spr.global_position = m_pos
		c_spr.scale = Vector2(1.15, 1.15)
		c_spr.visible = false
		c_spr.z_index = 0
		entities_root.add_child(c_spr)
		_morgue_corpse_sprites.append(c_spr)

	_add_station_area("MorgueAutopsyArea", _morgue_table_positions[1], 24.0, "morgue_table")
	_morgue_label = _make_station_label(_morgue_table_positions[1] + Vector2(-125, -26), "⚰️ Morgue Forense [E: Examinar Autopsias]")
	entities_root.add_child(_morgue_label)

	# Dr. Valen (Médico Cirujano y Forense)
	var tex_doc := _load_tex("res://assests/world/village/villager_doctor.png")
	var dr_valen := VillageNPC.new()
	dr_valen.name = "NPC_Dr_Valen"
	dr_valen.npc_name = "Dr. Valen"
	dr_valen.npc_role = "Cirujano y Forense"
	dr_valen.trade_role = VillageNPC.TradeRole.DOCTOR
	dr_valen.tavern_social_pos = _tavern_social_pos
	entities_root.add_child(dr_valen)
	dr_valen.setup_npc(
		tex_doc,
		Vector2(745, 128),
		Vector2(780, 132),
		{"surgical_kit": 4, "herbal_poultice": 6},
		_tavern_social_pos,
		"family_hospital",
		"Cuerpo Médico del Valle"
	)
	authority_npcs.append(dr_valen)
	_authority_slots.append({
		"role": VillageNPC.TradeRole.DOCTOR,
		"npc": dr_valen,
		"rehire_timer": 0.0,
		"vacancy_announced": false,
		"work_pos": Vector2(745, 128),
		"bed_pos": Vector2(780, 132),
		"tex_path": "res://assests/world/village/villager_doctor.png",
		"stock": {"surgical_kit": 4, "herbal_poultice": 6},
		"family_id": "family_hospital",
		"family_name": "Cuerpo Médico del Valle",
		"title": "Cirujano y Forense",
		"name_pool": ["Dr. Silvano", "Dra. Valeria", "Dr. Aurelio", "Dra. Caelia", "Dr. Mirko"]
	})

# ==============================================================================
# PASO 2: 🚓 COMISARÍA, 🔒 CÁRCEL Y GUARDIAS DE LA LEY (`Vector2(915, 148)`)
# ==============================================================================
func _spawn_police_station_and_jail() -> void:
	_construct_solid_building(
		"building_police",
		"🚓 Comisaría de Policía y 🔒 Cárcel del Valle",
		_police_center,
		Vector2(142, 96),
		false,
		"res://assests/world/village/floor_stone_forge.png",
		"res://assests/world/village/wall_stone_h.png",
		"res://assests/world/village/wall_stone_v.png",
		44.0,
		0.0,
		Color(0.62, 0.85, 1.0)
	)

	var tex_bars_h := _load_tex("res://assests/world/village/jail_bars_h.png")
	var tex_bars_v := _load_tex("res://assests/world/village/jail_bars_v.png")
	var tex_bed := _load_tex("res://assests/world/village/tavern_bed.png")

	# Rejas de Hierro de las Celdas (Sur-Oeste y Sur-Este de la Comisaría) con Puerta de Reja Física en `Vector2(902, 152)`
	_add_solid_wall_segment(Vector2(868, 152), Vector2(42, 6), tex_bars_h, false)
	_add_solid_wall_segment(Vector2(962, 152), Vector2(42, 6), tex_bars_h, false)
	_add_solid_wall_segment(Vector2(915, 174), Vector2(6, 42), tex_bars_v, false)

	# Puerta de Barrotes de la Celda (`Vector2(902, 152)`): se bloquea al estar recluido y se abre físicamente al salir en libertad o fugarse
	_jail_cell_gate_body = StaticBody2D.new()
	_jail_cell_gate_body.name = "JailCellGateBody"
	_jail_cell_gate_body.global_position = Vector2(902, 152)
	_jail_cell_gate_body.collision_layer = 1
	_jail_cell_gate_body.collision_mask = 0
	_jail_cell_gate_col = CollisionShape2D.new()
	var gate_rect := RectangleShape2D.new()
	gate_rect.size = Vector2(26, 6)
	_jail_cell_gate_col.shape = gate_rect
	_jail_cell_gate_col.disabled = true
	_jail_cell_gate_body.add_child(_jail_cell_gate_col)
	entities_root.add_child(_jail_cell_gate_body)

	_jail_cell_gate_spr_closed = Sprite2D.new()
	_jail_cell_gate_spr_closed.texture = tex_bars_h
	_jail_cell_gate_spr_closed.global_position = Vector2(902, 152)
	_jail_cell_gate_spr_closed.scale = Vector2(0.85, 1.0)
	_jail_cell_gate_spr_closed.visible = false
	_jail_cell_gate_spr_closed.z_index = 2
	entities_root.add_child(_jail_cell_gate_spr_closed)

	_jail_cell_gate_spr_open = Sprite2D.new()
	_jail_cell_gate_spr_open.texture = tex_bars_v
	_jail_cell_gate_spr_open.global_position = Vector2(890, 141)
	_jail_cell_gate_spr_open.scale = Vector2(1.0, 0.75)
	_jail_cell_gate_spr_open.visible = true
	_jail_cell_gate_spr_open.z_index = 2
	entities_root.add_child(_jail_cell_gate_spr_open)

	for c_bed_pos in [Vector2(872, 176), Vector2(958, 176), Vector2(862, 132), Vector2(968, 132)]:
		var cbed := Sprite2D.new()
		cbed.texture = tex_bed
		cbed.global_position = c_bed_pos
		cbed.scale = Vector2(1.0, 1.0)
		cbed.modulate = Color(0.75, 0.78, 0.85, 1.0)
		cbed.z_index = -1
		entities_root.add_child(cbed)

	_spawn_decor_prop("res://assests/Comprados/ Packs/Cute_Fantasy/Buildings/House_Decor/table_1.png", Vector2(890, 126))
	_add_station_area("PoliceJailCellArea", _jail_cell_pos, 22.0, "police_jail")
	_jail_label = _make_station_label(_jail_cell_pos + Vector2(-120, -28), "🚓 Celda Policial [E: Gestionar Fianza / Condena]")
	entities_root.add_child(_jail_label)

	# Comisario Vane y Guardia Rodric
	var tex_sheriff := _load_tex("res://assests/world/village/villager_sheriff.png")
	var tex_guard := _load_tex("res://assests/world/village/villager_guard.png")

	var sheriff := VillageNPC.new()
	sheriff.name = "NPC_Sheriff_Vane"
	sheriff.npc_name = "Comisario Vane"
	sheriff.npc_role = "Comisario Jefe"
	sheriff.trade_role = VillageNPC.TradeRole.SHERIFF
	sheriff.tavern_social_pos = _tavern_social_pos
	entities_root.add_child(sheriff)
	sheriff.setup_npc(
		tex_sheriff,
		Vector2(915, 126),
		Vector2(968, 132),
		{},
		_tavern_social_pos,
		"family_police",
		"Guardia del Valle"
	)
	authority_npcs.append(sheriff)
	_authority_slots.append({
		"role": VillageNPC.TradeRole.SHERIFF,
		"npc": sheriff,
		"rehire_timer": 0.0,
		"vacancy_announced": false,
		"work_pos": Vector2(915, 126),
		"bed_pos": Vector2(968, 132),
		"tex_path": "res://assests/world/village/villager_sheriff.png",
		"stock": {},
		"family_id": "family_police",
		"family_name": "Guardia del Valle",
		"title": "Comisario Jefe",
		"name_pool": ["Comisario Thorne", "Comisaria Vance", "Comisario Haldor", "Comisaria Lyra", "Comisario Rourke"]
	})

	var guard := VillageNPC.new()
	guard.name = "NPC_Guard_Rodric"
	guard.npc_name = "Guardia Rodric"
	guard.npc_role = "Oficial de Patrulla"
	guard.trade_role = VillageNPC.TradeRole.GUARD
	guard.tavern_social_pos = _tavern_social_pos
	entities_root.add_child(guard)
	guard.setup_npc(
		tex_guard,
		Vector2(510, 48), # Patrulla en torno a la Plaza Central y calles
		Vector2(862, 132),
		{},
		_tavern_social_pos,
		"family_police",
		"Guardia del Valle"
	)
	authority_npcs.append(guard)
	_authority_slots.append({
		"role": VillageNPC.TradeRole.GUARD,
		"npc": guard,
		"rehire_timer": 0.0,
		"vacancy_announced": false,
		"work_pos": Vector2(510, 48),
		"bed_pos": Vector2(862, 132),
		"tex_path": "res://assests/world/village/villager_guard.png",
		"stock": {},
		"family_id": "family_police",
		"family_name": "Guardia del Valle",
		"title": "Oficial de Patrulla",
		"name_pool": ["Guardia Kaelen", "Guardia Darian", "Guardia Brenna", "Guardia Tormund", "Guardia Soren"]
	})

## Temporizador de Recontratación Institucional: cuando muere el Médico o un Policía, la Prefectura / Gremio Médico
## envía un nuevo profesional de reemplazo tras `AUTHORITY_REHIRE_TIME_SECONDS` (75s reales o acelerado por horas de juego).
func _update_authority_rehiring(delta: float) -> void:
	for slot in _authority_slots:
		var cur_npc: VillageNPC = slot.get("npc")
		if is_instance_valid(cur_npc) and not cur_npc.is_dead:
			continue
		var r_timer: float = float(slot.get("rehire_timer", 0.0))
		if not bool(slot.get("vacancy_announced", false)):
			slot["vacancy_announced"] = true
			slot["rehire_timer"] = AUTHORITY_REHIRE_TIME_SECONDS
			var p = get_tree().get_first_node_in_group("player")
			if p and p.has_method("show_hint"):
				p.show_hint("📢 Vacante institucional: Se enviará un nuevo %s de reemplazo al Valle en %ds." % [str(slot["title"]), int(AUTHORITY_REHIRE_TIME_SECONDS)])
		else:
			r_timer -= delta
			slot["rehire_timer"] = r_timer
			if r_timer <= 0.0:
				_spawn_authority_replacement(slot)

func _spawn_authority_replacement(slot: Dictionary) -> VillageNPC:
	_rehire_counter += 1
	var pool: Array = slot.get("name_pool", ["Oficial de Reemplazo"])
	var new_name: String = str(pool[_rehire_counter % pool.size()])
	var new_npc := VillageNPC.new()
	new_npc.name = "NPC_Rehired_%d_%s" % [_rehire_counter, new_name.replace(" ", "_").replace(".", "")]
	new_npc.npc_name = new_name
	new_npc.npc_role = str(slot["title"])
	new_npc.trade_role = slot["role"]
	new_npc.tavern_social_pos = _tavern_social_pos
	entities_root.add_child(new_npc)
	var stock_copy: Dictionary = (slot.get("stock", {}) as Dictionary).duplicate()
	new_npc.setup_npc(
		_load_tex(str(slot["tex_path"])),
		slot["work_pos"],
		slot["bed_pos"],
		stock_copy,
		_tavern_social_pos,
		str(slot["family_id"]),
		str(slot["family_name"])
	)
	# El nuevo médico o policía llega caminando por el camino principal del Valle hacia su puesto
	new_npc.global_position = Vector2(240, 48)
	slot["npc"] = new_npc
	slot["rehire_timer"] = 0.0
	slot["vacancy_announced"] = false
	authority_npcs.append(new_npc)

	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("show_hint"):
		if slot["role"] == VillageNPC.TradeRole.DOCTOR:
			p.show_hint("🏥📢 El Gremio Médico ha contratado a %s (%s). Ya se dirige al Hospital y la Morgue." % [new_name, str(slot["title"])])
		else:
			p.show_hint("🚓📢 La Prefectura ha enviado a %s (%s) como nuevo refuerzo policial." % [new_name, str(slot["title"])])
	return new_npc

# ==============================================================================
# PASO 3: 🔓 COFRES DOMÉSTICOS Y ROBO EN SIGILO
# ==============================================================================
func _spawn_house_chest(pos: Vector2, chest_title: String, fam_id: String) -> void:
	var spr := Sprite2D.new()
	spr.texture = _load_tex("res://assests/world/village/house_chest_closed.png")
	spr.global_position = pos
	spr.scale = Vector2(1.05, 1.05)
	spr.z_index = -1
	entities_root.add_child(spr)

	var area := Area2D.new()
	area.global_position = pos
	area.collision_layer = 1
	area.collision_mask = 2
	area.add_to_group("interactable")
	area.set_meta("village_station", "house_chest")
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 9.0
	col.shape = c
	area.add_child(col)
	add_child(area)

	var lbl := _make_station_label(pos + Vector2(-115, -24), "🔓 %s [E: Forzar Cerradura (Usa Sigilo [C])]" % chest_title)
	entities_root.add_child(lbl)

	house_chests.append({
		"pos": pos,
		"sprite": spr,
		"label": lbl,
		"title": chest_title,
		"family_id": fam_id,
		"looted_day": -1
	})

# ==============================================================================
# PASO 5: 📋 TABLÓN DE ENCARGOS EN LA PLAZA CENTRAL (`Vector2(465, 24)`)
# ==============================================================================
func _spawn_notice_board_in_plaza() -> void:
	var board_spr := Sprite2D.new()
	board_spr.texture = _load_tex("res://assests/Comprados/ Packs/Cute_Fantasy/Buildings/House_Decor/questboard_1.png")
	board_spr.global_position = _notice_board_pos
	board_spr.scale = Vector2(1.15, 1.15)
	board_spr.z_index = -1
	entities_root.add_child(board_spr)

	_add_station_area("PlazaNoticeBoardArea", _notice_board_pos, 14.0, "notice_board")
	_notice_board_label = _make_station_label(_notice_board_pos + Vector2(-120, -28), "📋 Tablón de Encargos y Recompensas [E: Ver Misiones]")
	entities_root.add_child(_notice_board_label)

# ==============================================================================
# PASO 10: ⚡ FAROLAS ELÉCTRICAS EN LAS CALLES DEL PUEBLO (`lamp-post1.png`)
# ==============================================================================
func _spawn_electric_streetlights() -> void:
	var lamp_tex := _load_tex("res://assests/Comprados/ Packs/Cute_Fantasy/Buildings/House_Decor/lamp-post1.png")
	var lamp_positions: Array[Vector2] = [
		Vector2(215, 36),  # Entrada de la Granja
		Vector2(405, 18),  # Esquina Noroeste Plaza
		Vector2(525, 18),  # Esquina Noreste Plaza
		Vector2(432, -126),# Entrada de la Gran Posada
		Vector2(692, 88),  # Entrada del Hospital
		Vector2(862, 88)   # Entrada de la Comisaría
	]
	for l_pos in lamp_positions:
		var l_spr := Sprite2D.new()
		l_spr.texture = lamp_tex
		l_spr.global_position = l_pos
		l_spr.scale = Vector2(1.05, 1.05)
		l_spr.z_index = 1
		entities_root.add_child(l_spr)

		var glow := Polygon2D.new()
		glow.polygon = PackedVector2Array([
			Vector2(-26, -18), Vector2(26, -18), Vector2(34, 18), Vector2(-34, 18)
		])
		glow.color = Color(1.0, 0.92, 0.55, 0.22)
		glow.global_position = l_pos
		glow.visible = false
		glow.z_index = -1
		entities_root.add_child(glow)

		streetlights.append({"sprite": l_spr, "glow": glow, "pos": l_pos})

func _update_streetlights_glow() -> void:
	var is_night: bool = WorldClock != null and (WorldClock.current_hour >= 19 or WorldClock.current_hour < 6)
	var grid_on: bool = GameManager != null and bool(GameManager.get_flag("electric_grid_active", false))
	for sl in streetlights:
		var glow: Polygon2D = sl.get("glow")
		var spr: Sprite2D = sl.get("sprite")
		if is_instance_valid(glow):
			glow.visible = is_night or grid_on
			glow.color = Color(0.55, 0.96, 1.0, 0.28) if grid_on else Color(1.0, 0.85, 0.45, 0.16)
		if is_instance_valid(spr):
			spr.modulate = Color(0.90, 1.08, 1.18) if grid_on else Color.WHITE

func _spawn_decor_prop(tex_path: String, pos: Vector2) -> void:
	var tex := _load_tex(tex_path)
	if not tex:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.global_position = pos
	spr.z_index = -1
	entities_root.add_child(spr)

func _add_station_area(area_name: String, pos: Vector2, radius: float, meta_tag: String) -> void:
	var area := Area2D.new()
	area.name = area_name
	area.global_position = pos
	area.collision_layer = 1
	area.collision_mask = 2
	area.add_to_group("interactable")
	area.set_meta("village_station", meta_tag)
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	col.shape = c
	area.add_child(col)
	add_child(area)

# ==============================================================================
# TESTIGOS REALISTAS, FORENSE DE MORGUE Y SISTEMA POLICIAL (PASOS 1, 2, 3 y 4)
# ==============================================================================
func _get_building_at_pos(world_pos: Vector2) -> Dictionary:
	for b in building_footprints:
		var r: Rect2 = b["rect"]
		if r.has_point(world_pos):
			return b
	return {}

## Paso 2: Registra si algún vecino ve al jugador entrar o salir de un edificio sin usar Sigilo [C]
func _track_player_building_sightings(player: Node2D) -> void:
	if not player:
		return
	var cur_b: Dictionary = _get_building_at_pos(player.global_position)
	var cur_id: String = str(cur_b.get("id", ""))
	if cur_id == _last_player_building_id:
		return

	var entered_b: Dictionary = cur_b if cur_id != "" else _find_building_by_id(_last_player_building_id)
	var action_verb: String = "entrar a" if cur_id != "" else "salir de"
	_last_player_building_id = cur_id

	if entered_b.is_empty():
		return

	# Si el jugador entra o sale en Sigilo [C], pasa desapercibido salvo que un NPC esté pegado a menos de 34 px
	var in_stealth: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
	var vision_mult: float = WorldClock.get_weather_vision_multiplier() if (WorldClock and WorldClock.has_method("get_weather_vision_multiplier")) else 1.0
	var max_witness_dist: float = (34.0 if in_stealth else 160.0) * vision_mult

	var door_watch_pos: Vector2 = entered_b.get("door_pos", player.global_position)
	var witness: VillageNPC = _find_conscious_witness_near(door_watch_pos, max_witness_dist, null)
	if witness != null:
		var h: int = WorldClock.current_hour if WorldClock else 12
		var m: int = WorldClock.current_minute if WorldClock else 0
		var d: int = WorldClock.current_day if WorldClock else 1
		var entry: Dictionary = {
			"building_id": str(entered_b.get("id", "")),
			"building_title": str(entered_b.get("title", "Edificio")),
			"witness_name": witness.npc_name,
			"action": action_verb,
			"hour": h,
			"minute": m,
			"day": d,
			"total_minutes": d * 1440 + h * 60 + m
		}
		sighting_log.push_front(entry)
		while sighting_log.size() > 25:
			sighting_log.pop_back()

func _find_building_by_id(b_id: String) -> Dictionary:
	for b in building_footprints:
		if str(b.get("id", "")) == b_id:
			return b
	return {}

func _find_conscious_witness_near(pos: Vector2, max_dist: float, exclude_npc: VillageNPC) -> VillageNPC:
	var best: VillageNPC = null
	var best_d2: float = max_dist * max_dist
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != exclude_npc:
			var v: VillageNPC = n as VillageNPC
			if v.is_dead or v.is_downed or v.is_sleeping or v.is_stunned_flag or v.sedated_timer > 0.0:
				continue
			var d2: float = pos.distance_squared_to(v.global_position)
			if d2 <= best_d2 and has_line_of_sight(v.global_position, pos):
				best_d2 = d2
				best = v
	return best

## Paso 2: Agresión vista en directo (solo si un testigo tiene línea de visión directa sin muros)
func report_assault_crime(victim: VillageNPC) -> void:
	if not victim:
		return
	var vision_mult: float = WorldClock.get_weather_vision_multiplier() if (WorldClock and WorldClock.has_method("get_weather_vision_multiplier")) else 1.0
	var witness: VillageNPC = _find_conscious_witness_near(victim.global_position, 155.0 * vision_mult, victim)
	if witness != null or victim.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD]:
		wanted_level = clampi(wanted_level + 1, 1, 5)
		bounty_gold += 25
		if victim.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD]:
			is_resisting_arrest = true
			alert_police_to_resist(get_tree().get_first_node_in_group("player") as Node2D)
		var w_name: String = witness.npc_name if witness != null else victim.npc_name
		var msg := "👁️🚨 ¡%s presenció el ataque a %s! (+25 Oro de multa policial)" % [w_name, victim.npc_name]
		crime_history.push_front(msg)
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("show_hint"):
			player.show_hint(msg)

## Paso 1 y Paso 2: Cuando un NPC descubre un cadáver y lo traslada a la Morgue, el Dr. Valen realiza la autopsia y la Policía cruza pistas
func register_npc_death_and_corpse(
	victim: VillageNPC,
	death_pos: Vector2,
	weapon_name: String,
	by_player: bool,
	discoverer_name: String = "",
	rot_hours: float = 0.0
) -> void:
	if not victim:
		return
	var h: int = victim.death_hour if ("death_hour" in victim and victim.death_hour >= 0) else (WorldClock.current_hour if WorldClock else 12)
	var m: int = victim.death_minute if ("death_minute" in victim and victim.death_minute >= 0) else (WorldClock.current_minute if WorldClock else 0)
	var d: int = victim.death_day if ("death_day" in victim and victim.death_day >= 1) else (WorldClock.current_day if WorldClock else 1)
	var death_mins: int = d * 1440 + h * 60 + m
	var rot_days: int = int(floor(rot_hours / 24.0))
	var rot_desc: String = "Reciente (<1h)" if rot_hours < 1.0 else (
		"%d días (%dh) en descomposición" % [rot_days, int(round(rot_hours))] if rot_days >= 1 else "%dh antes del hallazgo" % int(round(rot_hours))
	)
	var finder_str: String = discoverer_name if discoverer_name != "" else "Dr. Valen"
	var time_str: String = "Muerte: Día %d (%02d:%02d) | Estado: %s (Hallado por %s)" % [d, h, m, rot_desc, finder_str]

	var b_info: Dictionary = _get_building_at_pos(death_pos)
	var crime_scene_name: String = str(b_info.get("title", "Vía Pública del Valle"))
	var crime_b_id: String = str(b_info.get("id", ""))

	var witness_clue: String = "Ningún vecino reportó entradas sospechosas."
	var suspect_str: String = "Desconocido (Caso sin resolver)"

	if by_player:
		var had_direct_witness: bool = ("murder_witness_name" in victim and str(victim.murder_witness_name) != "")
		if had_direct_witness:
			var mw: String = str(victim.murder_witness_name)
			witness_clue = "%s presenció el ataque directamente." % mw
			suspect_str = "Jugador (Testigo presencial: %s)" % mw
			wanted_level = clampi(wanted_level + 2, 1, 5)
			bounty_gold += 70
		elif crime_b_id != "":
			# 2. ¿Alguien vio al jugador entrar o salir de ese edificio cerca de la hora de la muerte (`sighting_log`)?
			for s_entry in sighting_log:
				if str(s_entry.get("building_id", "")) == crime_b_id and abs(death_mins - int(s_entry.get("total_minutes", 0))) <= 360:
					var w_name: String = str(s_entry.get("witness_name", "Un vecino"))
					var s_h: int = int(s_entry.get("hour", h))
					var s_m: int = int(s_entry.get("minute", m))
					witness_clue = "%s vio al jugador %s %s a las %02d:%02d." % [w_name, str(s_entry.get("action", "entrar a")), crime_scene_name, s_h, s_m]
					suspect_str = "Jugador (Identificado por cruce forense + testigo %s)" % w_name
					wanted_level = clampi(wanted_level + 2, 1, 5)
					bounty_gold += 65
					break

	var record: Dictionary = {
		"victim_name": victim.npc_name,
		"victim_role": victim.npc_role,
		"family_name": victim.family_name,
		"time_str": time_str,
		"crime_scene": crime_scene_name,
		"cause_of_death": weapon_name,
		"witness_clue": witness_clue,
		"suspect": suspect_str
	}
	corpse_records.push_front(record)

	# Mostrar cuerpo cubierto en las mesas de autopsia de la Morgue
	for i in range(_morgue_corpse_sprites.size()):
		if is_instance_valid(_morgue_corpse_sprites[i]):
			_morgue_corpse_sprites[i].visible = (i < corpse_records.size())

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("show_hint"):
		if suspect_str.begins_with("Jugador"):
			player.show_hint("⚰️🚨 El cuerpo de %s fue trasladado a la Morgue. ¡%s! Orden de arresto emitida (Multa: %d Oro)." % [victim.npc_name, witness_clue, bounty_gold])
		else:
			player.show_hint("⚰️🕵️ El cuerpo de %s está en la Morgue Forense. No hubo testigos de tu entrada: Caso sin resolver." % victim.npc_name)

## Paso 4: Propaga cambios de reputación a toda una familia (`family_id`)
func modify_family_reputation(fam_id: String, delta_amount: int, reason: String = "", source_npc: VillageNPC = null) -> void:
	if fam_id == "" or fam_id == "none":
		return
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != source_npc:
			var v: VillageNPC = n as VillageNPC
			if v.family_id == fam_id and not v.is_dead:
				v.affinity = clampi(v.affinity + delta_amount, -100, 100)
				if reason != "":
					v.add_thought("%s (%s%d)" % [reason, "+" if delta_amount >= 0 else "", delta_amount], float(delta_amount) * 0.4)

# ==============================================================================
# MODALES INTERACTIVOS (MORGUE, COMISARÍA/CÁRCEL Y TABLÓN DE ENCARGOS)
# ==============================================================================
func _setup_Interactive_modals_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 32
	add_child(ui_layer)

	# 1. Modal de Autopsias de la Morgue Forense
	morgue_panel = _create_styled_modal(Vector2(500, 250), Color(0.38, 0.85, 0.78))
	ui_layer.add_child(morgue_panel)
	var m_vbox := VBoxContainer.new()
	m_vbox.add_theme_constant_override("separation", 8)
	morgue_panel.add_child(m_vbox)
	morgue_info_lbl = Label.new()
	morgue_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	morgue_info_lbl.add_theme_font_size_override("font_size", 11)
	morgue_info_lbl.add_theme_color_override("font_color", Color(0.92, 0.98, 0.96))
	m_vbox.add_child(morgue_info_lbl)
	var m_close := Button.new()
	m_close.text = "[1 / ESC] Cerrar Informe Forense de la Morgue"
	m_close.pressed.connect(func(): morgue_panel.visible = false)
	m_vbox.add_child(m_close)

	# 2. Modal Policial de Arresto, Fianza y Celda
	police_panel = _create_styled_modal(Vector2(470, 230), Color(0.42, 0.72, 1.0))
	ui_layer.add_child(police_panel)
	var p_vbox := VBoxContainer.new()
	p_vbox.add_theme_constant_override("separation", 8)
	police_panel.add_child(p_vbox)
	police_info_lbl = Label.new()
	police_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	police_info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	police_info_lbl.add_theme_font_size_override("font_size", 12)
	police_info_lbl.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
	p_vbox.add_child(police_info_lbl)

	var p_b1 := Button.new()
	p_b1.text = "[1] 🔒 Entregarse y cumplir condena en la Celda hasta las 06:00 AM (Limpia cargos)"
	p_b1.pressed.connect(func(): _on_police_serve_sentence(get_tree().get_first_node_in_group("player") as Node2D))
	p_vbox.add_child(p_b1)

	var p_b2 := Button.new()
	p_b2.text = "[2] 💰 Pagar Fianza / Multa Policial en Oro para quedar libre"
	p_b2.pressed.connect(func(): pay_bounty_fine(get_tree().get_first_node_in_group("player") as Node2D))
	p_vbox.add_child(p_b2)

	var p_b3 := Button.new()
	p_b3.text = "[3] 🔓 Forzar barrotes para fugarse (en Celda) / Resistirse"
	p_b3.pressed.connect(func(): _on_police_jailbreak_or_resist(get_tree().get_first_node_in_group("player") as Node2D))
	p_vbox.add_child(p_b3)

	var p_b4 := Button.new()
	p_b4.text = "[4 / ESC] Cerrar"
	p_b4.pressed.connect(func(): police_panel.visible = false)
	p_vbox.add_child(p_b4)

	# 3. Modal del Tablón de Encargos de la Plaza Central
	board_panel = _create_styled_modal(Vector2(490, 240), Color(0.92, 0.76, 0.36))
	ui_layer.add_child(board_panel)
	var b_vbox := VBoxContainer.new()
	b_vbox.add_theme_constant_override("separation", 8)
	board_panel.add_child(b_vbox)
	board_info_lbl = Label.new()
	board_info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_info_lbl.add_theme_font_size_override("font_size", 12)
	board_info_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.80))
	b_vbox.add_child(board_info_lbl)

	var bb1 := Button.new()
	bb1.text = "[1] ⚒️ Encargo de Gremios: Entregar 2 Maderas o 1 Mineral Hierro (+28 Oro, +15 Afinidad)"
	bb1.pressed.connect(func(): _complete_board_contract(get_tree().get_first_node_in_group("player") as Node2D, 1))
	b_vbox.add_child(bb1)

	var bb2 := Button.new()
	bb2.text = "[2] 🏥 Urgencia del Hospital: Entregar 2 Hierbas o 1 Cataplasma (+26 Oro, +15 Afinidad)"
	bb2.pressed.connect(func(): _complete_board_contract(get_tree().get_first_node_in_group("player") as Node2D, 2))
	b_vbox.add_child(bb2)

	var bb3 := Button.new()
	bb3.text = "[3] 🚓 Cazarrecompensas: Entregar 1 Reliquia Bandido o 1 Ancas Rana (+34 Oro, -1 Cargo)"
	bb3.pressed.connect(func(): _complete_board_contract(get_tree().get_first_node_in_group("player") as Node2D, 3))
	b_vbox.add_child(bb3)

	var bb4 := Button.new()
	bb4.text = "[4 / ESC] Cerrar Tablón"
	bb4.pressed.connect(func(): board_panel.visible = false)
	b_vbox.add_child(bb4)

func _create_styled_modal(sz: Vector2, border_col: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -sz.x * 0.5
	panel.offset_top = -sz.y * 0.5
	panel.offset_right = sz.x * 0.5
	panel.offset_bottom = sz.y * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.13, 0.97)
	style.border_color = border_col
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _open_morgue_autopsy_ui() -> void:
	if not morgue_panel:
		return
	if corpse_records.is_empty():
		morgue_info_lbl.text = "⚰️ SALA DE AUTOPSIAS — MORGUE FORENSE DEL HOSPITAL\n\nLas 3 camillas de acero inoxidable están vacías.\nNo se ha registrado ningún fallecimiento en el valle.\n\n(Si un NPC cae a 0 HP entra primero en estado 'Agonizando' y puede salvarse trayéndolo a las camas de Urgencias)."
	else:
		var lines: Array[String] = ["⚰️ DICTÁMENES FORENSES DE LA MORGUE (%d Cuerpos examinados por el Dr. Valen):" % corpse_records.size()]
		var max_show: int = mini(3, corpse_records.size())
		for i in range(max_show):
			var rec: Dictionary = corpse_records[i]
			lines.append("• Camillas #%d: %s (%s — %s)\n   🕒 Hora: %s | 📍 Lugar: %s\n   🗡️ Causa Forense: %s\n   👁️ Pista Testigos: %s\n   ⚖️ Sospechoso Policial: %s" % [
				i + 1,
				str(rec.get("victim_name", "")),
				str(rec.get("victim_role", "")),
				str(rec.get("family_name", "")),
				str(rec.get("time_str", "")),
				str(rec.get("crime_scene", "")),
				str(rec.get("cause_of_death", "")),
				str(rec.get("witness_clue", "")),
				str(rec.get("suspect", ""))
			])
		morgue_info_lbl.text = "\n".join(lines)
	morgue_panel.visible = true

func clear_police_hostility() -> void:
	is_resisting_arrest = false
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			v.is_hostile = false
			v.remove_from_group("enemies")
			v.velocity = Vector2.ZERO
			if "_police_alerted_timer" in v:
				v._police_alerted_timer = 0.0
			if "_civilian_hostile_timer" in v:
				v._civilian_hostile_timer = 0.0

func alert_police_to_resist(player: Node2D = null) -> void:
	is_resisting_arrest = true
	if wanted_level <= 0:
		wanted_level = 1
		bounty_gold = maxi(25, bounty_gold)
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD] and not v.is_dead and not v.is_downed:
				if "_police_alerted_timer" in v:
					v._police_alerted_timer = 14.0
				if player != null and "_last_seen_player_pos" in v:
					v._last_seen_player_pos = player.global_position

func trigger_police_confrontation(officer: VillageNPC = null) -> void:
	if _police_confront_cooldown > 0.0 or not police_panel:
		return
	clear_police_hostility()
	_police_confront_cooldown = 4.0
	if officer != null:
		_last_confronting_officer = officer
	var off_name: String = officer.npc_name if officer else "Comisario Vane"
	var state_txt: String = ""
	if player_in_jail:
		if jail_mandatory_stay_timer > 0.0:
			state_txt = "🔒 ESTÁS RECLUIDO EN LA CELDA DE LA COMISARÍA\n⏳ Tiempo obligatorio en celda antes de acostarte en el camastro: %ds" % int(ceil(jail_mandatory_stay_timer))
		else:
			state_txt = "🔒🛏️ CELDA DE LA COMISARÍA — Camastro disponible para cumplir la pena (Avance Orgánico del Mundo)"
	else:
		state_txt = "🚨 ¡ALTO A LA GUARDIA! (%s intenta negociar tu entrega)\n[1] Entregarte: El agente te esposará y te llevará caminando físicamente hasta la Celda" % off_name
	police_info_lbl.text = "%s\nNivel de Búsqueda: %d | Multa Acumulada: %d Oro\nSi te resistes [3], la policía usará Porra de cerca y Pistola a distancia:" % [state_txt, wanted_level, maxi(15, bounty_gold)]
	police_panel.visible = true

func _find_nearest_police_officer(pos: Vector2) -> VillageNPC:
	var best: VillageNPC = null
	var best_d: float = INF
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD] and not v.is_dead and not v.is_downed:
				var d: float = pos.distance_to(v.global_position)
				if d < best_d:
					best_d = d
					best = v
	return best

## Inicia la escolta física del jugador esposado caminando por las calles y puertas hasta la celda (Estilo Kenshi / RDR2)
func start_police_escort_to_jail(player: Node2D, officer: VillageNPC = null) -> void:
	if not player:
		return
	clear_police_hostility()
	if police_panel:
		police_panel.visible = false
	var chosen_officer: VillageNPC = officer if (officer != null and is_instance_valid(officer) and not officer.is_dead) else _find_nearest_police_officer(player.global_position)
	player_being_escorted_to_jail = true
	player_in_jail = false
	escorting_officer = chosen_officer
	if "velocity" in player:
		player.velocity = Vector2.ZERO
	if chosen_officer != null:
		if chosen_officer.global_position.distance_to(player.global_position) > 48.0:
			chosen_officer.global_position = player.global_position + Vector2(14, 0)
		chosen_officer._spawn_floating_text("🚔⛓️ ¡Esposado! En marcha hacia la Celda de la Comisaría", Color.SKY_BLUE, -42.0)
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🚔⛓️ La policía te lleva físicamente hacia la Prisión...", Color.SKY_BLUE, -46.0)

## Controla físicamente la puerta de barrotes de la celda (`Vector2(902, 152)`) y abre la puerta principal de la Comisaría al quedar en libertad
func set_jail_cell_gate_locked(locked: bool) -> void:
	if is_instance_valid(_jail_cell_gate_col):
		_jail_cell_gate_col.disabled = not locked
		_jail_cell_gate_col.set_deferred("disabled", not locked)
	if is_instance_valid(_jail_cell_gate_spr_closed):
		_jail_cell_gate_spr_closed.visible = locked
	if is_instance_valid(_jail_cell_gate_spr_open):
		_jail_cell_gate_spr_open.visible = not locked
	if not locked:
		for d_entry in building_doors:
			if str(d_entry.get("building_id", "")) == "building_police":
				_set_door_state(d_entry, true, false, false)

## Se ejecuta cuando el agente y el jugador llegan caminando físicamente al interior de la celda
func complete_police_escort_to_jail(player: Node2D) -> void:
	clear_police_hostility()
	player_being_escorted_to_jail = false
	escorting_officer = null
	player_in_jail = true
	jail_mandatory_stay_timer = JAIL_MANDATORY_STAY_SECONDS
	set_jail_cell_gate_locked(true)
	if player:
		player.global_position = _jail_cell_pos
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🔒⛓️ Encerrado en la Celda (%ds de estancia antes de usar el camastro)" % int(JAIL_MANDATORY_STAY_SECONDS), Color.SKY_BLUE, -46.0)
	_police_confront_cooldown = 0.0
	trigger_police_confrontation(null)

func capture_knocked_out_player_to_jail(player: Node2D) -> void:
	if not player:
		return
	start_police_escort_to_jail(player, _last_confronting_officer)

func send_player_to_jail(player: Node2D) -> void:
	if not player:
		return
	start_police_escort_to_jail(player, _last_confronting_officer)

func _on_police_serve_sentence(player: Node2D) -> void:
	if not player:
		return
	# 1º Si el jugador aún está fuera de la celda (acaba de entregarse en la calle), el policía lo escolta físicamente caminando hasta la prisión
	if not player_in_jail and not player_being_escorted_to_jail:
		start_police_escort_to_jail(player, _last_confronting_officer)
		return
	if player_being_escorted_to_jail:
		if police_panel:
			police_panel.visible = false
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🚔⛓️ Espera a llegar a la celda con el guardia...", Color.GOLD, -42.0)
		return

	# 2º Ya dentro de la celda: exigir el tiempo mínimo de reclusión antes de poder acostarse en el camastro (The Escapists / Kenshi)
	if jail_mandatory_stay_timer > 0.0:
		var wait_s: int = int(ceil(jail_mandatory_stay_timer))
		if police_info_lbl:
			police_info_lbl.text = "⏳🔒 AÚN NO PUEDES USAR EL CAMASTRO DE LA CELDA\nDebes permanecer %ds más en la celda antes de acostarte para cumplir tu pena.\n(También puedes pagar tu fianza [2] o forzar los barrotes [3])." % wait_s
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("⏳🔒 Espera %ds en la celda antes de acostarte en el camastro" % wait_s, Color.GOLD, -44.0)
		return

	# 3º El jugador decide acostarse en el camastro de la celda -> El tiempo avanza de forma ORGÁNICA en el mundo (sin teletransportes ni congelar NPCs/animales)
	if police_panel:
		police_panel.visible = false
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🛏️⏩ Cumpliendo pena en el camastro: El mundo avanza orgánicamente hasta las 06:00 AM...", Color.AQUA, -46.0)
	if WorldClock and WorldClock.has_method("start_organic_fast_forward"):
		WorldClock.start_organic_fast_forward(6, 26.0, func(): release_player_from_jail_after_sentence(player))
	else:
		release_player_from_jail_after_sentence(player)

func release_player_from_jail_after_sentence(player: Node2D) -> void:
	clear_police_hostility()
	player_being_escorted_to_jail = false
	escorting_officer = null
	player_in_jail = false
	jail_mandatory_stay_timer = 0.0
	wanted_level = 0
	bounty_gold = 0
	set_jail_cell_gate_locked(false)
	if player and is_instance_valid(player):
		# Salida 100% natural: NO se teletransporta al jugador fuera de la comisaría; se abre la reja de la celda para que salga caminando por su pie
		var surv: SurvivalComponent = player.get_node_or_null("SurvivalComponent")
		if surv:
			surv.restore_sleep(85.0)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("⚖️🔓 Condena cumplida (06:00 AM): Reja abierta, puedes salir caminando de la Comisaría", Color.SPRING_GREEN, -46.0)

func pay_bounty_fine(player: Node2D) -> void:
	if not player or not ("inventory" in player) or not player.inventory:
		return
	var inv: SimpleInventory = player.inventory
	var fine: int = maxi(15, bounty_gold) if wanted_level > 0 else 0
	if fine <= 0 and not player_in_jail and not player_being_escorted_to_jail:
		if police_panel:
			police_panel.visible = false
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("✅ No tienes multas ni cargos pendientes", Color.SPRING_GREEN, -42.0)
		return
	var cost: int = maxi(15, fine)
	if inv.gold < cost:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("❌ Necesitas %d Oro para pagar la fianza" % cost, Color.ORANGE_RED, -42.0)
		return
	inv.add_gold(-cost)
	clear_police_hostility()
	player_being_escorted_to_jail = false
	escorting_officer = null
	jail_mandatory_stay_timer = 0.0
	wanted_level = 0
	bounty_gold = 0
	if player_in_jail:
		player_in_jail = false
		set_jail_cell_gate_locked(false)
	if police_panel:
		police_panel.visible = false
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("⚖️🔓 Fianza pagada (-%d Oro): Reja abierta, puedes salir caminando" % cost, Color.GOLD, -44.0)

func _on_police_jailbreak_or_resist(player: Node2D) -> void:
	if police_panel:
		police_panel.visible = false
	if not player:
		return
	if WorldClock and WorldClock.has_method("stop_organic_fast_forward") and WorldClock.is_fast_forwarding:
		WorldClock.stop_organic_fast_forward(false)
	if player_in_jail or player_being_escorted_to_jail:
		player_in_jail = false
		player_being_escorted_to_jail = false
		escorting_officer = null
		jail_mandatory_stay_timer = 0.0
		set_jail_cell_gate_locked(false)
		wanted_level = clampi(wanted_level + 1, 2, 5)
		bounty_gold += 30
		alert_police_to_resist(player)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🔓🔫 ¡Barrotes forzados! Escapa corriendo de la Comisaría (+30 Oro de multa)", Color.ORANGE_RED, -46.0)
	else:
		_police_confront_cooldown = 8.0
		bounty_gold += 15
		alert_police_to_resist(player)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🔫🏏 ¡Te resistes al arresto! La Policía usa Pistola y Porra", Color.ORANGE_RED, -44.0)

func _open_notice_board_ui() -> void:
	if not board_panel:
		return
	var d: int = WorldClock.current_day if WorldClock else 1
	var c1: String = "✅ COMPLETADO" if int(completed_contracts_today.get(1, -1)) == d else "🟢 DISPONIBLE"
	var c2: String = "✅ COMPLETADO" if int(completed_contracts_today.get(2, -1)) == d else "🟢 DISPONIBLE"
	var c3: String = "✅ COMPLETADO" if int(completed_contracts_today.get(3, -1)) == d else "🟢 DISPONIBLE"
	board_info_lbl.text = "📋 TABLÓN DE ENCARGOS DE LA PLAZA CENTRAL (Día %d)\nEstado hoy -> [1] Gremios: %s | [2] Hospital: %s | [3] Comisaría: %s" % [d, c1, c2, c3]
	board_panel.visible = true

func _complete_board_contract(player: Node2D, contract_idx: int) -> void:
	if not player or not ("inventory" in player) or not player.inventory:
		return
	var d: int = WorldClock.current_day if WorldClock else 1
	if int(completed_contracts_today.get(contract_idx, -1)) == d:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("✅ Ya completaste este encargo hoy", Color.GOLD, -42.0)
		return
	var inv: SimpleInventory = player.inventory
	if contract_idx == 1:
		if inv.has_item("wood", 2):
			inv.remove_item("wood", 2)
		elif inv.has_item("iron_ore", 1):
			inv.remove_item("iron_ore", 1)
		else:
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("❌ Requiere 2 Maderas o 1 Mineral de Hierro", Color.ORANGE_RED, -42.0)
			return
		inv.add_gold(28)
		modify_family_reputation("family_carpenter", 15, "Encargo del tablón completado")
		modify_family_reputation("family_smith", 15, "Encargo del tablón completado")
		completed_contracts_today[1] = d
		player._spawn_floating_text("📋⚒️ ¡Encargo Artesanal completado! (+28 Oro, +15 Afinidad)", Color.SPRING_GREEN, -44.0)
	elif contract_idx == 2:
		if inv.has_item("herbs", 2):
			inv.remove_item("herbs", 2)
		elif inv.has_item("herbal_poultice", 1):
			inv.remove_item("herbal_poultice", 1)
		else:
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("❌ Requiere 2 Hierbas Medicinales o 1 Cataplasma", Color.ORANGE_RED, -42.0)
			return
		inv.add_gold(26)
		modify_family_reputation("family_herbalist", 15, "Suministro médico entregado")
		completed_contracts_today[2] = d
		player._spawn_floating_text("📋🏥 ¡Urgencia Médica completada! (+26 Oro, +15 Afinidad)", Color.SPRING_GREEN, -44.0)
	elif contract_idx == 3:
		if inv.has_item("bandit_scrap", 1):
			inv.remove_item("bandit_scrap", 1)
		elif inv.has_item("frog_legs", 1):
			inv.remove_item("frog_legs", 1)
		else:
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("❌ Requiere 1 Chatarra de Bandido o 1 Ancas de Rana", Color.ORANGE_RED, -42.0)
			return
		inv.add_gold(34)
		if wanted_level > 0:
			wanted_level = maxi(0, wanted_level - 1)
			bounty_gold = maxi(0, bounty_gold - 25)
		completed_contracts_today[3] = d
		player._spawn_floating_text("📋🚓 ¡Recompensa cobrada! (+34 Oro, -1 Nivel de Búsqueda)", Color.GOLD, -44.0)
	_open_notice_board_ui()

# ==============================================================================
# HUÉSPEDES DE LA POSADA, POZO, COMPOSTADOR Y MASCOTAS
# ==============================================================================
func _spawn_unemployed_tavern_guests() -> void:
	var tex_traveler := _load_tex("res://assests/world/village/villager_traveler.png")
	var guest_defs: Array[Dictionary] = [
		{"name": "Aldric", "role": "Viajero sin Oficio", "day_pos": Vector2(440, 44), "bed_pos": Vector2(435, -252)},
		{"name": "Sora", "role": "Forastera sin Oficio", "day_pos": Vector2(495, 44), "bed_pos": Vector2(468, -252)},
		{"name": "Darío", "role": "Jornalero sin Oficio", "day_pos": Vector2(415, -105), "bed_pos": Vector2(502, -252)}
	]
	for g in guest_defs:
		var npc := VillageNPC.new()
		npc.name = "NPC_Guest_" + str(g["name"])
		npc.npc_name = str(g["name"])
		npc.npc_role = str(g["role"])
		npc.trade_role = VillageNPC.TradeRole.UNEMPLOYED
		npc.tavern_social_pos = _tavern_social_pos
		entities_root.add_child(npc)
		npc.setup_npc(tex_traveler, g["day_pos"], g["bed_pos"], {}, _tavern_social_pos, "none", "Huésped de Posada")
		unemployed_npcs.append(npc)

func _spawn_domestic_pets() -> void:
	var pet_defs: Array[Dictionary] = [
		{"type": DomesticPet.PetType.DOG, "name": "Toby", "owner": "Granja del Jugador", "pos": Vector2(128, 126), "guard": true, "tint": Color(1.0, 0.96, 0.90)},
		{"type": DomesticPet.PetType.DOG, "name": "Sultán", "owner": "Herrería Yunque Gris", "pos": Vector2(365, 16), "guard": false, "tint": Color(0.88, 0.82, 0.78)},
		{"type": DomesticPet.PetType.DOG, "name": "Canela", "owner": "Barrio Residencial", "pos": Vector2(745, -135), "guard": false, "tint": Color(1.0, 0.85, 0.72)},
		{"type": DomesticPet.PetType.CAT, "name": "Michi", "owner": "Posada El Jabalí Dorado", "pos": Vector2(405, -168), "guard": false, "tint": Color(1.0, 0.92, 0.82)},
		{"type": DomesticPet.PetType.CAT, "name": "Pelusa", "owner": "Botica Raíz Verde", "pos": Vector2(325, 96), "guard": false, "tint": Color(0.92, 0.92, 0.98)},
		{"type": DomesticPet.PetType.CAT, "name": "Sombra", "owner": "Pescadería Aguas Claras", "pos": Vector2(465, 96), "guard": false, "tint": Color(0.75, 0.78, 0.85)}
	]
	for pdef in pet_defs:
		var pet := DomesticPet.new()
		pet.name = "Pet_" + str(pdef["name"])
		pet.pet_type = pdef["type"]
		pet.pet_name = str(pdef["name"])
		pet.owner_label = str(pdef["owner"])
		pet.home_position = pdef["pos"]
		pet.global_position = pdef["pos"]
		pet.is_guard_dog = bool(pdef["guard"])
		pet.tint_color = pdef["tint"]
		entities_root.add_child(pet)
		domestic_pets.append(pet)

func _spawn_farm_well_and_compost() -> void:
	var tex_well := _load_tex("res://assests/world/village/water_well.png")
	var tex_compost := _load_tex("res://assests/world/village/compost_bin.png")

	var well_spr := Sprite2D.new()
	well_spr.texture = tex_well
	well_spr.global_position = _well_pos
	well_spr.scale = Vector2(1.25, 1.25)
	entities_root.add_child(well_spr)
	_add_station_area("WaterWellArea", _well_pos, 10.0, "well")
	_well_label = _make_station_label(_well_pos + Vector2(-110, -28), "🪣 Pozo de Agua [E: Llenar Regadera al 100%]")
	entities_root.add_child(_well_label)

	var comp_spr := Sprite2D.new()
	comp_spr.texture = tex_compost
	comp_spr.global_position = _compost_pos
	comp_spr.scale = Vector2(1.25, 1.25)
	entities_root.add_child(comp_spr)
	_add_station_area("CompostBinArea", _compost_pos, 10.0, "compost")
	_compost_label = _make_station_label(_compost_pos + Vector2(-115, -28), "♻️ Compostador [E: Crear Abono con Hierba/Hongo]")
	entities_root.add_child(_compost_label)

# ==============================================================================
# INTERACCIÓN CENTRAL CON TODAS LAS ESTACIONES DE LA ALDEA
# ==============================================================================
## Prioridad de interacción [E]: garantiza que el jugador siempre pueda abrir una puerta cerrada aunque haya un NPC parado encima,
## y permite reportar cualquier cadáver en el suelo con [E].
func try_priority_door_or_corpse_interaction(player: Node2D, mouse_pos: Vector2) -> bool:
	if not player:
		return false
	var pos: Vector2 = player.global_position

	# 1. Si hay una puerta cerrada muy cerca del jugador (<= 26 px) o una puerta apuntada con el ratón, abrirla/cerrarla con prioridad
	var near_door: Dictionary = _find_nearest_door(pos, 26.0)
	if not near_door.is_empty():
		var d_pos: Vector2 = near_door.get("pos", Vector2.ZERO)
		var is_closed_door: bool = not bool(near_door.get("is_open", false))
		var mouse_aiming_door: bool = d_pos.distance_to(mouse_pos) <= 18.0
		if is_closed_door or mouse_aiming_door:
			_interact_building_door(player, near_door)
			return true

	# 2. Si hay un cadáver en el suelo aún sin reportar cerca del jugador (<= 32 px), permitir reportarlo con [E]
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var c := n as VillageNPC
			if c.is_dead and c.corpse_on_ground and not c.corpse_in_morgue and not c.corpse_reported:
				if pos.distance_to(c.global_position) <= 32.0:
					c.report_corpse_by_player(player)
					return true

	return false

func interact(player: Node2D) -> void:
	if not player:
		return
	var pos := player.global_position

	# 0. ¿Está cerca de una Puerta (`building_doors`) o Ventana (`building_windows`)?
	var best_door: Dictionary = _find_nearest_door(pos, 24.0)
	if not best_door.is_empty():
		_interact_building_door(player, best_door)
		return

	var best_win: Dictionary = _find_nearest_window(pos, 20.0)
	if not best_win.is_empty():
		_interact_building_window(player, best_win)
		return

	# 1. ¿Está cerca de un Cofre Doméstico (`house_chests`)?
	for ch in house_chests:
		var c_pos: Vector2 = ch["pos"]
		if pos.distance_squared_to(c_pos) <= 22.0 * 22.0:
			_interact_house_chest(player, ch)
			return

	# 2. Tablón de Encargos de la Plaza
	if pos.distance_squared_to(_notice_board_pos) <= 28.0 * 28.0:
		_open_notice_board_ui()
		return

	# 3. Morgue Forense
	if pos.distance_squared_to(_morgue_table_positions[1]) <= 36.0 * 36.0:
		_open_morgue_autopsy_ui()
		return

	# 4. Cama de Urgencias del Hospital
	if pos.distance_squared_to(_hospital_bed_pos) <= 28.0 * 28.0:
		_use_hospital_emergency_bed(player)
		return

	# 5. Celda de la Comisaría
	if player_in_jail or pos.distance_squared_to(_jail_cell_pos) <= 32.0 * 32.0:
		_police_confront_cooldown = 0.0
		trigger_police_confrontation(null)
		return

	var d_bed: float = pos.distance_squared_to(_tavern_bed_pos)
	var d_games: float = pos.distance_squared_to(_tavern_games_pos)
	var d_pool: float = pos.distance_squared_to(_tavern_pool_pos)
	var d_well: float = pos.distance_squared_to(_well_pos)
	var d_comp: float = pos.distance_squared_to(_compost_pos)

	if d_pool <= d_games and d_pool <= d_bed and d_pool <= 32.0 * 32.0:
		_use_tavern_games_table(3)
	elif d_games <= d_bed and d_games <= d_well and d_games <= d_comp and d_games <= 32.0 * 32.0:
		_use_tavern_games_table(0)
	elif d_bed <= d_well and d_bed <= d_comp and d_bed <= 26.0 * 26.0:
		_use_tavern_bed(player)
	elif d_well <= d_comp and d_well <= 26.0 * 26.0:
		_use_water_well(player)
	elif d_comp <= 26.0 * 26.0:
		_use_compost_bin(player)

# ==============================================================================
# PUERTAS FÍSICAS, VENTANAS FORZABLES Y NIVEL DE SEGURIDAD / DESCONFIANZA DE LA ALDEA
# ==============================================================================
func get_village_security_level() -> int:
	var sec: int = wanted_level + corpse_records.size() * 2 + int(ceil(float(recent_breakins_count) * 0.5))
	return clampi(sec, 0, 5)

func get_village_security_text() -> String:
	var lvl: int = get_village_security_level()
	if lvl <= 0:
		return "🟢 Tranquila"
	elif lvl <= 2:
		return "🟡 Desconfiada (Nv.%d)" % lvl
	return "🔴 Alerta Máxima (Nv.%d)" % lvl

func _get_building_family_affinity(b_id: String) -> int:
	var target_fam: String = ""
	if b_id == "building_tavern":
		target_fam = "family_tavern"
	elif b_id.begins_with("house_"):
		target_fam = b_id.trim_prefix("house_")
	elif b_id.begins_with("shop_"):
		target_fam = b_id.trim_prefix("shop_")
	elif b_id.begins_with("mixed_"):
		target_fam = b_id.trim_prefix("mixed_")
	if target_fam == "":
		return 10
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.family_id == target_fam and not v.is_dead:
				return v.affinity
	return 10

func _on_hour_passed(new_hour: int, _new_day: int = 1) -> void:
	_apply_hourly_door_security_schedule(new_hour)
	# Cada hora de reloj acelera el envío de refuerzos médicos/policiales si hay vacantes por muerte
	for slot in _authority_slots:
		if bool(slot.get("vacancy_announced", false)) and float(slot.get("rehire_timer", 0.0)) > 0.0:
			slot["rehire_timer"] = maxf(0.0, float(slot["rehire_timer"]) - 25.0)
			if float(slot["rehire_timer"]) <= 0.0:
				_spawn_authority_replacement(slot)

func _apply_hourly_door_security_schedule(hour: int) -> void:
	var sec_lvl: int = get_village_security_level()
	var tex_win_open := _load_tex("res://assests/world/village/window_glass_open.png")
	var tex_win_shut := _load_tex("res://assests/world/village/window_shutter_closed.png")

	for d_entry in building_doors:
		if bool(d_entry.get("locked_by_player", false)) or float(d_entry.get("manual_override_timer", 0.0)) > 0.0:
			continue
		var b_id: String = str(d_entry.get("building_id", ""))
		var fam_aff: int = _get_building_family_affinity(b_id)

		# Las puertas permanecen físicamente cerradas (`is_open = false`) salvo cuando alguien las cruza o las abre;
		# el horario y el nivel de seguridad determinan si además están cerradas con llave (`is_locked = true`).
		if b_id == "building_hospital" or b_id == "building_police":
			_set_door_state(d_entry, false, false, false)
		elif b_id == "building_tavern":
			var tav_close_h: int = 21 if sec_lvl >= 3 else 23
			var lock_tav: bool = (hour >= tav_close_h or hour < 6)
			_set_door_state(d_entry, false, lock_tav, false)
		elif b_id.begins_with("shop_") or b_id.begins_with("mixed_"):
			var shop_close_h: int = 17 if sec_lvl >= 3 else 18
			var is_open_hours: bool = (hour >= 8 and hour < shop_close_h and fam_aff > -35)
			_set_door_state(d_entry, false, not is_open_hours, false)
		elif b_id.begins_with("house_"):
			var night_lock_h: int = 18 if (sec_lvl >= 3 or fam_aff < 0) else (19 if sec_lvl >= 1 else 21)
			if hour >= night_lock_h or hour < 7:
				var lock_prob_met: bool = (sec_lvl >= 1) or (fam_aff < 0) or (abs(b_id.hash()) % 4 != 0)
				_set_door_state(d_entry, false, lock_prob_met, false)
			else:
				var day_lock: bool = (sec_lvl >= 3 or fam_aff <= -15)
				_set_door_state(d_entry, false, day_lock, false)

	for w_entry in building_windows:
		var wb_id: String = str(w_entry.get("building_id", ""))
		var w_aff: int = _get_building_family_affinity(wb_id)
		var should_shutter: bool = (hour >= 20 or hour < 7) or (sec_lvl >= 2) or (w_aff < 0)
		w_entry["is_shuttered"] = should_shutter
		var w_spr: Sprite2D = w_entry.get("sprite")
		if is_instance_valid(w_spr):
			w_spr.texture = tex_win_shut if should_shutter else tex_win_open

func _set_door_state(d_entry: Dictionary, open_state: bool, locked_state: bool, by_player: bool) -> void:
	d_entry["is_open"] = open_state
	d_entry["is_locked"] = false if open_state else locked_state
	d_entry["locked_by_player"] = false if open_state else by_player
	_refresh_door_visual_and_collision(d_entry)

func _refresh_door_visual_and_collision(d_entry: Dictionary) -> void:
	var eff_open: bool = bool(d_entry.get("is_open", false)) or float(d_entry.get("npc_pass_timer", 0.0)) > 0.0
	var is_lck: bool = bool(d_entry.get("is_locked", false))
	var col: CollisionShape2D = d_entry.get("col")
	var spr_c: Sprite2D = d_entry.get("spr_closed")
	var spr_o: Sprite2D = d_entry.get("spr_open")
	if is_instance_valid(col):
		col.disabled = eff_open
		col.set_deferred("disabled", eff_open)
	if is_instance_valid(spr_c):
		spr_c.visible = not eff_open
		if not eff_open:
			var tex_path := "res://assests/world/village/door_wood_locked.png" if is_lck else "res://assests/world/village/door_wood_closed.png"
			spr_c.texture = _load_tex(tex_path)
	if is_instance_valid(spr_o):
		spr_o.visible = eff_open

## Llamado activamente por cada NPC al acercarse a una puerta durante su movimiento (`_move_towards_point`).
## Solo abre la puerta si el NPC tiene INTENCIÓN REAL de entrar o salir de ese edificio específico (`npc_inside != dest_inside`).
## Nunca abre puertas cuando un NPC independiente pasa caminando por la calle o cuando deambula en el interior.
func npc_interact_with_door(npc: VillageNPC, delta: float = 0.016, target_pos: Vector2 = Vector2.INF, _nav_target: Vector2 = Vector2.INF) -> bool:
	if npc == null or npc.is_dead or npc.is_downed or npc.is_sleeping:
		return true
	if target_pos == Vector2.INF:
		return true
	var npc_pos: Vector2 = npc.global_position
	for d_entry in building_doors:
		var d_pos: Vector2 = d_entry.get("pos", Vector2.ZERO)
		if npc_pos.distance_to(d_pos) <= 18.5:
			# Intención estricta: el origen y el destino final DEBEN estar en lados opuestos de ESTE edificio (uno dentro y otro fuera)
			var b_rect: Rect2 = d_entry["building_rect"].grow(-1.0)
			var npc_inside: bool = b_rect.has_point(npc_pos)
			var dest_inside: bool = b_rect.has_point(target_pos)
			var crossing_this_door: bool = (npc_inside != dest_inside)
			if not crossing_this_door:
				continue

			if bool(d_entry.get("is_open", false)):
				return true
			if bool(d_entry.get("locked_by_player", false)):
				# Si es un policía persiguiendo al jugador, derriba la puerta tras 2.0s de golpes
				if npc.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD] and (wanted_level > 0 or is_resisting_arrest or npc.is_hostile):
					var b_t: float = float(d_entry.get("police_breach_timer", 0.0)) + delta
					d_entry["police_breach_timer"] = b_t
					if b_t >= 2.0:
						d_entry["police_breach_timer"] = 0.0
						_set_door_state(d_entry, true, false, false)
						npc._spawn_floating_text("🚓💥 ¡Puerta derribada!", Color.ORANGE_RED, -38.0)
						return true
					return false
				return false

			# El NPC abre la puerta mientras cruza el umbral y esta se cierra sola en cuanto entra al centro de la habitación
			var was_passing: bool = float(d_entry.get("npc_pass_timer", 0.0)) > 0.0
			d_entry["npc_pass_timer"] = 0.65
			if not was_passing:
				_refresh_door_visual_and_collision(d_entry)
				var is_lck: bool = bool(d_entry.get("is_locked", false))
				npc._spawn_floating_text("🔑🚪" if is_lck else "🚪", Color(0.95, 0.88, 0.62), -28.0)
			return true
	return true

func _update_doors_and_windows(delta: float, player: Node2D, mouse_pos: Vector2) -> void:
	var sec_txt: String = get_village_security_text()
	for d_entry in building_doors:
		var m_timer: float = float(d_entry.get("manual_override_timer", 0.0))
		if m_timer > 0.0:
			d_entry["manual_override_timer"] = maxf(0.0, m_timer - delta)

		var d_pos: Vector2 = d_entry.get("pos", Vector2.ZERO)
		var was_npc_passing: bool = float(d_entry.get("npc_pass_timer", 0.0)) > 0.0
		if was_npc_passing:
			d_entry["npc_pass_timer"] = maxf(0.0, float(d_entry.get("npc_pass_timer", 0.0)) - delta)

		var now_npc_passing: bool = float(d_entry.get("npc_pass_timer", 0.0)) > 0.0
		if was_npc_passing != now_npc_passing:
			_refresh_door_visual_and_collision(d_entry)

		var d_lbl: Label = d_entry.get("label")
		if is_instance_valid(d_lbl):
			d_lbl.visible = _is_near(player, mouse_pos, d_pos, 24.0, 16.0)
			if d_lbl.visible:
				var b_title: String = str(d_entry.get("building_title", "Edificio"))
				if bool(d_entry.get("is_open", true)):
					d_lbl.text = "🚪 Puerta de %s (Abierta)\n[E: Cerrar Puerta | B: Cerrar y Bloquear con Cerrojo]" % b_title
				elif bool(d_entry.get("locked_by_player", false)):
					d_lbl.text = "🔒 Puerta de %s (TRANCADA POR TI)\n[E / B: Quitar Cerrojo y Abrir]" % b_title
				elif bool(d_entry.get("is_locked", false)):
					d_lbl.text = "🔒 Puerta Cerrada con Llave — Seguridad Aldea: %s\n[F: Forzar Cerradura (Usa Sigilo [C]) | E: Probar Picaporte]" % sec_txt
				else:
					d_lbl.text = "🚪 Puerta de %s (Cerrada sin llave)\n[E: Abrir Puerta | B: Echar Cerrojo]" % b_title

	for w_entry in building_windows:
		var w_pos: Vector2 = w_entry.get("pos", Vector2.ZERO)
		var w_lbl: Label = w_entry.get("label")
		if is_instance_valid(w_lbl):
			w_lbl.visible = _is_near(player, mouse_pos, w_pos, 20.0, 14.0)
			if w_lbl.visible:
				var wb_title: String = str(w_entry.get("building_title", "Edificio"))
				var shut: bool = bool(w_entry.get("is_shuttered", false))
				w_lbl.text = "🪟🔒 Ventana Cerrada de %s [F: Forzar Postigo y Entrar]" % wb_title if shut else "🪟 Ventana de %s [E: Colarse por la Ventana]" % wb_title

func _find_nearest_door(pos: Vector2, max_rad: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d2: float = max_rad * max_rad
	for d_entry in building_doors:
		var d_pos: Vector2 = d_entry.get("pos", Vector2.ZERO)
		var d2: float = pos.distance_squared_to(d_pos)
		if d2 <= best_d2:
			best_d2 = d2
			best = d_entry
	return best

func _find_nearest_window(pos: Vector2, max_rad: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d2: float = max_rad * max_rad
	for w_entry in building_windows:
		var w_pos: Vector2 = w_entry.get("pos", Vector2.ZERO)
		var d2: float = pos.distance_squared_to(w_pos)
		if d2 <= best_d2:
			best_d2 = d2
			best = w_entry
	return best

func _interact_building_door(player: Node2D, d_entry: Dictionary) -> void:
	var is_open_now: bool = bool(d_entry.get("is_open", true))
	var is_locked_now: bool = bool(d_entry.get("is_locked", false))
	var locked_by_p: bool = bool(d_entry.get("locked_by_player", false))
	var b_title: String = str(d_entry.get("building_title", "Edificio"))
	d_entry["manual_override_timer"] = 65.0

	if is_open_now:
		_set_door_state(d_entry, false, false, false)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🚪 Puerta cerrada (Oculta la visión desde fuera)", Color(0.90, 0.85, 0.70), -42.0)
		return

	if locked_by_p:
		_set_door_state(d_entry, true, false, false)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🔓 Quitaste tu cerrojo y abriste la puerta", Color.SPRING_GREEN, -42.0)
		return

	if not is_locked_now:
		_set_door_state(d_entry, true, false, false)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🚪 Puerta abierta", Color.SPRING_GREEN, -42.0)
		return

	# Si la puerta está cerrada con llave por los habitantes, pulsar [E] NO fuerza la cerradura (evita crímenes accidentales):
	# requiere pulsar explícitamente la tecla [F] para forzar la cerradura.
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🔒 Cerrada con llave — Pulsa [F] para forzar cerradura", Color.GOLD, -42.0)
	if player.has_method("show_hint"):
		player.call("show_hint", "🔒 La puerta de %s está cerrada con llave. Pulsa [F] si quieres forzar la cerradura (usa Sigilo [C])." % b_title)

## Tecla [F]: Acción dedicada para Forzar Cerraduras de puertas, Postigos de ventanas o Barrotes de la Celda (Separada de [E])
func force_lock_or_shutter_by_player(player: Node2D) -> bool:
	if not player:
		return false

	# 1. Si el jugador está encerrado en la Celda Policial, [F] fuerza los barrotes para fugarse
	if player_in_jail:
		_on_police_jailbreak_or_resist(player)
		return true

	# 2. ¿Está ante una puerta cerrada con llave?
	var d_entry: Dictionary = _find_nearest_door(player.global_position, 28.0)
	if not d_entry.is_empty():
		var is_open_now: bool = bool(d_entry.get("is_open", true))
		var is_locked_now: bool = bool(d_entry.get("is_locked", false))
		var locked_by_p: bool = bool(d_entry.get("locked_by_player", false))
		var b_title: String = str(d_entry.get("building_title", "Edificio"))

		if is_open_now or not is_locked_now or locked_by_p:
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🚪 Esta puerta no tiene llave ajena (Usa [E] para abrirla)", Color.LIGHT_GRAY, -40.0)
			return true

		d_entry["manual_override_timer"] = 65.0
		recent_breakins_count += 1
		_set_door_state(d_entry, true, false, false)
		var in_stealth: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
		var detect_rad: float = 42.0 if in_stealth else 145.0
		var witness: VillageNPC = _find_conscious_witness_near(d_entry.get("pos", player.global_position), detect_rad, null)
		if witness == null:
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🔓🤫 Cerradura forzada con [F] en sigilo: %s (Sin testigos)" % b_title, Color.SPRING_GREEN, -44.0)
		else:
			wanted_level = clampi(wanted_level + 1, 1, 5)
			bounty_gold += 20
			var msg := "🚨👁️ ¡%s te vio forzar la cerradura de %s! (+20 Oro de multa)" % [witness.npc_name, b_title]
			crime_history.push_front(msg)
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text(msg, Color.ORANGE_RED, -46.0)
		return true

	# 3. ¿Está ante una ventana con postigo cerrado?
	var w_entry: Dictionary = _find_nearest_window(player.global_position, 24.0)
	if not w_entry.is_empty():
		var b_rect: Rect2 = w_entry.get("building_rect", Rect2())
		var w_pos: Vector2 = w_entry.get("pos", Vector2.ZERO)
		var door_south: bool = bool(w_entry.get("door_south", true))
		var wb_title: String = str(w_entry.get("building_title", "Edificio"))
		var player_inside: bool = b_rect.has_point(player.global_position)
		if not player_inside and bool(w_entry.get("is_shuttered", false)):
			w_entry["is_shuttered"] = false
			recent_breakins_count += 1
			var w_spr: Sprite2D = w_entry.get("sprite")
			if is_instance_valid(w_spr):
				w_spr.texture = _load_tex("res://assests/world/village/window_glass_open.png")
			var in_stealth2: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
			var detect_rad2: float = 38.0 if in_stealth2 else 130.0
			var witness2: VillageNPC = _find_conscious_witness_near(w_pos, detect_rad2, null)
			if witness2 != null:
				wanted_level = clampi(wanted_level + 1, 1, 5)
				bounty_gold += 20
				if player.has_method("_spawn_floating_text"):
					player._spawn_floating_text("🚨👁️ ¡%s te vio forzar la ventana de %s! (+20 Oro)" % [witness2.npc_name, wb_title], Color.ORANGE_RED, -46.0)
			else:
				if player.has_method("_spawn_floating_text"):
					player._spawn_floating_text("🪟🔓 Forzaste el postigo con [F] y entraste por la ventana", Color.SPRING_GREEN, -44.0)
			player.global_position = w_pos + Vector2(0, -15.0 if door_south else 15.0)
			return true

	return false

## Tecla [B]: Permite al jugador cerrar y trancar con cerrojo cualquier puerta cercana (o desbloquearla)
func toggle_bar_door_by_player(player: Node2D) -> bool:
	if not player:
		return false
	var d_entry: Dictionary = _find_nearest_door(player.global_position, 28.0)
	if d_entry.is_empty():
		return false
	d_entry["manual_override_timer"] = 120.0
	var currently_barred: bool = bool(d_entry.get("locked_by_player", false)) and not bool(d_entry.get("is_open", true))
	if not currently_barred:
		_set_door_state(d_entry, false, true, true)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🚪🔒 ¡Puerta cerrada y trancada con cerrojo! (Impide el paso y la visión)", Color.GOLD, -44.0)
	else:
		_set_door_state(d_entry, false, false, false)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🔓 Quitaste el cerrojo de la puerta", Color.SPRING_GREEN, -42.0)
	return true

func _interact_building_window(player: Node2D, w_entry: Dictionary) -> void:
	var b_rect: Rect2 = w_entry.get("building_rect", Rect2())
	var w_pos: Vector2 = w_entry.get("pos", Vector2.ZERO)
	var door_south: bool = bool(w_entry.get("door_south", true))
	var b_title: String = str(w_entry.get("building_title", "Edificio"))
	var player_inside: bool = b_rect.has_point(player.global_position)

	if not player_inside:
		var was_shuttered: bool = bool(w_entry.get("is_shuttered", false))
		if was_shuttered:
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🪟🔒 Postigo cerrado — Pulsa [F] para forzar ventana", Color.GOLD, -42.0)
			if player.has_method("show_hint"):
				player.call("show_hint", "🪟🔒 La ventana de %s tiene el postigo echado. Pulsa [F] para forzarla." % b_title)
			return
		player.global_position = w_pos + Vector2(0, -15.0 if door_south else 15.0)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🪟🤫 Te colaste por la ventana de %s" % b_title, Color.AQUA, -44.0)
	else:
		player.global_position = w_pos + Vector2(0, 15.0 if door_south else -15.0)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🪟🏃 Saliste al exterior por la ventana", Color.AQUA, -44.0)

func _interact_house_chest(player: Node2D, ch: Dictionary) -> void:
	var cur_day: int = WorldClock.current_day if WorldClock else 1
	if int(ch.get("looted_day", -1)) == cur_day:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("📦 Este cofre ya fue abierto hoy", Color.LIGHT_GRAY, -42.0)
		return

	ch["looted_day"] = cur_day
	var spr: Sprite2D = ch.get("sprite")
	if is_instance_valid(spr):
		spr.texture = _load_tex("res://assests/world/village/house_chest_open.png")

	var inv: SimpleInventory = player.get("inventory")
	var gold_loot: int = randi_range(18, 32)
	var bonus_pool: Array[String] = ["bread", "iron_ore", "copper_coil", "herbal_poultice", "sleeping_draught"]
	var bonus_item: String = bonus_pool[randi() % bonus_pool.size()]
	if inv:
		inv.add_gold(gold_loot)
		inv.add_item(bonus_item, 1)

	var in_stealth: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
	var detect_rad: float = 52.0 if in_stealth else 135.0
	var witness: VillageNPC = _find_conscious_witness_near(player.global_position, detect_rad, null)

	if witness == null:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🔓🤫 Robo en sigilo perfecto: +%d Oro, +1 %s (Sin testigos)" % [gold_loot, SimpleInventory.CATALOG.get(bonus_item, {}).get("name", bonus_item)], Color.SPRING_GREEN, -46.0)
	else:
		wanted_level = clampi(wanted_level + 1, 1, 5)
		bounty_gold += 30
		var fam_id: String = str(ch.get("family_id", "none"))
		modify_family_reputation(fam_id, -35, "Robo de cofre visto por " + witness.npc_name)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🚨👁️ ¡%s te vio forzar el cofre! (+30 Oro de multa policial)" % witness.npc_name, Color.ORANGE_RED, -46.0)

func _use_hospital_emergency_bed(player: Node2D) -> void:
	# Primero comprobar si hay algún NPC agonizando cerca para ingresarlo
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v: VillageNPC = n as VillageNPC
			if v.is_downed and not v.is_dead and v.global_position.distance_to(player.global_position) <= 90.0:
				v.revive_from_downed(player, false)
				return

	var health: HealthComponent = player.get_node_or_null("HealthComponent")
	if health:
		health.heal(health.max_health)
	if "bleed_stacks" in player:
		player.bleed_stacks = 0
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🏥 Cama de Urgencias: Salud restaurada al 100%", Color.SPRING_GREEN, -44.0)

func _use_tavern_games_table(start_tab: int = 0) -> void:
	var games_ui = get_tree().root.find_child("TavernGamesUI", true, false)
	if games_ui and games_ui.has_method("open_games"):
		games_ui.call("open_games", start_tab)

func _use_tavern_bed(player: Node2D) -> void:
	var inv: SimpleInventory = player.get("inventory")
	if not inv or inv.gold < 8:
		if player.has_method("show_hint"):
			player.show_hint("🛌 Necesitas 8 Oro para alquilar la cama de la Taberna.")
		return
	inv.add_gold(-8)
	var surv: SurvivalComponent = player.get_node_or_null("SurvivalComponent")
	var stam: StaminaComponent = player.get_node_or_null("StaminaComponent")
	var health: HealthComponent = player.get_node_or_null("HealthComponent")
	if surv:
		surv.restore_sleep(100.0)
	if stam:
		stam.current_stamina = stam.max_stamina
		stam.stamina_changed.emit(stam.current_stamina, stam.max_stamina)
	if health:
		health.heal(35.0)
	if WorldClock:
		WorldClock.sleep_until_morning()
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🛌 Dormiste en la Posada (-8 Oro, +100% Sueño)", Color.GOLD, -42.0)

func _use_water_well(player: Node2D) -> void:
	if player.has_method("refill_watering_can"):
		player.call("refill_watering_can")
	elif player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("💧 Agua fresca del pozo", Color.AQUA, -40.0)

func _use_compost_bin(player: Node2D) -> void:
	var inv: SimpleInventory = player.get("inventory")
	if not inv:
		return
	for org_id in ["mushroom", "herbs", "carrot", "cabbage"]:
		if inv.remove_item(org_id, 1):
			inv.add_item("fertilizer", 2)
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("♻️ Compostador: +2 Abono Orgánico", Color.SPRING_GREEN, -42.0)
			return
	if player.has_method("show_hint"):
		player.show_hint("♻️ Necesitas 1 Hongo, Hierba o Verdura para fermentar 2 bolsas de Abono Orgánico.")

func _on_day_passed(_new_day: int) -> void:
	# Cerrar cofres domésticos para el nuevo día
	var tex_closed := _load_tex("res://assests/world/village/house_chest_closed.png")
	for ch in house_chests:
		var spr: Sprite2D = ch.get("sprite")
		if is_instance_valid(spr) and tex_closed:
			spr.texture = tex_closed

	for role_key in trade_configs.keys():
		var current_holder: VillageNPC = trade_npcs.get(role_key)
		var cfg: Dictionary = trade_configs[role_key]

		if not is_instance_valid(current_holder) or current_holder.is_dead:
			var kin_candidate: VillageNPC = family_npcs.get(role_key)
			if is_instance_valid(kin_candidate) and not kin_candidate.is_dead and kin_candidate.trade_role == VillageNPC.TradeRole.FAMILY_MEMBER:
				kin_candidate.promote_to_trade(
					role_key,
					str(cfg["title"]),
					cfg["work_pos"],
					cfg["stock"],
					cfg["tex"]
				)
				trade_npcs[role_key] = kin_candidate
				var p1 = get_tree().get_first_node_in_group("player")
				if p1 and p1.has_method("show_hint"):
					p1.show_hint("🏠 Herencia Familiar: %s (%s) ha asumido el puesto de %s." % [kin_candidate.npc_name, str(cfg["family_name"]), str(cfg["title"])])
				continue

			var outsider: VillageNPC = _pop_living_unemployed()
			if outsider:
				outsider.promote_to_trade(
					role_key,
					str(cfg["title"]),
					cfg["work_pos"],
					cfg["stock"],
					cfg["tex"],
					cfg["bed1_pos"],
					cfg["table_pos"],
					str(cfg["family_id"]),
					str(cfg["family_name"])
				)
				trade_npcs[role_key] = outsider
				var p2 = get_tree().get_first_node_in_group("player")
				if p2 and p2.has_method("show_hint"):
					p2.show_hint("🔄 Sucesión en la aldea: %s se ha mudado a la %s como nuevo %s." % [outsider.npc_name, str(cfg["house_title"]), str(cfg["title"])])
		else:
			var base_stock: Dictionary = cfg["stock"]
			for item_k in base_stock.keys():
				var cur_amt: int = int(current_holder.shop_stock.get(item_k, 0))
				var max_amt: int = int(base_stock[item_k]) + 2
				if cur_amt < max_amt:
					current_holder.shop_stock[item_k] = cur_amt + 1

func _pop_living_unemployed() -> VillageNPC:
	for i in range(unemployed_npcs.size()):
		var cand: VillageNPC = unemployed_npcs[i]
		if is_instance_valid(cand) and not cand.is_dead and cand.trade_role == VillageNPC.TradeRole.UNEMPLOYED:
			unemployed_npcs.remove_at(i)
			return cand
	return null

func _make_station_label(pos: Vector2, txt: String) -> Label:
	var lbl := Label.new()
	lbl.visible = false
	lbl.text = txt
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = pos
	lbl.custom_minimum_size = Vector2(250, 20)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.68))
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.z_index = 20
	return lbl

func _load_tex(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var t = load(res_path)
		if t is Texture2D:
			return t
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null
