extends Node2D
class_name VillageManager

## Gestor de la Aldea Viva: Las 5 Casas Familiares, Los 5 Oficios, La Taberna y Sucesión en 2 Niveles — Fase 2.3 y 2.4
## - Construye 5 Casas Familiares completas (Suelo, Paredes con Puerta, 2 Camas, Mesa de Comedor Familiar y Taller delantero).
## - Cada casa alberga a una Familia (el Maestro del Oficio + su Familiar directo), ambos con Sub-stats dinámicos
##   de Hambre (🍖), Energía/Descanso (💤) y Socialización (💬).
## - Construye aparte la Taberna y Posada "El Jabalí Dorado" con salón comedor/social, la Tabernera Marta,
##   1 cama de alquiler para el jugador y 3 camas para los 3 NPCs sin oficio (Aldric, Sora y Darío).
## - Sucesión Orgánica en 2 Niveles:
##   1. Si el Maestro muere, su Familiar hereda el oficio familiar al día siguiente.
##   2. Si toda la familia falta, uno de los NPCs sin oficio de la Taberna se muda a la casa y asume el puesto.

var entities_root: Node = null

var trade_npcs: Dictionary = {}    # TradeRole -> VillageNPC (Titular actual del oficio)
var family_npcs: Dictionary = {}   # TradeRole -> VillageNPC (Familiar directo de esa casa)
var unemployed_npcs: Array[VillageNPC] = []
var trade_configs: Dictionary = {}

var _well_label: Label = null
var _compost_label: Label = null
var _tavern_bed_label: Label = null
var _tavern_games_label: Label = null

var _tavern_bed_pos := Vector2(516, -198)
var _tavern_social_pos := Vector2(422, -162)
var _tavern_games_pos := Vector2(488, -156)
var _well_pos := Vector2(184, 82)
var _compost_pos := Vector2(184, 114)

