extends Control

## Ventana de tienda (versión provisional, 2026-11-13): sale al elegir «Comerciar» y enseña en dos columnas lo que
## vende el vecino y lo que te compra de tu mochila, con precio. Cada fila es una opción de compra o venta de siempre
## («buy:…» / «sell:…»): el gestor de diálogos la ejecuta igual que antes; aquí solo se pinta.

const DialogoTexto = preload("res://scripts/ui/dialogo/DialogoTexto.gd")

signal fila_elegida(indice: int) ## índice en la lista de opciones que se pasó a abrir()
signal cerrada

const ANCHO: float = 1000.0
const ALTO: float = 600.0
const ANCHO_PRECIO: float = 140.0
const COL_PERGAMINO: Color = Color(0.914, 0.878, 0.788)
const COL_BORDE: Color = Color(0.725, 0.659, 0.51)
const COL_TINTA: Color = Color(0.165, 0.141, 0.102)
const COL_TINTA_SUAVE: Color = Color(0.37, 0.33, 0.25)
const COL_FILA_FOCO: Color = Color(0.863, 0.812, 0.69)
const SIN_VENTAS: String = "No llevas nada que le interese."
const SIN_COMPRAS: String = "Hoy no le queda nada."
const AYUDA: String = "Clic: comprar o vender uno · Esc: volver a la charla"

var _titulo: Label
var _frase: Label
var _bolsa: Label
var _compras: VBoxContainer
var _ventas: VBoxContainer
var _detalle: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_construir()

## `opciones`: las opciones de compra y venta del vecino (diccionarios del diálogo). `inv`: la mochila del jugador.
func abrir(nombre_tienda: String, frase: String, opciones: Array, inv: Object) -> void:
	_titulo.text = nombre_tienda
	_frase.text = frase
	_frase.visible = frase != ""
	_bolsa.text = "Tu bolsa: %d %s" % [int(inv.get("gold")) if inv != null else 0, DialogoTexto.PALABRA_DINERO]
	_vaciar(_compras)
	_vaciar(_ventas)
	for i in range(opciones.size()):
		var op: Dictionary = opciones[i]
		var partes: PackedStringArray = str(op.get("action", "")).split(":")
		if partes.size() < 2:
			continue
		var es_compra: bool = partes[0] == "buy"
		var tiene: int = int(inv.call("get_count", partes[1])) if inv != null else 0
		if not es_compra and tiene <= 0:
			continue # solo se ofrece vender lo que llevas
		var quedan: int = DialogoTexto.existencias(str(op.get("label", "")))
		var detalle: String = ("quedan %d" % quedan if quedan >= 0 else "") if es_compra else "tienes %d" % tiene
		(_compras if es_compra else _ventas).add_child(_fila(i, op, partes, detalle, inv))
	_nota_si_vacia(_compras, SIN_COMPRAS)
	_nota_si_vacia(_ventas, SIN_VENTAS)
	_detalle.text = AYUDA
	visible = true
	var primera: Control = _primera_fila()
	if primera != null:
		primera.call_deferred("grab_focus")

func cerrar() -> void:
	if not visible:
		return
	visible = false
	cerrada.emit()

func _fila(i: int, op: Dictionary, partes: PackedStringArray, detalle: String, inv: Object) -> Button:
	var nombre: String = str(inv.call("get_item_name", partes[1])) if inv != null else partes[1]
	var precio: int = DialogoTexto.dinero(str(op.get("label", "")))
	if precio < 0 and partes.size() >= 3:
		precio = int(partes[2])
	var b := Button.new()
	b.text = "%s%s" % [nombre, ("  · " + detalle) if detalle != "" else ""]
	var etiqueta_precio := _texto(17, COL_TINTA, "%d %s" % [precio, DialogoTexto.PALABRA_DINERO])
	etiqueta_precio.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	etiqueta_precio.offset_left = -ANCHO_PRECIO
	etiqueta_precio.offset_right = -10.0
	etiqueta_precio.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	etiqueta_precio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta_precio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(etiqueta_precio) # precio a la derecha de la fila
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 17)
	for estado in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(estado, COL_TINTA)
	var normal := StyleBoxEmpty.new()
	normal.content_margin_left = 10
	normal.content_margin_top = 7
	normal.content_margin_bottom = 7
	var foco := StyleBoxFlat.new()
	foco.bg_color = COL_FILA_FOCO
	foco.set_corner_radius_all(4)
	foco.content_margin_left = 10
	foco.content_margin_top = 7
	foco.content_margin_bottom = 7
	b.add_theme_stylebox_override("normal", normal)
	for estado in ["hover", "focus", "pressed"]:
		b.add_theme_stylebox_override(estado, foco)
	var desc: String = str((inv.call("get_item_info", partes[1]) as Dictionary).get("desc", "")) if inv != null else ""
	b.focus_entered.connect(func() -> void: _detalle.text = "%s: %s" % [nombre, DialogoTexto.sin_emojis(desc)] if desc != "" else AYUDA)
	b.pressed.connect(func() -> void: fila_elegida.emit(i))
	return b

func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.55)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var hoja := PanelContainer.new()
	hoja.set_anchors_preset(Control.PRESET_CENTER)
	hoja.custom_minimum_size = Vector2(ANCHO, ALTO)
	hoja.offset_left = -ANCHO / 2.0
	hoja.offset_top = -ALTO / 2.0
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COL_PERGAMINO
	estilo.border_color = COL_BORDE
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(6)
	estilo.set_content_margin_all(32)
	hoja.add_theme_stylebox_override("panel", estilo)
	add_child(hoja)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	hoja.add_child(col)
	var cab := HBoxContainer.new()
	col.add_child(cab)
	var titulos := VBoxContainer.new()
	titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(titulos)
	_titulo = _texto(28, COL_TINTA)
	_frase = _texto(17, COL_TINTA_SUAVE)
	_frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titulos.add_child(_titulo)
	titulos.add_child(_frase)
	_bolsa = _texto(17, COL_TINTA_SUAVE)
	cab.add_child(_bolsa)
	var columnas := HBoxContainer.new()
	columnas.add_theme_constant_override("separation", 32)
	columnas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(columnas)
	_compras = _columna(columnas, "COMPRAR")
	_ventas = _columna(columnas, "VENDER (DE TU MOCHILA)")
	_detalle = _texto(15, COL_TINTA_SUAVE)
	_detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_detalle)

func _columna(padre: Control, titulo: String) -> VBoxContainer:
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_child(_texto(13, COL_TINTA_SUAVE, titulo))
	caja.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	caja.add_child(scroll)
	var filas := VBoxContainer.new()
	filas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(filas)
	padre.add_child(caja)
	return filas

func _texto(tam: int, col: Color, t: String = "") -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	return l

func _vaciar(c: Container) -> void:
	for h in c.get_children():
		c.remove_child(h)
		h.queue_free()

func _nota_si_vacia(c: Container, nota: String) -> void:
	if c.get_child_count() == 0:
		c.add_child(_texto(15, COL_TINTA_SUAVE, nota))

func _primera_fila() -> Control:
	for c: Container in [_compras, _ventas]:
		for h in c.get_children():
			if h is Button:
				return h
	return null

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		cerrar()
		accept_event()
