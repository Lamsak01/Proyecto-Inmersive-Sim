@tool
extends "res://scripts/enemies/VillageNPCDuties.gd"
const Zona = preload("res://mapa/zona.gd")
const PisosCasas = preload("res://scripts/fisica/PisosCasas.gd") # casas de dos plantas: camas de arriba
const ZONA_CIENAGA := "cienaga"


func _setup_craft_progress_bar_ui() -> void:
	_craft_bar_root = Node2D.new()
	_craft_bar_root.name = "CraftProgressBar"
	_craft_bar_root.position = Vector2(0, -25)
	_craft_bar_root.z_index = 18
	_craft_bar_root.visible = false
	add_child(_craft_bar_root)

	_craft_bar_bg = Polygon2D.new()
	_craft_bar_bg.color = Color(0.07, 0.08, 0.11, 0.88)
	_craft_bar_bg.polygon = PackedVector2Array([Vector2(-20, -3), Vector2(20, -3), Vector2(20, 2), Vector2(-20, 2)])
	_craft_bar_root.add_child(_craft_bar_bg)

	_craft_bar_fill = Polygon2D.new()
	_craft_bar_fill.color = Color(0.98, 0.78, 0.24, 0.95)
	_craft_bar_fill.polygon = PackedVector2Array([Vector2(-19, -2), Vector2(-19, -2), Vector2(-19, 1), Vector2(-19, 1)])
	_craft_bar_root.add_child(_craft_bar_fill)

	_craft_bar_label = Label.new()
	_style_label(_craft_bar_label, Vector2(-80, -14), Vector2(160, 11), 7, Color(1.0, 0.95, 0.75), 2)
	_craft_bar_root.add_child(_craft_bar_label)

func _init_workshop_materials() -> void:
	_craft_progress = randf_range(5.0, 42.0)
	_supply_run_cooldown = randf_range(10.0, 34.0)
	workshop_materials = (ROLE_INITIAL_MATERIALS.get(trade_role, {}) as Dictionary).duplicate()
	if pocket_items.is_empty():
		_init_npc_pockets()

func _init_npc_pockets() -> void:
	pocket_items.clear()
	match trade_role:
		TradeRole.BLACKSMITH:
			pocket_items = {"bread": 1, "iron_ore": 1}
		TradeRole.CARPENTER:
			pocket_items = {"bread": 1, "wood": 2}
		TradeRole.BUTCHER:
			pocket_items = {"cooked_meat": 1, "leather": 1}
		TradeRole.HERBALIST:
			pocket_items = {"herbal_poultice": 1, "herbs": 2}
		TradeRole.FISHMONGER:
			pocket_items = {"bread": 1, "cooked_fish": 1}
		TradeRole.INNKEEPER:
			pocket_items = {"country_stew": 1, "bread": 1}
		TradeRole.DOCTOR:
			pocket_items = {"surgical_kit": 1, "bandage": 2}
		TradeRole.SHERIFF, TradeRole.GUARD:
			pocket_items = {"bandage": 1, "bread": 1}
		TradeRole.TRAVELING_MERCHANT:
			pocket_items = {"royal_safe_conduct": 1, "royal_ration": 1}
			carries_royal_safe_conduct = true
		TradeRole.ROYAL_INVESTIGATOR:
			pocket_items = {"royal_ration": 1, "bandage": 1}
		_:
			pocket_items = {"bread": 1}
	if carries_royal_safe_conduct:
		pocket_items["royal_safe_conduct"] = maxi(1, int(pocket_items.get("royal_safe_conduct", 0)))

func _init_rimworld_psychology() -> void:
	if ROLE_PSYCHOLOGY.has(trade_role):
		var entry: Array = ROLE_PSYCHOLOGY[trade_role]
		traits.assign(entry[0])
		favorite_item = str(entry[1])
		thoughts.assign(entry[2])
	else:
		var pool_traits: Array[String] = ["Alegre", "Tahúr", "Glotón", "Noctámbulo", "Amante de Animales", "Curioso", "Leal"]
		var idx1: int = abs(npc_name.hash()) % pool_traits.size()
		traits = [pool_traits[idx1], pool_traits[(idx1 + 3) % pool_traits.size()]]
		var fav_pool: Array[String] = ["bread", "cooked_meat", "roasted_chicken", "country_stew", "cooked_fish"]
		favorite_item = fav_pool[abs(npc_name.hash()) % fav_pool.size()]
		thoughts = ["Paseando por el valle (+5)"]
	_init_person_profile()
	mood = clampf(78.0 + randf_range(-6.0, 12.0), 40.0, 98.0)

func _init_person_profile() -> void:
	var clean_name := npc_name.strip_edges()
	var lookup_name: String = str(NPC_NAME_ALIASES.get(clean_name, clean_name))
	if person_profile == null:
		if INITIAL_PERSON_PROFILES.has(lookup_name):
			person_profile = PersonProfile.from_dict(INITIAL_PERSON_PROFILES[lookup_name])
		else:
			person_profile = PersonProfile.make_fallback_for_name(clean_name)
	if person_profile != null:
		npc_id = str(person_profile.person_id)
		if not person_profile.personality.is_empty():
			traits.assign(person_profile.personality)
		if str(person_profile.favorite_item) != "":
			favorite_item = str(person_profile.favorite_item)
	if founder_secrets.is_empty() and NPCData.FOUNDER_SECRETS_POOL.has(lookup_name):
		var pool_arr: Array = NPCData.FOUNDER_SECRETS_POOL[lookup_name]
		var s_rng := RandomNumberGenerator.new()
		s_rng.seed = abs(("fsec:" + lookup_name).hash()) ^ int(Time.get_ticks_usec() & 0x7FFF)
		var indices: Array[int] = []
		for pi in range(pool_arr.size()):
			indices.append(pi)
		for pi in range(indices.size() - 1, 0, -1):
			var swap_idx: int = s_rng.randi_range(0, pi)
			var tmp_i: int = indices[pi]
			indices[pi] = indices[swap_idx]
			indices[swap_idx] = tmp_i
		var pick_count: int = clampi(s_rng.randi_range(2, 3), 2, indices.size())
		for k_idx in range(pick_count):
			founder_secrets.append((pool_arr[indices[k_idx]] as Dictionary).duplicate(true))

func get_portrait_texture() -> Texture2D:
	return portrait_texture if portrait_texture != null else (sprite.texture if sprite else null)

func get_character_tagline() -> String:
	return character_tagline

func _load_64_tex(res_path: String) -> Texture2D:
	if _tex_64_cache.has(res_path) and _tex_64_cache[res_path] is Texture2D:
		return _tex_64_cache[res_path] as Texture2D
	var abs_p := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_p):
		var img := Image.load_from_file(abs_p)
		if img and not img.is_empty():
			var itex := ImageTexture.create_from_image(img)
			_tex_64_cache[res_path] = itex
			return itex
	if ResourceLoader.exists(res_path):
		var t = load(res_path)
		if t is Texture2D:
			_tex_64_cache[res_path] = t
			return t
	return null

