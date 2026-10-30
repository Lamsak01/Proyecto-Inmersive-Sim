extends Area2D
class_name ArrowProjectile

## Proyectil de Flecha con Caída Balística y Escala Proporcionada — Fase 3.4
## Vuela describiendo un arco parabólico con sombra en el suelo, tiene alcance limitado
## y al perder fuerza cae y se clava en la tierra en lugar de volar infinitamente.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var max_range: float = 330.0
var damage_data: DamageData = null
var shooter: Node = null

var _traveled_dist: float = 0.0
var _is_grounded: bool = false
var _arrow_sprite: Sprite2D = null
var _shadow_line: Line2D = null
var _col_shape: CollisionShape2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 5 # Capas 1 (entorno/obstáculos) y 3 (hurtboxes de enemigos/animales)
	rotation = direction.angle()

	_col_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 3.0)
	_col_shape.shape = rect
	add_child(_col_shape)

	# Sombra sutil en el suelo con el doble de largo para acompañar la flecha
	_shadow_line = Line2D.new()
	_shadow_line.width = 1.3
	_shadow_line.default_color = Color(0.0, 0.0, 0.0, 0.35)
	_shadow_line.points = PackedVector2Array([Vector2(-8, 2.5), Vector2(8, 2.5)])
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
	_arrow_sprite.scale = Vector2(1.1, 0.65)
	add_child(_arrow_sprite)

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _is_grounded:
		return

	var progress: float = clampf(_traveled_dist / maxf(1.0, max_range), 0.0, 1.0)
	# La flecha pierde algo de velocidad al final de su parábola
	var current_speed: float = speed * lerpf(1.0, 0.65, progress * progress)
	var step: float = current_speed * delta

	global_position += direction * step
	_traveled_dist += step

	# Arco parabólico visual (se eleva levemente al inicio y cae hacia el suelo al final)
	if _arrow_sprite:
		var arc_height: float = sin(progress * PI) * 5.5
		_arrow_sprite.position.y = -arc_height
		# Ligera inclinación de caída en el último tramo del vuelo
		if progress > 0.65:
			var drop_t: float = (progress - 0.65) / 0.35
			_arrow_sprite.rotation = drop_t * 0.28 * (1.0 if direction.x >= 0.0 else -1.0)

	if _traveled_dist >= max_range:
		_stick_in_ground()

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
	if area is Hurtbox and damage_data:
		_is_grounded = true
		if _col_shape:
			_col_shape.set_deferred("disabled", true)
		area.receive_damage(damage_data)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _is_grounded or body == shooter:
		return
	if (body.is_in_group("wild_animals") or body.is_in_group("destructible")) and body.has_method("take_damage") and damage_data:
		_is_grounded = true
		if _col_shape:
			_col_shape.set_deferred("disabled", true)
		body.take_damage(damage_data)
		queue_free()
	elif body is StaticBody2D or body is TileMapLayer:
		_stick_in_ground()
