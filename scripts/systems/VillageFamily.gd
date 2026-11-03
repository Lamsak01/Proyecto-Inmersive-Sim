@tool
extends RefCounted

## V9: hijos.
## - Una pareja con casa puede esperar un hijo. Cuenta su edad (ella de 18 a 42), lo bien que se llevan, el dinero de
##   la casa, el humor y cuántos hijos tienen ya (como mucho 3). No hay fecha fija: cada día es una posibilidad pequeña.
## - El embarazo dura 9 días. El bebé nace en casa (oficio `CHILD`), con el apellido del padre y rasgos heredados (uno
##   de cada progenitor, si no chocan; el resto al azar).
## - Los niños crecen un año cada 4 días (provisional, para que se vea en una partida). Desde los 6 van a la escuela
##   entre semana de 9 a 14 h si hay maestro; el resto del tiempo juegan y van con su familia. Dibujo de adulto más
##   pequeño mientras no haya uno propio.
## - A los 16 son jóvenes sin oficio (`UNEMPLOYED`): siguen en casa de sus padres y buscan su sitio como cualquiera
##   (jornales, tiendas vacantes, casa propia).
## - Maestro: cuando hay 2 o más niños en edad escolar y no hay maestro, se hace maestro un vecino sin oficio (mejor si es
##   curioso o paciente) o, si no hay nadie, llega uno de fuera. Cobra 5 de oro al día de las arcas.
## Los niños no se emparejan, no se pelean, no votan ni se presentan y no entran en la secta (ver los filtros de edad).
## Estado en `vm.family_state` (se guarda).

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

const MOTHER_AGE: Vector2i = Vector2i(18, 42)
const PREGNANCY_DAYS: int = 9
const CHILD_YEAR_DAYS: int = 4
const ADULT_AGE: int = 16
const SCHOOL_AGE: int = 6
const MAX_CHILDREN: int = 3
const BIRTH_GAP_DAYS: int = 40
const BASE_CHANCE: float = 0.012
const MIN_COUPLE_REL: int = 30
const TEACHER_PAY: int = 5
const MIN_PUPILS_FOR_TEACHER: int = 2

static func state(vm) -> Dictionary:
	if not vm.family_state is Dictionary:
		vm.family_state = {}
	var defs: Dictionary = {"pregnancies": {}, "born": {}, "last_birth": {}, "births": 0, "grown_up": 0, "teacher": "",
		"lessons": 0, "teacher_unpaid": 0}
	for k in defs.keys():
		if not vm.family_state.has(k):
			vm.family_state[k] = defs[k]
	return vm.family_state

static func today() -> int:
	return int(WorldClock.current_day) if WorldClock else 1

static func by_key(vm) -> Dictionary:
	var d: Dictionary = {}
	for n in VillageNeeds.living(vm):
		d[n.get_person_key()] = n
	return d

static func is_child(n) -> bool:
	return int(n.trade_role) == int(VillageNPC.TradeRole.CHILD)

static func children_of_family(vm, fam: String) -> Array:
	return VillageNeeds.living(vm).filter(func(n): return is_child(n) and n.family_id == fam)

# ---------------------------------------------------------------- embarazo
static func _couple_key(a, b) -> String:
	var ka: String = a.get_person_key()
	var kb: String = b.get_person_key()
	return ka + "|" + kb if ka < kb else kb + "|" + ka

static func _has_home(n) -> bool:
	return n.family_id != "none" and n.family_id != "" and not n.is_vagrant_camper and not n.in_shelter