func _resolve_unique_64_visuals_and_lore(fallback_tex: Texture2D = null) -> void:
	var clean_name := npc_name.strip_edges()
	var lookup_name: String = str(NPC_NAME_ALIASES.get(clean_name, clean_name))
	var key := "aldric"
	if NPC_LORE_PROFILES.has(lookup_name):
		var p: Array = NPC_LORE_PROFILES[lookup_name]
		key = str(p[0])
		character_tagline = str(p[1])
		character_lore = str(p[2])
		character_secret = str(p[3])
	else:
		var fem: bool = (person_profile != null and str(person_profile.gender) == "F") or (person_profile == null and clean_name.ends_with("a"))
		var fb: Array = ROLE_FALLBACK_LORE.get(trade_role, ["bram", "mila", "Artesano profesional llegado de los valles vecinos para hacerse cargo del taller y mantener viva la economía local."])
		key = str(fb[1] if fem else fb[0])
		character_tagline = str(fb[2])
		character_lore = "«Llegué al valle tras escuchar que la comunidad necesitaba manos expertas. No vengo a hacer preguntas sobre lo que le ocurrió a mi predecesor: mientras haya trabajo y corra el oro, cumpliré mi jornada de sol a sol.»"
		character_secret = "«En este pueblo las paredes oyen y las puertas cerradas guardan más de un secreto. Conviene llevarse bien con los vecinos si quieres prosperar aquí.»"
		match trade_role: # V6/V9: historias que no son de forastero recién llegado
			TradeRole.CHILD:
				character_lore = "«Nací aquí, en el valle. Mis padres dicen que pregunto demasiado. Cuando sea mayor quiero tener mi propio taller... o irme lejos, todavía no lo sé.»"
				character_secret = "«Sé dónde se esconden los mayores cuando no quieren que los vean. Los niños nos fijamos en todo.»"
			TradeRole.NOBLE:
				character_lore = "«Mi familia lleva generaciones cobrando las rentas de estas tierras. El pueblo nos mira con respeto... o con envidia, según el día.»"
				character_secret = "«Las cuentas de la casa no van tan bien como aparentamos. Que nadie lo sepa.»"
			TradeRole.TEACHER:
				character_lore = "«Alguien tiene que enseñar a leer y a contar a los críos del valle. No es mal oficio, aunque las arcas paguen tarde.»"

	var anim_64 := _load_64_tex("res://assests/world/village/npcs_64/anim_%s.png" % key)
	var spr_64 := _load_64_tex("res://assests/world/village/npcs_64/sprite_%s.png" % key)
	var port_64 := _load_64_tex("res://assests/world/village/npcs_64/portrait_%s.png" % key)
	if sprite != null:
		if anim_64 != null:
			sprite.texture = anim_64
			sprite.hframes = 4
			sprite.vframes = 3
			sprite.frame = 0
			_has_spritesheet_anim = true
		elif spr_64 != null or fallback_tex != null:
			sprite.texture = spr_64 if spr_64 != null else fallback_tex
			sprite.hframes = 1
			sprite.vframes = 1
			_has_spritesheet_anim = false
	portrait_texture = port_64 if port_64 != null else (spr_64 if spr_64 != null else fallback_tex)

