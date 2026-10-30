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
var _innkeeper_npc: VillageNPC = null
const MAX_DAILY_ARRIVALS: int = 2
const MAX_MORGUE_CAPACITY: int = 3
var arrivals_today_count: int = 0
var _authority_slots: Array[Dictionary] = []
var _rehire_counter: int = 0
var trade_configs: Dictionary = {}
var domestic_pets: Array[DomesticPet] = []

# Registro de Edificios con Paredes Sólidas y Puertas para Navegación y Testigos
var building_footprints: Array[Dictionary] = []
var _wall_occluder_rects: Array[Rect2] = []

# Paso 1: Hospital de Urgencias, Morgue Forense (Máx. 3 Camillas), Iglesia y Cementerio Parroquial
var _hospital_center := Vector2(745, 148)
var _hospital_bed_pos := Vector2(710, 132)
var _morgue_table_positions: Array[Vector2] = [
	Vector2(712, 174),
	Vector2(745, 174),
	Vector2(778, 174)
]
var _morgue_corpse_sprites: Array[Sprite2D] = []
var morgue_active_corpses: Array[Dictionary] = [] # Máximo 3 cuerpos simultáneos en las camillas de la Morgue
var buried_graves: Array[Dictionary] = []         # Cuerpos sepultados físicamente en el Cementerio de la Iglesia
var corpse_records: Array[Dictionary] = []        # Archivo histórico forense completo
var _hospital_bed_label: Label = null
var _morgue_label: Label = null

# Iglesia de San Cipriano y Cementerio Parroquial (Sur del Hospital y la Comisaría)
var _church_center := Vector2(745, 312)
var _church_altar_pos := Vector2(745, 336)
var _cemetery_gate_pos := Vector2(888, 262)
var _cemetery_burial_pos := Vector2(888, 305)
var _cemetery_grave_positions: Array[Vector2] = []
var _cemetery_grave_nodes: Array[Node2D] = []
var _church_altar_label: Label = null
var _cemetery_label: Label = null
var church_panel: PanelContainer = null
var church_info_lbl: Label = null

# Paso 2: Comisaría, Cárcel y Sistema Realista de Testigos ("Me vieron entrar a la casa")
var _police_center := Vector2(915, 148)
var _jail_cell_pos := Vector2(886, 172)
var wanted_level: int = 0
var bounty_gold: int = 0
var player_arrests_count: int = 0
var player_murder_warrants_count: int = 0
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

# Capas de Interfaz para Morgue Forense, Arresto/Cárcel, Tablón de Encargos y Gestión de Negocios/Escrituras
var ui_layer: CanvasLayer = null
var morgue_panel: PanelContainer = null
var morgue_info_lbl: Label = null
var police_panel: PanelContainer = null
var police_info_lbl: Label = null
var board_panel: PanelContainer = null
var board_info_lbl: Label = null

# Fase 8: Economía Dinámica de Oferta/Demanda, Sabotaje Industrial y Propiedad Híbrida de Negocios
var shop_businesses: Dictionary = {} # int(TradeRole) -> {role, family_id, title, stall_pos, stall_sprite, stall_label, owner_mode, vault_gold, sabotaged_days, sabotaged_today_day, supply_items}
var village_food_shortage_days: int = 0
var house_pantry: Dictionary = {} # family_id / npc_name -> int (Raciones de comida guardadas en la despensa de casa)
var vagrant_camp_nodes: Dictionary = {} # npc_name -> Node2D (Campamento rústico físico en las afueras)
var merchant_suspension_days: Dictionary = {"casimir": 0, "valeria": 0} # Días de embargo comercial (20..30) si asesinan a un mercader
var _active_traveling_merchant: VillageNPC = null
var _royal_investigator_npc: VillageNPC = null
var active_royal_investigation: Dictionary = {} # Expediente deductivo del Inquisidor Real Alistair
var business_panel: PanelContainer = null
var business_info_lbl: Label = null
var _biz_btn_1: Button = null
var _biz_btn_2: Button = null
var _biz_btn_3: Button = null
var _biz_btn_4: Button = null
var _active_business_role: int = -1

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
	shop_businesses.clear()
	morgue_active_corpses.clear()
	buried_graves.clear()
	_cemetery_grave_positions.clear()
	_cemetery_grave_nodes.clear()
	vagrant_camp_nodes.clear()
	arrivals_today_count = 0
	house_pantry = {
		"family_smith": 3,
		"family_butcher": 4,
		"family_carpenter": 3,
		"family_fishmonger": 4,
		"family_herbalist": 4,
		"family_hospital": 3,
		"family_police": 4,
		"family_tavern": 5
	}

	_spawn_village_roads_and_plaza()
	_spawn_western_plains_and_frog_marsh()
	_spawn_tavern_and_rooms()
	_spawn_five_family_houses_and_trades()
	_spawn_hospital_and_morgue()
	_spawn_police_station_and_jail()
	_spawn_church_and_cemetery()
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

var _cached_player: Node2D = null
var _ui_hover_timer: float = 0.0
var _tex_cache: Dictionary = {}
var _deployed_bear_traps: Array[Dictionary] = []

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _police_confront_cooldown > 0.0:
		_police_confront_cooldown -= delta

	if not is_instance_valid(_cached_player):
		_cached_player = get_tree().get_first_node_in_group("player") as Node2D
	var player := _cached_player
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
		_check_authority_vacancy_announcements()

	if not _deployed_bear_traps.is_empty():
		_update_deployed_bear_traps(delta, player)

	# Actualizar temporizadores de paso de puertas y ventanas cada fotograma, pero throttlear las etiquetas UI a ~12.5 Hz
	for d_entry in building_doors:
		var m_timer: float = float(d_entry.get("manual_override_timer", 0.0))
		if m_timer > 0.0:
			d_entry["manual_override_timer"] = maxf(0.0, m_timer - delta)
		var was_npc_passing: bool = float(d_entry.get("npc_pass_timer", 0.0)) > 0.0
		if was_npc_passing:
			d_entry["npc_pass_timer"] = maxf(0.0, float(d_entry.get("npc_pass_timer", 0.0)) - delta)
		var now_npc_passing: bool = float(d_entry.get("npc_pass_timer", 0.0)) > 0.0
		if was_npc_passing != now_npc_passing:
			_refresh_door_visual_and_collision(d_entry)

	for w_entry in building_windows:
		var wm_timer: float = float(w_entry.get("manual_override_timer", 0.0))
		if wm_timer > 0.0:
			w_entry["manual_override_timer"] = maxf(0.0, wm_timer - delta)

	_ui_hover_timer -= delta
	if _ui_hover_timer > 0.0:
		return
	_ui_hover_timer = 0.08

	var mouse_pos := get_global_mouse_position()

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
			_morgue_label.text = "⚰️ Morgue Forense (%d/%d Camillas | %d en Cementerio) [E: Examinar Autopsias]" % [morgue_active_corpses.size(), MAX_MORGUE_CAPACITY, buried_graves.size()]
	if _church_altar_label:
		_church_altar_label.visible = _is_near(player, mouse_pos, _church_altar_pos, 30.0, 22.0)
		if _church_altar_label.visible:
			_church_altar_label.text = "⛪ Altar de San Cipriano y Libro de Difuntos (%d Sepulturas) [E: Consultar / Orar]" % buried_graves.size()
	if _cemetery_label:
		_cemetery_label.visible = _is_near(player, mouse_pos, _cemetery_gate_pos, 28.0, 20.0)
		if _cemetery_label.visible:
			_cemetery_label.text = "🪦 Cementerio Parroquial (%d/18 Tumbas Ocupadas) [E: Ver Registro]" % buried_graves.size()
	for g_node in _cemetery_grave_nodes:
		if is_instance_valid(g_node):
			var g_lbl: Label = g_node.get_node_or_null("GraveHoverLabel") as Label
			if g_lbl:
				g_lbl.visible = _is_near(player, mouse_pos, g_node.global_position, 22.0, 15.0)
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

	_update_shop_business_stalls(player, mouse_pos)
	_update_doors_and_windows(delta, player, mouse_pos)

func _is_near(player: Node2D, mouse_pos: Vector2, target_pos: Vector2, p_rad: float, m_rad: float) -> bool:
	return (player != null and player.global_position.distance_squared_to(target_pos) <= p_rad * p_rad) or (target_pos.distance_squared_to(mouse_pos) <= m_rad * m_rad)

func _unhandled_input(event: InputEvent) -> void:
	if business_panel and business_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			var player = get_tree().get_first_node_in_group("player") as Node2D
			if event.keycode == KEY_1:
				_on_business_action_1(player)
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_2:
				_on_business_action_2(player)
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_3:
				_on_business_action_3(player)
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_4:
				_on_business_action_4(player)
				get_viewport().set_input_as_handled()
			elif event.keycode in [KEY_5, KEY_ESCAPE]:
				business_panel.visible = false
				get_viewport().set_input_as_handled()
		return

	if morgue_panel and morgue_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_1, KEY_ESCAPE, KEY_ENTER, KEY_E]:
				morgue_panel.visible = false
				get_viewport().set_input_as_handled()
		return

	if church_panel and church_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			var player = get_tree().get_first_node_in_group("player") as Node2D
			if event.keycode == KEY_1:
				_on_church_pray_action(player)
				get_viewport().set_input_as_handled()
			elif event.keycode in [KEY_2, KEY_ESCAPE, KEY_ENTER]:
				church_panel.visible = false
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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_B, KEY_F]:
		var player = get_tree().get_first_node_in_group("player") as Node2D
		if not is_instance_valid(player) or player_being_escorted_to_jail:
			return
		if (player.has_method("is_stunned") and bool(player.call("is_stunned"))) or (player.has_method("is_any_ui_modal_open") and bool(player.call("is_any_ui_modal_open"))):
			return
		if event.keycode == KEY_B and toggle_bar_door_by_player(player):
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F and force_lock_or_shutter_by_player(player):
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
		"is_shuttered": false,
		"manual_override_timer": 0.0
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
		lane_shift = float((abs(agent.name.hash()) % 5) - 2) * 1.5

	# PASADA 1: Si el origen está dentro (o en el umbral de la puerta) de un edificio y el destino está fuera de él,
	# primero salir limpiamente por los tabiques internos y el pasillo de la puerta de ese edificio.
	for b in building_footprints:
		var r_building_check: Rect2 = b["rect"].grow(2.5)
		var r_interior: Rect2 = b["rect"].grow(1.5)
		var d_pos: Vector2 = b["door_pos"]
		var r_door_threshold := Rect2(d_pos - Vector2(16.0, 11.0), Vector2(32.0, 22.0))
		if (r_interior.has_point(from_pos) or r_door_threshold.has_point(from_pos)) and not r_building_check.has_point(to_pos):
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
		var r_target: Rect2 = b["rect"].grow(2.5)
		if r_target.has_point(to_pos):
			var b_id: String = str(b.get("id", ""))
			var d_pos2: Vector2 = b["door_pos"]
			var door_south2: bool = bool(b["door_south"])
			var lane_x2: float = d_pos2.x + lane_shift

			# Si el objetivo (p. ej. un cadáver o el jugador) está pegado a un muro interior, proyectar el punto de destino
			# ligeramente hacia el suelo caminable del interior (a >= 10 px de la pared) para no chocar con el muro
			var r_safe_dest: Rect2 = b["rect"].grow(-10.0)
			var safe_to_pos := Vector2(
				clampf(to_pos.x, r_safe_dest.position.x, r_safe_dest.end.x),
				clampf(to_pos.y, r_safe_dest.position.y, r_safe_dest.end.y)
			)

			var r_inside_room: Rect2 = b["rect"].grow(-3.0)
			var past_door_line: bool = (from_pos.y <= d_pos2.y - 7.0) if door_south2 else (from_pos.y >= d_pos2.y + 7.0)
			var already_inside: bool = r_inside_room.has_point(from_pos) and past_door_line

			if not already_inside:
				var outside_pt2 := Vector2(lane_x2, d_pos2.y + (18.0 if door_south2 else -18.0))
				var inside_pt2 := Vector2(lane_x2, d_pos2.y + (-15.0 if door_south2 else 15.0))

				var aligned_x: bool = absf(from_pos.x - lane_x2) <= 9.5
				var in_door_funnel_y: bool = (from_pos.y >= d_pos2.y - 16.0 and from_pos.y <= d_pos2.y + 22.0) if door_south2 else (from_pos.y >= d_pos2.y - 22.0 and from_pos.y <= d_pos2.y + 16.0)
				if aligned_x and in_door_funnel_y:
					return inside_pt2
				return _avoid_outdoor_buildings(from_pos, outside_pt2, "")
			else:
				# Ya está dentro del edificio destino; comprobar tabiques internos (Posada, Botica Mixta, Hospital, Comisaría)
				return _route_internal_building_partitions(b_id, from_pos, safe_to_pos)

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

		var r_inner: Rect2 = merged_rect.grow(2.5)
		var r_corners: Rect2 = merged_rect.grow(16.0)
		var corners: Array[Vector2] = [
			r_corners.position,
			Vector2(r_corners.end.x, r_corners.position.y),
			r_corners.end,
			Vector2(r_corners.position.x, r_corners.end.y)
		]

		# Si el NPC está rozando el borde exterior del muro (`r_inner`), proyectar su punto de prueba 2 px hacia afuera
		# para que las esquinas de ese lado sigan siendo alcanzables y jamás intente atravesar la pared en línea recta.
		var from_test: Vector2 = from_pos
		if r_inner.has_point(from_test):
			var d_left: float = absf(from_test.x - r_inner.position.x)
			var d_right: float = absf(r_inner.end.x - from_test.x)
			var d_top: float = absf(from_test.y - r_inner.position.y)
			var d_bot: float = absf(r_inner.end.y - from_test.y)
			var min_d: float = minf(minf(d_left, d_right), minf(d_top, d_bot))
			if min_d == d_left:
				from_test.x = r_inner.position.x - 2.0
			elif min_d == d_right:
				from_test.x = r_inner.end.x + 2.0
			elif min_d == d_top:
				from_test.y = r_inner.position.y - 2.0
			else:
				from_test.y = r_inner.end.y + 2.0

		# 1º Buscar esquinas directamente alcanzables desde `from_test` que tengan línea limpia hacia `cur_target`
		var best_direct_c: Vector2 = Vector2.INF
		var best_direct_score: float = INF
		# 2º Si el destino está en la cara opuesta del edificio, elegir la esquina alcanzable más cercana al destino (sin oscilación)
		var best_step_c: Vector2 = cur_target
		var best_step_score: float = INF

		for c in corners:
			if from_pos.distance_squared_to(c) < 25.0:
				continue
			var reachable_from_here: bool = not _segment_intersects_rect(from_test, c, r_inner)
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

	# 1. Camino Largo Oeste-Este desde el Borde Oeste del Mapa (-940, 36) hasta el Borde Este (1010, 48)
	_add_road_rect(Rect2(Vector2(-940, 36), Vector2(1950, 28)), dirt_col)
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

	# 4. Calles del Barrio Residencial, Distrito Hospital/Comisaría Este y Callejón hacia la Iglesia y Cementerio Parroquial
	_add_road_rect(Rect2(Vector2(660, -135), Vector2(310, 24)), dirt_col)
	_add_road_rect(Rect2(Vector2(660, -135), Vector2(24, 240)), dirt_col)
	_add_road_rect(Rect2(Vector2(660, 76), Vector2(325, 22)), stone_col)
	_add_road_rect(Rect2(Vector2(819, 76), Vector2(20, 186)), stone_col)
	_add_road_rect(Rect2(Vector2(720, 244), Vector2(240, 18)), stone_col)

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
	_innkeeper_npc = marta

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
			_build_mixed_shop_house_visuals(sc, str(cfg["shop_title"]), tex_bed, tex_stall, bed1_pos, bed2_pos, table_pos, work_pos, fam_id, int(role_key))
		else:
			var is_smithy: bool = (role_key == VillageNPC.TradeRole.BLACKSMITH)
			_build_enclosed_shop_visuals(sc, str(cfg["shop_title"]), tex_stall, work_pos, bool(cfg["shop_door_south"]), is_smithy, fam_id, int(role_key))
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
	fam_id: String,
	role_id: int = -1
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
	if role_id >= 0:
		_register_shop_business_stall(role_id, shop_title, fam_id, stall.global_position, stall)

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
	fam_id: String,
	role_id: int = -1
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
	if role_id >= 0:
		_register_shop_business_stall(role_id, title, fam_id, stall.global_position, stall)

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

	# Dr. Valen (Médico Cirujano y Forense) — Mesa de comedor propia dentro del Hospital (`Vector2(764, 128)`)
	_spawn_decor_prop("res://assests/Comprados/ Packs/Cute_Fantasy/Buildings/House_Decor/table_1.png", Vector2(764, 128))
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
		Vector2(764, 128),
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
		"table_pos": Vector2(764, 128),
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

	# Comisario Vane y Guardia Rodric (Con mesa de comedor propia en la Comisaría `Vector2(886, 126)` / `Vector2(896, 126)`)
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
		Vector2(886, 126),
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
		"table_pos": Vector2(886, 126),
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
		Vector2(896, 126),
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
		"table_pos": Vector2(896, 126),
		"tex_path": "res://assests/world/village/villager_guard.png",
		"stock": {},
		"family_id": "family_police",
		"family_name": "Guardia del Valle",
		"title": "Oficial de Patrulla",
		"name_pool": ["Guardia Kaelen", "Guardia Darian", "Guardia Brenna", "Guardia Tormund", "Guardia Soren"]
	})

## Devuelve la coordenada exacta en el borde del mapa (Camino Oeste `Vector2(-900, 48)` o Camino Este `Vector2(990, 48)`)
## desde la que cualquier nuevo habitante entra caminando físicamente al pueblo (Prohibido el respawn instantáneo en mitad de la calle).
func _get_map_edge_arrival_pos(index: int = 0) -> Vector2:
	if index % 2 == 0:
		return Vector2(-900.0, 48.0 + float((index % 3) - 1) * 6.0)
	return Vector2(990.0, 48.0 + float((index % 3) - 1) * 6.0)

## Comprueba si ha fallecido el Médico o un agente de Policía para anunciar la vacante institucional.
## NO hace respawn a los 75 segundos: los reemplazos solo llegan al amanecer respetando el límite estricto de `MAX_DAILY_ARRIVALS = 2` personas por día.
func _check_authority_vacancy_announcements() -> void:
	for slot in _authority_slots:
		var cur_npc: VillageNPC = slot.get("npc")
		if is_instance_valid(cur_npc) and not cur_npc.is_dead:
			continue
		if not bool(slot.get("vacancy_announced", false)):
			slot["vacancy_announced"] = true
			var p = get_tree().get_first_node_in_group("player")
			if p and p.has_method("show_hint"):
				p.show_hint("📢 Vacante en el Valle: %s ha muerto. Un reemplazo novato llegará caminando desde el borde del mapa en los próximos días (Máx. %d llegadas/día)." % [str(slot["title"]), MAX_DAILY_ARRIVALS])

func _spawn_authority_replacement(slot: Dictionary) -> VillageNPC:
	_rehire_counter += 1
	var pool: Array = slot.get("name_pool", ["Oficial de Reemplazo"])
	var new_name: String = str(pool[_rehire_counter % pool.size()])
	var new_npc := VillageNPC.new()
	new_npc.name = "NPC_Rehired_%d_%s" % [_rehire_counter, new_name.replace(" ", "_").replace(".", "")]
	new_npc.npc_name = new_name
	new_npc.npc_role = str(slot["title"]) + " (Recién Llegado)"
	new_npc.trade_role = slot["role"]
	new_npc.days_in_role = 0 # Empieza como Novato al 35% de eficiencia y necesita 7 días para alcanzar el 100%
	new_npc.tavern_social_pos = _tavern_social_pos
	entities_root.add_child(new_npc)
	var stock_copy: Dictionary = (slot.get("stock", {}) as Dictionary).duplicate()
	new_npc.setup_npc(
		_load_tex(str(slot["tex_path"])),
		slot["work_pos"],
		slot["bed_pos"],
		stock_copy,
		slot.get("table_pos", _tavern_social_pos),
		str(slot["family_id"]),
		str(slot["family_name"])
	)
	# Llega caminando físicamente desde el borde del mapa por el camino principal
	new_npc.global_position = _get_map_edge_arrival_pos(_rehire_counter)
	slot["npc"] = new_npc
	slot["rehire_timer"] = 0.0
	slot["vacancy_announced"] = false
	authority_npcs.append(new_npc)

	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("show_hint"):
		if slot["role"] == VillageNPC.TradeRole.DOCTOR:
			p.show_hint("🏥🚶 %s (%s · Novato 35%%) está entrando al valle por el camino principal hacia el Hospital." % [new_name, str(slot["title"])])
		else:
			p.show_hint("🚓🚶 %s (%s · Novato 35%%) está entrando al valle por el camino principal hacia la Comisaría." % [new_name, str(slot["title"])])
	return new_npc

# ==============================================================================
# PASO 2B: ⛪ CAPILLA DE SAN CIPRIANO Y 🪦 CEMENTERIO PARROQUIAL (`Vector2(745, 312)`)
# ==============================================================================
func _spawn_church_and_cemetery() -> void:
	# 1. Construcción sólida de la Capilla de San Cipriano al sur del Hospital
	_construct_solid_building(
		"building_church",
		"⛪ Capilla de San Cipriano",
		_church_center,
		Vector2(132, 92),
		false,
		"res://assests/world/village/floor_stone_forge.png",
		"res://assests/world/village/wall_stone_h.png",
		"res://assests/world/village/wall_stone_v.png",
		42.0,
		0.0,
		Color(0.92, 0.86, 1.0)
	)

	# Alfombra púrpura/dorada del pasillo central hacia el Altar
	var aisle_poly := Polygon2D.new()
	aisle_poly.polygon = PackedVector2Array([
		_church_center + Vector2(-12, -42),
		_church_center + Vector2(12, -42),
		_church_center + Vector2(12, 34),
		_church_center + Vector2(-12, 34)
	])
	aisle_poly.color = Color(0.46, 0.16, 0.36, 0.72)
	aisle_poly.z_index = -1
	entities_root.add_child(aisle_poly)

	# 4 Bancos de madera de oración (2 a la izquierda y 2 a la derecha del pasillo)
	for pew_offset in [Vector2(-36, -16), Vector2(-36, 6), Vector2(36, -16), Vector2(36, 6)]:
		var pew := Polygon2D.new()
		pew.polygon = PackedVector2Array([
			Vector2(-18, -5), Vector2(18, -5), Vector2(18, 5), Vector2(-18, 5)
		])
		pew.color = Color(0.46, 0.30, 0.16, 0.96)
		pew.global_position = _church_center + pew_offset
		pew.z_index = -1
		entities_root.add_child(pew)

	# Altar Sagrado y Libro Parroquial de Difuntos al Sur de la Capilla (`_church_altar_pos`)
	var altar_base := Polygon2D.new()
	altar_base.polygon = PackedVector2Array([
		Vector2(-24, -8), Vector2(24, -8), Vector2(24, 8), Vector2(-24, 8)
	])
	altar_base.color = Color(0.82, 0.78, 0.72, 1.0)
	altar_base.global_position = _church_altar_pos
	altar_base.z_index = -1
	entities_root.add_child(altar_base)

	var altar_cloth := Polygon2D.new()
	altar_cloth.polygon = PackedVector2Array([
		Vector2(-14, -8), Vector2(14, -8), Vector2(14, 8), Vector2(-14, 8)
	])
	altar_cloth.color = Color(0.88, 0.72, 0.24, 0.95)
	altar_cloth.global_position = _church_altar_pos
	altar_cloth.z_index = -1
	entities_root.add_child(altar_cloth)

	_add_station_area("ChurchAltarArea", _church_altar_pos, 22.0, "church_altar")
	_church_altar_label = _make_station_label(_church_altar_pos + Vector2(-125, -28), "⛪ Altar y Libro de Difuntos [E: Consultar Sepulturas / Orar]")
	entities_root.add_child(_church_altar_label)

	# 2. Cementerio Parroquial al Este de la Capilla (sur de la Comisaría, `Rect2(826, 262, 166, 98)`)
	var cem_ground := Polygon2D.new()
	cem_ground.polygon = PackedVector2Array([
		Vector2(826, 262), Vector2(992, 262), Vector2(992, 360), Vector2(826, 360)
	])
	cem_ground.color = Color(0.22, 0.30, 0.22, 0.78)
	cem_ground.z_index = -2
	entities_root.add_child(cem_ground)

	# Verja perimetral de hierro forjado del Cementerio (dejando entrada abierta en `x = 870..906, y = 262`)
	var fence_border := Line2D.new()
	fence_border.width = 2.5
	fence_border.default_color = Color(0.26, 0.28, 0.34, 0.95)
	fence_border.points = PackedVector2Array([
		Vector2(870, 262), Vector2(826, 262), Vector2(826, 360),
		Vector2(992, 360), Vector2(992, 262), Vector2(906, 262)
	])
	fence_border.z_index = 0
	entities_root.add_child(fence_border)

	# Letrero fijo del Cementerio Parroquial
	var cem_title := Label.new()
	cem_title.text = "🪦 Cementerio Parroquial de San Cipriano"
	cem_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cem_title.position = Vector2(784, 244)
	cem_title.custom_minimum_size = Vector2(250, 16)
	cem_title.add_theme_font_size_override("font_size", 8)
	cem_title.add_theme_color_override("font_color", Color(0.82, 0.86, 0.96))
	cem_title.add_theme_color_override("font_outline_color", Color.BLACK)
	cem_title.add_theme_constant_override("outline_size", 3)
	entities_root.add_child(cem_title)

	_add_station_area("CemeteryGateArea", _cemetery_gate_pos, 22.0, "cemetery_gate")
	_cemetery_label = _make_station_label(_cemetery_gate_pos + Vector2(-125, -26), "🪦 Cementerio Parroquial [E: Inspeccionar Sepulturas]")
	entities_root.add_child(_cemetery_label)

	# Generar las 18 parcelas físicas de tumbas (3 filas x 6 columnas)
	_cemetery_grave_positions.clear()
	for row_i in range(3):
		for col_i in range(6):
			var g_pos := Vector2(844.0 + float(col_i) * 26.0, 282.0 + float(row_i) * 28.0)
			_cemetery_grave_positions.append(g_pos)
			# Marca sutil de parcela vacía en el césped del camposanto
			var plot_mark := Polygon2D.new()
			plot_mark.polygon = PackedVector2Array([
				Vector2(-7, -9), Vector2(7, -9), Vector2(7, 9), Vector2(-7, 9)
			])
			plot_mark.color = Color(0.18, 0.24, 0.18, 0.50)
			plot_mark.global_position = g_pos
			plot_mark.z_index = -2
			entities_root.add_child(plot_mark)

## Indica si queda al menos 1 de las 3 camillas de acero libres en la Morgue del Hospital (`MAX_MORGUE_CAPACITY = 3`)
func has_free_morgue_table() -> bool:
	return morgue_active_corpses.size() < MAX_MORGUE_CAPACITY

## Devuelve la posición a la que se llevan los cadáveres cuando las 3 camillas de la Morgue están llenas
func get_cemetery_burial_target_pos() -> Vector2:
	var next_idx: int = buried_graves.size()
	if next_idx >= 0 and next_idx < _cemetery_grave_positions.size():
		return _cemetery_grave_positions[next_idx]
	return _cemetery_burial_pos

func _refresh_morgue_table_sprites() -> void:
	for i in range(_morgue_corpse_sprites.size()):
		if is_instance_valid(_morgue_corpse_sprites[i]):
			_morgue_corpse_sprites[i].visible = (i < morgue_active_corpses.size())

## Sepulta físicamente un cuerpo en la siguiente parcela libre del Cementerio Parroquial y crea su lápida e inscripción
func _bury_corpse_in_cemetery(rec: Dictionary, burial_reason: String = "Sepultura parroquial") -> void:
	if bool(rec.get("buried", false)):
		return
	rec["buried"] = true
	rec["burial_reason"] = burial_reason
	rec["burial_day"] = WorldClock.current_day if WorldClock else 1
	var grave_idx: int = buried_graves.size()
	rec["grave_index"] = grave_idx
	buried_graves.append(rec)
	_spawn_physical_grave_marker(grave_idx, rec)

