extends SceneTree

## Prueba de los animales salvajes como cuerpos 3D (paso a 3D, tanda 4b-2, 2026-11-14). Sin ventana, ~1 min.
## Uso: timeout 300 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/animales_3d.gd
## Termina con «ANIMALES 3D: PASSED» o «FAILED».
## Comprueba que son cuerpos 3D sin doble en el mapa plano, que pastan, huyen, se despiezan con [E] y se guardan, y
## (apagando el modo demo) la simulación completa: buscar comida, la embestida del jabalí y la caza del zorro.

const PASOS_POR_S: int = 60
const WA = "res://scripts/enemies/WildAnimal.gd"

var _fallos: int = 0
var _vm: Node = null
var _pl: Node2D = null
var _gm: Node = null
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
	_gm = root.get_node("/root/GameManager")
	_reloj = root.get_node("/root/WorldClock")
	_reloj.set("current_hour", 12)
	_son_cuerpos_3d()
	await _vida_tranquila()
	await _huyen_del_protagonista()
	await _guardar_y_cargar()
	await _despiece()
	_gm.call("set_demo_mode", false)
	await _simulacion_completa()
	await _jabali()
	await _zorro()
	_gm.call("set_demo_mode", true)
	print("ANIMALES 3D: %s (%d fallos)" % ["PASSED" if _fallos == 0 else "FAILED", _fallos])
	quit(1 if _fallos > 0 else 0)


func _esperar(segundos: float) -> void:
	for _i in range(int(segundos * PASOS_POR_S)):
		await physics_frame


func _vivos(especie: int = -1) -> Array[Node]:
	var out: Array[Node] = []
	for a in get_nodes_in_group("wild_animals"):
		if a.is_alive_in_ecosystem() and a.visible and (especie == -1 or int(a.species) == especie):
			out.append(a)
	return out


## El protagonista, a un sitio (metros sobre el suelo) y quieto.
func _prota_a(sitio: Vector2) -> void:
	_vm.call("set_player_elevation_level", 0)
	_pl.global_position = Lugar.a_mapa(sitio)
	_pl.velocity = Vector2.ZERO


func _son_cuerpos_3d() -> void:
	var todos: Array[Node] = get_nodes_in_group("wild_animals")
	var planos: int = 0
	var peor_suelo: float = 0.0
	var Base = load("res://scripts/fisica/CuerpoBase3D.gd")
	for a in todos:
		if not (a is CharacterBody3D) or a is Node2D or a.has_meta("cuerpo3d"):
			planos += 1
			continue
		peor_suelo = maxf(peor_suelo, absf(a.global_position.y - float(Base.suelo_y(a.global_position.x, a.global_position.z, 0, _vm))))
	_ok(todos.size() >= 20, "hay animales salvajes en el bosque (%d vivos)" % todos.size())
	_ok(planos == 0, "todos SON un cuerpo 3D y ninguno tiene nodo en el mapa plano (planos: %d)" % planos)
	_ok(peor_suelo < 0.3, "pisan el suelo (el peor, a %.2f m)" % peor_suelo)
	var en_mapa: int = 0
	for n in _vm.entities_root.get_children():
		if str(n.name).begins_with("Wild") and (n is CharacterBody2D):
			en_mapa += 1
	_ok(en_mapa == 0, "no queda ningún animal salvaje colgando del mapa plano")
	var sin_diana: int = 0
	for a in _vivos():
		if Diana3D.de(a) == null or not Diana3D.de(a).activa:
			sin_diana += 1
	_ok(sin_diana == 0, "todos los vivos tienen su diana 3D encendida (sin ella: %d)" % sin_diana)
	_ok(int(_pl.call("get_skill_xp", "hunting")) == 0 and int(_pl.call("get_skill_level", "hunting")) <= 1, "empezar la partida no da experiencia de caza (antes subía sola a nivel 3)")


