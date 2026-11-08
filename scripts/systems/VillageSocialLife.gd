@tool
extends RefCounted

const VillageQuests = preload("res://scripts/systems/VillageQuests.gd")

## Q3: Un vecino rencoroso o chismoso a veces habla mal de su rival a quien tiene delante.
## T1: la probabilidad por charla depende de la malicia de sus rasgos (TraitCatalog); sin malicia, nunca calumnia.
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const GossipMemory = preload("res://scripts/systems/GossipMemory.gd")
const VillageSecrets = preload("res://scripts/systems/VillageSecrets.gd")
const VillageDesires = preload("res://scripts/systems/VillageDesires.gd")
const TraitDiscoveryRef = preload("res://scripts/systems/TraitDiscovery.gd")
const NPC_SLANDER_PER_MALICE: float = 0.075 # T5: a la mitad tras pasar a 6 rasgos (Rencoroso solo: 7,5 %)
const NPC_SLANDER_MAX_CHANCE: float = 0.25
const NPC_SLANDER_REL: int = -30

## Vida social en el mundo: quedadas, peleas en vivo y chismes. Extraído de VillageManager.gd:
## cada función recibe al VillageManager como primer parámetro (`vm`); VillageManager mantiene llamadas finas con los mismos nombres
## y conserva el estado (`_live_fights`, temporizadores y constantes). `SocialDirector` decide; aquí se aplica en el mundo.

static func _is_npc_eligible_for_hangout(_vm: VillageManager, v: VillageNPC) -> bool:
	if not is_instance_valid(v) or v.is_dead or v.is_downed or v.is_sleeping or v.is_hostile or v.is_incapacitated():
		return false
	if v.trade_role in [VillageNPC.TradeRole.TRAVELING_MERCHANT, VillageNPC.TradeRole.ROYAL_INVESTIGATOR]:
		return false
	if v.is_vagrant_camper or v.is_in_live_fight() or v.current_activity != VillageNPC.ActivityState.SOCIALIZING:
		return false
	if v.person_profile != null and int(v.person_profile.bereavement_days_left) > 0:
		return false
	return true

static func _is_npc_free_to_fight(vm: VillageManager, v: VillageNPC) -> bool:
	if not is_instance_valid(v) or v.is_dead or v.is_sleeping or v.is_hostile or v.is_incapacitated():
		return false
	if v.trade_role in [VillageNPC.TradeRole.TRAVELING_MERCHANT, VillageNPC.TradeRole.ROYAL_INVESTIGATOR]:
		return false
	if v.is_vagrant_camper or v.is_at_poker_table or v.hangout_id >= 0 or v.is_in_live_fight() or v == vm.escorting_officer:
		return false
	if v.is_busy_with_player() or v.is_busy_with_emergency():
		return false
	return v.person_profile == null or int(v.person_profile.bereavement_days_left) <= 0

static func _find_fight_guard(vm: VillageManager, pos: Vector2, a: VillageNPC, b: VillageNPC) -> VillageNPC:
	var best: VillageNPC = null
	var best_d: float = vm.FIGHT_GUARD_RADIUS
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n == a or n == b or not (n is VillageNPC):
			continue
		var v: VillageNPC = n as VillageNPC
		if v.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD] and v.is_conscious():
			var d: float = pos.distance_to(v.global_position)
			if d <= best_d:
				best_d = d
				best = v
	return best

static func _scan_rival_friction(vm: VillageManager) -> void:
	var cur_day: int = int(WorldClock.current_day) if WorldClock != null else 1
	var npcs: Array = []
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and _is_npc_free_to_fight(vm, n as VillageNPC):
			npcs.append(n)
	for i in range(npcs.size()):
		for j in range(i + 1, npcs.size()):
			var a: VillageNPC = npcs[i]
			var b: VillageNPC = npcs[j]
			var dist_sq: float = a.global_position.distance_squared_to(b.global_position)
			if dist_sq <= STREET_CONTEMPT_RADIUS * STREET_CONTEMPT_RADIUS:
				_try_street_contempt_encounter(vm, a, b)
			if dist_sq > vm.FIGHT_TRIGGER_RADIUS * vm.FIGHT_TRIGGER_RADIUS:
				continue
			if a.family_id != "none" and a.family_id != "family_police" and a.family_id == b.family_id:
				continue
			var rel: int = a.get_relationship_with_npc(b.get_person_key())
			var t_mult: float = clampf(1.0 + 0.25 * (TraitCatalog.npc_tendency(a, "aggression") + TraitCatalog.npc_tendency(b, "aggression")) + 0.15 * (TraitCatalog.npc_tendency(a, "grudge") + TraitCatalog.npc_tendency(b, "grudge")), 0.5, 1.6)
			if vm.social_director.register_rival_encounter(a.get_person_key(), b.get_person_key(), rel, cur_day, t_mult):
				a._spawn_floating_text("😠", Color(1.0, 0.60, 0.40), -28.0)