func setup_village(target_entities_root: Node) -> void:
	entities_root = target_entities_root if target_entities_root else self
	_spawn_tavern_and_rooms()
	_spawn_five_family_houses_and_trades()
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

	if _tavern_games_label:
		var near_g: bool = (player != null and player.global_position.distance_squared_to(_tavern_games_pos) <= 24.0 * 24.0) or (_tavern_games_pos.distance_squared_to(mouse_pos) <= 18.0 * 18.0)
		_tavern_games_label.visible = near_g

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

	# Suelo y paredes de la Taberna El Jabalí Dorado (x = 355..540, y = -225..-130)
	var floor_poly := Polygon2D.new()
	floor_poly.polygon = PackedVector2Array([
		Vector2(355, -225), Vector2(540, -225), Vector2(540, -130), Vector2(355, -130)
	])
	floor_poly.color = Color(0.36, 0.24, 0.14, 0.78)
	floor_poly.z_index = -2
	entities_root.add_child(floor_poly)

	var wall_line := Line2D.new()
	wall_line.width = 3.5
	wall_line.default_color = Color(0.58, 0.38, 0.19, 1.0)
	wall_line.points = PackedVector2Array([
		Vector2(420, -130), Vector2(355, -130), Vector2(355, -225),
		Vector2(540, -225), Vector2(540, -130), Vector2(468, -130)
	])
	entities_root.add_child(wall_line)

	var sign_lbl := Label.new()
	sign_lbl.text = "🍺 Taberna y Posada 'El Jabalí Dorado'"
	sign_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_lbl.position = Vector2(345, -243)
	sign_lbl.custom_minimum_size = Vector2(210, 18)
	sign_lbl.add_theme_font_size_override("font_size", 9)
	sign_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	sign_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	sign_lbl.add_theme_constant_override("outline_size", 3)
	entities_root.add_child(sign_lbl)

	# Mostrador de la Taberna y Mesa Social de Comedor
	var bar_spr := Sprite2D.new()
	bar_spr.texture = tex_stall
	bar_spr.global_position = Vector2(382, -168)
	bar_spr.scale = Vector2(1.25, 1.25)
	entities_root.add_child(bar_spr)

	var table_poly := Polygon2D.new()
	table_poly.polygon = PackedVector2Array([
		Vector2(-16, -7), Vector2(16, -7), Vector2(16, 7), Vector2(-16, 7)
	])
	table_poly.color = Color(0.52, 0.34, 0.18, 0.95)
	table_poly.global_position = _tavern_social_pos
	table_poly.z_index = -1
	entities_root.add_child(table_poly)

	# Mesa Verde de Juegos y Apuestas (Póker, Blackjack y Ruleta) dentro de la Taberna
	var games_rim := Polygon2D.new()
	games_rim.polygon = PackedVector2Array([
		Vector2(-18, -10), Vector2(18, -10), Vector2(18, 10), Vector2(-18, 10)
	])
	games_rim.color = Color(0.42, 0.26, 0.12, 1.0)
	games_rim.global_position = _tavern_games_pos
	games_rim.z_index = -1
	entities_root.add_child(games_rim)

	var games_felt := Polygon2D.new()
	games_felt.polygon = PackedVector2Array([
		Vector2(-15, -7), Vector2(15, -7), Vector2(15, 7), Vector2(-15, 7)
	])
	games_felt.color = Color(0.10, 0.48, 0.24, 1.0)
	games_felt.global_position = _tavern_games_pos
	games_felt.z_index = -1
	entities_root.add_child(games_felt)

	var games_area := Area2D.new()
	games_area.name = "TavernGamesTableArea"
	games_area.global_position = _tavern_games_pos
	games_area.collision_layer = 1
	games_area.collision_mask = 2
	games_area.add_to_group("interactable")
	games_area.set_meta("village_station", "tavern_games")
	var gcol := CollisionShape2D.new()
	var gc := CircleShape2D.new()
	gc.radius = 14.0
	gcol.shape = gc
	games_area.add_child(gcol)
	add_child(games_area)

	_tavern_games_label = _make_station_label(_tavern_games_pos + Vector2(-115, -28), "🎲 Mesa de Apuestas [E: Póker, Blackjack y Ruleta]")
	entities_root.add_child(_tavern_games_label)

	# 4 Camas en las habitaciones de la Taberna (3 para los NPCs sin oficio + 1 para alquilar por el jugador)
	var bed_positions: Array[Vector2] = [
		Vector2(444, -198),
		Vector2(468, -198),
		Vector2(492, -198),
		_tavern_bed_pos
	]
	for i in range(bed_positions.size()):
		var b_spr := Sprite2D.new()
		b_spr.texture = tex_bed
		b_spr.global_position = bed_positions[i]
		b_spr.scale = Vector2(1.12, 1.12)
		b_spr.z_index = -1
		entities_root.add_child(b_spr)

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
	marta.tavern_social_pos = _tavern_social_pos
	entities_root.add_child(marta)
	marta.setup_npc(
		tex_innkeeper,
		Vector2(382, -152),
		Vector2(374, -198),
		{"country_stew": 4, "bread": 6},
		_tavern_social_pos,
		"family_tavern",
		"Posada El Jabalí"
	)

