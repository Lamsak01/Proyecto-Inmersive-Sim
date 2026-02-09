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

# We use the standard HealthComponent to track HP
@onready var health_comp: HealthComponent = $HealthComponent

func _ready() -> void:
	add_to_group("destructible")
	if health_comp:
		health_comp.died.connect(_on_died)
	
	# Default assignments if not set in editor
	if not visual_node and has_node("Sprite2D"):
		visual_node = $Sprite2D
	if not root_to_free:
		root_to_free = self

func take_damage(data: DamageData) -> void:
	# 1. Check vulnerabilities
	if not _is_damage_effective(data.type):
		# Optional: Play "clink" or "thud" sound for ineffective hit
		if visual_node: _play_deflect_effect()
		return

	# 2. Apply damage
	if health_comp:
		health_comp.take_damage(data)
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
	tween.tween_property(visual_node, "modulate", Color.WHITE, 0.05)

func _play_deflect_effect() -> void:
	# Visual feedback for ineffective hit (e.g., sparks, rigid shake)
	var tween = create_tween()
	tween.tween_property(visual_node, "position:x", 2, 0.05).as_relative()
	tween.tween_property(visual_node, "position:x", -2, 0.05).as_relative()

func _on_died() -> void:
	print(name, " DESTROYED!")
	# Spawn debris/particles here if needed
	if root_to_free:
		root_to_free.queue_free()
	else:
		queue_free()
