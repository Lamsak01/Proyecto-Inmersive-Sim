@tool
extends "res://scripts/visuals/WorldStageBase3D.gd"
const Suelo = preload("res://scripts/fisica/Suelo.gd") # paso a 3D, paso 2b: profundidad del club y las alcantarillas
const Cartel = preload("res://mapa/cartel.gd") # carteles de madera: los de las puertas (Buildings3D) y los postes de los caminos
const META_TIPO_3D := "tipo_3d" ## en un dibujo del mapa: qué objeto 3D le toca, si su dibujo no basta para saberlo
const ROCA_ALTO_PX: float = 12.0     ## rocas sueltas de adorno (cantera): algo más bajas que las que se pican (16)
const ROCA_HUNDIDA_PX: float = -1.4  ## medio enterradas, como las de la naturaleza
## Farolas y focos: luz eléctrica azulada del generador del Arreglador (antes había otra amarilla «sin corriente»).
const COLOR_LUZ_ELECTRICA: Color = Color(0.58, 0.96, 1.0)
## Farola (modelo «lightpost-single», medido 2026-11-12): el farol cuelga al sur del poste, entre las placas de 21–23 px
## y 25–27 px de alto (9 × 4 px de planta). El cristal brilla con una caja de luz un poco dentro de las placas y dos luces: un foco hacia abajo que deja un charco de luz en el suelo y un resplandor suave para las paredes.
## Medidas tomadas con la farola de 29 px; el usuario la pidió un 20 % más alta y con un 50 % más de luz (2026-11-12).
const FAROLA_ALTO_MEDIDO_PX: float = 29.0
const FAROLA_ALTO_PX: float = FAROLA_ALTO_MEDIDO_PX * 1.2
const FAROLA_ESTIRA: float = FAROLA_ALTO_PX / FAROLA_ALTO_MEDIDO_PX ## el modelo solo se estira hacia arriba
const FAROL_DESPLAZ: Vector2 = Vector2(0.0, 2.5)
const FAROL_TAM: Vector2 = Vector2(8.4, 3.6)
const FAROL_BASE_PX: float = 22.9 * FAROLA_ESTIRA
const FAROL_ALTO_PX: float = 2.2 * FAROLA_ESTIRA
const FAROLA_CHARCO_ENERGIA: float = 15.0
const FAROLA_CHARCO_ALCANCE_PX: float = 6.0   ## × Mapa3D.K, como el resto de luces de la escala vieja
const FAROLA_CHARCO_ANGULO: float = 60.0
const FAROLA_ENERGIA: float = 3.0
const FAROLA_ALCANCE_PX: float = 3.6
## Con ~47 farolas, las luces lejanas se apagan solas (el farol sigue brillando): el portátil no aguanta ~90 luces a la vez.
const FAROLA_LUZ_VISIBLE_M: float = 70.0
const FAROLA_LUZ_FUNDIDO_M: float = 15.0
const FOCO_ENERGIA: float = 3.2
const FOCO_SUELO_ENERGIA: float = 2.1

## Puesto del Paso, cementerio, alcantarillas, objetos de la época, farolas y objetos/props dinámicos 3D.

# ==============================================================================
# 4. ASENTAMIENTO FRONTERIZO «PUESTO DEL PASO» (EN EL LINDERO ESTE)
# ==============================================================================
func rebuild_outpost_3d() -> void:
	_clear_children(outpost_root_3d)
	if vm == null:
		return
	var op: Dictionary = VillageCulture.outpost_state(vm)
	var founded: bool = bool(op.get("founded", false))
	var upgs: Dictionary = op.get("upgrades", {})
	var c: Vector2 = VillageCulture.outpost_center()
	var gate_p: Vector2 = VillageCulture.outpost_gate_pos()
	mover_posiciones = true # el puesto está escrito en el mapa original: sigue a su pieza de «Solares»
	_dibujar_puesto(founded, upgs, c, gate_p)
	mover_posiciones = false