const STREET_CONTEMPT_RADIUS: float = 80.0
const STREET_CONTEMPT_COOLDOWN_SEC: float = 25.0
const CONTEMPT_BUBBLES: Array[String] = [
	"😤 «¡Aparta de mi vista!»",
	"😒 «Ni me mires al pasar…»",
	"😠 «Cámbiate de acera.»",
]
const FEUD_BUBBLES: Array[String] = [
	"🩸 «Nuestra sangre no olvida.»",
	"😤🩸 «¡Fuera de mi camino!»",
]

## B5.1: Dos vecinos con odio fuerte (<= -50) o en feudo de sangre que se cruzan a menos de 80 px se lanzan un gesto/bocadillo corto de desprecio o se apartan.
static func _try_street_contempt_encounter(vm: VillageManager, a: VillageNPC, b: VillageNPC, ignore_cooldown: bool = false) -> bool:
	if not is_instance_valid(a) or not is_instance_valid(b) or a == b:
		return false
	if a.is_dead or b.is_dead or not a.is_conscious() or not b.is_conscious():
		return false
	if a.global_position.distance_to(b.global_position) > STREET_CONTEMPT_RADIUS:
		return false
	var ka: String = a.get_person_key()
	var kb: String = b.get_person_key()
	var rel_ab: int = a.get_relationship_with_npc(kb)
	var rel_ba: int = b.get_relationship_with_npc(ka)
	var in_feud: bool = "VillageClans" in vm and vm.VillageClans != null and vm.VillageClans.is_blood_feud(vm, str(a.family_id), str(b.family_id))
	if rel_ab > -50 and rel_ba > -50 and not in_feud:
		return false
	var now_sec: float = float(Time.get_ticks_msec()) * 0.001
	var meta_k: String = "contempt_cd_" + kb
	if not ignore_cooldown and a.has_meta(meta_k) and now_sec - float(a.get_meta(meta_k, -999.0)) < STREET_CONTEMPT_COOLDOWN_SEC:
		return false
	a.set_meta("contempt_cd_" + kb, now_sec)
	b.set_meta("contempt_cd_" + ka, now_sec)
	var away: Vector2 = (a.global_position - b.global_position)
	if away.length_squared() < 0.01:
		away = Vector2(1.0, 0.0)
	else:
		away = away.normalized()
	var side_step: Vector2 = Vector2(-away.y, away.x) * 14.0 + away * 10.0
	a._wander_offset = side_step
	b._wander_offset = -side_step
	a.global_position += away * 6.0
	b.global_position -= away * 6.0
	a.set_meta("last_contempt_target", kb)
	b.set_meta("last_contempt_target", ka)
	var pool: Array[String] = FEUD_BUBBLES if in_feud else CONTEMPT_BUBBLES
	var msg_a: String = pool[absi(ka.hash() + kb.hash()) % pool.size()]
	a.spawn_short_bubble(msg_a, Color(1.0, 0.58, 0.45), -38.0, 1.5)
	b.spawn_short_bubble("😤", Color(1.0, 0.68, 0.50), -32.0, 1.5)
	return true

static func _try_start_live_fight(vm: VillageManager) -> void:
	var cur_day: int = int(WorldClock.current_day) if WorldClock != null else 1
	var pairs: Array = vm.social_director.get_fight_ready_pairs(cur_day)
	if pairs.is_empty():
		return
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for p in pairs:
		var a: VillageNPC = by_key.get(str(p[0]), null)
		var b: VillageNPC = by_key.get(str(p[1]), null)
		if not _is_npc_free_to_fight(vm, a) or not _is_npc_free_to_fight(vm, b):
			continue
		if a.global_position.distance_to(b.global_position) > vm.FIGHT_TRIGGER_RADIUS:
			continue
		var res: Dictionary = vm.social_director.try_resolve_live_fight(a, b, cur_day)
		if bool(res.get("triggered", false)):
			a.begin_live_fight(b)
			b.begin_live_fight(a)
			vm._live_fights.append({"a": a, "b": b, "res": res, "elapsed": 0.0, "guard": _find_fight_guard(vm, a.global_position, a, b)})
			return

static func _update_live_fights(vm: VillageManager, delta: float) -> void:
	if WorldClock != null and WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen():
		return
	for i in range(vm._live_fights.size() - 1, -1, -1):
		var fight: Dictionary = vm._live_fights[i]
		var a: VillageNPC = fight["a"] if is_instance_valid(fight["a"]) else null
		var b: VillageNPC = fight["b"] if is_instance_valid(fight["b"]) else null
		var interrupted: bool = false
		for v in [a, b]:
			if v == null or v.is_dead or v.is_hostile or v.is_incapacitated():
				interrupted = true
			# Una escolta o emergencia (p. ej. un guardia que tiene que llevarte a la celda) corta la pelea al momento
			elif v == vm.escorting_officer or v.is_busy_with_emergency():
				interrupted = true
		# Mientras el jugador habla con uno de ellos la pelea espera, para que pueda decidir si los separa
		if interrupted or not (a.is_busy_with_player() or b.is_busy_with_player()):
			fight["elapsed"] = float(fight["elapsed"]) + delta
		var guard_stops: bool = is_instance_valid(fight["guard"]) and fight["guard"].is_conscious() and float(fight["elapsed"]) >= vm.FIGHT_GUARD_STOP_SEC
		if interrupted or guard_stops or float(fight["elapsed"]) >= vm.FIGHT_DURATION_SEC:
			vm._live_fights.remove_at(i)
			_finish_live_fight(vm, fight, a, b, interrupted, guard_stops)
	vm._fight_scan_timer -= delta
	if vm._fight_scan_timer <= 0.0:
		vm._fight_scan_timer = randf_range(3.5, 6.0)
		_scan_rival_friction(vm)
		_try_start_live_fight(vm)

