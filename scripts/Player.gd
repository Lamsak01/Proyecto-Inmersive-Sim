extends CharacterBody2D

@export var dialogue_manager: Node
@export var hint_label: Label
@export var speed := 120.0
@export var weight: float = 50.0

@onready var interact_area: Area2D = $InteractArea
@onready var anim: AnimatedSprite2D = $Animations

# Components
@onready var health_comp: HealthComponent = $HealthComponent
@onready var stun_comp: StunComponent = $StunComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var combat_ctrl: PlayerCombatController = get_node_or_null("PlayerCombatController")
@onready var move_ctrl: PlayerMovementController = get_node_or_null("PlayerMovementController")

const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

var last_dir := "down"
var equipped_weapon: WeaponData
var inventory: SimpleInventory = null
var survival_comp: SurvivalComponent = null

var sword_weapon: WeaponData = load("res://resources/weapons/Sword.tres")
var hammer_weapon: WeaponData = load("res://resources/weapons/Hammer.tres")
var axe_weapon: WeaponData = null
var pickaxe_weapon: WeaponData = null
var bow_weapon: WeaponData = null
var sickle_weapon: WeaponData = null
var watering_can_weapon: WeaponData = null
var fishing_rod_weapon: WeaponData = null

const MAX_WATER_CHARGES: int = 6
var watering_can_charges: int = 6

# Status variables for controllers
var is_weak: bool = false
var is_stunned_flag: bool = false

func _load_tool_tex(res_path: String) -> Texture2D:
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

func _setup_tools() -> void:
	# Limpiar el ícono gigante del Martillo por nuestro sprite 16x16 limpio
	var clean_ham_tex := _load_tool_tex("res://assests/items/tools/hammer_clean.png")
	if clean_ham_tex and hammer_weapon:
		hammer_weapon.icon = clean_ham_tex
	if hammer_weapon and hammer_weapon.damage_data:
		hammer_weapon.damage_data.mining_efficiency = 0.35
	if sword_weapon and sword_weapon.damage_data:
		sword_weapon.damage_data.logging_efficiency = 0.35

	# [3] Hacha de Leñador (Alta eficiencia en Tala = 1.8x)
	axe_weapon = WeaponData.new()
	axe_weapon.name = "Axe"
	axe_weapon.icon = _load_tool_tex("res://assests/items/tools/axe_tool.png")
	var axe_dmg := DamageData.new()
	axe_dmg.amount = 10.0
	axe_dmg.type = CombatConstants.DamageType.CUT
	axe_dmg.bleed_buildup = 25.0
	axe_dmg.logging_efficiency = 1.8
	axe_dmg.mining_efficiency = 0.1
	axe_weapon.damage_data = axe_dmg

	# [4] Pico de Minero (Alta eficiencia en Minería = 1.8x)
	pickaxe_weapon = WeaponData.new()
	pickaxe_weapon.name = "Pickaxe"
	pickaxe_weapon.icon = _load_tool_tex("res://assests/items/tools/pickaxe_tool.png")
	var pick_dmg := DamageData.new()
	pick_dmg.amount = 10.0
	pick_dmg.type = CombatConstants.DamageType.BLUNT
	pick_dmg.stun_buildup = 20.0
	pick_dmg.mining_efficiency = 1.8
	pick_dmg.logging_efficiency = 0.1
	pickaxe_weapon.damage_data = pick_dmg

	# [5] Arco de Caza (Ataque a distancia silencioso para cacería)
	bow_weapon = WeaponData.new()
	bow_weapon.name = "Bow"
	bow_weapon.is_ranged = true
	bow_weapon.icon = _load_tool_tex("res://assests/items/tools/bow_weapon.png")
	var bow_dmg := DamageData.new()
	bow_dmg.amount = 14.0
	bow_dmg.type = CombatConstants.DamageType.CUT
	bow_dmg.bleed_buildup = 35.0
	bow_dmg.logging_efficiency = 0.0
	bow_dmg.mining_efficiency = 0.0
	bow_weapon.damage_data = bow_dmg

	# [6] Hoz de Cosecha (+1 Cultivo extra al cosechar plantas maduras)
	sickle_weapon = WeaponData.new()
	sickle_weapon.name = "Sickle"
	sickle_weapon.icon = _load_tool_tex("res://assests/items/tools/sickle_tool.png")
	var sickle_dmg := DamageData.new()
	sickle_dmg.amount = 7.0
	sickle_dmg.type = CombatConstants.DamageType.CUT
	sickle_dmg.bleed_buildup = 15.0
	sickle_dmg.logging_efficiency = 0.25
	sickle_dmg.mining_efficiency = 0.0
	sickle_weapon.damage_data = sickle_dmg

	# [7] Regadera Agrícola (Riego del huerto con cargas de agua recargables en Pozo o Lago)
	watering_can_weapon = WeaponData.new()
	watering_can_weapon.name = "WateringCan"
	watering_can_weapon.icon = _load_tool_tex("res://assests/items/tools/watering_can.png")
	var can_dmg := DamageData.new()
	can_dmg.amount = 2.0
	can_dmg.type = CombatConstants.DamageType.BLUNT
	can_dmg.logging_efficiency = 0.0
	can_dmg.mining_efficiency = 0.0
	watering_can_weapon.damage_data = can_dmg

	# [8] Caña de Pescar (Pesca en el Lago del Oeste)
	fishing_rod_weapon = WeaponData.new()
	fishing_rod_weapon.name = "FishingRod"
	fishing_rod_weapon.icon = _load_tool_tex("res://assests/items/tools/fishing_rod.png")
	var rod_dmg := DamageData.new()
	rod_dmg.amount = 2.0
	rod_dmg.type = CombatConstants.DamageType.BLUNT
	rod_dmg.logging_efficiency = 0.0
	rod_dmg.mining_efficiency = 0.0
	fishing_rod_weapon.damage_data = rod_dmg

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	_setup_tools()
	
	inventory = get_node_or_null("SimpleInventory")
	if not inventory:
		inventory = SimpleInventory.new()
		inventory.name = "SimpleInventory"
		add_child(inventory)

	survival_comp = get_node_or_null("SurvivalComponent")
	if not survival_comp:
		survival_comp = SurvivalComponent.new()
		survival_comp.name = "SurvivalComponent"
		add_child(survival_comp)
	
	if hint_label:
		hint_label.text = ""
	
	if health_comp:
		health_comp.died.connect(_on_died)
		health_comp.weakness_changed.connect(_on_weakness_changed)
		health_comp.bleed_triggered.connect(_on_bleed_triggered)
	if stun_comp:
		stun_comp.stunned.connect(_on_stunned)
	
	if hurtbox:
		hurtbox.hit_received.connect(take_damage)
	
	# Equip default weapon so combat works out of the box (1 = Sword, 2 = Hammer)
	call_deferred("equip_weapon", sword_weapon)

