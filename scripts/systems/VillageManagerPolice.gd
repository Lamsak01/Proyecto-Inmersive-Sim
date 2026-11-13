@tool
extends "res://scripts/systems/VillageManagerSocial.gd"
const FOOTPRINT_OFFSET := Vector2(0, 5) ## la huella cae a los pies, algo por debajo del centro del cuerpo


func report_assault_crime(victim: VillageNPC) -> void:
	if not victim:
		return
	var witness: VillageNPC = _find_conscious_witness_near(victim.global_position, 155.0, victim)
	if witness != null and witness.witness_silenced_player:
		witness = null
	var victim_officer_conscious: bool = victim.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR] and not victim.is_dead and not victim.is_downed and not victim.is_sleeping and not victim.is_stunned_flag and victim.sedated_timer <= 0.0
	# Si la víctima ya está muerta y quien lo vio es un civil (no un policía), NO hay alerta telepática inmediata:
	# el testigo primero examina el cuerpo 10s, va caminando en persona hasta la policía y pasa 12.5s explicándolo.
	if victim.is_dead and witness != null and not (witness.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR]):
		victim.murder_witness_name = witness.npc_name
		victim.begin_physical_corpse_discovery(witness)
		return
	if witness != null or victim_officer_conscious:
		wanted_level = clampi(wanted_level + 1, 1, 5)
		bounty_gold += 25
		if victim.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR]:
			is_resisting_arrest = true
			alert_police_to_resist(get_tree().get_first_node_in_group("player") as Node2D)
		var w_name: String = witness.npc_name if witness != null else victim.npc_name
		var msg := "👁️🚨 ¡%s presenció el ataque a %s! (+25 Oro de multa policial)" % [w_name, victim.npc_name]
		crime_history.push_front(msg)
		_notify_inquisitor_of_police_crime(msg, 24)
		_hint_player(msg)

## Se ejecuta cuando un aldeano termina de explicar físicamente a la policía que ha encontrado el cadáver de un civil (tras los 10s de examen + caminata + 12.5s de explicación)

func on_civilian_corpse_reported(victim: VillageNPC, death_pos: Vector2, weapon_name: String, discoverer_name: String = "") -> void:
	if not victim:
		return
	var mw: String = str(victim.murder_witness_name) if "murder_witness_name" in victim else ""
	if mw != "":
		var mw_npc: VillageNPC = _find_npc_by_name(mw)
		if mw_npc != null and mw_npc.witness_silenced_player:
			mw = ""
			victim.murder_witness_name = ""
	if victim.last_hit_by_player and mw != "":
		if not victim.has_meta("murder_warrant_issued"):
			victim.set_meta("murder_warrant_issued", true)
			wanted_level = clampi(wanted_level + 2, 1, 5)
			bounty_gold += 70
			player_murder_warrants_count += 1
			var msg := "🚓🚨 ¡%s declaró personalmente ante la policía que te vio asesinar a %s! (+70 Oro de multa)" % [mw, victim.npc_name]
			crime_history.push_front(msg)
			_notify_inquisitor_of_police_crime(msg, 45)
			_hint_player(msg)
	else:
		var d: int = victim.death_day if ("death_day" in victim and victim.death_day >= 1) else (WorldClock.current_day if WorldClock else 1)
		var h: int = victim.death_hour if ("death_hour" in victim and victim.death_hour >= 0) else (WorldClock.current_hour if WorldClock else 12)
		var m: int = victim.death_minute if ("death_minute" in victim and victim.death_minute >= 0) else (WorldClock.current_minute if WorldClock else 0)
		start_sheriff_investigation(victim, death_pos, weapon_name, discoverer_name, d * 1440 + h * 60 + m)

func report_pet_assault_crime(pet: Node2D) -> void:
	if not pet or ("family_id" in pet and str(pet.get("family_id")) == "player_farm"):
		return
	var witness: VillageNPC = _find_conscious_witness_near(pet.global_position, 145.0, null)
	if witness != null:
		wanted_level = clampi(wanted_level + 1, 1, 5)
		bounty_gold += 18
		var p_name: String = str(pet.get("pet_name")) if "pet_name" in pet else "una mascota"
		var fam_id: String = str(pet.get("family_id")) if "family_id" in pet else "none"
		if fam_id != "none" and fam_id != "player_farm":
			modify_family_reputation(fam_id, -25, "Atacó a su mascota " + p_name)
		var msg := "🐾🚨 ¡%s te vio atacar a %s! (+18 Oro de multa por crueldad)" % [witness.npc_name, p_name]
		crime_history.push_front(msg)
		_notify_inquisitor_of_police_crime(msg, 14)
		_hint_player(msg)

func report_theft_crime(fam_id: String, reason: String, crime_pos: Vector2) -> void:
	var witness: VillageNPC = _find_conscious_witness_near(crime_pos, 145.0, null)
	if witness != null:
		wanted_level = clampi(wanted_level + 1, 1, 5)
		bounty_gold += 20
		if fam_id != "none" and fam_id != "player_farm":
			modify_family_reputation(fam_id, -20, reason)
		var msg := "🕵️🚨 ¡%s te vio cometer robo (%s)! (+20 Oro de multa policial)" % [witness.npc_name, reason]
		crime_history.push_front(msg)
		_notify_inquisitor_of_police_crime(msg, 16)
		_hint_player(msg)

## Paso 1 y Paso 2: Cuando un NPC descubre un cadáver y lo traslada a la Morgue (máx. 3 camillas) o al Cementerio Parroquial (si la Morgue está llena)

