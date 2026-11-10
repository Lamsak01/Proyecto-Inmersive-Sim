extends Control

## Ajustes (Claude Code, 2026-11-10): pestañas Gráficos, Juego, Sonido y Controles.
## Todo se aplica en el momento y se guarda solo (Ajustes y Teclas). Se usa desde el menú principal y desde la pausa.

signal cerrado

const OPC_PANTALLA := ["Ventana", "Pantalla completa"]
const OPC_SOMBRAS := ["Sin sombras", "Bajas", "Altas"]
const OPC_NITIDEZ := [["Nítida (100 %)", 1.0], ["Equilibrada (75 %)", 0.75], ["Rápida (50 %)", 0.5]]
const OPC_SUAVIZADO := ["No", "2×", "4×"]
const OPC_FPS := [["Sin límite", 0], ["30", 30], ["60", 60], ["120", 120], ["144", 144]]

var _esperando_tecla: String = ""
var _botones_tecla: Dictionary = {} # id -> Button
var _aviso_teclas: Label
var _pestanas: TabContainer
var _construyendo: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = EstiloMenu.tema()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	EstiloMenu.velo(self)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var marco := PanelContainer.new()
	marco.custom_minimum_size = Vector2(860, 560)
	centro.add_child(marco)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	marco.add_child(col)
	col.add_child(EstiloMenu.titulo("Ajustes"))
	_pestanas = TabContainer.new()
	_pestanas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_pestanas)
	_construir()
	var abajo := HBoxContainer.new()
	abajo.alignment = BoxContainer.ALIGNMENT_END
	abajo.add_theme_constant_override("separation", 12)
	col.add_child(abajo)
	var b_def := EstiloMenu.boton("Valores por defecto", 240)
	b_def.pressed.connect(_on_por_defecto)
	abajo.add_child(b_def)
	var b_vol := EstiloMenu.boton("Volver", 160)
	b_vol.pressed.connect(cerrar)
	abajo.add_child(b_vol)
	b_vol.grab_focus.call_deferred()


func _construir() -> void:
	_construyendo = true
	var actual: int = _pestanas.current_tab
	for c in _pestanas.get_children():
		_pestanas.remove_child(c)
		c.queue_free()
	_botones_tecla.clear()
	_pestanas.add_child(_pestana_graficos())
	_pestanas.add_child(_pestana_juego())
	_pestanas.add_child(_pestana_sonido())
	_pestanas.add_child(_pestana_controles())
	if actual >= 0:
		_pestanas.current_tab = actual
	_construyendo = false


func _rejilla(nombre: String) -> Array:
	var sc := ScrollContainer.new()
	sc.name = nombre
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var m := MarginContainer.new()
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_theme_constant_override("margin_right", 16)
	sc.add_child(m)
	var g := GridContainer.new()
	g.columns = 2
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 24)
	g.add_theme_constant_override("v_separation", 12)
	m.add_child(g)
	return [sc, g]


func _fila(g: GridContainer, texto: String, control: Control, ayuda: String = "") -> void:
	var l := EstiloMenu.etiqueta(texto)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if ayuda != "":
		l.tooltip_text = ayuda
		l.mouse_filter = Control.MOUSE_FILTER_PASS
	g.add_child(l)
	control.custom_minimum_size.x = 320
	if control is CheckButton:
		control.custom_minimum_size.x = 0
		control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	g.add_child(control)


func _opciones(textos: Array, elegido: int, al_cambiar: Callable) -> OptionButton:
	var o := OptionButton.new()
	for t in textos:
		o.add_item(str(t))
	o.select(clampi(elegido, 0, textos.size() - 1))
	o.item_selected.connect(func(i: int) -> void:
		if not _construyendo:
			al_cambiar.call(i))
	return o


