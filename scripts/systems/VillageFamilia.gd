@tool
extends RefCounted

## Bloque R2 (crimen interno discreto, 2026-11-06): «La Familia».
## - Nace sola (nunca al empezar): un vecino adulto ambicioso, sin escrúpulos y persuasivo decide montarla cuando
##   tiene dinero ahorrado y un motivo (deudas, envidia, rencor) o una oportunidad. Si no hay nadie así, no nace.
## - Recluta de 2 a 4 vecinos de uno en uno entre quienes le deben algo, le tienen afecto o miedo, o están
##   desesperados (pobres, endeudados). Puede fallar: quien se niega lo recuerda y puede contarlo como chisme.
## - Se reúnen de noche en el reservado de la Trattoria «Il Corvo» (`VillageRestaurant.BACKROOM_TABLE`, sala
##   `"reservado"`) cuando el jefe lo decide según sus planes (sin calendario fijo). Si ven a la guardia o a un
##   desconocido cerca, lo dejan para otra noche.
## - Perfil bajo: de día siguen con sus oficios normales.
## - Guardar y cargar: jefe, miembros y rechazos viven en `VillageNeeds.state(vm)["familia"]`.
## Sin `class_name`: se carga con `preload`.

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageRestaurant = preload("res://scripts/systems/VillageRestaurant.gd")
const VillageLoans = preload("res://scripts/systems/VillageLoans.gd")
const VillageUnderworld = preload("res://scripts/systems/VillageUnderworld.gd")
const VillageDesires = preload("res://scripts/systems/VillageDesires.gd")

const MIN_AGE: int = 18
const MIN_BOSS_GOLD: int = 45
const OPPORTUNITY_GOLD: int = 75
const MIN_AMBITION: float = 0.8
const MIN_UNSCRUPULOUS: float = 0.7
const MIN_PERSUASION: float = 0.45

const MIN_RECRUITS: int = 2
const MAX_RECRUITS: int = 4

const MEET_CALL_HOURS: Array[int] = [22, 23, 0, 1]
const MEET_END_HOUR: int = 2
const GUARD_NEAR_PX: float = 180.0
const STRANGER_NEAR_PX: float = 75.0
const SEAT_RADIUS_X: float = 14.0
const SEAT_RADIUS_Y: float = 10.0

## Frases provisionales del cocinero cuando le preguntas por el reservado (anotadas en docs/APORTES_CREATIVOS.md).
const COOK_LINE_MEETING: String = "«Chist... baje la voz. Esta noche hay gente cenando a puerta cerrada en el reservado del fondo. Yo llevo las fuentes, dejo el vino y miro al suelo. En esta cocina el que no pregunta llega a viejo.»"
const COOK_LINE_ACTIVE: String = "«¿La mesa del reservado? Hay clientes que prefieren cenar tarde con la puerta cerrada y sin que nadie apunte sus nombres. Pagan al contado, no arman ruido y yo no pregunto de qué hablan.»"
const COOK_LINE_QUIET: String = "«El reservado del fondo está tranquilo últimamente. Sólo se abre cuando alguien quiere hablar de negocios lejos de los curiosos.»"

static func state(vm) -> Dictionary:
	var ns: Dictionary = VillageNeeds.state(vm)
	if not (ns.get("familia", null) is Dictionary):
		ns["familia"] = {}
	var st: Dictionary = ns["familia"]
	for pair in [
		["boss", ""],
		["boss_name", ""],
		["members", {}],
		["refusals", {}],
		["founded_day", -1],
		["target_recruits", 3],
		["next_plan_night", -99],
		["last_meeting_day", -99],
		["meeting_night", -99],
		["meeting_status", ""],
		["attending", []],
		["postponed", false],
		["meetings_held", 0],
		["aborted_nights", 0],
	]:
		if not st.has(pair[0]):
			st[pair[0]] = pair[1]
	return st

static func active(vm) -> bool:
	return vm != null and str(state(vm).get("boss", "")) != ""

static func boss_of(vm):
	if not active(vm):
		return null
	var b = vm._get_npcs_by_person_key().get(str(state(vm)["boss"]), null)
	return b if b != null and is_instance_valid(b) and not b.is_dead else null

static func is_member(vm, npc) -> bool:
	if vm == null or npc == null:
		return false
	return (state(vm)["members"] as Dictionary).has(npc.get_person_key())

