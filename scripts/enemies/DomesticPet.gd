@tool
extends CharacterBody2D
class_name DomesticPet

## Mascotas Domésticas Vivas y Mortales de la Aldea y la Granja (Perros y Gatos)
## - Entidades 100% sistémicas: tienen Salud (`HealthComponent`), Sangrado, Aturdimiento (`StunComponent`),
##   Hambre real (`need_hunger`), Energía/Sueño (`need_energy`), combate defensivo (Perros) o huida (Gatos),
##   muerte real e inanición si su familia muere y nadie las alimenta, y cadáver saqueable con [E].

enum PetType { DOG, CAT }

@export var pet_type: PetType = PetType.DOG
@export var pet_name: String = "Toby"
@export var owner_label: String = "Granja"
@export var family_id: String = "none"
@export var home_position: Vector2 = Vector2.ZERO
@export var is_guard_dog: bool = false
@export var tint_color: Color = Color.WHITE

var is_fed_today: bool = true
var affection: float = 75.0
var need_hunger: float = 88.0
var digestion_buffer: float = 0.0
var need_energy: float = 92.0

var is_dead: bool = false
var corpse_looted: bool = false
var is_stunned_flag: bool = false
var is_sleeping: bool = false
var is_hostile: bool = false
var _hostile_timer: float = 0.0
var _flee_timer: float = 0.0
var _flee_from_pos: Vector2 = Vector2.ZERO
var _attack_cooldown: float = 0.0
var _starve_tick_timer: float = 0.0

var _wander_target: Vector2 = Vector2.ZERO
var _wander_timer: float = 1.0
var _sleep_walk_timer: float = 0.0
var _hop_phase: float = 0.0
var _guard_scan_timer: float = 0.4
var _bark_cooldown: float = 0.0
var _label_timer: float = 0.0
var _player_near: bool = false

var sprite: Sprite2D = null
var status_label: Label = null
var interact_area: Area2D = null
var hurtbox: Hurtbox = null
var health_comp: HealthComponent = null
var stun_comp: StunComponent = null

const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

func _ready() -> void:
	var in_editor := Engine.is_editor_hint()
	set_physics_process(not in_editor)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("domestic_pets")
	# Sin Body Block (layer 0): el jugador y los NPCs atraviesan libremente a las mascotas sin quedar bloqueados
	collision_layer = 0
	collision_mask = 1

	if home_position == Vector2.ZERO:
		home_position = global_position
	_wander_target = home_position

	_setup_components_and_visuals()
	if not in_editor and WorldClock:
		if not WorldClock.day_passed.is_connected(_on_day_passed):
			WorldClock.day_passed.connect(_on_day_passed)

