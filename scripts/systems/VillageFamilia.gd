@tool
extends RefCounted

## Bloque R2 (crimen interno discreto, 2026-11-06): «La Familia».
## - Nace sola (nunca al empezar): un vecino adulto ambicioso, sin escrúpulos y persuasivo decide montarla cuando
##   tiene dinero ahorrado y un motivo (deudas, envidia, rencor) o una oportunidad. Si no hay nadie así, no nace.
## - Recluta de 2 a 4 vecinos de uno en uno entre quienes le deben algo, le tienen afecto o miedo, o están
##   desesperados (pobres, endeudados). Puede fallar: quien se niega lo recuerda y puede contarlo como chisme.
## - Se reúnen de noche en el reservado de la Trattoria «Il Corvo» (marca `mesa_reservado`, sala
##   `"reservado"`) cuando el jefe lo decide según sus planes (sin calendario fijo). Si ven a la guardia o a un
##   desconocido cerca, lo dejan para otra noche.
## - Perfil bajo: de día siguen con sus oficios normales.
## - Guardar y cargar: jefe, miembros y rechazos viven en `VillageNeeds.state(vm)["familia"]`.
## Sin `class_name`: se carga con `preload`.

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const PersonProfile = preload("res://scripts/data/PersonProfile.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const _AN_SITIOS = preload("res://mapa/anclas.gd") # plan de sitios: el reservado sigue al restaurante movido
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageRestaurant = preload("res://scripts/systems/VillageRestaurant.gd")
const VillageLoans = preload("res://scripts/systems/VillageLoans.gd")
const VillageUnderworld = preload("res://scripts/systems/VillageUnderworld.gd")
const VillageDesires = preload("res://scripts/systems/VillageDesires.gd")

## Jefe inicial desde el Día 0: Don Vittorio Corvo (cumple todos los requisitos de ambición, falta de escrúpulos, persuasión y motivo)
const INITIAL_BOSS_ID: String = "vittorio_corvo"
const INITIAL_BOSS_NAME: String = "Don Vittorio Corvo"
const INITIAL_BOSS_ROLE: String = "Patrón de la Casa del Corvo"
const INITIAL_BOSS_GOLD: int = 120
const INITIAL_BOSS_TRAITS: Array[String] = [
	"Sediento de poder",
	"Manipulador",
	"Líder",
	"Codicioso",
	"Astuto",
	"Rencoroso",
]

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

## Bloque R3: constantes de los negocios discretos (comisión de tranquilidad, préstamos del reservado y soborno a guardias)
const BUSINESS_HOURS: Array[int] = [11, 16]
const PROTECTION_MIN_GOLD: int = 30
const PROTECTION_FEE: int = 12
const PROTECTION_COOLDOWN_DAYS: int = 4
const LOAN_MIN_BOSS_GOLD: int = 55
const LOAN_MAX_TARGET_GOLD: int = 10
const LOAN_AMOUNT: int = 20
const LOAN_REPAY: int = 26
const LOAN_DURATION_DAYS: int = 4
const BRIBE_MIN_BOSS_GOLD: int = 45
const BRIBE_AMOUNT: int = 15
const BRIBE_DURATION_DAYS: int = 5
const BRIBE_COOLDOWN_DAYS: int = 5
const WITNESS_GUARD_RADIUS: float = 110.0

## Bloque R4: descubrimiento en persona (espiar tras la puerta del reservado, oír rumores) e intervención del jugador
const EAVESDROP_RADIUS: float = 78.0
const REPORT_REWARD: int = 35
const PLAYER_COLLECT_RADIUS: float = 95.0

## Frases provisionales del cocinero cuando le preguntas por el reservado (anotadas en docs/APORTES_CREATIVOS.md).
const COOK_LINE_MEETING: String = "«Chist... baje la voz. Esta noche hay gente cenando a puerta cerrada en el reservado del fondo. Yo llevo las fuentes, dejo el vino y miro al suelo. En esta cocina el que no pregunta llega a viejo.»"
const COOK_LINE_ACTIVE: String = "«¿La mesa del reservado? Hay clientes que prefieren cenar tarde con la puerta cerrada y sin que nadie apunte sus nombres. Pagan al contado, no arman ruido y yo no pregunto de qué hablan.»"
const COOK_LINE_QUIET: String = "«El reservado del fondo está tranquilo últimamente. Sólo se abre cuando alguien quiere hablar de negocios lejos de los curiosos.»"

static func state(vm) -> Dictionary:
	var ns: Dictionary = VillageNeeds.state(vm)
	var fresh: bool = not (ns.get("familia", null) is Dictionary)
	if fresh:
		ns["familia"] = {}
	var st: Dictionary = ns["familia"]
	if fresh and vm != null and is_instance_valid(vm) and vm.is_inside_tree():
		var init_b = vm._get_npcs_by_person_key().get(INITIAL_BOSS_ID, null)
		if init_b != null and is_instance_valid(init_b) and not init_b.is_dead:
			var d0: int = VillageNeeds.today()
			st["boss"] = INITIAL_BOSS_ID
			st["boss_name"] = init_b.npc_name
			st["members"] = {INITIAL_BOSS_ID: d0}
			st["founded_day"] = d0
			st["target_recruits"] = MAX_RECRUITS
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
		["protected_shops", {}],
		["protection_cooldown", {}],
		["loans", {}],
		["bribed_guards", {}],
		["bribe_cooldown", {}],
		["pending_business", {}],
		["business_done", 0],
		["player_knows_boss", false],
		["player_evidence", 0],
		["last_eavesdrop_night", -99],
		["known_members", {}],
		["known_target", ""],
		["player_job_target", ""],
		["player_job_collected", false],
		["reported_by_player", false],
	]:
		if not st.has(pair[0]):
			st[pair[0]] = pair[1]
	return st

