extends Node2D
class_name VillageManager

## Gestor de la Aldea Viva: Los 5 Oficios, La Taberna con Habitaciones, Sucesión y Utilidades de Granja — Fase 2.3 y 2.4
## - Crea los 5 puestos de oficio (Carnicero, Herrero, Carpintero, Herborista, Pescador/Molinero) con stock real.
## - Crea la Taberna ("El Jabalí Dorado") aparte de los 5 oficios, con la Tabernera Marta, 1 cama de alquiler
##   para el jugador y 3 habitaciones con camas donde duermen de noche los 3 NPCs sin oficio (Aldric, Sora y Darío).
## - Gestiona la producción diaria de stock y el sistema de Sucesión: si un artesano muere, al día siguiente
##   uno de los NPCs sin oficio de la Taberna asume su puesto de trabajo.

var entities_root: Node = null

var trade_npcs: Dictionary = {} # TradeRole -> VillageNPC
var unemployed_npcs: Array[VillageNPC] = []
var trade_configs: Dictionary = {}

var _well_label: Label = null
var _compost_label: Label = null
var _tavern_bed_label: Label = null
var _tavern_bed_pos := Vector2(486, -168)
var _well_pos := Vector2(184, 82)
var _compost_pos := Vector2(184, 114)

func setup_village(target_entities_root: Node) -> void:
	entities_root = target_entities_root if target_entities_root else self
	_spawn_tavern_and_rooms()
	_spawn_five_trades()
	_spawn_unemployed_tavern_guests()
	_spawn_farm_well_and_compost()

	if WorldClock and not WorldClock.day_passed.is_connected(_on_day_passed):
		WorldClock.day_passed.connect(_on_day_passed)

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	var mouse_pos := get_global_mouse_position()

	if _tavern_bed_label:
		var near_b: bool = (player != null and player.global_position.distance_squared_to(_tavern_bed_pos) <= 22.0 * 22.0) or (_tavern_bed_pos.distance_squared_to(mouse_pos) <= 16.0 * 16.0)
		_tavern_bed_label.visible = near_b

	if _well_label:
		var near_w: bool = (player != null and player.global_position.distance_squared_to(_well_pos) <= 22.0 * 22.0) or (_well_pos.distance_squared_to(mouse_pos) <= 16.0 * 16.0)
		_well_label.visible = near_w

	if _compost_label:
		var near_c: bool = (player != null and player.global_position.distance_squared_to(_compost_pos) <= 22.0 * 22.0) or (_compost_pos.distance_squared_to(mouse_pos) <= 16.0 * 16.0)
		_compost_label.visible = near_c

