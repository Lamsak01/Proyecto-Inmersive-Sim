@tool
extends RefCounted
const _AN_SITIOS = preload("res://mapa/anclas.gd") # plan de sitios: sitios al aire libre siguen a lo movido

## Economía y necesidades ampliadas (bloques E, `docs/PLAN_ECONOMIA_NECESIDADES.md`).
## - E1: higiene de vecinos y jugador; los vecinos caminan a lavarse (encargo «wash»).
## - E3: posición económica (rico … mendigo); los mendigos piden limosna en la plaza.
## - E5: bebida y juego: van de verdad a la taberna, gastan oro, se enganchan; borrachos hablan de más.
## - E6: lo que puede hacer el jugador (limosna, regalar oro, invitar a una ronda).
## Las enfermedades están en `VillageIllness.gd` y los robos en `VillageCrime.gd`.
## Estado guardado en `vm.needs_state`; la higiene de cada vecino en `npc.need_hygiene`.

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageFaith = preload("res://scripts/systems/VillageFaith.gd")

# ---- E1 higiene
const HYGIENE_DECAY_HOUR: float = 1.4 # 100 → 0 en unos 3 días
const DIRTY_TRADE_MULT: float = 1.5
const WASH_HOURS: Array[int] = [7, 8, 18, 19, 20]
const WASH_BASE_THRESHOLD: float = 45.0
const FILTHY: float = 20.0
const SMELL_REL: int = -1
const PLAYER_SMELLY: float = 25.0
const ERRAND_TIMEOUT_HOURS: int = 3
const ARRIVE_RADIUS: float = 24.0

# ---- E3 posición económica
const CLASS_RICH: int = 160
const CLASS_WELL_OFF: int = 70
const CLASS_HUMBLE: int = 20
const CLASS_LABEL: Dictionary = {"rico": "💰 Rico", "acomodado": "🪙 Acomodado", "humilde": "🧺 Humilde", "pobre": "🥣 Pobre", "mendigo": "🥺 Mendigo"}
const BEG_HOURS_FROM: int = 9
const BEG_HOURS_TO: int = 18
const BEG_GIVE_CHANCE: float = 0.25
const ENVY_CHANCE: float = 0.10
const ALMS_GOLD: int = 3
const GIFT_GOLD: int = 10

# ---- E5 bebida y juego
const VICE_HOURS: Array[int] = [19, 20]
const DRINK_COST: int = 3
const GAMBLE_STAKE: int = 8
const GAMBLE_WIN: float = 0.45
const ADDICT_STEP: float = 8.0
const ADDICT_DECAY: float = 3.0
const ADDICTED: float = 50.0
const DRUNK_HOURS: int = 3
const DRUNK_TELL_CHANCE: float = 0.5
const ROUND_COST: int = 4

## Borrachos de ahora mismo (clave -> hora total en que se les pasa). Copia de `needs_state.drunk` para `VillageSecrets.keeps_quiet`.
static var drunk_now: Dictionary = {}

static func state(vm) -> Dictionary:
	if not (vm.needs_state is Dictionary):
		vm.needs_state = {}
	for k in ["addict", "drunk", "ill", "immune", "thefts", "smell_day", "craving"]:
		if not vm.needs_state.has(k):
			if k == "thefts":
				vm.needs_state[k] = []
			else:
				vm.needs_state[k] = {}
	return vm.needs_state

static func total_hours() -> int:
	return (int(WorldClock.current_day) * 24 + int(WorldClock.current_hour)) if WorldClock else 0

static func today() -> int:
	return int(WorldClock.current_day) if WorldClock else 1

static func living(vm) -> Array:
	var out: Array = []
	for n in vm._get_npcs_by_person_key().values():
		if is_instance_valid(n) and not n.is_dead:
			out.append(n)
	return out

static func player_of(vm):
	return vm.get_tree().get_first_node_in_group("player") if vm.is_inside_tree() else null

static func is_outsider(npc) -> bool:
	return int(npc.trade_role) in [int(VillageNPC.TradeRole.TRAVELING_MERCHANT), int(VillageNPC.TradeRole.ROYAL_INVESTIGATOR)]

