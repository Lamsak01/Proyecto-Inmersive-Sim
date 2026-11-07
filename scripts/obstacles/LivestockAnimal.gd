extends Node2D

## Animal vivo de corral (Bloque FIS4): representa en el mapa cada ejemplar de `ranch_herd` (en el corral del Rancho
## del Sur) y cada ejemplar de `player_animals` (en el corral del gallinero del jugador).
## Pasea despacio dentro de los límites de su valla (`pen_rect`), cambia de tamaño según su etapa (`chick`, `juvenile`,
## `adult`), usa `animals/animated/Alpaca.glb` para la oveja y una gallina 3D hecha con piezas para el gallo/gallina,
## y permite a los animales del jugador comer (`[E] Dar de comer a …`) o dar su producto de adultos (`[E] Esquilar la
## oveja` / `[E] Recoger huevos`, máx. 1 vez cada 2 días).

const AnimalModel3DScript = preload("res://scripts/visuals/AnimalModel3D.gd")

var vm: Node2D = null
var is_player_animal: bool = false
var animal_index: int = 0
var species: String = "sheep"
var stage: String = "chick"
var pen_rect: Rect2 = Rect2()
var sprite: Sprite2D = null
var interact_area: Area2D = null
var model_3d: Node = null

var _target_pos: Vector2 = Vector2.ZERO
var _move_timer: float = 1.0
var _hop_phase: float = 0.0


func configure_from_entry(p_vm: Node2D, p_owner_kind: String, p_index: int, d: Dictionary, p_pen_rect: Rect2) -> void:
	var want_player: bool = (p_owner_kind == "player")
	if sprite == null or not is_instance_valid(sprite):
		setup_animal(p_vm, want_player, p_index, d, p_pen_rect)
	else:
		vm = p_vm
		is_player_animal = want_player
		pen_rect = p_pen_rect
		global_position.x = clampf(global_position.x, pen_rect.position.x, pen_rect.end.x)
		global_position.y = clampf(global_position.y, pen_rect.position.y, pen_rect.end.y)
		_target_pos.x = clampf(_target_pos.x, pen_rect.position.x, pen_rect.end.x)
		_target_pos.y = clampf(_target_pos.y, pen_rect.position.y, pen_rect.end.y)
		update_from_dict(p_index, d)


func setup_animal(p_vm: Node2D, p_is_player: bool, p_index: int, d: Dictionary, p_pen_rect: Rect2) -> void:
	vm = p_vm
	is_player_animal = p_is_player
	animal_index = p_index
	pen_rect = p_pen_rect
	add_to_group("livestock_animal")
	add_to_group("livestock_animals")
	if is_player_animal:
		add_to_group("player_livestock")
	else:
		add_to_group("ranch_livestock")

	var fx: float = fposmod(0.22 + float(p_index) * 0.27, 0.84) + 0.08
	var fy: float = fposmod(0.25 + float(p_index) * 0.37, 0.80) + 0.10
	global_position = Vector2(
		lerpf(pen_rect.position.x, pen_rect.end.x, fx),
		lerpf(pen_rect.position.y, pen_rect.end.y, fy)
	)
	_target_pos = global_position
	_move_timer = randf_range(0.6, 2.4)
	_hop_phase = randf() * TAU

	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.position = Vector2(0.0, -3.0)
	add_child(sprite)

	if is_player_animal:
		interact_area = Area2D.new()
		interact_area.name = "InteractArea"
		interact_area.collision_layer = 1
		interact_area.collision_mask = 2
		interact_area.add_to_group("interactable")
		var col := CollisionShape2D.new()
		var cshape := CircleShape2D.new()
		cshape.radius = 18.0
		col.shape = cshape
		interact_area.add_child(col)
		add_child(interact_area)

	update_from_dict(p_index, d)


func update_from_dict(p_index: int, d: Dictionary) -> void:
	animal_index = p_index
	species = str(d.get("species", "sheep"))
	stage = str(d.get("stage", "chick"))

	if sprite != null and is_instance_valid(sprite):
		if species == "sheep":
			sprite.texture = load("res://assests/world/harvest/wild_deer.png")
			sprite.modulate = Color(0.96, 0.94, 0.88)
			var sc_s: float = 0.48 if stage == "chick" else (0.66 if stage == "juvenile" else 0.85)
			sprite.scale = Vector2(sc_s, sc_s)
		else:
			sprite.texture = load("res://assests/world/camp/chicken.png")
			sprite.modulate = Color(1.0, 0.95, 0.62) if stage == "chick" else Color.WHITE
			var sc_r: float = 0.68 if stage == "chick" else (0.90 if stage == "juvenile" else 1.15)
			sprite.scale = Vector2(sc_r, sc_r)

	var rel: String = "animals/animated/Alpaca.glb" if species == "sheep" else "procedural:chicken"
	var h_px: float = (11.0 if stage == "chick" else (15.0 if stage == "juvenile" else 19.5)) if species == "sheep" else (6.5 if stage == "chick" else (8.5 if stage == "juvenile" else 11.0))
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
		if sprite != null:
			sprite.offset.y = 0.0
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
		if sprite != null:
			if absf(move_v.x) > 0.02:
				sprite.flip_h = move_v.x > 0.0
			_hop_phase += delta * 12.0
			sprite.offset.y = -absf(sin(_hop_phase)) * 1.6
	else:
		if sprite != null:
			sprite.offset.y = 0.0


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
	if is_player_animal:
		var coop := get_tree().get_first_node_in_group("chicken_coop") as Node2D
		if coop != null and is_instance_valid(coop) and "chickens" in coop:
			for chk in (coop.get("chickens") as Array):
				if chk is Dictionary:
					var cspr: Sprite2D = (chk as Dictionary).get("sprite")
					if cspr != null and is_instance_valid(cspr):
						var d_c: float = global_position.distance_to(cspr.global_position)
						if d_c < 12.0:
							var dir_c: Vector2 = (global_position - cspr.global_position).normalized() if d_c > 0.01 else Vector2.DOWN
							push += dir_c * ((12.0 - d_c) / 12.0) * 24.0 * delta
	return push


func get_interact_label(_player: Node2D = null) -> String:
	if not is_player_animal or vm == null or not ("VillageHousing" in vm):
		return ""
	return vm.VillageHousing.get_player_animal_interact_label(vm, animal_index)


func interact(player: Node2D) -> void:
	if not is_player_animal or vm == null or not ("VillageHousing" in vm):
		return
	vm.VillageHousing.interact_player_animal(vm, animal_index, player)