## Crea desde el Día 0 a Don Vittorio Corvo en la Trattoria «Il Corvo» con los 6 rasgos ideales de líder mafioso y funda «La Familia».
static func spawn_initial_boss(vm):
	if vm == null or not is_instance_valid(vm):
		return null
	var existing = vm._get_npcs_by_person_key().get(INITIAL_BOSS_ID, null) if vm.is_inside_tree() else null
	if existing == null and is_instance_valid(vm.entities_root):
		existing = vm.entities_root.get_node_or_null("NPC_Don_Vittorio_Corvo")
	if existing != null and is_instance_valid(existing):
		if not active(vm):
			found(vm, existing)
		return existing
	var boss := VillageNPC.new()
	boss.name = "NPC_Don_Vittorio_Corvo"
	boss.npc_name = INITIAL_BOSS_NAME
	boss.npc_role = INITIAL_BOSS_ROLE
	boss.trade_role = VillageNPC.TradeRole.FAMILY_MEMBER
	boss.linked_trade = VillageNPC.TradeRole.RESTAURATEUR
	boss.days_in_role = 7
	boss.personal_gold = INITIAL_BOSS_GOLD
	boss.tavern_social_pos = vm._tavern_social_pos
	boss.person_profile = PersonProfile.from_dict({
		"person_id": INITIAL_BOSS_ID,
		"gender": "M",
		"age": 49,
		"personality": INITIAL_BOSS_TRAITS.duplicate(),
		"likes": ["comida", "negocios"],
		"dislikes": ["chismes"],
		"romance_status": "single",
		"partner_id": "",
		"favorite_item": "braised_meat",
	})
	vm.entities_root.add_child(boss)
	boss.setup_npc(
		vm._load_tex("res://assests/world/village/villager_traveler.png"),
		VillageRestaurant.dining_tables()[VillageRestaurant.MESA_JEFE],
		VillageRestaurant.sitio(VillageRestaurant.M_CAMA_2),
		{},
		VillageRestaurant.sitio(VillageRestaurant.M_RESERVADO),
		VillageRestaurant.FAMILY_ID,
		VillageRestaurant.FAMILY_NAME
	)
	boss.character_tagline = "Caballero de modales suaves que almuerza siempre en la mesa del rincón de la Casa de Comidas."
	boss.character_lore = "«Un hombre prudente no necesita alzar la voz para que lo escuchen en este valle. En El Fogón del Valle siempre hay un plato caliente y una silla para quien sabe agradecer un favor a tiempo.»"
	boss.character_secret = "«Las cuentas importantes no se apuntan en los libros del Ayuntamiento; se cierran con un apretón de manos en el reservado del fondo cuando el comedor ya ha echado el cierre.»"
	found(vm, boss)
	return boss

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
	for l in vm.VillageLots.lots():
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
	return _AN_SITIOS.mover(VillageRestaurant.sitio(VillageRestaurant.M_RESERVADO) + Vector2(cos(a) * SEAT_RADIUS_X, sin(a) * SEAT_RADIUS_Y))

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
	var vm_a = npc._get_vm()
	if vm_a != null and vm_a.VillageJustice.is_npc_jailed(vm_a, npc):
		return false
	return true

## Comprueba si hay un guardia cerca del restaurante/reservado o un desconocido pegado al reservado.
static func has_unwanted_witness_near(vm):
	if vm == null:
		return null
	var table: Vector2 = VillageRestaurant.sitio(VillageRestaurant.M_RESERVADO)
	var rest_rect: Rect2 = VillageRestaurant.RECT.grow(70.0)
	var back_rect: Rect2 = (VillageRestaurant.ROOMS["reservado"] as Rect2).grow(40.0)
	for n in VillageNeeds.living(vm):
		if n.is_sleeping or n.is_incapacitated() or not n.is_conscious() or int(n.elevation_level) != 0:
			continue
		var np: Vector2 = _AN_SITIOS.desmover(n.global_position) # se compara en el mapa original
		if int(n.trade_role) in [int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.ROYAL_INVESTIGATOR)]:
			if is_guard_bribed(vm, n):
				continue # R3: el guardia untado mira para otro lado
			if np.distance_to(table) <= GUARD_NEAR_PX or rest_rect.has_point(np):
				return n
			continue
		if is_member(vm, n) or int(n.trade_role) == int(VillageNPC.TradeRole.RESTAURATEUR):
			continue
		if back_rect.has_point(np) or np.distance_to(table) <= STRANGER_NEAR_PX:
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
		if VillageRestaurant.room_of(_AN_SITIOS.desmover(m.global_position)) == "reservado" or m.global_position.distance_to(_AN_SITIOS.mover(VillageRestaurant.sitio(VillageRestaurant.M_RESERVADO))) <= 32.0:
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
		if (st.get("pending_business", {}) as Dictionary).is_empty():
			plan_next_business(vm)
		VillageChronicle.add(vm, "familia_meet", "La Familia de %s se reunió a puerta cerrada en el reservado de la casa de comidas" % str(st.get("boss_name", "")), false)

# ------------------------------------------------------------------ 3b. Negocios discretos (Bloque R3)
static func is_guard_bribed(vm, guard) -> bool:
	if vm == null or guard == null:
		return false
	var bg: Dictionary = state(vm).get("bribed_guards", {})
	return int(bg.get(guard.get_person_key(), -99)) >= VillageNeeds.today()

static func has_guard_witness_at(vm, pos: Vector2, exclude_guard = null) -> bool:
	if vm == null:
		return false
	for n in VillageNeeds.living(vm):
		if n == exclude_guard or n.is_sleeping or n.is_incapacitated() or not n.is_conscious() or int(n.elevation_level) != 0:
			continue
		if int(n.trade_role) in [int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.ROYAL_INVESTIGATOR)]:
			if is_guard_bribed(vm, n):
				continue
			if n.global_position.distance_to(pos) <= WITNESS_GUARD_RADIUS:
				return true
	return false

