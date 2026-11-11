@tool
extends "res://scripts/visuals/WorldStageProps3D.gd"

## Edificios 3D: los fijos se cargan de su escena (mapa/edificios/<id>.tscn); las casas de recién llegados y lo que se
## levante en un solar se dibujan aquí a partir de su planta. También cofres, solares vacíos y obras.

const Partes = preload("res://scripts/visuals/PartesEdificio3D.gd")
const EdificioEditor = preload("res://mapa/edificio.gd")

## Colores, texturas y alturas de un edificio sin escena propia, según su clase (los que tienen escena ya los llevan dentro).
func _style_for_building(b_id: String) -> Dictionary:
	var wall_col := Color(0.82, 0.76, 0.64)
	var roof_col := Color(0.68, 0.32, 0.22)
	var floor_col := Color(0.56, 0.40, 0.25)
	var wall_tex := "town_textures/timber_square_clay.png"
	var roof_tex := "town_textures/roof_clay_red_center.png"
	var floor_tex := "town_textures/floor_wood_planks.png"
	var wall_h: float = 28.0
	if b_id == "building_candil":
		wall_col = Color(0.56, 0.38, 0.48)
		roof_col = Color(0.58, 0.22, 0.38)
		floor_col = Color(0.44, 0.24, 0.32)
	elif b_id == "building_townhouse":
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.84, 0.82, 0.78)
		roof_col = Color(0.26, 0.46, 0.38)
		floor_col = Color(0.56, 0.40, 0.24)
		wall_tex = "town_textures/wall_brick_sand_center.png"
		wall_h = 32.0
	elif b_id == "building_tinker":
		roof_tex = "town_textures/roof_clay_grey_center.png"
		floor_tex = "town_textures/floor_stone_pattern.png"
		wall_col = Color(0.60, 0.58, 0.56)
		roof_col = Color(0.36, 0.34, 0.34)
		floor_col = Color(0.46, 0.44, 0.42)
		wall_tex = "town_textures/wall_stone.png"
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
	return {
		"wall_mat": _mat("wall_" + b_id, wall_col, 0.88, 0.04, Color.BLACK, 0.0, wall_tex, "", 0.70),
		"roof_mat": _mat("roof_" + b_id, roof_col, 0.80, 0.06, Color.BLACK, 0.0, roof_tex, "", 0.75),
		"floor_mat": _mat("floor_" + b_id, floor_col, 0.88, 0.02, Color.BLACK, 0.0, floor_tex, "", 0.85),
		"trim_mat": _mat("trim_" + b_id, Color(0.42, 0.28, 0.16), 0.84, 0.05, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.85),
		"wall_h": wall_h,
	}

func rebuild_buildings_3d() -> void:
	_clear_children(buildings_root_3d)
	_building_records_3d.clear()
	_building_furniture_rects.clear()
	_edificios_de_escena.clear()
	_muebles_claves.clear()
	muebles_grabados.clear()
	_current_building_id = ""
	_current_building_floor = 0
	_door_nodes_3d.clear()
	_puertas_interiores.limpiar()
	_window_nodes_3d.clear()
	_chest_nodes_3d.clear()
	_morgue_body_nodes_3d.clear()
	_restaurant_night_nodes.clear()
	_jail_gate_pivot_3d = null
	if vm == null:
		return
	for b: Dictionary in vm.building_footprints:
		var propia: PackedScene = null if edificios_por_codigo else EdificioEditor.escena(str(b.get("id", "")))
		if propia != null:
			_poner_edificio_de_escena(b, propia)
		else:
			_construir_edificio_por_codigo(b)
	_poner_cofres_3d()
	check_furniture_overlaps(true)