func _update_needs_and_decisions(delta: float) -> void:
	var is_night_env: bool = WorldClock != null and (WorldClock.current_hour >= 22 or WorldClock.current_hour < 6)
	var in_work_shift: bool = _is_mandatory_work_hours()
	var busy_eating: bool = (current_activity == ActivityState.EATING and not _is_amateur_foraging and _sitting_meal_ingested < 36.0 and (need_hunger + digestion_buffer) < 96.0)

	if in_work_shift and current_activity != ActivityState.WORKING and not busy_eating and (need_hunger > 22.0 or digestion_buffer > 5.0):
		is_sleeping = false
		_is_amateur_foraging = false
		_social_partner = null
		current_activity = ActivityState.WORKING
	elif in_work_shift and need_hunger <= 22.0 and digestion_buffer <= 2.0 and current_activity == ActivityState.WORKING:
		current_activity = ActivityState.EATING
		_eat_at_tavern = _choose_preferred_meal_location()

	if digestion_buffer > 0.0:
		var absorb_step: float = minf(digestion_buffer, 0.42 * delta)
		digestion_buffer = maxf(0.0, digestion_buffer - absorb_step)
		need_hunger = minf(100.0, need_hunger + absorb_step)

	var base_3day_hunger_rate: float = 0.092 * _hunger_decay_rate
	var malnutrition_fatigue_mult: float = lerpf(1.25, 1.0, clampf(need_hunger / 60.0, 0.0, 1.0))

	if current_activity != ActivityState.EATING:
		_restaurant_seat = Vector2.ZERO
		if current_activity != ActivityState.SOCIALIZING:
			_tavern_seat = Vector2.ZERO
		_meal_consumed_this_sitting = false
		_has_valid_meal_this_sitting = false
		_sitting_meal_ingested = 0.0
		_is_amateur_foraging = false

	match current_activity:
		ActivityState.WORKING:
			is_sleeping = false
			var work_mult: float = 1.10 if (trade_role != TradeRole.UNEMPLOYED and trade_role != TradeRole.FAMILY_MEMBER) else 0.90
			if digestion_buffer <= 0.0:
				need_hunger = maxf(0.0, need_hunger - base_3day_hunger_rate * work_mult * delta)
			need_energy = maxf(0.0, need_energy - _energy_decay_rate * (1.35 if is_night_env else 0.95) * malnutrition_fatigue_mult * delta)
			need_social = maxf(0.0, need_social - _social_decay_rate * 0.65 * delta)

		ActivityState.EATING:
			is_sleeping = false
			if _is_amateur_foraging:
				if digestion_buffer <= 0.0:
					need_hunger = maxf(0.0, need_hunger - base_3day_hunger_rate * 1.15 * delta)
				need_energy = maxf(0.0, need_energy - 0.42 * delta)
			else:
				var vm_chk = _get_vm()
				if _eat_at_tavern and vm_chk and vm_chk.has_method("is_building_door_blocked") and bool(vm_chk.call("is_building_door_blocked", "tavern")):
					_eat_at_tavern = false
					_spawn_floating_text("🚪🔒 ¡Taberna bloqueada! Iré a comer en casa / buscar suministros", Color.GOLD, -36.0)
				var meal_pos: Vector2 = _current_meal_pos()
				if global_position.distance_to(meal_pos) <= 22.0:
					if not _meal_consumed_this_sitting:
						_meal_consumed_this_sitting = true
						if _restaurant_seat != Vector2.ZERO:
							_has_valid_meal_this_sitting = _VillageRestaurant.serve_meal(vm_chk, self)
							if not _has_valid_meal_this_sitting:
								_restaurant_seat = Vector2.ZERO # R1b: no queda plato (o el cocinero no está): a comer a casa
								_meal_consumed_this_sitting = false
								_spawn_floating_text("🍝🚫 No sirven nada: comeré en casa", Color.LIGHT_GRAY, -32.0)
						elif _consume_pocket_meal_if_any():
							_has_valid_meal_this_sitting = true
						else:
							_has_valid_meal_this_sitting = bool(vm_chk.call("consume_village_meal_for_npc", self)) if (vm_chk and vm_chk.has_method("consume_village_meal_for_npc")) else false
						_sitting_meal_ingested = 0.0
					if _has_valid_meal_this_sitting:
						var at_public_table: bool = (_restaurant_seat != Vector2.ZERO or _tavern_seat != Vector2.ZERO or _eat_at_tavern)
						var eat_rate: float = 2.0 if at_public_table else 9.5
						var ingest_step: float = minf(38.0 - _sitting_meal_ingested, eat_rate * delta)
						if ingest_step > 0.0:
							_sitting_meal_ingested += ingest_step
							feed_npc_gradual(ingest_step)
						need_energy = minf(100.0, need_energy + 1.2 * delta)
						need_social = minf(100.0, need_social + 5.0 * delta)
					elif need_hunger < 74.0 and need_energy > 15.0:
						if vm_chk != null and vm_chk.has_method("is_demo_mode") and bool(vm_chk.call("is_demo_mode")):
							feed_npc_gradual(22.0)
							current_activity = ActivityState.SLEEPING if is_night_env else ActivityState.SOCIALIZING
						else:
							_is_amateur_foraging = true
							_amateur_forage_timer = 0.0
							_amateur_prey_target = null
							_spawn_floating_text("🏹🥺 ¡Sin comida ni dinero! Saliendo al bosque a cazar/recolectar por mi cuenta...", Color.ORANGE, -38.0)
					else:
						if digestion_buffer <= 0.0:
							need_hunger = maxf(0.0, need_hunger - base_3day_hunger_rate * 0.95 * delta)
						need_energy = maxf(0.0, need_energy - 0.22 * delta)
						current_activity = ActivityState.SLEEPING if is_night_env else ActivityState.SOCIALIZING
				else:
					if digestion_buffer <= 0.0:
						need_hunger = maxf(0.0, need_hunger - base_3day_hunger_rate * 0.85 * delta)
					need_energy = maxf(0.0, need_energy - 0.22 * delta)

		ActivityState.SOCIALIZING:
			is_sleeping = false
			if digestion_buffer <= 0.0:
				need_hunger = maxf(0.0, need_hunger - base_3day_hunger_rate * 0.90 * delta)
			need_energy = maxf(0.0, need_energy - _energy_decay_rate * 0.80 * malnutrition_fatigue_mult * delta)
			if global_position.distance_to(_get_social_target_pos()) <= 26.0:
				need_social = minf(100.0, need_social + 15.0 * delta)
				_chat_bubble_timer -= delta
				if _chat_bubble_timer <= 0.0:
					_chat_bubble_timer = randf_range(4.5, 7.5)
					if rite_kind in ["sect", "sect_lure"]:
						_spawn_floating_text("🌑" if rite_kind == "sect" else "❔", Color(0.7, 0.55, 0.95), -30.0)
					elif rite_pos != Vector2.ZERO:
						_spawn_floating_text("☀️🙏" if trade_role != TradeRole.PRIEST else "☀️ «Compartid el pan y perdonad...»", Color(1.0, 0.92, 0.65), -30.0)
					elif is_visiting_grave():
						_spawn_floating_text("🕯️ «No te olvido, %s...»" % str(person_profile.deceased_partner_name), Color(0.82, 0.80, 0.98), -30.0)
					elif is_instance_valid(_social_partner) and _npc_social_event_cooldown <= 0.0:
						_trigger_dynamic_npc_social_interaction(_social_partner)
					else:
						_spawn_floating_text("💬", Color(0.75, 0.95, 1.0), -28.0)

		ActivityState.SLEEPING:
			var vm_slp = _get_vm()
			if trade_role == TradeRole.UNEMPLOYED and not is_vagrant_camper and vm_slp and vm_slp.has_method("is_building_door_blocked") and bool(vm_slp.call("is_building_door_blocked", "tavern")) and vm_slp.has_method("evict_npc_to_vagrant_camp"):
				vm_slp.call("evict_npc_to_vagrant_camp", self, "Puerta de la Taberna bloqueada")
			var bed_target_elev: int = 1 if _es_de_arriba(bed_position) else 0
			if global_position.distance_to(bed_position) <= 20.0 and int(elevation_level) == bed_target_elev:
				is_sleeping = true
				if is_vagrant_camper and not in_shelter:
					var max_camp_energy: float = 62.0 if (WorldClock != null and int(WorldClock.current_weather) == 1) else 74.0
					need_energy = minf(max_camp_energy, need_energy + 0.72 * delta)
				else:
					need_energy = minf(100.0, need_energy + 1.10 * delta)
				if digestion_buffer <= 0.0:
					need_hunger = maxf(0.0, need_hunger - base_3day_hunger_rate * 0.55 * delta)
			else:
				is_sleeping = false

	if sprite and not is_incapacitated():
		sprite.modulate = Color(0.86, 0.88, 0.78, 1.0) if need_hunger < 33.33 else (Color(0.94, 0.94, 0.88, 1.0) if need_hunger < 66.67 else Color.WHITE)

	if need_hunger <= 0.0 and digestion_buffer <= 0.0:
		_starvation_tick_timer += delta
		if _starvation_tick_timer >= 3.5:
			_starvation_tick_timer = 0.0
			last_hit_weapon_name = "Muerte por Inanición (3+ Días de Hambruna)"
			last_hit_by_player = false
			add_thought("¡Muriendo de inanición tras 3 días sin comer! (-25)", -25.0)
			_spawn_floating_text("🍖💀 ¡Inanición Letal (+3 Días sin comer)! (-Salud)", Color.ORANGE_RED, -38.0)
			if health_comp:
				var starve_dmg := DamageData.new()
				starve_dmg.amount = 3.5
				starve_dmg.type = CombatConstants.DamageType.BLUNT
				health_comp.take_damage(starve_dmg)
	else:
		_starvation_tick_timer = 0.0

	if health_comp and not is_dead:
		_npc_env_sickness_timer += delta
		if _npc_env_sickness_timer >= 2.2:
			_npc_env_sickness_timer = 0.0
			_check_npc_environmental_sickness()

	# Si por alguna razón extrema llega a 0% de energía fuera del turno obligatorio, NO se desmaya en el suelo:
	# sufre los debufos severos de privación de sueño y camina hacia su cama/campamento a dormir.
	if (need_energy <= 0.0 or (health_comp and health_comp.fever >= 25.0) or sick_level >= 2) and not in_work_shift and current_activity != ActivityState.SLEEPING:
		current_activity = ActivityState.SLEEPING
		return
	if in_work_shift and current_activity == ActivityState.WORKING:
		return

	_decision_timer -= delta
	if _decision_timer > 0.0:
		return
	_decision_timer = randf_range(0.8, 1.5)

	if current_activity == ActivityState.SLEEPING:
		if not is_night_env and need_energy >= (60.0 if is_vagrant_camper else 78.0):
			is_sleeping = false
			current_activity = ActivityState.EATING if (need_hunger < 72.0 and digestion_buffer < 12.0) else ActivityState.WORKING
			if current_activity == ActivityState.EATING:
				_eat_at_tavern = _choose_preferred_meal_location()
		return

	if current_activity == ActivityState.EATING:
		if not _is_amateur_foraging and (_sitting_meal_ingested >= 36.0 or (need_hunger + digestion_buffer) >= 96.0):
			var cur_h_m: int = int(WorldClock.current_hour) if WorldClock else 12
			if not is_night_env and cur_h_m >= 8 and cur_h_m < 23 and (_tavern_seat != Vector2.ZERO or _restaurant_seat != Vector2.ZERO):
				var linger_seat: Vector2 = _restaurant_seat if _restaurant_seat != Vector2.ZERO else _tavern_seat
				var linger_place: String = ("restaurant_terrace" if _VillageRestaurant.en_terraza(linger_seat, 10.0) else "restaurant_hall") if _restaurant_seat != Vector2.ZERO else "tavern_hall"
				if not _is_mandatory_work_hours() or randf() < 0.65:
					set_meta("leisure_place", linger_place)
					start_errand("leisure", linger_seat)
					return
			if is_night_env or need_energy <= 12.0:
				current_activity = ActivityState.SLEEPING
			elif need_social < 75.0:
				current_activity = ActivityState.SOCIALIZING
				_social_partner = _find_best_social_partner()
			else:
				current_activity = ActivityState.WORKING
		return

	if current_activity == ActivityState.SOCIALIZING:
		if rite_pos != Vector2.ZERO and need_energy > 12.0 and need_hunger >= 30.0:
			return # G2: en el Oficio se quedan hasta que termina, salvo hambre o cansancio fuertes
		if rite_pos != Vector2.ZERO:
			leave_rite()
		if errand_kind != "" and need_energy > 12.0 and need_hunger >= 30.0 and (not is_night_env or errand_kind in NIGHT_ERRANDS):
			return # E: termina su encargo (lavarse, taberna, limosna, redada) antes de cambiar de idea
		if errand_kind != "":
			end_errand()
		if is_night_env or need_energy <= 12.0 or (need_hunger < 65.0 and digestion_buffer < 10.0) or (need_social >= 92.0 and hangout_id < 0):
			_social_partner = null
			if need_hunger < 70.0 and digestion_buffer < 12.0 and not is_night_env:
				current_activity = ActivityState.EATING
				_eat_at_tavern = _choose_preferred_meal_location()
			else:
				current_activity = ActivityState.SLEEPING if (is_night_env or need_energy <= 12.0) else ActivityState.WORKING
		return

	if need_hunger <= 78.0 and digestion_buffer < 15.0 and not is_night_env:
		current_activity = ActivityState.EATING
		_eat_at_tavern = _choose_preferred_meal_location()
	elif is_night_env or need_energy <= 12.0:
		current_activity = ActivityState.SLEEPING
	elif need_social <= (90.0 if (WorldClock != null and WorldClock.has_method("is_weekend") and WorldClock.is_weekend()) else 78.0): # G2: el fin de semana salen más
		current_activity = ActivityState.SOCIALIZING
		_social_partner = _find_best_social_partner()

