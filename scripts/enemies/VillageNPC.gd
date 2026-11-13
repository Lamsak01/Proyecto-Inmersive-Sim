@tool
extends "res://scripts/enemies/VillageNPCWork.gd"
class_name VillageNPC


func _ready() -> void:
	set_physics_process(not Engine.is_editor_hint())
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 0
	add_to_group("npcs")
	add_to_group("village_npcs")
	# Desfasar temporizadores de escaneo para que los ~20 NPC no ejecuten sus chequeos pesados en el mismo fotograma (evita picos de lag)
	_visual_memory_timer = randf_range(0.0, 1.25)
	_hover_label_timer = randf_range(0.0, 0.10)
	_unconscious_scan_timer = randf_range(0.0, 0.25)
	_corpse_scan_timer = randf_range(0.0, 0.25)
	if not Engine.is_editor_hint() and WorldClock and not WorldClock.hour_passed.is_connected(_on_hour_passed):
		WorldClock.hour_passed.connect(_on_hour_passed)

func _on_hour_passed(_day: int, _new_hour: int = 0) -> void:
	if is_dead and corpse_on_ground and not corpse_in_morgue:
		corpse_rot_hours += 1.0

## Las posiciones que recibe están en coordenadas del mapa ORIGINAL: aquí se traducen a su sitio actual (plan de sitios,
## docs/PLAN_SITIOS.md). Con p_ya_actuales = true vienen ya traducidas (copiadas de otro vecino o de trade_configs) y no
## se tocan. tavern_social_pos viene siempre de vm._tavern_social_pos (original) y se traduce siempre.
## Al cargar partida, from_save_dict pone después los sitios guardados.
func setup_npc(tex: Texture2D, p_work_pos: Vector2, p_bed_pos: Vector2, initial_stock: Dictionary = {}, p_home_table_pos: Vector2 = Vector2.ZERO, p_family_id: String = "none", p_family_name: String = "Independiente", p_ya_actuales: bool = false) -> void:
	var AN = load("res://mapa/anclas.gd")
	var tr := func(q: Vector2) -> Vector2: return q if q == Vector2.ZERO else AN.mover(q)
	var tr_in: Callable = (func(q: Vector2) -> Vector2: return q) if p_ya_actuales else tr
	work_position = tr_in.call(p_work_pos)
	bed_position = tr_in.call(p_bed_pos)
	home_table_pos = tr_in.call(p_home_table_pos) if p_home_table_pos != Vector2.ZERO else bed_position + Vector2(0, 18)
	if not has_meta("sitios_ok"):
		tavern_social_pos = tr.call(tavern_social_pos)
	set_meta("sitios_ok", true)
	family_id = p_family_id
	family_name = p_family_name
	global_position = work_position
	shop_stock = initial_stock.duplicate()
	need_hunger = randf_range(78.0, 96.0)
	digestion_buffer = 0.0
	need_energy = randf_range(84.0, 98.0)
	need_social = randf_range(58.0, 92.0)
	_hunger_decay_rate = randf_range(0.88, 1.14)
	_energy_decay_rate = randf_range(0.24, 0.30)
	_social_decay_rate = randf_range(0.45, 0.70)
	if personal_gold < 0:
		var gold_range: Vector2i = ROLE_INITIAL_GOLD.get(trade_role, Vector2i(24, 38))
		personal_gold = randi_range(gold_range.x, gold_range.y)
		if trade_role == TradeRole.TRAVELING_MERCHANT:
			carries_royal_safe_conduct = true
	_init_rimworld_psychology()
	npc_role = feminize_role_title(npc_role, is_female())

	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_resolve_unique_64_visuals_and_lore(tex)
	sprite.scale = Vector2(0.54, 0.54)
	add_child(sprite)

	var av3d_script = load("res://scripts/visuals/CharacterAvatar3D.gd")
	if av3d_script != null:
		var av3d = av3d_script.new()
		add_child(av3d)
		av3d.call("setup_for_entity", self, false)

	body_col = _add_circle_col(self, 6.5, true)

	health_comp = HealthComponent.new()
	health_comp.name = "HealthComponent"
	var base_hp: float = 165.0 if trade_role == TradeRole.ROYAL_INVESTIGATOR else (95.0 if trade_role == TradeRole.TRAVELING_MERCHANT else 65.0)
	health_comp.max_health = base_hp
	health_comp.current_health = base_hp
	health_comp.died.connect(_on_died)
	add_child(health_comp)

	stun_comp = StunComponent.new()
	stun_comp.name = "StunComponent"
	stun_comp.max_stun = 100.0
	stun_comp.stun_duration = 8.0
	stun_comp.stunned.connect(_on_stunned)
	add_child(stun_comp)

	hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 0
	_add_circle_col(hurtbox, 10.0)
	hurtbox.hit_received.connect(take_damage)
	add_child(hurtbox)

	interact_area = Area2D.new()
	interact_area.name = "InteractArea"
	interact_area.collision_layer = 1
	interact_area.collision_mask = 2
	interact_area.add_to_group("interactable")
	_add_circle_col(interact_area, 16.0)
	add_child(interact_area)

	status_label = Label.new()
	status_label.visible = false
	_style_label(status_label, Vector2(-60, -34), Vector2.ZERO, 8, Color(0.95, 0.91, 0.83), 2, 20)
	var tag_sb := StyleBoxFlat.new()
	tag_sb.bg_color = Color(0.094, 0.082, 0.067, 0.88)
	tag_sb.border_color = Color(0.227, 0.196, 0.157, 1.0)
	tag_sb.set_border_width_all(1)
	tag_sb.set_corner_radius_all(2)
	tag_sb.content_margin_left = 5
	tag_sb.content_margin_right = 5
	tag_sb.content_margin_top = 1
	tag_sb.content_margin_bottom = 1
	status_label.add_theme_stylebox_override("normal", tag_sb)
	add_child(status_label)

	_setup_craft_progress_bar_ui()
	_init_workshop_materials()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_lod_k = 1.0
	if _lod_far():
		var cur_step: int = _lod_step_for_npc()
		if _lod_phase < 0:
			_lod_phase = randi() % cur_step
		_lod_acc += delta
		_lod_tick += 1
		if (_lod_tick + _lod_phase) % cur_step != 0:
			return
		_lod_k = _lod_acc / delta if delta > 0.0 else 1.0
		delta = _lod_acc
		_lod_acc = 0.0
	elif _lod_acc > 0.0:
		delta += _lod_acc # Vuelve al detalle: recupera el tiempo pendiente
		_lod_acc = 0.0
	if perf_on:
		_physics_process_timed(delta)
		return
	if _process_inactive_states(delta):
		return
	_tick_frame_upkeep(delta)
	_tick_self_tending(delta)
	if _process_player_attention(delta):
		return
	if is_in_live_fight() and not is_hostile:
		_process_live_fight(delta)
		return
	if _process_duties(delta):
		return
	if is_hostile:
		_process_hostile_combat(delta)
		_finish_frame_movement(delta)
		return
	_update_needs_and_decisions(delta)
	if _process_hospital_care(delta):
		return
	_execute_dynamic_activity(delta)
	_finish_frame_movement(delta, true)

## B3 (medición): cronómetro por partes, solo lo enciende `tools/tests/perf_breakdown.gd`. Mismo orden y mismas
## llamadas que arriba; no cambia nada del comportamiento.

func _physics_process_timed(delta: float) -> void:
	var t: int = Time.get_ticks_usec()
	var stop: bool = _process_inactive_states(delta)
	t = _perf_add("inactive_states", t)
	if stop:
		return
	_tick_frame_upkeep(delta)
	t = _perf_add("frame_upkeep", t)
	_tick_self_tending(delta)
	t = _perf_add("self_tending", t)
	stop = _process_player_attention(delta)
	t = _perf_add("player_attention", t)
	if stop:
		return
	if is_in_live_fight() and not is_hostile:
		_process_live_fight(delta)
		_perf_add("live_fight", t)
		return
	stop = _process_duties(delta)
	t = _perf_add("duties", t)
	if stop:
		return
	if is_hostile:
		_process_hostile_combat(delta)
		_finish_frame_movement(delta)
		_perf_add("hostile", t)
		return
	_update_needs_and_decisions(delta)
	t = _perf_add("needs_decisions", t)
	stop = _process_hospital_care(delta)
	t = _perf_add("hospital_care", t)
	if stop:
		return
	_execute_dynamic_activity(delta)
	t = _perf_add("dynamic_activity", t)
	_finish_frame_movement(delta, true)
	_perf_add("movement", t)

## Estados en los que el vecino no actúa: muerto, agonizando, inconsciente, aturdido, sentado al póker o tiempo congelado.

