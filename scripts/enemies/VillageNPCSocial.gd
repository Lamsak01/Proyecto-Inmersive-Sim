@tool
extends "res://scripts/enemies/VillageNPCBase.gd"
const _MARCA = preload("res://mapa/marca.gd")
const _EDIFICIO = preload("res://mapa/edificio.gd")
const _ZONA = preload("res://mapa/zona.gd") # la plaza va con su pieza de «Zonas» (mapa original ×5)
const _PLAZA_ORIGINAL := Vector2(465, 44) ## centro de la plaza en el mapa original: sitio de reserva
const _HOSPITAL_ID := "building_hospital"
const _CAMA_URGENCIAS_PLANO := Vector2(718.0, 136.0) ## cama de urgencias, en el plano del hospital
const _MORGUE_ENTREGA_PLANO := Vector2(745.0, 174.0) ## donde se dejan los cadáveres, en el plano del hospital
const _COMISARIA_ID := "building_police"
const _COMISARIA_PLANO := Rect2(832.0, 92.0, 166.0, 108.0) ## comisaría y calabozo, en su plano


func _finish_frame_movement(delta: float, apply_yield: bool = true) -> void:
	var _pt: int = Time.get_ticks_usec() if perf_on else 0
	if apply_yield:
		_apply_player_and_doorway_yield(delta)
	if perf_on: _pt = _perf_add("m_yield", _pt)
	var lod_k: float = _lod_k # V2: solo en los pasos simplificados de quien está lejos
	if lod_k > 1.0:
		velocity *= lod_k # V2: un paso de varios fotogramas recorre la distancia de todos ellos
	var prev_pos: Vector2 = global_position
	var cuerpo = get_meta("cuerpo3d") if has_meta("cuerpo3d") else null
	if is_instance_valid(cuerpo):
		cuerpo.destino_actor = _last_nav_dest # su cama o su silla no le cierran el paso
		cuerpo.mover(velocity, delta) # paso a 3D (opción B): el cuerpo anda, choca y escribe la posición en el mapa
	else:
		move_and_slide()
	if cuerpo == null and not is_sleeping and not is_at_poker_table and _cached_vm != null: # sin cuerpo: recolocar a mano como siempre
		var in_door: bool = _cached_vm.has_method("get_doorway_clearance_nudge") and (_cached_vm.call("get_doorway_clearance_nudge", global_position, 22.0) as Vector2).length_squared() > 0.01
		if not in_door:
			if global_position.distance_squared_to(prev_pos) > 0.001 and _cached_vm.has_method("sanitize_npc_separation_pos"):
				global_position = _cached_vm.call("sanitize_npc_separation_pos", prev_pos, global_position, int(elevation_level))
			elif _cached_vm.has_method("push_out_of_furniture"):
				global_position = _cached_vm.call("push_out_of_furniture", global_position, int(elevation_level))
	_enforce_npc_personal_space(delta)
	if perf_on: _pt = _perf_add("m_move_and_slide", _pt)
	if lod_k > 1.0:
		velocity /= lod_k
		_lod_k = 1.0
	if _cached_vm:
		if not _footprint_check_done:
			_footprint_check_done = true
			_footprint_supported = _cached_vm.has_method("update_entity_blood_footprints")
		if _footprint_supported:
			_cached_vm.call("update_entity_blood_footprints", self, delta)
	if perf_on: _pt = _perf_add("m_footprints", _pt)
	_update_visual_animation(delta)
	if perf_on: _pt = _perf_add("m_visual_anim", _pt)
	_update_hover_label(delta)
	if perf_on: _perf_add("m_hover_label", _pt)

func _trigger_dynamic_npc_social_interaction(partner) -> void:
	if not is_instance_valid(partner) or partner == self or partner.is_dead or partner.is_downed:
		return
	if _pending_social_reply_timer > 0.0 or partner._pending_social_reply_timer > 0.0:
		return
	var vm_soc = _get_vm()
	var sdir = vm_soc.get("social_director") if vm_soc != null else null
	if sdir != null and sdir.has_method("resolve_live_conversation"):
		var cur_day: int = int(WorldClock.current_day) if WorldClock != null else 1
		var ex: Dictionary = sdir.call("resolve_live_conversation", self, partner, cur_day)
		if not bool(ex.get("allowed", false)):
			_spawn_floating_text("💬", Color(0.75, 0.95, 1.0), -28.0)
			return
		_npc_social_event_cooldown = randf_range(16.0, 26.0) * get_social_cooldown_mult()
		partner._npc_social_event_cooldown = randf_range(16.0, 26.0) * partner.get_social_cooldown_mult()
		var line_a: String = str(ex.get("line_a", ""))
		var line_b: String = str(ex.get("line_b", ""))
		var icon: String = str(ex.get("icon", "💬"))
		var col: Color = ex.get("color", Color(0.75, 0.96, 1.0))
		last_social_line_spoken = line_a
		_spawn_floating_text("%s «%s»" % [icon, line_a], col, -34.0)
		var dx: float = partner.global_position.x - global_position.x
		if absf(dx) > 2.0:
			if sprite:
				sprite.flip_h = (dx < 0.0)
			if partner.sprite:
				partner.sprite.flip_h = (dx > 0.0)
		partner._pending_social_reply_timer = 1.8
		partner._pending_social_reply_data = {
			"initiator": self,
			"line_b": line_b,
			"delta_rel": int(ex.get("delta_rel", 0)),
			"delta_rel_a": int(ex.get("delta_rel_a", ex.get("delta_rel", 0))),
			"delta_rel_b": int(ex.get("delta_rel_b", ex.get("delta_rel", 0))),
			"note": str(ex.get("note", "Charlaron en el pueblo")),
			"icon": icon,
			"color": col,
		}
		return
	_npc_social_event_cooldown = randf_range(16.0, 26.0) * get_social_cooldown_mult()
	partner._npc_social_event_cooldown = randf_range(16.0, 26.0) * partner.get_social_cooldown_mult()
	var cur_rel: int = get_relationship_with_npc(partner.npc_name)
	var roll: float = randf()
	if cur_rel <= -20:
		# 32% de probabilidad de giro inesperado ("por azares del destino") donde dos enemigos conectan positivamente
		if roll < 0.32:
			var boost: int = randi_range(18, 28)
			modify_npc_relationship(partner, boost, "Charla sincera e inesperada que limó viejas rencillas")
			_spawn_floating_text("🍻🤝 Charla inesperada con %s (+%d Relación vecinal)" % [partner.npc_name, boost], Color.SPRING_GREEN, -34.0)
		else:
			var drop: int = randi_range(-10, -5)
			modify_npc_relationship(partner, drop, "Discusión tensa al cruzarse en el pueblo")
			_spawn_floating_text("😠💬 Roce con %s (%d Relación vecinal)" % [partner.npc_name, drop], Color.ORANGE, -34.0)
	elif cur_rel >= 35:
		if roll < 0.14:
			var drop_f: int = randi_range(-14, -8)
			modify_npc_relationship(partner, drop_f, "Malentendido reciente conversando en el pueblo")
			_spawn_floating_text("😒💬 Desacuerdo con %s (%d Relación vecinal)" % [partner.npc_name, drop_f], Color.GOLD, -34.0)
		else:
			var gain_f: int = randi_range(6, 12)
			modify_npc_relationship(partner, gain_f, "Buena conversación y apoyo mutuo entre amigos")
			_spawn_floating_text("😊🤝 Charla amena con %s (+%d Relación vecinal)" % [partner.npc_name, gain_f], Color(0.65, 1.0, 0.78), -34.0)
	else:
		if roll < 0.72:
			var gain_n: int = randi_range(8, 15)
			modify_npc_relationship(partner, gain_n, "Se cayeron bien charlando durante el descanso")
			_spawn_floating_text("🙂💬 Buena charla con %s (+%d Relación vecinal)" % [partner.npc_name, gain_n], Color(0.75, 0.96, 1.0), -34.0)
		else:
			var drop_n: int = randi_range(-12, -6)
			modify_npc_relationship(partner, drop_n, "Choque de opiniones durante la jornada")
			_spawn_floating_text("😒💬 Discusión con %s (%d Relación vecinal)" % [partner.npc_name, drop_n], Color.ORANGE, -34.0)

func _process_pending_social_reply(delta: float) -> void:
	if _pending_social_reply_timer <= 0.0:
		return
	if is_incapacitated() or is_sleeping or is_hostile:
		_pending_social_reply_timer = 0.0
		_pending_social_reply_data.clear()
		return
	_pending_social_reply_timer -= delta
	if _pending_social_reply_timer > 0.0:
		return
	_pending_social_reply_timer = 0.0
	var initiator = _pending_social_reply_data.get("initiator", null)
	var line_b: String = str(_pending_social_reply_data.get("line_b", ""))
	var delta_rel: int = int(_pending_social_reply_data.get("delta_rel", 0))
	var d_init: int = int(_pending_social_reply_data.get("delta_rel_a", delta_rel)) # U2: lo que gana quien empezó la charla
	var d_self: int = int(_pending_social_reply_data.get("delta_rel_b", delta_rel)) # y lo que gana quien responde
	var note_str: String = str(_pending_social_reply_data.get("note", "Charlaron en el pueblo"))
	var icon_str: String = str(_pending_social_reply_data.get("icon", "💬"))
	var col: Color = _pending_social_reply_data.get("color", Color(0.75, 0.96, 1.0))
	_pending_social_reply_data.clear()
	if not is_instance_valid(initiator) or initiator.is_incapacitated() or initiator.is_sleeping:
		return
	if global_position.distance_to(initiator.global_position) > 140.0:
		return
	last_social_line_spoken = line_b
	# U2: la parte común se suma a los dos (con sus avisos de reconciliación o ruptura); el resto, a cada uno por su lado
	var d_common: int = int(round(float(d_init + d_self) / 2.0))
	initiator.modify_npc_relationship(self, d_common, note_str)
	if d_init != d_common:
		initiator.modify_npc_relationship(self, d_init - d_common, "", true)
	if d_self != d_common:
		modify_npc_relationship(initiator, d_self - d_common, "", true)
	var sign_tag: String = "+%d" % d_self if d_self >= 0 else "%d" % d_self
	_spawn_floating_text("%s «%s» (%s Rel)" % [icon_str, line_b, sign_tag], col, -36.0)
	_try_player_overhear(initiator, note_str)
	var vm_news = _get_vm()
	# T4: el chismoso cuenta novedades más a menudo y el frío menos (Chismoso solo: 75 %)
	if vm_news != null and randf() < clampf(0.5 + 0.25 * TraitCatalog.npc_tendency(initiator, "gossip") + (VillageFaith.BAND_GOSSIP_BONUS if VillageFaith.same_band(vm_news, initiator, self) else 0.0), 0.15, 0.9):
		var news: Dictionary = vm_news.spread_gossip(initiator, self)
		if not news.is_empty():
			initiator._spawn_floating_text("🗣️ «¿Te has enterado? %s»" % vm_news.gossip_text(news, self, get_person_key()), Color(1.0, 0.92, 0.65), -46.0)
	# R5: quien contesta también puede contar algo que el otro no sepa
	if vm_news != null and randf() < clampf(0.5 + 0.25 * TraitCatalog.npc_tendency(self, "gossip") + (VillageFaith.BAND_GOSSIP_BONUS if VillageFaith.same_band(vm_news, initiator, self) else 0.0), 0.15, 0.9):
		var news_b: Dictionary = vm_news.spread_gossip(self, initiator)
		if not news_b.is_empty():
			_spawn_floating_text("🗣️ «¿Y sabes qué? %s»" % vm_news.gossip_text(news_b, initiator, initiator.get_person_key()), Color(1.0, 0.92, 0.65), -50.0)
	if vm_news != null:
		vm_news.try_npc_slander(initiator, self)