func register_npc_death_and_corpse(
	victim: VillageNPC,
	death_pos: Vector2,
	weapon_name: String,
	by_player: bool,
	discoverer_name: String = "",
	rot_hours: float = 0.0
) -> void:
	if not victim:
		return
	var h: int = victim.death_hour if ("death_hour" in victim and victim.death_hour >= 0) else (WorldClock.current_hour if WorldClock else 12)
	var m: int = victim.death_minute if ("death_minute" in victim and victim.death_minute >= 0) else (WorldClock.current_minute if WorldClock else 0)
	var d: int = victim.death_day if ("death_day" in victim and victim.death_day >= 1) else (WorldClock.current_day if WorldClock else 1)
	var death_mins: int = d * 1440 + h * 60 + m
	var cur_d: int = WorldClock.current_day if WorldClock else d
	var cur_h: int = WorldClock.current_hour if WorldClock else h
	var added_total_hours: int = cur_d * 24 + cur_h
	var rot_days: int = int(floor(rot_hours / 24.0))
	var rot_desc: String = "Reciente (<1h)" if rot_hours < 1.0 else (
		"%d días (%dh) en descomposición" % [rot_days, int(round(rot_hours))] if rot_days >= 1 else "%dh antes del hallazgo" % int(round(rot_hours))
	)
	var finder_str: String = discoverer_name if discoverer_name != "" else "Dr. Valen"
	var time_str: String = "Muerte: Día %d (%02d:%02d) | Estado: %s (Hallado por %s)" % [d, h, m, rot_desc, finder_str]

	var b_info: Dictionary = _get_building_at_pos(death_pos)
	var crime_scene_name: String = str(b_info.get("title", "Vía Pública del Valle"))
	var crime_b_id: String = str(b_info.get("id", ""))

	var witness_clue: String = "Ningún vecino reportó entradas sospechosas."
	var suspect_str: String = "Desconocido (Caso sin resolver)"

	if by_player:
		var mw_check: String = str(victim.murder_witness_name) if "murder_witness_name" in victim else ""
		if mw_check != "":
			var mw_n: VillageNPC = _find_npc_by_name(mw_check)
			if mw_n != null and mw_n.witness_silenced_player:
				mw_check = ""
				victim.murder_witness_name = ""
		var had_direct_witness: bool = (mw_check != "")
		if had_direct_witness:
			var mw: String = mw_check
			witness_clue = "%s presenció el ataque directamente." % mw
			suspect_str = "Jugador (Testigo presencial: %s)" % mw
			if not victim.has_meta("murder_warrant_issued"):
				victim.set_meta("murder_warrant_issued", true)
				wanted_level = clampi(wanted_level + 2, 1, 5)
				bounty_gold += 70
				player_murder_warrants_count += 1
				_notify_inquisitor_of_police_crime("Orden de captura forense emitida: %s vio al Forastero asesinar a %s." % [mw, victim.npc_name], 45)
		elif crime_b_id != "":
			# 2. ¿Alguien vio al jugador entrar o salir de ese edificio cerca de la hora de la muerte (`sighting_log`)?
			for s_entry in sighting_log:
				var w_name: String = str(s_entry.get("witness_name", "Un vecino"))
				var w_node_chk: VillageNPC = _find_npc_by_name(w_name)
				if w_node_chk != null and w_node_chk.witness_silenced_player:
					continue
				if str(s_entry.get("building_id", "")) == crime_b_id and abs(death_mins - int(s_entry.get("total_minutes", 0))) <= 360:
					var s_h: int = int(s_entry.get("hour", h))
					var s_m: int = int(s_entry.get("minute", m))
					witness_clue = "%s vio al jugador %s %s a las %02d:%02d." % [w_name, str(s_entry.get("action", "entrar a")), crime_scene_name, s_h, s_m]
					suspect_str = "Jugador (Identificado por cruce forense + testigo %s)" % w_name
					wanted_level = clampi(wanted_level + 2, 1, 5)
					bounty_gold += 65
					player_murder_warrants_count += 1
					_notify_inquisitor_of_police_crime("Cruce forense en Morgue: %s situó al Forastero en el asesinato de %s." % [w_name, victim.npc_name], 38)
					break

	# Si el cadáver reportado/trasladado es un Mercader Viajero y aún no se había convocado al Inquisidor Real, convocarlo ahora
	if victim.trade_role == VillageNPC.TradeRole.TRAVELING_MERCHANT:
		on_traveling_merchant_murdered(victim, weapon_name)
	# Si el asesinato ocurrió sin testigo presencial directo del golpe, el Comisario Vane inicia una investigación en cadena (empezando por quien reportó el cuerpo)
	elif not suspect_str.begins_with("Jugador"):
		start_sheriff_investigation(victim, death_pos, weapon_name, finder_str, death_mins)

	var is_case_already_resolved: bool = suspect_str.begins_with("Jugador") and victim.trade_role != VillageNPC.TradeRole.TRAVELING_MERCHANT
	if VillageNPC.is_natural_death_cause(weapon_name) and not victim.last_hit_by_player: # J2: no es un crimen
		is_case_already_resolved = true
		suspect_str = "Sin crimen: %s" % VillageNPC.natural_death_text(weapon_name)
	var record: Dictionary = {
		"victim_name": victim.npc_name, "victim_role": victim.npc_role, "family_name": victim.family_name,
		"time_str": time_str, "crime_scene": crime_scene_name, "cause_of_death": weapon_name,
		"witness_clue": witness_clue, "suspect": suspect_str, "added_total_hours": added_total_hours,
		"death_pos_x": death_pos.x, "death_pos_y": death_pos.y, "discoverer_name": finder_str, "death_mins": death_mins,
		"case_resolved": is_case_already_resolved, "buried": false
	}
	corpse_records.push_front(record)

	if morgue_active_corpses.size() >= MAX_MORGUE_CAPACITY:
		for old_i in range(morgue_active_corpses.size()):
			var old_rec: Dictionary = morgue_active_corpses[old_i]
			if not _is_corpse_under_active_investigation(str(old_rec.get("victim_name", ""))):
				morgue_active_corpses.remove_at(old_i)
				_bury_corpse_in_cemetery(old_rec, "Traslado al Cementerio para liberar camilla forense")
				break

	var buried_directly := false
	if morgue_active_corpses.size() < MAX_MORGUE_CAPACITY:
		morgue_active_corpses.append(record)
		_refresh_morgue_table_sprites()
	else:
		buried_directly = true
		_bury_corpse_in_cemetery(record, "Sepultura directa (Morgue al límite de 3/3 camillas)")
		_refresh_morgue_table_sprites()

	# Si el Inquisidor Real Alistair está activo en el valle, re-cruzar los expedientes de la Morgue y Comisaría con el nuevo cadáver registrado
	if bool(active_royal_investigation.get("active", false)) and is_instance_valid(_royal_investigator_npc):
		active_royal_investigation["morgue_checked"] = false
		_cross_check_morgue_and_police_records(_royal_investigator_npc, active_royal_investigation.get("suspects", {}), active_royal_investigation.get("clues_log", []))

	if buried_directly:
		_hint_player("🪦🚨 La Morgue está llena (3/3): %s fue sepultado en el Cementerio Parroquial. ¡%s! (Multa: %d Oro)." % [victim.npc_name, witness_clue, bounty_gold] if suspect_str.begins_with("Jugador") else "🪦⛪ La Morgue está llena (3/3 camillas): El cuerpo de %s fue sepultado directamente en el Cementerio de la Iglesia." % victim.npc_name)
	else:
		_hint_player("⚰️🚨 El cuerpo de %s fue trasladado a la Morgue (%d/3). ¡%s! Orden de arresto emitida (Multa: %d Oro)." % [victim.npc_name, morgue_active_corpses.size(), witness_clue, bounty_gold] if suspect_str.begins_with("Jugador") else "⚰️🕵️ El cuerpo de %s está en la Morgue Forense (%d/3 camillas): conserva sus pertenencias y permanecerá aquí hasta que se resuelva o archive el caso." % [victim.npc_name, morgue_active_corpses.size()])

