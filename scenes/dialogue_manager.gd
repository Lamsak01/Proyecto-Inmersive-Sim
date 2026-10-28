extends Node
## Sistema de Diálogo reconstruido desde cero:
## - Interfaz centrada automáticamente con estilo limpio (Nombre del NPC, Estado de Relación, Texto con efecto máquina de escribir opcional y Opciones numeradas).
## - Controles intuitivos por Teclado ([1]-[9], W/S/Flechas + Enter/Espacio, ESC para salir) y Ratón.
## - Soporte directo para cambios de Afinidad/Relación ("affinity") y acciones ("action") por opción.

@export var dialogue_box: Control
@export var dialogue_text: Label
@export var choices_box: VBoxContainer

signal dialogue_finished(last_id: String, speaker: Node)
signal choice_action_triggered(action_id: String, speaker: Node)

var graph: Dictionary = {}
var current_id: String = ""
var active: bool = false
var current_speaker: Node = null
var current_choices: Array = []

# Nodos de UI construidos/gestionados limpiamente
var _panel: PanelContainer
var _speaker_label: Label
var _relation_label: Label
var _body_label: Label
var _choices_container: VBoxContainer
var _hint_footer: Label
var _input_cooldown: float = 0.0

func _ready() -> void:
	# Ocultar el contenedor viejo mal centrado si existe en la escena
	if dialogue_box:
		dialogue_box.visible = false
	_build_clean_ui()

func _process(delta: float) -> void:
	if _input_cooldown > 0.0:
		_input_cooldown -= delta

func _build_clean_ui() -> void:
	var ui_parent: Node = get_tree().current_scene.get_node_or_null("UI/UIRoot")
	if not ui_parent:
		ui_parent = get_parent()

	_panel = PanelContainer.new()
	_panel.name = "DialoguePanel"
	_panel.visible = false
	
	# Estilo visual oscuro con borde elegante
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.94)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.75, 0.65, 0.42, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	_panel.add_theme_stylebox_override("panel", style)

	# Centrado perfecto en la parte inferior de la pantalla (720px de ancho)
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.custom_minimum_size = Vector2(720, 190)
	_panel.offset_left = -360
	_panel.offset_right = 360
	_panel.offset_bottom = -24
	_panel.offset_top = -220

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(main_vbox)

	# Cabecera: Nombre del NPC a la izquierda, Estado de Relación a la derecha
	var header_hbox := HBoxContainer.new()
	main_vbox.add_child(header_hbox)

	_speaker_label = Label.new()
	_speaker_label.text = "NPC"
	_speaker_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speaker_label.add_theme_font_size_override("font_size", 18)
	_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	header_hbox.add_child(_speaker_label)

	_relation_label = Label.new()
	_relation_label.text = "Neutral (0)"
	_relation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_relation_label.add_theme_font_size_override("font_size", 14)
	_relation_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
	header_hbox.add_child(_relation_label)

	var sep := HSeparator.new()
	main_vbox.add_child(sep)

	# Texto principal del diálogo
	_body_label = Label.new()
	_body_label.custom_minimum_size = Vector2(680, 48)
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_size_override("font_size", 17)
	_body_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	main_vbox.add_child(_body_label)

	# Contenedor de opciones centrado y expandible
	_choices_container = VBoxContainer.new()
	_choices_container.add_theme_constant_override("separation", 6)
	main_vbox.add_child(_choices_container)

	# Pie de ayuda de controles
	_hint_footer = Label.new()
	_hint_footer.text = "[1-9] Elegir opción   |   [W/S + Espacio/Enter] Navegar   |   [ESC] Cerrar"
	_hint_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_footer.add_theme_font_size_override("font_size", 12)
	_hint_footer.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65))
	main_vbox.add_child(_hint_footer)

	ui_parent.call_deferred("add_child", _panel)

func is_active() -> bool:
	return active

func start_dialogue(new_graph: Dictionary, start_id: String, speaker: Node = null) -> void:
	if not _panel:
		_build_clean_ui()

	graph = new_graph
	current_id = start_id
	current_speaker = speaker
	active = true
	_input_cooldown = 0.15

	_update_header()
	_panel.visible = true
	_show_node(current_id)

