extends Node
## Gestor global de sonido posicional 3D y oclusión acústica 3D («AudioManager»).
## Reproduce pasos, puertas, voces, impactos y ambiente continuo (río, lago, lluvia) mediante `AudioStreamPlayer3D`
## dentro del mundo 3D, y comprueba muros 3D para amortiguar tanto el sonido oído como el alcance de alertas.

const BancoSonidos3DScript = preload("res://scripts/systems/BancoSonidos3D.gd")
const PaisajeSonoro3DScript = preload("res://scripts/systems/PaisajeSonoro3D.gd")
const ESCALA_SUELO_M: float = 0.056

var sfx_bus_idx: int = -1
var _banco: RefCounted = BancoSonidos3DScript.new()
var _paisaje: RefCounted = PaisajeSonoro3DScript.new()
var _raiz_3d: Node3D = null
var _oyente_3d: AudioListener3D = null
var _clima_3d: Node3D = null
var _escenario_nodo: Node = null


func _ready() -> void:
	sfx_bus_idx = AudioServer.get_bus_index("SFX")
	if sfx_bus_idx == -1:
		AudioServer.add_bus()
		sfx_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_bus_idx, "SFX")
		var master_idx: int = AudioServer.get_bus_index("Master")
		if master_idx != -1:
			AudioServer.set_bus_send(sfx_bus_idx, "Master")


func conectar_escenario_3d(escenario: Node, raiz_3d: Node3D, oyente: AudioListener3D, clima: Node3D) -> void:
	_escenario_nodo = escenario
	_raiz_3d = raiz_3d
	_oyente_3d = oyente
	_clima_3d = clima
	if DisplayServer.get_name() != "headless" and is_instance_valid(_raiz_3d) and is_instance_valid(_oyente_3d):
		_paisaje.call("configurar", self, _raiz_3d, _oyente_3d, _clima_3d, _banco)


func _process(delta: float) -> void:
	if DisplayServer.get_name() == "headless" or not is_instance_valid(_raiz_3d):
		return
	_paisaje.call("actualizar", delta, get_tree())


func reproducir_3d(stream: AudioStream, pos_3d: Vector3, variacion_tono: float = 0.08, volumen_db: float = 0.0, alcance_m: float = 30.0) -> AudioStreamPlayer3D:
	if stream == null or DisplayServer.get_name() == "headless" or not is_instance_valid(_raiz_3d):
		return null
	var emisor := AudioStreamPlayer3D.new()
	emisor.stream = stream
	emisor.position = pos_3d
	emisor.pitch_scale = maxf(0.25, 1.0 + randf_range(-variacion_tono, variacion_tono))
	emisor.volume_db = volumen_db
	emisor.unit_size = 4.2
	emisor.max_distance = alcance_m
	emisor.panning_strength = 1.0
	emisor.bus = "SFX"
	if is_instance_valid(_oyente_3d):
		var ocl: float = multiplicador_oclusion_3d(pos_3d, _oyente_3d.global_position)
		if ocl < 0.99:
			emisor.volume_db -= 5.5
			emisor.attenuation_filter_cutoff_hz = 950.0
	emisor.finished.connect(emisor.queue_free)
	_raiz_3d.add_child(emisor)
	emisor.play()
	return emisor


func play_sound_at(stream: AudioStream, global_pos: Vector2, pitch_variance: float = 0.1, base_volume_db: float = 0.0) -> void:
	reproducir_3d(stream, _punto_a_3d(global_pos, 1.1), pitch_variance, base_volume_db, 32.0)


func sonar_puerta_3d(pos_3d: Vector3, abriendo: bool) -> void:
	if is_instance_valid(_oyente_3d) and (pos_3d - _oyente_3d.global_position).length_squared() > 38.0 * 38.0:
		return
	var clave: String = "puerta_abrir" if abriendo else "puerta_cerrar"
	reproducir_3d(_banco.call("obtener", clave) as AudioStream, pos_3d, 0.06, -3.5, 26.0)


