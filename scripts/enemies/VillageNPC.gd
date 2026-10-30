@tool
extends CharacterBody2D
class_name VillageNPC

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
	ROYAL_INVESTIGATOR  # 10. Inquisidor Real enviado por la Corona si asesinan a un Mercader Semanal
}

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

# Experiencia y Curva de Eficiencia Laboral (0 días = Novato 35%, 2 días = Aprendiz Familiar 54%, 7+ días = Maestro 100%)
var days_in_role: int = 7

# Posiciones clave en la aldea para este NPC
var work_position: Vector2 = Vector2.ZERO
var bed_position: Vector2 = Vector2.ZERO
var home_table_pos: Vector2 = Vector2.ZERO
var tavern_social_pos: Vector2 = Vector2(395, -135)
var shop_stock: Dictionary = {}

# Economía Personal Real (`personal_gold`), Salvoconducto Real, Vagabundeo Rústico y Caza Amateur
var personal_gold: int = -1
var carries_royal_safe_conduct: bool = false
var corpse_pocket_looted: bool = false
var is_vagrant_camper: bool = false
var vagrant_camp_pos: Vector2 = Vector2.ZERO
var _is_amateur_foraging: bool = false
var _amateur_forage_timer: float = 0.0
var _amateur_prey_target: Node2D = null
var merchant_id: String = "" # "casimir" o "valeria"
var _merchant_visit_timer: float = 0.0
var _merchant_shop_index: int = 0
var _merchant_leaving: bool = false
var _investigator_timer: float = 0.0
var _investigator_target_npc: VillageNPC = null

# Sub-stats de Necesidades Dinámicas (0.0 = crítico / 3 días sin comer, 100.0 = 300 pts Kenshi Bien Alimentado)
var need_hunger: float = 88.0
var digestion_buffer: float = 0.0 # Reserva en estómago (se absorbe gradualmente en `need_hunger`, estilo Kenshi)
var need_energy: float = 85.0
var need_social: float = 75.0

# Psicología Estilo RimWorld (Rasgos, Humor, Gustos y Pensamientos) + Retratos 64x64 y Contexto Narrativo
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
var corpse_carrier: VillageNPC = null
var corpse_rot_hours: float = 0.0
var death_world_pos: Vector2 = Vector2.ZERO
var death_day: int = -1
var death_hour: int = -1
var death_minute: int = -1
var murder_witness_name: String = ""
var _carrying_corpse_target: VillageNPC = null
var _reporting_corpse_target: VillageNPC = null
var _active_downed_patient: VillageNPC = null

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

# Estado Policial y Sigilo (Negociación -> Persecución + Derribo No Letal / Asesinato Letal por la Espalda)
var _police_alerted_timer: float = 0.0
var _civilian_hostile_timer: float = 0.0
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

const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

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
	if not Engine.is_editor_hint() and WorldClock and not WorldClock.hour_passed.is_connected(_on_hour_passed):
		WorldClock.hour_passed.connect(_on_hour_passed)

func _on_hour_passed(_day: int, _new_hour: int = 0) -> void:
	if is_dead and corpse_on_ground and not corpse_in_morgue:
		corpse_rot_hours += 1.0

func setup_npc(
	tex: Texture2D,
	p_work_pos: Vector2,
	p_bed_pos: Vector2,
	initial_stock: Dictionary = {},
	p_home_table_pos: Vector2 = Vector2.ZERO,
	p_family_id: String = "none",
	p_family_name: String = "Independiente"
) -> void:
	work_position = p_work_pos
	bed_position = p_bed_pos
	home_table_pos = p_home_table_pos if p_home_table_pos != Vector2.ZERO else p_bed_pos + Vector2(0, 18)
	family_id = p_family_id
	family_name = p_family_name
	global_position = work_position
	shop_stock = initial_stock.duplicate()

	# Inicializar sub-stats y metabolismo con variación individual para que cada NPC tenga su propio ritmo (3 días completos = 100% -> 0%, 16h despierto / 8h sueño nocturno)
	need_hunger = randf_range(78.0, 96.0)
	digestion_buffer = 0.0
	need_energy = randf_range(84.0, 98.0)
	need_social = randf_range(58.0, 92.0)
	_hunger_decay_rate = randf_range(0.88, 1.14)
	_energy_decay_rate = randf_range(0.24, 0.30)
	_social_decay_rate = randf_range(0.45, 0.70)
	if personal_gold < 0:
		match trade_role:
			TradeRole.INNKEEPER, TradeRole.BLACKSMITH:
				personal_gold = randi_range(68, 95)
			TradeRole.BUTCHER, TradeRole.CARPENTER, TradeRole.HERBALIST, TradeRole.FISHMONGER:
				personal_gold = randi_range(48, 72)
			TradeRole.DOCTOR, TradeRole.SHERIFF, TradeRole.GUARD:
				personal_gold = randi_range(52, 78)
			TradeRole.FAMILY_MEMBER:
				personal_gold = randi_range(26, 44)
			TradeRole.TRAVELING_MERCHANT:
				personal_gold = randi_range(172, 238)
				carries_royal_safe_conduct = true
			TradeRole.ROYAL_INVESTIGATOR:
				personal_gold = randi_range(110, 155)
			_:
				personal_gold = randi_range(24, 38)
	_init_rimworld_psychology()

	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_resolve_unique_64_visuals_and_lore(tex)
	sprite.scale = Vector2(0.54, 0.54)
	add_child(sprite)

	body_col = CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.5
	body_col.shape = c
	# Colisión blanda (Stardew Valley / RimWorld): los NPCs pacíficos no bloquean físicamente el paso del jugador en umbrales/puertas
	body_col.disabled = true
	add_child(body_col)

	health_comp = HealthComponent.new()
	health_comp.name = "HealthComponent"
	var base_hp: float = 65.0
	if trade_role == TradeRole.ROYAL_INVESTIGATOR:
		base_hp = 165.0
	elif trade_role == TradeRole.TRAVELING_MERCHANT:
		base_hp = 95.0
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
	var hcol := CollisionShape2D.new()
	var hc := CircleShape2D.new()
	hc.radius = 10.0
	hcol.shape = hc
	hurtbox.add_child(hcol)
	hurtbox.hit_received.connect(take_damage)
	add_child(hurtbox)

	interact_area = Area2D.new()
	interact_area.name = "InteractArea"
	interact_area.collision_layer = 1
	interact_area.collision_mask = 2
	interact_area.add_to_group("interactable")
	var icol := CollisionShape2D.new()
	var ic := CircleShape2D.new()
	ic.radius = 16.0
	icol.shape = ic
	interact_area.add_child(icol)
	add_child(interact_area)

	status_label = Label.new()
	status_label.visible = false
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-135, -42)
	status_label.custom_minimum_size = Vector2(270, 28)
	status_label.add_theme_font_size_override("font_size", 8)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68))
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 3)
	status_label.z_index = 20
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
	_craft_bar_bg.polygon = PackedVector2Array([
		Vector2(-20, -3), Vector2(20, -3), Vector2(20, 2), Vector2(-20, 2)
	])
	_craft_bar_root.add_child(_craft_bar_bg)

	_craft_bar_fill = Polygon2D.new()
	_craft_bar_fill.color = Color(0.98, 0.78, 0.24, 0.95)
	_craft_bar_fill.polygon = PackedVector2Array([
		Vector2(-19, -2), Vector2(-19, -2), Vector2(-19, 1), Vector2(-19, 1)
	])
	_craft_bar_root.add_child(_craft_bar_fill)

	_craft_bar_label = Label.new()
	_craft_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_craft_bar_label.position = Vector2(-80, -14)
	_craft_bar_label.custom_minimum_size = Vector2(160, 11)
	_craft_bar_label.add_theme_font_size_override("font_size", 7)
	_craft_bar_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	_craft_bar_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_craft_bar_label.add_theme_constant_override("outline_size", 2)
	_craft_bar_root.add_child(_craft_bar_label)

func _init_workshop_materials() -> void:
	_craft_progress = randf_range(5.0, 42.0)
	_supply_run_cooldown = randf_range(10.0, 34.0)
	match trade_role:
		TradeRole.BLACKSMITH:
			workshop_materials = {"wood": 1, "leather": 1}
		TradeRole.CARPENTER:
			workshop_materials = {"iron_ore": 1, "herbal_poultice": 1}
		TradeRole.BUTCHER:
			workshop_materials = {"wood": 1, "herbal_poultice": 1}
		TradeRole.HERBALIST:
			workshop_materials = {"bread": 1, "fertilizer": 1}
		TradeRole.FISHMONGER:
			workshop_materials = {"wood": 1, "herbal_poultice": 1}
		TradeRole.INNKEEPER:
			workshop_materials = {"cooked_meat": 1, "bread": 1}
		_:
			workshop_materials = {}

func _init_rimworld_psychology() -> void:
	match trade_role:
		TradeRole.INNKEEPER:
			traits = ["Hospitalaria", "Chef Apasionada"]
			favorite_item = "roasted_chicken"
			thoughts = ["Olor a pan recién horneado (+8)", "La posada está animada (+6)"]
		TradeRole.BUTCHER:
			traits = ["Fuerte", "Carnívoro"]
			favorite_item = "fox_pelt"
			thoughts = ["Buen corte de caza hoy (+6)"]
		TradeRole.BLACKSMITH:
			traits = ["Perfeccionista", "Forjador Maestro"]
			favorite_item = "iron_ore"
			thoughts = ["Fragua al rojo vivo (+8)", "Orgulloso de sus armaduras (+5)"]
		TradeRole.CARPENTER:
			traits = ["Trabajador", "Amante del Bosque"]
			favorite_item = "wood"
			thoughts = ["Madera de pino bien seca (+6)"]
		TradeRole.HERBALIST:
			traits = ["Naturista", "Pacífica"]
			favorite_item = "herbs"
			thoughts = ["Las plantas crecen sanas (+7)"]
		TradeRole.FISHMONGER:
			traits = ["Paciente", "Madrugador"]
			favorite_item = "night_catfish"
			thoughts = ["Brisa fresca junto al molino (+6)"]
		TradeRole.DOCTOR:
			traits = ["Cirujano Experto", "Forense Meticuloso"]
			favorite_item = "surgical_kit"
			thoughts = ["Urgencias y morgue en orden (+8)"]
		TradeRole.SHERIFF:
			traits = ["Justiciero", "Observador"]
			favorite_item = "cooked_meat"
			thoughts = ["Vigilando la ley en el valle (+7)"]
		TradeRole.GUARD:
			traits = ["Leal", "Alerta"]
			favorite_item = "bread"
			thoughts = ["Patrulla sin novedad (+6)"]
		TradeRole.TRAVELING_MERCHANT:
			traits = ["Mercader Real", "Portador de Salvoconducto"]
			favorite_item = "royal_ration"
			thoughts = ["Comerciando entre el valle y las Tierras Reales (+10)"]
		TradeRole.ROYAL_INVESTIGATOR:
			traits = ["Inquisidor Implacable", "Deducción Forense", "Nunca Vuelve Vacío"]
			favorite_item = "royal_ration"
			thoughts = ["La Corona exige un culpable (+12)"]
		_:
			var pool_traits: Array[String] = ["Alegre", "Tahúr", "Glotón", "Noctámbulo", "Amante de Animales", "Curioso", "Leal"]
			var idx1: int = abs(npc_name.hash()) % pool_traits.size()
			var idx2: int = (idx1 + 3) % pool_traits.size()
			traits = [pool_traits[idx1], pool_traits[idx2]]
			var fav_pool: Array[String] = ["bread", "cooked_meat", "roasted_chicken", "country_stew", "cooked_fish"]
			favorite_item = fav_pool[abs(npc_name.hash()) % fav_pool.size()]
			thoughts = ["Paseando por el valle (+5)"]
	mood = clampf(78.0 + randf_range(-6.0, 12.0), 40.0, 98.0)

func get_portrait_texture() -> Texture2D:
	if portrait_texture != null:
		return portrait_texture
	if sprite and sprite.texture != null:
		return sprite.texture
	return null

func get_character_tagline() -> String:
	return character_tagline

func _load_64_tex(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var t = load(res_path)
		if t is Texture2D:
			return t
	var abs_p := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_p):
		var img := Image.load_from_file(abs_p)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

func _resolve_unique_64_visuals_and_lore(fallback_tex: Texture2D = null) -> void:
	var key := "aldric"
	var clean_name := npc_name.strip_edges()

	match clean_name:
		"Thoran":
			key = "thoran"
			character_tagline = "Antiguo maestro armero de la Fundición Imperial de Vaelgard; desertó tras negarse a forjar grilletes de plomo para las cuencas mineras."
			character_lore = "«No siempre forjé herraduras y azadas, forastero. Durante veinte años dirigí los altos hornos de la guarnición de Vaelgard. La cicatriz que me cruza el pómulo me la dejó un crisol de bronce cuando saboteé mis propios moldes la noche antes de que marcharan contra los mineros de Cima Quebrada.\n\nHuí al sur con mi hijo Kael entre la ceniza, jurando no volver a templar una hoja que sirviera a un tirano... aunque en este valle el hierro vuelve a pedir sangre.»"
			character_secret = "«El Comisario Vane y yo nos conocemos de aquella guerra, aunque ambos fingimos que no cuando nos cruzamos en la plaza. Él perdió el ojo en el mismo asedio donde yo deserté. Quemó mi cartel de búsqueda porque sabe que este valle necesita mi yunque más que otra soga en el patíbulo.»"
		"Kael":
			key = "kael"
			character_tagline = "Aprendiz de forja obsesionado con descifrar las bobinas y conductos de tecnología antigua enterrados bajo las ruinas del oeste."
			character_lore = "«Mi padre cree que el acero solo sirve para protegerse o arar la tierra, pero bajo este valle hay conductos de cobre y generadores que no forjó ningún herrero común.\n\nCuando cae la noche y Thoran duerme, estudio los fragmentos que los viajeros traen de la Llanura Salvaje. No quiero pasar mi vida reparando rejas; quiero entender qué civilización levantó las máquinas que aún laten bajo la roca.»"
			character_secret = "«Le he estado comprando reliquias y bobinas en secreto a Aldric en la posada. Si mi padre descubre que enciendo la fragua de madrugada para ensayar aleaciones antiguas, me quitará las llaves del taller.»"
		"Garrick":
			key = "garrick"
			character_tagline = "Único superviviente de una expedición de tramperos sepultada en el Paso del Aullido; conoce la anatomía de cada bestia del bosque."
			character_lore = "«La gente del pueblo me mira las manos manchadas y piensa que disfruto con el cuchillo. No saben lo que es pasar cuarenta días atrapado por un alud en las cumbres del norte, viendo apagarse a tu cuadrilla uno tras otro.\n\nAprendí a desollar y aprovechar hasta el último hueso y tendón porque el desperdicio en la frontera se paga con la muerte. Aquí cada corte mío mantiene vivo al valle.»"
			character_secret = "«El Dr. Valen acude a veces por la puerta trasera cuando cierro la carnicería. No busca carne para cenar: me pide huesos limpios y articulaciones para sus estudios anatómicos en la Morgue. Yo no hago preguntas, y él me cose cuando un jabalí me embiste en el bosque.»"
		"Lina":
			key = "lina"
			character_tagline = "Cartógrafa autodidacta y maestra curtidora llegada de las estepas de sal; traza mapas de las sendas de caza en el reverso del cuero."
			character_lore = "«Antes de casarme con Garrick, viajaba con las caravanas que cruzaban los pantanos orientales. Allí aprendí que un buen jubón de cuero curado con corteza de roble salva más vidas que una coraza pesada que te hunde en el barro.\n\nEn los recortes de piel que descarto llevo el mapa de las manadas del bosque sur: sé cuándo escasean los ciervos y cuándo bajan los zorros hambrientos hacia los corrales.»"
			character_secret = "«Todavía oigo a Garrick hablar entre sueños sobre el invierno en que perdió a su antigua cuadrilla en la montaña. Nunca pronuncia el nombre del explorador que los dejó atrás... pero siempre aprieta el cuchillo cuando Aldric entra en la taberna.»"
		"Bram":
			key = "bram"
			character_tagline = "Arquitecto gremial exiliado de la capital tras el derrumbe del Gran Teatro, donde un intendente corrupto sustituyó su roble por madera podrida."
			character_lore = "«Cada viga, cada puerta y cada umbral que ves en esta aldea pasó por mis manos. En la capital me cargaron la culpa cuando cedió la cúpula del teatro real: el intendente se embolsó el oro del roble curado y compró pino húmedo, pero fui yo quien pagó con su nombre.\n\nPor eso aquí levanto casas con muros de piedra y maderas que ni un vendaval ni una patrulla puedan derribar sin sudar sangre.»"
			character_secret = "«Le diseñé a cada edificio del pueblo un postigo lateral con bisagras ocultas. Llámalo manía de un constructor que conoció los calabozos de la corte: nunca me gustó levantar cuatro paredes de las que un hombre acorralado no pudiera escapar.»"
		"Mila":
			key = "mila"
			character_tagline = "Ebanista de precisión y maestra cerrajera; vendió sus herramientas de plata en la ciudad para pagar la fianza de su hermano Bram."
			character_lore = "«Bram levanta paredes; yo me ocupo de lo que guarda secretos: cerraduras de muelle, cofres de doble fondo y muebles ensamblados sin un solo clavo.\n\nEn la capital tallaba clavicordios para la nobleza, pero cuando hundieron a mi hermano en aquel juicio amañado, malvendí mi taller para sacarlo de la celda y vinimos a empezar de cero entre los pinos.»"
			character_secret = "«Todos los cofres domésticos de las casas del pueblo llevan mi sello. Tienen un fiador interno que cede en silencio si te acercas agachado y con pulso firme... pero si alguien intenta abrirlos a plena vista, el trinquete suena como una campana.»"
		"Marlo":
			key = "marlo"
			character_tagline = "Antiguo timonel del bergantín contrabandista 'La Estrella Hundida'; cambió el mar abierto por el sosiego del lago y la rueda del molino."
			character_lore = "«Este aro de oro en mi oreja es lo único que saqué a flote cuando *La Estrella Hundida* se partió contra los escollos del Cabo Gris. Navegué quince años burlando bloqueos navales con sacos de trigo y barriles de pólvora.\n\nCuando la resaca me escupió en la playa, juré que no volvería a echar el ancla en aguas donde no pudiera ver la otra orilla. Ahora el rumor del molino y las truchas del lago me bastan.»"
			character_secret = "«En las mañanas de niebla cerrada, cuando bajo al muelle antes de las siete, he visto fogatas apagándose hacia la Ciénaga de las Ranas. Esos bandidos de las ruinas no acampan ahí por azar: desentierran conductos del viejo mundo.»"
		"Nora":
			key = "nora"
			character_tagline = "Redera y cronista silenciosa del valle; registra en nudos marineros de cáñamo los movimientos y ausencias de cada habitante."
			character_lore = "«Mi padre Marlo me enseñó el código de cuerdas que usaban los contrabandistas del sur para llevar bitácoras sin escribir una sola letra que pudiera incriminarlos.\n\nMientras remiendo las redes frente a la pescadería, mis dedos atan nudos por cada persona que cruza la plaza. La gente cree que solo miro secarse el lino, pero sé quién duerme en su cama y quién camina de noche.»"
			character_secret = "«Hace tres noches vi a Sora, la forastera de la posada, medir los pasos entre la parte trasera de la herrería y el camino del este. Juega a parecer una simple apostadora, pero calcula las rutas de salida mejor que el propio guardia.»"
		"Elena":
			key = "elena"
			character_tagline = "Ex-catedrática del Colegio Botánico de Ámbar; quemó sus tratados y huyó cuando el consejo militar quiso convertir sus sedantes en venenos."
			character_lore = "«La diferencia entre un bálsamo que devuelve el aliento y un alcaloide que apaga la memoria es apenas media gota en el alambique. En la academia de Ámbar pretendían que mis destilados de espora azul se usaran en los interrogatorios de Estado.\n\nQuemé mis notas esa misma madrugada, recogí mis semillas madre y vine con Tomás a este valle, donde mis cataplasmas solo sirven para cerrar heridas.»"
			character_secret = "«Mi Somnífero Nocturno está destilado con raíz de sueño y hongos de los claros del sur. Si algún día necesitas silenciar a un testigo o dormir a un centinela sin mancharte las manos de sangre, cuarenta segundos de mi frasco bastan para cruzar cualquier puerta.»"
		"Tomás":
			key = "tomas"
			character_tagline = "Agrónomo paciente y estudioso del microclima del valle; logró fertilizar las tierras ácidas de la frontera mezclando ceniza de forja y compost."
			character_lore = "«Cuando Elena y yo llegamos, esta tierra era grava fría donde ni el cardo agarraba. Tardé tres años mezclando escoria mineral de la fragua de Thoran con mantillo de hojas del bosque hasta lograr que las coles y el trigo dieran cosechas dobles.\n\nLa tierra es como la gente del pueblo: si la fuerzas con hierro se cierra, pero si entiendes su ciclo te alimenta toda la vida.»"
			character_secret = "«He estudiado las lluvias de este valle durante años: cuando cae el aguacero, no solo riega cada surco sin esfuerzo, sino que el golpeteo del agua sobre los tejados apaga el sonido de las pisadas en toda la aldea.»"
		"Marta":
			key = "marta"
			character_tagline = "Dama de hierro de 'El Jabalí Dorado'; ganó la escritura de la Posada hace diez años en una mano legendaria de póker contra un barón minero."
			character_lore = "«Muchos entran por mi estofado campesino o por el pollo recién asado, pero el verdadero corazón de esta casa late sobre el paño verde del salón. Antes de que llegaran el médico y el comisario, esta posada era una posta sin ley donde se apostaban minas enteras.\n\nLe gané la propiedad de este edificio a su antiguo dueño con un full de ases a medianoche. Desde entonces puse dos reglas sagradas: aquí dentro nadie pasa hambre si tiene moneda, y mientras las cartas están en la mesa hasta el tiempo parece detenerse.»"
			character_secret = "«Desde la barra veo cómo respira cada jugador en el casino: hay quien parpadea de más por puro nervio aunque lleve escalera, y quien mantiene rostro de piedra con un dos y un siete. Aprende a leer a la persona, no solo sus cartas.»"
		"Dr. Valen", "Dra. Valeria", "Dr. Silvano":
			key = "valen"
			character_tagline = "Cirujano de mente analítica expulsado del anfiteatro médico de la capital por practicar autopsias forenses prohibidas por la nobleza."
			character_lore = "«En los salones de la capital, la medicina consistía en adular a duques hipocondríacos mientras prohibían abrir un cuerpo para investigar un asesinato. Yo vine a la frontera porque aquí la verdad no se esconde tras cortinas de seda.\n\nHe dividido mi hospital en dos mundos: en la sala norte salvo a todo aquel que aún conserve un hilo de pulso; en las losas de la Morgue del sur, dejo que las heridas y el rigor mortis dicten sentencia.»"
			character_secret = "«Mis bisturíes pueden determinar el arma exacta y cuántas horas o días lleva un cuerpo descomponiéndose, pero la ciencia forense tiene un límite: sin un testigo que te haya visto entrar o salir del edificio, el expediente quedará como un crimen perfecto sin autor.»"
		"Comisario Vane", "Comisario Thorne", "Inspectora Lyra":
			key = "vane"
			character_tagline = "Veterano inspector de frontera que perdió el ojo izquierdo en el motín de Cima Quebrada; aplica la ley con pragmatismo implacable."
			character_lore = "«Dejé los tribunales del norte porque me cansé de colgar a hambrientos mientras los intendentes robaban a manos llenas. En mi comisaría la ley no distingue cunas: si cometes un delito a la vista de un vecino o las pruebas de la Morgue te señalan, te doy la oportunidad de rendirte o pagar tu deuda.\n\nSi entregas las manos, te escolto vivo a la celda y al cantar el gallo sales libre. Pero si desenfundas contra mis hombres, mi revólver habla primero.»"
			character_secret = "«Cuando sube el número de robos o aparecen cadáveres sin resolver, ordeno a todas las familias que echen la llave temprano y cierren los postigos. Un pueblo asustado es un pueblo cerrado a cal y canto.»"
		"Guardia Rodric", "Guardia Kaelen", "Centinela Bastian":
			key = "rodric"
			character_tagline = "Joven centinela cuya granja familiar en la Llanura Oeste fue arrasada por los bandidos; patrulla las calles para que la historia no se repita."
			character_lore = "«¿Ves las ruinas de piedra al noroeste de la ciénaga? Ese era el granero de mis padres antes de que llegara la banda del oeste. Yo tenía doce años cuando escapamos hacia este valle.\n\nEl Comisario Vane me dio un yelmo y una porra reglamentaria, y me enseñó a mirar los callejones antes de doblar cada esquina. Mientras yo haga la ronda, nadie volverá a quemar una casa en esta aldea.»"
			character_secret = "«Los muros de piedra y las puertas cerradas nos impiden ver lo que ocurre dentro de los locales desde la calle. Por eso cuando la niebla baja del bosque, redoblamos la atención en las entradas.»"
		"Aldric":
			key = "aldric"
			character_tagline = "Ex-batidor militar reconvertido en buscador de reliquias y jugador de ventaja; espera la ocasión de hacerse con un taller propio."
			character_lore = "«Llevo el broche de mi antiguo regimiento escondido bajo la capa porque en las fronteras hacer demasiadas preguntas sobre el pasado acorta la vida. Oficialmente soy un huésped más de la posada que vive de sus ahorros y de alguna buena racha al blackjack.\n\nEn realidad, exploro las ruinas del oeste buscando piezas del viejo mundo... aunque si algún gremio del pueblo queda vacante, tengo manos de sobra para tomar el relevo.»"
			character_secret = "«He visto cómo funcionan los negocios aquí: cuando un taller sufre un 'accidente' en su maquinaria y se queda sin género, los precios se disparan al doble y el dueño está tan desesperado que vendería la escritura por un puñado de monedas.»"
		"Sora":
			key = "sora"
			character_tagline = "Tahúr de los barcos fluviales del sur y tasadora de arte; se refugió en el valle tras vaciarle los bolsillos al magistrado de Puerto Real."
			character_lore = "«En los salones flotantes del río Grande aprendí dos cosas: nunca apuestes contra quien reparte si no has contado las cartas que ya salieron, y nunca te quedes en la misma ciudad después de ganarle el carruaje a un juez.\n\nEste valle parecía un escondite aburrido al principio, pero entre las intrigas de las cinco familias y la mesa de Marta, te aseguro que aquí se mueve más oro del que aparentan sus calles de tierra.»"
			character_secret = "«Si te conviertes en socio o dueño de una tienda del pueblo y abasteces tú mismo el mostrador, cada vez que los vecinos vayan a cenar estarás llenando tu propia caja registradora sin mover un dedo.»"
		"Darío":
			key = "dario"
			character_tagline = "Antiguo capataz de cantera despedido por priorizar la vida de sus mineros sobre la cuota de extracción; busca un oficio digno en el pueblo."
			character_lore = "«Treinta hombres salieron vivos del pozo de Peñanegra gracias a que di la campana de evacuación diez minutos antes de que reventara la bóveda de agua. La compañía minera me agradeció el gesto poniéndome en la calle por 'pérdida de herramientas'.\n\nAhora alquilo una cama en el ala norte de la posada. No me asusta el trabajo duro: el día que falte un maestro en cualquier taller de la aldea, yo mismo levantaré el oficio.»"
			character_secret = "«Los maestros artesanos salen al bosque cada mañana a las 06:30 en punto a talar, picar o cazar su materia prima. Pero si la fauna o los árboles bajan del límite de equilibrio del bosque, regresan con las manos vacías y sus tiendas entran en escasez.»"
		"Maese Casimir":
			key = "casimir"
			character_tagline = "Intendente de la Liga Minera del Norte; porta un Salvoconducto Real para cruzar la frontera una vez por semana y comprar herramientas manufacturadas."
			character_lore = "«Este valle parece el fin del mundo, pero el hierro y la madera curada que trabajan Thoran y Bram superan con creces lo que sale de las fundiciones reales. Cada semana cruzo el Paso del Sur con escolta en la frontera y mi Salvoconducto Real lacrado en el pecho.\n\nSolo compro lo que realmente necesito: herramientas, lingotes, bobinas y tablones para las minas del norte. Sin el oro que inyecto en vuestros talleres, esta aldea acabaría devorándose a sí misma.»"
			character_secret = "«Nadie sale de esta región sin un Salvoconducto Real firmado por la Cancillería. Pero cuidado con codiciar mi sello: si un intendente de la Corona desaparece en este valle, la capital suspenderá las rutas durante un mes entero y enviará al Inquisidor Real.»"
		"Valeria la Tratante":
			key = "valeria"
			character_tagline = "Tratante de Caza y Pieles de las Tierras Reales; acude una vez por semana con Salvoconducto Real a comprar legalmente pieles y carne del valle."
			character_lore = "«En las Tierras Reales del norte cazar un ciervo o un zorro se paga con la horca: todos los bosques pertenecen a la Corona. Pero como esta región está tan apartada y a la capital le cuesta demasiado enviar suministros, el Rey hace la vista gorda y os permite cazar para sobrevivir.\n\nPor eso vengo cada semana con mi Salvoconducto Real: aquí compro legalmente vuestras pieles, astas, cueros y piezas de caza para revenderlas a precio de oro en los salones de extramuros.»"
			character_secret = "«Traigo conmigo Conservas Reales de Extramuros que no se pudren jamás. Nunca gasto todo mi oro de golpe: compro solo las pieles y carnes que están bien cortadas; los despieces torpes de aficionados no valen ni el barro que pisan.»"
		"Inquisidor Real Alistair":
			key = "alistair"
			character_tagline = "Alto Magistrado e Inquisidor de la Corona; enviado desde la capital para hallar y condenar a un culpable tras el asesinato de un mercader real."
			character_lore = "«No soy un comisario rural como Vane. Cuando un portador de Salvoconducto Real cae asesinado en la frontera, la Cancillería me envía con plenos poderes de vida y muerte.\n\nInterrogo a cada vecino, cruzo coartadas hora por hora, examino las heridas forenses y registro quién merodeaba la escena. Y ten algo muy claro, forastero: un Inquisidor Real jamás regresa a la capital con las manos vacías. Cuando termine mi expediente, alguien pagará con su cuello.»"
			character_secret = "«Mi filosofía es el orden absoluto de la Corona: si las pruebas señalan sin duda al asesino, lo ejecutaré yo mismo; pero si el verdadero criminal ocultó sus rastros, condenaré al aldeano sin coartada que acumule mayor probabilidad. La Corona exige un culpable, no excusas.»"
		_:
			var fem: bool = clean_name.ends_with("a")
			match trade_role:
				TradeRole.DOCTOR:
					key = "valen"
					character_tagline = "Médico forense y cirujano rural enviado por el Colegio Médico para mantener operativo el Hospital y la Morgue del valle."
				TradeRole.SHERIFF:
					key = "vane"
					character_tagline = "Comisario de frontera designado para restablecer la ley, investigar crímenes y dirigir las patrullas del valle."
				TradeRole.GUARD:
					key = "rodric"
					character_tagline = "Centinela de guardia asignado a la comisaría local para vigilar las calles, entradas y comercios de la aldea."
				TradeRole.INNKEEPER:
					key = "marta"
					character_tagline = "Regente de 'El Jabalí Dorado'; sirve platos calientes y administra las mesas de juego del salón."
				TradeRole.BLACKSMITH:
					key = "kiera" if fem else "thoran"
					character_tagline = "Maestro forjador llegado de los valles vecinos para mantener encendida la fragua y abastecer de herramientas al pueblo."
				TradeRole.BUTCHER:
					key = "lina" if fem else "garrick"
					character_tagline = "Cazador y maestro carnicero encargado de abastecer de carne fresca y cuero curado a la aldea."
				TradeRole.CARPENTER:
					key = "mila" if fem else "bram"
					character_tagline = "Maestro ebanista y carpintero llegado para mantener en pie el aserradero y los talleres locales."
				TradeRole.FISHMONGER:
					key = "nora" if fem else "marlo"
					character_tagline = "Pescador y molinero encargado de las redes del lago y de la molienda de grano para el valle."
				TradeRole.HERBALIST:
					key = "elena" if fem else "tomas"
					character_tagline = "Herborista y botánico rural dedicado al cultivo de semillas y a la preparación de cataplasmas medicinales."
				TradeRole.FAMILY_MEMBER, TradeRole.UNEMPLOYED:
					key = "sora" if fem else "aldric"
					character_tagline = "Viajero independiente recién llegado a la frontera en busca de fortuna y de un oficio estable en el valle."
				_:
					key = "mila" if fem else "bram"
					character_tagline = "Artesano profesional llegado de los valles vecinos para hacerse cargo del taller y mantener viva la economía local."
			character_lore = "«Llegué al valle tras escuchar que la comunidad necesitaba manos expertas. No vengo a hacer preguntas sobre lo que le ocurrió a mi predecesor: mientras haya trabajo y corra el oro, cumpliré mi jornada de sol a sol.»"
			character_secret = "«En este pueblo las paredes oyen y las puertas cerradas guardan más de un secreto. Conviene llevarse bien con los vecinos si quieres prosperar aquí.»"

	var anim_64 := _load_64_tex("res://assests/world/village/npcs_64/anim_%s.png" % key)
	var spr_64 := _load_64_tex("res://assests/world/village/npcs_64/sprite_%s.png" % key)
	var port_64 := _load_64_tex("res://assests/world/village/npcs_64/portrait_%s.png" % key)
	if anim_64 != null and sprite != null:
		sprite.texture = anim_64
		sprite.hframes = 4
		sprite.vframes = 3
		sprite.frame = 0
		_has_spritesheet_anim = true
	elif spr_64 != null and sprite != null:
		sprite.texture = spr_64
		sprite.hframes = 1
		sprite.vframes = 1
		_has_spritesheet_anim = false
	elif fallback_tex != null and sprite != null:
		sprite.texture = fallback_tex
		sprite.hframes = 1
		sprite.vframes = 1
		_has_spritesheet_anim = false
	portrait_texture = port_64 if port_64 != null else (spr_64 if spr_64 != null else fallback_tex)

