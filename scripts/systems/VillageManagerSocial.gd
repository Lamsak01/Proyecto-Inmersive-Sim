@tool
extends "res://scripts/systems/VillageManagerBase.gd"

func _register_authority_npc(node_name: String, npc_name_str: String, title: String, role: VillageNPC.TradeRole, tex_path: String, work_pos: Vector2, bed_pos: Vector2, table_pos: Vector2, stock: Dictionary, fam_id: String, fam_name: String, name_pool: Array) -> VillageNPC:
	var npc := VillageNPC.new()
	npc.name = node_name
	npc.npc_name = npc_name_str
	npc.npc_role = title
	npc.trade_role = role
	npc.tavern_social_pos = _tavern_social_pos
	entities_root.add_child(npc)
	npc.setup_npc(_load_tex(tex_path), work_pos, bed_pos, stock.duplicate(), table_pos, fam_id, fam_name)
	authority_npcs.append(npc)
	trade_npcs[int(role)] = npc
	_authority_slots.append({
		"role": role, "npc": npc, "rehire_timer": 0.0, "vacancy_announced": false,
		"work_pos": work_pos, "bed_pos": bed_pos, "table_pos": table_pos,
		"tex_path": tex_path, "stock": stock.duplicate(),
		"family_id": fam_id, "family_name": fam_name, "title": title, "name_pool": name_pool
	})
	return npc

const SITIO_ENTRADA_OESTE := "entrada_oeste" ## cruces de «Sitios»: por dónde llega andando quien viene de fuera
const SITIO_ENTRADA_ESTE := "entrada_este"

## Devuelve el punto del borde del mapa (camino del oeste o del este, cruces «entrada_…» de «Sitios», ya en el mundo)
## desde la que cualquier nuevo habitante entra caminando físicamente al pueblo (Prohibido el respawn instantáneo en mitad de la calle).

func _get_map_edge_arrival_pos(index: int = 0) -> Vector2:
	var entrada: String = SITIO_ENTRADA_OESTE if index % 2 == 0 else SITIO_ENTRADA_ESTE
	return VillageWork.Sitio.mundo(entrada) + Vector2(0.0, float((index % 3) - 1) * 6.0)

func _check_authority_vacancy_announcements() -> void:
	for slot in _authority_slots:
		var cur_npc: VillageNPC = slot.get("npc")
		if is_instance_valid(cur_npc) and not cur_npc.is_dead:
			continue
		if not bool(slot.get("vacancy_announced", false)):
			slot["vacancy_announced"] = true
			_hint_player("📢 Vacante en el Valle: %s ha muerto. Un reemplazo novato llegará caminando desde el borde del mapa en los próximos días (Máx. %d llegadas/día)." % [str(slot["title"]), MAX_DAILY_ARRIVALS])

func _spawn_authority_replacement(slot: Dictionary) -> VillageNPC:
	var stock_copy: Dictionary = (slot.get("stock", {}) as Dictionary).duplicate()
	var new_npc: VillageNPC = _spawn_generated_newcomer(
		"NPC_Rehired_",
		int(slot["role"]) as VillageNPC.TradeRole,
		int(slot["role"]) as VillageNPC.TradeRole,
		str(slot["title"]) + " (Recién Llegado)",
		_load_tex(str(slot["tex_path"])),
		slot["work_pos"],
		slot["bed_pos"],
		stock_copy,
		slot.get("table_pos", _tavern_social_pos),
		str(slot["family_id"]),
		str(slot["family_name"])
	)
	slot["npc"] = new_npc
	slot["rehire_timer"] = 0.0
	slot["vacancy_announced"] = false
	authority_npcs.append(new_npc)
	trade_npcs[int(slot["role"])] = new_npc
	var dest_b: String = "Hospital" if slot["role"] == VillageNPC.TradeRole.DOCTOR else ("Capilla del Alba" if slot["role"] == VillageNPC.TradeRole.PRIEST else "Comisaría")
	var icon_b: String = "🏥🚶" if slot["role"] == VillageNPC.TradeRole.DOCTOR else ("☀️🚶" if slot["role"] == VillageNPC.TradeRole.PRIEST else "🚓🚶")
	_hint_player("%s %s (%s · Novato 35%%) está entrando al valle por el camino principal hacia el/la %s." % [icon_b, new_npc.npc_name, str(slot["title"]), dest_b])
	return new_npc

func _init_newcomer_generator_registries() -> void:
	_used_first_names.clear()
	_used_person_ids.clear()
	if _newcomer_rng.seed == 0:
		_newcomer_rng.seed = 20261101
	for k in NPCData.INITIAL_PERSON_PROFILES.keys():
		var nm: String = str(k)
		var parts: PackedStringArray = nm.split(" ", false)
		var first_tok: String = parts[parts.size() - 1] if parts.size() > 1 and (parts[0] in ["Dr.", "Dra.", "Comisario", "Comisaria", "Guardia", "Maese", "Hermano", "Hermana"]) else parts[0]
		_used_first_names.append(first_tok)
		var prof_d: Dictionary = NPCData.INITIAL_PERSON_PROFILES[k]
		var pid: String = str(prof_d.get("person_id", ""))
		if pid != "":
			_used_person_ids[pid] = true