## ¿Está libre para un encargo (lavarse, ir a la taberna, pedir)? No le saca del trabajo ni del Oficio.
static func is_free(npc) -> bool:
	if npc.is_dead or npc.is_downed or npc.is_hostile or not npc.is_conscious() or is_outsider(npc):
		return false
	if npc.hangout_id >= 0 or npc.is_in_live_fight() or npc.is_busy_with_player():
		return false
	if npc.rite_pos != Vector2.ZERO or npc.errand_kind != "" or npc.sick_level >= 2:
		return false
	if npc._is_mandatory_work_hours():
		return false
	return int(npc.current_activity) in [int(VillageNPC.ActivityState.WORKING), int(VillageNPC.ActivityState.SOCIALIZING)]

# ---------------------------------------------------------------- E1 higiene

static func hygiene_decay(npc) -> float:
	var mult: float = DIRTY_TRADE_MULT if int(npc.trade_role) in [int(VillageNPC.TradeRole.BUTCHER), int(VillageNPC.TradeRole.BLACKSMITH)] else 1.0
	return HYGIENE_DECAY_HOUR * mult * clampf(1.0 - 0.35 * TraitCatalog.npc_tendency(npc, "hygiene"), 0.4, 1.6)

static func wash_threshold(npc) -> float:
	return WASH_BASE_THRESHOLD + 15.0 * TraitCatalog.npc_tendency(npc, "hygiene")

static func wash_spot(vm, npc) -> Vector2:
	if str(npc.family_id) not in ["", "none"] and npc.home_table_pos != Vector2.ZERO and (abs(npc.get_person_key().hash()) % 2) == 0:
		return npc.home_table_pos
	var best: Vector2 = vm.sitio(vm._plaza_well_pos)
	for w in vm._well_positions:
		if npc.global_position.distance_to(w) < npc.global_position.distance_to(best):
			best = w
	return best + Vector2(0, 16)

static func player_hygiene(vm) -> float:
	var pl = player_of(vm)
	if pl == null or pl.get("survival_comp") == null:
		return 100.0
	return float(pl.survival_comp.current_hygiene)

## El jugador se lava (pozo o al lavarse en el panel médico junto al agua).
static func player_wash(vm) -> void:
	var pl = player_of(vm)
	if pl != null and pl.get("survival_comp") != null:
		pl.survival_comp.restore_hygiene(100.0)

# ---------------------------------------------------------------- E3 posición

static func class_of(npc) -> String:
	if npc.is_vagrant_camper or (int(npc.trade_role) == int(VillageNPC.TradeRole.UNEMPLOYED) and npc.personal_gold < 5):
		return "mendigo"
	var g: int = npc.personal_gold
	if g >= CLASS_RICH:
		return "rico"
	if g >= CLASS_WELL_OFF:
		return "acomodado"
	if g >= CLASS_HUMBLE:
		return "humilde"
	return "pobre"

static func beg_spot(vm, npc) -> Vector2:
	return vm.sitio(vm._plaza_well_pos) + Vector2(-26.0 + float(abs(npc.get_person_key().hash()) % 3) * 13.0, 22.0)

# ---------------------------------------------------------------- B4.3 paseos nocturnos (Noctámbulo, Insomne, Sonámbulo)

const NIGHT_STROLL_SPOTS: Array[Vector2] = [
	Vector2(495, 88), Vector2(390, 56), Vector2(615, 88),
	Vector2(555, 76), Vector2(735, 78), Vector2(405, -24),
]

static func night_walk_kind(npc) -> String:
	if npc == null:
		return ""
	var p: Array = npc.person_profile.personality if npc.person_profile != null else npc.traits
	if "Sonámbulo" in p:
		return "sleepwalk"
	if "Noctámbulo" in p or "Insomne" in p or TraitCatalog.npc_tendency(npc, "night") >= 0.5:
		return "night_stroll"
	return ""

