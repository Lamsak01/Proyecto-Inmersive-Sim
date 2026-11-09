@tool
extends RefCounted

## Construcción inicial del pueblo (caminos, edificios y mobiliario). Extraído de VillageManager.gd:
## cada función recibe al VillageManager como primer parámetro (`vm`) y solo se ejecuta al montar el mundo.

# ==============================================================================
# RED DE CAMINOS Y BIOMAS EXTERIORES
# ==============================================================================
static func _spawn_village_roads_and_plaza(vm: VillageManager) -> void:
	var dirt_col := Color(0.46, 0.36, 0.24, 0.65)

	# 1. Camino Largo Oeste-Este desde las tierras salvajes (-1950, 36) pasando por el Campamento/Lago (-715) hasta el Borde Este (1010)
	_add_road_rect(vm, Rect2(Vector2(-1950, 36), Vector2(2960, 28)), dirt_col)
	_add_road_rect(vm, Rect2(Vector2(-688, -88), Vector2(18, 124)), dirt_col)
	_add_road_rect(vm, Rect2(Vector2(-688, 64), Vector2(18, 36)), dirt_col)
	_add_road_rect(vm, Rect2(Vector2(-1520, -140), Vector2(22, 176)), dirt_col)
	_add_road_rect(vm, Rect2(Vector2(-1520, 64), Vector2(22, 120)), dirt_col)

	# 2. Plaza Central Empedrada (x = 395..535, y = 10..88) y Patio Lateral del Pozo de la Taberna
	_add_cobble_rect(vm, Rect2(Vector2(395, 10), Vector2(140, 78)))
	_add_cobble_rect(vm, Rect2(Vector2(202, -250), Vector2(52, 46)))
	var plaza_border := Line2D.new()
	plaza_border.width = 2.0
	plaza_border.default_color = Color(0.28, 0.24, 0.20, 0.90)
	plaza_border.points = PackedVector2Array([
		Vector2(395, 10), Vector2(535, 10), Vector2(535, 88), Vector2(395, 88), Vector2(395, 10)
	])
	plaza_border.z_index = -2
	vm.entities_root.add_child(plaza_border)

	# 3. Avenida Norte-Sur desde la Gran Posada (-135) hasta el Bosque Profundo alejado al sur (+760)
	_add_road_rect(vm, Rect2(Vector2(448, -135), Vector2(34, 920)), dirt_col)
	_add_road_rect(vm, Rect2(Vector2(140, 130), Vector2(24, 248)), dirt_col)
	_add_road_rect(vm, Rect2(Vector2(140, 356), Vector2(312, 22)), dirt_col)
	_add_road_rect(vm, Rect2(Vector2(-380, 760), Vector2(1040, 24)), dirt_col)
	_add_road_rect(vm, Rect2(Vector2(130, 780), Vector2(26, 260)), dirt_col)

	# 4. Calles del Barrio Residencial, Distrito Hospital/Comisaría Este y Callejón hacia la Iglesia y Cementerio Parroquial
	_add_road_rect(vm, Rect2(Vector2(660, -135), Vector2(310, 24)), dirt_col)
	_add_road_rect(vm, Rect2(Vector2(660, -135), Vector2(24, 240)), dirt_col)
	_add_cobble_rect(vm, Rect2(Vector2(660, 76), Vector2(325, 22)))
	_add_cobble_rect(vm, Rect2(Vector2(819, 76), Vector2(20, 184)))
	_add_cobble_rect(vm, Rect2(Vector2(680, 240), Vector2(415, 20)))

	_spawn_world_signpost(vm, Vector2(-655, 12), "🏕️ Campamento y Lago del Oeste | ➡️ Camino Largo a la Aldea", Color(0.75, 0.94, 1.0))
	_spawn_world_signpost(vm, Vector2(-1010, 12), "⬅️ Oeste Lejano: Llanura Salvaje (N) y Ciénaga de Ranas (S)", Color(1.0, 0.86, 0.48))
	_spawn_world_signpost(vm, Vector2(465, 580), "⬇️ Sendero al Bosque Profundo del Sur", Color(0.76, 0.96, 0.68))
	_spawn_world_signpost(vm, Vector2(668, 72), "➡️ Este: 🏥 Hospital y Morgue Forense | 🚓 Comisaría y Cárcel", Color(0.68, 0.92, 1.0))

static func _spawn_world_signpost(vm: VillageManager, pos: Vector2, text_str: String, text_col: Color) -> void:
	vm._add_sprite_prop(vm._load_tex("res://assests/Comprados/Epic RPG World - The Village V2.1/buildings/Decorations_sprites/sign_1.png"), pos, Vector2(0.9, 0.9), -1)
	vm._add_title_label(pos + Vector2(-155, -28), Vector2(310, 16), text_str, text_col, 8)