func _spawn_physical_grave_marker(grave_idx: int, rec: Dictionary) -> void:
	if not is_instance_valid(entities_root):
		return
	var g_pos: Vector2 = _cemetery_burial_pos
	if grave_idx >= 0 and grave_idx < _cemetery_grave_positions.size():
		g_pos = _cemetery_grave_positions[grave_idx]
	else:
		g_pos = Vector2(844.0 + float(grave_idx % 6) * 26.0, 282.0 + float((grave_idx / 6) % 3) * 28.0)

	var grave_node := Node2D.new()
	grave_node.name = "GraveMarker_%d" % (grave_idx + 1)
	grave_node.global_position = g_pos
	entities_root.add_child(grave_node)
	_cemetery_grave_nodes.append(grave_node)

	# Montículo de tierra recién removida
	var mound := Polygon2D.new()
	mound.polygon = PackedVector2Array([
		Vector2(-7, -2), Vector2(7, -2), Vector2(8, 10), Vector2(-8, 10)
	])
	mound.color = Color(0.36, 0.25, 0.16, 0.95)
	mound.z_index = -1
	grave_node.add_child(mound)

	# Lápida de piedra tallada en la cabecera norte
	var headstone := Polygon2D.new()
	headstone.polygon = PackedVector2Array([
		Vector2(-6, -11), Vector2(-4, -14), Vector2(4, -14), Vector2(6, -11),
		Vector2(6, -2), Vector2(-6, -2)
	])
	headstone.color = Color(0.68, 0.72, 0.78, 1.0)
	headstone.z_index = 0
	grave_node.add_child(headstone)

	# Cruz grabada en la lápida
	var cross_v := Polygon2D.new()
	cross_v.polygon = PackedVector2Array([
		Vector2(-1, -12), Vector2(1, -12), Vector2(1, -4), Vector2(-1, -4)
	])
	cross_v.color = Color(0.32, 0.35, 0.40, 1.0)
	cross_v.z_index = 1
	grave_node.add_child(cross_v)

	var cross_h := Polygon2D.new()
	cross_h.polygon = PackedVector2Array([
		Vector2(-3, -10), Vector2(3, -10), Vector2(3, -8), Vector2(-3, -8)
	])
	cross_h.color = Color(0.32, 0.35, 0.40, 1.0)
	cross_h.z_index = 1
	grave_node.add_child(cross_h)

	var v_name: String = str(rec.get("victim_name", "Aldeano"))
	var v_role: String = str(rec.get("victim_role", "Habitante"))
	var v_cause: String = str(rec.get("cause_of_death", "Causa desconocida"))
	var b_day: int = int(rec.get("burial_day", 1))
	var g_lbl := _make_station_label(
		Vector2(-125, -34),
		"🪦 Tumba #%d: R.I.P. %s (%s)\n[Sepultado Día %d | %s | E: Libro de Difuntos]" % [grave_idx + 1, v_name, v_role, b_day, v_cause]
	)
	g_lbl.name = "GraveHoverLabel"
	g_lbl.add_theme_color_override("font_color", Color(0.86, 0.90, 1.0))
	grave_node.add_child(g_lbl)

func _rebuild_cemetery_graves_from_save() -> void:
	for g_n in _cemetery_grave_nodes:
		if is_instance_valid(g_n):
			g_n.name = "_freed_grave_" + str(g_n.get_instance_id())
			if g_n.get_parent():
				g_n.get_parent().remove_child(g_n)
			g_n.queue_free()
	_cemetery_grave_nodes.clear()
	for i in range(buried_graves.size()):
		if typeof(buried_graves[i]) == TYPE_DICTIONARY:
			_spawn_physical_grave_marker(i, buried_graves[i])

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
	var cloak_mult: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
	var max_witness_dist: float = (34.0 if in_stealth else 160.0) * cloak_mult

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
	var eff_dist: float = max_dist
	if WorldClock and WorldClock.has_method("get_weather_vision_multiplier"):
		eff_dist *= float(WorldClock.call("get_weather_vision_multiplier"))
	var best_d2: float = eff_dist * eff_dist
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

## Paso 2: Agresión vista en directo contra un aldeano o contra una mascota doméstica (solo si un testigo tiene línea de visión directa sin muros)
func report_assault_crime(victim: VillageNPC) -> void:
	if not victim:
		return
	var witness: VillageNPC = _find_conscious_witness_near(victim.global_position, 155.0, victim)
	var victim_officer_conscious: bool = victim.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR] and not victim.is_dead and not victim.is_downed and not victim.is_sleeping and not victim.is_stunned_flag and victim.sedated_timer <= 0.0
	if witness != null or victim_officer_conscious:
		wanted_level = clampi(wanted_level + 1, 1, 5)
		bounty_gold += 25
		if victim.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR]:
			is_resisting_arrest = true
			alert_police_to_resist(get_tree().get_first_node_in_group("player") as Node2D)
		var w_name: String = witness.npc_name if witness != null else victim.npc_name
		var msg := "👁️🚨 ¡%s presenció el ataque a %s! (+25 Oro de multa policial)" % [w_name, victim.npc_name]
		crime_history.push_front(msg)
		_notify_inquisitor_of_police_crime(msg, 24)
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("show_hint"):
			player.show_hint(msg)

func report_pet_assault_crime(pet: Node2D) -> void:
	if not pet or ("family_id" in pet and str(pet.get("family_id")) == "player_farm"):
		return
	var witness: VillageNPC = _find_conscious_witness_near(pet.global_position, 145.0, null)
	if witness != null:
		wanted_level = clampi(wanted_level + 1, 1, 5)
		bounty_gold += 18
		var p_name: String = str(pet.get("pet_name")) if "pet_name" in pet else "una mascota"
		var fam_id: String = str(pet.get("family_id")) if "family_id" in pet else "none"
		if fam_id != "none" and fam_id != "player_farm":
			modify_family_reputation(fam_id, -25, "Atacó a su mascota " + p_name)
		var msg := "🐾🚨 ¡%s te vio atacar a %s! (+18 Oro de multa por crueldad)" % [witness.npc_name, p_name]
		crime_history.push_front(msg)
		_notify_inquisitor_of_police_crime(msg, 14)
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("show_hint"):
			player.show_hint(msg)

func report_theft_crime(fam_id: String, reason: String, crime_pos: Vector2) -> void:
	var witness: VillageNPC = _find_conscious_witness_near(crime_pos, 145.0, null)
	if witness != null:
		wanted_level = clampi(wanted_level + 1, 1, 5)
		bounty_gold += 20
		if fam_id != "none" and fam_id != "player_farm":
			modify_family_reputation(fam_id, -20, reason)
		var msg := "🕵️🚨 ¡%s te vio cometer robo (%s)! (+20 Oro de multa policial)" % [witness.npc_name, reason]
		crime_history.push_front(msg)
		_notify_inquisitor_of_police_crime(msg, 16)
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("show_hint"):
			player.show_hint(msg)

## Paso 1 y Paso 2: Cuando un NPC descubre un cadáver y lo traslada a la Morgue (máx. 3 camillas) o al Cementerio Parroquial (si la Morgue está llena)
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
	var cur_d: int = WorldClock.current_day if WorldClock else d
	var cur_h: int = WorldClock.current_hour if WorldClock else h
	var added_total_hours: int = cur_d * 24 + cur_h
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
			player_murder_warrants_count += 1
			_notify_inquisitor_of_police_crime("Orden de captura forense emitida: %s vio al Forastero asesinar a %s." % [mw, victim.npc_name], 45)
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
					player_murder_warrants_count += 1
					_notify_inquisitor_of_police_crime("Cruce forense en Morgue: %s situó al Forastero en el asesinato de %s." % [w_name, victim.npc_name], 38)
					break

	var record: Dictionary = {
		"victim_name": victim.npc_name,
		"victim_role": victim.npc_role,
		"family_name": victim.family_name,
		"time_str": time_str,
		"crime_scene": crime_scene_name,
		"cause_of_death": weapon_name,
		"witness_clue": witness_clue,
		"suspect": suspect_str,
		"added_total_hours": added_total_hours,
		"buried": false
	}
	corpse_records.push_front(record)

	var buried_directly := false
	if morgue_active_corpses.size() < MAX_MORGUE_CAPACITY:
		morgue_active_corpses.append(record)
		_refresh_morgue_table_sprites()
	else:
		buried_directly = true
		_bury_corpse_in_cemetery(record, "Sepultura directa (Morgue al límite de 3/3 camillas)")
		_refresh_morgue_table_sprites()

	# Si el Inquisidor Real Alistair está activo en el valle, re-cruzar los expedientes de la Morgue y Comisaría con el nuevo cadáver registrado
	if bool(active_royal_investigation.get("active", false)) and is_instance_valid(_royal_investigator_npc):
		active_royal_investigation["morgue_checked"] = false
		_cross_check_morgue_and_police_records(
			_royal_investigator_npc,
			active_royal_investigation.get("suspects", {}),
			active_royal_investigation.get("clues_log", [])
		)

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("show_hint"):
		if buried_directly:
			if suspect_str.begins_with("Jugador"):
				player.show_hint("🪦🚨 La Morgue está llena (3/3): %s fue sepultado en el Cementerio Parroquial. ¡%s! (Multa: %d Oro)." % [victim.npc_name, witness_clue, bounty_gold])
			else:
				player.show_hint("🪦⛪ La Morgue está llena (3/3 camillas): El cuerpo de %s fue sepultado directamente en el Cementerio de la Iglesia." % victim.npc_name)
		else:
			if suspect_str.begins_with("Jugador"):
				player.show_hint("⚰️🚨 El cuerpo de %s fue trasladado a la Morgue (%d/3). ¡%s! Orden de arresto emitida (Multa: %d Oro)." % [victim.npc_name, morgue_active_corpses.size(), witness_clue, bounty_gold])
			else:
				player.show_hint("⚰️🕵️ El cuerpo de %s está en la Morgue Forense (%d/3 camillas). Se enterrará en el Cementerio tras 18h." % [victim.npc_name, morgue_active_corpses.size()])

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

	# 4. Modal de Gestión de Negocios, Oferta/Demanda, Sabotaje y Escrituras de Propiedad (Fase 8)
	business_panel = _create_styled_modal(Vector2(540, 310), Color(0.96, 0.80, 0.32))
	ui_layer.add_child(business_panel)
	var biz_vbox := VBoxContainer.new()
	biz_vbox.add_theme_constant_override("separation", 7)
	business_panel.add_child(biz_vbox)
	business_info_lbl = Label.new()
	business_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	business_info_lbl.add_theme_font_size_override("font_size", 11)
	business_info_lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.84))
	biz_vbox.add_child(business_info_lbl)

	_biz_btn_1 = Button.new()
	_biz_btn_1.pressed.connect(func(): _on_business_action_1(get_tree().get_first_node_in_group("player") as Node2D))
	biz_vbox.add_child(_biz_btn_1)

	_biz_btn_2 = Button.new()
	_biz_btn_2.pressed.connect(func(): _on_business_action_2(get_tree().get_first_node_in_group("player") as Node2D))
	biz_vbox.add_child(_biz_btn_2)

	_biz_btn_3 = Button.new()
	_biz_btn_3.pressed.connect(func(): _on_business_action_3(get_tree().get_first_node_in_group("player") as Node2D))
	biz_vbox.add_child(_biz_btn_3)

	_biz_btn_4 = Button.new()
	_biz_btn_4.pressed.connect(func(): _on_business_action_4(get_tree().get_first_node_in_group("player") as Node2D))
	biz_vbox.add_child(_biz_btn_4)

	var biz_close := Button.new()
	biz_close.text = "[5 / ESC] Cerrar Panel del Negocio"
	biz_close.pressed.connect(func(): business_panel.visible = false)
	biz_vbox.add_child(biz_close)

	# 5. Modal de la Capilla de San Cipriano y Libro de Sepulturas del Cementerio Parroquial
	church_panel = _create_styled_modal(Vector2(520, 285), Color(0.82, 0.72, 0.96))
	ui_layer.add_child(church_panel)
	var ch_vbox := VBoxContainer.new()
	ch_vbox.add_theme_constant_override("separation", 8)
	church_panel.add_child(ch_vbox)
	church_info_lbl = Label.new()
	church_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	church_info_lbl.add_theme_font_size_override("font_size", 11)
	church_info_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0))
	ch_vbox.add_child(church_info_lbl)
	var ch_pray := Button.new()
	ch_pray.text = "[1] 🕯️ Encender Vela y Orar por los Difuntos (-5 Oro -> +Calma / +Reputación Vecinal)"
	ch_pray.pressed.connect(func(): _on_church_pray_action(get_tree().get_first_node_in_group("player") as Node2D))
	ch_vbox.add_child(ch_pray)
	var ch_close := Button.new()
	ch_close.text = "[2 / ESC] Cerrar Libro Parroquial de Difuntos"
	ch_close.pressed.connect(func(): church_panel.visible = false)
	ch_vbox.add_child(ch_close)

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
	if morgue_active_corpses.is_empty():
		var buried_note: String = "\n🪦 Hay %d difuntos ya sepultados en el Cementerio Parroquial (al sur del Hospital)." % buried_graves.size() if not buried_graves.is_empty() else ""
		morgue_info_lbl.text = "⚰️ SALA DE AUTOPSIAS — MORGUE FORENSE DEL HOSPITAL (0/%d Camillas Ocupadas)\n\nLas 3 camillas de acero inoxidable están despejadas actualmente.%s\n\n(Los cuerpos permanecen en la Morgue hasta 18 horas durante la autopsia y luego reciben sepultura en el Cementerio de la Iglesia)." % [MAX_MORGUE_CAPACITY, buried_note]
	else:
		var lines: Array[String] = ["⚰️ CAMILLAS ACTIVAS DE LA MORGUE (%d/%d Ocupadas | %d Sepultados en Cementerio):" % [morgue_active_corpses.size(), MAX_MORGUE_CAPACITY, buried_graves.size()]]
		for i in range(morgue_active_corpses.size()):
			var rec: Dictionary = morgue_active_corpses[i]
			lines.append("• Camilla #%d: %s (%s — %s)\n   🕒 %s | 📍 %s\n   🗡️ Causa Forense: %s\n   👁️ Pista Testigos: %s\n   ⚖️ Sospechoso Policial: %s" % [
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

func _open_church_registry_ui() -> void:
	if not church_panel:
		return
	var lines: Array[String] = [
		"⛪ CAPILLA DE SAN CIPRIANO Y LIBRO PARROQUIAL DE DIFUNTOS",
		"⚰️ En Morgue Forense: %d/3 camillas | 🪦 En Cementerio Parroquial: %d/18 tumbas ocupadas" % [morgue_active_corpses.size(), buried_graves.size()]
	]
	if buried_graves.is_empty():
		lines.append("\n🕊️ El camposanto parroquial aún no tiene tumbas ocupadas.\nCuando un cuerpo completa su examen forense en la Morgue (18h) o cuando las 3 camillas de la Morgue se llenan, los difuntos son trasladados y sepultados aquí con su propia lápida física.")
	else:
		lines.append("\n🪦 REGISTRO DE SEPULTURAS EN EL CEMENTERIO:")
		var start_idx: int = maxi(0, buried_graves.size() - 5)
		for i in range(buried_graves.size() - 1, start_idx - 1, -1):
			var g: Dictionary = buried_graves[i]
			lines.append("• Tumba #%d: R.I.P. %s (%s — %s) | Sepultado Día %d\n   🗡️ Causa: %s | 📜 %s" % [
				int(g.get("grave_index", i)) + 1,
				str(g.get("victim_name", "")),
				str(g.get("victim_role", "")),
				str(g.get("family_name", "")),
				int(g.get("burial_day", 1)),
				str(g.get("cause_of_death", "")),
				str(g.get("burial_reason", "Sepultura parroquial"))
			])
	church_info_lbl.text = "\n".join(lines)
	church_panel.visible = true

func _on_church_pray_action(player: Node2D) -> void:
	if not player or not ("inventory" in player) or not player.inventory:
		return
	var inv: SimpleInventory = player.inventory
	if inv.gold < 5:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("❌ Necesitas 5 Oro para la ofrenda de velas del altar", Color.ORANGE_RED, -42.0)
		return
	inv.add_gold(-5)
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if not v.is_dead:
				v.affinity = clampi(v.affinity + 3, -100, 100)
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🕯️🙏 Encendiste una vela por los difuntos (-5 Oro, +3 Afinidad en el pueblo)", Color(0.95, 0.88, 1.0), -44.0)
	_open_church_registry_ui()

func clear_police_hostility() -> void:
	var hunting_player_royally: bool = bool(active_royal_investigation.get("active", false)) and str(active_royal_investigation.get("stage", "")) == "HUNTING_PLAYER" and not player_in_jail and not player_being_escorted_to_jail
	if not hunting_player_royally:
		is_resisting_arrest = false
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.trade_role == VillageNPC.TradeRole.ROYAL_INVESTIGATOR and hunting_player_royally:
				continue
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
	if bool(active_royal_investigation.get("active", false)) and str(active_royal_investigation.get("stage", "")) == "HUNTING_PLAYER":
		if is_instance_valid(_royal_investigator_npc) and not _royal_investigator_npc.is_dead and not _royal_investigator_npc.is_downed:
			_royal_investigator_npc.is_hostile = true
			_royal_investigator_npc._police_alerted_timer = 45.0
			if not _royal_investigator_npc.is_in_group("enemies"):
				_royal_investigator_npc.add_to_group("enemies")

func trigger_police_confrontation(officer: VillageNPC = null) -> void:
	if _police_confront_cooldown > 0.0 or not police_panel:
		return
	if player_in_jail or not is_resisting_arrest:
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
			if v.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR] and not v.is_dead and not v.is_downed and not v.is_stunned_flag and v.sedated_timer <= 0.0:
				var d: float = pos.distance_to(v.global_position)
				if d < best_d:
					best_d = d
					best = v
	if best == null:
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC:
				var v := n as VillageNPC
				if v.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR] and not v.is_dead and not v.is_downed:
					var d2: float = pos.distance_to(v.global_position)
					if d2 < best_d:
						best_d = d2
						best = v
	return best

## Inicia la escolta física del jugador esposado caminando por las calles y puertas hasta la celda (Estilo Kenshi / RDR2)
func start_police_escort_to_jail(player: Node2D, officer: VillageNPC = null) -> void:
	if not player:
		return
	var chosen_officer: VillageNPC = officer if (officer != null and is_instance_valid(officer) and not officer.is_dead and not officer.is_downed and not officer.is_stunned_flag and officer.sedated_timer <= 0.0) else _find_nearest_police_officer(player.global_position)
	player_being_escorted_to_jail = true
	player_in_jail = false
	escorting_officer = chosen_officer
	clear_police_hostility()
	if police_panel:
		police_panel.visible = false
	if "velocity" in player:
		player.velocity = Vector2.ZERO
	if chosen_officer != null:
		chosen_officer.is_sleeping = false
		chosen_officer.sedated_timer = 0.0
		chosen_officer.is_stunned_flag = false
		if chosen_officer.sprite:
			chosen_officer.sprite.rotation_degrees = 0.0
			chosen_officer.sprite.modulate = Color.WHITE
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
	player_arrests_count += 1
	jail_mandatory_stay_timer = JAIL_MANDATORY_STAY_SECONDS
	set_jail_cell_gate_locked(true)
	_notify_inquisitor_of_police_crime("El Comisario Vane encarceló al Forastero en el calabozo municipal.", 42)
	if not active_royal_investigation.is_empty() and bool(active_royal_investigation.get("active", false)):
		var cur_stg: String = str(active_royal_investigation.get("stage", ""))
		# Si Alistair ya pasó la Morgue y estaba interrogando al pueblo, acude de inmediato a los barrotes de la celda;
		# si aún está en CRIME_SCENE o MORGUE, primero termina la autopsia (~10s) y luego va directo a INITIAL_PLAYER_INTERVIEW.
		if cur_stg == "INTERVIEWS":
			var cur_t: String = str(active_royal_investigation.get("current_interview_target", ""))
			if cur_t != "":
				var q_arr: Array = active_royal_investigation.get("interview_queue", [])
				q_arr.push_front(cur_t)
				active_royal_investigation["current_interview_target"] = ""
			active_royal_investigation["stage"] = "INITIAL_PLAYER_INTERVIEW"
			active_royal_investigation["stage_timer"] = 0.0
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
	if bool(active_royal_investigation.get("active", false)) and str(active_royal_investigation.get("stage", "")) == "HUNTING_PLAYER":
		active_royal_investigation["stage"] = "DEPARTING"
		active_royal_investigation["stage_timer"] = 0.0
		if is_instance_valid(_royal_investigator_npc):
			_royal_investigator_npc.is_hostile = false
			_royal_investigator_npc.remove_from_group("enemies")
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
	if bool(active_royal_investigation.get("active", false)) and str(active_royal_investigation.get("stage", "")) == "HUNTING_PLAYER" and not player_in_jail:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("⚖️👑 Orden de Captura Real activa: debes entregarte en la Celda [1] antes de pagar fianza", Color.ORANGE_RED, -44.0)
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
	if not player_in_jail:
		player_arrests_count += 1
		_notify_inquisitor_of_police_crime("El Forastero pagó %d Oro de fianza policial tras ser detenido por la Guardia." % cost, 30)
	clear_police_hostility()
	player_being_escorted_to_jail = false
	escorting_officer = null
	jail_mandatory_stay_timer = 0.0
	wanted_level = 0
	bounty_gold = 0
	if player_in_jail:
		player_in_jail = false
		set_jail_cell_gate_locked(false)
	if bool(active_royal_investigation.get("active", false)) and str(active_royal_investigation.get("stage", "")) == "HUNTING_PLAYER":
		active_royal_investigation["stage"] = "DEPARTING"
		active_royal_investigation["stage_timer"] = 0.0
		if is_instance_valid(_royal_investigator_npc):
			_royal_investigator_npc.is_hostile = false
			_royal_investigator_npc.remove_from_group("enemies")
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
		{"type": DomesticPet.PetType.DOG, "name": "Toby", "owner": "Granja del Jugador", "fam": "player_farm", "pos": Vector2(128, 126), "guard": true, "tint": Color(1.0, 0.96, 0.90)},
		{"type": DomesticPet.PetType.DOG, "name": "Sultán", "owner": "Herrería Yunque Gris", "fam": "family_smith", "pos": Vector2(365, 16), "guard": false, "tint": Color(0.88, 0.82, 0.78)},
		{"type": DomesticPet.PetType.DOG, "name": "Canela", "owner": "Barrio Residencial", "fam": "family_carpenter", "pos": Vector2(745, -135), "guard": false, "tint": Color(1.0, 0.85, 0.72)},
		{"type": DomesticPet.PetType.CAT, "name": "Michi", "owner": "Posada El Jabalí Dorado", "fam": "family_tavern", "pos": Vector2(405, -168), "guard": false, "tint": Color(1.0, 0.92, 0.82)},
		{"type": DomesticPet.PetType.CAT, "name": "Pelusa", "owner": "Botica Raíz Verde", "fam": "family_herbalist", "pos": Vector2(325, 96), "guard": false, "tint": Color(0.92, 0.92, 0.98)},
		{"type": DomesticPet.PetType.CAT, "name": "Sombra", "owner": "Pescadería Aguas Claras", "fam": "family_fishmonger", "pos": Vector2(465, 96), "guard": false, "tint": Color(0.75, 0.78, 0.85)}
	]
	for pdef in pet_defs:
		var p_pos: Vector2 = pdef["pos"]
		_spawn_pet_bed_and_bowl(p_pos, pdef["type"], str(pdef["name"]))
		var pet := DomesticPet.new()
		pet.name = "Pet_" + str(pdef["name"])
		pet.pet_type = pdef["type"]
		pet.pet_name = str(pdef["name"])
		pet.owner_label = str(pdef["owner"])
		pet.family_id = str(pdef["fam"])
		pet.home_position = p_pos
		pet.global_position = p_pos
		pet.is_guard_dog = bool(pdef["guard"])
		pet.tint_color = pdef["tint"]
		entities_root.add_child(pet)
		domestic_pets.append(pet)

func _spawn_pet_bed_and_bowl(pos: Vector2, p_type: int, _p_name: String) -> void:
	if not is_instance_valid(entities_root):
		return
	var bed_root := Node2D.new()
	bed_root.name = "PetBed_" + _p_name
	bed_root.global_position = pos
	bed_root.z_index = -1
	entities_root.add_child(bed_root)

	# Borde de madera / cesta de descanso de la mascota
	var rim := Polygon2D.new()
	rim.polygon = PackedVector2Array([
		Vector2(-9, -5), Vector2(9, -5), Vector2(10, 5), Vector2(-10, 5)
	])
	rim.color = Color(0.45, 0.28, 0.15, 0.95) if p_type == DomesticPet.PetType.DOG else Color(0.52, 0.34, 0.22, 0.95)
	bed_root.add_child(rim)

	# Cojín / manta interior donde duerme la mascota
	var cushion := Polygon2D.new()
	cushion.polygon = PackedVector2Array([
		Vector2(-7, -3), Vector2(7, -3), Vector2(8, 3), Vector2(-8, 3)
	])
	cushion.color = Color(0.76, 0.28, 0.24, 0.95) if p_type == DomesticPet.PetType.DOG else Color(0.32, 0.56, 0.78, 0.95)
	bed_root.add_child(cushion)

	# Cuenco de comida junto a la cama
	var bowl := Polygon2D.new()
	bowl.polygon = PackedVector2Array([
		Vector2(11, -1), Vector2(16, -1), Vector2(15, 3), Vector2(12, 3)
	])
	bowl.color = Color(0.78, 0.68, 0.32, 0.95)
	bed_root.add_child(bowl)

## Comprueba si la familia dueña de una mascota sigue viva y con recursos para alimentarla en su casa.
## Si la familia dueña ha sido asesinada y no hay comida en el pueblo, la mascota pasa hambre real.
func can_family_feed_pet(fam_id: String) -> bool:
	if fam_id == "player_farm":
		for r_id in [int(VillageNPC.TradeRole.FISHMONGER), int(VillageNPC.TradeRole.BUTCHER), int(VillageNPC.TradeRole.HERBALIST)]:
			if get_trade_total_stock(r_id) > 0:
				return true
		return is_instance_valid(_innkeeper_npc) and not _innkeeper_npc.is_dead
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.family_id == fam_id and not v.is_dead and not v.is_downed:
				return true
	return false

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

	# 2. Si hay un cadáver, herido abatido o NPC aturdido/sedado cerca del jugador (<= 32 px), priorizar saquear/reanimar/reportar con [E]
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var c := n as VillageNPC
			if pos.distance_to(c.global_position) <= 32.0:
				var can_loot_pockets: bool = not c.corpse_pocket_looted and (c.personal_gold > 0 or c.carries_royal_safe_conduct)
				var mouse_aiming_c: bool = c.global_position.distance_to(mouse_pos) <= 20.0
				if (c.is_dead and c.corpse_on_ground and not c.corpse_in_morgue and (can_loot_pockets or not c.corpse_reported or mouse_aiming_c)) or (not c.is_dead and (c.is_downed or ((c.sedated_timer > 0.0 or c.is_stunned_flag) and can_loot_pockets))):
					c.interact(player)
					return true

	# 3. Si el jugador apunta con el ratón directamente a un mostrador de negocio (<= 16 px) o el local no tiene dueño presente cerca, abrir Panel de Negocio
	var near_stall: Dictionary = _find_nearest_business_stall(pos, 26.0)
	if not near_stall.is_empty():
		var s_pos: Vector2 = near_stall.get("stall_pos", Vector2.ZERO)
		var b_role: int = int(near_stall.get("role", -1))
		var holder: VillageNPC = trade_npcs.get(b_role)
		var holder_present: bool = is_instance_valid(holder) and not holder.is_dead and not holder.is_downed and not holder.is_sleeping and not holder.is_stunned_flag and holder.sedated_timer <= 0.0 and holder.global_position.distance_to(pos) <= 28.0
		if s_pos.distance_to(mouse_pos) <= 16.0 or not holder_present:
			open_business_management_ui(b_role)
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

	# 0.5. ¿Está junto al Mostrador de un Negocio (`shop_businesses`)?
	var best_stall: Dictionary = _find_nearest_business_stall(pos, 26.0)
	if not best_stall.is_empty():
		open_business_management_ui(int(best_stall.get("role", -1)))
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

	# 3b. Capilla de San Cipriano y Cementerio Parroquial
	if pos.distance_squared_to(_church_altar_pos) <= 34.0 * 34.0 or pos.distance_squared_to(_cemetery_gate_pos) <= 34.0 * 34.0 or Rect2(Vector2(822, 258), Vector2(174, 108)).has_point(pos):
		_open_church_registry_ui()
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