func equip_weapon(weapon_data: WeaponData) -> void:
	if not weapon_data:
		return
	equipped_weapon = weapon_data
	if not combat_ctrl:
		combat_ctrl = get_node_or_null("PlayerCombatController")
	if combat_ctrl and combat_ctrl.has_method("equip_weapon"):
		combat_ctrl.equip_weapon(weapon_data)

func equip_tool_by_index(idx: int) -> void:
	match idx:
		0:
			equip_weapon(sword_weapon)
			show_hint("[1] Espada (Combate: Corte/Sangrado | Tala lenta 35%)")
		1:
			equip_weapon(hammer_weapon)
			show_hint("[2] Martillo (Combate: Stun | Minería lenta 35%)")
		2:
			equip_weapon(axe_weapon)
			show_hint("[3] Hacha de Leñador (Especialista en Tala 180%)")
		3:
			equip_weapon(pickaxe_weapon)
			show_hint("[4] Pico de Minero (Especialista en Minería 180%)")
		4:
			equip_weapon(bow_weapon)
			show_hint("[5] Arco de Caza (Disparo a distancia con Clic Izquierdo)")
		5:
			equip_weapon(sickle_weapon)
			show_hint("[6] Hoz de Cosecha (+1 Cultivo extra al cosechar plantas maduras)")
		6:
			equip_weapon(watering_can_weapon)
			show_hint("[7] Regadera Agrícola (Agua: %d/%d — Recárgala en el Pozo o Lago)" % [watering_can_charges, MAX_WATER_CHARGES])
		7:
			equip_weapon(fishing_rod_weapon)
			show_hint("[8] Caña de Pescar (Pesca en el Lago del Oeste con [E])")

