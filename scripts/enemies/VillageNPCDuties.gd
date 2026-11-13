@tool
extends "res://scripts/enemies/VillageNPCSocial.gd"


func _process_doctor_duty(delta: float) -> bool:
	if trade_role == TradeRole.DOCTOR and not is_hostile:
		_doctor_scan_timer -= delta
		if not is_instance_valid(_active_downed_patient) or not _active_downed_patient.is_downed or _active_downed_patient.is_dead:
			_active_downed_patient = null
			if _doctor_scan_timer <= 0.0:
				_doctor_scan_timer = 0.25
				_active_downed_patient = _find_downed_npc()
		if _active_downed_patient != null:
			_stop_crafting_bar()
			if global_position.distance_to(_active_downed_patient.global_position) > 22.0:
				_move_towards_point(_active_downed_patient.global_position, 68.0 * lerpf(0.72, 1.0, get_job_efficiency()), delta)
				_finish_frame_movement(delta)
			else:
				_active_downed_patient.revive_from_downed(self, false)
				_spawn_floating_text("🩺 ¡%s trasladó a %s a la camilla de urgencias!" % [npc_name, _active_downed_patient.npc_name], Color.SPRING_GREEN, -42.0)
				_active_hospital_patient = _active_downed_patient
				_active_downed_patient = null
			return true
		if _process_doctor_hospital_treatment(delta):
			_finish_frame_movement(delta)
			return true
	return false

## Policía: aplicar la ley, investigar y buscar desaparecidos.

func _process_police_duty(delta: float) -> bool:
	if trade_role in [TradeRole.SHERIFF, TradeRole.GUARD]:
		var vm = _cached_vm
		if vm and (int(vm.get("wanted_level")) > 0 or bool(vm.get("is_resisting_arrest")) or is_hostile) and not bool(vm.get("player_in_jail")) and not bool(vm.get("player_being_escorted_to_jail")):
			if _process_police_law_enforcement(delta, vm):
				return true
		if trade_role == TradeRole.SHERIFF and vm and "active_sheriff_investigation" in vm and bool(vm.active_sheriff_investigation.get("active", false)):
			if vm.has_method("update_sheriff_investigator_ai"):
				vm.call("update_sheriff_investigator_ai", self, delta)
				_finish_frame_movement(delta, true)
				return true
		if not is_hostile and _process_police_missing_person_patrol(delta):
			return true
		if not is_hostile and _noise_react_mode == "guard_investigate" and _process_noise_reaction(delta):
			return true
	return false

## B1 (C7 fase 4d): reacción física al ruido de golpes fuertes, gritos de dolor o disparos.
## Los guardias despiertos acuden a mirar o intervenir; los vecinos pacíficos huyen o se asoman a distancia,
## y solo cuentan como testigos (`known_by` / `sighting_log`) si lo ven (paredes, puertas y suelos: Vista.gd).

func on_noise_heard(origin: Vector2, _radius: float = 160.0, _kind: String = "combat", src_elev: int = 0) -> void:
	if is_dead or is_downed or is_sleeping or is_stunned_flag or sedated_timer > 0.0 or is_at_poker_table or get_meta("club_bout", false) == true:
		return
	if is_in_live_fight() or is_busy_with_player() or is_busy_with_emergency():
		return
	if is_hostile:
		if trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.ROYAL_INVESTIGATOR]:
			_last_seen_player_pos = origin
			_police_alerted_timer = maxf(_police_alerted_timer, 6.0)
		return
	_noise_react_pos = origin
	_noise_react_elev = src_elev
	_noise_witness_logged = false
	if trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.ROYAL_INVESTIGATOR]:
		_noise_react_mode = "guard_investigate"
		_noise_react_timer = 8.0
		_spawn_floating_text("🛡️👂 ¡¿Qué ha sido ese ruido?!", Color.AQUA, -38.0)
	else:
		if TraitCatalog.npc_tendency(self, "curiosity") > 0 or TraitCatalog.npc_tendency(self, "courage") > 0:
			_noise_react_mode = "civilian_peek"
			_spawn_floating_text("👀 ¿Qué pasa ahí?", Color(1.0, 0.90, 0.55), -36.0)
		else:
			_noise_react_mode = "civilian_flee"
			_spawn_floating_text("😨 ¡Socorro, pelea!", Color(1.0, 0.65, 0.45), -36.0)
		_noise_react_timer = 6.0
	_try_log_combat_witness()

func can_witness_combat_at(pos: Vector2, target_elev: int = 0) -> bool:
	if not is_conscious():
		return false
	var vm = _get_vm()
	return vm == null or bool(vm.ve(global_position, elevation_level, pos, target_elev))

func _try_log_combat_witness() -> bool:
	if _noise_witness_logged:
		return true
	if not can_witness_combat_at(_noise_react_pos, _noise_react_elev):
		return false
	var vm = _get_vm()
	if vm == null:
		return false
	_noise_witness_logged = true
	var b_at: Dictionary = vm._get_building_at_pos(_noise_react_pos) if vm.has_method("_get_building_at_pos") else {}
	var b_id: String = str(b_at.get("id", "street"))
	var b_title: String = str(b_at.get("title", "Vía Pública"))
	var h: int = WorldClock.current_hour if WorldClock else 12
	var m: int = WorldClock.current_minute if WorldClock else 0
	var d: int = WorldClock.current_day if WorldClock else 1
	if "sighting_log" in vm and typeof(vm.sighting_log) == TYPE_ARRAY:
		vm.sighting_log.push_front({
			"building_id": b_id, "building_title": b_title,
			"witness_name": npc_name, "action": "pelear en",
			"hour": h, "minute": m, "day": d, "total_minutes": d * 1440 + h * 60 + m
		})
		while vm.sighting_log.size() > 25:
			vm.sighting_log.pop_back()
	if "social_event_log" in vm and typeof(vm.social_event_log) == TYPE_ARRAY:
		var my_key: String = get_person_key()
		for idx in range(vm.social_event_log.size() - 1, maxi(-1, vm.social_event_log.size() - 6), -1):
			var ev: Dictionary = vm.social_event_log[idx]
			if str(ev.get("type", "")) in ["fight", "feud"] and ev.get("known_by") is Dictionary:
				(ev["known_by"] as Dictionary)[my_key] = true
				break
	return true

