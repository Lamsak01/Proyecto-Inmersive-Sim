@tool
extends CharacterBody2D
class_name VillageNPC
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
	TEACHER             # 24. Maestro de la escuela (V9): llega cuando hay niños en edad de ir
}

## Oficios con taller y mostrador propios (V5: lista común para no repetirla en cada sitio)
const SHOP_ROLES: Array = [TradeRole.BLACKSMITH, TradeRole.BUTCHER, TradeRole.CARPENTER, TradeRole.HERBALIST, TradeRole.FISHMONGER, TradeRole.BAKER, TradeRole.TAILOR, TradeRole.LODGEKEEPER, TradeRole.FARMER, TradeRole.RANCHER, TradeRole.QUARRYMAN, TradeRole.WOODCUTTER, TradeRole.TINKER]

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
var tavern_social_pos: Vector2 = Vector2(395, -135)
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
var _meal_consumed_this_sitting: bool = false
var _has_valid_meal_this_sitting: bool = false
var _sitting_meal_ingested: float = 0.0
var _starvation_tick_timer: float = 0.0
var _social_partner: VillageNPC = null
var _decision_timer: float = 0.0
# B2.2: Quedada activa organizada por el SocialDirector (-1 = ninguna). El VillageManager la asigna y la limpia.
var hangout_id: int = -1
## G2: sitio en la capilla durante el Oficio del Alba (ZERO = no va al Oficio)
var rite_pos: Vector2 = Vector2.ZERO
var rite_kind: String = "" # "rite" (Oficio del Alba), "sect" (reunión de la secta), "sect_lure" (víctima engañada)
## E1/E3/E5: encargos cortos a pie (lavarse «wash», beber «drink», jugar «gamble», pedir limosna «beg»); ver VillageNeeds
var errand_kind: String = ""
## Recados que se hacen de noche: no se cancelan al caer la noche (P5b: el perista en el callejón).
const NIGHT_ERRANDS: Array[String] = ["fence_alley", "smuggler_bust", "gathering", "catering", "club_go", "club_watch", "night_job"]
var errand_pos: Vector2 = Vector2.ZERO
var errand_since: int = 0
## E1: higiene (100 limpio → 0 sucio). E2: 0 sano, 1 enfermo leve, 2 guarda cama (lo pone VillageIllness)
var need_hygiene: float = 80.0
var sick_level: int = 0
var live_fight_partner: VillageNPC = null
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
var corpse_reporter_npc: VillageNPC = null
var corpse_being_carried: bool = false
var corpse_in_morgue: bool = false
var corpse_buried: bool = false
var corpse_carrier: VillageNPC = null
var corpse_rot_hours: float = 0.0
var death_world_pos: Vector2 = Vector2.ZERO
var death_day: int = -1
var death_hour: int = -1
var death_minute: int = -1
var murder_witness_name: String = ""
var _carrying_corpse_target: VillageNPC = null
var _reporting_corpse_target: VillageNPC = null
var _corpse_report_phase: int = 0
var _corpse_report_timer: float = 0.0
var witness_silenced_player: bool = false
var witness_alibi_for_player: bool = false
var witness_framed_target_name: String = ""
var _interrog_correct_steps: int = 0
var _interrog_penalty_acc: int = 0
var _active_downed_patient: VillageNPC = null

# Relaciones Dinámicas entre Vecinos (-100 a +100, estilo RimWorld) y Búsqueda de Familiares Ausentes
var npc_relationships: Dictionary = {} # other_npc_name -> int (-100..100)
var npc_relationship_notes: Dictionary = {} # other_npc_name -> String (motivo actual / historia común)
var _npc_social_event_cooldown: float = 0.0
var _pending_social_reply_timer: float = 0.0
var _pending_social_reply_data: Dictionary = {}
var last_social_line_spoken: String = ""
var _searching_missing_kin: VillageNPC = null
var _missing_kin_phase: int = 0
var _missing_kin_timer: float = 0.0
var _missing_kin_reported_day: int = -1
var _kin_absence_worry_timer: float = 0.0
var _patrol_search_target_npc: VillageNPC = null
var _patrol_search_target_pos: Vector2 = Vector2.ZERO
var _patrol_search_timer: float = 0.0
var _reacting_unconscious_target: VillageNPC = null
var _unconscious_react_mode: String = "" # "opportunist_steal", "friend_rescue", "neutral_wake"
var _unconscious_react_phase: int = 0
var _unconscious_react_timer: float = 0.0
var _unconscious_helper_npc: VillageNPC = null
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

# Estado Policial y Sigilo (Negociación -> Persecución + Derribo No Letal / Asesinato Letal por la Espalda)
var _police_alerted_timer: float = 0.0
var _civilian_hostile_timer: float = 0.0
var _melee_windup_timer: float = 0.0
var _police_baton_windup_timer: float = 0.0
var disarmed_until_msec: int = 0 ## C7 fase 4c: sin porra ni pistola hasta entonces (le diste fuerte en el brazo)
var _melee_recover_timer: float = 0.0 ## C7 fase 2: quieto tras soltar un golpe (más si falló): ventana para castigarle
var _stagger_timer: float = 0.0
var _last_seen_player_pos: Vector2 = Vector2.ZERO
var _stuck_timer: float = 0.0
var _last_frame_pos: Vector2 = Vector2.ZERO
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
	TradeRole.FARMER: Vector2i(55, 80), TradeRole.RANCHER: Vector2i(55, 80), TradeRole.QUARRYMAN: Vector2i(45, 70), TradeRole.WOODCUTTER: Vector2i(40, 62), TradeRole.TINKER: Vector2i(45, 70), TradeRole.NOBLE: Vector2i(200, 300), TradeRole.CHILD: Vector2i(0, 0), TradeRole.TEACHER: Vector2i(30, 50),
	TradeRole.DOCTOR: Vector2i(52, 78), TradeRole.SHERIFF: Vector2i(52, 78), TradeRole.GUARD: Vector2i(52, 78),
	TradeRole.FAMILY_MEMBER: Vector2i(26, 44), TradeRole.TRAVELING_MERCHANT: Vector2i(172, 238), TradeRole.ROYAL_INVESTIGATOR: Vector2i(110, 155),
}

const ROLE_INITIAL_MATERIALS: Dictionary = {
	TradeRole.BLACKSMITH: {"wood": 1, "leather": 1}, TradeRole.CARPENTER: {"iron_ore": 1, "herbal_poultice": 1},
	TradeRole.BUTCHER: {"wood": 1, "herbal_poultice": 1}, TradeRole.HERBALIST: {"bread": 1, "fertilizer": 1},
	TradeRole.FISHMONGER: {"wood": 1, "herbal_poultice": 1}, TradeRole.INNKEEPER: {"cooked_meat": 1, "bread": 1},
	TradeRole.DOCTOR: {"herbal_poultice": 2, "leather": 1},
	TradeRole.BAKER: {"bread": 1, "wood": 1}, TradeRole.TAILOR: {"leather": 2}, TradeRole.LODGEKEEPER: {"cooked_meat": 1},
	TradeRole.FARMER: {"fertilizer": 1}, TradeRole.RANCHER: {"wheat": 1}, TradeRole.QUARRYMAN: {"repair_kit": 1}, TradeRole.WOODCUTTER: {"repair_kit": 1}, TradeRole.TINKER: {"iron_ore": 1},
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
	TradeRole.TAILOR: [["Perfeccionista", "Coqueto"], "clothes", ["Una costura perfecta (+6)"]],
	TradeRole.DOCTOR: [["Cirujano Experto", "Forense Meticuloso"], "surgical_kit", ["Urgencias y morgue en orden (+8)"]],
	TradeRole.SHERIFF: [["Justiciero", "Observador"], "cooked_meat", ["Vigilando la ley en el valle (+7)"]],
	TradeRole.GUARD: [["Leal", "Alerta"], "bread", ["Patrulla sin novedad (+6)"]],
	TradeRole.TRAVELING_MERCHANT: [["Mercader Real", "Portador de Salvoconducto"], "royal_ration", ["Comerciando entre el valle y las Tierras Reales (+10)"]],
	TradeRole.ROYAL_INVESTIGATOR: [["Inquisidor Implacable", "Deducción Forense", "Nunca Vuelve Vacío"], "royal_ration", ["La Corona exige un culpable (+12)"]],
}

const NPCData = preload("res://scripts/data/NPCData.gd")
const PersonProfile = preload("res://scripts/data/PersonProfile.gd")
const NPCDialogue = preload("res://scripts/enemies/NPCDialogue.gd")
const TraitDiscovery = preload("res://scripts/systems/TraitDiscovery.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageFaith = preload("res://scripts/systems/VillageFaith.gd")
const NPC_NAME_ALIASES: Dictionary = NPCData.NPC_NAME_ALIASES

const NPC_LORE_PROFILES: Dictionary = NPCData.NPC_LORE_PROFILES
const INITIAL_PERSON_PROFILES: Dictionary = NPCData.INITIAL_PERSON_PROFILES

const ROLE_FALLBACK_LORE: Dictionary = {
	TradeRole.DOCTOR: ["valen", "valen", "Médico forense y cirujano rural enviado por el Colegio Médico para mantener operativo el Hospital y la Morgue del valle."],
	TradeRole.SHERIFF: ["vane", "vane", "Comisario de frontera designado para restablecer la ley, investigar crímenes y dirigir las patrullas del valle."],
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
	TradeRole.BAKER: ["marlo", "marta", "Panadero llegado de un valle vecino para encender el horno de la calle norte y dar pan a casas y posadas."],
	TradeRole.TAILOR: ["dario", "mila", "Sastre de mano fina que remienda la ropa del pueblo y cose prendas nuevas para quien pueda pagarlas."],
	TradeRole.HERBALIST: ["tomas", "elena", "Herborista y botánico rural dedicado al cultivo de semillas y a la preparación de cataplasmas medicinales."],
	TradeRole.FAMILY_MEMBER: ["aldric", "sora", "Viajero independiente recién llegado a la frontera en busca de fortuna y de un oficio estable en el valle."],
	TradeRole.UNEMPLOYED: ["aldric", "sora", "Viajero independiente recién llegado a la frontera en busca de fortuna y de un oficio estable en el valle."],
}

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

func _finish_frame_movement(delta: float, apply_yield: bool = false) -> void:
	var _pt: int = Time.get_ticks_usec() if perf_on else 0
	if apply_yield:
		_apply_player_and_doorway_yield(delta)
	if perf_on: _pt = _perf_add("m_yield", _pt)
	var lod_k: float = _lod_k # V2: solo en los pasos simplificados de quien está lejos
	if lod_k > 1.0:
		velocity *= lod_k # V2: un paso de varios fotogramas recorre la distancia de todos ellos
	move_and_slide()
	if perf_on: _pt = _perf_add("m_move_and_slide", _pt)
	if lod_k > 1.0:
		velocity /= lod_k
		_lod_k = 1.0
	if _cached_vm:
		if not _footprint_check_done:
			_footprint_check_done = true
			_footprint_supported = _cached_vm.has_method("update_entity_blood_footprints")
		if _footprint_supported:
			_cached_vm.call("update_entity_blood_footprints", self, delta)
	if perf_on: _pt = _perf_add("m_footprints", _pt)
	_update_visual_animation(delta)
	if perf_on: _pt = _perf_add("m_visual_anim", _pt)
	_update_hover_label(delta)
	if perf_on: _perf_add("m_hover_label", _pt)

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

func _ready() -> void:
	set_physics_process(not Engine.is_editor_hint())
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 0
	add_to_group("npcs")
	add_to_group("village_npcs")
	# Desfasar temporizadores de escaneo para que los ~20 NPC no ejecuten sus chequeos pesados en el mismo fotograma (evita picos de lag)
	_visual_memory_timer = randf_range(0.0, 1.25)
	_hover_label_timer = randf_range(0.0, 0.10)
	_unconscious_scan_timer = randf_range(0.0, 0.25)
	_corpse_scan_timer = randf_range(0.0, 0.25)
	if not Engine.is_editor_hint() and WorldClock and not WorldClock.hour_passed.is_connected(_on_hour_passed):
		WorldClock.hour_passed.connect(_on_hour_passed)

func _on_hour_passed(_day: int, _new_hour: int = 0) -> void:
	if is_dead and corpse_on_ground and not corpse_in_morgue:
		corpse_rot_hours += 1.0

func setup_npc(tex: Texture2D, p_work_pos: Vector2, p_bed_pos: Vector2, initial_stock: Dictionary = {}, p_home_table_pos: Vector2 = Vector2.ZERO, p_family_id: String = "none", p_family_name: String = "Independiente") -> void:
	work_position = p_work_pos
	bed_position = p_bed_pos
	home_table_pos = p_home_table_pos if p_home_table_pos != Vector2.ZERO else p_bed_pos + Vector2(0, 18)
	family_id = p_family_id
	family_name = p_family_name
	global_position = work_position
	shop_stock = initial_stock.duplicate()
	need_hunger = randf_range(78.0, 96.0)
	digestion_buffer = 0.0
	need_energy = randf_range(84.0, 98.0)
	need_social = randf_range(58.0, 92.0)
	_hunger_decay_rate = randf_range(0.88, 1.14)
	_energy_decay_rate = randf_range(0.24, 0.30)
	_social_decay_rate = randf_range(0.45, 0.70)
	if personal_gold < 0:
		var gold_range: Vector2i = ROLE_INITIAL_GOLD.get(trade_role, Vector2i(24, 38))
		personal_gold = randi_range(gold_range.x, gold_range.y)
		if trade_role == TradeRole.TRAVELING_MERCHANT:
			carries_royal_safe_conduct = true
	_init_rimworld_psychology()

	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_resolve_unique_64_visuals_and_lore(tex)
	sprite.scale = Vector2(0.54, 0.54)
	add_child(sprite)

	var av3d_script = load("res://scripts/visuals/CharacterAvatar3D.gd")
	if av3d_script != null:
		var av3d = av3d_script.new()
		add_child(av3d)
		av3d.call("setup_for_entity", self, false)

	body_col = _add_circle_col(self, 6.5, true)

	health_comp = HealthComponent.new()
	health_comp.name = "HealthComponent"
	var base_hp: float = 165.0 if trade_role == TradeRole.ROYAL_INVESTIGATOR else (95.0 if trade_role == TradeRole.TRAVELING_MERCHANT else 65.0)
	health_comp.max_health = base_hp
	health_comp.current_health = base_hp
	health_comp.died.connect(_on_died)
	add_child(health_comp)

	stun_comp = StunComponent.new()
	stun_comp.name = "StunComponent"
	stun_comp.max_stun = 100.0
	stun_comp.stun_duration = 8.0
	stun_comp.stunned.connect(_on_stunned)
	add_child(stun_comp)

	hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 0
	_add_circle_col(hurtbox, 10.0)
	hurtbox.hit_received.connect(take_damage)
	add_child(hurtbox)

	interact_area = Area2D.new()
	interact_area.name = "InteractArea"
	interact_area.collision_layer = 1
	interact_area.collision_mask = 2
	interact_area.add_to_group("interactable")
	_add_circle_col(interact_area, 16.0)
	add_child(interact_area)

	status_label = Label.new()
	status_label.visible = false
	_style_label(status_label, Vector2(-135, -42), Vector2(270, 28), 8, Color(1.0, 0.92, 0.68), 3, 20)
	add_child(status_label)

	_setup_craft_progress_bar_ui()
	_init_workshop_materials()

func _setup_craft_progress_bar_ui() -> void:
	_craft_bar_root = Node2D.new()
	_craft_bar_root.name = "CraftProgressBar"
	_craft_bar_root.position = Vector2(0, -25)
	_craft_bar_root.z_index = 18
	_craft_bar_root.visible = false
	add_child(_craft_bar_root)

	_craft_bar_bg = Polygon2D.new()
	_craft_bar_bg.color = Color(0.07, 0.08, 0.11, 0.88)
	_craft_bar_bg.polygon = PackedVector2Array([Vector2(-20, -3), Vector2(20, -3), Vector2(20, 2), Vector2(-20, 2)])
	_craft_bar_root.add_child(_craft_bar_bg)

	_craft_bar_fill = Polygon2D.new()
	_craft_bar_fill.color = Color(0.98, 0.78, 0.24, 0.95)
	_craft_bar_fill.polygon = PackedVector2Array([Vector2(-19, -2), Vector2(-19, -2), Vector2(-19, 1), Vector2(-19, 1)])
	_craft_bar_root.add_child(_craft_bar_fill)

	_craft_bar_label = Label.new()
	_style_label(_craft_bar_label, Vector2(-80, -14), Vector2(160, 11), 7, Color(1.0, 0.95, 0.75), 2)
	_craft_bar_root.add_child(_craft_bar_label)

func _init_workshop_materials() -> void:
	_craft_progress = randf_range(5.0, 42.0)
	_supply_run_cooldown = randf_range(10.0, 34.0)
	workshop_materials = (ROLE_INITIAL_MATERIALS.get(trade_role, {}) as Dictionary).duplicate()
	if pocket_items.is_empty():
		_init_npc_pockets()

func _init_npc_pockets() -> void:
	pocket_items.clear()
	match trade_role:
		TradeRole.BLACKSMITH:
			pocket_items = {"bread": 1, "iron_ore": 1}
		TradeRole.CARPENTER:
			pocket_items = {"bread": 1, "wood": 2}
		TradeRole.BUTCHER:
			pocket_items = {"cooked_meat": 1, "leather": 1}
		TradeRole.HERBALIST:
			pocket_items = {"herbal_poultice": 1, "herbs": 2}
		TradeRole.FISHMONGER:
			pocket_items = {"bread": 1, "cooked_fish": 1}
		TradeRole.INNKEEPER:
			pocket_items = {"country_stew": 1, "bread": 1}
		TradeRole.DOCTOR:
			pocket_items = {"surgical_kit": 1, "bandage": 2}
		TradeRole.SHERIFF, TradeRole.GUARD:
			pocket_items = {"bandage": 1, "bread": 1}
		TradeRole.TRAVELING_MERCHANT:
			pocket_items = {"royal_safe_conduct": 1, "royal_ration": 1}
			carries_royal_safe_conduct = true
		TradeRole.ROYAL_INVESTIGATOR:
			pocket_items = {"royal_ration": 1, "bandage": 1}
		_:
			pocket_items = {"bread": 1}
	if carries_royal_safe_conduct:
		pocket_items["royal_safe_conduct"] = maxi(1, int(pocket_items.get("royal_safe_conduct", 0)))

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

func _init_rimworld_psychology() -> void:
	if ROLE_PSYCHOLOGY.has(trade_role):
		var entry: Array = ROLE_PSYCHOLOGY[trade_role]
		traits.assign(entry[0])
		favorite_item = str(entry[1])
		thoughts.assign(entry[2])
	else:
		var pool_traits: Array[String] = ["Alegre", "Tahúr", "Glotón", "Noctámbulo", "Amante de Animales", "Curioso", "Leal"]
		var idx1: int = abs(npc_name.hash()) % pool_traits.size()
		traits = [pool_traits[idx1], pool_traits[(idx1 + 3) % pool_traits.size()]]
		var fav_pool: Array[String] = ["bread", "cooked_meat", "roasted_chicken", "country_stew", "cooked_fish"]
		favorite_item = fav_pool[abs(npc_name.hash()) % fav_pool.size()]
		thoughts = ["Paseando por el valle (+5)"]
	_init_person_profile()
	mood = clampf(78.0 + randf_range(-6.0, 12.0), 40.0, 98.0)

func _init_person_profile() -> void:
	if person_profile == null:
		var clean_name := npc_name.strip_edges()
		var lookup_name: String = str(NPC_NAME_ALIASES.get(clean_name, clean_name))
		if INITIAL_PERSON_PROFILES.has(lookup_name):
			person_profile = PersonProfile.from_dict(INITIAL_PERSON_PROFILES[lookup_name])
		else:
			person_profile = PersonProfile.make_fallback_for_name(clean_name)
	if person_profile != null:
		npc_id = str(person_profile.person_id)
		if not person_profile.personality.is_empty():
			traits.assign(person_profile.personality)
		if str(person_profile.favorite_item) != "":
			favorite_item = str(person_profile.favorite_item)

func get_portrait_texture() -> Texture2D:
	return portrait_texture if portrait_texture != null else (sprite.texture if sprite else null)

func get_character_tagline() -> String:
	return character_tagline

static var _tex_64_cache: Dictionary = {}

func _load_64_tex(res_path: String) -> Texture2D:
	if _tex_64_cache.has(res_path) and _tex_64_cache[res_path] is Texture2D:
		return _tex_64_cache[res_path] as Texture2D
	var abs_p := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_p):
		var img := Image.load_from_file(abs_p)
		if img and not img.is_empty():
			var itex := ImageTexture.create_from_image(img)
			_tex_64_cache[res_path] = itex
			return itex
	if ResourceLoader.exists(res_path):
		var t = load(res_path)
		if t is Texture2D:
			_tex_64_cache[res_path] = t
			return t
	return null

func _resolve_unique_64_visuals_and_lore(fallback_tex: Texture2D = null) -> void:
	var clean_name := npc_name.strip_edges()
	var lookup_name: String = str(NPC_NAME_ALIASES.get(clean_name, clean_name))
	var key := "aldric"
	if NPC_LORE_PROFILES.has(lookup_name):
		var p: Array = NPC_LORE_PROFILES[lookup_name]
		key = str(p[0])
		character_tagline = str(p[1])
		character_lore = str(p[2])
		character_secret = str(p[3])
	else:
		var fem: bool = (person_profile != null and str(person_profile.gender) == "F") or (person_profile == null and clean_name.ends_with("a"))
		var fb: Array = ROLE_FALLBACK_LORE.get(trade_role, ["bram", "mila", "Artesano profesional llegado de los valles vecinos para hacerse cargo del taller y mantener viva la economía local."])
		key = str(fb[1] if fem else fb[0])
		character_tagline = str(fb[2])
		character_lore = "«Llegué al valle tras escuchar que la comunidad necesitaba manos expertas. No vengo a hacer preguntas sobre lo que le ocurrió a mi predecesor: mientras haya trabajo y corra el oro, cumpliré mi jornada de sol a sol.»"
		character_secret = "«En este pueblo las paredes oyen y las puertas cerradas guardan más de un secreto. Conviene llevarse bien con los vecinos si quieres prosperar aquí.»"
		match trade_role: # V6/V9: historias que no son de forastero recién llegado
			TradeRole.CHILD:
				character_lore = "«Nací aquí, en el valle. Mis padres dicen que pregunto demasiado. Cuando sea mayor quiero tener mi propio taller... o irme lejos, todavía no lo sé.»"
				character_secret = "«Sé dónde se esconden los mayores cuando no quieren que los vean. Los niños nos fijamos en todo.»"
			TradeRole.NOBLE:
				character_lore = "«Mi familia lleva generaciones cobrando las rentas de estas tierras. El pueblo nos mira con respeto... o con envidia, según el día.»"
				character_secret = "«Las cuentas de la casa no van tan bien como aparentamos. Que nadie lo sepa.»"
			TradeRole.TEACHER:
				character_lore = "«Alguien tiene que enseñar a leer y a contar a los críos del valle. No es mal oficio, aunque las arcas paguen tarde.»"

	var anim_64 := _load_64_tex("res://assests/world/village/npcs_64/anim_%s.png" % key)
	var spr_64 := _load_64_tex("res://assests/world/village/npcs_64/sprite_%s.png" % key)
	var port_64 := _load_64_tex("res://assests/world/village/npcs_64/portrait_%s.png" % key)
	if sprite != null:
		if anim_64 != null:
			sprite.texture = anim_64
			sprite.hframes = 4
			sprite.vframes = 3
			sprite.frame = 0
			_has_spritesheet_anim = true
		elif spr_64 != null or fallback_tex != null:
			sprite.texture = spr_64 if spr_64 != null else fallback_tex
			sprite.hframes = 1
			sprite.vframes = 1
			_has_spritesheet_anim = false
	portrait_texture = port_64 if port_64 != null else (spr_64 if spr_64 != null else fallback_tex)

const INITIAL_NPC_RELATIONS: Dictionary = NPCData.INITIAL_NPC_RELATIONS

## Devuelve el identificador único (`person_id`) de un vecino a partir de su `person_id` o `npc_name` (solo entre vecinos vivos).
func resolve_person_id_key(key_or_name: String) -> String:
	var clean := key_or_name.strip_edges()
	if clean == "":
		return ""
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC and not n.is_dead:
				var vn := n as VillageNPC
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
		if not (n is VillageNPC) or n == self or n.is_dead:
			continue
		var other := n as VillageNPC
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
		if not (n is VillageNPC) or n == self:
			continue
		var other := n as VillageNPC
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
func modify_npc_relationship(other: VillageNPC, delta_val: int, reason: String = "", one_way: bool = false) -> void:
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

func _trigger_dynamic_npc_social_interaction(partner: VillageNPC) -> void:
	if not is_instance_valid(partner) or partner == self or partner.is_dead or partner.is_downed:
		return
	if _pending_social_reply_timer > 0.0 or partner._pending_social_reply_timer > 0.0:
		return
	var vm_soc = _get_vm()
	var sdir = vm_soc.get("social_director") if vm_soc != null else null
	if sdir != null and sdir.has_method("resolve_live_conversation"):
		var cur_day: int = int(WorldClock.current_day) if WorldClock != null else 1
		var ex: Dictionary = sdir.call("resolve_live_conversation", self, partner, cur_day)
		if not bool(ex.get("allowed", false)):
			_spawn_floating_text("💬", Color(0.75, 0.95, 1.0), -28.0)
			return
		_npc_social_event_cooldown = randf_range(16.0, 26.0) * get_social_cooldown_mult()
		partner._npc_social_event_cooldown = randf_range(16.0, 26.0) * partner.get_social_cooldown_mult()
		var line_a: String = str(ex.get("line_a", ""))
		var line_b: String = str(ex.get("line_b", ""))
		var icon: String = str(ex.get("icon", "💬"))
		var col: Color = ex.get("color", Color(0.75, 0.96, 1.0))
		last_social_line_spoken = line_a
		_spawn_floating_text("%s «%s»" % [icon, line_a], col, -34.0)
		var dx: float = partner.global_position.x - global_position.x
		if absf(dx) > 2.0:
			if sprite:
				sprite.flip_h = (dx < 0.0)
			if partner.sprite:
				partner.sprite.flip_h = (dx > 0.0)
		partner._pending_social_reply_timer = 1.8
		partner._pending_social_reply_data = {
			"initiator": self,
			"line_b": line_b,
			"delta_rel": int(ex.get("delta_rel", 0)),
			"delta_rel_a": int(ex.get("delta_rel_a", ex.get("delta_rel", 0))),
			"delta_rel_b": int(ex.get("delta_rel_b", ex.get("delta_rel", 0))),
			"note": str(ex.get("note", "Charlaron en el pueblo")),
			"icon": icon,
			"color": col,
		}
		return
	_npc_social_event_cooldown = randf_range(16.0, 26.0) * get_social_cooldown_mult()
	partner._npc_social_event_cooldown = randf_range(16.0, 26.0) * partner.get_social_cooldown_mult()
	var cur_rel: int = get_relationship_with_npc(partner.npc_name)
	var roll: float = randf()
	if cur_rel <= -20:
		# 32% de probabilidad de giro inesperado ("por azares del destino") donde dos enemigos conectan positivamente
		if roll < 0.32:
			var boost: int = randi_range(18, 28)
			modify_npc_relationship(partner, boost, "Charla sincera e inesperada que limó viejas rencillas")
			_spawn_floating_text("🍻🤝 Charla inesperada con %s (+%d Relación vecinal)" % [partner.npc_name, boost], Color.SPRING_GREEN, -34.0)
		else:
			var drop: int = randi_range(-10, -5)
			modify_npc_relationship(partner, drop, "Discusión tensa al cruzarse en el pueblo")
			_spawn_floating_text("😠💬 Roce con %s (%d Relación vecinal)" % [partner.npc_name, drop], Color.ORANGE, -34.0)
	elif cur_rel >= 35:
		if roll < 0.14:
			var drop_f: int = randi_range(-14, -8)
			modify_npc_relationship(partner, drop_f, "Malentendido reciente conversando en el pueblo")
			_spawn_floating_text("😒💬 Desacuerdo con %s (%d Relación vecinal)" % [partner.npc_name, drop_f], Color.GOLD, -34.0)
		else:
			var gain_f: int = randi_range(6, 12)
			modify_npc_relationship(partner, gain_f, "Buena conversación y apoyo mutuo entre amigos")
			_spawn_floating_text("😊🤝 Charla amena con %s (+%d Relación vecinal)" % [partner.npc_name, gain_f], Color(0.65, 1.0, 0.78), -34.0)
	else:
		if roll < 0.72:
			var gain_n: int = randi_range(8, 15)
			modify_npc_relationship(partner, gain_n, "Se cayeron bien charlando durante el descanso")
			_spawn_floating_text("🙂💬 Buena charla con %s (+%d Relación vecinal)" % [partner.npc_name, gain_n], Color(0.75, 0.96, 1.0), -34.0)
		else:
			var drop_n: int = randi_range(-12, -6)
			modify_npc_relationship(partner, drop_n, "Choque de opiniones durante la jornada")
			_spawn_floating_text("😒💬 Discusión con %s (%d Relación vecinal)" % [partner.npc_name, drop_n], Color.ORANGE, -34.0)

func _process_pending_social_reply(delta: float) -> void:
	if _pending_social_reply_timer <= 0.0:
		return
	if is_incapacitated() or is_sleeping or is_hostile:
		_pending_social_reply_timer = 0.0
		_pending_social_reply_data.clear()
		return
	_pending_social_reply_timer -= delta
	if _pending_social_reply_timer > 0.0:
		return
	_pending_social_reply_timer = 0.0
	var initiator: VillageNPC = _pending_social_reply_data.get("initiator", null)
	var line_b: String = str(_pending_social_reply_data.get("line_b", ""))
	var delta_rel: int = int(_pending_social_reply_data.get("delta_rel", 0))
	var d_init: int = int(_pending_social_reply_data.get("delta_rel_a", delta_rel)) # U2: lo que gana quien empezó la charla
	var d_self: int = int(_pending_social_reply_data.get("delta_rel_b", delta_rel)) # y lo que gana quien responde
	var note_str: String = str(_pending_social_reply_data.get("note", "Charlaron en el pueblo"))
	var icon_str: String = str(_pending_social_reply_data.get("icon", "💬"))
	var col: Color = _pending_social_reply_data.get("color", Color(0.75, 0.96, 1.0))
	_pending_social_reply_data.clear()
	if not is_instance_valid(initiator) or initiator.is_incapacitated() or initiator.is_sleeping:
		return
	if global_position.distance_to(initiator.global_position) > 140.0:
		return
	last_social_line_spoken = line_b
	# U2: la parte común se suma a los dos (con sus avisos de reconciliación o ruptura); el resto, a cada uno por su lado
	var d_common: int = int(round(float(d_init + d_self) / 2.0))
	initiator.modify_npc_relationship(self, d_common, note_str)
	if d_init != d_common:
		initiator.modify_npc_relationship(self, d_init - d_common, "", true)
	if d_self != d_common:
		modify_npc_relationship(initiator, d_self - d_common, "", true)
	var sign_tag: String = "+%d" % d_self if d_self >= 0 else "%d" % d_self
	_spawn_floating_text("%s «%s» (%s Rel)" % [icon_str, line_b, sign_tag], col, -36.0)
	_try_player_overhear(initiator, note_str)
	var vm_news = _get_vm()
	# T4: el chismoso cuenta novedades más a menudo y el frío menos (Chismoso solo: 75 %)
	if vm_news != null and randf() < clampf(0.5 + 0.25 * TraitCatalog.npc_tendency(initiator, "gossip") + (VillageFaith.BAND_GOSSIP_BONUS if VillageFaith.same_band(vm_news, initiator, self) else 0.0), 0.15, 0.9):
		var news: Dictionary = vm_news.spread_gossip(initiator, self)
		if not news.is_empty():
			initiator._spawn_floating_text("🗣️ «¿Te has enterado? %s»" % vm_news.gossip_text(news, self, get_person_key()), Color(1.0, 0.92, 0.65), -46.0)
	# R5: quien contesta también puede contar algo que el otro no sepa
	if vm_news != null and randf() < clampf(0.5 + 0.25 * TraitCatalog.npc_tendency(self, "gossip") + (VillageFaith.BAND_GOSSIP_BONUS if VillageFaith.same_band(vm_news, initiator, self) else 0.0), 0.15, 0.9):
		var news_b: Dictionary = vm_news.spread_gossip(self, initiator)
		if not news_b.is_empty():
			_spawn_floating_text("🗣️ «¿Y sabes qué? %s»" % vm_news.gossip_text(news_b, initiator, initiator.get_person_key()), Color(1.0, 0.92, 0.65), -50.0)
	if vm_news != null:
		vm_news.try_npc_slander(initiator, self)

