extends SceneTree

## Comprueba NPCNames: 200/200/200, sin repetidos, sin nombres reservados, unicidad y reproducibilidad con semilla.
const NPCNames = preload("res://scripts/data/NPCNames.gd")
const NPCData = preload("res://scripts/data/NPCData.gd")
const PersonProfile = preload("res://scripts/data/PersonProfile.gd")

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
		assert(prof.romance_status == PersonProfile.ROMANCE_SINGLE and prof.partner_id == "", "En B0.2 deben iniciar single: %s" % r_name)
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
	print("NAMES CHECK PASSED (200 F / 200 M / 200 apellidos + 17 PersonProfile + B0.3 generator)")
	quit(0)