func _process_noise_reaction(delta: float) -> bool:
	if _noise_react_timer <= 0.0:
		return false
	if is_dead or is_downed or is_sleeping or is_hostile or is_in_live_fight():
		_noise_react_timer = 0.0
		return false
	_noise_react_timer = maxf(0.0, _noise_react_timer - delta)
	_try_log_combat_witness()
	var vm = _get_vm()
	if _noise_react_mode == "guard_investigate":
		if _noise_witness_logged and vm != null:
			for n in get_tree().get_nodes_in_group("village_npcs"):
				if n is VillageNPCBase and n != self:
					var v = n
					if v.elevation_level == elevation_level and v.global_position.distance_to(_noise_react_pos) <= 95.0 and v.last_hit_by_player and (v.is_hostile or v.is_downed):
						if int(vm.get("wanted_level")) <= 0 and vm.has_method("report_assault_crime"):
							vm.call("report_assault_crime", v)
						_police_alerted_timer = maxf(_police_alerted_timer, 6.0)
						_last_seen_player_pos = _cached_player.global_position if is_instance_valid(_cached_player) else _noise_react_pos
						_noise_react_timer = 0.0
						return true
		if global_position.distance_to(_noise_react_pos) > 26.0:
			_move_towards_point(_noise_react_pos, 76.0, delta)
		else:
			velocity = Vector2.ZERO
			trigger_action_animation(0.3)
	elif _noise_react_mode == "civilian_flee":
		var away: Vector2 = global_position - _noise_react_pos
		var dir: Vector2 = away.normalized() if away.length_squared() > 1.0 else Vector2.RIGHT
		if away.length() < 130.0:
			_move_towards_point(global_position + dir * 75.0, 72.0, delta)
		else:
			velocity = Vector2.ZERO
	elif _noise_react_mode == "civilian_peek":
		var dist: float = global_position.distance_to(_noise_react_pos)
		if dist > 92.0:
			_move_towards_point(_noise_react_pos, 54.0, delta)
		elif dist < 60.0:
			var back_dir: Vector2 = (global_position - _noise_react_pos).normalized() if dist > 1.0 else Vector2.LEFT
			_move_towards_point(global_position + back_dir * 45.0, 56.0, delta)
		else:
			velocity = Vector2.ZERO
			if sprite:
				sprite.flip_h = (_noise_react_pos.x < global_position.x)
	_finish_frame_movement(delta)
	return true

## Si está herido o enfermo, va a la cama del hospital y descansa allí.

func _process_hospital_care(delta: float) -> bool:
	if int(elevation_level) == -1 or errand_kind in ["club_go", "club_watch"] or get_meta("club_bout", false) == true:
		return false
	var needs_hospital_care: bool = false
	if health_comp and need_hunger > 5.0 and trade_role != TradeRole.DOCTOR:
		if health_comp.current_blood >= 22.0 or health_comp.get_most_urgent_untreated_wound_id(false) != -1:
			needs_hospital_care = true
		elif health_comp.current_health < health_comp.get_effective_max_health() * 0.78:
			needs_hospital_care = true
		elif health_comp.fever >= 35.0 or health_comp.food_poisoning >= 40.0 or health_comp.swamp_sickness >= 40.0 or health_comp.get_max_wound_infection() >= 25.0:
			needs_hospital_care = true
		elif health_comp.has_active_sickness_or_infection() and global_position.distance_to(_cama_urgencias()) <= 24.0:
			needs_hospital_care = true

	if needs_hospital_care:
		if is_sleeping:
			is_sleeping = false
			if sprite:
				sprite.rotation_degrees = 0.0
		_stop_crafting_bar()
		var hosp_bed_pos: Vector2 = _cama_urgencias()
		if global_position.distance_to(hosp_bed_pos) > 18.0:
			_move_towards_point(hosp_bed_pos, 46.0, delta)
		else:
			velocity = Vector2.ZERO
			health_comp.is_resting_in_bed = true
			# Solo recupera resistencia física gradualmente si ya no tiene heridas abiertas sangrando
			if health_comp.get_total_wound_bleed_rate() <= 0.0 and not health_comp.is_bleeding:
				health_comp.heal(1.8 * delta)
		_finish_frame_movement(delta)
		return true
	return false

## Gestiona un cadáver en el suelo o en la Morgue: se pudre con el paso de las horas/días hasta que otro NPC lo vea en su rutina natural (con línea de visión)
## o el jugador lo reporte con [E]. En la Morgue conserva sus bolsillos y órganos hasta que el caso se resuelva/archive y sea sepultado.