## B5.1: Si el jugador está en sigilo y a distancia de oído, se entera de cómo están realmente las cosas entre los dos.

func _try_player_overhear(other, note_str: String) -> bool:
	var player = _get_player()
	if player == null or not player.has_method("is_stealthing") or not player.is_stealthing():
		return false
	var hearing: float = 96.0 + 12.0 * float(int(player.call("get_skill_level", "stealth")) - 1)
	if global_position.distance_to(player.global_position) > hearing:
		return false
	var feeling: String = NPCDialogue.describe_feeling(get_relationship_with_npc(other.get_person_key()))
	_spawn_floating_text("👂 %s y %s %s: %s" % [other.npc_name, npc_name, feeling, note_str], Color(0.80, 0.75, 1.0), -52.0)
	player.call("add_skill_xp", "stealth", 3)
	TraitDiscovery.reveal_next(self, "le has espiado")
	return true

## Inicia la búsqueda física de un familiar que no llegó a dormir a casa ni sigue su rutina habitual:
## Fase 1: Ir a la tienda/taller familiar a buscarlo (8s). Si encuentra su cadáver allí, activa el reporte físico de inmediato.
## Fase 2: Si no está en la tienda, caminar hacia el policía más cercano.
## Fase 3: Explicar durante 10s a la policía que su familiar ha desaparecido para que la guardia salga a buscarlo.

func begin_missing_family_search(kin) -> void:
	if not is_instance_valid(kin) or kin == self or is_incapacitated():
		return
	if is_instance_valid(_reporting_corpse_target) or is_instance_valid(_searching_missing_kin):
		return
	_clear_unconscious_reaction_state()
	_searching_missing_kin = kin
	_missing_kin_phase = 1
	_missing_kin_timer = 0.0
	is_sleeping = false
	if sprite:
		sprite.rotation_degrees = 0.0
	add_thought("Preocupado: %s no ha vuelto a casa (-10)" % kin.npc_name, -10.0)
	_spawn_floating_text("😟🏠 ¡%s no ha llegado a dormir a casa! Voy a la tienda a ver qué pasó..." % kin.npc_name, Color.GOLD, -44.0)
	var vm = _get_vm()
	if vm and vm.has_method("_hint_player"):
		vm.call("_hint_player", "😟🏠 %s ha notado que su familiar %s no llegó a dormir a casa y va camino a la tienda a buscarlo." % [npc_name, kin.npc_name])

func _get_family_shop_search_pos(kin) -> Vector2:
	if is_instance_valid(kin) and kin.work_position.distance_to(home_table_pos) > 36.0:
		return kin.work_position
	if work_position.distance_to(home_table_pos) > 36.0:
		return work_position
	var vm = _get_vm()
	if vm and "trade_configs" in vm and vm.trade_configs.has(linked_trade):
		var cfg: Dictionary = vm.trade_configs[linked_trade]
		if cfg.has("work_pos"):
			return cfg["work_pos"] as Vector2
	return _ZONA.estirar(_PLAZA_ORIGINAL)

func _process_family_missing_search(delta: float) -> bool:
	if is_instance_valid(_searching_missing_kin):
		var kin = _searching_missing_kin
		if kin.corpse_reported or kin.corpse_in_morgue:
			_searching_missing_kin = null
			_missing_kin_phase = 0
			_missing_kin_timer = 0.0
			_stop_crafting_bar()
			return false
		# Si durante la búsqueda ve el cadáver de su familiar, pasa de inmediato a examinar el cuerpo (10s) y reportarlo
		if kin.is_dead and kin.corpse_on_ground and global_position.distance_to(kin.global_position) <= 95.0:
			_searching_missing_kin = null
			_missing_kin_phase = 0
			_missing_kin_timer = 0.0
			_stop_crafting_bar()
			kin.begin_physical_corpse_discovery(self)
			return true
		# Si lo encuentra vivo y cerca, se tranquiliza
		if not kin.is_dead and not kin.is_downed and global_position.distance_to(kin.global_position) <= 48.0:
			_searching_missing_kin = null
			_missing_kin_phase = 0
			_missing_kin_timer = 0.0
			_stop_crafting_bar()
			_spawn_floating_text("😮‍💨🏠 ¡Ahí estás, %s! Me tenías preocupado al no verte en casa." % kin.npc_name, Color.SPRING_GREEN, -40.0)
			return false

		is_sleeping = false
		if sprite:
			sprite.rotation_degrees = 0.0

		# FASE 1: Ir a la tienda/taller familiar e inspeccionar durante 8.0s
		if _missing_kin_phase == 1:
			var shop_pos: Vector2 = _get_family_shop_search_pos(kin)
			if global_position.distance_to(shop_pos) > 24.0:
				_stop_crafting_bar()
				_move_towards_point(shop_pos, 58.0, delta)
				_finish_frame_movement(delta)
				return true
			velocity = Vector2.ZERO
			_missing_kin_timer += delta
			var rem_s: int = maxi(1, int(ceil(8.0 - _missing_kin_timer)))
			_update_craft_bar_visual(clampf(_missing_kin_timer / 8.0, 0.02, 1.0), "😟🔍 Buscando a %s en tienda (%ds)" % [kin.npc_name, rem_s], Color(1.0, 0.78, 0.28, 0.95))
			trigger_action_animation(0.4)
			_finish_frame_movement(delta)
			if _missing_kin_timer >= 8.0:
				_stop_crafting_bar()
				_missing_kin_timer = 0.0
				_missing_kin_phase = 2
				_spawn_floating_text("😰🚨 ¡%s tampoco está en la tienda! ¡Voy a pedir ayuda a la policía!" % kin.npc_name, Color.ORANGE_RED, -42.0)
			return true

		# Buscar al policía más cercano (incluyendo si está durmiendo en la Comisaría por la noche para despertarlo)
		var nearest_police = _find_nearest_available_authority(true)
		var pol_dest: Vector2 = nearest_police.global_position if nearest_police != null else _comisaria_pos()

		# FASE 2: Caminar personalmente hacia la policía
		if _missing_kin_phase == 2:
			if global_position.distance_to(pol_dest) > 26.0:
				_stop_crafting_bar()
				_move_towards_point(pol_dest, 60.0, delta)
				_finish_frame_movement(delta)
				return true
			velocity = Vector2.ZERO
			_missing_kin_phase = 3
			_missing_kin_timer = 0.0
			if nearest_police != null:
				nearest_police.is_sleeping = false
				if nearest_police.sprite:
					nearest_police.sprite.rotation_degrees = 0.0
			_spawn_floating_text("🗣️🚓 ¡Guardia, por favor! ¡%s no llegó a casa ni está en su tienda!" % kin.npc_name, Color.GOLD, -42.0)
			return true

		# FASE 3: Explicar la desaparición a la policía durante 10.0s
		if global_position.distance_to(pol_dest) > 34.0:
			_stop_crafting_bar()
			_move_towards_point(pol_dest, 60.0, delta)
			_finish_frame_movement(delta)
			return true
		velocity = Vector2.ZERO
		if nearest_police != null:
			nearest_police.is_sleeping = false
			if nearest_police.sprite:
				nearest_police.sprite.rotation_degrees = 0.0
			nearest_police.hold_for_interview(self, 0.8)
			if sprite:
				sprite.flip_h = (nearest_police.global_position.x < global_position.x)
		_missing_kin_timer += delta
		var rem_p: int = maxi(1, int(ceil(10.0 - _missing_kin_timer)))
		var p_name: String = nearest_police.npc_name if nearest_police != null else "la Guardia"
		_update_craft_bar_visual(clampf(_missing_kin_timer / 10.0, 0.02, 1.0), "🗣️🚓 Denunciando ausencia a %s (%ds)" % [p_name, rem_p], Color(0.45, 0.88, 1.0, 0.95))
		trigger_action_animation(0.4)
		_finish_frame_movement(delta)
		if _missing_kin_timer >= 10.0:
			_stop_crafting_bar()
			_missing_kin_reported_day = WorldClock.current_day if WorldClock else 1
			var missing_ref = kin
			_searching_missing_kin = null
			_missing_kin_phase = 0
			_missing_kin_timer = 0.0
			_spawn_floating_text("📢 ¡%s denunció la desaparición de %s ante %s!" % [npc_name, missing_ref.npc_name, p_name], Color.AQUA, -42.0)
			if nearest_police != null:
				nearest_police.start_missing_person_police_search(missing_ref, self)
		return true

	# Detección automática en casa por la noche (21:00 - 06:00): ¿Falta mi familiar en su cama/casa?
	if family_id in ["family_smith", "family_butcher", "family_carpenter", "family_fishmonger", "family_herbalist"]:
		var cur_d: int = WorldClock.current_day if WorldClock else 1
		var cur_h: int = WorldClock.current_hour if WorldClock else 12
		var is_sleep_hours: bool = (cur_h >= 21 or cur_h < 6)
		if is_sleep_hours and _missing_kin_reported_day != cur_d and (global_position.distance_to(home_table_pos) <= 95.0 or is_sleeping):
			for n in get_tree().get_nodes_in_group("village_npcs"):
				if n is VillageNPCBase and n != self:
					var cand_kin := n
					if cand_kin.family_id == family_id and not cand_kin.corpse_reported and not cand_kin.corpse_in_morgue:
						var dist_home: float = minf(cand_kin.global_position.distance_to(cand_kin.bed_position), cand_kin.global_position.distance_to(home_table_pos))
						if dist_home > 85.0:
							# Si el familiar está muerto, abatido o sedado fuera de casa de noche, crece la preocupación
							if cand_kin.is_dead or cand_kin.is_downed or cand_kin.sedated_timer > 0.0:
								_kin_absence_worry_timer += delta
								if _kin_absence_worry_timer >= 4.0:
									_kin_absence_worry_timer = 0.0
									begin_missing_family_search(cand_kin)
									return true
						else:
							_kin_absence_worry_timer = 0.0
						break
		else:
			_kin_absence_worry_timer = 0.0
	return false

