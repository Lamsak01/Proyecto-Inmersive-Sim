@tool
extends CharacterBody2D
class_name DomesticPet

## Mascotas Domésticas de la Aldea y la Granja (Perros y Gatos) — Fase 6
## - Pasean cerca de su casa/dueño de día y duermen por la noche (salvo el Perro Guardián del gallinero).
## - Interactuables con [E]: puedes acariciarlos o darles comida (Carne/Pollo para perros, Pescado/Pollo para gatos).
## - El Perro Guardián de la granja protege activamente el Gallinero por la noche ladrando y ahuyentando a los zorros.

enum PetType { DOG, CAT }

@export var pet_type: PetType = PetType.DOG
@export var pet_name: String = "Toby"
@export var owner_label: String = "Granja"
@export var home_position: Vector2 = Vector2.ZERO
@export var is_guard_dog: bool = false
@export var tint_color: Color = Color.WHITE

var is_fed_today: bool = true
var affection: float = 75.0
var _wander_target: Vector2 = Vector2.ZERO
var _wander_timer: float = 1.0
var _hop_phase: float = 0.0
var _guard_scan_timer: float = 0.4
var _bark_cooldown: float = 0.0
var _player_near: bool = false

var sprite: Sprite2D = null
var status_label: Label = null
var interact_area: Area2D = null

const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

func _ready() -> void:
	var in_editor := Engine.is_editor_hint()
	set_physics_process(not in_editor)
	add_to_group("domestic_pets")
	collision_layer = 0
	collision_mask = 1

	if home_position == Vector2.ZERO:
		home_position = global_position
	_wander_target = home_position

	_setup_visuals()
	if not in_editor and WorldClock:
		WorldClock.day_passed.connect(_on_day_passed)

func _setup_visuals() -> void:
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 5.0
	col.shape = c
	add_child(col)

	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	var tex_path: String = "res://assests/world/pets/pet_dog.png" if pet_type == PetType.DOG else "res://assests/world/pets/pet_cat.png"
	sprite.texture = _load_tex(tex_path)
	sprite.modulate = tint_color
	sprite.scale = Vector2(1.15, 1.15)
	sprite.position = Vector2(0, -5)
	add_child(sprite)

	interact_area = Area2D.new()
	interact_area.name = "PetInteractArea"
	interact_area.collision_layer = 1
	interact_area.collision_mask = 2
	interact_area.add_to_group("interactable")
	var icol := CollisionShape2D.new()
	var ic := CircleShape2D.new()
	ic.radius = 16.0
	icol.shape = ic
	interact_area.add_child(icol)
	interact_area.body_entered.connect(func(b: Node): if b.is_in_group("player"): _player_near = true)
	interact_area.body_exited.connect(func(b: Node): if b.is_in_group("player"): _player_near = false)
	add_child(interact_area)

	status_label = Label.new()
	status_label.visible = false
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-115, -28)
	status_label.custom_minimum_size = Vector2(230, 18)
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.68))
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 3)
	status_label.z_index = 22
	add_child(status_label)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen():
		return

	if _bark_cooldown > 0.0:
		_bark_cooldown -= delta

	var is_night: bool = false
	if WorldClock:
		var h: int = WorldClock.current_hour
		is_night = (h >= 21 or h < 6)

	# Si es perro guardián y comió hoy, vigila contra zorros cerca del gallinero
	if pet_type == PetType.DOG and is_guard_dog:
		_guard_scan_timer -= delta
		if _guard_scan_timer <= 0.0:
			_guard_scan_timer = 0.45
			_check_for_fox_intruders()

	if is_night and not is_guard_dog:
		# Dormir junto a su casa
		var to_home: Vector2 = home_position - global_position
		if to_home.length() > 8.0:
			velocity = to_home.normalized() * 32.0
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			if sprite:
				sprite.scale = Vector2(1.18, 0.92)
		_update_label()
		return

	if sprite:
		sprite.scale = Vector2(1.15, 1.15)

	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(2.0, 4.5)
		var radius: float = 28.0 if is_guard_dog else 36.0
		_wander_target = home_position + Vector2(randf_range(-radius, radius), randf_range(-radius, radius))

	var diff: Vector2 = _wander_target - global_position
	if diff.length() > 4.0:
		var spd: float = 36.0 if pet_type == PetType.DOG else 30.0
		velocity = diff.normalized() * spd
		move_and_slide()
		if sprite:
			sprite.flip_h = velocity.x < -1.0
			_hop_phase += delta * 12.0
			sprite.offset.y = -absf(sin(_hop_phase)) * 1.8
	else:
		velocity = Vector2.ZERO
		if sprite:
			sprite.offset.y = 0.0

	_update_label()