static func has_refused(vm, npc) -> bool:
	if vm == null or npc == null:
		return false
	return (state(vm)["refusals"] as Dictionary).has(npc.get_person_key())

static func member_nodes(vm) -> Array:
	var out: Array = []
	if vm == null:
		return out
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for k in (state(vm)["members"] as Dictionary).keys():
		var n = by_key.get(str(k), null)
		if n != null and is_instance_valid(n) and not n.is_dead:
			out.append(n)
	return out

static func recruits_count(vm) -> int:
	if not active(vm):
		return 0
	var b_key: String = str(state(vm)["boss"])
	var c: int = 0
	for k in (state(vm)["members"] as Dictionary).keys():
		if str(k) != b_key:
			c += 1
	return c

static func _has(npc, trait_name: String) -> bool:
	return npc != null and npc.person_profile != null and (trait_name in npc.person_profile.personality)

static func _protected_role(npc) -> bool:
	return int(npc.trade_role) in [
		int(VillageNPC.TradeRole.SHERIFF),
		int(VillageNPC.TradeRole.GUARD),
		int(VillageNPC.TradeRole.PRIEST),
		int(VillageNPC.TradeRole.ROYAL_INVESTIGATOR),
		int(VillageNPC.TradeRole.TRAVELING_MERCHANT),
		int(VillageNPC.TradeRole.CHILD),
	]

static func _can_be_member(npc) -> bool:
	if npc == null or not is_instance_valid(npc) or npc.is_dead or npc.person_profile == null:
		return false
	if VillageNeeds.is_outsider(npc) or _protected_role(npc):
		return false
	return int(npc.person_profile.age) >= MIN_AGE

# ------------------------------------------------------------------ 1. Nacimiento
static func is_ambitious(npc) -> bool:
	if npc == null:
		return false
	return TraitCatalog.npc_tendency(npc, "ambition") >= MIN_AMBITION or _has(npc, "Ambicioso") or _has(npc, "Sediento de poder")

static func unscrupulous_score(npc) -> float:
	if npc == null:
		return 0.0
	return TraitCatalog.npc_tendency(npc, "malice") - TraitCatalog.npc_tendency(npc, "honesty") - 0.5 * TraitCatalog.npc_tendency(npc, "law")

static func is_unscrupulous(npc) -> bool:
	if npc == null or _has(npc, "Honrado") or _has(npc, "Íntegro"):
		return false
	return TraitCatalog.npc_tendency(npc, "honesty") < 0.0 and unscrupulous_score(npc) >= MIN_UNSCRUPULOUS

static func persuasion(vm, npc) -> float:
	if npc == null:
		return 0.0
	var p: float = 0.6 * maxf(0.0, TraitCatalog.npc_tendency(npc, "leadership"))
	p += 0.35 * maxf(0.0, TraitCatalog.npc_tendency(npc, "sociability"))
	p += 0.25 * maxf(0.0, TraitCatalog.npc_tendency(npc, "wit"))
	p += 0.25 * maxf(0.0, TraitCatalog.npc_tendency(npc, "trade"))
	if _has(npc, "Manipulador"):
		p += 0.50
	if _has(npc, "Líder"):
		p += 0.45
	if _has(npc, "Negociante"):
		p += 0.35
	if _has(npc, "Chantajista") or _has(npc, "Astuto"):
		p += 0.30
	if _has(npc, "Sumiso"):
		p -= 0.50
	if vm != null:
		var tot: int = 0
		var cnt: int = 0
		for o in VillageNeeds.living(vm):
			if o != npc and not VillageNeeds.is_outsider(o):
				tot += o.get_relationship_with_npc(npc.get_person_key())
				cnt += 1
		p += float(tot) / float(maxi(1, cnt)) / 250.0
	return p

static func is_persuasive(vm, npc) -> bool:
	return persuasion(vm, npc) >= MIN_PERSUASION

static func can_be_boss(vm, npc) -> bool:
	return _can_be_member(npc) and is_ambitious(npc) and is_unscrupulous(npc) and is_persuasive(vm, npc)

static func has_debt(vm, npc) -> bool:
	if vm == null or npc == null:
		return false
	if VillageLoans.debt_text(vm, npc) != "":
		return true
	var uw_loans: Dictionary = VillageUnderworld.state(vm).get("loans", {}) if VillageUnderworld.state(vm).get("loans", {}) is Dictionary else {}
	return uw_loans.has(npc.get_person_key())