## Edificio sin escena propia (casas de recién llegados y lo que se levante en un solar durante la partida): se dibuja
## a partir de su planta. Se construye donde estaba y sin girar, y luego se lleva entero a su sitio.
func _construir_edificio_por_codigo(b: Dictionary) -> void:
	var b_id: String = str(b.get("id", ""))
	var d_edif: Vector2 = EdificioEditor.desplazamiento(b_id)
	var g_edif: float = float(b.get("giro", 0.0))
	var rect_real: Rect2 = b["rect"]
	var rect: Rect2 = rect_real
	var door_pos: Vector2 = b["door_pos"]
	rect.position -= d_edif
	door_pos -= d_edif
	if g_edif > 0.5:
		rect = b["rect_orig"]
		door_pos = b["door_pos_orig"]
	var door_south: bool = bool(b.get("door_south_orig", b["door_south"]))
	var style: Dictionary = _style_for_building(b_id)
	# Altura de muro algo distinta en cada edificio (+0..10 px)
	var wall_h: float = float(style["wall_h"]) + 4.0 + float(absi(b_id.hash()) % 6) * 2.0

	var b_root := Node3D.new()
	b_root.name = "B3D_" + b_id
	buildings_root_3d.add_child(b_root)
	b_root.position = Mapa3D.a_3d(d_edif)
	if g_edif > 0.5:
		var piv := Mapa3D.a_3d(rect.get_center())
		var giro_b := Basis(Vector3.UP, deg_to_rad(g_edif))
		b_root.transform = Transform3D(giro_b, b_root.position + piv - giro_b * piv)

	# Estructura fija de cada edificio (docs/PLAN_MUNDO_DESDE_EDITOR.md, regla 1): Muros, Interior, PisoAlto y Tejado
	var muros := _grupo_3d(b_root, Partes.MUROS)
	var interior := _grupo_3d(b_root, Partes.INTERIOR)
	_grupo_3d(b_root, Partes.PISO_ALTO).visible = false
	var tejado := _grupo_3d(b_root, Partes.TEJADO)
	var door_w: float = float(_entrada_del_edificio(vm.building_doors, b_id).get("width", PUERTA_ANCHO_PX))
	_muros_3d(muros, tejado, rect, door_pos, door_w, door_south, wall_h, style)
	_puerta_y_ventana_3d(muros, b_id, rect, door_pos, door_w, wall_h, d_edif, g_edif, rect_real)
	_current_building_id = b_id
	_muebles_activos = true
	_populate_building_interior_3d(interior, b_id, rect, door_south, wall_h, style["wall_mat"])
	_muebles_activos = false
	_current_building_id = ""
	_tejado_3d(muros, tejado, b_id, rect, door_pos, door_w, door_south, wall_h, style)
	_registrar_edificio_3d(b_root, b_id, rect_real, door_south)
	if juntar_edificios:
		_juntar_edificio(b_root)


const MURO_GROSOR_PX: float = 6.5
const PUERTA_ANCHO_PX: float = 40.0
const MURO_REBAJADO_PX: float = 9.0 ## lo que queda del muro del fondo al retirar el tejado (vista desde arriba)