## Paso 4: Propaga cambios de reputación a toda una familia (`family_id`)

func clear_police_hostility() -> void:
	var hunting_player_royally: bool = bool(active_royal_investigation.get("active", false)) and str(active_royal_investigation.get("stage", "")) == "HUNTING_PLAYER" and not player_in_jail and not player_being_escorted_to_jail
	if not hunting_player_royally:
		is_resisting_arrest = false
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.trade_role == VillageNPC.TradeRole.ROYAL_INVESTIGATOR and hunting_player_royally:
				continue
			v.is_hostile = false
			v.remove_from_group("enemies")
			v.velocity = Vector2.ZERO
			if "_police_alerted_timer" in v:
				v._police_alerted_timer = 0.0
			if "_civilian_hostile_timer" in v:
				v._civilian_hostile_timer = 0.0

func alert_police_to_resist(player: Node2D = null) -> void:
	is_resisting_arrest = true
	if wanted_level <= 0:
		wanted_level = 1
		bounty_gold = maxi(25, bounty_gold)
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD] and not v.is_dead and not v.is_downed:
				if "_police_alerted_timer" in v:
					v._police_alerted_timer = 14.0
				if player != null and "_last_seen_player_pos" in v:
					v._last_seen_player_pos = player.global_position
	if bool(active_royal_investigation.get("active", false)) and str(active_royal_investigation.get("stage", "")) == "HUNTING_PLAYER":
		if is_instance_valid(_royal_investigator_npc) and not _royal_investigator_npc.is_dead and not _royal_investigator_npc.is_downed:
			_royal_investigator_npc.is_hostile = true
			_royal_investigator_npc._police_alerted_timer = 45.0
			if not _royal_investigator_npc.is_in_group("enemies"):
				_royal_investigator_npc.add_to_group("enemies")

func trigger_police_confrontation(officer: VillageNPC = null) -> void:
	if _police_confront_cooldown > 0.0 or not police_panel:
		return
	if player_in_jail or not is_resisting_arrest:
		clear_police_hostility()
	_police_confront_cooldown = 4.0
	if officer != null:
		_last_confronting_officer = officer
	var off_name: String = officer.npc_name if officer else "Comisario Vane"
	var state_txt: String = ""
	if player_in_jail:
		if jail_mandatory_stay_timer > 0.0:
			state_txt = "🔒 ESTÁS RECLUIDO EN LA CELDA DE LA COMISARÍA\n⏳ Tiempo obligatorio en celda antes de acostarte en el camastro: %ds" % int(ceil(jail_mandatory_stay_timer))
		else:
			state_txt = "🔒🛏️ CELDA DE LA COMISARÍA — Camastro disponible para cumplir la pena (Avance Orgánico del Mundo)"
	else:
		state_txt = "🚨 ¡ALTO A LA GUARDIA! (%s intenta negociar tu entrega)\n[1] Entregarte: El agente te esposará y te llevará caminando físicamente hasta la Celda" % off_name
	police_info_lbl.text = "%s\nNivel de Búsqueda: %d | Multa Acumulada: %d Oro\nSi te resistes [3], la policía usará Porra de cerca y Pistola a distancia:" % [state_txt, wanted_level, maxi(15, bounty_gold)]
	police_panel.visible = true

func _find_nearest_police_officer(pos: Vector2) -> VillageNPC:
	var best: VillageNPC = null
	var best_d: float = INF
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR] and not v.is_dead and not v.is_downed and not v.is_stunned_flag and v.sedated_timer <= 0.0:
				var d: float = pos.distance_to(v.global_position)
				if d < best_d:
					best_d = d
					best = v
	if best == null:
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC:
				var v := n as VillageNPC
				if v.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR] and not v.is_dead and not v.is_downed:
					var d2: float = pos.distance_to(v.global_position)
					if d2 < best_d:
						best_d = d2
						best = v
	return best

## Inicia la escolta física del jugador esposado caminando por las calles y puertas hasta la celda (Estilo Kenshi / RDR2)

