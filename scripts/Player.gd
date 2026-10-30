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

## Niveles de Mejora de Herramientas y Armas estilo Stardew Valley (1 = Básico, 2 = Hierro Forjado, 3 = Acero Maestro)
var tool_tiers: Dictionary = {
	"sword": 1,
	"hammer": 1,
	"axe": 1,
	"pickaxe": 1,
	"bow": 1,
	"sickle": 1,
	"watering_can": 1,
	"fishing_rod": 1
}

const TIER_NAMES: Dictionary = {
	1: "Básico",
	2: "Hierro",
	3: "Acero Maestro"
}

const TOOL_UPGRADE_CATALOG: Dictionary = {
	"sword": {
		"title": "Espada",
		"tiers": {
			2: {"gold": 25, "mats": {"iron_ore": 2, "wood": 1}},
			3: {"gold": 55, "mats": {"steel_ingot": 2, "wood": 2}}
		}
	},
	"hammer": {
		"title": "Martillo",
		"tiers": {
			2: {"gold": 25, "mats": {"iron_ore": 2, "wood": 1}},
			3: {"gold": 55, "mats": {"steel_ingot": 2, "wood": 2}}
		}
	},
	"axe": {
		"title": "Hacha",
		"tiers": {
			2: {"gold": 22, "mats": {"iron_ore": 2, "wood": 2}},
			3: {"gold": 48, "mats": {"steel_ingot": 2, "wood": 2}}
		}
	},
	"pickaxe": {
		"title": "Pico",
		"tiers": {
			2: {"gold": 22, "mats": {"iron_ore": 2, "wood": 2}},
			3: {"gold": 48, "mats": {"steel_ingot": 2, "wood": 2}}
		}
	},
	"bow": {
		"title": "Arco de Caza",
		"tiers": {
			2: {"gold": 26, "mats": {"wood": 3, "leather": 2}},
			3: {"gold": 56, "mats": {"steel_ingot": 1, "wood": 3, "fox_pelt": 1}}
		}
	},
	"sickle": {
		"title": "Hoz Agrícola",
		"tiers": {
			2: {"gold": 18, "mats": {"iron_ore": 1, "wood": 1}},
			3: {"gold": 40, "mats": {"steel_ingot": 1, "wood": 2}}
		}
	},
	"watering_can": {
		"title": "Regadera",
		"tiers": {
			2: {"gold": 18, "mats": {"iron_ore": 2}},
			3: {"gold": 40, "mats": {"steel_ingot": 2}}
		}
	},
	"fishing_rod": {
		"title": "Caña de Pescar",
		"tiers": {
			2: {"gold": 20, "mats": {"wood": 3, "iron_ore": 1}},
			3: {"gold": 45, "mats": {"steel_ingot": 1, "wood": 3, "feather": 2}}
		}
	}
}

var max_water_charges: int = 6
var watering_can_charges: int = 6
var armor_speed_multiplier: float = 1.0
var speed_tonic_timer: float = 0.0
var paralytic_venom_timer: float = 0.0
var _armor_visual_overlay: Node2D = null

# Status variables for controllers
var is_weak: bool = false
var is_stunned_flag: bool = false
var last_damage_source: Node = null
var _hit_flash_timer: float = 0.0