static func can_night_stroll(vm, npc) -> bool:
	if npc == null or npc.is_dead or npc.is_downed or npc.is_hostile or is_outsider(npc):
		return false
	if vm != null and vm.VillageJustice.is_npc_jailed(vm, npc):
		return false
	if npc.hangout_id >= 0 or npc.is_in_live_fight() or npc.is_busy_with_player():
		return false
	if npc.rite_pos != Vector2.ZERO or npc.errand_kind != "" or npc.sick_level >= 2:
		return false
	if npc._is_mandatory_work_hours() or npc.need_energy <= 18.0:
		return false
	var w_kind: String = night_walk_kind(npc)
	return w_kind != ""

static func night_stroll_spot(vm, npc, step: int = 0) -> Vector2:
	var h_idx: int = abs((npc.get_person_key() + ":" + str(step)).hash())
	if vm != null and "streetlights" in vm and not vm.streetlights.is_empty() and (step % 2 == 0):
		var sl: Dictionary = vm.streetlights[h_idx % vm.streetlights.size()]
		var spr: Sprite2D = sl.get("sprite")
		if is_instance_valid(spr):
			return spr.global_position + Vector2(float((h_idx % 3) - 1) * 14.0, 16.0)
	return _AN_SITIOS.mover(NIGHT_STROLL_SPOTS[h_idx % NIGHT_STROLL_SPOTS.size()] + Vector2(float((h_idx % 5) - 2) * 8.0, float(((h_idx / 5) % 3) - 1) * 8.0))

# ---------------------------------------------------------------- E5 vicios

static func addiction(vm, key: String, kind: String) -> float:
	return float((state(vm)["addict"].get(key, {}) as Dictionary).get(kind, 0.0))

static func _add_addiction(vm, key: String, kind: String, delta: float) -> void:
	var a: Dictionary = state(vm)["addict"]
	if not a.has(key):
		a[key] = {"drink": 0.0, "gamble": 0.0}
	a[key][kind] = clampf(float(a[key].get(kind, 0.0)) + delta, 0.0, 100.0)

static func is_addicted(vm, key: String, kind: String) -> bool:
	return addiction(vm, key, kind) >= ADDICTED

static func is_drunk_key(key: String) -> bool:
	return int(drunk_now.get(key, -1)) > total_hours()

static func make_drunk(vm, npc) -> void:
	var until: int = total_hours() + DRUNK_HOURS
	state(vm)["drunk"][npc.get_person_key()] = until
	drunk_now[npc.get_person_key()] = until

static func vice_chance(vm, npc, kind: String) -> float:
	var vice: float = TraitCatalog.npc_tendency(npc, "vice")
	var add: float = addiction(vm, npc.get_person_key(), kind)
	if kind == "drink":
		return clampf(0.04 + 0.22 * vice + add / 160.0, 0.0, 0.9)
	var gam: float = 0.4 if "Tahúr" in npc.person_profile.personality else 0.0
	return clampf(0.02 + 0.10 * maxf(0.0, vice) + gam + add / 160.0, 0.0, 0.8)

## Al llegar a la taberna: paga, bebe o juega, y se engancha un poco más.
static func do_vice(vm, npc, kind: String) -> Dictionary:
	var key: String = npc.get_person_key()
	var res: Dictionary = {"kind": kind, "gold": 0}
	var inn = vm._innkeeper_npc if is_instance_valid(vm._innkeeper_npc) else null
	var mult: float = 1.0 + maxf(0.0, TraitCatalog.npc_tendency(npc, "vice"))
	# M14 «La última copa»: el tabernero prometió no servirle (ni dejarle jugar) unos días
	if int((state(vm).get("no_serve", {}) as Dictionary).get(key, -1)) >= today():
		npc.add_thought("En la taberna no me han querido servir (-3)", -3.0)
		npc._spawn_floating_text("🚫🍺 «Hoy no, %s. Vete a casa.»" % npc.npc_name, Color(0.85, 0.85, 0.85), -30.0)
		return res
	if kind == "drink":
		if npc.personal_gold < DRINK_COST:
			return res
		npc.personal_gold -= DRINK_COST
		if inn != null and inn != npc:
			inn.personal_gold += DRINK_COST
		res["gold"] = -DRINK_COST
		make_drunk(vm, npc)
		npc.add_thought("Unas copas en la taberna (+4)", 4.0)
		npc._spawn_floating_text("🍺", Color(1.0, 0.85, 0.45), -30.0)
		_add_addiction(vm, key, "drink", ADDICT_STEP * mult)
	else:
		var stake: int = mini(GAMBLE_STAKE, npc.personal_gold)
		# Regla 1: juega contra la banca (el posadero); sin banca no hay partida, y no se apuesta más de lo que puede pagar.
		if inn == null or inn == npc:
			return res
		stake = mini(stake, inn.personal_gold)
		if stake <= 0:
			return res
		if randf() < GAMBLE_WIN:
			inn.personal_gold -= stake
			npc.personal_gold += stake
			res["gold"] = stake
			npc._spawn_floating_text("🎲 ¡+%d!" % stake, Color.GOLD, -30.0)
		else:
			npc.personal_gold -= stake
			inn.personal_gold += stake
			res["gold"] = -stake
			npc._spawn_floating_text("🎲 -%d" % stake, Color.CORAL, -30.0)
		_add_addiction(vm, key, "gamble", ADDICT_STEP * mult)
	state(vm)["addict"][key]["last_day"] = today()
	return res