func start_police_escort_to_jail(player: Node2D, officer: VillageNPC = null) -> void:
	if not player:
		return
	var chosen_officer: VillageNPC = officer if (officer != null and is_instance_valid(officer) and not officer.is_dead and not officer.is_downed and not officer.is_stunned_flag and officer.sedated_timer <= 0.0) else _find_nearest_police_officer(player.global_position)
	player_being_escorted_to_jail = true
	player_in_jail = false
	_escort_elapsed_timer = 0.0
	escorting_officer = chosen_officer
	clear_police_hostility()
	set_jail_cell_gate_locked(false)
	if police_panel:
		police_panel.visible = false
	if "velocity" in player:
		player.velocity = Vector2.ZERO
	if chosen_officer != null:
		chosen_officer.is_sleeping = false
		chosen_officer.sedated_timer = 0.0
		chosen_officer.is_stunned_flag = false
		if chosen_officer.body_col:
			chosen_officer.body_col.disabled = true
		if chosen_officer.health_comp:
			chosen_officer.health_comp.stop_bleeding()
			chosen_officer.health_comp.current_health = maxf(chosen_officer.health_comp.current_health, 28.0)
		if chosen_officer.sprite:
			chosen_officer.sprite.rotation_degrees = 0.0
			chosen_officer.sprite.modulate = Color.WHITE
		if chosen_officer.global_position.distance_to(player.global_position) > 48.0:
			chosen_officer.global_position = player.global_position + Vector2(14, 0)
		chosen_officer._spawn_floating_text("🚔⛓️ ¡Esposado! En marcha hacia la Celda de la Comisaría", Color.SKY_BLUE, -42.0)
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🚔⛓️ La policía te lleva físicamente hacia la Prisión...", Color.SKY_BLUE, -46.0)

## Controla físicamente la puerta de barrotes de la celda (`Vector2(902, 152)`) y abre la puerta principal de la Comisaría al quedar en libertad

func set_jail_cell_gate_locked(locked: bool) -> void:
	if is_instance_valid(_jail_cell_gate_col):
		_jail_cell_gate_col.disabled = not locked
		_jail_cell_gate_col.set_deferred("disabled", not locked)
	if not locked:
		for d_entry in building_doors:
			if str(d_entry.get("building_id", "")) == "building_police":
				_set_door_state(d_entry, true, false, false)

## Se ejecuta cuando el agente y el jugador llegan caminando físicamente al interior de la celda

func complete_police_escort_to_jail(player: Node2D) -> void:
	clear_police_hostility()
	player_being_escorted_to_jail = false
	escorting_officer = null
	player_in_jail = true
	player_arrests_count += 1
	jail_mandatory_stay_timer = JAIL_MANDATORY_STAY_SECONDS
	set_jail_cell_gate_locked(true)
	_notify_inquisitor_of_police_crime("El Comisario Vane encarceló al Forastero en el calabozo municipal.", 42)
	if not active_royal_investigation.is_empty() and bool(active_royal_investigation.get("active", false)):
		var cur_stg: String = str(active_royal_investigation.get("stage", ""))
		# Si Alistair ya pasó la Morgue y estaba interrogando al pueblo, acude de inmediato a los barrotes de la celda;
		# si aún está en CRIME_SCENE o MORGUE, primero termina la autopsia (~10s) y luego va directo a INITIAL_PLAYER_INTERVIEW.
		if cur_stg == "INTERVIEWS":
			var cur_t: String = str(active_royal_investigation.get("current_interview_target", ""))
			if cur_t != "":
				var q_arr: Array = active_royal_investigation.get("interview_queue", [])
				q_arr.push_front(cur_t)
				active_royal_investigation["current_interview_target"] = ""
			active_royal_investigation["stage"] = "INITIAL_PLAYER_INTERVIEW"
			active_royal_investigation["stage_timer"] = 0.0
	if player:
		player.global_position = _jail_cell_pos
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		_msg_player(player, "🔒⛓️ Encerrado en la Celda (%ds de estancia antes de usar el camastro)" % int(JAIL_MANDATORY_STAY_SECONDS), Color.SKY_BLUE, -46.0)
	_police_confront_cooldown = 0.0
	trigger_police_confrontation(null)

func capture_knocked_out_player_to_jail(player: Node2D) -> void:
	if player:
		start_police_escort_to_jail(player, _last_confronting_officer)

func send_player_to_jail(player: Node2D) -> void:
	if player:
		start_police_escort_to_jail(player, _last_confronting_officer)

func _on_police_serve_sentence(player: Node2D) -> void:
	if not player:
		return
	if not player_in_jail and not player_being_escorted_to_jail:
		start_police_escort_to_jail(player, _last_confronting_officer)
		return
	if player_being_escorted_to_jail:
		if police_panel:
			police_panel.visible = false
		_msg_player(player, "🚔⛓️ Espera a llegar a la celda con el guardia...", Color.GOLD, -42.0)
		return

	if jail_mandatory_stay_timer > 0.0:
		var wait_s: int = int(ceil(jail_mandatory_stay_timer))
		if police_info_lbl:
			police_info_lbl.text = "⏳🔒 AÚN NO PUEDES USAR EL CAMASTRO DE LA CELDA\nDebes permanecer %ds más en la celda antes de acostarte para cumplir tu pena.\n(También puedes pagar tu fianza [2] o forzar los barrotes [3])." % wait_s
		_msg_player(player, "⏳🔒 Espera %ds en la celda antes de acostarte en el camastro" % wait_s, Color.GOLD, -44.0)
		return

	if police_panel:
		police_panel.visible = false
	_msg_player(player, "🛏️⏩ Cumpliendo pena en el camastro: El mundo avanza orgánicamente hasta las 06:00 AM...", Color.AQUA, -46.0)
	if WorldClock and WorldClock.has_method("start_organic_fast_forward"):
		WorldClock.start_organic_fast_forward(6, 26.0, func(): release_player_from_jail_after_sentence(player))
	else:
		release_player_from_jail_after_sentence(player)

