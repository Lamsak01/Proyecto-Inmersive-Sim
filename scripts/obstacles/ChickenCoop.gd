extends Node2D
class_name ChickenCoop

## Gallinero Cuadrado con Comedero de 2 Toques, Nido de Huevos y Brecha por Ataque de Zorros — Fase 5.1
## - Cercado cuadrado con 3-5 Gallinas que pasean dentro, comen del comedero y ponen huevos cada mañana.
## - Comedero ([E] Llenar 0/2 -> 1/2 -> 2/2): Se llena en dos toques de [E] en modo prueba.
## - Nido ([E] Recoger Huevos): Acumula Huevos Frescos ("egg") puestos por las gallinas alimentadas.
## - Defensa Nocturna contra Zorros: Si un zorro del bosque no consiguió comer de día, viene de noche al
##   borde del gallinero, muerde la cerca hasta abrir un agujero (`is_breached = true`) y caza una gallina.
##   Puedes reparar el agujero pulsando [E] en la cerca rota.

var feeder_level: int = 1 # 0 = Vacío, 1 = Mitad (1/2), 2 = Lleno (2/2)
var eggs_in_nest: int = 2
var is_breached: bool = false
var fence_hp: float = 3.0
const MAX_FENCE_HP: float = 3.0

var feeder_sprite: Sprite2D = null
var nest_sprite: Sprite2D = null
var south_fence_left: Line2D = null
var south_fence_gap: Line2D = null
var south_fence_right: Line2D = null
var breach_marker: Label = null
var status_label: Label = null

var _tex_feeder_empty: Texture2D = null
var _tex_feeder_half: Texture2D = null
var _tex_feeder_full: Texture2D = null
var _tex_nest_empty: Texture2D = null
var _tex_nest_eggs: Texture2D = null
var _tex_chicken: Texture2D = null

var chickens: Array[Dictionary] = []
var _player_near: bool = false
var _eat_timer: float = 0.0
var _warn_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("chicken_coop")
	_tex_feeder_empty = _load_tex("res://assests/world/camp/coop_feeder_empty.png")
	_tex_feeder_half = _load_tex("res://assests/world/camp/coop_feeder_half.png")
	_tex_feeder_full = _load_tex("res://assests/world/camp/coop_feeder_full.png")
	_tex_nest_empty = _load_tex("res://assests/world/camp/coop_nest_empty.png")
	_tex_nest_eggs = _load_tex("res://assests/world/camp/coop_nest_eggs.png")
	_tex_chicken = _load_tex("res://assests/world/camp/chicken.png")

	_build_fence_enclosure()
	_build_feeder_and_nest()
	_spawn_initial_chickens(3)
	_refresh_coop_visuals()

	if WorldClock:
		WorldClock.day_passed.connect(_on_day_passed)
	if GameManager:
		GameManager.game_loaded.connect(_on_game_loaded)

	_load_saved_state()

func _build_fence_enclosure() -> void:
	# Suelo de tierra suave del gallinero
	var floor_poly := Polygon2D.new()
	floor_poly.polygon = PackedVector2Array([
		Vector2(-38, -30), Vector2(38, -30), Vector2(38, 30), Vector2(-38, 30)
	])
	floor_poly.color = Color(0.46, 0.36, 0.22, 0.42)
	floor_poly.z_index = -2
	add_child(floor_poly)

	var fence_col := Color(0.58, 0.38, 0.20, 1.0)
	# Paredes Norte, Oeste y Este
	var main_fence := Line2D.new()
	main_fence.width = 3.0
	main_fence.default_color = fence_col
	main_fence.points = PackedVector2Array([
		Vector2(-38, 30), Vector2(-38, -30), Vector2(38, -30), Vector2(38, 30)
	])
	add_child(main_fence)

	# Pared Sur dividida en 3 tramos para que el tramo central pueda abrirse cuando un zorro hace un agujero
	south_fence_left = Line2D.new()
	south_fence_left.width = 3.0
	south_fence_left.default_color = fence_col
	south_fence_left.points = PackedVector2Array([Vector2(-38, 30), Vector2(-12, 30)])
	add_child(south_fence_left)

	south_fence_gap = Line2D.new()
	south_fence_gap.width = 3.0
	south_fence_gap.default_color = fence_col
	south_fence_gap.points = PackedVector2Array([Vector2(-12, 30), Vector2(12, 30)])
	add_child(south_fence_gap)

	south_fence_right = Line2D.new()
	south_fence_right.width = 3.0
	south_fence_right.default_color = fence_col
	south_fence_right.points = PackedVector2Array([Vector2(12, 30), Vector2(38, 30)])
	add_child(south_fence_right)

	breach_marker = Label.new()
	breach_marker.visible = false
	breach_marker.text = "🕳️ [Agujero]"
	breach_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	breach_marker.position = Vector2(-45, 22)
	breach_marker.custom_minimum_size = Vector2(90, 16)
	breach_marker.add_theme_font_size_override("font_size", 8)
	breach_marker.add_theme_color_override("font_color", Color.ORANGE_RED)
	breach_marker.add_theme_color_override("font_outline_color", Color.BLACK)
	breach_marker.add_theme_constant_override("outline_size", 3)
	add_child(breach_marker)

