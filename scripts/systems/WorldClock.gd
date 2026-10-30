extends Node

## Sistema global de Reloj del Mundo (WorldClock) — Fase 2.1
## Gestiona el paso de minutos, horas, fases del día y días completos.
## Provee iluminación ambiental (CanvasModulate) y multiplicador de visión nocturna para el sigilo.

signal time_updated(day: int, hour: int, minute: int)
signal hour_passed(day: int, hour: int)
signal phase_changed(new_phase: DayPhase, phase_name: String)
signal day_passed(new_day: int)
signal weather_changed(new_weather: WeatherType, weather_name: String)

enum DayPhase {
	EARLY_MORNING, # 05:00 - 05:59 (Madrugada)
	MORNING,       # 06:00 - 11:59 (Mañana)
	AFTERNOON,     # 12:00 - 17:59 (Tarde)
	DUSK,          # 18:00 - 20:59 (Atardecer)
	NIGHT          # 21:00 - 04:59 (Noche)
}

enum WeatherType {
	CLEAR, # ☀️ Despejado
	RAIN,  # 🌧️ Lluvia del Valle (riega el huerto automáticamente y amortigua pasos un 35%)
	FOG    # 🌫️ Niebla Densa (reduce el rango visual de NPCs, guardias y fauna un 35%)
}

@export var real_seconds_per_game_hour: float = 15.0 ## 15s reales = 1 hora de juego (6 min por día completo, ritmo ágil)
@export var allow_debug_time_skip: bool = true       ## Tecla [T] avanza +2 horas para probar ciclos

var current_day: int = 1
var current_hour: int = 8
var current_minute: int = 0
var current_weather: WeatherType = WeatherType.CLEAR
var is_paused: bool = false
var is_paused_by_activity: bool = false

var _accumulated_seconds: float = 0.0
var _current_phase: DayPhase = DayPhase.MORNING

# Simulación Orgánica Acelerada (inspirado en RimWorld / Kenshi / The Sims: sin time-skips bruscos)
var is_fast_forwarding: bool = false
var fast_forward_target_hour: int = 6
var fast_forward_speed: float = 26.0
var _fast_forward_elapsed_minutes: int = 0
var _fast_forward_target_minutes: int = 0
var _on_fast_forward_complete: Callable = Callable()

func _ready() -> void:
	_current_phase = get_day_phase(current_hour)

func set_activity_pause(paused: bool) -> void:
	is_paused_by_activity = paused
	time_updated.emit(current_day, current_hour, current_minute)

func is_time_frozen() -> bool:
	return is_paused or is_paused_by_activity

func _process(delta: float) -> void:
	if is_paused or is_paused_by_activity:
		return

	var seconds_per_minute: float = real_seconds_per_game_hour / 60.0
	_accumulated_seconds += delta

	while _accumulated_seconds >= seconds_per_minute:
		_accumulated_seconds -= seconds_per_minute
		_advance_one_minute()

func _unhandled_input(event: InputEvent) -> void:
	if is_fast_forwarding and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			var vm = get_tree().get_first_node_in_group("village_manager")
			if vm == null or not bool(vm.get("player_in_jail")):
				stop_organic_fast_forward(false)
				get_viewport().set_input_as_handled()
				return
	if not allow_debug_time_skip:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			var vm = get_tree().get_first_node_in_group("village_manager")
			if not is_fast_forwarding and (vm == null or (not bool(vm.get("player_in_jail")) and not bool(vm.get("player_being_escorted_to_jail")))):
				start_organic_fast_forward_duration(120, 26.0)
		elif event.physical_keycode == KEY_F7:
			cycle_weather()

func cycle_weather() -> void:
	var next_w: int = (int(current_weather) + 1) % 3
	set_weather(next_w as WeatherType)

func set_weather(w: WeatherType) -> void:
	current_weather = w
	weather_changed.emit(current_weather, get_weather_name(current_weather))
	time_updated.emit(current_day, current_hour, current_minute)
	if current_weather == WeatherType.RAIN:
		_water_all_farm_plots_from_rain()

