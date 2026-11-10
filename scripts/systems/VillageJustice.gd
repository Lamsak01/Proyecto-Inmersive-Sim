@tool
extends RefCounted
const _AN_SITIOS = preload("res://mapa/anclas.gd") # plan de sitios: zonas fijas siguen a lo movido

## Justicia: investigaciones del Comisario y del Inquisidor Real, interrogatorios, veredictos y juicio público.
## Extraído de VillageManager.gd: cada función recibe al VillageManager como primer parámetro (`vm`).
## VillageManager mantiene llamadas finas con los mismos nombres y conserva el estado de los casos.

# M1: Móvil social. Suma algo de sospecha, pero nunca decide un culpable por sí solo.
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageQuests = preload("res://scripts/systems/VillageQuests.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const GossipMemory = preload("res://scripts/systems/GossipMemory.gd")
const VillageDesires = preload("res://scripts/systems/VillageDesires.gd")

const MOTIVE_PUBLIC_PTS: int = 10 # Enemistad larga o peleas conocidas por el pueblo
const MOTIVE_RUMOR_PTS: int = 8 # Rumor que cuenta un testigo en el interrogatorio
const MOTIVE_ENMITY_REL: int = -30
const MOTIVE_EVENT_TYPES: Array[String] = ["fight", "feud", "breakup", "player_slander", "npc_slander"]

static func _social_key(v: VillageNPC) -> String:
	if v == null:
		return ""
	return str(v.person_profile.person_id) if v.person_profile != null and str(v.person_profile.person_id) != "" else v.npc_id

static func _set_motive(entry: Dictionary, pts: int, text: String) -> bool:
	if bool(entry.get("motive_known", false)):
		return false
	entry["motive_known"] = true
	entry["motive_pts"] = pts
	entry["motive_note"] = text
	entry["score"] = int(entry.get("score", 10)) + pts
	return true

## Al abrir el caso: enemistades largas o peleas con la víctima, y calumnias del jugador que ya conoce medio pueblo.
static func _apply_public_motives(vm: VillageManager, victim: VillageNPC, suspects: Dictionary, all_living: Array[VillageNPC], clues: Array) -> void:
	if victim == null:
		return
	var vkey: String = _social_key(victim)
	var sd = vm.social_director
	var min_days: int = int(sd.dials.get("live_fight_min_enmity_days", 10)) if sd != null else 10
	for v in all_living:
		if not suspects.has(v.npc_name):
			continue
		var pe: Dictionary = sd.pair_metrics.get(sd.make_pair_key(vkey, _social_key(v)), {}) if sd != null else {}
		var fights: int = int(pe.get("fights_count", 0))
		var rel: int = victim.get_relationship_with_npc(v.npc_name)
		if fights <= 0 and not (rel <= MOTIVE_ENMITY_REL and int(pe.get("enmity_days", 0)) >= min_days):
			continue
		var txt: String = "Vieja enemistad con la víctima" + ((" (%d pelea%s)" % [fights, "" if fights == 1 else "s"]) if fights > 0 else "")
		if _set_motive(suspects[v.npc_name], MOTIVE_PUBLIC_PTS, txt):
			clues.append("Móvil: %s tenía una vieja enemistad con %s%s (+%d%% sospecha)." % [v.npc_name, victim.npc_name, (" y llegaron a pelearse %d vez/veces" % fights) if fights > 0 else "", MOTIVE_PUBLIC_PTS])
	if suspects.has("Jugador"):
		for ev in vm.social_event_log:
			if str(ev.get("type", "")) == "player_slander" and str(ev.get("target_id", "")) == vkey and (ev.get("known_by", {}) as Dictionary).size() >= vm.NEWS_MIN_KNOWERS:
				if _set_motive(suspects["Jugador"], MOTIVE_PUBLIC_PTS, "Habló mal de la víctima por el pueblo"):
					clues.append("Móvil: medio pueblo sabe que el Forastero iba hablando mal de %s (+%d%% sospecha)." % [victim.npc_name, MOTIVE_PUBLIC_PTS])
				break

## En el interrogatorio: el testigo cuenta lo que sabe de peleas, rupturas o calumnias relacionadas con la víctima.
static func _reveal_motives_known_by_witness(vm: VillageManager, witness: VillageNPC, suspects: Dictionary, clues: Array, case_dict: Dictionary) -> void:
	var vkey: String = str(case_dict.get("victim_key", ""))
	if vkey == "":
		return
	var wkey: String = _social_key(witness)
	for ev in vm.social_event_log:
		var t: String = str(ev.get("type", ""))
		if not (t in MOTIVE_EVENT_TYPES) or not GossipMemory.knows(ev, wkey): # R1: si lo olvidó, no lo cuenta
			continue
		if t == "npc_slander" and str(ev.get("target_id", "")) != vkey:
			continue
		var other_name: String = ""
		var other_key: String = ""
		if t == "player_slander":
			if str(ev.get("target_id", "")) == vkey:
				other_name = "Jugador"
		elif str(ev.get("actor_id", "")) == vkey:
			other_name = str(ev.get("target_name", ""))
			other_key = str(ev.get("target_id", ""))
		elif str(ev.get("target_id", "")) == vkey:
			other_name = str(ev.get("actor_name", ""))
			other_key = str(ev.get("actor_id", ""))
		if other_name == "" or other_key == wkey or other_name == witness.npc_name or not suspects.has(other_name):
			continue
		var label: String = "el Forastero" if other_name == "Jugador" else other_name
		var what: String = {"fight": "se peleó con", "feud": "estaba enemistado con", "breakup": "rompió con", "player_slander": "iba hablando mal de", "npc_slander": "iba hablando mal de"}.get(t, "tuvo un problema con")
		if _set_motive(suspects[other_name], MOTIVE_RUMOR_PTS, "Según %s, %s la víctima" % [witness.npc_name, what]):
			clues.append("Móvil: %s contó que %s %s %s el Día %d (+%d%% sospecha)." % [witness.npc_name, label, what, str(case_dict.get("victim_name", "la víctima")), int(ev.get("day", 0)), MOTIVE_RUMOR_PTS])

static func _build_investigation_case_dict(vm: VillageManager, victim: VillageNPC, crime_pos: Vector2, weapon_used: String, discoverer_name: String, max_interviews_cap: int, is_royal: bool, m_id: String = "", embargo_days: int = 0) -> Dictionary:
	var crime_hour: int = victim.death_hour if (victim != null and "death_hour" in victim and victim.death_hour >= 0) else (WorldClock.current_hour if WorldClock else 12)
	var crime_min: int = victim.death_minute if (victim != null and "death_minute" in victim and victim.death_minute >= 0) else (WorldClock.current_minute if WorldClock else 0)
	var crime_day: int = victim.death_day if (victim != null and "death_day" in victim and victim.death_day >= 1) else (WorldClock.current_day if WorldClock else 1)
	var crime_total_mins: int = crime_day * 1440 + crime_hour * 60 + crime_min
	var direct_murder_witness: String = str(victim.murder_witness_name) if (victim and "murder_witness_name" in victim) else ""

	var suspects_dict: Dictionary = {}
	var all_living: Array[VillageNPC] = []
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v != victim and not v.is_dead and v.trade_role != VillageNPC.TradeRole.ROYAL_INVESTIGATOR:
				all_living.append(v)

	var player := vm.get_tree().get_first_node_in_group("player") as Node2D
	var player_dist_at_crime: float = player.global_position.distance_to(crime_pos) if player else 999.0
	var player_in_stealth: bool = player != null and player.has_method("is_stealthing") and bool(player.call("is_stealthing"))

	for v in all_living:
		var alibi_partner: String = ""
		var seen_list: Array[Dictionary] = v.get_seen_entities_near_crime(crime_pos, crime_total_mins, 280.0, 240)
		var seen_names_set: Dictionary = {}
		for se in seen_list:
			seen_names_set[str(se.get("name", ""))] = true

		for other in all_living:
			if other == v or other.is_downed or other.is_sleeping:
				continue
			var d_other: float = v.global_position.distance_to(other.global_position)
			if alibi_partner == "" and d_other <= 115.0 and vm.has_line_of_sight(v.global_position, other.global_position):
				alibi_partner = other.npc_name
			if not seen_names_set.has(other.npc_name) and d_other <= 210.0 and other.global_position.distance_to(crime_pos) <= 280.0 and vm.has_line_of_sight(v.global_position, other.global_position):
				seen_names_set[other.npc_name] = true
				seen_list.append({
					"name": other.npc_name,
					"is_player": false,
					"pos_x": other.global_position.x,
					"pos_y": other.global_position.y,
					"dist_to_crime": other.global_position.distance_to(crime_pos),
					"bloodstained": other.is_bloodstained(),
					"wounded": other.health_comp != null and other.health_comp.has_fresh_combat_wounds_or_makeshift()
				})

		var dist_to_crime: float = v.global_position.distance_to(crime_pos)
		var saw_player_near: bool = (direct_murder_witness != "" and v.npc_name == direct_murder_witness) or seen_names_set.has("Jugador")
		if not saw_player_near and player != null and not v.is_sleeping and not v.is_downed and v.sedated_timer <= 0.0:
			var cloak_m: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
			var detect_r: float = (85.0 if player_in_stealth else 210.0) * cloak_m
			if v.global_position.distance_to(player.global_position) <= detect_r and player_dist_at_crime <= 240.0 * cloak_m:
				if vm.has_line_of_sight(v.global_position, player.global_position):
					saw_player_near = true
		if saw_player_near and not seen_names_set.has("Jugador") and player != null:
			var p_hc: HealthComponent = player.get_node_or_null("HealthComponent")
			seen_list.push_front({
				"name": "Jugador",
				"is_player": true,
				"pos_x": player.global_position.x,
				"pos_y": player.global_position.y,
				"dist_to_crime": player_dist_at_crime,
				"bloodstained": player.has_method("is_bloodstained") and bool(player.call("is_bloodstained")),
				"wounded": p_hc != null and p_hc.has_fresh_combat_wounds_or_makeshift()
			})

		suspects_dict[v.npc_name] = {
			"name": v.npc_name, "is_player": false, "score": 10, "known_dist": -1.0,
			"mem_pos_x": v.global_position.x, "mem_pos_y": v.global_position.y,
			"mem_alibi_partner": alibi_partner, "mem_dist_to_crime": dist_to_crime,
			"mem_saw_player_near": saw_player_near, "mem_player_dist": player_dist_at_crime if saw_player_near else -1.0,
			"mem_seen_list": seen_list,
			"is_vagrant": (v.trade_role == VillageNPC.TradeRole.UNEMPLOYED or v.is_vagrant_camper),
			"interviewed": false, "status_note": "Paradero desconocido hasta interrogar"
		}

	var player_init_score: int = 10
	var player_known_dist: float = -1.0
	var p_note: String = "Paradero aún no situado por ningún testigo"
	if direct_murder_witness != "":
		player_init_score += 45
		player_known_dist = player_dist_at_crime
		p_note = "Denunciado por testigo presencial (%s)" % direct_murder_witness
	if vm.player_in_jail or vm.player_being_escorted_to_jail or vm.wanted_level > 0 or vm.player_murder_warrants_count > 0:
		player_init_score += 35
		p_note = "Con antecedentes/búsqueda en Comisaría"

	suspects_dict["Jugador"] = {
		"name": "El Forastero (Jugador)", "is_player": true, "score": player_init_score,
		"known_dist": player_known_dist,
		"mem_pos_x": player.global_position.x if player else 0.0,
		"mem_pos_y": player.global_position.y if player else 0.0,
		"interviewed": false, "status_note": p_note
	}

	# Eslabón #1 de la cadena: quien descubrió/reportó el cuerpo (sin visión omnisciente del pueblo)
	var first_witness: String = discoverer_name
	if first_witness == "" or (first_witness != "Jugador" and not suspects_dict.has(first_witness)):
		if direct_murder_witness != "" and suspects_dict.has(direct_murder_witness):
			first_witness = direct_murder_witness
		else:
			# Si aún nadie reportó el cuerpo (p. ej. muerte recién ocurrida en la plaza), el primer interrogado es quien lo descubre visualmente o el Médico/Guardia
			var best_finder: String = ""
			var best_d2: float = 99999999.0
			for v in all_living:
				if v.is_sleeping or v.is_downed or v.trade_role == VillageNPC.TradeRole.SHERIFF:
					continue
				var d2: float = v.global_position.distance_squared_to(crime_pos)
				if d2 < best_d2 and (vm.has_line_of_sight(v.global_position, crime_pos) or d2 <= 220.0 * 220.0):
					best_d2 = d2
					best_finder = v.npc_name
			if best_finder == "" and not all_living.is_empty():
				best_finder = all_living[0].npc_name
			first_witness = best_finder

	var start_queue: Array[String] = []
	if first_witness != "":
		start_queue.append(first_witness)
	if direct_murder_witness != "" and not ("Jugador" in start_queue):
		start_queue.append("Jugador")

	var total_cap: int = mini(max_interviews_cap, all_living.size()) if not is_royal else all_living.size()
	var max_inv_days: int = mini(18, maxi(3, embargo_days - 2)) if is_royal else 3
	var init_daily_quota: int = 6 if is_royal else 5

	var v_label: String = victim.npc_name if victim else "Aldeano"
	var initial_clues: Array[String] = [
		"Cadáver de %s hallado en (%d, %d) a las %02d:00 del Día %d (Reportado por: %s)." % [v_label, int(crime_pos.x), int(crime_pos.y), crime_hour, crime_day, first_witness if first_witness != "" else "Guardia"],
		"Herida forense compatible con: %s." % weapon_used,
		"Método deductivo en cadena: empezar interrogando a quien reportó el hallazgo (%s) y seguir la pista de a quién vio cerca." % (first_witness if first_witness != "" else "Testigo #1")
	]
	if direct_murder_witness != "":
		initial_clues.append("Parte Policial: %s denunció al Forastero como autor presencial." % direct_murder_witness)
	# D5: si lo mató un vecino, no tiene coartada y deja rastro
	var npc_killer: String = VillageDesires.killer_of(vm, v_label)
	if npc_killer != "" and suspects_dict.has(npc_killer):
		var ks: Dictionary = suspects_dict[npc_killer]
		ks["score"] = int(ks.get("score", 10)) + 30
		ks["mem_alibi_partner"] = ""
		ks["status_note"] = "Nadie sabe dónde estuvo aquella noche"
		initial_clues.append("Nadie recuerda haber visto a %s aquella noche, y se le vio salir con prisa de casa." % npc_killer)
	_apply_public_motives(vm, victim, suspects_dict, all_living, initial_clues)
	VillageQuests.on_murder_case_opened(vm, victim)
	VillageChronicle.add(vm, "death_found", "Hallaron el cuerpo sin vida de %s" % victim.npc_name, true)

	var case_dict: Dictionary = {
		"active": true, "is_royal": is_royal, "victim_name": v_label, "victim_id": m_id, "victim_key": _social_key(victim), "embargo_days": embargo_days,
		"crime_pos_x": crime_pos.x, "crime_pos_y": crime_pos.y, "crime_hour": crime_hour, "crime_day": crime_day,
		"crime_total_mins": crime_total_mins, "reporter_name": first_witness,
		"flee_dir_x": 0.0, "flee_dir_y": 0.0, "flee_compass": "",
		"days_investigating": 1, "max_days": max_inv_days, "daily_quota": init_daily_quota, "interviews_done_today": 0,
		"recon_spot_idx": 0, "weapon_used": weapon_used, "morgue_checked": false, "stage": "CRIME_SCENE",
		"stage_timer": 0.0, "routine_timer": 0.0, "interviews_done": 0, "max_interviews": maxi(1, total_cap),
		"interview_queue": start_queue, "current_interview_target": "", "scapegoat_key": "",
		"clues_log": initial_clues, "suspects": suspects_dict, "verdict_target": "", "verdict_reason": ""
	}
	vm.VillageForensics.apply_to_case(vm, victim, case_dict) # P2: pistas plantadas, cómplices, autopsia y seguro de vida
	return case_dict

static func start_sheriff_investigation(vm: VillageManager, victim: VillageNPC, death_pos: Vector2, weapon_name: String, discoverer_name: String, _death_mins: int = 0) -> void:
	# J2: hambre, animales o enfermedad no son un crimen: se ve a simple vista y no se abre caso
	if victim != null and VillageNPC.is_natural_death_cause(weapon_name) and not victim.last_hit_by_player:
		var first_time: bool = not victim.has_meta("natural_death_noted")
		if first_time:
			victim.set_meta("natural_death_noted", true)
			VillageChronicle.add(vm, "death_found", "Hallaron el cuerpo sin vida de %s: %s" % [victim.npc_name, VillageNPC.natural_death_text(weapon_name)], true)
		# Siempre se marca resuelto (el registro de la morgue puede llegar después del hallazgo) para que se le entierre
		if first_time:
			vm._mark_morgue_case_resolved(victim.npc_name, "Sin crimen: %s" % VillageNPC.natural_death_text(weapon_name))
			_check_and_start_next_morgue_sheriff_case(vm)
		else:
			_resolve_quietly(vm, victim.npc_name, weapon_name)
		return
	if bool(vm.active_sheriff_investigation.get("active", false)):
		return
	vm.active_sheriff_investigation = _build_investigation_case_dict(vm, victim, death_pos, weapon_name, discoverer_name, 5, false)
	var rep_txt: String = str(vm.active_sheriff_investigation.get("reporter_name", "quien halló el cuerpo"))
	vm._hint_player("🕵️‍♂️🚓 El Alguacil mayor Vane abrió investigación por el homicidio de %s: inspeccionará huellas en la escena e interrogará primero a %s (cadena de hasta 5 testigos)." % [victim.npc_name, rep_txt])

## Se ejecuta cuando REPORTAN el cadáver de `Maese Casimir` o de `Valeria la Tratante`:
static func on_traveling_merchant_murdered(vm: VillageManager, merchant: VillageNPC, cause_text: String = "") -> void:
	if merchant == null:
		return
	if bool(vm.active_royal_investigation.get("active", false)) and str(vm.active_royal_investigation.get("victim_name", "")) == merchant.npc_name:
		return
	var m_id: String = merchant.merchant_id if merchant.merchant_id != "" else "casimir"
	var embargo_days: int = int(vm.merchant_suspension_days.get(m_id, 0))
	if embargo_days <= 0:
		embargo_days = 7 if (m_id in ["high_pass", "river_port", "sun_plain"]) else randi_range(20, 30)
		vm.merchant_suspension_days[m_id] = embargo_days

	var crime_pos: Vector2 = merchant.death_world_pos if ("death_world_pos" in merchant and merchant.death_world_pos != Vector2.ZERO) else merchant.global_position
	var weapon_used: String = merchant.last_hit_weapon_name if merchant.last_hit_weapon_name != "" else cause_text
	vm.spawn_blood_puddle(crime_pos, merchant.npc_name)

	var reporter: String = merchant.corpse_discovered_by if ("corpse_discovered_by" in merchant and merchant.corpse_discovered_by != "") else ""
	vm.active_royal_investigation = _build_investigation_case_dict(vm, merchant, crime_pos, weapon_used, reporter, 18, true, m_id, embargo_days)

	_spawn_royal_investigator(vm)
	var rep_label: String = str(vm.active_royal_investigation.get("reporter_name", "el primer testigo"))
	vm._hint_player("👑🕵️‍♂️ ¡CADÁVER REAL REPORTADO! Se ha dado aviso de la muerte de %s (Ruta suspendida %d días). El Inquisidor Real Alistair llega al valle, inspeccionará el charco de sangre e interrogará en cadena empezando por %s." % [merchant.npc_name, embargo_days, rep_label])

static func _get_investigation_crime_pos(vm: VillageManager) -> Vector2:
	if vm.active_royal_investigation.has("crime_pos_x") and vm.active_royal_investigation.has("crime_pos_y"):
		return Vector2(float(vm.active_royal_investigation["crime_pos_x"]), float(vm.active_royal_investigation["crime_pos_y"]))
	var raw_cp: Variant = vm.active_royal_investigation.get("crime_pos", Vector2(465, 44))
	if typeof(raw_cp) == TYPE_VECTOR2:
		return raw_cp as Vector2
	return Vector2(465, 44)

## Comunica en tiempo real cualquier arresto, fianza o ficha forense de la Comisaría/Morgue al expediente del Inquisidor Real Alistair
static func _notify_inquisitor_of_police_crime(vm: VillageManager, clue_text: String, suspicion_boost: int) -> void:
	if vm.active_royal_investigation.is_empty() or not bool(vm.active_royal_investigation.get("active", false)):
		return
	var suspects: Dictionary = vm.active_royal_investigation.get("suspects", {})
	var clues: Array = vm.active_royal_investigation.get("clues_log", [])
	if suspects.has("Jugador"):
		var p_entry: Dictionary = suspects["Jugador"]
		p_entry["score"] = int(p_entry.get("score", 16)) + suspicion_boost
		p_entry["status_note"] = "Fichado/Arrestado por el Comisario Vane"
	if not (clue_text in clues):
		clues.append(clue_text)

static func _spawn_royal_investigator(vm: VillageManager) -> void:
	if is_instance_valid(vm._royal_investigator_npc) and not vm._royal_investigator_npc.is_dead:
		vm._royal_investigator_npc.is_hostile = false
		vm._royal_investigator_npc.is_sleeping = false
		vm._royal_investigator_npc.remove_from_group("enemies")
		if "_police_alerted_timer" in vm._royal_investigator_npc:
			vm._royal_investigator_npc._police_alerted_timer = 0.0
		return
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and (n as VillageNPC).trade_role == VillageNPC.TradeRole.ROYAL_INVESTIGATOR and (n as VillageNPC).is_dead:
			if not str(n.name).begins_with("NPC_Royal_Investigator_Corpse_"):
				n.name = "NPC_Royal_Investigator_Corpse_" + str(n.get_instance_id())
	vm._royal_investigator_npc = null
	var inv_npc := VillageNPC.new()
	inv_npc.name = "NPC_Royal_Investigator_Alistair"
	inv_npc.npc_name = "Inquisidor Real Alistair"
	inv_npc.npc_role = "Alto Investigador de la Corona"
	inv_npc.trade_role = VillageNPC.TradeRole.ROYAL_INVESTIGATOR
	inv_npc.days_in_role = 7
	inv_npc.tavern_social_pos = vm._tavern_social_pos
	vm.entities_root.add_child(inv_npc)
	# Alistair duerme en su propia cama de huéspedes en la Posada (`Vector2(400, -252)`), nunca en la cama del Comisario Vane
	inv_npc.setup_npc(vm._load_tex("res://assests/world/village/npcs_64/sprite_alistair.png"), Vector2(465, 44), Vector2(400, -252), {}, vm._tavern_social_pos, "family_police", "Inquisición Real de la Corona")
	inv_npc.global_position = vm._get_map_edge_arrival_pos(1)
	vm._royal_investigator_npc = inv_npc

## Avanza día a día la investigación del Inquisidor Real Alistair (`_on_day_passed`):
## - NO realiza interrogatorios telepáticos en segundo plano al cambiar de día ni al dormir en la celda:
##   Alistair siempre camina físicamente hacia cada habitante durante el día (interrogando al menos a 5-6+ personas por día).
## - Garantiza matemáticamente que el caso quede resuelto antes de que regrese el mercader (`max_days <= 18`).
static func _advance_royal_investigation_day(vm: VillageManager, _new_day: int) -> void:
	if vm.active_royal_investigation.is_empty() or not bool(vm.active_royal_investigation.get("active", false)):
		return
	var stg: String = str(vm.active_royal_investigation.get("stage", "CRIME_SCENE"))
	# Si el Inquisidor Real fue abatido/asesinado mientras la investigación o persecución seguía activa, la Corona envía un nuevo Inquisidor al amanecer
	if stg != "DEPARTING" and (not is_instance_valid(vm._royal_investigator_npc) or vm._royal_investigator_npc.is_dead):
		_spawn_royal_investigator(vm)
		if stg == "HUNTING_PLAYER" and is_instance_valid(vm._royal_investigator_npc):
			vm._royal_investigator_npc.is_hostile = true
			if not vm._royal_investigator_npc.is_in_group("enemies"):
				vm._royal_investigator_npc.add_to_group("enemies")
	if stg in ["DEPARTING", "HUNTING_SCAPEGOAT", "PUBLIC_TRIAL_PLAZA", "HUNTING_PLAYER"]:
		return

	var suspects: Dictionary = vm.active_royal_investigation.get("suspects", {})
	var clues: Array = vm.active_royal_investigation.get("clues_log", [])
	var queue: Array = vm.active_royal_investigation.get("interview_queue", [])

	var days_inv: int = int(vm.active_royal_investigation.get("days_investigating", 1)) + 1
	var max_days: int = int(vm.active_royal_investigation.get("max_days", 18))
	vm.active_royal_investigation["days_investigating"] = days_inv
	vm.active_royal_investigation["interviews_done_today"] = 0

	# Recalcular la cuota diaria (mínimo 6 habitantes por día, o más si se acerca el día límite)
	var rem_days: int = maxi(1, (max_days - 1) - days_inv)
	var rem_to_interview: int = queue.size()
	var calc_quota: int = int(ceil(float(rem_to_interview) / float(rem_days)))
	vm.active_royal_investigation["daily_quota"] = maxi(6, calc_quota)

	# Si el Inquisidor Real fue abatido/asesinado mientras la investigación seguía activa, la Corona envía un nuevo Inquisidor al amanecer
	if not is_instance_valid(vm._royal_investigator_npc) or vm._royal_investigator_npc.is_dead:
		_spawn_royal_investigator(vm)

	# Solo si se alcanza el Día Límite (`max_days`, <= 18 días) se fuerza el cierre inmediato antes del regreso del mercader
	if days_inv >= max_days and stg in ["CRIME_SCENE", "MORGUE", "INITIAL_PLAYER_INTERVIEW", "INTERVIEWS", "PLAYER_CHECK"]:
		if not is_instance_valid(vm._royal_investigator_npc) or vm._royal_investigator_npc.is_dead:
			return
		while not queue.is_empty():
			var last_n: String = str(queue.pop_front())
			vm.active_royal_investigation["interviews_done"] = int(vm.active_royal_investigation.get("interviews_done", 0)) + 1
			var tv: VillageNPC = vm._find_npc_by_name(last_n)
			if tv != null and not tv.is_dead:
				_evaluate_npc_interview(vm, vm._royal_investigator_npc, tv, suspects, clues)
		var player := vm.get_tree().get_first_node_in_group("player") as Node2D
		if player != null:
			_evaluate_player_inspection(vm, vm._royal_investigator_npc, player, suspects, clues, false)
		_conclude_royal_investigation_with_mandatory_verdict(vm, vm._royal_investigator_npc)

## IA deductiva multidiaria paso a paso del Inquisidor Real Alistair:
## 1. Inspecciona físicamente la escena del crimen (`CRIME_SCENE`).
## 2. Examina la autopsia en la Morgue (`MORGUE`) y cruza datos con los archivos policiales del Comisario Vane.
## 3. Interroga inicialmente al Jugador (`INITIAL_PLAYER_INTERVIEW`) — yendo directamente a los barrotes de la celda si está preso.
## 4. Interroga físicamente a TODOS los aldeanos del pueblo (`INTERVIEWS`), deteniéndolos cara a cara (`hold_for_interview`),
##    a razón de 5-6+ interrogatorios por día, y pasa directo a la resolución apenas termina de interrogar a todos (sin esperas artificiales).
## 5. Inspección final al Jugador (`PLAYER_CHECK`), VEREDICTO OBLIGATORIO (`VERDICT`) y EJECUCIÓN PRESENCIAL (`HUNTING_SCAPEGOAT` / `HUNTING_PLAYER`).
static func update_royal_investigator_ai(vm: VillageManager, inv_npc: VillageNPC, delta: float) -> void:
	if inv_npc == null or inv_npc.is_dead or inv_npc.is_downed:
		return
	if vm.active_royal_investigation.is_empty() or not bool(vm.active_royal_investigation.get("active", false)):
		inv_npc.is_sleeping = false
		var exit_pt := Vector2(1000, 48)
		inv_npc._move_towards_point(exit_pt, 94.0, delta)
		if inv_npc.global_position.distance_to(exit_pt) <= 18.0:
			if vm._royal_investigator_npc == inv_npc:
				vm._royal_investigator_npc = null
			inv_npc.queue_free()
		return

	var stage: String = str(vm.active_royal_investigation.get("stage", "CRIME_SCENE"))
	var s_timer: float = float(vm.active_royal_investigation.get("stage_timer", 0.0))
	var r_timer: float = float(vm.active_royal_investigation.get("routine_timer", 0.0))
	var suspects: Dictionary = vm.active_royal_investigation.get("suspects", {})
	var clues: Array = vm.active_royal_investigation.get("clues_log", [])
	var h: int = WorldClock.current_hour if WorldClock else 12
	var days_inv: int = int(vm.active_royal_investigation.get("days_investigating", 1))
	var done_cnt: int = int(vm.active_royal_investigation.get("interviews_done", 0))
	var max_cnt: int = int(vm.active_royal_investigation.get("max_interviews", 18))

	# Si el jugador ya fue encarcelado tras haber sido declarado culpable (`HUNTING_PLAYER`), Alistair da el caso por cerrado y regresa a la Corte
	if stage == "HUNTING_PLAYER":
		if vm.player_in_jail or vm.player_being_escorted_to_jail:
			inv_npc.is_hostile = false
			inv_npc.remove_from_group("enemies")
			vm.active_royal_investigation["stage"] = "DEPARTING"
			inv_npc._spawn_floating_text("⚖️👑 ¡Caso resuelto ante la justicia real! Regreso a la Corte.", Color.GOLD, -44.0)
			return
		# Mantener la persecución activa hacia el jugador culpable para que nunca se quede congelado
		inv_npc.is_hostile = true
		inv_npc._police_alerted_timer = maxf(inv_npc._police_alerted_timer, 25.0)
		var p_hunt := vm.get_tree().get_first_node_in_group("player") as Node2D
		if p_hunt != null:
			inv_npc._last_seen_player_pos = p_hunt.global_position
			inv_npc._process_police_law_enforcement(delta, vm)
		return

	# Rutina diaria para fases de investigación (`CRIME_SCENE`, `MORGUE`, `INITIAL_PLAYER_INTERVIEW`, `INTERVIEWS`):
	if stage in ["CRIME_SCENE", "MORGUE", "INITIAL_PLAYER_INTERVIEW", "INTERVIEWS"]:
		# 1. Noche (22:00 a 06:00): Descansa en su propia cama de la Posada (`Vector2(400, -252)`), sin usar la cama del Comisario Vane
		if h >= 22 or h < 6:
			var bed_pt := Vector2(400, -252)
			if inv_npc.global_position.distance_to(bed_pt) > 12.0:
				inv_npc.is_sleeping = false
				inv_npc._move_towards_point(bed_pt, 78.0, delta)
			else:
				inv_npc.velocity = Vector2.ZERO
				inv_npc.is_sleeping = true
				inv_npc.need_energy = minf(100.0, inv_npc.need_energy + delta * 10.0)
			return

		inv_npc.is_sleeping = false

		# 2. Amanecer (06:00 a 07:00): Revisa brevemente el expediente con el Comisario Vane en la Comisaría (`Vector2(886, 126)`)
		if h >= 6 and h < 7 and not vm.player_in_jail:
			var desk_pt := Vector2(886, 126)
			if inv_npc.global_position.distance_to(desk_pt) > 18.0:
				inv_npc._move_towards_point(desk_pt, 82.0, delta)
			else:
				inv_npc.velocity = Vector2.ZERO
				inv_npc.trigger_action_animation(1.0)
				r_timer += delta
				vm.active_royal_investigation["routine_timer"] = r_timer
				if int(r_timer * 10.0) % 40 == 0:
					inv_npc._spawn_floating_text("📋🕯️ Día %d: Cotejando actas con el Alguacil mayor Vane (%d/%d interrogados)..." % [days_inv, done_cnt, max_cnt], Color(1.0, 0.88, 0.45), -36.0)
			return

		# 3. Noche temprana (20:00 a 22:00): Cena y vigila a los sospechosos en la Posada (`_tavern_social_pos`)
		if h >= 20 and h < 22 and stage == "INTERVIEWS":
			var tav_pt: Vector2 = vm._tavern_social_pos
			if inv_npc.global_position.distance_to(tav_pt) > 22.0:
				inv_npc._move_towards_point(tav_pt, 78.0, delta)
			else:
				inv_npc.velocity = Vector2.ZERO
				inv_npc.trigger_action_animation(1.0)
				inv_npc.need_hunger = minf(100.0, inv_npc.need_hunger + delta * 12.0)
				r_timer += delta
				vm.active_royal_investigation["routine_timer"] = r_timer
				if int(r_timer * 10.0) % 50 == 0:
					inv_npc._spawn_floating_text("🍷🕵️‍♂️ Vigilando sospechosos en la Posada (%d/%d interrogados)" % [done_cnt, max_cnt], Color.AQUA, -36.0)
			return

		# 4. Detección flagrante durante el día: si el jugador pasa a <= 56 px de Alistair con línea de visión llevando el Salvoconducto Real robado
		var p_near := vm.get_tree().get_first_node_in_group("player") as Node2D
		if p_near != null and inv_npc.global_position.distance_to(p_near.global_position) <= 56.0:
			var p_inv: SimpleInventory = p_near.get("inventory")
			if p_inv and p_inv.has_item("royal_safe_conduct", 1) and vm.has_line_of_sight(inv_npc.global_position, p_near.global_position):
				_evaluate_player_inspection(vm, inv_npc, p_near, suspects, clues, false)
				vm.active_royal_investigation["stage"] = "VERDICT"
				vm.active_royal_investigation["stage_timer"] = 0.0
				return

	match stage:
		"CRIME_SCENE":
			var c_pos: Vector2 = _get_investigation_crime_pos(vm)
			if inv_npc.global_position.distance_to(c_pos) > 24.0:
				inv_npc._stop_crafting_bar()
				inv_npc._move_towards_point(c_pos, 62.0, delta)
			else:
				inv_npc.velocity = Vector2.ZERO
				inv_npc.trigger_action_animation(1.0)
				s_timer += delta
				vm.active_royal_investigation["stage_timer"] = s_timer
				var rem_cs: int = maxi(1, int(ceil(12.0 - s_timer)))
				inv_npc._update_craft_bar_visual(clampf(s_timer / 12.0, 0.02, 1.0), "🔍 Examinando escena (%ds)" % rem_cs, Color(1.0, 0.84, 0.32, 0.95))
				if int(s_timer * 10.0) % 35 == 0:
					inv_npc._spawn_floating_text("🔍🩸 Analizando charco de sangre y dirección de huellas...", Color(1.0, 0.86, 0.38), -36.0)
				if s_timer >= 12.0:
					inv_npc._stop_crafting_bar()
					_inspect_crime_scene_and_footprints(vm, inv_npc, vm.active_royal_investigation)
					vm.active_royal_investigation["stage"] = "MORGUE"
					vm.active_royal_investigation["stage_timer"] = 0.0
		"MORGUE":
			var m_pos: Vector2 = vm.sitio(vm._morgue_table_positions[1])
			if inv_npc.global_position.distance_to(m_pos) > 26.0:
				inv_npc._stop_crafting_bar()
				inv_npc._move_towards_point(m_pos, 62.0, delta)
			else:
				inv_npc.velocity = Vector2.ZERO
				inv_npc.trigger_action_animation(1.0)
				s_timer += delta
				vm.active_royal_investigation["stage_timer"] = s_timer
				var rem_mg: int = maxi(1, int(ceil(10.0 - s_timer)))
				inv_npc._update_craft_bar_visual(clampf(s_timer / 10.0, 0.02, 1.0), "⚰️ Revisando autopsia (%ds)" % rem_mg, Color(0.45, 0.92, 0.95, 0.95))
				if s_timer >= 10.0:
					inv_npc._stop_crafting_bar()
					_cross_check_morgue_and_police_records(vm, inv_npc, suspects, clues)
					vm.active_royal_investigation["stage"] = "INTERVIEWS"
					vm.active_royal_investigation["stage_timer"] = 0.0
					var first_rep: String = str(vm.active_royal_investigation.get("reporter_name", "el primer testigo"))
					inv_npc._spawn_floating_text("⚰️📜 Autopsia verificada: interrogaré primero a %s y seguiré el hilo." % first_rep, Color.AQUA, -38.0)
		"INITIAL_PLAYER_INTERVIEW":
			vm.active_royal_investigation["stage"] = "INTERVIEWS"
			vm.active_royal_investigation["stage_timer"] = 0.0
		"INTERVIEWS":
			_process_case_chain_interviews_step(vm, inv_npc, delta, vm.active_royal_investigation, true)
		"DEEP_FORENSICS":
			vm.active_royal_investigation["stage"] = "PLAYER_CHECK"
			vm.active_royal_investigation["stage_timer"] = 0.0
		"PLAYER_CHECK":
			var p_susp: Dictionary = suspects.get("Jugador", {})
			var should_inspect_player: bool = (float(p_susp.get("known_dist", -1.0)) >= 0.0 or int(p_susp.get("score", 0)) >= 25 or vm.player_in_jail) and not bool(p_susp.get("interviewed", false))
			var player := vm.get_tree().get_first_node_in_group("player") as Node2D
			if player == null or not should_inspect_player:
				vm.active_royal_investigation["stage"] = "VERDICT"
				return
			var check_pt: Vector2 = Vector2(902, 144) if vm.player_in_jail else player.global_position
			var dist_chk: float = inv_npc.global_position.distance_to(check_pt)
			inv_npc._move_towards_point(check_pt, 98.0, delta)
			s_timer += delta
			vm.active_royal_investigation["stage_timer"] = s_timer
			if dist_chk <= 38.0:
				inv_npc.velocity = Vector2.ZERO
				inv_npc.trigger_action_animation(3.5)
				if not bool(vm.active_royal_investigation.get("player_dialogue_opened", false)):
					vm.active_royal_investigation["player_dialogue_opened"] = true
					inv_npc.start_interrogation_dialogue_with_player(player)
				if is_instance_valid(inv_npc._cached_dm) and inv_npc._cached_dm.has_method("is_active") and bool(inv_npc._cached_dm.call("is_active")):
					return
				_evaluate_player_inspection(vm, inv_npc, player, suspects, clues, false)
				vm.active_royal_investigation["stage"] = "VERDICT"
				vm.active_royal_investigation["stage_timer"] = 0.0
			elif s_timer >= 20.0:
				inv_npc.velocity = Vector2.ZERO
				vm.active_royal_investigation["stage"] = "VERDICT"
				vm.active_royal_investigation["stage_timer"] = 0.0
		"VERDICT":
			inv_npc.trigger_action_animation(4.5)
			_conclude_royal_investigation_with_mandatory_verdict(vm, inv_npc)
		"HUNTING_SCAPEGOAT":
			var sc_key: String = str(vm.active_royal_investigation.get("scapegoat_key", ""))
			var scapegoat: VillageNPC = vm._find_npc_by_name(sc_key)
			if scapegoat == null or scapegoat.is_dead:
				vm.active_royal_investigation["stage"] = "DEPARTING"
				vm.active_royal_investigation["stage_timer"] = 0.0
				return
			s_timer += delta
			vm.active_royal_investigation["stage_timer"] = s_timer
			if inv_npc.global_position.distance_to(scapegoat.global_position) <= 46.0:
				scapegoat.hold_for_interview(inv_npc, 1.0)
			inv_npc._move_towards_point(scapegoat.global_position, 104.0, delta)
			if inv_npc.global_position.distance_to(scapegoat.global_position) <= 32.0:
				inv_npc.velocity = Vector2.ZERO
				scapegoat.velocity = Vector2.ZERO
				scapegoat.is_sleeping = false
				inv_npc.trigger_action_animation(2.0)
				scapegoat._spawn_floating_text("⛓️😱 ¡No, por favor! ¡Soy inocente, me han incriminado!", Color.ORANGE_RED, -42.0)
				inv_npc._spawn_floating_text("⚖️⛓️ ¡%s, quedas bajo arresto real! ¡A la Plaza Central para tu Juicio Público!" % scapegoat.npc_name, Color.GOLD, -44.0)
				vm._hint_player("⚖️🔔 ¡JUICIO PÚBLICO EN LA PLAZA! El Inquisidor Real Alistair ha esposado a %s y lo lleva a la Plaza Central para leer su sentencia (Tienes 18s en la plaza para presenciarlo o hablar con el Inquisidor para intervenir)." % scapegoat.npc_name)
				vm.active_royal_investigation["stage"] = "PUBLIC_TRIAL_PLAZA"
				vm.active_royal_investigation["stage_timer"] = 0.0
		"PUBLIC_TRIAL_PLAZA":
			var sc_key_pl: String = str(vm.active_royal_investigation.get("scapegoat_key", ""))
			var scapegoat_pl: VillageNPC = vm._find_npc_by_name(sc_key_pl)
			if scapegoat_pl == null or scapegoat_pl.is_dead:
				inv_npc._stop_crafting_bar()
				vm.active_royal_investigation["stage"] = "DEPARTING"
				vm.active_royal_investigation["stage_timer"] = 0.0
				return
			var plaza_trial_pos := Vector2(465, 38)
			scapegoat_pl.is_sleeping = false
			scapegoat_pl.hold_for_interview(inv_npc, 1.2)
			if inv_npc.global_position.distance_to(plaza_trial_pos) > 26.0:
				inv_npc._stop_crafting_bar()
				inv_npc._move_towards_point(plaza_trial_pos, 78.0, delta)
				var sc_target_pos: Vector2 = inv_npc.global_position + Vector2(18, 2)
				if scapegoat_pl.global_position.distance_to(sc_target_pos) > 14.0:
					scapegoat_pl._move_towards_point(sc_target_pos, 84.0, delta)
					scapegoat_pl._finish_frame_movement(delta)
			else:
				inv_npc.velocity = Vector2.ZERO
				var accused_spot := plaza_trial_pos + Vector2(22, 0)
				if scapegoat_pl.global_position.distance_to(accused_spot) > 12.0:
					scapegoat_pl._move_towards_point(accused_spot, 80.0, delta)
					scapegoat_pl._finish_frame_movement(delta)
				else:
					scapegoat_pl.velocity = Vector2.ZERO
				if inv_npc.sprite:
					inv_npc.sprite.flip_h = false
				if scapegoat_pl.sprite:
					scapegoat_pl.sprite.flip_h = true
				# Los aldeanos cercanos en la Plaza se detienen a presenciar el juicio público
				for n_spec in vm.get_tree().get_nodes_in_group("village_npcs"):
					if n_spec is VillageNPC and n_spec != inv_npc and n_spec != scapegoat_pl:
						var v_spec := n_spec as VillageNPC
						if v_spec.is_conscious() and v_spec.global_position.distance_to(plaza_trial_pos) <= 170.0:
							v_spec.hold_for_interview(inv_npc, 0.6)
				if is_instance_valid(inv_npc._cached_dm) and inv_npc._cached_dm.has_method("is_active") and bool(inv_npc._cached_dm.call("is_active")):
					return
				var prev_tr: float = s_timer
				s_timer += delta
				vm.active_royal_investigation["stage_timer"] = s_timer
				var rem_tr: int = maxi(1, int(ceil(18.0 - s_timer)))
				inv_npc._update_craft_bar_visual(clampf(s_timer / 18.0, 0.02, 1.0), "⚖️ Juicio Público de %s (%ds)" % [scapegoat_pl.npc_name, rem_tr], Color(1.0, 0.78, 0.28, 0.95))
				inv_npc.trigger_action_animation(0.6)
				if prev_tr < 1.0 and s_timer >= 1.0:
					inv_npc._spawn_floating_text("⚖️🔔 «¡Habitantes del valle! ¡Por orden de la Corona, %s será juzgado por asesinato!»" % scapegoat_pl.npc_name, Color.GOLD, -44.0)
				elif prev_tr < 7.0 and s_timer >= 7.0:
					scapegoat_pl._spawn_floating_text("⛓️😭 «¡Juro por mi vida que soy inocente! ¡Alguien me tendió una trampa!»", Color.ORANGE_RED, -42.0)
				elif prev_tr < 13.0 and s_timer >= 13.0:
					inv_npc._spawn_floating_text("⚖️🗡️ «Si nadie presenta pruebas ni confiesa en 5 segundos, se ejecutará la sentencia.»", Color.ORANGE, -44.0)
				if s_timer >= 18.0:
					inv_npc._stop_crafting_bar()
					inv_npc.trigger_action_animation(3.5)
					var chosen_name: String = scapegoat_pl.npc_name
					var best_sc: int = int(suspects.get(sc_key_pl, {}).get("score", 50))
					scapegoat_pl._spawn_floating_text("⛓️💔 «¡Juro que soy inocente...!»", Color.ORANGE_RED, -42.0)
					arrest_npc(vm, scapegoat_pl, inv_npc, "condena en el Juicio Público", 48, 60)
					inv_npc._spawn_floating_text("⚖️⛓️ «¡Sentencia real dictada en la Plaza: %s cumplirá condena en el calabozo!»" % chosen_name, Color.GOLD, -44.0)
					vm._hint_player("⚖️👑 ¡SENTENCIA EN LA PLAZA CENTRAL! El Inquisidor Real Alistair condenó a %s (%d%% sospecha) a cumplir pena en el calabozo de la comisaría." % [chosen_name, clampi(best_sc, 35, 95)])
					vm.active_royal_investigation["stage"] = "DEPARTING"
					vm.active_royal_investigation["stage_timer"] = 0.0
		"DEPARTING":
			inv_npc.is_sleeping = false
			var exit_pos := Vector2(1000, 48)
			inv_npc._move_towards_point(exit_pos, 94.0, delta)
			if inv_npc.global_position.distance_to(exit_pos) <= 20.0:
				vm.active_royal_investigation["active"] = false
				if vm._royal_investigator_npc == inv_npc:
					vm._royal_investigator_npc = null
				inv_npc.queue_free()

## IA detectivesca del Comisario Vane (`active_sheriff_investigation`, máx. 5 eslabones en cadena):
## Devuelve `true` si el Comisario está realizando activamente su investigación en cadena.
static func update_sheriff_investigator_ai(vm: VillageManager, sheriff: VillageNPC, delta: float) -> bool:
	if sheriff == null or sheriff.is_dead or sheriff.is_downed:
		return false
	if vm.active_sheriff_investigation.is_empty() or not bool(vm.active_sheriff_investigation.get("active", false)):
		return false
	var h: int = WorldClock.current_hour if WorldClock else 12
	if h >= 22 or h < 6:
		return false
	var stage: String = str(vm.active_sheriff_investigation.get("stage", "CRIME_SCENE"))
	var s_timer: float = float(vm.active_sheriff_investigation.get("stage_timer", 0.0))
	match stage:
		"CRIME_SCENE":
			var c_pos := Vector2(float(vm.active_sheriff_investigation.get("crime_pos_x", 465.0)), float(vm.active_sheriff_investigation.get("crime_pos_y", 44.0)))
			if sheriff.global_position.distance_to(c_pos) > 24.0:
				sheriff._stop_crafting_bar()
				sheriff._move_towards_point(c_pos, 62.0, delta)
			else:
				sheriff.velocity = Vector2.ZERO
				sheriff.trigger_action_animation(1.0)
				s_timer += delta
				vm.active_sheriff_investigation["stage_timer"] = s_timer
				var rem_sh_cs: int = maxi(1, int(ceil(12.0 - s_timer)))
				sheriff._update_craft_bar_visual(clampf(s_timer / 12.0, 0.02, 1.0), "🔍 Examinando escena (%ds)" % rem_sh_cs, Color(0.45, 0.88, 1.0, 0.95))
				if int(s_timer * 10.0) % 35 == 0:
					sheriff._spawn_floating_text("🚓🔍 Inspeccionando escena del crimen y rastro de huellas...", Color.AQUA, -36.0)
				if s_timer >= 12.0:
					sheriff._stop_crafting_bar()
					_inspect_crime_scene_and_footprints(vm, sheriff, vm.active_sheriff_investigation)
					vm.active_sheriff_investigation["stage"] = "MORGUE"
					vm.active_sheriff_investigation["stage_timer"] = 0.0
			return true
		"MORGUE":
			var m_pos: Vector2 = vm.sitio(vm._morgue_table_positions[1])
			if sheriff.global_position.distance_to(m_pos) > 26.0:
				sheriff._stop_crafting_bar()
				sheriff._move_towards_point(m_pos, 62.0, delta)
			else:
				sheriff.velocity = Vector2.ZERO
				sheriff.trigger_action_animation(1.0)
				s_timer += delta
				vm.active_sheriff_investigation["stage_timer"] = s_timer
				var rem_sh_mg: int = maxi(1, int(ceil(10.0 - s_timer)))
				sheriff._update_craft_bar_visual(clampf(s_timer / 10.0, 0.02, 1.0), "⚰️ Revisando autopsia (%ds)" % rem_sh_mg, Color(0.45, 0.92, 0.95, 0.95))
				if s_timer >= 10.0:
					sheriff._stop_crafting_bar()
					vm.active_sheriff_investigation["stage"] = "INTERVIEWS"
					vm.active_sheriff_investigation["stage_timer"] = 0.0
					var rep_n: String = str(vm.active_sheriff_investigation.get("reporter_name", "quien halló el cuerpo"))
					sheriff._spawn_floating_text("⚰️🚓 Autopsia revisada: interrogaré primero a %s." % rep_n, Color.AQUA, -38.0)
			return true
		"INTERVIEWS":
			_process_case_chain_interviews_step(vm, sheriff, delta, vm.active_sheriff_investigation, false)
			return true
		"VERDICT":
			_conclude_sheriff_investigation_verdict(vm, sheriff)
			return true
		"ARRESTING_NPC":
			var arr_key: String = str(vm.active_sheriff_investigation.get("scapegoat_key", ""))
			var arr_npc: VillageNPC = vm._find_npc_by_name(arr_key)
			if arr_npc == null or arr_npc.is_dead:
				vm.active_sheriff_investigation["active"] = false
				return false
			arr_npc.is_sleeping = false
			arr_npc.hold_for_interview(sheriff, 1.0)
			if not bool(vm.active_sheriff_investigation.get("handcuffed_npc", false)):
				if sheriff.global_position.distance_to(arr_npc.global_position) > 28.0:
					sheriff._move_towards_point(arr_npc.global_position, 82.0, delta)
					return true
				vm.active_sheriff_investigation["handcuffed_npc"] = true
				arr_npc._spawn_floating_text("⛓️😱 ¡Alguacil mayor Vane, juro que me han incriminado!", Color.ORANGE_RED, -40.0)
				sheriff._spawn_floating_text("🚓⛓️ ¡%s, quedas detenido! ¡Camina hacia la Celda Policial!" % arr_npc.npc_name, Color.GOLD, -42.0)
				return true
			var cell_dest := Vector2(872, 176)
			if sheriff.global_position.distance_to(cell_dest) > 28.0:
				sheriff._move_towards_point(cell_dest, 74.0, delta)
				var follow_pt: Vector2 = sheriff.global_position + Vector2(-16, 4)
				if arr_npc.global_position.distance_to(follow_pt) > 12.0:
					arr_npc._move_towards_point(follow_pt, 80.0, delta)
					arr_npc._finish_frame_movement(delta)
				return true
			sheriff.velocity = Vector2.ZERO
			arr_npc.velocity = Vector2.ZERO
			arrest_npc(vm, arr_npc, sheriff, "condena del Alguacil mayor Vane", 48, 50)
			sheriff._spawn_floating_text("🚓🔒 %s encerrado en la Celda Policial. Caso cerrado." % arr_npc.npc_name, Color.AQUA, -42.0)
			vm._hint_player("🚓🔒 El Alguacil mayor Vane encerró físicamente a %s en la Celda Policial tras concluir su investigación." % arr_npc.npc_name)
			vm.active_sheriff_investigation["active"] = false
			_check_and_start_next_morgue_sheriff_case(vm)
			return true
	return false

static func _process_inquisitor_field_recon(vm: VillageManager, inv_npc: VillageNPC, delta: float, done_cnt: int, max_cnt: int, days_inv: int) -> void:
	var c_pos: Vector2 = _get_investigation_crime_pos(vm)
	var recon_pts: Array[Vector2] = [c_pos, vm.sitio(vm._morgue_table_positions[1]), vm.sitio(Vector2(886, 126)), vm.sitio(Vector2(465, 36))]
	var r_idx: int = int(vm.active_royal_investigation.get("recon_spot_idx", 0)) % recon_pts.size()
	var target_pt: Vector2 = recon_pts[r_idx]
	if inv_npc.global_position.distance_to(target_pt) > 22.0:
		inv_npc._move_towards_point(target_pt, 76.0, delta)
	else:
		inv_npc.velocity = Vector2.ZERO
		inv_npc.trigger_action_animation(1.0)
		var r_t: float = float(vm.active_royal_investigation.get("routine_timer", 0.0)) + delta
		vm.active_royal_investigation["routine_timer"] = r_t
		if int(r_t * 10.0) % 40 == 0:
			inv_npc._spawn_floating_text("🔍📓 Día %d: Cruzando testimonios (%d/%d interrogados)..." % [days_inv, done_cnt, max_cnt], Color(0.95, 0.88, 0.52), -36.0)
		if r_t >= 8.5:
			vm.active_royal_investigation["routine_timer"] = 0.0
			vm.active_royal_investigation["recon_spot_idx"] = (r_idx + 1) % recon_pts.size()

## Cruza el libro de autopsias de la Morgue (`corpse_records`) y los arrestos del Comisario Vane con el expediente del Inquisidor
static func _cross_check_morgue_and_police_records(vm: VillageManager, inv_npc: VillageNPC, suspects: Dictionary, clues: Array) -> void:
	if bool(vm.active_royal_investigation.get("morgue_checked", false)):
		return
	vm.active_royal_investigation["morgue_checked"] = true
	if not suspects.has("Jugador"):
		return
	var p_entry: Dictionary = suspects["Jugador"]
	var v_name: String = str(vm.active_royal_investigation.get("victim_name", ""))
	for rec in vm.corpse_records:
		var r_victim: String = str(rec.get("victim_name", ""))
		var r_susp: String = str(rec.get("suspect", ""))
		var r_clue: String = str(rec.get("witness_clue", ""))
		if r_susp.begins_with("Jugador"):
			if r_victim == v_name:
				var c_msg: String = "Registro Forense de la Morgue: %s (%s)." % [r_susp, r_clue]
				if not (c_msg in clues):
					p_entry["score"] = int(p_entry.get("score", 16)) + 50
					p_entry["status_note"] = "Identificado en el Libro Forense (%s)" % r_clue
					clues.append(c_msg)
			else:
				var c_msg2: String = "Antecedente de homicidio en la Morgue (%s): %s." % [r_victim, r_clue]
				if not (c_msg2 in clues):
					p_entry["score"] = int(p_entry.get("score", 16)) + 25
					clues.append(c_msg2)
	if is_instance_valid(inv_npc) and int(p_entry.get("score", 0)) >= 50:
		inv_npc._spawn_floating_text("⚖️📔 ¡El Libro Forense y la Guardia vinculan al Forastero con el crimen!", Color.ORANGE_RED, -42.0)

static func _inspect_crime_scene_and_footprints(vm: VillageManager, inv_npc: VillageNPC, case_dict: Dictionary) -> void:
	var c_pos := Vector2(float(case_dict.get("crime_pos_x", 465.0)), float(case_dict.get("crime_pos_y", 44.0)))
	var clues: Array = case_dict.get("clues_log", [])
	var pud: Dictionary = vm.get_blood_puddle_clue_near(c_pos, 95.0)
	if not pud.is_empty():
		var f_dir: Vector2 = pud.get("flee_dir", Vector2.ZERO) as Vector2
		var f_comp: String = str(pud.get("flee_compass", ""))
		if f_dir.length_squared() > 0.01 and f_comp != "":
			case_dict["flee_dir_x"] = f_dir.x
			case_dict["flee_dir_y"] = f_dir.y
			case_dict["flee_compass"] = f_comp
			clues.append("Rastro de sangre en la escena: huellas frescas desde el charco apuntan %s." % f_comp)
			if is_instance_valid(inv_npc):
				inv_npc._spawn_floating_text("🩸👣 ¡Huellas de sangre fresca! El asesino huyó %s." % f_comp, Color.ORANGE_RED, -40.0)
			return
	clues.append("Escena del crimen inspeccionada (sin huellas de pisadas en el charco).")

static func _pick_next_neighbor_to_keep_chain_alive(vm: VillageManager, inv_npc: VillageNPC, case_dict: Dictionary) -> String:
	var suspects: Dictionary = case_dict.get("suspects", {})
	var queue: Array = case_dict.get("interview_queue", [])
	var ref_pos: Vector2 = inv_npc.global_position if is_instance_valid(inv_npc) else Vector2(float(case_dict.get("crime_pos_x", 465.0)), float(case_dict.get("crime_pos_y", 44.0)))
	var best_name: String = ""
	var best_d2: float = 99999999.0
	for k in suspects.keys():
		var s_name: String = str(k)
		if s_name == "Jugador" or (s_name in queue):
			continue
		var se: Dictionary = suspects[s_name]
		if bool(se.get("interviewed", false)):
			continue
		var v_node: VillageNPC = vm._find_npc_by_name(s_name)
		if v_node == null or v_node.is_dead or (not bool(case_dict.get("is_royal", false)) and v_node == inv_npc):
			continue
		var d2: float = ref_pos.distance_squared_to(v_node.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best_name = s_name
	return best_name

static func _process_case_chain_interviews_step(vm: VillageManager, inv_npc: VillageNPC, delta: float, case_dict: Dictionary, is_royal: bool) -> void:
	var queue: Array = case_dict.get("interview_queue", [])
	var cur_target_name: String = str(case_dict.get("current_interview_target", ""))
	var done_cnt: int = int(case_dict.get("interviews_done", 0))
	var max_cnt: int = int(case_dict.get("max_interviews", 5))
	var days_inv: int = int(case_dict.get("days_investigating", 1))
	var max_days: int = int(case_dict.get("max_days", 18))
	var s_timer: float = float(case_dict.get("stage_timer", 0.0))
	var suspects: Dictionary = case_dict.get("suspects", {})
	var clues: Array = case_dict.get("clues_log", [])

	if cur_target_name == "" and queue.is_empty() and done_cnt < max_cnt and is_royal:
		var next_nb: String = _pick_next_neighbor_to_keep_chain_alive(vm, inv_npc, case_dict)
		if next_nb != "":
			queue.append(next_nb)

	if done_cnt >= max_cnt or (queue.is_empty() and cur_target_name == ""):
		case_dict["stage"] = "PLAYER_CHECK" if is_royal else "VERDICT"
		case_dict["stage_timer"] = 0.0
		return

	var done_today: int = int(case_dict.get("interviews_done_today", 0))
	var quota_today: int = int(case_dict.get("daily_quota", 6))
	if is_royal and done_today >= quota_today and days_inv < max_days - 1:
		_process_inquisitor_field_recon(vm, inv_npc, delta, done_cnt, max_cnt, days_inv)
		return

	if cur_target_name == "" and not queue.is_empty():
		cur_target_name = str(queue.pop_front())
		case_dict["current_interview_target"] = cur_target_name

	# Si un testigo nombró al Jugador (o el Jugador reportó el cuerpo), el investigador va físicamente a interrogarlo
	if cur_target_name == "Jugador":
		var player := vm.get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			case_dict["current_interview_target"] = ""
			case_dict["interviews_done"] = done_cnt + 1
			return
		var target_pt: Vector2 = Vector2(902, 144) if vm.player_in_jail else player.global_position
		var dist_p: float = inv_npc.global_position.distance_to(target_pt)
		if dist_p > 36.0:
			inv_npc._stop_crafting_bar()
			inv_npc._move_towards_point(target_pt, 64.0, delta)
			var walk_t: float = float(case_dict.get("walk_timer", 0.0)) + delta
			case_dict["walk_timer"] = walk_t
			if walk_t >= 26.0 and not vm.player_in_jail and dist_p > 220.0:
				case_dict["walk_timer"] = 0.0
				case_dict["stage_timer"] = 0.0
				case_dict["current_interview_target"] = ""
				inv_npc._spawn_floating_text("🕵️‍♂️📜 El Forastero no está cerca; seguiré interrogando a otros testigos.", Color.AQUA, -38.0)
		else:
			case_dict["walk_timer"] = 0.0
			inv_npc.velocity = Vector2.ZERO
			if not bool(case_dict.get("player_dialogue_opened", false)):
				case_dict["player_dialogue_opened"] = true
				if inv_npc.start_interrogation_dialogue_with_player(player):
					inv_npc._spawn_floating_text("🕵️‍♂️⚖️ ¡Interrogatorio en curso! Elige bien tus palabras para defenderte.", Color.GOLD, -44.0)
			if is_instance_valid(inv_npc._cached_dm) and inv_npc._cached_dm.has_method("is_active") and bool(inv_npc._cached_dm.call("is_active")):
				return
			var prev_sp: float = s_timer
			s_timer += delta
			case_dict["stage_timer"] = s_timer
			var rem_p_int: int = maxi(1, int(ceil(8.0 - s_timer)))
			inv_npc._update_craft_bar_visual(clampf(s_timer / 8.0, 0.02, 1.0), "🗣️ Interrogando al Forastero (%ds)" % rem_p_int, Color(1.0, 0.85, 0.35, 0.95))
			if prev_sp < 0.5 and s_timer >= 0.5:
				inv_npc._spawn_floating_text("🕵️‍♂️📜 Un testigo te situó cerca: ¿dónde estabas y qué tienes en las manos?", Color(1.0, 0.90, 0.52), -40.0)
			if s_timer >= 8.0:
				inv_npc._stop_crafting_bar()
				case_dict["stage_timer"] = 0.0
				case_dict["player_dialogue_opened"] = false
				case_dict["current_interview_target"] = ""
				case_dict["interviews_done"] = done_cnt + 1
				case_dict["interviews_done_today"] = done_today + 1
				_evaluate_player_inspection(vm, inv_npc, player, suspects, clues, true, case_dict)
				var p_sc: int = int(suspects.get("Jugador", {}).get("score", 0))
				if p_sc >= 75:
					case_dict["stage"] = "VERDICT"
		return

	var target_npc: VillageNPC = vm._find_npc_by_name(cur_target_name)
	if target_npc == null or target_npc.is_dead or target_npc == inv_npc:
		case_dict["current_interview_target"] = ""
		case_dict["interviews_done"] = done_cnt + 1
		return
	if target_npc.is_downed or target_npc.is_stunned_flag or target_npc.sedated_timer > 0.0:
		if not queue.is_empty():
			queue.push_back(cur_target_name)
			case_dict["current_interview_target"] = ""
		elif is_royal:
			_process_inquisitor_field_recon(vm, inv_npc, delta, done_cnt, max_cnt, days_inv)
		else:
			case_dict["current_interview_target"] = ""
			case_dict["interviews_done"] = done_cnt + 1
		return

	var dist_npc: float = inv_npc.global_position.distance_to(target_npc.global_position)
	if dist_npc <= 46.0:
		target_npc.hold_for_interview(inv_npc, 0.9)

	if dist_npc > 32.0:
		inv_npc._stop_crafting_bar()
		inv_npc._move_towards_point(target_npc.global_position, 62.0, delta)
	else:
		inv_npc.velocity = Vector2.ZERO
		target_npc.hold_for_interview(inv_npc, 0.9)
		var to_target: Vector2 = target_npc.global_position - inv_npc.global_position
		if to_target.length_squared() > 1.0:
			inv_npc.facing_direction = to_target.normalized()
		if inv_npc.sprite:
			inv_npc.sprite.flip_h = (target_npc.global_position.x < inv_npc.global_position.x)
		inv_npc.trigger_action_animation(1.0)
		var prev_s_npc: float = s_timer
		s_timer += delta
		case_dict["stage_timer"] = s_timer
		var rem_npc_int: int = maxi(1, int(ceil(12.0 - s_timer)))
		inv_npc._update_craft_bar_visual(clampf(s_timer / 12.0, 0.02, 1.0), "🗣️ Interrogando a %s (%ds)" % [target_npc.npc_name, rem_npc_int], Color(1.0, 0.88, 0.42, 0.95))
		if prev_s_npc < 0.6 and s_timer >= 0.6:
			inv_npc._spawn_floating_text("🕵️‍♂️📜 Interrogando a %s (%d/%d): ¿Dónde estabas y a quién viste?" % [target_npc.npc_name, done_cnt + 1, max_cnt], Color(1.0, 0.90, 0.52), -36.0)
		if s_timer >= 12.0:
			inv_npc._stop_crafting_bar()
			case_dict["stage_timer"] = 0.0
			case_dict["current_interview_target"] = ""
			case_dict["interviews_done"] = done_cnt + 1
			case_dict["interviews_done_today"] = done_today + 1
			_evaluate_npc_interview(vm, inv_npc, target_npc, suspects, clues, case_dict)

static func _evaluate_npc_interview(vm: VillageManager, inv_npc: VillageNPC, witness: VillageNPC, suspects: Dictionary, clues: Array, case_dict: Dictionary = {}) -> void:
	if not suspects.has(witness.npc_name):
		return
	var active_case: Dictionary = vm.active_royal_investigation if case_dict.is_empty() else case_dict
	var entry: Dictionary = suspects[witness.npc_name]
	entry["interviewed"] = true
	_reveal_motives_known_by_witness(vm, witness, suspects, clues, active_case)
	var alibi: String = str(entry.get("mem_alibi_partner", entry.get("alibi_partner", "")))
	var dist_to_crime: float = float(entry.get("mem_dist_to_crime", entry.get("dist_to_crime", 999.0)))
	entry["known_dist"] = dist_to_crime
	var dist_m: int = int(round(dist_to_crime / 16.0))
	var crime_pos := Vector2(float(active_case.get("crime_pos_x", 465.0)), float(active_case.get("crime_pos_y", 44.0)))
	var flee_dir := Vector2(float(active_case.get("flee_dir_x", 0.0)), float(active_case.get("flee_dir_y", 0.0)))
	var queue: Array = active_case.get("interview_queue", [])

	# 1. Registro físico de bolsillos, cofre doméstico de su casa, sangre y heridas de combate recientes / vendajes rudimentarios
	var chest_planted_ev: String = ""
	if witness.family_id != "" and witness.family_id != "none":
		for ch in vm.house_chests:
			if str(ch.get("family_id", "")) == witness.family_id and str(ch.get("planted_evidence", "")) != "":
				chest_planted_ev = str(ch.get("planted_evidence", ""))
				break

	if witness.carries_royal_safe_conduct or witness.has_pocket_item("royal_safe_conduct", 1) or chest_planted_ev == "royal_safe_conduct":
		entry["score"] = maxi(int(entry.get("score", 10)) + 85, 92)
		entry["known_dist"] = minf(dist_to_crime, 120.0)
		entry["mem_dist_to_crime"] = minf(dist_to_crime, 120.0)
		var where_found: String = "en el cofre de su casa" if chest_planted_ev == "royal_safe_conduct" else "en su bolsillo"
		entry["status_note"] = "¡Sorprendido con el Salvoconducto Real robado (%s)!" % where_found
		clues.append("¡PRUEBA IRREFUTABLE! Al registrar a %s se halló el Salvoconducto Real %s (+85%% sospecha)." % [witness.npc_name, where_found])
		witness._spawn_floating_text("😱📜 ¡¿Quién puso este Salvoconducto Real %s?!" % where_found, Color.ORANGE_RED, -40.0)
		if is_instance_valid(inv_npc):
			inv_npc._spawn_floating_text("👑📜 ¡Hallado el Salvoconducto Real %s de %s!" % [where_found, witness.npc_name], Color.GOLD, -42.0)
		active_case["stage"] = "VERDICT"
		active_case["stage_timer"] = 0.0
		return

	if witness.trade_role != VillageNPC.TradeRole.DOCTOR:
		for org_it in ["organ_heart", "organ_liver", "organ_kidney", "organ_lung", "organ_stomach", "organ_eye"]:
			if witness.has_pocket_item(org_it, 1) or chest_planted_ev == org_it:
				entry["score"] = maxi(int(entry.get("score", 10)) + 60, 72)
				entry["known_dist"] = minf(dist_to_crime, 160.0)
				entry["mem_dist_to_crime"] = minf(dist_to_crime, 160.0)
				var org_loc: String = "en el cofre de su casa" if chest_planted_ev == org_it else "en su bolsillo"
				entry["status_note"] = "Ocultaba un órgano humano extraído (%s)" % org_loc
				clues.append("Registro forense: %s ocultaba un órgano humano extraído (%s) %s (+60%% sospecha)." % [witness.npc_name, org_it, org_loc])
				break

	if witness.is_bloodstained():
		entry["score"] = int(entry.get("score", 10)) + 42
		clues.append("Inspección física: %s tenía manchas de sangre reciente en la ropa (+42%% sospecha)." % witness.npc_name)
	if witness.health_comp != null and witness.health_comp.has_fresh_combat_wounds_or_makeshift():
		entry["score"] = int(entry.get("score", 10)) + 28
		clues.append("Inspección médica: %s presenta heridas de forcejeo o vendajes rudimentarios recientes (+28%% sospecha)." % witness.npc_name)

	# 1b. Coartada falsa pactada por afinidad o Rumor sembrado contra otro vecino (`witness_alibi_for_player` / `witness_framed_target_name`)
	if witness.witness_alibi_for_player and suspects.has("Jugador"):
		var p_alibi_entry: Dictionary = suspects["Jugador"]
		p_alibi_entry["score"] = maxi(5, int(p_alibi_entry.get("score", 10)) - 25)
		p_alibi_entry["status_note"] = "Coartada avalada por %s (-25%% sospecha)" % witness.npc_name
		clues.append("Coartada a favor del Forastero: %s declaró bajo juramento que el Forastero estuvo con él/ella (-25%% sospecha)." % witness.npc_name)
		witness._spawn_floating_text("🗣️🤝 «El Forastero estuvo conmigo, doy fe de su inocencia.»", Color.SPRING_GREEN, -38.0)

	var named_for_chain: Array[String] = []
	if witness.witness_framed_target_name != "" and suspects.has(witness.witness_framed_target_name):
		var f_name: String = witness.witness_framed_target_name
		var f_entry: Dictionary = suspects[f_name]
		f_entry["known_dist"] = 80.0
		f_entry["mem_dist_to_crime"] = minf(float(f_entry.get("mem_dist_to_crime", 80.0)), 80.0)
		f_entry["mem_alibi_partner"] = ""
		f_entry["score"] = int(f_entry.get("score", 15)) + 38
		f_entry["status_note"] = "Señalado en la escena del crimen por %s" % witness.npc_name
		clues.append("Testimonio acusatorio de %s: aseguró haber visto a %s merodeando junto a la escena del crimen (+38%% sospecha)." % [witness.npc_name, f_name])
		witness._spawn_floating_text("🗣️👉 «¡Vi a %s merodeando junto al lugar del crimen!»" % f_name, Color.VIOLET, -38.0)
		if not bool(f_entry.get("interviewed", false)) and not (f_name in queue) and f_name != witness.npc_name:
			queue.push_front(f_name)
			named_for_chain.append(f_name)

	# 2. ¿Dónde estaba este testigo y a quién vio cerca? (Hilo en cadena)
	var seen_list: Array = entry.get("mem_seen_list", []).duplicate()
	var live_seen: Array[Dictionary] = witness.get_seen_entities_near_crime(crime_pos, int(active_case.get("crime_total_mins", 0)), 280.0, 240)
	for ls in live_seen:
		var ls_n: String = str(ls.get("name", ""))
		var exists_s := false
		for ex_s in seen_list:
			if str(ex_s.get("name", "")) == ls_n:
				exists_s = true
				break
		if not exists_s:
			seen_list.append(ls)

	for s_info in seen_list:
		var s_name: String = str(s_info.get("name", ""))
		if s_name == "" or not suspects.has(s_name):
			continue
		if s_name == "Jugador" and (witness.witness_silenced_player or witness.witness_alibi_for_player):
			continue
		var s_entry: Dictionary = suspects[s_name]
		var s_dist: float = float(s_info.get("dist_to_crime", s_entry.get("mem_dist_to_crime", 180.0)))
		s_entry["known_dist"] = s_dist
		var s_pos := Vector2(float(s_info.get("pos_x", s_entry.get("mem_pos_x", crime_pos.x))), float(s_info.get("pos_y", s_entry.get("mem_pos_y", crime_pos.y))))
		var matches_flee: bool = false
		if flee_dir.length_squared() > 0.01 and (s_pos - crime_pos).length_squared() > 16.0:
			matches_flee = (s_pos - crime_pos).normalized().dot(flee_dir) >= 0.42

		if s_name == "Jugador":
			var add_p: int = 34 if s_dist <= 180.0 else 18
			if bool(s_info.get("bloodstained", false)):
				add_p += 28
			if bool(s_info.get("wounded", false)):
				add_p += 18
			if matches_flee:
				add_p += 16
			s_entry["score"] = int(s_entry.get("score", 10)) + add_p
			s_entry["status_note"] = "Visto a %dm de la escena por %s%s" % [int(round(s_dist / 16.0)), witness.npc_name, " (en dirección de las huellas)" if matches_flee else ""]
			clues.append("Testimonio de %s: vio al Forastero a %d m del lugar del crimen%s (+%d%% sospecha)." % [witness.npc_name, int(round(s_dist / 16.0)), " en la dirección de las huellas de sangre" if matches_flee else "", add_p])
			witness._spawn_floating_text("🗣️👁️ ¡Vi al Forastero cerca de allí!", Color.ORANGE_RED, -36.0)
		else:
			if str(s_entry.get("mem_alibi_partner", "")) == "" and s_dist <= 320.0:
				var add_v: int = 12 + (16 if matches_flee else 0)
				var rel_w: int = witness.get_relationship_with_npc(s_name) if witness.has_method("get_relationship_with_npc") else 0
				var rel_bias_note: String = ""
				if rel_w <= -25:
					add_v += 16
					rel_bias_note = " [Rivalidad vecinal %d: acusación severa +16%%]" % rel_w
				elif rel_w >= 60:
					add_v = maxi(4, add_v - 8)
					rel_bias_note = " [Amigo/Familia +%d: intentó restarle importancia -8%%]" % rel_w
				s_entry["score"] = int(s_entry.get("score", 10)) + add_v
				if not bool(s_entry.get("interviewed", false)):
					s_entry["status_note"] = "Situado a %dm por %s%s" % [int(round(s_dist / 16.0)), witness.npc_name, " (rumbo de las huellas)" if matches_flee else ""]
				clues.append("%s declaró haber visto a %s a %d m de la escena%s%s (+%d%% sospecha)." % [witness.npc_name, s_name, int(round(s_dist / 16.0)), " en dirección de las huellas" if matches_flee else "", rel_bias_note, add_v])

		if not bool(s_entry.get("interviewed", false)) and not (s_name in queue) and s_name != witness.npc_name:
			var rel_prio: int = witness.get_relationship_with_npc(s_name) if (s_name != "Jugador" and witness.has_method("get_relationship_with_npc")) else 0
			if matches_flee or s_name == "Jugador" or rel_prio <= -25:
				queue.push_front(s_name)
			else:
				queue.append(s_name)
			named_for_chain.append(s_name)

	# 3. Evaluación de coartada y distancia del propio interrogado
	if alibi != "":
		entry["score"] = mini(int(entry.get("score", 10)), 12)
		entry["status_note"] = "Coartada confirmada con %s (%dm)" % [alibi, dist_m]
		if suspects.has(alibi):
			var p_alibi: Dictionary = suspects[alibi]
			p_alibi["known_dist"] = float(p_alibi.get("mem_dist_to_crime", dist_to_crime))
			if not bool(p_alibi.get("interviewed", false)) and not (alibi in queue):
				queue.append(alibi)
		var chain_txt: String = (" | Vio cerca a: " + ", ".join(named_for_chain)) if not named_for_chain.is_empty() else ""
		clues.append("%s estaba junto a %s a %d m (Coartada)%s." % [witness.npc_name, alibi, dist_m, chain_txt])
		if is_instance_valid(inv_npc):
			inv_npc._spawn_floating_text("📝✅ %s tiene coartada con %s%s" % [witness.npc_name, alibi, (" -> Iré a ver a " + named_for_chain[0]) if not named_for_chain.is_empty() else ""], Color.SPRING_GREEN, -36.0)
	elif dist_to_crime > 360.0:
		entry["score"] = mini(int(entry.get("score", 10)), 8)
		entry["status_note"] = "Descartado por distancia (%dm de la escena)" % dist_m
		clues.append("%s declaró estar lejos (a %d m de la escena — Descartado)." % [witness.npc_name, dist_m])
		if is_instance_valid(inv_npc):
			inv_npc._spawn_floating_text("📝📍 %s estaba lejos (%dm)%s" % [witness.npc_name, dist_m, (" -> Nombró a " + named_for_chain[0]) if not named_for_chain.is_empty() else ""], Color(0.65, 0.92, 1.0), -36.0)
	else:
		var new_sc: int = 48 if dist_to_crime <= 150.0 else (34 if dist_to_crime <= 250.0 else 22)
		if bool(entry.get("is_vagrant", false)):
			new_sc += 8
		var w_pos := Vector2(float(entry.get("mem_pos_x", witness.global_position.x)), float(entry.get("mem_pos_y", witness.global_position.y)))
		var w_low: String = str(active_case.get("weapon_used", "")).to_lower()
		var role_matches_weapon: bool = (
			(("hacha" in w_low) and witness.trade_role == VillageNPC.TradeRole.CARPENTER) or
			(("martillo" in w_low or "pico" in w_low or "espada" in w_low) and witness.trade_role == VillageNPC.TradeRole.BLACKSMITH) or
			(("cuchillo" in w_low or "corte" in w_low or "despiece" in w_low) and witness.trade_role == VillageNPC.TradeRole.BUTCHER) or
			(("envenenamiento" in w_low or "estofado" in w_low or "toxina" in w_low) and witness.trade_role in [VillageNPC.TradeRole.HERBALIST, VillageNPC.TradeRole.INNKEEPER]) or
			(("bisturí" in w_low or "órgano" in w_low or "quirúrgic" in w_low) and witness.trade_role == VillageNPC.TradeRole.DOCTOR)
		)
		var extra_notes: Array[String] = []
		if flee_dir.length_squared() > 0.01 and (w_pos - crime_pos).length_squared() > 16.0 and (w_pos - crime_pos).normalized().dot(flee_dir) >= 0.42:
			new_sc += 16
			extra_notes.append("En dirección de las huellas de sangre")
		if role_matches_weapon:
			new_sc += 18
			extra_notes.append("Oficio compatible con el arma/método forense")
		# T4/T2: carácter real del vecino (su personalidad): malicia y agresividad suman, honestidad resta
		var w_traits: Array = witness.person_profile.personality if witness.person_profile != null else witness.traits
		var dark_v: float = TraitCatalog.tendency(w_traits, "malice") + 0.5 * maxf(0.0, TraitCatalog.tendency(w_traits, "aggression")) - 0.5 * TraitCatalog.tendency(w_traits, "honesty")
		var dark_trait: String = ""
		if dark_v >= 0.6:
			var best_t: float = 0.0
			for trait_name in w_traits:
				var tv: float = TraitCatalog.tendency([trait_name], "malice") + 0.5 * maxf(0.0, TraitCatalog.tendency([trait_name], "aggression")) - 0.5 * TraitCatalog.tendency([trait_name], "honesty")
				if tv > best_t:
					best_t = tv
					dark_trait = TraitCatalog.npc_display(witness, str(trait_name))
		if dark_trait != "":
			new_sc += 10
			extra_notes.append("Rasgo: " + dark_trait)
		elif dark_v <= -0.6:
			new_sc = maxi(10, new_sc - 8)
		entry["score"] = maxi(int(entry.get("score", 10)), new_sc + int(entry.get("motive_pts", 0)))
		var note_suffix: String = (" [" + ", ".join(extra_notes) + "]") if not extra_notes.is_empty() else ""
		entry["status_note"] = "Estaba a %dm de la escena SIN coartada%s" % [dist_m, note_suffix]
		clues.append("%s admitió estar a %d m de la escena SIN coartada%s (%d%% sospecha)." % [witness.npc_name, dist_m, note_suffix, int(entry["score"])])
		if is_instance_valid(inv_npc):
			inv_npc._spawn_floating_text("📝⚠️ %s estaba a %dm sin coartada (%d%% sospecha)" % [witness.npc_name, dist_m, int(entry["score"])], Color.GOLD, -36.0)

static func _evaluate_player_inspection(vm: VillageManager, inv_npc: VillageNPC, player: Node2D, suspects: Dictionary, clues: Array, is_initial_interview: bool = false, case_dict: Dictionary = {}) -> void:
	if not suspects.has("Jugador") or not player:
		return
	var active_case: Dictionary = vm.active_royal_investigation if case_dict.is_empty() else case_dict
	var p_entry: Dictionary = suspects["Jugador"]
	var already_inspected: bool = bool(p_entry.get("interviewed", false))
	p_entry["interviewed"] = true
	if player.has_method("is_bloodstained") and bool(player.call("is_bloodstained")) and not bool(p_entry.get("caught_bloodstained", false)):
		p_entry["caught_bloodstained"] = true
		p_entry["score"] = int(p_entry.get("score", 16)) + 42
		p_entry["status_note"] = "¡Sorprendido con manchas de sangre fresca sin lavar!"
		clues.append("Inspección Forense: detectó manchas de sangre fresca en las manos y ropa del Forastero (+42% sospecha).")
		if is_instance_valid(inv_npc):
			inv_npc._spawn_floating_text("🩸🕵️‍♂️ ¡Tienes sangre fresca en las manos y la ropa!", Color.ORANGE_RED, -42.0)
	var p_hc: HealthComponent = player.get_node_or_null("HealthComponent")
	if p_hc and p_hc.has_fresh_combat_wounds_or_makeshift() and not bool(p_entry.get("caught_wounded", false)):
		p_entry["caught_wounded"] = true
		p_entry["score"] = int(p_entry.get("score", 16)) + 28
		p_entry["status_note"] = "Presenta heridas de combate recientes / vendaje rudimentario"
		clues.append("Inspección Médica: el Forastero tiene heridas recientes de pelea o vendajes improvisados (+28% sospecha).")
		if is_instance_valid(inv_npc):
			inv_npc._spawn_floating_text("🩹🕵️‍♂️ ¡Tienes heridas frescas de forcejeo o vendajes improvisados!", Color.ORANGE_RED, -40.0)
	var inv: SimpleInventory = player.get("inventory")
	if inv:
		if inv.has_item("royal_safe_conduct", 1) and not bool(p_entry.get("caught_with_safe_conduct", false)):
			p_entry["caught_with_safe_conduct"] = true
			p_entry["score"] = int(p_entry.get("score", 16)) + 75
			p_entry["status_note"] = "¡Porta el Salvoconducto Real robado!"
			clues.append("¡PRUEBA IRREFUTABLE! El Forastero lleva encima el Salvoconducto Real robado al mercader.")
			if is_instance_valid(inv_npc):
				inv_npc._spawn_floating_text("👑📜 ¡Llevas el Salvoconducto Real del difunto!", Color.ORANGE_RED, -42.0)
		var w_used: String = str(active_case.get("weapon_used", "")).to_lower()
		var eq_w: Variant = player.get("equipped_weapon")
		var holding_matching_weapon: bool = (("espada" in w_used or "cuchillo" in w_used) and eq_w == player.get("sword_weapon")) or ("martillo" in w_used and eq_w == player.get("hammer_weapon")) or ("hacha" in w_used and eq_w == player.get("axe_weapon")) or ("arco" in w_used and eq_w == player.get("bow_weapon")) or ("pico" in w_used and eq_w == player.get("pickaxe_weapon")) or ("hoz" in w_used and eq_w == player.get("sickle_weapon"))
		if w_used != "" and not already_inspected and holding_matching_weapon:
			p_entry["score"] = int(p_entry.get("score", 16)) + 16
			clues.append("El Forastero empuña abiertamente armamento compatible con la herida forense (%s)." % w_used)
	if not already_inspected and (vm.wanted_level > 0 or vm.player_in_jail or vm.player_being_escorted_to_jail or vm.player_arrests_count > 0 or vm.player_murder_warrants_count > 0 or vm.recent_breakins_count > 0):
		var police_add: int = 36 if (vm.player_in_jail or vm.player_murder_warrants_count > 0 or vm.player_arrests_count > 0) else 20
		p_entry["score"] = int(p_entry.get("score", 16)) + police_add
		p_entry["status_note"] = "Interrogado con antecedentes/arresto en la Comisaría"
		clues.append("Antecedentes directos o arresto en Comisaría (+%d%% sospecha)." % police_add)
	elif is_initial_interview and int(p_entry.get("score", 16)) < 40:
		p_entry["status_note"] = "Interrogado (%d%% sospecha)" % int(p_entry.get("score", 16))

## Resuelve el resultado de la rueda de diálogo de Defensa en Interrogatorio RPG (3 Rondas) ante el Comisario Vane o el Inquisidor Real Alistair
static func resolve_player_interrogation_outcome(vm: VillageManager, inv_npc: VillageNPC, player: Node2D, outcome_mode: String, correct_steps: int, penalty_acc: int) -> void:
	if inv_npc == null or player == null:
		return
	var is_royal: bool = (inv_npc.trade_role == VillageNPC.TradeRole.ROYAL_INVESTIGATOR and bool(vm.active_royal_investigation.get("active", false)))
	var active_case: Dictionary = vm.active_royal_investigation if is_royal else vm.active_sheriff_investigation
	if active_case.is_empty() or not bool(active_case.get("active", false)):
		return
	var suspects: Dictionary = active_case.get("suspects", {})
	var clues: Array = active_case.get("clues_log", [])
	if not suspects.has("Jugador"):
		return
	var p_entry: Dictionary = suspects["Jugador"]
	if not bool(p_entry.get("interviewed", false)):
		_evaluate_player_inspection(vm, inv_npc, player, suspects, clues, true, active_case)

	inv_npc._stop_crafting_bar()
	active_case["player_dialogue_opened"] = false
	if str(active_case.get("current_interview_target", "")) == "Jugador":
		active_case["current_interview_target"] = ""
		active_case["stage_timer"] = 0.0
		active_case["interviews_done"] = int(active_case.get("interviews_done", 0)) + 1
		active_case["interviews_done_today"] = int(active_case.get("interviews_done_today", 0)) + 1
	elif str(active_case.get("stage", "")) == "PLAYER_CHECK":
		active_case["stage"] = "VERDICT"
		active_case["stage_timer"] = 0.0

	if penalty_acc > 0:
		p_entry["score"] = int(p_entry.get("score", 16)) + penalty_acc
		p_entry["status_note"] = "Se contradijo en el interrogatorio (+%d%% sospecha)" % penalty_acc
		clues.append("Interrogatorio al Forastero: respuestas evasivas o contradictorias (+%d%% sospecha)." % penalty_acc)

	if bool(p_entry.get("caught_with_safe_conduct", false)):
		inv_npc._spawn_floating_text("👑📜 ¡Ninguna labia explica por qué llevas el Salvoconducto Real robado!", Color.ORANGE_RED, -44.0)
		active_case["stage"] = "VERDICT"
		return

	var inv: SimpleInventory = player.get("inventory")
	var charisma_bonus: float = float(player.call("get_skill_bonus", "charisma")) if player.has_method("get_skill_bonus") else 0.0
	var hunting_bonus: float = float(player.call("get_skill_bonus", "hunting")) if player.has_method("get_skill_bonus") else 0.0

	match outcome_mode:
		"r3_persuade":
			if correct_steps >= 2 and penalty_acc == 0:
				var had_blood_or_wound: bool = bool(p_entry.get("caught_bloodstained", false)) or bool(p_entry.get("caught_wounded", false))
				if not had_blood_or_wound:
					p_entry["score"] = maxi(6, int(p_entry.get("score", 16)) - 35)
					p_entry["persuaded_defense"] = true
					p_entry["status_note"] = "Defensa elocuente y coherente en interrogatorio (-35% sospecha)"
					clues.append("Interrogatorio al Forastero: defensa coherente y sin fisuras; redujo las sospechas (-35%).")
					inv_npc._spawn_floating_text("🗣️✅ «Tu declaración es sólida y coherente. Quedas descartado como sospechoso principal (-35%).»", Color.SPRING_GREEN, -44.0)
					vm._hint_player("🗣️✨ ¡Éxito de Persuasión en el Interrogatorio! Convenciste a %s con una secuencia de defensa impecable (-35%% sospecha)." % inv_npc.npc_name, player)
				else:
					var has_hunting_proof: bool = false
					if inv:
						for h_it in ["raw_meat", "leather", "fox_pelt", "antlers", "bones", "wood", "herbs"]:
							if inv.has_item(h_it, 1):
								has_hunting_proof = true
								break
					var base_ch: float = 0.28 if is_royal else 0.38
					var total_ch: float = clampf(base_ch + (0.20 if has_hunting_proof else 0.0) + charisma_bonus + hunting_bonus * 0.5, 0.15, 0.90)
					if randf() <= total_ch:
						p_entry["score"] = maxi(10, int(p_entry.get("score", 50)) - 45)
						p_entry["persuaded_defense"] = true
						p_entry["status_note"] = "Convenció al investigador de que su sangre/heridas eran de cazar (-45%)"
						clues.append("Persuasión exitosa: el Forastero justificó sus manchas/heridas como faena de caza en el bosque (-45% sospecha).")
						inv_npc._spawn_floating_text("🏹✅ «Acepto tu explicación: esas manchas parecen de faenar bestias en el bosque (-45% sospecha).»", Color.SPRING_GREEN, -44.0)
						vm._hint_player("🏹✨ ¡Persuasión crítica exitosa! Convenciste a %s de que tus manchas/heridas eran de cazar en el bosque (-45%% sospecha)." % inv_npc.npc_name, player)
					else:
						p_entry["score"] = int(p_entry.get("score", 40)) + 10
						p_entry["status_note"] = "No logró justificar sus manchas/heridas en el interrogatorio"
						clues.append("Interrogatorio: el investigador no creyó la excusa sobre las manchas de sangre/heridas (+10% sospecha).")
						inv_npc._spawn_floating_text("🤨🩸 «Buena historia sobre el bosque, pero esa sangre fresca sigue siendo muy sospechosa (+10%).»", Color.ORANGE, -44.0)
			else:
				p_entry["score"] = int(p_entry.get("score", 20)) + 12
				p_entry["status_note"] = "Alegato final fallido por contradicciones previas"
				clues.append("El Forastero intentó persuadir al investigador tras haberse contradicho (+12% sospecha).")
				inv_npc._spawn_floating_text("🤨📋 «Tu alegato final no se sostiene tras tus contradicciones anteriores (+12% sospecha).»", Color.ORANGE_RED, -44.0)
		"r3_bribe":
			if inv == null or inv.gold < 45:
				p_entry["score"] = int(p_entry.get("score", 20)) + 15
				inv_npc._spawn_floating_text("😠💰 «¿Intentas sobornarme sin tener siquiera 45 monedas de oro? (+15% sospecha)»", Color.ORANGE_RED, -44.0)
			elif is_royal:
				p_entry["score"] = int(p_entry.get("score", 20)) + 35
				p_entry["status_note"] = "¡Intentó sobornar al Inquisidor Real Alistair! (+35%)"
				clues.append("¡El Forastero intentó sobornar con oro al Inquisidor Real durante el interrogatorio! (+35% sospecha).")
				inv_npc._spawn_floating_text("⚖️😡 «¡¿Intentas comprar a la Inquisición Real?! ¡Eso confirma tu culpa! (+35% sospecha)»", Color.ORANGE_RED, -44.0)
			else:
				var bribe_ch: float = clampf(0.50 + charisma_bonus, 0.25, 0.90)
				if randf() <= bribe_ch:
					inv.add_gold(-45)
					inv_npc.personal_gold = maxi(0, inv_npc.personal_gold) + 45
					p_entry["score"] = maxi(8, int(p_entry.get("score", 30)) - 38)
					p_entry["status_note"] = "Acuerdo discreto en el interrogatorio (-38% sospecha)"
					clues.append("El Alguacil mayor dio por buena la declaración del Forastero tras un acuerdo discreto (-38% sospecha).")
					inv_npc._spawn_floating_text("💰🤫 «Haremos la vista gorda en el informe por esta vez... (-45 Oro, -38% sospecha)»", Color.GOLD, -44.0)
				else:
					p_entry["score"] = int(p_entry.get("score", 20)) + 22
					p_entry["status_note"] = "Intento de soborno policial rechazado (+22%)"
					clues.append("El Forastero intentó sobornar a la guardia durante su interrogatorio (+22% sospecha).")
					inv_npc._spawn_floating_text("😠🚓 «¡Guárdate tu oro! Anotaré este intento de soborno en el acta (+22% sospecha).»", Color.ORANGE_RED, -44.0)
		"r3_silent":
			if correct_steps >= 2 and penalty_acc == 0:
				p_entry["score"] = maxi(8, int(p_entry.get("score", 16)) - 12)
				inv_npc._spawn_floating_text("📝 «Anotada tu declaración. Seguiré investigando (-12% sospecha).»", Color.AQUA, -42.0)
			else:
				p_entry["score"] = int(p_entry.get("score", 16)) + 6
				inv_npc._spawn_floating_text("🤨 «Tu silencio tras esas respuestas deja muchas dudas (+6% sospecha).»", Color.GOLD, -42.0)

	if int(p_entry.get("score", 0)) >= 75:
		active_case["stage"] = "VERDICT"

static func _conclude_sheriff_investigation_verdict(vm: VillageManager, sheriff: VillageNPC) -> void:
	var suspects: Dictionary = vm.active_sheriff_investigation.get("suspects", {})
	var best_key: String = ""
	var best_score: int = -1
	var best_dist: float = 999999.0
	for k in suspects.keys():
		var se: Dictionary = suspects[k]
		var sc: int = int(se.get("score", 0))
		var kd: float = float(se.get("known_dist", -1.0))
		if kd < 0.0 and sc < 50:
			continue
		var dc: float = kd if kd >= 0.0 else 9999.0
		if sc > best_score or (sc == best_score and dc < best_dist):
			best_score = sc
			best_dist = dc
			best_key = str(k)
	vm.active_sheriff_investigation["active"] = false
	var v_name: String = str(vm.active_sheriff_investigation.get("victim_name", "Aldeano"))
	var p := vm.get_tree().get_first_node_in_group("player") as Node2D
	if best_key == "Jugador" and best_score >= 48:
		vm._mark_morgue_case_resolved(v_name, "Jugador (Declarado culpable por el Comisario Vane: %d%%)" % clampi(best_score, 48, 100))
		vm.wanted_level = clampi(vm.wanted_level + 2, 2, 5)
		vm.bounty_gold += 70
		vm.player_murder_warrants_count += 1
		var msg := "🚓⚖️ ¡Tras interrogar a la cadena de testigos del asesinato de %s, el Alguacil mayor Vane te declaró CULPABLE (%d%% sospecha)! (+70 Oro de multa)" % [v_name, clampi(best_score, 48, 100)]
		vm.crime_history.push_front(msg)
		_notify_inquisitor_of_police_crime(vm, msg, 45)
		if is_instance_valid(sheriff):
			sheriff._spawn_floating_text("🚓⚖️ ¡Orden de arresto contra el Forastero por el asesinato de %s!" % v_name, Color.ORANGE_RED, -42.0)
			if p:
				sheriff._last_seen_player_pos = p.global_position
				sheriff._police_alerted_timer = 45.0
		vm._hint_player(msg, p)
	elif best_key != "" and best_key != "Jugador" and best_score >= 52:
		vm._mark_morgue_case_resolved(v_name, "%s (Arrestado por el Comisario Vane: %d%%)" % [best_key, best_score])
		var sc_npc: VillageNPC = vm._find_npc_by_name(best_key)
		if is_instance_valid(sheriff) and is_instance_valid(sc_npc) and not sc_npc.is_dead:
			vm.active_sheriff_investigation["active"] = true
			vm.active_sheriff_investigation["stage"] = "ARRESTING_NPC"
			vm.active_sheriff_investigation["scapegoat_key"] = best_key
			vm.active_sheriff_investigation["handcuffed_npc"] = false
			vm.active_sheriff_investigation["stage_timer"] = 0.0
			sheriff._spawn_floating_text("🚓⛓️ ¡Las pruebas apuntan a %s (%d%%)! ¡Voy a arrestarlo y llevarlo a la Celda!" % [best_key, best_score], Color.GOLD, -40.0)
			vm._hint_player("🚓⛓️ El Alguacil mayor Vane concluyó su investigación por la muerte de %s: las pistas señalan a %s (%d%% sospecha) y va en persona a arrestarlo y encerrarlo en la Celda." % [v_name, best_key, best_score], p)
			return
		if is_instance_valid(sheriff):
			sheriff._spawn_floating_text("🚓📋 Investigación cerrada: las pruebas apuntan a %s (%d%%)." % [best_key, best_score], Color.GOLD, -40.0)
		vm._hint_player("🚓📋 El Alguacil mayor Vane concluyó sus 5 interrogatorios por la muerte de %s: las pistas señalan a %s (%d%% sospecha)." % [v_name, best_key, best_score], p)
	else:
		vm._mark_morgue_case_resolved(v_name, "Caso Archivado por el Comisario Vane (Sin pruebas)")
		if is_instance_valid(sheriff):
			sheriff._spawn_floating_text("🚓📋 Sin pruebas suficientes tras interrogar a los testigos cercanos.", Color.LIGHT_GRAY, -38.0)
		vm._hint_player("🚓📋 El Alguacil mayor Vane archivó sin cargos la investigación local de %s (ningún testigo te situó como culpable)." % v_name, p)

	_check_and_start_next_morgue_sheriff_case(vm)

## J2: marca resuelto el registro de la morgue sin repetir la línea de la crónica.
static func _resolve_quietly(vm: VillageManager, victim_name: String, cause: String) -> void:
	for rec in vm.morgue_active_corpses:
		if str(rec.get("victim_name", "")) == victim_name and not bool(rec.get("case_resolved", false)):
			rec["added_total_hours"] = (WorldClock.current_day if WorldClock else 1) * 24 + (WorldClock.current_hour if WorldClock else 12)
			rec["case_resolved"] = true
			rec["suspect"] = "Sin crimen: %s" % VillageNPC.natural_death_text(cause)
	for rec2 in vm.corpse_records:
		if str(rec2.get("victim_name", "")) == victim_name:
			rec2["case_resolved"] = true
			rec2["suspect"] = "Sin crimen: %s" % VillageNPC.natural_death_text(cause)

static func _check_and_start_next_morgue_sheriff_case(vm: VillageManager) -> void:
	for next_rec in vm.morgue_active_corpses:
		var next_v_name: String = str(next_rec.get("victim_name", ""))
		if next_v_name != "" and not bool(next_rec.get("case_resolved", true)):
			var next_c: VillageNPC = vm._find_corpse_npc_by_name(next_v_name)
			if is_instance_valid(next_c) and next_c.trade_role != VillageNPC.TradeRole.TRAVELING_MERCHANT:
				var dp := Vector2(float(next_rec.get("death_pos_x", next_c.death_world_pos.x)), float(next_rec.get("death_pos_y", next_c.death_world_pos.y)))
				start_sheriff_investigation(vm, next_c, dp, str(next_rec.get("cause_of_death", next_c.last_hit_weapon_name)), str(next_rec.get("discoverer_name", "")), int(next_rec.get("death_mins", 0)))
				break

## Permite al jugador intervenir durante el Juicio Público en la Plaza Central (`PUBLIC_TRIAL_PLAZA` / `HUNTING_SCAPEGOAT`)
static func resolve_public_trial_intervention(vm: VillageManager, inv_npc: VillageNPC, player: Node2D, mode: String) -> void:
	if inv_npc == null or player == null or vm.active_royal_investigation.is_empty() or not bool(vm.active_royal_investigation.get("active", false)):
		return
	var stg: String = str(vm.active_royal_investigation.get("stage", ""))
	if not (stg in ["PUBLIC_TRIAL_PLAZA", "HUNTING_SCAPEGOAT"]):
		return
	var sc_key: String = str(vm.active_royal_investigation.get("scapegoat_key", ""))
	var scapegoat: VillageNPC = vm._find_npc_by_name(sc_key)
	var sc_name: String = scapegoat.npc_name if is_instance_valid(scapegoat) else sc_key
	var royal_v_name: String = str(vm.active_royal_investigation.get("victim_name", "Mercader Real"))
	inv_npc._stop_crafting_bar()

	if mode == "confess":
		if is_instance_valid(scapegoat):
			scapegoat.modify_affinity(60)
			scapegoat.add_thought("¡El Forastero confesó para salvarme la vida en el Juicio Público! (+60)", 60.0)
			scapegoat._spawn_floating_text("😭🙏 ¡Gracias por salvarme la vida en el patíbulo!", Color.SPRING_GREEN, -42.0)
			if scapegoat.family_id != "none":
				vm.modify_family_reputation(scapegoat.family_id, 50, "Salvó a " + sc_name + " en el Juicio Público", scapegoat)
		vm.active_royal_investigation["verdict_target"] = "Jugador (Confesión en Juicio Público)"
		vm.active_royal_investigation["verdict_reason"] = "Confesó públicamente en la Plaza Central para salvar a " + sc_name
		vm._mark_morgue_case_resolved(royal_v_name, "Jugador (Confesión en Juicio Público)")
		vm.active_royal_investigation["stage"] = "HUNTING_PLAYER"
		vm.active_royal_investigation["stage_timer"] = 0.0
		vm.wanted_level = 5
		vm.bounty_gold += 250
		vm.is_resisting_arrest = true
		inv_npc.is_hostile = true
		inv_npc.add_to_group("enemies")
		inv_npc._last_seen_player_pos = player.global_position
		inv_npc._police_alerted_timer = 65.0
		vm.alert_police_to_resist(player)
		inv_npc._spawn_floating_text("⚖️🗡️ ¡Soltad a %s! ¡El Forastero acaba de confesar el crimen!" % sc_name, Color.ORANGE_RED, -46.0)
		vm._hint_player("⚖️✋ ¡Confesaste en el Juicio Público! Salvaste la vida de %s (+60 Afinidad), pero el Inquisidor Real Alistair y la Guardia van ahora a por ti." % sc_name, player)
	elif mode == "clemency":
		var charisma_bonus: float = float(player.call("get_skill_bonus", "charisma")) if player.has_method("get_skill_bonus") else 0.0
		var charisma_lvl: int = int(player.call("get_skill_level", "charisma")) if player.has_method("get_skill_level") else 1
		var clem_chance: float = 1.0 if charisma_lvl >= 3 else clampf(0.45 + charisma_bonus * 2.0, 0.35, 0.95)
		if randf() <= clem_chance:
			if is_instance_valid(scapegoat):
				scapegoat.modify_affinity(45)
				scapegoat.add_thought("Defendido con elocuencia en el Juicio Público (+45)", 45.0)
				scapegoat._spawn_floating_text("😭🙌 ¡Estoy libre! ¡Tu alegato me ha salvado la vida!", Color.SPRING_GREEN, -42.0)
				if scapegoat.family_id != "none":
					vm.modify_family_reputation(scapegoat.family_id, 35, "Logró el indulto de " + sc_name + " en el Juicio Público", scapegoat)
			vm.active_royal_investigation["verdict_target"] = "Indultado en Juicio Público (" + sc_name + ")"
			vm.active_royal_investigation["verdict_reason"] = "Sentencia conmutada por duda razonable tras alegato público."
			vm._mark_morgue_case_resolved(royal_v_name, "Caso Archivado tras Alegato en Juicio Público")
			vm.active_royal_investigation["stage"] = "DEPARTING"
			vm.active_royal_investigation["stage_timer"] = 0.0
			inv_npc._spawn_floating_text("⚖️📜 «Tu alegato demuestra que las pruebas contra %s son circunstanciales. Conmuto la pena y regreso a la Corte.»" % sc_name, Color.AQUA, -46.0)
			vm._hint_player("🗣️⚖️ ¡INDULTO LOGRADO EN LA PLAZA! Convenciste al Inquisidor Real de que las pruebas contra %s no eran concluyentes (+45 Afinidad)." % sc_name, player)
		else:
			inv_npc._spawn_floating_text("⚖️😠 «¡Silencio en la plaza! Tus palabras no bastan para anular las pruebas contra %s.»" % sc_name, Color.ORANGE_RED, -44.0)
			vm._hint_player("⚖️❌ Tu alegato verbal no bastó para frenar al Inquisidor (Puedes pagar la Fianza Real de Indulto de 60 Oro o confesar).", player)
	elif mode == "bail_innocent":
		var inv: SimpleInventory = player.get("inventory")
		if inv == null or inv.gold < 60:
			inv_npc._spawn_floating_text("⚖️💰 «Se requieren 60 monedas de Oro de Fianza Real para conmutar la pena capital.»", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-60)
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + 60 # Regla 1: la fianza va a las arcas
		if is_instance_valid(scapegoat):
			scapegoat.modify_affinity(55)
			scapegoat.add_thought("Pagó 60 Oro de Fianza Real para salvarme del patíbulo (+55)", 55.0)
			scapegoat._spawn_floating_text("😭💰 ¡Jamás olvidaré que pagaste mi indulto real!", Color.GOLD, -42.0)
			if scapegoat.family_id != "none":
				vm.modify_family_reputation(scapegoat.family_id, 45, "Pagó Fianza Real por la vida de " + sc_name, scapegoat)
		vm.active_royal_investigation["verdict_target"] = "Clemencia por Fianza Real (" + sc_name + ")"
		vm.active_royal_investigation["verdict_reason"] = "Pena conmutada mediante Fianza Real de 60 Oro."
		vm._mark_morgue_case_resolved(royal_v_name, "Cerrado por Fianza Real de Indulto (60 Oro)")
		vm.active_royal_investigation["stage"] = "DEPARTING"
		vm.active_royal_investigation["stage_timer"] = 0.0
		inv_npc._spawn_floating_text("⚖️💰 «La Corona acepta las 60 monedas de Fianza Real. %s queda en libertad.»" % sc_name, Color.GOLD, -46.0)
		vm._hint_player("⚖️💰 ¡Pagaste 60 Oro de Fianza Real en la Plaza! Salvaste la vida de %s (+55 Afinidad) y el Inquisidor Real se retira." % sc_name, player)

## FILOSOFÍA DEL INQUISIDOR REAL (Etapa 4):
## Condena al sospechoso con mayor puntuación forense real (`>= 35%`), desempatando por quién estaba más cerca de la escena.
## Si NINGÚN sospechoso supera el umbral mínimo de pruebas (`< 35%`), archiva el caso por falta de pruebas sin ejecutar inocentes al azar.
static func _conclude_royal_investigation_with_mandatory_verdict(vm: VillageManager, inv_npc: VillageNPC) -> void:
	var suspects: Dictionary = vm.active_royal_investigation.get("suspects", {})
	var best_key: String = ""
	var best_score: int = -1
	var best_dist: float = 999999.0

	for k in suspects.keys():
		var s_entry: Dictionary = suspects[k]
		var is_p: bool = bool(s_entry.get("is_player", false))
		var sc: int = int(s_entry.get("score", 0))
		var kd: float = float(s_entry.get("known_dist", s_entry.get("dist_to_crime", -1.0)))
		var dist_c: float = kd if kd >= 0.0 else 9999.0
		if is_p:
			if sc < 45 and kd < 0.0:
				continue
		else:
			var npc_node: VillageNPC = vm._find_npc_by_name(str(k))
			var real_d: float = float(s_entry.get("mem_dist_to_crime", dist_c))
			if npc_node == null or npc_node.is_dead or real_d > 360.0 or sc < 35:
				continue
		if sc >= 35 and (sc > best_score or (sc == best_score and dist_c < best_dist)):
			best_score = sc
			best_dist = dist_c
			best_key = str(k)

	var p = vm.get_tree().get_first_node_in_group("player") as Node2D
	var royal_v_name: String = str(vm.active_royal_investigation.get("victim_name", ""))
	if best_key == "" or best_score < 35:
		vm.active_royal_investigation["verdict_target"] = "Caso Archivado (Sin Pruebas >= 35%)"
		vm.active_royal_investigation["verdict_reason"] = "Ningún sospechoso superó el umbral mínimo del 35% de sospecha forense."
		vm.active_royal_investigation["stage"] = "DEPARTING"
		vm.active_royal_investigation["stage_timer"] = 0.0
		vm._mark_morgue_case_resolved(royal_v_name, "Caso Archivado por el Inquisidor Real (Sin pruebas >= 35%)")
		if is_instance_valid(inv_npc):
			inv_npc._spawn_floating_text("⚖️📜 Sin pruebas concluyentes (<35%): No ejecutaré a un inocente al azar. Regreso a la Corte.", Color.AQUA, -44.0)
		vm._hint_player("⚖️👑 ¡EXPEDIENTE ARCHIVADO POR FALTA DE PRUEBAS! Ningún sospechoso superó el 35% de sospecha forense ni se halló el Salvoconducto Real. El Inquisidor Real Alistair se retira sin ejecutar a ningún inocente.", p)
		return

	var chosen: Dictionary = suspects.get(best_key, {})
	var chosen_name: String = str(chosen.get("name", best_key))
	vm.active_royal_investigation["verdict_target"] = chosen_name
	vm._mark_morgue_case_resolved(royal_v_name, "Veredicto Real: %s (%d%%)" % [chosen_name, clampi(best_score, 35, 100)])

	if bool(chosen.get("is_player", false)):
		vm.active_royal_investigation["verdict_reason"] = "Culpable por deducción de pruebas y testimonios (%d%% de probabilidad)." % clampi(best_score, 50, 100)
		if vm.player_in_jail or vm.player_being_escorted_to_jail:
			vm.bounty_gold += 250
			vm.active_royal_investigation["stage"] = "DEPARTING"
			inv_npc._spawn_floating_text("⚖️👑 ¡El Forastero es el asesino y ya está tras las rejas! (+250 Oro de condena real)", Color.GOLD, -44.0)
			vm._hint_player("⚖️👑 ¡VEREDICTO DEL INQUISIDOR REAL ALISTAIR! Tras interrogar a todo el pueblo, confirmó tu culpabilidad mientras estabas en la celda (+250 Oro a tu fianza). El Inquisidor regresa a la Corte.", p)
		else:
			vm.active_royal_investigation["stage"] = "HUNTING_PLAYER"
			vm.wanted_level = 5
			vm.bounty_gold += 250
			vm.is_resisting_arrest = true
			inv_npc.is_hostile = true
			inv_npc.add_to_group("enemies")
			if p:
				inv_npc._last_seen_player_pos = p.global_position
				inv_npc._police_alerted_timer = 65.0
				vm.alert_police_to_resist(p)
				vm._hint_player("⚖️👑 ¡VEREDICTO DEL INQUISIDOR REAL ALISTAIR! Tras interrogar a todo el pueblo, te ha declarado CULPABLE del asesinato de %s (%d%% sospecha). ¡Orden de captura inmediata (+250 Oro)!" % [str(vm.active_royal_investigation.get("victim_name", "Mercader")), clampi(best_score, 50, 100)], p)
			inv_npc._spawn_floating_text("⚖️🗡️ ¡EN NOMBRE DEL REY, TÚ ASESINASTE AL MERCADER!", Color.ORANGE_RED, -44.0)
	else:
		var sc_dist_m: int = int(round(float(chosen.get("known_dist", chosen.get("mem_dist_to_crime", 120.0))) / 16.0))
		vm.active_royal_investigation["verdict_reason"] = "Condenado por estar a %d m de la escena sin coartada (%d%% sospecha)." % [sc_dist_m, clampi(best_score, 35, 95)]
		vm.active_royal_investigation["scapegoat_key"] = best_key
		vm.active_royal_investigation["stage"] = "HUNTING_SCAPEGOAT"
		vm.active_royal_investigation["stage_timer"] = 0.0
		inv_npc._spawn_floating_text("⚖️📜 ¡Orden de ejecución contra %s (estaba a %dm de la escena sin coartada)!" % [chosen_name, sc_dist_m], Color.GOLD, -44.0)
		vm._hint_player("⚖️👑 ¡VEREDICTO EMITIDO! El Inquisidor Real Alistair se dirige a buscar y ejecutar personalmente a %s (estaba a %d m de la escena del crimen sin coartada: %d%% sospecha)." % [chosen_name, sc_dist_m, clampi(best_score, 35, 95)], p)

static func get_royal_investigator_status_text(vm: VillageManager) -> String:
	if vm.active_royal_investigation.is_empty():
		return "Cerrado"
	var stg: String = str(vm.active_royal_investigation.get("stage", "CRIME_SCENE"))
	var done_i: int = int(vm.active_royal_investigation.get("interviews_done", 0))
	var max_i: int = int(vm.active_royal_investigation.get("max_interviews", 18))
	var d_inv: int = int(vm.active_royal_investigation.get("days_investigating", 1))
	var m_days: int = int(vm.active_royal_investigation.get("max_days", 18))
	match stg:
		"CRIME_SCENE": return "Inspeccionando Escena (Día %d/%d)" % [d_inv, m_days]
		"MORGUE": return "Examinando Autopsia y Comisaría (Día %d/%d)" % [d_inv, m_days]
		"INITIAL_PLAYER_INTERVIEW": return "Yendo a Interrogarte (Día %d/%d)" % [d_inv, m_days]
		"INTERVIEWS": return "Interrogando Pueblo (%d/%d · Día %d/%d)" % [done_i, max_i, d_inv, m_days]
		"DEEP_FORENSICS": return "Cruzando Coartadas (%d/%d · Día %d/%d)" % [done_i, max_i, d_inv, m_days]
		"PLAYER_CHECK": return "Inspección Final al Forastero"
		"HUNTING_SCAPEGOAT": return "Llevando Arrestado a " + str(vm.active_royal_investigation.get("verdict_target", "Sospechoso"))
		"PUBLIC_TRIAL_PLAZA": return "Juicio Público en la Plaza: " + str(vm.active_royal_investigation.get("verdict_target", "Sospechoso"))
		"HUNTING_PLAYER": return "Persiguiendo al Culpable (Jugador)"
		"VERDICT", "DEPARTING": return "Veredicto: " + str(vm.active_royal_investigation.get("verdict_target", "Emitido"))
	return "Investigando"

static func get_royal_investigation_dialogue_summary(vm: VillageManager) -> String:
	if vm.active_royal_investigation.is_empty():
		return "📋 EXPEDIENTE REAL: Caso cerrado. Ningún crimen contra la Corona queda sin culpable."
	var v_name: String = str(vm.active_royal_investigation.get("victim_name", "Mercader Real"))
	var w_used: String = str(vm.active_royal_investigation.get("weapon_used", "Desconocida"))
	var done_i: int = int(vm.active_royal_investigation.get("interviews_done", 0))
	var max_i: int = int(vm.active_royal_investigation.get("max_interviews", 18))
	var d_inv: int = int(vm.active_royal_investigation.get("days_investigating", 1))
	var m_days: int = int(vm.active_royal_investigation.get("max_days", 18))
	var suspects: Dictionary = vm.active_royal_investigation.get("suspects", {})

	var top_name: String = "Sin determinar (reuniendo testimonios)"
	var top_score: int = 10
	var top_dist: float = 999999.0
	for k in suspects.keys():
		var se: Dictionary = suspects[k]
		var sc: int = int(se.get("score", 0))
		var kd: float = float(se.get("known_dist", se.get("dist_to_crime", -1.0)))
		var dc: float = kd if kd >= 0.0 else 9999.0
		if not bool(se.get("is_player", false)) and kd > 360.0:
			continue
		if sc > top_score or (sc == top_score and sc > 10 and dc < top_dist):
			top_score = sc
			top_dist = dc
			top_name = str(se.get("name", k))

	var dist_txt: String = ("a %d m de la escena" % int(round(top_dist / 16.0))) if top_dist < 9000.0 else "paradero aún no confirmado"
	var clues: Array = vm.active_royal_investigation.get("clues_log", [])
	var last_clue: String = str(clues[clues.size() - 1]) if not clues.is_empty() else "Reuniendo testimonios."
	return "📋 EXPEDIENTE DEL INQUISIDOR REAL (Víctima: %s | Arma Forense: %s)\n• Día %d de %d (Plazo máx. antes de fin de embargo) | Pueblo interrogado: %d/%d habitantes\n• Principal sospechoso actual: %s (%d%% prob. · %s)\n• Última pista: %s" % [
		v_name, w_used, d_inv, m_days, done_i, max_i, top_name, clampi(top_score, 10, 100), dist_txt, last_clue
	]

static func get_royal_investigation_detailed_suspects_text(vm: VillageManager) -> String:
	if vm.active_royal_investigation.is_empty():
		return "📋 EXPEDIENTE CERRADO."
	var suspects: Dictionary = vm.active_royal_investigation.get("suspects", {})
	var done_i: int = int(vm.active_royal_investigation.get("interviews_done", 0))
	var max_i: int = int(vm.active_royal_investigation.get("max_interviews", 18))
	var d_inv: int = int(vm.active_royal_investigation.get("days_investigating", 1))
	var m_days: int = int(vm.active_royal_investigation.get("max_days", 18))
	var arr: Array[Dictionary] = []
	for k in suspects.keys():
		arr.append(suspects[k])
	arr.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa: int = int(a.get("score", 0))
		var sb: int = int(b.get("score", 0))
		if sa != sb:
			return sa > sb
		var da: float = float(a.get("known_dist", -1.0))
		var db: float = float(b.get("known_dist", -1.0))
		return (da if da >= 0.0 else 9999.0) < (db if db >= 0.0 else 9999.0)
	)
	var lines: Array[String] = [
		"📋 REGISTRO INQUISITORIAL DE SOSPECHOSOS Y COARTADAS (Día %d/%d · %d/%d Interrogados):" % [d_inv, m_days, done_i, max_i]
	]
	var limit_cnt: int = mini(7, arr.size())
	for i in range(limit_cnt):
		var s: Dictionary = arr[i]
		var s_name: String = str(s.get("name", ""))
		var sc: int = int(s.get("score", 0))
		var kd: float = float(s.get("known_dist", s.get("dist_to_crime", -1.0)))
		var dist_tag: String = ("A %d m de la escena" % int(round(kd / 16.0))) if kd >= 0.0 else "Paradero desconocido"
		var iv_tag: String = "✅Interrogado" if bool(s.get("interviewed", false)) else "⏳Pendiente"
		var note: String = str(s.get("status_note", ""))
		if str(s.get("motive_note", "")) != "":
			note += " · Móvil: " + str(s.get("motive_note", ""))
		lines.append("• #%d %s — %d%% sospecha | %s | [%s] %s" % [i + 1, s_name, sc, dist_tag, iv_tag, note])
	return "\n".join(lines)

# ==============================================================================
# BLOQUE B2: CALABOZO DE VERDAD (Vecinos detenidos en la celda de la comisaría)
# ==============================================================================
const CELL_POS: Vector2 = Vector2(886.0, 172.0)
const CELL_RECT: Rect2 = Rect2(864.0, 156.0, 44.0, 32.0)
const CELL_GATE_POS: Vector2 = Vector2(902.0, 152.0)
const CELL_OUTSIDE_POS: Vector2 = Vector2(910.0, 148.0)

static func _now_total_hours() -> int:
	if WorldClock == null:
		return 12
	return int(WorldClock.current_day) * 24 + int(WorldClock.current_hour)

static func inmates(vm: VillageManager) -> Dictionary:
	if vm == null:
		return {}
	if not (vm.town_state.get("jail_inmates", null) is Dictionary):
		vm.town_state["jail_inmates"] = {}
	return vm.town_state["jail_inmates"]

static func is_npc_jailed(vm: VillageManager, npc: VillageNPC) -> bool:
	if vm == null or npc == null or not is_instance_valid(npc):
		return false
	return inmates(vm).has(npc.get_person_key())

static func get_inmate_record(vm: VillageManager, npc: VillageNPC) -> Dictionary:
	if not is_npc_jailed(vm, npc):
		return {}
	return inmates(vm).get(npc.get_person_key(), {})

static func _pick_arresting_officer(vm: VillageManager, near_pos: Vector2) -> VillageNPC:
	var best: VillageNPC = null
	var best_d: float = 999999.0
	if vm == null or not vm.is_inside_tree():
		return null
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v: VillageNPC = n as VillageNPC
			if v.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD] and v.is_conscious():
				var d: float = near_pos.distance_to(v.global_position)
				if d < best_d:
					best_d = d
					best = v
	return best