static func _count_vulnerable(vm, exclude_npc) -> int:
	var c: int = 0
	for n in VillageNeeds.living(vm):
		if n == exclude_npc or not _can_be_member(n):
			continue
		if VillageNeeds.class_of(n) in ["pobre", "mendigo"] or has_debt(vm, n):
			c += 1
	return c

## Motivo para fundarla: dinero ahorrado + frustración (deudas, envidia, rencor) o una oportunidad.
static func has_boss_motive(vm, npc) -> bool:
	if vm == null or npc == null or int(npc.personal_gold) < MIN_BOSS_GOLD:
		return false
	if has_debt(vm, npc):
		return true
	var d_type: String = str(VillageDesires.active_of(vm, npc.get_person_key()).get("type", ""))
	if d_type in ["ambition", "revenge"]:
		return true
	if _has(npc, "Envidioso") or _has(npc, "Rencoroso") or _has(npc, "Vengativo") or TraitCatalog.npc_tendency(npc, "grudge") >= 0.4:
		return true
	for o in VillageNeeds.living(vm):
		if o == npc or VillageNeeds.is_outsider(o):
			continue
		if npc.get_relationship_with_npc(o.get_person_key()) <= -25:
			return true
		if (_has(npc, "Codicioso") or TraitCatalog.npc_tendency(npc, "ambition") >= 1.0) and int(o.personal_gold) >= int(npc.personal_gold) + 50:
			return true
	if int(npc.personal_gold) >= OPPORTUNITY_GOLD and _count_vulnerable(vm, npc) >= 2:
		return true
	return false

static func boss_score(vm, npc) -> float:
	if not can_be_boss(vm, npc) or not has_boss_motive(vm, npc):
		return 0.0
	return TraitCatalog.npc_tendency(npc, "ambition") + unscrupulous_score(npc) + persuasion(vm, npc)

static func try_found(vm) -> bool:
	if vm == null or active(vm):
		return false
	var best = null
	var best_s: float = 0.0
	for n in VillageNeeds.living(vm):
		var s: float = boss_score(vm, n)
		if s > best_s:
			best_s = s
			best = n
	if best == null:
		return false
	return found(vm, best)

static func found(vm, boss) -> bool:
	if vm == null or boss == null or not _can_be_member(boss):
		return false
	var st: Dictionary = state(vm)
	var d: int = VillageNeeds.today()
	var b_key: String = boss.get_person_key()
	st["boss"] = b_key
	st["boss_name"] = boss.npc_name
	st["members"] = {b_key: d}
	st["founded_day"] = d
	st["target_recruits"] = clampi(2 + int(round(TraitCatalog.npc_tendency(boss, "ambition"))), MIN_RECRUITS, MAX_RECRUITS)
	st["next_plan_night"] = -99
	st["meeting_status"] = ""
	st["attending"] = []
	boss.add_thought("Es hora de mover los hilos del valle sin hacer ruido (+5)", 5.0)
	VillageChronicle.add(vm, "familia_found", "%s empezó a tejer en secreto su propia Familia en el pueblo" % boss.npc_name, false)
	_update_band(vm)
	return true

# ------------------------------------------------------------------ 2. Reclutamiento (2 a 4, de uno en uno)
static func _owes_to(vm, target, boss) -> bool:
	var b_key: String = boss.get_person_key()
	if target.has_meta("owes_to") and str(target.get_meta("owes_to")) == b_key:
		return true
	var note: String = str(target.npc_relationship_notes.get(b_key, "")).to_lower()
	for kw in ["deuda", "debo", "prest", "limosna", "salv", "favor", "ayud"]:
		if note.contains(kw):
			return true
	for l in vm.VillageLots.LOTS:
		var lst: Dictionary = vm.VillageLots.lot(vm, str(l["id"]))
		if lst.has("loan") and str(lst.get("payer", "")) == target.get_person_key():
			if str((lst["loan"] as Dictionary).get("lender", "")) == b_key:
				return true
	return false

static func fears_boss(_vm, boss, target) -> bool:
	var boss_menace: float = TraitCatalog.npc_tendency(boss, "aggression") + 0.7 * maxf(0.0, TraitCatalog.npc_tendency(boss, "malice"))
	if boss_menace < 0.45:
		return false
	if _has(target, "Cobarde") or _has(target, "Sumiso") or TraitCatalog.npc_tendency(target, "courage") <= -0.3:
		return true
	return target.get_relationship_with_npc(boss.get_person_key()) <= -15 and TraitCatalog.npc_tendency(target, "courage") < boss_menace

