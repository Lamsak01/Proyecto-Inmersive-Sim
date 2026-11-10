extends SceneTree

## Prueba del menú principal (2026-11-10): paneles, cambio de teclas, guardar/cargar en hueco y pausa.
## No toca los ajustes, teclas ni partidas del jugador (hace copia y la repone).
## Uso: flatpak run org.godotengine.Godot --headless --path . -s tools/tests/menu_probe.gd

const RUTA_PRUEBA := "user://prueba_menu.json"
var _fallos: int = 0
var _copias: Dictionary = {}

func _ok(c: bool, txt: String) -> void:
	print(("  OK  " if c else "  FALLO  ") + txt)
	if not c:
		_fallos += 1

func _copiar(r: String) -> void:
	_copias[r] = FileAccess.get_file_as_bytes(r) if FileAccess.file_exists(r) else null

func _reponer() -> void:
	for r in _copias.keys():
		if _copias[r] == null:
			if FileAccess.file_exists(r):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(r))
		else:
			var f := FileAccess.open(r, FileAccess.WRITE)
			f.store_buffer(_copias[r])
			f.close()
	for r in [RUTA_PRUEBA, "user://prueba_menu.info.json"]:
		if FileAccess.file_exists(r):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(r))

func _frames(n: int) -> void:
	for _i in range(n):
		await physics_frame
		await process_frame

func _initialize() -> void:
	_copiar("user://ajustes.cfg")
	_copiar("user://teclas.cfg")
	await _frames(2)
	var aj = root.get_node("/root/Ajustes")
	var te = root.get_node("/root/Teclas")
	var gm = root.get_node("/root/GameManager")

	# 1. Menú principal y sus paneles
	var menu: Node = load("res://scenes/MenuPrincipal.tscn").instantiate()
	root.add_child(menu)
	await _frames(3)
	_ok(menu.get_child_count() >= 3, "el menú principal se monta")
	for ruta in ["res://scripts/ui/menu/PanelAjustes.gd", "res://scripts/ui/menu/PanelPartidas.gd", "res://scripts/ui/menu/PanelCreditos.gd"]:
		var p: Control = load(ruta).new()
		menu.add_child(p)
		await _frames(2)
		_ok(p.get_child_count() >= 2, "panel %s se monta" % ruta.get_file())
		p.call("cerrar")
		await _frames(1)

	# 2. Ajustes y teclas
	aj.poner("campo_vision", 85.0)
	_ok(is_equal_approx(float(aj.get_valor("campo_vision")), 85.0), "el campo de visión se guarda")
	var otra: String = te.cambiar("mochila", KEY_W)
	_ok(otra == "avanzar" and te.tecla("mochila") == KEY_W and te.tecla("avanzar") == KEY_I, "cambiar tecla intercambia con la que ya la usaba")
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_I
	_ok(InputMap.event_is_action(ev, "move_up"), "moverse hacia delante sigue la tecla nueva")
	te.restablecer()
	_ok(te.tecla("mochila") == KEY_I and te.tecla("avanzar") == KEY_W, "teclas por defecto")
	menu.queue_free()
	await _frames(2)

	# 3. Pueblo: guardar en un hueco, leer su ficha y cargarlo como lo pide el menú
	var world: Node = load("uid://dsoiuct8kdsk3").instantiate()
	root.add_child(world)
	current_scene = world
	await _frames(25)
	var wc = root.get_node("/root/WorldClock")
	_ok(gm.save_game(RUTA_PRUEBA), "guardar en un hueco")
	var info: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://prueba_menu.info.json"))
	_ok(typeof(info) == TYPE_DICTIONARY and int(info.get("dia", -1)) == int(wc.current_day), "la ficha del hueco tiene el día")
	var hora_guardada: int = int(wc.current_hour)
	wc.current_hour = (hora_guardada + 5) % 24
	var cargada := [false]
	gm.game_loaded.connect(func(_r): cargada[0] = true)
	gm.carga_pendiente = RUTA_PRUEBA
	gm.al_entrar_en_el_mundo()
	for _i in range(80):
		await process_frame
		if cargada[0]:
			break
	_ok(cargada[0] and int(wc.current_hour) == hora_guardada, "la carga pedida desde el menú restaura la hora")

	# 4. Pausa con Esc
	var ui = world.get_node_or_null("UI/UIRoot")
	_ok(ui != null and ui.has_method("abrir_menu_pausa"), "la interfaz sabe abrir la pausa")
	if ui:
		ui.call("abrir_menu_pausa")
		await process_frame
		var pausa = root.get_node_or_null("MenuPausa")
		_ok(pausa != null and paused, "la pausa se abre y para el pueblo")
		if pausa:
			pausa.call("cerrar")
		await process_frame
		_ok(not paused, "al cerrar la pausa el pueblo sigue")

	_reponer()
	print("MENU PROBE: %s (%d fallos)" % ["PASSED" if _fallos == 0 else "FAILED", _fallos])
	quit(1 if _fallos > 0 else 0)
