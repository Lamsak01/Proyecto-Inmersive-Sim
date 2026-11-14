extends SceneTree
const MapaViejo = preload("res://tools/tests/mapa_viejo.gd") ## posiciones escritas en el mapa original → mundo

## Prueba del paso del mundo a 3D (docs/PLAN_MUNDO_3D.md). Cada paso añade aquí lo suyo. Sin ventana, ~1 min.
## Uso: timeout 300 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/fisica_3d.gd
## Termina con «FISICA 3D: PASSED» o «FAILED».

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
var _fallos: int = 0


func _ok(c: bool, txt: String) -> void:
	print(("  OK  " if c else "  FALLO  ") + txt)
	if not c:
		_fallos += 1


func _initialize() -> void:
	_paso0_conversion()
	await _paso0b_vista_de_arriba()
	await _paso0_escenario()
	await _paso1_cuerpo()
	await _paso2_pisos()
	await _paso2b_bajo_tierra()
	await _paso2c_caidas()
	await _paso3_nadar()
	await _paso2e_casa()
	await _paso2f_casa_dos_plantas()
	await _paso4_vecino_sube()
	await _paso4b_contacto()
	await _paso4c_animales()
	await _tanda4_todos_con_cuerpo()
	await _tanda4b_ganado()
	await _paso5_vista()
	_paso5b_oido()
	await _paso5c_golpes()
	await _paso5d_alcance()
	await _tanda7a_dianas()
	await _arreglo_bandido_pared()
	print("FISICA 3D: %s (%d fallos)" % ["PASSED" if _fallos == 0 else "FAILED", _fallos])
	quit(1 if _fallos > 0 else 0)


## Paso 0 y 0b: la conversión única va y vuelve sin perder nada, y el mundo es uniforme y en metros.
func _paso0_conversion() -> void:
	var peor_vuelta: float = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 58
	for _i in range(2000):
		var p := Vector2(rng.randf_range(-2000, 2000), rng.randf_range(-1500, 1500))
		var h: float = rng.randf_range(-80, 200)
		peor_vuelta = maxf(peor_vuelta, (Mapa3D.a_mapa(Mapa3D.a_3d(p, h)) - p).length())
		peor_vuelta = maxf(peor_vuelta, absf(Mapa3D.alto_a_px(Mapa3D.alto_a_3d(h)) - h))
	_ok(peor_vuelta < 1e-3, "mapa → 3D → mapa sin perder posición (peor " + str(peor_vuelta) + " px)")
	var caja := Mapa3D.tam_a_3d(Vector2(10, 10), 0.0)
	_ok(is_equal_approx(caja.x, caja.z), "0b: una caja de 10×10 px es cuadrada en 3D (" + str(caja) + ")")
	var d_ns := Mapa3D.a_3d(Vector2(0, 100)).length()
	var d_eo := Mapa3D.a_3d(Vector2(100, 0)).length()
	_ok(is_equal_approx(d_ns, d_eo), "0b: 100 px norte-sur = 100 px este-oeste en 3D")
	var g := Mapa3D.dir_a_3d(Vector2(1, 1)).normalized()
	_ok(is_equal_approx(rad_to_deg(atan2(g.z, g.x)), 45.0), "0b: la diagonal del mapa es de 45° en 3D")
	# Persona: el muñeco mide ~1,55 en su esqueleto (CharacterRig3D) por la escala del escenario
	var CA = load("res://scripts/visuals/CharacterAvatar3D.gd")
	var alto_persona: float = 1.55 * float(CA.STAGE_K)
	_ok(absf(alto_persona - 1.75) < 0.05, "0b: una persona mide %.2f m (1,75 esperado)" % alto_persona)
	var ojos := Mapa3D.alto_a_3d(load("res://scripts/visuals/WorldStageBase3D.gd").FP_EYE_HEIGHT_PX)
	_ok(ojos > 1.5 and ojos < 1.7, "0b: los ojos en 1.ª persona a %.2f m" % ojos)


## Paso 0b: la vista desde arriba sigue cuadrando con el mapa del pueblo. Una cámara como la del juego (inclinada
## INCLINACION_GRADOS, imagen más baja y luego estirada) debe pintar un punto del mapa (x, y) a altura h justo donde el
## mapa 2D pinta (x, y − h): así se veía antes del paso 0b.
func _paso0b_vista_de_arriba() -> void:
	var W := 1280
	var H := int(round(720 / Mapa3D.ESTIRA_VERTICAL))
	var vp := SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.own_world_3d = true
	root.add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.near = 0.1 * Mapa3D.K
	cam.far = 250.0 * Mapa3D.K
	var vis_h := 400.0 # píxeles del mapa que caben de alto en la pantalla
	cam.size = vis_h * Mapa3D.ESCALA / Mapa3D.ESTIRA_VERTICAL
	vp.add_child(cam)
	var centro := Vector2(412, 54)
	var giro := Basis.from_euler(Vector3(deg_to_rad(-Mapa3D.INCLINACION_GRADOS), 0.0, 0.0))
	cam.transform = Transform3D(giro, Mapa3D.a_3d(centro) + giro.z * 65.0 * Mapa3D.K)
	await process_frame
	var px_por_mapa := 720.0 / vis_h # píxeles de imagen (ya estirada a 720 de alto) por píxel del mapa
	var peor := 0.0
	for q in [[Vector2(412, 54), 0.0], [Vector2(500, 120), 30.0], [Vector2(330, -20), 60.0], [Vector2(450, 0), 12.0]]:
		var p: Vector2 = q[0]
		var h: float = q[1]
		var en_imagen := cam.unproject_position(Mapa3D.a_3d(p, h))
		var en_pantalla := Vector2(en_imagen.x, en_imagen.y * Mapa3D.ESTIRA_VERTICAL)
		var esperado := Vector2(W, 720) * 0.5 + (p - Vector2(0, h) - centro) * px_por_mapa
		peor = maxf(peor, en_pantalla.distance_to(esperado))
	vp.queue_free()
	_ok(peor < 1.0, "0b: vista desde arriba cuadra con el mapa (peor %.2f píxeles de pantalla)" % peor)


## Paso 0: el escenario del juego usa la conversión única (to_3d / to_3d_flat / tamaños).
func _paso0_escenario() -> void:
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(20):
		await physics_frame
		await process_frame
	var stage = null
	for n in root.find_children("*", "", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("WorldStage3D.gd"):
			stage = n
			break
	_ok(stage != null, "hay escenario 3D")
	if stage == null:
		return
	var p := Vector2(412, 54)
	_ok((stage.to_3d_flat(p, 10.0) - Mapa3D.a_3d(p, 10.0)).length() < 1e-5, "to_3d_flat usa Mapa3D")
	var hs: float = stage.terrain_height_px(p)
	_ok((stage.to_3d(p, 10.0) - Mapa3D.a_3d(p, 10.0 + hs)).length() < 1e-5, "to_3d suma el relieve y usa Mapa3D")
	_ok((stage.to_3d(p, -60.0) - Mapa3D.a_3d(p, -60.0)).length() < 1e-5, "bajo tierra (< −40 px) no suma relieve")
	_ok((stage.size_3d(Vector2(30, 20), 40.0) - Mapa3D.tam_a_3d(Vector2(30, 20), 40.0)).length() < 1e-5, "tamaños 3D usan Mapa3D")


## Paso 1: el protagonista anda con su cuerpo 3D: choca con los muros, cruza puertas, salta y aterriza, y sigue los
## cambios de sitio hechos a mano.
func _paso1_cuerpo() -> void:
	var pl = get_first_node_in_group("player")
	var vm = get_first_node_in_group("village_manager")
	var mc = pl.get_node("PlayerMovementController")
	mc.set_physics_process(false) # lo movemos nosotros, paso a paso
	var c: CharacterBody3D = mc.cuerpo()
	_ok(c != null, "1: el protagonista tiene cuerpo 3D")
	if c == null:
		return
	_ok(pl.collision_mask == 0, "1: el protagonista ya no choca en el mapa (choca su cuerpo 3D)")
	# Puerta de la taberna: fuera, andar hacia dentro (las puertas se abren al llegar)
	var puerta: Dictionary = {}
	for d in vm.building_doors:
		if String(d.get("building_id", "")) == "building_tavern":
			puerta = d
	_ok(not puerta.is_empty(), "1: hay puerta de la taberna")
	if puerta.is_empty():
		return
	var fuera: Vector2 = vm.get_door_outward_dir(puerta)
	var rect: Rect2 = puerta["building_rect"]
	_despejar(puerta["pos"], 40.0) # un vecino parado en el umbral (con cuerpo de contacto) hacía fallar la prueba a ratos
	vm._set_door_state(puerta, true, false, true)
	pl.global_position = puerta["pos"] + fuera * 30.0
	await _andar(pl, mc, -fuera, 120.0, 1.6)
	_ok(rect.has_point(pl.global_position), "1: cruza la puerta de la taberna y entra (" + str(pl.global_position.round()) + ")")
	_ok(c.paredes_del_mundo() > 0, "1: hay %d paredes 3D levantadas en el mundo" % c.paredes_del_mundo())
	# Muro: desde dentro, andar hacia un muro lateral sin puerta → se queda dentro
	var lado := Vector2(fuera.y, -fuera.x)
	pl.global_position = rect.get_center()
	await _andar(pl, mc, lado, 120.0, 4.0)
	_ok(rect.grow(-1.0).has_point(pl.global_position), "1: el muro para al protagonista (" + str(pl.global_position.round()) + ")")
	# Salto al aire libre: sube ~1,2 m y vuelve al suelo
	pl.global_position = puerta["pos"] + fuera * 60.0
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.3)
	var y0: float = c.global_position.y
	_ok(pl.start_jump(), "1: salta")
	var cima: float = 0.0
	for _i in range(90):
		pl.velocity = Vector2.ZERO
		mc._mover()
		await physics_frame
		cima = maxf(cima, c.global_position.y - y0)
	_ok(cima > 0.9 and cima < 1.5, "1: el salto sube %.2f m (≈1,2 esperado)" % cima)
	_ok(not pl.is_jumping() and absf(c.global_position.y - y0) < 0.05, "1: y aterriza")
	# Cambio de sitio a mano (cama, escalera, cargar partida…)
	var lejos: Vector2 = puerta["pos"] + fuera * 200.0
	pl.global_position = lejos
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.1)
	# (si justo hay alguien de pie ahí, su cuerpo lo aparta un poco: paso 4b)
	_ok(Mapa3D.a_mapa(c.global_position).distance_to(lejos) < 12.0, "1: el cuerpo sigue al protagonista cuando lo cambian de sitio (a %.1f px)" % Mapa3D.a_mapa(c.global_position).distance_to(lejos))
	mc.set_physics_process(true)