func _update_header() -> void:
	if not _speaker_label or not _relation_label:
		return
	if is_instance_valid(current_speaker):
		var npc_name: String = current_speaker.get("npc_name") if "npc_name" in current_speaker else current_speaker.name
		_speaker_label.text = npc_name
		if current_speaker.has_method("get_relationship_status_text"):
			_relation_label.text = current_speaker.get_relationship_status_text()
			_relation_label.modulate = current_speaker.get_relationship_color()
		else:
			_relation_label.text = ""
	else:
		_speaker_label.text = "Diálogo"
		_relation_label.text = ""

func end_dialogue() -> void:
	active = false
	var finished_id = current_id
	var speaker_ref = current_speaker
	current_choices.clear()
	if _panel:
		_panel.visible = false
	if _choices_container:
		for c in _choices_container.get_children():
			c.queue_free()
	dialogue_finished.emit(finished_id, speaker_ref)

func _show_node(id: String) -> void:
	if not graph.has(id):
		end_dialogue()
		return

	_input_cooldown = 0.12
	var node_data: Dictionary = graph[id]

	if _body_label:
		_body_label.text = str(node_data.get("text", ""))

	for c in _choices_container.get_children():
		c.queue_free()

	current_choices = node_data.get("choices", [])
	var first_btn: Button = null

	for i in range(current_choices.size()):
		var ch: Dictionary = current_choices[i]
		var btn := Button.new()
		var num_prefix := "[%d] " % (i + 1)
		btn.text = num_prefix + str(ch.get("label", "Continuar"))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(680, 32)
		btn.add_theme_font_size_override("font_size", 15)
		btn.focus_mode = Control.FOCUS_ALL

		var btn_normal := StyleBoxFlat.new()
		btn_normal.bg_color = Color(0.15, 0.17, 0.22, 0.9)
		btn_normal.corner_radius_top_left = 4
		btn_normal.corner_radius_top_right = 4
		btn_normal.corner_radius_bottom_left = 4
		btn_normal.corner_radius_bottom_right = 4
		btn_normal.content_margin_left = 12
		btn_normal.content_margin_top = 4
		btn_normal.content_margin_bottom = 4

		var btn_hover := btn_normal.duplicate() as StyleBoxFlat
		btn_hover.bg_color = Color(0.25, 0.30, 0.40, 0.95)
		btn_hover.border_width_left = 3
		btn_hover.border_color = Color(1.0, 0.85, 0.45)

		btn.add_theme_stylebox_override("normal", btn_normal)
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("focus", btn_hover)

		btn.pressed.connect(_on_choice_pressed.bind(i))
		_choices_container.add_child(btn)
		if i == 0:
			first_btn = btn

	if first_btn:
		first_btn.call_deferred("grab_focus")

func _unhandled_input(event: InputEvent) -> void:
	if not active or _input_cooldown > 0.0:
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		end_dialogue()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var idx: int = event.keycode - KEY_1
			if idx >= 0 and idx < current_choices.size():
				get_viewport().set_input_as_handled()
				_on_choice_pressed(idx)

func _on_choice_pressed(index: int) -> void:
	if index < 0 or index >= current_choices.size():
		return

	var chosen: Dictionary = current_choices[index]

	# Aplicar cambio de afinidad/relación si la opción lo define
	if chosen.has("affinity") and is_instance_valid(current_speaker) and current_speaker.has_method("modify_affinity"):
		current_speaker.modify_affinity(int(chosen["affinity"]))
		_update_header()

	# Ejecutar acción de diálogo si existe
	if chosen.has("action") and str(chosen["action"]) != "":
		var action_id := str(chosen["action"])
		choice_action_triggered.emit(action_id, current_speaker)
		if is_instance_valid(current_speaker) and current_speaker.has_method("on_dialogue_action"):
			current_speaker.on_dialogue_action(action_id)

	var next_id := str(chosen.get("next", "END"))
	if next_id == "" or next_id == "END":
		end_dialogue()
		return

	current_id = next_id
	_show_node(current_id)