func _dibujar_puesto(founded: bool, upgs: Dictionary, c: Vector2, gate_p: Vector2) -> void:
	var m_road := _mat("road_dirt", Color(0.46, 0.37, 0.25), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.35)
	var m_log := _mat("outpost_log", Color(0.55, 0.40, 0.26), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/floor_wood_planks.png", "", 0.45)
	var m_plank := _mat("outpost_plank", Color(0.68, 0.50, 0.32), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/floor_wood_planks.png", "", 0.45)
	var m_stone := _mat("outpost_stone", Color(0.65, 0.64, 0.60), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.35)

	# Extensión del camino del este hasta el Puesto del Paso
	_add_box_2d(outpost_root_3d, Vector2(1512, 50), Vector2(72, 26), 0.0, 1.2, m_road)

	if not founded:
		# Solar fronterizo con estacas, mesa de planos y cartel
		for p in [Vector2(-64, -68), Vector2(64, -68), Vector2(64, 68), Vector2(-64, 68)]:
			_add_cyl_2d(outpost_root_3d, c + p, 2.5, 0.0, 11.0, m_log, 2.0, 8)
		_add_box_2d(outpost_root_3d, gate_p, Vector2(4.0, 4.0), 0.0, 16.0, m_log)
		_add_box_2d(outpost_root_3d, gate_p + Vector2(0, -2), Vector2(16.0, 3.0), 11.0, 5.0, m_plank)
		return

	# Explanada fortificada y empalizada de troncos 3D
	_add_box_2d(outpost_root_3d, c, Vector2(152, 164), 0.0, 1.5, m_stone)
	_add_box_2d(outpost_root_3d, c + Vector2(0, -80), Vector2(152, 6), 1.5, 22.0, m_log)
	_add_box_2d(outpost_root_3d, c + Vector2(0, 80), Vector2(152, 6), 1.5, 22.0, m_log)
	_add_box_2d(outpost_root_3d, c + Vector2(74, 0), Vector2(6, 164), 1.5, 22.0, m_log)
	_add_box_2d(outpost_root_3d, c + Vector2(-74, -50), Vector2(6, 60), 1.5, 22.0, m_log)
	_add_box_2d(outpost_root_3d, c + Vector2(-74, 50), Vector2(6, 60), 1.5, 22.0, m_log)
	# Pórtico de entrada en Vector2(1542, 50)
	_add_cyl_2d(outpost_root_3d, gate_p + Vector2(0, -20), 4.0, 1.5, 28.0, m_log, 3.5, 8)
	_add_cyl_2d(outpost_root_3d, gate_p + Vector2(0, 20), 4.0, 1.5, 28.0, m_log, 3.5, 8)
	_add_box_2d(outpost_root_3d, gate_p, Vector2(8.0, 44.0), 25.0, 5.0, m_plank)

	# Cabaña de mando 3D, Arca del asentamiento y Hoguera central encendida
	_add_model_2d(outpost_root_3d, "buildings/House_2.obj", c + Vector2(34, 0), 1.5, Vector2(50, 42), 34.0, -90.0)
	_add_model_2d(outpost_root_3d, "props/Chest_Wood.gltf", c + Vector2(6, 0), 1.5, Vector2(13, 9), 8.0, -90.0)
	_add_model_2d(outpost_root_3d, "exterior/Bonfire_Lit.obj", c + Vector2(-18, 0), 1.5, Vector2(16, 16), 11.0)
	_add_model_2d(outpost_root_3d, "props/Crate_Wooden.gltf", c + Vector2(14, 24), 1.5, Vector2(10, 10), 8.0)
	_add_model_2d(outpost_root_3d, "props/Barrel.gltf", c + Vector2(14, -24), 1.5, Vector2(9, 9), 9.5)
	if not _is_headless:
		var fire_lt := OmniLight3D.new()
		fire_lt.position = to_3d(c + Vector2(-18, 0), 12.0)
		fire_lt.light_color = Color(1.0, 0.65, 0.25)
		fire_lt.light_energy = 1.6
		fire_lt.omni_range = 3.2 * Mapa3D.K
		outpost_root_3d.add_child(fire_lt)

	# Mejora 1: Aserradero Fronterizo
	if bool(upgs.get("sawmill", false)):
		var sm_p := c + Vector2(-26, -50)
		_add_model_2d(outpost_root_3d, "buildings/Sawmill.obj", sm_p, 1.5, Vector2(48, 32), 28.0)
		_add_model_2d(outpost_root_3d, "nature/WoodLog.obj", sm_p + Vector2(22, 10), 1.5, Vector2(14, 8), 6.0)

	# Mejora 2: Granero / Molino del Paso
	if bool(upgs.get("granary", false)):
		var gr_p := c + Vector2(-26, 50)
		_add_model_2d(outpost_root_3d, "buildings/Mill.obj", gr_p, 1.5, Vector2(38, 38), 36.0)

	# Mejora 3: Atalaya de Guardia
	if bool(upgs.get("watchtower", false)):
		var wt_p := c + Vector2(-56, -56)
		_add_model_2d(outpost_root_3d, "buildings/Bell_Tower.obj", wt_p, 1.5, Vector2(30, 30), 48.0)

# ==============================================================================
# 5. TUMBAS DEL CEMENTERIO, ALCANTARILLAS (-1) Y FAROLAS CON LUZ REAL
# ==============================================================================
func rebuild_graves_3d() -> void:
	_clear_children(graves_root_3d)
	if vm == null:
		return
	_last_buried_count = vm.buried_graves.size()
	var m_mound := _mat("grave_earth", Color(0.36, 0.25, 0.16), 0.95, 0.0)
	var grave_models: Array[String] = [
		"graveyard/gravestone-cross.glb",
		"graveyard/gravestone-decorative.glb",
		"graveyard/gravestone-round.glb",
		"graveyard/cross-column.glb",
	]

	for i in range(vm.buried_graves.size()):
		var g_pos: Vector2 = vm._cemetery_burial_pos
		if i < vm._cemetery_grave_positions.size():
			g_pos = vm._cemetery_grave_positions[i]
		else:
			g_pos = Vector2(844.0 + float(i % 6) * 26.0, 282.0 + float(int(float(i) / 6.0) % 3) * 28.0)
		_add_box_2d(graves_root_3d, g_pos + Vector2(0, 3), Vector2(7.5, 8.5), 1.0, 1.8, m_mound)
		var g_mdl: String = grave_models[i % grave_models.size()]
		_add_model_2d(graves_root_3d, g_mdl, g_pos + Vector2(0, -4), 1.0, Vector2(6.8, 3.2), 8.8)

func _build_sewers_3d() -> void:
	_clear_children(sewers_root_3d)
	var m_bedrock := _mat("sewer_bedrock", Color(0.08, 0.10, 0.09), 0.96, 0.0)
	var m_brick := _mat("sewer_brick", Color(0.28, 0.34, 0.30), 0.90, 0.05, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.35)
	var m_walkway := _mat("sewer_walkway", Color(0.36, 0.40, 0.38), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/rf_cobblestone.png", "", 0.45)
	var m_water := _mat("sewer_water", Color(0.14, 0.46, 0.36, 0.92), 0.25, 0.15, Color(0.10, 0.42, 0.30), 0.35)
	var m_iron := _mat("sewer_iron", Color(0.24, 0.27, 0.32), 0.42, 0.78)
	var m_wood := _mat("sewer_wood", Color(0.46, 0.30, 0.16), 0.85, 0.04)
	var m_brass := _mat("sewer_brass", Color(0.90, 0.74, 0.26), 0.28, 0.85, Color(0.85, 0.68, 0.20), 0.45)
	var m_torch := _mat("sewer_torch", Color(1.0, 0.76, 0.32), 0.20, 0.0, Color(1.0, 0.68, 0.22), 2.8)

	var sy: float = VillageUnderworldScript.SEWER_Y
	# Editor del mapa 3D: la red entera se desplaza lo que el usuario la movió (VillageUnderworld.desp_red)
	var d_red: Vector2 = VillageUnderworldScript.desp_red
	# Losa oscura de roca subterránea para cubrir el entorno exterior alrededor de la red de túneles bajo el pueblo (y = SEWER_Y)
	var zona: Rect2 = VillageUnderworldScript.zona_alcantarillas()
	_add_box_2d(sewers_root_3d, zona.get_center() - d_red, zona.size, 1.2, 0.8, m_bedrock)
	_add_techo_roca(sewers_root_3d, zona.get_center() - d_red, zona.size, m_bedrock)
	# Paso a 3D, paso 2b: la red está de verdad bajo tierra (Suelo.PROFUNDIDAD_SOTANO_PX bajo la calle)
	sewers_root_3d.position = Mapa3D.a_3d(d_red, Suelo.PROFUNDIDAD_SOTANO_PX)

	# 3 cámaras conectadas bajo el centro del pueblo: Bóveda Inundada (260, SEWER_Y), Pasadizo del Contrabandista (420, SEWER_Y) y Cisterna (580, SEWER_Y)
	for loc_id in ["flooded_vault", "smuggler_tunnel", "cistern"]:
		var def: Dictionary = VillageUnderworldScript.SEWER_LOCATIONS_BASE[loc_id]
		var ch_p: Vector2 = def["chamber_center"]
		var lad_p: Vector2 = def["ladder_pos"]
		var chs_p: Vector2 = def["chest_pos"]

		# Suelo de piedra, andén seco norte y canal de aguas turbias al sur
		_add_box_2d(sewers_root_3d, ch_p, Vector2(110.0, 80.0), 2.0, 1.4, m_brick)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(0.0, -8.0), Vector2(106.0, 56.0), 3.4, 1.2, m_walkway)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(0.0, 26.0), Vector2(106.0, 18.0), 2.6, 1.0, m_water)

		# Muro norte alto y zócalo sur bajo (para que la cámara isométrica vea el interior sin tapar al jugador)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(0.0, -43.0), Vector2(116.0, 6.0), 3.0, 20.0, m_brick)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(0.0, 43.0), Vector2(116.0, 6.0), 3.0, 5.0, m_brick)

		# Escalerilla 3D de salida a la calle junto a la boca del túnel
		_add_box_2d(sewers_root_3d, lad_p + Vector2(0.0, -2.0), Vector2(11.0, 8.0), 4.6, 0.8, m_iron)
		_add_box_2d(sewers_root_3d, lad_p + Vector2(-4.0, -10.0), Vector2(1.4, 2.0), 4.6, 20.0, m_iron)
		_add_box_2d(sewers_root_3d, lad_p + Vector2(4.0, -10.0), Vector2(1.4, 2.0), 4.6, 20.0, m_iron)
		for rung_i in range(6):
			_add_box_2d(sewers_root_3d, lad_p + Vector2(0.0, -10.0), Vector2(8.0, 1.2), 6.5 + float(rung_i) * 3.0, 0.9, m_brass)

		# Antorcha mural subterránea junto a la escalerilla
		_add_cyl_2d(sewers_root_3d, lad_p + Vector2(12.0, -13.0), 1.4, 13.0, 5.0, m_wood, 1.0, 6)
		_add_cyl_2d(sewers_root_3d, lad_p + Vector2(12.0, -13.0), 2.2, 18.0, 3.0, m_torch, 1.4, 8)
		if not _is_headless:
			var t_light := OmniLight3D.new()
			t_light.position = to_3d(lad_p + Vector2(12.0, -8.0), 19.0)
			t_light.light_color = Color(1.0, 0.78, 0.42)
			t_light.light_energy = 1.35
			t_light.omni_range = 3.2 * Mapa3D.K
			sewers_root_3d.add_child(t_light)

		# Cofre de contrabando 3D sobre losa de piedra + barriles y cajas de alijo
		_add_box_2d(sewers_root_3d, chs_p, Vector2(16.0, 12.0), 4.6, 1.4, m_brick)
		if _add_model_2d(sewers_root_3d, "props/Chest_Wood.gltf", chs_p, 6.0, Vector2(13.0, 9.5), 8.5) == null:
			_add_box_2d(sewers_root_3d, chs_p, Vector2(13.0, 9.0), 6.0, 5.5, m_wood)
			_add_box_2d(sewers_root_3d, chs_p, Vector2(13.4, 9.4), 11.5, 2.5, m_iron)
		_add_box_2d(sewers_root_3d, chs_p + Vector2(0.0, 4.6), Vector2(2.4, 1.4), 8.5, 2.6, m_brass)
		if loc_id == "cistern":
			_vestir_renidero_3d(ch_p, m_wood, m_iron, m_brass)
			continue
		_add_model_2d(sewers_root_3d, "props/Barrel.gltf", ch_p + Vector2(-38.0, 6.0), 4.6, Vector2(9.0, 9.0), 9.5)
		_add_model_2d(sewers_root_3d, "props/Crate_Wooden.gltf", ch_p + Vector2(38.0, 6.0), 4.6, Vector2(11.0, 11.0), 8.5)

	# 2 galerías de conexión entre las 3 cámaras (x = 340 y x = 500) y muros laterales de cierre
	for corr_x in [340.0, 500.0]:
		var cp := Vector2(corr_x, sy)
		_add_box_2d(sewers_root_3d, cp, Vector2(56.0, 42.0), 2.0, 2.4, m_walkway)
		_add_box_2d(sewers_root_3d, cp + Vector2(0.0, 14.0), Vector2(56.0, 10.0), 2.6, 1.0, m_water)
		_add_box_2d(sewers_root_3d, cp + Vector2(0.0, -23.0), Vector2(56.0, 6.0), 3.0, 18.0, m_brick)
		_add_box_2d(sewers_root_3d, cp + Vector2(0.0, 23.0), Vector2(56.0, 6.0), 3.0, 5.0, m_brick)
	for sx in [315.0, 365.0, 475.0, 525.0]:
		_add_box_2d(sewers_root_3d, Vector2(sx, sy - 32.0), Vector2(6.0, 22.0), 3.0, 20.0, m_brick)
		_add_box_2d(sewers_root_3d, Vector2(sx, sy + 32.0), Vector2(6.0, 22.0), 3.0, 5.0, m_brick)
	_add_box_2d(sewers_root_3d, Vector2(202.0, sy), Vector2(6.0, 86.0), 3.0, 20.0, m_brick)
	_add_box_2d(sewers_root_3d, Vector2(638.0, sy), Vector2(6.0, 86.0), 3.0, 20.0, m_brick)

func _add_green_crt_terminal_3d(parent: Node3D, pos_2d: Vector2, base_h: float, face_north: bool = false) -> void:
	var m_crt_case := _mat("crt_case_iron", Color(0.22, 0.25, 0.24), 0.55, 0.68)
	var m_crt_bezel := _mat("crt_bezel_dark", Color(0.11, 0.13, 0.12), 0.65, 0.35)
	var m_crt_green := _mat("crt_screen_green", Color(0.12, 0.96, 0.34), 0.18, 0.0, Color(0.10, 0.88, 0.28), 2.2)
	var m_crt_line := _mat("crt_scanline", Color(0.42, 1.0, 0.58), 0.12, 0.0, Color(0.32, 0.96, 0.46), 2.8)
	var dir_y: float = -1.0 if face_north else 1.0
	# Monitor CRT compacto con chasis metálico y pantalla de fósforo verde
	_add_box_2d(parent, pos_2d + Vector2(0, -0.8 * dir_y), Vector2(8.4, 6.0), base_h, 5.8, m_crt_case)
	_add_box_2d(parent, pos_2d + Vector2(0, 1.8 * dir_y), Vector2(7.4, 1.4), base_h + 0.6, 4.6, m_crt_bezel)
	_add_box_2d(parent, pos_2d + Vector2(0, 2.3 * dir_y), Vector2(6.4, 0.8), base_h + 1.0, 3.8, m_crt_green)
	# Líneas de texto fosforescentes en la pantalla
	for ly in [1.7, 2.7, 3.7]:
		_add_box_2d(parent, pos_2d + Vector2(-0.5, 2.6 * dir_y), Vector2(4.4, 0.35), base_h + ly, 0.32, m_crt_line)
	# Teclado mecánico delantero
	_add_box_2d(parent, pos_2d + Vector2(0, 3.8 * dir_y), Vector2(7.8, 2.8), base_h, 1.0, m_crt_case)
	_add_box_2d(parent, pos_2d + Vector2(0, 3.8 * dir_y), Vector2(6.8, 1.9), base_h + 0.85, 0.35, m_crt_bezel)
	if not _is_headless:
		var crt_lt := OmniLight3D.new()
		crt_lt.position = to_3d(pos_2d + Vector2(0, 3.2 * dir_y), base_h + 3.6)
		crt_lt.light_color = Color(0.16, 0.96, 0.38)
		crt_lt.light_energy = 0.75
		crt_lt.omni_range = 1.8 * Mapa3D.K
		parent.add_child(crt_lt)

func _add_sandbag_wire_barrier_3d(parent: Node3D, pos_2d: Vector2) -> void:
	var m_bag := _mat("epoch_sandbag", Color(0.50, 0.43, 0.31), 0.95, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.8)
	var m_stake := _mat("epoch_stake_wood", Color(0.30, 0.20, 0.12), 0.90, 0.0)
	var m_wire := _mat("epoch_barbed_wire", Color(0.24, 0.25, 0.27), 0.48, 0.82)
	# Dos hileras escalonadas de sacos terreros
	for bx in [-7.5, -2.5, 2.5, 7.5]:
		_add_box_2d(parent, pos_2d + Vector2(bx, 1.2), Vector2(4.8, 3.4), 0.0, 2.4, m_bag)
		_add_box_2d(parent, pos_2d + Vector2(bx, -1.2), Vector2(4.8, 3.4), 0.0, 2.4, m_bag)
	for bx2 in [-5.0, 0.0, 5.0]:
		_add_box_2d(parent, pos_2d + Vector2(bx2, 0.0), Vector2(4.8, 3.6), 2.3, 2.3, m_bag)
	for bx3 in [-2.5, 2.5]:
		_add_box_2d(parent, pos_2d + Vector2(bx3, 0.0), Vector2(4.6, 3.2), 4.5, 2.0, m_bag)
	# Caballetes en X y rollos de alambre de espino encima y delante
	for sx in [-8.5, 0.0, 8.5]:
		_add_cyl_2d(parent, pos_2d + Vector2(sx, -2.8), 0.65, 0.0, 8.2, m_stake, 0.55, 6)
		_add_cyl_2d(parent, pos_2d + Vector2(sx, 2.8), 0.65, 0.0, 8.2, m_stake, 0.55, 6)
	for wy in [5.2, 6.8, 8.0]:
		_add_box_2d(parent, pos_2d, Vector2(21.0, 0.45), wy, 0.45, m_wire)
	for cx in [-7.0, -3.5, 0.0, 3.5, 7.0]:
		_add_cyl_2d(parent, pos_2d + Vector2(cx, 2.4), 2.2, 2.2, 3.8, m_wire, 2.2, 8)

func _add_floodlight_tower_3d(parent: Node3D, pos_2d: Vector2, target_2d: Vector2, m_bulb: Material) -> void:
	var m_pole := _mat("epoch_pole_wood", Color(0.28, 0.19, 0.11), 0.90, 0.0)
	var m_hood := _mat("epoch_hood_iron", Color(0.16, 0.18, 0.21), 0.45, 0.82)
	# Poste alto de madera con cruceta y carcasa de proyector metálico
	_add_cyl_2d(parent, pos_2d, 2.2, 0.0, 35.0, m_pole, 1.5, 8)
	_add_box_2d(parent, pos_2d, Vector2(7.5, 2.2), 31.5, 1.8, m_pole)
	var dir_2d: Vector2 = (target_2d - pos_2d).normalized()
	var head_2d: Vector2 = pos_2d + dir_2d * 2.8
	_add_box_2d(parent, head_2d, Vector2(5.2, 5.2), 33.0, 4.2, m_hood)
	var bulb := _add_cyl_2d(parent, head_2d + dir_2d * 1.6, 2.1, 33.4, 2.6, m_bulb, 2.1, 8)
	var spot: SpotLight3D = null
	var pool: OmniLight3D = null
	if not _is_headless:
		spot = SpotLight3D.new()
		spot.position = to_3d(head_2d, 34.5)
		var tgt_3d: Vector3 = to_3d(target_2d, 0.5)
		spot.spot_range = 9.5 * Mapa3D.K
		spot.spot_angle = 42.0
		spot.light_energy = FOCO_ENERGIA
		spot.light_color = COLOR_LUZ_ELECTRICA
		parent.add_child(spot)
		if spot.position.distance_to(tgt_3d) > 0.05:
			spot.look_at_from_position(spot.position, tgt_3d, Vector3.UP)
		pool = OmniLight3D.new()
		pool.position = to_3d(pos_2d.lerp(target_2d, 0.55), 10.0)
		pool.omni_range = 5.4 * Mapa3D.K
		pool.light_energy = FOCO_SUELO_ENERGIA
		pool.light_color = COLOR_LUZ_ELECTRICA
		parent.add_child(pool)
	_floodlight_nodes_3d.append({
		"bulb": bulb,
		"spot": spot,
		"pool": pool,
	})

func _build_epoch_props_3d(m_bulb: Material) -> void:
	mover_posiciones = true # generador, cables y terminales están escritos en el mapa original: siguen a sus edificios
	var m_cable := _mat("epoch_thick_cable", Color(0.08, 0.09, 0.11), 0.72, 0.25)
	var m_insul := _mat("epoch_insulator", Color(0.76, 0.78, 0.74), 0.35, 0.10)
	var m_gen_iron := _mat("epoch_gen_iron", Color(0.18, 0.21, 0.22), 0.48, 0.78)
	var m_gen_rust := _mat("epoch_gen_rust", Color(0.38, 0.24, 0.16), 0.75, 0.45)
	var m_brass := _mat("epoch_gen_brass", Color(0.82, 0.64, 0.22), 0.35, 0.85)
	var m_pad := _mat("epoch_gen_pad", Color(0.44, 0.43, 0.40), 0.92, 0.0)

	# 1. Generador diésel junto al muro este del Taller de Reparaciones (marca «generador» de su escena)
	var gp: Vector2 = VillageCulture.tinker_generator_pos()
	_add_box_2d(streetlights_root_3d, gp, Vector2(18.0, 24.0), 0.0, 2.2, m_pad) # Losa de hormigón
	_add_box_2d(streetlights_root_3d, gp, Vector2(13.5, 18.0), 2.2, 11.5, m_gen_iron) # Bloque motor diésel
	_add_box_2d(streetlights_root_3d, gp + Vector2(0.0, -3.5), Vector2(11.0, 9.0), 13.7, 3.8, m_gen_rust) # Culata con aletas
	_add_cyl_2d(streetlights_root_3d, gp + Vector2(0.0, 5.2), 4.2, 13.5, 6.2, m_gen_rust, 4.2, 10) # Depósito de gasóleo
	_add_cyl_2d(streetlights_root_3d, gp + Vector2(-5.5, -2.0), 4.4, 5.5, 3.0, m_brass, 4.4, 12) # Volante de inercia / alternador
	_add_cyl_2d(streetlights_root_3d, gp + Vector2(5.2, -6.5), 1.1, 13.0, 17.5, m_gen_iron, 1.1, 8) # Tubo de escape vertical
	_add_cyl_2d(streetlights_root_3d, gp + Vector2(5.2, -6.5), 2.0, 21.0, 5.5, m_gen_rust, 2.0, 8) # Silenciador

	# 2. Cables gruesos por las fachadas del Taller (e5), Comisaría y Ayuntamiento hasta el generador
	# Taller (e5: rect x=1166..1304, y=90..194): desde el generador (1316, 126) por el muro este y fachada norte hasta el cuadro eléctrico (1270, 90)
	_add_box_2d(streetlights_root_3d, Vector2(1310.0, 122.0), Vector2(12.0, 1.8), 11.0, 1.8, m_cable)
	_add_box_2d(streetlights_root_3d, Vector2(1304.8, 106.0), Vector2(1.8, 34.0), 11.0, 1.8, m_cable)
	_add_box_2d(streetlights_root_3d, Vector2(1304.8, 90.0), Vector2(1.8, 2.2), 11.0, 14.5, m_cable)
	_add_box_2d(streetlights_root_3d, Vector2(1240.0, 89.2), Vector2(130.0, 1.8), 24.0, 1.6, m_cable)
	_add_box_2d(streetlights_root_3d, Vector2(1240.0, 89.2), Vector2(130.0, 1.5), 21.2, 1.4, m_cable)
	for ix_t in [1182.0, 1212.0, 1270.0, 1300.0]:
		_add_cyl_2d(streetlights_root_3d, Vector2(ix_t, 88.5), 1.1, 23.5, 2.6, m_insul, 1.1, 6)

	# Comisaría (building_police: rect x=844..986, y=100..196): cables gruesos por la fachada norte y esquina este hasta el poste del foco
	_add_box_2d(streetlights_root_3d, Vector2(915.0, 99.2), Vector2(140.0, 1.8), 24.5, 1.6, m_cable)
	_add_box_2d(streetlights_root_3d, Vector2(915.0, 99.2), Vector2(140.0, 1.5), 21.5, 1.4, m_cable)
	_add_box_2d(streetlights_root_3d, Vector2(986.8, 136.0), Vector2(1.8, 72.0), 23.0, 1.6, m_cable)
	_add_box_2d(streetlights_root_3d, Vector2(936.0, 99.0), Vector2(1.6, 1.8), 12.0, 12.5, m_cable) # Bajante hacia la terminal policial
	_add_box_2d(streetlights_root_3d, Vector2(990.0, 97.5), Vector2(9.0, 1.6), 24.5, 1.6, m_cable) # Ramal al poste del foco
	for ix_p in [852.0, 886.0, 944.0, 980.0]:
		_add_cyl_2d(streetlights_root_3d, Vector2(ix_p, 98.5), 1.1, 24.0, 2.6, m_insul, 1.1, 6)

	# Ayuntamiento (building_town_hall: rect x=695..825, y=-468..-372): cables gruesos por la fachada sur y muro oeste hacia la terminal
	if vm != null and VillageCulture.VillageLots.lot(vm, "n4").get("kind", "") == "town_hall":
		_add_box_2d(streetlights_root_3d, Vector2(760.0, -371.2), Vector2(128.0, 1.8), 24.5, 1.6, m_cable)
		_add_box_2d(streetlights_root_3d, Vector2(760.0, -371.2), Vector2(128.0, 1.5), 21.5, 1.4, m_cable)
		_add_box_2d(streetlights_root_3d, Vector2(694.2, -412.0), Vector2(1.8, 82.0), 23.0, 1.6, m_cable)
		_add_box_2d(streetlights_root_3d, Vector2(716.0, -371.0), Vector2(1.6, 1.8), 11.0, 13.5, m_cable)
		for ix_th in [704.0, 734.0, 786.0, 816.0]:
			_add_cyl_2d(streetlights_root_3d, Vector2(ix_th, -370.5), 1.1, 24.0, 2.6, m_insul, 1.1, 6)

	# 3. Sacos terreros y alambre de espino a la entrada de la Comisaría (dejando libre la puerta x=893..937) y en el Puesto del Paso
	_add_sandbag_wire_barrier_3d(streetlights_root_3d, Vector2(864.0, 92.0))
	_add_sandbag_wire_barrier_3d(streetlights_root_3d, Vector2(966.0, 92.0))
	_add_sandbag_wire_barrier_3d(streetlights_root_3d, Vector2(1528.0, 22.0))
	_add_sandbag_wire_barrier_3d(streetlights_root_3d, Vector2(1528.0, 78.0))

	# 4. Focos en poste de madera en la Comisaría y en el Puesto del Paso (se apagan si se sabotea la red eléctrica)
	_add_floodlight_tower_3d(streetlights_root_3d, Vector2(994.0, 96.0), Vector2(915.0, 62.0), m_bulb)
	_add_floodlight_tower_3d(streetlights_root_3d, Vector2(1538.0, 18.0), Vector2(1506.0, 50.0), m_bulb)
	mover_posiciones = false

## Apaga poco a poco la luz de una farola cuando el jugador está lejos.
func _fundir_de_lejos(luz: Light3D) -> void:
	luz.distance_fade_enabled = true
	luz.distance_fade_begin = FAROLA_LUZ_VISIBLE_M
	luz.distance_fade_length = FAROLA_LUZ_FUNDIDO_M


func _build_streetlights_3d() -> void:
	_clear_children(streetlights_root_3d)
	_streetlight_nodes_3d.clear()
	_floodlight_nodes_3d.clear()
	if vm == null:
		return
	var m_bulb := _mat("bulb_voltaic", Color(0.55, 0.96, 1.0), 0.2, 0.0, Color(0.45, 0.92, 1.0), 3.4)

	for sl in vm.streetlights:
		var pos: Vector2 = sl.get("pos", Vector2.ZERO)
		_add_model_2d(streetlights_root_3d, "graveyard/lightpost-single.glb", pos, 0.0, Vector2(9.0, 9.0), FAROLA_ALTO_PX)
		var farol: Vector2 = pos + FAROL_DESPLAZ
		var bulb := _add_box_2d(streetlights_root_3d, farol, FAROL_TAM, FAROL_BASE_PX, FAROL_ALTO_PX, m_bulb)
		var omni: OmniLight3D = null
		var charco: SpotLight3D = null
		if not _is_headless:
			omni = OmniLight3D.new()
			omni.position = to_3d(farol, FAROL_BASE_PX + FAROL_ALTO_PX * 0.5)
			omni.omni_range = FAROLA_ALCANCE_PX * Mapa3D.K
			omni.light_energy = FAROLA_ENERGIA
			omni.light_color = COLOR_LUZ_ELECTRICA
			_fundir_de_lejos(omni)
			streetlights_root_3d.add_child(omni)
			charco = SpotLight3D.new()
			charco.position = to_3d(farol, FAROL_BASE_PX)
			charco.rotation_degrees.x = -90.0 # mira hacia abajo
			charco.spot_range = FAROLA_CHARCO_ALCANCE_PX * Mapa3D.K
			charco.spot_angle = FAROLA_CHARCO_ANGULO
			charco.light_energy = FAROLA_CHARCO_ENERGIA
			charco.light_color = COLOR_LUZ_ELECTRICA
			_fundir_de_lejos(charco)
			streetlights_root_3d.add_child(charco)
		_streetlight_nodes_3d.append({
			"bulb": bulb,
			"light": omni,
			"charco": charco,
		})
	_build_epoch_props_3d(m_bulb)


func _sync_dynamic_props_3d() -> void:
	# 1. Puertas abatibles 3D
	for d_node in _door_nodes_3d:
		var d_entry: Dictionary = d_node["entry"]
		var pivot: Node3D = d_node["pivot"]
		var badge: MeshInstance3D = d_node["lock_badge"]
		if not is_instance_valid(pivot):
			continue
		var eff_open: bool = bool(d_entry.get("is_open", false)) or float(d_entry.get("npc_pass_timer", 0.0)) > 0.0
		var door_south: bool = bool(d_node["door_south"])
		pivot.rotation_degrees.y = (-82.0 if door_south else 82.0) if eff_open else 0.0
		if is_instance_valid(badge):
			badge.visible = (not eff_open) and (bool(d_entry.get("is_locked", false)) or bool(d_entry.get("locked_by_player", false)))

	_puertas_interiores.sincronizar(get_tree(), vm, get_process_delta_time())
	_rastros.sincronizar(self)

	# 2. Postigos de ventanas 3D
	for w_node in _window_nodes_3d:
		var w_entry: Dictionary = w_node["entry"]
		var shutter: MeshInstance3D = w_node["shutter"]
		if is_instance_valid(shutter):
			shutter.visible = bool(w_entry.get("is_shuttered", false))

	# 3. Cofres abiertos / cerrados
	var wc = get_node_or_null("/root/WorldClock")
	var cur_d: int = int(wc.current_day) if wc != null else 1
	for ch_node in _chest_nodes_3d:
		var ch_entry: Dictionary = ch_node["entry"]
		var lid: MeshInstance3D = ch_node["lid"]
		if is_instance_valid(lid):
			lid.visible = (int(ch_entry.get("looted_day", -1)) != cur_d)

	# 4. Cuerpos en las 3 camillas de la Morgue
	var active_morgue: int = vm.morgue_active_corpses.size()
	for i in range(_morgue_body_nodes_3d.size()):
		if is_instance_valid(_morgue_body_nodes_3d[i]):
			_morgue_body_nodes_3d[i].visible = (i < active_morgue)

	# 5. Reja corredera de la celda de la Comisaría (cerrada en x=889.5; abierta se desliza tras la reja fija en x=867.5)
	if is_instance_valid(_jail_gate_pivot_3d):
		var gate_locked: bool = is_instance_valid(vm._jail_cell_gate_col) and not vm._jail_cell_gate_col.disabled
		var recorrido: float = 0.0 if gate_locked else REJA_CELDA_RECORRIDO_PX
		_jail_gate_pivot_3d.position = _reja_celda_cerrada + Vector3.LEFT * recorrido * WORLD_SCALE

	# 6. Visibilidad de las alcantarillas y del club del sótano (-1): al bajar bajo el pueblo, ocultar superficie 3D para ver las galerías limpias igual que en 2D
	var in_sewers: bool = VillageUnderworldScript.is_player_in_sewers(vm)
	var in_club: bool = load("res://scripts/systems/VillageClub.gd").is_player_in_club(vm)
	var underground_view: bool = in_sewers or in_club
	if is_instance_valid(sewers_root_3d):
		sewers_root_3d.visible = in_sewers
	for techo in get_tree().get_nodes_in_group("techo_bajo_tierra_3d"):
		(techo as Node3D).visible = first_person_active
	_sync_club_3d()
	if is_instance_valid(buildings_root_3d):
		buildings_root_3d.visible = not underground_view
	if is_instance_valid(lots_root_3d):
		lots_root_3d.visible = not underground_view
	if is_instance_valid(nature_root_3d):
		nature_root_3d.visible = not underground_view
	if is_instance_valid(streetlights_root_3d):
		streetlights_root_3d.visible = not underground_view

	# 7. Piloto luminoso del Cuadro Eléctrico del Taller y objeto físico del robo activo (Bloque FIS2)
	if is_instance_valid(_grid_panel_bulb_3d):
		var sab_on: bool = VillageCulture.is_grid_sabotaged(vm)
		_grid_panel_bulb_3d.material_override = _mat("grid_bulb_err", Color(1.0, 0.25, 0.18), 0.2, 0.0, Color(1.0, 0.20, 0.12), 2.8) if sab_on else _mat("tinker_screen", Color(0.32, 0.96, 0.82), 0.2, 0.0, Color(0.24, 0.92, 0.76), 2.4)
	_sync_heist_target_3d()
	_sync_town_ledger_3d()
	_sync_home_props_3d()

func _sync_home_props_3d() -> void:
	if vm == null or stage_root_3d == null:
		return
	var p_lots: Array[String] = VillageHousingScript.player_lots(vm, true)
	var hs: Dictionary = VillageHousingScript.state(vm)
	var prim_lot: String = VillageHousingScript.primary_player_lot(vm)
	var has_shop: bool = VillageHousingScript.has_player_shop(vm)
	var ps: Dictionary = hs.get("player_shop", {}) if has_shop else {}
	var shop_lot: String = VillageHousingScript.player_shop_lot(vm) if has_shop else ""
	var parts: PackedStringArray = PackedStringArray()
	for lid in p_lots:
		var st: Dictionary = VillageLots.lot(vm, lid)
		var up: Dictionary = st.get("upgrades", {})
		var wb: int = 1 if bool(up.get("workbench", false)) else 0
		var st_fl: int = 1 if (lid == prim_lot and bool(hs.get("has_stash", false))) else 0
		var up_fl: int = 1 if bool(up.get("upper_floor", false)) else 0
		var cel_fl: int = 1 if bool(up.get("hidden_cellar", false)) else 0
		var sh_fl: int = 1 if (has_shop and lid == shop_lot) else 0
		var sh_stk: int = clampi(int(ps.get("stock", 0)), 0, 4) if sh_fl == 1 else 0
		var sh_till: int = (1 if int(ps.get("till_gold", 0)) > 0 else 0) if sh_fl == 1 else 0
		var tb_rat: int = clampi(int(hs.get("table_rations", 0)), 0, 12) if lid == prim_lot else 0
		parts.append("%s:%d:%d:%d:%d:%d:%d:%d:%d" % [lid, wb, st_fl, up_fl, cel_fl, sh_fl, sh_stk, sh_till, tb_rat])
	var sig: String = "|".join(parts)
	if sig == _last_home_props_sig and (sig.is_empty() or is_instance_valid(_home_props_3d)):
		return
	_last_home_props_sig = sig
	if is_instance_valid(_home_props_3d):
		_home_props_3d.queue_free()
		_home_props_3d = null
	if sig.is_empty():
		return
	var root: Node3D = Node3D.new()
	root.name = "HomeProps3D"
	stage_root_3d.add_child(root)
	_home_props_3d = root
	mover_posiciones = true # los muebles de la casa están escritos en el mapa original: siguen a la casa

	var m_oak: StandardMaterial3D = _mat("hp_oak", Color(0.46, 0.30, 0.16), 0.85, 0.05)
	var m_dark: StandardMaterial3D = _mat("hp_dark", Color(0.14, 0.10, 0.06), 0.95, 0.0)
	var m_iron: StandardMaterial3D = _mat("hp_iron", Color(0.28, 0.32, 0.36), 0.45, 0.75)
	var m_gold: StandardMaterial3D = _mat("hp_gold", Color(0.95, 0.78, 0.24), 0.25, 0.85, Color(0.92, 0.74, 0.20), 0.55)
	var m_herb: StandardMaterial3D = _mat("hp_herb", Color(0.30, 0.82, 0.38), 0.45, 0.10, Color(0.20, 0.65, 0.28), 0.35)
	var m_dust: StandardMaterial3D = _mat("hp_dust", Color(0.74, 0.44, 0.96), 0.30, 0.15, Color(0.66, 0.36, 0.90), 0.55)

	for lid in p_lots:
		var st: Dictionary = VillageLots.lot(vm, lid)
		var up: Dictionary = st.get("upgrades", {})
		var tb_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_table")
		_add_box_2d(root, tb_pos, Vector2(18.0, 10.6), 2.0, 6.2, m_oak) # Mesa de comedor
		_add_box_2d(root, tb_pos, Vector2(19.4, 11.6), 7.8, 1.0, m_oak) # Tablero de la mesa
		if lid == prim_lot and int(hs.get("table_rations", 0)) > 0:
			_add_cyl_2d(root, tb_pos + Vector2(-3.2, -0.5), 2.2, 8.8, 1.4, m_gold, 2.0, 8) # Hogaza / plato en la mesa
			_add_cyl_2d(root, tb_pos + Vector2(3.2, 0.5), 2.0, 8.8, 2.0, m_herb, 1.6, 8) # Guiso / viandas
		if bool(up.get("workbench", false)):
			var wb_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_workbench")
			if _add_model_2d(root, "props/Workbench_Drawers.gltf", wb_pos, 2.0, Vector2(18.0, 10.0), 8.2) == null:
				_add_box_2d(root, wb_pos, Vector2(18.0, 10.0), 2.0, 7.5, m_oak)
			_add_cyl_2d(root, wb_pos + Vector2(-4.0, -0.5), 2.2, 9.5, 2.6, m_herb, 1.8, 8) # Mortero con cataplasma
			_add_cyl_2d(root, wb_pos + Vector2(3.5, -0.5), 2.0, 9.5, 3.8, m_dust, 1.0, 10) # Alambique de polvo de ocaso
		if lid == prim_lot and bool(hs.get("has_stash", false)):
			var st_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_stash")
			_add_box_2d(root, st_pos, Vector2(13.0, 9.5), 1.8, 0.8, m_dark) # Hueco bajo el suelo
			_add_box_2d(root, st_pos + Vector2(-3.2, 0), Vector2(4.2, 8.8), 2.2, 1.2, m_oak) # Tabla izq
			_add_box_2d(root, st_pos + Vector2(3.4, -0.6), Vector2(4.2, 8.8), 2.6, 1.4, m_oak) # Tabla entreabierta der
			_add_cyl_2d(root, st_pos + Vector2(0, 0.8), 2.2, 2.2, 1.2, m_gold, 2.2, 8) # Monedas ocultas
		# Paso a 3D, paso 2e: el piso alto es un suelo de madera a Suelo.ALTILLO_CASA_PX sobre toda la casa (se ve en
		# 1.ª persona o estando arriba: desde arriba taparía la planta baja) y el sótano, una sala de piedra bajo tierra.
		var d_lot: Dictionary = VillageLots.lot_def(lid)
		if bool(up.get("upper_floor", false)):
			var altillo := _add_box_2d(root, d_lot["center"], (d_lot["size"] as Vector2) - Vector2(6.0, 6.0), Suelo.ALTILLO_CASA_PX - 1.4, 1.4, m_oak)
			if altillo != null:
				altillo.add_to_group("altillo_casa_3d")
		if bool(up.get("hidden_cellar", false)):
			var m_piedra: StandardMaterial3D = _mat("hp_piedra", Color(0.34, 0.33, 0.31), 0.95, 0.0)
			var sotano := Node3D.new()
			sotano.position.y = Mapa3D.alto_a_3d(Suelo.PROFUNDIDAD_SOTANO_PX)
			root.add_child(sotano)
			_add_box_2d(sotano, d_lot["center"], (d_lot["size"] as Vector2) - Vector2(6.0, 6.0), -1.0, 1.0, m_piedra) # suelo
			_add_techo_roca(sotano, d_lot["center"], d_lot["size"], m_piedra)
		if bool(up.get("upper_floor", false)) or bool(up.get("hidden_cellar", false)):
			var sr_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_stairs")
			_add_box_2d(root, sr_pos, Vector2(13.0, 14.0), 1.8, 1.2, m_dark) # Trampilla / base
			_add_box_2d(root, sr_pos, Vector2(11.6, 12.6), 2.4, 1.4, m_oak)
			_add_box_2d(root, sr_pos + Vector2(4.0, 0), Vector2(1.8, 1.8), 3.6, 1.2, m_iron) # Argolla de hierro
			if bool(up.get("upper_floor", false)):
				for step_i in range(4):
					var sy: float = -4.5 + float(step_i) * 3.0
					var sh: float = 4.0 + float(step_i) * 4.2
					_add_box_2d(root, sr_pos + Vector2(0, sy), Vector2(10.0, 2.2), sh, 1.6, m_oak)
		if has_shop and lid == shop_lot:
			var sc_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "player_shop_counter")
			_add_box_2d(root, sc_pos, Vector2(18.0, 9.2), 2.0, 6.8, m_oak) # Cuerpo del mostrador
			_add_box_2d(root, sc_pos, Vector2(19.6, 10.4), 8.6, 1.2, m_oak) # Tablero del mostrador
			_add_box_2d(root, sc_pos + Vector2(4.6, -0.2), Vector2(5.2, 4.4), 9.8, 2.6, m_iron) # Caja de recaudación
			if int(ps.get("till_gold", 0)) > 0:
				_add_cyl_2d(root, sc_pos + Vector2(4.6, -0.2), 1.8, 12.2, 1.2, m_gold, 1.8, 8) # Monedas en la caja
			if int(ps.get("stock", 0)) > 0:
				_add_box_2d(root, sc_pos + Vector2(-4.8, -0.4), Vector2(3.8, 3.6), 9.8, 2.4, m_herb) # Mercancía expuesta 1
				if int(ps.get("stock", 0)) >= 2:
					_add_box_2d(root, sc_pos + Vector2(-1.2, 0.4), Vector2(3.6, 3.4), 9.8, 2.2, m_gold) # Mercancía expuesta 2
	mover_posiciones = false

