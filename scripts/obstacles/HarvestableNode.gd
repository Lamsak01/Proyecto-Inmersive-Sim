extends StaticBody2D
class_name HarvestableNode

## Nodo de Recolección Sistémico (Forrajeo, Tala y Minería) con Regeneración por Días — Fase 3
## Se conecta con WorldClock (day_passed) y GameManager (F5/F9) para persistir su estado y regenerarse tras X días.

enum HarvestType {
	FORAGE,  # Se recoge con [E] (Hierbas, Hongos)
	LOGGING, # Se tala con arma cortante [1] (Árboles -> Madera + Semillas)
	MINING   # Se pica con arma contundente [2] (Rocas/Vetas -> Piedra + Mineral de Hierro)
}

@export var harvest_type: HarvestType = HarvestType.FORAGE
@export var node_title: String = "Hierbas Silvestres"
@export var primary_item_id: String = "herbs"
@export var primary_amount: int = 2
@export var bonus_item_id: String = ""
@export var bonus_amount: int = 1
@export var max_hp: float = 30.0
@export var respawn_days: int = 2
@export var max_animal_bites: int = 2
@export var persistence_id: String = ""

var current_hp: float = 30.0
var animal_bites_left: int = 2
var is_depleted: bool = false
var respawn_on_day: int = -1

var sprite: Sprite2D = null
var body_collision: CollisionShape2D = null
var interact_area: Area2D = null
var prompt_label: Label = null

var _active_texture: Texture2D = null
var _depleted_texture: Texture2D = null
var _active_scale: Vector2 = Vector2.ONE
var _active_modulate: Color = Color.WHITE

func _ready() -> void:
	if persistence_id == "":
		persistence_id = "harvest_" + name + "_" + str(int(global_position.x)) + "_" + str(int(global_position.y))

	current_hp = max_hp
	animal_bites_left = max_animal_bites
	if harvest_type != HarvestType.FORAGE:
		add_to_group("destructible")
	else:
		add_to_group("wild_flora")

	if WorldClock:
		WorldClock.day_passed.connect(_on_day_passed)
	if GameManager:
		GameManager.game_loaded.connect(_on_game_loaded)

	_check_saved_state()

func setup_visuals(tex_active: Texture2D, tex_depleted: Texture2D = null, tint: Color = Color.WHITE, spr_scale: Vector2 = Vector2.ONE, col_radius: float = 12.0) -> void:
	_active_texture = tex_active
	_depleted_texture = tex_depleted
	_active_modulate = tint
	_active_scale = spr_scale

	# 1. Sprite
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = _active_texture
	sprite.modulate = _active_modulate
	sprite.scale = _active_scale
	sprite.position = Vector2(0, -12) if harvest_type == HarvestType.LOGGING else Vector2.ZERO
	add_child(sprite)

	# 2. Colisión física para Árboles y Vetas de Roca
	body_collision = CollisionShape2D.new()
	body_collision.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = col_radius
	body_collision.shape = circle
	body_collision.disabled = (harvest_type == HarvestType.FORAGE)
	add_child(body_collision)

	# 3. Área de Interacción / Etiqueta de ayuda
	interact_area = Area2D.new()
	interact_area.name = "InteractArea"
	interact_area.collision_layer = 1
	interact_area.collision_mask = 2
	if harvest_type == HarvestType.FORAGE:
		interact_area.add_to_group("interactable")
	var area_col := CollisionShape2D.new()
	var area_circle := CircleShape2D.new()
	area_circle.radius = col_radius + 14.0
	area_col.shape = area_circle
	interact_area.add_child(area_col)
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	add_child(interact_area)

	prompt_label = Label.new()
	prompt_label.visible = false
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-70, -42)
	prompt_label.custom_minimum_size = Vector2(140, 20)
	prompt_label.add_theme_font_size_override("font_size", 10)
	prompt_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.65))
	prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt_label.add_theme_constant_override("outline_size", 3)
	_update_prompt_text()
	add_child(prompt_label)

	_check_saved_state()

func _update_prompt_text() -> void:
	if not prompt_label:
		return
	match harvest_type:
		HarvestType.FORAGE:
			prompt_label.text = "[E] Recoger %s" % node_title
		HarvestType.LOGGING:
			prompt_label.text = "%s ([3] Hacha)" % node_title
		HarvestType.MINING:
			prompt_label.text = "%s ([4] Pico)" % node_title

func _on_body_entered(body: Node) -> void:
	if not is_depleted and body.is_in_group("player") and prompt_label:
		prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and prompt_label:
		prompt_label.visible = false

## Interacción con [E] para nodos de Forrajeo (Hierbas y Hongos)
func interact(player: Node) -> void:
	if is_depleted or harvest_type != HarvestType.FORAGE:
		return
	var yield_amt: int = primary_amount if animal_bites_left >= max_animal_bites else maxi(1, primary_amount - 1)
	_give_drop(player, primary_item_id, yield_amt)
	if bonus_item_id != "" and bonus_amount > 0:
		_give_drop(player, bonus_item_id, bonus_amount, -54.0)
	_deplete_node()

## Permite que los herbívoros del ecosistema coman hasta 2 brotes de esta planta antes de agotarla
func consume_by_animal() -> bool:
	if is_depleted or harvest_type != HarvestType.FORAGE:
		return false
	animal_bites_left -= 1
	_play_shake(false)
	if animal_bites_left <= 0:
		_deplete_node()
	elif sprite:
		sprite.scale = _active_scale * 0.78
	return true

