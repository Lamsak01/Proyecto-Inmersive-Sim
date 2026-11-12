@tool
extends "res://scripts/systems/VillageManagerEconomy.gd"
class_name VillageManager
const ObjetoEditor = preload("res://mapa/objeto.gd")


func setup_village(target_entities_root: Node) -> void:
	entities_root = target_entities_root if target_entities_root else self
	var in_editor := Engine.is_editor_hint()
	set_process(not in_editor)
	set_process_unhandled_input(not in_editor)
	add_to_group("village_manager")
	if is_inside_tree() and GameManager and GameManager.has_method("is_demo_mode"):
		demo_mode = bool(GameManager.is_demo_mode())

	for arr in [building_footprints, _wall_occluder_rects, house_chests, building_doors, building_windows, streetlights, _authority_slots, morgue_active_corpses, buried_graves, _cemetery_grave_positions, blood_puddles, social_event_log]:
		arr.clear()
	active_sheriff_investigation.clear()
	shop_businesses.clear()
	vagrant_camp_nodes.clear()
	arrivals_today_count = 0
	_init_newcomer_generator_registries()
	social_director = SocialDirector.new(20261101)
	social_director.set_pair_metrics("elena", "valen", 78, 75, 80, 5, SocialDirector.STAGE_COUPLE)
	house_pantry = {
		"family_smith": 3, "family_butcher": 4, "family_carpenter": 3, "family_fishmonger": 4,
		"family_herbalist": 4, "family_hospital": 3, "family_police": 4, "family_tavern": 5
	}

	# Editor del mapa 3D (2026-11-10): objetos con uso que el usuario puede mover en mapa/Mundo3D.tscn → «Objetos»
	_notice_board_pos = ObjetoEditor.pos("tablon_plaza", _notice_board_pos)
	_well_pos = ObjetoEditor.pos("pozo_granja", _well_pos)
	_tavern_well_pos = ObjetoEditor.pos("pozo_taberna", _tavern_well_pos)
	_plaza_well_pos = ObjetoEditor.pos("pozo_plaza", _plaza_well_pos)
	VillageWorldBuilder._spawn_village_roads_and_plaza(self)
	VillageWorldBuilder._spawn_western_plains_and_frog_marsh(self)
	VillageWorldBuilder._spawn_tavern_and_rooms(self)
	VillageWorldBuilder._spawn_five_family_houses_and_trades(self)
	VillageWorldBuilder._spawn_hospital_and_morgue(self)
	VillageWorldBuilder._spawn_police_station_and_jail(self)
	VillageWorldBuilder._spawn_church_and_cemetery(self)
	VillageWorldBuilder._spawn_notice_board_in_plaza(self)
	VillageWorldBuilder._spawn_electric_streetlights(self)
	_spawn_unemployed_tavern_guests()
	_spawn_case1_clearing_corpse()
	VillageWorldBuilder._spawn_farm_well_and_compost(self)
	VillageTrades.setup_world(self) # V5: panadería y sastrería (puestos vacantes al empezar)
	VillageTown.state(self) # J3: arcas iniciales (1000) en partida nueva
	VillageCivic.setup_world(self) # V5b: ayuntamiento, albergue y El Candil
	VillageRestaurant.setup_world(self) # R1: Trattoria «Il Corvo» (puesto vacante)
	VillageRestaurant.build(self) # R1: edificio grande con comedor, terraza, cocina, cámara, bodega y reservado
	VillageFamilia.spawn_initial_boss(self) # R2/R4: Don Vittorio Corvo empieza como jefe de La Familia desde el Día 0
	VillageCulture.ensure_lots(self) # V5e: biblioteca y escuela
	VillageNobility.ensure_lots(self) # V6: mansión y casa grande
	VillageLots.build_world(self) # V4: calles y solares del borde, afueras y lomas
	VillagePlaces.build_world(self) # V5c: parque, bancos de la plaza y mirador del lago
	VillageUnderworld.build_sewers_world(self) # FIS3: trampillas en la calle y red de túneles conectada al sur
	VillageClub.build_world(self) # P6: trampilla tras la taberna y club de pelea en el sótano
	VillageHousing.sync_livestock(self) # FIS4: ganado vivo del rancho y animales propios del corral
	VillageHousing.sync_home_props(self) # FIS-P1 y P1: objetos físicos en tu casa y mostrador de tu tienda
	_spawn_domestic_pets()
	VillageSecrets.seed_founder_history(self) # B6: rasgos con variante, red de amistades/rencores y 2–3 secretos por fundador
	_sitios_cfg(load("res://mapa/anclas.gd")) # las fichas de oficio ya en el mundo ANTES de repartir oficios a los recién llegados (su cama y su puesto)
	if not in_editor and DisplayServer.get_name() != "headless":
		VillageMigration.seed_start_population(self) # Provisional: arranque con 40 vecinos para probar (no en las pruebas)
		VillageTavern.seed_initial_patrons(self) # Paso 3: clientes sentados en el salón y partida de póker en curso al abrir la taberna
	else:
		VillageTavern.seed_initial_patrons(self)
	_anclas_repaso_final()
	_prune_door_blocking_prop_colliders()
	if is_instance_valid(world_stage_3d):
		world_stage_3d.queue_free()
	world_stage_3d = WorldStage3DScript.new()
	add_child(world_stage_3d)
	world_stage_3d.setup_stage(self)

	if not in_editor:
		_setup_Interactive_modals_ui()
		if WorldClock:
			if not WorldClock.day_passed.is_connected(_on_day_passed):
				WorldClock.day_passed.connect(_on_day_passed)
			var qm_node = get_node_or_null("/root/QuestManager")
			if qm_node and not qm_node.quest_changed.is_connected(_on_quests_changed):
				qm_node.quest_changed.connect(_on_quests_changed)
			if not WorldClock.hour_passed.is_connected(_on_hour_passed):
				WorldClock.hour_passed.connect(_on_hour_passed)
			_apply_hourly_door_security_schedule(WorldClock.current_hour)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _police_confront_cooldown > 0.0:
		_police_confront_cooldown -= delta
	_needs_tick_acc += delta
	if _needs_tick_acc >= 1.0:
		_needs_tick_acc = 0.0
		VillageNeeds.tick(self) # E: terminar encargos al llegar
	VillageTavern.tick(self, delta) # Paso 3: escalera al 2.º piso, mesa de póker viva y ambiente de taberna
	VillageRestaurant.tick(self, delta) # Terraza y comedor de la trattoria con vecinos sentados de tarde y noche
	if not is_demo_mode():
		VillageClub.tick(self, delta) # P6: la pelea en curso en el club del sótano
	if social_director != null:
		social_director.tick(delta, self)
		_update_social_hangouts(delta)
		if not is_demo_mode():
			_update_live_fights(delta)

	if not is_instance_valid(_cached_player):
		_cached_player = get_tree().get_first_node_in_group("player") as Node2D
	var player := _cached_player
	var real_delta: float = delta / maxf(1.0, Engine.time_scale)
	check_elevation_exit(player)

	# Escolta física policial hacia la celda de la Comisaría (Estilo Kenshi / Red Dead Redemption 2)
	if player_being_escorted_to_jail and player:
		_escort_elapsed_timer += real_delta
		set_jail_cell_gate_locked(false)
		if is_instance_valid(escorting_officer) and not escorting_officer.is_dead and not escorting_officer.is_downed and not escorting_officer.is_stunned_flag and escorting_officer.sedated_timer <= 0.0:
			var follow_pos: Vector2 = escorting_officer.global_position + Vector2(-8, 6)
			if player.global_position.distance_to(escorting_officer.global_position) > 28.0:
				player.global_position = follow_pos
			else:
				player.global_position = player.global_position.move_toward(follow_pos, 96.0 * delta)
			if "velocity" in player:
				player.velocity = Vector2.ZERO
			if escorting_officer.global_position.distance_to(sitio(_jail_cell_pos)) <= 26.0 or player.global_position.distance_to(sitio(_jail_cell_pos)) <= 24.0 or _escort_elapsed_timer >= 9.5:
				complete_police_escort_to_jail(player)
		else:
			var nav_wp: Vector2 = get_navigation_waypoint(player.global_position, sitio(_jail_cell_pos), player)
			player.global_position = player.global_position.move_toward(nav_wp, 84.0 * delta)
			if player.global_position.distance_to(sitio(_jail_cell_pos)) <= 24.0 or _escort_elapsed_timer >= 9.5:
				complete_police_escort_to_jail(player)

	# Si el jugador está cumpliendo condena dentro de la celda de la cárcel, mantenerlo dentro y descontar el tiempo mínimo en celda
	if player_in_jail and player:
		if jail_mandatory_stay_timer > 0.0:
			jail_mandatory_stay_timer = maxf(0.0, jail_mandatory_stay_timer - real_delta)
		var cell_rect := Rect2(sitio(_jail_cell_pos) - Vector2(22, 16), Vector2(44, 32))
		if not cell_rect.has_point(player.global_position):
			player.global_position = sitio(_jail_cell_pos)

	# Paso 2: Rastreo realista de entrada/salida a edificios por testigos
	_sighting_check_timer -= delta
	if _sighting_check_timer <= 0.0:
		_sighting_check_timer = 0.35
		_track_player_building_sightings(player)
		_check_authority_vacancy_announcements()

	if not _deployed_bear_traps.is_empty():
		_update_deployed_bear_traps(delta, player)

	# Actualizar temporizadores de paso de puertas y ventanas cada fotograma, pero throttlear las etiquetas UI a ~12.5 Hz
	for d_entry in building_doors:
		var m_timer: float = float(d_entry.get("manual_override_timer", 0.0))
		if m_timer > 0.0:
			d_entry["manual_override_timer"] = maxf(0.0, m_timer - delta)
		var was_npc_passing: bool = float(d_entry.get("npc_pass_timer", 0.0)) > 0.0
		if was_npc_passing:
			d_entry["npc_pass_timer"] = maxf(0.0, float(d_entry.get("npc_pass_timer", 0.0)) - delta)
		var now_npc_passing: bool = float(d_entry.get("npc_pass_timer", 0.0)) > 0.0
		if was_npc_passing != now_npc_passing:
			_refresh_door_visual_and_collision(d_entry)

	for w_entry in building_windows:
		var wm_timer: float = float(w_entry.get("manual_override_timer", 0.0))
		if wm_timer > 0.0:
			w_entry["manual_override_timer"] = maxf(0.0, wm_timer - delta)

	_ui_hover_timer -= delta
	if _ui_hover_timer > 0.0:
		return
	_ui_hover_timer = 0.08

	var mouse_pos := get_global_mouse_position()

	_update_shop_business_stalls(player, mouse_pos)

func _unhandled_input(event: InputEvent) -> void:
	if business_panel and business_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			var player = get_tree().get_first_node_in_group("player") as Node2D
			match event.keycode:
				KEY_1: _on_business_action_1(player); get_viewport().set_input_as_handled()
				KEY_2: _on_business_action_2(player); get_viewport().set_input_as_handled()
				KEY_3: _on_business_action_3(player); get_viewport().set_input_as_handled()
				KEY_4: _on_business_action_4(player); get_viewport().set_input_as_handled()
				KEY_5, KEY_ESCAPE: business_panel.visible = false; get_viewport().set_input_as_handled()
		return
	if morgue_panel and morgue_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			var player = get_tree().get_first_node_in_group("player") as Node2D
			match event.keycode:
				KEY_0: _on_morgue_open_detective_autopsy(); get_viewport().set_input_as_handled()
				KEY_1: _on_morgue_loot_corpses(player); get_viewport().set_input_as_handled()
				KEY_2: _on_morgue_open_anatomy_panel(); get_viewport().set_input_as_handled()
				KEY_3, KEY_ESCAPE, KEY_ENTER, KEY_E: morgue_panel.visible = false; get_viewport().set_input_as_handled()
		return
	if church_panel and church_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			var player = get_tree().get_first_node_in_group("player") as Node2D
			if event.keycode == KEY_1:
				_on_church_pray_action(player)
				get_viewport().set_input_as_handled()
			elif event.keycode in [KEY_2, KEY_ESCAPE, KEY_ENTER]:
				church_panel.visible = false
				get_viewport().set_input_as_handled()
		return

	if police_panel and police_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			var player = get_tree().get_first_node_in_group("player") as Node2D
			match event.keycode:
				KEY_1: _on_police_serve_sentence(player); get_viewport().set_input_as_handled()
				KEY_2: pay_bounty_fine(player); get_viewport().set_input_as_handled()
				KEY_3: _on_police_jailbreak_or_resist(player); get_viewport().set_input_as_handled()
				KEY_4, KEY_ESCAPE: police_panel.visible = false; get_viewport().set_input_as_handled()
		return
	if board_panel and board_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			var player = get_tree().get_first_node_in_group("player") as Node2D
			match event.keycode:
				KEY_1, KEY_2, KEY_3: _complete_board_contract(player, event.keycode - KEY_0); get_viewport().set_input_as_handled()
				KEY_4, KEY_ESCAPE: board_panel.visible = false; get_viewport().set_input_as_handled()
		return

	# Tecla [B]: Echar o quitar el cerrojo / bloquear la puerta más cercana
	if event is InputEventKey and event.pressed and not event.echo and (Teclas.es(event, "atrancar") or Teclas.es(event, "forzar")):
		var player = get_tree().get_first_node_in_group("player") as Node2D
		if not is_instance_valid(player) or player_being_escorted_to_jail:
			return
		if (player.has_method("is_stunned") and bool(player.call("is_stunned"))) or (player.has_method("is_any_ui_modal_open") and bool(player.call("is_any_ui_modal_open"))):
			return
		if Teclas.es(event, "atrancar") and toggle_bar_door_by_player(player):
			get_viewport().set_input_as_handled()
		elif Teclas.es(event, "forzar") and force_lock_or_shutter_by_player(player):
			get_viewport().set_input_as_handled()

