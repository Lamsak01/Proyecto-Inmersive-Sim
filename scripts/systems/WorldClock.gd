extends Node

## Sistema global de Reloj del Mundo (WorldClock) — Fase 2.1
## Gestiona el paso de minutos, horas, fases del día y días completos.
## Provee iluminación ambiental (CanvasModulate) y multiplicador de visión nocturna para el sigilo.

signal time_updated(day: int, hour: int, minute: int)
signal hour_passed(day: int, hour: int)
signal phase_changed(new_phase: DayPhase, phase_name: String)
signal day_passed(new_day: int)

enum DayPhase {
	EARLY_MORNING, # 05:00 - 05:59 (Madrugada)
	MORNING,       # 06:00 - 11:59 (Mañana)
	AFTERNOON,     # 12:00 - 17:59 (Tarde)
	DUSK,          # 18:00 - 20:59 (Atardecer)
	NIGHT          # 21:00 - 04:59 (Noche)
}

@export var real_seconds_per_game_hour: float = 30.0 ## 30s reales = 1 hora de juego (12 min por día completo)
@export var allow_debug_time_skip: bool = true       ## Tecla [T] avanza +2 horas para probar ciclos

var current_day: int = 1
var current_hour: int = 8
var current_minute: int = 0
var is_paused: bool = false

var _accumulated_seconds: float = 0.0
var _current_phase: DayPhase = DayPhase.MORNING

func _ready() -> void:
	_current_phase = get_day_phase(current_hour)

func _process(delta: float) -> void:
	if is_paused:
		return

	var seconds_per_minute: float = real_seconds_per_game_hour / 60.0
	_accumulated_seconds += delta

	while _accumulated_seconds >= seconds_per_minute:
		_accumulated_seconds -= seconds_per_minute
		_advance_one_minute()

func _unhandled_input(event: InputEvent) -> void:
	if not allow_debug_time_skip:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			advance_hours(2)

func _advance_one_minute() -> void:
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		if current_hour >= 24:
			current_hour = 0
			current_day += 1
			day_passed.emit(current_day)

		hour_passed.emit(current_day, current_hour)

		var new_phase := get_day_phase(current_hour)
		if new_phase != _current_phase:
			_current_phase = new_phase
			phase_changed.emit(_current_phase, get_phase_name(_current_phase))

	time_updated.emit(current_day, current_hour, current_minute)

## Avanza varias horas de golpe (útil para dormir o para pruebas con [T])
func advance_hours(hours: int) -> void:
	if hours <= 0:
		return
	var total_minutes := hours * 60
	for i in range(total_minutes):
		_advance_one_minute()

## Duerme hasta las 06:00 AM del siguiente amanecer
func sleep_until_morning() -> void:
	current_day += 1
	current_hour = 6
	current_minute = 0
	_accumulated_seconds = 0.0
	_current_phase = get_day_phase(current_hour)
	day_passed.emit(current_day)
	hour_passed.emit(current_day, current_hour)
	phase_changed.emit(_current_phase, get_phase_name(_current_phase))
	time_updated.emit(current_day, current_hour, current_minute)

func get_day_phase(hour: int = current_hour) -> DayPhase:
	if hour >= 5 and hour < 6:
		return DayPhase.EARLY_MORNING
	elif hour >= 6 and hour < 12:
		return DayPhase.MORNING
	elif hour >= 12 and hour < 18:
		return DayPhase.AFTERNOON
	elif hour >= 18 and hour < 21:
		return DayPhase.DUSK
	else:
		return DayPhase.NIGHT

func get_phase_name(phase: DayPhase = _current_phase) -> String:
	match phase:
		DayPhase.EARLY_MORNING:
			return "Madrugada"
		DayPhase.MORNING:
			return "Mañana"
		DayPhase.AFTERNOON:
			return "Tarde"
		DayPhase.DUSK:
			return "Atardecer"
		DayPhase.NIGHT:
			return "Noche"
	return "Día"

func get_phase_icon(phase: DayPhase = _current_phase) -> String:
	match phase:
		DayPhase.EARLY_MORNING:
			return "🌅"
		DayPhase.MORNING:
			return "☀"
		DayPhase.AFTERNOON:
			return "☀"
		DayPhase.DUSK:
			return "🌇"
		DayPhase.NIGHT:
			return "🌙"
	return "☀"

func get_formatted_time() -> String:
	return "Día %d | %02d:%02d (%s)" % [current_day, current_hour, current_minute, get_phase_name(_current_phase)]

## Multiplicador sistémico de visión según la luz del día (1.0 de día, 0.6 de noche)
func get_vision_multiplier() -> float:
	var exact_hour: float = float(current_hour) + float(current_minute) / 60.0
	if exact_hour >= 7.0 and exact_hour < 18.0:
		return 1.0
	elif exact_hour >= 18.0 and exact_hour < 21.0:
		# Transición suave de 1.0 a 0.6 durante el atardecer
		var t: float = (exact_hour - 18.0) / 3.0
		return lerpf(1.0, 0.6, t)
	elif exact_hour >= 21.0 or exact_hour < 5.0:
		return 0.6
	else:
		# Transición suave de 0.6 a 1.0 entre las 05:00 y las 07:00
		var t: float = (exact_hour - 5.0) / 2.0
		return lerpf(0.6, 1.0, t)

## Color ambiental interpolado suavemente según la hora exacta del día
func get_ambient_color() -> Color:
	var exact_hour: float = float(current_hour) + float(current_minute) / 60.0
	
	var color_night := Color(0.32, 0.36, 0.56, 1.0)
	var color_dawn := Color(0.85, 0.72, 0.68, 1.0)
	var color_day := Color(1.0, 1.0, 1.0, 1.0)
	var color_dusk := Color(0.92, 0.68, 0.55, 1.0)

	if exact_hour >= 0.0 and exact_hour < 5.0:
		return color_night
	elif exact_hour >= 5.0 and exact_hour < 7.0:
		return color_night.lerp(color_dawn, (exact_hour - 5.0) / 2.0)
	elif exact_hour >= 7.0 and exact_hour < 9.0:
		return color_dawn.lerp(color_day, (exact_hour - 7.0) / 2.0)
	elif exact_hour >= 9.0 and exact_hour < 17.5:
		return color_day
	elif exact_hour >= 17.5 and exact_hour < 19.5:
		return color_day.lerp(color_dusk, (exact_hour - 17.5) / 2.0)
	elif exact_hour >= 19.5 and exact_hour < 21.5:
		return color_dusk.lerp(color_night, (exact_hour - 19.5) / 2.0)
	else:
		return color_night

## Serialización limpia lista para el Sistema de Guardado (Paso 2.2)
func to_dict() -> Dictionary:
	return {
		"day": current_day,
		"hour": current_hour,
		"minute": current_minute
	}

func from_dict(data: Dictionary) -> void:
	current_day = int(data.get("day", 1))
	current_hour = clampi(int(data.get("hour", 8)), 0, 23)
	current_minute = clampi(int(data.get("minute", 0)), 0, 59)
	_current_phase = get_day_phase(current_hour)
	time_updated.emit(current_day, current_hour, current_minute)
	phase_changed.emit(_current_phase, get_phase_name(_current_phase))