static func can_target_merchant(vm, merchant) -> bool:
	if vm == null or merchant == null or not _can_be_member(merchant) or is_member(vm, merchant):
		return false
	if int(merchant.personal_gold) < PROTECTION_MIN_GOLD:
		return false
	var today: int = VillageNeeds.today()
	var m_key: String = merchant.get_person_key()
	var cd: Dictionary = state(vm).get("protection_cooldown", {})
	if int(cd.get(m_key, -99)) > today:
		return false
	var ps: Dictionary = state(vm).get("protected_shops", {})
	if ps.has(m_key) and int((ps[m_key] as Dictionary).get("last_day", -99)) + 3 > today:
		return false
	return true

static func protection_chance(vm, agent, merchant) -> float:
	if vm == null or agent == null or merchant == null:
		return 0.0
	var boss = boss_of(vm)
	var clout: float = 0.45 + 0.25 * maxf(0.0, persuasion(vm, agent))
	if boss != null and boss != agent:
		clout += 0.15 * maxf(0.0, persuasion(vm, boss))
	clout += 0.20 * maxf(0.0, TraitCatalog.npc_tendency(agent, "aggression"))
	var res: float = 0.30 * maxf(0.0, TraitCatalog.npc_tendency(merchant, "courage"))
	res += 0.25 * maxf(0.0, TraitCatalog.npc_tendency(merchant, "honesty"))
	res += 0.20 * maxf(0.0, TraitCatalog.npc_tendency(merchant, "law"))
	if _has(merchant, "Valiente") or _has(merchant, "Íntegro") or _has(merchant, "Honrado"):
		res += 0.35
	if _has(merchant, "Cobarde") or _has(merchant, "Sumiso") or _has(merchant, "Pragmático"):
		res -= 0.25
	return clampf(clout - res, 0.08, 0.90)

## Cobro en persona de la comisión de «tranquilidad» (suma cero: sale de merchant.personal_gold y se reparte entre cobrador y jefe).
static func resolve_protection(vm, agent, merchant, force_roll: float = -1.0) -> String:
	if vm == null or agent == null or merchant == null or not active(vm):
		return ""
	if int(merchant.personal_gold) < 6:
		return ""
	if has_guard_witness_at(vm, merchant.global_position):
		return "aborted_guard"
	var st: Dictionary = state(vm)
	var today: int = VillageNeeds.today()
	var m_key: String = merchant.get_person_key()
	var boss = boss_of(vm)
	var chance: float = protection_chance(vm, agent, merchant)
	var roll: float = force_roll if force_roll >= 0.0 else randf()
	if roll < chance:
		var fee: int = mini(PROTECTION_FEE, int(merchant.personal_gold))
		merchant.personal_gold -= fee
		if boss != null and boss != agent:
			var agent_cut: int = fee / 2
			var boss_cut: int = fee - agent_cut
			agent.personal_gold += agent_cut
			boss.personal_gold += boss_cut
		else:
			agent.personal_gold += fee
		(st["protected_shops"] as Dictionary)[m_key] = {
			"fee": fee,
			"last_day": today,
			"collector": agent.get_person_key(),
		}
		st["business_done"] = int(st.get("business_done", 0)) + 1
		merchant.add_thought("Pagué %d de oro a %s por tener tranquilidad en el negocio (-5)" % [fee, agent.npc_name], -5.0)
		merchant.modify_npc_relationship(agent, -6, "Me cobró por la «tranquilidad» del negocio", true)
		agent._spawn_floating_text("🤝 «Así todos trabajamos tranquilos.»", Color(0.92, 0.82, 0.62), -36.0)
		return "paid"
	(st["protection_cooldown"] as Dictionary)[m_key] = today + PROTECTION_COOLDOWN_DAYS
	merchant.add_thought("Me negué a pagar «tranquilidad» a %s (-4)" % agent.npc_name, -4.0)
	merchant.modify_npc_relationship(agent, -10, "Intentó cobrarme por la «tranquilidad» del local", true)
	if boss != null and boss != agent:
		merchant.modify_npc_relationship(boss, -8, "Mandó a su gente a pedirme dinero", true)
	if not _has(merchant, "Discreto") and not _has(merchant, "Cobarde"):
		var ev: Dictionary = vm.record_social_event(
			"familia_rumor",
			agent,
			merchant,
			"%s cuenta que %s pasó por su negocio pidiendo una comisión por «evitar disgustos»" % [merchant.npc_name, agent.npc_name]
		)
		ev["quiet"] = [agent.get_person_key()]
	return "refused"

static func can_loan_to(vm, target) -> bool:
	if vm == null or target == null or not _can_be_member(target) or is_member(vm, target):
		return false
	var boss = boss_of(vm)
	if boss == null or int(boss.personal_gold) < LOAN_MIN_BOSS_GOLD:
		return false
	if int(target.personal_gold) > LOAN_MAX_TARGET_GOLD:
		return false
	return not (state(vm).get("loans", {}) as Dictionary).has(target.get_person_key())