static func _spawn_western_plains_and_frog_marsh(vm: VillageManager) -> void:
	# 1. Llanura Salvaje del Noroeste (separada y mucho más amplia: x = -2050..-1080, y = -560..-20)
	var plains_poly := PackedVector2Array([
		Vector2(-2020, -490), Vector2(-1780, -560), Vector2(-1420, -540), Vector2(-1120, -470),
		Vector2(-1080, -260), Vector2(-1110, -45), Vector2(-1380, -20), Vector2(-1760, -28),
		Vector2(-2040, -110), Vector2(-2060, -310)
	])
	vm._add_poly(plains_poly, Color(0.58, 0.50, 0.26, 0.44), -4)
	# Ruinas de bandidos en la llanura norte
	vm._add_poly(PackedVector2Array([
		Vector2(-1740, -380), Vector2(-1320, -390), Vector2(-1290, -160), Vector2(-1760, -150)
	]), Color(0.42, 0.33, 0.22, 0.62), -3)

	# 2. Ciénaga de las Ranas del Suroeste (separada al sur del camino y mucho más amplia: x = -2020..-1100, y = 110..560)
	var marsh_outer := PackedVector2Array([
		Vector2(-1960, 150), Vector2(-1680, 110), Vector2(-1320, 120), Vector2(-1100, 190),
		Vector2(-1120, 420), Vector2(-1280, 540), Vector2(-1640, 560), Vector2(-1940, 490),
		Vector2(-2020, 320)
	])
	var marsh_water := PackedVector2Array([
		Vector2(-1860, 210), Vector2(-1620, 165), Vector2(-1340, 180), Vector2(-1200, 250),
		Vector2(-1220, 390), Vector2(-1360, 470), Vector2(-1650, 485), Vector2(-1850, 420),
		Vector2(-1910, 310)
	])
	vm._add_poly(marsh_outer, Color(0.26, 0.36, 0.24, 0.75), -3)
	vm._add_poly(marsh_water, Color(0.16, 0.44, 0.42, 0.82), -2)

	_spawn_world_signpost(vm, Vector2(-1140, -22), "🌾 Llanura Salvaje del Noroeste — ⚠️ Ruinas y Bandidos", Color(1.0, 0.78, 0.36))
	_spawn_world_signpost(vm, Vector2(-1480, 108), "🐸 Ciénaga de las Ranas del Suroeste", Color(0.62, 0.96, 0.68))

static func _add_road_rect(vm: VillageManager, rect: Rect2, col: Color) -> void:
	vm._add_poly(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), col, -3)

static func _add_cobble_rect(vm: VillageManager, rect: Rect2) -> void:
	var cobble_tex := vm._load_tex("res://assests/world/village/floor_plaza_cobble.png")
	if cobble_tex:
		var c_rect := TextureRect.new()
		c_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c_rect.texture = cobble_tex
		c_rect.stretch_mode = TextureRect.STRETCH_TILE
		c_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		c_rect.position = rect.position
		c_rect.size = rect.size
		c_rect.z_index = -3
		c_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vm.entities_root.add_child(c_rect)
	else:
		_add_road_rect(vm, rect, Color(0.46, 0.42, 0.36, 0.90))

# EDIFICIO MIXTO #1: GRAN POSADA DE 2 PLANTAS, TABERNA, CASINO Y SÓTANO DE PELEAS
static func _spawn_tavern_and_rooms(vm: VillageManager) -> void:
	preload("res://scripts/systems/VillageTavern.gd").setup_world(vm)