## B5.1: Si el jugador está en sigilo y a distancia de oído, se entera de cómo están realmente las cosas entre los dos.
func _try_player_overhear(other: VillageNPC, note_str: String) -> bool:
	var player = _get_player()
	if player == null or not player.has_method("is_stealthing") or not player.is_stealthing():
		return false
	var hearing: float = 96.0 + 12.0 * float(int(player.call("get_skill_level", "stealth")) - 1)
	if global_position.distance_to(player.global_position) > hearing:
		return false
	var feeling: String = NPCDialogue.describe_feeling(get_relationship_with_npc(other.get_person_key()))
	_spawn_floating_text("👂 %s y %s %s: %s" % [other.npc_name, npc_name, feeling, note_str], Color(0.80, 0.75, 1.0), -52.0)
	player.call("add_skill_xp", "stealth", 3)
	TraitDiscovery.reveal_next(self, "le has espiado")
	return true

## Inicia la búsqueda física de un familiar que no llegó a dormir a casa ni sigue su rutina habitual:
## Fase 1: Ir a la tienda/taller familiar a buscarlo (8s). Si encuentra su cadáver allí, activa el reporte físico de inmediato.
## Fase 2: Si no está en la tienda, caminar hacia el policía más cercano.
## Fase 3: Explicar durante 10s a la policía que su familiar ha desaparecido para que la guardia salga a buscarlo.
func begin_missing_family_search(kin: VillageNPC) -> void:
	if not is_instance_valid(kin) or kin == self or is_incapacitated():
		return
	if is_instance_valid(_reporting_corpse_target) or is_instance_valid(_searching_missing_kin):
		return
	_clear_unconscious_reaction_state()
	_searching_missing_kin = kin
	_missing_kin_phase = 1
	_missing_kin_timer = 0.0
	is_sleeping = false
	if sprite:
		sprite.rotation_degrees = 0.0
	add_thought("Preocupado: %s no ha vuelto a casa (-10)" % kin.npc_name, -10.0)
	_spawn_floating_text("😟🏠 ¡%s no ha llegado a dormir a casa! Voy a la tienda a ver qué pasó..." % kin.npc_name, Color.GOLD, -44.0)
	var vm = _get_vm()
	if vm and vm.has_method("_hint_player"):
		vm.call("_hint_player", "😟🏠 %s ha notado que su familiar %s no llegó a dormir a casa y va camino a la tienda a buscarlo." % [npc_name, kin.npc_name])

func _get_family_shop_search_pos(kin: VillageNPC) -> Vector2:
	if is_instance_valid(kin) and kin.work_position.distance_to(home_table_pos) > 36.0:
		return kin.work_position
	if work_position.distance_to(home_table_pos) > 36.0:
		return work_position
	var vm = _get_vm()
	if vm and "trade_configs" in vm and vm.trade_configs.has(linked_trade):
		var cfg: Dictionary = vm.trade_configs[linked_trade]
		if cfg.has("work_pos"):
			return cfg["work_pos"] as Vector2
	return Vector2(465, 44)

func _process_family_missing_search(delta: float) -> bool:
	if is_instance_valid(_searching_missing_kin):
		var kin: VillageNPC = _searching_missing_kin
		if kin.corpse_reported or kin.corpse_in_morgue:
			_searching_missing_kin = null
			_missing_kin_phase = 0
			_missing_kin_timer = 0.0
			_stop_crafting_bar()
			return false
		# Si durante la búsqueda ve el cadáver de su familiar, pasa de inmediato a examinar el cuerpo (10s) y reportarlo
		if kin.is_dead and kin.corpse_on_ground and global_position.distance_to(kin.global_position) <= 95.0:
			_searching_missing_kin = null
			_missing_kin_phase = 0
			_missing_kin_timer = 0.0
			_stop_crafting_bar()
			kin.begin_physical_corpse_discovery(self)
			return true
		# Si lo encuentra vivo y cerca, se tranquiliza
		if not kin.is_dead and not kin.is_downed and global_position.distance_to(kin.global_position) <= 48.0:
			_searching_missing_kin = null
			_missing_kin_phase = 0
			_missing_kin_timer = 0.0
			_stop_crafting_bar()
			_spawn_floating_text("😮‍💨🏠 ¡Ahí estás, %s! Me tenías preocupado al no verte en casa." % kin.npc_name, Color.SPRING_GREEN, -40.0)
			return false

		is_sleeping = false
		if sprite:
			sprite.rotation_degrees = 0.0

		# FASE 1: Ir a la tienda/taller familiar e inspeccionar durante 8.0s
		if _missing_kin_phase == 1:
			var shop_pos: Vector2 = _get_family_shop_search_pos(kin)
			if global_position.distance_to(shop_pos) > 24.0:
				_stop_crafting_bar()
				_move_towards_point(shop_pos, 58.0, delta)
				_finish_frame_movement(delta)
				return true
			velocity = Vector2.ZERO
			_missing_kin_timer += delta
			var rem_s: int = maxi(1, int(ceil(8.0 - _missing_kin_timer)))
			_update_craft_bar_visual(clampf(_missing_kin_timer / 8.0, 0.02, 1.0), "😟🔍 Buscando a %s en tienda (%ds)" % [kin.npc_name, rem_s], Color(1.0, 0.78, 0.28, 0.95))
			trigger_action_animation(0.4)
			_finish_frame_movement(delta)
			if _missing_kin_timer >= 8.0:
				_stop_crafting_bar()
				_missing_kin_timer = 0.0
				_missing_kin_phase = 2
				_spawn_floating_text("😰🚨 ¡%s tampoco está en la tienda! ¡Voy a pedir ayuda a la policía!" % kin.npc_name, Color.ORANGE_RED, -42.0)
			return true

		# Buscar al policía más cercano (incluyendo si está durmiendo en la Comisaría por la noche para despertarlo)
		var nearest_police: VillageNPC = _find_nearest_available_authority(true)
		var pol_dest: Vector2 = nearest_police.global_position if nearest_police != null else Vector2(886, 132)

		# FASE 2: Caminar personalmente hacia la policía
		if _missing_kin_phase == 2:
			if global_position.distance_to(pol_dest) > 26.0:
				_stop_crafting_bar()
				_move_towards_point(pol_dest, 60.0, delta)
				_finish_frame_movement(delta)
				return true
			velocity = Vector2.ZERO
			_missing_kin_phase = 3
			_missing_kin_timer = 0.0
			if nearest_police != null:
				nearest_police.is_sleeping = false
				if nearest_police.sprite:
					nearest_police.sprite.rotation_degrees = 0.0
			_spawn_floating_text("🗣️🚓 ¡Guardia, por favor! ¡%s no llegó a casa ni está en su tienda!" % kin.npc_name, Color.GOLD, -42.0)
			return true

		# FASE 3: Explicar la desaparición a la policía durante 10.0s
		if global_position.distance_to(pol_dest) > 34.0:
			_stop_crafting_bar()
			_move_towards_point(pol_dest, 60.0, delta)
			_finish_frame_movement(delta)
			return true
		velocity = Vector2.ZERO
		if nearest_police != null:
			nearest_police.is_sleeping = false
			if nearest_police.sprite:
				nearest_police.sprite.rotation_degrees = 0.0
			nearest_police.hold_for_interview(self, 0.8)
			if sprite:
				sprite.flip_h = (nearest_police.global_position.x < global_position.x)
		_missing_kin_timer += delta
		var rem_p: int = maxi(1, int(ceil(10.0 - _missing_kin_timer)))
		var p_name: String = nearest_police.npc_name if nearest_police != null else "la Guardia"
		_update_craft_bar_visual(clampf(_missing_kin_timer / 10.0, 0.02, 1.0), "🗣️🚓 Denunciando ausencia a %s (%ds)" % [p_name, rem_p], Color(0.45, 0.88, 1.0, 0.95))
		trigger_action_animation(0.4)
		_finish_frame_movement(delta)
		if _missing_kin_timer >= 10.0:
			_stop_crafting_bar()
			_missing_kin_reported_day = WorldClock.current_day if WorldClock else 1
			var missing_ref: VillageNPC = kin
			_searching_missing_kin = null
			_missing_kin_phase = 0
			_missing_kin_timer = 0.0
			_spawn_floating_text("📢 ¡%s denunció la desaparición de %s ante %s!" % [npc_name, missing_ref.npc_name, p_name], Color.AQUA, -42.0)
			if nearest_police != null:
				nearest_police.start_missing_person_police_search(missing_ref, self)
		return true

	# Detección automática en casa por la noche (21:00 - 06:00): ¿Falta mi familiar en su cama/casa?
	if family_id in ["family_smith", "family_butcher", "family_carpenter", "family_fishmonger", "family_herbalist"]:
		var cur_d: int = WorldClock.current_day if WorldClock else 1
		var cur_h: int = WorldClock.current_hour if WorldClock else 12
		var is_sleep_hours: bool = (cur_h >= 21 or cur_h < 6)
		if is_sleep_hours and _missing_kin_reported_day != cur_d and (global_position.distance_to(home_table_pos) <= 95.0 or is_sleeping):
			for n in get_tree().get_nodes_in_group("village_npcs"):
				if n is VillageNPC and n != self:
					var cand_kin := n as VillageNPC
					if cand_kin.family_id == family_id and not cand_kin.corpse_reported and not cand_kin.corpse_in_morgue:
						var dist_home: float = minf(cand_kin.global_position.distance_to(cand_kin.bed_position), cand_kin.global_position.distance_to(home_table_pos))
						if dist_home > 85.0:
							# Si el familiar está muerto, abatido, sedado o ya pasan de las 22:00 sin estar en casa, crece la preocupación
							if cand_kin.is_dead or cand_kin.is_downed or cand_kin.sedated_timer > 0.0 or cur_h >= 22 or cur_h < 6:
								_kin_absence_worry_timer += delta
								if _kin_absence_worry_timer >= 4.0:
									_kin_absence_worry_timer = 0.0
									begin_missing_family_search(cand_kin)
									return true
						else:
							_kin_absence_worry_timer = 0.0
						break
		else:
			_kin_absence_worry_timer = 0.0
	return false

func _find_nearest_available_authority(allow_waking_sleeping: bool = false) -> VillageNPC:
	var nearest_authority: VillageNPC = null
	var best_dist: float = 999999.0
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != self:
			var auth := n as VillageNPC
			var ok_state: bool = (not auth.is_incapacitated()) if allow_waking_sleeping else auth.is_conscious()
			if auth.trade_role in [TradeRole.SHERIFF, TradeRole.GUARD] and ok_state:
				var d: float = global_position.distance_to(auth.global_position)
				if d < best_dist:
					best_dist = d
					nearest_authority = auth
	if nearest_authority == null:
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC and n != self:
				var auth2 := n as VillageNPC
				var ok_state2: bool = (not auth2.is_incapacitated()) if allow_waking_sleeping else auth2.is_conscious()
				if auth2.trade_role == TradeRole.DOCTOR and ok_state2:
					var d2: float = global_position.distance_to(auth2.global_position)
					if d2 < best_dist:
						best_dist = d2
						nearest_authority = auth2
	return nearest_authority

func start_missing_person_police_search(missing_npc: VillageNPC, reporter: VillageNPC) -> void:
	if not is_instance_valid(missing_npc):
		return
	is_sleeping = false
	if sprite:
		sprite.rotation_degrees = 0.0
	_patrol_search_target_npc = missing_npc
	_patrol_search_target_pos = missing_npc.global_position
	_patrol_search_timer = 45.0
	var rep_name: String = reporter.npc_name if is_instance_valid(reporter) else "un vecino"
	_spawn_floating_text("🚓🔦 «Calma, %s. Iré en persona a buscar a %s ahora mismo.»" % [rep_name, missing_npc.npc_name], Color.AQUA, -40.0)
	var vm = _get_vm()
	if vm and vm.has_method("_hint_player"):
		vm.call("_hint_player", "🚓🔦 ¡PATRULLA DE BÚSQUEDA! Tras la denuncia de %s, %s ha salido a rastrear el paradero de %s." % [rep_name, npc_name, missing_npc.npc_name])

func _process_police_missing_person_patrol(delta: float) -> bool:
	if _patrol_search_timer <= 0.0:
		return false
	_patrol_search_timer = maxf(0.0, _patrol_search_timer - delta)
	if is_instance_valid(_patrol_search_target_npc):
		var m_npc: VillageNPC = _patrol_search_target_npc
		if m_npc.corpse_reported or m_npc.corpse_in_morgue:
			_patrol_search_timer = 0.0
			_patrol_search_target_npc = null
			_stop_crafting_bar()
			return false
		_patrol_search_target_pos = m_npc.global_position
		if m_npc.is_dead and m_npc.corpse_on_ground and global_position.distance_to(m_npc.global_position) <= 90.0:
			_patrol_search_timer = 0.0
			_patrol_search_target_npc = null
			_stop_crafting_bar()
			m_npc.begin_physical_corpse_discovery(self)
			return true
		if not m_npc.is_dead and global_position.distance_to(m_npc.global_position) <= 45.0:
			_patrol_search_timer = 0.0
			_patrol_search_target_npc = null
			_stop_crafting_bar()
			if m_npc.is_downed:
				m_npc.revive_from_downed(self, false)
			_spawn_floating_text("🚓🔦 ¡Localicé a %s!" % m_npc.npc_name, Color.SPRING_GREEN, -38.0)
			return false
	is_sleeping = false
	if sprite:
		sprite.rotation_degrees = 0.0
	var tgt_name: String = _patrol_search_target_npc.npc_name if is_instance_valid(_patrol_search_target_npc) else "vecino desaparecido"
	_update_craft_bar_visual(clampf(_patrol_search_timer / 45.0, 0.05, 1.0), "🚓🔦 Buscando a %s" % tgt_name, Color(0.40, 0.88, 1.0, 0.95))
	if global_position.distance_to(_patrol_search_target_pos) > 22.0:
		_move_towards_point(_patrol_search_target_pos, 66.0, delta)
	else:
		velocity = Vector2.ZERO
		_patrol_search_timer = 0.0
		_patrol_search_target_npc = null
		_stop_crafting_bar()
	_finish_frame_movement(delta)
	return true

func add_thought(thought_text: String, mood_delta: float) -> void:
	if thoughts.has(thought_text):
		thoughts.erase(thought_text)
	thoughts.push_front(thought_text)
	while thoughts.size() > 3:
		thoughts.pop_back()
	mood = clampf(mood + mood_delta, 0.0, 100.0)

var _pre_poker_pos: Vector2 = Vector2.ZERO

func _show_status_label(txt: String, col: Color) -> void:
	if status_label:
		status_label.text = txt
		status_label.add_theme_color_override("font_color", col)
		status_label.visible = true

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

func wake_up_from_unconscious(rescuer: VillageNPC = null) -> void:
	sedated_timer = 0.0
	is_stunned_flag = false
	is_sleeping = false
	_unconscious_helper_npc = null
	_unconscious_ignored_by.clear()
	_set_sprite_pose(0.0, Color.WHITE)
	if is_instance_valid(rescuer):
		add_thought("Despertado y auxiliado por %s (+6)" % rescuer.npc_name, 6.0)