func _process_inactive_states(delta: float) -> bool:
	if is_dead:
		velocity = Vector2.ZERO
		_stop_crafting_bar()
		_process_corpse_state(delta)
		return true

	if is_downed:
		velocity = Vector2.ZERO
		_stop_crafting_bar()
		if not (WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen()):
			bleedout_timer -= delta
		var pulse_r: float = 0.65 + absf(sin(bleedout_timer * 4.0)) * 0.35
		_set_sprite_pose(82.0, Color(1.15, pulse_r * 0.45, pulse_r * 0.45, 0.95))
		_update_world_tag_for_state(Color(0.96, 0.55, 0.52), "🩸")
		if bleedout_timer <= 0.0:
			_confirm_true_death()
		return true

	if sedated_timer > 0.0:
		if not (WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen()):
			sedated_timer -= delta
		velocity = Vector2.ZERO
		_stop_crafting_bar()
		is_sleeping = true
		if sprite:
			sprite.rotation_degrees = 90.0
		_scan_unconscious_victim_for_passersby(delta)
		_update_world_tag_for_state(Color(0.84, 0.78, 0.96), "💤")
		if sedated_timer <= 0.0:
			wake_up_from_unconscious()
		return true

	if is_stunned_flag:
		velocity = Vector2.ZERO
		_stop_crafting_bar()
		_scan_unconscious_victim_for_passersby(delta)
		_update_world_tag_for_state(Color(0.82, 0.88, 0.96), "💫")
		return true

	if is_at_poker_table:
		if poker_seat_pos != Vector2.ZERO and global_position.distance_to(poker_seat_pos) > 3.0:
			global_position = poker_seat_pos
		velocity = Vector2.ZERO
		_stop_crafting_bar()
		_update_visual_animation(delta)
		_update_hover_label()
		return true

	if WorldClock and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen():
		velocity = Vector2.ZERO
		_update_hover_label()
		return true
	return false

## Temporizadores y comprobaciones que corren en cada fotograma si el vecino está activo.

func _tick_frame_upkeep(delta: float) -> void:
	var vm_up = _get_vm()
	var same_elev_up: bool = vm_up == null or not vm_up.has_method("are_on_same_elevation") or bool(vm_up.call("are_on_same_elevation", elevation_level, vm_up.player_elevation_level))
	if body_col:
		body_col.disabled = not (is_hostile and same_elev_up)
	_get_vm()
	_get_player()
	if bloodstained_timer > 0.0:
		bloodstained_timer = maxf(0.0, bloodstained_timer - delta)
	if _npc_social_event_cooldown > 0.0:
		_npc_social_event_cooldown = maxf(0.0, _npc_social_event_cooldown - delta)
	if _pending_social_reply_timer > 0.0:
		_process_pending_social_reply(delta)
	if is_conscious():
		_update_visual_memory(delta)
	if health_comp and velocity.length_squared() > 9.0 and health_comp.is_resting_in_bed and _AN_SITIOS.desmover(global_position).distance_to(Vector2(718, 136)) > 26.0 and global_position.distance_to(bed_position) > 20.0:
		health_comp.is_resting_in_bed = false
	if not is_instance_valid(_cached_dm) and get_tree().current_scene:
		_cached_dm = get_tree().current_scene.get_node_or_null("Systems/dialogue_manager")

## Auto-cura de supervivencia (RimWorld Self-Tend): fuera de combate, si sangra se aplica un vendaje o torniquete rudimentario.

func _tick_self_tending(delta: float) -> void:
	if not is_hostile and health_comp and health_comp.get_total_wound_bleed_rate() > 0.0:
		_self_tend_timer += delta
		if _self_tend_timer >= 3.5:
			_self_tend_timer = 0.0
			var urg_wid: int = health_comp.get_most_urgent_untreated_wound_id(true)
			if urg_wid != -1:
				if remove_pocket_item("bandage", 1):
					health_comp.treat_wound(urg_wid, "bandage")
					_spawn_floating_text("🩹 %s se vendó su herida sangrante" % npc_name, Color.SPRING_GREEN, -38.0)
				else:
					health_comp.treat_wound(urg_wid, "tend_makeshift")
					_spawn_floating_text("🖐️🩹 %s se aplicó un torniquete rudimentario (Calidad 25%%)" % npc_name, Color(0.95, 0.80, 0.42), -38.0)
	else:
		_self_tend_timer = 0.0

## Se detiene y mira al jugador mientras habla con él o a quien lo interroga.

func _process_player_attention(delta: float) -> bool:
	var talking_to_player: bool = not is_hostile and is_instance_valid(_cached_dm) and bool(_cached_dm.get("active")) and _cached_dm.get("current_speaker") == self
	if talking_to_player or (_being_interviewed_timer > 0.0 and not is_hostile):
		if not talking_to_player:
			_being_interviewed_timer = maxf(0.0, _being_interviewed_timer - delta)
		velocity = Vector2.ZERO
		_stop_crafting_bar()
		_enforce_npc_personal_space(delta)
		var face_node: Node2D = _cached_player if talking_to_player else _interviewer_node
		if is_instance_valid(face_node) and sprite:
			sprite.flip_h = (face_node.global_position.x < global_position.x)
		trigger_action_animation(0.4)
		_update_visual_animation(delta)
		_update_hover_label(delta)
		return true
	return false

## Obligaciones por orden de prioridad: escolta, urgencias, emergencias vecinales, policía, investigación y ruta comercial.

func _process_duties(delta: float) -> bool:
	var vm_escort = _cached_vm
	if vm_escort and vm_escort.VillageJustice.process_npc_jail_step(vm_escort, self, delta):
		return true
	if vm_escort and bool(vm_escort.get("player_being_escorted_to_jail")) and vm_escort.get("escorting_officer") == self:
		var jail_target: Vector2 = vm_escort.get("_jail_cell_pos")
		_move_towards_point(jail_target, 64.0, delta)
		_finish_frame_movement(delta)
		return true

	if _process_doctor_duty(delta):
		return true

	if not is_hostile and (_process_witness_corpse_reporting(delta) or _process_corpse_morgue_transport(delta) or _process_family_missing_search(delta) or _process_unconscious_neighbor_reaction(delta)):
		return true

	if _process_police_duty(delta):
		return true

	if not is_hostile and _process_noise_reaction(delta):
		return true

	if trade_role == TradeRole.ROYAL_INVESTIGATOR:
		if is_hostile:
			_police_alerted_timer = maxf(_police_alerted_timer, 25.0)
			if is_instance_valid(_cached_player):
				_last_seen_player_pos = _cached_player.global_position
		_process_royal_investigator_ai(delta)
		return true

	if trade_role == TradeRole.TRAVELING_MERCHANT and not is_hostile:
		_process_traveling_merchant_routine(delta)
		return true

	# Bloque PH: Si este vecino es el acompañante activo del jugador, camina a su lado durante el día
	if not is_hostile and vm_escort != null and not (vm_escort.has_method("is_demo_mode") and bool(vm_escort.call("is_demo_mode"))) and "VillageFame" in vm_escort and vm_escort.VillageFame != null and vm_escort.VillageFame.is_companion(vm_escort, self):
		var h_comp: int = int(WorldClock.current_hour) if WorldClock != null else 12
		if h_comp >= 6 and h_comp < 22 and need_hunger > 25.0 and need_energy > 15.0 and is_instance_valid(_cached_player):
			_stop_crafting_bar()
			_approach_or_stop(_cached_player.global_position + Vector2(-22, 14), 24.0, 56.0, delta)
			_finish_frame_movement(delta)
			return true
	return false

## El médico atiende primero a los agonizantes y luego a sus pacientes del hospital.