## Posibilidad de que esta pareja espere un hijo hoy (0 si no puede).
static func conceive_chance(vm, mother, father) -> float:
	if mother == null or father == null or mother.person_profile == null or father.person_profile == null:
		return 0.0
	if str(mother.person_profile.gender) != "F" or str(father.person_profile.gender) == "F":
		return 0.0
	var age: int = int(mother.person_profile.age)
	if age < MOTHER_AGE.x or age > MOTHER_AGE.y or int(father.person_profile.age) < 18:
		return 0.0
	if VillageNeeds.is_outsider(mother) or VillageNeeds.is_outsider(father) or not _has_home(mother) or mother.sick_level >= 2:
		return 0.0
	var st: Dictionary = state(vm)
	if (st["pregnancies"] as Dictionary).has(mother.get_person_key()):
		return 0.0
	if today() - int(st["last_birth"].get(_couple_key(mother, father), -999)) < BIRTH_GAP_DAYS:
		return 0.0
	if children_of_family(vm, mother.family_id).size() >= MAX_CHILDREN:
		return 0.0
	var rel: float = 0.5 * float(mother.get_relationship_with_npc(father.get_person_key()) + father.get_relationship_with_npc(mother.get_person_key()))
	if rel < MIN_COUPLE_REL:
		return 0.0
	var c: float = BASE_CHANCE * clampf(rel / 60.0, 0.5, 1.5)
	var gold: int = int(mother.personal_gold) + int(father.personal_gold)
	c *= 0.3 if gold < 30 else (1.0 if gold < 150 else 1.2)
	if float(mother.mood) < 35.0:
		c *= 0.5
	if age > 35:
		c *= 0.6
	c *= 1.0 - 0.3 * float(children_of_family(vm, mother.family_id).size())
	return clampf(c, 0.0, 0.05)

static func start_pregnancy(vm, mother, father) -> void:
	state(vm)["pregnancies"][mother.get_person_key()] = {"father": father.get_person_key(), "due": today() + PREGNANCY_DAYS}
	mother.add_thought("¡Vamos a tener un hijo! (+12)", 12.0)
	father.add_thought("¡Vamos a tener un hijo! (+12)", 12.0)
	vm.VillageChronicle.add(vm, "pregnancy", "%s y %s esperan un hijo" % [mother.npc_name, father.npc_name], true)

static func try_conceptions(vm) -> int:
	var people: Dictionary = by_key(vm)
	var started: int = 0
	for n in people.values():
		if n.person_profile == null or str(n.person_profile.gender) != "F" or str(n.person_profile.partner_id) == "":
			continue
		var partner = null
		for o in people.values():
			if o.person_profile != null and str(o.person_profile.person_id) == str(n.person_profile.partner_id):
				partner = o
				break
		if randf() < conceive_chance(vm, n, partner):
			start_pregnancy(vm, n, partner)
			started += 1
	return started

# ---------------------------------------------------------------- nacimiento
static func _surname(n) -> String:
	var parts: PackedStringArray = str(n.npc_name).strip_edges().split(" ", false)
	return parts[parts.size() - 1] if parts.size() > 1 else ""

static func inherited_traits(mother, father) -> Array[String]:
	var keep: Array = []
	for p in [mother, father]:
		if p != null and p.person_profile != null and not p.person_profile.personality.is_empty():
			keep.append(str(p.person_profile.personality[randi() % p.person_profile.personality.size()]))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return TraitCatalog.roll_balanced(rng, keep)

static func child_scale(age: int) -> float:
	return clampf(0.55 + 0.028 * float(age), 0.55, 1.0)

static func apply_look(n) -> void:
	if not is_child(n) or n.person_profile == null:
		n.scale = Vector2.ONE
		return
	n.scale = Vector2.ONE * child_scale(int(n.person_profile.age))