## Paso 2: en la posada se sube y se baja la escalera andando; el piso sale de la altura del cuerpo; los choques de un
## piso no estorban en el otro.
func _paso2_pisos() -> void:
	var pl = get_first_node_in_group("player")
	var vm = get_first_node_in_group("village_manager")
	var mc = pl.get_node("PlayerMovementController")
	mc.set_physics_process(false)
	var VillageTavern = load("res://scripts/systems/VillageTavern.gd") # tras montar el pueblo (usa los autoloads)
	var arriba_px: float = VillageTavern.FLOOR_1_SURFACE_H
	var abajo_px: float = VillageTavern.FLOOR_0_SURFACE_H
	# Abajo, al pie de la escalera
	vm.set_player_elevation_level(0)
	pl.global_position = VillageTavern.al_mundo(VillageTavern.STAIRS_BOTTOM_POS + Vector2(0, -4))
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.3)
	_ok(absf(mc.altura_pies_px() - abajo_px) < 0.5, "2: al pie de la escalera pisa la Planta 0 (%.1f px)" % mc.altura_pies_px())
	await _andar(pl, mc, Vector2.DOWN, 100.0, 1.0) # sube la rampa (hacia el sur) hasta la galería
	_ok(int(vm.player_elevation_level) == 1, "2: subiendo la escalera andando llega a la Planta +1 (piso %d)" % int(vm.player_elevation_level))
	_ok(absf(mc.altura_pies_px() - arriba_px) < 0.5, "2: y pisa el suelo alto (%.1f px; %.1f esperado)" % [mc.altura_pies_px(), arriba_px])
	await _andar(pl, mc, Vector2.LEFT, 100.0, 1.2) # por la galería hacia el oeste
	_ok(int(vm.player_elevation_level) == 1 and absf(mc.altura_pies_px() - arriba_px) < 0.5, "2: anda por la galería sin caerse (" + str(pl.global_position.round()) + ")")
	await _andar(pl, mc, Vector2.DOWN, 100.0, 1.0) # contra la barandilla sur
	_ok(VillageTavern.al_plano(pl.global_position).y < VillageTavern.GALLERY_EDGE_Y and int(vm.player_elevation_level) == 1, "2: la barandilla de la galería lo para (" + str(pl.global_position.round()) + ")")
	# Bajar: vuelve al desembarco y baja la rampa hacia el norte
	pl.global_position = VillageTavern.al_mundo(VillageTavern.STAIRS_TOP_POS + Vector2(0, 4))
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.2)
	await _andar(pl, mc, Vector2.UP, 100.0, 1.4)
	_ok(int(vm.player_elevation_level) == 0 and absf(mc.altura_pies_px() - abajo_px) < 0.5, "2: bajando la escalera vuelve a la Planta 0 (piso %d, %.1f px)" % [int(vm.player_elevation_level), mc.altura_pies_px()])
	# Abajo, la barandilla de arriba no estorba: quieto justo debajo de ella (en un hueco sin muebles), no lo empuja
	var bajo_barandilla: Vector2 = _hueco_bajo_barandilla(pl, VillageTavern)
	_ok(bajo_barandilla != Vector2.INF, "2: hay un hueco libre en la Planta 0 bajo la barandilla de arriba")
	pl.global_position = bajo_barandilla
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.3)
	_ok(pl.global_position.distance_to(bajo_barandilla) < 0.5 and int(vm.player_elevation_level) == 0, "2: en la Planta 0 la barandilla de arriba no estorba (" + str(pl.global_position.round()) + ")")
	mc.set_physics_process(true)


## Paso 2b: las alcantarillas (y el club) están de verdad bajo tierra; se baja y se sube con la reja.
func _paso2b_bajo_tierra() -> void:
	var pl = get_first_node_in_group("player")
	var vm = get_first_node_in_group("village_manager")
	var mc = pl.get_node("PlayerMovementController")
	mc.set_physics_process(false)
	var Suelo = load("res://scripts/fisica/Suelo.gd")
	var Red = vm.VillageUnderworld
	_ok(Suelo.es_bajo_tierra(vm.VillageClub.CLUB_CENTER, vm), "2b: el club de peleas está bajo tierra")
	Red.sewers_state(vm)["unlocked"] = true
	_ok(Red.enter_sewer_location(vm, "cistern", pl), "2b: entra en las alcantarillas")
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.5)
	var hondo: float = mc.altura_pies_px()
	_ok(int(vm.player_elevation_level) == -1 and absf(hondo - Suelo.PROFUNDIDAD_SOTANO_PX) < 1.0, "2b: abajo pisa %.1f px bajo la calle (%.1f esperado)" % [hondo, Suelo.PROFUNDIDAD_SOTANO_PX])
	await _andar(pl, mc, Vector2.LEFT, 80.0, 0.6)
	_ok(absf(mc.altura_pies_px() - Suelo.PROFUNDIDAD_SOTANO_PX) < 1.0, "2b: anda por el túnel sin subir ni caer (" + str(pl.global_position.round()) + ")")
	Red.exit_sewers_to_surface(vm)
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.5)
	_ok(int(vm.player_elevation_level) == 0 and mc.altura_pies_px() > -1.0, "2b: al salir por la reja vuelve a la calle (%.1f px)" % mc.altura_pies_px())
	mc.set_physics_process(true)