func _process_hostile_combat(delta: float) -> void:
	var vm = _get_vm()
	# Si la policía ya capturó al jugador, lo lleva esposado a la comisaría, está en la celda o está negociando su entrega,
	# los civiles y guardias detienen de inmediato la agresión física (Kenshi / RDR2 / Skyrim)
	if vm and (bool(vm.get("player_being_escorted_to_jail")) or bool(vm.get("player_in_jail")) or (vm.get("police_panel") != null and vm.police_panel.visible)):
		_clear_combat_hostility(false)
		velocity = Vector2.ZERO
		return

	if _stagger_timer > 0.0:
		_stagger_timer = maxf(0.0, _stagger_timer - delta)
		_melee_windup_timer = 0.0
		velocity = Vector2.ZERO
		if _stagger_timer <= 0.0 and sprite:
			sprite.modulate = Color.WHITE
		return

	var player = _get_player()
	if not player:
		velocity = Vector2.ZERO
		return
	if vm and vm.has_method("are_on_same_elevation") and not bool(vm.call("are_on_same_elevation", elevation_level, vm.player_elevation_level)):
		_melee_windup_timer = 0.0
		velocity = Vector2.ZERO
		return

	var is_police_unit: bool = (trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.ROYAL_INVESTIGATOR])
	if not is_police_unit:
		if _civilian_hostile_timer > 0.0:
			_civilian_hostile_timer -= delta
			if _civilian_hostile_timer <= 0.0:
				_clear_combat_hostility(false)
				velocity = Vector2.ZERO
				_spawn_floating_text("😤 ¡Que la guardia se encargue de ti!", Color.GOLD, -36.0)
				return
		# Los civiles nunca entran a la Comisaría / Celda (`Rect2(832, 92, 166, 108)`) para seguir golpeando al jugador
		var police_station_rect := Rect2(832, 92, 166, 108)
		if police_station_rect.has_point(_AN_SITIOS.desmover(player.global_position)) or police_station_rect.has_point(_AN_SITIOS.desmover(global_position)):
			_clear_combat_hostility(false)
			velocity = Vector2.ZERO
			return

	if _melee_recover_timer > 0.0:
		_melee_recover_timer = maxf(0.0, _melee_recover_timer - delta)
		velocity = Vector2.ZERO
		return
	if _melee_windup_timer > 0.0:
		_melee_windup_timer = maxf(0.0, _melee_windup_timer - delta)
		velocity = Vector2.ZERO
		if _melee_windup_timer <= 0.0:
			_attack_timer = 1.0
			if sprite:
				sprite.modulate = Color.WHITE
			var af: Dictionary = _CombatFeel.attack_feel("porra" if is_police_unit else "puño")
			_CombatFeel.enemy_swing(self, "porra" if is_police_unit else "puño")
			if is_instance_valid(player) and global_position.distance_to(player.global_position) <= 34.0 and player.has_method("take_damage"):
				var d := DamageData.new()
				var armed_pol: bool = is_police_unit and not is_disarmed()
				d.amount = 14.0 if armed_pol else 9.0
				d.weapon_tag = "Porra Policial" if armed_pol else ("Golpe de " + npc_name)
				d.knockback_force = float(af["push"])
				d.source = self
				player.call("take_damage", d)
				_melee_recover_timer = float(af["recover"])
			else:
				_melee_recover_timer = float(af["miss_recover"])
		return

	var dist: float = global_position.distance_to(player.global_position)
	if dist > 30.0:
		_move_towards_point(player.global_position, 88.0, delta)
	else:
		velocity = Vector2.ZERO
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_melee_windup_timer = 0.40
			trigger_action_animation(0.45)
			if sprite:
				sprite.modulate = Color(1.35, 0.9, 0.45)
			_spawn_floating_text("❗", Color.ORANGE_RED, -36.0)

func take_damage(data: DamageData) -> void:
	if is_dead:
		return

	# Identificar arma y atacante para la autopsia forense (Paso 1 y Paso 2)
	if data and is_instance_valid(data.source):
		if data.source.is_in_group("player_trap"):
			last_hit_by_player = true
			last_hit_weapon_name = "Cepo de Acero"
		elif data.source.is_in_group("player"):
			last_hit_by_player = true
			var eq_w: Variant = data.source.get("equipped_weapon")
			if data.weapon_tag != "": last_hit_weapon_name = data.weapon_tag
			elif eq_w == data.source.get("bow_weapon"): last_hit_weapon_name = "Impacto de Flecha (Arco)"
			elif eq_w == data.source.get("hammer_weapon"): last_hit_weapon_name = "Traumatismo Contundente (Martillo)"
			elif eq_w == data.source.get("axe_weapon"): last_hit_weapon_name = "Tajo Profundo de Hacha"
			elif eq_w == data.source.get("pickaxe_weapon"): last_hit_weapon_name = "Impacto de Pico Minero"
			elif eq_w == data.source.get("sickle_weapon"): last_hit_weapon_name = "Corte de Hoz Agrícola"
			else: last_hit_weapon_name = "Corte de Espada"
		else:
			last_hit_by_player = false
			last_hit_weapon_name = death_cause_for_source(data.source)

	# Si ya está agonizando en el suelo y vuelven a golpearlo -> Rematar (muerte definitiva)
	if is_downed:
		_confirm_true_death()
		var vm_exec = get_tree().get_first_node_in_group("village_manager")
		if vm_exec and last_hit_by_player and murder_witness_name != "":
			if vm_exec.has_method("modify_family_reputation") and family_id != "none":
				vm_exec.call("modify_family_reputation", family_id, -35, "Ejecución de " + npc_name, self)
			if vm_exec.has_method("report_assault_crime"):
				vm_exec.call("report_assault_crime", self)
		return

	# P6: pelea a puño limpio en el club del sótano: sin delito ni muerte; nunca baja del 20 % (se rinde)
	if bool(get_meta("club_bout", false)) and data != null and health_comp != null:
		var club_floor: float = health_comp.get_effective_max_health() * 0.20
		data.amount = minf(data.amount, maxf(0.0, health_comp.current_health - club_floor))
		data.bleed_buildup = 0.0
		if data.amount > 0.0:
			health_comp.take_damage(data)
		return

	var vm = get_tree().get_first_node_in_group("village_manager")
	if last_hit_by_player:
		modify_affinity(-35)
		if vm:
			if vm.has_method("modify_family_reputation") and family_id != "none":
				vm.call("modify_family_reputation", family_id, -25, "Agresión a " + npc_name, self)
			if vm.has_method("report_assault_crime"):
				vm.call("report_assault_crime", self)

	is_hostile = true
	_civilian_hostile_timer = 14.0
	is_sleeping = false
	sedated_timer = 0.0
	_stop_crafting_bar()
	if not (stun_comp and stun_comp.is_stunned):
		is_stunned_flag = false
		if sprite and not is_dead and not is_downed:
			sprite.rotation_degrees = 0.0
			sprite.modulate = Color.WHITE
	current_activity = ActivityState.WORKING
	add_to_group("enemies")
	if trade_role == TradeRole.ROYAL_INVESTIGATOR and vm and "active_royal_investigation" in vm:
		var inv_dict: Dictionary = vm.active_royal_investigation
		if bool(inv_dict.get("active", false)) and str(inv_dict.get("stage", "")) != "HUNTING_PLAYER":
			inv_dict["stage"] = "HUNTING_PLAYER"
			inv_dict["verdict_target"] = "Jugador"
			inv_dict["verdict_reason"] = "Agresión directa al Inquisidor Real Alistair."
			vm.wanted_level = 5
			vm.bounty_gold = int(vm.bounty_gold) + 250
			vm.is_resisting_arrest = true
			_police_alerted_timer = 65.0
	if health_comp:
		health_comp.take_damage(data)
	if stun_comp and health_comp and health_comp.current_health > 0.0:
		stun_comp.take_damage(data)
	if data != null and data.amount >= 6.0 and AudioManager:
		AudioManager.emit_noise(global_position, 175.0, elevation_level, "pain_scream")

## Comprueba si el jugador en Sigilo (`[C]`) está situado por la espalda del NPC (o junto a un NPC dormido) para ejecutar un ataque sigiloso (No Letal o Letal)

func can_be_stealth_targeted(player: Node2D) -> bool:
	var vm = _get_vm()
	if vm and (bool(vm.get("player_being_escorted_to_jail")) or bool(vm.get("player_in_jail"))):
		return false
	if player == null or is_dead or is_downed or is_hostile or is_at_poker_table or is_stunned_flag or sedated_timer > 0.0 or trade_role == TradeRole.ROYAL_INVESTIGATOR:
		return false
	if not player.has_method("is_stealthing") or not bool(player.call("is_stealthing")):
		return false
	var to_player: Vector2 = player.global_position - global_position
	var dist_sq: float = to_player.length_squared()
	if dist_sq > 29.0 * 29.0 or dist_sq < 0.01:
		return false
	if is_sleeping:
		return true
	var face_vec: Vector2 = facing_direction
	if face_vec.length_squared() < 0.01 and sprite != null:
		face_vec = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	return face_vec.normalized().dot(to_player.normalized()) <= 0.22

## Opción No Letal en Sigilo ([E] o [Q] por la espalda): Aturde / deja inconsciente al civil sin matarlo

