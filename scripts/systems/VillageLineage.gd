@tool
extends RefCounted
const _AN_SITIOS = preload("res://mapa/anclas.gd") # plan de sitios: sitios al aire libre siguen a lo movido

## Bloque P3: Hijos secretos, romances prohibidos y vida familiar (10 mecánicas).
## 1) Embarazo fruto de una infidelidad (el marido cree que es suyo mientras la aventura siga en secreto).
## 2) Rasgo heredado del amante que despierta sospechas y rumores al crecer el niño.
## 3) Chantaje de paternidad (exigir oro a la madre o al amante por guardar el secreto).
## 4) Reclamar o repudiar al niño (reacción del marido al enterarse y decisión del padre biológico).
## 5) Manutención secreta semanal (el padre biológico pasa oro a escondidas; si lo ven, se descubre).
## 6) Bebé dejado en la puerta de la Capilla del Alba (expósito cuidado por el sacerdote).
## 7) Adopción de huérfanos y expósitos (por parejas sin hijos o por el propio jugador).
## 8) Disputa entre hermanastros al hacerse mayores por heredar el puesto familiar.
## 9) Matrimonio por interés (un codicioso corteja a un rico o noble solo por su fortuna).
## 10) Pasado familiar fuera del valle (un recién llegado al que le reclaman una familia o deuda anterior).
## Estado en `vm.family_state["lineage"]` (se guarda automáticamente con `family_state`).

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageSecrets = preload("res://scripts/systems/VillageSecrets.gd")
const VillageClans = preload("res://scripts/systems/VillageClans.gd")

const AFFAIR_PREG_CHANCE: float = 0.03
const BLACKMAIL_GOLD: int = 20
const SUPPORT_GOLD: int = 5
const PAST_DEBT_GOLD: int = 25
const ARRANGED_DOWRY: int = 30
const MIRADOR_POS: Vector2 = Vector2(-520.0, -290.0)

static func state(vm) -> Dictionary:
	if not (vm.family_state is Dictionary):
		vm.family_state = {}
	if not vm.family_state.has("lineage") or not (vm.family_state["lineage"] is Dictionary):
		vm.family_state["lineage"] = {}
	var st: Dictionary = vm.family_state["lineage"]
	for k in ["secret_preg", "bastards", "foundlings", "sibling_rivalries", "gold_diggers", "estranged_past", "love_letters", "arranged_marriages", "godparents", "mentored_kids"]:
		if not st.has(k) or not (st[k] is Dictionary):
			st[k] = {}
	return st

static func today() -> int:
	return int(WorldClock.current_day) if WorldClock else 1

# ==============================================================================
# P3.1, P3.2 y P3.6: Concepción por aventura, nacimiento de hijo secreto y expósitos
# ==============================================================================
static func try_affair_conceptions(vm) -> int:
	var st: Dictionary = state(vm)
	var fam_st: Dictionary = vm.VillageFamily.state(vm)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var started: int = 0
	for s in vm.secrets:
		if not bool(s.get("active", false)) or str(s.get("type", "")) != "affair":
			continue
		var a = by_key.get(str(s["a"]), null)
		var b = by_key.get(str(s["b"]), null)
		if a == null or b == null or a.is_dead or b.is_dead or a.person_profile == null or b.person_profile == null:
			continue
		if str(a.person_profile.gender) == str(b.person_profile.gender):
			continue
		var mother = a if str(a.person_profile.gender) == "F" else b
		var lover = b if mother == a else a
		var mk: String = mother.get_person_key()
		if (fam_st["pregnancies"] as Dictionary).has(mk):
			continue
		var age: int = int(mother.person_profile.age)
		if age < 18 or age > 42 or int(lover.person_profile.age) < 18:
			continue
		if randf() < AFFAIR_PREG_CHANCE:
			var partner_key: String = str(mother.person_profile.partner_id)
			var partner = by_key.get(partner_key, null)
			var official_father = partner if partner != null else lover
			vm.VillageFamily.start_pregnancy(vm, mother, official_father)
			st["secret_preg"][mk] = {
				"mother_key": mk, "mother_name": mother.npc_name,
				"real_father": lover.get_person_key(), "real_father_name": lover.npc_name,
				"presumed_father": partner_key, "presumed_name": partner.npc_name if partner else "",
				"secret_id": int(s["id"]), "player_knows": bool(s.get("player_knows", false))
			}
			started += 1
	return started

## Llamado desde `VillageFamily.give_birth` al nacer un bebé.
static func on_child_born(vm, mother, presumed_father, kid) -> void:
	if vm == null or mother == null or kid == null:
		return
	var st: Dictionary = state(vm)
	var mk: String = mother.get_person_key()
	var kk: String = kid.get_person_key()
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	# P3.1: ¿Era embarazo de un amante secreto?
	if (st["secret_preg"] as Dictionary).has(mk):
		var sp: Dictionary = st["secret_preg"][mk]
		st["secret_preg"].erase(mk)
		var real_f = by_key.get(str(sp.get("real_father", "")), null)
		var trait_from_lover: String = ""
		if real_f != null and real_f.person_profile != null and not real_f.person_profile.personality.is_empty():
			trait_from_lover = str(real_f.person_profile.personality[0])
			if kid.person_profile != null and not (trait_from_lover in kid.person_profile.personality):
				if kid.person_profile.personality.size() >= 6:
					kid.person_profile.personality[kid.person_profile.personality.size() - 1] = trait_from_lover
				else:
					kid.person_profile.personality.append(trait_from_lover)
		if real_f != null:
			real_f.modify_npc_relationship(kid, 65, "Es mi hijo secreto", true)
		st["bastards"][kk] = {
			"kid_key": kk, "kid_name": kid.npc_name,
			"mother_key": mk, "mother_name": mother.npc_name,
			"real_father": str(sp.get("real_father", "")), "real_father_name": str(sp.get("real_father_name", "")),
			"presumed_father": str(sp.get("presumed_father", "")), "presumed_name": str(sp.get("presumed_name", "")),
			"trait": trait_from_lover, "player_knows": bool(sp.get("player_knows", false)),
			"revealed": false, "blackmailed": false, "rumored": false
		}
	# P3.6: Si la madre no tiene pareja ni recursos (mendiga o en la calle), puede dejar al bebé en la Capilla del Alba
	if (presumed_father == null or str(mother.person_profile.partner_id) == "") and (mother.is_vagrant_camper or int(mother.personal_gold) < 10):
		leave_foundling_at_chapel(vm, mother, kid)
	# Tanda 3 (12): Padrinos en el bautizo (amigo cercano de la familia o el jugador si hay gran aprecio)
	var gp = null
	var best_rel: int = 25
	for o in VillageNeeds.living(vm):
		if o != mother and o != presumed_father and o != kid and int(o.trade_role) != int(VillageNPC.TradeRole.CHILD) and str(o.family_id) != str(mother.family_id):
			var r: int = mother.get_relationship_with_npc(o.get_person_key())
			if r > best_rel:
				best_rel = r
				gp = o
	if int(mother.affinity) >= 60:
		st["godparents"][kk] = {"kid_key": kk, "kid_name": kid.npc_name, "godparent_key": "player", "godparent_name": "Jugador"}
	elif gp != null:
		st["godparents"][kk] = {"kid_key": kk, "kid_name": kid.npc_name, "godparent_key": gp.get_person_key(), "godparent_name": gp.npc_name}
		gp.modify_npc_relationship(kid, 45, "Soy su padrino de bautizo", true)
		kid.modify_npc_relationship(gp, 45, "Es mi padrino de bautizo", true)