func _get(property: StringName) -> Variant:
	if property == &"MAX_WATER_CHARGES":
		return max_water_charges
	return null

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
	var clean_ham_tex := _load_tool_tex("res://assests/items/tools/hammer_clean.png")
	if clean_ham_tex and hammer_weapon:
		hammer_weapon.icon = clean_ham_tex

	# [3] Hacha de Leñador
	axe_weapon = WeaponData.new()
	axe_weapon.name = "Axe"
	axe_weapon.icon = _load_tool_tex("res://assests/items/tools/axe_tool.png")
	var axe_dmg := DamageData.new()
	axe_dmg.type = CombatConstants.DamageType.CUT
	axe_weapon.damage_data = axe_dmg

	# [4] Pico de Minero
	pickaxe_weapon = WeaponData.new()
	pickaxe_weapon.name = "Pickaxe"
	pickaxe_weapon.icon = _load_tool_tex("res://assests/items/tools/pickaxe_tool.png")
	var pick_dmg := DamageData.new()
	pick_dmg.type = CombatConstants.DamageType.BLUNT
	pickaxe_weapon.damage_data = pick_dmg

	# [5] Arco de Caza
	bow_weapon = WeaponData.new()
	bow_weapon.name = "Bow"
	bow_weapon.is_ranged = true
	bow_weapon.icon = _load_tool_tex("res://assests/items/tools/bow_weapon.png")
	var bow_dmg := DamageData.new()
	bow_dmg.type = CombatConstants.DamageType.CUT
	bow_weapon.damage_data = bow_dmg

	# [6] Hoz de Cosecha
	sickle_weapon = WeaponData.new()
	sickle_weapon.name = "Sickle"
	sickle_weapon.icon = _load_tool_tex("res://assests/items/tools/sickle_tool.png")
	var sickle_dmg := DamageData.new()
	sickle_dmg.type = CombatConstants.DamageType.CUT
	sickle_weapon.damage_data = sickle_dmg

	# [7] Regadera Agrícola
	watering_can_weapon = WeaponData.new()
	watering_can_weapon.name = "WateringCan"
	watering_can_weapon.icon = _load_tool_tex("res://assests/items/tools/watering_can.png")
	var can_dmg := DamageData.new()
	can_dmg.type = CombatConstants.DamageType.BLUNT
	watering_can_weapon.damage_data = can_dmg

	# [8] Caña de Pescar
	fishing_rod_weapon = WeaponData.new()
	fishing_rod_weapon.name = "FishingRod"
	fishing_rod_weapon.icon = _load_tool_tex("res://assests/items/tools/fishing_rod.png")
	var rod_dmg := DamageData.new()
	rod_dmg.type = CombatConstants.DamageType.BLUNT
	fishing_rod_weapon.damage_data = rod_dmg

	_apply_tool_tiers()

func _normalize_tool_key(tool_key: String) -> String:
	var k := tool_key.to_lower()
	if k == "wateringcan":
		return "watering_can"
	if k == "fishingrod":
		return "fishing_rod"
	return k

func get_tool_tier(tool_key: String) -> int:
	var nk := _normalize_tool_key(tool_key)
	return clampi(int(tool_tiers.get(nk, 1)), 1, 3)

func get_tool_tier_label(tool_key: String) -> String:
	var t := get_tool_tier(tool_key)
	return str(TIER_NAMES.get(t, "Básico"))

func get_sickle_bonus() -> int:
	return get_tool_tier("sickle") # +1 en Tier 1, +2 en Tier 2, +3 en Tier 3

func get_fishing_bar_multiplier() -> float:
	var t := get_tool_tier("fishing_rod")
	if t == 2:
		return 1.28
	elif t >= 3:
		return 1.55
	return 1.0

func upgrade_tool(tool_key: String, consume_resources: bool = true) -> bool:
	var nk := _normalize_tool_key(tool_key)
	var cur := get_tool_tier(nk)
	if cur >= 3:
		_spawn_floating_text("¡Esta herramienta ya está al Nivel Máximo!", Color.GOLD, -42.0)
		return false

	var next_tier: int = cur + 1
	var meta: Dictionary = TOOL_UPGRADE_CATALOG.get(nk, {})
	var t_title: String = str(meta.get("title", nk))
	var tier_cost: Dictionary = meta.get("tiers", {}).get(next_tier, {})

	if consume_resources and inventory and not tier_cost.is_empty():
		var req_gold: int = int(tier_cost.get("gold", 20))
		var req_mats: Dictionary = tier_cost.get("mats", {})
		if inventory.gold < req_gold:
			_spawn_floating_text("Necesitas %d Oro para mejorar %s" % [req_gold, t_title], Color.ORANGE_RED, -42.0)
			return false
		for m_id in req_mats.keys():
			var req_cnt: int = int(req_mats[m_id])
			if not inventory.has_item(str(m_id), req_cnt):
				_spawn_floating_text("Falta %d %s" % [req_cnt, inventory.get_item_name(str(m_id))], Color.ORANGE_RED, -42.0)
				return false
		inventory.add_gold(-req_gold)
		for m_id in req_mats.keys():
			inventory.remove_item(str(m_id), int(req_mats[m_id]))

	tool_tiers[nk] = next_tier
	_apply_tool_tiers()
	if nk == "watering_can":
		watering_can_charges = max_water_charges
	_spawn_floating_text("⚒️ ¡%s mejorada a Nivel %d (%s)!" % [t_title, next_tier, get_tool_tier_label(nk)], Color.CYAN, -44.0)
	return true