# 4 LOCALES COMERCIALES + 4 CASAS RESIDENCIALES + BOTICA-VIVIENDA MIXTA
static func _spawn_five_family_houses_and_trades(vm: VillageManager) -> void:
	var tex_stall := vm._load_tex("res://assests/world/village/work_stall.png")
	var tex_bed := vm._load_tex("res://assests/world/village/tavern_bed.png")
	var tex_family := vm._load_tex("res://assests/world/village/villager_traveler.png")

	vm.trade_configs = {
		VillageNPC.TradeRole.BLACKSMITH: {
			"family_id": "family_smith", "family_name": "Familia Yunque Gris",
			"shop_title": "⚒️ Herrería y Armería 'Yunque Gris'", "shop_center": Vector2(335, -36),
			"shop_door_south": true, "is_mixed_building": false,
			"house_title": "🏠 Residencia Familia Yunque Gris", "house_center": Vector2(745, -195),
			"name": "Thoran", "title": "Maestro Herrero y Armero",
			"tex": vm._load_tex("res://assests/world/village/villager_smith.png"),
			"stock": {"iron_ore": 4, "repair_kit": 3},
			"kin_name": "Kael", "kin_title": "Hijo y Aprendiz de Forja"
		},
		VillageNPC.TradeRole.BUTCHER: {
			"family_id": "family_butcher", "family_name": "Familia Colmillo",
			"shop_title": "🥩 Carnicería y Peletería 'El Colmillo'", "shop_center": Vector2(585, -36),
			"shop_door_south": true, "is_mixed_building": false,
			"house_title": "🏠 Residencia Familia Colmillo", "house_center": Vector2(905, -195),
			"name": "Garrick", "title": "Maestro Carnicero",
			"tex": vm._load_tex("res://assests/world/village/villager_butcher.png"),
			"stock": {"cooked_meat": 5, "leather": 4, "roasted_chicken": 2},
			"kin_name": "Lina", "kin_title": "Hermana y Curtidora"
		},
		VillageNPC.TradeRole.CARPENTER: {
			"family_id": "family_carpenter", "family_name": "Familia Roble Viejo",
			"shop_title": "🪚 Carpintería y Aserradero 'Roble Viejo'", "shop_center": Vector2(585, 148),
			"shop_door_south": false, "is_mixed_building": false,
			"house_title": "🏠 Residencia Familia Roble Viejo", "house_center": Vector2(745, -36),
			"name": "Bram", "title": "Maestro Carpintero",
			"tex": vm._load_tex("res://assests/world/village/villager_carpenter.png"),
			"stock": {"repair_kit": 5, "wood": 8, "copper_coil": 2, "empty_flask": 3},
			"kin_name": "Mila", "kin_title": "Hermana y Ebanista"
		},
		VillageNPC.TradeRole.FISHMONGER: {
			"family_id": "family_fishmonger", "family_name": "Familia Aguas Claras",
			"shop_title": "🐟 Pescadería y Molino 'Aguas Claras'", "shop_center": Vector2(465, 148),
			"shop_door_south": false, "is_mixed_building": false,
			"house_title": "🏠 Residencia Familia Aguas Claras", "house_center": Vector2(905, -36),
			"name": "Marlo", "title": "Pescador y Molinero",
			"tex": vm._load_tex("res://assests/world/village/villager_fishmonger.png"),
			"stock": {"bread": 6, "fertilizer": 5, "cooked_fish": 4},
			"kin_name": "Nora", "kin_title": "Hija y Redera"
		},
		VillageNPC.TradeRole.HERBALIST: {
			"family_id": "family_herbalist", "family_name": "Familia Raíz Verde",
			"shop_title": "🌿 Botica y Casa-Jardín 'Raíz Verde'", "shop_center": Vector2(325, 155),
			"shop_door_south": false, "is_mixed_building": true,
			"house_title": "🌿 Botica y Vivienda Raíz Verde", "house_center": Vector2(325, 155),
			"name": "Elena", "title": "Herborista y Alquimista",
			"tex": vm._load_tex("res://assests/world/village/villager_herbalist.png"),
			"stock": {"carrot_seeds": 8, "cabbage_seeds": 8, "wheat_seeds": 8, "herbal_poultice": 4, "sleeping_draught": 2, "surgical_kit": 1, "clean_water": 3, "empty_flask": 2},
			"kin_name": "Tomás", "kin_title": "Hermano y Hortelano"
		}
	}

	for role_key in vm.trade_configs.keys():
		var cfg: Dictionary = vm.trade_configs[role_key]
		var is_mixed: bool = bool(cfg.get("is_mixed_building", false))
		var sc: Vector2 = cfg["shop_center"]
		var hc: Vector2 = cfg["house_center"]
		var fam_id: String = str(cfg["family_id"])

		var shop_door_s: bool = bool(cfg.get("shop_door_south", true))
		var work_pos: Vector2 = sc + (Vector2(0, -6) if shop_door_s else Vector2(0, 8))
		var bed1_pos: Vector2 = hc + Vector2(-30, -18)
		var bed2_pos: Vector2 = hc + Vector2(30, -18)
		var table_pos: Vector2 = hc + Vector2(0, -2)
		var kin_work_pos: Vector2 = sc + (Vector2(-24, -6) if shop_door_s else Vector2(-24, 8))

		if is_mixed:
			work_pos = sc + Vector2(0, -18)
			bed1_pos = sc + Vector2(-36, 26)
			bed2_pos = sc + Vector2(36, 26)
			table_pos = sc + Vector2(0, 24)
			kin_work_pos = sc + Vector2(-24, -14)
			_build_mixed_shop_house_visuals(vm, sc, str(cfg["shop_title"]), tex_bed, tex_stall, bed1_pos, bed2_pos, table_pos, work_pos, fam_id, int(role_key))
		else:
			var is_smithy: bool = (role_key == VillageNPC.TradeRole.BLACKSMITH)
			_build_enclosed_shop_visuals(vm, sc, str(cfg["shop_title"]), tex_stall, work_pos, bool(cfg["shop_door_south"]), is_smithy, fam_id, int(role_key))
			_build_residential_house_visuals(vm, hc, str(cfg["house_title"]), tex_bed, bed1_pos, bed2_pos, table_pos, fam_id)

		cfg["work_pos"] = work_pos
		cfg["kin_work_pos"] = kin_work_pos
		cfg["bed1_pos"] = bed1_pos
		cfg["bed2_pos"] = bed2_pos
		cfg["table_pos"] = table_pos

		var master_npc := VillageNPC.new()
		master_npc.name = "NPC_" + str(cfg["name"])
		master_npc.npc_name = str(cfg["name"])
		master_npc.npc_role = str(cfg["title"])
		master_npc.trade_role = role_key
		master_npc.linked_trade = role_key
		master_npc.tavern_social_pos = vm._tavern_social_pos
		vm.entities_root.add_child(master_npc)
		master_npc.setup_npc(cfg["tex"], work_pos, bed1_pos, cfg["stock"], table_pos, fam_id, str(cfg["family_name"]))
		vm.trade_npcs[role_key] = master_npc

		var kin_npc := VillageNPC.new()
		kin_npc.name = "NPC_Kin_" + str(cfg["kin_name"])
		kin_npc.npc_name = str(cfg["kin_name"])
		kin_npc.npc_role = str(cfg["kin_title"])
		kin_npc.trade_role = VillageNPC.TradeRole.FAMILY_MEMBER
		kin_npc.linked_trade = role_key
		kin_npc.tavern_social_pos = vm._tavern_social_pos
		vm.entities_root.add_child(kin_npc)
		kin_npc.setup_npc(tex_family, kin_work_pos, bed2_pos, {}, table_pos, fam_id, str(cfg["family_name"]))
		vm.family_npcs[role_key] = kin_npc

