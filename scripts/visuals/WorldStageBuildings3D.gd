@tool
extends "res://scripts/visuals/WorldStageProps3D.gd"

## Edificios sólidos 3D, estilos de fachada/tejado, interiores, taberna (2 plantas), trattoria y solares.

# ==============================================================================
# 2. EDIFICIOS SÓLIDOS, INTERIORES, PUERTAS, VENTANAS, ALTILLOS (+1) Y CUTAWAY
# ==============================================================================
func _style_for_building(b_id: String) -> Dictionary:
	var wall_col := Color(0.82, 0.76, 0.64)
	var roof_col := Color(0.68, 0.32, 0.22)
	var floor_col := Color(0.56, 0.40, 0.25)
	var trim_col := Color(0.42, 0.28, 0.16)
	var wall_tex := "town_textures/timber_square_clay.png"
	var wall_norm := ""
	var roof_tex := "town_textures/roof_clay_red_center.png"
	var floor_tex := "town_textures/floor_wood_planks.png"
	if b_id in ["building_church", "building_police", "shop_family_smith", "building_tinker", "building_town_hall"]:
		floor_tex = "town_textures/floor_stone_pattern.png"
	elif b_id == "building_hospital":
		floor_tex = "town_textures/floor_tiles_sand_large.png"
	var roof_norm := ""
	var wall_h: float = 28.0
	var roof_h: float = 14.0

	if b_id == "building_tavern":
		wall_tex = "town_textures/wall_timber_structure_cross.png"
		wall_col = Color(0.86, 0.74, 0.56)
		roof_col = Color(0.66, 0.24, 0.20)
		floor_col = Color(0.52, 0.34, 0.20)
		wall_h = 68.0
		roof_h = 24.0
	elif b_id == "building_hospital":
		wall_tex = "town_textures/wall_brick_small_sand.png"
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.76, 0.74, 0.69)
		roof_col = Color(0.32, 0.35, 0.37)
		floor_col = Color(0.72, 0.74, 0.72)
		trim_col = Color(0.30, 0.23, 0.17)
		wall_h = 30.0
	elif b_id == "building_police":
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.64, 0.68, 0.74)
		roof_col = Color(0.26, 0.34, 0.48)
		floor_col = Color(0.50, 0.52, 0.56)
		trim_col = Color(0.34, 0.38, 0.46)
		wall_tex = "town_textures/wall_brick_stone_center.png"
		wall_norm = ""
		wall_h = 30.0
	elif b_id == "building_church":
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.88, 0.84, 0.78)
		roof_col = Color(0.36, 0.38, 0.44)
		floor_col = Color(0.66, 0.62, 0.58)
		trim_col = Color(0.52, 0.46, 0.42)
		wall_tex = "town_textures/wall_brick_sand_center.png"
		wall_norm = ""
		wall_h = 34.0
		roof_h = 18.0
	elif b_id == "building_town_hall":
		wall_col = Color(0.88, 0.82, 0.72)
		roof_col = Color(0.28, 0.42, 0.62)
		floor_col = Color(0.58, 0.42, 0.26)
		wall_tex = "town_textures/wall_brick_sand_center.png"
		wall_norm = ""
		wall_h = 32.0
		roof_h = 16.0
	elif b_id == "building_restaurant": # R1: trattoria de estuco/ladrillo claro ocre, teja roja y carpintería verde oscura
		wall_tex = "town_textures/wall_brick_sand_center.png"
		wall_norm = ""
		wall_col = Color(1.0, 0.94, 0.80)
		roof_col = Color(0.64, 0.26, 0.18)
		floor_col = Color(0.74, 0.46, 0.30)
		floor_tex = "town_textures/floor_tiles_tan_large.png"
		trim_col = Color(0.24, 0.40, 0.28)
		wall_h = 32.0
		roof_h = 16.0
	elif b_id == "building_candil":
		wall_col = Color(0.56, 0.38, 0.48)
		roof_col = Color(0.58, 0.22, 0.38)
		floor_col = Color(0.44, 0.24, 0.32)
	elif b_id == "building_manor" or b_id == "building_townhouse":
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.84, 0.82, 0.78)
		roof_col = Color(0.26, 0.46, 0.38)
		floor_col = Color(0.56, 0.40, 0.24)
		wall_tex = "town_textures/wall_brick_sand_center.png"
		wall_norm = ""
		wall_h = 32.0
	elif b_id == "building_library":
		wall_tex = "town_textures/wall_brick_sand_center.png"
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.88, 0.82, 0.72)
		roof_col = Color(0.30, 0.44, 0.64)
		trim_col = Color(0.28, 0.36, 0.48)
		wall_h = 32.0
		roof_h = 16.0
	elif b_id == "building_school":
		wall_col = Color(0.86, 0.78, 0.62)
		roof_col = Color(0.68, 0.36, 0.24)
	elif b_id == "building_abandoned_mill":
		wall_tex = "town_textures/wall_stone.png"
		wall_norm = "town_textures/wall_stone_n.png"
		roof_tex = "town_textures/rf_planks.png"
		floor_tex = "town_textures/rf_planks.png"
		wall_col = Color(0.32, 0.30, 0.27)
		roof_col = Color(0.22, 0.16, 0.11)
		floor_col = Color(0.22, 0.16, 0.12)
		trim_col = Color(0.20, 0.14, 0.09)
		wall_h = 26.0
		roof_h = 13.0
	elif b_id == "shop_family_smith" or b_id == "building_tinker":
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.60, 0.58, 0.56)
		roof_col = Color(0.36, 0.34, 0.34)
		floor_col = Color(0.46, 0.44, 0.42)
		wall_tex = "town_textures/wall_stone.png"
		wall_norm = ""
	elif b_id.begins_with("shop_") or b_id.begins_with("mixed_"):
		if (b_id.hash() % 2) == 0:
			wall_tex = "town_textures/wall_timber_structure_cross.png"
		if (b_id.hash() % 3) == 0:
			roof_tex = "town_textures/roof_thatch_center.png"
		wall_col = Color(0.84, 0.74, 0.56)
		roof_col = Color(0.68, 0.34, 0.22)
	elif b_id.begins_with("player_house_"):
		wall_tex = "town_textures/timber_square_planks.png"
		roof_tex = "town_textures/roof_thatch_center.png"
		wall_col = Color(0.86, 0.76, 0.58)
		roof_col = Color(0.28, 0.52, 0.36)

	var wall_emit_col := Color.BLACK
	var wall_emit_e: float = 0.0
	var w_mat := _mat("wall_" + b_id, wall_col, 0.88, 0.04, wall_emit_col, wall_emit_e, wall_tex, wall_norm, 0.70)
	if b_id == "building_restaurant":
		w_mat.albedo_color = Color(0.76, 0.66, 0.52)
		w_mat.uv1_scale = Vector3(2.4, 0.72, 2.4)
	return {
		"wall_mat": w_mat,
		"roof_mat": _mat("roof_" + b_id, roof_col, 0.80, 0.06, Color.BLACK, 0.0, roof_tex, roof_norm, 0.75),
		"floor_mat": _mat("floor_" + b_id, floor_col, 0.88, 0.02, Color.BLACK, 0.0, floor_tex, "", 0.85),
		"trim_mat": _mat("trim_" + b_id, trim_col, 0.84, 0.05, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.85),
		"wall_h": wall_h,
		"roof_h": roof_h,
	}

func rebuild_buildings_3d() -> void:
	_clear_children(buildings_root_3d)
	_building_records_3d.clear()
	_building_furniture_rects.clear()
	_current_building_id = ""
	_current_building_floor = 0
	_door_nodes_3d.clear()
	_window_nodes_3d.clear()
	_chest_nodes_3d.clear()
	_morgue_body_nodes_3d.clear()
	_restaurant_night_nodes.clear()
	_jail_gate_pivot_3d = null
	if vm == null:
		return

	var m_wood := _mat("prop_wood", Color(0.45, 0.29, 0.16), 0.85, 0.02)
	var m_dark_wood := _mat("prop_dark_wood", Color(0.32, 0.20, 0.11), 0.88, 0.02)
	var m_iron := _mat("wrought_iron", Color(0.22, 0.24, 0.28), 0.45, 0.75)
	var m_gold := _mat("brass_gold", Color(0.85, 0.68, 0.24), 0.35, 0.82)
	var m_glass := _mat("win_glass", Color(0.56, 0.82, 0.96, 0.75), 0.15, 0.25)
	var m_plinth := _mat("building_plinth_stone", Color(0.58, 0.56, 0.52), 0.90, 0.03, Color.BLACK, 0.0, "town_textures/wall_stone.png", "", 0.70)

	for b in vm.building_footprints:
		var b_id: String = str(b.get("id", ""))
		var rect: Rect2 = b["rect"]
		var center: Vector2 = rect.get_center()
		var sz: Vector2 = rect.size
		var half: Vector2 = sz * 0.5
		var door_pos: Vector2 = b["door_pos"]
		var door_south: bool = bool(b["door_south"])
		var style: Dictionary = _style_for_building(b_id)
		# Altura de muro algo mayor y distinta en cada edificio (+0..10 px), salvo la taberna de 2 plantas (44 px exactos: 22 px por planta).
		var wall_h: float = float(style["wall_h"]) if b_id == "building_tavern" else (float(style["wall_h"]) + 4.0 + float(absi(b_id.hash()) % 6) * 2.0)
		var roof_h: float = float(style["roof_h"])
		var m_wall: Material = style["wall_mat"]
		var m_roof: Material = style["roof_mat"]
		var m_floor: Material = style["floor_mat"]
		var m_trim: Material = style["trim_mat"]

		var b_root := Node3D.new()
		b_root.name = "B3D_" + b_id
		buildings_root_3d.add_child(b_root)

		# 1. Zócalo de piedra enterrado (cimentación contra posibles microdesniveles) + losa de suelo 3D y zócalo exterior
		_add_box_2d(b_root, center, sz + Vector2(6, 6), -2.5, 2.5, m_plinth)
		_add_box_2d(b_root, center, sz + Vector2(4, 4), 0.0, 1.5, m_trim)
		_add_box_2d(b_root, center, sz - Vector2(2, 2), 1.5, 1.0, m_floor)

		# 2. Muros perimetrales 3D con hueco de puerta y dintel superior
		var wall_t: float = 6.5
		var door_w: float = 40.0
		for d_entry in vm.building_doors:
			if str(d_entry.get("building_id", "")) == b_id:
				door_w = float(d_entry.get("width", 40.0))
				break

		# Muro izquierdo y derecho + pilares de esquina (en el molino viejo abandonado, el muro oeste tiene el hueco enrejado del sótano al canal de la rueda y el este/norte tienen boquetes)
		if b_id == "building_abandoned_mill":
			# Muro oeste con vano inferior para la reja del sótano que da al canal de la rueda (y = -1072..-1050)
			_add_box_2d(b_root, Vector2(rect.position.x, rect.position.y + 17.0), Vector2(wall_t, 34.0), 2.0, wall_h, m_wall)
			_add_box_2d(b_root, Vector2(rect.position.x, rect.end.y - 18.0), Vector2(wall_t, 36.0), 2.0, wall_h, m_wall)
			_add_box_2d(b_root, Vector2(rect.position.x, center.y - 1.0), Vector2(wall_t, 24.0), 12.8, wall_h - 10.8, m_wall)
			# Muro este con boquete de piedras derrumbadas en la mitad norte
			_add_box_2d(b_root, Vector2(rect.end.x, rect.position.y + 14.0), Vector2(wall_t, 28.0), 2.0, wall_h, m_wall)
			_add_box_2d(b_root, Vector2(rect.end.x, rect.end.y - 22.0), Vector2(wall_t, 44.0), 2.0, wall_h, m_wall)
			_add_box_2d(b_root, Vector2(rect.end.x, rect.position.y + 38.0), Vector2(wall_t, 20.0), 2.0, 9.5, m_wall)
		else:
			_add_box_2d(b_root, Vector2(rect.position.x, center.y), Vector2(wall_t, sz.y), 2.0, wall_h, m_wall)
			_add_box_2d(b_root, Vector2(rect.end.x, center.y), Vector2(wall_t, sz.y), 2.0, wall_h, m_wall)
		for c_pt in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
			_add_box_2d(b_root, c_pt, Vector2(wall_t + 2.0, wall_t + 2.0), 2.0, wall_h + 1.0, m_trim)

		# Muro cerrado (opuesto a la puerta): si es el muro sur (más cercano a la cámara), se rebaja al abrir el tejado (Cutaway)
		var closed_y: float = (center.y - half.y) if door_south else (center.y + half.y)
		if b_id == "building_abandoned_mill":
			# Muro norte del molino viejo con gran boquete irregular en el centro-oeste (entre el pajar y el hogar)
			_add_box_2d(b_root, Vector2(rect.position.x + 25.0, closed_y), Vector2(46.0, wall_t), 2.0, wall_h, m_wall)
			_add_box_2d(b_root, Vector2(rect.end.x - 27.0, closed_y), Vector2(50.0, wall_t), 2.0, wall_h, m_wall)
			_add_box_2d(b_root, Vector2(center.x - 2.0, closed_y), Vector2(28.0, wall_t), 2.0, 7.2, m_wall)
			_add_box_2d(b_root, Vector2(center.x - 11.0, closed_y), Vector2(8.0, wall_t), 9.2, 6.5, m_wall)
			_add_box_2d(b_root, Vector2(center.x + 8.0, closed_y), Vector2(7.0, wall_t), 9.2, 5.0, m_wall)
		elif door_south:
			_add_box_2d(b_root, Vector2(center.x, closed_y), Vector2(maxf(8.0, sz.x - wall_t), wall_t), 2.0, wall_h, m_wall)
		else:
			_add_box_2d(b_root, Vector2(center.x, closed_y), Vector2(maxf(8.0, sz.x - wall_t), wall_t), 2.0, 9.0, m_wall)

		# Muro de la fachada con hueco de puerta + dintel sobre la puerta
		var door_y: float = door_pos.y
		var door_left_x: float = door_pos.x - door_w * 0.5
		var door_right_x: float = door_pos.x + door_w * 0.5
		var left_w: float = maxf(6.0, door_left_x - (rect.position.x + wall_t * 0.5))
		var right_w: float = maxf(6.0, (rect.end.x - wall_t * 0.5) - door_right_x)
		_add_box_2d(b_root, Vector2(rect.position.x + wall_t * 0.5 + left_w * 0.5, door_y), Vector2(left_w, wall_t), 2.0, wall_h, m_wall)
		_add_box_2d(b_root, Vector2(rect.end.x - wall_t * 0.5 - right_w * 0.5, door_y), Vector2(right_w, wall_t), 2.0, wall_h, m_wall)
		# Jambas y dintel de la puerta
		_add_box_2d(b_root, Vector2(door_left_x, door_y), Vector2(3.5, wall_t + 2.0), 2.0, wall_h, m_trim)
		_add_box_2d(b_root, Vector2(door_right_x, door_y), Vector2(3.5, wall_t + 2.0), 2.0, wall_h, m_trim)
		var lintel_mat: Material = m_wall if b_id == "building_restaurant" else m_trim
		if b_id == "building_tavern":
			_add_box_2d(b_root, Vector2(door_pos.x, door_y), Vector2(door_w + 4.0, wall_t + 1.5), 25.0, 3.5, m_trim)
			_add_box_2d(b_root, Vector2(door_pos.x, door_y), Vector2(door_w + 2.0, wall_t), 28.5, wall_h - 26.5, m_wall)
			# Cinta de vigas de entreplanta exterior (h = 34.0) y ventanas del piso superior en la fachada de 2 plantas
			_add_box_2d(b_root, Vector2(center.x, rect.position.y), Vector2(sz.x + 2.5, wall_t + 1.8), 33.2, 2.4, m_trim)
			_add_box_2d(b_root, Vector2(center.x, rect.end.y), Vector2(sz.x + 2.5, wall_t + 1.8), 33.2, 2.4, m_trim)
			_add_box_2d(b_root, Vector2(rect.position.x, center.y), Vector2(wall_t + 1.8, sz.y + 2.5), 33.2, 2.4, m_trim)
			_add_box_2d(b_root, Vector2(rect.end.x, center.y), Vector2(wall_t + 1.8, sz.y + 2.5), 33.2, 2.4, m_trim)
		else:
			_add_box_2d(b_root, Vector2(door_pos.x, door_y), Vector2(door_w + 4.0, wall_t + 1.5), 2.0 + wall_h * 0.72, wall_h * 0.28, lintel_mat)

		# 3. Puerta abatible 3D sincronizada con `vm.building_doors` (diseño propio por edificio acorde a la fachada)
		for d_entry in vm.building_doors:
			if str(d_entry.get("building_id", "")) == b_id:
				var hinge_pos := Vector2(door_left_x + 2.0, door_y)
				var pivot := Node3D.new()
				pivot.name = "DoorPivot_" + b_id
				pivot.position = to_3d(hinge_pos, 2.0)
				b_root.add_child(pivot)
				var leaf_w: float = maxf(18.0, door_w - 4.0)
				var leaf_h: float = 23.0 if b_id == "building_tavern" else (wall_h * 0.70)
				if not _is_headless:
					_build_door_leaf_3d(pivot, b_id, leaf_w, leaf_h, m_wood, m_dark_wood, m_iron, m_gold)
				var lock_badge := MeshInstance3D.new()
				var lb_bm := BoxMesh.new()
				lb_bm.size = size_3d(Vector2(2.6, 3.2), 2.8)
				lock_badge.mesh = lb_bm
				lock_badge.material_override = m_iron
				lock_badge.position = Vector3((leaf_w - 4.0) * WORLD_SCALE, (leaf_h * 0.48 * WORLD_SCALE) / _cos_p, 0.0)
				pivot.add_child(lock_badge)
				_door_nodes_3d.append({"entry": d_entry, "pivot": pivot, "lock_badge": lock_badge, "door_south": door_south})
				break

		# 4. Ventana 3D con postigos sincronizada con `vm.building_windows`
		for w_entry in vm.building_windows:
			if str(w_entry.get("building_id", "")) == b_id:
				if b_id in ["building_police", "building_town_hall"]:
					break
				var w_pos: Vector2 = w_entry.get("pos", Vector2.ZERO)
				var pane: Node3D = null
				if not _is_headless:
					var win_tex: String = "town_textures/window_square_divided.png"
					if b_id == "building_church":
						win_tex = "town_textures/window_tall_rounded.png"
					elif b_id == "building_hospital":
						win_tex = "town_textures/window_square_pane.png"
					elif b_id == "building_library":
						win_tex = "town_textures/window_tall_divided.png"
					pane = _make_texture_panel(13.0, 12.0, wall_t + 2.4, _panel_mat("win_" + b_id, win_tex, false))
					pane.position = to_3d(w_pos, 10.0 + 6.0)
					b_root.add_child(pane)
				else:
					pane = _add_box_2d(b_root, w_pos, Vector2(11.0, wall_t + 2.4), 12.0, 8.0, m_glass)
				var shutter := _add_box_2d(b_root, w_pos, Vector2(12.0, wall_t + 2.8), 12.0, 8.2, m_dark_wood)
				_window_nodes_3d.append({"entry": w_entry, "pane": pane, "shutter": shutter})
				break

		# §3b.3: Barrotes de hierro y planchas remachadas en ventanas bajas de comisaría y ayuntamiento
		if b_id in ["building_police", "building_town_hall"]:
			var m_rivet := _mat("epoch_rivet_steel", Color(0.18, 0.20, 0.23), 0.52, 0.82)
			for side_s in [-1.0, 1.0]:
				var wx_low: float = center.x + side_s * (half.x * 0.58)
				var wy_low: float = door_y
				# Plancha superior e inferior remachada + 4 barrotes verticales en fachada
				_add_box_2d(b_root, Vector2(wx_low, wy_low), Vector2(16.0, wall_t + 2.8), 8.5, 2.2, m_rivet)
				_add_box_2d(b_root, Vector2(wx_low, wy_low), Vector2(16.0, wall_t + 2.8), 18.2, 2.2, m_rivet)
				_add_box_2d(b_root, Vector2(wx_low, wy_low), Vector2(14.5, wall_t + 1.8), 10.5, 8.0, _mat("epoch_dark_win", Color(0.08, 0.10, 0.12), 0.7, 0.2))
				for bx_i in [-5.4, -1.8, 1.8, 5.4]:
					_add_cyl_2d(b_root, Vector2(wx_low + bx_i, wy_low), 0.55, 8.5, 11.8, m_iron, 0.55, 6)
				# Ventana baja blindada con plancha remachada en muros laterales
				var sx_wall: float = rect.position.x if side_s < 0.0 else rect.end.x
				_add_box_2d(b_root, Vector2(sx_wall, center.y), Vector2(wall_t + 2.6, 16.0), 9.0, 10.0, m_rivet)
				for ry_i in [-5.5, 0.0, 5.5]:
					_add_cyl_2d(b_root, Vector2(sx_wall, center.y + ry_i), 0.55, 8.5, 11.0, m_iron, 0.55, 6)

		# 5. Mobiliario interior 3D específico de cada edificio
		_current_building_id = b_id
		_current_building_floor = 0
		_populate_building_interior_3d(b_root, b_id, rect, door_south, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)

		# 6. Altillo / Primer Piso (+1) 3D (exclusivo de la taberna de 2 plantas)
		var loft_root := Node3D.new()
		loft_root.name = "Loft3D_" + b_id
		loft_root.visible = false
		b_root.add_child(loft_root)
		_current_building_floor = 1
		if b_id == "building_tavern":
			_build_tavern_floor_1_3d(loft_root, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)
		_current_building_id = ""
		_current_building_floor = 0

		# 7. Tejado a dos aguas con alero (se retira en modo Cutaway). Cada edificio varía según su id:
		#    orientación de la cumbrera, altura, ala más baja en los edificios anchos, porche sobre la puerta y chimenea.
		var roof_cap := Node3D.new()
		roof_cap.name = "RoofCap_" + b_id
		b_root.add_child(roof_cap)
		# B7: Forjado/techo de tablas justo sobre la coronación de los muros (2.0 + wall_h + 0.08) para evitar Z-fighting (parpadeo) con paredes y tabiques
		if b_id == "building_abandoned_mill":
			# Techo del molino viejo con boquete de tablas hundidas en el centro-norte dejando ver los cabrios rotos y el exterior
			_add_box_2d(roof_cap, center + Vector2(-36.0, 0.0), Vector2(48.0, sz.y - 4.0), 2.0 + wall_h + 0.08, 2.1, m_trim)
			_add_box_2d(roof_cap, center + Vector2(38.0, 0.0), Vector2(44.0, sz.y - 4.0), 2.0 + wall_h + 0.08, 2.1, m_trim)
			_add_box_2d(roof_cap, center + Vector2(1.0, 22.0), Vector2(30.0, 42.0), 2.0 + wall_h + 0.08, 2.1, m_trim)
		else:
			_add_box_2d(roof_cap, center, sz - Vector2(4.0, 4.0), 2.0 + wall_h + 0.08, 2.1, m_wood)
		var hv: int = absi(b_id.hash())
		var ov: float = 6.0
		var short_side: float = minf(sz.x, sz.y)
		var rh: float = clampf(short_side * (0.40 + float(hv % 5) * 0.04), 16.0, 46.0)
		var ridge_x: bool = sz.x >= sz.y
		if absf(sz.x - sz.y) < 12.0:
			ridge_x = (hv % 2) == 0
		var roof_base_h: float = 2.0 + wall_h + 2.25
		if b_id == "building_abandoned_mill":
			# Tejado medio hundido y en ruinas con huecos y cabrios de madera podrida al descubierto
			_add_prism_2d(roof_cap, center + Vector2(-24.0, 0.0), Vector2(sz.x * 0.56, sz.y + ov * 1.5), roof_base_h, rh * 0.85, m_roof, false)
			_add_prism_2d(roof_cap, center + Vector2(34.0, -10.0), Vector2(sz.x * 0.36, sz.y * 0.68), roof_base_h, rh * 0.58, m_roof, true)
			for r_bx in [-46.0, -18.0, 10.0, 38.0]:
				_add_box_2d(roof_cap, center + Vector2(r_bx, 0.0), Vector2(2.8, sz.y + 4.0), roof_base_h - 0.5, 2.6, m_trim)
		elif sz.x > 118.0 and not (b_id in ["building_church"]):
			# Cuerpo principal + ala más baja (rompe la caja: silueta en L vista desde arriba)
			var main_w: float = sz.x * 0.60
			var wing_w: float = sz.x - main_w
			var main_left: bool = (hv % 2) == 0
			var main_cx: float = rect.position.x + (main_w * 0.5 if main_left else wing_w + main_w * 0.5)
			var wing_cx: float = rect.position.x + (main_w + wing_w * 0.5 if main_left else wing_w * 0.5)
			_add_prism_2d(roof_cap, Vector2(main_cx, center.y), Vector2(main_w + ov * 2.0, sz.y + ov * 2.0), roof_base_h, rh, m_roof, false)
			_add_prism_2d(roof_cap, Vector2(wing_cx, center.y), Vector2(wing_w + ov, sz.y * 0.86 + ov), roof_base_h, rh * 0.62, m_roof, true)
		else:
			_add_prism_2d(roof_cap, center, sz + Vector2(ov * 2.0, ov * 2.0), roof_base_h, rh, m_roof, ridge_x)
		# Remate de madera bajo el alero (se ve con el tejado puesto y quitado)
		if not door_south:
			_add_box_2d(roof_cap, Vector2(center.x, closed_y), Vector2(maxf(8.0, sz.x - wall_t), wall_t), 11.05, wall_h - 9.05, m_wall)
			_add_box_2d(roof_cap, Vector2(center.x, rect.end.y), Vector2(sz.x + 2.0, 3.0), 2.0 + wall_h + 0.08, 2.5, m_trim)
		else:
			_add_box_2d(b_root, Vector2(center.x, rect.end.y), Vector2(sz.x + 2.0, 3.0), 2.0 + wall_h + 0.08, 2.5, m_trim)
		_add_box_2d(b_root, Vector2(center.x, rect.position.y), Vector2(sz.x + 2.0, 3.0), 2.0 + wall_h + 0.08, 2.5, m_trim)
		# Porche sobre la puerta en tiendas y casas (tejadillo inclinado sobre dos postes)
		if (hv % 3) != 0 and not (b_id in ["building_church", "building_police", "building_hospital", "building_abandoned_mill"]):
			var porch_dir: float = 1.0 if door_south else -1.0
			var porch_c := Vector2(door_pos.x, door_y + porch_dir * 9.0)
			_add_box_2d(b_root, porch_c, Vector2(door_w + 16.0, 18.0), wall_h * 0.70, 2.5, m_roof)
			for px in [-1.0, 1.0]:
				_add_box_2d(b_root, Vector2(door_pos.x + px * (door_w * 0.5 + 6.0), door_y + porch_dir * 16.0), Vector2(2.5, 2.5), 2.0, wall_h * 0.70 - 2.0, m_trim)
		# Chimenea sobre la cumbrera
		if b_id != "building_abandoned_mill":
			var ch_off := Vector2(half.x * (0.30 if (hv % 2) == 0 else -0.30), -half.y * 0.15)
			_add_model_2d(roof_cap, "fantasy_town/chimney.glb", center + ch_off, roof_base_h + rh * 0.35, Vector2(9.0, 9.0), rh * 0.9)
		# Campanario de la iglesia: torre de piedra con chapitel junto a la fachada
		if b_id == "building_church":
			var tower_c := Vector2(center.x, (rect.end.y - 16.0) if door_south else (rect.position.y + 16.0))
			_add_box_2d(roof_cap, tower_c, Vector2(26.0, 22.0), roof_base_h, rh + 22.0, m_wall)
			_add_pyramid_2d(roof_cap, tower_c, Vector2(32.0, 28.0), roof_base_h + rh + 22.0, 34.0, m_roof)

		_building_records_3d.append({
			"id": b_id,
			"rect": rect,
			"root": b_root,
			"roof_cap": roof_cap,
			"loft_root": loft_root,
		})

	_merge_building_meshes()

	# Cofres domésticos 3D sincronizados con `vm.house_chests`
	for ch in vm.house_chests:
		var c_pos: Vector2 = ch.get("pos", Vector2.ZERO)
		var fam_id: String = str(ch.get("family_id", ""))
		var is_tavern_upper: bool = (fam_id == VillageTavern.FAMILY_ID)
		var base_h: float = VillageTavern.FLOOR_1_H if is_tavern_upper else 2.0
		var parent_node: Node3D = buildings_root_3d
		_current_building_id = ""
		_current_building_floor = 1 if is_tavern_upper else 0
		for rec in _building_records_3d:
			var r_rect: Rect2 = rec["rect"]
			if r_rect.grow(8.0).has_point(c_pos):
				_current_building_id = str(rec["id"])
				if is_tavern_upper and is_instance_valid(rec.get("loft_root")):
					parent_node = rec["loft_root"]
				break
		var ch_root := Node3D.new()
		parent_node.add_child(ch_root)
		_add_model_2d(ch_root, "props/Chest_Wood.gltf", c_pos, base_h, Vector2(12.0, 8.5), 7.5)
		var lid := _add_box_2d(ch_root, c_pos, Vector2(11.4, 7.8), base_h + 5.5, 1.8, m_gold)
		_chest_nodes_3d.append({"entry": ch, "lid": lid})
	_current_building_id = ""
	_current_building_floor = 0
	check_furniture_overlaps(true)

## Rendimiento: junta en una sola malla por material las piezas quietas de cada edificio (muros, suelos, muebles).
## Quedan aparte y se siguen moviendo: puertas, ventanas y postigos, cuerpos de la morgue, reja del calabozo, el tejado
## (que se abre) y el altillo (que aparece), estos dos juntados cada uno por su lado.
func _merge_building_meshes() -> void:
	if _is_headless:
		return
	var excl: Dictionary = {}
	for d in _door_nodes_3d:
		for k in ["pivot", "lock_badge"]:
			if d.get(k) is Node:
				excl[d[k]] = true
	for w in _window_nodes_3d:
		for k in ["pane", "shutter"]:
			if w.get(k) is Node:
				excl[w[k]] = true
	for mb in _morgue_body_nodes_3d:
		excl[mb] = true
	for rn in _restaurant_night_nodes: # R1: bombillas de la terraza (se encienden y apagan)
		excl[rn] = true
	if _jail_gate_pivot_3d != null:
		excl[_jail_gate_pivot_3d] = true
	for rec in _building_records_3d:
		var sub: Array = [rec["roof_cap"], rec["loft_root"]]
		var ex_b: Dictionary = excl.duplicate()
		for sn in sub:
			ex_b[sn] = true
		_merge_meshes_under(rec["root"], ex_b)
		for sn in sub:
			_merge_meshes_under(sn, excl)

func _merge_meshes_under(root: Node3D, excl: Dictionary) -> void:
	var found: Array = []
	_collect_merge_meshes(root, root, excl, found)
	if found.size() < 2:
		return
	var inv: Transform3D = root.global_transform.affine_inverse()
	var tools: Dictionary = {} # clave -> {"st": SurfaceTool, "mat": Material, "shadow": int}
	for mi in found:
		var xf: Transform3D = inv * mi.global_transform
		for si in range(mi.mesh.get_surface_count()):
			var mat: Material = mi.material_override
			if mat == null:
				mat = mi.get_surface_override_material(si)
			if mat == null:
				mat = mi.mesh.surface_get_material(si)
			var fmt: int = 0
			var arrs: Array = mi.mesh.surface_get_arrays(si)
			for ai in range(arrs.size()):
				if arrs[ai] != null:
					fmt |= 1 << ai
			var key := "%d_%d_%d" % [mat.get_instance_id() if mat != null else 0, fmt, int(mi.cast_shadow)]
			if not tools.has(key):
				tools[key] = {"st": SurfaceTool.new(), "mat": mat, "shadow": int(mi.cast_shadow)}
			(tools[key]["st"] as SurfaceTool).append_from(mi.mesh, si, xf)
		mi.mesh = null # el nodo se queda (por si tiene hijos), pero ya no se dibuja
	var by_shadow: Dictionary = {}
	for key in tools:
		var t: Dictionary = tools[key]
		var am: ArrayMesh = by_shadow.get(t["shadow"], null)
		if am == null:
			am = ArrayMesh.new()
			by_shadow[t["shadow"]] = am
		(t["st"] as SurfaceTool).commit(am)
		am.surface_set_material(am.get_surface_count() - 1, t["mat"])
	for sh in by_shadow:
		var out := MeshInstance3D.new()
		out.name = "Juntado"
		out.mesh = by_shadow[sh]
		out.cast_shadow = sh
		root.add_child(out)