func _spawn_tavern_and_rooms() -> void:
	var tex_bed := _load_tex("res://assests/world/village/tavern_bed.png")
	var tex_stall := _load_tex("res://assests/world/village/work_stall.png")
	var tex_innkeeper := _load_tex("res://assests/world/village/villager_innkeeper.png")

	# Suelo de madera y paredes de la Taberna El Jabalí Dorado (x = 340..510, y = -200..-110)
	var floor_poly := Polygon2D.new()
	floor_poly.polygon = PackedVector2Array([
		Vector2(340, -200), Vector2(510, -200), Vector2(510, -110), Vector2(340, -110)
	])
	floor_poly.color = Color(0.36, 0.24, 0.14, 0.72)
	floor_poly.z_index = -2
	entities_root.add_child(floor_poly)

	var wall_line := Line2D.new()
	wall_line.width = 3.5
	wall_line.default_color = Color(0.55, 0.36, 0.18, 1.0)
	wall_line.points = PackedVector2Array([
		Vector2(395, -110), Vector2(340, -110), Vector2(340, -200),
		Vector2(510, -200), Vector2(510, -110), Vector2(445, -110)
	])
	entities_root.add_child(wall_line)

	var sign_lbl := Label.new()
	sign_lbl.text = "🍺 Taberna y Posada 'El Jabalí Dorado'"
	sign_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_lbl.position = Vector2(325, -218)
	sign_lbl.custom_minimum_size = Vector2(200, 18)
	sign_lbl.add_theme_font_size_override("font_size", 9)
	sign_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	sign_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	sign_lbl.add_theme_constant_override("outline_size", 3)
	entities_root.add_child(sign_lbl)

	# Mostrador de la Taberna
	var bar_spr := Sprite2D.new()
	bar_spr.texture = tex_stall
	bar_spr.global_position = Vector2(372, -142)
	bar_spr.scale = Vector2(1.25, 1.25)
	entities_root.add_child(bar_spr)

	# 4 Camas en las habitaciones de la Taberna (3 para los NPCs sin oficio + 1 para alquilar por el jugador)
	var bed_positions: Array[Vector2] = [
		Vector2(414, -168),
		Vector2(438, -168),
		Vector2(462, -168),
		_tavern_bed_pos
	]
	for i in range(bed_positions.size()):
		var b_spr := Sprite2D.new()
		b_spr.texture = tex_bed
		b_spr.global_position = bed_positions[i]
		b_spr.scale = Vector2(1.15, 1.15)
		b_spr.z_index = -1
		entities_root.add_child(b_spr)

	# Cama de alquiler interactuable para el jugador (4.ª cama a la derecha)
	var bed_area := Area2D.new()
	bed_area.name = "TavernPlayerBedArea"
	bed_area.global_position = _tavern_bed_pos
	bed_area.collision_layer = 1
	bed_area.collision_mask = 2
	bed_area.add_to_group("interactable")
	bed_area.set_meta("village_station", "tavern_bed")
	var bcol := CollisionShape2D.new()
	var bc := CircleShape2D.new()
	bc.radius = 10.0
	bcol.shape = bc
	bed_area.add_child(bcol)
	add_child(bed_area)

	_tavern_bed_label = _make_station_label(_tavern_bed_pos + Vector2(-115, -28), "🛌 Cama de Posada [E: Dormir hasta 06:00 (-8 Oro)]")
	entities_root.add_child(_tavern_bed_label)

	# Tabernera Marta
	var marta := VillageNPC.new()
	marta.name = "NPC_Marta_Innkeeper"
	marta.npc_name = "Marta"
	marta.npc_role = "Tabernera"
	marta.trade_role = VillageNPC.TradeRole.INNKEEPER
	entities_root.add_child(marta)
	marta.setup_npc(tex_innkeeper, Vector2(372, -125), Vector2(360, -172), {
		"country_stew": 3,
		"bread": 5
	})

func _spawn_five_trades() -> void:
	var tex_stall := _load_tex("res://assests/world/village/work_stall.png")
	var tex_bed := _load_tex("res://assests/world/village/tavern_bed.png")

	trade_configs = {
		VillageNPC.TradeRole.BUTCHER: {
			"name": "Garrick",
			"title": "Carnicero y Peletero",
			"tex": _load_tex("res://assests/world/village/villager_butcher.png"),
			"work_pos": Vector2(335, -35),
			"bed_pos": Vector2(335, -62),
			"stock": {"cooked_meat": 4, "leather": 3}
		},
		VillageNPC.TradeRole.BLACKSMITH: {
			"name": "Thoran",
			"title": "Herrero",
			"tex": _load_tex("res://assests/world/village/villager_smith.png"),
			"work_pos": Vector2(420, -35),
			"bed_pos": Vector2(420, -62),
			"stock": {"iron_ore": 3, "repair_kit": 2}
		},
		VillageNPC.TradeRole.CARPENTER: {
			"name": "Bram",
			"title": "Carpintero",
			"tex": _load_tex("res://assests/world/village/villager_carpenter.png"),
			"work_pos": Vector2(505, -35),
			"bed_pos": Vector2(505, -62),
			"stock": {"repair_kit": 4, "wood": 6}
		},
		VillageNPC.TradeRole.HERBALIST: {
			"name": "Elena",
			"title": "Herborista y Agricultora",
			"tex": _load_tex("res://assests/world/village/villager_herbalist.png"),
			"work_pos": Vector2(355, 65),
			"bed_pos": Vector2(355, 40),
			"stock": {"carrot_seeds": 6, "cabbage_seeds": 6, "wheat_seeds": 6, "herbal_poultice": 3}
		},
		VillageNPC.TradeRole.FISHMONGER: {
			"name": "Marlo",
			"title": "Pescador y Molinero",
			"tex": _load_tex("res://assests/world/village/villager_fishmonger.png"),
			"work_pos": Vector2(455, 65),
			"bed_pos": Vector2(455, 40),
			"stock": {"bread": 5, "fertilizer": 4, "cooked_fish": 3}
		}
	}

	for role_key in trade_configs.keys():
		var cfg: Dictionary = trade_configs[role_key]
		var w_pos: Vector2 = cfg["work_pos"]
		var b_pos: Vector2 = cfg["bed_pos"]

		var stall := Sprite2D.new()
		stall.texture = tex_stall
		stall.global_position = w_pos + Vector2(0, -12)
		stall.scale = Vector2(1.25, 1.25)
		stall.z_index = -1
		entities_root.add_child(stall)

		var bed := Sprite2D.new()
		bed.texture = tex_bed
		bed.global_position = b_pos
		bed.scale = Vector2(1.05, 1.05)
		bed.z_index = -1
		entities_root.add_child(bed)

		var npc := VillageNPC.new()
		npc.name = "NPC_" + str(cfg["name"])
		npc.npc_name = str(cfg["name"])
		npc.npc_role = str(cfg["title"])
		npc.trade_role = role_key
		entities_root.add_child(npc)
		npc.setup_npc(cfg["tex"], w_pos, b_pos, cfg["stock"])
		trade_npcs[role_key] = npc