static func arrest_npc(vm: VillageManager, npc: VillageNPC, officer: VillageNPC = null, reason: String = "delito", hours: int = 36, bail: int = 35) -> bool:
	if vm == null or npc == null or not is_instance_valid(npc) or npc.is_dead:
		return false
	if officer == null or not is_instance_valid(officer):
		officer = _pick_arresting_officer(vm, npc.global_position)
	var key: String = npc.get_person_key()
	npc.end_errand()
	npc.end_live_fight()
	npc._clear_combat_hostility()
	npc.is_sleeping = false
	npc.sedated_timer = 0.0
	npc.elevation_level = 0
	var already_at_cell: bool = npc.global_position.distance_to(CELL_POS) <= 28.0
	inmates(vm)[key] = {
		"key": key,
		"name": npc.npc_name,
		"reason": reason,
		"officer_key": officer.get_person_key() if officer != null and is_instance_valid(officer) else "",
		"status": "jailed" if already_at_cell else "escorting",
		"hours_left": clampi(hours, 24, 48),
		"bail_gold": maxi(15, bail),
		"last_escape_fail_hour": -99,
	}
	if already_at_cell:
		npc.global_position = CELL_POS
		npc.velocity = Vector2.ZERO
	vm.set_jail_cell_gate_locked(true)
	if officer != null and is_instance_valid(officer):
		officer._spawn_floating_text("🚓⛓️ «¡%s, quedas detenido por %s! Al calabozo.»" % [npc.npc_name, reason], Color(0.65, 0.85, 1.0), -42.0)
	npc._spawn_floating_text("⛓️😤 «¡Malditos barrotes...!»", Color.ORANGE_RED, -38.0)
	vm.VillageChronicle.add(vm, "npc_arrested", "%s fue llevado al calabozo por %s (%dh de condena)" % [npc.npc_name, reason, clampi(hours, 24, 48)], true)
	return true