## Paso 2c: daño por caída «realista» (decisión del usuario): nada por debajo de 3 m, mortal a 8 m; las mejoras lo
## reducen; caer desde 4 m hace daño y hiere una parte del cuerpo; un salto normal, no.
func _paso2c_caidas() -> void:
	var pl = get_first_node_in_group("player")
	var vm = get_first_node_in_group("village_manager")
	var mc = pl.get_node("PlayerMovementController")
	var Cuerpo3D = load("res://scripts/fisica/Cuerpo3D.gd")
	var VillageTavern = load("res://scripts/systems/VillageTavern.gd")
	_ok(Cuerpo3D.dano_por_caida(2.9, 100.0) == 0.0, "2c: caer 2,9 m no hace daño")
	_ok(absf(Cuerpo3D.dano_por_caida(3.0, 100.0) - 9.1) < 0.5, "2c: caer 3 m quita ~9 de 100 (%.1f)" % Cuerpo3D.dano_por_caida(3.0, 100.0))
	_ok(Cuerpo3D.dano_por_caida(8.0, 100.0) >= 100.0, "2c: caer 8 m mata")
	# Caer 4 m al aire libre (como bajar de un saliente): se hace daño y hiere una parte del cuerpo
	mc.set_physics_process(false)
	var hc = pl.health_comp
	hc.current_health = hc.max_health
	var heridas_antes: int = hc.wounds.size()
	vm.set_player_elevation_level(0)
	pl.global_position = VillageTavern.al_mundo(VillageTavern.DOOR_POS) + Vector2(0, 80)
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.3)
	var c: CharacterBody3D = mc.cuerpo()
	c.global_position.y += 4.0
	await _andar(pl, mc, Vector2.ZERO, 0.0, 1.5)
	var perdida: float = hc.max_health - hc.current_health
	var esperada: float = Cuerpo3D.dano_por_caida(4.0, hc.max_health)
	_ok(absf(perdida - esperada) < 3.0, "2c: cae 4 m y se hace daño (-%.0f; ~%.0f esperado)" % [perdida, esperada])
	var zona: String = str(hc.wounds.back().get("region", "")) if hc.wounds.size() > heridas_antes else ""
	_ok(zona != "", "2c: la caída deja una herida en una parte del cuerpo (%s, %s)" % [zona, str(hc.wounds.back().get("name", "")) if zona != "" else ""])
	# Un salto normal no hace daño
	hc.current_health = hc.max_health
	pl.start_jump()
	await _andar(pl, mc, Vector2.ZERO, 0.0, 1.2)
	_ok(hc.current_health == hc.max_health, "2c: un salto normal no hace daño")
	# Con una mejora que quita la mitad, la misma caída hace la mitad
	pl.reduccion_dano_caida = 0.5
	hc.current_health = hc.max_health
	pl.recibir_dano_caida(20.0, 4.0)
	_ok(absf((hc.max_health - hc.current_health) - 10.0) < 1.5, "2c: con una mejora del 50 %% el daño se reduce a la mitad (-%.1f)" % (hc.max_health - hc.current_health))
	pl.reduccion_dano_caida = 0.0
	hc.current_health = hc.max_health
	mc.set_physics_process(true)


## Paso 3: se cruza el río nadando (en el centro no se hace pie) y se flota en el lago con la cabeza fuera.
func _paso3_nadar() -> void:
	var pl = get_first_node_in_group("player")
	var vm = get_first_node_in_group("village_manager")
	var mc = pl.get_node("PlayerMovementController")
	var Agua = load("res://scripts/fisica/Agua.gd")
	var Cuerpo3D = load("res://scripts/fisica/Cuerpo3D.gd")
	var rio_lago = load("res://scripts/fisica/RioLago.gd")
	mc.set_physics_process(false)
	vm.set_player_elevation_level(0)
	var c: CharacterBody3D = mc.cuerpo()
	# Un tramo del río en el pueblo sin puente ni rocas: de la orilla oeste a la este
	var y_rio: float = _tramo_de_rio_libre(pl, rio_lago)
	_ok(not is_nan(y_rio), "3: hay un tramo de río sin puente ni rocas para cruzar (y %.0f)" % y_rio)
	if is_nan(y_rio):
		return
	var orillas: Vector2 = rio_lago.river_banks_at(y_rio)
	pl.global_position = Vector2(orillas.x - 14.0, y_rio)
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.3)
	var aguante_antes: float = pl.stamina_comp.current_stamina if "stamina_comp" in pl else 0.0
	var nado: bool = false
	for _i in range(5 * 60):
		pl.velocity = Vector2.RIGHT * 120.0 * (mc.AGUA_NADO_MULT if mc.estado_agua() == Cuerpo3D.EnAgua.NADANDO else 1.0)
		mc._mover()
		await physics_frame
		if mc.estado_agua() == Cuerpo3D.EnAgua.NADANDO:
			nado = true
			if c.global_position.y < Agua.superficie_y(pl.global_position) - Cuerpo3D.FLOTA_M - 0.1: # se hunde más de lo que flota
				break
		if pl.global_position.x > orillas.y + 12.0:
			break
	_ok(nado, "3: en el centro del río no se hace pie: nada (hondo %.1f m)" % Agua.hondura_m(Vector2(rio_lago.river_center_x(y_rio), y_rio)))
	_ok(pl.global_position.x > orillas.y + 8.0 and mc.estado_agua() == Cuerpo3D.EnAgua.SECO, "3: cruza el río nadando y sale por la otra orilla (" + str(pl.global_position.round()) + ")")
	# En el lago: flota con la cabeza fuera
	pl.global_position = MapaViejo.a_mundo(Vector2(-880.0, 160.0))
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.5)
	var cabeza: float = c.global_position.y + 1.74 - Agua.superficie_y(pl.global_position)
	_ok(mc.estado_agua() == Cuerpo3D.EnAgua.NADANDO and cabeza > 0.2 and cabeza < 0.6, "3: en el lago flota con la cabeza fuera (%.2f m sobre el agua)" % cabeza)
	_ok(not pl.start_jump(), "3: nadando no se puede saltar")
	mc.is_stealthing = true
	mc._handle_input(1.0 / 60.0)
	_ok(not mc.is_stealthing, "3: en el agua no se puede ir agachado (los ojos quedarían bajo el agua)")
	# Paso 3b: bucear en el lago. Baja al fondo, gasta aire y sin aire pierde vida; al salir, recupera.
	var hc3 = pl.health_comp
	hc3.current_health = hc3.max_health
	var sup: float = Agua.superficie_y(pl.global_position)
	mc.buceando = true
	for _i in range(90):
		mc._respirar(1.0 / 60.0)
		await _andar(pl, mc, Vector2.ZERO, 0.0, 1.0 / 60.0)
	_ok(c.global_position.y < sup - 2.0, "3b: buceando baja al fondo (%.1f m bajo la superficie)" % (sup - c.global_position.y))
	_ok(mc.aire_s < mc.AIRE_S - 1.0, "3b: y gasta aire (%.1f s)" % mc.aire_s)
	mc.aire_s = 0.0
	for _i in range(130):
		mc._respirar(1.0 / 60.0)
	_ok(hc3.current_health < hc3.max_health, "3b: sin aire pierde vida (%.0f de %.0f)" % [hc3.current_health, hc3.max_health])
	mc.buceando = false
	for _i in range(30):
		mc._respirar(1.0 / 60.0)
		await _andar(pl, mc, Vector2.ZERO, 0.0, 1.0 / 60.0)
	_ok(c.global_position.y > sup - 1.5 and mc.aire_s > 0.0, "3b: al salir a la superficie flota otra vez y recupera aire")
	hc3.current_health = hc3.max_health
	# Paso 3c: un sitio marcado «bajo el agua» en el fondo del lago solo sale con [E] buceando
	var sel = pl.interaction_selector
	var fondo_area: Area2D = vm.marcar_bajo_el_agua(vm.add_zona_uso_mundo("PruebaFondoLago", pl.global_position, 20.0, "notice_board"))
	await physics_frame
	await physics_frame
	sel.refresh()
	var en_superficie: bool = sel.candidates.any(func(cd): return cd["area"] == fondo_area)
	mc.buceando = true
	sel.refresh()
	var buceando_ve: bool = sel.candidates.any(func(cd): return cd["area"] == fondo_area)
	mc.buceando = false
	_ok(not en_superficie and buceando_ve, "3c: lo del fondo solo se alcanza buceando (superficie %s, buceando %s)" % [str(en_superficie), str(buceando_ve)])
	fondo_area.queue_free()
	pl.global_position = MapaViejo.a_mundo(Vector2(454.0, -100.0)) # delante de la posada, fuera del agua
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.3)
	mc.set_physics_process(true)


