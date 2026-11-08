extends RefCounted

## Bloque P6 parte A (Claude Code): club de pelea en un sótano de verdad bajo la taberna.
## - Trampilla en el patio trasero de la taberna; sala a nivel −1 en la franja de túneles del sur (y ≈ 1520, x ≈ 1150).
## - Abre de 23:00 a 3:00 las noches de días pares. El perista y 3–6 vecinos pendencieros bajan andando.
## - Pelear tú: a puño limpio, entrada 10 (doble E), nadie muere: al 20 % de vida se rinde. Premio: la bolsa (máx. 35).
## - A las 0:00, si no peleas tú, pelean los dos asistentes más agresivos; puedes apostar 15 por uno (cobras 30).
## - Si un guardia ve a alguien bajar o subir por la trampilla, la próxima noche no abre (y si eras tú, búsqueda +1).

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageHousing = preload("res://scripts/systems/VillageHousing.gd")
const VillageUnderworld = preload("res://scripts/systems/VillageUnderworld.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

const TRAPDOOR_POS: Vector2 = Vector2(516.0, -286.0) # cuarto trasero de escalera y bodega de la taberna (planta 0)
const CLUB_CENTER: Vector2 = Vector2(434.0, -224.0) # sótano directamente bajo la taberna (nivel -1, misma huella X/Y)
const CLUB_SIZE: Vector2 = Vector2(240.0, 136.0)
const LADDER_POS: Vector2 = Vector2(516.0, -276.0) # escalerilla justo debajo de la trampilla (516, -286)
const RING_RADIUS: float = 40.0
const SEAT_RADIUS: float = 56.0
const OPEN_FROM: int = 21
const OPEN_UNTIL: int = 3
const NPC_BOUT_HOUR: int = 0
const ENTRY_FEE: int = 10
const BET_AMOUNT: int = 15
const BET_PAYOUT: int = 30
const PURSE_MAX: int = 35
const SURRENDER_RATIO: float = 0.20
const WITNESS_PX: float = 160.0
const MIN_PLAYER_HP_RATIO: float = 0.35
const CHEERS: Array[String] = ["¡Dale!", "¡Arriba esa guardia!", "¡Al suelo con él!", "¡Eso es, eso es!", "¡No te quedes quieto!", "¡Uuuh!"]

static func state(vm) -> Dictionary:
	var ns: Dictionary = VillageNeeds.state(vm)
	if not (ns.get("club", null) is Dictionary):
		ns["club"] = {}
	var c: Dictionary = ns["club"]
	for k in [["night", -99], ["closed_night", -99], ["attendees", []], ["fighters", []], ["pot", 0], ["player_fought_night", -99],
			["bet", {}], ["bout_done_night", -99], ["player_inside", false]]:
		if not c.has(k[0]):
			c[k[0]] = k[1]
	return c

# ------------------------------------------------------------------ horario
static func is_club_hour(h: int) -> bool:
	return h >= OPEN_FROM or h < OPEN_UNTIL

## Día al que pertenece la noche (la de las 21:00).
static func night_of(h: int) -> int:
	var d: int = VillageUnderworld.today()
	return d if h >= OPEN_FROM else d - 1

static func is_club_night(vm, night: int) -> bool:
	return int(state(vm).get("closed_night", -99)) != night

static func is_open_now(vm) -> bool:
	var h: int = VillageUnderworld.hour()
	return is_club_hour(h) and is_club_night(vm, night_of(h))

static func seat_pos(i: int, total: int) -> Vector2:
	var a: float = TAU * float(i) / float(maxi(1, total)) - PI * 0.5
	return CLUB_CENTER + Vector2(cos(a), sin(a) * 0.8) * SEAT_RADIUS

static func on_hour(vm, h: int) -> void:
	if vm == null:
		return
	var c: Dictionary = state(vm)
	if h in [OPEN_FROM, 22, 23] and is_club_night(vm, night_of(h)) and int(c.get("night", -99)) != night_of(h):
		open_night(vm)
	elif h == NPC_BOUT_HOUR and is_open_now(vm) and int(c.get("night", -99)) == night_of(h):
		if (c.get("bout", {}) as Dictionary).is_empty() and int(c.get("player_fought_night", -99)) != int(c["night"]):
			start_npc_bout(vm)
	elif h == OPEN_UNTIL:
		close_night(vm)

static func _free_adult(n) -> bool:
	if n == null or not is_instance_valid(n) or n.is_dead or n.is_incapacitated():
		return false
	if int(n.trade_role) in [int(VillageNPC.TradeRole.CHILD), int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.ROYAL_INVESTIGATOR)]:
		return false
	if VillageNeeds.is_outsider(n) or n.is_in_live_fight() or n.is_busy_with_player() or n.is_hostile:
		return false
	return n.rite_pos == Vector2.ZERO and not n.is_at_poker_table