static func process_npc_jail_step(vm: VillageManager, npc: VillageNPC, delta: float) -> bool:
	if vm == null or npc == null or not is_instance_valid(npc) or npc.is_dead:
		return false
	var map: Dictionary = inmates(vm)
	if map.is_empty():
		return false
	var k: String = npc.get_person_key()
	if map.has(k):
		var rec: Dictionary = map[k]
		npc.is_sleeping = false
		npc.elevation_level = 0
		npc._stop_crafting_bar()
		var cell_off := Vector2(float((absi(k.hash()) % 3) - 1) * 14.0, float((absi(k.hash() / 3) % 2) * 2 - 1) * 6.0)
		var my_cell_pos: Vector2 = CELL_POS + cell_off
		if str(rec.get("status", "escorting")) == "escorting":
			if npc.global_position.distance_to(my_cell_pos) > 22.0:
				npc._move_towards_point(my_cell_pos, 66.0, delta)
			else:
				rec["status"] = "jailed"
				npc.global_position = my_cell_pos
				npc.velocity = Vector2.ZERO
				vm.set_jail_cell_gate_locked(true)
				npc._spawn_floating_text("🔒⛓️ Encerrado en el calabozo (%dh)" % int(rec.get("hours_left", 24)), Color(0.75, 0.85, 1.0), -40.0)
		else:
			if not CELL_RECT.has_point(_AN_SITIOS.desmover(npc.global_position)):
				npc.global_position = my_cell_pos
			npc.velocity = Vector2.ZERO
			vm.set_jail_cell_gate_locked(true)
		npc._finish_frame_movement(delta)
		return true
	if npc.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR]:
		for inm_k in map.keys():
			var rec_o: Dictionary = map[inm_k]
			if str(rec_o.get("status", "")) == "escorting" and str(rec_o.get("officer_key", "")) == k:
				if npc.global_position.distance_to(CELL_POS) > 26.0:
					npc._move_towards_point(CELL_POS, 68.0, delta)
					npc._finish_frame_movement(delta)
					return true
				else:
					var pris = vm._get_npcs_by_person_key().get(str(inm_k), null)
					if pris != null and is_instance_valid(pris) and pris.global_position.distance_to(CELL_POS) <= 42.0:
						rec_o["status"] = "jailed"
						pris.global_position = CELL_POS
						pris.velocity = Vector2.ZERO
						vm.set_jail_cell_gate_locked(true)
	return false

