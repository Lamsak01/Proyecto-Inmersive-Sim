extends StaticBody2D
class_name DestructibleObject

enum Vulnerability {
	ANY,
	CUT_ONLY,
	BLUNT_ONLY,
	EXPLOSIVE_ONLY
}

@export var vulnerability: Vulnerability = Vulnerability.ANY
@export var debris_texture: Texture2D # Texture for particles when destroyed (optional)
@export var visual_node: Node2D
@export var root_to_free: Node

@export var persistence_id: String = ""

# We use the standard HealthComponent to track HP
@onready var health_comp: HealthComponent = $HealthComponent
var _base_modulate: Color = Color.WHITE
var _last_damaged_by_player: bool = false

func _ready() -> void:
	if persistence_id == "":
		persistence_id = "destructible_" + str(get_path())
	
	add_to_group("destructible")
	if health_comp:
		health_comp.died.connect(_on_died)
	
	# Default assignments if not set in editor
	if not visual_node and has_node("Sprite2D"):
		visual_node = $Sprite2D
	if visual_node:
		_base_modulate = visual_node.modulate
	if not root_to_free:
		root_to_free = self

	# Check persistence
	if GameManager.get_flag(persistence_id, false) == true:
		set_destroyed_state(true)

func take_damage(data: DamageData) -> void:
	# 1. Check vulnerabilities
	if not _is_damage_effective(data.type):
		if AudioManager:
			AudioManager.emit_noise(global_position, 110.0)
		if visual_node: _play_deflect_effect()
		return

	# 2. Apply damage
	_last_damaged_by_player = (data != null and is_instance_valid(data.source) and (data.source.is_in_group("player") or data.source.is_in_group("player_trap")))
	if health_comp:
		health_comp.take_damage(data)
		if health_comp.current_health > 0 and AudioManager:
			AudioManager.emit_noise(global_position, 100.0)
		if visual_node: _play_hit_effect()

func _is_damage_effective(type: int) -> bool:
	match vulnerability:
		Vulnerability.ANY:
			return true
		Vulnerability.CUT_ONLY:
			return type == CombatConstants.DamageType.CUT
		Vulnerability.BLUNT_ONLY:
			return type == CombatConstants.DamageType.BLUNT
		Vulnerability.EXPLOSIVE_ONLY:
			return type == CombatConstants.DamageType.THERMAL # Assuming Explosive maps to Thermal or separate type
	return false

func _play_hit_effect() -> void:
	# Visual feedback for taking damage (shake, flash, etc)
	var tween = create_tween()
	tween.tween_property(visual_node, "modulate", Color(3, 3, 3), 0.05) # Flash white
	tween.tween_property(visual_node, "modulate", _base_modulate, 0.05)

func _play_deflect_effect() -> void:
	# Visual feedback for ineffective hit (e.g., sparks, rigid shake)
	var tween = create_tween()
	tween.tween_property(visual_node, "position:x", 2, 0.05).as_relative()
	tween.tween_property(visual_node, "position:x", -2, 0.05).as_relative()

func _on_died() -> void:
	if AudioManager:
		AudioManager.emit_noise(global_position, 220.0)
	
	if persistence_id != "":
		GameManager.set_flag(persistence_id, true)

	# Entregar recursos al inventario del jugador solo si lo destruyó él o está cerca
	var player = get_tree().get_first_node_in_group("player")
	if player and "inventory" in player and player.inventory and (_last_damaged_by_player or global_position.distance_to(player.global_position) <= 180.0):
		var drop_id := "stone" if vulnerability == Vulnerability.BLUNT_ONLY else "wood"
		player.inventory.add_item(drop_id, 1)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("+1 %s" % player.inventory.get_item_name(drop_id), Color.WHEAT, -40.0)

	set_destroyed_state(true)

func set_destroyed_state(destroyed: bool) -> void:
	var target_root: Node = root_to_free if is_instance_valid(root_to_free) else self
	if target_root is CanvasItem:
		(target_root as CanvasItem).visible = not destroyed
	visible = not destroyed
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", destroyed)
		elif child is Area2D:
			var a := child as Area2D
			a.set_deferred("monitoring", not destroyed)
			a.set_deferred("monitorable", not destroyed)
			for sub in a.get_children():
				if sub is CollisionShape2D:
					(sub as CollisionShape2D).set_deferred("disabled", destroyed)
	if not destroyed:
		if visual_node:
			visual_node.modulate = _base_modulate
		if health_comp:
			health_comp.current_health = health_comp.max_health
