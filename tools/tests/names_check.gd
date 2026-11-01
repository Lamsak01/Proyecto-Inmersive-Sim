extends SceneTree

## Comprueba NPCNames: 200/200/200, sin repetidos, sin nombres reservados, unicidad y reproducibilidad con semilla.
const NPCNames = preload("res://scripts/data/NPCNames.gd")
const NPCData = preload("res://scripts/data/NPCData.gd")
const PersonProfile = preload("res://scripts/data/PersonProfile.gd")
const SocialDialogueData = preload("res://scripts/data/SocialDialogueData.gd")
const SocialDirector = preload("res://scripts/systems/SocialDirector.gd")

func _norm(s: String) -> String:
	return s.to_lower()

func _initialize() -> void:
	assert(NPCNames.FEMALE_NAMES.size() == 200, "Debe haber 200 nombres femeninos")
	assert(NPCNames.MALE_NAMES.size() == 200, "Debe haber 200 nombres masculinos")
	assert(NPCNames.SURNAMES.size() == 200, "Debe haber 200 apellidos")
	for lst in [NPCNames.FEMALE_NAMES, NPCNames.MALE_NAMES, NPCNames.SURNAMES]:
		var seen: Dictionary = {}
		for n in lst:
			assert(not seen.has(_norm(str(n))), "Repetido: %s" % n)
			seen[_norm(str(n))] = true
			assert(str(n).strip_edges() == str(n) and str(n) != "", "Nombre vacio o con espacios")
	var all_first: Dictionary = {}
	for n in NPCNames.FEMALE_NAMES:
		all_first[_norm(str(n))] = true
	for n in NPCNames.MALE_NAMES:
		assert(not all_first.has(_norm(str(n))), "Nombre en ambos generos: %s" % n)
	for r in ["Thoran", "Kael", "Garrick", "Lina", "Bram", "Mila", "Marlo", "Nora", "Elena", "Tomas", "Marta", "Valen", "Rodric", "Aldric", "Sora", "Dario"]:
		assert(not all_first.has(r.to_lower()), "Reservado en la lista: %s" % r)
	# Unicidad: pedir 200 nombres femeninos seguidos nunca repite, y el 201 usa numeral
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var used: Array = []
	for i in range(200):
		var nm: String = NPCNames.pick_first_name("F", rng, used)
		assert(not (nm in used), "Repetido al elegir: %s" % nm)
		used.append(nm)
	var extra: String = NPCNames.pick_first_name("F", rng, used)
	assert(not (extra in used) and " " in extra, "Con todos usados debe añadir numeral")
	# Reproducibilidad
	var r1 := RandomNumberGenerator.new(); r1.seed = 7
	var r2 := RandomNumberGenerator.new(); r2.seed = 7
	assert(NPCNames.make_person_name("M", r1, []) == NPCNames.make_person_name("M", r2, []), "Misma semilla debe dar el mismo nombre")
	var pn: Dictionary = NPCNames.make_person_name("F", r1, [])
	assert(pn["full"] == "%s %s" % [pn["first"], pn["last"]] and pn["gender"] == "F", "Estructura de make_person_name")
	# B0.2: Comprobar fichas PersonProfile de los 17 residentes
	var residents: Array[String] = [
		"Thoran", "Kael", "Garrick", "Lina", "Bram", "Mila", "Marlo", "Nora",
		"Elena", "Tomás", "Marta", "Dr. Valen", "Comisario Vane", "Guardia Rodric",
		"Aldric", "Sora", "Darío"
	]
	var seen_ids: Dictionary = {}
	var fem_count: int = 0
	var male_count: int = 0
	for r_name in residents:
		assert(NPCData.INITIAL_PERSON_PROFILES.has(r_name), "Falta ficha de: %s" % r_name)
		var prof = PersonProfile.from_dict(NPCData.INITIAL_PERSON_PROFILES[r_name])
		assert(prof.person_id != "" and not seen_ids.has(prof.person_id), "person_id invalido o repetido: %s" % prof.person_id)
		seen_ids[prof.person_id] = true
		assert(prof.gender in ["F", "M"], "Genero invalido en %s" % r_name)
		if prof.gender == "F":
			fem_count += 1
		else:
			male_count += 1
		assert(prof.age >= 18 and prof.age <= 75, "Edad fuera de rango en %s: %d" % [r_name, prof.age])
		assert(prof.get_age_group() in ["young", "adult", "senior"], "Grupo de edad invalido")
		assert(prof.personality.size() == 3, "Personalidad debe tener 3 rasgos en %s" % r_name)
		for tr in prof.personality:
			assert(tr in PersonProfile.PERSONALITY_TRAITS, "Rasgo fuera de catalogo en %s: %s" % [r_name, tr])
			var opp: String = str(PersonProfile.OPPOSITE_TRAITS.get(tr, ""))
			assert(opp == "" or not (opp in prof.personality), "Rasgos opuestos en %s: %s y %s" % [r_name, tr, opp])
		assert(prof.likes.size() >= 1 and prof.dislikes.size() >= 1, "Gustos vacios en %s" % r_name)
		if r_name == "Elena":
			assert(prof.romance_status == PersonProfile.ROMANCE_PARTNERED and prof.partner_id == "valen", "Elena debe iniciar en pareja con Dr. Valen")
		elif r_name == "Dr. Valen":
			assert(prof.romance_status == PersonProfile.ROMANCE_PARTNERED and prof.partner_id == "elena", "Dr. Valen debe iniciar en pareja con Elena")
		else:
			assert(prof.romance_status == PersonProfile.ROMANCE_SINGLE and prof.partner_id == "", "El resto de residentes debe iniciar soltero: %s" % r_name)
	assert(fem_count == 6 and male_count == 11, "Reparto esperado 6 F / 11 M, obtenido %d F / %d M" % [fem_count, male_count])
	# B0.3: Generador de vecinos nuevos (unicidad, equilibrio de genero, edad por oficio, reproducibilidad)
	var gen_rng := RandomNumberGenerator.new()
	gen_rng.seed = 2026
	var used_first: Array = residents.duplicate()
	var used_ids: Dictionary = seen_ids.duplicate()
	var live_f: int = 6
	var live_m: int = 11
	var full_seen: Dictionary = {}
	for i in range(40):
		var role_id: int = i % 11
		var g_res: Dictionary = PersonProfile.generate_newcomer(role_id, i + 1, gen_rng, used_first, used_ids, live_f, live_m)
		var g_prof = g_res["profile"]
		var fn: String = str(g_res["full_name"])
		assert(fn != "" and not full_seen.has(fn), "Nombre completo repetido: %s" % fn)
		full_seen[fn] = true
		assert(g_prof.person_id != "" and not seen_ids.has(g_prof.person_id), "ID choca con residente inicial: %s" % g_prof.person_id)
		var expected_range: Vector2i = PersonProfile.ROLE_GENERATION_HINTS[role_id]["age"]
		assert(g_prof.age >= expected_range.x and g_prof.age <= expected_range.y, "Edad fuera del rango del oficio %d: %d" % [role_id, g_prof.age])
		assert(g_prof.personality.size() == 3 and g_prof.likes.size() == 2 and g_prof.dislikes.size() == 1, "Ficha generada incompleta")
		if g_prof.gender == "F":
			live_f += 1
		else:
			live_m += 1
	assert(abs(live_f - live_m) <= 10, "El generador debe tender a equilibrar el genero: %d F vs %d M" % [live_f, live_m])
	# Reproducibilidad del generador con semilla
	var gr1 := RandomNumberGenerator.new(); gr1.seed = 99
	var gr2 := RandomNumberGenerator.new(); gr2.seed = 99
	var c1: Dictionary = PersonProfile.generate_newcomer(4, 1, gr1, [], {}, 6, 11)
	var c2: Dictionary = PersonProfile.generate_newcomer(4, 1, gr2, [], {}, 6, 11)
	assert(c1["full_name"] == c2["full_name"] and c1["profile"].to_dict() == c2["profile"].to_dict(), "Generador debe ser reproducible con la misma semilla")
	# B1.1: Comprobar catalogo de frases sociales (8 acciones, 16 gustos, sin placeholders residuales)
	assert(SocialDialogueData.ALL_ACTIONS.size() == 10, "Debe haber 10 tipos de acciones sociales (incluidos coqueteo y cariño)")
	for t_key in PersonProfile.TASTE_TOPICS:
		assert(SocialDialogueData.TASTE_LABELS.has(t_key), "Falta etiqueta de gusto para: %s" % t_key)
	var prof_elena: Dictionary = NPCData.INITIAL_PERSON_PROFILES["Elena"]
	var prof_thoran: Dictionary = NPCData.INITIAL_PERSON_PROFILES["Thoran"]
	for act_id in SocialDialogueData.ALL_ACTIONS:
		var ex: Dictionary = SocialDialogueData.build_exchange(act_id, prof_elena, "Elena", prof_thoran, "Thoran", "", gr1)
		var la: String = str(ex.get("line_a", ""))
		var lb: String = str(ex.get("line_b", ""))
		var nt: String = str(ex.get("note", ""))
		assert(la != "" and lb != "" and nt != "", "Intercambio vacio en accion %s" % act_id)
		assert(not ("{a}" in la or "{b}" in la or "{topic}" in la), "Placeholder sin sustituir en line_a (%s): %s" % [act_id, la])
		assert(not ("{a}" in lb or "{b}" in lb or "{topic}" in lb), "Placeholder sin sustituir en line_b (%s): %s" % [act_id, lb])
	# B1.2: Comprobar resolve_live_conversation en SocialDirector y limite max_concurrent_scenes = 3
	var sdir = SocialDirector.new(12345)
	var mock_pairs: Array = [
		[{"npc_name": "Elena", "person_profile": PersonProfile.from_dict(NPCData.INITIAL_PERSON_PROFILES["Elena"])}, {"npc_name": "Thoran", "person_profile": PersonProfile.from_dict(NPCData.INITIAL_PERSON_PROFILES["Thoran"])}],
		[{"npc_name": "Kael", "person_profile": PersonProfile.from_dict(NPCData.INITIAL_PERSON_PROFILES["Kael"])}, {"npc_name": "Mila", "person_profile": PersonProfile.from_dict(NPCData.INITIAL_PERSON_PROFILES["Mila"])}],
		[{"npc_name": "Bram", "person_profile": PersonProfile.from_dict(NPCData.INITIAL_PERSON_PROFILES["Bram"])}, {"npc_name": "Nora", "person_profile": PersonProfile.from_dict(NPCData.INITIAL_PERSON_PROFILES["Nora"])}],
		[{"npc_name": "Garrick", "person_profile": PersonProfile.from_dict(NPCData.INITIAL_PERSON_PROFILES["Garrick"])}, {"npc_name": "Marlo", "person_profile": PersonProfile.from_dict(NPCData.INITIAL_PERSON_PROFILES["Marlo"])}],
	]
	for pi in range(3):
		var conv_ok: Dictionary = sdir.resolve_live_conversation(mock_pairs[pi][0], mock_pairs[pi][1], 5)
		assert(bool(conv_ok.get("allowed", false)), "Las primeras 3 conversaciones deben permitirse")
		assert(str(conv_ok.get("line_a", "")) != "" and str(conv_ok.get("line_b", "")) != "", "Debe devolver line_a y line_b")
	var conv_blocked: Dictionary = sdir.resolve_live_conversation(mock_pairs[3][0], mock_pairs[3][1], 5)
	assert(not bool(conv_blocked.get("allowed", true)), "La 4ta conversacion simultanea debe bloquearse por max_concurrent_scenes=3")
	sdir.tick(4.0)
	var conv_after_tick: Dictionary = sdir.resolve_live_conversation(mock_pairs[3][0], mock_pairs[3][1], 5)
	assert(bool(conv_after_tick.get("allowed", false)), "Tras expirar las escenas de 3.2s, debe permitirse una nueva conversacion")
	# B2.1: Quedadas (pasar tiempo juntos) y rivales que se evitan
	var hd = SocialDirector.new(777)
	hd.set_pair_metrics("kael", "mila", 60, 40, 0, 0)       # amigos
	hd.set_pair_metrics("kael", "nora", 10, 10, 25, 0, SocialDirector.STAGE_FLIRT)  # coqueteo
	hd.set_pair_metrics("kael", "garrick", -40, 10, 0, 45)  # rivales
	hd.set_pair_metrics("kael", "bram", 5, 5, 0, 0)         # neutros
	assert(hd.should_avoid("kael", "garrick"), "Rivales deben evitarse")
	assert(not hd.should_avoid("kael", "mila"), "Amigos no deben evitarse")
	var avoid_ids: Array = hd.get_avoid_ids("kael", ["mila", "garrick", "bram"])
	assert(avoid_ids.size() == 1 and str(avoid_ids[0]) == "garrick", "get_avoid_ids debe devolver solo al rival")
	assert(hd.get_hangout_score("kael", "garrick") == -1 and hd.get_hangout_score("kael", "bram") == -1, "Rival y neutro no son elegibles")
	assert(hd.get_hangout_score("kael", "mila") > 0 and hd.get_hangout_score("kael", "nora") > 0, "Amigo y coqueteo si son elegibles")
	assert(not hd.is_social_hour(10) and hd.is_social_hour(19), "Horas sociales: 12h y 18-21h")
	assert(hd.pick_hangout_partner("kael", ["mila", "nora", "garrick", "bram"], 10, 3) == "", "Fuera de hora social no se queda")
	var cands: Array = ["mila", "nora", "garrick", "bram"]
	for _r in range(40):
		var pk: String = hd.pick_hangout_partner("kael", cands, 19, 3)
		assert(pk == "mila" or pk == "nora", "Solo amigos o con chispa pueden ser elegidos (salio: %s)" % pk)
	var spots: Array = [
		{"id": "tavern", "pos": Vector2(375, -182), "kind": "tavern"},
		{"id": "plaza", "pos": Vector2(412, 54), "kind": "plaza"},
		{"id": "far_bench", "pos": Vector2(5000, 5000), "kind": "bench"},
	]
	var sp_ev: Dictionary = hd.pick_shared_hangout_spot(spots, Vector2(380, -150), Vector2(400, -170), 19)
	assert(str(sp_ev.get("id", "")) == "tavern", "Por la tarde y cerca, debe elegirse la taberna")
	var sp_far: Dictionary = hd.pick_shared_hangout_spot(spots, Vector2(400, 40), Vector2(420, 60), 12)
	assert(str(sp_far.get("id", "")) == "plaza", "A mediodia junto a la plaza debe elegirse la plaza (nunca el banco lejano)")
	var positions: Dictionary = {"kael": Vector2(380, -150), "mila": Vector2(400, -170), "nora": Vector2(390, -160)}
	var hg: Dictionary = hd.try_plan_hangout("kael", ["mila"], positions, spots, 19, 3)
	assert(not hg.is_empty() and str(hg.get("phase", "")) == SocialDirector.HANGOUT_PHASE_TRAVEL, "Debe abrirse una quedada en fase de viaje")
	assert(hd.is_person_in_hangout("kael") and hd.is_person_in_hangout("mila"), "Ambos deben quedar ocupados")
	assert(hd.pick_hangout_partner("nora", ["kael"], 19, 3) == "", "No se puede quedar con alguien ya ocupado")
	assert(hd.start_hangout("kael", "nora", spots[1], 3).is_empty(), "Nadie puede estar en dos quedadas")
	assert(hd.pick_shared_hangout_spot([spots[0]], Vector2.ZERO, Vector2.ZERO, 19).is_empty(), "Un punto ocupado no se reutiliza")
	var aff_before: int = int(hd.get_pair_entry("kael", "mila")["affinity"])
	assert(not hd.mark_hangout_arrival(int(hg["id"]), "kael"), "Con uno solo no estan juntos")
	assert(hd.mark_hangout_arrival(int(hg["id"]), "mila"), "Al llegar ambos pasan a fase juntos")
	hd.tick(50.0)
	var fin: Array = hd.pop_finished_hangouts()
	assert(fin.size() == 1 and bool(fin[0].get("success", false)), "La quedada debe completarse con exito")
	assert(int(hd.get_pair_entry("kael", "mila")["affinity"]) > aff_before, "La quedada sube la afinidad")
	assert(not hd.is_person_in_hangout("kael"), "Al terminar quedan libres")
	assert(hd.pick_hangout_partner("kael", cands, 20, 3) == "", "Cupo de 1 quedada por persona y dia")
	assert(hd.pick_hangout_partner("kael", cands, 19, 4) != "", "Al dia siguiente puede volver a quedar")
	var hg2: Dictionary = hd.start_hangout("kael", "nora", spots[1], 4)
	assert(not hg2.is_empty(), "Segunda quedada (dia 4) debe abrirse")
	hd.tick(61.0)
	var fin2: Array = hd.pop_finished_hangouts()
	assert(fin2.size() == 1 and str(fin2[0].get("reason", "")) == "travel_timeout", "Si no llegan, la quedada caduca sin bono")
	var hd_save: Dictionary = hd.to_save_dict()
	var hd2 = SocialDirector.new(1)
	hd2.from_save_dict(hd_save)
	assert(hd2.get_hangouts_today("kael", 4) == 1 and hd2.active_hangouts.is_empty(), "Guardado: cupo diario persiste, quedadas activas no")
	# B3.1: Etapas de cortejo en vivo
	var rd = SocialDirector.new(4242)
	rd.dials["live_stage_advance_chance"] = 10.0  # garantiza el avance si se cumplen las condiciones
	var rprofs: Dictionary = {}
	for nm in NPCData.INITIAL_PERSON_PROFILES.keys():
		var pp = PersonProfile.from_dict(NPCData.INITIAL_PERSON_PROFILES[nm])
		pp.romance_status = PersonProfile.ROMANCE_SINGLE
		pp.partner_id = ""
		rprofs[str(pp.person_id)] = pp
	var best_pair: Array = []
	var best_c: int = -1
	var pids: Array = rprofs.keys()
	pids.sort()
	for i in range(pids.size()):
		for j in range(i + 1, pids.size()):
			var cc: int = rd.compute_compatibility(rprofs[pids[i]], rprofs[pids[j]], false)
			if cc > best_c:
				best_c = cc
				best_pair = [pids[i], pids[j]]
	assert(best_c >= 40, "Debe existir al menos un par compatible")
	var ra: String = best_pair[0]
	var rb: String = best_pair[1]
	rd.set_pair_metrics(ra, rb, 40, 40, 30, 0, SocialDirector.STAGE_INTEREST)
	rd.get_pair_entry(ra, rb)["last_contact_day"] = 9
	var rs1: Dictionary = rd.advance_live_romance_day(10, rprofs)
	assert(rd.get_pair_stage(ra, rb) == SocialDirector.STAGE_FLIRT and rs1["advanced"].size() == 1, "Con chispa 30 y contacto ayer: Interés -> Coqueteo")
	var rs2: Dictionary = rd.advance_live_romance_day(10, rprofs)
	assert(rd.get_pair_stage(ra, rb) == SocialDirector.STAGE_FLIRT and rs2["advanced"].is_empty(), "Sin chispa suficiente (30 < 44) no pasa a Citas")
	rd.get_pair_entry(ra, rb)["last_contact_day"] = 3
	rd.get_pair_entry(ra, rb)["spark"] = 70
	rd.advance_live_romance_day(10, rprofs)
	assert(rd.get_pair_stage(ra, rb) == SocialDirector.STAGE_FLIRT, "Sin contacto reciente no avanza aunque haya chispa")
	rd.get_pair_entry(ra, rb)["last_contact_day"] = 10
	rd.advance_live_romance_day(10, rprofs)
	assert(rd.get_pair_stage(ra, rb) == SocialDirector.STAGE_DATING, "Coqueteo -> Citas")
	assert(rd.get_courtship_of(ra).get("other_id", "") == rb, "get_courtship_of debe devolver al otro")
	var rs3: Dictionary = rd.advance_live_romance_day(10, rprofs)
	assert(rd.get_pair_stage(ra, rb) == SocialDirector.STAGE_COUPLE and rs3["new_couples"].size() == 1, "Citas -> Pareja")
	assert(str(rprofs[ra].romance_status) == PersonProfile.ROMANCE_PARTNERED and str(rprofs[ra].partner_id) == rb and str(rprofs[rb].partner_id) == ra, "Pareja: fichas cruzadas")
	assert(int(rd.get_pair_entry(ra, rb)["affinity"]) >= 68, "Pareja: afinidad minima 68")
	# Fizzle: el cortejo se apaga si la chispa cae
	var fz_ids: Array = []
	for pid2 in pids:
		if pid2 != ra and pid2 != rb:
			fz_ids.append(pid2)
	rd.set_pair_metrics(str(fz_ids[0]), str(fz_ids[1]), 20, 20, 3, 0, SocialDirector.STAGE_FLIRT)
	var rs4: Dictionary = rd.advance_live_romance_day(11, rprofs)
	assert(rs4["fizzled"].size() == 1, "Con chispa < 8, el coqueteo se apaga")
	# Tope diario de chispa
	var cap_pe: Dictionary = rd.get_pair_entry("x1", "x2")
	rd._add_spark_capped(cap_pe, 8, 5)
	rd._add_spark_capped(cap_pe, 8, 5)
	assert(int(cap_pe["spark"]) == 10, "Tope diario de chispa = 10")
	rd._add_spark_capped(cap_pe, 8, 6)
	assert(int(cap_pe["spark"]) == 18, "Al dia siguiente vuelve a ganar chispa")
	# B3.2: Comportamiento por etapa (coqueteo en etapa flirt/dating y cariño en pareja)
	var bd = SocialDirector.new(8888)
	var mock_kael: Dictionary = {"npc_name": "Kael", "person_profile": PersonProfile.from_dict(NPCData.INITIAL_PERSON_PROFILES["Kael"])}
	var mock_nora: Dictionary = {"npc_name": "Nora", "person_profile": PersonProfile.from_dict(NPCData.INITIAL_PERSON_PROFILES["Nora"])}
	bd.set_pair_metrics("kael", "nora", 35, 30, 36, 0, SocialDirector.STAGE_FLIRT)
	var saw_flirt: bool = false
	for _it in range(12):
		bd.active_scenes.clear()
		var ex_f: Dictionary = bd.resolve_live_conversation(mock_kael, mock_nora, 6)
		if str(ex_f.get("action_id", "")) == SocialDialogueData.ACTION_FLIRT:
			saw_flirt = true
			break
	assert(saw_flirt, "B3.2: Una pareja en etapa de coqueteo debe usar frases de ACTION_FLIRT")
	mock_kael["person_profile"].romance_status = PersonProfile.ROMANCE_PARTNERED
	mock_kael["person_profile"].partner_id = "nora"
	mock_nora["person_profile"].romance_status = PersonProfile.ROMANCE_PARTNERED
	mock_nora["person_profile"].partner_id = "kael"
	bd.set_pair_metrics("kael", "nora", 72, 65, 80, 0, SocialDirector.STAGE_COUPLE)
	var saw_affection: bool = false
	for _it2 in range(12):
		bd.active_scenes.clear()
		var ex_c: Dictionary = bd.resolve_live_conversation(mock_kael, mock_nora, 6)
		if str(ex_c.get("action_id", "")) == SocialDialogueData.ACTION_AFFECTION:
			saw_affection = true
			break
	assert(saw_affection, "B3.2: Una pareja establecida debe usar frases de ACTION_AFFECTION")
	print("NAMES CHECK PASSED (200 F / 200 M / 200 apellidos + 17 PersonProfile + B0.3 generator + B1.1/B1.2 social + B2.1 hangouts + B3.1/B3.2 romance)")
	quit(0)
