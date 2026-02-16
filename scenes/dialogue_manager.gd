extends Node

@export var dialogue_box: Control
@export var dialogue_text: Label
@export var choices_box: VBoxContainer

signal dialogue_finished(last_id: String)

var graph: Dictionary = {}
var current_id: String = ""
var active: bool = false

func _ready() -> void:
	if dialogue_box:
		dialogue_box.visible = false
		dialogue_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		dialogue_box.offset_left = 16
		dialogue_box.offset_right = -16
		dialogue_box.offset_bottom = -16
		dialogue_box.offset_top = -220


func is_active() -> bool:
	return active

func start_dialogue(new_graph: Dictionary, start_id: String) -> void:
	graph = new_graph
	current_id = start_id
	active = true

	if dialogue_box:
		dialogue_box.visible = true

	# IMPORTANTE: esperar 1 frame para que Godot recalcule sizes de Control
	await get_tree().process_frame

	# prints DESPUES del force + 1 frame
	print("UI refs:", dialogue_box, dialogue_text, choices_box)
	if dialogue_box:
		print("box rect AFTER:", dialogue_box.get_global_rect())
		print("box parent rect:", (dialogue_box.get_parent() as Control).get_global_rect())
	if dialogue_text:
		print("text rect AFTER:", dialogue_text.get_global_rect())
	if choices_box:
		print("choices rect AFTER:", choices_box.get_global_rect(), " children:", choices_box.get_child_count())

	_show_node(current_id)


func end_dialogue() -> void:
	active = false
	dialogue_finished.emit(current_id)
	if dialogue_box:
		dialogue_box.visible = false
	if choices_box:
		for c in choices_box.get_children():
			c.queue_free()

func _show_node(id: String) -> void:
	if not graph.has(id):
		end_dialogue()
		return

	var node_data: Dictionary = graph[id]
	print("node_data keys:", node_data.keys())
	print("node_data:", node_data)


	if dialogue_text:
		dialogue_text.text = str(node_data.get("text", ""))

	# limpiar botones viejos
	if choices_box == null:
		push_error("DialogueManager: choices_box no asignado en el Inspector.")
		return

	for c in choices_box.get_children():
		c.queue_free()

	var choices: Array = node_data.get("choices", [])
	for i in range(choices.size()):
		var ch: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = str(ch.get("label", "Opcion"))
		btn.add_theme_font_override("font", dialogue_text.get_theme_font("font"))
		btn.add_theme_font_size_override("font_size", dialogue_text.get_theme_font_size("font_size"))
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_choice_pressed.bind(i))
		choices_box.add_child(btn)


		

func _on_choice_pressed(index: int) -> void:
	var node_data: Dictionary = graph[current_id]
	var choices: Array = node_data.get("choices", [])
	
	if index < 0 or index >= choices.size():
		return

	var next_id := str((choices[index] as Dictionary).get("next", "END"))
	if next_id == "" or next_id == "END":
		end_dialogue()
		return
		


	current_id = next_id
	_show_node(current_id)
