@tool
extends RefCounted

## Bloque P1: Rencores de familia y clanes (10 mecánicas).
## 1) Heredar el odio al morir o marcharse (50 % de enemistades fuertes; odio total al asesino).
## 2) Feudo de sangre entre dos familias (tras peleas o muerte: enemistad mutua y boicot entre ellas).
## 3) Boicot comercial familiar contra el jugador (precios ×2 o negativa a vender si dañas a uno de los suyos).
## 4) Amor prohibido (Romeo y Julieta entre jóvenes de clanes en feudo; puedes ayudarles).
## 5) Venganza del huérfano al cumplir 16 años (recuerda al asesino de sus padres y jura venganza).
## 6) Cena de paz o boda entre clanes (mediar entre las dos familias para cerrar el feudo).
## 7) Desheredar a la oveja negra (el cabeza de familia honrado expulsa al pariente criminal).
## 8) Deuda de honor familiar (salvar a un vecino hace que todo su clan te deba un favor y te haga descuento).
## 9) Guerra por el testamento (disputa entre parientes y un amigo/amante cuando muere alguien con oro).
## 10) Profanar la tumba del rival (un enemigo mancha la lápida de noche; puedes limpiarla o delatarlo).
## Estado en `vm.family_state["clans"]` (se guarda automáticamente con `family_state`).

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageDesires = preload("res://scripts/systems/VillageDesires.gd")

const INHERIT_HATE_THRESHOLD: int = -35
const INHERIT_RATIO: float = 0.5
const KILLER_HATE: int = -90
const FEUD_FIGHTS_MIN: int = 2
const BOYCOTT_PRICE_AFF: int = -45
const BOYCOTT_REFUSE_AFF: int = -70
const PEACE_DINNER_COST: int = 25
const WILL_MIN_GOLD: int = 45
const GRAVE_PROFANE_CHANCE: float = 0.08

static func state(vm) -> Dictionary:
	if not (vm.family_state is Dictionary):
		vm.family_state = {}
	if not vm.family_state.has("clans") or not (vm.family_state["clans"] is Dictionary):
		vm.family_state["clans"] = {}
	var st: Dictionary = vm.family_state["clans"]
	for k in ["feuds", "clashes", "feud_player", "romeo_pairs", "orphan_killers", "disowned", "honor_debts", "wills", "desecrated_graves", "dead_enemies"]:
		if not st.has(k) or not (st[k] is Dictionary):
			st[k] = {}
	return st

static func today() -> int:
	return int(WorldClock.current_day) if WorldClock else 1

static func valid_family(fam: String) -> bool:
	return fam != "" and fam != "none" and fam != "family_police"

static func clan_members(vm, fam: String, exclude = null) -> Array:
	var out: Array = []
	if not valid_family(fam):
		return out
	for n in VillageNeeds.living(vm):
		if n != exclude and str(n.family_id) == fam:
			out.append(n)
	return out

static func relatives_of(vm, npc) -> Array:
	var out: Array = clan_members(vm, str(npc.family_id), npc)
	var pk: String = str(npc.person_profile.partner_id) if npc.person_profile != null else ""
	if pk != "":
		var partner = vm._get_npcs_by_person_key().get(pk, null)
		if partner != null and not partner.is_dead and not (partner in out):
			out.append(partner)
	return out

static func feud_key(fam_a: String, fam_b: String) -> String:
	return (fam_a + "|" + fam_b) if fam_a < fam_b else (fam_b + "|" + fam_a)

