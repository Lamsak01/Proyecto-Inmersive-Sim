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
			work_pos = sc + Vector2(-27, -25)
			bed1_pos = sc + Vector2(-42, 26)
			bed2_pos = sc + Vector2(42, 26)
			table_pos = sc + Vector2(0, 28)
			kin_work_pos = sc + Vector2(24, -14)
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
	vm._add_prop_collider(work_pos + Vector2(0, 8), Vector2(18.0, 8.5))
	vm._add_prop_collider(center + Vector2(35, -14), Vector2(11.0, 11.0))

	for b_pos in [bed1_pos, bed2_pos]:
		vm._add_sprite_prop(tex_bed, b_pos, Vector2(1.12, 1.12), -1)
		vm._add_prop_collider(b_pos, Vector2(12.0, 17.0))

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

	for pew_offset in [Vector2(-29, -14), Vector2(-29, 0), Vector2(29, -14), Vector2(29, 0)]:
		vm._add_rect_poly(vm._church_center + pew_offset, Vector2(12, 4), Color(0.46, 0.30, 0.16, 0.96), -1)
	for pew_col_x in [-31.0, 31.0]:
		vm._add_prop_collider(vm._church_center + Vector2(pew_col_x, -4.0), Vector2(18.0, 4.0))

	vm._add_rect_poly(vm._church_altar_pos, Vector2(24, 8), Color(0.82, 0.78, 0.72, 1.0), -1)
	vm._add_rect_poly(vm._church_altar_pos, Vector2(14, 8), Color(0.88, 0.72, 0.24, 0.95), -1)
	vm._add_prop_collider(vm._church_altar_pos + Vector2(0, 8), Vector2(18.0, 4.0))

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

	# Río de norte a sur, arroyo del bosque norte, Claro del Caso I y Molino Viejo Abandonado
	_spawn_river_arroyo_and_abandoned_mill(vm)

