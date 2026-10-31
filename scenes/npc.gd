extends CharacterBody2D
## NPC Aldeano con sistema de Afinidad/Relación (-100 a +100), Combate (Sangrado y Stun/KO) y Diálogo Contextual.

@export var npc_name: String = "Aldeano Guía"
@export var npc_role: String = "Vigía de la Aldea"
@export var dialogue_manager: Node
@export var enemy_ai: Node
@export var affinity: int = 0 ## -100 (Enemigo mortal) a +100 (Aliado fiel)
@export var hostility_threshold: int = -30 ## Si la afinidad baja de este valor, se vuelve hostil

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Hurtbox = get_node_or_null("Hurtbox")
@onready var health_comp: HealthComponent = get_node_or_null("HealthComponent")
@onready var stun_comp: StunComponent = get_node_or_null("StunComponent")

const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

enum Attitude { HOSTILE, UNFRIENDLY, NEUTRAL, FRIENDLY, ALLY }
var current_attitude: Attitude = Attitude.NEUTRAL
var is_attacking: bool = false
var is_stunned_flag: bool = false
var is_dead: bool = false
var push_velocity: Vector2 = Vector2.ZERO
@export var weight: float = 25.0

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 3
	add_to_group("npcs")
	anim.play("idle")
	_update_attitude_from_affinity()

	if enemy_ai:
		enemy_ai.set_process(false)
		enemy_ai.set_physics_process(false)
		if enemy_ai.has_signal("attack_triggered"):
			enemy_ai.attack_triggered.connect(_on_enemy_ai_attack)

	if not health_comp:
		health_comp = HealthComponent.new()
		health_comp.name = "HealthComponent"
		health_comp.max_health = 60.0
		add_child(health_comp)
	health_comp.died.connect(_on_died)
	health_comp.bleed_triggered.connect(_on_bleed_triggered)

	if not stun_comp:
		stun_comp = StunComponent.new()
		stun_comp.name = "StunComponent"
		stun_comp.max_stun = 100.0
		stun_comp.stun_duration = 4.0
		add_child(stun_comp)
	stun_comp.stunned.connect(_on_stunned)

	if hurtbox:
		hurtbox.hit_received.connect(take_damage)

func apply_push(force: Vector2) -> void:
	push_velocity = force

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return
	if push_velocity.length_squared() > 1.0:
		velocity = push_velocity
		push_velocity = push_velocity.move_toward(Vector2.ZERO, 320.0 * delta)
		move_and_slide()
		return
	if is_stunned_flag or not is_attacking or not enemy_ai:
		velocity = Vector2.ZERO
		return

	move_and_slide()

func _spawn_floating_text(text: String, color: Color, offset_y: float = -36.0) -> void:
	if FloatingTextScene:
		var ft = FloatingTextScene.instantiate()
		ft.start_text = text
		ft.text_color = color
		ft.global_position = global_position + Vector2(0, offset_y)
		get_tree().current_scene.add_child(ft)

# --- Sistema de Relación / Afinidad ---

func modify_affinity(delta_amount: int) -> void:
	if delta_amount == 0:
		return
	affinity = clamp(affinity + delta_amount, -100, 100)
	_update_attitude_from_affinity()
	_spawn_floating_text("%s%d Relación" % ["+" if delta_amount > 0 else "", delta_amount], Color.SPRING_GREEN if delta_amount > 0 else Color.CORAL, -42.0)

func _update_attitude_from_affinity() -> void:
	if affinity <= hostility_threshold: current_attitude = Attitude.HOSTILE
	elif affinity <= -10: current_attitude = Attitude.UNFRIENDLY
	elif affinity < 20: current_attitude = Attitude.NEUTRAL
	elif affinity < 50: current_attitude = Attitude.FRIENDLY
	else: current_attitude = Attitude.ALLY

func get_relationship_status_text() -> String:
	const STATES := {Attitude.HOSTILE: "Hostil", Attitude.UNFRIENDLY: "Desconfiado", Attitude.NEUTRAL: "Neutral", Attitude.FRIENDLY: "Amistoso", Attitude.ALLY: "Aliado"}
	return "%s | %s (%d)" % [npc_role, STATES.get(current_attitude, "Neutral"), affinity]

