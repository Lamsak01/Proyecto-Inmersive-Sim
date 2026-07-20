class_name Hitbox
extends Area2D

@export var damage_data: DamageData


func apply_damage(hurtbox: Hurtbox) -> void:
    if damage_data != null and hurtbox != null:
        hurtbox.receive_damage(damage_data)