# ---------------------------------------------------------------- relojes

## Cada segundo real: quien hace un encargo y ya llegó, lo termina.
static func tick(vm) -> void:
	var now: int = total_hours()
	for n in living(vm):
		if n.errand_kind == "":
			continue
		if now - int(n.errand_since) > ERRAND_TIMEOUT_HOURS and not (n.errand_kind in ["beg", "outpost_work", "player_shop_clerk", "fence_alley", "gathering", "catering", "club_go", "club_watch", "night_job", "familia_meet", "night_stroll", "sleepwalk", "prowl_victim"]):
			if n.errand_kind == "leisure":
				vm.VillagePlaces._leave(n)
				continue
			n.end_errand()
			continue
		if n.global_position.distance_to(n.errand_pos) > ARRIVE_RADIUS:
			continue
		match n.errand_kind:
			"wash":
				n.need_hygiene = 100.0
				n._spawn_floating_text("🧼", Color(0.7, 0.95, 1.0), -30.0)
				n.end_errand()
				vm.VillageWork.on_washed(vm, n) # V5d: chismes en el lavadero
			"drink", "gamble":
				do_vice(vm, n, n.errand_kind)
				var vice_k: String = n.errand_kind
				var cur_h_v: int = int(WorldClock.current_hour) if WorldClock else 12
				if vm.VillagePlaces.is_leisure_hour(cur_h_v, n):
					var p_seat: Vector2 = vm.VillageTavern.pick_poker_seat_for(vm, n) if vice_k == "gamble" else vm.VillageTavern.pick_seat_for(vm, n)
					var p_id: String = "tavern_poker" if vice_k == "gamble" else "tavern_hall"
					if p_seat == Vector2.ZERO:
						p_seat = vm.VillageTavern.pick_seat_for(vm, n)
						p_id = "tavern_hall"
					n.errand_kind = "leisure"
					n.errand_pos = p_seat
					n.set_meta("leisure_place", p_id)
					n.set_meta("leisure_until_hour", -1)
					vm.VillagePlaces.on_arrived(vm, n)
				else:
					n.end_errand()
			"night_job":
				vm.VillageNightJobs.on_arrived(vm, n) # P6b: llega al taller, la casa o la lápida
			"club_go":
				vm.VillageClub.on_arrived(vm, n) # P6: baja por la trampilla al club del sótano
			"night_stroll", "sleepwalk":
				var next_step: int = int(n.get_meta("night_stroll_step", 0)) + 1
				n.set_meta("night_stroll_step", next_step)
				n.errand_pos = night_stroll_spot(vm, n, next_step)
				if n.errand_kind == "sleepwalk" and randf() < 0.45:
					n._spawn_floating_text("😴💤 «Zzz...»", Color(0.78, 0.86, 1.0), -28.0)
			"prowl_victim":
				var d_prowl: Dictionary = vm.VillageDesires.active_of(vm, n.get_person_key())
				if not d_prowl.is_empty():
					var p_step: int = int(n.get_meta("prowl_step", 0)) + 1
					n.set_meta("prowl_step", p_step)
					n.errand_pos = vm.VillageDesires.prowl_spot_for_desire(vm, d_prowl, p_step)
			"beg", "outpost_work", "player_shop_clerk", "fence_alley", "club_watch", "familia_meet":
				pass # Se queda hasta la tarde (on_hour); el perista, hasta las 3:00 (P5b)
			"player_shop_buy":
				vm.VillageHousing.on_customer_arrived(vm, n) # Bloque P1: cliente compra en el mostrador de tu tienda
			"leisure":
				vm.VillagePlaces.on_arrived(vm, n) # V5c: se queda un rato (lo cierra VillagePlaces)
			"market":
				vm.VillageCulture.on_market_arrived(vm, n) # V5e: compra en el mercado
			"leave":
				vm.VillageMigration.on_left(vm, n) # V3: se marcha del valle
			"confess":
				vm.VillageConfession.on_errand_arrived(vm, n) # P4.1: confesión en la capilla
			"raid_defend":
				pass # PL.2: se quedan en el camino del este hasta que llega el asalto
			"smuggler_bust":
				vm.VillageUnderworld.on_guard_bust_arrived(vm, n) # P3 Parte B: guardia llega al campamento de contrabando
				n.end_errand()
			"gathering":
				vm.VillageHousing.on_gathering_guest_arrived(vm, n) # P4: invitado llega a la mesa de la cena/fiesta/paz
			"catering":
				vm.VillageHousing.on_caterer_arrived(vm, n) # P4: posadera llega a cocinar a tu mesa
			"familia_errand":
				vm.VillageFamilia.on_errand_arrived(vm, n) # R3: recado discreto de La Familia (cobro, préstamo o soborno)
			_:
				vm.VillageCivic.on_errand_arrived(vm, n) # V5b: votar, el alcalde en el ayuntamiento
	if not vm.is_demo_mode():
		vm.VillageHousing.tick_gathering(vm) # P4: duración, charla y cierre de cenas, fiestas y cenas de paz
		vm.VillageNightJobs.tick(vm) # P6b: guardias que pillan a quien sabotea, roba o profana; fin de la faena
		vm.VillageFamilia.tick(vm) # R2: reunión nocturna discreta en el reservado de la trattoria