func _collect_merge_meshes(n: Node, root: Node, excl: Dictionary, out: Array) -> void:
	for c in n.get_children():
		if excl.has(c):
			continue
		if c is Node3D and not (c as Node3D).visible:
			continue
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			var ok: bool = mi.mesh != null and mi.skin == null and not (mi.mesh is ArrayMesh and (mi.mesh as ArrayMesh).get_blend_shape_count() > 0)
			if ok:
				for si in range(mi.mesh.get_surface_count()):
					if mi.mesh is ArrayMesh and (mi.mesh as ArrayMesh).surface_get_primitive_type(si) != Mesh.PRIMITIVE_TRIANGLES:
						ok = false
			if ok:
				out.append(mi)
		_collect_merge_meshes(c, root, excl, out)

func _populate_building_interior_3d(b_root: Node3D, b_id: String, rect: Rect2, door_south: bool, wall_h: float, m_wall: Material, m_trim: Material, m_wood: Material, m_dark_wood: Material, m_iron: Material, m_gold: Material) -> void:
	var c: Vector2 = rect.get_center()
	var m_bed := _mat("bed_linen", Color(0.84, 0.28, 0.24), 0.85, 0.0)
	var m_pillow := _mat("bed_pillow", Color(0.94, 0.92, 0.86), 0.85, 0.0)
	var m_steel := _mat("morgue_steel", Color(0.74, 0.80, 0.84), 0.30, 0.78)
	var m_shroud := _mat("corpse_shroud", Color(0.82, 0.84, 0.78), 0.90, 0.0)
	var m_felt := _mat("green_felt", Color(0.16, 0.48, 0.26), 0.85, 0.0)
	var m_ember := _mat("forge_ember", Color(1.0, 0.42, 0.12), 0.4, 0.0, Color(1.0, 0.38, 0.08), 2.2)

	match b_id:
		"building_restaurant":
			_build_restaurant_3d(b_root, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)
		"building_tavern":
			_build_tavern_floor_0_3d(b_root, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)
		"building_hospital":
			_build_hospital_and_morgue_3d(b_root, rect, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)
		"building_police":
			_build_police_station_3d(b_root, rect, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)
		"building_church":
			_build_church_chapel_3d(b_root, rect, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)
		"building_library":
			_build_library_3d(b_root, rect, door_south, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)
		"building_abandoned_mill":
			_build_abandoned_mill_3d(b_root, rect, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)
		"building_school":
			var m_dir2: float = -1.0 if door_south else 1.0
			for p in [Vector2(-30, 6), Vector2(0, 6), Vector2(30, 6), Vector2(-30, 26), Vector2(0, 26), Vector2(30, 26)]:
				_add_model_2d(b_root, "props/Bench.gltf", c + Vector2(p.x, p.y * m_dir2), 2.0, Vector2(16.0, 9.0), 6.5)
			_add_box_2d(b_root, c + Vector2(0, -26.0 * m_dir2), Vector2(54.0, 4.0), 8.0, 14.0, _mat("chalkboard", Color(0.14, 0.28, 0.18), 0.9, 0.0))
		"shop_family_smith":
			# Fragua encendida, yunque real sobre tronco, piedra de afilar, soporte de armas y mostrador
			_register_furniture_rect("Forge", c + Vector2(-38, -16), Vector2(20.0, 16.0))
			_add_box_2d(b_root, c + Vector2(-38, -16), Vector2(20.0, 16.0), 2.0, 18.0, m_trim)
			_add_box_2d(b_root, c + Vector2(-38, -14), Vector2(12.0, 10.0), 5.0, 6.0, m_ember)
			_add_model_2d(b_root, "props/Anvil_Log.gltf", c + Vector2(-18, 8), 2.0, Vector2(11.0, 9.0), 9.0)
			_add_model_2d(b_root, "props/Whetstone.gltf", c + Vector2(24, -14), 2.0, Vector2(9.0, 7.5), 9.5)
			_add_model_2d(b_root, "props/WeaponStand.gltf", c + Vector2(34, 12), 2.0, Vector2(16.0, 8.0), 12.0)
			_add_model_2d(b_root, "props/Workbench.gltf", c + Vector2(2, -16), 2.0, Vector2(24.0, 10.5), 8.5)
			# Expositor de Armas de Fuego y Cajas de Munición en la Armería (ARMORY_RACK_POS = c + Vector2(34, 12))
			var rack_p: Vector2 = c + Vector2(34, 12)
			for gx in [-4.5, 0.0, 4.5]:
				var rack_gun: Node3D = AssetLib.instantiate_model("weapons/Pistol_1.obj", Vector3.ZERO, 0.065, true, false)
				if rack_gun != null:
					rack_gun.position = to_3d(rack_p + Vector2(gx, -1.0), 10.5)
					rack_gun.rotation_degrees = Vector3(0.0, 90.0, -25.0)
					b_root.add_child(rack_gun)
			# Dos fusiles largos apoyados en el armero
			for rx in [-6.0, 6.0]:
				_add_box_2d(b_root, rack_p + Vector2(rx, -1.5), Vector2(1.4, 2.2), 2.5, 5.5, m_wood)
				_add_box_2d(b_root, rack_p + Vector2(rx, -1.5), Vector2(1.1, 1.4), 7.5, 9.5, m_iron)
			# Cajas de cartuchos de pistola y fusil sobre el banco del armero
			_add_box_2d(b_root, c + Vector2(8, -16), Vector2(6.5, 4.5), 10.5, 3.8, m_dark_wood)
			_add_box_2d(b_root, c + Vector2(8, -16), Vector2(6.7, 4.7), 12.8, 0.8, m_gold)
			_add_box_2d(b_root, c + Vector2(-4, -16), Vector2(7.5, 5.0), 10.5, 4.2, m_iron)
			_add_box_2d(b_root, c + Vector2(-4, -16), Vector2(7.7, 5.2), 13.0, 0.8, m_gold)
		"mixed_family_herbalist":
			_build_herbalist_apothecary_3d(b_root, rect, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)
		"mixed_family_tinker":
			# Tabiques internos, banco de trabajo, camas traseras y mesa
			_add_box_2d(b_root, c + Vector2(-42, 4), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_box_2d(b_root, c + Vector2(42, 4), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_model_2d(b_root, "props/Workbench.gltf", c + Vector2(0, -10), 2.0, Vector2(24.0, 10.5), 8.5)
			_add_model_2d(b_root, "props/Anvil.gltf", c + Vector2(22, -16), 2.0, Vector2(9.0, 7.0), 7.5)
			_build_bed_3d(b_root, c + Vector2(-36, 26), m_wood, m_bed, m_pillow)
			_build_bed_3d(b_root, c + Vector2(36, 26), m_wood, m_bed, m_pillow)
			_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, 24), 2.0, Vector2(18.0, 12.0), 7.0)
			# Bloque FIS2 (§2.1): Terminal Lógica Electromecánica física sobre una mesa dentro del taller (TINKER_TERMINAL_POS)
			var t_pos: Vector2 = VillageCulture.TINKER_TERMINAL_POS
			var m_copper := _mat("tinker_copper", Color(0.84, 0.48, 0.22), 0.35, 0.78)
			var m_screen := _mat("tinker_screen", Color(0.14, 0.96, 0.34), 0.2, 0.0, Color(0.10, 0.92, 0.28), 3.1)
			var m_card := _mat("tinker_card", Color(0.92, 0.86, 0.70), 0.85, 0.0)
			if _add_model_2d(b_root, "props/Table_Large.gltf", t_pos, 2.0, Vector2(22.0, 14.0), 8.0) == null:
				_add_box_2d(b_root, t_pos, Vector2(22.0, 14.0), 2.0, 8.0, m_dark_wood)
			_add_box_2d(b_root, t_pos + Vector2(0, -1.0), Vector2(18.0, 10.5), 10.0, 12.5, m_iron) # Chasis de acero alto
			_add_box_2d(b_root, t_pos + Vector2(0, -1.0), Vector2(16.0, 8.8), 11.2, 11.8, m_gold) # Bastidor de latón
			_add_box_2d(b_root, t_pos + Vector2(-1.6, 3.8), Vector2(10.5, 2.6), 12.5, 8.2, m_screen) # Visor fosforescente verde hacia cámara
			_add_box_2d(b_root, t_pos + Vector2(0, 4.6), Vector2(13.0, 3.8), 10.0, 2.4, m_iron) # Teclado mecánico frontal
			_add_cyl_2d(b_root, t_pos + Vector2(4.8, -1.2), 2.8, 22.8, 6.0, m_card, 2.8, 10) # Tambor de tarjetas perforadas
			_add_cyl_2d(b_root, t_pos + Vector2(-4.8, -1.6), 2.2, 22.8, 5.5, m_copper, 2.2, 8) # Bobina de relés
			if not _is_headless:
				var term_lt := OmniLight3D.new()
				term_lt.position = to_3d(t_pos + Vector2(0, 2.0), 18.0)
				term_lt.light_color = Color(0.16, 0.96, 0.36)
				term_lt.light_energy = 1.05
				term_lt.omni_range = 2.0
				b_root.add_child(term_lt)
			# Bloque FIS2 (§2.2): Cuadro Eléctrico físico en la pared exterior norte del taller (TINKER_GRID_PANEL_POS)
			var gp_pos: Vector2 = VillageCulture.TINKER_GRID_PANEL_POS
			_add_cyl_2d(b_root, gp_pos + Vector2(5.5, 0.0), 1.2, 2.0, 34.0, m_iron, 1.2, 8) # Tubo de acometida vertical
			_add_box_2d(b_root, gp_pos + Vector2(0, 1.5), Vector2(16.0, 7.0), 22.0, 16.0, m_iron) # Armario metálico en el muro norte
			_add_box_2d(b_root, gp_pos + Vector2(0, 3.0), Vector2(13.6, 5.5), 23.5, 13.0, m_dark_wood) # Placa aislante
			_add_cyl_2d(b_root, gp_pos + Vector2(-4.4, 5.2), 2.2, 25.0, 11.5, m_copper, 2.2, 8) # Bobina izq
			_add_cyl_2d(b_root, gp_pos + Vector2(4.4, 5.2), 2.2, 25.0, 11.5, m_copper, 2.2, 8) # Bobina der
			for sx in [-2.6, 0.0, 2.6]:
				_add_box_2d(b_root, gp_pos + Vector2(sx, 6.2), Vector2(1.5, 3.5), 27.0, 6.5, m_gold) # 3 palancas seccionadoras
			if is_instance_valid(_grid_panel_bulb_3d):
				_grid_panel_bulb_3d.queue_free()
			_grid_panel_bulb_3d = _add_cyl_2d(buildings_root_3d, gp_pos + Vector2(0, 4.5), 2.6, 38.0, 4.5, m_screen, 2.0, 8)
		"building_mansion", "building_manor":
			# Mansión señorial (f1) o Casa solariega (f2): estudio con escritorio, salón y alcoba
			var nob_lot: String = "f1" if b_id == "building_mansion" else "f2"
			var study_p: Vector2 = load("res://scripts/systems/VillageNobility.gd").study_pos(nob_lot)
			if _add_model_2d(b_root, "props/Workbench.gltf", study_p, 2.0, Vector2(22.0, 11.0), 8.2) == null:
				_add_box_2d(b_root, study_p, Vector2(22.0, 11.0), 2.0, 8.2, m_dark_wood)
			var study_ch_p: Vector2 = study_p + Vector2(0, -11.5)
			_add_model_2d(b_root, "props/Chair_1.gltf", study_ch_p, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(study_ch_p, study_p))
			_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, -8), 2.0, Vector2(26.0, 13.0), 7.5)
			_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(-36, -38), 2.0, Vector2(20.0, 9.0), 16.0)
			_build_bed_3d(b_root, c + Vector2(56, -24), m_wood, m_bed, m_pillow)
			_build_bed_3d(b_root, c + Vector2(56, 22), m_wood, m_bed, m_pillow)
		"building_town_hall":
			# Ayuntamiento (n4): mesa municipal en (764, -444), urna, estanterías y terminal de pantalla verde
			var desk_p: Vector2 = c + Vector2(0, -24)
			if _add_model_2d(b_root, "props/Table_Large.gltf", desk_p, 2.0, Vector2(26.0, 13.0), 8.2) == null:
				_add_box_2d(b_root, desk_p, Vector2(26.0, 13.0), 2.0, 8.2, m_dark_wood)
			_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-42, 6), 2.0, Vector2(16.0, 10.0), 12.0)
			_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(36, 6), 2.0, Vector2(18.0, 9.0), 15.0)
			var th_term_p: Vector2 = VillageCulture.TOWN_HALL_TERMINAL_POS
			if _add_model_2d(b_root, "props/Table_Large.gltf", th_term_p, 2.0, Vector2(20.0, 12.0), 8.0) == null:
				_add_box_2d(b_root, th_term_p, Vector2(20.0, 12.0), 2.0, 8.0, m_dark_wood)
			_add_green_crt_terminal_3d(b_root, th_term_p, 10.0, false)
		"building_shelter":
			var sh_dy: float = -20.0 if door_south else 20.0
			for sh_x in [-42.0, -14.0, 14.0, 42.0]:
				_build_bed_3d(b_root, c + Vector2(sh_x, sh_dy), m_wood, m_bed, m_pillow)
		_:
			if b_id.begins_with("shop_"):
				var stall_y: float = -14.0 if door_south else 14.0
				_add_model_2d(b_root, "props/Workbench.gltf", c + Vector2(0, stall_y), 2.0, Vector2(24.0, 10.5), 8.5)
				_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-28, stall_y), 2.0, Vector2(14.0, 10.0), 13.0)
				_add_model_2d(b_root, "props/Barrel_Apples.gltf", c + Vector2(22, stall_y), 2.0, Vector2(9.0, 9.0), 9.5)
			elif b_id.begins_with("mixed_"):
				var m_dir_mix: float = -1.0 if door_south else 1.0
				_add_box_2d(b_root, c + Vector2(-42, 4.0 * m_dir_mix), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
				_add_box_2d(b_root, c + Vector2(42, 4.0 * m_dir_mix), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
				_add_model_2d(b_root, "props/Workbench.gltf", c + Vector2(0, -10.0 * m_dir_mix), 2.0, Vector2(24.0, 10.5), 8.5)
				_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-26, -16.0 * m_dir_mix), 2.0, Vector2(14.0, 9.0), 13.0)
				_build_bed_3d(b_root, c + Vector2(-36, 26.0 * m_dir_mix), m_wood, m_bed, m_pillow)
				_build_bed_3d(b_root, c + Vector2(36, 26.0 * m_dir_mix), m_wood, m_bed, m_pillow)
				_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, 24.0 * m_dir_mix), 2.0, Vector2(18.0, 12.0), 7.0)
			elif b_id.begins_with("house_") or b_id.begins_with("player_house_"):
				var bed_dx: float = 26.0 if rect.size.x < 96.0 else 30.0
				var bed_dy: float = (-12.0 if rect.size.y < 70.0 else -18.0) if door_south else (12.0 if rect.size.y < 70.0 else 18.0)
				var tbl_y: float = 2.0 if door_south else -2.0
				var bk_y: float = 16.0 if door_south else -16.0
				_build_bed_3d(b_root, c + Vector2(-bed_dx, bed_dy), m_wood, m_bed, m_pillow)
				if not b_id.begins_with("player_house_"):
					_build_bed_3d(b_root, c + Vector2(bed_dx, bed_dy), m_wood, m_bed, m_pillow)
				var tbl_p: Vector2 = c + Vector2(2.0, tbl_y)
				var ch_p: Vector2 = c + Vector2(-12.0, tbl_y)
				_add_model_2d(b_root, "props/Table_Large.gltf", tbl_p, 2.0, Vector2(17.0, 11.0), 7.0)
				_add_model_2d(b_root, "props/Chair_1.gltf", ch_p, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(ch_p, tbl_p))
				_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(bed_dx, bk_y), 2.0, Vector2(14.0, 6.0), 16.0)
			else:
				# Edificios cívicos adicionales
				_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, -10 if door_south else 10), 2.0, Vector2(24.0, 12.0), 7.5)
				_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-32, 12 if door_south else -12), 2.0, Vector2(16.0, 9.0), 13.0)
				_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(32, 12 if door_south else -12), 2.0, Vector2(16.0, 9.0), 15.0)

# ==============================================================================
# R1: TRATTORIA «IL CORVO» (comedor, terraza, cocina, cámara frigorífica, bodega, cuarto y reservado)
# ==============================================================================
var _restaurant_night_nodes: Array = [] ## bombillas y luces de la terraza: se encienden al caer la tarde

## Mantel de cuadros rojos y blancos (textura de 2×2 píxeles repetida).
func _checker_cloth_mat() -> StandardMaterial3D:
	if _mat_cache.has("checker_cloth"):
		return _mat_cache["checker_cloth"]
	var m := StandardMaterial3D.new()
	m.roughness = 0.92
	if not _is_headless:
		var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
		img.set_pixel(0, 0, Color(0.42, 0.34, 0.25))
		img.set_pixel(1, 1, Color(0.42, 0.34, 0.25))
		img.set_pixel(1, 0, Color(0.56, 0.46, 0.35))
		img.set_pixel(0, 1, Color(0.56, 0.46, 0.35))
		m.albedo_texture = ImageTexture.create_from_image(img)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(5.0, 5.0, 5.0)
	else:
		m.albedo_color = Color(0.48, 0.39, 0.30)
	_mat_cache["checker_cloth"] = m
	return m

func _restaurant_light(parent: Node3D, pos_2d: Vector2, h_px: float, col: Color, energy: float, rng: float, night_only: bool) -> void:
	if _is_headless:
		return
	var lt := OmniLight3D.new()
	lt.position = to_3d(pos_2d, h_px)
	lt.light_color = col
	lt.light_energy = energy
	lt.omni_range = rng
	lt.shadow_enabled = false
	parent.add_child(lt)
	if night_only:
		_restaurant_night_nodes.append(lt)

## Mesa con mantel de cuadros, vela en botella y dos sillas.
func _restaurant_table_3d(parent: Node3D, p: Vector2, m_wood: Material, round_top: bool) -> void:
	var m_bottle := _mat("chianti_bottle", Color(0.16, 0.42, 0.22, 0.92), 0.2, 0.1)
	var m_flame := _mat("candle_flame", Color(1.0, 0.78, 0.36), 0.4, 0.0, Color(1.0, 0.66, 0.24), 3.0)
	var m_wax := _mat("candle_wax", Color(0.96, 0.92, 0.82), 0.7, 0.0)
	var chair_dx: float = 14.5
	if round_top:
		_register_furniture_rect("TerraceRoundTable", p, Vector2(15.0, 15.0))
		_add_cyl_2d(parent, p, 1.4, 2.0, 7.0, m_wood, 1.4, 8)
		_add_cyl_2d(parent, p, 7.5, 9.0, 0.9, _checker_cloth_mat(), 7.5, 14)
		chair_dx = 12.5
	else:
		_add_model_2d(parent, "props/Table_Large.gltf", p, 2.0, Vector2(18.0, 12.0), 6.8)
		_add_box_2d(parent, p, Vector2(18.6, 12.6), 8.8, 0.7, _checker_cloth_mat())
	_add_cyl_2d(parent, p + Vector2(2, 0), 1.6, 9.6, 4.2, m_bottle, 0.7, 8) # botella de vino con la vela
	_add_cyl_2d(parent, p + Vector2(2, 0), 0.6, 13.8, 1.6, m_wax, 0.6, 6)
	_add_cyl_2d(parent, p + Vector2(2, 0), 0.4, 15.4, 1.0, m_flame, 0.1, 6)
	var ch_l: Vector2 = p + Vector2(-chair_dx, 0)
	var ch_r: Vector2 = p + Vector2(chair_dx, 0)
	_add_model_2d(parent, "props/Chair_1.gltf", ch_l, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(ch_l, p))
	_add_model_2d(parent, "props/Chair_1.gltf", ch_r, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(ch_r, p))

func _build_restaurant_3d(b_root: Node3D, wall_h: float, m_wall: Material, m_trim: Material, m_wood: Material, m_dark_wood: Material, m_iron: Material, m_gold: Material) -> void:
	var R = VillageRestaurant
	var ih: float = wall_h * 0.85
	var m_frost := _mat("frost_tile", Color(0.80, 0.90, 0.96), 0.35, 0.1, Color.BLACK, 0.0, "town_textures/floor_tiles_blue_small.png")
	var m_ice := _mat("ice_block", Color(0.78, 0.92, 1.0, 0.82), 0.1, 0.0)
	var m_meat := _mat("hung_meat", Color(0.66, 0.14, 0.12), 0.6, 0.0)
	var m_fat := _mat("hung_meat_fat", Color(0.92, 0.84, 0.74), 0.7, 0.0)
	var m_steel := _mat("kitchen_steel", Color(0.70, 0.74, 0.78), 0.3, 0.8)
	var m_stove := _mat("stove_iron", Color(0.16, 0.16, 0.18), 0.5, 0.7)
	var m_ember := _mat("stove_ember", Color(1.0, 0.40, 0.12), 0.4, 0.0, Color(1.0, 0.36, 0.08), 2.4)
	var m_rug := _mat("backroom_rug", Color(0.46, 0.08, 0.10), 0.95, 0.0)
	var m_felt := _mat("piano_keys", Color(0.95, 0.94, 0.90), 0.6, 0.0)
	var m_black := _mat("piano_black", Color(0.06, 0.05, 0.05), 0.35, 0.2)
	var m_tile := _mat("kitchen_tile", Color(0.86, 0.84, 0.78), 0.6, 0.0, Color.BLACK, 0.0, "town_textures/floor_tiles_sand_small.png")
	var m_terr := _mat("terrace_slabs", Color(0.70, 0.52, 0.40), 0.9, 0.0, Color.BLACK, 0.0, "town_textures/floor_stone_sand_random.png")
	var m_canvas_g := _mat("parasol_green", Color(0.20, 0.44, 0.26), 0.9, 0.0)
	var m_canvas_w := _mat("parasol_cream", Color(0.95, 0.90, 0.78), 0.9, 0.0)
	var m_bulb := _mat("string_bulb", Color(1.0, 0.86, 0.52), 0.3, 0.0, Color(1.0, 0.78, 0.40), 2.6)
	var m_frame := _mat("painting_frame", Color(0.62, 0.46, 0.18), 0.5, 0.6)
	var m_canvas_p := _mat("painting_canvas", Color(0.30, 0.22, 0.16), 0.9, 0.0)
	var m_plant := _mat("pot_plant", Color(0.22, 0.46, 0.20), 0.9, 0.0)
	var m_pot := _mat("terracotta_pot", Color(0.70, 0.36, 0.22), 0.85, 0.0)

	# --- Tabiques (los mismos huecos que en 2D)
	var x0: float = R.RECT.position.x
	var x1: float = R.RECT.end.x
	var cur: float = x0
	var gaps: Array[float] = []
	for o in R.OPENINGS:
		if str(o["axis"]) == "h":
			gaps.append(float((o["pos"] as Vector2).x))
	gaps.sort()
	for gx in gaps:
		var a: float = gx - R.GAP * 0.5
		if a - cur > 2.0:
			_add_box_2d(b_root, Vector2((cur + a) * 0.5, R.ROW_Y), Vector2(a - cur, 5.5), 2.0, ih, m_wall)
		_add_box_2d(b_root, Vector2(gx, R.ROW_Y), Vector2(R.GAP + 4.0, 5.5), 2.0 + ih * 0.78, ih * 0.22, m_trim) # dintel
		cur = gx + R.GAP * 0.5
	if x1 - cur > 2.0:
		_add_box_2d(b_root, Vector2((cur + x1) * 0.5, R.ROW_Y), Vector2(x1 - cur, 5.5), 2.0, ih, m_wall)
	for vx in [R.BASE.x + 85.0, R.BASE.x + 140.0]:
		_add_box_2d(b_root, Vector2(vx, (R.RECT.position.y + R.ROW_Y) * 0.5), Vector2(5.5, R.ROW_Y - R.RECT.position.y), 2.0, ih, m_wall)
	var top: float = R.RECT.position.y
	var bottom: float = R.RECT.end.y
	var gy: float = R.BASE.y + 135.0
	_add_box_2d(b_root, Vector2(R.KITCHEN_X, (top + gy - R.GAP * 0.5) * 0.5), Vector2(5.5, gy - R.GAP * 0.5 - top), 2.0, ih, m_wall)
	_add_box_2d(b_root, Vector2(R.KITCHEN_X, (gy + R.GAP * 0.5 + bottom) * 0.5), Vector2(5.5, bottom - gy - R.GAP * 0.5), 2.0, ih, m_wall)
	_add_box_2d(b_root, Vector2(R.KITCHEN_X, gy), Vector2(5.5, R.GAP + 4.0), 2.0 + ih * 0.78, ih * 0.22, m_trim)

	# --- Suelos de cada sala sobre el suelo general (baldosa de barro)
	_add_box_2d(b_root, R.ROOMS["cocina"].get_center(), R.ROOMS["cocina"].size - Vector2(6, 6), 2.5, 0.4, m_tile)
	_add_box_2d(b_root, R.ROOMS["camara"].get_center(), R.ROOMS["camara"].size - Vector2(6, 6), 2.5, 0.4, m_frost)
	_add_box_2d(b_root, R.ROOMS["bodega"].get_center(), R.ROOMS["bodega"].size - Vector2(6, 6), 2.5, 0.4, m_dark_wood)
	_add_box_2d(b_root, R.BACKROOM_TABLE, Vector2(58, 46), 2.5, 0.4, m_rug)

	# --- Comedor: mesas con mantel de cuadros, barra, piano, cuadros, plantas y dos arañas de luz
	for t in R.DINING_TABLES:
		_restaurant_table_3d(b_root, t, m_wood, false)
	_register_furniture_rect("RestaurantCounter", R.COUNTER_POS, Vector2(34.0, 9.0))
	_add_box_2d(b_root, R.COUNTER_POS, Vector2(34, 9), 2.0, 10.0, m_dark_wood) # barra
	_add_box_2d(b_root, R.COUNTER_POS, Vector2(36, 10.5), 12.0, 1.0, m_gold) # canto de latón
	_add_model_2d(b_root, "props/Shelf_Small_Bottles.gltf", R.COUNTER_POS + Vector2(4, 12), 2.0, Vector2(18.0, 5.0), 16.0)
	for bx in [-10.0, -4.0, 8.0]:
		_add_model_2d(b_root, "props/Bottle_1.gltf", R.COUNTER_POS + Vector2(bx, -1), 13.0, Vector2(2.5, 2.5), 5.0)
	_add_model_2d(b_root, "props/Mug.gltf", R.COUNTER_POS + Vector2(2, -1), 13.0, Vector2(3.0, 3.0), 3.5)
	# Piano vertical contra la pared
	_register_furniture_rect("Piano", R.PIANO_POS, Vector2(22.0, 9.0))
	_add_box_2d(b_root, R.PIANO_POS, Vector2(22, 9), 2.0, 16.0, m_black)
	_add_box_2d(b_root, R.PIANO_POS + Vector2(0, -5.0), Vector2(20, 3), 9.0, 1.2, m_felt)
	_register_furniture_rect("PianoBench", R.PIANO_POS + Vector2(0, -9.5), Vector2(10.0, 5.0))
	_add_box_2d(b_root, R.PIANO_POS + Vector2(0, -9.5), Vector2(10, 5), 2.0, 6.0, m_dark_wood) # banqueta
	for pp in [R.BASE + Vector2(40, 83), R.BASE + Vector2(150, 83)]: # cuadros en el tabique del fondo
		_add_box_2d(b_root, pp, Vector2(16, 1.5), 13.0, 11.0, m_frame)
		_add_box_2d(b_root, pp + Vector2(0, 0.6), Vector2(13, 1.0), 14.5, 8.0, m_canvas_p)
	for pl_p in [R.BASE + Vector2(8, 88), R.BASE + Vector2(187, 88), R.BASE + Vector2(187, 184)]:
		_add_cyl_2d(b_root, pl_p, 3.5, 2.0, 5.0, m_pot, 2.8, 10)
		_add_cyl_2d(b_root, pl_p, 4.5, 7.0, 7.0, m_plant, 1.5, 8)
	for ch in [R.BASE + Vector2(46, 132), R.BASE + Vector2(138, 132)]:
		_add_model_2d(b_root, "props/Chandelier.gltf", ch, ih - 8.0, Vector2(12.0, 12.0), 7.0)
		_restaurant_light(b_root, ch, ih - 6.0, Color(1.0, 0.80, 0.52), 1.15, 2.6, false)

	# --- Cocina: fogones con brasas, ollas, encimera, fregadero y cajas de verdura
	_register_furniture_rect("KitchenStove", R.STOVE_POS, Vector2(24.0, 12.0))
	_add_box_2d(b_root, R.STOVE_POS, Vector2(24, 12), 2.0, 10.0, m_stove)
	_add_box_2d(b_root, R.STOVE_POS, Vector2(20, 9), 12.0, 0.6, m_ember)
	_add_model_2d(b_root, "props/Cauldron.gltf", R.STOVE_POS + Vector2(-5, 0), 12.0, Vector2(8.0, 8.0), 6.0)
	_add_model_2d(b_root, "props/Pot_1.gltf", R.STOVE_POS + Vector2(6, 0), 12.0, Vector2(6.0, 6.0), 4.5)
	_add_box_2d(b_root, R.STOVE_POS + Vector2(0, -8), Vector2(26, 3), 22.0, 10.0, m_steel) # campana
	_add_model_2d(b_root, "props/Workbench.gltf", R.KITCHEN_COUNTER, 2.0, Vector2(28.0, 10.0), 10.0)
	_register_furniture_rect("KitchenSink", R.BASE + Vector2(210, 114), Vector2(10.0, 16.0))
	_add_box_2d(b_root, R.BASE + Vector2(210, 114), Vector2(10, 16), 2.0, 9.0, m_steel) # fregadero
	_add_model_2d(b_root, "props/Bucket_Metal.gltf", R.BASE + Vector2(210, 130), 2.0, Vector2(5.0, 5.0), 5.0)
	_add_model_2d(b_root, "props/FarmCrate_Carrot.gltf", R.BASE + Vector2(266, 148), 2.0, Vector2(9.0, 7.0), 6.0)
	_add_model_2d(b_root, "props/FarmCrate_Apple.gltf", R.BASE + Vector2(266, 162), 2.0, Vector2(9.0, 7.0), 6.0)
	_add_model_2d(b_root, "props/Barrel_Apples.gltf", R.BASE + Vector2(210, 178), 2.0, Vector2(8.0, 8.0), 9.0)
	_restaurant_light(b_root, R.BASE + Vector2(235, 126), ih - 4.0, Color(1.0, 0.92, 0.80), 0.9, 2.2, false)

	# --- Cámara frigorífica: paredes forradas de escarcha, bloques de hielo, carne colgada de un riel y marco de acero
	var cam: Rect2 = R.ROOMS["camara"]
	_add_box_2d(b_root, Vector2(cam.get_center().x, cam.position.y + 4.0), Vector2(cam.size.x - 8.0, 2.0), 2.0, ih - 2.0, m_frost)
	_add_box_2d(b_root, Vector2(cam.end.x - 4.0, cam.get_center().y), Vector2(2.0, cam.size.y - 8.0), 2.0, ih - 2.0, m_frost)
	_add_box_2d(b_root, Vector2(cam.position.x + 4.0, cam.get_center().y), Vector2(2.0, cam.size.y - 8.0), 2.0, ih - 2.0, m_frost)
	for ip in [R.BASE + Vector2(206, 8), R.BASE + Vector2(206, 22), R.BASE + Vector2(268, 10), R.BASE + Vector2(268, 24)]:
		_add_box_2d(b_root, ip, Vector2(10, 10), 2.0, 8.0, m_ice)
	_add_box_2d(b_root, R.BASE + Vector2(242, 18), Vector2(46, 1.5), ih - 5.0, 1.5, m_steel) # riel de ganchos
	for mp in [R.BASE + Vector2(226, 18), R.BASE + Vector2(238, 18), R.BASE + Vector2(250, 18), R.BASE + Vector2(260, 18)]:
		_add_box_2d(b_root, mp, Vector2(0.6, 0.6), ih - 9.0, 4.0, m_steel) # gancho
		_add_box_2d(b_root, mp, Vector2(5.5, 4.0), ih - 23.0, 14.0, m_meat) # pieza de carne
		_add_box_2d(b_root, mp + Vector2(0, -1.0), Vector2(5.8, 2.0), ih - 13.0, 3.0, m_fat)
	_add_model_2d(b_root, "props/Crate_Metal.gltf", R.BASE + Vector2(264, 56), 2.0, Vector2(10.0, 10.0), 8.0)
	_add_model_2d(b_root, "props/Crate_Wooden.gltf", R.BASE + Vector2(264, 44), 10.0, Vector2(8.0, 8.0), 6.0)
	var cam_gap: Vector2 = Vector2(R.BASE.x + 235.0, R.ROW_Y)
	for side in [-1.0, 1.0]:
		_add_box_2d(b_root, cam_gap + Vector2(side * (R.GAP * 0.5 + 1.0), 0), Vector2(3.0, 7.0), 2.0, ih, m_steel)
	_add_box_2d(b_root, cam_gap, Vector2(R.GAP + 6.0, 7.0), 2.0 + ih * 0.78, ih * 0.22, m_steel)
	_restaurant_light(b_root, cam.get_center(), ih - 4.0, Color(0.62, 0.82, 1.0), 0.75, 1.8, false)

	# --- Bodega: barriles y botellero
	for bp in [R.BASE + Vector2(96, 48), R.BASE + Vector2(96, 62), R.BASE + Vector2(130, 48)]:
		_add_model_2d(b_root, "props/Barrel.gltf", bp, 2.0, Vector2(10.0, 10.0), 11.0)
	_add_model_2d(b_root, "props/Barrel.gltf", R.BASE + Vector2(96, 55), 13.0, Vector2(9.0, 9.0), 10.0, 90.0)
	_add_model_2d(b_root, "props/Shelf_Simple.gltf", R.WINE_RACK, 2.0, Vector2(30.0, 6.0), 20.0)
	for wy in [6.0, 12.0, 18.0]:
		for wx in [-10.0, -4.0, 2.0, 8.0]:
			_add_cyl_2d(b_root, R.WINE_RACK + Vector2(wx, 0), 1.0, wy, 3.5, _mat("chianti_bottle", Color(0.16, 0.42, 0.22, 0.92), 0.2, 0.1), 0.5, 6)

	# --- Despacho del dueño: escritorio de madera noble, silla de dirección, estantería, libro de cuentas y alfombra
	_add_box_2d(b_root, R.BASE + Vector2(164, 36), Vector2(28, 22), 2.0, 0.5, _mat("office_rug", Color(0.46, 0.14, 0.14), 0.92, 0.0))
	var own_desk_p: Vector2 = R.OWNER_BED + Vector2(4, 6)
	var own_ch_n: Vector2 = R.OWNER_BED + Vector2(4, -5)
	var own_ch_s: Vector2 = R.OWNER_BED + Vector2(4, 15)
	_add_model_2d(b_root, "props/Workbench.gltf", own_desk_p, 2.0, Vector2(18.0, 10.0), 9.0)
	_add_model_2d(b_root, "props/Chair_1.gltf", own_ch_n, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(own_ch_n, own_desk_p))
	_add_model_2d(b_root, "props/Chair_1.gltf", own_ch_s, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(own_ch_s, own_desk_p))
	_add_model_2d(b_root, "props/Book_5.gltf", R.OWNER_BED + Vector2(1, 5), 11.0, Vector2(5.0, 4.0), 2.2)
	_add_model_2d(b_root, "props/CandleStick_Triple.gltf", R.OWNER_BED + Vector2(9, 4), 11.0, Vector2(4.0, 4.0), 5.5)
	_add_model_2d(b_root, "props/Shelf_Simple.gltf", R.BASE + Vector2(148, 8), 2.0, Vector2(12.0, 5.0), 18.0)
	_add_model_2d(b_root, "props/Nightstand_Shelf.gltf", R.BASE + Vector2(148, 46), 2.0, Vector2(7.0, 6.0), 8.0)

	# --- Reservado: mesa redonda grande, cinco sillas, candelabro, chimenea y luz roja tenue
	_register_furniture_rect("BackroomRoundTable", R.BACKROOM_TABLE, Vector2(21.0, 21.0))
	_add_cyl_2d(b_root, R.BACKROOM_TABLE, 2.0, 2.0, 7.0, m_dark_wood, 2.0, 8)
	_add_cyl_2d(b_root, R.BACKROOM_TABLE, 12.5, 9.0, 1.0, _mat("backroom_cloth", Color(0.92, 0.90, 0.84), 0.9, 0.0), 12.5, 18)
	_add_model_2d(b_root, "props/CandleStick_Triple.gltf", R.BACKROOM_TABLE, 10.0, Vector2(5.0, 5.0), 7.0)
	for i in range(5):
		var ang: float = TAU * float(i) / 5.0 + PI * 0.5
		var cp: Vector2 = R.BACKROOM_TABLE + Vector2(cos(ang), sin(ang)) * 21.5
		_add_model_2d(b_root, "props/Chair_1.gltf", cp, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(cp, R.BACKROOM_TABLE))
	_add_box_2d(b_root, R.BASE + Vector2(8, 12), Vector2(9, 18), 2.0, 16.0, _mat("fireplace_stone", Color(0.50, 0.46, 0.42), 0.9, 0.0))
	_add_box_2d(b_root, R.BASE + Vector2(11, 12), Vector2(3, 12), 3.0, 6.0, m_ember)
	_restaurant_light(b_root, R.BACKROOM_TABLE, ih - 8.0, Color(1.0, 0.46, 0.30), 0.85, 1.8, false)

	# --- Terraza: losas, mesas con sombrilla, macetas, guirnalda de bombillas, toldo verde y letrero
	_add_box_2d(b_root, R.TERRACE.get_center(), R.TERRACE.size, 0.0, 1.2, m_terr)
	for t in R.TERRACE_TABLES:
		_restaurant_table_3d(b_root, t, m_wood, true)
		_add_cyl_2d(b_root, t, 0.6, 9.0, 18.0, m_wood, 0.6, 6) # palo de la sombrilla
		_add_cyl_2d(b_root, t, 13.0, 27.0, 4.0, m_canvas_g if (int(t.x) % 2 == 0) else m_canvas_w, 0.8, 12)
	for pp in [R.BASE + Vector2(4, 232), R.BASE + Vector2(270, 232), R.BASE + Vector2(80, 232), R.BASE + Vector2(120, 232)]:
		_add_cyl_2d(b_root, pp, 3.8, 1.2, 5.5, m_pot, 3.0, 10) # maceta de barro
		_add_cyl_2d(b_root, pp, 3.2, 6.5, 3.0, m_plant, 5.0, 10) # mata redonda
		_add_cyl_2d(b_root, pp, 5.0, 9.5, 3.5, m_plant, 2.0, 10)
	# Postes y guirnalda de bombillas a lo largo de la terraza (se encienden al caer la tarde)
	var posts: Array[Vector2] = [R.BASE + Vector2(2, 234), R.BASE + Vector2(80, 234), R.BASE + Vector2(120, 234), R.BASE + Vector2(208, 234), R.BASE + Vector2(273, 234)]
	for pi in range(posts.size()):
		_add_cyl_2d(b_root, posts[pi], 0.8, 1.2, 30.0, m_iron, 0.8, 6)
		if pi + 1 < posts.size():
			var a2: Vector2 = posts[pi]
			var b2: Vector2 = posts[pi + 1]
			for k in range(1, 6):
				var tk: float = float(k) / 6.0
				var sag: float = 4.0 * sin(tk * PI)
				var bulb := _add_cyl_2d(b_root, a2.lerp(b2, tk), 0.9, 29.0 - sag, 1.6, m_bulb, 0.9, 6)
				_restaurant_night_nodes.append(bulb)
	_restaurant_light(b_root, R.BASE + Vector2(60, 216), 26.0, Color(1.0, 0.80, 0.46), 0.9, 2.4, true)
	_restaurant_light(b_root, R.BASE + Vector2(210, 216), 26.0, Color(1.0, 0.80, 0.46), 0.9, 2.4, true)
	# Toldo verde sobre la puerta y faroles
	var door_c: Vector2 = Vector2(R.DOOR_X, R.RECT.end.y + 6.0)
	_add_box_2d(b_root, door_c, Vector2(R.DOOR_W + 26.0, 12.0), wall_h * 0.72, 2.0, m_canvas_g)
	_add_box_2d(b_root, door_c + Vector2(0, 6.0), Vector2(R.DOOR_W + 26.0, 1.0), wall_h * 0.72 - 3.0, 3.0, m_canvas_w)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", Vector2(R.DOOR_X - 24.0, R.RECT.end.y + 2.0), wall_h * 0.55, Vector2(4.0, 4.0), 6.0)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", Vector2(R.DOOR_X + 24.0, R.RECT.end.y + 2.0), wall_h * 0.55, Vector2(4.0, 4.0), 6.0)
	# Sendero desde el camino del este
	_add_box_2d(b_root, R.PATH_RECT.get_center(), R.PATH_RECT.size, 0.0, 0.8, m_terr)

