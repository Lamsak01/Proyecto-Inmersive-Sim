extends CharacterBody2D
class_name VillageNPC

## Habitante Sistémico de la Aldea ("La Placa de Petri") — Fase 2.3 y 2.4
## - Soporta los 5 Oficios con Stock Real (`shop_stock`), el rol de Tabernera (alquiler de cama para dormir)
##   y los NPCs sin oficio/viajeros que socializan de día y duermen de noche en las habitaciones de la Taberna.
## - Incluye Afinidad (-100 a +100), Rutina Diaria conectada a WorldClock (Trabajo/Plaza de día -> Cama de noche),
##   Combate/KO y Sucesión automática cuando un puesto de oficio queda vacante.

enum TradeRole {
	UNEMPLOYED, # Viajero / Sin oficio (duerme en habitación de la Taberna y puede heredar un oficio vacante)
	INNKEEPER,  # Tabernera (vende comida caliente y alquila habitación para dormir)
	BUTCHER,    # 1. Carnicero y Peletero
	BLACKSMITH, # 2. Herrero
	CARPENTER,  # 3. Carpintero
	HERBALIST,  # 4. Herborista y Agricultora
	FISHMONGER  # 5. Pescador y Molinero
}

@export var npc_id: String = "npc_01"
@export var npc_name: String = "Aldeano"
@export var npc_role: String = "Habitante"
@export var trade_role: TradeRole = TradeRole.UNEMPLOYED
@export var affinity: int = 10

var work_position: Vector2 = Vector2.ZERO
var bed_position: Vector2 = Vector2.ZERO
var shop_stock: Dictionary = {}

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

const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 1
	add_to_group("npcs")
	add_to_group("village_npcs")

func setup_npc(tex: Texture2D, p_work_pos: Vector2, p_bed_pos: Vector2, initial_stock: Dictionary = {}) -> void:
	work_position = p_work_pos
	bed_position = p_bed_pos
	global_position = work_position
	shop_stock = initial_stock.duplicate()

	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = tex
	sprite.scale = Vector2(1.25, 1.25)
	add_child(sprite)

	body_col = CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 7.0
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
	status_label.position = Vector2(-115, -34)
	status_label.custom_minimum_size = Vector2(230, 20)
	status_label.add_theme_font_size_override("font_size", 9)
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

	_process_daily_routine(delta)
	move_and_slide()
	_update_visual_animation(delta)
	_update_hover_label()

func _process_daily_routine(delta: float) -> void:
	var is_night := false
	if WorldClock:
		var h: int = WorldClock.current_hour
		# La Tabernera cierra más tarde (23:00 a 06:00); los demás duermen de 20:00 a 06:00
		if trade_role == TradeRole.INNKEEPER:
			is_night = (h >= 23 or h < 6)
		else:
			is_night = (h >= 20 or h < 6)

	if is_night:
		var to_bed: Vector2 = bed_position - global_position
		if to_bed.length() > 8.0:
			is_sleeping = false
			velocity = to_bed.normalized() * 38.0
		else:
			is_sleeping = true
			velocity = Vector2.ZERO
		return

	is_sleeping = false
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(2.2, 4.5)
		if randf() < 0.60:
			_wander_offset = Vector2.ZERO
		else:
			var radius: float = 28.0 if trade_role == TradeRole.UNEMPLOYED else 12.0
			_wander_offset = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(4.0, radius)

	var target_pos: Vector2 = work_position + _wander_offset
	var diff: Vector2 = target_pos - global_position
	if diff.length() > 5.0:
		velocity = diff.normalized() * 32.0
	else:
		velocity = Vector2.ZERO

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
	var near_player: bool = player != null and global_position.distance_squared_to(player.global_position) <= 28.0 * 28.0
	var near_mouse: bool = global_position.distance_squared_to(get_global_mouse_position()) <= 20.0 * 20.0

	if is_sleeping and not near_mouse and not near_player:
		status_label.text = "Zzz"
		status_label.add_theme_color_override("font_color", Color(0.72, 0.85, 1.0))
		status_label.visible = true
		return

	if near_player or near_mouse:
		var act := "Durmiendo (Zzz)" if is_sleeping else ("En la Taberna" if trade_role == TradeRole.UNEMPLOYED else "Trabajando")
		status_label.text = "%s — %s [%s | E: Hablar]" % [npc_name, npc_role, act]
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
	return "%s | %s (%d)" % [npc_role, rel, affinity]

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