## Paso a 3D, paso 2b: techo de roca justo bajo la calle sobre una sala subterránea (dentro de `raiz`, que ya está
## bajada Suelo.PROFUNDIDAD_SOTANO_PX). Solo se ve en 1.ª persona: desde arriba taparía la sala.
func _add_techo_roca(raiz: Node3D, centro: Vector2, tam: Vector2, mat: Material) -> void:
	var grosor: float = 2.0
	var techo := _add_box_2d(raiz, centro, tam, -Suelo.PROFUNDIDAD_SOTANO_PX - grosor - 0.5, grosor, mat)
	if techo != null:
		techo.add_to_group("techo_bajo_tierra_3d")


## P6: sala del club de pelea (se construye una vez; solo se ve estando dentro).
## Reñidero de la Cisterna (fallo visible «alcantarillas vacías», 2026-11-11): un cuadrilátero de cuerdas con sus postes,
## bancos, la mesa del apostador con su pizarra y una pintada que manda a las peleas de verdad (el club bajo la posada).
## Solo se ve: nada choca (la cámara es estrecha y los vecinos no bajan aquí).
func _vestir_renidero_3d(c: Vector2, m_wood: Material, m_iron: Material, m_brass: Material) -> void:
	var r := sewers_root_3d
	var suelo: float = 4.6
	var m_cuerda := _mat("sewer_rope", Color(0.72, 0.60, 0.36), 0.92, 0.0)
	var m_serrin := _mat("sewer_sawdust", Color(0.46, 0.33, 0.20), 0.95, 0.0)
	var m_sangre := _mat("sewer_blood", Color(0.30, 0.08, 0.06), 0.90, 0.0)
	var m_pizarra := _mat("sewer_slate", Color(0.10, 0.11, 0.10), 0.85, 0.0)
	var m_tiza := _mat("sewer_chalk", Color(0.92, 0.92, 0.88), 0.80, 0.0)
	# Cuadrilátero: serrín, manchas, 4 postes y 2 alturas de cuerda
	_add_box_2d(r, c + Vector2(0.0, -8.0), Vector2(34.0, 26.0), suelo, 0.3, m_serrin)
	for mancha in [Vector2(-5.0, -12.0), Vector2(7.0, -3.0), Vector2(2.0, 2.0)]:
		_add_box_2d(r, c + mancha, Vector2(3.5, 2.5), suelo + 0.32, 0.1, m_sangre, randf() * 60.0)
	for px in [-17.0, 17.0]:
		for py in [-21.0, 5.0]:
			_add_cyl_2d(r, c + Vector2(px, py), 1.1, suelo, 11.0, m_wood, 1.1, 6)
		for h in [suelo + 5.0, suelo + 9.0]:
			_add_box_2d(r, c + Vector2(px, -8.0), Vector2(0.7, 26.0), h, 0.7, m_cuerda)
	for py in [-21.0, 5.0]:
		for h in [suelo + 5.0, suelo + 9.0]:
			_add_box_2d(r, c + Vector2(0.0, py), Vector2(34.0, 0.7), h, 0.7, m_cuerda)
	# Bancos del público: uno pegado al muro norte, otro en el lado oeste
	for banco in [[Vector2(0.0, -34.0), Vector2(26.0, 5.0)], [Vector2(-38.0, -8.0), Vector2(5.0, 24.0)]]:
		_add_box_2d(r, banco[0], banco[1], suelo + 3.5, 1.2, m_wood)
		var hb: Vector2 = (banco[1] as Vector2) * 0.5 - Vector2(1.5, 1.5)
		for esquina in [Vector2(-hb.x, -hb.y), Vector2(hb.x, -hb.y), Vector2(-hb.x, hb.y), Vector2(hb.x, hb.y)]:
			_add_box_2d(r, (banco[0] as Vector2) + esquina, Vector2(1.4, 1.4), suelo, 3.5, m_wood)
	# Mesa del apostador (lado este) con monedas, y pizarra de apuestas en el muro
	var mesa: Vector2 = c + Vector2(37.0, -6.0)
	_add_box_2d(r, mesa, Vector2(12.0, 9.0), suelo + 6.0, 1.0, m_wood)
	for pata in [Vector2(-5.0, -3.5), Vector2(5.0, -3.5), Vector2(-5.0, 3.5), Vector2(5.0, 3.5)]:
		_add_box_2d(r, mesa + pata, Vector2(1.2, 1.2), suelo, 6.0, m_wood)
	for moneda in [Vector2(-2.5, -1.0), Vector2(1.0, 1.5), Vector2(3.0, -2.0)]:
		_add_cyl_2d(r, mesa + moneda, 0.9, suelo + 7.0, 0.3, m_brass, 0.9, 8)
	_add_box_2d(r, mesa + Vector2(0.0, 2.0), Vector2(3.0, 2.0), suelo + 7.0, 1.2, m_iron) # caja de apuestas
	_add_box_2d(r, c + Vector2(53.0, -8.0), Vector2(1.0, 16.0), suelo + 8.0, 10.0, m_pizarra)
	for raya in range(4):
		_add_box_2d(r, c + Vector2(52.3, -13.0 + float(raya) * 3.2), Vector2(0.4, 8.0 - float(raya) * 1.5), suelo + 15.5 - float(raya) * 2.0, 0.5, m_tiza)
	if _is_headless:
		return
	var pintada := Label3D.new()
	pintada.text = "PELEAS · SÓTANO DEL JABALÍ\nNOCHES PARES · A LAS 23"
	pintada.font_size = 48
	pintada.pixel_size = 0.0022 * Mapa3D.K
	pintada.modulate = Color(0.90, 0.88, 0.80, 0.85)
	pintada.position = to_3d(c + Vector2(0.0, -39.0), suelo + 12.0) # en el muro norte, mirando al sur (hacia el reñidero)
	r.add_child(pintada)
	var luz := OmniLight3D.new()
	luz.position = to_3d(c + Vector2(0.0, -8.0), 18.0)
	luz.light_color = Color(1.0, 0.72, 0.40)
	luz.light_energy = 1.2
	luz.omni_range = 3.0 * Mapa3D.K
	r.add_child(luz)

