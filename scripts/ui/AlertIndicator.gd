extends Node2D
class_name AlertIndicator

@onready var progress_bar: ProgressBar = $ProgressBar

# Colors
const COLOR_ALERT = Color(1, 1, 0) # Yellow
const COLOR_CHASE = Color(1, 0, 0) # Red

var _is_red: bool = false
var _hide_timer: SceneTreeTimer = null

func _ready() -> void:
	if not progress_bar:
		push_error("AlertIndicator needs a ProgressBar child")
		return
	
	visible = false
	progress_bar.modulate = COLOR_ALERT
	progress_bar.value = 0.0

func update_awareness(level: float, is_alerted: bool) -> void:
	if not is_alerted:
		visible = false
		_is_red = false
		if _hide_timer:
			_hide_timer = null
		return
	
	# If we are already in the "hidden red" state, don't show it again until reset
	if _is_red and not visible:
		return

	visible = true
	progress_bar.value = level * 100.0
	
	if level >= 1.0:
		progress_bar.modulate = COLOR_CHASE
		if not _is_red:
			_is_red = true
			# Start 1s timer to hide
			_start_hide_timer()
	else:
		progress_bar.modulate = COLOR_ALERT
		_is_red = false

func _start_hide_timer() -> void:
	_hide_timer = get_tree().create_timer(1.0)
	await _hide_timer.timeout
	# Only hide if we are still in red state
	if _is_red:
		visible = false

func _process(_delta: float) -> void:
	# Keep rotation fixed so bar doesn't spin with enemy
	global_rotation = 0