## Comprueba si algún tercer vecino consciente o el Jugador está mirando al oportunista o a la víctima inconsciente (con línea de visión)
func _has_any_witness_watching_opportunist(victim: VillageNPC) -> Node2D:
	if not is_inside_tree():
		return null
	var vm = _get_vm()
	var check_pos: Vector2 = victim.global_position if is_instance_valid(victim) else global_position
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != self and n != victim:
			var w := n as VillageNPC
			if w.is_conscious():
				var d_v: float = w.global_position.distance_to(check_pos)
				var d_s: float = w.global_position.distance_to(global_position)
				if minf(d_v, d_s) <= 135.0:
					var has_los_v: bool = (vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", w.global_position, check_pos))
					var has_los_s: bool = (vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", w.global_position, global_position))
					if has_los_v or has_los_s:
						return w
	var p: Node2D = _get_player()
	if is_instance_valid(p) and not (p.has_method("is_stunned") and bool(p.call("is_stunned"))):
		var dp_v: float = p.global_position.distance_to(check_pos)
		var dp_s: float = p.global_position.distance_to(global_position)
		if minf(dp_v, dp_s) <= 120.0:
			var p_los_v: bool = (vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", p.global_position, check_pos))
			var p_los_s: bool = (vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", p.global_position, global_position))
			if p_los_v or p_los_s:
				return p
	return null

func _scan_unconscious_victim_for_passersby(delta: float) -> void:
	if not is_unconscious_on_ground() or not is_inside_tree():
		return
	if is_instance_valid(_unconscious_helper_npc) and _unconscious_helper_npc.is_conscious() and _unconscious_helper_npc._reacting_unconscious_target == self:
		return
	_unconscious_scan_timer -= delta
	if _unconscious_scan_timer > 0.0:
		return
	_unconscious_scan_timer = 0.25
	var vm = _get_vm()
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != self:
			var other := n as VillageNPC
			if not other.is_conscious() or other.is_hostile or other.is_at_poker_table:
				continue
			if other.trade_role in [TradeRole.ROYAL_INVESTIGATOR, TradeRole.TRAVELING_MERCHANT]:
				continue
			if is_instance_valid(other._reporting_corpse_target) or is_instance_valid(other._carrying_corpse_target) or is_instance_valid(other._searching_missing_kin) or is_instance_valid(other._reacting_unconscious_target):
				continue
			if _unconscious_ignored_by.has(other.npc_name):
				continue
			if other.global_position.distance_to(global_position) <= 95.0 and ((vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", other.global_position, global_position))):
				if begin_unconscious_neighbor_reaction(other):
					break

## Inicia la reacción de un vecino consciente al encontrar a este NPC inconsciente (estuneado o sedado) según su relación:
## - Enemigo (<= -25): No reporta nada; vigila que nadie esté mirando antes de acercarse a robarle (4s). Si alguien mira, disimula y lo deja tirado.
## - Amigo (>= 25) / Familiar / Autoridad: Corre a socorrerlo y despertarlo rápido (4s), gana afinidad y va a avisar/colaborar con la policía (6s).
## - Neutral (-24..+24): Se acerca con cautela a despertarlo (7s) y sigue su rutina.
func begin_unconscious_neighbor_reaction(discoverer: VillageNPC) -> bool:
	if discoverer == null or discoverer == self or not is_unconscious_on_ground():
		return false
	if is_instance_valid(_unconscious_helper_npc) and _unconscious_helper_npc.is_conscious() and _unconscious_helper_npc._reacting_unconscious_target == self:
		return false
	var rel: int = discoverer.get_relationship_with_npc(npc_name)
	var same_fam: bool = (family_id != "none" and family_id != "" and family_id != "family_police" and discoverer.family_id == family_id)
	var is_authority: bool = discoverer.trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.DOCTOR]

	# Caso 1: Enemigo / Rival Oportunista (rel <= -25, no familiar ni policía/médico)
	if rel <= -25 and not same_fam and not is_authority:
		if personal_gold <= 0 and pocket_items.is_empty():
			_unconscious_ignored_by[discoverer.npc_name] = true
			discoverer._spawn_floating_text("😏💤 ¿%s tirado en el suelo y sin un centavo? Ahí te quedas." % npc_name, Color(0.95, 0.72, 0.35), -40.0)
			return false
		var watcher: Node2D = discoverer._has_any_witness_watching_opportunist(self)
		if watcher != null:
			_unconscious_ignored_by[discoverer.npc_name] = true
			discoverer._spawn_floating_text("😒👀 Hay gente mirando... mejor no le robo a %s, pero tampoco pienso ayudarlo." % npc_name, Color(0.92, 0.68, 0.38), -40.0)
			return false
		_unconscious_helper_npc = discoverer
		discoverer._reacting_unconscious_target = self
		discoverer._unconscious_react_mode = "opportunist_steal"
		discoverer._unconscious_react_phase = 1
		discoverer._unconscious_react_timer = 0.0
		discoverer._spawn_floating_text("😏👀 Nadie mira... aprovechemos que %s está inconsciente para vaciarle los bolsillos." % npc_name, Color.GOLD, -42.0)
		return true

	# Caso 2: Amigo (>= 25), Familiar o Autoridad -> Socorro rápido (4s) + Alerta/Colaboración con la Policía
	if rel >= 25 or same_fam or is_authority:
		_unconscious_helper_npc = discoverer
		discoverer._reacting_unconscious_target = self
		discoverer._unconscious_react_mode = "friend_rescue"
		discoverer._unconscious_react_phase = 1
		discoverer._unconscious_react_timer = 0.0
		discoverer._spawn_floating_text("😟⚡ ¡%s está inconsciente en el suelo! ¡Resiste, voy a despertarte!" % npc_name, Color.SPRING_GREEN, -42.0)
		return true

	# Caso 3: Vecino Neutral (-24 a +24) -> Despierta con cautela (7s) sin ir a la policía
	_unconscious_helper_npc = discoverer
	discoverer._reacting_unconscious_target = self
	discoverer._unconscious_react_mode = "neutral_wake"
	discoverer._unconscious_react_phase = 1
	discoverer._unconscious_react_timer = 0.0
	discoverer._spawn_floating_text("🤨🤚 Oye %s, ¿qué haces tirado ahí? Levántate..." % npc_name, Color(0.78, 0.92, 1.0), -40.0)
	return true

func _clear_unconscious_reaction_state() -> void:
	if is_instance_valid(_reacting_unconscious_target) and _reacting_unconscious_target._unconscious_helper_npc == self:
		_reacting_unconscious_target._unconscious_helper_npc = null
	_reacting_unconscious_target = null
	_unconscious_react_mode = ""
	_unconscious_react_phase = 0
	_unconscious_react_timer = 0.0
	_stop_crafting_bar()

func _process_unconscious_neighbor_reaction(delta: float) -> bool:
	if not is_instance_valid(_reacting_unconscious_target) or _unconscious_react_mode == "":
		return false
	var target: VillageNPC = _reacting_unconscious_target

	# MODO A: RIVAL OPORTUNISTA ("opportunist_steal") — Vigila que nadie esté viendo antes y durante el robo (4.0s)
	if _unconscious_react_mode == "opportunist_steal":
		if not target.is_unconscious_on_ground():
			_clear_unconscious_reaction_state()
			return false
		_witness_check_timer -= delta
		if _witness_check_timer <= 0.0:
			_witness_check_timer = 0.2
			_witness_check_cached = _has_any_witness_watching_opportunist(target)
		var watcher: Node2D = _witness_check_cached if is_instance_valid(_witness_check_cached) else null
		if watcher != null:
			target._unconscious_ignored_by[npc_name] = true
			_spawn_floating_text("😳👀 ¡Alguien está mirando! Mejor disimulo y me alejo de %s..." % target.npc_name, Color.ORANGE, -42.0)
			_clear_unconscious_reaction_state()
			return false
		if global_position.distance_to(target.global_position) > 22.0:
			_stop_crafting_bar()
			_move_towards_point(target.global_position, 52.0, delta)
			_finish_frame_movement(delta)
			return true
		velocity = Vector2.ZERO
		if sprite:
			sprite.flip_h = (target.global_position.x < global_position.x)
		_unconscious_react_timer += delta
		var rem_st: int = maxi(1, int(ceil(4.0 - _unconscious_react_timer)))
		_update_craft_bar_visual(clampf(_unconscious_react_timer / 4.0, 0.02, 1.0), "🕵️‍♂️💰 Robando a %s sin testigos (%ds)" % [target.npc_name, rem_st], Color(0.95, 0.76, 0.24, 0.95))
		trigger_action_animation(0.4)
		_finish_frame_movement(delta)
		if _unconscious_react_timer >= 4.0:
			var stolen_g: int = 0
			if target.personal_gold > 0:
				stolen_g = maxi(1, int(ceil(float(target.personal_gold) * 0.65)))
				target.personal_gold = maxi(0, target.personal_gold - stolen_g)
				personal_gold += stolen_g
			var stolen_item_id: String = ""
			for pk in target.pocket_items.keys():
				if str(pk) != "royal_safe_conduct" and int(target.pocket_items[pk]) > 0:
					if target.remove_pocket_item(str(pk), 1):
						add_pocket_item(str(pk), 1)
						stolen_item_id = str(pk)
						break
			target._unconscious_ignored_by[npc_name] = true
			add_thought("Aproveché que mi rival %s estaba inconsciente para robarle (+10)" % target.npc_name, 10.0)
			target.add_thought("Alguien me vació los bolsillos mientras estaba inconsciente (-14)", -14.0)
			target.modify_npc_relationship(self, -12, "Sospecha que le robó mientras estaba inconsciente en el suelo", true)
			var loot_desc: String = "%d Oro" % stolen_g if stolen_g > 0 else "sus bolsillos"
			if stolen_item_id != "":
				loot_desc += " + 1x %s" % stolen_item_id
			_spawn_floating_text("😏💰 ¡%s le robó %s a %s sin que nadie viera y lo dejó tirado!" % [npc_name, loot_desc, target.npc_name], Color.GOLD, -44.0)
			_clear_unconscious_reaction_state()
		return true

	# MODO B: AMIGO / FAMILIAR / AUTORIDAD ("friend_rescue") — Fase 1: Reanimar rápido (4.0s) -> Fase 2 y 3: Informar y colaborar con la Policía (6.0s)
	if _unconscious_react_mode == "friend_rescue":
		if _unconscious_react_phase == 1:
			if not target.is_unconscious_on_ground():
				_clear_unconscious_reaction_state()
				return false
			if global_position.distance_to(target.global_position) > 22.0:
				_stop_crafting_bar()
				_move_towards_point(target.global_position, 64.0, delta)
				_finish_frame_movement(delta)
				return true
			velocity = Vector2.ZERO
			if sprite:
				sprite.flip_h = (target.global_position.x < global_position.x)
			_unconscious_react_timer += delta
			var rem_fr: int = maxi(1, int(ceil(4.0 - _unconscious_react_timer)))
			_update_craft_bar_visual(clampf(_unconscious_react_timer / 4.0, 0.02, 1.0), "🤝⚡ Socorriendo a %s (%ds)" % [target.npc_name, rem_fr], Color(0.35, 0.96, 0.58, 0.95))
			trigger_action_animation(0.4)
			_finish_frame_movement(delta)
			if _unconscious_react_timer >= 4.0:
				_stop_crafting_bar()
				_unconscious_react_timer = 0.0
				target.wake_up_from_unconscious(self)
				# U2: el favor pesa más para quien lo recibe
				target.modify_npc_relationship(self, 8, "Lo socorrió y despertó rápidamente al hallarlo inconsciente", true)
				modify_npc_relationship(target, 3, "Lo socorrió y despertó rápidamente al hallarlo inconsciente", true)
				if trade_role in [TradeRole.SHERIFF, TradeRole.GUARD]:
					_spawn_floating_text("🚓⚡ ¡%s reanimó a %s y patrullará la zona del ataque!" % [npc_name, target.npc_name], Color.AQUA, -42.0)
					_patrol_search_target_npc = target
					_patrol_search_target_pos = target.global_position
					_patrol_search_timer = 28.0
					_clear_unconscious_reaction_state()
				else:
					_unconscious_react_phase = 2
					_spawn_floating_text("🤝🚨 ¡Ya estás despierto, %s! ¡Voy corriendo a avisar a la policía de este ataque!" % target.npc_name, Color.SPRING_GREEN, -42.0)
			return true

		var nearest_police: VillageNPC = _find_nearest_available_authority(true)
		var pol_dest: Vector2 = nearest_police.global_position if nearest_police != null else Vector2(886, 132)

		if _unconscious_react_phase == 2:
			if global_position.distance_to(pol_dest) > 26.0:
				_stop_crafting_bar()
				_move_towards_point(pol_dest, 62.0, delta)
				_finish_frame_movement(delta)
				return true
			velocity = Vector2.ZERO
			_unconscious_react_phase = 3
			_unconscious_react_timer = 0.0
			if nearest_police != null:
				nearest_police.is_sleeping = false
				if nearest_police.sprite:
					nearest_police.sprite.rotation_degrees = 0.0
			_spawn_floating_text("🗣️🚓 ¡Guardia! ¡Encontré a mi amigo %s inconsciente en el suelo!" % target.npc_name, Color.GOLD, -42.0)
			return true

		if global_position.distance_to(pol_dest) > 34.0:
			_stop_crafting_bar()
			_move_towards_point(pol_dest, 62.0, delta)
			_finish_frame_movement(delta)
			return true
		velocity = Vector2.ZERO
		if nearest_police != null:
			nearest_police.is_sleeping = false
			if nearest_police.sprite:
				nearest_police.sprite.rotation_degrees = 0.0
			nearest_police.hold_for_interview(self, 0.8)
			if sprite:
				sprite.flip_h = (nearest_police.global_position.x < global_position.x)
		_unconscious_react_timer += delta
		var rem_rep: int = maxi(1, int(ceil(6.0 - _unconscious_react_timer)))
		var p_label: String = nearest_police.npc_name if nearest_police != null else "la Guardia"
		_update_craft_bar_visual(clampf(_unconscious_react_timer / 6.0, 0.02, 1.0), "🗣️🚓 Colaborando con %s sobre ataque a %s (%ds)" % [p_label, target.npc_name, rem_rep], Color(0.42, 0.88, 1.0, 0.95))
		trigger_action_animation(0.4)
		_finish_frame_movement(delta)
		if _unconscious_react_timer >= 6.0:
			var rescued_ref: VillageNPC = target
			_clear_unconscious_reaction_state()
			_spawn_floating_text("📢🚓 ¡%s informó a %s del ataque a %s y dio pistas para patrullar la zona!" % [npc_name, p_label, rescued_ref.npc_name], Color.AQUA, -42.0)
			if nearest_police != null:
				nearest_police.start_missing_person_police_search(rescued_ref, self)
		return true

	# MODO C: VECINO NEUTRAL ("neutral_wake") — Despierta con cautela (7.0s) y sigue su rutina sin ir a la policía
	if not target.is_unconscious_on_ground():
		_clear_unconscious_reaction_state()
		return false
	if global_position.distance_to(target.global_position) > 22.0:
		_stop_crafting_bar()
		_move_towards_point(target.global_position, 48.0, delta)
		_finish_frame_movement(delta)
		return true
	velocity = Vector2.ZERO
	if sprite:
		sprite.flip_h = (target.global_position.x < global_position.x)
	_unconscious_react_timer += delta
	var rem_nw: int = maxi(1, int(ceil(7.0 - _unconscious_react_timer)))
	_update_craft_bar_visual(clampf(_unconscious_react_timer / 7.0, 0.02, 1.0), "🤨🤚 Despertando con cautela a %s (%ds)" % [target.npc_name, rem_nw], Color(0.75, 0.88, 1.0, 0.95))
	trigger_action_animation(0.4)
	_finish_frame_movement(delta)
	if _unconscious_react_timer >= 7.0:
		target.wake_up_from_unconscious(self)
		target.modify_npc_relationship(self, 3, "Le ayudó a despertarse cuando estaba tirado en el suelo", true)
		modify_npc_relationship(target, 1, "Le ayudó a despertarse cuando estaba tirado en el suelo", true)
		_spawn_floating_text("😮‍💨🤚 %s despertó a %s y continúa con su jornada." % [npc_name, target.npc_name], Color(0.78, 0.94, 1.0), -40.0)
		_clear_unconscious_reaction_state()
	return true

## V2: simulación simplificada lejos del jugador. Fuera de la vista, el vecino piensa y se mueve 1 de cada
## LOD_STEP fotogramas con el tiempo acumulado (llega igual de lejos, solo que a saltos que nadie ve).
const LOD_DIST: float = 360.0 # La cámara (zoom 3, 1280x720) ve unos 430x240; con margen
const LOD_STEP: int = 4
var _lod_acc: float = 0.0
var _lod_phase: int = -1
var _lod_tick: int = 0
var _lod_k: float = 1.0
## B3 (orden del usuario, 2026-11-06): apagado. Los vecinos lejanos viven siempre al detalle; medido: cuesta ~1 fps.
## Queda como opción por si algún día hace falta.
static var lod_enabled: bool = false

func _lod_far() -> bool:
	if not lod_enabled or is_hostile or is_in_live_fight() or is_busy_with_player():
		return false
	if trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.DOCTOR, TradeRole.ROYAL_INVESTIGATOR]:
		return false # Patrullas, urgencias e investigaciones: siempre al detalle
	if is_instance_valid(_cached_vm) and "player_elevation_level" in _cached_vm and int(_cached_vm.player_elevation_level) != elevation_level:
		return true # Bloque PQ: En otro piso o en el subsuelo respecto al jugador se simula en modo simplificado
	var pl: Node2D = _get_player()
	return pl != null and global_position.distance_squared_to(pl.global_position) > LOD_DIST * LOD_DIST

func _lod_step_for_npc() -> int:
	if is_instance_valid(_cached_vm) and "player_elevation_level" in _cached_vm and int(_cached_vm.player_elevation_level) != elevation_level:
		return LOD_STEP * 2
	var pl: Node2D = _get_player()
	if pl != null and global_position.distance_squared_to(pl.global_position) > (LOD_DIST * 2.0) * (LOD_DIST * 2.0):
		return LOD_STEP * 2
	return LOD_STEP

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_lod_k = 1.0
	if _lod_far():
		var cur_step: int = _lod_step_for_npc()
		if _lod_phase < 0:
			_lod_phase = randi() % cur_step
		_lod_acc += delta
		_lod_tick += 1
		if (_lod_tick + _lod_phase) % cur_step != 0:
			return
		_lod_k = _lod_acc / delta if delta > 0.0 else 1.0
		delta = _lod_acc
		_lod_acc = 0.0
	elif _lod_acc > 0.0:
		delta += _lod_acc # Vuelve al detalle: recupera el tiempo pendiente
		_lod_acc = 0.0
	if perf_on:
		_physics_process_timed(delta)
		return
	if _process_inactive_states(delta):
		return
	_tick_frame_upkeep(delta)
	_tick_self_tending(delta)
	if _process_player_attention(delta):
		return
	if is_in_live_fight() and not is_hostile:
		_process_live_fight(delta)
		return
	if _process_duties(delta):
		return
	if is_hostile:
		_process_hostile_combat(delta)
		_finish_frame_movement(delta)
		return
	_update_needs_and_decisions(delta)
	if _process_hospital_care(delta):
		return
	_execute_dynamic_activity(delta)
	_finish_frame_movement(delta, true)

## B3 (medición): cronómetro por partes, solo lo enciende `tools/tests/perf_breakdown.gd`. Mismo orden y mismas
## llamadas que arriba; no cambia nada del comportamiento.
static var perf_on: bool = false
static var perf_usec: Dictionary = {}

static func _perf_add(part: String, since: int) -> int:
	var now: int = Time.get_ticks_usec()
	perf_usec[part] = int(perf_usec.get(part, 0)) + (now - since)
	return now

func _physics_process_timed(delta: float) -> void:
	var t: int = Time.get_ticks_usec()
	var stop: bool = _process_inactive_states(delta)
	t = _perf_add("inactive_states", t)
	if stop:
		return
	_tick_frame_upkeep(delta)
	t = _perf_add("frame_upkeep", t)
	_tick_self_tending(delta)
	t = _perf_add("self_tending", t)
	stop = _process_player_attention(delta)
	t = _perf_add("player_attention", t)
	if stop:
		return
	if is_in_live_fight() and not is_hostile:
		_process_live_fight(delta)
		_perf_add("live_fight", t)
		return
	stop = _process_duties(delta)
	t = _perf_add("duties", t)
	if stop:
		return
	if is_hostile:
		_process_hostile_combat(delta)
		_finish_frame_movement(delta)
		_perf_add("hostile", t)
		return
	_update_needs_and_decisions(delta)
	t = _perf_add("needs_decisions", t)
	stop = _process_hospital_care(delta)
	t = _perf_add("hospital_care", t)
	if stop:
		return
	_execute_dynamic_activity(delta)
	t = _perf_add("dynamic_activity", t)
	_finish_frame_movement(delta, true)
	_perf_add("movement", t)

## Estados en los que el vecino no actúa: muerto, agonizando, inconsciente, aturdido, sentado al póker o tiempo congelado.
func _process_inactive_states(delta: float) -> bool:
	if is_dead:
		velocity = Vector2.ZERO
		_stop_crafting_bar()
		_process_corpse_state(delta)
		return true

	if is_downed:
		velocity = Vector2.ZERO
		_stop_crafting_bar()
		if not (WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen()):
			bleedout_timer -= delta
		var pulse_r: float = 0.65 + absf(sin(bleedout_timer * 4.0)) * 0.35
		_set_sprite_pose(82.0, Color(1.15, pulse_r * 0.45, pulse_r * 0.45, 0.95))
		_show_status_label("🩸 %s — ¡AGONIZANDO! (%ds)\n[E: Salvar y llevar al Hospital | Atacar: Rematar]" % [npc_name, maxi(1, int(ceil(bleedout_timer)))], Color(1.0, 0.35, 0.35))
		if bleedout_timer <= 0.0:
			_confirm_true_death()
		return true

	if sedated_timer > 0.0:
		if not (WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen()):
			sedated_timer -= delta
		velocity = Vector2.ZERO
		_stop_crafting_bar()
		is_sleeping = true
		if sprite:
			sprite.rotation_degrees = 90.0
		_scan_unconscious_victim_for_passersby(delta)
		var helper_tag: String = ""
		if is_instance_valid(_unconscious_helper_npc) and _unconscious_helper_npc._reacting_unconscious_target == self:
			if _unconscious_helper_npc._unconscious_react_mode == "opportunist_steal":
				helper_tag = "\n[🕵️‍♂️ %s vigila que nadie mire para robarle]" % _unconscious_helper_npc.npc_name
			elif _unconscious_helper_npc._unconscious_react_mode == "friend_rescue":
				helper_tag = "\n[🤝 %s corre a socorrerlo y despertarlo]" % _unconscious_helper_npc.npc_name
			else:
				helper_tag = "\n[🤨 %s se acerca a despertarlo]" % _unconscious_helper_npc.npc_name
		_show_status_label("💤 %s — Inconsciente / Dormido (%ds)%s%s" % [npc_name, maxi(1, int(ceil(sedated_timer))), _get_pocket_loot_hint(), helper_tag], Color(0.78, 0.65, 1.0))
		if sedated_timer <= 0.0:
			wake_up_from_unconscious()
		return true

	if is_stunned_flag:
		velocity = Vector2.ZERO
		_stop_crafting_bar()
		_scan_unconscious_victim_for_passersby(delta)
		_show_status_label("💫 %s — Aturdido%s" % [npc_name, _get_pocket_loot_hint()], Color(0.75, 0.85, 1.0))
		return true

	if is_at_poker_table:
		if poker_seat_pos != Vector2.ZERO and global_position.distance_to(poker_seat_pos) > 3.0:
			global_position = poker_seat_pos
		velocity = Vector2.ZERO
		_stop_crafting_bar()
		_update_visual_animation(delta)
		_update_hover_label()
		return true

	if WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen():
		velocity = Vector2.ZERO
		_update_hover_label()
		return true
	return false

## Temporizadores y comprobaciones que corren en cada fotograma si el vecino está activo.
func _tick_frame_upkeep(delta: float) -> void:
	if body_col:
		body_col.disabled = not is_hostile
	_get_vm()
	_get_player()
	if bloodstained_timer > 0.0:
		bloodstained_timer = maxf(0.0, bloodstained_timer - delta)
	if _npc_social_event_cooldown > 0.0:
		_npc_social_event_cooldown = maxf(0.0, _npc_social_event_cooldown - delta)
	if _pending_social_reply_timer > 0.0:
		_process_pending_social_reply(delta)
	if is_conscious():
		_update_visual_memory(delta)
	if health_comp and velocity.length_squared() > 9.0 and health_comp.is_resting_in_bed and global_position.distance_to(Vector2(718, 136)) > 26.0 and global_position.distance_to(bed_position) > 20.0:
		health_comp.is_resting_in_bed = false
	if not is_instance_valid(_cached_dm) and get_tree().current_scene:
		_cached_dm = get_tree().current_scene.get_node_or_null("Systems/dialogue_manager")

## Auto-cura de supervivencia (RimWorld Self-Tend): fuera de combate, si sangra se aplica un vendaje o torniquete rudimentario.
func _tick_self_tending(delta: float) -> void:
	if not is_hostile and health_comp and health_comp.get_total_wound_bleed_rate() > 0.0:
		_self_tend_timer += delta
		if _self_tend_timer >= 3.5:
			_self_tend_timer = 0.0
			var urg_wid: int = health_comp.get_most_urgent_untreated_wound_id(true)
			if urg_wid != -1:
				if remove_pocket_item("bandage", 1):
					health_comp.treat_wound(urg_wid, "bandage")
					_spawn_floating_text("🩹 %s se vendó su herida sangrante" % npc_name, Color.SPRING_GREEN, -38.0)
				else:
					health_comp.treat_wound(urg_wid, "tend_makeshift")
					_spawn_floating_text("🖐️🩹 %s se aplicó un torniquete rudimentario (Calidad 25%%)" % npc_name, Color(0.95, 0.80, 0.42), -38.0)
	else:
		_self_tend_timer = 0.0

## Se detiene y mira al jugador mientras habla con él o a quien lo interroga.
func _process_player_attention(delta: float) -> bool:
	var talking_to_player: bool = not is_hostile and is_instance_valid(_cached_dm) and bool(_cached_dm.get("active")) and _cached_dm.get("current_speaker") == self
	if talking_to_player or (_being_interviewed_timer > 0.0 and not is_hostile):
		if not talking_to_player:
			_being_interviewed_timer = maxf(0.0, _being_interviewed_timer - delta)
		velocity = Vector2.ZERO
		_stop_crafting_bar()
		var face_node: Node2D = _cached_player if talking_to_player else _interviewer_node
		if is_instance_valid(face_node) and sprite:
			sprite.flip_h = (face_node.global_position.x < global_position.x)
		trigger_action_animation(0.4)
		_update_visual_animation(delta)
		_update_hover_label(delta)
		return true
	return false

## Obligaciones por orden de prioridad: escolta, urgencias, emergencias vecinales, policía, investigación y ruta comercial.
func _process_duties(delta: float) -> bool:
	var vm_escort = _cached_vm
	if vm_escort and bool(vm_escort.get("player_being_escorted_to_jail")) and vm_escort.get("escorting_officer") == self:
		var jail_target: Vector2 = vm_escort.get("_jail_cell_pos") if "_jail_cell_pos" in vm_escort else Vector2(886, 172)
		_move_towards_point(jail_target, 64.0, delta)
		_finish_frame_movement(delta)
		return true

	if _process_doctor_duty(delta):
		return true

	if not is_hostile and (_process_witness_corpse_reporting(delta) or _process_corpse_morgue_transport(delta) or _process_family_missing_search(delta) or _process_unconscious_neighbor_reaction(delta)):
		return true

	if _process_police_duty(delta):
		return true

	if trade_role == TradeRole.ROYAL_INVESTIGATOR:
		if is_hostile:
			_police_alerted_timer = maxf(_police_alerted_timer, 25.0)
			if is_instance_valid(_cached_player):
				_last_seen_player_pos = _cached_player.global_position
		_process_royal_investigator_ai(delta)
		return true

	if trade_role == TradeRole.TRAVELING_MERCHANT and not is_hostile:
		_process_traveling_merchant_routine(delta)
		return true

	# Bloque PH: Si este vecino es el acompañante activo del jugador, camina a su lado durante el día
	if not is_hostile and vm_escort != null and "VillageFame" in vm_escort and vm_escort.VillageFame != null and vm_escort.VillageFame.is_companion(vm_escort, self):
		var h_comp: int = int(WorldClock.current_hour) if WorldClock != null else 12
		if h_comp >= 6 and h_comp < 22 and need_hunger > 25.0 and need_energy > 15.0 and is_instance_valid(_cached_player):
			_stop_crafting_bar()
			_approach_or_stop(_cached_player.global_position + Vector2(-22, 14), 24.0, 56.0, delta)
			_finish_frame_movement(delta)
			return true
	return false

## El médico atiende primero a los agonizantes y luego a sus pacientes del hospital.
func _process_doctor_duty(delta: float) -> bool:
	if trade_role == TradeRole.DOCTOR and not is_hostile:
		_doctor_scan_timer -= delta
		if not is_instance_valid(_active_downed_patient) or not _active_downed_patient.is_downed or _active_downed_patient.is_dead:
			_active_downed_patient = null
			if _doctor_scan_timer <= 0.0:
				_doctor_scan_timer = 0.25
				_active_downed_patient = _find_downed_npc()
		if _active_downed_patient != null:
			_stop_crafting_bar()
			if global_position.distance_to(_active_downed_patient.global_position) > 22.0:
				_move_towards_point(_active_downed_patient.global_position, 68.0 * lerpf(0.72, 1.0, get_job_efficiency()), delta)
				_finish_frame_movement(delta)
			else:
				_active_downed_patient.revive_from_downed(self, false)
				_spawn_floating_text("🩺 ¡%s trasladó a %s a la camilla de urgencias!" % [npc_name, _active_downed_patient.npc_name], Color.SPRING_GREEN, -42.0)
				_active_hospital_patient = _active_downed_patient
				_active_downed_patient = null
			return true
		if _process_doctor_hospital_treatment(delta):
			_finish_frame_movement(delta)
			return true
	return false

## Policía: aplicar la ley, investigar y buscar desaparecidos.
func _process_police_duty(delta: float) -> bool:
	if trade_role in [TradeRole.SHERIFF, TradeRole.GUARD]:
		var vm = _cached_vm
		if vm and (int(vm.get("wanted_level")) > 0 or bool(vm.get("is_resisting_arrest")) or is_hostile) and not bool(vm.get("player_in_jail")) and not bool(vm.get("player_being_escorted_to_jail")):
			if _process_police_law_enforcement(delta, vm):
				return true
		if trade_role == TradeRole.SHERIFF and vm and "active_sheriff_investigation" in vm and bool(vm.active_sheriff_investigation.get("active", false)):
			if vm.has_method("update_sheriff_investigator_ai"):
				vm.call("update_sheriff_investigator_ai", self, delta)
				_finish_frame_movement(delta, true)
				return true
		if not is_hostile and _process_police_missing_person_patrol(delta):
			return true
	return false

## Si está herido o enfermo, va a la cama del hospital y descansa allí.
func _process_hospital_care(delta: float) -> bool:
	var needs_hospital_care: bool = false
	if health_comp and need_hunger > 5.0 and trade_role != TradeRole.DOCTOR:
		if health_comp.current_blood >= 22.0 or health_comp.get_most_urgent_untreated_wound_id(false) != -1:
			needs_hospital_care = true
		elif health_comp.current_health < health_comp.get_effective_max_health() * 0.78:
			needs_hospital_care = true
		elif health_comp.fever >= 35.0 or health_comp.food_poisoning >= 40.0 or health_comp.swamp_sickness >= 40.0 or health_comp.get_max_wound_infection() >= 25.0:
			needs_hospital_care = true
		elif health_comp.has_active_sickness_or_infection() and global_position.distance_to(Vector2(718, 136)) <= 24.0:
			needs_hospital_care = true

	if needs_hospital_care:
		if is_sleeping:
			is_sleeping = false
			if sprite:
				sprite.rotation_degrees = 0.0
		_stop_crafting_bar()
		var hosp_bed_pos := Vector2(718, 136)
		if global_position.distance_to(hosp_bed_pos) > 18.0:
			_move_towards_point(hosp_bed_pos, 46.0, delta)
		else:
			velocity = Vector2.ZERO
			health_comp.is_resting_in_bed = true
			# Solo recupera resistencia física gradualmente si ya no tiene heridas abiertas sangrando
			if health_comp.get_total_wound_bleed_rate() <= 0.0 and not health_comp.is_bleeding:
				health_comp.heal(1.8 * delta)
		_finish_frame_movement(delta)
		return true
	return false

## Gestiona un cadáver en el suelo o en la Morgue: se pudre con el paso de las horas/días hasta que otro NPC lo vea en su rutina natural (con línea de visión)
## o el jugador lo reporte con [E]. En la Morgue conserva sus bolsillos y órganos hasta que el caso se resuelva/archive y sea sepultado.
func _process_corpse_state(delta: float) -> void:
	if corpse_buried:
		return
	if corpse_in_morgue:
		if status_label:
			var player_m = _get_player()
			var near_pm: bool = player_m != null and global_position.distance_squared_to(player_m.global_position) <= 42.0 * 42.0
			var near_mm: bool = global_position.distance_squared_to(get_global_mouse_position()) <= 26.0 * 26.0
			if near_pm or near_mm:
				var loot_m: String = _get_pocket_loot_hint(true)
				var act_hint: String = loot_m if loot_m != "" else " | [E: Informe Forense]"
				_show_status_label("⚰️ Cadáver en Morgue: %s (%s)\n[En Camilla Forense%s | H: Examinar Cuerpo / Órganos]" % [npc_name, npc_role, act_hint], Color(0.68, 0.96, 0.90))
			else:
				status_label.visible = false
		return
	if not corpse_on_ground:
		return

	if corpse_being_carried:
		if is_instance_valid(corpse_carrier) and corpse_carrier.is_conscious() and not corpse_carrier.is_hostile:
			global_position = corpse_carrier.global_position + Vector2(0, -8)
		else:
			if is_instance_valid(corpse_carrier) and corpse_carrier._carrying_corpse_target == self:
				corpse_carrier._carrying_corpse_target = null
			corpse_being_carried = false
			corpse_carrier = null
	else:
		corpse_rot_hours += delta / 65.0

	if sprite:
		sprite.visible = true
		var rot_col: Color = Color(0.68, 0.54, 0.54, 0.96) if corpse_rot_hours < 12.0 else (Color(0.54, 0.60, 0.46, 0.96) if corpse_rot_hours < 24.0 else Color(0.38, 0.56, 0.30, 0.96))
		_set_sprite_pose(90.0, rot_col)

	_corpse_scan_timer -= delta
	if _corpse_scan_timer > 0.0:
		return
	_corpse_scan_timer = 0.25

	var vm = _get_vm()
	if not corpse_reported:
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC and n != self and (n as VillageNPC).is_conscious():
				var other := n as VillageNPC
				if other.trade_role in [TradeRole.ROYAL_INVESTIGATOR, TradeRole.TRAVELING_MERCHANT]:
					continue
				if other.witness_silenced_player and last_hit_by_player:
					continue
				if is_instance_valid(other._reporting_corpse_target) and other._reporting_corpse_target.is_dead and not other._reporting_corpse_target.corpse_reported:
					continue
				if other.global_position.distance_to(global_position) <= 95.0 and ((vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", other.global_position, global_position))):
					if not is_instance_valid(corpse_reporter_npc) or not corpse_reporter_npc.is_conscious() or corpse_reporter_npc._reporting_corpse_target != self:
						begin_physical_corpse_discovery(other)
						break

	if status_label:
		var player = _get_player()
		var near_p: bool = player != null and global_position.distance_squared_to(player.global_position) <= 44.0 * 44.0
		var near_m: bool = global_position.distance_squared_to(get_global_mouse_position()) <= 28.0 * 28.0
		if near_p or near_m or corpse_being_carried:
			var rot_days: int = int(floor(corpse_rot_hours / 24.0))
			var rot_rem_h: int = int(floor(corpse_rot_hours)) % 24
			var loot_tag: String = _get_pocket_loot_hint(true)
			var state_line: String = ("🩸 Cadáver en el suelo (%dh)%s | [E: 📢 Reportar Cadáver]" % [rot_rem_h, loot_tag]) if rot_days < 1 else ("🦠🪰 PUDRIÉNDOSE EN EL LUGAR (%d días, %dh)%s | [E: 📢 Reportar Cadáver]" % [rot_days, rot_rem_h, loot_tag])
			if corpse_being_carried and is_instance_valid(corpse_carrier):
				state_line = "⚰️ Trasladando cuerpo a la Morgue (Llevado por %s)%s" % [corpse_carrier.npc_name, loot_tag]
			elif corpse_reported:
				state_line = "🚨 Reportado por %s — En espera de traslado a la Morgue%s" % [corpse_discovered_by, loot_tag]
			elif corpse_discovered and is_instance_valid(corpse_reporter_npc):
				var r_phase: int = corpse_reporter_npc._corpse_report_phase
				if r_phase == 1:
					state_line = "🔍 %s comprueba si está muerto (10s)%s | [E: 📢 Reportar]" % [corpse_reporter_npc.npc_name, loot_tag]
				elif r_phase == 3:
					state_line = "🗣️ %s está explicando el hallazgo a la policía%s" % [corpse_reporter_npc.npc_name, loot_tag]
				else:
					state_line = "🏃 %s va en persona a avisar a la policía%s | [E: 📢 Reportar]" % [corpse_reporter_npc.npc_name, loot_tag]
			_show_status_label("💀 Cadáver de %s (%s)\n[%s]" % [npc_name, npc_role, state_line], Color(0.72, 0.96, 0.62) if rot_days >= 1 else Color(0.92, 0.55, 0.55))
		else:
			status_label.visible = false

## Inicia el proceso físico en 3 fases para quien descubre un cuerpo:
## 1) Acercarse y comprobar durante 10s si está muerto -> 2) Caminar personalmente a buscar a la policía -> 3) Explicar durante 12.5s lo sucedido
func begin_physical_corpse_discovery(discoverer: VillageNPC) -> void:
	if discoverer == null or not is_dead or corpse_reported or corpse_in_morgue:
		return
	if is_instance_valid(discoverer._reporting_corpse_target) and discoverer._reporting_corpse_target.is_dead and not discoverer._reporting_corpse_target.corpse_reported:
		if not corpse_discovered:
			corpse_discovered = true
			corpse_discovered_by = discoverer.npc_name
		return
	if not corpse_discovered:
		corpse_discovered = true
		corpse_discovered_by = discoverer.npc_name
		discoverer.add_thought("Descubrió el cuerpo de %s (-15)" % npc_name, -15.0)
	corpse_reporter_npc = discoverer
	discoverer._clear_unconscious_reaction_state()
	discoverer._reporting_corpse_target = self
	discoverer._corpse_report_phase = 1
	discoverer._corpse_report_timer = 0.0
	_spawn_floating_text("😟❓ ¡%s vio a %s tendido y se acerca a comprobar si está muerto!" % [discoverer.npc_name, npc_name], Color.GOLD, -42.0)

## Cuando un testigo termina de reportar un cadáver a la policía, también quedan reportados otros cadáveres de la misma escena (<= 165 px)
func _report_nearby_corpses_from_same_scene(primary_corpse: VillageNPC) -> void:
	if not is_instance_valid(primary_corpse) or not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != primary_corpse and n != self:
			var c := n as VillageNPC
			if c.is_dead and c.corpse_on_ground and not c.corpse_in_morgue and not c.corpse_reported:
				if c.global_position.distance_to(primary_corpse.global_position) <= 165.0:
					c.corpse_discovered = true
					if c.corpse_discovered_by == "":
						c.corpse_discovered_by = npc_name
					c.corpse_reported = true
					c.corpse_reporter_npc = null
					c._notify_corpse_reported_to_authorities()

## Borra al jugador de la memoria visual de este testigo y detiene cualquier reporte activo si fue convencido, sobornado o intimidado
func clear_witness_memories_of_player() -> void:
	witness_silenced_player = true
	for i in range(seen_entities_memory.size() - 1, -1, -1):
		if str(seen_entities_memory[i].get("name", "")) == "Jugador" or bool(seen_entities_memory[i].get("is_player", false)):
			seen_entities_memory.remove_at(i)
	if is_instance_valid(_reporting_corpse_target):
		if _reporting_corpse_target.corpse_reporter_npc == self:
			_reporting_corpse_target.corpse_reporter_npc = null
		_reporting_corpse_target = null
	_corpse_report_phase = 0
	_corpse_report_timer = 0.0
	_stop_crafting_bar()
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC and (n as VillageNPC).murder_witness_name == npc_name:
				(n as VillageNPC).murder_witness_name = ""
	var vm = _get_vm()
	if vm and "sighting_log" in vm and typeof(vm.sighting_log) == TYPE_ARRAY:
		var s_arr: Array = vm.sighting_log
		for idx in range(s_arr.size() - 1, -1, -1):
			if typeof(s_arr[idx]) == TYPE_DICTIONARY and str(s_arr[idx].get("witness_name", "")) == npc_name:
				s_arr.remove_at(idx)

## Notifica a las autoridades (y a la Corona si el cadáver reportado es un Mercader Viajero) recién cuando el testigo termina de explicarlo a la policía
func _notify_corpse_reported_to_authorities() -> void:
	var vm = _get_vm()
	if trade_role == TradeRole.TRAVELING_MERCHANT:
		if vm and vm.has_method("on_traveling_merchant_murdered"):
			vm.call("on_traveling_merchant_murdered", self, last_hit_weapon_name)
	elif vm and vm.has_method("on_civilian_corpse_reported"):
		vm.call("on_civilian_corpse_reported", self, death_world_pos if death_world_pos != Vector2.ZERO else global_position, last_hit_weapon_name, corpse_discovered_by)

## Permite al jugador reportar manualmente un cadáver con [E] (Estilo Among Us / Hitman / Streets of Rogue)
func report_corpse_by_player(player: Node) -> bool:
	if not is_dead or not corpse_on_ground or corpse_in_morgue:
		return false
	if corpse_reported:
		if player and player.has_method("_spawn_floating_text"):
			player.call("_spawn_floating_text", "🚨 El cadáver de %s ya fue reportado a las autoridades" % npc_name, Color.GOLD, -40.0)
		return true
	corpse_discovered = true
	if corpse_discovered_by == "":
		corpse_discovered_by = "Jugador (Reporte Ciudadano)"
	corpse_reported = true
	corpse_reporter_npc = null
	_notify_corpse_reported_to_authorities()
	_spawn_floating_text("📢 ¡Reportaste el cadáver de %s! El Dr. Valen / la guardia acudirá a recogerlo." % npc_name, Color.GOLD, -44.0)
	if player and player.has_method("_spawn_floating_text"):
		player.call("_spawn_floating_text", "📢 Cadáver de %s reportado al Hospital y Comisaría" % npc_name, Color.AQUA, -36.0)
	return true

## Un testigo que descubrió un cadáver cumple físicamente 3 fases sin telepatía ni instantaneidad:
## Fase 1 (10.0s): Camina hasta el cuerpo y se agacha 10s a comprobar si realmente está muerto.
## Fase 2: Camina personalmente por las calles en busca del Comisario/Guardia (o Médico/Comisaría).
## Fase 3 (12.5s): Se detiene frente al policía y pasa 12.5s explicándole lo ocurrido antes de que se active la alerta.
func _process_witness_corpse_reporting(delta: float) -> bool:
	if not is_instance_valid(_reporting_corpse_target):
		_corpse_report_phase = 0
		_corpse_report_timer = 0.0
		return false
	var corpse_to_report: VillageNPC = _reporting_corpse_target
	if not corpse_to_report.is_dead or not corpse_to_report.corpse_on_ground or corpse_to_report.corpse_in_morgue or corpse_to_report.corpse_reported or corpse_to_report.corpse_reporter_npc != self:
		_reporting_corpse_target = null
		_corpse_report_phase = 0
		_corpse_report_timer = 0.0
		_stop_crafting_bar()
		return false

	if _corpse_report_phase <= 0:
		_corpse_report_phase = 1
		_corpse_report_timer = 0.0

	# FASE 1: Acercarse al cuerpo y pasar 10.0 segundos investigando si la persona está muerta
	if _corpse_report_phase == 1:
		var dist_to_body: float = global_position.distance_to(corpse_to_report.global_position)
		if dist_to_body > 22.0:
			_stop_crafting_bar()
			_move_towards_point(corpse_to_report.global_position, 54.0, delta)
			_finish_frame_movement(delta)
			return true
		velocity = Vector2.ZERO
		if sprite:
			sprite.flip_h = (corpse_to_report.global_position.x < global_position.x)
		_corpse_report_timer += delta
		var rem_chk: int = maxi(1, int(ceil(10.0 - _corpse_report_timer)))
		_update_craft_bar_visual(clampf(_corpse_report_timer / 10.0, 0.02, 1.0), "🔍 Comprobando pulso (%ds)" % rem_chk, Color(0.95, 0.78, 0.30, 0.95))
		trigger_action_animation(0.4)
		_finish_frame_movement(delta)
		if _corpse_report_timer >= 10.0:
			_stop_crafting_bar()
			_corpse_report_timer = 0.0
			if trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.DOCTOR]:
				corpse_to_report.corpse_reported = true
				corpse_to_report.corpse_reporter_npc = null
				_reporting_corpse_target = null
				_corpse_report_phase = 0
				_spawn_floating_text("🚨 ¡%s examinó el cuerpo y confirmó la muerte de %s!" % [npc_name, corpse_to_report.npc_name], Color.ORANGE_RED, -42.0)
				corpse_to_report._notify_corpse_reported_to_authorities()
				_report_nearby_corpses_from_same_scene(corpse_to_report)
			else:
				_corpse_report_phase = 2
				_spawn_floating_text("😱💀 ¡No respira, está muerto! ¡Voy en persona a avisar a la policía!", Color.ORANGE_RED, -42.0)
		return true

	# Buscar al policía consciente más cercano (o despertarlo en la Comisaría si es de noche)
	var nearest_authority: VillageNPC = _find_nearest_available_authority(true)
	var report_dest: Vector2 = nearest_authority.global_position if nearest_authority != null else Vector2(886, 172)

	# FASE 2: Caminar personalmente hasta donde está la policía
	if _corpse_report_phase == 2:
		if global_position.distance_to(report_dest) > 26.0:
			_stop_crafting_bar()
			_move_towards_point(report_dest, 58.0, delta)
			_finish_frame_movement(delta)
			return true
		velocity = Vector2.ZERO
		_corpse_report_phase = 3
		_corpse_report_timer = 0.0
		if nearest_authority != null:
			nearest_authority.is_sleeping = false
			if nearest_authority.sprite:
				nearest_authority.sprite.rotation_degrees = 0.0
		_spawn_floating_text("🗣️🚓 ¡Guardia, escúcheme! ¡He encontrado a %s muerto!" % corpse_to_report.npc_name, Color.GOLD, -42.0)
		return true

	# FASE 3: Explicar durante 12.5 segundos a la policía lo que pasó
	if global_position.distance_to(report_dest) > 34.0:
		_stop_crafting_bar()
		_move_towards_point(report_dest, 58.0, delta)
		_finish_frame_movement(delta)
		return true

	velocity = Vector2.ZERO
	if nearest_authority != null:
		nearest_authority.is_sleeping = false
		if nearest_authority.sprite:
			nearest_authority.sprite.rotation_degrees = 0.0
		nearest_authority.hold_for_interview(self, 0.6)
		if sprite:
			sprite.flip_h = (nearest_authority.global_position.x < global_position.x)
	_corpse_report_timer += delta
	var rem_exp: int = maxi(1, int(ceil(12.5 - _corpse_report_timer)))
	var auth_name: String = nearest_authority.npc_name if nearest_authority != null else "la Comisaría"
	_update_craft_bar_visual(clampf(_corpse_report_timer / 12.5, 0.02, 1.0), "🗣️ Explicando a %s (%ds)" % [auth_name, rem_exp], Color(1.0, 0.56, 0.28, 0.95))
	trigger_action_animation(0.4)
	_finish_frame_movement(delta)
	if _corpse_report_timer >= 12.5:
		_stop_crafting_bar()
		corpse_to_report.corpse_reported = true
		corpse_to_report.corpse_reporter_npc = null
		_reporting_corpse_target = null
		_corpse_report_phase = 0
		_corpse_report_timer = 0.0
		_spawn_floating_text("📢 ¡%s terminó de explicar el hallazgo de %s a %s!" % [npc_name, corpse_to_report.npc_name, auth_name], Color.GOLD, -42.0)
		if nearest_authority != null:
			nearest_authority._spawn_floating_text("🚓📋 Entendido. Aseguraremos el cuerpo e investigaremos la escena.", Color.AQUA, -38.0)
		corpse_to_report._notify_corpse_reported_to_authorities()
		_report_nearby_corpses_from_same_scene(corpse_to_report)
	return true

## Recoge físicamente un cadáver YA REPORTADO (`corpse_reported == true`) y camina con él por las puertas y calles hasta depositarlo en la Morgue
func _process_corpse_morgue_transport(delta: float) -> bool:
	var target_corpse: VillageNPC = null
	if is_instance_valid(_carrying_corpse_target) and _carrying_corpse_target.is_dead and _carrying_corpse_target.corpse_on_ground and not _carrying_corpse_target.corpse_in_morgue:
		target_corpse = _carrying_corpse_target if (not _carrying_corpse_target.corpse_being_carried or _carrying_corpse_target.corpse_carrier == self) else null
		_carrying_corpse_target = target_corpse

	if target_corpse == null:
		_corpse_scan_timer -= delta
		if _corpse_scan_timer > 0.0:
			return false
		_corpse_scan_timer = 0.45
		var can_be_carrier: bool = (trade_role in [TradeRole.DOCTOR, TradeRole.GUARD, TradeRole.SHERIFF])
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC and n != self:
				var c := n as VillageNPC
				if c.is_dead and c.corpse_on_ground and not c.corpse_in_morgue and c.corpse_reported:
					if (c.corpse_being_carried and c.corpse_carrier == self) or (not c.corpse_being_carried and (can_be_carrier or (not _is_doctor_conscious_and_free() and c.corpse_discovered_by == npc_name))):
						target_corpse = c
						_carrying_corpse_target = c
						break

	if target_corpse == null:
		return false

	var vm_carry = _cached_vm
	var morgue_has_space: bool = (vm_carry == null) or (not vm_carry.has_method("has_free_morgue_table")) or bool(vm_carry.call("has_free_morgue_table"))
	var dest_label: String = "la Morgue" if morgue_has_space else "el Cementerio Parroquial (Morgue llena)"
	if not target_corpse.corpse_being_carried:
		if global_position.distance_to(target_corpse.global_position) > 24.0:
			_move_towards_point(target_corpse.global_position, 66.0, delta)
			_finish_frame_movement(delta)
			return true
		target_corpse.corpse_being_carried = true
		target_corpse.corpse_carrier = self
		_carrying_corpse_target = target_corpse
		_spawn_floating_text("⚰️ %s recoge el cadáver de %s hacia %s" % [npc_name, target_corpse.npc_name, dest_label], Color.AQUA, -42.0)

	var target_drop_pos := Vector2(745, 174)
	if not morgue_has_space and vm_carry and vm_carry.has_method("get_cemetery_burial_target_pos"):
		target_drop_pos = vm_carry.call("get_cemetery_burial_target_pos")
	target_corpse.global_position = global_position + Vector2(0, -8)
	if global_position.distance_to(target_drop_pos) > 22.0:
		_move_towards_point(target_drop_pos, 60.0, delta)
		_finish_frame_movement(delta)
		return true
	velocity = Vector2.ZERO
	target_corpse.corpse_on_ground = false
	target_corpse.corpse_being_carried = false
	target_corpse.corpse_in_morgue = true
	target_corpse.corpse_buried = not morgue_has_space
	target_corpse.corpse_carrier = null
	target_corpse.global_position = target_drop_pos
	if target_corpse.sprite:
		target_corpse.sprite.visible = false
	if target_corpse.status_label:
		target_corpse.status_label.visible = false
	target_corpse._stop_crafting_bar()
	# Mientras el cuerpo esté en una camilla de la Morgue (`not corpse_buried`), mantiene su área interactiva activa para poder saquear sus bolsillos o extraer órganos con [E] / [H]
	target_corpse._set_area_col_disabled(target_corpse.interact_area, target_corpse.corpse_buried)
	_carrying_corpse_target = null
	var vm = _cached_vm
	if vm and vm.has_method("register_npc_death_and_corpse"):
		vm.call("register_npc_death_and_corpse", target_corpse, target_corpse.death_world_pos, target_corpse.last_hit_weapon_name, target_corpse.last_hit_by_player, target_corpse.corpse_discovered_by, target_corpse.corpse_rot_hours)
	_spawn_floating_text(("⚰️ Cuerpo de %s depositado en la Morgue Forense" if not target_corpse.corpse_buried else "🪦 Cuerpo de %s sepultado en el Cementerio de la Iglesia") % target_corpse.npc_name, Color.AQUA if not target_corpse.corpse_buried else Color(0.85, 0.78, 0.95), -44.0)
	return true

func _is_doctor_conscious_and_free() -> bool:
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and (n as VillageNPC).trade_role == TradeRole.DOCTOR and (n as VillageNPC).is_conscious():
			return true
	return false

## IA Policial: 1º Negociar (si no se resiste), 2º Si se resiste -> Persecución con Pistola a distancia y Porra cuerpo a cuerpo, con Línea de Visión
func _process_police_law_enforcement(delta: float, vm: Node) -> bool:
	var player = _cached_player
	if not is_instance_valid(player):
		return false

	var dist_p: float = global_position.distance_to(player.global_position)
	var in_stealth: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
	var cloak_mult: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
	var eff_pol: float = get_job_efficiency()
	var detect_range: float = (95.0 if in_stealth else 235.0) * cloak_mult * lerpf(0.68, 1.0, eff_pol) * get_sleep_vision_multiplier()
	var can_see_player: bool = (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", global_position, player.global_position))

	if can_see_player and dist_p <= detect_range:
		_police_alerted_timer = 5.5
		_last_seen_player_pos = player.global_position
	elif _police_alerted_timer > 0.0:
		_police_alerted_timer -= delta
	if _police_alerted_timer <= 0.0:
		return false

	var resisting: bool = bool(vm.get("is_resisting_arrest")) or is_hostile
	var target_pt: Vector2 = player.global_position if can_see_player else _last_seen_player_pos
	var spd_mult: float = lerpf(0.78, 1.0, eff_pol)

	if not resisting:
		if can_see_player and dist_p <= 34.0:
			velocity = Vector2.ZERO
			if vm.has_method("trigger_police_confrontation"):
				vm.call("trigger_police_confrontation", self)
		else:
			_move_towards_point(target_pt, 86.0 * spd_mult, delta)
			move_and_slide()
		_update_visual_animation(delta)
		_update_hover_label(delta)
		return true

	if _stagger_timer > 0.0:
		_stagger_timer = maxf(0.0, _stagger_timer - delta)
		_police_baton_windup_timer = 0.0
		velocity = Vector2.ZERO
		if _stagger_timer <= 0.0 and sprite:
			sprite.modulate = Color.WHITE
		_finish_frame_movement(delta)
		return true

	if _melee_recover_timer > 0.0:
		_melee_recover_timer = maxf(0.0, _melee_recover_timer - delta)
		velocity = Vector2.ZERO
		_finish_frame_movement(delta)
		return true
	if _police_baton_windup_timer > 0.0:
		_police_baton_windup_timer = maxf(0.0, _police_baton_windup_timer - delta)
		velocity = Vector2.ZERO
		if _police_baton_windup_timer <= 0.0:
			_attack_timer = 0.85 / maxf(0.55, eff_pol)
			if sprite:
				sprite.modulate = Color.WHITE
			_CombatFeel.enemy_swing(self, "porra")
			if is_instance_valid(player) and global_position.distance_to(player.global_position) <= 38.0:
				_strike_police_baton(player)
				_melee_recover_timer = float(_CombatFeel.attack_feel("porra")["recover"])
			else:
				_melee_recover_timer = float(_CombatFeel.attack_feel("porra")["miss_recover"])
		_finish_frame_movement(delta)
		return true

	_attack_timer = maxf(0.0, _attack_timer - delta)
	if can_see_player and dist_p <= 36.0:
		if dist_p > 22.0:
			_move_towards_point(player.global_position, 96.0 * spd_mult, delta)
		else:
			velocity = Vector2.ZERO
		if _attack_timer <= 0.0:
			_police_baton_windup_timer = 0.40
			trigger_action_animation(0.45)
			if sprite:
				sprite.modulate = Color(1.35, 0.9, 0.45)
			_spawn_floating_text("❗", Color.ORANGE_RED, -36.0)
	elif can_see_player and dist_p <= 195.0:
		_move_towards_point(player.global_position, (96.0 if is_disarmed() else 82.0) * spd_mult, delta)
		if _attack_timer <= 0.0 and not is_disarmed():
			_attack_timer = 1.25 / maxf(0.55, eff_pol)
			_fire_police_pistol(player)
	else:
		_move_towards_point(target_pt, 96.0 * spd_mult, delta)

	_finish_frame_movement(delta)
	return true

func _strike_police_baton(player: Node2D) -> void:
	if not player or not player.has_method("take_damage"):
		return
	var eff: float = get_job_efficiency()
	var unarmed: bool = is_disarmed() # C7 fase 4c: sin porra, a puñetazos
	var d := DamageData.new()
	d.amount = (8.0 if unarmed else 14.0) * eff
	d.type = CombatConstants.DamageType.BLUNT
	d.stun_buildup = (14.0 if unarmed else 36.0) * eff
	d.weapon_tag = ("Puñetazo de " + npc_name) if unarmed else "Porra Policial"
	d.knockback_force = float(_CombatFeel.attack_feel("porra")["push"])
	d.source = self
	player.call("take_damage", d)
	_spawn_floating_text("🏏 ¡Porrazo Policial!", Color.AQUA, -40.0)

func _fire_police_pistol(player: Node2D) -> void:
	if not player or not player.has_method("take_damage"):
		return
	_spawn_shot_tracer(player.global_position, Color(1.0, 0.88, 0.32, 0.95), 2.2, 18, -6.0, 0.18)
	var eff: float = get_job_efficiency()
	var d := DamageData.new()
	d.amount = 16.0 * eff
	d.type = CombatConstants.DamageType.CUT
	d.bleed_buildup = 20.0 * eff
	d.weapon_tag = "Pistola Policial"
	d.is_ranged_projectile = true
	d.source = self
	player.call("take_damage", d)
	_spawn_floating_text("🔫 ¡Disparo Policial!", Color(1.0, 0.82, 0.28), -42.0)

func _find_downed_npc() -> VillageNPC:
	var vm = _cached_vm
	var hosp_rect := Rect2(704, 110, 82, 80)
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != self:
			var v: VillageNPC = n as VillageNPC
			if v.is_downed and not v.is_dead:
				if hosp_rect.has_point(v.global_position) or (global_position.distance_to(v.global_position) <= 115.0 and ((vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", global_position, v.global_position)))):
					return v
	return null

## Memoria visual orgánica de cada habitante: recuerda a las últimas personas que vio pasar cerca con línea de visión
func _update_visual_memory(delta: float) -> void:
	_visual_memory_timer -= delta
	if _visual_memory_timer > 0.0:
		return
	_visual_memory_timer = 1.25
	var vm = _cached_vm
	var d: int = WorldClock.current_day if WorldClock else 1
	var h: int = WorldClock.current_hour if WorldClock else 12
	var m: int = WorldClock.current_minute if WorldClock else 0
	var total_mins: int = d * 1440 + h * 60 + m
	var vis_mult: float = get_sleep_vision_multiplier()
	if WorldClock and WorldClock.has_method("get_weather_vision_multiplier"):
		vis_mult *= float(WorldClock.call("get_weather_vision_multiplier"))

	var player := _cached_player
	if is_instance_valid(player) and not witness_silenced_player:
		var in_st: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
		var clk_m: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
		var p_range: float = (62.0 if in_st else 195.0) * clk_m * vis_mult
		if global_position.distance_to(player.global_position) <= p_range:
			if vm == null or not vm.has_method("has_line_of_sight") or bool(vm.call("has_line_of_sight", global_position, player.global_position)):
				var p_hc: HealthComponent = player.get_node_or_null("HealthComponent")
				var p_stained: bool = player.has_method("is_bloodstained") and bool(player.call("is_bloodstained"))
				var p_wounded: bool = p_hc != null and p_hc.has_fresh_combat_wounds_or_makeshift()
				_record_entity_sighting("Jugador", true, player.global_position, total_mins, d, h, m, p_stained, p_wounded)

	var npc_range: float = 195.0 * vis_mult
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != self:
			var other := n as VillageNPC
			if other.is_dead:
				continue
			if global_position.distance_squared_to(other.global_position) <= npc_range * npc_range:
				if vm == null or not vm.has_method("has_line_of_sight") or bool(vm.call("has_line_of_sight", global_position, other.global_position)):
					var o_stained: bool = other.is_bloodstained()
					var o_wounded: bool = other.health_comp != null and other.health_comp.has_fresh_combat_wounds_or_makeshift()
					_record_entity_sighting(other.npc_name, false, other.global_position, total_mins, d, h, m, o_stained, o_wounded)

func _record_entity_sighting(ent_name: String, is_p: bool, pos: Vector2, total_mins: int, d: int, h: int, m: int, stained: bool, wounded: bool) -> void:
	for i in range(seen_entities_memory.size()):
		if str(seen_entities_memory[i].get("name", "")) == ent_name:
			seen_entities_memory.remove_at(i)
			break
	seen_entities_memory.push_front({
		"name": ent_name, "is_player": is_p, "pos_x": pos.x, "pos_y": pos.y,
		"witness_x": global_position.x, "witness_y": global_position.y,
		"total_minutes": total_mins, "day": d, "hour": h, "minute": m,
		"bloodstained": stained, "wounded": wounded
	})
	while seen_entities_memory.size() > 12:
		seen_entities_memory.pop_back()

func get_seen_entities_near_crime(crime_pos: Vector2, crime_total_mins: int, max_dist: float = 320.0, max_time_diff: int = 240) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for mem in seen_entities_memory:
		var t_diff: int = abs(crime_total_mins - int(mem.get("total_minutes", crime_total_mins)))
		if t_diff > max_time_diff:
			continue
		var seen_pos := Vector2(float(mem.get("pos_x", 0.0)), float(mem.get("pos_y", 0.0)))
		var d_crime: float = seen_pos.distance_to(crime_pos)
		if d_crime <= max_dist:
			var copy_m: Dictionary = mem.duplicate()
			copy_m["dist_to_crime"] = d_crime
			results.append(copy_m)
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("dist_to_crime", 999.0)) < float(b.get("dist_to_crime", 999.0))
	)
	return results

## Tratamiento médico secuencial herida por herida del Dr. Valen en el Hospital (RimWorld):
## El médico NO cura al 100% de golpe; camina hacia el paciente en la camilla y trata UNA herida cada ~3.2s consumiendo stock real.
func _process_doctor_hospital_treatment(delta: float) -> bool:
	if not is_instance_valid(_active_hospital_patient) or not _patient_still_needs_doctor(_active_hospital_patient):
		_active_hospital_patient = _find_hospital_patient_needing_care()
		_doctor_treat_progress = 0.0
	if _active_hospital_patient == null:
		return false

	var pat_pos: Vector2 = _active_hospital_patient.global_position
	var bedside_pos: Vector2 = pat_pos + Vector2(14.0, 0.0)
	if global_position.distance_to(bedside_pos) > 26.0:
		_doctor_treat_progress = maxf(0.0, _doctor_treat_progress - delta * 8.0)
		_update_craft_bar_visual(0.20, "🩺 Yendo a atender paciente...", Color(0.45, 0.95, 0.75, 0.90))
		_move_towards_point(bedside_pos, 64.0 * lerpf(0.75, 1.0, get_job_efficiency()), delta)
		return true

	velocity = Vector2.ZERO
	if sprite:
		sprite.flip_h = (pat_pos.x < global_position.x)
	trigger_action_animation(0.6)
	var pat_hc: HealthComponent = _active_hospital_patient.get_node_or_null("HealthComponent")
	if pat_hc == null:
		_active_hospital_patient = null
		_stop_crafting_bar()
		return false
	pat_hc.is_resting_in_bed = true

	var pat_label: String = "Forastero" if _active_hospital_patient.is_in_group("player") else str(_active_hospital_patient.get("npc_name"))
	var eff: float = maxf(0.55, get_job_efficiency())
	_doctor_treat_progress += (100.0 / 3.2) * eff * delta
	var pct: int = clampi(int(round(_doctor_treat_progress)), 0, 100)
	_update_craft_bar_visual(_doctor_treat_progress / 100.0, "🩺 Tratando herida de %s (%d%%)" % [pat_label, pct], Color(0.35, 0.98, 0.62, 0.95))

	if _doctor_treat_progress >= 100.0:
		_doctor_treat_progress = 0.0
		_doctor_apply_single_step_treatment(_active_hospital_patient, pat_hc, pat_label)
		if not _patient_still_needs_doctor(_active_hospital_patient):
			_active_hospital_patient = null
			_stop_crafting_bar()
	return true

func _patient_still_needs_doctor(pat: Node2D) -> bool:
	if not is_instance_valid(pat):
		return false
	if pat.get("is_dead") == true:
		return false
	var hosp_zone := Rect2(684, 98, 110, 96)
	if not hosp_zone.has_point(pat.global_position):
		return false
	var hc: HealthComponent = pat.get_node_or_null("HealthComponent")
	if hc == null:
		return false
	if hc.get_most_urgent_untreated_wound_id(false) != -1:
		return true
	if hc.has_active_sickness_or_infection():
		return true
	if hc.is_bleeding or hc.get_total_wound_bleed_rate() > 0.0:
		return true
	return false

func _find_hospital_patient_needing_care() -> Node2D:
	var hosp_zone := Rect2(684, 98, 110, 96)
	var best: Node2D = null
	var best_urgency: float = -1.0
	var candidates: Array[Node2D] = []
	if is_instance_valid(_cached_player):
		candidates.append(_cached_player)
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != self:
			candidates.append(n as Node2D)
	for c in candidates:
		if not _patient_still_needs_doctor(c) or not hosp_zone.has_point(c.global_position):
			continue
		var hc: HealthComponent = c.get_node_or_null("HealthComponent")
		var urg: float = hc.current_blood + hc.get_total_wound_bleed_rate() * 40.0 + float(hc.get_untreated_wound_count()) * 15.0
		if urg > best_urgency:
			best_urgency = urg
			best = c
	return best

func _doctor_apply_single_step_treatment(pat: Node2D, hc: HealthComponent, pat_label: String) -> void:
	# Prioridad 1: Herida sangrante más grave -> Prioridad 2: Herida sin tratar o con vendaje rudimentario
	var wid: int = hc.get_most_urgent_untreated_wound_id(true)
	if wid == -1:
		wid = hc.get_most_urgent_untreated_wound_id(false)
	if wid != -1:
		var w_type: String = "laceration"
		var w_name: String = "Herida"
		for w in hc.wounds:
			if int(w.get("id", -1)) == wid:
				w_type = str(w.get("type", "laceration"))
				w_name = str(w.get("name", "Herida"))
				break
		var used_supply_txt: String = "Cura sin medicina (Sin Stock)"
		if w_type in ["deep_wound", "lodged_arrow"] and int(shop_stock.get("surgical_kit", 0)) > 0:
			shop_stock["surgical_kit"] = int(shop_stock["surgical_kit"]) - 1
			hc.treat_wound(wid, "stitch")
			used_supply_txt = "Sutura Quirúrgica (115%)"
		elif w_type == "fracture" and int(shop_stock.get("bandage", 0)) > 0:
			shop_stock["bandage"] = int(shop_stock["bandage"]) - 1
			hc.treat_wound(wid, "splint")
			used_supply_txt = "Entablillado Clínico (85%)"
		elif int(shop_stock.get("bandage", 0)) > 0:
			shop_stock["bandage"] = int(shop_stock["bandage"]) - 1
			hc.treat_wound(wid, "bandage")
			used_supply_txt = "Vendaje Limpio (85%)"
		elif int(shop_stock.get("herbal_poultice", 0)) > 0:
			shop_stock["herbal_poultice"] = int(shop_stock["herbal_poultice"]) - 1
			hc.treat_wound(wid, "poultice")
			used_supply_txt = "Cataplasma Herbal (70%)"
		else:
			hc.treat_wound(wid, "tend_makeshift")
			for w in hc.wounds:
				if int(w.get("id", -1)) == wid:
					w["tend_quality"] = 42.0
					w["bandage_dirty"] = 18.0
					break
		_sync_shop_stock_to_vm()
		hc.heal(10.0)
		var rem_w: int = hc.get_untreated_wound_count()
		_spawn_floating_text("🩺 %s trató [%s] de %s (%s | Quedan %d heridas)" % [npc_name, w_name, pat_label, used_supply_txt, rem_w], Color.SPRING_GREEN, -42.0)
		if pat.has_method("_spawn_floating_text") and pat != self:
			pat.call("_spawn_floating_text", "🩹 Herida tratada: %s (%s)" % [w_name, used_supply_txt], Color.AQUA, -44.0)
		return

	if hc.has_active_sickness_or_infection():
		if int(shop_stock.get("herbal_poultice", 0)) > 0:
			shop_stock["herbal_poultice"] = int(shop_stock["herbal_poultice"]) - 1
			_sync_shop_stock_to_vm()
			hc.cure_sickness(48.0)
			_spawn_floating_text("🍵🩺 %s administró Cataplasma Antiséptica a %s (+Inmunidad)" % [npc_name, pat_label], Color.SPRING_GREEN, -42.0)
		else:
			hc.cure_sickness(24.0)
			_spawn_floating_text("🩺 %s asistió la fiebre de %s (Sin cataplasmas en stock)" % [npc_name, pat_label], Color.GOLD, -42.0)
		return

	hc.stop_bleeding()
	hc.heal(18.0)

func _apply_player_and_doorway_yield(delta: float) -> void:
	var player = _cached_player
	if is_instance_valid(player) and not is_sleeping and not is_at_poker_table:
		var d_p_sq: float = global_position.distance_squared_to(player.global_position)
		if d_p_sq > 0.0025 and d_p_sq < 256.0:
			var d_p: float = sqrt(d_p_sq)
			var away_dir: Vector2 = (global_position - player.global_position).normalized()
			var side_dir := Vector2(-away_dir.y, away_dir.x) if (abs(npc_name.hash()) % 2 == 0) else Vector2(away_dir.y, -away_dir.x)
			velocity += (away_dir * 0.7 + side_dir * 0.3).normalized() * ((16.0 - d_p) / 16.0) * 34.0

	if velocity.length_squared() < 9.0 and not is_sleeping and not is_at_poker_table:
		_door_nudge_timer -= delta
		if _door_nudge_timer <= 0.0:
			_door_nudge_timer = 0.25
			var vm = _cached_vm
			if vm and vm.has_method("get_doorway_clearance_nudge"):
				var nudge: Vector2 = vm.call("get_doorway_clearance_nudge", global_position, 18.0)
				if nudge.length_squared() > 0.1:
					velocity = nudge * 28.0

func _move_towards_point(target_pos: Vector2, speed: float, delta: float = 0.016) -> void:
	var vm = _get_vm()
	var is_escorting_player: bool = vm != null and bool(vm.get("player_being_escorted_to_jail")) and vm.get("escorting_officer") == self
	var leg_mult: float = health_comp.get_moving_capacity() if health_comp else 1.0
	var eff_speed: float = maxf(62.0, speed) if is_escorting_player else (speed * get_nutrition_speed_multiplier() * get_sleep_speed_multiplier() * leg_mult)

	var _pt: int = Time.get_ticks_usec() if perf_on else 0
	_nav_waypoint_timer -= delta
	if (_nav_waypoint_timer <= 0.0) or (_cached_nav_waypoint == Vector2.INF) or (target_pos.distance_squared_to(_last_nav_dest) > 16.0) or (global_position.distance_squared_to(_cached_nav_waypoint) <= 20.0):
		_nav_waypoint_timer = 0.12
		_last_nav_dest = target_pos
		_cached_nav_waypoint = vm.call("get_navigation_waypoint", global_position, target_pos, self) if (vm and vm.has_method("get_navigation_waypoint")) else target_pos

	var nav_target: Vector2 = _cached_nav_waypoint
	var diff: Vector2 = nav_target - global_position
	var step_snap: float = maxf(3.5, eff_speed * delta * 0.65)
	if diff.length() <= step_snap:
		if diff.length() <= 6.0:
			global_position = nav_target
		if nav_target.distance_squared_to(target_pos) > 9.0 and vm and vm.has_method("get_navigation_waypoint"):
			_cached_nav_waypoint = vm.call("get_navigation_waypoint", global_position, target_pos, self)
			nav_target = _cached_nav_waypoint
			diff = nav_target - global_position
		if diff.length() <= step_snap:
			velocity = Vector2.ZERO
			_stuck_timer = 0.0
			_last_frame_pos = global_position
			return

	if perf_on: _pt = _perf_add("a_nav_waypoint", _pt)
	var _door_ok: bool = not (vm and vm.has_method("npc_interact_with_door")) or bool(vm.call("npc_interact_with_door", self, delta, target_pos, nav_target))
	if perf_on: _pt = _perf_add("a_doors", _pt)
	if not _door_ok:
		velocity = Vector2.ZERO
		_stuck_timer += delta
		if _stuck_timer >= 2.2:
			_stuck_timer = 0.0
			var is_police: bool = trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.ROYAL_INVESTIGATOR]
			_spawn_floating_text("🚓💥 ¡Derribando puerta!" if is_police else "🚪✊ ¡Puerta trancada!", Color.ORANGE_RED if is_police else Color.GOLD, -34.0)
		return

	var desired_vel: Vector2 = diff.normalized() * eff_speed

	if global_position.distance_squared_to(_last_frame_pos) < 0.09 and eff_speed > 12.0:
		_stuck_timer += delta
		if _stuck_timer >= 0.40:
			_nav_waypoint_timer = 0.0
			var perp := Vector2(-diff.y, diff.x).normalized() if (abs(npc_name.hash()) % 2 == 0) else Vector2(diff.y, -diff.x).normalized()
			desired_vel = (diff.normalized() * 0.55 + perp * 0.75).normalized() * eff_speed
	else:
		_stuck_timer = 0.0

	if perf_on: _pt = _perf_add("a_stuck", _pt)
	_sep_timer -= delta
	if _sep_timer <= 0.0:
		_sep_timer = 0.10
		var sep_vec := Vector2.ZERO
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC and n != self:
				var other := n as VillageNPC
				if not other.is_dead and not other.is_downed and not other.is_sleeping:
					var d_sq: float = global_position.distance_squared_to(other.global_position)
					if d_sq > 0.01 and d_sq < 196.0:
						var d_other: float = sqrt(d_sq)
						sep_vec += (global_position - other.global_position).normalized() * ((14.0 - d_other) / 14.0) * 22.0
		_cached_sep_vec = sep_vec
	if perf_on: _perf_add("a_separation", _pt)

	_last_frame_pos = global_position
	velocity = desired_vel if is_escorting_player else (desired_vel + _cached_sep_vec).limit_length(eff_speed * 1.15)

func _is_morning_expedition_hours() -> bool:
	if not (trade_role in [TradeRole.BLACKSMITH, TradeRole.CARPENTER, TradeRole.HERBALIST, TradeRole.FISHMONGER, TradeRole.BUTCHER]) or not WorldClock or _completed_expedition_day == WorldClock.current_day:
		return false
	var h: int = WorldClock.current_hour
	var m: int = WorldClock.current_minute
	return (h == 6 and m >= 30) or h == 7 or h == 8 or (h == 9 and m < 30)

const EXPEDITION_TARGETS: Dictionary = {
	TradeRole.CARPENTER: Vector2(65, 640), TradeRole.BLACKSMITH: Vector2(515, 648),
	TradeRole.HERBALIST: Vector2(-180, 665), TradeRole.FISHMONGER: Vector2(-52, 105), TradeRole.BUTCHER: Vector2(142, 615),
}

const EXPEDITION_DESCS: Dictionary = {
	TradeRole.CARPENTER: "🪓 Expedición Matutina: Talando Pinos",
	TradeRole.BLACKSMITH: "⛏️ Expedición Matutina: Picando Hierro",
	TradeRole.HERBALIST: "🌿 Expedición Matutina: Recogiendo Hierbas",
	TradeRole.FISHMONGER: "🎣 Expedición Matutina: Pescando en el Lago",
	TradeRole.BUTCHER: "🏹 Expedición Matutina: Cazando en el Bosque",
}

func _get_expedition_target_pos() -> Vector2:
	return EXPEDITION_TARGETS.get(trade_role, work_position)

func _get_expedition_description() -> String:
	return str(EXPEDITION_DESCS.get(trade_role, "🚶 En Expedición"))

func _is_mandatory_work_hours() -> bool:
	if (trade_role == TradeRole.UNEMPLOYED and not has_meta("day_job")) or rite_pos != Vector2.ZERO or sick_level >= 2 or errand_kind in NIGHT_ERRANDS:
		return false # V5d: el jornalero con jornal sí tiene horario de trabajo (8–18)
	if not WorldClock or _is_morning_expedition_hours():
		return true
	var h: int = WorldClock.current_hour
	# G2: fin de semana. Los oficios y sus familias trabajan solo la mañana del sábado y descansan el domingo
	if WorldClock.has_method("is_weekend") and WorldClock.is_weekend() and (trade_role in SHOP_ROLES or trade_role == TradeRole.FAMILY_MEMBER):
		if WorldClock.is_rite_day():
			return false
		return h >= 9 and h < 13
	if trade_role == TradeRole.INNKEEPER:
		return h >= 8 and h < 23
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
func _choose_preferred_meal_location() -> bool:
	var vm = _get_vm()
	if vm != null and vm.has_method("is_building_door_blocked") and bool(vm.call("is_building_door_blocked", "tavern")):
		return false
	if trade_role == TradeRole.INNKEEPER:
		return true
	if trade_role == TradeRole.UNEMPLOYED:
		return not is_vagrant_camper and personal_gold >= 13
	return personal_gold >= 36 and randf() < (0.35 if personal_gold >= 160 else 0.10) # E3: los ricos comen fuera más a menudo

## Actualiza Hambre (escala de 3 días estilo Kenshi + digestión gradual), Energía (16h despierto / 8h de sueño nocturno 22:00-06:00) y Socialización.
func _update_needs_and_decisions(delta: float) -> void:
	var is_night_env: bool = WorldClock != null and (WorldClock.current_hour >= 22 or WorldClock.current_hour < 6)
	var in_work_shift: bool = _is_mandatory_work_hours()

	if in_work_shift and current_activity != ActivityState.WORKING and (need_hunger > 22.0 or digestion_buffer > 5.0):
		is_sleeping = false
		_is_amateur_foraging = false
		_social_partner = null
		current_activity = ActivityState.WORKING
	elif in_work_shift and need_hunger <= 22.0 and digestion_buffer <= 2.0 and current_activity == ActivityState.WORKING:
		current_activity = ActivityState.EATING
		_eat_at_tavern = _choose_preferred_meal_location()

	if digestion_buffer > 0.0:
		var absorb_step: float = minf(digestion_buffer, 0.42 * delta)
		digestion_buffer = maxf(0.0, digestion_buffer - absorb_step)
		need_hunger = minf(100.0, need_hunger + absorb_step)

	var base_3day_hunger_rate: float = 0.092 * _hunger_decay_rate
	var malnutrition_fatigue_mult: float = lerpf(1.25, 1.0, clampf(need_hunger / 60.0, 0.0, 1.0))

	if current_activity != ActivityState.EATING:
		_meal_consumed_this_sitting = false
		_has_valid_meal_this_sitting = false
		_sitting_meal_ingested = 0.0
		_is_amateur_foraging = false

	match current_activity:
		ActivityState.WORKING:
			is_sleeping = false
			var work_mult: float = 1.10 if (trade_role != TradeRole.UNEMPLOYED and trade_role != TradeRole.FAMILY_MEMBER) else 0.90
			if digestion_buffer <= 0.0:
				need_hunger = maxf(0.0, need_hunger - base_3day_hunger_rate * work_mult * delta)
			need_energy = maxf(0.0, need_energy - _energy_decay_rate * (1.35 if is_night_env else 0.95) * malnutrition_fatigue_mult * delta)
			need_social = maxf(0.0, need_social - _social_decay_rate * 0.65 * delta)

		ActivityState.EATING:
			is_sleeping = false
			if _is_amateur_foraging:
				if digestion_buffer <= 0.0:
					need_hunger = maxf(0.0, need_hunger - base_3day_hunger_rate * 1.15 * delta)
				need_energy = maxf(0.0, need_energy - 0.42 * delta)
			else:
				var vm_chk = _get_vm()
				if _eat_at_tavern and vm_chk and vm_chk.has_method("is_building_door_blocked") and bool(vm_chk.call("is_building_door_blocked", "tavern")):
					_eat_at_tavern = false
					_spawn_floating_text("🚪🔒 ¡Taberna bloqueada! Iré a comer en casa / buscar suministros", Color.GOLD, -36.0)
				var meal_pos: Vector2 = tavern_social_pos if _eat_at_tavern else home_table_pos
				if global_position.distance_to(meal_pos) <= 14.0:
					if not _meal_consumed_this_sitting:
						_meal_consumed_this_sitting = true
						if _consume_pocket_meal_if_any():
							_has_valid_meal_this_sitting = true
						else:
							_has_valid_meal_this_sitting = bool(vm_chk.call("consume_village_meal_for_npc", self)) if (vm_chk and vm_chk.has_method("consume_village_meal_for_npc")) else false
						_sitting_meal_ingested = 0.0
					if _has_valid_meal_this_sitting:
						var ingest_step: float = minf(38.0 - _sitting_meal_ingested, 9.5 * delta)
						if ingest_step > 0.0:
							_sitting_meal_ingested += ingest_step
							feed_npc_gradual(ingest_step)
						need_energy = minf(100.0, need_energy + 1.2 * delta)
						need_social = minf(100.0, need_social + 5.0 * delta)
					elif need_hunger < 74.0 and need_energy > 15.0:
						_is_amateur_foraging = true
						_amateur_forage_timer = 0.0
						_amateur_prey_target = null
						_spawn_floating_text("🏹🥺 ¡Sin comida ni dinero! Saliendo al bosque a cazar/recolectar por mi cuenta...", Color.ORANGE, -38.0)
					else:
						if digestion_buffer <= 0.0:
							need_hunger = maxf(0.0, need_hunger - base_3day_hunger_rate * 0.95 * delta)
						need_energy = maxf(0.0, need_energy - 0.22 * delta)
						current_activity = ActivityState.SLEEPING if is_night_env else ActivityState.SOCIALIZING
				else:
					if digestion_buffer <= 0.0:
						need_hunger = maxf(0.0, need_hunger - base_3day_hunger_rate * 0.85 * delta)
					need_energy = maxf(0.0, need_energy - 0.22 * delta)

		ActivityState.SOCIALIZING:
			is_sleeping = false
			if digestion_buffer <= 0.0:
				need_hunger = maxf(0.0, need_hunger - base_3day_hunger_rate * 0.90 * delta)
			need_energy = maxf(0.0, need_energy - _energy_decay_rate * 0.80 * malnutrition_fatigue_mult * delta)
			if global_position.distance_to(_get_social_target_pos()) <= 22.0:
				need_social = minf(100.0, need_social + 15.0 * delta)
				_chat_bubble_timer -= delta
				if _chat_bubble_timer <= 0.0:
					_chat_bubble_timer = randf_range(4.5, 7.5)
					if rite_kind in ["sect", "sect_lure"]:
						_spawn_floating_text("🌑" if rite_kind == "sect" else "❔", Color(0.7, 0.55, 0.95), -30.0)
					elif rite_pos != Vector2.ZERO:
						_spawn_floating_text("☀️🙏" if trade_role != TradeRole.PRIEST else "☀️ «Compartid el pan y perdonad...»", Color(1.0, 0.92, 0.65), -30.0)
					elif is_visiting_grave():
						_spawn_floating_text("🕯️ «No te olvido, %s...»" % str(person_profile.deceased_partner_name), Color(0.82, 0.80, 0.98), -30.0)
					elif is_instance_valid(_social_partner) and _npc_social_event_cooldown <= 0.0:
						_trigger_dynamic_npc_social_interaction(_social_partner)
					else:
						_spawn_floating_text("💬", Color(0.75, 0.95, 1.0), -28.0)

		ActivityState.SLEEPING:
			var vm_slp = _get_vm()
			if trade_role == TradeRole.UNEMPLOYED and not is_vagrant_camper and vm_slp and vm_slp.has_method("is_building_door_blocked") and bool(vm_slp.call("is_building_door_blocked", "tavern")) and vm_slp.has_method("evict_npc_to_vagrant_camp"):
				vm_slp.call("evict_npc_to_vagrant_camp", self, "Puerta de la Taberna bloqueada")
			if global_position.distance_to(bed_position) <= 12.0:
				is_sleeping = true
				if is_vagrant_camper and not in_shelter:
					var max_camp_energy: float = 62.0 if (WorldClock != null and int(WorldClock.current_weather) == 1) else 74.0
					need_energy = minf(max_camp_energy, need_energy + 0.72 * delta)
				else:
					need_energy = minf(100.0, need_energy + 1.10 * delta)
				if digestion_buffer <= 0.0:
					need_hunger = maxf(0.0, need_hunger - base_3day_hunger_rate * 0.55 * delta)
			else:
				is_sleeping = false

	if sprite and not is_incapacitated():
		sprite.modulate = Color(0.86, 0.88, 0.78, 1.0) if need_hunger < 33.33 else (Color(0.94, 0.94, 0.88, 1.0) if need_hunger < 66.67 else Color.WHITE)

	if need_hunger <= 0.0 and digestion_buffer <= 0.0:
		_starvation_tick_timer += delta
		if _starvation_tick_timer >= 3.5:
			_starvation_tick_timer = 0.0
			last_hit_weapon_name = "Muerte por Inanición (3+ Días de Hambruna)"
			last_hit_by_player = false
			add_thought("¡Muriendo de inanición tras 3 días sin comer! (-25)", -25.0)
			_spawn_floating_text("🍖💀 ¡Inanición Letal (+3 Días sin comer)! (-Salud)", Color.ORANGE_RED, -38.0)
			if health_comp:
				var starve_dmg := DamageData.new()
				starve_dmg.amount = 3.5
				starve_dmg.type = CombatConstants.DamageType.BLUNT
				health_comp.take_damage(starve_dmg)
	else:
		_starvation_tick_timer = 0.0

	if health_comp and not is_dead:
		_npc_env_sickness_timer += delta
		if _npc_env_sickness_timer >= 2.2:
			_npc_env_sickness_timer = 0.0
			_check_npc_environmental_sickness()

	# Si por alguna razón extrema llega a 0% de energía fuera del turno obligatorio, NO se desmaya en el suelo:
	# sufre los debufos severos de privación de sueño y camina hacia su cama/campamento a dormir.
	if (need_energy <= 0.0 or (health_comp and health_comp.fever >= 25.0) or sick_level >= 2) and not in_work_shift and current_activity != ActivityState.SLEEPING:
		current_activity = ActivityState.SLEEPING
		return
	if in_work_shift and current_activity == ActivityState.WORKING:
		return

	_decision_timer -= delta
	if _decision_timer > 0.0:
		return
	_decision_timer = randf_range(0.8, 1.5)

	if current_activity == ActivityState.SLEEPING:
		if not is_night_env and need_energy >= (60.0 if is_vagrant_camper else 78.0):
			is_sleeping = false
			current_activity = ActivityState.EATING if (need_hunger < 72.0 and digestion_buffer < 12.0) else ActivityState.WORKING
			if current_activity == ActivityState.EATING:
				_eat_at_tavern = _choose_preferred_meal_location()
		return

	if current_activity == ActivityState.EATING:
		if not _is_amateur_foraging and (_sitting_meal_ingested >= 36.0 or (need_hunger + digestion_buffer) >= 96.0):
			if is_night_env or need_energy <= 12.0:
				current_activity = ActivityState.SLEEPING
			elif need_social < 75.0:
				current_activity = ActivityState.SOCIALIZING
				_social_partner = _find_best_social_partner()
			else:
				current_activity = ActivityState.WORKING
		return

	if current_activity == ActivityState.SOCIALIZING:
		if rite_pos != Vector2.ZERO and need_energy > 12.0 and need_hunger >= 30.0:
			return # G2: en el Oficio se quedan hasta que termina, salvo hambre o cansancio fuertes
		if rite_pos != Vector2.ZERO:
			leave_rite()
		if errand_kind != "" and need_energy > 12.0 and need_hunger >= 30.0 and (not is_night_env or errand_kind in NIGHT_ERRANDS):
			return # E: termina su encargo (lavarse, taberna, limosna, redada) antes de cambiar de idea
		if errand_kind != "":
			end_errand()
		if is_night_env or need_energy <= 12.0 or (need_hunger < 65.0 and digestion_buffer < 10.0) or (need_social >= 92.0 and hangout_id < 0):
			_social_partner = null
			if need_hunger < 70.0 and digestion_buffer < 12.0 and not is_night_env:
				current_activity = ActivityState.EATING
				_eat_at_tavern = _choose_preferred_meal_location()
			else:
				current_activity = ActivityState.SLEEPING if (is_night_env or need_energy <= 12.0) else ActivityState.WORKING
		return

	if need_hunger <= 78.0 and digestion_buffer < 15.0 and not is_night_env:
		current_activity = ActivityState.EATING
		_eat_at_tavern = _choose_preferred_meal_location()
	elif is_night_env or need_energy <= 12.0:
		current_activity = ActivityState.SLEEPING
	elif need_social <= (90.0 if (WorldClock != null and WorldClock.has_method("is_weekend") and WorldClock.is_weekend()) else 78.0): # G2: el fin de semana salen más
		current_activity = ActivityState.SOCIALIZING
		_social_partner = _find_best_social_partner()

var _npc_env_sickness_timer: float = 0.0

func _consume_pocket_meal_if_any() -> bool:
	var priority_foods: Array[String] = ["poisoned_stew", "spoiled_food", "country_stew", "roasted_chicken", "cooked_meat", "cooked_fish", "fried_frog_legs", "royal_ration", "bread", "raw_meat", "raw_chicken"]
	for fid in priority_foods:
		if has_pocket_item(fid, 1):
			remove_pocket_item(fid, 1)
			var info: Dictionary = SimpleInventory.CATALOG.get(fid, {})
			var fname: String = str(info.get("name", fid))
			var p_risk: float = float(info.get("poison_risk", 0.0))
			if p_risk > 0.0 and health_comp and randf() <= p_risk:
				var p_amt: float = float(info.get("poison_amount", 40.0))
				health_comp.add_food_poisoning(p_amt, fname)
				last_hit_weapon_name = "Envenenamiento por " + fname
				add_thought("¡Comí %s contaminado/adulterado! (-22)" % fname, -22.0)
				_spawn_floating_text("🤢☣️ ¡%s sufrió intoxicación al comer %s!" % [npc_name, fname], Color(0.75, 1.0, 0.25), -44.0)
			return true
	return false

func _check_npc_environmental_sickness() -> void:
	if not health_comp or is_dead:
		return
	if Rect2(-725.0, 28.0, 240.0, 120.0).has_point(global_position):
		health_comp.add_swamp_or_miasma_exposure(1.4, "Humedad de la Ciénaga de las Ranas")
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n == self or not is_instance_valid(n) or not (n is Node2D):
			continue
		if n.get("corpse_on_ground") == true and n.get("corpse_in_morgue") != true and float(n.get("corpse_rot_hours")) >= 1.5:
			if global_position.distance_to((n as Node2D).global_position) <= 68.0:
				health_comp.add_swamp_or_miasma_exposure(2.5, "Miasma de cadáver putrefacto")
				break

func _approach_or_stop(target_pos: Vector2, tol: float, spd: float, delta: float) -> void:
	if global_position.distance_to(target_pos) > tol:
		_move_towards_point(target_pos, spd, delta)
	else:
		velocity = Vector2.ZERO

func _execute_dynamic_activity(delta: float) -> void:
	if current_activity != ActivityState.WORKING:
		_supply_run_target_role = 0
		_stop_crafting_bar()

	match current_activity:
		ActivityState.SLEEPING:
			_approach_or_stop(bed_position, 7.0, 42.0, delta)
		ActivityState.EATING:
			if _is_amateur_foraging:
				_process_amateur_survival_hunting(delta)
				return
			_approach_or_stop(tavern_social_pos if _eat_at_tavern else home_table_pos, 10.0, 40.0, delta)
		ActivityState.SOCIALIZING:
			_approach_or_stop(_get_social_target_pos(), 16.0, 38.0, delta)
		ActivityState.WORKING:
			if _is_morning_expedition_hours():
				_stop_crafting_bar()
				_process_physical_morning_expedition(delta)
				return
			if trade_role in SHOP_ROLES or trade_role in [TradeRole.INNKEEPER, TradeRole.DOCTOR]:
				var _pa: int = Time.get_ticks_usec() if perf_on else 0
				_process_artisan_workshop_crafting_and_supply_runs(delta)
				if perf_on: _perf_add("d_artisan_total", _pa)
				return
			_stop_crafting_bar()
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_wander_timer = randf_range(2.2, 4.6)
				var radius: float = 26.0 if (trade_role == TradeRole.UNEMPLOYED or trade_role == TradeRole.GUARD) else 8.0
				_wander_offset = Vector2.ZERO if randf() < 0.55 else Vector2.RIGHT.rotated(randf() * TAU) * randf_range(3.0, radius)
			var anchor: Vector2 = get_meta("day_job_pos") if has_meta("day_job_pos") else work_position # V5d: jornalero en el campo
			var target_pos: Vector2 = anchor + _wander_offset
			var vm = _get_vm()
			if vm and vm.has_method("clamp_point_to_building_interior"):
				target_pos = vm.call("clamp_point_to_building_interior", anchor, target_pos)
			if vm and vm.has_method("clamp_point_outside_buildings"):
				target_pos = vm.call("clamp_point_outside_buildings", anchor, target_pos)
			_approach_or_stop(target_pos, 5.0, 44.0, delta)

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
	TradeRole.FARMER: [{"output": "wheat", "label": "Trigo", "verb": "🌾 Segando", "input": "fertilizer", "supplier": int(TradeRole.FISHMONGER), "input_name": "Abono"}, {"output": "carrot", "label": "Zanahorias", "verb": "🥕 Recogiendo", "input": "fertilizer", "supplier": int(TradeRole.FISHMONGER), "input_name": "Abono"}],
	TradeRole.RANCHER: [{"output": "wool", "label": "Lana", "verb": "🐑 Esquilando", "input": "wheat", "supplier": int(TradeRole.FARMER), "input_name": "Pienso"}, {"output": "raw_meat", "label": "Carne", "verb": "🐖 Cuidando el ganado", "input": "wheat", "supplier": int(TradeRole.FARMER), "input_name": "Pienso"}],
	TradeRole.QUARRYMAN: [{"output": "stone", "label": "Piedra", "verb": "⛏️ Picando piedra", "input": "repair_kit", "supplier": int(TradeRole.BLACKSMITH), "input_name": "Herramientas"}],
	TradeRole.WOODCUTTER: [{"output": "wood", "label": "Madera", "verb": "🪓 Talando", "input": "repair_kit", "supplier": int(TradeRole.BLACKSMITH), "input_name": "Hacha afilada"}],
	TradeRole.TINKER: [{"output": "repair_kit", "label": "Kit de Reparación", "verb": "🔧 Remendando", "input": "iron_ore", "supplier": int(TradeRole.BLACKSMITH), "input_name": "Hierro"}],
}

func _get_artisan_recipes() -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	if ARTISAN_RECIPES.has(trade_role):
		res.assign(ARTISAN_RECIPES[trade_role])
	return res

func _update_craft_bar_visual(ratio: float, label_txt: String, bar_color: Color) -> void:
	if not _craft_bar_root:
		return
	_craft_bar_root.visible = true
	var fill_w: float = 38.0 * clampf(ratio, 0.02, 1.0)
	if _craft_bar_fill:
		_craft_bar_fill.color = bar_color
		_craft_bar_fill.polygon = PackedVector2Array([Vector2(-19.0, -2.0), Vector2(-19.0 + fill_w, -2.0), Vector2(-19.0 + fill_w, 1.0), Vector2(-19.0, 1.0)])
	if _craft_bar_label and _craft_bar_label.text != label_txt:
		_craft_bar_label.text = label_txt

func _process_artisan_workshop_crafting_and_supply_runs(delta: float) -> void:
	if _supply_run_cooldown > 0.0:
		_supply_run_cooldown = maxf(0.0, _supply_run_cooldown - delta)

	var vm = _get_vm()
	if vm and vm.has_method("is_trade_sabotaged") and bool(vm.call("is_trade_sabotaged", int(trade_role))):
		_supply_run_target_role = 0
		_stop_crafting_bar()
		_approach_or_stop(work_position, 8.0, 42.0, delta)
		return

	if _supply_run_target_role != 0:
		_is_actively_crafting = false
		_supply_run_timer += delta
		var supplier_npc: VillageNPC = null
		if vm and "trade_npcs" in vm and vm.trade_npcs.has(_supply_run_target_role):
			var cand = vm.trade_npcs[_supply_run_target_role]
			if cand is VillageNPC and is_instance_valid(cand) and cand.is_conscious() and not cand.is_hostile:
				supplier_npc = cand as VillageNPC

		if supplier_npc == null:
			_supply_run_target_role = 0
			_supply_run_timer = 0.0
			_supply_run_cooldown = 28.0
			_stop_crafting_bar()
			return

		var supplier_counter: Vector2 = supplier_npc.work_position + Vector2(0, 12)
		var dist_to_sup: float = global_position.distance_to(supplier_counter)
		_update_craft_bar_visual(clampf(1.0 - (dist_to_sup / 240.0), 0.12, 0.95), "🛒 A %s (%s)" % [supplier_npc.npc_name, _supply_run_input_label], Color(0.35, 0.86, 1.0, 0.95))

		if dist_to_sup > 28.0:
			if _supply_run_timer < 24.0:
				_move_towards_point(supplier_counter, 54.0, delta)
			else:
				_supply_run_target_role = 0
				_supply_run_timer = 0.0
				_supply_run_cooldown = 32.0
				_stop_crafting_bar()
			return

		velocity = Vector2.ZERO
		if supplier_npc.is_at_shop_counter() and int(supplier_npc.shop_stock.get(_supply_run_item_id, 0)) > 0:
			var buy_cost: int = 6
			personal_gold = maxi(0, personal_gold - buy_cost)
			var biz_mode: String = str(vm.shop_businesses[_supply_run_target_role].get("owner_mode", "NPC")) if (vm and "shop_businesses" in vm and vm.shop_businesses.has(_supply_run_target_role)) else "NPC"
			if biz_mode == "SOLE_OWNER":
				vm.shop_businesses[_supply_run_target_role]["vault_gold"] = int(vm.shop_businesses[_supply_run_target_role].get("vault_gold", 0)) + buy_cost
			elif biz_mode == "PARTNER":
				var player_cut: int = int(float(buy_cost) * 0.5)
				vm.shop_businesses[_supply_run_target_role]["vault_gold"] = int(vm.shop_businesses[_supply_run_target_role].get("vault_gold", 0)) + player_cut
				supplier_npc.personal_gold = maxi(0, supplier_npc.personal_gold) + (buy_cost - player_cut)
			else:
				supplier_npc.personal_gold = maxi(0, supplier_npc.personal_gold) + buy_cost
			supplier_npc.shop_stock[_supply_run_item_id] = int(supplier_npc.shop_stock[_supply_run_item_id]) - 1
			supplier_npc._sync_shop_stock_to_vm()
			workshop_materials[_supply_run_item_id] = int(workshop_materials.get(_supply_run_item_id, 0)) + 2
			trigger_action_animation(2.2)
			supplier_npc.trigger_action_animation(2.2)
			_spawn_floating_text("🛒🤝 Compró +2 %s a %s (-%d Oro)" % [_supply_run_input_label, supplier_npc.npc_name, buy_cost], Color(0.45, 0.95, 1.0), -42.0)
			supplier_npc._spawn_floating_text("💰 +%d Oro (Suministro a %s)" % [buy_cost, npc_name], Color.GOLD, -36.0)
			add_thought("Compró suministros de taller a %s (+5)" % supplier_npc.npc_name, 5.0)
			modify_npc_relationship(supplier_npc, 6, "Comercio frecuente de suministros entre talleres")
		_supply_run_target_role = 0
		_supply_run_timer = 0.0
		_supply_run_cooldown = randf_range(38.0, 56.0)
		return

	# 2. Regresar o permanecer en su propio puesto de trabajo (`work_position`)
	if global_position.distance_to(work_position) > 16.0:
		_is_actively_crafting = false
		_update_craft_bar_visual(0.20, "🚶 Volviendo al taller...", Color(0.75, 0.85, 0.95, 0.85))
		_move_towards_point(work_position, 50.0, delta)
		return

	velocity = Vector2.ZERO
	var recipes: Array[Dictionary] = _get_artisan_recipes()
	if recipes.is_empty():
		_stop_crafting_bar()
		return

	var rec: Dictionary = recipes[_crafting_recipe_idx % recipes.size()]
	# Si el stock de este producto ya está al máximo (>= 12), pasar a la otra receta o atender mostrador
	if int(shop_stock.get(str(rec.get("output", "")), 0)) >= 12:
		_craft_progress = 0.0
		_crafting_recipe_idx = (_crafting_recipe_idx + 1) % recipes.size()
		rec = recipes[_crafting_recipe_idx]
		if int(shop_stock.get(str(rec.get("output", "")), 0)) >= 12:
			_stop_crafting_bar()
			return

	var out_id: String = str(rec.get("output", ""))
	var out_label: String = str(rec.get("label", out_id))
	var verb_str: String = str(rec.get("verb", "⚒️ Elaborando"))
	var req_input: String = str(rec.get("input", ""))
	var sup_role: int = int(rec.get("supplier", 0))
	var in_label: String = str(rec.get("input_name", req_input))
	var cur_mat_count: int = int(workshop_materials.get(req_input, 0))
	var player_near_counter: bool = is_instance_valid(_cached_player) and _cached_player.global_position.distance_squared_to(work_position) <= 60.0 * 60.0

	# Si se quedó sin el material que vende el vecino, tiene oro suficiente, el vecino está atendiendo su mostrador, tiene stock y no está saboteado, va a comprarlo
	if cur_mat_count <= 0 and _craft_progress < 8.0 and _supply_run_cooldown <= 0.0 and personal_gold >= 8 and not player_near_counter and sup_role != 0:
		if vm and "trade_npcs" in vm and vm.trade_npcs.has(sup_role):
			var sup_sabotaged: bool = vm.has_method("is_trade_sabotaged") and bool(vm.call("is_trade_sabotaged", sup_role))
			var sup_cand = vm.trade_npcs[sup_role]
			if not sup_sabotaged and sup_cand is VillageNPC and is_instance_valid(sup_cand) and sup_cand.is_at_shop_counter() and int(sup_cand.shop_stock.get(req_input, 0)) > 0:
				_supply_run_target_role = sup_role
				_supply_run_item_id = req_input
				_supply_run_input_label = in_label
				_supply_run_timer = 0.0
				_is_actively_crafting = false
				_spawn_floating_text("🛒 Necesito %s: voy a comprarle a %s" % [in_label, sup_cand.npc_name], Color(0.55, 0.92, 1.0), -38.0)
				return

	# 3. Crafteo activo en el taller con animación de trabajo (Fila 2) y barra llenándose
	_is_actively_crafting = true
	_crafting_item_id = out_id
	var eff: float = get_job_efficiency()
	var mat_speed_mult: float = 1.0 if cur_mat_count > 0 else 0.68
	var fill_rate: float = (100.0 / 16.0) * eff * mat_speed_mult
	_craft_progress += fill_rate * delta

	var pct: int = clampi(int(round(_craft_progress)), 0, 100)
	_update_craft_bar_visual(_craft_progress / 100.0, "%s %s %d%%" % [verb_str, out_label, pct], Color(0.98, 0.78, 0.24, 0.95))

	if _craft_progress >= 100.0:
		_craft_progress = 0.0
		if cur_mat_count > 0:
			workshop_materials[req_input] = cur_mat_count - 1
		shop_stock[out_id] = int(shop_stock.get(out_id, 0)) + 1
		_sync_shop_stock_to_vm()
		_spawn_floating_text("⚒️✨ ¡%s fabricó +1 %s!" % [npc_name, out_label], Color(0.55, 1.0, 0.68), -40.0)
		add_thought("Elaboró +1 %s en su taller (+4)" % out_label, 4.0)
		_crafting_recipe_idx = (_crafting_recipe_idx + 1) % recipes.size()

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
func _process_physical_morning_expedition(delta: float) -> void:
	var cur_day: int = WorldClock.current_day if WorldClock else 1
	# En Día 3 de hambruna (< 22% nutrición), el artesano no tiene fuerzas físicas para salir al bosque/lago a extraer recursos
	if need_hunger < 22.0:
		_completed_expedition_day = cur_day
		_expedition_target_node = null
		current_activity = ActivityState.EATING
		add_thought("Demasiado débil por el hambre para salir a recolectar (-10)", -10.0)
		_spawn_floating_text("🥺🍖 ¡Sin fuerzas por desnutrición! No puedo salir a recolectar hoy", Color.ORANGE_RED, -38.0)
		return
	var vm_sab = _get_vm()
	if vm_sab and vm_sab.has_method("is_trade_sabotaged") and bool(vm_sab.call("is_trade_sabotaged", int(trade_role))):
		_completed_expedition_day = cur_day
		_expedition_target_node = null
		add_thought("¡Alguien saboteó mi taller! (-12)", -12.0)
		_spawn_floating_text("🔧💥 ¡Mi taller fue saboteado! No puedo producir hoy", Color.ORANGE_RED, -38.0)
		return
	var eco: EcosystemManager = get_tree().get_first_node_in_group("ecosystem_manager") as EcosystemManager
	var eff: float = get_job_efficiency()

	# Caso 1: Pescador en el Muelle del Lago del Oeste
	if trade_role == TradeRole.FISHMONGER:
		var dock_pos: Vector2 = _get_expedition_target_pos()
		if global_position.distance_to(dock_pos) > 16.0:
			_move_towards_point(dock_pos, 58.0, delta)
			return
		velocity = Vector2.ZERO
		trigger_action_animation(0.6)
		_expedition_gather_timer += delta
		if _expedition_gather_timer >= (2.2 / maxf(0.35, eff)):
			_expedition_gather_timer = 0.0
			_completed_expedition_day = cur_day
			var fish_yield: int = 2 if eff >= 0.75 else 1
			shop_stock["cooked_fish"] = int(shop_stock.get("cooked_fish", 0)) + fish_yield
			workshop_materials["wood"] = int(workshop_materials.get("wood", 0)) + 1
			_sync_shop_stock_to_vm()
			_spawn_floating_text("🎣🐟 ¡Pescado fresco capturado! (+%d Pescado | Eficiencia %d%%)" % [fish_yield, int(round(eff * 100.0))], Color(0.65, 0.95, 1.0), -34.0)
			add_thought("Pesca matutina sostenible en el lago (+6)", 6.0)
		return

	# Caso 2: Carnicero cazando físicamente una presa real del bosque (respetando N_min)
	if trade_role == TradeRole.BUTCHER:
		var prey: WildAnimal = _expedition_target_node as WildAnimal
		var prey_invalid: bool = (not is_instance_valid(prey)) or (prey.state in [WildAnimal.AnimalState.BUTCHERED, WildAnimal.AnimalState.IN_BURROW]) or (not prey.visible)
		if prey_invalid:
			_expedition_target_node = null
			if eco != null:
				prey = eco.find_sustainable_hunt_prey(global_position)
				_expedition_target_node = prey
			if prey == null:
				# El bosque está en o por debajo de su umbral de equilibrio: suspende la caza hoy
				_completed_expedition_day = cur_day
				_spawn_floating_text("🦌⚖️ Equilibrio del bosque al límite: hoy no cazaré para proteger la fauna", Color.SPRING_GREEN, -38.0)
				add_thought("Respetó el equilibrio de la fauna del bosque (+5)", 5.0)
				return

		# J1: si un jabalí le embiste y ya va por la mitad de la salud, deja la caza por hoy y se aleja
		if should_flee_boar(prey):
			flee_from_boar(prey)
			return

		# Si la presa ya ha caído abatida (`CARCASS`), acercarse físicamente a desollarla
		if prey.state == WildAnimal.AnimalState.CARCASS:
			if global_position.distance_to(prey.global_position) > 22.0:
				_move_towards_point(prey.global_position, 64.0, delta)
			else:
				velocity = Vector2.ZERO
				_expedition_gather_timer += delta
				if _expedition_gather_timer >= (0.85 / maxf(0.35, eff)):
					_expedition_gather_timer = 0.0
					var p_name: String = prey.animal_name
					prey._finish_butchering()
					_expedition_target_node = null
					_completed_expedition_day = cur_day
					var meat_yield: int = 3 if eff >= 0.85 else (2 if eff >= 0.60 else 1)
					var leather_yield: int = 1 if eff >= 0.60 else 0
					shop_stock["cooked_meat"] = int(shop_stock.get("cooked_meat", 0)) + meat_yield
					if leather_yield > 0:
						shop_stock["leather"] = int(shop_stock.get("leather", 0)) + leather_yield
						_spawn_floating_text("🔪🥩 ¡%s desollado! (+%d Carne, +%d Cuero | Ef.%d%%)" % [p_name, meat_yield, leather_yield, int(round(eff * 100.0))], Color.GOLD, -38.0)
					else:
						_spawn_floating_text("🔪🥩 ¡%s desollado! (+%d Carne | Piel dañada por novato)" % [p_name, meat_yield], Color.GOLD, -38.0)
					_sync_shop_stock_to_vm()
					add_thought("Caza matutina en equilibrio con el bosque (+6)", 6.0)
			return

		# La presa está viva: acercarse a rango de arco y disparar flechas físicas hasta abatirla
		var dist_prey: float = global_position.distance_to(prey.global_position)
		if dist_prey > 95.0:
			_move_towards_point(prey.global_position, 68.0, delta)
		else:
			if dist_prey > 48.0:
				_move_towards_point(prey.global_position, 52.0, delta)
			else:
				velocity = Vector2.ZERO
			_expedition_gather_timer += delta
			if _expedition_gather_timer >= (0.90 / maxf(0.45, eff)):
				_expedition_gather_timer = 0.0
				_fire_hunter_arrow_at_prey(prey)
		return

	# Caso 3: Carpintero (`LOGGING`), Herrero (`MINING`) y Herborista (`FORAGE`)
	var req_h_type: int = int(HarvestableNode.HarvestType.MINING if trade_role == TradeRole.BLACKSMITH else (HarvestableNode.HarvestType.FORAGE if trade_role == TradeRole.HERBALIST else HarvestableNode.HarvestType.LOGGING))
	var h_node: HarvestableNode = _expedition_target_node as HarvestableNode
	if not is_instance_valid(h_node) or h_node.is_depleted:
		_expedition_target_node = eco.find_sustainable_harvest_node(req_h_type, global_position) if eco != null else null
		h_node = _expedition_target_node as HarvestableNode
		if h_node == null:
			_completed_expedition_day = cur_day
			_spawn_floating_text("🌿⚖️ Recursos del bosque en su umbral mínimo: hoy no extraeré más", Color.SPRING_GREEN, -38.0)
			add_thought("Protegió la regeneración natural del bosque (+5)", 5.0)
			return

	if global_position.distance_to(h_node.global_position) > 24.0:
		_move_towards_point(h_node.global_position, 60.0, delta)
		return

	velocity = Vector2.ZERO
	trigger_action_animation(0.6)
	_expedition_gather_timer += delta

	if trade_role == TradeRole.HERBALIST:
		if _expedition_gather_timer >= (1.1 / maxf(0.35, eff)):
			_expedition_gather_timer = 0.0
			h_node.harvest_by_npc(self)
			_expedition_target_node = null
			_completed_expedition_day = cur_day
			var herb_yield: int = 2 if eff >= 0.75 else 1
			shop_stock["herbal_poultice"] = int(shop_stock.get("herbal_poultice", 0)) + herb_yield
			workshop_materials["bread"] = int(workshop_materials.get("bread", 0)) + 1
			_sync_shop_stock_to_vm()
			_spawn_floating_text("🌿✨ ¡%s recolectada! (+%d Botica | Ef.%d%%)" % [h_node.node_title, herb_yield, int(round(eff * 100.0))], Color.SPRING_GREEN, -36.0)
			add_thought("Cosecha herbolaria sostenible (+6)", 6.0)
		return

	# Carpintero (Hacha) o Herrero (Pico): golpear físicamente el árbol o la veta hasta derribarlo/agotarla
	if _expedition_gather_timer >= (0.75 / maxf(0.40, eff)):
		_expedition_gather_timer = 0.0
		var dmg := DamageData.new()
		dmg.amount = 15.0 * eff
		dmg.source = self
		if trade_role == TradeRole.CARPENTER:
			dmg.type = CombatConstants.DamageType.CUT
			dmg.logging_efficiency = 1.85 * eff
			_spawn_floating_text("🪓 ¡Tala!", Color(0.95, 0.85, 0.55), -30.0)
		else:
			dmg.type = CombatConstants.DamageType.BLUNT
			dmg.mining_efficiency = 1.85 * eff
			_spawn_floating_text("⛏️ ¡Pica!", Color(0.80, 0.90, 1.0), -30.0)
		h_node.take_damage(dmg)

		if h_node.is_depleted:
			_expedition_target_node = null
			_completed_expedition_day = cur_day
			if trade_role == TradeRole.CARPENTER:
				var wood_yield: int = 3 if eff >= 0.85 else (2 if eff >= 0.60 else 1)
				shop_stock["wood"] = int(shop_stock.get("wood", 0)) + wood_yield
				_spawn_floating_text("🌲🪓 ¡Árbol talado! (+%d Madera | Ef.%d%%)" % [wood_yield, int(round(eff * 100.0))], Color.SPRING_GREEN, -38.0)
			else:
				var ore_yield: int = 2 if eff >= 0.75 else 1
				shop_stock["iron_ore"] = int(shop_stock.get("iron_ore", 0)) + ore_yield
				_spawn_floating_text("🪨⛏️ ¡Veta extraída! (+%d Hierro | Ef.%d%%)" % [ore_yield, int(round(eff * 100.0))], Color.SPRING_GREEN, -38.0)
			_sync_shop_stock_to_vm()
			add_thought("Extracción matutina en equilibrio con el bosque (+6)", 6.0)

## J2: nombre de la herida según quién la hizo (cualquiera reconoce la de un animal).
const NATURAL_DEATH_TAGS: Array[String] = ["Embestida de jabalí", "Mordedura de zorro", "Ataque de animal salvaje", "Inanición", "Enfermedad"]
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

func _fire_hunter_arrow_at_prey(prey: WildAnimal) -> void:
	if not is_instance_valid(prey):
		return
	_spawn_shot_tracer(prey.global_position, Color(0.92, 0.78, 0.45, 0.92), 1.8, 16, -4.0, 0.16)
	var d := DamageData.new()
	d.amount = 18.0 * get_job_efficiency()
	d.type = CombatConstants.DamageType.CUT
	d.source = self
	prey.take_damage(d)
	_spawn_floating_text("🏹 ¡Flechazo de Caza!", Color(0.95, 0.86, 0.52), -34.0)

## Caza y Recolección Amateur Ineficiente (`_is_amateur_foraging`):
## Cuando un NPC sin experiencia en cacería se queda sin comida en su despensa y no puede comprar en tiendas ni Taberna,
## sale al bosque por desesperación:
## - No tiene arco (persigue animales a pie haciendo apenas 5.5 de daño y fallando el 38% de los golpes).
## - Gasta mucha más energía y tarda mucho tiempo.
## - Al desollar la presa (`CARCASS`), realiza un Despiece Torpe (`🔪💦`) que destruye la piel/huesos y desperdicia el 70% de la carne,
##   obteniendo solo 1 corte precario (+24% nutrición gradual).
func _process_amateur_survival_hunting(delta: float) -> void:
	_amateur_forage_timer += delta
	var eco: EcosystemManager = get_tree().get_first_node_in_group("ecosystem_manager") as EcosystemManager
	var prey: WildAnimal = _amateur_prey_target as WildAnimal
	var prey_invalid: bool = (not is_instance_valid(prey)) or (prey.state in [WildAnimal.AnimalState.BUTCHERED, WildAnimal.AnimalState.IN_BURROW]) or (not prey.visible)
	if prey_invalid:
		_amateur_prey_target = null
		if eco != null:
			prey = eco.find_sustainable_hunt_prey(global_position)
			_amateur_prey_target = prey

	# Si tras 18s no logra encontrar o alcanzar animales, desentierra raíces y bayas amargas para no morir de hambre
	if prey == null or _amateur_forage_timer >= 20.0:
		var fallback_spot := Vector2(88, 622)
		if global_position.distance_to(fallback_spot) > 22.0 and _amateur_forage_timer < 18.0:
			_move_towards_point(fallback_spot, 48.0, delta)
			return
		velocity = Vector2.ZERO
		if _amateur_forage_timer >= 14.0:
			_is_amateur_foraging = false
			_amateur_forage_timer = 0.0
			_amateur_prey_target = null
			feed_npc_gradual(18.0)
			add_thought("Tuvo que comer raíces amargas del bosque por falta de comida (-6)", -6.0)
			_spawn_floating_text("🌱😣 Raíces silvestres recolectadas (+18% Nutrición gradual)", Color(0.82, 0.92, 0.58), -36.0)
			current_activity = ActivityState.SOCIALIZING
		return

	if should_flee_boar(prey): # J1
		flee_from_boar(prey)
		return

	# Si la presa ya cayó (`CARCASS`), acercarse y hacer un despiece amateur torpe (desperdiciando piel y 70% de carne)
	if prey.state == WildAnimal.AnimalState.CARCASS:
		if global_position.distance_to(prey.global_position) > 20.0:
			_move_towards_point(prey.global_position, 52.0, delta)
		else:
			velocity = Vector2.ZERO
			_expedition_gather_timer += delta
			if _expedition_gather_timer >= 2.2:
				_expedition_gather_timer = 0.0
				var p_name: String = prey.animal_name
				prey._finish_butchering()
				_amateur_prey_target = null
				_is_amateur_foraging = false
				_amateur_forage_timer = 0.0
				feed_npc_gradual(24.0)
				var vm_p = _cached_vm if is_instance_valid(_cached_vm) else get_tree().get_first_node_in_group("village_manager")
				if vm_p and vm_p.has_method("add_home_pantry_ration"):
					vm_p.call("add_home_pantry_ration", self, 1)
				add_thought("Cazó torpemente en el bosque para sobrevivir (-4)", -4.0)
				_spawn_floating_text("🔪💦 Despiece torpe de %s: piel arruinada y 70%% desperdiciado (+1 Carne precaria)" % p_name, Color.ORANGE, -40.0)
				current_activity = ActivityState.SOCIALIZING
		return

	# Perseguir al animal a pie sin arco (ineficiente y agotador)
	var dist_p: float = global_position.distance_to(prey.global_position)
	if dist_p > 24.0:
		_move_towards_point(prey.global_position, 54.0, delta)
	else:
		velocity = Vector2.ZERO
		_expedition_gather_timer += delta
		if _expedition_gather_timer >= 1.35:
			_expedition_gather_timer = 0.0
			if randf() < 0.38:
				_spawn_floating_text("⚔️💦 ¡Golpe sin puntería fallido! (Sin oficio de caza)", Color(0.95, 0.72, 0.45), -34.0)
			else:
				var d := DamageData.new()
				d.amount = 5.5 * get_nutrition_skill_multiplier()
				d.type = CombatConstants.DamageType.BLUNT
				d.source = self
				prey.take_damage(d)
				_spawn_floating_text("🗡️💦 Golpe torpe de caza (-5 HP)", Color(0.95, 0.80, 0.50), -34.0)

## Rutina física de los 2 Comerciantes Semanales de Extramuros (`Maese Casimir` y `Valeria la Tratante`):
## Recorren los talleres de la aldea comprando solo lo que les interesa de su especialidad e inyectando oro externo,
## y a las 19:00 regresan al camino del sur (`Vector2(430, 820)`) con su Salvoconducto Real.
func _process_traveling_merchant_routine(delta: float) -> void:
	var vm = _get_vm()
	if vm and vm.has_method("update_traveling_merchant_ai"):
		vm.call("update_traveling_merchant_ai", self, delta)
	_finish_frame_movement(delta, true)

## IA Deductiva y Persecución del Inquisidor Real Alistair (`TradeRole.ROYAL_INVESTIGATOR`):
## 1º Inspecciona la escena del crimen y la Morgue.
## 2º Interroga físicamente a los habitantes, cruzando coartadas y acumulando sospecha probabilística.
## 3º Inspecciona al jugador si pasa cerca (rango de detección 2x superior al policía común y detecta el Salvoconducto Real robado).
## 4º Filosofía Real: Nunca se va con las manos vacías; condena al sospechoso con mayor puntuación (el Jugador o un aldeano Chivo Expiatorio).
func _process_royal_investigator_ai(delta: float) -> void:
	var vm = _get_vm()
	if vm and bool(vm.get("player_being_escorted_to_jail")) and vm.get("escorting_officer") == self:
		_clear_combat_hostility(false)
		if _process_police_law_enforcement(delta, vm):
			return
	if is_hostile and vm:
		if bool(vm.get("player_in_jail")) or bool(vm.get("player_being_escorted_to_jail")):
			_clear_combat_hostility(false)
			velocity = Vector2.ZERO
		elif _process_police_law_enforcement(delta, vm):
			return
	if vm and vm.has_method("update_royal_investigator_ai"):
		vm.call("update_royal_investigator_ai", self, delta)
	_finish_frame_movement(delta, true)

func get_person_key() -> String:
	if person_profile != null and str(person_profile.person_id) != "":
		return str(person_profile.person_id)
	return npc_id if npc_id != "" else npc_name

## B2.2: Asigna una quedada (llamado por el VillageManager). El vecino pasa a socializar y camina al punto de encuentro.
func assign_hangout(h_id: int, spot_pos: Vector2, partner: VillageNPC, side: int, spot_label: String = "") -> void:
	hangout_id = h_id
	hangout_spot_pos = spot_pos
	hangout_side = side
	hangout_spot_label = spot_label
	_social_partner = partner
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
	is_sleeping = false
	_social_partner = null
	current_activity = ActivityState.SOCIALIZING
	_decision_timer = randf_range(1.0, 2.0)

func end_errand() -> void:
	errand_kind = ""
	errand_pos = Vector2.ZERO

## B4.2: Escena discreta de pelea. `VillageManager` decide inicio, fin y consecuencias; aquí solo se representa.
func is_in_live_fight() -> bool:
	return is_instance_valid(live_fight_partner)

func is_busy_with_player() -> bool:
	return _being_interviewed_timer > 0.0 or (is_instance_valid(_cached_dm) and bool(_cached_dm.get("active")) and _cached_dm.get("current_speaker") == self)

func is_busy_with_emergency() -> bool:
	return is_instance_valid(_reporting_corpse_target) or is_instance_valid(_searching_missing_kin) or is_instance_valid(_reacting_unconscious_target) or is_instance_valid(_carrying_corpse_target)

func begin_live_fight(partner: VillageNPC) -> void:
	live_fight_partner = partner
	TraitDiscovery.on_witnessed_behavior(self, "aggression", "le has visto pelear")
	_live_fight_clock = 0.0
	velocity = Vector2.ZERO
	_stop_crafting_bar()

func end_live_fight() -> void:
	live_fight_partner = null
	if sprite:
		sprite.offset = Vector2.ZERO

func _process_live_fight(delta: float) -> void:
	velocity = Vector2.ZERO
	_stop_crafting_bar()
	var prev_beat: int = int(_live_fight_clock / 1.3)
	_live_fight_clock += delta
	if sprite:
		sprite.flip_h = live_fight_partner.global_position.x < global_position.x
		sprite.offset.x = sin(_live_fight_clock * 26.0) * 1.2
	if int(_live_fight_clock / 1.3) != prev_beat:
		_spawn_floating_text("💢", Color(1.0, 0.45, 0.35), -30.0)
	trigger_action_animation(0.4)
	_update_visual_animation(delta)
	_update_hover_label(delta)

func is_at_hangout_spot(tol: float = 20.0) -> bool:
	return hangout_id >= 0 and global_position.distance_to(_get_social_target_pos()) <= tol

func _find_best_social_partner() -> VillageNPC:
	ensure_npc_relationships_initialized()
	var vm_s = _get_vm()
	var sdir_s = vm_s.get("social_director") if vm_s != null else null
	var my_key: String = get_person_key()
	var best: VillageNPC = null
	var best_score: float = -9999.0
	for node in get_tree().get_nodes_in_group("village_npcs"):
		if node == self or not (node is VillageNPC):
			continue
		var other: VillageNPC = node as VillageNPC
		if other.is_dead or other.is_downed or other.is_sleeping:
			continue
		# B2.2: los rivales se evitan (no se buscan para charlar) y no se interrumpe una quedada ajena
		if sdir_s != null and bool(sdir_s.call("should_avoid", my_key, other.get_person_key())):
			continue
		if other.hangout_id >= 0 or other.is_in_live_fight():
			continue
		var dist: float = global_position.distance_to(other.global_position)
		var other_key: String = other.get_person_key()
		var family_bonus: float = 110.0 if (family_id != "none" and other.family_id == family_id) else 0.0
		var rom_bonus: float = 0.0
		if person_profile != null and str(person_profile.partner_id) != "" and str(person_profile.partner_id) == other_key:
			rom_bonus = 135.0
		elif sdir_s != null and sdir_s.has_method("get_pair_stage"):
			match str(sdir_s.call("get_pair_stage", my_key, other_key)):
				"couple": rom_bonus = 135.0
				"dating": rom_bonus = 95.0
				"flirt": rom_bonus = 60.0
				"interest": rom_bonus = 32.0
		var rel_score: float = float(get_relationship_with_npc(other.npc_name)) * 0.65
		var fate_jitter: float = randf_range(-20.0, 42.0)
		var score: float = family_bonus + rom_bonus + rel_score + fate_jitter - dist * 0.4 + (100.0 - other.need_social) * 0.5
		if score > best_score:
			best_score = score
			best = other
	return best

func is_visiting_grave() -> bool:
	return current_activity == ActivityState.SOCIALIZING and hangout_id < 0 and person_profile != null and int(person_profile.bereavement_days_left) > 0 and str(person_profile.deceased_partner_name) != ""

func _get_social_target_pos() -> Vector2:
	if rite_pos != Vector2.ZERO:
		return rite_pos
	if errand_kind != "":
		return errand_pos
	if hangout_id >= 0:
		return hangout_spot_pos + Vector2(float(hangout_side) * 11.0, 0.0)
	if is_visiting_grave():
		var vm_g = _get_vm()
		if vm_g and vm_g.has_method("get_grave_pos_for_victim"):
			return vm_g.call("get_grave_pos_for_victim", str(person_profile.deceased_partner_name))
		return Vector2(888, 262)
	if is_instance_valid(_social_partner) and not _social_partner.is_dead and not _social_partner.is_downed and not _social_partner.is_sleeping:
		var angle_idx: float = float(abs(npc_name.hash()) % 8) * (TAU / 8.0)
		var ring_offset := Vector2.RIGHT.rotated(angle_idx) * 14.0
		var ref_p: Vector2 = _social_partner.home_table_pos if _social_partner.velocity.length_squared() > 25.0 else _social_partner.global_position
		var cand_p: Vector2 = ref_p + ring_offset
		var vm = get_tree().get_first_node_in_group("village_manager")
		if vm and vm.has_method("clamp_point_to_building_interior"):
			cand_p = vm.call("clamp_point_to_building_interior", ref_p, cand_p)
		return cand_p
	if family_id != "none":
		return home_table_pos
	return tavern_social_pos

func get_activity_description() -> String:
	if is_downed: return "🩸 Agonizando (%ds)" % maxi(1, int(ceil(bleedout_timer)))
	if sedated_timer > 0.0: return "💤 Sedado (%ds)" % maxi(1, int(ceil(sedated_timer)))
	if is_in_live_fight(): return "💢 Peleando con %s" % live_fight_partner.npc_name
	if is_instance_valid(_reporting_corpse_target):
		if _corpse_report_phase == 1:
			return "🔍 Comprobando si %s respira (%ds)" % [_reporting_corpse_target.npc_name, maxi(1, int(ceil(10.0 - _corpse_report_timer)))]
		elif _corpse_report_phase == 3:
			return "🗣️ Explicando el hallazgo de %s a la policía (%ds)" % [_reporting_corpse_target.npc_name, maxi(1, int(ceil(12.5 - _corpse_report_timer)))]
		return "🏃 Yendo en persona a avisar a la policía por %s" % _reporting_corpse_target.npc_name
	if is_instance_valid(_searching_missing_kin):
		if _missing_kin_phase == 1:
			return "😟🔍 Buscando a su familiar %s en la tienda" % _searching_missing_kin.npc_name
		elif _missing_kin_phase == 3:
			return "🗣️🚓 Denunciando la desaparición de %s (%ds)" % [_searching_missing_kin.npc_name, maxi(1, int(ceil(10.0 - _missing_kin_timer)))]
		return "😰🏃 Yendo a la policía por la ausencia de %s" % _searching_missing_kin.npc_name
	if _patrol_search_timer > 0.0 and is_instance_valid(_patrol_search_target_npc):
		return "🚓🔦 Patrulla de búsqueda: rastreando a %s" % _patrol_search_target_npc.npc_name
	if is_instance_valid(_reacting_unconscious_target):
		if _unconscious_react_mode == "opportunist_steal":
			return "🕵️‍♂️💰 Robando en sigilo a su rival %s" % _reacting_unconscious_target.npc_name
		elif _unconscious_react_mode == "friend_rescue":
			if _unconscious_react_phase == 1:
				return "🤝⚡ Socorriendo y despertando a %s" % _reacting_unconscious_target.npc_name
			return "🗣️🚓 Informando a la guardia del ataque a %s" % _reacting_unconscious_target.npc_name
		return "🤨🤚 Despertando con cautela a %s" % _reacting_unconscious_target.npc_name
	var sick_tag: String = ""
	if health_comp and health_comp.has_active_sickness_or_infection():
		sick_tag = " [🌡️Enfermo/Fiebre %d%%]" % int(round(maxf(health_comp.fever, maxf(health_comp.food_poisoning, health_comp.swamp_sickness))))
	if trade_role == TradeRole.ROYAL_INVESTIGATOR:
		var vm_inv = _get_vm()
		if vm_inv and vm_inv.has_method("get_royal_investigator_status_text"):
			return str(vm_inv.call("get_royal_investigator_status_text")) + sick_tag
		return "🔍👑 Investigando Asesinato Real" + sick_tag
	if trade_role == TradeRole.TRAVELING_MERCHANT:
		return ("🧳👑 Regresando a las Tierras Reales" if _merchant_leaving else "⚖️👑 Comerciando con Salvoconducto Real") + sick_tag
	if health_comp and (health_comp.fever >= 45.0 or health_comp.food_poisoning >= 50.0 or health_comp.swamp_sickness >= 50.0) and global_position.distance_to(Vector2(718, 136)) <= 32.0:
		return "🏥 Ingresado en el Hospital tratándose la Fiebre/Infección" + sick_tag
	match current_activity:
		ActivityState.SLEEPING:
			if in_shelter:
				return ("🕯️ Durmiendo en el Albergue del Alba" if is_sleeping else "🚶🕯️ Yendo al Albergue") + sick_tag
			if lodging == "candil":
				return ("💤 Durmiendo en El Candil" if is_sleeping else "🚶 Yendo a El Candil") + sick_tag
			if is_vagrant_camper:
				return ("⛺ Durmiendo a la Intemperie (Campamento)" if is_sleeping else "🚶⛺ Yendo a su Campamento Rústico") + sick_tag
			return ("💤 Durmiendo en Cama" if is_sleeping else "🚶 Yendo a Dormir") + sick_tag
		ActivityState.EATING:
			if _is_amateur_foraging:
				return "🏹💦 Cazando/Recolectando Torpemente (Sin Dinero/Comida)"
			var loc := "en la Taberna" if _eat_at_tavern else ("en el Albergue" if in_shelter else ("en su Fogata" if is_vagrant_camper else "en Casa"))
			return "🍲 Comiendo %s" % loc
		ActivityState.SOCIALIZING:
			if errand_kind != "":
				var at_e: bool = global_position.distance_to(errand_pos) <= 30.0
				match errand_kind:
					"wash": return "🧼 Lavándose" if at_e else "🚶🧼 Yendo a lavarse"
					"drink": return "🍺 Bebiendo en la taberna" if at_e else "🚶🍺 Yendo a la taberna a beber"
					"gamble": return "🎲 Jugando en la taberna" if at_e else "🚶🎲 Yendo a jugar a la taberna"
					"beg": return "🥺 Pidiendo limosna en la plaza" if at_e else "🚶🥺 Yendo a pedir a la plaza"
					"vote": return "🗳️ Votando en el ayuntamiento" if at_e else "🚶🗳️ Yendo a votar"
					"leave": return "🎒 Marchándose del valle"
					"leisure": return load("res://scripts/systems/VillagePlaces.gd").activity_text(self, at_e)
					"market": return "🧺 Comprando en el mercado" if at_e else "🚶🧺 Yendo al mercado"
					"mayor_office": return "🏛️ Cuadrando las cuentas del pueblo" if at_e else "🚶🏛️ Yendo al ayuntamiento"
					"player_shop_clerk": return "🏪 Atendiendo el Bazar del Forastero" if at_e else "🚶🏪 Yendo a atender el Bazar del Forastero"
					"player_shop_buy": return "🛍️ Comprando en el Bazar del Forastero" if at_e else "🚶🛍️ Yendo a comprar al Bazar del Forastero"
					"fence_alley": return "🌙 Rondando de madrugada" if at_e else "🚶🌙 Paseando de madrugada"
			if rite_kind in ["sect", "sect_lure"]:
				var vm_sc = _get_vm()
				var known_sc: bool = vm_sc != null and "sect_state" in vm_sc and (bool(vm_sc.sect_state.get("player_member", false)) or (vm_sc.sect_state.get("known", {}) as Dictionary).has(get_person_key()))
				if rite_kind == "sect" and known_sc:
					return "🌑 En una reunión secreta de la secta" if global_position.distance_to(rite_pos) <= 30.0 else "🚶🌑 Yendo a una reunión secreta"
				return "🌙 Junto al cementerio, de madrugada" if global_position.distance_to(rite_pos) <= 30.0 else "🚶🌙 Paseando de madrugada"
			if rite_pos != Vector2.ZERO:
				if trade_role == TradeRole.PRIEST:
					return "☀️ Dirigiendo el Oficio del Alba"
				return "☀️ En el Oficio del Alba" if global_position.distance_to(rite_pos) <= 30.0 else "🚶☀️ Yendo al Oficio del Alba"
			if hangout_id >= 0 and is_instance_valid(_social_partner):
				var vm_act = _get_vm()
				var sdir_act = vm_act.get("social_director") if vm_act != null else null
				var p_key: String = _social_partner.get_person_key()
				var st_act: String = str(sdir_act.call("get_pair_stage", get_person_key(), p_key)) if (sdir_act != null and sdir_act.has_method("get_pair_stage")) else "none"
				if person_profile != null and str(person_profile.partner_id) == p_key:
					st_act = "couple"
				if st_act == "couple":
					return ("💑 Pasando la tarde con %s%s" % [_social_partner.npc_name, (" (%s)" % hangout_spot_label) if hangout_spot_label != "" else ""]) if is_at_hangout_spot(24.0) else ("💑 Ha quedado con su pareja %s%s" % [_social_partner.npc_name, (" en %s" % hangout_spot_label) if hangout_spot_label != "" else ""])
				elif st_act in ["dating", "flirt"]:
					return ("💞 En una cita con %s%s" % [_social_partner.npc_name, (" (%s)" % hangout_spot_label) if hangout_spot_label != "" else ""]) if is_at_hangout_spot(24.0) else ("💞 Yendo a su cita con %s%s" % [_social_partner.npc_name, (" en %s" % hangout_spot_label) if hangout_spot_label != "" else ""])
				return ("☕ Pasando el rato con %s%s" % [_social_partner.npc_name, (" (%s)" % hangout_spot_label) if hangout_spot_label != "" else ""]) if is_at_hangout_spot(24.0) else ("🚶 Ha quedado con %s%s" % [_social_partner.npc_name, (" en %s" % hangout_spot_label) if hangout_spot_label != "" else ""])
			if is_visiting_grave():
				var d_nm_g: String = str(person_profile.deceased_partner_name)
				return ("🪦 Visitando la tumba de %s" % d_nm_g) if global_position.distance_to(_get_social_target_pos()) <= 26.0 else ("🚶🕯️ Yendo al cementerio a recordar a %s" % d_nm_g)
			return ("💬 Charlando con %s" % _social_partner.npc_name) if is_instance_valid(_social_partner) else "💬 Socializando"
		_:
			if _is_morning_expedition_hours(): return _get_expedition_description()
			if _supply_run_target_role != 0: return "🛒 Yendo a comprar %s al taller vecino" % _supply_run_input_label
			if _is_actively_crafting: return "⚒️ Crafteando en Taller (%d%%)" % int(round(_craft_progress))
			if trade_role == TradeRole.DOCTOR: return "🩺 En Guardia de Urgencias y Morgue"
			if trade_role == TradeRole.SHERIFF: return "🚓 Dirigiendo la Comisaría"
			if trade_role == TradeRole.GUARD: return "🛡️ Patrullando la Aldea"
			if trade_role == TradeRole.PRIEST: return "☀️ Cuidando la Capilla del Alba"
			if trade_role == TradeRole.NOBLE: return "📜 Administrando sus tierras"
			if trade_role == TradeRole.CHILD: return "📚 En la escuela"
			if trade_role == TradeRole.TEACHER: return "🧑‍🏫 Dando clase"
			if trade_role == TradeRole.UNEMPLOYED:
				if has_meta("day_job"):
					return str(get_meta("day_job"))
				return ("🕯️ Sin oficio, acogido en el Albergue" if in_shelter else "⛺ Sobreviviendo en las Afueras") if is_vagrant_camper else "🚶 Paseando / Jornalero"
			elif trade_role == TradeRole.FAMILY_MEMBER:
				return "🏠 Turno del Hogar (08-18h)" if _is_mandatory_work_hours() else "🏠 Cuidando el Hogar"
			return "⚒️ En Turno Laboral (08-18h)" if _is_mandatory_work_hours() else "⚒️ Atendiendo su Oficio"

## C7 fase 4c: solo guardia y alguaciles llevan armas que se puedan tirar (porra y pistola).
func is_disarmed() -> bool:
	return Time.get_ticks_msec() < disarmed_until_msec

func disarm(seconds: float = 20.0) -> bool:
	if not (trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.ROYAL_INVESTIGATOR]) or is_disarmed():
		return false
	disarmed_until_msec = Time.get_ticks_msec() + int(seconds * 1000.0)
	_police_baton_windup_timer = 0.0
	_spawn_floating_text("🫳 ¡Se le cae el arma!", Color(1.0, 0.75, 0.35), -44.0)
	return true

func apply_parry_stagger(duration: float = 0.8, quiet: bool = false) -> void:
	_stagger_timer = maxf(_stagger_timer, duration)
	_melee_windup_timer = 0.0
	_police_baton_windup_timer = 0.0
	_attack_timer = maxf(_attack_timer, duration)
	velocity = Vector2.ZERO
	if quiet:
		return # C7: tambaleo corto de un golpe normal, sin letrero ni tinte
	if sprite:
		sprite.modulate = Color(0.75, 0.92, 1.35)
	_spawn_floating_text("💫 ¡Desequilibrado!", Color.AQUA, -36.0)

func _process_hostile_combat(delta: float) -> void:
	var vm = _get_vm()
	# Si la policía ya capturó al jugador, lo lleva esposado a la comisaría, está en la celda o está negociando su entrega,
	# los civiles y guardias detienen de inmediato la agresión física (Kenshi / RDR2 / Skyrim)
	if vm and (bool(vm.get("player_being_escorted_to_jail")) or bool(vm.get("player_in_jail")) or (vm.get("police_panel") != null and vm.police_panel.visible)):
		_clear_combat_hostility(false)
		velocity = Vector2.ZERO
		return

	if _stagger_timer > 0.0:
		_stagger_timer = maxf(0.0, _stagger_timer - delta)
		_melee_windup_timer = 0.0
		velocity = Vector2.ZERO
		if _stagger_timer <= 0.0 and sprite:
			sprite.modulate = Color.WHITE
		return

	var player = _get_player()
	if not player:
		velocity = Vector2.ZERO
		return

	var is_police_unit: bool = (trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.ROYAL_INVESTIGATOR])
	if not is_police_unit:
		if _civilian_hostile_timer > 0.0:
			_civilian_hostile_timer -= delta
			if _civilian_hostile_timer <= 0.0:
				_clear_combat_hostility(false)
				velocity = Vector2.ZERO
				_spawn_floating_text("😤 ¡Que la guardia se encargue de ti!", Color.GOLD, -36.0)
				return
		# Los civiles nunca entran a la Comisaría / Celda (`Rect2(832, 92, 166, 108)`) para seguir golpeando al jugador
		var police_station_rect := Rect2(832, 92, 166, 108)
		if police_station_rect.has_point(player.global_position) or police_station_rect.has_point(global_position):
			_clear_combat_hostility(false)
			velocity = Vector2.ZERO
			return

	if _melee_recover_timer > 0.0:
		_melee_recover_timer = maxf(0.0, _melee_recover_timer - delta)
		velocity = Vector2.ZERO
		return
	if _melee_windup_timer > 0.0:
		_melee_windup_timer = maxf(0.0, _melee_windup_timer - delta)
		velocity = Vector2.ZERO
		if _melee_windup_timer <= 0.0:
			_attack_timer = 1.0
			if sprite:
				sprite.modulate = Color.WHITE
			var af: Dictionary = _CombatFeel.attack_feel("porra" if is_police_unit else "puño")
			_CombatFeel.enemy_swing(self, "porra" if is_police_unit else "puño")
			if is_instance_valid(player) and global_position.distance_to(player.global_position) <= 34.0 and player.has_method("take_damage"):
				var d := DamageData.new()
				var armed_pol: bool = is_police_unit and not is_disarmed()
				d.amount = 14.0 if armed_pol else 9.0
				d.weapon_tag = "Porra Policial" if armed_pol else ("Golpe de " + npc_name)
				d.knockback_force = float(af["push"])
				d.source = self
				player.call("take_damage", d)
				_melee_recover_timer = float(af["recover"])
			else:
				_melee_recover_timer = float(af["miss_recover"])
		return

	var dist: float = global_position.distance_to(player.global_position)
	if dist > 30.0:
		_move_towards_point(player.global_position, 88.0, delta)
	else:
		velocity = Vector2.ZERO
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_melee_windup_timer = 0.40
			trigger_action_animation(0.45)
			if sprite:
				sprite.modulate = Color(1.35, 0.9, 0.45)
			_spawn_floating_text("❗", Color.ORANGE_RED, -36.0)

func trigger_action_animation(duration: float = 2.8) -> void:
	_anim_action_timer = maxf(_anim_action_timer, duration)

func _update_visual_animation(delta: float) -> void:
	if _anim_action_timer > 0.0:
		_anim_action_timer = maxf(0.0, _anim_action_timer - delta)
	_anim_cycle_clock += delta
	if velocity.length_squared() > 4.0:
		facing_direction = velocity.normalized()
	if not sprite:
		return
	if is_sleeping:
		if _has_spritesheet_anim:
			sprite.frame = 3
		sprite.rotation_degrees = 90.0
		sprite.position = Vector2(0, 2)
		return
	sprite.rotation_degrees = 0.0
	if absf(velocity.x) > 2.0:
		sprite.flip_h = velocity.x < 0.0

	if _has_spritesheet_anim and sprite.hframes == 4 and sprite.vframes == 3:
		var moving: bool = velocity.length_squared() > 14.0
		var near_p: bool = is_instance_valid(_cached_player) and global_position.distance_squared_to(_cached_player.global_position) <= 42.0 * 42.0
		var periodic_gesture: bool = fmod(_anim_cycle_clock, 8.5) > 6.2
		var use_action_row: bool = is_hostile or _is_actively_crafting or (_anim_action_timer > 0.0) or (not moving and (near_p or periodic_gesture))
		if moving:
			_anim_frame_timer += delta * 7.5
			var col_w: int = int(floor(_anim_frame_timer)) % 4
			sprite.frame = 4 + col_w
			_step_phase += delta * 11.0
			sprite.position.y = -absf(sin(_step_phase)) * 1.1
		elif use_action_row:
			_anim_frame_timer += delta * 5.0
			var col_a: int = int(floor(_anim_frame_timer)) % 4
			sprite.frame = 8 + col_a
			sprite.position.y = 0.0
		else:
			_anim_frame_timer += delta * 2.8
			var col_i: int = int(floor(_anim_frame_timer)) % 4
			sprite.frame = col_i
			sprite.position.y = 0.0
		return

	if velocity.length_squared() > 16.0:
		_step_phase += delta * 11.0
		sprite.position.y = -absf(sin(_step_phase)) * 2.0
	else:
		sprite.position.y = 0.0

func _update_hover_label(delta: float = 0.016) -> void:
	if not status_label or is_dead or is_downed:
		return
	if is_stunned_flag:
		_show_status_label("💫 %s (%s) — Inconsciente / Aturdido (No Letal)%s" % [npc_name, npc_role, _get_pocket_loot_hint()], Color(0.65, 0.82, 1.0))
		return
	if _showing_stealth_prompt:
		_show_status_label("🕵️ SIGILO POR LA ESPALDA — %s\n[E / Q: 💤 Aturdir (No Letal) | Clic Izq. / V: 🗡️ Matar (Letal)]" % npc_name, Color(0.55, 0.98, 0.82))
		return

	_hover_label_timer -= delta
	if _hover_label_timer > 0.0:
		return
	_hover_label_timer = 0.10

	var player := _get_player()
	var near_player: bool = player != null and global_position.distance_squared_to(player.global_position) <= 30.0 * 30.0
	# Ficha al pasar el ratón (2026-11-05): solo la del vecino más cercano al puntero, y corta.
	# La ficha completa (bolsillo, rasgos, hambre, sueño…) solo manteniendo Alt.
	var mouse_d: float = global_position.distance_to(get_global_mouse_position())
	var near_mouse: bool = mouse_d <= 22.0
	if near_mouse:
		if _hover_owner == null or not is_instance_valid(_hover_owner) or _hover_owner == self or mouse_d < _hover_owner_d:
			_hover_owner = self
			_hover_owner_d = mouse_d
	elif _hover_owner == self:
		_hover_owner = null
	near_mouse = near_mouse and _hover_owner == self

	if is_sleeping and not near_mouse and not near_player:
		if status_label.text != "Zzz" or not status_label.visible:
			_show_status_label("Zzz", Color(0.72, 0.85, 1.0))
		return

	if near_mouse and not Input.is_key_pressed(KEY_ALT):
		var act_short: String = "🃏 En la Mesa de Póker" if is_at_poker_table else get_activity_description()
		_show_status_label("%s — %s\n%s  (Alt: ficha)" % [npc_name, npc_role, act_short], Color(1.0, 0.92, 0.68))
	elif near_mouse:
		var act_txt: String = "🃏 En la Mesa de Póker" if is_at_poker_table else get_activity_description()
		var traits_str: String = ", ".join(traits) if not traits.is_empty() else "Equilibrado"
		var eff_badge: String = (" · ⚒️" + get_job_efficiency_label()) if not (trade_role in [TradeRole.UNEMPLOYED, TradeRole.FAMILY_MEMBER]) else ""
		var sleep_badge: String = (" (" + get_sleep_status_label() + ")") if (need_energy < 50.0 or is_vagrant_camper) else ""
		var seal_badge: String = " · 📜Salvoconducto Real" if carries_royal_safe_conduct else ""
		_show_status_label("%s (%s) — %s%s · 💰%d Oro%s [%s]\n[%s | 😊Humor:%d%% 🍖%d%% (%s) 💤%d%%%s 💬%d%%]" % [
			npc_name, family_name, npc_role, eff_badge, maxi(0, personal_gold), seal_badge, traits_str,
			act_txt, int(round(mood)), int(round(need_hunger)), get_nutrition_status_label(), int(round(need_energy)), sleep_badge, int(round(need_social))
		], Color(1.0, 0.92, 0.68))
	else:
		status_label.visible = false

func modify_affinity(delta_amount: int) -> void:
	affinity = clampi(affinity + delta_amount, -100, 100)
	VillageFaith.on_affinity_change(_get_vm(), self, delta_amount) # G5: cuenta con sus bandos
	var sign_str := "+" if delta_amount >= 0 else ""
	_spawn_floating_text("%s%d Relación" % [sign_str, delta_amount], Color.SPRING_GREEN if delta_amount >= 0 else Color.CORAL, -42.0)
	TraitDiscovery.check_trust(self)

## T3: rasgos tal como los ve el jugador («Rencoroso, ❓, ❓»).
## U5: ¿sabe el jugador lo que siente este vecino por `other_key`? La pareja y la familia se ven siempre.
func knows_feeling_toward(other_key: String) -> bool:
	if feelings_all_known or other_key in known_feelings:
		return true
	if person_profile != null and str(person_profile.partner_id) == other_key:
		return true
	var vm_k = _get_vm()
	if vm_k != null:
		var o: VillageNPC = vm_k._get_npcs_by_person_key().get(other_key, null)
		if o != null and family_id != "none" and family_id != "" and family_id != "family_police" and o.family_id == family_id:
			return true
	return false

func learn_feeling_toward(other_key: String) -> void:
	if other_key != "" and not other_key in known_feelings:
		known_feelings.append(other_key)
	heard_feelings.erase(other_key) # ya lo sabes de primera mano

## E4: alguien te cuenta lo que este vecino siente por `other_key` (de oídas: puede quedarse viejo).
func hear_feeling_toward(other_key: String, teller_name: String) -> void:
	if other_key == "" or knows_feeling_toward(other_key):
		return
	heard_feelings[other_key] = {"by": teller_name, "rel": get_relationship_with_npc(other_key)}

func get_known_traits_text() -> String:
	return TraitDiscovery.known_traits_text(self)

func get_relationship_status_text() -> String:
	var rel := "Aliado Familiar (-20% Precios)" if affinity >= 45 else ("Amistoso" if affinity >= 20 else ("Familia Agraviada" if affinity <= -35 else ("Desconfiado" if affinity <= -10 else "Neutral")))
	return "%s (%s) | %s (%d)" % [npc_role, family_name, rel, affinity]

func get_relationship_color() -> Color:
	if affinity >= 45: return Color.CYAN
	if affinity >= 20: return Color.LIGHT_GREEN
	if affinity <= -35: return Color.RED
	return Color.ORANGE if affinity <= -10 else Color(0.85, 0.88, 0.92)

func take_damage(data: DamageData) -> void:
	if is_dead:
		return

	# Identificar arma y atacante para la autopsia forense (Paso 1 y Paso 2)
	if data and is_instance_valid(data.source):
		if data.source.is_in_group("player_trap"):
			last_hit_by_player = true
			last_hit_weapon_name = "Cepo de Acero"
		elif data.source.is_in_group("player"):
			last_hit_by_player = true
			var eq_w: Variant = data.source.get("equipped_weapon")
			if data.weapon_tag != "": last_hit_weapon_name = data.weapon_tag
			elif eq_w == data.source.get("bow_weapon"): last_hit_weapon_name = "Impacto de Flecha (Arco)"
			elif eq_w == data.source.get("hammer_weapon"): last_hit_weapon_name = "Traumatismo Contundente (Martillo)"
			elif eq_w == data.source.get("axe_weapon"): last_hit_weapon_name = "Tajo Profundo de Hacha"
			elif eq_w == data.source.get("pickaxe_weapon"): last_hit_weapon_name = "Impacto de Pico Minero"
			elif eq_w == data.source.get("sickle_weapon"): last_hit_weapon_name = "Corte de Hoz Agrícola"
			else: last_hit_weapon_name = "Corte de Espada"
		else:
			last_hit_by_player = false
			last_hit_weapon_name = death_cause_for_source(data.source)

	# Si ya está agonizando en el suelo y vuelven a golpearlo -> Rematar (muerte definitiva)
	if is_downed:
		_confirm_true_death()
		var vm_exec = get_tree().get_first_node_in_group("village_manager")
		if vm_exec and last_hit_by_player and murder_witness_name != "":
			if vm_exec.has_method("modify_family_reputation") and family_id != "none":
				vm_exec.call("modify_family_reputation", family_id, -35, "Ejecución de " + npc_name, self)
			if vm_exec.has_method("report_assault_crime"):
				vm_exec.call("report_assault_crime", self)
		return

	# P6: pelea a puño limpio en el club del sótano: sin delito ni muerte; nunca baja del 20 % (se rinde)
	if bool(get_meta("club_bout", false)) and data != null and health_comp != null:
		var club_floor: float = health_comp.get_effective_max_health() * 0.20
		data.amount = minf(data.amount, maxf(0.0, health_comp.current_health - club_floor))
		data.bleed_buildup = 0.0
		if data.amount > 0.0:
			health_comp.take_damage(data)
		return

	var vm = get_tree().get_first_node_in_group("village_manager")
	if last_hit_by_player:
		modify_affinity(-35)
		if vm:
			if vm.has_method("modify_family_reputation") and family_id != "none":
				vm.call("modify_family_reputation", family_id, -25, "Agresión a " + npc_name, self)
			if vm.has_method("report_assault_crime"):
				vm.call("report_assault_crime", self)

	is_hostile = true
	_civilian_hostile_timer = 14.0
	is_sleeping = false
	sedated_timer = 0.0
	_stop_crafting_bar()
	if not (stun_comp and stun_comp.is_stunned):
		is_stunned_flag = false
		if sprite and not is_dead and not is_downed:
			sprite.rotation_degrees = 0.0
			sprite.modulate = Color.WHITE
	current_activity = ActivityState.WORKING
	add_to_group("enemies")
	if trade_role == TradeRole.ROYAL_INVESTIGATOR and vm and "active_royal_investigation" in vm:
		var inv_dict: Dictionary = vm.active_royal_investigation
		if bool(inv_dict.get("active", false)) and str(inv_dict.get("stage", "")) != "HUNTING_PLAYER":
			inv_dict["stage"] = "HUNTING_PLAYER"
			inv_dict["verdict_target"] = "Jugador"
			inv_dict["verdict_reason"] = "Agresión directa al Inquisidor Real Alistair."
			vm.wanted_level = 5
			vm.bounty_gold = int(vm.bounty_gold) + 250
			vm.is_resisting_arrest = true
			_police_alerted_timer = 65.0
	if health_comp:
		health_comp.take_damage(data)
	if stun_comp and health_comp and health_comp.current_health > 0.0:
		stun_comp.take_damage(data)

## Comprueba si el jugador en Sigilo (`[C]`) está situado por la espalda del NPC (o junto a un NPC dormido) para ejecutar un ataque sigiloso (No Letal o Letal)
func can_be_stealth_targeted(player: Node2D) -> bool:
	var vm = _get_vm()
	if vm and (bool(vm.get("player_being_escorted_to_jail")) or bool(vm.get("player_in_jail"))):
		return false
	if player == null or is_dead or is_downed or is_hostile or is_at_poker_table or is_stunned_flag or sedated_timer > 0.0 or trade_role == TradeRole.ROYAL_INVESTIGATOR:
		return false
	if not player.has_method("is_stealthing") or not bool(player.call("is_stealthing")):
		return false
	var to_player: Vector2 = player.global_position - global_position
	var dist_sq: float = to_player.length_squared()
	if dist_sq > 29.0 * 29.0 or dist_sq < 0.01:
		return false
	if is_sleeping:
		return true
	var face_vec: Vector2 = facing_direction
	if face_vec.length_squared() < 0.01 and sprite != null:
		face_vec = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	return face_vec.normalized().dot(to_player.normalized()) <= 0.22

## Opción No Letal en Sigilo ([E] o [Q] por la espalda): Aturde / deja inconsciente al civil sin matarlo
func stealth_knockout(player: Node = null) -> void:
	if is_dead or is_downed or is_stunned_flag or sedated_timer > 0.0:
		return
	hide_prompt()
	if is_instance_valid(_reporting_corpse_target) and _reporting_corpse_target.corpse_reporter_npc == self:
		_reporting_corpse_target.corpse_reporter_npc = null
	_reporting_corpse_target = null
	_clear_unconscious_reaction_state()
	_stop_crafting_bar()
	_clear_combat_hostility()
	velocity = Vector2.ZERO
	sedated_timer = maxf(sedated_timer, 25.0)
	is_sleeping = true
	is_stunned_flag = true
	_unconscious_ignored_by.clear()
	_unconscious_helper_npc = null
	_set_sprite_pose(90.0, Color(0.55, 0.65, 1.0))
	add_thought("Aturdido por la espalda (-12)", -12.0)
	_spawn_floating_text("💤🤫 ¡%s aturdido en sigilo! (No Letal — 25s)" % npc_name, Color.AQUA, -44.0)
	if player and player.has_method("add_skill_xp"):
		player.call("add_skill_xp", "stealth", 10)
	if player and player.has_method("show_hint"):
		player.call("show_hint", "💤 Has aturdido en sigilo a %s sin matarlo (Inconsciente durante 25s)." % npc_name)

	var vm = _get_vm()
	if vm and vm.has_method("_find_conscious_witness_near"):
		var w: VillageNPC = vm.call("_find_conscious_witness_near", global_position, 145.0, self)
		if w != null:
			var w_rel: int = w.get_relationship_with_npc(npc_name)
			var w_same_fam: bool = (family_id != "none" and family_id != "" and family_id != "family_police" and w.family_id == family_id)
			var w_is_auth: bool = w.trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.DOCTOR]
			if w_rel <= -25 and not w_same_fam and not w_is_auth:
				w._spawn_floating_text("😏🤫 %s vio caer a su enemigo %s y no piensa decir ni pío a la guardia..." % [w.npc_name, npc_name], Color.GOLD, -42.0)
			elif vm.has_method("report_assault_crime"):
				vm.call("report_assault_crime", self)

## Opción Letal en Sigilo ([Clic Izq.] o [V] por la espalda): Ejecución silenciosa instantánea
func stealth_assassinate(player: Node = null) -> void:
	if is_dead:
		return
	hide_prompt()
	last_hit_by_player = true
	last_hit_weapon_name = "Ejecución Silenciosa por la Espalda"
	_confirm_true_death()
	_spawn_floating_text("🗡️🩸 ¡Asesinato sigiloso! (%s eliminado)" % npc_name, Color.CRIMSON, -48.0)
	if player and player.has_method("show_hint"):
		if murder_witness_name != "":
			player.call("show_hint", "🗡️👁️ ¡%s te vio asesinar a %s! Irá a examinar el cuerpo (10s) y luego a avisar en persona a la policía si no lo silencias o detienes." % [murder_witness_name, npc_name])
		else:
			player.call("show_hint", "🗡️🤫 Asesinato sigiloso sin testigos: el cuerpo de %s queda en el suelo." % npc_name)
	var vm = _get_vm()
	if murder_witness_name != "" and vm and vm.has_method("report_assault_crime"):
		vm.call("report_assault_crime", self)

func knockout() -> void:
	stealth_knockout(_get_player())

func show_prompt() -> void:
	_showing_stealth_prompt = true
	_show_status_label("🕵️ SIGILO POR LA ESPALDA — %s\n[E / Q: 💤 Aturdir (No Letal) | Clic Izq. / V: 🗡️ Matar (Letal)]" % npc_name, Color(0.55, 0.98, 0.82))

func hide_prompt() -> void:
	_showing_stealth_prompt = false
	if status_label:
		status_label.visible = false

func _on_stunned(stunned: bool) -> void:
	if is_dead or is_downed:
		return
	is_stunned_flag = stunned or (sedated_timer > 0.0)
	if is_stunned_flag:
		if is_instance_valid(_reporting_corpse_target) and _reporting_corpse_target.corpse_reporter_npc == self:
			_reporting_corpse_target.corpse_reporter_npc = null
		_reporting_corpse_target = null
		_stop_crafting_bar()
		_clear_combat_hostility()
		velocity = Vector2.ZERO
		_set_sprite_pose(90.0, Color(0.55, 0.65, 1.0))
	else:
		_set_sprite_pose(0.0)

## Paso 1: Al caer a 0 HP entra primero en estado "Agonizando" (`is_downed`) con cuenta atrás según la herida
func _on_died() -> void:
	if is_dead:
		return
	var vm_bld = _get_vm()
	if health_comp:
		if health_comp.current_blood >= 99.0 and not ("Desangrado" in last_hit_weapon_name):
			last_hit_weapon_name = "%s (Exanguinación / Desangrado)" % (last_hit_weapon_name if last_hit_weapon_name != "" else "Hemorragia")
		if health_comp.last_sickness_cause != "" and (health_comp.fever >= 70.0 or health_comp.food_poisoning >= 70.0 or health_comp.swamp_sickness >= 70.0 or health_comp.get_max_wound_infection() >= 90.0):
			last_hit_weapon_name = "Envenenamiento / Sepsis (%s)" % health_comp.last_sickness_cause
		for vital_o in ["heart", "liver", "lungs", "kidneys", "brain"]:
			if float(health_comp.organ_hp.get(vital_o, 100.0)) <= 0.0:
				_confirm_true_death()
				return
		if health_comp.current_blood >= 99.9 or health_comp.get_max_wound_infection() >= 99.9:
			_confirm_true_death()
			return
	if vm_bld and vm_bld.has_method("spawn_blood_puddle") and not ("Envenenamiento" in last_hit_weapon_name or "Inanición" in last_hit_weapon_name):
		vm_bld.call("spawn_blood_puddle", global_position, npc_name)
	if not is_downed:
		is_downed = true
		is_sleeping = false
		sedated_timer = 0.0
		is_stunned_flag = false
		_stop_crafting_bar()
		_clear_combat_hostility()
		velocity = Vector2.ZERO
		if last_hit_weapon_name.contains("Martillo"): bleedout_timer = 90.0
		elif last_hit_weapon_name.contains("Espada") or last_hit_weapon_name.contains("Hacha"): bleedout_timer = 48.0
		else: bleedout_timer = 68.0
		_set_sprite_pose(82.0, Color(1.1, 0.42, 0.42, 0.95))
		_spawn_floating_text("🩸 ¡%s AGONIZANDO! (%ds para salvarlo en el Hospital)" % [npc_name, int(bleedout_timer)], Color.ORANGE_RED, -44.0)
		if last_hit_by_player and not ("Arco" in last_hit_weapon_name or "Envenenamiento" in last_hit_weapon_name):
			var p_down := _get_player()
			if p_down and p_down.has_method("add_bloodstain") and p_down.global_position.distance_to(global_position) <= 135.0:
				p_down.call("add_bloodstain", 180.0)
		return
	_confirm_true_death()

## Paso 1: Rescatar a un NPC que está agonizando (`is_downed`) llevándolo al Hospital o con un Botiquín Quirúrgico
func revive_from_downed(rescuer: Node, used_surgical_kit: bool = false) -> void:
	if not is_downed or is_dead:
		return
	is_downed = false
	bleedout_timer = 0.0
	is_stunned_flag = false
	sedated_timer = 0.0
	_clear_combat_hostility(false)
	if stun_comp:
		stun_comp.clear_stun()
	_set_area_col_disabled(hurtbox, false)
	if health_comp:
		if health_comp.last_sickness_cause != "" and (health_comp.fever >= 70.0 or health_comp.food_poisoning >= 70.0 or health_comp.swamp_sickness >= 70.0):
			last_hit_weapon_name = "Envenenamiento / Sepsis (%s)" % health_comp.last_sickness_cause
		for vital_o in ["heart", "liver", "lungs", "kidneys", "brain"]:
			if float(health_comp.organ_hp.get(vital_o, 100.0)) <= 0.0:
				_confirm_true_death()
				return
		if used_surgical_kit:
			health_comp.stop_bleeding()
			health_comp.current_blood = minf(health_comp.current_blood, 45.0)
			health_comp.current_health = health_comp.get_effective_max_health() * 0.75
		else:
			# Estabilización de urgencia en camilla: aplica solo 1 torniquete de emergencia a la peor herida; el Dr. Valen debe curar el resto herida por herida
			var worst_w: int = health_comp.get_most_urgent_untreated_wound_id(true)
			if worst_w != -1:
				health_comp.treat_wound(worst_w, "tend_makeshift")
			health_comp.current_blood = minf(health_comp.current_blood, 82.0)
			health_comp.current_health = maxf(health_comp.current_health, health_comp.get_effective_max_health() * 0.35)
			health_comp.is_resting_in_bed = true
		health_comp.blood_changed.emit(health_comp.current_blood, health_comp.max_blood)
		health_comp.health_changed.emit(health_comp.current_health, health_comp.max_health)
	if not used_surgical_kit:
		global_position = Vector2(718, 136)
	_set_sprite_pose(0.0)
	add_thought("Me trasladaron a urgencias (+25)", 25.0)
	if rescuer and rescuer.is_in_group("player"):
		modify_affinity(45)
		var vm = _get_vm()
		if vm and vm.has_method("modify_family_reputation") and family_id != "none":
			vm.call("modify_family_reputation", family_id, 40, "Salvó la vida de " + npc_name, self)
		if vm:
			vm.VillageClans.grant_honor_debt(vm, self, "salvó la vida de " + npc_name)
		if "inventory" in rescuer and rescuer.inventory:
			rescuer.inventory.add_gold(25)
		if rescuer.has_method("_spawn_floating_text"):
			rescuer._spawn_floating_text("🏥 ¡Trasladaste a %s al Hospital! (+25 Oro, el Dr. Valen tratará sus heridas)" % npc_name, Color.SPRING_GREEN, -46.0)

## Paso 1: Muerte definitiva -> el cadáver permanece en el lugar donde murió (y puede pudrirse durante días si nadie entra),
## hasta que otro NPC lo vea en sus pasos naturales y lo traslade físicamente a la Morgue Forense.
func _confirm_true_death() -> void:
	if is_dead:
		return
	if health_comp:
		health_comp.stop_bleeding()
	death_world_pos = global_position
	death_day = WorldClock.current_day if WorldClock else 1
	death_hour = WorldClock.current_hour if WorldClock else 12
	death_minute = WorldClock.current_minute if WorldClock else 0

	var vm = _get_vm()
	if vm and vm.has_method("spawn_blood_puddle") and not ("Envenenamiento" in last_hit_weapon_name or "Inanición" in last_hit_weapon_name):
		vm.call("spawn_blood_puddle", death_world_pos, npc_name)
	var direct_witness_node: VillageNPC = null
	murder_witness_name = ""
	if vm and vm.has_method("_find_conscious_witness_near"):
		var w: VillageNPC = vm.call("_find_conscious_witness_near", death_world_pos, 165.0, self)
		if w != null and not (last_hit_by_player and w.witness_silenced_player):
			murder_witness_name = w.npc_name
			direct_witness_node = w

	is_downed = false
	bleedout_timer = 0.0
	is_dead = true
	if vm:
		vm.VillageClans.on_npc_death(vm, self)
	var my_dead_id: String = str(person_profile.person_id) if person_profile != null and str(person_profile.person_id) != "" else npc_id
	if is_inside_tree():
		for n_other in get_tree().get_nodes_in_group("village_npcs"):
			if n_other is VillageNPC and n_other != self and not n_other.is_dead:
				var vo := n_other as VillageNPC
				if vo.person_profile != null and str(vo.person_profile.partner_id) == my_dead_id:
					vo.person_profile.start_bereavement(npc_name, 5)
					vo.clear_hangout()
					vo.add_thought("Duelo por la muerte de mi pareja %s (-18)" % npc_name, -18.0)
					if vm and vm.has_method("record_social_event"):
						vm.call("record_social_event", "widowed", vo, self, "%s quedó viudo/a tras la muerte de %s" % [vo.npc_name, npc_name])
				vo.purge_deceased_relationship(my_dead_id, npc_name)
	if vm and vm.get("social_director") != null:
		vm.get("social_director").call("purge_deceased", my_dead_id)
	_stop_crafting_bar()
	corpse_on_ground = true
	corpse_discovered = false
	corpse_discovered_by = ""
	corpse_reported = false
	corpse_reporter_npc = null
	corpse_being_carried = false
	corpse_in_morgue = false
	corpse_buried = false
	corpse_carrier = null
	corpse_rot_hours = 0.0
	if is_instance_valid(direct_witness_node) and not (direct_witness_node.trade_role in [TradeRole.ROYAL_INVESTIGATOR, TradeRole.TRAVELING_MERCHANT]):
		begin_physical_corpse_discovery(direct_witness_node)
	_clear_combat_hostility()
	_set_area_col_disabled(hurtbox, true)
	_set_area_col_disabled(interact_area, false)
	if sprite:
		_set_sprite_pose(90.0, Color(0.68, 0.54, 0.54, 0.96))
		sprite.z_index = -1
		sprite.visible = true
	_spawn_floating_text("💀 %s ha muerto (El cuerpo yace en el lugar)" % npc_name, Color(0.88, 0.45, 0.45), -44.0)
	if last_hit_by_player and not ("Arco" in last_hit_weapon_name or "Envenenamiento" in last_hit_weapon_name):
		var p_killer := _get_player()
		if p_killer and p_killer.has_method("add_bloodstain") and p_killer.global_position.distance_to(global_position) <= 180.0:
			p_killer.call("add_bloodstain", 180.0)
	if trade_role == TradeRole.TRAVELING_MERCHANT and merchant_id in ["high_pass", "river_port", "sun_plain"]:
		var vm_c = _get_vm()
		if vm_c != null and "merchant_suspension_days" in vm_c:
			vm_c.merchant_suspension_days[merchant_id] = 7
	# El Inquisidor Real Alistair NO viene apenas muere el comerciante: solo es convocado cuando alguien descubre y reporta el cadáver (`_notify_corpse_reported_to_authorities`)

## Sucesión: este familiar o viajero sin oficio asume un puesto vacante en la aldea
func promote_to_trade(new_role: TradeRole, new_title: String, new_work_pos: Vector2, inherited_stock: Dictionary, new_tex: Texture2D = null, new_bed_pos: Vector2 = Vector2.ZERO, new_table_pos: Vector2 = Vector2.ZERO, new_family_id: String = "", new_family_name: String = "") -> void:
	var was_family := (trade_role == TradeRole.FAMILY_MEMBER)
	trade_role = new_role
	var base_days: int = 2 if was_family else 0
	# La ventaja de la escuela vale solo para el primer oficio; cambiar de oficio empieza de cero como antes
	var school_bonus: int = int(get_meta("school_bonus_days", 0)) if has_meta("school_bonus_days") else 0
	if has_meta("school_bonus_days"):
		remove_meta("school_bonus_days")
	days_in_role = clampi(base_days + school_bonus, 0, 7)
	npc_role = new_title + (" (Herencia Familiar)" if was_family else " (Sucesor)")
	work_position = new_work_pos
	if new_bed_pos != Vector2.ZERO: bed_position = new_bed_pos
	if new_table_pos != Vector2.ZERO: home_table_pos = new_table_pos
	if new_family_id != "": family_id = new_family_id
	if new_family_name != "": family_name = new_family_name
	shop_stock = inherited_stock.duplicate()
	is_vagrant_camper = false
	in_shelter = false
	lodging = ""
	if is_at_poker_table:
		set_poker_seating(false)
	_init_workshop_materials()
	_resolve_unique_64_visuals_and_lore(new_tex)
	_sync_shop_stock_to_vm()
	var vm_prom = _get_vm()
	if vm_prom and "vagrant_camp_nodes" in vm_prom and vm_prom.vagrant_camp_nodes.has(npc_name):
		var c_node = vm_prom.vagrant_camp_nodes[npc_name]
		if is_instance_valid(c_node):
			c_node.visible = false

func _inject_character_lore_into_dialogue(diag: Dictionary) -> Dictionary:
	return NPCDialogue._inject_character_lore_into_dialogue(self, diag)

func get_pickpocket_success_chance(player: Node) -> float:
	if is_dead or is_downed or is_sleeping or sedated_timer > 0.0 or is_stunned_flag:
		return 1.0
	var chance: float = 0.58
	if player:
		var phc: HealthComponent = player.get_node_or_null("HealthComponent")
		if phc:
			var manip: float = float(phc.get_capacities().get("manipulation", 1.0))
			chance *= clampf(0.45 + manip * 0.60, 0.25, 1.15)
		if player.has_method("has_master_lockpick") and bool(player.call("has_master_lockpick")):
			chance += 0.20
		if player.has_method("get_stealth_detection_multiplier") and float(player.call("get_stealth_detection_multiplier")) < 0.8:
			chance += 0.14
	if health_comp:
		var npc_consc: float = float(health_comp.get_capacities().get("consciousness", 1.0))
		chance += (1.0 - npc_consc) * 0.30
	return clampf(chance, 0.15, 0.96)

func attempt_pickpocket_or_plant(player: Node, mode: String, item_id: String = "") -> bool:
	if not player or not ("inventory" in player) or not player.inventory:
		return false
	var inv: SimpleInventory = player.inventory
	var chance: float = get_pickpocket_success_chance(player)
	if randf() > chance:
		modify_affinity(-25)
		add_thought("¡Sorprendí al Forastero hurgando en mis bolsillos! (-25)", -25.0)
		_spawn_floating_text("🚨👁️ ¡%s te descubrió hurgando en su bolsillo!" % npc_name, Color.ORANGE_RED, -46.0)
		var vm = _get_vm()
		if vm and vm.has_method("report_theft_crime"):
			vm.call("report_theft_crime", family_id, "Hurto fallido en los bolsillos de " + npc_name, global_position)
		return false

	if mode == "steal_gold":
		if personal_gold <= 0:
			return false
		var stolen_g: int = personal_gold
		personal_gold = 0
		inv.add_gold(stolen_g)
		if player.has_method("add_skill_xp"):
			player.call("add_skill_xp", "stealth", 8)
		_spawn_floating_text("🕵️💰 Hurtaste +%d Oro de %s en sigilo" % [stolen_g, npc_name], Color.GOLD, -44.0)
		return true
	elif mode == "steal_item":
		if not remove_pocket_item(item_id, 1):
			return false
		inv.add_item(item_id, 1)
		_spawn_floating_text("🕵️🤏 Hurtaste 1x %s de %s" % [inv.get_item_name(item_id), npc_name], Color.AQUA, -44.0)
		return true
	elif mode == "plant_item":
		if not inv.remove_item(item_id, 1):
			return false
		add_pocket_item(item_id, 1)
		_spawn_floating_text("🕵️📥 Metiste 1x %s en el bolsillo de %s" % [inv.get_item_name(item_id), npc_name], Color.VIOLET, -44.0)
		return true
	return false

func loot_npc_pockets(player: Node) -> bool:
	if carries_royal_safe_conduct and int(pocket_items.get("royal_safe_conduct", 0)) <= 0:
		pocket_items["royal_safe_conduct"] = 1
	if corpse_pocket_looted or (personal_gold <= 0 and pocket_items.is_empty()):
		return false
	if not player or not ("inventory" in player) or not player.inventory:
		return false
	var inv: SimpleInventory = player.inventory
	var looted_gold: int = maxi(0, personal_gold)
	var got_seal: bool = has_pocket_item("royal_safe_conduct", 1)
	var item_names: Array[String] = []
	for pk in pocket_items.keys():
		var cnt: int = int(pocket_items[pk])
		if cnt > 0:
			inv.add_item(str(pk), cnt)
			item_names.append("%s x%d" % [inv.get_item_name(str(pk)), cnt])
	personal_gold = 0
	pocket_items.clear()
	carries_royal_safe_conduct = false
	corpse_pocket_looted = true
	if looted_gold > 0:
		inv.add_gold(looted_gold)
	var msg: String = "💰 Saqueaste +%d Oro de %s" % [looted_gold, npc_name]
	if not item_names.is_empty():
		msg += " + [" + ", ".join(item_names) + "]"
	_spawn_floating_text(msg, Color.GOLD, -44.0)
	if player.has_method("show_hint"):
		player.call("show_hint", msg + (" (Oculta o planta el Salvoconducto Real si viene el Inquisidor Real)" if got_seal else ""))
	var vm = get_tree().get_first_node_in_group("village_manager")
	if vm and vm.has_method("_find_conscious_witness_near"):
		var w: VillageNPC = vm.call("_find_conscious_witness_near", global_position, 140.0, self)
		if w != null and vm.has_method("report_theft_crime"):
			vm.call("report_theft_crime", family_id, "Saqueo de bolsillos a " + npc_name, global_position)
	return true

func interact(player: Node) -> void:
	var vm_nj = _get_vm()
	if vm_nj != null and not is_dead and vm_nj.VillageNightJobs.try_player_catch(vm_nj, self, player):
		return # P6b: lo pillas en plena faena nocturna
	if is_dead:
		if corpse_buried:
			return
		if not corpse_pocket_looted and (personal_gold > 0 or carries_royal_safe_conduct or not pocket_items.is_empty()):
			loot_npc_pockets(player)
			return
		if corpse_in_morgue:
			var vm_m = _get_vm()
			if vm_m and vm_m.has_method("_open_morgue_autopsy_ui"):
				vm_m.call("_open_morgue_autopsy_ui")
			return
		report_corpse_by_player(player)
		return
	if is_downed:
		revive_from_downed(player, false)
		return
	if is_stunned_flag or sedated_timer > 0.0:
		loot_npc_pockets(player)
		return
	if player is Node2D and can_be_stealth_targeted(player as Node2D):
		stealth_knockout(player)
		return
	if is_hostile:
		return
	_start_npc_dialogue(player)

func _start_npc_dialogue(player: Node) -> void:
	# Al conversar con el jugador, el NPC detiene lo que está haciendo, mira al jugador y satisface parte de su necesidad social
	velocity = Vector2.ZERO
	_stop_crafting_bar()
	if player is Node2D and sprite:
		sprite.flip_h = ((player as Node2D).global_position.x < global_position.x)
	trigger_action_animation(0.8)
	need_social = minf(100.0, need_social + 18.0)
	var dm = get_tree().current_scene.get_node_or_null("Systems/dialogue_manager")
	if not dm:
		return
	_cached_dm = dm
	var diag := _inject_character_lore_into_dialogue(_build_dialogue())
	dm.call("start_dialogue", diag, "start", self)

## Abre directamente la rueda de diálogo de Defensa de Interrogatorio RPG (3 Rondas) cuando la policía o el Inquisidor interrogan al jugador
func start_interrogation_dialogue_with_player(player: Node) -> bool:
	_interrog_correct_steps = 0
	_interrog_penalty_acc = 0
	velocity = Vector2.ZERO
	_stop_crafting_bar()
	if player is Node2D and sprite:
		sprite.flip_h = ((player as Node2D).global_position.x < global_position.x)
	trigger_action_animation(0.8)
	var dm: Node = null
	if get_tree() and get_tree().current_scene:
		dm = get_tree().current_scene.get_node_or_null("Systems/dialogue_manager")
	if not dm and get_tree() and get_tree().root:
		dm = get_tree().root.find_child("dialogue_manager", true, false)
	if not dm:
		return false
	if dm.has_method("is_active") and bool(dm.call("is_active")):
		return false
	_cached_dm = dm
	var diag := _inject_character_lore_into_dialogue(_build_dialogue())
	if not diag.has("interrogation_r1"):
		return false
	dm.call("start_dialogue", diag, "interrogation_r1", self)
	return true

func _get_needs_status_line() -> String:
	var traits_str: String = ", ".join(traits) if not traits.is_empty() else "Equilibrado"
	var last_thought: String = thoughts[0] if not thoughts.is_empty() else "Todo tranquilo"
	var fav_name: String = str(SimpleInventory.CATALOG.get(favorite_item, {}).get("name", favorite_item))
	var eff_info: String = ""
	if not (trade_role in [TradeRole.UNEMPLOYED, TradeRole.FAMILY_MEMBER, TradeRole.NOBLE, TradeRole.CHILD]): # Nobles y niños no tienen oficio
		var shop_state: String = ""
		if trade_role in SHOP_ROLES or trade_role == TradeRole.INNKEEPER:
			shop_state = " · 🟢 En Mostrador" if is_at_shop_counter() else " · 🔴 Fuera del Mostrador (No vende aquí)"
		eff_info = " | ⚒️ Dominio: %s%s" % [get_job_efficiency_label(), shop_state]
	var seal_str: String = " · 📜Salvoconducto Real" if carries_royal_safe_conduct else ""
	var vm_d = _get_vm()
	if vm_d != null and vm_d.has_method("_get_npcs_by_person_key"): # H: deuda de la casa
		var debt: String = vm_d.VillageLoans.debt_text(vm_d, self)
		if debt != "":
			seal_str += " · " + debt
	return "[%s%s | 💰 Oro: %d%s | 😊 Humor: %d%% | 🍖%d%% (%s) 💤%d%% (%s) 💬%d%%]\n[Rasgos: %s | Favorito: %s | 💭 \"%s\"]" % [
		get_activity_description(), eff_info, maxi(0, personal_gold), seal_str, int(round(mood)),
		int(round(need_hunger)), get_nutrition_status_label(), int(round(need_energy)), get_sleep_status_label(), int(round(need_social)),
		traits_str, fav_name, last_thought
	]

func _get_market_header_line() -> String:
	var vm = _get_vm()
	if not vm:
		return ""
	var mkt_txt: String = str(vm.call("get_trade_market_status_text", int(trade_role))) if vm.has_method("get_trade_market_status_text") else "⚖️ Estable"
	var own_badge: String = str(vm.call("get_business_owner_badge", int(trade_role))) if vm.has_method("get_business_owner_badge") else ""
	return "\n[📊 Oferta/Demanda: %s%s]" % [mkt_txt, own_badge]

func _get_dynamic_sell_price(base_price: int) -> int:
	var vm = _get_vm()
	var mult: float = float(vm.call("get_trade_market_multiplier", int(trade_role))) if (vm and vm.has_method("get_trade_market_multiplier")) else 1.0
	return maxi(1, int(round(float(base_price) * mult)))

func _get_dynamic_buy_price(base_price: int) -> int:
	var vm = _get_vm()
	var mult: float = float(vm.call("get_trade_market_multiplier", int(trade_role))) if (vm and vm.has_method("get_trade_market_multiplier")) else 1.0
	var is_owner: bool = bool(vm.call("is_player_owner_or_partner", int(trade_role))) if (vm and vm.has_method("is_player_owner_or_partner")) else false
	var disc: float = 0.70 if is_owner else (0.80 if affinity >= 45 else 1.0)
	if vm != null:
		disc *= vm.VillageClans.player_price_mult(vm, self)
		if WorldClock != null and int(WorldClock.current_day) % 7 == 3 and vm.VillageMayor.has_decree(vm, "market_subsidy"):
			disc *= 0.85
	return maxi(1, int(round(float(base_price) * mult * disc)))

func _make_armor_menu(title: String, menu_key: String, items: Array) -> Dictionary:
	return NPCDialogue._make_armor_menu(self, title, menu_key, items)

func _build_blacksmith_dialogue(needs_line: String) -> Dictionary:
	return NPCDialogue._build_blacksmith_dialogue(self, needs_line)

func _build_dialogue() -> Dictionary:
	return NPCDialogue._build_dialogue(self)

func on_dialogue_action(action_id: String) -> void:
	NPCDialogue.on_dialogue_action(self, action_id)

func _spawn_floating_text(text: String, color: Color, offset_y: float = -36.0) -> void:
	if FloatingTextScene and is_inside_tree():
		var parent_scene: Node = get_tree().current_scene if get_tree().current_scene else get_parent()
		if parent_scene:
			var ft = FloatingTextScene.instantiate()
			ft.start_text = text
			ft.text_color = color
			ft.global_position = global_position + Vector2(0, offset_y)
			parent_scene.add_child(ft)

const SAVED_INT_METAS: Array = ["evicted_day", "inherited_day", "read_day", "arrived_day", "rite_invited_week", "new_clothes_day", "school_bonus_days"]
const SAVED_STR_METAS: Array = ["evicted_lot", "inherited_from", "inherited_family"]

func to_save_dict() -> Dictionary:
	var route_bought_flags: Dictionary = {}
	for rk in ["route_Bought_smith", "route_Bought_carp", "route_Bought_butcher", "route_Bought_fish", "route_Bought_herb"]:
		if has_meta(rk):
			route_bought_flags[rk] = bool(get_meta(rk))
	var quest_marks: Dictionary = {}
	for mk in SAVED_INT_METAS:
		if has_meta(mk):
			quest_marks[mk] = int(get_meta(mk))
	for mk in SAVED_STR_METAS:
		if has_meta(mk):
			quest_marks[mk] = str(get_meta(mk))
	var save_pos: Vector2 = _pre_poker_pos if (is_at_poker_table and _pre_poker_pos != Vector2.ZERO and not is_dead) else global_position
	return {
		"npc_id": npc_id,
		"person_profile": person_profile.to_dict() if person_profile != null else {},
		"npc_name": npc_name, "npc_role": npc_role, "family_id": family_id, "family_name": family_name,
		"trade_role": int(trade_role), "linked_trade": int(linked_trade), "days_in_role": days_in_role,
		"affinity": affinity, "known_traits": known_traits.duplicate(), "rumored_traits": rumored_traits.duplicate(), "known_feelings": known_feelings.duplicate(), "feelings_all_known": feelings_all_known, "heard_feelings": heard_feelings.duplicate(true), "trait_trust_tier": trait_trust_tier,
		"trait_first_impression_done": trait_first_impression_done, "trait_lore_done": trait_lore_done, "personal_gold": personal_gold, "income_week": income_week, "carries_royal_safe_conduct": carries_royal_safe_conduct,
		"pocket_items": pocket_items.duplicate(), "corpse_pocket_looted": corpse_pocket_looted, "is_vagrant_camper": is_vagrant_camper, "in_shelter": in_shelter, "lodging": lodging,
		"vagrant_camp_x": vagrant_camp_pos.x, "vagrant_camp_y": vagrant_camp_pos.y, "merchant_id": merchant_id,
		"need_hunger": need_hunger, "digestion_buffer": digestion_buffer, "need_energy": need_energy, "need_social": need_social, "need_hygiene": need_hygiene,
		"mood": mood, "thoughts": thoughts.duplicate(), "activity": int(current_activity),
		"is_dead": is_dead, "is_downed": is_downed, "bleedout_timer": bleedout_timer, "sedated_timer": sedated_timer,
		"corpse_on_ground": corpse_on_ground, "corpse_discovered": corpse_discovered, "corpse_discovered_by": corpse_discovered_by,
		"corpse_reported": corpse_reported, "corpse_in_morgue": corpse_in_morgue, "corpse_buried": corpse_buried, "corpse_rot_hours": corpse_rot_hours,
		"last_hit_weapon_name": last_hit_weapon_name, "last_hit_by_player": last_hit_by_player, "murder_witness_name": murder_witness_name,
		"death_world_pos_x": death_world_pos.x, "death_world_pos_y": death_world_pos.y,
		"death_day": death_day, "death_hour": death_hour, "death_minute": death_minute, "is_hostile": is_hostile,
		"pos_x": save_pos.x, "pos_y": save_pos.y, "work_x": work_position.x, "work_y": work_position.y,
		"bed_x": bed_position.x, "bed_y": bed_position.y, "table_x": home_table_pos.x, "table_y": home_table_pos.y,
		"hp": health_comp.current_health if health_comp else 65.0,
		"shop_stock": shop_stock.duplicate(), "workshop_materials": workshop_materials.duplicate(),
		"craft_progress": _craft_progress, "crafting_recipe_idx": _crafting_recipe_idx,
		"completed_expedition_day": _completed_expedition_day, "route_bought_flags": route_bought_flags, "quest_marks": quest_marks,
		"bloodstained_timer": bloodstained_timer, "seen_entities_memory": seen_entities_memory.duplicate(true),
		"witness_silenced_player": witness_silenced_player, "witness_alibi_for_player": witness_alibi_for_player,
		"witness_framed_target_name": witness_framed_target_name,
		"npc_relationships": npc_relationships.duplicate(), "npc_relationship_notes": npc_relationship_notes.duplicate(),
		"missing_kin_reported_day": _missing_kin_reported_day,
		"medical": health_comp.to_medical_dict() if health_comp else {}
	}

func _read_vec2(data: Dictionary, kx: String, ky: String, fallback: Vector2) -> Vector2:
	return Vector2(float(data[kx]), float(data[ky])) if (data.has(kx) and data.has(ky)) else fallback

func from_save_dict(data: Dictionary) -> void:
	npc_name = str(data.get("npc_name", npc_name))
	if data.has("person_profile") and typeof(data["person_profile"]) == TYPE_DICTIONARY and not (data["person_profile"] as Dictionary).is_empty():
		person_profile = PersonProfile.from_dict(data["person_profile"] as Dictionary)
	else:
		person_profile = null
	_init_person_profile()
	if data.has("npc_id") and str(data["npc_id"]) != "" and (person_profile == null or str(person_profile.person_id) == ""):
		npc_id = str(data["npc_id"])
	bloodstained_timer = maxf(0.0, float(data.get("bloodstained_timer", 0.0)))
	known_traits.clear()
	for kt in data.get("known_traits", []):
		known_traits.append(str(kt))
	known_feelings.clear()
	for kf in data.get("known_feelings", []):
		known_feelings.append(str(kf))
	feelings_all_known = bool(data.get("feelings_all_known", not data.has("known_feelings")))
	heard_feelings = (data.get("heard_feelings", {}) as Dictionary).duplicate(true) if data.get("heard_feelings", {}) is Dictionary else {}
	rumored_traits.clear()
	var rt_data = data.get("rumored_traits", {})
	if typeof(rt_data) == TYPE_DICTIONARY:
		for rk in rt_data.keys():
			rumored_traits[str(rk)] = str(rt_data[rk])
	trait_trust_tier = int(data.get("trait_trust_tier", 0))
	trait_first_impression_done = bool(data.get("trait_first_impression_done", false))
	trait_lore_done = bool(data.get("trait_lore_done", false))
	witness_silenced_player = bool(data.get("witness_silenced_player", false))
	witness_alibi_for_player = bool(data.get("witness_alibi_for_player", false))
	witness_framed_target_name = str(data.get("witness_framed_target_name", ""))
	if data.has("npc_relationships") and typeof(data["npc_relationships"]) == TYPE_DICTIONARY:
		npc_relationships = (data["npc_relationships"] as Dictionary).duplicate()
	if data.has("npc_relationship_notes") and typeof(data["npc_relationship_notes"]) == TYPE_DICTIONARY:
		npc_relationship_notes = (data["npc_relationship_notes"] as Dictionary).duplicate()
	_migrate_legacy_relationship_keys()
	_missing_kin_reported_day = int(data.get("missing_kin_reported_day", -1))
	_searching_missing_kin = null
	_missing_kin_phase = 0
	_missing_kin_timer = 0.0
	_patrol_search_target_npc = null
	_patrol_search_timer = 0.0
	seen_entities_memory.clear()
	if data.has("seen_entities_memory") and typeof(data["seen_entities_memory"]) == TYPE_ARRAY:
		for mem_it in (data["seen_entities_memory"] as Array):
			if typeof(mem_it) == TYPE_DICTIONARY:
				seen_entities_memory.append((mem_it as Dictionary).duplicate())
	if data.has("workshop_materials") and typeof(data["workshop_materials"]) == TYPE_DICTIONARY:
		workshop_materials = data["workshop_materials"].duplicate()
	_craft_progress = clampf(float(data.get("craft_progress", _craft_progress)), 0.0, 99.0)
	_crafting_recipe_idx = maxi(0, int(data.get("crafting_recipe_idx", _crafting_recipe_idx)))
	_completed_expedition_day = int(data.get("completed_expedition_day", -1))
	_supply_run_target_role = 0
	_supply_run_item_id = ""
	_supply_run_input_label = ""
	_supply_run_timer = 0.0
	_expedition_target_node = null
	_expedition_gather_timer = 0.0
	_is_amateur_foraging = false
	_amateur_forage_timer = 0.0
	_being_interviewed_timer = 0.0
	_interviewer_node = null
	_stop_crafting_bar()
	for rk in ["route_Bought_smith", "route_Bought_carp", "route_Bought_butcher", "route_Bought_fish", "route_Bought_herb"]:
		if has_meta(rk):
			remove_meta(rk)
	if data.has("route_bought_flags") and typeof(data["route_bought_flags"]) == TYPE_DICTIONARY:
		var rbf: Dictionary = data["route_bought_flags"]
		for rk in rbf.keys():
			set_meta(str(rk), bool(rbf[rk]))
	for mk in SAVED_INT_METAS + SAVED_STR_METAS:
		if has_meta(mk):
			remove_meta(mk)
	if data.has("quest_marks") and typeof(data["quest_marks"]) == TYPE_DICTIONARY:
		var qm_d: Dictionary = data["quest_marks"]
		for mk in SAVED_INT_METAS:
			if qm_d.has(mk):
				set_meta(str(mk), int(qm_d[mk]))
		for mk in SAVED_STR_METAS:
			if qm_d.has(mk):
				set_meta(str(mk), str(qm_d[mk]))
	is_at_poker_table = false
	poker_seat_pos = Vector2.ZERO
	_pre_poker_pos = Vector2.ZERO
	corpse_being_carried = false
	corpse_carrier = null
	corpse_reporter_npc = null
	_carrying_corpse_target = null
	_reporting_corpse_target = null
	_active_downed_patient = null
	npc_role = str(data.get("npc_role", npc_role))
	family_id = str(data.get("family_id", family_id))
	family_name = str(data.get("family_name", family_name))
	trade_role = int(data.get("trade_role", trade_role)) as TradeRole
	linked_trade = int(data.get("linked_trade", linked_trade)) as TradeRole
	days_in_role = clampi(int(data.get("days_in_role", days_in_role)), 0, 7)
	affinity = int(data.get("affinity", affinity))
	_track_income = false
	personal_gold = maxi(0, int(data.get("personal_gold", personal_gold)))
	income_week = maxi(0, int(data.get("income_week", 0)))
	_track_income = data.has("income_week")
	carries_royal_safe_conduct = bool(data.get("carries_royal_safe_conduct", carries_royal_safe_conduct))
	if data.has("pocket_items") and typeof(data["pocket_items"]) == TYPE_DICTIONARY:
		pocket_items = (data["pocket_items"] as Dictionary).duplicate()
	elif carries_royal_safe_conduct:
		pocket_items["royal_safe_conduct"] = maxi(1, int(pocket_items.get("royal_safe_conduct", 0)))
	corpse_pocket_looted = bool(data.get("corpse_pocket_looted", corpse_pocket_looted))
	is_vagrant_camper = bool(data.get("is_vagrant_camper", is_vagrant_camper))
	in_shelter = bool(data.get("in_shelter", in_shelter))
	lodging = str(data.get("lodging", lodging))
	vagrant_camp_pos = _read_vec2(data, "vagrant_camp_x", "vagrant_camp_y", vagrant_camp_pos)
	merchant_id = str(data.get("merchant_id", merchant_id))
	need_hunger = clampf(float(data.get("need_hunger", need_hunger)), 0.0, 100.0)
	digestion_buffer = clampf(float(data.get("digestion_buffer", digestion_buffer)), 0.0, 100.0)
	need_energy = clampf(float(data.get("need_energy", need_energy)), 0.0, 100.0)
	need_social = clampf(float(data.get("need_social", need_social)), 0.0, 100.0)
	need_hygiene = clampf(float(data.get("need_hygiene", need_hygiene)), 0.0, 100.0)
	current_activity = int(data.get("activity", current_activity)) as ActivityState
	global_position = _read_vec2(data, "pos_x", "pos_y", global_position)
	work_position = _read_vec2(data, "work_x", "work_y", work_position)
	bed_position = _read_vec2(data, "bed_x", "bed_y", bed_position)
	home_table_pos = _read_vec2(data, "table_x", "table_y", home_table_pos)
	if data.has("shop_stock") and typeof(data["shop_stock"]) == TYPE_DICTIONARY:
		shop_stock = data["shop_stock"].duplicate()
	_resolve_unique_64_visuals_and_lore()
	mood = clampf(float(data.get("mood", mood)), 0.0, 100.0)
	if data.has("thoughts") and typeof(data["thoughts"]) == TYPE_ARRAY:
		thoughts.clear()
		for th in (data["thoughts"] as Array):
			thoughts.append(str(th))
	last_hit_weapon_name = str(data.get("last_hit_weapon_name", last_hit_weapon_name))
	last_hit_by_player = bool(data.get("last_hit_by_player", false))
	murder_witness_name = str(data.get("murder_witness_name", ""))
	if stun_comp: stun_comp.clear_stun()
	if health_comp: health_comp.stop_bleeding()
	if bool(data.get("is_dead", false)):
		is_downed = false
		bleedout_timer = 0.0
		is_dead = true
		_clear_combat_hostility()
		if health_comp: health_comp.current_health = 0.0
		corpse_on_ground = bool(data.get("corpse_on_ground", true))
		corpse_discovered = bool(data.get("corpse_discovered", false))
		corpse_discovered_by = str(data.get("corpse_discovered_by", ""))
		corpse_reported = bool(data.get("corpse_reported", false))
		corpse_in_morgue = bool(data.get("corpse_in_morgue", false))
		corpse_buried = bool(data.get("corpse_buried", false))
		corpse_rot_hours = float(data.get("corpse_rot_hours", 0.0))
		death_world_pos = _read_vec2(data, "death_world_pos_x", "death_world_pos_y", global_position)
		death_day = int(data.get("death_day", 1))
		death_hour = int(data.get("death_hour", 12))
		death_minute = int(data.get("death_minute", 0))
		_set_area_col_disabled(hurtbox, true)
		_set_area_col_disabled(interact_area, corpse_buried)
		if sprite:
			_set_sprite_pose(90.0, Color(0.68, 0.54, 0.54, 0.96))
			sprite.z_index = -1
			sprite.visible = not corpse_in_morgue
	else:
		is_dead = false
		is_downed = bool(data.get("is_downed", false))
		bleedout_timer = float(data.get("bleedout_timer", 0.0))
		sedated_timer = float(data.get("sedated_timer", 0.0))
		is_stunned_flag = sedated_timer > 0.0
		is_sleeping = sedated_timer > 0.0
		set_poker_seating(false)
		corpse_on_ground = false
		corpse_discovered = false
		corpse_reported = false
		corpse_in_morgue = false
		corpse_buried = false
		is_hostile = bool(data.get("is_hostile", false)) and not is_downed and sedated_timer <= 0.0
		if is_hostile:
			if not is_in_group("enemies"): add_to_group("enemies")
		else:
			remove_from_group("enemies")
		if body_col: body_col.set_deferred("disabled", not is_hostile)
		_set_area_col_disabled(hurtbox, false)
		_set_area_col_disabled(interact_area, false)
		if sprite:
			sprite.visible = true
			sprite.z_index = 0
			if is_downed: _set_sprite_pose(82.0, Color(1.1, 0.42, 0.42, 0.95))
			elif sedated_timer > 0.0: _set_sprite_pose(90.0, Color(0.55, 0.65, 1.0))
			else: _set_sprite_pose(0.0)
		if health_comp and data.has("hp"):
			health_comp.current_health = clampf(float(data["hp"]), 1.0, health_comp.max_health)
	if health_comp:
		if data.has("medical") and typeof(data["medical"]) == TYPE_DICTIONARY:
			health_comp.from_medical_dict(data["medical"])
		else:
			health_comp._init_anatomy()