## Préstamo discreto del reservado: sale del bolsillo del jefe y deja al vecino en deuda con él.
static func give_loan(vm, _agent, target) -> bool:
	if not can_loan_to(vm, target):
		return false
	var boss = boss_of(vm)
	var st: Dictionary = state(vm)
	var today: int = VillageNeeds.today()
	var t_key: String = target.get_person_key()
	boss.personal_gold -= LOAN_AMOUNT
	target.personal_gold += LOAN_AMOUNT
	(st["loans"] as Dictionary)[t_key] = {
		"amount": LOAN_AMOUNT,
		"repay": LOAN_REPAY,
		"due_day": today + LOAN_DURATION_DAYS,
		"lender": boss.get_person_key(),
	}
	st["business_done"] = int(st.get("business_done", 0)) + 1
	target.set_meta("owes_to", boss.get_person_key())
	target.add_thought("%s me prestó %d de oro cuando no tenía nada; ahora estoy en deuda (+3)" % [boss.npc_name, LOAN_AMOUNT], 3.0)
	target.modify_npc_relationship(boss, 6, "Me prestó dinero cuando estaba apurado")
	return true

## Cobro en persona de un préstamo vencido (suma cero: de target.personal_gold a boss.personal_gold).
static func collect_loan(vm, _agent, target) -> String:
	if vm == null or target == null or not active(vm):
		return ""
	var st: Dictionary = state(vm)
	var loans: Dictionary = st.get("loans", {})
	var t_key: String = target.get_person_key()
	if not loans.has(t_key):
		return ""
	var boss = boss_of(vm)
	if boss == null:
		return ""
	var entry: Dictionary = loans[t_key]
	var repay: int = int(entry.get("repay", LOAN_REPAY))
	var today: int = VillageNeeds.today()
	if int(target.personal_gold) >= repay:
		target.personal_gold -= repay
		boss.personal_gold += repay
		loans.erase(t_key)
		if target.has_meta("owes_to"):
			target.remove_meta("owes_to")
		st["business_done"] = int(st.get("business_done", 0)) + 1
		target.add_thought("Saldé mi deuda con %s (+2)" % boss.npc_name, 2.0)
		return "repaid"
	var partial: int = maxi(0, int(target.personal_gold) - 2)
	if partial > 0:
		target.personal_gold -= partial
		boss.personal_gold += partial
	entry["repay"] = maxi(4, repay - partial)
	entry["due_day"] = today + 2
	target.set_meta("owes_to", boss.get_person_key())
	target.add_thought("No pude pagar toda mi deuda con %s y me lo recordó en persona (-6)" % boss.npc_name, -6.0)
	target.modify_npc_relationship(boss, -6, "Le debo dinero vencido del reservado", true)
	return "defaulted"

static func can_bribe_guard(vm, guard) -> bool:
	if vm == null or guard == null or not is_instance_valid(guard) or guard.is_dead:
		return false
	if int(guard.trade_role) != int(VillageNPC.TradeRole.GUARD):
		return false
	if _has(guard, "Honrado") or _has(guard, "Íntegro") or TraitCatalog.npc_tendency(guard, "honesty") > 0.25:
		return false
	if is_guard_bribed(vm, guard):
		return false
	var cd: Dictionary = state(vm).get("bribe_cooldown", {})
	return int(cd.get(guard.get_person_key(), -99)) <= VillageNeeds.today()

static func bribe_guard_chance(vm, agent, guard) -> float:
	if vm == null or agent == null or guard == null:
		return 0.0
	var c: float = 0.52 + 0.25 * maxf(0.0, persuasion(vm, agent))
	c -= 0.40 * TraitCatalog.npc_tendency(guard, "honesty")
	c -= 0.30 * TraitCatalog.npc_tendency(guard, "law")
	if _has(guard, "Sobornable") or _has(guard, "Codicioso") or _has(guard, "Pragmático"):
		c += 0.30
	if _has(guard, "Cumplidor") or _has(guard, "Justiciero"):
		c -= 0.35
	return clampf(c, 0.08, 0.92)

## Intenta comprar el silencio de un guardia (suma cero: sale de boss.personal_gold y entra en guard.personal_gold).
static func try_bribe_guard(vm, agent, guard, force_roll: float = -1.0) -> String:
	if vm == null or agent == null or guard == null or not active(vm):
		return ""
	var boss = boss_of(vm)
	if boss == null or int(boss.personal_gold) < BRIBE_AMOUNT:
		return ""
	if has_guard_witness_at(vm, guard.global_position, guard):
		return "aborted_witness"
	var st: Dictionary = state(vm)
	var today: int = VillageNeeds.today()
	var g_key: String = guard.get_person_key()
	var chance: float = bribe_guard_chance(vm, agent, guard)
	var roll: float = force_roll if force_roll >= 0.0 else randf()
	if roll < chance:
		boss.personal_gold -= BRIBE_AMOUNT
		guard.personal_gold += BRIBE_AMOUNT
		(st["bribed_guards"] as Dictionary)[g_key] = today + BRIBE_DURATION_DAYS
		st["business_done"] = int(st.get("business_done", 0)) + 1
		guard.add_thought("Un sobre discreto de %s bien vale mirar hacia otro barrio (+2)" % boss.npc_name, 2.0)
		guard._spawn_floating_text("🪙 «Esta noche haré la ronda por el otro lado.»", Color(0.85, 0.85, 0.65), -36.0)
		return "bribed"
	(st["bribe_cooldown"] as Dictionary)[g_key] = today + BRIBE_COOLDOWN_DAYS
	guard.add_thought("%s intentó comprar mi silencio con unas monedas (-5)" % agent.npc_name, -5.0)
	guard.modify_npc_relationship(agent, -12, "Intentó sobornarme", true)
	var ev: Dictionary = vm.record_social_event(
		"familia_rumor",
		agent,
		guard,
		"%s cuenta que %s intentó untarle con unas monedas para que mirase a otro lado" % [guard.npc_name, agent.npc_name]
	)
	ev["quiet"] = [agent.get_person_key()]
	return "refused"

static func _pick_business_agent(vm):
	var boss = boss_of(vm)
	for m in member_nodes(vm):
		if m != boss and _can_attend(m) and m.errand_kind == "":
			return m
	return boss if boss != null and _can_attend(boss) and boss.errand_kind == "" else null