func _build_feeder_and_nest() -> void:
	feeder_sprite = Sprite2D.new()
	feeder_sprite.name = "FeederSprite"
	feeder_sprite.position = Vector2(-18, -16)
	feeder_sprite.scale = Vector2(1.2, 1.2)
	add_child(feeder_sprite)

	nest_sprite = Sprite2D.new()
	nest_sprite.name = "NestSprite"
	nest_sprite.position = Vector2(18, -16)
	nest_sprite.scale = Vector2(1.2, 1.2)
	add_child(nest_sprite)

	var area := Area2D.new()
	area.name = "CoopInteractArea"
	area.collision_layer = 1
	area.collision_mask = 2
	area.add_to_group("interactable")
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(88, 74)
	col.shape = rect
	area.add_child(col)
	area.body_entered.connect(func(b): if b.is_in_group("player"): _player_near = true)
	area.body_exited.connect(func(b): if b.is_in_group("player"): _player_near = false)
	add_child(area)

	status_label = Label.new()
	status_label.visible = false
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-135, -48)
	status_label.custom_minimum_size = Vector2(270, 20)
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68))
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 3)
	status_label.z_index = 20
	add_child(status_label)

func _spawn_initial_chickens(count: int) -> void:
	for i in range(count):
		_add_chicken()

func _add_chicken() -> void:
	if chickens.size() >= 6:
		return
	var spr := Sprite2D.new()
	spr.texture = _tex_chicken
	spr.scale = Vector2(1.05, 1.05)
	spr.position = Vector2(randf_range(-24.0, 24.0), randf_range(-8.0, 18.0))
	add_child(spr)

	chickens.append({
		"sprite": spr,
		"target": spr.position,
		"timer": randf_range(0.5, 2.2),
		"fed": true,
		"hop": randf() * TAU
	})

func has_live_chickens() -> bool:
	return not chickens.is_empty()

func get_breach_world_position() -> Vector2:
	return global_position + Vector2(0, 32)

## El zorro hambriento muerde la cerca del gallinero para abrir un agujero y entrar
func damage_fence_by_fox(dmg: float = 1.0) -> bool:
	if is_breached:
		return true
	fence_hp -= dmg
	if south_fence_gap:
		var tw := create_tween()
		tw.tween_property(south_fence_gap, "default_color", Color.RED, 0.08)
		tw.tween_property(south_fence_gap, "default_color", Color(0.58, 0.38, 0.20), 0.12)

	if _warn_cooldown <= 0.0:
		_warn_cooldown = 4.0
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("show_hint"):
			player.show_hint("🦊⚠️ ¡Un Zorro hambriento está mordiendo la cerca del Gallinero para entrar!")

	if fence_hp <= 0.0:
		is_breached = true
		_refresh_coop_visuals()
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("show_hint"):
			player.show_hint("🕳️⚠️ ¡El Zorro abrió un agujero en el Gallinero!")
		return true
	return false