func release_player_from_jail_after_sentence(player: Node2D) -> void:
	clear_police_hostility()
	player_being_escorted_to_jail = false
	escorting_officer = null
	player_in_jail = false
	jail_mandatory_stay_timer = 0.0
	wanted_level = 0
	bounty_gold = 0
	set_jail_cell_gate_locked(false)
	if bool(active_royal_investigation.get("active", false)) and str(active_royal_investigation.get("stage", "")) == "HUNTING_PLAYER":
		active_royal_investigation["stage"] = "DEPARTING"
		active_royal_investigation["stage_timer"] = 0.0
		if is_instance_valid(_royal_investigator_npc):
			_royal_investigator_npc.is_hostile = false
			_royal_investigator_npc.remove_from_group("enemies")
	if player and is_instance_valid(player):
		var surv: SurvivalComponent = player.get_node_or_null("SurvivalComponent")
		if surv:
			surv.restore_sleep(85.0)
		_msg_player(player, "⚖️🔓 Condena cumplida (06:00 AM): Reja abierta, puedes salir caminando de la Comisaría", Color.SPRING_GREEN, -46.0)

func pay_bounty_fine(player: Node2D) -> void:
	if not player or not ("inventory" in player) or not player.inventory:
		return
	if bool(active_royal_investigation.get("active", false)) and str(active_royal_investigation.get("stage", "")) == "HUNTING_PLAYER" and not player_in_jail:
		_msg_player(player, "⚖️👑 Orden de Captura Real activa: debes entregarte en la Celda [1] antes de pagar fianza", Color.ORANGE_RED, -44.0)
		return
	var inv: SimpleInventory = player.inventory
	var fine: int = maxi(15, bounty_gold) if wanted_level > 0 else 0
	if fine <= 0 and not player_in_jail and not player_being_escorted_to_jail:
		if police_panel:
			police_panel.visible = false
		_msg_player(player, "✅ No tienes multas ni cargos pendientes", Color.SPRING_GREEN, -42.0)
		return
	var cost: int = maxi(15, fine)
	if inv.gold < cost:
		_msg_player(player, "❌ Necesitas %d Oro para pagar la fianza" % cost, Color.ORANGE_RED, -42.0)
		return
	inv.add_gold(-cost)
	town_state["treasury"] = int(town_state.get("treasury", 0)) + cost # Regla 1: la fianza va a las arcas
	if not player_in_jail:
		player_arrests_count += 1
		_notify_inquisitor_of_police_crime("El Forastero pagó %d Oro de fianza policial tras ser detenido por la Guardia." % cost, 30)
	clear_police_hostility()
	player_being_escorted_to_jail = false
	escorting_officer = null
	jail_mandatory_stay_timer = 0.0
	wanted_level = 0
	bounty_gold = 0
	if player_in_jail:
		player_in_jail = false
		set_jail_cell_gate_locked(false)
	if bool(active_royal_investigation.get("active", false)) and str(active_royal_investigation.get("stage", "")) == "HUNTING_PLAYER":
		active_royal_investigation["stage"] = "DEPARTING"
		active_royal_investigation["stage_timer"] = 0.0
		if is_instance_valid(_royal_investigator_npc):
			_royal_investigator_npc.is_hostile = false
			_royal_investigator_npc.remove_from_group("enemies")
	if police_panel:
		police_panel.visible = false
	_msg_player(player, "⚖️🔓 Fianza pagada (-%d Oro): Reja abierta, puedes salir caminando" % cost, Color.GOLD, -44.0)

func _on_police_jailbreak_or_resist(player: Node2D) -> void:
	if police_panel:
		police_panel.visible = false
	if not player:
		return
	if WorldClock and WorldClock.has_method("stop_organic_fast_forward") and WorldClock.is_fast_forwarding:
		WorldClock.stop_organic_fast_forward(false)
	if player_in_jail or player_being_escorted_to_jail:
		var was_in_cell: bool = player_in_jail
		player_in_jail = false
		player_being_escorted_to_jail = false
		escorting_officer = null
		jail_mandatory_stay_timer = 0.0
		set_jail_cell_gate_locked(false)
		var in_stealth_jb: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
		var has_master_pick: bool = player.has_method("has_master_lockpick") and bool(player.call("has_master_lockpick"))
		var stealth_sk_bonus: float = float(player.call("get_skill_bonus", "stealth")) if player.has_method("get_skill_bonus") else 0.0
		var detect_jb_rad: float = (58.0 if in_stealth_jb else 135.0) * (0.35 if has_master_pick else 1.0) * clampf(1.0 - stealth_sk_bonus, 0.40, 1.0)
		var gate_pos := Vector2(902, 152)
		var watching_officer: VillageNPC = null
		if was_in_cell:
			for n_off in get_tree().get_nodes_in_group("village_npcs"):
				if n_off is VillageNPC:
					var vo := n_off as VillageNPC
					if vo.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR] and vo.is_conscious():
						if vo.global_position.distance_to(gate_pos) <= detect_jb_rad and has_line_of_sight(vo.global_position, gate_pos):
							watching_officer = vo
							break
		if was_in_cell and watching_officer == null:
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🔓🤫 ¡Fuga sigilosa! Forzaste la reja de la celda sin despertar ni alertar a la guardia", Color.SPRING_GREEN, -46.0)
			_hint_player("🔓🤫 Has forzado la cerradura de la celda en completo silencio. Sal de la Comisaría sin que te vean.", player)
		else:
			wanted_level = clampi(wanted_level + 1, 2, 5)
			bounty_gold += 30
			alert_police_to_resist(player)
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🔓🔫 ¡Barrotes forzados! La guardia te vio escapar (+30 Oro de multa)", Color.ORANGE_RED, -46.0)
	else:
		_police_confront_cooldown = 8.0
		bounty_gold += 15
		alert_police_to_resist(player)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🔫🏏 ¡Te resistes al arresto! La Policía usa Pistola y Porra", Color.ORANGE_RED, -44.0)