static func leave_foundling_at_chapel(vm, mother, kid) -> void:
	var st: Dictionary = state(vm)
	var kk: String = kid.get_person_key()
	kid.family_id = "family_chapel"
	kid.family_name = "Capilla del Alba"
	kid.bed_position = vm.sitio(vm._church_altar_pos + Vector2(24, 16))
	kid.home_table_pos = vm.sitio(vm._church_center + Vector2(0, 12))
	kid.work_position = kid.home_table_pos
	st["foundlings"][kk] = {"kid_key": kk, "kid_name": kid.npc_name, "mother_key": mother.get_person_key() if mother else "", "day": today()}
	var priest = vm.VillageFaith.priest_of(vm)
	if priest != null:
		priest.modify_npc_relationship(kid, 70, "Criatura acogida en la capilla", true)
		kid.modify_npc_relationship(priest, 75, "Me cuida en la capilla", true)
	VillageChronicle.add(vm, "foundling", "Dejaron al pequeño %s en la puerta de la Capilla del Alba para que lo cuide el sacerdote" % kid.npc_name, true)

# ==============================================================================
# P3.2, P3.4 y P3.5: Rumor por rasgo heredado, revelar paternidad y manutención
# ==============================================================================
static func reveal_paternity(vm, kk: String, how: String) -> void:
	var st: Dictionary = state(vm)
	if not (st["bastards"] as Dictionary).has(kk):
		return
	var b: Dictionary = st["bastards"][kk]
	if bool(b.get("revealed", false)):
		return
	b["revealed"] = true
	b["player_knows"] = true
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var kid = by_key.get(kk, null)
	var mother = by_key.get(str(b["mother_key"]), null)
	var pres = by_key.get(str(b["presumed_father"]), null)
	var real_f = by_key.get(str(b["real_father"]), null)
	if pres != null and mother != null:
		var forgive: bool = ("Indulgente" in (pres.person_profile.personality if pres.person_profile != null else [])) or pres.get_relationship_with_npc(mother.get_person_key()) >= 75
		if forgive:
			pres.add_thought("Perdoné el origen de %s y lo criaré como mío (+4)" % str(b["kid_name"]), 4.0)
			VillageChronicle.add(vm, "paternity_forgiven", "%s descubrió que %s es hijo de %s (%s), pero decidió perdonar y criarlo" % [pres.npc_name, str(b["kid_name"]), str(b["real_father_name"]), how], true)
			return
		# Ruptura y repudio
		pres.modify_npc_relationship(mother, -40, "Me hizo creer que %s era hijo mío" % str(b["kid_name"]), true)
		if real_f != null:
			pres.modify_npc_relationship(real_f, -45, "Es el verdadero padre de %s" % str(b["kid_name"]), true)
		if pres.person_profile != null and mother.person_profile != null and str(pres.person_profile.partner_id) == mother.get_person_key():
			pres.person_profile.partner_id = ""
			pres.person_profile.romance_status = "single"
			mother.person_profile.partner_id = ""
			mother.person_profile.romance_status = "single"
	# ¿El padre biológico lo reclama y le da su apellido?
	if real_f != null and kid != null:
		if TraitCatalog.npc_tendency(real_f, "honesty") + TraitCatalog.npc_tendency(real_f, "generosity") >= -0.2:
			var sur: String = vm.VillageFamily._surname(real_f)
			if sur != "":
				rename_child(vm, kid, sur)
			real_f.modify_npc_relationship(kid, 80, "Reconocí a mi hijo %s" % kid.npc_name, true)
			kid.modify_npc_relationship(real_f, 75, "Me reconoció como su hijo", true)
			VillageChronicle.add(vm, "paternity_claimed", "Se supo que %s es hijo de %s (%s); su padre biológico lo reconoció" % [kid.npc_name, real_f.npc_name, how], true)
		else:
			if mother != null:
				mother.modify_npc_relationship(real_f, -30, "Se desentendió de nuestro hijo %s" % kid.npc_name, true)
			VillageChronicle.add(vm, "paternity_denied", "Estalló el escándalo: %s es hijo de %s (%s), pero éste se negó a reconocerlo" % [str(b["kid_name"]), str(b["real_father_name"]), how], true)

