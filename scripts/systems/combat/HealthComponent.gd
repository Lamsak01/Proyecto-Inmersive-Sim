extends Node
class_name HealthComponent

signal died
signal health_changed(current, max)
signal blood_changed(current, max)
signal weakness_changed(is_weak)

@export var max_health: float = 100.0
@export var max_blood: float = 100.0

var current_health: float
var current_blood: float
var is_weak: bool = false

func _ready() -> void:
	current_health = max_health
	current_blood = max_blood

func take_damage(data: DamageData) -> void:
	# Apply Direct Health Damage
	current_health -= data.amount
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()
	
	# Apply Bleed Logic
	if data.bleed_chance > 0.0:
		var bleed_amount = data.amount * 0.2
		modify_blood(-bleed_amount)

func heal(amount: float) -> void:
	current_health = clamp(current_health + amount, 0, max_health)
	health_changed.emit(current_health, max_health)

func modify_blood(amount: float) -> void:
	current_blood = clamp(current_blood + amount, 0, max_blood)
	blood_changed.emit(current_blood, max_blood)
	
	var blood_percent = current_blood / max_blood
	var weak_state = blood_percent < 0.3
	
	if weak_state != is_weak:
		is_weak = weak_state
		weakness_changed.emit(is_weak)