## Paso 2e: el piso alto y el sótano de tu casa tienen altura de verdad; con [E] cambias de piso sin caerte ni hacerte daño.
func _paso2e_casa() -> void:
	var pl = get_first_node_in_group("player")
	var vm = get_first_node_in_group("village_manager")
	var mc = pl.get_node("PlayerMovementController")
	var Suelo = load("res://scripts/fisica/Suelo.gd")
	var VillageLots = load("res://scripts/systems/VillageLots.gd")
	var id: String = str(VillageLots.lots()[0]["id"])
	var st: Dictionary = VillageLots.lot(vm, id) # una casa del jugador de prueba, con las dos mejoras
	var antes: Dictionary = st.duplicate(true)
	st["payer"] = "player"
	st["status"] = "built"
	st["upgrades"] = {"upper_floor": true, "hidden_cellar": true}
	var centro: Vector2 = MapaViejo.a_mundo(VillageLots.lot_def(id)["center"]) # la casa está en su sitio del mundo (mapa ×E)
	_ok(Suelo.altura_px(centro, 1, vm) == Suelo.ALTILLO_CASA_PX, "2e: el piso alto de tu casa está a %.0f px de altura" % Suelo.altura_px(centro, 1, vm))
	_ok(Suelo.altura_px(centro, -1, vm) == Suelo.PROFUNDIDAD_SOTANO_PX, "2e: y el sótano, bajo tierra (%.0f px)" % Suelo.altura_px(centro, -1, vm))
	mc.set_physics_process(false)
	var hc = pl.health_comp
	hc.current_health = hc.max_health
	vm.set_player_elevation_level(0)
	pl.global_position = centro
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.3)
	vm.set_player_elevation_level(-1) # como con [E] en la trampilla
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.6)
	_ok(absf(mc.altura_pies_px() - Suelo.PROFUNDIDAD_SOTANO_PX) < 1.0 and hc.current_health == hc.max_health, "2e: bajas al sótano de golpe, sin caer ni hacerte daño (pies a %.1f px)" % mc.altura_pies_px())
	vm.set_player_elevation_level(1)
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.6)
	_ok(absf(mc.altura_pies_px() - Suelo.ALTILLO_CASA_PX) < 1.0, "2e: y subes al piso alto (pies a %.1f px)" % mc.altura_pies_px())
	vm.set_player_elevation_level(0)
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.3)
	for k in antes.keys():
		st[k] = antes[k]
	for k in st.keys().duplicate():
		if not antes.has(k):
			st.erase(k)


## Paso 2f: en la casona de los rentistas (casa de dos plantas) se sube andando por su escalera hasta la planta alta,
## se anda por el rellano sin caerse por el hueco y se baja otra vez.
func _paso2f_casa_dos_plantas() -> void:
	var pl = get_first_node_in_group("player")
	var vm = get_first_node_in_group("village_manager")
	var mc = pl.get_node("PlayerMovementController")
	var Marca = load("res://mapa/marca.gd")
	var id := "building_manor"
	var pie: Vector2 = Marca.mundo(id, "escalera_pie")
	var cima: Vector2 = Marca.mundo(id, "escalera_cima")
	var sube: Vector2 = (cima - pie).normalized()
	var arriba_px: float = Mapa3D.PISO_ALTO_PX
	mc.set_physics_process(false)
	vm.set_player_elevation_level(0)
	pl.global_position = pie - sube * 4.0
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.3)
	_ok(absf(mc.altura_pies_px() - Mapa3D.TARIMA_PX) < 0.5, "2f: al pie de la escalera de la casona pisa la planta baja (%.1f px)" % mc.altura_pies_px())
	await _andar(pl, mc, sube, 100.0, 0.8)
	_ok(int(vm.player_elevation_level) == 1 and absf(mc.altura_pies_px() - arriba_px) < 0.5, "2f: subiendo andando llega a la planta alta (piso %d, %.1f px)" % [int(vm.player_elevation_level), mc.altura_pies_px()])
	await _andar(pl, mc, sube.orthogonal(), 100.0, 0.4) # por el rellano, de lado
	_ok(int(vm.player_elevation_level) == 1 and absf(mc.altura_pies_px() - arriba_px) < 0.5, "2f: anda por el rellano sin caerse (" + str(pl.global_position.round()) + ")")
	pl.global_position = cima + sube * 4.0
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.2)
	await _andar(pl, mc, -sube, 100.0, 1.0)
	_ok(int(vm.player_elevation_level) == 0 and absf(mc.altura_pies_px() - Mapa3D.TARIMA_PX) < 0.5, "2f: bajando vuelve a la planta baja (piso %d, %.1f px)" % [int(vm.player_elevation_level), mc.altura_pies_px()])
	mc.set_physics_process(true)


## Paso 4a: un vecino que va a una cama de arriba sube la escalera de la posada andando y su altura crece poco a poco.
func _paso4_vecino_sube() -> void:
	var vm = get_first_node_in_group("village_manager")
	var VillageTavern = load("res://scripts/systems/VillageTavern.gd")
	var Suelo = load("res://scripts/fisica/Suelo.gd")
	var n = null
	for v in vm.VillageNeeds.living(vm):
		if v.is_conscious() and not v.is_hostile:
			n = v
			break
	_ok(n != null, "4: hay un vecino para la prueba")
	if n == null:
		return
	n.set_physics_process(false)
	n.set_process(false)
	n.global_position = VillageTavern.al_mundo(VillageTavern.STAIRS_BOTTOM_POS + Vector2(-14.0, -4.0))
	vm.set_npc_elevation_level(n, 0)
	var cama: Vector2 = VillageTavern.al_mundo(VillageTavern.guest_beds()[0])
	var h_antes: float = Suelo.altura_px(n.global_position, 0, vm)
	var salto_max: float = 0.0
	var h_max: float = h_antes
	for i in range(1200):
		n._move_towards_point(cama, 45.0, 1.0 / 60.0)
		n._finish_frame_movement(1.0 / 60.0)
		await physics_frame
		var h: float = Suelo.altura_px(n.global_position, int(n.elevation_level), vm)
		salto_max = maxf(salto_max, absf(h - h_antes))
		h_max = maxf(h_max, h)
		h_antes = h
		if n.global_position.distance_to(cama) < 8.0:
			break
	_ok(int(n.elevation_level) == 1 and n.global_position.distance_to(cama) < 8.0, "4: el vecino sube andando hasta la cama de arriba (piso %d, %s)" % [int(n.elevation_level), str(n.global_position.round())])
	_ok(absf(h_antes - VillageTavern.FLOOR_1_SURFACE_H) < 0.5, "4: y pisa el suelo alto (%.1f px)" % h_antes)
	_ok(salto_max < 2.0, "4: su altura sube poco a poco, sin saltos de golpe (mayor cambio %.2f px)" % salto_max)
	n.set_physics_process(true)
	n.set_process(true)


## Paso 4b: ya no se atraviesa a un vecino despierto (cuerpo de contacto); a uno dormido sí.
func _paso4b_contacto() -> void:
	var pl = get_first_node_in_group("player")
	var vm = get_first_node_in_group("village_manager")
	var mc = pl.get_node("PlayerMovementController")
	var VillageTavern = load("res://scripts/systems/VillageTavern.gd")
	mc.set_physics_process(false)
	vm.set_player_elevation_level(0)
	var n = null
	for v in vm.VillageNeeds.living(vm):
		if v.is_conscious() and not v.is_hostile and not v.is_sleeping:
			n = v
			break
	if n == null:
		_ok(false, "4b: hay un vecino despierto para la prueba")
		return
	n.set_physics_process(false)
	n.set_process(false)
	var inicio: Vector2 = VillageTavern.al_mundo(VillageTavern.DOOR_POS) + Vector2(-20, 80)
	# Sin nadie delante, el protagonista pasa
	n.global_position = inicio + Vector2(0, 400)
	pl.global_position = inicio
	await _andar(pl, mc, Vector2.RIGHT, 100.0, 0.8)
	var libre: bool = pl.global_position.x > inicio.x + 45.0
	_ok(libre, "4b: sin nadie delante anda sin chocar (%s)" % str(pl.global_position.round()))
	# Con un vecino delante, choca con él
	pl.global_position = inicio
	n.global_position = inicio + Vector2(30, 0)
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.1)
	_ok((n.has_meta("cuerpo3d") and is_instance_valid(n.get_meta("cuerpo3d"))), "4b: el vecino tiene su cuerpo 3D")
	var sitio_vecino: Vector2 = n.global_position
	await _andar(pl, mc, Vector2.RIGHT, 100.0, 0.8)
	# Con cuerpo completo (opción B) chocas con él: o te quedas delante o lo vas apartando poco a poco (se desplaza)
	_ok(pl.global_position.x < sitio_vecino.x - 5.0 or n.global_position.distance_to(sitio_vecino) > 3.0, "4b: no se le atraviesa sin más: choca y lo aparta (vecino desplazado %.1f px)" % n.global_position.distance_to(sitio_vecino))
	# Dormido (o caído) no tiene cuerpo: se pasa
	pl.global_position = inicio
	n.is_sleeping = true
	await _andar(pl, mc, Vector2.RIGHT, 100.0, 0.8)
	_ok(pl.global_position.x > inicio.x + 45.0, "4b: a un vecino dormido no se le choca (%s)" % str(pl.global_position.round()))
	n.is_sleeping = false
	n.set_physics_process(true)
	n.set_process(true)