## Motivo por el que el jefe se fija en `target`: "deuda", "miedo", "desesperado" o "afecto" ("" si no hay ninguno).
static func recruit_motive(vm, boss, target) -> String:
	if vm == null or boss == null or target == null or boss == target:
		return ""
	if not _can_be_member(target) or is_member(vm, target) or has_refused(vm, target):
		return ""
	if _owes_to(vm, target, boss):
		return "deuda"
	if fears_boss(vm, boss, target):
		return "miedo"
	if VillageNeeds.class_of(target) in ["pobre", "mendigo"] or has_debt(vm, target):
		return "desesperado"
	if target.get_relationship_with_npc(boss.get_person_key()) >= 30 or (boss.person_profile != null and str(boss.person_profile.partner_id) == target.get_person_key()):
		return "afecto"
	return ""

static func recruit_resistance(target) -> float:
	var r: float = 0.0
	if _has(target, "Íntegro") or _has(target, "Honrado"):
		r += 0.55
	if _has(target, "Cumplidor") or _has(target, "Justiciero"):
		r += 0.25
	r += 0.35 * maxf(0.0, TraitCatalog.npc_tendency(target, "honesty"))
	r += 0.30 * maxf(0.0, TraitCatalog.npc_tendency(target, "law"))
	if _has(target, "Codicioso") or _has(target, "Sobornable") or _has(target, "Delincuente") or _has(target, "Sumiso"):
		r -= 0.25
	return r

static func recruit_chance(vm, boss, target) -> float:
	var mot: String = recruit_motive(vm, boss, target)
	if mot == "":
		return 0.0
	var base: float = 0.48 if mot in ["deuda", "desesperado"] else 0.42
	if _owes_to(vm, target, boss) and (VillageNeeds.class_of(target) in ["pobre", "mendigo"] or has_debt(vm, target)):
		base += 0.12
	base += 0.25 * maxf(0.0, persuasion(vm, boss))
	base += float(maxi(0, target.get_relationship_with_npc(boss.get_person_key()))) / 250.0
	var c: float = base - recruit_resistance(target)
	return clampf(c, 0.05, 0.92)

## Intenta captar a un vecino (de uno en uno). Devuelve "joined", "refused" o "".
## `force_roll` (>= 0) permite fijar el dado en pruebas sin depender del azar.
static func try_recruit(vm, target = null, force_roll: float = -1.0) -> String:
	if not active(vm):
		return ""
	var st: Dictionary = state(vm)
	var limit: int = clampi(int(st.get("target_recruits", 3)), MIN_RECRUITS, MAX_RECRUITS)
	if recruits_count(vm) >= limit:
		return ""
	var boss = boss_of(vm)
	if boss == null:
		return ""
	if target == null:
		var best_c: float = 0.0
		for n in VillageNeeds.living(vm):
			var c: float = recruit_chance(vm, boss, n)
			if c > best_c:
				best_c = c
				target = n
	if target == null:
		return ""
	var mot: String = recruit_motive(vm, boss, target)
	if mot == "":
		return ""
	var chance: float = recruit_chance(vm, boss, target)
	var roll: float = force_roll if force_roll >= 0.0 else randf()
	if roll < chance:
		join(vm, target, boss, mot)
		return "joined"
	var today: int = VillageNeeds.today()
	(st["refusals"] as Dictionary)[target.get_person_key()] = {
		"by": boss.get_person_key(),
		"by_name": boss.npc_name,
		"day": today,
		"motive": mot,
	}
	target.add_thought("%s intentó meterme en sus negocios turbios (-6)" % boss.npc_name, -6.0)
	target.modify_npc_relationship(boss, -8, "Intentó meterme en negocios turbios", true)
	boss.modify_npc_relationship(target, -5, "Se negó a entrar en la Familia", true)
	# Quien se niega lo recuerda y, si no es discreto, puede contarlo como chisme
	if not _has(target, "Discreto"):
		var ev: Dictionary = vm.record_social_event(
			"familia_rumor",
			boss,
			target,
			"%s tanteó en voz baja a %s para meterlo en negocios turbios en el reservado" % [boss.npc_name, target.npc_name]
		)
		ev["quiet"] = [boss.get_person_key()]
	return "refused"