static func _build_enclosed_shop_visuals(vm: VillageManager, sc: Vector2, shop_title: String, tex_stall: Texture2D, work_pos: Vector2, door_on_south: bool, is_blacksmith: bool, fam_id: String, role_id: int = -1) -> void:
	var floor_p: String = "res://assests/world/village/floor_stone_forge.png" if is_blacksmith else "res://assests/world/village/floor_wood_planks.png"
	var wall_h_p: String = "res://assests/world/village/wall_stone_h.png" if is_blacksmith else "res://assests/world/village/wall_timber_h.png"
	var wall_v_p: String = "res://assests/world/village/wall_stone_v.png" if is_blacksmith else "res://assests/world/village/wall_timber_v.png"

	vm._construct_solid_building(
		"shop_" + fam_id, shop_title, sc, Vector2(116, 76), door_on_south,
		floor_p, wall_h_p, wall_v_p, 40.0, 0.0,
		Color(1.0, 0.88, 0.52) if is_blacksmith else Color(0.95, 0.90, 0.68)
	)
	var stall := vm._add_sprite_prop(tex_stall, work_pos + (Vector2(0, -10) if door_on_south else Vector2(0, 10)), Vector2(1.32, 1.32), -1)
	if role_id >= 0:
		vm._register_shop_business_stall(role_id, shop_title, fam_id, stall.global_position, stall)

	vm._spawn_house_chest(sc + (Vector2(38, -20) if door_on_south else Vector2(38, 20)), "Cofre de " + shop_title, fam_id)
	if is_blacksmith:
		vm._spawn_decor_prop("res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/fireplace_0.png", sc + Vector2(-36, -16), Vector2(0.32, 0.32))
		vm._spawn_decor_prop("res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/stand-1_part5.png", sc + Vector2(26, -12), Vector2(0.65, 0.65))

static func _build_residential_house_visuals(vm: VillageManager, hc: Vector2, house_title: String, tex_bed: Texture2D, bed1_pos: Vector2, bed2_pos: Vector2, table_pos: Vector2, fam_id: String) -> void:
	vm._construct_solid_building(
		"house_" + fam_id, house_title, hc, Vector2(112, 78), true,
		"res://assests/world/village/floor_wood_planks.png",
		"res://assests/world/village/wall_timber_h.png",
		"res://assests/world/village/wall_timber_v.png",
		38.0, 0.0, Color(0.92, 0.88, 0.72)
	)
	vm._add_rect_poly(hc + Vector2(0, 5), Vector2(24, 13), Color(0.52, 0.24, 0.20, 0.55), -2)
	for b_pos in [bed1_pos, bed2_pos]:
		vm._add_sprite_prop(tex_bed, b_pos, Vector2(1.12, 1.12), -1)

	vm._spawn_decor_prop("res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/table_chairs_1.png", table_pos, Vector2(0.45, 0.45))
	vm._spawn_house_chest(hc + Vector2(0, -24), "Cofre Familiar (" + house_title + ")", fam_id)

static func _build_mixed_shop_house_visuals(vm: VillageManager, center: Vector2, title: String, tex_bed: Texture2D, tex_stall: Texture2D, bed1_pos: Vector2, bed2_pos: Vector2, table_pos: Vector2, work_pos: Vector2, fam_id: String, role_id: int = -1) -> void:
	vm._construct_solid_building(
		"mixed_" + fam_id, title, center, Vector2(128, 96), false,
		"res://assests/world/village/floor_wood_planks.png",
		"res://assests/world/village/wall_timber_h.png",
		"res://assests/world/village/wall_timber_v.png",
		42.0, 0.0, Color(0.75, 0.96, 0.68)
	)
	var tex_wall_h := vm._load_tex("res://assests/world/village/wall_timber_h.png")
	vm._add_solid_wall_segment(center + Vector2(-42, 4), Vector2(40, 6), tex_wall_h)
	vm._add_solid_wall_segment(center + Vector2(42, 4), Vector2(40, 6), tex_wall_h)

	var stall := vm._add_sprite_prop(tex_stall, work_pos + Vector2(0, 8), Vector2(1.3, 1.3), -1)
	if role_id >= 0:
		vm._register_shop_business_stall(role_id, title, fam_id, stall.global_position, stall)

	for b_pos in [bed1_pos, bed2_pos]:
		vm._add_sprite_prop(tex_bed, b_pos, Vector2(1.12, 1.12), -1)

	vm._spawn_decor_prop("res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/table_chairs_1.png", table_pos, Vector2(0.45, 0.45))
	vm._spawn_house_chest(center + Vector2(42, -26), "Cofre de la Botica Raíz Verde", fam_id)

