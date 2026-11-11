@tool
extends CharacterBody2D
class_name VillageNPCBase
var _VillageRestaurant = load("res://scripts/systems/VillageRestaurant.gd") # R1b: comer en la trattoria
var _VillageTavern = load("res://scripts/systems/VillageTavern.gd") # Paso 3: taberna de 2 pisos y camarero
const _CombatFeel = preload("res://scripts/systems/combat/CombatFeel.gd") # C7 fase 2: rivales con las mismas reglas

## Habitante Sistémico de la Aldea con Casa, Familia, Sub-stats y Rutinas Dinámicas (IA de Utilidad) — Fase 2.3 y 2.4
## - Cada NPC pertenece a una Casa y Familia (`family_id`, `family_name`, `home_table_pos`, `bed_position`, `tavern_pos`).
## - Posee 3 Sub-stats dinámicos (0 a 100):
##   * 🍖 Hambre (`need_hunger`)
##   * 💤 Descanso (`need_energy`)
##   * 💬 Socialización (`need_social`)
## - En lugar de horarios fijos rígidos, evalúa dinámicamente sus necesidades (`ActivityState`):
##   trabaja cuando sus necesidades están cubiertas, va a comer a la mesa de su casa o a la Taberna cuando
##   tiene hambre, busca a su familia o amigos en la Taberna para conversar cuando necesita socializar,
##   y va a su cama cuando se queda sin energía (con ritmos metabólicos únicos para cada individuo).

enum TradeRole {
	UNEMPLOYED,         # Viajero sin oficio (vive en la Taberna, pasea y puede heredar un oficio si una familia entera falta)
	FAMILY_MEMBER,      # Familiar de un artesano (vive en la misma casa, ayuda en el hogar y es el heredero directo del oficio)
	INNKEEPER,          # Tabernera (regenta la Taberna El Jabalí Dorado)
	BUTCHER,            # 1. Carnicero y Peletero
	BLACKSMITH,         # 2. Herrero
	CARPENTER,          # 3. Carpintero
	HERBALIST,          # 4. Herborista y Agricultora
	FISHMONGER,         # 5. Pescador y Molinero
	DOCTOR,             # 6. Médico Cirujano y Forense del Hospital y Morgue
	SHERIFF,            # 7. Comisario Jefe de la Comisaría y Cárcel
	GUARD,              # 8. Guardia de Patrulla Policial
	TRAVELING_MERCHANT, # 9. Mercader Semanal de Extramuros con Salvoconducto Real (Casimir / Valeria)
	ROYAL_INVESTIGATOR, # 10. Inquisidor Real enviado por la Corona si asesinan a un Mercader Semanal
	PRIEST,             # 11. Sacerdote de la Capilla del Alba (G3): dirige el Oficio de los domingos
	BAKER,              # 12. Panadero (V5): hornea pan con harina del molino y leña
	TAILOR,             # 13. Sastre (V5): cose ropa con cuero; los ricos compran más
	LODGEKEEPER,        # 14. Posadero de El Candil (V5b): camas baratas y estofado sencillo
	FARMER,             # 15. Granjero (V5d): trigo y hortalizas en la Granja del Sur, con jornaleros
	RANCHER,            # 16. Ganadero (V5d): lana y carne en el rancho
	QUARRYMAN,          # 17. Cantero (V5d): piedra en la cantera del noroeste
	WOODCUTTER,         # 18. Leñador (V5d): madera en la linde del bosque
	TINKER,             # 21. Arreglador del Taller de Reparaciones (V5e): arregla tiendas saboteadas
	NOBLE,              # 22. Señor del valle, su familia y los rentistas (V6): viven de rentas, no del oficio
	CHILD,              # 23. Niño o niña (V9): nace en el pueblo, va a la escuela y a los 16 busca su sitio
	TEACHER,            # 24. Maestro de la escuela (V9): llega cuando hay niños en edad de ir
	RESTAURATEUR,       # 25. Cocinero de la Trattoria «Il Corvo» (R1): comedor, terraza, cocina y cámara frigorífica
	WAITER              # 26. Camarero de la Posada «El Jabalí Dorado» (Paso 3): recoge pedidos en las mesas y sirve platos desde la barra
}

## Oficios con taller y mostrador propios (V5: lista común para no repetirla en cada sitio)
const SHOP_ROLES: Array = [TradeRole.BLACKSMITH, TradeRole.BUTCHER, TradeRole.CARPENTER, TradeRole.HERBALIST, TradeRole.FISHMONGER, TradeRole.BAKER, TradeRole.TAILOR, TradeRole.LODGEKEEPER, TradeRole.FARMER, TradeRole.RANCHER, TradeRole.QUARRYMAN, TradeRole.WOODCUTTER, TradeRole.TINKER, TradeRole.RESTAURATEUR]

enum ActivityState {
	WORKING,     # Atendiendo su taller, ayudando en casa o paseando
	EATING,      # Yendo a comer a la mesa de su casa o a la Taberna
	SLEEPING,    # Durmiendo en su cama hasta recuperar energía
	SOCIALIZING  # Buscando a un familiar o vecino para charlar
}

@export var npc_id: String = "npc_01"
@export var npc_name: String = "Aldeano"
@export var npc_role: String = "Habitante"
@export var family_id: String = "none"
@export var family_name: String = "Sin Familia"
@export var trade_role: TradeRole = TradeRole.UNEMPLOYED
@export var linked_trade: TradeRole = TradeRole.UNEMPLOYED
@export var affinity: int = 10
## T3: rasgos de este vecino que el jugador ya conoce, y cómo se han ido revelando (ver TraitDiscovery).
var known_traits: Array[String] = []
## T2b: rasgos que te han contado otros y aún no has comprobado: id -> nombre de quien lo dijo (puede ser falso).
var rumored_traits: Dictionary = {}
## U5: lo que siente ESTE vecino por otros empieza oculto. Claves de los vecinos cuyo sentimiento ya conoce el jugador.
var known_feelings: Array[String] = []
## Partidas de antes de U5: el glosario ya lo enseñaba todo, así que se conserva todo a la vista.
var feelings_all_known: bool = false
## E4: lo que otros te han contado que siente este vecino: clave → {"by": quién lo contó, "rel": lo que sentía entonces}
var heard_feelings: Dictionary = {}
var trait_trust_tier: int = 0
var trait_first_impression_done: bool = false
var trait_lore_done: bool = false

# Experiencia y Curva de Eficiencia Laboral (0 días = Novato 35%, 2 días = Aprendiz Familiar 54%, 7+ días = Maestro 100%)
var days_in_role: int = 7

# Posiciones clave en la aldea para este NPC
var work_position: Vector2 = Vector2.ZERO
var bed_position: Vector2 = Vector2.ZERO
var home_table_pos: Vector2 = Vector2.ZERO
var tavern_social_pos: Vector2 = Vector2(420.0, -198.0)
var shop_stock: Dictionary = {}

# Economía Personal Real (`personal_gold`), Salvoconducto Real, Vagabundeo Rústico y Caza Amateur
var personal_gold: int = -1:
	set(v):
		# Impuesto sobre la renta: cada subida de su bolsillo cuenta como ingreso de la semana (cuando ya se le sigue).
		if _track_income and personal_gold >= 0 and v > personal_gold:
			income_week += v - personal_gold
		personal_gold = v
## Oro que ha ganado desde el último sábado de impuestos (sueldos, ventas, propinas, robos…).
var income_week: int = 0
## Se activa al día siguiente de llegar (así sus ahorros iniciales no cuentan como ingreso).
var _track_income: bool = false
var carries_royal_safe_conduct: bool = false
var pocket_items: Dictionary = {}
var corpse_pocket_looted: bool = false
var is_vagrant_camper: bool = false
var in_shelter: bool = false # V5b: sin dinero, pero duerme bajo techo en el Albergue del Alba
var lodging: String = "" # V5b: "candil" si se aloja en la posada humilde
var vagrant_camp_pos: Vector2 = Vector2.ZERO
var _is_amateur_foraging: bool = false
var _amateur_forage_timer: float = 0.0
var _amateur_prey_target: Node2D = null
var merchant_id: String = "" # "casimir" o "valeria"
var _merchant_leaving: bool = false

# Sub-stats de Necesidades Dinámicas (0.0 = crítico / 3 días sin comer, 100.0 = 300 pts Kenshi Bien Alimentado)
var need_hunger: float = 88.0
var digestion_buffer: float = 0.0 # Reserva en estómago (se absorbe gradualmente en `need_hunger`, estilo Kenshi)
var need_energy: float = 85.0
var need_social: float = 75.0

# Psicología Estilo RimWorld (Rasgos, Humor, Gustos y Pensamientos) + Ficha Social + Retratos 64x64 y Contexto Narrativo
var person_profile: RefCounted = null
var traits: Array[String] = []
var favorite_item: String = "bread"
var mood: float = 82.0
var thoughts: Array[String] = []
var portrait_texture: Texture2D = null
var character_tagline: String = ""
var character_lore: String = ""
var character_secret: String = ""
var founder_secrets: Array = [] # B6: 2–3 secretos iniciales sorteados para cada vecino fundador

# Control de Asiento en la Mesa de Juegos de la Taberna
var is_at_poker_table: bool = false
var poker_seat_pos: Vector2 = Vector2.ZERO
# Bloque PN: Nivel vertical / capa del mapa (-1 = sótano/alcantarillas, 0 = calle/planta baja, 1 = primer piso)
var elevation_level: int = 0

# Tasas metabólicas individuales (cada NPC tiene su propio ritmo para evitar comportamiento robótico sincronizado)
var _hunger_decay_rate: float = 1.15
var _energy_decay_rate: float = 0.95
var _social_decay_rate: float = 1.05

var current_activity: ActivityState = ActivityState.WORKING
var _eat_at_tavern: bool = false
var _restaurant_seat: Vector2 = Vector2.ZERO ## R1b: silla en la trattoria donde va a comer (ZERO = no)
var _tavern_seat: Vector2 = Vector2.ZERO ## Paso 3: silla libre de una mesa del salón de la taberna donde va a comer
var _meal_consumed_this_sitting: bool = false
var _has_valid_meal_this_sitting: bool = false
var _sitting_meal_ingested: float = 0.0
var _starvation_tick_timer: float = 0.0
var _social_partner = null
var _decision_timer: float = 0.0
# B2.2: Quedada activa organizada por el SocialDirector (-1 = ninguna). El VillageManager la asigna y la limpia.
var hangout_id: int = -1
## G2: sitio en la capilla durante el Oficio del Alba (ZERO = no va al Oficio)
var rite_pos: Vector2 = Vector2.ZERO
var rite_kind: String = "" # "rite" (Oficio del Alba), "sect" (reunión de la secta), "sect_lure" (víctima engañada)
## E1/E3/E5: encargos cortos a pie (lavarse «wash», beber «drink», jugar «gamble», pedir limosna «beg»); ver VillageNeeds
var errand_kind: String = ""
## Recados que se hacen de noche: no se cancelan al caer la noche (P5b: el perista en el callejón; B4: paseos nocturnos; B5: acecho).
const NIGHT_ERRANDS: Array[String] = ["fence_alley", "smuggler_bust", "gathering", "catering", "club_go", "club_watch", "night_job", "familia_meet", "night_stroll", "sleepwalk", "prowl_victim"]
var errand_pos: Vector2 = Vector2.ZERO
var errand_since: int = 0
## B4.1: Los vecinos despiertos llevan farol encendido de 20:00 a 6:00, salvo si van en sigilo, sonámbulos o de faena turbia.
var is_carrying_lantern: bool:
	get:
		if WorldClock == null or is_sleeping or is_incapacitated():
			return false
		if errand_kind in ["fence_alley", "night_job", "sleepwalk", "prowl_victim"]:
			return false
		var hr: int = int(WorldClock.current_hour)
		return hr >= 20 or hr < 6