func _deslizador(minimo: float, maximo: float, paso: float, valor: float, formato: Callable, al_cambiar: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	var s := HSlider.new()
	s.min_value = minimo
	s.max_value = maximo
	s.step = paso
	s.value = valor
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := EstiloMenu.etiqueta(formato.call(valor))
	l.custom_minimum_size.x = 70
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	s.value_changed.connect(func(v: float) -> void:
		l.text = formato.call(v)
		if not _construyendo:
			al_cambiar.call(v))
	h.add_child(s)
	h.add_child(l)
	return h


func _casilla(valor: bool, al_cambiar: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.button_pressed = valor
	c.toggled.connect(func(v: bool) -> void:
		if not _construyendo:
			al_cambiar.call(v))
	return c


func _indice(lista: Array, valor) -> int:
	for i in lista.size():
		if is_equal_approx(float(lista[i][1]), float(valor)):
			return i
	return 0


func _pestana_graficos() -> Control:
	var r: Array = _rejilla("Gráficos")
	var g: GridContainer = r[1]
	_fila(g, "Pantalla", _opciones(OPC_PANTALLA, 1 if bool(Ajustes.get_valor("pantalla_completa")) else 0,
		func(i: int) -> void: Ajustes.poner("pantalla_completa", i == 1)), "También con F11.")
	_fila(g, "Sincronización vertical", _casilla(bool(Ajustes.get_valor("vsync")),
		func(v: bool) -> void: Ajustes.poner("vsync", v)), "Evita que la imagen se «corte» al moverse. Puede limitar los fotogramas.")
	_fila(g, "Límite de fotogramas", _opciones(OPC_FPS.map(func(e): return e[0]), _indice(OPC_FPS, Ajustes.get_valor("fps_max")),
		func(i: int) -> void: Ajustes.poner("fps_max", int(OPC_FPS[i][1]))), "Menos fotogramas = el portátil se calienta menos.")
	_fila(g, "Sombras", _opciones(OPC_SOMBRAS, int(Ajustes.get_valor("sombras")),
		func(i: int) -> void: Ajustes.poner("sombras", i)), "Lo que más pesa. «Sin sombras» va mucho más rápido.")
	_fila(g, "Nitidez de la imagen 3D", _opciones(OPC_NITIDEZ.map(func(e): return e[0]), _indice(OPC_NITIDEZ, Ajustes.get_valor("nitidez")),
		func(i: int) -> void: Ajustes.poner("nitidez", float(OPC_NITIDEZ[i][1]))), "Dibuja el mundo a menos tamaño y lo estira: más rápido, algo más borroso.")
	_fila(g, "Suavizado de bordes", _opciones(OPC_SUAVIZADO, int(Ajustes.get_valor("suavizado")),
		func(i: int) -> void: Ajustes.poner("suavizado", i)), "Quita los «dientes de sierra» de los bordes. Cuesta rendimiento.")
	return r[0]


func _pestana_juego() -> Control:
	var r: Array = _rejilla("Juego")
	var g: GridContainer = r[1]
	_fila(g, "Sensibilidad del ratón (1.ª persona)", _deslizador(0.2, 3.0, 0.1, float(Ajustes.get_valor("sensibilidad")),
		func(v: float) -> String: return "%.1f" % v,
		func(v: float) -> void: Ajustes.poner("sensibilidad", v)))
	_fila(g, "Campo de visión (1.ª persona)", _deslizador(55, 100, 1, float(Ajustes.get_valor("campo_vision")),
		func(v: float) -> String: return "%d°" % int(v),
		func(v: float) -> void: Ajustes.poner("campo_vision", v)), "Cuánto se ve a los lados. Más grados = se ve más, pero las cosas parecen más lejos.")
	_fila(g, "Invertir el ratón arriba / abajo", _casilla(bool(Ajustes.get_valor("invertir_y")),
		func(v: bool) -> void: Ajustes.poner("invertir_y", v)))
	return r[0]


func _pestana_sonido() -> Control:
	var r: Array = _rejilla("Sonido")
	var g: GridContainer = r[1]
	var pct := func(v: float) -> String: return "%d %%" % int(round(v * 100.0))
	_fila(g, "Volumen general", _deslizador(0, 1, 0.05, float(Ajustes.get_valor("vol_general")), pct,
		func(v: float) -> void: Ajustes.poner("vol_general", v)))
	_fila(g, "Música", _deslizador(0, 1, 0.05, float(Ajustes.get_valor("vol_musica")), pct,
		func(v: float) -> void: Ajustes.poner("vol_musica", v)))
	_fila(g, "Efectos", _deslizador(0, 1, 0.05, float(Ajustes.get_valor("vol_efectos")), pct,
		func(v: float) -> void: Ajustes.poner("vol_efectos", v)))
	return r[0]


func _pestana_controles() -> Control:
	var caja := VBoxContainer.new()
	caja.name = "Controles"
	caja.add_theme_constant_override("separation", 8)
	_aviso_teclas = EstiloMenu.etiqueta("Pulsa un botón y después la tecla nueva. Esc cancela. Si la tecla ya se usaba, las dos se intercambian.", true, 17)
	_aviso_teclas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(_aviso_teclas)
	var r: Array = _rejilla("lista")
	r[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.add_child(r[0])
	var g: GridContainer = r[1]
	var grupo: String = ""
	for a in Teclas.ACCIONES:
		if a[3] != grupo:
			grupo = a[3]
			var cab := EstiloMenu.etiqueta(grupo, false, 19)
			cab.add_theme_color_override("font_color", EstiloMenu.ACENTO)
			g.add_child(cab)
			g.add_child(Control.new())
		var b := EstiloMenu.boton(Teclas.nombre_tecla(a[0]))
		var id: String = a[0]
		b.pressed.connect(func() -> void: _esperar_tecla(id))
		_botones_tecla[id] = b
		_fila(g, "   " + str(a[1]), b)
	var b_rest := EstiloMenu.boton("Teclas por defecto", 240)
	b_rest.pressed.connect(func() -> void:
		Teclas.restablecer()
		_refrescar_teclas()
		_aviso_teclas.text = "Teclas como al principio.")
	caja.add_child(b_rest)
	return caja


func _esperar_tecla(id: String) -> void:
	_refrescar_teclas()
	_esperando_tecla = id
	var b: Button = _botones_tecla[id]
	b.text = "Pulsa una tecla…"
	b.release_focus()


func _refrescar_teclas() -> void:
	for id in _botones_tecla.keys():
		_botones_tecla[id].text = Teclas.nombre_tecla(id)


func _nombre_accion(id: String) -> String:
	for a in Teclas.ACCIONES:
		if a[0] == id:
			return str(a[1])
	return id


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _esperando_tecla != "":
		if event is InputEventKey and event.pressed and not event.echo:
			get_viewport().set_input_as_handled()
			var id: String = _esperando_tecla
			_esperando_tecla = ""
			var k: int = int(event.physical_keycode) if event.physical_keycode != KEY_NONE else int(event.keycode)
			if k == KEY_ESCAPE:
				_aviso_teclas.text = "Cambio cancelado."
			elif k in Teclas.RESERVADAS:
				_aviso_teclas.text = "Esa tecla no se puede usar (es fija del juego)."
			else:
				var otra: String = Teclas.cambiar(id, k)
				if otra != "":
					_aviso_teclas.text = "«%s» ahora va con %s; «%s» se queda con %s." % [_nombre_accion(id), Teclas.nombre_tecla(id), _nombre_accion(otra), Teclas.nombre_tecla(otra)]
				else:
					_aviso_teclas.text = "«%s» ahora va con %s." % [_nombre_accion(id), Teclas.nombre_tecla(id)]
			_refrescar_teclas()
		elif event is InputEventMouseButton and event.pressed:
			_esperando_tecla = ""
			_refrescar_teclas()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		cerrar()


func _on_por_defecto() -> void:
	var tab: String = _pestanas.get_current_tab_control().name if _pestanas.get_current_tab_control() else ""
	if tab == "Controles":
		Teclas.restablecer()
	else:
		Ajustes.restablecer()
	_construir()


func cerrar() -> void:
	_esperando_tecla = ""
	cerrado.emit()
	queue_free()