func _apply_tool_tiers() -> void:
	# 1. Espada
	var t_sword := get_tool_tier("sword")
	if sword_weapon and sword_weapon.damage_data:
		sword_weapon.damage_data.amount = 12.0 if t_sword == 1 else (19.0 if t_sword == 2 else 28.0)
		sword_weapon.damage_data.bleed_buildup = 35.0 if t_sword == 1 else (52.0 if t_sword == 2 else 75.0)
		sword_weapon.damage_data.logging_efficiency = 0.35 if t_sword == 1 else (0.50 if t_sword == 2 else 0.70)

	# 2. Martillo
	var t_ham := get_tool_tier("hammer")
	if hammer_weapon and hammer_weapon.damage_data:
		hammer_weapon.damage_data.amount = 15.0 if t_ham == 1 else (23.0 if t_ham == 2 else 34.0)
		hammer_weapon.damage_data.stun_buildup = 42.0 if t_ham == 1 else (62.0 if t_ham == 2 else 85.0)
		hammer_weapon.damage_data.mining_efficiency = 0.35 if t_ham == 1 else (0.50 if t_ham == 2 else 0.70)

	# 3. Hacha
	var t_axe := get_tool_tier("axe")
	if axe_weapon and axe_weapon.damage_data:
		axe_weapon.damage_data.amount = 10.0 if t_axe == 1 else (15.0 if t_axe == 2 else 22.0)
		axe_weapon.damage_data.bleed_buildup = 25.0 if t_axe == 1 else (38.0 if t_axe == 2 else 55.0)
		axe_weapon.damage_data.logging_efficiency = 1.80 if t_axe == 1 else (2.70 if t_axe == 2 else 3.80)
		axe_weapon.damage_data.mining_efficiency = 0.10

	# 4. Pico
	var t_pick := get_tool_tier("pickaxe")
	if pickaxe_weapon and pickaxe_weapon.damage_data:
		pickaxe_weapon.damage_data.amount = 10.0 if t_pick == 1 else (15.0 if t_pick == 2 else 22.0)
		pickaxe_weapon.damage_data.stun_buildup = 22.0 if t_pick == 1 else (35.0 if t_pick == 2 else 50.0)
		pickaxe_weapon.damage_data.mining_efficiency = 1.80 if t_pick == 1 else (2.70 if t_pick == 2 else 3.80)
		pickaxe_weapon.damage_data.logging_efficiency = 0.10

	# 5. Arco
	var t_bow := get_tool_tier("bow")
	if bow_weapon and bow_weapon.damage_data:
		bow_weapon.damage_data.amount = 14.0 if t_bow == 1 else (22.0 if t_bow == 2 else 32.0)
		bow_weapon.damage_data.bleed_buildup = 35.0 if t_bow == 1 else (55.0 if t_bow == 2 else 80.0)

	# 6. Hoz
	var t_sickle := get_tool_tier("sickle")
	if sickle_weapon and sickle_weapon.damage_data:
		sickle_weapon.damage_data.amount = 7.0 if t_sickle == 1 else (11.0 if t_sickle == 2 else 16.0)
		sickle_weapon.damage_data.bleed_buildup = 15.0 if t_sickle == 1 else (25.0 if t_sickle == 2 else 40.0)
		sickle_weapon.damage_data.logging_efficiency = 0.25

	# 7. Regadera
	var t_can := get_tool_tier("watering_can")
	max_water_charges = 6 if t_can == 1 else (12 if t_can == 2 else 20)
	watering_can_charges = mini(watering_can_charges, max_water_charges)

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	_setup_tools()
	
	inventory = get_node_or_null("SimpleInventory")
	if not inventory:
		inventory = SimpleInventory.new()
		inventory.name = "SimpleInventory"
		add_child(inventory)
	if not inventory.armor_changed.is_connected(apply_armor_stats):
		inventory.armor_changed.connect(apply_armor_stats)

	survival_comp = get_node_or_null("SurvivalComponent")
	if not survival_comp:
		survival_comp = SurvivalComponent.new()
		survival_comp.name = "SurvivalComponent"
		add_child(survival_comp)

	_setup_armor_visual_placeholder()
	apply_armor_stats()
	
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
	
	call_deferred("equip_weapon", sword_weapon)