# ==============================================================================
# P1.1, P1.5 y P1.9: Muerte o marcha -> heredar rencor, huérfanos y testamentos
# ==============================================================================
static func on_npc_death(vm, dead_npc) -> void:
	if vm == null or dead_npc == null:
		return
	var st: Dictionary = state(vm)
	var d_key: String = dead_npc.get_person_key()
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var kin: Array = relatives_of(vm, dead_npc)
	# Guardar enemigos del difunto para P1.10 (profanar tumba) y heredar el 50 % a su familia (P1.1)
	var enemies: Array = []
	var best_friend = null
	var best_friend_rel: int = 49
	for ok in by_key.keys():
		var other = by_key[ok]
		if other == null or other == dead_npc or other.is_dead:
			continue
		var rel: int = dead_npc.get_relationship_with_npc(str(ok))
		if rel <= INHERIT_HATE_THRESHOLD and not (other in kin):
			enemies.append({"key": str(ok), "name": other.npc_name, "rel": rel})
		if not (other in kin) and rel > best_friend_rel and not (int(other.trade_role) == int(VillageNPC.TradeRole.CHILD)):
			best_friend_rel = rel
			best_friend = other
	if not enemies.is_empty():
		st["dead_enemies"][dead_npc.npc_name] = enemies
	var inherited_any: bool = false
	for k_npc in kin:
		for e in enemies:
			var target = by_key.get(str(e["key"]), null)
			if target == null or target.is_dead:
				continue
			var delta: int = mini(-12, int(round(float(int(e["rel"])) * INHERIT_RATIO)))
			k_npc.modify_npc_relationship(target, delta, "Rencor heredado de %s" % dead_npc.npc_name, true)
			inherited_any = true
	if inherited_any and not enemies.is_empty():
		VillageChronicle.add(vm, "grudge_inherited", "La familia de %s no olvida su enemistad con %s" % [dead_npc.npc_name, str(enemies[0]["name"])], true)
	# Si lo mató el jugador delante de alguien o por golpe directo, marcar ofensa al clan
	if bool(dead_npc.last_hit_by_player) and valid_family(str(dead_npc.family_id)):
		st["feud_player"][str(dead_npc.family_id)] = "severe"
		for k_npc in kin:
			k_npc.modify_affinity(-50)
	# P1.9: Testamento disputado si tenía ahorros, un gran amigo/amante fuera de la familia y roce con algún pariente
	if int(dead_npc.personal_gold) >= WILL_MIN_GOLD and best_friend != null and not kin.is_empty():
		var angry_kin = null
		for k_npc in kin:
			if int(k_npc.trade_role) != int(VillageNPC.TradeRole.CHILD) and dead_npc.get_relationship_with_npc(k_npc.get_person_key()) <= 15:
				angry_kin = k_npc
				break
		if angry_kin != null:
			var w_gold: int = maxi(40, int(dead_npc.personal_gold))
			st["wills"][d_key] = {
				"dead_key": d_key, "dead_name": dead_npc.npc_name,
				"beneficiary": best_friend.get_person_key(), "ben_name": best_friend.npc_name,
				"claimant": angry_kin.get_person_key(), "claim_name": angry_kin.npc_name,
				"gold": w_gold, "resolved": false, "day": today()
			}
			angry_kin.modify_npc_relationship(best_friend, -35, "Se quedó la herencia de %s" % dead_npc.npc_name, true)
			VillageChronicle.add(vm, "contested_will", "Disputa por el testamento de %s entre su pariente %s y %s (%d de oro)" % [dead_npc.npc_name, angry_kin.npc_name, best_friend.npc_name, w_gold], true)

static func on_npc_departure(vm, leaving_npc) -> void:
	if vm == null or leaving_npc == null:
		return
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for k_npc in relatives_of(vm, leaving_npc):
		for ok in by_key.keys():
			var other = by_key[ok]
			if other == null or other == leaving_npc or other == k_npc or other.is_dead:
				continue
			var rel: int = leaving_npc.get_relationship_with_npc(str(ok))
			if rel <= INHERIT_HATE_THRESHOLD:
				k_npc.modify_npc_relationship(other, int(round(float(rel) * INHERIT_RATIO)), "Heredó el rencor de %s antes de marcharse" % leaving_npc.npc_name, true)

