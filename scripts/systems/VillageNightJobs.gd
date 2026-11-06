extends RefCounted

## Bloque P6 parte B (Claude Code): sabotajes, robos y profanaciones nocturnas que alguien hace DE VERDAD.
## El trabajo se apunta (al contratarlo o cuando un clan lo decide a medianoche); a la 1:00 un vecino camina hasta el
## objetivo y, si se queda allí 20 minutos de juego sin que lo pillen, ocurre el efecto de siempre.
## Lo pilla un guardia despierto a ≤ 160 px o el jugador ([E] a ≤ 60 px: «¡Te he visto! ¿Qué haces aquí?»).
## Si lo pagaste tú, puede confesar: 0,6 − 0,4 × lealtad (−0,2 si te teme), mínimo 0,05.

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageUnderworld = preload("res://scripts/systems/VillageUnderworld.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

const START_HOUR: int = 1
const GIVE_UP_HOUR: int = 5 # si a las 5:00 no ha acabado, lo deja
const ACT_MINUTES: int = 20
const GUARD_PX: float = 160.0
const PLAYER_CATCH_PX: float = 60.0
const AGENT_MALICE: float = 0.3

static func jobs(vm) -> Array:
	var ns: Dictionary = VillageNeeds.state(vm)
	if not (ns.get("night_jobs", null) is Array):
		ns["night_jobs"] = []
	return ns["night_jobs"]

static func _now_minutes() -> int:
	if WorldClock == null:
		return 0
	return (int(WorldClock.current_day) * 24 + int(WorldClock.current_hour)) * 60 + int(WorldClock.current_minute)

## Apunta un trabajo para la 1:00 de la próxima noche (si se apunta de madrugada antes de la 1:00, esa misma noche).
## `job`: {type: sabotage|thief|clan_sabotage|grave, ...datos del efecto, agent_key (opcional), paid_by_player}
static func queue(vm, job: Dictionary) -> void:
	var d: int = VillageUnderworld.today()
	var h: int = VillageUnderworld.hour()
	var start_day: int = d if h < START_HOUR else d + 1
	job["start_at"] = start_day * 24 + START_HOUR
	job["status"] = "pending"
	jobs(vm).append(job)

static func _free(n) -> bool:
	return n != null and is_instance_valid(n) and not n.is_dead and not n.is_incapacitated() and not n.is_in_live_fight() \
		and not n.is_busy_with_player() and not n.is_hostile and n.rite_pos == Vector2.ZERO

## El vecino adulto más malicioso (≥ 0,3) libre esa noche; si no hay, el perista.
static func pick_hired_agent(vm):
	var best = null
	var best_m: float = AGENT_MALICE
	for n in VillageNeeds.living(vm):
		if int(n.trade_role) in [int(VillageNPC.TradeRole.CHILD), int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.ROYAL_INVESTIGATOR)]:
			continue
		if VillageNeeds.is_outsider(n) or not _free(n) or (n.errand_kind != "" and n.errand_kind != "fence_alley"):
			continue
		var m: float = TraitCatalog.npc_tendency(n, "malice")
		if m >= best_m:
			best_m = m
			best = n
	if best == null:
		best = VillageUnderworld.get_fence_npc(vm)
	return best

static func target_pos(vm, job: Dictionary) -> Vector2:
	match str(job.get("type", "")):
		"sabotage", "clan_sabotage":
			var o = vm.trade_npcs.get(int(job.get("role_id", -1)), null)
			if o != null and is_instance_valid(o):
				return o.work_position + Vector2(0, 10)
		"thief":
			var t = vm._get_npcs_by_person_key().get(str(job.get("target_key", "")), null)
			if t != null and is_instance_valid(t) and t.bed_position != Vector2.ZERO:
				return t.bed_position + Vector2(10, 0)
		"grave":
			var gi: int = int(job.get("grave_index", -1))
			if gi >= 0 and gi < vm._cemetery_grave_positions.size():
				return vm._cemetery_grave_positions[gi] + Vector2(0, 10)
	return Vector2.ZERO

# ------------------------------------------------------------------ reloj
static func on_hour(vm, h: int) -> void:
	if vm == null:
		return
	var now_h: int = VillageNeeds.total_hours()
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for job in jobs(vm):
		var stt: String = str(job.get("status", ""))
		if stt == "pending" and now_h >= int(job.get("start_at", 0)):
			start_job(vm, job)
		elif stt in ["walking", "acting"] and h == GIVE_UP_HOUR:
			var ag = by_key.get(str(job.get("agent_key", "")), null)
			if ag != null and is_instance_valid(ag) and ag.errand_kind == "night_job":
				ag.end_errand()
			job["status"] = "failed"
	_prune(vm)