func _count_living_genders() -> Vector2i:
	var fem: int = 0
	var male: int = 0
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC and not n.is_dead and n.trade_role not in [VillageNPC.TradeRole.TRAVELING_MERCHANT, VillageNPC.TradeRole.ROYAL_INVESTIGATOR]:
				var g: String = str(n.person_profile.gender) if n.person_profile != null else ("F" if n.npc_name.ends_with("a") else "M")
				if g == "F":
					fem += 1
				else:
					male += 1
	if fem == 0 and male == 0:
		return Vector2i(6, 11)
	return Vector2i(fem, male)

## Paso único para crear cualquier vecino nuevo (autoridades, posadera, artesano, viajero o encargado contratado).

func _spawn_generated_newcomer(
	node_prefix: String,
	role: VillageNPC.TradeRole,
	linked_role: VillageNPC.TradeRole,
	role_label: String,
	tex: Texture2D,
	work_pos: Vector2,
	bed_pos: Vector2,
	stock: Dictionary,
	table_pos: Vector2,
	fam_id: String,
	fam_name: String,
	ya_actuales: bool = false # plan de sitios: true si los sitios ya están traducidos (hijos, trade_configs)
) -> VillageNPC:
	_rehire_counter += 1
	var counts: Vector2i = _count_living_genders()
	var gen: Dictionary = PersonProfile.generate_newcomer(
		int(role), _rehire_counter, _newcomer_rng, _used_first_names, _used_person_ids, counts.x, counts.y
	)
	var prof = gen["profile"]
	var full_name: String = str(gen["full_name"])
	var new_npc := VillageNPC.new()
	new_npc.name = "%s%d_%s" % [node_prefix, _rehire_counter, str(gen["first_name"]).replace(" ", "_")]
	new_npc.npc_name = full_name
	new_npc.npc_role = role_label
	new_npc.trade_role = role
	new_npc.linked_trade = linked_role
	new_npc.days_in_role = 0
	new_npc.tavern_social_pos = _tavern_social_pos
	new_npc.person_profile = prof
	entities_root.add_child(new_npc)
	new_npc.setup_npc(tex, work_pos, bed_pos, stock, table_pos, fam_id, fam_name, ya_actuales)
	new_npc.global_position = _get_map_edge_arrival_pos(_rehire_counter)
	record_social_event("arrival", new_npc, null, "%s llegó al valle (%s)" % [new_npc.npc_name, role_label])
	return new_npc

## B0.6: Registra un evento social relevante (base de "Noticias del pueblo" y chismes entre vecinos) con tope de memoria.

func record_social_event(type_str: String, actor: VillageNPC, target: VillageNPC = null, summary_str: String = "") -> Dictionary:
	var a_id: String = ""
	var a_name: String = ""
	if is_instance_valid(actor):
		a_id = str(actor.person_profile.person_id) if actor.person_profile != null and str(actor.person_profile.person_id) != "" else actor.npc_id
		a_name = actor.npc_name
	var t_id: String = ""
	var t_name: String = ""
	if is_instance_valid(target):
		t_id = str(target.person_profile.person_id) if target.person_profile != null and str(target.person_profile.person_id) != "" else target.npc_id
		t_name = target.npc_name
	var entry: Dictionary = {
		"day": WorldClock.current_day if WorldClock else 1,
		"hour": WorldClock.current_hour if WorldClock else 12,
		"minute": WorldClock.current_minute if WorldClock else 0,
		"type": type_str,
		"actor_id": a_id,
		"actor_name": a_name,
		"target_id": t_id,
		"target_name": t_name,
		"summary": summary_str,
		"uid": _social_event_uid,
	}
	_social_event_uid += 1
	if type_str in GOSSIP_EVENT_TYPES:
		# B6.1: Al principio solo lo saben sus protagonistas; lo que el jugador dijo a escondidas no lo sabe el aludido
		entry["known_by"] = {a_id: true}
		if t_id != "" and not type_str in ["player_slander", "npc_slander"]:
			entry["known_by"][t_id] = true
		# Q3: de quién oyó cada uno el chisme, para poder seguir la pista hasta el origen
		entry["heard_from"] = {a_id: "player"} if type_str == "player_slander" else {}
	social_event_log.append(entry)
	VillageChronicle.on_social_event(self, entry, actor, target)
	VillageFaith.on_social_event(self, entry, actor, target) # G4: los bandos defienden a los suyos
	while social_event_log.size() > MAX_SOCIAL_EVENT_LOG:
		social_event_log.remove_at(0)
	return entry

## B6.1: Eventos que merecen chisme. Son solo información: no mueven relaciones entre vecinos.

func _get_live_gossip() -> Array[Dictionary]:
	return VillageSocialLife._get_live_gossip(self)