## E1: higiene (100 limpio → 0 sucio). E2: 0 sano, 1 enfermo leve, 2 guarda cama (lo pone VillageIllness)
var need_hygiene: float = 80.0
var sick_level: int = 0
var live_fight_partner = null
var _live_fight_clock: float = 0.0
var hangout_spot_pos: Vector2 = Vector2.ZERO
var hangout_side: int = 0  # -1 / +1: cada participante se coloca a un lado del punto de encuentro
var hangout_spot_label: String = ""

var is_dead: bool = false
var is_downed: bool = false
var bleedout_timer: float = 0.0
var last_hit_weapon_name: String = "Herida desconocida"
var last_hit_by_player: bool = false
var sedated_timer: float = 0.0
var is_sleeping: bool = false
var is_stunned_flag: bool = false
var is_hostile: bool = false

# Estado de Cadáver Persistente en el Suelo, Descomposición y Traslado Natural a la Morgue
var corpse_on_ground: bool = false
var corpse_discovered: bool = false
var corpse_discovered_by: String = ""
var corpse_reported: bool = false
var corpse_reporter_npc = null
var corpse_being_carried: bool = false
var corpse_in_morgue: bool = false
var corpse_buried: bool = false
var corpse_carrier = null
var corpse_rot_hours: float = 0.0
var death_world_pos: Vector2 = Vector2.ZERO
var death_day: int = -1
var death_hour: int = -1
var death_minute: int = -1
var murder_witness_name: String = ""
var _carrying_corpse_target = null
var _reporting_corpse_target = null
var _corpse_report_phase: int = 0
var _corpse_report_timer: float = 0.0
var witness_silenced_player: bool = false
var witness_alibi_for_player: bool = false
var witness_framed_target_name: String = ""
var _interrog_correct_steps: int = 0
var _interrog_penalty_acc: int = 0
var _active_downed_patient = null

# Relaciones Dinámicas entre Vecinos (-100 a +100, estilo RimWorld) y Búsqueda de Familiares Ausentes
var npc_relationships: Dictionary = {} # other_npc_name -> int (-100..100)
var npc_relationship_notes: Dictionary = {} # other_npc_name -> String (motivo actual / historia común)
var _npc_social_event_cooldown: float = 0.0
var _pending_social_reply_timer: float = 0.0
var _pending_social_reply_data: Dictionary = {}
var last_social_line_spoken: String = ""
var _searching_missing_kin = null
var _missing_kin_phase: int = 0
var _missing_kin_timer: float = 0.0
var _missing_kin_reported_day: int = -1
var _kin_absence_worry_timer: float = 0.0
var _patrol_search_target_npc = null
var _patrol_search_target_pos: Vector2 = Vector2.ZERO
var _patrol_search_timer: float = 0.0
var _reacting_unconscious_target = null
var _unconscious_react_mode: String = "" # "opportunist_steal", "friend_rescue", "neutral_wake"
var _unconscious_react_phase: int = 0
var _unconscious_react_timer: float = 0.0
var _unconscious_helper_npc = null
var _unconscious_ignored_by: Dictionary = {} # npc_name -> bool (rivales que ya le robaron o desistieron en este desmayo)
var _unconscious_scan_timer: float = 0.0
var _witness_check_timer: float = 0.0
var _footprint_check_done: bool = false
var _footprint_supported: bool = false
var _witness_check_cached: Node2D = null

# Cachés de rendimiento por fotograma (evita escaneos redundantes a 60 FPS en laptops)
var _cached_player: Node2D = null
var _cached_vm: Node = null
var _cached_nav_waypoint: Vector2 = Vector2.INF
var _last_nav_dest: Vector2 = Vector2.INF
var _nav_waypoint_timer: float = 0.0
var _cached_sep_vec: Vector2 = Vector2.ZERO
var _sep_timer: float = 0.0
var _door_nudge_timer: float = 0.0
var _corpse_scan_timer: float = 0.0
var _doctor_scan_timer: float = 0.0
var _hover_label_timer: float = 0.0
## Vecino que enseña su ficha (el más cercano al ratón): así solo hay una a la vez.
static var _hover_owner: Node = null
static var _hover_owner_d: float = 0.0
static var _focused_npc: Node = null
static var _focused_npc_frame: int = -1
var _active_floating_text: Node = null

# Estado Policial y Sigilo (Negociación -> Persecución + Derribo No Letal / Asesinato Letal por la Espalda)
var _police_alerted_timer: float = 0.0
var _civilian_hostile_timer: float = 0.0
var _melee_windup_timer: float = 0.0
var _police_baton_windup_timer: float = 0.0
var police_mag_loaded: int = 5 ## 5e: cargador policial de 5 balas; al vaciarse recarga en 3 pasos (ventana para el jugador)
var police_reload_step: int = 0
var police_reload_timer: float = 0.0
var _police_warning_done: bool = false
var _police_warning_timer: float = 0.0
var disarmed_until_msec: int = 0 ## C7 fase 4c: sin porra ni pistola hasta entonces (le diste fuerte en el brazo)
var _melee_recover_timer: float = 0.0 ## C7 fase 2: quieto tras soltar un golpe (más si falló): ventana para castigarle
var _stagger_timer: float = 0.0
var _noise_react_timer: float = 0.0 ## B1 (C7 fase 4d): reacción al ruido de combate (guardia acude, civil huye o se asoma)
var _noise_react_pos: Vector2 = Vector2.ZERO
var _noise_react_mode: String = "" ## "guard_investigate", "civilian_flee", "civilian_peek"
var _noise_react_elev: int = 0
var _noise_witness_logged: bool = false
var _last_seen_player_pos: Vector2 = Vector2.ZERO
var _stuck_timer: float = 0.0
var _last_frame_pos: Vector2 = Vector2.ZERO
## Atasco lento (2026-11-11): cada segundo se mira cuánto avanzó de verdad; si es menos de un cuarto de su paso, está
## corriendo en el sitio (empujado atrás y adelante) aunque cada fotograma se mueva un poco.
var _avance_pos: Vector2 = Vector2.ZERO
var _avance_t: float = 0.0
var _atascado_lento: bool = false
var facing_direction: Vector2 = Vector2.DOWN
var facing_dir: Vector2:
	get:
		return facing_direction
	set(v):
		facing_direction = v
var _showing_stealth_prompt: bool = false

var sprite: Sprite2D = null
var body_col: CollisionShape2D = null
var hurtbox: Hurtbox = null
var interact_area: Area2D = null
var status_label: Label = null
var health_comp: HealthComponent = null
var stun_comp: StunComponent = null

var _wander_offset: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _step_phase: float = 0.0
var _has_spritesheet_anim: bool = false
var _anim_frame_timer: float = 0.0
var _anim_action_timer: float = 0.0
var _anim_cycle_clock: float = 0.0
var _attack_timer: float = 0.0
var _chat_bubble_timer: float = 0.0
var last_short_bubble_text: String = ""
var last_short_bubble_duration: float = 0.0
var _expedition_gather_timer: float = 0.0
var _completed_expedition_day: int = -1
var _expedition_target_node: Node2D = null

# Sistema de Crafteo en Tiempo Real con Barra de Progreso y Compras Físicas entre Vecinos
var workshop_materials: Dictionary = {}
var _is_actively_crafting: bool = false
var _craft_progress: float = 0.0
var _crafting_item_id: String = ""
var _crafting_recipe_idx: int = 0
var _supply_run_target_role: int = 0
var _supply_run_item_id: String = ""
var _supply_run_input_label: String = ""
var _supply_run_cooldown: float = 0.0
var _supply_run_timer: float = 0.0
var _craft_bar_root: Node2D = null
var _craft_bar_bg: Polygon2D = null
var _craft_bar_fill: Polygon2D = null
var _craft_bar_label: Label = null
var _being_interviewed_timer: float = 0.0
var _interviewer_node: Node2D = null
var _cached_dm: Node = null
var _self_tend_timer: float = 0.0
var _active_hospital_patient: Node2D = null
var _doctor_treat_progress: float = 0.0
var bloodstained_timer: float = 0.0
var seen_entities_memory: Array[Dictionary] = []
var _visual_memory_timer: float = 0.0

const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

const ROLE_INITIAL_GOLD: Dictionary = {
	TradeRole.INNKEEPER: Vector2i(68, 95), TradeRole.BLACKSMITH: Vector2i(68, 95),
	TradeRole.BUTCHER: Vector2i(48, 72), TradeRole.CARPENTER: Vector2i(48, 72),
	TradeRole.HERBALIST: Vector2i(48, 72), TradeRole.FISHMONGER: Vector2i(48, 72),
	TradeRole.BAKER: Vector2i(40, 62), TradeRole.TAILOR: Vector2i(48, 72), TradeRole.LODGEKEEPER: Vector2i(36, 58),
	TradeRole.FARMER: Vector2i(55, 80), TradeRole.RANCHER: Vector2i(55, 80), TradeRole.QUARRYMAN: Vector2i(45, 70), TradeRole.WOODCUTTER: Vector2i(40, 62), TradeRole.TINKER: Vector2i(45, 70), TradeRole.NOBLE: Vector2i(200, 300), TradeRole.CHILD: Vector2i(0, 0), TradeRole.TEACHER: Vector2i(30, 50), TradeRole.RESTAURATEUR: Vector2i(50, 76), TradeRole.WAITER: Vector2i(36, 58),
	TradeRole.DOCTOR: Vector2i(52, 78), TradeRole.SHERIFF: Vector2i(52, 78), TradeRole.GUARD: Vector2i(52, 78),
	TradeRole.FAMILY_MEMBER: Vector2i(26, 44), TradeRole.TRAVELING_MERCHANT: Vector2i(172, 238), TradeRole.ROYAL_INVESTIGATOR: Vector2i(110, 155),
}

const ROLE_INITIAL_MATERIALS: Dictionary = {
	TradeRole.BLACKSMITH: {"wood": 1, "leather": 1}, TradeRole.CARPENTER: {"iron_ore": 1, "herbal_poultice": 1},
	TradeRole.BUTCHER: {"wood": 1, "herbal_poultice": 1}, TradeRole.HERBALIST: {"bread": 1, "fertilizer": 1},
	TradeRole.FISHMONGER: {"wood": 1, "herbal_poultice": 1}, TradeRole.INNKEEPER: {"cooked_meat": 1, "bread": 1},
	TradeRole.DOCTOR: {"herbal_poultice": 2, "leather": 1},
	TradeRole.BAKER: {"bread": 1, "wood": 1}, TradeRole.TAILOR: {"leather": 2}, TradeRole.LODGEKEEPER: {"cooked_meat": 1},
	TradeRole.FARMER: {"fertilizer": 1}, TradeRole.RANCHER: {"wheat": 1}, TradeRole.QUARRYMAN: {"repair_kit": 1}, TradeRole.WOODCUTTER: {"repair_kit": 1}, TradeRole.TINKER: {"iron_ore": 1}, TradeRole.RESTAURATEUR: {"wheat": 1, "raw_meat": 1}, TradeRole.WAITER: {"bread": 1},
}

