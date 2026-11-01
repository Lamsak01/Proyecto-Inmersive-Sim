extends SceneTree

## B0.9: Simulador headless de N días con semilla para calibrar los diales del Director Social.
## Metas para 60 días (sección 8 de HANDOFF.md):
## - 1–3 parejas nuevas (de media / rango esperado)
## - 2–6 peleas (ningún par pelea > 2 veces)
## - Ningún vecino sin amigos (al menos 1 relación >= 20)
## - Más de la mitad (> 50%) de todas las relaciones entre -20 y +40

const NPCData = preload("res://scripts/data/NPCData.gd")
const PersonProfile = preload("res://scripts/data/PersonProfile.gd")
const SocialDirector = preload("res://scripts/systems/SocialDirector.gd")

const RESIDENT_FAMILIES: Dictionary = {
	"Thoran": "family_smith", "Kael": "family_smith",
	"Garrick": "family_butcher", "Lina": "family_butcher",
	"Bram": "family_carpenter", "Mila": "family_carpenter",
	"Marlo": "family_fishmonger", "Nora": "family_fishmonger",
	"Elena": "family_herbalist", "Tomás": "family_herbalist",
	"Marta": "family_tavern",
	"Dr. Valen": "family_hospital",
	"Comisario Vane": "family_police", "Guardia Rodric": "family_police",
	"Aldric": "none", "Sora": "none", "Darío": "none",
}

func _run_simulation(seed_val: int, days: int = 60, replace_two_with_newcomers: bool = false) -> Dictionary:
	var sdir = SocialDirector.new(seed_val)
	var profiles: Dictionary = {}
	var families: Dictionary = {}
	var name_to_id: Dictionary = {}

	for r_name in RESIDENT_FAMILIES.keys():
		var prof = PersonProfile.from_dict(NPCData.INITIAL_PERSON_PROFILES[r_name])
		profiles[prof.person_id] = prof
		families[prof.person_id] = RESIDENT_FAMILIES[r_name]
		name_to_id[r_name] = prof.person_id

	if replace_two_with_newcomers:
		# Probar que el sistema funciona igual si faltan 2 residentes fijos y entran 2 generados por B0.3
		profiles.erase("aldric")
		families.erase("aldric")
		profiles.erase("sora")
		families.erase("sora")
		var gen_rng := RandomNumberGenerator.new()
		gen_rng.seed = seed_val + 77
		var used_f: Array = RESIDENT_FAMILIES.keys()
		var used_ids: Dictionary = profiles.duplicate()
		for i in range(2):
			var g_new: Dictionary = PersonProfile.generate_newcomer(0, i + 1, gen_rng, used_f, used_ids, 5, 10)
			var p_new = g_new["profile"]
			profiles[p_new.person_id] = p_new
			families[p_new.person_id] = "none"

	var ids: Array = profiles.keys()
	ids.sort()
	# Inicializar matriz de relaciones como hace ensure_npc_relationships_initialized
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var id_a: String = str(ids[i])
			var id_b: String = str(ids[j])
			var fam_a: String = str(families.get(id_a, "none"))
			var fam_b: String = str(families.get(id_b, "none"))
			var same_fam: bool = (fam_a != "none" and fam_a != "" and fam_a != "family_police" and fam_a == fam_b)
			var base_rel: int = 0
			if same_fam:
				base_rel = 85
			else:
				# Buscar en INITIAL_NPC_RELATIONS si ambos son residentes originales
				var found_lore: bool = false
				for rel_k in NPCData.INITIAL_NPC_RELATIONS.keys():
					var parts: PackedStringArray = str(rel_k).split("|")
					if parts.size() == 2:
						var lid_1: String = str(name_to_id.get(parts[0], ""))
						var lid_2: String = str(name_to_id.get(parts[1], ""))
						if (lid_1 == id_a and lid_2 == id_b) or (lid_1 == id_b and lid_2 == id_a):
							base_rel = int(NPCData.INITIAL_NPC_RELATIONS[rel_k][0])
							found_lore = true
							break
				if not found_lore:
					var pair_hash: int = abs((id_a + "_" + id_b).hash())
					base_rel = (pair_hash % 45) - 18
					if id_a == "marta" or id_b == "marta":
						base_rel = maxi(base_rel, 18)
			var pe: Dictionary = sdir.get_pair_entry(id_a, id_b, base_rel)
			if (id_a == "elena" and id_b == "valen") or (id_a == "valen" and id_b == "elena"):
				sdir.set_pair_metrics(id_a, id_b, 78, 75, 80, 5, SocialDirector.STAGE_COUPLE)
			elif base_rel <= -30:
				# Rivales de lore empiezan con algo de tensión acumulada
				pe["tension"] = clampi(-base_rel - 4, 0, 100)
			elif base_rel >= 40 and not same_fam:
				pe["familiarity"] = clampi(base_rel / 2 + 8, 0, 100)

	var total_new_couples: int = 0
	var total_fights: int = 0
	for d in range(1, days + 1):
		var step_res: Dictionary = sdir.simulate_social_day(d, profiles, families)
		total_new_couples += (step_res["new_couples"] as Array).size()
		total_fights += (step_res["fights"] as Array).size()

	var max_pair_fights: int = 0
	var total_pairs: int = 0
	var mid_range_pairs: int = 0
	var friends_count_by_id: Dictionary = {}
	for pid in ids:
		friends_count_by_id[pid] = 0

	for k in sdir.pair_metrics.keys():
		var pe: Dictionary = sdir.pair_metrics[k]
		total_pairs += 1
		var aff: int = int(pe["affinity"])
		if aff >= -20 and aff <= 40:
			mid_range_pairs += 1
		var fc: int = int(pe.get("fights_count", 0))
		if fc > max_pair_fights:
			max_pair_fights = fc
		if aff >= 20:
			var p_ids: PackedStringArray = str(k).split("|")
			if p_ids.size() == 2:
				friends_count_by_id[p_ids[0]] = int(friends_count_by_id.get(p_ids[0], 0)) + 1
				friends_count_by_id[p_ids[1]] = int(friends_count_by_id.get(p_ids[1], 0)) + 1

	var isolated_count: int = 0
	for pid in ids:
		if int(friends_count_by_id.get(pid, 0)) == 0:
			isolated_count += 1

	var mid_ratio: float = float(mid_range_pairs) / float(maxi(1, total_pairs))
	return {
		"seed": seed_val,
		"new_couples": total_new_couples,
		"fights": total_fights,
		"max_pair_fights": max_pair_fights,
		"isolated_count": isolated_count,
		"mid_ratio": mid_ratio,
	}

