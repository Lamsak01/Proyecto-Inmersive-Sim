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

static func state(vm) -> Dictionary:
	var ts: Dictionary = VillageTown.state(vm)
	if not ts.has("forensics") or not (ts["forensics"] is Dictionary):
		ts["forensics"] = {}
	var st: Dictionary = ts["forensics"]
	for k in ["planted", "alibis", "tampered", "hitmen", "poisoned", "moved", "slips", "scapegoats", "player_contracts"]:
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
			"hitman_key": killer.get_person_key(), "hitman_name": killer.npc_name, "exposed": false
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
		else:
			st["player_contracts"][holder.get_person_key()] = {
				"mastermind_key": holder.get_person_key(), "mastermind_name": holder.npc_name,
				"target_key": target.get_person_key(), "target_name": target.npc_name,
				"desire_id": int(d["id"]), "pay": HITMAN_PAY
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
				VillageChronicle.add(vm, "murder_slip", "%s, ebrio o febril, se fue de la lengua sobre la muerte de %s" % [n.npc_name, str(v_name)], true)

# ==============================================================================
# Diálogos de investigación, pistas falsas, emboscadas y sicarios
# ==============================================================================
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

	# P2.5: Autopsia por veneno lento (con el médico o el comisario si hay víctima envenenada sin autopsia)
	if is_doc or is_law:
		for pv in (st["poisoned"] as Dictionary).keys():
			var p_info: Dictionary = st["poisoned"][pv]
			if not bool(p_info.get("autopsied", false)):
				f_choices.append({"label": "🧪🔬 Solicitar análisis toxicológico del cuerpo de %s" % pv, "next": "END", "action": "forensic_autopsy:" + pv})

	# Opciones sobre el caso abierto
	if not case_dict.is_empty() and v_name != "":
		# P2.1: Desmontar prueba falsa ante el comisario
		if is_law and (st["planted"] as Dictionary).has(v_name) and not bool(st["planted"][v_name].get("debunked", false)):
			var fn: String = str(st["planted"][v_name]["framed_name"])
			f_choices.append({"label": "🔍⚖️ Desmontar la pista falsa plantada contra %s" % ("ti" if fn == "Jugador" else fn), "next": "END", "action": "forensic_debunk:" + v_name})
		# P2.2: Romper coartada falsa hablando con el encubridor o el comisario
		if (st["alibis"] as Dictionary).has(v_name) and not bool(st["alibis"][v_name].get("broken", false)):
			var al: Dictionary = st["alibis"][v_name]
			if npc.npc_name == str(al["ally_name"]) or is_law:
				f_choices.append({"label": "🕵️💥 Desmontar la coartada falsa de %s a favor de %s" % [str(al["ally_name"]), str(al["killer_name"])], "next": "END", "action": "forensic_break_alibi:" + v_name})
		# P2.3: Tranquilizar al testigo intimidado
		if (st["tampered"] as Dictionary).has(v_name) and not bool(st["tampered"][v_name].get("reassured", false)):
			var tm: Dictionary = st["tampered"][v_name]
			if npc.npc_name == str(tm["witness_name"]) or is_law:
				f_choices.append({"label": "🛡️🗣️ Dar garantías al testigo %s para que declare sin miedo" % str(tm["witness_name"]), "next": "END", "action": "forensic_reassure:" + v_name})
		# P2.4: Destapar al autor intelectual (sicario)
		if is_law and (st["hitmen"] as Dictionary).has(v_name) and not bool(st["hitmen"][v_name].get("exposed", false)):
			var hm: Dictionary = st["hitmen"][v_name]
			f_choices.append({"label": "💰🚨 Revelar que %s contrató a %s como sicario (+35 Oro)" % [str(hm["mastermind_name"]), str(hm["hitman_name"])], "next": "END", "action": "forensic_expose_hitman:" + v_name})
		# P2.6: Incriminar a un vecino plantando una pista falsa (en menú turbio con el comisario o con el propio vecino)
		if not is_law and case_dict.get("suspects", {}).has(npc.npc_name):
			ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🧤 Plantar pista falsa contra %s en el caso de %s (-%d Oro)" % [npc.npc_name, v_name, FRAME_COST], "next": "END", "action": "forensic_frame:" + npc.npc_name})
		# P2.7: Seguir el rastro del cadáver arrastrado
		if is_law and (st["moved"] as Dictionary).has(v_name) and not bool(st["moved"][v_name].get("tracked", false)):
			f_choices.append({"label": "👣 Señalar el rastro de arrastre del cadáver hasta la casa de %s" % str(st["moved"][v_name]["killer_name"]), "next": "END", "action": "forensic_track_drag:" + v_name})
		# P2.9: Destapar el chivo expiatorio del comisario corrupto
		if (st["scapegoats"] as Dictionary).has(v_name) and not bool(st["scapegoats"][v_name].get("exposed", false)):
			var sg: Dictionary = st["scapegoats"][v_name]
			if is_law or npc.npc_name == str(sg["scapegoat_name"]):
				f_choices.append({"label": "⚖️🔓 Demostrar la inocencia del chivo expiatorio %s y señalar a %s" % [str(sg["scapegoat_name"]), str(sg["killer_name"])], "next": "END", "action": "forensic_scapegoat:" + v_name})

	# P2.4b: Contrato de sicario ofrecido al jugador por un rico
	if (st["player_contracts"] as Dictionary).has(key):
		var pc: Dictionary = st["player_contracts"][key]
		f_choices.append({"label": "🗡️💰 Escuchar su encargo secreto contra %s (+%d Oro)" % [str(pc["target_name"]), int(pc["pay"])], "next": "END", "action": "forensic_contract_accept:" + key})
	if is_law and not (st["player_contracts"] as Dictionary).is_empty():
		var first_mm: String = str((st["player_contracts"] as Dictionary).keys()[0])
		var pc2: Dictionary = st["player_contracts"][first_mm]
		f_choices.append({"label": "🚨 Denunciar que %s busca un sicario para matar a %s (+30 Oro)" % [str(pc2["mastermind_name"]), str(pc2["target_name"])], "next": "END", "action": "forensic_contract_report:" + first_mm})

	# P2.8: Delatar confesión de borracho o enfermo
	if is_law:
		for sk in (st["slips"] as Dictionary).keys():
			var sl: Dictionary = st["slips"][sk]
			if not bool(sl.get("reported", false)):
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
		clues.append("Prueba falsa desmontada: la prenda de %s fue plantada por %s (+25%% sospecha al asesino real)." % [fn, kn])
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
		if inv != null:
			inv.add_gold(35)
		npc._spawn_floating_text("🚨 «¡Así que pagó a un sicario! Ambos responderán ante la ley.» (+35 Oro)", Color.GOLD, -46.0)

	elif action_id.begins_with("forensic_frame:"):
		if inv == null or int(inv.gold) < FRAME_COST:
			npc._spawn_floating_text("Necesitas %d de oro para preparar la pista falsa" % FRAME_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-FRAME_COST)
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
		clues.append("Rastro forense: el cadáver fue arrastrado de noche desde las inmediaciones de %s (+20%% sospecha)." % kn)
		npc._spawn_floating_text("👣 «El rastro de arrastre lleva directo hacia %s.»" % kn, Color.SPRING_GREEN, -46.0)

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
		VillageChronicle.add(vm, "scapegoat_cleared", "Se demostró que %s era un chivo expiatorio y la sospecha recayó en %s" % [sg_name, kn], true)
		npc._spawn_floating_text("⚖️ «Queda claro que %s era inocente y todo apuntaba a %s.»" % [sg_name, kn], Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("forensic_contract_accept:"):
		if not (st["player_contracts"] as Dictionary).has(arg):
			return
		var pc: Dictionary = st["player_contracts"][arg]
		var pay: int = int(pc["pay"])
		var mm = vm._get_npcs_by_person_key().get(arg, null)
		if mm != null and int(mm.personal_gold) >= pay:
			mm.personal_gold -= pay
		if inv != null:
			inv.add_gold(pay)
		st["player_contracts"].erase(arg)
		npc._spawn_floating_text("🗡️💰 «Aquí tienes %d de oro por adelantado. Que parezca un accidente.»" % pay, Color.GOLD, -46.0)

	elif action_id.begins_with("forensic_contract_report:"):
		if not (st["player_contracts"] as Dictionary).has(arg):
			return
		var pc: Dictionary = st["player_contracts"][arg]
		var mm = vm._get_npcs_by_person_key().get(arg, null)
		if mm != null:
			mm.personal_gold = maxi(0, int(mm.personal_gold) - 40)
			mm.modify_affinity(-40)
		for m in vm.desires:
			if int(m.get("id", -1)) == int(pc.get("desire_id", -2)):
				VillageDesires.finish(vm, m, "foiled")
		st["player_contracts"].erase(arg)
		if inv != null:
			inv.add_gold(30)
		VillageFaith.add_rep(vm, "law", 8)
		VillageChronicle.add(vm, "hitman_foiled", "Denunciaste que %s intentaba contratar un sicario contra %s" % [str(pc["mastermind_name"]), str(pc["target_name"])], true)
		npc._spawn_floating_text("🚨 «Lo multaremos ahora mismo. Toma 30 de oro por avisar.»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("forensic_slip:"):
		if not (st["slips"] as Dictionary).has(arg):
			return
		var sl: Dictionary = st["slips"][arg]
		sl["reported"] = true
		var kn: String = str(sl["killer_name"])
		var vn: String = str(sl["victim_name"])
		if suspects.has(kn):
			suspects[kn]["score"] = int(suspects[kn].get("score", 20)) + 45
		vm._mark_morgue_case_resolved(vn, "Confesión de %s (delatado ante la guardia)" % kn)
		VillageClans.on_murder_resolved(vm, vn, kn)
		if inv != null:
			inv.add_gold(35)
		npc._spawn_floating_text("🍷🚨 «Con esa confesión cerramos el caso de %s contra %s. Toma 35 de oro.»" % [vn, kn], Color.GOLD, -46.0)

	elif action_id.begins_with("forensic_ambush:"):
		var did: int = int(arg)
		for m in vm.desires:
			if int(m.get("id", -1)) == did and bool(m.get("active", false)):
				var by_key: Dictionary = vm._get_npcs_by_person_key()
				var killer = by_key.get(str(m["holder"]), null)
				var target = by_key.get(str(m["target"]), null)
				if killer != null:
					killer.personal_gold = maxi(0, int(killer.personal_gold) - 40)
					killer.modify_affinity(-45)
				if target != null:
					target.modify_affinity(20)
					VillageClans.grant_honor_debt(vm, target, "atrapó en una emboscada nocturna a quien iba a matarle")
				VillageDesires.finish(vm, m, "foiled")
				if inv != null:
					inv.add_gold(AMBUSH_REWARD)
				VillageFaith.add_rep(vm, "law", 10)
				VillageChronicle.add(vm, "murder_ambushed", "Tendiste una emboscada nocturna con la guardia y atrapaste a %s cuando iba a matar a %s" % [str(m["holder_name"]), str(m["target_name"])], true)
				npc._spawn_floating_text("🪤🌙 «¡Lo pillamos con el cuchillo en la mano! Toma %d de oro de recompensa.»" % AMBUSH_REWARD, Color.GOLD, -46.0)
				return