func add_thought(thought_text: String, mood_delta: float) -> void:
	if thoughts.has(thought_text):
		thoughts.erase(thought_text)
	thoughts.push_front(thought_text)
	while thoughts.size() > 3:
		thoughts.pop_back()
	mood = clampf(mood + mood_delta, 0.0, 100.0)

var _pre_poker_pos: Vector2 = Vector2.ZERO

func set_poker_seating(active: bool, seat_world_pos: Vector2 = Vector2.ZERO) -> void:
	_is_actively_crafting = false
	if _craft_bar_root:
		_craft_bar_root.visible = false
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
	_is_actively_crafting = false
	if _craft_bar_root:
		_craft_bar_root.visible = false
	sedated_timer = maxf(sedated_timer, duration)
	is_sleeping = true
	is_hostile = false
	remove_from_group("enemies")
	if body_col:
		body_col.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	if sprite:
		sprite.rotation_degrees = 90.0
		sprite.modulate = Color(0.68, 0.58, 1.0, 0.95)
	add_thought("Sedado por un somnífero (-6)", -6.0)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if is_dead:
		velocity = Vector2.ZERO
		_is_actively_crafting = false
		if _craft_bar_root:
			_craft_bar_root.visible = false
		_process_corpse_state(delta)
		return

	# Paso 1: Estado "Agonizando" (`is_downed`) antes de morir definitivamente
	if is_downed:
		velocity = Vector2.ZERO
		_is_actively_crafting = false
		if _craft_bar_root:
			_craft_bar_root.visible = false
		bleedout_timer -= delta
		if sprite:
			sprite.rotation_degrees = 82.0
			var pulse_r: float = 0.65 + absf(sin(bleedout_timer * 4.0)) * 0.35
			sprite.modulate = Color(1.15, pulse_r * 0.45, pulse_r * 0.45, 0.95)
		if status_label:
			status_label.text = "🩸 %s — ¡AGONIZANDO! (%ds)\n[E: Salvar y llevar al Hospital | Atacar: Rematar]" % [npc_name, maxi(1, int(ceil(bleedout_timer)))]
			status_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
			status_label.visible = true
		if bleedout_timer <= 0.0:
			_confirm_true_death()
		return

	# Paso 8: Estado dormido por Somnífero Nocturno (`sleeping_draught`) o Aturdido en Sigilo (`stealth_knockout`)
	if sedated_timer > 0.0:
		sedated_timer -= delta
		velocity = Vector2.ZERO
		_is_actively_crafting = false
		if _craft_bar_root:
			_craft_bar_root.visible = false
		is_sleeping = true
		if status_label:
			var loot_hint_s: String = ""
			if not corpse_pocket_looted and (personal_gold > 0 or carries_royal_safe_conduct):
				var seal_tag: String = " + 📜 Salvoconducto Real" if carries_royal_safe_conduct else ""
				loot_hint_s = "\n[E: 💰 Saquear Bolsillos (%d Oro%s)]" % [maxi(0, personal_gold), seal_tag]
			status_label.text = "💤 %s — Inconsciente / Dormido (%ds)%s" % [npc_name, maxi(1, int(ceil(sedated_timer))), loot_hint_s]
			status_label.add_theme_color_override("font_color", Color(0.78, 0.65, 1.0))
			status_label.visible = true
		if sedated_timer <= 0.0:
			is_sleeping = false
			is_stunned_flag = false
			if sprite:
				sprite.rotation_degrees = 0.0
				sprite.modulate = Color.WHITE
		return

	if is_stunned_flag:
		velocity = Vector2.ZERO
		_is_actively_crafting = false
		if _craft_bar_root:
			_craft_bar_root.visible = false
		if status_label:
			var loot_hint_st: String = ""
			if not corpse_pocket_looted and (personal_gold > 0 or carries_royal_safe_conduct):
				var seal_tag2: String = " + 📜 Salvoconducto Real" if carries_royal_safe_conduct else ""
				loot_hint_st = "\n[E: 💰 Saquear Bolsillos (%d Oro%s)]" % [maxi(0, personal_gold), seal_tag2]
			status_label.text = "💫 %s — Aturdido%s" % [npc_name, loot_hint_st]
			status_label.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
			status_label.visible = true
		return

	# Si está sentado jugando Póker/Billar o el reloj está congelado por minijuego, no drenar necesidades ni romper rutina
	if is_at_poker_table:
		if poker_seat_pos != Vector2.ZERO and global_position.distance_to(poker_seat_pos) > 3.0:
			global_position = poker_seat_pos
		velocity = Vector2.ZERO
		_is_actively_crafting = false
		if _craft_bar_root:
			_craft_bar_root.visible = false
		_update_visual_animation(delta)
		_update_hover_label()
		return

	if WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen():
		velocity = Vector2.ZERO
		_update_hover_label()
		return

	if body_col:
		body_col.disabled = not is_hostile

	if not is_instance_valid(_cached_vm):
		_cached_vm = get_tree().get_first_node_in_group("village_manager")
	if not is_instance_valid(_cached_player):
		_cached_player = get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(_cached_dm) and get_tree().current_scene:
		_cached_dm = get_tree().current_scene.get_node_or_null("Systems/dialogue_manager")

	# Si el jugador está hablando con este NPC, detener inmediatamente cualquier caminata o trabajo y atender al jugador
	if not is_hostile and is_instance_valid(_cached_dm) and bool(_cached_dm.get("active")) and _cached_dm.get("current_speaker") == self:
		velocity = Vector2.ZERO
		_is_actively_crafting = false
		if _craft_bar_root:
			_craft_bar_root.visible = false
		if is_instance_valid(_cached_player) and sprite:
			sprite.flip_h = (_cached_player.global_position.x < global_position.x)
		trigger_action_animation(0.4)
		_update_visual_animation(delta)
		_update_hover_label(delta)
		return

	# Si el Inquisidor Real Alistair está interrogando a este NPC, detenerse y responder sus preguntas sin irse caminando
	if _being_interviewed_timer > 0.0 and not is_hostile:
		_being_interviewed_timer = maxf(0.0, _being_interviewed_timer - delta)
		velocity = Vector2.ZERO
		_is_actively_crafting = false
		if _craft_bar_root:
			_craft_bar_root.visible = false
		if is_instance_valid(_interviewer_node) and sprite:
			sprite.flip_h = (_interviewer_node.global_position.x < global_position.x)
		trigger_action_animation(0.4)
		_update_visual_animation(delta)
		_update_hover_label(delta)
		return

	var vm_escort = _cached_vm
	# Paso 2b: Si este agente policial está escoltando físicamente al jugador esposado hacia la celda de la Comisaría (Kenshi / RDR2)
	if vm_escort and bool(vm_escort.get("player_being_escorted_to_jail")) and vm_escort.get("escorting_officer") == self:
		var jail_target: Vector2 = vm_escort.get("_jail_cell_pos") if "_jail_cell_pos" in vm_escort else Vector2(886, 172)
		_move_towards_point(jail_target, 64.0, delta)
		move_and_slide()
		_update_visual_animation(delta)
		_update_hover_label(delta)
		return

	# Paso 1: El Dr. Valen acude de urgencia SOLO si ve directamente a un NPC agonizando (con línea de visión) o si está dentro del Hospital
	if trade_role == TradeRole.DOCTOR and not is_hostile:
		_doctor_scan_timer -= delta
		if not is_instance_valid(_active_downed_patient) or not _active_downed_patient.is_downed or _active_downed_patient.is_dead:
			_active_downed_patient = null
			if _doctor_scan_timer <= 0.0:
				_doctor_scan_timer = 0.25
				_active_downed_patient = _find_downed_npc()
		if _active_downed_patient != null:
			var dist_d: float = global_position.distance_to(_active_downed_patient.global_position)
			var doc_spd: float = 68.0 * lerpf(0.72, 1.0, get_job_efficiency())
			if dist_d > 22.0:
				_move_towards_point(_active_downed_patient.global_position, doc_spd, delta)
				move_and_slide()
				_update_visual_animation(delta)
				_update_hover_label(delta)
				return
			else:
				_active_downed_patient.revive_from_downed(self, false)
				_spawn_floating_text("🩺 ¡%s estabilizó a %s!" % [npc_name, _active_downed_patient.npc_name], Color.SPRING_GREEN, -42.0)
				_active_downed_patient = null
				return

	# Paso 1b: Si este aldeano fue testigo del hallazgo de un cadáver, corre físicamente a reportarlo al Médico o a la Guardia (Hitman / Streets of Rogue)
	if not is_hostile and _process_witness_corpse_reporting(delta):
		return

	# Paso 1c: Traslado físico de cadáveres YA REPORTADOS hasta la Morgue del Hospital
	if not is_hostile and _process_corpse_morgue_transport(delta):
		return

	# Paso 2: Comisario Vane y Guardia Rodric (Negociación -> Persecución con Pistola a distancia y Porra de cerca, bloqueando visión por paredes)
	if trade_role in [TradeRole.SHERIFF, TradeRole.GUARD]:
		var vm = _cached_vm
		if vm and (int(vm.get("wanted_level")) > 0 or bool(vm.get("is_resisting_arrest")) or is_hostile) and not bool(vm.get("player_in_jail")) and not bool(vm.get("player_being_escorted_to_jail")):
			if _process_police_law_enforcement(delta, vm):
				return

	# Paso 2c: Inquisidor Real Alistair (Investigación Deductiva + Filosofía de Culpable Obligatorio)
	if trade_role == TradeRole.ROYAL_INVESTIGATOR:
		if is_hostile:
			_police_alerted_timer = maxf(_police_alerted_timer, 25.0)
			if is_instance_valid(_cached_player):
				_last_seen_player_pos = _cached_player.global_position
		_process_royal_investigator_ai(delta)
		return

	# Paso 2d: Comerciantes Semanales de Extramuros (Maese Casimir / Valeria la Tratante)
	if trade_role == TradeRole.TRAVELING_MERCHANT and not is_hostile:
		_process_traveling_merchant_routine(delta)
		return

	if is_hostile:
		_process_hostile_combat(delta)
		move_and_slide()
		return

	_update_needs_and_decisions(delta)

	# Paso 1: Si un NPC sufre heridas (`HP < 75%`) y NO está muriendo de hambre (`need_hunger > 5%`), camina hacia la Sala de Urgencias del Hospital (`Vector2(718, 136)`) para curarse
	if health_comp and health_comp.current_health < health_comp.max_health * 0.75 and need_hunger > 5.0:
		if is_sleeping:
			is_sleeping = false
			if sprite:
				sprite.rotation_degrees = 0.0
		if _craft_bar_root:
			_craft_bar_root.visible = false
		var hosp_bed_pos := Vector2(718, 136)
		if global_position.distance_to(hosp_bed_pos) > 18.0:
			_move_towards_point(hosp_bed_pos, 46.0, delta)
		else:
			velocity = Vector2.ZERO
			health_comp.heal(12.0 * delta)
			if health_comp.current_health >= health_comp.max_health - 0.5:
				_spawn_floating_text("🏥 Curado en el Hospital (+Salud)", Color.SPRING_GREEN, -36.0)
		move_and_slide()
		_update_visual_animation(delta)
		_update_hover_label(delta)
		return

	_execute_dynamic_activity(delta)
	_apply_player_and_doorway_yield(delta)
	move_and_slide()
	_update_visual_animation(delta)
	_update_hover_label(delta)