func _open_notice_board_ui() -> void:
	if not board_panel:
		return
	var d: int = WorldClock.current_day if WorldClock else 1
	var c1: String = "✅ COMPLETADO" if int(completed_contracts_today.get(1, -1)) == d else "🟢 DISPONIBLE"
	var c2: String = "✅ COMPLETADO" if int(completed_contracts_today.get(2, -1)) == d else "🟢 DISPONIBLE"
	var c3: String = "✅ COMPLETADO" if int(completed_contracts_today.get(3, -1)) == d else "🟢 DISPONIBLE"
	board_info_lbl.text = "📋 TABLÓN DE ENCARGOS DE LA PLAZA CENTRAL (Día %d)\nEstado hoy -> [1] Gremios: %s | [2] Hospital: %s | [3] Comisaría: %s" % [d, c1, c2, c3]
	var news: Array[Dictionary] = get_public_news()
	if not news.is_empty():
		board_info_lbl.text += "\n🗞️ NOTICIAS DEL PUEBLO"
		for ev in news:
			board_info_lbl.text += "\n• Día %d: %s" % [int(ev.get("day", 0)), str(ev.get("summary", ""))]
	board_panel.visible = true

func _complete_board_contract(player: Node2D, contract_idx: int) -> void:
	if not player or not ("inventory" in player) or not player.inventory:
		return
	var d: int = WorldClock.current_day if WorldClock else 1
	if int(completed_contracts_today.get(contract_idx, -1)) == d:
		_msg_player(player, "✅ Ya completaste este encargo hoy", Color.GOLD, -42.0)
		return
	var inv: SimpleInventory = player.inventory
	# Regla 1: los encargos del tablón los pagan las arcas municipales; si no llegan, hoy no se paga.
	var board_pay: int = {1: 28, 2: 26, 3: 34}.get(contract_idx, 0)
	if board_pay > 0 and int(town_state.get("treasury", 0)) < board_pay:
		_msg_player(player, "🏛️❌ Las arcas no pueden pagar este encargo hoy (%d Oro)" % board_pay, Color.ORANGE_RED, -42.0)
		return
	if contract_idx == 1:
		if inv.has_item("wood", 2): inv.remove_item("wood", 2)
		elif inv.has_item("iron_ore", 1): inv.remove_item("iron_ore", 1)
		else:
			_msg_player(player, "❌ Requiere 2 Maderas o 1 Mineral de Hierro", Color.ORANGE_RED, -42.0)
			return
		inv.add_gold(take_from_treasury(28))
		modify_family_reputation("family_carpenter", 15, "Encargo del tablón completado")
		modify_family_reputation("family_smith", 15, "Encargo del tablón completado")
		completed_contracts_today[1] = d
		_msg_player(player, "📋⚒️ ¡Encargo Artesanal completado! (+28 Oro, +15 Afinidad)", Color.SPRING_GREEN, -44.0)
	elif contract_idx == 2:
		if inv.has_item("herbs", 2): inv.remove_item("herbs", 2)
		elif inv.has_item("herbal_poultice", 1): inv.remove_item("herbal_poultice", 1)
		else:
			_msg_player(player, "❌ Requiere 2 Hierbas Medicinales o 1 Cataplasma", Color.ORANGE_RED, -42.0)
			return
		inv.add_gold(take_from_treasury(26))
		modify_family_reputation("family_herbalist", 15, "Suministro médico entregado")
		completed_contracts_today[2] = d
		_msg_player(player, "📋🏥 ¡Urgencia Médica completada! (+26 Oro, +15 Afinidad)", Color.SPRING_GREEN, -44.0)
	elif contract_idx == 3:
		if inv.has_item("bandit_scrap", 1): inv.remove_item("bandit_scrap", 1)
		elif inv.has_item("frog_legs", 1): inv.remove_item("frog_legs", 1)
		else:
			_msg_player(player, "❌ Requiere 1 Chatarra de Bandido o 1 Ancas de Rana", Color.ORANGE_RED, -42.0)
			return
		inv.add_gold(take_from_treasury(34))
		if wanted_level > 0:
			wanted_level = maxi(0, wanted_level - 1)
			bounty_gold = maxi(0, bounty_gold - 25)
		completed_contracts_today[3] = d
		_msg_player(player, "📋🚓 ¡Recompensa cobrada! (+34 Oro, -1 Nivel de Búsqueda)", Color.GOLD, -44.0)
	_open_notice_board_ui()

# ==============================================================================
# HUÉSPEDES DE LA POSADA, POZO, COMPOSTADOR Y MASCOTAS
# ==============================================================================

func spawn_blood_puddle(pos: Vector2, victim_name: String = "") -> void:
	if not is_instance_valid(entities_root):
		return
	for existing in blood_puddles:
		var ex_pos: Vector2 = existing.get("pos", Vector2.ZERO)
		if ex_pos.distance_to(pos) <= 20.0:
			if victim_name != "":
				existing["victim_name"] = victim_name
			return
	var cur_d: int = WorldClock.current_day if WorldClock else 1
	var cur_h: int = WorldClock.current_hour if WorldClock else 12
	var cur_m: int = WorldClock.current_minute if WorldClock else 0
	blood_puddles.append({
		"pos": pos,
		"victim_name": victim_name,
		"footprints": [], # [{pos, angle, alpha}]: el rastro que dibuja Rastros3D
		"flee_dir": Vector2.ZERO,
		"flee_compass": "",
		"last_stepper": "",
		"created_mins": cur_d * 1440 + cur_h * 60 + cur_m
	})