func _consume_pocket_meal_if_any() -> bool:
	var priority_foods: Array[String] = ["poisoned_stew", "spoiled_food", "braised_meat", "pasta_dish", "country_stew", "roasted_chicken", "cooked_meat", "cooked_fish", "fried_frog_legs", "royal_ration", "bread", "raw_meat", "raw_chicken"]
	for fid in priority_foods:
		if has_pocket_item(fid, 1):
			remove_pocket_item(fid, 1)
			var info: Dictionary = SimpleInventory.CATALOG.get(fid, {})
			var fname: String = str(info.get("name", fid))
			var p_risk: float = float(info.get("poison_risk", 0.0))
			if p_risk > 0.0 and health_comp and randf() <= p_risk:
				var p_amt: float = float(info.get("poison_amount", 40.0))
				health_comp.add_food_poisoning(p_amt, fname)
				last_hit_weapon_name = "Envenenamiento por " + fname
				add_thought("¡Comí %s contaminado/adulterado! (-22)" % fname, -22.0)
				_spawn_floating_text("🤢☣️ ¡%s sufrió intoxicación al comer %s!" % [npc_name, fname], Color(0.75, 1.0, 0.25), -44.0)
			return true
	return false

func _check_npc_environmental_sickness() -> void:
	if not health_comp or is_dead:
		return
	if Zona.rect_mundo(ZONA_CIENAGA).has_point(global_position): # la ciénaga, donde esté su pieza del editor
		health_comp.add_swamp_or_miasma_exposure(1.4, "Humedad de la Ciénaga de las Ranas")
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n == self or not is_instance_valid(n) or not (n is Node2D):
			continue
		if n.get("corpse_on_ground") == true and n.get("corpse_in_morgue") != true and float(n.get("corpse_rot_hours")) >= 1.5:
			if global_position.distance_to((n as Node2D).global_position) <= 68.0:
				health_comp.add_swamp_or_miasma_exposure(2.5, "Miasma de cadáver putrefacto")
				break

## ¿Está ese sitio en una planta alta (la de la posada o la de una casa de dos plantas)?
func _es_de_arriba(pos: Vector2) -> bool:
	return _VillageTavern.is_upper_floor_target(pos) or PisosCasas.es_arriba(pos)

func _approach_or_stop(target_pos: Vector2, tol: float, spd: float, delta: float) -> void:
	var target_elev: int = 1 if _es_de_arriba(target_pos) else (-1 if errand_kind == "club_watch" else 0)
	if global_position.distance_to(target_pos) > tol or int(elevation_level) != target_elev:
		_move_towards_point(target_pos, spd, delta)
	else:
		velocity = Vector2.ZERO

func _execute_dynamic_activity(delta: float) -> void:
	if current_activity != ActivityState.WORKING:
		_supply_run_target_role = 0
		_stop_crafting_bar()

	match current_activity:
		ActivityState.SLEEPING:
			_approach_or_stop(bed_position, 7.0, 42.0, delta)
		ActivityState.EATING:
			if _is_amateur_foraging:
				_process_amateur_survival_hunting(delta)
				return
			var meal_t: Vector2 = _current_meal_pos()
			var meal_tol: float = 2.0 if (_tavern_seat != Vector2.ZERO or _restaurant_seat != Vector2.ZERO or _VillageTavern.is_at_seat(meal_t) or _VillageRestaurant.is_at_seat(meal_t)) else 10.0
			_approach_or_stop(meal_t, meal_tol, 40.0, delta)
		ActivityState.SOCIALIZING:
			var soc_t: Vector2 = _get_social_target_pos()
			var soc_tol: float = 2.0 if (_VillageTavern.is_at_seat(soc_t) or _VillageRestaurant.is_at_seat(soc_t)) else (8.0 if (is_instance_valid(_social_partner) and errand_kind == "" and rite_pos == Vector2.ZERO) else 16.0)
			_approach_or_stop(soc_t, soc_tol, 38.0, delta)
		ActivityState.WORKING:
			if _is_morning_expedition_hours():
				_stop_crafting_bar()
				_process_physical_morning_expedition(delta)
				return
			if trade_role in SHOP_ROLES or trade_role in [TradeRole.INNKEEPER, TradeRole.DOCTOR]:
				var _pa: int = Time.get_ticks_usec() if perf_on else 0
				_process_artisan_workshop_crafting_and_supply_runs(delta)
				if perf_on: _perf_add("d_artisan_total", _pa)
				return
			if trade_role == TradeRole.WAITER:
				_VillageTavern.tick_waiter(_get_vm(), self, delta)
				return
			_stop_crafting_bar()
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				var is_idle_stroller: bool = (trade_role == TradeRole.UNEMPLOYED and not has_meta("day_job_pos"))
				var is_indoor_authority: bool = trade_role in [TradeRole.PRIEST, TradeRole.DOCTOR, TradeRole.SHERIFF]
				_wander_timer = randf_range(7.0, 14.0) if is_idle_stroller else randf_range(2.2, 4.6)
				var radius: float = 34.0 if (trade_role == TradeRole.UNEMPLOYED or trade_role == TradeRole.GUARD) else (3.5 if is_indoor_authority else 11.0)
				var base_ang: float = float(absi(npc_name.hash()) % 360) * (TAU / 360.0) + randf_range(-0.85, 0.85)
				_wander_offset = Vector2.RIGHT.rotated(base_ang) * randf_range(12.0, radius) if is_idle_stroller else Vector2.RIGHT.rotated(base_ang) * randf_range(1.5 if is_indoor_authority else 6.5, radius)
				if is_idle_stroller and randf() < 0.45:
					set_meta("stroll_anchor", Sitio.serie(SITIOS_PASEO).pick_random())
				elif is_idle_stroller and has_meta("stroll_anchor") and randf() < 0.30:
					remove_meta("stroll_anchor")
			var anchor: Vector2 = get_meta("day_job_pos") if has_meta("day_job_pos") else (get_meta("stroll_anchor") if (trade_role == TradeRole.UNEMPLOYED and has_meta("stroll_anchor")) else work_position) # V5d: jornalero en el campo o paseo por el pueblo
			var target_pos: Vector2 = anchor + _wander_offset
			var vm = _get_vm()
			if vm and vm.has_method("clamp_point_to_building_interior"):
				target_pos = vm.call("clamp_point_to_building_interior", anchor, target_pos)
			if vm and vm.has_method("clamp_point_outside_buildings"):
				target_pos = vm.call("clamp_point_outside_buildings", anchor, target_pos)
			_approach_or_stop(target_pos, 5.0, 44.0, delta)

