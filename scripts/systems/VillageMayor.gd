@tool
extends RefCounted

## Bloque P5: Presentarte a Alcalde, leyes y política (10 mecánicas).
## 1) Presentarte como candidato en el Ayuntamiento y ganar las elecciones.
## 2) Promesas electorales con factura (bajar impuestos, construir casa, ayuda al Albergue; castigo si incumples).
## 3) Discurso de campaña en la plaza y sacar trapos sucios de un candidato rival.
## 4) Nivel de impuestos de los sábados (Bajo, Normal, Alto) con efectos en recaudación y humor.
## 5) Decretos municipales activos: Ley Seca, Toque de queda nocturno y Subvención al mercado.
## 6) Presupuesto de obras y ayudas públicas (encargar casa social, financiar gachas, reforzar guardia).
## 7) Destituir o nombrar al Comisario desde la alcaldía (el nuevo comisario te es leal).
## 8) Desfalcar las arcas siendo alcalde y maquillar el libro de cuentas para borrar pistas.
## 9) Gobernar en la sombra convirtiendo al alcalde vecino en tu títere (mandas tú y cobras comisión).
## 10) Revuelta vecinal y moción de destitución para forzar elecciones anticipadas.
## Estado en `vm.town_state` (se guarda automáticamente con `town_state`).

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const VillageCivic = preload("res://scripts/systems/VillageCivic.gd")
const VillageSecrets = preload("res://scripts/systems/VillageSecrets.gd")

const EMBEZZLE_AMOUNT: int = 40
const COOK_BOOKS_COST: int = 15
const SMEAR_COST: int = 15
const RECALL_COST: int = 20
const RECALL_COOLDOWN: int = 30 # días entre mociones
const RECALL_SIGNERS: int = 6 # vecinos que te aprecian (afinidad >= 20) para que prospere
const PUPPET_WEEKLY_CUT: int = 12

static func ensure_state(vm) -> Dictionary:
	var ts: Dictionary = vm.VillageTown.state(vm)
	if not ts.has("player_candidate"):
		ts["player_candidate"] = false
	if not ts.has("campaign_bonus"):
		ts["campaign_bonus"] = 0
	if not ts.has("speech_done"):
		ts["speech_done"] = false
	if not ts.has("promise"):
		ts["promise"] = ""
	if not ts.has("promise_kept"):
		ts["promise_kept"] = false
	if not ts.has("promise_penalized"):
		ts["promise_penalized"] = false
	if not ts.has("tax_mode"):
		ts["tax_mode"] = "normal"
	if not ts.has("decrees") or not (ts["decrees"] is Dictionary):
		ts["decrees"] = {"dry_law": false, "curfew": false, "market_subsidy": false, "peace_tax": false}
	elif not (ts["decrees"] as Dictionary).has("peace_tax"):
		ts["decrees"]["peace_tax"] = false
	if not ts.has("debate_done"):
		ts["debate_done"] = false
	if not ts.has("smeared") or not (ts["smeared"] is Dictionary):
		ts["smeared"] = {}
	if not ts.has("puppet_mayor"):
		ts["puppet_mayor"] = ""
	if not ts.has("player_embezzle_risk"):
		ts["player_embezzle_risk"] = 0
	if not ts.has("protest_days"):
		ts["protest_days"] = 0
	return ts

static func today() -> int:
	return int(WorldClock.current_day) if WorldClock else 1

static func is_player_mayor(vm) -> bool:
	return str(ensure_state(vm).get("mayor", "")) == "player"

static func is_puppet_master(vm) -> bool:
	var ts: Dictionary = ensure_state(vm)
	var m: String = str(ts.get("mayor", ""))
	return m != "" and m != "player" and str(ts.get("puppet_mayor", "")) == m

static func has_mayor_power(vm) -> bool:
	return is_player_mayor(vm) or is_puppet_master(vm)

static func has_decree(vm, decree_id: String) -> bool:
	var dec: Dictionary = ensure_state(vm).get("decrees", {})
	return bool(dec.get(decree_id, false))

static func tax_multiplier(vm) -> float:
	match str(ensure_state(vm).get("tax_mode", "normal")):
		"low": return 0.5
		"high": return 1.8
		_: return 1.0

# ==============================================================================
# P5.1, P5.2 y P5.3: Candidatura del jugador, promesas, discursos y votación
# ==============================================================================
static func player_vote_score(vm, voter) -> float:
	var ts: Dictionary = ensure_state(vm)
	var s: float = float(voter.affinity) + float(int(ts.get("campaign_bonus", 0)))
	if str(ts.get("promise", "")) != "":
		s += 16.0
	return s

