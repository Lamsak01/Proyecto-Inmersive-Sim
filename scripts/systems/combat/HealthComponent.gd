extends Node
class_name HealthComponent

signal died
signal health_changed(current, max)
signal blood_changed(current, max)
signal weakness_changed(is_weak)
signal bleed_triggered(dps_amount)

@export var max_health: float = 100.0
@export var max_blood: float = 100.0 ## Umbral máximo de acumulación para activar el sangrado
@export var bleed_decay_rate: float = 8.0 ## Qué tan rápido baja la acumulación si no estás sangrando
@export var bleed_duration: float = 5.0 ## Duración en segundos del desangrado activo
@export var bleed_damage_multiplier: float = 0.4 ## Daño por segundo de sangrado como proporción del daño del arma

var current_health: float
var current_blood: float = 0.0 ## Acumulación actual de sangrado (0 a max_blood)
var is_bleeding: bool = false
var is_weak: bool = false

var _bleed_timer: float = 0.0
var _bleed_dps: float = 0.0

func _ready() -> void:
	current_health = max_health
	current_blood = 0.0

func _process(delta: float) -> void:
	if current_health <= 0.0:
		return

	if is_bleeding:
		_bleed_timer -= delta
		# Perder vida poco a poco dependiendo del daño del arma que causó el sangrado
		current_health = max(0.0, current_health - _bleed_dps * delta)
		health_changed.emit(current_health, max_health)

		# Reflejar el tiempo restante de sangrado en la barra
		current_blood = clamp((_bleed_timer / bleed_duration) * max_blood, 0.0, max_blood)
		blood_changed.emit(current_blood, max_blood)

		if current_health <= 0.0:
			is_bleeding = false
			died.emit()
			return

		if _bleed_timer <= 0.0:
			is_bleeding = false
			current_blood = 0.0
			_bleed_dps = 0.0
			blood_changed.emit(current_blood, max_blood)
			if is_weak:
				is_weak = false
				weakness_changed.emit(false)
	elif current_blood > 0.0:
		# Si no llegó al máximo, la acumulación baja poco a poco con el tiempo
		current_blood = max(0.0, current_blood - bleed_decay_rate * delta)
		blood_changed.emit(current_blood, max_blood)

func take_damage(data: DamageData) -> void:
	if current_health <= 0.0:
		return

	# 1. Aplicar daño directo a la vida
	current_health = max(0.0, current_health - data.amount)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0.0:
		is_bleeding = false
		died.emit()
		return
	
	# 2. Acumular sangrado según la estadística del arma
	var buildup: float = data.bleed_buildup
	if buildup <= 0.0 and data.type == CombatConstants.DamageType.CUT and data.bleed_chance > 0.0:
		buildup = data.amount * 3.0

	if buildup > 0.0:
		add_bleed_buildup(buildup, data.amount)

func add_bleed_buildup(buildup_amount: float, weapon_damage: float) -> void:
	var weapon_bleed_dps = max(1.5, weapon_damage * bleed_damage_multiplier)

	if is_bleeding:
		# Si ya está sangrando, refresca parcialmente el sangrado y mantiene el mayor DPS
		_bleed_dps = max(_bleed_dps, weapon_bleed_dps)
		_bleed_timer = min(bleed_duration, _bleed_timer + bleed_duration * 0.35)
		return

	current_blood = min(max_blood, current_blood + buildup_amount)
	blood_changed.emit(current_blood, max_blood)

	if current_blood >= max_blood:
		# Se llenó la barra: activar estado de sangrado
		is_bleeding = true
		_bleed_timer = bleed_duration
		_bleed_dps = weapon_bleed_dps
		if not is_weak:
			is_weak = true
			weakness_changed.emit(true)
		bleed_triggered.emit(_bleed_dps)

func heal(amount: float) -> void:
	current_health = clamp(current_health + amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)

func modify_blood(amount: float) -> void:
	if amount > 0.0:
		current_blood = max(0.0, current_blood - amount)
	else:
		add_bleed_buildup(-amount, 10.0)
	blood_changed.emit(current_blood, max_blood)