func _get_artisan_recipes() -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	if ARTISAN_RECIPES.has(trade_role):
		res.assign(ARTISAN_RECIPES[trade_role])
	return res

func _process_artisan_workshop_crafting_and_supply_runs(delta: float) -> void:
	if _supply_run_cooldown > 0.0:
		_supply_run_cooldown = maxf(0.0, _supply_run_cooldown - delta)

	var vm = _get_vm()
	if vm and vm.has_method("is_trade_sabotaged") and bool(vm.call("is_trade_sabotaged", int(trade_role))):
		_supply_run_target_role = 0
		_stop_crafting_bar()
		_approach_or_stop(work_position, 8.0, 42.0, delta)
		return

	if _supply_run_target_role != 0:
		_is_actively_crafting = false
		_supply_run_timer += delta
		var supplier_npc = null
		if vm and "trade_npcs" in vm and vm.trade_npcs.has(_supply_run_target_role):
			var cand = vm.trade_npcs[_supply_run_target_role]
			if cand is VillageNPCBase and is_instance_valid(cand) and cand.is_conscious() and not cand.is_hostile:
				supplier_npc = cand

		if supplier_npc == null:
			_supply_run_target_role = 0
			_supply_run_timer = 0.0
			_supply_run_cooldown = 28.0
			_stop_crafting_bar()
			return

		var supplier_counter: Vector2 = supplier_npc.work_position + Vector2(0, 12)
		var dist_to_sup: float = global_position.distance_to(supplier_counter)
		_update_craft_bar_visual(clampf(1.0 - (dist_to_sup / 240.0), 0.12, 0.95), "🛒 A %s (%s)" % [supplier_npc.npc_name, _supply_run_input_label], Color(0.35, 0.86, 1.0, 0.95))

		if dist_to_sup > 28.0:
			if _supply_run_timer < 24.0:
				_move_towards_point(supplier_counter, 54.0, delta)
			else:
				_supply_run_target_role = 0
				_supply_run_timer = 0.0
				_supply_run_cooldown = 32.0
				_stop_crafting_bar()
			return

		velocity = Vector2.ZERO
		if supplier_npc.is_at_shop_counter() and int(supplier_npc.shop_stock.get(_supply_run_item_id, 0)) > 0:
			var buy_cost: int = 6
			personal_gold = maxi(0, personal_gold - buy_cost)
			var biz_mode: String = str(vm.shop_businesses[_supply_run_target_role].get("owner_mode", "NPC")) if (vm and "shop_businesses" in vm and vm.shop_businesses.has(_supply_run_target_role)) else "NPC"
			if biz_mode == "SOLE_OWNER":
				vm.shop_businesses[_supply_run_target_role]["vault_gold"] = int(vm.shop_businesses[_supply_run_target_role].get("vault_gold", 0)) + buy_cost
			elif biz_mode == "PARTNER":
				var player_cut: int = int(float(buy_cost) * 0.5)
				vm.shop_businesses[_supply_run_target_role]["vault_gold"] = int(vm.shop_businesses[_supply_run_target_role].get("vault_gold", 0)) + player_cut
				supplier_npc.personal_gold = maxi(0, supplier_npc.personal_gold) + (buy_cost - player_cut)
			else:
				supplier_npc.personal_gold = maxi(0, supplier_npc.personal_gold) + buy_cost
			supplier_npc.shop_stock[_supply_run_item_id] = int(supplier_npc.shop_stock[_supply_run_item_id]) - 1
			supplier_npc._sync_shop_stock_to_vm()
			workshop_materials[_supply_run_item_id] = int(workshop_materials.get(_supply_run_item_id, 0)) + 2
			trigger_action_animation(2.2)
			supplier_npc.trigger_action_animation(2.2)
			_spawn_floating_text("🛒🤝 Compró +2 %s a %s (-%d Oro)" % [_supply_run_input_label, supplier_npc.npc_name, buy_cost], Color(0.45, 0.95, 1.0), -42.0)
			supplier_npc._spawn_floating_text("💰 +%d Oro (Suministro a %s)" % [buy_cost, npc_name], Color.GOLD, -36.0)
			add_thought("Compró suministros de taller a %s (+5)" % supplier_npc.npc_name, 5.0)
			modify_npc_relationship(supplier_npc, 6, "Comercio frecuente de suministros entre talleres")
		_supply_run_target_role = 0
		_supply_run_timer = 0.0
		_supply_run_cooldown = randf_range(38.0, 56.0)
		return

	# R1b: el cocinero va a la cámara fría a por la carne antes del estofado
	if trade_role == TradeRole.RESTAURATEUR and _craft_progress < 1.0:
		var r_recs: Array[Dictionary] = _get_artisan_recipes()
		if not r_recs.is_empty() and _VillageRestaurant.cook_cold_room_trip(self, r_recs[_crafting_recipe_idx % r_recs.size()], delta):
			_is_actively_crafting = false
			return
	var in_wed_market: bool = vm != null and "VillageCulture" in vm and vm.VillageCulture != null and (vm.VillageCulture.state(vm).get("market_sellers", {}) as Dictionary).has(get_person_key())
	var carp_on_site: bool = (trade_role == TradeRole.CARPENTER and vm != null and "VillageLots" in vm and vm.VillageLots != null and str(vm.VillageLots.active_site(vm)) != "")
	if not in_wed_market and not carp_on_site and vm != null and "trade_configs" in vm and vm.trade_configs.has(int(trade_role)):
		var true_wp: Vector2 = (vm.trade_configs[int(trade_role)] as Dictionary).get("work_pos", work_position)
		if true_wp != Vector2.ZERO and work_position.distance_to(true_wp) > 4.0:
			work_position = true_wp

	# 2. Regresar o permanecer en su propio puesto de trabajo (`work_position`)
	if global_position.distance_to(work_position) > 22.0 or int(elevation_level) != 0:
		_is_actively_crafting = false
		_update_craft_bar_visual(0.20, "🚶 Volviendo al taller...", Color(0.75, 0.85, 0.95, 0.85))
		_move_towards_point(work_position, 50.0, delta)
		return

	velocity = Vector2.ZERO
	if in_wed_market:
		_stop_crafting_bar()
		return
	var recipes: Array[Dictionary] = _get_artisan_recipes()
	if recipes.is_empty():
		_stop_crafting_bar()
		return

	var rec: Dictionary = recipes[_crafting_recipe_idx % recipes.size()]
	# Si el stock de este producto ya está al máximo (>= 12), pasar a la otra receta o atender mostrador
	if int(shop_stock.get(str(rec.get("output", "")), 0)) >= 12:
		_craft_progress = 0.0
		_crafting_recipe_idx = (_crafting_recipe_idx + 1) % recipes.size()
		rec = recipes[_crafting_recipe_idx]
		if int(shop_stock.get(str(rec.get("output", "")), 0)) >= 12:
			_stop_crafting_bar()
			return

	var out_id: String = str(rec.get("output", ""))
	var out_label: String = str(rec.get("label", out_id))
	var verb_str: String = str(rec.get("verb", "⚒️ Elaborando"))
	var req_input: String = str(rec.get("input", ""))
	var sup_role: int = int(rec.get("supplier", 0))
	var in_label: String = str(rec.get("input_name", req_input))
	var cur_mat_count: int = int(workshop_materials.get(req_input, 0))
	var player_near_counter: bool = is_instance_valid(_cached_player) and _cached_player.global_position.distance_squared_to(work_position) <= 60.0 * 60.0

	# Si se quedó sin el material que vende el vecino, tiene oro suficiente, el vecino está atendiendo su mostrador, tiene stock y no está saboteado, va a comprarlo
	if cur_mat_count <= 0 and _craft_progress < 8.0 and _supply_run_cooldown <= 0.0 and personal_gold >= 8 and not player_near_counter and sup_role != 0:
		if vm and "trade_npcs" in vm and vm.trade_npcs.has(sup_role):
			var sup_sabotaged: bool = vm.has_method("is_trade_sabotaged") and bool(vm.call("is_trade_sabotaged", sup_role))
			var sup_cand = vm.trade_npcs[sup_role]
			if not sup_sabotaged and sup_cand is VillageNPCBase and is_instance_valid(sup_cand) and sup_cand.is_at_shop_counter() and int(sup_cand.shop_stock.get(req_input, 0)) > 0:
				_supply_run_target_role = sup_role
				_supply_run_item_id = req_input
				_supply_run_input_label = in_label
				_supply_run_timer = 0.0
				_is_actively_crafting = false
				_spawn_floating_text("🛒 Necesito %s: voy a comprarle a %s" % [in_label, sup_cand.npc_name], Color(0.55, 0.92, 1.0), -38.0)
				return

	# 3. Crafteo activo en el taller con animación de trabajo (Fila 2) y barra llenándose
	_is_actively_crafting = true
	_crafting_item_id = out_id
	var eff: float = get_job_efficiency()
	var mat_speed_mult: float = 1.0 if cur_mat_count > 0 else 0.68
	var fill_rate: float = (100.0 / 16.0) * eff * mat_speed_mult
	_craft_progress += fill_rate * delta

	var pct: int = clampi(int(round(_craft_progress)), 0, 100)
	_update_craft_bar_visual(_craft_progress / 100.0, "%s %s %d%%" % [verb_str, out_label, pct], Color(0.98, 0.78, 0.24, 0.95))

	if _craft_progress >= 100.0:
		_craft_progress = 0.0
		if cur_mat_count > 0:
			workshop_materials[req_input] = cur_mat_count - 1
		if has_meta("cold_room_fetched"):
			remove_meta("cold_room_fetched")
		shop_stock[out_id] = int(shop_stock.get(out_id, 0)) + 1
		_sync_shop_stock_to_vm()
		_spawn_floating_text("⚒️✨ ¡%s fabricó +1 %s!" % [npc_name, out_label], Color(0.55, 1.0, 0.68), -40.0)
		add_thought("Elaboró +1 %s en su taller (+4)" % out_label, 4.0)
		_crafting_recipe_idx = (_crafting_recipe_idx + 1) % recipes.size()