func refill_watering_can() -> void:
	watering_can_charges = MAX_WATER_CHARGES
	_spawn_floating_text("💧 Regadera llena (%d/%d)" % [watering_can_charges, MAX_WATER_CHARGES], Color.AQUA, -40.0)
	show_hint("💧 Regadera recargada al 100%% (%d/%d usos de riego)." % [watering_can_charges, MAX_WATER_CHARGES])

func consume_water_charge() -> bool:
	if watering_can_charges <= 0:
		show_hint("⚠️ Tu Regadera está vacía (0/%d). Llénala en el Pozo junto al huerto o en el Lago del Oeste." % MAX_WATER_CHARGES)
		return false
	watering_can_charges -= 1
	return true

func _handle_interactions() -> void:
	if dialogue_manager and dialogue_manager.call("is_active"):
		return

	var overlaps := interact_area.get_overlapping_areas()
	var best_area: Area2D = null
	var best_dist_sq: float = INF
	var mouse_pos := get_global_mouse_position()
	var use_mouse_bias := global_position.distance_squared_to(mouse_pos) <= 55.0 * 55.0
	var ref_pos := mouse_pos if use_mouse_bias else global_position

	for a in overlaps:
		if a.is_in_group("interactable"):
			var d_sq := ref_pos.distance_squared_to(a.global_position)
			if d_sq < best_dist_sq:
				best_dist_sq = d_sq
				best_area = a

	if best_area:
		if best_area.has_method("interact"):
			best_area.interact(self)
			get_viewport().set_input_as_handled()
		elif best_area.get_parent().has_method("interact"):
			best_area.get_parent().interact(self)
			get_viewport().set_input_as_handled()

func show_hint(text: String) -> void:
	if hint_label:
		hint_label.text = text
		get_tree().create_timer(3.0).timeout.connect(func(): 
			if hint_label and hint_label.text == text:
				hint_label.text = "")

func _unhandled_input(event: InputEvent) -> void:
	if dialogue_manager and dialogue_manager.has_method("is_active") and dialogue_manager.call("is_active"):
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			equip_tool_by_index(0)
		elif event.keycode == KEY_2:
			equip_tool_by_index(1)
		elif event.keycode == KEY_3:
			equip_tool_by_index(2)
		elif event.keycode == KEY_4:
			equip_tool_by_index(3)
		elif event.keycode == KEY_5:
			equip_tool_by_index(4)
		elif event.keycode == KEY_6:
			equip_tool_by_index(5)
		elif event.keycode == KEY_7:
			equip_tool_by_index(6)
		elif event.keycode == KEY_8:
			equip_tool_by_index(7)
		elif event.keycode == KEY_R and inventory:
			var next_seed := inventory.cycle_selected_seed()
			var s_name := inventory.get_item_name(next_seed)
			var s_count := inventory.get_count(next_seed)
			_spawn_floating_text("🌱 %s (%d)" % [s_name, s_count], Color.SPRING_GREEN, -40.0)
			show_hint("[R] Semilla activa para sembrar: %s (Tienes %d)" % [s_name, s_count])
			
	if event.is_action_pressed("Interact"):
		_handle_interactions()

func _on_died() -> void:
	set_physics_process(false)
	if move_ctrl: move_ctrl.set_physics_process(false)
	if combat_ctrl: combat_ctrl.set_process(false)
	anim.stop()

func _on_weakness_changed(weak: bool) -> void:
	is_weak = weak

func _on_bleed_triggered(_dps: float) -> void:
	_spawn_floating_text("BLEEDING!", Color.CRIMSON, -34.0)

func _on_stunned(stunned: bool) -> void:
	is_stunned_flag = stunned
	if stunned:
		anim.stop()
		_spawn_floating_text("STUNNED!", Color.AQUA, -44.0)

func apply_push(force: Vector2) -> void:
	if not move_ctrl:
		move_ctrl = get_node_or_null("PlayerMovementController")
	if move_ctrl and move_ctrl.has_method("apply_impulse"):
		move_ctrl.apply_impulse(force)

func _spawn_floating_text(text: String, color: Color, offset_y: float = -36.0) -> void:
	if FloatingTextScene:
		var ft = FloatingTextScene.instantiate()
		ft.start_text = text
		ft.text_color = color
		ft.global_position = global_position + Vector2(0, offset_y)
		get_tree().current_scene.add_child(ft)

func is_stunned() -> bool:
	return is_stunned_flag

