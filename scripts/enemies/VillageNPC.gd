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
	UNEMPLOYED,    # Viajero sin oficio (vive en la Taberna, pasea y puede heredar un oficio si una familia entera falta)
	FAMILY_MEMBER, # Familiar de un artesano (vive en la misma casa, ayuda en el hogar y es el heredero directo del oficio)
	INNKEEPER,     # Tabernera (regenta la Taberna El Jabalí Dorado)
	BUTCHER,       # 1. Carnicero y Peletero
	BLACKSMITH,    # 2. Herrero
	CARPENTER,     # 3. Carpintero
	HERBALIST,     # 4. Herborista y Agricultora
	FISHMONGER,    # 5. Pescador y Molinero
	DOCTOR,        # 6. Médico Cirujano y Forense del Hospital y Morgue
	SHERIFF,       # 7. Comisario Jefe de la Comisaría y Cárcel
	GUARD          # 8. Guardia de Patrulla Policial
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

# Posiciones clave en la aldea para este NPC
var work_position: Vector2 = Vector2.ZERO
var bed_position: Vector2 = Vector2.ZERO
var home_table_pos: Vector2 = Vector2.ZERO
var tavern_social_pos: Vector2 = Vector2(395, -135)
var shop_stock: Dictionary = {}

# Sub-stats de Necesidades Dinámicas (0.0 = crítico, 100.0 = satisfecho)
var need_hunger: float = 80.0
var need_energy: float = 85.0
var need_social: float = 75.0

# Psicología Estilo RimWorld (Rasgos, Humor, Gustos y Pensamientos)
var traits: Array[String] = []
var favorite_item: String = "bread"
var mood: float = 82.0
var thoughts: Array[String] = []

# Control de Asiento en la Mesa de Juegos de la Taberna
var is_at_poker_table: bool = false
var poker_seat_pos: Vector2 = Vector2.ZERO

# Tasas metabólicas individuales (cada NPC tiene su propio ritmo para evitar comportamiento robótico sincronizado)
var _hunger_decay_rate: float = 1.15
var _energy_decay_rate: float = 0.95
var _social_decay_rate: float = 1.05

var current_activity: ActivityState = ActivityState.WORKING
var _eat_at_tavern: bool = false
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

# Estado Policial y Sigilo (Negociación -> Persecución + Derribo No Letal / Asesinato Letal por la Espalda)
var _police_alerted_timer: float = 0.0
var _civilian_hostile_timer: float = 0.0
var _last_seen_player_pos: Vector2 = Vector2.ZERO
var _stuck_timer: float = 0.0
var _last_frame_pos: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.DOWN
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
var _attack_timer: float = 0.0
var _chat_bubble_timer: float = 0.0
var _expedition_gather_timer: float = 0.0
var _completed_expedition_day: int = -1
var _expedition_target_node: Node2D = null

const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

func _ready() -> void:
	set_physics_process(not Engine.is_editor_hint())
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 0
	add_to_group("npcs")
	add_to_group("village_npcs")
	if not Engine.is_editor_hint() and WorldClock and not WorldClock.hour_passed.is_connected(_on_hour_passed):
		WorldClock.hour_passed.connect(_on_hour_passed)

func _on_hour_passed(_new_hour: int, _new_day: int = 1) -> void:
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

	# Inicializar sub-stats y metabolismo con variación individual para que cada NPC tenga su propio ritmo
	need_hunger = randf_range(58.0, 94.0)
	need_energy = randf_range(64.0, 96.0)
	need_social = randf_range(52.0, 92.0)
	_hunger_decay_rate = randf_range(0.85, 1.35)
	_energy_decay_rate = randf_range(0.75, 1.20)
	_social_decay_rate = randf_range(0.80, 1.30)
	_init_rimworld_psychology()

	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = tex
	sprite.scale = Vector2(1.25, 1.25)
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
	health_comp.max_health = 65.0
	health_comp.current_health = 65.0
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
		_:
			var pool_traits: Array[String] = ["Alegre", "Tahúr", "Glotón", "Noctámbulo", "Amante de Animales", "Curioso", "Leal"]
			var idx1: int = abs(npc_name.hash()) % pool_traits.size()
			var idx2: int = (idx1 + 3) % pool_traits.size()
			traits = [pool_traits[idx1], pool_traits[idx2]]
			var fav_pool: Array[String] = ["bread", "cooked_meat", "roasted_chicken", "country_stew", "cooked_fish"]
			favorite_item = fav_pool[abs(npc_name.hash()) % fav_pool.size()]
			thoughts = ["Paseando por el valle (+5)"]
	mood = clampf(78.0 + randf_range(-6.0, 12.0), 40.0, 98.0)

func add_thought(thought_text: String, mood_delta: float) -> void:
	if thoughts.has(thought_text):
		thoughts.erase(thought_text)
	thoughts.push_front(thought_text)
	while thoughts.size() > 3:
		thoughts.pop_back()
	mood = clampf(mood + mood_delta, 0.0, 100.0)

func set_poker_seating(active: bool, seat_world_pos: Vector2 = Vector2.ZERO) -> void:
	is_at_poker_table = active
	poker_seat_pos = seat_world_pos
	if active:
		is_sleeping = false
		velocity = Vector2.ZERO
		if seat_world_pos != Vector2.ZERO:
			global_position = seat_world_pos
		if sprite:
			sprite.rotation_degrees = 0.0
		add_thought("Jugando en la mesa del casino (+10)", 10.0)
	else:
		velocity = Vector2.ZERO