static func plan_next_business(vm) -> Dictionary:
	if vm == null or not active(vm) or member_nodes(vm).size() < 2:
		return {}
	var st: Dictionary = state(vm)
	var today: int = VillageNeeds.today()
	var agent = _pick_business_agent(vm)
	if agent == null:
		return {}
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	# 1. Cobrar un préstamo ya vencido
	var loans: Dictionary = st.get("loans", {})
	for t_key in loans.keys():
		var entry: Dictionary = loans[t_key]
		if today >= int(entry.get("due_day", 999999)):
			var deb = by_key.get(str(t_key), null)
			if deb != null and is_instance_valid(deb) and not deb.is_dead:
				var pb1: Dictionary = {"kind": "loan_collect", "agent": agent.get_person_key(), "target": str(t_key), "status": "planned"}
				st["pending_business"] = pb1
				return pb1
	# 2. Untar a un guardia si hubo reuniones abortadas o hay oro de sobra
	var boss = boss_of(vm)
	if boss != null and int(boss.personal_gold) >= BRIBE_MIN_BOSS_GOLD:
		for n in VillageNeeds.living(vm):
			if can_bribe_guard(vm, n):
				var pb2: Dictionary = {"kind": "bribe_guard", "agent": agent.get_person_key(), "target": n.get_person_key(), "status": "planned"}
				st["pending_business"] = pb2
				return pb2
	# 3. Cobrar comisión de «tranquilidad» a un comerciante con dinero
	var best_m = null
	var best_gold: int = PROTECTION_MIN_GOLD - 1
	for n in VillageNeeds.living(vm):
		if can_target_merchant(vm, n) and int(n.personal_gold) > best_gold:
			best_gold = int(n.personal_gold)
			best_m = n
	if best_m != null:
		var pb3: Dictionary = {"kind": "protection", "agent": agent.get_person_key(), "target": best_m.get_person_key(), "status": "planned"}
		st["pending_business"] = pb3
		return pb3
	# 4. Prestar dinero a un vecino apurado
	for n in VillageNeeds.living(vm):
		if can_loan_to(vm, n):
			var pb4: Dictionary = {"kind": "loan", "agent": agent.get_person_key(), "target": n.get_person_key(), "status": "planned"}
			st["pending_business"] = pb4
			return pb4
	return {}

static func dispatch_business(vm) -> bool:
	if vm == null or not active(vm):
		return false
	var st: Dictionary = state(vm)
	var pb: Dictionary = st.get("pending_business", {})
	if pb.is_empty():
		pb = plan_next_business(vm)
	if pb.is_empty() or str(pb.get("status", "")) != "planned":
		return false
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var agent = by_key.get(str(pb.get("agent", "")), null)
	var target = by_key.get(str(pb.get("target", "")), null)
	if agent == null or not is_instance_valid(agent) or agent.is_dead or not _can_attend(agent):
		agent = _pick_business_agent(vm)
		if agent != null:
			pb["agent"] = agent.get_person_key()
	if agent == null or target == null or not is_instance_valid(target) or target.is_dead or target.is_sleeping:
		return false
	pb["status"] = "walking"
	agent.start_errand("familia_errand", target.global_position)
	return true

static func on_errand_arrived(vm, npc) -> void:
	if npc != null:
		npc.end_errand()
	if vm == null or npc == null or not active(vm):
		return
	var st: Dictionary = state(vm)
	var pb: Dictionary = st.get("pending_business", {})
	if pb.is_empty() or str(pb.get("agent", "")) != npc.get_person_key():
		return
	var target = vm._get_npcs_by_person_key().get(str(pb.get("target", "")), null)
	st["pending_business"] = {}
	if target == null or not is_instance_valid(target) or target.is_dead:
		return
	match str(pb.get("kind", "")):
		"protection":
			resolve_protection(vm, npc, target)
		"loan":
			give_loan(vm, npc, target)
		"loan_collect":
			collect_loan(vm, npc, target)
		"bribe_guard":
			try_bribe_guard(vm, npc, target)

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
	if member_nodes(vm).size() >= 2 and (st.get("pending_business", {}) as Dictionary).is_empty():
		plan_next_business(vm)
	_update_band(vm)

static func on_hour(vm, hour: int) -> void:
	if vm == null or not active(vm):
		return
	var st: Dictionary = state(vm)
	var today: int = VillageNeeds.today()
	if hour in BUSINESS_HOURS:
		dispatch_business(vm)
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
	if vm == null or not active(vm):
		return
	var st: Dictionary = state(vm)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var pb: Dictionary = st.get("pending_business", {})
	if not pb.is_empty() and str(pb.get("status", "")) == "walking":
		var ag = by_key.get(str(pb.get("agent", "")), null)
		var tg = by_key.get(str(pb.get("target", "")), null)
		if ag == null or tg == null or not is_instance_valid(ag) or not is_instance_valid(tg) or ag.is_dead or tg.is_dead:
			st["pending_business"] = {}
		elif ag.errand_kind == "familia_errand":
			ag.errand_pos = tg.global_position
	if not is_meeting_now(vm):
		return
	var w = has_unwanted_witness_near(vm)
	if w != null:
		abort_meeting(vm, w)
		return
	var in_backroom: int = 0
	var keys: Array = st.get("attending", [])
	for i in range(keys.size()):
		var m = by_key.get(str(keys[i]), null)
		if m == null or not is_instance_valid(m) or m.is_dead:
			continue
		if m.errand_kind != "familia_meet" and _can_attend(m):
			m.start_errand("familia_meet", seat_pos(i, keys.size()))
		if VillageRestaurant.room_of(_AN_SITIOS.desmover(m.global_position)) == "reservado" or m.global_position.distance_to(_AN_SITIOS.mover(VillageRestaurant.sitio(VillageRestaurant.M_RESERVADO))) <= 28.0:
			in_backroom += 1
	if in_backroom >= 2:
		st["meeting_status"] = "meeting"
	try_eavesdrop_meeting(vm)