const ROLE_PSYCHOLOGY: Dictionary = {
	TradeRole.INNKEEPER: [["Hospitalaria", "Chef Apasionada"], "roasted_chicken", ["Olor a pan recién horneado (+8)", "La posada está animada (+6)"]],
	TradeRole.BUTCHER: [["Fuerte", "Carnívoro"], "fox_pelt", ["Buen corte de caza hoy (+6)"]],
	TradeRole.BLACKSMITH: [["Perfeccionista", "Forjador Maestro"], "iron_ore", ["Fragua al rojo vivo (+8)", "Orgulloso de sus armaduras (+5)"]],
	TradeRole.CARPENTER: [["Trabajador", "Amante del Bosque"], "wood", ["Madera de pino bien seca (+6)"]],
	TradeRole.HERBALIST: [["Naturista", "Pacífica"], "herbs", ["Las plantas crecen sanas (+7)"]],
	TradeRole.FISHMONGER: [["Paciente", "Madrugador"], "night_catfish", ["Brisa fresca junto al molino (+6)"]],
	TradeRole.BAKER: [["Madrugador", "Hogareño"], "bread", ["Huele a pan recién hecho (+7)"]],
	TradeRole.FARMER: [["Trabajador", "Madrugador"], "wheat", ["La cosecha viene bien (+6)"]],
	TradeRole.RANCHER: [["Paciente", "Amante de Animales"], "wool", ["Los animales están sanos (+6)"]],
	TradeRole.QUARRYMAN: [["Fuerte", "Callado"], "stone", ["Buena veta de piedra hoy (+5)"]],
	TradeRole.WOODCUTTER: [["Fuerte", "Amante del Bosque"], "wood", ["El hacha corta bien (+5)"]],
	TradeRole.TINKER: [["Mañoso", "Paciente"], "repair_kit", ["Lo roto, arreglado (+6)"]],
	TradeRole.NOBLE: [["Orgulloso", "Refinado"], "roasted_chicken", ["Las cuentas de las tierras cuadran (+4)"]],
	TradeRole.CHILD: [["Juguetón", "Curioso"], "bread", ["Jugando con los demás (+6)"]],
	TradeRole.TEACHER: [["Paciente", "Curioso"], "bread", ["Los niños aprenden (+5)"]],
	TradeRole.LODGEKEEPER: [["Hospitalario", "Sencillo"], "country_stew", ["Hay luz en El Candil (+5)"]],
	TradeRole.RESTAURATEUR: [["Hospitalario", "Perfeccionista"], "pasta_dish", ["El comedor está lleno (+6)"]],
	TradeRole.WAITER: [["Hospitalario", "Alegre"], "country_stew", ["Las mesas de la taberna están llenas (+6)"]],
	TradeRole.TAILOR: [["Perfeccionista", "Coqueto"], "clothes", ["Una costura perfecta (+6)"]],
	TradeRole.DOCTOR: [["Cirujano Experto", "Forense Meticuloso"], "surgical_kit", ["Urgencias y morgue en orden (+8)"]],
	TradeRole.SHERIFF: [["Justiciero", "Observador"], "cooked_meat", ["Vigilando la ley en el valle (+7)"]],
	TradeRole.GUARD: [["Leal", "Alerta"], "bread", ["Patrulla sin novedad (+6)"]],
	TradeRole.TRAVELING_MERCHANT: [["Mercader Real", "Portador de Salvoconducto"], "royal_ration", ["Comerciando entre el valle y las Tierras Reales (+10)"]],
	TradeRole.ROYAL_INVESTIGATOR: [["Inquisidor Implacable", "Deducción Forense", "Nunca Vuelve Vacío"], "royal_ration", ["La Corona exige un culpable (+12)"]],
}