static func candidate_penalty(vm, cand_key: String) -> float:
	var sm: Dictionary = ensure_state(vm).get("smeared", {})
	return -25.0 if sm.has(cand_key) else 0.0

static func on_saturday_taxes(vm, res: Dictionary) -> void:
	var ts: Dictionary = ensure_state(vm)
	var mode: String = str(ts.get("tax_mode", "normal"))
	if mode == "low":
		if str(ts.get("promise", "")) == "low_tax":
			ts["promise_kept"] = true
		for n in VillageNeeds.living(vm):
			n.add_thought("Impuestos bajos esta semana (+3)", 3.0)
			if is_player_mayor(vm):
				n.modify_affinity(2)
	elif mode == "high":
		for n in VillageNeeds.living(vm):
			n.add_thought("Impuestos abusivos del Ayuntamiento (-5)", -5.0)
			if is_player_mayor(vm):
				n.modify_affinity(-4)
	# Si el jugador es alcalde, cobra su sueldo de las arcas
	if is_player_mayor(vm) and int(ts.get("treasury", 0)) >= vm.VillageTown.MAYOR_PAY:
		var pl = VillageNeeds.player_of(vm)
		if pl != null and pl.get("inventory") != null:
			ts["treasury"] = int(ts["treasury"]) - vm.VillageTown.MAYOR_PAY
			pl.inventory.add_gold(vm.VillageTown.MAYOR_PAY)
	# P5.9: Si el alcalde es títere del jugador, le pasa su comisión semanal
	elif is_puppet_master(vm):
		var mayor = vm.VillageTown.mayor_of(vm)
		var pl2 = VillageNeeds.player_of(vm)
		if mayor != null and pl2 != null and pl2.get("inventory") != null and int(ts.get("treasury", 0)) >= PUPPET_WEEKLY_CUT:
			ts["treasury"] = int(ts["treasury"]) - PUPPET_WEEKLY_CUT
			pl2.inventory.add_gold(PUPPET_WEEKLY_CUT)
			res["puppet_cut"] = PUPPET_WEEKLY_CUT

# ==============================================================================
# P5.5, P5.6, P5.7, P5.8 y P5.10: Decretos, obras, comisario, desfalco y protestas
# ==============================================================================
static func toggle_decree(vm, decree_id: String) -> bool:
	var ts: Dictionary = ensure_state(vm)
	var dec: Dictionary = ts["decrees"]
	var new_val: bool = not bool(dec.get(decree_id, false))
	dec[decree_id] = new_val
	var labels: Dictionary = {
		"dry_law": "Ley Seca (prohibido beber y apostar en la posada)",
		"curfew": "Toque de queda nocturno (desde las 23:00)",
		"market_subsidy": "Subvención municipal al mercado de los miércoles",
		"peace_tax": "Tributo de paz (multa de 8 Oro a las arcas por pelearse)"
	}
	var action_word: String = "aprobó" if new_val else "derogó"
	VillageChronicle.add(vm, "decree", "La alcaldía %s el decreto de %s" % [action_word, str(labels.get(decree_id, decree_id))], true)
	if decree_id == "dry_law" and new_val:
		vm.VillageFaith.add_rep(vm, "believers", 5)
		for n in VillageNeeds.living(vm):
			if "Bebedor" in (n.person_profile.personality if n.person_profile != null else []) or "Tahúr" in (n.person_profile.personality if n.person_profile != null else []):
				n.add_thought("La alcaldía cerró la bebida y el juego (-6)", -6.0)
	return new_val

## Tanda 4 (19): Si está activo el decreto «Tributo de paz», quienes se pelean pagan hasta 8 de oro de su bolsillo a las arcas.
static func apply_peace_tax(vm, a, b) -> int:
	if vm == null or not has_decree(vm, "peace_tax"):
		return 0
	var ts: Dictionary = ensure_state(vm)
	var collected: int = 0
	for fighter in [a, b]:
		if fighter != null and is_instance_valid(fighter):
			var fine: int = clampi(int(fighter.personal_gold), 0, 8)
			fighter.personal_gold -= fine
			collected += fine
	if collected > 0:
		ts["treasury"] = int(ts.get("treasury", 0)) + collected
	return collected