# PASO 1: 🏥 HOSPITAL DE URGENCIAS Y ⚰️ MORGUE FORENSE (`Vector2(745, 148)`)
static func _spawn_hospital_and_morgue(vm: VillageManager) -> void:
	vm._construct_solid_building(
		"building_hospital", "🏥 Hospital de Urgencias y ⚰️ Morgue Forense",
		vm._hospital_center, Vector2(138, 96), false,
		"res://assests/world/village/floor_hospital_tile.png",
		"res://assests/world/village/wall_stone_h.png",
		"res://assests/world/village/wall_stone_v.png",
		44.0, 0.0, Color(0.68, 0.98, 0.88)
	)
	var tex_wall_h := vm._load_tex("res://assests/world/village/wall_stone_h.png")
	vm._add_solid_wall_segment(vm._hospital_center + Vector2(-46, 4), Vector2(44, 6), tex_wall_h)
	vm._add_solid_wall_segment(vm._hospital_center + Vector2(46, 4), Vector2(44, 6), tex_wall_h)

	var tex_hbed := vm._load_tex("res://assests/world/village/hospital_bed.png")
	for b_pos in [vm._hospital_bed_pos, Vector2(796, 134)]:
		vm._add_sprite_prop(tex_hbed, b_pos, Vector2(1.15, 1.15), -1)
	vm._add_prop_collider(Vector2(796, 134), Vector2(10.0, 14.0))

	vm._add_station_area("HospitalEmergencyBedArea", vm._hospital_bed_pos, 16.0, "hospital_bed")
	vm._hospital_bed_label = vm._make_station_label(vm._hospital_bed_pos + Vector2(-120, -28), "🏥 Cama de Urgencias [E: Ingresar para Cura Progresiva (-10 Oro)]")
	vm.entities_root.add_child(vm._hospital_bed_label)

	var tex_mtable := vm._load_tex("res://assests/world/village/morgue_table.png")
	var tex_corpse := vm._load_tex("res://assests/world/village/morgue_corpse_sheet.png")
	vm._morgue_corpse_sprites.clear()
	for m_pos in vm._morgue_table_positions:
		vm._add_sprite_prop(tex_mtable, m_pos, Vector2(1.15, 1.15), -1)
		vm._morgue_corpse_sprites.append(vm._add_sprite_prop(tex_corpse, m_pos, Vector2(1.15, 1.15), 0, false))
		vm._add_prop_collider(m_pos + Vector2(0.0, 4.0), Vector2(8.0, 10.0))

	vm._add_station_area("MorgueAutopsyArea", vm._morgue_table_positions[1], 24.0, "morgue_table")
	vm._morgue_label = vm._make_station_label(vm._morgue_table_positions[1] + Vector2(-125, -26), "⚰️ Morgue Forense [E: Examinar Autopsias]")
	vm.entities_root.add_child(vm._morgue_label)

	# Dr. Valen (Médico Cirujano y Forense) — Mesa de comedor propia dentro del Hospital (`Vector2(764, 128)`)
	vm._spawn_decor_prop("res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/table_chairs_1.png", Vector2(768, 124), Vector2(0.45, 0.45))
	vm._register_authority_npc(
		"NPC_Dr_Valen", "Dr. Valen", "Cirujano y Forense", VillageNPC.TradeRole.DOCTOR,
		"res://assests/world/village/villager_doctor.png",
		Vector2(756, 124), Vector2(796, 134), Vector2(768, 124),
		{"bandage": 4, "surgical_kit": 4, "herbal_poultice": 6},
		"family_hospital", "Cuerpo Médico del Valle",
		["Dr. Silvano", "Dra. Valeria", "Dr. Aurelio", "Dra. Caelia", "Dr. Mirko"]
	)

# PASO 2: 🚓 COMISARÍA, 🔒 CÁRCEL Y GUARDIAS DE LA LEY (`Vector2(915, 148)`)
static func _spawn_police_station_and_jail(vm: VillageManager) -> void:
	vm._construct_solid_building(
		"building_police", "🚓 Comisaría de Policía y 🔒 Cárcel del Valle",
		vm._police_center, Vector2(142, 96), false,
		"res://assests/world/village/floor_stone_forge.png",
		"res://assests/world/village/wall_stone_h.png",
		"res://assests/world/village/wall_stone_v.png",
		44.0, 0.0, Color(0.62, 0.85, 1.0)
	)
	var tex_bars_h := vm._load_tex("res://assests/world/village/jail_bars_h.png")
	var tex_bars_v := vm._load_tex("res://assests/world/village/jail_bars_v.png")
	var tex_bed := vm._load_tex("res://assests/world/village/tavern_bed.png")

	vm._add_solid_wall_segment(Vector2(868, 152), Vector2(42, 6), tex_bars_h, false)
	vm._add_solid_wall_segment(Vector2(962, 152), Vector2(42, 6), tex_bars_h, false)
	vm._add_solid_wall_segment(Vector2(915, 174), Vector2(6, 42), tex_bars_v, false)

	vm._jail_cell_gate_body = StaticBody2D.new()
	vm._jail_cell_gate_body.name = "JailCellGateBody"
	vm._jail_cell_gate_body.global_position = Vector2(902, 152)
	vm._jail_cell_gate_body.collision_layer = 1
	vm._jail_cell_gate_body.collision_mask = 0
	vm._jail_cell_gate_col = CollisionShape2D.new()
	var gate_rect := RectangleShape2D.new()
	gate_rect.size = Vector2(26, 6)
	vm._jail_cell_gate_col.shape = gate_rect
	vm._jail_cell_gate_col.disabled = true
	vm._jail_cell_gate_body.add_child(vm._jail_cell_gate_col)
	vm.entities_root.add_child(vm._jail_cell_gate_body)

	vm._jail_cell_gate_spr_closed = vm._add_sprite_prop(tex_bars_h, Vector2(902, 152), Vector2(0.85, 1.0), 2, false)
	vm._jail_cell_gate_spr_open = vm._add_sprite_prop(tex_bars_v, Vector2(890, 141), Vector2(1.0, 0.75), 2, true)

	for c_bed_pos in [Vector2(870, 182), Vector2(968, 178)]:
		vm._add_sprite_prop(tex_bed, c_bed_pos, Vector2.ONE, -1, true, Color(0.75, 0.78, 0.85, 1.0))

	vm._spawn_decor_prop("res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/table_chairs_1.png", Vector2(870, 126), Vector2(0.45, 0.45))
	vm._add_prop_collider(Vector2(960, 128), Vector2(20.0, 11.0))
	vm._add_prop_collider(Vector2(870, 182), Vector2(19.0, 11.0))
	vm._add_prop_collider(Vector2(968, 178), Vector2(14.0, 20.0))
	vm._add_station_area("PoliceJailCellArea", vm._jail_cell_pos, 22.0, "police_jail")
	vm._jail_label = vm._make_station_label(vm._jail_cell_pos + Vector2(-120, -28), "🚓 Celda Policial [E: Gestionar Fianza / Condena]")
	vm.entities_root.add_child(vm._jail_label)

	# Comisario Vane y Guardia Rodric (Con mesa de comedor propia en la Comisaría `Vector2(870, 126)` / `Vector2(878, 126)`)
	vm._register_authority_npc(
		"NPC_Sheriff_Vane", "Comisario Vane", "Alguacil mayor", VillageNPC.TradeRole.SHERIFF,
		"res://assests/world/village/villager_sheriff.png",
		Vector2(944, 128), Vector2(968, 178), Vector2(870, 126), {},
		"family_police", "Guardia del Valle",
		["Alguacil Thorne", "Alguacil Vance", "Alguacil Haldor", "Alguacil Lyra", "Alguacil Rourke"]
	)
	vm._register_authority_npc(
		"NPC_Guard_Rodric", "Guardia Rodric", "Oficial de Patrulla", VillageNPC.TradeRole.GUARD,
		"res://assests/world/village/villager_guard.png",
		Vector2(510, 48), Vector2(952, 178), Vector2(878, 126), {},
		"family_police", "Guardia del Valle",
		["Guardia Kaelen", "Guardia Darian", "Guardia Brenna", "Guardia Tormund", "Guardia Soren"]
	)