const NPCData = preload("res://scripts/data/NPCData.gd")
const PersonProfile = preload("res://scripts/data/PersonProfile.gd")
var NPCDialogue = load("res://scripts/enemies/NPCDialogue.gd")
var TraitDiscovery = load("res://scripts/systems/TraitDiscovery.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
var VillageFaith = load("res://scripts/systems/VillageFaith.gd")
const NPC_NAME_ALIASES: Dictionary = NPCData.NPC_NAME_ALIASES

const NPC_LORE_PROFILES: Dictionary = NPCData.NPC_LORE_PROFILES
const INITIAL_PERSON_PROFILES: Dictionary = NPCData.INITIAL_PERSON_PROFILES

const ROLE_FALLBACK_LORE: Dictionary = {
	TradeRole.DOCTOR: ["valen", "valen", "Médico forense y cirujano rural enviado por el Colegio Médico para mantener operativo el Hospital y la Morgue del valle."],
	TradeRole.SHERIFF: ["vane", "vane", "Alguacil mayor de frontera designado para restablecer la ley, investigar crímenes y dirigir las patrullas del valle."],
	TradeRole.GUARD: ["rodric", "rodric", "Centinela de guardia asignado a la comisaría local para vigilar las calles, entradas y comercios de la aldea."],
	TradeRole.INNKEEPER: ["marta", "marta", "Regente de 'El Jabalí Dorado'; sirve platos calientes y administra las mesas de juego del salón."],
	TradeRole.BLACKSMITH: ["thoran", "kiera", "Maestro forjador llegado de los valles vecinos para mantener encendida la fragua y abastecer de herramientas al pueblo."],
	TradeRole.BUTCHER: ["garrick", "lina", "Cazador y maestro carnicero encargado de abastecer de carne fresca y cuero curado a la aldea."],
	TradeRole.CARPENTER: ["bram", "mila", "Maestro ebanista y carpintero llegado para mantener en pie el aserradero y los talleres locales."],
	TradeRole.FISHMONGER: ["marlo", "nora", "Pescador y molinero encargado de las redes del lago y de la molienda de grano para el valle."],
	TradeRole.FARMER: ["tomas", "lina", "Granjero que labra los campos del sur con ayuda de jornaleros y vende trigo al molino y a la panadería."],
	TradeRole.RANCHER: ["garrick", "nora", "Ganadero del rancho del sur: cría animales por su lana y su carne."],
	TradeRole.QUARRYMAN: ["thoran", "kiera", "Cantero que saca piedra en la ladera del noroeste para las obras del pueblo."],
	TradeRole.CHILD: ["tomas", "nora", "Criatura nacida en el valle: corretea por las calles, va a la escuela y lo pregunta todo."],
	TradeRole.TEACHER: ["dario", "marta", "Maestro de la escuela del pueblo: enseña a leer, a contar y a portarse."],
	TradeRole.NOBLE: ["thoran", "elena", "Gente de la loma: viven de las rentas de las tierras de labor y miran el pueblo desde arriba."],
	TradeRole.TINKER: ["kael", "sora", "Arreglador que remienda lo que se rompe en el pueblo: puestos, herramientas y cerrojos."],
	TradeRole.WOODCUTTER: ["bram", "mila", "Leñador que corta madera en la linde del bosque para carpinteros, hornos y hogares."],
	TradeRole.LODGEKEEPER: ["dario", "nora", "Posadero modesto que alquila camas baratas a quien no puede pagar El Jabalí Dorado."],
	TradeRole.RESTAURATEUR: ["marlo", "mila", "Cocinero que regenta la Casa de Comidas «El Fogón del Valle»: guiso de trigo, asados de caza y una mesa al fondo para quien no quiere ser visto."],
	TradeRole.WAITER: ["dario", "sora", "Camarero de salón en «El Jabalí Dorado»: toma nota en las mesas, recoge los platos calientes en la barra y conoce todos los rumores del salón y del sótano."],
	TradeRole.BAKER: ["marlo", "marta", "Panadero llegado de un valle vecino para encender el horno de la calle norte y dar pan a casas y posadas."],
	TradeRole.TAILOR: ["dario", "mila", "Sastre de mano fina que remienda la ropa del pueblo y cose prendas nuevas para quien pueda pagarlas."],
	TradeRole.HERBALIST: ["tomas", "elena", "Herborista y botánico rural dedicado al cultivo de semillas y a la preparación de cataplasmas medicinales."],
	TradeRole.FAMILY_MEMBER: ["aldric", "sora", "Viajero independiente recién llegado a la frontera en busca de fortuna y de un oficio estable en el valle."],
	TradeRole.UNEMPLOYED: ["aldric", "sora", "Viajero independiente recién llegado a la frontera en busca de fortuna y de un oficio estable en el valle."],
}


static var _tex_64_cache: Dictionary = {}

const INITIAL_NPC_RELATIONS: Dictionary = NPCData.INITIAL_NPC_RELATIONS

## Devuelve el identificador único (`person_id`) de un vecino a partir de su `person_id` o `npc_name` (solo entre vecinos vivos).
var _pre_poker_pos: Vector2 = Vector2.ZERO

const LOD_DIST: float = 360.0 # La cámara (zoom 3, 1280x720) ve unos 430x240; con margen
const LOD_STEP: int = 4
## Rendimiento (2026-11-10): a media distancia (~14–36 m en 1.ª persona) el vecino piensa 1 de cada 2 pasos de física y
## recorre en ese paso la distancia de los dos (como los lejanos). Medido en el portátil: los vecinos costaban ~19 ms por fotograma.
const LOD_DIST_MEDIO: float = 140.0
var _lod_acc: float = 0.0
var _lod_phase: int = -1
var _lod_tick: int = 0
var _lod_k: float = 1.0
## B3 (orden del usuario, 2026-11-06): apagado. Los vecinos lejanos viven siempre al detalle; medido: cuesta ~1 fps.
## Queda como opción por si algún día hace falta.
static var lod_enabled: bool = true # Activado por el usuario (2026-11-09): vecinos lejanos (>360 px) piensan 1 de cada 4 pasos

static var perf_on: bool = false
static var perf_usec: Dictionary = {}

const EXPEDITION_TARGETS: Dictionary = {
	TradeRole.CARPENTER: Vector2(65, 790), TradeRole.BLACKSMITH: Vector2(515, 795),
	TradeRole.HERBALIST: Vector2(-180, 810), TradeRole.FISHMONGER: Vector2(-683, 105), TradeRole.BUTCHER: Vector2(142, 785),
}

const EXPEDITION_DESCS: Dictionary = {
	TradeRole.CARPENTER: "🪓 Expedición Matutina: Talando Pinos",
	TradeRole.BLACKSMITH: "⛏️ Expedición Matutina: Picando Hierro",
	TradeRole.HERBALIST: "🌿 Expedición Matutina: Recogiendo Hierbas",
	TradeRole.FISHMONGER: "🎣 Expedición Matutina: Pescando en el Lago",
	TradeRole.BUTCHER: "🏹 Expedición Matutina: Cazando en el Bosque",
}

var _npc_env_sickness_timer: float = 0.0

const IDLE_STROLL_SPOTS: Array[Vector2] = [
	Vector2(304, 280), Vector2(236, 268), Vector2(360, 280), # Parque del Roble
	Vector2(-715, 166), Vector2(215, 145), # Mirador del Lago y Lavadero
	Vector2(215, 44), Vector2(340, 44), Vector2(540, 44), Vector2(680, 44), Vector2(820, 44), Vector2(990, 44), # Calle Principal
	Vector2(330, -352), Vector2(520, -352), Vector2(740, -352), Vector2(940, -352), # Calle Norte
	Vector2(672, -210), Vector2(575, 225), Vector2(825, 225), # Barrio Residencial, Albergue y Capilla
]

const ARTISAN_RECIPES: Dictionary = {
	TradeRole.BLACKSMITH: [{"output": "steel_ingot", "label": "Lingote Acero", "verb": "⚒️ Forjando", "input": "wood", "supplier": int(TradeRole.CARPENTER), "input_name": "Madera"}, {"output": "repair_kit", "label": "Kit Herrero", "verb": "⚒️ Templando", "input": "leather", "supplier": int(TradeRole.BUTCHER), "input_name": "Cuero"}, {"output": "steel_ingot", "label": "Lingote Acero", "verb": "⚒️ Fundiendo", "input": "stone", "supplier": int(TradeRole.QUARRYMAN), "input_name": "Piedra de horno"}],
	TradeRole.CARPENTER: [{"output": "repair_kit", "label": "Tablones", "verb": "🪚 Aserrando", "input": "iron_ore", "supplier": int(TradeRole.BLACKSMITH), "input_name": "Clavos/Hierro"}, {"output": "wood", "label": "Vigas Pino", "verb": "🪚 Cepillando", "input": "herbal_poultice", "supplier": int(TradeRole.HERBALIST), "input_name": "Resina/Hierbas"}, {"output": "copper_coil", "label": "Bobina Cobre", "verb": "⚡ Bobinando", "input": "iron_ore", "supplier": int(TradeRole.BLACKSMITH), "input_name": "Hierro/Cobre"}, {"output": "repair_kit", "label": "Tablones", "verb": "🪚 Serrando troncos", "input": "wood", "supplier": int(TradeRole.WOODCUTTER), "input_name": "Troncos"}],
	TradeRole.BUTCHER: [{"output": "cooked_meat", "label": "Carne Asada", "verb": "🥩 Ahumando", "input": "wood", "supplier": int(TradeRole.CARPENTER), "input_name": "Leña"}, {"output": "leather", "label": "Cuero Curtido", "verb": "🔪 Curtiendo", "input": "herbal_poultice", "supplier": int(TradeRole.HERBALIST), "input_name": "Tanino/Hierbas"}, {"output": "cooked_meat", "label": "Carne del Rancho", "verb": "🥩 Despiezando", "input": "raw_meat", "supplier": int(TradeRole.RANCHER), "input_name": "Carne del rancho"}],
	TradeRole.HERBALIST: [{"output": "herbal_poultice", "label": "Cataplasma", "verb": "🧪 Destilando", "input": "bread", "supplier": int(TradeRole.FISHMONGER), "input_name": "Grano/Harina"}, {"output": "carrot_seeds", "label": "Semillas", "verb": "🌱 Seleccionando", "input": "fertilizer", "supplier": int(TradeRole.FISHMONGER), "input_name": "Abono"}, {"output": "sleeping_draught", "label": "Somnífero", "verb": "🌙 Alambicando", "input": "bread", "supplier": int(TradeRole.FISHMONGER), "input_name": "Extracto"}, {"output": "surgical_kit", "label": "Botiquín Quir.", "verb": "🩺 Esterilizando", "input": "fertilizer", "supplier": int(TradeRole.FISHMONGER), "input_name": "Sales"}],
	TradeRole.FISHMONGER: [{"output": "bread", "label": "Hogaza Pan", "verb": "🌾 Moliendo", "input": "wood", "supplier": int(TradeRole.CARPENTER), "input_name": "Leña"}, {"output": "fertilizer", "label": "Abono Org.", "verb": "♻️ Compostando", "input": "herbal_poultice", "supplier": int(TradeRole.HERBALIST), "input_name": "Hierbas"}],
	TradeRole.INNKEEPER: [{"output": "country_stew", "label": "Estofado", "verb": "🍲 Guisando", "input": "cooked_meat", "supplier": int(TradeRole.BUTCHER), "input_name": "Carne"}, {"output": "bread", "label": "Pan Posada", "verb": "🍞 Horneando", "input": "bread", "supplier": int(TradeRole.FISHMONGER), "input_name": "Harina"}, {"output": "roasted_chicken", "label": "Pollo Asado", "verb": "🍗 Asando", "input": "cooked_meat", "supplier": int(TradeRole.BUTCHER), "input_name": "Aves/Carne"}],
	TradeRole.DOCTOR: [{"output": "bandage", "label": "Vendaje Limpio", "verb": "🩹 Esterilizando", "input": "herbal_poultice", "supplier": int(TradeRole.HERBALIST), "input_name": "Cataplasma"}, {"output": "herbal_poultice", "label": "Cataplasma", "verb": "🧪 Preparando", "input": "bread", "supplier": int(TradeRole.FISHMONGER), "input_name": "Base Vegetal"}, {"output": "surgical_kit", "label": "Botiquín Quir.", "verb": "🩺 Ensamblando", "input": "leather", "supplier": int(TradeRole.BUTCHER), "input_name": "Sutura/Cuero"}],
	TradeRole.BAKER: [{"output": "bread", "label": "Hogaza", "verb": "🍞 Horneando", "input": "bread", "supplier": int(TradeRole.FISHMONGER), "input_name": "Harina"}, {"output": "bread", "label": "Pan de Leña", "verb": "🔥 Avivando el horno", "input": "wood", "supplier": int(TradeRole.CARPENTER), "input_name": "Leña"}, {"output": "bread", "label": "Pan de Trigo", "verb": "🍞 Amasando", "input": "wheat", "supplier": int(TradeRole.FARMER), "input_name": "Trigo"}],
	TradeRole.TAILOR: [{"output": "clothes", "label": "Ropa", "verb": "🧵 Cosiendo", "input": "leather", "supplier": int(TradeRole.BUTCHER), "input_name": "Cuero"}, {"output": "clothes", "label": "Ropa de Lana", "verb": "🧶 Tejiendo", "input": "wool", "supplier": int(TradeRole.RANCHER), "input_name": "Lana"}],
	TradeRole.LODGEKEEPER: [{"output": "country_stew", "label": "Estofado", "verb": "🍲 Guisando", "input": "cooked_meat", "supplier": int(TradeRole.BUTCHER), "input_name": "Carne"}],
	TradeRole.RESTAURATEUR: [{"output": "pasta_dish", "label": "Guiso de trigo", "verb": "🍲 Removiendo el guiso de trigo", "input": "wheat", "supplier": int(TradeRole.FARMER), "input_name": "Trigo"}, {"output": "braised_meat", "label": "Asado de caza", "verb": "🥩 Asando carne a la brasa", "input": "raw_meat", "supplier": int(TradeRole.RANCHER), "input_name": "Carne"}],
	TradeRole.FARMER: [{"output": "wheat", "label": "Trigo", "verb": "🌾 Segando", "input": "fertilizer", "supplier": int(TradeRole.FISHMONGER), "input_name": "Abono"}, {"output": "carrot", "label": "Zanahorias", "verb": "🥕 Recogiendo", "input": "fertilizer", "supplier": int(TradeRole.FISHMONGER), "input_name": "Abono"}],
	TradeRole.RANCHER: [{"output": "wool", "label": "Lana", "verb": "🐑 Esquilando", "input": "wheat", "supplier": int(TradeRole.FARMER), "input_name": "Pienso"}, {"output": "raw_meat", "label": "Carne", "verb": "🐖 Cuidando el ganado", "input": "wheat", "supplier": int(TradeRole.FARMER), "input_name": "Pienso"}],
	TradeRole.QUARRYMAN: [{"output": "stone", "label": "Piedra", "verb": "⛏️ Picando piedra", "input": "repair_kit", "supplier": int(TradeRole.BLACKSMITH), "input_name": "Herramientas"}],
	TradeRole.WOODCUTTER: [{"output": "wood", "label": "Madera", "verb": "🪓 Talando", "input": "repair_kit", "supplier": int(TradeRole.BLACKSMITH), "input_name": "Hacha afilada"}],
	TradeRole.TINKER: [{"output": "repair_kit", "label": "Kit de Reparación", "verb": "🔧 Remendando", "input": "iron_ore", "supplier": int(TradeRole.BLACKSMITH), "input_name": "Hierro"}],
}

const NATURAL_DEATH_TAGS: Array[String] = ["Embestida de jabalí", "Mordedura de zorro", "Ataque de animal salvaje", "Inanición", "Enfermedad"]
const SAVED_INT_METAS: Array = ["evicted_day", "inherited_day", "read_day", "arrived_day", "rite_invited_week", "new_clothes_day", "school_bonus_days"]
const SAVED_STR_METAS: Array = ["evicted_lot", "inherited_from", "inherited_family"]


func is_incapacitated() -> bool:
	return is_dead or is_downed or is_stunned_flag or sedated_timer > 0.0

func is_conscious() -> bool:
	return not is_incapacitated() and not is_sleeping

func _get_vm() -> Node:
	if not is_instance_valid(_cached_vm):
		_cached_vm = get_tree().get_first_node_in_group("village_manager")
	return _cached_vm

func _get_player() -> Node2D:
	if not is_instance_valid(_cached_player):
		_cached_player = get_tree().get_first_node_in_group("player") as Node2D
	return _cached_player

func _set_area_col_disabled(area: Node, dis: bool) -> void:
	if area and area.get_child_count() > 0 and area.get_child(0) is CollisionShape2D:
		(area.get_child(0) as CollisionShape2D).set_deferred("disabled", dis)

func _clear_combat_hostility(disable_col: bool = true) -> void:
	is_hostile = false
	_civilian_hostile_timer = 0.0
	remove_from_group("enemies")
	if disable_col and body_col:
		body_col.set_deferred("disabled", true)
	velocity = Vector2.ZERO

func _set_sprite_pose(rot_deg: float, mod_col: Color = Color.WHITE) -> void:
	if sprite:
		sprite.rotation_degrees = rot_deg
		sprite.modulate = mod_col

func is_bloodstained() -> bool:
	return bloodstained_timer > 0.0

func add_bloodstain(duration: float = 180.0) -> void:
	bloodstained_timer = maxf(bloodstained_timer, duration)

func _add_circle_col(parent: Node, radius: float, disabled: bool = false) -> CollisionShape2D:
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	col.shape = shape
	col.disabled = disabled
	parent.add_child(col)
	return col

func _style_label(lbl: Label, pos: Vector2, min_sz: Vector2, f_size: int, f_col: Color, out_sz: int, z_idx: int = 0) -> void:
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = pos
	lbl.custom_minimum_size = min_sz
	lbl.add_theme_font_size_override("font_size", f_size)
	lbl.add_theme_color_override("font_color", f_col)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", out_sz)
	if z_idx != 0:
		lbl.z_index = z_idx

func _stop_crafting_bar() -> void:
	_is_actively_crafting = false
	if _craft_bar_root:
		_craft_bar_root.visible = false

func _get_pocket_loot_hint(inline_sep: bool = false) -> String:
	if corpse_pocket_looted or (personal_gold <= 0 and not carries_royal_safe_conduct and pocket_items.is_empty()):
		return ""
	var seal_str: String = (" + 📜Salvoconducto Real" if inline_sep else " + 📜 Salvoconducto Real") if carries_royal_safe_conduct else (" + Objetos" if not pocket_items.is_empty() else "")
	return (" | [E: 💰 Saquear Bolsillos (%d Oro%s)]" % [maxi(0, personal_gold), seal_str]) if inline_sep else ("\n[E: 💰 Saquear Bolsillos (%d Oro%s)]" % [maxi(0, personal_gold), seal_str])

func _spawn_shot_tracer(to_pos: Vector2, color: Color, width: float = 2.0, z_idx: int = 18, end_offset_y: float = -6.0, fade_dur: float = 0.18) -> void:
	var tracer := Line2D.new()
	tracer.width = width
	tracer.default_color = color
	tracer.points = PackedVector2Array([global_position + Vector2(0, -6), to_pos + Vector2(0, end_offset_y)])
	tracer.z_index = z_idx
	var parent_scene: Node = get_tree().current_scene if get_tree().current_scene else get_parent()
	if parent_scene:
		parent_scene.add_child(tracer)
		var tw := tracer.create_tween()
		tw.tween_property(tracer, "modulate:a", 0.0, fade_dur)
		tw.tween_callback(tracer.queue_free)

func hold_for_interview(interviewer: Node2D, duration: float = 0.8) -> void:
	_being_interviewed_timer = maxf(_being_interviewed_timer, duration)
	_interviewer_node = interviewer

func has_pocket_item(item_id: String, count: int = 1) -> bool:
	if item_id == "royal_safe_conduct" and carries_royal_safe_conduct:
		return true
	return int(pocket_items.get(item_id, 0)) >= count

func add_pocket_item(item_id: String, count: int = 1) -> void:
	if item_id == "" or count <= 0:
		return
	pocket_items[item_id] = int(pocket_items.get(item_id, 0)) + count
	if item_id == "royal_safe_conduct":
		carries_royal_safe_conduct = true
	corpse_pocket_looted = false

func remove_pocket_item(item_id: String, count: int = 1) -> bool:
	var cur: int = int(pocket_items.get(item_id, 0))
	if item_id == "royal_safe_conduct" and carries_royal_safe_conduct and cur <= 0:
		cur = 1
	if cur < count:
		return false
	var left: int = cur - count
	if left <= 0:
		pocket_items.erase(item_id)
		if item_id == "royal_safe_conduct":
			carries_royal_safe_conduct = false
	else:
		pocket_items[item_id] = left
	return true

func get_pocket_summary_text() -> String:
	if carries_royal_safe_conduct and int(pocket_items.get("royal_safe_conduct", 0)) <= 0:
		pocket_items["royal_safe_conduct"] = 1
	var parts: Array[String] = []
	if personal_gold > 0:
		parts.append("💰 %d Oro" % personal_gold)
	for k in pocket_items.keys():
		var cnt: int = int(pocket_items[k])
		if cnt > 0:
			var info: Dictionary = SimpleInventory.CATALOG.get(str(k), {})
			var nm: String = str(info.get("name", k))
			parts.append("%s x%d" % [nm, cnt])
	return ", ".join(parts) if not parts.is_empty() else "Bolsillos vacíos"

func resolve_person_id_key(key_or_name: String) -> String:
	var clean := key_or_name.strip_edges()
	if clean == "":
		return ""
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPCBase and not n.is_dead:
				var vn := n
				var pid: String = str(vn.person_profile.person_id) if vn.person_profile != null else vn.npc_id
				if pid == clean or vn.npc_name == clean:
					return pid if pid != "" else vn.npc_name
	var lookup_name: String = str(NPC_NAME_ALIASES.get(clean, clean))
	if INITIAL_PERSON_PROFILES.has(lookup_name):
		return str(INITIAL_PERSON_PROFILES[lookup_name].get("person_id", clean))
	return clean

## Migra al vuelo cualquier entrada en `npc_relationships` / `npc_relationship_notes` que hubiera sido escrita con `npc_name` en vez de `person_id`.

func _migrate_legacy_relationship_keys() -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if not (n is VillageNPCBase) or n == self or n.is_dead:
			continue
		var other := n
		var o_id: String = str(other.person_profile.person_id) if other.person_profile != null else other.npc_id
		var o_name: String = other.npc_name
		if o_id != "" and o_name != "" and o_id != o_name:
			if npc_relationships.has(o_name):
				npc_relationships[o_id] = int(npc_relationships[o_name])
				npc_relationships.erase(o_name)
			if npc_relationship_notes.has(o_name):
				npc_relationship_notes[o_id] = str(npc_relationship_notes[o_name])
				npc_relationship_notes.erase(o_name)

## Elimina de este NPC cualquier vínculo con un fallecido para no acumular basura ni permitir herencias fantasma.

func purge_deceased_relationship(dead_id: String, dead_name: String = "") -> void:
	if dead_id != "":
		npc_relationships.erase(dead_id)
		npc_relationship_notes.erase(dead_id)
	if dead_name != "":
		npc_relationships.erase(dead_name)
		npc_relationship_notes.erase(dead_name)

## Inicializa de forma determinista y basada en el lore las relaciones iniciales de este NPC con todos los vecinos vivos del pueblo (indexadas por `person_id`).

func ensure_npc_relationships_initialized() -> void:
	if not is_inside_tree():
		return
	_migrate_legacy_relationship_keys()
	var my_id: String = str(person_profile.person_id) if person_profile != null else npc_id
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if not (n is VillageNPCBase) or n == self:
			continue
		var other := n
		if other.is_dead:
			continue
		var o_name: String = other.npc_name
		var o_id: String = str(other.person_profile.person_id) if other.person_profile != null else other.npc_id
		var key: String = o_id if o_id != "" else o_name
		if key == "" or npc_relationships.has(key):
			continue
		if family_id != "none" and family_id != "" and family_id != "family_police" and other.family_id == family_id:
			npc_relationships[key] = 85
			npc_relationship_notes[key] = "Familia cercana (%s)" % family_name
			continue
		var k1: String = "%s|%s" % [npc_name, o_name]
		var k2: String = "%s|%s" % [o_name, npc_name]
		if INITIAL_NPC_RELATIONS.has(k1):
			var info1: Array = INITIAL_NPC_RELATIONS[k1]
			npc_relationships[key] = int(info1[0])
			npc_relationship_notes[key] = str(info1[1])
		elif INITIAL_NPC_RELATIONS.has(k2):
			var info2: Array = INITIAL_NPC_RELATIONS[k2]
			npc_relationships[key] = int(info2[0])
			npc_relationship_notes[key] = str(info2[1])
		else:
			var a_key: String = my_id if my_id != "" else npc_name
			var pair_hash: int = abs((a_key + "_" + key).hash() if a_key < key else (key + "_" + a_key).hash())
			var base_rel: int = (pair_hash % 45) - 18
			if trade_role == TradeRole.INNKEEPER or other.trade_role == TradeRole.INNKEEPER:
				base_rel = maxi(base_rel, 18)
			npc_relationships[key] = clampi(base_rel, -100, 100)
			if base_rel >= 20:
				npc_relationship_notes[key] = "Simpatía vecinal y charlas en la plaza"
			elif base_rel <= -12:
				npc_relationship_notes[key] = "Roce de carácter y opiniones distintas"
			else:
				npc_relationship_notes[key] = "Trato vecinal cotidiano"

func get_relationship_with_npc(other_key_or_name: String) -> int:
	var my_id: String = str(person_profile.person_id) if person_profile != null else npc_id
	if other_key_or_name == "" or other_key_or_name == npc_name or other_key_or_name == my_id:
		return 0
	if npc_relationships.has(other_key_or_name):
		return clampi(int(npc_relationships[other_key_or_name]), -100, 100) # V1: camino rápido (ya guardado por id); antes recorría el pueblo dos veces en cada consulta
	_migrate_legacy_relationship_keys()
	var key: String = resolve_person_id_key(other_key_or_name)
	if not npc_relationships.has(key):
		ensure_npc_relationships_initialized()
	return clampi(int(npc_relationships.get(key, 0)), -100, 100)

func get_relationship_note_with_npc(other_key_or_name: String) -> String:
	if npc_relationship_notes.has(other_key_or_name):
		return str(npc_relationship_notes[other_key_or_name])
	_migrate_legacy_relationship_keys()
	var key: String = resolve_person_id_key(other_key_or_name)
	if not npc_relationship_notes.has(key):
		ensure_npc_relationships_initialized()
	return str(npc_relationship_notes.get(key, "Trato vecinal cotidiano"))

static func get_relationship_tier_label(val: int, is_same_family: bool = false, is_partner: bool = false) -> String:
	if is_partner:
		return "💑 Pareja"
	if is_same_family and val >= 50:
		return "🏠 Familia Cercana"
	if val >= 65:
		return "🌟 Mejor Amigo / Íntimo"
	if val >= 35:
		return "🤝 Amigo"
	if val >= 12:
		return "🙂 Cordial"
	if val > -12:
		return "😐 Neutral"
	if val > -30:
		return "😒 Frío / Distante"
	if val > -55:
		return "💢 Rival"
	return "⚔️ Enemigo Acérrimo"

## Modifica dinámicamente la relación mutua entre dos NPCs y detecta giros dramáticos ("por azares del destino")
## `one_way` (U1): solo cambia lo que ESTE vecino siente por `other`; el otro no se entera y no hay avisos de reconciliación o ruptura.

func modify_npc_relationship(other, delta_val: int, reason: String = "", one_way: bool = false) -> void:
	if other == null or other == self or other.is_dead or other.npc_name == "":
		return
	var my_key: String = str(person_profile.person_id) if person_profile != null and str(person_profile.person_id) != "" else (npc_id if npc_id != "" else npc_name)
	var other_key: String = str(other.person_profile.person_id) if other.person_profile != null and str(other.person_profile.person_id) != "" else (other.npc_id if other.npc_id != "" else other.npc_name)
	# V1: solo se inicializa (y migra claves antiguas por nombre) si hace falta; antes recorría el pueblo en cada cambio
	if not npc_relationships.has(other_key) or npc_relationships.has(other.npc_name):
		ensure_npc_relationships_initialized()
	if not other.npc_relationships.has(my_key) or other.npc_relationships.has(npc_name):
		other.ensure_npc_relationships_initialized()
	var old_val: int = get_relationship_with_npc(other_key)
	var new_val: int = clampi(old_val + delta_val, -100, 100)
	npc_relationships[other_key] = new_val
	if one_way:
		if reason != "":
			npc_relationship_notes[other_key] = reason
		return
	other.npc_relationships[my_key] = clampi(other.get_relationship_with_npc(my_key) + delta_val, -100, 100)
	if reason != "":
		npc_relationship_notes[other_key] = reason
		other.npc_relationship_notes[my_key] = reason
	# Giro de "azares del destino": dos rivales/enemigos que pasan a llevarse bien (o amigos que riñen)
	if old_val <= -20 and new_val >= 20:
		var twist_note: String = "🌟 Por azares del destino dejaron atrás su enemistad (%s)" % (reason if reason != "" else "Reconciliación inesperada")
		npc_relationship_notes[other_key] = twist_note
		other.npc_relationship_notes[my_key] = twist_note
		add_thought("Me reconcilié con mi antiguo rival %s (+12)" % other.npc_name, 12.0)
		other.add_thought("Me reconcilié con mi antiguo rival %s (+12)" % npc_name, 12.0)
		_spawn_floating_text("🌟🤝 ¡Por azares del destino, %s y %s dejaron atrás su enemistad!" % [npc_name, other.npc_name], Color.GOLD, -44.0)
		var vm_rec = _get_vm()
		if vm_rec and vm_rec.has_method("record_social_event"):
			vm_rec.call("record_social_event", "reconciliation", self, other, "%s y %s dejaron atrás su enemistad (%s)" % [npc_name, other.npc_name, reason if reason != "" else "Reconciliación"])
	elif old_val >= 30 and new_val <= -20:
		var feud_note: String = "⚡ Antiguos amigos enemistados (%s)" % (reason if reason != "" else "Disputa grave")
		npc_relationship_notes[other_key] = feud_note
		other.npc_relationship_notes[my_key] = feud_note
		add_thought("Ruptura de amistad con %s (-10)" % other.npc_name, -10.0)
		_spawn_floating_text("💢⚡ ¡%s y %s rompieron su amistad tras una fuerte disputa!" % [npc_name, other.npc_name], Color.ORANGE_RED, -44.0)
		var vm_feud = _get_vm()
		if vm_feud and vm_feud.has_method("record_social_event"):
			vm_feud.call("record_social_event", "feud", self, other, "%s y %s rompieron su amistad (%s)" % [npc_name, other.npc_name, reason if reason != "" else "Disputa grave"])

func add_thought(thought_text: String, mood_delta: float) -> void:
	if thoughts.has(thought_text):
		thoughts.erase(thought_text)
	thoughts.push_front(thought_text)
	while thoughts.size() > 3:
		thoughts.pop_back()
	mood = clampf(mood + mood_delta, 0.0, 100.0)

func _show_status_label(txt: String, col: Color) -> void:
	if status_label:
		var vm_sl = _get_vm()
		if vm_sl != null and int(vm_sl.player_elevation_level) != int(elevation_level):
			status_label.visible = false
			return
		status_label.text = txt.replace("Comisario Vane", "Alguacil mayor Vane").replace("Don Vittorio Corvo", "Don Vittorio")
		status_label.add_theme_color_override("font_color", col)
		status_label.scale = Vector2(0.74, 0.74)
		status_label.visible = true
		status_label.reset_size()
		status_label.position = Vector2(-(status_label.size.x * 0.74) * 0.5, -30.0)

func _refresh_unfocused_tag() -> void:
	if _craft_bar_root != null:
		_craft_bar_root.visible = false
	if not status_label:
		return
	var pl := _get_player()
	var near_pl: bool = pl != null and global_position.distance_squared_to(pl.global_position) <= 85.0 * 85.0
	if not near_pl:
		status_label.visible = false
		return
	if is_dead:
		_show_status_label("☠", Color(0.95, 0.91, 0.83))
	elif is_downed:
		_show_status_label("🩸", Color(0.96, 0.55, 0.52))
	elif sedated_timer > 0.0:
		_show_status_label("💤", Color(0.84, 0.78, 0.96))
	elif is_stunned_flag:
		_show_status_label("💫", Color(0.82, 0.88, 0.96))
	elif is_sleeping:
		_show_status_label("💤", Color(0.82, 0.88, 0.96))
	elif is_instance_valid(_active_floating_text):
		_show_status_label("💬", Color(0.95, 0.91, 0.83))
	else:
		status_label.visible = false

func _is_focused_npc() -> bool:
	var f: int = Engine.get_process_frames()
	if _focused_npc_frame != f:
		_focused_npc_frame = f
		var prev_focused: Node = _focused_npc
		_focused_npc = null
		var pl := _get_player()
		var vm_f = _get_vm()
		if pl != null and is_instance_valid(pl):
			var isel = pl.get("interaction_selector")
			if isel != null and is_instance_valid(isel) and isel.has_method("selected"):
				var sel: Dictionary = isel.call("selected")
				if not sel.is_empty() and sel.get("target") is VillageNPCBase and is_instance_valid(sel.get("target")):
					_focused_npc = sel.get("target")
			if _focused_npc == null and is_instance_valid(_hover_owner) and (_hover_owner as Node2D).global_position.distance_to(get_global_mouse_position()) <= 24.0:
				_focused_npc = _hover_owner
			if _focused_npc == null:
				var best_d2: float = 42.0 * 42.0
				for n in get_tree().get_nodes_in_group("village_npcs"):
					if n is VillageNPCBase and is_instance_valid(n) and (n as Node2D).visible and not bool(n.get("corpse_buried")):
						if vm_f != null and int(vm_f.player_elevation_level) != int((n).elevation_level):
							continue
						var d2: float = (n as Node2D).global_position.distance_squared_to(pl.global_position)
						if d2 < best_d2:
							if vm_f == null or not vm_f.has_method("has_line_of_sight") or bool(vm_f.call("has_line_of_sight", pl.global_position, (n as Node2D).global_position)):
								best_d2 = d2
								_focused_npc = n
		if prev_focused != null and prev_focused != _focused_npc and is_instance_valid(prev_focused) and prev_focused is VillageNPCBase:
			(prev_focused)._refresh_unfocused_tag()
	return _focused_npc == self

func is_female() -> bool:
	var clean_name: String = npc_name.split(" ")[0]
	return (person_profile != null and str(person_profile.gender) == "F") or (person_profile == null and (clean_name.ends_with("a") or clean_name in ["Eloise", "Inés", "Carmen", "Beatriz", "Dolores", "Mercedes", "Pilar", "Rocío", "Luz", "Sol", "Iris", "Astrid", "Maren", "Freya", "Ingrid"]))

static func feminize_role_title(title: String, fem: bool) -> String:
	if not fem or title.is_empty():
		return title
	var out: String = title
	var pairs: Array = [
		["Maestro Herrero y Armero", "Maestra Herrera y Armera"],
		["Maestro Carnicero", "Maestra Carnicera"],
		["Maestro Carpintero", "Maestra Carpintera"],
		["Pescador y Molinero", "Pescadora y Molinera"],
		["Médico Cirujano", "Médica Cirujana"],
		["Posadero", "Posadera"],
		["Tabernero", "Tabernera"],
		["Camarero", "Camarera"],
		["Panadero", "Panadera"],
		["Sastre", "Sastra"],
		["Granjero", "Granjera"],
		["Ganadero", "Ganadera"],
		["Cantero", "Cantera"],
		["Leñador", "Leñadora"],
		["Arreglador", "Arregladora"],
		["Herrero", "Herrera"],
		["Armero", "Armera"],
		["Carnicero", "Carnicera"],
		["Carpintero", "Carpintera"],
		["Pescador", "Pescadora"],
		["Molinero", "Molinera"],
		["Cocinero", "Cocinera"],
		["Jardinero", "Jardinera"],
		["Médico", "Médica"],
		["Cirujano", "Cirujana"],
		["Comisario", "Comisaria"],
		["Sacerdote", "Sacerdotisa"],
		["Artesano", "Artesana"],
		["Encargado", "Encargada"],
		["Forastero", "Forastera"],
		["Jornalero", "Jornalera"],
		["Viajero", "Viajera"],
		["Vecino", "Vecina"],
		["Recién Llegado", "Recién Llegada"],
		["Contratado", "Contratada"],
		["Sucesor", "Sucesora"],
		["Relegado", "Relegada"],
		["Señor del Valle", "Señora del Valle"],
	]
	for p in pairs:
		if out.find(str(p[0])) != -1:
			out = out.replace(str(p[0]), str(p[1]))
	return out

func set_poker_seating(active: bool, seat_world_pos: Vector2 = Vector2.ZERO) -> void:
	_stop_crafting_bar()
	if active:
		if not is_at_poker_table:
			_pre_poker_pos = global_position
		is_at_poker_table = true
		poker_seat_pos = seat_world_pos
		is_sleeping = false
		velocity = Vector2.ZERO
		if seat_world_pos != Vector2.ZERO:
			global_position = seat_world_pos
		if sprite:
			sprite.rotation_degrees = 0.0
		add_thought("Jugando en la mesa del casino (+10)", 10.0)
	else:
		if is_at_poker_table and _pre_poker_pos != Vector2.ZERO and not is_dead:
			global_position = _pre_poker_pos
		is_at_poker_table = false
		poker_seat_pos = Vector2.ZERO
		_pre_poker_pos = Vector2.ZERO
		velocity = Vector2.ZERO

func apply_sleeping_draught(duration: float = 40.0) -> void:
	if is_dead or is_downed:
		return
	_clear_unconscious_reaction_state()
	_stop_crafting_bar()
	sedated_timer = maxf(sedated_timer, duration)
	is_sleeping = true
	_unconscious_ignored_by.clear()
	_unconscious_helper_npc = null
	_clear_combat_hostility()
	_set_sprite_pose(90.0, Color(0.68, 0.58, 1.0, 0.95))
	add_thought("Sedado por un somnífero (-6)", -6.0)

func is_unconscious_on_ground() -> bool:
	return not is_dead and not is_downed and (sedated_timer > 0.0 or is_stunned_flag)

func wake_up_from_unconscious(rescuer = null) -> void:
	sedated_timer = 0.0
	is_stunned_flag = false
	is_sleeping = false
	_unconscious_helper_npc = null
	_unconscious_ignored_by.clear()
	_set_sprite_pose(0.0, Color.WHITE)
	if is_instance_valid(rescuer):
		add_thought("Despertado y auxiliado por %s (+6)" % rescuer.npc_name, 6.0)

## Comprueba si algún tercer vecino consciente o el Jugador está mirando al oportunista o a la víctima inconsciente (con línea de visión)

func _clear_unconscious_reaction_state() -> void:
	if is_instance_valid(_reacting_unconscious_target) and _reacting_unconscious_target._unconscious_helper_npc == self:
		_reacting_unconscious_target._unconscious_helper_npc = null
	_reacting_unconscious_target = null
	_unconscious_react_mode = ""
	_unconscious_react_phase = 0
	_unconscious_react_timer = 0.0
	_stop_crafting_bar()

func _lod_far() -> bool:
	if not lod_enabled or is_hostile or is_in_live_fight() or is_busy_with_player():
		return false
	if trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.DOCTOR, TradeRole.ROYAL_INVESTIGATOR]:
		return false # Patrullas, urgencias e investigaciones: siempre al detalle
	if is_instance_valid(_cached_vm) and "player_elevation_level" in _cached_vm and int(_cached_vm.player_elevation_level) != elevation_level:
		return true # Bloque PQ: En otro piso o en el subsuelo respecto al jugador se simula en modo simplificado
	var pl: Node2D = _get_player()
	return pl != null and global_position.distance_squared_to(pl.global_position) > LOD_DIST_MEDIO * LOD_DIST_MEDIO