func _setup_components_and_visuals() -> void:
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 5.0
	col.shape = c
	add_child(col)

	health_comp = HealthComponent.new()
	health_comp.name = "HealthComponent"
	health_comp.max_health = 45.0 if pet_type == PetType.DOG else 24.0
	health_comp.current_health = health_comp.max_health
	health_comp.died.connect(_on_died)
	health_comp.bleed_triggered.connect(func():
		_spawn_floating_text("🩸 ¡Sangrado!", Color.CRIMSON)
	)
	add_child(health_comp)

	stun_comp = StunComponent.new()
	stun_comp.name = "StunComponent"
	stun_comp.max_stun = 60.0 if pet_type == PetType.DOG else 35.0
	stun_comp.stun_duration = 6.0
	stun_comp.stunned.connect(_on_stunned)
	add_child(stun_comp)

	hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 0
	var h_col := CollisionShape2D.new()
	var h_circle := CircleShape2D.new()
	h_circle.radius = 9.0
	h_col.shape = h_circle
	hurtbox.add_child(h_col)
	hurtbox.hit_received.connect(take_damage)
	add_child(hurtbox)

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
	status_label.position = Vector2(-125, -32)
	status_label.custom_minimum_size = Vector2(250, 22)
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.68))
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 3)
	status_label.z_index = 22
	add_child(status_label)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or corpse_looted:
		return
	if is_dead:
		velocity = Vector2.ZERO
		_update_label(delta)
		return
	if WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen():
		return

	if _bark_cooldown > 0.0:
		_bark_cooldown -= delta
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta

	if is_stunned_flag:
		velocity = Vector2.ZERO
		_update_label(delta)
		return

	# 1. Digestión gradual estilo Kenshi + Desgaste biológico de 3 días (100% -> 0% en 72 horas = 1080s reales)
	if digestion_buffer > 0.0:
		var absorb: float = minf(digestion_buffer, 0.42 * delta)
		digestion_buffer = maxf(0.0, digestion_buffer - absorb)
		need_hunger = minf(100.0, need_hunger + absorb)
	else:
		var hunger_rate: float = 0.055 if is_sleeping else 0.098
		need_hunger = maxf(0.0, need_hunger - hunger_rate * delta)

	if is_sleeping:
		need_energy = minf(100.0, need_energy + 1.25 * delta)
	else:
		var fat_mult: float = lerpf(1.25, 1.0, clampf(need_hunger / 60.0, 0.0, 1.0))
		need_energy = maxf(0.0, need_energy - 0.145 * fat_mult * delta)

	# Si tiene hambre (< 70%) y no está ya digiriendo comida, intenta comer en su casa si su familia sigue viva
	if need_hunger < 70.0 and digestion_buffer < 10.0 and not is_hostile and _flee_timer <= 0.0:
		_try_eat_from_home_bowl(delta)

	# Solo tras 3 días completos sin comer (`need_hunger <= 0%` y `digestion_buffer <= 0%`) sufre daño letal por inanición
	if need_hunger <= 0.0 and digestion_buffer <= 0.0:
		_starve_tick_timer -= delta
		if _starve_tick_timer <= 0.0:
			_starve_tick_timer = 3.5
			if health_comp:
				var st_dmg := DamageData.new()
				st_dmg.amount = 3.0
				health_comp.take_damage(st_dmg)
				_spawn_floating_text("💀🍖 ¡%s muere de hambre (+3 días)!" % pet_name, Color.ORANGE_RED)
		if is_dead:
			return

	var pet_spd_mult: float = 1.0
	if need_hunger < 33.33:
		pet_spd_mult = lerpf(0.45, 0.70, clampf(need_hunger / 33.33, 0.0, 1.0))
	elif need_hunger < 66.67:
		pet_spd_mult = lerpf(0.70, 1.0, (need_hunger - 33.33) / 33.34)

	# 2. Huida por pánico (Gatos o mascotas heridas)
	if _flee_timer > 0.0:
		_flee_timer -= delta
		is_sleeping = false
		var away: Vector2 = (global_position - _flee_from_pos).normalized()
		if away.length_squared() < 0.01:
			away = Vector2.RIGHT
		velocity = away * 74.0
		move_and_slide()
		if sprite:
			sprite.rotation_degrees = 0.0
			sprite.flip_h = velocity.x < -1.0
		_update_label(delta)
		return

	# 3. Combate defensivo (Perros atacados)
	if is_hostile and pet_type == PetType.DOG:
		_hostile_timer -= delta
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if _hostile_timer <= 0.0 or not is_instance_valid(player) or global_position.distance_to(player.global_position) > 190.0:
			is_hostile = false
			remove_from_group("enemies")
		else:
			is_sleeping = false
			var dist_p: float = global_position.distance_to(player.global_position)
			if dist_p > 18.0:
				velocity = (player.global_position - global_position).normalized() * (68.0 * pet_spd_mult)
				move_and_slide()
			else:
				velocity = Vector2.ZERO
				if _attack_cooldown <= 0.0:
					_attack_cooldown = 1.05
					if player.has_method("take_damage"):
						var bite := DamageData.new()
						bite.amount = 9.0 * pet_spd_mult
						bite.type = CombatConstants.DamageType.CUT
						bite.bleed_buildup = 18.0 * pet_spd_mult
						bite.source = self
						player.call("take_damage", bite)
						_spawn_floating_text("🐕🦷 ¡Mordisco de %s!" % pet_name, Color.ORANGE_RED)
			_update_label(delta)
			return

	var is_night: bool = false
	if WorldClock:
		var h: int = WorldClock.current_hour
		is_night = (h >= 22 or h < 6)

	# Si es perro guardián con energía y sin hambre crítica, vigila contra zorros cerca del gallinero
	if pet_type == PetType.DOG and is_guard_dog and need_hunger > 15.0 and need_energy > 22.0 and not is_sleeping:
		_guard_scan_timer -= delta
		if _guard_scan_timer <= 0.0:
			_guard_scan_timer = 0.45
			_check_for_fox_intruders()

	if (is_night and not is_guard_dog) or need_energy < 25.0 or (is_sleeping and need_energy < 92.0):
		var to_home: Vector2 = home_position - global_position
		if not is_sleeping and to_home.length() > 16.0 and _sleep_walk_timer < 3.2 and need_energy > 2.0:
			_sleep_walk_timer += delta
			velocity = to_home.normalized() * 36.0
			move_and_slide()
			if sprite:
				sprite.flip_h = velocity.x < -1.0
		else:
			if not is_sleeping:
				is_sleeping = true
				_sleep_walk_timer = 0.0
				_spawn_floating_text("💤 %s se echó a dormir en su cama" % pet_name, Color(0.75, 0.85, 1.0))
			velocity = Vector2.ZERO
			if sprite:
				sprite.offset.y = 0.0
				sprite.scale = Vector2(1.18, 0.88)
		_update_label(delta)
		return

	is_sleeping = false
	_sleep_walk_timer = 0.0
	if sprite:
		sprite.scale = Vector2(1.15, 1.15)

	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(2.0, 4.5)
		var radius: float = 28.0 if is_guard_dog else 36.0
		_wander_target = home_position + Vector2(randf_range(-radius, radius), randf_range(-radius, radius))

	var diff: Vector2 = _wander_target - global_position
	var soft_push: Vector2 = _compute_player_soft_push()
	if diff.length() > 4.0 or soft_push.length_squared() > 1.0:
		var spd: float = (36.0 if pet_type == PetType.DOG else 30.0) * pet_spd_mult
		var base_vel: Vector2 = diff.normalized() * spd if diff.length() > 4.0 else Vector2.ZERO
		velocity = base_vel + soft_push
		move_and_slide()
		if sprite:
			if absf(velocity.x) > 1.0:
				sprite.flip_h = velocity.x < -1.0
			_hop_phase += delta * 12.0
			sprite.offset.y = -absf(sin(_hop_phase)) * 1.8
	else:
		velocity = Vector2.ZERO
		if sprite:
			sprite.offset.y = 0.0

	_update_label(delta)