## Gestiona un cadáver en el suelo: se pudre con el paso de las horas/días hasta que otro NPC lo vea en su rutina natural (con línea de visión)
## o el jugador lo reporte con [E]. El Dr. Valen NO sabe que alguien murió hasta que el cadáver sea físicamente reportado.
func _process_corpse_state(delta: float) -> void:
	if corpse_in_morgue or not corpse_on_ground:
		return

	# Si está siendo cargado físicamente hacia la Morgue por el Dr. Valen o un vecino/guardia
	if corpse_being_carried:
		if is_instance_valid(corpse_carrier) and not corpse_carrier.is_dead and not corpse_carrier.is_downed and not corpse_carrier.is_stunned_flag and corpse_carrier.sedated_timer <= 0.0 and not corpse_carrier.is_sleeping and not corpse_carrier.is_hostile:
			global_position = corpse_carrier.global_position + Vector2(0, -8)
		else:
			if is_instance_valid(corpse_carrier) and corpse_carrier._carrying_corpse_target == self:
				corpse_carrier._carrying_corpse_target = null
			corpse_being_carried = false
			corpse_carrier = null
	else:
		# Avance suave de descomposición en tiempo real (además de los saltos de hora del reloj)
		corpse_rot_hours += delta / 65.0

	if sprite:
		sprite.visible = true
		sprite.rotation_degrees = 90.0
		if corpse_rot_hours < 12.0:
			sprite.modulate = Color(0.68, 0.54, 0.54, 0.96)
		elif corpse_rot_hours < 24.0:
			sprite.modulate = Color(0.54, 0.60, 0.46, 0.96)
		else:
			# Cadáver pudriéndose tras 1, 2 o 3+ días sin ser recogido
			sprite.modulate = Color(0.38, 0.56, 0.30, 0.96)

	_corpse_scan_timer -= delta
	if _corpse_scan_timer > 0.0:
		return
	_corpse_scan_timer = 0.25

	if not is_instance_valid(_cached_vm):
		_cached_vm = get_tree().get_first_node_in_group("village_manager")
	var vm = _cached_vm
	# Descubrimiento natural: solo cuando otro NPC consciente pase a <= 105 px Y tenga línea de visión directa (sin paredes de por medio)
	if not corpse_reported:
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC and n != self:
				var other := n as VillageNPC
				if other.is_dead or other.is_downed or other.is_sleeping or other.is_stunned_flag or other.sedated_timer > 0.0:
					continue
				if other.global_position.distance_to(global_position) <= 105.0:
					var has_los: bool = (vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", other.global_position, global_position))
					if has_los:
						if not corpse_discovered:
							corpse_discovered = true
							corpse_discovered_by = other.npc_name
							other.add_thought("Descubrió el cadáver de %s (-15)" % npc_name, -15.0)
						if other.trade_role in [TradeRole.DOCTOR, TradeRole.SHERIFF, TradeRole.GUARD]:
							corpse_reported = true
							corpse_reporter_npc = null
							_spawn_floating_text("🚨 ¡%s encontró el cadáver de %s!" % [other.npc_name, npc_name], Color.ORANGE_RED, -42.0)
							break
						elif corpse_reporter_npc == null or not is_instance_valid(corpse_reporter_npc) or corpse_reporter_npc.is_dead or corpse_reporter_npc.is_downed:
							corpse_reporter_npc = other
							other._reporting_corpse_target = self
							_spawn_floating_text("😱 ¡%s vio el cadáver de %s y corre a avisar!" % [other.npc_name, npc_name], Color.ORANGE_RED, -42.0)
							break

	if status_label:
		if not is_instance_valid(_cached_player):
			_cached_player = get_tree().get_first_node_in_group("player") as Node2D
		var player = _cached_player
		var near_p: bool = player != null and global_position.distance_squared_to(player.global_position) <= 44.0 * 44.0
		var near_m: bool = global_position.distance_squared_to(get_global_mouse_position()) <= 28.0 * 28.0
		if near_p or near_m or corpse_being_carried:
			var rot_days: int = int(floor(corpse_rot_hours / 24.0))
			var rot_rem_h: int = int(floor(corpse_rot_hours)) % 24
			var state_line: String = ""
			var loot_tag: String = ""
			if not corpse_pocket_looted and (personal_gold > 0 or carries_royal_safe_conduct):
				loot_tag = " | [E: 💰 Saquear Bolsillos (%d Oro%s)]" % [personal_gold, " + 📜Salvoconducto Real" if carries_royal_safe_conduct else ""]
			if corpse_being_carried and is_instance_valid(corpse_carrier):
				state_line = "⚰️ Trasladando cuerpo a la Morgue (Llevado por %s)%s" % [corpse_carrier.npc_name, loot_tag]
			elif corpse_reported:
				state_line = "🚨 Reportado por %s — En espera de traslado a la Morgue%s" % [corpse_discovered_by, loot_tag]
			elif corpse_discovered and is_instance_valid(corpse_reporter_npc):
				state_line = "🏃 %s corre a reportarlo%s | [E: 📢 Reportar tú mismo]" % [corpse_reporter_npc.npc_name, loot_tag]
			elif rot_days >= 1:
				state_line = "🦠🪰 PUDRIÉNDOSE EN EL LUGAR (%d días, %dh)%s | [E: 📢 Reportar Cadáver]" % [rot_days, rot_rem_h, loot_tag]
			else:
				state_line = "🩸 Cadáver en el suelo (%dh)%s | [E: 📢 Reportar Cadáver]" % [rot_rem_h, loot_tag]
			status_label.text = "💀 Cadáver de %s (%s)\n[%s]" % [npc_name, npc_role, state_line]
			status_label.add_theme_color_override("font_color", Color(0.72, 0.96, 0.62) if rot_days >= 1 else Color(0.92, 0.55, 0.55))
			status_label.visible = true
		else:
			status_label.visible = false

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
	_spawn_floating_text("📢 ¡Reportaste el cadáver de %s! El Dr. Valen / la guardia acudirá a recogerlo." % npc_name, Color.GOLD, -44.0)
	if player and player.has_method("_spawn_floating_text"):
		player.call("_spawn_floating_text", "📢 Cadáver de %s reportado al Hospital y Comisaría" % npc_name, Color.AQUA, -36.0)
	return true

## Un testigo que descubrió un cadáver corre físicamente hasta el Dr. Valen o un Guardia para dar el aviso (sin telepatía)
func _process_witness_corpse_reporting(delta: float) -> bool:
	if not is_instance_valid(_reporting_corpse_target):
		return false
	var corpse_to_report: VillageNPC = _reporting_corpse_target
	if not corpse_to_report.is_dead or not corpse_to_report.corpse_on_ground or corpse_to_report.corpse_in_morgue or corpse_to_report.corpse_reported or corpse_to_report.corpse_reporter_npc != self:
		_reporting_corpse_target = null
		return false

	# Buscar a la autoridad viva más cercana (Dr. Valen, Comisario Vane o Guardia Rodric)
	var nearest_authority: VillageNPC = null
	var best_dist: float = 999999.0
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != self:
			var auth := n as VillageNPC
			if auth.trade_role in [TradeRole.DOCTOR, TradeRole.SHERIFF, TradeRole.GUARD] and not auth.is_dead and not auth.is_downed:
				var d: float = global_position.distance_to(auth.global_position)
				if d < best_dist:
					best_dist = d
					nearest_authority = auth

	var report_dest: Vector2 = nearest_authority.global_position if nearest_authority != null else Vector2(745, 128)
	if global_position.distance_to(report_dest) > 34.0:
		_move_towards_point(report_dest, 76.0, delta)
		move_and_slide()
		_update_visual_animation(delta)
		_update_hover_label(delta)
		return true
	else:
		velocity = Vector2.ZERO
		corpse_to_report.corpse_reported = true
		corpse_to_report.corpse_reporter_npc = null
		_reporting_corpse_target = null
		var auth_label: String = nearest_authority.npc_name if nearest_authority != null else "el Hospital"
		_spawn_floating_text("📢 ¡%s reportó el cadáver de %s a %s!" % [npc_name, corpse_to_report.npc_name, auth_label], Color.GOLD, -42.0)
		return true

## Recoge físicamente un cadáver YA REPORTADO (`corpse_reported == true`) y camina con él por las puertas y calles hasta depositarlo en la Morgue
func _process_corpse_morgue_transport(delta: float) -> bool:
	var target_corpse: VillageNPC = null
	if is_instance_valid(_carrying_corpse_target) and _carrying_corpse_target.is_dead and _carrying_corpse_target.corpse_on_ground and not _carrying_corpse_target.corpse_in_morgue:
		if not _carrying_corpse_target.corpse_being_carried or _carrying_corpse_target.corpse_carrier == self:
			target_corpse = _carrying_corpse_target
		else:
			_carrying_corpse_target = null

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
					if c.corpse_being_carried and c.corpse_carrier == self:
						target_corpse = c
						_carrying_corpse_target = c
						break
					elif not c.corpse_being_carried:
						# Tanto el Médico Forense como la Guardia/Comisario (o el descubridor si el médico no está libre) pueden levantar y trasladar el cuerpo
						var doc_available := _is_doctor_conscious_and_free()
						if can_be_carrier or (not doc_available and c.corpse_discovered_by == npc_name):
							target_corpse = c
							_carrying_corpse_target = c
							break

	if target_corpse == null:
		return false

	# Paso A: Caminar hasta donde yace el cadáver
	var vm_carry = _cached_vm
	var morgue_has_space: bool = (vm_carry == null) or (not vm_carry.has_method("has_free_morgue_table")) or bool(vm_carry.call("has_free_morgue_table"))
	var dest_label: String = "la Morgue" if morgue_has_space else "el Cementerio Parroquial (Morgue llena)"
	if not target_corpse.corpse_being_carried:
		if global_position.distance_to(target_corpse.global_position) > 24.0:
			_move_towards_point(target_corpse.global_position, 66.0, delta)
			move_and_slide()
			_update_visual_animation(delta)
			_update_hover_label(delta)
			return true
		else:
			target_corpse.corpse_being_carried = true
			target_corpse.corpse_carrier = self
			_carrying_corpse_target = target_corpse
			_spawn_floating_text("⚰️ %s recoge el cadáver de %s hacia %s" % [npc_name, target_corpse.npc_name, dest_label], Color.AQUA, -42.0)

	# Paso B: Llevar el cuerpo físicamente hasta la Morgue Forense (`Vector2(745, 174)`) o directo al Cementerio Parroquial (`Vector2(888, 305)`) si las 3 camillas están llenas
	var target_drop_pos := Vector2(745, 174)
	if not morgue_has_space and vm_carry and vm_carry.has_method("get_cemetery_burial_target_pos"):
		target_drop_pos = vm_carry.call("get_cemetery_burial_target_pos")
	target_corpse.global_position = global_position + Vector2(0, -8)
	if global_position.distance_to(target_drop_pos) > 22.0:
		_move_towards_point(target_drop_pos, 60.0, delta)
		move_and_slide()
		_update_visual_animation(delta)
		_update_hover_label(delta)
		return true
	else:
		velocity = Vector2.ZERO
		target_corpse.corpse_on_ground = false
		target_corpse.corpse_being_carried = false
		target_corpse.corpse_in_morgue = true
		target_corpse.corpse_carrier = null
		target_corpse.global_position = target_drop_pos
		if target_corpse.sprite:
			target_corpse.sprite.visible = false
		if target_corpse.status_label:
			target_corpse.status_label.visible = false
		if target_corpse._craft_bar_root:
			target_corpse._craft_bar_root.visible = false
		if target_corpse.interact_area and target_corpse.interact_area.get_child_count() > 0:
			var ic := target_corpse.interact_area.get_child(0) as CollisionShape2D
			if ic:
				ic.set_deferred("disabled", true)
		_carrying_corpse_target = null
		var vm = _cached_vm
		if vm and vm.has_method("register_npc_death_and_corpse"):
			vm.call(
				"register_npc_death_and_corpse",
				target_corpse,
				target_corpse.death_world_pos,
				target_corpse.last_hit_weapon_name,
				target_corpse.last_hit_by_player,
				target_corpse.corpse_discovered_by,
				target_corpse.corpse_rot_hours
			)
		if morgue_has_space:
			_spawn_floating_text("⚰️ Cuerpo de %s depositado en la Morgue Forense" % target_corpse.npc_name, Color.AQUA, -44.0)
		else:
			_spawn_floating_text("🪦 Cuerpo de %s sepultado en el Cementerio de la Iglesia" % target_corpse.npc_name, Color(0.85, 0.78, 0.95), -44.0)
		return true

func _is_doctor_conscious_and_free() -> bool:
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.trade_role == TradeRole.DOCTOR and not v.is_dead and not v.is_downed and not v.is_sleeping and not v.is_stunned_flag and v.sedated_timer <= 0.0:
				return true
	return false

## IA Policial: 1º Negociar (si no se resiste), 2º Si se resiste -> Persecución con Pistola a distancia y Porra cuerpo a cuerpo,
## respetando estrictamente la Línea de Visión (`has_line_of_sight`) para no detectar a través de las paredes.
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

	# Si el guardia NO tiene línea de visión y no ha visto al jugador recientemente, no puede detectarlo a través de paredes
	if _police_alerted_timer <= 0.0:
		return false

	var resisting: bool = bool(vm.get("is_resisting_arrest")) or is_hostile
	var target_pt: Vector2 = player.global_position if can_see_player else _last_seen_player_pos
	var spd_mult: float = lerpf(0.78, 1.0, eff_pol)

	# FASE 1: Intentar negociar primero con el jugador antes de usar la fuerza
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

	# FASE 2: El jugador se ha resistido al arresto -> Combate Policial con Porra (cerca) y Pistola (media/larga distancia)
	_attack_timer = maxf(0.0, _attack_timer - delta)

	if can_see_player and dist_p <= 36.0:
		# Combate cuerpo a cuerpo con Porra Policial
		if dist_p > 22.0:
			_move_towards_point(player.global_position, 96.0 * spd_mult, delta)
		else:
			velocity = Vector2.ZERO
		if _attack_timer <= 0.0:
			_attack_timer = 0.85 / maxf(0.55, eff_pol)
			_strike_police_baton(player)
	elif can_see_player and dist_p <= 195.0:
		# Disparo a distancia con Pistola Reglamentaria + avance táctico
		_move_towards_point(player.global_position, 82.0 * spd_mult, delta)
		if _attack_timer <= 0.0:
			_attack_timer = 1.25 / maxf(0.55, eff_pol)
			_fire_police_pistol(player)
	else:
		# Persecución hacia la última posición vista
		_move_towards_point(target_pt, 96.0 * spd_mult, delta)

	move_and_slide()
	_update_visual_animation(delta)
	_update_hover_label(delta)
	return true

func _strike_police_baton(player: Node2D) -> void:
	if not player or not player.has_method("take_damage"):
		return
	var eff: float = get_job_efficiency()
	var d := DamageData.new()
	d.amount = 14.0 * eff
	d.type = CombatConstants.DamageType.BLUNT
	d.stun_buildup = 36.0 * eff
	d.source = self
	player.call("take_damage", d)
	_spawn_floating_text("🏏 ¡Porrazo Policial!", Color.AQUA, -40.0)

func _fire_police_pistol(player: Node2D) -> void:
	if not player or not player.has_method("take_damage"):
		return
	# Crear traza visual de disparo de pistola entre el policía y el jugador
	var tracer := Line2D.new()
	tracer.width = 2.2
	tracer.default_color = Color(1.0, 0.88, 0.32, 0.95)
	tracer.points = PackedVector2Array([
		global_position + Vector2(0, -6),
		player.global_position + Vector2(0, -6)
	])
	tracer.z_index = 18
	var parent_scene: Node = get_tree().current_scene if get_tree().current_scene else get_parent()
	if parent_scene:
		parent_scene.add_child(tracer)
		var tw := tracer.create_tween()
		tw.tween_property(tracer, "modulate:a", 0.0, 0.18)
		tw.tween_callback(tracer.queue_free)

	var eff: float = get_job_efficiency()
	var d := DamageData.new()
	d.amount = 16.0 * eff
	d.type = CombatConstants.DamageType.CUT
	d.bleed_buildup = 20.0 * eff
	d.source = self
	player.call("take_damage", d)
	_spawn_floating_text("🔫 ¡Disparo Policial!", Color(1.0, 0.82, 0.28), -42.0)

## El Dr. Valen SOLO sabe que un NPC está agonizando si lo ve directamente con línea de visión (<= 115 px) o si el paciente ya está dentro del Hospital
func _find_downed_npc() -> VillageNPC:
	var vm = _cached_vm
	var hosp_rect := Rect2(704, 110, 82, 80)
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != self:
			var v: VillageNPC = n as VillageNPC
			if v.is_downed and not v.is_dead:
				if hosp_rect.has_point(v.global_position):
					return v
				if global_position.distance_to(v.global_position) <= 115.0:
					var has_los: bool = (vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", global_position, v.global_position))
					if has_los:
						return v
	return null

## Ceder paso al jugador y despejar umbrales de puertas (Stardew Valley / RimWorld / Baldur's Gate 3)
func _apply_player_and_doorway_yield(delta: float) -> void:
	var player = _cached_player
	if is_instance_valid(player) and not is_sleeping and not is_at_poker_table:
		var d_p_sq: float = global_position.distance_squared_to(player.global_position)
		if d_p_sq > 0.0025 and d_p_sq < 256.0:
			var d_p: float = sqrt(d_p_sq)
			var away_dir: Vector2 = (global_position - player.global_position).normalized()
			# Empuje lateral suave para ceder el paso en puertas estrechas
			var side_dir := Vector2(-away_dir.y, away_dir.x) if (abs(npc_name.hash()) % 2 == 0) else Vector2(away_dir.y, -away_dir.x)
			var yield_vec: Vector2 = (away_dir * 0.7 + side_dir * 0.3).normalized() * ((16.0 - d_p) / 16.0) * 34.0
			velocity += yield_vec

	# Si el NPC está quieto justo en el marco de una puerta (<= 18 px), da un paso hacia adentro/afuera para no obstruir la entrada (throttled a 4 Hz)
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
	var vm = _cached_vm
	if not is_instance_valid(vm):
		_cached_vm = get_tree().get_first_node_in_group("village_manager")
		vm = _cached_vm

	var eff_speed: float = speed * get_nutrition_speed_multiplier() * get_sleep_speed_multiplier()

	_nav_waypoint_timer -= delta
	var need_recalc: bool = (_nav_waypoint_timer <= 0.0) or (_cached_nav_waypoint == Vector2.INF) or (target_pos.distance_squared_to(_last_nav_dest) > 16.0) or (global_position.distance_squared_to(_cached_nav_waypoint) <= 20.0)
	if need_recalc:
		_nav_waypoint_timer = 0.12
		_last_nav_dest = target_pos
		if vm and vm.has_method("get_navigation_waypoint"):
			_cached_nav_waypoint = vm.call("get_navigation_waypoint", global_position, target_pos, self)
		else:
			_cached_nav_waypoint = target_pos

	var nav_target: Vector2 = _cached_nav_waypoint
	var diff: Vector2 = nav_target - global_position
	var step_snap: float = maxf(3.5, eff_speed * delta * 0.65)
	if diff.length() <= step_snap:
		if diff.length() <= 6.0:
			global_position = nav_target
		# Si `nav_target` era un waypoint intermedio (p. ej. umbral de puerta o esquina), encadenar al siguiente waypoint sin detenerse
		if nav_target.distance_squared_to(target_pos) > 9.0 and vm and vm.has_method("get_navigation_waypoint"):
			_cached_nav_waypoint = vm.call("get_navigation_waypoint", global_position, target_pos, self)
			nav_target = _cached_nav_waypoint
			diff = nav_target - global_position
		if diff.length() <= step_snap:
			velocity = Vector2.ZERO
			_stuck_timer = 0.0
			_last_frame_pos = global_position
			return

	# Interacción activa con puertas: si hay una puerta cerrada y el NPC realmente va a cruzarla, la abre; si está trancada con cerrojo [B], se detiene ante ella
	if vm and vm.has_method("npc_interact_with_door"):
		var can_pass_door: bool = bool(vm.call("npc_interact_with_door", self, delta, target_pos, nav_target))
		if not can_pass_door:
			velocity = Vector2.ZERO
			_stuck_timer += delta
			if _stuck_timer >= 2.2:
				_stuck_timer = 0.0
				var is_police: bool = trade_role in [TradeRole.SHERIFF, TradeRole.GUARD]
				_spawn_floating_text("🚓💥 ¡Derribando puerta!" if is_police else "🚪✊ ¡Puerta trancada!", Color.ORANGE_RED if is_police else Color.GOLD, -34.0)
			return

	var desired_vel: Vector2 = diff.normalized() * eff_speed

	# Recuperación anti-atasco contra esquinas o marcos de puertas
	if global_position.distance_squared_to(_last_frame_pos) < 0.09 and eff_speed > 12.0:
		_stuck_timer += delta
		if _stuck_timer >= 0.40:
			_nav_waypoint_timer = 0.0
			var perp := Vector2(-diff.y, diff.x).normalized() if (abs(npc_name.hash()) % 2 == 0) else Vector2(diff.y, -diff.x).normalized()
			desired_vel = (diff.normalized() * 0.55 + perp * 0.75).normalized() * eff_speed
	else:
		_stuck_timer = 0.0

	# Separación suave entre NPCs (throttled a 10 Hz para ahorrar 83% de iteraciones de grupo)
	_sep_timer -= delta
	if _sep_timer <= 0.0:
		_sep_timer = 0.10
		var sep_vec := Vector2.ZERO
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC and n != self:
				var other := n as VillageNPC
				if other.is_dead or other.is_downed or other.is_sleeping:
					continue
				var d_sq: float = global_position.distance_squared_to(other.global_position)
				if d_sq > 0.01 and d_sq < 196.0:
					var d_other: float = sqrt(d_sq)
					var push_dir: Vector2 = (global_position - other.global_position).normalized()
					sep_vec += push_dir * ((14.0 - d_other) / 14.0) * 22.0
		_cached_sep_vec = sep_vec

	_last_frame_pos = global_position
	velocity = (desired_vel + _cached_sep_vec).limit_length(eff_speed * 1.15)

func _is_morning_expedition_hours() -> bool:
	if not (trade_role in [TradeRole.BLACKSMITH, TradeRole.CARPENTER, TradeRole.HERBALIST, TradeRole.FISHMONGER, TradeRole.BUTCHER]):
		return false
	if not WorldClock:
		return false
	var cur_day: int = WorldClock.current_day
	if _completed_expedition_day == cur_day:
		return false
	var h: int = WorldClock.current_hour
	var m: int = WorldClock.current_minute
	return (h == 6 and m >= 30) or h == 7 or h == 8 or (h == 9 and m < 30)

func _get_expedition_target_pos() -> Vector2:
	match trade_role:
		TradeRole.CARPENTER:
			return Vector2(65, 640)    # Pinos en la entrada del Bosque Sur
		TradeRole.BLACKSMITH:
			return Vector2(515, 648)   # Veta de Hierro en la Cantera Este
		TradeRole.HERBALIST:
			return Vector2(-180, 665)  # Hierbas en la Pradera de Conejos
		TradeRole.FISHMONGER:
			return Vector2(-52, 105)   # Muelle del Lago del Oeste
		TradeRole.BUTCHER:
			return Vector2(142, 615)   # Cruce de caza en el Bosque Sur
	return work_position

func _get_expedition_description() -> String:
	match trade_role:
		TradeRole.CARPENTER:
			return "🪓 Expedición Matutina: Talando Pinos"
		TradeRole.BLACKSMITH:
			return "⛏️ Expedición Matutina: Picando Hierro"
		TradeRole.HERBALIST:
			return "🌿 Expedición Matutina: Recogiendo Hierbas"
		TradeRole.FISHMONGER:
			return "🎣 Expedición Matutina: Pescando en el Lago"
		TradeRole.BUTCHER:
			return "🏹 Expedición Matutina: Cazando en el Bosque"
	return "🚶 En Expedición"

func _is_mandatory_work_hours() -> bool:
	if trade_role == TradeRole.UNEMPLOYED:
		return false
	if not WorldClock:
		return true
	if _is_morning_expedition_hours():
		return true
	var h: int = WorldClock.current_hour
	# La Tabernera atiende la posada de 08:00 a 23:00 para recibir a los trabajadores tras las 18:00
	if trade_role == TradeRole.INNKEEPER:
		return h >= 8 and h < 23
	# Los comercios de alimentación (Pescadería, Carnicería y Botica) atienden el mostrador hasta las 20:00
	# para que los demás trabajadores puedan comprar comida al salir a las 18:00 mientras el dependiente está presente
	if trade_role in [TradeRole.FISHMONGER, TradeRole.BUTCHER, TradeRole.HERBALIST]:
		return h >= 8 and h < 20
	# Horario laboral obligatorio del resto de oficios y hogares: 08:00 AM a 18:00 (6:00 PM)
	return h >= 8 and h < 18

## Multiplicador continuo de velocidad por Nutrición estilo Kenshi (300 pts = 100% -> 3 días completos hasta 0%):
## - Día 1 (66.7% a 100%): 100% velocidad
## - Día 2 (33.3% a 66.7%, Hambriento -> Desnutrido): cae gradualmente del 100% al 68%
## - Día 3 (0% a 33.3%, Desnutrido -> Famélico): cae gradualmente del 68% al 42%
func get_nutrition_speed_multiplier() -> float:
	if need_hunger >= 66.67:
		return 1.0
	elif need_hunger >= 33.33:
		return lerpf(0.68, 1.0, (need_hunger - 33.33) / 33.34)
	return lerpf(0.42, 0.68, clampf(need_hunger / 33.33, 0.0, 1.0))

## Multiplicador continuo de habilidad profesional y combate por Nutrición estilo Kenshi:
## - Día 1 (66.7% a 100%): 100% habilidad
## - Día 2 (33.3% a 66.7%): cae gradualmente del 100% al 55%
## - Día 3 (0% a 33.3%): cae gradualmente del 55% al 20%
func get_nutrition_skill_multiplier() -> float:
	if need_hunger >= 66.67:
		return 1.0
	elif need_hunger >= 33.33:
		return lerpf(0.55, 1.0, (need_hunger - 33.33) / 33.34)
	return lerpf(0.20, 0.55, clampf(need_hunger / 33.33, 0.0, 1.0))

## Estado nutricional estilo Kenshi (con indicador de digestión/recuperación progresiva `↗Digeriendo`)
func get_nutrition_status_label() -> String:
	var dig_str: String = (" ↗Digeriendo" if digestion_buffer > 1.0 else "")
	var spd_pen: int = int(round((1.0 - get_nutrition_speed_multiplier()) * 100.0))
	var skl_pen: int = int(round((1.0 - get_nutrition_skill_multiplier()) * 100.0))
	if need_hunger <= 0.0 and digestion_buffer <= 0.0:
		return "💀Inanición Letal (+3d sin comer | -%d%%Vel -%d%%Oficio)" % [spd_pen, skl_pen]
	elif need_hunger < 33.33:
		return "🔴Famélico Día 3 (-%d%%Vel -%d%%Oficio)%s" % [spd_pen, skl_pen, dig_str]
	elif need_hunger < 66.67:
		return "🟠Desnutrido Día 2 (-%d%%Vel -%d%%Oficio)%s" % [spd_pen, skl_pen, dig_str]
	elif need_hunger < 80.0:
		return "🟡Hambriento%s" % dig_str
	return "🟢Bien alimentado%s" % dig_str

## Multiplicador continuo de velocidad por Privación de Sueño (`need_energy`):
## - >= 50%: 100% velocidad
## - 30% a 50% (Somnoliento): cae del 100% al 85%
## - 10% a 30% (Privación de Sueño): cae del 85% al 68%
## - < 10% (Agotamiento Extremo): cae del 68% al 52%
func get_sleep_speed_multiplier() -> float:
	if need_energy >= 50.0:
		return 1.0
	elif need_energy >= 30.0:
		return lerpf(0.85, 1.0, (need_energy - 30.0) / 20.0)
	elif need_energy >= 10.0:
		return lerpf(0.68, 0.85, (need_energy - 10.0) / 20.0)
	return lerpf(0.52, 0.68, clampf(need_energy / 10.0, 0.0, 1.0))

## Multiplicador continuo de habilidad profesional y combate por Privación de Sueño (`need_energy`)
func get_sleep_skill_multiplier() -> float:
	if need_energy >= 50.0:
		return 1.0
	elif need_energy >= 30.0:
		return lerpf(0.82, 1.0, (need_energy - 30.0) / 20.0)
	return lerpf(0.55, 0.82, clampf(need_energy / 30.0, 0.0, 1.0))

## Multiplicador de rango de visión por Privación de Sueño (`need_energy`)
func get_sleep_vision_multiplier() -> float:
	if need_energy >= 50.0:
		return 1.0
	elif need_energy >= 30.0:
		return 0.80
	elif need_energy >= 10.0:
		return 0.60
	return 0.45

func get_sleep_status_label() -> String:
	var camp_tag: String = " ⛺Intemperie" if is_vagrant_camper else ""
	if need_energy < 10.0:
		return "🔴Insomnio Extremo (-45%%Vel -55%%Vis)%s" % camp_tag
	elif need_energy < 30.0:
		return "🟠Privación Sueño (-28%%Vel -35%%Oficio)%s" % camp_tag
	elif need_energy < 50.0:
		return "🟡Somnoliento (-12%%Vel)%s" % camp_tag
	return "🟢Descansado%s" % camp_tag

## Devuelve la eficiencia laboral actual del NPC combinando su experiencia (`days_in_role`) con su estado nutricional estilo Kenshi y su nivel de sueño
func get_job_efficiency() -> float:
	if trade_role in [TradeRole.UNEMPLOYED, TradeRole.FAMILY_MEMBER]:
		return clampf(get_nutrition_skill_multiplier() * get_sleep_skill_multiplier(), 0.15, 1.0)
	var base_exp: float = clampf(0.35 + (float(days_in_role) / 7.0) * 0.65, 0.35, 1.0)
	return clampf(base_exp * get_nutrition_skill_multiplier() * get_sleep_skill_multiplier(), 0.12, 1.0)

## Etiqueta descriptiva del nivel de dominio del oficio, curva de aprendizaje de 7 días y penalización por desnutrición/sueño
func get_job_efficiency_label() -> String:
	if trade_role in [TradeRole.UNEMPLOYED, TradeRole.FAMILY_MEMBER]:
		return "Vecino"
	var pct: int = int(round(get_job_efficiency() * 100.0))
	var mal_tag: String = " ⚠️Desnutrido" if need_hunger < 60.0 else ""
	if need_energy < 35.0:
		mal_tag += " 💤Exhausto"
	if days_in_role >= 7:
		return "Maestro (%d%%%s)" % [pct, mal_tag]
	elif days_in_role >= 4:
		return "Oficial (%d%% · Día %d/7%s)" % [pct, days_in_role, mal_tag]
	elif days_in_role >= 2:
		return "Aprendiz (%d%% · Día %d/7%s)" % [pct, days_in_role, mal_tag]
	return "Novato (%d%% · Día %d/7%s)" % [pct, days_in_role, mal_tag]

## Verifica si este NPC (dependiente/artesano) está vivo, consciente y físicamente atendiendo su mostrador/taller
func is_at_shop_counter() -> bool:
	if is_dead or is_downed or is_sleeping or is_stunned_flag or sedated_timer > 0.0 or is_hostile or is_at_poker_table:
		return false
	if trade_role == TradeRole.TRAVELING_MERCHANT:
		return not _merchant_leaving
	if current_activity != ActivityState.WORKING:
		return false
	if _is_morning_expedition_hours() and global_position.distance_to(work_position) > 46.0:
		return false
	return global_position.distance_to(work_position) <= 48.0

## Alimenta al NPC añadiendo nutrientes al estómago (`digestion_buffer`) para que se recupere gradualmente al estilo Kenshi
func feed_npc_gradual(nutrition_amount: float = 38.0) -> void:
	var max_room: float = maxf(0.0, 100.0 - need_hunger)
	digestion_buffer = clampf(digestion_buffer + nutrition_amount, 0.0, maxf(18.0, max_room))
	_starvation_tick_timer = 0.0

## Prioridad "Casa Primero":
## - La opción principal de alimentación de los habitantes es SIEMPRE cocinar/comer en su casa (`home_table_pos` + `house_pantry`).
## - La Taberna es solo un capricho extra caro de comida preparada (`12-15 Oro`): si la puerta de la Taberna está bloqueada
##   o el NPC prefiere ahorrar su oro para comprar materia prima cruda barata (`3-5 Oro`), come en su casa.
func _choose_preferred_meal_location() -> bool:
	var vm = _cached_vm if is_instance_valid(_cached_vm) else get_tree().get_first_node_in_group("village_manager")
	var tavern_blocked: bool = (vm != null and vm.has_method("is_building_door_blocked") and bool(vm.call("is_building_door_blocked", "tavern")))
	if tavern_blocked:
		return false
	if trade_role == TradeRole.INNKEEPER:
		return true
	if trade_role == TradeRole.UNEMPLOYED:
		if is_vagrant_camper or personal_gold < 13:
			return false
		return true
	# Para todas las familias y autoridades con mesa propia: Casa Primero (90% casa; solo 10% capricho en Taberna si tienen oro de sobra >= 36)
	if personal_gold >= 36 and randf() < 0.10:
		return true
	return false

## Actualiza Hambre (escala de 3 días estilo Kenshi + digestión gradual), Energía (16h despierto / 8h de sueño nocturno 22:00-06:00) y Socialización.
func _update_needs_and_decisions(delta: float) -> void:
	var is_night_env := false
	if WorldClock:
		var h: int = WorldClock.current_hour
		is_night_env = (h >= 22 or h < 6) # 8 horas de sueño nocturno (22:00 a 06:00)
	var in_work_shift: bool = _is_mandatory_work_hours()

	# Si estamos en horario laboral obligatorio (08:00 - 18:00), el NPC cumple su turno salvo que esté en Día 3 de hambruna (<= 22%) y con el estómago vacío
	if in_work_shift and current_activity != ActivityState.WORKING and (need_hunger > 22.0 or digestion_buffer > 5.0):
		is_sleeping = false
		_is_amateur_foraging = false
		_social_partner = null
		current_activity = ActivityState.WORKING
	elif in_work_shift and need_hunger <= 22.0 and digestion_buffer <= 2.0 and current_activity == ActivityState.WORKING:
		# ¡Famélico en Día 3 en pleno turno! Intenta ir de urgencia a buscar comida en casa
		current_activity = ActivityState.EATING
		_eat_at_tavern = _choose_preferred_meal_location()

	# 1. Digestión progresiva estilo Kenshi: si hay comida en el estómago (`digestion_buffer > 0`),
	#    el cuerpo absorbe los nutrientes POCO A POCO con el paso de las horas, recuperando velocidad y habilidades gradualmente.
	if digestion_buffer > 0.0:
		var absorb_step: float = minf(digestion_buffer, 0.42 * delta)
		digestion_buffer = maxf(0.0, digestion_buffer - absorb_step)
		need_hunger = minf(100.0, need_hunger + absorb_step)

	# El desgaste de hambre está calibrado para que `100% -> 0%` tome exactamente 3 días completos de juego (72h = 1080s reales, ~33.3% por día)
	var base_3day_hunger_rate: float = 0.092 * _hunger_decay_rate
	# Cuando un NPC está desnutrido (< 60%), se cansa hasta un 25% más rápido por debilidad física
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
			# Calibrado para aguantar las 16h diurnas despierto (06:00 a 22:00 = 240s reales) perdiendo solo ~65% de energía en todo el día
			var night_fatigue: float = 1.35 if is_night_env else 0.95
			need_energy = maxf(0.0, need_energy - _energy_decay_rate * night_fatigue * malnutrition_fatigue_mult * delta)
			need_social = maxf(0.0, need_social - _social_decay_rate * 0.65 * delta)

		ActivityState.EATING:
			is_sleeping = false
			if _is_amateur_foraging:
				if digestion_buffer <= 0.0:
					need_hunger = maxf(0.0, need_hunger - base_3day_hunger_rate * 1.15 * delta)
				need_energy = maxf(0.0, need_energy - 0.42 * delta)
			else:
				var vm_chk = _cached_vm if is_instance_valid(_cached_vm) else get_tree().get_first_node_in_group("village_manager")
				if _eat_at_tavern and vm_chk and vm_chk.has_method("is_building_door_blocked") and bool(vm_chk.call("is_building_door_blocked", "tavern")):
					_eat_at_tavern = false
					_spawn_floating_text("🚪🔒 ¡Taberna bloqueada! Iré a comer en casa / buscar suministros", Color.GOLD, -36.0)
				var meal_pos: Vector2 = tavern_social_pos if _eat_at_tavern else home_table_pos
				if global_position.distance_to(meal_pos) <= 14.0:
					if not _meal_consumed_this_sitting:
						_meal_consumed_this_sitting = true
						_has_valid_meal_this_sitting = false
						_sitting_meal_ingested = 0.0
						if vm_chk and vm_chk.has_method("consume_village_meal_for_npc"):
							_has_valid_meal_this_sitting = bool(vm_chk.call("consume_village_meal_for_npc", self))
					if _has_valid_meal_this_sitting:
						# En vez de recuperar el 100% de golpe, el plato de comida llena gradualmente la reserva de digestión (+38% por comida = ~1 día de nutrición)
						var ingest_step: float = minf(38.0 - _sitting_meal_ingested, 9.5 * delta)
						if ingest_step > 0.0:
							_sitting_meal_ingested += ingest_step
							feed_npc_gradual(ingest_step)
						need_energy = minf(100.0, need_energy + 1.2 * delta)
						need_social = minf(100.0, need_social + 5.0 * delta)
					else:
						# ¡Despensa vacía y no pudo comprar comida en tiendas ni en Taberna!
						# Si tiene hambre (< 74%), sale por su cuenta al bosque como cazador/recolector amateur ineficiente
						if need_hunger < 74.0 and need_energy > 15.0:
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
			var target_s_pos: Vector2 = _get_social_target_pos()
			if global_position.distance_to(target_s_pos) <= 22.0:
				need_social = minf(100.0, need_social + 15.0 * delta)
				_chat_bubble_timer -= delta
				if _chat_bubble_timer <= 0.0:
					_chat_bubble_timer = randf_range(4.5, 7.5)
					_spawn_floating_text("💬", Color(0.75, 0.95, 1.0), -28.0)

		ActivityState.SLEEPING:
			var vm_slp = _cached_vm if is_instance_valid(_cached_vm) else get_tree().get_first_node_in_group("village_manager")
			if trade_role == TradeRole.UNEMPLOYED and not is_vagrant_camper and vm_slp and vm_slp.has_method("is_building_door_blocked") and bool(vm_slp.call("is_building_door_blocked", "tavern")):
				if vm_slp.has_method("evict_npc_to_vagrant_camp"):
					vm_slp.call("evict_npc_to_vagrant_camp", self, "Puerta de la Taberna bloqueada")
			if global_position.distance_to(bed_position) <= 12.0:
				is_sleeping = true
				# 8 horas de sueño nocturno (22:00 a 06:00 = 120s reales):
				# En cama recupera +1.10%/s (~16.5%/hora) llegando al 100% al amanecer; en campamento rústico recupera un 40% más lento con tope de 74% (62% bajo lluvia).
				if is_vagrant_camper:
					var raining: bool = (WorldClock != null and int(WorldClock.current_weather) == 1)
					var max_camp_energy: float = 62.0 if raining else 74.0
					need_energy = minf(max_camp_energy, need_energy + 0.72 * delta)
				else:
					need_energy = minf(100.0, need_energy + 1.10 * delta)
				if digestion_buffer <= 0.0:
					need_hunger = maxf(0.0, need_hunger - base_3day_hunger_rate * 0.55 * delta)
			else:
				is_sleeping = false

	# 1b. Tono visual sutil de palidez cuando está gravemente desnutrido (Día 2-3 sin comer)
	if sprite and not is_downed and not is_dead and not is_stunned_flag and sedated_timer <= 0.0:
		if need_hunger < 33.33:
			sprite.modulate = Color(0.86, 0.88, 0.78, 1.0)
		elif need_hunger < 66.67:
			sprite.modulate = Color(0.94, 0.94, 0.88, 1.0)
		else:
			sprite.modulate = Color.WHITE

	# 1c. Consecuencias Biológicas Reales:
	#     SOLO tras cumplir 3 DÍAS COMPLETOS sin comer (`need_hunger <= 0%` y `digestion_buffer <= 0%`) empieza a perder vida real.
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

	# Si por alguna razón extrema llega a 0% de energía fuera del turno obligatorio, NO se desmaya en el suelo:
	# sufre los debufos severos de privación de sueño y camina hacia su cama/campamento a dormir.
	if need_energy <= 0.0 and not in_work_shift and current_activity != ActivityState.SLEEPING:
		current_activity = ActivityState.SLEEPING
		return

	# Durante el turno laboral obligatorio (08:00 - 18:00), permanece trabajando salvo urgencia de hambruna (Día 3)
	if in_work_shift and current_activity == ActivityState.WORKING:
		return

	# 2. Fuera del horario laboral (18:00 a 08:00, o todo el día para viajeros sin oficio):
	#    Mantener horarios realistas (despiertos de 06:00 a 22:00 y durmiendo las 8 horas nocturnas de 22:00 a 06:00)
	_decision_timer -= delta
	if _decision_timer > 0.0:
		return
	_decision_timer = randf_range(0.8, 1.5)

	# Si está durmiendo, duerme toda la noche hasta que amanezca a las 06:00 (`not is_night_env`) y haya descansado
	if current_activity == ActivityState.SLEEPING:
		var wake_threshold: float = 60.0 if is_vagrant_camper else 78.0
		if not is_night_env and need_energy >= wake_threshold:
			is_sleeping = false
			current_activity = ActivityState.EATING if (need_hunger < 72.0 and digestion_buffer < 12.0) else ActivityState.WORKING
			if current_activity == ActivityState.EATING:
				_eat_at_tavern = _choose_preferred_meal_location()
		return

	# Si está comiendo (o cazando como amateur), permanece hasta ingerir su ración completa
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

	# Si está socializando, charla hasta la hora de dormir (22:00) o hasta llenar su barra social
	if current_activity == ActivityState.SOCIALIZING:
		if is_night_env or need_energy <= 12.0 or (need_hunger < 65.0 and digestion_buffer < 10.0) or need_social >= 92.0:
			_social_partner = null
			if need_hunger < 70.0 and digestion_buffer < 12.0 and not is_night_env:
				current_activity = ActivityState.EATING
				_eat_at_tavern = _choose_preferred_meal_location()
			elif is_night_env or need_energy <= 12.0:
				current_activity = ActivityState.SLEEPING
			else:
				current_activity = ActivityState.WORKING
		return

	# Al salir de trabajar a las 18:00 (o para viajeros), si tiene hambre (< 78%) y no está ya digiriendo un plato lleno, va a cenar (Casa Primero):
	if need_hunger <= 78.0 and digestion_buffer < 15.0 and not is_night_env:
		current_activity = ActivityState.EATING
		_eat_at_tavern = _choose_preferred_meal_location()
		return

	# Solo van a dormir durante la noche (22:00 a 06:00) o si están en agotamiento crítico (<= 12%); el resto del día permanecen despiertos
	if is_night_env or need_energy <= 12.0:
		current_activity = ActivityState.SLEEPING
		return

	if need_social <= 78.0:
		current_activity = ActivityState.SOCIALIZING
		_social_partner = _find_best_social_partner()
		return

func _execute_dynamic_activity(delta: float) -> void:
	if current_activity != ActivityState.WORKING:
		_is_actively_crafting = false
		_supply_run_target_role = 0
		if _craft_bar_root:
			_craft_bar_root.visible = false

	match current_activity:
		ActivityState.SLEEPING:
			if global_position.distance_to(bed_position) > 7.0:
				_move_towards_point(bed_position, 42.0, delta)
			else:
				velocity = Vector2.ZERO

		ActivityState.EATING:
			if _is_amateur_foraging:
				_process_amateur_survival_hunting(delta)
				return
			var meal_pos: Vector2 = tavern_social_pos if _eat_at_tavern else home_table_pos
			if global_position.distance_to(meal_pos) > 10.0:
				_move_towards_point(meal_pos, 40.0, delta)
			else:
				velocity = Vector2.ZERO

		ActivityState.SOCIALIZING:
			var target_s: Vector2 = _get_social_target_pos()
			if global_position.distance_to(target_s) > 16.0:
				_move_towards_point(target_s, 38.0, delta)
			else:
				velocity = Vector2.ZERO

		ActivityState.WORKING:
			if _is_morning_expedition_hours():
				_is_actively_crafting = false
				if _craft_bar_root:
					_craft_bar_root.visible = false
				_process_physical_morning_expedition(delta)
				return

			if trade_role in [TradeRole.BLACKSMITH, TradeRole.BUTCHER, TradeRole.CARPENTER, TradeRole.HERBALIST, TradeRole.FISHMONGER, TradeRole.INNKEEPER]:
				_process_artisan_workshop_crafting_and_supply_runs(delta)
				return

			_is_actively_crafting = false
			if _craft_bar_root:
				_craft_bar_root.visible = false

			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_wander_timer = randf_range(2.2, 4.6)
				if randf() < 0.55:
					_wander_offset = Vector2.ZERO
				else:
					var radius: float = 26.0 if (trade_role == TradeRole.UNEMPLOYED or trade_role == TradeRole.GUARD) else 8.0
					_wander_offset = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(3.0, radius)

			var target_pos: Vector2 = work_position + _wander_offset
			var vm = get_tree().get_first_node_in_group("village_manager")
			if vm and vm.has_method("clamp_point_to_building_interior"):
				target_pos = vm.call("clamp_point_to_building_interior", work_position, target_pos)
			if vm and vm.has_method("clamp_point_outside_buildings"):
				target_pos = vm.call("clamp_point_outside_buildings", work_position, target_pos)
			if global_position.distance_to(target_pos) > 5.0:
				_move_towards_point(target_pos, 44.0, delta)
			else:
				velocity = Vector2.ZERO

func _get_artisan_recipes() -> Array[Dictionary]:
	match trade_role:
		TradeRole.BLACKSMITH:
			return [
				{"output": "steel_ingot", "label": "Lingote Acero", "verb": "⚒️ Forjando", "input": "wood", "supplier": int(TradeRole.CARPENTER), "input_name": "Madera"},
				{"output": "repair_kit", "label": "Kit Herrero", "verb": "⚒️ Templando", "input": "leather", "supplier": int(TradeRole.BUTCHER), "input_name": "Cuero"}
			]
		TradeRole.CARPENTER:
			return [
				{"output": "repair_kit", "label": "Tablones", "verb": "🪚 Aserrando", "input": "iron_ore", "supplier": int(TradeRole.BLACKSMITH), "input_name": "Clavos/Hierro"},
				{"output": "wood", "label": "Vigas Pino", "verb": "🪚 Cepillando", "input": "herbal_poultice", "supplier": int(TradeRole.HERBALIST), "input_name": "Resina/Hierbas"}
			]
		TradeRole.BUTCHER:
			return [
				{"output": "cooked_meat", "label": "Carne Asada", "verb": "🥩 Ahumando", "input": "wood", "supplier": int(TradeRole.CARPENTER), "input_name": "Leña"},
				{"output": "leather", "label": "Cuero Curtido", "verb": "🔪 Curtiendo", "input": "herbal_poultice", "supplier": int(TradeRole.HERBALIST), "input_name": "Tanino/Hierbas"}
			]
		TradeRole.HERBALIST:
			return [
				{"output": "herbal_poultice", "label": "Cataplasma", "verb": "🧪 Destilando", "input": "bread", "supplier": int(TradeRole.FISHMONGER), "input_name": "Grano/Harina"},
				{"output": "carrot_seeds", "label": "Semillas", "verb": "🌱 Seleccionando", "input": "fertilizer", "supplier": int(TradeRole.FISHMONGER), "input_name": "Abono"}
			]
		TradeRole.FISHMONGER:
			return [
				{"output": "bread", "label": "Hogaza Pan", "verb": "🌾 Moliendo", "input": "wood", "supplier": int(TradeRole.CARPENTER), "input_name": "Leña"},
				{"output": "fertilizer", "label": "Abono Org.", "verb": "♻️ Compostando", "input": "herbal_poultice", "supplier": int(TradeRole.HERBALIST), "input_name": "Hierbas"}
			]
		TradeRole.INNKEEPER:
			return [
				{"output": "country_stew", "label": "Estofado", "verb": "🍲 Guisando", "input": "cooked_meat", "supplier": int(TradeRole.BUTCHER), "input_name": "Carne"},
				{"output": "bread", "label": "Pan Posada", "verb": "🍞 Horneando", "input": "bread", "supplier": int(TradeRole.FISHMONGER), "input_name": "Harina"}
			]
	return []

func _update_craft_bar_visual(ratio: float, label_txt: String, bar_color: Color) -> void:
	if not _craft_bar_root:
		return
	_craft_bar_root.visible = true
	var r: float = clampf(ratio, 0.02, 1.0)
	var fill_w: float = 38.0 * r
	if _craft_bar_fill:
		_craft_bar_fill.color = bar_color
		_craft_bar_fill.polygon = PackedVector2Array([
			Vector2(-19.0, -2.0),
			Vector2(-19.0 + fill_w, -2.0),
			Vector2(-19.0 + fill_w, 1.0),
			Vector2(-19.0, 1.0)
		])
	if _craft_bar_label and _craft_bar_label.text != label_txt:
		_craft_bar_label.text = label_txt

func _process_artisan_workshop_crafting_and_supply_runs(delta: float) -> void:
	if _supply_run_cooldown > 0.0:
		_supply_run_cooldown = maxf(0.0, _supply_run_cooldown - delta)

	var vm = _cached_vm if is_instance_valid(_cached_vm) else get_tree().get_first_node_in_group("village_manager")
	if vm and vm.has_method("is_trade_sabotaged") and bool(vm.call("is_trade_sabotaged", int(trade_role))):
		_is_actively_crafting = false
		_supply_run_target_role = 0
		if _craft_bar_root:
			_craft_bar_root.visible = false
		if global_position.distance_to(work_position) > 8.0:
			_move_towards_point(work_position, 42.0, delta)
		else:
			velocity = Vector2.ZERO
		return

	# 1. Si el artesano está yendo físicamente a la tienda del vecino a comprar materiales (`_supply_run_target_role != 0`)
	if _supply_run_target_role != 0:
		_is_actively_crafting = false
		_supply_run_timer += delta
		var supplier_npc: VillageNPC = null
		if vm and "trade_npcs" in vm and vm.trade_npcs.has(_supply_run_target_role):
			var cand = vm.trade_npcs[_supply_run_target_role]
			if cand is VillageNPC and is_instance_valid(cand) and not cand.is_dead and not cand.is_downed and not cand.is_sleeping and not cand.is_stunned_flag and cand.sedated_timer <= 0.0 and not cand.is_hostile:
				supplier_npc = cand as VillageNPC

		if supplier_npc == null:
			_supply_run_target_role = 0
			_supply_run_timer = 0.0
			_supply_run_cooldown = 28.0
			if _craft_bar_root:
				_craft_bar_root.visible = false
			return

		var supplier_counter: Vector2 = supplier_npc.work_position + Vector2(0, 12)
		var dist_to_sup: float = global_position.distance_to(supplier_counter)
		var trip_ratio: float = clampf(1.0 - (dist_to_sup / 240.0), 0.12, 0.95)
		_update_craft_bar_visual(trip_ratio, "🛒 A %s (%s)" % [supplier_npc.npc_name, _supply_run_input_label], Color(0.35, 0.86, 1.0, 0.95))

		if dist_to_sup > 28.0:
			if _supply_run_timer < 24.0:
				_move_towards_point(supplier_counter, 54.0, delta)
			else:
				# Si hubo puerta bloqueada o demora excesiva, cancelar compra sin ejecutarla a distancia
				_supply_run_target_role = 0
				_supply_run_timer = 0.0
				_supply_run_cooldown = 32.0
				if _craft_bar_root:
					_craft_bar_root.visible = false
			return

		# Ha llegado físicamente al mostrador del vecino: verifica que el artesano esté atendiendo su puesto, tenga stock y realiza la compra
		velocity = Vector2.ZERO
		if supplier_npc.is_at_shop_counter() and int(supplier_npc.shop_stock.get(_supply_run_item_id, 0)) > 0:
			var buy_cost: int = 6
			personal_gold = maxi(0, personal_gold - buy_cost)
			var biz_mode: String = "NPC"
			if vm and "shop_businesses" in vm and vm.shop_businesses.has(_supply_run_target_role):
				biz_mode = str(vm.shop_businesses[_supply_run_target_role].get("owner_mode", "NPC"))
			if biz_mode == "SOLE_OWNER":
				vm.shop_businesses[_supply_run_target_role]["vault_gold"] = int(vm.shop_businesses[_supply_run_target_role].get("vault_gold", 0)) + buy_cost
			elif biz_mode == "PARTNER":
				var player_cut: int = int(buy_cost / 2)
				vm.shop_businesses[_supply_run_target_role]["vault_gold"] = int(vm.shop_businesses[_supply_run_target_role].get("vault_gold", 0)) + player_cut
				supplier_npc.personal_gold = maxi(0, supplier_npc.personal_gold) + (buy_cost - player_cut)
			else:
				supplier_npc.personal_gold = maxi(0, supplier_npc.personal_gold) + buy_cost
			supplier_npc.shop_stock[_supply_run_item_id] = int(supplier_npc.shop_stock[_supply_run_item_id]) - 1
			if vm and "shop_businesses" in vm and vm.shop_businesses.has(_supply_run_target_role):
				vm.shop_businesses[_supply_run_target_role]["stock_override"] = supplier_npc.shop_stock.duplicate()
			workshop_materials[_supply_run_item_id] = int(workshop_materials.get(_supply_run_item_id, 0)) + 2
			trigger_action_animation(2.2)
			supplier_npc.trigger_action_animation(2.2)
			_spawn_floating_text("🛒🤝 Compró +2 %s a %s (-%d Oro)" % [_supply_run_input_label, supplier_npc.npc_name, buy_cost], Color(0.45, 0.95, 1.0), -42.0)
			supplier_npc._spawn_floating_text("💰 +%d Oro (Suministro a %s)" % [buy_cost, npc_name], Color.GOLD, -36.0)
			add_thought("Compró suministros de taller a %s (+5)" % supplier_npc.npc_name, 5.0)
			if vm and vm.has_method("_refresh_shop_stall_visual"):
				vm.call("_refresh_shop_stall_visual", _supply_run_target_role)
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
		_is_actively_crafting = false
		if _craft_bar_root:
			_craft_bar_root.visible = false
		return

	var rec: Dictionary = recipes[_crafting_recipe_idx % recipes.size()]
	var out_id: String = str(rec.get("output", ""))
	var out_label: String = str(rec.get("label", out_id))
	var verb_str: String = str(rec.get("verb", "⚒️ Elaborando"))
	var req_input: String = str(rec.get("input", ""))
	var sup_role: int = int(rec.get("supplier", 0))
	var in_label: String = str(rec.get("input_name", req_input))

	# Si el stock de este producto ya está al máximo (>= 12), pasar a la otra receta o atender mostrador
	if int(shop_stock.get(out_id, 0)) >= 12:
		_crafting_recipe_idx = (_crafting_recipe_idx + 1) % recipes.size()
		rec = recipes[_crafting_recipe_idx]
		out_id = str(rec.get("output", ""))
		out_label = str(rec.get("label", out_id))
		verb_str = str(rec.get("verb", "⚒️ Elaborando"))
		req_input = str(rec.get("input", ""))
		sup_role = int(rec.get("supplier", 0))
		in_label = str(rec.get("input_name", req_input))
		if int(shop_stock.get(out_id, 0)) >= 12:
			_is_actively_crafting = false
			if _craft_bar_root:
				_craft_bar_root.visible = false
			return

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
		if vm and "shop_businesses" in vm and vm.shop_businesses.has(int(trade_role)):
			vm.shop_businesses[int(trade_role)]["stock_override"] = shop_stock.duplicate()
		if vm and vm.has_method("_refresh_shop_stall_visual"):
			vm.call("_refresh_shop_stall_visual", int(trade_role))
		_spawn_floating_text("⚒️✨ ¡%s fabricó +1 %s!" % [npc_name, out_label], Color(0.55, 1.0, 0.68), -40.0)
		add_thought("Elaboró +1 %s en su taller (+4)" % out_label, 4.0)
		_crafting_recipe_idx = (_crafting_recipe_idx + 1) % recipes.size()

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
	var vm_sab = get_tree().get_first_node_in_group("village_manager")
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
		else:
			velocity = Vector2.ZERO
			trigger_action_animation(0.6)
			_expedition_gather_timer += delta
			if _expedition_gather_timer >= (2.2 / maxf(0.35, eff)):
				_expedition_gather_timer = 0.0
				_completed_expedition_day = cur_day
				var fish_yield: int = 2 if eff >= 0.75 else 1
				shop_stock["cooked_fish"] = int(shop_stock.get("cooked_fish", 0)) + fish_yield
				workshop_materials["wood"] = int(workshop_materials.get("wood", 0)) + 1
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
	var req_h_type: int = int(HarvestableNode.HarvestType.LOGGING)
	if trade_role == TradeRole.BLACKSMITH:
		req_h_type = int(HarvestableNode.HarvestType.MINING)
	elif trade_role == TradeRole.HERBALIST:
		req_h_type = int(HarvestableNode.HarvestType.FORAGE)

	var h_node: HarvestableNode = _expedition_target_node as HarvestableNode
	if not is_instance_valid(h_node) or h_node.is_depleted:
		_expedition_target_node = null
		if eco != null:
			h_node = eco.find_sustainable_harvest_node(req_h_type, global_position)
			_expedition_target_node = h_node
		if h_node == null:
			# El recurso está en su umbral mínimo de conservación (N <= N_min): no talar/picar/cosechar hoy
			_completed_expedition_day = cur_day
			_spawn_floating_text("🌿⚖️ Recursos del bosque en su umbral mínimo: hoy no extraeré más", Color.SPRING_GREEN, -38.0)
			add_thought("Protegió la regeneración natural del bosque (+5)", 5.0)
			return

	var dist_node: float = global_position.distance_to(h_node.global_position)
	if dist_node > 24.0:
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
			add_thought("Extracción matutina en equilibrio con el bosque (+6)", 6.0)

func _fire_hunter_arrow_at_prey(prey: WildAnimal) -> void:
	if not is_instance_valid(prey):
		return
	var tracer := Line2D.new()
	tracer.width = 1.8
	tracer.default_color = Color(0.92, 0.78, 0.45, 0.92)
	tracer.points = PackedVector2Array([
		global_position + Vector2(0, -6),
		prey.global_position + Vector2(0, -4)
	])
	tracer.z_index = 16
	var parent_scene: Node = get_tree().current_scene if get_tree().current_scene else get_parent()
	if parent_scene:
		parent_scene.add_child(tracer)
		var tw := tracer.create_tween()
		tw.tween_property(tracer, "modulate:a", 0.0, 0.16)
		tw.tween_callback(tracer.queue_free)

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
	var vm = _cached_vm if is_instance_valid(_cached_vm) else get_tree().get_first_node_in_group("village_manager")
	if vm and vm.has_method("update_traveling_merchant_ai"):
		vm.call("update_traveling_merchant_ai", self, delta)
	_apply_player_and_doorway_yield(delta)
	move_and_slide()
	_update_visual_animation(delta)
	_update_hover_label(delta)

## IA Deductiva y Persecución del Inquisidor Real Alistair (`TradeRole.ROYAL_INVESTIGATOR`):
## 1º Inspecciona la escena del crimen y la Morgue.
## 2º Interroga físicamente a los habitantes, cruzando coartadas y acumulando sospecha probabilística.
## 3º Inspecciona al jugador si pasa cerca (rango de detección 2x superior al policía común y detecta el Salvoconducto Real robado).
## 4º Filosofía Real: Nunca se va con las manos vacías; condena al sospechoso con mayor puntuación (el Jugador o un aldeano Chivo Expiatorio).
func _process_royal_investigator_ai(delta: float) -> void:
	var vm = _cached_vm if is_instance_valid(_cached_vm) else get_tree().get_first_node_in_group("village_manager")
	if vm and bool(vm.get("player_being_escorted_to_jail")) and vm.get("escorting_officer") == self:
		is_hostile = false
		remove_from_group("enemies")
		if _process_police_law_enforcement(delta, vm):
			return
	if is_hostile and vm:
		if bool(vm.get("player_in_jail")) or bool(vm.get("player_being_escorted_to_jail")):
			is_hostile = false
			remove_from_group("enemies")
			velocity = Vector2.ZERO
		elif _process_police_law_enforcement(delta, vm):
			return
	if vm and vm.has_method("update_royal_investigator_ai"):
		vm.call("update_royal_investigator_ai", self, delta)
	_apply_player_and_doorway_yield(delta)
	move_and_slide()
	_update_visual_animation(delta)
	_update_hover_label(delta)

func _find_best_social_partner() -> VillageNPC:
	var best: VillageNPC = null
	var best_score: float = -9999.0
	for node in get_tree().get_nodes_in_group("village_npcs"):
		if node == self or not (node is VillageNPC):
			continue
		var other: VillageNPC = node as VillageNPC
		if other.is_dead or other.is_downed or other.is_sleeping:
			continue
		var dist: float = global_position.distance_to(other.global_position)
		var family_bonus: float = 120.0 if (family_id != "none" and other.family_id == family_id) else 0.0
		var score: float = family_bonus - dist * 0.4 + (100.0 - other.need_social) * 0.5
		if score > best_score:
			best_score = score
			best = other
	return best

func _get_social_target_pos() -> Vector2:
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
	if is_downed:
		return "🩸 Agonizando (%ds)" % maxi(1, int(ceil(bleedout_timer)))
	if sedated_timer > 0.0:
		return "💤 Sedado (%ds)" % maxi(1, int(ceil(sedated_timer)))
	if trade_role == TradeRole.ROYAL_INVESTIGATOR:
		var vm_inv = _cached_vm if is_instance_valid(_cached_vm) else get_tree().get_first_node_in_group("village_manager")
		if vm_inv and vm_inv.has_method("get_royal_investigator_status_text"):
			return str(vm_inv.call("get_royal_investigator_status_text"))
		return "🔍👑 Investigando Asesinato Real"
	if trade_role == TradeRole.TRAVELING_MERCHANT:
		if _merchant_leaving:
			return "🧳👑 Regresando a las Tierras Reales"
		return "⚖️👑 Comerciando con Salvoconducto Real"
	match current_activity:
		ActivityState.SLEEPING:
			if is_vagrant_camper:
				return "⛺ Durmiendo a la Intemperie (Campamento)" if is_sleeping else "🚶⛺ Yendo a su Campamento Rústico"
			return "💤 Durmiendo en Cama" if is_sleeping else "🚶 Yendo a Dormir"
		ActivityState.EATING:
			if _is_amateur_foraging:
				return "🏹💦 Cazando/Recolectando Torpemente (Sin Dinero/Comida)"
			var loc := "en la Taberna" if _eat_at_tavern else ("en su Fogata" if is_vagrant_camper else "en Casa")
			return "🍲 Comiendo %s" % loc
		ActivityState.SOCIALIZING:
			if is_instance_valid(_social_partner):
				return "💬 Charlando con %s" % _social_partner.npc_name
			return "💬 Socializando"
		_:
			if _is_morning_expedition_hours():
				return _get_expedition_description()
			if _supply_run_target_role != 0:
				return "🛒 Yendo a comprar %s al taller vecino" % _supply_run_input_label
			if _is_actively_crafting:
				return "⚒️ Crafteando en Taller (%d%%)" % int(round(_craft_progress))
			if trade_role == TradeRole.DOCTOR:
				return "🩺 En Guardia de Urgencias y Morgue"
			if trade_role == TradeRole.SHERIFF:
				return "🚓 Dirigiendo la Comisaría"
			if trade_role == TradeRole.GUARD:
				return "🛡️ Patrullando la Aldea"
			if trade_role == TradeRole.UNEMPLOYED:
				return "⛺ Sobreviviendo en las Afueras" if is_vagrant_camper else "🚶 Paseando / Jornalero"
			elif trade_role == TradeRole.FAMILY_MEMBER:
				return "🏠 Turno del Hogar (08-18h)" if _is_mandatory_work_hours() else "🏠 Cuidando el Hogar"
			return "⚒️ En Turno Laboral (08-18h)" if _is_mandatory_work_hours() else "⚒️ Atendiendo su Oficio"

func _process_hostile_combat(delta: float) -> void:
	var vm = get_tree().get_first_node_in_group("village_manager")
	# Si la policía ya capturó al jugador, lo lleva esposado a la comisaría, está en la celda o está negociando su entrega,
	# los civiles y guardias detienen de inmediato la agresión física (Kenshi / RDR2 / Skyrim)
	if vm and (bool(vm.get("player_being_escorted_to_jail")) or bool(vm.get("player_in_jail")) or (vm.get("police_panel") != null and vm.police_panel.visible)):
		is_hostile = false
		_civilian_hostile_timer = 0.0
		remove_from_group("enemies")
		velocity = Vector2.ZERO
		return

	var player = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		velocity = Vector2.ZERO
		return

	var is_police_unit: bool = (trade_role in [TradeRole.SHERIFF, TradeRole.GUARD])
	if not is_police_unit:
		if _civilian_hostile_timer > 0.0:
			_civilian_hostile_timer -= delta
			if _civilian_hostile_timer <= 0.0:
				is_hostile = false
				remove_from_group("enemies")
				velocity = Vector2.ZERO
				_spawn_floating_text("😤 ¡Que la guardia se encargue de ti!", Color.GOLD, -36.0)
				return
		# Los civiles nunca entran a la Comisaría / Celda (`Rect2(832, 92, 166, 108)`) para seguir golpeando al jugador
		var police_station_rect := Rect2(832, 92, 166, 108)
		if police_station_rect.has_point(player.global_position) or police_station_rect.has_point(global_position):
			is_hostile = false
			_civilian_hostile_timer = 0.0
			remove_from_group("enemies")
			velocity = Vector2.ZERO
			return

	var to_p: Vector2 = player.global_position - global_position
	var dist: float = to_p.length()
	if dist > 30.0:
		_move_towards_point(player.global_position, 88.0, delta)
	else:
		velocity = Vector2.ZERO
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer = 1.0
			if player.has_method("take_damage"):
				var d := DamageData.new()
				d.amount = 14.0 if is_police_unit else 9.0
				d.source = self
				player.call("take_damage", d)

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
		var loot_hint: String = ("\n[E: 💰 Saquear Bolsillos (%d Oro%s)]" % [personal_gold, " + 📜Salvoconducto Real" if carries_royal_safe_conduct else ""]) if (not corpse_pocket_looted and (personal_gold > 0 or carries_royal_safe_conduct)) else ""
		status_label.text = "💫 %s (%s) — Inconsciente / Aturdido (No Letal)%s" % [npc_name, npc_role, loot_hint]
		status_label.add_theme_color_override("font_color", Color(0.65, 0.82, 1.0))
		status_label.visible = true
		return
	if _showing_stealth_prompt:
		status_label.text = "🕵️ SIGILO POR LA ESPALDA — %s\n[E / Q: 💤 Aturdir (No Letal) | Clic Izq. / V: 🗡️ Matar (Letal)]" % npc_name
		status_label.add_theme_color_override("font_color", Color(0.55, 0.98, 0.82))
		status_label.visible = true
		return

	_hover_label_timer -= delta
	if _hover_label_timer > 0.0:
		return
	_hover_label_timer = 0.10

	if not is_instance_valid(_cached_player):
		_cached_player = get_tree().get_first_node_in_group("player") as Node2D
	var player = _cached_player
	var near_player: bool = player != null and global_position.distance_squared_to(player.global_position) <= 30.0 * 30.0
	var near_mouse: bool = global_position.distance_squared_to(get_global_mouse_position()) <= 22.0 * 22.0

	if is_sleeping and not near_mouse and not near_player:
		if status_label.text != "Zzz" or not status_label.visible:
			status_label.text = "Zzz"
			status_label.add_theme_color_override("font_color", Color(0.72, 0.85, 1.0))
			status_label.visible = true
		return

	if near_player or near_mouse:
		var act_txt: String = "🃏 En la Mesa de Póker" if is_at_poker_table else get_activity_description()
		var traits_str: String = ", ".join(traits) if not traits.is_empty() else "Equilibrado"
		var eff_badge: String = (" · ⚒️" + get_job_efficiency_label()) if not (trade_role in [TradeRole.UNEMPLOYED, TradeRole.FAMILY_MEMBER]) else ""
		var nut_badge: String = get_nutrition_status_label()
		var sleep_badge: String = (" (" + get_sleep_status_label() + ")") if (need_energy < 50.0 or is_vagrant_camper) else ""
		var seal_badge: String = " · 📜Salvoconducto Real" if carries_royal_safe_conduct else ""
		status_label.text = "%s (%s) — %s%s · 💰%d Oro%s [%s]\n[%s | 😊Humor:%d%% 🍖%d%% (%s) 💤%d%%%s 💬%d%% | E: Hablar]" % [
			npc_name,
			family_name,
			npc_role,
			eff_badge,
			maxi(0, personal_gold),
			seal_badge,
			traits_str,
			act_txt,
			int(round(mood)),
			int(round(need_hunger)),
			nut_badge,
			int(round(need_energy)),
			sleep_badge,
			int(round(need_social))
		]
		status_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68))
		status_label.visible = true
	else:
		status_label.visible = false