func _setup_armor_visual_placeholder() -> void:
	_armor_visual_overlay = Node2D.new()
	_armor_visual_overlay.name = "ArmorPlaceholderOverlay"
	_armor_visual_overlay.z_index = 2
	add_child(_armor_visual_overlay)

	# Placeholder visual modular para Casco, Pecho, Piernas y Botas sobre el sprite del jugador
	var helm_poly := Polygon2D.new()
	helm_poly.name = "HelmVis"
	helm_poly.polygon = PackedVector2Array([Vector2(-4, -24), Vector2(4, -24), Vector2(5, -20), Vector2(-5, -20)])
	helm_poly.visible = false
	_armor_visual_overlay.add_child(helm_poly)

	var chest_poly := Polygon2D.new()
	chest_poly.name = "ChestVis"
	chest_poly.polygon = PackedVector2Array([Vector2(-5, -15), Vector2(5, -15), Vector2(4, -9), Vector2(-4, -9)])
	chest_poly.visible = false
	_armor_visual_overlay.add_child(chest_poly)

	var legs_poly := Polygon2D.new()
	legs_poly.name = "LegsVis"
	legs_poly.polygon = PackedVector2Array([Vector2(-4, -9), Vector2(4, -9), Vector2(4, -5), Vector2(-4, -5)])
	legs_poly.visible = false
	_armor_visual_overlay.add_child(legs_poly)

	var boots_poly := Polygon2D.new()
	boots_poly.name = "BootsVis"
	boots_poly.polygon = PackedVector2Array([Vector2(-4, -4), Vector2(4, -4), Vector2(4, -1), Vector2(-4, -1)])
	boots_poly.visible = false
	_armor_visual_overlay.add_child(boots_poly)

func _tier_to_armor_color(tier: int) -> Color:
	match tier:
		1: return Color(0.68, 0.44, 0.24, 0.82) # Cuero Curtido
		2: return Color(0.75, 0.80, 0.88, 0.86) # Hierro Forjado
		3: return Color(0.45, 0.82, 1.00, 0.90) # Acero Templado
	return Color.TRANSPARENT

func apply_speed_tonic(duration: float = 35.0) -> void:
	speed_tonic_timer = maxf(speed_tonic_timer, duration)
	apply_armor_stats()
	_spawn_floating_text("⚡ Tónico de Velocidad (+25% Vel por %ds)" % int(duration), Color.AQUA, -44.0)

func apply_paralytic_venom(duration: float = 60.0) -> void:
	paralytic_venom_timer = maxf(paralytic_venom_timer, duration)
	_spawn_floating_text("🧪🐍 Veneno Paralizante (+50 Stun en impactos por %ds)" % int(duration), Color(0.55, 1.0, 0.35), -44.0)

func get_stealth_detection_multiplier() -> float:
	if inventory and inventory.has_item("ranger_camo_cloak", 1):
		return 0.60
	return 1.0

func has_master_lockpick() -> bool:
	return inventory != null and inventory.has_item("master_lockpick", 1)

func _process(delta: float) -> void:
	if speed_tonic_timer > 0.0:
		speed_tonic_timer -= delta
		if speed_tonic_timer <= 0.0:
			speed_tonic_timer = 0.0
			apply_armor_stats()
	if paralytic_venom_timer > 0.0:
		paralytic_venom_timer = maxf(0.0, paralytic_venom_timer - delta)
	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
		if _hit_flash_timer <= 0.0 and anim:
			anim.modulate = Color.WHITE