## Golpe de arma/herramienta para Tala (LOGGING) y Minería (MINING)
func take_damage(data: DamageData) -> void:
	if is_depleted or harvest_type == HarvestType.FORAGE:
		return

	var player = get_tree().get_first_node_in_group("player")
	var effective := false
	var tool_efficiency: float = 0.35

	if harvest_type == HarvestType.LOGGING:
		effective = (data.type == CombatConstants.DamageType.CUT)
		tool_efficiency = data.logging_efficiency
		if not effective and player and player.has_method("show_hint"):
			player.show_hint("Necesitas filo ([3] Hacha o [1] Espada) para talar árboles.")
		elif effective and tool_efficiency < 1.0 and player and player.has_method("show_hint"):
			player.show_hint("La Espada es poco eficiente talando (35%). Usa [3] Hacha para talar rápido.")
	elif harvest_type == HarvestType.MINING:
		effective = (data.type == CombatConstants.DamageType.BLUNT)
		tool_efficiency = data.mining_efficiency
		if not effective and player and player.has_method("show_hint"):
			player.show_hint("Necesitas impacto ([4] Pico o [2] Martillo) para picar la veta.")
		elif effective and tool_efficiency < 1.0 and player and player.has_method("show_hint"):
			player.show_hint("El Martillo es poco eficiente minando (35%). Usa [4] Pico para extraer mineral rápido.")

	if not effective:
		if AudioManager:
			AudioManager.emit_noise(global_position, 110.0)
		_play_shake(true)
		return

	current_hp -= data.amount * tool_efficiency
	if AudioManager:
		AudioManager.emit_noise(global_position, 130.0)
	_play_shake(false)

	# Solo la herramienta especializada (Hacha/Pico con eficiencia >= 1.0) da material extra en cada golpe
	if tool_efficiency >= 1.0:
		_give_drop(player, primary_item_id, 1)

	if current_hp <= 0.0:
		# Al derribar el árbol o romper la veta: la herramienta adecuada rinde el total, la improvisada la mitad
		var final_yield: int = primary_amount if tool_efficiency >= 1.0 else max(1, int(primary_amount / 2))
		_give_drop(player, primary_item_id, final_yield, -44.0)
		if bonus_item_id != "" and bonus_amount > 0 and tool_efficiency >= 1.0:
			_give_drop(player, bonus_item_id, bonus_amount, -58.0)
		if AudioManager:
			AudioManager.emit_noise(global_position, 200.0)
		_deplete_node()

func _give_drop(player: Node, item_id: String, amount: int, offset_y: float = -36.0) -> void:
	if not player or item_id == "" or amount <= 0:
		return
	if "inventory" in player and player.inventory:
		player.inventory.add_item(item_id, amount)
		if player.has_method("_spawn_floating_text"):
			var item_name: String = player.inventory.get_item_name(item_id)
			player._spawn_floating_text("+%d %s" % [amount, item_name], Color.SPRING_GREEN, offset_y)

func _play_shake(deflected: bool) -> void:
	if not sprite:
		return
	var tween := create_tween()
	if not deflected:
		tween.tween_property(sprite, "modulate", Color(2.5, 2.5, 2.5), 0.05)
		tween.tween_property(sprite, "modulate", _active_modulate, 0.05)
	tween.tween_property(sprite, "position:x", 3.0, 0.04).as_relative()
	tween.tween_property(sprite, "position:x", -3.0, 0.04).as_relative()

func _deplete_node() -> void:
	is_depleted = true
	var cur_day: int = WorldClock.current_day if WorldClock else 1
	respawn_on_day = cur_day + max(1, respawn_days)
	if GameManager and persistence_id != "":
		GameManager.set_flag(persistence_id, respawn_on_day)
	_apply_depleted_visuals()

func _apply_depleted_visuals() -> void:
	if prompt_label:
		prompt_label.visible = false
	if body_collision:
		body_collision.set_deferred("disabled", true)
	if sprite:
		if _depleted_texture:
			sprite.texture = _depleted_texture
			sprite.position = Vector2.ZERO
			sprite.scale = _active_scale * 0.85
			sprite.modulate = Color(0.75, 0.75, 0.75, 0.9)
		else:
			sprite.visible = false

func _regrow_node() -> void:
	is_depleted = false
	respawn_on_day = -1
	current_hp = max_hp
	animal_bites_left = max_animal_bites
	if GameManager and persistence_id != "":
		GameManager.set_flag(persistence_id, -1)
	if body_collision and harvest_type != HarvestType.FORAGE:
		body_collision.set_deferred("disabled", false)
	if sprite:
		sprite.visible = true
		sprite.texture = _active_texture
		sprite.modulate = _active_modulate
		sprite.scale = _active_scale
		sprite.position = Vector2(0, -12) if harvest_type == HarvestType.LOGGING else Vector2.ZERO

func _on_day_passed(new_day: int) -> void:
	if is_depleted and respawn_on_day > 0 and new_day >= respawn_on_day:
		_regrow_node()

func _on_game_loaded(_filepath: String) -> void:
	_check_saved_state()

func _check_saved_state() -> void:
	if not GameManager or persistence_id == "":
		return
	var saved_val: Variant = GameManager.get_flag(persistence_id, -1)
	var saved_day: int = int(saved_val) if typeof(saved_val) in [TYPE_INT, TYPE_FLOAT] else -1
	var cur_day: int = WorldClock.current_day if WorldClock else 1
	if saved_day > cur_day:
		is_depleted = true
		respawn_on_day = saved_day
		_apply_depleted_visuals()
	else:
		if is_depleted:
			_regrow_node()