func _process_physical_morning_expedition(delta: float) -> void:
	var cur_day: int = WorldClock.current_day if WorldClock else 1
	# En Día 3 de hambruna (< 22% nutrición), el artesano no tiene fuerzas físicas para salir al bosque/lago a extraer recursos
	if need_hunger < 22.0:
		_completed_expedition_day = cur_day
		_expedition_target_node = null
		current_activity = ActivityState.EATING
		add_thought("Demasiado débil por el hambre para salir a recolectar (-10)", -10.0)
		_spawn_floating_text("🥺🍖 ¡Sin fuerzas por desnutrición! No puedo salir a recolectar hoy", Color.ORANGE_RED, -38.0)
		return
	var vm_sab = _get_vm()
	if vm_sab and vm_sab.has_method("is_trade_sabotaged") and bool(vm_sab.call("is_trade_sabotaged", int(trade_role))):
		_completed_expedition_day = cur_day
		_expedition_target_node = null
		add_thought("¡Alguien saboteó mi taller! (-12)", -12.0)
		_spawn_floating_text("🔧💥 ¡Mi taller fue saboteado! No puedo producir hoy", Color.ORANGE_RED, -38.0)
		return
	var eco: EcosystemManager = get_tree().get_first_node_in_group("ecosystem_manager") as EcosystemManager
	var eff: float = get_job_efficiency()

	# Caso 1: Pescador en el Muelle del Lago del Oeste
	if trade_role == TradeRole.FISHMONGER:
		var dock_pos: Vector2 = _get_expedition_target_pos()
		if global_position.distance_to(dock_pos) > 16.0:
			_move_towards_point(dock_pos, 58.0, delta)
			return
		velocity = Vector2.ZERO
		facing_direction = Vector2.LEFT
		trigger_action_animation(0.6)
		_expedition_gather_timer += delta
		if _expedition_gather_timer >= (2.2 / maxf(0.35, eff)):
			_expedition_gather_timer = 0.0
			_completed_expedition_day = cur_day
			var fish_yield: int = 2 if eff >= 0.75 else 1
			shop_stock["cooked_fish"] = int(shop_stock.get("cooked_fish", 0)) + fish_yield
			workshop_materials["wood"] = int(workshop_materials.get("wood", 0)) + 1
			_sync_shop_stock_to_vm()
			_spawn_floating_text("🎣🐟 ¡Pescado fresco capturado! (+%d Pescado | Eficiencia %d%%)" % [fish_yield, int(round(eff * 100.0))], Color(0.65, 0.95, 1.0), -34.0)
			add_thought("Pesca matutina sostenible en el lago (+6)", 6.0)
		return

	# Caso 2: Carnicero cazando físicamente una presa real del bosque (respetando N_min)
	if trade_role == TradeRole.BUTCHER:
		var prey: WildAnimal = _expedition_target_node as WildAnimal
		var prey_invalid: bool = (not is_instance_valid(prey)) or (prey.state in [WildAnimal.AnimalState.BUTCHERED, WildAnimal.AnimalState.IN_BURROW]) or (not prey.visible)
		if prey_invalid:
			_expedition_target_node = null
			if eco != null:
				prey = eco.find_sustainable_hunt_prey(global_position)
				_expedition_target_node = prey
			if prey == null:
				# El bosque está en o por debajo de su umbral de equilibrio: suspende la caza hoy
				_completed_expedition_day = cur_day
				_spawn_floating_text("🦌⚖️ Equilibrio del bosque al límite: hoy no cazaré para proteger la fauna", Color.SPRING_GREEN, -38.0)
				add_thought("Respetó el equilibrio de la fauna del bosque (+5)", 5.0)
				return

		# J1: si un jabalí le embiste y ya va por la mitad de la salud, deja la caza por hoy y se aleja
		if should_flee_boar(prey):
			flee_from_boar(prey)
			return

		# Si la presa ya ha caído abatida (`CARCASS`), acercarse físicamente a desollarla
		if prey.state == WildAnimal.AnimalState.CARCASS:
			if global_position.distance_to(prey.global_position) > 22.0:
				_move_towards_point(prey.global_position, 64.0, delta)
			else:
				velocity = Vector2.ZERO
				_expedition_gather_timer += delta
				if _expedition_gather_timer >= (0.85 / maxf(0.35, eff)):
					_expedition_gather_timer = 0.0
					var p_name: String = prey.animal_name
					prey._finish_butchering()
					_expedition_target_node = null
					_completed_expedition_day = cur_day
					var meat_yield: int = 3 if eff >= 0.85 else (2 if eff >= 0.60 else 1)
					var leather_yield: int = 1 if eff >= 0.60 else 0
					shop_stock["cooked_meat"] = int(shop_stock.get("cooked_meat", 0)) + meat_yield
					if leather_yield > 0:
						shop_stock["leather"] = int(shop_stock.get("leather", 0)) + leather_yield
						_spawn_floating_text("🔪🥩 ¡%s desollado! (+%d Carne, +%d Cuero | Ef.%d%%)" % [p_name, meat_yield, leather_yield, int(round(eff * 100.0))], Color.GOLD, -38.0)
					else:
						_spawn_floating_text("🔪🥩 ¡%s desollado! (+%d Carne | Piel dañada por novato)" % [p_name, meat_yield], Color.GOLD, -38.0)
					_sync_shop_stock_to_vm()
					add_thought("Caza matutina en equilibrio con el bosque (+6)", 6.0)
			return

		# La presa está viva: acercarse a rango de arco y disparar flechas físicas hasta abatirla
		var dist_prey: float = global_position.distance_to(prey.global_position)
		if dist_prey > 95.0:
			_move_towards_point(prey.global_position, 68.0, delta)
		else:
			if dist_prey > 48.0:
				_move_towards_point(prey.global_position, 52.0, delta)
			else:
				velocity = Vector2.ZERO
			_expedition_gather_timer += delta
			if _expedition_gather_timer >= (0.90 / maxf(0.45, eff)):
				_expedition_gather_timer = 0.0
				_fire_hunter_arrow_at_prey(prey)
		return

	# Caso 3: Carpintero (`LOGGING`), Herrero (`MINING`) y Herborista (`FORAGE`)
	var req_h_type: int = int(HarvestableNode.HarvestType.MINING if trade_role == TradeRole.BLACKSMITH else (HarvestableNode.HarvestType.FORAGE if trade_role == TradeRole.HERBALIST else HarvestableNode.HarvestType.LOGGING))
	var h_node: HarvestableNode = _expedition_target_node as HarvestableNode
	if not is_instance_valid(h_node) or h_node.is_depleted:
		_expedition_target_node = eco.find_sustainable_harvest_node(req_h_type, global_position) if eco != null else null
		h_node = _expedition_target_node as HarvestableNode
		if h_node == null:
			_completed_expedition_day = cur_day
			_spawn_floating_text("🌿⚖️ Recursos del bosque en su umbral mínimo: hoy no extraeré más", Color.SPRING_GREEN, -38.0)
			add_thought("Protegió la regeneración natural del bosque (+5)", 5.0)
			return

	if global_position.distance_to(h_node.global_position) > 24.0:
		_move_towards_point(h_node.global_position, 60.0, delta)
		return

	velocity = Vector2.ZERO
	trigger_action_animation(0.6)
	_expedition_gather_timer += delta

	if trade_role == TradeRole.HERBALIST:
		if _expedition_gather_timer >= (1.1 / maxf(0.35, eff)):
			_expedition_gather_timer = 0.0
			h_node.harvest_by_npc(self)
			_expedition_target_node = null
			_completed_expedition_day = cur_day
			var herb_yield: int = 2 if eff >= 0.75 else 1
			shop_stock["herbal_poultice"] = int(shop_stock.get("herbal_poultice", 0)) + herb_yield
			workshop_materials["bread"] = int(workshop_materials.get("bread", 0)) + 1
			_sync_shop_stock_to_vm()
			_spawn_floating_text("🌿✨ ¡%s recolectada! (+%d Botica | Ef.%d%%)" % [h_node.node_title, herb_yield, int(round(eff * 100.0))], Color.SPRING_GREEN, -36.0)
			add_thought("Cosecha herbolaria sostenible (+6)", 6.0)
		return

	# Carpintero (Hacha) o Herrero (Pico): golpear físicamente el árbol o la veta hasta derribarlo/agotarla
	if _expedition_gather_timer >= (0.75 / maxf(0.40, eff)):
		_expedition_gather_timer = 0.0
		var dmg := DamageData.new()
		dmg.amount = 15.0 * eff
		dmg.source = self
		if trade_role == TradeRole.CARPENTER:
			dmg.type = CombatConstants.DamageType.CUT
			dmg.logging_efficiency = 1.85 * eff
			_spawn_floating_text("🪓 ¡Tala!", Color(0.95, 0.85, 0.55), -30.0)
		else:
			dmg.type = CombatConstants.DamageType.BLUNT
			dmg.mining_efficiency = 1.85 * eff
			_spawn_floating_text("⛏️ ¡Pica!", Color(0.80, 0.90, 1.0), -30.0)
		h_node.take_damage(dmg)

		if h_node.is_depleted:
			_expedition_target_node = null
			_completed_expedition_day = cur_day
			if trade_role == TradeRole.CARPENTER:
				var wood_yield: int = 3 if eff >= 0.85 else (2 if eff >= 0.60 else 1)
				shop_stock["wood"] = int(shop_stock.get("wood", 0)) + wood_yield
				_spawn_floating_text("🌲🪓 ¡Árbol talado! (+%d Madera | Ef.%d%%)" % [wood_yield, int(round(eff * 100.0))], Color.SPRING_GREEN, -38.0)
			else:
				var ore_yield: int = 2 if eff >= 0.75 else 1
				shop_stock["iron_ore"] = int(shop_stock.get("iron_ore", 0)) + ore_yield
				_spawn_floating_text("🪨⛏️ ¡Veta extraída! (+%d Hierro | Ef.%d%%)" % [ore_yield, int(round(eff * 100.0))], Color.SPRING_GREEN, -38.0)
			_sync_shop_stock_to_vm()
			add_thought("Extracción matutina en equilibrio con el bosque (+6)", 6.0)