func _check_for_fox_intruders() -> void:
	if not is_fed_today:
		return
	var coop := get_tree().get_first_node_in_group("chicken_coop") as Node2D
	var guard_center: Vector2 = coop.global_position if is_instance_valid(coop) else home_position

	for node in get_tree().get_nodes_in_group("wild_animals"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		var anim_node: Node2D = node as Node2D
		# Species.FOX == 1 en WildAnimal.gd
		var sp_val: int = int(anim_node.get("species")) if "species" in anim_node else -1
		var is_dead_flag: bool = bool(anim_node.get("is_dead")) if "is_dead" in anim_node else false
		if sp_val == 1 and not is_dead_flag:
			var dist_to_coop: float = anim_node.global_position.distance_to(guard_center)
			if dist_to_coop <= 98.0:
				_wander_target = anim_node.global_position
				if anim_node.has_method("_enter_flee"):
					anim_node.call("_enter_flee", global_position)
				if _bark_cooldown <= 0.0:
					_bark_cooldown = 4.5
					_spawn_floating_text("🐕💢 ¡GUAU GUAU! (Zorro ahuyentado)", Color.GOLD)
					var player = get_tree().get_first_node_in_group("player")
					if player and player.has_method("show_hint"):
						player.show_hint("🐕🛡️ ¡%s ha ladrado y ahuyentado a un Zorro que intentaba acercarse al Gallinero!" % pet_name)
				break

func interact(player: Node2D) -> void:
	if not player:
		return
	var inv: SimpleInventory = player.get("inventory") if "inventory" in player else null
	var icon_str: String = "🐕" if pet_type == PetType.DOG else "🐈"
	var sound_str: String = "¡Guau guau!" if pet_type == PetType.DOG else "¡Prrr miau!"

	# Si aún no ha comido hoy y el jugador lleva comida adecuada, alimentarlo
	if inv and not is_fed_today:
		var food_candidates: Array[String] = ["raw_meat", "raw_chicken", "cooked_meat"] if pet_type == PetType.DOG else ["river_trout", "golden_carp", "raw_chicken", "cooked_fish"]
		for f_id in food_candidates:
			if inv.has_item(f_id, 1):
				var f_name: String = inv.get_item_name(f_id)
				inv.remove_item(f_id, 1)
				is_fed_today = true
				affection = clampf(affection + 20.0, 0.0, 100.0)
				_play_happy_bounce()
				_spawn_floating_text("%s🍖 %s comió %s (Lealtad %d%%)" % [icon_str, pet_name, f_name, int(affection)], Color.SPRING_GREEN)
				_boost_nearby_npc_mood()
				return

	# Acariciar a la mascota
	affection = clampf(affection + 5.0, 0.0, 100.0)
	_play_happy_bounce()
	_spawn_floating_text("%s❤️ %s: %s (Afecto %d%%)" % [icon_str, pet_name, sound_str, int(affection)], Color.PINK)
	_boost_nearby_npc_mood()
	if player.has_node("StaminaComponent"):
		var stam: StaminaComponent = player.get_node("StaminaComponent")
		stam.current_stamina = minf(stam.max_stamina, stam.current_stamina + 10.0)
		stam.stamina_changed.emit(stam.current_stamina, stam.max_stamina)

func _boost_nearby_npc_mood() -> void:
	for npc in get_tree().get_nodes_in_group("village_npcs"):
		if is_instance_valid(npc) and npc is Node2D:
			if (npc as Node2D).global_position.distance_squared_to(global_position) <= 180.0 * 180.0:
				if npc.has_method("add_thought"):
					npc.call("add_thought", "Vio a %s feliz (+6)" % pet_name, 6.0)

func _play_happy_bounce() -> void:
	if not sprite:
		return
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(1.35, 1.35), 0.08)
	tw.tween_property(sprite, "scale", Vector2(1.15, 1.15), 0.08)

func _on_day_passed(_new_day: int) -> void:
	# Por defecto empieza el día con hambre para que puedas alimentarlo si quieres (aunque el perro guardián mantiene guardia si tiene afecto alto)
	is_fed_today = (affection >= 60.0)

func _update_label() -> void:
	if not status_label:
		return
	var mouse_near: bool = global_position.distance_squared_to(get_global_mouse_position()) <= 24.0 * 24.0
	if _player_near or mouse_near:
		var icon_str: String = "🐕" if pet_type == PetType.DOG else "🐈"
		var role_tag: String = "Guardián del Gallinero" if is_guard_dog else owner_label
		var act_tag: String = "E: Acariciar" if is_fed_today else "E: Alimentar / Acariciar"
		status_label.text = "%s %s (%s) [%s]" % [icon_str, pet_name, role_tag, act_tag]
		status_label.visible = true
	else:
		status_label.visible = false

func _spawn_floating_text(text: String, color: Color) -> void:
	if FloatingTextScene:
		var ft = FloatingTextScene.instantiate()
		ft.start_text = text
		ft.text_color = color
		ft.global_position = global_position + Vector2(0, -24)
		get_tree().current_scene.add_child(ft)

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