func _lod_step_for_npc() -> int:
	if is_instance_valid(_cached_vm) and "player_elevation_level" in _cached_vm and int(_cached_vm.player_elevation_level) != elevation_level:
		return LOD_STEP * 2
	var pl: Node2D = _get_player()
	var d2: float = global_position.distance_squared_to(pl.global_position) if pl != null else INF
	if d2 > (LOD_DIST * 2.0) * (LOD_DIST * 2.0):
		return LOD_STEP * 2
	if d2 > LOD_DIST * LOD_DIST:
		return LOD_STEP
	return 2 # franja intermedia (LOD_DIST_MEDIO..LOD_DIST): 1 de cada 2 pasos

static func _perf_add(part: String, since: int) -> int:
	var now: int = Time.get_ticks_usec()
	perf_usec[part] = int(perf_usec.get(part, 0)) + (now - since)
	return now

func _is_morning_expedition_hours() -> bool:
	if not (trade_role in [TradeRole.BLACKSMITH, TradeRole.CARPENTER, TradeRole.HERBALIST, TradeRole.FISHMONGER, TradeRole.BUTCHER]) or not WorldClock or _completed_expedition_day == WorldClock.current_day:
		return false
	if trade_role == TradeRole.BUTCHER and GameManager != null and GameManager.has_method("is_demo_mode") and GameManager.is_demo_mode():
		return false
	var h: int = WorldClock.current_hour
	var m: int = WorldClock.current_minute
	return (h == 6 and m >= 30) or h == 7 or h == 8 or (h == 9 and m < 30)

