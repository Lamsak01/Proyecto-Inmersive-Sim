extends Area2D
class_name ArrowProjectile

## Proyectil de Flecha con Caída Balística y Escala Proporcionada — Fase 3.4
## Vuela describiendo un arco parabólico con sombra en el suelo, tiene alcance limitado
## y al perder fuerza cae y se clava en la tierra en lugar de volar infinitamente.
## Paso a 3D, paso 5c (2026-11-10): vuela con altura de verdad. Sale a la altura del pecho de quien dispara y, si es el
## protagonista en 1.ª persona, con la pendiente hacia donde mira (arriba o abajo). Solo hiere a quien esté a esa altura;
## si baja hasta el suelo se clava (la bala desaparece), y un suelo alto (la galería de la posada) la para.

const Vista = preload("res://scripts/fisica/Vista.gd")
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const WorldStageBase3D = preload("res://scripts/visuals/WorldStageBase3D.gd")

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var max_range: float = 330.0
var damage_data: DamageData = null
var shooter: Node = null
var is_bullet: bool = false

var altura_px: float = NAN     ## altura actual (px de altura, con relieve); si nadie la pone, la del pecho de quien dispara
var pendiente: float = NAN     ## px de altura que sube por cada px que avanza; si nadie la pone, hacia donde mira el protagonista
var _nivel: int = 0            ## piso de quien dispara (para saber qué suelo hay debajo)
var _origen: Vector2 = Vector2.ZERO
var _altura_origen: float = 0.0
var _traveled_dist: float = 0.0
var _is_grounded: bool = false
var _arrow_sprite: Sprite2D = null
var _shadow_line: Line2D = null
var _col_shape: CollisionShape2D = null

func _ready() -> void:
	if damage_data:
		damage_data.is_ranged_projectile = true
		if damage_data.is_firearm_bullet:
			is_bullet = true
	collision_layer = 0
	collision_mask = 5 # Capas 1 (entorno/obstáculos) y 3 (hurtboxes de enemigos/animales)
	rotation = direction.angle()
	_preparar_altura()

	_col_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 5.0) if is_bullet else Vector2(14, 3.0)
	_col_shape.shape = rect
	add_child(_col_shape)

	# Sombra sutil en el suelo con el doble de largo para acompañar la flecha
	_shadow_line = Line2D.new()
	_shadow_line.width = 1.1 if is_bullet else 1.3
	_shadow_line.default_color = Color(1.0, 0.85, 0.35, 0.55) if is_bullet else Color(0.0, 0.0, 0.0, 0.35)
	_shadow_line.points = PackedVector2Array([Vector2(-12, 0.0), Vector2(8, 0.0)] if is_bullet else [Vector2(-8, 2.5), Vector2(8, 2.5)])
	add_child(_shadow_line)

	_arrow_sprite = Sprite2D.new()
	var tex_path := "res://assests/items/tools/arrow_proj.png"
	if ResourceLoader.exists(tex_path):
		_arrow_sprite.texture = load(tex_path)
	else:
		var abs_path := ProjectSettings.globalize_path(tex_path)
		if FileAccess.file_exists(abs_path):
			var img := Image.load_from_file(abs_path)
			if img and not img.is_empty():
				_arrow_sprite.texture = ImageTexture.create_from_image(img)
	# Largo duplicado respecto a la versión anterior (1.1x en X, estilizada en Y)
	_arrow_sprite.scale = Vector2(0.85, 0.38) if is_bullet else Vector2(1.1, 0.65)
	if is_bullet:
		_arrow_sprite.modulate = Color(1.0, 0.92, 0.52)
	add_child(_arrow_sprite)

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _is_grounded:
		return

	var progress: float = clampf(_traveled_dist / maxf(1.0, max_range), 0.0, 1.0)
	# La flecha pierde algo de velocidad al final de su parábola; la bala mantiene su velocidad balística
	var current_speed: float = speed if is_bullet else (speed * lerpf(1.0, 0.65, progress * progress))
	var step: float = current_speed * delta

	global_position += direction * step
	_traveled_dist += step
	altura_px += pendiente * step
	if _toca_suelo():
		if is_bullet:
			queue_free()
		else:
			_stick_in_ground()
		return

	# Arco parabólico visual (solo para flechas)
	if _arrow_sprite and not is_bullet:
		var arc_height: float = sin(progress * PI) * 5.5
		_arrow_sprite.position.y = -arc_height
		# Ligera inclinación de caída en el último tramo del vuelo
		if progress > 0.65:
			var drop_t: float = (progress - 0.65) / 0.35
			_arrow_sprite.rotation = drop_t * 0.28 * (1.0 if direction.x >= 0.0 else -1.0)

	if _traveled_dist >= max_range:
		if is_bullet:
			queue_free()
		else:
			_stick_in_ground()