## Cambia el apellido de un niño y sincroniza todos los registros que guardan su nombre (`vagrant_camp_nodes`, `npc_murders`, expedientes, deseos, secretos, misiones, etc.).
static func rename_child(vm, kid, new_surname: String) -> void:
	if vm == null or kid == null or new_surname.strip_edges() == "":
		return
	var first: String = str(kid.npc_name).split(" ", false)[0]
	var new_name: String = first + " " + new_surname.strip_edges()
	var old_name: String = str(kid.npc_name)
	if new_name == old_name or old_name == "":
		return
	kid.npc_name = new_name
	var st: Dictionary = state(vm)
	var kk: String = kid.get_person_key()
	if (st["bastards"] as Dictionary).has(kk):
		st["bastards"][kk]["kid_name"] = new_name
	if (st["foundlings"] as Dictionary).has(kk):
		st["foundlings"][kk]["kid_name"] = new_name
	if (st["godparents"] as Dictionary).has(kk):
		st["godparents"][kk]["kid_name"] = new_name
	if (st["mentored_kids"] as Dictionary).has(kk):
		st["mentored_kids"][kk]["kid_name"] = new_name
	for fam_k in (st["sibling_rivalries"] as Dictionary).keys():
		var sr: Dictionary = st["sibling_rivalries"][fam_k]
		if str(sr.get("a_name", "")) == old_name:
			sr["a_name"] = new_name
		if str(sr.get("b_name", "")) == old_name:
			sr["b_name"] = new_name
	if vm.vagrant_camp_nodes.has(old_name):
		vm.vagrant_camp_nodes[new_name] = vm.vagrant_camp_nodes[old_name]
		vm.vagrant_camp_nodes.erase(old_name)
	if vm.npc_murders.has(old_name):
		vm.npc_murders[new_name] = vm.npc_murders[old_name]
		vm.npc_murders.erase(old_name)
	for v_k in vm.npc_murders.keys():
		if str(vm.npc_murders[v_k]) == old_name:
			vm.npc_murders[v_k] = new_name
	for arr in [vm.morgue_active_corpses, vm.corpse_records, vm.buried_graves]:
		for entry in arr:
			if entry is Dictionary and str(entry.get("victim_name", "")) == old_name:
				entry["victim_name"] = new_name
	for case_d in [vm.active_sheriff_investigation, vm.active_royal_investigation]:
		if case_d is Dictionary and not case_d.is_empty():
			if str(case_d.get("victim_name", "")) == old_name:
				case_d["victim_name"] = new_name
			if str(case_d.get("reporter_name", "")) == old_name:
				case_d["reporter_name"] = new_name
			var sus: Dictionary = case_d.get("suspects", {})
			if sus.has(old_name):
				var s_entry: Dictionary = sus[old_name]
				s_entry["name"] = new_name
				sus[new_name] = s_entry
				sus.erase(old_name)
	for d in vm.desires:
		if d is Dictionary:
			if str(d.get("holder_name", "")) == old_name:
				d["holder_name"] = new_name
			if str(d.get("target_name", "")) == old_name:
				d["target_name"] = new_name
	for s in vm.secrets:
		if s is Dictionary:
			for nk in ["a_name", "b_name", "holder_name", "target_name"]:
				if str(s.get(nk, "")) == old_name:
					s[nk] = new_name
	for ev in vm.social_event_log:
		if ev is Dictionary:
			if str(ev.get("actor_name", "")) == old_name:
				ev["actor_name"] = new_name
			if str(ev.get("target_name", "")) == old_name:
				ev["target_name"] = new_name
	if "quests_state" in vm and vm.quests_state is Dictionary:
		for q_list_key in ["active", "offered"]:
			var q_arr = vm.quests_state.get(q_list_key, [])
			if q_arr is Array:
				for q in q_arr:
					if q is Dictionary:
						for qnk in ["giver_name", "target_name", "other_name"]:
							if str(q.get(qnk, "")) == old_name:
								q[qnk] = new_name
	if "VillageForensics" in vm and vm.VillageForensics != null:
		var fst: Dictionary = vm.VillageForensics.state(vm)
		for dict_k in ["planted", "alibis", "tampered", "hitmen", "poisoned", "moved", "slips", "scapegoats", "insurance", "tampered_time"]:
			var sub: Dictionary = fst.get(dict_k, {})
			if sub.has(old_name):
				sub[new_name] = sub[old_name]
				sub.erase(old_name)
			for sk in sub.keys():
				if sub[sk] is Dictionary:
					var sd: Dictionary = sub[sk]
					for fnk in ["framed_name", "killer_name", "ally_name", "witness_name", "mastermind_name", "hitman_name", "victim_name", "scapegoat_name", "beneficiary_name"]:
						if str(sd.get(fnk, "")) == old_name:
							sd[fnk] = new_name
	for n in VillageNeeds.living(vm):
		if n.npc_relationships.has(old_name):
			n.npc_relationships[kk] = n.npc_relationships[old_name]
			n.npc_relationships.erase(old_name)
		if n.npc_relationship_notes.has(old_name):
			n.npc_relationship_notes[kk] = n.npc_relationship_notes[old_name]
			n.npc_relationship_notes.erase(old_name)

static func _daily_paternity_and_support(vm) -> void:
	var st: Dictionary = state(vm)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var is_monday: bool = WorldClock != null and WorldClock.has_method("get_weekday") and int(WorldClock.get_weekday()) == 0
	var is_sunday: bool = WorldClock != null and WorldClock.has_method("get_weekday") and int(WorldClock.get_weekday()) == 6
	var pl = VillageNeeds.player_of(vm)
	# Tanda 3 (12): Padrinos de bautizo (propina dominical de 2 de oro de su bolsillo y adopción si queda huérfano)
	for gkk in (st["godparents"] as Dictionary).keys():
		var gp_info: Dictionary = st["godparents"][gkk]
		var g_kid = by_key.get(gkk, null)
		if g_kid == null or g_kid.is_dead:
			continue
		var gp_key: String = str(gp_info.get("godparent_key", ""))
		if gp_key != "player":
			var gp_npc = by_key.get(gp_key, null)
			if gp_npc != null and not gp_npc.is_dead:
				if is_sunday and int(gp_npc.personal_gold) >= 6:
					gp_npc.personal_gold -= 2
					g_kid.personal_gold += 2
				if is_orphan(vm, g_kid):
					adopt_child_by_couple(vm, gp_npc, g_kid)
	for kk in (st["bastards"] as Dictionary).keys():
		var b: Dictionary = st["bastards"][kk]
		if bool(b.get("revealed", false)):
			continue
		var kid = by_key.get(kk, null)
		var mother = by_key.get(str(b["mother_key"]), null)
		var real_f = by_key.get(str(b["real_father"]), null)
		if kid == null or kid.is_dead:
			continue
		# P3.5: Manutención secreta los lunes
		if is_monday and real_f != null and mother != null and int(real_f.personal_gold) >= 25:
			real_f.personal_gold -= SUPPORT_GOLD
			mother.personal_gold += SUPPORT_GOLD
			if pl is Node2D and (pl as Node2D).global_position.distance_to(mother.global_position) <= 160.0:
				b["player_knows"] = true
		# P3.2: Al crecer (>= 6 años), el rasgo heredado del amante despierta rumores entre chismosos
		if not bool(b.get("rumored", false)) and kid.person_profile != null and int(kid.person_profile.age) >= 6 and randf() < 0.15:
			b["rumored"] = true
			var ev: Dictionary = vm.record_social_event("paternity_doubt", mother, real_f, "Murmuran que %s tiene los mismos gestos que %s" % [kid.npc_name, str(b["real_father_name"])])
			ev["known_by"] = {}
			for n in VillageNeeds.living(vm):
				if TraitCatalog.npc_tendency(n, "gossip") >= 0.4:
					ev["known_by"][n.get_person_key()] = true
			VillageChronicle.add(vm, "paternity_rumor", "Por el pueblo murmuran que el pequeño %s se parece demasiado a %s" % [kid.npc_name, str(b["real_father_name"])], true)