func modify_affinity(delta_amount: int) -> void:
	affinity = clampi(affinity + delta_amount, -100, 100)
	var sign_str := "+" if delta_amount >= 0 else ""
	_spawn_floating_text("%s%d Relación" % [sign_str, delta_amount], Color.SPRING_GREEN if delta_amount >= 0 else Color.CORAL, -42.0)

func get_relationship_status_text() -> String:
	var rel := "Neutral"
	if affinity >= 45:
		rel = "Aliado Familiar (-20% Precios)"
	elif affinity >= 20:
		rel = "Amistoso"
	elif affinity <= -35:
		rel = "Familia Agraviada"
	elif affinity <= -10:
		rel = "Desconfiado"
	return "%s (%s) | %s (%d)" % [npc_role, family_name, rel, affinity]

func get_relationship_color() -> Color:
	if affinity >= 45:
		return Color.CYAN
	elif affinity >= 20:
		return Color.LIGHT_GREEN
	elif affinity <= -35:
		return Color.RED
	elif affinity <= -10:
		return Color.ORANGE
	return Color(0.85, 0.88, 0.92)

func take_damage(data: DamageData) -> void:
	if is_dead:
		return

	# Identificar arma y atacante para la autopsia forense (Paso 1 y Paso 2)
	if data and is_instance_valid(data.source):
		if data.source.is_in_group("player"):
			last_hit_by_player = true
			var eq_tool: int = int(data.source.get("equipped_tool")) if "equipped_tool" in data.source else 0
			match eq_tool:
				0: last_hit_weapon_name = "Corte de Espada"
				1: last_hit_weapon_name = "Traumatismo Contundente (Martillo)"
				2: last_hit_weapon_name = "Tajo Profundo de Hacha"
				4: last_hit_weapon_name = "Impacto de Flecha (Arco)"
				_: last_hit_weapon_name = "Arma de Herramienta"
		else:
			last_hit_by_player = false
			last_hit_weapon_name = "Desgarro por Animal/Asaltante"

	# Si ya está agonizando en el suelo y vuelven a golpearlo -> Rematar (muerte definitiva)
	if is_downed:
		_confirm_true_death()
		var vm_exec = get_tree().get_first_node_in_group("village_manager")
		if vm_exec and last_hit_by_player:
			if vm_exec.has_method("modify_family_reputation") and family_id != "none":
				vm_exec.call("modify_family_reputation", family_id, -35, "Ejecución de " + npc_name, self)
			if murder_witness_name != "" and vm_exec.has_method("report_assault_crime"):
				vm_exec.call("report_assault_crime", self)
		return

	modify_affinity(-35)
	var vm = get_tree().get_first_node_in_group("village_manager")
	if vm and last_hit_by_player:
		if vm.has_method("modify_family_reputation") and family_id != "none":
			vm.call("modify_family_reputation", family_id, -25, "Agresión a " + npc_name, self)
		if vm.has_method("report_assault_crime"):
			vm.call("report_assault_crime", self)

	is_hostile = true
	_civilian_hostile_timer = 14.0
	is_sleeping = false
	sedated_timer = 0.0
	_is_actively_crafting = false
	if _craft_bar_root:
		_craft_bar_root.visible = false
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
	var dir_to_player: Vector2 = to_player.normalized()
	var face_vec: Vector2 = facing_direction
	if face_vec.length_squared() < 0.01 and sprite != null:
		face_vec = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	# El jugador está en el hemisferio trasero / punto ciego de la espalda del NPC
	return face_vec.normalized().dot(dir_to_player) <= 0.22

