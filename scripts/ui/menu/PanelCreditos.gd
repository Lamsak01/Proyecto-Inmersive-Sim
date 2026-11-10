extends Control

## Créditos (Claude Code, 2026-11-10). El texto sale de creditos.txt (mismo directorio), que se puede editar a mano.

signal cerrado

const ARCHIVO: String = "res://scripts/ui/menu/creditos.txt"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = EstiloMenu.tema()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	EstiloMenu.velo(self)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var marco := PanelContainer.new()
	marco.custom_minimum_size = Vector2(860, 600)
	centro.add_child(marco)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	marco.add_child(col)
	col.add_child(EstiloMenu.titulo("Créditos"))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sc)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 6)
	sc.add_child(lista)
	var texto: String = FileAccess.get_file_as_string(ARCHIVO)
	if texto == "":
		texto = "== La Placa de Petri\n(falta el archivo de créditos)"
	for linea in texto.split("\n"):
		var l: String = linea.strip_edges()
		if l.begins_with("#"):
			continue
		var e: Label
		if l.begins_with("=="):
			e = EstiloMenu.etiqueta(l.substr(2).strip_edges(), false, 24)
			e.add_theme_color_override("font_color", EstiloMenu.ACENTO)
		else:
			e = EstiloMenu.etiqueta(l, false, 18)
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lista.add_child(e)
	var b := EstiloMenu.boton("Volver", 160)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.pressed.connect(cerrar)
	col.add_child(b)
	b.grab_focus.call_deferred()


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		cerrar()


func cerrar() -> void:
	cerrado.emit()
	queue_free()