static func release_npc(vm: VillageManager, key: String, mode: String = "served") -> bool:
	if vm == null:
		return false
	var map: Dictionary = inmates(vm)
	if not map.has(key):
		return false
	var rec: Dictionary = map[key]
	map.erase(key)
	if map.is_empty() and not vm.player_in_jail:
		vm.set_jail_cell_gate_locked(false)
	var npc: VillageNPC = vm._get_npcs_by_person_key().get(key, null)
	if npc != null and is_instance_valid(npc) and not npc.is_dead:
		if CELL_RECT.has_point(_AN_SITIOS.desmover(npc.global_position)) or _AN_SITIOS.desmover(npc.global_position).distance_to(CELL_POS) <= 32.0:
			npc.global_position = CELL_OUTSIDE_POS
		npc.velocity = Vector2.ZERO
		match mode:
			"bailed":
				npc._spawn_floating_text("⚖️🔓 «¡Gracias por pagar mi fianza! No lo olvidaré.»", Color.GOLD, -42.0)
			"escaped":
				npc._spawn_floating_text("🗝️🏃 «¡Rápido, antes de que nos vean!»", Color.SPRING_GREEN, -42.0)
			_:
				npc._spawn_floating_text("🔓 «Cumplida la condena... vuelvo a mi vida.»", Color.AQUA, -40.0)
				vm.VillageChronicle.add(vm, "npc_released", "%s salió del calabozo tras cumplir su condena" % str(rec.get("name", npc.npc_name)), false)
	return true

