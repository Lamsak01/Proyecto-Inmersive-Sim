@tool
extends RefCounted

## Bloque P2: Asesinatos, pistas falsas e investigaciones (10 mecánicas).
## 1) Plantar un objeto de un rival en la escena del crimen (+20 % de sospecha al inocente; desmontable).
## 2) Coartadas falsas por lealtad (pareja, familia o secta mienten por el asesino; se puede romper la coartada).
## 3) Comprar o intimidar al testigo presencial (calla hasta que lo protejas o tranquilices).
## 4) Crimen por encargo / Sicario (un rico cobarde paga a otro o te ofrece el contrato a ti).
## 5) Simular muerte natural con veneno lento (no abre caso hasta descubrir el veneno en la autopsia).
## 6) Incriminar tú a un vecino (plantar prueba falsa contra un sospechoso para bajar tu sospecha).
## 7) Esconder o mover el cadáver de noche (arrastrar el cuerpo para despistar; rastro de arrastre).
## 8) Confesión borracho o delirando con fiebre (el asesino suelta la verdad ebrio o enfermo grave).
## 9) Chivo expiatorio del comisario corrupto (el asesino rico compra al comisario para culpar a un mendigo).
## 10) Tender una emboscada nocturna al asesino con la guardia antes de que ataque (+40 Oro).
## Estado en `vm.town_state["forensics"]` (se guarda automáticamente con `town_state`).

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageDesires = preload("res://scripts/systems/VillageDesires.gd")
const VillageTown = preload("res://scripts/systems/VillageTown.gd")
const VillageFaith = preload("res://scripts/systems/VillageFaith.gd")
const VillageClans = preload("res://scripts/systems/VillageClans.gd")

const PLANTED_PTS: int = 20
const FALSE_ALIBI_RELIEF: int = 15
const SCAPEGOAT_PTS: int = 30
const FRAME_COST: int = 15
const AMBUSH_REWARD: int = 40
const HITMAN_PAY: int = 45
const BLEACH_COST: int = 8
const BRIBE_AUTOPSY_COST: int = 35
const CLEANER_COST: int = 25
const INSURANCE_PAYOUT: int = 40
const INSURANCE_LOOKUP_COST: int = 10

static func state(vm) -> Dictionary:
	var ts: Dictionary = VillageTown.state(vm)
	if not ts.has("forensics") or not (ts["forensics"] is Dictionary):
		ts["forensics"] = {}
	var st: Dictionary = ts["forensics"]
	for k in ["planted", "alibis", "tampered", "hitmen", "poisoned", "moved", "slips", "scapegoats", "player_contracts", "insurance", "tampered_time", "copycats", "detective_board"]:
		if not st.has(k) or not (st[k] is Dictionary):
			st[k] = {}
	return st

static func today() -> int:
	return int(WorldClock.current_day) if WorldClock else 1

# ==============================================================================
# Al cometerse un asesinato de vecino (`VillageDesires.try_commit_murder`)
# ==============================================================================
static func on_npc_murder_committed(vm, killer, victim, desire: Dictionary) -> void:
	if vm == null or killer == null or victim == null:
		return
	var st: Dictionary = state(vm)
	var v_name: String = victim.npc_name
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	# P2.4: ¿Actuó por encargo de un cerebro rico?
	var mastermind_key: String = str(desire.get("mastermind", ""))
	if mastermind_key != "":
		var mm = by_key.get(mastermind_key, null)
		st["hitmen"][v_name] = {
			"mastermind_key": mastermind_key, "mastermind_name": mm.npc_name if mm else str(desire.get("mastermind_name", "Un rico")),
			"hitman_key": killer.get_person_key(), "hitman_name": killer.npc_name, "exposed": false,
			"desire_id": int(desire.get("id", -1))
		}
	# P2.5: ¿Usó veneno lento para simular muerte natural? (si tiene malicia >= 0.6 y agresividad <= 0.2)
	if TraitCatalog.npc_tendency(killer, "malice") >= 0.6 and TraitCatalog.npc_tendency(killer, "aggression") <= 0.2:
		victim.last_hit_weapon_name = "Fallo súbito (¿veneno lento?)"
		st["poisoned"][v_name] = {"killer_key": killer.get_person_key(), "killer_name": killer.npc_name, "autopsied": false}
	# P2.7: Mover o esconder el cadáver de noche (40 % si no fue veneno)
	elif randf() < 0.40:
		var orig: Vector2 = victim.global_position
		victim.global_position += Vector2(96.0, -64.0)
		victim.death_world_pos = victim.global_position
		st["moved"][v_name] = {"orig_x": orig.x, "orig_y": orig.y, "killer_name": killer.npc_name, "tracked": false}
	# P2.1: Plantar una pista falsa contra otro rival (si tiene malicia >= 0.2)
	if TraitCatalog.npc_tendency(killer, "malice") >= 0.2:
		var framed_name: String = ""
		var framed_key: String = ""
		if int(killer.affinity) <= -50:
			framed_name = "Jugador"
			framed_key = "player"
		else:
			var worst_rel: int = -25
			for ok in by_key.keys():
				var other = by_key[ok]
				if other == null or other == killer or other == victim or other.is_dead:
					continue
				if int(other.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.CHILD)]:
					continue
				var r: int = killer.get_relationship_with_npc(str(ok))
				if r < worst_rel:
					worst_rel = r
					framed_name = other.npc_name
					framed_key = str(ok)
		if framed_name != "":
			st["planted"][v_name] = {"framed_name": framed_name, "framed_key": framed_key, "killer_name": killer.npc_name, "debunked": false}
	# P2.2: Coartada falsa de pareja, familia o compañero de secta
	for ally in VillageNeeds.living(vm):
		if ally == killer or ally == victim or int(ally.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.CHILD)]:
			continue
		var same_fam: bool = VillageClans.valid_family(str(killer.family_id)) and str(ally.family_id) == str(killer.family_id)
		var is_partner: bool = killer.person_profile != null and str(killer.person_profile.partner_id) == ally.get_person_key()
		var same_sect: bool = (vm.sect_state.get("members", {}) as Dictionary).has(killer.get_person_key()) and (vm.sect_state.get("members", {}) as Dictionary).has(ally.get_person_key())
		if (is_partner or same_fam or same_sect) and ally.get_relationship_with_npc(killer.get_person_key()) >= 30:
			st["alibis"][v_name] = {"ally_key": ally.get_person_key(), "ally_name": ally.npc_name, "killer_name": killer.npc_name, "broken": false}
			break
	# P2.11: Trucar la hora de la muerte enfriando o cubriendo el cuerpo (si tiene malicia >= 0.35)
	if TraitCatalog.npc_tendency(killer, "malice") >= 0.35:
		st["tampered_time"][v_name] = {"killer_name": killer.npc_name, "examined": false}
	# P2.12: Si había una póliza de seguro de vida sobre la víctima y nadie la ha destapado, queda lista para cobrarse
	if (st["insurance"] as Dictionary).has(v_name):
		st["insurance"][v_name]["victim_dead"] = true
	# Tanda 2 (6): Imitador / Copycat (si ya hubo otro asesinato antes y el asesino tiene malicia >= 0.4)
	if TraitCatalog.npc_tendency(killer, "malice") >= 0.4 and not vm.npc_murders.is_empty():
		for prev_v in vm.npc_murders.keys():
			var prev_k: String = str(vm.npc_murders[prev_v])
			if prev_v != v_name and prev_k != "" and prev_k != killer.npc_name:
				st["copycats"][v_name] = {"killer_name": killer.npc_name, "imitated_killer": prev_k, "imitated_victim": str(prev_v), "debunked": false}
				break

