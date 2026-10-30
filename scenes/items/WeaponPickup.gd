extends Area2D

@export var weapon_data: WeaponData
@export var weapon_name: String = "Sword"
var player_in_range: Node2D = null

var _is_picked_up: bool = false

func _ready() -> void:
	add_to_group("interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if GameManager and not GameManager.game_loaded.is_connected(_on_game_loaded):
		GameManager.game_loaded.connect(_on_game_loaded)

	if weapon_data == null:
		if weapon_name == "Sword":
			weapon_data = load("res://resources/weapons/Sword.tres")
		elif weapon_name == "Hammer":
			weapon_data = load("res://resources/weapons/Hammer.tres")

	if weapon_data and weapon_data.icon and has_node("Sprite2D"):
		$Sprite2D.texture = weapon_data.icon

	var flag_key := "weapon_pickup_" + str(name)
	if GameManager and bool(GameManager.get_flag(flag_key, false)):
		_set_picked_state(true)

func _on_game_loaded(_filepath: String) -> void:
	var flag_key := "weapon_pickup_" + str(name)
	var picked := GameManager != null and bool(GameManager.get_flag(flag_key, false))
	_set_picked_state(picked)

func _set_picked_state(picked: bool) -> void:
	_is_picked_up = picked
	visible = not picked
	set_deferred("monitoring", not picked)
	set_deferred("monitorable", not picked)
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", picked)
	if picked:
		player_in_range = null
		remove_from_group("interactable")
	else:
		if not is_in_group("interactable"):
			add_to_group("interactable")

func interact(player: Node) -> void:
	if _is_picked_up:
		return
	_pickup(player)

func _unhandled_input(event: InputEvent) -> void:
	if _is_picked_up or not is_instance_valid(player_in_range):
		return
	if (player_in_range.has_method("is_stunned") and player_in_range.is_stunned()) or (player_in_range.has_method("is_any_ui_modal_open") and bool(player_in_range.call("is_any_ui_modal_open"))):
		return
	if event.is_action_pressed("Interact"):
		_pickup(player_in_range)
		get_viewport().set_input_as_handled()

func _pickup(player: Node) -> void:
	if not player or _is_picked_up:
		return
	if GameManager:
		GameManager.set_flag("weapon_pickup_" + str(name), true)
	if player.has_method("equip_weapon") and weapon_data != null:
		player.equip_weapon(weapon_data)
		if player.has_method("show_hint"):
			player.show_hint("Recogiste: " + weapon_data.name)

	if ObjectiveManager:
		var obj_id = weapon_data.name if weapon_data else weapon_name
		ObjectiveManager.progress_objective(1, obj_id, 1) # 1 = COLLECT
		if weapon_name == "Sword" or (weapon_data and weapon_data.name == "Sword"):
			ObjectiveManager.complete_objective("obj_find_sword")

	_set_picked_state(true)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = body
		if body.has_method("show_hint"):
			body.show_hint("Presiona [E] para recoger " + weapon_name)

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