## B5.3: El jugador separa a los vecinos: mismo desenlace que un guardia, sin heridas.
static func player_stop_live_fight(vm: VillageManager, npc: VillageNPC) -> bool:
	for i in range(vm._live_fights.size()):
		var fight: Dictionary = vm._live_fights[i]
		if fight["a"] == npc or fight["b"] == npc:
			vm._live_fights.remove_at(i)
			fight["guard"] = null
			_finish_live_fight(vm, fight, fight["a"], fight["b"], false, true)
			return true
	return false

static func _finish_live_fight(vm: VillageManager, fight: Dictionary, a: VillageNPC, b: VillageNPC, interrupted: bool, guard_stops: bool) -> void:
	var res: Dictionary = fight["res"]
	vm.social_director.end_scene(int(res.get("scene_id", 0)))
	for v in [a, b]:
		if v != null:
			v.end_live_fight()
	if interrupted:
		vm.social_director.refund_live_fight(res)
		return
	a.modify_npc_relationship(b, int(res.get("relationship_delta", -14)), "💢 Llegaron a las manos")
	a._npc_social_event_cooldown = randf_range(40.0, 70.0)
	b._npc_social_event_cooldown = randf_range(40.0, 70.0)
	var winner: VillageNPC = a if a.get_person_key() == str(res.get("winner_id", "")) else b
	var loser: VillageNPC = b if winner == a else a
	var summary: String
	if guard_stops:
		var guard: VillageNPC = fight["guard"] if is_instance_valid(fight["guard"]) else null
		var stopper: String = guard.npc_name if guard != null else "El forastero"
		if guard != null:
			guard._spawn_floating_text("👮 «¡Basta ya, separaos!»", Color(0.65, 0.82, 1.0), -38.0)
			if a.get_relationship_with_npc(b.get_person_key()) <= -50 or b.get_relationship_with_npc(a.get_person_key()) <= -50:
				vm.VillageJustice.arrest_npc(vm, a, guard, "pelea grave en la calle", 24, 25)
		a.add_thought("%s me separó de %s (-4)" % [stopper, b.npc_name], -4.0)
		b.add_thought("%s me separó de %s (-4)" % [stopper, a.npc_name], -4.0)
		summary = "%s separó a %s y %s antes de que llegaran a más" % [stopper, a.npc_name, b.npc_name]
	else:
		loser.health_comp.apply_minor_bruise(randf_range(6.0, 10.0), vm.FIGHT_HEALTH_FLOOR, "Pelea con %s" % winner.npc_name)
		var loser_fem: bool = loser.person_profile != null and str(loser.person_profile.gender) == "F"
		loser._spawn_floating_text("🤕 Magullada" if loser_fem else "🤕 Magullado", Color(1.0, 0.70, 0.55), -34.0)
		winner.add_thought("Le paré los pies a %s (+2)" % loser.npc_name, 2.0)
		loser.add_thought("%s me dio una paliza (-8)" % winner.npc_name, -8.0)
		summary = "%s y %s se pelearon; %s salió peor %s" % [winner.npc_name, loser.npc_name, loser.npc_name, "parada" if loser_fem else "parado"]
	var knowers: Dictionary = {}
	if guard_stops and is_instance_valid(fight["guard"]):
		knowers[fight["guard"].get_person_key()] = true
	var witnesses: int = 0
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n == a or n == b or not (n is VillageNPC) or witnesses >= 3:
			continue
		var w: VillageNPC = n as VillageNPC
		if w.is_conscious() and vm.are_on_same_elevation(w.elevation_level, a.elevation_level) and w.global_position.distance_to(a.global_position) <= vm.FIGHT_WITNESS_RADIUS and (not vm.has_method("has_line_of_sight") or bool(vm.call("has_line_of_sight", w.global_position, a.global_position))):
			w.add_thought("Vi pelearse a %s y %s (-2)" % [a.npc_name, b.npc_name], -2.0)
			knowers[w.get_person_key()] = true
			witnesses += 1
	(vm.record_social_event("fight", winner, loser, summary)["known_by"] as Dictionary).merge(knowers)
	if not guard_stops:
		vm.VillageFame.add_fame(vm, winner, 6, "Se impuso en una pelea contra %s" % loser.npc_name)
		vm.VillageFame.add_fame(vm, loser, -4, "Salió mal parado en una pelea con %s" % winner.npc_name)
	vm.VillageClans.register_clan_clash(vm, a, b, "pelea callejera") # P1.3: enemistad entre familias por peleas
	vm.VillageMayor.apply_peace_tax(vm, a, b) # Tanda 4 (19): decreto de Tributo de paz (multa a las arcas por pelearse)