func update_entity_blood_footprints(entity: Node2D, _delta: float) -> void:
	if entity == null or not is_instance_valid(entities_root) or blood_puddles.is_empty():
		return
	var steps_left: int = int(entity.get_meta("bloody_steps_left", 0)) if entity.has_meta("bloody_steps_left") else 0
	var ent_pos: Vector2 = entity.global_position
	if steps_left <= 0:
		for i in range(blood_puddles.size()):
			var pud: Dictionary = blood_puddles[i]
			var p_pos: Vector2 = pud.get("pos", Vector2.ZERO)
			if ent_pos.distance_squared_to(p_pos) <= 16.0 * 16.0:
				entity.set_meta("bloody_steps_left", 6)
				entity.set_meta("bloody_last_step_pos", ent_pos)
				entity.set_meta("bloody_puddle_idx", i)
				entity.set_meta("bloody_origin_pos", p_pos)
				if entity.has_method("add_bloodstain"):
					entity.call("add_bloodstain", 180.0)
				break
		return

	var last_pos: Vector2 = entity.get_meta("bloody_last_step_pos", ent_pos) as Vector2
	if ent_pos.distance_squared_to(last_pos) < 15.0 * 15.0:
		return

	steps_left -= 1
	entity.set_meta("bloody_steps_left", steps_left)
	entity.set_meta("bloody_last_step_pos", ent_pos)

	var origin_pos: Vector2 = entity.get_meta("bloody_origin_pos", last_pos) as Vector2
	var move_vec: Vector2 = ent_pos - origin_pos
	var flee_dir: Vector2 = move_vec.normalized() if move_vec.length_squared() > 1.0 else (ent_pos - last_pos).normalized()
	var alpha: float = clampf(0.28 + float(steps_left) * 0.09, 0.25, 0.82)
	var huella: Dictionary = {"pos": ent_pos + FOOTPRINT_OFFSET, "angle": flee_dir.angle(), "alpha": alpha}

	var p_idx: int = int(entity.get_meta("bloody_puddle_idx", -1))
	if p_idx >= 0 and p_idx < blood_puddles.size() and flee_dir.length_squared() > 0.01:
		var pud: Dictionary = blood_puddles[p_idx]
		pud["flee_dir"] = flee_dir
		pud["flee_compass"] = _describe_direction_and_landmark(origin_pos, flee_dir)
		var ent_name: String = "Jugador" if entity.is_in_group("player") else (str(entity.get("npc_name")) if "npc_name" in entity else str(entity.name))
		pud["last_stepper"] = ent_name
		(pud["footprints"] as Array).append(huella)

func get_blood_puddle_clue_near(crime_pos: Vector2, max_radius: float = 95.0) -> Dictionary:
	var best_idx: int = -1
	var best_d2: float = max_radius * max_radius
	for i in range(blood_puddles.size()):
		var p_pos: Vector2 = blood_puddles[i].get("pos", Vector2.ZERO)
		var d2: float = crime_pos.distance_squared_to(p_pos)
		if d2 <= best_d2:
			best_d2 = d2
			best_idx = i
	return blood_puddles[best_idx] if best_idx >= 0 else {}

func _describe_direction_and_landmark(origin: Vector2, dir: Vector2) -> String:
	if dir.length_squared() <= 0.001:
		return "dirección indeterminada"
	var ang: float = rad_to_deg(dir.angle())
	var compass: String = "hacia el Este"
	if ang >= -22.5 and ang < 22.5: compass = "hacia el Este"
	elif ang >= 22.5 and ang < 67.5: compass = "hacia el Sureste"
	elif ang >= 67.5 and ang < 112.5: compass = "hacia el Sur"
	elif ang >= 112.5 and ang < 157.5: compass = "hacia el Suroeste"
	elif ang >= 157.5 or ang < -157.5: compass = "hacia el Oeste"
	elif ang >= -157.5 and ang < -112.5: compass = "hacia el Noroeste"
	elif ang >= -112.5 and ang < -67.5: compass = "hacia el Norte"
	elif ang >= -67.5 and ang < -22.5: compass = "hacia el Noreste"
	var sample_pt: Vector2 = origin + dir * 130.0
	var b_info: Dictionary = _get_building_at_pos(sample_pt)
	var b_title: String = str(b_info.get("title", ""))
	if b_title != "":
		return "%s (rumbo a %s)" % [compass, b_title]
	return compass

func _build_investigation_case_dict(victim: VillageNPC, crime_pos: Vector2, weapon_used: String, discoverer_name: String, max_interviews_cap: int, is_royal: bool, m_id: String = "", embargo_days: int = 0) -> Dictionary:
	return VillageJustice._build_investigation_case_dict(self, victim, crime_pos, weapon_used, discoverer_name, max_interviews_cap, is_royal, m_id, embargo_days)

func start_sheriff_investigation(victim: VillageNPC, death_pos: Vector2, weapon_name: String, discoverer_name: String, _death_mins: int = 0) -> void:
	VillageJustice.start_sheriff_investigation(self, victim, death_pos, weapon_name, discoverer_name, _death_mins)

func on_traveling_merchant_murdered(merchant: VillageNPC, cause_text: String = "") -> void:
	VillageJustice.on_traveling_merchant_murdered(self, merchant, cause_text)

func _get_investigation_crime_pos() -> Vector2:
	return VillageJustice._get_investigation_crime_pos(self)

func _notify_inquisitor_of_police_crime(clue_text: String, suspicion_boost: int) -> void:
	VillageJustice._notify_inquisitor_of_police_crime(self, clue_text, suspicion_boost)

func _spawn_royal_investigator() -> void:
	VillageJustice._spawn_royal_investigator(self)

func _advance_royal_investigation_day(_new_day: int) -> void:
	VillageJustice._advance_royal_investigation_day(self, _new_day)

func update_royal_investigator_ai(inv_npc: VillageNPC, delta: float) -> void:
	VillageJustice.update_royal_investigator_ai(self, inv_npc, delta)

func update_sheriff_investigator_ai(sheriff: VillageNPC, delta: float) -> bool:
	return VillageJustice.update_sheriff_investigator_ai(self, sheriff, delta)

func _process_inquisitor_field_recon(inv_npc: VillageNPC, delta: float, done_cnt: int, max_cnt: int, days_inv: int) -> void:
	VillageJustice._process_inquisitor_field_recon(self, inv_npc, delta, done_cnt, max_cnt, days_inv)

func _cross_check_morgue_and_police_records(inv_npc: VillageNPC, suspects: Dictionary, clues: Array) -> void:
	VillageJustice._cross_check_morgue_and_police_records(self, inv_npc, suspects, clues)