## Paso 4c: los animales grandes (ciervo, jabalí, ganado adulto) estorban el paso; a los pequeños (conejo, zorro…) se
## les pasa por encima (tienen cuerpo, pero en una capa con la que nadie choca).
func _paso4c_animales() -> void:
	var pl = get_first_node_in_group("player")
	var mc = pl.get_node("PlayerMovementController")
	var Talla = load("res://scripts/fisica/TallaCuerpo3D.gd")
	var VillageTavern = load("res://scripts/systems/VillageTavern.gd")
	var grande = null
	var pequeno = null
	for a in get_nodes_in_group("wild_animals"):
		if not a.is_alive_in_ecosystem():
			continue
		if int(a.species) in [1, 3] and grande == null:
			grande = a
		elif int(a.species) in [0, 2] and pequeno == null:
			pequeno = a
	_ok(grande != null and Talla.de(grande) == Talla.ANIMAL and Talla.estorba(grande), "4c: un ciervo o jabalí estorba el paso")
	_ok(pequeno != null and not Talla.estorba(pequeno), "4c: un conejo o zorro se atraviesa")
	for g in get_nodes_in_group("livestock_animals"):
		if str(g.species) == "chicken" or str(g.stage) == "chick":
			_ok(not Talla.estorba(g), "4c: gallinas y crías se atraviesan (%s, %s)" % [g.species, g.stage])
			_ok(g is CharacterBody3D and g.is_in_group("cuerpos_3d"), "4c: pero son un cuerpo 3D, como todos")
			break
	if grande == null:
		return
	# Un jabalí o ciervo delante para al protagonista
	grande.set_physics_process(false)
	grande.set_process(false)
	var inicio: Vector2 = VillageTavern.al_mundo(VillageTavern.DOOR_POS) + Vector2(-20, 80)
	pl.global_position = inicio
	grande.sitio = Lugar.a_suelo(inicio + Vector2(30, 0))
	await _andar(pl, mc, Vector2.RIGHT, 100.0, 0.8)
	# Te para o lo apartas poco a poco (se desplaza)
	_ok(pl.global_position.x < inicio.x + 25.0 or Lugar.en_mapa(grande).distance_to(inicio + Vector2(30.0, 0.0)) > 3.0, "4c: no se atraviesa a un animal grande sin más: choca y lo aparta (animal desplazado %.1f px)" % Lugar.en_mapa(grande).distance_to(inicio + Vector2(30.0, 0.0)))
	# El ciervo, andando contra la pared de la posada, se para
	var AndarMapa = load("res://scripts/fisica/AndarMapa.gd")
	var pared: Vector2 = VillageTavern.al_mundo(VillageTavern.DOOR_POS) + Vector2(-60.0, 40.0) # al suroeste de la puerta, delante de la pared sur
	grande.sitio = Lugar.a_suelo(pared)
	pl.global_position = pared + Vector2(0.0, 40.0)
	for _i in range(12):
		await physics_frame
	_ok(grande is CharacterBody3D and not grande.has_meta("cuerpo3d"), "B: el ciervo ES su cuerpo 3D (4b-2), sin doble en el mapa plano")
	for _i in range(90):
		grande.andar = Lugar.a_suelo(Vector2.UP * 60.0)
		grande._moverse(1.0 / 60.0, false)
		await physics_frame
	_ok(VillageTavern.al_plano(Lugar.en_mapa(grande)).y > VillageTavern.RECT.end.y - 2.0, "B: y la pared de la posada lo para (y %.0f; pared en %.0f)" % [VillageTavern.al_plano(Lugar.en_mapa(grande)).y, VillageTavern.RECT.end.y])
	grande.set_physics_process(true)
	grande.set_process(true)


## Tanda 4 del paso a 3D: TODOS los personajes llevan su cuerpo 3D siempre, también lejos del protagonista; lejos, una
## pared les para igual y nadie se queda sin cuerpo por atascarse.
func _tanda4_todos_con_cuerpo() -> void:
	var pl = get_first_node_in_group("player")
	var VillageTavern = load("res://scripts/systems/VillageTavern.gd")
	var Cuerpo3D = load("res://scripts/fisica/Cuerpo3D.gd")
	var AndarMapa = load("res://scripts/fisica/AndarMapa.gd")
	var sin_cuerpo: Array[String] = []
	var total: int = 0
	for g in ["village_npcs", "wild_animals", "domestic_pets", "raiders", "enemies", "livestock_animals"]:
		for n in get_nodes_in_group(g):
			total += 1
			var es_su_cuerpo: bool = n is CharacterBody3D # tanda 4b: el ganado ya ES su cuerpo
			if not es_su_cuerpo and not (n.has_meta("cuerpo3d") and is_instance_valid(n.get_meta("cuerpo3d"))):
				sin_cuerpo.append(str(n.name))
	_ok(total > 0 and sin_cuerpo.is_empty(), "T4: los %d personajes del juego tienen cuerpo 3D (sin él: %s)" % [total, str(sin_cuerpo.slice(0, 5))])
	_ok(not ResourceLoader.exists("res://scripts/fisica/CuerposDelPueblo3D.gd") and not ResourceLoader.exists("res://scripts/fisica/CuerposCercanos3D.gd"), "T4: ya no existen el reparto por cercanía ni los cuerpos de contacto")
	# Un vecino a más de 1.500 px del protagonista (~84 m) anda contra la pared sur de la posada: su cuerpo la respeta
	var vm = get_first_node_in_group("village_manager")
	var n = null
	for v in vm.VillageNeeds.living(vm):
		if v.is_conscious() and not v.is_hostile and not v.is_sleeping:
			n = v
			break
	if n == null:
		_ok(false, "T4: hay un vecino despierto para la prueba")
		return
	n.set_physics_process(false)
	n.set_process(false)
	var pared: Vector2 = VillageTavern.al_mundo(VillageTavern.DOOR_POS) + Vector2(-60.0, 40.0)
	var prota_antes: Vector2 = pl.global_position
	pl.global_position = pared + Vector2(0.0, 1600.0)
	n.global_position = pared
	for _i in range(20):
		await physics_frame
	_ok(n.has_meta("cuerpo3d") and is_instance_valid(n.get_meta("cuerpo3d")) and pl.global_position.distance_to(n.global_position) > 1500.0, "T4: lejos del protagonista (%.0f px) el vecino sigue con su cuerpo" % pl.global_position.distance_to(n.global_position))
	for _i in range(90):
		n.velocity = Vector2.UP * 60.0
		AndarMapa.paso(n, 1.0 / 60.0)
		await physics_frame
	_ok(VillageTavern.al_plano(n.global_position).y > VillageTavern.RECT.end.y - 2.0, "T4: y la pared de la posada lo para aunque no haya nadie mirando (y %.0f; pared en %.0f)" % [VillageTavern.al_plano(n.global_position).y, VillageTavern.RECT.end.y])
	# Red contra atascos: tras ATASCO_S empujando contra la pared, se cuela un momento (atajo apuntado en el plan) y
	# conserva su cuerpo
	var colados_antes: int = Cuerpo3D.colados
	for _i in range(int((Cuerpo3D.ATASCO_S + 2.0) * 60.0)):
		n.velocity = Vector2.UP * 60.0
		AndarMapa.paso(n, 1.0 / 60.0)
		await physics_frame
	_ok(Cuerpo3D.colados > colados_antes and (n.has_meta("cuerpo3d") and is_instance_valid(n.get_meta("cuerpo3d"))), "T4: atascado %d s contra la pared, se cuela un momento sin perder el cuerpo" % int(Cuerpo3D.ATASCO_S))
	n.velocity = Vector2.ZERO
	n.global_position = pared + Vector2(0.0, 60.0)
	pl.global_position = prota_antes
	n.set_physics_process(true)
	n.set_process(true)
	for _i in range(10):
		await physics_frame