## Zócalo, suelo, cuatro muros con el hueco de la puerta, pilares de esquina, jambas y dintel.
func _muros_3d(muros: Node3D, tejado: Node3D, rect: Rect2, door_pos: Vector2, door_w: float, door_south: bool, wall_h: float, style: Dictionary) -> void:
	var center: Vector2 = rect.get_center()
	var sz: Vector2 = rect.size
	var wall_t: float = MURO_GROSOR_PX
	var m_wall: Material = style["wall_mat"]
	var m_trim: Material = style["trim_mat"]
	var m_plinth := _mat("building_plinth_stone", Color(0.58, 0.56, 0.52), 0.90, 0.03, Color.BLACK, 0.0, "town_textures/wall_stone.png", "", 0.70)
	# Zócalo de piedra enterrado (cimentación contra microdesniveles), zócalo exterior y losa de suelo
	_add_box_2d(muros, center, sz + Vector2(6, 6), -2.5, 2.5, m_plinth)
	_add_box_2d(muros, center, sz + Vector2(4, 4), 0.0, 1.5, m_trim)
	_add_box_2d(muros, center, sz - Vector2(2, 2), 1.5, 1.0, style["floor_mat"])
	# Muros laterales y pilares de esquina
	_add_box_2d(muros, Vector2(rect.position.x, center.y), Vector2(wall_t, sz.y), 2.0, wall_h, m_wall)
	_add_box_2d(muros, Vector2(rect.end.x, center.y), Vector2(wall_t, sz.y), 2.0, wall_h, m_wall)
	for esquina: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		_add_box_2d(muros, esquina, Vector2(wall_t + 2.0, wall_t + 2.0), 2.0, wall_h + 1.0, m_trim)
	# Muro del fondo (el opuesto a la puerta). Si es el del sur, tapa la vista desde arriba: su parte alta va con el tejado
	var closed_y: float = rect.position.y if door_south else rect.end.y
	var fondo_tam := Vector2(maxf(8.0, sz.x - wall_t), wall_t)
	if door_south:
		_add_box_2d(muros, Vector2(center.x, closed_y), fondo_tam, 2.0, wall_h, m_wall)
	else:
		_add_box_2d(muros, Vector2(center.x, closed_y), fondo_tam, 2.0, MURO_REBAJADO_PX, m_wall)
		_add_box_2d(tejado, Vector2(center.x, closed_y), fondo_tam, 2.0 + MURO_REBAJADO_PX + 0.05, wall_h - MURO_REBAJADO_PX - 0.05, m_wall)
	# Fachada con el hueco de la puerta, jambas y dintel
	var door_left_x: float = door_pos.x - door_w * 0.5
	var door_right_x: float = door_pos.x + door_w * 0.5
	var left_w: float = maxf(6.0, door_left_x - (rect.position.x + wall_t * 0.5))
	var right_w: float = maxf(6.0, (rect.end.x - wall_t * 0.5) - door_right_x)
	_add_box_2d(muros, Vector2(rect.position.x + wall_t * 0.5 + left_w * 0.5, door_pos.y), Vector2(left_w, wall_t), 2.0, wall_h, m_wall)
	_add_box_2d(muros, Vector2(rect.end.x - wall_t * 0.5 - right_w * 0.5, door_pos.y), Vector2(right_w, wall_t), 2.0, wall_h, m_wall)
	_add_box_2d(muros, Vector2(door_left_x, door_pos.y), Vector2(3.5, wall_t + 2.0), 2.0, wall_h, m_trim)
	_add_box_2d(muros, Vector2(door_right_x, door_pos.y), Vector2(3.5, wall_t + 2.0), 2.0, wall_h, m_trim)
	_add_box_2d(muros, Vector2(door_pos.x, door_pos.y), Vector2(door_w + 4.0, wall_t + 1.5), 2.0 + wall_h * 0.72, wall_h * 0.28, m_trim)