# ==============================================================================
# Al abrirse el expediente en `VillageJustice._build_investigation_case_dict`
# ==============================================================================
static func apply_to_case(vm, victim, case_dict: Dictionary) -> void:
	if vm == null or victim == null or case_dict.is_empty():
		return
	var st: Dictionary = state(vm)
	var v_name: String = str(case_dict.get("victim_name", victim.npc_name))
	var suspects: Dictionary = case_dict.get("suspects", {})
	var clues: Array = case_dict.get("clues_log", [])
	var killer_name: String = VillageDesires.killer_of(vm, v_name)
	# P2.1: Aplicar pista falsa plantada
	if (st["planted"] as Dictionary).has(v_name):
		var pl_info: Dictionary = st["planted"][v_name]
		var f_name: String = str(pl_info.get("framed_name", ""))
		if suspects.has(f_name) and not bool(pl_info.get("debunked", false)):
			suspects[f_name]["score"] = int(suspects[f_name].get("score", 10)) + PLANTED_PTS
			var label_f: String = "el Forastero" if f_name == "Jugador" else f_name
			clues.append("Prueba física dudosa: apareció un objeto personal de %s junto al cuerpo (+%d%% sospecha)." % [label_f, PLANTED_PTS])
			case_dict["planted_clue_on"] = f_name
	# P2.2: Coartada falsa por lealtad familiar/pareja/secta
	if (st["alibis"] as Dictionary).has(v_name) and killer_name != "" and suspects.has(killer_name):
		var al_info: Dictionary = st["alibis"][v_name]
		if not bool(al_info.get("broken", false)):
			var ks: Dictionary = suspects[killer_name]
			ks["score"] = maxi(5, int(ks.get("score", 25)) - FALSE_ALIBI_RELIEF)
			ks["mem_alibi_partner"] = str(al_info["ally_name"])
			ks["status_note"] = "Coartada declarada por %s (familiar/allegado)" % str(al_info["ally_name"])
			clues.append("Coartada sospechosa: %s asegura que %s estuvo en casa toda la noche (-%d%% sospecha)." % [str(al_info["ally_name"]), killer_name, FALSE_ALIBI_RELIEF])
	# P2.3: Comprar o intimidar al primer testigo si el asesino es rico o agresivo
	var reporter: String = str(case_dict.get("reporter_name", ""))
	if killer_name != "" and reporter != "" and reporter != "Jugador" and reporter != killer_name:
		var killer_npc = null
		for n in VillageNeeds.living(vm):
			if n.npc_name == killer_name:
				killer_npc = n
				break
		if killer_npc != null and (int(killer_npc.personal_gold) >= 60 or TraitCatalog.npc_tendency(killer_npc, "aggression") >= 0.5):
			st["tampered"][v_name] = {"witness_name": reporter, "killer_name": killer_name, "reassured": false}
			clues.append("Testigo huidizo: %s parece asustado o presionado para callar lo que vio." % reporter)
	# P2.7: Cadáver movido de sitio
	if (st["moved"] as Dictionary).has(v_name) and not bool(st["moved"][v_name].get("tracked", false)):
		clues.append("Escena alterada: hay marcas en la tierra como si hubieran arrastrado el cuerpo desde otro punto.")
	# P2.11: Hora de la muerte trucada (rebaja la sospecha del asesino hasta que se revise la rigidez del cadáver)
	if (st["tampered_time"] as Dictionary).has(v_name) and not bool(st["tampered_time"][v_name].get("examined", false)):
		if killer_name != "" and suspects.has(killer_name):
			suspects[killer_name]["score"] = maxi(5, int(suspects[killer_name].get("score", 25)) - 15)
		clues.append("Hora de la muerte confusa: la temperatura del cuerpo no encaja del todo con el momento del hallazgo.")
	# Tanda 2 (6): Sello de un imitador (copycat)
	if (st["copycats"] as Dictionary).has(v_name) and not bool(st["copycats"][v_name].get("debunked", false)):
		var cc: Dictionary = st["copycats"][v_name]
		var im_k: String = str(cc.get("imitated_killer", ""))
		if suspects.has(im_k):
			suspects[im_k]["score"] = int(suspects[im_k].get("score", 15)) + 20
		if killer_name != "" and suspects.has(killer_name):
			suspects[killer_name]["score"] = maxi(5, int(suspects[killer_name].get("score", 25)) - 10)
		clues.append("Modus operandi repetido: las heridas imitan el sello de un crimen anterior atribuido a %s (+20%% sospecha)." % im_k)
	# P2.9: Chivo expiatorio del comisario corrupto
	var sheriff = vm.trade_npcs.get(VillageNPC.TradeRole.SHERIFF, null)
	if sheriff != null and VillageTown.is_corrupt(sheriff) and killer_name != "":
		var killer_npc2 = null
		for n in VillageNeeds.living(vm):
			if n.npc_name == killer_name:
				killer_npc2 = n
				break
		if killer_npc2 != null and (int(killer_npc2.personal_gold) >= 70 or int(killer_npc2.trade_role) == int(VillageNPC.TradeRole.NOBLE)):
			var scapegoat = null
			for n in VillageNeeds.living(vm):
				if n != killer_npc2 and VillageNeeds.class_of(n) in ["mendigo", "pobre"] and suspects.has(n.npc_name):
					scapegoat = n
					break
			if scapegoat != null:
				var bribe: int = mini(30, int(killer_npc2.personal_gold))
				killer_npc2.personal_gold -= bribe
				sheriff.personal_gold += bribe
				suspects[scapegoat.npc_name]["score"] = int(suspects[scapegoat.npc_name].get("score", 10)) + SCAPEGOAT_PTS
				suspects[killer_name]["score"] = maxi(5, int(suspects[killer_name].get("score", 25)) - 15)
				st["scapegoats"][v_name] = {"scapegoat_name": scapegoat.npc_name, "scapegoat_key": scapegoat.get_person_key(), "killer_name": killer_name, "exposed": false}
				clues.append("Informe oficial sesgado: el comisario señala con insistencia a %s como sospechoso principal (+%d%% sospecha)." % [scapegoat.npc_name, SCAPEGOAT_PTS])