func spread_gossip(teller: VillageNPC, listener: VillageNPC) -> Dictionary:
	return VillageSocialLife.spread_gossip(self, teller, listener)

func try_npc_slander(speaker: VillageNPC, listener: VillageNPC, chance: float = -1.0) -> Dictionary:
	return VillageSocialLife.try_npc_slander(self, speaker, listener, chance)

func gossip_text(ev: Dictionary, listener: VillageNPC = null, ver_key: String = "") -> String:
	return VillageSocialLife.gossip_text(ev, listener, ver_key)

func get_news_known_by(npc: VillageNPC, limit: int = 3) -> Array[Dictionary]:
	return VillageSocialLife.get_news_known_by(self, npc, limit)

func get_public_news(limit: int = 4) -> Array[Dictionary]:
	return VillageSocialLife.get_public_news(self, limit)

## Devuelve los eventos sociales más recientes (del más nuevo al más antiguo), con filtro opcional por tipo o vecino.

func get_recent_social_events(limit: int = 15, filter_type: String = "", person_id_or_name: String = "") -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	var p_clean: String = person_id_or_name.strip_edges()
	var i: int = social_event_log.size() - 1
	while i >= 0 and res.size() < limit:
		var ev: Dictionary = social_event_log[i]
		i -= 1
		if filter_type != "" and str(ev.get("type", "")) != filter_type:
			continue
		if p_clean != "":
			var match_p: bool = (
				str(ev.get("actor_id", "")) == p_clean or
				str(ev.get("target_id", "")) == p_clean or
				str(ev.get("actor_name", "")) == p_clean or
				str(ev.get("target_name", "")) == p_clean
			)
			if not match_p:
				continue
		res.append(ev)
	return res

## Indica si queda al menos 1 de las 3 camillas de acero libres en la Morgue del Hospital (`MAX_MORGUE_CAPACITY = 3`),
## o si algún cuerpo en la Morgue ya tiene su caso resuelto/archivado y puede pasar al Cementerio para ceder la camilla

func has_free_morgue_table() -> bool:
	if morgue_active_corpses.size() < MAX_MORGUE_CAPACITY:
		return true
	for rec in morgue_active_corpses:
		if not _is_corpse_under_active_investigation(str(rec.get("victim_name", ""))):
			return true
	return false

func _find_corpse_npc_by_name(target_name: String) -> VillageNPC:
	if target_name == "":
		return null
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.is_dead and v.npc_name == target_name:
				return v
	return null

## Devuelve `true` mientras el caso de homicidio de este cadáver siga abierto (sin resolverse ni archivarse)

func _is_corpse_under_active_investigation(victim_name: String) -> bool:
	if victim_name == "":
		return false
	if bool(active_royal_investigation.get("active", false)):
		var r_stg: String = str(active_royal_investigation.get("stage", ""))
		if str(active_royal_investigation.get("victim_name", "")) == victim_name and r_stg != "DEPARTING":
			return true
	if bool(active_sheriff_investigation.get("active", false)):
		if str(active_sheriff_investigation.get("victim_name", "")) == victim_name:
			return true
	for rec in morgue_active_corpses:
		if str(rec.get("victim_name", "")) == victim_name and rec.has("case_resolved") and not bool(rec.get("case_resolved", true)):
			return true
	return false

func _mark_morgue_case_resolved(victim_name: String, resolution_note: String = "") -> void:
	if victim_name == "":
		return
	var cur_d: int = WorldClock.current_day if WorldClock else 1
	var cur_h: int = WorldClock.current_hour if WorldClock else 12
	var cur_tot_h: int = cur_d * 24 + cur_h
	VillageQuests.on_case_resolved(self, victim_name, resolution_note)
	VillageClans.on_murder_resolved(self, victim_name, resolution_note)
	VillageChronicle.add(self, "case_closed", "Se cerró el caso de la muerte de %s%s" % [victim_name, (": " + resolution_note) if resolution_note != "" else ""], true)
	for rec in morgue_active_corpses:
		if str(rec.get("victim_name", "")) == victim_name:
			rec["case_resolved"] = true
			rec["added_total_hours"] = cur_tot_h
			if resolution_note != "":
				rec["suspect"] = resolution_note
	for rec2 in corpse_records:
		if str(rec2.get("victim_name", "")) == victim_name:
			rec2["case_resolved"] = true
			if resolution_note != "":
				rec2["suspect"] = resolution_note

## Devuelve la posición a la que se llevan los cadáveres cuando las 3 camillas de la Morgue están llenas

func get_cemetery_burial_target_pos() -> Vector2:
	var next_idx: int = buried_graves.size()
	if next_idx >= 0 and next_idx < _cemetery_grave_positions.size():
		return sitio(_cemetery_grave_positions[next_idx])
	return sitio(_cemetery_burial_pos)

## B3.4: Devuelve la posición de la tumba de un difunto en el cementerio (o la puerta del cementerio si aún está en la morgue).