static func appoint_new_sheriff(vm) -> String:
	var ts: Dictionary = ensure_state(vm)
	if int(ts.get("treasury", 0)) < 30:
		return ""
	var old_sheriff = vm.trade_npcs.get(VillageNPC.TradeRole.SHERIFF, null)
	if old_sheriff == null or old_sheriff.is_dead or int(old_sheriff.trade_role) != int(VillageNPC.TradeRole.SHERIFF):
		for n in VillageNeeds.living(vm):
			if int(n.trade_role) == int(VillageNPC.TradeRole.SHERIFF):
				old_sheriff = n
				break
	var guard = vm.trade_npcs.get(VillageNPC.TradeRole.GUARD, null)
	if guard == null or guard.is_dead or guard == old_sheriff or int(guard.trade_role) != int(VillageNPC.TradeRole.GUARD):
		guard = null
		for n in VillageNeeds.living(vm):
			if n != old_sheriff and int(n.trade_role) == int(VillageNPC.TradeRole.GUARD):
				guard = n
				break
	if guard == null or guard.is_dead:
		for n in VillageNeeds.living(vm):
			if n != old_sheriff and int(n.trade_role) == int(VillageNPC.TradeRole.UNEMPLOYED):
				guard = n
				break
	if guard == null:
		return ""
	ts["treasury"] = int(ts["treasury"]) - 30
	if old_sheriff != null and not old_sheriff.is_dead:
		old_sheriff.trade_role = VillageNPC.TradeRole.GUARD
		old_sheriff.npc_role = "Guardia Relegado"
		old_sheriff.modify_affinity(-25)
		vm.trade_npcs[VillageNPC.TradeRole.GUARD] = old_sheriff
		if not (old_sheriff in vm.authority_npcs):
			vm.authority_npcs.append(old_sheriff)
	vm.unemployed_npcs.erase(guard)
	if not (guard in vm.authority_npcs):
		vm.authority_npcs.append(guard)
	guard.trade_role = VillageNPC.TradeRole.SHERIFF
	guard.npc_role = "Comisario Municipal"
	guard.modify_affinity(35)
	vm.trade_npcs[VillageNPC.TradeRole.SHERIFF] = guard
	for slot in vm._authority_slots:
		if int(slot.get("role", -1)) == int(VillageNPC.TradeRole.SHERIFF):
			slot["npc"] = guard
			slot["rehire_timer"] = 0.0
			slot["vacancy_announced"] = false
		elif int(slot.get("role", -1)) == int(VillageNPC.TradeRole.GUARD) and old_sheriff != null and not old_sheriff.is_dead:
			slot["npc"] = old_sheriff
			slot["rehire_timer"] = 0.0
			slot["vacancy_announced"] = false
	# Un comisario nuevo hereda los expedientes: tu búsqueda no se borra
	VillageChronicle.add(vm, "sheriff_appointed", "La alcaldía nombró a %s nuevo Comisario del valle" % guard.npc_name, true)
	return guard.npc_name

static func daily(vm) -> void:
	var ts: Dictionary = ensure_state(vm)
	# P5.2: Comprobar si el jugador incumplió su promesa electoral a los 14 días de mandato
	if is_player_mayor(vm) and str(ts.get("promise", "")) != "" and not bool(ts.get("promise_kept", false)) and not bool(ts.get("promise_penalized", false)):
		if today() - int(ts.get("term_start", today())) >= 14:
			ts["promise_penalized"] = true
			for n in VillageNeeds.living(vm):
				n.modify_affinity(-12)
				n.add_thought("El alcalde incumplió su promesa de campaña (-8)", -8.0)
			VillageChronicle.add(vm, "broken_promise", "El pueblo está indignado porque incumpliste tu promesa electoral", true)
	# P5.5: Subvención de los miércoles al mercado
	if has_decree(vm, "market_subsidy") and WorldClock != null and WorldClock.has_method("get_weekday") and int(WorldClock.get_weekday()) == 2:
		if int(ts.get("treasury", 0)) >= 12:
			ts["treasury"] = int(ts["treasury"]) - 12
			for n in VillageNeeds.living(vm):
				n.add_thought("Precios rebajados hoy en el mercado gracias al Ayuntamiento (+4)", 4.0)
	# P5.8: Si el jugador desfalcó las arcas y dejó el riesgo alto sin maquillar las cuentas, estalla el escándalo
	if is_player_mayor(vm) and int(ts.get("player_embezzle_risk", 0)) >= 2:
		ts["player_embezzle_risk"] = 0
		ts["mayor"] = ""
		ts["player_candidate"] = false
		for n in VillageNeeds.living(vm):
			n.modify_affinity(-15)
		VillageChronicle.add(vm, "player_embezzle_exposed", "Se descubrió que desviabas oro de las arcas municipales; perdiste la alcaldía", true)
		vm.VillageTown.hold_election(vm, "destitución por desfalco de las arcas")
		return
	# P5.10: Protestas vecinales si hay impuestos altos y arcas vacías
	if str(ts.get("tax_mode", "normal")) == "high" and int(ts.get("treasury", 0)) < 80:
		ts["protest_days"] = int(ts.get("protest_days", 0)) + 1
		if int(ts["protest_days"]) >= 3:
			ts["protest_days"] = 0
			ts["tax_mode"] = "normal"
			ts["player_candidate"] = false
			VillageChronicle.add(vm, "mayor_revolt", "Los vecinos protestaron frente al Ayuntamiento contra los impuestos abusivos y forzaron elecciones anticipadas", true)
			vm.VillageTown.hold_election(vm, "revuelta vecinal contra los impuestos")
	else:
		ts["protest_days"] = 0