## Cuando el zorro ya abrió el agujero y captura una gallina
func steal_chicken_by_fox() -> bool:
	if chickens.is_empty():
		return false
	var victim: Dictionary = chickens.pop_back()
	var spr: Sprite2D = victim.get("sprite")
	if is_instance_valid(spr):
		spr.queue_free()
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("show_hint"):
		player.show_hint("🐔💀 ¡Un Zorro se ha llevado una gallina del Gallinero! (%d restantes)" % chickens.size())
	return true

func _process(delta: float) -> void:
	if _warn_cooldown > 0.0:
		_warn_cooldown -= delta

	_update_chickens_motion(delta)

	var mouse_near := global_position.distance_squared_to(get_global_mouse_position()) <= 42.0 * 42.0
	if status_label:
		if _player_near or mouse_near:
			status_label.text = _get_coop_prompt()
			status_label.visible = true
		else:
			status_label.visible = false

func _update_chickens_motion(delta: float) -> void:
	var is_night := false
	if WorldClock:
		var h: int = WorldClock.current_hour
		is_night = (h >= 20 or h < 6)

	# Si hay comida en el comedero, las gallinas con hambre van comiendo durante el día
	if not is_night and feeder_level > 0:
		_eat_timer += delta
		if _eat_timer >= 6.0:
			_eat_timer = 0.0
			for chk in chickens:
				if not chk["fed"]:
					chk["fed"] = true
					feeder_level = maxi(0, feeder_level - 1)
					_refresh_coop_visuals()
					break

	for chk in chickens:
		var spr: Sprite2D = chk["sprite"]
		if not is_instance_valid(spr):
			continue
		if is_night:
			spr.scale.y = 0.85
			continue
		spr.scale.y = 1.05
		chk["timer"] = float(chk["timer"]) - delta
		if float(chk["timer"]) <= 0.0:
			chk["timer"] = randf_range(1.4, 3.2)
			if not chk["fed"] and feeder_level > 0:
				chk["target"] = Vector2(-18, -8) + Vector2(randf_range(-6, 6), randf_range(-4, 6))
			else:
				chk["target"] = Vector2(randf_range(-28.0, 28.0), randf_range(-10.0, 20.0))

		var target: Vector2 = chk["target"]
		var diff := target - spr.position
		if diff.length() > 2.0:
			var step := diff.normalized() * 18.0 * delta
			spr.position += step
			spr.flip_h = diff.x > 0.0
			chk["hop"] = float(chk["hop"]) + delta * 14.0
			spr.offset.y = -abs(sin(float(chk["hop"]))) * 2.0
		else:
			spr.offset.y = 0.0

## Interacción con [E] en el Gallinero: Reparar agujero -> Recoger Huevos -> Llenar Comedero (2 toques)
func interact(player: Node2D) -> void:
	if not player:
		return
	var inv: SimpleInventory = player.get("inventory")

	# 1. Si la cerca tiene un agujero de zorro, repararla primero
	if is_breached:
		is_breached = false
		fence_hp = MAX_FENCE_HP
		_refresh_coop_visuals()
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🔨 Agujero del Gallinero reparado", Color.SPRING_GREEN, -42.0)
		return

	# 2. Si hay huevos en el nido y el jugador está más cerca del nido (derecha) o el comedero ya está lleno
	var d_feeder: float = player.global_position.distance_squared_to(global_position + Vector2(-18, -16))
	var d_nest: float = player.global_position.distance_squared_to(global_position + Vector2(18, -16))

	if eggs_in_nest > 0 and (d_nest <= d_feeder or feeder_level >= 2):
		var collected := eggs_in_nest
		eggs_in_nest = 0
		if inv:
			inv.add_item("egg", collected)
		_refresh_coop_visuals()
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🥚 Recogido: +%d Huevo Fresco" % collected, Color.GOLD, -42.0)
		return

	# 3. Llenar el Comedero (sistema de 2 toques [E]: 0/2 -> 1/2 -> 2/2)
	if feeder_level < 2:
		feeder_level += 1
		# Alimentar también a una gallina al llenar
		for chk in chickens:
			if not chk["fed"]:
				chk["fed"] = true
				break
		_refresh_coop_visuals()
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🌾 Comedero llenado (%d/2)" % feeder_level, Color.SPRING_GREEN, -42.0)
		return

	# 4. Si el comedero ya está 2/2 y aún quedaban huevos
	if eggs_in_nest > 0:
		var collected := eggs_in_nest
		eggs_in_nest = 0
		if inv:
			inv.add_item("egg", collected)
		_refresh_coop_visuals()
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🥚 Recogido: +%d Huevo Fresco" % collected, Color.GOLD, -42.0)
		return

	if player.has_method("show_hint"):
		player.show_hint("🐔 Gallinero al día: %d Gallinas | Comedero Lleno (2/2) | Sin huevos por recoger." % chickens.size())