# ==============================================================================
# Paso diario: P2.4 (Sicarios entre vecinos) y P2.8 (Confesión ebrio/fiebre)
# ==============================================================================
static func daily(vm) -> void:
	var st: Dictionary = state(vm)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	# P2.4: Un vecino rico o noble con un deseo de asesinato pero poca agresividad busca un sicario pobre y violento
	for d in vm.desires:
		if not bool(d.get("active", false)) or str(d.get("type", "")) != "murder" or d.has("mastermind"):
			continue
		var holder = by_key.get(str(d.get("holder", "")), null)
		var target = by_key.get(str(d.get("target", "")), null)
		if holder == null or target == null or int(holder.personal_gold) < 90 or TraitCatalog.npc_tendency(holder, "aggression") > 0.2:
			continue
		# Buscar sicario vecino o proponérselo al jugador
		var best_hitman = null
		for n in VillageNeeds.living(vm):
			if n == holder or n == target or int(n.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.PRIEST), int(VillageNPC.TradeRole.CHILD)]:
				continue
			if int(n.personal_gold) < 25 and TraitCatalog.npc_tendency(n, "aggression") + TraitCatalog.npc_tendency(n, "malice") >= 0.8:
				best_hitman = n
				break
		if best_hitman != null:
			holder.personal_gold -= HITMAN_PAY
			best_hitman.personal_gold += HITMAN_PAY
			d["mastermind"] = holder.get_person_key()
			d["mastermind_name"] = holder.npc_name
			d["holder"] = best_hitman.get_person_key()
			d["holder_name"] = best_hitman.npc_name
			VillageChronicle.add(vm, "hitman_hired", "%s pagó en secreto a %s para quitar de en medio a %s" % [holder.npc_name, best_hitman.npc_name, target.npc_name], false)
		elif not (st["player_contracts"] as Dictionary).has(holder.get_person_key()):
			st["player_contracts"][holder.get_person_key()] = {
				"mastermind_key": holder.get_person_key(), "mastermind_name": holder.npc_name,
				"target_key": target.get_person_key(), "target_name": target.npc_name,
				"desire_id": int(d["id"]), "pay": HITMAN_PAY, "heard": false, "accepted": false
			}
	# P2.8: Un asesino impune que está borracho o con fiebre gris delira y suelta su culpa
	for v_name in vm.npc_murders.keys():
		var k_name: String = str(vm.npc_murders[v_name])
		for n in VillageNeeds.living(vm):
			if n.npc_name != k_name:
				continue
			var key: String = n.get_person_key()
			if (st["slips"] as Dictionary).has(key):
				continue
			if VillageNeeds.is_drunk_key(key) or int(n.sick_level) >= 2:
				st["slips"][key] = {"killer_key": key, "killer_name": n.npc_name, "victim_name": str(v_name), "day": today(), "reported": false}
				var ev: Dictionary = vm.record_social_event("murder_slip", n, null, "%s murmuró entre delirios que él mató a %s" % [n.npc_name, str(v_name)])
				ev["known_by"] = {key: true}
				VillageChronicle.add(vm, "murder_slip", "Alguien, ebrio o febril, murmuró cosas extrañas sobre la muerte de %s" % str(v_name), false)
	# P2.4b: Contrato aceptado por el jugador: el rico paga solo cuando el objetivo ya está muerto (y solo lo que tenga)
	for mk in (st["player_contracts"] as Dictionary).keys():
		var pc: Dictionary = st["player_contracts"][mk]
		if not bool(pc.get("accepted", false)):
			continue
		var tgt = by_key.get(str(pc.get("target_key", "")), null)
		var mm = by_key.get(mk, null)
		if mm == null or mm.is_dead:
			st["player_contracts"].erase(mk)
			continue
		if tgt != null and not tgt.is_dead:
			continue
		var pl = VillageNeeds.player_of(vm)
		var inv_p = pl.get("inventory") if pl != null else null
		var paid: int = mini(int(pc.get("pay", HITMAN_PAY)), int(mm.personal_gold))
		mm.personal_gold -= paid
		if inv_p != null:
			inv_p.add_gold(paid)
		for m in vm.desires:
			if int(m.get("id", -1)) == int(pc.get("desire_id", -2)) and bool(m.get("active", false)):
				VillageDesires.finish(vm, m, "done")
		st["player_contracts"].erase(mk)
		if pl != null and pl.has_method("show_hint"):
			pl.show_hint("🗡️💰 %s te dejó %d de oro en secreto: el encargo contra %s está cumplido." % [str(pc["mastermind_name"]), paid, str(pc["target_name"])])
	# P2.12: Pólizas de seguro de vida sospechosas (suscritas antes de un asesinato o cobradas si nadie las destapa)
	for d in vm.desires:
		if not bool(d.get("active", false)) or str(d.get("type", "")) != "murder":
			continue
		var holder = by_key.get(str(d.get("holder", "")), null)
		var target = by_key.get(str(d.get("target", "")), null)
		if holder == null or target == null or (st["insurance"] as Dictionary).has(target.npc_name):
			continue
		if TraitCatalog.npc_tendency(holder, "greed") >= 0.2 or str(holder.family_id) == str(target.family_id):
			st["insurance"][target.npc_name] = {
				"victim_name": target.npc_name, "beneficiary_key": holder.get_person_key(),
				"beneficiary_name": holder.npc_name, "payout": INSURANCE_PAYOUT,
				"player_knows": false, "exposed": false, "paid": false, "victim_dead": false
			}
	# Pólizas inocentes entre parientes: así una póliza no señala al asesino por sí sola
	if randf() < 0.08:
		var adults: Array = []
		for n in VillageNeeds.living(vm):
			if int(n.trade_role) != int(VillageNPC.TradeRole.CHILD) and not VillageNeeds.is_outsider(n) and not (st["insurance"] as Dictionary).has(n.npc_name):
				adults.append(n)
		if not adults.is_empty():
			var ins_t = adults[randi() % adults.size()]
			for rel in VillageClans.relatives_of(vm, ins_t):
				if int(rel.trade_role) != int(VillageNPC.TradeRole.CHILD) and not rel.is_dead:
					st["insurance"][ins_t.npc_name] = {
						"victim_name": ins_t.npc_name, "beneficiary_key": rel.get_person_key(),
						"beneficiary_name": rel.npc_name, "payout": INSURANCE_PAYOUT,
						"player_knows": false, "exposed": false, "paid": false, "victim_dead": false, "innocent": true
					}
					break
	for iv_name in (st["insurance"] as Dictionary).keys():
		var ins: Dictionary = st["insurance"][iv_name]
		if bool(ins.get("victim_dead", false)) and not bool(ins.get("exposed", false)) and not bool(ins.get("paid", false)):
			var ben = by_key.get(str(ins.get("beneficiary_key", "")), null)
			var ts: Dictionary = VillageTown.state(vm)
			if ben != null and not ben.is_dead and int(ts.get("treasury", 0)) >= INSURANCE_PAYOUT:
				ts["treasury"] = int(ts["treasury"]) - INSURANCE_PAYOUT
				ben.personal_gold += INSURANCE_PAYOUT
				ins["paid"] = true
				VillageChronicle.add(vm, "insurance_paid", "%s cobró %d de oro de la póliza por el fallecimiento de %s" % [ben.npc_name, INSURANCE_PAYOUT, iv_name], true)

## Elimina charcos de sangre y huellas físicas de `vm.blood_puddles` (todos si `victim_filter == ""`, o los cercanos a `near_pos`).
static func clear_blood_puddles(vm, near_pos: Vector2 = Vector2.INF, max_dist: float = 95.0) -> int:
	if vm == null or vm.blood_puddles.is_empty():
		return 0
	var removed: int = 0
	for i in range(vm.blood_puddles.size() - 1, -1, -1):
		var pud: Dictionary = vm.blood_puddles[i]
		var p_pos: Vector2 = pud.get("pos", Vector2.ZERO)
		if near_pos != Vector2.INF and p_pos.distance_to(near_pos) > max_dist:
			continue
		var node = pud.get("node", null)
		if node != null and is_instance_valid(node):
			node.queue_free()
		for fp in (pud.get("footprint_nodes", []) as Array):
			if fp != null and is_instance_valid(fp):
				fp.queue_free()
		vm.blood_puddles.remove_at(i)
		removed += 1
	return removed

static func _press_twice(vm, tag: String) -> bool:
	var now: int = Time.get_ticks_msec()
	if str(vm.get_meta("e_confirm_tag", "")) == tag and now - int(vm.get_meta("e_confirm_ms", 0)) <= 4000:
		vm.set_meta("e_confirm_tag", "")
		return true
	vm.set_meta("e_confirm_tag", tag)
	vm.set_meta("e_confirm_ms", now)
	return false