## Sucesión: este NPC sin oficio asume un puesto vacante en la aldea
func promote_to_trade(new_role: TradeRole, new_title: String, new_work_pos: Vector2, inherited_stock: Dictionary, new_tex: Texture2D = null) -> void:
	trade_role = new_role
	npc_role = new_title + " (Sucesor)"
	work_position = new_work_pos
	shop_stock = inherited_stock.duplicate()
	if new_tex and sprite:
		sprite.texture = new_tex

func interact(player: Node) -> void:
	if is_dead or is_stunned_flag or is_hostile:
		return
	var dm = get_tree().current_scene.get_node_or_null("Systems/dialogue_manager")
	if not dm:
		return
	var diag := _build_dialogue()
	dm.call("start_dialogue", diag, "start", self)

func _build_dialogue() -> Dictionary:
	match trade_role:
		TradeRole.BUTCHER:
			return {
				"start": {
					"text": "Soy %s (%s). Compro pieles de caza y carne fresca, y vendo raciones asadas. [Stock Carne Cocida: %d | Cuero: %d]" % [npc_name, npc_role, int(shop_stock.get("cooked_meat", 0)), int(shop_stock.get("leather", 0))],
					"choices": [
						{"label": "Vender 1 Piel de Zorro (+18 Oro)", "next": "start", "action": "sell:fox_pelt:18"},
						{"label": "Vender 1 Cuero Animal (+10 Oro)", "next": "start", "action": "sell:leather:10"},
						{"label": "Vender 1 Carne Cruda (+8 Oro)", "next": "start", "action": "sell:raw_meat:8"},
						{"label": "Comprar 1 Carne Cocida (-10 Oro) [Stock: %d]" % int(shop_stock.get("cooked_meat", 0)), "next": "start", "action": "buy:cooked_meat:10"},
						{"label": "Hasta luego. [Salir]", "next": "END"}
					]
				}
			}
		TradeRole.BLACKSMITH:
			return {
				"start": {
					"text": "Soy %s (%s). Si traes mineral de hierro o piedra del bosque, te lo pagaré bien en oro. [Stock Hierro: %d | Tablones: %d]" % [npc_name, npc_role, int(shop_stock.get("iron_ore", 0)), int(shop_stock.get("repair_kit", 0))],
					"choices": [
						{"label": "Vender 1 Mineral de Hierro (+14 Oro)", "next": "start", "action": "sell:iron_ore:14"},
						{"label": "Vender 1 Piedra (+7 Oro)", "next": "start", "action": "sell:stone:7"},
						{"label": "Comprar 1 Tablones Reforzados (-16 Oro) [Stock: %d]" % int(shop_stock.get("repair_kit", 0)), "next": "start", "action": "buy:repair_kit:16"},
						{"label": "Nos vemos. [Salir]", "next": "END"}
					]
				}
			}
		TradeRole.CARPENTER:
			return {
				"start": {
					"text": "Soy %s (%s). La madera del bosque del sur es excelente. Tráeme troncos o compra tablones listos. [Stock Tablones: %d | Madera: %d]" % [npc_name, npc_role, int(shop_stock.get("repair_kit", 0)), int(shop_stock.get("wood", 0))],
					"choices": [
						{"label": "Vender 1 Madera (+8 Oro)", "next": "start", "action": "sell:wood:8"},
						{"label": "Comprar 1 Tablones Reforzados (-15 Oro) [Stock: %d]" % int(shop_stock.get("repair_kit", 0)), "next": "start", "action": "buy:repair_kit:15"},
						{"label": "Comprar 1 Madera (-9 Oro) [Stock: %d]" % int(shop_stock.get("wood", 0)), "next": "start", "action": "buy:wood:9"},
						{"label": "Hasta pronto. [Salir]", "next": "END"}
					]
				}
			}
		TradeRole.HERBALIST:
			return {
				"start": {
					"text": "Soy %s (%s). Tengo semillas para tu huerto y compro tus cosechas y hierbas. [Semillas Zanahoria: %d | Col: %d | Trigo: %d]" % [npc_name, npc_role, int(shop_stock.get("carrot_seeds", 0)), int(shop_stock.get("cabbage_seeds", 0)), int(shop_stock.get("wheat_seeds", 0))],
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
					"text": "Soy %s (%s). Compro todo el pescado que saques del lago del oeste y trigo de tu huerto. [Stock Pan: %d | Abono: %d]" % [npc_name, npc_role, int(shop_stock.get("bread", 0)), int(shop_stock.get("fertilizer", 0))],
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
					"text": "¡Bienvenido a la Taberna El Jabalí Dorado! Soy %s. Aquí duermen los viajeros sin oficio y siempre hay plato caliente y cama limpia (8 Oro la noche)." % npc_name,
					"choices": [
						{"label": "🛌 Alquilar habitación y dormir hasta las 06:00 AM (-8 Oro)", "next": "END", "action": "rent_tavern_bed"},
						{"label": "🍲 Comprar 1 Estofado Campesino (-14 Oro) [Stock: %d]" % int(shop_stock.get("country_stew", 0)), "next": "start", "action": "buy:country_stew:14"},
						{"label": "🍞 Comprar 1 Hogaza de Pan (-7 Oro) [Stock: %d]" % int(shop_stock.get("bread", 0)), "next": "start", "action": "buy:bread:7"},
						{"label": "Solo pasaba a tomar algo. [Salir]", "next": "END"}
					]
				}
			}
		_:
			return {
				"start": {
					"text": "Hola, soy %s (%s). Por ahora no tengo un taller propio, así que paso el día por la aldea y duermo de noche en una de las habitaciones de la Taberna. Si algún artesano falta, estaré listo para aprender su oficio." % [npc_name, npc_role],
					"choices": [
						{"label": "Charlar un rato sobre el valle (+10 Relación)", "next": "chat", "affinity": 10},
						{"label": "Invitarle a una Hogaza de Pan (+20 Relación)", "next": "start", "action": "gift_bread"},
						{"label": "Nos vemos por la taberna. [Salir]", "next": "END"}
					]
				},
				"chat": {
					"text": "Dicen que en el lago al oeste del huerto pican truchas de día y grandes siluros de noche. Y ten cuidado con los zorros si dejas a tus gallinas sin vigilar.",
					"choices": [
						{"label": "Buen dato, gracias. [Salir]", "next": "END"}
					]
				}
			}

func on_dialogue_action(action_id: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not ("inventory" in player) or not player.inventory:
		return
	var inv: SimpleInventory = player.inventory

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
			_spawn_floating_text("¡Gracias por el pan!", Color.GOLD, -44.0)
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
		"trade_role": int(trade_role),
		"affinity": affinity,
		"is_dead": is_dead,
		"is_hostile": is_hostile,
		"pos_x": global_position.x,
		"pos_y": global_position.y,
		"work_x": work_position.x,
		"work_y": work_position.y,
		"hp": health_comp.current_health if health_comp else 65.0,
		"shop_stock": shop_stock.duplicate()
	}

func from_save_dict(data: Dictionary) -> void:
	if data.has("npc_role"):
		npc_role = str(data["npc_role"])
	if data.has("trade_role"):
		trade_role = int(data["trade_role"]) as TradeRole
	if data.has("affinity"):
		affinity = int(data["affinity"])
	if data.has("pos_x") and data.has("pos_y"):
		global_position = Vector2(float(data["pos_x"]), float(data["pos_y"]))
	if data.has("work_x") and data.has("work_y"):
		work_position = Vector2(float(data["work_x"]), float(data["work_y"]))
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