func get_grave_pos_for_victim(victim_name_str: String) -> Vector2:
	var clean: String = victim_name_str.strip_edges()
	for rec in buried_graves:
		if typeof(rec) == TYPE_DICTIONARY and str(rec.get("victim_name", "")).strip_edges() == clean:
			var g_idx: int = int(rec.get("grave_index", -1))
			if g_idx >= 0 and g_idx < _cemetery_grave_positions.size():
				return sitio(_cemetery_grave_positions[g_idx] + Vector2(0, 10))
			return sitio(_cemetery_burial_pos)
	return sitio(_cemetery_gate_pos)

func _refresh_morgue_table_sprites() -> void:
	for i in range(morgue_active_corpses.size()):
		if i < _morgue_table_positions.size():
			var v_name: String = str(morgue_active_corpses[i].get("victim_name", ""))
			var c_node: VillageNPC = _find_corpse_npc_by_name(v_name)
			if is_instance_valid(c_node):
				c_node.corpse_on_ground = false
				c_node.corpse_in_morgue = true
				c_node.corpse_buried = false
				c_node.global_position = sitio(_morgue_table_positions[i])
				if c_node.sprite:
					c_node.sprite.visible = false
				c_node._set_area_col_disabled(c_node.interact_area, false)

## Sepulta físicamente un cuerpo en la siguiente parcela libre del Cementerio Parroquial y crea su lápida e inscripción

func _bury_corpse_in_cemetery(rec: Dictionary, burial_reason: String = "Sepultura parroquial") -> void:
	if bool(rec.get("buried", false)):
		return
	rec["buried"] = true
	rec["burial_reason"] = burial_reason
	rec["burial_day"] = WorldClock.current_day if WorldClock else 1
	var grave_idx: int = buried_graves.size()
	rec["grave_index"] = grave_idx
	buried_graves.append(rec)
	var c_node: VillageNPC = _find_corpse_npc_by_name(str(rec.get("victim_name", "")))
	if is_instance_valid(c_node):
		c_node.corpse_buried = true
		c_node.corpse_in_morgue = true
		c_node.corpse_on_ground = false
		if c_node.status_label:
			c_node.status_label.visible = false
		if c_node.sprite:
			c_node.sprite.visible = false
		c_node._set_area_col_disabled(c_node.interact_area, true)

# ==============================================================================
# PASO 3: 🔓 COFRES DOMÉSTICOS Y ROBO EN SIGILO
# ==============================================================================

func modify_family_reputation(fam_id: String, delta_amount: int, reason: String = "", source_npc: VillageNPC = null) -> void:
	if fam_id == "" or fam_id == "none":
		return
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != source_npc:
			var v: VillageNPC = n as VillageNPC
			if v.family_id == fam_id and not v.is_dead:
				v.affinity = clampi(v.affinity + delta_amount, -100, 100)
				if reason != "":
					v.add_thought("%s (%s%d)" % [reason, "+" if delta_amount >= 0 else "", delta_amount], float(delta_amount) * 0.4)

# ==============================================================================
# MODALES INTERACTIVOS (MORGUE, COMISARÍA/CÁRCEL Y TABLÓN DE ENCARGOS)
# ==============================================================================

func _spawn_unemployed_tavern_guests() -> void:
	var tex_traveler := _load_tex("res://assests/world/village/villager_traveler.png")
	var guest_defs: Array[Dictionary] = [
		{"name": "Aldric", "role": "Viajero sin Oficio", "day_pos": VillageWork.Sitio.original("espera_1"), "bed_pos": VillageTavern.guest_beds()[0]},
		{"name": "Sora", "role": "Forastera sin Oficio", "day_pos": VillageWork.Sitio.original("espera_2"), "bed_pos": VillageTavern.guest_beds()[1]},
		{"name": "Darío", "role": "Jornalero sin Oficio", "day_pos": VillageWork.Sitio.original("espera_3"), "bed_pos": VillageTavern.guest_beds()[2]}
	]
	for g in guest_defs:
		var npc := VillageNPC.new()
		npc.name = "NPC_Guest_" + str(g["name"])
		npc.npc_name = str(g["name"])
		npc.npc_role = str(g["role"])
		npc.trade_role = VillageNPC.TradeRole.UNEMPLOYED
		npc.tavern_social_pos = _tavern_social_pos
		entities_root.add_child(npc)
		npc.setup_npc(tex_traveler, g["day_pos"], g["bed_pos"], {}, _tavern_social_pos, "none", "Huésped de Posada")
		unemployed_npcs.append(npc)