func _roll_daily_weather() -> void:
	var roll := randf()
	if roll < 0.52:
		current_weather = WeatherType.CLEAR
	elif roll < 0.80:
		current_weather = WeatherType.RAIN
	else:
		current_weather = WeatherType.FOG
	weather_changed.emit(current_weather, get_weather_name(current_weather))
	if current_weather == WeatherType.RAIN:
		call_deferred("_water_all_farm_plots_from_rain")

func _water_all_farm_plots_from_rain() -> void:
	if not is_inside_tree():
		return
	for plot in get_tree().get_nodes_in_group("farm_plots"):
		if is_instance_valid(plot) and plot.has_method("water_from_rain_or_sprinkler"):
			plot.call("water_from_rain_or_sprinkler")

func _advance_one_minute() -> void:
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		if current_hour >= 24:
			current_hour = 0
			current_day += 1
			_roll_daily_weather()
			day_passed.emit(current_day)

		hour_passed.emit(current_day, current_hour)

		var new_phase := get_day_phase(current_hour)
		if new_phase != _current_phase:
			_current_phase = new_phase
			phase_changed.emit(_current_phase, get_phase_name(_current_phase))

	time_updated.emit(current_day, current_hour, current_minute)

	if is_fast_forwarding:
		_fast_forward_elapsed_minutes += 1
		if _fast_forward_target_minutes > 0:
			if _fast_forward_elapsed_minutes >= _fast_forward_target_minutes:
				stop_organic_fast_forward(true)
		elif _fast_forward_elapsed_minutes >= 5 and current_hour == fast_forward_target_hour and current_minute == 0:
			stop_organic_fast_forward(true)

## Inicia un avance rápido orgánico del mundo (`Engine.time_scale`) hasta la hora objetivo (por defecto 06:00 AM),
## haciendo que NPCs, animales, cultivos y rutinas se muevan y reaccionen físicamente sin saltos artificiales.
func start_organic_fast_forward(target_hour: int = 6, speed_mult: float = 26.0, on_complete: Callable = Callable()) -> void:
	is_fast_forwarding = true
	fast_forward_target_hour = clampi(target_hour, 0, 23)
	fast_forward_speed = maxf(2.0, speed_mult)
	_fast_forward_elapsed_minutes = 0
	_fast_forward_target_minutes = 0
	_on_fast_forward_complete = on_complete
	Engine.physics_ticks_per_second = 240
	Engine.time_scale = fast_forward_speed

func start_organic_fast_forward_duration(minutes_to_advance: int, speed_mult: float = 26.0, on_complete: Callable = Callable()) -> void:
	is_fast_forwarding = true
	fast_forward_speed = maxf(2.0, speed_mult)
	_fast_forward_elapsed_minutes = 0
	_fast_forward_target_minutes = maxi(1, minutes_to_advance)
	_on_fast_forward_complete = on_complete
	Engine.physics_ticks_per_second = 240
	Engine.time_scale = fast_forward_speed

func stop_organic_fast_forward(completed_target: bool = true) -> void:
	if not is_fast_forwarding and Engine.time_scale == 1.0:
		return
	is_fast_forwarding = false
	_fast_forward_target_minutes = 0
	Engine.physics_ticks_per_second = 60
	Engine.time_scale = 1.0
	var cb: Callable = _on_fast_forward_complete
	_on_fast_forward_complete = Callable()
	if completed_target and cb.is_valid():
		cb.call()

## Avanza varias horas de golpe (mantenido para compatibilidad de tests unitarios)
func advance_hours(hours: int) -> void:
	if hours <= 0:
		return
	var total_minutes := hours * 60
	for i in range(total_minutes):
		_advance_one_minute()

## Activa el descanso orgánico acelerado hasta las 06:00 AM del siguiente amanecer (sin time-skip instantáneo)
func sleep_until_morning(on_complete: Callable = Callable()) -> void:
	start_organic_fast_forward(6, 26.0, on_complete)

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

func get_weather_name(w: WeatherType = current_weather) -> String:
	match w:
		WeatherType.RAIN:
			return "Lluvia"
		WeatherType.FOG:
			return "Niebla"
		_:
			return "Despejado"

func get_weather_icon(w: WeatherType = current_weather) -> String:
	match w:
		WeatherType.RAIN:
			return "🌧️"
		WeatherType.FOG:
			return "🌫️"
		_:
			return "☀️"