## Puerta abatible (con su chapa de candado) y ventana con postigo, etiquetadas para que el juego las mueva.
func _puerta_y_ventana_3d(muros: Node3D, b_id: String, rect: Rect2, door_pos: Vector2, door_w: float, wall_h: float, d_edif: Vector2, g_edif: float, rect_real: Rect2) -> void:
	var m_dark_wood := _mat("prop_dark_wood", Color(0.32, 0.20, 0.11), 0.88, 0.02)
	var m_iron := _mat("wrought_iron", Color(0.22, 0.24, 0.28), 0.45, 0.75)
	if not _entrada_del_edificio(vm.building_doors, b_id).is_empty():
		var pivot := _grupo_3d(muros, "Puerta")
		pivot.set_meta(Partes.ROL, Partes.PUERTA)
		pivot.position = to_3d(Vector2(door_pos.x - door_w * 0.5 + 2.0, door_pos.y), 2.0)
		var leaf_w: float = maxf(18.0, door_w - 4.0)
		var leaf_h: float = wall_h * 0.70
		if not _is_headless:
			_build_door_leaf_3d(pivot, leaf_w, leaf_h)
		var lock_badge := MeshInstance3D.new()
		var lb_bm := BoxMesh.new()
		lb_bm.size = size_3d(Vector2(2.6, 3.2), 2.8)
		lock_badge.mesh = lb_bm
		lock_badge.material_override = m_iron
		lock_badge.position = Vector3((leaf_w - 4.0) * WORLD_SCALE, Mapa3D.alto_a_3d(leaf_h * 0.48), 0.0)
		lock_badge.set_meta(Partes.ROL, Partes.CANDADO)
		pivot.add_child(lock_badge)
	var ventana: Dictionary = _entrada_del_edificio(vm.building_windows, b_id)
	if ventana.is_empty():
		return
	# La ventana viene en el sitio nuevo; aquí hace falta donde estaba, porque el edificio se traslada entero
	var w_pos: Vector2 = (ventana.get("pos", Vector2.ZERO) as Vector2) - d_edif
	if g_edif > 0.5:
		w_pos = rect.get_center() + AnclasScript.matriz(g_edif).affine_inverse().basis_xform((ventana.get("pos", Vector2.ZERO) as Vector2) - rect_real.get_center())
	var wall_t: float = MURO_GROSOR_PX
	var pane: Node3D = null
	if _is_headless:
		pane = _add_box_2d(muros, w_pos, Vector2(11.0, wall_t + 2.4), 12.0, 8.0, _mat("win_glass", Color(0.56, 0.82, 0.96, 0.75), 0.15, 0.25))
	else:
		pane = _make_texture_panel(13.0, 12.0, wall_t + 2.4, _panel_mat("win_" + b_id, "town_textures/window_square_divided.png", false))
		pane.position = to_3d(w_pos, 10.0 + 6.0)
		muros.add_child(pane)
	pane.set_meta(Partes.ROL, Partes.CRISTAL)
	_add_box_2d(muros, w_pos, Vector2(12.0, wall_t + 2.8), 12.0, 8.2, m_dark_wood).set_meta(Partes.ROL, Partes.POSTIGO)


## Techo de tablas, tejado a dos aguas (con un ala más baja en los edificios anchos), remates, porche y chimenea.
## La orientación de la cumbrera, la altura y el porche varían con el nombre del edificio, para que no sean todos iguales.
func _tejado_3d(muros: Node3D, tejado: Node3D, b_id: String, rect: Rect2, door_pos: Vector2, door_w: float, door_south: bool, wall_h: float, style: Dictionary) -> void:
	var center: Vector2 = rect.get_center()
	var sz: Vector2 = rect.size
	var m_roof: Material = style["roof_mat"]
	var m_trim: Material = style["trim_mat"]
	# Techo de tablas justo sobre los muros (+0,08 para que no parpadee contra ellos)
	_add_box_2d(tejado, center, sz - Vector2(4.0, 4.0), 2.0 + wall_h + 0.08, 2.1, _mat("prop_wood", Color(0.45, 0.29, 0.16), 0.85, 0.02))
	var hv: int = absi(b_id.hash())
	var ov: float = 6.0
	var rh: float = clampf(minf(sz.x, sz.y) * (0.40 + float(hv % 5) * 0.04), 16.0, 46.0)
	var ridge_x: bool = sz.x >= sz.y
	if absf(sz.x - sz.y) < 12.0:
		ridge_x = (hv % 2) == 0
	var roof_base_h: float = 2.0 + wall_h + 2.25
	if sz.x > 118.0:
		# Cuerpo principal + ala más baja (rompe la caja: silueta en L vista desde arriba)
		var main_w: float = sz.x * 0.60
		var wing_w: float = sz.x - main_w
		var main_left: bool = (hv % 2) == 0
		var main_cx: float = rect.position.x + (main_w * 0.5 if main_left else wing_w + main_w * 0.5)
		var wing_cx: float = rect.position.x + (main_w + wing_w * 0.5 if main_left else wing_w * 0.5)
		_add_prism_2d(tejado, Vector2(main_cx, center.y), Vector2(main_w + ov * 2.0, sz.y + ov * 2.0), roof_base_h, rh, m_roof, false)
		_add_prism_2d(tejado, Vector2(wing_cx, center.y), Vector2(wing_w + ov, sz.y * 0.86 + ov), roof_base_h, rh * 0.62, m_roof, true)
	else:
		_add_prism_2d(tejado, center, sz + Vector2(ov * 2.0, ov * 2.0), roof_base_h, rh, m_roof, ridge_x)
	# Remates de madera bajo el alero (el del sur se retira con el tejado si tapa la vista)
	var remate_sur: Node3D = muros if door_south else tejado
	_add_box_2d(remate_sur, Vector2(center.x, rect.end.y), Vector2(sz.x + 2.0, 3.0), 2.0 + wall_h + 0.08, 2.5, m_trim)
	_add_box_2d(muros, Vector2(center.x, rect.position.y), Vector2(sz.x + 2.0, 3.0), 2.0 + wall_h + 0.08, 2.5, m_trim)
	# Porche sobre la puerta (tejadillo sobre dos postes) en dos de cada tres edificios
	if (hv % 3) != 0:
		var porch_dir: float = 1.0 if door_south else -1.0
		_add_box_2d(muros, Vector2(door_pos.x, door_pos.y + porch_dir * 9.0), Vector2(door_w + 16.0, 18.0), wall_h * 0.70, 2.5, m_roof)
		for lado: float in [-1.0, 1.0]:
			_add_box_2d(muros, Vector2(door_pos.x + lado * (door_w * 0.5 + 6.0), door_pos.y + porch_dir * 16.0), Vector2(2.5, 2.5), 2.0, wall_h * 0.70 - 2.0, m_trim)
	# Chimenea sobre la cumbrera
	var ch_off := Vector2(sz.x * 0.5 * (0.30 if (hv % 2) == 0 else -0.30), -sz.y * 0.5 * 0.15)
	_add_model_2d(tejado, "fantasy_town/chimney.glb", center + ch_off, roof_base_h + rh * 0.35, Vector2(9.0, 9.0), rh * 0.9)


