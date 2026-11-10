extends Control

## Guardar / cargar partida (Claude Code, 2026-11-10). modo = "guardar" (solo huecos 1–3) o "cargar" (todos).
## Al elegir emite «elegida(ruta)»; quien lo abre decide qué hacer (cargar ya en la partida o arrancar el pueblo).

signal elegida(ruta: String)
signal cerrado

var modo: String = "cargar"
var _lista: VBoxContainer
var _aviso: Label
var _confirmar_id: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = EstiloMenu.tema()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	EstiloMenu.velo(self)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var marco := PanelContainer.new()
	marco.custom_minimum_size = Vector2(700, 0)
	centro.add_child(marco)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	marco.add_child(col)
	col.add_child(EstiloMenu.titulo("Guardar partida" if modo == "guardar" else "Cargar partida"))
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 8)
	col.add_child(_lista)
	_aviso = EstiloMenu.etiqueta("", true, 17)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_aviso)
	var b_vol := EstiloMenu.boton("Volver", 160)
	b_vol.size_flags_horizontal = Control.SIZE_SHRINK_END
	b_vol.pressed.connect(cerrar)
	col.add_child(b_vol)
	_rellenar()


func _rellenar() -> void:
	for c in _lista.get_children():
		c.queue_free()
	var ids: Array = ["1", "2", "3"] if modo == "guardar" else ["auto", "rapida", "1", "2", "3"]
	var primero: Button = null
	for id in ids:
		var info: Dictionary = GameManager.info_ranura(id)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 64)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if bool(info["existe"]):
			b.text = "%s  —  Día %d, %s\n      guardada el %s" % [info["nombre"], int(info["dia"]), info["hora"], _fecha_bonita(str(info["fecha"]))]
		else:
			b.text = "%s  —  vacía" % info["nombre"]
			b.disabled = modo == "cargar"
		if _confirmar_id == id:
			b.text = "¿Sobrescribir «%s»? Pulsa otra vez para confirmar." % info["nombre"]
		b.pressed.connect(_on_hueco.bind(id))
		fila.add_child(b)
		if bool(info["existe"]) and id in ["1", "2", "3"]:
			var bb := EstiloMenu.boton("Borrar")
			bb.custom_minimum_size = Vector2(110, 64)
			bb.pressed.connect(func() -> void:
				GameManager.borrar_ranura(id)
				_aviso.text = "«%s» borrada." % info["nombre"]
				_rellenar())
			fila.add_child(bb)
		_lista.add_child(fila)
		if primero == null and not b.disabled:
			primero = b
	if primero:
		primero.grab_focus.call_deferred()


func _fecha_bonita(f: String) -> String:
	# «2026-11-10 18:42» → «10/11/2026 a las 18:42»
	var partes: PackedStringArray = f.split(" ")
	if partes.size() < 2:
		return f
	var d: PackedStringArray = partes[0].split("-")
	if d.size() != 3:
		return f
	return "%s/%s/%s a las %s" % [d[2], d[1], d[0], partes[1]]


func _on_hueco(id: String) -> void:
	var info: Dictionary = GameManager.info_ranura(id)
	if modo == "guardar":
		if bool(info["existe"]) and _confirmar_id != id:
			_confirmar_id = id
			_rellenar()
			return
		_confirmar_id = ""
	elegida.emit(str(info["ruta"]))


## Tras guardar desde la pausa: refrescar la lista para que se vea la hora nueva.
func avisar(texto: String) -> void:
	_aviso.text = texto
	_rellenar()


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		cerrar()


func cerrar() -> void:
	cerrado.emit()
	queue_free()