## Opción No Letal en Sigilo ([E] o [Q] por la espalda): Aturde / deja inconsciente al civil sin matarlo
func stealth_knockout(player: Node = null) -> void:
	if is_dead or is_downed or is_stunned_flag or sedated_timer > 0.0:
		return
	hide_prompt()
	_is_actively_crafting = false
	if _craft_bar_root:
		_craft_bar_root.visible = false
	is_hostile = false
	_civilian_hostile_timer = 0.0
	remove_from_group("enemies")
	if body_col:
		body_col.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	sedated_timer = maxf(sedated_timer, 25.0)
	is_sleeping = true
	is_stunned_flag = true
	if sprite:
		sprite.rotation_degrees = 90.0
		sprite.modulate = Color(0.55, 0.65, 1.0)
	add_thought("Aturdido por la espalda (-12)", -12.0)
	_spawn_floating_text("💤🤫 ¡%s aturdido en sigilo! (No Letal — 25s)" % npc_name, Color.AQUA, -44.0)
	if player and player.has_method("show_hint"):
		player.call("show_hint", "💤 Has aturdido en sigilo a %s sin matarlo (Inconsciente durante 25s)." % npc_name)

	# Solo hay cargos policiales si otro testigo consciente tiene línea de visión directa del derribo
	var vm = get_tree().get_first_node_in_group("village_manager")
	if vm and vm.has_method("_find_conscious_witness_near"):
		var w: VillageNPC = vm.call("_find_conscious_witness_near", global_position, 145.0, self)
		if w != null and vm.has_method("report_assault_crime"):
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
			player.call("show_hint", "🗡️🚨 ¡%s te vio asesinar a %s! La guardia ha sido alertada." % [murder_witness_name, npc_name])
		else:
			player.call("show_hint", "🗡️🤫 Asesinato sigiloso sin testigos: el cuerpo de %s queda en el suelo." % npc_name)
	var vm = get_tree().get_first_node_in_group("village_manager")
	if murder_witness_name != "" and vm and vm.has_method("report_assault_crime"):
		vm.call("report_assault_crime", self)