static func on_hour(vm: VillageManager) -> void:
	if vm == null:
		return
	var map: Dictionary = inmates(vm)
	if map.is_empty():
		return
	var to_release: Array[String] = []
	for k in map.keys():
		var rec: Dictionary = map[k]
		var left: int = int(rec.get("hours_left", 24)) - 1
		rec["hours_left"] = left
		if left <= 0:
			to_release.append(str(k))
	for k_rel in to_release:
		release_npc(vm, k_rel, "served")

static func after_load(vm: VillageManager) -> void:
	if vm == null:
		return
	var map: Dictionary = inmates(vm)
	if not map.is_empty():
		vm.set_jail_cell_gate_locked(true)
		var by_key: Dictionary = vm._get_npcs_by_person_key()
		for k in map.keys():
			var rec: Dictionary = map[k]
			var n: VillageNPC = by_key.get(str(k), null)
			if n != null and is_instance_valid(n) and not n.is_dead and str(rec.get("status", "")) == "jailed":
				n.global_position = CELL_POS

static func pay_npc_bail(vm: VillageManager, officer: VillageNPC, key: String, inv) -> bool:
	if vm == null or inv == null:
		return false
	var map: Dictionary = inmates(vm)
	if not map.has(key):
		return false
	var rec: Dictionary = map[key]
	var cost: int = maxi(15, int(rec.get("bail_gold", 35)))
	if int(inv.gold) < cost:
		if officer != null and is_instance_valid(officer):
			officer._spawn_floating_text("❌ «La fianza de %s son %d monedas de oro.»" % [str(rec.get("name", key)), cost], Color.ORANGE_RED, -42.0)
		return false
	inv.add_gold(-cost)
	vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + cost # Regla 1: el dinero va a las arcas
	var pris: VillageNPC = vm._get_npcs_by_person_key().get(key, null)
	release_npc(vm, key, "bailed")
	if pris != null and is_instance_valid(pris) and not pris.is_dead:
		pris.modify_affinity(22)
		pris.add_thought("El forastero pagó mi fianza en la comisaría (+18)", 18.0)
	if officer != null and is_instance_valid(officer):
		officer._spawn_floating_text("⚖️🔓 «Fianza abonada a las arcas (+%d Oro). %s queda en libertad.»" % [cost, str(rec.get("name", key))], Color.GOLD, -44.0)
	vm.VillageChronicle.add(vm, "npc_bail_paid", "Pagaste la fianza de %s (%d de oro a las arcas municipales)" % [str(rec.get("name", key)), cost], true)
	return true