func _sync_club_3d() -> void:
	if vm == null or stage_root_3d == null:
		return
	var Club = load("res://scripts/systems/VillageClub.gd")
	if not is_instance_valid(_club_root_3d):
		_club_root_3d = Node3D.new()
		_club_root_3d.name = "FightClub3D"
		_club_root_3d.position.y = Mapa3D.alto_a_3d(Suelo.PROFUNDIDAD_SOTANO_PX) # paso a 3D, paso 2b: de verdad bajo tierra
		stage_root_3d.add_child(_club_root_3d)
		var m_rock := _mat("sewer_bedrock", Color(0.08, 0.10, 0.09), 0.96, 0.0)
		var m_dirt := _mat("club_dirt", Color(0.36, 0.27, 0.18), 0.95, 0.0)
		var m_stone := _mat("sewer_brick", Color(0.28, 0.34, 0.30), 0.90, 0.05, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.35)
		var m_rope := _mat("club_rope", Color(0.78, 0.66, 0.42), 0.9, 0.0)
		var m_wood := _mat("sewer_wood", Color(0.46, 0.30, 0.16), 0.85, 0.04)
		var m_iron := _mat("sewer_iron", Color(0.24, 0.27, 0.32), 0.42, 0.78)
		var m_torch := _mat("sewer_torch", Color(1.0, 0.76, 0.32), 0.20, 0.0, Color(1.0, 0.68, 0.22), 2.8)
		var c: Vector2 = Club.CLUB_CENTER
		var sz: Vector2 = Club.CLUB_SIZE
		_add_box_2d(_club_root_3d, c, sz + Vector2(80, 80), 0.0, 1.0, m_rock)
		_add_techo_roca(_club_root_3d, c, sz + Vector2(80, 80), m_rock)
		_add_box_2d(_club_root_3d, c, sz, 1.0, 1.2, m_dirt)
		_add_box_2d(_club_root_3d, c + Vector2(0, -sz.y * 0.5 - 3), Vector2(sz.x + 12, 6), 2.0, 22.0, m_stone) # muro norte alto
		_add_box_2d(_club_root_3d, c + Vector2(0, sz.y * 0.5 + 3), Vector2(sz.x + 12, 6), 2.0, 5.0, m_stone) # zócalo sur bajo
		_add_box_2d(_club_root_3d, c + Vector2(-sz.x * 0.5 - 3, 0), Vector2(6, sz.y), 2.0, 22.0, m_stone)
		_add_box_2d(_club_root_3d, c + Vector2(sz.x * 0.5 + 3, 0), Vector2(6, sz.y), 2.0, 22.0, m_stone)
		# Corro: 12 postes y cuerda entre ellos
		var r: float = Club.RING_RADIUS
		for i in range(12):
			var a0: float = TAU * float(i) / 12.0
			var a1: float = TAU * float(i + 1) / 12.0
			var p0: Vector2 = c + Vector2(cos(a0), sin(a0)) * r
			var p1: Vector2 = c + Vector2(cos(a1), sin(a1)) * r
			_add_cyl_2d(_club_root_3d, p0, 1.2, 2.2, 9.0, m_wood, 1.2, 6)
			var mid: Vector2 = (p0 + p1) * 0.5
			_add_box_2d(_club_root_3d, mid, Vector2(maxf(absf(p1.x - p0.x), 1.2), maxf(absf(p1.y - p0.y), 1.2)), 8.0, 0.8, m_rope)
		# Escalerilla de subida a la trampilla
		var lad: Vector2 = Club.LADDER_POS
		_add_box_2d(_club_root_3d, lad + Vector2(-4, -6), Vector2(1.4, 2.0), 2.4, 22.0, m_iron)
		_add_box_2d(_club_root_3d, lad + Vector2(4, -6), Vector2(1.4, 2.0), 2.4, 22.0, m_iron)
		for k in range(6):
			_add_box_2d(_club_root_3d, lad + Vector2(0, -6), Vector2(8.0, 1.2), 4.0 + float(k) * 3.2, 0.9, m_wood)
		# Faroles en las esquinas
		for off in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			var tp: Vector2 = c + Vector2(off.x * (sz.x * 0.5 - 8), off.y * (sz.y * 0.5 - 8))
			_add_cyl_2d(_club_root_3d, tp, 1.4, 2.0, 10.0, m_wood, 1.0, 6)
			_add_cyl_2d(_club_root_3d, tp, 2.2, 12.0, 3.0, m_torch, 1.4, 8)
			if not _is_headless:
				var lt := OmniLight3D.new()
				lt.position = to_3d(tp, 16.0)
				lt.light_color = Color(1.0, 0.78, 0.42)
				lt.light_energy = 1.2
				lt.omni_range = 3.4 * Mapa3D.K
				_club_root_3d.add_child(lt)
		# Trampilla en la sala trasera de escalera/bodega de la taberna (sobre la losa del suelo en h = 2.5)
		var trap := Node3D.new()
		trap.name = "ClubTrapdoor3D"
		stage_root_3d.add_child(trap)
		var closed_lid := Node3D.new()
		closed_lid.name = "ClosedLid"
		trap.add_child(closed_lid)
		_add_box_2d(closed_lid, Club.TRAPDOOR_POS, Vector2(16.0, 14.0), 2.5, 1.1, m_wood)
		_add_box_2d(closed_lid, Club.TRAPDOOR_POS + Vector2(0, 4.2), Vector2(12.0, 1.3), 3.6, 0.6, m_iron)
		_add_box_2d(closed_lid, Club.TRAPDOOR_POS + Vector2(0, -4.2), Vector2(12.0, 1.3), 3.6, 0.6, m_iron)
		var open_hatch := Node3D.new()
		open_hatch.name = "OpenHatch"
		trap.add_child(open_hatch)
		# Marco de madera, hueco oscuro hacia el sótano (-1), hoja levantada al norte y peldaños de escalera asomando
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(0, -7.2), Vector2(16.0, 1.6), 2.5, 1.4, m_wood)
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(0, 7.2), Vector2(16.0, 1.6), 2.5, 1.4, m_wood)
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(-7.8, 0), Vector2(1.6, 13.0), 2.5, 1.4, m_wood)
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(7.8, 0), Vector2(1.6, 13.0), 2.5, 1.4, m_wood)
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS, Vector2(13.6, 12.2), 2.45, 0.4, m_rock) # Pozo oscuro abierto
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(0, -7.8), Vector2(15.2, 1.8), 3.2, 11.5, m_wood) # Tapa abierta levantada
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(0, -6.8), Vector2(12.0, 0.6), 6.0, 1.2, m_iron) # Herraje interior
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(-4.0, -1.5), Vector2(1.2, 1.4), 1.5, 4.8, m_iron) # Larguero izq
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(4.0, -1.5), Vector2(1.2, 1.4), 1.5, 4.8, m_iron) # Larguero der
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(0, -1.5), Vector2(7.4, 1.0), 3.2, 0.8, m_wood) # Peldaño superior
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(0, 1.5), Vector2(7.4, 1.0), 2.6, 0.8, m_torch) # Resplandor cálido del sótano
		if not _is_headless:
			var t_lt := OmniLight3D.new()
			t_lt.position = to_3d(Club.TRAPDOOR_POS, 5.5)
			t_lt.light_color = Color(1.0, 0.72, 0.28)
			t_lt.light_energy = 1.35
			t_lt.omni_range = 1.8 * Mapa3D.K
			open_hatch.add_child(t_lt)
	var in_club_now: bool = Club.is_player_in_club(vm)
	var open_now: bool = Club.is_open_now(vm)
	_club_root_3d.visible = in_club_now
	var trap_node := stage_root_3d.get_node_or_null("ClubTrapdoor3D") as Node3D
	if is_instance_valid(trap_node):
		trap_node.visible = not in_club_now
		var cl_n := trap_node.get_node_or_null("ClosedLid") as Node3D
		var op_n := trap_node.get_node_or_null("OpenHatch") as Node3D
		if is_instance_valid(cl_n):
			cl_n.visible = not open_now
		if is_instance_valid(op_n):
			op_n.visible = open_now