## Cuando se descubre al asesino de `victim_name` (al cerrarse el caso o por asesinato de vecino).
static func on_murder_resolved(vm, victim_name: String, killer_name_or_key: String) -> void:
	if vm == null or victim_name == "" or killer_name_or_key == "":
		return
	var st: Dictionary = state(vm)
	var victim = vm._find_corpse_npc_by_name(victim_name)
	if victim == null:
		for n in vm.get_tree().get_nodes_in_group("village_npcs"):
			if n is VillageNPC and str(n.npc_name) == victim_name:
				victim = n
				break
	if victim == null:
		return
	var killer = null
	var is_player_killer: bool = ("Jugador" in killer_name_or_key or "Forastero" in killer_name_or_key or killer_name_or_key == "player")
	for n in VillageNeeds.living(vm):
		if n.npc_name == killer_name_or_key or n.get_person_key() == killer_name_or_key or n.npc_name in killer_name_or_key:
			killer = n
			break
	var kin: Array = relatives_of(vm, victim)
	if is_player_killer and valid_family(str(victim.family_id)):
		st["feud_player"][str(victim.family_id)] = "severe"
	for k_npc in kin:
		if is_player_killer:
			k_npc.modify_affinity(-60)
			continue
		if killer == null or killer == k_npc:
			continue
		if int(k_npc.trade_role) == int(VillageNPC.TradeRole.CHILD):
			# P1.5: El huérfano guarda quién mató a su padre/madre para cuando cumpla 16 años
			st["orphan_killers"][k_npc.get_person_key()] = {
				"killer_key": killer.get_person_key(), "killer_name": killer.npc_name, "parent_name": victim.npc_name
			}
			k_npc.modify_npc_relationship(killer, KILLER_HATE, "Asesinó a %s" % victim.npc_name, true)
		else:
			k_npc.modify_npc_relationship(killer, KILLER_HATE, "Asesinó a %s de mi familia" % victim.npc_name, true)
			if TraitCatalog.npc_tendency(k_npc, "grudge") + TraitCatalog.npc_tendency(k_npc, "aggression") >= 0.0:
				_start_clan_revenge_desire(vm, k_npc, killer, "Vengar la muerte de %s" % victim.npc_name)
	if killer != null and valid_family(str(victim.family_id)) and valid_family(str(killer.family_id)) and str(victim.family_id) != str(killer.family_id):
		declare_blood_feud(vm, str(victim.family_id), str(killer.family_id), "el asesinato de %s" % victim.npc_name)

static func _start_clan_revenge_desire(vm, holder, target, reason_txt: String) -> void:
	if not VillageDesires.active_of(vm, holder.get_person_key()).is_empty():
		return
	var d: Dictionary = VillageDesires.create(vm, "revenge", holder, target.get_person_key(), target.npc_name, reason_txt, true)
	d["clan_reason"] = reason_txt
	VillageChronicle.add(vm, "desire_start", "%s juró vengar a su familia contra %s (%s)" % [holder.npc_name, target.npc_name, reason_txt], true)

## P1.5: Llamado desde `VillageFamily.grow_up` cuando un niño cumple 16 años.
static func on_child_grown_up(vm, youth) -> void:
	var st: Dictionary = state(vm)
	var k: String = youth.get_person_key()
	if not (st["orphan_killers"] as Dictionary).has(k):
		return
	var info: Dictionary = st["orphan_killers"][k]
	st["orphan_killers"].erase(k)
	var killer = vm._get_npcs_by_person_key().get(str(info.get("killer_key", "")), null)
	if killer == null or killer.is_dead:
		return
	youth.modify_npc_relationship(killer, -95, "Mató a %s cuando yo era niño" % str(info.get("parent_name", "mi familia")), true)
	_start_clan_revenge_desire(vm, youth, killer, "Venganza de huérfano por %s" % str(info.get("parent_name", "su familia")))
	VillageChronicle.add(vm, "orphan_vow", "%s cumplió 16 años y juró vengar la muerte de %s contra %s" % [youth.npc_name, str(info.get("parent_name", "")), killer.npc_name], true)

# ==============================================================================
# P1.2, P1.4 y P1.6: Feudo de sangre, Amor prohibido (Romeo y Julieta) y Paz
# ==============================================================================
static func register_clan_clash(vm, a, b, reason: String = "peleas repetidas") -> void:
	if vm == null or a == null or b == null:
		return
	var fa: String = str(a.family_id)
	var fb: String = str(b.family_id)
	if not valid_family(fa) or not valid_family(fb) or fa == fb:
		return
	var st: Dictionary = state(vm)
	var fk: String = feud_key(fa, fb)
	if (st["feuds"] as Dictionary).has(fk):
		return
	st["clashes"][fk] = int(st["clashes"].get(fk, 0)) + 1
	if int(st["clashes"][fk]) >= FEUD_FIGHTS_MIN:
		declare_blood_feud(vm, fa, fb, reason)