func is_stealthing() -> bool:
	if not move_ctrl:
		move_ctrl = get_node_or_null("PlayerMovementController")
	if move_ctrl:
		return move_ctrl.is_stealthing
	return false

func get_noise_multiplier() -> float:
	"""Devuelve el multiplicador de ruido actual según el movimiento (0 = silencio, 1 = caminar, 1.8 = correr)."""
	if velocity.length_squared() < 4.0:
		return 0.0
	if not move_ctrl:
		move_ctrl = get_node_or_null("PlayerMovementController")
	if move_ctrl:
		if move_ctrl.is_stealthing:
			return 0.0
		if move_ctrl.is_sprinting:
			return 1.8
	return 1.0

func take_damage(data: DamageData) -> void:
	if health_comp:
		health_comp.take_damage(data)
	if stun_comp:
		stun_comp.take_damage(data)

func to_save_dict() -> Dictionary:
	var stam_comp: StaminaComponent = get_node_or_null("StaminaComponent")
	var weapon_id := "sword"
	if equipped_weapon == hammer_weapon:
		weapon_id = "hammer"
	elif equipped_weapon == axe_weapon:
		weapon_id = "axe"
	elif equipped_weapon == pickaxe_weapon:
		weapon_id = "pickaxe"
	elif equipped_weapon == bow_weapon:
		weapon_id = "bow"
	elif equipped_weapon == sickle_weapon:
		weapon_id = "sickle"
	elif equipped_weapon == watering_can_weapon:
		weapon_id = "watering_can"
	elif equipped_weapon == fishing_rod_weapon:
		weapon_id = "fishing_rod"
	return {
		"pos_x": global_position.x,
		"pos_y": global_position.y,
		"hp": health_comp.current_health if health_comp else 100.0,
		"blood": health_comp.current_blood if health_comp else 0.0,
		"is_bleeding": health_comp.is_bleeding if health_comp else false,
		"stamina": stam_comp.current_stamina if stam_comp else 100.0,
		"hunger": survival_comp.current_hunger if survival_comp else 100.0,
		"sleep": survival_comp.current_sleep if survival_comp else 100.0,
		"watering_can_charges": watering_can_charges,
		"weapon": weapon_id,
		"inventory": inventory.to_dict() if inventory else {}
	}

func from_save_dict(data: Dictionary) -> void:
	if data.has("pos_x") and data.has("pos_y"):
		global_position = Vector2(float(data["pos_x"]), float(data["pos_y"]))
	if health_comp:
		health_comp.current_health = clamp(float(data.get("hp", health_comp.max_health)), 1.0, health_comp.max_health)
		health_comp.current_blood = clamp(float(data.get("blood", 0.0)), 0.0, health_comp.max_blood)
		health_comp.is_bleeding = bool(data.get("is_bleeding", false))
		health_comp.health_changed.emit(health_comp.current_health, health_comp.max_health)
		health_comp.blood_changed.emit(health_comp.current_blood, health_comp.max_blood)
	var stam_comp: StaminaComponent = get_node_or_null("StaminaComponent")
	if stam_comp and data.has("stamina"):
		stam_comp.current_stamina = clamp(float(data["stamina"]), 0.0, stam_comp.max_stamina)
		stam_comp.stamina_changed.emit(stam_comp.current_stamina, stam_comp.max_stamina)
	if survival_comp:
		if data.has("hunger"):
			survival_comp.current_hunger = clampf(float(data["hunger"]), 0.0, survival_comp.max_hunger)
		if data.has("sleep"):
			survival_comp.current_sleep = clampf(float(data["sleep"]), 0.0, survival_comp.max_sleep)
		survival_comp._emit_all()
	if data.has("watering_can_charges"):
		watering_can_charges = clampi(int(data["watering_can_charges"]), 0, MAX_WATER_CHARGES)
	var weapon_id: String = str(data.get("weapon", "sword"))
	match weapon_id:
		"hammer": equip_weapon(hammer_weapon)
		"axe": equip_weapon(axe_weapon)
		"pickaxe": equip_weapon(pickaxe_weapon)
		"bow": equip_weapon(bow_weapon)
		"sickle": equip_weapon(sickle_weapon)
		"watering_can": equip_weapon(watering_can_weapon)
		"fishing_rod": equip_weapon(fishing_rod_weapon)
		_: equip_weapon(sword_weapon)
	if inventory and data.has("inventory"):
		inventory.from_dict(data["inventory"])