func _get_expedition_target_pos() -> Vector2:
	return EXPEDITION_TARGETS.get(trade_role, work_position)

func _get_expedition_description() -> String:
	return str(EXPEDITION_DESCS.get(trade_role, "🚶 En Expedición"))

func _is_mandatory_work_hours() -> bool:
	if (trade_role == TradeRole.UNEMPLOYED and not has_meta("day_job")) or rite_pos != Vector2.ZERO or sick_level >= 2 or errand_kind in NIGHT_ERRANDS:
		return false # V5d: el jornalero con jornal sí tiene horario de trabajo (8–18)
	if errand_kind == "leisure":
		var lp_w: String = str(get_meta("leisure_place", ""))
		if lp_w == "tavern_poker" or (lp_w in ["tavern_hall", "restaurant_terrace", "restaurant_hall"] and WorldClock != null and int(WorldClock.current_hour) >= 12):
			return false
	if not WorldClock or _is_morning_expedition_hours():
		return true
	var h: int = WorldClock.current_hour
	if trade_role == TradeRole.RESTAURATEUR: # R1b: la trattoria prepara desde las 8 h, abre a mediodía y sirve cenas, también el fin de semana
		return h >= 8 and h < _VillageRestaurant.OPEN_TO and not WorldClock.is_rite_day()
	# G2: fin de semana. Los oficios y sus familias trabajan solo la mañana del sábado y descansan el domingo
	if WorldClock.has_method("is_weekend") and WorldClock.is_weekend() and (trade_role in SHOP_ROLES or trade_role == TradeRole.FAMILY_MEMBER):
		if WorldClock.is_rite_day():
			return false
		return h >= 9 and h < 13
	if trade_role == TradeRole.INNKEEPER:
		return h >= 8 and h < 23
	if trade_role == TradeRole.WAITER:
		return h >= 10 and h < 23
	if trade_role in [TradeRole.FISHMONGER, TradeRole.BUTCHER, TradeRole.HERBALIST]:
		return h >= 8 and h < 20
	if trade_role == TradeRole.BAKER:
		return h >= 6 and h < 16 # El horno madruga
	if trade_role in [TradeRole.CHILD, TradeRole.TEACHER]: # V9: escuela de 9 a 14 h entre semana (los niños, si están apuntados)
		if trade_role == TradeRole.CHILD and not has_meta("school_pos"):
			return false
		return h >= 9 and h < 14 and not (WorldClock.has_method("is_weekend") and WorldClock.is_weekend())
	if trade_role == TradeRole.NOBLE: # V6: de 10 a 13 h entre semana administran sus tierras en casa
		return h >= 10 and h < 13 and not (WorldClock.has_method("is_weekend") and WorldClock.is_weekend())
	return h >= 8 and h < 18