func apply_armor_stats() -> void:
	if not inventory:
		return
	var stats: Dictionary = inventory.get_total_armor_stats()
	if health_comp:
		health_comp.armor_defense = float(stats.get("defense", 0.0))
		health_comp.armor_bleed_resistance = float(stats.get("bleed_res", 0.0))
	if stun_comp:
		stun_comp.armor_stun_resistance = float(stats.get("stun_res", 0.0))
	var tonic_bonus: float = 0.25 if speed_tonic_timer > 0.0 else 0.0
	armor_speed_multiplier = 1.0 + float(stats.get("speed_bonus", 0.0)) + tonic_bonus

	if _armor_visual_overlay:
		var slot_map := {
			"HEAD": "HelmVis",
			"CHEST": "ChestVis",
			"LEGS": "LegsVis",
			"BOOTS": "BootsVis"
		}
		for slot_key in slot_map.keys():
			var node_name: String = slot_map[slot_key]
			var poly := _armor_visual_overlay.get_node_or_null(node_name) as Polygon2D
			if not poly:
				continue
			var item_id: String = str(inventory.equipped_armor.get(slot_key, ""))
			if item_id == "":
				poly.visible = false
			else:
				var info: Dictionary = inventory.get_item_info(item_id)
				var t: int = int(info.get("armor_tier", 1))
				poly.color = _tier_to_armor_color(t)
				poly.visible = true

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
			show_hint("[1] Espada (%s) — Daño: %d | Sangrado: %d" % [get_tool_tier_label("sword"), int(sword_weapon.damage_data.amount), int(sword_weapon.damage_data.bleed_buildup)])
		1:
			equip_weapon(hammer_weapon)
			show_hint("[2] Martillo (%s) — Daño: %d | Stun: %d" % [get_tool_tier_label("hammer"), int(hammer_weapon.damage_data.amount), int(hammer_weapon.damage_data.stun_buildup)])
		2:
			equip_weapon(axe_weapon)
			show_hint("[3] Hacha (%s) — Eficiencia Tala: %d%%" % [get_tool_tier_label("axe"), int(round(axe_weapon.damage_data.logging_efficiency * 100.0))])
		3:
			equip_weapon(pickaxe_weapon)
			show_hint("[4] Pico (%s) — Eficiencia Minería: %d%%" % [get_tool_tier_label("pickaxe"), int(round(pickaxe_weapon.damage_data.mining_efficiency * 100.0))])
		4:
			equip_weapon(bow_weapon)
			show_hint("[5] Arco (%s) — Daño a distancia: %d (Mantén Clic Izq.)" % [get_tool_tier_label("bow"), int(bow_weapon.damage_data.amount)])
		5:
			equip_weapon(sickle_weapon)
			show_hint("[6] Hoz (%s) — Bono Cosecha: +%d cultivos extra" % [get_tool_tier_label("sickle"), get_sickle_bonus()])
		6:
			equip_weapon(watering_can_weapon)
			show_hint("[7] Regadera (%s) — Agua: %d/%d (Recarga en Pozo o Lago)" % [get_tool_tier_label("watering_can"), watering_can_charges, max_water_charges])
		7:
			equip_weapon(fishing_rod_weapon)
			show_hint("[8] Caña de Pescar (%s) — Barra de Pesca: %d%%" % [get_tool_tier_label("fishing_rod"), int(round(get_fishing_bar_multiplier() * 100.0))])

func refill_watering_can() -> void:
	watering_can_charges = max_water_charges
	_spawn_floating_text("💧 Regadera llena (%d/%d)" % [watering_can_charges, max_water_charges], Color.AQUA, -40.0)
	show_hint("💧 Regadera recargada al 100%% (%d/%d usos de riego)." % [watering_can_charges, max_water_charges])

func consume_water_charge() -> bool:
	if watering_can_charges <= 0:
		show_hint("⚠️ Tu Regadera está vacía (0/%d). Llénala en el Pozo junto al huerto o en el Lago del Oeste." % max_water_charges)
		return false
	watering_can_charges -= 1
	return true

func _handle_interactions() -> void:
	if dialogue_manager and dialogue_manager.call("is_active"):
		return

	var vm = get_tree().get_first_node_in_group("village_manager")
	var mouse_pos := get_global_mouse_position()
	# Prioridad de salida/puerta cerrada (referencia Stardew Valley / Baldur's Gate 3):
	# Si el jugador está ante una puerta cerrada o apunta a una puerta, nunca queda atrapado aunque haya un NPC parado junto al marco.
	if vm and vm.has_method("try_priority_door_or_corpse_interaction"):
		if bool(vm.call("try_priority_door_or_corpse_interaction", self, mouse_pos)):
			get_viewport().set_input_as_handled()
			return

	var overlaps := interact_area.get_overlapping_areas()
	var best_area: Area2D = null
	var best_dist_sq: float = INF
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
		elif best_area.get_parent() and best_area.get_parent().has_method("interact"):
			best_area.get_parent().interact(self)
			get_viewport().set_input_as_handled()
		elif best_area.get_parent() and best_area.get_parent().get_parent() and best_area.get_parent().get_parent().has_method("interact"):
			best_area.get_parent().get_parent().interact(self)
			get_viewport().set_input_as_handled()