## Cofres de las casas (lista del pueblo): modelo y tapa, que se esconde el día que el cofre se saquea.
func _poner_cofres_3d() -> void:
	var m_gold := _mat("brass_gold", Color(0.85, 0.68, 0.24), 0.35, 0.82)
	for ch: Dictionary in vm.house_chests:
		var c_pos: Vector2 = ch.get("pos", Vector2.ZERO)
		var is_tavern_upper: bool = str(ch.get("family_id", "")) == VillageTavern.FAMILY_ID
		var base_h: float = VillageTavern.FLOOR_1_H if is_tavern_upper else 2.0
		var parent_node: Node3D = buildings_root_3d
		_current_building_id = ""
		_current_building_floor = 1 if is_tavern_upper else 0
		for rec: Dictionary in _building_records_3d:
			if not (rec["rect"] as Rect2).grow(8.0).has_point(c_pos):
				continue
			_current_building_id = str(rec["id"])
			if is_tavern_upper and is_instance_valid(rec.get("loft_root")):
				parent_node = rec["loft_root"]
			break
		var ch_root := Node3D.new()
		ch_root.set_meta(Partes.ROL, Partes.COFRE)
		parent_node.add_child(ch_root)
		ch_root.global_transform = Transform3D.IDENTITY # el cofre viene en coordenadas del mundo, cuelgue de quien cuelgue
		_add_model_2d(ch_root, "props/Chest_Wood.gltf", c_pos, base_h, Vector2(12.0, 8.5), 7.5)
		var lid := _add_box_2d(ch_root, c_pos, Vector2(11.4, 7.8), base_h + 5.5, 1.8, m_gold)
		_chest_nodes_3d.append({"entry": ch, "lid": lid})
	_current_building_id = ""
	_current_building_floor = 0


