extends RefCounted

## Paisaje sonoro 3D continuo del valle: corriente del río y orilla del lago con amortiguación bajo techo,
## repiqueteo de lluvia exterior, pasos 3D del protagonista y vecinos cercanos, y voces 3D en charlas.

const INTERVALO_PASO_BASE_M: float = 1.52
const DIST_PASOS_VECINOS_M: float = 18.0
const DIST_VOCES_CALLE_M: float = 19.0

var _audio: Node = null
var _raiz_3d: Node3D = null
var _oyente: AudioListener3D = null
var _clima: Node3D = null
var _rio_player: AudioStreamPlayer3D = null
var _lago_player: AudioStreamPlayer3D = null
var _lluvia_player: AudioStreamPlayer3D = null
var _estado_pasos: Dictionary = {}
var _reloj_voz_dialogo: float = 0.0
var _reloj_voces_calle: float = 1.8


func configurar(audio_mgr: Node, raiz_3d: Node3D, oyente: AudioListener3D, clima: Node3D, banco: RefCounted) -> void:
	_audio = audio_mgr
	_raiz_3d = raiz_3d
	_oyente = oyente
	_clima = clima
	_estado_pasos.clear()
	_rio_player = _crear_bucle("SonidoRio3D", banco.call("obtener", "agua_rio") as AudioStream, 8.5, 64.0, -5.5)
	_lago_player = _crear_bucle("SonidoLago3D", banco.call("obtener", "agua_rio") as AudioStream, 7.0, 52.0, -8.0)
	_lago_player.pitch_scale = 0.86
	_lluvia_player = _crear_bucle("SonidoLluvia3D", banco.call("obtener", "lluvia_ambiente") as AudioStream, 12.0, 40.0, -9.0)
	_lluvia_player.stop()