func stealth_knockout(player: Node = null) -> void:
	if is_dead or is_downed or is_stunned_flag or sedated_timer > 0.0:
		return
	hide_prompt()
	if is_instance_valid(_reporting_corpse_target) and _reporting_corpse_target.corpse_reporter_npc == self:
		_reporting_corpse_target.corpse_reporter_npc = null
	_reporting_corpse_target = null
	_clear_unconscious_reaction_state()
	_stop_crafting_bar()
	_clear_combat_hostility()
	velocity = Vector2.ZERO
	sedated_timer = maxf(sedated_timer, 25.0)
	is_sleeping = true
	is_stunned_flag = true
	_unconscious_ignored_by.clear()
	_unconscious_helper_npc = null
	_set_sprite_pose(90.0, Color(0.55, 0.65, 1.0))
	add_thought("Aturdido por la espalda (-12)", -12.0)
	_spawn_floating_text("💤🤫 ¡%s aturdido en sigilo! (No Letal — 25s)" % npc_name, Color.AQUA, -44.0)
	if player and player.has_method("add_skill_xp"):
		player.call("add_skill_xp", "stealth", 10)
	if player and player.has_method("show_hint"):
		player.call("show_hint", "💤 Has aturdido en sigilo a %s sin matarlo (Inconsciente durante 25s)." % npc_name)

	var vm = _get_vm()
	if vm and vm.has_method("_find_conscious_witness_near"):
		var w: VillageNPC = vm.call("_find_conscious_witness_near", global_position, 145.0, self)
		if w != null:
			var w_rel: int = w.get_relationship_with_npc(npc_name)
			var w_same_fam: bool = (family_id != "none" and family_id != "" and family_id != "family_police" and w.family_id == family_id)
			var w_is_auth: bool = w.trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.DOCTOR]
			if w_rel <= -25 and not w_same_fam and not w_is_auth:
				w._spawn_floating_text("😏🤫 %s vio caer a su enemigo %s y no piensa decir ni pío a la guardia..." % [w.npc_name, npc_name], Color.GOLD, -42.0)
			elif vm.has_method("report_assault_crime"):
				vm.call("report_assault_crime", self)

## Opción Letal en Sigilo ([Clic Izq.] o [V] por la espalda): Ejecución silenciosa instantánea

func stealth_assassinate(player: Node = null) -> void:
	if is_dead:
		return
	hide_prompt()
	last_hit_by_player = true
	var w_label := "Puñalada por la Espalda (Hoja Afilada)"
	var w_type := "Corte / Puñalada"
	var w_part := "Neck"
	var w_bleed := 2.8
	if player != null and is_instance_valid(player):
		var eq_w: Variant = player.get("equipped_weapon")
		if eq_w != null and eq_w == player.get("hammer_weapon"):
			w_label = "Traumatismo Contundente por la Espalda (Martillo)"
			w_type = "Contusión / Fractura"
			w_part = "Head"
			w_bleed = 0.6
		elif eq_w != null and eq_w == player.get("axe_weapon"):
			w_label = "Tajo Profundo por la Espalda (Hacha)"
			w_type = "Tajo Profundo"
			w_part = "Torso"
			w_bleed = 3.2
		elif eq_w != null and eq_w == player.get("pickaxe_weapon"):
			w_label = "Impacto de Pico Minero por la Espalda"
			w_type = "Perforación Profunda"
			w_part = "Torso"
			w_bleed = 2.4
		elif eq_w != null and eq_w == player.get("sickle_weapon"):
			w_label = "Corte de Hoz Agrícola por la Espalda"
			w_type = "Corte"
			w_part = "Neck"
			w_bleed = 2.8
		elif eq_w != null and eq_w == player.get("bow_weapon"):
			w_label = "Ejecución Silenciosa por la Espalda (Cuchillo)"
		else:
			w_label = "Corte Letal por la Espalda (Espada)"
	last_hit_weapon_name = w_label
	if health_comp != null:
		health_comp.wounds.append({
			"id": health_comp._next_wound_id,
			"part": w_part,
			"type": w_type,
			"severity": 44.0,
			"bleeding": w_bleed,
			"pain": 32.0,
			"bandaged": false,
			"bandage_quality": 0.0,
			"infection": 0.0,
			"heal_rate": 0.0,
			"permanent": false,
			"source_tag": last_hit_weapon_name,
		})
		health_comp._next_wound_id += 1
	_confirm_true_death()
	_spawn_floating_text("🗡️🩸 ¡Asesinato sigiloso! (%s eliminado)" % npc_name, Color.CRIMSON, -48.0)
	if player and player.has_method("show_hint"):
		if murder_witness_name != "":
			player.call("show_hint", "🗡️👁️ ¡%s te vio asesinar a %s! Irá a examinar el cuerpo (10s) y luego a avisar en persona a la policía si no lo silencias o detienes." % [murder_witness_name, npc_name])
		else:
			player.call("show_hint", "🗡️🤫 Asesinato sigiloso sin testigos: el cuerpo de %s queda en el suelo." % npc_name)
	var vm = _get_vm()
	if murder_witness_name != "" and vm and vm.has_method("report_assault_crime"):
		vm.call("report_assault_crime", self)

func knockout() -> void:
	stealth_knockout(_get_player())

func _on_stunned(stunned: bool) -> void:
	if is_dead or is_downed:
		return
	is_stunned_flag = stunned or (sedated_timer > 0.0)
	if is_stunned_flag:
		if is_instance_valid(_reporting_corpse_target) and _reporting_corpse_target.corpse_reporter_npc == self:
			_reporting_corpse_target.corpse_reporter_npc = null
		_reporting_corpse_target = null
		_stop_crafting_bar()
		_clear_combat_hostility()
		velocity = Vector2.ZERO
		_set_sprite_pose(90.0, Color(0.55, 0.65, 1.0))
	else:
		_set_sprite_pose(0.0)

## Paso 1: Al caer a 0 HP entra primero en estado "Agonizando" (`is_downed`) con cuenta atrás según la herida

func _on_died() -> void:
	if is_dead:
		return
	var vm_bld = _get_vm()
	if health_comp:
		if health_comp.current_blood >= 99.0 and not ("Desangrado" in last_hit_weapon_name):
			last_hit_weapon_name = "%s (Exanguinación / Desangrado)" % (last_hit_weapon_name if last_hit_weapon_name != "" else "Hemorragia")
		if health_comp.last_sickness_cause != "" and (health_comp.fever >= 70.0 or health_comp.food_poisoning >= 70.0 or health_comp.swamp_sickness >= 70.0 or health_comp.get_max_wound_infection() >= 90.0):
			last_hit_weapon_name = "Envenenamiento / Sepsis (%s)" % health_comp.last_sickness_cause
		for vital_o in ["heart", "liver", "lungs", "kidneys", "brain"]:
			if float(health_comp.organ_hp.get(vital_o, 100.0)) <= 0.0:
				_confirm_true_death()
				return
		if health_comp.current_blood >= 99.9 or health_comp.get_max_wound_infection() >= 99.9:
			_confirm_true_death()
			return
	if vm_bld and vm_bld.has_method("spawn_blood_puddle") and not ("Envenenamiento" in last_hit_weapon_name or "Inanición" in last_hit_weapon_name):
		vm_bld.call("spawn_blood_puddle", global_position, npc_name)
	if not is_downed:
		is_downed = true
		is_sleeping = false
		sedated_timer = 0.0
		is_stunned_flag = false
		_stop_crafting_bar()
		_clear_combat_hostility()
		velocity = Vector2.ZERO
		if last_hit_weapon_name.contains("Martillo"): bleedout_timer = 90.0
		elif last_hit_weapon_name.contains("Espada") or last_hit_weapon_name.contains("Hacha"): bleedout_timer = 48.0
		else: bleedout_timer = 68.0
		_set_sprite_pose(82.0, Color(1.1, 0.42, 0.42, 0.95))
		_spawn_floating_text("🩸 ¡%s AGONIZANDO! (%ds para salvarlo en el Hospital)" % [npc_name, int(bleedout_timer)], Color.ORANGE_RED, -44.0)
		if last_hit_by_player and not ("Arco" in last_hit_weapon_name or "Envenenamiento" in last_hit_weapon_name):
			var p_down := _get_player()
			if p_down and p_down.has_method("add_bloodstain") and p_down.global_position.distance_to(global_position) <= 135.0:
				p_down.call("add_bloodstain", 180.0)
		return
	_confirm_true_death()

## Paso 1: Rescatar a un NPC que está agonizando (`is_downed`) llevándolo al Hospital o con un Botiquín Quirúrgico