func _inspect_crime_scene_and_footprints(inv_npc: VillageNPC, case_dict: Dictionary) -> void:
	VillageJustice._inspect_crime_scene_and_footprints(self, inv_npc, case_dict)

func _pick_next_neighbor_to_keep_chain_alive(inv_npc: VillageNPC, case_dict: Dictionary) -> String:
	return VillageJustice._pick_next_neighbor_to_keep_chain_alive(self, inv_npc, case_dict)

func _process_case_chain_interviews_step(inv_npc: VillageNPC, delta: float, case_dict: Dictionary, is_royal: bool) -> void:
	VillageJustice._process_case_chain_interviews_step(self, inv_npc, delta, case_dict, is_royal)

func _evaluate_npc_interview(inv_npc: VillageNPC, witness: VillageNPC, suspects: Dictionary, clues: Array, case_dict: Dictionary = {}) -> void:
	VillageJustice._evaluate_npc_interview(self, inv_npc, witness, suspects, clues, case_dict)

func _evaluate_player_inspection(inv_npc: VillageNPC, player: Node2D, suspects: Dictionary, clues: Array, is_initial_interview: bool = false, case_dict: Dictionary = {}) -> void:
	VillageJustice._evaluate_player_inspection(self, inv_npc, player, suspects, clues, is_initial_interview, case_dict)

func resolve_player_interrogation_outcome(inv_npc: VillageNPC, player: Node2D, outcome_mode: String, correct_steps: int, penalty_acc: int) -> void:
	VillageJustice.resolve_player_interrogation_outcome(self, inv_npc, player, outcome_mode, correct_steps, penalty_acc)

func _conclude_sheriff_investigation_verdict(sheriff: VillageNPC) -> void:
	VillageJustice._conclude_sheriff_investigation_verdict(self, sheriff)

func _check_and_start_next_morgue_sheriff_case() -> void:
	VillageJustice._check_and_start_next_morgue_sheriff_case(self)

func resolve_public_trial_intervention(inv_npc: VillageNPC, player: Node2D, mode: String) -> void:
	VillageJustice.resolve_public_trial_intervention(self, inv_npc, player, mode)

func _conclude_royal_investigation_with_mandatory_verdict(inv_npc: VillageNPC) -> void:
	VillageJustice._conclude_royal_investigation_with_mandatory_verdict(self, inv_npc)

func get_royal_investigator_status_text() -> String:
	return VillageJustice.get_royal_investigator_status_text(self)

func get_royal_investigation_dialogue_summary() -> String:
	return VillageJustice.get_royal_investigation_dialogue_summary(self)

func get_royal_investigation_detailed_suspects_text() -> String:
	return VillageJustice.get_royal_investigation_detailed_suspects_text(self)

func deploy_steel_bear_trap(pos: Vector2, _player: Node = null) -> void:
	if not is_instance_valid(entities_root):
		return
	var trap_root := Node2D.new()
	trap_root.name = "DeployedBearTrap_%d" % _deployed_bear_traps.size()
	trap_root.global_position = pos
	trap_root.z_index = -1
	trap_root.add_to_group("player_trap")
	entities_root.add_child(trap_root)

	var spr := Sprite2D.new()
	spr.texture = _load_tex("res://assests/items/icons/steel_bear_trap.png")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(0.95, 0.95)
	trap_root.add_child(spr)

	_deployed_bear_traps.append({
		"node": trap_root,
		"pos": pos,
		"arm_delay": 0.45
	})

func _update_deployed_bear_traps(delta: float, player: Node2D) -> void:
	for i in range(_deployed_bear_traps.size() - 1, -1, -1):
		var t_entry: Dictionary = _deployed_bear_traps[i]
		var t_node: Node2D = t_entry.get("node") as Node2D
		if not is_instance_valid(t_node):
			_deployed_bear_traps.remove_at(i)
			continue
		var arm_d: float = float(t_entry.get("arm_delay", 0.0))
		if arm_d > 0.0:
			t_entry["arm_delay"] = maxf(0.0, arm_d - delta)
			continue
		var t_pos: Vector2 = t_node.global_position
		var triggered_target: Node2D = null

		# 1. ¿Un animal salvaje pisó el cepo?
		for w in get_tree().get_nodes_in_group("wild_animals"):
			if w is WildAnimal:
				var wa := w as WildAnimal
				if wa.visible and not (wa.state in [WildAnimal.AnimalState.CARCASS, WildAnimal.AnimalState.BUTCHERED, WildAnimal.AnimalState.IN_BURROW]):
					if wa.global_position.distance_squared_to(t_pos) <= 16.0 * 16.0:
						triggered_target = wa
						break

		# 2. ¿Un enemigo de bosque o NPC hostil pisó el cepo?
		if triggered_target == null:
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Node2D and e != player:
					var en := e as Node2D
					if en.visible and en.get("is_dead") != true and en.get("is_dead_flag") != true and en.get("is_downed") != true and en.global_position.distance_squared_to(t_pos) <= 16.0 * 16.0:
						triggered_target = en
						break

		if triggered_target != null and triggered_target.has_method("take_damage"):
			var dmg := DamageData.new()
			dmg.amount = 35.0
			dmg.type = CombatConstants.DamageType.CUT
			dmg.bleed_buildup = 85.0
			dmg.stun_buildup = 100.0
			dmg.source = t_node
			triggered_target.call("take_damage", dmg)
			if "last_hit_weapon_name" in triggered_target:
				triggered_target.set("last_hit_weapon_name", "Cepo de Acero")
			if triggered_target.has_method("_spawn_floating_text"):
				triggered_target.call("_spawn_floating_text", "🪤💥 ¡ATRAPADO EN CEPO DE ACERO! (-35 HP, Stun)", Color.ORANGE_RED, -40.0)
			t_node.queue_free()
			_deployed_bear_traps.remove_at(i)
