extends CanvasLayer

## Acabado visual retro de grano de película, viñeta suave y tramado ordenado PS1 (`shaders/retro_post_fx.gdshader`).
## La iluminación diurna/nocturna, los charcos de farolas, la lluvia y la niebla ya son íntegramente 3D en el mundo;
## esta capa solo aporta la textura visual retro sobre la imagen final sin añadir tintes ni nieblas planas sobre la pantalla.

const WorldStage3DScript = preload("res://scripts/visuals/WorldStage3D.gd")
const SHADER := preload("res://shaders/retro_post_fx.gdshader")

var _rect: ColorRect = null
var _mat: ShaderMaterial = null
var _time: float = 0.0


func setup(_village_manager: Node = null) -> void:
	name = "RetroPostFX"
	layer = 1
	_rect = ColorRect.new()
	_rect.name = "RetroPostFXRect"
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_rect.material = _mat
	add_child(_rect)


func _process(delta: float) -> void:
	if _mat == null or not is_instance_valid(_rect):
		return
	_rect.visible = not WorldStage3DScript.first_person_active
	if not _rect.visible:
		return
	_time += delta
	_mat.set_shader_parameter("time_s", _time)