## 3 NPCs sin oficio que socializan de día y duermen en las 3 habitaciones de la Taberna de noche
func _spawn_unemployed_tavern_guests() -> void:
	var tex_traveler := _load_tex("res://assests/world/village/villager_traveler.png")
	var guest_defs: Array[Dictionary] = [
		{
			"name": "Aldric",
			"role": "Viajero sin Oficio",
			"day_pos": Vector2(380, -10),
			"bed_pos": Vector2(414, -168)
		},
		{
			"name": "Sora",
			"role": "Forastera sin Oficio",
			"day_pos": Vector2(415, 18),
			"bed_pos": Vector2(438, -168)
		},
		{
			"name": "Darío",
			"role": "Jornalero sin Oficio",
			"day_pos": Vector2(315, 15),
			"bed_pos": Vector2(462, -168)
		}
	]

	for g in guest_defs:
		var npc := VillageNPC.new()
		npc.name = "NPC_Guest_" + str(g["name"])
		npc.npc_name = str(g["name"])
		npc.npc_role = str(g["role"])
		npc.trade_role = VillageNPC.TradeRole.UNEMPLOYED
		entities_root.add_child(npc)
		npc.setup_npc(tex_traveler, g["day_pos"], g["bed_pos"], {})
		unemployed_npcs.append(npc)

func _spawn_farm_well_and_compost() -> void:
	var tex_well := _load_tex("res://assests/world/village/water_well.png")
	var tex_compost := _load_tex("res://assests/world/village/compost_bin.png")

	var well_spr := Sprite2D.new()
	well_spr.texture = tex_well
	well_spr.global_position = _well_pos
	well_spr.scale = Vector2(1.25, 1.25)
	entities_root.add_child(well_spr)

	var well_area := Area2D.new()
	well_area.name = "WaterWellArea"
	well_area.global_position = _well_pos
	well_area.collision_layer = 1
	well_area.collision_mask = 2
	well_area.add_to_group("interactable")
	well_area.set_meta("village_station", "well")
	var wcol := CollisionShape2D.new()
	var wc := CircleShape2D.new()
	wc.radius = 10.0
	wcol.shape = wc
	well_area.add_child(wcol)
	add_child(well_area)

	_well_label = _make_station_label(_well_pos + Vector2(-110, -28), "🪣 Pozo de Agua [E: Llenar Regadera al 100%]")
	entities_root.add_child(_well_label)

	var comp_spr := Sprite2D.new()
	comp_spr.texture = tex_compost
	comp_spr.global_position = _compost_pos
	comp_spr.scale = Vector2(1.25, 1.25)
	entities_root.add_child(comp_spr)

	var comp_area := Area2D.new()
	comp_area.name = "CompostBinArea"
	comp_area.global_position = _compost_pos
	comp_area.collision_layer = 1
	comp_area.collision_mask = 2
	comp_area.add_to_group("interactable")
	comp_area.set_meta("village_station", "compost")
	var ccol := CollisionShape2D.new()
	var cc := CircleShape2D.new()
	cc.radius = 10.0
	ccol.shape = cc
	comp_area.add_child(ccol)
	add_child(comp_area)

	_compost_label = _make_station_label(_compost_pos + Vector2(-115, -28), "♻️ Compostador [E: Crear Abono con Hierba/Hongo]")
	entities_root.add_child(_compost_label)