func _on_hour_passed(_day: int, new_hour: int = 8) -> void:
	var actual_hour: int = WorldClock.current_hour if WorldClock else new_hour
	var actual_day: int = WorldClock.current_day if WorldClock else 1
	_apply_hourly_door_security_schedule(actual_hour)

	# 07:00 AM -> Comprobar llegada semanal de los 2 Mercaderes Ambulantes (Día 3: Maese Casimir | Día 6: Valeria la Tratante)
	if actual_hour == 7:
		_check_weekly_merchant_arrival(actual_day)
	# 08:00 AM -> Salarios de autoridades, compras recíprocas entre gremios y jornales diarios
	elif actual_hour == 8:
		_process_morning_salaries_and_inter_guild_circulation()
	# 21:00 PM -> Cobro de alquiler nocturno en la Posada (6 Oro) o desahucio a Campamentos Rústicos en las Afueras
	elif actual_hour == 21:
		_process_nightly_tavern_rent_and_vagrant_camps()

	# Ciclo de Sepultura Forense: tras 18 horas en la Morgue, los cadáveres examinados son trasladados y sepultados en el Cementerio de la Iglesia,
	# liberando sus camillas de acero inoxidable para nuevos casos.
	var cur_total_hours: int = actual_day * 24 + actual_hour
	var remaining_morgue: Array[Dictionary] = []
	var any_buried := false
	for entry in morgue_active_corpses:
		var added_h: int = int(entry.get("added_total_hours", cur_total_hours))
		if (cur_total_hours - added_h) >= 18:
			_bury_corpse_in_cemetery(entry, "Sepultura parroquial tras concluir autopsia forense (18h)")
			any_buried = true
		else:
			remaining_morgue.append(entry)
	if any_buried:
		morgue_active_corpses = remaining_morgue
		_refresh_morgue_table_sprites()

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
		if b_id == "building_hospital" or b_id == "building_police" or b_id == "building_church":
			_set_door_state(d_entry, false, false, false)
		elif b_id == "building_tavern":
			var tav_close_h: int = 21 if sec_lvl >= 3 else 23
			var lock_tav: bool = (hour >= tav_close_h or hour < 6) and sec_lvl >= 2
			_set_door_state(d_entry, false, lock_tav, false)
		elif b_id.begins_with("shop_") or b_id.begins_with("mixed_"):
			# Si el jugador es Socio o Dueño del negocio, siempre tiene llave de su local
			var player_owns_this_shop: bool = false
			for r_k in shop_businesses.keys():
				var biz_chk: Dictionary = shop_businesses[int(r_k)]
				if ("shop_" + str(biz_chk.get("family_id", "")) == b_id or "mixed_" + str(biz_chk.get("family_id", "")) == b_id) and str(biz_chk.get("owner_mode", "NPC")) in ["PARTNER", "SOLE_OWNER"]:
					player_owns_this_shop = true
					break
			if player_owns_this_shop:
				_set_door_state(d_entry, false, false, false)
			elif b_id.begins_with("mixed_"):
				# La Botica-Vivienda mixta sigue la misma regla de confianza vecinal que las casas cuando el nivel de alerta es bajo
				if sec_lvl == 0 and fam_aff >= 0:
					_set_door_state(d_entry, false, false, false)
				else:
					var mix_open: bool = (hour >= 7 and hour < 20 and fam_aff > -35)
					_set_door_state(d_entry, false, not mix_open, false)
			else:
				var shop_open_h: int = 8 if sec_lvl >= 1 else 7
				var shop_close_h: int = 17 if sec_lvl >= 3 else (18 if sec_lvl >= 1 else 20)
				var is_open_hours: bool = (hour >= shop_open_h and hour < shop_close_h and fam_aff > -35)
				var lock_shop: bool = (not is_open_hours) and (sec_lvl >= 1 or fam_aff < 0 or hour >= 21 or hour < 6)
				_set_door_state(d_entry, false, lock_shop, false)
		elif b_id.begins_with("house_"):
			# Cuando el nivel de alerta en el pueblo es bajo (`sec_lvl == 0`) y la familia no desconfía de ti (`fam_aff >= 0`),
			# las puertas de las casas están cerradas pero SIN LLAVE (`is_locked = false`).
			# Solo echan la llave cuando sube la alerta en el pueblo (`sec_lvl >= 1`) o si la familia te tiene rencor (`fam_aff < 0`).
			if sec_lvl == 0 and fam_aff >= 0:
				_set_door_state(d_entry, false, false, false)
			else:
				var night_lock_h: int = 18 if (sec_lvl >= 3 or fam_aff < 0) else 20
				if hour >= night_lock_h or hour < 7:
					_set_door_state(d_entry, false, true, false)
				else:
					var day_lock: bool = (sec_lvl >= 3 or fam_aff <= -15)
					_set_door_state(d_entry, false, day_lock, false)

	for w_entry in building_windows:
		if float(w_entry.get("manual_override_timer", 0.0)) > 0.0:
			continue
		var wb_id: String = str(w_entry.get("building_id", ""))
		var w_aff: int = _get_building_family_affinity(wb_id)
		var should_shutter: bool = ((hour >= 21 or hour < 6) and sec_lvl >= 1) or (sec_lvl >= 2) or (w_aff < 0)
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
			var b_rect_npc: Rect2 = d_entry["building_rect"].grow(-1.0)
			var b_rect_dest: Rect2 = d_entry["building_rect"].grow(2.5)
			var npc_inside: bool = b_rect_npc.has_point(npc_pos)
			var dest_inside: bool = b_rect_dest.has_point(target_pos)
			var crossing_this_door: bool = (npc_inside != dest_inside)
			if not crossing_this_door:
				continue

			if bool(d_entry.get("is_open", false)):
				return true
			if bool(d_entry.get("locked_by_player", false)):
				# Si es un policía o el Inquisidor Real persiguiendo al jugador o en investigación, derriba la puerta tras 2.0s de golpes
				if npc.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR] and (wanted_level > 0 or is_resisting_arrest or npc.is_hostile or npc.trade_role == VillageNPC.TradeRole.ROYAL_INVESTIGATOR):
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

## Indica si la puerta de un edificio está trancada con cerrojo por el jugador (`locked_by_player`),
## evitando que los aldeanos civiles se queden atascados frente a la puerta de la Taberna u otro edificio.
func is_building_door_blocked(building_id_or_keyword: String) -> bool:
	var kw: String = building_id_or_keyword.to_lower()
	for d_entry in building_doors:
		var b_id: String = str(d_entry.get("building_id", "")).to_lower()
		var b_title: String = str(d_entry.get("building_title", "")).to_lower()
		if b_id == kw or b_id.find(kw) != -1 or b_title.find(kw) != -1:
			if bool(d_entry.get("locked_by_player", false)) and not bool(d_entry.get("is_open", false)):
				return true
	return false

func _update_doors_and_windows(_delta: float, player: Node2D, mouse_pos: Vector2) -> void:
	var sec_txt: String = get_village_security_text()
	for d_entry in building_doors:
		var d_pos: Vector2 = d_entry.get("pos", Vector2.ZERO)
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
		var cloak_mult: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
		var lockpick_mult: float = 0.35 if (player.has_method("has_master_lockpick") and bool(player.call("has_master_lockpick"))) else 1.0
		var detect_rad: float = (42.0 if in_stealth else 145.0) * cloak_mult * lockpick_mult
		var witness: VillageNPC = _find_conscious_witness_near(d_entry.get("pos", player.global_position), detect_rad, null)
		if witness == null:
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🔓🤫 Cerradura forzada con [F] en sigilo: %s (Sin testigos)" % b_title, Color.SPRING_GREEN, -44.0)
		else:
			wanted_level = clampi(wanted_level + 1, 1, 5)
			bounty_gold += 20
			var msg := "🚨👁️ ¡%s te vio forzar la cerradura de %s! (+20 Oro de multa)" % [witness.npc_name, b_title]
			crime_history.push_front(msg)
			_notify_inquisitor_of_police_crime(msg, 12)
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
			w_entry["manual_override_timer"] = 120.0
			recent_breakins_count += 1
			var w_spr: Sprite2D = w_entry.get("sprite")
			if is_instance_valid(w_spr):
				w_spr.texture = _load_tex("res://assests/world/village/window_glass_open.png")
			var in_stealth2: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
			var cloak_mult2: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
			var lockpick_mult2: float = 0.35 if (player.has_method("has_master_lockpick") and bool(player.call("has_master_lockpick"))) else 1.0
			var detect_rad2: float = (38.0 if in_stealth2 else 130.0) * cloak_mult2 * lockpick_mult2
			var witness2: VillageNPC = _find_conscious_witness_near(w_pos, detect_rad2, null)
			if witness2 != null:
				wanted_level = clampi(wanted_level + 1, 1, 5)
				bounty_gold += 20
				var w_msg := "🚨👁️ ¡%s te vio forzar la ventana de %s! (+20 Oro de multa)" % [witness2.npc_name, wb_title]
				crime_history.push_front(w_msg)
				_notify_inquisitor_of_police_crime(w_msg, 12)
				if player.has_method("_spawn_floating_text"):
					player._spawn_floating_text(w_msg, Color.ORANGE_RED, -46.0)
			else:
				if player.has_method("_spawn_floating_text"):
					player._spawn_floating_text("🪟🔓 Forzaste el postigo con [F] y entraste por la ventana", Color.SPRING_GREEN, -44.0)
			player.global_position = w_pos + Vector2(0, -15.0 if door_south else 15.0)
			return true

	# 4. ¿Está junto al mostrador/taller de un negocio (`shop_businesses`)? -> [F] Sabotear Taller Industrial
	var stall_entry: Dictionary = _find_nearest_business_stall(player.global_position, 28.0)
	if not stall_entry.is_empty():
		var s_role: int = int(stall_entry.get("role", -1))
		sabotage_shop_stall(player, s_role)
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
	var cloak_mult3: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
	var lockpick_mult3: float = 0.35 if (player.has_method("has_master_lockpick") and bool(player.call("has_master_lockpick"))) else 1.0
	var detect_rad: float = (52.0 if in_stealth else 135.0) * cloak_mult3 * lockpick_mult3
	var witness: VillageNPC = _find_conscious_witness_near(player.global_position, detect_rad, null)

	if witness == null:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🔓🤫 Robo en sigilo perfecto: +%d Oro, +1 %s (Sin testigos)" % [gold_loot, SimpleInventory.CATALOG.get(bonus_item, {}).get("name", bonus_item)], Color.SPRING_GREEN, -46.0)
	else:
		wanted_level = clampi(wanted_level + 1, 1, 5)
		bounty_gold += 30
		var fam_id: String = str(ch.get("family_id", "none"))
		var ch_title: String = str(ch.get("title", "Cofre"))
		var chest_crime_msg := "🚨👁️ ¡%s vio al Forastero saquear %s! (+30 Oro de multa)" % [witness.npc_name, ch_title]
		crime_history.push_front(chest_crime_msg)
		_notify_inquisitor_of_police_crime(chest_crime_msg, 15)
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
	if health and health.current_health >= health.max_health - 0.1 and not health.is_bleeding and health.current_blood <= 0.1:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🏥 Tu salud ya está al 100% y no tienes sangrado", Color.LIGHT_GRAY, -42.0)
		return
	var inv: SimpleInventory = player.get("inventory") if "inventory" in player else null
	if inv and inv.gold < 10:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("❌ Necesitas 10 Oro para usar la Cama de Urgencias", Color.ORANGE_RED, -42.0)
		return
	if inv:
		inv.add_gold(-10)
	if health:
		health.stop_bleeding()
		health.heal(health.max_health)
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🏥 Cama de Urgencias (-10 Oro): Salud y Sangrado curados al 100%", Color.SPRING_GREEN, -44.0)

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
	arrivals_today_count = 0

	# Descontar 1 día del embargo comercial (20..30 días) si alguno de los 2 mercaderes semanales fue asesinado
	for m_key in ["casimir", "valeria"]:
		var susp_d: int = int(merchant_suspension_days.get(m_key, 0))
		if susp_d > 0:
			susp_d = maxi(0, susp_d - 1)
			merchant_suspension_days[m_key] = susp_d
			if susp_d == 0:
				var p_m = get_tree().get_first_node_in_group("player")
				if p_m and p_m.has_method("show_hint"):
					var m_label: String = "Maese Casimir (Liga Minera)" if m_key == "casimir" else "Valeria la Tratante (Gremio de Caza)"
					p_m.show_hint("📜⚖️ El embargo comercial sobre la ruta de %s ha concluido tras semanas de bloqueo. Volverá a pasar en su día semanal." % m_label)

	# Avanzar jornada de investigación del Inquisidor Real Alistair (garantizando resolución antes del día 19)
	_advance_royal_investigation_day(_new_day)

	# Cerrar cofres domésticos para el nuevo día
	var tex_closed := _load_tex("res://assests/world/village/house_chest_closed.png")
	for ch in house_chests:
		var spr: Sprite2D = ch.get("sprite")
		if is_instance_valid(spr) and tex_closed:
			spr.texture = tex_closed

	# 1. Progresión de la Curva de Eficiencia Laboral de 7 Días (+1 día de experiencia a cada trabajador vivo)
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if not v.is_dead and not (v.trade_role in [VillageNPC.TradeRole.UNEMPLOYED, VillageNPC.TradeRole.FAMILY_MEMBER]):
				if v.days_in_role < 7:
					v.days_in_role = mini(7, v.days_in_role + 1)
					if v.days_in_role == 7:
						v._spawn_floating_text("🎓⚒️ ¡Dominio Maestro alcanzado (100% Eficiencia)!", Color.GOLD, -40.0)
					else:
						v._spawn_floating_text("📈 Experiencia laboral: Día %d/7 (%d%% Eficiencia)" % [v.days_in_role, int(round(v.get_job_efficiency() * 100.0))], Color.AQUA, -36.0)

	# 1b. Sepultura matutina de cuerpos en la Morgue que hayan cumplido su autopsia (>= 12h)
	var cur_total_h: int = _new_day * 24 + (WorldClock.current_hour if WorldClock else 6)
	var rem_morgue: Array[Dictionary] = []
	for m_entry in morgue_active_corpses:
		if (cur_total_h - int(m_entry.get("added_total_hours", cur_total_h))) >= 12:
			_bury_corpse_in_cemetery(m_entry, "Sepultura parroquial matutina tras autopsia")
		else:
			rem_morgue.append(m_entry)
	morgue_active_corpses = rem_morgue
	_refresh_morgue_table_sprites()

	# 1c. Reposición matutina de la Posada si la Tabernera está viva y consciente (escalada por su eficiencia laboral)
	if is_instance_valid(_innkeeper_npc) and not _innkeeper_npc.is_dead and not _innkeeper_npc.is_downed:
		var inn_eff: float = _innkeeper_npc.get_job_efficiency()
		var inn_restock_cnt: int = 1 if inn_eff < 0.60 else (2 if inn_eff < 0.85 else 3)
		var inn_added: int = 0
		var inn_base := {"country_stew": 5, "bread": 7, "roasted_chicken": 3}
		for ik in inn_base.keys():
			if inn_added >= inn_restock_cnt:
				break
			var cur_iq: int = int(_innkeeper_npc.shop_stock.get(ik, 0))
			var max_iq: int = int(ceil(float(inn_base[ik]) * inn_eff))
			if cur_iq < max_iq:
				_innkeeper_npc.shop_stock[ik] = cur_iq + 1
				inn_added += 1

	var total_player_dividends: int = 0
	for role_key in trade_configs.keys():
		var r_id: int = int(role_key)
		var current_holder: VillageNPC = trade_npcs.get(role_key)
		var cfg: Dictionary = trade_configs[role_key]
		var biz: Dictionary = shop_businesses.get(r_id, {})
		var owner_mode: String = str(biz.get("owner_mode", "NPC"))
		var sab_days: int = int(biz.get("sabotaged_days", 0))

		# Reducir 1 día de sabotaje si estaba averiado
		if sab_days > 0:
			sab_days = maxi(0, sab_days - 1)
			biz["sabotaged_days"] = sab_days
			_refresh_shop_stall_visual(r_id)

		# Procesar ventas diarias del mostrador y dividendos si el jugador es Socio ("PARTNER") o Dueño ("SOLE_OWNER")
		if owner_mode in ["PARTNER", "SOLE_OWNER"]:
			var day_profit: int = _process_daily_business_sales_and_dividends(r_id, current_holder, sab_days)
			total_player_dividends += day_profit

		if not is_instance_valid(current_holder) or current_holder.is_dead:
			# Si el jugador ya compró la propiedad completa ("SOLE_OWNER"), él decide cuándo contratar encargado en [3]
			if owner_mode == "SOLE_OWNER":
				continue

			# Sucesión Interna #1: Familiar directo que ya vivía en esa casa (Empieza con `days_in_role = 2` -> 54% Aprendiz)
			var kin_candidate: VillageNPC = family_npcs.get(role_key)
			if is_instance_valid(kin_candidate) and not kin_candidate.is_dead and kin_candidate.trade_role == VillageNPC.TradeRole.FAMILY_MEMBER:
				var inh_stock: Dictionary = (biz.get("stock_override", cfg["stock"]) as Dictionary).duplicate()
				kin_candidate.promote_to_trade(
					role_key,
					str(cfg["title"]),
					cfg["work_pos"],
					inh_stock,
					cfg["tex"]
				)
				trade_npcs[role_key] = kin_candidate
				family_npcs.erase(role_key)
				var p1 = get_tree().get_first_node_in_group("player")
				if p1 and p1.has_method("show_hint"):
					p1.show_hint("🏠 Herencia Familiar: %s (%s) asumió el puesto de %s como Aprendiz (54%% Eficiencia · 5 días para Maestro)." % [kin_candidate.npc_name, str(cfg["family_name"]), str(cfg["title"])])
				continue

			# Si toda la familia murió y el taller está saboteado, queda vacante para que el jugador pueda comprarlo barato en liquidación
			if sab_days > 0:
				continue

			# Sucesión Interna #2: Viajero sin oficio que ya se alojaba en la Posada (Empieza con `days_in_role = 0` -> 35% Novato)
			var outsider: VillageNPC = _pop_living_unemployed()
			if outsider:
				var inh_stock2: Dictionary = (biz.get("stock_override", cfg["stock"]) as Dictionary).duplicate()
				outsider.promote_to_trade(
					role_key,
					str(cfg["title"]),
					cfg["work_pos"],
					inh_stock2,
					cfg["tex"],
					cfg["bed1_pos"],
					cfg["table_pos"],
					str(cfg["family_id"]),
					str(cfg["family_name"])
				)
				trade_npcs[role_key] = outsider
				var p2 = get_tree().get_first_node_in_group("player")
				if p2 and p2.has_method("show_hint"):
					p2.show_hint("🔄 Sucesión en la aldea: %s asumió el taller como nuevo %s Novato (35%% Eficiencia · 7 días para Maestro)." % [outsider.npc_name, str(cfg["title"])])
		else:
			# Solo repone stock pasivo si el taller NO está saboteado y el titular está consciente; la cantidad depende de `get_job_efficiency()`
			if sab_days <= 0 and not current_holder.is_downed:
				var eff_h: float = current_holder.get_job_efficiency()
				var max_items_restock: int = 1 if eff_h < 0.60 else (2 if eff_h < 0.85 else 99)
				var items_restocked: int = 0
				var base_stock: Dictionary = cfg["stock"]
				for item_k in base_stock.keys():
					if items_restocked >= max_items_restock:
						break
					var cur_amt: int = int(current_holder.shop_stock.get(item_k, 0))
					var base_cap: int = int(base_stock[item_k])
					var max_amt: int = maxi(1, int(ceil(float(base_cap) * 0.60))) if eff_h < 0.60 else (base_cap if eff_h < 0.85 else base_cap + 2)
					if cur_amt < max_amt:
						var add_qty: int = 2 if (eff_h >= 0.95 and cur_amt + 2 <= max_amt) else 1
						current_holder.shop_stock[item_k] = cur_amt + add_qty
						items_restocked += 1
			biz["stock_override"] = current_holder.shop_stock.duplicate()

	# 2. LLEGADAS EXTERNAS DESDE EL BORDE DEL MAPA (Estricto límite de `MAX_DAILY_ARRIVALS = 2` personas por día)
	_process_daily_map_edge_arrivals()

	if total_player_dividends > 0:
		var p_div = get_tree().get_first_node_in_group("player")
		if p_div and p_div.has_method("show_hint"):
			p_div.show_hint("💰📈 Tus negocios del valle generaron +%d Oro hoy (Recáudalo en sus Cajas Registradoras [E])." % total_player_dividends)

## Gestiona la llegada diaria de hasta `MAX_DAILY_ARRIVALS = 2` personas caminando físicamente desde el borde del mapa (`Vector2(-900, 48)` o `Vector2(990, 48)`).
## Si toda la aldea muere, NO reaparece de golpe al día siguiente: llegan como máximo 2 personas por día y entran como Novatos (35% eficiencia).
func _process_daily_map_edge_arrivals() -> void:
	# Prioridad 1: Vacantes de Autoridades (Médico Forense, Comisario, Guardia)
	for slot in _authority_slots:
		if arrivals_today_count >= MAX_DAILY_ARRIVALS:
			return
		var cur_auth: VillageNPC = slot.get("npc")
		if not is_instance_valid(cur_auth) or cur_auth.is_dead:
			_spawn_authority_replacement(slot)
			arrivals_today_count += 1

	# Prioridad 2: Vacante de Posadera/Chef en la Taberna El Jabalí Dorado
	if arrivals_today_count < MAX_DAILY_ARRIVALS and (not is_instance_valid(_innkeeper_npc) or _innkeeper_npc.is_dead):
		_rehire_counter += 1
		var inn_names: Array[String] = ["Posadera Sofía", "Chef Herminia", "Posadera Brisa", "Chef Lucía"]
		var new_inn_name: String = inn_names[_rehire_counter % inn_names.size()]
		var new_inn := VillageNPC.new()
		new_inn.name = "NPC_Innkeeper_%d" % _rehire_counter
		new_inn.npc_name = new_inn_name
		new_inn.npc_role = "Chef y Posadera (Novata)"
		new_inn.trade_role = VillageNPC.TradeRole.INNKEEPER
		new_inn.days_in_role = 0
		new_inn.tavern_social_pos = _tavern_social_pos
		entities_root.add_child(new_inn)
		new_inn.setup_npc(
			_load_tex("res://assests/world/village/villager_innkeeper.png"),
			Vector2(348, -154),
			Vector2(342, -252),
			{"country_stew": 2, "bread": 3, "roasted_chicken": 1},
			_tavern_social_pos,
			"family_tavern",
			"Posada El Jabalí"
		)
		new_inn.global_position = _get_map_edge_arrival_pos(_rehire_counter)
		_innkeeper_npc = new_inn
		arrivals_today_count += 1
		var p_inn = get_tree().get_first_node_in_group("player")
		if p_inn and p_inn.has_method("show_hint"):
			p_inn.show_hint("🍺🚶 %s (Posadera Novata · 35%%) está llegando por el borde del valle para reabrir la Posada." % new_inn_name)

	# Prioridad 3: Oficios vacantes sin familia ni huésped disponible (salvo que sean propiedad exclusiva del jugador o estén saboteados)
	for role_key in trade_configs.keys():
		if arrivals_today_count >= MAX_DAILY_ARRIVALS:
			return
		var r_id: int = int(role_key)
		var holder: VillageNPC = trade_npcs.get(role_key)
		if is_instance_valid(holder) and not holder.is_dead:
			continue
		var biz: Dictionary = shop_businesses.get(r_id, {})
		if str(biz.get("owner_mode", "NPC")) == "SOLE_OWNER" or int(biz.get("sabotaged_days", 0)) > 0:
			continue
		var cfg: Dictionary = trade_configs[role_key]
		_rehire_counter += 1
		var art_names: Array[String] = ["Artesano Gael", "Artesana Nerea", "Artesano Orson", "Artesana Talia", "Artesano Tristán"]
		var new_art_name: String = art_names[_rehire_counter % art_names.size()]
		var new_art := VillageNPC.new()
		new_art.name = "NPC_Newcomer_Trade_%d" % _rehire_counter
		new_art.npc_name = new_art_name
		new_art.npc_role = str(cfg.get("title", "Artesano")) + " (Recién Llegado)"
		new_art.trade_role = role_key
		new_art.linked_trade = role_key
		new_art.days_in_role = 0 # 35% eficiencia inicial, requiere 7 días de aprendizaje
		new_art.tavern_social_pos = _tavern_social_pos
		entities_root.add_child(new_art)
		var inh_st: Dictionary = (biz.get("stock_override", cfg["stock"]) as Dictionary).duplicate()
		new_art.setup_npc(
			cfg.get("tex", null),
			cfg.get("work_pos", Vector2(440, 44)),
			cfg.get("bed1_pos", _tavern_bed_pos),
			inh_st,
			cfg.get("table_pos", _tavern_social_pos),
			str(cfg.get("family_id", "none")),
			str(cfg.get("family_name", "Gremio"))
		)
		new_art.global_position = _get_map_edge_arrival_pos(_rehire_counter)
		trade_npcs[role_key] = new_art
		arrivals_today_count += 1
		var p_art = get_tree().get_first_node_in_group("player")
		if p_art and p_art.has_method("show_hint"):
			p_art.show_hint("⚒️🚶 %s (%s Novato · 35%% Eficiencia) está entrando al valle desde el borde del mapa." % [new_art_name, str(cfg.get("title", "Artesano"))])

	# Prioridad 4: Si aún queda cupo en el límite diario (<= 2/día) y hay camas de viajeros vacías en la Posada (máx. 3 huéspedes)
	var living_guests: Array[VillageNPC] = []
	for g in unemployed_npcs:
		if is_instance_valid(g) and not g.is_dead and g.trade_role == VillageNPC.TradeRole.UNEMPLOYED:
			living_guests.append(g)
	unemployed_npcs = living_guests

	var guest_beds: Array[Vector2] = [Vector2(435, -252), Vector2(468, -252), Vector2(502, -252)]
	var guest_day_spots: Array[Vector2] = [Vector2(440, 44), Vector2(495, 44), Vector2(415, -105)]
	var trav_names: Array[String] = ["Caminante Elian", "Viajera Maeve", "Jornalero Bastián", "Forastera Íngrid", "Viajero Román"]
	var tex_traveler := _load_tex("res://assests/world/village/villager_traveler.png")
	while unemployed_npcs.size() < 3 and arrivals_today_count < MAX_DAILY_ARRIVALS:
		_rehire_counter += 1
		var slot_idx: int = unemployed_npcs.size()
		var t_name: String = trav_names[_rehire_counter % trav_names.size()]
		var t_npc := VillageNPC.new()
		t_npc.name = "NPC_Traveler_%d" % _rehire_counter
		t_npc.npc_name = t_name
		t_npc.npc_role = "Viajero Recién Llegado"
		t_npc.trade_role = VillageNPC.TradeRole.UNEMPLOYED
		t_npc.days_in_role = 0
		t_npc.tavern_social_pos = _tavern_social_pos
		entities_root.add_child(t_npc)
		t_npc.setup_npc(
			tex_traveler,
			guest_day_spots[slot_idx % guest_day_spots.size()],
			guest_beds[slot_idx % guest_beds.size()],
			{},
			_tavern_social_pos,
			"none",
			"Huésped de Posada"
		)
		t_npc.global_position = _get_map_edge_arrival_pos(_rehire_counter)
		unemployed_npcs.append(t_npc)
		arrivals_today_count += 1
		var p_tr = get_tree().get_first_node_in_group("player")
		if p_tr and p_tr.has_method("show_hint"):
			p_tr.show_hint("🎒🚶 Un nuevo viajero (%s) acaba de entrar al valle por el camino principal." % t_name)