func _compute_player_soft_push() -> Vector2:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(p):
		return Vector2.ZERO
	var d_sq: float = global_position.distance_squared_to(p.global_position)
	var min_r: float = 15.0
	if d_sq >= min_r * min_r:
		return Vector2.ZERO
	var away: Vector2 = global_position - p.global_position
	var d: float = sqrt(d_sq)
	if d < 0.01:
		away = Vector2.RIGHT
	else:
		away = away / d
	return away * ((min_r - d) / min_r) * 58.0

func _try_eat_from_home_bowl(_delta: float) -> void:
	# Camina hacia su casa para buscar comida
	if global_position.distance_to(home_position) > 14.0:
		_wander_target = home_position
		return
	var vm = get_tree().get_first_node_in_group("village_manager")
	if family_id != "none" and vm and vm.has_method("can_family_feed_pet"):
		if bool(vm.call("can_family_feed_pet", family_id)):
			digestion_buffer = clampf(digestion_buffer + 38.0, 0.0, maxf(18.0, 100.0 - need_hunger))
			is_fed_today = true
			_spawn_floating_text("🥣↗ %s comió en casa (Digeriendo...)" % pet_name, Color.SPRING_GREEN)

func take_damage(data: DamageData) -> void:
	if is_dead or corpse_looted:
		return
	is_sleeping = false
	var attacker_is_player: bool = data != null and is_instance_valid(data.source) and data.source.is_in_group("player")
	if attacker_is_player:
		affection = maxf(0.0, affection - 45.0)
		var vm = get_tree().get_first_node_in_group("village_manager")
		if vm and vm.has_method("report_pet_assault_crime"):
			vm.call("report_pet_assault_crime", self)

	if pet_type == PetType.DOG:
		is_hostile = true
		_hostile_timer = 14.0
		add_to_group("enemies")
	else:
		_flee_timer = 6.0
		_flee_from_pos = data.source.global_position if (data and is_instance_valid(data.source)) else global_position

	if health_comp:
		health_comp.take_damage(data)
	if stun_comp and health_comp and health_comp.current_health > 0.0:
		stun_comp.take_damage(data)

func _on_stunned(stunned: bool) -> void:
	if is_dead:
		return
	is_stunned_flag = stunned
	if stunned:
		is_hostile = false
		remove_from_group("enemies")
		velocity = Vector2.ZERO
	if sprite:
		sprite.rotation_degrees = 90.0 if stunned else 0.0
		sprite.modulate = Color(0.65, 0.75, 1.0) if stunned else tint_color