func _process_corpse_state(delta: float) -> void:
	if corpse_buried:
		return
	if corpse_in_morgue:
		_update_world_tag_for_state(Color(0.85, 0.92, 0.88), "☠")
		return
	if not corpse_on_ground:
		return

	if corpse_being_carried:
		if is_instance_valid(corpse_carrier) and corpse_carrier.is_conscious() and not corpse_carrier.is_hostile:
			global_position = corpse_carrier.global_position + Vector2(0, -8)
		else:
			if is_instance_valid(corpse_carrier) and corpse_carrier._carrying_corpse_target == self:
				corpse_carrier._carrying_corpse_target = null
			corpse_being_carried = false
			corpse_carrier = null
	else:
		corpse_rot_hours += delta / 65.0

	if sprite:
		sprite.visible = true
		var rot_col: Color = Color(0.68, 0.54, 0.54, 0.96) if corpse_rot_hours < 12.0 else (Color(0.54, 0.60, 0.46, 0.96) if corpse_rot_hours < 24.0 else Color(0.38, 0.56, 0.30, 0.96))
		_set_sprite_pose(90.0, rot_col)

	if status_label:
		_update_world_tag_for_state(Color(0.95, 0.91, 0.83), "☠")

	_corpse_scan_timer -= delta
	if _corpse_scan_timer > 0.0:
		return
	_corpse_scan_timer = 0.25

	var vm = _get_vm()
	if not corpse_reported:
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPCBase and n != self and (n).is_conscious():
				var other := n
				if other.trade_role in [TradeRole.ROYAL_INVESTIGATOR, TradeRole.TRAVELING_MERCHANT]:
					continue
				if other.witness_silenced_player and last_hit_by_player:
					continue
				if is_instance_valid(other._reporting_corpse_target) and other._reporting_corpse_target.is_dead and not other._reporting_corpse_target.corpse_reported:
					continue
				if other.global_position.distance_to(global_position) <= 95.0 and ((vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", other.global_position, global_position))):
					if not is_instance_valid(corpse_reporter_npc) or not corpse_reporter_npc.is_conscious() or corpse_reporter_npc._reporting_corpse_target != self:
						begin_physical_corpse_discovery(other)
						break

## Inicia el proceso físico en 3 fases para quien descubre un cuerpo:
## 1) Acercarse y comprobar durante 10s si está muerto -> 2) Caminar personalmente a buscar a la policía -> 3) Explicar durante 12.5s lo sucedido

func begin_physical_corpse_discovery(discoverer) -> void:
	if discoverer == null or not is_dead or corpse_reported or corpse_in_morgue:
		return
	if is_instance_valid(discoverer._reporting_corpse_target) and discoverer._reporting_corpse_target.is_dead and not discoverer._reporting_corpse_target.corpse_reported:
		if not corpse_discovered:
			corpse_discovered = true
			corpse_discovered_by = discoverer.npc_name
		return
	if not corpse_discovered:
		corpse_discovered = true
		corpse_discovered_by = discoverer.npc_name
		discoverer.add_thought("Descubrió el cuerpo de %s (-15)" % npc_name, -15.0)
	corpse_reporter_npc = discoverer
	discoverer._clear_unconscious_reaction_state()
	discoverer._reporting_corpse_target = self
	discoverer._corpse_report_phase = 1
	discoverer._corpse_report_timer = 0.0
	var tend_w: String = "tendida" if is_female() else "tendido"
	discoverer._spawn_floating_text("😟❓ ¡%s vio a %s %s y va a comprobarlo!" % [discoverer.npc_name, npc_name, tend_w], Color.GOLD, -42.0)

## Cuando un testigo termina de reportar un cadáver a la policía, también quedan reportados otros cadáveres de la misma escena (<= 165 px)

func _report_nearby_corpses_from_same_scene(primary_corpse) -> void:
	if not is_instance_valid(primary_corpse) or not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPCBase and n != primary_corpse and n != self:
			var c := n
			if c.is_dead and c.corpse_on_ground and not c.corpse_in_morgue and not c.corpse_reported:
				if c.global_position.distance_to(primary_corpse.global_position) <= 165.0:
					c.corpse_discovered = true
					if c.corpse_discovered_by == "":
						c.corpse_discovered_by = npc_name
					c.corpse_reported = true
					c.corpse_reporter_npc = null
					c._notify_corpse_reported_to_authorities()

## Borra al jugador de la memoria visual de este testigo y detiene cualquier reporte activo si fue convencido, sobornado o intimidado

func clear_witness_memories_of_player() -> void:
	witness_silenced_player = true
	for i in range(seen_entities_memory.size() - 1, -1, -1):
		if str(seen_entities_memory[i].get("name", "")) == "Jugador" or bool(seen_entities_memory[i].get("is_player", false)):
			seen_entities_memory.remove_at(i)
	if is_instance_valid(_reporting_corpse_target):
		if _reporting_corpse_target.corpse_reporter_npc == self:
			_reporting_corpse_target.corpse_reporter_npc = null
		_reporting_corpse_target = null
	_corpse_report_phase = 0
	_corpse_report_timer = 0.0
	_stop_crafting_bar()
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPCBase and (n).murder_witness_name == npc_name:
				(n).murder_witness_name = ""
	var vm = _get_vm()
	if vm and "sighting_log" in vm and typeof(vm.sighting_log) == TYPE_ARRAY:
		var s_arr: Array = vm.sighting_log
		for idx in range(s_arr.size() - 1, -1, -1):
			if typeof(s_arr[idx]) == TYPE_DICTIONARY and str(s_arr[idx].get("witness_name", "")) == npc_name:
				s_arr.remove_at(idx)

## Notifica a las autoridades (y a la Corona si el cadáver reportado es un Mercader Viajero) recién cuando el testigo termina de explicarlo a la policía

func _notify_corpse_reported_to_authorities() -> void:
	var vm = _get_vm()
	if trade_role == TradeRole.TRAVELING_MERCHANT:
		if vm and vm.has_method("on_traveling_merchant_murdered"):
			vm.call("on_traveling_merchant_murdered", self, last_hit_weapon_name)
	elif vm and vm.has_method("on_civilian_corpse_reported"):
		vm.call("on_civilian_corpse_reported", self, death_world_pos if death_world_pos != Vector2.ZERO else global_position, last_hit_weapon_name, corpse_discovered_by)

## Permite al jugador reportar manualmente un cadáver con [E] (Estilo Among Us / Hitman / Streets of Rogue)

func report_corpse_by_player(player: Node) -> bool:
	if not is_dead or not corpse_on_ground or corpse_in_morgue:
		return false
	if corpse_reported:
		if player and player.has_method("_spawn_floating_text"):
			player.call("_spawn_floating_text", "🚨 El cadáver de %s ya fue reportado a las autoridades" % npc_name, Color.GOLD, -40.0)
		return true
	corpse_discovered = true
	if corpse_discovered_by == "":
		corpse_discovered_by = "Jugador (Reporte Ciudadano)"
	corpse_reported = true
	corpse_reporter_npc = null
	_notify_corpse_reported_to_authorities()
	_spawn_floating_text("📢 ¡Reportaste el cadáver de %s! El Dr. Valen / la guardia acudirá a recogerlo." % npc_name, Color.GOLD, -44.0)
	if player and player.has_method("_spawn_floating_text"):
		player.call("_spawn_floating_text", "📢 Cadáver de %s reportado al Hospital y Comisaría" % npc_name, Color.AQUA, -36.0)
	return true

## Un testigo que descubrió un cadáver cumple físicamente 3 fases sin telepatía ni instantaneidad:
## Fase 1 (10.0s): Camina hasta el cuerpo y se agacha 10s a comprobar si realmente está muerto.
## Fase 2: Camina personalmente por las calles en busca del Comisario/Guardia (o Médico/Comisaría).
## Fase 3 (12.5s): Se detiene frente al policía y pasa 12.5s explicándole lo ocurrido antes de que se active la alerta.

func _process_witness_corpse_reporting(delta: float) -> bool:
	if not is_instance_valid(_reporting_corpse_target):
		_corpse_report_phase = 0
		_corpse_report_timer = 0.0
		return false
	var corpse_to_report = _reporting_corpse_target
	if not corpse_to_report.is_dead or not corpse_to_report.corpse_on_ground or corpse_to_report.corpse_in_morgue or corpse_to_report.corpse_reported or corpse_to_report.corpse_reporter_npc != self:
		_reporting_corpse_target = null
		_corpse_report_phase = 0
		_corpse_report_timer = 0.0
		_stop_crafting_bar()
		return false

	if _corpse_report_phase <= 0:
		_corpse_report_phase = 1
		_corpse_report_timer = 0.0

	# FASE 1: Acercarse al cuerpo y pasar 10.0 segundos investigando si la persona está muerta
	if _corpse_report_phase == 1:
		var dist_to_body: float = global_position.distance_to(corpse_to_report.global_position)
		if dist_to_body > 22.0:
			_stop_crafting_bar()
			_move_towards_point(corpse_to_report.global_position, 54.0, delta)
			_finish_frame_movement(delta)
			return true
		velocity = Vector2.ZERO
		if sprite:
			sprite.flip_h = (corpse_to_report.global_position.x < global_position.x)
		_corpse_report_timer += delta
		var rem_chk: int = maxi(1, int(ceil(10.0 - _corpse_report_timer)))
		_update_craft_bar_visual(clampf(_corpse_report_timer / 10.0, 0.02, 1.0), "🔍 Comprobando pulso (%ds)" % rem_chk, Color(0.95, 0.78, 0.30, 0.95))
		trigger_action_animation(0.4)
		_finish_frame_movement(delta)
		if _corpse_report_timer >= 10.0:
			_stop_crafting_bar()
			_corpse_report_timer = 0.0
			if trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.DOCTOR]:
				corpse_to_report.corpse_reported = true
				corpse_to_report.corpse_reporter_npc = null
				_reporting_corpse_target = null
				_corpse_report_phase = 0
				_spawn_floating_text("🚨 ¡%s examinó el cuerpo y confirmó la muerte de %s!" % [npc_name, corpse_to_report.npc_name], Color.ORANGE_RED, -42.0)
				corpse_to_report._notify_corpse_reported_to_authorities()
				_report_nearby_corpses_from_same_scene(corpse_to_report)
			else:
				_corpse_report_phase = 2
				var dead_w: String = "muerta" if corpse_to_report.is_female() else "muerto"
				_spawn_floating_text("😱💀 ¡No respira, está %s! ¡Voy a avisar a la guardia!" % dead_w, Color.ORANGE_RED, -42.0)
		return true

	# Buscar al policía consciente más cercano (o despertarlo en la Comisaría si es de noche)
	var nearest_authority = _find_nearest_available_authority(true)
	var report_dest: Vector2 = nearest_authority.global_position if nearest_authority != null else (load("res://scripts/systems/VillageJustice.gd").call("cell_pos") as Vector2)

	# FASE 2: Caminar personalmente hasta donde está la policía
	if _corpse_report_phase == 2:
		if global_position.distance_to(report_dest) > 26.0:
			_stop_crafting_bar()
			_move_towards_point(report_dest, 58.0, delta)
			_finish_frame_movement(delta)
			return true
		velocity = Vector2.ZERO
		_corpse_report_phase = 3
		_corpse_report_timer = 0.0
		if nearest_authority != null:
			nearest_authority.is_sleeping = false
			if nearest_authority.sprite:
				nearest_authority.sprite.rotation_degrees = 0.0
		var dead_w2: String = "muerta" if corpse_to_report.is_female() else "muerto"
		_spawn_floating_text("🗣️🚓 ¡Guardia! ¡He encontrado a %s %s!" % [corpse_to_report.npc_name, dead_w2], Color.GOLD, -42.0)
		return true

	# FASE 3: Explicar durante 12.5 segundos a la policía lo que pasó
	if global_position.distance_to(report_dest) > 34.0:
		_stop_crafting_bar()
		_move_towards_point(report_dest, 58.0, delta)
		_finish_frame_movement(delta)
		return true

	velocity = Vector2.ZERO
	if nearest_authority != null:
		nearest_authority.is_sleeping = false
		if nearest_authority.sprite:
			nearest_authority.sprite.rotation_degrees = 0.0
		nearest_authority.hold_for_interview(self, 0.6)
		if sprite:
			sprite.flip_h = (nearest_authority.global_position.x < global_position.x)
	_corpse_report_timer += delta
	var rem_exp: int = maxi(1, int(ceil(12.5 - _corpse_report_timer)))
	var auth_name: String = nearest_authority.npc_name if nearest_authority != null else "la Comisaría"
	_update_craft_bar_visual(clampf(_corpse_report_timer / 12.5, 0.02, 1.0), "🗣️ Explicando a %s (%ds)" % [auth_name, rem_exp], Color(1.0, 0.56, 0.28, 0.95))
	trigger_action_animation(0.4)
	_finish_frame_movement(delta)
	if _corpse_report_timer >= 12.5:
		_stop_crafting_bar()
		corpse_to_report.corpse_reported = true
		corpse_to_report.corpse_reporter_npc = null
		_reporting_corpse_target = null
		_corpse_report_phase = 0
		_corpse_report_timer = 0.0
		_spawn_floating_text("📢 ¡%s terminó de explicar el hallazgo de %s a %s!" % [npc_name, corpse_to_report.npc_name, auth_name], Color.GOLD, -42.0)
		if nearest_authority != null:
			nearest_authority._spawn_floating_text("🚓📋 Entendido. Aseguraremos el cuerpo e investigaremos la escena.", Color.AQUA, -38.0)
		corpse_to_report._notify_corpse_reported_to_authorities()
		_report_nearby_corpses_from_same_scene(corpse_to_report)
	return true

## Recoge físicamente un cadáver YA REPORTADO (`corpse_reported == true`) y camina con él por las puertas y calles hasta depositarlo en la Morgue

func _process_corpse_morgue_transport(delta: float) -> bool:
	var target_corpse = null
	if is_instance_valid(_carrying_corpse_target) and _carrying_corpse_target.is_dead and _carrying_corpse_target.corpse_on_ground and not _carrying_corpse_target.corpse_in_morgue:
		target_corpse = _carrying_corpse_target if (not _carrying_corpse_target.corpse_being_carried or _carrying_corpse_target.corpse_carrier == self) else null
		_carrying_corpse_target = target_corpse

	if target_corpse == null:
		_corpse_scan_timer -= delta
		if _corpse_scan_timer > 0.0:
			return false
		_corpse_scan_timer = 0.45
		var can_be_carrier: bool = (trade_role in [TradeRole.DOCTOR, TradeRole.GUARD, TradeRole.SHERIFF])
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPCBase and n != self:
				var c := n
				if c.is_dead and c.corpse_on_ground and not c.corpse_in_morgue and c.corpse_reported:
					if (c.corpse_being_carried and c.corpse_carrier == self) or (not c.corpse_being_carried and (can_be_carrier or (not _is_doctor_conscious_and_free() and c.corpse_discovered_by == npc_name))):
						target_corpse = c
						_carrying_corpse_target = c
						break

	if target_corpse == null:
		return false

	var vm_carry = _cached_vm
	var morgue_has_space: bool = (vm_carry == null) or (not vm_carry.has_method("has_free_morgue_table")) or bool(vm_carry.call("has_free_morgue_table"))
	var dest_label: String = "la Morgue" if morgue_has_space else "el Cementerio Parroquial (Morgue llena)"
	if not target_corpse.corpse_being_carried:
		if global_position.distance_to(target_corpse.global_position) > 24.0:
			_move_towards_point(target_corpse.global_position, 66.0, delta)
			_finish_frame_movement(delta)
			return true
		target_corpse.corpse_being_carried = true
		target_corpse.corpse_carrier = self
		_carrying_corpse_target = target_corpse
		_spawn_floating_text("⚰️ %s recoge el cadáver de %s hacia %s" % [npc_name, target_corpse.npc_name, dest_label], Color.AQUA, -42.0)

	var target_drop_pos: Vector2 = _EDIFICIO.a_mundo(_HOSPITAL_ID, _MORGUE_ENTREGA_PLANO) # morgue, sigue al hospital movido
	if not morgue_has_space and vm_carry and vm_carry.has_method("get_cemetery_burial_target_pos"):
		target_drop_pos = vm_carry.call("get_cemetery_burial_target_pos")
	target_corpse.global_position = global_position + Vector2(0, -8)
	if global_position.distance_to(target_drop_pos) > 22.0:
		_move_towards_point(target_drop_pos, 60.0, delta)
		_finish_frame_movement(delta)
		return true
	velocity = Vector2.ZERO
	target_corpse.corpse_on_ground = false
	target_corpse.corpse_being_carried = false
	target_corpse.corpse_in_morgue = true
	target_corpse.corpse_buried = not morgue_has_space
	target_corpse.corpse_carrier = null
	target_corpse.global_position = target_drop_pos
	if target_corpse.sprite:
		target_corpse.sprite.visible = false
	if target_corpse.status_label:
		target_corpse.status_label.visible = false
	target_corpse._stop_crafting_bar()
	# Mientras el cuerpo esté en una camilla de la Morgue (`not corpse_buried`), mantiene su área interactiva activa para poder saquear sus bolsillos o extraer órganos con [E] / [H]
	target_corpse._set_area_col_disabled(target_corpse.interact_area, target_corpse.corpse_buried)
	_carrying_corpse_target = null
	var vm = _cached_vm
	if vm and vm.has_method("register_npc_death_and_corpse"):
		vm.call("register_npc_death_and_corpse", target_corpse, target_corpse.death_world_pos, target_corpse.last_hit_weapon_name, target_corpse.last_hit_by_player, target_corpse.corpse_discovered_by, target_corpse.corpse_rot_hours)
	_spawn_floating_text(("⚰️ Cuerpo de %s depositado en la Morgue Forense" if not target_corpse.corpse_buried else "🪦 Cuerpo de %s sepultado en el Cementerio de la Iglesia") % target_corpse.npc_name, Color.AQUA if not target_corpse.corpse_buried else Color(0.85, 0.78, 0.95), -44.0)
	return true

func _is_doctor_conscious_and_free() -> bool:
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPCBase and (n).trade_role == TradeRole.DOCTOR and (n).is_conscious():
			return true
	return false

## IA Policial: 1º Negociar (si no se resiste), 2º Si se resiste -> Persecución con Pistola a distancia y Porra cuerpo a cuerpo, con Línea de Visión

func _process_police_law_enforcement(delta: float, vm: Node) -> bool:
	var player = _cached_player
	if not is_instance_valid(player):
		return false
	var can_see_player: bool = vm.ve(global_position, elevation_level, player.global_position, vm.player_elevation_level)
	if not can_see_player and int(elevation_level) != int(vm.player_elevation_level):
		_police_baton_windup_timer = 0.0
		velocity = Vector2.ZERO
		return false

	var dist_p: float = global_position.distance_to(player.global_position)
	var in_stealth: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
	var cloak_mult: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
	var eff_pol: float = get_job_efficiency()
	var amb_pol_vis: float = float(vm.call("get_ambient_vision_multiplier_at", player.global_position, self)) if (vm and vm.has_method("get_ambient_vision_multiplier_at")) else (float(WorldClock.call("get_weather_vision_multiplier")) if WorldClock else 1.0)
	var detect_range: float = (95.0 if in_stealth else 235.0) * cloak_mult * lerpf(0.68, 1.0, eff_pol) * get_sleep_vision_multiplier() * amb_pol_vis

	if can_see_player and dist_p <= detect_range:
		_police_alerted_timer = 5.5
		_last_seen_player_pos = player.global_position
	elif _police_alerted_timer > 0.0:
		_police_alerted_timer -= delta
	if _police_alerted_timer <= 0.0:
		_police_warning_done = false
		_police_warning_timer = 0.0
		return false

	var resisting: bool = bool(vm.get("is_resisting_arrest")) or is_hostile
	var target_pt: Vector2 = player.global_position if can_see_player else _last_seen_player_pos
	var spd_mult: float = lerpf(0.78, 1.0, eff_pol)

	if not resisting:
		_police_warning_done = false
		_police_warning_timer = 0.0
		if can_see_player and dist_p <= 34.0:
			velocity = Vector2.ZERO
			if vm.has_method("trigger_police_confrontation"):
				vm.call("trigger_police_confrontation", self)
		else:
			_move_towards_point(target_pt, 86.0 * spd_mult, delta)
			move_and_slide()
		_update_visual_animation(delta)
		_update_hover_label(delta)
		return true

	if _stagger_timer > 0.0:
		_stagger_timer = maxf(0.0, _stagger_timer - delta)
		_police_baton_windup_timer = 0.0
		velocity = Vector2.ZERO
		if _stagger_timer <= 0.0 and sprite:
			sprite.modulate = Color.WHITE
		_finish_frame_movement(delta)
		return true

	if police_reload_step > 0 and not is_disarmed():
		police_reload_timer -= delta
		var away_dir: Vector2 = (global_position - player.global_position).normalized()
		if away_dir.length_squared() < 0.01:
			away_dir = Vector2.LEFT
		_move_towards_point(global_position + away_dir * 30.0, 42.0 * spd_mult, delta)
		facing_direction = -away_dir
		if police_reload_timer <= 0.0:
			if police_reload_step < 3:
				police_reload_step += 1
				police_reload_timer = 0.75
				_spawn_floating_text("🔄 Recargando (%d/3)..." % police_reload_step, Color(0.82, 0.90, 1.0), -38.0)
			else:
				police_reload_step = 0
				police_mag_loaded = 5
				_spawn_floating_text("🔫 ¡Cargador listo (5/5)!", Color(1.0, 0.88, 0.35), -38.0)
		_finish_frame_movement(delta)
		return true

	if _melee_recover_timer > 0.0:
		_melee_recover_timer = maxf(0.0, _melee_recover_timer - delta)
		velocity = Vector2.ZERO
		_finish_frame_movement(delta)
		return true
	if _police_baton_windup_timer > 0.0:
		_police_baton_windup_timer = maxf(0.0, _police_baton_windup_timer - delta)
		velocity = Vector2.ZERO
		if _police_baton_windup_timer <= 0.0:
			_attack_timer = 0.85 / maxf(0.55, eff_pol)
			if sprite:
				sprite.modulate = Color.WHITE
			_CombatFeel.enemy_swing(self, "porra")
			if is_instance_valid(player) and global_position.distance_to(player.global_position) <= 38.0:
				_strike_police_baton(player)
				_melee_recover_timer = float(_CombatFeel.attack_feel("porra")["recover"])
			else:
				_melee_recover_timer = float(_CombatFeel.attack_feel("porra")["miss_recover"])
		_finish_frame_movement(delta)
		return true

	if _police_warning_timer > 0.0:
		_police_warning_timer = maxf(0.0, _police_warning_timer - delta)
		velocity = Vector2.ZERO
		facing_direction = (player.global_position - global_position).normalized()
		_finish_frame_movement(delta)
		return true

	_attack_timer = maxf(0.0, _attack_timer - delta)
	if can_see_player and dist_p <= 36.0:
		if dist_p > 22.0:
			_move_towards_point(player.global_position, 96.0 * spd_mult, delta)
		else:
			velocity = Vector2.ZERO
		if _attack_timer <= 0.0:
			_police_baton_windup_timer = 0.40
			trigger_action_animation(0.45)
			if sprite:
				sprite.modulate = Color(1.35, 0.9, 0.45)
			_spawn_floating_text("❗", Color.ORANGE_RED, -36.0)
	elif can_see_player and dist_p <= 195.0:
		if not _police_warning_done and not is_disarmed():
			_police_warning_done = true
			_police_warning_timer = 0.90
			velocity = Vector2.ZERO
			facing_direction = (player.global_position - global_position).normalized()
			trigger_action_animation(0.75)
			_spawn_floating_text("✋ ¡Alto en nombre de la ley o disparo!", Color(1.0, 0.86, 0.28), -44.0)
			spawn_short_bubble("¡Alto en nombre de la ley o abro fuego!", Color(1.0, 0.96, 0.78), -40.0, 2.4)
			if vm and vm.has_method("_show_toast"):
				vm.call("_show_toast", "🚨 %s te apunta: «¡Alto en nombre de la ley o disparo!»" % npc_name, Color(1.0, 0.78, 0.28))
			_finish_frame_movement(delta)
			return true
		_move_towards_point(player.global_position, (96.0 if is_disarmed() else 82.0) * spd_mult, delta)
		if _attack_timer <= 0.0 and not is_disarmed():
			if police_mag_loaded <= 0:
				police_reload_step = 1
				police_reload_timer = 0.75
				_spawn_floating_text("🔄 Recargando (1/3)...", Color(0.82, 0.90, 1.0), -38.0)
				spawn_short_bubble("¡Sin balas, recargando!", Color(0.82, 0.90, 1.0), -38.0, 1.9)
			else:
				police_mag_loaded -= 1
				_attack_timer = (1.35 if carries_police_rifle() else 1.25) / maxf(0.55, eff_pol)
				_fire_police_pistol(player)
				if police_mag_loaded <= 0:
					police_reload_step = 1
					police_reload_timer = 0.75
	else:
		_move_towards_point(target_pt, 96.0 * spd_mult, delta)

	_finish_frame_movement(delta)
	return true

func carries_police_rifle() -> bool:
	if not (trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.ROYAL_INVESTIGATOR]) or is_disarmed():
		return false
	if trade_role in [TradeRole.SHERIFF, TradeRole.ROYAL_INVESTIGATOR]:
		return true
	if global_position.x >= 1320.0: # Puesto del Paso / frontera del este
		return true
	var vm = _cached_vm if _cached_vm != null else _get_vm()
	if vm != null and (int(vm.get("wanted_level")) >= 2 or bool(vm.get("is_resisting_arrest"))):
		return true
	return is_hostile

