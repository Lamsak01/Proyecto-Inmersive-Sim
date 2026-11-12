@tool
extends "res://scripts/systems/VillageManagerPolice.gd"


const SHOP_LABEL_OFFSET: Vector2 = Vector2(-130.0, 14.0) ## del mostrador a la esquina del letrero de «gestionar negocio»


func get_village_security_level() -> int:
	var sec: int = wanted_level + corpse_records.size() * 2 + int(ceil(float(recent_breakins_count) * 0.5))
	return clampi(sec, 0, 5)

func get_village_security_text() -> String:
	var lvl: int = get_village_security_level()
	if lvl <= 0:
		return "🟢 Tranquila"
	elif lvl <= 2:
		return "🟡 Desconfiada (Nv.%d)" % lvl
	return "🔴 Alerta Máxima (Nv.%d)" % lvl

func _get_building_family_affinity(b_id: String) -> int:
	var target_fam: String = ""
	if b_id == "building_tavern":
		target_fam = "family_tavern"
	elif b_id.begins_with("house_"):
		target_fam = b_id.trim_prefix("house_")
	elif b_id.begins_with("shop_"):
		target_fam = b_id.trim_prefix("shop_")
	elif b_id.begins_with("mixed_"):
		target_fam = b_id.trim_prefix("mixed_")
	if target_fam == "":
		return 10
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v := n as VillageNPC
			if v.family_id == target_fam and not v.is_dead:
				return v.affinity
	return 10

func _apply_hourly_door_security_schedule(hour: int) -> void:
	var sec_lvl: int = get_village_security_level()
	var tex_win_open := _load_tex("res://assests/world/village/window_glass_open.png")
	var tex_win_shut := _load_tex("res://assests/world/village/window_shutter_closed.png")

	for d_entry in building_doors:
		if bool(d_entry.get("locked_by_player", false)) or float(d_entry.get("manual_override_timer", 0.0)) > 0.0:
			continue
		var b_id: String = str(d_entry.get("building_id", ""))
		var fam_aff: int = _get_building_family_affinity(b_id)

		# Las puertas permanecen físicamente cerradas (`is_open = false`) salvo cuando alguien las cruza o las abre;
		# el horario y el nivel de seguridad determinan si además están cerradas con llave (`is_locked = true`).
		if b_id == "building_hospital" or b_id == "building_police" or b_id == "building_church" or b_id == "building_library" or b_id == "building_school":
			_set_door_state(d_entry, false, false, false)
		elif b_id == "building_abandoned_mill":
			_set_door_state(d_entry, true, false, false)
		elif b_id == "building_tavern":
			var tav_close_h: int = 21 if sec_lvl >= 3 else 23
			var lock_tav: bool = (hour >= tav_close_h or hour < 6) and sec_lvl >= 2
			_set_door_state(d_entry, false, lock_tav, false)
		elif b_id.begins_with("shop_") or b_id.begins_with("mixed_"):
			# Si el jugador es Socio o Dueño del negocio, siempre tiene llave de su local
			var player_owns_this_shop: bool = false
			for r_k in shop_businesses.keys():
				var biz_chk: Dictionary = shop_businesses[int(r_k)]
				if ("shop_" + str(biz_chk.get("family_id", "")) == b_id or "mixed_" + str(biz_chk.get("family_id", "")) == b_id) and str(biz_chk.get("owner_mode", "NPC")) in ["PARTNER", "SOLE_OWNER"]:
					player_owns_this_shop = true
					break
			if player_owns_this_shop:
				_set_door_state(d_entry, false, false, false)
			elif b_id.begins_with("mixed_"):
				# La Botica-Vivienda mixta sigue la misma regla de confianza vecinal que las casas cuando el nivel de alerta es bajo
				if sec_lvl == 0 and fam_aff >= 0:
					_set_door_state(d_entry, false, false, false)
				else:
					var mix_open: bool = (hour >= 7 and hour < 20 and fam_aff > -35)
					_set_door_state(d_entry, false, not mix_open, false)
			else:
				var shop_open_h: int = 8 if sec_lvl >= 1 else 7
				var shop_close_h: int = 17 if sec_lvl >= 3 else (18 if sec_lvl >= 1 else 20)
				var is_open_hours: bool = (hour >= shop_open_h and hour < shop_close_h and fam_aff > -35)
				var lock_shop: bool = (not is_open_hours) and (sec_lvl >= 1 or fam_aff < 0 or hour >= 21 or hour < 6)
				_set_door_state(d_entry, false, lock_shop, false)
		elif b_id.begins_with("house_"):
			# Cuando el nivel de alerta en el pueblo es bajo (`sec_lvl == 0`) y la familia no desconfía de ti (`fam_aff >= 0`),
			# las puertas de las casas están cerradas pero SIN LLAVE (`is_locked = false`).
			# Solo echan la llave cuando sube la alerta en el pueblo (`sec_lvl >= 1`) o si la familia te tiene rencor (`fam_aff < 0`).
			if sec_lvl == 0 and fam_aff >= 0:
				_set_door_state(d_entry, false, false, false)
			else:
				var night_lock_h: int = 18 if (sec_lvl >= 3 or fam_aff < 0) else 20
				if hour >= night_lock_h or hour < 7:
					_set_door_state(d_entry, false, true, false)
				else:
					var day_lock: bool = (sec_lvl >= 3 or fam_aff <= -15)
					_set_door_state(d_entry, false, day_lock, false)

	for w_entry in building_windows:
		if float(w_entry.get("manual_override_timer", 0.0)) > 0.0:
			continue
		var wb_id: String = str(w_entry.get("building_id", ""))
		var w_aff: int = _get_building_family_affinity(wb_id)
		var should_shutter: bool = ((hour >= 21 or hour < 6) and sec_lvl >= 1) or (sec_lvl >= 2) or (w_aff < 0)
		w_entry["is_shuttered"] = should_shutter
		var w_spr: Sprite2D = w_entry.get("sprite")
		if is_instance_valid(w_spr):
			w_spr.texture = tex_win_shut if should_shutter else tex_win_open

func _interact_building_door(player: Node2D, d_entry: Dictionary) -> void:
	var is_open_now: bool = bool(d_entry.get("is_open", true))
	var is_locked_now: bool = bool(d_entry.get("is_locked", false))
	var locked_by_p: bool = bool(d_entry.get("locked_by_player", false))
	var b_title: String = str(d_entry.get("building_title", "Edificio"))
	d_entry["manual_override_timer"] = 65.0

	if is_open_now:
		_set_door_state(d_entry, false, false, false)
		_msg_player(player, "🚪 Puerta cerrada (Oculta la visión desde fuera)", Color(0.90, 0.85, 0.70), -42.0)
		return
	if locked_by_p:
		_set_door_state(d_entry, true, false, false)
		_msg_player(player, "🔓 Quitaste tu cerrojo y abriste la puerta", Color.SPRING_GREEN, -42.0)
		return
	if not is_locked_now:
		_set_door_state(d_entry, true, false, false)
		_msg_player(player, "🚪 Puerta abierta", Color.SPRING_GREEN, -42.0)
		return

	_msg_player(player, "🔒 Cerrada con llave — Pulsa [F] para forzar cerradura", Color.GOLD, -42.0)
	_hint_player("🔒 La puerta de %s está cerrada con llave. Pulsa [F] si quieres forzar la cerradura (usa Sigilo [C])." % b_title, player)

## Tecla [F]: Acción dedicada para Forzar Cerraduras de puertas, Postigos de ventanas o Barrotes de la Celda (Separada de [E])

func force_lock_or_shutter_by_player(player: Node2D) -> bool:
	if not player:
		return false

	# 1. Si el jugador está encerrado en la Celda Policial, [F] fuerza los barrotes para fugarse
	if player_in_jail:
		_on_police_jailbreak_or_resist(player)
		return true

	# 2. ¿Está ante una puerta cerrada con llave?
	var d_entry: Dictionary = _find_nearest_door(player.global_position, 28.0)
	if not d_entry.is_empty():
		var is_open_now: bool = bool(d_entry.get("is_open", true))
		var is_locked_now: bool = bool(d_entry.get("is_locked", false))
		var locked_by_p: bool = bool(d_entry.get("locked_by_player", false))
		var b_title: String = str(d_entry.get("building_title", "Edificio"))

		if is_open_now or not is_locked_now or locked_by_p:
			_msg_player(player, "🚪 Esta puerta no tiene llave ajena (Usa [E] para abrirla)", Color.LIGHT_GRAY, -40.0)
			return true

		d_entry["manual_override_timer"] = 65.0
		recent_breakins_count += 1
		_set_door_state(d_entry, true, false, false)
		var in_stealth: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
		var cloak_mult: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
		var lockpick_mult: float = 0.35 if (player.has_method("has_master_lockpick") and bool(player.call("has_master_lockpick"))) else 1.0
		var detect_rad: float = (42.0 if in_stealth else 145.0) * cloak_mult * lockpick_mult
		var witness: VillageNPC = _find_conscious_witness_near(d_entry.get("pos", player.global_position), detect_rad, null)
		if witness == null:
			_msg_player(player, "🔓🤫 Cerradura forzada con [F] en sigilo: %s (Sin testigos)" % b_title, Color.SPRING_GREEN, -44.0)
		else:
			wanted_level = clampi(wanted_level + 1, 1, 5)
			bounty_gold += 20
			var msg := "🚨👁️ ¡%s te vio forzar la cerradura de %s! (+20 Oro de multa)" % [witness.npc_name, b_title]
			crime_history.push_front(msg)
			_notify_inquisitor_of_police_crime(msg, 12)
			_msg_player(player, msg, Color.ORANGE_RED, -46.0)
		return true

	# 3. ¿Está ante una ventana con postigo cerrado?
	var w_entry: Dictionary = _find_nearest_window(player.global_position, 24.0)
	if not w_entry.is_empty():
		var b_rect: Rect2 = w_entry.get("building_rect", Rect2())
		var w_pos: Vector2 = w_entry.get("pos", Vector2.ZERO)
		var door_south: bool = bool(w_entry.get("door_south", true))
		var wb_title: String = str(w_entry.get("building_title", "Edificio"))
		var player_inside: bool = b_rect.has_point(player.global_position)
		if not player_inside and bool(w_entry.get("is_shuttered", false)):
			w_entry["is_shuttered"] = false
			w_entry["manual_override_timer"] = 120.0
			recent_breakins_count += 1
			var w_spr: Sprite2D = w_entry.get("sprite")
			if is_instance_valid(w_spr):
				w_spr.texture = _load_tex("res://assests/world/village/window_glass_open.png")
			var in_stealth2: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
			var cloak_mult2: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
			var lockpick_mult2: float = 0.35 if (player.has_method("has_master_lockpick") and bool(player.call("has_master_lockpick"))) else 1.0
			var detect_rad2: float = (38.0 if in_stealth2 else 130.0) * cloak_mult2 * lockpick_mult2
			var witness2: VillageNPC = _find_conscious_witness_near(w_pos, detect_rad2, null)
			if witness2 != null:
				wanted_level = clampi(wanted_level + 1, 1, 5)
				bounty_gold += 20
				var w_msg := "🚨👁️ ¡%s te vio forzar la ventana de %s! (+20 Oro de multa)" % [witness2.npc_name, wb_title]
				crime_history.push_front(w_msg)
				_notify_inquisitor_of_police_crime(w_msg, 12)
				_msg_player(player, w_msg, Color.ORANGE_RED, -46.0)
			else:
				_msg_player(player, "🪟🔓 Forzaste el postigo con [F] y entraste por la ventana", Color.SPRING_GREEN, -44.0)
			player.global_position = w_pos + Vector2(0, -15.0 if door_south else 15.0)
			return true

	# 4. ¿Está junto al expositor de armas de la Herrería (marca «expositor»)? -> [F] Robar arma o munición
	if player.global_position.distance_to(sitio(VillageCulture.armory_rack_pos())) <= 32.0:
		var inv_arm = player.get("inventory")
		if inv_arm != null:
			var want_rf: bool = inv_arm.has_item("flintlock_pistol", 1) and not inv_arm.has_item("assault_rifle", 1)
			var act_arm: String = "culture_steal_rifle" if want_rf else ("culture_steal_firearm" if not inv_arm.has_item("flintlock_pistol", 1) else "culture_steal_pistol_ammo")
			VillageCulture.on_player_action(self, null, act_arm, inv_arm)
			return true

	# 5. ¿Está junto al mostrador/taller de un negocio (`shop_businesses`)? -> [F] Sabotear Taller Industrial
	var stall_entry: Dictionary = _find_nearest_business_stall(player.global_position, 28.0)
	if not stall_entry.is_empty():
		var s_role: int = int(stall_entry.get("role", -1))
		sabotage_shop_stall(player, s_role)
		return true

	return false