## Interacción directa con el escritorio o la urna del Ayuntamiento (`VillageManager.interact`).
## La primera E avisa; una segunda E en 4 s sobre lo mismo confirma (mismo mecanismo que comprar casa).
static func _press_twice(vm, tag: String) -> bool:
	var now: int = Time.get_ticks_msec()
	if str(vm.get_meta("e_confirm_tag", "")) == tag and now - int(vm.get_meta("e_confirm_ms", 0)) <= 4000:
		vm.set_meta("e_confirm_tag", "")
		return true
	vm.set_meta("e_confirm_tag", tag)
	vm.set_meta("e_confirm_ms", now)
	return false

static func try_interact(vm, player: Node2D, pos: Vector2) -> bool:
	var desk: Vector2 = VillageCivic.hall_spots()["desk"]
	if pos.distance_to(desk) > 36.0:
		return false
	var ts: Dictionary = ensure_state(vm)
	if has_mayor_power(vm):
		var cur: String = str(ts.get("tax_mode", "normal"))
		var next_mode: String = "low" if cur == "normal" else ("high" if cur == "low" else "normal")
		var names_m: Dictionary = {"low": "Bajos (50 %)", "normal": "Normales (100 %)", "high": "Altos (180 %)"}
		if not _press_twice(vm, "tax:" + next_mode):
			if player.has_method("show_hint"):
				player.show_hint("🏛️❓ Impuestos ahora: %s. ¿Cambiarlos a %s? Pulsa E otra vez para confirmar." % [names_m[cur], names_m[next_mode]])
			return true
		ts["tax_mode"] = next_mode
		if next_mode == "low" and str(ts.get("promise", "")) == "low_tax":
			ts["promise_kept"] = true
		var label_m: String = {"low": "Bajos (50 %)", "normal": "Normales (100 %)", "high": "Altos (180 %)"}[next_mode]
		if player.has_method("show_hint"):
			player.show_hint("🏛️⚖️ Desde el escritorio de la Alcaldía fijaste los impuestos en: %s. (Habla con cualquier vecino para abrir el menú completo de decretos y obras)." % label_m)
		return true
	elif not bool(ts.get("player_candidate", false)) and int(vm.wanted_level) == 0:
		if not _press_twice(vm, "candidacy"):
			if player.has_method("show_hint"):
				player.show_hint("🗳️❓ ¿Inscribirte como candidato a Alcalde? Pulsa E otra vez para confirmar.")
			return true
		ts["player_candidate"] = true
		if player.has_method("show_hint"):
			player.show_hint("🗳️🏛️ Te has inscrito oficialmente en el Ayuntamiento como candidato a Alcalde para las próximas elecciones.")
		VillageChronicle.add(vm, "player_candidacy", "Te presentaste como candidato a la alcaldía del valle", true)
		return true
	return false

