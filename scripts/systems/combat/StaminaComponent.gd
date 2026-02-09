extends Node
class_name StaminaComponent

signal stamina_changed(current, max)
signal exhausted # Emitted when stamina reaches 0

@export var max_stamina: float = 100.0
@export var regen_rate: float = 30.0 # Doubled from 15.0
@export var sprint_cost: float = 20.0 # Per second
@export var attack_cost: float = 15.0 # Per attack

var current_stamina: float
var regen_cooldown: float = 0.0 # Time until regen can start
var is_input_blocking: bool = false

func _ready() -> void:
	current_stamina = max_stamina

func _process(delta: float) -> void:
	if regen_cooldown > 0:
		regen_cooldown -= delta
	
	if regen_cooldown <= 0 and not is_input_blocking and current_stamina < max_stamina:
		current_stamina = min(current_stamina + regen_rate * delta, max_stamina)
		stamina_changed.emit(current_stamina, max_stamina)

func use_stamina(amount: float) -> bool:
	if current_stamina > 0:
		current_stamina -= amount
		if current_stamina < 0:
			current_stamina = 0
		
		stamina_changed.emit(current_stamina, max_stamina)
		
		# Set cooldown
		if current_stamina == 0:
			regen_cooldown = 3.0 # Exhaustion penalty
			exhausted.emit()
		else:
			regen_cooldown = 1.0 # Normal delay
			
		return true
	return false

func get_stamina_ratio() -> float:
	return current_stamina / max_stamina