func _spawn_case1_clearing_corpse() -> void:
	var victim_pos: Vector2 = VillageWork.Sitio.mundo(VillageCase1.SITIO_CUERPO) # cruz de «Sitios» en el claro, ya en el mundo
	var tex_victim := _load_tex("res://assests/world/village/villager_traveler.png")
	var npc := VillageNPC.new()
	npc.name = "NPC_Case1_Victim"
	npc.npc_name = "Clara"
	npc.npc_role = "Lavandera"
	npc.trade_role = VillageNPC.TradeRole.UNEMPLOYED
	npc.tavern_social_pos = _tavern_social_pos
	npc.set_meta("scripted_case_id", DetectiveCaseData.CASE_01_ID)
	npc.set_meta("scripted_case_zones", true)
	entities_root.add_child(npc)
	npc.setup_npc(tex_victim, victim_pos, victim_pos, {}, sitio(_tavern_social_pos), "none", "Vecina del Valle", true) # victim_pos ya va traducido
	if npc.person_profile != null:
		npc.person_profile.gender = "F"
		npc.person_profile.age = 26
	npc.global_position = victim_pos
	npc.death_world_pos = victim_pos
	npc.is_dead = true
	npc.corpse_on_ground = true
	npc.corpse_discovered = false
	npc.corpse_reported = false
	npc.corpse_in_morgue = false
	npc.corpse_buried = false
	npc.corpse_rot_hours = 1.8
	npc.last_hit_weapon_name = "Estrangulamiento"
	npc._set_area_col_disabled(npc.hurtbox, true)
	npc._set_area_col_disabled(npc.interact_area, false)
	if npc.sprite:
		npc._set_sprite_pose(90.0, Color(0.68, 0.54, 0.54, 0.96))
		npc.sprite.z_index = -1
		npc.sprite.visible = true
	VillageCase1.mostrar_cuerpo(self, VillageCase1.empezado()) # día de margen: el día 1 el cuerpo aún no está

func _spawn_domestic_pets() -> void:
	var is_demo: bool = (GameManager == null) or (GameManager.has_method("is_demo_mode") and bool(GameManager.call("is_demo_mode")))
	var pet_defs: Array[Dictionary] = [
		{"type": DomesticPet.PetType.DOG, "name": "Toby", "owner": "Granja del Jugador", "fam": "player_farm", "sitio": "mascota_toby", "guard": true, "tint": Color(1.0, 0.96, 0.90)},
		{"type": DomesticPet.PetType.DOG, "name": "Sultán", "owner": "Herrería Yunque Gris", "fam": "family_smith", "sitio": "mascota_sultan", "guard": false, "tint": Color(0.88, 0.82, 0.78)},
		{"type": DomesticPet.PetType.DOG, "name": "Canela", "owner": "Barrio Residencial", "fam": "family_carpenter", "sitio": "mascota_canela", "guard": false, "tint": Color(1.0, 0.85, 0.72)},
		{"type": DomesticPet.PetType.CAT, "name": "Michi", "owner": "Posada El Jabalí Dorado", "fam": "family_tavern", "sitio": "mascota_michi", "guard": false, "tint": Color(1.0, 0.92, 0.82)},
		{"type": DomesticPet.PetType.CAT, "name": "Pelusa", "owner": "Botica Raíz Verde", "fam": "family_herbalist", "sitio": "mascota_pelusa", "guard": false, "tint": Color(0.92, 0.92, 0.98)},
		{"type": DomesticPet.PetType.CAT, "name": "Sombra", "owner": "Pescadería Aguas Claras", "fam": "family_fishmonger", "sitio": "mascota_sombra", "guard": false, "tint": Color(0.75, 0.78, 0.85)}
	]
	for pdef in pet_defs:
		if is_demo and str(pdef["fam"]) == "player_farm":
			continue
		var p_pos: Vector2 = VillageWork.Sitio.mundo(str(pdef["sitio"])) # cama y cuenco: su cruz de «Sitios», ya en el mundo
		_spawn_pet_bed_and_bowl(p_pos, pdef["type"], str(pdef["name"]))
		var pet := DomesticPet.new()
		pet.name = "Pet_" + str(pdef["name"])
		pet.pet_type = pdef["type"]
		pet.pet_name = str(pdef["name"])
		pet.owner_label = str(pdef["owner"])
		pet.family_id = str(pdef["fam"])
		pet.home_position = p_pos
		pet.global_position = p_pos
		pet.is_guard_dog = bool(pdef["guard"])
		pet.tint_color = pdef["tint"]
		entities_root.add_child(pet)
		domestic_pets.append(pet)

func _spawn_pet_bed_and_bowl(pos: Vector2, p_type: int, _p_name: String) -> void:
	if not is_instance_valid(entities_root):
		return
	var bed_root := Node2D.new()
	bed_root.name = "PetBed_" + _p_name
	bed_root.global_position = pos
	bed_root.set_meta("pet_type", p_type)
	entities_root.add_child(bed_root)

func can_family_feed_pet(fam_id: String) -> bool:
	if fam_id == "player_farm":
		for r_id in [int(VillageNPC.TradeRole.FISHMONGER), int(VillageNPC.TradeRole.BUTCHER), int(VillageNPC.TradeRole.HERBALIST), int(VillageNPC.TradeRole.BAKER)]:
			if get_trade_total_stock(r_id) > 0:
				return true
		return is_instance_valid(_innkeeper_npc) and not _innkeeper_npc.is_dead
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.family_id == fam_id and not v.is_dead and not v.is_downed:
				return true
	return false