func knockout() -> void:
	stealth_knockout(get_tree().get_first_node_in_group("player"))

func show_prompt() -> void:
	_showing_stealth_prompt = true
	if status_label:
		status_label.text = "🕵️ SIGILO POR LA ESPALDA — %s\n[E / Q: 💤 Aturdir (No Letal) | Clic Izq. / V: 🗡️ Matar (Letal)]" % npc_name
		status_label.add_theme_color_override("font_color", Color(0.55, 0.98, 0.82))
		status_label.visible = true

func hide_prompt() -> void:
	_showing_stealth_prompt = false
	if status_label:
		status_label.visible = false

func _on_stunned(stunned: bool) -> void:
	if is_dead or is_downed:
		return
	is_stunned_flag = stunned
	if stunned:
		_is_actively_crafting = false
		if _craft_bar_root:
			_craft_bar_root.visible = false
		is_hostile = false
		_civilian_hostile_timer = 0.0
		remove_from_group("enemies")
		if body_col:
			body_col.set_deferred("disabled", true)
		velocity = Vector2.ZERO
	if sprite:
		sprite.rotation_degrees = 90.0 if stunned else 0.0
		sprite.modulate = Color(0.55, 0.65, 1.0) if stunned else Color.WHITE

## Paso 1: Al caer a 0 HP entra primero en estado "Agonizando" (`is_downed`) con cuenta atrás según la herida
func _on_died() -> void:
	if is_dead:
		return
	if not is_downed:
		is_downed = true
		is_hostile = false
		is_sleeping = false
		sedated_timer = 0.0
		is_stunned_flag = false
		_is_actively_crafting = false
		if _craft_bar_root:
			_craft_bar_root.visible = false
		if body_col:
			body_col.set_deferred("disabled", true)
		velocity = Vector2.ZERO
		remove_from_group("enemies")
		if last_hit_weapon_name.contains("Martillo"):
			bleedout_timer = 90.0
		elif last_hit_weapon_name.contains("Espada") or last_hit_weapon_name.contains("Hacha"):
			bleedout_timer = 34.0
		else:
			bleedout_timer = 58.0
		if sprite:
			sprite.rotation_degrees = 82.0
			sprite.modulate = Color(1.1, 0.42, 0.42, 0.95)
		_spawn_floating_text("🩸 ¡%s AGONIZANDO! (%ds para salvarlo en el Hospital)" % [npc_name, int(bleedout_timer)], Color.ORANGE_RED, -44.0)
		return
	_confirm_true_death()

## Paso 1: Rescatar a un NPC que está agonizando (`is_downed`) llevándolo al Hospital o con un Botiquín Quirúrgico
func revive_from_downed(rescuer: Node, used_surgical_kit: bool = false) -> void:
	if not is_downed or is_dead:
		return
	is_downed = false
	bleedout_timer = 0.0
	is_hostile = false
	remove_from_group("enemies")
	if hurtbox and hurtbox.get_child_count() > 0:
		var hcol := hurtbox.get_child(0) as CollisionShape2D
		if hcol:
			hcol.set_deferred("disabled", false)
	if health_comp:
		health_comp.current_health = health_comp.max_health * (0.85 if used_surgical_kit else 0.65)
	if not used_surgical_kit:
		# Traslado a la Cama de Urgencias del Hospital
		global_position = Vector2(718, 142)
	if sprite:
		sprite.rotation_degrees = 0.0
		sprite.modulate = Color.WHITE
	add_thought("Me salvaron la vida en urgencias (+25)", 25.0)
	if rescuer and rescuer.is_in_group("player"):
		modify_affinity(45)
		var vm = get_tree().get_first_node_in_group("village_manager")
		if vm and vm.has_method("modify_family_reputation") and family_id != "none":
			vm.call("modify_family_reputation", family_id, 40, "Salvó la vida de " + npc_name, self)
		if "inventory" in rescuer and rescuer.inventory:
			rescuer.inventory.add_gold(25)
		if rescuer.has_method("_spawn_floating_text"):
			rescuer._spawn_floating_text("🏥 ¡Salvaste la vida de %s! (+25 Oro, +40 Afinidad Familiar)" % npc_name, Color.SPRING_GREEN, -46.0)

## Paso 1: Muerte definitiva -> el cadáver permanece en el lugar donde murió (y puede pudrirse durante días si nadie entra),
## hasta que otro NPC lo vea en sus pasos naturales y lo traslade físicamente a la Morgue Forense.
func _confirm_true_death() -> void:
	if is_dead:
		return
	death_world_pos = global_position
	death_day = WorldClock.current_day if WorldClock else 1
	death_hour = WorldClock.current_hour if WorldClock else 12
	death_minute = WorldClock.current_minute if WorldClock else 0

	var vm = get_tree().get_first_node_in_group("village_manager")
	murder_witness_name = ""
	if vm and vm.has_method("_find_conscious_witness_near"):
		var w: VillageNPC = vm.call("_find_conscious_witness_near", death_world_pos, 165.0, self)
		if w != null:
			murder_witness_name = w.npc_name

	is_downed = false
	bleedout_timer = 0.0
	is_dead = true
	is_hostile = false
	_is_actively_crafting = false
	if _craft_bar_root:
		_craft_bar_root.visible = false
	corpse_on_ground = true
	corpse_discovered = false
	corpse_discovered_by = ""
	corpse_reported = false
	corpse_reporter_npc = null
	corpse_being_carried = false
	corpse_in_morgue = false
	corpse_carrier = null
	corpse_rot_hours = 0.0
	remove_from_group("enemies")
	if body_col:
		body_col.set_deferred("disabled", true)
	if hurtbox and hurtbox.get_child_count() > 0:
		var hcol_dead := hurtbox.get_child(0) as CollisionShape2D
		if hcol_dead:
			hcol_dead.set_deferred("disabled", true)
	# Mantener InteractArea activa mientras el cadáver yace en el suelo para que el jugador pueda reportarlo con [E]
	if interact_area and interact_area.get_child_count() > 0:
		var ic := interact_area.get_child(0) as CollisionShape2D
		if ic:
			ic.set_deferred("disabled", false)
	if sprite:
		sprite.rotation_degrees = 90.0
		sprite.modulate = Color(0.68, 0.54, 0.54, 0.96)
		sprite.z_index = -1
		sprite.visible = true # Se queda en el suelo donde murió hasta que alguien lo descubra y lo lleve a la Morgue
	_spawn_floating_text("💀 %s ha muerto (El cuerpo yace en el lugar)" % npc_name, Color(0.88, 0.45, 0.45), -44.0)
	if trade_role == TradeRole.TRAVELING_MERCHANT and vm and vm.has_method("on_traveling_merchant_murdered"):
		vm.call("on_traveling_merchant_murdered", self, last_hit_weapon_name)

## Sucesión: este familiar o viajero sin oficio asume un puesto vacante en la aldea
func promote_to_trade(
	new_role: TradeRole,
	new_title: String,
	new_work_pos: Vector2,
	inherited_stock: Dictionary,
	new_tex: Texture2D = null,
	new_bed_pos: Vector2 = Vector2.ZERO,
	new_table_pos: Vector2 = Vector2.ZERO,
	new_family_id: String = "",
	new_family_name: String = ""
) -> void:
	var was_family := (trade_role == TradeRole.FAMILY_MEMBER)
	trade_role = new_role
	days_in_role = 2 if was_family else 0
	npc_role = new_title + (" (Herencia Familiar)" if was_family else " (Sucesor)")
	work_position = new_work_pos
	if new_bed_pos != Vector2.ZERO:
		bed_position = new_bed_pos
	if new_table_pos != Vector2.ZERO:
		home_table_pos = new_table_pos
	if new_family_id != "":
		family_id = new_family_id
	if new_family_name != "":
		family_name = new_family_name
	shop_stock = inherited_stock.duplicate()
	is_vagrant_camper = false
	_init_workshop_materials()
	_resolve_unique_64_visuals_and_lore(new_tex)
	var vm_prom = _cached_vm if is_instance_valid(_cached_vm) else get_tree().get_first_node_in_group("village_manager")
	if vm_prom and "vagrant_camp_nodes" in vm_prom and vm_prom.vagrant_camp_nodes.has(npc_name):
		var c_node = vm_prom.vagrant_camp_nodes[npc_name]
		if is_instance_valid(c_node):
			c_node.visible = false

func _inject_character_lore_into_dialogue(diag: Dictionary) -> Dictionary:
	if not diag.has("start") or typeof(diag["start"]) != TYPE_DICTIONARY:
		return diag
	var start_node: Dictionary = diag["start"]
	if not start_node.has("choices") or typeof(start_node["choices"]) != TYPE_ARRAY:
		return diag
	var ch_arr: Array = start_node["choices"]
	# Si está agraviado (compensate_family), no añadir charla amistosa hasta reconciliar
	for c in ch_arr:
		if typeof(c) == TYPE_DICTIONARY and str(c.get("action", "")) == "compensate_family":
			return diag

	var lore_choice: Dictionary = {
		"label": "📖 Conocer la historia personal y el pasado de %s (+10 Relación)" % npc_name,
		"next": "character_lore",
		"affinity": 10
	}
	var insert_idx: int = maxi(0, ch_arr.size() - 1)
	ch_arr.insert(insert_idx, lore_choice)

	if need_hunger < 75.0:
		var feed_choice: Dictionary = {
			"label": "🍲 Darle 1 ración de comida de tu mochila (%s) para que se recupere gradualmente (+18 Relación)" % get_nutrition_status_label(),
			"next": "start",
			"action": "give_npc_food_ration"
		}
		ch_arr.insert(insert_idx, feed_choice)

	diag["character_lore"] = {
		"text": "📜 Historia de %s (%s):\n%s" % [npc_name, npc_role, character_lore],
		"choices": [
			{"label": "🔍 Preguntar por lo que calla o ha observado en el valle (+6 Relación)", "next": "character_secret", "affinity": 6},
			{"label": "⬅️ Volver a la conversación principal", "next": "start"}
		]
	}
	diag["character_secret"] = {
		"text": "🤫 Confidencia de %s:\n%s" % [npc_name, character_secret],
		"choices": [
			{"label": "Guardaré el secreto. [Volver]", "next": "start"}
		]
	}
	return diag

func loot_npc_pockets(player: Node) -> bool:
	if corpse_pocket_looted or (personal_gold <= 0 and not carries_royal_safe_conduct):
		return false
	if not player or not ("inventory" in player) or not player.inventory:
		return false
	var inv: SimpleInventory = player.inventory
	var looted_gold: int = maxi(0, personal_gold)
	var got_seal: bool = carries_royal_safe_conduct
	personal_gold = 0
	carries_royal_safe_conduct = false
	corpse_pocket_looted = true
	if looted_gold > 0:
		inv.add_gold(looted_gold)
	if got_seal:
		inv.add_item("royal_safe_conduct", 1)
	var msg: String = "💰 Saqueaste +%d Oro de %s" % [looted_gold, npc_name]
	if got_seal:
		msg += " + 📜 ¡SALVOCONDUCTO REAL SELLADO!"
	_spawn_floating_text(msg, Color.GOLD, -44.0)
	if player.has_method("show_hint"):
		player.call("show_hint", msg + (" (Oculta el Salvoconducto Real en un cofre si viene el Inquisidor Real)" if got_seal else ""))
	var vm = get_tree().get_first_node_in_group("village_manager")
	if vm and vm.has_method("_find_conscious_witness_near"):
		var w: VillageNPC = vm.call("_find_conscious_witness_near", global_position, 140.0, self)
		if w != null and vm.has_method("report_theft_crime"):
			vm.call("report_theft_crime", family_id, "Saqueo de bolsillos a " + npc_name, global_position)
	return true

func interact(player: Node) -> void:
	if is_dead:
		if not corpse_pocket_looted and (personal_gold > 0 or carries_royal_safe_conduct):
			loot_npc_pockets(player)
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
	# Al conversar con el jugador, el NPC detiene lo que está haciendo, mira al jugador y satisface parte de su necesidad social
	velocity = Vector2.ZERO
	_is_actively_crafting = false
	if _craft_bar_root:
		_craft_bar_root.visible = false
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

func _get_needs_status_line() -> String:
	var traits_str: String = ", ".join(traits) if not traits.is_empty() else "Equilibrado"
	var last_thought: String = thoughts[0] if not thoughts.is_empty() else "Todo tranquilo"
	var fav_name: String = str(SimpleInventory.CATALOG.get(favorite_item, {}).get("name", favorite_item))
	var eff_info: String = ""
	if not (trade_role in [TradeRole.UNEMPLOYED, TradeRole.FAMILY_MEMBER]):
		var shop_state: String = ""
		if trade_role in [TradeRole.BLACKSMITH, TradeRole.BUTCHER, TradeRole.CARPENTER, TradeRole.FISHMONGER, TradeRole.HERBALIST, TradeRole.INNKEEPER]:
			shop_state = " · 🟢 En Mostrador" if is_at_shop_counter() else " · 🔴 Fuera del Mostrador (No vende aquí)"
		eff_info = " | ⚒️ Dominio: %s%s" % [get_job_efficiency_label(), shop_state]
	var seal_str: String = " · 📜Salvoconducto Real" if carries_royal_safe_conduct else ""
	return "[%s%s | 💰 Oro: %d%s | 😊 Humor: %d%% | 🍖%d%% (%s) 💤%d%% (%s) 💬%d%%]\n[Rasgos: %s | Favorito: %s | 💭 \"%s\"]" % [
		get_activity_description(),
		eff_info,
		maxi(0, personal_gold),
		seal_str,
		int(round(mood)),
		int(round(need_hunger)),
		get_nutrition_status_label(),
		int(round(need_energy)),
		get_sleep_status_label(),
		int(round(need_social)),
		traits_str,
		fav_name,
		last_thought
	]

func _get_market_header_line() -> String:
	var vm = get_tree().get_first_node_in_group("village_manager")
	if not vm:
		return ""
	var mkt_txt: String = str(vm.call("get_trade_market_status_text", int(trade_role))) if vm.has_method("get_trade_market_status_text") else "⚖️ Estable"
	var own_badge: String = str(vm.call("get_business_owner_badge", int(trade_role))) if vm.has_method("get_business_owner_badge") else ""
	return "\n[📊 Oferta/Demanda: %s%s]" % [mkt_txt, own_badge]

func _get_dynamic_sell_price(base_price: int) -> int:
	var vm = get_tree().get_first_node_in_group("village_manager")
	var mult: float = float(vm.call("get_trade_market_multiplier", int(trade_role))) if (vm and vm.has_method("get_trade_market_multiplier")) else 1.0
	return maxi(1, int(round(float(base_price) * mult)))

func _get_dynamic_buy_price(base_price: int) -> int:
	var vm = get_tree().get_first_node_in_group("village_manager")
	var mult: float = float(vm.call("get_trade_market_multiplier", int(trade_role))) if (vm and vm.has_method("get_trade_market_multiplier")) else 1.0
	var is_owner: bool = bool(vm.call("is_player_owner_or_partner", int(trade_role))) if (vm and vm.has_method("is_player_owner_or_partner")) else false
	var disc: float = 0.70 if is_owner else (0.80 if affinity >= 45 else 1.0)
	return maxi(1, int(round(float(base_price) * mult * disc)))

func _build_blacksmith_dialogue(needs_line: String) -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	var catalog_dict: Dictionary = player.get("TOOL_UPGRADE_CATALOG") if (player and "TOOL_UPGRADE_CATALOG" in player) else {}
	var upgrade_choices: Array[Dictionary] = []
	var tool_order: Array[String] = ["sword", "hammer", "axe", "pickaxe", "bow", "sickle", "watering_can", "fishing_rod"]
	for t_id in tool_order:
		var cur_tier: int = 1
		if player and player.has_method("get_tool_tier"):
			cur_tier = int(player.call("get_tool_tier", t_id))
		var t_meta: Dictionary = catalog_dict.get(t_id, {})
		var t_title: String = str(t_meta.get("title", t_id))
		if cur_tier >= 3:
			upgrade_choices.append({
				"label": "★ %s [Nivel 3 Acero Maestro — MÁXIMO]" % t_title,
				"next": "upgrade_menu"
			})
		else:
			var next_tier: int = cur_tier + 1
			var tier_info: Dictionary = t_meta.get("tiers", {}).get(next_tier, {})
			var g_cost: int = int(tier_info.get("gold", 25))
			var mats: Dictionary = tier_info.get("mats", {})
			var mat_parts: Array[String] = []
			for m_id in mats.keys():
				var m_name: String = str(SimpleInventory.CATALOG.get(str(m_id), {}).get("name", str(m_id)))
				mat_parts.append("%d %s" % [int(mats[m_id]), m_name])
			upgrade_choices.append({
				"label": "⬆️ Mejorar %s a Nv.%d (%d Oro + %s)" % [t_title, next_tier, g_cost, ", ".join(mat_parts)],
				"next": "upgrade_menu",
				"action": "upgrade_tool:" + t_id
			})
	upgrade_choices.append({"label": "⬅️ Volver al mostrador de la Herrería", "next": "start"})

	return {
		"start": {
			"text": "Soy %s de la %s (%s). %s%s\n¡Bienvenido a la Gran Herrería y Armería! Aquí forjo armaduras y mejoro tus herramientas." % [npc_name, family_name, npc_role, needs_line, _get_market_header_line()],
			"choices": [
				{"label": "📜 Negocio, Escritura de Propiedad y Caja Registradora", "next": "END", "action": "open_business_panel"},
				{"label": "⚒️ Mejorar Armas y Herramientas (Nv.1 -> Nv.2 Hierro -> Nv.3 Acero)", "next": "upgrade_menu"},
				{"label": "🛡️ Comprar Armaduras (Cuero, Hierro y Acero — 4 Piezas)", "next": "armor_menu"},
				{"label": "🔥 Fundir 1 Lingote de Acero (-10 Oro, 2 Mineral Hierro, 1 Madera)", "next": "start", "action": "forge_steel"},
				{"label": "⚙️ Vender 1 Chatarra/Reliquia de Bandido (+%d Oro)" % _get_dynamic_sell_price(18), "next": "start", "action": "sell:bandit_scrap:18"},
				{"label": "💎 Vender 1 Mineral de Hierro (+%d Oro)" % _get_dynamic_sell_price(14), "next": "start", "action": "sell:iron_ore:14"},
				{"label": "🪨 Vender 1 Piedra (+%d Oro)" % _get_dynamic_sell_price(7), "next": "start", "action": "sell:stone:7"},
				{"label": "🪵 Comprar 1 Tablones Reforzados (-%d Oro) [Stock: %d]" % [_get_dynamic_buy_price(16), int(shop_stock.get("repair_kit", 0))], "next": "start", "action": "buy:repair_kit:16"},
				{"label": "💬 Charlar sobre la forja (+8 Relación)", "next": "family_chat", "affinity": 8},
				{"label": "Nos vemos. [Salir]", "next": "END"}
			]
		},
		"upgrade_menu": {
			"text": "⚒️ Yunque de Mejora de Herramientas y Armas (Estilo Stardew Valley):\nElige qué herramienta o arma deseas forjar al siguiente nivel:",
			"choices": upgrade_choices
		},
		"armor_menu": {
			"text": "🛡️ Armería de Thoran (Casco, Pecho, Piernas y Botas):\nEquípalas desde tu Mochila [I] para reducir daño físico, sangrado y aturdimiento.",
			"choices": [
				{"label": "🟫 Ver Armaduras de Cuero Curtido (Ligeras, sin penalización de velocidad)", "next": "armor_leather"},
				{"label": "⬜ Ver Armaduras de Hierro Forjado (Defensa media, muy resistentes)", "next": "armor_iron"},
				{"label": "🟦 Ver Armaduras de Acero Maestro (Máxima protección del valle)", "next": "armor_steel"},
				{"label": "⬅️ Volver al mostrador", "next": "start"}
			]
		},
		"armor_leather": {
			"text": "🟫 Set de Armadura de Cuero Curtido (Tier 1):",
			"choices": [
				{"label": "🪖 Comprar Capucha de Cuero (-18 Oro) [+6% Def]", "next": "armor_leather", "action": "buy_armor:helm_leather:18"},
				{"label": "🦺 Comprar Jubón de Cuero (-28 Oro) [+12% Def]", "next": "armor_leather", "action": "buy_armor:chest_leather:28"},
				{"label": "👖 Comprar Grebas de Cuero (-22 Oro) [+8% Def]", "next": "armor_leather", "action": "buy_armor:legs_leather:22"},
				{"label": "🥾 Comprar Botas de Cuero (-16 Oro) [+5% Def, +3% Vel]", "next": "armor_leather", "action": "buy_armor:boots_leather:16"},
				{"label": "⬅️ Volver a Categorías de Armadura", "next": "armor_menu"}
			]
		},
		"armor_iron": {
			"text": "⬜ Set de Armadura de Hierro Forjado (Tier 2):",
			"choices": [
				{"label": "🪖 Comprar Yelmo de Hierro (-36 Oro) [+11% Def]", "next": "armor_iron", "action": "buy_armor:helm_iron:36"},
				{"label": "🦺 Comprar Coraza de Hierro (-52 Oro) [+20% Def]", "next": "armor_iron", "action": "buy_armor:chest_iron:52"},
				{"label": "👖 Comprar Quijotes de Hierro (-42 Oro) [+14% Def]", "next": "armor_iron", "action": "buy_armor:legs_iron:42"},
				{"label": "🥾 Comprar Escarpes de Hierro (-32 Oro) [+9% Def]", "next": "armor_iron", "action": "buy_armor:boots_iron:32"},
				{"label": "⬅️ Volver a Categorías de Armadura", "next": "armor_menu"}
			]
		},
		"armor_steel": {
			"text": "🟦 Set de Armadura de Acero Maestro (Tier 3):",
			"choices": [
				{"label": "🪖 Comprar Gran Yelmo de Acero (-68 Oro) [+16% Def]", "next": "armor_steel", "action": "buy_armor:helm_steel:68"},
				{"label": "🦺 Comprar Armadura Real de Acero (-95 Oro) [+28% Def]", "next": "armor_steel", "action": "buy_armor:chest_steel:95"},
				{"label": "👖 Comprar Grebas de Acero Maestro (-78 Oro) [+20% Def]", "next": "armor_steel", "action": "buy_armor:legs_steel:78"},
				{"label": "🥾 Comprar Botas de Acero Maestro (-62 Oro) [+13% Def]", "next": "armor_steel", "action": "buy_armor:boots_steel:62"},
				{"label": "⬅️ Volver a Categorías de Armadura", "next": "armor_menu"}
			]
		},
		"family_chat": {
			"text": "Ahora tengo mi propio edificio de Herrería separado de nuestra casa familiar. Tráeme mineral de hierro y oro cuando quieras subir tus herramientas a Hierro o Acero Maestro.",
			"choices": [{"label": "Buen trabajo, maestro Thoran. [Volver]", "next": "start"}]
		}
	}