## T4: quien propone quedar se elige al azar, pero los sociables proponen más a menudo (peso 0,3–2).
static func pick_hangout_initiator(eligible: Array[VillageNPC]) -> VillageNPC:
	var weights: Array[float] = []
	var total: float = 0.0
	for v in eligible:
		var w: float = clampf(1.0 + 0.5 * TraitCatalog.npc_tendency(v, "sociability"), 0.3, 2.0)
		weights.append(w)
		total += w
	var r: float = randf() * total
	for i in range(eligible.size()):
		r -= weights[i]
		if r <= 0.0:
			return eligible[i]
	return eligible[eligible.size() - 1]

static func _update_social_hangouts(vm: VillageManager, delta: float) -> void:
	if vm.social_director == null or not vm.is_inside_tree():
		return
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var cur_day: int = int(WorldClock.current_day) if WorldClock != null else 1
	var cur_hour: int = int(WorldClock.current_hour) if WorldClock != null else 12

	# 1. Seguimiento de quedadas activas: llegadas y cancelaciones si alguien deja de estar disponible
	for hg in vm.social_director.active_hangouts.duplicate():
		var h_id: int = int(hg.get("id", -1))
		var a: VillageNPC = by_key.get(str(hg.get("actor_a_id", "")), null)
		var b: VillageNPC = by_key.get(str(hg.get("actor_b_id", "")), null)
		var broken: bool = false
		for v in [a, b]:
			if not is_instance_valid(v) or v.is_dead or v.is_downed or v.is_hostile or v.is_sleeping or v.hangout_id != h_id or v.current_activity != VillageNPC.ActivityState.SOCIALIZING:
				broken = true
		if broken:
			vm.social_director.cancel_hangout(h_id, "interrupted")
			continue
		if a.is_at_hangout_spot(vm.HANGOUT_ARRIVAL_RADIUS):
			vm.social_director.mark_hangout_arrival(h_id, a.get_person_key())
		if b.is_at_hangout_spot(vm.HANGOUT_ARRIVAL_RADIUS):
			vm.social_director.mark_hangout_arrival(h_id, b.get_person_key())

	# 2. Resultados de quedadas terminadas: bono suave de relación y humor, o liberar a los participantes
	for res in vm.social_director.pop_finished_hangouts():
		var ra: VillageNPC = by_key.get(str(res.get("actor_a_id", "")), null)
		var rb: VillageNPC = by_key.get(str(res.get("actor_b_id", "")), null)
		var res_id: int = int(res.get("id", -1))
		for v2 in [ra, rb]:
			if is_instance_valid(v2) and v2.hangout_id == res_id:
				v2.clear_hangout()
		if bool(res.get("success", false)) and is_instance_valid(ra) and is_instance_valid(rb) and not ra.is_dead and not rb.is_dead:
			var d_aff: int = int(res.get("delta_affinity", 3))
			var st_done: String = vm.social_director.get_pair_stage(ra.get_person_key(), rb.get_person_key())
			var spot_lbl: String = vm._spot_label_for(str(res.get("spot_id", ""))) if str(res.get("spot_id", "")) != "" else "el pueblo"
			if st_done == "couple" or (ra.person_profile != null and str(ra.person_profile.partner_id) == rb.get_person_key()):
				ra.modify_npc_relationship(rb, d_aff + 2, "💑 Pasaron la tarde juntos en pareja")
				ra.add_thought("Pasé una tarde preciosa con %s (+10)" % rb.npc_name, 10.0)
				rb.add_thought("Pasé una tarde preciosa con %s (+10)" % ra.npc_name, 10.0)
				ra.need_social = minf(100.0, ra.need_social + 26.0)
				rb.need_social = minf(100.0, rb.need_social + 26.0)
				ra._spawn_floating_text("💑✨ Tarde en pareja con %s (+%d)" % [rb.npc_name, d_aff + 2], Color(1.0, 0.62, 0.80), -40.0)
				vm.record_social_event("date", ra, rb, "%s y %s pasaron la tarde juntos como pareja en %s" % [ra.npc_name, rb.npc_name, spot_lbl])
			elif st_done in ["dating", "flirt"]:
				ra.modify_npc_relationship(rb, d_aff + 1, "💞 Tuvieron una cita juntos")
				ra.add_thought("Disfruté mucho de mi cita con %s (+8)" % rb.npc_name, 8.0)
				rb.add_thought("Disfruté mucho de mi cita con %s (+8)" % ra.npc_name, 8.0)
				ra.need_social = minf(100.0, ra.need_social + 24.0)
				rb.need_social = minf(100.0, rb.need_social + 24.0)
				ra._spawn_floating_text("💞✨ Cita con %s (+%d)" % [rb.npc_name, d_aff + 1], Color(1.0, 0.70, 0.88), -40.0)
				vm.record_social_event("date", ra, rb, "%s y %s tuvieron una cita en %s" % [ra.npc_name, rb.npc_name, spot_lbl])
			else:
				ra.modify_npc_relationship(rb, d_aff, "Pasaron un buen rato juntos")
				ra.add_thought("Pasé un buen rato con %s (+6)" % rb.npc_name, 6.0)
				rb.add_thought("Pasé un buen rato con %s (+6)" % ra.npc_name, 6.0)
				ra.need_social = minf(100.0, ra.need_social + 20.0)
				rb.need_social = minf(100.0, rb.need_social + 20.0)
				ra._spawn_floating_text("☕🤝 Buen rato con %s (+%d)" % [rb.npc_name, d_aff], Color(0.70, 1.0, 0.80), -40.0)
				vm.record_social_event("hangout", ra, rb, "%s y %s pasaron un rato juntos en %s" % [ra.npc_name, rb.npc_name, spot_lbl])
			VillageSecrets.on_meeting(vm, ra, rb) # S2: si son amantes, alguien puede pillarlos
			# B3.3: Comprobar si quedar con un tercero despierta celos en alguna pareja actual
			if st_done != "couple" and (ra.person_profile == null or str(ra.person_profile.partner_id) != rb.get_person_key()):
				var profs_j: Dictionary = {}
				var fams_j: Dictionary = {}
				for kj in by_key.keys():
					var vj: VillageNPC = by_key[kj]
					if vj.person_profile != null and not vj.is_dead:
						profs_j[kj] = vj.person_profile
						fams_j[kj] = vj.family_id
				for jev in vm.social_director.trigger_jealousy_if_any(ra.get_person_key(), rb.get_person_key(), profs_j, fams_j, cur_day):
					var jp: VillageNPC = by_key.get(str(jev.get("partner_id", "")), null)
					var jc: VillageNPC = by_key.get(str(jev.get("cheater_id", "")), null)
					var jr: VillageNPC = by_key.get(str(jev.get("rival_id", "")), null)
					if is_instance_valid(jp) and is_instance_valid(jc) and is_instance_valid(jr):
						jp.modify_npc_relationship(jc, -8, "💢💔 Celos por pasar tiempo a solas con %s" % jr.npc_name, true)
						jp.modify_npc_relationship(jr, -8, "💢 Rival de celos por %s" % jc.npc_name, true)
						jp.add_thought("No me gustó ver a %s tan cerca de %s (-8)" % [jc.npc_name, jr.npc_name], -8.0)
						jp._spawn_floating_text("💢💔 ¡Celos de %s al ver a %s con %s!" % [jp.npc_name, jc.npc_name, jr.npc_name], Color(1.0, 0.42, 0.42), -44.0)
						vm.record_social_event("jealousy", jp, jc, "%s sintió celos al ver a %s con %s" % [jp.npc_name, jc.npc_name, jr.npc_name])

	# 3. Planificar nuevas quedadas cada pocos segundos en horario social
	vm._hangout_plan_timer -= delta
	if vm._hangout_plan_timer > 0.0:
		return
	vm._hangout_plan_timer = randf_range(5.0, 8.0)
	if not vm.social_director.is_social_hour(cur_hour):
		return
	# A las 22h se van a dormir: más tarde de las 20:15 no daría tiempo a llegar y pasar el rato
	if cur_hour == 20 and WorldClock != null and int(WorldClock.current_minute) > 15:
		return
	var eligible: Array[VillageNPC] = []
	for k in by_key.keys():
		var v3: VillageNPC = by_key[k]
		if _is_npc_eligible_for_hangout(vm, v3) and v3.hangout_id < 0:
			eligible.append(v3)
	if eligible.size() < 2:
		return
	var initiator: VillageNPC = pick_hangout_initiator(eligible)
	var cand_ids: Array = []
	var positions: Dictionary = {}
	for v4 in eligible:
		var key4: String = v4.get_person_key()
		positions[key4] = v4.global_position
		if v4 == initiator:
			continue
		cand_ids.append(key4)
		# Sincroniza la afinidad del par con la relación vecinal real (fuente de verdad en VillageNPC)
		var pe: Dictionary = vm.social_director.get_pair_entry(initiator.get_person_key(), key4, initiator.get_relationship_with_npc(key4))
		if not pe.is_empty():
			pe["affinity"] = initiator.get_relationship_with_npc(key4)
	cand_ids = VillageSecrets.bias_hangout_candidates(vm, initiator, cand_ids) # S1: el infiel busca al amante
	var hg_new: Dictionary = vm.social_director.try_plan_hangout(initiator.get_person_key(), cand_ids, positions, vm.get_hangout_spots(), cur_hour, cur_day)
	if hg_new.is_empty():
		return
	var pa: VillageNPC = by_key.get(str(hg_new.get("actor_a_id", "")), null)
	var pb: VillageNPC = by_key.get(str(hg_new.get("actor_b_id", "")), null)
	if not is_instance_valid(pa) or not is_instance_valid(pb):
		vm.social_director.cancel_hangout(int(hg_new.get("id", -1)), "missing_actor")
		return
	# U4: si el invitado no aprecia a quien le invita tanto como al revés, puede poner una excusa
	var invitee: VillageNPC = pb if pa == initiator else pa
	if try_hangout_excuse(vm, initiator, invitee, randf()):
		vm.social_director.cancel_hangout(int(hg_new.get("id", -1)), "excuse")
		return
	var lbl: String = vm._spot_label_for(str(hg_new.get("spot_id", "")))
	var sp_pos: Vector2 = hg_new.get("spot_pos", pa.global_position)
	pa.assign_hangout(int(hg_new["id"]), sp_pos, pb, -1, lbl)
	pb.assign_hangout(int(hg_new["id"]), sp_pos, pa, 1, lbl)
	var st_inv: String = vm.social_director.get_pair_stage(pa.get_person_key(), pb.get_person_key())
	if st_inv == "couple" or (pa.person_profile != null and str(pa.person_profile.partner_id) == pb.get_person_key()):
		pa._spawn_floating_text("💑 «%s, ¿pasamos la tarde juntos en %s?»" % [pb.npc_name, lbl], Color(1.0, 0.65, 0.82), -36.0)
	elif st_inv in ["dating", "flirt"]:
		pa._spawn_floating_text("💞 «%s, ¿vamos un rato a %s?»" % [pb.npc_name, lbl], Color(1.0, 0.72, 0.88), -36.0)
	else:
		pa._spawn_floating_text("☕ «%s, ¿nos vemos en %s?»" % [pb.npc_name, lbl], Color(0.85, 0.95, 1.0), -36.0)