# ------------------------------------------------------------------ 4b. Descubrimiento e intervención del jugador (Bloque R4)
static func is_boss_known_to_player(vm) -> bool:
	if vm == null or not active(vm):
		return false
	var st: Dictionary = state(vm)
	if bool(st.get("player_knows_boss", false)):
		return true
	var boss_k: String = str(st.get("boss", ""))
	for ev in vm.social_event_log:
		if str(ev.get("type", "")) == "familia_rumor":
			var kb: Dictionary = ev.get("known_by", {}) if ev.get("known_by", {}) is Dictionary else {}
			if kb.has("player") or str(ev.get("actor_id", "")) == boss_k and kb.size() >= 3:
				if kb.has("player"):
					st["player_knows_boss"] = true
					return true
	return false

## Si el jugador se acerca con discreción a la puerta del reservado durante una reunión nocturna, escucha sus planes.
static func try_eavesdrop_meeting(vm, player = null) -> bool:
	if vm == null or not is_meeting_now(vm):
		return false
	if player == null and vm.is_inside_tree():
		player = vm.get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return false
	if int(vm.player_elevation_level) != 0:
		return false
	var dist: float = player.global_position.distance_to(_AN_SITIOS.mover(VillageRestaurant.sitio(VillageRestaurant.M_RESERVADO)))
	if dist > EAVESDROP_RADIUS:
		return false
	var st: Dictionary = state(vm)
	var today: int = VillageNeeds.today()
	var boss = boss_of(vm)
	st["player_knows_boss"] = true
	var km: Dictionary = st.get("known_members", {})
	for k in (st.get("attending", []) as Array):
		km[str(k)] = true
	if boss != null:
		km[boss.get_person_key()] = true
	st["known_members"] = km
	if int(st.get("last_eavesdrop_night", -99)) != today:
		st["last_eavesdrop_night"] = today
		st["player_evidence"] = int(st.get("player_evidence", 0)) + 1
		var pb: Dictionary = st.get("pending_business", {})
		if pb.is_empty():
			pb = plan_next_business(vm)
		if not pb.is_empty() and str(pb.get("target", "")) != "":
			st["known_target"] = str(pb.get("target", ""))
		if boss != null:
			boss._spawn_floating_text("🍷 «Mañana pasaremos a cobrar... y ni media palabra fuera de esta mesa.»", Color(0.95, 0.80, 0.58), -40.0)
		VillageChronicle.add(
			vm,
			"familia_eavesdrop",
			"Escuchaste tras la puerta del reservado los tratos de la Familia de %s" % str(st.get("boss_name", "")),
			true
		)
	return true

## El jugador cobra en persona la comisión de «tranquilidad» encargada por el jefe (suma cero: sale de merchant.personal_gold y entra en inv).
static func player_collect_protection(vm, merchant, inv, force_roll: float = -1.0) -> String:
	if vm == null or merchant == null or inv == null or not active(vm):
		return ""
	var st: Dictionary = state(vm)
	if str(st.get("player_job_target", "")) != merchant.get_person_key() or bool(st.get("player_job_collected", false)):
		return ""
	var player = vm.get_tree().get_first_node_in_group("player") if vm.is_inside_tree() else null
	if player != null and is_instance_valid(player) and player.global_position.distance_to(merchant.global_position) > PLAYER_COLLECT_RADIUS:
		merchant._spawn_floating_text("🚫 Acércate en persona para hablar en voz baja.", Color.ORANGE_RED, -42.0)
		return "too_far"
	if has_guard_witness_at(vm, merchant.global_position):
		vm.wanted_level = maxi(1, int(vm.wanted_level) + 1)
		vm.bounty_gold = int(vm.bounty_gold) + 15
		merchant._spawn_floating_text("🚨 ¡Un guardia vio cómo intentabas extorsionarme!", Color.ORANGE_RED, -44.0)
		return "witnessed_guard"
	var boss = boss_of(vm)
	var chance: float = protection_chance(vm, boss if boss != null else merchant, merchant)
	if player != null and player.has_method("get_skill_bonus"):
		chance = clampf(chance + float(player.call("get_skill_bonus", "charisma")) * 0.5, 0.12, 0.92)
	var roll: float = force_roll if force_roll >= 0.0 else randf()
	var today: int = VillageNeeds.today()
	var m_key: String = merchant.get_person_key()
	if roll < chance and int(merchant.personal_gold) >= 2:
		var fee: int = mini(PROTECTION_FEE, int(merchant.personal_gold))
		merchant.personal_gold -= fee
		inv.add_gold(fee)
		st["player_job_collected"] = true
		(st["protected_shops"] as Dictionary)[m_key] = {
			"fee": fee,
			"last_day": today,
			"collector": "player",
		}
		merchant.modify_affinity(-10)
		merchant.add_thought("Tuve que pagar %d de oro al recadero de %s (-6)" % [fee, str(st.get("boss_name", "la Familia"))], -6.0)
		merchant._spawn_floating_text("💰 «Toma los %d de oro y dile a %s que no quiero líos.»" % [fee, str(st.get("boss_name", "la Familia"))], Color.GOLD, -44.0)
		return "paid"
	(st["protection_cooldown"] as Dictionary)[m_key] = today + PROTECTION_COOLDOWN_DAYS
	st["player_job_target"] = ""
	merchant.modify_affinity(-12)
	merchant.add_thought("Me negué a pagar comisión al recadero de %s (-5)" % str(st.get("boss_name", "la Familia")), -5.0)
	if not _has(merchant, "Discreto") and not _has(merchant, "Cobarde") and boss != null:
		vm.record_social_event(
			"familia_rumor",
			boss,
			merchant,
			"%s cuenta que mandaron a cobrarle una comisión en nombre de %s" % [merchant.npc_name, boss.npc_name]
		)
	merchant._spawn_floating_text("😤 «¡No pienso pagaros ni una moneda!»", Color.ORANGE, -44.0)
	return "refused"