func _on_died(silent: bool = false) -> void:
	if is_dead:
		return
	if health_comp:
		health_comp.stop_bleeding()
	is_dead = true
	is_hostile = false
	is_sleeping = false
	remove_from_group("enemies")
	velocity = Vector2.ZERO
	if hurtbox and hurtbox.get_child_count() > 0:
		var hcol := hurtbox.get_child(0) as CollisionShape2D
		if hcol:
			hcol.set_deferred("disabled", true)
	if sprite:
		sprite.rotation_degrees = 90.0
		sprite.offset.y = 0.0
		sprite.modulate = Color(0.62, 0.45, 0.45, 0.96)
	if not silent:
		_spawn_floating_text("💀 %s ha muerto" % pet_name, Color.CRIMSON)

func _check_for_fox_intruders() -> void:
	var coop := get_tree().get_first_node_in_group("chicken_coop") as Node2D
	var guard_center: Vector2 = coop.global_position if is_instance_valid(coop) else home_position

	for node in get_tree().get_nodes_in_group("wild_animals"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		var anim_node: Node2D = node as Node2D
		var sp_val: int = int(anim_node.get("species")) if "species" in anim_node else -1
		var is_alive_flag: bool = bool(anim_node.call("is_alive_in_ecosystem")) if anim_node.has_method("is_alive_in_ecosystem") else true
		if sp_val == 2 and is_alive_flag:
			var dist_to_coop: float = anim_node.global_position.distance_to(guard_center)
			if dist_to_coop <= 98.0:
				_wander_target = anim_node.global_position
				if anim_node.has_method("_start_flee_from"):
					anim_node.call("_start_flee_from", global_position)
				if _bark_cooldown <= 0.0:
					_bark_cooldown = 4.5
					_spawn_floating_text("🐕💢 ¡GUAU GUAU! (Zorro ahuyentado)", Color.GOLD)
					var player = get_tree().get_first_node_in_group("player")
					if player and player.has_method("show_hint"):
						player.show_hint("🐕🛡️ ¡%s ha ladrado y ahuyentado a un Zorro que intentaba acercarse al Gallinero!" % pet_name)
				break

func interact(player: Node2D) -> void:
	if not player or corpse_looted:
		return
	var inv: SimpleInventory = player.get("inventory") if "inventory" in player else null

	# Si está muerto en el suelo, [E] permite desollar/saquear el cuerpo
	if is_dead:
		corpse_looted = true
		visible = false
		if interact_area and interact_area.get_child_count() > 0:
			var ic := interact_area.get_child(0) as CollisionShape2D
			if ic:
				ic.set_deferred("disabled", true)
		var vm_skin = get_tree().get_first_node_in_group("village_manager")
		if vm_skin and vm_skin.has_method("report_pet_assault_crime"):
			vm_skin.call("report_pet_assault_crime", self)
		if inv:
			inv.add_item("raw_meat", 1)
			if pet_type == PetType.DOG:
				inv.add_item("leather", 1)
				_spawn_floating_text("🔪 Desollaste a %s (+1 Carne Cruda, +1 Cuero)" % pet_name, Color.ORANGE_RED)
			else:
				_spawn_floating_text("🔪 Desollaste a %s (+1 Carne Cruda)" % pet_name, Color.ORANGE_RED)
		return

	if is_stunned_flag:
		_spawn_floating_text("💫 %s está aturdido" % pet_name, Color.SKY_BLUE)
		return

	var icon_str: String = "🐕" if pet_type == PetType.DOG else "🐈"
	var sound_str: String = "¡Guau guau!" if pet_type == PetType.DOG else "¡Prrr miau!"

	# Si tiene hambre (< 80%) y el jugador lleva comida adecuada, alimentarlo
	if inv and (not is_fed_today or need_hunger < 80.0):
		var food_candidates: Array[String] = []
		if pet_type == PetType.DOG:
			food_candidates = ["raw_meat", "raw_chicken", "cooked_meat"]
		else:
			food_candidates = ["river_trout", "golden_carp", "raw_chicken", "cooked_fish"]
		for f_id in food_candidates:
			if inv.has_item(f_id, 1):
				var f_name: String = inv.get_item_name(f_id)
				inv.remove_item(f_id, 1)
				is_fed_today = true
				digestion_buffer = clampf(digestion_buffer + 42.0, 0.0, maxf(20.0, 100.0 - need_hunger))
				if health_comp:
					health_comp.heal(15.0)
				affection = clampf(affection + 20.0, 0.0, 100.0)
				_play_happy_bounce()
				_spawn_floating_text("%s🍖↗ %s comió %s (Digeriendo gradualmente | Lealtad %d%%)" % [icon_str, pet_name, f_name, int(affection)], Color.SPRING_GREEN)
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
	if is_dead:
		return
	is_fed_today = false

func _update_label(delta: float = 0.016) -> void:
	if not status_label:
		return
	_label_timer -= delta
	if _label_timer > 0.0:
		return
	_label_timer = 0.10

	var mouse_near: bool = global_position.distance_squared_to(get_global_mouse_position()) <= 24.0 * 24.0
	if _player_near or mouse_near:
		var icon_str: String = "🐕" if pet_type == PetType.DOG else "🐈"
		if is_dead:
			status_label.text = "💀 Cadáver de %s (%s)\n[E: Desollar / Saquear Carne]" % [pet_name, owner_label]
			status_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.55))
		elif is_stunned_flag:
			status_label.text = "💫 %s (%s) — Aturdido" % [pet_name, owner_label]
			status_label.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
		else:
			var role_tag: String = "Guardián del Gallinero" if is_guard_dog else owner_label
			var hp_pct: int = int(round((health_comp.current_health / maxf(1.0, health_comp.max_health)) * 100.0)) if health_comp else 100
			var sleep_tag: String = " · 💤 Durmiendo en Cama" if is_sleeping else ""
			var act_tag: String = "E: Acariciar" if (is_fed_today and need_hunger >= 75.0) else "E: Alimentar / Acariciar"
			status_label.text = "%s %s (%s%s)\n[❤️%d%% 🍖%d%% 💤%d%% | %s]" % [
				icon_str, pet_name, role_tag, sleep_tag, hp_pct, int(round(need_hunger)), int(round(need_energy)), act_tag
			]
			status_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.68))
		status_label.visible = true
	elif is_sleeping and not is_dead:
		status_label.text = "Zzz"
		status_label.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
		status_label.visible = true
	else:
		status_label.visible = false