## Tanda 4b del paso a 3D: el ganado del rancho ES su cuerpo 3D. Vive en el escenario 3D, en metros, dentro de su
## corral y pisando el suelo; no queda de él ningún nodo en el mapa plano. Pasea, y un adulto estorba el paso.
func _tanda4b_ganado() -> void:
	var vm = get_first_node_in_group("village_manager")
	var pl = get_first_node_in_group("player")
	var mc = pl.get_node("PlayerMovementController")
	var Base = load("res://scripts/fisica/CuerpoBase3D.gd")
	var rebano: Array = vm.VillageHousing.state(vm)["ranch_herd"]
	var ganado: Array[Node] = get_nodes_in_group("livestock_animals")
	var corral: Rect2 = vm.VillageHousing.ranch_pen_m()
	var planos: int = 0
	var fuera: int = 0
	var peor_suelo: float = 0.0
	for g in ganado:
		if not (g is CharacterBody3D) or g is Node2D or g.has_meta("cuerpo3d"):
			planos += 1
			continue
		var p: Vector3 = g.global_position
		if not corral.grow(0.01).has_point(Vector2(p.x, p.z)):
			fuera += 1
		peor_suelo = maxf(peor_suelo, absf(p.y - float(Base.suelo_y(p.x, p.z, 0, vm))))
	_ok(ganado.size() == rebano.size() and ganado.size() > 0, "4b: hay un animal por cada ejemplar del rebaño (%d de %d)" % [ganado.size(), rebano.size()])
	_ok(planos == 0, "4b: todos SON un cuerpo 3D y ninguno tiene nodo en el mapa plano (planos: %d)" % planos)
	_ok(fuera == 0, "4b: todos dentro de su corral (fuera: %d)" % fuera)
	_ok(peor_suelo < 0.25, "4b: pisan el suelo (el peor, a %.2f m)" % peor_suelo)
	_ok(vm.entities_root.find_children("*", "Node2D", false, false).filter(func(n): return n.is_in_group("ranch_livestock")).is_empty(), "4b: no queda ganado colgando del mapa plano")
	# De día pasean: en 12 s alguno se ha movido
	var reloj: Node = root.get_node("/root/WorldClock")
	var hora_antes: int = int(reloj.get("current_hour"))
	reloj.set("current_hour", 12)
	var antes: Array[Vector3] = []
	for g in ganado:
		antes.append(g.global_position)
	for _i in range(12 * 60):
		await physics_frame
	var movidos: int = 0
	for i in range(ganado.size()):
		if ganado[i].global_position.distance_to(antes[i]) > 0.3:
			movidos += 1
	_ok(movidos > 0, "4b: de día pasean por el corral (%d de %d se han movido)" % [movidos, ganado.size()])
	# Un adulto grande estorba: andando contra él, o te para o lo apartas, pero no lo atraviesas sin más
	var grande: Node = null
	for g in ganado:
		if str(g.species) in ["cow", "bull"] and str(g.stage) == "adult":
			grande = g
			break
	_ok(grande != null, "4b: hay una vaca o un toro adulto en el rebaño")
	if grande != null:
		for g in ganado:
			g.set_physics_process(false)
		var centro := Vector3(corral.get_center().x, 0.0, corral.get_center().y)
		for g in ganado: # los demás, a una esquina: que no estorben
			g.global_position = Vector3(corral.position.x, g.global_position.y, corral.position.y)
		grande.global_position = Vector3(centro.x, float(Base.suelo_y(centro.x, centro.z, 0, vm)), centro.z)
		var sitio_vaca: Vector3 = grande.global_position
		var inicio: Vector2 = Mapa3D.a_mapa(centro) + Vector2(-30.0, 0.0)
		pl.global_position = inicio
		await _andar(pl, mc, Vector2.ZERO, 0.0, 0.3)
		await _andar(pl, mc, Vector2.RIGHT, 100.0, 0.8)
		var avance_px: float = pl.global_position.x - inicio.x
		var apartada_m: float = grande.global_position.distance_to(sitio_vaca)
		_ok(avance_px < 55.0 or apartada_m > 0.1, "4b: una vaca adulta estorba el paso (avanzas %.0f px de 80; ella se aparta %.2f m)" % [avance_px, apartada_m])
		_ok(corral.grow(0.01).has_point(Vector2(grande.global_position.x, grande.global_position.z)), "4b: y al apartarla no sale de su corral")
		for g in ganado:
			g.set_physics_process(true)
	reloj.set("current_hour", hora_antes)



## Paso 5a: la vista con alturas. Desde el salón se ve el borde de la galería; bajo la galería no se ve a quien está encima.
func _paso5_vista() -> void:
	var vm = get_first_node_in_group("village_manager")
	var pl = get_first_node_in_group("player")
	var VillageTavern = load("res://scripts/systems/VillageTavern.gd")
	# El salón (Planta 0) va de la galería (y -166) a la pared sur (y -132); x 440 evita un tabique en x 479
	var borde_galeria: Vector2 = VillageTavern.al_mundo(Vector2(440.0, VillageTavern.GALLERY_EDGE_Y - 6.0))
	var salon: Vector2 = VillageTavern.al_mundo(Vector2(440.0, VillageTavern.GALLERY_EDGE_Y + 16.0))
	var bajo_galeria: Vector2 = VillageTavern.al_mundo(Vector2(440.0, VillageTavern.GALLERY_EDGE_Y - 30.0))
	var fuera: Vector2 = VillageTavern.al_mundo(Vector2(330.0, -100.0)) # al suroeste: la mirada cruza la pared sur lejos de la puerta
	_ok(vm.ve(salon, 0, borde_galeria, 1), "5: desde el salón se ve a quien está en el borde de la galería")
	_ok(vm.ve(borde_galeria, 1, salon, 0), "5: y desde la galería se ve el salón")
	_ok(not vm.ve(bajo_galeria, 0, borde_galeria, 1), "5: bajo la galería no se ve a quien está encima")
	_ok(not vm.ve(fuera, 0, salon, 0), "5: desde fuera la pared de la posada tapa el salón")
	_ok(not vm.ve(salon, 0, salon + Vector2(10, 0), -1), "5: bajo tierra no se ve desde la calle")
	# Un vecino en la galería es testigo de lo que pasa en el salón (antes, en otro piso, no lo era)
	var n = null
	for v in vm.VillageNeeds.living(vm):
		if v.is_conscious() and not v.is_hostile and not v.is_sleeping:
			n = v
			break
	if n == null:
		_ok(false, "5: hay un vecino para la prueba")
		return
	n.set_physics_process(false)
	n.global_position = borde_galeria
	vm.set_npc_elevation_level(n, 1)
	pl.global_position = salon
	vm.set_player_elevation_level(0)
	var testigo = vm._find_conscious_witness_near(salon, 120.0, null) # el más cercano: puede ser otro que ande por el salón
	_ok(testigo == n or (testigo != null and testigo.global_position.distance_to(salon) <= n.global_position.distance_to(salon)), "5: un vecino en la galería es testigo de lo que pasa en el salón (o uno más cercano)")
	n.global_position = fuera + Vector2(0, 400)
	vm.set_npc_elevation_level(n, 0)
	n.set_physics_process(true)


## Paso 5b: el oído con alturas. Por la galería abierta se oye entero; a través del suelo, a un tercio; bajo tierra, casi nada.
func _paso5b_oido() -> void:
	var vm = get_first_node_in_group("village_manager")
	var VillageTavern = load("res://scripts/systems/VillageTavern.gd")
	var borde_galeria: Vector2 = VillageTavern.al_mundo(Vector2(440.0, VillageTavern.GALLERY_EDGE_Y - 6.0))
	var salon: Vector2 = VillageTavern.al_mundo(Vector2(440.0, VillageTavern.GALLERY_EDGE_Y + 16.0))
	var bajo_galeria: Vector2 = VillageTavern.al_mundo(Vector2(440.0, VillageTavern.GALLERY_EDGE_Y - 30.0))
	_ok(vm.oye(salon, 0, borde_galeria, 1) == 1.0, "5b: un ruido en el salón llega entero al borde de la galería")
	_ok(vm.oye(bajo_galeria, 0, borde_galeria, 1) == 0.35, "5b: a través del suelo de la galería llega a un tercio")
	_ok(vm.oye(salon, 0, salon, -1) == 0.1, "5b: de la calle a bajo tierra casi no llega")
	root.get_node("AudioManager").emit_noise(salon, 160.0, 0, "combat") # con vecinos en varios pisos: no debe fallar