func _pop_living_unemployed() -> VillageNPC:
	for i in range(unemployed_npcs.size()):
		var cand: VillageNPC = unemployed_npcs[i]
		if is_instance_valid(cand) and not cand.is_dead and cand.trade_role == VillageNPC.TradeRole.UNEMPLOYED:
			unemployed_npcs.remove_at(i)
			return cand
	return null

# ==============================================================================
# FASE 8: ECONOMÍA DINÁMICA DE OFERTA Y DEMANDA, CONSUMO REAL, SABOTAJE Y PROPIEDAD DE NEGOCIOS
# ==============================================================================
func _register_shop_business_stall(role_id: int, shop_title: String, fam_id: String, stall_pos: Vector2, stall_spr: Sprite2D) -> void:
	_add_station_area("ShopBusinessStall_%d" % role_id, stall_pos, 14.0, "shop_business_stall")
	var lbl := _make_station_label(stall_pos + Vector2(-130, -32), "📜 %s [E: Gestionar Negocio | F: Sabotear]" % shop_title)
	lbl.custom_minimum_size = Vector2(260, 26)
	entities_root.add_child(lbl)

	var sup_items: Array[String] = []
	match role_id:
		int(VillageNPC.TradeRole.BLACKSMITH):
			sup_items = ["iron_ore", "stone", "steel_ingot", "repair_kit", "bandit_scrap"]
		int(VillageNPC.TradeRole.BUTCHER):
			sup_items = ["cooked_meat", "raw_meat", "roasted_chicken", "raw_chicken", "leather", "fox_pelt", "antlers"]
		int(VillageNPC.TradeRole.CARPENTER):
			sup_items = ["wood", "repair_kit", "copper_coil"]
		int(VillageNPC.TradeRole.FISHMONGER):
			sup_items = ["bread", "cooked_fish", "river_trout", "golden_carp", "night_catfish", "wheat", "fertilizer"]
		int(VillageNPC.TradeRole.HERBALIST):
			sup_items = ["herbal_poultice", "herbs", "mushroom", "carrot", "cabbage", "sleeping_draught", "surgical_kit"]

	var cfg: Dictionary = trade_configs.get(role_id, {})
	var init_stock: Dictionary = (cfg.get("stock", {}) as Dictionary).duplicate()
	shop_businesses[role_id] = {
		"role": role_id,
		"family_id": fam_id,
		"title": shop_title,
		"stall_pos": stall_pos,
		"stall_sprite": stall_spr,
		"stall_label": lbl,
		"owner_mode": "NPC", # "NPC", "PARTNER" (Socio Capitalista), "SOLE_OWNER" (Dueño Único)
		"vault_gold": 0,
		"sabotaged_days": 0,
		"sabotaged_today_day": -1,
		"supply_items": sup_items,
		"stock_override": init_stock
	}

func _find_nearest_business_stall(pos: Vector2, max_rad: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d2: float = max_rad * max_rad
	for r_id in shop_businesses.keys():
		var biz: Dictionary = shop_businesses[r_id]
		var s_pos: Vector2 = biz.get("stall_pos", Vector2.ZERO)
		var d2: float = pos.distance_squared_to(s_pos)
		if d2 <= best_d2:
			best_d2 = d2
			best = biz
	return best

func _update_shop_business_stalls(player: Node2D, mouse_pos: Vector2) -> void:
	for r_id in shop_businesses.keys():
		var role_int: int = int(r_id)
		var biz: Dictionary = shop_businesses[role_int]
		var lbl: Label = biz.get("stall_label")
		var s_pos: Vector2 = biz.get("stall_pos", Vector2.ZERO)
		if not is_instance_valid(lbl):
			continue
		lbl.visible = _is_near(player, mouse_pos, s_pos, 25.0, 17.0)
		if lbl.visible:
			var b_title: String = str(biz.get("title", "Negocio"))
			var owner_m: String = str(biz.get("owner_mode", "NPC"))
			var vault_g: int = int(biz.get("vault_gold", 0))
			var sab_d: int = int(biz.get("sabotaged_days", 0))
			var mkt_txt: String = get_trade_market_status_text(role_int)
			var tot_stk: int = get_trade_total_stock(role_int)
			var own_tag: String = "🏢 Familiar"
			if owner_m == "PARTNER":
				own_tag = "🤝 Eres Socio (Caja: %d Oro)" % vault_g
			elif owner_m == "SOLE_OWNER":
				own_tag = "👑 TU NEGOCIO (Caja: %d Oro)" % vault_g
			var sab_tag: String = " | 🔧💥 SABOTEADO (%dd)" % sab_d if sab_d > 0 else ""
			lbl.text = "%s [%s | Stock:%d | %s%s]\n[E: 📜 Gestionar Negocio / Escritura / Caja | F: 💣 Sabotear Taller]" % [
				b_title, own_tag, tot_stk, mkt_txt, sab_tag
			]
			if sab_d > 0:
				lbl.add_theme_color_override("font_color", Color(1.0, 0.58, 0.48))
			elif owner_m != "NPC":
				lbl.add_theme_color_override("font_color", Color(0.58, 1.0, 0.72))
			else:
				lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.68))

func _refresh_shop_stall_visual(role_id: int) -> void:
	if not shop_businesses.has(role_id):
		return
	var biz: Dictionary = shop_businesses[role_id]
	var spr: Sprite2D = biz.get("stall_sprite")
	var sab_d: int = int(biz.get("sabotaged_days", 0))
	var owner_m: String = str(biz.get("owner_mode", "NPC"))
	if is_instance_valid(spr):
		if sab_d > 0:
			spr.modulate = Color(0.62, 0.36, 0.34, 0.96)
		elif owner_m != "NPC":
			spr.modulate = Color(1.06, 1.04, 0.88, 1.0)
		else:
			spr.modulate = Color.WHITE

## Obtiene el diccionario de stock activo del negocio (del NPC titular si vive, o de `stock_override` si está vacante)
func get_trade_stock_dict(role_id: int) -> Dictionary:
	var holder: VillageNPC = trade_npcs.get(role_id)
	if is_instance_valid(holder) and not holder.is_dead:
		if shop_businesses.has(role_id):
			shop_businesses[role_id]["stock_override"] = holder.shop_stock
		return holder.shop_stock
	if shop_businesses.has(role_id):
		var ov: Variant = shop_businesses[role_id].get("stock_override", {})
		if typeof(ov) == TYPE_DICTIONARY:
			return ov as Dictionary
	return {}

func get_trade_total_stock(role_id: int) -> int:
	var st: Dictionary = get_trade_stock_dict(role_id)
	var total: int = 0
	for k in st.keys():
		total += maxi(0, int(st[k]))
	return total

func is_trade_sabotaged(role_id: int) -> bool:
	if not shop_businesses.has(role_id):
		return false
	return int(shop_businesses[role_id].get("sabotaged_days", 0)) > 0

func is_player_owner_or_partner(role_id: int) -> bool:
	if not shop_businesses.has(role_id):
		return false
	var om: String = str(shop_businesses[role_id].get("owner_mode", "NPC"))
	return om in ["PARTNER", "SOLE_OWNER"]

func get_business_owner_badge(role_id: int) -> String:
	if not shop_businesses.has(role_id):
		return ""
	var biz: Dictionary = shop_businesses[role_id]
	var om: String = str(biz.get("owner_mode", "NPC"))
	var vg: int = int(biz.get("vault_gold", 0))
	if om == "PARTNER":
		return " | 🤝 Eres Socio (-30%% Dto | Caja: %d Oro)" % vg
	elif om == "SOLE_OWNER":
		return " | 👑 Dueño Único (-30%% Dto | Caja: %d Oro)" % vg
	return ""

## Multiplicador dinámico de Oferta y Demanda (`0.80x` Excedente -> `1.00x` Estable -> `1.55x` Escasez -> `2.25x` Crisis/Sabotaje)
func get_trade_market_multiplier(role_id: int) -> float:
	if role_id == int(VillageNPC.TradeRole.INNKEEPER):
		var m_butcher: float = get_trade_market_multiplier(int(VillageNPC.TradeRole.BUTCHER))
		var m_fish: float = get_trade_market_multiplier(int(VillageNPC.TradeRole.FISHMONGER))
		return clampf((m_butcher + m_fish) * 0.5, 0.85, 2.10)
	if not shop_businesses.has(role_id):
		return 1.0
	var biz: Dictionary = shop_businesses[role_id]
	var sab_d: int = int(biz.get("sabotaged_days", 0))
	var holder: VillageNPC = trade_npcs.get(role_id)
	var holder_missing: bool = (not is_instance_valid(holder)) or holder.is_dead or holder.is_downed
	var tot_stock: int = get_trade_total_stock(role_id)

	if sab_d > 0 or holder_missing or tot_stock <= 0:
		return 2.25
	if tot_stock <= 3:
		return 1.55
	if tot_stock >= 12:
		return 0.80
	return 1.0

func get_trade_market_status_text(role_id: int) -> String:
	var mult: float = get_trade_market_multiplier(role_id)
	if mult >= 2.0:
		return "🔥 Crisis (+125%)"
	elif mult >= 1.4:
		return "📈 Escasez (+55%)"
	elif mult <= 0.85:
		return "📉 Excedente (-20%)"
	return "⚖️ Estable (100%)"

## Verifica si el dependiente de un oficio está vivo, consciente y físicamente atendiendo su mostrador (`is_at_shop_counter()`).
## Ningún NPC ni el jugador pueden comprar en una tienda si el dependiente no está ahí sirviendo.
func is_shopkeeper_present_and_serving(role_id: int) -> bool:
	if role_id == int(VillageNPC.TradeRole.INNKEEPER):
		return is_instance_valid(_innkeeper_npc) and _innkeeper_npc.is_at_shop_counter()
	var holder: VillageNPC = trade_npcs.get(role_id)
	return is_instance_valid(holder) and holder.is_at_shop_counter()

## Añade raciones de comida a la despensa doméstica de la casa del NPC (`house_pantry`)
func add_home_pantry_ration(npc: VillageNPC, amount: int = 1) -> void:
	if npc == null:
		return
	var p_key: String = npc.family_id if (npc.family_id != "none" and npc.family_id != "") else npc.npc_name
	house_pantry[p_key] = clampi(int(house_pantry.get(p_key, 0)) + amount, 0, 8)

## Consumo Real de Alimentos por los Habitantes (`ActivityState.EATING`):
## 1º PRIORIDAD: Cocinar y comer en CASA de su propia despensa doméstica (`house_pantry`, coste 0 Oro extra).
## 2º PRIORIDAD: Comprar producto fresco/crudo barato (`3–5 Oro` × multiplicador de mercado) en Pescadería, Carnicería o Botica (pagando de `npc.personal_gold` a `holder.personal_gold`) para cocinarlo en casa y abastecer la despensa (`+1` ración extra).
## 3º PRIORIDAD (Lujo Opcional): Plato cocinado en la Posada (`12–15 Oro` × mercado), solo si la puerta no está bloqueada y el NPC puede permitírselo.
func consume_village_meal_for_npc(npc: VillageNPC) -> bool:
	if npc == null or npc.is_dead:
		return false

	var p_key: String = npc.family_id if (npc.family_id != "none" and npc.family_id != "") else npc.npc_name
	var near_tavern: bool = npc.global_position.distance_to(_tavern_social_pos) <= 55.0

	# 1º PRIORIDAD: Si está en su casa/cuartel (no en la Taberna) y su despensa doméstica (`house_pantry`) tiene suministros, cocina en casa gratis
	var cur_pantry: int = int(house_pantry.get(p_key, 0))
	if not near_tavern and cur_pantry > 0:
		house_pantry[p_key] = cur_pantry - 1
		npc.add_thought("Cocinó y comió en casa de su despensa (+6)", 6.0)
		npc._spawn_floating_text("🍲🏠 Comida casera (Despensa: %d)" % int(house_pantry[p_key]), Color(0.65, 1.0, 0.72), -32.0)
		return true

	# 2º PRIORIDAD: Comprar producto crudo/fresco barato (3-5 Oro × mercado) en las tiendas de alimentación abiertas y llevar a la despensa
	var food_roles: Array[int] = [
		int(VillageNPC.TradeRole.FISHMONGER),
		int(VillageNPC.TradeRole.BUTCHER),
		int(VillageNPC.TradeRole.HERBALIST)
	]
	if npc.trade_role == VillageNPC.TradeRole.BUTCHER:
		food_roles = [int(VillageNPC.TradeRole.BUTCHER), int(VillageNPC.TradeRole.FISHMONGER), int(VillageNPC.TradeRole.HERBALIST)]

	var edible_keys: Array[String] = ["bread", "cooked_meat", "cooked_fish", "roasted_chicken", "carrot", "cabbage", "herbal_poultice"]
	for r_id in food_roles:
		var holder: VillageNPC = trade_npcs.get(r_id)
		var cfg: Dictionary = trade_configs.get(r_id, {})
		var shop_fam_id: String = str(cfg.get("family_id", ""))
		var is_own_family_pantry: bool = (npc.family_id != "none" and npc.family_id == shop_fam_id)

		if not is_own_family_pantry:
			if is_trade_sabotaged(r_id) or not is_instance_valid(holder) or not holder.is_at_shop_counter():
				continue
		else:
			if not is_instance_valid(holder) or holder.is_dead:
				continue

		var mkt_m: float = get_trade_market_multiplier(r_id)
		var raw_price: int = 0 if is_own_family_pantry else maxi(3, int(round(4.0 * mkt_m)))
		if not is_own_family_pantry and npc.personal_gold < raw_price:
			continue

		var st: Dictionary = holder.shop_stock
		for f_key in edible_keys:
			var cur_q: int = int(st.get(f_key, 0))
			if cur_q > 0:
				st[f_key] = cur_q - 1
				if not is_own_family_pantry:
					npc.personal_gold = maxi(0, npc.personal_gold - raw_price)
					holder.personal_gold += raw_price
					# Si le alcanza para llevar otra unidad a su despensa casera, guarda +1 ración para no depender de tiendas cerradas
					if cur_q >= 2 and npc.personal_gold >= raw_price and int(house_pantry.get(p_key, 0)) < 3:
						st[f_key] = cur_q - 2
						npc.personal_gold = maxi(0, npc.personal_gold - raw_price)
						holder.personal_gold += raw_price
						house_pantry[p_key] = int(house_pantry.get(p_key, 0)) + 1
				if shop_businesses.has(r_id):
					shop_businesses[r_id]["stock_override"] = st.duplicate()
				var food_name: String = str(SimpleInventory.CATALOG.get(f_key, {}).get("name", f_key))
				npc.add_thought("Cocinó %s comprado en el mercado (-%d Oro, +6)" % [food_name, raw_price], 6.0)
				npc._spawn_floating_text("🥖🏠 %s (-%d Oro | Bolsillo: %d)" % [food_name, raw_price, npc.personal_gold], Color(0.75, 1.0, 0.75), -32.0)
				# Si el jugador es Socio o Dueño de este negocio, la venta al aldeano ingresa oro real en su Caja Registradora
				if shop_businesses.has(r_id) and not is_own_family_pantry:
					var biz: Dictionary = shop_businesses[r_id]
					var om: String = str(biz.get("owner_mode", "NPC"))
					if om in ["PARTNER", "SOLE_OWNER"]:
						var eff_m: float = holder.get_job_efficiency()
						var base_val: int = 10 if om == "SOLE_OWNER" else 6
						var sale_gold: int = maxi(3, int(round(float(base_val) * mkt_m * eff_m)))
						biz["vault_gold"] = int(biz.get("vault_gold", 0)) + sale_gold
				return true

	# 3º PRIORIDAD (Lujo Opcional): Plato cocinado en la Posada (12-15 Oro × mercado) SOLO si la puerta de la Taberna no está bloqueada y la Tabernera sirve en barra
	if not is_building_door_blocked("building_tavern"):
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC:
				var inn: VillageNPC = n as VillageNPC
				if inn.trade_role == VillageNPC.TradeRole.INNKEEPER and not inn.is_dead:
					var is_innkeeper_self: bool = (npc == inn)
					if not is_innkeeper_self and not inn.is_at_shop_counter():
						continue
					var tav_mult: float = get_trade_market_multiplier(int(VillageNPC.TradeRole.INNKEEPER))
					var tav_price: int = 0 if is_innkeeper_self else maxi(10, int(round(13.0 * tav_mult)))
					if not is_innkeeper_self and npc.personal_gold < tav_price:
						continue
					for t_key in ["country_stew", "bread", "roasted_chicken"]:
						var tq: int = int(inn.shop_stock.get(t_key, 0))
						if tq > 0:
							inn.shop_stock[t_key] = tq - 1
							if not is_innkeeper_self:
								npc.personal_gold = maxi(0, npc.personal_gold - tav_price)
								inn.personal_gold += tav_price
							npc.add_thought("Pagó comida caliente en la Posada (-%d Oro, +5)" % tav_price, 5.0)
							npc._spawn_floating_text("🍲🍺 Plato de Posada (-%d Oro)" % tav_price, Color.GOLD, -32.0)
							return true

	# Respaldo: Si estaba en la Taberna pero estaba cerrada o era muy cara, revisar si aún le quedaba algo en su despensa casera
	if int(house_pantry.get(p_key, 0)) > 0:
		house_pantry[p_key] = int(house_pantry.get(p_key, 0)) - 1
		npc.add_thought("Comió de su despensa casera (+5)", 5.0)
		return true

	# ¡Escasez o falta de dinero! El NPC no pudo comprar comida y recurrirá a cazar/recolectar torpemente en el bosque
	village_food_shortage_days += 1
	npc.add_thought("¡Sin comida o sin oro para pagar precios de crisis! (-12)", -12.0)
	npc._spawn_floating_text("🍽️💸 ¡Sin comida accesible (Irá a buscar/cazar al bosque)!", Color.ORANGE_RED, -34.0)
	return false

## Procesa las ventas diarias y dividendos de un negocio propiedad del jugador al cambiar de día (escalados por la eficiencia laboral `get_job_efficiency()`)
func _process_daily_business_sales_and_dividends(role_id: int, holder: VillageNPC, sab_days: int) -> int:
	if not shop_businesses.has(role_id):
		return 0
	var biz: Dictionary = shop_businesses[role_id]
	var owner_mode: String = str(biz.get("owner_mode", "NPC"))
	if not (owner_mode in ["PARTNER", "SOLE_OWNER"]):
		return 0

	var has_active_worker: bool = is_instance_valid(holder) and not holder.is_dead and not holder.is_downed
	# Si no hay ningún trabajador vivo atendiendo el local, NO se puede vender nada en la tienda
	if not has_active_worker or sab_days > 0:
		return 0

	var eff: float = holder.get_job_efficiency()
	var earned_today: int = int(round(float(18 if owner_mode == "SOLE_OWNER" else 14) * eff))

	# 2. Ventas automáticas a los vecinos de los productos en el mostrador (limitadas por la eficiencia del trabajador)
	var st: Dictionary = get_trade_stock_dict(role_id)
	var mkt_mult: float = get_trade_market_multiplier(role_id)
	var max_sales: int = 1 if eff < 0.60 else (2 if eff < 0.85 else 3)
	var items_sold: int = 0
	for item_k in st.keys():
		if items_sold >= max_sales:
			break
		var avail: int = int(st.get(item_k, 0))
		if avail > 0:
			var sell_cnt: int = mini(avail, 2 if (items_sold == 0 and eff >= 0.85) else 1)
			st[item_k] = avail - sell_cnt
			items_sold += sell_cnt
			var unit_val: int = 12 if owner_mode == "SOLE_OWNER" else 8
			earned_today += int(round(float(unit_val * sell_cnt) * mkt_mult * eff))

	if earned_today > 0:
		biz["vault_gold"] = int(biz.get("vault_gold", 0)) + earned_today
	return earned_today

## Tecla [F] o Botón [4]: Sabotear Taller Industrial (estropea maquinaria 2 días, reduce stock, da botín y hunde el precio de compra del local)
func sabotage_shop_stall(player: Node2D, role_id: int) -> void:
	if not player or not shop_businesses.has(role_id):
		return
	var biz: Dictionary = shop_businesses[role_id]
	var b_title: String = str(biz.get("title", "Taller"))
	var cur_day: int = WorldClock.current_day if WorldClock else 1

	if int(biz.get("sabotaged_days", 0)) > 0 or int(biz.get("sabotaged_today_day", -1)) == cur_day:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🔧💥 Este taller ya fue saboteado hoy", Color.GOLD, -42.0)
		return

	biz["sabotaged_days"] = 2
	biz["sabotaged_today_day"] = cur_day
	recent_breakins_count += 1
	_refresh_shop_stall_visual(role_id)

	# Reducir a la mitad el stock actual del negocio (provocando Escasez / Crisis de Suministro 2.25x)
	var st: Dictionary = get_trade_stock_dict(role_id)
	for k in st.keys():
		st[k] = int(floor(float(st[k]) * 0.4))

	# Entregar 1 material saqueado del taller al jugador
	var inv: SimpleInventory = player.get("inventory")
	var sup_list: Array = biz.get("supply_items", ["wood"])
	var loot_id: String = str(sup_list[0]) if not sup_list.is_empty() else "wood"
	if inv:
		inv.add_item(loot_id, 1)
	var loot_name: String = str(SimpleInventory.CATALOG.get(loot_id, {}).get("name", loot_id))

	var in_stealth: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
	var cloak_mult: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
	var detect_rad: float = (48.0 if in_stealth else 145.0) * cloak_mult
	var witness: VillageNPC = _find_conscious_witness_near(biz.get("stall_pos", player.global_position), detect_rad, null)

	if witness == null:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("💣🤫 ¡Sabotaje industrial en sigilo! %s averiado (+1 %s | Precios a 2.25x)" % [b_title, loot_name], Color.SPRING_GREEN, -46.0)
		if player.has_method("show_hint"):
			player.call("show_hint", "💣 Has saboteado %s sin testigos: su producción se detiene 2 días, sus precios suben al 225%% y puedes comprar su escritura en liquidación (65 Oro)." % b_title)
	else:
		wanted_level = clampi(wanted_level + 1, 1, 5)
		bounty_gold += 35
		var fam_id: String = str(biz.get("family_id", "none"))
		modify_family_reputation(fam_id, -40, "Sabotaje del taller visto por " + witness.npc_name)
		var msg := "🚨👁️ ¡%s te vio sabotear %s! (+35 Oro de multa policial)" % [witness.npc_name, b_title]
		crime_history.push_front(msg)
		_notify_inquisitor_of_police_crime(msg, 22)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text(msg, Color.ORANGE_RED, -46.0)

	if business_panel and business_panel.visible and _active_business_role == role_id:
		open_business_management_ui(role_id)

## Abre el Modal de Gestión del Negocio, Oferta/Demanda, Caja Registradora y Compra Híbrida de Escritura
func open_business_management_ui(role_id: int) -> void:
	if not business_panel or not shop_businesses.has(role_id):
		return
	_active_business_role = role_id
	var biz: Dictionary = shop_businesses[role_id]
	var b_title: String = str(biz.get("title", "Negocio"))
	var fam_id: String = str(biz.get("family_id", "none"))
	var owner_mode: String = str(biz.get("owner_mode", "NPC"))
	var vault_gold: int = int(biz.get("vault_gold", 0))
	var sab_days: int = int(biz.get("sabotaged_days", 0))

	var holder: VillageNPC = trade_npcs.get(role_id)
	var holder_alive: bool = is_instance_valid(holder) and not holder.is_dead
	var holder_str: String = "%s (%s · ⚒️%s)" % [holder.npc_name, holder.npc_role, holder.get_job_efficiency_label()] if holder_alive else "❌ VACANTE (Sin artesano activo — Tienda cerrada)"
	var fam_aff: int = holder.affinity if holder_alive else _get_building_family_affinity("shop_" + fam_id)

	var st: Dictionary = get_trade_stock_dict(role_id)
	var stock_parts: Array[String] = []
	for k in st.keys():
		var k_name: String = str(SimpleInventory.CATALOG.get(str(k), {}).get("name", str(k)))
		stock_parts.append("%s: %d" % [k_name, int(st[k])])
	var stock_str: String = ", ".join(stock_parts) if not stock_parts.is_empty() else "Vacío (0 unidades)"

	var mkt_txt: String = get_trade_market_status_text(role_id)
	var sab_str: String = "🔧💥 SABOTEADO (%d días sin producir)" % sab_days if sab_days > 0 else "🟢 Operativo"
	var prop_str: String = "🏢 Propiedad Familiar Original"
	if owner_mode == "PARTNER":
		prop_str = "🤝 Eres Socio Capitalista (Recibes dividendos diarios + -30% Dto)"
	elif owner_mode == "SOLE_OWNER":
		prop_str = "👑 Eres el Dueño Único (100% de las ventas van a tu Caja Registradora)"

	business_info_lbl.text = "📜 %s\n👤 Artesano al frente: %s | 🛠️ Estado Taller: %s\n📊 Mercado Actual: %s | 📦 Stock Mostrador: %s\n🏛️ Propiedad: %s | 💰 Caja Registradora: %d Oro" % [
		b_title, holder_str, sab_str, mkt_txt, stock_str, prop_str, vault_gold
	]

	var tot_stk: int = get_trade_total_stock(role_id)
	var in_distress: bool = (not holder_alive) or (sab_days > 0) or (tot_stk <= 0)

	# Configurar Botón [1]: Comprar Escritura (Socio o Liquidación) O Recaudar Caja Registradora
	if owner_mode == "NPC":
		if in_distress:
			_biz_btn_1.text = "[1] 📜🔥 Comprar Escritura Completa en Liquidación (-65 Oro -> Dueño Único)"
		else:
			var partner_cost: int = 85 if fam_aff >= 45 else 110
			_biz_btn_1.text = "[1] 🤝 Comprar Acciones / Escritura de Socio (-%d Oro -> Dividendos Diarios + -30%% Dto)" % partner_cost
	elif owner_mode == "PARTNER" and vault_gold <= 0:
		_biz_btn_1.text = "[1] 👑 Adquirir el 100% de la Escritura (-55 Oro -> Pasar a Dueño Único)"
	else:
		_biz_btn_1.text = "[1] 💰 Recaudar Beneficios de la Caja Registradora (+%d Oro)" % vault_gold

	# Configurar Botón [2]: Abastecer el Mostrador con recursos de tu Mochila
	var sup_items: Array = biz.get("supply_items", [])
	var sup_names: Array[String] = []
	for i in range(mini(3, sup_items.size())):
		var s_id: String = str(sup_items[i])
		sup_names.append(str(SimpleInventory.CATALOG.get(s_id, {}).get("name", s_id)))
	_biz_btn_2.text = "[2] 📦 Abastecer Mostrador con tu Mochila (%s... -> Venta Automática)" % ", ".join(sup_names)

	# Configurar Botón [3]: Contratar / Asignar Encargado si está vacante o cobrar suministro
	if not holder_alive:
		_biz_btn_3.text = "[3] 🤝 Contratar Nuevo Encargado en la Posada (-30 Oro -> Reanuda Producción)"
	else:
		_biz_btn_3.text = "[3] 💬 Hablar / Comerciar Directamente con %s" % holder.npc_name

	# Configurar Botón [4]: Sabotear Taller o Reparar Taller Saboteado
	if sab_days > 0:
		_biz_btn_4.text = "[4] 🔧 Reparar Maquinaria Saboteada (-1 Madera o -12 Oro -> Reanuda Producción)"
	else:
		_biz_btn_4.text = "[4] 💣 Sabotear Taller [F] (Averiar 2 días, saquear material y subir precios a 2.25x)"

	business_panel.visible = true