## Interacción directa con un charco de sangre [E] para fregar la escena con lejía (con confirmación de doble E y riesgo de testigos).
static func try_interact(vm, player: Node2D, pos: Vector2) -> bool:
	if vm == null or player == null or vm.blood_puddles.is_empty():
		return false
	var has_near: bool = false
	for pud in vm.blood_puddles:
		if pos.distance_to(pud.get("pos", Vector2.ZERO)) <= 36.0:
			has_near = true
			break
	if not has_near:
		return false
	if not _press_twice(vm, "bleach_puddle"):
		if player.has_method("show_hint"):
			player.show_hint("🧽 Hay sangre y huellas aquí. Pulsa E otra vez para fregar la escena con lejía (%d Oro)." % BLEACH_COST)
		return true
	var inv = player.get("inventory")
	if inv == null or int(inv.gold) < BLEACH_COST:
		if player.has_method("show_hint"):
			player.show_hint("Necesitas %d de oro para comprar lejía y fregar la escena." % BLEACH_COST)
		return true
	bleach_crime_scene(vm, player, inv, pos)
	return true

static func bleach_crime_scene(vm, player: Node2D, inv, pos: Vector2 = Vector2.INF) -> bool:
	if inv == null or int(inv.gold) < BLEACH_COST:
		return false
	inv.add_gold(-BLEACH_COST)
	if vm.shop_businesses.has(int(VillageNPC.TradeRole.DOCTOR)):
		vm.shop_businesses[int(VillageNPC.TradeRole.DOCTOR)]["vault_gold"] = int(vm.shop_businesses[int(VillageNPC.TradeRole.DOCTOR)].get("vault_gold", 0)) + BLEACH_COST
	else:
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + BLEACH_COST
	# ¿Alguien ve al jugador fregando la sangre?
	var check_pos: Vector2 = pos if pos != Vector2.INF else (player.global_position if player != null else Vector2.ZERO)
	for w in VillageNeeds.living(vm):
		if not w.is_conscious():
			continue
		if w.global_position.distance_to(check_pos) <= 160.0 and vm.has_line_of_sight(w.global_position, check_pos):
			vm.wanted_level = int(vm.wanted_level) + 1
			var susp_w: Dictionary = vm.active_sheriff_investigation.get("suspects", {})
			if susp_w.has("Jugador"):
				susp_w["Jugador"]["score"] = int(susp_w["Jugador"].get("score", 15)) + 25
			w._spawn_floating_text("🚨 «¡Eh! ¡Está borrando la sangre del crimen con lejía!»", Color.ORANGE_RED, -46.0)
			return false
	clear_blood_puddles(vm, pos, 95.0)
	if player != null and player.has_meta("bloody_steps_left"):
		player.set_meta("bloody_steps_left", 0)
	var susp: Dictionary = vm.active_sheriff_investigation.get("suspects", {})
	if susp.has("Jugador"):
		susp["Jugador"]["score"] = maxi(0, int(susp["Jugador"].get("score", 20)) - 20)
	if player != null and player.has_method("show_hint"):
		player.show_hint("🧽✨ Fregaste la sangre y las huellas con lejía sin que nadie te viera (-20%% sospecha).")
	return true

# ==============================================================================
# Diálogos de investigación, pistas falsas, emboscadas y sicarios
# ==============================================================================
static func _desire_known(vm, desire_id: int) -> bool:
	for d in vm.desires:
		if int(d.get("id", -2)) == desire_id:
			return bool(d.get("player_knows", false))
	return false

static func has_known_dirt_on(vm, npc) -> bool:
	if vm == null or npc == null:
		return false
	var key: String = npc.get_person_key()
	for s in vm.secrets:
		if bool(s.get("active", false)) and bool(s.get("player_knows", false)):
			if str(s.get("a", "")) == key or str(s.get("b", "")) == key or str(s.get("holder", "")) == key:
				return true
	if (vm.sect_state.get("members", {}) as Dictionary).has(key) and bool(vm.sect_state.get("player_knows", false)):
		return true
	if vm.VillageTown.is_corrupt(npc) and bool(vm.town_state.get("corrupt_known", false)):
		return true
	return false