static func _rowdy(n) -> bool:
	return TraitCatalog.npc_tendency(n, "aggression") >= 0.35 or TraitCatalog.npc_tendency(n, "malice") >= 0.3

## 21:00–23:00: el perista y 3–6 vecinos pendencieros van a la trampilla (primero los despiertos).
static func open_night(vm) -> int:
	var c: Dictionary = state(vm)
	var fence = VillageUnderworld.get_fence_npc(vm)
	if fence == null or not _free_adult(fence):
		return 0
	var cur_h: int = VillageUnderworld.hour()
	c["night"] = night_of(cur_h) if is_club_hour(cur_h) else night_of(OPEN_FROM)
	c["pot"] = 0
	c["bet"] = {}
	c["bout"] = {}
	var awake: Array = []
	var asleep: Array = []
	for n in VillageNeeds.living(vm):
		if n == fence or not _free_adult(n) or not _rowdy(n) or (n.errand_kind != "" and n.errand_kind != "leisure"):
			continue
		if n.is_sleeping:
			asleep.append(n)
		else:
			awake.append(n)
	var want: int = randi_range(3, 6)
	var picked: Array = []
	for pool in [awake, asleep]:
		pool.shuffle()
		for n in pool:
			if picked.size() < want:
				picked.append(n)
	var keys: Array = [fence.get_person_key()]
	for n in picked:
		keys.append(n.get_person_key())
	c["attendees"] = keys
	# Los dos más agresivos (sin contar al perista) serán la pelea de medianoche
	var by_aggr: Array = picked.duplicate()
	by_aggr.sort_custom(func(x, y): return TraitCatalog.npc_tendency(x, "aggression") > TraitCatalog.npc_tendency(y, "aggression"))
	c["fighters"] = [by_aggr[0].get_person_key(), by_aggr[1].get_person_key()] if by_aggr.size() >= 2 else []
	if fence.errand_kind != "":
		fence.end_errand() # deja el callejón (P5b)
	fence.start_errand("club_go", TRAPDOOR_POS)
	fence._spawn_floating_text("🕳️🥊 «Abierta la trampilla del sótano (21:00–03:00)»", Color(1.0, 0.84, 0.42), -36.0)
	for n in picked:
		if n.errand_kind == "leisure":
			vm.VillagePlaces._leave(n)
		n.start_errand("club_go", TRAPDOOR_POS)
	return picked.size()

## Al llegar a la trampilla: baja por la escalerilla a la sala (nivel −1) y camina hasta su sitio alrededor del corro.
static func on_arrived(vm, n) -> void:
	var c: Dictionary = state(vm)
	var keys: Array = c.get("attendees", [])
	var idx: int = keys.find(n.get_person_key())
	if idx < 0 or not is_open_now(vm):
		n.end_errand()
		return
	_check_trapdoor_witness(vm, n, TRAPDOOR_POS)
	var seat: Vector2 = seat_pos(idx, keys.size())
	n.global_position = LADDER_POS + Vector2(randf_range(-4.0, 4.0), randf_range(2.0, 6.0))
	vm.set_npc_elevation_level(n, -1)
	n.start_errand("club_watch", seat)

## 3:00: todos suben por la trampilla y vuelven a casa.
static func close_night(vm) -> void:
	var c: Dictionary = state(vm)
	if not (c.get("bout", {}) as Dictionary).is_empty():
		_end_bout(vm, "", "cierre")
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for k in c.get("attendees", []):
		var n = by_key.get(str(k), null)
		if n == null or not is_instance_valid(n) or n.is_dead:
			continue
		if n.errand_kind in ["club_go", "club_watch"]:
			n.end_errand()
		if int(n.elevation_level) == -1 and n.global_position.distance_to(CLUB_CENTER) <= CLUB_SIZE.length():
			n.global_position = TRAPDOOR_POS + Vector2(randf_range(-10, 10), randf_range(4, 12))
			vm.set_npc_elevation_level(n, 0)
	c["attendees"] = []
	c["fighters"] = []
	c["bet"] = {}