static func on_hour(vm, hour: int) -> void:
	var st: Dictionary = state(vm)
	var now: int = total_hours()
	for k in st["drunk"].keys():
		if int(st["drunk"][k]) <= now:
			st["drunk"].erase(k)
	drunk_now = st["drunk"].duplicate()
	var people: Array = living(vm)
	for n in people:
		n.need_hygiene = maxf(0.0, n.need_hygiene - hygiene_decay(n))
	if not vm.is_demo_mode():
		vm.VillageDesires.on_hour(vm, hour) # B5.2: quien prepara asesinato o venganza ronda de noche la casa de su víctima
	for n in people:
		# B4.3 / B5.2: Paseos nocturnos (Noctámbulo, Insomne, Sonámbulo) y rondas nocturnas
		if n.errand_kind in ["night_stroll", "sleepwalk", "prowl_victim"]:
			var end_night_walk: bool = (hour >= 5 and hour < 22)
			if n.errand_kind == "night_stroll" and (hour >= 1 and hour < 22):
				end_night_walk = true
			if end_night_walk:
				n.end_errand()
			elif n.errand_kind in ["night_stroll", "sleepwalk"]:
				var st_step: int = int(n.get_meta("night_stroll_step", 0)) + 1
				n.set_meta("night_stroll_step", st_step)
				n.errand_pos = night_stroll_spot(vm, n, st_step)
			continue
		if (hour >= 22 or hour <= 4) and can_night_stroll(vm, n):
			var w_kind: String = night_walk_kind(n)
			if w_kind == "sleepwalk" and (hour >= 0 and hour <= 4):
				n.set_meta("night_stroll_step", hour)
				n.start_errand("sleepwalk", night_stroll_spot(vm, n, hour))
				continue
			elif w_kind == "night_stroll" and hour >= 22:
				n.set_meta("night_stroll_step", hour)
				n.start_errand("night_stroll", night_stroll_spot(vm, n, hour))
				continue
		# Mendigos: piden en la plaza durante el día
		if n.errand_kind == "beg":
			if hour >= BEG_HOURS_TO or hour < BEG_HOURS_FROM:
				n.end_errand()
			elif n.global_position.distance_to(n.errand_pos) <= ARRIVE_RADIUS * 2.0:
				_beg_round(vm, n, people)
			continue
		if not is_free(n):
			continue
		if hour in WASH_HOURS and n.need_hygiene < wash_threshold(n):
			n.start_errand("wash", vm.VillageWork.wash_spot(vm, n, wash_spot(vm, n))) # V5d: a veces, al lavadero
		elif hour in VICE_HOURS and not vm.is_building_door_blocked("tavern") and (vm.is_demo_mode() or not vm.VillageMayor.has_decree(vm, "dry_law")):
			var key: String = n.get_person_key()
			if randf() < vice_chance(vm, n, "drink"):
				if n.personal_gold >= DRINK_COST:
					var seat_d: Vector2 = vm.VillageTavern.pick_seat_for(vm, n) if "VillageTavern" in vm else vm.sitio(vm._tavern_social_pos + Vector2(randf_range(-14, 14), randf_range(-8, 8)))
					n.start_errand("drink", seat_d)
				elif is_addicted(vm, key, "drink"):
					_crave(vm, n, "bebida")
			elif not vm.is_demo_mode() and randf() < vice_chance(vm, n, "gamble"):
				if n.personal_gold >= 2:
					var seat_g: Vector2 = vm.VillageTavern.pick_poker_seat_for(vm, n) if "VillageTavern" in vm else vm.sitio(vm._tavern_games_pos + Vector2(randf_range(-10, 10), 10))
					n.start_errand("gamble", seat_g)
				elif is_addicted(vm, key, "gamble"):
					_crave(vm, n, "juego")
		elif hour >= BEG_HOURS_FROM and hour < BEG_HOURS_TO and class_of(n) == "mendigo":
			n.start_errand("beg", beg_spot(vm, n))