func apply_sleeping_draught(duration: float = 40.0) -> void:
	if is_dead or is_downed:
		return
	sedated_timer = maxf(sedated_timer, duration)
	is_sleeping = true
	is_hostile = false
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
		_process_corpse_state(delta)
		return

	# Paso 1: Estado "Agonizando" (`is_downed`) antes de morir definitivamente
	if is_downed:
		velocity = Vector2.ZERO
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
		is_sleeping = true
		if status_label:
			status_label.text = "💤 %s — Inconsciente / Dormido (%ds)" % [npc_name, maxi(1, int(ceil(sedated_timer)))]
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
		return

	# Si está sentado jugando Póker/Billar o el reloj está congelado por minijuego, no drenar necesidades ni romper rutina
	if is_at_poker_table:
		if poker_seat_pos != Vector2.ZERO and global_position.distance_to(poker_seat_pos) > 3.0:
			global_position = poker_seat_pos
		velocity = Vector2.ZERO
		_update_visual_animation(delta)
		_update_hover_label()
		return

	if WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen():
		velocity = Vector2.ZERO
		_update_hover_label()
		return

	if body_col:
		body_col.disabled = not is_hostile

	var vm_escort = get_tree().get_first_node_in_group("village_manager")
	# Paso 2b: Si este agente policial está escoltando físicamente al jugador esposado hacia la celda de la Comisaría (Kenshi / RDR2)
	if vm_escort and bool(vm_escort.get("player_being_escorted_to_jail")) and vm_escort.get("escorting_officer") == self:
		var jail_target: Vector2 = vm_escort.get("_jail_cell_pos") if "_jail_cell_pos" in vm_escort else Vector2(886, 172)
		_move_towards_point(jail_target, 64.0, delta)
		move_and_slide()
		_update_visual_animation(delta)
		_update_hover_label()
		return

	# Paso 1: El Dr. Valen acude de urgencia SOLO si ve directamente a un NPC agonizando (con línea de visión) o si está dentro del Hospital
	if trade_role == TradeRole.DOCTOR and not is_hostile:
		var downed_target: VillageNPC = _find_downed_npc()
		if downed_target != null:
			var dist_d: float = global_position.distance_to(downed_target.global_position)
			if dist_d > 22.0:
				_move_towards_point(downed_target.global_position, 68.0, delta)
				move_and_slide()
				_update_visual_animation(delta)
				_update_hover_label()
				return
			else:
				downed_target.revive_from_downed(self, false)
				_spawn_floating_text("🩺 ¡Dr. Valen estabilizó a %s!" % downed_target.npc_name, Color.SPRING_GREEN, -42.0)
				return

	# Paso 1b: Si este aldeano fue testigo del hallazgo de un cadáver, corre físicamente a reportarlo al Médico o a la Guardia (Hitman / Streets of Rogue)
	if not is_hostile and _process_witness_corpse_reporting(delta):
		return

	# Paso 1c: Traslado físico de cadáveres YA REPORTADOS hasta la Morgue del Hospital
	if not is_hostile and _process_corpse_morgue_transport(delta):
		return

	# Paso 2: Comisario Vane y Guardia Rodric (Negociación -> Persecución con Pistola a distancia y Porra de cerca, bloqueando visión por paredes)
	if trade_role in [TradeRole.SHERIFF, TradeRole.GUARD]:
		var vm = get_tree().get_first_node_in_group("village_manager")
		if vm and (int(vm.get("wanted_level")) > 0 or bool(vm.get("is_resisting_arrest")) or is_hostile) and not bool(vm.get("player_in_jail")) and not bool(vm.get("player_being_escorted_to_jail")):
			if _process_police_law_enforcement(delta, vm):
				return

	if is_hostile:
		_process_hostile_combat(delta)
		move_and_slide()
		return

	# Paso 1: Si un NPC sufre heridas (`HP < 75%`), camina hacia la Sala de Urgencias del Hospital (`Vector2(718, 136)`) para curarse
	if health_comp and health_comp.current_health < health_comp.max_health * 0.75:
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
		_update_hover_label()
		return

	_update_needs_and_decisions(delta)
	_execute_dynamic_activity(delta)
	_apply_player_and_doorway_yield(delta)
	move_and_slide()
	_update_visual_animation(delta)
	_update_hover_label()

## Gestiona un cadáver en el suelo: se pudre con el paso de las horas/días hasta que otro NPC lo vea en su rutina natural (con línea de visión)
## o el jugador lo reporte con [E]. El Dr. Valen NO sabe que alguien murió hasta que el cadáver sea físicamente reportado.
func _process_corpse_state(delta: float) -> void:
	if corpse_in_morgue or not corpse_on_ground:
		return

	# Si está siendo cargado físicamente hacia la Morgue por el Dr. Valen o un vecino/guardia
	if corpse_being_carried:
		if is_instance_valid(corpse_carrier) and not corpse_carrier.is_dead and not corpse_carrier.is_downed:
			global_position = corpse_carrier.global_position + Vector2(0, -8)
		else:
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

	var vm = get_tree().get_first_node_in_group("village_manager")
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
							_spawn_floating_text("😱 ¡%s vio el cadáver de %s y corre a avisar!" % [other.npc_name, npc_name], Color.ORANGE_RED, -42.0)
							break

	if status_label:
		var player = get_tree().get_first_node_in_group("player") as Node2D
		var near_p: bool = player != null and global_position.distance_squared_to(player.global_position) <= 44.0 * 44.0
		var near_m: bool = global_position.distance_squared_to(get_global_mouse_position()) <= 28.0 * 28.0
		if near_p or near_m or corpse_being_carried:
			var rot_days: int = int(floor(corpse_rot_hours / 24.0))
			var rot_rem_h: int = int(floor(corpse_rot_hours)) % 24
			var state_line: String = ""
			if corpse_being_carried and is_instance_valid(corpse_carrier):
				state_line = "⚰️ Trasladando cuerpo a la Morgue (Llevado por %s)" % corpse_carrier.npc_name
			elif corpse_reported:
				state_line = "🚨 Reportado por %s — En espera de traslado a la Morgue" % corpse_discovered_by
			elif corpse_discovered and is_instance_valid(corpse_reporter_npc):
				state_line = "🏃 %s corre a reportarlo al Hospital/Comisaría | [E: 📢 Reportar tú mismo]" % corpse_reporter_npc.npc_name
			elif rot_days >= 1:
				state_line = "🦠🪰 PUDRIÉNDOSE EN EL LUGAR (%d días, %dh — Nadie lo ha visto) | [E: 📢 Reportar Cadáver]" % [rot_days, rot_rem_h]
			else:
				state_line = "🩸 Cadáver en el suelo (%dh — Nadie lo ha reportado) | [E: 📢 Reportar Cadáver]" % rot_rem_h
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
	var corpse_to_report: VillageNPC = null
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != self:
			var c := n as VillageNPC
			if c.is_dead and c.corpse_on_ground and not c.corpse_in_morgue and c.corpse_discovered and not c.corpse_reported and c.corpse_reporter_npc == self:
				corpse_to_report = c
				break
	if corpse_to_report == null:
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
		_update_hover_label()
		return true
	else:
		velocity = Vector2.ZERO
		corpse_to_report.corpse_reported = true
		corpse_to_report.corpse_reporter_npc = null
		var auth_label: String = nearest_authority.npc_name if nearest_authority != null else "el Hospital"
		_spawn_floating_text("📢 ¡%s reportó el cadáver de %s a %s!" % [npc_name, corpse_to_report.npc_name, auth_label], Color.GOLD, -42.0)
		return true