func _on_business_action_1(player: Node2D) -> void:
	if not player or not ("inventory" in player) or not player.inventory or not shop_businesses.has(_active_business_role):
		return
	var inv: SimpleInventory = player.inventory
	var biz: Dictionary = shop_businesses[_active_business_role]
	var b_title: String = str(biz.get("title", "Negocio"))
	var fam_id: String = str(biz.get("family_id", "none"))
	var owner_mode: String = str(biz.get("owner_mode", "NPC"))
	var vault_gold: int = int(biz.get("vault_gold", 0))
	var sab_days: int = int(biz.get("sabotaged_days", 0))
	var holder: VillageNPC = trade_npcs.get(_active_business_role)
	var holder_alive: bool = is_instance_valid(holder) and not holder.is_dead
	var fam_aff: int = holder.affinity if holder_alive else _get_building_family_affinity("shop_" + fam_id)
	var tot_stk: int = get_trade_total_stock(_active_business_role)
	var in_distress: bool = (not holder_alive) or (sab_days > 0) or (tot_stk <= 0)

	if owner_mode == "NPC":
		if in_distress:
			var buyout_cost: int = 65
			if inv.gold < buyout_cost:
				player._spawn_floating_text("❌ Necesitas %d Oro para comprar la escritura en liquidación" % buyout_cost, Color.ORANGE_RED, -42.0)
				return
			inv.add_gold(-buyout_cost)
			biz["owner_mode"] = "SOLE_OWNER"
			_refresh_shop_stall_visual(_active_business_role)
			player._spawn_floating_text("👑📜 ¡Adquiriste el 100%% de %s en liquidación! (-%d Oro)" % [b_title, buyout_cost], Color.GOLD, -46.0)
		else:
			var partner_cost: int = 85 if fam_aff >= 45 else 110
			if inv.gold < partner_cost:
				player._spawn_floating_text("❌ Necesitas %d Oro para comprar acciones de Socio" % partner_cost, Color.ORANGE_RED, -42.0)
				return
			inv.add_gold(-partner_cost)
			biz["owner_mode"] = "PARTNER"
			modify_family_reputation(fam_id, 20, "Socio capitalista del negocio familiar")
			_refresh_shop_stall_visual(_active_business_role)
			player._spawn_floating_text("🤝📜 ¡Ahora eres Socio de %s! (-%d Oro | Dividendos diarios + -30%% Dto)" % [b_title, partner_cost], Color.SPRING_GREEN, -46.0)
	elif owner_mode == "PARTNER" and vault_gold <= 0:
		var up_cost: int = 55
		if inv.gold < up_cost:
			player._spawn_floating_text("❌ Necesitas %d Oro para adquirir el 100%% de la propiedad" % up_cost, Color.ORANGE_RED, -42.0)
			return
		inv.add_gold(-up_cost)
		biz["owner_mode"] = "SOLE_OWNER"
		_refresh_shop_stall_visual(_active_business_role)
		player._spawn_floating_text("👑📜 ¡Ahora eres Dueño Único de %s! (-%d Oro)" % [b_title, up_cost], Color.GOLD, -46.0)
	else:
		if vault_gold <= 0:
			player._spawn_floating_text("💰 La Caja Registradora está vacía por ahora (0 Oro)", Color.LIGHT_GRAY, -42.0)
			return
		inv.add_gold(vault_gold)
		biz["vault_gold"] = 0
		player._spawn_floating_text("💰✨ ¡Recaudaste +%d Oro de la Caja Registradora de %s!" % [vault_gold, b_title], Color.GOLD, -46.0)

	open_business_management_ui(_active_business_role)

func _on_business_action_2(player: Node2D) -> void:
	if not player or not ("inventory" in player) or not player.inventory or not shop_businesses.has(_active_business_role):
		return
	var inv: SimpleInventory = player.inventory
	var biz: Dictionary = shop_businesses[_active_business_role]
	var owner_mode: String = str(biz.get("owner_mode", "NPC"))
	var sup_items: Array = biz.get("supply_items", [])
	var st: Dictionary = get_trade_stock_dict(_active_business_role)
	var mkt_mult: float = get_trade_market_multiplier(_active_business_role)

	for raw_id in sup_items:
		var item_id: String = str(raw_id)
		if inv.has_item(item_id, 1):
			inv.remove_item(item_id, 1)
			st[item_id] = int(st.get(item_id, 0)) + 1
			var holder_sup: VillageNPC = trade_npcs.get(_active_business_role)
			if is_instance_valid(holder_sup) and item_id in ["wood", "iron_ore", "leather", "herbal_poultice", "bread", "fertilizer", "cooked_meat"]:
				holder_sup.workshop_materials[item_id] = int(holder_sup.workshop_materials.get(item_id, 0)) + 1
			var i_name: String = str(SimpleInventory.CATALOG.get(item_id, {}).get("name", item_id))
			if owner_mode in ["PARTNER", "SOLE_OWNER"]:
				# Como dueño/socio, reabasteces el stock físico de tu propio mostrador para que se venda a los vecinos y genere caja real
				_refresh_shop_stall_visual(_active_business_role)
				player._spawn_floating_text("📦✨ Abasteciste +1 %s en el mostrador de tu negocio (Stock actualizado)" % i_name, Color.SPRING_GREEN, -46.0)
			else:
				# Si abasteces un negocio ajeno en escasez, te pagan al contado al precio dinámico de mercado
				var instant_pay: int = maxi(6, int(round(9.0 * mkt_mult)))
				inv.add_gold(instant_pay)
				_refresh_shop_stall_visual(_active_business_role)
				var fam_id: String = str(biz.get("family_id", "none"))
				modify_family_reputation(fam_id, 6, "Suministró mercancía al mostrador")
				player._spawn_floating_text("📦🤝 Suministraste 1 %s al mostrador (+%d Oro al contado)" % [i_name, instant_pay], Color.GOLD, -44.0)
			open_business_management_ui(_active_business_role)
			return

	player._spawn_floating_text("❌ No llevas en tu mochila ningún producto compatible con este negocio", Color.ORANGE_RED, -42.0)

func _on_business_action_3(player: Node2D) -> void:
	if not player or not ("inventory" in player) or not player.inventory or not shop_businesses.has(_active_business_role):
		return
	var biz: Dictionary = shop_businesses[_active_business_role]
	var cfg: Dictionary = trade_configs.get(_active_business_role, {})
	var holder: VillageNPC = trade_npcs.get(_active_business_role)
	var holder_alive: bool = is_instance_valid(holder) and not holder.is_dead

	if holder_alive:
		business_panel.visible = false
		if holder.is_at_shop_counter() and player.global_position.distance_to(holder.global_position) <= 85.0:
			holder._start_npc_dialogue(player)
		elif player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("⏳ %s no está atendiendo el mostrador en este momento" % holder.npc_name, Color.GOLD, -42.0)
		return

	var inv: SimpleInventory = player.inventory
	if inv.gold < 30:
		player._spawn_floating_text("❌ Necesitas 30 Oro para contratar a un nuevo encargado", Color.ORANGE_RED, -42.0)
		return

	var candidate: VillageNPC = _pop_living_unemployed()
	if candidate == null:
		candidate = family_npcs.get(_active_business_role)
		if not is_instance_valid(candidate) or candidate.is_dead:
			candidate = null

	if candidate == null and arrivals_today_count >= MAX_DAILY_ARRIVALS:
		player._spawn_floating_text("⏳ Límite diario alcanzado (%d/%d llegadas hoy). Espera a mañana para que llegue otro artesano al valle" % [arrivals_today_count, MAX_DAILY_ARRIVALS], Color.GOLD, -44.0)
		return

	inv.add_gold(-30)

	if candidate != null:
		candidate.promote_to_trade(
			_active_business_role as VillageNPC.TradeRole,
			str(cfg.get("title", "Artesano")),
			cfg.get("work_pos", biz.get("stall_pos", Vector2.ZERO)),
			get_trade_stock_dict(_active_business_role),
			cfg.get("tex", null),
			cfg.get("bed1_pos", Vector2.ZERO),
			cfg.get("table_pos", Vector2.ZERO),
			str(cfg.get("family_id", "none")),
			str(cfg.get("family_name", "Gremio"))
		)
		trade_npcs[_active_business_role] = candidate
		if family_npcs.get(_active_business_role) == candidate:
			family_npcs.erase(_active_business_role)
		player._spawn_floating_text("🤝⚒️ ¡Contrataste a %s (%s) como encargado de %s! (-30 Oro)" % [candidate.npc_name, candidate.get_job_efficiency_label(), str(biz.get("title", ""))], Color.SPRING_GREEN, -46.0)
	else:
		# Si no quedan viajeros libres en la posada, llega un nuevo artesano novato caminando desde el borde del mapa (máx. 2 llegadas/día)
		arrivals_today_count += 1
		_rehire_counter += 1
		var hired_npc := VillageNPC.new()
		hired_npc.name = "NPC_Hired_Artisan_%d" % _rehire_counter
		hired_npc.npc_name = "Artesano Julián" if (_rehire_counter % 2 == 0) else "Artesana Clara"
		hired_npc.npc_role = str(cfg.get("title", "Encargado")) + " (Contratado)"
		hired_npc.trade_role = _active_business_role as VillageNPC.TradeRole
		hired_npc.linked_trade = _active_business_role as VillageNPC.TradeRole
		hired_npc.days_in_role = 0 # Empieza como Novato al 35% de eficiencia y tarda 7 días en llegar a Maestro
		hired_npc.tavern_social_pos = _tavern_social_pos
		entities_root.add_child(hired_npc)
		hired_npc.setup_npc(
			cfg.get("tex", null),
			cfg.get("work_pos", biz.get("stall_pos", Vector2.ZERO)),
			cfg.get("bed1_pos", _tavern_bed_pos),
			get_trade_stock_dict(_active_business_role),
			cfg.get("table_pos", _tavern_social_pos),
			str(cfg.get("family_id", "none")),
			str(cfg.get("family_name", "Gremio"))
		)
		hired_npc.global_position = _get_map_edge_arrival_pos(_rehire_counter)
		trade_npcs[_active_business_role] = hired_npc
		player._spawn_floating_text("🤝🚶 ¡Contrataste a %s (Novato 35%%)! Ya viene caminando desde el borde del mapa (-30 Oro)" % hired_npc.npc_name, Color.SPRING_GREEN, -46.0)

	open_business_management_ui(_active_business_role)

func _on_business_action_4(player: Node2D) -> void:
	if not player or not ("inventory" in player) or not player.inventory or not shop_businesses.has(_active_business_role):
		return
	var biz: Dictionary = shop_businesses[_active_business_role]
	var sab_days: int = int(biz.get("sabotaged_days", 0))

	if sab_days > 0:
		var inv: SimpleInventory = player.inventory
		if inv.has_item("wood", 1):
			inv.remove_item("wood", 1)
		elif inv.gold >= 12:
			inv.add_gold(-12)
		else:
			player._spawn_floating_text("❌ Requiere 1 Madera o 12 Oro para reparar la maquinaria del taller", Color.ORANGE_RED, -42.0)
			return
		biz["sabotaged_days"] = 0
		_refresh_shop_stall_visual(_active_business_role)
		var fam_id: String = str(biz.get("family_id", "none"))
		if int(biz.get("sabotaged_today_day", -1)) != (WorldClock.current_day if WorldClock else 1):
			modify_family_reputation(fam_id, 15, "Reparó el taller saboteado")
		player._spawn_floating_text("🔧✨ ¡Maquinaria de %s reparada y lista para producir!" % str(biz.get("title", "")), Color.SPRING_GREEN, -44.0)
		open_business_management_ui(_active_business_role)
	else:
		sabotage_shop_stall(player, _active_business_role)

# ==============================================================================
# FASE 9: ECONOMÍA CIRCULAR, CAMPAMENTOS RÚSTICOS DE VAGABUNDOS, 2 MERCADERES
# SEMANALES CON SALVOCONDUCTO REAL E INQUISIDOR REAL ALISTAIR (DEDUCCIÓN JUSTA)
# ==============================================================================

## 08:00 AM -> Salarios de Autoridades, Compras Recíprocas entre Gremios y Jornales de Viajeros
func _process_morning_salaries_and_inter_guild_circulation() -> void:
	# 1. Sueldo institucional diario para el Médico Forense y la Policía (14–18 Oro/día)
	for auth in authority_npcs:
		if is_instance_valid(auth) and not auth.is_dead and not auth.is_downed:
			var salary: int = 18 if auth.trade_role == VillageNPC.TradeRole.SHERIFF else (16 if auth.trade_role == VillageNPC.TradeRole.DOCTOR else 14)
			auth.personal_gold += salary
			auth._spawn_floating_text("💰+%d Oro (Salario)" % salary, Color.GOLD, -30.0)

	# 2. Demanda Cruzada entre Gremios: los comercios de comida y la Posada compran afilado/cuchillos/anzuelos
	# al Herrero (`Thoran`) y leña/barriles/reparaciones al Carpintero (`Bram`) para que el oro circule de vuelta.
	var smith_npc: VillageNPC = trade_npcs.get(int(VillageNPC.TradeRole.BLACKSMITH))
	var carp_npc: VillageNPC = trade_npcs.get(int(VillageNPC.TradeRole.CARPENTER))
	var food_sellers: Array[VillageNPC] = []
	for r_food in [int(VillageNPC.TradeRole.BUTCHER), int(VillageNPC.TradeRole.FISHMONGER), int(VillageNPC.TradeRole.HERBALIST)]:
		var fh: VillageNPC = trade_npcs.get(r_food)
		if is_instance_valid(fh) and not fh.is_dead and not fh.is_downed:
			food_sellers.append(fh)
	if is_instance_valid(_innkeeper_npc) and not _innkeeper_npc.is_dead and not _innkeeper_npc.is_downed:
		food_sellers.append(_innkeeper_npc)

	for seller in food_sellers:
		if seller.personal_gold >= 28:
			# Paga 7 Oro al Herrero por afilado de cuchillos/herramientas si vive
			if is_instance_valid(smith_npc) and not smith_npc.is_dead and not smith_npc.is_downed:
				seller.personal_gold -= 7
				smith_npc.personal_gold += 7
			# Paga 7 Oro al Carpintero por leña para el horno, cajas y barriles si vive
			if seller.personal_gold >= 20 and is_instance_valid(carp_npc) and not carp_npc.is_dead and not carp_npc.is_downed:
				seller.personal_gold -= 7
				carp_npc.personal_gold += 7

	# 3. Jornaleros y Viajeros sin Oficio (`UNEMPLOYED`): ganan un jornal modesto (8–12 Oro) acarreando leña/agua para talleres activos
	var active_shops_count: int = food_sellers.size()
	if is_instance_valid(smith_npc) and not smith_npc.is_dead:
		active_shops_count += 1
	if is_instance_valid(carp_npc) and not carp_npc.is_dead:
		active_shops_count += 1

	for guest in unemployed_npcs:
		if is_instance_valid(guest) and not guest.is_dead and not guest.is_downed:
			if active_shops_count > 0:
				var wage: int = clampi(4 + active_shops_count * 2, 6, 12)
				guest.personal_gold += wage
				guest._spawn_floating_text("🪓+%d Oro (Jornal)" % wage, Color(0.85, 0.95, 0.65), -30.0)

## 21:00 PM -> Cobro de 6 Oro/noche en la Posada o Desahucio a Campamentos Rústicos en las Afueras (`is_vagrant_camper`)
func _process_nightly_tavern_rent_and_vagrant_camps() -> void:
	var inn_alive: bool = is_instance_valid(_innkeeper_npc) and not _innkeeper_npc.is_dead
	var tav_blocked: bool = is_building_door_blocked("building_tavern")
	var rent_cost: int = 6

	for guest in unemployed_npcs:
		if not is_instance_valid(guest) or guest.is_dead or guest.trade_role != VillageNPC.TradeRole.UNEMPLOYED:
			continue
		# Si ya era vagabundo pero ha ahorrado >= 18 Oro y la Posada está abierta, recupera su cama bajo techo
		if guest.is_vagrant_camper and not tav_blocked and inn_alive and guest.personal_gold >= 18:
			guest.personal_gold -= rent_cost
			_innkeeper_npc.personal_gold += rent_cost
			guest.is_vagrant_camper = false
			var guest_beds: Array[Vector2] = [Vector2(435, -252), Vector2(468, -252), Vector2(502, -252)]
			guest.bed_position = guest_beds[abs(guest.npc_name.hash()) % guest_beds.size()]
			if vagrant_camp_nodes.has(guest.npc_name) and is_instance_valid(vagrant_camp_nodes[guest.npc_name]):
				vagrant_camp_nodes[guest.npc_name].visible = false
			guest.add_thought("Volvió a pagar cama caliente en la Posada (+8)", 8.0)
			guest._spawn_floating_text("🛏️🏠 Pagó Posada (-6 Oro)", Color.SPRING_GREEN, -34.0)
			continue

		if not guest.is_vagrant_camper:
			if tav_blocked or guest.personal_gold < rent_cost:
				evict_npc_to_vagrant_camp(guest)
			elif inn_alive:
				guest.personal_gold -= rent_cost
				_innkeeper_npc.personal_gold += rent_cost
				guest._spawn_floating_text("🛏️-6 Oro (Alquiler Posada)", Color.GOLD, -30.0)

## Convierte a un NPC sin dinero o sin acceso a su cama en Vagabundo y levanta su Campamento Rústico físico en las afueras
func evict_npc_to_vagrant_camp(npc: VillageNPC, _reason: String = "") -> void:
	if npc == null or npc.is_dead:
		return
	var camp_spots: Array[Vector2] = [
		Vector2(360, 345),
		Vector2(412, 355),
		Vector2(522, 348),
		Vector2(310, 348)
	]
	var idx: int = abs(npc.npc_name.hash()) % camp_spots.size()
	var c_pos: Vector2 = camp_spots[idx]
	npc.is_vagrant_camper = true
	npc.vagrant_camp_pos = c_pos
	npc.bed_position = c_pos
	_spawn_or_update_vagrant_camp_visual(npc, c_pos)
	npc.add_thought("Sin oro para la Posada: acampó a la intemperie (-10)", -10.0)
	npc._spawn_floating_text("⛺💸 ¡Sin dinero para la Posada! Monta campamento rústico en las afueras", Color.ORANGE, -38.0)

func _spawn_or_update_vagrant_camp_visual(npc: VillageNPC, camp_pos: Vector2) -> void:
	if not is_instance_valid(entities_root):
		return
	if vagrant_camp_nodes.has(npc.npc_name) and is_instance_valid(vagrant_camp_nodes[npc.npc_name]):
		var existing: Node2D = vagrant_camp_nodes[npc.npc_name]
		existing.global_position = camp_pos
		existing.visible = true
		return

	var camp_root := Node2D.new()
	camp_root.name = "VagrantCamp_" + npc.npc_name.replace(" ", "_")
	camp_root.global_position = camp_pos
	entities_root.add_child(camp_root)
	vagrant_camp_nodes[npc.npc_name] = camp_root

	# Suelo de tierra pisada del campamento rústico
	var dirt := Polygon2D.new()
	dirt.polygon = PackedVector2Array([
		Vector2(-18, -10), Vector2(18, -10), Vector2(20, 12), Vector2(-20, 12)
	])
	dirt.color = Color(0.36, 0.27, 0.18, 0.72)
	dirt.z_index = -2
	camp_root.add_child(dirt)

	# Tienda de lona improvisada (Tarp triangular)
	var tent := Polygon2D.new()
	tent.polygon = PackedVector2Array([
		Vector2(-15, 4), Vector2(-6, -11), Vector2(4, 4)
	])
	tent.color = Color(0.56, 0.46, 0.32, 0.95)
	tent.z_index = 0
	camp_root.add_child(tent)

	# Saco de dormir / petate junto a la lona
	var bedroll := Polygon2D.new()
	bedroll.polygon = PackedVector2Array([
		Vector2(-6, 1), Vector2(8, 1), Vector2(8, 7), Vector2(-6, 7)
	])
	bedroll.color = Color(0.45, 0.52, 0.36, 0.95)
	bedroll.z_index = -1
	camp_root.add_child(bedroll)

	# Pequeña hoguera de piedras para sobrevivir al frío nocturno
	var fire_glow := Polygon2D.new()
	fire_glow.polygon = PackedVector2Array([
		Vector2(10, -2), Vector2(15, -5), Vector2(18, 0), Vector2(14, 4)
	])
	fire_glow.color = Color(1.0, 0.58, 0.18, 0.88)
	fire_glow.z_index = 1
	camp_root.add_child(fire_glow)

	var lbl := Label.new()
	lbl.text = "⛺ Campamento Rústico de %s (Intemperie: Sueño máx. 74%%)" % npc.npc_name
	lbl.position = Vector2(-110, -26)
	lbl.custom_minimum_size = Vector2(220, 16)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 7)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.52))
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 3)
	camp_root.add_child(lbl)

## Comprueba cada mañana (07:00 AM) si hoy toca visita de uno de los 2 Mercaderes Semanales de Extramuros:
## - Día 3 de cada semana (`day % 7 == 3`): Maese Casimir (Liga Minera, presupuesto variable `168..196 Oro`).
## - Día 6 de cada semana (`day % 7 == 6`): Valeria la Tratante (Gremio de Caza y Pieles, presupuesto variable `214..248 Oro`).
func _check_weekly_merchant_arrival(current_day: int, ignore_suspension: bool = false, silent: bool = false) -> void:
	if is_instance_valid(_active_traveling_merchant) and not _active_traveling_merchant.is_dead:
		return

	var mod_d: int = current_day % 7
	var m_id: String = ""
	if mod_d == 3:
		m_id = "casimir"
	elif mod_d == 6:
		m_id = "valeria"
	else:
		return

	var susp_left: int = int(merchant_suspension_days.get(m_id, 0))
	if susp_left > 0 and not ignore_suspension:
		var p_emb = get_tree().get_first_node_in_group("player")
		if p_emb and p_emb.has_method("show_hint"):
			var emb_name: String = "Maese Casimir" if m_id == "casimir" else "Valeria la Tratante"
			p_emb.show_hint("🚫⚖️ Ruta Comercial Suspendida: %s NO ha venido hoy al pueblo por el asesinato previo (Quedan %d días de embargo económico)." % [emb_name, susp_left])
		return

	# Si el mercader anterior murió, conservar su cadáver en el mundo/morgue renombrándolo para que no colisione con el nuevo mercader
	if is_instance_valid(_active_traveling_merchant) and _active_traveling_merchant.is_dead:
		_active_traveling_merchant.name = "NPC_Merchant_Corpse_" + str(_active_traveling_merchant.get_instance_id())
		_active_traveling_merchant = null
	for old_n in get_tree().get_nodes_in_group("village_npcs"):
		if old_n is VillageNPC and (old_n as VillageNPC).merchant_id == m_id and (old_n as VillageNPC).is_dead:
			if not str(old_n.name).begins_with("NPC_Merchant_Corpse_"):
				old_n.name = "NPC_Merchant_Corpse_" + str(old_n.get_instance_id())

	var m_npc := VillageNPC.new()
	m_npc.trade_role = VillageNPC.TradeRole.TRAVELING_MERCHANT
	m_npc.merchant_id = m_id
	m_npc.carries_royal_safe_conduct = true
	m_npc.days_in_role = 7
	m_npc.tavern_social_pos = _tavern_social_pos

	if m_id == "casimir":
		m_npc.name = "NPC_Merchant_Casimir"
		m_npc.npc_name = "Maese Casimir"
		m_npc.npc_role = "Intendente de la Liga Minera"
		m_npc.personal_gold = randi_range(168, 196) # Cantidad dinámica no redonda
		m_npc.set_meta("initial_budget", m_npc.personal_gold)
		m_npc.set_meta("route_Bought_smith", false)
		m_npc.set_meta("route_Bought_carp", false)
		entities_root.add_child(m_npc)
		m_npc.setup_npc(
			_load_tex("res://assests/world/village/npcs_64/sprite_casimir.png"),
			Vector2(335, 12),
			Vector2(-900, 48),
			{"royal_ration": 3, "steel_ingot": 3, "copper_coil": 2, "repair_kit": 3},
			_tavern_social_pos,
			"none",
			"Comitiva Real de Extramuros"
		)
	else:
		m_npc.name = "NPC_Merchant_Valeria"
		m_npc.npc_name = "Valeria la Tratante"
		m_npc.npc_role = "Tratante de Caza y Pieles"
		m_npc.personal_gold = randi_range(214, 248) # Cantidad dinámica distinta a Casimir
		m_npc.set_meta("initial_budget", m_npc.personal_gold)
		m_npc.set_meta("route_Bought_butcher", false)
		m_npc.set_meta("route_Bought_fish", false)
		m_npc.set_meta("route_Bought_herb", false)
		entities_root.add_child(m_npc)
		m_npc.setup_npc(
			_load_tex("res://assests/world/village/npcs_64/sprite_valeria.png"),
			Vector2(585, 12),
			Vector2(990, 48),
			{"royal_ration": 4, "surgical_kit": 2, "sleeping_draught": 2},
			_tavern_social_pos,
			"none",
			"Comitiva Real de Extramuros"
		)

	m_npc.global_position = Vector2(-900, 48) if m_id == "casimir" else Vector2(990, 48)
	_active_traveling_merchant = m_npc

	if not silent:
		var p = get_tree().get_first_node_in_group("player")
		if p and p.has_method("show_hint"):
			p.show_hint("🐎👑 ¡Ha llegado %s (%s) con %d Oro y Salvoconducto Real! Comprará producción local hasta las 19:00." % [m_npc.npc_name, m_npc.npc_role, m_npc.personal_gold])