static func _get_live_gossip(vm: VillageManager) -> Array[Dictionary]:
	var today: int = int(WorldClock.current_day) if WorldClock != null else 1
	var res: Array[Dictionary] = []
	for i in range(vm.social_event_log.size() - 1, -1, -1):
		var ev: Dictionary = vm.social_event_log[i]
		if ev.has("known_by") and today - int(ev.get("day", 0)) <= vm.GOSSIP_MAX_AGE_DAYS:
			res.append(ev)
	return res

## B6.1: `teller` cuenta a `listener` la novedad más reciente que este aún no sabe. Si era lo que dijiste de él, le cae mal saberlo.
static func spread_gossip(vm: VillageManager, teller: VillageNPC, listener: VillageNPC) -> Dictionary:
	var teller_key: String = teller.get_person_key()
	var listener_key: String = listener.get_person_key()
	for ev in _get_live_gossip(vm):
		var known: Dictionary = ev["known_by"]
		# R1: solo cuenta lo que aún recuerda; a quien lo olvidó se le puede volver a contar
		if GossipMemory.knows(ev, teller_key) and not GossipMemory.knows(ev, listener_key) and not VillageSecrets.keeps_quiet(ev, teller_key):
			known[listener_key] = true
			if not ev.has("heard_from"):
				ev["heard_from"] = {}
			ev["heard_from"][listener_key] = teller_key
			var ev_type: String = str(ev.get("type", ""))
			if ev_type in ["player_slander", "npc_slander"] and str(ev.get("target_id", "")) == listener_key:
				_on_slander_reached_target(vm, ev, teller, listener)
			GossipMemory.on_told(vm, ev, teller, listener) # R2: puede llegar deformado
			VillageSecrets.on_heard(vm, ev, teller, listener) # S3: quien lo oye piensa peor del que cree culpable
			if not vm.is_demo_mode():
				VillageDesires.on_heard(vm, ev, teller, listener) # D: rumores de deseos y contra el jugador
			VillageChronicle.on_gossip(vm, ev, teller, listener)
			return ev
	return {}