static func start_job(vm, job: Dictionary) -> bool:
	var ag = vm._get_npcs_by_person_key().get(str(job.get("agent_key", "")), null)
	if ag == null:
		ag = pick_hired_agent(vm)
	var pos: Vector2 = target_pos(vm, job)
	if ag == null or not _free(ag) or pos == Vector2.ZERO:
		job["status"] = "failed"
		return false
	job["agent_key"] = ag.get_person_key()
	job["agent_name"] = ag.npc_name
	if ag.errand_kind != "":
		ag.end_errand()
	ag.start_errand("night_job", pos)
	job["status"] = "walking"
	return true

## Al llegar (desde `VillageNeeds.tick`): empieza los 20 minutos.
static func on_arrived(vm, n) -> void:
	var job: Dictionary = active_job_of(vm, n)
	if job.is_empty():
		n.end_errand()
		return
	if str(job["status"]) == "walking":
		job["status"] = "acting"
		job["act_since"] = _now_minutes()

static func active_job_of(vm, n) -> Dictionary:
	if n == null:
		return {}
	var k: String = n.get_person_key()
	for job in jobs(vm):
		if str(job.get("agent_key", "")) == k and str(job.get("status", "")) in ["walking", "acting"]:
			return job
	return {}

## Cada segundo (desde `VillageNeeds.tick`): guardias que lo ven y fin del trabajo.
static func tick(vm) -> void:
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for job in jobs(vm):
		var stt: String = str(job.get("status", ""))
		if not (stt in ["walking", "acting"]):
			continue
		var ag = by_key.get(str(job.get("agent_key", "")), null)
		if ag == null or not is_instance_valid(ag) or ag.is_dead or ag.errand_kind != "night_job":
			job["status"] = "failed"
			continue
		var g = _guard_watching(vm, ag)
		if g != null:
			caught(vm, job, g)
			continue
		if stt == "acting":
			ag.velocity = Vector2.ZERO
			ag.trigger_action_animation(1.2) # agachado junto a la puerta o la lápida
			if _now_minutes() - int(job.get("act_since", 0)) >= ACT_MINUTES:
				_succeed(vm, job, ag)
	_prune(vm)

static func _guard_watching(vm, ag):
	for n in VillageNeeds.living(vm):
		if n == ag or not (int(n.trade_role) in [int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.SHERIFF)]):
			continue
		if n.is_sleeping or n.is_incapacitated() or int(n.elevation_level) != int(ag.elevation_level):
			continue
		if n.global_position.distance_to(ag.global_position) <= GUARD_PX and (not vm.has_method("has_line_of_sight") or vm.has_line_of_sight(n.global_position, ag.global_position)):
			return n
	return null

static func _prune(vm) -> void:
	var keep: Array = []
	for job in jobs(vm):
		if str(job.get("status", "")) in ["pending", "walking", "acting"]:
			keep.append(job)
	var list: Array = jobs(vm)
	list.clear()
	list.append_array(keep)

# ------------------------------------------------------------------ pillarlo tú
static func catch_label(vm, npc, player) -> String:
	if vm == null or npc == null or player == null:
		return ""
	if active_job_of(vm, npc).is_empty() or player.global_position.distance_to(npc.global_position) > PLAYER_CATCH_PX:
		return ""
	return "¡Te he visto! ¿Qué haces aquí?"

## Lo llama `VillageNPC.interact`: si está en plena faena y estás cerca, lo pillas. Devuelve true si lo pilló.
static func try_player_catch(vm, npc, player) -> bool:
	if catch_label(vm, npc, player) == "":
		return false
	caught(vm, active_job_of(vm, npc), null)
	return true

# ------------------------------------------------------------------ desenlaces
## Pillado: no hay efecto. `guard` null = lo pilló el jugador. `force_confess_prob` ≥ 0 solo para pruebas.
static func caught(vm, job: Dictionary, guard, force_confess_prob: float = -1.0) -> bool:
	job["status"] = "caught"
	var ag = vm._get_npcs_by_person_key().get(str(job.get("agent_key", "")), null)
	var nm: String = ag.npc_name if ag != null else str(job.get("agent_name", "Alguien"))
	if ag != null and is_instance_valid(ag) and ag.errand_kind == "night_job":
		ag.end_errand()
	var what: String = {"sabotage": "un taller", "clan_sabotage": "un taller", "thief": "una casa", "grave": "una lápida"}.get(str(job.get("type", "")), "un sitio")
	if guard != null:
		guard._spawn_floating_text("👮 «¡Alto! ¿Qué haces ahí?»", Color(0.65, 0.82, 1.0), -38.0)
		VillageChronicle.add(vm, "night_job_caught", "%s pilló a %s de noche junto a %s" % [guard.npc_name, nm, what], true)
		if ag != null:
			ag.add_thought("La guardia me pilló de noche (-8)", -8.0)
			vm.VillageFame.add_fame(vm, ag, -6, "La guardia lo pilló de noche junto a %s" % what)
			if VillageUnderworld.is_fence(vm, ag):
				VillageUnderworld.state(vm)["fence_busted_until"] = VillageUnderworld.today() + 3
	else:
		if ag != null:
			ag._spawn_floating_text("😳 «¡Nada, nada! Ya me iba...»", Color(1.0, 0.8, 0.6), -38.0)
		VillageChronicle.add(vm, "night_job_caught", "Sorprendiste a %s de noche junto a %s" % [nm, what], false)
	var confessed: bool = false
	if bool(job.get("paid_by_player", false)) and ag != null:
		var p: float = force_confess_prob if force_confess_prob >= 0.0 else confess_prob(vm, ag)
		if randf() < p:
			confessed = true
			vm.wanted_level = clampi(int(vm.wanted_level) + 1, 1, 5)
			VillageChronicle.add(vm, "night_job_confess", "%s confesó que lo pagaste tú" % nm, true)
			ag._spawn_floating_text("🗣️ «¡Fue el forastero quien me pagó!»", Color.ORANGE_RED, -46.0)
	return confessed