# PASO 2B: ☀️ CAPILLA DEL ALBA Y 🪦 CEMENTERIO PARROQUIAL (`Vector2(745, 312)`)
static func _spawn_church_and_cemetery(vm: VillageManager) -> void:
	vm._construct_solid_building(
		"building_church", "☀️ Capilla del Alba",
		vm._church_center, Vector2(132, 92), false,
		"res://assests/world/village/floor_stone_forge.png",
		"res://assests/world/village/wall_stone_h.png",
		"res://assests/world/village/wall_stone_v.png",
		42.0, 0.0, Color(0.92, 0.86, 1.0)
	)
	# Alfombra central sobria bajo el pasillo de bancos (con posición centrada y z_index = -2 para no montar sobre el tejado)
	vm._add_rect_poly(vm._church_center + Vector2(0, -4), Vector2(10, 32), Color(0.54, 0.24, 0.20, 0.62), -2)

	for pew_offset in [Vector2(-36, -16), Vector2(-36, 6), Vector2(36, -16), Vector2(36, 6)]:
		vm._add_rect_poly(vm._church_center + pew_offset, Vector2(18, 5), Color(0.46, 0.30, 0.16, 0.96), -1)
		vm._add_prop_collider(vm._church_center + pew_offset, Vector2(34.0, 8.0))

	vm._add_rect_poly(vm._church_altar_pos, Vector2(24, 8), Color(0.82, 0.78, 0.72, 1.0), -1)
	vm._add_rect_poly(vm._church_altar_pos, Vector2(14, 8), Color(0.88, 0.72, 0.24, 0.95), -1)

	vm._add_station_area("ChurchAltarArea", vm._church_altar_pos, 22.0, "church_altar")
	vm._church_altar_label = vm._make_station_label(vm._church_altar_pos + Vector2(-125, -28), "⛪ Altar y Libro de Difuntos [E: Consultar Sepulturas / Orar]")
	vm.entities_root.add_child(vm._church_altar_label)

	# G3: el sacerdote vive en la capilla (cama en la esquina noreste y mesa propia en la noroeste)
	vm._add_sprite_prop(vm._load_tex("res://assests/world/village/tavern_bed.png"), Vector2(796, 280), Vector2.ONE, -1, true, Color(0.92, 0.88, 0.80, 1.0))
	vm._spawn_decor_prop("res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/table_chairs_1.png", Vector2(696, 280), Vector2(0.45, 0.45))
	vm._register_authority_npc(
		"NPC_Priest_Anselmo", "Hermano Anselmo", "Sacerdote del Alba", VillageNPC.TradeRole.PRIEST,
		"res://assests/world/village/villager_traveler.png",
		vm._church_altar_pos + Vector2(0, -12), Vector2(796, 280), Vector2(696, 280), {},
		"family_chapel", "Capilla del Alba",
		["Hermano Teodoro", "Hermana Clara", "Hermano Bastián", "Hermana Inés", "Hermano Lucio"]
	)

	# 2. Cementerio Parroquial ampliado al Este de la Capilla (`Rect2(822, 260, 268, 168)`) con caminos en cruz, verja de hierro/piedra, árboles y 24 tumbas en filas
	var cem_rect := Rect2(Vector2(822.0, 260.0), Vector2(268.0, 168.0))
	var cem_outer_2d := vm._add_rect_poly(cem_rect.get_center(), cem_rect.size * 0.5, Color(0.20, 0.27, 0.19, 0.92), -3)
	if cem_outer_2d != null:
		cem_outer_2d.add_to_group("ranch_fence_2d")
	var cem_ground_2d := vm._add_rect_poly(cem_rect.get_center(), cem_rect.size * 0.5 - Vector2(4.0, 4.0), Color(0.25, 0.33, 0.23, 0.88), -2)
	if cem_ground_2d != null:
		cem_ground_2d.add_to_group("ranch_fence_2d")

	# Caminos interiores de piedra en cruz: camino principal Norte-Sur desde la verja (x = 888) y paseo transversal Este-Oeste (y = 344)
	var path_v_2d := vm._add_rect_poly(Vector2(888.0, 344.0), Vector2(9.0, 82.0), Color(0.50, 0.48, 0.44, 0.94), -2)
	if path_v_2d != null:
		path_v_2d.add_to_group("ranch_fence_2d")
	var path_h_2d := vm._add_rect_poly(Vector2(956.0, 344.0), Vector2(128.0, 7.0), Color(0.50, 0.48, 0.44, 0.94), -2)
	if path_h_2d != null:
		path_h_2d.add_to_group("ranch_fence_2d")
	for slab_y in range(268, 422, 12):
		var sl_v := vm._add_rect_poly(Vector2(888.0, float(slab_y)), Vector2(7.0, 4.0), Color(0.62, 0.60, 0.56, 0.92), -2)
		if sl_v != null:
			sl_v.add_to_group("ranch_fence_2d")
	for slab_x in range(832, 1082, 14):
		var sl_h := vm._add_rect_poly(Vector2(float(slab_x), 344.0), Vector2(5.0, 5.0), Color(0.62, 0.60, 0.56, 0.92), -2)
		if sl_h != null:
			sl_h.add_to_group("ranch_fence_2d")

	# Verja perimetral de hierro forjado y pilares de piedra (con choque físico salvo el paso de entrada en x = 870..906)
	var fence_border := Line2D.new()
	fence_border.width = 3.0
	fence_border.default_color = Color(0.24, 0.26, 0.32, 0.98)
	fence_border.points = PackedVector2Array([Vector2(870, 260), Vector2(822, 260), Vector2(822, 428), Vector2(1090, 428), Vector2(1090, 260), Vector2(906, 260)])
	fence_border.z_index = 0
	fence_border.add_to_group("ranch_fence_2d")
	vm.entities_root.add_child(fence_border)
	# Rejilla de barrotes verticales en el muro norte y sur en 2D
	for fx in range(826, 1088, 8):
		if fx < 870 or fx > 906:
			var bar_n := vm._add_rect_poly(Vector2(float(fx), 260.0), Vector2(1.0, 3.5), Color(0.18, 0.20, 0.25, 0.95), 0)
			if bar_n != null:
				bar_n.add_to_group("ranch_fence_2d")
		var bar_s := vm._add_rect_poly(Vector2(float(fx), 428.0), Vector2(1.0, 3.5), Color(0.18, 0.20, 0.25, 0.95), 0)
		if bar_s != null:
			bar_s.add_to_group("ranch_fence_2d")
	for pil_pos in [Vector2(822, 260), Vector2(870, 260), Vector2(906, 260), Vector2(998, 260), Vector2(1090, 260), Vector2(822, 344), Vector2(1090, 344), Vector2(822, 428), Vector2(956, 428), Vector2(1090, 428)]:
		var pil_p := vm._add_rect_poly(pil_pos, Vector2(3.5, 4.5), Color(0.52, 0.54, 0.58, 0.98), 0)
		if pil_p != null:
			pil_p.add_to_group("ranch_fence_2d")
	# Colisión física de la verja del cementerio (dejando libre la puerta norte en 870..906)
	vm._add_prop_collider(Vector2(846.0, 260.0), Vector2(48.0, 4.0))
	vm._add_prop_collider(Vector2(998.0, 260.0), Vector2(184.0, 4.0))
	vm._add_prop_collider(Vector2(956.0, 428.0), Vector2(268.0, 4.0))
	vm._add_prop_collider(Vector2(822.0, 344.0), Vector2(4.0, 168.0))
	vm._add_prop_collider(Vector2(1090.0, 344.0), Vector2(4.0, 168.0))

	vm._add_title_label(Vector2(830, 238), Vector2(250, 16), "🪦 Cementerio Parroquial del Alba", Color(0.82, 0.86, 0.96), 8)
	vm._add_station_area("CemeteryGateArea", vm._cemetery_gate_pos, 24.0, "cemetery_gate")
	vm._cemetery_label = vm._make_station_label(vm._cemetery_gate_pos + Vector2(-125, -26), "🪦 Cementerio Parroquial [E: Inspeccionar Sepulturas]")
	vm.entities_root.add_child(vm._cemetery_label)

	# 4 filas ordenadas × 6 columnas = 24 tumbas completas con túmulo de tierra, bordillo de piedra, lápida y cruz tallada en 2D
	vm._cemetery_grave_positions.clear()
	var row_ys: Array[float] = [286.0, 316.0, 372.0, 402.0]
	var col_xs: Array[float] = [852.0, 924.0, 954.0, 984.0, 1014.0, 1044.0]
	var g_idx_2d: int = 0
	for ry in row_ys:
		for cx in col_xs:
			var g_pos := Vector2(cx, ry)
			vm._cemetery_grave_positions.append(g_pos)
			# Bordillo de piedra y túmulo de tierra
			var curb_2d := vm._add_rect_poly(g_pos + Vector2(0, 2), Vector2(7.0, 7.5), Color(0.42, 0.44, 0.48, 0.92), -2)
			var mound_2d := vm._add_rect_poly(g_pos + Vector2(0, 2.5), Vector2(5.5, 6.0), Color(0.36, 0.26, 0.18, 0.95), -1)
			# Lápida vertical en la cabecera norte de cada tumba + cruz grabada
			var stone_col := Color(0.68, 0.71, 0.76, 0.98) if (g_idx_2d % 2 == 0) else Color(0.58, 0.61, 0.66, 0.98)
			var head_2d := vm._add_rect_poly(g_pos + Vector2(0, -5.5), Vector2(5.0, 3.8), stone_col, -1)
			var head_top_2d := vm._add_rect_poly(g_pos + Vector2(0, -9.8), Vector2(3.4, 1.4), stone_col, -1)
			var cr_v := vm._add_rect_poly(g_pos + Vector2(0, -6.2), Vector2(0.8, 2.8), Color(0.30, 0.32, 0.38, 0.95), -1)
			var cr_h := vm._add_rect_poly(g_pos + Vector2(0, -7.0), Vector2(2.2, 0.8), Color(0.30, 0.32, 0.38, 0.95), -1)
			for p_item in [curb_2d, mound_2d, head_2d, head_top_2d, cr_v, cr_h]:
				if p_item != null:
					p_item.add_to_group("ranch_fence_2d")
			if (g_idx_2d % 3) == 0:
				var flw := vm._add_rect_poly(g_pos + Vector2(2.5, 3.5), Vector2(1.6, 1.4), Color(0.92, 0.80, 0.32, 0.92), -1)
				if flw != null:
					flw.add_to_group("ranch_fence_2d")
			vm._add_prop_collider(g_pos, Vector2(10.0, 10.0))
			g_idx_2d += 1

	# Árboles (pinos/cipreses) flanqueando el perímetro del cementerio en 2D y 3D
	var cem_tree_tex := vm._load_tex("res://assests/Comprados/Epic RPG World - The Village V2.1/tilesets and props/props-sprites/pine-tree_0.png")
	for c_tp in [Vector2(834.0, 272.0), Vector2(1076.0, 272.0), Vector2(1076.0, 344.0), Vector2(834.0, 416.0), Vector2(968.0, 418.0), Vector2(1076.0, 416.0)]:
		vm._add_sprite_prop(cem_tree_tex, c_tp, Vector2(0.62, 0.62), 0)