## Recoge físicamente un cadáver YA REPORTADO (`corpse_reported == true`) y camina con él por las puertas y calles hasta depositarlo en la Morgue
func _process_corpse_morgue_transport(delta: float) -> bool:
	var can_be_carrier: bool = (trade_role in [TradeRole.DOCTOR, TradeRole.GUARD, TradeRole.SHERIFF])
	var target_corpse: VillageNPC = null

	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != self:
			var c := n as VillageNPC
			if c.is_dead and c.corpse_on_ground and not c.corpse_in_morgue and c.corpse_reported:
				if c.corpse_being_carried and c.corpse_carrier == self:
					target_corpse = c
					break
				elif not c.corpse_being_carried:
					# Prioridad al Dr. Valen; si Dr. Valen no está disponible o este NPC fue quien lo descubrió, también puede llevarlo
					var doc_available := _is_doctor_conscious_and_free()
					if trade_role == TradeRole.DOCTOR or (not doc_available and (can_be_carrier or c.corpse_discovered_by == npc_name)):
						target_corpse = c
						break

	if target_corpse == null:
		return false

	# Paso A: Caminar hasta donde yace el cadáver
	if not target_corpse.corpse_being_carried:
		if global_position.distance_to(target_corpse.global_position) > 20.0:
			_move_towards_point(target_corpse.global_position, 66.0, delta)
			move_and_slide()
			_update_visual_animation(delta)
			_update_hover_label()
			return true
		else:
			target_corpse.corpse_being_carried = true
			target_corpse.corpse_carrier = self
			_carrying_corpse_target = target_corpse
			_spawn_floating_text("⚰️ %s recoge el cadáver de %s hacia la Morgue" % [npc_name, target_corpse.npc_name], Color.AQUA, -42.0)

	# Paso B: Llevar el cuerpo físicamente hasta la Mesa Central de la Morgue Forense (`Vector2(745, 174)`)
	var morgue_pos := Vector2(745, 174)
	target_corpse.global_position = global_position + Vector2(0, -8)
	if global_position.distance_to(morgue_pos) > 22.0:
		_move_towards_point(morgue_pos, 60.0, delta)
		move_and_slide()
		_update_visual_animation(delta)
		_update_hover_label()
		return true
	else:
		velocity = Vector2.ZERO
		target_corpse.corpse_on_ground = false
		target_corpse.corpse_being_carried = false
		target_corpse.corpse_in_morgue = true
		target_corpse.corpse_carrier = null
		target_corpse.global_position = morgue_pos
		if target_corpse.sprite:
			target_corpse.sprite.visible = false
		if target_corpse.status_label:
			target_corpse.status_label.visible = false
		if target_corpse.interact_area and target_corpse.interact_area.get_child_count() > 0:
			var ic := target_corpse.interact_area.get_child(0) as CollisionShape2D
			if ic:
				ic.set_deferred("disabled", true)
		_carrying_corpse_target = null
		var vm = get_tree().get_first_node_in_group("village_manager")
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
		_spawn_floating_text("⚰️ Cuerpo de %s depositado en la Morgue Forense" % target_corpse.npc_name, Color.AQUA, -44.0)
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
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return false

	var dist_p: float = global_position.distance_to(player.global_position)
	var in_stealth: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
	var detect_range: float = 95.0 if in_stealth else 235.0
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

	# FASE 1: Intentar negociar primero con el jugador antes de usar la fuerza
	if not resisting:
		if can_see_player and dist_p <= 34.0:
			velocity = Vector2.ZERO
			if vm.has_method("trigger_police_confrontation"):
				vm.call("trigger_police_confrontation", self)
		else:
			_move_towards_point(target_pt, 86.0, delta)
			move_and_slide()
		_update_visual_animation(delta)
		_update_hover_label()
		return true

	# FASE 2: El jugador se ha resistido al arresto -> Combate Policial con Porra (cerca) y Pistola (media/larga distancia)
	_attack_timer = maxf(0.0, _attack_timer - delta)

	if can_see_player and dist_p <= 36.0:
		# Combate cuerpo a cuerpo con Porra Policial
		if dist_p > 22.0:
			_move_towards_point(player.global_position, 96.0, delta)
		else:
			velocity = Vector2.ZERO
		if _attack_timer <= 0.0:
			_attack_timer = 0.85
			_strike_police_baton(player)
	elif can_see_player and dist_p <= 195.0:
		# Disparo a distancia con Pistola Reglamentaria + avance táctico
		_move_towards_point(player.global_position, 82.0, delta)
		if _attack_timer <= 0.0:
			_attack_timer = 1.25
			_fire_police_pistol(player)
	else:
		# Persecución hacia la última posición vista
		_move_towards_point(target_pt, 96.0, delta)

	move_and_slide()
	_update_visual_animation(delta)
	_update_hover_label()
	return true

func _strike_police_baton(player: Node2D) -> void:
	if not player or not player.has_method("take_damage"):
		return
	var d := DamageData.new()
	d.amount = 14.0
	d.type = CombatConstants.DamageType.BLUNT
	d.stun_buildup = 36.0
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

	var d := DamageData.new()
	d.amount = 16.0
	d.type = CombatConstants.DamageType.CUT
	d.bleed_buildup = 20.0
	d.source = self
	player.call("take_damage", d)
	_spawn_floating_text("🔫 ¡Disparo Policial!", Color(1.0, 0.82, 0.28), -42.0)

## El Dr. Valen SOLO sabe que un NPC está agonizando si lo ve directamente con línea de visión (<= 115 px) o si el paciente ya está dentro del Hospital
func _find_downed_npc() -> VillageNPC:
	var vm = get_tree().get_first_node_in_group("village_manager")
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
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player and not is_sleeping and not is_at_poker_table:
		var d_p: float = global_position.distance_to(player.global_position)
		if d_p > 0.05 and d_p < 16.0:
			var away_dir: Vector2 = (global_position - player.global_position).normalized()
			# Empuje lateral suave para ceder el paso en puertas estrechas
			var side_dir := Vector2(-away_dir.y, away_dir.x) if (abs(npc_name.hash()) % 2 == 0) else Vector2(away_dir.y, -away_dir.x)
			var yield_vec: Vector2 = (away_dir * 0.7 + side_dir * 0.3).normalized() * ((16.0 - d_p) / 16.0) * 34.0
			velocity += yield_vec

	# Si el NPC está quieto justo en el marco de una puerta (<= 18 px), da un paso hacia adentro/afuera para no obstruir la entrada
	if velocity.length_squared() < 9.0 and not is_sleeping and not is_at_poker_table:
		var vm = get_tree().get_first_node_in_group("village_manager")
		if vm and vm.has_method("get_doorway_clearance_nudge"):
			var nudge: Vector2 = vm.call("get_doorway_clearance_nudge", global_position, 18.0)
			if nudge.length_squared() > 0.1:
				velocity = nudge * 28.0

func _move_towards_point(target_pos: Vector2, speed: float, delta: float = 0.016) -> void:
	var nav_target: Vector2 = target_pos
	var vm = get_tree().get_first_node_in_group("village_manager")
	if vm and vm.has_method("get_navigation_waypoint"):
		nav_target = vm.call("get_navigation_waypoint", global_position, target_pos, self)
	var diff: Vector2 = nav_target - global_position
	var step_snap: float = maxf(4.0, speed * delta * 0.65)
	if diff.length() <= step_snap:
		if diff.length() <= 6.0:
			global_position = nav_target
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

	var desired_vel: Vector2 = diff.normalized() * speed

	# Separación suave entre NPCs para que nunca se atasquen entre ellos en puertas o pasillos
	var sep_vec := Vector2.ZERO
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != self:
			var other := n as VillageNPC
			if other.is_dead or other.is_downed or other.is_sleeping:
				continue
			var d_other: float = global_position.distance_to(other.global_position)
			if d_other > 0.1 and d_other < 14.0:
				var push_dir: Vector2 = (global_position - other.global_position).normalized()
				sep_vec += push_dir * ((14.0 - d_other) / 14.0) * 22.0

	_stuck_timer = 0.0
	_last_frame_pos = global_position
	velocity = (desired_vel + sep_vec).limit_length(speed * 1.15)

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
	# Horario laboral obligatorio de los oficios y hogares: 08:00 AM a 18:00 (6:00 PM)
	return h >= 8 and h < 18

