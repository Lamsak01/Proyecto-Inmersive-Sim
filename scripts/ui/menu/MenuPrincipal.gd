extends Control

## Menú principal (Claude Code, 2026-11-10): Nueva partida, Continuar, Cargar, Ajustes, Créditos y Salir.
## Es la primera escena del juego; el pueblo (World.tscn) se carga al elegir partida.

const ESCENA_PUEBLO: String = "res://scenes/World.tscn"

var _botones: VBoxContainer
var _cargando: Label
var _b_continuar: Button
var _b_cargar: Button


func _ready() -> void:
	theme = EstiloMenu.tema()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var fondo := TextureRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.stretch_mode = TextureRect.STRETCH_SCALE
	var grad := Gradient.new()
	grad.set_color(0, Color(0.16, 0.12, 0.08))
	grad.set_color(1, Color(0.03, 0.03, 0.04))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.35)
	tex.fill_to = Vector2(1.1, 1.1)
	fondo.texture = tex
	add_child(fondo)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	add_child(col)
	col.add_child(EstiloMenu.titulo("La Placa de Petri", 64))
	col.add_child(Control.new())
	_botones = VBoxContainer.new()
	_botones.add_theme_constant_override("separation", 10)
	_botones.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_botones)
	var b_nueva := _boton("Nueva partida", _nueva_partida)
	_b_continuar = _boton("Continuar", _continuar)
	_b_cargar = _boton("Cargar partida", _abrir_cargar)
	_boton("Ajustes", _abrir_ajustes)
	_boton("Créditos", _abrir_creditos)
	_boton("Salir", func() -> void: get_tree().quit())
	_cargando = EstiloMenu.etiqueta("Montando el pueblo…", false, 26)
	_cargando.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cargando.visible = false
	col.add_child(_cargando)
	var version := EstiloMenu.etiqueta("Versión de pruebas · F11 pantalla completa", true, 15)
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.position -= Vector2(16, 12)
	add_child(version)
	_refrescar()
	(_b_continuar if not _b_continuar.disabled else b_nueva).grab_focus.call_deferred()


func _boton(texto: String, accion: Callable) -> Button:
	var b := EstiloMenu.boton(texto, 320)
	b.pressed.connect(accion)
	_botones.add_child(b)
	return b


func _refrescar() -> void:
	var hay: bool = GameManager.ranura_mas_reciente() != ""
	_b_continuar.disabled = not hay
	_b_cargar.disabled = not hay
	if hay:
		var info: Dictionary = GameManager.info_ranura(GameManager.ranura_mas_reciente())
		_b_continuar.tooltip_text = "%s — Día %d, %s" % [info["nombre"], int(info["dia"]), info["hora"]]


func _entrar(ruta_partida: String) -> void:
	GameManager.carga_pendiente = ruta_partida
	_botones.visible = false
	_cargando.visible = true
	# Dos fotogramas para que se vea el aviso antes de que el pueblo tarde en montarse.
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().change_scene_to_file(ESCENA_PUEBLO)


func _nueva_partida() -> void:
	_entrar("")


func _continuar() -> void:
	var id: String = GameManager.ranura_mas_reciente()
	if id != "":
		_entrar(str(GameManager.RANURAS[id]))


func _abrir_cargar() -> void:
	var p: Control = load("res://scripts/ui/menu/PanelPartidas.gd").new()
	p.modo = "cargar"
	p.elegida.connect(func(ruta: String) -> void:
		p.cerrar()
		_entrar(ruta))
	p.cerrado.connect(_al_cerrar_panel)
	add_child(p)


func _abrir_ajustes() -> void:
	var p: Control = load("res://scripts/ui/menu/PanelAjustes.gd").new()
	p.cerrado.connect(_al_cerrar_panel)
	add_child(p)


func _abrir_creditos() -> void:
	var p: Control = load("res://scripts/ui/menu/PanelCreditos.gd").new()
	p.cerrado.connect(_al_cerrar_panel)
	add_child(p)


func _al_cerrar_panel() -> void:
	_refrescar()
	if _botones.visible and _botones.get_child_count() > 0:
		_botones.get_child(0).grab_focus.call_deferred()
