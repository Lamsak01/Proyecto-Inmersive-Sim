extends SceneTree

## Prueba de las mascotas del pueblo como cuerpos 3D (paso a 3D, tanda 4b-3, 2026-11-14). Sin ventana, ~1 min.
## Uso: timeout 240 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/mascotas_3d.gd
## Termina con «MASCOTAS 3D: PASSED» o «FAILED».

const PASOS_POR_S: int = 60

var _fallos: int = 0
var _vm: Node = null
var _pl: Node2D = null
var _reloj: Node = null


func _ok(c: bool, txt: String) -> void:
	print(("  OK  " if c else "  FALLO  ") + txt)
	if not c:
		_fallos += 1


func _initialize() -> void:
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(40):
		await physics_frame
	_vm = get_first_node_in_group("village_manager")
	_pl = get_first_node_in_group("player") as Node2D
	_reloj = root.get_node("/root/WorldClock")
	_reloj.set("current_hour", 12)
	_son_cuerpos_3d()
	await _pasean_y_duermen()
	await _caricias_y_comida()
	await _guardar_y_cargar()
	await _gato_huye()
	await _perro_se_revuelve()
	await _muerte_y_desuello()
	print("MASCOTAS 3D: %s (%d fallos)" % ["PASSED" if _fallos == 0 else "FAILED", _fallos])
	quit(1 if _fallos > 0 else 0)


func _esperar(segundos: float) -> void:
	for _i in range(int(segundos * PASOS_POR_S)):
		await physics_frame


func _mascota(clase: int, distinta_de: Node = null) -> Node:
	for m in get_nodes_in_group("domestic_pets"):
		if int(m.pet_type) == clase and not m.is_dead and m != distinta_de:
			return m
	return null


func _prota_a(sitio: Vector2) -> void:
	_vm.call("set_player_elevation_level", 0)
	_pl.global_position = Lugar.a_mapa(sitio)
	_pl.velocity = Vector2.ZERO


func _son_cuerpos_3d() -> void:
	var todas: Array[Node] = get_nodes_in_group("domestic_pets")
	var Base = load("res://scripts/fisica/CuerpoBase3D.gd")
	var planas: int = 0
	var peor_suelo: float = 0.0
	var sin_piezas: int = 0
	for m in todas:
		if not (m is CharacterBody3D) or m is Node2D or m.has_meta("cuerpo3d"):
			planas += 1
			continue
		peor_suelo = maxf(peor_suelo, absf(m.global_position.y - float(Base.suelo_y(m.global_position.x, m.global_position.z, 0, _vm))))
		if Diana3D.de(m) == null or not (m.zona_e is Tocable3D) or m.get_node_or_null("HealthComponent") == null:
			sin_piezas += 1
	_ok(todas.size() >= 5, "hay mascotas en el pueblo (%d)" % todas.size())
	_ok(planas == 0, "todas SON un cuerpo 3D y ninguna tiene nodo en el mapa plano (planas: %d)" % planas)
	_ok(peor_suelo < 0.3, "pisan el suelo (la peor, a %.2f m)" % peor_suelo)
	_ok(sin_piezas == 0, "todas tienen su diana, su zona de la tecla E y su vida (sin algo: %d)" % sin_piezas)
	var en_mapa: int = 0
	for n in _vm.entities_root.get_children():
		if str(n.name).begins_with("Pet_"):
			en_mapa += 1
	_ok(en_mapa == 0, "no queda ninguna mascota colgando del mapa plano")


func _pasean_y_duermen() -> void:
	var todas: Array[Node] = get_nodes_in_group("domestic_pets")
	var antes: Array[Vector2] = []
	for m in todas:
		m.need_energy = 95.0
		antes.append(m.sitio)
	await _esperar(12.0)
	var movidas: int = 0
	var lejos: int = 0
	for i in range(todas.size()):
		if todas[i].sitio.distance_to(antes[i]) > 0.3:
			movidas += 1
		if todas[i].sitio.distance_to(todas[i].casa) > 6.0:
			lejos += 1
	_ok(movidas >= todas.size() / 2, "de día pasean cerca de su casa (%d de %d se han movido)" % [movidas, todas.size()])
	_ok(lejos == 0, "y no se alejan de ella (lejos: %d)" % lejos)
	_reloj.set("current_hour", 23)
	await _esperar(8.0)
	var dormidas: int = 0
	for m in todas:
		if m.is_sleeping and m.sitio.distance_to(m.casa) < 2.5:
			dormidas += 1
	_ok(dormidas == todas.size(), "de noche vuelven a su cama y duermen (%d de %d)" % [dormidas, todas.size()])
	_reloj.set("current_hour", 12)
	await _esperar(1.0)