func _spawn_five_family_houses_and_trades() -> void:
	var tex_stall := _load_tex("res://assests/world/village/work_stall.png")
	var tex_bed := _load_tex("res://assests/world/village/tavern_bed.png")
	var tex_family := _load_tex("res://assests/world/village/villager_traveler.png")

	# 5 Casas Familiares distribuidas en 2 filas amplias al Este de la parcela del jugador
	trade_configs = {
		VillageNPC.TradeRole.BUTCHER: {
			"family_id": "family_butcher",
			"family_name": "Familia Colmillo",
			"house_title": "🏠 Casa Colmillo (Carnicería)",
			"house_center": Vector2(335, -45),
			"name": "Garrick",
			"title": "Maestro Carnicero",
			"tex": _load_tex("res://assests/world/village/villager_butcher.png"),
			"stock": {"cooked_meat": 4, "leather": 3},
			"kin_name": "Lina",
			"kin_title": "Esposa y Curtidora"
		},
		VillageNPC.TradeRole.BLACKSMITH: {
			"family_id": "family_smith",
			"family_name": "Familia Yunque Gris",
			"house_title": "🏠 Casa Yunque Gris (Herrería)",
			"house_center": Vector2(455, -45),
			"name": "Thoran",
			"title": "Maestro Herrero",
			"tex": _load_tex("res://assests/world/village/villager_smith.png"),
			"stock": {"iron_ore": 3, "repair_kit": 2},
			"kin_name": "Kael",
			"kin_title": "Hijo y Aprendiz de Forja"
		},
		VillageNPC.TradeRole.CARPENTER: {
			"family_id": "family_carpenter",
			"family_name": "Familia Roble Viejo",
			"house_title": "🏠 Casa Roble Viejo (Carpintería)",
			"house_center": Vector2(575, -45),
			"name": "Bram",
			"title": "Maestro Carpintero",
			"tex": _load_tex("res://assests/world/village/villager_carpenter.png"),
			"stock": {"repair_kit": 4, "wood": 6},
			"kin_name": "Mila",
			"kin_title": "Hermana y Ebanista"
		},
		VillageNPC.TradeRole.HERBALIST: {
			"family_id": "family_herbalist",
			"family_name": "Familia Raíz Verde",
			"house_title": "🏠 Casa Raíz Verde (Herboristería)",
			"house_center": Vector2(385, 88),
			"name": "Elena",
			"title": "Herborista y Agricultora",
			"tex": _load_tex("res://assests/world/village/villager_herbalist.png"),
			"stock": {"carrot_seeds": 6, "cabbage_seeds": 6, "wheat_seeds": 6, "herbal_poultice": 3},
			"kin_name": "Tomás",
			"kin_title": "Esposo y Hortelano"
		},
		VillageNPC.TradeRole.FISHMONGER: {
			"family_id": "family_fishmonger",
			"family_name": "Familia Aguas Claras",
			"house_title": "🏠 Casa Aguas Claras (Pescadería)",
			"house_center": Vector2(515, 88),
			"name": "Marlo",
			"title": "Pescador y Molinero",
			"tex": _load_tex("res://assests/world/village/villager_fishmonger.png"),
			"stock": {"bread": 5, "fertilizer": 4, "cooked_fish": 3},
			"kin_name": "Nora",
			"kin_title": "Hija y Redera"
		}
	}

	for role_key in trade_configs.keys():
		var cfg: Dictionary = trade_configs[role_key]
		var hc: Vector2 = cfg["house_center"]
		var bed1_pos: Vector2 = hc + Vector2(-22, -18)
		var bed2_pos: Vector2 = hc + Vector2(22, -18)
		var table_pos: Vector2 = hc + Vector2(0, 2)
		var work_pos: Vector2 = hc + Vector2(0, 36)
		var kin_work_pos: Vector2 = hc + Vector2(-16, 8)

		cfg["work_pos"] = work_pos
		cfg["bed1_pos"] = bed1_pos
		cfg["bed2_pos"] = bed2_pos
		cfg["table_pos"] = table_pos

		_build_family_house_visuals(hc, str(cfg["house_title"]), tex_bed, tex_stall, bed1_pos, bed2_pos, table_pos, work_pos)

		# 1. Crear al Maestro del Oficio
		var master_npc := VillageNPC.new()
		master_npc.name = "NPC_" + str(cfg["name"])
		master_npc.npc_name = str(cfg["name"])
		master_npc.npc_role = str(cfg["title"])
		master_npc.trade_role = role_key
		master_npc.linked_trade = role_key
		master_npc.tavern_social_pos = _tavern_social_pos
		entities_root.add_child(master_npc)
		master_npc.setup_npc(
			cfg["tex"],
			work_pos,
			bed1_pos,
			cfg["stock"],
			table_pos,
			str(cfg["family_id"]),
			str(cfg["family_name"])
		)
		trade_npcs[role_key] = master_npc

		# 2. Crear al Familiar Directo en la misma Casa (vive, come, duerme y hereda el oficio si el maestro falta)
		var kin_npc := VillageNPC.new()
		kin_npc.name = "NPC_Kin_" + str(cfg["kin_name"])
		kin_npc.npc_name = str(cfg["kin_name"])
		kin_npc.npc_role = str(cfg["kin_title"])
		kin_npc.trade_role = VillageNPC.TradeRole.FAMILY_MEMBER
		kin_npc.linked_trade = role_key
		kin_npc.tavern_social_pos = _tavern_social_pos
		entities_root.add_child(kin_npc)
		kin_npc.setup_npc(
			tex_family,
			kin_work_pos,
			bed2_pos,
			{},
			table_pos,
			str(cfg["family_id"]),
			str(cfg["family_name"])
		)
		family_npcs[role_key] = kin_npc

