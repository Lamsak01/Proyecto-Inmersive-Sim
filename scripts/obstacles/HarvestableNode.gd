@tool
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

var body_collision: CollisionShape2D = null
var interact_area: Area2D = null

func _ready() -> void:
	if persistence_id == "":
		persistence_id = "harvest_" + name + "_" + str(int(global_position.x)) + "_" + str(int(global_position.y))

	current_hp = max_hp
	animal_bites_left = max_animal_bites
	if harvest_type != HarvestType.FORAGE:
		add_to_group("destructible")
	else:
		add_to_group("wild_flora")

	if not Engine.is_editor_hint():
		if WorldClock:
			WorldClock.day_passed.connect(_on_day_passed)
		if GameManager:
			GameManager.game_loaded.connect(_on_game_loaded)
		_check_saved_state()

## Solo el choque y la zona de recoger (2026-11-12): el dibujo plano se quitó; el árbol, la roca o la planta en 3D los
## pone el escenario 3D (WorldStageTerrain3D) a partir de este nodo, su tipo y si está agotado.
func setup_collision(col_radius: float) -> void:
	# Colisión física para Árboles y Vetas de Roca
	body_collision = CollisionShape2D.new()
	body_collision.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = col_radius
	body_collision.shape = circle
	body_collision.disabled = (harvest_type == HarvestType.FORAGE)
	add_child(body_collision)

	# Área de Interacción / Etiqueta de ayuda
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
	add_child(interact_area)

	if not Engine.is_editor_hint():
		_check_saved_state()


## Interacción con [E] para nodos de Forrajeo (Hierbas y Hongos)
func interact(player: Node) -> void:
	if is_depleted or harvest_type != HarvestType.FORAGE:
		return
	var yield_amt: int = primary_amount if animal_bites_left >= max_animal_bites else maxi(1, primary_amount - 1)
	_give_drop(player, primary_item_id, yield_amt)
	if bonus_item_id != "" and bonus_amount > 0:
		_give_drop(player, bonus_item_id, bonus_amount, -54.0)
	_deplete_node()

## Permite que la Herborista (`HERBALIST`) coseche físicamente la planta durante su expedición matutina, dejando 1 planta menos hoy
func harvest_by_npc(_npc: Node = null) -> bool:
	if is_depleted or harvest_type != HarvestType.FORAGE:
		return false
	_deplete_node()
	return true

## Permite que los herbívoros del ecosistema coman hasta 2 brotes de esta planta antes de agotarla
func consume_by_animal() -> bool:
	if is_depleted or harvest_type != HarvestType.FORAGE:
		return false
	animal_bites_left -= 1
	if animal_bites_left <= 0:
		_deplete_node()
	return true

## Golpe de arma/herramienta para Tala (LOGGING) y Minería (MINING)
func take_damage(data: DamageData) -> void:
	if is_depleted or harvest_type == HarvestType.FORAGE:
		return

	var is_npc_harvester: bool = (data != null and is_instance_valid(data.source) and data.source.is_in_group("village_npcs"))
	var player = null if is_npc_harvester else get_tree().get_first_node_in_group("player")
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
		return

	current_hp -= data.amount * tool_efficiency
	if AudioManager:
		AudioManager.emit_noise(global_position, 130.0)

	# Solo la herramienta especializada (Hacha/Pico con eficiencia >= 1.0) da material extra en cada golpe
	if tool_efficiency >= 1.0:
		var hit_drop: int = 1
		if tool_efficiency >= 3.2:
			hit_drop = 3
		elif tool_efficiency >= 2.2:
			hit_drop = 2
		_give_drop(player, primary_item_id, hit_drop)

	if current_hp <= 0.0:
		# Al derribar el árbol o romper la veta: la herramienta adecuada rinde el total (+bono por tier), la improvisada la mitad
		var tier_bonus: int = 2 if tool_efficiency >= 3.2 else (1 if tool_efficiency >= 2.2 else 0)
		var final_yield: int = (primary_amount + tier_bonus) if tool_efficiency >= 1.0 else maxi(1, int(float(primary_amount) * 0.5))
		_give_drop(player, primary_item_id, final_yield, -44.0)
		if bonus_item_id != "" and bonus_amount > 0 and tool_efficiency >= 1.0:
			_give_drop(player, bonus_item_id, bonus_amount + (1 if tool_efficiency >= 2.2 else 0), -58.0)
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

func _deplete_node() -> void:
	is_depleted = true
	var cur_day: int = WorldClock.current_day if WorldClock else 1
	respawn_on_day = cur_day + max(1, respawn_days)
	if GameManager and persistence_id != "":
		GameManager.set_flag(persistence_id, respawn_on_day)
	_apply_depleted_visuals()

func _set_harvest_cols_disabled(dis: bool) -> void:
	if body_collision and (dis or harvest_type != HarvestType.FORAGE):
		body_collision.set_deferred("disabled", dis)
	if interact_area and interact_area.get_child_count() > 0:
		var icol := interact_area.get_child(0) as CollisionShape2D
		if icol: icol.set_deferred("disabled", dis)

func _apply_depleted_visuals() -> void:
	_set_harvest_cols_disabled(true)

func _regrow_node() -> void:
	is_depleted = false
	respawn_on_day = -1
	current_hp = max_hp
	animal_bites_left = max_animal_bites
	if GameManager and persistence_id != "":
		GameManager.set_flag(persistence_id, -1)
	_set_harvest_cols_disabled(false)

func _on_day_passed(new_day: int) -> void:
	if is_depleted and respawn_on_day > 0 and new_day >= respawn_on_day:
		_regrow_node()
	elif not is_depleted:
		current_hp = max_hp
		if harvest_type == HarvestType.FORAGE and animal_bites_left < max_animal_bites:
			animal_bites_left = max_animal_bites

func _on_game_loaded(_filepath: String) -> void:
	if not Engine.is_editor_hint():
		_check_saved_state()

func _check_saved_state() -> void:
	if Engine.is_editor_hint() or not GameManager or persistence_id == "":
		return
	var saved_val: Variant = GameManager.get_flag(persistence_id, -1)
	var saved_day: int = int(saved_val) if typeof(saved_val) in [TYPE_INT, TYPE_FLOAT] else -1
	var cur_day: int = WorldClock.current_day if WorldClock else 1
	if saved_day > cur_day:
		is_depleted = true
		respawn_on_day = saved_day
		_apply_depleted_visuals()
	else:
		if is_depleted or current_hp < max_hp or animal_bites_left < max_animal_bites:
			_regrow_node()