# ==============================================================================
# P3.7 y P3.8: Adopción de huérfanos y Disputa de hermanastros al cumplir 16
# ==============================================================================
static func is_orphan(vm, kid) -> bool:
	if kid == null or not vm.VillageFamily.is_child(kid):
		return false
	if (state(vm)["foundlings"] as Dictionary).has(kid.get_person_key()):
		return true
	if str(kid.family_id) == "family_player":
		return false # ya es tu hijo adoptivo
	for o in VillageNeeds.living(vm):
		if o != kid and not vm.VillageFamily.is_child(o) and str(o.family_id) == str(kid.family_id) and str(kid.family_id) != "none":
			return false
	return true

static func adopt_child_by_couple(vm, adopter, kid) -> void:
	var st: Dictionary = state(vm)
	st["foundlings"].erase(kid.get_person_key())
	kid.family_id = adopter.family_id
	kid.family_name = adopter.family_name
	kid.home_table_pos = adopter.home_table_pos
	kid.bed_position = adopter.bed_position + Vector2(14, 8)
	var sur: String = vm.VillageFamily._surname(adopter)
	if sur != "":
		rename_child(vm, kid, sur)
	adopter.modify_npc_relationship(kid, 80, "Lo adoptamos como nuestro hijo", true)
	kid.modify_npc_relationship(adopter, 85, "Me dio un hogar y una familia", true)
	VillageChronicle.add(vm, "adoption", "%s adoptó al pequeño %s en su hogar" % [adopter.npc_name, kid.npc_name], true)

static func adopt_child_by_player(vm, kid) -> void:
	var st: Dictionary = state(vm)
	st["foundlings"].erase(kid.get_person_key())
	st["player_adopted"] = kid.get_person_key()
	kid.family_id = "family_player"
	kid.family_name = "Casa del Forastero"
	# Si tienes casa propia, el niño se muda a ella
	vm.VillageHousing.move_into_player_home(vm, kid, 1)
	kid.modify_affinity(85)
	kid.add_thought("¡Tengo una familia! (+25)", 25.0)
	VillageChronicle.add(vm, "player_adoption", "Adoptaste al pequeño %s como parte de tu hogar" % kid.npc_name, true)

## P3.8 y Tanda 3 (13): Llamado desde `VillageFamily.grow_up` cuando un joven cumple 16 años.
static func on_child_grown_up(vm, youth) -> void:
	var st: Dictionary = state(vm)
	var yk: String = youth.get_person_key()
	# Tanda 3 (13): Si le enseñaste un oficio de niño, empieza con experiencia y puesto de aprendiz
	if (st["mentored_kids"] as Dictionary).has(yk):
		youth.days_in_role = maxi(int(youth.days_in_role), 5)
		youth.modify_affinity(15)
		if int(youth.trade_role) == int(VillageNPC.TradeRole.UNEMPLOYED):
			for tr_id in vm.trade_npcs.keys():
				var master = vm.trade_npcs[tr_id]
				if master != null and is_instance_valid(master) and not vm.family_npcs.has(int(tr_id)):
					youth.trade_role = VillageNPC.TradeRole.FAMILY_MEMBER
					youth.linked_trade = master.trade_role
					vm.family_npcs[int(tr_id)] = youth
					vm.unemployed_npcs.erase(youth)
					break
		VillageChronicle.add(vm, "mentored_grown", "%s cumplió 16 años con el oficio que le enseñaste de niño" % youth.npc_name, true)
	var fam: String = str(youth.family_id)
	if not VillageClans.valid_family(fam):
		return
	for o in VillageNeeds.living(vm):
		if o != youth and str(o.family_id) == fam and int(o.trade_role) in [int(VillageNPC.TradeRole.FAMILY_MEMBER), int(VillageNPC.TradeRole.UNEMPLOYED)] and o.person_profile != null and int(o.person_profile.age) <= 24:
			youth.modify_npc_relationship(o, -25, "Competimos por heredar el taller familiar", true)
			o.modify_npc_relationship(youth, -25, "Quiere quitarme el puesto de la familia", true)
			st["sibling_rivalries"][fam] = {"a": o.get_person_key(), "a_name": o.npc_name, "b": youth.get_person_key(), "b_name": youth.npc_name, "resolved": false}
			VillageChronicle.add(vm, "sibling_rivalry", "Rivalidad entre los hermanos %s y %s por quién heredará el negocio familiar" % [o.npc_name, youth.npc_name], true)
			return

# ==============================================================================
# P3.9, P3.10 y Tanda 3 (11, 14): Matrimonio por interés, Bodas concertadas y Mirador
# ==============================================================================
static func send_lovers_to_mirador(vm) -> int:
	var cst: Dictionary = VillageClans.state(vm)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var sent: int = 0
	for pk in (cst["romeo_pairs"] as Dictionary).keys():
		var rp: Dictionary = cst["romeo_pairs"][pk]
		if bool(rp.get("helped", false)):
			continue
		var a = by_key.get(str(rp["a"]), null)
		var b = by_key.get(str(rp["b"]), null)
		if a != null and b != null and not a.is_dead and not b.is_dead:
			a.start_errand("mirador_escape", _AN_SITIOS.mover(MIRADOR_POS + Vector2(-8, 0)))
			b.start_errand("mirador_escape", _AN_SITIOS.mover(MIRADOR_POS + Vector2(8, 0)))
			rp["at_mirador"] = true
			sent += 1
	return sent