## Modo demo: pastan por su rincón sin alejarse de casa.
func _vida_tranquila() -> void:
	_prota_a(Vector2(0.0, 0.0)) # lejos del bosque
	var vivos: Array[Node] = _vivos()
	var antes: Array[Vector2] = []
	for a in vivos:
		antes.append(a.sitio)
	await _esperar(15.0)
	var movidos: int = 0
	var lejos_de_casa: int = 0
	for i in range(vivos.size()):
		if not is_instance_valid(vivos[i]):
			continue
		if vivos[i].sitio.distance_to(antes[i]) > 0.5:
			movidos += 1
		if vivos[i].sitio.distance_to(vivos[i].casa) > 45.0:
			lejos_de_casa += 1
	_ok(movidos >= vivos.size() / 3, "en 15 s pastan y se mueven (%d de %d)" % [movidos, vivos.size()])
	_ok(lejos_de_casa == 0, "y no se alejan de su zona (lejos: %d)" % lejos_de_casa)
	# Lejos del protagonista andan sin paredes, pero no se meten en el agua: uno puesto en la orilla y andando hacia el río se queda fuera
	var Agua = load("res://scripts/fisica/Agua.gd")
	var RioLago = load("res://scripts/fisica/RioLago.gd")
	var ciervo = vivos[0]
	ciervo.set_physics_process(false)
	var y_rio: float = (float(RioLago.river_y_start()) + float(RioLago.river_y_end())) * 0.5
	var orillas: Vector2 = RioLago.river_banks_at(y_rio)
	ciervo.sitio = Lugar.a_suelo(Vector2(orillas.x - 30.0, y_rio)) # 30 px al oeste de la orilla oeste
	ciervo._posar()
	ciervo.andar = Vector2(3.0, 0.0) # hacia el este, hacia el agua
	for _i in range(6 * PASOS_POR_S):
		ciervo._moverse(1.0 / PASOS_POR_S, true)
	_ok(not bool(Agua.en_agua(Lugar.en_mapa(ciervo))) and Lugar.en_mapa(ciervo).x > orillas.x - 20.0, "lejos del protagonista, un ciervo que va hacia el río se para en la orilla (a %.0f px del agua)" % (orillas.x - Lugar.en_mapa(ciervo).x))
	ciervo.sitio = ciervo.casa
	ciervo.set_physics_process(true)


func _huyen_del_protagonista() -> void:
	var ciervo = _vivos(1)[0]
	var a_2m: Vector2 = ciervo.sitio + Vector2(2.0, 0.0)
	_prota_a(a_2m)
	await _esperar(1.0)
	_ok(int(ciervo.state) == int(ciervo.AnimalState.FLEE), "un ciervo con el protagonista a 2 m echa a correr")
	await _esperar(2.0)
	_ok(ciervo.sitio.distance_to(a_2m) > 6.0, "y en 2 s se ha alejado (está a %.1f m)" % ciervo.sitio.distance_to(a_2m))


func _guardar_y_cargar() -> void:
	var zorro = _vivos(2)[0]
	zorro.set_physics_process(false)
	var donde: Vector2 = zorro.sitio
	var guardado: Dictionary = zorro.to_save_dict()
	zorro.sitio = donde + Vector2(20.0, 5.0)
	zorro.from_save_dict(guardado)
	_ok(zorro.sitio.distance_to(donde) < 0.01 and zorro.is_alive_in_ecosystem() and zorro.visible, "guardar y cargar lo deja donde estaba, vivo")
	var viejo: Dictionary = guardado.duplicate()
	viejo.erase("x_m")
	viejo.erase("z_m")
	viejo["pos_x"] = 1000.0
	viejo["pos_y"] = 2000.0
	zorro.from_save_dict(viejo)
	_ok(zorro.sitio.distance_to(Lugar.a_suelo(Vector2(1000.0, 2000.0))) < 0.01, "una partida vieja (sitio en el mapa plano) se carga en su sitio en metros")
	zorro.sitio = donde
	zorro.set_physics_process(true)
	await physics_frame


## Matarlo deja su cadáver; con [E] el protagonista lo despieza, se lleva las piezas y gana experiencia de caza.
func _despiece() -> void:
	var ciervo = _vivos(1)[0]
	ciervo.set_physics_process(false)
	var donde: Vector2 = ciervo.sitio
	_prota_a(donde + Vector2(0.8, 0.0))
	var golpe = load("res://scripts/systems/combat/DamageData.gd").new()
	golpe.amount = 999.0
	golpe.source = _pl
	ciervo.take_damage(golpe)
	await process_frame
	await _esperar(0.3)
	var zona: Node = ciervo.zona_despiece
	_ok(int(ciervo.state) == int(ciervo.AnimalState.CARCASS) and ciervo.tumbado and not ciervo.is_in_group("wild_animals"), "un golpe mortal lo deja como cadáver tumbado")
	_ok(not Diana3D.de(ciervo).activa and ciervo._forma.disabled, "al cadáver ya no se le hiere ni estorba el paso")
	_ok(is_instance_valid(zona) and zona.is_in_group("interactable") and zona.global_position.distance_to(Lugar.a_mapa(donde)) < 1.0, "y deja su zona de despiece en su sitio")
	var sel = _pl.interaction_selector
	sel.refresh()
	var opcion: Array = sel.candidates.filter(func(c): return c["target"] == zona)
	_ok(not opcion.is_empty() and str(opcion[0]["label"]).begins_with("Despiezar"), "la tecla E lo ofrece: «%s»" % (str(opcion[0]["label"]) if not opcion.is_empty() else "nada"))
	var carne_antes: int = int(_pl.inventory.get_count("raw_meat"))
	var xp_antes: int = int(_pl.call("get_skill_xp", "hunting"))
	if is_instance_valid(zona):
		zona.interact(_pl)
	await process_frame
	var carne: int = int(_pl.inventory.get_count("raw_meat"))
	_ok(int(ciervo.state) == int(ciervo.AnimalState.BUTCHERED) and not ciervo.visible and not is_instance_valid(ciervo.zona_despiece), "al despiezarlo desaparece del mundo, y su zona con él")
	_ok(carne > carne_antes, "el protagonista se lleva la carne (%d → %d)" % [carne_antes, carne])
	_ok(int(_pl.call("get_skill_xp", "hunting")) > xp_antes or int(_pl.call("get_skill_level", "hunting")) > 1, "y gana experiencia de caza")
	ciervo.respawn_from_ecosystem(1)
	await physics_frame
	_ok(ciervo.is_alive_in_ecosystem() and ciervo.visible and not ciervo.tumbado and ciervo.sitio.distance_to(ciervo.casa) < 2.0 and Diana3D.de(ciervo).activa, "al renacer vuelve junto a su nido, en pie y otra vez herible")