func _initialize() -> void:
	var seeds: Array[int] = [101, 202, 303, 404, 505]
	for s in seeds:
		var m: Dictionary = _run_simulation(s, 60, false)
		print("SIM 60d [seed=%d]: new_couples=%d fights=%d max_pair_fights=%d isolated=%d mid_ratio=%.2f" % [
			s, int(m["new_couples"]), int(m["fights"]), int(m["max_pair_fights"]), int(m["isolated_count"]), float(m["mid_ratio"])
		])
		assert(int(m["new_couples"]) >= 1 and int(m["new_couples"]) <= 3, "Meta 60d: 1..3 parejas nuevas (obtenido %d en seed %d)" % [int(m["new_couples"]), s])
		assert(int(m["fights"]) >= 2 and int(m["fights"]) <= 6, "Meta 60d: 2..6 peleas (obtenido %d en seed %d)" % [int(m["fights"]), s])
		assert(int(m["max_pair_fights"]) <= 2, "Meta 60d: ningun par pelea > 2 veces (obtenido %d)" % int(m["max_pair_fights"]))
		assert(int(m["isolated_count"]) == 0, "Meta 60d: ningun vecino sin amigos (aislados=%d)" % int(m["isolated_count"]))
		assert(float(m["mid_ratio"]) > 0.50, "Meta 60d: >50%% relaciones entre -20 y +40 (obtenido %.2f)" % float(m["mid_ratio"]))

	# Reproducibilidad exacta con semilla y funcionamiento con vecinos generados (B0.3)
	var r_a: Dictionary = _run_simulation(777, 60, true)
	var r_b: Dictionary = _run_simulation(777, 60, true)
	assert(r_a == r_b, "La simulacion debe ser 100%% reproducible con la misma semilla")
	assert(int(r_a["isolated_count"]) == 0 and int(r_a["max_pair_fights"]) <= 2 and float(r_a["mid_ratio"]) > 0.50, "Simulacion con vecinos nuevos debe mantener invariantes")
	print("SOCIAL SIM CHECK PASSED (60d metas verificadas en 5 semillas + reemplazos procedurales)")
	quit(0)
