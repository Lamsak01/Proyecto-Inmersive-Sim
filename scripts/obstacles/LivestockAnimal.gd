extends Node2D

## Animal vivo de corral (Bloque FIS4): representa en el mapa cada ejemplar de `ranch_herd` (en el corral del Rancho
## del Sur). Pasea despacio dentro de su valla (`pen_rect`), cambia de tamaño según su etapa (`chick`, `juvenile`,
## `adult`), usa `animals/animated/Alpaca.glb` para la oveja y una gallina 3D hecha con piezas para el gallo/gallina.
## Los animales propios del jugador se borraron el 2026-11-12 (se rehacen en 3D con el gallinero, tras el Caso I).

const AnimalModel3DScript = preload("res://scripts/visuals/AnimalModel3D.gd")

var vm: Node2D = null
var animal_index: int = 0
var species: String = "sheep"
var stage: String = "chick"
var pen_rect: Rect2 = Rect2()
var _montado: bool = false ## ya tiene su modelo 3D (sin dibujo plano desde el 2026-11-13)
var model_3d: Node = null

var _target_pos: Vector2 = Vector2.ZERO
var _move_timer: float = 1.0


func configure_from_entry(p_vm: Node2D, p_index: int, d: Dictionary, p_pen_rect: Rect2) -> void:
	if not _montado:
		setup_animal(p_vm, p_index, d, p_pen_rect)
	else:
		vm = p_vm
		pen_rect = p_pen_rect
		global_position.x = clampf(global_position.x, pen_rect.position.x, pen_rect.end.x)
		global_position.y = clampf(global_position.y, pen_rect.position.y, pen_rect.end.y)
		_target_pos.x = clampf(_target_pos.x, pen_rect.position.x, pen_rect.end.x)
		_target_pos.y = clampf(_target_pos.y, pen_rect.position.y, pen_rect.end.y)
		update_from_dict(p_index, d)


func setup_animal(p_vm: Node2D, p_index: int, d: Dictionary, p_pen_rect: Rect2) -> void:
	vm = p_vm
	animal_index = p_index
	pen_rect = p_pen_rect
	add_to_group("livestock_animal")
	add_to_group("livestock_animals")
	add_to_group("ranch_livestock")
	add_to_group("con_cuerpo_3d") # Poblacion3D le da su cuerpo 3D: a un animal adulto no se le atraviesa

	var fx: float = fposmod(0.22 + float(p_index) * 0.27, 0.84) + 0.08
	var fy: float = fposmod(0.25 + float(p_index) * 0.37, 0.80) + 0.10
	global_position = Vector2(
		lerpf(pen_rect.position.x, pen_rect.end.x, fx),
		lerpf(pen_rect.position.y, pen_rect.end.y, fy)
	)
	_target_pos = global_position
	_move_timer = randf_range(0.6, 2.4)
	_montado = true
	update_from_dict(p_index, d)


func update_from_dict(p_index: int, d: Dictionary) -> void:
	animal_index = p_index
	species = str(d.get("species", "sheep"))
	stage = str(d.get("stage", "chick"))

	var rel: String = "procedural:chicken"
	var h_px: float = 5.5 if stage == "chick" else (7.0 if stage == "juvenile" else 9.0)
	match species:
		"sheep":
			rel = "animals/animated/Alpaca.glb"
			h_px = 9.5 if stage == "chick" else (12.5 if stage == "juvenile" else 15.5)
		"cow":
			rel = "animals/Cow.obj"
			h_px = 10.5 if stage == "chick" else (13.5 if stage == "juvenile" else 16.5)
		"bull":
			rel = "animals/Bull.obj"
			h_px = 11.0 if stage == "chick" else (14.5 if stage == "juvenile" else 17.5)
		"donkey":
			rel = "animals/Donkey.obj"
			h_px = 9.5 if stage == "chick" else (12.5 if stage == "juvenile" else 15.0)
		"horse":
			rel = "animals/animated/Horse.glb"
			h_px = 11.5 if stage == "chick" else (15.0 if stage == "juvenile" else 18.5)
	if model_3d == null or not is_instance_valid(model_3d):
		model_3d = AnimalModel3DScript.attach(self, rel, h_px, 2.0)
		if model_3d != null:
			model_3d.walk_px_s = 12.0
			model_3d.run_px_s = 55.0
	else:
		model_3d.call("set_model_config", rel, h_px)


func _process(delta: float) -> void:
	if pen_rect.size.x <= 1.0 or pen_rect.size.y <= 1.0:
		return
	var is_night: bool = false
	if WorldClock != null:
		var h: int = int(WorldClock.current_hour)
		is_night = (h >= 21 or h < 6)
	if is_night:
		return

	_move_timer -= delta
	if _move_timer <= 0.0:
		_move_timer = randf_range(2.2, 4.8)
		if randf() < 0.68:
			_target_pos = Vector2(
				randf_range(pen_rect.position.x, pen_rect.end.x),
				randf_range(pen_rect.position.y, pen_rect.end.y)
			)
		else:
			_target_pos = global_position

	var diff: Vector2 = _target_pos - global_position
	var spd: float = 11.0 if species == "sheep" else 14.0
	var sep_step: Vector2 = _compute_separation_step(delta)
	if diff.length() > 1.8 or sep_step.length_squared() > 0.001:
		var move_v: Vector2 = (diff.normalized() * spd * delta if diff.length() > 1.8 else Vector2.ZERO) + sep_step
		global_position.x = clampf(global_position.x + move_v.x, pen_rect.position.x, pen_rect.end.x)
		global_position.y = clampf(global_position.y + move_v.y, pen_rect.position.y, pen_rect.end.y)


func _compute_separation_step(delta: float) -> Vector2:
	if not is_inside_tree() or get_tree() == null:
		return Vector2.ZERO
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("livestock_animal"):
		if other == self or not (other is Node2D) or not is_instance_valid(other):
			continue
		var opos: Vector2 = (other as Node2D).global_position
		var d: float = global_position.distance_to(opos)
		if d < 14.0:
			var dir: Vector2 = (global_position - opos).normalized() if d > 0.01 else Vector2(cos(float(animal_index)), sin(float(animal_index)))
			push += dir * ((14.0 - d) / 14.0) * 26.0 * delta
	return push