func _strike_police_baton(player: Node2D) -> void:
	if not player or not player.has_method("take_damage"):
		return
	var eff: float = get_job_efficiency()
	var unarmed: bool = is_disarmed() # C7 fase 4c: sin porra, a puñetazos
	var d := DamageData.new()
	d.amount = (8.0 if unarmed else 14.0) * eff
	d.type = CombatConstants.DamageType.BLUNT
	d.stun_buildup = (14.0 if unarmed else 36.0) * eff
	d.weapon_tag = ("Puñetazo de " + npc_name) if unarmed else "Porra Policial"
	d.knockback_force = float(_CombatFeel.attack_feel("porra")["push"])
	d.source = self
	player.call("take_damage", d)
	_spawn_floating_text("🏏 ¡Porrazo Policial!", Color.AQUA, -40.0)

func _fire_police_pistol(player: Node2D) -> void:
	if not player or not player.has_method("take_damage"):
		return
	var is_rifle: bool = carries_police_rifle()
	var to_p: Vector2 = player.global_position - global_position
	if to_p.length_squared() > 0.01:
		facing_direction = to_p.normalized()
	trigger_action_animation(0.38)
	var av3d = get_node_or_null("CharacterAvatar3D")
	if av3d and av3d.has_method("trigger_muzzle_flash"):
		av3d.call("trigger_muzzle_flash")
	_spawn_shot_tracer(player.global_position, Color(1.0, 0.88, 0.32, 0.95), 2.4 if is_rifle else 2.0, 18, -6.0, 0.18)
	var eff: float = get_job_efficiency()
	var dist_shot: float = global_position.distance_to(player.global_position)
	var d := DamageData.new()
	d.amount = (22.0 if is_rifle else 16.0) * eff
	d.type = CombatConstants.DamageType.CUT
	d.bleed_buildup = (26.0 if is_rifle else 20.0) * eff
	d.weapon_tag = "Fusil Policial del Paso" if is_rifle else "Pistola Policial"
	d.is_ranged_projectile = true
	d.is_firearm_bullet = true
	d.firearm_kind = "rifle" if is_rifle else "pistol"
	d.shot_distance_px = dist_shot
	d.source = self
	player.call("take_damage", d)
	if AudioManager:
		AudioManager.emit_noise(global_position, 320.0 if is_rifle else 260.0, elevation_level, "gunshot")
	_spawn_floating_text("🔫 ¡Disparo de Fusil!" if is_rifle else "🔫 ¡Disparo Policial!", Color(1.0, 0.82, 0.28), -42.0)

