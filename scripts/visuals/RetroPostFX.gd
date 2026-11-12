extends CanvasLayer

## Etalonaje retro de pantalla completa (ver `shaders/retro_post_fx.gdshader`).
## Va en la misma capa que la interfaz, pero justo antes que ella en el árbol: afecta al mundo y no a los menús.
## Calcula cada fotograma cuánto es de noche y dónde hay luz (farolas encendidas, ventanas sin postigo y el jugador).
## De noche añade la niebla que se cierra con la distancia al jugador (las luces la atraviesan).
## No se crea en modo headless (pruebas automáticas) ni en el editor.

const VillageCulture = preload("res://scripts/systems/VillageCulture.gd")
const WorldStage3DScript = preload("res://scripts/visuals/WorldStage3D.gd")
const SHADER := preload("res://shaders/retro_post_fx.gdshader")
const MAX_LIGHTS := 24

var vm: Node = null
var _rect: ColorRect = null
var _mat: ShaderMaterial = null
var _time: float = 0.0


func setup(village_manager: Node) -> void:
	vm = village_manager
	name = "RetroPostFX"
	layer = 1
	_rect = ColorRect.new()
	_rect.name = "RetroPostFXRect"
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_rect.material = _mat
	add_child(_rect)


## 0 = pleno día, 1 = noche cerrada. Atardecer largo (17:00–21:30) y amanecer (5:00–7:30).
static func night_factor(hour_f: float) -> float:
	if hour_f >= 21.5 or hour_f < 5.0:
		return 1.0
	if hour_f >= 17.0:
		return smoothstep(17.0, 21.5, hour_f)
	if hour_f < 7.5:
		return 1.0 - smoothstep(5.0, 7.5, hour_f)
	return 0.0


## Intensidad del tono dorado: máxima hacia las 18:30 y, más suave, al amanecer.
static func dusk_factor(hour_f: float) -> float:
	var ev := clampf(1.0 - absf(hour_f - 18.6) / 2.2, 0.0, 1.0)
	var mo := clampf(1.0 - absf(hour_f - 6.3) / 1.4, 0.0, 1.0) * 0.6
	return maxf(ev, mo)


func _process(delta: float) -> void:
	if _mat == null:
		return
	if is_instance_valid(_rect):
		_rect.visible = not WorldStage3DScript.first_person_active
		if not _rect.visible:
			return
	_time += delta
	var wc = get_node_or_null("/root/WorldClock")
	var hour_f: float = 12.0
	var weather_fog: float = 0.0
	if wc != null:
		hour_f = float(wc.current_hour) + float(wc.current_minute) / 60.0
		var w_mode: int = int(wc.get("current_weather")) if wc.get("current_weather") != null else 0
		if w_mode == 2:
			weather_fog = 1.0
		elif w_mode == 1:
			weather_fog = 0.22
	var nf := night_factor(hour_f)
	_mat.set_shader_parameter("night", nf)
	_mat.set_shader_parameter("dusk", dusk_factor(hour_f))
	_mat.set_shader_parameter("weather_fog", weather_fog)
	_mat.set_shader_parameter("time_s", _time)

	var vp := get_viewport()
	var cam := vp.get_camera_2d()
	var zoom: float = cam.zoom.x if cam != null else 2.4
	var final_t: Transform2D = vp.get_final_transform()
	var to_screen: Transform2D = final_t * vp.get_canvas_transform()
	var px_per_world: float = final_t.get_scale().x * zoom
	_mat.set_shader_parameter("pixel_size", maxf(1.0, px_per_world))
	_mat.set_shader_parameter("px_per_world", maxf(0.001, px_per_world))
	_mat.set_shader_parameter("world_origin_px", to_screen.origin)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(player):
		_mat.set_shader_parameter("player_px", to_screen * player.global_position)
		# Con el farol encendido se ve algo más lejos entre la niebla
		var lantern := bool(player.get("is_carrying_lantern")) if player.get("is_carrying_lantern") != null else false
		_mat.set_shader_parameter("fog_clear", 120.0 if lantern else 70.0)
		_mat.set_shader_parameter("fog_full", 300.0 if lantern else 240.0)

	var lights: Array = []
	if nf > 0.01:
		_collect_lights(lights, to_screen, px_per_world, hour_f)
	var packed := PackedVector4Array()
	packed.resize(MAX_LIGHTS)
	var n: int = mini(lights.size(), MAX_LIGHTS)
	for i in range(n):
		packed[i] = lights[i]
	_mat.set_shader_parameter("lights", packed)
	_mat.set_shader_parameter("light_count", n)


func _collect_lights(out: Array, to_screen: Transform2D, px_per_world: float, hour_f: float) -> void:
	var screen_sz: Vector2 = get_viewport().get_final_transform().get_scale() * get_viewport().get_visible_rect().size
	var margin := 120.0 * px_per_world
	var player := get_tree().get_first_node_in_group("player") as Node2D
	# El jugador lleva siempre un pequeño halo para no perderse en la oscuridad.
	if is_instance_valid(player):
		var lantern := bool(player.get("is_carrying_lantern")) if player.get("is_carrying_lantern") != null else false
		var r := 95.0 if lantern else 46.0
		out.append(_light(to_screen * player.global_position, r * px_per_world, 0.9))
	if vm == null or not is_instance_valid(vm):
		vm = get_tree().root.find_child("VillageManager", true, false)
		if vm == null:
			return
	var gm = get_node_or_null("/root/GameManager")
	var grid_on: bool = gm != null and bool(gm.get_flag("electric_grid_active", false))
	# Con el circuito de farolas cortado (sabotaje), sin halos de farola.
	var lamps_lit: bool = VillageCulture.is_lamps_powered(vm) and (hour_f >= 19.0 or hour_f < 6.0 or grid_on)
	if lamps_lit and "streetlights" in vm:
		for sl in vm.streetlights:
			var p: Vector2 = to_screen * ((sl.get("pos", Vector2.ZERO) as Vector2) + Vector2(3.5, -6.0))
			if _on_screen(p, screen_sz, margin):
				out.append(_light(p, 78.0 * px_per_world, 1.0))
	# Ventanas encendidas: de 18:00 a 23:30 y antes del alba, salvo si tienen el postigo cerrado.
	var windows_lit: bool = hour_f >= 18.0 and hour_f < 23.5 or (hour_f >= 5.0 and hour_f < 6.5)
	if windows_lit and "building_windows" in vm:
		for w in vm.building_windows:
			if bool(w.get("is_shuttered", false)):
				continue
			var wp: Vector2 = to_screen * (w.get("pos", Vector2.ZERO) as Vector2)
			if _on_screen(wp, screen_sz, margin):
				out.append(_light(wp, 34.0 * px_per_world, 0.75))
	# Las más cercanas al centro primero (por si hay más de MAX_LIGHTS)
	var center := screen_sz * 0.5
	out.sort_custom(func(a: Vector4, b: Vector4) -> bool:
		return Vector2(a.x, a.y).distance_squared_to(center) < Vector2(b.x, b.y).distance_squared_to(center))


func _light(p: Vector2, r: float, w: float) -> Vector4:
	return Vector4(p.x, p.y, r, w)


func _on_screen(p: Vector2, sz: Vector2, margin: float) -> bool:
	return p.x > -margin and p.y > -margin and p.x < sz.x + margin and p.y < sz.y + margin