static func attendees_below(vm) -> Array:
	var out: Array = []
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for k in state(vm).get("attendees", []):
		var n = by_key.get(str(k), null)
		if n != null and is_instance_valid(n) and not n.is_dead and n.errand_kind == "club_watch" and int(n.elevation_level) == -1:
			out.append(n)
	return out

# ------------------------------------------------------------------ trampilla y escalerilla
static func trapdoor_label(vm) -> String:
	return "🕳️🥊 Bajar al Club de Peleas del Sótano" if is_open_now(vm) else "🕳️🔒 Trampilla del Sótano de Peleas (Abre cada noche de 21:00 a 03:00)"

static func go_down(vm, player: Node2D) -> bool:
	if not is_open_now(vm) or player == null:
		_msg(player, "La trampilla está cerrada", Color.LIGHT_GRAY)
		return false
	_check_trapdoor_witness(vm, player, TRAPDOOR_POS)
	player.global_position = LADDER_POS + Vector2(0, 12)
	vm.set_player_elevation_level(-1)
	vm._elevation_anchor = Vector2.INF
	state(vm)["player_inside"] = true
	sync_club_visibility(vm)
	return true

static func go_up(vm, player: Node2D) -> void:
	if player == null:
		return
	if not (state(vm).get("bout", {}) as Dictionary).is_empty() and str(state(vm)["bout"].get("type", "")) == "player":
		_end_bout(vm, "rival", "huida")
	player.global_position = TRAPDOOR_POS + Vector2(0, 12)
	vm.set_player_elevation_level(0)
	state(vm)["player_inside"] = false
	sync_club_visibility(vm)
	_check_trapdoor_witness(vm, player, TRAPDOOR_POS)

## B4: al cargar partida. Un combate en marcha se anula sin ganador (se devuelven la entrada y la apuesta); los vecinos
## del club recuperan su piso y su sitio (los recados y el piso de los vecinos no se guardan); el jugador sigue abajo.
static func after_load(vm) -> void:
	if vm == null:
		return
	var c: Dictionary = state(vm)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var pl = VillageNeeds.player_of(vm)
	var inv = pl.get("inventory") if pl != null else null
	var fence = VillageUnderworld.get_fence_npc(vm)
	var b: Dictionary = c.get("bout", {}) if c.get("bout", {}) is Dictionary else {}
	var refund: int = 0
	if not b.is_empty():
		if str(b.get("type", "")) == "player":
			refund = ENTRY_FEE
			var rival = by_key.get(str(b.get("rival", "")), null)
			if rival != null and is_instance_valid(rival):
				rival.set_meta("club_bout", false)
				rival._clear_combat_hostility(false)
				rival.remove_from_group("enemies")
		else:
			for fk in [str(b.get("a", "")), str(b.get("b", ""))]:
				var f = by_key.get(fk, null)
				if f != null and is_instance_valid(f) and f.is_in_live_fight():
					f.end_live_fight()
		c["bout"] = {}
		c["bout_done_night"] = int(c.get("night", -1))
	var bet: Dictionary = c.get("bet", {}) if c.get("bet", {}) is Dictionary else {}
	if not bet.is_empty() and int(c.get("bout_done_night", -99)) == int(c.get("night", -1)):
		refund += int(bet.get("amount", BET_AMOUNT))
		c["bet"] = {}
	if refund > 0:
		if fence != null and is_instance_valid(fence):
			fence.personal_gold = maxi(0, int(fence.personal_gold) - refund)
		if inv != null:
			inv.add_gold(refund)
		c["pot"] = maxi(0, int(c.get("pot", 0)) - refund)
		_msg(pl, "🥊 La pelea del club se anuló; te devuelven %d de oro" % refund, Color.LIGHT_GRAY)
	# Al cargar con el juego abierto, los vecinos conservan sus marcas de la partida de antes: nadie sigue «peleando»
	for n_any in VillageNeeds.living(vm):
		if n_any.has_meta("club_bout") and bool(n_any.get_meta("club_bout")):
			n_any.set_meta("club_bout", false)
			n_any._clear_combat_hostility(false)
			n_any.remove_from_group("enemies")
	var keys: Array = c.get("attendees", [])
	var open: bool = is_open_now(vm)
	for i in range(keys.size()):
		var n = by_key.get(str(keys[i]), null)
		if n == null or not is_instance_valid(n) or n.is_dead:
			continue
		var below: bool = n.global_position.distance_to(CLUB_CENTER) <= CLUB_SIZE.length()
		if open and below:
			var seat: Vector2 = seat_pos(i, keys.size())
			n.global_position = seat
			vm.set_npc_elevation_level(n, -1)
			n.start_errand("club_watch", seat)
		elif open:
			n.start_errand("club_go", TRAPDOOR_POS)
		elif below:
			n.global_position = TRAPDOOR_POS + Vector2(randf_range(-10, 10), randf_range(4, 12))
			vm.set_npc_elevation_level(n, 0)
	if not open:
		c["attendees"] = []
		c["fighters"] = []
	if bool(c.get("player_inside", false)):
		if int(vm.player_elevation_level) == -1 and pl != null and pl.global_position.distance_to(CLUB_CENTER) <= CLUB_SIZE.length():
			vm._elevation_anchor = Vector2.INF # abajo no salta la vuelta automática a la calle; se sube por la escalerilla
		else:
			c["player_inside"] = false