static func after_load(vm) -> void:
	if vm == null:
		return
	_update_band(vm)
	if not active(vm):
		return
	var st: Dictionary = state(vm)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var boss_k: String = str(st.get("boss", ""))
	for t_key in (st.get("loans", {}) as Dictionary).keys():
		var deb = by_key.get(str(t_key), null)
		if deb != null and is_instance_valid(deb) and not deb.is_dead:
			deb.set_meta("owes_to", boss_k)
	var pb: Dictionary = st.get("pending_business", {})
	if not pb.is_empty() and str(pb.get("status", "")) == "walking":
		var ag = by_key.get(str(pb.get("agent", "")), null)
		var tg = by_key.get(str(pb.get("target", "")), null)
		if ag != null and tg != null and is_instance_valid(ag) and is_instance_valid(tg) and not ag.is_dead and not tg.is_dead and _can_attend(ag):
			ag.start_errand("familia_errand", tg.global_position)
		else:
			pb["status"] = "planned"
	if not (str(st.get("meeting_status", "")) in ["gathering", "meeting"]):
		return
	var h: int = int(WorldClock.current_hour) if WorldClock != null else 12
	if not (h in MEET_CALL_HOURS) or has_unwanted_witness_near(vm) != null:
		finish_meeting(vm)
		return
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
	if vm == null or npc == null:
		return
	var st: Dictionary = state(vm)
	var n_key: String = npc.get_person_key()
	# 1. Cocinero de la Trattoria: pista sobre el reservado
	if int(npc.trade_role) == int(VillageNPC.TradeRole.RESTAURATEUR):
		var pos_c: int = maxi(0, ch_arr.size() - 1)
		ch_arr.insert(pos_c, {"label": "🍷 Preguntar por el reservado del fondo", "next": "familia_cook_ask"})
		diag["familia_cook_ask"] = {
			"text": cook_line(vm),
			"choices": [{"label": "Entendido. [Volver]", "next": "start"}],
		}
		if diag.has("family_chat") and diag["family_chat"] is Dictionary and active(vm):
			diag["family_chat"]["text"] = str(diag["family_chat"].get("text", "")) + "\n\n" + cook_line(vm)
	if not active(vm):
		return
	var boss = boss_of(vm)
	var b_name: String = str(st.get("boss_name", "la Familia"))
	# 2. Avisar al vecino que va a recibir una visita de «La Familia»
	if str(st.get("known_target", "")) == n_key and n_key != "":
		var pos_w: int = maxi(0, ch_arr.size() - 1)
		ch_arr.insert(pos_w, {
			"label": "🤫 Avisarle de que la gente de %s planea pasar a cobrarle" % b_name,
			"action": "familia_warn_target",
			"next": "END",
		})
	# 3. Delatar al Comisario Vane cuando tienes pruebas del reservado
	if int(npc.trade_role) == int(VillageNPC.TradeRole.SHERIFF) and int(st.get("player_evidence", 0)) >= 1:
		var pos_s: int = maxi(0, ch_arr.size() - 1)
		ch_arr.insert(pos_s, {
			"label": "⚖️ Entregar pruebas de los tratos del reservado de %s" % b_name,
			"next": "familia_report_confirm",
		})
		diag["familia_report_confirm"] = {
			"text": "«¿Dices que has oído a %s y a su gente repartirse cobros tras la puerta del reservado? Si me das los nombres ahora mismo, mandaré patrullas a cortarles el paso y te pagaré %d de oro de las arcas por el soplo.»" % [b_name, REPORT_REWARD],
			"choices": [
				{"label": "⚖️ [Confirmar] Sí, delatar a la Familia de %s (+%d Oro)" % [b_name, REPORT_REWARD], "action": "familia_report_sheriff", "next": "END"},
				{"label": "Mejor me callo por ahora. [Volver]", "next": "start"},
			],
		}
	# 4. Hablar con el jefe (si ya sabes quién es): pedir un encargo o entregar su parte
	if boss != null and npc == boss and is_boss_known_to_player(vm) and not bool(st.get("reported_by_player", false)) and npc.affinity >= -15:
		var pos_b: int = maxi(0, ch_arr.size() - 1)
		if bool(st.get("player_job_collected", false)):
			var cut: int = PROTECTION_FEE / 2
			ch_arr.insert(pos_b, {
				"label": "🪙 Entregar la mitad del cobro al jefe (%d Oro)" % cut,
				"action": "familia_deliver_cut",
				"next": "END",
			})
		elif str(st.get("player_job_target", "")) == "":
			ch_arr.insert(pos_b, {
				"label": "🍷 «Sé de qué habláis en el reservado. ¿Tienes algún encargo discreto?»",
				"action": "familia_ask_work",
				"next": "END",
			})
	# 5. Cobrar en persona al comerciante que te señaló el jefe
	if str(st.get("player_job_target", "")) == n_key and n_key != "" and not bool(st.get("player_job_collected", false)):
		var pos_e: int = maxi(0, ch_arr.size() - 1)
		ch_arr.insert(pos_e, {
			"label": "🤝 Cobrar comisión de «tranquilidad» (%d Oro) de parte de %s" % [PROTECTION_FEE, b_name],
			"action": "familia_player_extort",
			"next": "END",
		})

