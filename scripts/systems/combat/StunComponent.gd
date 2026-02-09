extends Node
class_name StunComponent

signal stunned(is_stunned)
signal stun_changed(current, max)

@export var max_stun: float = 100.0
@export var recovery_rate: float = 10.0

var current_stun: float = 0.0
var is_stunned: bool = false

func _process(delta: float) -> void:
	if current_stun > 0:
		current_stun = max(0, current_stun - recovery_rate * delta)
		stun_changed.emit(current_stun, max_stun)
		
		if is_stunned and current_stun <= 0:
			is_stunned = false
			stunned.emit(false)

func take_damage(data: DamageData) -> void:
	if data.type == CombatConstants.DamageType.BLUNT:
		add_stun(data.amount * 2.0)
	elif data.type == CombatConstants.DamageType.ELECTRIC:
		add_stun(data.amount * 0.5)

func add_stun(amount: float) -> void:
	current_stun = min(current_stun + amount, max_stun)
	stun_changed.emit(current_stun, max_stun)
	
	if current_stun >= max_stun and not is_stunned:
		is_stunned = true
		stunned.emit(true)