static func _crave(vm, n, what: String) -> void:
	state(vm)["craving"][n.get_person_key()] = today()
	n.add_thought("Necesito %s y no tengo con qué pagarlo (-6)" % what, -6.0)
	n._spawn_floating_text("😣", Color.CORAL, -30.0)

static func _beg_round(_vm, beggar, people: Array) -> void:
	for p in people:
		if p == beggar or not p.is_conscious() or class_of(p) in ["mendigo", "pobre"] or p.global_position.distance_to(beggar.global_position) > 90.0:
			continue
		var gen: float = TraitCatalog.npc_tendency(p, "generosity")
		if randf() < BEG_GIVE_CHANCE * clampf(0.6 + gen, 0.1, 2.0) and p.personal_gold >= 2:
			var amt: int = 1 + (1 if gen > 0.5 else 0)
			p.personal_gold -= amt
			beggar.personal_gold += amt
			beggar.modify_npc_relationship(p, 2, "Me dio limosna", true)
			beggar._spawn_floating_text("🙏 +%d" % amt, Color(1.0, 0.92, 0.65), -30.0)
			return

static func daily(vm) -> void:
	var st: Dictionary = state(vm)
	var people: Array = living(vm)
	for k in st["addict"].keys():
		var a: Dictionary = st["addict"][k]
		for kind in ["drink", "gamble"]:
			a[kind] = maxf(0.0, float(a.get(kind, 0.0)) - ADDICT_DECAY)
	for n in people:
		if n.need_hygiene < FILTHY:
			n.add_thought("Me siento sucio (-5)", -5.0)
			var others: Array = people.duplicate()
			others.shuffle()
			var hit: int = 0
			for o in others:
				if o == n or hit >= 2:
					continue
				o.modify_npc_relationship(n, SMELL_REL, "Huele mal", true)
				hit += 1
		# Envidia y desprecio entre ricos y pobres (pequeño)
		var cl: String = class_of(n)
		if cl in ["pobre", "mendigo"] and TraitCatalog.npc_tendency(n, "malice") > 0.3 and randf() < ENVY_CHANCE:
			for r in people:
				if r != n and class_of(r) == "rico":
					n.modify_npc_relationship(r, -1, "Presume de dinero", true)
					break