func get_noise_weather_multiplier() -> float:
	if current_weather == WeatherType.RAIN:
		return 0.65
	return 1.0

func get_weather_vision_multiplier() -> float:
	return get_vision_multiplier()

func get_formatted_time() -> String:
	return "Día %d | %02d:%02d (%s | %s %s)" % [
		current_day,
		current_hour,
		current_minute,
		get_phase_name(_current_phase),
		get_weather_icon(current_weather),
		get_weather_name(current_weather)
	]

## Multiplicador sistémico de visión según la luz del día y el clima actual (Niebla reduce -35%, Lluvia -15%)
func get_vision_multiplier() -> float:
	var exact_hour: float = float(current_hour) + float(current_minute) / 60.0
	var base_vis: float = 1.0
	if exact_hour >= 7.0 and exact_hour < 18.0:
		base_vis = 1.0
	elif exact_hour >= 18.0 and exact_hour < 21.0:
		var t: float = (exact_hour - 18.0) / 3.0
		base_vis = lerpf(1.0, 0.6, t)
	elif exact_hour >= 21.0 or exact_hour < 5.0:
		base_vis = 0.6
	else:
		var t: float = (exact_hour - 5.0) / 2.0
		base_vis = lerpf(0.6, 1.0, t)

	if current_weather == WeatherType.FOG:
		base_vis *= 0.65
	elif current_weather == WeatherType.RAIN:
		base_vis *= 0.85
	return clampf(base_vis, 0.28, 1.0)

## Color ambiental interpolado suavemente según la hora exacta del día y el clima
func get_ambient_color() -> Color:
	var exact_hour: float = float(current_hour) + float(current_minute) / 60.0
	
	var color_night := Color(0.32, 0.36, 0.56, 1.0)
	var color_dawn := Color(0.85, 0.72, 0.68, 1.0)
	var color_day := Color(1.0, 1.0, 1.0, 1.0)
	var color_dusk := Color(0.92, 0.68, 0.55, 1.0)

	var base_col := color_day
	if exact_hour >= 0.0 and exact_hour < 5.0:
		base_col = color_night
	elif exact_hour >= 5.0 and exact_hour < 7.0:
		base_col = color_night.lerp(color_dawn, (exact_hour - 5.0) / 2.0)
	elif exact_hour >= 7.0 and exact_hour < 9.0:
		base_col = color_dawn.lerp(color_day, (exact_hour - 7.0) / 2.0)
	elif exact_hour >= 9.0 and exact_hour < 17.5:
		base_col = color_day
	elif exact_hour >= 17.5 and exact_hour < 19.5:
		base_col = color_day.lerp(color_dusk, (exact_hour - 17.5) / 2.0)
	elif exact_hour >= 19.5 and exact_hour < 21.5:
		base_col = color_dusk.lerp(color_night, (exact_hour - 19.5) / 2.0)
	else:
		base_col = color_night

	if current_weather == WeatherType.RAIN:
		return base_col.lerp(Color(0.62, 0.70, 0.84, 1.0), 0.25)
	elif current_weather == WeatherType.FOG:
		return base_col.lerp(Color(0.76, 0.80, 0.84, 1.0), 0.22)
	return base_col

## Serialización limpia lista para el Sistema de Guardado
func to_dict() -> Dictionary:
	return {
		"day": current_day,
		"hour": current_hour,
		"minute": current_minute,
		"weather": int(current_weather)
	}

func from_dict(data: Dictionary) -> void:
	stop_organic_fast_forward(false)
	is_paused_by_activity = false
	current_day = int(data.get("day", 1))
	current_hour = clampi(int(data.get("hour", 8)), 0, 23)
	current_minute = clampi(int(data.get("minute", 0)), 0, 59)
	current_weather = clampi(int(data.get("weather", 0)), 0, 2) as WeatherType
	_current_phase = get_day_phase(current_hour)
	weather_changed.emit(current_weather, get_weather_name(current_weather))
	time_updated.emit(current_day, current_hour, current_minute)
	phase_changed.emit(_current_phase, get_phase_name(_current_phase))