## Crea un niño de esta familia. `age` 0 = recién nacido aquí; mayor que 0 = llega al valle con sus padres (V3).
static func spawn_child(vm, mother, father, age: int = 0):
	var st: Dictionary = state(vm)
	var log_size: int = vm.social_event_log.size()
	var tex: Texture2D = vm._load_tex("res://assests/world/village/villager_traveler.png")
	var bed: Vector2 = mother.bed_position + Vector2(16, 6 + 6 * children_of_family(vm, mother.family_id).size())
	var kid = vm._spawn_generated_newcomer("NPC_Child_", VillageNPC.TradeRole.CHILD, VillageNPC.TradeRole.CHILD, "Criatura del valle",
		tex, mother.home_table_pos, bed, {}, mother.home_table_pos, mother.family_id, mother.family_name)
	if age == 0:
		while vm.social_event_log.size() > log_size:
			vm.social_event_log.pop_back() # No «llegó al valle»: ha nacido aquí
	var sur: String = _surname(father) if father != null else _surname(mother)
	var first: String = str(kid.npc_name).split(" ", false)[0]
	kid.npc_name = first + (" " + sur if sur != "" else "")
	kid.npc_role = "Hija del valle" if kid.person_profile != null and str(kid.person_profile.gender) == "F" else "Hijo del valle"
	kid.global_position = mother.global_position + Vector2(10, 4)
	kid.personal_gold = 0
	if kid.person_profile != null:
		kid.person_profile.age = age
		kid.person_profile.personality = inherited_traits(mother, father)
	st["born"][kid.get_person_key()] = today() - age * CHILD_YEAR_DAYS
	for p in [mother, father]:
		if p != null:
			p.modify_npc_relationship(kid, 80, "Es mi hijo", true)
			kid.modify_npc_relationship(p, 80, "Es mi madre o mi padre", true)
			if age == 0:
				p.add_thought("Ha nacido nuestro bebé (+20)", 20.0)
	for sib in children_of_family(vm, mother.family_id):
		if sib != kid:
			sib.modify_npc_relationship(kid, 40, "Es mi hermano", true)
			kid.modify_npc_relationship(sib, 40, "Es mi hermano", true)
	apply_look(kid)
	return kid

static func give_birth(vm, mother, father):
	var st: Dictionary = state(vm)
	var kid = spawn_child(vm, mother, father, 0)
	st["births"] = int(st["births"]) + 1
	if father != null:
		st["last_birth"][_couple_key(mother, father)] = today()
	vm.VillageChronicle.add(vm, "birth", "Ha nacido %s, hijo de %s%s" % [kid.npc_name, mother.npc_name, (" y " + father.npc_name) if father != null else ""], true)
	vm.record_social_event("birth", kid, mother, "%s nació en el valle" % kid.npc_name)
	return kid

## Casa a dos vecinos (pareja estable).
static func marry(a, b) -> void:
	if a.person_profile == null or b.person_profile == null:
		return
	a.person_profile.partner_id = str(b.person_profile.person_id)
	b.person_profile.partner_id = str(a.person_profile.person_id)
	a.person_profile.romance_status = "partnered"
	b.person_profile.romance_status = "partnered"

static func process_births(vm) -> int:
	var st: Dictionary = state(vm)
	var people: Dictionary = by_key(vm)
	var born: int = 0
	for mk in (st["pregnancies"] as Dictionary).keys():
		var p: Dictionary = st["pregnancies"][mk]
		var mother = people.get(mk)
		if mother == null:
			st["pregnancies"].erase(mk) # La madre murió o se fue
			continue
		if today() >= int(p["due"]):
			give_birth(vm, mother, people.get(str(p["father"])))
			st["pregnancies"].erase(mk)
			born += 1
	return born

# ---------------------------------------------------------------- crecer
static func update_ages(vm) -> int:
	var st: Dictionary = state(vm)
	var grown: int = 0
	for n in VillageNeeds.living(vm):
		if not is_child(n) or n.person_profile == null:
			continue
		var k: String = n.get_person_key()
		if not (st["born"] as Dictionary).has(k):
			st["born"][k] = today() - int(n.person_profile.age) * CHILD_YEAR_DAYS
		n.person_profile.age = mini(ADULT_AGE, int((today() - int(st["born"][k])) / CHILD_YEAR_DAYS))
		if int(n.person_profile.age) >= ADULT_AGE:
			grow_up(vm, n)
			grown += 1
		else:
			apply_look(n)
	return grown