## Q3: El calumniado se entera. Si se lo cuenta quien lo oyó directamente del autor, sabe quién fue;
## si le llega de segunda mano, no sabe quién lo empezó y puede pedir al jugador que lo averigüe.
static func _on_slander_reached_target(vm: VillageManager, ev: Dictionary, teller: VillageNPC, listener: VillageNPC) -> void:
	var by_player: bool = str(ev.get("type", "")) == "player_slander"
	var origin_key: String = "player" if by_player else str(ev.get("actor_id", ""))
	var teller_source: String = str((ev.get("heard_from", {}) as Dictionary).get(teller.get_person_key(), ""))
	var direct: bool = teller_source == origin_key or teller.get_person_key() == origin_key
	if not direct:
		listener._spawn_floating_text("😟 «¿Quién anda diciendo eso de mí?»", Color(1.0, 0.80, 0.55), -46.0)
		VillageQuests.on_rumor_reached_target(vm, ev, teller, listener)
		return
	if by_player:
		listener.modify_affinity(-5)
		listener._spawn_floating_text("😠 Se ha enterado de lo que dijiste de él/ella", Color.ORANGE, -46.0)
	else:
		var origin: VillageNPC = vm._get_npcs_by_person_key().get(origin_key, null)
		if origin != null:
			listener.modify_npc_relationship(origin, -6, "Se enteró de que %s hablaba mal de él/ella" % origin.npc_name, true)
			listener._spawn_floating_text("😠 Se ha enterado de lo que %s dice de él/ella" % origin.npc_name, Color.ORANGE, -46.0)

## T1: Probabilidad por charla de que `npc` hable mal de su peor rival, según la malicia de sus rasgos.
static func npc_slander_chance(npc: VillageNPC) -> float:
	return clampf(NPC_SLANDER_PER_MALICE * TraitCatalog.npc_tendency(npc, "malice"), 0.0, NPC_SLANDER_MAX_CHANCE)