func _find_downed_npc():
	var vm = _cached_vm
	var hosp_rect := Rect2(704, 110, 82, 80)
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPCBase and n != self:
			var v = n
			if v.is_downed and not v.is_dead:
				if hosp_rect.has_point(v.global_position) or (global_position.distance_to(v.global_position) <= 115.0 and ((vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", global_position, v.global_position)))):
					return v
	return null

## Memoria visual orgánica de cada habitante: recuerda a las últimas personas que vio pasar cerca con línea de visión

func _update_visual_memory(delta: float) -> void:
	_visual_memory_timer -= delta
	if _visual_memory_timer > 0.0:
		return
	_visual_memory_timer = 1.25
	var vm = _cached_vm
	var d: int = WorldClock.current_day if WorldClock else 1
	var h: int = WorldClock.current_hour if WorldClock else 12
	var m: int = WorldClock.current_minute if WorldClock else 0
	var total_mins: int = d * 1440 + h * 60 + m
	var vis_mult: float = get_sleep_vision_multiplier()
	if WorldClock and WorldClock.has_method("get_weather_vision_multiplier"):
		vis_mult *= float(WorldClock.call("get_weather_vision_multiplier"))

	var player := _cached_player
	if is_instance_valid(player) and not witness_silenced_player:
		var in_st: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
		var clk_m: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
		var p_amb: float = float(vm.call("get_ambient_vision_multiplier_at", player.global_position, self)) if (vm != null and vm.has_method("get_ambient_vision_multiplier_at")) else (float(WorldClock.call("get_weather_vision_multiplier")) if WorldClock else 1.0)
		var p_range: float = (62.0 if in_st else 195.0) * clk_m * get_sleep_vision_multiplier() * p_amb
		if global_position.distance_to(player.global_position) <= p_range:
			if vm == null or not vm.has_method("has_line_of_sight") or bool(vm.call("has_line_of_sight", global_position, player.global_position)):
				var p_hc: HealthComponent = player.get_node_or_null("HealthComponent")
				var p_stained: bool = player.has_method("is_bloodstained") and bool(player.call("is_bloodstained"))
				var p_wounded: bool = p_hc != null and p_hc.has_fresh_combat_wounds_or_makeshift()
				_record_entity_sighting("Jugador", true, player.global_position, total_mins, d, h, m, p_stained, p_wounded)

	var npc_range: float = 195.0 * vis_mult
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPCBase and n != self:
			var other := n
			if other.is_dead:
				continue
			var o_amb: float = float(vm.call("get_ambient_vision_multiplier_at", other.global_position, self)) if (vm != null and vm.has_method("get_ambient_vision_multiplier_at")) else (vis_mult / maxf(0.01, get_sleep_vision_multiplier()))
			var eff_npc_range: float = 195.0 * get_sleep_vision_multiplier() * o_amb
			if global_position.distance_squared_to(other.global_position) <= eff_npc_range * eff_npc_range:
				if vm == null or not vm.has_method("has_line_of_sight") or bool(vm.call("has_line_of_sight", global_position, other.global_position)):
					var o_stained: bool = other.is_bloodstained()
					var o_wounded: bool = other.health_comp != null and other.health_comp.has_fresh_combat_wounds_or_makeshift()
					_record_entity_sighting(other.npc_name, false, other.global_position, total_mins, d, h, m, o_stained, o_wounded)

func _record_entity_sighting(ent_name: String, is_p: bool, pos: Vector2, total_mins: int, d: int, h: int, m: int, stained: bool, wounded: bool) -> void:
	for i in range(seen_entities_memory.size()):
		if str(seen_entities_memory[i].get("name", "")) == ent_name:
			seen_entities_memory.remove_at(i)
			break
	seen_entities_memory.push_front({
		"name": ent_name, "is_player": is_p, "pos_x": pos.x, "pos_y": pos.y,
		"witness_x": global_position.x, "witness_y": global_position.y,
		"total_minutes": total_mins, "day": d, "hour": h, "minute": m,
		"bloodstained": stained, "wounded": wounded
	})
	while seen_entities_memory.size() > 12:
		seen_entities_memory.pop_back()

func get_seen_entities_near_crime(crime_pos: Vector2, crime_total_mins: int, max_dist: float = 320.0, max_time_diff: int = 240) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for mem in seen_entities_memory:
		var t_diff: int = abs(crime_total_mins - int(mem.get("total_minutes", crime_total_mins)))
		if t_diff > max_time_diff:
			continue
		var seen_pos := Vector2(float(mem.get("pos_x", 0.0)), float(mem.get("pos_y", 0.0)))
		var d_crime: float = seen_pos.distance_to(crime_pos)
		if d_crime <= max_dist:
			var copy_m: Dictionary = mem.duplicate()
			copy_m["dist_to_crime"] = d_crime
			results.append(copy_m)
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("dist_to_crime", 999.0)) < float(b.get("dist_to_crime", 999.0))
	)
	return results

## Tratamiento médico secuencial herida por herida del Dr. Valen en el Hospital (RimWorld):
## El médico NO cura al 100% de golpe; camina hacia el paciente en la camilla y trata UNA herida cada ~3.2s consumiendo stock real.

func _process_doctor_hospital_treatment(delta: float) -> bool:
	if not is_instance_valid(_active_hospital_patient) or not _patient_still_needs_doctor(_active_hospital_patient):
		_active_hospital_patient = _find_hospital_patient_needing_care()
		_doctor_treat_progress = 0.0
	if _active_hospital_patient == null:
		return false

	var pat_pos: Vector2 = _active_hospital_patient.global_position
	var bedside_pos: Vector2 = pat_pos + Vector2(14.0, 0.0)
	if global_position.distance_to(bedside_pos) > 26.0:
		_doctor_treat_progress = maxf(0.0, _doctor_treat_progress - delta * 8.0)
		_update_craft_bar_visual(0.20, "🩺 Yendo a atender paciente...", Color(0.45, 0.95, 0.75, 0.90))
		_move_towards_point(bedside_pos, 64.0 * lerpf(0.75, 1.0, get_job_efficiency()), delta)
		return true

	velocity = Vector2.ZERO
	if sprite:
		sprite.flip_h = (pat_pos.x < global_position.x)
	trigger_action_animation(0.6)
	var pat_hc: HealthComponent = _active_hospital_patient.get_node_or_null("HealthComponent")
	if pat_hc == null:
		_active_hospital_patient = null
		_stop_crafting_bar()
		return false
	pat_hc.is_resting_in_bed = true

	var pat_label: String = "Forastero" if _active_hospital_patient.is_in_group("player") else str(_active_hospital_patient.get("npc_name"))
	var eff: float = maxf(0.55, get_job_efficiency())
	_doctor_treat_progress += (100.0 / 3.2) * eff * delta
	var pct: int = clampi(int(round(_doctor_treat_progress)), 0, 100)
	_update_craft_bar_visual(_doctor_treat_progress / 100.0, "🩺 Tratando herida de %s (%d%%)" % [pat_label, pct], Color(0.35, 0.98, 0.62, 0.95))

	if _doctor_treat_progress >= 100.0:
		_doctor_treat_progress = 0.0
		_doctor_apply_single_step_treatment(_active_hospital_patient, pat_hc, pat_label)
		if not _patient_still_needs_doctor(_active_hospital_patient):
			_active_hospital_patient = null
			_stop_crafting_bar()
	return true

func _patient_still_needs_doctor(pat: Node2D) -> bool:
	if not is_instance_valid(pat):
		return false
	if pat.get("is_dead") == true:
		return false
	var hosp_zone := Rect2(684, 98, 110, 96)
	if not hosp_zone.has_point(pat.global_position):
		return false
	var hc: HealthComponent = pat.get_node_or_null("HealthComponent")
	if hc == null:
		return false
	if hc.get_most_urgent_untreated_wound_id(false) != -1:
		return true
	if hc.has_active_sickness_or_infection():
		return true
	if hc.is_bleeding or hc.get_total_wound_bleed_rate() > 0.0:
		return true
	return false

func _find_hospital_patient_needing_care() -> Node2D:
	var hosp_zone := Rect2(684, 98, 110, 96)
	var best: Node2D = null
	var best_urgency: float = -1.0
	var candidates: Array[Node2D] = []
	if is_instance_valid(_cached_player):
		candidates.append(_cached_player)
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPCBase and n != self:
			candidates.append(n as Node2D)
	for c in candidates:
		if not _patient_still_needs_doctor(c) or not hosp_zone.has_point(c.global_position):
			continue
		var hc: HealthComponent = c.get_node_or_null("HealthComponent")
		var urg: float = hc.current_blood + hc.get_total_wound_bleed_rate() * 40.0 + float(hc.get_untreated_wound_count()) * 15.0
		if urg > best_urgency:
			best_urgency = urg
			best = c
	return best

func _doctor_apply_single_step_treatment(pat: Node2D, hc: HealthComponent, pat_label: String) -> void:
	# Prioridad 1: Herida sangrante más grave -> Prioridad 2: Herida sin tratar o con vendaje rudimentario
	var wid: int = hc.get_most_urgent_untreated_wound_id(true)
	if wid == -1:
		wid = hc.get_most_urgent_untreated_wound_id(false)
	if wid != -1:
		var w_type: String = "laceration"
		var w_name: String = "Herida"
		for w in hc.wounds:
			if int(w.get("id", -1)) == wid:
				w_type = str(w.get("type", "laceration"))
				w_name = str(w.get("name", "Herida"))
				break
		var used_supply_txt: String = "Cura sin medicina (Sin Stock)"
		if w_type in ["deep_wound", "lodged_arrow"] and int(shop_stock.get("surgical_kit", 0)) > 0:
			shop_stock["surgical_kit"] = int(shop_stock["surgical_kit"]) - 1
			hc.treat_wound(wid, "stitch")
			used_supply_txt = "Sutura Quirúrgica (115%)"
		elif w_type == "fracture" and int(shop_stock.get("bandage", 0)) > 0:
			shop_stock["bandage"] = int(shop_stock["bandage"]) - 1
			hc.treat_wound(wid, "splint")
			used_supply_txt = "Entablillado Clínico (85%)"
		elif int(shop_stock.get("bandage", 0)) > 0:
			shop_stock["bandage"] = int(shop_stock["bandage"]) - 1
			hc.treat_wound(wid, "bandage")
			used_supply_txt = "Vendaje Limpio (85%)"
		elif int(shop_stock.get("herbal_poultice", 0)) > 0:
			shop_stock["herbal_poultice"] = int(shop_stock["herbal_poultice"]) - 1
			hc.treat_wound(wid, "poultice")
			used_supply_txt = "Cataplasma Herbal (70%)"
		else:
			hc.treat_wound(wid, "tend_makeshift")
			for w in hc.wounds:
				if int(w.get("id", -1)) == wid:
					w["tend_quality"] = 42.0
					w["bandage_dirty"] = 18.0
					break
		_sync_shop_stock_to_vm()
		hc.heal(10.0)
		var rem_w: int = hc.get_untreated_wound_count()
		_spawn_floating_text("🩺 %s trató [%s] de %s (%s | Quedan %d heridas)" % [npc_name, w_name, pat_label, used_supply_txt, rem_w], Color.SPRING_GREEN, -42.0)
		if pat.has_method("_spawn_floating_text") and pat != self:
			pat.call("_spawn_floating_text", "🩹 Herida tratada: %s (%s)" % [w_name, used_supply_txt], Color.AQUA, -44.0)
		return

	if hc.has_active_sickness_or_infection():
		if int(shop_stock.get("herbal_poultice", 0)) > 0:
			shop_stock["herbal_poultice"] = int(shop_stock["herbal_poultice"]) - 1
			_sync_shop_stock_to_vm()
			hc.cure_sickness(48.0)
			_spawn_floating_text("🍵🩺 %s administró Cataplasma Antiséptica a %s (+Inmunidad)" % [npc_name, pat_label], Color.SPRING_GREEN, -42.0)
		else:
			hc.cure_sickness(24.0)
			_spawn_floating_text("🩺 %s asistió la fiebre de %s (Sin cataplasmas en stock)" % [npc_name, pat_label], Color.GOLD, -42.0)
		return

	hc.stop_bleeding()
	hc.heal(18.0)

func _process_traveling_merchant_routine(delta: float) -> void:
	var vm = _get_vm()
	if vm and vm.has_method("update_traveling_merchant_ai"):
		vm.call("update_traveling_merchant_ai", self, delta)
	_finish_frame_movement(delta, true)

## IA Deductiva y Persecución del Inquisidor Real Alistair (`TradeRole.ROYAL_INVESTIGATOR`):
## 1º Inspecciona la escena del crimen y la Morgue.
## 2º Interroga físicamente a los habitantes, cruzando coartadas y acumulando sospecha probabilística.
## 3º Inspecciona al jugador si pasa cerca (rango de detección 2x superior al policía común y detecta el Salvoconducto Real robado).
## 4º Filosofía Real: Nunca se va con las manos vacías; condena al sospechoso con mayor puntuación (el Jugador o un aldeano Chivo Expiatorio).

func _process_royal_investigator_ai(delta: float) -> void:
	var vm = _get_vm()
	if vm and bool(vm.get("player_being_escorted_to_jail")) and vm.get("escorting_officer") == self:
		_clear_combat_hostility(false)
		if _process_police_law_enforcement(delta, vm):
			return
	if is_hostile and vm:
		if bool(vm.get("player_in_jail")) or bool(vm.get("player_being_escorted_to_jail")):
			_clear_combat_hostility(false)
			velocity = Vector2.ZERO
		elif _process_police_law_enforcement(delta, vm):
			return
	if vm and vm.has_method("update_royal_investigator_ai"):
		vm.call("update_royal_investigator_ai", self, delta)
	_finish_frame_movement(delta, true)