func sonar_paso_3d(pos_3d: Vector3, superficie: String = "hierba", volumen_db: float = -4.0) -> void:
	var llueve: bool = WorldClock != null and int(WorldClock.get("current_weather")) == 1
	var sup_real: String = "agua" if (llueve and superficie == "hierba" and randf() < 0.25) else superficie
	reproducir_3d(_banco.call("obtener", "paso_" + sup_real) as AudioStream, pos_3d, 0.11, volumen_db, 20.0)


func sonar_voz_3d(pos_3d: Vector3, semilla: int = 0, volumen_db: float = -6.0) -> void:
	var clave: String = "voz_%d" % posmod(semilla, 4)
	reproducir_3d(_banco.call("obtener", clave) as AudioStream, pos_3d, 0.07, volumen_db, 22.0)


func _punto_a_3d(pos_plana: Vector2, elevacion_m: float = 1.2) -> Vector3:
	if is_instance_valid(_escenario_nodo) and _escenario_nodo.has_method("to_3d"):
		var base: Vector3 = _escenario_nodo.call("to_3d", pos_plana, 0.0)
		return base + Vector3(0.0, elevacion_m, 0.0)
	return Vector3(pos_plana.x * ESCALA_SUELO_M, elevacion_m, pos_plana.y * ESCALA_SUELO_M)


func multiplicador_oclusion_3d(origen_3d: Vector3, oyente_3d: Vector3) -> float:
	if not is_instance_valid(_raiz_3d) or _raiz_3d.get_world_3d() == null:
		return 1.0
	var espacio: PhysicsDirectSpaceState3D = _raiz_3d.get_world_3d().direct_space_state
	if espacio == null:
		return 1.0
	var consulta := PhysicsRayQueryParameters3D.create(origen_3d, oyente_3d, 1)
	var impacto: Dictionary = espacio.intersect_ray(consulta)
	return 1.0 if impacto.is_empty() else 0.35


func emit_noise(origin: Vector2, base_radius: float, elevation: int = -999, kind: String = "combat") -> void:
	var origen_3d: Vector3 = _punto_a_3d(origin, 1.3)
	if kind == "gunshot":
		reproducir_3d(_banco.call("obtener", "disparo_seco") as AudioStream, origen_3d, 0.05, 1.5, 65.0)
	elif kind in ["heavy_hit", "melee_hit", "combat"]:
		reproducir_3d(_banco.call("obtener", "golpe_seco") as AudioStream, origen_3d, 0.09, -2.5, 34.0)

	var radio_sq: float = base_radius * base_radius
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var pos_v: Variant = enemy.get("global_position")
		if not (pos_v is Vector2):
			continue
		var pos_e: Vector2 = pos_v
		var dist_sq: float = (pos_e - origin).length_squared()
		if dist_sq > radio_sq:
			continue
		var ai: Node = enemy.get_node_or_null("EnemyAI")
		if ai == null or not ai.is_physics_processing():
			continue
		var eff_range: float = base_radius * multiplicador_oclusion_3d(origen_3d, _punto_a_3d(pos_e, 1.3))
		if dist_sq <= eff_range * eff_range and ai.has_method("on_noise_heard"):
			ai.call("on_noise_heard", origin)

	var vm: Node = get_tree().get_first_node_in_group("village_manager")
	var src_elev: int = elevation if elevation != -999 else (int(vm.get("player_elevation_level")) if vm != null and "player_elevation_level" in vm else 0)
	for n: Node in get_tree().get_nodes_in_group("village_npcs"):
		if not is_instance_valid(n) or not n.has_method("on_noise_heard"):
			continue
		if n.get("is_dead") == true or n.get("is_downed") == true or n.get("is_sleeping") == true or n.get("is_stunned_flag") == true:
			continue
		var pos_nv: Variant = n.get("global_position")
		if not (pos_nv is Vector2):
			continue
		var pos_n: Vector2 = pos_nv
		var d2: float = (pos_n - origin).length_squared()
		if d2 > radio_sq or d2 < 4.0:
			continue
		var eff_r: float = base_radius * multiplicador_oclusion_3d(origen_3d, _punto_a_3d(pos_n, 1.3))
		if vm != null:
			eff_r *= float(vm.call("oye", origin, src_elev, pos_n, int(n.get("elevation_level"))))
		if d2 <= eff_r * eff_r:
			n.call("on_noise_heard", origin, base_radius, kind, src_elev)