static func declare_blood_feud(vm, fam_a: String, fam_b: String, reason: String) -> void:
	if not valid_family(fam_a) or not valid_family(fam_b) or fam_a == fam_b:
		return
	var st: Dictionary = state(vm)
	var fk: String = feud_key(fam_a, fam_b)
	if (st["feuds"] as Dictionary).has(fk):
		return
	var mem_a: Array = clan_members(vm, fam_a)
	var mem_b: Array = clan_members(vm, fam_b)
	var name_a: String = str(mem_a[0].family_name) if not mem_a.is_empty() and str(mem_a[0].family_name) != "" else fam_a
	var name_b: String = str(mem_b[0].family_name) if not mem_b.is_empty() and str(mem_b[0].family_name) != "" else fam_b
	st["feuds"][fk] = {"fam_a": fam_a, "fam_b": fam_b, "name_a": name_a, "name_b": name_b, "day": today(), "reason": reason}
	for ma in mem_a:
		for mb in mem_b:
			ma.modify_npc_relationship(mb, -25, "Feudo de sangre entre clanes (%s)" % reason, true)
			mb.modify_npc_relationship(ma, -25, "Feudo de sangre entre clanes (%s)" % reason, true)
	VillageChronicle.add(vm, "blood_feud", "Estalló un feudo de sangre entre %s y %s por %s" % [name_a, name_b, reason], true)

static func is_blood_feud(vm, fam_a: String, fam_b: String) -> bool:
	if not valid_family(fam_a) or not valid_family(fam_b) or fam_a == fam_b:
		return false
	return (state(vm)["feuds"] as Dictionary).has(feud_key(fam_a, fam_b))

static func mediate_clan_peace(vm, fk: String, how: String) -> bool:
	var st: Dictionary = state(vm)
	if not (st["feuds"] as Dictionary).has(fk):
		return false
	var f: Dictionary = st["feuds"][fk]
	var mem_a: Array = clan_members(vm, str(f["fam_a"]))
	var mem_b: Array = clan_members(vm, str(f["fam_b"]))
	for ma in mem_a:
		for mb in mem_b:
			ma.modify_npc_relationship(mb, 25, "Paz sellada entre nuestras familias (%s)" % how, true)
			mb.modify_npc_relationship(ma, 25, "Paz sellada entre nuestras familias (%s)" % how, true)
	var na: String = str(f.get("name_a", f["fam_a"]))
	var nb: String = str(f.get("name_b", f["fam_b"]))
	st["feuds"].erase(fk)
	st["clashes"].erase(fk)
	VillageChronicle.add(vm, "clan_peace", "Se selló la paz entre %s y %s (%s)" % [na, nb, how], true)
	return true