func _build_family_house_visuals(
	hc: Vector2,
	house_title: String,
	tex_bed: Texture2D,
	tex_stall: Texture2D,
	bed1_pos: Vector2,
	bed2_pos: Vector2,
	table_pos: Vector2,
	work_pos: Vector2
) -> void:
	# Suelo de madera de la casa familiar (84 x 60 px)
	var floor_poly := Polygon2D.new()
	floor_poly.polygon = PackedVector2Array([
		hc + Vector2(-42, -32),
		hc + Vector2(42, -32),
		hc + Vector2(42, 22),
		hc + Vector2(-42, 22)
	])
	floor_poly.color = Color(0.38, 0.27, 0.17, 0.78)
	floor_poly.z_index = -2
	entities_root.add_child(floor_poly)

	# Paredes de la casa con puerta abierta al Sur (hacia el puesto de trabajo)
	var wall := Line2D.new()
	wall.width = 3.0
	wall.default_color = Color(0.60, 0.42, 0.23, 1.0)
	wall.points = PackedVector2Array([
		hc + Vector2(-14, 22),
		hc + Vector2(-42, 22),
		hc + Vector2(-42, -32),
		hc + Vector2(42, -32),
		hc + Vector2(42, 22),
		hc + Vector2(14, 22)
	])
	entities_root.add_child(wall)

	# Letrero de la Casa y Familia sobre el tejado
	var lbl := Label.new()
	lbl.text = house_title
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = hc + Vector2(-85, -48)
	lbl.custom_minimum_size = Vector2(170, 16)
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color(0.96, 0.88, 0.62))
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 3)
	entities_root.add_child(lbl)

	# 2 Camas familiares en la parte norte de la casa
	for b_pos in [bed1_pos, bed2_pos]:
		var bed := Sprite2D.new()
		bed.texture = tex_bed
		bed.global_position = b_pos
		bed.scale = Vector2(1.0, 1.0)
		bed.z_index = -1
		entities_root.add_child(bed)

	# Mesa de Comedor Familiar en el centro de la casa
	var table := Polygon2D.new()
	table.polygon = PackedVector2Array([
		Vector2(-10, -5), Vector2(10, -5), Vector2(10, 5), Vector2(-10, 5)
	])
	table.color = Color(0.55, 0.36, 0.19, 0.95)
	table.global_position = table_pos
	table.z_index = -1
	entities_root.add_child(table)

	# Puesto de trabajo / Mostrador delante de la puerta de la casa
	var stall := Sprite2D.new()
	stall.texture = tex_stall
	stall.global_position = work_pos + Vector2(0, -10)
	stall.scale = Vector2(1.22, 1.22)
	stall.z_index = -1
	entities_root.add_child(stall)

