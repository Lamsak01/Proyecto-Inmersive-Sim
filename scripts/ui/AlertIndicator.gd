extends Node2D
class_name AlertIndicator

@onready var progress_bar: ProgressBar = $ProgressBar

const COLOR_ALERT = Color(1, 1, 0)
const COLOR_CHASE = Color(1, 0, 0)

var _is_red: bool = false
var _hide_timer: SceneTreeTimer = null
var _hide_gen: int = 0

func _ready() -> void:
	if not progress_bar:
		push_error("AlertIndicator needs a ProgressBar child")
		return
	
	visible = false
	set_process(false)
	progress_bar.modulate = COLOR_ALERT
	progress_bar.value = 0.0

func update_awareness(level: float, is_alerted: bool) -> void:
	if not is_alerted:
		visible = false
		set_process(false)
		_is_red = false
		_hide_timer = null
		return
	
	if _is_red and not visible:
		return

	visible = true
	set_process(true)
	progress_bar.value = level * 100.0
	
	if level >= 1.0:
		progress_bar.modulate = COLOR_CHASE
		if not _is_red:
			_is_red = true
			_start_hide_timer()
	else:
		progress_bar.modulate = COLOR_ALERT
		_is_red = false

func _start_hide_timer() -> void:
	_hide_gen += 1
	var my_gen: int = _hide_gen
	_hide_timer = get_tree().create_timer(1.0)
	await _hide_timer.timeout
	if is_instance_valid(self) and _is_red and my_gen == _hide_gen:
		visible = false
		set_process(false)

func _process(_delta: float) -> void:
	global_rotation = 0.0
