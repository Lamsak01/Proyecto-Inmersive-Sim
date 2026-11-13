@tool
extends RefCounted
const Marca = preload("res://mapa/marca.gd")
const EdificioEditor = preload("res://mapa/edificio.gd")
const Cartel = preload("res://mapa/cartel.gd")
const Sitio = preload("res://mapa/sitio.gd")
## Farolas de las calles (2026-11-12): cruces «farola_calle_N» del mapa (Sitios), ya en el mundo y movibles en el editor.
const SERIE_FAROLAS_CALLE := "farola_calle"
const ObjetoEditor = preload("res://mapa/objeto.gd")
const SITIO_BARRO_ROJO := "barro_rojo_molino" ## orilla de arcilla roja junto al molino viejo (pista del Caso I)
const OBJETO_FAROLA := "farola_%d"  ## las 6 farolas de la plaza que son piezas de «Objetos» (Farola_1…6)
const FAROLAS_OBJETO: int = 6
## Postes indicadores: cruces «poste_N» del mapa (Sitios), con su giro; el texto de cada tabla, en el mismo orden.
const SERIE_POSTES := "poste"
const TEXTOS_POSTES: Array[String] = [
	"Campamento y Lago del Oeste · Camino a la Aldea",
	"Oeste Lejano: Llanura al norte, Ciénaga al sur",
	"Sendero al Bosque Profundo",
	"Al este: Hospital, Morgue, Comisaría y Cárcel",
	"Llanura Salvaje · Cuidado: bandidos",
	"Ciénaga del Suroeste · Cuidado: bandidos",
]

## Construcción inicial del pueblo (caminos, edificios y mobiliario). Extraído de VillageManager.gd:
## cada función recibe al VillageManager como primer parámetro (`vm`) y solo se ejecuta al montar el mundo.

# ==============================================================================
# RED DE CAMINOS Y BIOMAS EXTERIORES
# ==============================================================================
## Postes indicadores de los caminos (el suelo de caminos, plaza, llanura y ciénaga es 3D): su dibujo es 3D
## (WorldStageProps3D, «sign») con el texto escrito en la tabla (mapa/cartel.gd).
static func _spawn_signposts(vm: VillageManager) -> void:
	var sitios: Array[Vector2] = Sitio.serie(SERIE_POSTES)
	if sitios.size() != TEXTOS_POSTES.size():
		push_error("POSTES: hay %d cruces «poste_N» y %d textos" % [sitios.size(), TEXTOS_POSTES.size()])
	for i in range(mini(sitios.size(), TEXTOS_POSTES.size())):
		var giro: float = Sitio.giro(Sitio.SERIE % [SERIE_POSTES, i + 1])
		vm.add_marca_3d_mundo("sign", sitios[i], giro).set_meta(Cartel.META_TEXTO, TEXTOS_POSTES[i])

# EDIFICIO MIXTO #1: GRAN POSADA DE 2 PLANTAS, TABERNA, CASINO Y SÓTANO DE PELEAS
static func _spawn_tavern_and_rooms(vm: VillageManager) -> void:
	preload("res://scripts/systems/VillageTavern.gd").setup_world(vm)