static func join(vm, npc, boss = null, motive: String = "") -> void:
	if vm == null or npc == null:
		return
	var st: Dictionary = state(vm)
	var today: int = VillageNeeds.today()
	(st["members"] as Dictionary)[npc.get_person_key()] = today
	npc.add_thought("Ahora cuento con el respaldo discreto de %s (+4)" % str(st.get("boss_name", "la Familia")), 4.0)
	if boss != null and is_instance_valid(boss):
		npc.modify_npc_relationship(boss, 8, "Me dio un sitio en la Familia")
		boss.modify_npc_relationship(npc, 8, "Es de los nuestros en el reservado")
	VillageChronicle.add(
		vm,
		"familia_join",
		"%s entró en el círculo discreto de %s%s" % [npc.npc_name, str(st.get("boss_name", "")), (" (%s)" % motive) if motive != "" else ""],
		false
	)
	_update_band(vm)
	# Con un nuevo miembro (y al menos 2 en total), el jefe convoca reunión para esa noche
	if member_nodes(vm).size() >= 2:
		plan_meeting(vm, today)

static func _update_band(vm) -> void:
	if vm == null or not ("faith_bands" in vm):
		return
	var keep: Array = []
	for b in vm.faith_bands:
		if str(b.get("kind", "")) != "familia":
			keep.append(b)
	var keys: Array = []
	for n in member_nodes(vm):
		keys.append(n.get_person_key())
	if keys.size() >= 2:
		keep.append({
			"id": "familia",
			"kind": "familia",
			"name": "La Familia",
			"members": keys,
			"leader": str(state(vm).get("boss", "")),
			"hidden": true,
		})
	vm.faith_bands = keep

# ------------------------------------------------------------------ 3. Reuniones nocturnas en el reservado
static func seat_pos(i: int, total: int) -> Vector2:
	var a: float = TAU * float(i) / float(maxi(1, total)) - PI * 0.5
	return VillageRestaurant.BACKROOM_TABLE + Vector2(cos(a) * SEAT_RADIUS_X, sin(a) * SEAT_RADIUS_Y)

static func plan_meeting(vm, night: int = -1) -> void:
	if not active(vm):
		return
	var st: Dictionary = state(vm)
	st["next_plan_night"] = night if night >= 0 else VillageNeeds.today()

static func is_meeting_now(vm) -> bool:
	if not active(vm):
		return false
	return str(state(vm).get("meeting_status", "")) in ["gathering", "meeting"]

static func _can_attend(npc) -> bool:
	if npc == null or not is_instance_valid(npc) or npc.is_dead or npc.is_downed or npc.is_hostile or not npc.is_conscious():
		return false
	if npc.sick_level >= 2 or npc.is_in_live_fight() or npc.is_busy_with_player() or npc.rite_pos != Vector2.ZERO:
		return false
	return true

## Comprueba si hay un guardia cerca del restaurante/reservado o un desconocido pegado al reservado.
static func has_unwanted_witness_near(vm):
	if vm == null:
		return null
	var table: Vector2 = VillageRestaurant.BACKROOM_TABLE
	var rest_rect: Rect2 = VillageRestaurant.RECT.grow(70.0)
	var back_rect: Rect2 = (VillageRestaurant.ROOMS["reservado"] as Rect2).grow(40.0)
	for n in VillageNeeds.living(vm):
		if n.is_sleeping or n.is_incapacitated() or not n.is_conscious() or int(n.elevation_level) != 0:
			continue
		if int(n.trade_role) in [int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.ROYAL_INVESTIGATOR)]:
			if n.global_position.distance_to(table) <= GUARD_NEAR_PX or rest_rect.has_point(n.global_position):
				return n
			continue
		if is_member(vm, n) or int(n.trade_role) == int(VillageNPC.TradeRole.RESTAURATEUR):
			continue
		if back_rect.has_point(n.global_position) or n.global_position.distance_to(table) <= STRANGER_NEAR_PX:
			return n
	return null