## Multiplicador continuo de velocidad por Nutrición estilo Kenshi (300 pts = 100% -> 3 días completos hasta 0%)

func get_nutrition_speed_multiplier() -> float:
	if need_hunger >= 66.67:
		return 1.0
	if need_hunger >= 33.33:
		return lerpf(0.68, 1.0, (need_hunger - 33.33) / 33.34)
	return lerpf(0.42, 0.68, clampf(need_hunger / 33.33, 0.0, 1.0))

## Multiplicador continuo de habilidad profesional y combate por Nutrición estilo Kenshi

func get_nutrition_skill_multiplier() -> float:
	if need_hunger >= 66.67:
		return 1.0
	if need_hunger >= 33.33:
		return lerpf(0.55, 1.0, (need_hunger - 33.33) / 33.34)
	return lerpf(0.20, 0.55, clampf(need_hunger / 33.33, 0.0, 1.0))

## Estado nutricional estilo Kenshi (con indicador de digestión/recuperación progresiva `↗Digeriendo`)

func get_nutrition_status_label() -> String:
	var dig_str: String = (" ↗Digeriendo" if digestion_buffer > 1.0 else "")
	var spd_pen: int = int(round((1.0 - get_nutrition_speed_multiplier()) * 100.0))
	var skl_pen: int = int(round((1.0 - get_nutrition_skill_multiplier()) * 100.0))
	if need_hunger <= 0.0 and digestion_buffer <= 0.0:
		return "💀Inanición Letal (+3d sin comer | -%d%%Vel -%d%%Oficio)" % [spd_pen, skl_pen]
	if need_hunger < 33.33:
		return "🔴Famélico Día 3 (-%d%%Vel -%d%%Oficio)%s" % [spd_pen, skl_pen, dig_str]
	if need_hunger < 66.67:
		return "🟠Desnutrido Día 2 (-%d%%Vel -%d%%Oficio)%s" % [spd_pen, skl_pen, dig_str]
	return ("🟡Hambriento%s" if need_hunger < 80.0 else "🟢Bien alimentado%s") % dig_str

## Multiplicador continuo de velocidad por Privación de Sueño (`need_energy`)

func get_sleep_speed_multiplier() -> float:
	if need_energy >= 50.0:
		return 1.0
	if need_energy >= 30.0:
		return lerpf(0.85, 1.0, (need_energy - 30.0) / 20.0)
	if need_energy >= 10.0:
		return lerpf(0.68, 0.85, (need_energy - 10.0) / 20.0)
	return lerpf(0.52, 0.68, clampf(need_energy / 10.0, 0.0, 1.0))

## Multiplicador continuo de habilidad profesional y combate por Privación de Sueño (`need_energy`)

func get_sleep_skill_multiplier() -> float:
	if need_energy >= 50.0:
		return 1.0
	if need_energy >= 30.0:
		return lerpf(0.82, 1.0, (need_energy - 30.0) / 20.0)
	return lerpf(0.55, 0.82, clampf(need_energy / 30.0, 0.0, 1.0))

## Multiplicador de rango de visión por Privación de Sueño (`need_energy`)

func get_sleep_vision_multiplier() -> float:
	return 1.0 if need_energy >= 50.0 else (0.80 if need_energy >= 30.0 else (0.60 if need_energy >= 10.0 else 0.45))

func get_sleep_status_label() -> String:
	var camp_tag: String = " ⛺Intemperie" if is_vagrant_camper else ""
	if need_energy < 10.0:
		return "🔴Insomnio Extremo (-45%%Vel -55%%Vis)%s" % camp_tag
	if need_energy < 30.0:
		return "🟠Privación Sueño (-28%%Vel -35%%Oficio)%s" % camp_tag
	return ("🟡Somnoliento (-12%%Vel)%s" if need_energy < 50.0 else "🟢Descansado%s") % camp_tag

## Devuelve la eficiencia laboral actual del NPC combinando su experiencia (`days_in_role`) con su estado nutricional estilo Kenshi, sueño y capacidad de brazos (`manipulation`)

func get_job_efficiency() -> float:
	var arm_mult: float = health_comp.get_manipulation_capacity() if health_comp else 1.0
	var mult: float = get_nutrition_skill_multiplier() * get_sleep_skill_multiplier() * arm_mult
	if trade_role in [TradeRole.UNEMPLOYED, TradeRole.FAMILY_MEMBER]:
		return clampf(mult, 0.15, 1.0)
	var base_exp: float = clampf(0.35 + (float(days_in_role) / 7.0) * 0.65, 0.35, 1.0)
	return clampf(base_exp * mult * get_diligence_mult(), 0.12, 1.15)

## T4: el trabajador rinde más en su oficio y el holgazán menos (Trabajador: +15 %).

func get_diligence_mult() -> float:
	return clampf(1.0 + 0.15 * TraitCatalog.npc_tendency(self, "diligence"), 0.75, 1.15)

## T4: el sociable vuelve a charlar antes y el frío tarda más (Alegre: ×0,82; Frío: ×1,18).

func get_social_cooldown_mult() -> float:
	return clampf(1.0 - 0.3 * TraitCatalog.npc_tendency(self, "sociability"), 0.6, 1.5)

## Etiqueta descriptiva del nivel de dominio del oficio, curva de aprendizaje de 7 días y penalización por desnutrición/sueño

func get_job_efficiency_label() -> String:
	if trade_role in [TradeRole.UNEMPLOYED, TradeRole.FAMILY_MEMBER]:
		return "Vecino"
	var pct: int = int(round(get_job_efficiency() * 100.0))
	var mal_tag: String = (" ⚠️Desnutrido" if need_hunger < 60.0 else "") + (" 💤Exhausto" if need_energy < 35.0 else "")
	if days_in_role >= 7:
		return "Maestro (%d%%%s)" % [pct, mal_tag]
	var rank_name: String = "Oficial" if days_in_role >= 4 else ("Aprendiz" if days_in_role >= 2 else "Novato")
	return "%s (%d%% · Día %d/7%s)" % [rank_name, pct, days_in_role, mal_tag]

## Verifica si este NPC (dependiente/artesano) está vivo, consciente y físicamente atendiendo su mostrador/taller

func is_at_shop_counter() -> bool:
	if is_incapacitated() or is_sleeping or is_hostile or is_at_poker_table:
		return false
	if trade_role == TradeRole.TRAVELING_MERCHANT:
		return not _merchant_leaving
	if current_activity != ActivityState.WORKING or (_is_morning_expedition_hours() and global_position.distance_to(work_position) > 46.0):
		return false
	return global_position.distance_to(work_position) <= 48.0

## Alimenta al NPC añadiendo nutrientes al estómago (`digestion_buffer`) para que se recupere gradualmente al estilo Kenshi

func feed_npc_gradual(nutrition_amount: float = 38.0) -> void:
	digestion_buffer = clampf(digestion_buffer + nutrition_amount, 0.0, maxf(18.0, maxf(0.0, 100.0 - need_hunger)))
	_starvation_tick_timer = 0.0

## Prioridad "Casa Primero": comer en casa es la opción principal; la Taberna es capricho o para viajeros con oro
## R1b: dónde come ahora: la silla de la trattoria, la taberna o la mesa de casa.

func _current_meal_pos() -> Vector2:
	if _restaurant_seat != Vector2.ZERO:
		return _restaurant_seat
	var h_ang: float = float(absi(npc_name.hash()) % 360) * (TAU / 360.0)
	if _eat_at_tavern:
		if _tavern_seat != Vector2.ZERO and _tavern_seat != tavern_social_pos:
			return _tavern_seat
		return tavern_social_pos + Vector2.RIGHT.rotated(h_ang) * 9.0
	var cand_home: Vector2 = home_table_pos + Vector2(cos(h_ang) * 14.0, sin(h_ang) * 11.5)
	var vm = _get_vm()
	if vm and vm.has_method("clamp_point_to_building_interior"):
		cand_home = vm.call("clamp_point_to_building_interior", home_table_pos, cand_home)
	return cand_home

func _choose_preferred_meal_location() -> bool:
	var vm = _get_vm()
	_restaurant_seat = _VillageRestaurant.pick_seat_for(vm, self)
	if _restaurant_seat != Vector2.ZERO:
		_tavern_seat = Vector2.ZERO
		return false # R1b: sale a comer a la trattoria
	if vm != null and vm.has_method("is_building_door_blocked") and bool(vm.call("is_building_door_blocked", "tavern")):
		_tavern_seat = Vector2.ZERO
		return false
	var go_tavern: bool = false
	if trade_role in [TradeRole.INNKEEPER, TradeRole.WAITER]:
		go_tavern = true
	elif trade_role == TradeRole.UNEMPLOYED:
		go_tavern = not is_vagrant_camper and personal_gold >= 13
	else:
		go_tavern = personal_gold >= 24 and randf() < (0.55 if personal_gold >= 120 else 0.30) # E3: los ricos y vecinos con ahorros salen a comer a la taberna
	_tavern_seat = _VillageTavern.pick_seat_for(vm, self) if go_tavern else Vector2.ZERO
	return go_tavern

## Actualiza Hambre (escala de 3 días estilo Kenshi + digestión gradual), Energía (16h despierto / 8h de sueño nocturno 22:00-06:00) y Socialización.