## Tecla [B]: Permite al jugador cerrar y trancar con cerrojo cualquier puerta cercana (o desbloquearla)

func toggle_bar_door_by_player(player: Node2D) -> bool:
	if not player:
		return false
	var d_entry: Dictionary = _find_nearest_door(player.global_position, 28.0)
	if d_entry.is_empty():
		return false
	d_entry["manual_override_timer"] = 120.0
	var currently_barred: bool = bool(d_entry.get("locked_by_player", false)) and not bool(d_entry.get("is_open", true))
	if not currently_barred:
		_set_door_state(d_entry, false, true, true)
		_msg_player(player, "🚪🔒 ¡Puerta cerrada y trancada con cerrojo! (Impide el paso y la visión)", Color.GOLD, -44.0)
	else:
		_set_door_state(d_entry, false, false, false)
		_msg_player(player, "🔓 Quitaste el cerrojo de la puerta", Color.SPRING_GREEN, -42.0)
	return true

func _interact_building_window(player: Node2D, w_entry: Dictionary) -> void:
	var b_rect: Rect2 = w_entry.get("building_rect", Rect2())
	var w_pos: Vector2 = w_entry.get("pos", Vector2.ZERO)
	var door_south: bool = bool(w_entry.get("door_south", true))
	var b_title: String = str(w_entry.get("building_title", "Edificio"))
	if not b_rect.has_point(player.global_position):
		if bool(w_entry.get("is_shuttered", false)):
			_msg_player(player, "🪟🔒 Postigo cerrado — Pulsa [F] para forzar ventana", Color.GOLD, -42.0)
			_hint_player("🪟🔒 La ventana de %s tiene el postigo echado. Pulsa [F] para forzarla." % b_title, player)
			return
		player.global_position = w_pos + Vector2(0, -15.0 if door_south else 15.0)
		_msg_player(player, "🪟🤫 Te colaste por la ventana de %s" % b_title, Color.AQUA, -44.0)
	else:
		player.global_position = w_pos + Vector2(0, 15.0 if door_south else -15.0)
		_msg_player(player, "🪟🏃 Saliste al exterior por la ventana", Color.AQUA, -44.0)

func _interact_house_chest(player: Node2D, ch: Dictionary) -> void:
	var cur_day: int = WorldClock.current_day if WorldClock else 1
	var inv: SimpleInventory = player.get("inventory")
	if int(ch.get("looted_day", -1)) == cur_day:
		if inv:
			for ev_id in ["royal_safe_conduct", "organ_heart", "organ_liver", "organ_kidney", "organ_lung", "organ_stomach", "organ_eye"]:
				if inv.remove_item(ev_id, 1):
					ch["planted_evidence"] = ev_id
					ch["planted_by_player"] = true
					var ev_name: String = inv.get_item_name(ev_id)
					var ch_title_ev: String = str(ch.get("title", "Cofre"))
					_msg_player(player, "🕵️📥 ¡Plantaste %s dentro de %s! (Incriminará a esta familia en la investigación)" % [ev_name, ch_title_ev], Color.VIOLET, -46.0)
					return
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("📦 Este cofre ya fue abierto hoy (Lleva el Salvoconducto o un Órgano y pulsa [E] para plantar pruebas)", Color.LIGHT_GRAY, -42.0)
		return

	# P6.2: el cofre de tu propia casa no regala oro (antes daba 18–32 al día). Tu oro a salvo va en el escondite.
	if VillageHousing.is_player_family_chest(self, str(ch.get("family_id", ""))):
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("📦🏡 Es tu cofre: aquí no hay nada que no hayas puesto tú. (Para esconder oro, pide al carpintero un escondite)", Color.LIGHT_GRAY, -46.0)
		return

	ch["looted_day"] = cur_day
	var spr: Sprite2D = ch.get("sprite")
	if is_instance_valid(spr):
		spr.texture = _load_tex("res://assests/world/village/house_chest_open.png")

	var gold_loot: int = randi_range(18, 32)
	if str(ch.get("family_id", "")) == "town_hall":
		gold_loot = VillageCivic.rob_coffers(self) # V5b: sale de las arcas de verdad (puede estar casi vacía)
	else:
		# Regla 1: los ahorros del cofre son de la familia; se los quitas a sus miembros (si no tienen, no hay nada).
		gold_loot = _take_family_savings(str(ch.get("family_id", "")), gold_loot)
	var bonus_pool: Array[String] = ["bread", "iron_ore", "copper_coil", "herbal_poultice", "sleeping_draught"]
	var bonus_item: String = bonus_pool[randi() % bonus_pool.size()]
	if inv:
		inv.add_gold(gold_loot)
		inv.add_item(bonus_item, 1)

	var in_stealth: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
	var cloak_mult3: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
	var lockpick_mult3: float = 0.35 if (player.has_method("has_master_lockpick") and bool(player.call("has_master_lockpick"))) else 1.0
	var detect_rad: float = (52.0 if in_stealth else 135.0) * cloak_mult3 * lockpick_mult3
	var witness: VillageNPC = _find_conscious_witness_near(player.global_position, detect_rad, null)

	if witness == null:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🔓🤫 Robo en sigilo perfecto: +%d Oro, +1 %s (Sin testigos)" % [gold_loot, SimpleInventory.CATALOG.get(bonus_item, {}).get("name", bonus_item)], Color.SPRING_GREEN, -46.0)
	else:
		wanted_level = clampi(wanted_level + 1, 1, 5)
		bounty_gold += 30
		var fam_id: String = str(ch.get("family_id", "none"))
		var ch_title: String = str(ch.get("title", "Cofre"))
		var chest_crime_msg := "🚨👁️ ¡%s vio al Forastero saquear %s! (+30 Oro de multa)" % [witness.npc_name, ch_title]
		crime_history.push_front(chest_crime_msg)
		_notify_inquisitor_of_police_crime(chest_crime_msg, 15)
		modify_family_reputation(fam_id, -35, "Robo de cofre visto por " + witness.npc_name)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🚨👁️ ¡%s te vio forzar el cofre! (+30 Oro de multa policial)" % witness.npc_name, Color.ORANGE_RED, -46.0)

func _use_hospital_emergency_bed(player: Node2D) -> void:
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var v: VillageNPC = n as VillageNPC
			if v.is_downed and not v.is_dead and v.global_position.distance_to(player.global_position) <= 90.0:
				v.revive_from_downed(player, false)
				return

	var health: HealthComponent = player.get_node_or_null("HealthComponent")
	if health and health.current_health >= health.max_health - 0.1 and not health.is_bleeding and health.current_blood <= 0.1 and health.wounds.is_empty() and not health.has_active_sickness_or_infection():
		_msg_player(player, "🏥 Tu salud ya está al 100%, sin heridas ni infecciones", Color.LIGHT_GRAY, -42.0)
		return
	var already_resting: bool = health != null and health.is_resting_in_bed
	var inv: SimpleInventory = player.get("inventory") if "inventory" in player else null
	if not already_resting:
		if inv and inv.gold < 10:
			_msg_player(player, "❌ Necesitas 10 Oro para ingresar en la Cama de Urgencias", Color.ORANGE_RED, -42.0)
			return
		if inv:
			inv.add_gold(-10)
			pay_into(role_npc(int(VillageNPC.TradeRole.DOCTOR)), 10) # Regla 1: cobra el médico (o las arcas)
	player.global_position = sitio(_hospital_bed_pos)
	if "velocity" in player:
		player.velocity = Vector2.ZERO
	if health:
		health.is_resting_in_bed = true
	var doc_npc: VillageNPC = null
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC:
			var vn := n as VillageNPC
			if vn.trade_role == VillageNPC.TradeRole.DOCTOR and not vn.is_dead and not vn.is_downed:
				doc_npc = vn
				break
	if is_instance_valid(doc_npc):
		doc_npc.is_sleeping = false
		doc_npc._active_hospital_patient = player
		_msg_player(player, "🏥🛏️ Ingresado en Cama de Urgencias: %s irá curando tus heridas una por una (no te muevas)" % doc_npc.npc_name, Color.SPRING_GREEN, -44.0)
	else:
		if health:
			var urg_id: int = health.get_most_urgent_untreated_wound_id(true)
			if urg_id >= 0:
				health.treat_wound(urg_id, "tend_makeshift")
		_msg_player(player, "🏥🛏️ Sin médico de guardia: te aplicaste un vendaje de urgencia; descansa en la camilla para recuperarte", Color.GOLD, -44.0)

func _use_tavern_games_table(start_tab: int = 0) -> void:
	if is_demo_mode():
		_hint_player("🃏 La mesa de juego está cerrada por ahora.")
		return
	var games_ui = get_tree().root.find_child("TavernGamesUI", true, false)
	if games_ui and games_ui.has_method("open_games"):
		games_ui.call("open_games", start_tab)