# ==============================================================================
# Diálogos de campaña y gobierno municipal
# ==============================================================================
static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null or npc == null or VillageNeeds.is_outsider(npc) or int(npc.trade_role) == int(VillageNPC.TradeRole.CHILD):
		return
	var ts: Dictionary = ensure_state(vm)
	var key: String = npc.get_person_key()
	var opts: Array = []

	# P5.1, P5.2 y P5.3: Candidatura, promesas, discurso y trapos sucios
	if not is_player_mayor(vm):
		if not bool(ts.get("player_candidate", false)) and int(vm.wanted_level) == 0:
			opts.append({"label": "🗳️🏛️ Anunciar que te presentas a Alcalde en las próximas elecciones", "next": "END", "action": "town_run_mayor"})
		elif bool(ts.get("player_candidate", false)):
			if int(npc.affinity) >= 20 and str(ts["pledges"].get(key, "")) != "player":
				opts.append({"label": "🤝🗳️ Pedirle que te vote a ti para Alcalde", "next": "END", "action": "town_pledge_player"})
			if str(ts.get("promise", "")) == "":
				opts.append({"label": "📢 Prometer en campaña bajar los impuestos (+apoyo electoral)", "next": "END", "action": "town_promise:low_tax"})
				opts.append({"label": "📢 Prometer construir una casa pública con las arcas (+apoyo electoral)", "next": "END", "action": "town_promise:build_house"})
				opts.append({"label": "📢 Prometer financiar más raciones en el Albergue (+apoyo electoral)", "next": "END", "action": "town_promise:shelter_aid"})
			if not bool(ts.get("speech_done", false)):
				opts.append({"label": "🎙️ Dar discurso electoral en la plaza para convencer a indecisos", "next": "END", "action": "town_speech"})
			for cand in vm.VillageTown.candidates(vm):
				if cand != npc and not (ts["smeared"] as Dictionary).has(cand.get_person_key()):
					opts.append({"label": "🗞️💥 Sacar trapos sucios del candidato %s (-%d Oro)" % [cand.npc_name, SMEAR_COST], "next": "END", "action": "town_smear:" + cand.get_person_key()})
				# Tanda 4 (17): Debates públicos entre candidatos
				if not bool(ts.get("debate_done", false)):
					opts.append({"label": "🎤🏛️ Retar a debate público en la plaza al candidato %s" % cand.npc_name, "next": "END", "action": "town_debate:" + cand.get_person_key()})

		# P5.9: Convertir al alcalde actual en tu títere si sabes algo turbio suyo o es corrupto
		if vm.VillageTown.is_mayor(vm, npc) and not is_puppet_master(vm):
			# Solo si TÚ ya conoces algo turbio suyo (desfalco oído, aventura descubierta o secta destapada)
			var aff: Dictionary = VillageSecrets.active_affair_of(vm, key)
			var has_dirt: bool = bool(vm.VillageTown.state(vm).get("player_knows_embezzle", false)) or (not aff.is_empty() and bool(aff.get("player_knows", false))) or vm.VillageSect.known_member(vm, npc)
			if has_dirt:
				opts.append({"label": "🎭🤫 Chantajear al alcalde para convertirlo en tu títere en la sombra", "next": "END", "action": "town_make_puppet"})

		# P5.10: Impulsar moción de destitución contra el alcalde actual
		if str(ts.get("mayor", "")) != "" and not vm.VillageTown.is_mayor(vm, npc) and today() - int(ts.get("last_recall_day", -999)) >= RECALL_COOLDOWN:
			opts.append({"label": "📜🔥 Recoger firmas e impulsar moción de destitución del alcalde (-%d Oro)" % RECALL_COST, "next": "END", "action": "town_recall"})

	# P5.4, P5.5, P5.6, P5.7 y P5.8: Poderes de Alcalde (o amo del alcalde títere)
	if has_mayor_power(vm):
		var cur_tax: String = str(ts.get("tax_mode", "normal"))
		for tm in [["low", "Bajos (mitad, +aprecio)"], ["normal", "Normales"], ["high", "Altos (doble, -humor)"]]:
			if tm[0] != cur_tax:
				opts.append({"label": "⚖️💰 Fijar impuestos de los sábados en: %s" % tm[1], "next": "END", "action": "town_tax:" + tm[0]})
		for dec in [["dry_law", "Ley Seca en la posada"], ["curfew", "Toque de queda nocturno (23:00)"], ["market_subsidy", "Subvención al mercado (miércoles)"], ["peace_tax", "Tributo de paz (multa de 8 Oro a quienes se peleen)"]]:
			var active_d: bool = has_decree(vm, dec[0])
			opts.append({"label": "📜 %s decreto: %s" % ["Derogar" if active_d else "Firmar", dec[1]], "next": "END", "action": "town_decree:" + dec[0]})
		# Tanda 4 (18): Indultar acusados o rehabilitar repudiados desde la alcaldía
		if int(ts.get("treasury", 0)) >= 15:
			var cst_p: Dictionary = vm.VillageClans.state(vm)
			for dk in (cst_p["disowned"] as Dictionary).keys():
				var d_npc = vm._get_npcs_by_person_key().get(dk, null)
				if d_npc != null and not d_npc.is_dead:
					opts.append({"label": "⚖️🕊️ Firmar indulto municipal y rehabilitar a %s (-15 Oro de arcas, -Ley)" % d_npc.npc_name, "next": "END", "action": "town_pardon:" + dk})
			if vm.active_sheriff_investigation.get("suspects", {}).has(npc.npc_name):
				opts.append({"label": "⚖️🕊️ Conceder indulto municipal a %s en el caso abierto (-15 Oro de arcas, -Ley)" % npc.npc_name, "next": "END", "action": "town_pardon:" + key})
		if int(ts.get("treasury", 0)) >= 100 and not VillageLots.free_lots(vm, "house").is_empty() and VillageLots.active_site(vm) == "":
			opts.append({"label": "🏗️🏠 Ordenar construir una casa social pagada con las arcas (100 Oro de arcas)", "next": "END", "action": "town_work_house"})
		if int(ts.get("treasury", 0)) >= 20:
			opts.append({"label": "🥣🏛️ Financiar 8 raciones extra en el Albergue con las arcas (20 Oro de arcas)", "next": "END", "action": "town_work_shelter"})
		if int(ts.get("treasury", 0)) >= 30:
			opts.append({"label": "👮🔄 Relevar al Comisario y nombrar a un nuevo jefe policial leal (30 Oro de arcas)", "next": "END", "action": "town_appoint_sheriff"})
		if int(ts.get("treasury", 0)) >= EMBEZZLE_AMOUNT:
			opts.append({"label": "💼🪙 Desviar %d de oro de las arcas municipales a tu bolsillo" % EMBEZZLE_AMOUNT, "next": "END", "action": "town_player_embezzle"})
		if int(ts.get("player_embezzle_risk", 0)) > 0:
			opts.append({"label": "帳🧹 Maquillar el libro de cuentas del Ayuntamiento (-%d Oro o Carisma 2)" % COOK_BOOKS_COST, "next": "END", "action": "town_cook_books"})

	if not opts.is_empty():
		opts.append({"label": "⬅️ Volver", "next": "start"})
		var title_m: String = "🏛️ Alcaldía del Valle (Arcas: %d Oro · Impuestos: %s):" % [int(ts.get("treasury", 0)), str(ts.get("tax_mode", "normal"))]
		diag["town_mayor_menu"] = {"text": title_m, "choices": opts}
		ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🏛️ Alcaldía, elecciones y decretos…", "next": "town_mayor_menu"})