# CONSTRUCCIÓN SÓLIDA DE EDIFICIOS CON TEXTURAS Y COLISIÓN (`StaticBody2D`)

func _build_modal_base(sz: Vector2, border_col: Color, font_sz: int, font_col: Color, center_align: bool = false, sep: int = 8) -> Dictionary:
	var panel := _create_styled_modal(sz, border_col)
	ui_layer.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", sep)
	panel.add_child(vbox)
	var lbl := Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if center_align:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_color", font_col)
	vbox.add_child(lbl)
	return {"panel": panel, "vbox": vbox, "lbl": lbl}

func _add_modal_btn(vbox: VBoxContainer, txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.pressed.connect(cb)
	vbox.add_child(b)
	return b

func _setup_Interactive_modals_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 32
	add_child(ui_layer)

	var m1 := _build_modal_base(Vector2(540, 325), Color(0.38, 0.85, 0.78), 11, Color(0.92, 0.98, 0.96))
	morgue_panel = m1["panel"]
	morgue_info_lbl = m1["lbl"]
	_add_modal_btn(m1["vbox"], "[0] 🔬 Mesa de Autopsias del Detective (Sangre, Cuello, Estómago, Piel)", func(): _on_morgue_open_detective_autopsy())
	_add_modal_btn(m1["vbox"], "[1] 💰 Saquear Bolsillos / Propiedades de los Cuerpos en la Morgue", func(): _on_morgue_loot_corpses(get_tree().get_first_node_in_group("player") as Node2D))
	_add_modal_btn(m1["vbox"], "[2] 🩺 Examen Anatómico / Bolsillos y Órganos en Camilla [H]", func(): _on_morgue_open_anatomy_panel())
	_add_modal_btn(m1["vbox"], "[3 / ESC] Cerrar Informe Forense de la Morgue", func(): morgue_panel.visible = false)

	var m2 := _build_modal_base(Vector2(470, 230), Color(0.42, 0.72, 1.0), 12, Color(0.95, 0.96, 1.0), true)
	police_panel = m2["panel"]
	police_info_lbl = m2["lbl"]
	_add_modal_btn(m2["vbox"], "[1] 🔒 Entregarse y cumplir condena en la Celda hasta las 06:00 AM (Limpia cargos)", func(): _on_police_serve_sentence(get_tree().get_first_node_in_group("player") as Node2D))
	_add_modal_btn(m2["vbox"], "[2] 💰 Pagar Fianza / Multa Policial en Oro para quedar libre", func(): pay_bounty_fine(get_tree().get_first_node_in_group("player") as Node2D))
	_add_modal_btn(m2["vbox"], "[3] 🔓 Forzar barrotes para fugarse (en Celda) / Resistirse", func(): _on_police_jailbreak_or_resist(get_tree().get_first_node_in_group("player") as Node2D))
	_add_modal_btn(m2["vbox"], "[4 / ESC] Cerrar", func(): police_panel.visible = false)

	var m3 := _build_modal_base(Vector2(490, 240), Color(0.92, 0.76, 0.36), 12, Color(1.0, 0.95, 0.80), true)
	board_panel = m3["panel"]
	board_info_lbl = m3["lbl"]
	_add_modal_btn(m3["vbox"], "[1] ⚒️ Encargo de Gremios: Entregar 2 Maderas o 1 Mineral Hierro (+28 Oro, +15 Afinidad)", func(): _complete_board_contract(get_tree().get_first_node_in_group("player") as Node2D, 1))
	_add_modal_btn(m3["vbox"], "[2] 🏥 Urgencia del Hospital: Entregar 2 Hierbas o 1 Cataplasma (+26 Oro, +15 Afinidad)", func(): _complete_board_contract(get_tree().get_first_node_in_group("player") as Node2D, 2))
	_add_modal_btn(m3["vbox"], "[3] 🚓 Cazarrecompensas: Entregar 1 Reliquia Bandido o 1 Ancas Rana (+34 Oro, -1 Cargo)", func(): _complete_board_contract(get_tree().get_first_node_in_group("player") as Node2D, 3))
	_add_modal_btn(m3["vbox"], "[4 / ESC] Cerrar Tablón", func(): board_panel.visible = false)

	var m4 := _build_modal_base(Vector2(540, 310), Color(0.96, 0.80, 0.32), 11, Color(1.0, 0.96, 0.84), false, 7)
	business_panel = m4["panel"]
	business_info_lbl = m4["lbl"]
	_biz_btn_1 = _add_modal_btn(m4["vbox"], "", func(): _on_business_action_1(get_tree().get_first_node_in_group("player") as Node2D))
	_biz_btn_2 = _add_modal_btn(m4["vbox"], "", func(): _on_business_action_2(get_tree().get_first_node_in_group("player") as Node2D))
	_biz_btn_3 = _add_modal_btn(m4["vbox"], "", func(): _on_business_action_3(get_tree().get_first_node_in_group("player") as Node2D))
	_biz_btn_4 = _add_modal_btn(m4["vbox"], "", func(): _on_business_action_4(get_tree().get_first_node_in_group("player") as Node2D))
	_add_modal_btn(m4["vbox"], "[5 / ESC] Cerrar Panel del Negocio", func(): business_panel.visible = false)

	var m5 := _build_modal_base(Vector2(520, 285), Color(0.82, 0.72, 0.96), 11, Color(0.95, 0.92, 1.0))
	church_panel = m5["panel"]
	church_info_lbl = m5["lbl"]
	_add_modal_btn(m5["vbox"], "[1] 🕯️ Encender Vela y Orar por los Difuntos (-5 Oro -> +Calma / +Reputación Vecinal)", func(): _on_church_pray_action(get_tree().get_first_node_in_group("player") as Node2D))
	_add_modal_btn(m5["vbox"], "[2 / ESC] Cerrar Libro Parroquial de Difuntos", func(): church_panel.visible = false)

func _create_styled_modal(sz: Vector2, border_col: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -sz.x * 0.5
	panel.offset_top = -sz.y * 0.5
	panel.offset_right = sz.x * 0.5
	panel.offset_bottom = sz.y * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.13, 0.97)
	style.border_color = border_col
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _open_morgue_autopsy_ui() -> void:
	var ui_root := get_tree().get_first_node_in_group("game_ui") if is_inside_tree() else null
	var det_ui = ui_root.get("detective_ui") if ui_root != null else null
	if det_ui != null and is_inside_tree():
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if is_instance_valid(n) and n.has_meta("scripted_case_id"):
				n.set("corpse_in_morgue", true)
				det_ui.call("open_for_corpse", n, "morgue")
				return
	if not morgue_panel:
		return
	if morgue_active_corpses.is_empty():
		var buried_note: String = "\n🪦 Hay %d difuntos ya sepultados en el Cementerio Parroquial (al sur del Hospital)." % buried_graves.size() if not buried_graves.is_empty() else ""
		morgue_info_lbl.text = "⚰️ SALA DE AUTOPSIAS — MORGUE FORENSE DEL HOSPITAL (0/%d Camillas Ocupadas)\n\nLas 3 camillas de acero inoxidable están despejadas actualmente.%s\n\n(Los cuerpos en la Morgue conservan sus pertenencias y órganos, y permanecen en su camilla hasta que su caso se resuelva o se archive)." % [MAX_MORGUE_CAPACITY, buried_note]
	else:
		var lines: Array[String] = ["⚰️ CAMILLAS ACTIVAS DE LA MORGUE (%d/%d Ocupadas | %d Sepultados en Cementerio):" % [morgue_active_corpses.size(), MAX_MORGUE_CAPACITY, buried_graves.size()]]
		for i in range(morgue_active_corpses.size()):
			var rec: Dictionary = morgue_active_corpses[i]
			var v_name: String = str(rec.get("victim_name", ""))
			var c_node: VillageNPC = _find_corpse_npc_by_name(v_name)
			var pocket_txt: String = c_node.get_pocket_summary_text() if is_instance_valid(c_node) else "Bolsillos vacíos"
			var under_inv: bool = _is_corpse_under_active_investigation(v_name)
			var case_badge: String = "🔍 Caso Abierto (Permanece en Morgue hasta resolver/archivar)" if under_inv else "✅ Caso Resuelto/Archivado (Listo para sepultura)"
			lines.append("• Camilla #%d: %s (%s — %s) [%s]\n   🕒 %s | 📍 %s | 🗡️ Causa: %s\n   💰 Pertenencias en el cuerpo: %s\n   👁️ Pista: %s | ⚖️ Sospechoso: %s" % [
				i + 1, v_name, str(rec.get("victim_role", "")), str(rec.get("family_name", "")), case_badge,
				str(rec.get("time_str", "")), str(rec.get("crime_scene", "")), str(rec.get("cause_of_death", "")),
				pocket_txt, str(rec.get("witness_clue", "")), str(rec.get("suspect", ""))
			])
		morgue_info_lbl.text = "\n".join(lines)
	morgue_panel.visible = true

func _on_morgue_loot_corpses(player: Node2D) -> void:
	if not is_instance_valid(player) or morgue_active_corpses.is_empty():
		return
	var any_looted := false
	for rec in morgue_active_corpses:
		var c_node: VillageNPC = _find_corpse_npc_by_name(str(rec.get("victim_name", "")))
		if is_instance_valid(c_node) and c_node.loot_npc_pockets(player):
			any_looted = true
	if not any_looted:
		_msg_player(player, "⚰️ Los bolsillos de los cuerpos en la Morgue ya están vacíos (Usa [2] o [H] para cirugía/plantar pruebas)", Color.LIGHT_GRAY, -40.0)
	_open_morgue_autopsy_ui()

func _on_morgue_open_anatomy_panel() -> void:
	if morgue_active_corpses.is_empty():
		return
	var target_corpse: VillageNPC = null
	var p := get_tree().get_first_node_in_group("player") as Node2D
	var best_d2: float = INF
	for rec in morgue_active_corpses:
		var c_node: VillageNPC = _find_corpse_npc_by_name(str(rec.get("victim_name", "")))
		if is_instance_valid(c_node):
			var d2: float = p.global_position.distance_squared_to(c_node.global_position) if p else 0.0
			if d2 < best_d2:
				best_d2 = d2
				target_corpse = c_node
	if not is_instance_valid(target_corpse):
		return
	if morgue_panel:
		morgue_panel.visible = false
	var ui_root := get_tree().current_scene.get_node_or_null("UIRoot") if get_tree().current_scene else null
	if ui_root and "medical_panel" in ui_root and is_instance_valid(ui_root.medical_panel):
		ui_root.medical_panel.open_panel(target_corpse)

func _on_morgue_open_detective_autopsy() -> void:
	var target_corpse: VillageNPC = null
	var p := get_tree().get_first_node_in_group("player") as Node2D
	var best_d2: float = INF
	for rec in morgue_active_corpses:
		var c_node: VillageNPC = _find_corpse_npc_by_name(str(rec.get("victim_name", "")))
		if is_instance_valid(c_node):
			var d2: float = p.global_position.distance_squared_to(c_node.global_position) if p else 0.0
			if d2 < best_d2:
				best_d2 = d2
				target_corpse = c_node
	if morgue_panel:
		morgue_panel.visible = false
	var ui_root := get_tree().current_scene.get_node_or_null("UIRoot") if get_tree().current_scene else null
	if ui_root and "detective_ui" in ui_root and is_instance_valid(ui_root.detective_ui):
		ui_root.detective_ui.open_for_corpse(target_corpse, "morgue")

func _open_church_registry_ui() -> void:
	if not church_panel:
		return
	var lines: Array[String] = [
		"⛪ CAPILLA DE SAN CIPRIANO Y LIBRO PARROQUIAL DE DIFUNTOS",
		"⚰️ En Morgue Forense: %d/3 camillas | 🪦 En Cementerio Parroquial: %d/18 tumbas ocupadas" % [morgue_active_corpses.size(), buried_graves.size()]
	]
	if buried_graves.is_empty():
		lines.append("\n🕊️ El camposanto parroquial aún no tiene tumbas ocupadas.\nCuando un cuerpo completa su examen forense en la Morgue (18h) o cuando las 3 camillas de la Morgue se llenan, los difuntos son trasladados y sepultados aquí con su propia lápida física.")
	else:
		lines.append("\n🪦 REGISTRO DE SEPULTURAS EN EL CEMENTERIO:")
		var start_idx: int = maxi(0, buried_graves.size() - 5)
		for i in range(buried_graves.size() - 1, start_idx - 1, -1):
			var g: Dictionary = buried_graves[i]
			lines.append("• Tumba #%d: R.I.P. %s (%s — %s) | Sepultado Día %d\n   🗡️ Causa: %s | 📜 %s" % [
				int(g.get("grave_index", i)) + 1, str(g.get("victim_name", "")), str(g.get("victim_role", "")),
				str(g.get("family_name", "")), int(g.get("burial_day", 1)), str(g.get("cause_of_death", "")), str(g.get("burial_reason", "Sepultura parroquial"))
			])
	church_info_lbl.text = "\n".join(lines)
	church_panel.visible = true

func _on_church_pray_action(player: Node2D) -> void:
	if not player or not ("inventory" in player) or not player.inventory:
		return
	var inv: SimpleInventory = player.inventory
	if inv.gold < 5:
		_msg_player(player, "❌ Necesitas 5 Oro para la ofrenda de velas del altar", Color.ORANGE_RED, -42.0)
		return
	inv.add_gold(-5)
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if not v.is_dead and v.trade_role != VillageNPC.TradeRole.ROYAL_INVESTIGATOR:
				v.affinity = clampi(v.affinity + 3, -100, 100)
	_msg_player(player, "🕯️🙏 Encendiste una vela por los difuntos (-5 Oro, +3 Afinidad en el pueblo)", Color(0.95, 0.88, 1.0), -44.0)
	_open_church_registry_ui()

func try_priority_door_or_corpse_interaction(player: Node2D, mouse_pos: Vector2) -> bool:
	if not player or player_being_escorted_to_jail:
		return false
	var pos: Vector2 = player.global_position

	# 1. Si hay una puerta cerrada muy cerca del jugador (<= 26 px) o una puerta apuntada con el ratón, abrirla/cerrarla con prioridad
	var near_door: Dictionary = _find_nearest_door(pos, 26.0)
	if not near_door.is_empty():
		var d_pos: Vector2 = near_door.get("pos", Vector2.ZERO)
		var is_closed_door: bool = not bool(near_door.get("is_open", false))
		var mouse_aiming_door: bool = d_pos.distance_to(mouse_pos) <= 18.0
		if is_closed_door or mouse_aiming_door:
			_interact_building_door(player, near_door)
			return true

	# 1.5. Si el jugador está junto a cualquier Pozo de Agua y está manchado de sangre, herido o lleva recipientes vacíos (o apunta al pozo), usar el pozo con prioridad
	for w_pos in _well_positions:
		if pos.distance_to(w_pos) <= 28.0 and ((player.has_method("is_bloodstained") and bool(player.call("is_bloodstained"))) or w_pos.distance_to(mouse_pos) <= 18.0):
			_use_water_well(player)
			return true

	# 2. Si hay un cadáver, herido abatido o NPC aturdido/sedado cerca del jugador (<= 32 px), priorizar saquear/reanimar/reportar con [E]
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var c := n as VillageNPC
			if pos.distance_to(c.global_position) <= 32.0:
				var can_loot_pockets: bool = not c.corpse_pocket_looted and (c.personal_gold > 0 or c.carries_royal_safe_conduct or not c.pocket_items.is_empty())
				var mouse_aiming_c: bool = c.global_position.distance_to(mouse_pos) <= 20.0
				if (c.is_dead and not c.corpse_buried and (c.corpse_on_ground or c.corpse_in_morgue)) or (not c.is_dead and (c.is_downed or ((c.sedated_timer > 0.0 or c.is_stunned_flag) and can_loot_pockets))):
					c.interact(player)
					return true

	# 3. Si el jugador apunta con el ratón directamente a un mostrador de negocio (<= 16 px) o el local no tiene dueño presente cerca, abrir Panel de Negocio
	var near_stall: Dictionary = _find_nearest_business_stall(pos, 26.0)
	if not near_stall.is_empty():
		var s_pos: Vector2 = near_stall.get("stall_pos", Vector2.ZERO)
		var b_role: int = int(near_stall.get("role", -1))
		var holder: VillageNPC = trade_npcs.get(b_role)
		var holder_present: bool = is_instance_valid(holder) and not holder.is_dead and not holder.is_downed and not holder.is_sleeping and not holder.is_stunned_flag and holder.sedated_timer <= 0.0 and holder.global_position.distance_to(pos) <= 28.0
		if s_pos.distance_to(mouse_pos) <= 16.0 or not holder_present:
			open_business_management_ui(b_role)
			return true

	return false

func interact(player: Node2D) -> void:
	if not player or player_being_escorted_to_jail:
		return
	var pos := player.global_position
	var o: Vector2 = _AN_SITIOS.desmover(pos) # mapa ×E: las pistas escritas a mano se comparan en el mapa original

	# Caso I: si el jugador apunta a una pista o a la bandeja del caso, manda eso aunque haya una puerta o ventana cerca
	var c1_sel0: Node = player.get("interaction_selector")
	var c1_cand0: Dictionary = c1_sel0.call("selected") if (c1_sel0 != null and c1_sel0.has_method("selected")) else {}
	if str(c1_cand0.get("station", "")).begins_with("case1_") and VillageCase1.try_interact(self, player, pos, str(c1_cand0.get("station", ""))):
		return
	if str(c1_cand0.get("station", "")) == "old_bridge_left_shoe": # el zapato del Puente Viejo manda sobre lo que haya cerca
		_anotar_zapato_puente(player)
		return

	# 0. ¿Está cerca de una Puerta (`building_doors`) o Ventana (`building_windows`)?
	var best_door: Dictionary = _find_nearest_door(pos, 24.0)
	if not best_door.is_empty():
		_interact_building_door(player, best_door)
		return

	var best_win: Dictionary = _find_nearest_window(pos, 20.0)
	if not best_win.is_empty():
		_interact_building_window(player, best_win)
		return

	# 0.5. ¿Está junto al Mostrador de un Negocio (`shop_businesses`)?
	var best_stall: Dictionary = _find_nearest_business_stall(pos, 26.0)
	if not best_stall.is_empty():
		open_business_management_ui(int(best_stall.get("role", -1)))
		return

	# 0.9. Caso I: gabinete forzado de la mansión y hoja arrancada en casa del familiar (antes que los cofres)
	var c1_sel: Node = player.get("interaction_selector") if player != null else null
	var c1_cand: Dictionary = c1_sel.call("selected") if (c1_sel != null and c1_sel.has_method("selected")) else {}
	if VillageCase1.try_interact(self, player, pos, str(c1_cand.get("station", ""))):
		return
	# 1. ¿Está cerca de un Cofre Doméstico (`house_chests`)?
	for ch in house_chests:
		var c_pos: Vector2 = ch["pos"]
		if pos.distance_squared_to(c_pos) <= 22.0 * 22.0:
			_interact_house_chest(player, ch)
			return
	# 1b. Punto 5 (Caso I): Sala oculta de la Biblioteca (libro-palanca, cuaderno de firmas y libro con página arrancada)
	var sel_node: Node = player.get("interaction_selector") if player != null else null
	var sel_cand: Dictionary = sel_node.call("selected") if (sel_node != null and sel_node.has_method("selected")) else {}
	var sel_kind: String = str(sel_cand.get("station", ""))
	if sel_kind == "library_secret_ledger" or (sel_kind != "library_torn_book" and o.distance_squared_to(VillageCulture.library_site(VillageCulture.M_LIBRO_MAYOR)) <= 22.0 * 22.0 and o.distance_squared_to(VillageCulture.library_site(VillageCulture.M_LIBRO_MAYOR)) <= o.distance_squared_to(VillageCulture.library_site(VillageCulture.M_LIBRO_ROTO))):
		if o.distance_squared_to(VillageCulture.library_site(VillageCulture.M_LIBRO_MAYOR)) <= 26.0 * 26.0:
			_record_case_clue(
				player,
				"🖋️ Cuaderno",
				"🖋️ Varias firmas de quienes han entrado en esta sala; una se parece a la del billete de «V.», aunque la presión y el rasgo final son distintos.",
				"Biblioteca (sala oculta): cuaderno con varias firmas; una se parece a la del billete de «V.», pero el trazo no coincide.",
				"Pista: Cuaderno de firmas",
				"clue_library_secret_ledger",
				Color(0.95, 0.88, 0.68)
			)
			return
	if sel_kind == "library_torn_book" or o.distance_squared_to(VillageCulture.library_site(VillageCulture.M_LIBRO_ROTO)) <= 22.0 * 22.0:
		if o.distance_squared_to(VillageCulture.library_site(VillageCulture.M_LIBRO_ROTO)) <= 26.0 * 26.0:
			_record_case_clue(
				player,
				"📖 Libro antiguo",
				"📖 Un viejo tomo de herboristería y venenos. En el índice figura un capítulo sobre la belladama gris y las mezclas que apagan el pulso, pero falta esa hoja: solo queda el borde de papel rasgado junto al lomo.",
				"Biblioteca (sala oculta): tomo antiguo de venenos al que han arrancado la página del capítulo sobre la belladama gris.",
				"Pista: Página arrancada",
				"clue_library_torn_book",
				Color(0.88, 0.78, 0.96)
			)
			return
	if sel_kind == "library_book_lever" or o.distance_squared_to(VillageCulture.library_site(VillageCulture.M_PALANCA)) <= 24.0 * 24.0: # como los otros dos: vale lo que el jugador tiene seleccionado
		_record_case_clue(
			player,
			"📕 Estantería",
			"📕 En el suelo de madera hay marcas curvas de roce y por la rendija sale una corriente de aire frío que mueve el polvo. Uno de los tomos está sujeto a un pestillo interior y cede hacia abajo al tirar de él.",
			"Biblioteca: marcas curvas en las tablas del suelo, corriente de aire y un libro sujeto a un pestillo que abre la estantería.",
			"Pista: Estantería móvil",
			"clue_library_book_lever",
			Color(0.96, 0.84, 0.64)
		)
		return
	if VillageCulture.try_interact(self, player, pos): # V5e: leer en la biblioteca
		return
	if not is_demo_mode():
		if VillageMayor.try_interact(self, player, pos): # P5: alcaldía y candidatura
			return
		if VillageHousing.try_interact(self, player, pos): # P6: solar o cama de tu casa
			return
		if VillageUnderworld.try_interact(self, player, pos): # P7: encargo nocturno del perista
			return
	if VillageForensics.try_interact(self, player, pos): # P2: fregar escena de sangre con lejía (doble E)
		return

	# 2. Tablón de Encargos de la Plaza
	if pos.distance_squared_to(sitio(_notice_board_pos)) <= 28.0 * 28.0:
		_open_notice_board_ui()
		return

	# 3. Morgue Forense
	if pos.distance_squared_to(sitio(_morgue_table_positions[1])) <= 36.0 * 36.0:
		_open_morgue_autopsy_ui()
		return

	# 3b. Capilla del Alba y Cementerio Parroquial
	if pos.distance_squared_to(sitio(_church_altar_pos)) <= 34.0 * 34.0 or pos.distance_squared_to(sitio(_cemetery_gate_pos)) <= 34.0 * 34.0 or Rect2(Vector2(822, 260), Vector2(268, 168)).has_point(_AN_SITIOS.desmover(pos)):
		_open_church_registry_ui()
		return

	# 4. Cama de Urgencias del Hospital
	if pos.distance_squared_to(sitio(_hospital_bed_pos)) <= 28.0 * 28.0:
		_use_hospital_emergency_bed(player)
		return

	# 5. Celda de la Comisaría y Archivo de Pruebas (Caso I)
	if o.distance_squared_to(Marca.sitio(ID_COMISARIA, Marca.ARCHIVO)) <= 26.0 * 26.0 or o.distance_squared_to(Vector2(856.0, 107.0)) <= 24.0 * 24.0:
		_record_case_clue(
			player,
			"📋 Carpeta de archivo",
			"📋 Una denuncia de desaparición fechada anoche. Lleva un sello rojo de «Archivada» cruzado sobre la hoja y ninguna diligencia anotada debajo.",
			"Comisaría: denuncia de desaparición fechada anoche y sellada como «Archivada» sin actuaciones registradas.",
			"Pista: Denuncia archivada",
			"clue_police_archived_report",
			Color(0.95, 0.88, 0.68)
		)
		return
	if player_in_jail or pos.distance_squared_to(sitio(_jail_cell_pos)) <= 32.0 * 32.0:
		_police_confront_cooldown = 0.0
		trigger_police_confrontation(null)
		return

	# 5b. Pistas del Caso I en el Molino Viejo Abandonado y Claro del Arroyo
	if o.distance_squared_to(Vector2(140.0, -1006.0)) <= 30.0 * 30.0:
		_record_case_clue(
			player,
			"🧱 Orilla de arcilla",
			"🧱 La ribera junto al molino es de barro rojo vivo y arcilla plástica, con pisadas recientes hundidas en el fango.",
			"Exterior del molino: la orilla del arroyo junto al molino es de barro rojo de arcilla con pisadas hundidas.",
			"Pista: Barro rojo del molino",
			"clue_mill_red_clay",
			Color(0.92, 0.52, 0.42)
		)
		return
	if o.distance_squared_to(Marca.sitio(ID_MOLINO, Marca.SOTANO)) <= 28.0 * 28.0:
		_record_case_clue(
			player,
			"🔩 Reja de hierro",
			"🔩 Una reja oxidada que cierra el hueco hacia el canal de la rueda. Dos barrotes tienen muescas frescas en el metal, están algo separados y en una arista ha quedado enganchado un retal de lana azul oscuro.",
			"Sótano del molino: reja hacia el canal con dos barrotes doblados, muescas frescas y un retal de lana azul oscuro enganchado.",
			"Pista: Reja de hierro",
			"clue_mill_cellar_grate",
			Color(0.76, 0.88, 0.96)
		)
		return
	if o.distance_squared_to(Marca.sitio(ID_MOLINO, Marca.MESA_PAPEL)) <= 28.0 * 28.0 and o.distance_squared_to(Marca.sitio(ID_MOLINO, Marca.MESA_PAPEL)) <= o.distance_squared_to(Marca.sitio(ID_MOLINO, Marca.HOGAR)):
		_record_case_clue(
			player,
			"📄 Papel sobre la mesa",
			"📄 Sobre la mesa del molino hay una hoja doblada: «Lista de nombres — texto pendiente del autor».",
			"Mesa del molino: hoja con una «Lista de nombres — texto pendiente del autor».",
			"Pista: Papel en el molino",
			"clue_mill_table_paper",
			Color(0.96, 0.90, 0.72)
		)
		return
	if o.distance_squared_to(Marca.sitio(ID_MOLINO, Marca.CORDEL)) <= 26.0 * 26.0:
		_record_case_clue(
			player,
			"🪢 Rollo de cordel",
			"🪢 Un carrete de cordel de cáñamo frotado con cera de abeja. El extremo está recién cortado junto a una navaja oxidada.",
			"Molino viejo: carrete de cordel de cáñamo encerado con el extremo recién cortado.",
			"Pista: Cordel en el molino",
			"clue_mill_hemp_cord",
			Color(0.90, 0.80, 0.58)
		)
		return
	if o.distance_squared_to(Marca.sitio(ID_MOLINO, Marca.HOGAR)) <= 26.0 * 26.0:
		_record_case_clue(
			player,
			"🪨 Hogar de piedra",
			"🪨 El hogar apagado acumula ceniza negra de carbón mineral y polvo de hollín esparcido por las losas de delante.",
			"Molino viejo: hogar de piedra apagado con ceniza negra de carbón esparcida por el suelo.",
			"Pista: Ceniza en el molino",
			"clue_mill_hearth",
			Color(0.78, 0.78, 0.82)
		)
		return
	if o.distance_squared_to(Marca.sitio(ID_MOLINO, Marca.PAJAR)) <= 26.0 * 26.0:
		_record_case_clue(
			player,
			"🌾 Pajar",
			"🌾 Un montón de paja seca y espigas de sauce en el rincón; el centro está aplastado y hundido.",
			"Molino viejo: montón de paja seca y espigas de sauce hundido en el centro.",
			"Pista: Pajar del molino",
			"clue_mill_hayloft",
			Color(0.92, 0.82, 0.45)
		)
		return
	if pos.distance_to(VillageCase1.Sitio.mundo(VillageCase1.SITIO_CLARO)) <= VillageCase1.CLARO_RADIO_PX * VillageCase1.Mapa3D.E:
		if not VillageCase1.empezado(): # día de margen: todavía no ha pasado nada aquí
			_msg_player(player, "🌲 Un recodo tranquilo del arroyo. Nada llama la atención… por ahora.", Color(0.84, 0.72, 0.54))
			return
		_record_case_clue(
			player,
			"🌲 Orilla del arroyo",
			"🌲 En este recodo del arroyo la tierra húmeda junto al agua es de barro pardo oscuro mezclado con hojarasca.",
			"Claro del arroyo: la tierra húmeda de esta orilla es de barro pardo oscuro.",
			"Pista: Orilla del claro",
			"clue_case1_clearing",
			Color(0.84, 0.72, 0.54)
		)
		return
	# El zapato está donde lo puso VillageWorldBuilder (junto al cruce del río del editor): se mira su zona de verdad
	var shoe_area: Node2D = entities_root.get_node_or_null("OldBridgeVictimShoeArea") as Node2D
	if shoe_area != null and pos.distance_squared_to(shoe_area.global_position) <= 26.0 * 26.0:
		_anotar_zapato_puente(player)
		return

	var d_bed: float = pos.distance_squared_to(sitio(_tavern_bed_pos))
	var d_games: float = pos.distance_squared_to(sitio(_tavern_games_pos))
	var d_pool: float = pos.distance_squared_to(sitio(_tavern_pool_pos))
	var d_well: float = _get_nearest_well_dist_sq(pos)
	var comp_on: bool = _compost_marca == null or _compost_marca.visible
	var d_comp: float = pos.distance_squared_to(sitio(_compost_pos)) if comp_on else INF

	if d_pool <= d_games and d_pool <= d_bed and d_pool <= 32.0 * 32.0:
		_use_tavern_games_table(3)
	elif d_games <= d_bed and d_games <= d_well and d_games <= d_comp and d_games <= 32.0 * 32.0:
		_use_tavern_games_table(0)
	elif d_bed <= d_well and d_bed <= d_comp and d_bed <= 26.0 * 26.0:
		_use_tavern_bed(player)
	elif d_well <= d_comp and d_well <= 26.0 * 26.0:
		_use_water_well(player)
	elif d_comp <= 26.0 * 26.0:
		_use_compost_bin(player)


## Punto 6 del Caso I: el zapato izquierdo de la víctima en el Puente Viejo.
func _anotar_zapato_puente(player: Node2D) -> void:
	_record_case_clue(
		player,
		"👞 Zapato",
		"👞 Un zapato izquierdo de mujer, de cuero marrón con la hebilla de latón torcida, volcado de costado junto al pretil norte del puente.",
		"Puente Viejo: zapato izquierdo de cuero con la hebilla torcida caído junto al pretil.",
		"Pista: Zapato en el puente",
		"clue_old_bridge_left_shoe",
		Color(0.92, 0.82, 0.64)
	)


func _record_case_clue(
	player: Node2D, title: String, hint_txt: String, note_txt: String,
	tag: String, source_key: String, msg_col: Color
) -> void:
	_msg_player(player, title, msg_col, -42.0)
	_hint_player(hint_txt, player)
	var ui_root := get_tree().get_first_node_in_group("game_ui")
	if ui_root and "detective_ui" in ui_root and is_instance_valid(ui_root.detective_ui):
		if ui_root.detective_ui.has_method("add_notebook_note"):
			ui_root.detective_ui.add_notebook_note(title, note_txt, tag, source_key)

# ==============================================================================
# PUERTAS FÍSICAS, VENTANAS FORZABLES Y NIVEL DE SEGURIDAD / DESCONFIANZA DE LA ALDEA
# ==============================================================================

func _on_hour_passed(_day: int, new_hour: int = 8) -> void:
	var actual_hour: int = WorldClock.current_hour if WorldClock else new_hour
	var actual_day: int = WorldClock.current_day if WorldClock else 1
	_apply_hourly_door_security_schedule(actual_hour)
	var demo_active: bool = is_demo_mode()
	VillageFaith.on_hour(self, actual_hour) # G2: Oficio del Alba (domingo por la mañana)
	if not demo_active:
		VillageHousing.on_hour(self, actual_hour) # P1: dependiente y clientes reales en tu tienda
		VillageUnderworld.fence_on_hour(self, actual_hour) # P5b: el perista trasnocha en el callejón de la taberna
		VillageNightJobs.on_hour(self, actual_hour) # P6b: a la 1:00 salen los saboteadores, rateros y profanadores
		VillageClub.on_hour(self, actual_hour) # P6: el club del sótano abre cada noche de 21:00 a 03:00
	VillageTavern.on_hour(self, actual_hour) # Paso 3: clientes en mesas y partida de póker en El Jabalí Dorado
	VillageRestaurant.on_hour(self, actual_hour) # Clientes sentados cenando y tomando algo en la terraza de la trattoria de noche
	if not demo_active:
		VillageFame.sync_masterwork_counters(self) # A1: mostrador de las Obras Maestras en el taller de cada maestro
		VillageCollections.sync_points(self) # P5: puntos de cobro en los locales y objetos del ayuntamiento
	VillageNeeds.on_hour(self, actual_hour) # E: higiene, taberna, limosna
	if not demo_active:
		VillageIllness.on_hour(self, actual_hour) # E2: contagios
		VillageSect.on_hour(self, actual_hour) # O3: reunión de la secta (viernes de madrugada)
		VillageFamilia.on_hour(self, actual_hour) # R2: reuniones nocturnas en el reservado de la Trattoria
		VillageLots.on_hour(self, actual_hour) # V4: el carpintero avanza la obra si está allí
	VillageCivic.on_hour(self, actual_hour) # V5b: votar en persona y el alcalde en el ayuntamiento
	VillagePlaces.on_hour(self, actual_hour) # V5c: ratos libres en el parque, la plaza o el mirador
	VillageWork.on_hour(self, actual_hour) # V5d: jornaleros (contratar, contar horas, pagar)
	if not demo_active:
		VillageCulture.on_hour(self, actual_hour) # V5e: mercado de los miércoles
		VillageMigration.on_hour(self, actual_hour) # V3: los que se marchan siguen su camino
	VillageNobility.on_hour(self, actual_hour) # V6: los nobles aparecen en la primera hora
	VillageCase1.sync(self) # Caso I: papeles, gabinete, hoja arrancada y secuestradores del molino
	if not demo_active:
		VillageFamily.on_hour(self, actual_hour) # V9: lo que se aprende en la escuela
	VillageConfession.on_hour(self, actual_hour) # P4: confesiones entre semana en la capilla
	if not demo_active:
		VillageUnderworld.on_hour(self, actual_hour) # P3 Parte B: caravana nocturna de contrabando
	VillageJustice.on_hour(self) # B2: condenas por horas de los vecinos encerrados en el calabozo

	# 07:00 AM -> Comprobar llegada semanal de los 2 Mercaderes Ambulantes (Día 3: Maese Casimir | Día 6: Valeria la Tratante)
	if actual_hour == 7 and not demo_active:
		_check_weekly_merchant_arrival(actual_day)
	# 08:00 AM -> Salarios de autoridades, compras recíprocas entre gremios y jornales diarios
	elif actual_hour == 8:
		_process_morning_salaries_and_inter_guild_circulation()
	# 21:00 PM -> Cobro de alquiler nocturno en la Posada (6 Oro) o desahucio a Campamentos Rústicos en las Afueras
	elif actual_hour == 21:
		_process_nightly_tavern_rent_and_vagrant_camps()

	# Ciclo de Sepultura Forense: solo se sepultan los cuerpos cuyo caso YA fue resuelto o archivado y que lleven >= 18h desde entonces
	var cur_total_hours: int = actual_day * 24 + actual_hour
	var remaining_morgue: Array[Dictionary] = []
	var any_buried := false
	for entry in morgue_active_corpses:
		var v_name_h: String = str(entry.get("victim_name", ""))
		var added_h: int = int(entry.get("added_total_hours", cur_total_hours))
		if not _is_corpse_under_active_investigation(v_name_h) and (cur_total_hours - added_h) >= 18:
			_bury_corpse_in_cemetery(entry, "Sepultura parroquial tras resolverse/archivarse el caso")
			any_buried = true
		else:
			remaining_morgue.append(entry)
	if any_buried:
		morgue_active_corpses = remaining_morgue
		_refresh_morgue_table_sprites()

func _on_day_passed(_new_day: int) -> void:
	arrivals_today_count = 0
	chronicle_daily = true
	if social_director != null:
		_advance_live_romances(_new_day)
		var demo_active_day: bool = is_demo_mode()
		social_director.on_day_passed(_new_day)
		VillageSocialLife.daily_reciprocity(self)
		VillageSocialLife.daily_distance_cooling(self, _new_day)
		VillageChronicle.daily_friendship_scan(self)
		VillageSocialLife.GossipMemory.daily_decay(self)
		if not demo_active_day:
			VillageSecrets.daily(self)
			VillageDesires.daily(self)
		VillageFaith.daily(self) # G: roces de fe, sacerdote y bandos
		if not demo_active_day:
			VillageSect.daily(self) # O: la secta (justo después: vuelve a añadir su bando oculto)
			VillageFamilia.daily(self) # R2: La Familia (nace sola, recluta y planea reuniones en el reservado)
		VillageNeeds.daily(self) # E1/E3/E5
		VillageTrades.daily(self) # V5: estrenar ropa en la sastrería
		if not demo_active_day:
			VillageCivic.daily(self) # V5b: arcas robadas y albergue
			VillageCulture.daily(self) # V5e: el arreglador repara puestos saboteados
			VillageNobility.daily(self) # V6: los lunes, rentas de las tierras
			VillageFamily.daily(self) # V9: crecer, nacer, esperar un hijo y la escuela
			VillageIllness.daily(self) # E2
			VillageCrime.daily(self) # E4: como mucho un robo por noche
			VillageTown.daily(self) # I: elecciones, impuestos del sábado, desfalcos
			VillageClans.daily(self) # P1: romances prohibidos, ovejas negras y tumbas
			VillageForensics.daily(self) # P2: sicarios y confesiones por embriaguez/fiebre
			VillageLineage.daily(self) # P3: hijos secretos, manutención, cazafortunas y pasado
		VillageConfession.daily(self) # P4: penitencias, santuario y excomuniones
		if not demo_active_day:
			VillageMayor.daily(self) # P5: promesas electorales, decretos y protestas
			VillageHousing.daily(self) # P6: pareja en casa, huerto y rentas comerciales
			VillageUnderworld.daily(self) # P7: mercado negro, usura, protección y jefe del hampa
			VillageCollections.daily(self) # P5: el sábado se aparta lo que te deben; lo recoges en persona
			VillageFame.daily(self) # Fama de los vecinos y Maestros Artesanos con estilo propio
		VillageQuests.on_day_passed(self)
	chronicle_daily = false

	# Descontar 1 día del embargo comercial (20..30 días mercaderes semanales / 7 días caravanas P3) si fue asesinado
	for m_key in ["casimir", "valeria", "high_pass", "river_port", "sun_plain"]:
		var susp_d: int = int(merchant_suspension_days.get(m_key, 0))
		if susp_d > 0:
			susp_d = maxi(0, susp_d - 1)
			merchant_suspension_days[m_key] = susp_d
			if susp_d == 0:
				var p_m = get_tree().get_first_node_in_group("player")
				if p_m and p_m.has_method("show_hint"):
					var m_label: String = "Maese Casimir (Liga Minera)" if m_key == "casimir" else ("Valeria la Tratante (Gremio de Caza)" if m_key == "valeria" else str(VillageCulture.ROUTE_CARAVAN_NAMES.get(m_key, m_key)))
					p_m.show_hint("📜⚖️ El embargo comercial sobre la ruta de %s ha concluido tras semanas de bloqueo. Volverá a pasar en su día semanal." % m_label)

	# Avanzar jornada de investigación del Inquisidor Real Alistair (garantizando resolución antes del día 19)
	_advance_royal_investigation_day(_new_day)

	# 1. Progresión de la Curva de Eficiencia Laboral de 7 Días (+1 día de experiencia a cada trabajador vivo)
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if not v.is_dead and not (v.trade_role in [VillageNPC.TradeRole.UNEMPLOYED, VillageNPC.TradeRole.FAMILY_MEMBER]):
				if v.days_in_role < 7:
					v.days_in_role = mini(7, v.days_in_role + 1)
					if v.days_in_role == 7:
						v._spawn_floating_text("🎓⚒️ ¡Dominio Maestro alcanzado (100% Eficiencia)!", Color.GOLD, -40.0)
					else:
						v._spawn_floating_text("📈 Experiencia laboral: Día %d/7 (%d%% Eficiencia)" % [v.days_in_role, int(round(v.get_job_efficiency() * 100.0))], Color.AQUA, -36.0)

	# 1b. Sepultura matutina de cuerpos en la Morgue SOLO si su caso ya se resolvió o archivó (los casos abiertos permanecen en la Morgue)
	var cur_total_h: int = _new_day * 24 + (WorldClock.current_hour if WorldClock else 6)
	var rem_morgue: Array[Dictionary] = []
	for m_entry in morgue_active_corpses:
		var v_name_d: String = str(m_entry.get("victim_name", ""))
		if not _is_corpse_under_active_investigation(v_name_d) and (cur_total_h - int(m_entry.get("added_total_hours", cur_total_h))) >= 12:
			_bury_corpse_in_cemetery(m_entry, "Sepultura parroquial matutina tras resolverse/archivarse el caso")
		else:
			rem_morgue.append(m_entry)
	morgue_active_corpses = rem_morgue
	_refresh_morgue_table_sprites()

	# 1c. La Posada y los artesanos ya NO reponen stock por arte de magia al dormir: fabrican sus propios recursos físicamente durante su turno de trabajo (`_process_artisan_work_shift`)

	var total_player_dividends: int = 0
	for role_key in trade_configs.keys():
		var r_id: int = int(role_key)
		var current_holder: VillageNPC = trade_npcs.get(role_key)
		var cfg: Dictionary = trade_configs[role_key]
		var biz: Dictionary = shop_businesses.get(r_id, {})
		var owner_mode: String = str(biz.get("owner_mode", "NPC"))
		var sab_days: int = int(biz.get("sabotaged_days", 0))

		# Reducir 1 día de sabotaje si estaba averiado
		if sab_days > 0:
			sab_days = maxi(0, sab_days - 1)
			biz["sabotaged_days"] = sab_days
			_refresh_shop_stall_visual(r_id)

		# Procesar ventas diarias del mostrador y dividendos si el jugador es Socio ("PARTNER") o Dueño ("SOLE_OWNER")
		if owner_mode in ["PARTNER", "SOLE_OWNER"]:
			var day_profit: int = _process_daily_business_sales_and_dividends(r_id, current_holder, sab_days)
			total_player_dividends += day_profit

		if not is_instance_valid(current_holder) or current_holder.is_dead:
			if is_demo_mode():
				continue
			# Si el jugador ya compró la propiedad completa ("SOLE_OWNER"), él decide cuándo contratar encargado en [3]
			if owner_mode == "SOLE_OWNER":
				continue

			# Sucesión Interna #1: Familiar directo que ya vivía en esa casa (Empieza con `days_in_role = 2` -> 54% Aprendiz)
			var kin_candidate: VillageNPC = family_npcs.get(role_key)
			if is_instance_valid(kin_candidate) and not kin_candidate.is_dead and kin_candidate.trade_role == VillageNPC.TradeRole.FAMILY_MEMBER:
				var inh_stock: Dictionary = (biz.get("stock_override", cfg["stock"]) as Dictionary).duplicate()
				kin_candidate.promote_to_trade(role_key, str(cfg["title"]), cfg["work_pos"], inh_stock, cfg["tex"])
				_note_inheritance(kin_candidate, current_holder)
				trade_npcs[role_key] = kin_candidate
				family_npcs.erase(role_key)
				_hint_player("🏠 Herencia Familiar: %s (%s) asumió el puesto de %s como Aprendiz (54%% Eficiencia · 5 días para Maestro)." % [kin_candidate.npc_name, str(cfg["family_name"]), str(cfg["title"])])
				continue

			if sab_days > 0:
				continue

			# Sucesión Interna #2 (V8): el más ambicioso y capaz del pueblo (un sin oficio, o un familiar de otra casa que
			# quiere prosperar) se queda el taller; si no hay nadie, el primer viajero sin oficio de la posada
			var outsider: VillageNPC = _pick_ambitious_successor(role_key, str(cfg["title"]))
			if outsider == null:
				outsider = _pop_living_unemployed()
			if outsider:
				var inh_stock2: Dictionary = (biz.get("stock_override", cfg["stock"]) as Dictionary).duplicate()
				outsider.promote_to_trade(role_key, str(cfg["title"]), cfg["work_pos"], inh_stock2, cfg["tex"], cfg["bed1_pos"], cfg["table_pos"], str(cfg["family_id"]), str(cfg["family_name"]))
				_note_inheritance(outsider, current_holder)
				trade_npcs[role_key] = outsider
				_hint_player("🔄 Sucesión en la aldea: %s asumió el taller como nuevo %s Novato (35%% Eficiencia · 7 días para Maestro)." % [outsider.npc_name, str(cfg["title"])])
		else:
			biz["stock_override"] = current_holder.shop_stock.duplicate()

	# 2. LLEGADAS EXTERNAS DESDE EL BORDE DEL MAPA (Estricto límite de `MAX_DAILY_ARRIVALS = 2` personas por día)
	if not is_demo_mode():
		_process_daily_map_edge_arrivals()
		VillageMigration.daily(self) # V3: casas, marchas y llegadas según el atractivo del pueblo

	if total_player_dividends > 0:
		var p_div = get_tree().get_first_node_in_group("player")
		if p_div and p_div.has_method("show_hint"):
			p_div.show_hint("💰📈 Tus negocios del valle generaron +%d Oro hoy (Recáudalo en sus Cajas Registradoras [E])." % total_player_dividends)

## Gestiona la llegada diaria de hasta `MAX_DAILY_ARRIVALS = 2` personas caminando físicamente desde el borde del mapa (`Vector2(-900, 48)` o `Vector2(990, 48)`).
## Si toda la aldea muere, NO reaparece de golpe al día siguiente: llegan como máximo 2 personas por día y entran como Novatos (35% eficiencia).

func _process_daily_map_edge_arrivals() -> void:
	# Prioridad 1: Vacantes de Autoridades (Médico Forense, Comisario, Guardia)
	for slot in _authority_slots:
		if arrivals_today_count >= MAX_DAILY_ARRIVALS:
			return
		var cur_auth: VillageNPC = slot.get("npc")
		if not is_instance_valid(cur_auth) or cur_auth.is_dead:
			_spawn_authority_replacement(slot)
			arrivals_today_count += 1

	# Prioridad 2: Vacante de Posadera/Chef en la Taberna El Jabalí Dorado
	if arrivals_today_count < MAX_DAILY_ARRIVALS and (not is_instance_valid(_innkeeper_npc) or _innkeeper_npc.is_dead):
		var new_inn: VillageNPC = _spawn_generated_newcomer(
			"NPC_Innkeeper_",
			VillageNPC.TradeRole.INNKEEPER,
			VillageNPC.TradeRole.INNKEEPER,
			"Chef y Posadera (Novata)",
			_load_tex("res://assests/world/village/villager_innkeeper.png"),
			VillageTavern.sitio(VillageTavern.M_TRABAJO),
			VillageTavern.sitio(VillageTavern.M_CAMA_MARTA),
			{"country_stew": 2, "bread": 3, "roasted_chicken": 1},
			_tavern_social_pos,
			"family_tavern",
			"Posada El Jabalí"
		)
		_innkeeper_npc = new_inn
		arrivals_today_count += 1
		_hint_player("🍺🚶 %s (Posadera Novata · 35%%) está llegando por el borde del valle para reabrir la Posada." % new_inn.npc_name)

	# Prioridad 3: Oficios vacantes sin familia ni huésped disponible (salvo que sean propiedad exclusiva del jugador o estén saboteados)
	for role_key in trade_configs.keys():
		if arrivals_today_count >= MAX_DAILY_ARRIVALS:
			return
		var r_id: int = int(role_key)
		var holder: VillageNPC = trade_npcs.get(role_key)
		if is_instance_valid(holder) and not holder.is_dead:
			continue
		var biz: Dictionary = shop_businesses.get(r_id, {})
		if str(biz.get("owner_mode", "NPC")) == "SOLE_OWNER" or int(biz.get("sabotaged_days", 0)) > 0:
			continue
		var cfg: Dictionary = trade_configs[role_key]
		var inh_st: Dictionary = (biz.get("stock_override", cfg["stock"]) as Dictionary).duplicate()
		var new_art: VillageNPC = _spawn_generated_newcomer(
			"NPC_Newcomer_Trade_",
			role_key,
			role_key,
			str(cfg.get("title", "Artesano")) + " (Recién Llegado)",
			cfg.get("tex", null),
			cfg.get("work_pos", sitio(Vector2(440, 44))),
			cfg.get("bed1_pos", sitio(_tavern_bed_pos)),
			inh_st,
			cfg.get("table_pos", sitio(_tavern_social_pos)),
			str(cfg.get("family_id", "none")),
			str(cfg.get("family_name", "Gremio")),
			true # trade_configs ya está traducido (plan de sitios)
		)
		trade_npcs[role_key] = new_art
		arrivals_today_count += 1
		_hint_player("⚒️🚶 %s (%s Novato · 35%% Eficiencia) está entrando al valle desde el borde del mapa." % [new_art.npc_name, str(cfg.get("title", "Artesano"))])

	# Prioridad 4 (V3): ya no hay «siempre 3 viajeros»; llegan según el atractivo del pueblo (VillageMigration.daily)

## V8: quién se queda un negocio sin dueño. Puntúa ambición, diligencia y ahorros; un familiar de otra casa solo deja
## la suya si es ambicioso. Los otros ambiciosos que se quedan sin él le cogen algo de envidia.
## M13 «La herencia»: quién heredó, de quién y cuándo (para que los parientes puedan reclamar).

func get_economy_save_dict() -> Dictionary:
	var out: Dictionary = {}
	for r_id in shop_businesses.keys():
		var role_int: int = int(r_id)
		var biz: Dictionary = shop_businesses[role_int]
		out[str(role_int)] = {
			"owner_mode": str(biz.get("owner_mode", "NPC")), "vault_gold": int(biz.get("vault_gold", 0)),
			"sabotaged_days": int(biz.get("sabotaged_days", 0)), "sabotaged_today_day": int(biz.get("sabotaged_today_day", -1)),
			"stock_override": get_trade_stock_dict(role_int).duplicate()
		}
	var saved_merchant: Dictionary = _active_traveling_merchant.to_save_dict() if (is_instance_valid(_active_traveling_merchant) and not _active_traveling_merchant.is_dead) else {}
	var saved_investigator: Dictionary = _royal_investigator_npc.to_save_dict() if (is_instance_valid(_royal_investigator_npc) and not _royal_investigator_npc.is_dead) else {}
	var saved_pets: Array[Dictionary] = []
	for p in domestic_pets:
		if is_instance_valid(p) and p.has_method("to_save_dict"):
			saved_pets.append(p.to_save_dict())
	var saved_chests: Dictionary = {}
	for ch in house_chests:
		var ch_id: String = str(ch.get("title", ch.get("family_id", ch.get("id", ""))))
		if ch_id != "":
			saved_chests[ch_id] = {
				"looted_day": int(ch.get("looted_day", -1)),
				"planted_evidence": str(ch.get("planted_evidence", ""))
			}
	var saved_doors: Dictionary = {}
	for d_entry in building_doors:
		var d_id: String = str(d_entry.get("building_id", d_entry.get("id", "")))
		if d_id != "":
			saved_doors[d_id] = {
				"is_open": bool(d_entry.get("is_open", false)), "is_locked": bool(d_entry.get("is_locked", false)),
				"locked_by_player": bool(d_entry.get("locked_by_player", false)), "manual_override_timer": float(d_entry.get("manual_override_timer", 0.0)),
				"picked_until_hour": int(d_entry.get("picked_until_hour", -1)), "picked_day": int(d_entry.get("picked_day", -1))
			}
	var saved_windows: Dictionary = {}
	for w_entry in building_windows:
		var w_id: String = str(w_entry.get("building_id", w_entry.get("id", "")))
		if w_id != "":
			saved_windows[w_id] = {
				"is_shuttered": bool(w_entry.get("is_shuttered", false)), "manual_override_timer": float(w_entry.get("manual_override_timer", 0.0)),
				"picked_until_hour": int(w_entry.get("picked_until_hour", -1)), "picked_day": int(w_entry.get("picked_day", -1))
			}
	var saved_traps: Array[Dictionary] = []
	for trap_entry in _deployed_bear_traps:
		var tr_node: Node2D = trap_entry.get("node") as Node2D
		if is_instance_valid(tr_node):
			saved_traps.append({"x": tr_node.global_position.x, "y": tr_node.global_position.y})
	return {
		"businesses": out, "village_food_shortage_days": village_food_shortage_days, "house_pantry": house_pantry.duplicate(),
		"merchant_suspension_days": merchant_suspension_days.duplicate(), "active_royal_investigation": active_royal_investigation.duplicate(true),
		"active_sheriff_investigation": active_sheriff_investigation.duplicate(true),
		"active_traveling_merchant": saved_merchant, "royal_investigator_npc": saved_investigator, "domestic_pets": saved_pets,
		"player_arrests_count": player_arrests_count, "player_murder_warrants_count": player_murder_warrants_count,
		"recent_breakins_count": recent_breakins_count, "crime_history": crime_history.duplicate(), "arrivals_today_count": arrivals_today_count,
		"rehire_counter": _rehire_counter, "house_chests": saved_chests, "building_doors": saved_doors,
		"building_windows": saved_windows, "deployed_bear_traps": saved_traps,
		"used_first_names": _used_first_names.duplicate(),
		"used_person_ids": _used_person_ids.keys(),
		"newcomer_rng_state": _newcomer_rng.state,
		"social_event_log": social_event_log.duplicate(true),
		"chronicle": chronicle.duplicate(true),
		"chronicle_tiers": chronicle_tiers.duplicate(),
		"secrets": secrets.duplicate(true),
		"secret_uid": secret_uid,
		"desires": desires.duplicate(true),
		"desire_uid": desire_uid,
		"desire_hate_since": desire_hate_since.duplicate(),
		"npc_murders": npc_murders.duplicate(),
		"last_npc_murder_day": last_npc_murder_day,
		"faith_state": faith_state.duplicate(true),
		"needs_state": needs_state.duplicate(true),
		"town_state": town_state.duplicate(true),
		"lots_state": lots_state.duplicate(true),
		"places_state": places_state.duplicate(true),
		"culture_state": culture_state.duplicate(true),
		"migration_state": migration_state.duplicate(true),
		"nobility_state": nobility_state.duplicate(true),
		"family_state": family_state.duplicate(true),
		"work_state": work_state.duplicate(true),
		"sect_state": sect_state.duplicate(true),
		"player_elevation_level": player_elevation_level,
		"social_event_uid": _social_event_uid,
		"social_director": social_director.to_save_dict() if social_director != null else {}
	}

func _free_transient_npc(npc: VillageNPC) -> void:
	if not is_instance_valid(npc):
		return
	npc.remove_from_group("village_npcs")
	npc.remove_from_group("npcs")
	npc.name = "_freed_npc_" + str(npc.get_instance_id())
	if npc.get_parent():
		npc.get_parent().remove_child(npc)
	npc.queue_free()

## B4: el JSON del guardado convierte cada `Vector2` en el texto «(x, y)»; aquí se devuelven a `Vector2` dentro de los
## estados del pueblo (solo valores, nunca claves; un texto normal no tiene esa forma).
static var _vec_re: RegEx = null

static func revive_vectors(v):
	if v is Dictionary:
		for k in (v as Dictionary).keys():
			v[k] = revive_vectors(v[k])
		return v
	if v is Array:
		for i in range((v as Array).size()):
			v[i] = revive_vectors(v[i])
		return v
	if v is String and (v as String).begins_with("(") and (v as String).ends_with(")"):
		if _vec_re == null:
			_vec_re = RegEx.new()
			_vec_re.compile("^\\((-?(?:[0-9.]+(?:e[-+]?[0-9]+)?|inf)), (-?(?:[0-9.]+(?:e[-+]?[0-9]+)?|inf))\\)$")
		var m: RegExMatch = _vec_re.search(v)
		if m != null:
			return Vector2(float(m.get_string(1)), float(m.get_string(2)))
	return v

func load_economy_save_dict(data: Dictionary) -> void:
	for st_key in ["needs_state", "town_state", "lots_state", "places_state", "work_state", "culture_state", "migration_state", "nobility_state", "family_state", "faith_state"]:
		if typeof(data.get(st_key)) == TYPE_DICTIONARY:
			revive_vectors(data[st_key])
	village_food_shortage_days = int(data.get("village_food_shortage_days", 0))
	player_arrests_count = int(data.get("player_arrests_count", 0))
	player_murder_warrants_count = int(data.get("player_murder_warrants_count", 0))
	recent_breakins_count = int(data.get("recent_breakins_count", 0))
	arrivals_today_count = int(data.get("arrivals_today_count", 0))
	_rehire_counter = maxi(_rehire_counter, int(data.get("rehire_counter", _rehire_counter)))
	if data.has("used_first_names") and typeof(data["used_first_names"]) == TYPE_ARRAY:
		for fn_it in (data["used_first_names"] as Array):
			var fn_s: String = str(fn_it)
			if fn_s != "" and not (fn_s in _used_first_names):
				_used_first_names.append(fn_s)
	if data.has("used_person_ids") and typeof(data["used_person_ids"]) == TYPE_ARRAY:
		for pid_it in (data["used_person_ids"] as Array):
			var pid_s: String = str(pid_it)
			if pid_s != "":
				_used_person_ids[pid_s] = true
	if data.has("newcomer_rng_state"):
		_newcomer_rng.state = int(data["newcomer_rng_state"])
	if data.has("social_event_log") and typeof(data["social_event_log"]) == TYPE_ARRAY:
		social_event_log.clear()
		for ev_it in (data["social_event_log"] as Array):
			if typeof(ev_it) == TYPE_DICTIONARY:
				social_event_log.append((ev_it as Dictionary).duplicate())
		while social_event_log.size() > MAX_SOCIAL_EVENT_LOG:
			social_event_log.remove_at(0)
	_social_event_uid = int(data.get("social_event_uid", social_event_log.size()))
	chronicle_tiers = (data["chronicle_tiers"] as Dictionary).duplicate() if typeof(data.get("chronicle_tiers")) == TYPE_DICTIONARY else {}
	secrets.clear()
	if typeof(data.get("secrets")) == TYPE_ARRAY:
		for sc_it in (data["secrets"] as Array):
			if typeof(sc_it) == TYPE_DICTIONARY:
				secrets.append((sc_it as Dictionary).duplicate(true))
	secret_uid = int(data.get("secret_uid", secrets.size()))
	desires.clear()
	if typeof(data.get("desires")) == TYPE_ARRAY:
		for de_it in (data["desires"] as Array):
			if typeof(de_it) == TYPE_DICTIONARY:
				desires.append((de_it as Dictionary).duplicate(true))
	desire_uid = int(data.get("desire_uid", desires.size()))
	desire_hate_since = (data["desire_hate_since"] as Dictionary).duplicate() if typeof(data.get("desire_hate_since")) == TYPE_DICTIONARY else {}
	npc_murders = (data["npc_murders"] as Dictionary).duplicate() if typeof(data.get("npc_murders")) == TYPE_DICTIONARY else {}
	last_npc_murder_day = int(data.get("last_npc_murder_day", -9999))
	faith_state = (data["faith_state"] as Dictionary).duplicate(true) if typeof(data.get("faith_state")) == TYPE_DICTIONARY else {}
	faith_bands = []
	needs_state = (data["needs_state"] as Dictionary).duplicate(true) if typeof(data.get("needs_state")) == TYPE_DICTIONARY else {}
	VillageNeeds.drunk_now = (VillageNeeds.state(self)["drunk"] as Dictionary).duplicate()
	town_state = (data["town_state"] as Dictionary).duplicate(true) if typeof(data.get("town_state")) == TYPE_DICTIONARY else {}
	(func(): VillageCase1.sync(self)).call_deferred() # Caso I: tras cargar, recoloca hoja y secuestradores según lo guardado
	sect_state = (data["sect_state"] as Dictionary).duplicate(true) if typeof(data.get("sect_state")) == TYPE_DICTIONARY else {}
	lots_state = (data["lots_state"] as Dictionary).duplicate(true) if typeof(data.get("lots_state")) == TYPE_DICTIONARY else {}
	VillageLots.after_load(self)
	VillageHousing.sync_livestock(self)
	VillageHousing.sync_home_props(self)
	places_state = (data["places_state"] as Dictionary).duplicate(true) if typeof(data.get("places_state")) == TYPE_DICTIONARY else {}
	work_state = (data["work_state"] as Dictionary).duplicate(true) if typeof(data.get("work_state")) == TYPE_DICTIONARY else {}
	VillageWork.after_load(self)
	culture_state = (data["culture_state"] as Dictionary).duplicate(true) if typeof(data.get("culture_state")) == TYPE_DICTIONARY else {}
	VillageCulture.after_load(self)
	if data.has("player_elevation_level"):
		set_player_elevation_level(int(data.get("player_elevation_level", 0)))
	VillageUnderworld.after_load(self)
	migration_state = (data["migration_state"] as Dictionary).duplicate(true) if typeof(data.get("migration_state")) == TYPE_DICTIONARY else {}
	VillageMigration.after_load(self)
	nobility_state = (data["nobility_state"] as Dictionary).duplicate(true) if typeof(data.get("nobility_state")) == TYPE_DICTIONARY else {}
	family_state = (data["family_state"] as Dictionary).duplicate(true) if typeof(data.get("family_state")) == TYPE_DICTIONARY else {}
	VillageFamily.after_load(self)
	# B4: retomar o cancelar limpio lo que estaba a medias al guardar (recados, club, cenas)
	VillageNightJobs.after_load(self)
	VillageClub.after_load(self)
	VillageHousing.after_load_gathering(self)
	VillageSect._update_band(self)
	VillageFamilia.after_load(self)
	if data.has("chronicle") and typeof(data["chronicle"]) == TYPE_ARRAY:
		chronicle.clear()
		for ch_it in (data["chronicle"] as Array):
			if typeof(ch_it) == TYPE_DICTIONARY:
				chronicle.append((ch_it as Dictionary).duplicate())
		while chronicle.size() > VillageChronicle.MAX_ENTRIES:
			chronicle.remove_at(0)
	else:
		VillageChronicle.seed_from_social_log(self) # Partidas de antes de la crónica
	for live_fight in _live_fights:
		for fighter in [live_fight["a"], live_fight["b"]]:
			if is_instance_valid(fighter):
				fighter.end_live_fight()
	_live_fights.clear()
	if data.has("social_director") and typeof(data["social_director"]) == TYPE_DICTIONARY and social_director != null:
		social_director.from_save_dict(data["social_director"] as Dictionary)
	if data.has("crime_history") and typeof(data["crime_history"]) == TYPE_ARRAY:
		crime_history.clear()
		for ch_item in (data["crime_history"] as Array):
			crime_history.append(str(ch_item))
	if data.has("house_chests") and typeof(data["house_chests"]) == TYPE_DICTIONARY:
		var sc: Dictionary = data["house_chests"]
		for ch in house_chests:
			var ch_title_key: String = str(ch.get("title", ""))
			var ch_fam_key: String = str(ch.get("family_id", ch.get("id", "")))
			var match_key: String = ch_title_key if sc.has(ch_title_key) else (ch_fam_key if sc.has(ch_fam_key) else "")
			if match_key != "":
				var raw_ch: Variant = sc[match_key]
				if typeof(raw_ch) == TYPE_DICTIONARY:
					var ch_d: Dictionary = raw_ch as Dictionary
					ch["looted_day"] = int(ch_d.get("looted_day", -1))
					ch["planted_evidence"] = str(ch_d.get("planted_evidence", ""))
				else:
					ch["looted_day"] = int(raw_ch)
					ch["planted_evidence"] = ""
			else:
				ch["looted_day"] = -1
				ch["planted_evidence"] = ""
	if data.has("building_doors") and typeof(data["building_doors"]) == TYPE_DICTIONARY:
		var sd: Dictionary = data["building_doors"]
		for d_entry in building_doors:
			var d_id: String = str(d_entry.get("building_id", d_entry.get("id", "")))
			if sd.has(d_id) and typeof(sd[d_id]) == TYPE_DICTIONARY:
				var de: Dictionary = sd[d_id]
				d_entry["is_open"] = bool(de.get("is_open", false))
				d_entry["is_locked"] = bool(de.get("is_locked", false))
				d_entry["locked_by_player"] = bool(de.get("locked_by_player", false))
				d_entry["manual_override_timer"] = float(de.get("manual_override_timer", 0.0))
				d_entry["picked_until_hour"] = int(de.get("picked_until_hour", -1))
				d_entry["picked_day"] = int(de.get("picked_day", -1))
				_refresh_door_visual_and_collision(d_entry)
	if data.has("building_windows") and typeof(data["building_windows"]) == TYPE_DICTIONARY:
		var sw: Dictionary = data["building_windows"]
		for w_entry in building_windows:
			var w_id: String = str(w_entry.get("building_id", w_entry.get("id", "")))
			if sw.has(w_id) and typeof(sw[w_id]) == TYPE_DICTIONARY:
				var we: Dictionary = sw[w_id]
				var shut: bool = bool(we.get("is_shuttered", we.get("is_locked", false)))
				w_entry["is_shuttered"] = shut
				w_entry["manual_override_timer"] = float(we.get("manual_override_timer", 0.0))
				w_entry["picked_until_hour"] = int(we.get("picked_until_hour", -1))
				w_entry["picked_day"] = int(we.get("picked_day", -1))
	for trap_entry in _deployed_bear_traps:
		var trap_node: Node2D = trap_entry.get("node") as Node2D
		if is_instance_valid(trap_node):
			trap_node.queue_free()
	_deployed_bear_traps.clear()
	if data.has("deployed_bear_traps") and typeof(data["deployed_bear_traps"]) == TYPE_ARRAY:
		for t_item in (data["deployed_bear_traps"] as Array):
			if typeof(t_item) == TYPE_DICTIONARY:
				var td: Dictionary = t_item
				deploy_steel_bear_trap(Vector2(float(td.get("x", 0.0)), float(td.get("y", 0.0))))
	if data.has("house_pantry") and typeof(data["house_pantry"]) == TYPE_DICTIONARY:
		house_pantry = (data["house_pantry"] as Dictionary).duplicate()
	if data.has("merchant_suspension_days") and typeof(data["merchant_suspension_days"]) == TYPE_DICTIONARY:
		merchant_suspension_days = (data["merchant_suspension_days"] as Dictionary).duplicate()
	# Reconciliar los nodos dinámicos ya restaurados por GameManager antes de evaluar mercaderes e Inquisidor para evitar duplicados
	reconcile_npc_registries_after_load()
	if data.has("active_traveling_merchant") and typeof(data["active_traveling_merchant"]) == TYPE_DICTIONARY:
		var m_data: Dictionary = data["active_traveling_merchant"] as Dictionary
		if m_data.is_empty() or bool(m_data.get("is_dead", false)):
			if is_instance_valid(_active_traveling_merchant) and not _active_traveling_merchant.is_dead:
				_free_transient_npc(_active_traveling_merchant)
				_active_traveling_merchant = null
		else:
			var m_id_saved: String = str(m_data.get("merchant_id", "casimir"))
			if is_instance_valid(_active_traveling_merchant) and _active_traveling_merchant.merchant_id != m_id_saved and not _active_traveling_merchant.is_dead:
				_free_transient_npc(_active_traveling_merchant)
				_active_traveling_merchant = null
			if not is_instance_valid(_active_traveling_merchant):
				_check_weekly_merchant_arrival(3 if m_id_saved == "casimir" else 6, true, true)
			if is_instance_valid(_active_traveling_merchant):
				_active_traveling_merchant.from_save_dict(m_data)
	if data.has("active_sheriff_investigation") and typeof(data["active_sheriff_investigation"]) == TYPE_DICTIONARY:
		active_sheriff_investigation = (data["active_sheriff_investigation"] as Dictionary).duplicate(true)
		if typeof(active_sheriff_investigation.get("suspects")) == TYPE_DICTIONARY:
			var s_dict: Dictionary = active_sheriff_investigation["suspects"]
			for sk in s_dict.keys():
				if typeof(s_dict[sk]) == TYPE_DICTIONARY and (s_dict[sk] as Dictionary).has("score"):
					s_dict[sk]["score"] = int(s_dict[sk]["score"])
	if data.has("active_royal_investigation") and typeof(data["active_royal_investigation"]) == TYPE_DICTIONARY:
		active_royal_investigation = (data["active_royal_investigation"] as Dictionary).duplicate(true)
		if typeof(active_royal_investigation.get("suspects")) == TYPE_DICTIONARY:
			var r_dict: Dictionary = active_royal_investigation["suspects"]
			for rk in r_dict.keys():
				if typeof(r_dict[rk]) == TYPE_DICTIONARY and (r_dict[rk] as Dictionary).has("score"):
					r_dict[rk]["score"] = int(r_dict[rk]["score"])
		var inv_data: Dictionary = data.get("royal_investigator_npc", {}) if typeof(data.get("royal_investigator_npc", {})) == TYPE_DICTIONARY else {}
		if bool(active_royal_investigation.get("active", false)):
			if not inv_data.is_empty() and not bool(inv_data.get("is_dead", false)):
				if not is_instance_valid(_royal_investigator_npc):
					_spawn_royal_investigator()
				if is_instance_valid(_royal_investigator_npc):
					_royal_investigator_npc.from_save_dict(inv_data)
			if str(active_royal_investigation.get("stage", "")) == "HUNTING_PLAYER" and not player_in_jail and not player_being_escorted_to_jail:
				is_resisting_arrest = true
				alert_police_to_resist()
				if is_instance_valid(_royal_investigator_npc) and not _royal_investigator_npc.is_dead:
					_royal_investigator_npc.is_hostile = true
					if not _royal_investigator_npc.is_in_group("enemies"):
						_royal_investigator_npc.add_to_group("enemies")
		else:
			if is_instance_valid(_royal_investigator_npc) and not _royal_investigator_npc.is_dead:
				_free_transient_npc(_royal_investigator_npc)
				_royal_investigator_npc = null
	if data.has("domestic_pets") and typeof(data["domestic_pets"]) == TYPE_ARRAY:
		var p_arr: Array = data["domestic_pets"] as Array
		for p_item in p_arr:
			if typeof(p_item) == TYPE_DICTIONARY:
				var p_dict: Dictionary = p_item as Dictionary
				var p_name_target: String = str(p_dict.get("pet_name", ""))
				for pet_node in domestic_pets:
					if is_instance_valid(pet_node) and pet_node.pet_name == p_name_target and pet_node.has_method("from_save_dict"):
						pet_node.from_save_dict(p_dict)
						break
	# Reconciliar primero los registros de NPCs vivos para que `trade_npcs` apunte a los titulares actuales antes de aplicar `stock_override`
	reconcile_npc_registries_after_load()
	VillageJustice.after_load(self)
	VillageHousing.sync_relocated_camp_assets(self, false)
	VillageHousing.sync_livestock(self)

	var b_dict: Variant = data.get("businesses", {})
	if typeof(b_dict) != TYPE_DICTIONARY:
		refresh_world_stage_3d()
		return
	var saved_b: Dictionary = b_dict as Dictionary
	for k_str in saved_b.keys():
		var role_int: int = int(str(k_str))
		if shop_businesses.has(role_int) and typeof(saved_b[k_str]) == TYPE_DICTIONARY:
			var entry: Dictionary = saved_b[k_str]
			var biz: Dictionary = shop_businesses[role_int]
			biz["owner_mode"] = str(entry.get("owner_mode", "NPC"))
			biz["vault_gold"] = int(entry.get("vault_gold", 0))
			biz["sabotaged_days"] = int(entry.get("sabotaged_days", 0))
			biz["sabotaged_today_day"] = int(entry.get("sabotaged_today_day", -1))
			if entry.has("stock_override") and typeof(entry["stock_override"]) == TYPE_DICTIONARY:
				biz["stock_override"] = (entry["stock_override"] as Dictionary).duplicate()
				var holder: VillageNPC = trade_npcs.get(role_int)
				if is_instance_valid(holder) and not holder.is_dead:
					holder.shop_stock = (entry["stock_override"] as Dictionary).duplicate()
			_refresh_shop_stall_visual(role_int)
	refresh_world_stage_3d()

func spawn_dynamic_npc_from_save(node_name: String, npc_data: Dictionary) -> VillageNPC:
	if not is_instance_valid(entities_root):
		return null
	var existing := entities_root.get_node_or_null(node_name) as VillageNPC
	if is_instance_valid(existing):
		existing.from_save_dict(npc_data)
		return existing
	var dyn_npc := VillageNPC.new()
	dyn_npc.name = node_name
	dyn_npc.npc_name = str(npc_data.get("npc_name", "Aldeano"))
	dyn_npc.npc_role = str(npc_data.get("npc_role", "Habitante"))
	dyn_npc.trade_role = int(npc_data.get("trade_role", int(VillageNPC.TradeRole.UNEMPLOYED))) as VillageNPC.TradeRole
	dyn_npc.linked_trade = int(npc_data.get("linked_trade", int(dyn_npc.trade_role))) as VillageNPC.TradeRole
	dyn_npc.tavern_social_pos = _tavern_social_pos
	if npc_data.has("person_profile") and typeof(npc_data["person_profile"]) == TYPE_DICTIONARY:
		dyn_npc.person_profile = PersonProfile.from_dict(npc_data["person_profile"])
	entities_root.add_child(dyn_npc)
	var default_tex := _load_tex("res://assests/world/village/villager_traveler.png")
	var def_bed: Vector2 = VillageTavern.guest_beds()[0]
	dyn_npc.setup_npc(
		default_tex, Vector2(float(npc_data.get("work_x", 440.0)), float(npc_data.get("work_y", 44.0))),
		Vector2(float(npc_data.get("bed_x", def_bed.x)), float(npc_data.get("bed_y", def_bed.y))), {},
		Vector2(float(npc_data.get("table_x", _tavern_social_pos.x)), float(npc_data.get("table_y", _tavern_social_pos.y))),
		str(npc_data.get("family_id", "none")), str(npc_data.get("family_name", "Independiente"))
	)
	dyn_npc.from_save_dict(npc_data)
	if dyn_npc.person_profile != null and str(dyn_npc.person_profile.person_id) != "":
		_used_person_ids[str(dyn_npc.person_profile.person_id)] = true
	var first_tok: String = dyn_npc.npc_name.strip_edges().split(" ", false)[0] if dyn_npc.npc_name.strip_edges() != "" else ""
	if first_tok != "" and not (first_tok in _used_first_names):
		_used_first_names.append(first_tok)
	return dyn_npc

func reconcile_npc_registries_after_load() -> void:
	for camp_key in vagrant_camp_nodes.keys():
		var c_node: Node2D = vagrant_camp_nodes[camp_key]
		if is_instance_valid(c_node):
			c_node.visible = false
	trade_npcs.clear()
	family_npcs.clear()
	unemployed_npcs.clear()
	authority_npcs.clear()
	_innkeeper_npc = null
	_royal_investigator_npc = null
	_active_traveling_merchant = null
	for slot in _authority_slots:
		slot["npc"] = null
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			v.tavern_social_pos = sitio(_tavern_social_pos) # los vecinos guardan sitios del mundo
			if v.home_table_pos.distance_to(sitio(Vector2(376.0, -184.0))) < 2.0:
				v.home_table_pos = sitio(_tavern_social_pos)
			if v.trade_role == VillageNPC.TradeRole.ROYAL_INVESTIGATOR and not v.is_dead and not str(v.name).begins_with("NPC_Royal_Investigator_Corpse_"):
				_royal_investigator_npc = v
			elif v.trade_role == VillageNPC.TradeRole.TRAVELING_MERCHANT and not v.is_dead and not str(v.name).begins_with("NPC_Merchant_Corpse_"):
				_active_traveling_merchant = v
			var r_int: int = int(v.trade_role)
			if (v.trade_role in VillageNPC.SHOP_ROLES or v.trade_role == VillageNPC.TradeRole.WAITER) and not v.is_dead:
				trade_npcs[r_int] = v
				if trade_configs.has(r_int):
					v.work_position = (trade_configs[r_int] as Dictionary).get("work_pos", v.work_position)
			elif v.trade_role == VillageNPC.TradeRole.FAMILY_MEMBER and not v.is_dead:
				family_npcs[int(v.linked_trade)] = v
				if v.npc_name == VillageFamilia.INITIAL_BOSS_NAME:
					v.work_position = VillageRestaurant.dining_tables()[VillageRestaurant.MESA_JEFE]
					v.bed_position = VillageRestaurant.sitio(VillageRestaurant.M_CAMA_2)
					v.home_table_pos = VillageRestaurant.sitio(VillageRestaurant.M_RESERVADO)
				elif trade_configs.has(int(v.linked_trade)):
					var l_cfg: Dictionary = trade_configs[int(v.linked_trade)]
					v.work_position = l_cfg.get("kin_work_pos", l_cfg.get("work_pos", v.work_position))
			elif v.trade_role == VillageNPC.TradeRole.TEACHER and not v.is_dead:
				v.work_position = VillageLots.building_center("e3") + Vector2(0, -16)
			elif v.trade_role == VillageNPC.TradeRole.NOBLE and not v.is_dead:
				var n_lot: String = "f1" if v.family_id == "family_vane" else ("f2" if v.family_id == "family_solis" else "")
				if n_lot != "":
					v.work_position = sitio(VillageNobility.study_pos(n_lot))
			elif v.trade_role == VillageNPC.TradeRole.UNEMPLOYED and not v.is_dead:
				unemployed_npcs.append(v)
			elif v.trade_role == VillageNPC.TradeRole.INNKEEPER and not v.is_dead:
				_innkeeper_npc = v
				v.work_position = VillageTavern.sitio(VillageTavern.M_TRABAJO)
				v.bed_position = VillageTavern.sitio(VillageTavern.M_CAMA_MARTA)
				v.home_table_pos = VillageTavern.sitio(VillageTavern.M_MESA_CENTRAL)
			elif v.trade_role in [VillageNPC.TradeRole.DOCTOR, VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.PRIEST] and not v.is_dead:
				authority_npcs.append(v)
				trade_npcs[r_int] = v
				for slot in _authority_slots:
					if int(slot.get("role", -1)) == r_int:
						slot["npc"] = v
						slot["rehire_timer"] = 0.0
						slot["vacancy_announced"] = false
						v.work_position = slot.get("work_pos", v.work_position)
			if v.is_vagrant_camper and not v.is_dead and not v.in_shelter:
				_spawn_or_update_vagrant_camp_visual(v, v.vagrant_camp_pos)


## Editor del mapa 3D (2026-11-10): los objetos que el juego crea sin pasar por las funciones _add_* (huertos, gallinero,
## animales de granja con su corral, campamento, muro débil, cajas y carteles con uso, carro y caballo) también siguen
## a las anclas del editor (mapa/anclas.gd).
## Plan de sitios, paso 1 (docs/PLAN_SITIOS.md, 2026-11-10): cama, mesa y puesto de trabajo de los vecinos y de los
## oficios (trade_configs) se escriben en coordenadas del mapa original; aquí se traducen UNA vez a su sitio actual
## (edificio movido o girado, mueble movido). Las marcas evitan traducir dos veces.
const SITIOS_CAMPOS_CFG: Array[String] = ["work_pos", "kin_work_pos", "bed1_pos", "bed2_pos", "table_pos", "stall_pos"]
const SITIOS_CAMPOS_NPC: Array[String] = ["bed_position", "home_table_pos", "work_position", "tavern_social_pos"]

func _sitios_cfg(AN) -> void:
	for k in trade_configs.keys():
		var cfg: Dictionary = trade_configs[k]
		if cfg.get("_sitios", false):
			continue
		cfg["_sitios"] = true
		for campo in SITIOS_CAMPOS_CFG:
			if cfg.get(campo) is Vector2 and cfg[campo] != Vector2.ZERO:
				if campo == "work_pos" and cfg.has("anexo_lot"):
					cfg[campo] = VillageLots.anexo(self, str(cfg["anexo_lot"]), cfg[campo]) # puesto pegado a su edificio
				else:
					cfg[campo] = AN.mover(cfg[campo])


func _sitios_repaso(AN) -> void:
	_sitios_cfg(AN)
	for n in get_tree().get_nodes_in_group("village_npcs"):
		sitios_traducir_npc(n)
	# Pozos: la lista de pozos es del mundo (se compara con posiciones reales); los tres fijos van por las anclas
	if _well_positions.size() >= 3:
		_well_positions[0] = sitio(_well_pos)
		_well_positions[1] = sitio(_tavern_well_pos)
		_well_positions[2] = sitio(_plaza_well_pos)


## Traduce una vez los sitios de un vecino creado con coordenadas del mapa original.
func sitios_traducir_npc(n: Node) -> void:
	if n == null or n.has_meta("sitios_ok"):
		return
	n.set_meta("sitios_ok", true)
	var AN = load("res://mapa/anclas.gd")
	for campo in SITIOS_CAMPOS_NPC:
		var v = n.get(campo)
		if v is Vector2 and v != Vector2.ZERO:
			n.set(campo, AN.mover(v))


func _anclas_repaso_final() -> void:
	var AN = load("res://mapa/anclas.gd")
	_sitios_repaso(AN)
	var clases := ["FarmPlot.gd", "ChickenCoop.gd", "CampSite.gd", "LivestockAnimal.gd", "DestructibleObject.gd", "WorldInteractableProp.gd", "PlayerCart.gd", "PlayerHorse.gd"]
	for c in entities_root.get_children():
		if not (c is Node2D) or c is HarvestableNode or c.get_script() == null:
			continue
		var f: String = String(c.get_script().resource_path).get_file()
		if not (f in clases):
			continue
		if c.is_in_group("club_world") or String(c.name).begins_with("Sewer"):
			continue # bajo tierra y sus trampillas ya se colocan solos (VillageClub / VillageUnderworld)
		var p0: Vector2 = (c as Node2D).global_position
		var a_obj: Dictionary = AN.buscar(p0)
		var p1: Vector2 = AN.mover(p0, "objeto", f.get_basename() + ":" + String(c.name))
		var d := p1 - p0
		if d == Vector2.ZERO:
			continue
		(c as Node2D).global_position = p1
		if c.get("pen_rect") is Rect2 and (c.get("pen_rect") as Rect2).has_area():
			c.set("pen_rect", AN.rect_con(a_obj, c.get("pen_rect") as Rect2))