## 3 NPCs sin oficio que viven en las 3 habitaciones de la Taberna con rutinas dinámicas
func _spawn_unemployed_tavern_guests() -> void:
	var tex_traveler := _load_tex("res://assests/world/village/villager_traveler.png")
	var guest_defs: Array[Dictionary] = [
		{
			"name": "Aldric",
			"role": "Viajero sin Oficio",
			"day_pos": Vector2(390, -105),
			"bed_pos": Vector2(444, -198)
		},
		{
			"name": "Sora",
			"role": "Forastera sin Oficio",
			"day_pos": Vector2(445, 22),
			"bed_pos": Vector2(468, -198)
		},
		{
			"name": "Darío",
			"role": "Jornalero sin Oficio",
			"day_pos": Vector2(315, 22),
			"bed_pos": Vector2(492, -198)
		}
	]

	for g in guest_defs:
		var npc := VillageNPC.new()
		npc.name = "NPC_Guest_" + str(g["name"])
		npc.npc_name = str(g["name"])
		npc.npc_role = str(g["role"])
		npc.trade_role = VillageNPC.TradeRole.UNEMPLOYED
		npc.tavern_social_pos = _tavern_social_pos
		entities_root.add_child(npc)
		npc.setup_npc(
			tex_traveler,
			g["day_pos"],
			g["bed_pos"],
			{},
			_tavern_social_pos,
			"none",
			"Huésped de Posada"
		)
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
	var d_games: float = player.global_position.distance_squared_to(_tavern_games_pos)
	var d_well: float = player.global_position.distance_squared_to(_well_pos)
	var d_comp: float = player.global_position.distance_squared_to(_compost_pos)

	if d_games <= d_bed and d_games <= d_well and d_games <= d_comp and d_games <= 30.0 * 30.0:
		_use_tavern_games_table()
	elif d_bed <= d_well and d_bed <= d_comp and d_bed <= 26.0 * 26.0:
		_use_tavern_bed(player)
	elif d_well <= d_comp and d_well <= 26.0 * 26.0:
		_use_water_well(player)
	elif d_comp <= 26.0 * 26.0:
		_use_compost_bin(player)

func _use_tavern_games_table() -> void:
	var games_ui = get_tree().root.find_child("TavernGamesUI", true, false)
	if games_ui and games_ui.has_method("open_games"):
		games_ui.call("open_games")

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

## Producción diaria de stock y Sucesión en 2 Niveles (1.º Familiar de la casa -> 2.º Huésped sin oficio de la Taberna)
func _on_day_passed(_new_day: int) -> void:
	for role_key in trade_configs.keys():
		var current_holder: VillageNPC = trade_npcs.get(role_key)
		var cfg: Dictionary = trade_configs[role_key]

		if not is_instance_valid(current_holder) or current_holder.is_dead:
			# Nivel 1: ¿Vive el familiar directo de esa casa?
			var kin_candidate: VillageNPC = family_npcs.get(role_key)
			if is_instance_valid(kin_candidate) and not kin_candidate.is_dead and kin_candidate.trade_role == VillageNPC.TradeRole.FAMILY_MEMBER:
				kin_candidate.promote_to_trade(
					role_key,
					str(cfg["title"]),
					cfg["work_pos"],
					cfg["stock"],
					cfg["tex"]
				)
				trade_npcs[role_key] = kin_candidate
				var p1 = get_tree().get_first_node_in_group("player")
				if p1 and p1.has_method("show_hint"):
					p1.show_hint("🏠 Herencia Familiar: %s (%s) ha asumido el puesto de %s." % [kin_candidate.npc_name, str(cfg["family_name"]), str(cfg["title"])])
				continue

			# Nivel 2: Si también falta el familiar, un viajero sin oficio de la Taberna se muda a la casa y asume el oficio
			var outsider: VillageNPC = _pop_living_unemployed()
			if outsider:
				outsider.promote_to_trade(
					role_key,
					str(cfg["title"]),
					cfg["work_pos"],
					cfg["stock"],
					cfg["tex"],
					cfg["bed1_pos"],
					cfg["table_pos"],
					str(cfg["family_id"]),
					str(cfg["family_name"])
				)
				trade_npcs[role_key] = outsider
				var p2 = get_tree().get_first_node_in_group("player")
				if p2 and p2.has_method("show_hint"):
					p2.show_hint("🔄 Sucesión en la aldea: %s se ha mudado a la %s como nuevo %s." % [outsider.npc_name, str(cfg["house_title"]), str(cfg["title"])])
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