func _build_dialogue() -> Dictionary:
	var needs_line := _get_needs_status_line()
	var discount_tag: String = " [🌟 Aliado Familiar: -20% Dto]" if affinity >= 45 else ""

	# Paso 4: Si la familia está agraviada (`affinity <= -35`) por robo o agresión, exige compensación antes de comerciar
	if affinity <= -35 and not (trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.DOCTOR, TradeRole.ROYAL_INVESTIGATOR, TradeRole.TRAVELING_MERCHANT]):
		return {
			"start": {
				"text": "😠 ¡Soy %s de la %s! Has agraviado a nuestra familia (Afinidad: %d).\nNo comerciaremos contigo hasta que repares el daño o cumplas con la ley." % [npc_name, family_name, affinity],
				"choices": [
					{"label": "💰 Pagar Compensación Familiar (-20 Oro -> Reconciliar a toda la %s)" % family_name, "next": "END", "action": "compensate_family"},
					{"label": "Me marcharé. [Salir]", "next": "END"}
				]
			}
		}

	match trade_role:
		TradeRole.DOCTOR:
			return {
				"start": {
					"text": "Soy el %s (%s). %s%s\nDirijo el Hospital de Urgencias y la Morgue Forense. Si alguien cae herido grave (`Agonizando`), tráelo aquí con [E] antes de que se desangre y te recompensaré con 25 Oro." % [npc_name, npc_role, needs_line, discount_tag],
					"choices": [
						{"label": "🏥 Recibir Cura Médica Completa (+100% Vida y Curar Sangrado) (-10 Oro)", "next": "start", "action": "doctor_heal"},
						{"label": "🩺 Comprar 1 Botiquín Quirúrgico (-24 Oro) [Revive agonizantes o +85 HP]", "next": "start", "action": "buy_unlimited:surgical_kit:24"},
						{"label": "🌿 Comprar 1 Cataplasma Curativa (-10 Oro)", "next": "start", "action": "buy_unlimited:herbal_poultice:10"},
						{"label": "⚰️ Consultar Informes Forenses de la Morgue", "next": "morgue_info"},
						{"label": "Gracias, doctor. [Salir]", "next": "END"}
					]
				},
				"morgue_info": {
					"text": "En la sala trasera está la Morgue Forense con 3 mesas de autopsia. Si ocurre una muerte, puedes acercarte a la camilla y pulsar [E] para leer el dictamen forense: hora exacta, arma empleada y si algún vecino vio entrar al sospechoso.",
					"choices": [{"label": "Entendido, revisaré las mesas de la Morgue. [Volver]", "next": "start"}]
				}
			}
		TradeRole.SHERIFF, TradeRole.GUARD:
			var vm = get_tree().get_first_node_in_group("village_manager")
			var w_lvl: int = int(vm.get("wanted_level")) if vm else 0
			var b_gold: int = int(vm.get("bounty_gold")) if vm else 0
			var status_crime: String = "✅ Sin cargos pendientes" if w_lvl <= 0 else ("🚨 BUSCADO (Nivel %d | Multa: %d Oro)" % [w_lvl, b_gold])
			return {
				"start": {
					"text": "Soy %s (%s). %s\nEstado Policial: %s\nDesde la Comisaría vigilamos las calles y cruzamos los registros de testigos con las autopsias de la Morgue." % [npc_name, npc_role, needs_line, status_crime],
					"choices": [
						{"label": "⚖️ Pagar Multa / Fianza Policial para limpiar historial (-%d Oro)" % maxi(15, b_gold), "next": "start", "action": "pay_police_bounty"},
						{"label": "🔒 Entregarse voluntariamente y cumplir condena en la Celda hasta las 06:00 AM", "next": "END", "action": "surrender_to_jail"},
						{"label": "⚙️ Entregar 1 Reliquia/Chatarra de Bandido por Recompensa (+22 Oro)", "next": "start", "action": "sell:bandit_scrap:22"},
						{"label": "💬 Preguntar cómo funciona la investigación de crímenes", "next": "crime_explain"},
						{"label": "Seguiré mi camino. [Salir]", "next": "END"}
					]
				},
				"crime_explain": {
					"text": "Si entras a una casa sin usar Sigilo [C] y un vecino te ve, recordará la hora y el edificio. Si luego aparece un cadáver en la Morgue de ese edificio, sabremos que fuiste tú. ¡Pero si nadie te ve entrar ni atacar, será un caso sin resolver!",
					"choices": [{"label": "Un sistema implacable. [Volver]", "next": "start"}]
				}
			}
		TradeRole.BUTCHER:
			return {
				"start": {
					"text": "Soy %s de la %s (%s). %s%s%s\n[Stock Carne Cocida: %d | Pollo Asado: %d]" % [npc_name, family_name, npc_role, needs_line, discount_tag, _get_market_header_line(), int(shop_stock.get("cooked_meat", 0)), int(shop_stock.get("roasted_chicken", 2))],
					"choices": [
						{"label": "📜 Negocio, Escritura de Propiedad y Caja Registradora", "next": "END", "action": "open_business_panel"},
						{"label": "🥚✨ Vender 1 Huevo Dorado Genética Nv.3 (+%d Oro)" % _get_dynamic_sell_price(32), "next": "start", "action": "sell:golden_egg:32"},
						{"label": "🦌 Vender 1 Astas de Ciervo (+%d Oro)" % _get_dynamic_sell_price(20), "next": "start", "action": "sell:antlers:20"},
						{"label": "🦊 Vender 1 Piel de Zorro (+%d Oro)" % _get_dynamic_sell_price(18), "next": "start", "action": "sell:fox_pelt:18"},
						{"label": "🐸 Vender 1 Ancas de Rana Crudas (+%d Oro)" % _get_dynamic_sell_price(11), "next": "start", "action": "sell:frog_legs:11"},
						{"label": "👜 Vender 1 Cuero Animal (+%d Oro)" % _get_dynamic_sell_price(10), "next": "start", "action": "sell:leather:10"},
						{"label": "🦴 Vender 1 Huesos / Tendones / Grasa (+%d Oro)" % _get_dynamic_sell_price(8), "next": "anatomy_sell"},
						{"label": "🥩 Vender 1 Carne Cruda (+%d Oro) o Pollo Crudo (+%d Oro)" % [_get_dynamic_sell_price(8), _get_dynamic_sell_price(9)], "next": "start", "action": "sell:raw_meat:8"},
						{"label": "🍖 Comprar 1 Carne Cocida (-%d Oro) [Stock: %d]" % [_get_dynamic_buy_price(10), int(shop_stock.get("cooked_meat", 0))], "next": "start", "action": "buy:cooked_meat:10"},
						{"label": "💬 Charlar sobre su familia y rutina (+8 Relación)", "next": "family_chat", "affinity": 8},
						{"label": "Hasta luego. [Salir]", "next": "END"}
					]
				},
				"anatomy_sell": {
					"text": "🦴 Compra de Despiece Anatómico Avanzado (Huesos, Tendones y Grasa):",
					"choices": [
						{"label": "🦴 Vender 1 Huesos Limpios (+%d Oro)" % _get_dynamic_sell_price(7), "next": "anatomy_sell", "action": "sell:bones:7"},
						{"label": "🧬 Vender 1 Tendones y Vísceras (+%d Oro)" % _get_dynamic_sell_price(9), "next": "anatomy_sell", "action": "sell:sinew_viscera:9"},
						{"label": "🕯️ Vender 1 Grasa Animal (+%d Oro)" % _get_dynamic_sell_price(8), "next": "anatomy_sell", "action": "sell:animal_fat:8"},
						{"label": "🍗 Vender 1 Pollo Crudo (+%d Oro)" % _get_dynamic_sell_price(9), "next": "anatomy_sell", "action": "sell:raw_chicken:9"},
						{"label": "⬅️ Volver al mostrador", "next": "start"}
					]
				},
				"family_chat": {
					"text": "En nuestra carnicería curtimos pieles y aprovechamos cada pieza anatómica. Si crías animales bien alimentados de Genética Nv.3, sus productos valen una fortuna.",
					"choices": [{"label": "Entendido. [Volver]", "next": "start"}]
				}
			}
		TradeRole.BLACKSMITH:
			return _build_blacksmith_dialogue(needs_line + discount_tag)
		TradeRole.CARPENTER:
			return {
				"start": {
					"text": "Soy %s de la %s (%s). %s%s%s\n[Stock Tablones: %d | Madera: %d]" % [npc_name, family_name, npc_role, needs_line, discount_tag, _get_market_header_line(), int(shop_stock.get("repair_kit", 0)), int(shop_stock.get("wood", 0))],
					"choices": [
						{"label": "📜 Negocio, Escritura de Propiedad y Caja Registradora", "next": "END", "action": "open_business_panel"},
						{"label": "🛖 Construir Cabaña de Madera en tu Campamento (Nv.2: -30 Oro)", "next": "start", "action": "upgrade_camp_house:2:30"},
						{"label": "🏡 Construir Casa de Piedra con Cofre Propio (Nv.3: -55 Oro)", "next": "start", "action": "upgrade_camp_house:3:55"},
						{"label": "⚡ Comprar 1 Bobina de Cobre para Generador/Aspersor (-%d Oro)" % _get_dynamic_buy_price(16), "next": "start", "action": "buy_unlimited:copper_coil:16"},
						{"label": "🪵 Vender 1 Madera (+%d Oro)" % _get_dynamic_sell_price(8), "next": "start", "action": "sell:wood:8"},
						{"label": "🔨 Comprar 1 Tablones Reforzados (-%d Oro) [Stock: %d]" % [_get_dynamic_buy_price(15), int(shop_stock.get("repair_kit", 0))], "next": "start", "action": "buy:repair_kit:15"},
						{"label": "🌲 Comprar 1 Madera (-%d Oro) [Stock: %d]" % [_get_dynamic_buy_price(9), int(shop_stock.get("wood", 0))], "next": "start", "action": "buy:wood:9"},
						{"label": "💬 Charlar un rato (+8 Relación)", "next": "family_chat", "affinity": 8},
						{"label": "Hasta pronto. [Salir]", "next": "END"}
					]
				},
				"family_chat": {
					"text": "Construimos todas las casas de esta aldea con muros sólidos y puertas de madera. Si quieres ampliar tu tienda de campaña a una Cabaña o Casa de Piedra con Cofre, yo mismo te la levanto.",
					"choices": [{"label": "Así se hace. [Volver]", "next": "start"}]
				}
			}
		TradeRole.HERBALIST:
			return {
				"start": {
					"text": "Soy %s de la %s (%s). %s%s%s\n[Semillas Zanahoria: %d | Col: %d | Trigo: %d]" % [npc_name, family_name, npc_role, needs_line, discount_tag, _get_market_header_line(), int(shop_stock.get("carrot_seeds", 0)), int(shop_stock.get("cabbage_seeds", 0)), int(shop_stock.get("wheat_seeds", 0))],
					"choices": [
						{"label": "📜 Negocio, Escritura de Propiedad y Caja Registradora", "next": "END", "action": "open_business_panel"},
						{"label": "🧪 Comprar 1 Somnífero Nocturno (-%d Oro) [Duerme a un NPC 40s sin matarlo]" % _get_dynamic_buy_price(18), "next": "start", "action": "buy_unlimited:sleeping_draught:18"},
						{"label": "⚡ Comprar 1 Tónico de Ligereza (-%d Oro) [+30%% Velocidad]" % _get_dynamic_buy_price(15), "next": "start", "action": "buy_unlimited:speed_tonic:15"},
						{"label": "🩺 Comprar 1 Botiquín Quirúrgico (-%d Oro)" % _get_dynamic_buy_price(24), "next": "start", "action": "buy_unlimited:surgical_kit:24"},
						{"label": "🥬 Vender 1 Col de Huerta (+%d Oro)" % _get_dynamic_sell_price(12), "next": "start", "action": "sell:cabbage:12"},
						{"label": "🥕 Vender 1 Zanahoria Fresca (+%d Oro)" % _get_dynamic_sell_price(8), "next": "start", "action": "sell:carrot:8"},
						{"label": "🌱 Comprar 2 Semillas de Zanahoria (-%d Oro)" % _get_dynamic_buy_price(6), "next": "start", "action": "buy2:carrot_seeds:6"},
						{"label": "🌱 Comprar 2 Semillas de Col (-%d Oro)" % _get_dynamic_buy_price(8), "next": "start", "action": "buy2:cabbage_seeds:8"},
						{"label": "🌾 Comprar 2 Semillas de Trigo (-%d Oro)" % _get_dynamic_buy_price(8), "next": "start", "action": "buy2:wheat_seeds:8"},
						{"label": "Salir.", "next": "END"}
					]
				}
			}
		TradeRole.FISHMONGER:
			return {
				"start": {
					"text": "Soy %s de la %s (%s). %s%s%s\n[Stock Pan: %d | Abono: %d]" % [npc_name, family_name, npc_role, needs_line, discount_tag, _get_market_header_line(), int(shop_stock.get("bread", 0)), int(shop_stock.get("fertilizer", 0))],
					"choices": [
						{"label": "📜 Negocio, Escritura de Propiedad y Caja Registradora", "next": "END", "action": "open_business_panel"},
						{"label": "Vender 1 Siluro Nocturno (+%d Oro)" % _get_dynamic_sell_price(22), "next": "start", "action": "sell:night_catfish:22"},
						{"label": "Vender 1 Carpa Dorada (+%d Oro)" % _get_dynamic_sell_price(15), "next": "start", "action": "sell:golden_carp:15"},
						{"label": "Vender 1 Trucha de Río (+%d Oro)" % _get_dynamic_sell_price(10), "next": "start", "action": "sell:river_trout:10"},
						{"label": "Vender 1 Gavilla de Trigo (+%d Oro)" % _get_dynamic_sell_price(9), "next": "start", "action": "sell:wheat:9"},
						{"label": "Comprar 1 Hogaza de Pan (-%d Oro) [Stock: %d]" % [_get_dynamic_buy_price(8), int(shop_stock.get("bread", 0))], "next": "start", "action": "buy:bread:8"},
						{"label": "Comprar 1 Abono Orgánico (-%d Oro) [Stock: %d]" % [_get_dynamic_buy_price(6), int(shop_stock.get("fertilizer", 0))], "next": "start", "action": "buy:fertilizer:6"},
						{"label": "Salir.", "next": "END"}
					]
				}
			}
		TradeRole.INNKEEPER:
			return {
				"start": {
					"text": "¡Bienvenido a la Posada y Casino El Jabalí Dorado! Soy %s, Chef y Posadera. %s%s%s\nAquí el tiempo se detiene mientras juegas al Póker, Blackjack, Ruleta o Billar con los vecinos." % [npc_name, needs_line, discount_tag, _get_market_header_line()],
					"choices": [
						{"label": "🃏🎱 Sentarse a la Mesa de Casino y Billar (Póker, 21, Ruleta y Billar)", "next": "END", "action": "open_tavern_games"},
						{"label": "🛌 Alquilar habitación y dormir hasta las 06:00 AM (-8 Oro)", "next": "END", "action": "rent_tavern_bed"},
						{"label": "🍗 Comprar 1 Pollo Asado Crujiente (-%d Oro)" % _get_dynamic_buy_price(13), "next": "start", "action": "buy_unlimited:roasted_chicken:13"},
						{"label": "🐸 Vender 1 Ancas de Rana al Ajillo (+%d Oro)" % _get_dynamic_sell_price(24), "next": "start", "action": "sell:fried_frog_legs:24"},
						{"label": "🍲 Comprar 1 Estofado Campesino (-%d Oro) [Stock: %d]" % [_get_dynamic_buy_price(14), int(shop_stock.get("country_stew", 0))], "next": "start", "action": "buy:country_stew:14"},
						{"label": "🍞 Comprar 1 Hogaza de Pan (-%d Oro) [Stock: %d]" % [_get_dynamic_buy_price(7), int(shop_stock.get("bread", 0))], "next": "start", "action": "buy:bread:7"},
						{"label": "Solo pasaba a saludar. [Salir]", "next": "END"}
					]
				}
			}
		TradeRole.FAMILY_MEMBER:
			return {
				"start": {
					"text": "Soy %s de la %s (%s). %s\n%s" % [npc_name, family_name, npc_role, needs_line, character_tagline],
					"choices": [
						{"label": "🎁 Regalar 1 Hogaza de Pan para su mesa familiar (+22 Relación)", "next": "start", "action": "gift_bread"},
						{"label": "Hasta luego. [Salir]", "next": "END"}
					]
				}
			}
		TradeRole.TRAVELING_MERCHANT:
			if merchant_id == "casimir":
				return {
					"start": {
						"text": "Soy %s (%s). %s\nPorto el 📜 Salvoconducto Real de la Cancillería (Presupuesto actual: 💰 %d Oro). Paso una vez por semana para comprar herramientas manufacturadas, lingotes y madera labrada para las cuencas mineras del norte." % [npc_name, npc_role, needs_line, maxi(0, personal_gold)],
						"choices": [
							{"label": "🔥 Vender 1 Lingote de Acero (+38 Oro) [Solo compra manufacturas]", "next": "start", "action": "sell:steel_ingot:38"},
							{"label": "🔨 Vender 1 Tablones Reforzados (+24 Oro)", "next": "start", "action": "sell:repair_kit:24"},
							{"label": "⚡ Vender 1 Bobina de Cobre (+26 Oro)", "next": "start", "action": "sell:copper_coil:26"},
							{"label": "⚙️ Vender 1 Reliquia/Chatarra de Ruinas (+25 Oro)", "next": "start", "action": "sell:bandit_scrap:25"},
							{"label": "💎 Vender 1 Mineral de Hierro (+18 Oro)", "next": "start", "action": "sell:iron_ore:18"},
							{"label": "🗝️👑 Comprar 1 Ganzúa Maestra de Relojero (-48 Oro) [-65% detección al forzar puertas/cofres]", "next": "start", "action": "buy_unlimited:master_lockpick:48"},
							{"label": "🪤👑 Comprar 1 Cepo de Acero de Frontera (-26 Oro) [Trampa desplegable: 35 Daño + 100 Stun]", "next": "start", "action": "buy_unlimited:steel_bear_trap:26"},
							{"label": "🥫👑 Comprar 1 Conserva Real de Extramuros (-22 Oro) [Importación Real]", "next": "start", "action": "buy_unlimited:royal_ration:22"},
							{"label": "📜 Preguntar por su Salvoconducto Real y las Tierras Reales", "next": "safe_conduct_info"},
							{"label": "Buen viaje, Maese Casimir. [Salir]", "next": "END"}
						]
					},
					"safe_conduct_info": {
						"text": "«Este Salvoconducto Real lleva el sello lacrado del Canciller. Es el único documento que permite cruzar los puestos de guardia que rodean este valle.\n\nY no se te ocurra asaltar a un enviado real: si falto a mi cita en la capital, suspenderán las caravanas durante un mes entero y enviarán al Inquisidor Real Alistair a buscar un culpable.»",
						"choices": [{"label": "Lo tendré muy en cuenta. [Volver]", "next": "start"}]
					}
				}
			else:
				return {
					"start": {
						"text": "Soy %s (%s). %s\nPorto el 📜 Salvoconducto Real (Presupuesto actual: 💰 %d Oro). En las Tierras Reales cazar está prohibido bajo pena de horca, pero como este valle está tan aislado el Rey lo tolera. Vengo una vez por semana a comprar legalmente pieles y carnes para revenderlas fuera." % [npc_name, npc_role, needs_line, maxi(0, personal_gold)],
						"choices": [
							{"label": "🦌 Vender 1 Astas de Ciervo (+30 Oro) [Alta demanda en la Corte]", "next": "start", "action": "sell:antlers:30"},
							{"label": "🦊 Vender 1 Piel de Zorro (+28 Oro)", "next": "start", "action": "sell:fox_pelt:28"},
							{"label": "🥚✨ Vender 1 Huevo Dorado Genética Nv.3 (+44 Oro)", "next": "start", "action": "sell:golden_egg:44"},
							{"label": "👜 Vender 1 Cuero Curtido (+16 Oro)", "next": "start", "action": "sell:leather:16"},
							{"label": "🍖 Vender 1 Carne Cocida (+15 Oro) o Carne Cruda (+12 Oro)", "next": "start", "action": "sell:cooked_meat:15"},
							{"label": "🦴 Vender 1 Huesos Limpios (+11 Oro)", "next": "start", "action": "sell:bones:11"},
							{"label": "🧥👑 Comprar 1 Manto de Camuflaje Montaraz (-52 Oro) [-40% detección de guardias, animales e Inquisidor]", "next": "start", "action": "buy_unlimited:ranger_camo_cloak:52"},
							{"label": "🧪🐍 Comprar 1 Veneno Paralizante de Extramuros (-28 Oro) [+50 Stun en impactos durante 60s]", "next": "start", "action": "buy_unlimited:royal_paralytic_venom:28"},
							{"label": "🥫👑 Comprar 1 Conserva Real de Extramuros (-22 Oro) [Importación Real]", "next": "start", "action": "buy_unlimited:royal_ration:22"},
							{"label": "📜 Preguntar por las leyes de caza del Reino y su Salvoconducto", "next": "hunting_law_info"},
							{"label": "Buen viaje, Valeria. [Salir]", "next": "END"}
						]
					},
					"hunting_law_info": {
						"text": "«Fuera de esta frontera todos los ciervos y zorros son propiedad de la Corona. Aquí os dejan cazar porque enviar carros de grano cuesta demasiado.\n\nGracias a mi Salvoconducto Real puedo sacar vuestras pieles legalmente cada semana e inyectar oro fresco en el pueblo. Si alguien me matara, el valle quedaría aislado y arruinado durante semanas... y la Inquisición Real vendría a cobrar sangre.»",
						"choices": [{"label": "Un negocio redondo para todos. [Volver]", "next": "start"}]
					}
				}
		TradeRole.ROYAL_INVESTIGATOR:
			var vm_inv = get_tree().get_first_node_in_group("village_manager")
			var inv_report: String = "Expediente Real en curso."
			var detailed_list: String = inv_report
			if vm_inv and vm_inv.has_method("get_royal_investigation_dialogue_summary"):
				inv_report = str(vm_inv.call("get_royal_investigation_dialogue_summary"))
			if vm_inv and vm_inv.has_method("get_royal_investigation_detailed_suspects_text"):
				detailed_list = str(vm_inv.call("get_royal_investigation_detailed_suspects_text"))
			else:
				detailed_list = inv_report
			return {
				"start": {
					"text": "Soy el %s (%s). %s\n%s" % [npc_name, npc_role, needs_line, inv_report],
					"choices": [
						{"label": "📋 Consultar lista detallada de interrogatorios, distancias y coartadas", "next": "suspect_list"},
						{"label": "⚖️ Preguntar por su filosofía y plazo real de investigación", "next": "philosophy_info"},
						{"label": "No le interrumpo más, Inquisidor. [Salir]", "next": "END"}
					]
				},
				"suspect_list": {
					"text": detailed_list,
					"choices": [{"label": "Entendido. [Volver]", "next": "start"}]
				},
				"philosophy_info": {
					"text": "«La Corona me envió a este rincón olvidado con una única orden: hallar al asesino del mercader real antes de que se reanude la ruta comercial (plazo máximo de 19 días).\n\nNo tengo prisa por cerrar el caso en un solo día: interrogo uno por uno a TODOS los habitantes del pueblo (empezando por quienes estaban más cerca de la escena), compruebo líneas de visión, descarto a quienes estaban lejos del lugar del crimen y verifico coartadas mutuas. Pero cuando concluya el expediente, alguien pagará con su cuello.»",
					"choices": [{"label": "Una justicia metódica e implacable. [Volver]", "next": "start"}]
				}
			}
		_:
			var camp_note: String = "\n[⛺ Desahuciado de la Posada: Sobreviviendo en un Campamento Rústico a las afueras por falta de oro]" if is_vagrant_camper else ""
			return {
				"start": {
					"text": "Soy %s (%s). %s%s\n%s" % [npc_name, npc_role, needs_line, camp_note, character_tagline],
					"choices": [
						{"label": "🍞 Invitarle a una Hogaza de Pan (+20 Relación)", "next": "start", "action": "gift_bread"},
						{"label": "Nos vemos. [Salir]", "next": "END"}
					]
				}
			}