static func on_player_action(vm, npc, action_str: String, inv = null, force_roll: float = -1.0) -> bool:
	if vm == null or npc == null or not action_str.begins_with("familia_"):
		return false
	var st: Dictionary = state(vm)
	var today: int = VillageNeeds.today()
	var boss = boss_of(vm)
	var b_name: String = str(st.get("boss_name", "la Familia"))
	match action_str:
		"familia_warn_target":
			var n_key: String = npc.get_person_key()
			if str(st.get("known_target", "")) != n_key:
				return false
			(st["protection_cooldown"] as Dictionary)[n_key] = today + PROTECTION_COOLDOWN_DAYS + 2
			st["known_target"] = ""
			var pb: Dictionary = st.get("pending_business", {})
			if str(pb.get("target", "")) == n_key:
				st["pending_business"] = {}
			npc.modify_affinity(10)
			npc.add_thought("El forastero me avisó a tiempo de los planes de %s (+8)" % b_name, 8.0)
			if boss != null and is_instance_valid(boss):
				boss.modify_affinity(-12)
				boss.add_thought("Alguien puso sobre aviso a nuestro objetivo antes de cobrar (-6)", -6.0)
			npc._spawn_floating_text("🤝 «Gracias por el aviso. Guardaré el oro bajo llave cuando asomen.» (+10 Relación)", Color.SPRING_GREEN, -44.0)
			VillageChronicle.add(vm, "familia_warn", "Pusiste sobre aviso a %s antes de que la Familia de %s pasara a cobrarle" % [npc.npc_name, b_name], true)
			return true
		"familia_report_sheriff":
			if int(npc.trade_role) != int(VillageNPC.TradeRole.SHERIFF) or int(st.get("player_evidence", 0)) < 1:
				return false
			var ts: Dictionary = vm.VillageTown.state(vm)
			var tr: int = maxi(0, int(ts.get("treasury", 0)))
			var reward: int = mini(REPORT_REWARD, tr)
			ts["treasury"] = tr - reward
			if inv != null and reward > 0:
				inv.add_gold(reward)
			(st["bribed_guards"] as Dictionary).clear()
			(st["protected_shops"] as Dictionary).clear()
			st["pending_business"] = {}
			st["postponed"] = true
			st["player_evidence"] = 0
			st["reported_by_player"] = true
			st["next_plan_night"] = today + 4
			npc.modify_affinity(10)
			npc.add_thought("Desarticulamos los cobros del reservado gracias a un soplo (+8)", 8.0)
			if boss != null and is_instance_valid(boss):
				boss.modify_affinity(-25)
				boss.add_thought("El forastero nos delató ante la comisaría (-15)", -15.0)
				vm.VillageJustice.arrest_npc(vm, boss, npc, "liderar «La Familia»", 48, 60)
			for mem in member_nodes(vm):
				if mem == boss:
					continue
				mem.modify_affinity(-12)
				mem.add_thought("Detuvieron a %s por el soplo a la comisaría (-10)" % b_name, -10.0)
				if mem.errand_kind in ["familia_meet", "familia_errand"]:
					mem.end_errand()
			npc._spawn_floating_text("⚖️ «Buen trabajo. Se acabaron sus cobros por ahora (+%d Oro de recompensa).»" % reward, Color.GOLD, -44.0)
			VillageChronicle.add(vm, "familia_reported", "Delataste ante %s los tratos del reservado de %s (+%d Oro)" % [npc.npc_name, b_name, reward], true)
			return true
		"familia_ask_work":
			if boss == null or npc != boss or not is_boss_known_to_player(vm) or bool(st.get("reported_by_player", false)):
				return false
			var target = null
			var best_g: int = PROTECTION_FEE - 1
			for n in VillageNeeds.living(vm):
				if can_target_merchant(vm, n) and int(n.personal_gold) > best_g:
					best_g = int(n.personal_gold)
					target = n
			if target == null:
				for n2 in VillageNeeds.living(vm):
					if _can_be_member(n2) and not is_member(vm, n2) and int(n2.personal_gold) > best_g:
						best_g = int(n2.personal_gold)
						target = n2
			if target == null:
				npc._spawn_floating_text("🍷 «Hoy no hay nadie con la bolsa lo bastante llena. Vuelve otro día.»", Color(0.9, 0.8, 0.65), -40.0)
				return false
			st["player_job_target"] = target.get_person_key()
			st["player_job_collected"] = false
			npc._spawn_floating_text("🍷 «Pásate a ver a %s, cóbrale %d de oro por su tranquilidad y tráeme mi mitad.»" % [target.npc_name, PROTECTION_FEE], Color(0.95, 0.82, 0.58), -44.0)
			return true
		"familia_player_extort":
			return player_collect_protection(vm, npc, inv, force_roll) != ""
		"familia_deliver_cut":
			if boss == null or npc != boss or not bool(st.get("player_job_collected", false)):
				return false
			var cut: int = PROTECTION_FEE / 2
			if inv == null or int(inv.gold) < cut:
				npc._spawn_floating_text("😠 «¿Dónde está mi parte (%d de oro)? Con la Familia no se juega.»" % cut, Color.ORANGE_RED, -42.0)
				return false
			inv.add_gold(-cut)
			npc.personal_gold += cut
			st["player_job_target"] = ""
			st["player_job_collected"] = false
			st["business_done"] = int(st.get("business_done", 0)) + 1
			npc.modify_affinity(8)
			npc.add_thought("El forastero cumplió el encargo y trajo mi parte sin hacer preguntas (+6)", 6.0)
			npc._spawn_floating_text("🍷 «Un trabajo limpio (-%d Oro para el jefe, te quedas tu mitad).»" % cut, Color.SPRING_GREEN, -44.0)
			return true
	return false