static func _daily_gold_diggers_and_past(vm) -> void:
	var st: Dictionary = state(vm)
	var sd = vm.social_director
	if sd == null:
		return
	# Tanda 3 (11): Bodas concertadas con dote por padres pudientes o nobles
	if (st["arranged_marriages"] as Dictionary).is_empty() and randf() < 0.25:
		for parent in VillageNeeds.living(vm):
			if int(parent.trade_role) == int(VillageNPC.TradeRole.CHILD) or not VillageClans.valid_family(str(parent.family_id)):
				continue
			if int(parent.personal_gold) < 60 and int(parent.trade_role) != int(VillageNPC.TradeRole.NOBLE):
				continue
			var youth = null
			for m in VillageClans.clan_members(vm, str(parent.family_id), parent):
				if m.person_profile != null and int(m.person_profile.age) >= 18 and str(m.person_profile.partner_id) == "":
					youth = m
					break
			if youth == null:
				continue
			for suitor in VillageNeeds.living(vm):
				if suitor == parent or suitor == youth or str(suitor.family_id) == str(parent.family_id):
					continue
				if suitor.person_profile != null and int(suitor.person_profile.age) >= 18 and str(suitor.person_profile.partner_id) == "" and str(suitor.person_profile.gender) != str(youth.person_profile.gender):
					st["arranged_marriages"][parent.get_person_key()] = {
						"parent_key": parent.get_person_key(), "parent_name": parent.npc_name,
						"youth_key": youth.get_person_key(), "youth_name": youth.npc_name,
						"suitor_key": suitor.get_person_key(), "suitor_name": suitor.npc_name,
						"dowry": ARRANGED_DOWRY, "resolved": false
					}
					break
			if not (st["arranged_marriages"] as Dictionary).is_empty():
				break
	# Tanda 3 (14): Si hay amantes prohibidos, se escapan al mirador
	if not (VillageClans.state(vm)["romeo_pairs"] as Dictionary).is_empty():
		send_lovers_to_mirador(vm)
	# P3.9: Un soltero pobre y codicioso corteja a un rico o noble por interés
	if (st["gold_diggers"] as Dictionary).size() < 2 and randf() < 0.12:
		for n in VillageNeeds.living(vm):
			if n.person_profile == null or int(n.person_profile.age) < 18 or str(n.person_profile.partner_id) != "" or int(n.personal_gold) >= 20:
				continue
			if (st["gold_diggers"] as Dictionary).has(n.get_person_key()):
				continue
			if TraitCatalog.npc_tendency(n, "ambition") - TraitCatalog.npc_tendency(n, "generosity") < 0.6:
				continue
			for rich in VillageNeeds.living(vm):
				if rich == n or rich.person_profile == null or str(rich.person_profile.partner_id) != "" or str(rich.person_profile.gender) == str(n.person_profile.gender):
					continue
				if int(rich.personal_gold) >= 130 or int(rich.trade_role) == int(VillageNPC.TradeRole.NOBLE):
					sd.add_spark_one_way(n.get_person_key(), rich.get_person_key(), 24)
					sd.add_spark_one_way(rich.get_person_key(), n.get_person_key(), 16)
					st["gold_diggers"][n.get_person_key()] = {"digger_key": n.get_person_key(), "digger_name": n.npc_name, "rich_key": rich.get_person_key(), "rich_name": rich.npc_name, "exposed": false}
					break
	# P3.10: Un recién llegado con pasado familiar oculto fuera del valle
	if (st["estranged_past"] as Dictionary).size() < 2 and randf() < 0.10:
		for n in VillageNeeds.living(vm):
			var k: String = n.get_person_key()
			if (st["estranged_past"] as Dictionary).has(k) or int(n.trade_role) == int(VillageNPC.TradeRole.CHILD):
				continue
			if n.has_meta("arrived_day") and today() - int(n.get_meta("arrived_day")) <= 12:
				st["estranged_past"][k] = {"npc_key": k, "npc_name": n.npc_name, "debt": PAST_DEBT_GOLD, "resolved": false}
				VillageChronicle.add(vm, "past_arrived", "Llegó un mensajero de otra comarca reclamando a %s una deuda familiar del pasado" % n.npc_name, true)
				break
	# Adopción automática por matrimonio sin hijos si queda un expósito en la capilla más de 5 días
	for fk in (st["foundlings"] as Dictionary).keys():
		var f: Dictionary = st["foundlings"][fk]
		if today() - int(f.get("day", today())) < 5:
			continue
		var kid = vm._get_npcs_by_person_key().get(fk, null)
		if kid == null:
			st["foundlings"].erase(fk)
			continue
		for n in VillageNeeds.living(vm):
			if n.person_profile != null and str(n.person_profile.partner_id) != "" and VillageClans.valid_family(str(n.family_id)) and vm.VillageFamily.children_of_family(vm, str(n.family_id)).is_empty():
				adopt_child_by_couple(vm, n, kid)
				break

static func _daily_love_letters(vm) -> void:
	var st: Dictionary = state(vm)
	for s in vm.secrets:
		if not bool(s.get("active", false)) or str(s.get("type", "")) != "affair":
			continue
		var sid: String = str(int(s.get("id", -1)))
		if not (st["love_letters"] as Dictionary).has(sid):
			st["love_letters"][sid] = {
				"secret_id": int(s["id"]), "sender_key": str(s["a"]), "sender_name": str(s["a_name"]),
				"receiver_key": str(s["b"]), "receiver_name": str(s["b_name"]),
				"intercepted": false, "handled": false
			}

static func daily(vm) -> void:
	try_affair_conceptions(vm)
	_daily_paternity_and_support(vm)
	_daily_gold_diggers_and_past(vm)
	_daily_love_letters(vm)