## Actualiza Hambre, Energía y Socialización: de 08:00 a 18:00 cumplen su jornada de trabajo sin abandonar el puesto;
## a partir de las 18:00 siguen su rutina dinámica según sus sub-stats.
func _update_needs_and_decisions(delta: float) -> void:
	var is_night_env := false
	if WorldClock:
		var h: int = WorldClock.current_hour
		is_night_env = (h >= 21 or h < 6)
	var in_work_shift: bool = _is_mandatory_work_hours()

	# Si estamos en horario laboral obligatorio (08:00 - 18:00), el NPC no puede abandonar su puesto de trabajo
	if in_work_shift and current_activity != ActivityState.WORKING:
		is_sleeping = false
		_social_partner = null
		current_activity = ActivityState.WORKING

	# 1. Desgaste o recuperación según la actividad actual
	match current_activity:
		ActivityState.WORKING:
			is_sleeping = false
			var work_mult: float = 0.85 if (trade_role != TradeRole.UNEMPLOYED and trade_role != TradeRole.FAMILY_MEMBER) else 0.65
			var min_floor: float = 15.0 if in_work_shift else 0.0
			need_hunger = maxf(min_floor, need_hunger - _hunger_decay_rate * work_mult * delta)
			var night_fatigue: float = 1.65 if is_night_env else 0.75
			need_energy = maxf(min_floor, need_energy - _energy_decay_rate * night_fatigue * delta)
			need_social = maxf(min_floor, need_social - _social_decay_rate * 0.80 * delta)

		ActivityState.EATING:
			is_sleeping = false
			var meal_pos: Vector2 = tavern_social_pos if _eat_at_tavern else home_table_pos
			if global_position.distance_to(meal_pos) <= 14.0:
				# Está sentado a la mesa comiendo
				need_hunger = minf(100.0, need_hunger + 16.0 * delta)
				need_energy = minf(100.0, need_energy + 2.5 * delta)
				# Comer en casa con la familia o en la taberna también sube un poco la socialización
				need_social = minf(100.0, need_social + 5.0 * delta)
			else:
				need_energy = maxf(0.0, need_energy - 0.5 * delta)

		ActivityState.SOCIALIZING:
			is_sleeping = false
			need_hunger = maxf(0.0, need_hunger - _hunger_decay_rate * 0.65 * delta)
			need_energy = maxf(0.0, need_energy - _energy_decay_rate * 0.70 * delta)
			var target_s_pos: Vector2 = _get_social_target_pos()
			if global_position.distance_to(target_s_pos) <= 22.0:
				need_social = minf(100.0, need_social + 15.0 * delta)
				_chat_bubble_timer -= delta
				if _chat_bubble_timer <= 0.0:
					_chat_bubble_timer = randf_range(4.5, 7.5)
					_spawn_floating_text("💬", Color(0.75, 0.95, 1.0), -28.0)

		ActivityState.SLEEPING:
			if global_position.distance_to(bed_position) <= 10.0:
				is_sleeping = true
				need_energy = minf(100.0, need_energy + 12.5 * delta)
				need_hunger = maxf(0.0, need_hunger - _hunger_decay_rate * 0.25 * delta)
			else:
				is_sleeping = false

	# Durante el turno laboral obligatorio (08:00 - 18:00), permanece trabajando sin cambiar de actividad
	if in_work_shift:
		return

	# 2. Fuera del horario laboral (18:00 a 08:00, o todo el día para viajeros sin oficio):
	#    Evaluar transiciones de estado dinámicas según el sub-stat más urgente
	_decision_timer -= delta
	if _decision_timer > 0.0:
		return
	_decision_timer = randf_range(0.8, 1.5)

	# Si está durmiendo, sigue durmiendo hasta recuperar buena energía (92%+) o hasta que empiece el turno a las 08:00
	if current_activity == ActivityState.SLEEPING:
		if need_energy >= 92.0 and not is_night_env:
			is_sleeping = false
			current_activity = ActivityState.EATING if need_hunger < 55.0 else ActivityState.SOCIALIZING
		return

	# Si está comiendo, sigue en la mesa hasta saciarse (92%+)
	if current_activity == ActivityState.EATING:
		if need_hunger >= 92.0:
			if need_social < 65.0 and not is_night_env:
				current_activity = ActivityState.SOCIALIZING
				_social_partner = _find_best_social_partner()
			elif need_energy < 55.0 or is_night_env:
				current_activity = ActivityState.SLEEPING
			else:
				current_activity = ActivityState.WORKING
		return

	# Si está socializando, charla hasta llenar su barra social (88%+) o hasta que le entre hambre/sueño
	if current_activity == ActivityState.SOCIALIZING:
		if need_social >= 88.0 or need_hunger < 38.0 or need_energy < 32.0 or is_night_env:
			_social_partner = null
			if need_hunger < 45.0:
				current_activity = ActivityState.EATING
				_eat_at_tavern = (trade_role == TradeRole.UNEMPLOYED) or (randf() < 0.35)
			elif need_energy < 55.0 or is_night_env:
				current_activity = ActivityState.SLEEPING
			else:
				current_activity = ActivityState.WORKING
		return

	# Al salir de trabajar a las 18:00 (o para viajeros), elegir dinámicamente según la necesidad más baja:
	if need_hunger <= 60.0 and need_hunger <= need_social:
		current_activity = ActivityState.EATING
		_eat_at_tavern = (trade_role == TradeRole.UNEMPLOYED) or (randf() < 0.35)
		return

	if need_social <= 65.0 and not is_night_env:
		current_activity = ActivityState.SOCIALIZING
		_social_partner = _find_best_social_partner()
		return

	if need_energy <= 65.0 or is_night_env:
		current_activity = ActivityState.SLEEPING
		return

func _execute_dynamic_activity(delta: float) -> void:
	match current_activity:
		ActivityState.SLEEPING:
			if global_position.distance_to(bed_position) > 7.0:
				_move_towards_point(bed_position, 42.0, delta)
			else:
				velocity = Vector2.ZERO

		ActivityState.EATING:
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
				_process_physical_morning_expedition(delta)
				return

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

