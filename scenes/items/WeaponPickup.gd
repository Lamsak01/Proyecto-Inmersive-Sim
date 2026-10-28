extends Area2D

@export var weapon_data: WeaponData
@export var weapon_name: String = "Sword"
var player_in_range: Node2D = null

func _ready() -> void:
	add_to_group("interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if weapon_data == null:
		if weapon_name == "Sword":
			weapon_data = load("res://resources/weapons/Sword.tres")
		elif weapon_name == "Hammer":
			weapon_data = load("res://resources/weapons/Hammer.tres")
	
	if weapon_data and weapon_data.icon and has_node("Sprite2D"):
		$Sprite2D.texture = weapon_data.icon

func interact(player: Node) -> void:
	_pickup(player)

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("Interact"):
		_pickup(player_in_range)
		get_viewport().set_input_as_handled()

func _pickup(player: Node) -> void:
	if not player:
		return
	if player.has_method("equip_weapon") and weapon_data != null:
		player.equip_weapon(weapon_data)
		if player.has_method("show_hint"):
			player.show_hint("Recogiste: " + weapon_data.name)
	
	if ObjectiveManager:
		var obj_id = weapon_data.name if weapon_data else weapon_name
		ObjectiveManager.progress_objective(1, obj_id, 1) # 1 = COLLECT
		if weapon_name == "Sword" or (weapon_data and weapon_data.name == "Sword"):
			ObjectiveManager.complete_objective("obj_find_sword")
			
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = body
		if body.has_method("show_hint"):
			body.show_hint("Presiona [E] para recoger " + weapon_name)

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
