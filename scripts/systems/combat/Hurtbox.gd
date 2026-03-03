class_name Hurtbox
extends Area2D

signal hit_received(damage_data: DamageData)

func _init() -> void:
    pass

func receive_damage(damage_data: DamageData) -> void:
    hit_received.emit(damage_data)