## Expedición Matutina Física y Sostenible (06:30 - 09:30):
## Los maestros de oficio acuden físicamente a talar un árbol real, picar una veta de hierro real,
## cosechar una planta real o cazar y desollar un animal real, PERO solo si la población supera
## el umbral mínimo de equilibrio ecológico (N_actual > N_min) calculado en `EcosystemManager`.
func _process_physical_morning_expedition(delta: float) -> void:
	var cur_day: int = WorldClock.current_day if WorldClock else 1
	var eco: EcosystemManager = get_tree().get_first_node_in_group("ecosystem_manager") as EcosystemManager

	# Caso 1: Pescador Marlo en el Muelle del Lago del Oeste
	if trade_role == TradeRole.FISHMONGER:
		var dock_pos: Vector2 = _get_expedition_target_pos()
		if global_position.distance_to(dock_pos) > 16.0:
			_move_towards_point(dock_pos, 58.0, delta)
		else:
			velocity = Vector2.ZERO
			_expedition_gather_timer += delta
			if _expedition_gather_timer >= 2.2:
				_expedition_gather_timer = 0.0
				_completed_expedition_day = cur_day
				shop_stock["cooked_fish"] = int(shop_stock.get("cooked_fish", 0)) + 2
				_spawn_floating_text("🎣🐟 ¡Pescado fresco capturado! (+2 Pescado)", Color(0.65, 0.95, 1.0), -34.0)
				add_thought("Pesca matutina sostenible en el lago (+6)", 6.0)
		return

	# Caso 2: Carnicero Garrick cazando físicamente una presa real del bosque (respetando N_min)
	if trade_role == TradeRole.BUTCHER:
		var prey: WildAnimal = _expedition_target_node as WildAnimal
		var prey_invalid: bool = (not is_instance_valid(prey)) or (prey.state in [WildAnimal.AnimalState.BUTCHERED, WildAnimal.AnimalState.IN_BURROW]) or (not prey.visible)
		if prey_invalid:
			_expedition_target_node = null
			if eco != null:
				prey = eco.find_sustainable_hunt_prey(global_position)
				_expedition_target_node = prey
			if prey == null:
				# El bosque está en o por debajo de su umbral de equilibrio: Garrick suspende la caza hoy
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
				if _expedition_gather_timer >= 0.85:
					_expedition_gather_timer = 0.0
					var p_name: String = prey.animal_name
					prey._finish_butchering()
					_expedition_target_node = null
					_completed_expedition_day = cur_day
					shop_stock["cooked_meat"] = int(shop_stock.get("cooked_meat", 0)) + 2
					shop_stock["leather"] = int(shop_stock.get("leather", 0)) + 1
					_spawn_floating_text("🔪🥩 ¡%s desollado! (+2 Carne, +1 Cuero)" % p_name, Color.GOLD, -38.0)
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
			if _expedition_gather_timer >= 0.90:
				_expedition_gather_timer = 0.0
				_fire_hunter_arrow_at_prey(prey)
		return

	# Caso 3: Carpintero Bram (`LOGGING`), Herrero Thoran (`MINING`) y Herborista Elena (`FORAGE`)
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
	_expedition_gather_timer += delta

	if trade_role == TradeRole.HERBALIST:
		if _expedition_gather_timer >= 1.1:
			_expedition_gather_timer = 0.0
			h_node.harvest_by_npc(self)
			_expedition_target_node = null
			_completed_expedition_day = cur_day
			shop_stock["herbal_poultice"] = int(shop_stock.get("herbal_poultice", 0)) + 2
			_spawn_floating_text("🌿✨ ¡%s recolectada! (+2 Botica)" % h_node.node_title, Color.SPRING_GREEN, -36.0)
			add_thought("Cosecha herbolaria sostenible (+6)", 6.0)
		return

	# Carpintero (Hacha) o Herrero (Pico): golpear físicamente el árbol o la veta hasta derribarlo/agotarla
	if _expedition_gather_timer >= 0.75:
		_expedition_gather_timer = 0.0
		var dmg := DamageData.new()
		dmg.amount = 15.0
		dmg.source = self
		if trade_role == TradeRole.CARPENTER:
			dmg.type = CombatConstants.DamageType.CUT
			dmg.logging_efficiency = 1.85
			_spawn_floating_text("🪓 ¡Tala!", Color(0.95, 0.85, 0.55), -30.0)
		else:
			dmg.type = CombatConstants.DamageType.BLUNT
			dmg.mining_efficiency = 1.85
			_spawn_floating_text("⛏️ ¡Pica!", Color(0.80, 0.90, 1.0), -30.0)
		h_node.take_damage(dmg)

		if h_node.is_depleted:
			_expedition_target_node = null
			_completed_expedition_day = cur_day
			if trade_role == TradeRole.CARPENTER:
				shop_stock["wood"] = int(shop_stock.get("wood", 0)) + 3
				_spawn_floating_text("🌲🪓 ¡Árbol talado! (+3 Madera)", Color.SPRING_GREEN, -38.0)
			else:
				shop_stock["iron_ore"] = int(shop_stock.get("iron_ore", 0)) + 2
				_spawn_floating_text("🪨⛏️ ¡Veta extraída! (+2 Mineral de Hierro)", Color.SPRING_GREEN, -38.0)
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
	d.amount = 18.0
	d.type = CombatConstants.DamageType.CUT
	d.source = self
	prey.take_damage(d)
	_spawn_floating_text("🏹 ¡Flechazo de Caza!", Color(0.95, 0.86, 0.52), -34.0)

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
	match current_activity:
		ActivityState.SLEEPING:
			return "💤 Durmiendo en Cama" if is_sleeping else "🚶 Yendo a Dormir"
		ActivityState.EATING:
			var loc := "en la Taberna" if _eat_at_tavern else "en Casa"
			return "🍲 Comiendo %s" % loc
		ActivityState.SOCIALIZING:
			if is_instance_valid(_social_partner):
				return "💬 Charlando con %s" % _social_partner.npc_name
			return "💬 Socializando"
		_:
			if _is_morning_expedition_hours():
				return _get_expedition_description()
			if trade_role == TradeRole.DOCTOR:
				return "🩺 En Guardia de Urgencias y Morgue"
			if trade_role == TradeRole.SHERIFF:
				return "🚓 Dirigiendo la Comisaría"
			if trade_role == TradeRole.GUARD:
				return "🛡️ Patrullando la Aldea"
			if trade_role == TradeRole.UNEMPLOYED:
				return "🚶 Paseando por la Aldea"
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

func _update_visual_animation(delta: float) -> void:
	if velocity.length_squared() > 4.0:
		facing_direction = velocity.normalized()
	if not sprite:
		return
	if is_sleeping:
		sprite.rotation_degrees = 90.0
		sprite.position = Vector2(0, 2)
		return
	sprite.rotation_degrees = 0.0
	if absf(velocity.x) > 2.0:
		sprite.flip_h = velocity.x < 0.0
	if velocity.length_squared() > 16.0:
		_step_phase += delta * 11.0
		sprite.position.y = -absf(sin(_step_phase)) * 2.0
	else:
		sprite.position.y = 0.0