## Edificio con escena propia (mapa/edificios/<id>.tscn): se cuelga tal cual, en el sitio y con el giro de su planta.
func _poner_edificio_de_escena(b: Dictionary, propia: PackedScene) -> void:
	var b_id: String = str(b["id"])
	var rect: Rect2 = b["rect"]
	var raiz: Node3D = propia.instantiate()
	raiz.name = "B3D_" + b_id
	buildings_root_3d.add_child(raiz)
	raiz.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(b.get("giro", 0.0)))), to_3d(rect.get_center()))
	_edificios_de_escena[b_id] = true
	_poner_muebles_de_escena(raiz, b_id)
	_registrar_edificio_3d(raiz, b_id, rect, bool(b.get("door_south_orig", b["door_south"])))


## Dibuja el modelo de cada pieza del grupo «Muebles» (mapa/mueble.gd) donde la dejó el usuario y los junta en una
## malla. Los de la planta alta pasan al grupo «PisoAlto», para esconderse con él.
func _poner_muebles_de_escena(raiz: Node3D, b_id: String) -> void:
	var muebles: Node3D = raiz.get_node_or_null(Partes.MUEBLES)
	if muebles == null:
		return
	var altos: Node3D = _grupo_3d(raiz.get_node(Partes.PISO_ALTO) as Node3D, Partes.MUEBLES)
	_current_building_id = b_id
	for pieza: Node in muebles.get_children():
		var mueble := pieza as Node3D
		var modelo: String = String(mueble.get("modelo"))
		var tam3: Vector3 = mueble.get("tam3")
		_current_building_floor = int(mueble.get("piso"))
		if _current_building_floor > 0:
			mueble.reparent(altos, false)
		_register_furniture_rect(modelo.get_file().get_basename(), Mapa3D.a_mapa(mueble.global_position), Mapa3D.a_mapa(tam3), mueble.global_rotation_degrees.y)
		if _is_headless or not AssetLib.has_curated_assets():
			continue
		var dibujo: Node3D = AssetLib.instantiate_model(modelo, tam3, float(mueble.get("alto3")), true, true)
		if dibujo != null:
			mueble.add_child(dibujo)
	_current_building_id = ""
	_current_building_floor = 0
	if not _is_headless:
		_merge_meshes_under(muebles, {})
		_merge_meshes_under(altos, {})


## Apunta un edificio ya montado (por código o desde su escena) y sus partes móviles, que reconoce por su etiqueta.
func _registrar_edificio_3d(raiz: Node3D, b_id: String, rect_real: Rect2, door_south: bool) -> void:
	_building_records_3d.append({
		"id": b_id,
		"rect": rect_real, # dónde está de verdad (para abrir el tejado al entrar)
		"root": raiz,
		"roof_cap": raiz.get_node_or_null(Partes.TEJADO),
		"loft_root": raiz.get_node_or_null(Partes.PISO_ALTO),
	})
	for parte: Node in Partes.con_rol(raiz):
		match String(parte.get_meta(Partes.ROL)):
			Partes.PUERTA:
				var entrada: Dictionary = _entrada_del_edificio(vm.building_doors, b_id)
				if not entrada.is_empty():
					_door_nodes_3d.append({"entry": entrada, "pivot": parte, "lock_badge": Partes.hijo_con_rol(parte, Partes.CANDADO), "door_south": door_south})
			Partes.POSTIGO:
				var ventana: Dictionary = _entrada_del_edificio(vm.building_windows, b_id)
				if not ventana.is_empty():
					_window_nodes_3d.append({"entry": ventana, "shutter": parte})
			Partes.LUZ_NOCHE:
				_restaurant_night_nodes.append(parte)
			Partes.CUERPO_MORGUE:
				_morgue_body_nodes_3d.append(parte as Node3D)
			Partes.REJA_CELDA:
				_jail_gate_pivot_3d = parte as Node3D
				_reja_celda_cerrada = _jail_gate_pivot_3d.position
			Partes.BOMBILLA_CUADRO:
				_grid_panel_bulb_3d = parte as MeshInstance3D
			Partes.PUERTA_CUARTO:
				var hueco: Vector3 = raiz.global_transform * (parte.get_meta(Partes.HUECO) as Vector3)
				_puertas_interiores.anadir(parte as Node3D, Mapa3D.a_mapa(hueco), int(parte.get_meta(Partes.NIVEL, 0)))