static func is_player_in_club(vm) -> bool:
	return vm != null and bool(state(vm).get("player_inside", false)) and int(vm.player_elevation_level) == -1

static func _guard_watching(vm, pos: Vector2):
	for n in VillageNeeds.living(vm):
		if int(n.trade_role) in [int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.SHERIFF)]:
			if not n.is_sleeping and not n.is_incapacitated() and int(n.elevation_level) == 0 and n.global_position.distance_to(pos) <= 72.0:
				if vm == null or not vm.has_method("has_line_of_sight") or vm.has_line_of_sight(n.global_position, pos):
					return n
	return null

static func _check_trapdoor_witness(vm, who, pos: Vector2) -> void:
	if who == null or not who.is_in_group("player"):
		return
	var g = _guard_watching(vm, pos)
	if g == null:
		return
	var c: Dictionary = state(vm)
	c["closed_night"] = int(c.get("night", night_of(OPEN_FROM))) + 2
	vm.wanted_level = clampi(int(vm.wanted_level) + 1, 1, 5)
	_msg(who, "👮 ¡%s te vio en la trampilla! (Búsqueda +1)" % g.npc_name, Color.ORANGE_RED)
	VillageChronicle.add(vm, "club_seen", "%s vio al forastero colarse por una trampilla detrás de la taberna" % g.npc_name, true)

# ------------------------------------------------------------------ pelear tú
static func _player_hp_ratio(player) -> float:
	var hc = player.get_node_or_null("HealthComponent") if player != null else null
	if hc == null:
		return 1.0
	return float(hc.current_health) / maxf(1.0, float(hc.max_health))

static func _npc_hp_ratio(n) -> float:
	if n == null or n.health_comp == null:
		return 1.0
	return float(n.health_comp.current_health) / maxf(1.0, float(n.health_comp.get_effective_max_health()))

static func pick_rival(vm):
	var best = null
	var fence = VillageUnderworld.get_fence_npc(vm)
	for n in attendees_below(vm):
		if n == fence or _npc_hp_ratio(n) <= SURRENDER_RATIO + 0.1:
			continue
		if best == null or TraitCatalog.npc_tendency(n, "aggression") > TraitCatalog.npc_tendency(best, "aggression"):
			best = n
	return best

static func ring_label(vm, player) -> String:
	if not is_open_now(vm) or not is_player_in_club(vm):
		return ""
	var c: Dictionary = state(vm)
	if not (c.get("bout", {}) as Dictionary).is_empty():
		return ""
	if int(c.get("player_fought_night", -99)) == int(c.get("night", -1)):
		return "Ya peleaste esta noche"
	if pick_rival(vm) == null:
		return "No hay nadie con quien pelear"
	if player != null and _player_hp_ratio(player) < MIN_PLAYER_HP_RATIO:
		return "Estás demasiado herido para pelear"
	return "Pelear por la bolsa (entrada %d oro)" % ENTRY_FEE