func interact(player: Node2D) -> void:
	if not player:
		return
	var d_bed: float = player.global_position.distance_squared_to(_tavern_bed_pos)
	var d_well: float = player.global_position.distance_squared_to(_well_pos)
	var d_comp: float = player.global_position.distance_squared_to(_compost_pos)

	if d_bed <= d_well and d_bed <= d_comp and d_bed <= 26.0 * 26.0:
		_use_tavern_bed(player)
	elif d_well <= d_comp and d_well <= 26.0 * 26.0:
		_use_water_well(player)
	elif d_comp <= 26.0 * 26.0:
		_use_compost_bin(player)

func _use_tavern_bed(player: Node2D) -> void:
	var inv: SimpleInventory = player.get("inventory")
	if not inv or inv.gold < 8:
		if player.has_method("show_hint"):
			player.show_hint("🛌 Necesitas 8 Oro para alquilar la cama de la Taberna.")
		return
	inv.add_gold(-8)
	var surv: SurvivalComponent = player.get_node_or_null("SurvivalComponent")
	var stam: StaminaComponent = player.get_node_or_null("StaminaComponent")
	var health: HealthComponent = player.get_node_or_null("HealthComponent")
	if surv:
		surv.restore_sleep(100.0)
	if stam:
		stam.current_stamina = stam.max_stamina
		stam.stamina_changed.emit(stam.current_stamina, stam.max_stamina)
	if health:
		health.heal(35.0)
	if WorldClock:
		WorldClock.sleep_until_morning()
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🛌 Dormiste en la Posada (-8 Oro, +100% Sueño)", Color.GOLD, -42.0)

func _use_water_well(player: Node2D) -> void:
	if player.has_method("refill_watering_can"):
		player.call("refill_watering_can")
	elif player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("💧 Agua fresca del pozo", Color.AQUA, -40.0)

func _use_compost_bin(player: Node2D) -> void:
	var inv: SimpleInventory = player.get("inventory")
	if not inv:
		return
	for org_id in ["mushroom", "herbs", "carrot", "cabbage"]:
		if inv.remove_item(org_id, 1):
			inv.add_item("fertilizer", 2)
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("♻️ Compostador: +2 Abono Orgánico", Color.SPRING_GREEN, -42.0)
			return
	if player.has_method("show_hint"):
		player.show_hint("♻️ Necesitas 1 Hongo, Hierba o Verdura para fermentar 2 bolsas de Abono Orgánico.")

## Producción diaria de stock y Sucesión de oficios vacantes al cambiar de día
func _on_day_passed(_new_day: int) -> void:
	for role_key in trade_configs.keys():
		var current_holder: VillageNPC = trade_npcs.get(role_key)
		var cfg: Dictionary = trade_configs[role_key]

		if not is_instance_valid(current_holder) or current_holder.is_dead:
			# ¡El puesto está vacante! Buscar un sucesor entre los NPCs sin oficio de la Taberna
			var successor: VillageNPC = _pop_living_unemployed()
			if successor:
				successor.promote_to_trade(role_key, str(cfg["title"]), cfg["work_pos"], cfg["stock"], cfg["tex"])
				trade_npcs[role_key] = successor
				var player = get_tree().get_first_node_in_group("player")
				if player and player.has_method("show_hint"):
					player.show_hint("🔄 Sucesión en la aldea: %s ha asumido el puesto vacante de %s." % [successor.npc_name, str(cfg["title"])])
		else:
			# Reponer producción diaria del oficio
			var base_stock: Dictionary = cfg["stock"]
			for item_k in base_stock.keys():
				var cur_amt: int = int(current_holder.shop_stock.get(item_k, 0))
				var max_amt: int = int(base_stock[item_k]) + 2
				if cur_amt < max_amt:
					current_holder.shop_stock[item_k] = cur_amt + 1

func _pop_living_unemployed() -> VillageNPC:
	for i in range(unemployed_npcs.size()):
		var cand: VillageNPC = unemployed_npcs[i]
		if is_instance_valid(cand) and not cand.is_dead and cand.trade_role == VillageNPC.TradeRole.UNEMPLOYED:
			unemployed_npcs.remove_at(i)
			return cand
	return null

func _make_station_label(pos: Vector2, txt: String) -> Label:
	var lbl := Label.new()
	lbl.visible = false
	lbl.text = txt
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = pos
	lbl.custom_minimum_size = Vector2(230, 20)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.68))
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.z_index = 20
	return lbl

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