static func grow_up(vm, n) -> void:
	var st: Dictionary = state(vm)
	n.trade_role = VillageNPC.TradeRole.UNEMPLOYED
	n.linked_trade = VillageNPC.TradeRole.UNEMPLOYED
	n.npc_role = "Joven del valle"
	n.person_profile.age = ADULT_AGE
	n.work_position = n.home_table_pos
	n.lodging = "family" # Sigue en casa de sus padres (no paga posada; VillageMigration lo puede mudar a una casa libre)
	if n.has_meta("school_pos"):
		n.remove_meta("school_pos")
	st["born"].erase(n.get_person_key())
	st["grown_up"] = int(st["grown_up"]) + 1
	# Sus padres le dan algo para empezar
	for o in VillageNeeds.living(vm):
		if o.family_id == n.family_id and o != n and not is_child(o) and o.personal_gold >= 30:
			o.personal_gold -= 10
			n.personal_gold += 10
	# Si su madre o su padre lleva un negocio sin ayudante, se queda a ayudar en la familia (y lo heredará)
	var helper_role: int = -1
	for o in VillageNeeds.living(vm):
		if o.family_id == n.family_id and o != n and o.trade_role in VillageNPC.SHOP_ROLES:
			var kin = vm.family_npcs.get(int(o.trade_role))
			if kin == null or not is_instance_valid(kin) or kin.is_dead:
				helper_role = int(o.trade_role)
				n.work_position = o.work_position + Vector2(-24, 4)
				break
	if helper_role >= 0:
		n.trade_role = VillageNPC.TradeRole.FAMILY_MEMBER
		n.linked_trade = helper_role as VillageNPC.TradeRole
		n.npc_role = "Ayudante de la familia"
		vm.family_npcs[helper_role] = n
		n.add_thought("Ya soy mayor: ayudo en el negocio de casa (+6)", 6.0)
	else:
		if not vm.unemployed_npcs.has(n):
			vm.unemployed_npcs.append(n)
		n.add_thought("Ya soy mayor: me toca buscarme la vida (+5)", 5.0)
	apply_look(n)
	vm.VillageChronicle.add(vm, "grown_up", "%s ya es mayor y busca su sitio en el valle" % n.npc_name, true)

# ---------------------------------------------------------------- escuela
static func school_lot_ready(vm) -> bool:
	return str(VillageLots.lot(vm, "e3").get("kind", "")) == "school"

static func desk_pos(i: int) -> Vector2:
	var c: Vector2 = VillageLots.building_center("e3")
	var m: float = -1.0 if bool(VillageLots.lot_def("e3")["door_south"]) else 1.0
	var desks: Array = [Vector2(-30, 6), Vector2(0, 6), Vector2(30, 6), Vector2(-30, 26), Vector2(0, 26), Vector2(30, 26)]
	var d: Vector2 = desks[i % desks.size()]
	return c + Vector2(d.x + float(i / desks.size()) * 8.0, (d.y + 6.0) * m)

static func teacher_pos() -> Vector2:
	var m: float = -1.0 if bool(VillageLots.lot_def("e3")["door_south"]) else 1.0
	return VillageLots.building_center("e3") + Vector2(0, -18 * m)

static func pupils(vm) -> Array:
	return VillageNeeds.living(vm).filter(func(n): return is_child(n) and n.person_profile != null and int(n.person_profile.age) >= SCHOOL_AGE)

static func teacher_of(vm):
	var t = by_key(vm).get(str(state(vm)["teacher"]))
	if t != null and int(t.trade_role) == int(VillageNPC.TradeRole.TEACHER):
		return t
	return null

static func _teacher_score(n) -> float:
	var s: float = TraitCatalog.npc_tendency(n, "diligence") + randf_range(0.0, 0.3)
	if n.person_profile != null:
		for t in ["Curioso", "Paciente"]:
			if t in n.person_profile.personality:
				s += 1.0
	return s