## Sin modo demo: con hambre van a por comida, y nadie da errores ni sale volando.
func _simulacion_completa() -> void:
	_prota_a(Vector2(0.0, 0.0))
	var vivos: Array[Node] = _vivos()
	var ocupados: Dictionary = {}
	for _t in range(20):
		await _esperar(1.0)
		for a in vivos:
			if is_instance_valid(a) and (int(a.state) in [int(a.AnimalState.SEEK_FOOD), int(a.AnimalState.EATING), int(a.AnimalState.STALK_PREY), int(a.AnimalState.CHASE_PREY)] or int(a.meals_eaten) > 0):
				ocupados[a.get_instance_id()] = true
	var perdidos: int = 0
	for a in vivos:
		if is_instance_valid(a) and (a.sitio.distance_to(a.casa) > 120.0 or absf(a.global_position.y) > 60.0):
			perdidos += 1
	_ok(ocupados.size() >= 3, "sin modo demo, con hambre salen a por comida (%d de %d en 20 s)" % [ocupados.size(), vivos.size()])
	_ok(perdidos == 0, "y ninguno se pierde ni sale volando (perdidos: %d)" % perdidos)


## Un jabalí herido se enfurece con quien le hirió, va a por él y le hace daño.
func _jabali() -> void:
	var jabali = _vivos(3)[0]
	_prota_a(jabali.sitio + Vector2(4.0, 0.0))
	await _esperar(0.2)
	var vida_antes: float = float(_pl.health_comp.current_health)
	var golpe = load("res://scripts/systems/combat/DamageData.gd").new()
	golpe.amount = 5.0
	golpe.source = _pl
	jabali.take_damage(golpe)
	_ok(int(jabali.state) == int(jabali.AnimalState.CHARGE_ATTACK) and jabali.boar_aggressor == _pl, "un jabalí herido se enfurece con quien le hirió")
	var mas_cerca: float = 99.0
	for _i in range(6 * PASOS_POR_S):
		await physics_frame
		_pl.velocity = Vector2.ZERO
		mas_cerca = minf(mas_cerca, jabali.sitio.distance_to(Lugar.de(_pl)))
	_ok(mas_cerca < 1.6, "embiste y llega hasta él (lo más cerca, %.2f m)" % mas_cerca)
	_ok(float(_pl.health_comp.current_health) < vida_antes, "y le hace daño (vida %.0f → %.0f)" % [vida_antes, float(_pl.health_comp.current_health)])
	jabali.boar_aggro_timer = 0.0
	_pl.health_comp.current_health = _pl.health_comp.max_health
	_prota_a(Vector2(0.0, 0.0))
	await _esperar(0.5)


## Un zorro hambriento con un conejo a tiro salta sobre él: o lo abate o el conejo se le zafa y huye.
func _zorro() -> void:
	var zorro = _vivos(2)[0]
	var conejo = _vivos(0)[0]
	conejo.set_physics_process(false)
	zorro.meals_eaten = 0
	zorro.is_on_reserve_day = false
	zorro.attack_cooldown = 0.0
	conejo.escaped_first_pounce = false
	conejo.sitio = zorro.sitio + Vector2(1.6, 0.0)
	zorro.food_target = conejo
	zorro.state = zorro.AnimalState.STALK_PREY
	var resuelto: bool = false
	for _i in range(4 * PASOS_POR_S):
		await physics_frame
		if int(conejo.state) == int(conejo.AnimalState.CARCASS) or conejo.escaped_first_pounce:
			resuelto = true
			break
	_ok(resuelto, "un zorro con un conejo a 1,6 m salta sobre él (%s)" % ("lo abate" if int(conejo.state) == int(conejo.AnimalState.CARCASS) else ("se le zafa" if conejo.escaped_first_pounce else "no pasa nada")))
	if int(conejo.state) == int(conejo.AnimalState.CARCASS):
		await _esperar(4.0)
		_ok(int(zorro.meals_eaten) >= 2 and int(conejo.state) == int(conejo.AnimalState.BUTCHERED), "y se lo come: queda saciado y el conejo desaparece")
	conejo.set_physics_process(true)