func is_any_ui_modal_open() -> bool:
	if dialogue_manager and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active")):
		return true
	if WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen():
		return true
	var ui_root = get_tree().current_scene.get_node_or_null("UI/UIRoot") if get_tree().current_scene else null
	if ui_root:
		var inv_p = ui_root.get("inv_panel")
		if inv_p is Control and inv_p.visible:
			return true
		var tw_p = ui_root.get("tool_wheel")
		if tw_p is Control and tw_p.visible:
			return true
		var tg_p = ui_root.get("tavern_games")
		if tg_p is Control and tg_p.visible:
			return true
		var vm_ui = ui_root.get("valley_map")
		if vm_ui and bool(vm_ui.get("is_full_map_open")):
			return true
	var vm = get_tree().get_first_node_in_group("village_manager")
	if vm:
		for p_name in ["business_panel", "morgue_panel", "jail_panel", "board_panel", "police_panel", "pantry_panel", "church_panel"]:
			var p_ctrl = vm.get(p_name)
			if p_ctrl is Control and p_ctrl.visible:
				return true
	var camp = get_tree().current_scene.find_child("PlayerCampSite", true, false) if get_tree().current_scene else null
	if camp:
		for c_panel in ["sleep_confirm_panel", "upgrade_panel", "chest_panel"]:
			var cp = camp.get(c_panel)
			if cp is Control and cp.visible:
				return true
	var coop = get_tree().get_first_node_in_group("chicken_coop")
	if coop:
		var coop_p = coop.get("chicken_action_panel")
		if coop_p is Control and coop_p.visible:
			return true
	return false

func is_fishing_or_sitting() -> bool:
	var camp = get_tree().current_scene.find_child("PlayerCampSite", true, false) if get_tree().current_scene else null
	if camp and bool(camp.get("is_player_sitting")):
		return true
	var lake = get_tree().current_scene.find_child("WestFishingLake", true, false) if get_tree().current_scene else null
	if lake and int(lake.get("state")) != 0:
		return true
	return false

func show_hint(text: String) -> void:
	if hint_label:
		hint_label.text = text
		get_tree().create_timer(3.0).timeout.connect(func(): 
			if hint_label and hint_label.text == text:
				hint_label.text = "")

func _unhandled_input(event: InputEvent) -> void:
	if is_stunned_flag or is_any_ui_modal_open():
		return
	var vm = get_tree().get_first_node_in_group("village_manager")
	if vm and (bool(vm.get("player_in_jail")) or bool(vm.get("player_being_escorted_to_jail"))):
		if event.is_action_pressed("Interact"):
			_handle_interactions()
		return
	var lake = get_tree().current_scene.find_child("WestFishingLake", true, false) if get_tree().current_scene else null
	if lake and int(lake.get("state")) == 3: # FishState.MINIGAME
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
	var vm = get_tree().get_first_node_in_group("village_manager")
	var knocked_by_police := false
	if is_instance_valid(last_damage_source) and (last_damage_source is VillageNPC):
		var v_src := last_damage_source as VillageNPC
		if v_src.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR]:
			knocked_by_police = true
	if vm and (int(vm.get("wanted_level")) > 0 or bool(vm.get("is_resisting_arrest")) or knocked_by_police):
		if health_comp:
			health_comp.stop_bleeding()
			health_comp.heal(health_comp.max_health * 0.50)
		if stun_comp and stun_comp.has_method("clear_stun"):
			stun_comp.clear_stun()
		is_stunned_flag = false
		if vm.has_method("capture_knocked_out_player_to_jail"):
			vm.call("capture_knocked_out_player_to_jail", self)
		return

	# Si cae abatido fuera de persecución policial, es trasladado de urgencia al Hospital del Dr. Valen
	if health_comp:
		health_comp.stop_bleeding()
		health_comp.heal(health_comp.max_health * 0.60)
	if stun_comp and stun_comp.has_method("clear_stun"):
		stun_comp.clear_stun()
	is_stunned_flag = false
	velocity = Vector2.ZERO
	global_position = Vector2(710, 132)
	_spawn_floating_text("🚑 ¡Rescatado de urgencia en el Hospital!", Color.SPRING_GREEN, -46.0)
	show_hint("🏥 Caíste inconsciente y el Dr. Valen te estabilizó en la Sala de Urgencias del Hospital.")

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
	if FloatingTextScene and is_inside_tree():
		var parent_scene: Node = get_tree().current_scene if get_tree().current_scene else get_parent()
		if parent_scene:
			var ft = FloatingTextScene.instantiate()
			ft.start_text = text
			ft.text_color = color
			ft.global_position = global_position + Vector2(0, offset_y)
			parent_scene.add_child(ft)