# ==============================================================================
# PASO 5: 📋 TABLÓN DE ENCARGOS EN LA PLAZA CENTRAL (`Vector2(465, 24)`)
# ==============================================================================
static func _spawn_notice_board_in_plaza(vm: VillageManager) -> void:
	vm._add_sprite_prop(vm._load_tex("res://assests/Comprados/Epic RPG World - The Village V2.1/tilesets and props/props-sprites/questboard_1.png"), vm._notice_board_pos, Vector2(0.65, 0.65), -1)
	vm._add_station_area("PlazaNoticeBoardArea", vm._notice_board_pos, 14.0, "notice_board")
	vm._notice_board_label = vm._make_station_label(vm._notice_board_pos + Vector2(-120, -28), "📋 Tablón de Encargos y Recompensas [E: Ver Misiones]")
	vm.entities_root.add_child(vm._notice_board_label)

# ==============================================================================
# PASO 10: ⚡ FAROLAS ELÉCTRICAS EN LAS CALLES DEL PUEBLO (`lamp-post1.png`)
# ==============================================================================
static func _spawn_electric_streetlights(vm: VillageManager) -> void:
	var lamp_tex := vm._load_tex("res://assests/Comprados/Epic RPG World - The Village V2.1/tilesets and props/props-sprites/lamp-post1.png")
	var lamp_positions: Array[Vector2] = [Vector2(215, 36), Vector2(392, 10), Vector2(534, 10), Vector2(396, -118), Vector2(692, 88), Vector2(862, 88)]
	for l_pos in lamp_positions:
		var l_spr := vm._add_sprite_prop(lamp_tex, l_pos, Vector2(0.75, 0.75), 1)
		var glow := vm._add_poly(PackedVector2Array([Vector2(-26, -18), Vector2(26, -18), Vector2(34, 18), Vector2(-34, 18)]), Color(1.0, 0.92, 0.55, 0.22), -1, l_pos)
		glow.visible = false
		vm.streetlights.append({"sprite": l_spr, "glow": glow, "pos": l_pos})