## Con [E]: una caricia sube su afecto; con comida que le gusta, come.
func _caricias_y_comida() -> void:
	var perro = _mascota(0)
	perro.set_physics_process(false)
	_prota_a(perro.sitio + Vector2(0.9, 0.0))
	await _esperar(0.3)
	var sel = _pl.interaction_selector
	sel.refresh()
	var opcion: Array = sel.candidates.filter(func(c): return c["target"] == perro)
	_ok(not opcion.is_empty() and str(opcion[0]["label"]).contains(perro.pet_name), "la tecla E ofrece a %s: «%s»" % [perro.pet_name, str(opcion[0]["label"]) if not opcion.is_empty() else "nada"])
	var afecto: float = perro.affection
	var textos_antes: int = _textos()
	perro.is_fed_today = true
	perro.need_hunger = 95.0
	perro.interact(_pl)
	await physics_frame
	_ok(perro.affection > afecto, "una caricia sube su afecto (%.0f → %.0f)" % [afecto, perro.affection])
	_ok(_textos() > textos_antes, "y sale un texto flotante en el mundo 3D")
	perro.need_hunger = 40.0
	perro.digestion_buffer = 0.0
	_pl.inventory.add_item("raw_meat", 1)
	var carne: int = int(_pl.inventory.get_count("raw_meat"))
	perro.interact(_pl)
	_ok(int(_pl.inventory.get_count("raw_meat")) == carne - 1 and perro.digestion_buffer > 0.0, "con hambre y carne en la bolsa, come de tu mano")
	perro.set_physics_process(true)


func _textos() -> int:
	var n: int = 0
	for t in root.find_children("*", "Label3D", true, false):
		if t is TextoFlotante3D:
			n += 1
	return n


func _guardar_y_cargar() -> void:
	var gato = _mascota(1)
	gato.set_physics_process(false)
	var donde: Vector2 = gato.sitio
	var guardado: Dictionary = gato.to_save_dict()
	gato.sitio = donde + Vector2(9.0, 3.0)
	gato.from_save_dict(guardado)
	_ok(gato.sitio.distance_to(donde) < 0.01 and not gato.is_dead and gato.visible, "guardar y cargar la deja donde estaba, viva")
	var viejo: Dictionary = guardado.duplicate()
	viejo.erase("x_m")
	viejo.erase("z_m")
	viejo["pos_x"] = 1000.0
	viejo["pos_y"] = 2000.0
	gato.from_save_dict(viejo)
	_ok(gato.sitio.distance_to(Lugar.a_suelo(Vector2(1000.0, 2000.0))) < 0.01, "una partida vieja (sitio en el mapa plano) se carga en su sitio en metros")
	gato.sitio = donde
	gato.set_physics_process(true)
	await physics_frame


func _golpe(cuanto: float) -> Object:
	var g = load("res://scripts/systems/combat/DamageData.gd").new()
	g.amount = cuanto
	g.source = _pl
	return g


func _gato_huye() -> void:
	var gato = _mascota(1)
	_prota_a(gato.sitio + Vector2(1.0, 0.0))
	await _esperar(0.2)
	var d0: float = gato.sitio.distance_to(Lugar.de(_pl))
	gato.take_damage(_golpe(2.0))
	await _esperar(2.0)
	_ok(gato.flee_timer > 0.0 and gato.sitio.distance_to(Lugar.de(_pl)) > d0 + 3.0, "un gato al que pegan sale huyendo (de %.1f a %.1f m)" % [d0, gato.sitio.distance_to(Lugar.de(_pl))])
	gato.flee_timer = 0.0


func _perro_se_revuelve() -> void:
	var perro = _mascota(0)
	_prota_a(perro.sitio + Vector2(3.0, 0.0))
	await _esperar(0.2)
	var vida: float = float(_pl.health_comp.current_health)
	perro.take_damage(_golpe(2.0))
	_ok(perro.is_hostile and perro.is_in_group("enemies"), "un perro al que pegan se revuelve")
	for _i in range(5 * PASOS_POR_S):
		await physics_frame
		_pl.velocity = Vector2.ZERO
	_ok(float(_pl.health_comp.current_health) < vida, "te alcanza y te muerde (vida %.0f → %.0f)" % [vida, float(_pl.health_comp.current_health)])
	perro.hostile_timer = 0.0
	_pl.health_comp.current_health = _pl.health_comp.max_health
	await _esperar(0.3)
	_ok(not perro.is_hostile and not perro.is_in_group("enemies"), "y al rato se le pasa")


func _muerte_y_desuello() -> void:
	var perro = _mascota(0)
	perro.set_physics_process(false)
	_prota_a(perro.sitio + Vector2(0.9, 0.0))
	perro.take_damage(_golpe(999.0))
	await process_frame
	await _esperar(0.3)
	_ok(perro.is_dead and perro.tumbado and not Diana3D.de(perro).activa, "un golpe mortal la deja muerta en el suelo y ya no se la hiere")
	var sel = _pl.interaction_selector
	sel.refresh()
	_ok(not sel.candidates.filter(func(c): return c["target"] == perro).is_empty(), "la tecla E sigue ofreciéndola (para desollarla)")
	var carne: int = int(_pl.inventory.get_count("raw_meat"))
	perro.interact(_pl)
	await _esperar(0.2)
	sel.refresh()
	_ok(perro.corpse_looted and not perro.visible and int(_pl.inventory.get_count("raw_meat")) == carne + 1, "al desollarla desaparece y te llevas la carne")
	_ok(sel.candidates.filter(func(c): return c["target"] == perro).is_empty(), "y la tecla E ya no la ofrece")
