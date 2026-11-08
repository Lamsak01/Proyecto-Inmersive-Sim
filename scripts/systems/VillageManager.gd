@tool
extends Node2D
class_name VillageManager

const VillageJustice = preload("res://scripts/systems/VillageJustice.gd")

const VillageSocialLife = preload("res://scripts/systems/VillageSocialLife.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageSecrets = preload("res://scripts/systems/VillageSecrets.gd")
const VillageDesires = preload("res://scripts/systems/VillageDesires.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageFaith = preload("res://scripts/systems/VillageFaith.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageIllness = preload("res://scripts/systems/VillageIllness.gd")
const VillageCrime = preload("res://scripts/systems/VillageCrime.gd")
const VillageTown = preload("res://scripts/systems/VillageTown.gd")
const VillageSect = preload("res://scripts/systems/VillageSect.gd")
const VillageQuests = preload("res://scripts/systems/VillageQuests.gd")

const VillageWorldBuilder = preload("res://scripts/systems/VillageWorldBuilder.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const VillageTrades = preload("res://scripts/systems/VillageTrades.gd")
const VillageCivic = preload("res://scripts/systems/VillageCivic.gd")
const VillageTavern = preload("res://scripts/systems/VillageTavern.gd") # Paso 3: Taberna El Jabalí Dorado (2 pisos)
const VillageRestaurant = preload("res://scripts/systems/VillageRestaurant.gd") # R1: Trattoria «Il Corvo»
const VillageFamilia = preload("res://scripts/systems/VillageFamilia.gd") # R2: La Familia (crimen organizado discreto)
const VillagePlaces = preload("res://scripts/systems/VillagePlaces.gd")
const VillageCulture = preload("res://scripts/systems/VillageCulture.gd")
const VillageMigration = preload("res://scripts/systems/VillageMigration.gd")
const VillageNobility = preload("res://scripts/systems/VillageNobility.gd")
const VillageFamily = preload("res://scripts/systems/VillageFamily.gd")
const VillageLoans = preload("res://scripts/systems/VillageLoans.gd")
const VillageWork = preload("res://scripts/systems/VillageWork.gd")
const VillageClans = preload("res://scripts/systems/VillageClans.gd")
const VillageForensics = preload("res://scripts/systems/VillageForensics.gd")
const VillageLineage = preload("res://scripts/systems/VillageLineage.gd")
const VillageConfession = preload("res://scripts/systems/VillageConfession.gd")
const VillageMayor = preload("res://scripts/systems/VillageMayor.gd")
const VillageCollections = preload("res://scripts/systems/VillageCollections.gd")
const VillageClub = preload("res://scripts/systems/VillageClub.gd")
const VillageNightJobs = preload("res://scripts/systems/VillageNightJobs.gd")
const VillageHousing = preload("res://scripts/systems/VillageHousing.gd")
const VillageUnderworld = preload("res://scripts/systems/VillageUnderworld.gd")
const VillageFame = preload("res://scripts/systems/VillageFame.gd")
const WorldStage3DScript = preload("res://scripts/visuals/WorldStage3D.gd")

## Gestor Integral de Urbanismo Sólido, Hospital/Morgue Forense, Comisaría/Cárcel, Testigos,
## Sigilo Doméstico, Reputación Familiar, Tablón de Encargos y Red Eléctrica (10 Pasos de Expansión)

var entities_root: Node = null
var world_stage_3d: Node2D = null

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
const PersonProfile = preload("res://scripts/data/PersonProfile.gd")
const NPCData = preload("res://scripts/data/NPCData.gd")
const SocialDirector = preload("res://scripts/systems/SocialDirector.gd")
var social_director: RefCounted = null
var _newcomer_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _used_first_names: Array = []
var _used_person_ids: Dictionary = {}
const MAX_SOCIAL_EVENT_LOG: int = 80
var social_event_log: Array[Dictionary] = []
## Crónica del pueblo (C): historia permanente de los últimos sucesos (ver `VillageChronicle.gd`).
var chronicle: Array[Dictionary] = []
## Escalón de amistad apuntado por cada vecino hacia cada otro («a>b»), para la crónica.
var chronicle_tiers: Dictionary = {}
## true mientras se procesa el cambio de día: lo que se apunte entonces pasó durante el día anterior.
var chronicle_daily: bool = false
## Secretos (S): aventuras y chantajes, ver `VillageSecrets.gd`.
var secrets: Array[Dictionary] = []
var secret_uid: int = 0
## Deseos propios (D): ver `VillageDesires.gd`.
var desires: Array[Dictionary] = []
var desire_uid: int = 0
var desire_hate_since: Dictionary = {} # clave del vecino -> día desde el que odia al jugador
var npc_murders: Dictionary = {} # nombre de la víctima -> nombre del asesino (para el comisario)
var last_npc_murder_day: int = -9999
## Grupos y fe (G): ver `VillageFaith.gd`. faith_state se guarda; los bandos se recalculan cada día.
var faith_state: Dictionary = {}
var faith_bands: Array = []
## Economía y necesidades (E): vicios, enfermedades, robos… ver `VillageNeeds.gd`. Se guarda.
var needs_state: Dictionary = {}
## Instituciones (I): alcalde, arcas, corrupción. Ver `VillageTown.gd`. Se guarda.
var town_state: Dictionary = {}
var lots_state: Dictionary = {} # V4: solares y obras (VillageLots)
@warning_ignore("unused_private_class_variable")
var _lot_visuals: Dictionary = {}
var places_state: Dictionary = {} # V5c: terceros espacios (contadores)
var culture_state: Dictionary = {} # V5e: biblioteca, mercado y arreglos
var migration_state: Dictionary = {} # V3: llegadas, marchas y atractivo del pueblo
var nobility_state: Dictionary = {} # V6: el señor del valle, los rentistas y las rentas
var family_state: Dictionary = {} # V9: embarazos, nacimientos, edades y escuela
var work_state: Dictionary = {} # V5d: jornaleros del día
## La secta secreta (O). Ver `VillageSect.gd`. Se guarda.
var sect_state: Dictionary = {}
var _needs_tick_acc: float = 0.0
var _social_event_uid: int = 0
var trade_configs: Dictionary = {}
var domestic_pets: Array[DomesticPet] = []

# Registro de Edificios con Paredes Sólidas y Puertas para Navegación y Testigos
var building_footprints: Array[Dictionary] = []
var _wall_occluder_rects: Array[Rect2] = []

# Paso 1: Hospital de Urgencias, Morgue Forense (Máx. 3 Camillas), Iglesia y Cementerio Parroquial
@warning_ignore("unused_private_class_variable") # Se usa desde otro script (vm._hospital_center)
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

# Capilla del Alba y Cementerio Parroquial (Sur del Hospital y la Comisaría)
@warning_ignore("unused_private_class_variable") # Se usa desde otro script (vm._church_center)
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
@warning_ignore("unused_private_class_variable") # Se usa desde otro script (vm._police_center)
var _police_center := Vector2(915, 148)
var _jail_cell_pos := Vector2(886, 172)
var wanted_level: int = 0
var bounty_gold: int = 0
var player_arrests_count: int = 0
var player_murder_warrants_count: int = 0
var player_in_jail: bool = false
var player_being_escorted_to_jail: bool = false
var escorting_officer: VillageNPC = null
var _escort_elapsed_timer: float = 0.0
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
@warning_ignore("unused_private_class_variable") # Se usa desde otro script (vm._jail_cell_gate_body)
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
var _tavern_well_label: Label = null
var _extra_station_labels: Array = [] # Bloque AB: [[Label, Vector2]] carteles de puestos añadidos luego (Pozo de la Ronda)
var _plaza_well_label: Label = null
var _compost_label: Label = null
var _compost_sprite: Sprite2D = null
var _compost_area: Area2D = null
var _tavern_bed_label: Label = null
var _tavern_games_label: Label = null
var _tavern_pool_label: Label = null

var _tavern_bed_pos := VillageTavern.PLAYER_BED_POS
var _tavern_social_pos := VillageTavern.SOCIAL_POS
var _tavern_games_pos := VillageTavern.GAMES_POS
var _tavern_pool_pos := VillageTavern.POOL_POS
var _well_pos := Vector2(184, 82)
var _tavern_well_pos := VillageTavern.WELL_POS
var _plaza_well_pos := Vector2(412, 54)
var _well_positions: Array[Vector2] = [Vector2(184, 82), VillageTavern.WELL_POS, Vector2(412, 54)]
var _compost_pos := Vector2(-706, -6)

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
var merchant_suspension_days: Dictionary = {"casimir": 0, "valeria": 0, "high_pass": 0, "river_port": 0, "sun_plain": 0} # Días de embargo comercial (20..30 mercaderes semanales / 7 caravanas P3) si asesinan a un mercader
var _active_traveling_merchant: VillageNPC = null
var _royal_investigator_npc: VillageNPC = null
var active_royal_investigation: Dictionary = {} # Expediente deductivo del Inquisidor Real Alistair
var active_sheriff_investigation: Dictionary = {} # Expediente deductivo local del Comisario Vane (máx. 5 eslabones)
var blood_puddles: Array[Dictionary] = [] # Charcos de sangre y rastro direccional de huellas ([{pos, victim_name, node, footprint_nodes, flee_dir, flee_compass}])
var business_panel: PanelContainer = null
var business_info_lbl: Label = null
var _biz_btn_1: Button = null
var _biz_btn_2: Button = null
var _biz_btn_3: Button = null
var _biz_btn_4: Button = null
var _active_business_role: int = -1

func get_poker_chair_positions() -> Array[Vector2]:
	return VillageTavern.POKER_CHAIRS.duplicate()

func set_camp_farm_enabled(en: bool) -> void:
	if is_instance_valid(_compost_sprite):
		_compost_sprite.visible = en
	if is_instance_valid(_compost_area):
		_compost_area.monitoring = en
		_compost_area.monitorable = en
	if not en and is_instance_valid(_compost_label):
		_compost_label.visible = false

func setup_village(target_entities_root: Node) -> void:
	entities_root = target_entities_root if target_entities_root else self
	var in_editor := Engine.is_editor_hint()
	set_process(not in_editor)
	set_process_unhandled_input(not in_editor)
	add_to_group("village_manager")

	for arr in [building_footprints, _wall_occluder_rects, house_chests, building_doors, building_windows, streetlights, _authority_slots, morgue_active_corpses, buried_graves, _cemetery_grave_positions, _cemetery_grave_nodes, blood_puddles, social_event_log]:
		arr.clear()
	active_sheriff_investigation.clear()
	shop_businesses.clear()
	vagrant_camp_nodes.clear()
	arrivals_today_count = 0
	_init_newcomer_generator_registries()
	social_director = SocialDirector.new(20261101)
	social_director.set_pair_metrics("elena", "valen", 78, 75, 80, 5, SocialDirector.STAGE_COUPLE)
	house_pantry = {
		"family_smith": 3, "family_butcher": 4, "family_carpenter": 3, "family_fishmonger": 4,
		"family_herbalist": 4, "family_hospital": 3, "family_police": 4, "family_tavern": 5
	}

	VillageWorldBuilder._spawn_village_roads_and_plaza(self)
	VillageWorldBuilder._spawn_western_plains_and_frog_marsh(self)
	VillageWorldBuilder._spawn_tavern_and_rooms(self)
	VillageWorldBuilder._spawn_five_family_houses_and_trades(self)
	VillageWorldBuilder._spawn_hospital_and_morgue(self)
	VillageWorldBuilder._spawn_police_station_and_jail(self)
	VillageWorldBuilder._spawn_church_and_cemetery(self)
	VillageWorldBuilder._spawn_notice_board_in_plaza(self)
	VillageWorldBuilder._spawn_electric_streetlights(self)
	_spawn_unemployed_tavern_guests()
	VillageWorldBuilder._spawn_farm_well_and_compost(self)
	VillageLots.reset_layout() # Bloque AB: solares en su sitio desplazado antes de que nadie los use
	VillageTrades.setup_world(self) # V5: panadería y sastrería (puestos vacantes al empezar)
	VillageTown.state(self) # J3: arcas iniciales (1000) en partida nueva
	VillageCivic.setup_world(self) # V5b: ayuntamiento, albergue y El Candil
	VillageRestaurant.setup_world(self) # R1: Trattoria «Il Corvo» (puesto vacante)
	VillageRestaurant.build(self) # R1: edificio grande con comedor, terraza, cocina, cámara, bodega y reservado
	VillageFamilia.spawn_initial_boss(self) # R2/R4: Don Vittorio Corvo empieza como jefe de La Familia desde el Día 0
	VillageCulture.ensure_lots(self) # V5e: biblioteca y escuela
	VillageNobility.ensure_lots(self) # V6: mansión y casa grande
	VillageLots.build_world(self) # V4: calles y solares del borde, afueras y lomas
	VillagePlaces.build_world(self) # V5c: parque, bancos de la plaza y mirador del lago
	VillageWork.build_world(self) # V5d: lavadero
	VillageUnderworld.build_sewers_world(self) # FIS3: trampillas en la calle y red de túneles conectada al sur
	VillageClub.build_world(self) # P6: trampilla tras la taberna y club de pelea en el sótano
	VillageHousing.sync_livestock(self) # FIS4: ganado vivo del rancho y animales propios del corral
	VillageHousing.sync_home_props(self) # FIS-P1 y P1: objetos físicos en tu casa y mostrador de tu tienda
	_spawn_domestic_pets()
	VillageSecrets.seed_founder_history(self) # B6: rasgos con variante, red de amistades/rencores y 2–3 secretos por fundador
	if not in_editor and DisplayServer.get_name() != "headless":
		VillageMigration.seed_start_population(self) # Provisional: arranque con 40 vecinos para probar (no en las pruebas)
		VillageTavern.seed_initial_patrons(self) # Paso 3: clientes sentados en el salón y partida de póker en curso al abrir la taberna
	else:
		VillageTavern.seed_initial_patrons(self)
	_prune_door_blocking_prop_colliders()
	if is_instance_valid(world_stage_3d):
		world_stage_3d.queue_free()
	world_stage_3d = WorldStage3DScript.new()
	add_child(world_stage_3d)
	world_stage_3d.setup_stage(self)

	if not in_editor:
		_setup_Interactive_modals_ui()
		if WorldClock:
			if not WorldClock.day_passed.is_connected(_on_day_passed):
				WorldClock.day_passed.connect(_on_day_passed)
			var qm_node = get_node_or_null("/root/QuestManager")
			if qm_node and not qm_node.quest_changed.is_connected(_on_quests_changed):
				qm_node.quest_changed.connect(_on_quests_changed)
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
	_titles_declutter_t -= delta
	if _titles_declutter_t <= 0.0:
		_titles_declutter_t = 0.25
		_declutter_title_labels()
	if _police_confront_cooldown > 0.0:
		_police_confront_cooldown -= delta
	_needs_tick_acc += delta
	if _needs_tick_acc >= 1.0:
		_needs_tick_acc = 0.0
		VillageNeeds.tick(self) # E: terminar encargos al llegar
	VillageTavern.tick(self, delta) # Paso 3: escalera al 2.º piso, mesa de póker viva y ambiente de taberna
	VillageClub.tick(self, delta) # P6: la pelea en curso en el club del sótano
	if social_director != null:
		social_director.tick(delta, self)
		_update_social_hangouts(delta)
		_update_live_fights(delta)

	if not is_instance_valid(_cached_player):
		_cached_player = get_tree().get_first_node_in_group("player") as Node2D
	var player := _cached_player
	var real_delta: float = delta / maxf(1.0, Engine.time_scale)
	check_elevation_exit(player)

	# Escolta física policial hacia la celda de la Comisaría (Estilo Kenshi / Red Dead Redemption 2)
	if player_being_escorted_to_jail and player:
		_escort_elapsed_timer += real_delta
		set_jail_cell_gate_locked(false)
		if is_instance_valid(escorting_officer) and not escorting_officer.is_dead and not escorting_officer.is_downed and not escorting_officer.is_stunned_flag and escorting_officer.sedated_timer <= 0.0:
			var follow_pos: Vector2 = escorting_officer.global_position + Vector2(-8, 6)
			if player.global_position.distance_to(escorting_officer.global_position) > 28.0:
				player.global_position = follow_pos
			else:
				player.global_position = player.global_position.move_toward(follow_pos, 96.0 * delta)
			if "velocity" in player:
				player.velocity = Vector2.ZERO
			if escorting_officer.global_position.distance_to(_jail_cell_pos) <= 26.0 or player.global_position.distance_to(_jail_cell_pos) <= 24.0 or _escort_elapsed_timer >= 9.5:
				complete_police_escort_to_jail(player)
		else:
			var nav_wp: Vector2 = get_navigation_waypoint(player.global_position, _jail_cell_pos, player)
			player.global_position = player.global_position.move_toward(nav_wp, 84.0 * delta)
			if player.global_position.distance_to(_jail_cell_pos) <= 24.0 or _escort_elapsed_timer >= 9.5:
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

	for st_lbl in [_tavern_bed_label, _tavern_games_label, _tavern_pool_label, _well_label, _tavern_well_label, _plaza_well_label, _compost_label, _hospital_bed_label, _morgue_label, _church_altar_label, _cemetery_label, _notice_board_label]:
		if is_instance_valid(st_lbl):
			st_lbl.visible = false
	for esl in _extra_station_labels:
		if is_instance_valid(esl[0]):
			(esl[0] as Label).visible = false
	for g_node in _cemetery_grave_nodes:
		if is_instance_valid(g_node):
			var g_lbl: Label = g_node.get_node_or_null("GraveHoverLabel") as Label
			if g_lbl:
				g_lbl.visible = _is_near(player, mouse_pos, g_node.global_position, 18.0, 14.0)
	if _jail_label:
		_jail_label.visible = player_in_jail or player_being_escorted_to_jail
		if _jail_label.visible:
			if player_being_escorted_to_jail:
				_jail_label.text = "🚔 Siendo escoltado a la celda..."
			elif player_in_jail and jail_mandatory_stay_timer > 0.0:
				_jail_label.text = "🔒 Celda — Espera %ds" % int(ceil(jail_mandatory_stay_timer))
			else:
				_jail_label.text = "🔒 Celda lista"
	for ch in house_chests:
		var c_lbl: Label = ch.get("label")
		if is_instance_valid(c_lbl):
			c_lbl.visible = false

	_update_shop_business_stalls(player, mouse_pos)
	_update_doors_and_windows(delta, player, mouse_pos)

func _is_near(player: Node2D, mouse_pos: Vector2, target_pos: Vector2, p_rad: float, m_rad: float) -> bool:
	return (player != null and player.global_position.distance_squared_to(target_pos) <= p_rad * p_rad) or (target_pos.distance_squared_to(mouse_pos) <= m_rad * m_rad)

func _unhandled_input(event: InputEvent) -> void:
	if business_panel and business_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			var player = get_tree().get_first_node_in_group("player") as Node2D
			match event.keycode:
				KEY_1: _on_business_action_1(player); get_viewport().set_input_as_handled()
				KEY_2: _on_business_action_2(player); get_viewport().set_input_as_handled()
				KEY_3: _on_business_action_3(player); get_viewport().set_input_as_handled()
				KEY_4: _on_business_action_4(player); get_viewport().set_input_as_handled()
				KEY_5, KEY_ESCAPE: business_panel.visible = false; get_viewport().set_input_as_handled()
		return
	if morgue_panel and morgue_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			var player = get_tree().get_first_node_in_group("player") as Node2D
			match event.keycode:
				KEY_0: _on_morgue_open_detective_autopsy(); get_viewport().set_input_as_handled()
				KEY_1: _on_morgue_loot_corpses(player); get_viewport().set_input_as_handled()
				KEY_2: _on_morgue_open_anatomy_panel(); get_viewport().set_input_as_handled()
				KEY_3, KEY_ESCAPE, KEY_ENTER, KEY_E: morgue_panel.visible = false; get_viewport().set_input_as_handled()
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
			match event.keycode:
				KEY_1: _on_police_serve_sentence(player); get_viewport().set_input_as_handled()
				KEY_2: pay_bounty_fine(player); get_viewport().set_input_as_handled()
				KEY_3: _on_police_jailbreak_or_resist(player); get_viewport().set_input_as_handled()
				KEY_4, KEY_ESCAPE: police_panel.visible = false; get_viewport().set_input_as_handled()
		return
	if board_panel and board_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			var player = get_tree().get_first_node_in_group("player") as Node2D
			match event.keycode:
				KEY_1, KEY_2, KEY_3: _complete_board_contract(player, event.keycode - KEY_0); get_viewport().set_input_as_handled()
				KEY_4, KEY_ESCAPE: board_panel.visible = false; get_viewport().set_input_as_handled()
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

# CONSTRUCCIÓN SÓLIDA DE EDIFICIOS CON TEXTURAS Y COLISIÓN (`StaticBody2D`)
func _construct_solid_building(
	b_id: String, b_title: String, center: Vector2, size: Vector2, door_on_south: bool,
	floor_tex_path: String, wall_h_path: String, wall_v_path: String,
	door_width: float = 42.0, door_offset_x: float = 0.0, title_color: Color = Color(0.96, 0.90, 0.68)
) -> void:
	var half := size * 0.5
	var rect := Rect2(center - half, size)
	var door_y: float = (center.y + half.y) if door_on_south else (center.y - half.y)
	var door_pos := Vector2(center.x + door_offset_x, door_y)

	building_footprints.append({
		"id": b_id, "title": b_title, "rect": rect, "door_pos": door_pos, "door_south": door_on_south
	})

	var floor_tex := _load_tex(floor_tex_path)
	if floor_tex:
		var f_rect := TextureRect.new()
		f_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		f_rect.texture = floor_tex
		f_rect.stretch_mode = TextureRect.STRETCH_TILE
		f_rect.position = rect.position
		f_rect.size = size
		f_rect.z_index = -2
		f_rect.set_meta("flat_2d_building_visual", true)
		entities_root.add_child(f_rect)

	var tex_h := _load_tex(wall_h_path)
	var tex_v := _load_tex(wall_v_path)
	var wall_t: float = 7.0

	_add_solid_wall_segment(Vector2(rect.position.x, center.y), Vector2(wall_t, size.y), tex_v)
	_add_solid_wall_segment(Vector2(rect.end.x, center.y), Vector2(wall_t, size.y), tex_v)

	var closed_y: float = (center.y - half.y) if door_on_south else (center.y + half.y)
	_add_solid_wall_segment(Vector2(center.x, closed_y), Vector2(size.x, wall_t), tex_h)

	var door_left_x: float = (center.x + door_offset_x) - door_width * 0.5
	var door_right_x: float = (center.x + door_offset_x) + door_width * 0.5
	var left_seg_w: float = maxf(8.0, door_left_x - rect.position.x)
	var right_seg_w: float = maxf(8.0, rect.end.x - door_right_x)

	_add_solid_wall_segment(Vector2(rect.position.x + left_seg_w * 0.5, door_y), Vector2(left_seg_w, wall_t), tex_h)
	_add_solid_wall_segment(Vector2(rect.end.x - right_seg_w * 0.5, door_y), Vector2(right_seg_w, wall_t), tex_h)

	_add_rect_poly(door_pos, Vector2(door_width * 0.5, 3.0), Color(0.72, 0.54, 0.30, 0.85), -2)
	_add_title_label(center + Vector2(-125, -half.y - 36.0), Vector2(250, 16), b_title, title_color, 8)
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

	var spr_closed := _add_sprite_prop(tex_door_closed, door_pos, Vector2(door_width / 42.0, 1.0), 3, true)
	var spr_open := _add_sprite_prop(tex_door_open, door_pos + Vector2(-door_width * 0.5 + 4.0, -15.0 if door_on_south else 15.0), Vector2.ONE, 2, false)

	_add_station_area("DoorArea_" + b_id, door_pos, 14.0, "building_door")
	var d_lbl := _make_station_label(door_pos + Vector2(-125, -26), "🚪 Puerta de %s" % b_title)
	entities_root.add_child(d_lbl)

	building_doors.append({
		"building_id": b_id, "building_title": b_title, "building_rect": rect, "pos": door_pos,
		"door_south": door_on_south, "width": door_width, "body": d_body, "col": d_col,
		"spr_closed": spr_closed, "spr_open": spr_open, "label": d_lbl,
		"occluder_rect": Rect2(door_pos - Vector2(door_width * 0.5, 4.0), Vector2(door_width, 8.0)),
		"is_open": false, "is_locked": false, "locked_by_player": false,
		"manual_override_timer": 0.0, "npc_pass_timer": 0.0, "police_breach_timer": 0.0
	})

	var win_x: float = door_pos.x - door_width * 0.5 - 18.0
	if win_x < rect.position.x + 15.0:
		win_x = door_pos.x + door_width * 0.5 + 18.0
	var win_pos := Vector2(clampf(win_x, rect.position.x + 14.0, rect.end.x - 14.0), door_pos.y)
	var spr_win := _add_sprite_prop(tex_win_open, win_pos, Vector2.ONE, 3)

	_add_station_area("WindowArea_" + b_id, win_pos, 11.0, "building_window")
	var w_lbl := _make_station_label(win_pos + Vector2(-125, -24), "🪟 Ventana de %s" % b_title)
	entities_root.add_child(w_lbl)

	building_windows.append({
		"building_id": b_id, "building_title": b_title, "building_rect": rect, "pos": win_pos,
		"door_south": door_on_south, "sprite": spr_win, "label": w_lbl,
		"is_shuttered": false, "manual_override_timer": 0.0
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
		var tex_rect := TextureRect.new()
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.texture = tex
		tex_rect.stretch_mode = TextureRect.STRETCH_TILE
		tex_rect.position = -sz * 0.5
		tex_rect.size = sz
		tex_rect.z_index = 2
		sb.add_child(tex_rect)
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
	var top_r := Vector2(r.end.x, r.position.y)
	var br := r.end
	var bl := Vector2(r.position.x, r.end.y)
	if Geometry2D.segment_intersects_segment(p1, p2, tl, top_r) != null:
		return true
	if Geometry2D.segment_intersects_segment(p1, p2, top_r, br) != null:
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
	if agent != null and "elevation_level" in agent and int(agent.elevation_level) == -1:
		var club_rect := Rect2(VillageClub.CLUB_CENTER - VillageClub.CLUB_SIZE * 0.5, VillageClub.CLUB_SIZE).grow(12.0)
		var stay_in_club: bool = club_rect.has_point(to_pos) and (("errand_kind" in agent and str(agent.errand_kind) == "club_watch") or agent.get_meta("club_bout", false) == true)
		if stay_in_club:
			return to_pos
		if from_pos.distance_to(VillageClub.LADDER_POS) > 10.0:
			return VillageClub.LADDER_POS
		agent.global_position = VillageClub.TRAPDOOR_POS + Vector2(0.0, 8.0)
		if agent is VillageNPC:
			set_npc_elevation_level(agent as VillageNPC, 0)
		else:
			agent.set("elevation_level", 0)
		from_pos = agent.global_position

	var lane_shift: float = 0.0
	if agent != null:
		lane_shift = float((abs(agent.name.hash()) % 5) - 2) * 1.5

	# PASADA 1: Si el origen está dentro (o en el umbral de la puerta) de un edificio y el destino está fuera de él,
	# primero salir limpiamente por los tabiques internos y el pasillo de la puerta de ese edificio.
	for b in building_footprints:
		var r_building_check: Rect2 = b["rect"].grow(2.5)
		var r_interior: Rect2 = b["rect"].grow(1.5)
		var d_pos: Vector2 = b["door_pos"]
		var door_south: bool = bool(b["door_south"])
		var r_door_threshold := Rect2(d_pos - Vector2(16.0, 14.0 if door_south else 16.5), Vector2(32.0, 30.5))
		if (r_interior.has_point(from_pos) or r_door_threshold.has_point(from_pos)) and not r_building_check.has_point(to_pos):
			var b_id: String = str(b.get("id", ""))
			var lane_x: float = d_pos.x + lane_shift
			var inside_pt := Vector2(lane_x, d_pos.y + (-15.0 if door_south else 15.0))
			var outside_pt := Vector2(lane_x, d_pos.y + (20.0 if door_south else -20.0))

			# Primero salvar cualquier tabique interno hacia la antesala de la puerta principal
			var part_wp: Vector2 = _route_internal_building_partitions(b_id, from_pos, inside_pt, agent)
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
				return _route_internal_building_partitions(b_id, from_pos, safe_to_pos, agent)

	# PASADA 3: Navegación exterior esquivando edificios intermedios
	return _avoid_outdoor_buildings(from_pos, to_pos, "")

func _route_internal_building_partitions(b_id: String, from_pos: Vector2, target_pos: Vector2, agent: Node2D = null) -> Vector2:
	match b_id:
		"building_tavern":
			return VillageTavern.route(from_pos, target_pos, agent, self)
		"mixed_family_herbalist":
			if from_pos.y > 156.0 and target_pos.y < 162.0:
				return Vector2(325.0, 171.0 if absf(from_pos.x - 325.0) > 9.0 else 145.0)
			elif from_pos.y < 162.0 and target_pos.y > 156.0:
				return Vector2(325.0, 145.0 if absf(from_pos.x - 325.0) > 9.0 else 171.0)
		"building_hospital":
			if from_pos.y < 149.0 and target_pos.y > 155.0:
				return Vector2(745.0, 138.0 if absf(from_pos.x - 745.0) > 10.0 else 165.0)
			elif from_pos.y > 155.0 and target_pos.y < 149.0:
				return Vector2(745.0, 165.0 if absf(from_pos.x - 745.0) > 10.0 else 138.0)
		"building_restaurant": # R1: varias salas; cruza por los pasos (ver VillageRestaurant.OPENINGS)
			return VillageRestaurant.route(from_pos, target_pos)
		"building_police":
			if from_pos.y < 149.0 and target_pos.y > 155.0:
				return Vector2(902.0, 138.0 if absf(from_pos.x - 902.0) > 9.0 else 165.0)
			elif from_pos.y > 155.0 and target_pos.y < 149.0:
				return Vector2(902.0, 165.0 if absf(from_pos.x - 902.0) > 9.0 else 138.0)
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
	for _step in range(3):
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
				var clamped_pt := Vector2(
					clampf(from_pos.x, r_avoid.position.x, r_avoid.end.x),
					clampf(from_pos.y, r_avoid.position.y, r_avoid.end.y)
				)
				var d_closest: float = from_pos.distance_to(clamped_pt)
				if d_closest < closest_d:
					closest_d = d_closest
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

		var r_inner: Rect2 = merged_rect.grow(7.0)
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

func _register_authority_npc(node_name: String, npc_name_str: String, title: String, role: VillageNPC.TradeRole, tex_path: String, work_pos: Vector2, bed_pos: Vector2, table_pos: Vector2, stock: Dictionary, fam_id: String, fam_name: String, name_pool: Array) -> VillageNPC:
	var npc := VillageNPC.new()
	npc.name = node_name
	npc.npc_name = npc_name_str
	npc.npc_role = title
	npc.trade_role = role
	npc.tavern_social_pos = _tavern_social_pos
	entities_root.add_child(npc)
	npc.setup_npc(_load_tex(tex_path), work_pos, bed_pos, stock.duplicate(), table_pos, fam_id, fam_name)
	authority_npcs.append(npc)
	trade_npcs[int(role)] = npc
	_authority_slots.append({
		"role": role, "npc": npc, "rehire_timer": 0.0, "vacancy_announced": false,
		"work_pos": work_pos, "bed_pos": bed_pos, "table_pos": table_pos,
		"tex_path": tex_path, "stock": stock.duplicate(),
		"family_id": fam_id, "family_name": fam_name, "title": title, "name_pool": name_pool
	})
	return npc

## Devuelve la coordenada exacta en el borde del mapa (Camino Oeste `Vector2(-900, 48)` o Camino Este `Vector2(990, 48)`)
## desde la que cualquier nuevo habitante entra caminando físicamente al pueblo (Prohibido el respawn instantáneo en mitad de la calle).
func _get_map_edge_arrival_pos(index: int = 0) -> Vector2:
	if index % 2 == 0:
		return Vector2(-900.0, 48.0 + float((index % 3) - 1) * 6.0)
	return Vector2(990.0, 48.0 + float((index % 3) - 1) * 6.0)

func _check_authority_vacancy_announcements() -> void:
	for slot in _authority_slots:
		var cur_npc: VillageNPC = slot.get("npc")
		if is_instance_valid(cur_npc) and not cur_npc.is_dead:
			continue
		if not bool(slot.get("vacancy_announced", false)):
			slot["vacancy_announced"] = true
			_hint_player("📢 Vacante en el Valle: %s ha muerto. Un reemplazo novato llegará caminando desde el borde del mapa en los próximos días (Máx. %d llegadas/día)." % [str(slot["title"]), MAX_DAILY_ARRIVALS])

func _spawn_authority_replacement(slot: Dictionary) -> VillageNPC:
	var stock_copy: Dictionary = (slot.get("stock", {}) as Dictionary).duplicate()
	var new_npc: VillageNPC = _spawn_generated_newcomer(
		"NPC_Rehired_",
		int(slot["role"]) as VillageNPC.TradeRole,
		int(slot["role"]) as VillageNPC.TradeRole,
		str(slot["title"]) + " (Recién Llegado)",
		_load_tex(str(slot["tex_path"])),
		slot["work_pos"],
		slot["bed_pos"],
		stock_copy,
		slot.get("table_pos", _tavern_social_pos),
		str(slot["family_id"]),
		str(slot["family_name"])
	)
	slot["npc"] = new_npc
	slot["rehire_timer"] = 0.0
	slot["vacancy_announced"] = false
	authority_npcs.append(new_npc)
	trade_npcs[int(slot["role"])] = new_npc
	var dest_b: String = "Hospital" if slot["role"] == VillageNPC.TradeRole.DOCTOR else ("Capilla del Alba" if slot["role"] == VillageNPC.TradeRole.PRIEST else "Comisaría")
	var icon_b: String = "🏥🚶" if slot["role"] == VillageNPC.TradeRole.DOCTOR else ("☀️🚶" if slot["role"] == VillageNPC.TradeRole.PRIEST else "🚓🚶")
	_hint_player("%s %s (%s · Novato 35%%) está entrando al valle por el camino principal hacia el/la %s." % [icon_b, new_npc.npc_name, str(slot["title"]), dest_b])
	return new_npc

func _init_newcomer_generator_registries() -> void:
	_used_first_names.clear()
	_used_person_ids.clear()
	if _newcomer_rng.seed == 0:
		_newcomer_rng.seed = 20261101
	for k in NPCData.INITIAL_PERSON_PROFILES.keys():
		var nm: String = str(k)
		var parts: PackedStringArray = nm.split(" ", false)
		var first_tok: String = parts[parts.size() - 1] if parts.size() > 1 and (parts[0] in ["Dr.", "Dra.", "Comisario", "Comisaria", "Guardia", "Maese", "Hermano", "Hermana"]) else parts[0]
		_used_first_names.append(first_tok)
		var prof_d: Dictionary = NPCData.INITIAL_PERSON_PROFILES[k]
		var pid: String = str(prof_d.get("person_id", ""))
		if pid != "":
			_used_person_ids[pid] = true

func _count_living_genders() -> Vector2i:
	var fem: int = 0
	var male: int = 0
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC and not n.is_dead and n.trade_role not in [VillageNPC.TradeRole.TRAVELING_MERCHANT, VillageNPC.TradeRole.ROYAL_INVESTIGATOR]:
				var g: String = str(n.person_profile.gender) if n.person_profile != null else ("F" if n.npc_name.ends_with("a") else "M")
				if g == "F":
					fem += 1
				else:
					male += 1
	if fem == 0 and male == 0:
		return Vector2i(6, 11)
	return Vector2i(fem, male)

## Paso único para crear cualquier vecino nuevo (autoridades, posadera, artesano, viajero o encargado contratado).
func _spawn_generated_newcomer(
	node_prefix: String,
	role: VillageNPC.TradeRole,
	linked_role: VillageNPC.TradeRole,
	role_label: String,
	tex: Texture2D,
	work_pos: Vector2,
	bed_pos: Vector2,
	stock: Dictionary,
	table_pos: Vector2,
	fam_id: String,
	fam_name: String
) -> VillageNPC:
	_rehire_counter += 1
	var counts: Vector2i = _count_living_genders()
	var gen: Dictionary = PersonProfile.generate_newcomer(
		int(role), _rehire_counter, _newcomer_rng, _used_first_names, _used_person_ids, counts.x, counts.y
	)
	var prof = gen["profile"]
	var full_name: String = str(gen["full_name"])
	var new_npc := VillageNPC.new()
	new_npc.name = "%s%d_%s" % [node_prefix, _rehire_counter, str(gen["first_name"]).replace(" ", "_")]
	new_npc.npc_name = full_name
	new_npc.npc_role = role_label
	new_npc.trade_role = role
	new_npc.linked_trade = linked_role
	new_npc.days_in_role = 0
	new_npc.tavern_social_pos = _tavern_social_pos
	new_npc.person_profile = prof
	entities_root.add_child(new_npc)
	new_npc.setup_npc(tex, work_pos, bed_pos, stock, table_pos, fam_id, fam_name)
	new_npc.global_position = _get_map_edge_arrival_pos(_rehire_counter)
	record_social_event("arrival", new_npc, null, "%s llegó al valle (%s)" % [new_npc.npc_name, role_label])
	return new_npc

## B0.6: Registra un evento social relevante (base de "Noticias del pueblo" y chismes entre vecinos) con tope de memoria.
func record_social_event(type_str: String, actor: VillageNPC, target: VillageNPC = null, summary_str: String = "") -> Dictionary:
	var a_id: String = ""
	var a_name: String = ""
	if is_instance_valid(actor):
		a_id = str(actor.person_profile.person_id) if actor.person_profile != null and str(actor.person_profile.person_id) != "" else actor.npc_id
		a_name = actor.npc_name
	var t_id: String = ""
	var t_name: String = ""
	if is_instance_valid(target):
		t_id = str(target.person_profile.person_id) if target.person_profile != null and str(target.person_profile.person_id) != "" else target.npc_id
		t_name = target.npc_name
	var entry: Dictionary = {
		"day": WorldClock.current_day if WorldClock else 1,
		"hour": WorldClock.current_hour if WorldClock else 12,
		"minute": WorldClock.current_minute if WorldClock else 0,
		"type": type_str,
		"actor_id": a_id,
		"actor_name": a_name,
		"target_id": t_id,
		"target_name": t_name,
		"summary": summary_str,
		"uid": _social_event_uid,
	}
	_social_event_uid += 1
	if type_str in GOSSIP_EVENT_TYPES:
		# B6.1: Al principio solo lo saben sus protagonistas; lo que el jugador dijo a escondidas no lo sabe el aludido
		entry["known_by"] = {a_id: true}
		if t_id != "" and not type_str in ["player_slander", "npc_slander"]:
			entry["known_by"][t_id] = true
		# Q3: de quién oyó cada uno el chisme, para poder seguir la pista hasta el origen
		entry["heard_from"] = {a_id: "player"} if type_str == "player_slander" else {}
	social_event_log.append(entry)
	VillageChronicle.on_social_event(self, entry, actor, target)
	VillageFaith.on_social_event(self, entry, actor, target) # G4: los bandos defienden a los suyos
	while social_event_log.size() > MAX_SOCIAL_EVENT_LOG:
		social_event_log.remove_at(0)
	return entry

## B6.1: Eventos que merecen chisme. Son solo información: no mueven relaciones entre vecinos.
const GOSSIP_EVENT_TYPES: Array[String] = ["fight", "breakup", "couple", "couple_reconciled", "feud", "reconciliation", "player_slander", "npc_slander", "rejection",
	"date", "romance_flirt", "romance_dating", "jealousy", "arrival", "departure", "affair_forgiven", "theft", "theft_caught", "embezzle", "police_bribe", "sect_rumor", "sect_night", "familia_rumor"] # R5: más cosas de las que hablar # Sin "widowed": revelaría muertes aún sin descubrir
const GOSSIP_MAX_AGE_DAYS: int = 20 # R1: tope; antes lo decide la memoria de cada vecino (GossipMemory)
const NEWS_MIN_KNOWERS: int = 3

func _get_live_gossip() -> Array[Dictionary]:
	return VillageSocialLife._get_live_gossip(self)

func spread_gossip(teller: VillageNPC, listener: VillageNPC) -> Dictionary:
	return VillageSocialLife.spread_gossip(self, teller, listener)

func try_npc_slander(speaker: VillageNPC, listener: VillageNPC, chance: float = -1.0) -> Dictionary:
	return VillageSocialLife.try_npc_slander(self, speaker, listener, chance)

func gossip_text(ev: Dictionary, listener: VillageNPC = null, ver_key: String = "") -> String:
	return VillageSocialLife.gossip_text(ev, listener, ver_key)

func get_news_known_by(npc: VillageNPC, limit: int = 3) -> Array[Dictionary]:
	return VillageSocialLife.get_news_known_by(self, npc, limit)

func get_public_news(limit: int = 4) -> Array[Dictionary]:
	return VillageSocialLife.get_public_news(self, limit)

## Devuelve los eventos sociales más recientes (del más nuevo al más antiguo), con filtro opcional por tipo o vecino.
func get_recent_social_events(limit: int = 15, filter_type: String = "", person_id_or_name: String = "") -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	var p_clean: String = person_id_or_name.strip_edges()
	var i: int = social_event_log.size() - 1
	while i >= 0 and res.size() < limit:
		var ev: Dictionary = social_event_log[i]
		i -= 1
		if filter_type != "" and str(ev.get("type", "")) != filter_type:
			continue
		if p_clean != "":
			var match_p: bool = (
				str(ev.get("actor_id", "")) == p_clean or
				str(ev.get("target_id", "")) == p_clean or
				str(ev.get("actor_name", "")) == p_clean or
				str(ev.get("target_name", "")) == p_clean
			)
			if not match_p:
				continue
		res.append(ev)
	return res

## Indica si queda al menos 1 de las 3 camillas de acero libres en la Morgue del Hospital (`MAX_MORGUE_CAPACITY = 3`),
## o si algún cuerpo en la Morgue ya tiene su caso resuelto/archivado y puede pasar al Cementerio para ceder la camilla
func has_free_morgue_table() -> bool:
	if morgue_active_corpses.size() < MAX_MORGUE_CAPACITY:
		return true
	for rec in morgue_active_corpses:
		if not _is_corpse_under_active_investigation(str(rec.get("victim_name", ""))):
			return true
	return false

func _find_corpse_npc_by_name(target_name: String) -> VillageNPC:
	if target_name == "":
		return null
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.is_dead and v.npc_name == target_name:
				return v
	return null

## Devuelve `true` mientras el caso de homicidio de este cadáver siga abierto (sin resolverse ni archivarse)
func _is_corpse_under_active_investigation(victim_name: String) -> bool:
	if victim_name == "":
		return false
	if bool(active_royal_investigation.get("active", false)):
		var r_stg: String = str(active_royal_investigation.get("stage", ""))
		if str(active_royal_investigation.get("victim_name", "")) == victim_name and r_stg != "DEPARTING":
			return true
	if bool(active_sheriff_investigation.get("active", false)):
		if str(active_sheriff_investigation.get("victim_name", "")) == victim_name:
			return true
	for rec in morgue_active_corpses:
		if str(rec.get("victim_name", "")) == victim_name and rec.has("case_resolved") and not bool(rec.get("case_resolved", true)):
			return true
	return false

func _mark_morgue_case_resolved(victim_name: String, resolution_note: String = "") -> void:
	if victim_name == "":
		return
	var cur_d: int = WorldClock.current_day if WorldClock else 1
	var cur_h: int = WorldClock.current_hour if WorldClock else 12
	var cur_tot_h: int = cur_d * 24 + cur_h
	VillageQuests.on_case_resolved(self, victim_name, resolution_note)
	VillageClans.on_murder_resolved(self, victim_name, resolution_note)
	VillageChronicle.add(self, "case_closed", "Se cerró el caso de la muerte de %s%s" % [victim_name, (": " + resolution_note) if resolution_note != "" else ""], true)
	for rec in morgue_active_corpses:
		if str(rec.get("victim_name", "")) == victim_name:
			rec["case_resolved"] = true
			rec["added_total_hours"] = cur_tot_h
			if resolution_note != "":
				rec["suspect"] = resolution_note
	for rec2 in corpse_records:
		if str(rec2.get("victim_name", "")) == victim_name:
			rec2["case_resolved"] = true
			if resolution_note != "":
				rec2["suspect"] = resolution_note

## Devuelve la posición a la que se llevan los cadáveres cuando las 3 camillas de la Morgue están llenas
func get_cemetery_burial_target_pos() -> Vector2:
	var next_idx: int = buried_graves.size()
	if next_idx >= 0 and next_idx < _cemetery_grave_positions.size():
		return _cemetery_grave_positions[next_idx]
	return _cemetery_burial_pos

## B3.4: Devuelve la posición de la tumba de un difunto en el cementerio (o la puerta del cementerio si aún está en la morgue).
func get_grave_pos_for_victim(victim_name_str: String) -> Vector2:
	var clean: String = victim_name_str.strip_edges()
	for rec in buried_graves:
		if typeof(rec) == TYPE_DICTIONARY and str(rec.get("victim_name", "")).strip_edges() == clean:
			var g_idx: int = int(rec.get("grave_index", -1))
			if g_idx >= 0 and g_idx < _cemetery_grave_positions.size():
				return _cemetery_grave_positions[g_idx] + Vector2(0, 10)
			return _cemetery_burial_pos
	return _cemetery_gate_pos

func _refresh_morgue_table_sprites() -> void:
	for i in range(_morgue_corpse_sprites.size()):
		if is_instance_valid(_morgue_corpse_sprites[i]):
			_morgue_corpse_sprites[i].visible = (i < morgue_active_corpses.size())
	for i in range(morgue_active_corpses.size()):
		if i < _morgue_table_positions.size():
			var v_name: String = str(morgue_active_corpses[i].get("victim_name", ""))
			var c_node: VillageNPC = _find_corpse_npc_by_name(v_name)
			if is_instance_valid(c_node):
				c_node.corpse_on_ground = false
				c_node.corpse_in_morgue = true
				c_node.corpse_buried = false
				c_node.global_position = _morgue_table_positions[i]
				if c_node.sprite:
					c_node.sprite.visible = false
				c_node._set_area_col_disabled(c_node.interact_area, false)

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
	var c_node: VillageNPC = _find_corpse_npc_by_name(str(rec.get("victim_name", "")))
	if is_instance_valid(c_node):
		c_node.corpse_buried = true
		c_node.corpse_in_morgue = true
		c_node.corpse_on_ground = false
		if c_node.status_label:
			c_node.status_label.visible = false
		if c_node.sprite:
			c_node.sprite.visible = false
		c_node._set_area_col_disabled(c_node.interact_area, true)
	_spawn_physical_grave_marker(grave_idx, rec)

func _spawn_physical_grave_marker(grave_idx: int, rec: Dictionary) -> void:
	if not is_instance_valid(entities_root):
		return
	var g_pos: Vector2 = _cemetery_burial_pos
	if grave_idx >= 0 and grave_idx < _cemetery_grave_positions.size():
		g_pos = _cemetery_grave_positions[grave_idx]
	else:
		g_pos = Vector2(844.0 + float(grave_idx % 6) * 26.0, 282.0 + float(int(float(grave_idx) / 6.0) % 3) * 28.0)

	var grave_node := Node2D.new()
	grave_node.name = "GraveMarker_%d" % (grave_idx + 1)
	grave_node.global_position = g_pos
	entities_root.add_child(grave_node)
	_cemetery_grave_nodes.append(grave_node)

	_add_poly(PackedVector2Array([Vector2(-7, -2), Vector2(7, -2), Vector2(8, 10), Vector2(-8, 10)]), Color(0.36, 0.25, 0.16, 0.95), -1, Vector2.ZERO, grave_node)
	_add_poly(PackedVector2Array([Vector2(-6, -11), Vector2(-4, -14), Vector2(4, -14), Vector2(6, -11), Vector2(6, -2), Vector2(-6, -2)]), Color(0.68, 0.72, 0.78, 1.0), 0, Vector2.ZERO, grave_node)
	_add_poly(PackedVector2Array([Vector2(-1, -12), Vector2(1, -12), Vector2(1, -4), Vector2(-1, -4)]), Color(0.32, 0.35, 0.40, 1.0), 1, Vector2.ZERO, grave_node)
	_add_poly(PackedVector2Array([Vector2(-3, -10), Vector2(3, -10), Vector2(3, -8), Vector2(-3, -8)]), Color(0.32, 0.35, 0.40, 1.0), 1, Vector2.ZERO, grave_node)

	var v_name: String = str(rec.get("victim_name", "Aldeano"))
	var v_role: String = str(rec.get("victim_role", "Habitante"))
	var v_cause: String = str(rec.get("cause_of_death", "Causa desconocida"))
	var b_day: int = int(rec.get("burial_day", 1))
	var g_lbl := _make_station_label(Vector2(-125, -34), "🪦 Tumba #%d: R.I.P. %s (%s)\n[Sepultado Día %d | %s | E: Libro de Difuntos]" % [grave_idx + 1, v_name, v_role, b_day, v_cause])
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
	var spr := _add_sprite_prop(_load_tex("res://assests/world/village/house_chest_closed.png"), pos, Vector2(1.05, 1.05), -1)
	_add_prop_collider(pos, Vector2(11.0, 8.0))
	_add_station_area("", pos, 15.0, "house_chest")
	var lbl := _make_station_label(pos + Vector2(-115, -24), "🔓 %s [E: Forzar Cerradura (Usa Sigilo [C])]" % chest_title)
	entities_root.add_child(lbl)
	house_chests.append({"pos": pos, "sprite": spr, "label": lbl, "title": chest_title, "family_id": fam_id, "looted_day": -1})

func _is_prop_collider_blocking_passage(pos: Vector2, sz: Vector2) -> bool:
	var prop_rect := Rect2(pos - sz * 0.5, sz)
	for d_entry in building_doors:
		var d_pos: Vector2 = d_entry.get("pos", Vector2.ZERO)
		if prop_rect.intersects(Rect2(d_pos - Vector2(22.0, 24.0), Vector2(44.0, 48.0))):
			return true
	for b in building_footprints:
		var d_pos2: Vector2 = b.get("door_pos", Vector2.ZERO)
		if prop_rect.intersects(Rect2(d_pos2 - Vector2(22.0, 24.0), Vector2(44.0, 48.0))):
			return true
	for op in VillageTavern.OPENINGS_FLOOR_0:
		var op_pos: Vector2 = op.get("pos", Vector2.ZERO)
		if prop_rect.intersects(Rect2(op_pos - Vector2(18.0, 18.0), Vector2(36.0, 36.0))):
			return true
	for op_r in VillageRestaurant.OPENINGS:
		var opr_pos: Vector2 = op_r.get("pos", Vector2.ZERO)
		if prop_rect.intersects(Rect2(opr_pos - Vector2(16.0, 16.0), Vector2(32.0, 32.0))):
			return true
	for p_gap in [Vector2(325.0, 158.0), Vector2(745.0, 152.0), Vector2(902.0, 152.0)]:
		if prop_rect.intersects(Rect2(p_gap - Vector2(16.0, 16.0), Vector2(32.0, 32.0))):
			return true
	return false

func _prune_door_blocking_prop_colliders() -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group("prop_collider"):
		if n is StaticBody2D and is_instance_valid(n):
			var sb := n as StaticBody2D
			var sz := Vector2(10.0, 10.0)
			for ch in sb.get_children():
				if ch is CollisionShape2D and ch.shape is RectangleShape2D:
					sz = (ch.shape as RectangleShape2D).size
			if _is_prop_collider_blocking_passage(sb.global_position, sz):
				sb.queue_free()

func _add_prop_collider(pos: Vector2, sz: Vector2, group_tag: String = "") -> StaticBody2D:
	if not is_instance_valid(entities_root) or sz.x <= 0.0 or sz.y <= 0.0:
		return null
	if _is_prop_collider_blocking_passage(pos, sz):
		return null
	var tag: String = group_tag
	if tag == "" and VillageTavern.RECT.has_point(pos):
		tag = "tavern_floor0_walls"
	var sb := StaticBody2D.new()
	sb.name = "PropCollider"
	sb.global_position = pos
	sb.collision_layer = 1 if tag != "tavern_upper_walls" else (1 if int(player_elevation_level) == 1 else 0)
	sb.collision_mask = 0
	sb.add_to_group("prop_collider")
	if tag != "":
		sb.add_to_group(tag)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = sz
	col.shape = rect
	sb.add_child(col)
	entities_root.add_child(sb)
	return sb

func _update_streetlights_glow() -> void:
	if Engine.is_editor_hint():
		return
	var is_night: bool = WorldClock != null and (WorldClock.current_hour >= 19 or WorldClock.current_hour < 6)
	var grid_on: bool = GameManager != null and bool(GameManager.get_flag("electric_grid_active", false)) and VillageCulture.is_lamps_powered(self)
	for sl in streetlights:
		var glow: Polygon2D = sl.get("glow")
		var spr: Sprite2D = sl.get("sprite")
		if is_instance_valid(glow):
			glow.visible = VillageCulture.is_lamps_powered(self) and (is_night or grid_on)
			glow.color = Color(0.55, 0.96, 1.0, 0.28) if grid_on else Color(1.0, 0.85, 0.45, 0.16)
		if is_instance_valid(spr):
			spr.modulate = Color(0.90, 1.08, 1.18) if grid_on else Color.WHITE

func _spawn_decor_prop(tex_path: String, pos: Vector2, sc: Vector2 = Vector2.ONE) -> void:
	var tex := _load_tex(tex_path)
	if not tex:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.global_position = pos
	spr.scale = sc
	spr.z_index = -1
	entities_root.add_child(spr)
	var fname: String = tex_path.get_file()
	var col_sz := Vector2.ZERO
	match fname:
		"round_table_0.png":
			col_sz = Vector2(22.0, 9.0)
		"table_chairs_0.png", "table_chairs_1.png":
			col_sz = Vector2(18.0, 10.0)
		"big_round_table_chairs_0.png":
			col_sz = Vector2(22.0, 16.0)
		"piano.png", "stove.png", "storage_countertop_0.png", "storage_countertop2_0.png", "drinks_shelf_0.png", "drinks_shelf_1.png", "fireplace_0.png", "stand-1_part5.png":
			col_sz = Vector2(16.0, 9.0)
		"bench_0.png":
			col_sz = Vector2(16.0, 7.0)
		"barrels3_0.png", "barrels_2.png", "crates_0.png", "crates_3.png", "hay_0.png", "hay_2.png", "logs_0.png":
			col_sz = Vector2(11.0, 8.0)
		"plants_3.png", "plants_5.png", "plants_8.png", "kitchen_props_3.png", "pots_pack_0.png":
			col_sz = Vector2(8.0, 8.0)
	if col_sz != Vector2.ZERO:
		_add_prop_collider(pos, col_sz)

func _add_station_area(area_name: String, pos: Vector2, radius: float, meta_tag: String) -> Area2D:
	var area := Area2D.new()
	if area_name != "":
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
	return area

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
		sighting_log.push_front({
			"building_id": str(entered_b.get("id", "")), "building_title": str(entered_b.get("title", "Edificio")),
			"witness_name": witness.npc_name, "action": action_verb, "hour": h, "minute": m, "day": d, "total_minutes": d * 1440 + h * 60 + m
		})
		while sighting_log.size() > 25:
			sighting_log.pop_back()

func _find_building_by_id(b_id: String) -> Dictionary:
	for b in building_footprints:
		if str(b.get("id", "")) == b_id:
			return b
	return {}

## Bloque PN: Sistema de niveles verticales por capas (-1 sótano/alcantarillas, 0 calle, 1 primer piso)
var player_elevation_level: int = 0

func are_on_same_elevation(level_a: int, level_b: int) -> bool:
	return level_a == level_b

func distance_on_same_level(pos_a: Vector2, level_a: int, pos_b: Vector2, level_b: int) -> float:
	if not are_on_same_elevation(level_a, level_b):
		return INF
	return pos_a.distance_to(pos_b)

## Punto donde el jugador cambió de piso: si se aleja de él (sale de casa), vuelve solo a la calle.
var _elevation_anchor: Vector2 = Vector2.INF
const ELEVATION_LEAVE_DIST: float = 70.0

func set_player_elevation_level(new_level: int) -> void:
	player_elevation_level = clampi(new_level, -1, 1)
	var pl_e: Node2D = get_tree().get_first_node_in_group("player") as Node2D if is_inside_tree() else null
	_elevation_anchor = pl_e.global_position if (pl_e != null and player_elevation_level != 0) else Vector2.INF
	if GameManager:
		GameManager.set_flag("player_elevation_level", player_elevation_level)
	_refresh_elevation_layer_visuals()

## Bloque PN: al alejarte del sitio donde cambiaste de piso (sales de casa), vuelves a la calle y los vecinos vuelven a verte.
## Bloque FIS3: dentro de la red de alcantarillas no salta la vuelta automática a la calle (solo se sube por las escalerillas).
func check_elevation_exit(player: Node2D) -> void:
	if VillageUnderworld.is_player_in_sewers(self) or VillageClub.is_player_in_club(self):
		return
	if player != null and player_elevation_level == 1 and VillageTavern.RECT.grow(14.0).has_point(player.global_position):
		return
	if player_elevation_level != 0 and player != null and _elevation_anchor != Vector2.INF and player.global_position.distance_to(_elevation_anchor) > ELEVATION_LEAVE_DIST:
		set_player_elevation_level(0)

func set_npc_elevation_level(npc: VillageNPC, new_level: int) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	npc.elevation_level = clampi(new_level, -1, 1)
	_refresh_elevation_layer_visuals()

func _refresh_elevation_layer_visuals() -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v: VillageNPC = n as VillageNPC
			var same_underground: bool = (int(v.elevation_level) == -1) == (int(player_elevation_level) == -1)
			if not same_underground:
				v.modulate.a = 0.0
			else:
				v.modulate.a = 1.0 if are_on_same_elevation(v.elevation_level, player_elevation_level) else 0.35
	VillageUnderworld.sync_sewer_visibility(self)
	VillageClub.sync_club_visibility(self)

func is_position_lit_by_lamp_or_lantern(pos: Vector2, ignore_entity: Node2D = null) -> bool:
	var hr: int = int(WorldClock.current_hour) if WorldClock else 12
	var gm = get_node_or_null("/root/GameManager")
	var grid_on: bool = gm != null and gm.get_flag("electric_grid_active", false) == true
	var lamps_lit: bool = VillageCulture.is_lamps_powered(self) and (hr >= 19 or hr < 7 or grid_on)
	if lamps_lit:
		for sl in streetlights:
			var spr: Sprite2D = sl.get("sprite")
			var sl_pos: Vector2 = spr.global_position if is_instance_valid(spr) else (sl.get("pos", Vector2.ZERO) as Vector2)
			if pos.distance_squared_to(sl_pos) <= 82.0 * 82.0:
				return true
	if hr >= 20 or hr < 7:
		var pl := get_tree().get_first_node_in_group("player") as Node2D if is_inside_tree() else null
		if is_instance_valid(pl) and pl != ignore_entity and pl.get("is_carrying_lantern") == true:
			if pos.distance_squared_to(pl.global_position) <= 62.0 * 62.0:
				return true
		if is_inside_tree():
			for n in get_tree().get_nodes_in_group("village_npcs"):
				if n is VillageNPC and n != ignore_entity:
					var v: VillageNPC = n as VillageNPC
					if v.is_carrying_lantern and pos.distance_squared_to(v.global_position) <= 58.0 * 58.0:
						return true
	return false

func get_ambient_vision_multiplier_at(pos: Vector2, ignore_entity: Node2D = null) -> float:
	var base_mult: float = float(WorldClock.call("get_weather_vision_multiplier")) if (WorldClock and WorldClock.has_method("get_weather_vision_multiplier")) else 1.0
	if WorldClock == null:
		return base_mult
	var hr: int = int(WorldClock.current_hour)
	var is_fog_or_night: bool = (hr >= 19 or hr < 7) or int(WorldClock.current_weather) == 2
	if not is_fog_or_night:
		return base_mult
	if is_position_lit_by_lamp_or_lantern(pos, ignore_entity):
		return maxf(base_mult, 0.92)
	if hr >= 0 and hr < 7:
		# B4.1: de madrugada la niebla nocturna recorta el alcance de la vista lejos de farolas y faroles
		return clampf(base_mult * 0.65, 0.22, 1.0)
	return base_mult

func _find_conscious_witness_near(pos: Vector2, max_dist: float, exclude_npc: VillageNPC, required_level: int = -999) -> VillageNPC:
	var best: VillageNPC = null
	var eff_dist: float = max_dist * get_ambient_vision_multiplier_at(pos, exclude_npc)
	var best_d2: float = eff_dist * eff_dist
	var target_level: int = required_level if required_level != -999 else (exclude_npc.elevation_level if exclude_npc != null else player_elevation_level)
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != exclude_npc:
			var v: VillageNPC = n as VillageNPC
			if v.is_dead or v.is_downed or v.is_sleeping or v.is_stunned_flag or v.sedated_timer > 0.0:
				continue
			if not are_on_same_elevation(v.elevation_level, target_level):
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
	if witness != null and witness.witness_silenced_player:
		witness = null
	var victim_officer_conscious: bool = victim.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR] and not victim.is_dead and not victim.is_downed and not victim.is_sleeping and not victim.is_stunned_flag and victim.sedated_timer <= 0.0
	# Si la víctima ya está muerta y quien lo vio es un civil (no un policía), NO hay alerta telepática inmediata:
	# el testigo primero examina el cuerpo 10s, va caminando en persona hasta la policía y pasa 12.5s explicándolo.
	if victim.is_dead and witness != null and not (witness.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR]):
		victim.murder_witness_name = witness.npc_name
		victim.begin_physical_corpse_discovery(witness)
		return
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
		_hint_player(msg)

## Se ejecuta cuando un aldeano termina de explicar físicamente a la policía que ha encontrado el cadáver de un civil (tras los 10s de examen + caminata + 12.5s de explicación)
func on_civilian_corpse_reported(victim: VillageNPC, death_pos: Vector2, weapon_name: String, discoverer_name: String = "") -> void:
	if not victim:
		return
	var mw: String = str(victim.murder_witness_name) if "murder_witness_name" in victim else ""
	if mw != "":
		var mw_npc: VillageNPC = _find_npc_by_name(mw)
		if mw_npc != null and mw_npc.witness_silenced_player:
			mw = ""
			victim.murder_witness_name = ""
	if victim.last_hit_by_player and mw != "":
		if not victim.has_meta("murder_warrant_issued"):
			victim.set_meta("murder_warrant_issued", true)
			wanted_level = clampi(wanted_level + 2, 1, 5)
			bounty_gold += 70
			player_murder_warrants_count += 1
			var msg := "🚓🚨 ¡%s declaró personalmente ante la policía que te vio asesinar a %s! (+70 Oro de multa)" % [mw, victim.npc_name]
			crime_history.push_front(msg)
			_notify_inquisitor_of_police_crime(msg, 45)
			_hint_player(msg)
	else:
		var d: int = victim.death_day if ("death_day" in victim and victim.death_day >= 1) else (WorldClock.current_day if WorldClock else 1)
		var h: int = victim.death_hour if ("death_hour" in victim and victim.death_hour >= 0) else (WorldClock.current_hour if WorldClock else 12)
		var m: int = victim.death_minute if ("death_minute" in victim and victim.death_minute >= 0) else (WorldClock.current_minute if WorldClock else 0)
		start_sheriff_investigation(victim, death_pos, weapon_name, discoverer_name, d * 1440 + h * 60 + m)

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
		_hint_player(msg)

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
		_hint_player(msg)

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
		var mw_check: String = str(victim.murder_witness_name) if "murder_witness_name" in victim else ""
		if mw_check != "":
			var mw_n: VillageNPC = _find_npc_by_name(mw_check)
			if mw_n != null and mw_n.witness_silenced_player:
				mw_check = ""
				victim.murder_witness_name = ""
		var had_direct_witness: bool = (mw_check != "")
		if had_direct_witness:
			var mw: String = mw_check
			witness_clue = "%s presenció el ataque directamente." % mw
			suspect_str = "Jugador (Testigo presencial: %s)" % mw
			if not victim.has_meta("murder_warrant_issued"):
				victim.set_meta("murder_warrant_issued", true)
				wanted_level = clampi(wanted_level + 2, 1, 5)
				bounty_gold += 70
				player_murder_warrants_count += 1
				_notify_inquisitor_of_police_crime("Orden de captura forense emitida: %s vio al Forastero asesinar a %s." % [mw, victim.npc_name], 45)
		elif crime_b_id != "":
			# 2. ¿Alguien vio al jugador entrar o salir de ese edificio cerca de la hora de la muerte (`sighting_log`)?
			for s_entry in sighting_log:
				var w_name: String = str(s_entry.get("witness_name", "Un vecino"))
				var w_node_chk: VillageNPC = _find_npc_by_name(w_name)
				if w_node_chk != null and w_node_chk.witness_silenced_player:
					continue
				if str(s_entry.get("building_id", "")) == crime_b_id and abs(death_mins - int(s_entry.get("total_minutes", 0))) <= 360:
					var s_h: int = int(s_entry.get("hour", h))
					var s_m: int = int(s_entry.get("minute", m))
					witness_clue = "%s vio al jugador %s %s a las %02d:%02d." % [w_name, str(s_entry.get("action", "entrar a")), crime_scene_name, s_h, s_m]
					suspect_str = "Jugador (Identificado por cruce forense + testigo %s)" % w_name
					wanted_level = clampi(wanted_level + 2, 1, 5)
					bounty_gold += 65
					player_murder_warrants_count += 1
					_notify_inquisitor_of_police_crime("Cruce forense en Morgue: %s situó al Forastero en el asesinato de %s." % [w_name, victim.npc_name], 38)
					break

	# Si el cadáver reportado/trasladado es un Mercader Viajero y aún no se había convocado al Inquisidor Real, convocarlo ahora
	if victim.trade_role == VillageNPC.TradeRole.TRAVELING_MERCHANT:
		on_traveling_merchant_murdered(victim, weapon_name)
	# Si el asesinato ocurrió sin testigo presencial directo del golpe, el Comisario Vane inicia una investigación en cadena (empezando por quien reportó el cuerpo)
	elif not suspect_str.begins_with("Jugador"):
		start_sheriff_investigation(victim, death_pos, weapon_name, finder_str, death_mins)

	var is_case_already_resolved: bool = suspect_str.begins_with("Jugador") and victim.trade_role != VillageNPC.TradeRole.TRAVELING_MERCHANT
	if VillageNPC.is_natural_death_cause(weapon_name) and not victim.last_hit_by_player: # J2: no es un crimen
		is_case_already_resolved = true
		suspect_str = "Sin crimen: %s" % VillageNPC.natural_death_text(weapon_name)
	var record: Dictionary = {
		"victim_name": victim.npc_name, "victim_role": victim.npc_role, "family_name": victim.family_name,
		"time_str": time_str, "crime_scene": crime_scene_name, "cause_of_death": weapon_name,
		"witness_clue": witness_clue, "suspect": suspect_str, "added_total_hours": added_total_hours,
		"death_pos_x": death_pos.x, "death_pos_y": death_pos.y, "discoverer_name": finder_str, "death_mins": death_mins,
		"case_resolved": is_case_already_resolved, "buried": false
	}
	corpse_records.push_front(record)

	if morgue_active_corpses.size() >= MAX_MORGUE_CAPACITY:
		for old_i in range(morgue_active_corpses.size()):
			var old_rec: Dictionary = morgue_active_corpses[old_i]
			if not _is_corpse_under_active_investigation(str(old_rec.get("victim_name", ""))):
				morgue_active_corpses.remove_at(old_i)
				_bury_corpse_in_cemetery(old_rec, "Traslado al Cementerio para liberar camilla forense")
				break

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
		_cross_check_morgue_and_police_records(_royal_investigator_npc, active_royal_investigation.get("suspects", {}), active_royal_investigation.get("clues_log", []))

	if buried_directly:
		_hint_player("🪦🚨 La Morgue está llena (3/3): %s fue sepultado en el Cementerio Parroquial. ¡%s! (Multa: %d Oro)." % [victim.npc_name, witness_clue, bounty_gold] if suspect_str.begins_with("Jugador") else "🪦⛪ La Morgue está llena (3/3 camillas): El cuerpo de %s fue sepultado directamente en el Cementerio de la Iglesia." % victim.npc_name)
	else:
		_hint_player("⚰️🚨 El cuerpo de %s fue trasladado a la Morgue (%d/3). ¡%s! Orden de arresto emitida (Multa: %d Oro)." % [victim.npc_name, morgue_active_corpses.size(), witness_clue, bounty_gold] if suspect_str.begins_with("Jugador") else "⚰️🕵️ El cuerpo de %s está en la Morgue Forense (%d/3 camillas): conserva sus pertenencias y permanecerá aquí hasta que se resuelva o archive el caso." % [victim.npc_name, morgue_active_corpses.size()])

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
func _build_modal_base(sz: Vector2, border_col: Color, font_sz: int, font_col: Color, center_align: bool = false, sep: int = 8) -> Dictionary:
	var panel := _create_styled_modal(sz, border_col)
	ui_layer.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", sep)
	panel.add_child(vbox)
	var lbl := Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if center_align:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_color", font_col)
	vbox.add_child(lbl)
	return {"panel": panel, "vbox": vbox, "lbl": lbl}

func _add_modal_btn(vbox: VBoxContainer, txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.pressed.connect(cb)
	vbox.add_child(b)
	return b

func _setup_Interactive_modals_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 32
	add_child(ui_layer)

	var m1 := _build_modal_base(Vector2(540, 325), Color(0.38, 0.85, 0.78), 11, Color(0.92, 0.98, 0.96))
	morgue_panel = m1["panel"]
	morgue_info_lbl = m1["lbl"]
	_add_modal_btn(m1["vbox"], "[0] 🔬 Mesa de Autopsias del Detective (Sangre, Cuello, Estómago, Piel)", func(): _on_morgue_open_detective_autopsy())
	_add_modal_btn(m1["vbox"], "[1] 💰 Saquear Bolsillos / Propiedades de los Cuerpos en la Morgue", func(): _on_morgue_loot_corpses(get_tree().get_first_node_in_group("player") as Node2D))
	_add_modal_btn(m1["vbox"], "[2] 🩺 Examen Anatómico / Bolsillos y Órganos en Camilla [H]", func(): _on_morgue_open_anatomy_panel())
	_add_modal_btn(m1["vbox"], "[3 / ESC] Cerrar Informe Forense de la Morgue", func(): morgue_panel.visible = false)

	var m2 := _build_modal_base(Vector2(470, 230), Color(0.42, 0.72, 1.0), 12, Color(0.95, 0.96, 1.0), true)
	police_panel = m2["panel"]
	police_info_lbl = m2["lbl"]
	_add_modal_btn(m2["vbox"], "[1] 🔒 Entregarse y cumplir condena en la Celda hasta las 06:00 AM (Limpia cargos)", func(): _on_police_serve_sentence(get_tree().get_first_node_in_group("player") as Node2D))
	_add_modal_btn(m2["vbox"], "[2] 💰 Pagar Fianza / Multa Policial en Oro para quedar libre", func(): pay_bounty_fine(get_tree().get_first_node_in_group("player") as Node2D))
	_add_modal_btn(m2["vbox"], "[3] 🔓 Forzar barrotes para fugarse (en Celda) / Resistirse", func(): _on_police_jailbreak_or_resist(get_tree().get_first_node_in_group("player") as Node2D))
	_add_modal_btn(m2["vbox"], "[4 / ESC] Cerrar", func(): police_panel.visible = false)

	var m3 := _build_modal_base(Vector2(490, 240), Color(0.92, 0.76, 0.36), 12, Color(1.0, 0.95, 0.80), true)
	board_panel = m3["panel"]
	board_info_lbl = m3["lbl"]
	_add_modal_btn(m3["vbox"], "[1] ⚒️ Encargo de Gremios: Entregar 2 Maderas o 1 Mineral Hierro (+28 Oro, +15 Afinidad)", func(): _complete_board_contract(get_tree().get_first_node_in_group("player") as Node2D, 1))
	_add_modal_btn(m3["vbox"], "[2] 🏥 Urgencia del Hospital: Entregar 2 Hierbas o 1 Cataplasma (+26 Oro, +15 Afinidad)", func(): _complete_board_contract(get_tree().get_first_node_in_group("player") as Node2D, 2))
	_add_modal_btn(m3["vbox"], "[3] 🚓 Cazarrecompensas: Entregar 1 Reliquia Bandido o 1 Ancas Rana (+34 Oro, -1 Cargo)", func(): _complete_board_contract(get_tree().get_first_node_in_group("player") as Node2D, 3))
	_add_modal_btn(m3["vbox"], "[4 / ESC] Cerrar Tablón", func(): board_panel.visible = false)

	var m4 := _build_modal_base(Vector2(540, 310), Color(0.96, 0.80, 0.32), 11, Color(1.0, 0.96, 0.84), false, 7)
	business_panel = m4["panel"]
	business_info_lbl = m4["lbl"]
	_biz_btn_1 = _add_modal_btn(m4["vbox"], "", func(): _on_business_action_1(get_tree().get_first_node_in_group("player") as Node2D))
	_biz_btn_2 = _add_modal_btn(m4["vbox"], "", func(): _on_business_action_2(get_tree().get_first_node_in_group("player") as Node2D))
	_biz_btn_3 = _add_modal_btn(m4["vbox"], "", func(): _on_business_action_3(get_tree().get_first_node_in_group("player") as Node2D))
	_biz_btn_4 = _add_modal_btn(m4["vbox"], "", func(): _on_business_action_4(get_tree().get_first_node_in_group("player") as Node2D))
	_add_modal_btn(m4["vbox"], "[5 / ESC] Cerrar Panel del Negocio", func(): business_panel.visible = false)

	var m5 := _build_modal_base(Vector2(520, 285), Color(0.82, 0.72, 0.96), 11, Color(0.95, 0.92, 1.0))
	church_panel = m5["panel"]
	church_info_lbl = m5["lbl"]
	_add_modal_btn(m5["vbox"], "[1] 🕯️ Encender Vela y Orar por los Difuntos (-5 Oro -> +Calma / +Reputación Vecinal)", func(): _on_church_pray_action(get_tree().get_first_node_in_group("player") as Node2D))
	_add_modal_btn(m5["vbox"], "[2 / ESC] Cerrar Libro Parroquial de Difuntos", func(): church_panel.visible = false)

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
		morgue_info_lbl.text = "⚰️ SALA DE AUTOPSIAS — MORGUE FORENSE DEL HOSPITAL (0/%d Camillas Ocupadas)\n\nLas 3 camillas de acero inoxidable están despejadas actualmente.%s\n\n(Los cuerpos en la Morgue conservan sus pertenencias y órganos, y permanecen en su camilla hasta que su caso se resuelva o se archive)." % [MAX_MORGUE_CAPACITY, buried_note]
	else:
		var lines: Array[String] = ["⚰️ CAMILLAS ACTIVAS DE LA MORGUE (%d/%d Ocupadas | %d Sepultados en Cementerio):" % [morgue_active_corpses.size(), MAX_MORGUE_CAPACITY, buried_graves.size()]]
		for i in range(morgue_active_corpses.size()):
			var rec: Dictionary = morgue_active_corpses[i]
			var v_name: String = str(rec.get("victim_name", ""))
			var c_node: VillageNPC = _find_corpse_npc_by_name(v_name)
			var pocket_txt: String = c_node.get_pocket_summary_text() if is_instance_valid(c_node) else "Bolsillos vacíos"
			var under_inv: bool = _is_corpse_under_active_investigation(v_name)
			var case_badge: String = "🔍 Caso Abierto (Permanece en Morgue hasta resolver/archivar)" if under_inv else "✅ Caso Resuelto/Archivado (Listo para sepultura)"
			lines.append("• Camilla #%d: %s (%s — %s) [%s]\n   🕒 %s | 📍 %s | 🗡️ Causa: %s\n   💰 Pertenencias en el cuerpo: %s\n   👁️ Pista: %s | ⚖️ Sospechoso: %s" % [
				i + 1, v_name, str(rec.get("victim_role", "")), str(rec.get("family_name", "")), case_badge,
				str(rec.get("time_str", "")), str(rec.get("crime_scene", "")), str(rec.get("cause_of_death", "")),
				pocket_txt, str(rec.get("witness_clue", "")), str(rec.get("suspect", ""))
			])
		morgue_info_lbl.text = "\n".join(lines)
	morgue_panel.visible = true

func _on_morgue_loot_corpses(player: Node2D) -> void:
	if not is_instance_valid(player) or morgue_active_corpses.is_empty():
		return
	var any_looted := false
	for rec in morgue_active_corpses:
		var c_node: VillageNPC = _find_corpse_npc_by_name(str(rec.get("victim_name", "")))
		if is_instance_valid(c_node) and c_node.loot_npc_pockets(player):
			any_looted = true
	if not any_looted:
		_msg_player(player, "⚰️ Los bolsillos de los cuerpos en la Morgue ya están vacíos (Usa [2] o [H] para cirugía/plantar pruebas)", Color.LIGHT_GRAY, -40.0)
	_open_morgue_autopsy_ui()

func _on_morgue_open_anatomy_panel() -> void:
	if morgue_active_corpses.is_empty():
		return
	var target_corpse: VillageNPC = null
	var p := get_tree().get_first_node_in_group("player") as Node2D
	var best_d2: float = INF
	for rec in morgue_active_corpses:
		var c_node: VillageNPC = _find_corpse_npc_by_name(str(rec.get("victim_name", "")))
		if is_instance_valid(c_node):
			var d2: float = p.global_position.distance_squared_to(c_node.global_position) if p else 0.0
			if d2 < best_d2:
				best_d2 = d2
				target_corpse = c_node
	if not is_instance_valid(target_corpse):
		return
	if morgue_panel:
		morgue_panel.visible = false
	var ui_root := get_tree().current_scene.get_node_or_null("UIRoot") if get_tree().current_scene else null
	if ui_root and "medical_panel" in ui_root and is_instance_valid(ui_root.medical_panel):
		ui_root.medical_panel.open_panel(target_corpse)

func _on_morgue_open_detective_autopsy() -> void:
	var target_corpse: VillageNPC = null
	var p := get_tree().get_first_node_in_group("player") as Node2D
	var best_d2: float = INF
	for rec in morgue_active_corpses:
		var c_node: VillageNPC = _find_corpse_npc_by_name(str(rec.get("victim_name", "")))
		if is_instance_valid(c_node):
			var d2: float = p.global_position.distance_squared_to(c_node.global_position) if p else 0.0
			if d2 < best_d2:
				best_d2 = d2
				target_corpse = c_node
	if morgue_panel:
		morgue_panel.visible = false
	var ui_root := get_tree().current_scene.get_node_or_null("UIRoot") if get_tree().current_scene else null
	if ui_root and "detective_ui" in ui_root and is_instance_valid(ui_root.detective_ui):
		ui_root.detective_ui.open_for_corpse(target_corpse, "morgue")

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
				int(g.get("grave_index", i)) + 1, str(g.get("victim_name", "")), str(g.get("victim_role", "")),
				str(g.get("family_name", "")), int(g.get("burial_day", 1)), str(g.get("cause_of_death", "")), str(g.get("burial_reason", "Sepultura parroquial"))
			])
	church_info_lbl.text = "\n".join(lines)
	church_panel.visible = true

func _on_church_pray_action(player: Node2D) -> void:
	if not player or not ("inventory" in player) or not player.inventory:
		return
	var inv: SimpleInventory = player.inventory
	if inv.gold < 5:
		_msg_player(player, "❌ Necesitas 5 Oro para la ofrenda de velas del altar", Color.ORANGE_RED, -42.0)
		return
	inv.add_gold(-5)
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if not v.is_dead and v.trade_role != VillageNPC.TradeRole.ROYAL_INVESTIGATOR:
				v.affinity = clampi(v.affinity + 3, -100, 100)
	_msg_player(player, "🕯️🙏 Encendiste una vela por los difuntos (-5 Oro, +3 Afinidad en el pueblo)", Color(0.95, 0.88, 1.0), -44.0)
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
	_escort_elapsed_timer = 0.0
	escorting_officer = chosen_officer
	clear_police_hostility()
	set_jail_cell_gate_locked(false)
	if police_panel:
		police_panel.visible = false
	if "velocity" in player:
		player.velocity = Vector2.ZERO
	if chosen_officer != null:
		chosen_officer.is_sleeping = false
		chosen_officer.sedated_timer = 0.0
		chosen_officer.is_stunned_flag = false
		if chosen_officer.body_col:
			chosen_officer.body_col.disabled = true
		if chosen_officer.health_comp:
			chosen_officer.health_comp.stop_bleeding()
			chosen_officer.health_comp.current_health = maxf(chosen_officer.health_comp.current_health, 28.0)
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
		_msg_player(player, "🔒⛓️ Encerrado en la Celda (%ds de estancia antes de usar el camastro)" % int(JAIL_MANDATORY_STAY_SECONDS), Color.SKY_BLUE, -46.0)
	_police_confront_cooldown = 0.0
	trigger_police_confrontation(null)

func capture_knocked_out_player_to_jail(player: Node2D) -> void:
	if player:
		start_police_escort_to_jail(player, _last_confronting_officer)

func send_player_to_jail(player: Node2D) -> void:
	if player:
		start_police_escort_to_jail(player, _last_confronting_officer)

func _on_police_serve_sentence(player: Node2D) -> void:
	if not player:
		return
	if not player_in_jail and not player_being_escorted_to_jail:
		start_police_escort_to_jail(player, _last_confronting_officer)
		return
	if player_being_escorted_to_jail:
		if police_panel:
			police_panel.visible = false
		_msg_player(player, "🚔⛓️ Espera a llegar a la celda con el guardia...", Color.GOLD, -42.0)
		return

	if jail_mandatory_stay_timer > 0.0:
		var wait_s: int = int(ceil(jail_mandatory_stay_timer))
		if police_info_lbl:
			police_info_lbl.text = "⏳🔒 AÚN NO PUEDES USAR EL CAMASTRO DE LA CELDA\nDebes permanecer %ds más en la celda antes de acostarte para cumplir tu pena.\n(También puedes pagar tu fianza [2] o forzar los barrotes [3])." % wait_s
		_msg_player(player, "⏳🔒 Espera %ds en la celda antes de acostarte en el camastro" % wait_s, Color.GOLD, -44.0)
		return

	if police_panel:
		police_panel.visible = false
	_msg_player(player, "🛏️⏩ Cumpliendo pena en el camastro: El mundo avanza orgánicamente hasta las 06:00 AM...", Color.AQUA, -46.0)
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
		var surv: SurvivalComponent = player.get_node_or_null("SurvivalComponent")
		if surv:
			surv.restore_sleep(85.0)
		_msg_player(player, "⚖️🔓 Condena cumplida (06:00 AM): Reja abierta, puedes salir caminando de la Comisaría", Color.SPRING_GREEN, -46.0)

func pay_bounty_fine(player: Node2D) -> void:
	if not player or not ("inventory" in player) or not player.inventory:
		return
	if bool(active_royal_investigation.get("active", false)) and str(active_royal_investigation.get("stage", "")) == "HUNTING_PLAYER" and not player_in_jail:
		_msg_player(player, "⚖️👑 Orden de Captura Real activa: debes entregarte en la Celda [1] antes de pagar fianza", Color.ORANGE_RED, -44.0)
		return
	var inv: SimpleInventory = player.inventory
	var fine: int = maxi(15, bounty_gold) if wanted_level > 0 else 0
	if fine <= 0 and not player_in_jail and not player_being_escorted_to_jail:
		if police_panel:
			police_panel.visible = false
		_msg_player(player, "✅ No tienes multas ni cargos pendientes", Color.SPRING_GREEN, -42.0)
		return
	var cost: int = maxi(15, fine)
	if inv.gold < cost:
		_msg_player(player, "❌ Necesitas %d Oro para pagar la fianza" % cost, Color.ORANGE_RED, -42.0)
		return
	inv.add_gold(-cost)
	town_state["treasury"] = int(town_state.get("treasury", 0)) + cost # Regla 1: la fianza va a las arcas
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
	_msg_player(player, "⚖️🔓 Fianza pagada (-%d Oro): Reja abierta, puedes salir caminando" % cost, Color.GOLD, -44.0)

func _on_police_jailbreak_or_resist(player: Node2D) -> void:
	if police_panel:
		police_panel.visible = false
	if not player:
		return
	if WorldClock and WorldClock.has_method("stop_organic_fast_forward") and WorldClock.is_fast_forwarding:
		WorldClock.stop_organic_fast_forward(false)
	if player_in_jail or player_being_escorted_to_jail:
		var was_in_cell: bool = player_in_jail
		player_in_jail = false
		player_being_escorted_to_jail = false
		escorting_officer = null
		jail_mandatory_stay_timer = 0.0
		set_jail_cell_gate_locked(false)
		var in_stealth_jb: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
		var has_master_pick: bool = player.has_method("has_master_lockpick") and bool(player.call("has_master_lockpick"))
		var stealth_sk_bonus: float = float(player.call("get_skill_bonus", "stealth")) if player.has_method("get_skill_bonus") else 0.0
		var detect_jb_rad: float = (58.0 if in_stealth_jb else 135.0) * (0.35 if has_master_pick else 1.0) * clampf(1.0 - stealth_sk_bonus, 0.40, 1.0)
		var gate_pos := Vector2(902, 152)
		var watching_officer: VillageNPC = null
		if was_in_cell:
			for n_off in get_tree().get_nodes_in_group("village_npcs"):
				if n_off is VillageNPC:
					var vo := n_off as VillageNPC
					if vo.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR] and vo.is_conscious():
						if vo.global_position.distance_to(gate_pos) <= detect_jb_rad and has_line_of_sight(vo.global_position, gate_pos):
							watching_officer = vo
							break
		if was_in_cell and watching_officer == null:
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🔓🤫 ¡Fuga sigilosa! Forzaste la reja de la celda sin despertar ni alertar a la guardia", Color.SPRING_GREEN, -46.0)
			_hint_player("🔓🤫 Has forzado la cerradura de la celda en completo silencio. Sal de la Comisaría sin que te vean.", player)
		else:
			wanted_level = clampi(wanted_level + 1, 2, 5)
			bounty_gold += 30
			alert_police_to_resist(player)
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🔓🔫 ¡Barrotes forzados! La guardia te vio escapar (+30 Oro de multa)", Color.ORANGE_RED, -46.0)
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
	var news: Array[Dictionary] = get_public_news()
	if not news.is_empty():
		board_info_lbl.text += "\n🗞️ NOTICIAS DEL PUEBLO"
		for ev in news:
			board_info_lbl.text += "\n• Día %d: %s" % [int(ev.get("day", 0)), str(ev.get("summary", ""))]
	board_panel.visible = true

func _complete_board_contract(player: Node2D, contract_idx: int) -> void:
	if not player or not ("inventory" in player) or not player.inventory:
		return
	var d: int = WorldClock.current_day if WorldClock else 1
	if int(completed_contracts_today.get(contract_idx, -1)) == d:
		_msg_player(player, "✅ Ya completaste este encargo hoy", Color.GOLD, -42.0)
		return
	var inv: SimpleInventory = player.inventory
	# Regla 1: los encargos del tablón los pagan las arcas municipales; si no llegan, hoy no se paga.
	var board_pay: int = {1: 28, 2: 26, 3: 34}.get(contract_idx, 0)
	if board_pay > 0 and int(town_state.get("treasury", 0)) < board_pay:
		_msg_player(player, "🏛️❌ Las arcas no pueden pagar este encargo hoy (%d Oro)" % board_pay, Color.ORANGE_RED, -42.0)
		return
	if contract_idx == 1:
		if inv.has_item("wood", 2): inv.remove_item("wood", 2)
		elif inv.has_item("iron_ore", 1): inv.remove_item("iron_ore", 1)
		else:
			_msg_player(player, "❌ Requiere 2 Maderas o 1 Mineral de Hierro", Color.ORANGE_RED, -42.0)
			return
		inv.add_gold(take_from_treasury(28))
		modify_family_reputation("family_carpenter", 15, "Encargo del tablón completado")
		modify_family_reputation("family_smith", 15, "Encargo del tablón completado")
		completed_contracts_today[1] = d
		_msg_player(player, "📋⚒️ ¡Encargo Artesanal completado! (+28 Oro, +15 Afinidad)", Color.SPRING_GREEN, -44.0)
	elif contract_idx == 2:
		if inv.has_item("herbs", 2): inv.remove_item("herbs", 2)
		elif inv.has_item("herbal_poultice", 1): inv.remove_item("herbal_poultice", 1)
		else:
			_msg_player(player, "❌ Requiere 2 Hierbas Medicinales o 1 Cataplasma", Color.ORANGE_RED, -42.0)
			return
		inv.add_gold(take_from_treasury(26))
		modify_family_reputation("family_herbalist", 15, "Suministro médico entregado")
		completed_contracts_today[2] = d
		_msg_player(player, "📋🏥 ¡Urgencia Médica completada! (+26 Oro, +15 Afinidad)", Color.SPRING_GREEN, -44.0)
	elif contract_idx == 3:
		if inv.has_item("bandit_scrap", 1): inv.remove_item("bandit_scrap", 1)
		elif inv.has_item("frog_legs", 1): inv.remove_item("frog_legs", 1)
		else:
			_msg_player(player, "❌ Requiere 1 Chatarra de Bandido o 1 Ancas de Rana", Color.ORANGE_RED, -42.0)
			return
		inv.add_gold(take_from_treasury(34))
		if wanted_level > 0:
			wanted_level = maxi(0, wanted_level - 1)
			bounty_gold = maxi(0, bounty_gold - 25)
		completed_contracts_today[3] = d
		_msg_player(player, "📋🚓 ¡Recompensa cobrada! (+34 Oro, -1 Nivel de Búsqueda)", Color.GOLD, -44.0)
	_open_notice_board_ui()

# ==============================================================================
# HUÉSPEDES DE LA POSADA, POZO, COMPOSTADOR Y MASCOTAS
# ==============================================================================
func _spawn_unemployed_tavern_guests() -> void:
	var tex_traveler := _load_tex("res://assests/world/village/villager_traveler.png")
	var guest_defs: Array[Dictionary] = [
		{"name": "Aldric", "role": "Viajero sin Oficio", "day_pos": Vector2(440, 44), "bed_pos": VillageTavern.GUEST_BEDS[0]},
		{"name": "Sora", "role": "Forastera sin Oficio", "day_pos": Vector2(495, 44), "bed_pos": VillageTavern.GUEST_BEDS[1]},
		{"name": "Darío", "role": "Jornalero sin Oficio", "day_pos": Vector2(465, 58), "bed_pos": VillageTavern.GUEST_BEDS[2]}
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
		{"type": DomesticPet.PetType.DOG, "name": "Toby", "owner": "Granja del Jugador", "fam": "player_farm", "pos": Vector2(-685, -52), "guard": true, "tint": Color(1.0, 0.96, 0.90)},
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
	bed_root.set_meta("pet_type", p_type)
	bed_root.add_to_group("ranch_fence_2d")
	entities_root.add_child(bed_root)
	var p1 := _add_poly(PackedVector2Array([Vector2(-9, -5), Vector2(9, -5), Vector2(10, 5), Vector2(-10, 5)]), Color(0.45, 0.28, 0.15, 0.95) if p_type == DomesticPet.PetType.DOG else Color(0.52, 0.34, 0.22, 0.95), 0, Vector2.ZERO, bed_root)
	var p2 := _add_poly(PackedVector2Array([Vector2(-7, -3), Vector2(7, -3), Vector2(8, 3), Vector2(-8, 3)]), Color(0.76, 0.28, 0.24, 0.95) if p_type == DomesticPet.PetType.DOG else Color(0.32, 0.56, 0.78, 0.95), 0, Vector2.ZERO, bed_root)
	var p3 := _add_poly(PackedVector2Array([Vector2(11, -1), Vector2(16, -1), Vector2(15, 3), Vector2(12, 3)]), Color(0.78, 0.68, 0.32, 0.95), 0, Vector2.ZERO, bed_root)
	for p_it in [p1, p2, p3]:
		if p_it != null:
			p_it.add_to_group("ranch_fence_2d")

func can_family_feed_pet(fam_id: String) -> bool:
	if fam_id == "player_farm":
		for r_id in [int(VillageNPC.TradeRole.FISHMONGER), int(VillageNPC.TradeRole.BUTCHER), int(VillageNPC.TradeRole.HERBALIST), int(VillageNPC.TradeRole.BAKER)]:
			if get_trade_total_stock(r_id) > 0:
				return true
		return is_instance_valid(_innkeeper_npc) and not _innkeeper_npc.is_dead
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.family_id == fam_id and not v.is_dead and not v.is_downed:
				return true
	return false

func _get_nearest_well_dist_sq(pos: Vector2) -> float:
	var best_d2: float = INF
	for w_pos in _well_positions:
		var d2: float = pos.distance_squared_to(w_pos)
		if d2 < best_d2:
			best_d2 = d2
	return best_d2

## Devuelve `true` si `world_pos` está a `<= max_meters` (por defecto 2.0m = 32 px del borde) de cualquier fuente de agua
## (Pozos de Agua de la Granja/Taberna/Plaza, Lago del Oeste, Ciénaga de las Ranas o lavabo de Urgencias del Hospital).
func is_position_near_water_source(world_pos: Vector2, max_meters: float = 2.0) -> bool:
	var max_well_dist: float = max_meters * 16.0 + 6.0 # 2m (32 px) desde el brocal del pozo (~6 px de radio) = 38 px
	for w_pos in _well_positions:
		if world_pos.distance_squared_to(w_pos) <= max_well_dist * max_well_dist:
			return true
	for spot in get_tree().get_nodes_in_group("fishing_spots"):
		if spot is Node2D:
			var s_pos: Vector2 = (spot as Node2D).global_position
			# El Lago del Oeste tiene radio ~48 px alrededor de su centro + muelle en `Vector2(36, 0)`
			var lake_r: float = 48.0 + max_meters * 16.0
			if world_pos.distance_squared_to(s_pos) <= lake_r * lake_r:
				return true
			if world_pos.distance_squared_to(s_pos + Vector2(36, 0)) <= max_well_dist * max_well_dist:
				return true
	# Charca de agua de la Ciénaga del Suroeste
	if Rect2(Vector2(-1910, 165), Vector2(710, 320)).grow(max_meters * 16.0).has_point(world_pos):
		return true
	# Arroyo / Fuente del Lavadero del pueblo
	if world_pos.distance_squared_to(VillageWork.LAVADERO_POS) <= max_well_dist * max_well_dist:
		return true
	# Lavabo quirúrgico junto a la Cama de Urgencias del Hospital
	if world_pos.distance_squared_to(_hospital_bed_pos) <= max_well_dist * max_well_dist:
		return true
	return false

# ==============================================================================
# INTERACCIÓN CENTRAL CON TODAS LAS ESTACIONES DE LA ALDEA
# ==============================================================================
## Prioridad de interacción [E]: garantiza que el jugador siempre pueda abrir una puerta cerrada aunque haya un NPC parado encima,
## y permite reportar cualquier cadáver en el suelo con [E].
func try_priority_door_or_corpse_interaction(player: Node2D, mouse_pos: Vector2) -> bool:
	if not player or player_being_escorted_to_jail:
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

	# 1.5. Si el jugador está junto a cualquier Pozo de Agua y está manchado de sangre, herido o lleva recipientes vacíos (o apunta al pozo), usar el pozo con prioridad
	for w_pos in _well_positions:
		if pos.distance_to(w_pos) <= 28.0 and ((player.has_method("is_bloodstained") and bool(player.call("is_bloodstained"))) or w_pos.distance_to(mouse_pos) <= 18.0):
			_use_water_well(player)
			return true

	# 2. Si hay un cadáver, herido abatido o NPC aturdido/sedado cerca del jugador (<= 32 px), priorizar saquear/reanimar/reportar con [E]
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var c := n as VillageNPC
			if pos.distance_to(c.global_position) <= 32.0:
				var can_loot_pockets: bool = not c.corpse_pocket_looted and (c.personal_gold > 0 or c.carries_royal_safe_conduct or not c.pocket_items.is_empty())
				var mouse_aiming_c: bool = c.global_position.distance_to(mouse_pos) <= 20.0
				if (c.is_dead and not c.corpse_buried and (c.corpse_on_ground or c.corpse_in_morgue)) or (not c.is_dead and (c.is_downed or ((c.sedated_timer > 0.0 or c.is_stunned_flag) and can_loot_pockets))):
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
	if not player or player_being_escorted_to_jail:
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
	if VillageCulture.try_interact(self, player, pos): # V5e: leer en la biblioteca
		return
	if VillageMayor.try_interact(self, player, pos): # P5: alcaldía y candidatura
		return
	if VillageHousing.try_interact(self, player, pos): # P6: solar o cama de tu casa
		return
	if VillageUnderworld.try_interact(self, player, pos): # P7: encargo nocturno del perista
		return
	if VillageForensics.try_interact(self, player, pos): # P2: fregar escena de sangre con lejía (doble E)
		return

	# 2. Tablón de Encargos de la Plaza
	if pos.distance_squared_to(_notice_board_pos) <= 28.0 * 28.0:
		_open_notice_board_ui()
		return

	# 3. Morgue Forense
	if pos.distance_squared_to(_morgue_table_positions[1]) <= 36.0 * 36.0:
		_open_morgue_autopsy_ui()
		return

	# 3b. Capilla del Alba y Cementerio Parroquial
	if pos.distance_squared_to(_church_altar_pos) <= 34.0 * 34.0 or pos.distance_squared_to(_cemetery_gate_pos) <= 34.0 * 34.0 or Rect2(Vector2(822, 260), Vector2(268, 168)).has_point(pos):
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
	var d_well: float = _get_nearest_well_dist_sq(pos)
	var comp_on: bool = _compost_sprite == null or _compost_sprite.visible
	var d_comp: float = pos.distance_squared_to(_compost_pos) if comp_on else INF

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
	VillageFaith.on_hour(self, actual_hour) # G2: Oficio del Alba (domingo por la mañana)
	VillageHousing.on_hour(self, actual_hour) # P1: dependiente y clientes reales en tu tienda
	VillageUnderworld.fence_on_hour(self, actual_hour) # P5b: el perista trasnocha en el callejón de la taberna
	VillageNightJobs.on_hour(self, actual_hour) # P6b: a la 1:00 salen los saboteadores, rateros y profanadores
	VillageClub.on_hour(self, actual_hour) # P6: el club del sótano abre cada noche de 21:00 a 03:00
	VillageTavern.on_hour(self, actual_hour) # Paso 3: clientes en mesas y partida de póker en El Jabalí Dorado
	VillageFame.sync_masterwork_counters(self) # A1: mostrador de las Obras Maestras en el taller de cada maestro
	VillageCollections.sync_points(self) # P5: puntos de cobro en los locales y objetos del ayuntamiento
	VillageNeeds.on_hour(self, actual_hour) # E: higiene, taberna, limosna
	VillageIllness.on_hour(self, actual_hour) # E2: contagios
	VillageSect.on_hour(self, actual_hour) # O3: reunión de la secta (viernes de madrugada)
	VillageFamilia.on_hour(self, actual_hour) # R2: reuniones nocturnas en el reservado de la Trattoria
	VillageLots.on_hour(self, actual_hour) # V4: el carpintero avanza la obra si está allí
	VillageCivic.on_hour(self, actual_hour) # V5b: votar en persona y el alcalde en el ayuntamiento
	VillagePlaces.on_hour(self, actual_hour) # V5c: ratos libres en el parque, la plaza o el mirador
	VillageWork.on_hour(self, actual_hour) # V5d: jornaleros (contratar, contar horas, pagar)
	VillageCulture.on_hour(self, actual_hour) # V5e: mercado de los miércoles
	VillageMigration.on_hour(self, actual_hour) # V3: los que se marchan siguen su camino
	VillageNobility.on_hour(self, actual_hour) # V6: los nobles aparecen en la primera hora
	VillageFamily.on_hour(self, actual_hour) # V9: lo que se aprende en la escuela
	VillageConfession.on_hour(self, actual_hour) # P4: confesiones entre semana en la capilla
	VillageUnderworld.on_hour(self, actual_hour) # P3 Parte B: caravana nocturna de contrabando
	VillageJustice.on_hour(self) # B2: condenas por horas de los vecinos encerrados en el calabozo

	# 07:00 AM -> Comprobar llegada semanal de los 2 Mercaderes Ambulantes (Día 3: Maese Casimir | Día 6: Valeria la Tratante)
	if actual_hour == 7:
		_check_weekly_merchant_arrival(actual_day)
	# 08:00 AM -> Salarios de autoridades, compras recíprocas entre gremios y jornales diarios
	elif actual_hour == 8:
		_process_morning_salaries_and_inter_guild_circulation()
	# 21:00 PM -> Cobro de alquiler nocturno en la Posada (6 Oro) o desahucio a Campamentos Rústicos en las Afueras
	elif actual_hour == 21:
		_process_nightly_tavern_rent_and_vagrant_camps()

	# Ciclo de Sepultura Forense: solo se sepultan los cuerpos cuyo caso YA fue resuelto o archivado y que lleven >= 18h desde entonces
	var cur_total_hours: int = actual_day * 24 + actual_hour
	var remaining_morgue: Array[Dictionary] = []
	var any_buried := false
	for entry in morgue_active_corpses:
		var v_name_h: String = str(entry.get("victim_name", ""))
		var added_h: int = int(entry.get("added_total_hours", cur_total_hours))
		if not _is_corpse_under_active_investigation(v_name_h) and (cur_total_hours - added_h) >= 18:
			_bury_corpse_in_cemetery(entry, "Sepultura parroquial tras resolverse/archivarse el caso")
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

func _update_doors_and_windows(_delta: float, _player: Node2D, _mouse_pos: Vector2) -> void:
	for d_entry in building_doors:
		var d_lbl: Label = d_entry.get("label")
		if is_instance_valid(d_lbl):
			d_lbl.visible = false
	for w_entry in building_windows:
		var w_lbl: Label = w_entry.get("label")
		if is_instance_valid(w_lbl):
			w_lbl.visible = false

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
		_msg_player(player, "🚪 Puerta cerrada (Oculta la visión desde fuera)", Color(0.90, 0.85, 0.70), -42.0)
		return
	if locked_by_p:
		_set_door_state(d_entry, true, false, false)
		_msg_player(player, "🔓 Quitaste tu cerrojo y abriste la puerta", Color.SPRING_GREEN, -42.0)
		return
	if not is_locked_now:
		_set_door_state(d_entry, true, false, false)
		_msg_player(player, "🚪 Puerta abierta", Color.SPRING_GREEN, -42.0)
		return

	_msg_player(player, "🔒 Cerrada con llave — Pulsa [F] para forzar cerradura", Color.GOLD, -42.0)
	_hint_player("🔒 La puerta de %s está cerrada con llave. Pulsa [F] si quieres forzar la cerradura (usa Sigilo [C])." % b_title, player)

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
			_msg_player(player, "🚪 Esta puerta no tiene llave ajena (Usa [E] para abrirla)", Color.LIGHT_GRAY, -40.0)
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
			_msg_player(player, "🔓🤫 Cerradura forzada con [F] en sigilo: %s (Sin testigos)" % b_title, Color.SPRING_GREEN, -44.0)
		else:
			wanted_level = clampi(wanted_level + 1, 1, 5)
			bounty_gold += 20
			var msg := "🚨👁️ ¡%s te vio forzar la cerradura de %s! (+20 Oro de multa)" % [witness.npc_name, b_title]
			crime_history.push_front(msg)
			_notify_inquisitor_of_police_crime(msg, 12)
			_msg_player(player, msg, Color.ORANGE_RED, -46.0)
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
				_msg_player(player, w_msg, Color.ORANGE_RED, -46.0)
			else:
				_msg_player(player, "🪟🔓 Forzaste el postigo con [F] y entraste por la ventana", Color.SPRING_GREEN, -44.0)
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
		_msg_player(player, "🚪🔒 ¡Puerta cerrada y trancada con cerrojo! (Impide el paso y la visión)", Color.GOLD, -44.0)
	else:
		_set_door_state(d_entry, false, false, false)
		_msg_player(player, "🔓 Quitaste el cerrojo de la puerta", Color.SPRING_GREEN, -42.0)
	return true

func _interact_building_window(player: Node2D, w_entry: Dictionary) -> void:
	var b_rect: Rect2 = w_entry.get("building_rect", Rect2())
	var w_pos: Vector2 = w_entry.get("pos", Vector2.ZERO)
	var door_south: bool = bool(w_entry.get("door_south", true))
	var b_title: String = str(w_entry.get("building_title", "Edificio"))
	if not b_rect.has_point(player.global_position):
		if bool(w_entry.get("is_shuttered", false)):
			_msg_player(player, "🪟🔒 Postigo cerrado — Pulsa [F] para forzar ventana", Color.GOLD, -42.0)
			_hint_player("🪟🔒 La ventana de %s tiene el postigo echado. Pulsa [F] para forzarla." % b_title, player)
			return
		player.global_position = w_pos + Vector2(0, -15.0 if door_south else 15.0)
		_msg_player(player, "🪟🤫 Te colaste por la ventana de %s" % b_title, Color.AQUA, -44.0)
	else:
		player.global_position = w_pos + Vector2(0, 15.0 if door_south else -15.0)
		_msg_player(player, "🪟🏃 Saliste al exterior por la ventana", Color.AQUA, -44.0)

func _interact_house_chest(player: Node2D, ch: Dictionary) -> void:
	var cur_day: int = WorldClock.current_day if WorldClock else 1
	var inv: SimpleInventory = player.get("inventory")
	if int(ch.get("looted_day", -1)) == cur_day:
		if inv:
			for ev_id in ["royal_safe_conduct", "organ_heart", "organ_liver", "organ_kidney", "organ_lung", "organ_stomach", "organ_eye"]:
				if inv.remove_item(ev_id, 1):
					ch["planted_evidence"] = ev_id
					ch["planted_by_player"] = true
					var ev_name: String = inv.get_item_name(ev_id)
					var ch_title_ev: String = str(ch.get("title", "Cofre"))
					_msg_player(player, "🕵️📥 ¡Plantaste %s dentro de %s! (Incriminará a esta familia en la investigación)" % [ev_name, ch_title_ev], Color.VIOLET, -46.0)
					return
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("📦 Este cofre ya fue abierto hoy (Lleva el Salvoconducto o un Órgano y pulsa [E] para plantar pruebas)", Color.LIGHT_GRAY, -42.0)
		return

	# P6.2: el cofre de tu propia casa no regala oro (antes daba 18–32 al día). Tu oro a salvo va en el escondite.
	if VillageHousing.is_player_family_chest(self, str(ch.get("family_id", ""))):
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("📦🏡 Es tu cofre: aquí no hay nada que no hayas puesto tú. (Para esconder oro, pide al carpintero un escondite)", Color.LIGHT_GRAY, -46.0)
		return

	ch["looted_day"] = cur_day
	var spr: Sprite2D = ch.get("sprite")
	if is_instance_valid(spr):
		spr.texture = _load_tex("res://assests/world/village/house_chest_open.png")

	var gold_loot: int = randi_range(18, 32)
	if str(ch.get("family_id", "")) == "town_hall":
		gold_loot = VillageCivic.rob_coffers(self) # V5b: sale de las arcas de verdad (puede estar casi vacía)
	else:
		# Regla 1: los ahorros del cofre son de la familia; se los quitas a sus miembros (si no tienen, no hay nada).
		gold_loot = _take_family_savings(str(ch.get("family_id", "")), gold_loot)
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
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v: VillageNPC = n as VillageNPC
			if v.is_downed and not v.is_dead and v.global_position.distance_to(player.global_position) <= 90.0:
				v.revive_from_downed(player, false)
				return

	var health: HealthComponent = player.get_node_or_null("HealthComponent")
	if health and health.current_health >= health.max_health - 0.1 and not health.is_bleeding and health.current_blood <= 0.1 and health.wounds.is_empty() and not health.has_active_sickness_or_infection():
		_msg_player(player, "🏥 Tu salud ya está al 100%, sin heridas ni infecciones", Color.LIGHT_GRAY, -42.0)
		return
	var already_resting: bool = health != null and health.is_resting_in_bed
	var inv: SimpleInventory = player.get("inventory") if "inventory" in player else null
	if not already_resting:
		if inv and inv.gold < 10:
			_msg_player(player, "❌ Necesitas 10 Oro para ingresar en la Cama de Urgencias", Color.ORANGE_RED, -42.0)
			return
		if inv:
			inv.add_gold(-10)
			pay_into(role_npc(int(VillageNPC.TradeRole.DOCTOR)), 10) # Regla 1: cobra el médico (o las arcas)
	player.global_position = _hospital_bed_pos
	if "velocity" in player:
		player.velocity = Vector2.ZERO
	if health:
		health.is_resting_in_bed = true
	var doc_npc: VillageNPC = null
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var vn := n as VillageNPC
			if vn.trade_role == VillageNPC.TradeRole.DOCTOR and not vn.is_dead and not vn.is_downed:
				doc_npc = vn
				break
	if is_instance_valid(doc_npc):
		doc_npc.is_sleeping = false
		doc_npc._active_hospital_patient = player
		_msg_player(player, "🏥🛏️ Ingresado en Cama de Urgencias: %s irá curando tus heridas una por una (no te muevas)" % doc_npc.npc_name, Color.SPRING_GREEN, -44.0)
	else:
		if health:
			var urg_id: int = health.get_most_urgent_untreated_wound_id(true)
			if urg_id >= 0:
				health.treat_wound(urg_id, "tend_makeshift")
		_msg_player(player, "🏥🛏️ Sin médico de guardia: te aplicaste un vendaje de urgencia; descansa en la camilla para recuperarte", Color.GOLD, -44.0)

func _use_tavern_games_table(start_tab: int = 0) -> void:
	var games_ui = get_tree().root.find_child("TavernGamesUI", true, false)
	if games_ui and games_ui.has_method("open_games"):
		games_ui.call("open_games", start_tab)

func _use_tavern_bed(player: Node2D) -> void:
	var inv: SimpleInventory = player.get("inventory")
	if not inv or inv.gold < 8:
		_hint_player("🛌 Necesitas 8 Oro para alquilar la cama de la Taberna.", player)
		return
	inv.add_gold(-8)
	pay_into(_innkeeper_npc, 8) # Regla 1: cobra la posadera (o las arcas)
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
	_msg_player(player, "🛌 Dormiste en la Posada (-8 Oro, +100% Sueño)", Color.GOLD, -42.0)

func _use_water_well(player: Node2D) -> void:
	VillageNeeds.player_wash(self) # E1: también te lavas
	if player.has_method("refill_watering_can"):
		player.call("refill_watering_can")
	else:
		_msg_player(player, "💧 Agua fresca del pozo", Color.AQUA, -40.0)

func _use_compost_bin(player: Node2D) -> void:
	var inv: SimpleInventory = player.get("inventory")
	if not inv:
		return
	for org_id in ["mushroom", "herbs", "carrot", "cabbage"]:
		if inv.remove_item(org_id, 1):
			inv.add_item("fertilizer", 2)
			_msg_player(player, "♻️ Compostador: +2 Abono Orgánico", Color.SPRING_GREEN, -42.0)
			return
	_hint_player("♻️ Necesitas 1 Hongo, Hierba o Verdura para fermentar 2 bolsas de Abono Orgánico.", player)

# ==============================================================================
# B2.2: QUEDADAS FÍSICAS (Pasar tiempo juntos) — el SocialDirector decide, aquí se ejecuta en el mundo
# ==============================================================================
@warning_ignore("unused_private_class_variable") # Se usa desde otro script (vm._hangout_plan_timer)
var _hangout_plan_timer: float = 6.0
const HANGOUT_ARRIVAL_RADIUS: float = 20.0

## Puntos de encuentro del pueblo ofrecidos al SocialDirector ({id, pos, kind, label}).
func get_hangout_spots() -> Array:
	var spots: Array = []
	if not is_building_door_blocked("tavern"):
		spots.append({"id": "tavern", "pos": _tavern_social_pos + Vector2(0, 14), "kind": "tavern", "label": "la Taberna"})
	spots.append({"id": "plaza_well", "pos": _plaza_well_pos + Vector2(0, 24), "kind": "well", "label": "el Pozo de la Plaza"})
	spots.append({"id": "plaza_bench", "pos": Vector2(468, 54), "kind": "bench", "label": "el Rincón de la Plaza"})
	spots.append({"id": "plaza_board", "pos": _notice_board_pos + Vector2(0, 26), "kind": "plaza", "label": "la Plaza Central"})
	spots.append({"id": "farm_well", "pos": _well_pos + Vector2(0, 24), "kind": "well", "label": "el Pozo de la Granja"})
	spots.append_array(VillagePlaces.hangout_spots()) # V5c
	return spots

func _is_npc_eligible_for_hangout(v: VillageNPC) -> bool:
	return VillageSocialLife._is_npc_eligible_for_hangout(self, v)

func _get_npcs_by_person_key() -> Dictionary:
	var out: Dictionary = {}
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and not (n as VillageNPC).is_dead:
			out[(n as VillageNPC).get_person_key()] = n
	return out

func _spot_label_for(spot_id: String) -> String:
	for sp in get_hangout_spots():
		if str(sp.get("id", "")) == spot_id:
			return str(sp.get("label", ""))
	return ""

# ==============================================================================
# B4.2: PELEAS DISCRETAS EN VIVO — el Director decide, aquí se representan y se aplican las consecuencias
# ==============================================================================
const FIGHT_TRIGGER_RADIUS: float = 72.0
const FIGHT_GUARD_RADIUS: float = 140.0
const FIGHT_WITNESS_RADIUS: float = 110.0
const FIGHT_DURATION_SEC: float = 3.5
const FIGHT_GUARD_STOP_SEC: float = 1.6
const FIGHT_HEALTH_FLOOR: float = 0.35
var _live_fights: Array[Dictionary] = []
@warning_ignore("unused_private_class_variable") # Se usa desde otro script (vm._fight_scan_timer)
var _fight_scan_timer: float = 3.0

func _is_npc_free_to_fight(v: VillageNPC) -> bool:
	return VillageSocialLife._is_npc_free_to_fight(self, v)

func _find_fight_guard(pos: Vector2, a: VillageNPC, b: VillageNPC) -> VillageNPC:
	return VillageSocialLife._find_fight_guard(self, pos, a, b)

func _scan_rival_friction() -> void:
	VillageSocialLife._scan_rival_friction(self)

func _try_start_live_fight() -> void:
	VillageSocialLife._try_start_live_fight(self)

func _update_live_fights(delta: float) -> void:
	VillageSocialLife._update_live_fights(self, delta)

func player_stop_live_fight(npc: VillageNPC) -> bool:
	return VillageSocialLife.player_stop_live_fight(self, npc)

func _finish_live_fight(fight: Dictionary, a: VillageNPC, b: VillageNPC, interrupted: bool, guard_stops: bool) -> void:
	VillageSocialLife._finish_live_fight(self, fight, a, b, interrupted, guard_stops)

func _update_social_hangouts(delta: float) -> void:
	VillageSocialLife._update_social_hangouts(self, delta)

# ==============================================================================
# B3.1: AVANCE DIARIO DE CORTEJOS EN VIVO (Interés → Coqueteo → Citas → Pareja)
# ==============================================================================
const ROMANCE_STAGE_NAMES: Dictionary = {"interest": "sienten interés mutuo", "flirt": "han empezado a coquetear", "dating": "han empezado a salir"}

func _advance_live_romances(cur_day: int) -> Dictionary:
	if social_director == null:
		return {}
	var by_key: Dictionary = _get_npcs_by_person_key()
	var profiles: Dictionary = {}
	var families: Dictionary = {}
	for k in by_key.keys():
		var v: VillageNPC = by_key[k]
		if v.person_profile != null and not v.is_dead:
			if int(v.person_profile.bereavement_days_left) > 0:
				var d_nm: String = str(v.person_profile.deceased_partner_name)
				var ended: bool = v.person_profile.tick_bereavement_day()
				if ended:
					v.add_thought("Aunque siempre recordaré a %s, la vida continúa (+4)" % d_nm, 4.0)
					record_social_event("bereavement_ended", v, null, "%s ha superado los días más duros del luto por %s" % [v.npc_name, d_nm])
				else:
					v.add_thought("Sigo de luto por la pérdida de %s (-12)" % d_nm, -12.0)
			profiles[k] = v.person_profile
			families[k] = v.family_id
	var res: Dictionary = social_director.advance_live_romance_day(cur_day, profiles, families)
	for adv in res.get("advanced", []):
		var a: VillageNPC = by_key.get(str(adv.get("id_a", "")), null)
		var b: VillageNPC = by_key.get(str(adv.get("id_b", "")), null)
		if not is_instance_valid(a) or not is_instance_valid(b):
			continue
		var to_st: String = str(adv.get("to", ""))
		if to_st == "couple":
			var rel_now: int = a.get_relationship_with_npc(b.get_person_key())
			a.modify_npc_relationship(b, maxi(0, 68 - rel_now), "💑 Pareja: decidieron estar juntos")
			a.add_thought("¡Ahora estoy en pareja con %s! (+15)" % b.npc_name, 15.0)
			b.add_thought("¡Ahora estoy en pareja con %s! (+15)" % a.npc_name, 15.0)
			a._spawn_floating_text("💑 ¡%s y %s ahora son pareja!" % [a.npc_name, b.npc_name], Color(1.0, 0.55, 0.75), -46.0)
			record_social_event("couple", a, b, "%s y %s ahora son pareja" % [a.npc_name, b.npc_name])
			VillageSocialLife.on_new_couple_jealousy(self, a, b)
		else:
			if to_st in ["flirt", "dating"]:
				a.add_thought("Me hace ilusión lo que tengo con %s (+5)" % b.npc_name, 5.0)
				b.add_thought("Me hace ilusión lo que tengo con %s (+5)" % a.npc_name, 5.0)
			record_social_event("romance_" + to_st, a, b, "%s y %s %s" % [a.npc_name, b.npc_name, str(ROMANCE_STAGE_NAMES.get(to_st, "se acercan"))])
	for rj in res.get("rejections", []):
		VillageSocialLife.on_rejection(self, by_key.get(str(rj.get("from", "")), null), by_key.get(str(rj.get("to", "")), null))
	for fz in res.get("fizzled", []):
		var fa: VillageNPC = by_key.get(str(fz.get("id_a", "")), null)
		var fb: VillageNPC = by_key.get(str(fz.get("id_b", "")), null)
		if is_instance_valid(fa) and is_instance_valid(fb):
			record_social_event("romance_fizzle", fa, fb, "Lo de %s y %s se enfrió" % [fa.npc_name, fb.npc_name])
	for brk in res.get("breakups", []):
		var ba: VillageNPC = by_key.get(str(brk.get("id_a", "")), null)
		var bb: VillageNPC = by_key.get(str(brk.get("id_b", "")), null)
		if is_instance_valid(ba) and is_instance_valid(bb):
			ba.modify_npc_relationship(bb, -10, "💔 Ex-pareja tras una ruptura")
			ba.add_thought("Rompí mi relación con %s (-14)" % bb.npc_name, -14.0)
			bb.add_thought("Rompí mi relación con %s (-14)" % ba.npc_name, -14.0)
			ba._spawn_floating_text("💔 ¡%s y %s han roto su relación!" % [ba.npc_name, bb.npc_name], Color(1.0, 0.38, 0.45), -46.0)
			record_social_event("breakup", ba, bb, "%s y %s han roto su relación" % [ba.npc_name, bb.npc_name])
	for rec in res.get("reconciled", []):
		var rca: VillageNPC = by_key.get(str(rec.get("id_a", "")), null)
		var rcb: VillageNPC = by_key.get(str(rec.get("id_b", "")), null)
		if is_instance_valid(rca) and is_instance_valid(rcb):
			var rel_r: int = rca.get_relationship_with_npc(rcb.get_person_key())
			rca.modify_npc_relationship(rcb, maxi(10, 62 - rel_r), "💑 Pareja reconciliada")
			rca.add_thought("Me reconcilié con %s (+14)" % rcb.npc_name, 14.0)
			rcb.add_thought("Me reconcilié con %s (+14)" % rca.npc_name, 14.0)
			rca._spawn_floating_text("💑✨ ¡%s y %s se han reconciliado!" % [rca.npc_name, rcb.npc_name], Color(1.0, 0.62, 0.80), -46.0)
			record_social_event("couple_reconciled", rca, rcb, "%s y %s se han reconciliado y vuelven a ser pareja" % [rca.npc_name, rcb.npc_name])
	return res

func _on_quests_changed(_qid: String) -> void:
	VillageQuests.refresh_markers(self)
	var qm_c = get_node_or_null("/root/QuestManager")
	if qm_c != null and _qid != "":
		var q_c: Dictionary = qm_c.get_quest(_qid)
		if not q_c.is_empty():
			VillageChronicle.on_quest_changed(self, q_c)

func _on_day_passed(_new_day: int) -> void:
	arrivals_today_count = 0
	chronicle_daily = true
	if social_director != null:
		_advance_live_romances(_new_day)
		social_director.on_day_passed(_new_day)
		VillageSocialLife.daily_reciprocity(self)
		VillageSocialLife.daily_distance_cooling(self, _new_day)
		VillageChronicle.daily_friendship_scan(self)
		VillageSocialLife.GossipMemory.daily_decay(self)
		VillageSecrets.daily(self)
		VillageDesires.daily(self)
		VillageFaith.daily(self) # G: roces de fe, sacerdote y bandos
		VillageSect.daily(self) # O: la secta (justo después: vuelve a añadir su bando oculto)
		VillageFamilia.daily(self) # R2: La Familia (nace sola, recluta y planea reuniones en el reservado)
		VillageNeeds.daily(self) # E1/E3/E5
		VillageTrades.daily(self) # V5: estrenar ropa en la sastrería
		VillageCivic.daily(self) # V5b: arcas robadas y albergue
		VillageCulture.daily(self) # V5e: el arreglador repara puestos saboteados
		VillageNobility.daily(self) # V6: los lunes, rentas de las tierras
		VillageFamily.daily(self) # V9: crecer, nacer, esperar un hijo y la escuela
		VillageIllness.daily(self) # E2
		VillageCrime.daily(self) # E4: como mucho un robo por noche
		VillageTown.daily(self) # I: elecciones, impuestos del sábado, desfalcos
		VillageClans.daily(self) # P1: romances prohibidos, ovejas negras y tumbas
		VillageForensics.daily(self) # P2: sicarios y confesiones por embriaguez/fiebre
		VillageLineage.daily(self) # P3: hijos secretos, manutención, cazafortunas y pasado
		VillageConfession.daily(self) # P4: penitencias, santuario y excomuniones
		VillageMayor.daily(self) # P5: promesas electorales, decretos y protestas
		VillageHousing.daily(self) # P6: pareja en casa, huerto y rentas comerciales
		VillageUnderworld.daily(self) # P7: mercado negro, usura, protección y jefe del hampa
		VillageCollections.daily(self) # P5: el sábado se aparta lo que te deben; lo recoges en persona
		VillageFame.daily(self) # Fama de los vecinos y Maestros Artesanos con estilo propio
		VillageQuests.on_day_passed(self)
	chronicle_daily = false

	# Descontar 1 día del embargo comercial (20..30 días mercaderes semanales / 7 días caravanas P3) si fue asesinado
	for m_key in ["casimir", "valeria", "high_pass", "river_port", "sun_plain"]:
		var susp_d: int = int(merchant_suspension_days.get(m_key, 0))
		if susp_d > 0:
			susp_d = maxi(0, susp_d - 1)
			merchant_suspension_days[m_key] = susp_d
			if susp_d == 0:
				var p_m = get_tree().get_first_node_in_group("player")
				if p_m and p_m.has_method("show_hint"):
					var m_label: String = "Maese Casimir (Liga Minera)" if m_key == "casimir" else ("Valeria la Tratante (Gremio de Caza)" if m_key == "valeria" else str(VillageCulture.ROUTE_CARAVAN_NAMES.get(m_key, m_key)))
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

	# 1b. Sepultura matutina de cuerpos en la Morgue SOLO si su caso ya se resolvió o archivó (los casos abiertos permanecen en la Morgue)
	var cur_total_h: int = _new_day * 24 + (WorldClock.current_hour if WorldClock else 6)
	var rem_morgue: Array[Dictionary] = []
	for m_entry in morgue_active_corpses:
		var v_name_d: String = str(m_entry.get("victim_name", ""))
		if not _is_corpse_under_active_investigation(v_name_d) and (cur_total_h - int(m_entry.get("added_total_hours", cur_total_h))) >= 12:
			_bury_corpse_in_cemetery(m_entry, "Sepultura parroquial matutina tras resolverse/archivarse el caso")
		else:
			rem_morgue.append(m_entry)
	morgue_active_corpses = rem_morgue
	_refresh_morgue_table_sprites()

	# 1c. La Posada y los artesanos ya NO reponen stock por arte de magia al dormir: fabrican sus propios recursos físicamente durante su turno de trabajo (`_process_artisan_work_shift`)

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
				kin_candidate.promote_to_trade(role_key, str(cfg["title"]), cfg["work_pos"], inh_stock, cfg["tex"])
				_note_inheritance(kin_candidate, current_holder)
				trade_npcs[role_key] = kin_candidate
				family_npcs.erase(role_key)
				_hint_player("🏠 Herencia Familiar: %s (%s) asumió el puesto de %s como Aprendiz (54%% Eficiencia · 5 días para Maestro)." % [kin_candidate.npc_name, str(cfg["family_name"]), str(cfg["title"])])
				continue

			if sab_days > 0:
				continue

			# Sucesión Interna #2 (V8): el más ambicioso y capaz del pueblo (un sin oficio, o un familiar de otra casa que
			# quiere prosperar) se queda el taller; si no hay nadie, el primer viajero sin oficio de la posada
			var outsider: VillageNPC = _pick_ambitious_successor(role_key, str(cfg["title"]))
			if outsider == null:
				outsider = _pop_living_unemployed()
			if outsider:
				var inh_stock2: Dictionary = (biz.get("stock_override", cfg["stock"]) as Dictionary).duplicate()
				outsider.promote_to_trade(role_key, str(cfg["title"]), cfg["work_pos"], inh_stock2, cfg["tex"], cfg["bed1_pos"], cfg["table_pos"], str(cfg["family_id"]), str(cfg["family_name"]))
				_note_inheritance(outsider, current_holder)
				trade_npcs[role_key] = outsider
				_hint_player("🔄 Sucesión en la aldea: %s asumió el taller como nuevo %s Novato (35%% Eficiencia · 7 días para Maestro)." % [outsider.npc_name, str(cfg["title"])])
		else:
			biz["stock_override"] = current_holder.shop_stock.duplicate()

	# 2. LLEGADAS EXTERNAS DESDE EL BORDE DEL MAPA (Estricto límite de `MAX_DAILY_ARRIVALS = 2` personas por día)
	_process_daily_map_edge_arrivals()
	VillageMigration.daily(self) # V3: casas, marchas y llegadas según el atractivo del pueblo

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
		var new_inn: VillageNPC = _spawn_generated_newcomer(
			"NPC_Innkeeper_",
			VillageNPC.TradeRole.INNKEEPER,
			VillageNPC.TradeRole.INNKEEPER,
			"Chef y Posadera (Novata)",
			_load_tex("res://assests/world/village/villager_innkeeper.png"),
			VillageTavern.INNKEEPER_WORK_POS,
			VillageTavern.MARTA_BED_POS,
			{"country_stew": 2, "bread": 3, "roasted_chicken": 1},
			_tavern_social_pos,
			"family_tavern",
			"Posada El Jabalí"
		)
		_innkeeper_npc = new_inn
		arrivals_today_count += 1
		_hint_player("🍺🚶 %s (Posadera Novata · 35%%) está llegando por el borde del valle para reabrir la Posada." % new_inn.npc_name)

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
		var inh_st: Dictionary = (biz.get("stock_override", cfg["stock"]) as Dictionary).duplicate()
		var new_art: VillageNPC = _spawn_generated_newcomer(
			"NPC_Newcomer_Trade_",
			role_key,
			role_key,
			str(cfg.get("title", "Artesano")) + " (Recién Llegado)",
			cfg.get("tex", null),
			cfg.get("work_pos", Vector2(440, 44)),
			cfg.get("bed1_pos", _tavern_bed_pos),
			inh_st,
			cfg.get("table_pos", _tavern_social_pos),
			str(cfg.get("family_id", "none")),
			str(cfg.get("family_name", "Gremio"))
		)
		trade_npcs[role_key] = new_art
		arrivals_today_count += 1
		_hint_player("⚒️🚶 %s (%s Novato · 35%% Eficiencia) está entrando al valle desde el borde del mapa." % [new_art.npc_name, str(cfg.get("title", "Artesano"))])

	# Prioridad 4 (V3): ya no hay «siempre 3 viajeros»; llegan según el atractivo del pueblo (VillageMigration.daily)

## V8: quién se queda un negocio sin dueño. Puntúa ambición, diligencia y ahorros; un familiar de otra casa solo deja
## la suya si es ambicioso. Los otros ambiciosos que se quedan sin él le cogen algo de envidia.
## M13 «La herencia»: quién heredó, de quién y cuándo (para que los parientes puedan reclamar).
func _note_inheritance(heir: VillageNPC, dead: VillageNPC) -> void:
	heir.set_meta("inherited_day", WorldClock.current_day if WorldClock else 1)
	if is_instance_valid(dead):
		heir.set_meta("inherited_from", dead.npc_name)
		heir.set_meta("inherited_family", dead.family_id)

func _pick_ambitious_successor(_role_key, title: String) -> VillageNPC:
	var best: VillageNPC = null
	var best_s: float = -INF
	var rivals: Array = []
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if not (n is VillageNPC) or n.is_dead or n.is_downed or VillageNeeds.is_outsider(n) or n.person_profile == null or int(n.person_profile.age) < 16:
			continue
		if n.get_person_key() == VillageFamilia.INITIAL_BOSS_ID or VillageFamilia.boss_of(self) == n:
			continue
		var amb: float = TraitCatalog.npc_tendency(n, "ambition")
		if n.trade_role == VillageNPC.TradeRole.FAMILY_MEMBER:
			if amb < 0.5:
				continue
		elif n.trade_role != VillageNPC.TradeRole.UNEMPLOYED:
			continue
		var sc: float = 1.2 * amb + 0.4 * TraitCatalog.npc_tendency(n, "diligence") + float(n.personal_gold) / 150.0
		if amb >= 0.5:
			rivals.append(n)
		if sc > best_s:
			best_s = sc
			best = n
	if best == null or (best.trade_role == VillageNPC.TradeRole.UNEMPLOYED and TraitCatalog.npc_tendency(best, "ambition") < 0.5):
		return null # Sin nadie ambicioso: sigue la regla de siempre (el primero sin oficio)
	unemployed_npcs.erase(best)
	for fk in family_npcs.keys():
		if family_npcs[fk] == best:
			family_npcs.erase(fk)
			break
	for r in rivals:
		if r != best:
			r.modify_npc_relationship(best, -6, "Se quedó el taller que yo quería", true)
	var d: Dictionary = VillageDesires.active_of(self, best.get_person_key())
	if not d.is_empty() and str(d.get("type", "")) == "ambition":
		VillageDesires.finish(self, d, "satisfied")
	best.add_thought("¡Por fin un negocio propio! (+12)", 12.0)
	VillageChronicle.add(self, "ambition_business", "%s, con ganas de prosperar, se quedó el puesto vacante de %s" % [best.npc_name, title], true)
	return best

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
	_add_station_area("ShopBusinessStall_%d" % role_id, stall_pos, 18.0, "shop_business_stall")
	var lbl := _make_station_label(stall_pos + Vector2(-130, 14), "📜 %s [E: Gestionar Negocio | F: Sabotear]" % shop_title)
	lbl.custom_minimum_size = Vector2(260, 26)
	entities_root.add_child(lbl)

	var sup_items: Array[String] = []
	match role_id:
		int(VillageNPC.TradeRole.BLACKSMITH): sup_items = ["iron_ore", "stone", "steel_ingot", "repair_kit", "bandit_scrap"]
		int(VillageNPC.TradeRole.BUTCHER): sup_items = ["cooked_meat", "raw_meat", "roasted_chicken", "raw_chicken", "leather", "fox_pelt", "antlers"]
		int(VillageNPC.TradeRole.CARPENTER): sup_items = ["wood", "repair_kit", "copper_coil"]
		int(VillageNPC.TradeRole.FISHMONGER): sup_items = ["bread", "cooked_fish", "river_trout", "golden_carp", "night_catfish", "wheat", "fertilizer"]
		int(VillageNPC.TradeRole.HERBALIST): sup_items = ["herbal_poultice", "herbs", "mushroom", "carrot", "cabbage", "sleeping_draught", "surgical_kit"]
		int(VillageNPC.TradeRole.BAKER): sup_items = ["bread", "wheat"]
		int(VillageNPC.TradeRole.TAILOR): sup_items = ["clothes", "leather", "fox_pelt"]
		int(VillageNPC.TradeRole.LODGEKEEPER): sup_items = ["country_stew", "cooked_meat"]
		int(VillageNPC.TradeRole.RESTAURATEUR): sup_items = ["pasta_dish", "braised_meat"]
		_: sup_items = VillageTrades.supply_items_for(role_id) # V5d

	var cfg: Dictionary = trade_configs.get(role_id, {})
	var init_stock: Dictionary = (cfg.get("stock", {}) as Dictionary).duplicate()
	shop_businesses[role_id] = {
		"role": role_id, "family_id": fam_id, "title": shop_title, "stall_pos": stall_pos, "stall_sprite": stall_spr,
		"stall_label": lbl, "owner_mode": "NPC", "vault_gold": 0, "sabotaged_days": 0, "sabotaged_today_day": -1,
		"supply_items": sup_items, "stock_override": init_stock
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

func _update_shop_business_stalls(_player: Node2D, _mouse_pos: Vector2) -> void:
	for r_id in shop_businesses.keys():
		var role_int: int = int(r_id)
		_sync_shop_sabotage_fx_2d(role_int)
		var biz: Dictionary = shop_businesses[role_int]
		var lbl: Label = biz.get("stall_label")
		if is_instance_valid(lbl):
			lbl.visible = false

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
	_sync_shop_sabotage_fx_2d(role_id)

## B4.2: Taller saboteado echa humo y chispas en 2D hasta que se repara; si hay fuego fuera, la lluvia ayuda a apagarlo.
func _sync_shop_sabotage_fx_2d(role_id: int) -> void:
	if not shop_businesses.has(role_id):
		return
	var biz: Dictionary = shop_businesses[role_id]
	var sab_d: int = int(biz.get("sabotaged_days", 0))
	var existing: Node2D = biz.get("sabotage_fx_2d") as Node2D if is_instance_valid(biz.get("sabotage_fx_2d")) else null
	if sab_d <= 0:
		biz["outdoor_fire"] = false
		biz["fire_intensity"] = 0.0
		biz["rain_helped_day"] = -1
		if existing != null:
			existing.queue_free()
		biz.erase("sabotage_fx_2d")
		return
	var raining: bool = WorldClock != null and int(WorldClock.current_weather) == 1
	if not biz.has("outdoor_fire"):
		biz["outdoor_fire"] = not raining
		biz["fire_intensity"] = 0.25 if raining else 1.0
	if raining and (biz.get("outdoor_fire") == true or float(biz.get("fire_intensity", 0.0)) > 0.25):
		biz["outdoor_fire"] = false
		biz["fire_intensity"] = 0.20
		var cur_d: int = int(WorldClock.current_day) if WorldClock else 1
		if sab_d > 1 and int(biz.get("rain_helped_day", -1)) != cur_d:
			biz["rain_helped_day"] = cur_d
			biz["sabotaged_days"] = maxi(1, sab_d - 1)
	if existing == null:
		existing = Node2D.new()
		existing.name = "SabotageFX2D_%d" % role_id
		existing.position = (biz.get("stall_pos", Vector2.ZERO) as Vector2) + Vector2(0.0, -10.0)
		existing.z_index = 28
		var smoke := CPUParticles2D.new()
		smoke.name = "Smoke2D"
		smoke.amount = 14
		smoke.lifetime = 1.35
		smoke.direction = Vector2(0.15, -1.0)
		smoke.spread = 28.0
		smoke.initial_velocity_min = 10.0
		smoke.initial_velocity_max = 22.0
		smoke.gravity = Vector2(4.0, -12.0)
		smoke.scale_amount_min = 2.2
		smoke.scale_amount_max = 4.2
		smoke.color = Color(0.24, 0.24, 0.26, 0.72)
		smoke.emitting = true
		existing.add_child(smoke)
		var sparks := CPUParticles2D.new()
		sparks.name = "Sparks2D"
		sparks.amount = 10
		sparks.lifetime = 0.45
		sparks.explosiveness = 0.35
		sparks.direction = Vector2(0.0, -1.0)
		sparks.spread = 65.0
		sparks.initial_velocity_min = 24.0
		sparks.initial_velocity_max = 52.0
		sparks.gravity = Vector2(0.0, 95.0)
		sparks.scale_amount_min = 1.2
		sparks.scale_amount_max = 2.2
		sparks.color = Color(1.0, 0.78, 0.25, 0.95)
		sparks.emitting = true
		existing.add_child(sparks)
		var fire := CPUParticles2D.new()
		fire.name = "Fire2D"
		fire.amount = 12
		fire.lifetime = 0.55
		fire.direction = Vector2(0.0, -1.0)
		fire.spread = 32.0
		fire.initial_velocity_min = 8.0
		fire.initial_velocity_max = 18.0
		fire.gravity = Vector2(0.0, -24.0)
		fire.scale_amount_min = 2.0
		fire.scale_amount_max = 3.6
		fire.color = Color(1.0, 0.42, 0.12, 0.88)
		fire.emitting = biz.get("outdoor_fire") == true
		existing.add_child(fire)
		add_child(existing)
		biz["sabotage_fx_2d"] = existing
	else:
		existing.position = (biz.get("stall_pos", Vector2.ZERO) as Vector2) + Vector2(0.0, -10.0)
		var fire_node := existing.get_node_or_null("Fire2D") as CPUParticles2D
		if fire_node != null:
			fire_node.emitting = biz.get("outdoor_fire") == true

func extinguish_outdoor_fires_from_rain() -> int:
	var count: int = 0
	for r_id in shop_businesses.keys():
		var role_int: int = int(r_id)
		var biz: Dictionary = shop_businesses[role_int]
		if int(biz.get("sabotaged_days", 0)) > 0 and (biz.get("outdoor_fire") == true or float(biz.get("fire_intensity", 0.0)) > 0.25):
			count += 1
		_sync_shop_sabotage_fx_2d(role_int)
	return count

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
	var food_roles: Array[int] = [int(VillageNPC.TradeRole.BAKER), int(VillageNPC.TradeRole.FISHMONGER), int(VillageNPC.TradeRole.BUTCHER), int(VillageNPC.TradeRole.HERBALIST)]
	if npc.trade_role == VillageNPC.TradeRole.BUTCHER:
		food_roles = [int(VillageNPC.TradeRole.BUTCHER), int(VillageNPC.TradeRole.BAKER), int(VillageNPC.TradeRole.FISHMONGER), int(VillageNPC.TradeRole.HERBALIST)]
	if near_tavern:
		food_roles.clear()

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
						# Regla 1: tu parte sale de lo que el vecino acaba de pagar al artesano, no del aire.
						sale_gold = mini(sale_gold, maxi(0, holder.personal_gold))
						holder.personal_gold -= sale_gold
						biz["vault_gold"] = int(biz.get("vault_gold", 0)) + sale_gold
				_refresh_shop_stall_visual(r_id)
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

	# J4: último recurso, las gachas del albergue
	if VillageCivic.take_shelter_ration(self, npc):
		return true

	# ¡Escasez o falta de dinero! El NPC no pudo comprar comida y recurrirá a cazar/recolectar torpemente en el bosque
	village_food_shortage_days += 1
	VillageMigration.note_meal_failure(self, npc)
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
	# Regla 1: ya no hay «ganancia base» del aire; la caja solo crece con ventas que paga un vecino de su bolsillo.
	var earned_today: int = 0

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
			var unit_val: int = 12 if owner_mode == "SOLE_OWNER" else 8
			var unit_price: int = maxi(1, int(round(float(unit_val) * mkt_mult * eff)))
			var sold_now: int = 0
			for _u in range(sell_cnt):
				var buyer: VillageNPC = _find_paying_customer(unit_price, holder)
				if buyer == null:
					break
				buyer.personal_gold -= unit_price
				earned_today += unit_price
				sold_now += 1
			if sold_now <= 0:
				break
			st[item_k] = avail - sold_now
			items_sold += sold_now

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
		_msg_player(player, "🔧💥 Este taller ya fue saboteado hoy", Color.GOLD, -42.0)
		return

	biz["sabotaged_days"] = 2
	biz["sabotaged_today_day"] = cur_day
	recent_breakins_count += 1
	_refresh_shop_stall_visual(role_id)

	var st: Dictionary = get_trade_stock_dict(role_id)
	for k in st.keys():
		st[k] = int(floor(float(st[k]) * 0.4))

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
		_msg_player(player, "💣🤫 ¡Sabotaje industrial en sigilo! %s averiado (+1 %s | Precios a 2.25x)" % [b_title, loot_name], Color.SPRING_GREEN, -46.0)
		_hint_player("💣 Has saboteado %s sin testigos: su producción se detiene 2 días, sus precios suben al 225%% y puedes comprar su escritura en liquidación (65 Oro)." % b_title, player)
	else:
		wanted_level = clampi(wanted_level + 1, 1, 5)
		bounty_gold += 35
		var fam_id: String = str(biz.get("family_id", "none"))
		modify_family_reputation(fam_id, -40, "Sabotaje del taller visto por " + witness.npc_name)
		var msg := "🚨👁️ ¡%s te vio sabotear %s! (+35 Oro de multa policial)" % [witness.npc_name, b_title]
		crime_history.push_front(msg)
		_notify_inquisitor_of_police_crime(msg, 22)
		_msg_player(player, msg, Color.ORANGE_RED, -46.0)

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
			pay_into(holder if holder_alive else null, buyout_cost) # Regla 1: al titular, o a las arcas si no hay
			biz["owner_mode"] = "SOLE_OWNER"
			_refresh_shop_stall_visual(_active_business_role)
			player._spawn_floating_text("👑📜 ¡Adquiriste el 100%% de %s en liquidación! (-%d Oro)" % [b_title, buyout_cost], Color.GOLD, -46.0)
		else:
			var partner_cost: int = 85 if fam_aff >= 45 else 110
			if inv.gold < partner_cost:
				player._spawn_floating_text("❌ Necesitas %d Oro para comprar acciones de Socio" % partner_cost, Color.ORANGE_RED, -42.0)
				return
			inv.add_gold(-partner_cost)
			pay_into(holder if holder_alive else null, partner_cost) # Regla 1: compras su parte al titular
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
		var holder_up: VillageNPC = trade_npcs.get(_active_business_role)
		pay_into(holder_up if is_instance_valid(holder_up) and not holder_up.is_dead else null, up_cost) # Regla 1
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
			# Regla 1: en un negocio ajeno te paga el titular de su bolsillo; si no tiene, no te compra.
			if not (owner_mode in ["PARTNER", "SOLE_OWNER"]):
				var holder_pay: VillageNPC = trade_npcs.get(_active_business_role)
				var want_pay: int = maxi(6, int(round(9.0 * mkt_mult)))
				if not is_instance_valid(holder_pay) or holder_pay.is_dead or holder_pay.personal_gold < want_pay:
					player._spawn_floating_text("📦❌ El dueño no tiene %d Oro para pagarte la mercancía ahora" % want_pay, Color.ORANGE_RED, -44.0)
					return
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
				var holder_paying: VillageNPC = trade_npcs.get(_active_business_role)
				holder_paying.personal_gold -= instant_pay
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
	pay_into(candidate, 30) # Regla 1: la prima de contratación es para el encargado (o las arcas si llega uno nuevo)

	if candidate != null:
		candidate.promote_to_trade(_active_business_role as VillageNPC.TradeRole, str(cfg.get("title", "Artesano")), cfg.get("work_pos", biz.get("stall_pos", Vector2.ZERO)), get_trade_stock_dict(_active_business_role), cfg.get("tex", null), cfg.get("bed1_pos", Vector2.ZERO), cfg.get("table_pos", Vector2.ZERO), str(cfg.get("family_id", "none")), str(cfg.get("family_name", "Gremio")))
		trade_npcs[_active_business_role] = candidate
		if family_npcs.get(_active_business_role) == candidate:
			family_npcs.erase(_active_business_role)
		_msg_player(player, "🤝⚒️ ¡Contrataste a %s (%s) como encargado de %s! (-30 Oro)" % [candidate.npc_name, candidate.get_job_efficiency_label(), str(biz.get("title", ""))], Color.SPRING_GREEN, -46.0)
	else:
		arrivals_today_count += 1
		var hired_npc: VillageNPC = _spawn_generated_newcomer(
			"NPC_Hired_Artisan_",
			_active_business_role as VillageNPC.TradeRole,
			_active_business_role as VillageNPC.TradeRole,
			str(cfg.get("title", "Encargado")) + " (Contratado)",
			cfg.get("tex", null),
			cfg.get("work_pos", biz.get("stall_pos", Vector2.ZERO)),
			cfg.get("bed1_pos", _tavern_bed_pos),
			get_trade_stock_dict(_active_business_role),
			cfg.get("table_pos", _tavern_social_pos),
			str(cfg.get("family_id", "none")),
			str(cfg.get("family_name", "Gremio"))
		)
		trade_npcs[_active_business_role] = hired_npc
		_msg_player(player, "🤝🚶 ¡Contrataste a %s (Novato 35%%)! Ya viene caminando desde el borde del mapa (-30 Oro)" % hired_npc.npc_name, Color.SPRING_GREEN, -46.0)

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
			pay_into(role_npc(int(VillageNPC.TradeRole.CARPENTER)), 12) # Regla 1: cobra el carpintero
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
	# 1. Sueldo institucional diario para el Médico Forense y la Policía (14–18 Oro/día; si las arcas superan 250, aportan 8 de oro por agente)
	for auth in authority_npcs:
		if is_instance_valid(auth) and not auth.is_dead and not auth.is_downed:
			var salary: int = 18 if auth.trade_role == VillageNPC.TradeRole.SHERIFF else (16 if auth.trade_role == VillageNPC.TradeRole.DOCTOR else 14)
			# Regla 1: el sueldo entero sale de las arcas; si están vacías, cobran lo que haya.
			salary = take_from_treasury(salary)
			if salary <= 0:
				continue
			auth.personal_gold += salary
			auth._spawn_floating_text("💰+%d Oro (Salario)" % salary, Color.GOLD, -30.0)

	# 2. Demanda Cruzada entre Gremios: los comercios de comida y la Posada compran afilado/cuchillos/anzuelos
	# al Herrero (`Thoran`) y leña/barriles/reparaciones al Carpintero (`Bram`) para que el oro circule de vuelta.
	var smith_npc: VillageNPC = trade_npcs.get(int(VillageNPC.TradeRole.BLACKSMITH))
	var carp_npc: VillageNPC = trade_npcs.get(int(VillageNPC.TradeRole.CARPENTER))
	var food_sellers: Array[VillageNPC] = []
	for r_food in [int(VillageNPC.TradeRole.BUTCHER), int(VillageNPC.TradeRole.FISHMONGER), int(VillageNPC.TradeRole.HERBALIST), int(VillageNPC.TradeRole.BAKER)]:
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
				# Regla 1: el jornal lo paga un taller que tenga oro (el que más tenga); si nadie puede, no hay jornal.
				var employer: VillageNPC = null
				var employers: Array = []
				employers.append_array(food_sellers)
				employers.append(smith_npc)
				employers.append(carp_npc)
				for emp in employers:
					if is_instance_valid(emp) and not emp.is_dead and emp.personal_gold >= wage and (employer == null or emp.personal_gold > employer.personal_gold):
						employer = emp
				if employer == null:
					continue
				employer.personal_gold -= wage
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
		if VillageMigration.nightly(self, guest): # V3: vive en una casa, no paga posada
			continue
		if VillageCivic.nightly_guest(self, guest, rent_cost): # V5b: El Candil, más barata
			continue
		# Si ya era vagabundo pero ha ahorrado >= 18 Oro y la Posada está abierta, recupera su cama bajo techo
		if guest.is_vagrant_camper and not tav_blocked and inn_alive and guest.personal_gold >= 18:
			guest.personal_gold -= rent_cost
			_innkeeper_npc.personal_gold += rent_cost
			guest.is_vagrant_camper = false
			guest.in_shelter = false
			guest.lodging = ""
			var guest_beds: Array[Vector2] = [Vector2(435, -252), Vector2(468, -252), Vector2(502, -252)]
			var free_b = VillageMigration.free_tavern_bed(self) # E3: cama libre, no la que toque por el nombre
			guest.bed_position = free_b if free_b != null else guest_beds[abs(guest.npc_name.hash()) % guest_beds.size()]
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
	if npc.in_shelter or VillageCivic.try_shelter(self, npc): # V5b: antes que a la intemperie, el Albergue del Alba
		return
	var camp_spots: Array[Vector2] = [Vector2(360, 345), Vector2(412, 355), Vector2(522, 348), Vector2(310, 348)]
	var c_pos: Vector2 = camp_spots[abs(npc.npc_name.hash()) % camp_spots.size()]
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

	_add_poly(PackedVector2Array([Vector2(-18, -10), Vector2(18, -10), Vector2(20, 12), Vector2(-20, 12)]), Color(0.36, 0.27, 0.18, 0.72), -2, Vector2.ZERO, camp_root)
	_add_poly(PackedVector2Array([Vector2(-15, 4), Vector2(-6, -11), Vector2(4, 4)]), Color(0.56, 0.46, 0.32, 0.95), 0, Vector2.ZERO, camp_root)
	_add_poly(PackedVector2Array([Vector2(-6, 1), Vector2(8, 1), Vector2(8, 7), Vector2(-6, 7)]), Color(0.45, 0.52, 0.36, 0.95), -1, Vector2.ZERO, camp_root)
	_add_poly(PackedVector2Array([Vector2(10, -2), Vector2(15, -5), Vector2(18, 0), Vector2(14, 4)]), Color(1.0, 0.58, 0.18, 0.88), 1, Vector2.ZERO, camp_root)
	_add_title_label(Vector2(-110, -26), Vector2(220, 16), "⛺ Campamento Rústico de %s (Intemperie: Sueño máx. 74%%)" % npc.npc_name, Color(1.0, 0.80, 0.52), 7, camp_root)

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
		var emb_name: String = "Maese Casimir" if m_id == "casimir" else "Valeria la Tratante"
		_hint_player("🚫⚖️ Ruta Comercial Suspendida: %s NO ha venido hoy al pueblo por el asesinato previo (Quedan %d días de embargo económico)." % [emb_name, susp_left])
		return

	if not ignore_suspension:
		for existing_m in get_tree().get_nodes_in_group("village_npcs"):
			if existing_m is VillageNPC and (existing_m as VillageNPC).merchant_id == m_id and (existing_m as VillageNPC).is_dead and not (existing_m as VillageNPC).corpse_buried:
				return

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
		m_npc.personal_gold = randi_range(168, 196)
		m_npc.set_meta("initial_budget", m_npc.personal_gold)
		m_npc.set_meta("route_Bought_smith", false)
		m_npc.set_meta("route_Bought_carp", false)
		entities_root.add_child(m_npc)
		m_npc.setup_npc(_load_tex("res://assests/world/village/npcs_64/sprite_casimir.png"), Vector2(335, 12), Vector2(-900, 48), {"royal_ration": 3, "steel_ingot": 3, "copper_coil": 2, "repair_kit": 3}, _tavern_social_pos, "none", "Comitiva Real de Extramuros")
	else:
		m_npc.name = "NPC_Merchant_Valeria"
		m_npc.npc_name = "Valeria la Tratante"
		m_npc.npc_role = "Tratante de Caza y Pieles"
		m_npc.personal_gold = randi_range(214, 248)
		m_npc.set_meta("initial_budget", m_npc.personal_gold)
		m_npc.set_meta("route_Bought_butcher", false)
		m_npc.set_meta("route_Bought_fish", false)
		m_npc.set_meta("route_Bought_herb", false)
		entities_root.add_child(m_npc)
		m_npc.setup_npc(_load_tex("res://assests/world/village/npcs_64/sprite_valeria.png"), Vector2(585, 12), Vector2(990, 48), {"royal_ration": 4, "surgical_kit": 2, "sleeping_draught": 2}, _tavern_social_pos, "none", "Comitiva Real de Extramuros")

	m_npc.global_position = Vector2(-900, 48) if m_id == "casimir" else Vector2(990, 48)
	_active_traveling_merchant = m_npc

	if not silent:
		_hint_player("🐎👑 ¡Ha llegado %s (%s) con %d Oro y Salvoconducto Real! Comprará producción local hasta las 19:00." % [m_npc.npc_name, m_npc.npc_role, m_npc.personal_gold])

## IA física de los 2 Mercaderes Semanales: recorren las tiendas de su especialidad comprando solo lo que hay en stock
## (inyectando oro externo real a los artesanos y cazadores) y se marchan por el camino principal a las 19:00.
func update_traveling_merchant_ai(merchant: VillageNPC, delta: float) -> void:
	if merchant == null or merchant.is_dead or merchant.is_downed:
		return
	var h: int = WorldClock.current_hour if WorldClock else 12
	var m_id: String = merchant.merchant_id
	if m_id in ["high_pass", "river_port", "sun_plain"]:
		VillageCulture.update_caravan_merchant_ai(self, merchant, delta)
		return
	if m_id == "smuggler":
		VillageUnderworld.update_smuggler_merchant_ai(self, merchant, delta)
		return

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

## ==============================================================================
## BLOQUE 3 Y 4: CHARCOS DE SANGRE, HUELLAS DIRECCIONALES Y MOTOR DETECTIVESCO EN CADENA
## ==============================================================================
func spawn_blood_puddle(pos: Vector2, victim_name: String = "") -> void:
	if not is_instance_valid(entities_root):
		return
	for existing in blood_puddles:
		var ex_pos: Vector2 = existing.get("pos", Vector2.ZERO)
		if ex_pos.distance_to(pos) <= 20.0:
			if victim_name != "":
				existing["victim_name"] = victim_name
			return
	var pts := PackedVector2Array([
		Vector2(-9, -4), Vector2(-4, -8), Vector2(4, -7), Vector2(10, -3),
		Vector2(8, 5), Vector2(2, 8), Vector2(-6, 7), Vector2(-10, 2)
	])
	var puddle_poly := _add_poly(pts, Color(0.56, 0.04, 0.06, 0.84), -2, pos)
	var cur_d: int = WorldClock.current_day if WorldClock else 1
	var cur_h: int = WorldClock.current_hour if WorldClock else 12
	var cur_m: int = WorldClock.current_minute if WorldClock else 0
	blood_puddles.append({
		"pos": pos,
		"victim_name": victim_name,
		"node": puddle_poly,
		"footprint_nodes": [],
		"flee_dir": Vector2.ZERO,
		"flee_compass": "",
		"last_stepper": "",
		"created_mins": cur_d * 1440 + cur_h * 60 + cur_m
	})

func update_entity_blood_footprints(entity: Node2D, _delta: float) -> void:
	if entity == null or not is_instance_valid(entities_root) or blood_puddles.is_empty():
		return
	var steps_left: int = int(entity.get_meta("bloody_steps_left", 0)) if entity.has_meta("bloody_steps_left") else 0
	var ent_pos: Vector2 = entity.global_position
	if steps_left <= 0:
		for i in range(blood_puddles.size()):
			var pud: Dictionary = blood_puddles[i]
			var p_pos: Vector2 = pud.get("pos", Vector2.ZERO)
			if ent_pos.distance_squared_to(p_pos) <= 16.0 * 16.0:
				entity.set_meta("bloody_steps_left", 6)
				entity.set_meta("bloody_last_step_pos", ent_pos)
				entity.set_meta("bloody_puddle_idx", i)
				entity.set_meta("bloody_origin_pos", p_pos)
				if entity.has_method("add_bloodstain"):
					entity.call("add_bloodstain", 180.0)
				break
		return

	var last_pos: Vector2 = entity.get_meta("bloody_last_step_pos", ent_pos) as Vector2
	if ent_pos.distance_squared_to(last_pos) < 15.0 * 15.0:
		return

	steps_left -= 1
	entity.set_meta("bloody_steps_left", steps_left)
	entity.set_meta("bloody_last_step_pos", ent_pos)

	var origin_pos: Vector2 = entity.get_meta("bloody_origin_pos", last_pos) as Vector2
	var move_vec: Vector2 = ent_pos - origin_pos
	var flee_dir: Vector2 = move_vec.normalized() if move_vec.length_squared() > 1.0 else (ent_pos - last_pos).normalized()
	var alpha: float = clampf(0.28 + float(steps_left) * 0.09, 0.25, 0.82)
	var fp_pts := PackedVector2Array([Vector2(-2.2, -1.2), Vector2(2.2, -1.2), Vector2(2.2, 1.2), Vector2(-2.2, 1.2)])
	var fp_poly := _add_poly(fp_pts, Color(0.52, 0.04, 0.06, alpha), -2, ent_pos + Vector2(0, 5))
	fp_poly.rotation = flee_dir.angle()

	var p_idx: int = int(entity.get_meta("bloody_puddle_idx", -1))
	if p_idx >= 0 and p_idx < blood_puddles.size() and flee_dir.length_squared() > 0.01:
		var pud: Dictionary = blood_puddles[p_idx]
		pud["flee_dir"] = flee_dir
		pud["flee_compass"] = _describe_direction_and_landmark(origin_pos, flee_dir)
		var ent_name: String = "Jugador" if entity.is_in_group("player") else (str(entity.get("npc_name")) if "npc_name" in entity else str(entity.name))
		pud["last_stepper"] = ent_name
		var fp_arr: Array = pud.get("footprint_nodes", [])
		fp_arr.append(fp_poly)
		pud["footprint_nodes"] = fp_arr

func get_blood_puddle_clue_near(crime_pos: Vector2, max_radius: float = 95.0) -> Dictionary:
	var best_idx: int = -1
	var best_d2: float = max_radius * max_radius
	for i in range(blood_puddles.size()):
		var p_pos: Vector2 = blood_puddles[i].get("pos", Vector2.ZERO)
		var d2: float = crime_pos.distance_squared_to(p_pos)
		if d2 <= best_d2:
			best_d2 = d2
			best_idx = i
	return blood_puddles[best_idx] if best_idx >= 0 else {}

func _describe_direction_and_landmark(origin: Vector2, dir: Vector2) -> String:
	if dir.length_squared() <= 0.001:
		return "dirección indeterminada"
	var ang: float = rad_to_deg(dir.angle())
	var compass: String = "hacia el Este"
	if ang >= -22.5 and ang < 22.5: compass = "hacia el Este"
	elif ang >= 22.5 and ang < 67.5: compass = "hacia el Sureste"
	elif ang >= 67.5 and ang < 112.5: compass = "hacia el Sur"
	elif ang >= 112.5 and ang < 157.5: compass = "hacia el Suroeste"
	elif ang >= 157.5 or ang < -157.5: compass = "hacia el Oeste"
	elif ang >= -157.5 and ang < -112.5: compass = "hacia el Noroeste"
	elif ang >= -112.5 and ang < -67.5: compass = "hacia el Norte"
	elif ang >= -67.5 and ang < -22.5: compass = "hacia el Noreste"
	var sample_pt: Vector2 = origin + dir * 130.0
	var b_info: Dictionary = _get_building_at_pos(sample_pt)
	var b_title: String = str(b_info.get("title", ""))
	if b_title != "":
		return "%s (rumbo a %s)" % [compass, b_title]
	return compass

func _build_investigation_case_dict(victim: VillageNPC, crime_pos: Vector2, weapon_used: String, discoverer_name: String, max_interviews_cap: int, is_royal: bool, m_id: String = "", embargo_days: int = 0) -> Dictionary:
	return VillageJustice._build_investigation_case_dict(self, victim, crime_pos, weapon_used, discoverer_name, max_interviews_cap, is_royal, m_id, embargo_days)

func start_sheriff_investigation(victim: VillageNPC, death_pos: Vector2, weapon_name: String, discoverer_name: String, _death_mins: int = 0) -> void:
	VillageJustice.start_sheriff_investigation(self, victim, death_pos, weapon_name, discoverer_name, _death_mins)

func on_traveling_merchant_murdered(merchant: VillageNPC, cause_text: String = "") -> void:
	VillageJustice.on_traveling_merchant_murdered(self, merchant, cause_text)

func _get_investigation_crime_pos() -> Vector2:
	return VillageJustice._get_investigation_crime_pos(self)

func _notify_inquisitor_of_police_crime(clue_text: String, suspicion_boost: int) -> void:
	VillageJustice._notify_inquisitor_of_police_crime(self, clue_text, suspicion_boost)

func _spawn_royal_investigator() -> void:
	VillageJustice._spawn_royal_investigator(self)

func _advance_royal_investigation_day(_new_day: int) -> void:
	VillageJustice._advance_royal_investigation_day(self, _new_day)

func update_royal_investigator_ai(inv_npc: VillageNPC, delta: float) -> void:
	VillageJustice.update_royal_investigator_ai(self, inv_npc, delta)

func update_sheriff_investigator_ai(sheriff: VillageNPC, delta: float) -> bool:
	return VillageJustice.update_sheriff_investigator_ai(self, sheriff, delta)

func _process_inquisitor_field_recon(inv_npc: VillageNPC, delta: float, done_cnt: int, max_cnt: int, days_inv: int) -> void:
	VillageJustice._process_inquisitor_field_recon(self, inv_npc, delta, done_cnt, max_cnt, days_inv)

func _find_npc_by_name(target_name: String) -> VillageNPC:
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.npc_name == target_name and not v.is_dead:
				return v
	return null

func _cross_check_morgue_and_police_records(inv_npc: VillageNPC, suspects: Dictionary, clues: Array) -> void:
	VillageJustice._cross_check_morgue_and_police_records(self, inv_npc, suspects, clues)

func _inspect_crime_scene_and_footprints(inv_npc: VillageNPC, case_dict: Dictionary) -> void:
	VillageJustice._inspect_crime_scene_and_footprints(self, inv_npc, case_dict)

func _pick_next_neighbor_to_keep_chain_alive(inv_npc: VillageNPC, case_dict: Dictionary) -> String:
	return VillageJustice._pick_next_neighbor_to_keep_chain_alive(self, inv_npc, case_dict)

func _process_case_chain_interviews_step(inv_npc: VillageNPC, delta: float, case_dict: Dictionary, is_royal: bool) -> void:
	VillageJustice._process_case_chain_interviews_step(self, inv_npc, delta, case_dict, is_royal)

func _evaluate_npc_interview(inv_npc: VillageNPC, witness: VillageNPC, suspects: Dictionary, clues: Array, case_dict: Dictionary = {}) -> void:
	VillageJustice._evaluate_npc_interview(self, inv_npc, witness, suspects, clues, case_dict)

func _evaluate_player_inspection(inv_npc: VillageNPC, player: Node2D, suspects: Dictionary, clues: Array, is_initial_interview: bool = false, case_dict: Dictionary = {}) -> void:
	VillageJustice._evaluate_player_inspection(self, inv_npc, player, suspects, clues, is_initial_interview, case_dict)

func resolve_player_interrogation_outcome(inv_npc: VillageNPC, player: Node2D, outcome_mode: String, correct_steps: int, penalty_acc: int) -> void:
	VillageJustice.resolve_player_interrogation_outcome(self, inv_npc, player, outcome_mode, correct_steps, penalty_acc)

func _conclude_sheriff_investigation_verdict(sheriff: VillageNPC) -> void:
	VillageJustice._conclude_sheriff_investigation_verdict(self, sheriff)

func _check_and_start_next_morgue_sheriff_case() -> void:
	VillageJustice._check_and_start_next_morgue_sheriff_case(self)

func resolve_public_trial_intervention(inv_npc: VillageNPC, player: Node2D, mode: String) -> void:
	VillageJustice.resolve_public_trial_intervention(self, inv_npc, player, mode)

func _conclude_royal_investigation_with_mandatory_verdict(inv_npc: VillageNPC) -> void:
	VillageJustice._conclude_royal_investigation_with_mandatory_verdict(self, inv_npc)

func get_royal_investigator_status_text() -> String:
	return VillageJustice.get_royal_investigator_status_text(self)

func get_royal_investigation_dialogue_summary() -> String:
	return VillageJustice.get_royal_investigation_dialogue_summary(self)

func get_royal_investigation_detailed_suspects_text() -> String:
	return VillageJustice.get_royal_investigation_detailed_suspects_text(self)

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
					if en.visible and en.get("is_dead") != true and en.get("is_dead_flag") != true and en.get("is_downed") != true and en.global_position.distance_squared_to(t_pos) <= 16.0 * 16.0:
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
			"owner_mode": str(biz.get("owner_mode", "NPC")), "vault_gold": int(biz.get("vault_gold", 0)),
			"sabotaged_days": int(biz.get("sabotaged_days", 0)), "sabotaged_today_day": int(biz.get("sabotaged_today_day", -1)),
			"stock_override": get_trade_stock_dict(role_int).duplicate()
		}
	var saved_merchant: Dictionary = _active_traveling_merchant.to_save_dict() if (is_instance_valid(_active_traveling_merchant) and not _active_traveling_merchant.is_dead) else {}
	var saved_investigator: Dictionary = _royal_investigator_npc.to_save_dict() if (is_instance_valid(_royal_investigator_npc) and not _royal_investigator_npc.is_dead) else {}
	var saved_pets: Array[Dictionary] = []
	for p in domestic_pets:
		if is_instance_valid(p) and p.has_method("to_save_dict"):
			saved_pets.append(p.to_save_dict())
	var saved_chests: Dictionary = {}
	for ch in house_chests:
		var ch_id: String = str(ch.get("title", ch.get("family_id", ch.get("id", ""))))
		if ch_id != "":
			saved_chests[ch_id] = {
				"looted_day": int(ch.get("looted_day", -1)),
				"planted_evidence": str(ch.get("planted_evidence", ""))
			}
	var saved_doors: Dictionary = {}
	for d_entry in building_doors:
		var d_id: String = str(d_entry.get("building_id", d_entry.get("id", "")))
		if d_id != "":
			saved_doors[d_id] = {
				"is_open": bool(d_entry.get("is_open", false)), "is_locked": bool(d_entry.get("is_locked", false)),
				"locked_by_player": bool(d_entry.get("locked_by_player", false)), "manual_override_timer": float(d_entry.get("manual_override_timer", 0.0)),
				"picked_until_hour": int(d_entry.get("picked_until_hour", -1)), "picked_day": int(d_entry.get("picked_day", -1))
			}
	var saved_windows: Dictionary = {}
	for w_entry in building_windows:
		var w_id: String = str(w_entry.get("building_id", w_entry.get("id", "")))
		if w_id != "":
			saved_windows[w_id] = {
				"is_shuttered": bool(w_entry.get("is_shuttered", false)), "manual_override_timer": float(w_entry.get("manual_override_timer", 0.0)),
				"picked_until_hour": int(w_entry.get("picked_until_hour", -1)), "picked_day": int(w_entry.get("picked_day", -1))
			}
	var saved_traps: Array[Dictionary] = []
	for trap_entry in _deployed_bear_traps:
		var tr_node: Node2D = trap_entry.get("node") as Node2D
		if is_instance_valid(tr_node):
			saved_traps.append({"x": tr_node.global_position.x, "y": tr_node.global_position.y})
	return {
		"businesses": out, "village_food_shortage_days": village_food_shortage_days, "house_pantry": house_pantry.duplicate(),
		"merchant_suspension_days": merchant_suspension_days.duplicate(), "active_royal_investigation": active_royal_investigation.duplicate(true),
		"active_sheriff_investigation": active_sheriff_investigation.duplicate(true),
		"active_traveling_merchant": saved_merchant, "royal_investigator_npc": saved_investigator, "domestic_pets": saved_pets,
		"player_arrests_count": player_arrests_count, "player_murder_warrants_count": player_murder_warrants_count,
		"recent_breakins_count": recent_breakins_count, "crime_history": crime_history.duplicate(), "arrivals_today_count": arrivals_today_count,
		"rehire_counter": _rehire_counter, "house_chests": saved_chests, "building_doors": saved_doors,
		"building_windows": saved_windows, "deployed_bear_traps": saved_traps,
		"used_first_names": _used_first_names.duplicate(),
		"used_person_ids": _used_person_ids.keys(),
		"newcomer_rng_state": _newcomer_rng.state,
		"social_event_log": social_event_log.duplicate(true),
		"chronicle": chronicle.duplicate(true),
		"chronicle_tiers": chronicle_tiers.duplicate(),
		"secrets": secrets.duplicate(true),
		"secret_uid": secret_uid,
		"desires": desires.duplicate(true),
		"desire_uid": desire_uid,
		"desire_hate_since": desire_hate_since.duplicate(),
		"npc_murders": npc_murders.duplicate(),
		"last_npc_murder_day": last_npc_murder_day,
		"faith_state": faith_state.duplicate(true),
		"needs_state": needs_state.duplicate(true),
		"town_state": town_state.duplicate(true),
		"lots_state": lots_state.duplicate(true),
		"places_state": places_state.duplicate(true),
		"culture_state": culture_state.duplicate(true),
		"migration_state": migration_state.duplicate(true),
		"nobility_state": nobility_state.duplicate(true),
		"family_state": family_state.duplicate(true),
		"work_state": work_state.duplicate(true),
		"sect_state": sect_state.duplicate(true),
		"player_elevation_level": player_elevation_level,
		"social_event_uid": _social_event_uid,
		"social_director": social_director.to_save_dict() if social_director != null else {}
	}

func _free_transient_npc(npc: VillageNPC) -> void:
	if not is_instance_valid(npc):
		return
	npc.remove_from_group("village_npcs")
	npc.remove_from_group("npcs")
	npc.name = "_freed_npc_" + str(npc.get_instance_id())
	if npc.get_parent():
		npc.get_parent().remove_child(npc)
	npc.queue_free()

## B4: el JSON del guardado convierte cada `Vector2` en el texto «(x, y)»; aquí se devuelven a `Vector2` dentro de los
## estados del pueblo (solo valores, nunca claves; un texto normal no tiene esa forma).
static var _vec_re: RegEx = null
static func revive_vectors(v):
	if v is Dictionary:
		for k in (v as Dictionary).keys():
			v[k] = revive_vectors(v[k])
		return v
	if v is Array:
		for i in range((v as Array).size()):
			v[i] = revive_vectors(v[i])
		return v
	if v is String and (v as String).begins_with("(") and (v as String).ends_with(")"):
		if _vec_re == null:
			_vec_re = RegEx.new()
			_vec_re.compile("^\\((-?(?:[0-9.]+(?:e[-+]?[0-9]+)?|inf)), (-?(?:[0-9.]+(?:e[-+]?[0-9]+)?|inf))\\)$")
		var m: RegExMatch = _vec_re.search(v)
		if m != null:
			return Vector2(float(m.get_string(1)), float(m.get_string(2)))
	return v

func load_economy_save_dict(data: Dictionary) -> void:
	for st_key in ["needs_state", "town_state", "lots_state", "places_state", "work_state", "culture_state", "migration_state", "nobility_state", "family_state", "faith_state"]:
		if typeof(data.get(st_key)) == TYPE_DICTIONARY:
			revive_vectors(data[st_key])
	village_food_shortage_days = int(data.get("village_food_shortage_days", 0))
	player_arrests_count = int(data.get("player_arrests_count", 0))
	player_murder_warrants_count = int(data.get("player_murder_warrants_count", 0))
	recent_breakins_count = int(data.get("recent_breakins_count", 0))
	arrivals_today_count = int(data.get("arrivals_today_count", 0))
	_rehire_counter = maxi(_rehire_counter, int(data.get("rehire_counter", _rehire_counter)))
	if data.has("used_first_names") and typeof(data["used_first_names"]) == TYPE_ARRAY:
		for fn_it in (data["used_first_names"] as Array):
			var fn_s: String = str(fn_it)
			if fn_s != "" and not (fn_s in _used_first_names):
				_used_first_names.append(fn_s)
	if data.has("used_person_ids") and typeof(data["used_person_ids"]) == TYPE_ARRAY:
		for pid_it in (data["used_person_ids"] as Array):
			var pid_s: String = str(pid_it)
			if pid_s != "":
				_used_person_ids[pid_s] = true
	if data.has("newcomer_rng_state"):
		_newcomer_rng.state = int(data["newcomer_rng_state"])
	if data.has("social_event_log") and typeof(data["social_event_log"]) == TYPE_ARRAY:
		social_event_log.clear()
		for ev_it in (data["social_event_log"] as Array):
			if typeof(ev_it) == TYPE_DICTIONARY:
				social_event_log.append((ev_it as Dictionary).duplicate())
		while social_event_log.size() > MAX_SOCIAL_EVENT_LOG:
			social_event_log.remove_at(0)
	_social_event_uid = int(data.get("social_event_uid", social_event_log.size()))
	chronicle_tiers = (data["chronicle_tiers"] as Dictionary).duplicate() if typeof(data.get("chronicle_tiers")) == TYPE_DICTIONARY else {}
	secrets.clear()
	if typeof(data.get("secrets")) == TYPE_ARRAY:
		for sc_it in (data["secrets"] as Array):
			if typeof(sc_it) == TYPE_DICTIONARY:
				secrets.append((sc_it as Dictionary).duplicate(true))
	secret_uid = int(data.get("secret_uid", secrets.size()))
	desires.clear()
	if typeof(data.get("desires")) == TYPE_ARRAY:
		for de_it in (data["desires"] as Array):
			if typeof(de_it) == TYPE_DICTIONARY:
				desires.append((de_it as Dictionary).duplicate(true))
	desire_uid = int(data.get("desire_uid", desires.size()))
	desire_hate_since = (data["desire_hate_since"] as Dictionary).duplicate() if typeof(data.get("desire_hate_since")) == TYPE_DICTIONARY else {}
	npc_murders = (data["npc_murders"] as Dictionary).duplicate() if typeof(data.get("npc_murders")) == TYPE_DICTIONARY else {}
	last_npc_murder_day = int(data.get("last_npc_murder_day", -9999))
	faith_state = (data["faith_state"] as Dictionary).duplicate(true) if typeof(data.get("faith_state")) == TYPE_DICTIONARY else {}
	faith_bands = []
	needs_state = (data["needs_state"] as Dictionary).duplicate(true) if typeof(data.get("needs_state")) == TYPE_DICTIONARY else {}
	VillageNeeds.drunk_now = (VillageNeeds.state(self)["drunk"] as Dictionary).duplicate()
	town_state = (data["town_state"] as Dictionary).duplicate(true) if typeof(data.get("town_state")) == TYPE_DICTIONARY else {}
	sect_state = (data["sect_state"] as Dictionary).duplicate(true) if typeof(data.get("sect_state")) == TYPE_DICTIONARY else {}
	lots_state = (data["lots_state"] as Dictionary).duplicate(true) if typeof(data.get("lots_state")) == TYPE_DICTIONARY else {}
	VillageLots.after_load(self)
	VillageHousing.sync_livestock(self)
	VillageHousing.sync_home_props(self)
	places_state = (data["places_state"] as Dictionary).duplicate(true) if typeof(data.get("places_state")) == TYPE_DICTIONARY else {}
	work_state = (data["work_state"] as Dictionary).duplicate(true) if typeof(data.get("work_state")) == TYPE_DICTIONARY else {}
	VillageWork.after_load(self)
	culture_state = (data["culture_state"] as Dictionary).duplicate(true) if typeof(data.get("culture_state")) == TYPE_DICTIONARY else {}
	VillageCulture.after_load(self)
	if data.has("player_elevation_level"):
		set_player_elevation_level(int(data.get("player_elevation_level", 0)))
	VillageUnderworld.after_load(self)
	migration_state = (data["migration_state"] as Dictionary).duplicate(true) if typeof(data.get("migration_state")) == TYPE_DICTIONARY else {}
	VillageMigration.after_load(self)
	nobility_state = (data["nobility_state"] as Dictionary).duplicate(true) if typeof(data.get("nobility_state")) == TYPE_DICTIONARY else {}
	family_state = (data["family_state"] as Dictionary).duplicate(true) if typeof(data.get("family_state")) == TYPE_DICTIONARY else {}
	VillageFamily.after_load(self)
	# B4: retomar o cancelar limpio lo que estaba a medias al guardar (recados, club, cenas)
	VillageNightJobs.after_load(self)
	VillageClub.after_load(self)
	VillageHousing.after_load_gathering(self)
	VillageSect._update_band(self)
	VillageFamilia.after_load(self)
	if data.has("chronicle") and typeof(data["chronicle"]) == TYPE_ARRAY:
		chronicle.clear()
		for ch_it in (data["chronicle"] as Array):
			if typeof(ch_it) == TYPE_DICTIONARY:
				chronicle.append((ch_it as Dictionary).duplicate())
		while chronicle.size() > VillageChronicle.MAX_ENTRIES:
			chronicle.remove_at(0)
	else:
		VillageChronicle.seed_from_social_log(self) # Partidas de antes de la crónica
	for live_fight in _live_fights:
		for fighter in [live_fight["a"], live_fight["b"]]:
			if is_instance_valid(fighter):
				fighter.end_live_fight()
	_live_fights.clear()
	if data.has("social_director") and typeof(data["social_director"]) == TYPE_DICTIONARY and social_director != null:
		social_director.from_save_dict(data["social_director"] as Dictionary)
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
				var raw_ch: Variant = sc[match_key]
				if typeof(raw_ch) == TYPE_DICTIONARY:
					var ch_d: Dictionary = raw_ch as Dictionary
					ch["looted_day"] = int(ch_d.get("looted_day", -1))
					ch["planted_evidence"] = str(ch_d.get("planted_evidence", ""))
				else:
					ch["looted_day"] = int(raw_ch)
					ch["planted_evidence"] = ""
				var spr: Sprite2D = ch.get("sprite")
				if is_instance_valid(spr):
					var is_open: bool = (int(ch["looted_day"]) == cur_d)
					spr.texture = _load_tex("res://assests/world/village/house_chest_open.png" if is_open else "res://assests/world/village/house_chest_closed.png")
			else:
				ch["looted_day"] = -1
				ch["planted_evidence"] = ""
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
	for trap_entry in _deployed_bear_traps:
		var trap_node: Node2D = trap_entry.get("node") as Node2D
		if is_instance_valid(trap_node):
			trap_node.queue_free()
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
				_free_transient_npc(_active_traveling_merchant)
				_active_traveling_merchant = null
		else:
			var m_id_saved: String = str(m_data.get("merchant_id", "casimir"))
			if is_instance_valid(_active_traveling_merchant) and _active_traveling_merchant.merchant_id != m_id_saved and not _active_traveling_merchant.is_dead:
				_free_transient_npc(_active_traveling_merchant)
				_active_traveling_merchant = null
			if not is_instance_valid(_active_traveling_merchant):
				_check_weekly_merchant_arrival(3 if m_id_saved == "casimir" else 6, true, true)
			if is_instance_valid(_active_traveling_merchant):
				_active_traveling_merchant.from_save_dict(m_data)
	if data.has("active_sheriff_investigation") and typeof(data["active_sheriff_investigation"]) == TYPE_DICTIONARY:
		active_sheriff_investigation = (data["active_sheriff_investigation"] as Dictionary).duplicate(true)
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
				_free_transient_npc(_royal_investigator_npc)
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
	VillageJustice.after_load(self)
	VillageHousing.sync_relocated_camp_assets(self, false)
	VillageHousing.sync_livestock(self)

	var b_dict: Variant = data.get("businesses", {})
	if typeof(b_dict) != TYPE_DICTIONARY:
		refresh_world_stage_3d()
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
	refresh_world_stage_3d()

func refresh_world_stage_3d() -> void:
	if is_instance_valid(world_stage_3d) and world_stage_3d.has_method("rebuild_all_3d"):
		world_stage_3d.rebuild_all_3d()

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
	if npc_data.has("person_profile") and typeof(npc_data["person_profile"]) == TYPE_DICTIONARY:
		dyn_npc.person_profile = PersonProfile.from_dict(npc_data["person_profile"])
	entities_root.add_child(dyn_npc)
	var default_tex := _load_tex("res://assests/world/village/villager_traveler.png")
	var def_bed: Vector2 = VillageTavern.GUEST_BEDS[0]
	dyn_npc.setup_npc(
		default_tex, Vector2(float(npc_data.get("work_x", 440.0)), float(npc_data.get("work_y", 44.0))),
		Vector2(float(npc_data.get("bed_x", def_bed.x)), float(npc_data.get("bed_y", def_bed.y))), {},
		Vector2(float(npc_data.get("table_x", _tavern_social_pos.x)), float(npc_data.get("table_y", _tavern_social_pos.y))),
		str(npc_data.get("family_id", "none")), str(npc_data.get("family_name", "Independiente"))
	)
	dyn_npc.from_save_dict(npc_data)
	if dyn_npc.person_profile != null and str(dyn_npc.person_profile.person_id) != "":
		_used_person_ids[str(dyn_npc.person_profile.person_id)] = true
	var first_tok: String = dyn_npc.npc_name.strip_edges().split(" ", false)[0] if dyn_npc.npc_name.strip_edges() != "" else ""
	if first_tok != "" and not (first_tok in _used_first_names):
		_used_first_names.append(first_tok)
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
			v.tavern_social_pos = _tavern_social_pos
			if v.home_table_pos.distance_to(Vector2(376.0, -184.0)) < 2.0:
				v.home_table_pos = _tavern_social_pos
			if v.trade_role == VillageNPC.TradeRole.ROYAL_INVESTIGATOR and not v.is_dead and not str(v.name).begins_with("NPC_Royal_Investigator_Corpse_"):
				_royal_investigator_npc = v
			elif v.trade_role == VillageNPC.TradeRole.TRAVELING_MERCHANT and not v.is_dead and not str(v.name).begins_with("NPC_Merchant_Corpse_"):
				_active_traveling_merchant = v
			var r_int: int = int(v.trade_role)
			if (v.trade_role in VillageNPC.SHOP_ROLES or v.trade_role == VillageNPC.TradeRole.WAITER) and not v.is_dead:
				trade_npcs[r_int] = v
				if trade_configs.has(r_int):
					v.work_position = (trade_configs[r_int] as Dictionary).get("work_pos", v.work_position)
			elif v.trade_role == VillageNPC.TradeRole.FAMILY_MEMBER and not v.is_dead:
				family_npcs[int(v.linked_trade)] = v
				if v.npc_name == VillageFamilia.INITIAL_BOSS_NAME:
					v.work_position = VillageRestaurant.DINING_TABLES[4]
					v.bed_position = VillageRestaurant.OWNER_BED2
					v.home_table_pos = VillageRestaurant.BACKROOM_TABLE
				elif trade_configs.has(int(v.linked_trade)):
					var l_cfg: Dictionary = trade_configs[int(v.linked_trade)]
					v.work_position = l_cfg.get("kin_work_pos", l_cfg.get("work_pos", v.work_position))
			elif v.trade_role == VillageNPC.TradeRole.TEACHER and not v.is_dead:
				v.work_position = VillageLots.building_center("e3") + Vector2(0, -16)
			elif v.trade_role == VillageNPC.TradeRole.NOBLE and not v.is_dead:
				var n_lot: String = "f1" if v.family_id == "family_vane" else ("f2" if v.family_id == "family_solis" else "")
				if n_lot != "":
					v.work_position = VillageNobility.study_pos(n_lot)
			elif v.trade_role == VillageNPC.TradeRole.UNEMPLOYED and not v.is_dead:
				unemployed_npcs.append(v)
			elif v.trade_role == VillageNPC.TradeRole.INNKEEPER and not v.is_dead:
				_innkeeper_npc = v
				v.work_position = VillageTavern.INNKEEPER_WORK_POS
				v.bed_position = VillageTavern.MARTA_BED_POS
				v.home_table_pos = VillageTavern.SOCIAL_POS
			elif v.trade_role in [VillageNPC.TradeRole.DOCTOR, VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.PRIEST] and not v.is_dead:
				authority_npcs.append(v)
				trade_npcs[r_int] = v
				for slot in _authority_slots:
					if int(slot.get("role", -1)) == r_int:
						slot["npc"] = v
						slot["rehire_timer"] = 0.0
						slot["vacancy_announced"] = false
						v.work_position = slot.get("work_pos", v.work_position)
			if v.is_vagrant_camper and not v.is_dead and not v.in_shelter:
				_spawn_or_update_vagrant_camp_visual(v, v.vagrant_camp_pos)

func _add_poly(pts: PackedVector2Array, col: Color, z_idx: int = -1, pos: Vector2 = Vector2.ZERO, parent_node: Node = null) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = col
	if pos != Vector2.ZERO:
		p.global_position = pos
	p.z_index = z_idx
	(parent_node if parent_node else entities_root).add_child(p)
	return p

func _add_rect_poly(pos: Vector2, half_sz: Vector2, col: Color, z_idx: int = -1, parent_node: Node = null) -> Polygon2D:
	var pts := PackedVector2Array([Vector2(-half_sz.x, -half_sz.y), Vector2(half_sz.x, -half_sz.y), Vector2(half_sz.x, half_sz.y), Vector2(-half_sz.x, half_sz.y)])
	return _add_poly(pts, col, z_idx, pos, parent_node)

func _add_sprite_prop(tex: Texture2D, pos: Vector2, sc: Vector2 = Vector2.ONE, z_idx: int = -1, vis: bool = true, mod: Color = Color.WHITE) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.global_position = pos
	s.scale = sc
	s.z_index = z_idx
	s.visible = vis
	if mod != Color.WHITE:
		s.modulate = mod
	entities_root.add_child(s)
	if tex != null and tex.has_meta("src_path"):
		var fname: String = str(tex.get_meta("src_path")).get_file()
		match fname:
			"work_stall.png", "storage_countertop_0.png":
				_add_prop_collider(pos, Vector2(16.0, 9.0))
			"water_well.png":
				_add_prop_collider(pos, Vector2(14.0, 14.0))
			"compost_bin.png":
				_add_prop_collider(pos, Vector2(10.0, 9.0))
			"pine-tree_0.png":
				_add_prop_collider(pos, Vector2(10.0, 10.0))
			"questboard_1.png", "sign_1.png", "lamp-post1.png":
				_add_prop_collider(pos, Vector2(7.0, 6.0))
			"morgue_table.png":
				_add_prop_collider(pos, Vector2(10.0, 14.0))
			"tavern_bed.png", "hospital_bed.png":
				var b_tag: String = "tavern_upper_walls" if VillageTavern.RECT.has_point(pos) else ""
				_add_prop_collider(pos, Vector2(10.0, 14.0), b_tag)
	return s

func _add_title_label(pos: Vector2, min_sz: Vector2, txt: String, col: Color, f_sz: int = 8, parent_node: Node = null) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = pos
	lbl.custom_minimum_size = min_sz
	lbl.add_theme_font_size_override("font_size", f_sz)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 3)
	(parent_node if parent_node else entities_root).add_child(lbl)
	lbl.add_to_group("world_title_label")
	return lbl

## Letreros del mapa sin amontonarse (2026-11-05): solo se ven los que están cerca del jugador (o bajo el ratón), y si
## dos se pisan, se queda el más cercano. Usa la transparencia (modulate.a), así no toca su `visible`.
const TITLE_SHOW_RADIUS: float = 72.0
var _titles_declutter_t: float = 0.0

## El trozo del letrero que ocupa el texto de verdad (los letreros son más anchos que su texto y van centrados).
func _title_text_rect(lbl: Label) -> Rect2:
	var full: Rect2 = lbl.get_global_rect()
	var font: Font = lbl.get_theme_font("font")
	if font == null or lbl.text == "":
		return full
	var fsz: int = lbl.get_theme_font_size("font_size")
	var w: float = 0.0
	var lines: PackedStringArray = lbl.text.split("\n")
	for ln in lines:
		w = maxf(w, font.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x)
	var sc: float = lbl.get_global_transform().get_scale().x
	w = minf(w * sc, full.size.x)
	return Rect2(Vector2(full.get_center().x - w * 0.5, full.position.y), Vector2(w, full.size.y))

func _declutter_title_labels() -> void:
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	if pl == null:
		return
	var pp: Vector2 = pl.global_position
	var mp: Vector2 = get_global_mouse_position()
	var cands: Array = []
	for l in get_tree().get_nodes_in_group("world_title_label"):
		var lbl := l as Label
		if lbl == null or not lbl.is_visible_in_tree():
			continue
		var r: Rect2 = _title_text_rect(lbl)
		var d: float = r.get_center().distance_to(pp)
		if d <= TITLE_SHOW_RADIUS or r.grow(6.0).has_point(mp):
			cands.append([d if not r.grow(6.0).has_point(mp) else -1.0, lbl, r])
		else:
			lbl.modulate.a = 0.0
	cands.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	var kept: Array = []
	var sel_node := pl.get_node_or_null("InteractionSelector/PromptLabel") as Label
	if sel_node != null and sel_node.is_visible_in_tree():
		kept.append(_title_text_rect(sel_node).grow(3.0))
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var vnpc := n as VillageNPC
			if vnpc._craft_bar_root != null and vnpc._craft_bar_root.is_visible_in_tree() and vnpc._craft_bar_label != null:
				kept.append(_title_text_rect(vnpc._craft_bar_label).grow(3.0))
			if vnpc.status_label != null and vnpc.status_label.is_visible_in_tree():
				kept.append(_title_text_rect(vnpc.status_label).grow(3.0))
	for r_id in shop_businesses.keys():
		var sb_lbl: Label = shop_businesses[r_id].get("stall_label")
		if sb_lbl != null and is_instance_valid(sb_lbl) and sb_lbl.is_visible_in_tree():
			kept.append(_title_text_rect(sb_lbl).grow(3.0))
	var shown_count: int = 0
	for c in cands:
		var r2: Rect2 = c[2]
		var clash: bool = (shown_count >= 1)
		if not clash:
			for k in kept:
				if r2.grow(2.0).intersects(k):
					clash = true
					break
		(c[1] as Label).modulate.a = 0.0 if clash else 0.88
		if not clash:
			kept.append(r2)
			shown_count += 1

# ==============================================================================
# Regla 1 (suma cero): ayudas para que todo oro salga de un bolsillo, una caja o las arcas, y vaya a otro.
# ==============================================================================
## Un vecino adulto vivo (que no sea `exclude`) con al menos `price` de oro, al azar. Null si nadie puede pagar.
func _find_paying_customer(price: int, exclude = null) -> VillageNPC:
	var cands: Array = []
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != exclude and not n.is_dead and not n.is_downed and n.personal_gold >= price and int(n.trade_role) != int(VillageNPC.TradeRole.CHILD):
			cands.append(n)
	return null if cands.is_empty() else cands.pick_random()

## Quita hasta `amount` de oro repartido entre los miembros vivos de una familia. Devuelve lo quitado.
func _take_family_savings(fam_id: String, amount: int) -> int:
	var taken: int = 0
	if fam_id == "" or fam_id == "none":
		return 0
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if taken >= amount:
			break
		if n is VillageNPC and not n.is_dead and n.family_id == fam_id and n.personal_gold > 0:
			var t: int = mini(amount - taken, n.personal_gold)
			n.personal_gold -= t
			taken += t
	return taken

## Ingresa oro a un vecino vivo; si no hay nadie que lo reciba, va a las arcas municipales.
func pay_into(npc, amount: int) -> void:
	if amount <= 0:
		return
	if npc != null and is_instance_valid(npc) and not bool(npc.get("is_dead")):
		npc.personal_gold += amount
	else:
		town_state["treasury"] = int(town_state.get("treasury", 0)) + amount

## Saca hasta `amount` de las arcas (nunca las deja en negativo). Devuelve lo que se pudo sacar.
func take_from_treasury(amount: int) -> int:
	var paid: int = clampi(int(town_state.get("treasury", 0)), 0, maxi(0, amount))
	town_state["treasury"] = int(town_state.get("treasury", 0)) - paid
	return paid

## Primer vecino vivo con ese oficio (titular de taller o autoridad).
func role_npc(role: int) -> VillageNPC:
	var t: VillageNPC = trade_npcs.get(role)
	if is_instance_valid(t) and not t.is_dead:
		return t
	for a in authority_npcs:
		if is_instance_valid(a) and not a.is_dead and int(a.trade_role) == role:
			return a
	return null

func _msg_player(player: Node, txt: String, col: Color, offset_y: float = -42.0) -> void:
	if is_instance_valid(player) and player.has_method("_spawn_floating_text"):
		player.call("_spawn_floating_text", txt, col, offset_y)

func _hint_player(txt: String, player: Node = null) -> void:
	var p: Node = player if is_instance_valid(player) else get_tree().get_first_node_in_group("player")
	if is_instance_valid(p) and p.has_method("show_hint"):
		p.call("show_hint", txt)

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
	if _tex_cache.has(res_path) and _tex_cache[res_path] is Texture2D:
		return _tex_cache[res_path] as Texture2D
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img and not img.is_empty():
			var itex := ImageTexture.create_from_image(img)
			itex.set_meta("src_path", res_path) # la usa el escenario 3D para reconocer, p. ej., los pinos
			_tex_cache[res_path] = itex
			return itex
	if ResourceLoader.exists(res_path):
		var t = load(res_path)
		if t is Texture2D:
			_tex_cache[res_path] = t
			return t
	return null
