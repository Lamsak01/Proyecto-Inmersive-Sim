class_name Hitbox
extends Area2D

@export var damage_data: DamageData

func _init() -> void:
    # Set default collision layer/mask if needed, usually Hitbox is on a specific layer
    # For now, we rely on the editor settings or set them dynamically.
    pass

func apply_damage(hurtbox: Hurtbox) -> void:
    if damage_data != null and hurtbox != null:
        hurtbox.receive_damage(damage_data)