func revive_from_downed(rescuer: Node, used_surgical_kit: bool = false) -> void:
	if not is_downed or is_dead:
		return
	is_downed = false
	bleedout_timer = 0.0
	is_stunned_flag = false
	sedated_timer = 0.0
	_clear_combat_hostility(false)
	if stun_comp:
		stun_comp.clear_stun()
	_set_area_col_disabled(hurtbox, false)
	if health_comp:
		if health_comp.last_sickness_cause != "" and (health_comp.fever >= 70.0 or health_comp.food_poisoning >= 70.0 or health_comp.swamp_sickness >= 70.0):
			last_hit_weapon_name = "Envenenamiento / Sepsis (%s)" % health_comp.last_sickness_cause
		for vital_o in ["heart", "liver", "lungs", "kidneys", "brain"]:
			if float(health_comp.organ_hp.get(vital_o, 100.0)) <= 0.0:
				_confirm_true_death()
				return
		if used_surgical_kit:
			health_comp.stop_bleeding()
			health_comp.current_blood = minf(health_comp.current_blood, 45.0)
			health_comp.current_health = health_comp.get_effective_max_health() * 0.75
		else:
			# Estabilización de urgencia en camilla: aplica solo 1 torniquete de emergencia a la peor herida; el Dr. Valen debe curar el resto herida por herida
			var worst_w: int = health_comp.get_most_urgent_untreated_wound_id(true)
			if worst_w != -1:
				health_comp.treat_wound(worst_w, "tend_makeshift")
			health_comp.current_blood = minf(health_comp.current_blood, 82.0)
			health_comp.current_health = maxf(health_comp.current_health, health_comp.get_effective_max_health() * 0.35)
			health_comp.is_resting_in_bed = true
		health_comp.blood_changed.emit(health_comp.current_blood, health_comp.max_blood)
		health_comp.health_changed.emit(health_comp.current_health, health_comp.max_health)
	if not used_surgical_kit:
		global_position = _AN_SITIOS.mover(Vector2(718, 136))
	_set_sprite_pose(0.0)
	add_thought("Me trasladaron a urgencias (+25)", 25.0)
	if rescuer and rescuer.is_in_group("player"):
		modify_affinity(45)
		var vm = _get_vm()
		if vm and vm.has_method("modify_family_reputation") and family_id != "none":
			vm.call("modify_family_reputation", family_id, 40, "Salvó la vida de " + npc_name, self)
		if vm and not (vm.has_method("is_demo_mode") and bool(vm.call("is_demo_mode"))):
			vm.VillageClans.grant_honor_debt(vm, self, "salvó la vida de " + npc_name)
		if "inventory" in rescuer and rescuer.inventory:
			rescuer.inventory.add_gold(25)
		if rescuer.has_method("_spawn_floating_text"):
			rescuer._spawn_floating_text("🏥 ¡Trasladaste a %s al Hospital! (+25 Oro, el Dr. Valen tratará sus heridas)" % npc_name, Color.SPRING_GREEN, -46.0)

## Paso 1: Muerte definitiva -> el cadáver permanece en el lugar donde murió (y puede pudrirse durante días si nadie entra),
## hasta que otro NPC lo vea en sus pasos naturales y lo traslade físicamente a la Morgue Forense.

func _confirm_true_death() -> void:
	if is_dead:
		return
	if health_comp:
		health_comp.stop_bleeding()
	death_world_pos = global_position
	death_day = WorldClock.current_day if WorldClock else 1
	death_hour = WorldClock.current_hour if WorldClock else 12
	death_minute = WorldClock.current_minute if WorldClock else 0

	var vm = _get_vm()
	if vm and vm.has_method("spawn_blood_puddle") and not ("Envenenamiento" in last_hit_weapon_name or "Inanición" in last_hit_weapon_name):
		vm.call("spawn_blood_puddle", death_world_pos, npc_name)
	var direct_witness_node: VillageNPC = null
	murder_witness_name = ""
	if vm and vm.has_method("_find_conscious_witness_near"):
		var w: VillageNPC = vm.call("_find_conscious_witness_near", death_world_pos, 165.0, self)
		if w != null and not (last_hit_by_player and w.witness_silenced_player):
			murder_witness_name = w.npc_name
			direct_witness_node = w

	is_downed = false
	bleedout_timer = 0.0
	is_dead = true
	if vm and not (vm.has_method("is_demo_mode") and bool(vm.call("is_demo_mode"))):
		vm.VillageClans.on_npc_death(vm, self)
	var my_dead_id: String = str(person_profile.person_id) if person_profile != null and str(person_profile.person_id) != "" else npc_id
	if is_inside_tree():
		for n_other in get_tree().get_nodes_in_group("village_npcs"):
			if n_other is VillageNPC and n_other != self and not n_other.is_dead:
				var vo := n_other as VillageNPC
				if vo.person_profile != null and str(vo.person_profile.partner_id) == my_dead_id:
					vo.person_profile.start_bereavement(npc_name, 5)
					vo.clear_hangout()
					vo.add_thought("Duelo por la muerte de mi pareja %s (-18)" % npc_name, -18.0)
					if vm and vm.has_method("record_social_event"):
						vm.call("record_social_event", "widowed", vo, self, "%s quedó viudo/a tras la muerte de %s" % [vo.npc_name, npc_name])
				vo.purge_deceased_relationship(my_dead_id, npc_name)
	if vm and vm.get("social_director") != null:
		vm.get("social_director").call("purge_deceased", my_dead_id)
	_stop_crafting_bar()
	corpse_on_ground = true
	corpse_discovered = false
	corpse_discovered_by = ""
	corpse_reported = false
	corpse_reporter_npc = null
	corpse_being_carried = false
	corpse_in_morgue = false
	corpse_buried = false
	corpse_carrier = null
	corpse_rot_hours = 0.0
	if is_instance_valid(direct_witness_node) and not (direct_witness_node.trade_role in [TradeRole.ROYAL_INVESTIGATOR, TradeRole.TRAVELING_MERCHANT]):
		begin_physical_corpse_discovery(direct_witness_node)
	_clear_combat_hostility()
	_set_area_col_disabled(hurtbox, true)
	_set_area_col_disabled(interact_area, false)
	if sprite:
		_set_sprite_pose(90.0, Color(0.68, 0.54, 0.54, 0.96))
		sprite.z_index = -1
		sprite.visible = true
	_spawn_floating_text("💀 %s ha muerto (El cuerpo yace en el lugar)" % npc_name, Color(0.88, 0.45, 0.45), -44.0)
	if last_hit_by_player and not ("Arco" in last_hit_weapon_name or "Envenenamiento" in last_hit_weapon_name):
		var p_killer := _get_player()
		if p_killer and p_killer.has_method("add_bloodstain") and p_killer.global_position.distance_to(global_position) <= 180.0:
			p_killer.call("add_bloodstain", 180.0)
	if trade_role == TradeRole.TRAVELING_MERCHANT and merchant_id in ["high_pass", "river_port", "sun_plain"]:
		var vm_c = _get_vm()
		if vm_c != null and "merchant_suspension_days" in vm_c:
			vm_c.merchant_suspension_days[merchant_id] = 7
	# El Inquisidor Real Alistair NO viene apenas muere el comerciante: solo es convocado cuando alguien descubre y reporta el cadáver (`_notify_corpse_reported_to_authorities`)

## Sucesión: este familiar o viajero sin oficio asume un puesto vacante en la aldea

func get_pickpocket_success_chance(player: Node) -> float:
	if is_dead or is_downed or is_sleeping or sedated_timer > 0.0 or is_stunned_flag:
		return 1.0
	var chance: float = 0.58
	if player:
		var phc: HealthComponent = player.get_node_or_null("HealthComponent")
		if phc:
			var manip: float = float(phc.get_capacities().get("manipulation", 1.0))
			chance *= clampf(0.45 + manip * 0.60, 0.25, 1.15)
		if player.has_method("has_master_lockpick") and bool(player.call("has_master_lockpick")):
			chance += 0.20
		if player.has_method("get_stealth_detection_multiplier") and float(player.call("get_stealth_detection_multiplier")) < 0.8:
			chance += 0.14
	if health_comp:
		var npc_consc: float = float(health_comp.get_capacities().get("consciousness", 1.0))
		chance += (1.0 - npc_consc) * 0.30
	return clampf(chance, 0.15, 0.96)

func attempt_pickpocket_or_plant(player: Node, mode: String, item_id: String = "") -> bool:
	if not player or not ("inventory" in player) or not player.inventory:
		return false
	var inv: SimpleInventory = player.inventory
	var chance: float = get_pickpocket_success_chance(player)
	if randf() > chance:
		modify_affinity(-25)
		add_thought("¡Sorprendí al Forastero hurgando en mis bolsillos! (-25)", -25.0)
		_spawn_floating_text("🚨👁️ ¡%s te descubrió hurgando en su bolsillo!" % npc_name, Color.ORANGE_RED, -46.0)
		var vm = _get_vm()
		if vm and vm.has_method("report_theft_crime"):
			vm.call("report_theft_crime", family_id, "Hurto fallido en los bolsillos de " + npc_name, global_position)
		return false

	if mode == "steal_gold":
		if personal_gold <= 0:
			return false
		var stolen_g: int = personal_gold
		personal_gold = 0
		inv.add_gold(stolen_g)
		if player.has_method("add_skill_xp"):
			player.call("add_skill_xp", "stealth", 8)
		_spawn_floating_text("🕵️💰 Hurtaste +%d Oro de %s en sigilo" % [stolen_g, npc_name], Color.GOLD, -44.0)
		return true
	elif mode == "steal_item":
		if not remove_pocket_item(item_id, 1):
			return false
		inv.add_item(item_id, 1)
		_spawn_floating_text("🕵️🤏 Hurtaste 1x %s de %s" % [inv.get_item_name(item_id), npc_name], Color.AQUA, -44.0)
		return true
	elif mode == "plant_item":
		if not inv.remove_item(item_id, 1):
			return false
		add_pocket_item(item_id, 1)
		_spawn_floating_text("🕵️📥 Metiste 1x %s en el bolsillo de %s" % [inv.get_item_name(item_id), npc_name], Color.VIOLET, -44.0)
		return true
	return false