static func start_player_bout(vm, player: Node2D, skip_confirm: bool = false) -> bool:
	if ring_label(vm, player) != "Pelear por la bolsa (entrada %d oro)" % ENTRY_FEE:
		return false
	var inv = player.get("inventory")
	if inv == null or int(inv.gold) < ENTRY_FEE:
		_msg(player, "Necesitas %d de oro para la entrada" % ENTRY_FEE, Color.ORANGE_RED)
		return false
	if not skip_confirm and not VillageHousing.press_twice(vm, "club_fight"):
		_msg(player, "Pulsa [E] otra vez para pagar %d de oro y pelear" % ENTRY_FEE, Color.LIGHT_GRAY)
		return false
	var c: Dictionary = state(vm)
	var fence = VillageUnderworld.get_fence_npc(vm)
	var rival = pick_rival(vm)
	inv.add_gold(-ENTRY_FEE)
	vm.pay_into(fence, ENTRY_FEE)
	c["pot"] = int(c.get("pot", 0)) + ENTRY_FEE
	c["player_fought_night"] = int(c.get("night", -1))
	c["bout"] = {"type": "player", "rival": rival.get_person_key()}
	# A puño limpio: guardamos tu arma y peleas con los puños
	vm.set_meta("club_prev_weapon", player.get("equipped_weapon"))
	if player.has_method("equip_weapon"):
		player.call("equip_weapon", _fists())
	player.global_position = CLUB_CENTER + Vector2(-18, 0)
	rival.global_position = CLUB_CENTER + Vector2(18, 0)
	rival.set_meta("club_bout", true)
	rival.is_hostile = true
	rival._civilian_hostile_timer = 14.0
	rival.add_to_group("enemies")
	rival._spawn_floating_text("🥊 «¡Vamos allá, forastero!»", Color(1.0, 0.75, 0.4), -38.0)
	return true

static func _fists():
	var w = load("res://scripts/systems/combat/WeaponData.gd").new()
	var d = load("res://scripts/systems/combat/DamageData.gd").new()
	d.amount = 6.0
	d.bleed_buildup = 0.0
	d.stun_buildup = 8.0
	w.name = "Puños"
	w.damage_data = d
	return w

## Cada fotograma (lo llama `VillageManager._process`): lleva la pelea en curso.
static func tick(vm, delta: float) -> void:
	if vm == null:
		return
	var c: Dictionary = state(vm)
	var b: Dictionary = c.get("bout", {})
	if b.is_empty():
		return
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	b["cheer_t"] = float(b.get("cheer_t", 2.0)) - delta
	if float(b["cheer_t"]) <= 0.0:
		b["cheer_t"] = randf_range(2.5, 4.5)
		var crowd: Array = attendees_below(vm)
		if not crowd.is_empty():
			var who = crowd[randi() % crowd.size()]
			if not who.has_meta("club_bout") or not bool(who.get_meta("club_bout")):
				who._spawn_floating_text(CHEERS[randi() % CHEERS.size()], Color(1.0, 0.9, 0.6), -34.0)
	if str(b.get("type", "")) == "player":
		var rival = by_key.get(str(b.get("rival", "")), null)
		var pl = VillageNeeds.player_of(vm)
		if rival == null or not is_instance_valid(rival) or rival.is_dead or pl == null:
			_end_bout(vm, "", "interrumpida")
			return
		rival._civilian_hostile_timer = 14.0
		rival.is_hostile = true
		if _npc_hp_ratio(rival) <= SURRENDER_RATIO + 0.005:
			_end_bout(vm, "player", "rendición")
		elif _player_hp_ratio(pl) <= SURRENDER_RATIO:
			_end_bout(vm, "rival", "rendición")
		elif pl.global_position.distance_to(CLUB_CENTER) > RING_RADIUS + 10.0:
			_end_bout(vm, "rival", "fuera del corro")
	else:
		var a = by_key.get(str(b.get("a", "")), null)
		var bb = by_key.get(str(b.get("b", "")), null)
		if a == null or bb == null or a.is_dead or bb.is_dead:
			_end_bout(vm, "", "interrumpida")
			return
		b["beat"] = float(b.get("beat", 1.3)) - delta
		if float(b["beat"]) <= 0.0:
			b["beat"] = 1.3
			npc_exchange_blows(a, bb)
		if _npc_hp_ratio(a) <= SURRENDER_RATIO + 0.005:
			_end_bout(vm, str(b["b"]), "rendición")
		elif _npc_hp_ratio(bb) <= SURRENDER_RATIO + 0.005:
			_end_bout(vm, str(b["a"]), "rendición")