## Paso 5c: golpes por altura de los pies; flechas con altura (plana da, muy alta pasa por encima, hacia abajo se clava).
func _paso5c_golpes() -> void:
	var vm = get_first_node_in_group("village_manager")
	var pl = get_first_node_in_group("player")
	var VillageTavern = load("res://scripts/systems/VillageTavern.gd")
	var borde_galeria: Vector2 = VillageTavern.al_mundo(Vector2(440.0, VillageTavern.GALLERY_EDGE_Y - 6.0))
	var salon: Vector2 = VillageTavern.al_mundo(Vector2(440.0, VillageTavern.GALLERY_EDGE_Y + 16.0))
	var pie: Vector2 = VillageTavern.al_mundo(VillageTavern.STAIRS_BOTTOM_POS + Vector2(0, 10))
	_ok(not vm.alcanza(salon, 0, borde_galeria, 1), "5c: desde el salón no se golpea a quien está en la galería")
	_ok(vm.alcanza(pie, 0, pie + Vector2(0, 12), 0), "5c: en la escalera sí se golpea a quien va unos peldaños más arriba")
	var ciervo = null
	for a in get_nodes_in_group("wild_animals"):
		if int(a.species) == 1 and a.is_alive_in_ecosystem():
			ciervo = a
			break
	if ciervo == null:
		_ok(false, "5c: hay un ciervo para probar las flechas")
		return
	ciervo.set_physics_process(false)
	var sitio: Vector2 = VillageTavern.al_mundo(VillageTavern.DOOR_POS) + Vector2(-20.0, 80.0)
	vm.set_player_elevation_level(0)
	pl.global_position = sitio
	ciervo.sitio = Lugar.a_suelo(sitio + Vector2(60.0, 0.0))
	await physics_frame
	var vida: float = ciervo.current_hp
	await _flechazo(pl, sitio, 0.0)
	_ok(ciervo.current_hp < vida, "5c: una flecha plana a 60 px da al ciervo")
	vida = ciervo.current_hp
	await _flechazo(pl, sitio, 1.13)
	_ok(ciervo.current_hp == vida, "5c: apuntando muy arriba pasa por encima")
	var clavada: bool = await _flechazo(pl, sitio, -1.13)
	_ok(ciervo.current_hp == vida and clavada, "5c: apuntando al suelo se clava antes de llegar")
	# 7a-2: la flecha vuela de verdad. Contra la pared sur de la posada se clava en ella; no la atraviesa.
	var pared: Vector2 = VillageTavern.al_mundo(VillageTavern.DOOR_POS) + Vector2(-60.0, 60.0)
	pl.global_position = pared
	await physics_frame
	await physics_frame
	var cuerpo = load("res://scripts/fisica/AndarMapa.gd").cuerpo(pl)
	var dano = load("res://scripts/systems/combat/DamageData.gd").new()
	var f = load("res://scripts/systems/combat/Flecha3D.gd").disparar(pl, cuerpo.global_position + Vector3(0.0, 1.4, -0.5), Vector3(0.0, 0.0, -1.0), 16.8, 12.0, dano, false)
	for _i in range(90):
		await physics_frame
		if f.clavada:
			break
	var muro_z: float = Mapa3D.a_3d(VillageTavern.al_mundo(Vector2(0.0, VillageTavern.RECT.end.y))).z
	_ok(f.clavada and f.global_position.z > muro_z - 0.6, "7a-2: una flecha contra la pared de la posada se clava en ella (z %.2f; pared en %.2f)" % [f.global_position.z, muro_z])
	_ok(f.global_position.y > cuerpo.global_position.y + 0.5, "7a-2: y se clava a media altura, no en el suelo (a %.2f m del suelo)" % (f.global_position.y - cuerpo.global_position.y))
	_ok(not ResourceLoader.exists("res://scripts/systems/combat/ArrowProjectile.gd"), "7a-2: ya no existe la flecha del mapa plano")
	ciervo.set_physics_process(true)


## Paso 5d: con [E] se llega a lo que está a tu altura: a un vecino unos peldaños más arriba sí; a uno en la galería, desde
## el salón, no; y a la cama de arriba desde abajo tampoco.
func _paso5d_alcance() -> void:
	var vm = get_first_node_in_group("village_manager")
	var pl = get_first_node_in_group("player")
	var sel = pl.interaction_selector
	var VillageTavern = load("res://scripts/systems/VillageTavern.gd")
	var n = null
	for v in vm.VillageNeeds.living(vm):
		if v.is_conscious() and not v.is_hostile and not v.is_sleeping:
			n = v
			break
	if n == null:
		_ok(false, "5d: hay un vecino para la prueba")
		return
	n.set_physics_process(false)
	var pie: Vector2 = VillageTavern.al_mundo(VillageTavern.STAIRS_BOTTOM_POS + Vector2(0, 6))
	vm.set_player_elevation_level(0)
	pl.global_position = pie
	n.global_position = pie + Vector2(0, 14) # unos peldaños más arriba (la rampa sube hacia el sur)
	vm.set_npc_elevation_level(n, 0)
	await physics_frame
	await physics_frame
	sel.refresh()
	_ok(sel.candidates.any(func(c): return c["target"] == n), "5d: en la escalera se llega a hablar con quien va unos peldaños más arriba")
	var salon: Vector2 = VillageTavern.al_mundo(Vector2(440.0, VillageTavern.GALLERY_EDGE_Y + 16.0))
	pl.global_position = salon
	n.global_position = VillageTavern.al_mundo(Vector2(440.0, VillageTavern.GALLERY_EDGE_Y - 6.0))
	vm.set_npc_elevation_level(n, 1)
	await physics_frame
	await physics_frame
	sel.refresh()
	_ok(not sel.candidates.any(func(c): return c["target"] == n), "5d: desde el salón no se llega a quien está en la galería")
	_ok(not sel.candidates.any(func(c): return c["station"] == "tavern_bed"), "5d: ni a las camas de arriba")
	n.global_position = salon + Vector2(0, 300)
	vm.set_npc_elevation_level(n, 0)
	n.set_physics_process(true)


## Tanda 7a del paso a 3D: los golpes buscan la diana 3D de cada personaje. Ya no hay zonas de golpe en el mapa plano.
## El tajo de espada hiere a quien tiene delante, no a quien tiene detrás ni a quien está en el piso de arriba; a un
## conejo metido en su madriguera no se le puede herir.
func _tanda7a_dianas() -> void:
	var vm = get_first_node_in_group("village_manager")
	var pl = get_first_node_in_group("player")
	var VillageTavern = load("res://scripts/systems/VillageTavern.gd")
	var planas: int = 0
	var sin_diana: Array[String] = []
	for g in ["player", "village_npcs", "wild_animals", "domestic_pets", "raiders", "enemies"]:
		for n in get_nodes_in_group(g):
			if n.get_node_or_null("Hurtbox") != null:
				planas += 1
			if n.has_method("take_damage") and (n is CharacterBody2D or n is CharacterBody3D) and Diana3D.de(n) == null:
				sin_diana.append(str(n.name))
	_ok(planas == 0 and not ResourceLoader.exists("res://scripts/systems/combat/Hurtbox.gd"), "7a: no queda ninguna zona de golpe en el mapa plano (quedan %d)" % planas)
	_ok(sin_diana.is_empty(), "7a: todo personaje que puede recibir daño tiene su diana 3D (sin ella: %s)" % str(sin_diana.slice(0, 5)))
	var ciervo = null
	var conejo = null
	for a in get_nodes_in_group("wild_animals"):
		if not a.is_alive_in_ecosystem():
			continue
		if int(a.species) == 1 and ciervo == null:
			ciervo = a
		elif int(a.species) == 0 and conejo == null:
			conejo = a
	if ciervo == null or conejo == null:
		_ok(false, "7a: hay un ciervo y un conejo para la prueba")
		return
	ciervo.set_physics_process(false)
	conejo.set_physics_process(false)
	var cc = pl.combat_ctrl
	var sitio: Vector2 = VillageTavern.al_mundo(VillageTavern.DOOR_POS) + Vector2(-20.0, 140.0)
	_despejar(sitio, 120.0)
	vm.set_player_elevation_level(0)
	pl.global_position = sitio
	# Delante, a 40 px: le da
	ciervo.sitio = Lugar.a_suelo(sitio + Vector2(40.0, 0.0))
	_ok(await _tajo(cc, ciervo), "7a: el tajo hiere al ciervo que tienes delante, a 40 px")
	# Detrás, a 60 px: no
	ciervo.sitio = Lugar.a_suelo(sitio + Vector2(-60.0, 0.0))
	_ok(not await _tajo(cc, ciervo), "7a: y no al que tienes detrás")
	# Muy lejos delante (120 px): no
	ciervo.sitio = Lugar.a_suelo(sitio + Vector2(120.0, 0.0))
	_ok(not await _tajo(cc, ciervo), "7a: ni al que está fuera de alcance (120 px)")
	# Un conejo en su madriguera no recibe golpes; al salir, sí
	conejo.sitio = Lugar.a_suelo(sitio + Vector2(30.0, 0.0))
	conejo.entrar_en_madriguera(60.0)
	_ok(not await _tajo(cc, conejo), "7a: a un conejo metido en su madriguera no se le hiere")
	conejo.casa = Lugar.a_suelo(sitio + Vector2(30.0, 0.0))
	conejo.salir_de_madriguera()
	conejo.sitio = Lugar.a_suelo(sitio + Vector2(30.0, 0.0))
	_ok(await _tajo(cc, conejo), "7a: y al salir de la madriguera, sí")
	# Otro piso: desde el salón de la posada no se hiere a quien está en la galería, justo encima
	var n = null
	for v in vm.VillageNeeds.living(vm):
		if v.is_conscious() and not v.is_hostile and not v.is_sleeping:
			n = v
			break
	if n != null:
		n.set_physics_process(false)
		var salon: Vector2 = VillageTavern.al_mundo(Vector2(440.0, VillageTavern.GALLERY_EDGE_Y + 16.0))
		_despejar(salon, 60.0)
		pl.global_position = salon
		n.global_position = VillageTavern.al_mundo(Vector2(440.0, VillageTavern.GALLERY_EDGE_Y - 6.0))
		vm.set_npc_elevation_level(n, 1)
		_ok(not await _tajo(cc, n, (n.global_position - salon).normalized()), "7a: desde el salón el tajo no llega a quien está en la galería, por su altura de verdad")
		ciervo.sitio = Lugar.a_suelo(salon + Vector2(0.0, -22.0)) # en el salón, a la misma distancia en el mapa
		_ok(await _tajo(cc, ciervo, Vector2.UP), "7a: pero sí a quien está en tu mismo piso a esa distancia")
		n.global_position = salon + Vector2(0, 300)
		vm.set_npc_elevation_level(n, 0)
		n.set_physics_process(true)
	ciervo.set_physics_process(true)
	conejo.set_physics_process(true)