## Q3: `speaker` habla mal de su peor rival delante de `listener` si lo detesta. `chance` < 0 = según su malicia.
static func try_npc_slander(vm: VillageManager, speaker: VillageNPC, listener: VillageNPC, chance: float = -1.0) -> Dictionary:
	if speaker.person_profile == null or vm.social_director == null:
		return {}
	var p: float = npc_slander_chance(speaker) if chance < 0.0 else chance
	if p <= 0.0 or vm.social_director.rng.randf() >= p:
		return {}
	var rival: VillageNPC = null
	var worst: int = NPC_SLANDER_REL + 1
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and n != speaker and n != listener and not n.is_dead:
			var r: int = speaker.get_relationship_with_npc((n as VillageNPC).get_person_key())
			if r < worst:
				worst = r
				rival = n
	if rival == null:
		return {}
	var ev: Dictionary = vm.record_social_event("npc_slander", speaker, rival, "%s va diciendo cosas feas de %s" % [speaker.npc_name, rival.npc_name])
	ev["known_by"][listener.get_person_key()] = true
	ev["heard_from"][listener.get_person_key()] = speaker.get_person_key()
	listener.modify_npc_relationship(rival, -3, "Lo que %s le contó de %s" % [speaker.npc_name, rival.npc_name], true)
	speaker._spawn_floating_text("🤫 «¿Sabes lo que dicen de %s...?»" % rival.npc_name, Color(0.95, 0.75, 1.0), -46.0)
	TraitDiscoveryRef.on_witnessed_behavior(speaker, "malice", "le has oído calumniar")
	return ev

## Texto del chisme tal como se cuenta. Las calumnias no dicen quién las empezó (eso se averigua siguiendo la cadena).
## R2: `ver_key` = de quién es la versión que se cuenta ("" = la verdad).
static func gossip_text(ev: Dictionary, listener: VillageNPC = null, ver_key: String = "") -> String:
	if str(ev.get("type", "")) in ["player_slander", "npc_slander"]:
		var believed: String = GossipMemory.render(ev, str(ev.get("target_name", "alguien")), ver_key, false, true)
		if listener != null and listener.npc_name == believed:
			return GossipMemory.render(ev, "Andan diciendo cosas feas de ti.", ver_key, true, false)
		return GossipMemory.render(ev, "Andan diciendo cosas feas de %s." % str(ev.get("target_name", "alguien")), ver_key)
	return GossipMemory.render(ev, str(ev.get("summary", "")), ver_key)

static func get_news_known_by(vm: VillageManager, npc: VillageNPC, limit: int = 3) -> Array[Dictionary]:
	var key: String = npc.get_person_key()
	var res: Array[Dictionary] = []
	for ev in _get_live_gossip(vm):
		if res.size() < limit and GossipMemory.knows(ev, key):
			res.append(ev)
	return res

## B6.2: Noticias públicas: lo que ya corre de boca en boca, sin los comentarios del jugador.
static func get_public_news(vm: VillageManager, limit: int = 4) -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	for ev in _get_live_gossip(vm):
		if res.size() < limit and not str(ev.get("type", "")) in ["player_slander", "npc_slander"] and (ev["known_by"] as Dictionary).size() >= vm.NEWS_MIN_KNOWERS:
			res.append(ev)
	return res


## U2: reciprocidad lenta del aprecio. Cada día, quien siente bastante menos que el otro se acerca un 5 % de la
## diferencia (1 o 2 puntos): a uno le acaba cayendo mejor quien le aprecia, y peor quien le desprecia, sin igualarse del todo.
const RECIPROCITY_MIN_GAP: int = 20 # U7: por debajo no se corrige (deja sitio a cariños desiguales)
static func daily_reciprocity(vm: VillageManager) -> void:
	var npcs: Array = []
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and not n.is_dead:
			npcs.append(n)
	for i in range(npcs.size()):
		for j in range(i + 1, npcs.size()):
			var a: VillageNPC = npcs[i]
			var b: VillageNPC = npcs[j]
			var ra: int = a.get_relationship_with_npc(b.get_person_key())
			var rb: int = b.get_relationship_with_npc(a.get_person_key())
			var gap: int = ra - rb
			if absi(gap) < RECIPROCITY_MIN_GAP:
				continue
			var step: int = clampi(int(round(float(gap) * 0.05)), -2, 2)
			if step == 0:
				step = 1 if gap > 0 else -1
			b.modify_npc_relationship(a, step, "", true)


## U3: `from` se ha declarado a `to` y le ha dicho que no. Duele al que se declara y deja algo de incomodidad al otro.
static func on_rejection(vm: VillageManager, from: VillageNPC, to: VillageNPC) -> void:
	if not is_instance_valid(from) or not is_instance_valid(to) or from.is_dead or to.is_dead:
		return
	from.modify_npc_relationship(to, -5, "💔 Le dijo que no cuando se le declaró", true)
	to.modify_npc_relationship(from, -2, "Se le declaró y no siente lo mismo", true)
	from.add_thought("%s no siente lo mismo por mí (-10)" % to.npc_name, -10.0)
	from._spawn_floating_text("💔 %s se ha declarado a %s... y le ha dicho que no" % [from.npc_name, to.npc_name], Color(0.80, 0.70, 1.0), -46.0)
	vm.record_social_event("rejection", from, to, "%s se declaró a %s y le dijo que no" % [from.npc_name, to.npc_name])