## P5: libro de cuentas abierto sobre la mesa del ayuntamiento (se construye una vez).
func _sync_town_ledger_3d() -> void:
	if vm == null or stage_root_3d == null or is_instance_valid(_town_ledger_3d):
		return
	var pos: Vector2 = vm.sitio(load("res://scripts/systems/VillageCollections.gd").ledger_pos()) # en el mundo (mapa ×E)
	var root := Node3D.new()
	root.name = "TownLedger3D"
	stage_root_3d.add_child(root)
	_town_ledger_3d = root
	var m_leather := _mat("ledger_leather", Color(0.40, 0.20, 0.10), 0.82, 0.05)
	var m_page := _mat("heist_page", Color(0.95, 0.90, 0.76), 0.85, 0.0)
	_add_box_2d(root, pos, Vector2(12.0, 8.0), 10.2, 1.0, m_leather) # Tapas abiertas
	_add_box_2d(root, pos + Vector2(-2.9, 0), Vector2(5.4, 6.8), 11.2, 0.8, m_page) # Página izquierda
	_add_box_2d(root, pos + Vector2(2.9, 0), Vector2(5.4, 6.8), 11.2, 0.8, m_page) # Página derecha

func _sync_heist_target_3d() -> void:
	if vm == null or stage_root_3d == null:
		return
	var ah: Dictionary = VillageUnderworldScript.state(vm).get("active_heist", {})
	var active: bool = (not ah.is_empty()) and (not bool(ah.get("stolen", false)))
	var sig: String = "%s|%d|%d" % [str(ah.get("id", "")), int(ah.get("pos_x", 0)), int(ah.get("pos_y", 0))] if active else ""
	if sig == _last_heist_sig and (not active or is_instance_valid(_heist_prop_3d)):
		return
	_last_heist_sig = sig
	if is_instance_valid(_heist_prop_3d):
		_heist_prop_3d.queue_free()
		_heist_prop_3d = null
	if not active:
		return
	var h_id: String = str(ah.get("id", "sello_noble"))
	var h_pos := Vector2(float(ah.get("pos_x", 0.0)), float(ah.get("pos_y", 0.0)))
	var root := Node3D.new()
	root.name = "HeistTarget3D_" + h_id
	stage_root_3d.add_child(root)
	_heist_prop_3d = root

	var m_gold := _mat("heist_gold", Color(0.96, 0.80, 0.28), 0.25, 0.85, Color(0.95, 0.76, 0.22), 0.65)
	var m_silver := _mat("heist_silver", Color(0.88, 0.92, 0.98), 0.20, 0.90, Color(0.75, 0.85, 1.0), 0.55)
	var m_crimson := _mat("heist_crimson", Color(0.76, 0.14, 0.20), 0.75, 0.05)
	var m_leather := _mat("heist_leather", Color(0.42, 0.22, 0.12), 0.82, 0.05)
	var m_page := _mat("heist_page", Color(0.95, 0.90, 0.76), 0.85, 0.0)

	match h_id:
		"sello_noble":
			# Sobre el escritorio del estudio de la Mansión (altura base ~10.2 px)
			_add_box_2d(root, h_pos, Vector2(11.0, 9.0), 10.2, 2.2, m_crimson) # Cojín de terciopelo
			_add_cyl_2d(root, h_pos + Vector2(-2.0, 0.5), 2.6, 12.4, 1.4, m_crimson, 2.6, 10) # Lacre real
			_add_cyl_2d(root, h_pos + Vector2(1.8, -0.5), 2.2, 12.4, 5.2, m_gold, 1.5, 10) # Matriz de oro del sello
			_add_model_2d(root, "props/Scroll_1.gltf", h_pos + Vector2(-5.0, -2.0), 10.2, Vector2(7.0, 5.0), 3.5)
		"caliz_capilla":
			# Sobre el altar de piedra de la Capilla (altura base ~13.0 px)
			if _add_model_2d(root, "props/Chalice.gltf", h_pos, 13.0, Vector2(8.0, 8.0), 8.5) == null:
				_add_cyl_2d(root, h_pos, 3.2, 13.0, 1.8, m_silver, 2.4, 10)
				_add_cyl_2d(root, h_pos, 1.4, 14.8, 3.2, m_silver, 1.4, 10)
				_add_cyl_2d(root, h_pos, 2.6, 18.0, 3.6, m_gold, 3.8, 12)
			else:
				_add_cyl_2d(root, h_pos, 4.4, 12.4, 0.8, m_gold, 4.4, 12) # Patena dorada bajo el cáliz
		_:
			# Libro Mayor de los Gremios sobre la mesa del Ayuntamiento (altura base ~10.2 px)
			if _add_model_2d(root, "props/Book_5.gltf", h_pos, 10.2, Vector2(13.0, 10.0), 4.5) == null:
				_add_box_2d(root, h_pos, Vector2(13.0, 10.0), 10.2, 1.6, m_leather)
				_add_box_2d(root, h_pos, Vector2(11.4, 8.6), 11.8, 1.8, m_page)
			_add_box_2d(root, h_pos + Vector2(-5.8, 0), Vector2(1.4, 8.8), 10.2, 3.6, m_gold)
			_add_box_2d(root, h_pos + Vector2(5.8, 0), Vector2(1.4, 8.8), 10.2, 3.6, m_gold)