## Da un tajo de prueba (la búsqueda de dianas del arma, sin animación) y dice si ha alcanzado a `quien`.
func _tajo(cc, quien, hacia: Vector2 = Vector2.RIGHT) -> bool:
	await process_frame # lo aplazado al final del fotograma (encender o apagar la forma de una diana)
	for _i in range(3): # que su cuerpo 3D y su diana lleguen a su sitio
		await physics_frame
	cc.current_aim_dir = hacia # después de esperar: el mando la cambia en cada fotograma según el ratón
	cc._swing_hit_targets.clear()
	cc._dano_golpe = load("res://scripts/systems/combat/DamageData.gd").new()
	cc._dano_golpe.amount = 0.01
	cc._dano_golpe.source = cc.player
	cc._buscar_dianas_del_tajo()
	return quien in cc._swing_hit_targets


## Arreglo 2026-11-10 (fallo visto por el usuario): un bandido que huye ya no atraviesa las paredes; si se queda
## atascado contra un muro, se da por huido.
func _arreglo_bandido_pared() -> void:
	var pl = get_first_node_in_group("player")
	var VillageTavern = load("res://scripts/systems/VillageTavern.gd")
	var r = load("res://scripts/enemies/Raider.gd").crear(self) # ya ES un cuerpo 3D (tanda 4b-3b): nace en el escenario 3D
	var dentro: Vector2 = VillageTavern.al_mundo(Vector2(500.0, VillageTavern.GALLERY_EDGE_Y + 16.0)) # salón; la pared este está en x 608
	var pared_x: float = VillageTavern.al_mundo(Vector2(VillageTavern.RECT.end.x, dentro.y)).x
	r.setup("bandit", Lugar.a_suelo(dentro), 1.0)
	r.fleeing = true
	r.target = null
	var max_x: float = dentro.x
	for _i in range(300): # ~1,4 s hasta la pared + 2 s atascado
		await physics_frame
		if not is_instance_valid(r):
			break
		max_x = maxf(max_x, Lugar.en_mapa(r).x)
	_ok(max_x < pared_x + 2.0, "arreglo: un bandido huyendo no atraviesa la pared de la posada (llega a x %.0f; pared en %.0f)" % [max_x, pared_x])
	_ok(not is_instance_valid(r), "arreglo: atascado contra el muro, se da por huido y desaparece")
	if is_instance_valid(r):
		r.queue_free()


## Dispara una flecha desde `desde` (mapa) hacia el este, con la `pendiente` dada (lo que sube por cada metro que
## avanza), sin apuntar a ojo (como en la vista desde arriba), y espera a que acabe su vuelo. Devuelve la flecha.
func _flechazo(pl, desde: Vector2, pendiente: float):
	var cuerpo = load("res://scripts/fisica/AndarMapa.gd").cuerpo(pl)
	var origen: Vector3 = Mapa3D.a_3d(desde + Vector2(12.0, 0.0))
	origen.y = cuerpo.global_position.y + 1.4
	var dano = load("res://scripts/systems/combat/DamageData.gd").new()
	dano.amount = 5.0
	var f = load("res://scripts/systems/combat/Flecha3D.gd").disparar(pl, origen, Vector3(1.0, pendiente, 0.0), 16.8, 6.7, dano, false)
	var acabo: Array = [false, false] # [terminó su vuelo, y fue clavada en el suelo o en una pared]
	f.tree_exiting.connect(func(): acabo[0] = true)
	for _i in range(90):
		await physics_frame
		if acabo[0] or f.clavada:
			acabo[1] = not acabo[0] and f.clavada
			break
	return acabo[1]


## Todos los personajes que se pueden apartar menos el protagonista: los que aún son nodos del mapa plano (con su
## cuerpo 3D) y los que ya SON su cuerpo y saben decir su `sitio` (animales salvajes; el ganado no sale de su corral).
func _personajes() -> Array[Node]:
	var out: Array[Node] = []
	for c in get_nodes_in_group("cuerpos_3d"):
		var n: Node = c.get("actor") as Node if c.get("actor") != null else (c if "sitio" in c else null)
		if is_instance_valid(n) and not n.is_in_group("player"):
			out.append(n)
	return out


## Aparta (300 px al sur) a los vecinos y animales que estén a menos de `radio` de `pos`, para que no estorben a la prueba.
func _despejar(pos: Vector2, radio: float) -> void:
	for n in _personajes():
		if Lugar.en_mapa(n).distance_to(pos) >= radio:
			continue
		if n is Node2D:
			n.global_position += Vector2(0.0, 300.0)
		else:
			n.sitio = Lugar.a_suelo(Lugar.en_mapa(n) + Vector2(0.0, 300.0))


## ¿Hay algún vecino o animal dentro de `zona`?
func _alguien_en(zona: Rect2) -> bool:
	for n in _personajes():
		if zona.has_point(Lugar.en_mapa(n)):
			return true
	return false


## La «y» de un tramo del río en el pueblo que se puede cruzar en línea recta (sin puente ni rocas). NAN si no hay.
func _tramo_de_rio_libre(pl, rio_lago) -> float:
	var espacio: PhysicsDirectSpaceState2D = pl.get_world_2d().direct_space_state
	var agua: Array[RID] = [pl.get_rid()]
	for n in get_nodes_in_group("agua_2d"):
		agua.append((n as CollisionObject2D).get_rid())
	for y in range(-150, 300, 10):
		var o: Vector2 = rio_lago.river_banks_at(float(y))
		if rio_lago.is_in_river_crossing(Vector2((o.x + o.y) * 0.5, float(y)), 25.0) or o.y - o.x < 40.0:
			continue
		var libre := not _alguien_en(Rect2(o.x - 20.0, y - 14.0, o.y - o.x + 40.0, 28.0))
		for dy in [-6.0, 0.0, 6.0]: # un pasillo del ancho del cuerpo
			var q := PhysicsRayQueryParameters2D.create(Vector2(o.x - 16.0, y + dy), Vector2(o.y + 16.0, y + dy), 1, agua)
			if not espacio.intersect_ray(q).is_empty():
				libre = false
		if libre:
			return float(y)
	return NAN


## Un punto bajo la barandilla sur de la galería donde en la Planta 0 no hay nada (solo la barandilla de arriba).
func _hueco_bajo_barandilla(pl, VillageTavern) -> Vector2:
	var q := PhysicsShapeQueryParameters2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 8.0
	q.shape = circulo
	q.collision_mask = 0xFFFFFFFF
	q.exclude = [pl.get_rid()]
	var r: Rect2 = VillageTavern.RECT
	for x in range(int(r.position.x) + 20, int(r.end.x) - 20, 4):
		var p: Vector2 = VillageTavern.al_mundo(Vector2(float(x), -168.0))
		q.transform = Transform2D(0.0, p)
		var solo_arriba := true
		for h in pl.get_world_2d().direct_space_state.intersect_shape(q, 16):
			if not (h["collider"] as Node).is_in_group("choques_piso_1"):
				solo_arriba = false
		if solo_arriba:
			return p
	return Vector2.INF


func _andar(pl, mc, dir: Vector2, vel: float, segundos: float) -> void:
	for _i in range(int(segundos * 60.0)):
		pl.velocity = dir * vel
		mc._mover()
		await physics_frame