func _use_tavern_bed(player: Node2D) -> void:
	var inv: SimpleInventory = player.get("inventory")
	if not inv or inv.gold < 8:
		_hint_player("🛌 Necesitas 8 Oro para alquilar la cama de la Taberna.", player)
		return
	inv.add_gold(-8)
	pay_into(_innkeeper_npc, 8) # Regla 1: cobra la posadera (o las arcas)
	var surv: SurvivalComponent = player.get_node_or_null("SurvivalComponent")
	var stam: StaminaComponent = player.get_node_or_null("StaminaComponent")
	var health: HealthComponent = player.get_node_or_null("HealthComponent")
	if surv:
		surv.restore_sleep(100.0)
	if stam:
		stam.current_stamina = stam.max_stamina
		stam.stamina_changed.emit(stam.current_stamina, stam.max_stamina)
	if health:
		health.heal(35.0)
	if WorldClock:
		WorldClock.sleep_until_morning()
	_msg_player(player, "🛌 Dormiste en la Posada (-8 Oro, +100% Sueño)", Color.GOLD, -42.0)

func _use_water_well(player: Node2D) -> void:
	VillageNeeds.player_wash(self) # E1: también te lavas
	if player.has_method("refill_watering_can"):
		player.call("refill_watering_can")
	else:
		_msg_player(player, "💧 Agua fresca del pozo", Color.AQUA, -40.0)

func _use_compost_bin(player: Node2D) -> void:
	var inv: SimpleInventory = player.get("inventory")
	if not inv:
		return
	for org_id in ["mushroom", "herbs", "carrot", "cabbage"]:
		if inv.remove_item(org_id, 1):
			inv.add_item("fertilizer", 2)
			_msg_player(player, "♻️ Compostador: +2 Abono Orgánico", Color.SPRING_GREEN, -42.0)
			return
	_hint_player("♻️ Necesitas 1 Hongo, Hierba o Verdura para fermentar 2 bolsas de Abono Orgánico.", player)

# ==============================================================================
# B2.2: QUEDADAS FÍSICAS (Pasar tiempo juntos) — el SocialDirector decide, aquí se ejecuta en el mundo
# ==============================================================================
@warning_ignore("unused_private_class_variable") # Se usa desde otro script (vm._hangout_plan_timer)

## `stall_original`: sitio del mostrador en el mapa ORIGINAL (su marca). La zona de uso y el letrero lo siguen a donde
## esté de verdad; en la ficha del negocio se guarda ya en el mundo actual.
func _register_shop_business_stall(role_id: int, shop_title: String, fam_id: String, stall_original: Vector2, stall_spr: Sprite2D) -> void:
	_add_station_area("ShopBusinessStall_%d" % role_id, stall_original, 18.0, "shop_business_stall")
	var stall_pos: Vector2 = Anclas.mover(stall_original)
	var lbl := _make_station_label(stall_original, "📜 %s [E: Gestionar Negocio | F: Sabotear]" % shop_title)
	lbl.position = stall_pos + SHOP_LABEL_OFFSET # el letrero es más ancho que el edificio: se coloca respecto al mostrador
	lbl.custom_minimum_size = Vector2(260, 26)
	entities_root.add_child(lbl)

	var sup_items: Array[String] = []
	match role_id:
		int(VillageNPC.TradeRole.BLACKSMITH): sup_items = ["iron_ore", "stone", "steel_ingot", "repair_kit", "bandit_scrap"]
		int(VillageNPC.TradeRole.BUTCHER): sup_items = ["cooked_meat", "raw_meat", "roasted_chicken", "raw_chicken", "leather", "fox_pelt", "antlers"]
		int(VillageNPC.TradeRole.CARPENTER): sup_items = ["wood", "repair_kit", "copper_coil"]
		int(VillageNPC.TradeRole.FISHMONGER): sup_items = ["bread", "cooked_fish", "river_trout", "golden_carp", "night_catfish", "wheat", "fertilizer"]
		int(VillageNPC.TradeRole.HERBALIST): sup_items = ["herbal_poultice", "herbs", "mushroom", "carrot", "cabbage", "sleeping_draught", "surgical_kit"]
		int(VillageNPC.TradeRole.BAKER): sup_items = ["bread", "wheat"]
		int(VillageNPC.TradeRole.TAILOR): sup_items = ["clothes", "leather", "fox_pelt"]
		int(VillageNPC.TradeRole.LODGEKEEPER): sup_items = ["country_stew", "cooked_meat"]
		int(VillageNPC.TradeRole.RESTAURATEUR): sup_items = ["pasta_dish", "braised_meat"]
		_: sup_items = VillageTrades.supply_items_for(role_id) # V5d

	var cfg: Dictionary = trade_configs.get(role_id, {})
	var init_stock: Dictionary = (cfg.get("stock", {}) as Dictionary).duplicate()
	shop_businesses[role_id] = {
		"role": role_id, "family_id": fam_id, "title": shop_title, "stall_pos": stall_pos, "stall_sprite": stall_spr,
		"stall_label": lbl, "owner_mode": "NPC", "vault_gold": 0, "sabotaged_days": 0, "sabotaged_today_day": -1,
		"supply_items": sup_items, "stock_override": init_stock
	}

