extends CanvasLayer

## Menú de pausa con Esc (Claude Code, 2026-11-10): Seguir, Guardar, Cargar, Ajustes y Salir al menú.
## Para el pueblo entero mientras está abierto (el reloj y los vecinos no avanzan).

var _raiz: Control
var _botones: VBoxContainer
var _aviso: Label
var _b_salir: Button
var _confirmar_salida: bool = false
var _raton_antes: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
var _panel: Control = null


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	_raton_antes = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	_raiz = Control.new()
	_raiz.theme = EstiloMenu.tema()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_raiz)
	EstiloMenu.velo(_raiz)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(centro)
	var marco := PanelContainer.new()
	marco.custom_minimum_size = Vector2(420, 0)
	centro.add_child(marco)
	_botones = VBoxContainer.new()
	_botones.add_theme_constant_override("separation", 10)
	marco.add_child(_botones)
	_botones.add_child(EstiloMenu.titulo("Pausa"))
	var hora := EstiloMenu.etiqueta(WorldClock.get_formatted_time() if WorldClock else "", true, 18)
	hora.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_botones.add_child(hora)
	var b_seguir := _boton("Seguir jugando", cerrar)
	_boton("Guardar partida", _abrir_guardar)
	_boton("Cargar partida", _abrir_cargar)
	_boton("Ajustes", _abrir_ajustes)
	_b_salir = _boton("Salir al menú principal", _salir_al_menu)
	_aviso = EstiloMenu.etiqueta("", true, 16)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.custom_minimum_size.x = 380
	_botones.add_child(_aviso)
	b_seguir.grab_focus.call_deferred()


func _boton(texto: String, accion: Callable) -> Button:
	var b := EstiloMenu.boton(texto, 380)
	b.pressed.connect(accion)
	_botones.add_child(b)
	return b


func _abrir(p: Control) -> void:
	_panel = p
	p.cerrado.connect(func() -> void:
		_panel = null
		if _botones.get_child_count() > 2:
			_botones.get_child(2).grab_focus.call_deferred())
	_raiz.add_child(p)


func _abrir_guardar() -> void:
	if not GameManager._se_puede_guardar_ahora():
		_aviso.text = "Ahora no se puede guardar (descanso, escolta o conversación en marcha)."
		return
	var p: Control = load("res://scripts/ui/menu/PanelPartidas.gd").new()
	p.modo = "guardar"
	p.elegida.connect(func(ruta: String) -> void:
		var ok: bool = GameManager.save_game(ruta)
		p.avisar("Partida guardada." if ok else "No se pudo guardar."))
	_abrir(p)


func _abrir_cargar() -> void:
	var p: Control = load("res://scripts/ui/menu/PanelPartidas.gd").new()
	p.modo = "cargar"
	p.elegida.connect(func(ruta: String) -> void:
		p.cerrar()
		cerrar()
		GameManager.load_game(ruta))
	_abrir(p)


func _abrir_ajustes() -> void:
	_abrir(load("res://scripts/ui/menu/PanelAjustes.gd").new())


## Volver al menú reinicia el juego: así el pueblo siguiente empieza limpio (hay datos que no se borran solos).
func _salir_al_menu() -> void:
	if not _confirmar_salida:
		_confirmar_salida = true
		_b_salir.text = "¿Seguro? Pulsa otra vez"
		_aviso.text = "Lo que no hayas guardado se pierde."
		return
	get_tree().paused = false
	OS.set_restart_on_exit(true, OS.get_cmdline_args())
	get_tree().quit()


func _input(event: InputEvent) -> void:
	if _panel != null:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		cerrar()


func cerrar() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(_raton_antes)
	queue_free()