## U3: quien estaba ilusionado con alguien que acaba de emparejarse siente celos de su nueva pareja.
const JEALOUSY_MIN_SPARK: int = 28
static func on_new_couple_jealousy(vm: VillageManager, a: VillageNPC, b: VillageNPC) -> void:
	var sd = vm.social_director
	if sd == null or not is_instance_valid(a) or not is_instance_valid(b):
		return
	for x in vm.get_tree().get_nodes_in_group("village_npcs"):
		if not (x is VillageNPC) or x == a or x == b or x.is_dead:
			continue
		for pair in [[a, b], [b, a]]:
			var loved: VillageNPC = pair[0]
			var rival: VillageNPC = pair[1]
			if sd.get_spark(x.get_person_key(), loved.get_person_key()) >= JEALOUSY_MIN_SPARK:
				x.modify_npc_relationship(rival, -10, "💢💔 Celos: está con %s" % loved.npc_name, true)
				x.add_thought("%s está con %s... (-8)" % [loved.npc_name, rival.npc_name], -8.0)
				vm.record_social_event("jealousy", x, rival, "%s tiene celos de %s por %s" % [x.npc_name, rival.npc_name, loved.npc_name])


## U4: amistad desigual. Quien invita aprecia bastante al otro (≥ 35) pero el invitado apenas a él (< 15):
## con `EXCUSE_CHANCE` pone una excusa y no van. No pasa entre parejas ni en pleno cortejo.
const EXCUSE_INVITER_MIN: int = 35
const EXCUSE_INVITEE_MAX: int = 15
const EXCUSE_CHANCE: float = 0.7
static func try_hangout_excuse(vm: VillageManager, inviter: VillageNPC, invitee: VillageNPC, roll: float) -> bool:
	if not is_instance_valid(inviter) or not is_instance_valid(invitee) or roll >= EXCUSE_CHANCE:
		return false
	var st: String = vm.social_director.get_pair_stage(inviter.get_person_key(), invitee.get_person_key()) if vm.social_director != null else "none"
	if st in ["couple", "dating", "flirt"]:
		return false
	if inviter.get_relationship_with_npc(invitee.get_person_key()) < EXCUSE_INVITER_MIN or invitee.get_relationship_with_npc(inviter.get_person_key()) >= EXCUSE_INVITEE_MAX:
		return false
	invitee._spawn_floating_text("🙄 «Hoy no me viene bien, %s...»" % inviter.npc_name, Color(0.85, 0.85, 0.75), -36.0)
	inviter.add_thought("%s siempre me pone excusas (-3)" % invitee.npc_name, -3.0)
	inviter.modify_npc_relationship(invitee, -1, "", true)
	return true

## U4/U5: cómo describe un vecino lo que siente él por `other` (de un solo lado, con el género de `other`).
static func feeling_phrase(rel: int, other: VillageNPC) -> String:
	var fem: bool = other != null and other.person_profile != null and str(other.person_profile.gender) == "F"
	if rel >= 65: return "es mi mejor amiga" if fem else "es mi mejor amigo"
	if rel >= 35: return "es una buena amiga" if fem else "es un buen amigo"
	if rel >= 12: return "me cae bien"
	if rel > -12: return "ni fu ni fa"
	if rel > -30: return "no me termina de caer bien"
	if rel > -60: return "me cae mal"
	return "no la soporto" if fem else "no lo soporto"


## U6: enfriamiento por distancia. Si dos vecinos llevan más de `COOL_AFTER_DAYS` sin cruzarse, lo que siente cada uno
## (bueno o malo) se acerca un `COOL_RATE` al día a neutro (en proporción, así no se borran las diferencias entre los dos),
## sin bajar de ±`COOL_FLOOR`. No afecta a parejas ni familia.
const COOL_RATE: float = 0.03
const COOL_AFTER_DAYS: int = 7
const COOL_FLOOR: int = 10
static func daily_distance_cooling(vm: VillageManager, current_day: int) -> void:
	var sd = vm.social_director
	if sd == null:
		return
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for k in sd.pair_metrics.keys():
		var pe: Dictionary = sd.pair_metrics[k]
		if str(pe.get("stage", "none")) == "couple" or int(pe.get("last_contact_day", current_day)) >= current_day - COOL_AFTER_DAYS:
			continue
		var ids: PackedStringArray = str(k).split("|")
		if ids.size() != 2:
			continue
		var a: VillageNPC = by_key.get(ids[0], null)
		var b: VillageNPC = by_key.get(ids[1], null)
		if a == null or b == null or a.is_dead or b.is_dead:
			continue
		if a.family_id != "none" and a.family_id != "" and a.family_id != "family_police" and a.family_id == b.family_id:
			continue
		for side in [[a, b], [b, a]]:
			var r: int = (side[0] as VillageNPC).get_relationship_with_npc((side[1] as VillageNPC).get_person_key())
			var step: int = int(round(float(absi(r)) * COOL_RATE))
			if absi(r) > COOL_FLOOR and step > 0:
				(side[0] as VillageNPC).modify_npc_relationship(side[1], -step if r > 0 else step, "", true)
