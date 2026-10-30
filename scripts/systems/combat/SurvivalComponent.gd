extends Node
class_name SurvivalComponent

## Componente de Necesidades Básicas del Jugador (Hambre y Sueño/Descanso) — Fase 3.1
## - Hambre (100 = Saciado -> 0 = Hambriento): Se recupera comiendo verduras, pan, huevos o carne cocida.
## - Sueño (100 = Descansado -> 0 = Agotado): Se recupera sentándose junto a la hoguera o durmiendo hasta el amanecer.

signal hunger_changed(current: float, maximum: float)
signal sleep_changed(current: float, maximum: float)

@export var max_hunger: float = 100.0
@export var max_sleep: float = 100.0
@export var hunger_drain_per_sec: float = 0.20
@export var sleep_drain_per_sec: float = 0.16

var current_hunger: float = 100.0
var current_sleep: float = 100.0
var is_sitting_resting: bool = false

var _starve_tick: float = 0.0
var _ui_emit_tick: float = 0.0

func _ready() -> void:
	current_hunger = max_hunger
	current_sleep = max_sleep
	if Engine.is_editor_hint():
		set_process(false)
		return
	call_deferred("_emit_all")

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or (WorldClock and ((WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen()) or bool(WorldClock.get("is_fast_forwarding")))):
		return
	var prev_h := current_hunger
	var prev_s := current_sleep

	# Mientras estás sentado en el tronco junto al fuego (modo AFK/Descanso), las barras se gastan un 85% más lento
	var drain_mult: float = 0.15 if is_sitting_resting else 1.0
	current_hunger = maxf(0.0, current_hunger - (hunger_drain_per_sec * drain_mult) * delta)
	current_sleep = maxf(0.0, current_sleep - (sleep_drain_per_sec * drain_mult) * delta)

	_ui_emit_tick += delta
	if _ui_emit_tick >= 0.35 or absf(prev_h - current_hunger) > 1.0 or absf(prev_s - current_sleep) > 1.0:
		_ui_emit_tick = 0.0
		_emit_all()

	# Penalizaciones suaves si llegas a 0 de Hambre o 0 de Sueño
	var player := get_parent()
	if current_sleep <= 12.0 and player:
		var stam: StaminaComponent = player.get_node_or_null("StaminaComponent")
		if stam and stam.current_stamina > 55.0:
			stam.current_stamina = lerpf(stam.current_stamina, 55.0, delta * 2.0)
			stam.stamina_changed.emit(stam.current_stamina, stam.max_stamina)

	if current_hunger <= 0.0 and player:
		_starve_tick += delta
		if _starve_tick >= 2.5:
			_starve_tick = 0.0
			var h_comp: HealthComponent = player.get_node_or_null("HealthComponent")
			if h_comp and h_comp.current_health > 5.0:
				h_comp.current_health = maxf(5.0, h_comp.current_health - 1.5)
				h_comp.health_changed.emit(h_comp.current_health, h_comp.max_health)
				if player.has_method("_spawn_floating_text"):
					player._spawn_floating_text("¡Hambriento! (-HP)", Color.ORANGE_RED, -38.0)

func restore_hunger(amount: float) -> void:
	current_hunger = clampf(current_hunger + amount, 0.0, max_hunger)
	hunger_changed.emit(current_hunger, max_hunger)

func restore_sleep(amount: float) -> void:
	current_sleep = clampf(current_sleep + amount, 0.0, max_sleep)
	sleep_changed.emit(current_sleep, max_sleep)

func _emit_all() -> void:
	hunger_changed.emit(current_hunger, max_hunger)
	sleep_changed.emit(current_sleep, max_sleep)
