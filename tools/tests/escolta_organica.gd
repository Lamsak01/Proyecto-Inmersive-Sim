extends SceneTree

## Prueba de la detención sin atajos (Claude Code, 2026-11-13; scripts/systems/EscoltaPolicial.gd): el preso se
## entrega en la plaza; el guardia viene andando, lo esposa y lo lleva a la celda; nadie salta de sitio; el preso entra
## andando y la reja cerrada lo retiene. Sin ventana, unos minutos:
##   timeout 900 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/escolta_organica.gd
## Termina con «ESCOLTA: PASSED» o «FAILED».

const MapaViejo = preload("res://tools/tests/mapa_viejo.gd")
const Marca = preload("res://mapa/marca.gd")
const PLAZA_ORIGINAL := Vector2(430.0, 76.0) ## mapa original: centro de la plaza, lejos de la comisaría
const TOPE_S: float = 240.0                  ## la prueba se rinde si en este rato no hay preso en la celda
const SALTO_MAX_PX: float = 10.0             ## moverse más que esto en un fotograma es un salto de sitio
const EN_CELDA_PX: float = 6.0
const EMPUJE_PX_S: float = 120.0             ## el preso intenta salir de la celda andando hacia la reja
const EMPUJE_S: float = 3.0
const FPS: float = 60.0

var _fallos: int = 0


func _ok(c: bool, txt: String) -> void:
	print(("  OK  " if c else "  FALLO  ") + txt)
	if not c:
		_fallos += 1


func _initialize() -> void:
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(60):
		await physics_frame
	var vm = get_first_node_in_group("village_manager")
	var pl: CharacterBody2D = get_first_node_in_group("player")
	root.get_node("/root/WorldClock").set("current_hour", 11)
	pl.global_position = MapaViejo.a_mundo(PLAZA_ORIGINAL)
	await physics_frame
	var guardia = vm._find_nearest_police_officer(pl.global_position)
	_ok(guardia != null, "hay un guardia en pie")
	if guardia == null:
		return _fin()
	var lejos: float = guardia.global_position.distance_to(pl.global_position)
	vm.start_police_escort_to_jail(pl, guardia)
	_ok(guardia.global_position.distance_to(pl.global_position) == lejos, "el guardia no aparece al lado: sigue a %d px" % int(lejos))
	await _seguir(vm, pl, guardia)
	var celda: Vector2 = Marca.mundo(vm.ID_COMISARIA, Marca.CELDA)
	_ok(bool(vm.player_in_jail), "el preso acaba en la celda")
	_ok(pl.global_position.distance_to(celda) <= EN_CELDA_PX, "ha llegado andando al centro de la celda (a %.1f px)" % pl.global_position.distance_to(celda))
	await _empujar_hacia_reja(vm, pl, celda)
	_fin()


## Fotograma a fotograma hasta que el preso esté en la celda (o se suelte): ni él ni el guardia saltan de sitio.
func _seguir(vm, pl: CharacterBody2D, guardia) -> void:
	var antes_pl: Vector2 = pl.global_position
	var antes_g: Vector2 = guardia.global_position
	var salto_pl: float = 0.0
	var salto_g: float = 0.0
	var esposado_s: float = -1.0
	for i in range(int(TOPE_S * FPS)):
		await physics_frame
		salto_pl = maxf(salto_pl, pl.global_position.distance_to(antes_pl))
		salto_g = maxf(salto_g, guardia.global_position.distance_to(antes_g))
		antes_pl = pl.global_position
		antes_g = guardia.global_position
		if esposado_s < 0.0 and vm.escolta.fase != vm.escolta.Fase.ACERCARSE:
			esposado_s = i / FPS
		if not vm.player_being_escorted_to_jail:
			print("  fin de la escolta a los %.1f s (esposado a los %.1f s)" % [i / FPS, esposado_s])
			break
	_ok(esposado_s >= 0.0, "el guardia llega andando y pone las esposas")
	_ok(salto_pl <= SALTO_MAX_PX, "el preso no salta de sitio (paso máximo %.1f px)" % salto_pl)
	_ok(salto_g <= SALTO_MAX_PX, "el guardia no salta de sitio (paso máximo %.1f px)" % salto_g)


## Con la reja cerrada, el preso anda hacia ella y no sale.
func _empujar_hacia_reja(vm, pl: CharacterBody2D, celda: Vector2) -> void:
	var mc = pl.get_node("PlayerMovementController")
	mc.set_physics_process(false)
	var reja: Vector2 = Marca.mundo(vm.ID_COMISARIA, Marca.CELDA_PUERTA)
	var salida: Vector2 = Marca.mundo(vm.ID_COMISARIA, Marca.CELDA_SALIDA)
	var dir: Vector2 = (salida - celda).normalized()
	for _i in range(int(EMPUJE_S * FPS)):
		pl.velocity = dir * EMPUJE_PX_S
		mc._mover()
		await physics_frame
	var lado_celda: float = (pl.global_position - reja).dot(dir)
	_ok(lado_celda < 0.0, "la reja cerrada retiene al preso (queda a %.1f px de la reja, por dentro)" % -lado_celda)


func _fin() -> void:
	print("ESCOLTA: %s (%d fallos)" % ["PASSED" if _fallos == 0 else "FAILED", _fallos])
	quit(1 if _fallos > 0 else 0)