func _on_day_passed(_new_day: int) -> void:
	var fed_count := 0
	for chk in chickens:
		if chk["fed"] or feeder_level > 0:
			if not chk["fed"] and feeder_level > 0:
				feeder_level -= 1
			chk["fed"] = true
			fed_count += 1
		chk["fed"] = false

	# Cada gallina alimentada pone 1 huevo al amanecer (máx 6 en el nido)
	if fed_count > 0:
		eggs_in_nest = mini(6, eggs_in_nest + fed_count)
	# Si al menos 2 gallinas comieron bien y hay espacio, nace un polluelo/gallina nueva
	if fed_count >= 2 and chickens.size() < 5:
		_add_chicken()

	_refresh_coop_visuals()

func _refresh_coop_visuals() -> void:
	if feeder_sprite:
		if feeder_level <= 0:
			feeder_sprite.texture = _tex_feeder_empty
		elif feeder_level == 1:
			feeder_sprite.texture = _tex_feeder_half
		else:
			feeder_sprite.texture = _tex_feeder_full

	if nest_sprite:
		nest_sprite.texture = _tex_nest_eggs if eggs_in_nest > 0 else _tex_nest_empty

	if south_fence_gap:
		south_fence_gap.visible = not is_breached
	if breach_marker:
		breach_marker.visible = is_breached
	_save_state()

func _save_state() -> void:
	if not GameManager:
		return
	GameManager.set_flag("player_chicken_coop", {
		"feeder": feeder_level,
		"eggs": eggs_in_nest,
		"breached": is_breached,
		"fence_hp": fence_hp,
		"chickens": chickens.size()
	})

func _load_saved_state() -> void:
	if not GameManager:
		return
	var saved: Variant = GameManager.get_flag("player_chicken_coop", null)
	if typeof(saved) == TYPE_DICTIONARY:
		feeder_level = int(saved.get("feeder", 1))
		eggs_in_nest = int(saved.get("eggs", 2))
		is_breached = bool(saved.get("breached", false))
		fence_hp = float(saved.get("fence_hp", MAX_FENCE_HP))
		var target_c: int = clampi(int(saved.get("chickens", 3)), 0, 6)
		while chickens.size() > target_c:
			var removed: Dictionary = chickens.pop_back()
			var spr: Sprite2D = removed.get("sprite")
			if is_instance_valid(spr):
				spr.queue_free()
		while chickens.size() < target_c:
			_add_chicken()
		_refresh_coop_visuals()

func _on_game_loaded(_filepath: String) -> void:
	_load_saved_state()

func _get_coop_prompt() -> String:
	if is_breached:
		return "⚠️ Gallinero Con Agujero (%d 🐔) [E: Reparar Cerca]" % chickens.size()
	var parts: Array[String] = []
	if feeder_level < 2:
		parts.append("E: Llenar Comedero (%d/2)" % feeder_level)
	else:
		parts.append("Comedero 2/2")
	if eggs_in_nest > 0:
		parts.append("E: Recoger %d Huevos" % eggs_in_nest)
	return "🐔 Gallinero (%d) [%s]" % [chickens.size(), " | ".join(parts)]

func _load_tex(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var t = load(res_path)
		if t is Texture2D:
			return t
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null