static func _spawn_river_arroyo_and_abandoned_mill(vm: VillageManager) -> void:
	# 1. Sendero forestal que sube desde la Calle Norte junto al arroyo hasta el Claro y el Molino Viejo
	var trail_pts: Array[Vector2] = [
		Vector2(138.0, -351.0),
		Vector2(126.0, -435.0),
		Vector2(218.0, -545.0),
		Vector2(118.0, -695.0),
		Vector2(114.0, -785.0),
		Vector2(138.0, -860.0),
		Vector2(142.0, -945.0),
		Vector2(168.0, -996.0),
		Vector2(188.0, -1014.0),
	]
	for ti in range(trail_pts.size() - 1):
		var p_a: Vector2 = trail_pts[ti]
		var p_b: Vector2 = trail_pts[ti + 1]
		var dir_t: Vector2 = (p_b - p_a).normalized()
		var n_t: Vector2 = Vector2(-dir_t.y, dir_t.x) * 9.0
		var seg_poly := vm._add_poly(PackedVector2Array([
			p_a - n_t, p_b - n_t, p_b + n_t, p_a + n_t
		]), Color(0.46, 0.36, 0.24, 0.86), -3)
		if seg_poly != null:
			seg_poly.add_to_group("ranch_fence_2d")

	# 2. Orillas naturales irregulares, barro rojo del molino, barro pardo del claro y cauce de agua 2D
	var left_bank_outer := PackedVector2Array()
	var right_bank_outer := PackedVector2Array()
	var left_water := PackedVector2Array()
	var right_water := PackedVector2Array()
	var left_deep := PackedVector2Array()
	var right_deep := PackedVector2Array()
	var sample_y: float = -1180.0
	while sample_y <= 940.0:
		var banks: Vector2 = FishingSpot.river_banks_at(sample_y)
		var town_bank_boost: float = lerpf(1.0, 2.2, smoothstep(-520.0, -180.0, sample_y) * (1.0 - smoothstep(260.0, 390.0, sample_y)))
		var bank_pad_l: float = (5.5 + sin(sample_y * 0.043) * 2.2 + cos(sample_y * 0.089) * 1.4) * town_bank_boost
		var bank_pad_r: float = (5.5 + cos(sample_y * 0.039) * 2.2 + sin(sample_y * 0.083) * 1.4) * town_bank_boost
		left_bank_outer.append(Vector2(banks.x - bank_pad_l, sample_y))
		right_bank_outer.append(Vector2(banks.y + bank_pad_r, sample_y))
		left_water.append(Vector2(banks.x, sample_y))
		right_water.append(Vector2(banks.y, sample_y))
		var hw_d: float = (banks.y - banks.x) * 0.30
		var cx_d: float = (banks.x + banks.y) * 0.5
		left_deep.append(Vector2(cx_d - hw_d, sample_y))
		right_deep.append(Vector2(cx_d + hw_d, sample_y))
		sample_y += 12.0

	var bank_poly_pts := PackedVector2Array()
	for p in left_bank_outer:
		bank_poly_pts.append(p)
	for i in range(right_bank_outer.size() - 1, -1, -1):
		bank_poly_pts.append(right_bank_outer[i])
	var bank_2d := vm._add_poly(bank_poly_pts, Color(0.44, 0.35, 0.24, 0.90), -3)
	if bank_2d != null:
		bank_2d.add_to_group("ranch_fence_2d")

	# Orilla de barro rojo / arcilla junto al Molino Viejo Abandonado (y = -1135..-985)
	var red_mud_pts := PackedVector2Array([
		Vector2(94.0, -1135.0), Vector2(158.0, -1132.0), Vector2(168.0, -1085.0),
		Vector2(174.0, -1012.0), Vector2(156.0, -985.0), Vector2(94.0, -988.0)
	])
	var red_mud_2d := vm._add_poly(red_mud_pts, Color(0.76, 0.22, 0.14, 0.96), -2)
	if red_mud_2d != null:
		red_mud_2d.add_to_group("ranch_fence_2d")

	# Orilla de barro pardo y claro del bosque donde aparece el cuerpo del Caso I (y = -905..-818)
	var clearing_grass_pts := PackedVector2Array([
		Vector2(110.0, -905.0), Vector2(166.0, -900.0), Vector2(176.0, -860.0),
		Vector2(168.0, -818.0), Vector2(110.0, -820.0)
	])
	var clearing_2d := vm._add_poly(clearing_grass_pts, Color(0.34, 0.42, 0.24, 0.88), -3)
	if clearing_2d != null:
		clearing_2d.add_to_group("ranch_fence_2d")
	var brown_mud_pts := PackedVector2Array([
		Vector2(88.0, -904.0), Vector2(136.0, -900.0), Vector2(142.0, -860.0),
		Vector2(135.0, -820.0), Vector2(88.0, -822.0)
	])
	var brown_mud_2d := vm._add_poly(brown_mud_pts, Color(0.38, 0.26, 0.16, 0.94), -2)
	if brown_mud_2d != null:
		brown_mud_2d.add_to_group("ranch_fence_2d")

	var water_poly_pts := PackedVector2Array()
	for p in left_water:
		water_poly_pts.append(p)
	for i in range(right_water.size() - 1, -1, -1):
		water_poly_pts.append(right_water[i])
	var water_2d := vm._add_poly(water_poly_pts, Color(0.14, 0.42, 0.66, 0.95), -2)
	if water_2d != null:
		water_2d.add_to_group("ranch_fence_2d")

	var deep_poly_pts := PackedVector2Array()
	for p in left_deep:
		deep_poly_pts.append(p)
	for i in range(right_deep.size() - 1, -1, -1):
		deep_poly_pts.append(right_deep[i])
	var deep_2d := vm._add_poly(deep_poly_pts, Color(0.08, 0.26, 0.46, 0.88), -2)
	if deep_2d != null:
		deep_2d.add_to_group("ranch_fence_2d")

	# 3. Colisión física real del agua del río y arroyo (StaticBody2D, collision_layer = 1)
	# Dividida en los 6 tramos húmedos entre los 5 puentes y vados para que solo se cruce por ellos
	var wet_segments: Array[Vector2] = [
		Vector2(-1180.0, -877.0),
		Vector2(-843.0, -368.0),
		Vector2(-334.0, 29.0),
		Vector2(71.0, 355.0),
		Vector2(389.0, 753.0),
		Vector2(791.0, 940.0),
	]
	var river_col_body := StaticBody2D.new()
	river_col_body.name = "RiverWaterCollisionBody"
	river_col_body.collision_layer = 1
	river_col_body.collision_mask = 0
	for seg in wet_segments:
		var seg_l := PackedVector2Array()
		var seg_r := PackedVector2Array()
		var sy: float = seg.x
		while sy <= seg.y + 0.01:
			var b: Vector2 = FishingSpot.river_banks_at(sy)
			seg_l.append(Vector2(b.x + 1.2, sy))
			seg_r.append(Vector2(b.y - 1.2, sy))
			if sy >= seg.y:
				break
			sy = minf(sy + 14.0, seg.y)
		var c_pts := PackedVector2Array()
		for lp in seg_l:
			c_pts.append(lp)
		for ri in range(seg_r.size() - 1, -1, -1):
			c_pts.append(seg_r[ri])
		var c_poly := CollisionPolygon2D.new()
		c_poly.polygon = c_pts
		river_col_body.add_child(c_poly)
	vm.entities_root.add_child(river_col_body)

	# 4. Puentes y vados en 2D + pretiles de colisión sobre el tramo de agua para no caer al río
	for cr in FishingSpot.RIVER_CROSSINGS:
		var c_pos: Vector2 = cr["pos"]
		var c_hy: float = float(cr["half_y"])
		var b_at: Vector2 = FishingSpot.river_banks_at(c_pos.y)
		var water_span: float = maxf(18.0, b_at.y - b_at.x)
		var deck_w: float = water_span + 18.0
		var deck_cx: float = (b_at.x + b_at.y) * 0.5
		var c_id: String = String(cr["id"])
		if c_id == "old_bridge":
			# Puente Viejo de piedra y madera en el centro del pueblo (Calle Mayor)
			var arch_p := vm._add_rect_poly(Vector2(deck_cx, c_pos.y), Vector2(deck_w + 6.0, c_hy * 2.0 + 4.0), Color(0.46, 0.45, 0.43, 0.98), -1)
			var deck_p := vm._add_rect_poly(Vector2(deck_cx, c_pos.y), Vector2(deck_w, c_hy * 2.0 - 2.0), Color(0.42, 0.30, 0.19, 0.98), -1)
			var rail_n := vm._add_rect_poly(Vector2(deck_cx, c_pos.y - c_hy), Vector2(deck_w + 4.0, 4.0), Color(0.56, 0.54, 0.50, 0.98), 0)
			var rail_s := vm._add_rect_poly(Vector2(deck_cx, c_pos.y + c_hy), Vector2(deck_w + 4.0, 4.0), Color(0.56, 0.54, 0.50, 0.98), 0)
			for bp in [arch_p, deck_p, rail_n, rail_s]:
				if bp != null:
					bp.add_to_group("ranch_fence_2d")
			vm._add_prop_collider(Vector2(deck_cx, c_pos.y - c_hy - 1.5), Vector2(water_span, 3.0))
			vm._add_prop_collider(Vector2(deck_cx, c_pos.y + c_hy + 1.5), Vector2(water_span, 3.0))
			vm._add_title_label(Vector2(deck_cx - 72.0, c_pos.y - 34.0), Vector2(144.0, 16.0), "🌉 Puente Viejo", Color(0.95, 0.88, 0.72), 8)
		elif c_id == "bridge_north" or c_id == "south_fields_bridge":
			var b_deck := vm._add_rect_poly(Vector2(deck_cx, c_pos.y), Vector2(deck_w, c_hy * 2.0), Color(0.46, 0.33, 0.20, 0.96), -1)
			var b_rn := vm._add_rect_poly(Vector2(deck_cx, c_pos.y - c_hy), Vector2(deck_w, 3.0), Color(0.32, 0.22, 0.13, 0.98), 0)
			var b_rs := vm._add_rect_poly(Vector2(deck_cx, c_pos.y + c_hy), Vector2(deck_w, 3.0), Color(0.32, 0.22, 0.13, 0.98), 0)
			for bp in [b_deck, b_rn, b_rs]:
				if bp != null:
					bp.add_to_group("ranch_fence_2d")
			vm._add_prop_collider(Vector2(deck_cx, c_pos.y - c_hy - 1.5), Vector2(water_span, 3.0))
			vm._add_prop_collider(Vector2(deck_cx, c_pos.y + c_hy + 1.5), Vector2(water_span, 3.0))
		else:
			# Vados de piedras planas (Claro del Arroyo y Bosque del Sur)
			var st_x: float = b_at.x + 3.0
			var st_idx: int = 0
			while st_x <= b_at.y - 2.0:
				var st_p := vm._add_rect_poly(Vector2(st_x, c_pos.y + float(st_idx % 2) * 2.0), Vector2(5.2, 7.5), Color(0.55, 0.54, 0.50, 0.95), -1)
				if st_p != null:
					st_p.add_to_group("ranch_fence_2d")
				st_x += 6.2
				st_idx += 1

	# 5. Punto de pesca en la orilla este del río dentro del pueblo (y = 188)
	var fish_banks: Vector2 = FishingSpot.river_banks_at(188.0)
	var river_fish_spot := FishingSpot.new()
	river_fish_spot.name = "RiverFishingSpot"
	river_fish_spot.is_river_spot = true
	river_fish_spot.spot_title = "🎣 Ribera de Pesca del Río"
	river_fish_spot.dock_pos = Vector2(18.0, 0.0)
	river_fish_spot.position = Vector2(fish_banks.y - 10.0, 188.0)
	vm.entities_root.add_child(river_fish_spot)

	# 6. Claro del Arroyo (Caso I) — etiqueta y área de inspección del lugar
	vm._add_title_label(Vector2(68.0, -902.0), Vector2(160.0, 16.0), "🌲 Claro del Arroyo", Color(0.84, 0.92, 0.78), 8)
	vm._add_station_area("Case1ClearingArea", FishingSpot.CASE1_CLEARING_POS, 22.0, "case1_clearing")
	var clearing_lbl := vm._make_station_label(FishingSpot.CASE1_CLEARING_POS + Vector2(-120.0, -26.0), "🌲 Orilla de Barro Pardo del Arroyo [E: Examinar Claro]")
	vm.entities_root.add_child(clearing_lbl)
	vm._extra_station_labels.append([clearing_lbl, FishingSpot.CASE1_CLEARING_POS])

	# 7. Molino Viejo Abandonado río arriba del claro (`Vector2(188, -1060)`, tamaño `Vector2(124, 92)`)
	var mill_center: Vector2 = FishingSpot.ABANDONED_MILL_CENTER
	var mill_size: Vector2 = FishingSpot.ABANDONED_MILL_SIZE
	vm._construct_solid_building(
		"building_abandoned_mill",
		"🏚️ Molino Viejo Abandonado",
		mill_center,
		mill_size,
		true,
		"res://assests/world/village/floor_wood_planks.png",
		"res://assests/world/village/wall_stone_h.png",
		"res://assests/world/village/wall_stone_v.png",
		42.0,
		0.0,
		Color(0.82, 0.66, 0.52)
	)
	# Rueda de molino parada en el exterior oeste (sobre el cauce del arroyo) en 2D
	var wheel_2d := vm._add_rect_poly(Vector2(mill_center.x - mill_size.x * 0.5 - 5.0, mill_center.y), Vector2(8.0, 34.0), Color(0.28, 0.19, 0.12, 0.98), 0)
	if wheel_2d != null:
		wheel_2d.add_to_group("ranch_fence_2d")

	# Interior del Molino Viejo Abandonado (4 pistas/elementos del Caso I, dejando libre el pasillo central):
	# (a) Pajar con paja seca (esquina noroeste: Vector2(152, -1084))
	var straw_pos := Vector2(152.0, -1084.0)
	var straw_2d := vm._add_rect_poly(straw_pos, Vector2(30.0, 22.0), Color(0.76, 0.64, 0.28, 0.95), -1)
	if straw_2d != null:
		straw_2d.add_to_group("ranch_fence_2d")
	vm._add_prop_collider(straw_pos, Vector2(24.0, 16.0))
	vm._add_station_area("MillHayloftArea", straw_pos, 22.0, "mill_hayloft")
	var straw_lbl := vm._make_station_label(straw_pos + Vector2(-105.0, -24.0), "🌾 Pajar con Paja Seca [E: Examinar]")
	vm.entities_root.add_child(straw_lbl)
	vm._extra_station_labels.append([straw_lbl, straw_pos])

	# (b) Hogar viejo con ceniza de carbón (esquina noreste: Vector2(224, -1086))
	var hearth_pos := Vector2(224.0, -1086.0)
	var hearth_2d := vm._add_rect_poly(hearth_pos, Vector2(28.0, 18.0), Color(0.32, 0.31, 0.30, 0.98), -1)
	var ash_2d := vm._add_rect_poly(hearth_pos + Vector2(0.0, 2.0), Vector2(16.0, 10.0), Color(0.14, 0.14, 0.15, 0.98), -1)
	for hp in [hearth_2d, ash_2d]:
		if hp != null:
			hp.add_to_group("ranch_fence_2d")
	vm._add_prop_collider(hearth_pos, Vector2(24.0, 14.0))
	vm._add_station_area("MillHearthArea", hearth_pos, 22.0, "mill_hearth")
	var hearth_lbl := vm._make_station_label(hearth_pos + Vector2(-115.0, -24.0), "🪨 Hogar Viejo con Ceniza de Carbón [E: Examinar]")
	vm.entities_root.add_child(hearth_lbl)
	vm._extra_station_labels.append([hearth_lbl, hearth_pos])

	# (c) Cordel de cáñamo encerado (esquina suroeste: Vector2(150, -1040))
	var cord_pos := Vector2(150.0, -1040.0)
	var cord_bench_2d := vm._add_rect_poly(cord_pos, Vector2(22.0, 16.0), Color(0.42, 0.29, 0.18, 0.96), -1)
	var cord_coil_2d := vm._add_rect_poly(cord_pos, Vector2(9.0, 9.0), Color(0.68, 0.58, 0.36, 0.98), -1)
	for cp in [cord_bench_2d, cord_coil_2d]:
		if cp != null:
			cp.add_to_group("ranch_fence_2d")
	vm._add_prop_collider(cord_pos, Vector2(18.0, 12.0))
	vm._add_station_area("MillHempCordArea", cord_pos, 22.0, "mill_hemp_cord")
	var cord_lbl := vm._make_station_label(cord_pos + Vector2(-110.0, -24.0), "🪢 Cordel de Cáñamo Encerado [E: Examinar]")
	vm.entities_root.add_child(cord_lbl)
	vm._extra_station_labels.append([cord_lbl, cord_pos])

	# (d) Mesa con papel («Lista de nombres — texto pendiente del autor») (sureste: Vector2(218, -1050))
	var table_pos := Vector2(218.0, -1050.0)
	var table_2d := vm._add_rect_poly(table_pos, Vector2(26.0, 18.0), Color(0.45, 0.31, 0.19, 0.98), -1)
	var paper_2d := vm._add_rect_poly(table_pos + Vector2(-2.0, -1.0), Vector2(10.0, 7.0), Color(0.90, 0.85, 0.72, 0.98), -1)
	for tp in [table_2d, paper_2d]:
		if tp != null:
			tp.add_to_group("ranch_fence_2d")
	vm._add_prop_collider(table_pos, Vector2(22.0, 14.0))
	vm._add_station_area("MillPaperTableArea", table_pos, 24.0, "mill_table_paper")
	var paper_lbl := vm._make_station_label(table_pos + Vector2(-135.0, -26.0), "📄 Mesa con Papel: «Lista de nombres — texto pendiente del autor» [E: Leer]")
	vm.entities_root.add_child(paper_lbl)
	vm._extra_station_labels.append([paper_lbl, table_pos])

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