func on_dialogue_action(action_id: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not ("inventory" in player) or not player.inventory:
		return
	var inv: SimpleInventory = player.inventory
	var vm = get_tree().get_first_node_in_group("village_manager")

	if action_id == "compensate_family":
		if inv.gold < 20:
			_spawn_floating_text("Necesitas 20 Oro para compensar a la familia", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-20)
		affinity = maxi(10, affinity + 50)
		if vm and vm.has_method("modify_family_reputation") and family_id != "none":
			vm.call("modify_family_reputation", family_id, 50, "Compensación familiar pagada", self)
		_spawn_floating_text("🤝 Familia %s reconciliada (-20 Oro)" % family_name, Color.SPRING_GREEN, -44.0)
		return

	if action_id == "doctor_heal":
		if inv.gold < 10:
			_spawn_floating_text("Necesitas 10 Oro para el tratamiento médico", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-10)
		var health: HealthComponent = player.get_node_or_null("HealthComponent")
		if health:
			health.stop_bleeding()
			health.heal(health.max_health)
		_spawn_floating_text("🏥 Curación Completa en el Hospital (-10 Oro)", Color.SPRING_GREEN, -44.0)
		return

	if action_id == "pay_police_bounty":
		if vm and vm.has_method("pay_bounty_fine"):
			vm.call("pay_bounty_fine", player)
		return

	if action_id == "surrender_to_jail":
		if vm and vm.has_method("send_player_to_jail"):
			vm.call("send_player_to_jail", player)
		return

	if action_id.begins_with("upgrade_camp_house:"):
		if not is_at_shop_counter():
			_spawn_floating_text("🚫 Ahora no estoy en la Carpintería. Búscame en mi mostrador en horario laboral.", Color.ORANGE_RED, -44.0)
			return
		var up_parts := action_id.split(":")
		var target_t: int = int(up_parts[1])
		if target_t >= 3 and need_hunger < 46.0:
			_spawn_floating_text("🪚🥺 Estoy demasiado débil por la desnutrición (%d%%) para levantar obras Nv.3. Necesito comer y recuperarme gradualmente." % int(round(need_hunger)), Color.ORANGE_RED, -44.0)
			return
		if target_t >= 3 and get_job_efficiency() < 0.75:
			_spawn_floating_text("🪚⏳ Aún soy %s: necesito al menos 5 días en el oficio (75%%) para levantar Casas de Piedra Nv.3" % get_job_efficiency_label(), Color.GOLD, -44.0)
			return
		var base_cost: int = int(up_parts[2])
		var final_cost: int = int(round(float(base_cost) * 0.8)) if affinity >= 45 else base_cost
		var camp = get_tree().get_first_node_in_group("campsite")
		if not camp or not camp.has_method("upgrade_player_house"):
			return
		var cur_t: int = int(camp.get("house_tier"))
		if cur_t >= target_t:
			_spawn_floating_text("🏡 Ya tienes esa mejora construida en tu Campamento", Color.GOLD, -44.0)
			return
		if inv.gold < final_cost:
			_spawn_floating_text("Necesitas %d Oro para esta obra" % final_cost, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-final_cost)
		camp.call("upgrade_player_house", target_t)
		modify_affinity(15)
		_spawn_floating_text("🏡 ¡Bram construyó tu vivienda Nv.%d en el Campamento! (-%d Oro)" % [target_t, final_cost], Color.SPRING_GREEN, -46.0)
		return

	if action_id == "open_business_panel":
		if vm and vm.has_method("open_business_management_ui"):
			vm.call_deferred("open_business_management_ui", int(trade_role))
		return

	if action_id == "open_tavern_games":
		var games_ui = get_tree().root.find_child("TavernGamesUI", true, false)
		if games_ui and games_ui.has_method("open_games"):
			games_ui.call_deferred("open_games")
		return

	if action_id == "rent_tavern_bed":
		if inv.gold < 8:
			_spawn_floating_text("Necesitas 8 Oro para alquilar cama", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-8)
		var surv: SurvivalComponent = player.get_node_or_null("SurvivalComponent")
		var stam: StaminaComponent = player.get_node_or_null("StaminaComponent")
		var health: HealthComponent = player.get_node_or_null("HealthComponent")
		if surv:
			surv.restore_sleep(100.0)
			surv.restore_hunger(25.0)
		if stam:
			stam.current_stamina = stam.max_stamina
			stam.stamina_changed.emit(stam.current_stamina, stam.max_stamina)
		if health:
			health.heal(40.0)
		if WorldClock:
			WorldClock.sleep_until_morning()
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🛌 Dormiste en la Taberna (+100% Sueño, +40 HP)", Color.GOLD, -44.0)
		return

	if action_id == "give_npc_food_ration":
		var food_options: Array[String] = ["country_stew", "roasted_chicken", "cooked_meat", "cooked_fish", "fried_frog_legs", "bread", "cabbage", "carrot"]
		for f_id in food_options:
			if inv.remove_item(f_id, 1):
				var f_name: String = inv.get_item_name(f_id)
				var nut_gain: float = 44.0 if f_id in ["country_stew", "roasted_chicken", "cooked_meat", "cooked_fish", "fried_frog_legs"] else 34.0
				feed_npc_gradual(nut_gain)
				need_social = minf(100.0, need_social + 20.0)
				modify_affinity(18)
				if vm and vm.has_method("modify_family_reputation") and family_id != "none":
					vm.call("modify_family_reputation", family_id, 12, "Alimentó a " + npc_name, self)
				add_thought("Me dieron %s cuando tenía hambre (+15)" % f_name, 15.0)
				_spawn_floating_text("🍲↗ ¡Gracias por %s! Digeriendo y recuperando fuerzas gradualmente..." % f_name, Color.SPRING_GREEN, -44.0)
				return
		_spawn_floating_text("❌ No llevas ninguna comida en tu mochila (Pan, Carne, Estofado, Pescado, Verdura...)", Color.ORANGE_RED, -44.0)
		return

	if action_id == "gift_bread":
		if inv.remove_item("bread", 1):
			modify_affinity(20)
			if vm and vm.has_method("modify_family_reputation") and family_id != "none":
				vm.call("modify_family_reputation", family_id, 12, "Regalo de pan a " + npc_name, self)
			feed_npc_gradual(38.0)
			need_social = minf(100.0, need_social + 25.0)
			add_thought("Recibió pan recién horneado (+12)", 12.0)
			_spawn_floating_text("🍞↗ ¡Gracias por el pan! (Digeriendo gradualmente)", Color.GOLD, -44.0)
		else:
			_spawn_floating_text("No tienes Hogaza de Pan", Color.ORANGE_RED, -44.0)
		return

	if action_id == "forge_steel":
		if not is_at_shop_counter():
			_spawn_floating_text("🚫 No estoy junto a la fragua ahora mismo. Vuelve cuando atienda la Herrería.", Color.ORANGE_RED, -44.0)
			return
		if need_hunger < 46.0:
			_spawn_floating_text("🔥🥺 Me tiembla el pulso por la desnutrición (%d%%). Necesito comer e ir recuperando fuerzas antes de fundir Acero." % int(round(need_hunger)), Color.ORANGE_RED, -44.0)
			return
		if get_job_efficiency() < 0.65:
			_spawn_floating_text("🔥⏳ Aún soy %s: necesito más días de práctica para fundir Lingotes de Acero" % get_job_efficiency_label(), Color.GOLD, -44.0)
			return
		if inv.gold < 10:
			_spawn_floating_text("Necesitas 10 Oro para fundir Acero", Color.ORANGE_RED, -44.0)
			return
		if not inv.has_item("iron_ore", 2) or not inv.has_item("wood", 1):
			_spawn_floating_text("Requiere 2 Mineral de Hierro y 1 Madera", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-10)
		inv.remove_item("iron_ore", 2)
		inv.remove_item("wood", 1)
		inv.add_item("steel_ingot", 1)
		modify_affinity(6)
		add_thought("Forjó acero de primera calidad (+8)", 8.0)
		_spawn_floating_text("🔥 +1 Lingote de Acero Forjado (-10 Oro)", Color.CYAN, -44.0)
		return

	if action_id.begins_with("upgrade_tool:"):
		if not is_at_shop_counter():
			_spawn_floating_text("🚫 No estoy en el yunque de la Herrería ahora mismo. Vuelve en mi turno de mostrador.", Color.ORANGE_RED, -44.0)
			return
		var t_id: String = action_id.get_slice(":", 1)
		var cur_t_lvl: int = int(player.call("get_tool_tier", t_id)) if player.has_method("get_tool_tier") else 1
		if cur_t_lvl >= 2 and need_hunger < 46.0:
			_spawn_floating_text("⚒️🥺 Me tiemblan las manos por la desnutrición (%d%%). Necesito comer y recuperarme gradualmente para forjar Nv.3." % int(round(need_hunger)), Color.ORANGE_RED, -44.0)
			return
		if cur_t_lvl >= 2 and get_job_efficiency() < 0.75:
			_spawn_floating_text("⚒️⏳ Aún soy %s: necesito al menos 5 días de experiencia (75%%) para forjar Acero Maestro Nv.3" % get_job_efficiency_label(), Color.GOLD, -44.0)
			return
		if player.has_method("upgrade_tool"):
			if bool(player.call("upgrade_tool", t_id)):
				modify_affinity(10)
				add_thought("Mejoró un arma/herramienta en la fragua (+10)", 10.0)
		return

	var parts := action_id.split(":")
	if parts.size() != 3:
		return
	var cmd := parts[0]
	var item_id := parts[1]
	var price := int(parts[2])

	# Prohibido comprar o vender en cualquier tienda si el dependiente NO está físicamente atendiendo su mostrador
	if trade_role in [TradeRole.BLACKSMITH, TradeRole.BUTCHER, TradeRole.CARPENTER, TradeRole.FISHMONGER, TradeRole.HERBALIST, TradeRole.INNKEEPER]:
		if not is_at_shop_counter():
			_spawn_floating_text("🚫 Estoy fuera del mostrador (%s). No puedo vender ni comprar hasta volver a la tienda." % get_activity_description(), Color.ORANGE_RED, -44.0)
			return

	if cmd == "buy_armor" and item_id.ends_with("_steel") and get_job_efficiency() < 0.75:
		_spawn_floating_text("🛡️⏳ Aún soy %s: necesito al menos 5 días en la forja (75%%) para templar Armaduras de Acero Maestro" % get_job_efficiency_label(), Color.GOLD, -44.0)
		return
	# Fase 8: Precios dinámicos de Oferta/Demanda y descuentos de Socio/Dueño (-30%) o Aliado (-20%)
	if cmd == "sell":
		if not (trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.TRAVELING_MERCHANT]):
			price = _get_dynamic_sell_price(price)
	elif cmd in ["buy", "buy2", "buy_unlimited"]:
		if trade_role != TradeRole.TRAVELING_MERCHANT:
			price = _get_dynamic_buy_price(price)
	elif cmd == "buy_armor":
		if vm and vm.has_method("is_player_owner_or_partner") and bool(vm.call("is_player_owner_or_partner", int(trade_role))):
			price = maxi(1, int(round(float(price) * 0.70)))
		elif affinity >= 45:
			price = maxi(1, int(round(float(price) * 0.80)))

	if cmd == "buy_armor" or cmd == "buy_unlimited":
		if inv.gold < price:
			_spawn_floating_text("Oro insuficiente (%d Oro)" % price, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-price)
		personal_gold = maxi(0, personal_gold) + price
		inv.add_item(item_id, 1)
		if cmd == "buy_armor":
			inv.equip_armor_item(item_id, player)
			add_thought("Vendió una pieza de armadura (+8)", 8.0)
		else:
			_spawn_floating_text("+1 %s (-%d Oro)" % [inv.get_item_name(item_id), price], Color.SPRING_GREEN, -44.0)
		return

	if cmd == "sell":
		if trade_role == TradeRole.TRAVELING_MERCHANT and personal_gold < price:
			_spawn_floating_text("💰 No me queda suficiente presupuesto esta semana (%d Oro restante). Volveré la próxima semana." % maxi(0, personal_gold), Color.GOLD, -44.0)
			return
		if inv.remove_item(item_id, 1):
			inv.add_gold(price)
			if trade_role == TradeRole.TRAVELING_MERCHANT:
				personal_gold = maxi(0, personal_gold - price)
			else:
				personal_gold = maxi(0, personal_gold - int(ceil(float(price) * 0.5)))
			shop_stock[item_id] = int(shop_stock.get(item_id, 0)) + 1
			if item_id in ["wood", "iron_ore", "leather", "herbal_poultice", "bread", "fertilizer", "cooked_meat"]:
				workshop_materials[item_id] = int(workshop_materials.get(item_id, 0)) + 1
			if vm and "shop_businesses" in vm and vm.shop_businesses.has(int(trade_role)):
				vm.shop_businesses[int(trade_role)]["stock_override"] = shop_stock.duplicate()
			modify_affinity(4)
			_spawn_floating_text("+%d Oro (Vendido %s)" % [price, inv.get_item_name(item_id)], Color.GOLD, -44.0)
		else:
			_spawn_floating_text("No tienes %s" % inv.get_item_name(item_id), Color.ORANGE_RED, -44.0)
	elif cmd == "buy":
		var avail: int = int(shop_stock.get(item_id, 0))
		if avail <= 0:
			_spawn_floating_text("Sin stock hoy de %s" % inv.get_item_name(item_id), Color.ORANGE_RED, -44.0)
			return
		if inv.gold < price:
			_spawn_floating_text("Oro insuficiente (%d Oro)" % price, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-price)
		personal_gold = maxi(0, personal_gold) + price
		shop_stock[item_id] = avail - 1
		if vm and "shop_businesses" in vm and vm.shop_businesses.has(int(trade_role)):
			vm.shop_businesses[int(trade_role)]["stock_override"] = shop_stock.duplicate()
		inv.add_item(item_id, 1)
		_spawn_floating_text("+1 %s (-%d Oro)" % [inv.get_item_name(item_id), price], Color.SPRING_GREEN, -44.0)
	elif cmd == "buy2":
		var avail2: int = int(shop_stock.get(item_id, 0))
		if avail2 < 2:
			_spawn_floating_text("Stock insuficiente", Color.ORANGE_RED, -44.0)
			return
		if inv.gold < price:
			_spawn_floating_text("Oro insuficiente (%d Oro)" % price, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-price)
		personal_gold = maxi(0, personal_gold) + price
		shop_stock[item_id] = avail2 - 2
		if vm and "shop_businesses" in vm and vm.shop_businesses.has(int(trade_role)):
			vm.shop_businesses[int(trade_role)]["stock_override"] = shop_stock.duplicate()
		inv.add_item(item_id, 2)
		_spawn_floating_text("+2 %s (-%d Oro)" % [inv.get_item_name(item_id), price], Color.SPRING_GREEN, -44.0)

func _spawn_floating_text(text: String, color: Color, offset_y: float = -36.0) -> void:
	if FloatingTextScene and is_inside_tree():
		var parent_scene: Node = get_tree().current_scene if get_tree().current_scene else get_parent()
		if parent_scene:
			var ft = FloatingTextScene.instantiate()
			ft.start_text = text
			ft.text_color = color
			ft.global_position = global_position + Vector2(0, offset_y)
			parent_scene.add_child(ft)

func to_save_dict() -> Dictionary:
	var route_bought_flags: Dictionary = {}
	for rk in ["route_Bought_smith", "route_Bought_carp", "route_Bought_butcher", "route_Bought_fish", "route_Bought_herb"]:
		if has_meta(rk):
			route_bought_flags[rk] = bool(get_meta(rk))
	var save_pos: Vector2 = _pre_poker_pos if (is_at_poker_table and _pre_poker_pos != Vector2.ZERO and not is_dead) else global_position
	return {
		"npc_name": npc_name,
		"npc_role": npc_role,
		"family_id": family_id,
		"family_name": family_name,
		"trade_role": int(trade_role),
		"linked_trade": int(linked_trade),
		"days_in_role": days_in_role,
		"affinity": affinity,
		"personal_gold": personal_gold,
		"carries_royal_safe_conduct": carries_royal_safe_conduct,
		"corpse_pocket_looted": corpse_pocket_looted,
		"is_vagrant_camper": is_vagrant_camper,
		"vagrant_camp_x": vagrant_camp_pos.x,
		"vagrant_camp_y": vagrant_camp_pos.y,
		"merchant_id": merchant_id,
		"need_hunger": need_hunger,
		"digestion_buffer": digestion_buffer,
		"need_energy": need_energy,
		"need_social": need_social,
		"activity": int(current_activity),
		"is_dead": is_dead,
		"corpse_on_ground": corpse_on_ground,
		"corpse_discovered": corpse_discovered,
		"corpse_discovered_by": corpse_discovered_by,
		"corpse_reported": corpse_reported,
		"corpse_in_morgue": corpse_in_morgue,
		"corpse_rot_hours": corpse_rot_hours,
		"last_hit_weapon_name": last_hit_weapon_name,
		"last_hit_by_player": last_hit_by_player,
		"murder_witness_name": murder_witness_name,
		"death_world_pos_x": death_world_pos.x,
		"death_world_pos_y": death_world_pos.y,
		"death_day": death_day,
		"death_hour": death_hour,
		"death_minute": death_minute,
		"is_hostile": is_hostile,
		"pos_x": save_pos.x,
		"pos_y": save_pos.y,
		"work_x": work_position.x,
		"work_y": work_position.y,
		"bed_x": bed_position.x,
		"bed_y": bed_position.y,
		"table_x": home_table_pos.x,
		"table_y": home_table_pos.y,
		"hp": health_comp.current_health if health_comp else 65.0,
		"shop_stock": shop_stock.duplicate(),
		"workshop_materials": workshop_materials.duplicate(),
		"craft_progress": _craft_progress,
		"crafting_recipe_idx": _crafting_recipe_idx,
		"completed_expedition_day": _completed_expedition_day,
		"route_bought_flags": route_bought_flags
	}

func from_save_dict(data: Dictionary) -> void:
	if data.has("npc_name"):
		npc_name = str(data["npc_name"])
	if data.has("workshop_materials") and typeof(data["workshop_materials"]) == TYPE_DICTIONARY:
		workshop_materials = data["workshop_materials"].duplicate()
	if data.has("craft_progress"):
		_craft_progress = clampf(float(data["craft_progress"]), 0.0, 99.0)
	if data.has("crafting_recipe_idx"):
		_crafting_recipe_idx = maxi(0, int(data["crafting_recipe_idx"]))
	_completed_expedition_day = int(data.get("completed_expedition_day", -1))
	_supply_run_target_role = 0
	_supply_run_item_id = ""
	_supply_run_input_label = ""
	_supply_run_timer = 0.0
	_is_actively_crafting = false
	_expedition_target_node = null
	_expedition_gather_timer = 0.0
	_is_amateur_foraging = false
	_amateur_forage_timer = 0.0
	_being_interviewed_timer = 0.0
	_interviewer_node = null
	if _craft_bar_root:
		_craft_bar_root.visible = false
	for rk in ["route_Bought_smith", "route_Bought_carp", "route_Bought_butcher", "route_Bought_fish", "route_Bought_herb"]:
		if has_meta(rk):
			remove_meta(rk)
	if data.has("route_bought_flags") and typeof(data["route_bought_flags"]) == TYPE_DICTIONARY:
		var rbf: Dictionary = data["route_bought_flags"]
		for rk in rbf.keys():
			set_meta(str(rk), bool(rbf[rk]))
	is_at_poker_table = false
	poker_seat_pos = Vector2.ZERO
	_pre_poker_pos = Vector2.ZERO
	corpse_being_carried = false
	corpse_carrier = null
	corpse_reporter_npc = null
	_carrying_corpse_target = null
	_reporting_corpse_target = null
	_active_downed_patient = null
	if data.has("npc_role"):
		npc_role = str(data["npc_role"])
	if data.has("family_id"):
		family_id = str(data["family_id"])
	if data.has("family_name"):
		family_name = str(data["family_name"])
	if data.has("trade_role"):
		trade_role = int(data["trade_role"]) as TradeRole
	if data.has("linked_trade"):
		linked_trade = int(data["linked_trade"]) as TradeRole
	if data.has("days_in_role"):
		days_in_role = clampi(int(data["days_in_role"]), 0, 7)
	if data.has("affinity"):
		affinity = int(data["affinity"])
	if data.has("personal_gold"):
		personal_gold = maxi(0, int(data["personal_gold"]))
	if data.has("carries_royal_safe_conduct"):
		carries_royal_safe_conduct = bool(data["carries_royal_safe_conduct"])
	if data.has("corpse_pocket_looted"):
		corpse_pocket_looted = bool(data["corpse_pocket_looted"])
	if data.has("is_vagrant_camper"):
		is_vagrant_camper = bool(data["is_vagrant_camper"])
	if data.has("vagrant_camp_x") and data.has("vagrant_camp_y"):
		vagrant_camp_pos = Vector2(float(data["vagrant_camp_x"]), float(data["vagrant_camp_y"]))
	if data.has("merchant_id"):
		merchant_id = str(data["merchant_id"])
	if data.has("need_hunger"):
		need_hunger = clampf(float(data["need_hunger"]), 0.0, 100.0)
	if data.has("digestion_buffer"):
		digestion_buffer = clampf(float(data["digestion_buffer"]), 0.0, 100.0)
	if data.has("need_energy"):
		need_energy = clampf(float(data["need_energy"]), 0.0, 100.0)
	if data.has("need_social"):
		need_social = clampf(float(data["need_social"]), 0.0, 100.0)
	if data.has("activity"):
		current_activity = int(data["activity"]) as ActivityState
	if data.has("pos_x") and data.has("pos_y"):
		global_position = Vector2(float(data["pos_x"]), float(data["pos_y"]))
	if data.has("work_x") and data.has("work_y"):
		work_position = Vector2(float(data["work_x"]), float(data["work_y"]))
	if data.has("bed_x") and data.has("bed_y"):
		bed_position = Vector2(float(data["bed_x"]), float(data["bed_y"]))
	if data.has("table_x") and data.has("table_y"):
		home_table_pos = Vector2(float(data["table_x"]), float(data["table_y"]))
	if data.has("shop_stock") and typeof(data["shop_stock"]) == TYPE_DICTIONARY:
		shop_stock = data["shop_stock"].duplicate()
	_resolve_unique_64_visuals_and_lore()
	var dead_saved: bool = bool(data.get("is_dead", false))
	if dead_saved:
		is_downed = false
		bleedout_timer = 0.0
		is_dead = true
		is_hostile = false
		remove_from_group("enemies")
		corpse_on_ground = bool(data.get("corpse_on_ground", true))
		corpse_discovered = bool(data.get("corpse_discovered", false))
		corpse_discovered_by = str(data.get("corpse_discovered_by", ""))
		corpse_reported = bool(data.get("corpse_reported", false))
		corpse_in_morgue = bool(data.get("corpse_in_morgue", false))
		corpse_rot_hours = float(data.get("corpse_rot_hours", 0.0))
		last_hit_weapon_name = str(data.get("last_hit_weapon_name", last_hit_weapon_name))
		last_hit_by_player = bool(data.get("last_hit_by_player", false))
		murder_witness_name = str(data.get("murder_witness_name", ""))
		if data.has("death_world_pos_x") and data.has("death_world_pos_y"):
			death_world_pos = Vector2(float(data["death_world_pos_x"]), float(data["death_world_pos_y"]))
		else:
			death_world_pos = global_position
		death_day = int(data.get("death_day", 1))
		death_hour = int(data.get("death_hour", 12))
		death_minute = int(data.get("death_minute", 0))
		if body_col:
			body_col.set_deferred("disabled", true)
		if hurtbox and hurtbox.get_child_count() > 0:
			var hcol_d := hurtbox.get_child(0) as CollisionShape2D
			if hcol_d:
				hcol_d.set_deferred("disabled", true)
		if interact_area and interact_area.get_child_count() > 0:
			var ic := interact_area.get_child(0) as CollisionShape2D
			if ic:
				ic.set_deferred("disabled", corpse_in_morgue)
		if sprite:
			sprite.rotation_degrees = 90.0
			sprite.modulate = Color(0.68, 0.54, 0.54, 0.96)
			sprite.z_index = -1
			sprite.visible = not corpse_in_morgue
	else:
		is_dead = false
		is_downed = false
		bleedout_timer = 0.0
		sedated_timer = 0.0
		is_stunned_flag = false
		is_sleeping = false
		set_poker_seating(false)
		corpse_on_ground = false
		corpse_discovered = false
		corpse_reported = false
		corpse_in_morgue = false
		is_hostile = bool(data.get("is_hostile", false))
		if is_hostile:
			if not is_in_group("enemies"):
				add_to_group("enemies")
		else:
			remove_from_group("enemies")
		if body_col:
			body_col.set_deferred("disabled", not is_hostile)
		if hurtbox and hurtbox.get_child_count() > 0:
			var hcol_a := hurtbox.get_child(0) as CollisionShape2D
			if hcol_a:
				hcol_a.set_deferred("disabled", false)
		if interact_area and interact_area.get_child_count() > 0:
			var ic := interact_area.get_child(0) as CollisionShape2D
			if ic:
				ic.set_deferred("disabled", false)
		if sprite:
			sprite.visible = true
			sprite.z_index = 0
			sprite.rotation_degrees = 0.0
			sprite.modulate = Color.WHITE
		if stun_comp:
			stun_comp.clear_stun()
		if health_comp:
			health_comp.stop_bleeding()
			if data.has("hp"):
				health_comp.current_health = clampf(float(data["hp"]), 1.0, health_comp.max_health)