# ==============================================================================
# OBJETOS QUIETOS 2D -> 3D (pozos, farolas, tablón…)
# ==============================================================================
## Qué versión 3D lleva cada dibujo 2D, según el nombre de su imagen. "hide" = ya tiene 3D propio, solo se esconde.
const PROP_KIND_BY_TEXTURE := {
	"bench_0.png": "hide",
	"flowers_plants_0.png": "hide",
	"hay_0.png": "hide",
	"hay_2.png": "hide",
	"logs_0.png": "hide",
	"iron_sword.png": "weapon_sword",
	"steel_hammer.png": "weapon_hammer",
	"crate.png": "crate",
	"barrel.png": "barrel",
	"weak_wall.png": "weak_wall",
	"wild_herb.png": "wild_herb",
	"wild_mushroom.png": "wild_mushroom",
}

static func _tex_file(t: Texture2D) -> String:
	if t == null:
		return ""
	var src: String = t.resource_path if not t.resource_path.is_empty() else String(t.get_meta("src_path", ""))
	return src.get_file()


func _prop_kind_for(spr: Node2D) -> String:
	if spr.has_meta(META_TIPO_3D): # marca sin dibujo (2026-11-12) o dibujo que no basta para saber qué es
		return String(spr.get_meta(META_TIPO_3D))
	if not spr is Sprite2D:
		return ""
	var mapped: String = String(PROP_KIND_BY_TEXTURE.get(_tex_file((spr as Sprite2D).texture), ""))
	if not mapped.is_empty():
		return mapped
	var p: Node = spr.get_parent()
	if p != null and p.get_parent() != null and p.get_parent().name == "Items":
		return "dropped_item"
	return ""


## Busca los dibujos 2D de objetos quietos: hijos directos del pueblo, ecosistema (hierbas, setas, madrigueras) y objetos de la escena.
func _scan_props_sources() -> void:
	_prop_sources.clear()
	if vm == null or not is_instance_valid(vm.entities_root):
		return
	for c in vm.entities_root.get_children():
		if c is Sprite2D or (c is Node2D and c.has_meta(META_TIPO_3D)):
			_add_prop_source(c as Node2D)
		elif c is Node2D and String(c.name).begins_with("PetBed_"):
			_build_pet_bed_3d_for(c as Node2D)
	for eco in get_tree().get_nodes_in_group("ecosystem_manager"):
		_collect_child_sprites(eco)
	var w_root: Node = vm.get_parent()
	if w_root != null and is_instance_valid(w_root):
		for container_name in ["Items", "Environment"]:
			var cont: Node = w_root.get_node_or_null(container_name)
			if cont != null:
				_collect_child_sprites(cont)
	_sync_props_3d(false)


func _build_pet_bed_3d_for(bed_node: Node2D) -> void:
	if nature_root_3d == null or bed_node == null:
		return
	var b_name := "PetBed3D_" + String(bed_node.name)
	var old := nature_root_3d.get_node_or_null(b_name)
	if old != null:
		old.queue_free()
	var root := Node3D.new()
	root.name = b_name
	nature_root_3d.add_child(root)
	var pos: Vector2 = bed_node.global_position
	var is_dog: bool = int(bed_node.get_meta("pet_type", 0)) == 0
	var m_frame := _mat("pet_bed_wood", Color(0.46, 0.30, 0.16), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.75)
	var m_cush := _mat("pet_bed_cush_dog" if is_dog else "pet_bed_cush_cat", Color(0.74, 0.28, 0.24) if is_dog else Color(0.72, 0.54, 0.38), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.65)
	var m_bowl := _mat("pet_bowl_brass", Color(0.82, 0.68, 0.30), 0.38, 0.65)
	var m_water := _mat("pet_bowl_water", Color(0.22, 0.56, 0.82), 0.20, 0.10)
	_add_box_2d(root, pos, Vector2(19.0, 11.0), 0.0, 2.2, m_frame)
	_add_box_2d(root, pos + Vector2(0, -4.8), Vector2(19.0, 1.8), 2.2, 2.0, m_frame)
	_add_box_2d(root, pos + Vector2(-8.6, 0), Vector2(1.8, 11.0), 2.2, 1.8, m_frame)
	_add_box_2d(root, pos + Vector2(8.6, 0), Vector2(1.8, 11.0), 2.2, 1.8, m_frame)
	_add_box_2d(root, pos + Vector2(0, 0.5), Vector2(15.0, 7.6), 1.8, 1.8, m_cush)
	_add_cyl_2d(root, pos + Vector2(13.5, 1.0), 2.8, 0.0, 2.2, m_bowl, 2.4, 10)
	_add_cyl_2d(root, pos + Vector2(13.5, 1.0), 2.1, 1.6, 0.8, m_water, 2.1, 10)


func _add_prop_source(spr: Node2D) -> void:
	var kind := _prop_kind_for(spr)
	if not kind.is_empty():
		_prop_sources.append({"sprite": spr, "kind": kind})


## Recorre un nodo y sus hijos buscando dibujos o marcas con versión 3D.
func _collect_child_sprites(n: Node) -> void:
	for c in n.get_children():
		if c is Sprite2D or c.has_meta(META_TIPO_3D):
			_add_prop_source(c as Node2D)
		if c.get_child_count() > 0:
			_collect_child_sprites(c)


func _sync_props_3d(only_update: bool) -> void:
	if nature_root_3d == null:
		return
	var alive: Dictionary = {}
	for src in _prop_sources:
		var spr_v = src["sprite"]
		if not is_instance_valid(spr_v):
			continue # p. ej. el cartel de un solar que ya se construyó
		var spr: Node2D = spr_v
		var id := spr.get_instance_id()
		alive[id] = true
		var kind: String = src["kind"]
		var variant := kind
		var rec: Dictionary = _prop_nodes.get(id, {})
		var stale: bool = not rec.is_empty() and (String(rec.get("variant", "")) != variant or (rec.get("pos", Vector2.ZERO) as Vector2).distance_squared_to(spr.global_position) > 0.25)
		if stale:
			var old_root = rec.get("root")
			if old_root is Node3D and is_instance_valid(old_root):
				(old_root as Node3D).queue_free()
			rec = {}
		if rec.is_empty() and (not only_update or stale) and kind != "hide":
			var root := Node3D.new()
			root.name = "Prop3D_" + kind
			nature_root_3d.add_child(root)
			_build_prop_3d(root, kind, spr)
			if spr.has_meta("giro_3d"): # su ancla se giró en el editor del mapa 3D
				var piv: Vector3 = to_3d(spr.global_position, 0.0)
				var gb := Basis(Vector3.UP, deg_to_rad(float(spr.get_meta("giro_3d"))))
				root.transform = Transform3D(gb, piv - gb * piv)
			rec = {"root": root, "variant": variant, "pos": spr.global_position}
			_prop_nodes[id] = rec
		var r3 = rec.get("root")
		if r3 is Node3D and is_instance_valid(r3):
			(r3 as Node3D).visible = spr.is_visible_in_tree() and (not spr is Sprite2D or (spr as Sprite2D).texture != null)
		spr.self_modulate.a = 0.0
	_sync_sabotage_fx_3d()
	if only_update:
		return
	for id in _prop_nodes.keys():
		if not alive.has(id):
			var r = _prop_nodes[id].get("root")
			if r is Node3D and is_instance_valid(r):
				(r as Node3D).queue_free()
			_prop_nodes.erase(id)