func _get_nearest_well_dist_sq(pos: Vector2) -> float:
	var best_d2: float = INF
	for w_pos in _well_positions:
		var d2: float = pos.distance_squared_to(w_pos)
		if d2 < best_d2:
			best_d2 = d2
	return best_d2

## Devuelve `true` si `world_pos` está a `<= max_meters` (por defecto 2.0m = 32 px del borde) de cualquier fuente de agua
## (Pozos de Agua de la Granja/Taberna/Plaza, Lago del Oeste, Ciénaga de las Ranas o lavabo de Urgencias del Hospital).

func is_position_near_water_source(world_pos: Vector2, max_meters: float = 2.0) -> bool:
	var max_well_dist: float = max_meters * 16.0 + 6.0 # 2m (32 px) desde el brocal del pozo (~6 px de radio) = 38 px
	for w_pos in _well_positions:
		if world_pos.distance_squared_to(w_pos) <= max_well_dist * max_well_dist:
			return true
	for spot in get_tree().get_nodes_in_group("fishing_spots"):
		if spot is Node2D:
			var s_pos: Vector2 = (spot as Node2D).global_position
			if not bool(spot.get("is_river_spot")):
				# El Lago del Oeste: su contorno (mapa ×E) más el margen en metros
				var orilla: PackedVector2Array = FishingSpot.lake_scaled(1.0, max_meters * 16.0 + 6.0) * Transform2D(0.0, Vector2.ONE * Mapa3D.E, 0.0, Vector2.ZERO)
				if Geometry2D.is_point_in_polygon(world_pos, orilla):
					return true
			if world_pos.distance_squared_to(s_pos + (spot.get("dock_pos") as Vector2)) <= max_well_dist * max_well_dist:
				return true
	# Charca de agua de la Ciénaga del Suroeste
	if Rect2(Vector2(-1910, 165), Vector2(710, 320)).grow(max_meters * 16.0).has_point(world_pos):
		return true
	# Arroyo / Fuente del Lavadero del pueblo
	if world_pos.distance_squared_to(VillageWork.Sitio.mundo(VillageWork.SITIO_LAVADERO)) <= max_well_dist * max_well_dist:
		return true
	# Lavabo quirúrgico junto a la Cama de Urgencias del Hospital
	if world_pos.distance_squared_to(sitio(_hospital_bed_pos)) <= max_well_dist * max_well_dist:
		return true
	# Cauce del río de norte a sur y arroyo del bosque norte
	if world_pos.y >= FishingSpot.river_y_start() and world_pos.y <= FishingSpot.river_y_end():
		var riv_cx: float = FishingSpot.river_center_x(world_pos.y)
		var riv_hw: float = FishingSpot.river_half_width(world_pos.y)
		if absf(world_pos.x - riv_cx) <= riv_hw + max_meters * 16.0:
			return true
	return false

# ==============================================================================
# INTERACCIÓN CENTRAL CON TODAS LAS ESTACIONES DE LA ALDEA
# ==============================================================================
## Prioridad de interacción [E]: garantiza que el jugador siempre pueda abrir una puerta cerrada aunque haya un NPC parado encima,
## y permite reportar cualquier cadáver en el suelo con [E].

func get_hangout_spots() -> Array:
	var spots: Array = []
	if not is_building_door_blocked("tavern"):
		spots.append({"id": "tavern", "pos": sitio(_tavern_social_pos + Vector2(0, 14)), "kind": "tavern", "label": "la Taberna"})
	spots.append({"id": "plaza_well", "pos": sitio(_plaza_well_pos + Vector2(0, 24)), "kind": "well", "label": "el Pozo de la Plaza"})
	spots.append({"id": "plaza_bench", "pos": sitio(Vector2(468, 54)), "kind": "bench", "label": "el Rincón de la Plaza"})
	spots.append({"id": "plaza_board", "pos": sitio(_notice_board_pos + Vector2(0, 26)), "kind": "plaza", "label": "la Plaza Central"})
	spots.append({"id": "farm_well", "pos": sitio(_well_pos + Vector2(0, 24)), "kind": "well", "label": "el Pozo de la Granja"})
	spots.append_array(VillagePlaces.hangout_spots()) # V5c
	return spots

func _is_npc_eligible_for_hangout(v: VillageNPC) -> bool:
	return VillageSocialLife._is_npc_eligible_for_hangout(self, v)

func _get_npcs_by_person_key() -> Dictionary:
	var out: Dictionary = {}
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and not (n as VillageNPC).is_dead:
			out[(n as VillageNPC).get_person_key()] = n
	return out

func _spot_label_for(spot_id: String) -> String:
	for sp in get_hangout_spots():
		if str(sp.get("id", "")) == spot_id:
			return str(sp.get("label", ""))
	return ""

# ==============================================================================
# B4.2: PELEAS DISCRETAS EN VIVO — el Director decide, aquí se representan y se aplican las consecuencias
# ==============================================================================