func is_stunned() -> bool:
	return is_stunned_flag

func is_stealthing() -> bool:
	if not move_ctrl:
		move_ctrl = get_node_or_null("PlayerMovementController")
	if move_ctrl:
		return move_ctrl.is_stealthing
	return false

func get_noise_multiplier() -> float:
	if velocity.length_squared() < 4.0:
		return 0.0
	var weather_mult: float = 1.0
	if WorldClock and WorldClock.has_method("get_noise_weather_multiplier"):
		weather_mult = float(WorldClock.call("get_noise_weather_multiplier"))
	if not move_ctrl:
		move_ctrl = get_node_or_null("PlayerMovementController")
	if move_ctrl:
		if move_ctrl.is_stealthing:
			return 0.0
		if move_ctrl.is_sprinting:
			return 1.8 * weather_mult
	return 1.0 * weather_mult

func take_damage(data: DamageData) -> void:
	var vm: Node = get_tree().get_first_node_in_group("village_manager")
	if vm and ((("player_being_escorted_to_jail" in vm) and vm.player_being_escorted_to_jail) or (("player_in_jail" in vm) and vm.player_in_jail)):
		return
	if data and is_instance_valid(data.source):
		last_damage_source = data.source
	var hp_before: float = health_comp.current_health if health_comp else 100.0
	if health_comp:
		health_comp.take_damage(data)
	if stun_comp and health_comp and health_comp.current_health > 0.0:
		stun_comp.take_damage(data)
	var hp_lost: float = maxf(0.0, hp_before - (health_comp.current_health if health_comp else hp_before))
	if hp_lost > 0.1:
		_spawn_floating_text("-%d HP" % maxi(1, int(round(hp_lost))), Color(1.0, 0.35, 0.35), -38.0)
		if anim:
			anim.modulate = Color(1.35, 0.45, 0.45)
			_hit_flash_timer = 0.18

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
		"speed_tonic_timer": speed_tonic_timer,
		"paralytic_venom_timer": paralytic_venom_timer,
		"tool_tiers": tool_tiers.duplicate(),
		"weapon": weapon_id,
		"inventory": inventory.to_dict() if inventory else {}
	}

func from_save_dict(data: Dictionary) -> void:
	if data.has("pos_x") and data.has("pos_y"):
		global_position = Vector2(float(data["pos_x"]), float(data["pos_y"]))
	speed_tonic_timer = float(data.get("speed_tonic_timer", 0.0))
	paralytic_venom_timer = float(data.get("paralytic_venom_timer", 0.0))
	if data.has("tool_tiers") and typeof(data["tool_tiers"]) == TYPE_DICTIONARY:
		var saved_tiers: Dictionary = data["tool_tiers"]
		for k in tool_tiers.keys():
			if saved_tiers.has(k):
				tool_tiers[k] = clampi(int(saved_tiers[k]), 1, 3)
		_apply_tool_tiers()
	if stun_comp and stun_comp.has_method("clear_stun"):
		stun_comp.clear_stun()
	is_stunned_flag = false
	if health_comp:
		health_comp.current_health = clamp(float(data.get("hp", health_comp.max_health)), 1.0, health_comp.max_health)
		health_comp.current_blood = clamp(float(data.get("blood", 0.0)), 0.0, health_comp.max_blood)
		health_comp.is_bleeding = bool(data.get("is_bleeding", false))
		if health_comp.is_bleeding:
			health_comp._bleed_timer = health_comp.bleed_duration
			health_comp._bleed_dps = 2.0
			health_comp.is_weak = true
			is_weak = true
			health_comp.weakness_changed.emit(true)
		else:
			health_comp._bleed_timer = 0.0
			health_comp._bleed_dps = 0.0
			health_comp.is_weak = false
			is_weak = false
			health_comp.weakness_changed.emit(false)
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
		watering_can_charges = clampi(int(data["watering_can_charges"]), 0, max_water_charges)
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
	apply_armor_stats()