# ==============================================================================
# Diálogos con vecinos (P3.3, P3.4, P3.7, P3.8, P3.9, P3.10 + Tanda 2: 10)
# ==============================================================================
static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null or npc == null:
		return
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key()
	var fam: String = str(npc.family_id)
	var opts: Array = []

	# P3.3 y P3.4: Chantajear o revelar paternidad secreta
	for kk in (st["bastards"] as Dictionary).keys():
		var b: Dictionary = st["bastards"][kk]
		if bool(b.get("revealed", false)):
			continue
		if bool(b.get("player_knows", false)) or bool(b.get("rumored", false)):
			if (key == str(b["mother_key"]) or key == str(b["real_father"])) and not bool(b.get("blackmailed", false)):
				opts.append({"label": "🤫👶 Exigir %d de oro por callar quién es el padre de %s" % [BLACKMAIL_GOLD, str(b["kid_name"])], "next": "END", "action": "lineage_blackmail:" + kk})
			if key == str(b["presumed_father"]):
				opts.append({"label": "💔👶 Contarle que el pequeño %s es en realidad hijo de %s" % [str(b["kid_name"]), str(b["real_father_name"])], "next": "END", "action": "lineage_reveal:" + kk})

	# P3.7: Adoptar a un niño huérfano o expósito de la capilla (hablando con el niño o con el sacerdote)
	if is_orphan(vm, npc):
		opts.append({"label": "🏡👶 Adoptar a %s en tu hogar (-15 Oro para su ajuar)" % npc.npc_name, "next": "END", "action": "lineage_adopt:" + key})
	elif vm.VillageFaith.is_priest(npc):
		for fk in (st["foundlings"] as Dictionary).keys():
			var fn: String = str(st["foundlings"][fk]["kid_name"])
			opts.append({"label": "🏡👶 Adoptar al pequeño expósito %s de la capilla (-15 Oro)" % fn, "next": "END", "action": "lineage_adopt:" + fk})

	# P3.8: Mediar en disputa de hermanastros
	if (st["sibling_rivalries"] as Dictionary).has(fam) and not bool(st["sibling_rivalries"][fam].get("resolved", false)):
		var sr: Dictionary = st["sibling_rivalries"][fam]
		opts.append({"label": "⚖️👨‍👦 Respaldar a %s como heredero del taller familiar (hasta 15 Oro)" % str(sr["a_name"]), "next": "END", "action": "lineage_sibling_a:" + fam})
		opts.append({"label": "⚖️👨‍👦 Respaldar a %s como heredero del taller familiar (hasta 15 Oro)" % str(sr["b_name"]), "next": "END", "action": "lineage_sibling_b:" + fam})

	# P3.9: Avisar a un rico de un pretendiente cazafortunas
	for dk in (st["gold_diggers"] as Dictionary).keys():
		var gd: Dictionary = st["gold_diggers"][dk]
		if not bool(gd.get("exposed", false)) and key == str(gd["rich_key"]):
			opts.append({"label": "💸⚠️ Avisarle de que %s solo le corteja por su fortuna (hasta 20 Oro)" % str(gd["digger_name"]), "next": "END", "action": "lineage_digger:" + dk})

	# P3.10: Pasado familiar fuera del valle
	if (st["estranged_past"] as Dictionary).has(key) and not bool(st["estranged_past"][key].get("resolved", false)):
		opts.append({"label": "🤝💰 Ayudarle a saldar la deuda con su antigua familia (-%d Oro)" % PAST_DEBT_GOLD, "next": "END", "action": "lineage_past_help:" + key})
		opts.append({"label": "📢 Presionarle con su pasado oculto fuera del valle (hasta 15 Oro)", "next": "END", "action": "lineage_past_press:" + key})

	# Tanda 2 (10): Interceptar cartas de amantes (sin revelar al destinatario antes de interceptarla)
	var p_id: String = str(npc.person_profile.partner_id) if npc.person_profile != null else ""
	for sid in (st["love_letters"] as Dictionary).keys():
		var ll: Dictionary = st["love_letters"][sid]
		if bool(ll.get("handled", false)):
			continue
		if bool(ll.get("intercepted", false)):
			if key == str(ll["receiver_key"]):
				opts.append({"label": "✉️💘 Entregarle en secreto la carta de amor de %s (hasta 12 Oro)" % str(ll["sender_name"]), "next": "END", "action": "lineage_deliver_letter:" + sid})
			elif p_id != "" and (p_id == str(ll["sender_key"]) or p_id == str(ll["receiver_key"])):
				opts.append({"label": "✉️💔 Mostrarle la carta de amor entre %s y %s (hasta 15 Oro)" % [str(ll["sender_name"]), str(ll["receiver_name"])], "next": "END", "action": "lineage_expose_letter:" + sid})

	# Registrar bolsillos: se ofrece a cualquier adulto (una vez al día), así la opción no delata ninguna aventura
	if not vm.VillageFamily.is_child(npc) and not (int(npc.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)]):
		var srch: Dictionary = st.get("pocket_searched", {})
		if int(srch.get(key, -1)) != today():
			opts.append({"label": "🤏🕵️ Hurgar a escondidas en su bolsillo mientras está distraído", "next": "END", "action": "lineage_search_pocket:" + key})

	# Tanda 3 (11): Bodas concertadas con dote
	for apk in (st["arranged_marriages"] as Dictionary).keys():
		var am: Dictionary = st["arranged_marriages"][apk]
		if bool(am.get("resolved", false)):
			continue
		if key == str(am["parent_key"]):
			opts.append({"label": "💍💰 Mediar para cerrar la boda concertada de %s con %s (dote de %d Oro)" % [str(am["youth_name"]), str(am["suitor_name"]), int(am["dowry"])], "next": "END", "action": "lineage_arrange_wed:" + apk})
		elif key == str(am["youth_key"]):
			opts.append({"label": "💔🕊️ Ayudarle a rechazar la boda concertada con %s (hasta 12 Oro)" % str(am["suitor_name"]), "next": "END", "action": "lineage_arrange_refuse:" + apk})

	# Tanda 3 (12): Padrinos en el bautizo (ofrecerte como padrino si los padres te aprecian)
	if int(npc.affinity) >= 40 and VillageClans.valid_family(fam):
		for kid_c in vm.VillageFamily.children_of_family(vm, fam):
			var gkk: String = kid_c.get_person_key()
			if str((st["godparents"].get(gkk, {}) as Dictionary).get("godparent_key", "")) != "player":
				opts.append({"label": "🕯️👶 Ofrecerte como padrino de bautizo de %s (-10 Oro de regalo)" % kid_c.npc_name, "next": "END", "action": "lineage_become_godparent:" + gkk})

	# Tanda 3 (13): Enseñar un oficio a un niño
	if vm.VillageFamily.is_child(npc) and npc.person_profile != null and int(npc.person_profile.age) >= 7 and not (st["mentored_kids"] as Dictionary).has(key):
		opts.append({"label": "🛠️📚 Enseñarle nociones de oficio y comercio a %s (-10 Oro en herramientas)" % npc.npc_name, "next": "END", "action": "lineage_mentor_child:" + key})

	# Tanda 3 (14): Jóvenes que se escapan de noche al mirador (sin revelar en el menú con quién se ve)
	var cst_m: Dictionary = VillageClans.state(vm)
	for rpk in (cst_m["romeo_pairs"] as Dictionary).keys():
		var rp_m: Dictionary = cst_m["romeo_pairs"][rpk]
		if bool(rp_m.get("at_mirador", false)) and not bool(rp_m.get("mirador_seen", false)):
			if key == str(rp_m["a"]) or key == str(rp_m["b"]):
				opts.append({"label": "🌙👀 Preguntarle qué hace escapándose de noche al mirador del lago", "next": "END", "action": "lineage_catch_mirador:" + rpk})

	if not opts.is_empty():
		opts.append({"label": "⬅️ Volver", "next": "start"})
		diag["lineage_menu"] = {"text": "👶 Linaje, hijos secretos y secretos de familia:", "choices": opts}
		ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "👶 Linaje y secretos de familia…", "next": "lineage_menu"})

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	var st: Dictionary = state(vm)
	var arg: String = action_id.get_slice(":", 1)
	var by_key: Dictionary = vm._get_npcs_by_person_key()

	if action_id.begins_with("lineage_blackmail:"):
		if not (st["bastards"] as Dictionary).has(arg):
			return
		var b: Dictionary = st["bastards"][arg]
		b["blackmailed"] = true
		var pay: int = VillageClans.pay_from_pocket(npc, BLACKMAIL_GOLD, inv)
		npc.modify_affinity(-18)
		npc._spawn_floating_text("😰 «Toma %d de oro, pero ni una palabra a nadie sobre el niño...»" % pay, Color.GOLD, -46.0)

	elif action_id.begins_with("lineage_reveal:"):
		reveal_paternity(vm, arg, "se lo contaste tú")
		npc._spawn_floating_text("💔 «¿Qué estás diciendo...? ¡No puede ser!»", Color.ORANGE_RED, -46.0)

	elif action_id.begins_with("lineage_adopt:"):
		if inv == null or int(inv.gold) < 15:
			npc._spawn_floating_text("Necesitas 15 de oro para el ajuar del niño", Color.ORANGE_RED, -44.0)
			return
		var kid = by_key.get(arg, null)
		if kid == null:
			return
		inv.add_gold(-15)
		kid.personal_gold += 15
		adopt_child_by_player(vm, kid)
		npc.modify_affinity(20)
		npc._spawn_floating_text("🏡👶 «¡Cuidarás muy bien de %s!»" % kid.npc_name, Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("lineage_sibling_a:") or action_id.begins_with("lineage_sibling_b:"):
		if not (st["sibling_rivalries"] as Dictionary).has(arg):
			return
		var sr: Dictionary = st["sibling_rivalries"][arg]
		sr["resolved"] = true
		var chosen_key: String = str(sr["a"]) if action_id.begins_with("lineage_sibling_a:") else str(sr["b"])
		var other_key: String = str(sr["b"]) if action_id.begins_with("lineage_sibling_a:") else str(sr["a"])
		var chosen = by_key.get(chosen_key, null)
		var other = by_key.get(other_key, null)
		if chosen != null and other != null:
			chosen.modify_affinity(18)
			chosen.modify_npc_relationship(other, 15, "Zanjamos la disputa por el taller", true)
			other.modify_npc_relationship(chosen, 15, "Zanjamos la disputa por el taller", true)
			for m in VillageClans.clan_members(vm, arg):
				if vm.trade_npcs.get(int(m.trade_role), null) == m:
					var tr_id: int = int(m.trade_role)
					if other != null and int(other.trade_role) == int(VillageNPC.TradeRole.FAMILY_MEMBER):
						other.trade_role = VillageNPC.TradeRole.UNEMPLOYED
						other.linked_trade = VillageNPC.TradeRole.UNEMPLOYED
						if not vm.unemployed_npcs.has(other):
							vm.unemployed_npcs.append(other)
					chosen.trade_role = VillageNPC.TradeRole.FAMILY_MEMBER
					chosen.linked_trade = m.trade_role
					vm.family_npcs[tr_id] = chosen
					vm.unemployed_npcs.erase(chosen)
					break
		var s_tip: int = VillageClans.pay_from_pocket(chosen, 15, inv)
		npc._spawn_floating_text("⚖️ «Queda decidido quién llevará el taller familiar.»%s" % (" (+%d Oro)" % s_tip if s_tip > 0 else ""), Color.GOLD, -46.0)

	elif action_id.begins_with("lineage_digger:"):
		if not (st["gold_diggers"] as Dictionary).has(arg):
			return
		var gd: Dictionary = st["gold_diggers"][arg]
		gd["exposed"] = true
		var digger = by_key.get(str(gd["digger_key"]), null)
		if digger != null:
			npc.modify_npc_relationship(digger, -35, "Solo iba detrás de mi dinero", true)
			if vm.social_director != null:
				vm.social_director.add_spark_one_way(npc.get_person_key(), digger.get_person_key(), -30)
		npc.modify_affinity(16)
		var g_tip: int = VillageClans.pay_from_pocket(npc, 20, inv)
		VillageChronicle.add(vm, "gold_digger_exposed", "Avisaste a %s de que %s solo buscaba su fortuna" % [npc.npc_name, str(gd["digger_name"])], true)
		npc._spawn_floating_text("💸 «¡Conque iba detrás de mi oro! Gracias por abrirme los ojos.»%s" % (" (+%d Oro)" % g_tip if g_tip > 0 else ""), Color.GOLD, -46.0)

	elif action_id.begins_with("lineage_past_help:"):
		if inv == null or int(inv.gold) < PAST_DEBT_GOLD:
			npc._spawn_floating_text("Necesitas %d de oro" % PAST_DEBT_GOLD, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-PAST_DEBT_GOLD)
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + PAST_DEBT_GOLD
		st["estranged_past"][arg]["resolved"] = true
		npc.modify_affinity(25)
		VillageClans.grant_honor_debt(vm, npc, "saldó su deuda familiar del pasado")
		npc._spawn_floating_text("🤝 «¡Nunca olvidaré lo que has hecho por mí!»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("lineage_past_press:"):
		st["estranged_past"][arg]["resolved"] = true
		var pay: int = VillageClans.pay_from_pocket(npc, 15, inv)
		npc.modify_affinity(-15)
		npc._spawn_floating_text("😠 «Toma %d de oro y no te metas en mi vida pasada.»" % pay, Color.GOLD, -46.0)

	elif action_id.begins_with("lineage_search_pocket:"):
		if not st.has("pocket_searched") or not (st["pocket_searched"] is Dictionary):
			st["pocket_searched"] = {}
		st["pocket_searched"][arg] = today()
		var seen_by = vm._find_conscious_witness_near(npc.global_position, 120.0, npc)
		if seen_by != null or randf() < 0.25:
			npc.modify_affinity(-25)
			npc._spawn_floating_text("😠 «¡Eh! ¡Saca la mano de mi bolsillo!»", Color.ORANGE_RED, -46.0)
			return
		for lsid in (st["love_letters"] as Dictionary).keys():
			var lf: Dictionary = st["love_letters"][lsid]
			if str(lf.get("sender_key", "")) == arg and not bool(lf.get("intercepted", false)) and not bool(lf.get("handled", false)):
				on_player_action(vm, npc, "lineage_intercept_letter:" + str(lsid), inv)
				return
		npc._spawn_floating_text("🤏 Solo encuentras pelusa y un par de botones.", Color(0.85, 0.85, 0.85), -46.0)

	elif action_id.begins_with("lineage_intercept_letter:"):
		if not (st["love_letters"] as Dictionary).has(arg):
			return
		var ll: Dictionary = st["love_letters"][arg]
		ll["intercepted"] = true
		for s in vm.secrets:
			if int(s.get("id", -2)) == int(ll.get("secret_id", -1)):
				s["player_knows"] = true
		npc._spawn_floating_text("✉️🕵️ Interceptaste una carta de amor de %s para %s." % [str(ll["sender_name"]), str(ll["receiver_name"])], Color(0.9, 0.8, 1.0), -46.0)

	elif action_id.begins_with("lineage_deliver_letter:"):
		if not (st["love_letters"] as Dictionary).has(arg):
			return
		var ll2: Dictionary = st["love_letters"][arg]
		ll2["handled"] = true
		var l_tip: int = VillageClans.pay_from_pocket(npc, 12, inv)
		npc.modify_affinity(12)
		npc._spawn_floating_text("✉️💘 «¡Shh, gracias por traérmela sin que nadie la viera!»%s" % (" (+%d Oro)" % l_tip if l_tip > 0 else ""), Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("lineage_expose_letter:"):
		if not (st["love_letters"] as Dictionary).has(arg):
			return
		var ll3: Dictionary = st["love_letters"][arg]
		ll3["handled"] = true
		for s in vm.secrets:
			if int(s.get("id", -2)) == int(ll3.get("secret_id", -1)) and bool(s.get("active", false)):
				VillageSecrets.partner_reaction(vm, s, npc, str(ll3["sender_name"]), str(ll3["receiver_name"]), "una carta de amor interceptada")
		var e_tip: int = VillageClans.pay_from_pocket(npc, 15, inv)
		npc.modify_affinity(10)
		npc._spawn_floating_text("✉️💔 «¡Con su propia letra! ¡Gracias por abrirme los ojos!»%s" % (" (+%d Oro)" % e_tip if e_tip > 0 else ""), Color.ORANGE_RED, -46.0)

	elif action_id.begins_with("lineage_arrange_wed:"):
		if not (st["arranged_marriages"] as Dictionary).has(arg):
			return
		var am: Dictionary = st["arranged_marriages"][arg]
		am["resolved"] = true
		var parent = by_key.get(str(am["parent_key"]), null)
		var youth = by_key.get(str(am["youth_key"]), null)
		var suitor = by_key.get(str(am["suitor_key"]), null)
		var dowry_total: int = clampi(int(parent.personal_gold) if parent != null else 0, 0, int(am.get("dowry", ARRANGED_DOWRY)))
		if parent != null:
			parent.personal_gold -= dowry_total
			parent.modify_affinity(15)
		var broker_fee: int = int(float(dowry_total) / 2.0)
		var couple_share: int = dowry_total - broker_fee
		if youth != null and suitor != null:
			youth.personal_gold += couple_share
			vm.VillageFamily.marry(youth, suitor)
		if inv != null and broker_fee > 0:
			inv.add_gold(broker_fee)
		VillageChronicle.add(vm, "arranged_marriage", "Se celebró la boda concertada entre %s y %s con %d de oro de dote" % [str(am["youth_name"]), str(am["suitor_name"]), dowry_total], true)
		npc._spawn_floating_text("💍💰 «Queda sellada la unión de las familias. Toma %d de oro de la dote por mediar.»" % broker_fee, Color.GOLD, -46.0)

	elif action_id.begins_with("lineage_arrange_refuse:"):
		if not (st["arranged_marriages"] as Dictionary).has(arg):
			return
		var am2: Dictionary = st["arranged_marriages"][arg]
		am2["resolved"] = true
		var r_tip: int = VillageClans.pay_from_pocket(npc, 12, inv)
		npc.modify_affinity(20)
		VillageClans.grant_honor_debt(vm, npc, "le ayudó a librarse de una boda concertada")
		npc._spawn_floating_text("💔🕊️ «¡Gracias! No quería casarme por obligación.»%s" % (" (+%d Oro)" % r_tip if r_tip > 0 else ""), Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("lineage_become_godparent:"):
		if inv == null or int(inv.gold) < 10:
			npc._spawn_floating_text("Necesitas 10 de oro para el regalo de bautizo", Color.ORANGE_RED, -44.0)
			return
		var g_kid = by_key.get(arg, null)
		if g_kid == null:
			return
		inv.add_gold(-10)
		g_kid.personal_gold += 10
		st["godparents"][arg] = {"kid_key": arg, "kid_name": g_kid.npc_name, "godparent_key": "player", "godparent_name": "Jugador"}
		npc.modify_affinity(18)
		g_kid.modify_affinity(35)
		VillageChronicle.add(vm, "player_godparent", "Apadrinaste en el bautizo al pequeño %s" % g_kid.npc_name, true)
		npc._spawn_floating_text("🕯️👶 «¡Será un honor que seas el padrino de %s!»" % g_kid.npc_name, Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("lineage_mentor_child:"):
		if inv == null or int(inv.gold) < 10 or (st["mentored_kids"] as Dictionary).has(arg):
			npc._spawn_floating_text("Necesitas 10 de oro para sus primeras herramientas", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-10)
		npc.personal_gold += 10 # las herramientas son suyas
		st["mentored_kids"][arg] = {"kid_key": arg, "kid_name": npc.npc_name, "day": today()}
		npc.modify_affinity(18)
		npc.add_thought("Aprendí nociones de oficio (+10)", 10.0)
		npc._spawn_floating_text("🛠️📚 «¡Gracias! Cuando cumpla 16 años sabré trabajar en un taller de verdad.»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("lineage_catch_mirador:"):
		var cst_c: Dictionary = VillageClans.state(vm)
		if not (cst_c["romeo_pairs"] as Dictionary).has(arg):
			return
		var rp_c: Dictionary = cst_c["romeo_pairs"][arg]
		rp_c["mirador_seen"] = true
		var m_tip: int = VillageClans.pay_from_pocket(npc, 10, inv)
		var other_n: String = str(rp_c["b_name"]) if npc.get_person_key() == str(rp_c["a"]) else str(rp_c["a_name"])
		npc._spawn_floating_text("🌙😳 «¡Chist, no grites! Me veo aquí en secreto con %s...»%s" % [other_n, (" (+%d Oro por callar)" % m_tip if m_tip > 0 else "")], Color(0.95, 0.80, 1.0), -46.0)