func loot_npc_pockets(player: Node) -> bool:
	if carries_royal_safe_conduct and int(pocket_items.get("royal_safe_conduct", 0)) <= 0:
		pocket_items["royal_safe_conduct"] = 1
	if corpse_pocket_looted or (personal_gold <= 0 and pocket_items.is_empty()):
		return false
	if not player or not ("inventory" in player) or not player.inventory:
		return false
	var inv: SimpleInventory = player.inventory
	var looted_gold: int = maxi(0, personal_gold)
	var got_seal: bool = has_pocket_item("royal_safe_conduct", 1)
	var item_names: Array[String] = []
	for pk in pocket_items.keys():
		var cnt: int = int(pocket_items[pk])
		if cnt > 0:
			inv.add_item(str(pk), cnt)
			item_names.append("%s x%d" % [inv.get_item_name(str(pk)), cnt])
	personal_gold = 0
	pocket_items.clear()
	carries_royal_safe_conduct = false
	corpse_pocket_looted = true
	if looted_gold > 0:
		inv.add_gold(looted_gold)
	var msg: String = "💰 Saqueaste +%d Oro de %s" % [looted_gold, npc_name]
	if not item_names.is_empty():
		msg += " + [" + ", ".join(item_names) + "]"
	_spawn_floating_text(msg, Color.GOLD, -44.0)
	if player.has_method("show_hint"):
		player.call("show_hint", msg + (" (Oculta o planta el Salvoconducto Real si viene el Inquisidor Real)" if got_seal else ""))
	var vm = get_tree().get_first_node_in_group("village_manager")
	if vm and vm.has_method("_find_conscious_witness_near"):
		var w: VillageNPC = vm.call("_find_conscious_witness_near", global_position, 140.0, self)
		if w != null and vm.has_method("report_theft_crime"):
			vm.call("report_theft_crime", family_id, "Saqueo de bolsillos a " + npc_name, global_position)
	return true

func interact(player: Node) -> void:
	var vm_nj = _get_vm()
	if vm_nj != null and not (vm_nj.has_method("is_demo_mode") and bool(vm_nj.call("is_demo_mode"))) and not is_dead and vm_nj.VillageNightJobs.try_player_catch(vm_nj, self, player):
		return # P6b: lo pillas en plena faena nocturna
	if is_dead:
		if corpse_buried:
			return
		var cs_ui = get_tree().current_scene if is_inside_tree() else null
		var ui_root = cs_ui.get_node_or_null("UI/UIRoot") if cs_ui else null
		if ui_root == null and cs_ui != null:
			ui_root = cs_ui.get_node_or_null("UIRoot")
		if ui_root == null and is_inside_tree():
			ui_root = get_tree().get_first_node_in_group("game_ui")
		if ui_root != null and ui_root.has_method("open_detective_ui"):
			ui_root.call("open_detective_ui", self, "morgue" if corpse_in_morgue else "body")
			return
		if not corpse_pocket_looted and (personal_gold > 0 or carries_royal_safe_conduct or not pocket_items.is_empty()):
			loot_npc_pockets(player)
			return
		if corpse_in_morgue:
			var vm_m = _get_vm()
			if vm_m and vm_m.has_method("_open_morgue_autopsy_ui"):
				vm_m.call("_open_morgue_autopsy_ui")
			return
		report_corpse_by_player(player)
		return
	if is_downed:
		revive_from_downed(player, false)
		return
	if is_stunned_flag or sedated_timer > 0.0:
		loot_npc_pockets(player)
		return
	if player is Node2D and can_be_stealth_targeted(player as Node2D):
		stealth_knockout(player)
		return
	if is_hostile:
		return
	_start_npc_dialogue(player)

func _start_npc_dialogue(player: Node) -> void:
	# Al conversar con el jugador, el NPC detiene lo que está haciendo, mira al jugador y satisface parte de su necesidad social
	velocity = Vector2.ZERO
	_stop_crafting_bar()
	if player is Node2D and sprite:
		sprite.flip_h = ((player as Node2D).global_position.x < global_position.x)
	trigger_action_animation(0.8)
	need_social = minf(100.0, need_social + 18.0)
	var dm = get_tree().current_scene.get_node_or_null("Systems/dialogue_manager")
	if not dm:
		return
	_cached_dm = dm
	var diag := _inject_character_lore_into_dialogue(_build_dialogue())
	dm.call("start_dialogue", diag, "start", self)

## Abre directamente la rueda de diálogo de Defensa de Interrogatorio RPG (3 Rondas) cuando la policía o el Inquisidor interrogan al jugador

func start_interrogation_dialogue_with_player(player: Node) -> bool:
	_interrog_correct_steps = 0
	_interrog_penalty_acc = 0
	velocity = Vector2.ZERO
	_stop_crafting_bar()
	if player is Node2D and sprite:
		sprite.flip_h = ((player as Node2D).global_position.x < global_position.x)
	trigger_action_animation(0.8)
	var dm: Node = null
	if get_tree() and get_tree().current_scene:
		dm = get_tree().current_scene.get_node_or_null("Systems/dialogue_manager")
	if not dm and get_tree() and get_tree().root:
		dm = get_tree().root.find_child("dialogue_manager", true, false)
	if not dm:
		return false
	if dm.has_method("is_active") and bool(dm.call("is_active")):
		return false
	_cached_dm = dm
	var diag := _inject_character_lore_into_dialogue(_build_dialogue())
	if not diag.has("interrogation_r1"):
		return false
	dm.call("start_dialogue", diag, "interrogation_r1", self)
	return true

func _get_needs_status_line() -> String:
	var traits_str: String = ", ".join(traits) if not traits.is_empty() else "Equilibrado"
	var last_thought: String = thoughts[0] if not thoughts.is_empty() else "Todo tranquilo"
	var fav_name: String = str(SimpleInventory.CATALOG.get(favorite_item, {}).get("name", favorite_item))
	var eff_info: String = ""
	if not (trade_role in [TradeRole.UNEMPLOYED, TradeRole.FAMILY_MEMBER, TradeRole.NOBLE, TradeRole.CHILD]): # Nobles y niños no tienen oficio
		var shop_state: String = ""
		if trade_role in SHOP_ROLES or trade_role == TradeRole.INNKEEPER:
			shop_state = " · 🟢 En Mostrador" if is_at_shop_counter() else " · 🔴 Fuera del Mostrador (No vende aquí)"
		eff_info = " | ⚒️ Dominio: %s%s" % [get_job_efficiency_label(), shop_state]
	var seal_str: String = " · 📜Salvoconducto Real" if carries_royal_safe_conduct else ""
	var vm_d = _get_vm()
	if vm_d != null and not (vm_d.has_method("is_demo_mode") and bool(vm_d.call("is_demo_mode"))) and vm_d.has_method("_get_npcs_by_person_key"): # H: deuda de la casa
		var debt: String = vm_d.VillageLoans.debt_text(vm_d, self)
		if debt != "":
			seal_str += " · " + debt
	return "[%s%s | 💰 Oro: %d%s | 😊 Humor: %d%% | 🍖%d%% (%s) 💤%d%% (%s) 💬%d%%]\n[Rasgos: %s | Favorito: %s | 💭 \"%s\"]" % [
		get_activity_description(), eff_info, maxi(0, personal_gold), seal_str, int(round(mood)),
		int(round(need_hunger)), get_nutrition_status_label(), int(round(need_energy)), get_sleep_status_label(), int(round(need_social)),
		traits_str, fav_name, last_thought
	]

func _get_market_header_line() -> String:
	var vm = _get_vm()
	if not vm:
		return ""
	var mkt_txt: String = str(vm.call("get_trade_market_status_text", int(trade_role))) if vm.has_method("get_trade_market_status_text") else "⚖️ Estable"
	var own_badge: String = str(vm.call("get_business_owner_badge", int(trade_role))) if vm.has_method("get_business_owner_badge") else ""
	return "\n[📊 Oferta/Demanda: %s%s]" % [mkt_txt, own_badge]