func _build_prop_3d(root: Node3D, kind: String, spr: Node2D) -> void:
	var pos: Vector2 = spr.global_position
	# Mismos valores que tenía la madera del terreno, que antes se creaba primero con este nombre y era la que salía
	var m_wood := _mat("prop_wood", Color(0.54, 0.36, 0.20), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_dark := _mat("prop_dark_wood", Color(0.38, 0.24, 0.13), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_iron := _mat("prop_iron", Color(0.30, 0.31, 0.33), 0.6, 0.5)
	match kind:
		"well":
			if _add_model_2d(root, "exterior/Well.obj", pos, 0.0, Vector2.ZERO, 24.0) == null:
				_add_cyl_2d(root, pos, 8.5, 0.0, 7.5, _mat("well_stone", Color(0.58, 0.57, 0.54), 0.9, 0.02), 8.5, 14)
		"tent":
			var m_canvas := _mat("tent_canvas", Color(0.84, 0.74, 0.54), 0.88, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "town_textures/T_Trim_Cloth_Normal.png", 0.55)
			var m_flap := _mat("tent_flap", Color(0.72, 0.60, 0.42), 0.90, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.65)
			var m_bedroll := _mat("tent_bedroll", Color(0.58, 0.24, 0.20), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.70)
			var m_pillow := _mat("tent_pillow", Color(0.92, 0.88, 0.78), 0.90, 0.0)
			# Plataforma base de madera + cuerpo principal de lona a dos aguas + cumbrera y postes de madera
			_add_box_2d(root, pos + Vector2(0, 2), Vector2(34, 24), 0.0, 1.6, m_dark)
			_add_prism_2d(root, pos + Vector2(0, 2), Vector2(32, 22), 1.4, 17.5, m_canvas, false)
			_add_box_2d(root, pos + Vector2(0, 2), Vector2(3.0, 25.0), 17.2, 2.2, m_dark)
			_add_cyl_2d(root, pos + Vector2(0, -9.2), 1.4, 1.4, 17.6, m_dark, 1.4, 8)
			_add_cyl_2d(root, pos + Vector2(0, 13.2), 1.3, 1.4, 17.6, m_dark, 1.3, 8)
			# Entrada abierta con faldones enrollados e interior con saco de dormir y almohada 3D
			_add_box_2d(root, pos + Vector2(0, 12.6), Vector2(8.5, 1.2), 1.6, 10.5, _mat("tent_door", Color(0.16, 0.12, 0.09), 0.96, 0.0))
			_add_cyl_2d(root, pos + Vector2(-4.8, 13.0), 1.6, 1.6, 11.2, m_flap, 1.4, 8)
			_add_cyl_2d(root, pos + Vector2(4.8, 13.0), 1.6, 1.6, 11.2, m_flap, 1.4, 8)
			_add_box_2d(root, pos + Vector2(0, 4.5), Vector2(8.0, 13.0), 1.6, 2.2, m_bedroll)
			_add_box_2d(root, pos + Vector2(0, -0.5), Vector2(6.8, 3.4), 3.6, 1.4, m_pillow)
			# Estacas y vientos tensores en las 4 esquinas
			for stake_off in [Vector2(-18.5, -8.5), Vector2(18.5, -8.5), Vector2(-18.5, 12.5), Vector2(18.5, 12.5)]:
				_add_cyl_2d(root, pos + stake_off, 1.0, 0.0, 4.2, m_dark, 0.8, 6)
				_add_box_2d(root, pos + stake_off * 0.82, Vector2(3.6, 0.9), 2.5, 1.2, m_wood)
		"campfire":
			var m_stone_ring := _mat("campfire_stone", Color(0.48, 0.46, 0.44), 0.92, 0.02)
			var m_ember := _mat("campfire_ember", Color(0.95, 0.34, 0.08), 0.40, 0.0, Color(1.0, 0.36, 0.06), 2.4)
			var m_flame := _mat("campfire_flame", Color(1.0, 0.72, 0.18), 0.25, 0.0, Color(1.0, 0.58, 0.10), 3.0)
			var m_stew := _mat("campfire_stew", Color(0.76, 0.42, 0.18), 0.35, 0.05)
			for i in range(8):
				var ang: float = float(i) * TAU / 8.0
				_add_box_2d(root, pos + Vector2(cos(ang), sin(ang)) * 7.2, Vector2(3.8, 3.2), 0.0, 2.6, m_stone_ring, rad_to_deg(ang))
			_add_cyl_2d(root, pos, 5.8, 0.0, 1.6, m_ember, 5.2, 10)
			_add_box_2d(root, pos, Vector2(13.0, 2.4), 0.8, 2.2, m_dark, 28.0)
			_add_box_2d(root, pos, Vector2(13.0, 2.4), 0.8, 2.2, m_dark, -32.0)
			_add_cyl_2d(root, pos + Vector2(-1.8, 0.8), 2.4, 1.4, 4.8, m_flame, 0.4, 7)
			_add_cyl_2d(root, pos + Vector2(1.8, -0.6), 2.0, 1.4, 4.2, m_flame, 0.3, 7)
			_add_model_2d(root, "exterior/Bonfire_Lit.obj", pos, 0.0, Vector2(16, 16), 9.0)
			_add_model_2d(root, "exterior/Cauldron.obj", pos, 3.2, Vector2(11, 11), 7.8)
			_add_cyl_2d(root, pos, 3.8, 8.8, 1.2, m_stew, 3.8, 10)
			# Trípode de hierro forjado sosteniendo la cacerola sobre la hoguera
			for t_ang in [-2.1, 0.0, 2.1]:
				var leg_p := pos + Vector2(cos(t_ang), sin(t_ang)) * 5.2
				_add_cyl_2d(root, leg_p, 0.75, 0.0, 15.5, m_iron, 0.65, 6)
			_add_cyl_2d(root, pos, 4.8, 14.5, 1.2, m_iron, 4.8, 10)
			_add_cyl_2d(root, pos, 0.6, 9.5, 5.5, m_iron, 0.6, 6)
			if not _is_headless:
				var lt := OmniLight3D.new()
				lt.position = to_3d(pos, 10.0)
				lt.light_color = Color(1.0, 0.62, 0.28)
				lt.light_energy = 1.35
				lt.omni_range = 2.8 * Mapa3D.K
				root.add_child(lt)
		"log_seat":
			# Tronco tumbado 3D con corteza, anillos de madera en los extremos y calzos de apoyo
			var m_ring := _mat("log_end_ring", Color(0.78, 0.64, 0.42), 0.85, 0.0)
			var log_mi := _add_cyl_2d(root, pos, 3.8, 0.0, 23.0, m_dark, 3.8, 10)
			log_mi.rotation_degrees.z = 90.0
			log_mi.position = to_3d(pos, 3.8)
			for end_x in [-11.6, 11.6]:
				var cap_mi := _add_cyl_2d(root, pos + Vector2(end_x, 0), 3.4, 0.0, 0.6, m_ring, 3.4, 10)
				cap_mi.rotation_degrees.z = 90.0
				cap_mi.position = to_3d(pos + Vector2(end_x, 0), 3.8)
			_add_box_2d(root, pos + Vector2(-7.0, 0), Vector2(3.0, 8.2), 0.0, 2.2, m_wood)
			_add_box_2d(root, pos + Vector2(7.0, 0), Vector2(3.0, 8.2), 0.0, 2.2, m_wood)
		"clothesline":
			# Tendedero 3D con dos postes de madera, cuerda tensada y 3 prendas tendidas (incluyendo la prenda morada)
			var m_rope := _mat("clothesline_rope", Color(0.76, 0.66, 0.48), 0.90, 0.0)
			var m_cloth_purple := _mat("cloth_purple", Color(0.62, 0.46, 0.84), 0.88, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.7)
			var m_cloth_tunic := _mat("cloth_tunic", Color(0.58, 0.52, 0.42), 0.90, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.7)
			var m_cloth_teal := _mat("cloth_teal", Color(0.24, 0.58, 0.68), 0.88, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.7)
			for px in [-13.0, 13.0]:
				_add_box_2d(root, pos + Vector2(px, 3.0), Vector2(3.8, 3.8), 0.0, 2.0, m_dark)
				_add_cyl_2d(root, pos + Vector2(px, 3.0), 1.6, 0.0, 16.5, m_wood, 1.4, 8)
				_add_box_2d(root, pos + Vector2(px, 3.0), Vector2(2.6, 2.8), 13.5, 1.8, m_rope)
			_add_box_2d(root, pos + Vector2(0, 3.0), Vector2(26.0, 1.2), 14.0, 1.0, m_rope)
			# Prenda 1 (izquierda): pantalón/tela morada con dos perneras y pinzas de madera
			_add_box_2d(root, pos + Vector2(-7.2, 3.2), Vector2(5.6, 1.6), 9.5, 4.8, m_cloth_purple)
			_add_box_2d(root, pos + Vector2(-8.6, 3.2), Vector2(2.4, 1.6), 5.2, 4.5, m_cloth_purple)
			_add_box_2d(root, pos + Vector2(-5.8, 3.2), Vector2(2.4, 1.6), 5.2, 4.5, m_cloth_purple)
			# Prenda 2 (centro): casaca/camisa con mangas
			_add_box_2d(root, pos + Vector2(0.0, 3.2), Vector2(6.4, 1.8), 4.8, 9.5, m_cloth_tunic)
			_add_box_2d(root, pos + Vector2(0.0, 3.2), Vector2(9.2, 1.6), 11.2, 3.0, m_cloth_tunic)
			# Prenda 3 (derecha): prenda azul turquesa
			_add_box_2d(root, pos + Vector2(7.4, 3.2), Vector2(5.4, 1.6), 9.5, 4.8, m_cloth_teal)
			_add_box_2d(root, pos + Vector2(6.1, 3.2), Vector2(2.3, 1.6), 5.5, 4.2, m_cloth_teal)
			_add_box_2d(root, pos + Vector2(8.7, 3.2), Vector2(2.3, 1.6), 5.5, 4.2, m_cloth_teal)
			for pin_x in [-8.4, -6.0, -1.8, 1.8, 6.2, 8.6]:
				_add_box_2d(root, pos + Vector2(pin_x, 3.2), Vector2(0.9, 2.0), 14.2, 1.6, m_dark)
		"weapon_sword", "weapon_hammer":
			# Espada / Martillo 3D apoyado sobre un caballete/tocón de armero en el campamento
			var m_steel := _mat("weapon_steel_3d", Color(0.82, 0.85, 0.90), 0.25, 0.85)
			var m_hilt := _mat("weapon_hilt_brass", Color(0.86, 0.68, 0.24), 0.32, 0.80)
			_add_cyl_2d(root, pos + Vector2(0, 2.0), 4.8, 0.0, 4.5, m_dark, 4.2, 10)
			_add_box_2d(root, pos + Vector2(0, 2.0), Vector2(8.0, 3.2), 4.2, 1.6, m_wood)
			var w_mdl_path: String = "props/Sword_Bronze.gltf" if kind == "weapon_sword" else "weapons/Hammer_Double.obj"
			var w_mdl := _add_model_2d(root, w_mdl_path, pos + Vector2(0, 1.5), 4.5, Vector2.ZERO, 15.0, 25.0)
			if w_mdl != null:
				w_mdl.rotation_degrees.z = -28.0
			else:
				_add_box_2d(root, pos + Vector2(0, 1.5), Vector2(2.2, 13.0), 5.5, 1.8, m_steel, -25.0)
				_add_box_2d(root, pos + Vector2(-2.2, 3.5), Vector2(5.8, 1.8), 5.2, 2.0, m_hilt, -25.0)
		"crate":
			if _add_model_2d(root, "exterior/Crate.obj", pos, 0.0, Vector2(14, 14), 12.0) == null:
				_add_box_2d(root, pos, Vector2(14, 14), 0.0, 12.0, m_wood)
		"barrel":
			if _add_model_2d(root, "props/Barrel.gltf", pos, 0.0, Vector2(13, 13), 13.0) == null:
				_add_cyl_2d(root, pos, 6.5, 0.0, 13.0, m_dark, 6.0, 10)
		"weak_wall":
			var m_ww := _mat("weak_wall_stone", Color(0.56, 0.54, 0.50), 0.90, 0.02, Color.BLACK, 0.0, "town_textures/wall_stone.png", "", 0.70)
			_add_box_2d(root, pos, Vector2(18.0, 28.0), 0.0, 2.0, m_ww)
			_add_box_2d(root, pos + Vector2(0.0, -4.0), Vector2(10.0, 18.0), 2.0, 12.0, m_ww)
			_add_box_2d(root, pos + Vector2(0.0, 7.0), Vector2(10.0, 8.0), 2.0, 7.5, m_ww)
		"sign":
			_add_box_2d(root, pos + Vector2(0, 4.0), Vector2(12.5, 5.2), 0.0, 2.2, m_dark)
			_add_box_2d(root, pos + Vector2(-4.5, 4.0), Vector2(2.4, 2.6), 0.0, 14.5, m_dark)
			_add_box_2d(root, pos + Vector2(4.5, 4.0), Vector2(2.4, 2.6), 0.0, 14.5, m_dark)
			var tabla: MeshInstance3D = _add_box_2d(root, pos + Vector2(0, 4.4), Vector2(16.5, 3.4), 6.2, 7.6, m_wood)
			_add_prism_2d(root, pos + Vector2(0, 4.2), Vector2(18.5, 5.8), 13.6, 3.6, m_dark, false)
			if spr.has_meta(Cartel.META_TEXTO):
				_escribir_poste(tabla, String(spr.get_meta(Cartel.META_TEXTO)))
		"wild_herb":
			var m_herb := _mat("forest_herb_3d", Color(0.26, 0.74, 0.34), 0.80, 0.0)
			if _add_model_2d(root, "nature/Flowers.obj", pos, -0.5, Vector2(12, 12), 7.5) == null:
				for off in [Vector2(-2.5, -1.5), Vector2(2.5, -1.0), Vector2(0.0, 2.2)]:
					_add_cyl_2d(root, pos + off, 2.2, 0.0, 5.5, m_herb, 0.6, 6)
		"wild_mushroom":
			var m_stem := _mat("mush_stem_3d", Color(0.92, 0.88, 0.78), 0.88, 0.0)
			var m_cap := _mat("mush_cap_3d", Color(0.82, 0.24, 0.18), 0.78, 0.0)
			for m_off in [Vector2(-2.2, 0.8), Vector2(2.4, -1.2), Vector2(0.2, -2.0)]:
				var sc: float = 1.0 if m_off.x < 0.0 else 0.75
				_add_cyl_2d(root, pos + m_off, 1.1 * sc, -0.4, 3.4 * sc, m_stem, 0.9 * sc, 7)
				_add_cyl_2d(root, pos + m_off, 2.8 * sc, 2.6 * sc, 2.2 * sc, m_cap, 0.6 * sc, 8)
		"rabbit_burrow":
			var m_earth := _mat("burrow_earth_3d", Color(0.42, 0.30, 0.19), 0.95, 0.0)
			var m_hole := _mat("burrow_hole_3d", Color(0.08, 0.06, 0.05), 0.98, 0.0)
			_add_cyl_2d(root, pos, 8.5, -0.8, 3.2, m_earth, 5.2, 10)
			_add_cyl_2d(root, pos + Vector2(0, 1.0), 4.2, 1.6, 1.0, m_hole, 3.8, 8)
		"fox_den":
			var m_den_rock := _mat("fox_den_rock_3d", Color(0.46, 0.43, 0.39), 0.92, 0.02)
			var m_den_earth := _mat("burrow_earth_3d", Color(0.42, 0.30, 0.19), 0.95, 0.0)
			var m_den_hole := _mat("burrow_hole_3d", Color(0.08, 0.06, 0.05), 0.98, 0.0)
			_add_cyl_2d(root, pos, 11.5, -1.0, 5.5, m_den_earth, 7.5, 10)
			_add_box_2d(root, pos + Vector2(0, -3.0), Vector2(14.0, 9.0), 0.0, 6.8, m_den_rock)
			_add_cyl_2d(root, pos + Vector2(0, 2.2), 5.2, 1.2, 2.4, m_den_hole, 4.6, 8)
		"roca":
			var rocas: Array[String] = ["nature/Rock_1.obj", "nature/Rock_2.obj", "nature/Rock_3.obj", "nature/Rock_4.obj", "nature/Rock_5.obj"]
			var h: int = absi(hash(pos.round()))
			_add_model_2d(root, rocas[h % rocas.size()], pos, ROCA_HUNDIDA_PX, Vector2.ZERO, ROCA_ALTO_PX, float(h % 360))
		"dropped_item":
			var m_pouch := _mat("dropped_pouch_3d", Color(0.68, 0.52, 0.32), 0.85, 0.05)
			_add_cyl_2d(root, pos, 3.4, 0.0, 4.2, m_pouch, 2.0, 8)


## Oculta las tiras planas 2D de muros/puertas/suelos cuando el 3D está activo (usando `self_modulate.a`
## en lugar de `.visible`, de modo que ningún test de estado de puertas o ventanas se vea afectado).
## Esconde los dibujos planos del mapa que ya tienen versión 3D (pinos, rocas, objetos, fachadas). Desde 2026-11-12 ya no
## hay modo 2D al que volver: se esconden siempre.
func _sync_2d_flat_visuals() -> void:
	if vm == null or not is_instance_valid(vm.entities_root):
		return
	var target_a: float = 0.0
	for src in _nature_sources + _prop_sources:
		var spr_n = src.get("sprite")
		if spr_n is CanvasItem and is_instance_valid(spr_n):
			(spr_n as CanvasItem).self_modulate.a = target_a
	var inner_rects: Array[Rect2] = [VillageRestaurant.TERRACE.grow(6.0)]
	for b in vm.building_footprints:
		inner_rects.append((b["rect"] as Rect2).grow(-3.0))
	for child in vm.entities_root.get_children():
		# Muebles y suelos 2D dentro de los edificios (camas, mesas, alfombras…): el interior 3D ya los tiene.
		if (child is Sprite2D or child is TextureRect or child is Polygon2D) and (child as CanvasItem).z_index <= 0 and not child.has_meta("flat_2d_building_visual"):
			var cpos: Vector2 = (child as Node2D).global_position if child is Node2D else (child as Control).global_position + (child as Control).size * 0.5
			if child is Polygon2D and cpos == Vector2.ZERO and (child as Polygon2D).polygon.size() > 0:
				cpos = (child as Polygon2D).polygon[0]
			for ir in inner_rects:
				if ir.has_point(cpos):
					(child as CanvasItem).self_modulate.a = target_a
					break
		if child.has_meta("flat_2d_building_visual"):
			if child is CanvasItem:
				(child as CanvasItem).self_modulate.a = target_a
		elif child is StaticBody2D:
			for sub in child.get_children():
				if sub is TextureRect:
					(sub as TextureRect).self_modulate.a = target_a
	VillageUnderworldScript.sync_sewer_visibility(vm)
	load("res://scripts/systems/VillageClub.gd").sync_club_visibility(vm)
	for rf in get_tree().get_nodes_in_group("ranch_fence_2d"):
		if rf is CanvasItem and is_instance_valid(rf):
			(rf as CanvasItem).self_modulate.a = target_a


## B4.2: Un taller saboteado echa humo y chispas en 3D hasta que se repara; si llueve, el fuego exterior se apaga.
func _sync_sabotage_fx_3d() -> void:
	if vm == null or not ("shop_businesses" in vm) or not is_instance_valid(nature_root_3d):
		return
	var raining: bool = WorldClock != null and int(WorldClock.current_weather) == 1
	for r_id in vm.shop_businesses.keys():
		var role_int: int = int(r_id)
		var biz: Dictionary = vm.shop_businesses[role_int]
		var sab_d: int = int(biz.get("sabotaged_days", 0))
		var node3d: Node3D = _sabotage_fx_3d.get(role_int) as Node3D if is_instance_valid(_sabotage_fx_3d.get(role_int)) else null
		if sab_d <= 0:
			if node3d != null:
				node3d.queue_free()
			_sabotage_fx_3d.erase(role_int)
			continue
		var s_pos: Vector2 = biz.get("stall_pos", Vector2.ZERO)
		var has_fire: bool = (biz.get("outdoor_fire") == true) and not raining
		if node3d == null:
			node3d = Node3D.new()
			node3d.name = "SabotageFX3D_%d" % role_int
			node3d.position = to_3d(s_pos, 10.0)
			var smoke3 := CPUParticles3D.new()
			smoke3.name = "Smoke3D"
			var sm_mesh := SphereMesh.new()
			sm_mesh.radius = 0.14
			sm_mesh.height = 0.28
			sm_mesh.material = _mat("sab_smoke_3d", Color(0.24, 0.24, 0.27), 0.95, 0.0)
			smoke3.mesh = sm_mesh
			smoke3.amount = 10
			smoke3.lifetime = 1.4
			smoke3.direction = Vector3(0.1, 1.0, -0.05)
			smoke3.spread = 24.0
			smoke3.initial_velocity_min = 0.45
			smoke3.initial_velocity_max = 0.95
			smoke3.gravity = Vector3(0.0, 0.35, 0.0)
			smoke3.emitting = true
			_particulas_a_metros(smoke3)
			node3d.add_child(smoke3)
			var sparks3 := CPUParticles3D.new()
			sparks3.name = "Sparks3D"
			var sp_mesh := BoxMesh.new()
			sp_mesh.size = Vector3(0.06, 0.06, 0.06)
			sp_mesh.material = _mat("sab_spark_3d", Color(1.0, 0.80, 0.25), 0.2, 0.0, Color(1.0, 0.72, 0.18), 2.2)
			sparks3.mesh = sp_mesh
			sparks3.amount = 8
			sparks3.lifetime = 0.45
			sparks3.explosiveness = 0.35
			sparks3.direction = Vector3(0.0, 1.0, 0.0)
			sparks3.spread = 58.0
			sparks3.initial_velocity_min = 0.8
			sparks3.initial_velocity_max = 1.6
			sparks3.gravity = Vector3(0.0, -3.2, 0.0)
			sparks3.emitting = true
			_particulas_a_metros(sparks3)
			node3d.add_child(sparks3)
			var fire3 := CPUParticles3D.new()
			fire3.name = "Fire3D"
			var fi_mesh := SphereMesh.new()
			fi_mesh.radius = 0.11
			fi_mesh.height = 0.24
			fi_mesh.material = _mat("sab_fire_3d", Color(1.0, 0.45, 0.12), 0.3, 0.0, Color(1.0, 0.38, 0.08), 2.5)
			fire3.mesh = fi_mesh
			fire3.amount = 8
			fire3.lifetime = 0.55
			fire3.direction = Vector3(0.0, 1.0, 0.0)
			fire3.spread = 26.0
			fire3.initial_velocity_min = 0.35
			fire3.initial_velocity_max = 0.75
			fire3.gravity = Vector3(0.0, 0.6, 0.0)
			fire3.emitting = has_fire
			_particulas_a_metros(fire3)
			node3d.add_child(fire3)
			if not _is_headless:
				var lt := OmniLight3D.new()
				lt.name = "FireLight3D"
				lt.light_color = Color(1.0, 0.58, 0.20)
				lt.light_energy = 1.15 if has_fire else 0.35
				lt.omni_range = 2.4 * Mapa3D.K
				node3d.add_child(lt)
			nature_root_3d.add_child(node3d)
			_sabotage_fx_3d[role_int] = node3d
		else:
			node3d.position = to_3d(s_pos, 10.0)
			var f3 := node3d.get_node_or_null("Fire3D") as CPUParticles3D
			if f3 != null:
				f3.emitting = has_fire
			var lt3 := node3d.get_node_or_null("FireLight3D") as OmniLight3D
			if lt3 != null:
				lt3.light_energy = 1.15 if has_fire else 0.35


## Texto del poste de un camino en las dos caras de su tabla (mapa/cartel.gd: letras quemadas que encogen si no caben).
func _escribir_poste(tabla: MeshInstance3D, texto: String) -> void:
	var tam: Vector3 = (tabla.mesh as BoxMesh).size
	for giro: float in [0.0, PI]:
		var l: Label3D = Cartel.letras(tam, Cartel.COLOR_LETRAS_PINTADAS)
		Cartel.escribir(l, texto, tam)
		l.position = Basis(Vector3.UP, giro) * l.position
		l.rotation.y = giro
		tabla.add_child(l)
