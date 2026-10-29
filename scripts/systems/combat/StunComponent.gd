extends Node
class_name StunComponent

signal stunned(is_stunned)
signal stun_changed(current, max)

@export var max_stun: float = 100.0
@export var recovery_rate: float = 10.0 ## Qué tan rápido baja la acumulación antes de llegar al máximo
@export var stun_duration: float = 3.0 ## Segundos que dura el estuneo en combate al llegar al máximo

var current_stun: float = 0.0
var is_stunned: bool = false
var armor_stun_resistance: float = 0.0 ## Reducción de acumulación de stun por casco/armadura (0.0 a 0.80)
var _stun_timer: float = 0.0
var _active_duration: float = 3.0

func _process(delta: float) -> void:
	if is_stunned:
		_stun_timer -= delta
		current_stun = clamp((_stun_timer / max(0.01, _active_duration)) * max_stun, 0.0, max_stun)
		stun_changed.emit(current_stun, max_stun)

		if _stun_timer <= 0.0:
			is_stunned = false
			current_stun = 0.0
			stun_changed.emit(current_stun, max_stun)
			stunned.emit(false)
	elif current_stun > 0.0:
		current_stun = max(0.0, current_stun - recovery_rate * delta)
		stun_changed.emit(current_stun, max_stun)

func take_damage(data: DamageData) -> void:
	# Mientras ya está estuneado no re-acumula para evitar stunlock infinito
	if is_stunned:
		return

	var buildup: float = data.stun_buildup
	if buildup <= 0.0:
		if data.type == CombatConstants.DamageType.BLUNT:
			buildup = data.amount * 2.5
		elif data.type == CombatConstants.DamageType.ELECTRIC:
			buildup = data.amount * 1.0

	buildup *= clampf(1.0 - armor_stun_resistance, 0.15, 1.0)
	if buildup > 0.0:
		add_stun(buildup)

func add_stun(amount: float) -> void:
	if is_stunned:
		return

	current_stun = min(current_stun + amount, max_stun)
	stun_changed.emit(current_stun, max_stun)
	
	if current_stun >= max_stun:
		apply_knockout(stun_duration)

func apply_knockout(duration: float) -> void:
	"""Fuerza el estado de Stun / KO durante 'duration' segundos (ej. Takedown de sigilo o barra llena)."""
	is_stunned = true
	_active_duration = duration
	_stun_timer = duration
	current_stun = max_stun
	stun_changed.emit(current_stun, max_stun)
	stunned.emit(true)