static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null or npc == null:
		return
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key()
	var is_law: bool = int(npc.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.ROYAL_INVESTIGATOR)]
	var is_doc: bool = int(npc.trade_role) == int(VillageNPC.TradeRole.DOCTOR)
	var case_dict: Dictionary = vm.active_sheriff_investigation if bool(vm.active_sheriff_investigation.get("active", false)) else (vm.active_royal_investigation if bool(vm.active_royal_investigation.get("active", false)) else {})
	var v_name: String = str(case_dict.get("victim_name", ""))
	var f_choices: Array = []

	# P2.5: Autopsia por veneno lento: solo de cuerpos ya hallados (si no, el menú delataría que hubo veneno)
	if is_doc or is_law:
		for pv in (st["poisoned"] as Dictionary).keys():
			var p_info: Dictionary = st["poisoned"][pv]
			var body = vm._find_corpse_npc_by_name(pv)
			if not bool(p_info.get("autopsied", false)) and body != null and (bool(body.corpse_discovered) or bool(body.corpse_in_morgue)):
				f_choices.append({"label": "🧪🔬 Solicitar análisis toxicológico del cuerpo de %s" % pv, "next": "END", "action": "forensic_autopsy:" + pv})

	# Opciones sobre el caso abierto. Regla: ninguna etiqueta nombra al asesino real antes de que el jugador lo averigüe.
	if not case_dict.is_empty() and v_name != "":
		# P2.1: Desmontar prueba falsa ante el comisario (el objeto plantado ya figura en el expediente)
		if is_law and (st["planted"] as Dictionary).has(v_name) and not bool(st["planted"][v_name].get("debunked", false)):
			var fn: String = str(st["planted"][v_name]["framed_name"])
			f_choices.append({"label": "🔍⚖️ Demostrar que el objeto de %s fue colocado a propósito" % ("tu propiedad" if fn == "Jugador" else fn), "next": "END", "action": "forensic_debunk:" + v_name})
		# P2.2: Romper la coartada hablando con quien la dio (la coartada ya figura en el expediente)
		if (st["alibis"] as Dictionary).has(v_name) and not bool(st["alibis"][v_name].get("broken", false)):
			var al: Dictionary = st["alibis"][v_name]
			if npc.npc_name == str(al["ally_name"]):
				f_choices.append({"label": "🕵️💥 Apretarle sobre la coartada que dio a %s" % str(al["killer_name"]), "next": "END", "action": "forensic_break_alibi:" + v_name})
		# P2.3: Tranquilizar al testigo intimidado (solo hablando con el propio testigo)
		if (st["tampered"] as Dictionary).has(v_name) and not bool(st["tampered"][v_name].get("reassured", false)):
			var tm: Dictionary = st["tampered"][v_name]
			if npc.npc_name == str(tm["witness_name"]):
				f_choices.append({"label": "🛡️🗣️ Darle garantías para que declare sin miedo", "next": "END", "action": "forensic_reassure:" + v_name})
		# P2.4: Destapar el crimen por encargo, solo si el jugador ya conocía el plan de asesinato
		if is_law and (st["hitmen"] as Dictionary).has(v_name) and not bool(st["hitmen"][v_name].get("exposed", false)):
			var hm: Dictionary = st["hitmen"][v_name]
			if _desire_known(vm, int(hm.get("desire_id", -1))):
				f_choices.append({"label": "💰🚨 Revelar que %s contrató a %s como sicario (+35 Oro)" % [str(hm["mastermind_name"]), str(hm["hitman_name"])], "next": "END", "action": "forensic_expose_hitman:" + v_name})
		# P2.6: Incriminar a un vecino plantando una pista falsa
		if not is_law and case_dict.get("suspects", {}).has(npc.npc_name):
			ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🧤 Plantar pista falsa contra %s en el caso de %s (-%d Oro)" % [npc.npc_name, v_name, FRAME_COST], "next": "END", "action": "forensic_frame:" + npc.npc_name})
		# P2.7: Pedir que sigan el rastro de arrastre (la marca ya figura en el expediente; no se dice adónde lleva)
		if is_law and (st["moved"] as Dictionary).has(v_name) and not bool(st["moved"][v_name].get("tracked", false)):
			f_choices.append({"label": "👣 Pedir que sigan el rastro de arrastre del cadáver", "next": "END", "action": "forensic_track_drag:" + v_name})
		# P2.9: El chivo expiatorio te pide ayuda (solo hablando con él/ella)
		if (st["scapegoats"] as Dictionary).has(v_name) and not bool(st["scapegoats"][v_name].get("exposed", false)):
			var sg: Dictionary = st["scapegoats"][v_name]
			if npc.npc_name == str(sg["scapegoat_name"]):
				f_choices.append({"label": "⚖️🔓 Ayudarle a demostrar que el comisario le señala sin pruebas", "next": "END", "action": "forensic_scapegoat:" + v_name})
		# Tanda 1 (1): La lejía se usa EN la escena (E sobre el charco), no desde un diálogo a distancia
		# Tanda 1 (2): Sobornar al médico para falsear la autopsia
		if is_doc and not bool(case_dict.get("autopsy_bribed", false)):
			f_choices.append({"label": "🩺💰 Sobornar al médico para certificar fallo natural o borrar pistas del arma (-%d Oro)" % BRIBE_AUTOPSY_COST, "next": "END", "action": "forensic_bribe_autopsy:" + v_name})
		# Tanda 1 (3): Pólizas de seguro de vida sospechosas (primero consultar el libro sin revelar nombres; luego denunciar)
		# La consulta se ofrece SIEMPRE (haya póliza o no), para que la opción en sí no delate nada.
		var ins: Dictionary = (st["insurance"] as Dictionary).get(v_name, {})
		var ins_asked: bool = (case_dict.get("insurance_asked", {}) as Dictionary).has(v_name)
		if (is_doc or vm.VillageTown.is_mayor(vm, npc)) and not ins_asked:
			f_choices.append({"label": "📜🔍 Consultar en el registro si existía alguna póliza de vida a nombre de %s (-%d Oro)" % [v_name, INSURANCE_LOOKUP_COST], "next": "END", "action": "forensic_check_insurance:" + v_name})
		if not ins.is_empty() and not bool(ins.get("exposed", false)):
			if bool(ins.get("player_knows", false)) and is_law:
					f_choices.append({"label": "📜🚨 Denunciar que %s suscribió una póliza de vida sobre %s antes del crimen" % [str(ins["beneficiary_name"]), v_name], "next": "END", "action": "forensic_expose_insurance:" + v_name})
		# Tanda 1 (4): Comprobar si trucaron la hora de la muerte (sin revelar al asesino en el menú)
		if (is_doc or is_law) and (st["tampered_time"] as Dictionary).has(v_name) and not bool(st["tampered_time"][v_name].get("examined", false)):
			f_choices.append({"label": "🕰️🔬 Examinar la rigidez del cadáver de %s para verificar la hora real de la muerte" % v_name, "next": "END", "action": "forensic_check_rigor:" + v_name})
		# Tanda 2 (6): Desmontar un crimen por imitación comparando las heridas (sin nombrar al asesino real en el menú)
		if (is_doc or is_law) and (st["copycats"] as Dictionary).has(v_name) and not bool(st["copycats"][v_name].get("debunked", false)):
			f_choices.append({"label": "🔪🔍 Comparar las heridas de %s con crímenes anteriores para descartar un imitador" % v_name, "next": "END", "action": "forensic_debunk_copycat:" + v_name})
		# Tanda 2 (7): Forzar una confesión falsa chantajeando a un vecino cuyo secreto conoces
		if not is_law and (case_dict.get("suspects", {}).has("Jugador") or int(vm.wanted_level) > 0) and has_known_dirt_on(vm, npc):
			f_choices.append({"label": "🤫⚖️ Chantajearle con su secreto para que se declare culpable del caso de %s" % v_name, "next": "END", "action": "forensic_force_confession:" + v_name})

	# Tanda 1 (5): Limpiador nocturno de cadáveres y rastros de sangre (con el perista de noche)
	if vm.VillageUnderworld.is_fence(vm, npc) and not vm.blood_puddles.is_empty():
		f_choices.append({"label": "🧹🌙 Pagar al limpiador nocturno para borrar los charcos de sangre antes del alba (-%d Oro)" % CLEANER_COST, "next": "END", "action": "forensic_hire_cleaner"})

	# P2.4b: Contrato de sicario ofrecido al jugador por un rico: primero lo escuchas, luego decides
	if (st["player_contracts"] as Dictionary).has(key):
		var pc: Dictionary = st["player_contracts"][key]
		if not bool(pc.get("heard", false)):
			f_choices.append({"label": "🗡️ Escuchar lo que quiere proponerte en voz baja", "next": "END", "action": "forensic_contract_listen:" + key})
		elif not bool(pc.get("accepted", false)):
			f_choices.append({"label": "🗡️💰 Aceptar el encargo contra %s (cobras %d cuando esté hecho)" % [str(pc["target_name"]), int(pc["pay"])], "next": "END", "action": "forensic_contract_accept:" + key})
	if is_law:
		for mk in (st["player_contracts"] as Dictionary).keys():
			var pc2: Dictionary = st["player_contracts"][mk]
			if bool(pc2.get("heard", false)):
				f_choices.append({"label": "🚨 Denunciar que %s busca un sicario para matar a %s (+30 Oro)" % [str(pc2["mastermind_name"]), str(pc2["target_name"])], "next": "END", "action": "forensic_contract_report:" + mk})

	# P2.8: Oír los desvaríos del asesino ebrio o febril (hablando con él mientras sigue así) y luego delatarlo
	if (st["slips"] as Dictionary).has(key):
		var sl0: Dictionary = st["slips"][key]
		if not bool(sl0.get("heard", false)) and (int(sl0.get("day", -1)) == today() or VillageNeeds.is_drunk_key(key) or int(npc.sick_level) >= 2):
			f_choices.append({"label": "🍷👂 Dejarle hablar: no para de murmurar cosas raras", "next": "END", "action": "forensic_listen_slip:" + key})
	if is_law:
		for sk in (st["slips"] as Dictionary).keys():
			var sl: Dictionary = st["slips"][sk]
			if bool(sl.get("heard", false)) and not bool(sl.get("reported", false)):
				f_choices.append({"label": "🍷🚨 Informar que %s confesó ebrio/febril haber matado a %s (+35 Oro)" % [str(sl["killer_name"]), str(sl["victim_name"])], "next": "END", "action": "forensic_slip:" + sk})

	# P2.10: Tender emboscada nocturna a un asesino cuyo plan conoces
	if is_law:
		for m in vm.desires:
			if bool(m.get("active", false)) and str(m.get("type", "")) == "murder" and bool(m.get("player_knows", false)):
				f_choices.append({"label": "🪤🌙 Tender emboscada nocturna a %s junto a %s (+%d Oro)" % [str(m["holder_name"]), str(m["target_name"]), AMBUSH_REWARD], "next": "END", "action": "forensic_ambush:%d" % int(m["id"])})

	if not f_choices.is_empty():
		f_choices.append({"label": "⬅️ Volver", "next": "start"})
		diag["forensic_menu"] = {"text": "🔎 Investigación forense, pistas y coartadas:", "choices": f_choices}
		ch_arr.insert(0, {"label": "🔎 Pruebas, coartadas y pistas del caso…", "next": "forensic_menu"})

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	var st: Dictionary = state(vm)
	var arg: String = action_id.get_slice(":", 1)
	var case_dict: Dictionary = vm.active_sheriff_investigation if (bool(vm.active_sheriff_investigation.get("active", false)) or vm.active_sheriff_investigation.has("suspects")) else (vm.active_royal_investigation if (bool(vm.active_royal_investigation.get("active", false)) or vm.active_royal_investigation.has("suspects")) else {})
	var suspects: Dictionary = case_dict.get("suspects", {})
	var clues: Array = case_dict.get("clues_log", [])

	if action_id.begins_with("forensic_autopsy:"):
		if not (st["poisoned"] as Dictionary).has(arg):
			return
		var p_info: Dictionary = st["poisoned"][arg]
		p_info["autopsied"] = true
		var victim = vm._find_corpse_npc_by_name(arg)
		if victim != null:
			victim.last_hit_weapon_name = "Envenenamiento lento confirmado"
			vm.start_sheriff_investigation(victim, victim.death_world_pos, victim.last_hit_weapon_name, "Jugador")
		if bool(vm.active_sheriff_investigation.get("active", false)):
			var susp2: Dictionary = vm.active_sheriff_investigation.get("suspects", {})
			var kn: String = str(p_info["killer_name"])
			if susp2.has(kn):
				susp2[kn]["score"] = int(susp2[kn].get("score", 10)) + 30
		VillageChronicle.add(vm, "poison_autopsy", "La autopsia de %s reveló que fue asesinado con veneno lento" % arg, true)
		npc._spawn_floating_text("🧪 «¡No fue muerte natural! Hay restos de veneno lento en la sangre.»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("forensic_debunk:"):
		if not (st["planted"] as Dictionary).has(arg):
			return
		var pl_info: Dictionary = st["planted"][arg]
		pl_info["debunked"] = true
		var fn: String = str(pl_info["framed_name"])
		var kn: String = str(pl_info["killer_name"])
		if suspects.has(fn):
			suspects[fn]["score"] = maxi(0, int(suspects[fn].get("score", 20)) - 25)
		if suspects.has(kn):
			suspects[kn]["score"] = int(suspects[kn].get("score", 20)) + 25
		clues.append("Prueba falsa desmontada: el objeto de %s lo colocó otra persona para despistar." % ("el Forastero" if fn == "Jugador" else fn))
		for n in VillageNeeds.living(vm):
			if n.npc_name == fn:
				VillageClans.grant_honor_debt(vm, n, "le libró de una prueba falsa de asesinato")
				break
		npc.modify_affinity(10)
		npc._spawn_floating_text("🔍 «Tienes razón: esa prueba fue colocada para despistarnos.»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("forensic_break_alibi:"):
		if not (st["alibis"] as Dictionary).has(arg):
			return
		var al: Dictionary = st["alibis"][arg]
		al["broken"] = true
		var kn: String = str(al["killer_name"])
		if suspects.has(kn):
			suspects[kn]["mem_alibi_partner"] = ""
			suspects[kn]["score"] = int(suspects[kn].get("score", 20)) + 30
			suspects[kn]["status_note"] = "Su coartada resultó ser una mentira de %s" % str(al["ally_name"])
		clues.append("Coartada rota: %s confesó que mintió para encubrir a %s (+30%% sospecha)." % [str(al["ally_name"]), kn])
		npc._spawn_floating_text("😰 «¡Está bien, mentí! No estuvo en casa aquella noche...»", Color.GOLD, -46.0)

	elif action_id.begins_with("forensic_reassure:"):
		if not (st["tampered"] as Dictionary).has(arg):
			return
		var tm: Dictionary = st["tampered"][arg]
		tm["reassured"] = true
		var kn: String = str(tm["killer_name"])
		if suspects.has(kn):
			suspects[kn]["score"] = int(suspects[kn].get("score", 20)) + 25
		clues.append("Testigo protegido: %s declaró que %s le amenazó tras el crimen (+25%% sospecha)." % [str(tm["witness_name"]), kn])
		npc.modify_affinity(12)
		npc._spawn_floating_text("🛡️ «Gracias... ahora me atrevo a decirlo: fue %s quien me amenazó.»" % kn, Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("forensic_expose_hitman:"):
		if not (st["hitmen"] as Dictionary).has(arg):
			return
		var hm: Dictionary = st["hitmen"][arg]
		hm["exposed"] = true
		for n_name in [str(hm["mastermind_name"]), str(hm["hitman_name"])]:
			if suspects.has(n_name):
				suspects[n_name]["score"] = int(suspects[n_name].get("score", 20)) + 35
		clues.append("Crimen por encargo: %s pagó %d de oro a %s para ejecutar el asesinato (+35%% sospecha)." % [str(hm["mastermind_name"]), HITMAN_PAY, str(hm["hitman_name"])])
		var mm_hm = vm._get_npcs_by_person_key().get(str(hm.get("mastermind_key", "")), null)
		var hm_paid: int = 0
		if mm_hm != null:
			hm_paid = mini(35, maxi(0, int(mm_hm.personal_gold)))
			mm_hm.personal_gold -= hm_paid
		var tr_hm: int = mini(35 - hm_paid, maxi(0, int(vm.town_state.get("treasury", 0))))
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - tr_hm
		var total_hm: int = hm_paid + tr_hm
		if inv != null and total_hm > 0:
			inv.add_gold(total_hm)
		npc._spawn_floating_text("🚨 «¡Así que pagó a un sicario! Ambos responderán ante la ley.» (+%d Oro)" % total_hm, Color.GOLD, -46.0)

	elif action_id.begins_with("forensic_frame:"):
		if inv == null or int(inv.gold) < FRAME_COST:
			npc._spawn_floating_text("Necesitas %d de oro para preparar la pista falsa" % FRAME_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-FRAME_COST)
		npc.personal_gold += FRAME_COST
		if suspects.has(arg):
			suspects[arg]["score"] = int(suspects[arg].get("score", 10)) + 25
			suspects[arg]["mem_alibi_partner"] = ""
		if suspects.has("Jugador"):
			suspects["Jugador"]["score"] = maxi(0, int(suspects["Jugador"].get("score", 15)) - 15)
		clues.append("Pista hallada: apareció una pertenencia de %s cerca del lugar del crimen (+25%% sospecha)." % arg)
		npc._spawn_floating_text("🧤 Colocaste en secreto una prueba que incrimina a %s" % arg, Color(0.85, 0.75, 1.0), -46.0)

	elif action_id.begins_with("forensic_track_drag:"):
		if not (st["moved"] as Dictionary).has(arg):
			return
		var mv: Dictionary = st["moved"][arg]
		mv["tracked"] = true
		var kn: String = str(mv["killer_name"])
		if suspects.has(kn):
			suspects[kn]["score"] = int(suspects[kn].get("score", 20)) + 20
		clues.append("Rastro forense: el cuerpo no murió donde se encontró; lo arrastraron de noche. El comisario revisa a quién se vio por allí.")
		npc._spawn_floating_text("👣 «Lo arrastraron hasta aquí. Ya sé por dónde seguir.»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("forensic_scapegoat:"):
		if not (st["scapegoats"] as Dictionary).has(arg):
			return
		var sg: Dictionary = st["scapegoats"][arg]
		sg["exposed"] = true
		var sg_name: String = str(sg["scapegoat_name"])
		var kn: String = str(sg["killer_name"])
		if suspects.has(sg_name):
			suspects[sg_name]["score"] = maxi(0, int(suspects[sg_name].get("score", 30)) - 35)
		if suspects.has(kn):
			suspects[kn]["score"] = int(suspects[kn].get("score", 20)) + 35
		for n in VillageNeeds.living(vm):
			if n.npc_name == sg_name:
				VillageClans.grant_honor_debt(vm, n, "demostró que era un chivo expiatorio inocente")
				break
		clues.append("Acusación sin pruebas: el informe contra %s no se sostiene; alguien quería cerrar el caso deprisa." % sg_name)
		VillageChronicle.add(vm, "scapegoat_cleared", "Se demostró que %s era un chivo expiatorio del comisario" % sg_name, true)
		npc._spawn_floating_text("⚖️ «¡Gracias! Ahora todos saben que no fui yo.»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("forensic_contract_listen:"):
		if not (st["player_contracts"] as Dictionary).has(arg):
			return
		var pc0: Dictionary = st["player_contracts"][arg]
		pc0["heard"] = true
		npc._spawn_floating_text("🗡️ «Quiero a %s fuera de mi camino. Te pagaré %d cuando esté hecho.»" % [str(pc0["target_name"]), int(pc0["pay"])], Color.GOLD, -46.0)

	elif action_id.begins_with("forensic_contract_accept:"):
		if not (st["player_contracts"] as Dictionary).has(arg):
			return
		var pc: Dictionary = st["player_contracts"][arg]
		pc["accepted"] = true
		npc._spawn_floating_text("🗡️ «Trato hecho. Ni un céntimo hasta que %s no respire. Que parezca un accidente.»" % str(pc["target_name"]), Color.GOLD, -46.0)

	elif action_id.begins_with("forensic_contract_report:"):
		if not (st["player_contracts"] as Dictionary).has(arg):
			return
		var pc: Dictionary = st["player_contracts"][arg]
		var mm = vm._get_npcs_by_person_key().get(arg, null)
		var fine_taken: int = 0
		if mm != null:
			fine_taken = mini(40, maxi(0, int(mm.personal_gold)))
			mm.personal_gold -= fine_taken
			mm.modify_affinity(-40)
		for m in vm.desires:
			if int(m.get("id", -1)) == int(pc.get("desire_id", -2)):
				VillageDesires.finish(vm, m, "foiled")
		st["player_contracts"].erase(arg)
		var rew_cr: int = mini(30, fine_taken)
		if rew_cr < 30:
			var tr_cr: int = mini(30 - rew_cr, maxi(0, int(vm.town_state.get("treasury", 0))))
			vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - tr_cr
			rew_cr += tr_cr
		elif fine_taken > 30:
			vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + (fine_taken - 30)
		if inv != null and rew_cr > 0:
			inv.add_gold(rew_cr)
		VillageFaith.add_rep(vm, "law", 8)
		VillageChronicle.add(vm, "hitman_foiled", "Denunciaste que %s intentaba contratar un sicario contra %s" % [str(pc["mastermind_name"]), str(pc["target_name"])], true)
		npc._spawn_floating_text("🚨 «Lo multaremos ahora mismo. Toma %d de oro por avisar.»" % rew_cr, Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("forensic_listen_slip:"):
		if not (st["slips"] as Dictionary).has(arg):
			return
		var sl0: Dictionary = st["slips"][arg]
		sl0["heard"] = true
		npc._spawn_floating_text("🥴 «...no quería... %s no tenía que mirarme así... la sangre no se va...»" % str(sl0["victim_name"]), Color(0.9, 0.8, 1.0), -46.0)
		var pl_s = VillageNeeds.player_of(vm)
		if pl_s != null and pl_s.has_method("show_hint"):
			pl_s.show_hint("👂 %s acaba de soltar entre delirios que mató a %s. Podrías contárselo a la guardia." % [npc.npc_name, str(sl0["victim_name"])])

	elif action_id.begins_with("forensic_slip:"):
		if not (st["slips"] as Dictionary).has(arg):
			return
		var sl: Dictionary = st["slips"][arg]
		sl["reported"] = true
		var kn: String = str(sl["killer_name"])
		var vn: String = str(sl["victim_name"])
		if suspects.has(kn):
			suspects[kn]["score"] = int(suspects[kn].get("score", 20)) + 45
		vm._mark_morgue_case_resolved(vn, "Confesión de %s (delatado ante la guardia)" % kn) # ya avisa a los clanes
		var killer_sl = vm._get_npcs_by_person_key().get(arg, null)
		var sl_paid: int = 0
		if killer_sl != null:
			sl_paid = mini(35, maxi(0, int(killer_sl.personal_gold)))
			killer_sl.personal_gold -= sl_paid
		var tr_sl: int = mini(35 - sl_paid, maxi(0, int(vm.town_state.get("treasury", 0))))
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - tr_sl
		var total_sl: int = sl_paid + tr_sl
		if inv != null and total_sl > 0:
			inv.add_gold(total_sl)
		npc._spawn_floating_text("🍷🚨 «Con esa confesión cerramos el caso de %s contra %s. Toma %d de oro.»" % [vn, kn, total_sl], Color.GOLD, -46.0)

	elif action_id.begins_with("forensic_ambush:"):
		var did: int = int(arg)
		for m in vm.desires:
			if int(m.get("id", -1)) == did and bool(m.get("active", false)):
				var by_key: Dictionary = vm._get_npcs_by_person_key()
				var killer = by_key.get(str(m["holder"]), null)
				var target = by_key.get(str(m["target"]), null)
				var amb_paid: int = 0
				if killer != null:
					amb_paid = mini(AMBUSH_REWARD, maxi(0, int(killer.personal_gold)))
					killer.personal_gold -= amb_paid
					killer.modify_affinity(-45)
				if target != null:
					target.modify_affinity(20)
					VillageClans.grant_honor_debt(vm, target, "atrapó en una emboscada nocturna a quien iba a matarle")
				VillageDesires.finish(vm, m, "foiled")
				var tr_amb: int = mini(AMBUSH_REWARD - amb_paid, maxi(0, int(vm.town_state.get("treasury", 0))))
				vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - tr_amb
				var total_amb: int = amb_paid + tr_amb
				if inv != null and total_amb > 0:
					inv.add_gold(total_amb)
				VillageFaith.add_rep(vm, "law", 10)
				VillageChronicle.add(vm, "murder_ambushed", "Tendiste una emboscada nocturna con la guardia y atrapaste a %s cuando iba a matar a %s" % [str(m["holder_name"]), str(m["target_name"])], true)
				npc._spawn_floating_text("🪤🌙 «¡Lo pillamos con el cuchillo en la mano! Toma %d de oro de recompensa.»" % total_amb, Color.GOLD, -46.0)
				return

	elif action_id.begins_with("forensic_bleach_scene:"):
		var pl_b = VillageNeeds.player_of(vm)
		if inv == null or int(inv.gold) < BLEACH_COST:
			npc._spawn_floating_text("Necesitas %d de oro para la lejía" % BLEACH_COST, Color.ORANGE_RED, -44.0)
			return
		var target_pos: Vector2 = Vector2.INF
		if not vm.blood_puddles.is_empty():
			target_pos = vm.blood_puddles[0].get("pos", Vector2.INF)
		if bleach_crime_scene(vm, pl_b, inv, target_pos):
			npc._spawn_floating_text("🧽 «Con esta lejía no quedará ni rastro de sangre en las piedras.»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("forensic_bribe_autopsy:"):
		if inv == null or int(inv.gold) < BRIBE_AUTOPSY_COST:
			npc._spawn_floating_text("Necesitas %d de oro para sobornar al médico" % BRIBE_AUTOPSY_COST, Color.ORANGE_RED, -44.0)
			return
		if TraitCatalog.npc_tendency(npc, "honesty") >= 0.5 and int(npc.affinity) < 60:
			npc.modify_affinity(-10)
			npc._spawn_floating_text("😠🩺 «¡Mi juramento médico no está en venta!» (-10 Afinidad)", Color.ORANGE_RED, -46.0)
			return
		inv.add_gold(-BRIBE_AUTOPSY_COST)
		npc.personal_gold += BRIBE_AUTOPSY_COST
		case_dict["autopsy_bribed"] = true
		if (st["poisoned"] as Dictionary).has(arg):
			st["poisoned"][arg]["autopsied"] = true
			st["poisoned"][arg]["falsified"] = true
		for rec in vm.morgue_active_corpses:
			if str(rec.get("victim_name", "")) == arg:
				rec["cause"] = "Paro cardíaco certificado por el médico"
		if suspects.has("Jugador"):
			suspects["Jugador"]["score"] = maxi(0, int(suspects["Jugador"].get("score", 20)) - 25)
		clues.append("Informe médico revisado: el doctor atribuye las lesiones a una caída o fallo súbito (-25%% sospecha al Forastero).")
		npc._spawn_floating_text("🩺🤫 «Escribiré en el acta que fue un fallo natural. Nadie hará más preguntas.»", Color.GOLD, -46.0)

	elif action_id.begins_with("forensic_check_insurance:"):
		if inv == null or int(inv.gold) < INSURANCE_LOOKUP_COST:
			npc._spawn_floating_text("Necesitas %d de oro para consultar el registro" % INSURANCE_LOOKUP_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-INSURANCE_LOOKUP_COST)
		npc.personal_gold += INSURANCE_LOOKUP_COST
		if not case_dict.is_empty():
			if not case_dict.has("insurance_asked") or not (case_dict["insurance_asked"] is Dictionary):
				case_dict["insurance_asked"] = {}
			case_dict["insurance_asked"][arg] = true
		if not (st["insurance"] as Dictionary).has(arg):
			npc._spawn_floating_text("📜 «No consta ninguna póliza de vida a nombre de %s.»" % arg, Color(0.85, 0.85, 0.85), -46.0)
			return
		var ins: Dictionary = st["insurance"][arg]
		ins["player_knows"] = true
		# Ojo: también hay pólizas inocentes entre parientes; tener una no prueba nada por sí sola
		npc._spawn_floating_text("📜 «Consta una póliza: %s cobraría %d de oro si %s moría. Muchas familias las tienen, ojo.»" % [str(ins["beneficiary_name"]), int(ins["payout"]), arg], Color.GOLD, -46.0)

	elif action_id.begins_with("forensic_expose_insurance:"):
		if not (st["insurance"] as Dictionary).has(arg):
			return
		var ins2: Dictionary = st["insurance"][arg]
		ins2["exposed"] = true
		var b_name: String = str(ins2["beneficiary_name"])
		if suspects.has(b_name):
			suspects[b_name]["score"] = int(suspects[b_name].get("score", 15)) + 30
		clues.append("Móvil económico: %s había contratado una póliza sobre la vida de %s (+30%% sospecha; cobro bloqueado)." % [b_name, arg])
		var ts_i: Dictionary = VillageTown.state(vm)
		var reward_i: int = mini(15, int(ts_i.get("treasury", 0)))
		if reward_i > 0 and inv != null:
			ts_i["treasury"] = int(ts_i["treasury"]) - reward_i
			inv.add_gold(reward_i)
		VillageChronicle.add(vm, "insurance_exposed", "Destapaste que %s pretendía cobrar un seguro por la muerte de %s" % [b_name, arg], true)
		npc._spawn_floating_text("📜🚨 «¡Conque quería cobrar la póliza de %s! Queda congelada y %s pasa a encabezar la lista.»" % [arg, b_name], Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("forensic_check_rigor:"):
		if not (st["tampered_time"] as Dictionary).has(arg):
			return
		var tt: Dictionary = st["tampered_time"][arg]
		tt["examined"] = true
		var kn: String = str(tt["killer_name"])
		if suspects.has(kn):
			suspects[kn]["score"] = int(suspects[kn].get("score", 15)) + 25
		clues.append("Hora real de la muerte: la rigidez del cadáver demuestra que enfriaron el cuerpo para fingir otra hora (+25%% sospecha a quien tenía coartada para más tarde).")
		npc._spawn_floating_text("🕰️🔬 «¡El rigor mortis no engaña! Enfriaron el cuerpo para falsear la hora de la muerte.»", Color.SPRING_GREEN, -46.0)

	elif action_id == "forensic_hire_cleaner":
		if inv == null or int(inv.gold) < CLEANER_COST:
			npc._spawn_floating_text("Necesitas %d de oro para el limpiador nocturno" % CLEANER_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-CLEANER_COST)
		npc.personal_gold += CLEANER_COST
		var cleaned: int = clear_blood_puddles(vm)
		if suspects.has("Jugador"):
			suspects["Jugador"]["score"] = maxi(0, int(suspects["Jugador"].get("score", 20)) - 20)
		npc._spawn_floating_text("🧹🌙 «Mis hombres ya han limpiado %d rastro(s) de sangre. Al amanecer no habrá nada.»" % maxi(1, cleaned), Color.GOLD, -46.0)

	elif action_id.begins_with("forensic_debunk_copycat:"):
		if not (st["copycats"] as Dictionary).has(arg):
			return
		var cc: Dictionary = st["copycats"][arg]
		cc["debunked"] = true
		var im_k: String = str(cc["imitated_killer"])
		var real_k: String = str(cc["killer_name"])
		if suspects.has(im_k):
			suspects[im_k]["score"] = maxi(0, int(suspects[im_k].get("score", 20)) - 20)
		if suspects.has(real_k):
			suspects[real_k]["score"] = int(suspects[real_k].get("score", 15)) + 25
		clues.append("Imitador descubierto: las heridas de %s solo fingen la firma del caso de %s (+25%% sospecha al autor real)." % [arg, str(cc.get("imitated_victim", "un crimen anterior"))])
		npc._spawn_floating_text("🔪🔬 «¡Fíjate en el corte! No es la misma mano que mató a %s: alguien ha imitado el crimen.»" % str(cc.get("imitated_victim", "un crimen anterior")), Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("forensic_force_confession:"):
		if not has_known_dirt_on(vm, npc):
			return
		if suspects.has("Jugador"):
			suspects["Jugador"]["score"] = 0
		if suspects.has(npc.npc_name):
			suspects[npc.npc_name]["score"] = 100
		vm.wanted_level = 0
		vm._mark_morgue_case_resolved(arg, "Confesión de %s (bajo coacción)" % npc.npc_name)
		npc.modify_affinity(-80)
		VillageClans.mark_player_offense(vm, npc, true)
		VillageChronicle.add(vm, "forced_confession", "%s se declaró culpable de la muerte de %s para que no saliera a la luz su secreto" % [npc.npc_name, arg], true)
		npc._spawn_floating_text("😰⚖️ «¡Calla, por favor! Diré al comisario que fui yo antes de que arruines mi nombre...»", Color.ORANGE_RED, -46.0)