## Altura y pendiente de salida (paso 5c).
func _preparar_altura() -> void:
	var vm = get_tree().get_first_node_in_group("village_manager")
	var es_prota: bool = is_instance_valid(shooter) and shooter.is_in_group("player")
	if es_prota and vm != null:
		_nivel = int(vm.get("player_elevation_level"))
	elif is_instance_valid(shooter) and "elevation_level" in shooter:
		_nivel = int(shooter.get("elevation_level"))
	if is_nan(altura_px):
		altura_px = Vista.altura_ojos(global_position, _nivel, vm) - 2.0 # el pecho
	if is_nan(pendiente):
		pendiente = tan(WorldStageBase3D.fp_pitch) * Mapa3D.ESCALA / Mapa3D.ALTO if es_prota else 0.0
	_origen = global_position
	_altura_origen = altura_px


## ¿Ha bajado hasta el suelo o ha chocado con un suelo alto?
func _toca_suelo() -> bool:
	var vm = get_tree().get_first_node_in_group("village_manager")
	return altura_px <= Vista.altura_pies(global_position, _nivel, vm) or Vista.tapa_un_suelo(_origen, _altura_origen, global_position, altura_px)


## ¿Está `n` (vecino, animal, enemigo) a la altura a la que va la flecha?
func _a_su_altura(n: Node) -> bool:
	if not (n is Node2D):
		return true
	var vm = get_tree().get_first_node_in_group("village_manager")
	var nivel: int = int(n.get("elevation_level")) if "elevation_level" in n else _nivel
	var pies: float = Vista.altura_pies((n as Node2D).global_position, nivel, vm)
	return altura_px >= pies - 2.0 and altura_px <= pies + Vista.ALTO_CUERPO_PX


func _stick_in_ground() -> void:
	_is_grounded = true
	if _col_shape:
		_col_shape.set_deferred("disabled", true)
	if _arrow_sprite:
		_arrow_sprite.position.y = 0.0
		# Queda clavada en la tierra con un ligero ángulo de caída
		_arrow_sprite.rotation = 0.35 if direction.x >= 0.0 else -0.35
	if _shadow_line:
		_shadow_line.visible = false

	# Desvanecer suavemente la flecha clavada tras 1.8 segundos
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func _on_area_entered(area: Area2D) -> void:
	if _is_grounded or area.get_parent() == shooter:
		return
	if area is Hurtbox and damage_data and _a_su_altura(area.get_parent()):
		damage_data.is_ranged_projectile = true
		damage_data.shot_distance_px = _traveled_dist
		_is_grounded = true
		if _col_shape:
			_col_shape.set_deferred("disabled", true)
		var target_node: Node = area.get_parent() if area.get_parent() else area
		area.receive_damage(damage_data)
		if is_bullet and target_node is Node2D:
			var ws_scr = load("res://scripts/visuals/WorldStage3D.gd")
			var cf_scr = load("res://scripts/systems/combat/CombatFeel.gd")
			var bf: Dictionary = {"knockback": 18.0 if damage_data.firearm_kind == "rifle" else 12.0, "stagger": 0.42, "hitstop": 0.04, "shake": 4.0, "pitch": 0.65}
			if cf_scr:
				cf_scr.apply_hit_reaction(target_node, direction, bf)
			if ws_scr and is_instance_valid(shooter) and shooter is Node2D and shooter.is_in_group("player"):
				ws_scr.notify_fp_melee_hit(shooter as Node2D, target_node as Node2D, direction, bf, 1.35)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _is_grounded or body == shooter:
		return
	if (body.is_in_group("wild_animals") or body.is_in_group("destructible")) and body.has_method("take_damage") and damage_data:
		if body.is_in_group("wild_animals") and not _a_su_altura(body):
			return
		damage_data.is_ranged_projectile = true
		damage_data.shot_distance_px = _traveled_dist
		_is_grounded = true
		if _col_shape:
			_col_shape.set_deferred("disabled", true)
		body.take_damage(damage_data)
		if is_bullet:
			var ws_scr = load("res://scripts/visuals/WorldStage3D.gd")
			var cf_scr = load("res://scripts/systems/combat/CombatFeel.gd")
			var bf: Dictionary = {"knockback": 18.0 if damage_data.firearm_kind == "rifle" else 12.0, "stagger": 0.42, "hitstop": 0.04, "shake": 4.0, "pitch": 0.65}
			if cf_scr:
				cf_scr.apply_hit_reaction(body, direction, bf)
			if ws_scr and is_instance_valid(shooter) and shooter is Node2D and shooter.is_in_group("player"):
				ws_scr.notify_fp_melee_hit(shooter as Node2D, body, direction, bf, 1.35)
		queue_free()
	elif body is StaticBody2D or body is TileMapLayer:
		if is_bullet:
			queue_free()
		else:
			_stick_in_ground()