static func _daily_forbidden_romances(vm) -> void:
	var st: Dictionary = state(vm)
	if (st["feuds"] as Dictionary).is_empty() or vm.social_director == null:
		return
	var sd = vm.social_director
	for fk in (st["feuds"] as Dictionary).keys():
		var f: Dictionary = st["feuds"][fk]
		var mem_a: Array = clan_members(vm, str(f["fam_a"]))
		var mem_b: Array = clan_members(vm, str(f["fam_b"]))
		for a in mem_a:
			if a.person_profile == null or int(a.person_profile.age) < 18 or str(a.person_profile.partner_id) != "":
				continue
			for b in mem_b:
				if b.person_profile == null or int(b.person_profile.age) < 18 or str(b.person_profile.partner_id) != "":
					continue
				if str(a.person_profile.gender) == str(b.person_profile.gender):
					continue
				var pk: String = sd.make_pair_key(a.get_person_key(), b.get_person_key())
				if (st["romeo_pairs"] as Dictionary).has(pk):
					continue
				var spk: int = maxi(sd.get_spark(a.get_person_key(), b.get_person_key()), sd.get_spark(b.get_person_key(), a.get_person_key()))
				if spk >= 18 or (sd.compute_compatibility(a.person_profile, b.person_profile, false) >= 55 and randf() < 0.15):
					sd.add_spark_one_way(a.get_person_key(), b.get_person_key(), 25)
					sd.add_spark_one_way(b.get_person_key(), a.get_person_key(), 25)
					a.modify_npc_relationship(b, 40, "Amor secreto pese al odio de nuestras familias", true)
					b.modify_npc_relationship(a, 40, "Amor secreto pese al odio de nuestras familias", true)
					st["romeo_pairs"][pk] = {
						"pair_key": pk, "a": a.get_person_key(), "b": b.get_person_key(),
						"a_name": a.npc_name, "b_name": b.npc_name, "feud_key": fk, "helped": false
					}
					VillageChronicle.add(vm, "forbidden_love", "%s y %s se han enamorado en secreto pese al feudo entre sus familias" % [a.npc_name, b.npc_name], false)
					return

# ==============================================================================
# P1.3 y P1.8: Boicot comercial familiar y Deuda de honor familiar
# ==============================================================================
static func mark_player_offense(vm, victim_npc, severe: bool = false) -> void:
	if vm == null or victim_npc == null or not valid_family(str(victim_npc.family_id)):
		return
	var st: Dictionary = state(vm)
	var fam: String = str(victim_npc.family_id)
	st["feud_player"][fam] = "severe" if severe else "boycott"
	for m in clan_members(vm, fam, victim_npc):
		m.modify_affinity(-25 if severe else -12)

static func grant_honor_debt(vm, saved_npc, reason: String = "salvó a uno de los nuestros") -> void:
	if vm == null or saved_npc == null or not valid_family(str(saved_npc.family_id)):
		return
	var st: Dictionary = state(vm)
	var fam: String = str(saved_npc.family_id)
	st["feud_player"].erase(fam)
	st["honor_debts"][fam] = {"by": saved_npc.npc_name, "reason": reason, "day": today(), "favor_used": false}
	for m in clan_members(vm, fam):
		m.modify_affinity(15)
		m.add_thought("El forastero %s (+10)" % reason, 10.0)
	var fam_label: String = str(saved_npc.family_name) if str(saved_npc.family_name) != "" else saved_npc.npc_name
	VillageChronicle.add(vm, "honor_debt", "La familia de %s te debe una deuda de honor (%s)" % [fam_label, reason], true)

static func is_boycotting_player(vm, npc) -> bool:
	if vm == null or npc == null or not valid_family(str(npc.family_id)):
		return false
	var st: Dictionary = state(vm)
	var fam: String = str(npc.family_id)
	if str(st["feud_player"].get(fam, "")) == "severe":
		return true
	for m in clan_members(vm, fam):
		if int(m.affinity) <= BOYCOTT_REFUSE_AFF:
			return true
	return false

static func player_price_mult(vm, npc) -> float:
	if vm == null or npc == null or not valid_family(str(npc.family_id)):
		return 1.0
	var st: Dictionary = state(vm)
	var fam: String = str(npc.family_id)
	if (st["honor_debts"] as Dictionary).has(fam):
		return 0.75 # 25 % de descuento por deuda de honor
	if (st["feud_player"] as Dictionary).has(fam):
		return 2.0
	for m in clan_members(vm, fam):
		if int(m.affinity) <= BOYCOTT_PRICE_AFF:
			return 2.0
	return 1.0

