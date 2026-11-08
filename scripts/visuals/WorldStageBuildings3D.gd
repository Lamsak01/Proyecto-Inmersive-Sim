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
		wall_col = Color(0.90, 0.94, 0.96)
		roof_col = Color(0.28, 0.54, 0.58)
		floor_col = Color(0.80, 0.86, 0.88)
		trim_col = Color(0.48, 0.58, 0.62)
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
		wall_tex = "town_textures/timber_square_frame.png"
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.80, 0.70, 0.56)
		roof_col = Color(0.30, 0.44, 0.64)
	elif b_id == "building_school":
		wall_col = Color(0.86, 0.78, 0.62)
		roof_col = Color(0.68, 0.36, 0.24)
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

		# Muro izquierdo y derecho + pilares de esquina
		_add_box_2d(b_root, Vector2(rect.position.x, center.y), Vector2(wall_t, sz.y), 2.0, wall_h, m_wall)
		_add_box_2d(b_root, Vector2(rect.end.x, center.y), Vector2(wall_t, sz.y), 2.0, wall_h, m_wall)
		for c_pt in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
			_add_box_2d(b_root, c_pt, Vector2(wall_t + 2.0, wall_t + 2.0), 2.0, wall_h + 1.0, m_trim)

		# Muro cerrado (opuesto a la puerta): si es el muro sur (más cercano a la cámara), se rebaja al abrir el tejado (Cutaway)
		var closed_y: float = (center.y - half.y) if door_south else (center.y + half.y)
		if door_south:
			_add_box_2d(b_root, Vector2(center.x, closed_y), Vector2(sz.x, wall_t), 2.0, wall_h, m_wall)
		else:
			_add_box_2d(b_root, Vector2(center.x, closed_y), Vector2(sz.x, wall_t), 2.0, 9.0, m_wall)

		# Muro de la fachada con hueco de puerta + dintel sobre la puerta
		var door_y: float = door_pos.y
		var door_left_x: float = door_pos.x - door_w * 0.5
		var door_right_x: float = door_pos.x + door_w * 0.5
		var left_w: float = maxf(6.0, door_left_x - rect.position.x)
		var right_w: float = maxf(6.0, rect.end.x - door_right_x)
		_add_box_2d(b_root, Vector2(rect.position.x + left_w * 0.5, door_y), Vector2(left_w, wall_t), 2.0, wall_h, m_wall)
		_add_box_2d(b_root, Vector2(rect.end.x - right_w * 0.5, door_y), Vector2(right_w, wall_t), 2.0, wall_h, m_wall)
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

		# 3. Puerta abatible 3D sincronizada con `vm.building_doors`
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
					var door_leaf := _make_texture_panel(leaf_w, leaf_h, 3.0, _panel_mat("door_wood", "town_textures/door_wood.png", false))
					door_leaf.position = Vector3((leaf_w * 0.5) * WORLD_SCALE, (leaf_h * 0.5 * WORLD_SCALE) / _cos_p, 0.0)
					pivot.add_child(door_leaf)
				var lock_badge := MeshInstance3D.new()
				var lb_bm := BoxMesh.new()
				lb_bm.size = size_3d(Vector2(3.5, 4.2), 3.5)
				lock_badge.mesh = lb_bm
				lock_badge.material_override = m_gold
				lock_badge.position = Vector3((leaf_w - 4.0) * WORLD_SCALE, (leaf_h * 0.48 * WORLD_SCALE) / _cos_p, 0.0)
				pivot.add_child(lock_badge)
				_door_nodes_3d.append({"entry": d_entry, "pivot": pivot, "lock_badge": lock_badge, "door_south": door_south})
				break

		# 4. Ventana 3D con postigos sincronizada con `vm.building_windows`
		for w_entry in vm.building_windows:
			if str(w_entry.get("building_id", "")) == b_id:
				var w_pos: Vector2 = w_entry.get("pos", Vector2.ZERO)
				var pane: Node3D = null
				if not _is_headless:
					pane = _make_texture_panel(13.0, 12.0, wall_t + 2.4, _panel_mat("win_day", "town_textures/window_square_divided.png", false))
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

		# 6. Altillo / Primer Piso (+1) 3D (visible cuando estás en nivel +1 o cerca)
		var loft_root := Node3D.new()
		loft_root.name = "Loft3D_" + b_id
		loft_root.visible = false
		b_root.add_child(loft_root)
		_current_building_floor = 1
		if b_id == "building_tavern":
			_build_tavern_floor_1_3d(loft_root, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)
		else:
			var loft_y: float = center.y + (-half.y * 0.42 if door_south else half.y * 0.42)
			_add_box_2d(loft_root, Vector2(center.x, loft_y), Vector2(sz.x - 10.0, sz.y * 0.42), wall_h - 3.0, 2.0, m_wood)
			_add_box_2d(loft_root, Vector2(center.x, loft_y + (sz.y * 0.20 if door_south else -sz.y * 0.20)), Vector2(sz.x - 12.0, 2.5), wall_h - 1.0, 6.0, m_dark_wood)
			_add_model_2d(loft_root, "props/Chest_Wood.gltf", Vector2(center.x - sz.x * 0.22, loft_y), wall_h - 1.0, Vector2(12.0, 8.0), 6.5)
		_current_building_id = ""
		_current_building_floor = 0

		# 7. Tejado a dos aguas con alero (se retira en modo Cutaway). Cada edificio varía según su id:
		#    orientación de la cumbrera, altura, ala más baja en los edificios anchos, porche sobre la puerta y chimenea.
		var roof_cap := Node3D.new()
		roof_cap.name = "RoofCap_" + b_id
		b_root.add_child(roof_cap)
		# B7: Forjado/techo de tablas bajo la cubierta para que en 1.ª persona se vea el techo cerrado desde dentro
		_add_box_2d(roof_cap, center, sz - Vector2(2.0, 2.0), wall_h - 0.4, 2.2, m_wood)
		var hv: int = absi(b_id.hash())
		var ov: float = 6.0
		var short_side: float = minf(sz.x, sz.y)
		var rh: float = clampf(short_side * (0.40 + float(hv % 5) * 0.04), 16.0, 46.0)
		var ridge_x: bool = sz.x >= sz.y
		if absf(sz.x - sz.y) < 12.0:
			ridge_x = (hv % 2) == 0
		var roof_base_h: float = wall_h + 2.2
		if sz.x > 118.0 and not (b_id in ["building_church"]):
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
			_add_box_2d(roof_cap, Vector2(center.x, closed_y), Vector2(sz.x, wall_t), 11.0, wall_h - 9.0, m_wall)
			_add_box_2d(roof_cap, Vector2(center.x, rect.end.y), Vector2(sz.x + 2.0, 3.0), wall_h, 2.5, m_trim)
		else:
			_add_box_2d(b_root, Vector2(center.x, rect.end.y), Vector2(sz.x + 2.0, 3.0), wall_h, 2.5, m_trim)
		_add_box_2d(b_root, Vector2(center.x, rect.position.y), Vector2(sz.x + 2.0, 3.0), wall_h, 2.5, m_trim)
		# Porche sobre la puerta en tiendas y casas (tejadillo inclinado sobre dos postes)
		if (hv % 3) != 0 and not (b_id in ["building_church", "building_police", "building_hospital"]):
			var porch_dir: float = 1.0 if door_south else -1.0
			var porch_c := Vector2(door_pos.x, door_y + porch_dir * 9.0)
			_add_box_2d(b_root, porch_c, Vector2(door_w + 16.0, 18.0), wall_h * 0.70, 2.5, m_roof)
			for px in [-1.0, 1.0]:
				_add_box_2d(b_root, Vector2(door_pos.x + px * (door_w * 0.5 + 6.0), door_y + porch_dir * 16.0), Vector2(2.5, 2.5), 2.0, wall_h * 0.70 - 2.0, m_trim)
		# Chimenea sobre la cumbrera
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
			# Tabique entre Urgencias y Morgue Forense
			_add_box_2d(b_root, Vector2(704, 152), Vector2(56, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_box_2d(b_root, Vector2(786, 152), Vector2(56, 5.5), 2.0, wall_h * 0.85, m_wall)
			_build_bed_3d(b_root, vm._hospital_bed_pos, m_steel, _mat("hosp_sheet", Color(0.32, 0.72, 0.78), 0.8, 0.0), m_pillow)
			_add_model_2d(b_root, "props/Shelf_Small_Bottles.gltf", vm._hospital_bed_pos + Vector2(-18, -10), 2.0, Vector2(12.0, 6.0), 13.0)
			# 3 Camillas de acero inoxidable de la Morgue + cuerpos cubiertos
			for mp in vm._morgue_table_positions:
				_register_furniture_rect("MorgueTable", mp, Vector2(14.0, 22.0))
				_add_box_2d(b_root, mp, Vector2(14.0, 22.0), 2.0, 7.5, m_steel)
				var body_n := Node3D.new()
				body_n.visible = false
				b_root.add_child(body_n)
				_add_box_2d(body_n, mp, Vector2(9.0, 17.0), 9.5, 4.2, m_shroud)
				_add_box_2d(body_n, mp + Vector2(0, -6.0), Vector2(5.5, 5.5), 13.5, 3.0, m_shroud)
				_morgue_body_nodes_3d.append(body_n)
		"building_police":
			# Tabique de barrotes de acero del calabozo y puerta de reja en Vector2(902, 152)
			_add_model_2d(b_root, "graveyard/iron-fence.glb", Vector2(874, 152), 2.0, Vector2(36, 4.5), wall_h * 0.85)
			_add_model_2d(b_root, "graveyard/iron-fence.glb", Vector2(940, 152), 2.0, Vector2(52, 4.5), wall_h * 0.85)
			_jail_gate_pivot_3d = Node3D.new()
			_jail_gate_pivot_3d.position = to_3d(Vector2(892, 152), 2.0)
			b_root.add_child(_jail_gate_pivot_3d)
			var gate_mesh := MeshInstance3D.new()
			var gm_box := BoxMesh.new()
			gm_box.size = size_3d(Vector2(20.0, 3.0), wall_h * 0.75)
			gate_mesh.mesh = gm_box
			gate_mesh.material_override = m_iron
			gate_mesh.position = Vector3(10.0 * WORLD_SCALE, (wall_h * 0.375 * WORLD_SCALE) / _cos_p, 0.0)
			_jail_gate_pivot_3d.add_child(gate_mesh)
			# Camastro del calabozo, jaula y escritorio del comisario
			_build_bed_3d(b_root, vm._jail_cell_pos + Vector2(-14, 8), m_iron, m_dark_wood, m_pillow)
			_add_model_2d(b_root, "props/Cage_Small.gltf", vm._jail_cell_pos + Vector2(16, 6), 2.0, Vector2(9.0, 9.0), 10.0)
			_add_model_2d(b_root, "props/Workbench.gltf", vm._police_center + Vector2(18, -18), 2.0, Vector2(22, 12), 8.5)
			_add_model_2d(b_root, "props/WeaponStand.gltf", vm._police_center + Vector2(-24, -18), 2.0, Vector2(14, 7), 11.0)
			# §3b.3: Terminal de pantalla verde sobre el escritorio de la Comisaría
			_add_green_crt_terminal_3d(b_root, VillageCulture.POLICE_TERMINAL_POS, 10.5, true)
		"building_church":
			# Altar mayor con velas y bancos de madera 3D
			_add_model_2d(b_root, "graveyard/altar-stone.glb", vm._church_altar_pos, 2.0, Vector2(32.0, 14.0), 11.0)
			_add_model_2d(b_root, "props/CandleStick_Triple.gltf", vm._church_altar_pos + Vector2(-10, 0), 12.0, Vector2(5.0, 5.0), 6.0)
			_add_model_2d(b_root, "props/CandleStick_Triple.gltf", vm._church_altar_pos + Vector2(10, 0), 12.0, Vector2(5.0, 5.0), 6.0)
			for py in [-12.0, 4.0]:
				for px in [-26.0, 26.0]:
					_add_model_2d(b_root, "props/Bench.gltf", c + Vector2(px, py), 2.0, Vector2(26.0, 7.0), 6.5)
		"building_library":
			var m_dir: float = -1.0 if door_south else 1.0
			for sx in [-40.0, -14.0, 14.0, 40.0]:
				_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(sx, 34.0 * m_dir), 2.0, Vector2(22.0, 8.0), 22.0)
			_add_model_2d(b_root, "props/Table_Large.gltf", VillageCulture.reading_spot(), 2.0, Vector2(22.0, 13.0), 7.5)
			_add_model_2d(b_root, "props/BookStand.gltf", VillageCulture.reading_spot() + Vector2(-19, -8), 2.0, Vector2(8.0, 8.0), 11.0)
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
			_add_box_2d(b_root, c + Vector2(-42, 4), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_box_2d(b_root, c + Vector2(42, 4), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_model_2d(b_root, "props/Workbench.gltf", c + Vector2(0, -10), 2.0, Vector2(24.0, 10.5), 8.5)
			_add_model_2d(b_root, "props/Cauldron.gltf", c + Vector2(-24, -14), 2.0, Vector2(11.0, 11.0), 9.0)
			_add_model_2d(b_root, "props/Shelf_Small_Bottles.gltf", c + Vector2(24, -16), 2.0, Vector2(14.0, 6.0), 13.0)
			_build_bed_3d(b_root, c + Vector2(-36, 26), m_wood, m_bed, m_pillow)
			_build_bed_3d(b_root, c + Vector2(36, 26), m_wood, m_bed, m_pillow)
			_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, 24), 2.0, Vector2(18.0, 12.0), 7.0)
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
	var ih0: float = 30.4
	var m_felt := _mat("tavern_green_felt", Color(0.12, 0.52, 0.28), 0.82, 0.0)
	var m_carpet := _mat("tavern_casino_carpet", Color(0.48, 0.12, 0.14), 0.92, 0.0)
	var m_hall_rug := _mat("tavern_hall_rug", Color(0.56, 0.24, 0.16), 0.90, 0.0)
	var m_tile := _mat("tavern_kitchen_tile", Color(0.76, 0.70, 0.62), 0.75, 0.0, Color.BLACK, 0.0, "town_textures/floor_tiles_sand_small.png")
	var m_stone := _mat("tavern_hearth_stone", Color(0.52, 0.48, 0.44), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png")
	var m_stove := _mat("tavern_stove_iron", Color(0.16, 0.16, 0.18), 0.48, 0.72)
	var m_ember := _mat("tavern_ember", Color(1.0, 0.42, 0.12), 0.35, 0.0, Color(1.0, 0.38, 0.08), 2.4)
	var m_plate := _mat("tavern_plate", Color(0.92, 0.90, 0.84), 0.45, 0.05)
	var m_chip_red := _mat("poker_chip_red", Color(0.84, 0.18, 0.18), 0.55, 0.1)
	var m_chip_blue := _mat("poker_chip_blue", Color(0.18, 0.38, 0.82), 0.55, 0.1)

	# 1. Tabiques interiores de Planta 0 (con los mismos huecos de paso que en VillageTavern.OPENINGS_FLOOR_0)
	var x0: float = T.RECT.position.x
	var x1: float = T.RECT.end.x
	var h_gaps: Array[float] = [432.0, 534.0]
	var cur_x: float = x0
	for gx in h_gaps:
		var a: float = gx - T.GAP * 0.5
		if a - cur_x > 2.0:
			_add_box_2d(b_root, Vector2((cur_x + a) * 0.5, T.MID_WALL_Y), Vector2(a - cur_x, 5.5), 2.0, ih0, m_wall)
		_add_box_2d(b_root, Vector2(gx, T.MID_WALL_Y), Vector2(T.GAP + 4.0, 5.5), 2.0 + ih0 * 0.78, ih0 * 0.22, m_trim)
		cur_x = gx + T.GAP * 0.5
	if 558.0 - cur_x > 2.0:
		_add_box_2d(b_root, Vector2((cur_x + 558.0) * 0.5, T.MID_WALL_Y), Vector2(558.0 - cur_x, 5.5), 2.0, ih0, m_wall)
	_add_box_2d(b_root, Vector2(558.0, -223.0), Vector2(4.8, 42.0), 2.0, ih0, m_wall)

	var y0: float = T.RECT.position.y
	var y1: float = T.RECT.end.y
	var v_gaps: Array[float] = [-276.0, -182.0]
	var cur_y: float = y0
	for gy in v_gaps:
		var ay: float = gy - T.GAP * 0.5
		if ay - cur_y > 2.0:
			_add_box_2d(b_root, Vector2(T.EAST_WING_X, (cur_y + ay) * 0.5), Vector2(5.5, ay - cur_y), 2.0, ih0, m_wall)
		_add_box_2d(b_root, Vector2(T.EAST_WING_X, gy), Vector2(5.5, T.GAP + 4.0), 2.0 + ih0 * 0.78, ih0 * 0.22, m_trim)
		cur_y = gy + T.GAP * 0.5
	if y1 - cur_y > 2.0:
		_add_box_2d(b_root, Vector2(T.EAST_WING_X, (cur_y + y1) * 0.5), Vector2(5.5, y1 - cur_y), 2.0, ih0, m_wall)

	# 2. Alfombras y pavimentos diferenciados por sala en Planta 0
	_add_box_2d(b_root, T.ROOMS_FLOOR_0["barra_cocina"].get_center(), T.ROOMS_FLOOR_0["barra_cocina"].size - Vector2(8, 8), 2.5, 0.35, m_tile)
	_add_box_2d(b_root, T.ROOMS_FLOOR_0["casino"].get_center(), T.ROOMS_FLOOR_0["casino"].size - Vector2(10, 10), 2.5, 0.38, m_carpet)
	_add_box_2d(b_root, Vector2(368.0, -174.0), Vector2(168.0, 56.0), 2.5, 0.35, m_hall_rug)

	# 3. Gran Salón y Comedor: Hogar de piedra con brasas, 6 mesas con 12 sillas, platos, jarras y arañas de techo
	_register_furniture_rect("TavernFireplace", T.FIREPLACE_POS, Vector2(14.0, 32.0))
	_add_box_2d(b_root, T.FIREPLACE_POS, Vector2(14.0, 32.0), 2.0, 29.0, m_stone)
	_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(2.0, 0.0), Vector2(16.0, 36.0), 16.5, 2.2, m_dark_wood) # Repisa de roble
	_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(5.0, 0.0), Vector2(6.0, 20.0), 2.8, 5.5, m_ember)
	_add_model_2d(b_root, "props/Cauldron.gltf", T.FIREPLACE_POS + Vector2(4.5, 0.0), 6.0, Vector2(7.5, 7.5), 5.5)

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
	_add_box_2d(b_root, T.STOVE_POS, Vector2(21.0, 8.5), 12.0, 0.6, m_ember)
	_add_model_2d(b_root, "props/Cauldron.gltf", T.STOVE_POS + Vector2(-5.5, 0.0), 12.0, Vector2(8.0, 8.0), 6.0)
	_add_model_2d(b_root, "props/Pot_1.gltf", T.STOVE_POS + Vector2(6.5, 0.0), 12.0, Vector2(6.0, 6.0), 4.5)
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