func _get_dynamic_sell_price(base_price: int) -> int:
	var vm = _get_vm()
	var mult: float = float(vm.call("get_trade_market_multiplier", int(trade_role))) if (vm and vm.has_method("get_trade_market_multiplier")) else 1.0
	return maxi(1, int(round(float(base_price) * mult)))

func _get_dynamic_buy_price(base_price: int) -> int:
	var vm = _get_vm()
	var mult: float = float(vm.call("get_trade_market_multiplier", int(trade_role))) if (vm and vm.has_method("get_trade_market_multiplier")) else 1.0
	var is_owner: bool = bool(vm.call("is_player_owner_or_partner", int(trade_role))) if (vm and vm.has_method("is_player_owner_or_partner")) else false
	var disc: float = 0.70 if is_owner else (0.80 if affinity >= 45 else 1.0)
	if vm != null and not (vm.has_method("is_demo_mode") and bool(vm.call("is_demo_mode"))):
		disc *= vm.VillageClans.player_price_mult(vm, self)
		if WorldClock != null and int(WorldClock.current_day) % 7 == 3 and vm.VillageMayor.has_decree(vm, "market_subsidy"):
			disc *= 0.85
	return maxi(1, int(round(float(base_price) * mult * disc)))

func to_save_dict() -> Dictionary:
	var route_bought_flags: Dictionary = {}
	for rk in ["route_Bought_smith", "route_Bought_carp", "route_Bought_butcher", "route_Bought_fish", "route_Bought_herb"]:
		if has_meta(rk):
			route_bought_flags[rk] = bool(get_meta(rk))
	var quest_marks: Dictionary = {}
	for mk in SAVED_INT_METAS:
		if has_meta(mk):
			quest_marks[mk] = int(get_meta(mk))
	for mk in SAVED_STR_METAS:
		if has_meta(mk):
			quest_marks[mk] = str(get_meta(mk))
	var save_pos: Vector2 = _pre_poker_pos if (is_at_poker_table and _pre_poker_pos != Vector2.ZERO and not is_dead) else global_position
	return {
		"npc_id": npc_id,
		"person_profile": person_profile.to_dict() if person_profile != null else {},
		"npc_name": npc_name, "npc_role": npc_role, "family_id": family_id, "family_name": family_name,
		"trade_role": int(trade_role), "linked_trade": int(linked_trade), "days_in_role": days_in_role,
		"affinity": affinity, "known_traits": known_traits.duplicate(), "rumored_traits": rumored_traits.duplicate(), "known_feelings": known_feelings.duplicate(), "feelings_all_known": feelings_all_known, "heard_feelings": heard_feelings.duplicate(true), "trait_trust_tier": trait_trust_tier,
		"trait_first_impression_done": trait_first_impression_done, "trait_lore_done": trait_lore_done, "personal_gold": personal_gold, "income_week": income_week, "carries_royal_safe_conduct": carries_royal_safe_conduct,
		"pocket_items": pocket_items.duplicate(), "corpse_pocket_looted": corpse_pocket_looted, "is_vagrant_camper": is_vagrant_camper, "in_shelter": in_shelter, "lodging": lodging,
		"vagrant_camp_x": vagrant_camp_pos.x, "vagrant_camp_y": vagrant_camp_pos.y, "merchant_id": merchant_id,
		"need_hunger": need_hunger, "digestion_buffer": digestion_buffer, "need_energy": need_energy, "need_social": need_social, "need_hygiene": need_hygiene,
		"mood": mood, "thoughts": thoughts.duplicate(), "activity": int(current_activity),
		"is_dead": is_dead, "is_downed": is_downed, "bleedout_timer": bleedout_timer, "sedated_timer": sedated_timer,
		"corpse_on_ground": corpse_on_ground, "corpse_discovered": corpse_discovered, "corpse_discovered_by": corpse_discovered_by,
		"corpse_reported": corpse_reported, "corpse_in_morgue": corpse_in_morgue, "corpse_buried": corpse_buried, "corpse_rot_hours": corpse_rot_hours,
		"last_hit_weapon_name": last_hit_weapon_name, "last_hit_by_player": last_hit_by_player, "murder_witness_name": murder_witness_name,
		"death_world_pos_x": death_world_pos.x, "death_world_pos_y": death_world_pos.y,
		"death_day": death_day, "death_hour": death_hour, "death_minute": death_minute, "is_hostile": is_hostile,
		"pos_x": save_pos.x, "pos_y": save_pos.y, "elevation_level": elevation_level, "work_x": work_position.x, "work_y": work_position.y,
		"bed_x": bed_position.x, "bed_y": bed_position.y, "table_x": home_table_pos.x, "table_y": home_table_pos.y,
		"hp": health_comp.current_health if health_comp else 65.0,
		"shop_stock": shop_stock.duplicate(), "workshop_materials": workshop_materials.duplicate(),
		"craft_progress": _craft_progress, "crafting_recipe_idx": _crafting_recipe_idx,
		"completed_expedition_day": _completed_expedition_day, "route_bought_flags": route_bought_flags, "quest_marks": quest_marks,
		"bloodstained_timer": bloodstained_timer, "seen_entities_memory": seen_entities_memory.duplicate(true),
		"witness_silenced_player": witness_silenced_player, "witness_alibi_for_player": witness_alibi_for_player,
		"witness_framed_target_name": witness_framed_target_name,
		"npc_relationships": npc_relationships.duplicate(), "npc_relationship_notes": npc_relationship_notes.duplicate(),
		"founder_secrets": founder_secrets.duplicate(true),
		"missing_kin_reported_day": _missing_kin_reported_day,
		"medical": health_comp.to_medical_dict() if health_comp else {}
	}