static func has_lockpick_or_key(player: Node, inv) -> bool:
	if player != null and player.has_method("has_master_lockpick") and bool(player.call("has_master_lockpick")):
		return true
	if inv != null and inv.has_method("has_item"):
		for it_id in ["master_lockpick", "lockpick", "iron_key", "skeleton_key", "jail_key"]:
			if bool(inv.call("has_item", it_id, 1)):
				return true
	return false

static func help_npc_escape(vm: VillageManager, npc: VillageNPC, inv = null, force_roll: float = -1.0) -> String:
	if vm == null or npc == null or not is_npc_jailed(vm, npc):
		return ""
	var pl: Node2D = vm.get_tree().get_first_node_in_group("player") as Node2D if vm.is_inside_tree() else null
	if pl != null and pl.global_position.distance_to(npc.global_position) > 95.0:
		npc._spawn_floating_text("⛓️ «Acércate a los barrotes si vas a abrir la cerradura.»", Color.ORANGE, -38.0)
		return ""
	if not has_lockpick_or_key(pl, inv):
		npc._spawn_floating_text("🗝️ «Necesitas una ganzúa o una llave para abrir esta reja.»", Color.ORANGE_RED, -40.0)
		return "no_tool"
	var rec: Dictionary = inmates(vm)[npc.get_person_key()]
	var cur_h: int = _now_total_hours()
	if int(rec.get("last_escape_fail_hour", -99)) == cur_h and force_roll < 0.0:
		npc._spawn_floating_text("⏳ «La cerradura sigue caliente; espera un poco antes de volver a intentarlo.»", Color.GOLD, -40.0)
		return "cooldown"
	# Comprobar riesgo de testigos en la misma planta con línea de visión
	var in_stealth: bool = pl != null and pl.has_method("is_stealthing") and bool(pl.call("is_stealthing"))
	var detect_rad: float = 60.0 if in_stealth else 125.0
	var witness: VillageNPC = null
	if vm.is_inside_tree():
		for n_w in vm.get_tree().get_nodes_in_group("village_npcs"):
			if n_w is VillageNPC and n_w != npc:
				var vw: VillageNPC = n_w as VillageNPC
				if not vw.is_conscious() or vw.elevation_level != 0 or vw.witness_silenced_player:
					continue
				if is_npc_jailed(vm, vw):
					continue
				if vw.global_position.distance_to(CELL_GATE_POS) <= detect_rad and (not vm.has_method("has_line_of_sight") or bool(vm.call("has_line_of_sight", vw.global_position, CELL_GATE_POS))):
					witness = vw
					break
	if witness != null:
		vm.wanted_level = clampi(int(vm.wanted_level) + 1, 1, 5)
		vm.bounty_gold += 30
		witness._spawn_floating_text("🚨⛓️ «¡Alto! ¡Está forzando el calabozo para sacar a %s!»" % npc.npc_name, Color.ORANGE_RED, -44.0)
	var roll: float = force_roll if force_roll >= 0.0 else randf()
	if roll > 0.78:
		rec["last_escape_fail_hour"] = cur_h
		if AudioManager:
			AudioManager.emit_noise(CELL_GATE_POS, 145.0, 0, "heavy_hit")
		npc._spawn_floating_text("🔒❌ «¡Chist, se ha atascado el pestillo! Espera un poco.»", Color.ORANGE, -40.0)
		return "failed"
	release_npc(vm, npc.get_person_key(), "escaped")
	npc.modify_affinity(28)
	npc.add_thought("El forastero me ayudó a escapar del calabozo (+22)", 22.0)
	vm.VillageChronicle.add(vm, "npc_jailbreak", "Ayudaste a %s a escapar del calabozo con ganzúa/llave" % npc.npc_name, witness != null)
	return "escaped_seen" if witness != null else "escaped"