func get_relationship_color() -> Color:
	const COLS := {Attitude.HOSTILE: Color.RED, Attitude.UNFRIENDLY: Color.ORANGE, Attitude.NEUTRAL: Color(0.8, 0.85, 0.9), Attitude.FRIENDLY: Color.LIGHT_GREEN, Attitude.ALLY: Color.CYAN}
	return COLS.get(current_attitude, Color.WHITE)

# --- Combate / Daño / Stun / Sangrado ---

func take_damage(data: DamageData) -> void:
	if is_dead:
		return
	var from_player: bool = (data != null and is_instance_valid(data.source) and (data.source.is_in_group("player") or data.source.is_in_group("player_trap")))
	if from_player:
		modify_affinity(-40)
		if dialogue_manager and dialogue_manager.has_method("is_active") and dialogue_manager.call("is_active"):
			dialogue_manager.call("end_dialogue")
		if not is_attacking:
			_trigger_attack()
	elif data and is_instance_valid(data.source) and enemy_ai and enemy_ai.has_method("notify_damage"):
		is_attacking = true
		enemy_ai.set_process(true)
		enemy_ai.set_physics_process(true)
		enemy_ai.notify_damage(data.source)

	if health_comp:
		health_comp.take_damage(data)
	if stun_comp and health_comp and health_comp.current_health > 0:
		stun_comp.take_damage(data)

	if not is_dead:
		modulate = Color(10, 10, 10)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self) and not is_dead and health_comp and health_comp.current_health > 0:
			modulate = Color(0.5, 0.6, 1.0) if is_stunned_flag else Color.WHITE

func knockout() -> void:
	if is_dead:
		return
	if stun_comp:
		var d := DamageData.new()
		d.stun_buildup = stun_comp.max_stun
		stun_comp.take_damage(d)

func stealth_knockout(_player: Node = null) -> void:
	knockout()

func stealth_assassinate(_player: Node = null) -> void:
	if is_dead:
		return
	if health_comp:
		var d := DamageData.new()
		d.amount = health_comp.max_health * 10.0
		health_comp.take_damage(d)

func _on_bleed_triggered(_dps: float) -> void:
	_spawn_floating_text("BLEEDING!", Color.CRIMSON, -28.0)

func _on_stunned(stunned: bool) -> void:
	if is_dead:
		return
	is_stunned_flag = stunned
	if enemy_ai and is_attacking:
		enemy_ai.set_physics_process(not stunned)
	if stunned:
		anim.stop()
		rotation_degrees = 90
		modulate = Color(0.5, 0.6, 1.0)
		_spawn_floating_text("STUNNED!", Color.AQUA, -48.0)
	else:
		rotation_degrees = 0
		modulate = Color.WHITE
		anim.play("idle")

func _on_died() -> void:
	if is_dead:
		return
	is_dead = true
	is_attacking = false
	remove_from_group("enemies")
	set_physics_process(false)
	set_process(false)
	if enemy_ai:
		enemy_ai.set_process(false)
		enemy_ai.set_physics_process(false)
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

	$InteractArea/NpcInteractCollision.set_deferred("disabled", true)
	$"cuerpo solido".set_deferred("disabled", true)

	rotation_degrees = 90
	modulate = Color.WHITE
	anim.modulate = Color(0.45, 0.45, 0.45, 0.8)

func _trigger_attack() -> void:
	is_attacking = true
	current_attitude = Attitude.HOSTILE
	add_to_group("enemies")
	if enemy_ai:
		enemy_ai.set_process(true)
		enemy_ai.set_physics_process(true)
		var player = get_tree().get_first_node_in_group("player")
		if player and enemy_ai.has_method("notify_damage"):
			enemy_ai.notify_damage(player)

func _on_enemy_ai_attack(damage_data: DamageData) -> void:
	if enemy_ai and "target" in enemy_ai and enemy_ai.target:
		if enemy_ai.target.has_method("take_damage"):
			damage_data.source = self
			enemy_ai.target.take_damage(damage_data)

