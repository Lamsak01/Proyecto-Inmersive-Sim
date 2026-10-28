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
	FISHMONGER     # 5. Pescador y Molinero
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

# Tasas metabólicas individuales (cada NPC tiene su propio ritmo para evitar comportamiento robótico sincronizado)
var _hunger_decay_rate: float = 1.15
var _energy_decay_rate: float = 0.95
var _social_decay_rate: float = 1.05

var current_activity: ActivityState = ActivityState.WORKING
var _eat_at_tavern: bool = false
var _social_partner: VillageNPC = null
var _decision_timer: float = 0.0

var is_dead: bool = false
var is_sleeping: bool = false
var is_stunned_flag: bool = false
var is_hostile: bool = false

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

const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 1
	add_to_group("npcs")
	add_to_group("village_npcs")

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

	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = tex
	sprite.scale = Vector2(1.25, 1.25)
	add_child(sprite)

	body_col = CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.5
	body_col.shape = c
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

func _physics_process(delta: float) -> void:
	if is_dead or is_stunned_flag:
		velocity = Vector2.ZERO
		return

	if is_hostile:
		_process_hostile_combat(delta)
		move_and_slide()
		return

	_update_needs_and_decisions(delta)
	_execute_dynamic_activity(delta)
	move_and_slide()
	_update_visual_animation(delta)
	_update_hover_label()

func _is_mandatory_work_hours() -> bool:
	if trade_role == TradeRole.UNEMPLOYED:
		return false
	if not WorldClock:
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
			var to_bed: Vector2 = bed_position - global_position
			if to_bed.length() > 7.0:
				velocity = to_bed.normalized() * 42.0
			else:
				velocity = Vector2.ZERO

		ActivityState.EATING:
			var meal_pos: Vector2 = tavern_social_pos if _eat_at_tavern else home_table_pos
			var to_table: Vector2 = meal_pos - global_position
			if to_table.length() > 10.0:
				velocity = to_table.normalized() * 40.0
			else:
				velocity = Vector2.ZERO

		ActivityState.SOCIALIZING:
			var target_s: Vector2 = _get_social_target_pos()
			var to_s: Vector2 = target_s - global_position
			if to_s.length() > 16.0:
				velocity = to_s.normalized() * 38.0
			else:
				velocity = Vector2.ZERO

		ActivityState.WORKING:
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_wander_timer = randf_range(2.2, 4.6)
				if randf() < 0.55:
					_wander_offset = Vector2.ZERO
				else:
					var radius: float = 28.0 if (trade_role == TradeRole.UNEMPLOYED or trade_role == TradeRole.FAMILY_MEMBER) else 10.0
					_wander_offset = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(4.0, radius)

			var target_pos: Vector2 = work_position + _wander_offset
			var diff: Vector2 = target_pos - global_position
			if diff.length() > 5.0:
				velocity = diff.normalized() * 32.0
			else:
				velocity = Vector2.ZERO

func _find_best_social_partner() -> VillageNPC:
	var best: VillageNPC = null
	var best_score: float = -9999.0
	for node in get_tree().get_nodes_in_group("village_npcs"):
		if node == self or not (node is VillageNPC):
			continue
		var other: VillageNPC = node as VillageNPC
		if other.is_dead or other.is_sleeping:
			continue
		var dist: float = global_position.distance_to(other.global_position)
		var family_bonus: float = 120.0 if (family_id != "none" and other.family_id == family_id) else 0.0
		var score: float = family_bonus - dist * 0.4 + (100.0 - other.need_social) * 0.5
		if score > best_score:
			best_score = score
			best = other
	return best

func _get_social_target_pos() -> Vector2:
	if is_instance_valid(_social_partner) and not _social_partner.is_dead and not _social_partner.is_sleeping:
		return _social_partner.global_position + Vector2(14, 0)
	if family_id != "none":
		return home_table_pos
	return tavern_social_pos

func get_activity_description() -> String:
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
			if trade_role == TradeRole.UNEMPLOYED:
				return "🚶 Paseando por la Aldea"
			elif trade_role == TradeRole.FAMILY_MEMBER:
				return "🏠 Turno del Hogar (08-18h)" if _is_mandatory_work_hours() else "🏠 Cuidando el Hogar"
			return "⚒️ En Turno Laboral (08-18h)" if _is_mandatory_work_hours() else "⚒️ Atendiendo su Oficio"