static func confess_prob(vm, ag) -> float:
	var loyalty: float = clampf(float(ag.affinity) / 100.0, 0.0, 1.0)
	var p: float = 0.6 - 0.4 * loyalty
	if fears_player(vm, ag):
		p -= 0.2
	return maxf(0.05, p)

## Te teme si le cobras «protección» (no hay otro registro de amenazas a una persona).
static func fears_player(vm, ag) -> bool:
	return (VillageUnderworld.state(vm).get("rackets", {}) as Dictionary).has(str(int(ag.trade_role)))

## Llegó y aguantó 20 minutos: el efecto de siempre.
static func _succeed(vm, job: Dictionary, ag) -> void:
	job["status"] = "done"
	ag.end_errand()
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	match str(job.get("type", "")):
		"sabotage":
			var r_id: int = int(job.get("role_id", -1))
			if vm.shop_businesses.has(r_id):
				vm.shop_businesses[r_id]["sabotaged_days"] = maxi(2, int(vm.shop_businesses[r_id].get("sabotaged_days", 0)) + 2)
				vm._refresh_shop_stall_visual(r_id)
			VillageChronicle.add(vm, "hired_sabotage", "Un saboteador a sueldo averió de noche %s mientras tú tenías coartada" % str(job.get("role_title", "el taller")), true)
		"thief":
			var tnpc = by_key.get(str(job.get("target_key", "")), null)
			var take: int = 0
			var cut: int = 0
			if tnpc != null and not tnpc.is_dead:
				take = mini(30, int(float(tnpc.personal_gold) / 3.0))
				tnpc.personal_gold -= take
				cut = int(round(float(take) * 0.75))
			var pl = VillageNeeds.player_of(vm)
			var inv = pl.get("inventory") if pl != null else null
			if inv != null:
				inv.add_gold(cut)
			var rest: int = maxi(0, take - cut)
			# Como antes: la parte del ratero (25 %) se la lleva el perista que lo contrató
			if rest > 0:
				var fence_n = by_key.get(str(job.get("fence_key", "")), null)
				if fence_n != null and not fence_n.is_dead:
					fence_n.personal_gold += rest
				else:
					var swp: Dictionary = VillageUnderworld.sewers_state(vm)
					swp["lost_coins_pool"] = int(swp.get("lost_coins_pool", 0)) + rest
			VillageChronicle.add(vm, "hired_theft", "El ratero contratado desvalijó a %s de noche y te entregó tu parte (+%d de oro)" % [str(job.get("target_name", "un vecino")), cut], false)
		"clan_sabotage":
			var r2: int = int(job.get("role_id", -1))
			var cst: Dictionary = vm.VillageClans.state(vm)
			if vm.shop_businesses.has(r2) and not (cst["clan_sabotages"] as Dictionary).has(str(r2)):
				vm.shop_businesses[r2]["sabotaged_days"] = int(vm.shop_businesses[r2].get("sabotaged_days", 0)) + 1
				var rec: Dictionary = (job.get("record", {}) as Dictionary).duplicate()
				rec["day"] = VillageUnderworld.today()
				cst["clan_sabotages"][str(r2)] = rec
				VillageChronicle.add(vm, "clan_sabotage", "Alguien saboteó de noche el negocio de %s por el feudo entre clanes" % str(rec.get("victim_name", "un vecino")), true)
		"grave":
			var cst2: Dictionary = vm.VillageClans.state(vm)
			var v_name: String = str(job.get("victim_name", ""))
			if v_name != "" and not (cst2["desecrated_graves"] as Dictionary).has(v_name):
				cst2["desecrated_graves"][v_name] = {"culprit": ag.get_person_key(), "culprit_name": ag.npc_name, "day": VillageUnderworld.today(), "known": false}
				VillageChronicle.add(vm, "grave_profaned", "Alguien profanó de noche la lápida de %s en el cementerio" % v_name, true)