## J2: nombre de la herida según quién la hizo (cualquiera reconoce la de un animal).

func _fire_hunter_arrow_at_prey(prey: WildAnimal) -> void:
	if not is_instance_valid(prey):
		return
	_spawn_shot_tracer(prey.global_position, Color(0.92, 0.78, 0.45, 0.92), 1.8, 16, -4.0, 0.16)
	var d := DamageData.new()
	d.amount = 18.0 * get_job_efficiency()
	d.type = CombatConstants.DamageType.CUT
	d.source = self
	prey.take_damage(d)
	_spawn_floating_text("🏹 ¡Flechazo de Caza!", Color(0.95, 0.86, 0.52), -34.0)

## Caza y Recolección Amateur Ineficiente (`_is_amateur_foraging`):
## Cuando un NPC sin experiencia en cacería se queda sin comida en su despensa y no puede comprar en tiendas ni Taberna,
## sale al bosque por desesperación:
## - No tiene arco (persigue animales a pie haciendo apenas 5.5 de daño y fallando el 38% de los golpes).
## - Gasta mucha más energía y tarda mucho tiempo.
## - Al desollar la presa (`CARCASS`), realiza un Despiece Torpe (`🔪💦`) que destruye la piel/huesos y desperdicia el 70% de la carne,
##   obteniendo solo 1 corte precario (+24% nutrición gradual).

