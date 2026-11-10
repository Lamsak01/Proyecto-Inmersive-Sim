@tool
extends Node2D
const _AN_SITIOS = preload("res://mapa/anclas.gd") # plan de sitios: zonas fijas siguen a lo movido
const EdificioEditor = preload("res://mapa/edificio.gd")
const Anclas = preload("res://mapa/anclas.gd")

## Plan de sitios (docs/PLAN_SITIOS.md): traduce un punto escrito en coordenadas del mapa ORIGINAL a su sitio actual
## (edificio, mueble u objeto movido en el editor del mapa 3D). Úsalo una sola vez, donde se escribe el número fijo.
func sitio(p: Vector2) -> Vector2:
	return p if p == Vector2.ZERO else Anclas.mover(p)

## Lo mismo para una lista de puntos originales (para comparar con sitios ya traducidos de los vecinos).
func sitios(lista: Array) -> Array:
	var out: Array = []
	for q in lista:
		out.append(sitio(q))
	return out

var VillageJustice = load("res://scripts/systems/VillageJustice.gd")

var VillageSocialLife = load("res://scripts/systems/VillageSocialLife.gd")
var VillageChronicle = load("res://scripts/systems/VillageChronicle.gd")
var VillageSecrets = load("res://scripts/systems/VillageSecrets.gd")
var VillageDesires = load("res://scripts/systems/VillageDesires.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageFaith = preload("res://scripts/systems/VillageFaith.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageIllness = preload("res://scripts/systems/VillageIllness.gd")
const VillageCrime = preload("res://scripts/systems/VillageCrime.gd")
const VillageTown = preload("res://scripts/systems/VillageTown.gd")
const VillageSect = preload("res://scripts/systems/VillageSect.gd")
var VillageQuests = load("res://scripts/systems/VillageQuests.gd")

var VillageWorldBuilder = load("res://scripts/systems/VillageWorldBuilder.gd")
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
const VillageCase1 = preload("res://scripts/systems/VillageCase1.gd") # Caso I en el mundo (papeles, diálogos, gabinete, secuestradores)
const WorldStage3DScript = preload("res://scripts/visuals/WorldStage3D.gd")

## Gestor Integral de Urbanismo Sólido, Hospital/Morgue Forense, Comisaría/Cárcel, Testigos,
## Sigilo Doméstico, Reputación Familiar, Tablón de Encargos y Red Eléctrica (10 Pasos de Expansión)

## Interruptor central «MODO DEMO» (Caso I), sincronizado con `GameManager.demo_mode` (encendido por defecto).
const DEMO_MODE_DEFAULT: bool = true
var demo_mode: bool = DEMO_MODE_DEFAULT:
	set(value):
		if demo_mode == value:
			return
		demo_mode = value
		if is_inside_tree() and GameManager and bool(GameManager.get("demo_mode")) != value:
			GameManager.demo_mode = value

func is_demo_mode() -> bool:
	if is_inside_tree() and GameManager and GameManager.has_method("is_demo_mode"):
		return bool(GameManager.is_demo_mode())
	return demo_mode

func set_demo_mode(enabled: bool) -> void:
	demo_mode = enabled
	if is_inside_tree() and GameManager and GameManager.has_method("set_demo_mode"):
		GameManager.set_demo_mode(enabled)

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
var _no_stand_furniture_rects: Array[Rect2] = []
## Rendimiento (2026-11-09): copia plana de las huellas de edificios para las comprobaciones de cada vecino en cada
## instante (evita leer diccionarios y comparar textos 60 veces por vecino). Se rehace si cambia el número de huellas.
var _fp_cache_n: int = -1
var _fp_rects: Array[Rect2] = []
var _fp_skip_mill: Array[bool] = []

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
var _notice_board_pos := Vector2(476, 14)
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
var _plaza_well_pos := Vector2(416, 62)
var _well_positions: Array[Vector2] = [Vector2(184, 82), VillageTavern.WELL_POS, Vector2(416, 62)]
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


var _cached_player: Node2D = null
var _ui_hover_timer: float = 0.0
var _tex_cache: Dictionary = {}
var _deployed_bear_traps: Array[Dictionary] = []

const GOSSIP_EVENT_TYPES: Array[String] = ["fight", "breakup", "couple", "couple_reconciled", "feud", "reconciliation", "player_slander", "npc_slander", "rejection",
	"date", "romance_flirt", "romance_dating", "jealousy", "arrival", "departure", "affair_forgiven", "theft", "theft_caught", "embezzle", "police_bribe", "sect_rumor", "sect_night", "familia_rumor"] # R5: más cosas de las que hablar # Sin "widowed": revelaría muertes aún sin descubrir
const GOSSIP_MAX_AGE_DAYS: int = 20 # R1: tope; antes lo decide la memoria de cada vecino (GossipMemory)
const NEWS_MIN_KNOWERS: int = 3

var player_elevation_level: int = 0

var _elevation_anchor: Vector2 = Vector2.INF
const ELEVATION_LEAVE_DIST: float = 70.0

var _hangout_plan_timer: float = 6.0
const HANGOUT_ARRIVAL_RADIUS: float = 20.0

## Puntos de encuentro del pueblo ofrecidos al SocialDirector ({id, pos, kind, label}).
const FIGHT_TRIGGER_RADIUS: float = 72.0
const FIGHT_GUARD_RADIUS: float = 140.0
const FIGHT_WITNESS_RADIUS: float = 110.0
const FIGHT_DURATION_SEC: float = 3.5
const FIGHT_GUARD_STOP_SEC: float = 1.6
const FIGHT_HEALTH_FLOOR: float = 0.35
var _live_fights: Array[Dictionary] = []
@warning_ignore("unused_private_class_variable") # Se usa desde otro script (vm._fight_scan_timer)
var _fight_scan_timer: float = 3.0

const ROMANCE_STAGE_NAMES: Dictionary = {"interest": "sienten interés mutuo", "flirt": "han empezado a coquetear", "dating": "han empezado a salir"}

const TITLE_SHOW_RADIUS: float = 28.0
var _titles_declutter_t: float = 0.0

## El trozo del letrero que ocupa el texto de verdad (los letreros son más anchos que su texto y van centrados).

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

func _is_near(player: Node2D, mouse_pos: Vector2, target_pos: Vector2, p_rad: float, m_rad: float) -> bool:
	return (player != null and player.global_position.distance_squared_to(target_pos) <= p_rad * p_rad) or (target_pos.distance_squared_to(mouse_pos) <= m_rad * m_rad)

const MIN_DUAL_LANE_DOOR_WIDTH: float = 34.0

func get_door_outward_dir(b_or_door: Dictionary) -> Vector2:
	if b_or_door.has("door_dir"):
		var dd = b_or_door["door_dir"]
		if dd is Vector2 and (dd as Vector2).length_squared() > 0.01:
			return (dd as Vector2).normalized()
		var s: String = str(dd).to_lower().strip_edges()
		match s:
			"south", "s", "down", "sur":
				return Vector2(0.0, 1.0)
			"north", "n", "up", "norte":
				return Vector2(0.0, -1.0)
			"east", "e", "right", "este":
				return Vector2(1.0, 0.0)
			"west", "w", "left", "oeste":
				return Vector2(-1.0, 0.0)
	if b_or_door.has("door_south"):
		return Vector2(0.0, 1.0 if bool(b_or_door["door_south"]) else -1.0)
	var r: Rect2 = b_or_door.get("rect", b_or_door.get("building_rect", Rect2()))
	var dp: Vector2 = b_or_door.get("door_pos", b_or_door.get("pos", r.get_center()))
	if r.size.x > 0.0 and r.size.y > 0.0:
		var d_s: float = absf(dp.y - r.end.y)
		var d_n: float = absf(dp.y - r.position.y)
		var d_e: float = absf(dp.x - r.end.x)
		var d_w: float = absf(dp.x - r.position.x)
		var m: float = minf(minf(d_s, d_n), minf(d_e, d_w))
		if is_equal_approx(m, d_s):
			return Vector2(0.0, 1.0)
		elif is_equal_approx(m, d_n):
			return Vector2(0.0, -1.0)
		elif is_equal_approx(m, d_e):
			return Vector2(1.0, 0.0)
		else:
			return Vector2(-1.0, 0.0)
	return Vector2(0.0, 1.0)

func get_door_lanes(b_or_door: Dictionary, lane_shift: float = 0.0) -> Dictionary:
	var d_pos: Vector2 = b_or_door.get("door_pos", b_or_door.get("pos", Vector2.ZERO))
	var out_dir: Vector2 = get_door_outward_dir(b_or_door)
	var in_dir: Vector2 = -out_dir
	# Carril derecho según el sentido de la marcha: al salir (`out_dir`) gira +90° (`Vector2(-out_dir.y, out_dir.x)`),
	# y al entrar (`in_dir`) va por el carril opuesto (`-exit_side`). Vale para Norte, Sur, Este, Oeste o cualquier ángulo.
	var exit_side: Vector2 = Vector2(-out_dir.y, out_dir.x)
	var enter_side: Vector2 = -exit_side
	var tangent_axis: Vector2 = Vector2(1.0, 0.0) if absf(out_dir.y) >= absf(out_dir.x) else Vector2(0.0, 1.0)
	var exit_lane_center: Vector2 = d_pos + exit_side * 7.5 + tangent_axis * (lane_shift * 0.5)
	var enter_lane_center: Vector2 = d_pos + enter_side * 7.5 + tangent_axis * (lane_shift * 0.5)
	return {
		"door_pos": d_pos,
		"out_dir": out_dir,
		"in_dir": in_dir,
		"exit_side": exit_side,
		"enter_side": enter_side,
		"exit_lane_center": exit_lane_center,
		"enter_lane_center": enter_lane_center,
		"exit_inside_pt": exit_lane_center + in_dir * 16.0,
		"exit_outside_pt": exit_lane_center + out_dir * 20.0,
		"enter_outside_pt": enter_lane_center + out_dir * 18.0,
		"enter_inside_pt": enter_lane_center + in_dir * 16.0,
	}

func _construct_solid_building(
	b_id: String, b_title: String, center: Vector2, size: Vector2, door_on_south,
	floor_tex_path: String, wall_h_path: String, wall_v_path: String,
	door_width: float = 42.0, door_offset_x: float = 0.0, title_color: Color = Color(0.96, 0.90, 0.68)
) -> void:
	# Editor del mapa 3D (2026-11-10): si el usuario movió el edificio en mapa/Mundo3D.tscn, se construye en el sitio nuevo
	var d_edif: Vector2 = EdificioEditor.desplazamiento(b_id)
	var g_edif: float = EdificioEditor.giro(b_id)
	Anclas.registrar_edificio(Rect2(center - size * 0.5, size), d_edif, g_edif)
	var orig_info := {"rect_orig": Rect2(center - size * 0.5, size)}
	center += d_edif
	Anclas.pausa += 1 # sus muros ya van desplazados; que las anclas no los muevan otra vez
	var half := size * 0.5
	var rect := Rect2(center - half, size)
	var door_dir: String = "south"
	if typeof(door_on_south) == TYPE_STRING:
		var dd_s: String = str(door_on_south).to_lower().strip_edges()
		if dd_s in ["south", "north", "east", "west"]:
			door_dir = dd_s
	else:
		door_dir = "south" if bool(door_on_south) else "north"
	if g_edif > 0.5:
		# Girado en el editor (de 90 en 90): se gira la planta, la puerta y su sitio; el resto del código no cambia
		var m_g: Transform2D = Anclas.matriz(g_edif)
		var horiz0: bool = door_dir in ["south", "north"]
		var v_door: Vector2 = Vector2(door_offset_x, half.y if door_dir == "south" else -half.y) if horiz0 else Vector2(half.x if door_dir == "east" else -half.x, door_offset_x)
		orig_info["door_pos_orig"] = center - d_edif + v_door
		orig_info["door_south_orig"] = door_dir == "south"
		orig_info["giro"] = g_edif
		var v2: Vector2 = m_g.basis_xform(v_door)
		door_width *= m_g.basis_xform(Vector2(1, 0) if horiz0 else Vector2(0, 1)).length()
		size = Vector2(absf(m_g.x.x) * size.x + absf(m_g.y.x) * size.y, absf(m_g.x.y) * size.x + absf(m_g.y.y) * size.y)
		half = size * 0.5
		rect = Rect2(center - half, size)
		var giros: Array = ["south", "east", "north", "west"]
		door_dir = giros[(giros.find(door_dir) + int(roundf(g_edif / 90.0))) % 4]
		door_offset_x = v2.x if door_dir in ["south", "north"] else v2.y
	var is_south: bool = (door_dir == "south")
	var is_horiz_door: bool = (door_dir in ["south", "north"])
	var door_pos: Vector2
	if is_horiz_door:
		var door_y: float = (center.y + half.y) if is_south else (center.y - half.y)
		door_pos = Vector2(center.x + door_offset_x, door_y)
	else:
		var is_east: bool = (door_dir == "east")
		var door_x: float = (center.x + half.x) if is_east else (center.x - half.x)
		door_pos = Vector2(door_x, center.y + door_offset_x)

	building_footprints.append({
		"id": b_id, "title": b_title, "rect": rect, "door_pos": door_pos,
		"door_south": is_south, "door_dir": door_dir, "door_width": door_width
	})
	if orig_info.has("giro"):
		(building_footprints[-1] as Dictionary).merge(orig_info)

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

	if is_horiz_door:
		_add_solid_wall_segment(Vector2(rect.position.x, center.y), Vector2(wall_t, size.y), tex_v)
		_add_solid_wall_segment(Vector2(rect.end.x, center.y), Vector2(wall_t, size.y), tex_v)

		var closed_y: float = (center.y - half.y) if is_south else (center.y + half.y)
		_add_solid_wall_segment(Vector2(center.x, closed_y), Vector2(size.x, wall_t), tex_h)

		var door_left_x: float = door_pos.x - door_width * 0.5
		var door_right_x: float = door_pos.x + door_width * 0.5
		var left_seg_w: float = maxf(8.0, door_left_x - rect.position.x)
		var right_seg_w: float = maxf(8.0, rect.end.x - door_right_x)

		_add_solid_wall_segment(Vector2(rect.position.x + left_seg_w * 0.5, door_pos.y), Vector2(left_seg_w, wall_t), tex_h)
		_add_solid_wall_segment(Vector2(rect.end.x - right_seg_w * 0.5, door_pos.y), Vector2(right_seg_w, wall_t), tex_h)
		_add_rect_poly(door_pos, Vector2(door_width * 0.5, 3.0), Color(0.72, 0.54, 0.30, 0.85), -2)
	else:
		_add_solid_wall_segment(Vector2(center.x, rect.position.y), Vector2(size.x, wall_t), tex_h)
		_add_solid_wall_segment(Vector2(center.x, rect.end.y), Vector2(size.x, wall_t), tex_h)

		var is_east: bool = (door_dir == "east")
		var closed_x: float = (center.x - half.x) if is_east else (center.x + half.x)
		_add_solid_wall_segment(Vector2(closed_x, center.y), Vector2(wall_t, size.y), tex_v)

		var door_top_y: float = door_pos.y - door_width * 0.5
		var door_bot_y: float = door_pos.y + door_width * 0.5
		var top_seg_h: float = maxf(8.0, door_top_y - rect.position.y)
		var bot_seg_h: float = maxf(8.0, rect.end.y - door_bot_y)

		_add_solid_wall_segment(Vector2(door_pos.x, rect.position.y + top_seg_h * 0.5), Vector2(wall_t, top_seg_h), tex_v)
		_add_solid_wall_segment(Vector2(door_pos.x, rect.end.y - bot_seg_h * 0.5), Vector2(wall_t, bot_seg_h), tex_v)
		_add_rect_poly(door_pos, Vector2(3.0, door_width * 0.5), Color(0.72, 0.54, 0.30, 0.85), -2)

	var t_lbl := _add_title_label(center + Vector2(-125, -half.y - 18.0), Vector2(250, 14), b_title, title_color, 7)
	t_lbl.set_meta("anchor_pos", door_pos)
	_spawn_building_door_and_window(b_id, b_title, rect, door_pos, is_south, door_width, door_dir)
	Anclas.pausa -= 1

func _spawn_building_door_and_window(
	b_id: String,
	b_title: String,
	rect: Rect2,
	door_pos: Vector2,
	door_on_south: bool,
	door_width: float,
	door_dir: String = ""
) -> void:
	var eff_dir: String = door_dir if door_dir != "" else ("south" if door_on_south else "north")
	var is_horiz_door: bool = (eff_dir in ["south", "north"])
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
	d_rect_shape.size = Vector2(maxf(20.0, door_width - 4.0), 7.0) if is_horiz_door else Vector2(7.0, maxf(20.0, door_width - 4.0))
	d_col.shape = d_rect_shape
	d_col.disabled = false # Las puertas permanecen cerradas por defecto y se abren solo al cruzar el umbral
	d_body.add_child(d_col)
	entities_root.add_child(d_body)

	var spr_closed := _add_sprite_prop(tex_door_closed, door_pos, Vector2(door_width / 42.0, 1.0), 3, true)
	var spr_open := _add_sprite_prop(tex_door_open, door_pos + Vector2(-door_width * 0.5 + 4.0, -15.0 if door_on_south else 15.0), Vector2.ONE, 2, false)

	_add_station_area("DoorArea_" + b_id, door_pos, 20.0, "building_door")
	var d_lbl := _make_station_label(door_pos + Vector2(-125, -26), "🚪 Puerta de %s" % b_title)
	entities_root.add_child(d_lbl)

	var occ_rect: Rect2 = Rect2(door_pos - Vector2(door_width * 0.5, 4.0), Vector2(door_width, 8.0)) if is_horiz_door else Rect2(door_pos - Vector2(4.0, door_width * 0.5), Vector2(8.0, door_width))
	building_doors.append({
		"building_id": b_id, "building_title": b_title, "building_rect": rect, "pos": door_pos,
		"door_south": door_on_south, "door_dir": eff_dir, "width": door_width, "body": d_body, "col": d_col,
		"spr_closed": spr_closed, "spr_open": spr_open, "label": d_lbl,
		"occluder_rect": occ_rect,
		"is_open": false, "is_locked": false, "locked_by_player": false,
		"manual_override_timer": 0.0, "npc_pass_timer": 0.0, "police_breach_timer": 0.0
	})

	var win_pos: Vector2
	if is_horiz_door:
		var win_x: float = door_pos.x - door_width * 0.5 - 18.0
		if win_x < rect.position.x + 15.0:
			win_x = door_pos.x + door_width * 0.5 + 18.0
		win_pos = Vector2(clampf(win_x, rect.position.x + 14.0, rect.end.x - 14.0), door_pos.y)
	else:
		var win_y: float = door_pos.y - door_width * 0.5 - 18.0
		if win_y < rect.position.y + 15.0:
			win_y = door_pos.y + door_width * 0.5 + 18.0
		win_pos = Vector2(door_pos.x, clampf(win_y, rect.position.y + 14.0, rect.end.y - 14.0))
	var spr_win := _add_sprite_prop(tex_win_open, win_pos, Vector2.ONE, 3)

	_add_station_area("WindowArea_" + b_id, win_pos, 11.0, "building_window")
	var w_lbl := _make_station_label(win_pos + Vector2(-125, -24), "🪟 Ventana de %s" % b_title)
	entities_root.add_child(w_lbl)

	building_windows.append({
		"building_id": b_id, "building_title": b_title, "building_rect": rect, "pos": win_pos,
		"door_south": door_on_south, "door_dir": eff_dir, "sprite": spr_win, "label": w_lbl,
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
	# primero salir limpiamente por los tabiques internos y el pasillo de la puerta de ese edificio (vale para N/S/E/O).
	for b in building_footprints:
		var r_building_check: Rect2 = b["rect"].grow(2.5)
		var r_interior: Rect2 = b["rect"].grow(1.5)
		var d_pos: Vector2 = b["door_pos"]
		# Rendimiento (2026-11-09): descarte barato antes de calcular los carriles de la puerta. El umbral de la puerta
		# cabe en ±20 px alrededor de ella (<= 25,6 px), así que lejos del edificio y de su puerta nunca se cumple.
		if r_building_check.has_point(to_pos) or (not r_interior.has_point(from_pos) and from_pos.distance_squared_to(d_pos) > 900.0):
			continue
		var lanes: Dictionary = get_door_lanes(b, lane_shift)
		var out_dir: Vector2 = lanes["out_dir"]
		var exit_side: Vector2 = lanes["exit_side"]
		var exit_lane_center: Vector2 = lanes["exit_lane_center"]
		var inside_pt: Vector2 = lanes["exit_inside_pt"]
		var outside_pt: Vector2 = lanes["exit_outside_pt"]
		var is_horiz_door: bool = absf(out_dir.y) >= absf(out_dir.x)
		var r_door_threshold: Rect2
		if is_horiz_door:
			r_door_threshold = Rect2(d_pos - Vector2(20.0, 16.0 if out_dir.y > 0.0 else 12.0), Vector2(40.0, 28.0))
		else:
			r_door_threshold = Rect2(d_pos - Vector2(16.0 if out_dir.x > 0.0 else 12.0, 20.0), Vector2(28.0, 40.0))
		if (r_interior.has_point(from_pos) or r_door_threshold.has_point(from_pos)) and not r_building_check.has_point(to_pos):
			var b_id: String = str(b.get("id", ""))
			var along_out: float = (from_pos - d_pos).dot(out_dir)
			var still_inside_wall: bool = along_out < -2.0
			var on_other_floor: bool = agent != null and "elevation_level" in agent and int(agent.elevation_level) != 0
			if still_inside_wall or on_other_floor:
				var part_wp: Vector2 = _route_internal_building_partitions(b_id, from_pos, inside_pt, agent)
				if part_wp != inside_pt:
					return part_wp

			var lateral_err_exit: float = absf((from_pos - exit_lane_center).dot(exit_side))
			if still_inside_wall and lateral_err_exit > 6.5:
				return inside_pt
			return outside_pt

	# PASADA 2: Si el destino está dentro de un edificio, entrar limpiamente por el pasillo exterior -> puerta -> interior (N/S/E/O)
	for b in building_footprints:
		var r_target: Rect2 = b["rect"].grow(2.5)
		if r_target.has_point(to_pos):
			var b_id: String = str(b.get("id", ""))
			var d_pos2: Vector2 = b["door_pos"]
			var lanes2: Dictionary = get_door_lanes(b, lane_shift)
			var out_dir2: Vector2 = lanes2["out_dir"]
			var enter_side2: Vector2 = lanes2["enter_side"]
			var enter_lane_center: Vector2 = lanes2["enter_lane_center"]

			# Si el objetivo (p. ej. un cadáver o el jugador) está pegado a un muro interior, proyectar el punto de destino
			# ligeramente hacia el suelo caminable del interior (a >= 10 px de la pared) para no chocar con el muro
			var r_safe_dest: Rect2 = b["rect"].grow(-10.0)
			var safe_to_pos := Vector2(
				clampf(to_pos.x, r_safe_dest.position.x, r_safe_dest.end.x),
				clampf(to_pos.y, r_safe_dest.position.y, r_safe_dest.end.y)
			)

			var r_inside_room: Rect2 = b["rect"].grow(-2.5)
			var along_out2: float = (from_pos - d_pos2).dot(out_dir2)
			var past_door_line: bool = along_out2 <= -5.5
			var already_inside: bool = r_inside_room.has_point(from_pos) and past_door_line

			if not already_inside:
				var outside_pt2: Vector2 = lanes2["enter_outside_pt"]
				var inside_pt2: Vector2 = lanes2["enter_inside_pt"]

				var aligned_lateral: bool = absf((from_pos - enter_lane_center).dot(enter_side2)) <= 6.5
				var in_door_funnel: bool = along_out2 >= -18.0 and along_out2 <= 24.0
				if aligned_lateral and in_door_funnel:
					return inside_pt2
				return _avoid_outdoor_buildings(from_pos, outside_pt2, "")
			else:
				# Ya está dentro del edificio destino; comprobar tabiques internos (Posada, Botica Mixta, Hospital, Comisaría)
				return _route_internal_building_partitions(b_id, from_pos, safe_to_pos, agent)

	# PASADA 3: Navegación exterior esquivando edificios intermedios
	return _avoid_outdoor_buildings(from_pos, to_pos, "")

## Plan de sitios: los tabiques y pasos interiores están escritos en el mapa original. Se calcula allí y se devuelve el
## paso en su sitio actual (sigue al edificio movido o girado en el editor 3D).
func _route_internal_building_partitions(b_id: String, from_pos: Vector2, target_pos: Vector2, agent: Node2D = null) -> Vector2:
	if b_id == "building_tavern":
		return VillageTavern.route(from_pos, target_pos, agent, self) # ya traduce por su cuenta
	var o_from: Vector2 = _AN_SITIOS.desmover(from_pos)
	var o_to: Vector2 = _AN_SITIOS.desmover(target_pos)
	var r: Vector2 = _route_internal_original(b_id, o_from, o_to, agent)
	return target_pos if r == o_to else _AN_SITIOS.mover(r)


func _route_internal_original(b_id: String, from_pos: Vector2, target_pos: Vector2, agent: Node2D = null) -> Vector2:
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
				return Vector2(745.0, 138.0 if absf(from_pos.x - 745.0) > 16.0 else 163.0)
			elif from_pos.y > 155.0 and target_pos.y < 149.0:
				return Vector2(745.0, 163.0 if absf(from_pos.x - 745.0) > 16.0 else 138.0)
		"building_restaurant": # R1: varias salas; cruza por los pasos (ver VillageRestaurant.OPENINGS)
			return VillageRestaurant.route(from_pos, target_pos)
		"building_police":
			if from_pos.y > 154.0 and target_pos.y > 154.0 and ((from_pos.x < 915.0 and target_pos.x > 915.0) or (from_pos.x > 915.0 and target_pos.x < 915.0)):
				var exit_x: float = 902.0 if from_pos.x < 915.0 else 928.0
				return Vector2(exit_x, 165.0 if absf(from_pos.x - exit_x) > 8.0 else 138.0)
			if from_pos.y < 149.0 and target_pos.y > 155.0:
				var pass_x: float = 902.0 if target_pos.x < 915.0 else 928.0
				return Vector2(pass_x, 138.0 if absf(from_pos.x - pass_x) > 8.0 else 165.0)
			elif from_pos.y > 155.0 and target_pos.y < 149.0:
				var pass_x2: float = 902.0 if from_pos.x < 915.0 else 928.0
				return Vector2(pass_x2, 165.0 if absf(from_pos.x - pass_x2) > 8.0 else 138.0)
	if b_id.begins_with("mixed_"):
		for b in building_footprints:
			if str(b.get("id", "")) == b_id:
				var br: Rect2 = b["rect"]
				var c: Vector2 = br.get_center()
				var d_south: bool = bool(b.get("door_south", false))
				var y_wall: float = c.y + (-4.0 if d_south else 4.0)
				if from_pos.y < y_wall - 2.0 and target_pos.y > y_wall + 2.0:
					return Vector2(c.x, (y_wall - 11.0) if absf(from_pos.x - c.x) > 9.0 else (y_wall + 12.0))
				elif from_pos.y > y_wall + 2.0 and target_pos.y < y_wall - 2.0:
					return Vector2(c.x, (y_wall + 11.0) if absf(from_pos.x - c.x) > 9.0 else (y_wall - 12.0))
				break
	return target_pos

func register_no_stand_furniture(pos: Vector2, sz: Vector2) -> void:
	if sz.x <= 0.0 or sz.y <= 0.0:
		return
	_no_stand_furniture_rects.append(Rect2(pos - sz * 0.5, sz))

## Impide que ningún vecino (ni sus pies 3D con FOOT_OFFSET_PX = 4.0) quede subido encima de altares, mesas, mostradores o muebles.
func push_out_of_furniture(pos: Vector2, elev: int = 0) -> Vector2:
	if elev != 0:
		return pos
	var res := pos
	for f_rect in _no_stand_furniture_rects:
		var guard := Rect2(f_rect.position - Vector2(2.5, 5.2), f_rect.size + Vector2(5.0, 7.6))
		if guard.has_point(res):
			var dl: float = absf(res.x - guard.position.x)
			var dr: float = absf(guard.end.x - res.x)
			var dt: float = absf(res.y - guard.position.y)
			var db: float = absf(guard.end.y - res.y)
			var md: float = minf(minf(dl, dr), minf(dt, db))
			if md == dt:
				res.y = guard.position.y - 0.5
			elif md == db:
				res.y = guard.end.y + 0.5
			elif md == dl:
				res.x = guard.position.x - 0.5
			else:
				res.x = guard.end.x + 0.5
	return res

func clamp_point_to_building_interior(ref_pos: Vector2, candidate_pos: Vector2) -> Vector2:
	_refresh_fp_cache()
	for fi in range(_fp_rects.size()):
		if _fp_skip_mill[fi]:
			continue
		var r: Rect2 = _fp_rects[fi]
		if r.has_point(ref_pos):
			var r_safe: Rect2 = r.grow(-16.0)
			var clamped := Vector2(
				clampf(candidate_pos.x, r_safe.position.x, r_safe.end.x),
				clampf(candidate_pos.y, r_safe.position.y, r_safe.end.y)
			)
			clamped = push_out_of_furniture(clamped, 0)
			return Vector2(
				clampf(clamped.x, r_safe.position.x, r_safe.end.x),
				clampf(clamped.y, r_safe.position.y, r_safe.end.y)
			)
	return push_out_of_furniture(candidate_pos, 0)

## Evita que el paseo aleatorio de un NPC exterior (`UNEMPLOYED` o `GUARD`) caiga por accidente dentro de una casa o sobre su puerta

func is_point_in_river_water(pos: Vector2) -> bool:
	return FishingSpot.is_point_in_river_water(pos, 1.5)

func clamp_point_outside_buildings(ref_pos: Vector2, candidate_pos: Vector2) -> Vector2:
	if FishingSpot.is_point_in_river_water(candidate_pos, 5.0):
		return ref_pos
	_refresh_fp_cache()
	for fi in range(_fp_rects.size()):
		if _fp_rects[fi].has_point(ref_pos) and not _fp_skip_mill[fi]:
			return candidate_pos
	for fi2 in range(_fp_rects.size()):
		if _fp_rects[fi2].grow(14.0).has_point(candidate_pos):
			return ref_pos
	return candidate_pos

## Rendimiento (2026-11-09): rejilla de vecinos rehecha una vez por paso de física. Cada vecino pregunta solo por los
## de su zona en vez de recorrer a todo el pueblo varias veces por paso. Devuelve candidatos con margen (+6 px): quien
## llama sigue comprobando la distancia exacta con la posición actual, así que el resultado es el mismo.
const NPC_GRID_CELL: float = 32.0
var _npc_grid: Dictionary = {}
var _npc_grid_frame: int = -1

func npcs_near(pos: Vector2, radius: float) -> Array[Node]:
	if not Engine.is_in_physics_frame():
		return get_tree().get_nodes_in_group("village_npcs") # llamadas a mano (pruebas, saltos): sin rejilla
	var frame: int = Engine.get_physics_frames()
	if frame != _npc_grid_frame:
		_npc_grid_frame = frame
		_npc_grid.clear()
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if is_instance_valid(n):
				var c := Vector2i(floori(n.global_position.x / NPC_GRID_CELL), floori(n.global_position.y / NPC_GRID_CELL))
				if not _npc_grid.has(c):
					_npc_grid[c] = []
				_npc_grid[c].append(n)
	var out: Array[Node] = []
	var r: float = radius + 6.0
	var c0 := Vector2i(floori((pos.x - r) / NPC_GRID_CELL), floori((pos.y - r) / NPC_GRID_CELL))
	var c1 := Vector2i(floori((pos.x + r) / NPC_GRID_CELL), floori((pos.y + r) / NPC_GRID_CELL))
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			var cell = _npc_grid.get(Vector2i(cx, cy), null)
			if cell != null:
				for n in cell:
					if is_instance_valid(n):
						out.append(n)
	return out

func _refresh_fp_cache() -> void:
	if _fp_cache_n == building_footprints.size():
		return
	_fp_cache_n = building_footprints.size()
	_fp_rects.clear()
	_fp_skip_mill.clear()
	for b in building_footprints:
		_fp_rects.append(b["rect"])
		_fp_skip_mill.append(str(b.get("id", "")) == "building_abandoned_mill")

## Vecinos atascados (2026-11-09): al chocar con el margen de un edificio o con el agua del río, en vez de quedarse
## congelado (la ruta pasa rozando las esquinas y el empuje lateral también choca), el vecino se desliza por el borde
## moviéndose solo en horizontal o solo en vertical, como haría un cuerpo físico contra una pared.
func _slide_or_stay(prev_pos: Vector2, candidate_pos: Vector2, elev: int, allow_slide: bool) -> Vector2:
	if not allow_slide:
		return prev_pos
	var d: Vector2 = candidate_pos - prev_pos
	var options: Array[Vector2] = [Vector2(candidate_pos.x, prev_pos.y), Vector2(prev_pos.x, candidate_pos.y)]
	if absf(d.y) > absf(d.x):
		options.reverse()
	for o in options:
		if o.distance_squared_to(prev_pos) < 0.0001:
			continue
		var res: Vector2 = sanitize_npc_separation_pos(prev_pos, o, elev, false)
		if res.distance_squared_to(o) < 0.0001:
			return o
	return prev_pos

## Garantiza que el empuje de separación entre vecinos nunca meta a nadie dentro de un muro, edificio o pozo.
func sanitize_npc_separation_pos(prev_pos: Vector2, candidate_pos: Vector2, elev: int = 0, allow_slide: bool = true) -> Vector2:
	if elev == 1:
		var r_up: Rect2 = VillageTavern.RECT.grow(-13.0)
		var c_orig: Vector2 = _AN_SITIOS.desmover(candidate_pos) # plan de sitios: el piso de arriba sigue a la taberna
		return _AN_SITIOS.mover(Vector2(
			clampf(c_orig.x, r_up.position.x, r_up.end.x),
			clampf(c_orig.y, r_up.position.y, r_up.end.y)
		))
	if elev != 0:
		return candidate_pos
	if FishingSpot.is_point_in_river_water(candidate_pos, 4.0):
		if not FishingSpot.is_point_in_river_water(prev_pos, 2.0):
			return _slide_or_stay(prev_pos, candidate_pos, elev, allow_slide)
		var b_riv: Vector2 = FishingSpot.river_banks_at(candidate_pos.y)
		var cx_riv: float = (b_riv.x + b_riv.y) * 0.5
		return Vector2(b_riv.x - 5.0 if candidate_pos.x < cx_riv else b_riv.y + 5.0, candidate_pos.y)
	_refresh_fp_cache()
	for fi in range(_fp_rects.size()):
		if _fp_skip_mill[fi]:
			continue
		var r: Rect2 = _fp_rects[fi]
		if r.has_point(prev_pos):
			var r_safe: Rect2 = r.grow(-12.5)
			var clamped_in := Vector2(
				clampf(candidate_pos.x, r_safe.position.x, r_safe.end.x),
				clampf(candidate_pos.y, r_safe.position.y, r_safe.end.y)
			)
			clamped_in = push_out_of_furniture(clamped_in, elev)
			clamped_in = Vector2(
				clampf(clamped_in.x, r_safe.position.x, r_safe.end.x),
				clampf(clamped_in.y, r_safe.position.y, r_safe.end.y)
			)
			var seg_box := Rect2(prev_pos, Vector2.ZERO).expand(clamped_in)
			for w_rect in _wall_occluder_rects:
				var w_g: Rect2 = w_rect.grow(3.0)
				# Rendimiento (2026-11-09): si las cajas no se tocan, el segmento no puede cruzar el muro
				if w_g.intersects(seg_box, true) and _segment_intersects_rect(prev_pos, clamped_in, w_g):
					return prev_pos
			return clamped_in
	for fi2 in range(_fp_rects.size()):
		var r_avoid: Rect2 = _fp_rects[fi2].grow(9.5)
		if r_avoid.has_point(candidate_pos):
			if not r_avoid.has_point(prev_pos):
				return _slide_or_stay(prev_pos, candidate_pos, elev, allow_slide)
			var br_out: Rect2 = _fp_rects[fi2].grow(10.0)
			var dl: float = absf(candidate_pos.x - br_out.position.x)
			var dr: float = absf(br_out.end.x - candidate_pos.x)
			var dt: float = absf(candidate_pos.y - br_out.position.y)
			var db: float = absf(br_out.end.y - candidate_pos.y)
			var md: float = minf(minf(dl, dr), minf(dt, db))
			if md == dl:
				return Vector2(br_out.position.x, candidate_pos.y)
			elif md == dr:
				return Vector2(br_out.end.x, candidate_pos.y)
			elif md == dt:
				return Vector2(candidate_pos.x, br_out.position.y)
			else:
				return Vector2(candidate_pos.x, br_out.end.y)
	for w_rect in _wall_occluder_rects:
		if w_rect.grow(2.5).has_point(candidate_pos):
			return prev_pos
	for w_pos in [_plaza_well_pos, _well_pos, _tavern_well_pos]:
		if w_pos != Vector2.ZERO and candidate_pos.distance_squared_to(w_pos) < 18.0 * 18.0:
			var away_w: Vector2 = candidate_pos - w_pos
			if away_w.length_squared() > 0.01:
				return w_pos + away_w.normalized() * 18.0
			return prev_pos
	if _notice_board_pos != Vector2.ZERO and candidate_pos.distance_squared_to(_notice_board_pos) < 14.0 * 14.0:
		var away_nb: Vector2 = candidate_pos - _notice_board_pos
		if away_nb.length_squared() > 0.01:
			return _notice_board_pos + away_nb.normalized() * 14.0
		return prev_pos
	return candidate_pos

## Comprobación automática de solapes entre vecinos conscientes en todo el pueblo.
func check_npc_overlaps(min_dist: float = 11.5) -> Array:
	var issues: Array = []
	if not is_inside_tree():
		return issues
	var npcs: Array = []
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and is_instance_valid(n):
			var v: VillageNPC = n as VillageNPC
			if v.is_conscious() and not v.is_sleeping and not v.is_at_poker_table:
				npcs.append(v)
	for i in range(npcs.size()):
		var a: VillageNPC = npcs[i]
		for j in range(i + 1, npcs.size()):
			var b: VillageNPC = npcs[j]
			if int(a.elevation_level) != int(b.elevation_level):
				continue
			var d: float = a.global_position.distance_to(b.global_position)
			var in_door_a: bool = get_doorway_clearance_nudge(a.global_position, 22.0).length_squared() > 0.01
			var in_door_b: bool = get_doorway_clearance_nudge(b.global_position, 22.0).length_squared() > 0.01
			var req_d: float = 8.5 if (in_door_a or in_door_b) else min_dist
			if d < req_d:
				issues.append("%s and %s overlapping (dist=%.2f < %.1f at %s vs %s, elev=%d)" % [
					a.npc_name, b.npc_name, d, req_d, str(a.global_position.round()), str(b.global_position.round()), int(a.elevation_level)
				])
	return issues

## Si un NPC está parado justo en el umbral de una puerta (`<= radius`), devuelve un vector hacia adentro/afuera para despejar el paso

func get_doorway_clearance_nudge(pos: Vector2, radius: float = 18.0) -> Vector2:
	var r_sq: float = radius * radius
	for d_entry in building_doors:
		var d_pos: Vector2 = d_entry.get("pos", Vector2.ZERO)
		if pos.distance_squared_to(d_pos) <= r_sq:
			var b_rect: Rect2 = d_entry.get("building_rect", Rect2())
			var out_dir: Vector2 = get_door_outward_dir(d_entry)
			var is_inside: bool = b_rect.has_point(pos)
			return -out_dir if is_inside else out_dir
	return Vector2.ZERO

## Comprobación automática de todas las puertas del pueblo (presentes y futuras):
## 1) Que toda huella en `building_footprints` tenga puerta registrada con dirección (`door_dir` en N/S/E/O) y ancho >= `MIN_DUAL_LANE_DOOR_WIDTH` (dos personas).
## 2) Que sus dos carriles (`exit_lane` y `enter_lane`) estén bien separados y despejados de paredes/tabiques (`_wall_occluder_rects`) y de muebles (`prop_collider`).
func check_all_building_doors_and_lanes() -> Array:
	var issues: Array = []
	var prop_rects: Array[Rect2] = []
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group("prop_collider"):
			if n is StaticBody2D and is_instance_valid(n):
				var sb := n as StaticBody2D
				if sb.is_in_group("tavern_upper_walls"):
					continue
				var sz := Vector2(10.0, 10.0)
				for ch in sb.get_children():
					if ch is CollisionShape2D and ch.shape is RectangleShape2D:
						sz = (ch.shape as RectangleShape2D).size
				prop_rects.append(Rect2(sb.global_position - sz * 0.5, sz))

	for b in building_footprints:
		var b_id: String = str(b.get("id", "unknown"))
		var d_dir: String = str(b.get("door_dir", ""))
		if not (d_dir in ["south", "north", "east", "west"]):
			issues.append("%s: missing or invalid door_dir '%s'" % [b_id, d_dir])
		var d_w: float = float(b.get("door_width", 0.0))
		if d_w < MIN_DUAL_LANE_DOOR_WIDTH:
			issues.append("%s: door_width %.1f < %.1f (too narrow for 2 people)" % [b_id, d_w, MIN_DUAL_LANE_DOOR_WIDTH])

		var lanes: Dictionary = get_door_lanes(b, 0.0)
		var out_dir: Vector2 = lanes["out_dir"]
		var exit_side: Vector2 = lanes["exit_side"]
		var exit_c: Vector2 = lanes["exit_lane_center"]
		var enter_c: Vector2 = lanes["enter_lane_center"]
		var sep: float = absf((enter_c - exit_c).dot(exit_side))
		if sep < 14.0 or out_dir.length_squared() < 0.9:
			issues.append("%s: invalid door lanes (sep=%.1f, out_dir=%s)" % [b_id, sep, str(out_dir)])

		var exit_in: Vector2 = lanes["exit_inside_pt"]
		var exit_out: Vector2 = lanes["exit_outside_pt"]
		var enter_out: Vector2 = lanes["enter_outside_pt"]
		var enter_in: Vector2 = lanes["enter_inside_pt"]

		for w_rect in _wall_occluder_rects:
			if _segment_intersects_rect(exit_in, exit_out, w_rect):
				issues.append("%s: wall/partition %s blocks exit lane (%s -> %s)" % [b_id, str(w_rect), str(exit_in), str(exit_out)])
			if _segment_intersects_rect(enter_out, enter_in, w_rect):
				issues.append("%s: wall/partition %s blocks enter lane (%s -> %s)" % [b_id, str(w_rect), str(enter_out), str(enter_in)])

		for pr in prop_rects:
			if _segment_intersects_rect(exit_in, exit_out, pr.grow(3.0)):
				issues.append("%s: furniture/prop %s blocks exit lane (%s -> %s)" % [b_id, str(pr), str(exit_in), str(exit_out)])
			if _segment_intersects_rect(enter_out, enter_in, pr.grow(3.0)):
				issues.append("%s: furniture/prop %s blocks enter lane (%s -> %s)" % [b_id, str(pr), str(enter_out), str(enter_in)])

	for d_entry in building_doors:
		var db_id: String = str(d_entry.get("building_id", "unknown"))
		var dw: float = float(d_entry.get("width", 0.0))
		if dw < MIN_DUAL_LANE_DOOR_WIDTH:
			issues.append("door %s: width %.1f < %.1f" % [db_id, dw, MIN_DUAL_LANE_DOOR_WIDTH])
		var dd: String = str(d_entry.get("door_dir", ""))
		if not (dd in ["south", "north", "east", "west"]):
			issues.append("door %s: missing door_dir '%s'" % [db_id, dd])

	return issues

func _avoid_outdoor_buildings(from_pos: Vector2, target_pos: Vector2, ignore_b_id: String) -> Vector2:
	var cur_target: Vector2 = target_pos
	# 0. Si el trayecto cruza el río o toca el agua fuera de los puentes/vados, redirigir al puente/vado más cercano
	var side_from: float = from_pos.x - FishingSpot.river_center_x(from_pos.y)
	var side_to: float = cur_target.x - FishingSpot.river_center_x(cur_target.y)
	if side_from * side_to < 0.0:
		var cr: Dictionary = FishingSpot.nearest_river_crossing(from_pos, cur_target)
		var cr_pos: Vector2 = cr["pos"]
		var cr_hy: float = maxf(6.0, float(cr["half_y"]) - 4.0)
		var b_cr: Vector2 = FishingSpot.river_banks_at(cr_pos.y)
		if absf(from_pos.y - cr_pos.y) > cr_hy:
			var approach_x: float = (b_cr.x - 10.0) if side_from < 0.0 else (b_cr.y + 10.0)
			cur_target = Vector2(approach_x, cr_pos.y)
		else:
			var exit_x: float = (b_cr.y + 10.0) if side_to > 0.0 else (b_cr.x - 10.0)
			cur_target = Vector2(exit_x, cr_pos.y)
	# Mientras el destino (o el punto de llegada al puente) quede en esta orilla, no cortar por el agua: si el río hace
	# una curva por medio, ir antes a la orilla (2026-11-10: se metían en el agua yendo a la pasarela del norte).
	if side_from * (cur_target.x - FishingSpot.river_center_x(cur_target.y)) > 0.0:
		for s_i in range(1, 8):
			var t_s: float = float(s_i) / 8.0
			var p_s: Vector2 = from_pos.lerp(cur_target, t_s)
			if FishingSpot.is_point_in_river_water(p_s, 5.0):
				var b_s: Vector2 = FishingSpot.river_banks_at(p_s.y)
				var safe_x: float = (b_s.x - 11.0) if side_from < 0.0 else (b_s.y + 11.0)
				cur_target = Vector2(safe_x, p_s.y)
				break

	for _step in range(3):
		var blocking_b: Dictionary = {}
		var closest_d: float = INF
		for b in building_footprints:
			var b_id: String = str(b.get("id", ""))
			if b_id == ignore_b_id:
				continue
			var r_core: Rect2 = b["rect"].grow(-2.5)
			var r_avoid: Rect2 = b["rect"].grow(10.5) # > 9.5 de sanitize_npc_separation_pos: la ruta no roza el margen que frena (2026-11-09)
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

		# Si hay edificios contiguos con una separación estrecha (< 24 px) por donde no cabe un NPC,
		# fusionar sus huellas en un único bloque de esquiva para rodear la manzana por las calles exteriores.
		# (2026-11-10: antes < 18 px; pero el margen que frena junto a un muro es 9,5 px por lado y la ruta se aparta
		# 10,5 px, así que por un hueco de 18–23 px, como el de la herboristería y la pescadería, no se pasa y se atascaban.)
		var merged_rect: Rect2 = blocking_b["rect"]
		var merged_changed := true
		while merged_changed:
			merged_changed = false
			for b_other in building_footprints:
				var r_o: Rect2 = b_other["rect"]
				if not merged_rect.encloses(r_o) and merged_rect.grow(12.0).intersects(r_o.grow(12.0)):
					merged_rect = merged_rect.merge(r_o)
					merged_changed = true

		var r_inner: Rect2 = merged_rect.grow(7.0)
		var r_corners: Rect2 = merged_rect.grow(18.0)
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
			if sb.is_in_group("tavern_upper_walls"):
				continue
			var sz := Vector2(10.0, 10.0)
			for ch in sb.get_children():
				if ch is CollisionShape2D and ch.shape is RectangleShape2D:
					sz = (ch.shape as RectangleShape2D).size
			if _is_prop_collider_blocking_passage(sb.global_position, sz):
				sb.queue_free()

func _add_prop_collider(pos: Vector2, sz: Vector2, group_tag: String = "") -> StaticBody2D:
	var ancla: Dictionary = Anclas.buscar(pos)
	pos = Anclas.aplicar(ancla, pos)
	if not is_instance_valid(entities_root) or sz.x <= 0.0 or sz.y <= 0.0:
		return null
	if group_tag != "tavern_upper_walls" and _is_prop_collider_blocking_passage(pos, sz):
		return null
	var tag: String = group_tag
	if tag == "" and VillageTavern.RECT.has_point(_AN_SITIOS.desmover(pos)):
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
	Anclas.girar_choque(ancla, sb, sz)
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
		if fname in ["round_table_0.png", "table_chairs_0.png", "table_chairs_1.png", "big_round_table_chairs_0.png", "piano.png", "drinks_shelf_0.png", "drinks_shelf_1.png", "fireplace_0.png", "stand-1_part5.png"]:
			register_no_stand_furniture(pos, col_sz)

func _add_station_area(area_name: String, pos: Vector2, radius: float, meta_tag: String) -> Area2D:
	pos = Anclas.mover(pos, "zona", area_name)
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

func _is_pos_inside_any_building(world_pos: Vector2) -> bool:
	return not _get_building_at_pos(world_pos).is_empty()

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

func are_on_same_elevation(level_a: int, level_b: int) -> bool:
	return level_a == level_b

func distance_on_same_level(pos_a: Vector2, level_a: int, pos_b: Vector2, level_b: int) -> float:
	if not are_on_same_elevation(level_a, level_b):
		return INF
	return pos_a.distance_to(pos_b)

## Punto donde el jugador cambió de piso: si se aleja de él (sale de casa), vuelve solo a la calle.

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
	if player != null and player_elevation_level == 1 and VillageTavern.RECT.grow(14.0).has_point(_AN_SITIOS.desmover(player.global_position)):
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
			var same_elev: bool = are_on_same_elevation(v.elevation_level, player_elevation_level)
			var same_underground: bool = (int(v.elevation_level) == -1) == (int(player_elevation_level) == -1)
			if not same_underground:
				v.modulate.a = 0.0
			else:
				v.modulate.a = 1.0 if same_elev else 0.35
			if v.body_col:
				v.body_col.set_deferred("disabled", not (v.is_hostile and same_elev))
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
		if npc_pos.distance_to(d_pos) <= 24.0:
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
			d_entry["npc_pass_timer"] = 1.15
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

func _find_npc_by_name(target_name: String) -> VillageNPC:
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.npc_name == target_name and not v.is_dead:
				return v
	return null

func refresh_world_stage_3d() -> void:
	if is_instance_valid(world_stage_3d) and world_stage_3d.has_method("rebuild_all_3d"):
		world_stage_3d.rebuild_all_3d()

func _add_poly(pts: PackedVector2Array, col: Color, z_idx: int = -1, pos: Vector2 = Vector2.ZERO, parent_node: Node = null) -> Polygon2D:
	if pos != Vector2.ZERO:
		pos = Anclas.mover(pos)
	else:
		pts = Anclas.mover_puntos(pts)
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
	var p0 := pos # las paredes invisibles de abajo siguen al ancla por su cuenta (y giran con ella)
	var g_ancla: float = Anclas.giro(pos)
	pos = Anclas.mover(pos, "dibujo", (tex.resource_path if tex.resource_path != "" else str(tex.get_meta("src_path", ""))).get_file().get_basename() if tex != null else "")
	var s := Sprite2D.new()
	s.texture = tex
	s.global_position = pos
	s.scale = sc
	s.z_index = z_idx
	s.visible = vis
	if mod != Color.WHITE:
		s.modulate = mod
	if absf(g_ancla) > 0.5:
		s.set_meta("giro_3d", g_ancla) # el dibujo 3D gira con su ancla (WorldStageProps3D)
	entities_root.add_child(s)
	if tex != null and tex.has_meta("src_path"):
		var fname: String = str(tex.get_meta("src_path")).get_file()
		match fname:
			"work_stall.png", "storage_countertop_0.png":
				_add_prop_collider(p0, Vector2(16.0, 9.0))
			"water_well.png":
				_add_prop_collider(p0, Vector2(14.0, 14.0))
			"compost_bin.png":
				_add_prop_collider(p0, Vector2(10.0, 9.0))
			"pine-tree_0.png":
				_add_prop_collider(p0, Vector2(10.0, 10.0))
			"questboard_1.png", "sign_1.png", "lamp-post1.png":
				_add_prop_collider(p0, Vector2(7.0, 6.0))
			"morgue_table.png":
				_add_prop_collider(p0, Vector2(10.0, 14.0))
			"tavern_bed.png", "hospital_bed.png":
				var b_tag: String = "tavern_upper_walls" if VillageTavern.RECT.has_point(_AN_SITIOS.desmover(pos)) else ""
				_add_prop_collider(p0, Vector2(10.0, 14.0), b_tag)
	return s

func _add_title_label(pos: Vector2, min_sz: Vector2, txt: String, col: Color, f_sz: int = 7, parent_node: Node = null) -> Label:
	pos = Anclas.mover(pos + min_sz * 0.5, "letrero", txt) - min_sz * 0.5
	var lbl := Label.new()
	lbl.text = txt
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.scale = Vector2(0.62, 0.62)
	lbl.position = Vector2(pos.x + min_sz.x * (1.0 - lbl.scale.x) * 0.5, pos.y)
	lbl.custom_minimum_size = min_sz
	lbl.add_theme_font_size_override("font_size", f_sz)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.05, 0.92))
	lbl.add_theme_constant_override("outline_size", 2)
	(parent_node if parent_node else entities_root).add_child(lbl)
	lbl.add_to_group("world_title_label")
	return lbl

## Letreros del mapa sin amontonarse (2026-11-05): solo se ven los que están cerca del jugador (o bajo el ratón), y si
## dos se pisan, se queda el más cercano. Usa la transparencia (modulate.a), así no toca su `visible`.

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
	var focusing_npc: bool = false
	var isel = pl.get("interaction_selector")
	if isel != null and is_instance_valid(isel) and isel.has_method("selected"):
		var sel: Dictionary = isel.call("selected")
		if not sel.is_empty() and sel.get("target") is VillageNPC:
			focusing_npc = true
	var cands: Array = []
	for l in get_tree().get_nodes_in_group("world_title_label"):
		var lbl := l as Label
		if lbl == null or not lbl.is_visible_in_tree():
			continue
		if focusing_npc:
			lbl.modulate.a = 0.0
			continue
		var r: Rect2 = _title_text_rect(lbl)
		var anchor: Vector2 = lbl.get_meta("anchor_pos") if lbl.has_meta("anchor_pos") else r.get_center()
		var d: float = anchor.distance_to(pp)
		if d <= TITLE_SHOW_RADIUS:
			cands.append([d, lbl, r])
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
	pos = Anclas.mover(pos)
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