func _build_bed_3d(parent: Node3D, pos_2d: Vector2, m_frame: Material, m_blanket: Material, m_pillow: Material) -> void:
	_build_bed_3d_at_h(parent, pos_2d, 2.0, m_frame, m_blanket, m_pillow)

func _build_bed_3d_at_h(parent: Node3D, pos_2d: Vector2, base_h: float, m_frame: Material, m_blanket: Material, m_pillow: Material) -> void:
	var bed := _add_model_2d(parent, "props/Bed_Twin1.gltf", pos_2d, base_h, Vector2(15.0, 21.0), 8.5)
	if bed != null:
		return
	_add_box_2d(parent, pos_2d, Vector2(15.0, 21.0), base_h, 4.5, m_frame)
	_add_box_2d(parent, pos_2d + Vector2(0, 2.0), Vector2(13.5, 15.0), base_h + 4.5, 2.0, m_blanket)
	_add_box_2d(parent, pos_2d + Vector2(0, -6.5), Vector2(11.0, 4.5), base_h + 4.5, 2.2, m_pillow)

## Paso 3: Planta Baja (Planta 0) de la Gran Taberna «El Jabalí Dorado» (Salón-Comedor, Barra-Cocina, Casino con Póker y Mesa de Billar real 3D, Escalera al Piso +1 y Bodega con Trampilla del Club).
func _build_tavern_floor_0_3d(b_root: Node3D, _wall_h: float, m_wall: Material, m_trim: Material, m_wood: Material, m_dark_wood: Material, m_iron: Material, m_gold: Material) -> void:
	var T = VillageTavern
	var ih0: float = 30.2
	var m_felt := _mat("tavern_green_felt", Color(0.12, 0.52, 0.28), 0.82, 0.0)
	var m_carpet := _mat("tavern_casino_carpet", Color(0.34, 0.13, 0.15), 0.94, 0.0, Color.BLACK, 0.0, "town_textures/rf_planks.png")
	var m_hall_rug := _mat("tavern_hall_rug", Color(0.36, 0.18, 0.14), 0.94, 0.0, Color.BLACK, 0.0, "town_textures/rf_planks.png")
	var m_tile := _mat("tavern_kitchen_tile", Color(0.76, 0.70, 0.62), 0.75, 0.0, Color.BLACK, 0.0, "town_textures/floor_tiles_sand_small.png")
	var m_stone := _mat("tavern_hearth_stone", Color(0.52, 0.48, 0.44), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png")
	var m_soot := _mat("tavern_hearth_soot", Color(0.12, 0.11, 0.10), 0.96, 0.0)
	var m_log := _mat("tavern_firewood_log", Color(0.22, 0.14, 0.09), 0.92, 0.0)
	var m_stove := _mat("tavern_stove_iron", Color(0.16, 0.16, 0.18), 0.48, 0.72)
	var m_ember := _mat("tavern_ember_coal", Color(0.68, 0.18, 0.05), 0.65, 0.0, Color(0.72, 0.16, 0.03), 0.55)
	var m_plate := _mat("tavern_plate", Color(0.92, 0.90, 0.84), 0.45, 0.05)
	var m_chip_red := _mat("poker_chip_red", Color(0.84, 0.18, 0.18), 0.55, 0.1)
	var m_chip_blue := _mat("poker_chip_blue", Color(0.18, 0.38, 0.82), 0.55, 0.1)

	# 1. Tabiques interiores de Planta 0 (con los mismos huecos de paso que en VillageTavern.OPENINGS_FLOOR_0 y sin solapar en x=480)
	var x0: float = T.RECT.position.x
	var x1: float = T.RECT.end.x
	var h_segs: Array[Vector2] = [
		Vector2(x0 + 2.5, 432.0 - T.GAP * 0.5),
		Vector2(432.0 + T.GAP * 0.5, T.EAST_WING_X - 2.8),
		Vector2(T.EAST_WING_X + 2.8, 534.0 - T.GAP * 0.5),
		Vector2(534.0 + T.GAP * 0.5, 555.6),
	]
	for hs in h_segs:
		if hs.y - hs.x > 1.5:
			_add_box_2d(b_root, Vector2((hs.x + hs.y) * 0.5, T.MID_WALL_Y), Vector2(hs.y - hs.x, 5.2), 2.0, ih0, m_wall)
	for gx in [432.0, 534.0]:
		_add_box_2d(b_root, Vector2(gx, T.MID_WALL_Y), Vector2(T.GAP + 4.0, 5.6), 2.0 + ih0 * 0.78, ih0 * 0.22, m_trim)
		_add_box_2d(b_root, Vector2(gx - T.GAP * 0.5, T.MID_WALL_Y), Vector2(2.4, 5.8), 2.0, ih0 * 0.78, m_trim)
		_add_box_2d(b_root, Vector2(gx + T.GAP * 0.5, T.MID_WALL_Y), Vector2(2.4, 5.8), 2.0, ih0 * 0.78, m_trim)
	_add_box_2d(b_root, Vector2(558.0, -223.0), Vector2(4.8, 42.0), 2.0, ih0, m_wall)

	var y0: float = T.RECT.position.y + 2.5
	var y1: float = T.RECT.end.y - 2.5
	var v_gaps: Array[float] = [-276.0, -182.0]
	var cur_y: float = y0
	for gy in v_gaps:
		var ay: float = gy - T.GAP * 0.5
		if ay - cur_y > 2.0:
			_add_box_2d(b_root, Vector2(T.EAST_WING_X, (cur_y + ay) * 0.5), Vector2(5.5, ay - cur_y), 2.0, ih0, m_wall)
		_add_box_2d(b_root, Vector2(T.EAST_WING_X, gy), Vector2(5.8, T.GAP + 4.0), 2.0 + ih0 * 0.78, ih0 * 0.22, m_trim)
		_add_box_2d(b_root, Vector2(T.EAST_WING_X, gy - T.GAP * 0.5), Vector2(5.8, 2.4), 2.0, ih0 * 0.78, m_trim)
		_add_box_2d(b_root, Vector2(T.EAST_WING_X, gy + T.GAP * 0.5), Vector2(5.8, 2.4), 2.0, ih0 * 0.78, m_trim)
		cur_y = gy + T.GAP * 0.5
	if y1 - cur_y > 2.0:
		_add_box_2d(b_root, Vector2(T.EAST_WING_X, (cur_y + y1) * 0.5), Vector2(5.5, y1 - cur_y), 2.0, ih0, m_wall)

	# 2. Pavimentos diferenciados por sala en Planta 0 (loseta en cocina, tapiz granate en casino, losa guardafuegos ante la chimenea y felpudo de entrada)
	_add_box_2d(b_root, T.ROOMS_FLOOR_0["barra_cocina"].get_center(), T.ROOMS_FLOOR_0["barra_cocina"].size - Vector2(8, 8), 2.5, 0.35, m_tile)
	_add_box_2d(b_root, T.ROOMS_FLOOR_0["casino"].get_center(), T.ROOMS_FLOOR_0["casino"].size - Vector2(10, 10), 2.5, 0.38, m_carpet)
	_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(10.5, 0.0), Vector2(10.0, 32.0), 2.5, 0.32, m_stone) # Losa guardafuegos de piedra frente al hogar
	_add_box_2d(b_root, T.DOOR_POS + Vector2(0.0, -12.0), Vector2(28.0, 13.0), 2.5, 0.26, m_dark_wood)
	_add_box_2d(b_root, T.DOOR_POS + Vector2(0.0, -12.0), Vector2(25.0, 10.5), 2.55, 0.28, m_hall_rug)

	# 3. Gran Salón y Comedor: Hogar de piedra con boca oscura, leños, morillos, caldero y repisa de roble (sin franja amarilla plana)
	_register_furniture_rect("TavernFireplace", T.FIREPLACE_POS, Vector2(14.0, 32.0))
	# Pilares laterales de sillería, fondo tiznado de hollín, solera y campana superior de piedra
	_add_box_2d(b_root, T.FIREPLACE_POS, Vector2(14.0, 32.0), 2.0, 2.2, m_stone) # Solera del hogar
	_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(0.0, -11.5), Vector2(14.0, 9.0), 4.2, 10.2, m_stone) # Jamba norte de piedra
	_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(0.0, 11.5), Vector2(14.0, 9.0), 4.2, 10.2, m_stone) # Jamba sur de piedra
	_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(-4.2, 0.0), Vector2(5.6, 15.0), 4.2, 10.2, m_soot) # Fondo oscuro del hogar
	_add_box_2d(b_root, T.FIREPLACE_POS, Vector2(14.0, 32.0), 14.4, 16.0, m_stone) # Campana y tiro superior
	_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(2.0, 0.0), Vector2(16.0, 35.0), 15.6, 2.2, m_dark_wood) # Repisa de roble
	# Morillos de forja, leños de roble apilados, rescoldo bajo de brasas y caldero colgado en el interior del hogar
	for ay_f in [-5.0, 5.0]:
		_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(2.0, ay_f), Vector2(6.5, 1.2), 4.2, 1.4, m_stove)
		_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(4.6, ay_f), Vector2(1.4, 1.4), 4.2, 4.2, m_stove)
	_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(1.2, 0.0), Vector2(4.2, 11.5), 4.2, 0.65, m_ember) # Rescoldo bajo entre la ceniza
	_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(0.6, 0.0), Vector2(2.6, 12.0), 5.2, 2.2, m_log)
	_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(2.8, 0.5), Vector2(2.4, 11.2), 5.2, 2.0, m_log)
	_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(1.6, -0.4), Vector2(2.2, 10.4), 7.0, 1.9, m_log)
	_add_model_2d(b_root, "props/Cauldron.gltf", T.FIREPLACE_POS + Vector2(2.2, 0.0), 7.6, Vector2(6.8, 6.8), 5.0)
	_add_model_2d(b_root, "props/CandleStick.gltf", T.FIREPLACE_POS + Vector2(3.5, -12.0), 17.8, Vector2(3.0, 3.0), 4.6)
	_add_model_2d(b_root, "props/Mug.gltf", T.FIREPLACE_POS + Vector2(3.5, 11.0), 17.8, Vector2(3.2, 3.2), 3.6)
	_restaurant_light(b_root, T.FIREPLACE_POS + Vector2(8.0, 0.0), 9.0, Color(1.0, 0.58, 0.24), 0.85, 2.2, false)

	for ti in range(T.DINING_TABLES.size()):
		var tp: Vector2 = T.DINING_TABLES[ti]
		if _add_model_2d(b_root, "props/Table_Large.gltf", tp, 2.0, Vector2(19.0, 12.5), 7.2) == null:
			_add_box_2d(b_root, tp, Vector2(19.0, 12.5), 2.0, 7.2, m_wood)
		# 2 sillas enfrentadas (izquierda y derecha de cada mesa), orientadas de cara a la mesa
		var t_ch_l: Vector2 = tp + Vector2(-15.0, 0.0)
		var t_ch_r: Vector2 = tp + Vector2(15.0, 0.0)
		_add_model_2d(b_root, "props/Chair_1.gltf", t_ch_l, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(t_ch_l, tp))
		_add_model_2d(b_root, "props/Chair_1.gltf", t_ch_r, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(t_ch_r, tp))
		# Platos y jarras servidas sobre la mesa
		_add_cyl_2d(b_root, tp + Vector2(-5.5, -1.5), 2.6, 9.2, 0.5, m_plate, 2.2, 10)
		_add_cyl_2d(b_root, tp + Vector2(5.5, 1.5), 2.6, 9.2, 0.5, m_plate, 2.2, 10)
		_add_model_2d(b_root, "props/Mug.gltf", tp + Vector2(-4.0, 2.5), 9.2, Vector2(3.2, 3.2), 3.6)
		_add_model_2d(b_root, "props/Mug.gltf", tp + Vector2(4.5, -2.5), 9.2, Vector2(3.2, 3.2), 3.6)
		if (ti % 2) == 0:
			_add_model_2d(b_root, "props/CandleStick_Triple.gltf", tp, 9.2, Vector2(3.8, 3.8), 5.0)

	for ch_pos in [Vector2(332.0, -172.0), Vector2(416.0, -172.0)]:
		_add_model_2d(b_root, "props/Chandelier.gltf", ch_pos, 24.5, Vector2(12.0, 12.0), 6.5)
		_restaurant_light(b_root, ch_pos, 25.0, Color(1.0, 0.80, 0.48), 1.25, 3.2, false)

	# Faroles en la fachada sur de la taberna
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", T.DOOR_POS + Vector2(-28.0, 3.0), 18.0, Vector2(4.2, 4.2), 6.2)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", T.DOOR_POS + Vector2(28.0, 3.0), 18.0, Vector2(4.2, 4.2), 6.2)

	# 4. Barra del Tabernero (con Marta detrás), Pasa-platos del Camarero, Toneles y Cocina
	_register_furniture_rect("TavernBarCounter", T.BAR_COUNTER_POS, Vector2(88.0, 10.0))
	_add_box_2d(b_root, T.BAR_COUNTER_POS, Vector2(86.0, 10.0), 2.0, 10.0, m_dark_wood)
	_add_box_2d(b_root, T.BAR_COUNTER_POS, Vector2(88.0, 11.0), 11.6, 1.2, m_wood)
	_add_box_2d(b_root, T.BAR_COUNTER_POS + Vector2(0.0, 5.4), Vector2(84.0, 1.2), 3.6, 0.9, m_gold) # Barra reposapiés de latón
	# 3 tiradores de cerveza de latón + jarras y botellas
	for tap_x in [-24.0, 0.0, 24.0]:
		_add_cyl_2d(b_root, T.BAR_COUNTER_POS + Vector2(tap_x, -2.0), 1.1, 12.8, 4.2, m_gold, 0.8, 8)
	_add_model_2d(b_root, "props/Mug.gltf", T.BAR_COUNTER_POS + Vector2(-32.0, 1.0), 12.8, Vector2(3.8, 3.8), 4.0)
	_add_model_2d(b_root, "props/Mug.gltf", T.BAR_COUNTER_POS + Vector2(-10.0, 1.5), 12.8, Vector2(3.8, 3.8), 4.0)
	_add_model_2d(b_root, "props/Chalice.gltf", T.BAR_COUNTER_POS + Vector2(12.0, 1.0), 12.8, Vector2(3.8, 3.8), 4.4)
	_add_model_2d(b_root, "props/Bottle_1.gltf", T.BAR_COUNTER_POS + Vector2(34.0, -1.0), 12.8, Vector2(2.8, 2.8), 5.2)
	# 4 taburetes altos frente a la barra
	for st_x in [-33.0, -11.0, 11.0, 33.0]:
		var st_pos: Vector2 = T.BAR_COUNTER_POS + Vector2(st_x, 9.5)
		_register_furniture_rect("BarStool", st_pos, Vector2(6.5, 6.5))
		_add_cyl_2d(b_root, st_pos, 1.2, 2.0, 5.8, m_dark_wood, 1.8, 8)
		_add_cyl_2d(b_root, st_pos, 3.25, 7.8, 1.1, m_wood, 3.25, 10)
	# Pasa-platos del camarero al este de la barra
	var pass_c: Vector2 = T.PASS_COUNTER_POS + Vector2(2.0, 8.0)
	_register_furniture_rect("TavernPassCounter", pass_c, Vector2(21.0, 9.5))
	_add_box_2d(b_root, pass_c, Vector2(20.0, 8.5), 2.0, 9.8, m_dark_wood)
	_add_box_2d(b_root, pass_c, Vector2(21.0, 9.5), 11.6, 1.0, m_gold)
	_add_cyl_2d(b_root, pass_c + Vector2(-4.0, 0.0), 3.2, 12.6, 0.6, m_plate, 2.8, 10)
	_add_model_2d(b_root, "props/Mug.gltf", pass_c + Vector2(4.0, 0.0), 12.6, Vector2(3.5, 3.5), 3.8)
	# Estantería de botellas tras Marta y hilera de grandes toneles de roble
	_add_model_2d(b_root, "props/Shelf_Small_Bottles.gltf", Vector2(346.0, -309.0), 2.0, Vector2(24.0, 5.0), 17.0)
	for bx in [-24.0, -8.0, 8.0, 24.0]:
		_add_model_2d(b_root, "props/Barrel.gltf", T.BARREL_RACK_POS + Vector2(bx, 0.0), 2.0, Vector2(10.0, 10.0), 11.0)
	# Fogones de cocina de la posada y mesa de preparación
	_register_furniture_rect("TavernStove", T.STOVE_POS, Vector2(26.0, 12.0))
	_add_box_2d(b_root, T.STOVE_POS, Vector2(26.0, 12.0), 2.0, 10.0, m_stove)
	_add_box_2d(b_root, T.STOVE_POS, Vector2(24.0, 10.5), 12.0, 0.4, m_soot)
	_add_cyl_2d(b_root, T.STOVE_POS + Vector2(-5.5, 0.0), 3.6, 12.4, 0.25, m_ember, 3.6, 8)
	_add_cyl_2d(b_root, T.STOVE_POS + Vector2(6.5, 0.0), 2.8, 12.4, 0.25, m_ember, 2.8, 8)
	_add_model_2d(b_root, "props/Cauldron.gltf", T.STOVE_POS + Vector2(-5.5, 0.0), 12.5, Vector2(8.0, 8.0), 6.0)
	_add_model_2d(b_root, "props/Pot_1.gltf", T.STOVE_POS + Vector2(6.5, 0.0), 12.5, Vector2(6.0, 6.0), 4.5)
	_add_model_2d(b_root, "props/Workbench.gltf", T.PREP_POS, 2.0, Vector2(24.0, 9.5), 9.5)
	_restaurant_light(b_root, Vector2(368.0, -268.0), 16.5, Color(1.0, 0.86, 0.60), 1.0, 2.5, false)

	# 5. Sala de Casino y Billar: Mesa de Póker con 4 sillas y fichas + Mesa de Billar Real en 3D
	var gp: Vector2 = T.GAMES_POS
	_register_furniture_rect("PokerTable", gp, Vector2(23.0, 23.0))
	_add_cyl_2d(b_root, gp, 3.2, 2.0, 6.4, m_dark_wood, 5.2, 10) # Pedestal central torneado de la mesa de póker
	_add_cyl_2d(b_root, gp, 11.5, 8.2, 1.4, m_dark_wood, 11.5, 12) # Aro de caoba
	_add_cyl_2d(b_root, gp, 9.8, 9.3, 0.5, m_felt, 9.8, 12) # Paño verde de póker
	# 4 sillas de póker (Oeste, Este, Norte, Sur) sincronizadas con T.POKER_CHAIRS, orientadas hacia la mesa
	for p_ch in T.POKER_CHAIRS:
		_add_model_2d(b_root, "props/Chair_1.gltf", p_ch, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(p_ch, gp))
	# Montón de fichas de póker en el bote central y cartas frente a cada jugador
	_add_cyl_2d(b_root, gp + Vector2(-1.4, -0.8), 1.3, 9.8, 1.4, m_gold, 1.3, 8)
	_add_cyl_2d(b_root, gp + Vector2(1.5, 0.6), 1.3, 9.8, 1.1, m_chip_red, 1.3, 8)
	_add_cyl_2d(b_root, gp + Vector2(0.2, -1.6), 1.2, 9.8, 0.9, m_chip_blue, 1.2, 8)
	for c_off in [Vector2(-6.8, 0.0), Vector2(6.8, 0.0), Vector2(0.0, -6.8), Vector2(0.0, 6.8)]:
		_add_box_2d(b_root, gp + c_off, Vector2(2.6, 1.8), 9.8, 0.25, m_plate)

	# Mesa de Billar Real en 3D (sin usar Table_Large ni patas de cama)
	_build_billiard_table_3d(b_root, T.POOL_POS, m_dark_wood, m_wood, m_gold)
	_restaurant_light(b_root, Vector2(546.0, -178.0), 25.0, Color(1.0, 0.84, 0.50), 1.1, 2.8, false)

	# 6. Vestíbulo de Escalera y Bodega: Escalera física real de 16 peldaños (h = 2.0 -> 34.0) y rincón de la Trampilla del Club
	var num_steps: int = 16
	var stair_x: float = T.STAIRS_BOTTOM_POS.x
	var y_bot: float = T.STAIRS_BOTTOM_POS.y
	var y_top: float = T.STAIRS_TOP_POS.y
	var step_dy: float = (y_top - y_bot) / float(num_steps)
	var step_dh: float = (T.FLOOR_1_H - 2.0) / float(num_steps)
	for si in range(num_steps):
		var sy: float = y_bot + (float(si) + 0.5) * step_dy
		var sh: float = 2.0 + float(si) * step_dh
		# Zanca/contorno de soporte bajo el peldaño y huella de roble macizo
		_add_box_2d(b_root, Vector2(stair_x, sy), Vector2(24.0, absf(step_dy) + 0.8), 2.0, sh - 1.5, m_dark_wood)
		_add_box_2d(b_root, Vector2(stair_x, sy), Vector2(26.0, absf(step_dy) + 1.2), sh, step_dh + 0.5, m_wood)
		if si in [0, 5, 10, 15]:
			var is_end_post: bool = (si == 0 or si == 15)
			var post_w: float = 2.0 if is_end_post else 1.3
			var post_h: float = 7.4 if is_end_post else 6.8
			for rail_side in [-12.5, 12.5]:
				_add_box_2d(b_root, Vector2(stair_x + rail_side, sy), Vector2(post_w, post_w), sh + step_dh, post_h, m_dark_wood)
	# Pasamanos continuo inclinado a cada lado de la escalera (de peldaño 0 a peldaño 15)
	for rail_side in [-12.5, 12.5]:
		var p0_3d: Vector3 = to_3d(Vector2(stair_x + rail_side, y_bot + 0.5 * step_dy), 2.0 + step_dh + 7.0)
		var p1_3d: Vector3 = to_3d(Vector2(stair_x + rail_side, y_top - 0.5 * step_dy), T.FLOOR_1_H + 7.0)
		var rail_mi := MeshInstance3D.new()
		var rail_bm := BoxMesh.new()
		rail_bm.size = Vector3(1.9 * WORLD_SCALE, (1.2 * WORLD_SCALE) / _cos_p, p0_3d.distance_to(p1_3d) + 0.04)
		rail_mi.mesh = rail_bm
		rail_mi.material_override = m_trim
		rail_mi.position = (p0_3d + p1_3d) * 0.5
		rail_mi.rotation.x = -atan2(p1_3d.y - p0_3d.y, p1_3d.z - p0_3d.z)
		b_root.add_child(rail_mi)
	# Toneles y cajas de bodega flanqueando la trampilla del Club de la Lucha (516, -286)
	_add_model_2d(b_root, "props/Barrel.gltf", Vector2(498.0, -302.0), 2.0, Vector2(9.5, 9.5), 10.5)
	_add_model_2d(b_root, "props/Barrel.gltf", Vector2(534.0, -302.0), 2.0, Vector2(9.5, 9.5), 10.5)
	_add_model_2d(b_root, "props/Crate_Wooden.gltf", Vector2(498.0, -268.0), 2.0, Vector2(9.0, 9.0), 8.0)
	_restaurant_light(b_root, Vector2(526.0, -276.0), 25.0, Color(1.0, 0.64, 0.32), 0.9, 2.4, false)