static func make_teacher(vm, n) -> void:
	n.trade_role = VillageNPC.TradeRole.TEACHER
	n.linked_trade = VillageNPC.TradeRole.TEACHER
	n.npc_role = "Maestra de la Escuela" if n.person_profile != null and str(n.person_profile.gender) == "F" else "Maestro de la Escuela"
	n.work_position = teacher_pos()
	vm.unemployed_npcs.erase(n)
	state(vm)["teacher"] = n.get_person_key()
	n.add_thought("Me han dado la escuela (+10)", 10.0)
	vm.VillageChronicle.add(vm, "teacher", "%s es ahora quien enseña en la escuela" % n.npc_name, true)

## Hace falta maestro si hay bastantes niños en edad escolar.
static func ensure_teacher(vm):
	if not school_lot_ready(vm) or teacher_of(vm) != null or pupils(vm).size() < MIN_PUPILS_FOR_TEACHER:
		return teacher_of(vm)
	var best = null
	var best_s: float = -INF
	for n in VillageNeeds.living(vm):
		if int(n.trade_role) != int(VillageNPC.TradeRole.UNEMPLOYED) or VillageNeeds.is_outsider(n) or n.is_downed or n.has_meta("leaving"):
			continue
		if n.person_profile == null or int(n.person_profile.age) < 20:
			continue
		var s: float = _teacher_score(n)
		if s > best_s:
			best_s = s
			best = n
	if best == null and vm.VillageMigration.population(vm) < vm.VillageMigration.POP_CAP and vm.arrivals_today_count < vm.MAX_DAILY_ARRIVALS:
		best = vm.VillageMigration._spawn_one(vm, {"label": "Maestro Recién Llegado", "gold": Vector2i(20, 40)}, 1)
		vm.VillageMigration.move_into_house(vm, best)
	if best != null:
		make_teacher(vm, best)
	return best

## Cada día: quién va a la escuela (solo si hay maestro) y el sueldo del maestro.
static func update_school(vm, pay: bool = true) -> void:
	var t = ensure_teacher(vm)
	var i: int = 0
	for n in VillageNeeds.living(vm):
		if not is_child(n):
			continue
		var goes: bool = t != null and n.person_profile != null and int(n.person_profile.age) >= SCHOOL_AGE
		if goes:
			n.set_meta("school_pos", desk_pos(i))
			n.work_position = desk_pos(i)
			i += 1
		else:
			if n.has_meta("school_pos"):
				n.remove_meta("school_pos")
			n.work_position = n.home_table_pos
	var school_lbl = vm.get_meta("school_sign", null)
	if school_lbl != null and is_instance_valid(school_lbl):
		school_lbl.text = ("Abierta · %s · %d alumnos" % [t.npc_name, i]) if t != null else "Esperando alumnos"
	if pay and t != null and not (WorldClock != null and WorldClock.has_method("is_weekend") and WorldClock.is_weekend()):
		var ts: Dictionary = vm.town_state
		if int(ts.get("treasury", 0)) >= TEACHER_PAY:
			ts["treasury"] = int(ts["treasury"]) - TEACHER_PAY
			t.personal_gold += TEACHER_PAY
		else:
			state(vm)["teacher_unpaid"] = int(state(vm)["teacher_unpaid"]) + TEACHER_PAY
			t.add_thought("Las arcas no me pagan la escuela (-6)", -6.0)

## 14 h: los niños que estaban en clase aprenden algo.
static func on_hour(vm, hour: int) -> void:
	if hour != 14 or teacher_of(vm) == null:
		return
	var st: Dictionary = state(vm)
	for n in pupils(vm):
		if n.has_meta("school_pos") and n.global_position.distance_to(n.get_meta("school_pos")) < 60.0:
			st["lessons"] = int(st["lessons"]) + 1
			n.add_thought("Hoy aprendí algo en la escuela (+3)", 3.0)

# ---------------------------------------------------------------- cada día
static func daily(vm) -> void:
	update_ages(vm)
	process_births(vm)
	try_conceptions(vm)
	update_school(vm)

## Al cargar: tamaños y pupitres (las marcas no se guardan).
static func after_load(vm) -> void:
	for n in VillageNeeds.living(vm):
		apply_look(n)
	update_school(vm, false)