## Un intercambio de golpes entre vecinos: cada uno pega según su agresividad (nunca baja del 20 %).
static func npc_exchange_blows(a, b) -> void:
	for pair in [[a, b], [b, a]]:
		var hitter = pair[0]
		var target = pair[1]
		if target.health_comp == null:
			continue
		var dmg: float = 3.0 + 5.0 * clampf(TraitCatalog.npc_tendency(hitter, "aggression"), 0.0, 1.0) + randf() * 3.0
		target.health_comp.apply_minor_bruise(dmg, SURRENDER_RATIO, "Pelea en el club de %s" % hitter.npc_name)

## Una vez por noche, a las 0:00: pelean los dos asistentes más agresivos.
static func start_npc_bout(vm) -> bool:
	var c: Dictionary = state(vm)
	var f: Array = c.get("fighters", [])
	if f.size() < 2:
		return false
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var a = by_key.get(str(f[0]), null)
	var b = by_key.get(str(f[1]), null)
	var below: Array = attendees_below(vm)
	if a == null or b == null or not (a in below) or not (b in below):
		return false
	a.global_position = CLUB_CENTER + Vector2(-14, 0)
	b.global_position = CLUB_CENTER + Vector2(14, 0)
	a.begin_live_fight(b)
	b.begin_live_fight(a)
	c["bout"] = {"type": "npc", "a": str(f[0]), "b": str(f[1]), "beat": 1.3}
	return true

static func _end_bout(vm, winner: String, why: String) -> void:
	var c: Dictionary = state(vm)
	var b: Dictionary = c.get("bout", {})
	c["bout"] = {}
	c["bout_done_night"] = int(c.get("night", -1))
	if b.is_empty():
		return
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var fence = VillageUnderworld.get_fence_npc(vm)
	var pl = VillageNeeds.player_of(vm)
	if str(b.get("type", "")) == "player":
		var rival = by_key.get(str(b.get("rival", "")), null)
		if rival != null and is_instance_valid(rival):
			rival.set_meta("club_bout", false)
			rival._clear_combat_hostility(false)
		var prev = vm.get_meta("club_prev_weapon", null)
		if pl != null and prev != null and pl.has_method("equip_weapon"):
			pl.call("equip_weapon", prev)
		if winner == "player":
			var purse: int = mini(mini(int(c.get("pot", 0)), PURSE_MAX), int(fence.personal_gold) if fence != null else 0)
			if fence != null:
				fence.personal_gold -= purse
			var inv = pl.get("inventory") if pl != null else null
			if inv != null:
				inv.add_gold(purse)
			if rival != null:
				rival._spawn_floating_text("🏳️ «¡Basta, basta! Me rindo.»", Color(1.0, 0.8, 0.6), -38.0)
				rival.add_thought("El forastero me tumbó en el club (-6)", -6.0)
			_msg(pl, "🥊🏆 ¡Ganaste la bolsa! (+%d de oro)" % purse, Color.GOLD)
			VillageChronicle.add(vm, "club_fight", "El forastero ganó una pelea a puño limpio en el sótano de la taberna", false)
		elif winner == "rival":
			_msg(pl, "🥊 Perdiste la pelea (%s)" % why, Color.ORANGE_RED)
			if rival != null:
				rival.add_thought("Tumbé al forastero en el club (+4)", 4.0)
			VillageChronicle.add(vm, "club_fight", "El forastero perdió una pelea a puño limpio en el sótano de la taberna", false)
		c["pot"] = 0
	else:
		var a = by_key.get(str(b.get("a", "")), null)
		var bb = by_key.get(str(b.get("b", "")), null)
		for v in [a, bb]:
			if v != null and is_instance_valid(v):
				v.end_live_fight()
				if v.health_comp != null:
					v.health_comp.current_health = maxf(v.health_comp.current_health, v.health_comp.get_effective_max_health() * 0.82)
		var bet: Dictionary = c.get("bet", {})
		if winner != "" and not bet.is_empty():
			if str(bet.get("on", "")) == winner:
				var pay: int = mini(BET_PAYOUT, int(fence.personal_gold) if fence != null else 0)
				if fence != null:
					fence.personal_gold -= pay
				var inv2 = pl.get("inventory") if pl != null else null
				if inv2 != null:
					inv2.add_gold(pay)
				_msg(pl, "🎲 ¡Acertaste la apuesta! (+%d de oro)" % pay, Color.GOLD)
			else:
				_msg(pl, "🎲 Perdiste la apuesta", Color.ORANGE_RED)
		c["bet"] = {}
		var w = by_key.get(winner, null)
		var l = bb if w == a else a
		if w != null and l != null:
			l._spawn_floating_text("🏳️ «¡Ya vale! Me rindo.»", Color(1.0, 0.8, 0.6), -38.0)
			w.add_thought("Gané en el club de la taberna (+3)", 3.0)
			l.add_thought("Me tumbaron en el club (-5)", -5.0)
			VillageChronicle.add(vm, "club_fight", "%s tumbó a %s en el sótano de la taberna" % [w.npc_name, l.npc_name], false)