## IA física de los 2 Mercaderes Semanales: recorren las tiendas de su especialidad comprando solo lo que hay en stock
## (inyectando oro externo real a los artesanos y cazadores) y se marchan por el camino principal a las 19:00.
func update_traveling_merchant_ai(merchant: VillageNPC, delta: float) -> void:
	if merchant == null or merchant.is_dead or merchant.is_downed:
		return
	var h: int = WorldClock.current_hour if WorldClock else 12
	var m_id: String = merchant.merchant_id

	# A partir de las 19:00 regresan caminando hacia el borde del mapa para salir de la región con su Salvoconducto Real
	if h >= 19 or h < 6:
		var exit_pos: Vector2 = Vector2(-910, 48) if m_id == "casimir" else Vector2(1000, 48)
		merchant._merchant_leaving = true
		merchant.current_activity = VillageNPC.ActivityState.WORKING
		merchant._move_towards_point(exit_pos, 62.0, delta)
		if merchant.global_position.distance_to(exit_pos) <= 18.0:
			var p = get_tree().get_first_node_in_group("player")
			if p and p.has_method("show_hint"):
				p.show_hint("🐎📜 %s ha partido del valle hacia las Tierras Reales conservando %d Oro en su bolsa." % [merchant.npc_name, merchant.personal_gold])
			if _active_traveling_merchant == merchant:
				_active_traveling_merchant = null
			merchant.queue_free()
		return

	merchant._merchant_leaving = false
	merchant.current_activity = VillageNPC.ActivityState.WORKING
	var target_spot: Vector2 = Vector2(465, 44)
	if m_id == "casimir":
		if h < 12:
			target_spot = Vector2(335, -30) # Herrería de Thoran
		elif h < 16:
			target_spot = Vector2(585, 142) # Carpintería de Bram
		else:
			target_spot = Vector2(455, 44)  # Plaza Central para comerciar con el jugador
	else:
		if h < 11:
			target_spot = Vector2(585, -30) # Carnicería y Peletería de Garrick
		elif h < 14:
			target_spot = Vector2(465, 142) # Pescadería de Marlo
		elif h < 16:
			target_spot = Vector2(325, 150) # Botica de Elena
		else:
			target_spot = Vector2(480, 44)  # Plaza Central para comprar caza legal al jugador

	merchant._move_towards_point(target_spot, 56.0, delta)

	# Cuando llega a cada taller, compra solo las existencias disponibles (no gasta todo su oro si no hay suficiente mercancía)
	if m_id == "casimir":
		if h < 12 and not bool(merchant.get_meta("route_Bought_smith", false)) and merchant.global_position.distance_to(Vector2(335, -30)) <= 26.0:
			merchant.set_meta("route_Bought_smith", true)
			_merchant_buy_from_local_shop(merchant, int(VillageNPC.TradeRole.BLACKSMITH), ["repair_kit", "iron_ore", "steel_ingot"], 24, 68)
		elif h >= 12 and h < 16 and not bool(merchant.get_meta("route_Bought_carp", false)) and merchant.global_position.distance_to(Vector2(585, 142)) <= 26.0:
			merchant.set_meta("route_Bought_carp", true)
			_merchant_buy_from_local_shop(merchant, int(VillageNPC.TradeRole.CARPENTER), ["repair_kit", "wood", "copper_coil"], 20, 62)
	else:
		if h < 11 and not bool(merchant.get_meta("route_Bought_butcher", false)) and merchant.global_position.distance_to(Vector2(585, -30)) <= 26.0:
			merchant.set_meta("route_Bought_butcher", true)
			_merchant_buy_from_local_shop(merchant, int(VillageNPC.TradeRole.BUTCHER), ["leather", "cooked_meat", "roasted_chicken", "fox_pelt", "antlers"], 26, 78)
		elif h >= 11 and h < 14 and not bool(merchant.get_meta("route_Bought_fish", false)) and merchant.global_position.distance_to(Vector2(465, 142)) <= 26.0:
			merchant.set_meta("route_Bought_fish", true)
			_merchant_buy_from_local_shop(merchant, int(VillageNPC.TradeRole.FISHMONGER), ["cooked_fish", "bread", "fertilizer"], 18, 48)
		elif h >= 14 and h < 16 and not bool(merchant.get_meta("route_Bought_herb", false)) and merchant.global_position.distance_to(Vector2(325, 150)) <= 26.0:
			merchant.set_meta("route_Bought_herb", true)
			_merchant_buy_from_local_shop(merchant, int(VillageNPC.TradeRole.HERBALIST), ["herbal_poultice", "carrot_seeds"], 16, 42)

func _merchant_buy_from_local_shop(merchant: VillageNPC, role_id: int, wanted_keys: Array, unit_pay: int, max_spend_here: int) -> void:
	var holder: VillageNPC = trade_npcs.get(role_id)
	if not is_instance_valid(holder) or holder.is_dead or holder.is_downed or is_trade_sabotaged(role_id) or not holder.is_at_shop_counter():
		return
	var owner_mode_m: String = str(shop_businesses.get(role_id, {}).get("owner_mode", "NPC"))
	var spent: int = 0
	var bought_units: int = 0
	for k in wanted_keys:
		var key_s: String = str(k)
		var q: int = int(holder.shop_stock.get(key_s, 0))
		while q > 1 and merchant.personal_gold >= unit_pay and (spent + unit_pay) <= max_spend_here:
			q -= 1
			holder.shop_stock[key_s] = q
			merchant.shop_stock[key_s] = int(merchant.shop_stock.get(key_s, 0)) + 1
			merchant.personal_gold -= unit_pay
			if owner_mode_m == "SOLE_OWNER" and shop_businesses.has(role_id):
				shop_businesses[role_id]["vault_gold"] = int(shop_businesses[role_id].get("vault_gold", 0)) + unit_pay
			elif owner_mode_m == "PARTNER" and shop_businesses.has(role_id):
				var p_cut: int = int(ceil(float(unit_pay) * 0.5))
				shop_businesses[role_id]["vault_gold"] = int(shop_businesses[role_id].get("vault_gold", 0)) + p_cut
				holder.personal_gold += (unit_pay - p_cut)
			else:
				holder.personal_gold += unit_pay
			spent += unit_pay
			bought_units += 1
	if shop_businesses.has(role_id):
		shop_businesses[role_id]["stock_override"] = holder.shop_stock.duplicate()
	if spent > 0:
		_refresh_shop_stall_visual(role_id)
		# Además, los viajeros del pueblo que ayudan a cargar los fardos reciben una propina de 6 Oro del mercader
		for g in unemployed_npcs:
			if is_instance_valid(g) and not g.is_dead and merchant.personal_gold >= 6:
				merchant.personal_gold -= 6
				g.personal_gold += 6
		holder._spawn_floating_text("🤝💰 +%d Oro vendidos a %s" % [spent, merchant.npc_name], Color.GOLD, -36.0)
		merchant._spawn_floating_text("📦 Compró %d lotes (-%d Oro | Quedan %d Oro)" % [bought_units, spent, merchant.personal_gold], Color.AQUA, -36.0)
		merchant.trigger_action_animation(3.5)

## Se ejecuta cuando matan a `Maese Casimir` o a `Valeria la Tratante`:
## 1) Suspende su ruta comercial entre `20 y 30 días` (rango dinámico), dejando al pueblo sin esa inyección de oro.
## 2) Registra las coartadas reales (con línea de visión), testigos oculares y distancias de TODOS los NPCs vivos en ese instante,
##    los ordena por cercanía real a la escena del crimen y convoca al `Inquisidor Real Alistair` para que interrogue
##    físicamente a TODO el pueblo a un ritmo ágil (5 a 6+ aldeanos por día, sin alargar artificialmente el caso).
func on_traveling_merchant_murdered(merchant: VillageNPC, cause_text: String = "") -> void:
	if merchant == null:
		return
	var m_id: String = merchant.merchant_id if merchant.merchant_id != "" else "casimir"
	var embargo_days: int = randi_range(20, 30)
	merchant_suspension_days[m_id] = embargo_days

	var crime_pos: Vector2 = merchant.global_position
	var crime_hour: int = WorldClock.current_hour if WorldClock else 12
	var crime_day: int = WorldClock.current_day if WorldClock else 1
	var weapon_used: String = merchant.last_hit_weapon_name if merchant.last_hit_weapon_name != "" else cause_text
	var direct_murder_witness: String = str(merchant.murder_witness_name) if "murder_witness_name" in merchant else ""

	# Construir matriz deductiva justa de sospechosos, testigos oculares y coartadas en el instante real del crimen
	var suspects_dict: Dictionary = {}
	var npcs_to_interview: Array[String] = []
	var all_living: Array[VillageNPC] = []
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v != merchant and not v.is_dead and v.trade_role != VillageNPC.TradeRole.ROYAL_INVESTIGATOR:
				all_living.append(v)

	# Ordenar a TODOS los aldeanos vivos de menor a mayor distancia a la escena del crimen (`dist_to_crime`)
	all_living.sort_custom(func(a: VillageNPC, b: VillageNPC) -> bool:
		return a.global_position.distance_squared_to(crime_pos) < b.global_position.distance_squared_to(crime_pos)
	)

	var player := get_tree().get_first_node_in_group("player") as Node2D
	var player_dist_at_crime: float = player.global_position.distance_to(crime_pos) if player else 999.0
	var player_in_stealth: bool = player != null and player.has_method("is_stealthing") and bool(player.call("is_stealthing"))

	for v in all_living:
		# Memoria privada de cada habitante en el instante del crimen (el Inquisidor NO la conoce hasta interrogarlo)
		var alibi_partner: String = ""
		var seen_near_villager: String = ""
		for other in all_living:
			if other == v or other.is_downed or other.is_sleeping:
				continue
			var d_other: float = v.global_position.distance_to(other.global_position)
			if alibi_partner == "" and d_other <= 115.0 and has_line_of_sight(v.global_position, other.global_position):
				alibi_partner = other.npc_name
			elif seen_near_villager == "" and d_other <= 220.0 and other.global_position.distance_to(crime_pos) <= 280.0 and has_line_of_sight(v.global_position, other.global_position):
				seen_near_villager = other.npc_name

		var dist_to_crime: float = v.global_position.distance_to(crime_pos)
		var saw_player_near: bool = (direct_murder_witness != "" and v.npc_name == direct_murder_witness)
		if not saw_player_near and player != null and not v.is_sleeping and not v.is_downed and v.sedated_timer <= 0.0:
			var cloak_m: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
			var detect_r: float = (85.0 if player_in_stealth else 210.0) * cloak_m
			if v.global_position.distance_to(player.global_position) <= detect_r and player_dist_at_crime <= 240.0 * cloak_m:
				if has_line_of_sight(v.global_position, player.global_position):
					saw_player_near = true

		suspects_dict[v.npc_name] = {
			"name": v.npc_name,
			"is_player": false,
			"score": 10,
			"known_dist": -1.0,
			"mem_alibi_partner": alibi_partner,
			"mem_dist_to_crime": dist_to_crime,
			"mem_saw_player_near": saw_player_near,
			"mem_player_dist": player_dist_at_crime if saw_player_near else -1.0,
			"mem_seen_villager": seen_near_villager,
			"is_vagrant": (v.trade_role == VillageNPC.TradeRole.UNEMPLOYED or v.is_vagrant_camper),
			"interviewed": false,
			"status_note": "Paradero pendiente de interrogar"
		}
		npcs_to_interview.append(v.npc_name)

	# Expediente inicial del Jugador: sin omnisciencia mágica (Alistair solo sabe lo que conste en actas de la Guardia o declaren testigos)
	var player_init_score: int = 10
	var player_known_dist: float = -1.0
	var p_note: String = "Forastero en el valle (paradero aún no confirmado)"
	if direct_murder_witness != "":
		player_init_score += 45
		player_known_dist = player_dist_at_crime
		p_note = "Denunciado a la Guardia por testigo presencial (%s)" % direct_murder_witness
	if player_in_jail or player_being_escorted_to_jail or wanted_level > 0 or player_murder_warrants_count > 0:
		player_init_score += 35
		p_note = "Fichado/Arrestado por el Comisario Vane tras el crimen"

	suspects_dict["Jugador"] = {
		"name": "El Forastero (Jugador)",
		"is_player": true,
		"score": player_init_score,
		"known_dist": player_known_dist,
		"interviewed": false,
		"status_note": p_note
	}

	var total_villagers: int = npcs_to_interview.size()
	var max_inv_days: int = mini(18, embargo_days - 2) # Plazo máximo: antes de que regrese el nuevo mercader (<= 18 días)
	var init_daily_quota: int = 6                      # Interroga al menos a 5-6+ habitantes por día sin alargar artificialmente el caso

	var initial_clues: Array[String] = [
		"Cadáver de %s hallado en (%d, %d) a las %02d:00 del Día %d." % [merchant.npc_name, int(crime_pos.x), int(crime_pos.y), crime_hour, crime_day],
		"Herida forense compatible con: %s." % weapon_used,
		"Plan Inquisitorial: interrogar a los %d habitantes del pueblo (%d por día, sin demoras artificiales; límite máx. %d días)." % [total_villagers, init_daily_quota, max_inv_days]
	]
	if direct_murder_witness != "":
		initial_clues.append("Parte Policial del Comisario Vane: %s denunció al Forastero como autor presencial." % direct_murder_witness)

	active_royal_investigation = {
		"active": true,
		"victim_name": merchant.npc_name,
		"victim_id": m_id,
		"embargo_days": embargo_days,
		"crime_pos_x": crime_pos.x,
		"crime_pos_y": crime_pos.y,
		"crime_hour": crime_hour,
		"crime_day": crime_day,
		"days_investigating": 1,
		"max_days": max_inv_days,
		"daily_quota": init_daily_quota,
		"interviews_done_today": 0,
		"recon_spot_idx": 0,
		"weapon_used": weapon_used,
		"morgue_checked": false,
		"stage": "CRIME_SCENE", # "CRIME_SCENE" -> "MORGUE" -> "INITIAL_PLAYER_INTERVIEW" -> "INTERVIEWS" -> "PLAYER_CHECK" -> "VERDICT" -> "HUNTING_SCAPEGOAT" / "HUNTING_PLAYER" -> "DEPARTING"
		"stage_timer": 0.0,
		"routine_timer": 0.0,
		"interviews_done": 0,
		"max_interviews": total_villagers,
		"interview_queue": npcs_to_interview,
		"current_interview_target": "",
		"scapegoat_key": "",
		"clues_log": initial_clues,
		"suspects": suspects_dict,
		"verdict_target": "",
		"verdict_reason": ""
	}

	_spawn_royal_investigator()

	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("show_hint"):
		p.show_hint("👑🕵️‍♂️ ¡MAGNICIDIO COMERCIAL! %s ha muerto (Ruta suspendida %d días). El Inquisidor Real Alistair interrogará a todo el pueblo (~%d al día) y resolverá el caso sin demoras." % [merchant.npc_name, embargo_days, init_daily_quota])

func _get_investigation_crime_pos() -> Vector2:
	if active_royal_investigation.has("crime_pos_x") and active_royal_investigation.has("crime_pos_y"):
		return Vector2(float(active_royal_investigation["crime_pos_x"]), float(active_royal_investigation["crime_pos_y"]))
	var raw_cp: Variant = active_royal_investigation.get("crime_pos", Vector2(465, 44))
	if typeof(raw_cp) == TYPE_VECTOR2:
		return raw_cp as Vector2
	return Vector2(465, 44)

## Comunica en tiempo real cualquier arresto, fianza o ficha forense de la Comisaría/Morgue al expediente del Inquisidor Real Alistair
func _notify_inquisitor_of_police_crime(clue_text: String, suspicion_boost: int) -> void:
	if active_royal_investigation.is_empty() or not bool(active_royal_investigation.get("active", false)):
		return
	var suspects: Dictionary = active_royal_investigation.get("suspects", {})
	var clues: Array = active_royal_investigation.get("clues_log", [])
	if suspects.has("Jugador"):
		var p_entry: Dictionary = suspects["Jugador"]
		p_entry["score"] = int(p_entry.get("score", 16)) + suspicion_boost
		p_entry["status_note"] = "Fichado/Arrestado por el Comisario Vane"
	if not (clue_text in clues):
		clues.append(clue_text)

func _spawn_royal_investigator() -> void:
	if is_instance_valid(_royal_investigator_npc) and not _royal_investigator_npc.is_dead:
		_royal_investigator_npc.is_hostile = false
		_royal_investigator_npc.is_sleeping = false
		_royal_investigator_npc.remove_from_group("enemies")
		if "_police_alerted_timer" in _royal_investigator_npc:
			_royal_investigator_npc._police_alerted_timer = 0.0
		return
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and (n as VillageNPC).trade_role == VillageNPC.TradeRole.ROYAL_INVESTIGATOR and (n as VillageNPC).is_dead:
			if not str(n.name).begins_with("NPC_Royal_Investigator_Corpse_"):
				n.name = "NPC_Royal_Investigator_Corpse_" + str(n.get_instance_id())
	_royal_investigator_npc = null
	var inv_npc := VillageNPC.new()
	inv_npc.name = "NPC_Royal_Investigator_Alistair"
	inv_npc.npc_name = "Inquisidor Real Alistair"
	inv_npc.npc_role = "Alto Investigador de la Corona"
	inv_npc.trade_role = VillageNPC.TradeRole.ROYAL_INVESTIGATOR
	inv_npc.days_in_role = 7
	inv_npc.tavern_social_pos = _tavern_social_pos
	entities_root.add_child(inv_npc)
	inv_npc.setup_npc(
		_load_tex("res://assests/world/village/npcs_64/sprite_alistair.png"),
		Vector2(465, 44),
		Vector2(968, 132),
		{},
		Vector2(886, 126),
		"family_police",
		"Inquisición Real de la Corona"
	)
	inv_npc.global_position = _get_map_edge_arrival_pos(1)
	_royal_investigator_npc = inv_npc

## Avanza día a día la investigación del Inquisidor Real Alistair (`_on_day_passed`):
## - NO realiza interrogatorios telepáticos en segundo plano al cambiar de día ni al dormir en la celda:
##   Alistair siempre camina físicamente hacia cada habitante durante el día (interrogando al menos a 5-6+ personas por día).
## - Garantiza matemáticamente que el caso quede resuelto antes de que regrese el mercader (`max_days <= 18`).
func _advance_royal_investigation_day(_new_day: int) -> void:
	if active_royal_investigation.is_empty() or not bool(active_royal_investigation.get("active", false)):
		return
	var stg: String = str(active_royal_investigation.get("stage", "CRIME_SCENE"))
	# Si el Inquisidor Real fue abatido/asesinado mientras la investigación o persecución seguía activa, la Corona envía un nuevo Inquisidor al amanecer
	if stg != "DEPARTING" and (not is_instance_valid(_royal_investigator_npc) or _royal_investigator_npc.is_dead):
		_spawn_royal_investigator()
		if stg == "HUNTING_PLAYER" and is_instance_valid(_royal_investigator_npc):
			_royal_investigator_npc.is_hostile = true
			if not _royal_investigator_npc.is_in_group("enemies"):
				_royal_investigator_npc.add_to_group("enemies")
	if stg in ["DEPARTING", "HUNTING_SCAPEGOAT", "HUNTING_PLAYER"]:
		return

	var suspects: Dictionary = active_royal_investigation.get("suspects", {})
	var clues: Array = active_royal_investigation.get("clues_log", [])
	var queue: Array = active_royal_investigation.get("interview_queue", [])

	var days_inv: int = int(active_royal_investigation.get("days_investigating", 1)) + 1
	var max_days: int = int(active_royal_investigation.get("max_days", 18))
	active_royal_investigation["days_investigating"] = days_inv
	active_royal_investigation["interviews_done_today"] = 0

	# Recalcular la cuota diaria (mínimo 6 habitantes por día, o más si se acerca el día límite)
	var rem_days: int = maxi(1, (max_days - 1) - days_inv)
	var rem_to_interview: int = queue.size()
	var calc_quota: int = int(ceil(float(rem_to_interview) / float(rem_days)))
	active_royal_investigation["daily_quota"] = maxi(6, calc_quota)

	# Si el Inquisidor Real fue abatido/asesinado mientras la investigación seguía activa, la Corona envía un nuevo Inquisidor al amanecer
	if not is_instance_valid(_royal_investigator_npc) or _royal_investigator_npc.is_dead:
		_spawn_royal_investigator()

	# Solo si se alcanza el Día Límite (`max_days`, <= 18 días) se fuerza el cierre inmediato antes del regreso del mercader
	if days_inv >= max_days and stg in ["CRIME_SCENE", "MORGUE", "INITIAL_PLAYER_INTERVIEW", "INTERVIEWS", "PLAYER_CHECK"]:
		if not is_instance_valid(_royal_investigator_npc) or _royal_investigator_npc.is_dead:
			return
		while not queue.is_empty():
			var last_n: String = str(queue.pop_front())
			active_royal_investigation["interviews_done"] = int(active_royal_investigation.get("interviews_done", 0)) + 1
			var tv: VillageNPC = _find_npc_by_name(last_n)
			if tv != null and not tv.is_dead:
				_evaluate_npc_interview(_royal_investigator_npc, tv, suspects, clues)
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null:
			_evaluate_player_inspection(_royal_investigator_npc, player, suspects, clues, false)
		_conclude_royal_investigation_with_mandatory_verdict(_royal_investigator_npc)