func _is_npc_free_to_fight(v: VillageNPC) -> bool:
	return VillageSocialLife._is_npc_free_to_fight(self, v)

func _find_fight_guard(pos: Vector2, a: VillageNPC, b: VillageNPC) -> VillageNPC:
	return VillageSocialLife._find_fight_guard(self, pos, a, b)

func _scan_rival_friction() -> void:
	VillageSocialLife._scan_rival_friction(self)

func _try_start_live_fight() -> void:
	VillageSocialLife._try_start_live_fight(self)

func _update_live_fights(delta: float) -> void:
	VillageSocialLife._update_live_fights(self, delta)

func player_stop_live_fight(npc: VillageNPC) -> bool:
	return VillageSocialLife.player_stop_live_fight(self, npc)

func _finish_live_fight(fight: Dictionary, a: VillageNPC, b: VillageNPC, interrupted: bool, guard_stops: bool) -> void:
	VillageSocialLife._finish_live_fight(self, fight, a, b, interrupted, guard_stops)

func _update_social_hangouts(delta: float) -> void:
	VillageSocialLife._update_social_hangouts(self, delta)

# ==============================================================================
# B3.1: AVANCE DIARIO DE CORTEJOS EN VIVO (Interés → Coqueteo → Citas → Pareja)
# ==============================================================================

func _advance_live_romances(cur_day: int) -> Dictionary:
	if social_director == null:
		return {}
	var by_key: Dictionary = _get_npcs_by_person_key()
	var profiles: Dictionary = {}
	var families: Dictionary = {}
	for k in by_key.keys():
		var v: VillageNPC = by_key[k]
		if v.person_profile != null and not v.is_dead:
			if int(v.person_profile.bereavement_days_left) > 0:
				var d_nm: String = str(v.person_profile.deceased_partner_name)
				var ended: bool = v.person_profile.tick_bereavement_day()
				if ended:
					v.add_thought("Aunque siempre recordaré a %s, la vida continúa (+4)" % d_nm, 4.0)
					record_social_event("bereavement_ended", v, null, "%s ha superado los días más duros del luto por %s" % [v.npc_name, d_nm])
				else:
					v.add_thought("Sigo de luto por la pérdida de %s (-12)" % d_nm, -12.0)
			profiles[k] = v.person_profile
			families[k] = v.family_id
	var res: Dictionary = social_director.advance_live_romance_day(cur_day, profiles, families)
	for adv in res.get("advanced", []):
		var a: VillageNPC = by_key.get(str(adv.get("id_a", "")), null)
		var b: VillageNPC = by_key.get(str(adv.get("id_b", "")), null)
		if not is_instance_valid(a) or not is_instance_valid(b):
			continue
		var to_st: String = str(adv.get("to", ""))
		if to_st == "couple":
			var rel_now: int = a.get_relationship_with_npc(b.get_person_key())
			a.modify_npc_relationship(b, maxi(0, 68 - rel_now), "💑 Pareja: decidieron estar juntos")
			a.add_thought("¡Ahora estoy en pareja con %s! (+15)" % b.npc_name, 15.0)
			b.add_thought("¡Ahora estoy en pareja con %s! (+15)" % a.npc_name, 15.0)
			a._spawn_floating_text("💑 ¡%s y %s ahora son pareja!" % [a.npc_name, b.npc_name], Color(1.0, 0.55, 0.75), -46.0)
			record_social_event("couple", a, b, "%s y %s ahora son pareja" % [a.npc_name, b.npc_name])
			VillageSocialLife.on_new_couple_jealousy(self, a, b)
		else:
			if to_st in ["flirt", "dating"]:
				a.add_thought("Me hace ilusión lo que tengo con %s (+5)" % b.npc_name, 5.0)
				b.add_thought("Me hace ilusión lo que tengo con %s (+5)" % a.npc_name, 5.0)
			record_social_event("romance_" + to_st, a, b, "%s y %s %s" % [a.npc_name, b.npc_name, str(ROMANCE_STAGE_NAMES.get(to_st, "se acercan"))])
	for rj in res.get("rejections", []):
		VillageSocialLife.on_rejection(self, by_key.get(str(rj.get("from", "")), null), by_key.get(str(rj.get("to", "")), null))
	for fz in res.get("fizzled", []):
		var fa: VillageNPC = by_key.get(str(fz.get("id_a", "")), null)
		var fb: VillageNPC = by_key.get(str(fz.get("id_b", "")), null)
		if is_instance_valid(fa) and is_instance_valid(fb):
			record_social_event("romance_fizzle", fa, fb, "Lo de %s y %s se enfrió" % [fa.npc_name, fb.npc_name])
	for brk in res.get("breakups", []):
		var ba: VillageNPC = by_key.get(str(brk.get("id_a", "")), null)
		var bb: VillageNPC = by_key.get(str(brk.get("id_b", "")), null)
		if is_instance_valid(ba) and is_instance_valid(bb):
			ba.modify_npc_relationship(bb, -10, "💔 Ex-pareja tras una ruptura")
			ba.add_thought("Rompí mi relación con %s (-14)" % bb.npc_name, -14.0)
			bb.add_thought("Rompí mi relación con %s (-14)" % ba.npc_name, -14.0)
			ba._spawn_floating_text("💔 ¡%s y %s han roto su relación!" % [ba.npc_name, bb.npc_name], Color(1.0, 0.38, 0.45), -46.0)
			record_social_event("breakup", ba, bb, "%s y %s han roto su relación" % [ba.npc_name, bb.npc_name])
	for rec in res.get("reconciled", []):
		var rca: VillageNPC = by_key.get(str(rec.get("id_a", "")), null)
		var rcb: VillageNPC = by_key.get(str(rec.get("id_b", "")), null)
		if is_instance_valid(rca) and is_instance_valid(rcb):
			var rel_r: int = rca.get_relationship_with_npc(rcb.get_person_key())
			rca.modify_npc_relationship(rcb, maxi(10, 62 - rel_r), "💑 Pareja reconciliada")
			rca.add_thought("Me reconcilié con %s (+14)" % rcb.npc_name, 14.0)
			rcb.add_thought("Me reconcilié con %s (+14)" % rca.npc_name, 14.0)
			rca._spawn_floating_text("💑✨ ¡%s y %s se han reconciliado!" % [rca.npc_name, rcb.npc_name], Color(1.0, 0.62, 0.80), -46.0)
			record_social_event("couple_reconciled", rca, rcb, "%s y %s se han reconciliado y vuelven a ser pareja" % [rca.npc_name, rcb.npc_name])
	return res