func _process_hostile_combat(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		velocity = Vector2.ZERO
		return
	var to_p: Vector2 = player.global_position - global_position
	var dist: float = to_p.length()
	if dist > 22.0:
		velocity = to_p.normalized() * 68.0
	else:
		velocity = Vector2.ZERO
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer = 1.1
			if player.has_method("take_damage"):
				var d := DamageData.new()
				d.amount = 8.0
				d.source = self
				player.call("take_damage", d)

func _update_visual_animation(delta: float) -> void:
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
	if not status_label or is_dead:
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
		var act_txt: String = get_activity_description()
		status_label.text = "%s (%s) — %s\n[%s | 🍖%d%% 💤%d%% 💬%d%% | E: Hablar]" % [
			npc_name,
			family_name,
			npc_role,
			act_txt,
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
	if affinity >= 50:
		rel = "Aliado"
	elif affinity >= 20:
		rel = "Amistoso"
	elif affinity <= -30:
		rel = "Hostil"
	elif affinity <= -10:
		rel = "Desconfiado"
	return "%s (%s) | %s (%d)" % [npc_role, family_name, rel, affinity]

func get_relationship_color() -> Color:
	if affinity >= 50:
		return Color.CYAN
	elif affinity >= 20:
		return Color.LIGHT_GREEN
	elif affinity <= -30:
		return Color.RED
	elif affinity <= -10:
		return Color.ORANGE
	return Color(0.85, 0.88, 0.92)

func take_damage(data: DamageData) -> void:
	if is_dead:
		return
	modify_affinity(-35)
	is_hostile = true
	is_sleeping = false
	current_activity = ActivityState.WORKING
	add_to_group("enemies")
	if health_comp:
		health_comp.take_damage(data)
	if stun_comp and health_comp and health_comp.current_health > 0.0:
		stun_comp.take_damage(data)

func knockout() -> void:
	if stun_comp:
		stun_comp.trigger_stun(10.0)

func show_prompt() -> void:
	if status_label:
		status_label.text = "[E] Noquear en sigilo"
		status_label.visible = true

func hide_prompt() -> void:
	if status_label:
		status_label.visible = false

func _on_stunned(stunned: bool) -> void:
	is_stunned_flag = stunned
	if sprite:
		sprite.rotation_degrees = 90.0 if stunned else 0.0
		sprite.modulate = Color(0.55, 0.65, 1.0) if stunned else Color.WHITE

func _on_died() -> void:
	is_dead = true
	is_hostile = false
	remove_from_group("enemies")
	if body_col:
		body_col.set_deferred("disabled", true)
	if interact_area and interact_area.get_child_count() > 0:
		var ic := interact_area.get_child(0) as CollisionShape2D
		if ic:
			ic.set_deferred("disabled", true)
	if sprite:
		sprite.rotation_degrees = 90.0
		sprite.modulate = Color(0.45, 0.45, 0.45, 0.85)
	if status_label:
		status_label.visible = false

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

func interact(_player: Node) -> void:
	if is_dead or is_stunned_flag or is_hostile:
		return
	# Al conversar con el jugador, el NPC también satisface parte de su necesidad social
	need_social = minf(100.0, need_social + 18.0)
	var dm = get_tree().current_scene.get_node_or_null("Systems/dialogue_manager")
	if not dm:
		return
	var diag := _build_dialogue()
	dm.call("start_dialogue", diag, "start", self)

func _get_needs_status_line() -> String:
	return "[Estado: %s | 🍖 Hambre: %d%% | 💤 Energía: %d%% | 💬 Social: %d%%]" % [
		get_activity_description(),
		int(round(need_hunger)),
		int(round(need_energy)),
		int(round(need_social))
	]

func _build_dialogue() -> Dictionary:
	var needs_line := _get_needs_status_line()
	match trade_role:
		TradeRole.BUTCHER:
			return {
				"start": {
					"text": "Soy %s de la %s (%s). %s\n[Stock Carne Cocida: %d | Cuero: %d]" % [npc_name, family_name, npc_role, needs_line, int(shop_stock.get("cooked_meat", 0)), int(shop_stock.get("leather", 0))],
					"choices": [
						{"label": "Vender 1 Piel de Zorro (+18 Oro)", "next": "start", "action": "sell:fox_pelt:18"},
						{"label": "Vender 1 Cuero Animal (+10 Oro)", "next": "start", "action": "sell:leather:10"},
						{"label": "Vender 1 Carne Cruda (+8 Oro)", "next": "start", "action": "sell:raw_meat:8"},
						{"label": "Comprar 1 Carne Cocida (-10 Oro) [Stock: %d]" % int(shop_stock.get("cooked_meat", 0)), "next": "start", "action": "buy:cooked_meat:10"},
						{"label": "Charlar sobre su familia y rutina (+8 Relación)", "next": "family_chat", "affinity": 8},
						{"label": "Hasta luego. [Salir]", "next": "END"}
					]
				},
				"family_chat": {
					"text": "En nuestra casa compartimos la mesa cuando aprieta el hambre. Si algún día me pasa algo, mi familia mantendrá abierto el puesto de carnicería.",
					"choices": [{"label": "Entendido. [Volver]", "next": "start"}]
				}
			}
		TradeRole.BLACKSMITH:
			return {
				"start": {
					"text": "Soy %s de la %s (%s). %s\n[Stock Hierro: %d | Tablones: %d]" % [npc_name, family_name, npc_role, needs_line, int(shop_stock.get("iron_ore", 0)), int(shop_stock.get("repair_kit", 0))],
					"choices": [
						{"label": "Vender 1 Mineral de Hierro (+14 Oro)", "next": "start", "action": "sell:iron_ore:14"},
						{"label": "Vender 1 Piedra (+7 Oro)", "next": "start", "action": "sell:stone:7"},
						{"label": "Comprar 1 Tablones Reforzados (-16 Oro) [Stock: %d]" % int(shop_stock.get("repair_kit", 0)), "next": "start", "action": "buy:repair_kit:16"},
						{"label": "Charlar sobre la forja y su familia (+8 Relación)", "next": "family_chat", "affinity": 8},
						{"label": "Nos vemos. [Salir]", "next": "END"}
					]
				},
				"family_chat": {
					"text": "El calor de la fragua agota rápido y da hambre, así que me verás entrar a comer a casa o tomar aire con los vecinos cuando necesito descansar.",
					"choices": [{"label": "Buen trabajo. [Volver]", "next": "start"}]
				}
			}
		TradeRole.CARPENTER:
			return {
				"start": {
					"text": "Soy %s de la %s (%s). %s\n[Stock Tablones: %d | Madera: %d]" % [npc_name, family_name, npc_role, needs_line, int(shop_stock.get("repair_kit", 0)), int(shop_stock.get("wood", 0))],
					"choices": [
						{"label": "Vender 1 Madera (+8 Oro)", "next": "start", "action": "sell:wood:8"},
						{"label": "Comprar 1 Tablones Reforzados (-15 Oro) [Stock: %d]" % int(shop_stock.get("repair_kit", 0)), "next": "start", "action": "buy:repair_kit:15"},
						{"label": "Comprar 1 Madera (-9 Oro) [Stock: %d]" % int(shop_stock.get("wood", 0)), "next": "start", "action": "buy:wood:9"},
						{"label": "Charlar un rato (+8 Relación)", "next": "family_chat", "affinity": 8},
						{"label": "Hasta pronto. [Salir]", "next": "END"}
					]
				},
				"family_chat": {
					"text": "Construimos todas las casas de esta aldea con pino del bosque del sur. Cuando me canso de aserrar, entro a casa a comer o voy a la taberna a charlar.",
					"choices": [{"label": "Así se hace. [Volver]", "next": "start"}]
				}
			}
		TradeRole.HERBALIST:
			return {
				"start": {
					"text": "Soy %s de la %s (%s). %s\n[Semillas Zanahoria: %d | Col: %d | Trigo: %d]" % [npc_name, family_name, npc_role, needs_line, int(shop_stock.get("carrot_seeds", 0)), int(shop_stock.get("cabbage_seeds", 0)), int(shop_stock.get("wheat_seeds", 0))],
					"choices": [
						{"label": "Vender 1 Col de Huerta (+12 Oro)", "next": "start", "action": "sell:cabbage:12"},
						{"label": "Vender 1 Zanahoria Fresca (+8 Oro)", "next": "start", "action": "sell:carrot:8"},
						{"label": "Comprar 2 Semillas de Zanahoria (-6 Oro)", "next": "start", "action": "buy2:carrot_seeds:6"},
						{"label": "Comprar 2 Semillas de Col (-8 Oro)", "next": "start", "action": "buy2:cabbage_seeds:8"},
						{"label": "Comprar 2 Semillas de Trigo (-8 Oro)", "next": "start", "action": "buy2:wheat_seeds:8"},
						{"label": "Salir.", "next": "END"}
					]
				}
			}
		TradeRole.FISHMONGER:
			return {
				"start": {
					"text": "Soy %s de la %s (%s). %s\n[Stock Pan: %d | Abono: %d]" % [npc_name, family_name, npc_role, needs_line, int(shop_stock.get("bread", 0)), int(shop_stock.get("fertilizer", 0))],
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
					"text": "¡Bienvenido a la Taberna El Jabalí Dorado! Soy %s. %s\nAquí vienen los vecinos cuando quieren comer caliente, jugar unas manos de cartas o socializar, y arriba duermen los viajeros." % [npc_name, needs_line],
					"choices": [
						{"label": "🎲 Sentarse a la Mesa de Juegos (Póker, Blackjack y Ruleta)", "next": "END", "action": "open_tavern_games"},
						{"label": "🛌 Alquilar habitación y dormir hasta las 06:00 AM (-8 Oro)", "next": "END", "action": "rent_tavern_bed"},
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
			need_hunger = minf(100.0, need_hunger + 45.0)
			need_social = minf(100.0, need_social + 25.0)
			_spawn_floating_text("¡Gracias por el pan! (+Hambre/Social)", Color.GOLD, -44.0)
		else:
			_spawn_floating_text("No tienes Hogaza de Pan", Color.ORANGE_RED, -44.0)
		return

	var parts := action_id.split(":")
	if parts.size() != 3:
		return
	var cmd := parts[0]
	var item_id := parts[1]
	var price := int(parts[2])

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
	if FloatingTextScene:
		var ft = FloatingTextScene.instantiate()
		ft.start_text = text
		ft.text_color = color
		ft.global_position = global_position + Vector2(0, offset_y)
		get_tree().current_scene.add_child(ft)

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
		_on_died()
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