func _update_hover_label() -> void:
	if not status_label or is_dead or is_downed:
		return
	if is_stunned_flag:
		status_label.text = "💫 %s (%s) — Inconsciente / Aturdido (No Letal)" % [npc_name, npc_role]
		status_label.add_theme_color_override("font_color", Color(0.65, 0.82, 1.0))
		status_label.visible = true
		return
	if _showing_stealth_prompt:
		status_label.text = "🕵️ SIGILO POR LA ESPALDA — %s\n[E / Q: 💤 Aturdir (No Letal) | Clic Izq. / V: 🗡️ Matar (Letal)]" % npc_name
		status_label.add_theme_color_override("font_color", Color(0.55, 0.98, 0.82))
		status_label.visible = true
		return
	var player = get_tree().get_first_node_in_group("player") as Node2D
	var near_player: bool = player != null and global_position.distance_squared_to(player.global_position) <= 30.0 * 30.0
	var near_mouse: bool = global_position.distance_squared_to(get_global_mouse_position()) <= 22.0 * 22.0

	if is_sleeping and not near_mouse and not near_player:
		status_label.text = "Zzz"
		status_label.add_theme_color_override("font_color", Color(0.72, 0.85, 1.0))
		status_label.visible = true
		return

	if near_player or near_mouse:
		var act_txt: String = "🃏 En la Mesa de Póker" if is_at_poker_table else get_activity_description()
		var traits_str: String = ", ".join(traits) if not traits.is_empty() else "Equilibrado"
		status_label.text = "%s (%s) — %s [%s]\n[%s | 😊Humor:%d%% 🍖%d%% 💤%d%% 💬%d%% | E: Hablar]" % [
			npc_name,
			family_name,
			npc_role,
			traits_str,
			act_txt,
			int(round(mood)),
			int(round(need_hunger)),
			int(round(need_energy)),
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
	current_activity = ActivityState.WORKING
	add_to_group("enemies")
	if health_comp:
		health_comp.take_damage(data)
	if stun_comp and health_comp and health_comp.current_health > 0.0:
		stun_comp.take_damage(data)

## Comprueba si el jugador en Sigilo (`[C]`) está situado por la espalda del NPC (o junto a un NPC dormido) para ejecutar un ataque sigiloso (No Letal o Letal)
func can_be_stealth_targeted(player: Node2D) -> bool:
	if player == null or is_dead or is_downed or is_hostile or is_at_poker_table:
		return false
	if not player.has_method("is_stealthing") or not bool(player.call("is_stealthing")):
		return false
	var to_player: Vector2 = player.global_position - global_position
	var dist_sq: float = to_player.length_squared()
	if dist_sq > 29.0 * 29.0 or dist_sq < 0.01:
		return false
	if is_sleeping or sedated_timer > 0.0:
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
	is_hostile = false
	_civilian_hostile_timer = 0.0
	remove_from_group("enemies")
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
	is_stunned_flag = stunned
	if stunned:
		is_hostile = false
		_civilian_hostile_timer = 0.0
		remove_from_group("enemies")
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
	if new_tex and sprite:
		sprite.texture = new_tex

func interact(player: Node) -> void:
	if is_dead:
		report_corpse_by_player(player)
		return
	if is_downed:
		revive_from_downed(player, false)
		return
	if player is Node2D and can_be_stealth_targeted(player as Node2D):
		stealth_knockout(player)
		return
	if is_stunned_flag or is_hostile or sedated_timer > 0.0:
		return
	# Al conversar con el jugador, el NPC también satisface parte de su necesidad social
	need_social = minf(100.0, need_social + 18.0)
	var dm = get_tree().current_scene.get_node_or_null("Systems/dialogue_manager")
	if not dm:
		return
	var diag := _build_dialogue()
	dm.call("start_dialogue", diag, "start", self)

func _get_needs_status_line() -> String:
	var traits_str: String = ", ".join(traits) if not traits.is_empty() else "Equilibrado"
	var last_thought: String = thoughts[0] if not thoughts.is_empty() else "Todo tranquilo"
	var fav_name: String = str(SimpleInventory.CATALOG.get(favorite_item, {}).get("name", favorite_item))
	return "[%s | 😊 Humor: %d%% | 🍖%d%% 💤%d%% 💬%d%%]\n[Rasgos: %s | Favorito: %s | 💭 \"%s\"]" % [
		get_activity_description(),
		int(round(mood)),
		int(round(need_hunger)),
		int(round(need_energy)),
		int(round(need_social)),
		traits_str,
		fav_name,
		last_thought
	]

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
			"text": "Soy %s de la %s (%s). %s\n¡Bienvenido a la Gran Herrería y Armería! Aquí forjo armaduras y mejoro tus herramientas." % [npc_name, family_name, npc_role, needs_line],
			"choices": [
				{"label": "⚒️ Mejorar Armas y Herramientas (Nv.1 -> Nv.2 Hierro -> Nv.3 Acero)", "next": "upgrade_menu"},
				{"label": "🛡️ Comprar Armaduras (Cuero, Hierro y Acero — 4 Piezas)", "next": "armor_menu"},
				{"label": "🔥 Fundir 1 Lingote de Acero (-10 Oro, 2 Mineral Hierro, 1 Madera)", "next": "start", "action": "forge_steel"},
				{"label": "⚙️ Vender 1 Chatarra/Reliquia de Bandido (+18 Oro)", "next": "start", "action": "sell:bandit_scrap:18"},
				{"label": "💎 Vender 1 Mineral de Hierro (+14 Oro)", "next": "start", "action": "sell:iron_ore:14"},
				{"label": "🪨 Vender 1 Piedra (+7 Oro)", "next": "start", "action": "sell:stone:7"},
				{"label": "🪵 Comprar 1 Tablones Reforzados (-16 Oro) [Stock: %d]" % int(shop_stock.get("repair_kit", 0)), "next": "start", "action": "buy:repair_kit:16"},
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
	if affinity <= -35 and not (trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.DOCTOR]):
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
					"text": "Soy %s de la %s (%s). %s%s\n[Stock Carne Cocida: %d | Pollo Asado: %d]" % [npc_name, family_name, npc_role, needs_line, discount_tag, int(shop_stock.get("cooked_meat", 0)), int(shop_stock.get("roasted_chicken", 2))],
					"choices": [
						{"label": "🥚✨ Vender 1 Huevo Dorado Genética Nv.3 (+32 Oro)", "next": "start", "action": "sell:golden_egg:32"},
						{"label": "🦌 Vender 1 Astas de Ciervo (+20 Oro)", "next": "start", "action": "sell:antlers:20"},
						{"label": "🦊 Vender 1 Piel de Zorro (+18 Oro)", "next": "start", "action": "sell:fox_pelt:18"},
						{"label": "🐸 Vender 1 Ancas de Rana Crudas (+11 Oro)", "next": "start", "action": "sell:frog_legs:11"},
						{"label": "👜 Vender 1 Cuero Animal (+10 Oro)", "next": "start", "action": "sell:leather:10"},
						{"label": "🦴 Vender 1 Huesos / Tendones / Grasa (+8 Oro)", "next": "anatomy_sell"},
						{"label": "🥩 Vender 1 Carne Cruda (+8 Oro) o Pollo Crudo (+9 Oro)", "next": "start", "action": "sell:raw_meat:8"},
						{"label": "🍖 Comprar 1 Carne Cocida (-10 Oro) [Stock: %d]" % int(shop_stock.get("cooked_meat", 0)), "next": "start", "action": "buy:cooked_meat:10"},
						{"label": "💬 Charlar sobre su familia y rutina (+8 Relación)", "next": "family_chat", "affinity": 8},
						{"label": "Hasta luego. [Salir]", "next": "END"}
					]
				},
				"anatomy_sell": {
					"text": "🦴 Compra de Despiece Anatómico Avanzado (Huesos, Tendones y Grasa):",
					"choices": [
						{"label": "🦴 Vender 1 Huesos Limpios (+7 Oro)", "next": "anatomy_sell", "action": "sell:bones:7"},
						{"label": "🧬 Vender 1 Tendones y Vísceras (+9 Oro)", "next": "anatomy_sell", "action": "sell:sinew_viscera:9"},
						{"label": "🕯️ Vender 1 Grasa Animal (+8 Oro)", "next": "anatomy_sell", "action": "sell:animal_fat:8"},
						{"label": "🍗 Vender 1 Pollo Crudo (+9 Oro)", "next": "anatomy_sell", "action": "sell:raw_chicken:9"},
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
					"text": "Soy %s de la %s (%s). %s%s\n[Stock Tablones: %d | Madera: %d]" % [npc_name, family_name, npc_role, needs_line, discount_tag, int(shop_stock.get("repair_kit", 0)), int(shop_stock.get("wood", 0))],
					"choices": [
						{"label": "🛖 Construir Cabaña de Madera en tu Campamento (Nv.2: -30 Oro)", "next": "start", "action": "upgrade_camp_house:2:30"},
						{"label": "🏡 Construir Casa de Piedra con Cofre Propio (Nv.3: -55 Oro)", "next": "start", "action": "upgrade_camp_house:3:55"},
						{"label": "⚡ Comprar 1 Bobina de Cobre para Generador/Aspersor (-16 Oro)", "next": "start", "action": "buy_unlimited:copper_coil:16"},
						{"label": "🪵 Vender 1 Madera (+8 Oro)", "next": "start", "action": "sell:wood:8"},
						{"label": "🔨 Comprar 1 Tablones Reforzados (-15 Oro) [Stock: %d]" % int(shop_stock.get("repair_kit", 0)), "next": "start", "action": "buy:repair_kit:15"},
						{"label": "🌲 Comprar 1 Madera (-9 Oro) [Stock: %d]" % int(shop_stock.get("wood", 0)), "next": "start", "action": "buy:wood:9"},
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
					"text": "Soy %s de la %s (%s). %s%s\n[Semillas Zanahoria: %d | Col: %d | Trigo: %d]" % [npc_name, family_name, npc_role, needs_line, discount_tag, int(shop_stock.get("carrot_seeds", 0)), int(shop_stock.get("cabbage_seeds", 0)), int(shop_stock.get("wheat_seeds", 0))],
					"choices": [
						{"label": "🧪 Comprar 1 Somnífero Nocturno (-18 Oro) [Duerme a un NPC 40s sin matarlo]", "next": "start", "action": "buy_unlimited:sleeping_draught:18"},
						{"label": "⚡ Comprar 1 Tónico de Ligereza (-15 Oro) [+30% Velocidad]", "next": "start", "action": "buy_unlimited:speed_tonic:15"},
						{"label": "🩺 Comprar 1 Botiquín Quirúrgico (-24 Oro)", "next": "start", "action": "buy_unlimited:surgical_kit:24"},
						{"label": "🥬 Vender 1 Col de Huerta (+12 Oro)", "next": "start", "action": "sell:cabbage:12"},
						{"label": "🥕 Vender 1 Zanahoria Fresca (+8 Oro)", "next": "start", "action": "sell:carrot:8"},
						{"label": "🌱 Comprar 2 Semillas de Zanahoria (-6 Oro)", "next": "start", "action": "buy2:carrot_seeds:6"},
						{"label": "🌱 Comprar 2 Semillas de Col (-8 Oro)", "next": "start", "action": "buy2:cabbage_seeds:8"},
						{"label": "🌾 Comprar 2 Semillas de Trigo (-8 Oro)", "next": "start", "action": "buy2:wheat_seeds:8"},
						{"label": "Salir.", "next": "END"}
					]
				}
			}
		TradeRole.FISHMONGER:
			return {
				"start": {
					"text": "Soy %s de la %s (%s). %s%s\n[Stock Pan: %d | Abono: %d]" % [npc_name, family_name, npc_role, needs_line, discount_tag, int(shop_stock.get("bread", 0)), int(shop_stock.get("fertilizer", 0))],
					"choices": [
						{"label": "Vender 1 Siluro Nocturno (+22 Oro)", "next": "start", "action": "sell:night_catfish:22"},
						{"label": "Vender 1 Carpa Dorada (+15 Oro)", "next": "start", "action": "sell:golden_carp:15"},
						{"label": "Vender 1 Trucha de Río (+10 Oro)", "next": "start", "action": "sell:river_trout:10"},
						{"label": "Vender 1 Gavilla de Trigo (+9 Oro)", "next": "start", "action": "sell:wheat:9"},
						{"label": "Comprar 1 Hogaza de Pan (-8 Oro) [Stock: %d]" % int(shop_stock.get("bread", 0)), "next": "start", "action": "buy:bread:8"},
						{"label": "Comprar 1 Abono Orgánico (-6 Oro) [Stock: %d]" % int(shop_stock.get("fertilizer", 0)), "next": "start", "action": "buy:fertilizer:6"},
						{"label": "Salir.", "next": "END"}
					]
				}
			}
		TradeRole.INNKEEPER:
			return {
				"start": {
					"text": "¡Bienvenido a la Posada y Casino El Jabalí Dorado! Soy %s, Chef y Posadera. %s%s\nAquí el tiempo se detiene mientras juegas al Póker, Blackjack, Ruleta o Billar con los vecinos." % [npc_name, needs_line, discount_tag],
					"choices": [
						{"label": "🃏🎱 Sentarse a la Mesa de Casino y Billar (Póker, 21, Ruleta y Billar)", "next": "END", "action": "open_tavern_games"},
						{"label": "🛌 Alquilar habitación y dormir hasta las 06:00 AM (-8 Oro)", "next": "END", "action": "rent_tavern_bed"},
						{"label": "🍗 Comprar 1 Pollo Asado Crujiente (-13 Oro)", "next": "start", "action": "buy_unlimited:roasted_chicken:13"},
						{"label": "🐸 Vender 1 Ancas de Rana al Ajillo (+24 Oro)", "next": "start", "action": "sell:fried_frog_legs:24"},
						{"label": "🍲 Comprar 1 Estofado Campesino (-14 Oro) [Stock: %d]" % int(shop_stock.get("country_stew", 0)), "next": "start", "action": "buy:country_stew:14"},
						{"label": "🍞 Comprar 1 Hogaza de Pan (-7 Oro) [Stock: %d]" % int(shop_stock.get("bread", 0)), "next": "start", "action": "buy:bread:7"},
						{"label": "Solo pasaba a saludar. [Salir]", "next": "END"}
					]
				}
			}
		TradeRole.FAMILY_MEMBER:
			return {
				"start": {
					"text": "Hola, soy %s de la %s (%s). %s\nVivo en esta casa familiar y ayudo en el taller. Si algún día faltara el maestro del oficio, yo me haré cargo del negocio familiar." % [npc_name, family_name, npc_role, needs_line],
					"choices": [
						{"label": "Conversar un rato (+12 Relación, +Social)", "next": "chat", "affinity": 12},
						{"label": "Regalar 1 Hogaza de Pan para su mesa familiar (+22 Relación)", "next": "start", "action": "gift_bread"},
						{"label": "Hasta luego. [Salir]", "next": "END"}
					]
				},
				"chat": {
					"text": "Cada uno en la casa tiene su propio ritmo: cuando nos entra el hambre nos sentamos a la mesa del comedor, y cuando necesitamos hablar salimos a buscar a la familia o vamos a la taberna.",
					"choices": [
						{"label": "Me alegra ver el pueblo tan vivo. [Salir]", "next": "END"}
					]
				}
			}
		_:
			return {
				"start": {
					"text": "Hola, soy %s (%s). %s\nMe alojo en una de las habitaciones de la Taberna. Paso el día según mis necesidades de comida, descanso y charla, y si algún oficio queda sin familia, estaré listo para aprenderlo." % [npc_name, npc_role, needs_line],
					"choices": [
						{"label": "Charlar un rato sobre el valle (+10 Relación)", "next": "chat", "affinity": 10},
						{"label": "Invitarle a una Hogaza de Pan (+20 Relación)", "next": "start", "action": "gift_bread"},
						{"label": "Nos vemos por la taberna. [Salir]", "next": "END"}
					]
				},
				"chat": {
					"text": "Me gusta que aquí nadie vive atado a un reloj fijo: cuando aprieta el hambre vamos a comer a la posada, y cuando estamos cansados nos echamos a dormir.",
					"choices": [
						{"label": "Tal cual. ¡Nos vemos! [Salir]", "next": "END"}
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
			health.heal(health.max_health)
		if "bleed_stacks" in player:
			player.bleed_stacks = 0
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
		var up_parts := action_id.split(":")
		var target_t: int = int(up_parts[1])
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

	if action_id == "gift_bread":
		if inv.remove_item("bread", 1):
			modify_affinity(20)
			if vm and vm.has_method("modify_family_reputation") and family_id != "none":
				vm.call("modify_family_reputation", family_id, 12, "Regalo de pan a " + npc_name, self)
			need_hunger = minf(100.0, need_hunger + 45.0)
			need_social = minf(100.0, need_social + 25.0)
			add_thought("Recibió pan recién horneado (+12)", 12.0)
			_spawn_floating_text("¡Gracias por el pan! (+Hambre/Social)", Color.GOLD, -44.0)
		else:
			_spawn_floating_text("No tienes Hogaza de Pan", Color.ORANGE_RED, -44.0)
		return

	if action_id == "forge_steel":
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
		var t_id: String = action_id.get_slice(":", 1)
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
	# Paso 4: Descuento del 20% si la familia es Aliada (`affinity >= 45`)
	if cmd != "sell" and affinity >= 45:
		price = maxi(1, int(round(float(price) * 0.8)))

	if cmd == "buy_armor" or cmd == "buy_unlimited":
		if inv.gold < price:
			_spawn_floating_text("Oro insuficiente (%d Oro)" % price, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-price)
		inv.add_item(item_id, 1)
		if cmd == "buy_armor":
			inv.equip_armor_item(item_id, player)
			add_thought("Vendió una pieza de armadura (+8)", 8.0)
		else:
			_spawn_floating_text("+1 %s (-%d Oro)" % [inv.get_item_name(item_id), price], Color.SPRING_GREEN, -44.0)
		return

	if cmd == "sell":
		if inv.remove_item(item_id, 1):
			inv.add_gold(price)
			shop_stock[item_id] = int(shop_stock.get(item_id, 0)) + 1
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
		shop_stock[item_id] = avail - 1
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
		shop_stock[item_id] = avail2 - 2
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
	return {
		"npc_name": npc_name,
		"npc_role": npc_role,
		"family_id": family_id,
		"family_name": family_name,
		"trade_role": int(trade_role),
		"linked_trade": int(linked_trade),
		"affinity": affinity,
		"need_hunger": need_hunger,
		"need_energy": need_energy,
		"need_social": need_social,
		"activity": int(current_activity),
		"is_dead": is_dead,
		"corpse_on_ground": corpse_on_ground,
		"corpse_discovered": corpse_discovered,
		"corpse_in_morgue": corpse_in_morgue,
		"corpse_rot_hours": corpse_rot_hours,
		"is_hostile": is_hostile,
		"pos_x": global_position.x,
		"pos_y": global_position.y,
		"work_x": work_position.x,
		"work_y": work_position.y,
		"bed_x": bed_position.x,
		"bed_y": bed_position.y,
		"table_x": home_table_pos.x,
		"table_y": home_table_pos.y,
		"hp": health_comp.current_health if health_comp else 65.0,
		"shop_stock": shop_stock.duplicate()
	}

func from_save_dict(data: Dictionary) -> void:
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
	if data.has("affinity"):
		affinity = int(data["affinity"])
	if data.has("need_hunger"):
		need_hunger = clampf(float(data["need_hunger"]), 0.0, 100.0)
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
	var dead_saved: bool = bool(data.get("is_dead", false))
	if dead_saved:
		_confirm_true_death()
		corpse_on_ground = bool(data.get("corpse_on_ground", true))
		corpse_discovered = bool(data.get("corpse_discovered", false))
		corpse_in_morgue = bool(data.get("corpse_in_morgue", false))
		corpse_rot_hours = float(data.get("corpse_rot_hours", 0.0))
		if corpse_in_morgue and sprite:
			sprite.visible = false
	else:
		is_dead = false
		is_hostile = bool(data.get("is_hostile", false))
		if body_col:
			body_col.set_deferred("disabled", false)
		if interact_area and interact_area.get_child_count() > 0:
			var ic := interact_area.get_child(0) as CollisionShape2D
			if ic:
				ic.set_deferred("disabled", false)
		if sprite:
			sprite.rotation_degrees = 0.0
			sprite.modulate = Color.WHITE
		if health_comp and data.has("hp"):
			health_comp.current_health = clampf(float(data["hp"]), 1.0, health_comp.max_health)