## Construye una mesa de billar 3D auténtica: 4 patas torneadas de caoba con casquillos de latón, faldón perimetral,
## pizarra de paño verde esmeralda, 4 bandas de caoba con herrajes dorados, 6 troneras oscuras, triángulo de bolas de colores + blanca y 2 tacos.
func _build_billiard_table_3d(parent: Node3D, pos: Vector2, m_mahogany: Material, m_cue_wood: Material, m_brass: Material) -> void:
	_register_furniture_rect("BilliardTable", pos, Vector2(26.4, 16.8))
	var m_baize := _mat("billiard_baize_emerald", Color(0.08, 0.56, 0.30), 0.78, 0.02)
	var m_pocket := _mat("billiard_pocket_dark", Color(0.07, 0.06, 0.06), 0.92, 0.1)
	var m_cue_ball := _mat("billiard_ball_white", Color(0.97, 0.96, 0.92), 0.18, 0.08)
	var m_ball_yellow := _mat("billiard_ball_yellow", Color(0.95, 0.80, 0.14), 0.20, 0.08)
	var m_ball_blue := _mat("billiard_ball_blue", Color(0.14, 0.36, 0.86), 0.20, 0.08)
	var m_ball_red := _mat("billiard_ball_red", Color(0.86, 0.16, 0.16), 0.20, 0.08)
	var m_ball_eight := _mat("billiard_ball_eight", Color(0.08, 0.08, 0.10), 0.16, 0.12)
	var m_chalk := _mat("billiard_chalk_tip", Color(0.22, 0.58, 0.92), 0.70, 0.0)

	# 1. 4 patas torneadas de caoba con casquillo inferior de latón
	for lx in [-11.2, 11.2]:
		for ly in [-6.6, 6.6]:
			var lp: Vector2 = pos + Vector2(lx, ly)
			_add_cyl_2d(parent, lp, 1.35, 2.0, 1.2, m_brass, 1.15, 10)
			_add_cyl_2d(parent, lp, 1.85, 3.2, 3.8, m_mahogany, 1.30, 10)

	# 2. Faldón / bastidor de caoba maciza y lecho de pizarra con paño verde esmeralda
	_add_box_2d(parent, pos, Vector2(26.4, 16.8), 6.6, 2.1, m_mahogany)
	_add_box_2d(parent, pos, Vector2(23.8, 14.2), 8.7, 0.65, m_baize)
	# Línea de saque blanca sobre el paño
	_add_box_2d(parent, pos + Vector2(-5.8, 0.0), Vector2(0.35, 13.2), 9.36, 0.08, m_cue_ball)

	# 3. Bandas elevadas de caoba (divididas en los lados largos para dejar las 6 troneras) y cantoneras de latón
	for sy in [-7.6, 7.6]:
		_add_box_2d(parent, pos + Vector2(-5.6, sy), Vector2(9.2, 1.5), 8.9, 1.1, m_mahogany)
		_add_box_2d(parent, pos + Vector2(5.6, sy), Vector2(9.2, 1.5), 8.9, 1.1, m_mahogany)
	for sx in [-12.4, 12.4]:
		_add_box_2d(parent, pos + Vector2(sx, 0.0), Vector2(1.5, 11.6), 8.9, 1.1, m_mahogany)

	# 4. 6 Troneras (4 esquinas + 2 centrales) con embocadura de latón y hueco oscuro
	var pockets: Array[Vector2] = [
		Vector2(-11.8, -7.1), Vector2(11.8, -7.1),
		Vector2(-11.8, 7.1), Vector2(11.8, 7.1),
		Vector2(0.0, -7.4), Vector2(0.0, 7.4),
	]
	for pk in pockets:
		_add_cyl_2d(parent, pos + pk, 1.65, 8.85, 1.2, m_brass, 1.65, 10)
		_add_cyl_2d(parent, pos + pk * 0.94, 1.28, 8.95, 1.18, m_pocket, 1.28, 10)

	# 5. Bolas de billar sobre el paño: bola blanca en zona de saque + triángulo de bolas de colores en el punto de pie
	_add_cyl_2d(parent, pos + Vector2(-6.2, 0.6), 0.68, 9.35, 0.95, m_cue_ball, 0.62, 10)
	var rack_balls: Array = [
		[Vector2(3.6, 0.0), m_ball_yellow],
		[Vector2(5.0, -0.8), m_ball_blue],
		[Vector2(5.0, 0.8), m_ball_red],
		[Vector2(6.4, -1.5), m_ball_red],
		[Vector2(6.4, 0.0), m_ball_eight],
		[Vector2(6.4, 1.5), m_ball_yellow],
	]
	for rb in rack_balls:
		_add_cyl_2d(parent, pos + (rb[0] as Vector2), 0.68, 9.35, 0.95, rb[1] as Material, 0.62, 10)

	# 6. 2 Tacos de billar de madera con virola de tiza azul apoyados sobre las bandas
	_add_box_2d(parent, pos + Vector2(-2.0, -4.4), Vector2(15.5, 0.48), 10.05, 0.42, m_cue_wood, 14.0)
	_add_box_2d(parent, pos + Vector2(5.4, -2.5), Vector2(0.9, 0.48), 10.06, 0.44, m_chalk, 14.0)
	_add_box_2d(parent, pos + Vector2(-1.5, 4.8), Vector2(15.5, 0.48), 10.05, 0.42, m_cue_wood, -11.0)
	_add_box_2d(parent, pos + Vector2(5.9, 3.3), Vector2(0.9, 0.48), 10.06, 0.44, m_chalk, -11.0)

## Paso 3: Primer Piso (Planta +1, h = 34.0) de la Gran Taberna «El Jabalí Dorado»:
## galería con barandilla sobre el salón, pasillo superior y 5 cuartos de huéspedes con las 6 camas reales a escala adulta.
func _build_tavern_floor_1_3d(loft_root: Node3D, _wall_h: float, m_wall: Material, m_trim: Material, m_wood: Material, m_dark_wood: Material, _m_iron: Material, _m_gold: Material) -> void:
	var T = VillageTavern
	var h1: float = T.FLOOR_1_H # 34.0
	var ih1: float = 34.0
	var m_bed_red := _mat("tavern_bed_red", Color(0.82, 0.24, 0.22), 0.85, 0.0)
	var m_bed_gold := _mat("tavern_bed_gold", Color(0.84, 0.62, 0.22), 0.85, 0.0)
	var m_pillow := _mat("tavern_bed_pillow", Color(0.95, 0.93, 0.88), 0.85, 0.0)
	var m_rug := _mat("tavern_upper_rug", Color(0.52, 0.18, 0.16), 0.92, 0.0)

	# 1. Forjado de madera de la Planta +1 (deja libre el hueco de la escalera en x = 558..604, y = -290..-206 y el balcón sur en y = -168..-132)
	_add_box_2d(loft_root, Vector2(411.0, -241.0), Vector2(294.0, 146.0), h1 - 1.6, 1.6, m_wood)
	# Relleno del desembarco superior de la escalera (x = 558..604, y = -206..-168)
	_add_box_2d(loft_root, Vector2(581.0, -187.0), Vector2(46.0, 38.0), h1 - 1.6, 1.6, m_wood)
	# Alfombra larga del pasillo de la galería alta
	_add_box_2d(loft_root, Vector2(422.0, T.HALLWAY_Y), Vector2(280.0, 18.0), h1 + 0.1, 0.35, m_rug)

	# 2. Barandilla de madera de la galería alta (asomada al Gran Salón en y = -168.0) y barandilla del hueco de escalera
	_add_box_2d(loft_root, Vector2(434.0, -168.0), Vector2(340.0, 2.6), h1 + 7.2, 1.5, m_dark_wood)
	for bx in range(272, 602, 28):
		_add_box_2d(loft_root, Vector2(float(bx), -168.0), Vector2(1.8, 2.2), h1, 7.2, m_trim)
	_add_box_2d(loft_root, Vector2(558.0, -248.0), Vector2(2.4, 84.0), h1 + 7.2, 1.5, m_dark_wood)
	for by in [-284.0, -246.0, -208.0]:
		_add_box_2d(loft_root, Vector2(558.0, by), Vector2(2.0, 2.0), h1, 7.2, m_trim)

	# 3. Tabique completo del pasillo de los 5 dormitorios (y = -216.0, x = 264..558) con sus 5 huecos de puerta enmarcados y muro superior continuo
	var d_hw: float = T.BEDROOM_DOOR_HALF_W
	var cur_x: float = 264.0
	for dx_v in T.BEDROOM_DOORS_X:
		var dx: float = float(dx_v)
		var a: float = dx - d_hw
		if a - cur_x > 1.0:
			_add_box_2d(loft_root, Vector2((cur_x + a) * 0.5, -216.0), Vector2(a - cur_x, 5.0), h1, ih1, m_wall)
		# Jambas verticales, dintel de madera y cerramiento de muro hasta el techo sobre cada puerta
		_add_box_2d(loft_root, Vector2(dx - d_hw, -216.0), Vector2(2.4, 5.6), h1, ih1, m_trim)
		_add_box_2d(loft_root, Vector2(dx + d_hw, -216.0), Vector2(2.4, 5.6), h1, ih1, m_trim)
		_add_box_2d(loft_root, Vector2(dx, -216.0), Vector2(d_hw * 2.0 + 2.4, 5.8), h1 + 22.2, 2.2, m_trim)
		_add_box_2d(loft_root, Vector2(dx, -216.0), Vector2(d_hw * 2.0, 5.0), h1 + 24.4, ih1 - 24.4, m_wall)
		cur_x = dx + d_hw
	if 558.0 - cur_x > 1.0:
		_add_box_2d(loft_root, Vector2((cur_x + 558.0) * 0.5, -216.0), Vector2(558.0 - cur_x, 5.0), h1, ih1, m_wall)

	# Tabiques divisorios completos entre los 5 cuartos de huéspedes (y = -314..-216), alineados con T.BEDROOM_PARTITIONS_X
	for part_x_v in T.BEDROOM_PARTITIONS_X:
		var part_x: float = float(part_x_v)
		_add_box_2d(loft_root, Vector2(part_x, -265.0), Vector2(4.8, 99.0), h1, ih1, m_wall)
		_add_box_2d(loft_root, Vector2(part_x, -216.0), Vector2(5.6, 5.6), h1, ih1, m_trim)

	# Iluminación cálida del pasillo y dormitorios de la Planta +1
	_restaurant_light(loft_root, Vector2(346.0, T.HALLWAY_Y), h1 + 25.0, Color(1.0, 0.82, 0.52), 1.0, 2.8, false)
	_restaurant_light(loft_root, Vector2(488.0, T.HALLWAY_Y), h1 + 25.0, Color(1.0, 0.82, 0.52), 1.0, 2.8, false)

	# 4. Las 6 camas reales en Planta +1 (con mesillas, cofres y alfombras a los pies)
	for bi in range(T.ALL_UPPER_BEDS.size()):
		var bp: Vector2 = T.ALL_UPPER_BEDS[bi]
		var blanket_mat: Material = m_bed_gold if bi == 0 else m_bed_red
		_build_bed_3d_at_h(loft_root, bp, h1, m_wood, blanket_mat, m_pillow)
		_add_model_2d(loft_root, "props/Nightstand_Shelf.gltf", bp + Vector2(0.0, -16.0), h1, Vector2(7.0, 6.0), 7.5)
		_add_box_2d(loft_root, bp + Vector2(0.0, 14.0), Vector2(16.0, 10.0), h1 + 0.1, 0.3, m_rug)
	_add_model_2d(loft_root, "props/Chest_Wood.gltf", Vector2(520.0, -288.0), h1, Vector2(12.0, 8.0), 6.8)