func _crear_bucle(nombre: String, pista: AudioStream, unidad_m: float, alcance_m: float, vol_db: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.name = nombre
	p.stream = pista
	p.bus = "SFX"
	p.unit_size = unidad_m
	p.max_distance = alcance_m
	p.volume_db = vol_db
	p.panning_strength = 1.0
	p.attenuation_filter_cutoff_hz = 5200.0
	p.attenuation_filter_db = -18.0
	_raiz_3d.add_child(p)
	p.play()
	return p


func actualizar(delta: float, arbol: SceneTree) -> void:
	if not is_instance_valid(_raiz_3d) or not is_instance_valid(_oyente):
		return
	var pos_o: Vector3 = _oyente.global_position
	var resguardado: bool = is_instance_valid(_clima) and bool(_clima.call("bajo_techo_en_3d", pos_o))
	var punto_rio: Vector3 = _actualizar_agua(pos_o, resguardado)
	_actualizar_lluvia(pos_o, resguardado, arbol)
	_actualizar_pasos(delta, pos_o, punto_rio)
	_actualizar_voces(delta, pos_o, arbol)


func _actualizar_agua(pos_o: Vector3, resguardado: bool) -> Vector3:
	var terreno := _raiz_3d.get_node_or_null("Terrain3D") as Node3D
	var mejor_rio := Vector3(8.0, -0.2, pos_o.z)
	if terreno != null and terreno.has_meta("puntos_rio_3d"):
		mejor_rio = _punto_mas_cercano_polilinea(terreno.get_meta("puntos_rio_3d") as PackedVector3Array, pos_o)
	if is_instance_valid(_rio_player):
		_rio_player.global_position = mejor_rio
		_rio_player.volume_db = -13.5 if resguardado else -5.0
		_rio_player.attenuation_filter_cutoff_hz = 720.0 if resguardado else 4800.0
		if not _rio_player.playing:
			_rio_player.play()
	if is_instance_valid(_lago_player) and terreno != null and terreno.has_meta("puntos_lago_3d"):
		var mejor_lago: Vector3 = _punto_mas_cercano_polilinea(terreno.get_meta("puntos_lago_3d") as PackedVector3Array, pos_o)
		_lago_player.global_position = mejor_lago
		_lago_player.volume_db = -16.0 if resguardado else -8.0
		_lago_player.attenuation_filter_cutoff_hz = 680.0 if resguardado else 4200.0
		if not _lago_player.playing:
			_lago_player.play()
	return mejor_rio


func _actualizar_lluvia(pos_o: Vector3, resguardado: bool, arbol: SceneTree) -> void:
	if not is_instance_valid(_lluvia_player):
		return
	var reloj: Node = arbol.root.get_node_or_null("WorldClock")
	var llueve: bool = reloj != null and int(reloj.get("current_weather")) == 1
	if not llueve:
		if _lluvia_player.playing:
			_lluvia_player.stop()
		return
	_lluvia_player.global_position = pos_o + Vector3(0.0, 2.8 if resguardado else 1.4, 0.0)
	_lluvia_player.volume_db = -12.5 if resguardado else -7.5
	_lluvia_player.attenuation_filter_cutoff_hz = 820.0 if resguardado else 5600.0
	if not _lluvia_player.playing:
		_lluvia_player.play()


func _actualizar_pasos(delta: float, pos_o: Vector3, punto_rio: Vector3) -> void:
	if delta <= 0.0001:
		return
	var terreno := _raiz_3d.get_node_or_null("Terrain3D") as Node3D
	var caja_plaza: AABB = terreno.get_meta("caja_plaza_3d") as AABB if (terreno != null and terreno.has_meta("caja_plaza_3d")) else AABB()
	# Protagonista: seguido desde el oyente 3D (funciona igual en 1.ª persona y desde arriba)
	_procesar_paso_entidad(0, pos_o - Vector3(0.0, 1.54, 0.0), true, delta, punto_rio, caja_plaza)
	var personajes := _raiz_3d.get_node_or_null("Characters3D") as Node3D
	if personajes == null:
		return
	for h: Node in personajes.get_children():
		if not (h is Node3D) or not String(h.name).begins_with("Avatar_") or h.name == &"Avatar_PlayerGood":
			continue
		var av := h as Node3D
		var pos_act: Vector3 = av.global_position
		if (pos_act - pos_o).length_squared() > DIST_PASOS_VECINOS_M * DIST_PASOS_VECINOS_M:
			continue
		_procesar_paso_entidad(av.get_instance_id(), pos_act, false, delta, punto_rio, caja_plaza)


func _procesar_paso_entidad(clave: int, pos_act: Vector3, es_jugador: bool, delta: float, punto_rio: Vector3, caja_plaza: AABB) -> void:
	if not _estado_pasos.has(clave):
		_estado_pasos[clave] = {"pos": pos_act, "acum": 0.0}
		return
	var est: Dictionary = _estado_pasos[clave]
	var prev: Vector3 = est["pos"]
	est["pos"] = pos_act
	var desp_h := Vector3(pos_act.x - prev.x, 0.0, pos_act.z - prev.z)
	var d_m: float = desp_h.length()
	var vel_m_s: float = d_m / delta
	if d_m > 3.5 or vel_m_s < 0.42 or absf(pos_act.y - prev.y) > d_m * 1.6 + 0.35:
		return
	var paso_meta: float = INTERVALO_PASO_BASE_M * (0.82 if vel_m_s > 4.2 else 1.0)
	var acum: float = float(est["acum"]) + d_m
	if acum >= paso_meta:
		acum = fmod(acum, paso_meta)
		var sup: String = _superficie_en_3d(pos_act, punto_rio, caja_plaza)
		var vol: float = (-3.5 if vel_m_s > 2.2 else -7.5) if es_jugador else -11.5
		_audio.call("sonar_paso_3d", pos_act + Vector3(0.0, 0.08, 0.0), sup, vol)
	est["acum"] = acum


func _superficie_en_3d(pie: Vector3, punto_rio: Vector3, caja_plaza: AABB) -> String:
	var dr_xz: float = Vector2(pie.x - punto_rio.x, pie.z - punto_rio.z).length()
	if dr_xz < 6.8:
		return "agua" if pie.y <= punto_rio.y + 0.45 else "madera"
	if is_instance_valid(_clima) and bool(_clima.call("bajo_techo_en_3d", pie + Vector3(0.0, 1.0, 0.0))):
		return "madera"
	if caja_plaza.size.x > 0.5 and caja_plaza.grow(1.2).has_point(Vector3(pie.x, caja_plaza.position.y + 0.2, pie.z)):
		return "piedra"
	return "hierba"


func _actualizar_voces(delta: float, pos_o: Vector3, arbol: SceneTree) -> void:
	var personajes := _raiz_3d.get_node_or_null("Characters3D") as Node3D
	if personajes == null:
		return
	var jugador: Node = arbol.get_first_node_in_group("player")
	var dm: Variant = jugador.get("dialogue_manager") if is_instance_valid(jugador) else null
	if dm is Node and bool((dm as Node).get("active")):
		_reloj_voz_dialogo -= delta
		var ventana: Variant = (dm as Node).get("_ventana")
		var hablando_ahora: bool = ventana is Node and ventana.has_method("revelando") and bool(ventana.call("revelando"))
		if hablando_ahora and _reloj_voz_dialogo <= 0.0:
			_reloj_voz_dialogo = 0.21
			var hablante: Variant = (dm as Node).get("current_speaker")
			if hablante is Node and is_instance_valid(hablante):
				var av_h := personajes.get_node_or_null("Avatar_" + String((hablante as Node).name)) as Node3D
				var cab: Vector3 = (av_h.global_position + Vector3(0.0, 1.58, 0.0)) if av_h != null else (pos_o + Vector3(0.0, 0.0, -1.5))
				_audio.call("sonar_voz_3d", cab, hash(String((hablante as Node).name)), -5.5)
		return
	_reloj_voces_calle -= delta
	if _reloj_voces_calle > 0.0:
		return
	_reloj_voces_calle = 3.4
	var cercanos: Array[Node3D] = []
	for h: Node in personajes.get_children():
		if h is Node3D and (h as Node3D).visible and String(h.name).begins_with("Avatar_") and h.name != &"Avatar_PlayerGood":
			if ((h as Node3D).global_position - pos_o).length_squared() <= DIST_VOCES_CALLE_M * DIST_VOCES_CALLE_M:
				cercanos.append(h as Node3D)
	for i: int in range(cercanos.size()):
		for j: int in range(i + 1, cercanos.size()):
			if (cercanos[i].global_position - cercanos[j].global_position).length_squared() <= 10.5:
				_audio.call("sonar_voz_3d", cercanos[i].global_position + Vector3(0.0, 1.58, 0.0), i + j, -13.5)
				return


func _punto_mas_cercano_polilinea(pts: PackedVector3Array, p: Vector3) -> Vector3:
	if pts.is_empty():
		return p
	var mejor: Vector3 = pts[0]
	var mejor_d2: float = (pts[0] - p).length_squared()
	for i: int in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var ab: Vector3 = b - a
		var ab2: float = ab.length_squared()
		var t: float = clampf((p - a).dot(ab) / ab2, 0.0, 1.0) if ab2 > 0.0001 else 0.0
		var proy: Vector3 = a + ab * t
		var d2: float = (proy - p).length_squared()
		if d2 < mejor_d2:
			mejor_d2 = d2
			mejor = proy
	return mejor