## La puerta o la ventana (de las listas del pueblo) que pertenece a ese edificio; {} si no tiene.
func _entrada_del_edificio(lista: Array, b_id: String) -> Dictionary:
	for entrada: Dictionary in lista:
		if str(entrada.get("building_id", "")) == b_id:
			return entrada
	return {}


## Rendimiento: junta en una sola malla por material las piezas quietas de cada grupo del edificio (muros, interior,
## piso alto y tejado, cada uno por su lado porque se esconden por separado). Lo etiquetado se sigue moviendo aparte.
func _juntar_edificio(raiz: Node3D) -> void:
	if _is_headless:
		return
	for grupo: Node in raiz.get_children():
		if grupo is Node3D:
			_merge_meshes_under(grupo as Node3D, {})


## Nodo vacío con nombre fijo, hijo de `padre` (los grupos de un edificio).
func _grupo_3d(padre: Node3D, nombre: String) -> Node3D:
	var grupo := Node3D.new()
	grupo.name = nombre
	padre.add_child(grupo)
	return grupo

func _merge_meshes_under(root: Node3D, excl: Dictionary) -> void:
	var found: Array = []
	_collect_merge_meshes(root, root, excl, found)
	_merge_mesh_list(root, found)

## Junta en `root` las mallas de `found` (una malla por sombra, una superficie por material). Las originales dejan de dibujarse.
func _merge_mesh_list(root: Node3D, found: Array) -> void:
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
		if excl.has(c) or c.has_meta(Partes.ROL): # lo etiquetado (puertas, postigos, luces de noche…) se mueve: no se junta
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

## Muebles de una casa sin escena propia: tienda (mostrador), tienda con vivienda, casa, o sala cívica sencilla.
func _populate_building_interior_3d(b_root: Node3D, b_id: String, rect: Rect2, door_south: bool, wall_h: float, m_wall: Material) -> void:
	var c: Vector2 = rect.get_center()
	var m_wood := _mat("prop_wood", Color(0.45, 0.29, 0.16), 0.85, 0.02)
	var m_bed := _mat("bed_linen", Color(0.84, 0.28, 0.24), 0.85, 0.0)
	var m_pillow := _mat("bed_pillow", Color(0.94, 0.92, 0.86), 0.85, 0.0)
	var fondo: float = -1.0 if door_south else 1.0 # hacia el muro opuesto a la puerta
	if b_id.begins_with("shop_"):
		_add_model_2d(b_root, "props/Workbench.gltf", c + Vector2(0, 14.0 * fondo), 2.0, Vector2(24.0, 10.5), 8.5)
		_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-28, 14.0 * fondo), 2.0, Vector2(14.0, 10.0), 13.0)
		_add_model_2d(b_root, "props/Barrel_Apples.gltf", c + Vector2(22, 14.0 * fondo), 2.0, Vector2(9.0, 9.0), 9.5)
	elif b_id.begins_with("mixed_"):
		_add_box_2d(b_root, c + Vector2(-42, 4.0 * fondo), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
		_add_box_2d(b_root, c + Vector2(42, 4.0 * fondo), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
		_add_model_2d(b_root, "props/Workbench.gltf", c + Vector2(0, -10.0 * fondo), 2.0, Vector2(24.0, 10.5), 8.5)
		_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-26, -16.0 * fondo), 2.0, Vector2(14.0, 9.0), 13.0)
		_build_bed_3d(b_root, c + Vector2(-36, 26.0 * fondo), m_wood, m_bed, m_pillow)
		_build_bed_3d(b_root, c + Vector2(36, 26.0 * fondo), m_wood, m_bed, m_pillow)
		_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, 24.0 * fondo), 2.0, Vector2(18.0, 12.0), 7.0)
	elif b_id.begins_with("house_") or b_id.begins_with("player_house_"):
		var bed_dx: float = 26.0 if rect.size.x < 96.0 else 30.0
		var bed_dy: float = (12.0 if rect.size.y < 70.0 else 18.0) * fondo
		_build_bed_3d(b_root, c + Vector2(-bed_dx, bed_dy), m_wood, m_bed, m_pillow)
		if not b_id.begins_with("player_house_"):
			_build_bed_3d(b_root, c + Vector2(bed_dx, bed_dy), m_wood, m_bed, m_pillow)
		var tbl_p: Vector2 = c + Vector2(2.0, -2.0 * fondo)
		var ch_p: Vector2 = c + Vector2(-12.0, -2.0 * fondo)
		_add_model_2d(b_root, "props/Table_Large.gltf", tbl_p, 2.0, Vector2(17.0, 11.0), 7.0)
		_add_model_2d(b_root, "props/Chair_1.gltf", ch_p, 2.0, Vector2(6.0, 6.0), 8.5, _chair_rot_y_towards(ch_p, tbl_p))
		_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(bed_dx, -16.0 * fondo), 2.0, Vector2(14.0, 6.0), 16.0)
	else:
		_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, 10.0 * fondo), 2.0, Vector2(24.0, 12.0), 7.5)
		_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-32, -12.0 * fondo), 2.0, Vector2(16.0, 9.0), 13.0)
		_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(32, -12.0 * fondo), 2.0, Vector2(16.0, 9.0), 15.0)