func _update_craft_bar_visual(ratio: float, label_txt: String, bar_color: Color) -> void:
	if not _craft_bar_root:
		return
	var pl := _get_player()
	var dist_sq: float = global_position.distance_squared_to(pl.global_position) if pl != null else INF
	if dist_sq > 85.0 * 85.0:
		_craft_bar_root.visible = false
		return
	var focused: bool = _is_focused_npc()
	if not focused:
		_craft_bar_root.visible = false
		return
	var vm_cb = _get_vm()
	if pl != null and vm_cb != null and vm_cb.has_method("has_line_of_sight") and not bool(vm_cb.call("has_line_of_sight", pl.global_position, global_position)):
		_craft_bar_root.visible = false
		return
	_craft_bar_root.visible = true
	_craft_bar_root.scale = Vector2(0.72, 0.72)
	_craft_bar_root.position = Vector2(0.0, -42.0 if (status_label != null and status_label.visible) else -23.0)
	var fill_w: float = 38.0 * clampf(ratio, 0.02, 1.0)
	if _craft_bar_fill:
		_craft_bar_fill.color = bar_color
		_craft_bar_fill.polygon = PackedVector2Array([Vector2(-19.0, -2.0), Vector2(-19.0 + fill_w, -2.0), Vector2(-19.0 + fill_w, 1.0), Vector2(-19.0, 1.0)])
	if _craft_bar_label:
		var has_bubble: bool = is_instance_valid(_active_floating_text)
		if focused and not has_bubble:
			_craft_bar_label.visible = true
			if _craft_bar_label.text != label_txt:
				_craft_bar_label.text = label_txt
		else:
			_craft_bar_label.visible = false

func _sync_shop_stock_to_vm() -> void:
	var vm = _get_vm()
	if vm and "shop_businesses" in vm and vm.shop_businesses.has(int(trade_role)):
		vm.shop_businesses[int(trade_role)]["stock_override"] = shop_stock.duplicate()
	if vm and vm.has_method("_refresh_shop_stall_visual"):
		vm.call("_refresh_shop_stall_visual", int(trade_role))

## Expedición Matutina Física y Sostenible (06:30 - 09:30):
## Los maestros de oficio acuden físicamente a talar un árbol real, picar una veta de hierro real,
## cosechar una planta real o cazar y desollar un animal real, PERO solo si la población supera
## el umbral mínimo de equilibrio ecológico (N_actual > N_min) calculado en `EcosystemManager`.

static func death_cause_for_source(src) -> String:
	if src is WildAnimal:
		match (src as WildAnimal).species:
			WildAnimal.SpeciesType.BOAR: return "Embestida de jabalí"
			WildAnimal.SpeciesType.FOX: return "Mordedura de zorro"
		return "Ataque de animal salvaje"
	return "Herida de asaltante"

## J2: muertes que no son un crimen (hambre, animales, enfermedad): no hace falta investigar.

static func is_natural_death_cause(cause: String) -> bool:
	for t in NATURAL_DEATH_TAGS:
		if t in cause:
			return true
	return false

static func natural_death_text(cause: String) -> String:
	if "jabalí" in cause:
		return "lo mató un jabalí"
	if "zorro" in cause:
		return "lo mató un zorro"
	if "animal" in cause:
		return "lo mató un animal salvaje"
	if "Inanición" in cause:
		return "murió de hambre"
	if "Enfermedad" in cause:
		return "murió de una enfermedad"
	return "murió"

## J1: ¿le está embistiendo este jabalí y ya va herido (salud ≤ 50 %)?

func should_flee_boar(prey) -> bool:
	if not is_instance_valid(prey) or not (prey is WildAnimal) or prey.species != WildAnimal.SpeciesType.BOAR:
		return false
	if prey.state != WildAnimal.AnimalState.CHARGE_ATTACK or prey.boar_aggressor != self or health_comp == null:
		return false
	return health_comp.current_health <= health_comp.max_health * 0.5

## J1: abandona la caza del día; el jabalí pierde el interés en quien huye (2 s más de furia como mucho).

func flee_from_boar(prey) -> void:
	var cur_day: int = WorldClock.current_day if WorldClock else 1
	_completed_expedition_day = cur_day
	_expedition_target_node = null
	_amateur_prey_target = null
	_is_amateur_foraging = false
	prey.boar_aggro_timer = minf(prey.boar_aggro_timer, 2.0)
	add_thought("Un jabalí casi me mata; hoy no cazo más (-8)", -8.0)
	_spawn_floating_text("🐗🏃 ¡Retirada! El jabalí es demasiado peligroso", Color.ORANGE, -38.0)

func get_person_key() -> String:
	if person_profile != null and str(person_profile.person_id) != "":
		return str(person_profile.person_id)
	return npc_id if npc_id != "" else npc_name

## B2.2: Asigna una quedada (llamado por el VillageManager). El vecino pasa a socializar y camina al punto de encuentro.

func assign_hangout(h_id: int, spot_pos: Vector2, partner, side: int, spot_label: String = "") -> void:
	_clear_unconscious_reaction_state()
	hangout_id = h_id
	hangout_spot_pos = spot_pos
	hangout_side = side
	hangout_spot_label = spot_label
	_social_partner = partner
	_noise_react_timer = 0.0
	errand_kind = ""
	errand_pos = Vector2.ZERO
	is_sleeping = false
	current_activity = ActivityState.SOCIALIZING
	_decision_timer = randf_range(2.0, 3.0)

func clear_hangout() -> void:
	hangout_id = -1
	hangout_spot_pos = Vector2.ZERO
	hangout_side = 0
	hangout_spot_label = ""

## G2: el vecino deja lo que hace y camina a la capilla para el Oficio del Alba (lo llama VillageFaith).

func join_rite(spot: Vector2, kind: String = "rite") -> void:
	rite_pos = spot
	rite_kind = kind
	_noise_react_timer = 0.0
	is_sleeping = false
	_social_partner = null
	current_activity = ActivityState.SOCIALIZING
	_decision_timer = randf_range(1.0, 2.0)

func leave_rite() -> void:
	rite_pos = Vector2.ZERO
	rite_kind = ""

## E: encargo corto a pie (lo decide VillageNeeds; lo termina al llegar).

func start_errand(kind: String, spot: Vector2) -> void:
	errand_kind = kind
	errand_pos = spot
	errand_since = (int(WorldClock.current_day) * 24 + int(WorldClock.current_hour)) if WorldClock else 0
	_noise_react_timer = 0.0
	is_sleeping = false
	_social_partner = null
	current_activity = ActivityState.SOCIALIZING
	_decision_timer = randf_range(1.0, 2.0)

func end_errand() -> void:
	errand_kind = ""
	errand_pos = Vector2.ZERO
	for m in ["leisure_since", "leisure_place", "leisure_until_hour"]:
		if has_meta(m):
			remove_meta(m)

## B4.2: Escena discreta de pelea. `VillageManager` decide inicio, fin y consecuencias; aquí solo se representa.

func is_in_live_fight() -> bool:
	return is_instance_valid(live_fight_partner)

func is_busy_with_player() -> bool:
	return _being_interviewed_timer > 0.0 or (is_instance_valid(_cached_dm) and bool(_cached_dm.get("active")) and _cached_dm.get("current_speaker") == self)

func is_busy_with_emergency() -> bool:
	return is_instance_valid(_reporting_corpse_target) or is_instance_valid(_searching_missing_kin) or is_instance_valid(_reacting_unconscious_target) or is_instance_valid(_carrying_corpse_target)

func begin_live_fight(partner) -> void:
	live_fight_partner = partner
	TraitDiscovery.on_witnessed_behavior(self, "aggression", "le has visto pelear")
	_live_fight_clock = 0.0
	velocity = Vector2.ZERO
	_stop_crafting_bar()

func end_live_fight() -> void:
	live_fight_partner = null
	if sprite:
		sprite.offset = Vector2.ZERO

func is_disarmed() -> bool:
	return Time.get_ticks_msec() < disarmed_until_msec

func disarm(seconds: float = 20.0) -> bool:
	if not (trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.ROYAL_INVESTIGATOR]) or is_disarmed():
		return false
	disarmed_until_msec = Time.get_ticks_msec() + int(seconds * 1000.0)
	_police_baton_windup_timer = 0.0
	police_reload_step = 0
	police_reload_timer = 0.0
	_spawn_floating_text("🫳 ¡Se le cae el arma!", Color(1.0, 0.75, 0.35), -44.0)
	return true

func apply_parry_stagger(duration: float = 0.8, quiet: bool = false) -> void:
	_stagger_timer = maxf(_stagger_timer, duration)
	_melee_windup_timer = 0.0
	_police_baton_windup_timer = 0.0
	if police_reload_step > 0:
		police_reload_step = 0
		police_reload_timer = 0.0
		_spawn_floating_text("💥 ¡Recarga interrumpida!", Color(1.0, 0.65, 0.35), -42.0)
	_attack_timer = maxf(_attack_timer, duration)
	velocity = Vector2.ZERO
	if quiet:
		return # C7: tambaleo corto de un golpe normal, sin letrero ni tinte
	if sprite:
		sprite.modulate = Color(0.75, 0.92, 1.35)
	_spawn_floating_text("💫 ¡Desequilibrado!", Color.AQUA, -36.0)

func trigger_action_animation(duration: float = 2.8) -> void:
	_anim_action_timer = maxf(_anim_action_timer, duration)

func show_prompt() -> void:
	_showing_stealth_prompt = true
	_show_status_label("%s · Desprevenido" % npc_name, Color(0.95, 0.91, 0.83))

func hide_prompt() -> void:
	_showing_stealth_prompt = false
	if status_label:
		status_label.visible = false

func _make_armor_menu(title: String, menu_key: String, items: Array) -> Dictionary:
	return NPCDialogue._make_armor_menu(self, title, menu_key, items)

func _build_blacksmith_dialogue(needs_line: String) -> Dictionary:
	return NPCDialogue._build_blacksmith_dialogue(self, needs_line)

func _build_dialogue() -> Dictionary:
	return NPCDialogue._build_dialogue(self)

func on_dialogue_action(action_id: String) -> void:
	NPCDialogue.on_dialogue_action(self, action_id)

func _spawn_floating_text(text: String, color: Color, offset_y: float = -36.0, duration: float = 1.0) -> void:
	if FloatingTextScene and is_inside_tree():
		var pl := _get_player()
		if pl != null and global_position.distance_squared_to(pl.global_position) > 190.0 * 190.0:
			return
		var parent_scene: Node = get_tree().current_scene if get_tree().current_scene else get_parent()
		if parent_scene:
			if is_instance_valid(_active_floating_text):
				_active_floating_text.queue_free()
				_active_floating_text = null
			var adj_y: float = offset_y
			if _craft_bar_root != null and _craft_bar_root.visible:
				if _craft_bar_label != null:
					_craft_bar_label.visible = false
				adj_y = minf(adj_y, -48.0)
			var nearby_bubbles: int = 0
			for n in get_tree().get_nodes_in_group("village_npcs"):
				if n is VillageNPCBase and n != self and is_instance_valid((n)._active_floating_text):
					if (n as Node2D).global_position.distance_squared_to(global_position) <= 84.0 * 84.0:
						nearby_bubbles += 1
			if nearby_bubbles >= 1 and not _is_focused_npc():
				return
			if nearby_bubbles >= 1:
				adj_y -= 16.0
			var ft = FloatingTextScene.instantiate()
			ft.start_text = text
			ft.text_color = color
			ft.duration = duration
			ft.global_position = global_position + Vector2(0, adj_y)
			parent_scene.add_child(ft)
			_active_floating_text = ft

## B5.3: Bocadillo corto sobre la cabeza (1.5 s) que no para nada ni pausa el juego.

func spawn_short_bubble(text: String, color: Color = Color(1.0, 0.96, 0.78), offset_y: float = -40.0, duration: float = 1.5) -> void:
	last_short_bubble_text = text
	last_short_bubble_duration = duration
	_spawn_floating_text(text, color, offset_y, duration)

func _read_vec2(data: Dictionary, kx: String, ky: String, fallback: Vector2) -> Vector2:
	return Vector2(float(data[kx]), float(data[ky])) if (data.has(kx) and data.has(ky)) else fallback