# ==============================================================================
# 3. SOLARES VACÍOS Y OBRAS EN CONSTRUCCIÓN (`VillageLots.LOTS`)
# ==============================================================================
func rebuild_lots_3d() -> void:
	_clear_children(lots_root_3d)
	if vm == null:
		return
	var m_stake := _mat("lot_stake", Color(0.52, 0.36, 0.22), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_scaffold := _mat("lot_scaffold", Color(0.64, 0.48, 0.30), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_found := _mat("lot_foundation", Color(0.56, 0.54, 0.50), 0.90, 0.02, Color.BLACK, 0.0, "town_textures/wall_stone.png", "", 0.70)

	for l_entry in VillageLots.LOTS:
		var l_dict: Dictionary = l_entry
		var id: String = str(l_dict["id"])
		var st: Dictionary = VillageLots.lot(vm, id)
		var status: String = str(st.get("status", "empty"))
		if status == "built":
			continue
		var c: Vector2 = VillageLots.lot_def(id)["center"]
		var sz_l: Vector2 = l_dict["size"]
		var h: Vector2 = sz_l * 0.5 - Vector2(6, 6)
		if status == "empty":
			for p in [Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)]:
				_add_box_2d(lots_root_3d, c + p, Vector2(3.5, 3.5), 0.0, 9.0, m_stake)
		elif status == "building":
			var prog: float = clampf(float(st.get("progress", 0.0)), 0.05, 1.0)
			_add_box_2d(lots_root_3d, c, Vector2(124, 92), 0.0, 2.5, m_found)
			var cur_h: float = 8.0 + 20.0 * prog
			for sx in [-56.0, 0.0, 56.0]:
				for sy in [-40.0, 40.0]:
					_add_box_2d(lots_root_3d, c + Vector2(sx, sy), Vector2(3.5, 3.5), 2.5, cur_h, m_scaffold)
			_add_box_2d(lots_root_3d, c + Vector2(0, -40.0), Vector2(118.0, 3.0), cur_h * 0.6, 2.5, m_scaffold)
			_add_box_2d(lots_root_3d, c + Vector2(0, 40.0), Vector2(118.0, 3.0), cur_h * 0.6, 2.5, m_scaffold)
			_add_model_2d(lots_root_3d, "props/Workbench.gltf", c + Vector2(-28.0, 0.0), 2.5, Vector2(24.0, 14.0), 8.0)

# ==============================================================================
# 4. PUERTAS PERSONALIZADAS POR FACHADA E INTERIORES DE EDIFICIOS DEL CASO I
# ==============================================================================
func _add_door_part(pivot: Node3D, cx_px: float, cy_px: float, cz_px: float, sx_px: float, sy_px: float, sz_px: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size_3d(Vector2(sx_px, sz_px), sy_px)
	mi.mesh = bm
	mi.material_override = mat
	mi.position = Vector3(cx_px * WORLD_SCALE, (cy_px * WORLD_SCALE) / _cos_p, (cz_px * WORLD_SCALE) / _sin_p)
	pivot.add_child(mi)
	return mi

func _build_door_leaf_3d(pivot: Node3D, b_id: String, leaf_w: float, leaf_h: float, m_wood: Material, m_dark_wood: Material, m_iron: Material, m_gold: Material) -> void:
	var hw: float = leaf_w * 0.5
	var hh: float = leaf_h * 0.5
	match b_id:
		"building_police":
			# Puerta blindada de la Comisaría: hierro y tablón oscuro remachado, tosco y gastado
			var m_pol_steel := _mat("door_police_steel", Color(0.22, 0.23, 0.25), 0.78, 0.58, Color.BLACK, 0.0, "town_textures/wall_stone.png", "town_textures/wall_stone_n.png")
			var m_pol_dark := _mat("door_police_frame", Color(0.14, 0.14, 0.16), 0.82, 0.68, Color.BLACK, 0.0, "town_textures/rf_planks.png")
			var m_pol_win := _mat("door_police_win", Color(0.08, 0.09, 0.10), 0.85, 0.15)
			_add_door_part(pivot, hw, hh, 0.0, leaf_w, leaf_h, 2.8, m_pol_steel)
			_add_door_part(pivot, 1.4, hh, 0.0, 2.8, leaf_h, 3.3, m_pol_dark)
			_add_door_part(pivot, leaf_w - 1.4, hh, 0.0, 2.8, leaf_h, 3.3, m_pol_dark)
			for ry in [2.2, leaf_h * 0.45, leaf_h - 2.0]:
				_add_door_part(pivot, hw, ry, 0.0, leaf_w, 2.2, 3.4, m_pol_dark)
			var wy: float = leaf_h * 0.72
			_add_door_part(pivot, hw, wy, 0.0, leaf_w * 0.42, leaf_h * 0.18, 3.1, m_pol_win)
			for bx in [-4.2, -1.4, 1.4, 4.2]:
				_add_door_part(pivot, hw + bx, wy, 0.0, 0.9, leaf_h * 0.20, 3.5, m_iron)
			_add_door_part(pivot, leaf_w - 5.2, leaf_h * 0.45, 0.0, 1.8, 3.6, 4.0, m_iron)
		"building_hospital":
			# Portón del Hospital: madera oscura gastada y sucia con herrajes de hierro oxidado y una pequeña cruz pintada desvaída
			var m_hosp_wood := _mat("door_hosp_worn_wood", Color(0.23, 0.17, 0.13), 0.92, 0.03, Color.BLACK, 0.0, "town_textures/rf_planks.png", "town_textures/rf_planks_n.png")
			var m_hosp_stile := _mat("door_hosp_dark_stile", Color(0.17, 0.13, 0.10), 0.94, 0.04, Color.BLACK, 0.0, "town_textures/rf_planks.png", "town_textures/rf_planks_n.png")
			var m_hosp_iron := _mat("door_hosp_worn_iron", Color(0.18, 0.16, 0.15), 0.80, 0.58, Color.BLACK, 0.0, "town_textures/wall_stone.png")
			var m_hosp_vent := _mat("door_hosp_dark_vent", Color(0.10, 0.10, 0.09), 0.90, 0.10)
			var m_hosp_cross := _mat("door_hosp_faded_cross", Color(0.42, 0.23, 0.19), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/rf_planks.png")
			_add_door_part(pivot, hw, hh, 0.0, leaf_w, leaf_h, 2.7, m_hosp_wood)
			# Montantes verticales de madera oscura y flejes horizontales de hierro gastado
			_add_door_part(pivot, 1.4, hh, 0.0, 2.8, leaf_h, 3.1, m_hosp_stile)
			_add_door_part(pivot, hw, hh, 0.0, 2.2, leaf_h, 3.1, m_hosp_stile)
			_add_door_part(pivot, leaf_w - 1.4, hh, 0.0, 2.8, leaf_h, 3.1, m_hosp_stile)
			for ry in [2.2, leaf_h * 0.46, leaf_h - 1.8]:
				_add_door_part(pivot, hw, ry, 0.0, leaf_w, 2.0, 3.3, m_hosp_iron)
			# Pequeño ventanuco enrejado oscuro y una única cruz pintada pequeña y desvaída
			var h_wy: float = leaf_h * 0.73
			_add_door_part(pivot, hw, h_wy, 0.0, leaf_w * 0.28, leaf_h * 0.14, 3.0, m_hosp_vent)
			for h_bx in [-2.6, 0.0, 2.6]:
				_add_door_part(pivot, hw + h_bx, h_wy, 0.0, 0.7, leaf_h * 0.15, 3.4, m_hosp_iron)
			_add_door_part(pivot, hw, leaf_h * 0.58, 0.0, 3.2, 0.95, 3.15, m_hosp_cross)
			_add_door_part(pivot, hw, leaf_h * 0.58, 0.0, 0.95, 3.2, 3.15, m_hosp_cross)
			_add_door_part(pivot, leaf_w - 5.0, leaf_h * 0.46, 0.0, 1.8, 3.6, 3.7, m_hosp_iron)
		"building_tavern":
			# Portón de roble de la Gran Taberna «El Jabalí Dorado»: madera de roble oscuro con herrajes, ventanuco ámbar y zócalo de hierro
			var door_leaf := _make_texture_panel(leaf_w, leaf_h, 2.8, _panel_mat("door_tavern", "town_textures/door_wood_window_lit.png", false))
			door_leaf.position = Vector3(hw * WORLD_SCALE, (hh * WORLD_SCALE) / _cos_p, 0.0)
			pivot.add_child(door_leaf)
			_add_door_part(pivot, 1.4, hh, 0.0, 2.6, leaf_h, 3.2, m_dark_wood)
			_add_door_part(pivot, leaf_w - 1.4, hh, 0.0, 2.6, leaf_h, 3.2, m_dark_wood)
			_add_door_part(pivot, hw, 1.8, 0.0, leaf_w - 1.0, 2.8, 3.3, m_iron)
			_add_door_part(pivot, hw, leaf_h * 0.44, 0.0, leaf_w - 1.0, 2.0, 3.3, m_iron)
			_add_door_part(pivot, hw, leaf_h - 1.5, 0.0, leaf_w - 1.0, 2.2, 3.3, m_iron)
			_add_door_part(pivot, leaf_w - 5.0, leaf_h * 0.44, 0.0, 2.0, 4.0, 3.8, m_iron)
		"building_library":
			# Puerta de nogal oscuro y hierro forjado de la Biblioteca
			var m_lib_wood := _mat("door_lib_walnut", Color(0.25, 0.17, 0.12), 0.88, 0.03, Color.BLACK, 0.0, "town_textures/rf_planks.png", "town_textures/rf_planks_n.png")
			var m_lib_stile := _mat("door_lib_stile", Color(0.18, 0.13, 0.09), 0.92, 0.04, Color.BLACK, 0.0, "town_textures/rf_planks.png", "town_textures/rf_planks_n.png")
			_add_door_part(pivot, hw, hh, 0.0, leaf_w, leaf_h, 2.7, m_lib_wood)
			_add_door_part(pivot, 1.4, hh, 0.0, 2.8, leaf_h, 3.2, m_lib_stile)
			_add_door_part(pivot, hw, hh, 0.0, 2.2, leaf_h, 3.2, m_lib_stile)
			_add_door_part(pivot, leaf_w - 1.4, hh, 0.0, 2.8, leaf_h, 3.2, m_lib_stile)
			for ry in [2.0, leaf_h * 0.46, leaf_h - 1.6]:
				_add_door_part(pivot, hw, ry, 0.0, leaf_w, 2.2, 3.3, m_iron)
			_add_door_part(pivot, leaf_w - 5.0, leaf_h * 0.46, 0.0, 1.8, 3.6, 3.7, m_iron)
		"mixed_family_herbalist":
			# Puerta de la Botica «Raíz Verde»: madera gastada y oscura con herrajes toscos de hierro y postigo oscuro
			var m_herb_wood := _mat("door_herb_worn_wood", Color(0.22, 0.18, 0.13), 0.92, 0.03, Color.BLACK, 0.0, "town_textures/rf_planks.png", "town_textures/rf_planks_n.png")
			var m_herb_trim := _mat("door_herb_dark_trim", Color(0.16, 0.13, 0.09), 0.94, 0.03, Color.BLACK, 0.0, "town_textures/rf_planks.png", "town_textures/rf_planks_n.png")
			var m_herb_iron := _mat("door_herb_worn_iron", Color(0.19, 0.17, 0.15), 0.82, 0.56, Color.BLACK, 0.0, "town_textures/wall_stone.png")
			var m_herb_shutter := _mat("door_herb_shutter", Color(0.13, 0.11, 0.09), 0.92, 0.05, Color.BLACK, 0.0, "town_textures/rf_planks.png")
			_add_door_part(pivot, hw, hh, 0.0, leaf_w, leaf_h, 2.6, m_herb_wood)
			_add_door_part(pivot, 1.4, hh, 0.0, 2.8, leaf_h, 3.1, m_herb_trim)
			_add_door_part(pivot, leaf_w - 1.4, hh, 0.0, 2.8, leaf_h, 3.1, m_herb_trim)
			for ry in [2.0, leaf_h * 0.46, leaf_h - 1.6]:
				_add_door_part(pivot, hw, ry, 0.0, leaf_w, 2.0, 3.2, m_herb_iron)
			_add_door_part(pivot, hw, leaf_h * 0.70, 0.0, leaf_w * 0.30, leaf_h * 0.15, 3.0, m_herb_shutter)
			for bx in [-2.2, 2.2]:
				_add_door_part(pivot, hw + bx, leaf_h * 0.70, 0.0, 0.7, leaf_h * 0.16, 3.3, m_herb_iron)
			_add_door_part(pivot, leaf_w - 5.0, leaf_h * 0.46, 0.0, 1.8, 3.6, 3.6, m_herb_iron)
		"building_church":
			# Portón de nogal oscuro de la Capilla del Alba con herrajes de forja y cruz sobria de bronce viejo
			var m_ch_oak := _mat("door_church_oak", Color(0.22, 0.15, 0.10), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/rf_planks.png", "town_textures/rf_planks_n.png")
			var m_ch_bronze := _mat("door_church_old_bronze", Color(0.32, 0.25, 0.16), 0.78, 0.35, Color.BLACK, 0.0, "town_textures/rf_planks.png")
			_add_door_part(pivot, hw, hh, 0.0, leaf_w, leaf_h, 2.9, m_ch_oak)
			_add_door_part(pivot, 1.5, hh, 0.0, 3.0, leaf_h, 3.4, m_iron)
			_add_door_part(pivot, hw, hh, 0.0, 2.4, leaf_h, 3.4, m_iron)
			_add_door_part(pivot, leaf_w - 1.5, hh, 0.0, 3.0, leaf_h, 3.4, m_iron)
			for ry in [2.4, leaf_h * 0.48, leaf_h - 2.0]:
				_add_door_part(pivot, hw, ry, 0.0, leaf_w, 2.0, 3.4, m_iron)
			_add_door_part(pivot, hw, leaf_h * 0.62, 0.0, 1.6, leaf_h * 0.32, 3.5, m_ch_bronze)
			_add_door_part(pivot, hw, leaf_h * 0.66, 0.0, leaf_w * 0.26, 1.6, 3.5, m_ch_bronze)
		"building_abandoned_mill":
			var m_mill_door := _mat("door_abandoned_mill", Color(0.24, 0.17, 0.12), 0.94, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "town_textures/rf_planks_n.png")
			var m_rust_iron := _mat("door_rust_iron", Color(0.22, 0.16, 0.13), 0.82, 0.55)
			_add_door_part(pivot, hw, hh, 0.0, leaf_w, leaf_h, 2.8, m_mill_door)
			for ry in [2.6, leaf_h * 0.48, leaf_h - 2.4]:
				_add_door_part(pivot, hw, ry, 0.0, leaf_w, 2.0, 3.3, m_rust_iron)
			_add_door_part(pivot, 1.5, hh, 0.0, 2.6, leaf_h, 3.3, m_rust_iron)
			_add_door_part(pivot, leaf_w - 1.5, hh, 0.0, 2.6, leaf_h, 3.3, m_rust_iron)
		_:
			var door_leaf := _make_texture_panel(leaf_w, leaf_h, 3.0, _panel_mat("door_wood", "town_textures/door_wood.png", false))
			door_leaf.position = Vector3(hw * WORLD_SCALE, (hh * WORLD_SCALE) / _cos_p, 0.0)
			pivot.add_child(door_leaf)

## Punto 1 del Caso I: Comisaría de Policía y Calabozo Municipal (`building_police`, rect x=844..986, y=100..196).
## Tres estancias diferenciadas y sincronizadas con los muros 2D:
##  1) Guardia y Despacho del Alguacil (Norte, y=100..152): mesa de interrogatorios, tablón de anuncios, archivadores y despacho con terminal CRT.
##  2) El Calabozo (Suroeste, x=844..915, y=152..196): reja de hierro oscuro, puerta de barrotes con cerradura y llave, catre, cubo y grilletes.
##  3) Cuarto de Guardia y Archivo de Pruebas (Sureste, x=915..986, y=152..196): tabique con puerta, camastro de guardia, armero y cajas de pruebas.
func _build_police_station_3d(b_root: Node3D, _rect: Rect2, wall_h: float, m_wall: Material, m_trim: Material, m_wood: Material, m_dark_wood: Material, m_iron: Material, m_gold: Material) -> void:
	var ih: float = wall_h - 0.15
	var m_dark_iron := _mat("jail_dark_wrought_iron", Color(0.14, 0.16, 0.19), 0.42, 0.84)
	var m_cell_stone := _mat("jail_cell_floor_stone", Color(0.36, 0.39, 0.43), 0.92, 0.04, Color.BLACK, 0.0, "town_textures/floor_stone_grate.png")
	var m_guard_rug := _mat("police_office_rug", Color(0.18, 0.26, 0.38), 0.90, 0.0)
	var m_straw_mat := _mat("jail_cot_straw", Color(0.56, 0.49, 0.36), 0.94, 0.0)
	var m_cell_blanket := _mat("jail_cot_blanket", Color(0.34, 0.37, 0.42), 0.90, 0.0)
	var m_guard_blanket := _mat("police_guard_blanket", Color(0.20, 0.32, 0.48), 0.86, 0.0)
	var m_pillow := _mat("police_pillow", Color(0.86, 0.84, 0.78), 0.88, 0.0)
	var m_paper := _mat("police_dossier_paper", Color(0.92, 0.89, 0.80), 0.85, 0.0)
	var m_cork := _mat("police_board_cork", Color(0.58, 0.42, 0.24), 0.90, 0.0)

	# 1. Pavimentos diferenciados por estancia (sin solapar alturas)
	_add_box_2d(b_root, Vector2(880.0, 174.0), Vector2(64.0, 38.0), 2.5, 0.32, m_cell_stone)
	_add_box_2d(b_root, Vector2(960.0, 128.0), Vector2(36.0, 26.0), 2.5, 0.28, m_guard_rug)

	# 2. Tabiques interiores y cerramientos sincronizados al milímetro con las colisiones 2D:
	# 2a. Reja frontal de hierro forjado oscuro del Calabozo: x = 847..889, y = 152 (colisión 2D: center 868,152 size 42x6)
	_add_box_2d(b_root, Vector2(868.0, 152.0), Vector2(42.0, 5.2), 2.0, 3.2, m_trim) # Zócalo inferior de piedra/madera
	_add_box_2d(b_root, Vector2(868.0, 152.0), Vector2(42.0, 5.2), 2.0 + ih * 0.82, ih * 0.18, m_wall) # Dintel superior
	for rail_h in [5.2, 14.8, 2.0 + ih * 0.80]:
		_add_box_2d(b_root, Vector2(868.0, 152.0), Vector2(42.0, 3.0), rail_h, 1.4, m_dark_iron)
	for bx in [852.0, 857.5, 863.0, 868.5, 874.0, 879.5, 885.0]:
		_add_cyl_2d(b_root, Vector2(bx, 152.0), 0.56, 5.0, ih * 0.80 - 2.5, m_dark_iron, 0.56, 8)
	# Pilar maestro de hierro y piedra entre la reja fija y la puerta de la celda (x = 889, y = 152) y en x = 915, y = 152
	_add_box_2d(b_root, Vector2(889.0, 152.0), Vector2(3.6, 5.8), 2.0, ih, m_dark_iron)
	_add_box_2d(b_root, Vector2(915.0, 152.0), Vector2(4.2, 5.8), 2.0, ih, m_dark_iron)
	_add_box_2d(b_root, Vector2(902.0, 152.0), Vector2(26.0, 5.2), 2.0 + ih * 0.80, ih * 0.20, m_dark_iron) # Dintel sobre la puerta de reja

	# 2b. Puerta corredera de reja de hierro oscuro con cerradura y llave en Vector2(902, 152) (pivote en 889.5, 152; ancho 24.5)
	_jail_gate_pivot_3d = Node3D.new()
	_jail_gate_pivot_3d.name = "JailGatePivot3D"
	_jail_gate_pivot_3d.position = to_3d(Vector2(889.5, 152.0), 2.0)
	b_root.add_child(_jail_gate_pivot_3d)
	var gate_h: float = ih * 0.78
	var gate_w: float = 24.5
	# Bastidor de la puerta de barrotes (travesaños inferior, medio y superior + montantes laterales + 4 barrotes verticales)
	_add_door_part(_jail_gate_pivot_3d, gate_w * 0.5, 1.2, 0.0, gate_w, 1.5, 2.2, m_dark_iron)
	_add_door_part(_jail_gate_pivot_3d, gate_w * 0.5, gate_h * 0.48, 0.0, gate_w, 1.4, 2.2, m_dark_iron)
	_add_door_part(_jail_gate_pivot_3d, gate_w * 0.5, gate_h - 1.0, 0.0, gate_w, 1.6, 2.2, m_dark_iron)
	_add_door_part(_jail_gate_pivot_3d, 1.0, gate_h * 0.5, 0.0, 1.5, gate_h, 2.2, m_dark_iron)
	_add_door_part(_jail_gate_pivot_3d, gate_w - 1.0, gate_h * 0.5, 0.0, 1.6, gate_h, 2.2, m_dark_iron)
	for gbx in [5.5, 10.5, 15.5, 20.5]:
		_add_door_part(_jail_gate_pivot_3d, gbx, gate_h * 0.5, 0.0, 1.0, gate_h - 1.2, 1.6, m_dark_iron)
	# Caja de cerradura pesada con escudo de latón y llave puesta en la puerta de la celda
	_add_door_part(_jail_gate_pivot_3d, gate_w - 2.6, gate_h * 0.48, 0.0, 3.6, 4.8, 3.2, m_dark_iron)
	_add_door_part(_jail_gate_pivot_3d, gate_w - 2.4, gate_h * 0.48, 0.0, 2.2, 3.2, 3.6, m_gold)
	_add_door_part(_jail_gate_pivot_3d, gate_w - 2.4, gate_h * 0.48, -2.1, 0.9, 1.4, 2.4, m_gold) # Llave asomando en la cerradura
	# Manojo de llaves del calabozo colgado en el pilar junto a la celda (Vector2(887.5, 148.8))
	_add_box_2d(b_root, Vector2(887.5, 148.8), Vector2(1.2, 1.4), 15.5, 1.2, m_dark_iron)
	_add_cyl_2d(b_root, Vector2(887.5, 148.4), 1.4, 14.0, 0.6, m_gold, 1.4, 8)
	_add_box_2d(b_root, Vector2(887.1, 148.3), Vector2(0.5, 0.5), 11.8, 2.4, m_gold)
	_add_box_2d(b_root, Vector2(887.9, 148.3), Vector2(0.5, 0.5), 12.1, 2.1, m_iron)

	# 2c. Muro divisorio este del Calabozo: x = 915, y = 153..195 (colisión 2D: center 915,174 size 6x42)
	_add_box_2d(b_root, Vector2(915.0, 174.0), Vector2(5.2, 42.0), 2.0, 11.5, m_wall)
	_add_box_2d(b_root, Vector2(915.0, 174.0), Vector2(5.4, 42.0), 13.5, 1.5, m_dark_iron)
	_add_box_2d(b_root, Vector2(915.0, 174.0), Vector2(5.2, 42.0), 2.0 + ih * 0.80, ih * 0.20, m_wall)
	for by_c in range(157, 193, 5):
		_add_cyl_2d(b_root, Vector2(915.0, float(by_c)), 0.56, 14.5, ih * 0.80 - 12.0, m_dark_iron, 0.56, 8)

	# 2d. Tabique del Cuarto de Guardia / Archivo (Sureste): x = 941..983, y = 152 (hueco de paso libre en x = 917..941)
	_add_box_2d(b_root, Vector2(962.0, 152.0), Vector2(42.0, 5.2), 2.0, ih, m_wall)
	_add_box_2d(b_root, Vector2(941.0, 152.0), Vector2(3.0, 5.8), 2.0, ih, m_trim) # Jamba derecha del paso SE
	_add_box_2d(b_root, Vector2(928.0, 152.0), Vector2(26.0, 5.6), 2.0 + ih * 0.78, ih * 0.22, m_trim) # Dintel sobre el paso SE

	# 3. Interior del Calabozo (Suroeste, x = 848..912, y = 155..192; _jail_cell_pos = (886, 172) libre para el preso)
	# Catre de hierro oscuro con jergón de paja y manta gris junto al muro sur de la celda (Vector2(870, 182))
	var cot_p := Vector2(870.0, 182.0)
	_register_furniture_rect("JailCellCot", cot_p, Vector2(19.0, 11.5))
	_add_box_2d(b_root, cot_p, Vector2(19.0, 11.5), 2.0, 3.2, m_dark_iron)
	_add_box_2d(b_root, cot_p + Vector2(-9.0, 0.0), Vector2(1.4, 11.5), 2.0, 6.8, m_dark_iron)
	_add_box_2d(b_root, cot_p + Vector2(9.0, 0.0), Vector2(1.4, 11.5), 2.0, 5.2, m_dark_iron)
	_add_box_2d(b_root, cot_p, Vector2(17.2, 10.4), 5.2, 1.4, m_straw_mat)
	_add_box_2d(b_root, cot_p + Vector2(2.2, 0.0), Vector2(11.5, 10.2), 6.6, 0.8, m_cell_blanket)
	_add_box_2d(b_root, cot_p + Vector2(-6.0, 0.0), Vector2(3.8, 8.2), 6.6, 1.2, m_pillow)
	# Cubo de celda, banqueta baja con jarro de latón y grilletes de hierro en el muro del fondo
	_add_model_2d(b_root, "props/Bucket_Wooden_1.gltf", Vector2(896.0, 183.0), 2.0, Vector2(5.5, 5.5), 5.5)
	_add_model_2d(b_root, "props/Stool.gltf", Vector2(855.0, 165.0), 2.0, Vector2(5.5, 5.5), 5.2)
	_add_model_2d(b_root, "props/Mug.gltf", Vector2(855.0, 165.0), 7.2, Vector2(2.8, 2.8), 3.2)
	# Placa de anclaje y cadenas de grilletes en el muro sur de la celda (Vector2(878, 192))
	_add_box_2d(b_root, Vector2(878.0, 192.2), Vector2(10.0, 1.4), 13.5, 3.2, m_dark_iron)
	for sh_x in [-3.2, 3.2]:
		_add_box_2d(b_root, Vector2(878.0 + sh_x, 191.6), Vector2(0.9, 1.2), 9.0, 5.0, m_dark_iron)
		_add_cyl_2d(b_root, Vector2(878.0 + sh_x, 191.4), 1.5, 7.8, 1.2, m_dark_iron, 1.5, 8)

	# 4. Sala Principal / Guardia e Interrogatorios (Oeste, x = 848..892, y = 104..144)
	var int_tbl := Vector2(870.0, 126.0)
	if _add_model_2d(b_root, "props/Table_Large.gltf", int_tbl, 2.0, Vector2(18.0, 11.0), 7.4) == null:
		_add_box_2d(b_root, int_tbl, Vector2(18.0, 11.0), 2.0, 7.4, m_dark_wood)
	for ch_p in [int_tbl + Vector2(-13.5, 0.0), int_tbl + Vector2(13.5, 0.0)]:
		_add_model_2d(b_root, "props/Chair_1.gltf", ch_p, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(ch_p, int_tbl))
	_add_model_2d(b_root, "props/Book_5.gltf", int_tbl + Vector2(-3.0, -1.5), 9.4, Vector2(4.5, 3.5), 2.0)
	_add_model_2d(b_root, "props/Book_Stack_1.gltf", int_tbl + Vector2(4.0, 1.5), 9.4, Vector2(4.5, 4.5), 3.5)
	_add_model_2d(b_root, "props/CandleStick.gltf", int_tbl + Vector2(0.0, -2.5), 9.4, Vector2(3.0, 3.0), 4.8)
	# Archivador y estantería de expedientes junto al muro noroeste
	_add_model_2d(b_root, "props/Cabinet.gltf", Vector2(856.0, 107.0), 2.0, Vector2(14.0, 8.0), 13.5)
	_add_model_2d(b_root, "props/Shelf_Simple.gltf", Vector2(876.0, 106.5), 2.0, Vector2(16.0, 6.0), 16.5)
	# Tablón policial de «SE BUSCA» y pistas en el muro oeste (Vector2(848, 126))
	_add_box_2d(b_root, Vector2(847.8, 126.0), Vector2(1.4, 22.0), 11.5, 11.0, m_dark_wood)
	_add_box_2d(b_root, Vector2(848.4, 126.0), Vector2(1.0, 19.5), 12.3, 9.4, m_cork)
	for py_off in [-5.5, 0.0, 5.5]:
		_add_box_2d(b_root, Vector2(848.8, 126.0 + py_off), Vector2(0.6, 4.2), 14.2, 5.4, m_paper)

	# 5. Despacho del Comisario Vane y Terminal Policial (Este, x = 944..982, y = 104..144)
	var sh_desk := VillageCulture.POLICE_TERMINAL_POS # Vector2(960, 128)
	if _add_model_2d(b_root, "props/Table_Large.gltf", sh_desk, 2.0, Vector2(20.0, 11.5), 7.8) == null:
		_add_box_2d(b_root, sh_desk, Vector2(20.0, 11.5), 2.0, 7.8, m_dark_wood)
	var sh_chair := sh_desk + Vector2(0.0, -11.5)
	_add_model_2d(b_root, "props/Chair_1.gltf", sh_chair, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(sh_chair, sh_desk))
	_add_green_crt_terminal_3d(b_root, sh_desk + Vector2(-2.5, 0.0), 9.8, true)
	_add_model_2d(b_root, "props/Book_Stack_2.gltf", sh_desk + Vector2(5.8, 1.0), 9.8, Vector2(4.5, 4.5), 3.8)
	# Armero reglamentario adosado al muro noreste (lejos del paso central)
	_add_model_2d(b_root, "props/WeaponStand.gltf", Vector2(960.0, 106.5), 2.0, Vector2(14.0, 6.5), 11.5)

	# 6. Cuarto de Guardia y Archivo de Pruebas (Sureste, x = 918..982, y = 155..192)
	_build_bed_3d(b_root, Vector2(968.0, 178.0), m_dark_wood, m_guard_blanket, m_pillow)
	_add_model_2d(b_root, "props/Nightstand_Shelf.gltf", Vector2(952.0, 185.0), 2.0, Vector2(7.0, 6.0), 7.5, 180.0)
	_add_model_2d(b_root, "props/Bookcase_2.gltf", Vector2(936.0, 189.0), 2.0, Vector2(18.0, 7.0), 16.5, 180.0)
	_add_model_2d(b_root, "props/Crate_Wooden.gltf", Vector2(974.0, 160.0), 2.0, Vector2(8.5, 8.5), 7.5)
	# Punto 4 (Caso I): Mesa / Archivador de Pruebas con la «Denuncia de desaparición archivada» (`Vector2(934, 180)`)
	var rep_pos := Vector2(934.0, 180.0)
	var m_stamp_red := _mat("police_archived_stamp", Color(0.68, 0.14, 0.12), 0.85, 0.0)
	var m_folder_tan := _mat("police_archived_folder", Color(0.72, 0.58, 0.38), 0.90, 0.0)
	var m_ink_dark := _mat("police_archived_ink", Color(0.16, 0.14, 0.12), 0.90, 0.0)
	_register_furniture_rect("PoliceEvidenceDesk", rep_pos, Vector2(16.0, 9.5))
	_add_box_2d(b_root, rep_pos, Vector2(16.0, 9.5), 2.0, 6.8, m_dark_wood)
	_add_box_2d(b_root, rep_pos, Vector2(17.0, 10.2), 8.6, 0.7, m_wood)
	# Cajón de archivo entreabierto y carpeta con el papel de la denuncia archivada
	_add_box_2d(b_root, rep_pos + Vector2(-4.2, -3.5), Vector2(6.2, 4.5), 5.6, 2.2, m_dark_wood)
	_add_box_2d(b_root, rep_pos + Vector2(-4.2, -4.2), Vector2(5.4, 3.6), 6.4, 1.6, m_folder_tan)
	_add_box_2d(b_root, rep_pos + Vector2(1.2, -0.4), Vector2(9.2, 6.8), 9.32, 0.24, m_folder_tan, -8.0)
	_add_box_2d(b_root, rep_pos + Vector2(1.6, -0.2), Vector2(7.8, 5.8), 9.56, 0.22, m_paper, 5.0)
	for r_line in [-1.6, -0.5, 0.6, 1.7]:
		_add_box_2d(b_root, rep_pos + Vector2(1.5, r_line), Vector2(5.8, 0.36), 9.78, 0.08, m_ink_dark, 5.0)
	# Sello rojo diagonal de «ARCHIVADA» sobre la denuncia
	_add_box_2d(b_root, rep_pos + Vector2(2.6, 1.1), Vector2(3.6, 1.3), 9.80, 0.10, m_stamp_red, -18.0)

	# 7. Iluminación interior y faroles de fachada
	for lt_pos in [Vector2(882.0, 124.0), Vector2(952.0, 124.0)]:
		_add_model_2d(b_root, "props/Chandelier.gltf", lt_pos, ih - 6.5, Vector2(10.0, 10.0), 6.0)
		_restaurant_light(b_root, lt_pos, ih - 5.0, Color(0.95, 0.88, 0.72), 1.05, 2.5, false)
	_restaurant_light(b_root, Vector2(882.0, 172.0), ih - 4.5, Color(0.86, 0.72, 0.48), 0.72, 1.9, false) # Luz tenue del calabozo
	_restaurant_light(b_root, Vector2(954.0, 174.0), ih - 4.5, Color(0.96, 0.84, 0.62), 0.85, 2.1, false) # Luz del cuarto de guardia
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", Vector2(890.0, 97.5), wall_h * 0.58, Vector2(4.0, 4.0), 6.0)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", Vector2(940.0, 97.5), wall_h * 0.58, Vector2(4.0, 4.0), 6.0)

## Punto 2 del Caso I: Hospital de Urgencias y Morgue Forense (`building_hospital`, rect x=676..814, y=100..196).
## Dos estancias diferenciadas y sincronizadas con las colisiones 2D:
##  1) Sala Norte (y=100..152): Box de Urgencias con cama clínica, suero, biombo, lavamanos y botiquín (Oeste) + Consulta del Dr. Valen y cama de guardia (Este).
##  2) Sala Sur / Morgue Forense (y=152..196): pavimento frío de loseta azulada, 3 mesas de autopsia de acero inoxidable con drenaje, lámparas quirúrgicas, cámaras frigoríficas murales y carro de instrumental.
func _build_hospital_and_morgue_3d(b_root: Node3D, _rect: Rect2, wall_h: float, m_wall: Material, m_trim: Material, m_wood: Material, m_dark_wood: Material, m_iron: Material, m_gold: Material) -> void:
	var ih: float = wall_h - 0.15
	var m_steel := _mat("hosp_stainless_steel", Color(0.76, 0.82, 0.86), 0.26, 0.82)
	var m_dark_steel := _mat("hosp_dark_steel", Color(0.38, 0.44, 0.48), 0.36, 0.76)
	var m_white_enamel := _mat("hosp_white_enamel", Color(0.80, 0.82, 0.78), 0.65, 0.08, Color.BLACK, 0.0, "town_textures/wall_brick_small_sand.png")
	var m_teal_trim := _mat("hosp_teal_trim", Color(0.28, 0.34, 0.33), 0.78, 0.08, Color.BLACK, 0.0, "town_textures/rf_planks.png")
	var m_hosp_mat := _mat("hosp_entry_worn_mat", Color(0.28, 0.24, 0.20), 0.95, 0.0, Color.BLACK, 0.0, "town_textures/roof_thatch_center.png")
	var m_teal_sheet := _mat("hosp_teal_sheet", Color(0.32, 0.48, 0.46), 0.88, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png")
	var m_screen_cloth := _mat("hosp_screen_cloth", Color(0.62, 0.68, 0.64), 0.90, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_sand.png")
	var m_pillow := _mat("hosp_pillow_white", Color(0.88, 0.88, 0.84), 0.88, 0.0)
	var m_shroud := _mat("hosp_corpse_shroud", Color(0.78, 0.78, 0.72), 0.92, 0.0)
	var m_morgue_floor := _mat("morgue_floor_blue_tile", Color(0.54, 0.60, 0.64), 0.68, 0.06, Color.BLACK, 0.0, "town_textures/floor_tiles_blue_small_damaged.png")
	var m_glass_jar := _mat("hosp_glass_jar", Color(0.58, 0.88, 0.82), 0.20, 0.10, Color(0.18, 0.55, 0.48), 0.35)
	var m_lamp_glow := _mat("hosp_surgical_glow", Color(0.88, 0.98, 1.0), 0.15, 0.0, Color(0.78, 0.95, 1.0), 2.4)

	# 1. Pavimento diferenciado de la Morgue Forense (Sur, y = 153..193) y felpudo gastado de entrada
	_add_box_2d(b_root, Vector2(745.0, 173.5), Vector2(130.0, 39.0), 2.5, 0.30, m_morgue_floor)
	_add_box_2d(b_root, Vector2(745.0, 112.0), Vector2(24.0, 12.0), 2.5, 0.22, m_hosp_mat)

	# 2. Tabique divisorio entre Urgencias y Morgue en y = 152 (sincronizado al milímetro con colisión 2D: 699,152 [44x6] y 791,152 [44x6]; paso libre x = 721..769)
	_add_box_2d(b_root, Vector2(699.0, 152.0), Vector2(44.0, 5.4), 2.0, ih, m_wall)
	_add_box_2d(b_root, Vector2(791.0, 152.0), Vector2(44.0, 5.4), 2.0, ih, m_wall)
	# Zócalo sanitario esmaltado a media altura en el tabique
	_add_box_2d(b_root, Vector2(699.0, 152.0), Vector2(44.2, 5.8), 2.0, 11.5, m_white_enamel)
	_add_box_2d(b_root, Vector2(791.0, 152.0), Vector2(44.2, 5.8), 2.0, 11.5, m_white_enamel)
	_add_box_2d(b_root, Vector2(699.0, 152.0), Vector2(44.4, 6.0), 13.5, 1.2, m_teal_trim)
	_add_box_2d(b_root, Vector2(791.0, 152.0), Vector2(44.4, 6.0), 13.5, 1.2, m_teal_trim)
	# Marco clínico, dintel superior y placa «MORGUE» sobre el paso central (x = 721..769, y = 152)
	_add_box_2d(b_root, Vector2(721.5, 152.0), Vector2(2.8, 6.2), 2.0, ih, m_teal_trim)
	_add_box_2d(b_root, Vector2(768.5, 152.0), Vector2(2.8, 6.2), 2.0, ih, m_teal_trim)
	_add_box_2d(b_root, Vector2(745.0, 152.0), Vector2(48.0, 5.8), 2.0 + ih * 0.76, ih * 0.24, m_wall)
	_add_box_2d(b_root, Vector2(745.0, 152.0), Vector2(48.0, 6.2), 2.0 + ih * 0.74, 1.8, m_teal_trim)
	_add_box_2d(b_root, Vector2(745.0, 148.8), Vector2(18.0, 0.8), 2.0 + ih * 0.79, 4.2, m_white_enamel)
	_add_box_2d(b_root, Vector2(745.0, 148.6), Vector2(15.6, 0.8), 2.0 + ih * 0.82, 1.4, m_teal_trim)

	# 3. Sala Norte — Ala Oeste: Box de Urgencias y Botiquín Clínico (x = 680..726, y = 104..146)
	_build_hospital_bed_3d(b_root, vm._hospital_bed_pos, m_white_enamel, m_teal_sheet, m_pillow)
	# Soporte de suero intravenoso de acero inoxidable junto a la cabecera de urgencias (Vector2(700, 121))
	_add_cyl_2d(b_root, Vector2(700.0, 121.0), 2.2, 2.0, 0.8, m_steel, 2.2, 8)
	_add_cyl_2d(b_root, Vector2(700.0, 121.0), 0.45, 2.8, 16.5, m_steel, 0.45, 8)
	_add_box_2d(b_root, Vector2(700.0, 121.0), Vector2(3.6, 0.6), 19.0, 0.6, m_steel)
	_add_cyl_2d(b_root, Vector2(701.2, 121.0), 0.9, 16.2, 2.6, m_glass_jar, 0.9, 8)
	# Biombo médico plegable de 2 hojas junto al box de urgencias (Vector2(692, 133))
	_add_box_2d(b_root, Vector2(692.0, 133.0), Vector2(1.4, 17.0), 2.0, 14.5, m_white_enamel)
	_add_box_2d(b_root, Vector2(692.0, 133.0), Vector2(1.8, 15.2), 3.6, 11.8, m_screen_cloth)
	# Estantería de frascos medicinales, vitrina farmacéutica y lavamanos quirúrgico
	_add_model_2d(b_root, "props/Shelf_Small_Bottles.gltf", Vector2(691.0, 106.5), 2.0, Vector2(12.0, 5.5), 13.5)
	_add_model_2d(b_root, "props/Cabinet.gltf", Vector2(711.0, 106.8), 2.0, Vector2(13.0, 6.5), 13.5)
	_add_box_2d(b_root, Vector2(682.5, 118.0), Vector2(5.2, 7.5), 2.0, 7.8, m_white_enamel) # Pedestal lavamanos
	_add_box_2d(b_root, Vector2(683.2, 118.0), Vector2(6.5, 8.8), 9.4, 2.0, m_white_enamel) # Pileta porcelana
	_add_box_2d(b_root, Vector2(681.2, 118.0), Vector2(1.6, 1.6), 11.4, 2.4, m_gold) # Grifo de latón

	# 4. Sala Norte — Ala Este: Consulta del Dr. Valen y Cama de Guardia (x = 758..808, y = 104..146)
	var doc_desk := Vector2(768.0, 124.0)
	if _add_model_2d(b_root, "props/Table_Large.gltf", doc_desk, 2.0, Vector2(18.0, 11.0), 7.6) == null:
		_add_box_2d(b_root, doc_desk, Vector2(18.0, 11.0), 2.0, 7.6, m_dark_wood)
	for ch_p in [doc_desk + Vector2(0.0, -11.5), doc_desk + Vector2(0.0, 11.5)]:
		_add_model_2d(b_root, "props/Chair_1.gltf", ch_p, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(ch_p, doc_desk))
	_add_model_2d(b_root, "props/Book_5.gltf", doc_desk + Vector2(-4.0, -1.0), 9.6, Vector2(4.5, 3.5), 2.0)
	_add_model_2d(b_root, "props/Bottle_1.gltf", doc_desk + Vector2(4.2, -2.0), 9.6, Vector2(2.6, 2.6), 3.8)
	_add_model_2d(b_root, "props/CandleStick.gltf", doc_desk + Vector2(2.0, 2.0), 9.6, Vector2(3.0, 3.0), 4.8)
	# Segunda cama clínica (guardia/observación) junto al muro este (Vector2(796, 134)) y mesilla
	_build_hospital_bed_3d(b_root, Vector2(796.0, 134.0), m_white_enamel, m_teal_sheet, m_pillow)
	_add_model_2d(b_root, "props/Nightstand_Shelf.gltf", Vector2(796.0, 107.0), 2.0, Vector2(7.0, 6.0), 7.8)

	# 5. Sala Sur — Morgue Forense (x = 679..811, y = 155..193)
	# 3 Mesas de autopsia de acero inoxidable con pedestal hidráulico, bandeja acanalada, reposacabezas y desagüe
	for mp in vm._morgue_table_positions:
		_register_furniture_rect("MorgueTable", mp, Vector2(13.6, 21.6))
		_add_box_2d(b_root, mp, Vector2(8.6, 13.0), 2.0, 1.0, m_dark_steel) # Placa base de anclaje
		_add_cyl_2d(b_root, mp, 2.8, 3.0, 4.4, m_steel, 2.8, 8) # Columna hidráulica central
		for lx in [-5.4, 5.4]:
			for ly in [-9.0, 9.0]:
				_add_cyl_2d(b_root, mp + Vector2(lx, ly), 0.55, 2.0, 5.4, m_dark_steel, 0.55, 8)
		# Bandeja superior de disección de acero inoxidable con rebordes perimetrales y canal de drenaje
		_add_box_2d(b_root, mp, Vector2(13.6, 21.6), 7.4, 1.1, m_steel)
		_add_box_2d(b_root, mp + Vector2(-6.4, 0.0), Vector2(0.8, 21.6), 8.5, 0.55, m_dark_steel)
		_add_box_2d(b_root, mp + Vector2(6.4, 0.0), Vector2(0.8, 21.6), 8.5, 0.55, m_dark_steel)
		_add_box_2d(b_root, mp + Vector2(0.0, -10.4), Vector2(13.6, 0.8), 8.5, 0.55, m_dark_steel)
		_add_box_2d(b_root, mp + Vector2(0.0, 10.4), Vector2(13.6, 0.8), 8.5, 0.55, m_dark_steel)
		_add_box_2d(b_root, mp + Vector2(0.0, -7.2), Vector2(5.8, 2.4), 8.5, 1.1, m_dark_steel) # Bloque occipucio / reposacabezas
		for gx in [-2.8, 0.0, 2.8]:
			_add_box_2d(b_root, mp + Vector2(gx, 1.5), Vector2(0.4, 13.5), 8.5, 0.18, m_dark_steel) # Estrías de evacuación
		# Tubo de desagüe y cubo colector bajo el extremo sur de la mesa
		_add_cyl_2d(b_root, mp + Vector2(0.0, 8.2), 0.5, 4.2, 3.2, m_dark_steel, 0.5, 8)
		_add_cyl_2d(b_root, mp + Vector2(0.0, 8.2), 2.1, 2.0, 2.6, m_steel, 1.7, 8)
		# Lámpara quirúrgica suspendida sobre cada mesa de autopsia
		_add_cyl_2d(b_root, mp, 0.45, ih - 5.5, 5.5, m_dark_steel, 0.45, 8)
		_add_box_2d(b_root, mp, Vector2(9.5, 5.2), ih - 6.8, 1.4, m_steel)
		_add_box_2d(b_root, mp, Vector2(8.2, 3.8), ih - 7.1, 0.4, m_lamp_glow)
		# Nodo de cadáver cubierto con sábana forense (sincronizado con vm.morgue_active_corpses)
		var body_n := Node3D.new()
		body_n.visible = false
		b_root.add_child(body_n)
		_add_box_2d(body_n, mp + Vector2(0.0, 0.8), Vector2(9.2, 16.8), 8.5, 3.6, m_shroud)
		_add_box_2d(body_n, mp + Vector2(0.0, -6.2), Vector2(5.2, 5.0), 8.5, 4.4, m_shroud)
		_add_box_2d(body_n, mp + Vector2(0.0, 7.8), Vector2(6.6, 2.4), 8.5, 4.2, m_shroud)
		_morgue_body_nodes_3d.append(body_n)

	# 6. Equipamiento forense perimetral de la Morgue (sin invadir los pasillos de paso x=723.5 y x=766.5)
	# Cámaras frigoríficas mortuorias de acero empotradas en el muro oeste (x = 681, y = 174)
	_add_box_2d(b_root, Vector2(681.2, 174.0), Vector2(4.2, 26.0), 2.0, 18.5, m_dark_steel)
	for cy_l in [-7.5, 0.0, 7.5]:
		for cz_h in [4.5, 12.0]:
			_add_box_2d(b_root, Vector2(683.4, 174.0 + cy_l), Vector2(0.6, 7.2), cz_h, 6.2, m_steel)
			_add_box_2d(b_root, Vector2(683.9, 174.0 + cy_l), Vector2(0.6, 1.8), cz_h + 2.6, 0.9, m_gold)
	# Carrito quirúrgico de acero inoxidable con frascos de muestras e instrumental (Vector2(723.5, 189.0))
	var tr_p := Vector2(723.5, 189.0)
	_add_box_2d(b_root, tr_p, Vector2(11.0, 6.2), 2.4, 0.6, m_steel)
	_add_box_2d(b_root, tr_p, Vector2(11.0, 6.2), 8.2, 0.7, m_steel)
	for tx in [-4.8, 4.8]:
		for ty in [-2.6, 2.6]:
			_add_cyl_2d(b_root, tr_p + Vector2(tx, ty), 0.4, 2.0, 7.0, m_dark_steel, 0.4, 6)
	_add_cyl_2d(b_root, tr_p + Vector2(-2.8, 0.0), 1.3, 8.9, 3.0, m_glass_jar, 1.3, 8)
	_add_box_2d(b_root, tr_p + Vector2(2.2, 0.0), Vector2(4.2, 3.2), 8.9, 0.5, m_dark_steel)
	# Atril de registro de autopsias y vitrina de muestras en el lado este de la morgue
	_add_model_2d(b_root, "props/BookStand.gltf", Vector2(766.5, 189.0), 2.0, Vector2(7.0, 7.0), 10.8, 180.0)
	_add_model_2d(b_root, "props/Shelf_Small_Bottles.gltf", Vector2(805.5, 174.0), 2.0, Vector2(6.0, 14.0), 14.0, -90.0)

	# 7. Iluminación clínica (cálida-blanca en Urgencias, blanca-fría quirúrgica en la Morgue) y faroles de fachada
	_restaurant_light(b_root, Vector2(712.0, 126.0), ih - 4.5, Color(0.94, 0.98, 0.96), 0.95, 2.4, false)
	_restaurant_light(b_root, Vector2(778.0, 126.0), ih - 4.5, Color(0.96, 0.94, 0.86), 0.92, 2.4, false)
	_restaurant_light(b_root, Vector2(715.0, 176.0), ih - 5.0, Color(0.76, 0.92, 1.0), 0.95, 2.3, false)
	_restaurant_light(b_root, Vector2(775.0, 176.0), ih - 5.0, Color(0.76, 0.92, 1.0), 0.95, 2.3, false)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", Vector2(720.0, 97.5), wall_h * 0.58, Vector2(4.0, 4.0), 6.0)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", Vector2(770.0, 97.5), wall_h * 0.58, Vector2(4.0, 4.0), 6.0)

func _build_hospital_bed_3d(parent: Node3D, pos_2d: Vector2, m_frame: Material, m_sheet: Material, m_pillow: Material) -> void:
	_register_furniture_rect("HospitalBed", pos_2d, Vector2(13.5, 19.5))
	# Cabecero y piecero tubulares de acero esmaltado blanco + bastidor elevado sobre 4 patas
	_add_box_2d(parent, pos_2d + Vector2(0.0, -9.2), Vector2(13.5, 1.2), 2.0, 8.8, m_frame)
	_add_box_2d(parent, pos_2d + Vector2(0.0, 9.2), Vector2(13.5, 1.2), 2.0, 6.8, m_frame)
	_add_box_2d(parent, pos_2d, Vector2(13.5, 18.0), 4.2, 1.2, m_frame)
	# Colchón clínico blanco, manta verde agua y almohada
	_add_box_2d(parent, pos_2d, Vector2(12.4, 17.4), 5.4, 1.6, m_pillow)
	_add_box_2d(parent, pos_2d + Vector2(0.0, 2.4), Vector2(12.6, 12.2), 7.0, 0.8, m_sheet)
	_add_box_2d(parent, pos_2d + Vector2(0.0, -5.8), Vector2(9.4, 3.8), 7.0, 1.3, m_pillow)

## Punto 4 del Caso I: Biblioteca Municipal y Archivo del Valle (`building_library`, solar n5, tamaño 128x96, puerta al sur).
## Tres zonas diferenciadas con arcada interior de nogal, alfombras de lectura y estanterías llenas de volúmenes:
##  1) Mostrador de Catalogación y Préstamo (Suroeste): escritorio de bibliotecario, fichero y libros de registro.
##  2) Rincón de Crónicas del Valle y Mapas (Sureste): mesa de consulta, pergaminos y estantería lateral.
##  3) Gran Sala de Lectura y Fondo Antiguo (Norte): gran mesa central con 4 sillas y candelabros, atril de crónicas y 6 grandes librerías repletas de tomos.
func _build_library_3d(b_root: Node3D, rect: Rect2, door_south: bool, wall_h: float, m_wall: Material, m_trim: Material, m_wood: Material, m_dark_wood: Material, _m_iron: Material, m_gold: Material) -> void:
	var c: Vector2 = rect.get_center()
	var m_dir: float = -1.0 if door_south else 1.0
	var ih: float = wall_h - 0.15
	var m_rug_burgundy := _mat("lib_rug_burgundy", Color(0.38, 0.17, 0.16), 0.96, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_rug_border := _mat("lib_rug_border", Color(0.20, 0.13, 0.11), 0.98, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_wainscot := _mat("lib_wainscot_oak", Color(0.30, 0.20, 0.13), 0.86, 0.04, Color.BLACK, 0.0, "town_textures/rf_planks.png")
	var m_wainscot_cap := _mat("lib_wainscot_cap", Color(0.22, 0.15, 0.10), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/rf_planks.png")
	var m_book_red := _mat("lib_book_red", Color(0.62, 0.16, 0.14), 0.78, 0.05)
	var m_book_blue := _mat("lib_book_blue", Color(0.16, 0.28, 0.48), 0.78, 0.05)
	var m_book_green := _mat("lib_book_green", Color(0.16, 0.42, 0.24), 0.78, 0.05)
	var m_book_ochre := _mat("lib_book_ochre", Color(0.66, 0.48, 0.18), 0.78, 0.05)
	var m_book_leather := _mat("lib_book_leather", Color(0.40, 0.24, 0.14), 0.82, 0.04)
	var book_mats: Array[Material] = [m_book_red, m_book_blue, m_book_green, m_book_ochre, m_book_leather]

	# 1. Alfombras tejidas gastadas de lectura (sala norte y pasillo de entrada), sin bordes amarillos chillones
	_add_box_2d(b_root, c + Vector2(-10.0, 15.0 * m_dir), Vector2(62.0, 32.0), 2.50, 0.14, m_rug_border)
	_add_box_2d(b_root, c + Vector2(-10.0, 15.0 * m_dir), Vector2(58.0, 28.5), 2.52, 0.15, m_rug_burgundy)
	_add_box_2d(b_root, c + Vector2(0.0, -20.0 * m_dir), Vector2(27.0, 29.0), 2.50, 0.14, m_rug_border)
	_add_box_2d(b_root, c + Vector2(0.0, -20.0 * m_dir), Vector2(24.0, 26.0), 2.52, 0.15, m_rug_burgundy)

	# 2. Arcada interior de madera de nogal y friso perimetral que separa el Vestíbulo de Recepción de la Gran Sala de Lectura
	_add_box_2d(b_root, c + Vector2(-49.0, -2.0 * m_dir), Vector2(22.0, 4.4), 2.0, 11.5, m_wainscot)
	_add_box_2d(b_root, c + Vector2(-49.0, -2.0 * m_dir), Vector2(22.4, 4.8), 13.5, 1.2, m_wainscot_cap)
	_add_box_2d(b_root, c + Vector2(-38.0, -2.0 * m_dir), Vector2(3.4, 5.2), 2.0, ih, m_wainscot)
	_add_box_2d(b_root, c + Vector2(-58.0, -2.0 * m_dir), Vector2(3.2, 5.0), 2.0, ih, m_wainscot)
	_add_box_2d(b_root, c + Vector2(24.0, -2.0 * m_dir), Vector2(3.4, 5.2), 2.0, ih, m_wainscot)
	_add_box_2d(b_root, c + Vector2(58.0, -2.0 * m_dir), Vector2(3.2, 5.0), 2.0, ih, m_wainscot)
	_add_box_2d(b_root, c + Vector2(0.0, -2.0 * m_dir), Vector2(120.0, 4.8), 2.0 + ih * 0.78, ih * 0.22, m_wainscot)
	_add_box_2d(b_root, c + Vector2(0.0, -2.0 * m_dir), Vector2(78.0, 5.2), 2.0 + ih * 0.76, 1.4, m_wainscot_cap)

	# 3. Fondo Antiguo (Muro Norte): 3 grandes librerías de nogal en la sala pública + librería lateral oeste
	var north_rot: float = 0.0 if door_south else 180.0
	for bi in range(3):
		var sx: float = [-44.0, -18.0, 8.0][bi]
		var bc_pos: Vector2 = c + Vector2(sx, 36.0 * m_dir)
		_add_model_2d(b_root, "props/Bookcase_2.gltf", bc_pos, 2.0, Vector2(20.0, 7.0), 21.5, north_rot)
		for shelf_i in range(3):
			var sh_h: float = 8.4 + float(shelf_i) * 4.2
			for bk_i in range(7):
				var bx_off: float = -7.2 + float(bk_i) * 2.4
				var b_h: float = 2.7 + float((bi + shelf_i + bk_i) % 3) * 0.45
				var b_mat: Material = book_mats[(bi * 3 + shelf_i * 2 + bk_i) % book_mats.size()]
				_add_box_2d(b_root, bc_pos + Vector2(bx_off, -0.4 * m_dir), Vector2(1.9, 3.6), sh_h, b_h, b_mat)
	_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(-53.0, 14.0 * m_dir), 2.0, Vector2(18.0, 7.0), 20.0, 90.0)
	for shelf_j in range(3):
		var sh_h2: float = 8.0 + float(shelf_j) * 3.9
		for bk_j in range(6):
			var by_off: float = -6.0 + float(bk_j) * 2.4
			var b_mat2: Material = book_mats[(shelf_j + bk_j) % book_mats.size()]
			_add_box_2d(b_root, c + Vector2(-52.6, 14.0 * m_dir + by_off), Vector2(3.4, 2.0), sh_h2, 2.8, b_mat2)

	# ==========================================================================
	# 3b. PUNTO 5 (CASO I): SALA OCULTA DE LA BIBLIOTECA (Cuadrante Noreste, `c + Vector2(24..62, -46..-4)`)
	# ==========================================================================
	var m_occult_floor := _mat("lib_secret_stone_floor", Color(0.05, 0.05, 0.05), 0.98, 0.02, Color.BLACK, 0.0, "town_textures/floor_stone_grate.png")
	var m_secret_wall_stone := _mat("lib_secret_wall_stone", Color(0.07, 0.07, 0.07), 0.98, 0.02, Color.BLACK, 0.0, "town_textures/wall_stone.png", "town_textures/wall_stone_n.png", 0.78)
	var m_old_shelf_wood := _mat("lib_secret_old_wood", Color(0.07, 0.05, 0.04), 0.96, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "town_textures/rf_planks_n.png", 0.85)
	var m_old_shelf_dark := _mat("lib_secret_old_wood_dark", Color(0.04, 0.03, 0.02), 0.98, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "town_textures/rf_planks_n.png", 0.88)
	var m_drag_scuff := _mat("lib_floor_drag_scuff", Color(0.14, 0.10, 0.06), 0.96, 0.0)
	var m_draft_wisp := _mat("lib_draft_air_wisp", Color(0.84, 0.88, 0.94, 0.34), 0.90, 0.0, Color(0.62, 0.68, 0.78), 0.35)
	(m_draft_wisp as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	var m_dust_mote := _mat("lib_draft_dust_mote", Color(0.86, 0.80, 0.66, 0.72), 0.88, 0.0, Color(0.55, 0.48, 0.35), 0.35)
	var m_secret_dust := _mat("lib_secret_floor_dust", Color(0.18, 0.16, 0.14, 0.76), 0.98, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_cobweb_secret := _mat("lib_secret_cobweb", Color(0.58, 0.56, 0.52, 0.46), 0.95, 0.0)
	(m_cobweb_secret as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	var m_cobweb_strand := _mat("lib_secret_cobweb_strand", Color(0.66, 0.64, 0.60, 0.62), 0.94, 0.0)
	# Libros gastados de tonos apagados (pardo, negro, granate)
	var m_tome_brown_1 := _mat("lib_tome_brown_1", Color(0.11, 0.08, 0.05), 0.95, 0.02, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_tome_brown_2 := _mat("lib_tome_brown_2", Color(0.08, 0.06, 0.04), 0.96, 0.02, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_tome_black_1 := _mat("lib_tome_black_1", Color(0.04, 0.04, 0.04), 0.95, 0.03, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_tome_black_2 := _mat("lib_tome_black_2", Color(0.07, 0.07, 0.07), 0.96, 0.02, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_tome_maroon_1 := _mat("lib_tome_maroon_1", Color(0.13, 0.04, 0.05), 0.94, 0.02, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_tome_maroon_2 := _mat("lib_tome_maroon_2", Color(0.09, 0.03, 0.04), 0.95, 0.02, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_book_lever := _mat("lib_book_lever_crimson", Color(0.34, 0.08, 0.08), 0.85, 0.06, Color(0.08, 0.01, 0.01), 0.12)
	var m_page_paper := _mat("lib_secret_paper", Color(0.56, 0.50, 0.38), 0.94, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_sand.png", "", 0.85)
	var m_bundle_paper := _mat("lib_bundle_paper", Color(0.32, 0.26, 0.19), 0.96, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_sand.png", "", 0.85)
	var m_bundle_twine := _mat("lib_bundle_twine", Color(0.16, 0.12, 0.08), 0.94, 0.0)
	var m_ink_sig := _mat("lib_secret_ink", Color(0.06, 0.05, 0.05), 0.94, 0.0)
	var m_torn_stub := _mat("lib_torn_page_stub", Color(0.62, 0.56, 0.44), 0.95, 0.0)
	var m_carved_tablet := _mat("lib_carved_stone_tablet", Color(0.09, 0.08, 0.08), 0.96, 0.02, Color.BLACK, 0.0, "town_textures/wall_stone.png", "town_textures/wall_stone_n.png", 0.82)
	var m_carved_groove := _mat("lib_carved_stone_groove", Color(0.02, 0.02, 0.02), 0.98, 0.0)
	var m_candle_wax := _mat("lib_secret_candle_wax", Color(0.82, 0.74, 0.56), 0.72, 0.02)
	var m_candle_flame := _mat("lib_secret_candle_flame", Color(1.0, 0.78, 0.32), 0.20, 0.0, Color(1.0, 0.64, 0.18), 2.8)

	# Pavimento de losa antigua, revestimiento interior de piedra oscura en los muros de la Sala Oculta y techo bajo de madera vieja
	_add_box_2d(b_root, c + Vector2(43.0, 25.0 * m_dir), Vector2(36.0, 40.0), 2.48, 0.18, m_occult_floor)
	_add_box_2d(b_root, c + Vector2(43.0, 25.0 * m_dir), Vector2(37.0, 41.0), 2.0 + ih - 0.8, 0.8, m_old_shelf_dark)
	_add_box_2d(b_root, c + Vector2(24.0, 25.0 * m_dir), Vector2(3.8, 42.0), 2.0, ih, m_wainscot)
	_add_box_2d(b_root, c + Vector2(25.6, 25.0 * m_dir), Vector2(1.4, 41.2), 2.0, ih, m_secret_wall_stone)
	_add_box_2d(b_root, c + Vector2(43.0, 44.6 * m_dir), Vector2(36.5, 2.2), 2.0, ih, m_secret_wall_stone)
	_add_box_2d(b_root, c + Vector2(60.0, 25.0 * m_dir), Vector2(2.2, 41.2), 2.0, ih, m_secret_wall_stone)
	_add_box_2d(b_root, c + Vector2(56.5, 4.0 * m_dir), Vector2(11.0, 3.8), 2.0, ih, m_wainscot)
	_add_box_2d(b_root, c + Vector2(56.5, 5.4 * m_dir), Vector2(10.8, 1.4), 2.0, ih, m_secret_wall_stone)
	_add_box_2d(b_root, c + Vector2(37.5, 4.0 * m_dir), Vector2(27.0, 3.8), 2.0 + ih * 0.78, ih * 0.22, m_wainscot)
	_add_box_2d(b_root, c + Vector2(37.5, 5.4 * m_dir), Vector2(26.8, 1.4), 2.0 + ih * 0.78, ih * 0.22, m_secret_wall_stone)
	# Vigas y pilares de madera oscura vieja en las esquinas de la Sala Oculta
	for pil_p in [
		c + Vector2(26.8, 43.2 * m_dir),
		c + Vector2(58.8, 43.2 * m_dir),
		c + Vector2(26.8, 6.8 * m_dir),
		c + Vector2(58.8, 6.8 * m_dir),
	]:
		_add_box_2d(b_root, pil_p, Vector2(2.4, 2.4), 2.0, ih, m_old_shelf_dark)

	# A) MARCAS DE ARRASTRE EN EL SUELO (`c + Vector2(38, -1.5)`) producidas al girar la estantería secreta
	var lever_area_pos: Vector2 = c + Vector2(39.0, 1.5 * m_dir)
	for arc_i in range(6):
		var ang_sc: float = -12.0 + float(arc_i) * 11.0
		var r_off := Vector2(-8.5 + float(arc_i) * 2.4, -3.5 + float(arc_i % 2) * 1.6)
		_add_box_2d(b_root, lever_area_pos + r_off, Vector2(4.8, 0.65), 2.55, 0.09, m_drag_scuff, ang_sc)
		_add_box_2d(b_root, lever_area_pos + r_off + Vector2(0.8, 2.2), Vector2(4.2, 0.55), 2.55, 0.09, m_drag_scuff, ang_sc + 6.0)

	# B) CORRIENTE DE AIRE (POLVO QUE SE MUEVE) saliendo por la rendija de la estantería secreta
	for wisp_d in [
		[lever_area_pos + Vector2(-5.5, -1.0), Vector2(1.4, 8.5), 4.2, 0.18, -16.0],
		[lever_area_pos + Vector2(-2.0, 0.5), Vector2(1.2, 9.5), 6.8, 0.16, -22.0],
		[lever_area_pos + Vector2(1.5, -0.5), Vector2(1.3, 8.0), 9.4, 0.16, -14.0],
	]:
		_add_box_2d(b_root, wisp_d[0], wisp_d[1], float(wisp_d[2]), float(wisp_d[3]), m_draft_wisp, float(wisp_d[4]))
	for mote_i in range(10):
		var mp: Vector2 = lever_area_pos + Vector2(-6.0 + float(mote_i % 5) * 2.6, -3.0 + float(mote_i / 2) * 1.8)
		var mh: float = 3.8 + float((mote_i * 3) % 7) * 1.3
		_add_box_2d(b_root, mp, Vector2(0.28, 0.28), mh, 0.28, m_dust_mote, float(mote_i * 19))
	var draft_particles := CPUParticles3D.new()
	draft_particles.name = "LibrarySecretDraftParticles"
	draft_particles.amount = 24
	draft_particles.lifetime = 2.6
	draft_particles.preprocess = 1.5
	var pm_mote := BoxMesh.new()
	pm_mote.size = Vector3(0.008, 0.008, 0.008)
	pm_mote.material = m_dust_mote
	draft_particles.mesh = pm_mote
	draft_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	draft_particles.emission_box_extents = Vector3(0.24, 0.30, 0.16)
	draft_particles.direction = Vector3(-0.35, 0.15, 1.0).normalized()
	draft_particles.spread = 24.0
	draft_particles.gravity = Vector3(0.0, 0.02, 0.04)
	draft_particles.initial_velocity_min = 0.06
	draft_particles.initial_velocity_max = 0.14
	draft_particles.position = to_3d(lever_area_pos + Vector2(-2.0, 0.0), 7.5)
	b_root.add_child(draft_particles)

	# C) ESTANTERÍA SECRETA ENTREABIERTA CON EL LIBRO-PALANCA (`c + Vector2(46.5, 5.5 * m_dir)`)
	var sec_bc_pos: Vector2 = c + Vector2(46.5, 5.5 * m_dir)
	var sec_bc_rot: float = 32.0
	var occ_mats: Array[Material] = [
		m_tome_brown_1, m_tome_black_1, m_tome_maroon_1,
		m_tome_brown_2, m_tome_black_2, m_tome_maroon_2
	]
	_add_box_2d(b_root, sec_bc_pos, Vector2(16.5, 4.6), 2.0, 19.5, m_old_shelf_wood, sec_bc_rot)
	_add_box_2d(b_root, sec_bc_pos, Vector2(17.2, 5.2), 21.2, 1.1, m_old_shelf_dark, sec_bc_rot)
	for s_sh in [7.2, 11.6, 16.0]:
		_add_box_2d(b_root, sec_bc_pos, Vector2(15.2, 4.8), s_sh, 0.65, m_old_shelf_dark, sec_bc_rot)
	for sb_i in [-5.2, -3.0, 1.6, 3.8, 5.8]:
		_add_box_2d(b_root, sec_bc_pos + Vector2(sb_i, 0.6), Vector2(1.7, 3.2), 7.9, 2.9, occ_mats[absi(int(sb_i * 3.0)) % occ_mats.size()], sec_bc_rot)
		_add_box_2d(b_root, sec_bc_pos + Vector2(sb_i, 0.6), Vector2(1.7, 3.2), 16.7, 2.8, occ_mats[absi(int(sb_i * 5.0)) % occ_mats.size()], sec_bc_rot)
	# El LIBRO-PALANCA: tomo granate gastado que sobresale inclinado en la balda central y acciona el pestillo
	var lever_book_p: Vector2 = sec_bc_pos + Vector2(-1.4, 2.2)
	var lb_mi := _add_box_2d(b_root, lever_book_p, Vector2(2.2, 4.8), 12.2, 3.4, m_book_lever, sec_bc_rot)
	lb_mi.rotation.x = 0.38
	_add_box_2d(b_root, lever_book_p + Vector2(0.0, 0.4), Vector2(2.3, 1.2), 13.2, 2.8, m_bundle_paper, sec_bc_rot)

	# D) INTERIOR DE LA SALA OCULTA: Estantes de madera oscura y vieja, libros gastados (pardo, negro, granate),
	#    legajos atados, polvo, telarañas, símbolo grabado en piedra sin significado concreto y una sola vela
	var occ_bc_pos: Vector2 = c + Vector2(43.0, 41.2 * m_dir)
	# Estructura de estantería antigua de madera oscura y pesada (sin mueble naranja)
	_add_box_2d(b_root, occ_bc_pos + Vector2(0.0, 2.2 * m_dir), Vector2(26.0, 1.4), 2.0, 19.2, m_old_shelf_dark)
	for up_x in [-12.4, -4.2, 4.2, 12.4]:
		_add_box_2d(b_root, occ_bc_pos + Vector2(up_x, 0.0), Vector2(1.5, 5.8), 2.0, 19.2, m_old_shelf_wood)
	_add_box_2d(b_root, occ_bc_pos, Vector2(27.2, 6.4), 20.8, 1.2, m_old_shelf_dark)
	for o_sh in range(4):
		var sh_y_3d: float = 5.2 + float(o_sh) * 4.2
		_add_box_2d(b_root, occ_bc_pos, Vector2(25.6, 5.6), sh_y_3d, 0.72, m_old_shelf_dark)
		# Capa de polvo viejo sobre cada balda
		_add_box_2d(b_root, occ_bc_pos + Vector2(0.0, -1.6 * m_dir), Vector2(24.4, 1.8), sh_y_3d + 0.72, 0.05, m_secret_dust)
		if o_sh < 3:
			var o_h: float = sh_y_3d + 0.74
			for o_bk in range(9):
				if o_sh == 1 and (o_bk == 3 or o_bk == 4):
					continue # Hueco para un legajo atado en la segunda balda
				var ox_off: float = -10.4 + float(o_bk) * 2.55
				if absf(ox_off - (-4.2)) < 0.7 or absf(ox_off - 4.2) < 0.7:
					continue
				var o_mat: Material = occ_mats[(o_sh * 3 + o_bk * 2) % occ_mats.size()]
				var bk_h: float = 2.6 + float((o_sh + o_bk) % 3) * 0.42
				var bk_w: float = 1.65 + float((o_sh * 2 + o_bk) % 2) * 0.35
				var bk_mi := _add_box_2d(b_root, occ_bc_pos + Vector2(ox_off, -0.4 * m_dir), Vector2(bk_w, 3.8), o_h, bk_h, o_mat)
				if (o_sh + o_bk) % 4 == 0:
					bk_mi.rotation.z = 0.14 if (o_bk % 2 == 0) else -0.12
	# Legajos atados con cordel en la estantería del fondo y en la balda superior
	for bdl_def in [
		[occ_bc_pos + Vector2(-1.4, -0.3 * m_dir), 10.15, 8.0],
		[occ_bc_pos + Vector2(-8.2, -0.2 * m_dir), 18.55, -6.0],
		[occ_bc_pos + Vector2(8.0, -0.3 * m_dir), 18.55, 11.0],
	]:
		var bp_pos: Vector2 = bdl_def[0]
		var bp_h: float = float(bdl_def[1])
		var bp_rot: float = float(bdl_def[2])
		_add_box_2d(b_root, bp_pos, Vector2(4.4, 3.4), bp_h, 1.15, m_bundle_paper, bp_rot)
		_add_box_2d(b_root, bp_pos + Vector2(0.1, -0.1), Vector2(4.2, 3.2), bp_h + 1.15, 0.75, m_page_paper, bp_rot - 4.0)
		_add_box_2d(b_root, bp_pos, Vector2(4.6, 0.45), bp_h + 0.05, 1.92, m_bundle_twine, bp_rot)
		_add_box_2d(b_root, bp_pos, Vector2(0.45, 3.6), bp_h + 0.05, 1.92, m_bundle_twine, bp_rot)

	# Estante auxiliar estrecho de madera vieja en el muro este (`c + Vector2(57.2, 26.0 * m_dir)`) con legajos y tomos apilados
	var east_rack_p: Vector2 = c + Vector2(57.2, 26.0 * m_dir)
	_add_box_2d(b_root, east_rack_p, Vector2(3.8, 14.0), 2.0, 16.5, m_old_shelf_dark)
	for er_h in [6.0, 10.6, 15.2]:
		_add_box_2d(b_root, east_rack_p, Vector2(4.2, 13.4), er_h, 0.65, m_old_shelf_wood)
	_add_box_2d(b_root, east_rack_p + Vector2(-0.2, -2.5 * m_dir), Vector2(3.2, 4.4), 6.65, 1.2, m_tome_black_1, 6.0)
	_add_box_2d(b_root, east_rack_p + Vector2(-0.2, 2.2 * m_dir), Vector2(3.2, 4.2), 11.25, 1.4, m_bundle_paper, -8.0)
	_add_box_2d(b_root, east_rack_p + Vector2(-0.2, 2.2 * m_dir), Vector2(3.4, 0.42), 11.25, 1.48, m_bundle_twine, -8.0)

	# Símbolo geométrico abstracto grabado en la piedra sobre la estantería (sin oro ni lore de la antigua fe)
	var sym_pos: Vector2 = occ_bc_pos + Vector2(0.0, 1.8 * m_dir)
	_add_box_2d(b_root, sym_pos, Vector2(7.6, 0.8), 22.2, 4.6, m_carved_tablet)
	for gr_d in [
		[Vector2(-1.6, -0.35 * m_dir), Vector2(2.8, 0.25), 24.4, 0.32, 38.0],
		[Vector2(1.6, -0.35 * m_dir), Vector2(2.8, 0.25), 24.4, 0.32, -38.0],
		[Vector2(-1.6, -0.35 * m_dir), Vector2(2.8, 0.25), 23.1, 0.32, -38.0],
		[Vector2(1.6, -0.35 * m_dir), Vector2(2.8, 0.25), 23.1, 0.32, 38.0],
		[Vector2(0.0, -0.36 * m_dir), Vector2(0.32, 0.26), 22.6, 3.6, 0.0],
		[Vector2(0.0, -0.36 * m_dir), Vector2(4.2, 0.26), 24.25, 0.30, 0.0],
	]:
		var gr_mi := _add_box_2d(b_root, sym_pos + (gr_d[0] as Vector2), gr_d[1], float(gr_d[2]), float(gr_d[3]), m_carved_groove)
		gr_mi.rotation.z = deg_to_rad(float(gr_d[4]))

	# Manchas de polvo acumulado en el suelo y telarañas en los rincones y estantes de la Sala Oculta
	for dst_d in [
		[c + Vector2(32.0, 36.5 * m_dir), Vector2(11.0, 8.5), 14.0],
		[c + Vector2(52.5, 35.0 * m_dir), Vector2(10.5, 9.0), -18.0],
		[c + Vector2(42.0, 28.0 * m_dir), Vector2(22.0, 9.5), 4.0],
		[c + Vector2(31.0, 15.5 * m_dir), Vector2(8.5, 7.0), -22.0],
	]:
		_add_box_2d(b_root, dst_d[0], dst_d[1], 2.66, 0.05, m_secret_dust, float(dst_d[2]))
	for web_d in [
		[c + Vector2(28.5, 41.5 * m_dir), Vector2(6.5, 5.5), 19.2, 2.8, 32.0, 0.35],
		[c + Vector2(56.2, 41.5 * m_dir), Vector2(6.5, 5.5), 19.2, 2.8, -32.0, -0.35],
		[c + Vector2(56.5, 11.0 * m_dir), Vector2(5.8, 5.0), 19.5, 2.6, 28.0, 0.30],
		[c + Vector2(31.5, 28.0 * m_dir), Vector2(4.8, 4.2), 6.2, 2.2, -18.0, 0.25],
	]:
		var wb_mi := _add_box_2d(b_root, web_d[0], web_d[1], float(web_d[2]), float(web_d[3]), m_cobweb_secret, float(web_d[4]))
		wb_mi.rotation.x = float(web_d[5])
	for str_d in [
		[c + Vector2(29.2, 39.8 * m_dir), Vector2(8.2, 0.16), 20.4, 0.16, 36.0, 0.42],
		[c + Vector2(55.4, 39.8 * m_dir), Vector2(8.2, 0.16), 20.4, 0.16, -36.0, -0.42],
		[occ_bc_pos + Vector2(-9.5, -1.8 * m_dir), Vector2(5.5, 0.14), 17.8, 0.14, 22.0, 0.38],
		[occ_bc_pos + Vector2(9.5, -1.8 * m_dir), Vector2(5.5, 0.14), 13.6, 0.14, -24.0, -0.35],
	]:
		var st_mi := _add_box_2d(b_root, str_d[0], str_d[1], float(str_d[2]), float(str_d[3]), m_cobweb_strand, float(str_d[4]))
		st_mi.rotation.z = float(str_d[5])

	# Mesa prohibida interior de madera oscura y vieja (`c + Vector2(42, 28 * m_dir)`) con las 2 pistas clave del Caso I:
	var sec_tbl: Vector2 = c + Vector2(42.0, 28.0 * m_dir)
	_add_box_2d(b_root, sec_tbl, Vector2(25.0, 10.5), 2.0, 7.6, m_old_shelf_dark)
	_add_box_2d(b_root, sec_tbl, Vector2(26.2, 11.4), 9.2, 0.8, m_old_shelf_wood)
	_add_box_2d(b_root, sec_tbl + Vector2(-9.2, 2.8 * m_dir), Vector2(5.2, 3.8), 10.02, 0.04, m_secret_dust, -12.0)
	# Legajo atado en la esquina de la mesa
	var tbl_bdl_p: Vector2 = sec_tbl + Vector2(-10.2, 2.6 * m_dir)
	_add_box_2d(b_root, tbl_bdl_p, Vector2(4.0, 3.0), 10.0, 0.95, m_bundle_paper, 14.0)
	_add_box_2d(b_root, tbl_bdl_p, Vector2(4.2, 0.40), 10.02, 1.0, m_bundle_twine, 14.0)
	_add_box_2d(b_root, tbl_bdl_p, Vector2(0.40, 3.2), 10.02, 1.0, m_bundle_twine, 14.0)

	# (1) Cuaderno de firmas (`c + Vector2(35, 28 * m_dir)`)
	var ledger_p: Vector2 = sec_tbl + Vector2(-6.5, -0.4 * m_dir)
	_add_box_2d(b_root, ledger_p, Vector2(7.8, 5.8), 10.0, 0.55, m_tome_brown_2, -8.0)
	_add_box_2d(b_root, ledger_p + Vector2(-1.7, 0.0), Vector2(3.4, 5.0), 10.56, 0.18, m_page_paper, -8.0)
	_add_box_2d(b_root, ledger_p + Vector2(1.7, 0.0), Vector2(3.4, 5.0), 10.56, 0.18, m_page_paper, -8.0)
	for sig_y in [-1.4, -0.2, 1.0]:
		_add_box_2d(b_root, ledger_p + Vector2(1.6, sig_y), Vector2(2.4, 0.32), 10.76, 0.08, m_ink_sig, -8.0)

	# (2) Libro antiguo con una PÁGINA ARRANCADA (`sec_tbl + Vector2(6.5, 0.0)`) en cuero granate/negro gastado
	var torn_p: Vector2 = sec_tbl + Vector2(6.5, -0.4 * m_dir)
	_add_box_2d(b_root, torn_p, Vector2(8.6, 6.4), 10.0, 0.85, m_tome_maroon_2, 10.0)
	_add_box_2d(b_root, torn_p + Vector2(-1.9, 0.0), Vector2(3.6, 5.6), 10.86, 0.25, m_page_paper, 10.0)
	# Muñón dentado de la página arrancada en el lado derecho del códice
	_add_box_2d(b_root, torn_p + Vector2(0.6, -0.4), Vector2(1.1, 5.2), 10.92, 0.28, m_torn_stub, 16.0)
	_add_box_2d(b_root, torn_p + Vector2(2.2, 0.2), Vector2(2.6, 5.4), 10.72, 0.18, m_page_paper, 10.0)

	# E) MUY POCA LUZ (UNA SOLA VELA): una única vela de sebo sobre la mesa con alcance corto
	var candle_p: Vector2 = sec_tbl + Vector2(-0.2, 0.8 * m_dir)
	_add_cyl_2d(b_root, candle_p, 1.55, 10.0, 0.32, m_tome_black_1, 1.7, 10)
	_add_cyl_2d(b_root, candle_p + Vector2(0.25, -0.2), 0.95, 10.28, 0.35, m_candle_wax, 1.1, 8)
	_add_cyl_2d(b_root, candle_p, 0.68, 10.30, 2.55, m_candle_wax, 0.76, 10)
	_add_box_2d(b_root, candle_p, Vector2(0.34, 0.34), 12.88, 0.68, m_candle_flame, 15.0)
	var candle_lt := OmniLight3D.new()
	candle_lt.name = "LibrarySecretSingleCandleLight"
	candle_lt.light_color = Color(1.0, 0.72, 0.36)
	candle_lt.light_energy = 0.38
	candle_lt.omni_range = 1.05
	candle_lt.omni_attenuation = 1.65
	candle_lt.shadow_enabled = false
	candle_lt.position = to_3d(candle_p, 13.5)
	b_root.add_child(candle_lt)

	# 4. Gran Mesa Central de Lectura (`VillageCulture.reading_spot()`) con sillas, códices abiertos, candelabro y atril
	var read_p: Vector2 = VillageCulture.reading_spot()
	if _add_model_2d(b_root, "props/Table_Large.gltf", read_p, 2.0, Vector2(22.0, 12.5), 7.6) == null:
		_add_box_2d(b_root, read_p, Vector2(22.0, 12.5), 2.0, 7.6, m_dark_wood)
	for r_ch in [read_p + Vector2(-15.0, 0.0), read_p + Vector2(15.0, 0.0), read_p + Vector2(-5.5, -10.5 * m_dir), read_p + Vector2(5.5, -10.5 * m_dir)]:
		_add_model_2d(b_root, "props/Chair_1.gltf", r_ch, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(r_ch, read_p))
	_add_model_2d(b_root, "props/CandleStick_Triple.gltf", read_p + Vector2(0.0, 1.5 * m_dir), 9.6, Vector2(3.8, 3.8), 5.2)
	_add_model_2d(b_root, "props/Book_5.gltf", read_p + Vector2(-5.5, -1.5 * m_dir), 9.6, Vector2(4.5, 3.5), 2.0)
	_add_model_2d(b_root, "props/Book_7.gltf", read_p + Vector2(5.5, -1.5 * m_dir), 9.6, Vector2(4.5, 3.5), 2.0)
	_add_model_2d(b_root, "props/Book_Stack_1.gltf", read_p + Vector2(-6.5, 2.2 * m_dir), 9.6, Vector2(4.5, 4.5), 3.6)
	_add_model_2d(b_root, "props/Scroll_2.gltf", read_p + Vector2(6.2, 2.2 * m_dir), 9.6, Vector2(4.0, 3.5), 2.2)
	_add_model_2d(b_root, "props/BookStand.gltf", read_p + Vector2(-22.5, 5.0 * m_dir), 2.0, Vector2(7.5, 7.5), 11.0, 20.0)

	# 5. Vestíbulo Suroeste: Mostrador de Catalogación y Préstamo (c + Vector2(-36, -18 * m_dir))
	var rec_desk: Vector2 = c + Vector2(-36.0, -18.0 * m_dir)
	if _add_model_2d(b_root, "props/Workbench.gltf", rec_desk, 2.0, Vector2(18.0, 9.5), 8.2) == null:
		_add_box_2d(b_root, rec_desk, Vector2(18.0, 9.5), 2.0, 8.2, m_dark_wood)
	var rec_ch: Vector2 = rec_desk + Vector2(0.0, -10.0 * m_dir)
	_add_model_2d(b_root, "props/Chair_1.gltf", rec_ch, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(rec_ch, rec_desk))
	_add_model_2d(b_root, "props/Book_Stack_2.gltf", rec_desk + Vector2(-4.5, 0.0), 10.2, Vector2(4.5, 4.5), 3.8)
	_add_model_2d(b_root, "props/CandleStick.gltf", rec_desk + Vector2(4.5, 0.0), 10.2, Vector2(3.0, 3.0), 4.6)
	_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-53.0, -30.0 * m_dir), 2.0, Vector2(13.0, 7.5), 13.5, 90.0)

	# 6. Vestíbulo Sureste: Mesa de Consulta de Crónicas y Mapas del Valle (c + Vector2(36, -18 * m_dir))
	var study_desk: Vector2 = c + Vector2(36.0, -18.0 * m_dir)
	if _add_model_2d(b_root, "props/Table_Large.gltf", study_desk, 2.0, Vector2(18.0, 10.0), 7.5) == null:
		_add_box_2d(b_root, study_desk, Vector2(18.0, 10.0), 2.0, 7.5, m_wood)
	var st_ch: Vector2 = study_desk + Vector2(0.0, -10.5 * m_dir)
	_add_model_2d(b_root, "props/Chair_1.gltf", st_ch, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(st_ch, study_desk))
	_add_model_2d(b_root, "props/Scroll_1.gltf", study_desk + Vector2(-3.5, 0.0), 9.5, Vector2(4.2, 4.2), 2.4)
	_add_model_2d(b_root, "props/Book_5.gltf", study_desk + Vector2(3.5, 0.0), 9.5, Vector2(4.5, 3.5), 2.0)
	_add_model_2d(b_root, "props/Nightstand_Shelf.gltf", c + Vector2(53.0, -30.0 * m_dir), 2.0, Vector2(8.0, 6.5), 8.5, -90.0)

	# 7. Arañas de techo con luz cálida de lectura (en la sala pública, sin iluminar la Sala Oculta) y faroles de fachada
	for lt_x in [-30.0, 4.0]:
		var lt_p: Vector2 = c + Vector2(lt_x, 8.0 * m_dir)
		_add_model_2d(b_root, "props/Chandelier.gltf", lt_p, ih - 6.5, Vector2(11.0, 11.0), 6.2)
		_restaurant_light(b_root, lt_p, ih - 5.0, Color(1.0, 0.86, 0.58), 1.15, 2.7, false)
	_restaurant_light(b_root, c + Vector2(0.0, -20.0 * m_dir), ih - 4.5, Color(0.98, 0.84, 0.56), 0.90, 2.2, false)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", c + Vector2(-26.0, -50.5 * m_dir), wall_h * 0.58, Vector2(4.0, 4.0), 6.0)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", c + Vector2(26.0, -50.5 * m_dir), wall_h * 0.58, Vector2(4.0, 4.0), 6.0)

## Punto 5 del Caso I: Botica y Casa-Jardín «Raíz Verde» (`mixed_family_herbalist`, centro 325,155, tamaño 128x96, puerta al norte).
## Dos estancias conectadas por un paso central despejado y sincronizadas con las colisiones 2D:
##  1) Sala Norte (Botica y Laboratorio Alquímico de Elena, y=107..159): mostrador de dispensario al oeste con estanterías de pociones, y laboratorio de destilación al este con hornillo de piedra, caldero humeante, alambiques y secadero de hierbas.
##  2) Sala Sur (Trastienda y Vivienda de Elena y Tomás, y=159..203): comedor familiar con alfombra, mesa puesta con 2 sillas, y dormitorios laterales con camas, mesilla y librería.
func _build_herbalist_apothecary_3d(b_root: Node3D, rect: Rect2, wall_h: float, m_wall: Material, m_trim: Material, m_wood: Material, m_dark_wood: Material, m_iron: Material, m_gold: Material) -> void:
	var c: Vector2 = rect.get_center()
	var ih: float = wall_h - 0.15
	var m_herb_rug := _mat("herb_sage_rug", Color(0.25, 0.29, 0.21), 0.96, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_warm_rug := _mat("herb_home_rug", Color(0.36, 0.21, 0.16), 0.96, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_rug_trim := _mat("herb_rug_trim", Color(0.18, 0.14, 0.11), 0.98, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_hearth_stone := _mat("herb_brazier_stone", Color(0.46, 0.44, 0.40), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png")
	var m_brew := _mat("herb_emerald_brew", Color(0.22, 0.82, 0.44), 0.25, 0.05, Color(0.14, 0.68, 0.34), 1.35)
	var m_amber_glass := _mat("herb_amber_alembic", Color(0.88, 0.56, 0.18), 0.22, 0.12, Color(0.62, 0.36, 0.08), 0.45)
	var m_coal := _mat("herb_brazier_coal", Color(0.72, 0.22, 0.06), 0.60, 0.0, Color(0.76, 0.18, 0.04), 0.65)
	var m_herb_leaf := _mat("herb_dried_bundle", Color(0.28, 0.52, 0.24), 0.88, 0.0)
	var m_lavender := _mat("herb_dried_lavender", Color(0.48, 0.34, 0.58), 0.88, 0.0)
	var m_bed_green := _mat("herb_bed_linen", Color(0.26, 0.52, 0.38), 0.86, 0.0)
	var m_pillow := _mat("herb_pillow", Color(0.94, 0.92, 0.86), 0.85, 0.0)
	var m_plate := _mat("herb_plate", Color(0.90, 0.88, 0.82), 0.45, 0.05)

	# 1. Alfombras de arpillera/lana gastadas de la Botica y de la Vivienda trasera, sin franjas amarillas
	_add_box_2d(b_root, c + Vector2(0.0, -18.0), Vector2(23.0, 37.0), 2.50, 0.14, m_rug_trim)
	_add_box_2d(b_root, c + Vector2(0.0, -18.0), Vector2(20.5, 34.5), 2.52, 0.15, m_herb_rug)
	_add_box_2d(b_root, c + Vector2(0.0, 27.0), Vector2(45.0, 23.0), 2.50, 0.14, m_rug_trim)
	_add_box_2d(b_root, c + Vector2(0.0, 27.0), Vector2(41.5, 20.0), 2.52, 0.15, m_warm_rug)

	# 2. Tabique divisorio entre Botica (Norte) y Trastienda/Vivienda (Sur) en c.y + 4 (colisión 2D: c+(-42,4) [40x6] y c+(42,4) [40x6])
	_add_box_2d(b_root, c + Vector2(-42.0, 4.0), Vector2(40.0, 5.4), 2.0, ih, m_wall)
	_add_box_2d(b_root, c + Vector2(42.0, 4.0), Vector2(40.0, 5.4), 2.0, ih, m_wall)
	# Jambas de madera y dintel superior sobre el paso central (x = c.x - 22 .. c.x + 22)
	_add_box_2d(b_root, c + Vector2(-21.5, 4.0), Vector2(2.8, 6.0), 2.0, ih, m_trim)
	_add_box_2d(b_root, c + Vector2(21.5, 4.0), Vector2(2.8, 6.0), 2.0, ih, m_trim)
	_add_box_2d(b_root, c + Vector2(0.0, 4.0), Vector2(46.0, 5.6), 2.0 + ih * 0.78, ih * 0.22, m_wall)
	_add_box_2d(b_root, c + Vector2(0.0, 4.0), Vector2(46.0, 6.0), 2.0 + ih * 0.76, 1.8, m_trim)

	# 3. Sala Norte — Ala Oeste: Mostrador de la Botica, Vitrina de Remedios y Estantería de Frascos (pasillo central libre)
	var stall_p: Vector2 = c + Vector2(-27.0, -17.0)
	_register_furniture_rect("ApothecaryCounter", stall_p, Vector2(21.0, 9.5))
	_add_box_2d(b_root, stall_p, Vector2(20.0, 8.6), 2.0, 7.2, m_dark_wood)
	_add_box_2d(b_root, stall_p, Vector2(21.2, 9.6), 9.2, 0.8, m_wood)
	_add_box_2d(b_root, stall_p + Vector2(0.0, -4.4), Vector2(18.0, 0.4), 3.2, 5.2, m_trim)
	_add_model_2d(b_root, "props/Bottle_1.gltf", stall_p + Vector2(-6.0, -1.0), 10.0, Vector2(2.6, 2.6), 4.0)
	_add_model_2d(b_root, "props/Bottle_2.gltf", stall_p + Vector2(-3.0, 1.2), 10.0, Vector2(2.6, 2.6), 3.8)
	_add_model_2d(b_root, "props/Book_5.gltf", stall_p + Vector2(2.5, 0.0), 10.0, Vector2(4.5, 3.5), 2.0)
	_add_model_2d(b_root, "props/Mug.gltf", stall_p + Vector2(7.0, -1.0), 10.0, Vector2(2.8, 2.8), 3.0) # Mortero de botica
	_add_model_2d(b_root, "props/Shelf_Small_Bottles.gltf", c + Vector2(-34.0, -40.5), 2.0, Vector2(15.0, 5.5), 14.0)
	_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-53.0, -24.0), 2.0, Vector2(12.0, 6.5), 13.5, 90.0)

	# 4. Sala Norte — Ala Este: Laboratorio Alquímico (Hornillo de Piedra con Caldero Esmeralda, Mesa de Destilación y Secadero de Hierbas)
	var brazier_p: Vector2 = c + Vector2(35.0, -14.0)
	_register_furniture_rect("AlchemyBrazier", brazier_p, Vector2(12.0, 12.0))
	_add_box_2d(b_root, brazier_p, Vector2(12.0, 12.0), 2.0, 3.2, m_hearth_stone)
	_add_box_2d(b_root, brazier_p, Vector2(9.2, 9.2), 5.2, 0.5, m_coal)
	_add_model_2d(b_root, "props/Cauldron.gltf", brazier_p, 5.2, Vector2(10.0, 10.0), 8.2)
	_add_cyl_2d(b_root, brazier_p, 3.1, 9.8, 0.5, m_brew, 3.1, 10) # Brebaje alquímico verde esmeralda dentro del caldero
	# Mesa de alambiques y destilación junto al muro noreste (c + Vector2(28, -38))
	var dist_tbl: Vector2 = c + Vector2(28.0, -38.0)
	if _add_model_2d(b_root, "props/Table_Large.gltf", dist_tbl, 2.0, Vector2(16.0, 8.5), 7.6) == null:
		_add_box_2d(b_root, dist_tbl, Vector2(16.0, 8.5), 2.0, 7.6, m_wood)
	# Retorta y matraz de vidrio con tubo de cobre sobre la mesa de destilación
	_add_cyl_2d(b_root, dist_tbl + Vector2(-4.0, 0.0), 1.8, 9.6, 3.2, m_amber_glass, 0.8, 8)
	_add_cyl_2d(b_root, dist_tbl + Vector2(1.5, 0.0), 1.6, 9.6, 3.8, m_brew, 0.6, 8)
	_add_box_2d(b_root, dist_tbl + Vector2(-1.2, 0.0), Vector2(5.5, 0.5), 12.4, 0.5, m_gold)
	_add_model_2d(b_root, "props/Scroll_1.gltf", dist_tbl + Vector2(5.2, 0.5), 9.6, Vector2(3.8, 3.8), 2.2)
	# Viga aérea de secado con manojos colgantes de hierbas medicinales y lavanda
	_add_box_2d(b_root, c + Vector2(32.0, -24.0), Vector2(24.0, 1.6), ih - 5.5, 1.4, m_dark_wood)
	for hx_i in range(5):
		var hx_off: float = 22.0 + float(hx_i) * 5.0
		var h_mat: Material = m_herb_leaf if (hx_i % 2) == 0 else m_lavender
		_add_cyl_2d(b_root, c + Vector2(hx_off, -24.0), 0.8, ih - 10.2, 4.6, h_mat, 1.8, 6)

	# 5. Sala Sur — Trastienda y Vivienda Familiar de Elena y Tomás (c.y + 6 .. c.y + 44)
	_build_bed_3d(b_root, c + Vector2(-42.0, 26.0), m_wood, m_bed_green, m_pillow)
	_build_bed_3d(b_root, c + Vector2(42.0, 26.0), m_wood, m_bed_green, m_pillow)
	_add_model_2d(b_root, "props/Nightstand_Shelf.gltf", c + Vector2(-53.0, 14.0), 2.0, Vector2(7.0, 6.0), 7.8, 90.0)
	_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(53.0, 14.0), 2.0, Vector2(14.0, 6.0), 16.5, -90.0)
	var fam_tbl: Vector2 = c + Vector2(0.0, 28.0)
	if _add_model_2d(b_root, "props/Table_Large.gltf", fam_tbl, 2.0, Vector2(17.0, 11.0), 7.4) == null:
		_add_box_2d(b_root, fam_tbl, Vector2(17.0, 11.0), 2.0, 7.4, m_wood)
	for f_ch in [fam_tbl + Vector2(-13.0, 0.0), fam_tbl + Vector2(13.0, 0.0)]:
		_add_model_2d(b_root, "props/Chair_1.gltf", f_ch, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(f_ch, fam_tbl))
	_add_cyl_2d(b_root, fam_tbl + Vector2(-4.2, 0.0), 2.2, 9.4, 0.45, m_plate, 2.0, 8)
	_add_cyl_2d(b_root, fam_tbl + Vector2(4.2, 0.0), 2.2, 9.4, 0.45, m_plate, 2.0, 8)
	_add_model_2d(b_root, "props/CandleStick.gltf", fam_tbl + Vector2(0.0, -2.0), 9.4, Vector2(3.0, 3.0), 4.6)

	# 6. Iluminación interior (botica, caldero y vivienda trasera) y faroles de fachada
	_add_model_2d(b_root, "props/Chandelier.gltf", c + Vector2(-16.0, -20.0), ih - 6.5, Vector2(10.0, 10.0), 6.0)
	_restaurant_light(b_root, c + Vector2(-16.0, -20.0), ih - 5.0, Color(0.96, 0.90, 0.68), 1.05, 2.5, false)
	_restaurant_light(b_root, brazier_p, 14.0, Color(0.42, 0.96, 0.58), 0.78, 1.9, false)
	_restaurant_light(b_root, c + Vector2(0.0, 24.0), ih - 4.5, Color(1.0, 0.86, 0.58), 0.95, 2.4, false)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", c + Vector2(-24.0, -50.5), wall_h * 0.58, Vector2(4.0, 4.0), 6.0)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", c + Vector2(24.0, -50.5), wall_h * 0.58, Vector2(4.0, 4.0), 6.0)

## Punto 6 del Caso I: Capilla del Alba (`building_church`, centro 745,312, tamaño 132x92, puerta al norte).
## Espacios coherentes en 1.ª persona y sincronizados con las colisiones 2D:
##  1) Nave Central y Bancos de Roble (`c + (±28, -10)` y `c + (±28, 6)`): alfombra litúrgica carmesí y oro desde el pórtico norte hasta el presbiterio, 4 bancos tallados mirando al sur y pilastras con arcos de madera.
##  2) Presbiterio y Altar Mayor del Alba (`vm._church_altar_pos = 745,336`): tarima sagrada, altar con frontal carmesí/oro, cáliz sagrado, candelabros triples, misal, atril del Libro de Difuntos, mesa votiva y gran retablo con rosetón vitral y Cruz Solar en el muro sur.
##  3) Sacristía de Estudio y Confesionario al Noroeste (`696,280`) y Celda Monástica del Hermano Anselmo al Noreste (`796,280`), delimitadas por celosías de madera para no invadir la nave.
func _build_church_chapel_3d(b_root: Node3D, rect: Rect2, wall_h: float, _m_wall: Material, m_trim: Material, m_wood: Material, m_dark_wood: Material, _m_iron: Material, m_gold: Material) -> void:
	var c: Vector2 = rect.get_center()
	var ih: float = wall_h - 0.15
	var m_crimson := _mat("chapel_crimson", Color(0.40, 0.16, 0.15), 0.96, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_chapel_hem := _mat("chapel_rug_hem", Color(0.20, 0.12, 0.11), 0.98, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_gold_trim := _mat("chapel_gold_trim", Color(0.34, 0.24, 0.15), 0.82, 0.18, Color.BLACK, 0.0, "town_textures/rf_planks.png")
	var m_marble := _mat("chapel_altar_marble", Color(0.86, 0.84, 0.78), 0.38, 0.08, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png")
	var m_stained_sun := _mat("chapel_stained_sun", Color(0.98, 0.78, 0.28), 0.20, 0.10, Color(0.95, 0.68, 0.18), 1.45)
	var m_stained_ruby := _mat("chapel_stained_ruby", Color(0.86, 0.20, 0.22), 0.25, 0.08, Color(0.72, 0.12, 0.14), 0.95)
	var m_stained_azure := _mat("chapel_stained_azure", Color(0.24, 0.52, 0.88), 0.25, 0.08, Color(0.16, 0.40, 0.76), 0.85)
	var m_monk_linen := _mat("chapel_monk_linen", Color(0.52, 0.36, 0.24), 0.88, 0.0)
	var m_pillow := _mat("chapel_pillow", Color(0.92, 0.88, 0.80), 0.85, 0.0)

	# 1. Alfombra procesional gastada por el pasillo central (sin franjas amarillas) y estrado del Presbiterio al Sur
	_add_box_2d(b_root, c + Vector2(0.0, -6.0), Vector2(21.0, 55.0), 2.50, 0.14, m_chapel_hem)
	_add_box_2d(b_root, c + Vector2(0.0, -6.0), Vector2(18.5, 53.0), 2.52, 0.15, m_crimson)
	# Estrado litúrgico bajo el Altar Mayor (y = 324..352)
	_add_box_2d(b_root, c + Vector2(0.0, 26.0), Vector2(78.0, 24.0), 2.5, 0.36, m_marble)
	_add_box_2d(b_root, c + Vector2(0.0, 26.0), Vector2(52.0, 20.0), 2.86, 0.16, m_crimson)

	# 2. Celosías de madera tallada que enmarcan la Sacristía Noroeste y la Celda Noreste sin bloquear el paso
	for side_s in [-1.0, 1.0]:
		_add_box_2d(b_root, c + Vector2(36.0 * side_s, -22.0), Vector2(2.8, 3.2), 2.0, ih, m_dark_wood)
		_add_box_2d(b_root, c + Vector2(49.0 * side_s, -22.0), Vector2(24.0, 2.2), 2.0, 9.5, m_dark_wood)
		_add_box_2d(b_root, c + Vector2(49.0 * side_s, -22.0), Vector2(24.6, 2.8), 11.5, 1.0, m_gold_trim)
		_add_box_2d(b_root, c + Vector2(49.0 * side_s, -22.0), Vector2(26.0, 2.8), 2.0 + ih * 0.78, ih * 0.22, m_dark_wood)
		# Pilastras murales a lo largo de la nave y vigas tirantes bajo el techo (sin tocar 2.0 + wall_h)
		for py_pil in [-10.0, 12.0, 32.0]:
			_add_box_2d(b_root, c + Vector2(61.5 * side_s, py_pil), Vector2(3.0, 4.0), 2.0, ih, m_trim)
	for by_beam in [-22.0, 0.0, 22.0]:
		_add_box_2d(b_root, c + Vector2(0.0, by_beam), Vector2(122.0, 3.2), ih - 2.2, 2.0, m_dark_wood)

	# 3. Bancos de roble de la Nave Central (`c + (±29, -14)` y `c + (±29, 0)`), orientados hacia el Altar Sur
	for py in [-14.0, 0.0]:
		for px in [-29.0, 29.0]:
			var pew_p: Vector2 = c + Vector2(px, py)
			if _add_model_2d(b_root, "props/Bench.gltf", pew_p, 2.0, Vector2(23.0, 6.2), 6.8, 180.0) == null:
				_add_box_2d(b_root, pew_p, Vector2(23.0, 6.2), 2.0, 6.0, m_wood)
			# Respaldo litúrgico de roble oscuro en el borde norte de cada banco para mirar al Altar Sur
			_add_box_2d(b_root, pew_p + Vector2(0.0, -2.7), Vector2(22.5, 1.1), 5.2, 4.2, m_dark_wood)

	# 4. Presbiterio Sur: Altar Mayor (`vm._church_altar_pos`), Retablo del Alba, Atril de Difuntos y Mesa Votiva
	var altar_p: Vector2 = vm._church_altar_pos
	_add_model_2d(b_root, "graveyard/altar-stone.glb", altar_p, 2.0, Vector2(28.0, 9.5), 8.2)
	# Mensa de mármol y frontal carmesí/oro con cota exacta (top = 9.8 px) para que nada flote sobre el altar
	_add_box_2d(b_root, altar_p, Vector2(27.0, 9.0), 2.8, 6.2, m_marble)
	_add_box_2d(b_root, altar_p, Vector2(28.6, 9.8), 9.0, 0.8, m_marble)
	_add_box_2d(b_root, altar_p + Vector2(0.0, -4.6), Vector2(16.0, 0.6), 3.0, 6.0, m_crimson)
	_add_box_2d(b_root, altar_p + Vector2(0.0, -4.8), Vector2(1.4, 0.5), 4.2, 3.8, m_gold)
	_add_box_2d(b_root, altar_p + Vector2(0.0, -4.8), Vector2(3.6, 0.5), 5.6, 1.2, m_gold)
	_add_model_2d(b_root, "props/CandleStick_Triple.gltf", altar_p + Vector2(-10.0, 0.0), 9.8, Vector2(4.2, 4.2), 5.6)
	_add_model_2d(b_root, "props/CandleStick_Triple.gltf", altar_p + Vector2(10.0, 0.0), 9.8, Vector2(4.2, 4.2), 5.6)
	_add_model_2d(b_root, "props/Chalice.gltf", altar_p + Vector2(0.0, -0.8), 9.8, Vector2(2.8, 2.8), 3.6)
	_add_model_2d(b_root, "props/Book_5.gltf", altar_p + Vector2(-4.5, -1.0), 9.8, Vector2(4.2, 3.2), 1.8)
	# Atril del Libro de Difuntos al oeste del altar y Mesa de Velas Votivas al este
	_add_model_2d(b_root, "props/BookStand.gltf", altar_p + Vector2(-24.0, -2.0), 2.8, Vector2(7.5, 7.5), 11.0, 160.0)
	var votive_p: Vector2 = altar_p + Vector2(24.0, -2.0)
	_add_model_2d(b_root, "props/Nightstand_Shelf.gltf", votive_p, 2.8, Vector2(9.0, 6.5), 7.4, 180.0)
	_add_model_2d(b_root, "props/CandleStick.gltf", votive_p + Vector2(-2.2, 0.0), 10.2, Vector2(2.8, 2.8), 4.2)
	_add_model_2d(b_root, "props/CandleStick.gltf", votive_p + Vector2(2.2, 0.0), 10.2, Vector2(2.8, 2.8), 4.2)

	# 5. Gran Retablo del Alba y Rosetón Vitral en el Muro Sur (detrás del Altar Mayor, c.y + 42.2)
	var ret_p: Vector2 = c + Vector2(0.0, 42.2)
	_add_box_2d(b_root, ret_p, Vector2(40.0, 2.2), 2.8, ih - 3.5, m_dark_wood)
	_add_box_2d(b_root, ret_p + Vector2(-18.5, -0.4), Vector2(2.6, 2.8), 2.8, ih - 3.0, m_gold_trim)
	_add_box_2d(b_root, ret_p + Vector2(18.5, -0.4), Vector2(2.6, 2.8), 2.8, ih - 3.0, m_gold_trim)
	# Vitral tripartito luminoso (azul celeste, rubí y sol del Alba en el centro) + Gran Cruz Solar dorada
	_add_box_2d(b_root, ret_p + Vector2(-11.0, -0.8), Vector2(8.0, 1.2), 8.0, 15.0, m_stained_azure)
	_add_box_2d(b_root, ret_p + Vector2(11.0, -0.8), Vector2(8.0, 1.2), 8.0, 15.0, m_stained_azure)
	_add_box_2d(b_root, ret_p + Vector2(0.0, -0.8), Vector2(11.0, 1.2), 7.0, 18.0, m_stained_ruby)
	_add_box_2d(b_root, ret_p + Vector2(0.0, -1.1), Vector2(7.2, 1.2), 11.5, 9.0, m_stained_sun)
	_add_box_2d(b_root, ret_p + Vector2(0.0, -1.4), Vector2(2.0, 1.4), 8.0, 15.5, m_gold)
	_add_box_2d(b_root, ret_p + Vector2(0.0, -1.4), Vector2(9.5, 1.4), 15.0, 2.0, m_gold)
	# Estandartes litúrgicos laterales en el muro sur
	for ban_s in [-1.0, 1.0]:
		_add_box_2d(b_root, c + Vector2(32.0 * ban_s, 42.4), Vector2(8.0, 1.0), 7.5, 16.0, m_crimson)
		_add_box_2d(b_root, c + Vector2(32.0 * ban_s, 42.2), Vector2(9.2, 1.2), 23.2, 1.0, m_gold)

	# 6. Sacristía de Estudio al Noroeste (`Vector2(696, 280)`) y Celda del Hermano Anselmo al Noreste (`Vector2(796, 280)`)
	var study_p := Vector2(696.0, 280.0)
	if _add_model_2d(b_root, "props/Table_Large.gltf", study_p, 2.0, Vector2(14.0, 9.0), 7.4) == null:
		_add_box_2d(b_root, study_p, Vector2(14.0, 9.0), 2.0, 7.4, m_wood)
	var pr_ch := study_p + Vector2(0.0, -8.0)
	_add_model_2d(b_root, "props/Chair_1.gltf", pr_ch, 2.0, Vector2(5.5, 5.5), 8.2, _chair_rot_y_towards(pr_ch, study_p))
	_add_model_2d(b_root, "props/Book_Stack_1.gltf", study_p + Vector2(-3.2, 0.0), 9.4, Vector2(4.0, 4.0), 3.4)
	_add_model_2d(b_root, "props/CandleStick.gltf", study_p + Vector2(3.5, 0.0), 9.4, Vector2(2.8, 2.8), 4.2)
	_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-55.0, -10.0), 2.0, Vector2(11.0, 6.0), 13.0, 90.0)

	# Celda Monástica Noreste (`Vector2(796, 280)`)
	_build_bed_3d(b_root, Vector2(796.0, 280.0), m_dark_wood, m_monk_linen, m_pillow)
	_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(55.0, -10.0), 2.0, Vector2(12.0, 6.0), 15.5, -90.0)

	# 7. Arañas de techo sobre la nave, luz dorada en el Altar Mayor y faroles de fachada
	for ch_y in [-14.0, 8.0]:
		var ch_p: Vector2 = c + Vector2(0.0, ch_y)
		_add_model_2d(b_root, "props/Chandelier.gltf", ch_p, ih - 6.5, Vector2(10.5, 10.5), 6.0)
		_restaurant_light(b_root, ch_p, ih - 5.0, Color(1.0, 0.86, 0.58), 1.05, 2.5, false)
	_restaurant_light(b_root, altar_p + Vector2(0.0, -4.0), 15.5, Color(1.0, 0.82, 0.44), 1.15, 2.4, false)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", c + Vector2(-24.0, -48.5), wall_h * 0.58, Vector2(4.0, 4.0), 6.0)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", c + Vector2(24.0, -48.5), wall_h * 0.58, Vector2(4.0, 4.0), 6.0)


## Punto 1 del Encargo (Caso I): Molino Viejo Abandonado río arriba del Claro (`building_abandoned_mill`, centro 188,-1060, tamaño 124x92, puerta al sur).
## Exterior con rueda de molino parada junto al arroyo y orilla de barro rojo / arcilla;
## Interior en ruinas caminable en primera persona con:
##  1) Pajar con paja seca (`Vector2(152, -1084)`),
##  2) Hogar viejo con ceniza de carbón (`Vector2(224, -1086)`),
##  3) Cordel de cáñamo encerado (`Vector2(150, -1040)`),
##  4) Mesa (`Vector2(218, -1050)`) con un papel con el texto provisional «Lista de nombres — texto pendiente del autor».
func _build_abandoned_mill_3d(
	b_root: Node3D, rect: Rect2, wall_h: float, _m_wall: Material, _m_trim: Material,
	_m_wood: Material, m_dark_wood: Material, m_iron: Material, _m_gold: Material
) -> void:
	var c: Vector2 = rect.get_center()
	var m_rotten_wood := _mat("mill_rotten_wood", Color(0.24, 0.17, 0.11), 0.95, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "town_textures/rf_planks_n.png", 0.78)
	var m_splinter_wood := _mat("mill_splinter_wood", Color(0.32, 0.22, 0.14), 0.94, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "town_textures/rf_planks_n.png", 0.82)
	var m_moss_wood := _mat("mill_moss_wood", Color(0.22, 0.28, 0.16), 0.94, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78)
	var m_floor_gap := _mat("mill_floor_rot_gap", Color(0.06, 0.05, 0.04), 0.98, 0.0)
	var m_dust_pile := _mat("mill_dust_pile", Color(0.42, 0.39, 0.34), 0.98, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_cobweb := _mat("mill_cobweb_mat", Color(0.76, 0.74, 0.70, 0.22), 0.95, 0.0)
	(m_cobweb as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	var m_cobweb_thread := _mat("mill_cobweb_thread_mat", Color(0.82, 0.80, 0.75, 0.62), 0.92, 0.0)
	var m_rust := _mat("mill_rusted_iron", Color(0.25, 0.17, 0.13), 0.80, 0.55)
	var m_mill_stone := _mat("mill_old_stone", Color(0.36, 0.34, 0.31), 0.94, 0.04, Color.BLACK, 0.0, "town_textures/wall_stone.png", "town_textures/wall_stone_n.png", 0.75)
	var m_soot_stone := _mat("mill_soot_stone", Color(0.16, 0.15, 0.14), 0.96, 0.02, Color.BLACK, 0.0, "town_textures/wall_stone.png", "", 0.75)
	var m_coal_ash := _mat("mill_coal_ash", Color(0.13, 0.13, 0.14), 0.98, 0.02, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.85)
	var m_coal_chunk := _mat("mill_coal_chunk", Color(0.07, 0.07, 0.08), 0.78, 0.10, Color.BLACK, 0.0, "town_textures/wall_stone.png", "", 0.85)
	var m_dry_straw := _mat("mill_dry_straw", Color(0.68, 0.54, 0.24), 0.94, 0.0, Color.BLACK, 0.0, "town_textures/roof_thatch_center.png", "", 0.80)
	var m_straw_dark := _mat("mill_dry_straw_dark", Color(0.52, 0.40, 0.18), 0.96, 0.0, Color.BLACK, 0.0, "town_textures/roof_thatch_center.png", "", 0.80)
	var m_hemp_cord := _mat("mill_waxed_hemp", Color(0.70, 0.59, 0.35), 0.80, 0.04, Color.BLACK, 0.0, "town_textures/roof_thatch_center.png", "", 0.85)
	var m_beeswax := _mat("mill_beeswax", Color(0.74, 0.58, 0.24), 0.58, 0.05, Color.BLACK, 0.0, "town_textures/floor_ground_sand.png", "", 0.85)
	var m_paper := _mat("mill_list_paper", Color(0.86, 0.80, 0.66), 0.90, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_sand.png", "", 0.85)
	var m_ink := _mat("mill_list_ink", Color(0.15, 0.12, 0.10), 0.90, 0.0)
	var m_red_clay_stain := _mat("mill_floor_red_clay", Color(0.84, 0.16, 0.08), 0.56, 0.04, Color(0.26, 0.04, 0.02), 1.0, "town_textures/floor_ground_dirt.png", "", 0.82)

	# 0. EXTERIOR: Rueda de molino parada en el muro oeste (sobre el cauce del arroyo y el barro rojo de arcilla)
	var wheel_x: float = rect.position.x - 5.5
	var wheel_y: float = c.y
	var wheel_axle_h: float = 11.5
	var wheel_r_px: float = 15.0
	# Canal de piedra del caz bajo la rueda y eje horizontal que se apoya en el muro oeste exterior
	_add_box_2d(b_root, Vector2(wheel_x - 3.5, wheel_y), Vector2(3.2, 38.0), -1.2, 5.5, m_mill_stone)
	_add_box_2d(b_root, Vector2(wheel_x + 1.8, wheel_y), Vector2(6.5, 3.2), wheel_axle_h + 1.2, 2.8, m_rotten_wood)
	_add_box_2d(b_root, Vector2(wheel_x, wheel_y), Vector2(6.0, 3.8), wheel_axle_h + 1.0, 3.2, m_rust)
	# Tranca / madero caído que bloquea y mantiene parada la rueda del molino + depósitos de arcilla roja junto a la rueda
	_add_box_2d(b_root, Vector2(wheel_x - 0.5, wheel_y + 11.0), Vector2(6.5, 18.0), 1.5, 2.6, m_rotten_wood, 18.0)
	for clay_bank_patch in [
		[Vector2(rect.position.x - 16.0, wheel_y + 8.0), Vector2(12.0, 26.0), 0.22, -6.0],
		[Vector2(rect.position.x - 15.0, wheel_y - 14.0), Vector2(11.0, 22.0), 0.22, 9.0],
		[Vector2(rect.position.x - 12.0, rect.end.y + 6.0), Vector2(22.0, 18.0), 0.20, 14.0],
		[Vector2(rect.position.x + 14.0, rect.end.y + 8.0), Vector2(34.0, 16.0), 0.18, -5.0],
	]:
		_add_box_2d(b_root, clay_bank_patch[0], clay_bank_patch[1], float(clay_bank_patch[2]), 0.42, m_red_clay_stain, float(clay_bank_patch[3]))

	# Rueda hidráulica de madera oscura y musgo (10 radios y paletas, completamente parada y rota en varios tramos)
	var wheel_root := Node3D.new()
	wheel_root.name = "StoppedMillWaterwheel3D"
	wheel_root.position = to_3d(Vector2(wheel_x, wheel_y), wheel_axle_h)
	b_root.add_child(wheel_root)
	var n_paddles: int = 10
	for pi in range(n_paddles):
		var ang: float = (TAU * float(pi)) / float(n_paddles) + 0.18
		var sy_p: float = cos(ang) * wheel_r_px
		var sz_h: float = sin(ang) * wheel_r_px
		for rim_x in [-2.4, 2.4]:
			var spoke_mi := MeshInstance3D.new()
			var spoke_bm := BoxMesh.new()
			spoke_bm.size = size_3d(Vector2(1.2, wheel_r_px * 2.0), 1.4)
			spoke_mi.mesh = spoke_bm
			spoke_mi.material_override = m_rotten_wood
			spoke_mi.position = Vector3(rim_x * WORLD_SCALE, 0.0, 0.0)
			spoke_mi.rotation.x = ang
			wheel_root.add_child(spoke_mi)
		var pad_mi := MeshInstance3D.new()
		var pad_bm := BoxMesh.new()
		pad_bm.size = size_3d(Vector2(6.2, 3.2), 1.6)
		pad_mi.mesh = pad_bm
		pad_mi.material_override = m_moss_wood if (pi % 2 == 0) else m_rotten_wood
		pad_mi.position = Vector3(0.0, (sz_h * WORLD_SCALE) / _cos_p, (sy_p * WORLD_SCALE) / _sin_p)
		pad_mi.rotation.x = ang
		wheel_root.add_child(pad_mi)

		var next_ang: float = (TAU * float(pi + 1)) / float(n_paddles) + 0.18
		var mid_ang: float = (ang + next_ang) * 0.5
		var chord_len: float = 2.0 * wheel_r_px * sin(PI / float(n_paddles)) + 1.2
		for rim_side in [-2.4, 2.4]:
			var rim_mi := MeshInstance3D.new()
			var rim_bm := BoxMesh.new()
			rim_bm.size = size_3d(Vector2(1.3, chord_len), 1.8)
			rim_mi.mesh = rim_bm
			rim_mi.material_override = m_rust if (pi % 3 == 0) else m_rotten_wood
			rim_mi.position = Vector3(
				rim_side * WORLD_SCALE,
				(sin(mid_ang) * wheel_r_px * WORLD_SCALE) / _cos_p,
				(cos(mid_ang) * wheel_r_px * WORLD_SCALE) / _sin_p
			)
			rim_mi.rotation.x = mid_ang + PI * 0.5
			wheel_root.add_child(rim_mi)

	# ==========================================================================
	# AMBIENTACIÓN DE ABANDONO PROLONGADO: boquetes con piedras caídas, tablas
	# del suelo rotas/levantadas, polvo acumulado, telarañas, muebles volcados y maderas caídas
	# ==========================================================================
	# A) Boquete del muro norte (`c.x - 2, rect.position.y`) y boquete del muro este: sillares dentados, viga partida y cascotes en el suelo
	var breach_n := Vector2(c.x - 2.0, rect.position.y)
	_add_box_2d(b_root, breach_n + Vector2(-9.5, 0.5), Vector2(5.5, 6.8), 15.5, 5.2, m_soot_stone, 6.0)
	_add_box_2d(b_root, breach_n + Vector2(9.0, 0.5), Vector2(5.2, 6.8), 14.0, 6.0, m_soot_stone, -8.0)
	_add_box_2d(b_root, breach_n + Vector2(-1.0, 1.2), Vector2(22.0, 3.2), wall_h - 1.8, 2.4, m_rotten_wood, 12.0)
	# Sillares y cascotes de piedra derrumbados al pie del boquete norte y del boquete este
	for rub in [
		[breach_n + Vector2(-6.0, 6.5), Vector2(5.5, 4.2), 2.0, 2.8, 19.0],
		[breach_n + Vector2(1.5, 8.0), Vector2(6.2, 4.8), 2.0, 3.2, -14.0],
		[breach_n + Vector2(6.5, 5.8), Vector2(4.8, 3.8), 2.0, 2.4, 27.0],
		[breach_n + Vector2(-1.5, 11.5), Vector2(4.2, 3.4), 2.0, 1.9, -22.0],
		[Vector2(rect.end.x - 6.5, rect.position.y + 36.0), Vector2(4.8, 5.2), 2.0, 2.8, 15.0],
		[Vector2(rect.end.x - 8.5, rect.position.y + 41.0), Vector2(4.0, 3.8), 2.0, 2.1, -24.0],
	]:
		_add_box_2d(b_root, rub[0], rub[1], float(rub[2]), float(rub[3]), m_mill_stone, float(rub[4]))

	# B) Huecos oscuros de tablas podridas y TABLAS DEL SUELO ROTAS O LEVANTADAS
	for gap_d in [
		[Vector2(178.0, -1066.0), Vector2(14.0, 6.5), 4.0],
		[Vector2(194.0, -1052.0), Vector2(12.0, 5.8), -7.0],
		[Vector2(172.0, -1042.0), Vector2(11.0, 5.2), 11.0],
		[Vector2(188.0, -1078.0), Vector2(15.0, 6.2), -3.0],
		[Vector2(204.0, -1068.0), Vector2(10.5, 5.0), 9.0],
	]:
		_add_box_2d(b_root, gap_d[0], gap_d[1], 2.01, 0.10, m_floor_gap, float(gap_d[2]))

	for plank_d in [
		[Vector2(176.0, -1065.0), Vector2(13.0, 2.4), 2.35, 0.45, 16.0, 0.16, -0.08],
		[Vector2(182.0, -1067.5), Vector2(10.5, 2.2), 2.28, 0.42, -24.0, -0.14, 0.10],
		[Vector2(193.0, -1051.0), Vector2(12.5, 2.5), 2.40, 0.45, -12.0, 0.18, 0.06],
		[Vector2(197.0, -1054.0), Vector2(9.5, 2.1), 2.25, 0.40, 28.0, -0.15, -0.09],
		[Vector2(171.0, -1041.0), Vector2(11.5, 2.3), 2.32, 0.42, 9.0, 0.15, 0.08],
		[Vector2(186.0, -1077.0), Vector2(14.0, 2.6), 2.45, 0.48, -19.0, 0.20, -0.07],
		[Vector2(203.0, -1067.0), Vector2(11.0, 2.3), 2.36, 0.44, 22.0, -0.17, 0.09],
		[Vector2(165.0, -1056.0), Vector2(10.0, 2.2), 2.26, 0.40, -31.0, 0.12, -0.11],
	]:
		var pm := _add_box_2d(b_root, plank_d[0], plank_d[1], float(plank_d[2]), float(plank_d[3]), m_splinter_wood, float(plank_d[4]))
		pm.rotation.x += float(plank_d[5])
		pm.rotation.z += float(plank_d[6])

	# C) Capas de POLVO grisáceo, tierra seca y manchas de arcilla roja arrastrada en el suelo
	for dust_p in [
		[Vector2(185.0, -1082.0), Vector2(26.0, 14.0), 12.0],
		[Vector2(176.0, -1058.0), Vector2(22.0, 13.0), -18.0],
		[Vector2(202.0, -1064.0), Vector2(20.0, 12.0), 25.0],
		[Vector2(164.0, -1068.0), Vector2(18.0, 11.0), -9.0],
		[Vector2(214.0, -1034.0), Vector2(16.0, 10.0), 14.0],
	]:
		_add_box_2d(b_root, dust_p[0], dust_p[1], 2.02, 0.09, m_dust_pile, float(dust_p[2]))

	for mud_step in [
		[Vector2(186.0, -1020.0), Vector2(16.0, 10.0), 8.0],
		[Vector2(191.0, -1033.0), Vector2(12.0, 8.0), -15.0],
		[Vector2(204.0, -1045.0), Vector2(9.5, 6.8), 22.0],
	]:
		_add_box_2d(b_root, mud_step[0], mud_step[1], 2.03, 0.12, m_red_clay_stain, float(mud_step[2]))

	# D) MUEBLES VOLCADOS (estantería caída contra el muro norte, taburete volcado, barril roto tumbado y silla volcada junto a la mesa)
	# 1. Estantería / alacena de madera podrida volcada de costado al pie del muro norte (`Vector2(186, -1093)`)
	var fallen_shelf_p := Vector2(186.0, -1093.0)
	var fs_body := _add_box_2d(b_root, fallen_shelf_p, Vector2(20.0, 7.5), 2.2, 6.2, m_rotten_wood, -14.0)
	fs_body.rotation.z = 0.22
	for fs_bar in [-6.0, 0.0, 6.0]:
		_add_box_2d(b_root, fallen_shelf_p + Vector2(fs_bar, 0.5), Vector2(1.4, 7.8), 2.4, 6.4, m_splinter_wood, -14.0)
	# 2. Taburete / silla vieja volcada en el suelo (`Vector2(170, -1060)`)
	var fallen_stool_p := Vector2(170.0, -1060.0)
	var st_seat := _add_box_2d(b_root, fallen_stool_p, Vector2(5.2, 5.2), 2.6, 1.2, m_splinter_wood, 34.0)
	st_seat.rotation.x = 1.15
	for st_leg in [Vector2(-1.8, -1.5), Vector2(1.8, -1.5), Vector2(-1.8, 1.5), Vector2(1.8, 1.5)]:
		var lg := _add_box_2d(b_root, fallen_stool_p + st_leg + Vector2(1.6, 1.8), Vector2(0.9, 4.6), 2.2, 0.9, m_rotten_wood, 34.0)
		lg.rotation.x = 0.18
	# 3. Tonel / barril viejo de harina tumbado y desfondado junto a las muelas (`Vector2(160, -1076)`)
	var fallen_barrel := _add_cyl_2d(b_root, Vector2(160.0, -1076.0), 4.2, 3.8, 8.5, m_rotten_wood, 3.8, 10)
	fallen_barrel.rotation.z = 1.42
	fallen_barrel.rotation.y = 0.35
	_add_box_2d(b_root, Vector2(165.5, -1075.0), Vector2(9.0, 7.0), 2.03, 0.12, m_dust_pile, 18.0)

	# E) MADERAS CAÍDAS Y VIGAS DERRUMBADAS (en el suelo, apoyadas en las paredes y colgando del techo roto)
	var beam_1 := _add_box_2d(b_root, Vector2(177.0, -1075.0), Vector2(30.0, 2.8), 3.4, 2.2, m_rotten_wood, 26.0)
	beam_1.rotation.z = 0.11
	var beam_2 := _add_box_2d(b_root, Vector2(201.0, -1073.0), Vector2(28.0, 2.6), 3.2, 2.1, m_splinter_wood, -32.0)
	beam_2.rotation.z = -0.10
	_add_box_2d(b_root, Vector2(c.x - 20.0, c.y - 10.0), Vector2(44.0, 2.8), wall_h - 4.2, 2.6, m_rotten_wood, 14.0)
	_add_box_2d(b_root, Vector2(c.x + 18.0, c.y + 6.0), Vector2(40.0, 2.8), wall_h - 3.6, 2.6, m_rotten_wood, -11.0)
	_add_box_2d(b_root, Vector2(166.0, -1072.0), Vector2(19.0, 2.2), 2.15, 1.4, m_rotten_wood, 41.0)
	_add_box_2d(b_root, Vector2(202.0, -1080.0), Vector2(17.0, 2.2), 2.15, 1.4, m_splinter_wood, -36.0)
	_add_box_2d(b_root, Vector2(rect.end.x - 11.0, c.y - 4.0), Vector2(18.0, 2.6), 2.15, 1.8, m_rotten_wood, 32.0)

	# F) TELARAÑAS 3D (filamentos radiales y cruzados en esquinas altas, boquete, vigas y bajo la mesa + velos translúcidos en los rincones)
	for web_thread in [
		# Rincón del boquete norte y viga rota superior
		[Vector2(172.0, -1096.0), Vector2(18.0, 0.24), 20.5, 0.24, 18.0, 0.22],
		[Vector2(174.0, -1094.0), Vector2(16.0, 0.22), 19.2, 0.22, 34.0, 0.28],
		[Vector2(176.0, -1092.0), Vector2(14.0, 0.22), 18.0, 0.22, -22.0, -0.18],
		[Vector2(196.0, -1096.0), Vector2(17.0, 0.24), 20.2, 0.24, -19.0, -0.22],
		[Vector2(194.0, -1094.0), Vector2(15.0, 0.22), 18.8, 0.22, -36.0, -0.26],
		# Esquina noroeste sobre el pajar
		[Vector2(138.0, -1096.0), Vector2(22.0, 0.24), 21.5, 0.24, -38.0, 0.16],
		[Vector2(140.0, -1093.0), Vector2(19.0, 0.22), 19.8, 0.22, -24.0, 0.22],
		[Vector2(142.0, -1095.0), Vector2(16.0, 0.22), 20.6, 0.22, 42.0, -0.14],
		# Esquina noreste junto al hogar viejo
		[Vector2(234.0, -1096.0), Vector2(22.0, 0.24), 21.5, 0.24, 38.0, -0.16],
		[Vector2(232.0, -1093.0), Vector2(19.0, 0.22), 19.8, 0.22, 24.0, -0.22],
		[Vector2(230.0, -1095.0), Vector2(16.0, 0.22), 20.6, 0.22, -42.0, 0.14],
		# Bajo la mesa del papel y rincón del muro este
		[Vector2(218.0, -1055.0), Vector2(14.0, 0.22), 6.8, 0.22, 16.0, 0.24],
		[Vector2(222.0, -1053.0), Vector2(12.0, 0.22), 5.6, 0.22, -28.0, -0.20],
		[Vector2(236.0, -1050.0), Vector2(16.0, 0.24), 10.5, 0.24, 32.0, 0.26],
	]:
		var wt_mi := _add_box_2d(b_root, web_thread[0], web_thread[1], float(web_thread[2]), float(web_thread[3]), m_cobweb_thread, float(web_thread[4]))
		wt_mi.rotation.z = float(web_thread[5])

	var st_webs := SurfaceTool.new()
	st_webs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var web_triangles: Array = [
		# Esquina noroeste alta sobre el pajar
		[to_3d(Vector2(130.0, -1102.0), 24.5), to_3d(Vector2(154.0, -1102.0), 24.0), to_3d(Vector2(130.0, -1080.0), 17.5)],
		# Esquina noreste alta junto a la campana del hogar
		[to_3d(Vector2(214.0, -1102.0), 24.0), to_3d(Vector2(246.0, -1102.0), 24.5), to_3d(Vector2(246.0, -1080.0), 17.5)],
		# Rincón del boquete norte (velo tenue de telaraña en el borde superior)
		[to_3d(Vector2(164.0, -1100.0), 23.5), to_3d(Vector2(178.0, -1100.0), 23.0), to_3d(Vector2(168.0, -1090.0), 17.5)],
		[to_3d(Vector2(190.0, -1100.0), 23.0), to_3d(Vector2(204.0, -1100.0), 23.5), to_3d(Vector2(198.0, -1090.0), 17.5)],
		# Bajo el tablero de la mesa vieja
		[to_3d(Vector2(208.0, -1056.0), 8.1), to_3d(Vector2(226.0, -1056.0), 8.1), to_3d(Vector2(224.0, -1050.0), 3.2)],
	]
	for wt in web_triangles:
		st_webs.set_normal(Vector3.UP)
		st_webs.add_vertex(wt[0]); st_webs.add_vertex(wt[1]); st_webs.add_vertex(wt[2])
	var web_mi := MeshInstance3D.new()
	web_mi.mesh = st_webs.commit()
	web_mi.material_override = m_cobweb
	web_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b_root.add_child(web_mi)

	# ==========================================================================
	# 0b) PUNTO 4 (CASO I): SÓTANO DEL MOLINO CON REJA DE HIERRO AL CANAL DE LA RUEDA (`Vector2(138, -1061)`)
	# ==========================================================================
	# Foso escalonado de piedra húmeda bajo el lado oeste del molino que comunica con el canal de la rueda:
	# incluye barrotes de hierro con marcas claras de palanca/forcejeo y un trozo de tela del familiar enganchado.
	var cellar_pos := Vector2(139.0, -1061.0)
	var m_cellar_water := _mat("mill_cellar_water", Color(0.10, 0.18, 0.22), 0.18, 0.25)
	var m_pry_mark := _mat("mill_grate_pry_scrape", Color(0.74, 0.77, 0.82), 0.32, 0.88)
	var m_kin_cloth := _mat("mill_kin_torn_cloth", Color(0.22, 0.46, 0.68), 0.88, 0.0, Color(0.08, 0.18, 0.28), 0.35, "town_textures/roof_thatch_center.png", "", 0.85)
	# Hueco oscuro del sótano hundido y peldaños de piedra que bajan hacia el canal de la rueda
	_add_box_2d(b_root, cellar_pos, Vector2(24.0, 22.0), 2.01, 0.14, m_floor_gap)
	_add_box_2d(b_root, cellar_pos + Vector2(-4.0, 0.0), Vector2(16.0, 19.0), 0.20, 1.85, m_soot_stone)
	_add_box_2d(b_root, Vector2(rect.position.x - 1.5, cellar_pos.y), Vector2(12.0, 20.0), 2.02, 0.18, m_cellar_water)
	# Muretes laterales de piedra del foso del sótano y escalones de bajada desde el centro del molino
	_add_box_2d(b_root, cellar_pos + Vector2(0.0, -11.2), Vector2(24.0, 2.4), 2.0, 3.8, m_mill_stone)
	_add_box_2d(b_root, cellar_pos + Vector2(0.0, 11.2), Vector2(24.0, 2.4), 2.0, 3.8, m_mill_stone)
	for st_i in range(3):
		_add_box_2d(b_root, cellar_pos + Vector2(9.5 - float(st_i) * 3.8, 0.0), Vector2(3.6, 17.5), 2.0, 2.6 - float(st_i) * 0.75, m_mill_stone)
	# Marco y dintel de piedra del vano del sótano hacia el canal de la rueda (`x = 126.5, y = -1061`)
	var grate_x: float = rect.position.x + 1.2
	_add_box_2d(b_root, Vector2(grate_x, cellar_pos.y - 10.8), Vector2(4.6, 3.0), 2.0, 11.2, m_soot_stone)
	_add_box_2d(b_root, Vector2(grate_x, cellar_pos.y + 10.8), Vector2(4.6, 3.0), 2.0, 11.2, m_soot_stone)
	_add_box_2d(b_root, Vector2(grate_x, cellar_pos.y), Vector2(4.8, 22.0), 2.0, 1.4, m_mill_stone)
	_add_box_2d(b_root, Vector2(grate_x, cellar_pos.y), Vector2(4.8, 22.0), 11.8, 1.6, m_mill_stone)
	# Travesaños horizontales de la reja de hierro (el travesaño central está combado por el intento de forzarla)
	_add_box_2d(b_root, Vector2(grate_x + 0.4, cellar_pos.y), Vector2(1.4, 20.5), 3.4, 0.9, m_rust)
	_add_box_2d(b_root, Vector2(grate_x + 0.4, cellar_pos.y), Vector2(1.4, 20.5), 10.8, 0.9, m_rust)
	var mid_rail := _add_box_2d(b_root, Vector2(grate_x + 0.6, cellar_pos.y), Vector2(1.3, 20.5), 6.8, 0.85, m_rust)
	mid_rail.rotation.z = 0.08
	# Barrotes verticales de la reja: los dos centrales (`gy_i == 2` y `gy_i == 3`) están doblados/forzados dejando hueco para un frasco
	var grate_ys: Array[float] = [-8.2, -5.0, -2.2, 2.4, 5.2, 8.2]
	for gy_i in range(grate_ys.size()):
		var gy_off: float = grate_ys[gy_i]
		var bar_pos := Vector2(grate_x + 0.5, cellar_pos.y + gy_off)
		var bar_mi := _add_cyl_2d(b_root, bar_pos, 0.62, 2.8, 8.8, m_rust, 0.62, 8)
		if gy_i == 2:
			bar_mi.rotation.x = -0.22
			bar_mi.rotation.z = 0.14
		elif gy_i == 3:
			bar_mi.rotation.x = 0.24
			bar_mi.rotation.z = -0.15
	# Marcas brillantes de palanca y muescas de hierro forzado en los dos barrotes centrales y en el alféizar de piedra
	for pry_d in [
		[Vector2(grate_x + 0.9, cellar_pos.y - 1.6), Vector2(0.45, 0.65), 6.5, 0.9, 18.0],
		[Vector2(grate_x + 0.9, cellar_pos.y + 1.8), Vector2(0.45, 0.65), 6.3, 0.9, -22.0],
		[Vector2(grate_x + 1.2, cellar_pos.y - 0.3), Vector2(1.2, 2.0), 3.35, 0.22, 12.0],
		[Vector2(grate_x + 1.3, cellar_pos.y + 1.0), Vector2(1.1, 1.6), 3.35, 0.22, -19.0],
	]:
		_add_box_2d(b_root, pry_d[0], pry_d[1], float(pry_d[2]), float(pry_d[3]), m_pry_mark, float(pry_d[4]))
	# Trozo de tela azul del familiar enganchado en el barrote forzado (`Vector2(grate_x + 1.1, cellar_pos.y + 1.9)`)
	var cloth_pos := Vector2(grate_x + 1.1, cellar_pos.y + 1.9)
	var cloth_1 := _add_box_2d(b_root, cloth_pos, Vector2(2.4, 0.45), 5.6, 2.4, m_kin_cloth, 18.0)
	cloth_1.rotation.z = 0.28
	var cloth_2 := _add_box_2d(b_root, cloth_pos + Vector2(0.8, 0.5), Vector2(2.0, 0.38), 4.2, 1.9, m_kin_cloth, -24.0)
	cloth_2.rotation.x = 0.24
	_restaurant_light(b_root, Vector2(grate_x + 3.0, cellar_pos.y), 7.8, Color(0.58, 0.72, 0.84), 0.42, 1.8, false)
	# Muelas de piedra viejas desplazadas un poco al norte del foso del sótano (`x = 138, y = -1076`)
	_add_cyl_2d(b_root, Vector2(rect.position.x + 12.0, c.y - 16.0), 5.8, 2.0, 3.0, m_mill_stone, 5.8, 12)
	_add_cyl_2d(b_root, Vector2(rect.position.x + 13.5, c.y - 14.0), 5.5, 5.0, 2.8, m_mill_stone, 5.5, 12)

	# ==========================================================================
	# 1) PAJAR CON PAJA SECA (Esquina Noroeste: `Vector2(152, -1084)`)
	# ==========================================================================
	var straw_pos := Vector2(152.0, -1084.0)
	_register_furniture_rect("MillHayloft", straw_pos, Vector2(28.0, 20.0))
	# Bordillo de tablas viejas rotas del pajar y montículo de paja seca vieja y aplastada
	_add_box_2d(b_root, straw_pos + Vector2(0.0, 10.5), Vector2(30.0, 2.2), 2.0, 4.2, m_rotten_wood, 3.0)
	_add_box_2d(b_root, straw_pos + Vector2(14.5, 0.0), Vector2(2.2, 22.0), 2.0, 3.8, m_rotten_wood, -4.0)
	_add_box_2d(b_root, straw_pos, Vector2(27.0, 19.0), 2.0, 3.2, m_straw_dark)
	_add_box_2d(b_root, straw_pos + Vector2(-4.0, -2.5), Vector2(18.0, 13.0), 5.0, 2.8, m_dry_straw, -8.0)
	_add_box_2d(b_root, straw_pos + Vector2(6.0, -3.5), Vector2(13.0, 11.0), 4.8, 3.4, m_dry_straw, 14.0)
	_add_box_2d(b_root, straw_pos + Vector2(-6.5, 4.0), Vector2(14.0, 9.0), 4.6, 2.2, m_dry_straw, 19.0)
	for st_b in [
		[Vector2(-8.0, -4.0), Vector2(9.0, 3.2), 6.8, 24.0],
		[Vector2(4.0, -5.0), Vector2(10.0, 3.4), 7.2, -18.0],
		[Vector2(0.0, 2.5), Vector2(11.0, 3.0), 5.4, 9.0],
		[Vector2(10.0, 6.0), Vector2(8.0, 2.6), 4.2, -32.0],
		[Vector2(16.0, 11.0), Vector2(7.5, 2.4), 2.1, 28.0],
	]:
		_add_box_2d(b_root, straw_pos + (st_b[0] as Vector2), st_b[1], float(st_b[2]), 1.1, m_dry_straw, float(st_b[3]))

	# ==========================================================================
	# 2) HOGAR VIEJO CON CENIZA DE CARBÓN (Esquina Noreste: `Vector2(224, -1086)`)
	# ==========================================================================
	var hearth_pos := Vector2(224.0, -1086.0)
	_register_furniture_rect("MillOldHearth", hearth_pos, Vector2(26.0, 16.0))
	_add_box_2d(b_root, hearth_pos, Vector2(28.0, 18.0), 2.0, 2.2, m_mill_stone)
	_add_box_2d(b_root, hearth_pos + Vector2(-11.5, -1.0), Vector2(4.5, 15.0), 4.2, 12.5, m_soot_stone)
	_add_box_2d(b_root, hearth_pos + Vector2(11.5, -1.0), Vector2(4.5, 15.0), 4.2, 12.5, m_soot_stone)
	_add_box_2d(b_root, hearth_pos + Vector2(0.0, -6.5), Vector2(24.0, 4.0), 4.2, 19.5, m_soot_stone)
	_add_box_2d(b_root, hearth_pos + Vector2(0.0, -2.0), Vector2(27.0, 10.0), 15.5, 5.5, m_mill_stone)
	_add_box_2d(b_root, hearth_pos + Vector2(0.0, 1.0), Vector2(17.0, 10.5), 4.2, 1.4, m_coal_ash)
	_add_box_2d(b_root, hearth_pos + Vector2(-1.5, 0.5), Vector2(11.5, 7.5), 5.4, 1.3, m_coal_ash, 12.0)
	for coal_off in [
		Vector2(-4.2, 0.5), Vector2(-1.0, -1.2), Vector2(2.6, 0.8),
		Vector2(4.5, -0.6), Vector2(0.5, 2.2), Vector2(-3.0, 2.5)
	]:
		_add_box_2d(b_root, hearth_pos + coal_off, Vector2(2.6, 2.2), 6.2, 1.4, m_coal_chunk, float(int(coal_off.x * 19.0) % 45))
	_add_box_2d(b_root, hearth_pos + Vector2(15.5, 2.0), Vector2(1.0, 11.0), 2.2, 1.0, m_rust, -16.0)
	_add_cyl_2d(b_root, hearth_pos + Vector2(-16.0, 2.5), 3.4, 2.0, 5.2, m_rust, 2.8, 10)
	_add_cyl_2d(b_root, hearth_pos + Vector2(-16.0, 2.5), 2.9, 6.8, 1.0, m_coal_chunk, 2.9, 10)

	# ==========================================================================
	# 3) CORDEL DE CÁÑAMO ENCERADO (Suroeste: `Vector2(150, -1040)`)
	# ==========================================================================
	var cord_pos := Vector2(150.0, -1040.0)
	_register_furniture_rect("MillHempCord", cord_pos, Vector2(20.0, 14.0))
	_add_box_2d(b_root, cord_pos, Vector2(22.0, 14.0), 2.0, 6.8, m_rotten_wood)
	_add_box_2d(b_root, cord_pos, Vector2(23.2, 15.2), 8.4, 1.0, m_splinter_wood)
	_add_cyl_2d(b_root, cord_pos + Vector2(-3.5, -1.0), 4.2, 9.4, 3.6, m_hemp_cord, 4.0, 14)
	_add_cyl_2d(b_root, cord_pos + Vector2(-3.5, -1.0), 1.8, 9.5, 3.8, m_dark_wood, 1.8, 10)
	_add_cyl_2d(b_root, cord_pos + Vector2(3.8, 1.2), 3.4, 9.4, 2.2, m_hemp_cord, 3.4, 14)
	_add_box_2d(b_root, cord_pos + Vector2(1.5, -3.6), Vector2(9.5, 1.1), 9.4, 0.9, m_hemp_cord, 22.0)
	_add_box_2d(b_root, cord_pos + Vector2(5.2, -1.8), Vector2(7.0, 1.0), 9.4, 0.9, m_hemp_cord, -18.0)
	_add_box_2d(b_root, cord_pos + Vector2(-7.2, 2.8), Vector2(3.2, 2.4), 9.4, 1.8, m_beeswax, 15.0)
	_add_box_2d(b_root, cord_pos + Vector2(7.2, 2.5), Vector2(4.2, 1.2), 9.4, 0.6, m_iron, -28.0)
	_add_box_2d(b_root, cord_pos + Vector2(9.0, 3.4), Vector2(2.4, 1.4), 9.4, 0.8, m_dark_wood, -28.0)

	# ==========================================================================
	# 4) MESA CON PAPEL («Lista de nombres — texto pendiente del autor») (`Vector2(218, -1050)`)
	# ==========================================================================
	var table_pos := Vector2(218.0, -1050.0)
	_register_furniture_rect("MillPaperTable", table_pos, Vector2(24.0, 15.0))
	# Mesa rústica de tablones viejos y oscuros (en vez de mueble brillante nuevo)
	_add_box_2d(b_root, table_pos, Vector2(24.0, 15.0), 8.2, 1.3, m_rotten_wood)
	_add_box_2d(b_root, table_pos + Vector2(0.0, -3.5), Vector2(24.2, 3.4), 8.3, 1.3, m_splinter_wood, 1.5)
	for tx in [-10.0, 10.0]:
		for ty in [-5.8, 5.8]:
			_add_box_2d(b_root, table_pos + Vector2(tx, ty), Vector2(2.2, 2.2), 2.0, 6.4, m_rotten_wood)
	# Silla vieja VOLCADA en el suelo junto a la mesa (`table_pos + Vector2(-16.5, 1.5)`)
	var ch_pos := table_pos + Vector2(-16.5, 1.5)
	var ch_fallen := _add_box_2d(b_root, ch_pos, Vector2(5.6, 5.4), 2.8, 1.1, m_rotten_wood, -24.0)
	ch_fallen.rotation.z = 1.25
	var ch_back := _add_box_2d(b_root, ch_pos + Vector2(-2.2, -0.8), Vector2(1.0, 5.4), 2.8, 6.2, m_splinter_wood, -24.0)
	ch_back.rotation.z = 1.25
	for ch_ly in [-2.0, 2.0]:
		_add_box_2d(b_root, ch_pos + Vector2(2.2, ch_ly), Vector2(5.2, 0.9), 2.2, 0.9, m_rotten_wood, -24.0)
	# Papel sobre la mesa con renglones de tinta y texto provisional «Lista de nombres — texto pendiente del autor»
	var paper_center := table_pos + Vector2(-1.5, -0.5)
	_add_box_2d(b_root, paper_center, Vector2(11.0, 8.2), 9.52, 0.28, m_paper, -6.0)
	for line_i in range(-2, 3):
		var line_w: float = 8.2 if line_i != 2 else 5.4
		_add_box_2d(b_root, paper_center + Vector2(-0.4, float(line_i) * 1.25), Vector2(line_w, 0.42), 9.80, 0.08, m_ink, -6.0)
	# Tintero viejo volcado y palmatoria oxidada en la esquina de la mesa
	_add_cyl_2d(b_root, table_pos + Vector2(7.0, -3.2), 1.4, 9.5, 2.0, m_rust, 1.2, 8)
	_add_model_2d(b_root, "props/CandleStick.gltf", table_pos + Vector2(7.5, 2.8), 9.5, Vector2(2.8, 2.8), 4.2)

	# G) POCA LUZ: penumbra densa en el interior abandonado (absorción ambiental) con un único rayo pálido en el boquete
	var gloom_light := OmniLight3D.new()
	gloom_light.name = "MillAbandonedGloom"
	gloom_light.light_negative = true
	gloom_light.light_color = Color(0.55, 0.56, 0.58)
	gloom_light.light_energy = 0.58
	gloom_light.omni_range = 4.6
	gloom_light.omni_attenuation = 0.85
	gloom_light.position = to_3d(c + Vector2(0.0, -4.0), 14.0)
	b_root.add_child(gloom_light)
	_restaurant_light(b_root, breach_n + Vector2(0.0, 6.0), 17.0, Color(0.72, 0.78, 0.86), 0.34, 2.2, false)
	_restaurant_light(b_root, table_pos + Vector2(-2.0, -1.0), 15.0, Color(0.86, 0.80, 0.66), 0.32, 1.8, false)