# ==============================================================================
# P1.7 y P1.10: Desheredar a la oveja negra y Profanación de tumbas por rencor
# ==============================================================================
static func _daily_disown_check(vm) -> void:
	var st: Dictionary = state(vm)
	var thefts: Array = VillageNeeds.state(vm).get("thefts", [])
	var caught_counts: Dictionary = {}
	for t in thefts:
		if str(t.get("status", "")) == "caught":
			var tk: String = str(t.get("thief", ""))
			caught_counts[tk] = int(caught_counts.get(tk, 0)) + 1
	for n in VillageNeeds.living(vm):
		var k: String = n.get_person_key()
		var fam: String = str(n.family_id)
		if not valid_family(fam) or (st["disowned"] as Dictionary).has(k) or int(n.trade_role) == int(VillageNPC.TradeRole.CHILD):
			continue
		if int(caught_counts.get(k, 0)) < 2:
			continue
		var head = null
		for m in clan_members(vm, fam, n):
			if int(m.trade_role) != int(VillageNPC.TradeRole.CHILD) and TraitCatalog.npc_tendency(m, "honesty") >= 0.4:
				head = m
				break
		if head != null:
			disown_member(vm, head, n, "sus robos reiterados")

static func disown_member(vm, head, sheep, reason: String) -> void:
	var st: Dictionary = state(vm)
	var old_fam: String = str(sheep.family_id)
	st["disowned"][sheep.get_person_key()] = {"fam": old_fam, "by": head.npc_name, "reason": reason, "day": today()}
	for r in vm.family_npcs.keys():
		if vm.family_npcs[r] == sheep:
			vm.family_npcs.erase(r)
	sheep.family_id = "none"
	sheep.family_name = "Repudiado"
	if int(sheep.trade_role) == int(VillageNPC.TradeRole.FAMILY_MEMBER):
		sheep.trade_role = VillageNPC.TradeRole.UNEMPLOYED
		sheep.linked_trade = VillageNPC.TradeRole.UNEMPLOYED
		if not vm.unemployed_npcs.has(sheep):
			vm.unemployed_npcs.append(sheep)
	vm.evict_npc_to_vagrant_camp(sheep, "desheredado por su familia")
	head.modify_npc_relationship(sheep, -30, "Deshonró a nuestra familia (%s)" % reason, true)
	sheep.modify_npc_relationship(head, -35, "Me echó de casa y me desheredó", true)
	VillageChronicle.add(vm, "disowned", "%s desheredó y echó de casa a %s por %s" % [head.npc_name, sheep.npc_name, reason], true)

static func _daily_grave_desecration(vm) -> void:
	if vm.buried_graves.is_empty() or randf() >= GRAVE_PROFANE_CHANCE:
		return
	var st: Dictionary = state(vm)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for rec in vm.buried_graves:
		var v_name: String = str(rec.get("victim_name", ""))
		if v_name == "" or (st["desecrated_graves"] as Dictionary).has(v_name):
			continue
		var enemies: Array = st["dead_enemies"].get(v_name, [])
		for e in enemies:
			var culprit = by_key.get(str(e.get("key", "")), null)
			if culprit != null and not culprit.is_dead and TraitCatalog.npc_tendency(culprit, "grudge") >= 0.3:
				st["desecrated_graves"][v_name] = {"culprit": culprit.get_person_key(), "culprit_name": culprit.npc_name, "day": today(), "known": false}
				VillageChronicle.add(vm, "grave_profaned", "Alguien profanó de noche la lápida de %s en el cementerio" % v_name, true)
				return

static func daily(vm) -> void:
	_daily_forbidden_romances(vm)
	_daily_disown_check(vm)
	_daily_grave_desecration(vm)