func from_save_dict(data: Dictionary) -> void:
	npc_name = str(data.get("npc_name", npc_name))
	if data.has("person_profile") and typeof(data["person_profile"]) == TYPE_DICTIONARY and not (data["person_profile"] as Dictionary).is_empty():
		person_profile = PersonProfile.from_dict(data["person_profile"] as Dictionary)
	else:
		person_profile = null
	_init_person_profile()
	if data.has("npc_id") and str(data["npc_id"]) != "" and (person_profile == null or str(person_profile.person_id) == ""):
		npc_id = str(data["npc_id"])
	bloodstained_timer = maxf(0.0, float(data.get("bloodstained_timer", 0.0)))
	known_traits.clear()
	for kt in data.get("known_traits", []):
		known_traits.append(str(kt))
	known_feelings.clear()
	for kf in data.get("known_feelings", []):
		known_feelings.append(str(kf))
	feelings_all_known = bool(data.get("feelings_all_known", not data.has("known_feelings")))
	heard_feelings = (data.get("heard_feelings", {}) as Dictionary).duplicate(true) if data.get("heard_feelings", {}) is Dictionary else {}
	rumored_traits.clear()
	var rt_data = data.get("rumored_traits", {})
	if typeof(rt_data) == TYPE_DICTIONARY:
		for rk in rt_data.keys():
			rumored_traits[str(rk)] = str(rt_data[rk])
	trait_trust_tier = int(data.get("trait_trust_tier", 0))
	trait_first_impression_done = bool(data.get("trait_first_impression_done", false))
	trait_lore_done = bool(data.get("trait_lore_done", false))
	witness_silenced_player = bool(data.get("witness_silenced_player", false))
	witness_alibi_for_player = bool(data.get("witness_alibi_for_player", false))
	witness_framed_target_name = str(data.get("witness_framed_target_name", ""))
	if data.has("npc_relationships") and typeof(data["npc_relationships"]) == TYPE_DICTIONARY:
		npc_relationships = (data["npc_relationships"] as Dictionary).duplicate()
	if data.has("npc_relationship_notes") and typeof(data["npc_relationship_notes"]) == TYPE_DICTIONARY:
		npc_relationship_notes = (data["npc_relationship_notes"] as Dictionary).duplicate()
	if data.has("founder_secrets") and typeof(data["founder_secrets"]) == TYPE_ARRAY:
		founder_secrets.clear()
		for fs_it in (data["founder_secrets"] as Array):
			if typeof(fs_it) == TYPE_DICTIONARY:
				founder_secrets.append((fs_it as Dictionary).duplicate(true))
	_migrate_legacy_relationship_keys()
	_missing_kin_reported_day = int(data.get("missing_kin_reported_day", -1))
	_searching_missing_kin = null
	_missing_kin_phase = 0
	_missing_kin_timer = 0.0
	_patrol_search_target_npc = null
	_patrol_search_timer = 0.0
	seen_entities_memory.clear()
	if data.has("seen_entities_memory") and typeof(data["seen_entities_memory"]) == TYPE_ARRAY:
		for mem_it in (data["seen_entities_memory"] as Array):
			if typeof(mem_it) == TYPE_DICTIONARY:
				seen_entities_memory.append((mem_it as Dictionary).duplicate())
	if data.has("workshop_materials") and typeof(data["workshop_materials"]) == TYPE_DICTIONARY:
		workshop_materials = data["workshop_materials"].duplicate()
	_craft_progress = clampf(float(data.get("craft_progress", _craft_progress)), 0.0, 99.0)
	_crafting_recipe_idx = maxi(0, int(data.get("crafting_recipe_idx", _crafting_recipe_idx)))
	_completed_expedition_day = int(data.get("completed_expedition_day", -1))
	_supply_run_target_role = 0
	_supply_run_item_id = ""
	_supply_run_input_label = ""
	_supply_run_timer = 0.0
	_expedition_target_node = null
	_expedition_gather_timer = 0.0
	_is_amateur_foraging = false
	_amateur_forage_timer = 0.0
	_being_interviewed_timer = 0.0
	_interviewer_node = null
	_stop_crafting_bar()
	for rk in ["route_Bought_smith", "route_Bought_carp", "route_Bought_butcher", "route_Bought_fish", "route_Bought_herb"]:
		if has_meta(rk):
			remove_meta(rk)
	if data.has("route_bought_flags") and typeof(data["route_bought_flags"]) == TYPE_DICTIONARY:
		var rbf: Dictionary = data["route_bought_flags"]
		for rk in rbf.keys():
			set_meta(str(rk), bool(rbf[rk]))
	for mk in SAVED_INT_METAS + SAVED_STR_METAS:
		if has_meta(mk):
			remove_meta(mk)
	if data.has("quest_marks") and typeof(data["quest_marks"]) == TYPE_DICTIONARY:
		var qm_d: Dictionary = data["quest_marks"]
		for mk in SAVED_INT_METAS:
			if qm_d.has(mk):
				set_meta(str(mk), int(qm_d[mk]))
		for mk in SAVED_STR_METAS:
			if qm_d.has(mk):
				set_meta(str(mk), str(qm_d[mk]))
	is_at_poker_table = false
	poker_seat_pos = Vector2.ZERO
	_pre_poker_pos = Vector2.ZERO
	corpse_being_carried = false
	corpse_carrier = null
	corpse_reporter_npc = null
	_carrying_corpse_target = null
	_reporting_corpse_target = null
	_active_downed_patient = null
	npc_role = str(data.get("npc_role", npc_role))
	family_id = str(data.get("family_id", family_id))
	family_name = str(data.get("family_name", family_name))
	trade_role = int(data.get("trade_role", trade_role)) as TradeRole
	linked_trade = int(data.get("linked_trade", linked_trade)) as TradeRole
	days_in_role = clampi(int(data.get("days_in_role", days_in_role)), 0, 7)
	affinity = int(data.get("affinity", affinity))
	_track_income = false
	personal_gold = maxi(0, int(data.get("personal_gold", personal_gold)))
	income_week = maxi(0, int(data.get("income_week", 0)))
	_track_income = data.has("income_week")
	carries_royal_safe_conduct = bool(data.get("carries_royal_safe_conduct", carries_royal_safe_conduct))
	if data.has("pocket_items") and typeof(data["pocket_items"]) == TYPE_DICTIONARY:
		pocket_items = (data["pocket_items"] as Dictionary).duplicate()
	elif carries_royal_safe_conduct:
		pocket_items["royal_safe_conduct"] = maxi(1, int(pocket_items.get("royal_safe_conduct", 0)))
	corpse_pocket_looted = bool(data.get("corpse_pocket_looted", corpse_pocket_looted))
	is_vagrant_camper = bool(data.get("is_vagrant_camper", is_vagrant_camper))
	in_shelter = bool(data.get("in_shelter", in_shelter))
	lodging = str(data.get("lodging", lodging))
	vagrant_camp_pos = _read_vec2(data, "vagrant_camp_x", "vagrant_camp_y", vagrant_camp_pos)
	merchant_id = str(data.get("merchant_id", merchant_id))
	need_hunger = clampf(float(data.get("need_hunger", need_hunger)), 0.0, 100.0)
	digestion_buffer = clampf(float(data.get("digestion_buffer", digestion_buffer)), 0.0, 100.0)
	need_energy = clampf(float(data.get("need_energy", need_energy)), 0.0, 100.0)
	need_social = clampf(float(data.get("need_social", need_social)), 0.0, 100.0)
	need_hygiene = clampf(float(data.get("need_hygiene", need_hygiene)), 0.0, 100.0)
	current_activity = int(data.get("activity", current_activity)) as ActivityState
	global_position = _read_vec2(data, "pos_x", "pos_y", global_position)
	elevation_level = int(data.get("elevation_level", 0))
	work_position = _read_vec2(data, "work_x", "work_y", work_position)
	bed_position = _read_vec2(data, "bed_x", "bed_y", bed_position)
	home_table_pos = _read_vec2(data, "table_x", "table_y", home_table_pos)
	if data.has("shop_stock") and typeof(data["shop_stock"]) == TYPE_DICTIONARY:
		shop_stock = data["shop_stock"].duplicate()
	_resolve_unique_64_visuals_and_lore()
	mood = clampf(float(data.get("mood", mood)), 0.0, 100.0)
	if data.has("thoughts") and typeof(data["thoughts"]) == TYPE_ARRAY:
		thoughts.clear()
		for th in (data["thoughts"] as Array):
			thoughts.append(str(th))
	last_hit_weapon_name = str(data.get("last_hit_weapon_name", last_hit_weapon_name))
	last_hit_by_player = bool(data.get("last_hit_by_player", false))
	murder_witness_name = str(data.get("murder_witness_name", ""))
	if stun_comp: stun_comp.clear_stun()
	if health_comp: health_comp.stop_bleeding()
	if bool(data.get("is_dead", false)):
		is_downed = false
		bleedout_timer = 0.0
		is_dead = true
		_clear_combat_hostility()
		if health_comp: health_comp.current_health = 0.0
		corpse_on_ground = bool(data.get("corpse_on_ground", true))
		corpse_discovered = bool(data.get("corpse_discovered", false))
		corpse_discovered_by = str(data.get("corpse_discovered_by", ""))
		corpse_reported = bool(data.get("corpse_reported", false))
		corpse_in_morgue = bool(data.get("corpse_in_morgue", false))
		corpse_buried = bool(data.get("corpse_buried", false))
		corpse_rot_hours = float(data.get("corpse_rot_hours", 0.0))
		death_world_pos = _read_vec2(data, "death_world_pos_x", "death_world_pos_y", global_position)
		death_day = int(data.get("death_day", 1))
		death_hour = int(data.get("death_hour", 12))
		death_minute = int(data.get("death_minute", 0))
		_set_area_col_disabled(hurtbox, true)
		_set_area_col_disabled(interact_area, corpse_buried)
		if sprite:
			_set_sprite_pose(90.0, Color(0.68, 0.54, 0.54, 0.96))
			sprite.z_index = -1
			sprite.visible = not corpse_in_morgue
	else:
		is_dead = false
		is_downed = bool(data.get("is_downed", false))
		bleedout_timer = float(data.get("bleedout_timer", 0.0))
		sedated_timer = float(data.get("sedated_timer", 0.0))
		is_stunned_flag = sedated_timer > 0.0
		is_sleeping = sedated_timer > 0.0
		set_poker_seating(false)
		corpse_on_ground = false
		corpse_discovered = false
		corpse_reported = false
		corpse_in_morgue = false
		corpse_buried = false
		is_hostile = bool(data.get("is_hostile", false)) and not is_downed and sedated_timer <= 0.0
		if is_hostile:
			if not is_in_group("enemies"): add_to_group("enemies")
		else:
			remove_from_group("enemies")
		if body_col: body_col.set_deferred("disabled", not is_hostile)
		_set_area_col_disabled(hurtbox, false)
		_set_area_col_disabled(interact_area, false)
		if sprite:
			sprite.visible = true
			sprite.z_index = 0
			if is_downed: _set_sprite_pose(82.0, Color(1.1, 0.42, 0.42, 0.95))
			elif sedated_timer > 0.0: _set_sprite_pose(90.0, Color(0.55, 0.65, 1.0))
			else: _set_sprite_pose(0.0)
		if health_comp and data.has("hp"):
			health_comp.current_health = clampf(float(data["hp"]), 1.0, health_comp.max_health)
	if health_comp:
		if data.has("medical") and typeof(data["medical"]) == TYPE_DICTIONARY:
			health_comp.from_medical_dict(data["medical"])
		else:
			health_comp._init_anatomy()