# ------------------------------------------------------------------ apostar
static func bet_label(vm, fighter_key: String) -> String:
	var c: Dictionary = state(vm)
	if not is_open_now(vm) or not is_player_in_club(vm) or not (c.get("bout", {}) as Dictionary).is_empty():
		return ""
	if int(c.get("bout_done_night", -99)) == int(c.get("night", -1)) or not (c.get("bet", {}) as Dictionary).is_empty():
		return ""
	if int(c.get("player_fought_night", -99)) == int(c.get("night", -1)) or not (fighter_key in c.get("fighters", [])):
		return ""
	var n = vm._get_npcs_by_person_key().get(fighter_key, null)
	if n == null or not (n in attendees_below(vm)):
		return ""
	return "Apostar %d oro por %s" % [BET_AMOUNT, n.npc_name]

static func place_bet(vm, player: Node2D, fighter_key: String, skip_confirm: bool = false) -> bool:
	if bet_label(vm, fighter_key) == "":
		return false
	var inv = player.get("inventory") if player != null else null
	if inv == null or int(inv.gold) < BET_AMOUNT:
		_msg(player, "Necesitas %d de oro para apostar" % BET_AMOUNT, Color.ORANGE_RED)
		return false
	if not skip_confirm and not VillageHousing.press_twice(vm, "club_bet:" + fighter_key):
		_msg(player, "Pulsa [E] otra vez para apostar %d de oro" % BET_AMOUNT, Color.LIGHT_GRAY)
		return false
	var c: Dictionary = state(vm)
	inv.add_gold(-BET_AMOUNT)
	vm.pay_into(VillageUnderworld.get_fence_npc(vm), BET_AMOUNT)
	c["pot"] = int(c.get("pot", 0)) + BET_AMOUNT
	c["bet"] = {"on": fighter_key, "amount": BET_AMOUNT}
	_msg(player, "🎲 Apuesta hecha: %d de oro" % BET_AMOUNT, Color.GOLD)
	return true