func _spawn_floating_text(text: String, color: Color, offset_y: float = -24.0) -> void:
	if FloatingTextScene:
		var ft = FloatingTextScene.instantiate()
		ft.start_text = text
		ft.text_color = color
		ft.global_position = global_position + Vector2(0, offset_y)
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

func to_save_dict() -> Dictionary:
	return {
		"pet_name": pet_name,
		"is_fed_today": is_fed_today,
		"affection": affection,
		"need_hunger": need_hunger,
		"digestion_buffer": digestion_buffer,
		"need_energy": need_energy,
		"is_dead": is_dead,
		"corpse_looted": corpse_looted,
		"pos_x": global_position.x,
		"pos_y": global_position.y,
		"hp": health_comp.current_health if health_comp else 36.0
	}

func from_save_dict(data: Dictionary) -> void:
	is_fed_today = bool(data.get("is_fed_today", true))
	affection = clampf(float(data.get("affection", 75.0)), 0.0, 100.0)
	need_hunger = clampf(float(data.get("need_hunger", 90.0)), 0.0, 100.0)
	digestion_buffer = clampf(float(data.get("digestion_buffer", 0.0)), 0.0, 100.0)
	need_energy = clampf(float(data.get("need_energy", 90.0)), 0.0, 100.0)
	if data.has("pos_x") and data.has("pos_y"):
		global_position = Vector2(float(data["pos_x"]), float(data["pos_y"]))
	var dead_s: bool = bool(data.get("is_dead", false))
	if dead_s:
		_on_died(true)
		corpse_looted = bool(data.get("corpse_looted", false))
		visible = not corpse_looted
		if interact_area and interact_area.get_child_count() > 0:
			var ic_dead := interact_area.get_child(0) as CollisionShape2D
			if ic_dead:
				ic_dead.set_deferred("disabled", corpse_looted)
	else:
		is_dead = false
		corpse_looted = false
		is_hostile = false
		_hostile_timer = 0.0
		_flee_timer = 0.0
		is_stunned_flag = false
		remove_from_group("enemies")
		visible = true
		if interact_area and interact_area.get_child_count() > 0:
			var ic_alive := interact_area.get_child(0) as CollisionShape2D
			if ic_alive:
				ic_alive.set_deferred("disabled", false)
		if hurtbox and hurtbox.get_child_count() > 0:
			var hcol := hurtbox.get_child(0) as CollisionShape2D
			if hcol:
				hcol.set_deferred("disabled", false)
		if sprite:
			sprite.rotation_degrees = 0.0
			sprite.modulate = tint_color
		if stun_comp:
			stun_comp.clear_stun()
		if health_comp:
			health_comp.stop_bleeding()
			if data.has("hp"):
				health_comp.current_health = clampf(float(data["hp"]), 1.0, health_comp.max_health)