## IA deductiva multidiaria paso a paso del Inquisidor Real Alistair:
## 1. Inspecciona físicamente la escena del crimen (`CRIME_SCENE`).
## 2. Examina la autopsia en la Morgue (`MORGUE`) y cruza datos con los archivos policiales del Comisario Vane.
## 3. Interroga inicialmente al Jugador (`INITIAL_PLAYER_INTERVIEW`) — yendo directamente a los barrotes de la celda si está preso.
## 4. Interroga físicamente a TODOS los aldeanos del pueblo (`INTERVIEWS`), deteniéndolos cara a cara (`hold_for_interview`),
##    a razón de 5-6+ interrogatorios por día, y pasa directo a la resolución apenas termina de interrogar a todos (sin esperas artificiales).
## 5. Inspección final al Jugador (`PLAYER_CHECK`), VEREDICTO OBLIGATORIO (`VERDICT`) y EJECUCIÓN PRESENCIAL (`HUNTING_SCAPEGOAT` / `HUNTING_PLAYER`).
func update_royal_investigator_ai(inv_npc: VillageNPC, delta: float) -> void:
	if inv_npc == null or inv_npc.is_dead or inv_npc.is_downed:
		return
	if active_royal_investigation.is_empty() or not bool(active_royal_investigation.get("active", false)):
		inv_npc.is_sleeping = false
		var exit_pt := Vector2(1000, 48)
		inv_npc._move_towards_point(exit_pt, 94.0, delta)
		if inv_npc.global_position.distance_to(exit_pt) <= 18.0:
			if _royal_investigator_npc == inv_npc:
				_royal_investigator_npc = null
			inv_npc.queue_free()
		return

	var stage: String = str(active_royal_investigation.get("stage", "CRIME_SCENE"))
	var s_timer: float = float(active_royal_investigation.get("stage_timer", 0.0))
	var r_timer: float = float(active_royal_investigation.get("routine_timer", 0.0))
	var suspects: Dictionary = active_royal_investigation.get("suspects", {})
	var clues: Array = active_royal_investigation.get("clues_log", [])
	var h: int = WorldClock.current_hour if WorldClock else 12
	var days_inv: int = int(active_royal_investigation.get("days_investigating", 1))
	var max_days: int = int(active_royal_investigation.get("max_days", 18))
	var done_cnt: int = int(active_royal_investigation.get("interviews_done", 0))
	var max_cnt: int = int(active_royal_investigation.get("max_interviews", 18))

	# Si el jugador ya fue encarcelado tras haber sido declarado culpable (`HUNTING_PLAYER`), Alistair da el caso por cerrado y regresa a la Corte
	if stage == "HUNTING_PLAYER":
		if player_in_jail or player_being_escorted_to_jail:
			inv_npc.is_hostile = false
			inv_npc.remove_from_group("enemies")
			active_royal_investigation["stage"] = "DEPARTING"
			inv_npc._spawn_floating_text("⚖️👑 ¡Caso resuelto ante la justicia real! Regreso a la Corte.", Color.GOLD, -44.0)
			return
		# Mantener la persecución activa hacia el jugador culpable para que nunca se quede congelado
		inv_npc.is_hostile = true
		inv_npc._police_alerted_timer = maxf(inv_npc._police_alerted_timer, 25.0)
		var p_hunt := get_tree().get_first_node_in_group("player") as Node2D
		if p_hunt != null:
			inv_npc._last_seen_player_pos = p_hunt.global_position
			inv_npc._process_police_law_enforcement(delta, self)
		return

	# Rutina diaria para fases de investigación (`CRIME_SCENE`, `MORGUE`, `INITIAL_PLAYER_INTERVIEW`, `INTERVIEWS`):
	if stage in ["CRIME_SCENE", "MORGUE", "INITIAL_PLAYER_INTERVIEW", "INTERVIEWS"]:
		# 1. Noche (22:00 a 06:00): Descansa en los aposentos de la Comisaría (`Vector2(968, 132)`)
		if h >= 22 or h < 6:
			var bed_pt := Vector2(968, 132)
			if inv_npc.global_position.distance_to(bed_pt) > 12.0:
				inv_npc.is_sleeping = false
				inv_npc._move_towards_point(bed_pt, 78.0, delta)
			else:
				inv_npc.velocity = Vector2.ZERO
				inv_npc.is_sleeping = true
				inv_npc.need_energy = minf(100.0, inv_npc.need_energy + delta * 10.0)
			return

		inv_npc.is_sleeping = false

		# 2. Amanecer (06:00 a 07:00): Revisa brevemente el expediente con el Comisario Vane en la Comisaría (`Vector2(886, 126)`)
		if h >= 6 and h < 7 and not player_in_jail:
			var desk_pt := Vector2(886, 126)
			if inv_npc.global_position.distance_to(desk_pt) > 18.0:
				inv_npc._move_towards_point(desk_pt, 82.0, delta)
			else:
				inv_npc.velocity = Vector2.ZERO
				inv_npc.trigger_action_animation(1.0)
				r_timer += delta
				active_royal_investigation["routine_timer"] = r_timer
				if int(r_timer * 10.0) % 40 == 0:
					inv_npc._spawn_floating_text("📋🕯️ Día %d: Cotejando actas con el Comisario Vane (%d/%d interrogados)..." % [days_inv, done_cnt, max_cnt], Color(1.0, 0.88, 0.45), -36.0)
			return

		# 3. Noche temprana (20:00 a 22:00): Cena y vigila a los sospechosos en la Posada (`_tavern_social_pos`)
		if h >= 20 and h < 22 and stage == "INTERVIEWS":
			var tav_pt: Vector2 = _tavern_social_pos
			if inv_npc.global_position.distance_to(tav_pt) > 22.0:
				inv_npc._move_towards_point(tav_pt, 78.0, delta)
			else:
				inv_npc.velocity = Vector2.ZERO
				inv_npc.trigger_action_animation(1.0)
				inv_npc.need_hunger = minf(100.0, inv_npc.need_hunger + delta * 12.0)
				r_timer += delta
				active_royal_investigation["routine_timer"] = r_timer
				if int(r_timer * 10.0) % 50 == 0:
					inv_npc._spawn_floating_text("🍷🕵️‍♂️ Vigilando sospechosos en la Posada (%d/%d interrogados)" % [done_cnt, max_cnt], Color.AQUA, -36.0)
			return

		# 4. Detección flagrante durante el día: si el jugador pasa a <= 56 px de Alistair con línea de visión llevando el Salvoconducto Real robado
		var p_near := get_tree().get_first_node_in_group("player") as Node2D
		if p_near != null and inv_npc.global_position.distance_to(p_near.global_position) <= 56.0:
			var p_inv: SimpleInventory = p_near.get("inventory")
			if p_inv and p_inv.has_item("royal_safe_conduct", 1) and has_line_of_sight(inv_npc.global_position, p_near.global_position):
				_evaluate_player_inspection(inv_npc, p_near, suspects, clues, false)
				active_royal_investigation["stage"] = "VERDICT"
				active_royal_investigation["stage_timer"] = 0.0
				return

	match stage:
		"CRIME_SCENE":
			var c_pos: Vector2 = _get_investigation_crime_pos()
			inv_npc._move_towards_point(c_pos, 90.0, delta)
			if inv_npc.global_position.distance_to(c_pos) <= 24.0:
				inv_npc.velocity = Vector2.ZERO
				inv_npc.trigger_action_animation(1.0)
				s_timer += delta
				active_royal_investigation["stage_timer"] = s_timer
				if int(s_timer * 10.0) % 28 == 0:
					inv_npc._spawn_floating_text("🔍🕵️‍♂️ Analizando rastros, sangre y distancias en la escena...", Color(1.0, 0.86, 0.38), -36.0)
				if s_timer >= 7.5:
					active_royal_investigation["stage"] = "MORGUE"
					active_royal_investigation["stage_timer"] = 0.0
					clues.append("Escena del crimen y perímetro de 360 px inspeccionados por Alistair.")
		"MORGUE":
			var m_pos: Vector2 = _morgue_table_positions[1]
			inv_npc._move_towards_point(m_pos, 90.0, delta)
			if inv_npc.global_position.distance_to(m_pos) <= 26.0:
				inv_npc.velocity = Vector2.ZERO
				inv_npc.trigger_action_animation(1.0)
				s_timer += delta
				active_royal_investigation["stage_timer"] = s_timer
				if s_timer >= 6.5:
					_cross_check_morgue_and_police_records(inv_npc, suspects, clues)
					active_royal_investigation["stage"] = "INITIAL_PLAYER_INTERVIEW"
					active_royal_investigation["stage_timer"] = 0.0
					inv_npc._spawn_floating_text("⚰️📜 Autopsia y partes policiales verificados: iré a interrogar al Forastero y al pueblo.", Color.AQUA, -38.0)
		"INITIAL_PLAYER_INTERVIEW":
			var player := get_tree().get_first_node_in_group("player") as Node2D
			if player == null:
				active_royal_investigation["stage"] = "INTERVIEWS"
				active_royal_investigation["stage_timer"] = 0.0
				return
			# Si el jugador está encerrado en la Celda de la Comisaría, Alistair camina hasta la reja del calabozo (`Vector2(902, 144)`)
			var target_pt: Vector2 = Vector2(902, 144) if player_in_jail else player.global_position
			var dist_to_target: float = inv_npc.global_position.distance_to(target_pt)
			if dist_to_target > 36.0:
				inv_npc._move_towards_point(target_pt, 96.0, delta)
				var walk_t: float = float(active_royal_investigation.get("walk_timer", 0.0)) + delta
				active_royal_investigation["walk_timer"] = walk_t
				# Si el jugador está fuera del pueblo (p. ej. en el Bosque Profundo) tras 24s de búsqueda, posponer su interrogatorio hasta `PLAYER_CHECK` sin inspeccionarlo por telepatía
				if walk_t >= 24.0 and not player_in_jail and dist_to_target > 240.0:
					active_royal_investigation["walk_timer"] = 0.0
					active_royal_investigation["stage_timer"] = 0.0
					active_royal_investigation["stage"] = "INTERVIEWS"
					inv_npc._spawn_floating_text("🕵️‍♂️📜 El Forastero no está en la aldea; interrogaré primero a los habitantes.", Color.AQUA, -38.0)
			else:
				active_royal_investigation["walk_timer"] = 0.0
				inv_npc.velocity = Vector2.ZERO
				var dir_to_p: Vector2 = (player.global_position - inv_npc.global_position)
				if dir_to_p.length_squared() > 1.0:
					inv_npc.facing_direction = dir_to_p.normalized()
				if inv_npc.sprite:
					inv_npc.sprite.flip_h = (player.global_position.x < inv_npc.global_position.x)
				inv_npc.trigger_action_animation(1.2)
				var prev_s: float = s_timer
				s_timer += delta
				active_royal_investigation["stage_timer"] = s_timer
				if prev_s < 0.6 and s_timer >= 0.6:
					if player_in_jail:
						inv_npc._spawn_floating_text("⚖️⛓️ Interrogándote en la celda: el Comisario Vane ya me entregó tus cargos...", Color.ORANGE_RED, -40.0)
					else:
						inv_npc._spawn_floating_text("🕵️‍♂️📜 Interrogando al Forastero: verificando tus manos, armas y coartada...", Color(1.0, 0.90, 0.52), -40.0)
				if s_timer >= 4.2:
					_evaluate_player_inspection(inv_npc, player, suspects, clues, true)
					active_royal_investigation["stage_timer"] = 0.0
					# Si ya encontró el Salvoconducto Real robado encima del jugador, dicta veredicto inmediato
					var p_sc: int = int(suspects.get("Jugador", {}).get("score", 0))
					var p_inv: SimpleInventory = player.get("inventory")
					if p_inv and p_inv.has_item("royal_safe_conduct", 1) and p_sc >= 85:
						active_royal_investigation["stage"] = "VERDICT"
					else:
						active_royal_investigation["stage"] = "INTERVIEWS"
		"INTERVIEWS":
			var queue: Array = active_royal_investigation.get("interview_queue", [])
			var cur_target_name: String = str(active_royal_investigation.get("current_interview_target", ""))
			# Apenas termina de interrogar a todos los habitantes (incluido el objetivo actual en curso), pasa DIRECTAMENTE a `PLAYER_CHECK`
			if done_cnt >= max_cnt or (queue.is_empty() and cur_target_name == ""):
				active_royal_investigation["stage"] = "PLAYER_CHECK"
				active_royal_investigation["stage_timer"] = 0.0
				return

			var done_today: int = int(active_royal_investigation.get("interviews_done_today", 0))
			var quota_today: int = int(active_royal_investigation.get("daily_quota", 6))
			# Si ya cumplió su cuota de 6+ interrogatorios del día, realiza reconstrucción forense el resto de la tarde
			if done_today >= quota_today and days_inv < max_days - 1:
				_process_inquisitor_field_recon(inv_npc, delta, done_cnt, max_cnt, days_inv)
				return

			if cur_target_name == "" and not queue.is_empty():
				cur_target_name = str(queue.pop_front())
				active_royal_investigation["current_interview_target"] = cur_target_name

			var target_npc: VillageNPC = _find_npc_by_name(cur_target_name)
			if target_npc == null or target_npc.is_dead:
				active_royal_investigation["current_interview_target"] = ""
				active_royal_investigation["interviews_done"] = done_cnt + 1
				return
			if target_npc.is_downed or target_npc.is_stunned_flag or target_npc.sedated_timer > 0.0:
				if not queue.is_empty():
					queue.push_back(cur_target_name)
					active_royal_investigation["current_interview_target"] = ""
				else:
					_process_inquisitor_field_recon(inv_npc, delta, done_cnt, max_cnt, days_inv)
				return

			var dist_npc: float = inv_npc.global_position.distance_to(target_npc.global_position)
			if dist_npc <= 46.0:
				# El NPC detiene lo que está haciendo, oculta su barra de crafteo y atiende cara a cara al Inquisidor
				target_npc.hold_for_interview(inv_npc, 0.9)

			if dist_npc > 32.0:
				inv_npc._move_towards_point(target_npc.global_position, 92.0, delta)
			else:
				inv_npc.velocity = Vector2.ZERO
				target_npc.hold_for_interview(inv_npc, 0.9)
				var to_target: Vector2 = target_npc.global_position - inv_npc.global_position
				if to_target.length_squared() > 1.0:
					inv_npc.facing_direction = to_target.normalized()
				if inv_npc.sprite:
					inv_npc.sprite.flip_h = (target_npc.global_position.x < inv_npc.global_position.x)
				inv_npc.trigger_action_animation(1.0)
				var prev_s_npc: float = s_timer
				s_timer += delta
				active_royal_investigation["stage_timer"] = s_timer
				if prev_s_npc < 0.6 and s_timer >= 0.6:
					inv_npc._spawn_floating_text("🕵️‍♂️📜 Interrogando a %s (%d/%d)..." % [target_npc.npc_name, done_cnt + 1, max_cnt], Color(1.0, 0.90, 0.52), -36.0)
				if s_timer >= 4.6:
					active_royal_investigation["stage_timer"] = 0.0
					active_royal_investigation["current_interview_target"] = ""
					active_royal_investigation["interviews_done"] = done_cnt + 1
					active_royal_investigation["interviews_done_today"] = done_today + 1
					_evaluate_npc_interview(inv_npc, target_npc, suspects, clues)
		"DEEP_FORENSICS":
			# Compatibilidad con guardados previos: pasar directamente a `PLAYER_CHECK` sin demoras artificiales
			active_royal_investigation["stage"] = "PLAYER_CHECK"
			active_royal_investigation["stage_timer"] = 0.0
		"PLAYER_CHECK":
			var player := get_tree().get_first_node_in_group("player") as Node2D
			if player == null:
				active_royal_investigation["stage"] = "VERDICT"
				return
			var check_pt: Vector2 = Vector2(902, 144) if player_in_jail else player.global_position
			var dist_chk: float = inv_npc.global_position.distance_to(check_pt)
			inv_npc._move_towards_point(check_pt, 98.0, delta)
			s_timer += delta
			active_royal_investigation["stage_timer"] = s_timer
			if dist_chk <= 38.0:
				inv_npc.velocity = Vector2.ZERO
				inv_npc.trigger_action_animation(3.5)
				_evaluate_player_inspection(inv_npc, player, suspects, clues, false)
				active_royal_investigation["stage"] = "VERDICT"
				active_royal_investigation["stage_timer"] = 0.0
			elif s_timer >= 24.0:
				# Si el jugador está escondido lejos del pueblo, Alistair emite el veredicto con las pruebas forenses y testimonios ya reunidos sin inspeccionarlo por telepatía
				inv_npc.velocity = Vector2.ZERO
				active_royal_investigation["stage"] = "VERDICT"
				active_royal_investigation["stage_timer"] = 0.0
		"VERDICT":
			inv_npc.trigger_action_animation(4.5)
			_conclude_royal_investigation_with_mandatory_verdict(inv_npc)
		"HUNTING_SCAPEGOAT":
			var sc_key: String = str(active_royal_investigation.get("scapegoat_key", ""))
			var scapegoat: VillageNPC = _find_npc_by_name(sc_key)
			if scapegoat == null or scapegoat.is_dead:
				active_royal_investigation["stage"] = "DEPARTING"
				active_royal_investigation["stage_timer"] = 0.0
				return
			s_timer += delta
			active_royal_investigation["stage_timer"] = s_timer
			if inv_npc.global_position.distance_to(scapegoat.global_position) <= 46.0:
				scapegoat.hold_for_interview(inv_npc, 1.0)
			inv_npc._move_towards_point(scapegoat.global_position, 104.0, delta)
			if inv_npc.global_position.distance_to(scapegoat.global_position) <= 28.0:
				inv_npc.velocity = Vector2.ZERO
				scapegoat.velocity = Vector2.ZERO
				inv_npc.trigger_action_animation(3.5)
				var chosen_name: String = scapegoat.npc_name
				var best_sc: int = int(suspects.get(sc_key, {}).get("score", 50))
				scapegoat._spawn_floating_text("⛓️😱 ¡Soy inocente! ¡No tenía coartada cerca de allí!", Color.ORANGE_RED, -42.0)
				scapegoat.last_hit_by_player = false
				scapegoat.last_hit_weapon_name = "Ejecutado presencialmente por el Inquisidor Real Alistair (Chivo Expiatorio)"
				scapegoat._confirm_true_death()
				inv_npc._spawn_floating_text("⚖️🗡️ ¡Sentencia real ejecutada contra %s! Caso cerrado." % chosen_name, Color.GOLD, -44.0)
				var p_h = get_tree().get_first_node_in_group("player")
				if p_h and p_h.has_method("show_hint"):
					p_h.show_hint("⚖️👑 ¡EJECUCIÓN INQUISITORIAL! Tras interrogar a todo el pueblo (%d/%d), el Inquisidor Real Alistair ajustició en persona a %s (el sospechoso cercano sin coartada con mayor probabilidad: %d%%)." % [done_cnt, max_cnt, chosen_name, clampi(best_sc, 35, 95)])
				active_royal_investigation["stage"] = "DEPARTING"
				active_royal_investigation["stage_timer"] = 0.0
		"HUNTING_PLAYER":
			if player_in_jail or player_being_escorted_to_jail:
				inv_npc.velocity = Vector2.ZERO
			elif not inv_npc.is_hostile and not inv_npc.is_downed and not inv_npc.is_stunned_flag and inv_npc.sedated_timer <= 0.0:
				inv_npc.is_hostile = true
				inv_npc._police_alerted_timer = 45.0
				if not inv_npc.is_in_group("enemies"):
					inv_npc.add_to_group("enemies")
		"DEPARTING":
			inv_npc.is_sleeping = false
			var exit_pos := Vector2(1000, 48)
			inv_npc._move_towards_point(exit_pos, 94.0, delta)
			if inv_npc.global_position.distance_to(exit_pos) <= 20.0:
				active_royal_investigation["active"] = false
				if _royal_investigator_npc == inv_npc:
					_royal_investigator_npc = null
				inv_npc.queue_free()

## Cuando Alistair ya completó su cuota de interrogatorios del día (6+ aldeanos), pasa el resto de la tarde
## reconstruyendo el caso entre la escena del crimen, la Morgue Forense, la Plaza y su escritorio en la Comisaría.
func _process_inquisitor_field_recon(inv_npc: VillageNPC, delta: float, done_cnt: int, max_cnt: int, days_inv: int) -> void:
	var c_pos: Vector2 = _get_investigation_crime_pos()
	var recon_pts: Array[Vector2] = [
		c_pos,
		_morgue_table_positions[1],
		Vector2(886, 126),
		Vector2(465, 36)
	]
	var r_idx: int = int(active_royal_investigation.get("recon_spot_idx", 0)) % recon_pts.size()
	var target_pt: Vector2 = recon_pts[r_idx]
	if inv_npc.global_position.distance_to(target_pt) > 22.0:
		inv_npc._move_towards_point(target_pt, 76.0, delta)
	else:
		inv_npc.velocity = Vector2.ZERO
		inv_npc.trigger_action_animation(1.0)
		var r_t: float = float(active_royal_investigation.get("routine_timer", 0.0)) + delta
		active_royal_investigation["routine_timer"] = r_t
		if int(r_t * 10.0) % 40 == 0:
			inv_npc._spawn_floating_text("🔍📓 Día %d: Cruzando testimonios (%d/%d interrogados)..." % [days_inv, done_cnt, max_cnt], Color(0.95, 0.88, 0.52), -36.0)
		if r_t >= 8.5:
			active_royal_investigation["routine_timer"] = 0.0
			active_royal_investigation["recon_spot_idx"] = (r_idx + 1) % recon_pts.size()

func _find_npc_by_name(target_name: String) -> VillageNPC:
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.npc_name == target_name and not v.is_dead:
				return v
	return null

## Cruza el libro de autopsias de la Morgue (`corpse_records`) y los arrestos del Comisario Vane con el expediente del Inquisidor
func _cross_check_morgue_and_police_records(inv_npc: VillageNPC, suspects: Dictionary, clues: Array) -> void:
	if bool(active_royal_investigation.get("morgue_checked", false)):
		return
	active_royal_investigation["morgue_checked"] = true
	if not suspects.has("Jugador"):
		return
	var p_entry: Dictionary = suspects["Jugador"]
	var v_name: String = str(active_royal_investigation.get("victim_name", ""))
	for rec in corpse_records:
		var r_victim: String = str(rec.get("victim_name", ""))
		var r_susp: String = str(rec.get("suspect", ""))
		var r_clue: String = str(rec.get("witness_clue", ""))
		if r_susp.begins_with("Jugador"):
			if r_victim == v_name:
				var c_msg: String = "Registro Forense de la Morgue: %s (%s)." % [r_susp, r_clue]
				if not (c_msg in clues):
					p_entry["score"] = int(p_entry.get("score", 16)) + 50
					p_entry["status_note"] = "Identificado en el Libro Forense (%s)" % r_clue
					clues.append(c_msg)
			else:
				var c_msg2: String = "Antecedente de homicidio en la Morgue (%s): %s." % [r_victim, r_clue]
				if not (c_msg2 in clues):
					p_entry["score"] = int(p_entry.get("score", 16)) + 25
					clues.append(c_msg2)
	if is_instance_valid(inv_npc) and int(p_entry.get("score", 0)) >= 50:
		inv_npc._spawn_floating_text("⚖️📔 ¡El Libro Forense y la Guardia vinculan al Forastero con el crimen!", Color.ORANGE_RED, -42.0)

func _evaluate_npc_interview(inv_npc: VillageNPC, witness: VillageNPC, suspects: Dictionary, clues: Array) -> void:
	if not suspects.has(witness.npc_name):
		return
	var entry: Dictionary = suspects[witness.npc_name]
	entry["interviewed"] = true
	var alibi: String = str(entry.get("mem_alibi_partner", entry.get("alibi_partner", "")))
	var dist_to_crime: float = float(entry.get("mem_dist_to_crime", entry.get("dist_to_crime", 999.0)))
	entry["known_dist"] = dist_to_crime
	var dist_m: int = int(round(dist_to_crime / 16.0))
	var is_eyewitness: bool = bool(entry.get("mem_saw_player_near", entry.get("saw_player_near", false)))

	if is_eyewitness and suspects.has("Jugador"):
		entry["score"] = 0
		entry["status_note"] = "Testigo ocular de cargo contra el Forastero (%dm)" % dist_m
		var p_entry: Dictionary = suspects["Jugador"]
		var p_dist: float = float(entry.get("mem_player_dist", 32.0))
		if p_dist >= 0.0:
			p_entry["known_dist"] = p_dist
		p_entry["score"] = int(p_entry.get("score", 10)) + 38
		p_entry["status_note"] = "Visto junto a la escena por %s" % witness.npc_name
		clues.append("Testimonio de %s: declaró haber visto al Forastero junto al mercader en el momento del crimen (+38%% sospecha al Jugador)." % witness.npc_name)
		witness._spawn_floating_text("🗣️👁️ ¡Lo vi! ¡El Forastero estaba junto al mercader!", Color.ORANGE_RED, -36.0)
		if is_instance_valid(inv_npc):
			inv_npc._spawn_floating_text("📝👁️ Testigo clave: %s vio al Forastero en la escena" % witness.npc_name, Color.ORANGE_RED, -38.0)
		return

	if alibi != "":
		entry["score"] = 0
		entry["status_note"] = "Coartada confirmada con %s (%dm)" % [alibi, dist_m]
		if suspects.has(alibi):
			var p_alibi: Dictionary = suspects[alibi]
			p_alibi["known_dist"] = float(p_alibi.get("mem_dist_to_crime", dist_to_crime))
			if not bool(p_alibi.get("interviewed", false)):
				p_alibi["score"] = 2
				p_alibi["status_note"] = "Coartada corroborada por %s" % witness.npc_name
		clues.append("%s declaró que estaba junto a %s a %d m de la escena (Coartada confirmada)." % [witness.npc_name, alibi, dist_m])
		if is_instance_valid(inv_npc):
			inv_npc._spawn_floating_text("📝✅ %s tiene coartada con %s" % [witness.npc_name, alibi], Color.SPRING_GREEN, -36.0)
	elif dist_to_crime > 360.0:
		entry["score"] = 0
		entry["status_note"] = "Descartado por distancia (%dm de la escena)" % dist_m
		clues.append("%s declaró estar en la otra punta del pueblo (a %d m de la escena — Descartado)." % [witness.npc_name, dist_m])
		if is_instance_valid(inv_npc):
			inv_npc._spawn_floating_text("📝📍 %s estaba lejos (%dm — Descartado)" % [witness.npc_name, dist_m], Color(0.65, 0.92, 1.0), -36.0)
	else:
		var new_sc: int = 48 if dist_to_crime <= 150.0 else (34 if dist_to_crime <= 250.0 else 22)
		if bool(entry.get("is_vagrant", false)):
			new_sc += 8
		entry["score"] = maxi(int(entry.get("score", 10)), new_sc)
		entry["status_note"] = "Estaba a %dm de la escena SIN coartada" % dist_m
		clues.append("%s admitió estar a %d m de la escena y SIN coartada (%d%% sospecha)." % [witness.npc_name, dist_m, int(entry["score"])])
		if is_instance_valid(inv_npc):
			inv_npc._spawn_floating_text("📝⚠️ %s estaba a %dm sin coartada (%d%% sospecha)" % [witness.npc_name, dist_m, int(entry["score"])], Color.GOLD, -36.0)

	# Fragmento adicional: si este vecino vio a otro aldeano merodeando cerca del crimen sin coartada, lo aporta al expediente
	var seen_v: String = str(entry.get("mem_seen_villager", ""))
	if seen_v != "" and suspects.has(seen_v):
		var sv_entry: Dictionary = suspects[seen_v]
		var sv_dist: float = float(sv_entry.get("mem_dist_to_crime", 200.0))
		sv_entry["known_dist"] = sv_dist
		if str(sv_entry.get("mem_alibi_partner", "")) == "" and sv_dist <= 360.0:
			sv_entry["score"] = int(sv_entry.get("score", 10)) + 12
			if not bool(sv_entry.get("interviewed", false)):
				sv_entry["status_note"] = "Situado cerca (%dm) por %s" % [int(round(sv_dist / 16.0)), witness.npc_name]
			clues.append("%s declaró haber visto a %s merodeando solo a %d m del crimen (+12%% sospecha a %s)." % [witness.npc_name, seen_v, int(round(sv_dist / 16.0)), seen_v])

func _evaluate_player_inspection(inv_npc: VillageNPC, player: Node2D, suspects: Dictionary, clues: Array, is_initial_interview: bool = false) -> void:
	if not suspects.has("Jugador") or not player:
		return
	var p_entry: Dictionary = suspects["Jugador"]
	var already_inspected: bool = bool(p_entry.get("interviewed", false))
	p_entry["interviewed"] = true
	var inv: SimpleInventory = player.get("inventory")
	if inv:
		if inv.has_item("royal_safe_conduct", 1) and not bool(p_entry.get("caught_with_safe_conduct", false)):
			p_entry["caught_with_safe_conduct"] = true
			p_entry["score"] = int(p_entry.get("score", 16)) + 75
			p_entry["status_note"] = "¡Porta el Salvoconducto Real robado!"
			clues.append("¡PRUEBA IRREFUTABLE! El Forastero lleva encima el Salvoconducto Real robado al mercader.")
			if is_instance_valid(inv_npc):
				inv_npc._spawn_floating_text("👑📜 ¡Llevas el Salvoconducto Real del difunto!", Color.ORANGE_RED, -42.0)
		var w_used: String = str(active_royal_investigation.get("weapon_used", "")).to_lower()
		var eq_w: Variant = player.get("equipped_weapon")
		var holding_matching_weapon: bool = (("espada" in w_used or "cuchillo" in w_used) and eq_w == player.get("sword_weapon")) or ("martillo" in w_used and eq_w == player.get("hammer_weapon")) or ("hacha" in w_used and eq_w == player.get("axe_weapon")) or ("arco" in w_used and eq_w == player.get("bow_weapon")) or ("pico" in w_used and eq_w == player.get("pickaxe_weapon")) or ("hoz" in w_used and eq_w == player.get("sickle_weapon"))
		if w_used != "" and not already_inspected and holding_matching_weapon:
			p_entry["score"] = int(p_entry.get("score", 16)) + 16
			clues.append("El Forastero empuña abiertamente armamento compatible con la herida forense (%s)." % w_used)
	if not already_inspected and (wanted_level > 0 or player_in_jail or player_being_escorted_to_jail or player_arrests_count > 0 or player_murder_warrants_count > 0 or recent_breakins_count > 0):
		var police_add: int = 36 if (player_in_jail or player_murder_warrants_count > 0 or player_arrests_count > 0) else 20
		p_entry["score"] = int(p_entry.get("score", 16)) + police_add
		p_entry["status_note"] = "Interrogado con antecedentes/arresto en la Comisaría"
		clues.append("El Comisario Vane confirmó antecedentes directos o arresto del Forastero (+%d%% sospecha)." % police_add)
	elif is_initial_interview and int(p_entry.get("score", 16)) < 40:
		p_entry["status_note"] = "Interrogado por Alistair (%d%% sospecha)" % int(p_entry.get("score", 16))

## FILOSOFÍA DEL INQUISIDOR REAL: "Nunca regresa a la Corte con las manos vacías".
## Condena al sospechoso con mayor puntuación real (desempatando siempre por quién estaba físicamente más cerca de la escena del crimen).
## Jamás condena a un aldeano que estuviera lejos de la escena (`dist_to_crime > 360 px`) ni a un testigo ocular (`score == 0`).
func _conclude_royal_investigation_with_mandatory_verdict(inv_npc: VillageNPC) -> void:
	var suspects: Dictionary = active_royal_investigation.get("suspects", {})
	var best_key: String = ""
	var best_score: int = -1
	var best_dist: float = 999999.0

	for k in suspects.keys():
		var s_entry: Dictionary = suspects[k]
		var is_p: bool = bool(s_entry.get("is_player", false))
		var sc: int = int(s_entry.get("score", 0))
		var kd: float = float(s_entry.get("known_dist", s_entry.get("dist_to_crime", -1.0)))
		var dist_c: float = kd if kd >= 0.0 else 9999.0
		if is_p:
			if sc <= 15 and kd < 0.0:
				continue
		else:
			var npc_node: VillageNPC = _find_npc_by_name(str(k))
			var real_d: float = float(s_entry.get("mem_dist_to_crime", dist_c))
			if npc_node == null or npc_node.is_dead or real_d > 360.0 or sc <= 0:
				continue
		if sc > best_score or (sc == best_score and dist_c < best_dist):
			best_score = sc
			best_dist = dist_c
			best_key = str(k)

	if best_key == "":
		for k in suspects.keys():
			var s_entry: Dictionary = suspects[k]
			if bool(s_entry.get("is_player", false)) or str(s_entry.get("alibi", "")) != "":
				continue
			var npc_node: VillageNPC = _find_npc_by_name(str(k))
			var real_d: float = float(s_entry.get("mem_dist_to_crime", 9999.0))
			if npc_node and not npc_node.is_dead and real_d < best_dist:
				best_dist = real_d
				best_key = str(k)
				best_score = maxi(35, int(s_entry.get("score", 25)))
	if best_key == "":
		best_key = "Jugador"

	var chosen: Dictionary = suspects.get(best_key, {})
	var chosen_name: String = str(chosen.get("name", best_key))
	active_royal_investigation["verdict_target"] = chosen_name

	var p = get_tree().get_first_node_in_group("player") as Node2D
	if bool(chosen.get("is_player", false)):
		active_royal_investigation["verdict_reason"] = "Culpable por deducción de pruebas y testimonios (%d%% de probabilidad)." % clampi(best_score, 50, 100)
		if player_in_jail or player_being_escorted_to_jail:
			# Si el jugador ya está encerrado en la Celda cuando Alistair emite el veredicto, le impone la condena real directamente y cierra el caso
			bounty_gold += 250
			active_royal_investigation["stage"] = "DEPARTING"
			inv_npc._spawn_floating_text("⚖️👑 ¡El Forastero es el asesino y ya está tras las rejas! (+250 Oro de condena real)", Color.GOLD, -44.0)
			if p and p.has_method("show_hint"):
				p.show_hint("⚖️👑 ¡VEREDICTO DEL INQUISIDOR REAL ALISTAIR! Tras interrogar a todo el pueblo, confirmó tu culpabilidad mientras estabas en la celda (+250 Oro a tu fianza). El Inquisidor regresa a la Corte.")
		else:
			active_royal_investigation["stage"] = "HUNTING_PLAYER"
			wanted_level = 5
			bounty_gold += 250
			is_resisting_arrest = true
			inv_npc.is_hostile = true
			inv_npc.add_to_group("enemies")
			if p:
				inv_npc._last_seen_player_pos = p.global_position
				inv_npc._police_alerted_timer = 65.0
				alert_police_to_resist(p)
				if p.has_method("show_hint"):
					p.show_hint("⚖️👑 ¡VEREDICTO DEL INQUISIDOR REAL ALISTAIR! Tras interrogar a todo el pueblo, te ha declarado CULPABLE del asesinato de %s (%d%% sospecha). ¡Orden de captura inmediata (+250 Oro)!" % [str(active_royal_investigation.get("victim_name", "Mercader")), clampi(best_score, 50, 100)])
			inv_npc._spawn_floating_text("⚖️🗡️ ¡EN NOMBRE DEL REY, TÚ ASESINASTE AL MERCADER!", Color.ORANGE_RED, -44.0)
	else:
		# ¡CHIVO EXPIATORIO CERCANO (`Scapegoat`)! El jugador ocultó sus pruebas y había otro aldeano SIN coartada cerca de la escena (`<= 360 px`).
		# Alistair camina físicamente hasta donde esté ese aldeano (`HUNTING_SCAPEGOAT`) para arrestarlo y ejecutarlo en persona.
		var sc_dist_m: int = int(round(float(chosen.get("known_dist", chosen.get("mem_dist_to_crime", 120.0))) / 16.0))
		active_royal_investigation["verdict_reason"] = "Condenado por estar a %d m de la escena sin coartada (%d%% sospecha)." % [sc_dist_m, clampi(best_score, 35, 95)]
		active_royal_investigation["scapegoat_key"] = best_key
		active_royal_investigation["stage"] = "HUNTING_SCAPEGOAT"
		active_royal_investigation["stage_timer"] = 0.0
		inv_npc._spawn_floating_text("⚖️📜 ¡Orden de ejecución contra %s (estaba a %dm de la escena sin coartada)!" % [chosen_name, sc_dist_m], Color.GOLD, -44.0)
		if p and p.has_method("show_hint"):
			p.show_hint("⚖️👑 ¡VEREDICTO EMITIDO! El Inquisidor Real Alistair se dirige a buscar y ejecutar personalmente a %s (estaba a %d m de la escena del crimen sin coartada: %d%% sospecha)." % [chosen_name, sc_dist_m, clampi(best_score, 35, 95)])