func _find_nearest_business_stall(pos: Vector2, max_rad: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d2: float = max_rad * max_rad
	for r_id in shop_businesses.keys():
		var biz: Dictionary = shop_businesses[r_id]
		var s_pos: Vector2 = biz.get("stall_pos", Vector2.ZERO)
		var d2: float = pos.distance_squared_to(s_pos)
		if d2 <= best_d2:
			best_d2 = d2
			best = biz
	return best

func _update_shop_business_stalls(_player: Node2D, _mouse_pos: Vector2) -> void:
	for r_id in shop_businesses.keys():
		var role_int: int = int(r_id)
		_sync_shop_sabotage_fx_2d(role_int)
		var biz: Dictionary = shop_businesses[role_int]
		var lbl: Label = biz.get("stall_label")
		if is_instance_valid(lbl):
			lbl.visible = false

func _refresh_shop_stall_visual(role_id: int) -> void:
	if not shop_businesses.has(role_id):
		return
	var biz: Dictionary = shop_businesses[role_id]
	var spr: Sprite2D = biz.get("stall_sprite")
	var sab_d: int = int(biz.get("sabotaged_days", 0))
	var owner_m: String = str(biz.get("owner_mode", "NPC"))
	if is_instance_valid(spr):
		if sab_d > 0:
			spr.modulate = Color(0.62, 0.36, 0.34, 0.96)
		elif owner_m != "NPC":
			spr.modulate = Color(1.06, 1.04, 0.88, 1.0)
		else:
			spr.modulate = Color.WHITE
	_sync_shop_sabotage_fx_2d(role_id)

## B4.2: Taller saboteado echa humo y chispas en 2D hasta que se repara; si hay fuego fuera, la lluvia ayuda a apagarlo.

func _sync_shop_sabotage_fx_2d(role_id: int) -> void:
	if not shop_businesses.has(role_id):
		return
	var biz: Dictionary = shop_businesses[role_id]
	var sab_d: int = int(biz.get("sabotaged_days", 0))
	var existing: Node2D = biz.get("sabotage_fx_2d") as Node2D if is_instance_valid(biz.get("sabotage_fx_2d")) else null
	if sab_d <= 0:
		biz["outdoor_fire"] = false
		biz["fire_intensity"] = 0.0
		biz["rain_helped_day"] = -1
		if existing != null:
			existing.queue_free()
		biz.erase("sabotage_fx_2d")
		return
	var raining: bool = WorldClock != null and int(WorldClock.current_weather) == 1
	if not biz.has("outdoor_fire"):
		biz["outdoor_fire"] = not raining
		biz["fire_intensity"] = 0.25 if raining else 1.0
	if raining and (biz.get("outdoor_fire") == true or float(biz.get("fire_intensity", 0.0)) > 0.25):
		biz["outdoor_fire"] = false
		biz["fire_intensity"] = 0.20
		var cur_d: int = int(WorldClock.current_day) if WorldClock else 1
		if sab_d > 1 and int(biz.get("rain_helped_day", -1)) != cur_d:
			biz["rain_helped_day"] = cur_d
			biz["sabotaged_days"] = maxi(1, sab_d - 1)
	if existing == null:
		existing = Node2D.new()
		existing.name = "SabotageFX2D_%d" % role_id
		existing.position = (biz.get("stall_pos", Vector2.ZERO) as Vector2) + Vector2(0.0, -10.0)
		existing.z_index = 28
		var smoke := CPUParticles2D.new()
		smoke.name = "Smoke2D"
		smoke.amount = 14
		smoke.lifetime = 1.35
		smoke.direction = Vector2(0.15, -1.0)
		smoke.spread = 28.0
		smoke.initial_velocity_min = 10.0
		smoke.initial_velocity_max = 22.0
		smoke.gravity = Vector2(4.0, -12.0)
		smoke.scale_amount_min = 2.2
		smoke.scale_amount_max = 4.2
		smoke.color = Color(0.24, 0.24, 0.26, 0.72)
		smoke.emitting = true
		existing.add_child(smoke)
		var sparks := CPUParticles2D.new()
		sparks.name = "Sparks2D"
		sparks.amount = 10
		sparks.lifetime = 0.45
		sparks.explosiveness = 0.35
		sparks.direction = Vector2(0.0, -1.0)
		sparks.spread = 65.0
		sparks.initial_velocity_min = 24.0
		sparks.initial_velocity_max = 52.0
		sparks.gravity = Vector2(0.0, 95.0)
		sparks.scale_amount_min = 1.2
		sparks.scale_amount_max = 2.2
		sparks.color = Color(1.0, 0.78, 0.25, 0.95)
		sparks.emitting = true
		existing.add_child(sparks)
		var fire := CPUParticles2D.new()
		fire.name = "Fire2D"
		fire.amount = 12
		fire.lifetime = 0.55
		fire.direction = Vector2(0.0, -1.0)
		fire.spread = 32.0
		fire.initial_velocity_min = 8.0
		fire.initial_velocity_max = 18.0
		fire.gravity = Vector2(0.0, -24.0)
		fire.scale_amount_min = 2.0
		fire.scale_amount_max = 3.6
		fire.color = Color(1.0, 0.42, 0.12, 0.88)
		fire.emitting = biz.get("outdoor_fire") == true
		existing.add_child(fire)
		add_child(existing)
		biz["sabotage_fx_2d"] = existing
	else:
		existing.position = (biz.get("stall_pos", Vector2.ZERO) as Vector2) + Vector2(0.0, -10.0)
		var fire_node := existing.get_node_or_null("Fire2D") as CPUParticles2D
		if fire_node != null:
			fire_node.emitting = biz.get("outdoor_fire") == true

func extinguish_outdoor_fires_from_rain() -> int:
	var count: int = 0
	for r_id in shop_businesses.keys():
		var role_int: int = int(r_id)
		var biz: Dictionary = shop_businesses[role_int]
		if int(biz.get("sabotaged_days", 0)) > 0 and (biz.get("outdoor_fire") == true or float(biz.get("fire_intensity", 0.0)) > 0.25):
			count += 1
		_sync_shop_sabotage_fx_2d(role_int)
	return count

## Obtiene el diccionario de stock activo del negocio (del NPC titular si vive, o de `stock_override` si está vacante)

func add_home_pantry_ration(npc: VillageNPC, amount: int = 1) -> void:
	if npc == null:
		return
	var p_key: String = npc.family_id if (npc.family_id != "none" and npc.family_id != "") else npc.npc_name
	house_pantry[p_key] = clampi(int(house_pantry.get(p_key, 0)) + amount, 0, 8)

## Consumo Real de Alimentos por los Habitantes (`ActivityState.EATING`):
## 1º PRIORIDAD: Cocinar y comer en CASA de su propia despensa doméstica (`house_pantry`, coste 0 Oro extra).
## 2º PRIORIDAD: Comprar producto fresco/crudo barato (`3–5 Oro` × multiplicador de mercado) en Pescadería, Carnicería o Botica (pagando de `npc.personal_gold` a `holder.personal_gold`) para cocinarlo en casa y abastecer la despensa (`+1` ración extra).
## 3º PRIORIDAD (Lujo Opcional): Plato cocinado en la Posada (`12–15 Oro` × mercado), solo si la puerta no está bloqueada y el NPC puede permitírselo.

func consume_village_meal_for_npc(npc: VillageNPC) -> bool:
	if npc == null or npc.is_dead:
		return false

	var p_key: String = npc.family_id if (npc.family_id != "none" and npc.family_id != "") else npc.npc_name
	var near_tavern: bool = VillageTavern.RECT.grow(8.0).has_point(_AN_SITIOS.desmover(npc.global_position))

	# 1º PRIORIDAD: Si está en su casa/cuartel (no en la Taberna) y su despensa doméstica (`house_pantry`) tiene suministros, cocina en casa gratis
	var cur_pantry: int = int(house_pantry.get(p_key, 0))
	if not near_tavern and cur_pantry > 0:
		house_pantry[p_key] = cur_pantry - 1
		npc.add_thought("Cocinó y comió en casa de su despensa (+6)", 6.0)
		npc._spawn_floating_text("🍲🏠 Comida casera (Despensa: %d)" % int(house_pantry[p_key]), Color(0.65, 1.0, 0.72), -32.0)
		return true

	# 2º PRIORIDAD: Comprar producto crudo/fresco barato (3-5 Oro × mercado) en las tiendas de alimentación abiertas y llevar a la despensa
	var food_roles: Array[int] = [int(VillageNPC.TradeRole.BAKER), int(VillageNPC.TradeRole.FISHMONGER), int(VillageNPC.TradeRole.BUTCHER), int(VillageNPC.TradeRole.HERBALIST)]
	if npc.trade_role == VillageNPC.TradeRole.BUTCHER:
		food_roles = [int(VillageNPC.TradeRole.BUTCHER), int(VillageNPC.TradeRole.BAKER), int(VillageNPC.TradeRole.FISHMONGER), int(VillageNPC.TradeRole.HERBALIST)]
	if near_tavern:
		food_roles.clear()

	var edible_keys: Array[String] = ["bread", "cooked_meat", "cooked_fish", "roasted_chicken", "carrot", "cabbage", "herbal_poultice"]
	for r_id in food_roles:
		var holder: VillageNPC = trade_npcs.get(r_id)
		var cfg: Dictionary = trade_configs.get(r_id, {})
		var shop_fam_id: String = str(cfg.get("family_id", ""))
		var is_own_family_pantry: bool = (npc.family_id != "none" and npc.family_id == shop_fam_id)

		if not is_own_family_pantry:
			if is_trade_sabotaged(r_id) or not is_instance_valid(holder) or not holder.is_at_shop_counter():
				continue
		else:
			if not is_instance_valid(holder) or holder.is_dead:
				continue

		var mkt_m: float = get_trade_market_multiplier(r_id)
		var raw_price: int = 0 if is_own_family_pantry else maxi(3, int(round(4.0 * mkt_m)))
		if not is_own_family_pantry and npc.personal_gold < raw_price:
			continue

		var st: Dictionary = holder.shop_stock
		for f_key in edible_keys:
			var cur_q: int = int(st.get(f_key, 0))
			if cur_q > 0:
				st[f_key] = cur_q - 1
				if not is_own_family_pantry:
					npc.personal_gold = maxi(0, npc.personal_gold - raw_price)
					holder.personal_gold += raw_price
					# Si le alcanza para llevar otra unidad a su despensa casera, guarda +1 ración para no depender de tiendas cerradas
					if cur_q >= 2 and npc.personal_gold >= raw_price and int(house_pantry.get(p_key, 0)) < 3:
						st[f_key] = cur_q - 2
						npc.personal_gold = maxi(0, npc.personal_gold - raw_price)
						holder.personal_gold += raw_price
						house_pantry[p_key] = int(house_pantry.get(p_key, 0)) + 1
				if shop_businesses.has(r_id):
					shop_businesses[r_id]["stock_override"] = st.duplicate()
				var food_name: String = str(SimpleInventory.CATALOG.get(f_key, {}).get("name", f_key))
				npc.add_thought("Cocinó %s comprado en el mercado (-%d Oro, +6)" % [food_name, raw_price], 6.0)
				npc._spawn_floating_text("🥖🏠 %s (-%d Oro | Bolsillo: %d)" % [food_name, raw_price, npc.personal_gold], Color(0.75, 1.0, 0.75), -32.0)
				# Si el jugador es Socio o Dueño de este negocio, la venta al aldeano ingresa oro real en su Caja Registradora
				if shop_businesses.has(r_id) and not is_own_family_pantry:
					var biz: Dictionary = shop_businesses[r_id]
					var om: String = str(biz.get("owner_mode", "NPC"))
					if om in ["PARTNER", "SOLE_OWNER"]:
						var eff_m: float = holder.get_job_efficiency()
						var base_val: int = 10 if om == "SOLE_OWNER" else 6
						var sale_gold: int = maxi(3, int(round(float(base_val) * mkt_m * eff_m)))
						# Regla 1: tu parte sale de lo que el vecino acaba de pagar al artesano, no del aire.
						sale_gold = mini(sale_gold, maxi(0, holder.personal_gold))
						holder.personal_gold -= sale_gold
						biz["vault_gold"] = int(biz.get("vault_gold", 0)) + sale_gold
				_refresh_shop_stall_visual(r_id)
				return true

	# 3º PRIORIDAD (Lujo Opcional): Plato cocinado en la Posada (12-15 Oro × mercado) SOLO si la puerta de la Taberna no está bloqueada y la Tabernera sirve en barra
	if not is_building_door_blocked("building_tavern"):
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC:
				var inn: VillageNPC = n as VillageNPC
				if inn.trade_role == VillageNPC.TradeRole.INNKEEPER and not inn.is_dead:
					var is_innkeeper_self: bool = (npc == inn)
					if not is_innkeeper_self and not inn.is_at_shop_counter():
						continue
					var tav_mult: float = get_trade_market_multiplier(int(VillageNPC.TradeRole.INNKEEPER))
					var tav_price: int = 0 if is_innkeeper_self else maxi(10, int(round(13.0 * tav_mult)))
					if not is_innkeeper_self and npc.personal_gold < tav_price:
						continue
					for t_key in ["country_stew", "bread", "roasted_chicken"]:
						var tq: int = int(inn.shop_stock.get(t_key, 0))
						if tq > 0:
							inn.shop_stock[t_key] = tq - 1
							if not is_innkeeper_self:
								npc.personal_gold = maxi(0, npc.personal_gold - tav_price)
								inn.personal_gold += tav_price
							npc.add_thought("Pagó comida caliente en la Posada (-%d Oro, +5)" % tav_price, 5.0)
							npc._spawn_floating_text("🍲🍺 Plato de Posada (-%d Oro)" % tav_price, Color.GOLD, -32.0)
							return true

	# Respaldo: Si estaba en la Taberna pero estaba cerrada o era muy cara, revisar si aún le quedaba algo en su despensa casera
	if int(house_pantry.get(p_key, 0)) > 0:
		house_pantry[p_key] = int(house_pantry.get(p_key, 0)) - 1
		npc.add_thought("Comió de su despensa casera (+5)", 5.0)
		return true

	# J4: último recurso, las gachas del albergue
	if VillageCivic.take_shelter_ration(self, npc):
		return true

	# ¡Escasez o falta de dinero! El NPC no pudo comprar comida y recurrirá a cazar/recolectar torpemente en el bosque
	village_food_shortage_days += 1
	VillageMigration.note_meal_failure(self, npc)
	npc.add_thought("¡Sin comida o sin oro para pagar precios de crisis! (-12)", -12.0)
	npc._spawn_floating_text("🍽️💸 ¡Sin comida accesible (Irá a buscar/cazar al bosque)!", Color.ORANGE_RED, -34.0)
	return false

## Procesa las ventas diarias y dividendos de un negocio propiedad del jugador al cambiar de día (escalados por la eficiencia laboral `get_job_efficiency()`)

func _process_daily_business_sales_and_dividends(role_id: int, holder: VillageNPC, sab_days: int) -> int:
	if not shop_businesses.has(role_id):
		return 0
	var biz: Dictionary = shop_businesses[role_id]
	var owner_mode: String = str(biz.get("owner_mode", "NPC"))
	if not (owner_mode in ["PARTNER", "SOLE_OWNER"]):
		return 0

	var has_active_worker: bool = is_instance_valid(holder) and not holder.is_dead and not holder.is_downed
	# Si no hay ningún trabajador vivo atendiendo el local, NO se puede vender nada en la tienda
	if not has_active_worker or sab_days > 0:
		return 0

	var eff: float = holder.get_job_efficiency()
	# Regla 1: ya no hay «ganancia base» del aire; la caja solo crece con ventas que paga un vecino de su bolsillo.
	var earned_today: int = 0

	# 2. Ventas automáticas a los vecinos de los productos en el mostrador (limitadas por la eficiencia del trabajador)
	var st: Dictionary = get_trade_stock_dict(role_id)
	var mkt_mult: float = get_trade_market_multiplier(role_id)
	var max_sales: int = 1 if eff < 0.60 else (2 if eff < 0.85 else 3)
	var items_sold: int = 0
	for item_k in st.keys():
		if items_sold >= max_sales:
			break
		var avail: int = int(st.get(item_k, 0))
		if avail > 0:
			var sell_cnt: int = mini(avail, 2 if (items_sold == 0 and eff >= 0.85) else 1)
			var unit_val: int = 12 if owner_mode == "SOLE_OWNER" else 8
			var unit_price: int = maxi(1, int(round(float(unit_val) * mkt_mult * eff)))
			var sold_now: int = 0
			for _u in range(sell_cnt):
				var buyer: VillageNPC = _find_paying_customer(unit_price, holder)
				if buyer == null:
					break
				buyer.personal_gold -= unit_price
				earned_today += unit_price
				sold_now += 1
			if sold_now <= 0:
				break
			st[item_k] = avail - sold_now
			items_sold += sold_now

	if earned_today > 0:
		biz["vault_gold"] = int(biz.get("vault_gold", 0)) + earned_today
	return earned_today

## Tecla [F] o Botón [4]: Sabotear Taller Industrial (estropea maquinaria 2 días, reduce stock, da botín y hunde el precio de compra del local)

func sabotage_shop_stall(player: Node2D, role_id: int) -> void:
	if not player or not shop_businesses.has(role_id):
		return
	var biz: Dictionary = shop_businesses[role_id]
	var b_title: String = str(biz.get("title", "Taller"))
	var cur_day: int = WorldClock.current_day if WorldClock else 1

	if int(biz.get("sabotaged_days", 0)) > 0 or int(biz.get("sabotaged_today_day", -1)) == cur_day:
		_msg_player(player, "🔧💥 Este taller ya fue saboteado hoy", Color.GOLD, -42.0)
		return

	biz["sabotaged_days"] = 2
	biz["sabotaged_today_day"] = cur_day
	recent_breakins_count += 1
	_refresh_shop_stall_visual(role_id)

	var st: Dictionary = get_trade_stock_dict(role_id)
	for k in st.keys():
		st[k] = int(floor(float(st[k]) * 0.4))

	var inv: SimpleInventory = player.get("inventory")
	var sup_list: Array = biz.get("supply_items", ["wood"])
	var loot_id: String = str(sup_list[0]) if not sup_list.is_empty() else "wood"
	if inv:
		inv.add_item(loot_id, 1)
	var loot_name: String = str(SimpleInventory.CATALOG.get(loot_id, {}).get("name", loot_id))

	var in_stealth: bool = player.has_method("is_stealthing") and bool(player.call("is_stealthing"))
	var cloak_mult: float = float(player.call("get_stealth_detection_multiplier")) if player.has_method("get_stealth_detection_multiplier") else 1.0
	var detect_rad: float = (48.0 if in_stealth else 145.0) * cloak_mult
	var witness: VillageNPC = _find_conscious_witness_near(biz.get("stall_pos", player.global_position), detect_rad, null)

	if witness == null:
		_msg_player(player, "💣🤫 ¡Sabotaje industrial en sigilo! %s averiado (+1 %s | Precios a 2.25x)" % [b_title, loot_name], Color.SPRING_GREEN, -46.0)
		_hint_player("💣 Has saboteado %s sin testigos: su producción se detiene 2 días, sus precios suben al 225%% y puedes comprar su escritura en liquidación (65 Oro)." % b_title, player)
	else:
		wanted_level = clampi(wanted_level + 1, 1, 5)
		bounty_gold += 35
		var fam_id: String = str(biz.get("family_id", "none"))
		modify_family_reputation(fam_id, -40, "Sabotaje del taller visto por " + witness.npc_name)
		var msg := "🚨👁️ ¡%s te vio sabotear %s! (+35 Oro de multa policial)" % [witness.npc_name, b_title]
		crime_history.push_front(msg)
		_notify_inquisitor_of_police_crime(msg, 22)
		_msg_player(player, msg, Color.ORANGE_RED, -46.0)

	if business_panel and business_panel.visible and _active_business_role == role_id:
		open_business_management_ui(role_id)

## Abre el Modal de Gestión del Negocio, Oferta/Demanda, Caja Registradora y Compra Híbrida de Escritura

func open_business_management_ui(role_id: int) -> void:
	if not business_panel or not shop_businesses.has(role_id):
		return
	_active_business_role = role_id
	var biz: Dictionary = shop_businesses[role_id]
	var b_title: String = str(biz.get("title", "Negocio"))
	var fam_id: String = str(biz.get("family_id", "none"))
	var owner_mode: String = str(biz.get("owner_mode", "NPC"))
	var vault_gold: int = int(biz.get("vault_gold", 0))
	var sab_days: int = int(biz.get("sabotaged_days", 0))

	var holder: VillageNPC = trade_npcs.get(role_id)
	var holder_alive: bool = is_instance_valid(holder) and not holder.is_dead
	var holder_str: String = "%s (%s · ⚒️%s)" % [holder.npc_name, holder.npc_role, holder.get_job_efficiency_label()] if holder_alive else "❌ VACANTE (Sin artesano activo — Tienda cerrada)"
	var fam_aff: int = holder.affinity if holder_alive else _get_building_family_affinity("shop_" + fam_id)

	var st: Dictionary = get_trade_stock_dict(role_id)
	var stock_parts: Array[String] = []
	for k in st.keys():
		var k_name: String = str(SimpleInventory.CATALOG.get(str(k), {}).get("name", str(k)))
		stock_parts.append("%s: %d" % [k_name, int(st[k])])
	var stock_str: String = ", ".join(stock_parts) if not stock_parts.is_empty() else "Vacío (0 unidades)"

	var mkt_txt: String = get_trade_market_status_text(role_id)
	var sab_str: String = "🔧💥 SABOTEADO (%d días sin producir)" % sab_days if sab_days > 0 else "🟢 Operativo"
	var prop_str: String = "🏢 Propiedad Familiar Original"
	if owner_mode == "PARTNER":
		prop_str = "🤝 Eres Socio Capitalista (Recibes dividendos diarios + -30% Dto)"
	elif owner_mode == "SOLE_OWNER":
		prop_str = "👑 Eres el Dueño Único (100% de las ventas van a tu Caja Registradora)"

	business_info_lbl.text = "📜 %s\n👤 Artesano al frente: %s | 🛠️ Estado Taller: %s\n📊 Mercado Actual: %s | 📦 Stock Mostrador: %s\n🏛️ Propiedad: %s | 💰 Caja Registradora: %d Oro" % [
		b_title, holder_str, sab_str, mkt_txt, stock_str, prop_str, vault_gold
	]

	var tot_stk: int = get_trade_total_stock(role_id)
	var in_distress: bool = (not holder_alive) or (sab_days > 0) or (tot_stk <= 0)

	# Configurar Botón [1]: Comprar Escritura (Socio o Liquidación) O Recaudar Caja Registradora
	if owner_mode == "NPC":
		if in_distress:
			_biz_btn_1.text = "[1] 📜🔥 Comprar Escritura Completa en Liquidación (-65 Oro -> Dueño Único)"
		else:
			var partner_cost: int = 85 if fam_aff >= 45 else 110
			_biz_btn_1.text = "[1] 🤝 Comprar Acciones / Escritura de Socio (-%d Oro -> Dividendos Diarios + -30%% Dto)" % partner_cost
	elif owner_mode == "PARTNER" and vault_gold <= 0:
		_biz_btn_1.text = "[1] 👑 Adquirir el 100% de la Escritura (-55 Oro -> Pasar a Dueño Único)"
	else:
		_biz_btn_1.text = "[1] 💰 Recaudar Beneficios de la Caja Registradora (+%d Oro)" % vault_gold

	# Configurar Botón [2]: Abastecer el Mostrador con recursos de tu Mochila
	var sup_items: Array = biz.get("supply_items", [])
	var sup_names: Array[String] = []
	for i in range(mini(3, sup_items.size())):
		var s_id: String = str(sup_items[i])
		sup_names.append(str(SimpleInventory.CATALOG.get(s_id, {}).get("name", s_id)))
	_biz_btn_2.text = "[2] 📦 Abastecer Mostrador con tu Mochila (%s... -> Venta Automática)" % ", ".join(sup_names)

	# Configurar Botón [3]: Contratar / Asignar Encargado si está vacante o cobrar suministro
	if not holder_alive:
		_biz_btn_3.text = "[3] 🤝 Contratar Nuevo Encargado en la Posada (-30 Oro -> Reanuda Producción)"
	else:
		_biz_btn_3.text = "[3] 💬 Hablar / Comerciar Directamente con %s" % holder.npc_name

	# Configurar Botón [4]: Sabotear Taller o Reparar Taller Saboteado
	if sab_days > 0:
		_biz_btn_4.text = "[4] 🔧 Reparar Maquinaria Saboteada (-1 Madera o -12 Oro -> Reanuda Producción)"
	else:
		_biz_btn_4.text = "[4] 💣 Sabotear Taller [F] (Averiar 2 días, saquear material y subir precios a 2.25x)"

	business_panel.visible = true

func _on_business_action_1(player: Node2D) -> void:
	if not player or not ("inventory" in player) or not player.inventory or not shop_businesses.has(_active_business_role):
		return
	var inv: SimpleInventory = player.inventory
	var biz: Dictionary = shop_businesses[_active_business_role]
	var b_title: String = str(biz.get("title", "Negocio"))
	var fam_id: String = str(biz.get("family_id", "none"))
	var owner_mode: String = str(biz.get("owner_mode", "NPC"))
	var vault_gold: int = int(biz.get("vault_gold", 0))
	var sab_days: int = int(biz.get("sabotaged_days", 0))
	var holder: VillageNPC = trade_npcs.get(_active_business_role)
	var holder_alive: bool = is_instance_valid(holder) and not holder.is_dead
	var fam_aff: int = holder.affinity if holder_alive else _get_building_family_affinity("shop_" + fam_id)
	var tot_stk: int = get_trade_total_stock(_active_business_role)
	var in_distress: bool = (not holder_alive) or (sab_days > 0) or (tot_stk <= 0)

	if owner_mode == "NPC":
		if in_distress:
			var buyout_cost: int = 65
			if inv.gold < buyout_cost:
				player._spawn_floating_text("❌ Necesitas %d Oro para comprar la escritura en liquidación" % buyout_cost, Color.ORANGE_RED, -42.0)
				return
			inv.add_gold(-buyout_cost)
			pay_into(holder if holder_alive else null, buyout_cost) # Regla 1: al titular, o a las arcas si no hay
			biz["owner_mode"] = "SOLE_OWNER"
			_refresh_shop_stall_visual(_active_business_role)
			player._spawn_floating_text("👑📜 ¡Adquiriste el 100%% de %s en liquidación! (-%d Oro)" % [b_title, buyout_cost], Color.GOLD, -46.0)
		else:
			var partner_cost: int = 85 if fam_aff >= 45 else 110
			if inv.gold < partner_cost:
				player._spawn_floating_text("❌ Necesitas %d Oro para comprar acciones de Socio" % partner_cost, Color.ORANGE_RED, -42.0)
				return
			inv.add_gold(-partner_cost)
			pay_into(holder if holder_alive else null, partner_cost) # Regla 1: compras su parte al titular
			biz["owner_mode"] = "PARTNER"
			modify_family_reputation(fam_id, 20, "Socio capitalista del negocio familiar")
			_refresh_shop_stall_visual(_active_business_role)
			player._spawn_floating_text("🤝📜 ¡Ahora eres Socio de %s! (-%d Oro | Dividendos diarios + -30%% Dto)" % [b_title, partner_cost], Color.SPRING_GREEN, -46.0)
	elif owner_mode == "PARTNER" and vault_gold <= 0:
		var up_cost: int = 55
		if inv.gold < up_cost:
			player._spawn_floating_text("❌ Necesitas %d Oro para adquirir el 100%% de la propiedad" % up_cost, Color.ORANGE_RED, -42.0)
			return
		inv.add_gold(-up_cost)
		var holder_up: VillageNPC = trade_npcs.get(_active_business_role)
		pay_into(holder_up if is_instance_valid(holder_up) and not holder_up.is_dead else null, up_cost) # Regla 1
		biz["owner_mode"] = "SOLE_OWNER"
		_refresh_shop_stall_visual(_active_business_role)
		player._spawn_floating_text("👑📜 ¡Ahora eres Dueño Único de %s! (-%d Oro)" % [b_title, up_cost], Color.GOLD, -46.0)
	else:
		if vault_gold <= 0:
			player._spawn_floating_text("💰 La Caja Registradora está vacía por ahora (0 Oro)", Color.LIGHT_GRAY, -42.0)
			return
		inv.add_gold(vault_gold)
		biz["vault_gold"] = 0
		player._spawn_floating_text("💰✨ ¡Recaudaste +%d Oro de la Caja Registradora de %s!" % [vault_gold, b_title], Color.GOLD, -46.0)

	open_business_management_ui(_active_business_role)

func _on_business_action_2(player: Node2D) -> void:
	if not player or not ("inventory" in player) or not player.inventory or not shop_businesses.has(_active_business_role):
		return
	var inv: SimpleInventory = player.inventory
	var biz: Dictionary = shop_businesses[_active_business_role]
	var owner_mode: String = str(biz.get("owner_mode", "NPC"))
	var sup_items: Array = biz.get("supply_items", [])
	var st: Dictionary = get_trade_stock_dict(_active_business_role)
	var mkt_mult: float = get_trade_market_multiplier(_active_business_role)

	for raw_id in sup_items:
		var item_id: String = str(raw_id)
		if inv.has_item(item_id, 1):
			# Regla 1: en un negocio ajeno te paga el titular de su bolsillo; si no tiene, no te compra.
			if not (owner_mode in ["PARTNER", "SOLE_OWNER"]):
				var holder_pay: VillageNPC = trade_npcs.get(_active_business_role)
				var want_pay: int = maxi(6, int(round(9.0 * mkt_mult)))
				if not is_instance_valid(holder_pay) or holder_pay.is_dead or holder_pay.personal_gold < want_pay:
					player._spawn_floating_text("📦❌ El dueño no tiene %d Oro para pagarte la mercancía ahora" % want_pay, Color.ORANGE_RED, -44.0)
					return
			inv.remove_item(item_id, 1)
			st[item_id] = int(st.get(item_id, 0)) + 1
			var holder_sup: VillageNPC = trade_npcs.get(_active_business_role)
			if is_instance_valid(holder_sup) and item_id in ["wood", "iron_ore", "leather", "herbal_poultice", "bread", "fertilizer", "cooked_meat"]:
				holder_sup.workshop_materials[item_id] = int(holder_sup.workshop_materials.get(item_id, 0)) + 1
			var i_name: String = str(SimpleInventory.CATALOG.get(item_id, {}).get("name", item_id))
			if owner_mode in ["PARTNER", "SOLE_OWNER"]:
				# Como dueño/socio, reabasteces el stock físico de tu propio mostrador para que se venda a los vecinos y genere caja real
				_refresh_shop_stall_visual(_active_business_role)
				player._spawn_floating_text("📦✨ Abasteciste +1 %s en el mostrador de tu negocio (Stock actualizado)" % i_name, Color.SPRING_GREEN, -46.0)
			else:
				# Si abasteces un negocio ajeno en escasez, te pagan al contado al precio dinámico de mercado
				var instant_pay: int = maxi(6, int(round(9.0 * mkt_mult)))
				var holder_paying: VillageNPC = trade_npcs.get(_active_business_role)
				holder_paying.personal_gold -= instant_pay
				inv.add_gold(instant_pay)
				_refresh_shop_stall_visual(_active_business_role)
				var fam_id: String = str(biz.get("family_id", "none"))
				modify_family_reputation(fam_id, 6, "Suministró mercancía al mostrador")
				player._spawn_floating_text("📦🤝 Suministraste 1 %s al mostrador (+%d Oro al contado)" % [i_name, instant_pay], Color.GOLD, -44.0)
			open_business_management_ui(_active_business_role)
			return

	player._spawn_floating_text("❌ No llevas en tu mochila ningún producto compatible con este negocio", Color.ORANGE_RED, -42.0)

func _on_business_action_3(player: Node2D) -> void:
	if not player or not ("inventory" in player) or not player.inventory or not shop_businesses.has(_active_business_role):
		return
	var biz: Dictionary = shop_businesses[_active_business_role]
	var cfg: Dictionary = trade_configs.get(_active_business_role, {})
	var holder: VillageNPC = trade_npcs.get(_active_business_role)
	var holder_alive: bool = is_instance_valid(holder) and not holder.is_dead

	if holder_alive:
		business_panel.visible = false
		if holder.is_at_shop_counter() and player.global_position.distance_to(holder.global_position) <= 85.0:
			holder._start_npc_dialogue(player)
		elif player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("⏳ %s no está atendiendo el mostrador en este momento" % holder.npc_name, Color.GOLD, -42.0)
		return

	var inv: SimpleInventory = player.inventory
	if inv.gold < 30:
		player._spawn_floating_text("❌ Necesitas 30 Oro para contratar a un nuevo encargado", Color.ORANGE_RED, -42.0)
		return

	var candidate: VillageNPC = _pop_living_unemployed()
	if candidate == null:
		candidate = family_npcs.get(_active_business_role)
		if not is_instance_valid(candidate) or candidate.is_dead:
			candidate = null

	if candidate == null and arrivals_today_count >= MAX_DAILY_ARRIVALS:
		player._spawn_floating_text("⏳ Límite diario alcanzado (%d/%d llegadas hoy). Espera a mañana para que llegue otro artesano al valle" % [arrivals_today_count, MAX_DAILY_ARRIVALS], Color.GOLD, -44.0)
		return

	inv.add_gold(-30)
	pay_into(candidate, 30) # Regla 1: la prima de contratación es para el encargado (o las arcas si llega uno nuevo)

	if candidate != null:
		candidate.promote_to_trade(_active_business_role as VillageNPC.TradeRole, str(cfg.get("title", "Artesano")), cfg.get("work_pos", biz.get("stall_pos", Vector2.ZERO)), get_trade_stock_dict(_active_business_role), cfg.get("tex", null), cfg.get("bed1_pos", Vector2.ZERO), cfg.get("table_pos", Vector2.ZERO), str(cfg.get("family_id", "none")), str(cfg.get("family_name", "Gremio")))
		trade_npcs[_active_business_role] = candidate
		if family_npcs.get(_active_business_role) == candidate:
			family_npcs.erase(_active_business_role)
		_msg_player(player, "🤝⚒️ ¡Contrataste a %s (%s) como encargado de %s! (-30 Oro)" % [candidate.npc_name, candidate.get_job_efficiency_label(), str(biz.get("title", ""))], Color.SPRING_GREEN, -46.0)
	else:
		arrivals_today_count += 1
		var hired_npc: VillageNPC = _spawn_generated_newcomer(
			"NPC_Hired_Artisan_",
			_active_business_role as VillageNPC.TradeRole,
			_active_business_role as VillageNPC.TradeRole,
			str(cfg.get("title", "Encargado")) + " (Contratado)",
			cfg.get("tex", null),
			cfg.get("work_pos", biz.get("stall_pos", Vector2.ZERO)),
			cfg.get("bed1_pos", sitio(_tavern_bed_pos)),
			get_trade_stock_dict(_active_business_role),
			cfg.get("table_pos", sitio(_tavern_social_pos)),
			str(cfg.get("family_id", "none")),
			str(cfg.get("family_name", "Gremio")),
			true # trade_configs ya está traducido (plan de sitios)
		)
		trade_npcs[_active_business_role] = hired_npc
		_msg_player(player, "🤝🚶 ¡Contrataste a %s (Novato 35%%)! Ya viene caminando desde el borde del mapa (-30 Oro)" % hired_npc.npc_name, Color.SPRING_GREEN, -46.0)

	open_business_management_ui(_active_business_role)

func _on_business_action_4(player: Node2D) -> void:
	if not player or not ("inventory" in player) or not player.inventory or not shop_businesses.has(_active_business_role):
		return
	var biz: Dictionary = shop_businesses[_active_business_role]
	var sab_days: int = int(biz.get("sabotaged_days", 0))

	if sab_days > 0:
		var inv: SimpleInventory = player.inventory
		if inv.has_item("wood", 1):
			inv.remove_item("wood", 1)
		elif inv.gold >= 12:
			inv.add_gold(-12)
			pay_into(role_npc(int(VillageNPC.TradeRole.CARPENTER)), 12) # Regla 1: cobra el carpintero
		else:
			player._spawn_floating_text("❌ Requiere 1 Madera o 12 Oro para reparar la maquinaria del taller", Color.ORANGE_RED, -42.0)
			return
		biz["sabotaged_days"] = 0
		_refresh_shop_stall_visual(_active_business_role)
		var fam_id: String = str(biz.get("family_id", "none"))
		if int(biz.get("sabotaged_today_day", -1)) != (WorldClock.current_day if WorldClock else 1):
			modify_family_reputation(fam_id, 15, "Reparó el taller saboteado")
		player._spawn_floating_text("🔧✨ ¡Maquinaria de %s reparada y lista para producir!" % str(biz.get("title", "")), Color.SPRING_GREEN, -44.0)
		open_business_management_ui(_active_business_role)
	else:
		sabotage_shop_stall(player, _active_business_role)

# ==============================================================================
# FASE 9: ECONOMÍA CIRCULAR, CAMPAMENTOS RÚSTICOS DE VAGABUNDOS, 2 MERCADERES
# SEMANALES CON SALVOCONDUCTO REAL E INQUISIDOR REAL ALISTAIR (DEDUCCIÓN JUSTA)
# ==============================================================================

## 08:00 AM -> Salarios de Autoridades, Compras Recíprocas entre Gremios y Jornales de Viajeros

func _process_morning_salaries_and_inter_guild_circulation() -> void:
	# 1. Sueldo institucional diario para el Médico Forense y la Policía (14–18 Oro/día; si las arcas superan 250, aportan 8 de oro por agente)
	for auth in authority_npcs:
		if is_instance_valid(auth) and not auth.is_dead and not auth.is_downed:
			var salary: int = 18 if auth.trade_role == VillageNPC.TradeRole.SHERIFF else (16 if auth.trade_role == VillageNPC.TradeRole.DOCTOR else 14)
			# Regla 1: el sueldo entero sale de las arcas; si están vacías, cobran lo que haya.
			salary = take_from_treasury(salary)
			if salary <= 0:
				continue
			auth.personal_gold += salary
			auth._spawn_floating_text("💰+%d Oro (Salario)" % salary, Color.GOLD, -30.0)

	# 2. Demanda Cruzada entre Gremios: los comercios de comida y la Posada compran afilado/cuchillos/anzuelos
	# al Herrero (`Thoran`) y leña/barriles/reparaciones al Carpintero (`Bram`) para que el oro circule de vuelta.
	var smith_npc: VillageNPC = trade_npcs.get(int(VillageNPC.TradeRole.BLACKSMITH))
	var carp_npc: VillageNPC = trade_npcs.get(int(VillageNPC.TradeRole.CARPENTER))
	var food_sellers: Array[VillageNPC] = []
	for r_food in [int(VillageNPC.TradeRole.BUTCHER), int(VillageNPC.TradeRole.FISHMONGER), int(VillageNPC.TradeRole.HERBALIST), int(VillageNPC.TradeRole.BAKER)]:
		var fh: VillageNPC = trade_npcs.get(r_food)
		if is_instance_valid(fh) and not fh.is_dead and not fh.is_downed:
			food_sellers.append(fh)
	if is_instance_valid(_innkeeper_npc) and not _innkeeper_npc.is_dead and not _innkeeper_npc.is_downed:
		food_sellers.append(_innkeeper_npc)

	for seller in food_sellers:
		if seller.personal_gold >= 28:
			# Paga 7 Oro al Herrero por afilado de cuchillos/herramientas si vive
			if is_instance_valid(smith_npc) and not smith_npc.is_dead and not smith_npc.is_downed:
				seller.personal_gold -= 7
				smith_npc.personal_gold += 7
			# Paga 7 Oro al Carpintero por leña para el horno, cajas y barriles si vive
			if seller.personal_gold >= 20 and is_instance_valid(carp_npc) and not carp_npc.is_dead and not carp_npc.is_downed:
				seller.personal_gold -= 7
				carp_npc.personal_gold += 7

	# 3. Jornaleros y Viajeros sin Oficio (`UNEMPLOYED`): ganan un jornal modesto (8–12 Oro) acarreando leña/agua para talleres activos
	var active_shops_count: int = food_sellers.size()
	if is_instance_valid(smith_npc) and not smith_npc.is_dead:
		active_shops_count += 1
	if is_instance_valid(carp_npc) and not carp_npc.is_dead:
		active_shops_count += 1

	for guest in unemployed_npcs:
		if is_instance_valid(guest) and not guest.is_dead and not guest.is_downed:
			if active_shops_count > 0:
				var wage: int = clampi(4 + active_shops_count * 2, 6, 12)
				# Regla 1: el jornal lo paga un taller que tenga oro (el que más tenga); si nadie puede, no hay jornal.
				var employer: VillageNPC = null
				var employers: Array = []
				employers.append_array(food_sellers)
				employers.append(smith_npc)
				employers.append(carp_npc)
				for emp in employers:
					if is_instance_valid(emp) and not emp.is_dead and emp.personal_gold >= wage and (employer == null or emp.personal_gold > employer.personal_gold):
						employer = emp
				if employer == null:
					continue
				employer.personal_gold -= wage
				guest.personal_gold += wage
				guest._spawn_floating_text("🪓+%d Oro (Jornal)" % wage, Color(0.85, 0.95, 0.65), -30.0)

## 21:00 PM -> Cobro de 6 Oro/noche en la Posada o Desahucio a Campamentos Rústicos en las Afueras (`is_vagrant_camper`)

func _process_nightly_tavern_rent_and_vagrant_camps() -> void:
	var inn_alive: bool = is_instance_valid(_innkeeper_npc) and not _innkeeper_npc.is_dead
	var tav_blocked: bool = is_building_door_blocked("building_tavern")
	var rent_cost: int = 6

	for guest in unemployed_npcs:
		if not is_instance_valid(guest) or guest.is_dead or guest.trade_role != VillageNPC.TradeRole.UNEMPLOYED:
			continue
		if VillageMigration.nightly(self, guest): # V3: vive en una casa, no paga posada
			continue
		if VillageCivic.nightly_guest(self, guest, rent_cost): # V5b: El Candil, más barata
			continue
		# Si ya era vagabundo pero ha ahorrado >= 18 Oro y la Posada está abierta, recupera su cama bajo techo
		if guest.is_vagrant_camper and not tav_blocked and inn_alive and guest.personal_gold >= 18:
			guest.personal_gold -= rent_cost
			_innkeeper_npc.personal_gold += rent_cost
			guest.is_vagrant_camper = false
			guest.in_shelter = false
			guest.lodging = ""
			var guest_beds: Array[Vector2] = [Vector2(435, -252), Vector2(468, -252), Vector2(502, -252)]
			var free_b = VillageMigration.free_tavern_bed(self) # E3: cama libre, no la que toque por el nombre
			guest.bed_position = free_b if free_b != null else guest_beds[abs(guest.npc_name.hash()) % guest_beds.size()]
			if vagrant_camp_nodes.has(guest.npc_name) and is_instance_valid(vagrant_camp_nodes[guest.npc_name]):
				vagrant_camp_nodes[guest.npc_name].visible = false
			guest.add_thought("Volvió a pagar cama caliente en la Posada (+8)", 8.0)
			guest._spawn_floating_text("🛏️🏠 Pagó Posada (-6 Oro)", Color.SPRING_GREEN, -34.0)
			continue

		if not guest.is_vagrant_camper:
			if tav_blocked or guest.personal_gold < rent_cost:
				evict_npc_to_vagrant_camp(guest)
			elif inn_alive:
				guest.personal_gold -= rent_cost
				_innkeeper_npc.personal_gold += rent_cost
				guest._spawn_floating_text("🛏️-6 Oro (Alquiler Posada)", Color.GOLD, -30.0)

## Convierte a un NPC sin dinero o sin acceso a su cama en Vagabundo y levanta su Campamento Rústico físico en las afueras

func evict_npc_to_vagrant_camp(npc: VillageNPC, _reason: String = "") -> void:
	if npc == null or npc.is_dead:
		return
	if npc.in_shelter or VillageCivic.try_shelter(self, npc): # V5b: antes que a la intemperie, el Albergue del Alba
		return
	var camp_spots: Array[Vector2] = [Vector2(360, 345), Vector2(412, 355), Vector2(522, 348), Vector2(310, 348)]
	var c_pos: Vector2 = camp_spots[abs(npc.npc_name.hash()) % camp_spots.size()]
	npc.is_vagrant_camper = true
	npc.vagrant_camp_pos = c_pos
	npc.bed_position = c_pos
	_spawn_or_update_vagrant_camp_visual(npc, c_pos)
	npc.add_thought("Sin oro para la Posada: acampó a la intemperie (-10)", -10.0)
	npc._spawn_floating_text("⛺💸 ¡Sin dinero para la Posada! Monta campamento rústico en las afueras", Color.ORANGE, -38.0)

func _spawn_or_update_vagrant_camp_visual(npc: VillageNPC, camp_pos: Vector2) -> void:
	if not is_instance_valid(entities_root):
		return
	if vagrant_camp_nodes.has(npc.npc_name) and is_instance_valid(vagrant_camp_nodes[npc.npc_name]):
		var existing: Node2D = vagrant_camp_nodes[npc.npc_name]
		existing.global_position = camp_pos
		existing.visible = true
		return

	var camp_root := Node2D.new()
	camp_root.name = "VagrantCamp_" + npc.npc_name.replace(" ", "_")
	camp_root.global_position = camp_pos
	entities_root.add_child(camp_root)
	vagrant_camp_nodes[npc.npc_name] = camp_root

	_add_poly(PackedVector2Array([Vector2(-18, -10), Vector2(18, -10), Vector2(20, 12), Vector2(-20, 12)]), Color(0.36, 0.27, 0.18, 0.72), -2, Vector2.ZERO, camp_root)
	_add_poly(PackedVector2Array([Vector2(-15, 4), Vector2(-6, -11), Vector2(4, 4)]), Color(0.56, 0.46, 0.32, 0.95), 0, Vector2.ZERO, camp_root)
	_add_poly(PackedVector2Array([Vector2(-6, 1), Vector2(8, 1), Vector2(8, 7), Vector2(-6, 7)]), Color(0.45, 0.52, 0.36, 0.95), -1, Vector2.ZERO, camp_root)
	_add_poly(PackedVector2Array([Vector2(10, -2), Vector2(15, -5), Vector2(18, 0), Vector2(14, 4)]), Color(1.0, 0.58, 0.18, 0.88), 1, Vector2.ZERO, camp_root)

## Comprueba cada mañana (07:00 AM) si hoy toca visita de uno de los 2 Mercaderes Semanales de Extramuros:
## - Día 3 de cada semana (`day % 7 == 3`): Maese Casimir (Liga Minera, presupuesto variable `168..196 Oro`).
## - Día 6 de cada semana (`day % 7 == 6`): Valeria la Tratante (Gremio de Caza y Pieles, presupuesto variable `214..248 Oro`).

func _check_weekly_merchant_arrival(current_day: int, ignore_suspension: bool = false, silent: bool = false) -> void:
	if is_instance_valid(_active_traveling_merchant) and not _active_traveling_merchant.is_dead:
		return

	var mod_d: int = current_day % 7
	var m_id: String = ""
	if mod_d == 3:
		m_id = "casimir"
	elif mod_d == 6:
		m_id = "valeria"
	else:
		return

	var susp_left: int = int(merchant_suspension_days.get(m_id, 0))
	if susp_left > 0 and not ignore_suspension:
		var emb_name: String = "Maese Casimir" if m_id == "casimir" else "Valeria la Tratante"
		_hint_player("🚫⚖️ Ruta Comercial Suspendida: %s NO ha venido hoy al pueblo por el asesinato previo (Quedan %d días de embargo económico)." % [emb_name, susp_left])
		return

	if not ignore_suspension:
		for existing_m in get_tree().get_nodes_in_group("village_npcs"):
			if existing_m is VillageNPC and (existing_m as VillageNPC).merchant_id == m_id and (existing_m as VillageNPC).is_dead and not (existing_m as VillageNPC).corpse_buried:
				return

	if is_instance_valid(_active_traveling_merchant) and _active_traveling_merchant.is_dead:
		_active_traveling_merchant.name = "NPC_Merchant_Corpse_" + str(_active_traveling_merchant.get_instance_id())
		_active_traveling_merchant = null
	for old_n in get_tree().get_nodes_in_group("village_npcs"):
		if old_n is VillageNPC and (old_n as VillageNPC).merchant_id == m_id and (old_n as VillageNPC).is_dead:
			if not str(old_n.name).begins_with("NPC_Merchant_Corpse_"):
				old_n.name = "NPC_Merchant_Corpse_" + str(old_n.get_instance_id())

	var m_npc := VillageNPC.new()
	m_npc.trade_role = VillageNPC.TradeRole.TRAVELING_MERCHANT
	m_npc.merchant_id = m_id
	m_npc.carries_royal_safe_conduct = true
	m_npc.days_in_role = 7
	m_npc.tavern_social_pos = _tavern_social_pos

	if m_id == "casimir":
		m_npc.name = "NPC_Merchant_Casimir"
		m_npc.npc_name = "Maese Casimir"
		m_npc.npc_role = "Intendente de la Liga Minera"
		m_npc.personal_gold = randi_range(168, 196)
		m_npc.set_meta("initial_budget", m_npc.personal_gold)
		m_npc.set_meta("route_Bought_smith", false)
		m_npc.set_meta("route_Bought_carp", false)
		entities_root.add_child(m_npc)
		m_npc.setup_npc(_load_tex("res://assests/world/village/npcs_64/sprite_casimir.png"), Vector2(335, 12), Vector2(-900, 48), {"royal_ration": 3, "steel_ingot": 3, "copper_coil": 2, "repair_kit": 3}, _tavern_social_pos, "none", "Comitiva Real de Extramuros")
	else:
		m_npc.name = "NPC_Merchant_Valeria"
		m_npc.npc_name = "Valeria la Tratante"
		m_npc.npc_role = "Tratante de Caza y Pieles"
		m_npc.personal_gold = randi_range(214, 248)
		m_npc.set_meta("initial_budget", m_npc.personal_gold)
		m_npc.set_meta("route_Bought_butcher", false)
		m_npc.set_meta("route_Bought_fish", false)
		m_npc.set_meta("route_Bought_herb", false)
		entities_root.add_child(m_npc)
		m_npc.setup_npc(_load_tex("res://assests/world/village/npcs_64/sprite_valeria.png"), Vector2(585, 12), Vector2(990, 48), {"royal_ration": 4, "surgical_kit": 2, "sleeping_draught": 2}, _tavern_social_pos, "none", "Comitiva Real de Extramuros")

	m_npc.global_position = Vector2(-900, 48) if m_id == "casimir" else Vector2(990, 48)
	_active_traveling_merchant = m_npc

	if not silent:
		_hint_player("🐎👑 ¡Ha llegado %s (%s) con %d Oro y Salvoconducto Real! Comprará producción local hasta las 19:00." % [m_npc.npc_name, m_npc.npc_role, m_npc.personal_gold])

## IA física de los 2 Mercaderes Semanales: recorren las tiendas de su especialidad comprando solo lo que hay en stock
## (inyectando oro externo real a los artesanos y cazadores) y se marchan por el camino principal a las 19:00.

func update_traveling_merchant_ai(merchant: VillageNPC, delta: float) -> void:
	if merchant == null or merchant.is_dead or merchant.is_downed:
		return
	var h: int = WorldClock.current_hour if WorldClock else 12
	var m_id: String = merchant.merchant_id
	if m_id in ["high_pass", "river_port", "sun_plain"]:
		VillageCulture.update_caravan_merchant_ai(self, merchant, delta)
		return
	if m_id == "smuggler":
		VillageUnderworld.update_smuggler_merchant_ai(self, merchant, delta)
		return

	# A partir de las 19:00 regresan caminando hacia el borde del mapa para salir de la región con su Salvoconducto Real
	if h >= 19 or h < 6:
		var exit_pos: Vector2 = Vector2(-910, 48) if m_id == "casimir" else Vector2(1000, 48)
		merchant._merchant_leaving = true
		merchant.current_activity = VillageNPC.ActivityState.WORKING
		merchant._move_towards_point(exit_pos, 62.0, delta)
		if merchant.global_position.distance_to(exit_pos) <= 18.0:
			var p = get_tree().get_first_node_in_group("player")
			if p and p.has_method("show_hint"):
				p.show_hint("🐎📜 %s ha partido del valle hacia las Tierras Reales conservando %d Oro en su bolsa." % [merchant.npc_name, merchant.personal_gold])
			if _active_traveling_merchant == merchant:
				_active_traveling_merchant = null
			merchant.queue_free()
		return

	merchant._merchant_leaving = false
	merchant.current_activity = VillageNPC.ActivityState.WORKING
	var target_spot: Vector2 = Vector2(465, 44)
	if m_id == "casimir":
		if h < 12:
			target_spot = Vector2(335, -30) # Herrería de Thoran
		elif h < 16:
			target_spot = Vector2(585, 142) # Carpintería de Bram
		else:
			target_spot = Vector2(455, 44)  # Plaza Central para comerciar con el jugador
	else:
		if h < 11:
			target_spot = Vector2(585, -30) # Carnicería y Peletería de Garrick
		elif h < 14:
			target_spot = Vector2(465, 142) # Pescadería de Marlo
		elif h < 16:
			target_spot = Vector2(325, 150) # Botica de Elena
		else:
			target_spot = Vector2(480, 44)  # Plaza Central para comprar caza legal al jugador

	merchant._move_towards_point(target_spot, 56.0, delta)

	# Cuando llega a cada taller, compra solo las existencias disponibles (no gasta todo su oro si no hay suficiente mercancía)
	if m_id == "casimir":
		if h < 12 and not bool(merchant.get_meta("route_Bought_smith", false)) and merchant.global_position.distance_to(Vector2(335, -30)) <= 26.0:
			merchant.set_meta("route_Bought_smith", true)
			_merchant_buy_from_local_shop(merchant, int(VillageNPC.TradeRole.BLACKSMITH), ["repair_kit", "iron_ore", "steel_ingot"], 24, 68)
		elif h >= 12 and h < 16 and not bool(merchant.get_meta("route_Bought_carp", false)) and merchant.global_position.distance_to(Vector2(585, 142)) <= 26.0:
			merchant.set_meta("route_Bought_carp", true)
			_merchant_buy_from_local_shop(merchant, int(VillageNPC.TradeRole.CARPENTER), ["repair_kit", "wood", "copper_coil"], 20, 62)
	else:
		if h < 11 and not bool(merchant.get_meta("route_Bought_butcher", false)) and merchant.global_position.distance_to(Vector2(585, -30)) <= 26.0:
			merchant.set_meta("route_Bought_butcher", true)
			_merchant_buy_from_local_shop(merchant, int(VillageNPC.TradeRole.BUTCHER), ["leather", "cooked_meat", "roasted_chicken", "fox_pelt", "antlers"], 26, 78)
		elif h >= 11 and h < 14 and not bool(merchant.get_meta("route_Bought_fish", false)) and merchant.global_position.distance_to(Vector2(465, 142)) <= 26.0:
			merchant.set_meta("route_Bought_fish", true)
			_merchant_buy_from_local_shop(merchant, int(VillageNPC.TradeRole.FISHMONGER), ["cooked_fish", "bread", "fertilizer"], 18, 48)
		elif h >= 14 and h < 16 and not bool(merchant.get_meta("route_Bought_herb", false)) and merchant.global_position.distance_to(Vector2(325, 150)) <= 26.0:
			merchant.set_meta("route_Bought_herb", true)
			_merchant_buy_from_local_shop(merchant, int(VillageNPC.TradeRole.HERBALIST), ["herbal_poultice", "carrot_seeds"], 16, 42)

func _merchant_buy_from_local_shop(merchant: VillageNPC, role_id: int, wanted_keys: Array, unit_pay: int, max_spend_here: int) -> void:
	var holder: VillageNPC = trade_npcs.get(role_id)
	if not is_instance_valid(holder) or holder.is_dead or holder.is_downed or is_trade_sabotaged(role_id) or not holder.is_at_shop_counter():
		return
	var owner_mode_m: String = str(shop_businesses.get(role_id, {}).get("owner_mode", "NPC"))
	var spent: int = 0
	var bought_units: int = 0
	for k in wanted_keys:
		var key_s: String = str(k)
		var q: int = int(holder.shop_stock.get(key_s, 0))
		while q > 1 and merchant.personal_gold >= unit_pay and (spent + unit_pay) <= max_spend_here:
			q -= 1
			holder.shop_stock[key_s] = q
			merchant.shop_stock[key_s] = int(merchant.shop_stock.get(key_s, 0)) + 1
			merchant.personal_gold -= unit_pay
			if owner_mode_m == "SOLE_OWNER" and shop_businesses.has(role_id):
				shop_businesses[role_id]["vault_gold"] = int(shop_businesses[role_id].get("vault_gold", 0)) + unit_pay
			elif owner_mode_m == "PARTNER" and shop_businesses.has(role_id):
				var p_cut: int = int(ceil(float(unit_pay) * 0.5))
				shop_businesses[role_id]["vault_gold"] = int(shop_businesses[role_id].get("vault_gold", 0)) + p_cut
				holder.personal_gold += (unit_pay - p_cut)
			else:
				holder.personal_gold += unit_pay
			spent += unit_pay
			bought_units += 1
	if shop_businesses.has(role_id):
		shop_businesses[role_id]["stock_override"] = holder.shop_stock.duplicate()
	if spent > 0:
		_refresh_shop_stall_visual(role_id)
		# Además, los viajeros del pueblo que ayudan a cargar los fardos reciben una propina de 6 Oro del mercader
		for g in unemployed_npcs:
			if is_instance_valid(g) and not g.is_dead and merchant.personal_gold >= 6:
				merchant.personal_gold -= 6
				g.personal_gold += 6
		holder._spawn_floating_text("🤝💰 +%d Oro vendidos a %s" % [spent, merchant.npc_name], Color.GOLD, -36.0)
		merchant._spawn_floating_text("📦 Compró %d lotes (-%d Oro | Quedan %d Oro)" % [bought_units, spent, merchant.personal_gold], Color.AQUA, -36.0)
		merchant.trigger_action_animation(3.5)

## ==============================================================================
## BLOQUE 3 Y 4: CHARCOS DE SANGRE, HUELLAS DIRECCIONALES Y MOTOR DETECTIVESCO EN CADENA
## ==============================================================================