# 4 LOCALES COMERCIALES + 4 CASAS RESIDENCIALES + BOTICA-VIVIENDA MIXTA
static func _spawn_five_family_houses_and_trades(vm: VillageManager) -> void:
	var tex_family := vm._load_tex("res://assests/world/village/villager_traveler.png")

	vm.trade_configs = {
		VillageNPC.TradeRole.BLACKSMITH: {
			"family_id": "family_smith", "family_name": "Familia Yunque Gris",
			"shop_title": "⚒️ Herrería y Armería 'Yunque Gris'", "shop_center": Vector2(335, -36),
			"is_mixed_building": false,
			"house_title": "🏠 Residencia Familia Yunque Gris", "house_center": Vector2(745, -195),
			"name": "Thoran", "title": "Maestro Herrero y Armero",
			"tex": vm._load_tex("res://assests/world/village/villager_smith.png"),
			"stock": {"iron_ore": 4, "repair_kit": 3},
			"kin_name": "Kael", "kin_title": "Hijo y Aprendiz de Forja"
		},
		VillageNPC.TradeRole.BUTCHER: {
			"family_id": "family_butcher", "family_name": "Familia Colmillo",
			"shop_title": "🥩 Carnicería y Peletería 'El Colmillo'", "shop_center": Vector2(585, -36),
			"is_mixed_building": false,
			"house_title": "🏠 Residencia Familia Colmillo", "house_center": Vector2(905, -195),
			"name": "Garrick", "title": "Maestro Carnicero",
			"tex": vm._load_tex("res://assests/world/village/villager_butcher.png"),
			"stock": {"cooked_meat": 5, "leather": 4, "roasted_chicken": 2},
			"kin_name": "Lina", "kin_title": "Hermana y Curtidora"
		},
		VillageNPC.TradeRole.CARPENTER: {
			"family_id": "family_carpenter", "family_name": "Familia Roble Viejo",
			"shop_title": "🪚 Carpintería y Aserradero 'Roble Viejo'", "shop_center": Vector2(585, 148),
			"is_mixed_building": false,
			"house_title": "🏠 Residencia Familia Roble Viejo", "house_center": Vector2(745, -36),
			"name": "Bram", "title": "Maestro Carpintero",
			"tex": vm._load_tex("res://assests/world/village/villager_carpenter.png"),
			"stock": {"repair_kit": 5, "wood": 8, "copper_coil": 2, "empty_flask": 3},
			"kin_name": "Mila", "kin_title": "Hermana y Ebanista"
		},
		VillageNPC.TradeRole.FISHMONGER: {
			"family_id": "family_fishmonger", "family_name": "Familia Aguas Claras",
			"shop_title": "🐟 Pescadería y Molino 'Aguas Claras'", "shop_center": Vector2(465, 148),
			"is_mixed_building": false,
			"house_title": "🏠 Residencia Familia Aguas Claras", "house_center": Vector2(905, -36),
			"name": "Marlo", "title": "Pescador y Molinero",
			"tex": vm._load_tex("res://assests/world/village/villager_fishmonger.png"),
			"stock": {"bread": 6, "fertilizer": 5, "cooked_fish": 4},
			"kin_name": "Nora", "kin_title": "Hija y Redera"
		},
		VillageNPC.TradeRole.HERBALIST: {
			"family_id": "family_herbalist", "family_name": "Familia Raíz Verde",
			"shop_title": "🌿 Botica y Casa-Jardín 'Raíz Verde'", "shop_center": Vector2(325, 155),
			"is_mixed_building": true,
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

		# Dónde trabaja, duerme y come la familia lo dicen las marcas de sus edificios (mapa/marca.gd), no números aquí
		var shop_id: String = ("mixed_" if is_mixed else "shop_") + fam_id
		var house_id: String = ("mixed_" if is_mixed else "house_") + fam_id
		var work_pos: Vector2 = Marca.mundo(shop_id, Marca.TRABAJO)
		var kin_work_pos: Vector2 = Marca.mundo(shop_id, Marca.TRABAJO_FAMILIAR)
		var bed1_pos: Vector2 = Marca.mundo(house_id, Marca.CAMA_1)
		var bed2_pos: Vector2 = Marca.mundo(house_id, Marca.CAMA_2)
		var table_pos: Vector2 = Marca.mundo(house_id, Marca.MESA)

		if is_mixed:
			_build_mixed_shop_house_visuals(vm, sc, str(cfg["shop_title"]), fam_id, int(role_key))
		else:
			var is_smithy: bool = (role_key == VillageNPC.TradeRole.BLACKSMITH)
			_build_enclosed_shop_visuals(vm, sc, str(cfg["shop_title"]), is_smithy, fam_id, int(role_key))
			_build_residential_house_visuals(vm, hc, str(cfg["house_title"]), fam_id)

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

static func _build_enclosed_shop_visuals(vm: VillageManager, sc: Vector2, shop_title: String, is_blacksmith: bool, fam_id: String, role_id: int = -1) -> void:
	var floor_p: String = "res://assests/world/village/floor_stone_forge.png" if is_blacksmith else "res://assests/world/village/floor_wood_planks.png"
	var wall_h_p: String = "res://assests/world/village/wall_stone_h.png" if is_blacksmith else "res://assests/world/village/wall_timber_h.png"
	var wall_v_p: String = "res://assests/world/village/wall_stone_v.png" if is_blacksmith else "res://assests/world/village/wall_timber_v.png"

	vm._construct_solid_building("shop_" + fam_id, shop_title, sc,
		floor_p, wall_h_p, wall_v_p)
	var shop_id: String = "shop_" + fam_id
	if role_id >= 0: # el mostrador choca desde su mueble
		vm.mostrador_mundo(role_id, shop_title, fam_id, Marca.mundo(shop_id, Marca.PUESTO))

	vm.cofre_en_edificio(shop_id, Marca.sitio(shop_id, Marca.COFRE), "Cofre de " + shop_title, fam_id)
	if is_blacksmith:
		vm.adorno_en_edificio(shop_id, "res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/fireplace_0.png", sc + Vector2(-36, -16))

static func _build_residential_house_visuals(vm: VillageManager, hc: Vector2, house_title: String, fam_id: String) -> void:
	vm._construct_solid_building("house_" + fam_id, house_title, hc,
		"res://assests/world/village/floor_wood_planks.png", "res://assests/world/village/wall_timber_h.png", "res://assests/world/village/wall_timber_v.png")
	vm.cofre_en_edificio("house_" + fam_id, Marca.sitio("house_" + fam_id, Marca.COFRE), "Cofre Familiar (" + house_title + ")", fam_id)

static func _build_mixed_shop_house_visuals(vm: VillageManager, center: Vector2, title: String, fam_id: String, role_id: int = -1) -> void:
	vm._construct_solid_building("mixed_" + fam_id, title, center,
		"res://assests/world/village/floor_wood_planks.png", "res://assests/world/village/wall_timber_h.png", "res://assests/world/village/wall_timber_v.png")

	var id: String = "mixed_" + fam_id
	var stall_pos: Vector2 = Marca.sitio(id, Marca.PUESTO)
	if role_id >= 0:
		vm.mostrador_mundo(role_id, title, fam_id, Marca.mundo(id, Marca.PUESTO))
	vm.choque_en_edificio(id, stall_pos, Vector2(21.0, 9.5), true)
	vm.choque_en_edificio(id, center + Vector2(35, -14), Vector2(12.0, 12.0), true)
	vm.choque_en_edificio(id, center + Vector2(28, -38), Vector2(16.0, 8.5), true)
	# Camas y mesa chocan desde sus muebles
	vm.cofre_en_edificio(id, Marca.sitio(id, Marca.COFRE), "Cofre de la Botica Raíz Verde", fam_id)

# PASO 1: 🏥 HOSPITAL DE URGENCIAS Y ⚰️ MORGUE FORENSE (`Vector2(745, 148)`)
static func _spawn_hospital_and_morgue(vm: VillageManager) -> void:
	vm._construct_solid_building("building_hospital", "🏥 Hospital de Urgencias y ⚰️ Morgue Forense", vm._hospital_center,
		"res://assests/world/village/floor_hospital_tile.png", "res://assests/world/village/wall_stone_h.png", "res://assests/world/village/wall_stone_v.png")

	var id: String = vm.ID_HOSPITAL
	for marca: String in [Marca.CAMILLA, Marca.CAMA_1]:
		vm.choque_en_edificio(id, Marca.sitio(id, marca), Vector2(13.5, 19.5))

	vm.add_zona_uso_mundo("HospitalEmergencyBedArea", vm._hospital_bed_pos, 16.0, "hospital_bed")

	# Camillas y cuerpos se ven en 3D (escena del hospital y WorldStageProps3D); aquí solo su choque
	for i in range(1, vm.MESAS_MORGUE + 1):
		vm.choque_en_edificio(id, Marca.sitio(id, Marca.MESA_MORGUE % i), Vector2(13.6, 21.6), true)
	vm.no_pisar_mundo(EdificioEditor.a_mundo(id, Vector2(723.5, 189.0)), Vector2(11.0, 6.2), EdificioEditor.giro_plano(id))
	vm.no_pisar_mundo(EdificioEditor.a_mundo(id, Vector2(766.5, 189.0)), Vector2(7.0, 7.0), EdificioEditor.giro_plano(id))

	vm.add_zona_uso_mundo("MorgueAutopsyArea", vm._morgue_table_positions[1], 24.0, "morgue_table")

	# Dr. Valen (Médico Cirujano y Forense) — Mesa de comedor propia dentro del Hospital
	vm.adorno_en_edificio(id, "res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/table_chairs_1.png", Marca.sitio(id, Marca.MESA))
	vm._register_authority_npc(
		"NPC_Dr_Valen", "Dr. Valen", "Cirujano y Forense", VillageNPC.TradeRole.DOCTOR,
		"res://assests/world/village/villager_doctor.png",
		Marca.mundo(vm.ID_HOSPITAL, Marca.TRABAJO), Marca.mundo(vm.ID_HOSPITAL, Marca.CAMA_1), Marca.mundo(vm.ID_HOSPITAL, Marca.MESA),
		{"bandage": 4, "surgical_kit": 4, "herbal_poultice": 6},
		"family_hospital", "Cuerpo Médico del Valle",
		["Dr. Silvano", "Dra. Valeria", "Dr. Aurelio", "Dra. Caelia", "Dr. Mirko"]
	)

# PASO 2: 🚓 COMISARÍA, 🔒 CÁRCEL Y GUARDIAS DE LA LEY (`Vector2(915, 148)`)
static func _spawn_police_station_and_jail(vm: VillageManager) -> void:
	vm._construct_solid_building("building_police", "🚓 Comisaría de Policía y 🔒 Cárcel del Valle", vm._police_center,
		"res://assests/world/village/floor_stone_forge.png", "res://assests/world/village/wall_stone_h.png", "res://assests/world/village/wall_stone_v.png")
	# Reja de la celda: solo su choque (la reja 3D está en la escena de la comisaría)
	vm._jail_cell_gate_body = StaticBody2D.new()
	vm._jail_cell_gate_body.name = "JailCellGateBody"
	vm._jail_cell_gate_body.global_position = EdificioEditor.a_mundo(vm.ID_COMISARIA, Vector2(902, 152)) # en el plano de la comisaría
	vm._jail_cell_gate_body.rotation = EdificioEditor.giro_plano(vm.ID_COMISARIA)
	vm._jail_cell_gate_body.collision_layer = 1
	vm._jail_cell_gate_body.collision_mask = 0
	vm._jail_cell_gate_col = CollisionShape2D.new()
	var gate_rect := RectangleShape2D.new()
	gate_rect.size = Vector2(26, 6)
	vm._jail_cell_gate_col.shape = gate_rect
	vm._jail_cell_gate_col.disabled = true
	vm._jail_cell_gate_body.add_child(vm._jail_cell_gate_col)
	vm.entities_root.add_child(vm._jail_cell_gate_body)


	# Mesas y cama del comisario chocan desde sus muebles; la cama de la celda y el archivo, aún desde aquí
	var id: String = vm.ID_COMISARIA
	var giro: float = EdificioEditor.giro_plano(id)
	vm.no_pisar_mundo(EdificioEditor.a_mundo(id, Vector2(952, 185)), Vector2(7.0, 6.0), giro)
	vm.no_pisar_mundo(EdificioEditor.a_mundo(id, Vector2(936, 189)), Vector2(18.0, 7.0), giro)
	vm.choque_en_edificio(id, Marca.sitio(id, Marca.CAMA_CELDA), Vector2(19.0, 11.0))
	# Punto 4 (Caso I): Mesa / Archivador de Pruebas con la denuncia de desaparición archivada
	var pol_rep_pos: Vector2 = Marca.sitio(id, Marca.ARCHIVO)
	vm.choque_en_edificio(id, pol_rep_pos, Vector2(15.0, 9.0))
	vm.no_pisar_mundo(EdificioEditor.a_mundo(id, pol_rep_pos), Vector2(16.0, 9.5), giro)
	vm.zona_en_edificio(id, "PoliceArchivedReportArea", pol_rep_pos, 22.0, "police_archived_report")
	vm.add_zona_uso_mundo("PoliceJailCellArea", vm._jail_cell_pos, 22.0, "police_jail")

	# Comisario Vane y Guardia Rodric (con mesa de comedor propia en la Comisaría)
	vm._register_authority_npc(
		"NPC_Sheriff_Vane", "Comisario Vane", "Alguacil mayor", VillageNPC.TradeRole.SHERIFF,
		"res://assests/world/village/villager_sheriff.png",
		Marca.mundo(vm.ID_COMISARIA, Marca.TRABAJO), Marca.mundo(vm.ID_COMISARIA, Marca.CAMA_1), Marca.mundo(vm.ID_COMISARIA, Marca.MESA), {},
		"family_police", "Guardia del Valle",
		["Alguacil Thorne", "Alguacil Vance", "Alguacil Haldor", "Alguacil Lyra", "Alguacil Rourke"]
	)
	vm._register_authority_npc(
		"NPC_Guard_Rodric", "Guardia Rodric", "Oficial de Patrulla", VillageNPC.TradeRole.GUARD,
		"res://assests/world/village/villager_guard.png",
		vm.sitio(Vector2(510, 48)), Marca.mundo(vm.ID_COMISARIA, Marca.CAMA_1), Marca.mundo(vm.ID_COMISARIA, Marca.MESA), {},
		"family_police", "Guardia del Valle",
		["Guardia Kaelen", "Guardia Darian", "Guardia Brenna", "Guardia Tormund", "Guardia Soren"]
	)

# PASO 2B: ☀️ CAPILLA DEL ALBA Y 🪦 CEMENTERIO PARROQUIAL (`Vector2(745, 312)`)
static func _spawn_church_and_cemetery(vm: VillageManager) -> void:
	vm._construct_solid_building("building_church", "☀️ Capilla del Alba", vm._church_center,
		"res://assests/world/village/floor_stone_forge.png", "res://assests/world/village/wall_stone_h.png", "res://assests/world/village/wall_stone_v.png")
	# Bancos, altar, atril, cama y mesa del sacerdote chocan desde sus muebles (escena de la capilla)
	vm.add_zona_uso_mundo("ChurchAltarArea", vm._church_altar_pos, 22.0, "church_altar")

	# G3: el sacerdote vive en la capilla (cama en la esquina noreste y mesa propia en la noroeste)
	vm._register_authority_npc(
		"NPC_Priest_Anselmo", "Hermano Anselmo", "Sacerdote del Alba", VillageNPC.TradeRole.PRIEST,
		"res://assests/world/village/villager_traveler.png",
		Marca.mundo(vm.ID_CAPILLA, Marca.ALTAR, Vector2(0, -18)), Marca.mundo(vm.ID_CAPILLA, Marca.CAMA_1), Marca.mundo(vm.ID_CAPILLA, Marca.MESA), {},
		"family_chapel", "Capilla del Alba",
		["Hermano Teodoro", "Hermana Clara", "Hermano Bastián", "Hermana Inés", "Hermano Lucio"]
	)

	# 2. Cementerio Parroquial ampliado al Este de la Capilla (`Rect2(822, 260, 268, 168)`) con caminos en cruz, verja de hierro/piedra, árboles y 24 tumbas en filas
	# Suelo, caminos, verja y tumbas se ven en 3D (piezas de «Decorado»); aquí van los choques y las tumbas para la lógica
	# La verja (con la puerta norte libre) y las tumbas chocan desde sus piezas de «Decorado»

	vm.add_zona_uso_mundo("CemeteryGateArea", vm._cemetery_gate_pos, 24.0, "cemetery_gate")

	# 4 filas × 6 columnas = 24 tumbas: sitio de cada una (entierros)
	vm._cemetery_grave_positions.clear()
	var row_ys: Array[float] = [286.0, 316.0, 372.0, 402.0]
	var col_xs: Array[float] = [852.0, 924.0, 954.0, 984.0, 1014.0, 1044.0]
	for ry in row_ys:
		for cx in col_xs:
			vm._cemetery_grave_positions.append(Vector2(cx, ry))

	# Río de norte a sur, arroyo del bosque norte, Claro del Caso I y Molino Viejo Abandonado
	_spawn_river_arroyo_and_abandoned_mill(vm)

static func _spawn_river_arroyo_and_abandoned_mill(vm: VillageManager) -> void:
	# Sendero, orillas, barro y agua se ven en 3D (terreno y «Decorado»); aquí van el agua para la física y los puentes
	# 3. Colisión física real del agua del río y arroyo (StaticBody2D, collision_layer = 1)
	# Dividida en los 6 tramos húmedos entre los 5 puentes y vados para que solo se cruce por ellos
	# (Editor del mapa, 2026-11-09: los tramos salen de los puentes y vados; con el mapa original dan los mismos 6 de antes)
	var wet_segments: Array[Vector2] = []
	var seg_from: float = RioLago.river_y_start()
	for cr_w in RioLago.river_crossings():
		var cy: float = float(cr_w["pos"].y)
		var gap: float = float(cr_w["half_y"]) - 1.0
		if cy - gap > seg_from:
			wet_segments.append(Vector2(seg_from, cy - gap))
		seg_from = maxf(seg_from, cy + gap)
	if RioLago.river_y_end() > seg_from:
		wet_segments.append(Vector2(seg_from, RioLago.river_y_end()))
	var river_col_body := StaticBody2D.new()
	river_col_body.name = "RiverWaterCollisionBody"
	river_col_body.collision_layer = 1
	river_col_body.collision_mask = 0
	river_col_body.add_to_group("agua_2d") # el protagonista (cuerpo 3D) entra en el agua; los vecinos no (paso a 3D, paso 3)
	for seg in wet_segments:
		var seg_l := PackedVector2Array()
		var seg_r := PackedVector2Array()
		var sy: float = seg.x
		while sy <= seg.y + 0.01:
			var b: Vector2 = RioLago.river_banks_at(sy)
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
	for cr in RioLago.river_crossings():
		var c_pos: Vector2 = cr["pos"]
		var c_hy: float = float(cr["half_y"])
		var b_at: Vector2 = RioLago.river_banks_at(c_pos.y)
		var water_span: float = maxf(18.0, b_at.y - b_at.x)
		var deck_w: float = water_span + 18.0
		var deck_cx: float = (b_at.x + b_at.y) * 0.5
		var c_id: String = String(cr["id"])
		# El cruce viene del editor, ya en el mundo: pretiles a los dos lados del tablero, sobre el agua
		if c_id == "old_bridge" or c_id == "bridge_north" or c_id == "south_fields_bridge":
			vm.add_choque_mundo(Vector2(deck_cx, c_pos.y - c_hy - 1.5), Vector2(water_span, 3.0), 0.0)
			vm.add_choque_mundo(Vector2(deck_cx, c_pos.y + c_hy + 1.5), Vector2(water_span, 3.0), 0.0)
		if c_id == "old_bridge":
			# Punto 6 (Caso I): zapato izquierdo de la víctima en el Puente Viejo, junto al pretil norte
			vm.add_zona_uso_mundo("OldBridgeVictimShoeArea", Vector2(deck_cx - 10.0, c_pos.y - 12.0), 24.0, "old_bridge_left_shoe")
		# Vados (Claro del Arroyo y Bosque del Sur): sus piedras se ven en 3D y se cruzan sin pretiles

	# 6. Claro del Arroyo (Caso I) — área de inspección del lugar
	vm.add_zona_uso_mundo("Case1ClearingArea", Sitio.mundo(vm.VillageCase1.SITIO_CLARO), 22.0, "case1_clearing")

	# 7. Molino Viejo Abandonado río arriba del claro (`Vector2(188, -1060)`, tamaño `Vector2(124, 92)`)
	var mill_center: Vector2 = RioLago.ABANDONED_MILL_CENTER
	vm._construct_solid_building(vm.ID_MOLINO, "🏚️ Molino Viejo Abandonado", mill_center,
		"res://assests/world/village/floor_wood_planks.png", "res://assests/world/village/wall_stone_h.png", "res://assests/world/village/wall_stone_v.png")

	# Interior del Molino Viejo Abandonado (4 pistas/elementos del Caso I, dejando libre el pasillo central):
	# Sus sitios son marcas de la escena del molino (mapa/marca.gd)
	# (a) Pajar con paja seca (esquina noroeste)
	var straw_pos: Vector2 = Marca.sitio(vm.ID_MOLINO, Marca.PAJAR)
	vm.choque_en_edificio(vm.ID_MOLINO, straw_pos, Vector2(24.0, 16.0))
	vm.zona_en_edificio(vm.ID_MOLINO, "MillHayloftArea", straw_pos, 26.0, "mill_hayloft")

	# (b) Hogar viejo con ceniza de carbón (esquina noreste)
	var hearth_pos: Vector2 = Marca.sitio(vm.ID_MOLINO, Marca.HOGAR)
	vm.choque_en_edificio(vm.ID_MOLINO, hearth_pos, Vector2(24.0, 14.0))
	vm.zona_en_edificio(vm.ID_MOLINO, "MillHearthArea", hearth_pos, 28.0, "mill_hearth")

	# (c) Cordel de cáñamo encerado (esquina suroeste)
	var cord_pos: Vector2 = Marca.sitio(vm.ID_MOLINO, Marca.CORDEL)
	vm.choque_en_edificio(vm.ID_MOLINO, cord_pos, Vector2(18.0, 12.0))
	vm.zona_en_edificio(vm.ID_MOLINO, "MillHempCordArea", cord_pos, 26.0, "mill_hemp_cord")

	# (d) Mesa con papel («Lista de nombres — texto pendiente del autor») (sureste)
	var table_pos: Vector2 = Marca.sitio(vm.ID_MOLINO, Marca.MESA_PAPEL)
	vm.choque_en_edificio(vm.ID_MOLINO, table_pos, Vector2(22.0, 14.0))
	vm.zona_en_edificio(vm.ID_MOLINO, "MillPaperTableArea", table_pos, 26.0, "mill_table_paper")

	# (e) Punto 4 (Caso I): Sótano del molino con reja de hierro al canal de la rueda (oeste)
	var cellar_pos: Vector2 = Marca.sitio(vm.ID_MOLINO, Marca.SOTANO)
	vm.zona_en_edificio(vm.ID_MOLINO, "MillCellarGrateArea", cellar_pos, 26.0, "mill_cellar_grate")
	vm.add_zona_uso_mundo("MillRedClayArea", Sitio.mundo(SITIO_BARRO_ROJO), 28.0, "mill_red_clay")

# ==============================================================================
# PASO 5: 📋 TABLÓN DE ENCARGOS EN LA PLAZA CENTRAL (`Vector2(465, 24)`)
# ==============================================================================
static func _spawn_notice_board_in_plaza(vm: VillageManager) -> void:
	vm.add_choque_mundo(vm._notice_board_pos, vm.COLISOR_TABLON, 0.0) # el tablón se ve en 3D
	vm.add_zona_uso_mundo("PlazaNoticeBoardArea", vm._notice_board_pos, 14.0, "notice_board")

# ==============================================================================
# PASO 10: ⚡ FAROLAS ELÉCTRICAS EN LAS CALLES DEL PUEBLO (`lamp-post1.png`)
# ==============================================================================
static func _spawn_electric_streetlights(vm: VillageManager) -> void:
	# Las 6 primeras son piezas «Farola» de «Objetos»; las demás, cruces de «Sitios». La farola 3D sale de aquí
	var sitios: Array[Vector2] = []
	for li in range(FAROLAS_OBJETO):
		sitios.append(ObjetoEditor.mundo(OBJETO_FAROLA % li))
	for f_pos in sitios + Sitio.serie(SERIE_FAROLAS_CALLE):
		vm.add_choque_mundo(f_pos, vm.COLISOR_TABLON, 0.0)
		vm.streetlights.append({"pos": f_pos})

static func _spawn_wells(vm: VillageManager) -> void:
	# Pozos de la granja, del patio de la posada y de la plaza: su sitio y su giro, de su pieza de «Objetos»
	for pozo: Array in [[vm.OBJETO_POZO_GRANJA, "WaterWellArea"], [vm.OBJETO_POZO_TABERNA, "TavernWaterWellArea"], [vm.OBJETO_POZO_PLAZA, "PlazaWaterWellArea"]]:
		var w_pos: Vector2 = ObjetoEditor.mundo(pozo[0])
		vm.add_marca_3d_mundo("well", w_pos, ObjetoEditor.giro(pozo[0]))
		vm.add_zona_uso_mundo(pozo[1], w_pos, 24.0, "well")