func _on_quests_changed(_qid: String) -> void:
	VillageQuests.refresh_markers(self)
	var qm_c = get_node_or_null("/root/QuestManager")
	if qm_c != null and _qid != "":
		var q_c: Dictionary = qm_c.get_quest(_qid)
		if not q_c.is_empty():
			VillageChronicle.on_quest_changed(self, q_c)

func _note_inheritance(heir: VillageNPC, dead: VillageNPC) -> void:
	heir.set_meta("inherited_day", WorldClock.current_day if WorldClock else 1)
	if is_instance_valid(dead):
		heir.set_meta("inherited_from", dead.npc_name)
		heir.set_meta("inherited_family", dead.family_id)

func _pick_ambitious_successor(_role_key, title: String) -> VillageNPC:
	var best: VillageNPC = null
	var best_s: float = -INF
	var rivals: Array = []
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if not (n is VillageNPC) or n.is_dead or n.is_downed or VillageNeeds.is_outsider(n) or n.person_profile == null or int(n.person_profile.age) < 16:
			continue
		if n.get_person_key() == VillageFamilia.INITIAL_BOSS_ID or VillageFamilia.boss_of(self) == n:
			continue
		var amb: float = TraitCatalog.npc_tendency(n, "ambition")
		if n.trade_role == VillageNPC.TradeRole.FAMILY_MEMBER:
			if amb < 0.5:
				continue
		elif n.trade_role != VillageNPC.TradeRole.UNEMPLOYED:
			continue
		var sc: float = 1.2 * amb + 0.4 * TraitCatalog.npc_tendency(n, "diligence") + float(n.personal_gold) / 150.0
		if amb >= 0.5:
			rivals.append(n)
		if sc > best_s:
			best_s = sc
			best = n
	if best == null or (best.trade_role == VillageNPC.TradeRole.UNEMPLOYED and TraitCatalog.npc_tendency(best, "ambition") < 0.5):
		return null # Sin nadie ambicioso: sigue la regla de siempre (el primero sin oficio)
	unemployed_npcs.erase(best)
	for fk in family_npcs.keys():
		if family_npcs[fk] == best:
			family_npcs.erase(fk)
			break
	for r in rivals:
		if r != best:
			r.modify_npc_relationship(best, -6, "Se quedó el taller que yo quería", true)
	var d: Dictionary = VillageDesires.active_of(self, best.get_person_key())
	if not d.is_empty() and str(d.get("type", "")) == "ambition":
		VillageDesires.finish(self, d, "satisfied")
	best.add_thought("¡Por fin un negocio propio! (+12)", 12.0)
	VillageChronicle.add(self, "ambition_business", "%s, con ganas de prosperar, se quedó el puesto vacante de %s" % [best.npc_name, title], true)
	return best

func _pop_living_unemployed() -> VillageNPC:
	for i in range(unemployed_npcs.size()):
		var cand: VillageNPC = unemployed_npcs[i]
		if is_instance_valid(cand) and not cand.is_dead and cand.trade_role == VillageNPC.TradeRole.UNEMPLOYED:
			unemployed_npcs.remove_at(i)
			return cand
	return null

# ==============================================================================
# FASE 8: ECONOMÍA DINÁMICA DE OFERTA Y DEMANDA, CONSUMO REAL, SABOTAJE Y PROPIEDAD DE NEGOCIOS
# ==============================================================================