# ---------------------------------------------------------------- E6 diálogo

static func add_dialogue_choices(vm, npc, _diag: Dictionary, ch_arr: Array) -> void:
	if vm == null:
		return
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key()
	# Si hueles mal, se nota (una vez al día por vecino)
	if player_hygiene(vm) < PLAYER_SMELLY and int(st["smell_day"].get(key, -1)) != today():
		st["smell_day"][key] = today()
		npc.modify_affinity(-1)
		npc._spawn_floating_text("😷 «Uf... ¿cuándo te lavaste por última vez?»", Color(0.85, 0.9, 0.6), -46.0)
	var pos: int = maxi(0, ch_arr.size() - 1)
	var cl: String = class_of(npc)
	if cl == "mendigo":
		ch_arr.insert(pos, {"label": "🪙 Darle limosna (%d de oro)" % ALMS_GOLD, "next": "END", "action": "needs_alms"})
	elif cl == "pobre":
		ch_arr.insert(pos, {"label": "🪙 Regalarle %d de oro" % GIFT_GOLD, "next": "END", "action": "needs_gift"})
	if npc.global_position.distance_to(vm.sitio(vm._tavern_social_pos)) <= 140.0 and not is_outsider(npc):
		ch_arr.insert(pos, {"label": "🍺 Invitarle a una ronda (%d de oro)" % ROUND_COST, "next": "END", "action": "needs_round"})

## Devuelve true si la acción salió bien (para que el diálogo dispare lo que cuenta un borracho).
static func on_player_action(vm, npc, action_id: String, inv) -> bool:
	var cost: int = {"needs_alms": ALMS_GOLD, "needs_gift": GIFT_GOLD, "needs_round": ROUND_COST}.get(action_id, 0)
	if cost <= 0:
		return false
	if inv == null or int(inv.gold) < cost:
		npc._spawn_floating_text("«No tienes ni para eso.»", Color.CORAL, -46.0)
		return false
	inv.add_gold(-cost)
	match action_id:
		"needs_alms":
			npc.personal_gold += cost
			npc.modify_affinity(6)
			VillageFaith.add_rep(vm, "faith", 1)
			VillageFaith.add_rep(vm, "poor", 3)
			npc._spawn_floating_text("🙏 «Que el Alba te lo pague.»", Color(1.0, 0.92, 0.65), -46.0)
			VillageChronicle.add(vm, "player_alms", "Diste limosna a %s" % npc.npc_name, true)
		"needs_gift":
			npc.personal_gold += cost
			npc.modify_affinity(8)
			VillageFaith.add_rep(vm, "poor", 4)
			npc._spawn_floating_text("😊 «¿De verdad? Gracias, no sabes cuánto lo necesitaba.»", Color(1.0, 0.92, 0.65), -46.0)
		"needs_round":
			var inn = vm._innkeeper_npc if is_instance_valid(vm._innkeeper_npc) else null
			if inn != null:
				inn.personal_gold += cost
			npc.modify_affinity(3)
			make_drunk(vm, npc)
			npc._spawn_floating_text("🍺 «¡A tu salud! ...Oye, ¿quieres que te cuente una cosa?»", Color(1.0, 0.85, 0.45), -46.0)
	return true

## Línea del glosario (J).
static func glossary_line(vm, npc) -> String:
	var key: String = npc.get_person_key()
	var vices: Array[String] = []
	if is_addicted(vm, key, "drink"):
		vices.append("🍺 enganchado a la bebida")
	if is_addicted(vm, key, "gamble"):
		vices.append("🎲 enganchado al juego")
	var ill: Dictionary = state(vm)["ill"].get(key, {})
	var ill_txt: String = ("  🤒 %s" % str(ill.get("name", "Enfermo"))) if not ill.is_empty() else ""
	return "[color=#a8e6ff][b]🧼 Higiene:[/b][/color] %d%%   [color=#a8e6ff][b]Posición:[/b][/color] %s%s%s" % [
		int(round(npc.need_hygiene)), str(CLASS_LABEL.get(class_of(npc), "")), ("   " + ", ".join(vices)) if not vices.is_empty() else "", ill_txt]