func play_attack_anticipation(duration: float) -> void:
	var original_modulate = modulate
	modulate = Color(1.0, 0.5, 0.0)
	var tween = create_tween()
	var orig_scale = scale
	tween.tween_property(self, "scale", orig_scale * 1.1, duration * 0.5)
	tween.tween_property(self, "scale", orig_scale, duration * 0.5)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self) and modulate == Color(1.0, 0.5, 0.0):
		modulate = original_modulate

# --- Interacción y Diálogo ---

func interact(_player: Node) -> void:
	if is_stunned_flag:
		return
	if is_attacking:
		if _player and _player.has_method("show_hint"):
			_player.show_hint(npc_name + " es hostil y no quiere hablar.")
		return

	var dialogue_data: Dictionary = _build_dialogue_for_attitude()
	if dialogue_manager:
		dialogue_manager.call("start_dialogue", dialogue_data, "start", self)

func on_dialogue_action(action_id: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	match action_id:
		"start_combat", "start_ combat", "provoke_fight":
			_trigger_attack()
		"heal_player":
			if player and player.has_node("HealthComponent"):
				var hc: HealthComponent = player.get_node("HealthComponent")
				hc.heal(30.0)
				hc.stop_bleeding()
				_spawn_floating_text("Curado +30 HP", Color.GREEN, -48.0)
		"sell_wood":
			if player and "inventory" in player and player.inventory:
				if player.inventory.remove_item("wood", 1):
					player.inventory.add_gold(8)
					modify_affinity(8)
					_spawn_floating_text("+8 Oro (Madera entregada)", Color.GOLD, -48.0)
				else:
					_spawn_floating_text("No tienes Madera", Color.ORANGE_RED, -48.0)
		"buy_bandage":
			if player and "inventory" in player and player.inventory:
				if player.inventory.gold >= 6:
					player.inventory.add_gold(-6)
					player.inventory.add_item("bandage", 1)
					_spawn_floating_text("+1 Vendaje (-6 Oro)", Color.LIGHT_GREEN, -48.0)
				else:
					_spawn_floating_text("Oro insuficiente (6 Oro)", Color.ORANGE_RED, -48.0)

func _build_dialogue() -> Dictionary:
	return _build_dialogue_for_attitude()

func _build_dialogue_for_attitude() -> Dictionary:
	match current_attitude:
		Attitude.FRIENDLY, Attitude.ALLY:
			return {
				"start": {"text": "¡Me alegra verte! Vigilo el paso entre la Granja y la Llanura Salvaje del Oeste. ¿Necesitas algo?", "choices": [
					{"label": "¿Puedes vendar mis heridas?", "next": "healed", "action": "heal_player"},
					{"label": "Te traje Madera para el puesto (+8 Oro, +8 Relación)", "next": "start", "action": "sell_wood"},
					{"label": "Comprar Vendaje Limpio (-6 Oro)", "next": "start", "action": "buy_bandage"},
					{"label": "Háblame de la Llanura Salvaje y la Ciénaga.", "next": "frogs_info"},
					{"label": "Solo pasaba a saludar. [Salir]", "next": "END"}
				]},
				"healed": {"text": "Listo, eso detendrá el sangrado y recuperará tus fuerzas. Ten más cuidado ahí fuera.", "choices": [{"label": "¡Muchas gracias! [Salir]", "next": "END"}]},
				"frogs_info": {"text": "Aquí en la Llanura del Oeste hay ruinas hostiles al noroeste y la Ciénaga de las Ranas al suroeste. Usa el Martillo ([2]) para aturdirlas o acércate en sigilo ([C]).", "choices": [{"label": "Buen consejo, me encargaré de ellas.", "next": "END", "affinity": 5}]}
			}
		Attitude.UNFRIENDLY, Attitude.HOSTILE:
			return {
				"start": {"text": "No me gusta tu actitud, forastero. Más vale que no causes problemas en nuestra aldea o te pesará.", "choices": [
					{"label": "Disculpa, empecemos de nuevo.", "next": "apology", "affinity": 15},
					{"label": "Intenta detenerme si puedes. [Pelear]", "next": "END", "affinity": -30, "action": "provoke_fight"},
					{"label": "[Alejarse en silencio]", "next": "END"}
				]},
				"apology": {"text": "Hmph... Está bien. Mientras respetes a la gente del pueblo y ayudes con las plagas, no tendremos problemas.", "choices": [{"label": "Entendido. [Salir]", "next": "END"}]}
			}

		_: # NEUTRAL
			return {
				"start": {"text": "Alto ahí. Estás entrando en la Llanura Salvaje del Oeste. Más allá de este puesto hay ruinas hostiles y la ciénaga de las ranas.", "choices": [
					{"label": "Quiero ganarme mi lugar. ¿En qué puedo ayudar?", "next": "help_branch", "affinity": 15},
					{"label": "Vender 1 Madera (+8 Oro, +8 Relación)", "next": "start", "action": "sell_wood"},
					{"label": "Comprar Vendaje Limpio (-6 Oro)", "next": "start", "action": "buy_bandage"},
					{"label": "¿Cómo se dividen las zonas del valle?", "next": "tips_branch"},
					{"label": "Apártate de mi camino, viejo.", "next": "rude_branch", "affinity": -20},
					{"label": "Nos vemos luego. [Salir]", "next": "END"}
				]},
				"help_branch": {"text": "Aquí mismo a mi izquierda dejé una espada. Al suroeste de esta llanura está la Ciénaga de las Ranas y al noroeste el campamento hostil. Límpialos y el pueblo te respetará.", "choices": [{"label": "Cuenta conmigo.", "next": "END", "affinity": 10}, {"label": "Veré qué puedo hacer.", "next": "END"}]},
				"tips_branch": {"text": "Al este tienes tu Granja y la Aldea con sus talleres, casas y la Posada-Casino. Siguiendo el sendero largo del sur llegarás al Bosque Profundo, dividido en Pradera de Conejos (Oeste), Claros de Venados (Sur) y Cantera de Zorros (Este).", "choices": [{"label": "Gracias por la información.", "next": "start", "affinity": 5}]},
				"rude_branch": {"text": "Cuidado con esa lengua. En una aldea de cinco casas todo se sabe muy rápido, y nadie le vende comida a un bravucón.", "choices": [{"label": "Tienes razón, disculpa.", "next": "start", "affinity": 15}, {"label": "No me importa. [Salir]", "next": "END", "affinity": -10}]}
			}

func to_save_dict() -> Dictionary:
	return {
		"npc_name": npc_name,
		"pos_x": global_position.x,
		"pos_y": global_position.y,
		"affinity": affinity,
		"hp": health_comp.current_health if health_comp else 60.0,
		"is_dead": (health_comp.current_health <= 0.0) if health_comp else false,
		"is_attacking": is_attacking
	}

func from_save_dict(data: Dictionary) -> void:
	if data.has("pos_x") and data.has("pos_y"):
		global_position = Vector2(float(data["pos_x"]), float(data["pos_y"]))
	affinity = int(data.get("affinity", affinity))
	_update_attitude_from_affinity()
	if health_comp and data.has("hp"):
		health_comp.current_health = float(data["hp"])
		if bool(data.get("is_dead", false)) or health_comp.current_health <= 0.0:
			_on_died()
		else:
			is_dead = false
			is_stunned_flag = false
			health_comp.stop_bleeding()
			if stun_comp:
				stun_comp.clear_stun()
			if hurtbox:
				hurtbox.set_deferred("monitoring", true)
				hurtbox.set_deferred("monitorable", true)
			set_physics_process(true)
			set_process(true)
			rotation_degrees = 0
			anim.modulate = Color.WHITE
			$InteractArea/NpcInteractCollision.set_deferred("disabled", false)
			$"cuerpo solido".set_deferred("disabled", false)
	if bool(data.get("is_attacking", false)) and (not health_comp or health_comp.current_health > 0.0):
		_trigger_attack()
	else:
		is_attacking = false
		remove_from_group("enemies")
		if enemy_ai:
			enemy_ai.set_process(false)
			enemy_ai.set_physics_process(false)
