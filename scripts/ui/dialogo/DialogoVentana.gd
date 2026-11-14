extends Control

## Aspecto de la ventana de diálogo (versión provisional, 2026-11-13): caja oscura abajo con el nombre y oficio del
## vecino, su frase apareciendo letra a letra y, al acabar, las opciones numeradas sin adornos. Es solo la «funda»:
## qué se dice y qué hace cada opción lo decide el gestor de diálogos, así que cambiar el aspecto no toca nada más.

signal avanzar_pulsado
signal opcion_pulsada(indice: int)

const MARGEN_LADOS: float = 140.0
const MARGEN_ABAJO: float = 28.0
const LETRAS_POR_SEGUNDO: float = 70.0
const TAM_NOMBRE: int = 22
const TAM_OFICIO: int = 14
const TAM_CUERPO: int = 19
const TAM_OPCION: int = 17
const TAM_PIE: int = 13
const COL_FONDO: Color = Color(0.07, 0.086, 0.10, 0.94)
const COL_BORDE: Color = Color(0.29, 0.26, 0.20)
const COL_AMBAR: Color = Color(0.91, 0.69, 0.31)
const COL_AMBAR_CLARO: Color = Color(0.95, 0.80, 0.52)
const COL_TINTA: Color = Color(0.93, 0.89, 0.82)
const COL_GRIS: Color = Color(0.66, 0.62, 0.54)
const COL_GRIS_OSCURO: Color = Color(0.56, 0.53, 0.46)
const FUENTES_LIBRO: PackedStringArray = ["Alegreya", "Georgia", "DejaVu Serif", "Liberation Serif", "Noto Serif", "serif"]
const AVISO_SEGUIR: String = "Clic o E para seguir"
const AVISO_ELEGIR: String = "1-9 o clic para elegir · Esc para salir"

var _nombre: Label
var _oficio: Label
var _relacion: Label
var _cuerpo: Label
var _pagina: Label
var _aviso: Label
var _opciones: VBoxContainer
var _letras: float = 0.0
var _fuente_libro: SystemFont

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fuente_libro = SystemFont.new()
	_fuente_libro.font_names = FUENTES_LIBRO
	_construir()

func _process(delta: float) -> void:
	if not visible or not revelando():
		return
	_letras += delta * LETRAS_POR_SEGUNDO
	_cuerpo.visible_characters = int(_letras)

## ¿Sigue apareciendo la frase letra a letra?
func revelando() -> bool:
	return _cuerpo != null and _cuerpo.visible_characters >= 0 and _cuerpo.visible_characters < _cuerpo.get_total_character_count()

func revelar_todo() -> void:
	_cuerpo.visible_characters = -1

func poner_hablante(nombre: String, oficio: String, relacion: String, color_relacion: Color) -> void:
	_nombre.text = nombre
	_oficio.text = oficio
	_oficio.visible = oficio != ""
	_relacion.text = relacion
	_relacion.add_theme_color_override("font_color", color_relacion)

## Un trozo de lo que dice el vecino; `pagina`/`total` cuentan desde 1 (con un solo trozo no se enseña).
func poner_trozo(texto: String, pagina: int, total: int) -> void:
	_cuerpo.text = texto
	_letras = 0.0
	_cuerpo.visible_characters = 0
	_pagina.text = ("%d de %d" % [pagina, total]) if total > 1 else ""
	_aviso.text = AVISO_SEGUIR if pagina < total else AVISO_ELEGIR

## Opciones del final del trozo; vacío las esconde mientras quedan trozos por leer.
func poner_opciones(etiquetas: Array[String]) -> void:
	for b in _opciones.get_children():
		_opciones.remove_child(b)
		b.queue_free()
	for i in range(etiquetas.size()):
		_opciones.add_child(_boton_opcion(i, etiquetas[i]))
	_opciones.visible = not etiquetas.is_empty()
	if not etiquetas.is_empty():
		(_opciones.get_child(0) as Button).call_deferred("grab_focus")

## W/S: mueve el foco entre las opciones (da la vuelta al llegar al final).
func mover_foco(paso: int) -> void:
	var n: int = _opciones.get_child_count()
	if n == 0:
		return
	var actual: int = 0
	for i in range(n):
		if _opciones.get_child(i).has_focus():
			actual = i
	(_opciones.get_child(posmod(actual + paso, n)) as Button).grab_focus()

func _construir() -> void:
	var columna := VBoxContainer.new()
	columna.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	columna.offset_left = MARGEN_LADOS
	columna.offset_right = -MARGEN_LADOS
	columna.offset_bottom = -MARGEN_ABAJO
	columna.offset_top = -MARGEN_ABAJO
	columna.grow_vertical = Control.GROW_DIRECTION_BEGIN
	columna.add_theme_constant_override("separation", 12)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(columna)
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", _estilo_caja())
	caja.mouse_filter = Control.MOUSE_FILTER_STOP
	caja.gui_input.connect(_on_caja_input)
	columna.add_child(caja)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 10)
	caja.add_child(dentro)
	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 12)
	dentro.add_child(cabecera)
	_nombre = _etiqueta(TAM_NOMBRE, COL_AMBAR, true)
	_oficio = _etiqueta(TAM_OFICIO, COL_GRIS)
	_relacion = _etiqueta(TAM_PIE, COL_GRIS)
	_relacion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_relacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for l in [_nombre, _oficio, _relacion]:
		cabecera.add_child(l)
	_cuerpo = _etiqueta(TAM_CUERPO, COL_TINTA, true)
	_cuerpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cuerpo.custom_minimum_size = Vector2(0, TAM_CUERPO * 2)
	dentro.add_child(_cuerpo)
	var pie := HBoxContainer.new()
	dentro.add_child(pie)
	_pagina = _etiqueta(TAM_PIE, COL_GRIS_OSCURO)
	_pagina.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_aviso = _etiqueta(TAM_PIE, COL_GRIS_OSCURO)
	pie.add_child(_pagina)
	pie.add_child(_aviso)
	_opciones = VBoxContainer.new()
	_opciones.add_theme_constant_override("separation", 2)
	var sangria := MarginContainer.new()
	sangria.add_theme_constant_override("margin_left", 34)
	sangria.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sangria.add_child(_opciones)
	columna.add_child(sangria)

func _boton_opcion(i: int, texto: String) -> Button:
	var b := Button.new()
	b.text = "%d    %s" % [i + 1, texto]
	b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.add_theme_font_size_override("font_size", TAM_OPCION)
	b.add_theme_color_override("font_color", COL_TINTA)
	for estado in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(estado, COL_AMBAR_CLARO)
	var vacio := StyleBoxEmpty.new()
	vacio.content_margin_top = 4
	vacio.content_margin_bottom = 4
	for estilo in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		b.add_theme_stylebox_override(estilo, vacio)
	b.pressed.connect(func() -> void: opcion_pulsada.emit(i))
	return b

func _etiqueta(tam: int, col: Color, libro: bool = false) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	if libro:
		l.add_theme_font_override("font", _fuente_libro)
	return l

func _estilo_caja() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = COL_FONDO
	s.border_color = COL_BORDE
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.content_margin_left = 34
	s.content_margin_right = 34
	s.content_margin_top = 22
	s.content_margin_bottom = 18
	return s

func _on_caja_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		avanzar_pulsado.emit()
		accept_event()