## El jefe convoca a los miembros al reservado. Si hay un guardia o desconocido cerca, lo dejan para otra noche.
static func call_meeting(vm) -> bool:
	if not active(vm):
		return false
	var st: Dictionary = state(vm)
	var mems: Array = member_nodes(vm)
	if mems.size() < 2:
		return false
	var w = has_unwanted_witness_near(vm)
	if w != null:
		abort_meeting(vm, w)
		return false
	var avail: Array = []
	for m in mems:
		if _can_attend(m):
			avail.append(m)
	if avail.size() < 2:
		return false
	var keys: Array = []
	for i in range(avail.size()):
		var m = avail[i]
		keys.append(m.get_person_key())
		m.start_errand("familia_meet", seat_pos(i, avail.size()))
	st["attending"] = keys
	st["meeting_night"] = VillageNeeds.today()
	st["meeting_status"] = "gathering"
	st["postponed"] = false
	return true

## Cancela la reunión de esta noche y la deja para otra noche.
static func abort_meeting(vm, _witness = null) -> void:
	if vm == null:
		return
	var st: Dictionary = state(vm)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for k in (st.get("attending", []) as Array):
		var m = by_key.get(str(k), null)
		if m != null and is_instance_valid(m) and m.errand_kind == "familia_meet":
			m.end_errand()
	for m2 in member_nodes(vm):
		if m2.errand_kind == "familia_meet":
			m2.end_errand()
	st["attending"] = []
	st["meeting_status"] = "aborted"
	st["aborted_nights"] = int(st.get("aborted_nights", 0)) + 1
	st["postponed"] = true
	st["next_plan_night"] = VillageNeeds.today() + 1
	var boss = boss_of(vm)
	if boss != null:
		boss._spawn_floating_text("🍷 «Hay demasiados ojos cerca. Lo dejamos para otra noche.»", Color(0.9, 0.78, 0.65), -38.0)

static func finish_meeting(vm) -> void:
	if vm == null or not active(vm):
		return
	var st: Dictionary = state(vm)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var in_room: Array = []
	for k in (st.get("attending", []) as Array):
		var m = by_key.get(str(k), null)
		if m == null or not is_instance_valid(m) or m.is_dead:
			continue
		if VillageRestaurant.room_of(m.global_position) == "reservado" or m.global_position.distance_to(VillageRestaurant.BACKROOM_TABLE) <= 32.0:
			in_room.append(m)
		if m.errand_kind == "familia_meet":
			m.end_errand()
	for m2 in member_nodes(vm):
		if m2.errand_kind == "familia_meet":
			m2.end_errand()
	st["attending"] = []
	st["meeting_status"] = ""
	if in_room.size() >= 2:
		var today: int = VillageNeeds.today()
		st["meetings_held"] = int(st.get("meetings_held", 0)) + 1
		st["last_meeting_day"] = today
		st["postponed"] = false
		for i in range(in_room.size()):
			for j in range(i + 1, in_room.size()):
				in_room[i].modify_npc_relationship(in_room[j], 3, "Tratos discretos en el reservado")
				in_room[j].modify_npc_relationship(in_room[i], 3, "Tratos discretos en el reservado")
		var gap: int = 2 + (abs((str(st["boss"]) + "#" + str(st["meetings_held"])).hash()) % 3)
		st["next_plan_night"] = today + gap
		VillageChronicle.add(vm, "familia_meet", "La Familia de %s se reunió a puerta cerrada en el reservado de la trattoria" % str(st.get("boss_name", "")), false)

# ------------------------------------------------------------------ 4. Relojes y guardado
static func daily(vm) -> void:
	if vm == null:
		return
	var st: Dictionary = state(vm)
	var today: int = VillageNeeds.today()
	if not active(vm):
		try_found(vm)
		return
	# Limpiar bajas y comprobar si el jefe sigue vivo
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for k in (st["members"] as Dictionary).keys():
		var n = by_key.get(str(k), null)
		if n == null or not is_instance_valid(n) or n.is_dead:
			(st["members"] as Dictionary).erase(k)
	var boss = boss_of(vm)
	if boss == null:
		var heir = null
		var best_p: float = MIN_PERSUASION * 0.5
		for m in member_nodes(vm):
			if is_unscrupulous(m) and persuasion(vm, m) > best_p:
				best_p = persuasion(vm, m)
				heir = m
		if heir == null:
			st["boss"] = ""
			st["boss_name"] = ""
			(st["members"] as Dictionary).clear()
			_update_band(vm)
			return
		st["boss"] = heir.get_person_key()
		st["boss_name"] = heir.npc_name
		boss = heir
	# Reclutar de uno en uno hasta alcanzar el cupo (2 a 4 cómplices)
	var limit: int = clampi(int(st.get("target_recruits", 3)), MIN_RECRUITS, MAX_RECRUITS)
	if recruits_count(vm) < limit:
		try_recruit(vm)
	# Si hay al menos 2 miembros y el jefe tiene planes pendientes, fija la próxima noche de reunión
	if member_nodes(vm).size() >= 2 and int(st.get("next_plan_night", -99)) < today:
		if bool(st.get("postponed", false)) or recruits_count(vm) < limit or has_boss_motive(vm, boss):
			st["next_plan_night"] = today
		else:
			st["next_plan_night"] = today + 2
	_update_band(vm)