func _find_nearest_available_authority(allow_waking_sleeping: bool = false):
	var nearest_authority = null
	var best_dist: float = 999999.0
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPCBase and n != self:
			var auth := n
			var ok_state: bool = (not auth.is_incapacitated()) if allow_waking_sleeping else auth.is_conscious()
			if auth.trade_role in [TradeRole.SHERIFF, TradeRole.GUARD] and ok_state:
				var d: float = global_position.distance_to(auth.global_position)
				if d < best_dist:
					best_dist = d
					nearest_authority = auth
	if nearest_authority == null:
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPCBase and n != self:
				var auth2 := n
				var ok_state2: bool = (not auth2.is_incapacitated()) if allow_waking_sleeping else auth2.is_conscious()
				if auth2.trade_role == TradeRole.DOCTOR and ok_state2:
					var d2: float = global_position.distance_to(auth2.global_position)
					if d2 < best_dist:
						best_dist = d2
						nearest_authority = auth2
	return nearest_authority

func start_missing_person_police_search(missing_npc, reporter) -> void:
	if not is_instance_valid(missing_npc):
		return
	is_sleeping = false
	if sprite:
		sprite.rotation_degrees = 0.0
	_patrol_search_target_npc = missing_npc
	_patrol_search_target_pos = missing_npc.global_position
	_patrol_search_timer = 45.0
	var rep_name: String = reporter.npc_name if is_instance_valid(reporter) else "un vecino"
	_spawn_floating_text("🚓🔦 «Calma, %s. Iré en persona a buscar a %s ahora mismo.»" % [rep_name, missing_npc.npc_name], Color.AQUA, -40.0)
	var vm = _get_vm()
	if vm and vm.has_method("_hint_player"):
		vm.call("_hint_player", "🚓🔦 ¡PATRULLA DE BÚSQUEDA! Tras la denuncia de %s, %s ha salido a rastrear el paradero de %s." % [rep_name, npc_name, missing_npc.npc_name])

func _process_police_missing_person_patrol(delta: float) -> bool:
	if _patrol_search_timer <= 0.0:
		return false
	_patrol_search_timer = maxf(0.0, _patrol_search_timer - delta)
	if is_instance_valid(_patrol_search_target_npc):
		var m_npc = _patrol_search_target_npc
		if m_npc.corpse_reported or m_npc.corpse_in_morgue:
			_patrol_search_timer = 0.0
			_patrol_search_target_npc = null
			_stop_crafting_bar()
			return false
		_patrol_search_target_pos = m_npc.global_position
		if m_npc.is_dead and m_npc.corpse_on_ground and global_position.distance_to(m_npc.global_position) <= 90.0:
			_patrol_search_timer = 0.0
			_patrol_search_target_npc = null
			_stop_crafting_bar()
			m_npc.begin_physical_corpse_discovery(self)
			return true
		if not m_npc.is_dead and global_position.distance_to(m_npc.global_position) <= 45.0:
			_patrol_search_timer = 0.0
			_patrol_search_target_npc = null
			_stop_crafting_bar()
			if m_npc.is_downed:
				m_npc.revive_from_downed(self, false)
			_spawn_floating_text("🚓🔦 ¡Localicé a %s!" % m_npc.npc_name, Color.SPRING_GREEN, -38.0)
			return false
	is_sleeping = false
	if sprite:
		sprite.rotation_degrees = 0.0
	var tgt_name: String = _patrol_search_target_npc.npc_name if is_instance_valid(_patrol_search_target_npc) else "vecino desaparecido"
	_update_craft_bar_visual(clampf(_patrol_search_timer / 45.0, 0.05, 1.0), "🚓🔦 Buscando a %s" % tgt_name, Color(0.40, 0.88, 1.0, 0.95))
	if global_position.distance_to(_patrol_search_target_pos) > 22.0:
		_move_towards_point(_patrol_search_target_pos, 66.0, delta)
	else:
		velocity = Vector2.ZERO
		_patrol_search_timer = 0.0
		_patrol_search_target_npc = null
		_stop_crafting_bar()
	_finish_frame_movement(delta)
	return true

func get_short_world_state() -> String:
	var fem: bool = is_female()
	if is_dead:
		return "En Morgue" if corpse_in_morgue else ("Muerta" if fem else "Muerto")
	if is_downed:
		return "Agonizando"
	if sedated_timer > 0.0 or is_stunned_flag:
		return "Inconsciente"
	if _showing_stealth_prompt:
		return "Desprevenida" if fem else "Desprevenido"
	if is_sleeping:
		return "Durmiendo"
	if is_at_poker_table:
		return "Póker"
	if is_hostile or _police_alerted_timer > 0.0 or _civilian_hostile_timer > 0.0:
		return "Alerta"
	if _is_actively_crafting or (_craft_bar_root != null and _craft_bar_root.visible):
		return "Trabajando"
	var act: String = get_activity_description().to_lower()
	if act.find("trabaj") != -1 or act.find("forj") != -1 or act.find("talan") != -1 or act.find("pesc") != -1 or act.find("cosech") != -1 or act.find("cuid") != -1 or act.find("atend") != -1 or act.find("cocin") != -1 or act.find("horne") != -1:
		return "Trabajando"
	if act.find("patrull") != -1 or act.find("guardia") != -1 or act.find("investig") != -1:
		return "Patrullando"
	if act.find("taberna") != -1 or act.find("posada") != -1 or act.find("beb") != -1 or act.find("cen") != -1 or act.find("trattoria") != -1:
		return "Descansando"
	if act.find("charl") != -1 or act.find("habl") != -1:
		return "Hablando"
	return feminize_role_title(npc_role, fem) if npc_role != "" else ("Vecina" if fem else "Vecino")

func _update_world_tag_for_state(focused_color: Color, fallback_icon: String = "") -> void:
	if not status_label:
		return
	var vm_tag = _get_vm()
	if vm_tag != null and int(vm_tag.player_elevation_level) != int(elevation_level):
		status_label.visible = false
		return
	var pl := _get_player()
	var dist_sq: float = global_position.distance_squared_to(pl.global_position) if pl != null else INF
	if _is_focused_npc():
		_show_status_label("%s · %s" % [npc_name, get_short_world_state()], focused_color)
	elif fallback_icon != "" and dist_sq <= 90.0 * 90.0:
		_show_status_label(fallback_icon, focused_color)
	else:
		status_label.visible = false