static func _spawn_farm_well_and_compost(vm: VillageManager) -> void:
	var well_tex := vm._load_tex("res://assests/world/village/water_well.png")
	vm._well_positions = [vm._well_pos, vm._tavern_well_pos, vm._plaza_well_pos]

	vm._add_sprite_prop(well_tex, vm._well_pos, Vector2(1.25, 1.25), 0)
	vm._add_station_area("WaterWellArea", vm._well_pos, 24.0, "well")
	vm._well_label = vm._make_station_label(vm._well_pos + Vector2(-130, -28), "🪣 Pozo de la Granja [E: Llenar Recipiente / Lavar Heridas y Sangre]")
	vm.entities_root.add_child(vm._well_label)

	# Pozo en el Patio Lateral de la Gran Posada ('El Jabalí Dorado')
	vm._add_sprite_prop(well_tex, vm._tavern_well_pos, Vector2(1.25, 1.25), 0)
	vm._add_station_area("TavernWaterWellArea", vm._tavern_well_pos, 24.0, "well")
	vm._tavern_well_label = vm._make_station_label(vm._tavern_well_pos + Vector2(-135, -28), "🪣 Pozo de la Posada [E: Llenar Recipiente / Lavar Heridas y Sangre]")
	vm.entities_root.add_child(vm._tavern_well_label)

	# Pozo en la Plaza Central del Pueblo
	vm._add_sprite_prop(well_tex, vm._plaza_well_pos, Vector2(1.25, 1.25), 0)
	vm._add_station_area("PlazaWaterWellArea", vm._plaza_well_pos, 24.0, "well")
	vm._plaza_well_label = vm._make_station_label(vm._plaza_well_pos + Vector2(-135, -28), "🪣 Pozo de la Plaza Central [E: Llenar Recipiente / Lavar Heridas y Sangre]")
	vm.entities_root.add_child(vm._plaza_well_label)

	vm._compost_sprite = vm._add_sprite_prop(vm._load_tex("res://assests/world/village/compost_bin.png"), vm._compost_pos, Vector2(1.25, 1.25), 0)
	vm._compost_area = vm._add_station_area("CompostBinArea", vm._compost_pos, 16.0, "compost")
	vm._compost_label = vm._make_station_label(vm._compost_pos + Vector2(-115, -28), "♻️ Compostador [E: Crear Abono con Hierba/Hongo]")
	vm.entities_root.add_child(vm._compost_label)
	vm.set_camp_farm_enabled(false)