var _restaurant_night_nodes: Array = [] ## luces y bombillas que se encienden al caer la tarde (terraza de la casa de comidas)

const CAMA_VIEJA_PX: Vector2 = Vector2(15.0, 21.0) ## camas de las casas antiguas (0,8 × 1,2 m; se agrandan al rehacer cada edificio)
const CAMA_REAL_PX: Vector2 = Vector2(16.0, 32.0)  ## cama de adulto: 0,9 × 1,8 m

func _build_bed_3d(parent: Node3D, pos_2d: Vector2, m_frame: Material, m_blanket: Material, m_pillow: Material) -> void:
	_build_bed_3d_at_h(parent, pos_2d, 2.0, m_frame, m_blanket, m_pillow)

func _build_bed_3d_at_h(parent: Node3D, pos_2d: Vector2, base_h: float, m_frame: Material, m_blanket: Material, m_pillow: Material, tam: Vector2 = CAMA_VIEJA_PX) -> void:
	var alto: float = 8.5 * tam.x / CAMA_VIEJA_PX.x
	var bed := _add_model_2d(parent, "props/Bed_Twin1.gltf", pos_2d, base_h, tam, alto)
	if bed != null:
		return
	_add_box_2d(parent, pos_2d, tam, base_h, alto * 0.53, m_frame)
	_add_box_2d(parent, pos_2d + Vector2(0, tam.y * 0.1), tam - Vector2(1.5, 6.0), base_h + alto * 0.53, 2.0, m_blanket)
	_add_box_2d(parent, pos_2d + Vector2(0, -tam.y * 0.31), Vector2(tam.x - 4.0, 4.5), base_h + alto * 0.53, 2.2, m_pillow)

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
		var c: Vector2 = AnclasScript.mover(VillageLots.lot_def(id)["center"]) # mapa ×E
		var sz_l: Vector2 = (l_dict["size"] as Vector2) * Mapa3D.E
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

## Hoja de la puerta de la calle: un panel con textura de madera que gira sobre la bisagra.
func _build_door_leaf_3d(pivot: Node3D, leaf_w: float, leaf_h: float) -> void:
	var door_leaf := _make_texture_panel(leaf_w, leaf_h, 3.0, _panel_mat("door_wood", "town_textures/door_wood.png", false))
	door_leaf.position = Vector3(leaf_w * 0.5 * WORLD_SCALE, Mapa3D.alto_a_3d(leaf_h * 0.5), 0.0)
	pivot.add_child(door_leaf)
