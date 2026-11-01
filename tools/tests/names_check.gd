extends SceneTree

## Comprueba NPCNames: 200/200/200, sin repetidos, sin nombres reservados, unicidad y reproducibilidad con semilla.
const NPCNames = preload("res://scripts/data/NPCNames.gd")

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
	print("NAMES CHECK PASSED (200 F / 200 M / 200 apellidos)")
	quit(0)