static func on_hour(vm, hour: int) -> void:
	if vm == null or not active(vm):
		return
	var st: Dictionary = state(vm)
	var today: int = VillageNeeds.today()
	if hour in MEET_CALL_HOURS:
		var planned: int = int(st.get("next_plan_night", -99))
		if is_meeting_now(vm):
			if has_unwanted_witness_near(vm) != null:
				abort_meeting(vm)
			return
		if planned >= 0 and planned <= today and int(st.get("last_meeting_day", -99)) != today and not ( str(st.get("meeting_status", "")) == "aborted" and int(st.get("meeting_night", -99)) == today ):
			call_meeting(vm)
	elif hour == MEET_END_HOUR or (hour >= 5 and hour < 22):
		if is_meeting_now(vm):
			finish_meeting(vm)
		elif str(st.get("meeting_status", "")) == "aborted" and hour >= 6 and hour < 22:
			st["meeting_status"] = ""

static func tick(vm) -> void:
	if vm == null or not active(vm) or not is_meeting_now(vm):
		return
	var w = has_unwanted_witness_near(vm)
	if w != null:
		abort_meeting(vm, w)
		return
	var st: Dictionary = state(vm)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var in_backroom: int = 0
	var keys: Array = st.get("attending", [])
	for i in range(keys.size()):
		var m = by_key.get(str(keys[i]), null)
		if m == null or not is_instance_valid(m) or m.is_dead:
			continue
		if m.errand_kind != "familia_meet" and _can_attend(m):
			m.start_errand("familia_meet", seat_pos(i, keys.size()))
		if VillageRestaurant.room_of(m.global_position) == "reservado" or m.global_position.distance_to(VillageRestaurant.BACKROOM_TABLE) <= 28.0:
			in_backroom += 1
	if in_backroom >= 2:
		st["meeting_status"] = "meeting"

static func after_load(vm) -> void:
	if vm == null:
		return
	_update_band(vm)
	if not active(vm):
		return
	var st: Dictionary = state(vm)
	if not (str(st.get("meeting_status", "")) in ["gathering", "meeting"]):
		return
	var h: int = int(WorldClock.current_hour) if WorldClock != null else 12
	if not (h in MEET_CALL_HOURS) or has_unwanted_witness_near(vm) != null:
		finish_meeting(vm)
		return
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var keys: Array = st.get("attending", [])
	for i in range(keys.size()):
		var m = by_key.get(str(keys[i]), null)
		if m != null and is_instance_valid(m) and not m.is_dead and _can_attend(m):
			m.start_errand("familia_meet", seat_pos(i, keys.size()))

# ------------------------------------------------------------------ 5. El cocinero suelta una frase si le preguntas
static func cook_line(vm) -> String:
	if is_meeting_now(vm):
		return COOK_LINE_MEETING
	if active(vm):
		return COOK_LINE_ACTIVE
	return COOK_LINE_QUIET

static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null or npc == null or int(npc.trade_role) != int(VillageNPC.TradeRole.RESTAURATEUR):
		return
	var pos: int = maxi(0, ch_arr.size() - 1)
	ch_arr.insert(pos, {"label": "🍷 Preguntar por el reservado del fondo", "next": "familia_cook_ask"})
	diag["familia_cook_ask"] = {
		"text": cook_line(vm),
		"choices": [{"label": "Entendido. [Volver]", "next": "start"}],
	}
	if diag.has("family_chat") and diag["family_chat"] is Dictionary and active(vm):
		diag["family_chat"]["text"] = str(diag["family_chat"].get("text", "")) + "\n\n" + cook_line(vm)