func _process_amateur_survival_hunting(delta: float) -> void:
	_amateur_forage_timer += delta
	var eco: EcosystemManager = get_tree().get_first_node_in_group("ecosystem_manager") as EcosystemManager
	var prey: WildAnimal = _amateur_prey_target as WildAnimal
	var prey_invalid: bool = (not is_instance_valid(prey)) or (prey.state in [WildAnimal.AnimalState.BUTCHERED, WildAnimal.AnimalState.IN_BURROW]) or (not prey.visible)
	if prey_invalid:
		_amateur_prey_target = null
		if eco != null:
			prey = eco.find_sustainable_hunt_prey(global_position)
			_amateur_prey_target = prey

	# Si tras 18s no logra encontrar o alcanzar animales, desentierra raíces y bayas amargas para no morir de hambre
	if prey == null or _amateur_forage_timer >= 20.0:
		var fallback_spot: Vector2 = Sitio.mundo("forrajeo") # raíces y bayas amargas, al sur
		if global_position.distance_to(fallback_spot) > 22.0 and _amateur_forage_timer < 18.0:
			_move_towards_point(fallback_spot, 48.0, delta)
			return
		velocity = Vector2.ZERO
		if _amateur_forage_timer >= 14.0:
			_is_amateur_foraging = false
			_amateur_forage_timer = 0.0
			_amateur_prey_target = null
			feed_npc_gradual(18.0)
			add_thought("Tuvo que comer raíces amargas del bosque por falta de comida (-6)", -6.0)
			_spawn_floating_text("🌱😣 Raíces silvestres recolectadas (+18% Nutrición gradual)", Color(0.82, 0.92, 0.58), -36.0)
			current_activity = ActivityState.SOCIALIZING
		return

	if should_flee_boar(prey): # J1
		flee_from_boar(prey)
		return

	# Si la presa ya cayó (`CARCASS`), acercarse y hacer un despiece amateur torpe (desperdiciando piel y 70% de carne)
	if prey.state == WildAnimal.AnimalState.CARCASS:
		if global_position.distance_to(prey.global_position) > 20.0:
			_move_towards_point(prey.global_position, 52.0, delta)
		else:
			velocity = Vector2.ZERO
			_expedition_gather_timer += delta
			if _expedition_gather_timer >= 2.2:
				_expedition_gather_timer = 0.0
				var p_name: String = prey.animal_name
				prey._finish_butchering()
				_amateur_prey_target = null
				_is_amateur_foraging = false
				_amateur_forage_timer = 0.0
				feed_npc_gradual(24.0)
				var vm_p = _cached_vm if is_instance_valid(_cached_vm) else get_tree().get_first_node_in_group("village_manager")
				if vm_p and vm_p.has_method("add_home_pantry_ration"):
					vm_p.call("add_home_pantry_ration", self, 1)
				add_thought("Cazó torpemente en el bosque para sobrevivir (-4)", -4.0)
				_spawn_floating_text("🔪💦 Despiece torpe de %s: piel arruinada y 70%% desperdiciado (+1 Carne precaria)" % p_name, Color.ORANGE, -40.0)
				current_activity = ActivityState.SOCIALIZING
		return

	# Perseguir al animal a pie sin arco (ineficiente y agotador)
	var dist_p: float = global_position.distance_to(prey.global_position)
	if dist_p > 24.0:
		_move_towards_point(prey.global_position, 54.0, delta)
	else:
		velocity = Vector2.ZERO
		_expedition_gather_timer += delta
		if _expedition_gather_timer >= 1.35:
			_expedition_gather_timer = 0.0
			if randf() < 0.38:
				_spawn_floating_text("⚔️💦 ¡Golpe sin puntería fallido! (Sin oficio de caza)", Color(0.95, 0.72, 0.45), -34.0)
			else:
				var d := DamageData.new()
				d.amount = 5.5 * get_nutrition_skill_multiplier()
				d.type = CombatConstants.DamageType.BLUNT
				d.source = self
				prey.take_damage(d)
				_spawn_floating_text("🗡️💦 Golpe torpe de caza (-5 HP)", Color(0.95, 0.80, 0.50), -34.0)

## Rutina física de los 2 Comerciantes Semanales de Extramuros (`Maese Casimir` y `Valeria la Tratante`):
## Recorren los talleres de la aldea comprando solo lo que les interesa de su especialidad e inyectando oro externo,
## y a las 19:00 regresan al camino del sur (`Vector2(430, 820)`) con su Salvoconducto Real.

func promote_to_trade(new_role: TradeRole, new_title: String, new_work_pos: Vector2, inherited_stock: Dictionary, new_tex: Texture2D = null, new_bed_pos: Vector2 = Vector2.ZERO, new_table_pos: Vector2 = Vector2.ZERO, new_family_id: String = "", new_family_name: String = "") -> void:
	var was_family := (trade_role == TradeRole.FAMILY_MEMBER)
	trade_role = new_role
	var base_days: int = 2 if was_family else 0
	# La ventaja de la escuela vale solo para el primer oficio; cambiar de oficio empieza de cero como antes
	var school_bonus: int = int(get_meta("school_bonus_days", 0)) if has_meta("school_bonus_days") else 0
	if has_meta("school_bonus_days"):
		remove_meta("school_bonus_days")
	days_in_role = clampi(base_days + school_bonus, 0, 7)
	npc_role = feminize_role_title(new_title + (" (Herencia Familiar)" if was_family else " (Sucesor)"), is_female())
	work_position = new_work_pos
	if new_bed_pos != Vector2.ZERO: bed_position = new_bed_pos
	if new_table_pos != Vector2.ZERO: home_table_pos = new_table_pos
	if new_family_id != "": family_id = new_family_id
	if new_family_name != "": family_name = new_family_name
	shop_stock = inherited_stock.duplicate()
	is_vagrant_camper = false
	in_shelter = false
	lodging = ""
	if is_at_poker_table:
		set_poker_seating(false)
	_init_workshop_materials()
	_resolve_unique_64_visuals_and_lore(new_tex)
	_sync_shop_stock_to_vm()
	var vm_prom = _get_vm()
	if vm_prom and "vagrant_camp_nodes" in vm_prom and vm_prom.vagrant_camp_nodes.has(npc_name):
		var c_node = vm_prom.vagrant_camp_nodes[npc_name]
		if is_instance_valid(c_node):
			c_node.visible = false

func _inject_character_lore_into_dialogue(diag: Dictionary) -> Dictionary:
	return NPCDialogue._inject_character_lore_into_dialogue(self, diag)