func _has_any_witness_watching_opportunist(victim) -> Node2D:
	if not is_inside_tree():
		return null
	var vm = _get_vm()
	var check_pos: Vector2 = victim.global_position if is_instance_valid(victim) else global_position
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPCBase and n != self and n != victim:
			var w := n
			if w.is_conscious():
				var d_v: float = w.global_position.distance_to(check_pos)
				var d_s: float = w.global_position.distance_to(global_position)
				if minf(d_v, d_s) <= 135.0:
					var has_los_v: bool = (vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", w.global_position, check_pos))
					var has_los_s: bool = (vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", w.global_position, global_position))
					if has_los_v or has_los_s:
						return w
	var p: Node2D = _get_player()
	if is_instance_valid(p) and not (p.has_method("is_stunned") and bool(p.call("is_stunned"))):
		var dp_v: float = p.global_position.distance_to(check_pos)
		var dp_s: float = p.global_position.distance_to(global_position)
		if minf(dp_v, dp_s) <= 120.0:
			var p_los_v: bool = (vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", p.global_position, check_pos))
			var p_los_s: bool = (vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", p.global_position, global_position))
			if p_los_v or p_los_s:
				return p
	return null

func _scan_unconscious_victim_for_passersby(delta: float) -> void:
	if not is_unconscious_on_ground() or not is_inside_tree():
		return
	if is_instance_valid(_unconscious_helper_npc) and _unconscious_helper_npc.is_conscious() and _unconscious_helper_npc._reacting_unconscious_target == self:
		return
	_unconscious_scan_timer -= delta
	if _unconscious_scan_timer > 0.0:
		return
	_unconscious_scan_timer = 0.25
	var vm = _get_vm()
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPCBase and n != self:
			var other := n
			if not other.is_conscious() or other.is_hostile or other.is_at_poker_table:
				continue
			if other.trade_role in [TradeRole.ROYAL_INVESTIGATOR, TradeRole.TRAVELING_MERCHANT]:
				continue
			if is_instance_valid(other._reporting_corpse_target) or is_instance_valid(other._carrying_corpse_target) or is_instance_valid(other._searching_missing_kin) or is_instance_valid(other._reacting_unconscious_target):
				continue
			if _unconscious_ignored_by.has(other.npc_name):
				continue
			if other.global_position.distance_to(global_position) <= 95.0 and ((vm == null) or (not vm.has_method("has_line_of_sight")) or bool(vm.call("has_line_of_sight", other.global_position, global_position))):
				if begin_unconscious_neighbor_reaction(other):
					break

## Inicia la reacción de un vecino consciente al encontrar a este NPC inconsciente (estuneado o sedado) según su relación:
## - Enemigo (<= -25): No reporta nada; vigila que nadie esté mirando antes de acercarse a robarle (4s). Si alguien mira, disimula y lo deja tirado.
## - Amigo (>= 25) / Familiar / Autoridad: Corre a socorrerlo y despertarlo rápido (4s), gana afinidad y va a avisar/colaborar con la policía (6s).
## - Neutral (-24..+24): Se acerca con cautela a despertarlo (7s) y sigue su rutina.

func begin_unconscious_neighbor_reaction(discoverer) -> bool:
	if discoverer == null or discoverer == self or not is_unconscious_on_ground():
		return false
	if is_instance_valid(_unconscious_helper_npc) and _unconscious_helper_npc.is_conscious() and _unconscious_helper_npc._reacting_unconscious_target == self:
		return false
	var rel: int = discoverer.get_relationship_with_npc(npc_name)
	var same_fam: bool = (family_id != "none" and family_id != "" and family_id != "family_police" and discoverer.family_id == family_id)
	var is_authority: bool = discoverer.trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.DOCTOR]

	# Caso 1: Enemigo / Rival Oportunista (rel <= -25, no familiar ni policía/médico)
	if rel <= -25 and not same_fam and not is_authority:
		if personal_gold <= 0 and pocket_items.is_empty():
			_unconscious_ignored_by[discoverer.npc_name] = true
			discoverer._spawn_floating_text("😏💤 ¿%s tirado en el suelo y sin un centavo? Ahí te quedas." % npc_name, Color(0.95, 0.72, 0.35), -40.0)
			return false
		var watcher: Node2D = discoverer._has_any_witness_watching_opportunist(self)
		if watcher != null:
			_unconscious_ignored_by[discoverer.npc_name] = true
			discoverer._spawn_floating_text("😒👀 Hay gente mirando... mejor no le robo a %s, pero tampoco pienso ayudarlo." % npc_name, Color(0.92, 0.68, 0.38), -40.0)
			return false
		_unconscious_helper_npc = discoverer
		discoverer._reacting_unconscious_target = self
		discoverer._unconscious_react_mode = "opportunist_steal"
		discoverer._unconscious_react_phase = 1
		discoverer._unconscious_react_timer = 0.0
		discoverer._spawn_floating_text("😏👀 Nadie mira... aprovechemos que %s está inconsciente para vaciarle los bolsillos." % npc_name, Color.GOLD, -42.0)
		return true

	# Caso 2: Amigo (>= 25), Familiar o Autoridad -> Socorro rápido (4s) + Alerta/Colaboración con la Policía
	if rel >= 25 or same_fam or is_authority:
		_unconscious_helper_npc = discoverer
		discoverer._reacting_unconscious_target = self
		discoverer._unconscious_react_mode = "friend_rescue"
		discoverer._unconscious_react_phase = 1
		discoverer._unconscious_react_timer = 0.0
		discoverer._spawn_floating_text("😟⚡ ¡%s está inconsciente en el suelo! ¡Resiste, voy a despertarte!" % npc_name, Color.SPRING_GREEN, -42.0)
		return true

	# Caso 3: Vecino Neutral (-24 a +24) -> Despierta con cautela (7s) sin ir a la policía
	_unconscious_helper_npc = discoverer
	discoverer._reacting_unconscious_target = self
	discoverer._unconscious_react_mode = "neutral_wake"
	discoverer._unconscious_react_phase = 1
	discoverer._unconscious_react_timer = 0.0
	discoverer._spawn_floating_text("🤨🤚 Oye %s, ¿qué haces tirado ahí? Levántate..." % npc_name, Color(0.78, 0.92, 1.0), -40.0)
	return true

func _process_unconscious_neighbor_reaction(delta: float) -> bool:
	if not is_instance_valid(_reacting_unconscious_target) or _unconscious_react_mode == "":
		return false
	var target = _reacting_unconscious_target

	# MODO A: RIVAL OPORTUNISTA ("opportunist_steal") — Vigila que nadie esté viendo antes y durante el robo (4.0s)
	if _unconscious_react_mode == "opportunist_steal":
		if not target.is_unconscious_on_ground():
			_clear_unconscious_reaction_state()
			return false
		_witness_check_timer -= delta
		if _witness_check_timer <= 0.0:
			_witness_check_timer = 0.2
			_witness_check_cached = _has_any_witness_watching_opportunist(target)
		var watcher: Node2D = _witness_check_cached if is_instance_valid(_witness_check_cached) else null
		if watcher != null:
			target._unconscious_ignored_by[npc_name] = true
			_spawn_floating_text("😳👀 ¡Alguien está mirando! Mejor disimulo y me alejo de %s..." % target.npc_name, Color.ORANGE, -42.0)
			_clear_unconscious_reaction_state()
			return false
		if global_position.distance_to(target.global_position) > 22.0:
			_stop_crafting_bar()
			_move_towards_point(target.global_position, 52.0, delta)
			_finish_frame_movement(delta)
			return true
		velocity = Vector2.ZERO
		if sprite:
			sprite.flip_h = (target.global_position.x < global_position.x)
		_unconscious_react_timer += delta
		var rem_st: int = maxi(1, int(ceil(4.0 - _unconscious_react_timer)))
		_update_craft_bar_visual(clampf(_unconscious_react_timer / 4.0, 0.02, 1.0), "🕵️‍♂️💰 Robando a %s sin testigos (%ds)" % [target.npc_name, rem_st], Color(0.95, 0.76, 0.24, 0.95))
		trigger_action_animation(0.4)
		_finish_frame_movement(delta)
		if _unconscious_react_timer >= 4.0:
			var stolen_g: int = 0
			if target.personal_gold > 0:
				stolen_g = maxi(1, int(ceil(float(target.personal_gold) * 0.65)))
				target.personal_gold = maxi(0, target.personal_gold - stolen_g)
				personal_gold += stolen_g
			var stolen_item_id: String = ""
			for pk in target.pocket_items.keys():
				if str(pk) != "royal_safe_conduct" and int(target.pocket_items[pk]) > 0:
					if target.remove_pocket_item(str(pk), 1):
						add_pocket_item(str(pk), 1)
						stolen_item_id = str(pk)
						break
			target._unconscious_ignored_by[npc_name] = true
			add_thought("Aproveché que mi rival %s estaba inconsciente para robarle (+10)" % target.npc_name, 10.0)
			target.add_thought("Alguien me vació los bolsillos mientras estaba inconsciente (-14)", -14.0)
			target.modify_npc_relationship(self, -12, "Sospecha que le robó mientras estaba inconsciente en el suelo", true)
			var loot_desc: String = "%d Oro" % stolen_g if stolen_g > 0 else "sus bolsillos"
			if stolen_item_id != "":
				loot_desc += " + 1x %s" % stolen_item_id
			_spawn_floating_text("😏💰 ¡%s le robó %s a %s sin que nadie viera y lo dejó tirado!" % [npc_name, loot_desc, target.npc_name], Color.GOLD, -44.0)
			_clear_unconscious_reaction_state()
		return true

	# MODO B: AMIGO / FAMILIAR / AUTORIDAD ("friend_rescue") — Fase 1: Reanimar rápido (4.0s) -> Fase 2 y 3: Informar y colaborar con la Policía (6.0s)
	if _unconscious_react_mode == "friend_rescue":
		if _unconscious_react_phase == 1:
			if not target.is_unconscious_on_ground():
				_clear_unconscious_reaction_state()
				return false
			if global_position.distance_to(target.global_position) > 22.0:
				_stop_crafting_bar()
				_move_towards_point(target.global_position, 64.0, delta)
				_finish_frame_movement(delta)
				return true
			velocity = Vector2.ZERO
			if sprite:
				sprite.flip_h = (target.global_position.x < global_position.x)
			_unconscious_react_timer += delta
			var rem_fr: int = maxi(1, int(ceil(4.0 - _unconscious_react_timer)))
			_update_craft_bar_visual(clampf(_unconscious_react_timer / 4.0, 0.02, 1.0), "🤝⚡ Socorriendo a %s (%ds)" % [target.npc_name, rem_fr], Color(0.35, 0.96, 0.58, 0.95))
			trigger_action_animation(0.4)
			_finish_frame_movement(delta)
			if _unconscious_react_timer >= 4.0:
				_stop_crafting_bar()
				_unconscious_react_timer = 0.0
				target.wake_up_from_unconscious(self)
				# U2: el favor pesa más para quien lo recibe
				target.modify_npc_relationship(self, 8, "Lo socorrió y despertó rápidamente al hallarlo inconsciente", true)
				modify_npc_relationship(target, 3, "Lo socorrió y despertó rápidamente al hallarlo inconsciente", true)
				if trade_role in [TradeRole.SHERIFF, TradeRole.GUARD]:
					_spawn_floating_text("🚓⚡ ¡%s reanimó a %s y patrullará la zona del ataque!" % [npc_name, target.npc_name], Color.AQUA, -42.0)
					_patrol_search_target_npc = target
					_patrol_search_target_pos = target.global_position
					_patrol_search_timer = 28.0
					_clear_unconscious_reaction_state()
				else:
					_unconscious_react_phase = 2
					_spawn_floating_text("🤝🚨 ¡Ya estás despierto, %s! ¡Voy corriendo a avisar a la policía de este ataque!" % target.npc_name, Color.SPRING_GREEN, -42.0)
			return true

		var nearest_police = _find_nearest_available_authority(true)
		var pol_dest: Vector2 = nearest_police.global_position if nearest_police != null else _comisaria_pos()

		if _unconscious_react_phase == 2:
			if global_position.distance_to(pol_dest) > 26.0:
				_stop_crafting_bar()
				_move_towards_point(pol_dest, 62.0, delta)
				_finish_frame_movement(delta)
				return true
			velocity = Vector2.ZERO
			_unconscious_react_phase = 3
			_unconscious_react_timer = 0.0
			if nearest_police != null:
				nearest_police.is_sleeping = false
				if nearest_police.sprite:
					nearest_police.sprite.rotation_degrees = 0.0
			_spawn_floating_text("🗣️🚓 ¡Guardia! ¡Encontré a mi amigo %s inconsciente en el suelo!" % target.npc_name, Color.GOLD, -42.0)
			return true

		if global_position.distance_to(pol_dest) > 34.0:
			_stop_crafting_bar()
			_move_towards_point(pol_dest, 62.0, delta)
			_finish_frame_movement(delta)
			return true
		velocity = Vector2.ZERO
		if nearest_police != null:
			nearest_police.is_sleeping = false
			if nearest_police.sprite:
				nearest_police.sprite.rotation_degrees = 0.0
			nearest_police.hold_for_interview(self, 0.8)
			if sprite:
				sprite.flip_h = (nearest_police.global_position.x < global_position.x)
		_unconscious_react_timer += delta
		var rem_rep: int = maxi(1, int(ceil(6.0 - _unconscious_react_timer)))
		var p_label: String = nearest_police.npc_name if nearest_police != null else "la Guardia"
		_update_craft_bar_visual(clampf(_unconscious_react_timer / 6.0, 0.02, 1.0), "🗣️🚓 Colaborando con %s sobre ataque a %s (%ds)" % [p_label, target.npc_name, rem_rep], Color(0.42, 0.88, 1.0, 0.95))
		trigger_action_animation(0.4)
		_finish_frame_movement(delta)
		if _unconscious_react_timer >= 6.0:
			var rescued_ref = target
			_clear_unconscious_reaction_state()
			_spawn_floating_text("📢🚓 ¡%s informó a %s del ataque a %s y dio pistas para patrullar la zona!" % [npc_name, p_label, rescued_ref.npc_name], Color.AQUA, -42.0)
			if nearest_police != null:
				nearest_police.start_missing_person_police_search(rescued_ref, self)
		return true

	# MODO C: VECINO NEUTRAL ("neutral_wake") — Despierta con cautela (7.0s) y sigue su rutina sin ir a la policía
	if not target.is_unconscious_on_ground():
		_clear_unconscious_reaction_state()
		return false
	if global_position.distance_to(target.global_position) > 22.0:
		_stop_crafting_bar()
		_move_towards_point(target.global_position, 48.0, delta)
		_finish_frame_movement(delta)
		return true
	velocity = Vector2.ZERO
	if sprite:
		sprite.flip_h = (target.global_position.x < global_position.x)
	_unconscious_react_timer += delta
	var rem_nw: int = maxi(1, int(ceil(7.0 - _unconscious_react_timer)))
	_update_craft_bar_visual(clampf(_unconscious_react_timer / 7.0, 0.02, 1.0), "🤨🤚 Despertando con cautela a %s (%ds)" % [target.npc_name, rem_nw], Color(0.75, 0.88, 1.0, 0.95))
	trigger_action_animation(0.4)
	_finish_frame_movement(delta)
	if _unconscious_react_timer >= 7.0:
		target.wake_up_from_unconscious(self)
		target.modify_npc_relationship(self, 3, "Le ayudó a despertarse cuando estaba tirado en el suelo", true)
		modify_npc_relationship(target, 1, "Le ayudó a despertarse cuando estaba tirado en el suelo", true)
		_spawn_floating_text("😮‍💨🤚 %s despertó a %s y continúa con su jornada." % [npc_name, target.npc_name], Color(0.78, 0.94, 1.0), -40.0)
		_clear_unconscious_reaction_state()
	return true

## V2: simulación simplificada lejos del jugador. Fuera de la vista, el vecino piensa y se mueve 1 de cada
## LOD_STEP fotogramas con el tiempo acumulado (llega igual de lejos, solo que a saltos que nadie ve).

func _is_seated_on_furniture(pos: Vector2) -> bool:
	return _VillageTavern.is_at_seat(pos) or _VillageRestaurant.is_at_seat(pos)

## Rendimiento (2026-11-09): vecinos de la zona (rejilla del pueblo, rehecha una vez por paso); sin pueblo, todos.
func _near_npcs(center: Vector2, radius: float) -> Array[Node]:
	var vm_g = _cached_vm if is_instance_valid(_cached_vm) else _get_vm()
	if vm_g != null and vm_g.has_method("npcs_near"):
		return vm_g.npcs_near(center, radius)
	return get_tree().get_nodes_in_group("village_npcs")

func _has_nearby_standing_npc(pt: Vector2, radius: float = 16.0) -> bool:
	var r_sq: float = radius * radius
	for n in _near_npcs(pt, radius):
		if n is VillageNPCBase and n != self:
			var other := n as VillageNPCBase
			if other.global_position.distance_squared_to(pt) < r_sq: # lo barato primero (rendimiento, 2026-11-09)
				if other.is_conscious() and not other.is_sleeping and not other.is_at_poker_table and int(other.elevation_level) == int(elevation_level):
					return true
	return false

func _is_target_occupied_by_closer_npc(target_pos: Vector2) -> bool:
	var my_d: float = global_position.distance_to(target_pos)
	if my_d > 21.0:
		return false
	for n in _near_npcs(global_position, 17.5):
		if n is VillageNPCBase and n != self:
			var other := n as VillageNPCBase
			var d_pair_sq: float = global_position.distance_squared_to(other.global_position)
			if d_pair_sq <= 17.5 * 17.5 and other.is_conscious() and not other.is_sleeping and not other.is_at_poker_table and int(other.elevation_level) == int(elevation_level):
				var ot_d: float = other.global_position.distance_to(target_pos)
				if ot_d <= 14.5 or ot_d + 1.0 < my_d:
					return true
	return false

const SEP_EN_PUERTA: float = 10.0 ## distancia mínima entre vecinos en el umbral de una puerta (píxeles del mapa)


func _enforce_npc_personal_space(delta: float) -> void:
	if not is_conscious() or is_sleeping or is_at_poker_table or _is_seated_on_furniture(global_position):
		return
	var vm = _get_vm()
	var tiene_puertas: bool = vm != null and vm.has_method("get_doorway_clearance_nudge")
	# En el umbral de una puerta la distancia baja a SEP_EN_PUERTA (caben dos de frente) en vez de desaparecer: antes dos
	# vecinos podían quedarse encimados en la puerta (2026-11-10, salió al pasar el mundo a metros, paso 0b).
	var en_puerta: bool = tiene_puertas and (vm.call("get_doorway_clearance_nudge", global_position, 22.0) as Vector2).length_squared() > 0.01
	var min_sep: float = SEP_EN_PUERTA if en_puerta else 15.0
	for n in _near_npcs(global_position, 15.0):
		if n is VillageNPCBase and n != self:
			var other := n as VillageNPCBase
			var diff_o: Vector2 = global_position - other.global_position
			var d_sq: float = diff_o.length_squared()
			if d_sq >= min_sep * min_sep:
				continue # Rendimiento (2026-11-09): lo barato primero; el resto de comprobaciones solo para los cercanos
			if not other.is_conscious() or other.is_sleeping or other.is_at_poker_table or int(other.elevation_level) != int(elevation_level):
				continue
			var sep_par: float = min_sep
			if not en_puerta and tiene_puertas and (vm.call("get_doorway_clearance_nudge", other.global_position, 20.0) as Vector2).length_squared() > 0.01:
				sep_par = SEP_EN_PUERTA
			if d_sq < sep_par * sep_par:
				var d_o: float = sqrt(d_sq)
				var push_dir: Vector2
				if d_o > 0.05:
					push_dir = diff_o / d_o
				else:
					var ang: float = float((absi(npc_name.hash()) + absi(other.npc_name.hash())) % 180) * (TAU / 360.0)
					var dir_base := Vector2.RIGHT.rotated(ang)
					push_dir = dir_base if get_instance_id() > other.get_instance_id() else -dir_base
				var overlap: float = sep_par - d_o
				var other_fixed: bool = _is_seated_on_furniture(other.global_position) or other.velocity.length_squared() < 4.0
				var step_push: float = minf(overlap * (0.85 if other_fixed else 0.58), maxf(2.2, 56.0 * delta))
				var cand_pos: Vector2 = global_position + push_dir * step_push
				if vm != null and vm.has_method("sanitize_npc_separation_pos"):
					var san_pos: Vector2 = vm.call("sanitize_npc_separation_pos", global_position, cand_pos, int(elevation_level))
					if san_pos.distance_squared_to(global_position) < 0.01:
						var perp := Vector2(-push_dir.y, push_dir.x) if (get_instance_id() % 2 == 0) else Vector2(push_dir.y, -push_dir.x)
						san_pos = vm.call("sanitize_npc_separation_pos", global_position, global_position + perp * step_push, int(elevation_level))
						if san_pos.distance_squared_to(global_position) < 0.01:
							san_pos = vm.call("sanitize_npc_separation_pos", global_position, global_position - perp * step_push, int(elevation_level))
					global_position = san_pos
				else:
					global_position = cand_pos

func _apply_player_and_doorway_yield(delta: float) -> void:
	if _is_seated_on_furniture(global_position):
		return
	var player = _cached_player
	if is_instance_valid(player) and not is_sleeping and not is_at_poker_table:
		var d_p_sq: float = global_position.distance_squared_to(player.global_position)
		if d_p_sq > 0.0025 and d_p_sq < 256.0:
			var d_p: float = sqrt(d_p_sq)
			var away_dir: Vector2 = (global_position - player.global_position).normalized()
			var side_dir := Vector2(-away_dir.y, away_dir.x) if (abs(npc_name.hash()) % 2 == 0) else Vector2(away_dir.y, -away_dir.x)
			velocity += (away_dir * 0.7 + side_dir * 0.3).normalized() * ((16.0 - d_p) / 16.0) * 34.0

	if velocity.length_squared() < 9.0 and not is_sleeping and not is_at_poker_table:
		_door_nudge_timer -= delta
		if _door_nudge_timer <= 0.0:
			_door_nudge_timer = 0.08
			var vm = _cached_vm
			if vm and vm.has_method("get_doorway_clearance_nudge"):
				var nudge: Vector2 = vm.call("get_doorway_clearance_nudge", global_position, 18.0)
				if nudge.length_squared() > 0.1:
					velocity = nudge * 28.0
			var idle_sep := Vector2.ZERO
			for n in _near_npcs(global_position, 18.0):
				if n is VillageNPCBase and n != self:
					var other := n
					if not other.is_dead and not other.is_downed and not other.is_sleeping and int(other.elevation_level) == int(elevation_level):
						var d_sq: float = global_position.distance_squared_to(other.global_position)
						if d_sq < 324.0:
							var d_other: float = sqrt(d_sq)
							var push_dir: Vector2 = (global_position - other.global_position).normalized() if d_sq > 0.04 else (Vector2.RIGHT.rotated(float((absi(npc_name.hash()) + absi(other.npc_name.hash())) % 180) * (TAU / 360.0)) * (1.0 if get_instance_id() > other.get_instance_id() else -1.0))
							idle_sep += push_dir * ((18.0 - d_other) / 18.0) * 42.0
			_cached_sep_vec = idle_sep
		if _cached_sep_vec.length_squared() > 0.25:
			velocity += _cached_sep_vec.limit_length(42.0)

const COLA_UMBRAL_PX: float = 22.0 ## umbral de una puerta (el mismo radio que mira check_npc_overlaps)
const COLA_ESPERA_PX: float = 34.0 ## a esta distancia del paso por la puerta se espera turno


## Cola en las puertas (2026-11-13): quien va a cruzar un umbral espera fuera si otro vecino ya lo cruza en su mismo
## sentido (cada sentido tiene su carril). Antes se metían varios a la vez y quedaban encimados en la puerta.
func _esperar_turno_en_puerta(vm, en_umbral: bool, nav_target: Vector2) -> bool:
	if en_umbral or vm == null or not vm.has_method("get_doorway_clearance_nudge"):
		return false
	if global_position.distance_to(nav_target) > COLA_ESPERA_PX or (vm.call("get_doorway_clearance_nudge", nav_target, COLA_UMBRAL_PX) as Vector2).length_squared() <= 0.01:
		return false
	var mi_sentido: Vector2 = nav_target - global_position
	for n in _near_npcs(nav_target, COLA_UMBRAL_PX):
		if n == self or not (n is VillageNPCBase):
			continue
		var otro := n as VillageNPCBase
		if not otro.is_conscious() or int(otro.elevation_level) != int(elevation_level) or otro.velocity.dot(mi_sentido) <= 0.0:
			continue
		if (vm.call("get_doorway_clearance_nudge", otro.global_position, COLA_UMBRAL_PX) as Vector2).length_squared() > 0.01:
			return true
	return false


func _move_towards_point(target_pos: Vector2, speed: float, delta: float = 0.016) -> void:
	var vm = _get_vm()
	var is_escorting_player: bool = vm != null and bool(vm.get("player_being_escorted_to_jail")) and vm.get("escorting_officer") == self
	var leg_mult: float = health_comp.get_moving_capacity() if health_comp else 1.0
	var eff_speed: float = maxf(62.0, speed) if is_escorting_player else (speed * get_nutrition_speed_multiplier() * get_sleep_speed_multiplier() * leg_mult)
	if errand_kind in URGENT_ERRANDS: # con prisa, el cansancio y el hambre apenas le frenan (el guardia del día 2 se arrastraba)
		eff_speed = maxf(eff_speed, speed * URGENT_MIN_SPEED_FACTOR * leg_mult)

	var in_doorway_now: bool = vm != null and vm.has_method("get_doorway_clearance_nudge") and (vm.call("get_doorway_clearance_nudge", global_position, 24.0) as Vector2).length_squared() > 0.01
	var is_seat_target: bool = _is_seated_on_furniture(target_pos)
	if not is_escorting_player and not is_hostile and not in_doorway_now and not is_seat_target:
		if _is_target_occupied_by_closer_npc(target_pos):
			velocity = Vector2.ZERO
			_stuck_timer = 0.0
			_last_frame_pos = global_position
			return

	var _pt: int = Time.get_ticks_usec() if perf_on else 0
	_nav_waypoint_timer -= delta
	if (_nav_waypoint_timer <= 0.0) or (_cached_nav_waypoint == Vector2.INF) or (target_pos.distance_squared_to(_last_nav_dest) > 16.0):
		_nav_waypoint_timer = 0.12
		_last_nav_dest = target_pos
		_cached_nav_waypoint = vm.call("get_navigation_waypoint", global_position, target_pos, self) if (vm and vm.has_method("get_navigation_waypoint")) else target_pos

	var nav_target: Vector2 = _cached_nav_waypoint
	var diff: Vector2 = nav_target - global_position
	var step_snap: float = maxf(4.5, eff_speed * delta * 0.85)
	if diff.length() <= step_snap:
		var is_intermediate_wp: bool = nav_target.distance_squared_to(target_pos) > 9.0
		if is_intermediate_wp or (diff.length() <= 6.5 and (in_doorway_now or is_seat_target or not _has_nearby_standing_npc(nav_target, 16.5))):
			global_position = nav_target
		if is_intermediate_wp and vm and vm.has_method("get_navigation_waypoint"):
			_cached_nav_waypoint = vm.call("get_navigation_waypoint", global_position, target_pos, self)
			nav_target = _cached_nav_waypoint
			diff = nav_target - global_position
		if diff.length() <= step_snap:
			velocity = Vector2.ZERO
			_stuck_timer = 0.0
			_last_frame_pos = global_position
			return

	if perf_on: _pt = _perf_add("a_nav_waypoint", _pt)
	if _esperar_turno_en_puerta(vm, in_doorway_now, nav_target):
		velocity = Vector2.ZERO
		_stuck_timer = 0.0
		_last_frame_pos = global_position
		return
	var _door_ok: bool = not (vm and vm.has_method("npc_interact_with_door")) or bool(vm.call("npc_interact_with_door", self, delta, target_pos, nav_target))
	if perf_on: _pt = _perf_add("a_doors", _pt)
	if not _door_ok:
		velocity = Vector2.ZERO
		_stuck_timer += delta
		if _stuck_timer >= 2.2:
			_stuck_timer = 0.0
			var is_police: bool = trade_role in [TradeRole.SHERIFF, TradeRole.GUARD, TradeRole.ROYAL_INVESTIGATOR]
			_spawn_floating_text("🚓💥 ¡Derribando puerta!" if is_police else "🚪✊ ¡Puerta trancada!", Color.ORANGE_RED if is_police else Color.GOLD, -34.0)
		return

	var desired_vel: Vector2 = diff.normalized() * eff_speed

	_avance_t += delta
	if _avance_t >= 1.0:
		_atascado_lento = eff_speed > 12.0 and global_position.distance_to(_avance_pos) < eff_speed * 0.25
		_avance_pos = global_position
		_avance_t = 0.0
	if (global_position.distance_squared_to(_last_frame_pos) < 0.09 and eff_speed > 12.0) or _atascado_lento:
		_stuck_timer += delta
		if _stuck_timer >= 0.40:
			_nav_waypoint_timer = 0.0
			if in_doorway_now:
				# En el umbral de una puerta no empujar perpendicularmente contra las jambas; avanzar por el eje del paso
				if _stuck_timer >= 0.70:
					global_position += diff.normalized() * minf(6.0, diff.length())
					_stuck_timer = 0.0
			else:
				# Atascos (2026-11-09): si tras 1,2 s sigue sin salir, prueba por el otro lado (y así sucesivamente)
				var side_left: bool = (abs(npc_name.hash()) % 2 == 0) != (int(_stuck_timer / 1.2) % 2 == 1)
				var perp := Vector2(-diff.y, diff.x).normalized() if side_left else Vector2(diff.y, -diff.x).normalized()
				desired_vel = (diff.normalized() * 0.55 + perp * 0.75).normalized() * eff_speed
	else:
		_stuck_timer = 0.0

	if perf_on: _pt = _perf_add("a_stuck", _pt)
	_sep_timer -= delta
	if _sep_timer <= 0.0:
		_sep_timer = 0.04
		var sep_vec := Vector2.ZERO
		if not in_doorway_now:
			for n in _near_npcs(global_position, 22.0):
				if n is VillageNPCBase and n != self:
					var other := n
					if not other.is_dead and not other.is_downed and not other.is_sleeping and int(other.elevation_level) == int(elevation_level):
						var d_sq: float = global_position.distance_squared_to(other.global_position)
						if d_sq < 484.0:
							var d_other: float = sqrt(d_sq)
							var push_dir: Vector2 = (global_position - other.global_position).normalized() if d_sq > 0.04 else (Vector2.RIGHT.rotated(float((absi(npc_name.hash()) + absi(other.npc_name.hash())) % 180) * (TAU / 360.0)) * (1.0 if get_instance_id() > other.get_instance_id() else -1.0))
							var side_dir := Vector2(-push_dir.y, push_dir.x)
							var steer_dir: Vector2 = (push_dir + side_dir * 0.45).normalized() if desired_vel.dot(-push_dir) > 0.0 else push_dir
							sep_vec += steer_dir * ((22.0 - d_other) / 22.0) * 52.0
		_cached_sep_vec = sep_vec
	if not in_doorway_now and not is_escorting_player:
		for n in _near_npcs(global_position, 16.0):
			if n is VillageNPCBase and n != self:
				var other := n as VillageNPCBase
				if not other.is_dead and not other.is_downed and not other.is_sleeping and int(other.elevation_level) == int(elevation_level):
					var d_sq_now: float = global_position.distance_squared_to(other.global_position)
					if d_sq_now > 0.01 and d_sq_now < 256.0:
						var push_now: Vector2 = (global_position - other.global_position).normalized()
						var toward_dot: float = desired_vel.dot(-push_now)
						if toward_dot > 0.0:
							desired_vel += push_now * toward_dot
	if perf_on: _perf_add("a_separation", _pt)

	_last_frame_pos = global_position
	velocity = desired_vel if (is_escorting_player or in_doorway_now) else (desired_vel + _cached_sep_vec).limit_length(eff_speed * 1.15)

func _process_live_fight(delta: float) -> void:
	velocity = Vector2.ZERO
	_stop_crafting_bar()
	_enforce_npc_personal_space(delta)
	var prev_beat: int = int(_live_fight_clock / 1.3)
	_live_fight_clock += delta
	if sprite:
		sprite.flip_h = live_fight_partner.global_position.x < global_position.x
		sprite.offset.x = sin(_live_fight_clock * 26.0) * 1.2
	if int(_live_fight_clock / 1.3) != prev_beat:
		_spawn_floating_text("💢", Color(1.0, 0.45, 0.35), -30.0)
	trigger_action_animation(0.4)
	_update_visual_animation(delta)
	_update_hover_label(delta)

func is_at_hangout_spot(tol: float = 20.0) -> bool:
	return hangout_id >= 0 and global_position.distance_to(_get_social_target_pos()) <= tol

func _find_best_social_partner():
	ensure_npc_relationships_initialized()
	var vm_s = _get_vm()
	var sdir_s = vm_s.get("social_director") if vm_s != null else null
	var my_key: String = get_person_key()
	var best = null
	var best_score: float = -9999.0
	for node in get_tree().get_nodes_in_group("village_npcs"):
		if node == self or not (node is VillageNPCBase):
			continue
		var other = node
		if other.is_dead or other.is_downed or other.is_sleeping:
			continue
		# B2.2: los rivales se evitan (no se buscan para charlar) y no se interrumpe una quedada ajena
		if sdir_s != null and bool(sdir_s.call("should_avoid", my_key, other.get_person_key())):
			continue
		if other.hangout_id >= 0 or other.is_in_live_fight():
			continue
		var dist: float = global_position.distance_to(other.global_position)
		var other_key: String = other.get_person_key()
		var family_bonus: float = 110.0 if (family_id != "none" and other.family_id == family_id) else 0.0
		var rom_bonus: float = 0.0
		if person_profile != null and str(person_profile.partner_id) != "" and str(person_profile.partner_id) == other_key:
			rom_bonus = 135.0
		elif sdir_s != null and sdir_s.has_method("get_pair_stage"):
			match str(sdir_s.call("get_pair_stage", my_key, other_key)):
				"couple": rom_bonus = 135.0
				"dating": rom_bonus = 95.0
				"flirt": rom_bonus = 60.0
				"interest": rom_bonus = 32.0
		var rel_score: float = float(get_relationship_with_npc(other.npc_name)) * 0.65
		var fate_jitter: float = randf_range(-20.0, 42.0)
		var score: float = family_bonus + rom_bonus + rel_score + fate_jitter - dist * 0.4 + (100.0 - other.need_social) * 0.5
		if score > best_score:
			best_score = score
			best = other
	return best

func is_visiting_grave() -> bool:
	return current_activity == ActivityState.SOCIALIZING and hangout_id < 0 and person_profile != null and int(person_profile.bereavement_days_left) > 0 and str(person_profile.deceased_partner_name) != ""

func _get_social_target_pos() -> Vector2:
	if rite_pos != Vector2.ZERO:
		return rite_pos
	if errand_kind != "":
		return errand_pos
	if hangout_id >= 0:
		return hangout_spot_pos + Vector2(float(hangout_side) * 11.0, 0.0)
	if is_visiting_grave():
		var vm_g = _get_vm()
		if vm_g and vm_g.has_method("get_grave_pos_for_victim"):
			return vm_g.call("get_grave_pos_for_victim", str(person_profile.deceased_partner_name))
		return global_position # sin pueblo no hay cementerio: se queda donde está
	var vm_s = _get_vm()
	if _VillageTavern.dentro(global_position) or (family_id == "none" and not is_vagrant_camper) or home_table_pos == tavern_social_pos:
		if not (trade_role in [TradeRole.INNKEEPER, TradeRole.WAITER]):
			if _tavern_seat == Vector2.ZERO or _tavern_seat == tavern_social_pos or _VillageTavern.is_seat_taken(vm_s, _tavern_seat, self):
				_tavern_seat = _VillageTavern.pick_seat_for(vm_s, self)
			if _tavern_seat != Vector2.ZERO and _tavern_seat != tavern_social_pos:
				return _tavern_seat
	if is_instance_valid(_social_partner) and not _social_partner.is_dead and not _social_partner.is_downed and not _social_partner.is_sleeping:
		if _VillageTavern.dentro(_social_partner.global_position):
			if _tavern_seat == Vector2.ZERO or _tavern_seat == tavern_social_pos or _VillageTavern.is_seat_taken(vm_s, _tavern_seat, self):
				_tavern_seat = _VillageTavern.pick_seat_for(vm_s, self)
			if _tavern_seat != Vector2.ZERO and _tavern_seat != tavern_social_pos:
				return _tavern_seat
		var h_ang: float = float(absi(npc_name.hash()) % 360) * (TAU / 360.0)
		var ring_offset := Vector2.RIGHT.rotated(h_ang) * 20.0
		var ref_p: Vector2 = _social_partner.home_table_pos if _social_partner.velocity.length_squared() > 25.0 else _social_partner.global_position
		var cand_p: Vector2 = ref_p + ring_offset
		var vm = get_tree().get_first_node_in_group("village_manager")
		if vm and vm.has_method("clamp_point_to_building_interior"):
			cand_p = vm.call("clamp_point_to_building_interior", ref_p, cand_p)
		return cand_p
	var h_ang_home: float = float(absi(npc_name.hash()) % 360) * (TAU / 360.0)
	if family_id != "none":
		var cand_ht: Vector2 = home_table_pos + Vector2(cos(h_ang_home) * 14.0, sin(h_ang_home) * 11.5)
		if vm_s and vm_s.has_method("clamp_point_to_building_interior"):
			cand_ht = vm_s.call("clamp_point_to_building_interior", home_table_pos, cand_ht)
		return cand_ht
	return tavern_social_pos + Vector2.RIGHT.rotated(h_ang_home) * 9.0

func get_activity_description() -> String:
	if is_downed: return "🩸 Agonizando (%ds)" % maxi(1, int(ceil(bleedout_timer)))
	if sedated_timer > 0.0: return "💤 Sedado (%ds)" % maxi(1, int(ceil(sedated_timer)))
	var vm_j = _get_vm()
	if vm_j != null and vm_j.VillageJustice.is_npc_jailed(vm_j, self):
		var rec_j: Dictionary = vm_j.VillageJustice.get_inmate_record(vm_j, self)
		if str(rec_j.get("status", "")) == "escorting":
			return "🚔⛓️ Llevado detenido al calabozo por %s" % str(rec_j.get("reason", "un delito"))
		return "🔒⛓️ En el calabozo por %s (%dh)" % [str(rec_j.get("reason", "un delito")), maxi(1, int(rec_j.get("hours_left", 1)))]
	if is_in_live_fight(): return "💢 Peleando con %s" % live_fight_partner.npc_name
	if is_instance_valid(_reporting_corpse_target):
		if _corpse_report_phase == 1:
			return "🔍 Comprobando si %s respira (%ds)" % [_reporting_corpse_target.npc_name, maxi(1, int(ceil(10.0 - _corpse_report_timer)))]
		elif _corpse_report_phase == 3:
			return "🗣️ Explicando el hallazgo de %s a la policía (%ds)" % [_reporting_corpse_target.npc_name, maxi(1, int(ceil(12.5 - _corpse_report_timer)))]
		return "🏃 Yendo en persona a avisar a la policía por %s" % _reporting_corpse_target.npc_name
	if is_instance_valid(_searching_missing_kin):
		if _missing_kin_phase == 1:
			return "😟🔍 Buscando a su familiar %s en la tienda" % _searching_missing_kin.npc_name
		elif _missing_kin_phase == 3:
			return "🗣️🚓 Denunciando la desaparición de %s (%ds)" % [_searching_missing_kin.npc_name, maxi(1, int(ceil(10.0 - _missing_kin_timer)))]
		return "😰🏃 Yendo a la policía por la ausencia de %s" % _searching_missing_kin.npc_name
	if _patrol_search_timer > 0.0 and is_instance_valid(_patrol_search_target_npc):
		return "🚓🔦 Patrulla de búsqueda: rastreando a %s" % _patrol_search_target_npc.npc_name
	if is_instance_valid(_reacting_unconscious_target):
		if _unconscious_react_mode == "opportunist_steal":
			return "🕵️‍♂️💰 Robando en sigilo a su rival %s" % _reacting_unconscious_target.npc_name
		elif _unconscious_react_mode == "friend_rescue":
			if _unconscious_react_phase == 1:
				return "🤝⚡ Socorriendo y despertando a %s" % _reacting_unconscious_target.npc_name
			return "🗣️🚓 Informando a la guardia del ataque a %s" % _reacting_unconscious_target.npc_name
		return "🤨🤚 Despertando con cautela a %s" % _reacting_unconscious_target.npc_name
	var sick_tag: String = ""
	if health_comp and health_comp.has_active_sickness_or_infection():
		sick_tag = " [🌡️Enfermo/Fiebre %d%%]" % int(round(maxf(health_comp.fever, maxf(health_comp.food_poisoning, health_comp.swamp_sickness))))
	if trade_role == TradeRole.ROYAL_INVESTIGATOR:
		var vm_inv = _get_vm()
		if vm_inv and vm_inv.has_method("get_royal_investigator_status_text"):
			return str(vm_inv.call("get_royal_investigator_status_text")) + sick_tag
		return "🔍👑 Investigando Asesinato Real" + sick_tag
	if trade_role == TradeRole.TRAVELING_MERCHANT:
		return ("🧳👑 Regresando a las Tierras Reales" if _merchant_leaving else "⚖️👑 Comerciando con Salvoconducto Real") + sick_tag
	if health_comp and (health_comp.fever >= 45.0 or health_comp.food_poisoning >= 50.0 or health_comp.swamp_sickness >= 50.0) and global_position.distance_to(_cama_urgencias()) <= 32.0:
		return "🏥 Ingresado en el Hospital tratándose la Fiebre/Infección" + sick_tag
	match current_activity:
		ActivityState.SLEEPING:
			if in_shelter:
				return ("🕯️ Durmiendo en el Albergue del Alba" if is_sleeping else "🚶🕯️ Yendo al Albergue") + sick_tag
			if lodging == "candil":
				return ("💤 Durmiendo en El Candil" if is_sleeping else "🚶 Yendo a El Candil") + sick_tag
			if is_vagrant_camper:
				return ("⛺ Durmiendo a la Intemperie (Campamento)" if is_sleeping else "🚶⛺ Yendo a su Campamento Rústico") + sick_tag
			return ("💤 Durmiendo en Cama" if is_sleeping else "🚶 Yendo a Dormir") + sick_tag
		ActivityState.EATING:
			if _is_amateur_foraging:
				return "🏹💦 Cazando/Recolectando Torpemente (Sin Dinero/Comida)"
			var loc := "en la Casa de Comidas" if _restaurant_seat != Vector2.ZERO else "en la Taberna" if _eat_at_tavern else ("en el Albergue" if in_shelter else ("en su Fogata" if is_vagrant_camper else "en Casa"))
			return "🍲 Comiendo %s" % loc
		ActivityState.SOCIALIZING:
			if errand_kind != "":
				var at_e: bool = global_position.distance_to(errand_pos) <= 30.0
				match errand_kind:
					"wash": return "🧼 Lavándose" if at_e else "🚶🧼 Yendo a lavarse"
					"drink": return "🍺 Bebiendo en la taberna" if at_e else "🚶🍺 Yendo a la taberna a beber"
					"gamble": return "🎲 Jugando en la taberna" if at_e else "🚶🎲 Yendo a jugar a la taberna"
					"beg": return "🥺 Pidiendo limosna en la plaza" if at_e else "🚶🥺 Yendo a pedir a la plaza"
					"vote": return "🗳️ Votando en el ayuntamiento" if at_e else "🚶🗳️ Yendo a votar"
					"leave": return "🎒 Marchándose del valle"
					"leisure": return load("res://scripts/systems/VillagePlaces.gd").activity_text(self, at_e)
					"market": return "🧺 Comprando en el mercado" if at_e else "🚶🧺 Yendo al mercado"
					"mayor_office": return "🏛️ Cuadrando las cuentas del pueblo" if at_e else "🚶🏛️ Yendo al ayuntamiento"
					"player_shop_clerk": return "🏪 Atendiendo el Bazar del Forastero" if at_e else "🚶🏪 Yendo a atender el Bazar del Forastero"
					"player_shop_buy": return "🛍️ Comprando en el Bazar del Forastero" if at_e else "🚶🛍️ Yendo a comprar al Bazar del Forastero"
					"fence_alley": return "🌙 Rondando de madrugada" if at_e else "🚶🌙 Paseando de madrugada"
					"familia_meet": return "🍷 Cenando tarde en el reservado" if at_e else "🚶🌙 Paseando de noche"
					"familia_errand": return "🗣️ Hablando en voz baja" if at_e else "🚶 Haciendo un recado por el pueblo"
					"night_stroll": return "🌙🚶 Paseando de noche por las calles"
					"sleepwalk": return "😴🚶 Caminando dormido por la calle (Sonámbulo)"
					"prowl_victim": return "🕵️‍♂️🌑 Rondando en las sombras de madrugada"
			if rite_kind in ["sect", "sect_lure"]:
				var vm_sc = _get_vm()
				var known_sc: bool = vm_sc != null and "sect_state" in vm_sc and (bool(vm_sc.sect_state.get("player_member", false)) or (vm_sc.sect_state.get("known", {}) as Dictionary).has(get_person_key()))
				if rite_kind == "sect" and known_sc:
					return "🌑 En una reunión secreta de la secta" if global_position.distance_to(rite_pos) <= 30.0 else "🚶🌑 Yendo a una reunión secreta"
				return "🌙 Junto al cementerio, de madrugada" if global_position.distance_to(rite_pos) <= 30.0 else "🚶🌙 Paseando de madrugada"
			if rite_pos != Vector2.ZERO:
				if trade_role == TradeRole.PRIEST:
					return "☀️ Dirigiendo el Oficio del Alba"
				return "☀️ En el Oficio del Alba" if global_position.distance_to(rite_pos) <= 30.0 else "🚶☀️ Yendo al Oficio del Alba"
			if hangout_id >= 0 and is_instance_valid(_social_partner):
				var vm_act = _get_vm()
				var sdir_act = vm_act.get("social_director") if vm_act != null else null
				var p_key: String = _social_partner.get_person_key()
				var st_act: String = str(sdir_act.call("get_pair_stage", get_person_key(), p_key)) if (sdir_act != null and sdir_act.has_method("get_pair_stage")) else "none"
				if person_profile != null and str(person_profile.partner_id) == p_key:
					st_act = "couple"
				if st_act == "couple":
					return ("💑 Pasando la tarde con %s%s" % [_social_partner.npc_name, (" (%s)" % hangout_spot_label) if hangout_spot_label != "" else ""]) if is_at_hangout_spot(20.0) else ("💑 Ha quedado con su pareja %s%s" % [_social_partner.npc_name, (" en %s" % hangout_spot_label) if hangout_spot_label != "" else ""])
				elif st_act in ["dating", "flirt"]:
					return ("💞 En una cita con %s%s" % [_social_partner.npc_name, (" (%s)" % hangout_spot_label) if hangout_spot_label != "" else ""]) if is_at_hangout_spot(20.0) else ("💞 Yendo a su cita con %s%s" % [_social_partner.npc_name, (" en %s" % hangout_spot_label) if hangout_spot_label != "" else ""])
				return ("☕ Pasando el rato con %s%s" % [_social_partner.npc_name, (" (%s)" % hangout_spot_label) if hangout_spot_label != "" else ""]) if is_at_hangout_spot(20.0) else ("🚶 Ha quedado con %s%s" % [_social_partner.npc_name, (" en %s" % hangout_spot_label) if hangout_spot_label != "" else ""])
			if is_visiting_grave():
				var d_nm_g: String = str(person_profile.deceased_partner_name)
				return ("🪦 Visitando la tumba de %s" % d_nm_g) if global_position.distance_to(_get_social_target_pos()) <= 26.0 else ("🚶🕯️ Yendo al cementerio a recordar a %s" % d_nm_g)
			return ("💬 Charlando con %s" % _social_partner.npc_name) if is_instance_valid(_social_partner) else "💬 Socializando"
		_:
			if _noise_react_timer > 0.0 and not is_hostile:
				if _noise_react_mode == "guard_investigate":
					return "🛡️👂 Acudiendo a un ruido sospechoso"
				elif _noise_react_mode == "civilian_peek":
					return "👀 Asomándose a mirar el alboroto"
				return "😨🏃 Alejándose de una pelea"
			if _is_morning_expedition_hours(): return _get_expedition_description()
			if _supply_run_target_role != 0: return "🛒 Yendo a comprar %s al taller vecino" % _supply_run_input_label
			if _is_actively_crafting: return "⚒️ Crafteando en Taller (%d%%)" % int(round(_craft_progress))
			if trade_role == TradeRole.INNKEEPER: return "🍺 Atendiendo el Mostrador de la Posada"
			if trade_role == TradeRole.WAITER:
				var w_step: String = str(get_meta("waiter_step", "idle"))
				if w_step == "take_order": return "📝 Tomando nota en las mesas de la Taberna"
				if w_step == "pickup_kitchen": return "🍲 Recogiendo comanda en el pasa-platos"
				if w_step == "serve_table": return "🍺 Llevando platos y jarras a las mesas"
				return "🍺 Atendiendo el Salón de la Taberna"
			if trade_role == TradeRole.DOCTOR: return "🩺 En Guardia de Urgencias y Morgue"
			if trade_role == TradeRole.SHERIFF: return "🚓 Dirigiendo la Comisaría"
			if trade_role == TradeRole.GUARD: return "🛡️ Patrullando la Aldea"
			if trade_role == TradeRole.PRIEST: return "☀️ Cuidando la Capilla del Alba"
			if trade_role == TradeRole.NOBLE: return "📜 Administrando sus tierras"
			if trade_role == TradeRole.CHILD: return "📚 En la escuela"
			if trade_role == TradeRole.TEACHER: return "🧑‍🏫 Dando clase"
			if trade_role == TradeRole.UNEMPLOYED:
				if has_meta("day_job"):
					return str(get_meta("day_job"))
				return ("🕯️ Sin oficio, acogido en el Albergue" if in_shelter else "⛺ Sobreviviendo en las Afueras") if is_vagrant_camper else "🚶 Paseando / Jornalero"
			elif trade_role == TradeRole.FAMILY_MEMBER:
				return "🏠 Turno del Hogar (08-18h)" if _is_mandatory_work_hours() else "🏠 Cuidando el Hogar"
			return "⚒️ En Turno Laboral (08-18h)" if _is_mandatory_work_hours() else "⚒️ Atendiendo su Oficio"

## C7 fase 4c: solo guardia y alguaciles llevan armas que se puedan tirar (porra y pistola).

func _update_visual_animation(delta: float) -> void:
	if _anim_action_timer > 0.0:
		_anim_action_timer = maxf(0.0, _anim_action_timer - delta)
	_anim_cycle_clock += delta
	if velocity.length_squared() > 4.0:
		facing_direction = velocity.normalized()
	if not sprite:
		return
	if is_sleeping:
		if _has_spritesheet_anim:
			sprite.frame = 3
		sprite.rotation_degrees = 90.0
		sprite.position = Vector2(0, 2)
		return
	sprite.rotation_degrees = 0.0
	if absf(velocity.x) > 2.0:
		sprite.flip_h = velocity.x < 0.0

	if _has_spritesheet_anim and sprite.hframes == 4 and sprite.vframes == 3:
		var moving: bool = velocity.length_squared() > 14.0
		var near_p: bool = is_instance_valid(_cached_player) and global_position.distance_squared_to(_cached_player.global_position) <= 42.0 * 42.0
		var periodic_gesture: bool = fmod(_anim_cycle_clock, 8.5) > 6.2
		var use_action_row: bool = is_hostile or _is_actively_crafting or (_anim_action_timer > 0.0) or (not moving and (near_p or periodic_gesture))
		if moving:
			_anim_frame_timer += delta * 7.5
			var col_w: int = int(floor(_anim_frame_timer)) % 4
			sprite.frame = 4 + col_w
			_step_phase += delta * 11.0
			sprite.position.y = -absf(sin(_step_phase)) * 1.1
		elif use_action_row:
			_anim_frame_timer += delta * 5.0
			var col_a: int = int(floor(_anim_frame_timer)) % 4
			sprite.frame = 8 + col_a
			sprite.position.y = 0.0
		else:
			_anim_frame_timer += delta * 2.8
			var col_i: int = int(floor(_anim_frame_timer)) % 4
			sprite.frame = col_i
			sprite.position.y = 0.0
		return

	if velocity.length_squared() > 16.0:
		_step_phase += delta * 11.0
		sprite.position.y = -absf(sin(_step_phase)) * 2.0
	else:
		sprite.position.y = 0.0

func _update_hover_label(delta: float = 0.016) -> void:
	if not status_label or is_dead or is_downed:
		return
	if is_stunned_flag:
		_update_world_tag_for_state(Color(0.82, 0.88, 0.96), "💫")
		return
	if _showing_stealth_prompt:
		_show_status_label("%s · Desprevenido" % npc_name, Color(0.95, 0.91, 0.83))
		return

	var focused_now: bool = _is_focused_npc()
	_hover_label_timer -= delta
	if _hover_label_timer > 0.0 and not focused_now:
		if status_label and status_label.visible and status_label.text.find("·") != -1:
			_refresh_unfocused_tag()
		return
	_hover_label_timer = 0.08

	var player := _get_player()
	var near_player: bool = player != null and global_position.distance_squared_to(player.global_position) <= 85.0 * 85.0
	var mouse_d: float = global_position.distance_to(get_global_mouse_position())
	var near_mouse: bool = mouse_d <= 22.0
	if near_mouse:
		if _hover_owner == null or not is_instance_valid(_hover_owner) or _hover_owner == self or mouse_d < _hover_owner_d:
			_hover_owner = self
			_hover_owner_d = mouse_d
	elif _hover_owner == self:
		_hover_owner = null

	if _is_focused_npc():
		if near_mouse and Input.is_key_pressed(KEY_ALT):
			var traits_str: String = ", ".join(traits) if not traits.is_empty() else "Equilibrado"
			_show_status_label("%s (%s) · %s [%s]" % [npc_name, npc_role, get_short_world_state(), traits_str], Color(0.95, 0.91, 0.83))
		else:
			_show_status_label("%s · %s" % [npc_name, get_short_world_state()], Color(0.95, 0.91, 0.83))
	elif near_player:
		if is_sleeping:
			_show_status_label("💤", Color(0.82, 0.88, 0.96))
		elif is_instance_valid(_active_floating_text):
			_show_status_label("💬", Color(0.95, 0.91, 0.83))
		elif _is_actively_crafting or (_craft_bar_root != null and _craft_bar_root.visible):
			status_label.visible = false
		else:
			status_label.visible = false
	else:
		status_label.visible = false

func modify_affinity(delta_amount: int) -> void:
	affinity = clampi(affinity + delta_amount, -100, 100)
	VillageFaith.on_affinity_change(_get_vm(), self, delta_amount) # G5: cuenta con sus bandos
	var sign_str := "+" if delta_amount >= 0 else ""
	_spawn_floating_text("%s%d Relación" % [sign_str, delta_amount], Color.SPRING_GREEN if delta_amount >= 0 else Color.CORAL, -42.0)
	TraitDiscovery.check_trust(self)

## T3: rasgos tal como los ve el jugador («Rencoroso, ❓, ❓»).
## U5: ¿sabe el jugador lo que siente este vecino por `other_key`? La pareja y la familia se ven siempre.

func knows_feeling_toward(other_key: String) -> bool:
	if feelings_all_known or other_key in known_feelings:
		return true
	if person_profile != null and str(person_profile.partner_id) == other_key:
		return true
	var vm_k = _get_vm()
	if vm_k != null:
		var o = vm_k._get_npcs_by_person_key().get(other_key, null)
		if o != null and family_id != "none" and family_id != "" and family_id != "family_police" and o.family_id == family_id:
			return true
	return false

func learn_feeling_toward(other_key: String) -> void:
	if other_key != "" and not other_key in known_feelings:
		known_feelings.append(other_key)
	heard_feelings.erase(other_key) # ya lo sabes de primera mano

## E4: alguien te cuenta lo que este vecino siente por `other_key` (de oídas: puede quedarse viejo).

func hear_feeling_toward(other_key: String, teller_name: String) -> void:
	if other_key == "" or knows_feeling_toward(other_key):
		return
	heard_feelings[other_key] = {"by": teller_name, "rel": get_relationship_with_npc(other_key)}

func get_known_traits_text() -> String:
	return TraitDiscovery.known_traits_text(self)

func get_relationship_status_text() -> String:
	var rel := "Aliado Familiar (-20% Precios)" if affinity >= 45 else ("Amistoso" if affinity >= 20 else ("Familia Agraviada" if affinity <= -35 else ("Desconfiado" if affinity <= -10 else "Neutral")))
	return "%s (%s) | %s (%d)" % [npc_role, family_name, rel, affinity]

func get_relationship_color() -> Color:
	if affinity >= 45: return Color.CYAN
	if affinity >= 20: return Color.LIGHT_GREEN
	if affinity <= -35: return Color.RED
	return Color.ORANGE if affinity <= -10 else Color(0.85, 0.88, 0.92)


## Si no hay ningún policía a mano, se va a la comisaría: su escritorio (marca de la escena), llevado al mundo.
func _comisaria_pos() -> Vector2:
	return _MARCA.mundo(_COMISARIA_ID, _MARCA.ESCRITORIO)


## Cama de urgencias del hospital, en el mundo (sigue al hospital movido en el editor).
func _cama_urgencias() -> Vector2:
	return _EDIFICIO.a_mundo(_HOSPITAL_ID, _CAMA_URGENCIAS_PLANO)


## ¿Está ese punto del mundo dentro de la comisaría?
func _en_comisaria(p_mundo: Vector2) -> bool:
	return _COMISARIA_PLANO.has_point(_EDIFICIO.a_plano(_COMISARIA_ID, p_mundo))