static func on_player_action(vm, npc, action_id: String, inv) -> bool:
	var ts: Dictionary = ensure_state(vm)
	var arg: String = action_id.get_slice(":", 1)

	if action_id == "town_run_mayor":
		ts["player_candidate"] = true
		ts["speech_done"] = false
		VillageChronicle.add(vm, "player_candidacy", "Anunciaste tu candidatura a la Alcaldía del valle", true)
		npc._spawn_floating_text("🗳️ «¡Así que te presentas a alcalde! Veremos qué propones.»", Color.SPRING_GREEN, -46.0)
		return true

	elif action_id == "town_pledge_player":
		ts["pledges"][npc.get_person_key()] = "player"
		npc._spawn_floating_text("🗳️ «Cuenta con mi voto en la urna.»", Color(0.75, 1.0, 0.8), -46.0)
		return true

	elif action_id.begins_with("town_promise:"):
		ts["promise"] = arg
		ts["promise_kept"] = false
		ts["promise_penalized"] = false
		for n in VillageNeeds.living(vm):
			n.modify_affinity(4)
		var p_labels: Dictionary = {"low_tax": "bajar los impuestos", "build_house": "construir vivienda pública", "shelter_aid": "financiar el Albergue"}
		VillageChronicle.add(vm, "campaign_promise", "Prometiste en campaña %s si sales elegido alcalde" % str(p_labels.get(arg, arg)), true)
		npc._spawn_floating_text("📢 «¡Buena promesa! Pero más te vale cumplirla si ganas.»", Color.SPRING_GREEN, -46.0)
		return true

	elif action_id == "town_speech":
		ts["speech_done"] = true
		var pl = npc._get_player()
		var cha: int = int(pl.call("get_skill_level", "charisma")) if pl != null and pl.has_method("get_skill_level") else 1
		ts["campaign_bonus"] = int(ts.get("campaign_bonus", 0)) + 8 + cha * 4
		VillageChronicle.add(vm, "campaign_speech", "Diste un discurso electoral en la plaza que convenció a varios indecisos", true)
		npc._spawn_floating_text("🎙️👏 «¡Bien hablado! Has ganado apoyos para las urnas.»", Color.SPRING_GREEN, -46.0)
		return true

	elif action_id.begins_with("town_smear:"):
		if inv == null or int(inv.gold) < SMEAR_COST:
			npc._spawn_floating_text("Necesitas %d de oro para difundir el escándalo" % SMEAR_COST, Color.ORANGE_RED, -44.0)
			return true
		inv.add_gold(-SMEAR_COST)
		ts["smeared"][arg] = true
		var target = vm._get_npcs_by_person_key().get(arg, null)
		if target != null:
			target.modify_affinity(-15)
			VillageChronicle.add(vm, "campaign_smear", "Salieron a la luz trapos sucios contra la candidatura de %s" % target.npc_name, true)
		npc._spawn_floating_text("🗞️💥 «Con esto su campaña electoral queda hundida.»", Color.GOLD, -46.0)
		return true

	elif action_id == "town_make_puppet":
		ts["puppet_mayor"] = npc.get_person_key()
		npc.modify_affinity(-10)
		VillageChronicle.add(vm, "puppet_mayor", "Convertiste al alcalde %s en tu títere en la sombra" % npc.npc_name, false)
		npc._spawn_floating_text("😰🎭 «Está bien... firmaré los decretos que me pidas y te daré tu parte.»", Color.GOLD, -46.0)
		return true

	elif action_id == "town_recall":
		if inv == null or int(inv.gold) < RECALL_COST:
			npc._spawn_floating_text("Necesitas %d de oro para impulsar la moción" % RECALL_COST, Color.ORANGE_RED, -44.0)
			return true
		if today() - int(ts.get("last_recall_day", -999)) < RECALL_COOLDOWN:
			return true
		inv.add_gold(-RECALL_COST)
		ts["last_recall_day"] = today()
		# Hacen falta firmas de verdad: vecinos adultos que te aprecien
		var signers: int = 0
		for n in VillageNeeds.living(vm):
			if not VillageNeeds.is_outsider(n) and int(n.trade_role) != int(VillageNPC.TradeRole.CHILD) and int(n.affinity) >= 20:
				signers += 1
		if signers < RECALL_SIGNERS:
			VillageChronicle.add(vm, "mayor_recall_failed", "Tu moción contra el alcalde no reunió firmas suficientes (%d de %d)" % [signers, RECALL_SIGNERS], true)
			npc._spawn_floating_text("📜❌ «Solo %d firmas... la moción no prospera. Habrá que esperar.»" % signers, Color.ORANGE_RED, -46.0)
			return true
		ts["player_candidate"] = true
		VillageChronicle.add(vm, "mayor_recall", "Impulsaste una moción vecinal que forzó elecciones anticipadas en el Ayuntamiento", true)
		vm.VillageTown.hold_election(vm, "moción de destitución vecinal")
		npc._spawn_floating_text("📜🔥 «¡Se convocan elecciones anticipadas hoy mismo!»", Color.SPRING_GREEN, -46.0)
		return true

	elif action_id.begins_with("town_tax:"):
		ts["tax_mode"] = arg
		if arg == "low" and str(ts.get("promise", "")) == "low_tax":
			ts["promise_kept"] = true
		VillageChronicle.add(vm, "tax_rate_changed", "La alcaldía fijó el nivel de impuestos en: %s" % arg, true)
		npc._spawn_floating_text("⚖️💰 Nivel de impuestos cambiado a: %s" % arg, Color.SPRING_GREEN, -46.0)
		return true

	elif action_id.begins_with("town_decree:"):
		var on_now: bool = toggle_decree(vm, arg)
		npc._spawn_floating_text("📜 Decreto %s: %s" % [arg, "ACTIVO" if on_now else "DEROGADO"], Color.SPRING_GREEN, -46.0)
		return true

	elif action_id == "town_work_house":
		var free: Array = VillageLots.free_lots(vm, "house")
		if free.is_empty():
			return true
		var built_id: String = VillageLots.request_build(vm, str(free[0]), "house", null, "🏠 Casa Municipal")
		if built_id != "":
			if str(ts.get("promise", "")) == "build_house":
				ts["promise_kept"] = true
			for n in VillageNeeds.living(vm):
				n.modify_affinity(3)
			npc._spawn_floating_text("🏗️🏠 «El carpintero empezará la casa municipal con fondos de las arcas.»", Color.SPRING_GREEN, -46.0)
		return true

	elif action_id == "town_work_shelter":
		if int(ts.get("treasury", 0)) < 20:
			return true
		ts["treasury"] = int(ts["treasury"]) - 20
		ts["shelter_rations"] = int(ts.get("shelter_rations", 0)) + 8
		if str(ts.get("promise", "")) == "shelter_aid":
			ts["promise_kept"] = true
		for n in VillageNeeds.living(vm):
			if VillageNeeds.class_of(n) in ["pobre", "mendigo"]:
				n.modify_affinity(6)
		VillageChronicle.add(vm, "shelter_funded", "La alcaldía financió 8 raciones extra para los pobres en el Albergue del Alba", true)
		npc._spawn_floating_text("🥣🏛️ «¡8 raciones extra listas en el Albergue del Alba!»", Color.SPRING_GREEN, -46.0)
		return true

	elif action_id == "town_appoint_sheriff":
		var new_sh: String = appoint_new_sheriff(vm)
		if new_sh != "":
			npc._spawn_floating_text("👮🔄 «%s es el nuevo Comisario del valle.»" % new_sh, Color.SPRING_GREEN, -46.0)
		return true

	elif action_id == "town_player_embezzle":
		var take: int = mini(EMBEZZLE_AMOUNT, int(ts.get("treasury", 0)))
		if take <= 0:
			return true
		ts["treasury"] = int(ts["treasury"]) - take
		if inv != null:
			inv.add_gold(take)
		if randf() < 0.45:
			ts["player_embezzle_risk"] = int(ts.get("player_embezzle_risk", 0)) + 1
		VillageChronicle.add(vm, "player_embezzle", "Desviaste %d de oro de las arcas municipales a tu bolsillo" % take, false)
		npc._spawn_floating_text("💼🪙 Desviaste +%d de oro de las arcas municipales" % take, Color.GOLD, -46.0)
		return true

	elif action_id == "town_cook_books":
		var pl = npc._get_player()
		var cha: int = int(pl.call("get_skill_level", "charisma")) if pl != null and pl.has_method("get_skill_level") else 0
		if cha < 2:
			if inv == null or int(inv.gold) < COOK_BOOKS_COST:
				npc._spawn_floating_text("Necesitas %d de oro o Carisma Nv.2 para maquillar las cuentas" % COOK_BOOKS_COST, Color.ORANGE_RED, -44.0)
				return true
			inv.add_gold(-COOK_BOOKS_COST)
		ts["player_embezzle_risk"] = 0
		npc._spawn_floating_text("🧹📒 «Las cuentas del Ayuntamiento vuelven a cuadrar al céntimo.»", Color.SPRING_GREEN, -46.0)
		return true

	elif action_id.begins_with("town_debate:"):
		ts["debate_done"] = true
		var pl_d = npc._get_player()
		var cha_d: int = int(pl_d.call("get_skill_level", "charisma")) if pl_d != null and pl_d.has_method("get_skill_level") else 1
		ts["campaign_bonus"] = int(ts.get("campaign_bonus", 0)) + 10 + cha_d * 4
		var rival = vm._get_npcs_by_person_key().get(arg, null)
		var swayed: int = 0
		for v_n in VillageNeeds.living(vm):
			if int(v_n.trade_role) == int(VillageNPC.TradeRole.CHILD) or v_n == rival:
				continue
			var vk: String = v_n.get_person_key()
			if str(ts["pledges"].get(vk, "")) != "player":
				ts["pledges"][vk] = "player"
				swayed += 1
				if swayed >= 2 + cha_d:
					break
		var r_name: String = rival.npc_name if rival != null else "tu rival"
		VillageChronicle.add(vm, "mayor_debate", "Ganaste el debate público en la plaza frente a %s (+%d votos)" % [r_name, swayed], true)
		npc._spawn_floating_text("🎤👏 «¡Lo dejaste sin argumentos en el debate! +%d vecinos te votarán.»" % swayed, Color.SPRING_GREEN, -46.0)
		return true

	elif action_id.begins_with("town_pardon:"):
		if int(ts.get("treasury", 0)) < 15:
			return true
		var target_p = vm._get_npcs_by_person_key().get(arg, null)
		if target_p == null:
			return true
		ts["treasury"] = int(ts["treasury"]) - 15
		vm.VillageFaith.add_rep(vm, "law", -6)
		var cst_p2: Dictionary = vm.VillageClans.state(vm)
		if (cst_p2["disowned"] as Dictionary).has(arg):
			var d_info: Dictionary = cst_p2["disowned"][arg]
			target_p.family_id = str(d_info.get("fam", target_p.family_id))
			target_p.family_name = str(d_info.get("by", "Rehabilitado"))
			cst_p2["disowned"].erase(arg)
		var susp_p: Dictionary = vm.active_sheriff_investigation.get("suspects", {})
		if susp_p.has(target_p.npc_name):
			susp_p[target_p.npc_name]["score"] = 0
		target_p.modify_affinity(25)
		vm.VillageClans.grant_honor_debt(vm, target_p, "le concedió un indulto desde la alcaldía")
		VillageChronicle.add(vm, "mayor_pardon", "La alcaldía concedió un indulto municipal a %s (-Ley)" % target_p.npc_name, true)
		npc._spawn_floating_text("⚖️🕊️ «Queda firmado el indulto municipal para %s.»" % target_p.npc_name, Color.GOLD, -46.0)
		return true

	return false