# ==============================================================================
# Diálogo con los vecinos (P1.3, P1.4, P1.6, P1.8, P1.9, P1.10)
# ==============================================================================
static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null or npc == null:
		return
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key()
	var fam: String = str(npc.family_id)
	var sub: Array = []
	# P1.3: Si la familia te boicotea, opción de pagar compensación familiar (20 oro) para levantar el boicot
	if (st["feud_player"] as Dictionary).has(fam) or is_boycotting_player(vm, npc):
		sub.append({"label": "🕊️💰 Disculparte con su familia y compensar la ofensa (-20 Oro)", "next": "END", "action": "clan_apologize:" + fam})
	# P1.6: Mediar cena de paz si su familia está en feudo de sangre
	for fk in (st["feuds"] as Dictionary).keys():
		var f: Dictionary = st["feuds"][fk]
		if str(f["fam_a"]) == fam or str(f["fam_b"]) == fam:
			var other_name: String = str(f["name_b"]) if str(f["fam_a"]) == fam else str(f["name_a"])
			sub.append({"label": "🍷🕊️ Organizar cena de paz con %s (-%d Oro o Carisma 2)" % [other_name, PEACE_DINNER_COST], "next": "END", "action": "clan_peace:" + fk})
	# P1.4: Amor prohibido (Romeo y Julieta)
	for pk in (st["romeo_pairs"] as Dictionary).keys():
		var rp: Dictionary = st["romeo_pairs"][pk]
		if not bool(rp.get("helped", false)) and (str(rp["a"]) == key or str(rp["b"]) == key):
			var other_lover: String = str(rp["b_name"]) if str(rp["a"]) == key else str(rp["a_name"])
			sub.append({"label": "💘 Ayudarle en su romance prohibido con %s (+20 Oro)" % other_lover, "next": "END", "action": "clan_romeo:" + pk})
	# P1.8: Reclamar favor de deuda de honor familiar
	if (st["honor_debts"] as Dictionary).has(fam) and not bool(st["honor_debts"][fam].get("favor_used", false)):
		sub.append({"label": "🤝💰 Pedir ayuda económica por la deuda de honor familiar (+25 Oro)", "next": "END", "action": "clan_favor_gold:" + fam})
		sub.append({"label": "🤝🗳️ Pedir que toda su familia apoye tu causa/voto", "next": "END", "action": "clan_favor_vote:" + fam})
	# P1.9: Disputa de testamento
	for wk in (st["wills"] as Dictionary).keys():
		var w: Dictionary = st["wills"][wk]
		if bool(w.get("resolved", false)):
			continue
		if str(w["beneficiary"]) == key:
			sub.append({"label": "📜⚖️ Respaldar su derecho al testamento de %s (+25 Oro)" % str(w["dead_name"]), "next": "END", "action": "clan_will_back:" + wk})
		elif str(w["claimant"]) == key:
			sub.append({"label": "📜⚖️ Apoyar a la familia para impugnar el testamento de %s (+25 Oro)" % str(w["dead_name"]), "next": "END", "action": "clan_will_contest:" + wk})
	# P1.10: Tumbas profanadas
	for v_name in (st["desecrated_graves"] as Dictionary).keys():
		var dg: Dictionary = st["desecrated_graves"][v_name]
		sub.append({"label": "🪦 Limpiar la lápida profanada de %s y señalar a %s (+15 Oro)" % [v_name, str(dg["culprit_name"])], "next": "END", "action": "clan_grave_fix:" + v_name})
	if not sub.is_empty():
		sub.append({"label": "⬅️ Volver", "next": "start"})
		diag["clan_menu"] = {"text": "🩸 Asuntos de familia, honor y clanes:", "choices": sub}
		ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🩸 Asuntos de familia y clan…", "next": "clan_menu"})

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	var st: Dictionary = state(vm)
	var arg: String = action_id.get_slice(":", 1)
	if action_id.begins_with("clan_apologize:"):
		if inv == null or int(inv.gold) < 20:
			npc._spawn_floating_text("Necesitas 20 de oro para compensar a la familia", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-20)
		npc.personal_gold += 20
		st["feud_player"].erase(arg)
		for m in clan_members(vm, arg):
			if int(m.affinity) < -20:
				m.modify_affinity(30)
			else:
				m.modify_affinity(12)
		npc._spawn_floating_text("🕊️ «Nuestra familia acepta tu compensación. Borrón y cuenta nueva.»", Color.SPRING_GREEN, -46.0)
	elif action_id.begins_with("clan_peace:"):
		var pl = npc._get_player()
		var cha: int = int(pl.call("get_skill_level", "charisma")) if pl != null and pl.has_method("get_skill_level") else 0
		if cha < 2 and (inv == null or int(inv.gold) < PEACE_DINNER_COST):
			npc._spawn_floating_text("Necesitas %d de oro para la cena de paz (o Carisma Nv.2)" % PEACE_DINNER_COST, Color.ORANGE_RED, -44.0)
			return
		if cha < 2 and inv != null:
			inv.add_gold(-PEACE_DINNER_COST)
		if mediate_clan_peace(vm, arg, "gracias a tu mediación"):
			npc.modify_affinity(18)
			npc._spawn_floating_text("🍷🕊️ «Habrá paz entre nuestras familias.»", Color.SPRING_GREEN, -46.0)
	elif action_id.begins_with("clan_romeo:"):
		if not (st["romeo_pairs"] as Dictionary).has(arg):
			return
		var rp: Dictionary = st["romeo_pairs"][arg]
		rp["helped"] = true
		var by_key: Dictionary = vm._get_npcs_by_person_key()
		var a = by_key.get(str(rp["a"]), null)
		var b = by_key.get(str(rp["b"]), null)
		if a != null and b != null:
			vm.VillageFamily.marry(a, b)
			a.modify_affinity(18)
			b.modify_affinity(18)
			mediate_clan_peace(vm, str(rp.get("feud_key", "")), "la unión de %s y %s" % [a.npc_name, b.npc_name])
		if inv != null:
			inv.add_gold(20)
		npc._spawn_floating_text("💘 «¡Gracias! Nuestras familias por fin han cedido.» (+20 Oro)", Color.SPRING_GREEN, -46.0)
	elif action_id.begins_with("clan_favor_gold:"):
		if (st["honor_debts"] as Dictionary).has(arg):
			st["honor_debts"][arg]["favor_used"] = true
			if inv != null:
				inv.add_gold(25)
			npc._spawn_floating_text("🤝 «Nuestra familia no olvida lo que hiciste. Toma estos 25 de oro.»", Color.GOLD, -46.0)
	elif action_id.begins_with("clan_favor_vote:"):
		if (st["honor_debts"] as Dictionary).has(arg):
			st["honor_debts"][arg]["favor_used"] = true
			for m in clan_members(vm, arg):
				m.modify_affinity(15)
				vm.VillageTown.state(vm)["pledges"][m.get_person_key()] = "player" if bool(vm.VillageTown.state(vm).get("player_candidate", false)) else npc.get_person_key()
			npc._spawn_floating_text("🤝🗳️ «Toda nuestra casa votará como tú digas.»", Color.SPRING_GREEN, -46.0)
	elif action_id.begins_with("clan_will_back:") or action_id.begins_with("clan_will_contest:"):
		if not (st["wills"] as Dictionary).has(arg):
			return
		var w: Dictionary = st["wills"][arg]
		w["resolved"] = true
		var by_key: Dictionary = vm._get_npcs_by_person_key()
		var winner_key: String = str(w["beneficiary"]) if action_id.begins_with("clan_will_back:") else str(w["claimant"])
		var loser_key: String = str(w["claimant"]) if action_id.begins_with("clan_will_back:") else str(w["beneficiary"])
		var winner = by_key.get(winner_key, null)
		var loser = by_key.get(loser_key, null)
		if winner != null:
			winner.personal_gold += int(w["gold"])
			winner.modify_affinity(18)
		if loser != null:
			loser.modify_affinity(-12)
		if inv != null:
			inv.add_gold(25)
		VillageChronicle.add(vm, "will_resolved", "El testamento de %s se resolvió a favor de %s" % [str(w["dead_name"]), winner.npc_name if winner else "su heredero"], true)
		npc._spawn_floating_text("📜⚖️ «Gracias por testificar a mi favor. Toma 25 de oro.»", Color.GOLD, -46.0)
	elif action_id.begins_with("clan_grave_fix:"):
		if not (st["desecrated_graves"] as Dictionary).has(arg):
			return
		var dg: Dictionary = st["desecrated_graves"][arg]
		var culprit = vm._get_npcs_by_person_key().get(str(dg.get("culprit", "")), null)
		if culprit != null:
			npc.modify_npc_relationship(culprit, -40, "Profanó la tumba de %s" % arg, true)
		st["desecrated_graves"].erase(arg)
		npc.modify_affinity(14)
		if inv != null:
			inv.add_gold(15)
		npc._spawn_floating_text("🪦 «Gracias por limpiar la lápida y decirnos quién fue.» (+15 Oro)", Color.SPRING_GREEN, -46.0)