static func add_dialogue_choices(vm: VillageManager, npc: VillageNPC, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null or npc == null:
		return
	if is_npc_jailed(vm, npc):
		var rec: Dictionary = get_inmate_record(vm, npc)
		var r_txt: String = str(rec.get("reason", "delito"))
		var h_left: int = maxi(1, int(rec.get("hours_left", 24)))
		var b_gold: int = maxi(15, int(rec.get("bail_gold", 35)))
		if diag.has("start") and diag["start"] is Dictionary:
			diag["start"]["text"] = "⛓️ «Me tienen encerrado en el calabozo por %s (%dh restantes de condena)... Puedes pagar mi fianza de %d de oro en la comisaría o abrir la reja cuando nadie mire.»" % [r_txt, h_left, b_gold]
		var pos_j: int = maxi(0, ch_arr.size() - 1)
		ch_arr.insert(pos_j, {
			"label": "🗝️ Ayudarle a escapar del calabozo (Ganzúa / Llave)",
			"next": "jail_escape_confirm",
		})
		diag["jail_escape_confirm"] = {
			"text": "«Si tienes una ganzúa o una llave maestra y vigilas que no mire ningún guardia, puedes abrir el cerrojo de los barrotes ahora mismo.»",
			"choices": [
				{"label": "🗝️ [Confirmar] Forzar el cerrojo y liberar a %s" % npc.npc_name, "action": "jail_escape_npc", "next": "END"},
				{"label": "Ahora no es seguro. [Volver]", "next": "start"},
			],
		}
	if npc.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD]:
		var map: Dictionary = inmates(vm)
		for k in map.keys():
			var rec_b: Dictionary = map[k]
			var nm: String = str(rec_b.get("name", k))
			var cost: int = maxi(15, int(rec_b.get("bail_gold", 35)))
			var r_b: String = str(rec_b.get("reason", "delito"))
			var node_id: String = "jail_bail_confirm_" + str(k)
			var pos_b: int = maxi(0, ch_arr.size() - 1)
			ch_arr.insert(pos_b, {
				"label": "⚖️ Pagar la fianza de %s (%d Oro)" % [nm, cost],
				"next": node_id,
			})
			diag[node_id] = {
				"text": "«%s cumple condena en el calabozo por %s (%dh restantes). Si abonas %d monedas de oro de fianza para las arcas municipales, le abriré la celda ahora mismo.»" % [nm, r_b, maxi(1, int(rec_b.get("hours_left", 24))), cost],
				"choices": [
					{"label": "🪙 [Confirmar] Pagar %d Oro de fianza por %s" % [cost, nm], "action": "jail_pay_bail:" + str(k), "next": "END"},
					{"label": "Lo pensaré. [Volver]", "next": "start"},
				],
			}

static func on_player_action(vm: VillageManager, npc: VillageNPC, action_str: String, inv = null) -> bool:
	if vm == null or npc == null:
		return false
	if action_str == "jail_escape_npc":
		return help_npc_escape(vm, npc, inv) in ["escaped", "escaped_seen"]
	if action_str.begins_with("jail_pay_bail:"):
		var k: String = action_str.trim_prefix("jail_pay_bail:")
		return pay_npc_bail(vm, npc, k, inv)
	return false