# ------------------------------------------------------------------ mundo 2D (el 3D lo hace WorldStage3D)
static func build_world(vm) -> void:
	if vm == null or not ("entities_root" in vm) or not is_instance_valid(vm.entities_root):
		return
	var PropScript = load("res://scripts/obstacles/WorldInteractableProp.gd")
	if vm.is_inside_tree():
		for old_n in vm.get_tree().get_nodes_in_group("club_world"):
			if is_instance_valid(old_n):
				old_n.queue_free()
	var root := Node2D.new()
	root.name = "FightClub2D"
	root.add_to_group("club_world")
	vm.entities_root.add_child(root)
	var vis := Node2D.new()
	vis.name = "FightClubVisual2D"
	vis.z_index = -1
	vis.add_to_group("sewer_visual_2d")
	root.add_child(vis)
	var add_rect := func(center: Vector2, sz: Vector2, col: Color) -> void:
		var p := Polygon2D.new()
		var h: Vector2 = sz * 0.5
		p.polygon = PackedVector2Array([center + Vector2(-h.x, -h.y), center + Vector2(h.x, -h.y), center + Vector2(h.x, h.y), center + Vector2(-h.x, h.y)])
		p.color = col
		vis.add_child(p)
	add_rect.call(CLUB_CENTER, Vector2(368.0, 204.0), Color(0.08, 0.09, 0.08, 0.98)) # roca bajo toda la huella de la taberna
	add_rect.call(CLUB_CENTER, CLUB_SIZE, Color(0.36, 0.27, 0.18)) # suelo de tierra del sótano
	var rope := Line2D.new()
	rope.width = 2.0
	rope.default_color = Color(0.78, 0.66, 0.42)
	for i in range(25):
		var a: float = TAU * float(i) / 24.0
		rope.add_point(CLUB_CENTER + Vector2(cos(a), sin(a)) * RING_RADIUS)
	vis.add_child(rope)
	# Paredes de piedra
	var body := StaticBody2D.new()
	body.name = "FightClubWallsBody"
	body.collision_layer = 1 if is_player_in_club(vm) else 0
	body.collision_mask = 0
	root.add_child(body)
	var hs: Vector2 = CLUB_SIZE * 0.5
	for seg in [[CLUB_CENTER + Vector2(0, -hs.y - 3), Vector2(CLUB_SIZE.x + 12, 6)], [CLUB_CENTER + Vector2(0, hs.y + 3), Vector2(CLUB_SIZE.x + 12, 6)],
			[CLUB_CENTER + Vector2(-hs.x - 3, 0), Vector2(6, CLUB_SIZE.y)], [CLUB_CENTER + Vector2(hs.x + 3, 0), Vector2(6, CLUB_SIZE.y)]]:
		add_rect.call(seg[0], seg[1], Color(0.20, 0.20, 0.19))
		var col := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = seg[1]
		col.shape = rs
		col.position = seg[0]
		body.add_child(col)
	# Trampilla, escalerilla, corro y apuestas (objetos con [E])
	for spec in [["club_trapdoor", TRAPDOOR_POS, ""], ["club_ladder", LADDER_POS, ""], ["club_ring", CLUB_CENTER, ""],
			["club_bet", CLUB_CENTER + Vector2(-SEAT_RADIUS - 6, -10), "0"], ["club_bet", CLUB_CENTER + Vector2(-SEAT_RADIUS - 6, 10), "1"]]:
		var p: Node2D = PropScript.new()
		p.global_position = spec[1]
		p.add_to_group("club_world")
		vm.entities_root.add_child(p)
		p.setup_prop(vm, spec[0], spec[2], "")
	sync_club_visibility(vm)

static func sync_club_visibility(vm) -> void:
	if vm == null or not ("entities_root" in vm) or not is_instance_valid(vm.entities_root):
		return
	var in_club: bool = is_player_in_club(vm)
	var use_3d: bool = load("res://scripts/visuals/CharacterAvatar3D.gd").use_3d_characters
	var root: Node2D = vm.entities_root.get_node_or_null("FightClub2D") as Node2D
	if is_instance_valid(root):
		var vis: Node2D = root.get_node_or_null("FightClubVisual2D") as Node2D
		if is_instance_valid(vis):
			vis.visible = in_club and not use_3d
		var body: StaticBody2D = root.get_node_or_null("FightClubWallsBody") as StaticBody2D
		if is_instance_valid(body):
			body.collision_layer = 1 if in_club else 0
	if vm.is_inside_tree():
		for n0 in vm.get_tree().get_nodes_in_group("tavern_floor0_2d"):
			if n0 is CanvasItem and is_instance_valid(n0):
				(n0 as CanvasItem).visible = not in_club and not use_3d
		var on_floor0: bool = (int(vm.player_elevation_level) == 0)
		for w0 in vm.get_tree().get_nodes_in_group("tavern_floor0_walls"):
			if w0 is StaticBody2D and is_instance_valid(w0):
				(w0 as StaticBody2D).collision_layer = 1 if on_floor0 else 0
		var on_floor1: bool = (int(vm.player_elevation_level) == 1)
		for w1 in vm.get_tree().get_nodes_in_group("tavern_upper_walls"):
			if w1 is StaticBody2D and is_instance_valid(w1):
				(w1 as StaticBody2D).collision_layer = 1 if on_floor1 else 0

static func fighter_key_at(vm, slot: String) -> String:
	var f: Array = state(vm).get("fighters", [])
	var i: int = int(slot)
	return str(f[i]) if i >= 0 and i < f.size() else ""

static func _msg(player, txt: String, col: Color) -> void:
	if player != null and is_instance_valid(player) and player.has_method("_spawn_floating_text"):
		player._spawn_floating_text(txt, col, -46.0)