func get_royal_investigator_status_text() -> String:
	if active_royal_investigation.is_empty():
		return "Cerrado"
	var stg: String = str(active_royal_investigation.get("stage", "CRIME_SCENE"))
	var done_i: int = int(active_royal_investigation.get("interviews_done", 0))
	var max_i: int = int(active_royal_investigation.get("max_interviews", 18))
	var d_inv: int = int(active_royal_investigation.get("days_investigating", 1))
	var m_days: int = int(active_royal_investigation.get("max_days", 18))
	match stg:
		"CRIME_SCENE":
			return "Inspeccionando Escena (Día %d/%d)" % [d_inv, m_days]
		"MORGUE":
			return "Examinando Autopsia y Comisaría (Día %d/%d)" % [d_inv, m_days]
		"INITIAL_PLAYER_INTERVIEW":
			return "Yendo a Interrogarte (Día %d/%d)" % [d_inv, m_days]
		"INTERVIEWS":
			return "Interrogando Pueblo (%d/%d · Día %d/%d)" % [done_i, max_i, d_inv, m_days]
		"DEEP_FORENSICS":
			return "Cruzando Coartadas (%d/%d · Día %d/%d)" % [done_i, max_i, d_inv, m_days]
		"PLAYER_CHECK":
			return "Inspección Final al Forastero"
		"HUNTING_SCAPEGOAT":
			return "Yendo a Ajusticiar a " + str(active_royal_investigation.get("verdict_target", "Sospechoso"))
		"HUNTING_PLAYER":
			return "Persiguiendo al Culpable (Jugador)"
		"VERDICT", "DEPARTING":
			return "Veredicto: " + str(active_royal_investigation.get("verdict_target", "Emitido"))
	return "Investigando"

func get_royal_investigation_dialogue_summary() -> String:
	if active_royal_investigation.is_empty():
		return "📋 EXPEDIENTE REAL: Caso cerrado. Ningún crimen contra la Corona queda sin culpable."
	var v_name: String = str(active_royal_investigation.get("victim_name", "Mercader Real"))
	var w_used: String = str(active_royal_investigation.get("weapon_used", "Desconocida"))
	var done_i: int = int(active_royal_investigation.get("interviews_done", 0))
	var max_i: int = int(active_royal_investigation.get("max_interviews", 18))
	var d_inv: int = int(active_royal_investigation.get("days_investigating", 1))
	var m_days: int = int(active_royal_investigation.get("max_days", 18))
	var suspects: Dictionary = active_royal_investigation.get("suspects", {})

	var top_name: String = "Sin determinar (reuniendo testimonios)"
	var top_score: int = 10
	var top_dist: float = 999999.0
	for k in suspects.keys():
		var se: Dictionary = suspects[k]
		var sc: int = int(se.get("score", 0))
		var kd: float = float(se.get("known_dist", se.get("dist_to_crime", -1.0)))
		var dc: float = kd if kd >= 0.0 else 9999.0
		if not bool(se.get("is_player", false)) and kd > 360.0:
			continue
		if sc > top_score or (sc == top_score and sc > 10 and dc < top_dist):
			top_score = sc
			top_dist = dc
			top_name = str(se.get("name", k))

	var dist_txt: String = ("a %d m de la escena" % int(round(top_dist / 16.0))) if top_dist < 9000.0 else "paradero aún no confirmado"
	var clues: Array = active_royal_investigation.get("clues_log", [])
	var last_clue: String = str(clues[clues.size() - 1]) if not clues.is_empty() else "Reuniendo testimonios."
	return "📋 EXPEDIENTE DEL INQUISIDOR REAL (Víctima: %s | Arma Forense: %s)\n• Día %d de %d (Plazo máx. antes de fin de embargo) | Pueblo interrogado: %d/%d habitantes\n• Principal sospechoso actual: %s (%d%% prob. · %s)\n• Última pista: %s" % [
		v_name, w_used, d_inv, m_days, done_i, max_i, top_name, clampi(top_score, 10, 100), dist_txt, last_clue
	]

func get_royal_investigation_detailed_suspects_text() -> String:
	if active_royal_investigation.is_empty():
		return "📋 EXPEDIENTE CERRADO."
	var suspects: Dictionary = active_royal_investigation.get("suspects", {})
	var done_i: int = int(active_royal_investigation.get("interviews_done", 0))
	var max_i: int = int(active_royal_investigation.get("max_interviews", 18))
	var d_inv: int = int(active_royal_investigation.get("days_investigating", 1))
	var m_days: int = int(active_royal_investigation.get("max_days", 18))
	var arr: Array[Dictionary] = []
	for k in suspects.keys():
		arr.append(suspects[k])
	arr.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa: int = int(a.get("score", 0))
		var sb: int = int(b.get("score", 0))
		if sa != sb:
			return sa > sb
		var da: float = float(a.get("known_dist", -1.0))
		var db: float = float(b.get("known_dist", -1.0))
		return (da if da >= 0.0 else 9999.0) < (db if db >= 0.0 else 9999.0)
	)
	var lines: Array[String] = [
		"📋 REGISTRO INQUISITORIAL DE SOSPECHOSOS Y COARTADAS (Día %d/%d · %d/%d Interrogados):" % [d_inv, m_days, done_i, max_i]
	]
	var limit_cnt: int = mini(7, arr.size())
	for i in range(limit_cnt):
		var s: Dictionary = arr[i]
		var s_name: String = str(s.get("name", ""))
		var sc: int = int(s.get("score", 0))
		var kd: float = float(s.get("known_dist", s.get("dist_to_crime", -1.0)))
		var dist_tag: String = ("A %d m de la escena" % int(round(kd / 16.0))) if kd >= 0.0 else "Paradero desconocido"
		var iv_tag: String = "✅Interrogado" if bool(s.get("interviewed", false)) else "⏳Pendiente"
		var note: String = str(s.get("status_note", ""))
		lines.append("• #%d %s — %d%% sospecha | %s | [%s] %s" % [i + 1, s_name, sc, dist_tag, iv_tag, note])
	return "\n".join(lines)

func deploy_steel_bear_trap(pos: Vector2, _player: Node = null) -> void:
	if not is_instance_valid(entities_root):
		return
	var trap_root := Node2D.new()
	trap_root.name = "DeployedBearTrap_%d" % _deployed_bear_traps.size()
	trap_root.global_position = pos
	trap_root.z_index = -1
	trap_root.add_to_group("player_trap")
	entities_root.add_child(trap_root)

	var spr := Sprite2D.new()
	spr.texture = _load_tex("res://assests/items/icons/steel_bear_trap.png")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(0.95, 0.95)
	trap_root.add_child(spr)

	_deployed_bear_traps.append({
		"node": trap_root,
		"pos": pos,
		"arm_delay": 0.45
	})

func _update_deployed_bear_traps(delta: float, player: Node2D) -> void:
	for i in range(_deployed_bear_traps.size() - 1, -1, -1):
		var t_entry: Dictionary = _deployed_bear_traps[i]
		var t_node: Node2D = t_entry.get("node") as Node2D
		if not is_instance_valid(t_node):
			_deployed_bear_traps.remove_at(i)
			continue
		var arm_d: float = float(t_entry.get("arm_delay", 0.0))
		if arm_d > 0.0:
			t_entry["arm_delay"] = maxf(0.0, arm_d - delta)
			continue
		var t_pos: Vector2 = t_node.global_position
		var triggered_target: Node2D = null

		# 1. ¿Un animal salvaje pisó el cepo?
		for w in get_tree().get_nodes_in_group("wild_animals"):
			if w is WildAnimal:
				var wa := w as WildAnimal
				if wa.visible and not (wa.state in [WildAnimal.AnimalState.CARCASS, WildAnimal.AnimalState.BUTCHERED, WildAnimal.AnimalState.IN_BURROW]):
					if wa.global_position.distance_squared_to(t_pos) <= 16.0 * 16.0:
						triggered_target = wa
						break

		# 2. ¿Un enemigo de bosque o NPC hostil pisó el cepo?
		if triggered_target == null:
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Node2D and e != player:
					var en := e as Node2D
					if en.visible and not bool(en.get("is_dead")) and not bool(en.get("is_downed")) and en.global_position.distance_squared_to(t_pos) <= 16.0 * 16.0:
						triggered_target = en
						break

		if triggered_target != null and triggered_target.has_method("take_damage"):
			var dmg := DamageData.new()
			dmg.amount = 35.0
			dmg.type = CombatConstants.DamageType.CUT
			dmg.bleed_buildup = 85.0
			dmg.stun_buildup = 100.0
			dmg.source = t_node
			triggered_target.call("take_damage", dmg)
			if "last_hit_weapon_name" in triggered_target:
				triggered_target.set("last_hit_weapon_name", "Cepo de Acero")
			if triggered_target.has_method("_spawn_floating_text"):
				triggered_target.call("_spawn_floating_text", "🪤💥 ¡ATRAPADO EN CEPO DE ACERO! (-35 HP, Stun)", Color.ORANGE_RED, -40.0)
			t_node.queue_free()
			_deployed_bear_traps.remove_at(i)

func get_economy_save_dict() -> Dictionary:
	var out: Dictionary = {}
	for r_id in shop_businesses.keys():
		var role_int: int = int(r_id)
		var biz: Dictionary = shop_businesses[role_int]
		out[str(role_int)] = {
			"owner_mode": str(biz.get("owner_mode", "NPC")),
			"vault_gold": int(biz.get("vault_gold", 0)),
			"sabotaged_days": int(biz.get("sabotaged_days", 0)),
			"sabotaged_today_day": int(biz.get("sabotaged_today_day", -1)),
			"stock_override": get_trade_stock_dict(role_int).duplicate()
		}
	var saved_merchant: Dictionary = {}
	if is_instance_valid(_active_traveling_merchant) and not _active_traveling_merchant.is_dead:
		saved_merchant = _active_traveling_merchant.to_save_dict()
	var saved_investigator: Dictionary = {}
	if is_instance_valid(_royal_investigator_npc) and not _royal_investigator_npc.is_dead:
		saved_investigator = _royal_investigator_npc.to_save_dict()
	var saved_pets: Array[Dictionary] = []
	for p in domestic_pets:
		if is_instance_valid(p) and p.has_method("to_save_dict"):
			saved_pets.append(p.to_save_dict())
	var saved_chests: Dictionary = {}
	for ch in house_chests:
		var ch_id: String = str(ch.get("title", ch.get("family_id", ch.get("id", ""))))
		if ch_id != "":
			saved_chests[ch_id] = int(ch.get("looted_day", -1))
	var saved_doors: Dictionary = {}
	for d_entry in building_doors:
		var d_id: String = str(d_entry.get("building_id", d_entry.get("id", "")))
		if d_id != "":
			saved_doors[d_id] = {
				"is_open": bool(d_entry.get("is_open", false)),
				"is_locked": bool(d_entry.get("is_locked", false)),
				"locked_by_player": bool(d_entry.get("locked_by_player", false)),
				"manual_override_timer": float(d_entry.get("manual_override_timer", 0.0)),
				"picked_until_hour": int(d_entry.get("picked_until_hour", -1)),
				"picked_day": int(d_entry.get("picked_day", -1))
			}
	var saved_windows: Dictionary = {}
	for w_entry in building_windows:
		var w_id: String = str(w_entry.get("building_id", w_entry.get("id", "")))
		if w_id != "":
			saved_windows[w_id] = {
				"is_shuttered": bool(w_entry.get("is_shuttered", false)),
				"manual_override_timer": float(w_entry.get("manual_override_timer", 0.0)),
				"picked_until_hour": int(w_entry.get("picked_until_hour", -1)),
				"picked_day": int(w_entry.get("picked_day", -1))
			}
	var saved_traps: Array[Dictionary] = []
	for tr in _deployed_bear_traps:
		var tr_node: Node2D = tr.get("node") as Node2D
		if is_instance_valid(tr_node):
			saved_traps.append({"x": tr_node.global_position.x, "y": tr_node.global_position.y})
	return {
		"businesses": out,
		"village_food_shortage_days": village_food_shortage_days,
		"house_pantry": house_pantry.duplicate(),
		"merchant_suspension_days": merchant_suspension_days.duplicate(),
		"active_royal_investigation": active_royal_investigation.duplicate(true),
		"active_traveling_merchant": saved_merchant,
		"royal_investigator_npc": saved_investigator,
		"domestic_pets": saved_pets,
		"player_arrests_count": player_arrests_count,
		"player_murder_warrants_count": player_murder_warrants_count,
		"recent_breakins_count": recent_breakins_count,
		"crime_history": crime_history.duplicate(),
		"arrivals_today_count": arrivals_today_count,
		"rehire_counter": _rehire_counter,
		"house_chests": saved_chests,
		"building_doors": saved_doors,
		"building_windows": saved_windows,
		"deployed_bear_traps": saved_traps
	}

func load_economy_save_dict(data: Dictionary) -> void:
	village_food_shortage_days = int(data.get("village_food_shortage_days", 0))
	player_arrests_count = int(data.get("player_arrests_count", 0))
	player_murder_warrants_count = int(data.get("player_murder_warrants_count", 0))
	recent_breakins_count = int(data.get("recent_breakins_count", 0))
	arrivals_today_count = int(data.get("arrivals_today_count", 0))
	_rehire_counter = maxi(_rehire_counter, int(data.get("rehire_counter", _rehire_counter)))
	if data.has("crime_history") and typeof(data["crime_history"]) == TYPE_ARRAY:
		crime_history.clear()
		for ch_item in (data["crime_history"] as Array):
			crime_history.append(str(ch_item))
	if data.has("house_chests") and typeof(data["house_chests"]) == TYPE_DICTIONARY:
		var sc: Dictionary = data["house_chests"]
		var cur_d: int = WorldClock.current_day if WorldClock else 1
		for ch in house_chests:
			var ch_title_key: String = str(ch.get("title", ""))
			var ch_fam_key: String = str(ch.get("family_id", ch.get("id", "")))
			var match_key: String = ch_title_key if sc.has(ch_title_key) else (ch_fam_key if sc.has(ch_fam_key) else "")
			if match_key != "":
				ch["looted_day"] = int(sc[match_key])
				var spr: Sprite2D = ch.get("sprite")
				if is_instance_valid(spr):
					var is_open: bool = (int(ch["looted_day"]) == cur_d)
					spr.texture = _load_tex("res://assests/world/village/house_chest_open.png" if is_open else "res://assests/world/village/house_chest_closed.png")
			else:
				ch["looted_day"] = -1
				var spr_def: Sprite2D = ch.get("sprite")
				if is_instance_valid(spr_def):
					spr_def.texture = _load_tex("res://assests/world/village/house_chest_closed.png")
	if data.has("building_doors") and typeof(data["building_doors"]) == TYPE_DICTIONARY:
		var sd: Dictionary = data["building_doors"]
		for d_entry in building_doors:
			var d_id: String = str(d_entry.get("building_id", d_entry.get("id", "")))
			if sd.has(d_id) and typeof(sd[d_id]) == TYPE_DICTIONARY:
				var de: Dictionary = sd[d_id]
				d_entry["is_open"] = bool(de.get("is_open", false))
				d_entry["is_locked"] = bool(de.get("is_locked", false))
				d_entry["locked_by_player"] = bool(de.get("locked_by_player", false))
				d_entry["manual_override_timer"] = float(de.get("manual_override_timer", 0.0))
				d_entry["picked_until_hour"] = int(de.get("picked_until_hour", -1))
				d_entry["picked_day"] = int(de.get("picked_day", -1))
				_refresh_door_visual_and_collision(d_entry)
	if data.has("building_windows") and typeof(data["building_windows"]) == TYPE_DICTIONARY:
		var sw: Dictionary = data["building_windows"]
		var tex_win_open := _load_tex("res://assests/world/village/window_glass_open.png")
		var tex_win_shut := _load_tex("res://assests/world/village/window_shutter_closed.png")
		for w_entry in building_windows:
			var w_id: String = str(w_entry.get("building_id", w_entry.get("id", "")))
			if sw.has(w_id) and typeof(sw[w_id]) == TYPE_DICTIONARY:
				var we: Dictionary = sw[w_id]
				var shut: bool = bool(we.get("is_shuttered", we.get("is_locked", false)))
				w_entry["is_shuttered"] = shut
				w_entry["manual_override_timer"] = float(we.get("manual_override_timer", 0.0))
				w_entry["picked_until_hour"] = int(we.get("picked_until_hour", -1))
				w_entry["picked_day"] = int(we.get("picked_day", -1))
				var w_spr: Sprite2D = w_entry.get("sprite")
				if is_instance_valid(w_spr):
					w_spr.texture = tex_win_shut if shut else tex_win_open
	for tr in _deployed_bear_traps:
		var tr_n: Node2D = tr.get("node") as Node2D
		if is_instance_valid(tr_n):
			tr_n.queue_free()
	_deployed_bear_traps.clear()
	if data.has("deployed_bear_traps") and typeof(data["deployed_bear_traps"]) == TYPE_ARRAY:
		for t_item in (data["deployed_bear_traps"] as Array):
			if typeof(t_item) == TYPE_DICTIONARY:
				var td: Dictionary = t_item
				deploy_steel_bear_trap(Vector2(float(td.get("x", 0.0)), float(td.get("y", 0.0))))
	if data.has("house_pantry") and typeof(data["house_pantry"]) == TYPE_DICTIONARY:
		house_pantry = (data["house_pantry"] as Dictionary).duplicate()
	if data.has("merchant_suspension_days") and typeof(data["merchant_suspension_days"]) == TYPE_DICTIONARY:
		merchant_suspension_days = (data["merchant_suspension_days"] as Dictionary).duplicate()
	# Reconciliar los nodos dinámicos ya restaurados por GameManager antes de evaluar mercaderes e Inquisidor para evitar duplicados
	reconcile_npc_registries_after_load()
	if data.has("active_traveling_merchant") and typeof(data["active_traveling_merchant"]) == TYPE_DICTIONARY:
		var m_data: Dictionary = data["active_traveling_merchant"] as Dictionary
		if m_data.is_empty() or bool(m_data.get("is_dead", false)):
			if is_instance_valid(_active_traveling_merchant) and not _active_traveling_merchant.is_dead:
				_active_traveling_merchant.remove_from_group("village_npcs")
				_active_traveling_merchant.remove_from_group("npcs")
				_active_traveling_merchant.name = "_freed_merchant_" + str(_active_traveling_merchant.get_instance_id())
				if _active_traveling_merchant.get_parent():
					_active_traveling_merchant.get_parent().remove_child(_active_traveling_merchant)
				_active_traveling_merchant.queue_free()
				_active_traveling_merchant = null
		else:
			var m_id_saved: String = str(m_data.get("merchant_id", "casimir"))
			if is_instance_valid(_active_traveling_merchant) and _active_traveling_merchant.merchant_id != m_id_saved and not _active_traveling_merchant.is_dead:
				_active_traveling_merchant.remove_from_group("village_npcs")
				_active_traveling_merchant.remove_from_group("npcs")
				_active_traveling_merchant.name = "_freed_merchant_" + str(_active_traveling_merchant.get_instance_id())
				if _active_traveling_merchant.get_parent():
					_active_traveling_merchant.get_parent().remove_child(_active_traveling_merchant)
				_active_traveling_merchant.queue_free()
				_active_traveling_merchant = null
			if not is_instance_valid(_active_traveling_merchant):
				_check_weekly_merchant_arrival(3 if m_id_saved == "casimir" else 6, true, true)
			if is_instance_valid(_active_traveling_merchant):
				_active_traveling_merchant.from_save_dict(m_data)
	if data.has("active_royal_investigation") and typeof(data["active_royal_investigation"]) == TYPE_DICTIONARY:
		active_royal_investigation = (data["active_royal_investigation"] as Dictionary).duplicate(true)
		var inv_data: Dictionary = data.get("royal_investigator_npc", {}) if typeof(data.get("royal_investigator_npc", {})) == TYPE_DICTIONARY else {}
		if bool(active_royal_investigation.get("active", false)):
			if not inv_data.is_empty() and not bool(inv_data.get("is_dead", false)):
				if not is_instance_valid(_royal_investigator_npc):
					_spawn_royal_investigator()
				if is_instance_valid(_royal_investigator_npc):
					_royal_investigator_npc.from_save_dict(inv_data)
			if str(active_royal_investigation.get("stage", "")) == "HUNTING_PLAYER" and not player_in_jail and not player_being_escorted_to_jail:
				is_resisting_arrest = true
				alert_police_to_resist()
				if is_instance_valid(_royal_investigator_npc) and not _royal_investigator_npc.is_dead:
					_royal_investigator_npc.is_hostile = true
					if not _royal_investigator_npc.is_in_group("enemies"):
						_royal_investigator_npc.add_to_group("enemies")
		else:
			if is_instance_valid(_royal_investigator_npc) and not _royal_investigator_npc.is_dead:
				_royal_investigator_npc.remove_from_group("village_npcs")
				_royal_investigator_npc.remove_from_group("npcs")
				_royal_investigator_npc.name = "_freed_inquisitor_" + str(_royal_investigator_npc.get_instance_id())
				if _royal_investigator_npc.get_parent():
					_royal_investigator_npc.get_parent().remove_child(_royal_investigator_npc)
				_royal_investigator_npc.queue_free()
				_royal_investigator_npc = null
	if data.has("domestic_pets") and typeof(data["domestic_pets"]) == TYPE_ARRAY:
		var p_arr: Array = data["domestic_pets"] as Array
		for p_item in p_arr:
			if typeof(p_item) == TYPE_DICTIONARY:
				var p_dict: Dictionary = p_item as Dictionary
				var p_name_target: String = str(p_dict.get("pet_name", ""))
				for pet_node in domestic_pets:
					if is_instance_valid(pet_node) and pet_node.pet_name == p_name_target and pet_node.has_method("from_save_dict"):
						pet_node.from_save_dict(p_dict)
						break
	# Reconciliar primero los registros de NPCs vivos para que `trade_npcs` apunte a los titulares actuales antes de aplicar `stock_override`
	reconcile_npc_registries_after_load()

	var b_dict: Variant = data.get("businesses", {})
	if typeof(b_dict) != TYPE_DICTIONARY:
		return
	var saved_b: Dictionary = b_dict as Dictionary
	for k_str in saved_b.keys():
		var role_int: int = int(str(k_str))
		if shop_businesses.has(role_int) and typeof(saved_b[k_str]) == TYPE_DICTIONARY:
			var entry: Dictionary = saved_b[k_str]
			var biz: Dictionary = shop_businesses[role_int]
			biz["owner_mode"] = str(entry.get("owner_mode", "NPC"))
			biz["vault_gold"] = int(entry.get("vault_gold", 0))
			biz["sabotaged_days"] = int(entry.get("sabotaged_days", 0))
			biz["sabotaged_today_day"] = int(entry.get("sabotaged_today_day", -1))
			if entry.has("stock_override") and typeof(entry["stock_override"]) == TYPE_DICTIONARY:
				biz["stock_override"] = (entry["stock_override"] as Dictionary).duplicate()
				var holder: VillageNPC = trade_npcs.get(role_int)
				if is_instance_valid(holder) and not holder.is_dead:
					holder.shop_stock = (entry["stock_override"] as Dictionary).duplicate()
			_refresh_shop_stall_visual(role_int)

func spawn_dynamic_npc_from_save(node_name: String, npc_data: Dictionary) -> VillageNPC:
	if not is_instance_valid(entities_root):
		return null
	var existing := entities_root.get_node_or_null(node_name) as VillageNPC
	if is_instance_valid(existing):
		existing.from_save_dict(npc_data)
		return existing
	var dyn_npc := VillageNPC.new()
	dyn_npc.name = node_name
	dyn_npc.npc_name = str(npc_data.get("npc_name", "Aldeano"))
	dyn_npc.npc_role = str(npc_data.get("npc_role", "Habitante"))
	dyn_npc.trade_role = int(npc_data.get("trade_role", int(VillageNPC.TradeRole.UNEMPLOYED))) as VillageNPC.TradeRole
	dyn_npc.linked_trade = int(npc_data.get("linked_trade", int(dyn_npc.trade_role))) as VillageNPC.TradeRole
	dyn_npc.tavern_social_pos = _tavern_social_pos
	entities_root.add_child(dyn_npc)
	var default_tex := _load_tex("res://assests/world/village/villager_traveler.png")
	dyn_npc.setup_npc(
		default_tex,
		Vector2(float(npc_data.get("work_x", 440.0)), float(npc_data.get("work_y", 44.0))),
		Vector2(float(npc_data.get("bed_x", 435.0)), float(npc_data.get("bed_y", -252.0))),
		{},
		Vector2(float(npc_data.get("table_x", _tavern_social_pos.x)), float(npc_data.get("table_y", _tavern_social_pos.y))),
		str(npc_data.get("family_id", "none")),
		str(npc_data.get("family_name", "Independiente"))
	)
	dyn_npc.from_save_dict(npc_data)
	return dyn_npc

func reconcile_npc_registries_after_load() -> void:
	for camp_key in vagrant_camp_nodes.keys():
		var c_node: Node2D = vagrant_camp_nodes[camp_key]
		if is_instance_valid(c_node):
			c_node.visible = false
	trade_npcs.clear()
	family_npcs.clear()
	unemployed_npcs.clear()
	authority_npcs.clear()
	_innkeeper_npc = null
	_royal_investigator_npc = null
	_active_traveling_merchant = null
	for slot in _authority_slots:
		slot["npc"] = null
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.trade_role == VillageNPC.TradeRole.ROYAL_INVESTIGATOR and not v.is_dead and not str(v.name).begins_with("NPC_Royal_Investigator_Corpse_"):
				_royal_investigator_npc = v
			elif v.trade_role == VillageNPC.TradeRole.TRAVELING_MERCHANT and not v.is_dead and not str(v.name).begins_with("NPC_Merchant_Corpse_"):
				_active_traveling_merchant = v
			var r_int: int = int(v.trade_role)
			if r_int in [
				int(VillageNPC.TradeRole.BLACKSMITH),
				int(VillageNPC.TradeRole.BUTCHER),
				int(VillageNPC.TradeRole.CARPENTER),
				int(VillageNPC.TradeRole.FISHMONGER),
				int(VillageNPC.TradeRole.HERBALIST)
			] and not v.is_dead:
				trade_npcs[r_int] = v
			elif v.trade_role == VillageNPC.TradeRole.FAMILY_MEMBER and not v.is_dead:
				family_npcs[int(v.linked_trade)] = v
			elif v.trade_role == VillageNPC.TradeRole.UNEMPLOYED and not v.is_dead:
				unemployed_npcs.append(v)
			elif v.trade_role == VillageNPC.TradeRole.INNKEEPER and not v.is_dead:
				_innkeeper_npc = v
			elif v.trade_role in [VillageNPC.TradeRole.DOCTOR, VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD] and not v.is_dead:
				authority_npcs.append(v)
				for slot in _authority_slots:
					if int(slot.get("role", -1)) == r_int:
						slot["npc"] = v
						slot["rehire_timer"] = 0.0
						slot["vacancy_announced"] = false
			if v.is_vagrant_camper and not v.is_dead:
				_spawn_or_update_vagrant_camp_visual(v, v.vagrant_camp_pos)

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
	if _tex_cache.has(res_path):
		var cached: Variant = _tex_cache[res_path]
		if cached is Texture2D:
			return cached as Texture2D
	if ResourceLoader.exists(res_path):
		var t = load(res_path)
		if t is Texture2D:
			_tex_cache[res_path] = t
			return t
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img and not img.is_empty():
			var itex := ImageTexture.create_from_image(img)
			_tex_cache[res_path] = itex
			return itex
	return null
