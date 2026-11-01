extends SceneTree

const SkillCatalog = preload("res://scripts/systems/SkillCatalog.gd")

func _initialize() -> void:
	var packed: PackedScene = load("uid://dsoiuct8kdsk3")
	var main_inst: Node = packed.instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame

	var vm = root.find_child("VillageManager", true, false)
	var player: Node2D = get_first_node_in_group("player") as Node2D
	assert(vm != null, "VillageManager must exist")
	assert(player != null, "Player must exist")

	# 1. Test RimWorld HealthComponent (Independent Blood Loss, Symbolic Effective Max Health, Makeshift Tending)
	var hc_script = load("res://scripts/systems/combat/HealthComponent.gd")
	var dmg_script = load("res://scripts/systems/combat/DamageData.gd")
	var hc = hc_script.new()
	root.add_child(hc)
	var cut_dmg = dmg_script.new()
	cut_dmg.amount = 8.0
	cut_dmg.type = 0 # CombatConstants.DamageType.CUT
	cut_dmg.bleed_buildup = 0.0
	hc.take_damage(cut_dmg)
	assert(hc.is_bleeding, "Laceration should bleed")
	var hp_after_wound: float = hc.current_health
	var blood_before_tick: float = hc.current_blood
	hc._process(10.0) # 10 seconds of bleeding
	assert(is_equal_approx(hc.current_health, hp_after_wound), "Bleeding must NOT drain HP directly per second!")
	assert(hc.current_blood > blood_before_tick + 3.5 and hc.current_blood < blood_before_tick + 6.0, "Blood loss should accumulate realistically (~4.2% in 10s), got: " + str(hc.current_blood))
	assert(hc.get_bleedout_eta_seconds() > 150.0, "Bleedout ETA should be permissive (>150s for 1 cut)")

	# Symbolic max health reduction from sickness
	hc.fever = 50.0
	var eff_max: float = hc.get_effective_max_health()
	assert(eff_max < hc.max_health and eff_max >= hc.max_health * 0.5, "Sickness should symbolically reduce effective max health: " + str(eff_max))

	# Free makeshift tending ("tend_makeshift")
	var urg_w_id: int = hc.get_most_urgent_untreated_wound_id(true)
	assert(urg_w_id >= 0, "Must find untreated bleeding wound")
	var tended: bool = hc.treat_wound(urg_w_id, "tend_makeshift")
	assert(tended and not hc.is_bleeding, "Makeshift tending must stop bleeding immediately")
	assert(hc.has_fresh_combat_wounds_or_makeshift(), "Makeshift bandage must be detectable by investigators")

	# 2. Test Blood Puddle & Directional Footprints
	var test_puddle_pos := Vector2(465, 60)
	vm.spawn_blood_puddle(test_puddle_pos, "Víctima Test")
	player.global_position = test_puddle_pos
	vm.update_entity_blood_footprints(player, 0.1)
	assert(int(player.get_meta("bloody_steps_left", 0)) == 6, "Stepping on blood puddle must set 6 bloody steps")
	for step_i in range(1, 7):
		player.global_position = test_puddle_pos + Vector2(-18.0 * step_i, 0.0) # Fleeing West
		vm.update_entity_blood_footprints(player, 0.1)
	assert(int(player.get_meta("bloody_steps_left", 0)) == 0, "All 6 bloody footprints should be placed after walking ~108 px")
	var puddle_clue: Dictionary = vm.get_blood_puddle_clue_near(test_puddle_pos)
	assert("Oeste" in str(puddle_clue.get("flee_compass", "")), "Footprints should record Westward flee direction, got: " + str(puddle_clue.get("flee_compass", "")))

	# 3. Test Inquisitor Alistair's Own Bed & Witness-Chain Investigation
	vm._spawn_royal_investigator()
	assert(vm._royal_investigator_npc != null, "Royal Investigator should spawn")
	assert(vm._royal_investigator_npc.bed_position == Vector2(400, -252), "Alistair must sleep in his own Inn bed Vector2(400, -252), not Sheriff Vane's bed!")

	# 4. Test Sequential Doctor Wound-by-Wound Treatment
	var doc_npc = null
	for n in get_nodes_in_group("village_npcs"):
		if int(n.get("trade_role")) == 8: # TradeRole.DOCTOR
			doc_npc = n
			break
	assert(doc_npc != null, "Dr. Valen must exist")
	var p_hc = player.get_node_or_null("HealthComponent")
	p_hc.take_damage(cut_dmg)
	p_hc.take_damage(cut_dmg)
	var open_before: int = 0
	for w in p_hc.wounds:
		if float(w.get("bleed_rate", 0.0)) > 0.0:
			open_before += 1
	assert(open_before >= 2, "Player should have at least 2 bleeding wounds")
	doc_npc._doctor_apply_single_step_treatment(player, p_hc, "Forastero")
	var open_after_one_step: int = 0
	for w in p_hc.wounds:
		if float(w.get("bleed_rate", 0.0)) > 0.0:
			open_after_one_step += 1
	assert(open_after_one_step == open_before - 1, "Doctor must treat exactly ONE wound per step, not all at once!")

	# 5. Test Sheriff Witness-Chain Investigation (Starts with Reporter, not Player)
	var smith = vm._find_npc_by_name("Thoran")
	var carpenter = vm._find_npc_by_name("Bram")
	if smith and carpenter:
		player.global_position = Vector2(-500, -500) # Player far away, unseen by anyone
		vm.start_sheriff_investigation(smith, test_puddle_pos, "Cuchillo", carpenter.npc_name)
		var q: Array = vm.active_sheriff_investigation.get("interview_queue", [])
		assert(q.size() == 1 and str(q[0]) == carpenter.npc_name, "Sheriff must start interview queue with corpse reporter (Bram), not Player! Queue: " + str(q))

	# 6. Test Merchant Murder: Inquisitor does NOT arrive on death, ONLY when corpse is reported!
	if is_instance_valid(vm._royal_investigator_npc):
		vm._free_transient_npc(vm._royal_investigator_npc)
		vm._royal_investigator_npc = null
	vm.active_royal_investigation.clear()
	vm.merchant_suspension_days["casimir"] = 0
	vm._check_weekly_merchant_arrival(3, true, true)
	var casimir = vm._active_traveling_merchant
	assert(casimir != null and not casimir.is_dead, "Maese Casimir should be spawned")
	casimir.global_position = Vector2(-750, -180) # Remote spot away from witnesses
	casimir.last_hit_by_player = true
	casimir.last_hit_weapon_name = "Corte de Espada"
	casimir._confirm_true_death()
	assert(casimir.is_dead and casimir.corpse_on_ground and not casimir.corpse_reported, "Casimir is dead on ground and unreported")
	assert(vm.active_royal_investigation.is_empty() and vm._royal_investigator_npc == null, "Inquisitor must NOT arrive the instant the merchant dies before the corpse is reported!")

	# Now report the corpse -> Inquisitor MUST be summoned!
	casimir.report_corpse_by_player(player)
	assert(casimir.corpse_reported, "Corpse should be marked reported")
	assert(bool(vm.active_royal_investigation.get("active", false)) and vm._royal_investigator_npc != null, "Inquisitor MUST arrive once the merchant's corpse is reported!")

	# 7. Test Morgue Corpse Looting & Persistence Until Case Resolved/Archived
	var pre_gold: int = casimir.personal_gold
	assert(pre_gold > 0 and casimir.carries_royal_safe_conduct, "Casimir should still have his gold and Royal Safe Conduct")
	vm.register_npc_death_and_corpse(casimir, casimir.death_world_pos, casimir.last_hit_weapon_name, true, "Jugador", 0.5)
	assert(casimir.corpse_in_morgue and not casimir.corpse_buried, "Casimir should be in the Morgue and not buried")
	assert(casimir.global_position == vm._morgue_table_positions[0], "Casimir should be placed physically on Morgue Table #1")

	# Simulate 48 hours passing while investigation is still active -> Corpse MUST remain in Morgue!
	for d_pass in range(2, 5):
		vm._on_day_passed(d_pass)
		vm._on_hour_passed(d_pass, 12)
	assert(vm.morgue_active_corpses.size() == 1 and not casimir.corpse_buried, "Corpse must stay in Morgue while case is still open!")

	# Loot the corpse in the Morgue!
	var p_inv = player.get("inventory")
	var p_gold_before: int = p_inv.gold
	var looted_ok: bool = casimir.loot_npc_pockets(player)
	assert(looted_ok and p_inv.gold == p_gold_before + pre_gold and p_inv.has_item("royal_safe_conduct", 1), "Player must be able to loot gold and Royal Safe Conduct from corpse in Morgue!")

	# Now resolve/archive the case -> Corpse can be buried after 18h!
	vm._mark_morgue_case_resolved(casimir.npc_name, "Caso Archivado")
	vm.active_royal_investigation["stage"] = "DEPARTING"
	vm.active_royal_investigation["active"] = false
	vm._on_day_passed(7)
	assert(vm.morgue_active_corpses.is_empty() and casimir.corpse_buried and vm.buried_graves.size() >= 1, "Once the case is resolved/archived, the corpse should be buried in the Cemetery on subsequent day pass!")

	# 8. Test Village Wells (Behind Tavern & Plaza), Water Containers (`empty_flask` / `clean_water`), and <=2m Proximity Rule
	assert(vm._well_positions.size() >= 3, "Must have Farm Well, Tavern Well, and Plaza Well")
	assert(p_inv.has_item("clean_water", 1) and p_inv.has_item("empty_flask", 1), "Player starts with 1 clean_water and 1 empty_flask")

	# Inflict a wound on the player and test washing within <=2m of the Tavern Well (free, no water consumed)
	var p_hc_w = player.get_node_or_null("HealthComponent")
	p_hc_w.wounds.clear()
	p_hc_w.take_damage(cut_dmg)
	assert(not p_hc_w.wounds.is_empty(), "Player must have a wound")
	var pw_id: int = int(p_hc_w.wounds[0]["id"])
	assert(not bool(p_hc_w.wounds[0].get("clean", false)), "Fresh wound starts uncleaned")

	# Move player within 1.5m (24 px) of the Tavern Back Well (`Vector2(440, -306)`)
	player.global_position = vm._tavern_well_pos + Vector2(0, 20)
	assert(player.is_near_water_source(2.0), "Player at 20px (~1.25m) from Tavern Well must be detected as <=2m from water source")
	var water_before: int = p_inv.get_count("clean_water")
	var med_ui = root.find_child("MedicalPanel", true, false)
	if med_ui == null:
		var med_script = load("res://scripts/ui/MedicalPanelUI.gd")
		med_ui = med_script.new()
		root.add_child(med_ui)
	med_ui.open_panel(player)
	med_ui._apply_treatment(p_hc_w, pw_id, "wash")
	assert(bool(p_hc_w.wounds[0].get("clean", false)), "Wound must be clean after washing near Tavern Well")
	assert(p_inv.get_count("clean_water") == water_before, "Washing within <=2m of a water source must NOT consume inventory clean_water!")

	# Now move player far from any water source (`Vector2(100, -250)`) and dirty the wound again
	player.global_position = Vector2(100, -250)
	assert(not player.is_near_water_source(2.0), "Player at (100, -250) must be >2m from any water source")
	p_hc_w.wounds[0]["clean"] = false
	var empty_before: int = p_inv.get_count("empty_flask")
	med_ui._apply_treatment(p_hc_w, pw_id, "wash")
	assert(bool(p_hc_w.wounds[0].get("clean", false)), "Wound must be washed using inventory clean_water")
	assert(p_inv.get_count("clean_water") == water_before - 1, "Washing >2m from water must consume 1 clean_water")
	assert(p_inv.get_count("empty_flask") == empty_before + 1, "Consuming 1 clean_water must return 1 empty_flask to inventory!")

	# With 0 clean_water left and >2m from water, washing must fail until refilled
	p_hc_w.wounds[0]["clean"] = false
	med_ui._apply_treatment(p_hc_w, pw_id, "wash")
	assert(not bool(p_hc_w.wounds[0].get("clean", false)), "Cannot wash wound without clean_water when >2m from water source")

	# Refill empty_flasks at the Plaza Well (`_plaza_well_pos`)
	player.global_position = vm._plaza_well_pos
	vm._use_water_well(player)
	assert(p_inv.get_count("empty_flask") == 0 and p_inv.get_count("clean_water") >= 2, "Interacting with Plaza Well must fill all empty_flasks into clean_water!")

	# 9. Test 3-Phase Physical Corpse Discovery & Reporting Pipeline (10s Pulse Check -> Walk to Police -> 12.5s Explanation)
	var victim_npc = vm._find_npc_by_name("Aldric")
	var witness_npc = vm._find_npc_by_name("Sora")
	var sheriff_npc = null
	for n in get_nodes_in_group("village_npcs"):
		if int(n.get("trade_role")) == 9: # TradeRole.SHERIFF
			sheriff_npc = n
			break
	assert(victim_npc != null and witness_npc != null and sheriff_npc != null, "Aldric, Sora, and Sheriff Vane must exist")
	vm.wanted_level = 0
	vm.bounty_gold = 0
	vm.active_sheriff_investigation.clear()
	victim_npc.global_position = Vector2(445, 44)
	witness_npc.global_position = Vector2(455, 44) # 10px from body
	sheriff_npc.global_position = Vector2(520, 44) # 65px away in Plaza
	# Determinismo: apartar a cualquier otro NPC (p.ej. guardias en patrulla) del testigo/cuerpo para que Vane sea la única autoridad cercana
	for n_far in get_nodes_in_group("village_npcs"):
		if n_far != victim_npc and n_far != witness_npc and n_far != sheriff_npc and n_far.global_position.distance_to(witness_npc.global_position) < 140.0:
			n_far.global_position = Vector2(950, 160)
	victim_npc.last_hit_by_player = false
	victim_npc.last_hit_weapon_name = "Cuchillo"
	victim_npc._confirm_true_death()
	victim_npc.begin_physical_corpse_discovery(witness_npc)
	assert(witness_npc._corpse_report_phase == 1 and not victim_npc.corpse_reported, "Witness must start in Phase 1 (checking pulse) and corpse must NOT be reported yet!")

	# Simulate 5 seconds of Phase 1 -> still checking pulse, not reported!
	for i in range(50):
		witness_npc._process_witness_corpse_reporting(0.1)
	assert(witness_npc._corpse_report_phase == 1 and not victim_npc.corpse_reported, "At 5.0s witness must still be in Phase 1 checking pulse!")

	# Complete the remaining 5.2 seconds of Phase 1 -> transitions to Phase 2 (walking personally to police)
	for i in range(55):
		witness_npc._process_witness_corpse_reporting(0.1)
	assert(witness_npc._corpse_report_phase == 2 and not victim_npc.corpse_reported, "After 10s checking pulse, witness must transition to Phase 2 (walking to police) and corpse is STILL not reported!")

	# Place witness next to Sheriff Vane to enter Phase 3 (12.5s explaining what happened)
	witness_npc.global_position = sheriff_npc.global_position + Vector2(-16, 0)
	witness_npc._process_witness_corpse_reporting(0.1)
	assert(witness_npc._corpse_report_phase == 3 and not victim_npc.corpse_reported, "Upon reaching police, witness enters Phase 3 (explaining what happened) and corpse is STILL not reported!")

	# Simulate 6 seconds of explanation -> still explaining!
	for i in range(60):
		witness_npc._process_witness_corpse_reporting(0.1)
	assert(witness_npc._corpse_report_phase == 3 and not victim_npc.corpse_reported, "At 6.0s of Phase 3, witness is still explaining to police!")

	# Complete the remaining 7 seconds of Phase 3 -> NOW corpse_reported becomes true and Sheriff starts investigation!
	for i in range(70):
		witness_npc._process_witness_corpse_reporting(0.1)
	assert(victim_npc.corpse_reported and witness_npc._corpse_report_phase == 0, "After 12.5s of explaining to police, corpse_reported becomes true!")
	assert(bool(vm.active_sheriff_investigation.get("active", false)), "Sheriff investigation starts only after the witness finishes explaining!")

	# 10. Test Witness Manipulation (Bribe / Alibi / Frame Another Villager) & House Chest Evidence Planting
	p_inv.add_gold(100)
	witness_npc.affinity = 45
	witness_npc.on_dialogue_action("witness_convince_alibi")
	assert(witness_npc.witness_silenced_player and witness_npc.witness_alibi_for_player, "Convincing witness by affinity must set witness_silenced_player and witness_alibi_for_player!")

	witness_npc.on_dialogue_action("witness_frame_npc:Bram")
	assert(witness_npc.witness_framed_target_name == "Bram", "Framing Bram via rumor must set witness_framed_target_name == 'Bram'")

	# Plant Royal Safe Conduct inside a House Chest and verify `_evaluate_npc_interview` detects it
	assert(not vm.house_chests.is_empty(), "House chests must exist")
	var test_chest: Dictionary = vm.house_chests[0]
	var chest_fam: String = str(test_chest.get("family_id", ""))
	var wc = root.get_node_or_null("WorldClock")
	test_chest["looted_day"] = wc.current_day if wc else 1
	if not p_inv.has_item("royal_safe_conduct", 1):
		p_inv.add_item("royal_safe_conduct", 1)
	vm._interact_house_chest(player, test_chest)
	assert(str(test_chest.get("planted_evidence", "")) == "royal_safe_conduct", "Interacting with an open house chest while carrying royal_safe_conduct must plant the evidence in the chest!")

	var chest_owner_npc = null
	for n in get_nodes_in_group("village_npcs"):
		if not bool(n.get("is_dead")) and str(n.get("family_id")) == chest_fam:
			chest_owner_npc = n
			break
	if chest_owner_npc != null:
		vm._evaluate_npc_interview(sheriff_npc, chest_owner_npc, vm.active_sheriff_investigation["suspects"], vm.active_sheriff_investigation["clues_log"], vm.active_sheriff_investigation)
		var owner_score: int = int(vm.active_sheriff_investigation["suspects"][chest_owner_npc.npc_name].get("score", 0))
		assert(owner_score >= 92 and str(vm.active_sheriff_investigation.get("stage", "")) == "VERDICT", "Planting Royal Safe Conduct in a family's house chest must raise their suspicion >= 92% and trigger VERDICT!")

	# 11. Test Multiple-Corpse Discovery & Reporting Bug Fix (2 corpses in same spot with Lyra nearby)
	var living_civs: Array = []
	for n in get_nodes_in_group("village_npcs"):
		if not bool(n.get("is_dead")) and not (int(n.get("trade_role")) in [8, 9, 10, 11, 12]):
			living_civs.append(n)
	assert(living_civs.size() >= 3, "At least 3 living civilians must exist for multi-corpse test")
	var corpse_a = living_civs[0]
	var corpse_b = living_civs[1]
	var lyra_npc = living_civs[2]
	lyra_npc.witness_silenced_player = false
	lyra_npc._reporting_corpse_target = null
	lyra_npc._corpse_report_phase = 0
	lyra_npc._corpse_report_timer = 0.0
	corpse_a.global_position = Vector2(390, 44)
	corpse_b.global_position = Vector2(398, 44)
	lyra_npc.global_position = Vector2(394, 44)
	corpse_a._confirm_true_death()
	corpse_b._confirm_true_death()
	# Simulate both corpses scanning every frame while Lyra is examining one of them!
	var prev_timer: float = -1.0
	for step_i in range(105):
		corpse_a._process_corpse_state(0.1)
		corpse_b._process_corpse_state(0.1)
		lyra_npc._process_witness_corpse_reporting(0.1)
		if lyra_npc._corpse_report_phase == 1:
			assert(lyra_npc._corpse_report_timer >= prev_timer, "Two nearby corpses must NEVER reset witness _corpse_report_timer!")
			prev_timer = lyra_npc._corpse_report_timer
	assert(lyra_npc._corpse_report_phase == 2, "Witness near 2 corpses must finish the 10s pulse check cleanly and enter Phase 2!")
	lyra_npc.global_position = sheriff_npc.global_position + Vector2(-12, 0)
	for step_j in range(135):
		lyra_npc._process_witness_corpse_reporting(0.1)
	assert(corpse_a.corpse_reported and corpse_b.corpse_reported, "Both nearby corpses from the same crime scene must be reported once Lyra finishes explaining to police!")

	# 12. Test Interactive 3-Round RPG Interrogation Defense Dialogue & Future Skills System Hook
	assert(player.get_skill_level("charisma") == 1 and is_equal_approx(player.get_skill_bonus("charisma"), 0.0), "Player charisma skill hook must default to level 1 (0.0 bonus)")
	player.player_skills["charisma"] = 4
	assert(player.get_skill_level("charisma") == 4 and is_equal_approx(player.get_skill_bonus("charisma"), 0.15), "Level 4 charisma must grant +15% skill bonus")

	var sh_diag: Dictionary = sheriff_npc._inject_character_lore_into_dialogue(sheriff_npc._build_dialogue())
	assert(sh_diag.has("interrogation_r1") and sh_diag.has("interrogation_r2") and sh_diag.has("interrogation_r3"), "Sheriff dialogue must include 3-round RPG interrogation nodes!")

	# Set up active investigation with player at 55% suspicion (clean, no safe conduct)
	player.bloodstained_timer = 0.0
	p_hc_w.wounds.clear()
	vm.active_sheriff_investigation["active"] = true
	vm.active_sheriff_investigation["stage"] = "INTERVIEWS"
	vm.active_sheriff_investigation["current_interview_target"] = "Jugador"
	vm.active_sheriff_investigation["suspects"]["Jugador"] = {"name": "Jugador (Forastero)", "is_player": true, "score": 55, "interviewed": true, "known_dist": 90.0}

	# Execute the winning 3-round RPG dialogue sequence: init -> r1_correct -> r2_correct -> r3_persuade
	sheriff_npc.on_dialogue_action("interrog_step:init")
	sheriff_npc.on_dialogue_action("interrog_step:r1_correct")
	sheriff_npc.on_dialogue_action("interrog_step:r2_correct")
	sheriff_npc.on_dialogue_action("interrog_step:r3_persuade")

	var new_p_score: int = int(vm.active_sheriff_investigation["suspects"]["Jugador"].get("score", 55))
	assert(new_p_score <= 20 and bool(vm.active_sheriff_investigation["suspects"]["Jugador"].get("persuaded_defense", false)), "Completing the correct 3-round RPG interrogation sequence must reduce player suspicion by -35% (down to <= 20%)!")

	# 13. Test Stealthy Cell Escape (Option C) when officers are sleeping at night
	for n_auth in get_nodes_in_group("village_npcs"):
		if int(n_auth.get("trade_role")) in [9, 10, 12]:
			n_auth.is_sleeping = true
	vm.wanted_level = 1
	vm.bounty_gold = 25
	vm.is_resisting_arrest = false
	vm.player_in_jail = true
	vm.set_jail_cell_gate_locked(true)
	vm._on_police_jailbreak_or_resist(player)
	assert(not vm.player_in_jail and not vm.is_resisting_arrest and vm.wanted_level == 1, "Escaping jail when guards are asleep must be a silent stealth jailbreak without alerting police or adding bounty!")
	for n_auth2 in get_nodes_in_group("village_npcs"):
		if int(n_auth2.get("trade_role")) in [9, 10, 12]:
			n_auth2.is_sleeping = false

	# 14. Test Public Trial in the Plaza (PUBLIC_TRIAL_PLAZA) & Player Intervention (Option C)
	var trial_target = lyra_npc
	var prev_lyra_aff: int = trial_target.affinity
	vm._spawn_royal_investigator()
	var inq_npc = vm._royal_investigator_npc
	assert(inq_npc != null, "Royal Inquisitor Alistair must exist")
	vm.active_royal_investigation = {
		"active": true,
		"stage": "HUNTING_SCAPEGOAT",
		"stage_timer": 0.0,
		"scapegoat_key": trial_target.npc_name,
		"verdict_target": trial_target.npc_name,
		"victim_name": "Maese Casimir",
		"suspects": {trial_target.npc_name: {"name": trial_target.npc_name, "score": 65}},
		"clues_log": []
	}
	inq_npc.global_position = trial_target.global_position + Vector2(10, 0)
	vm.update_royal_investigator_ai(inq_npc, 0.1)
	assert(str(vm.active_royal_investigation.get("stage", "")) == "PUBLIC_TRIAL_PLAZA" and not trial_target.is_dead, "Inquisitor reaching scapegoat must escort them to PUBLIC_TRIAL_PLAZA instead of killing them instantly!")

	var inq_diag: Dictionary = inq_npc._inject_character_lore_into_dialogue(inq_npc._build_dialogue())
	assert(inq_diag.has("public_trial_menu"), "Inquisitor dialogue during PUBLIC_TRIAL_PLAZA must expose public_trial_menu!")

	player.player_skills["charisma"] = 4
	inq_npc.on_dialogue_action("trial_intervene:clemency")
	assert(not trial_target.is_dead and trial_target.affinity >= prev_lyra_aff + 45 and str(vm.active_royal_investigation.get("stage", "")) == "DEPARTING", "Winning clemency plea in Public Trial must spare the scapegoat (+45 affinity) and send Inquisitor to DEPARTING!")

	# 15. Test Dynamic NPC-to-NPC Relationships (Predefined Lore + "Por Azares del Destino" Reconciliation)
	var bram_npc = null
	var mila_npc = null
	var elena_npc = null
	var tomas_npc = null
	for n_rel in get_nodes_in_group("village_npcs"):
		var nm_r: String = str(n_rel.get("npc_name"))
		if nm_r == "Bram": bram_npc = n_rel
		elif nm_r == "Mila": mila_npc = n_rel
		elif nm_r == "Elena": elena_npc = n_rel
		elif nm_r == "Tomás": tomas_npc = n_rel
	assert(bram_npc != null and mila_npc != null, "Bram and Mila must exist")
	bram_npc.ensure_npc_relationships_initialized()
	mila_npc.ensure_npc_relationships_initialized()
	assert(bram_npc.get_relationship_with_npc("Mila") == 85, "Family members Bram and Mila must start at +85 close family relationship!")
	assert(bram_npc.npc_relationships.has("mila") and not bram_npc.npc_relationships.has("Mila"), "B0.4: relationships must be indexed by unique person_id ('mila'), not display name!")
	assert(bram_npc.get_relationship_with_npc("Comisario Vane") == -26, "Bram and Sheriff Vane must start with their predefined lore relationship (-26)!")
	# Simulate a "por azares del destino" reconciliation from rival (-30) to friend (+25)
	bram_npc.npc_relationships["Comisario Vane"] = -30
	sheriff_npc.npc_relationships["Bram"] = -30
	bram_npc.modify_npc_relationship(sheriff_npc, 55, "Se salvaron mutuamente durante una tormenta")
	assert(bram_npc.get_relationship_with_npc("Comisario Vane") == 25 and "Por azares del destino" in bram_npc.get_relationship_note_with_npc("Comisario Vane"), "Rivals crossing from <= -20 to >= +20 must record a 'Por azares del destino' reconciliation note!")
	assert(bram_npc.npc_relationships.has("vane") and not bram_npc.npc_relationships.has("Comisario Vane"), "B0.4: legacy name keys must migrate to person_id!")
	# B0.4: Verify deceased relationship cleanup and non-inheritance
	bram_npc.purge_deceased_relationship("mila", "Mila")
	assert(not bram_npc.npc_relationships.has("mila"), "B0.4: purge_deceased_relationship must remove deceased entry!")
	bram_npc.ensure_npc_relationships_initialized()
	assert(bram_npc.get_relationship_with_npc("mila") == 85, "Living Mila re-initializes cleanly")
	# B0.5: Verify save/load of PersonProfile, relationships, and legacy save fallback
	var bram_saved: Dictionary = bram_npc.to_save_dict()
	assert(bram_saved.has("person_profile") and str(bram_saved["person_profile"].get("person_id", "")) == "bram", "B0.5: to_save_dict must include person_profile!")
	bram_npc.person_profile.age = 99
	bram_npc.from_save_dict(bram_saved)
	assert(bram_npc.person_profile.age == 41 and bram_npc.get_relationship_with_npc("vane") == 25, "B0.5: from_save_dict must restore PersonProfile and relationships!")
	# Legacy save (no person_profile key, relationship keyed by display name "Mila")
	var legacy_save: Dictionary = bram_saved.duplicate(true)
	legacy_save.erase("person_profile")
	legacy_save["npc_relationships"] = {"Mila": 77}
	bram_npc.from_save_dict(legacy_save)
	assert(bram_npc.person_profile != null and bram_npc.person_profile.person_id == "bram" and bram_npc.get_relationship_with_npc("mila") == 77 and bram_npc.npc_relationships.has("mila"), "B0.5: legacy save without person_profile must rebuild default profile and migrate name keys to person_id!")
	bram_npc.from_save_dict(bram_saved)
	var vm_econ_save: Dictionary = vm.get_economy_save_dict()
	assert(vm_econ_save.has("used_first_names") and vm_econ_save.has("used_person_ids"), "B0.5: VillageManager save must persist used names and IDs!")
	# B0.6: Verify social event log recorded Bram + Sheriff Vane reconciliation, filtering, and cap (80)
	var rec_events: Array = vm.get_recent_social_events(10, "reconciliation", "bram")
	assert(not rec_events.is_empty() and str(rec_events[0].get("target_id", "")) == "vane", "B0.6: social_event_log must record reconciliation with actor/target person_ids!")
	for cap_i in range(90):
		vm.record_social_event("chat", bram_npc, mila_npc, "Charla de prueba %d" % cap_i)
	assert(vm.social_event_log.size() == vm.MAX_SOCIAL_EVENT_LOG, "B0.6: social_event_log must respect MAX_SOCIAL_EVENT_LOG (80)!")
	assert(vm.get_economy_save_dict().has("social_event_log"), "B0.6: social_event_log must be persisted in save dict!")
	# B0.7: Verify SocialDirector skeleton, DIALS, max 3 concurrent scenes, 4 metrics, decay, and compatibility rules
	var sdir = vm.social_director
	assert(sdir != null and int(sdir.dials.get("max_concurrent_scenes", 0)) == 3, "B0.7: SocialDirector must be initialized with max_concurrent_scenes == 3!")
	assert(sdir.compute_compatibility(bram_npc.person_profile, mila_npc.person_profile, true) == 0, "B0.7: Same-family compatibility must always be 0!")
	assert(sdir.compute_compatibility(bram_npc.person_profile, sheriff_npc.person_profile, false) == 0, "B0.7: Same-gender heterosexual compatibility must be 0!")
	assert(sdir.compute_compatibility(elena_npc.person_profile, doc_npc.person_profile, false) >= 60, "B0.7: Elena and Dr. Valen must have high compatibility!")
	sdir.set_pair_metrics("bram", "sora", 20, 30, 15, 10)
	sdir.get_pair_entry("bram", "sora")["last_contact_day"] = 1
	sdir.on_day_passed(4)
	var bs_pe: Dictionary = sdir.get_pair_entry("bram", "sora")
	assert(int(bs_pe["familiarity"]) < 30 and int(bs_pe["spark"]) < 15 and int(bs_pe["tension"]) < 10, "B0.7: Days without contact must cool down familiarity, spark, and tension!")
	var sc1: Dictionary = sdir.start_scene("chat", "bram", "mila", 5.0, 4)
	var sc2: Dictionary = sdir.start_scene("chat", "elena", "valen", 5.0, 4)
	var sc3: Dictionary = sdir.start_scene("chat", "thoran", "vane", 5.0, 4)
	var sc_dup: Dictionary = sdir.start_scene("chat", "bram", "tomas", 5.0, 4)
	var sc4: Dictionary = sdir.start_scene("chat", "garrick", "lina", 5.0, 4)
	assert(not sc1.is_empty() and not sc2.is_empty() and not sc3.is_empty() and sc_dup.is_empty() and sc4.is_empty(), "B0.7: SocialDirector must enforce max 3 concurrent scenes and prevent actor overlap!")
	sdir.tick(6.0, vm)
	assert(sdir.active_scenes.is_empty(), "B0.7: Scenes must expire after duration!")

	# 16. Test Worried Family Missing-Person Search (Shop Search 8s -> Police Report 10s -> Police Search Patrol)
	assert(elena_npc != null and tomas_npc != null, "Elena and Tomás must exist for family search test")
	elena_npc.is_dead = false
	elena_npc.is_downed = false
	tomas_npc.is_dead = false
	tomas_npc.is_downed = false
	tomas_npc.corpse_reported = false
	tomas_npc.corpse_in_morgue = false
	# Suppose Elena is killed far away in the forest and Tomás is at home at 22:00
	elena_npc.global_position = Vector2(140, 620)
	elena_npc._confirm_true_death()
	tomas_npc.global_position = tomas_npc.home_table_pos
	if wc:
		wc.current_hour = 22
	for w_i in range(45):
		tomas_npc._process_family_missing_search(0.1)
	assert(tomas_npc._searching_missing_kin == elena_npc and tomas_npc._missing_kin_phase == 1, "At 22:00, Tomás at home must notice Elena hasn't come home and start Phase 1 (search shop)!")
	# Move Tomás to the shop pos and let him search for 8.0s (Elena's body is in the forest, not the shop)
	tomas_npc.global_position = tomas_npc._get_family_shop_search_pos(elena_npc)
	for s_i in range(85):
		tomas_npc._process_family_missing_search(0.1)
	assert(tomas_npc._missing_kin_phase == 2, "After 8s searching the empty shop, Tomás must advance to Phase 2 (walk to police)!")
	# Move Tomás to Sheriff Vane at Police Station and explain for 10.0s
	sheriff_npc.global_position = Vector2(886, 132)
	tomas_npc.global_position = Vector2(880, 132)
	for p_i in range(110):
		tomas_npc._process_family_missing_search(0.1)
	assert(tomas_npc._searching_missing_kin == null and sheriff_npc._patrol_search_target_npc == elena_npc and sheriff_npc._patrol_search_timer > 0.0, "After 10s explaining disappearance to police, Sheriff Vane must launch an active missing-person search patrol!")

	# 17. Test Social Glossary UI (RimWorld + RDR2 Compendium Panel [J])
	var soc_ui = root.find_child("SocialGlossaryUI", true, false)
	assert(soc_ui != null, "SocialGlossaryUI must be instantiated in UI Root!")
	soc_ui.open_panel(bram_npc)
	assert(soc_ui.visible and soc_ui.selected_npc == bram_npc, "Opening SocialGlossaryUI with Bram must select Bram and populate his RimWorld social table!")
	current_scene = main_inst
	assert(player.is_any_ui_modal_open(), "Player.is_any_ui_modal_open() must return true while SocialGlossaryUI is open so the mouse cursor is visible!")
	# Cambiar de vecino debe reutilizar los mismos nodos (sin crear/destruir) y actualizar la ficha y la tabla
	soc_ui._fill_rows_step(100)
	var btn_count_before: int = soc_ui._npc_list_vbox.get_child_count()
	var rows_before: int = soc_ui._social_table_vbox.get_child_count()
	var first_btn_before = soc_ui._npc_list_vbox.get_child(0)
	soc_ui._select_npc(sheriff_npc)
	assert(soc_ui.selected_npc == sheriff_npc, "Selecting another neighbour must change selected_npc!")
	assert(soc_ui._row_fill_idx < soc_ui._row_fill_entries.size() or soc_ui._row_fill_entries.size() <= soc_ui.ROWS_PER_FRAME, "Row refresh must be spread across frames (max 5 rows per frame)!")
	soc_ui._fill_rows_step(100)
	assert(soc_ui._npc_list_vbox.get_child_count() == btn_count_before and soc_ui._social_table_vbox.get_child_count() == rows_before, "Switching neighbour must not create or destroy list buttons / table rows (pooled nodes)!")
	assert(soc_ui._npc_list_vbox.get_child(0) == first_btn_before, "Neighbour list buttons must be reused across selections!")
	var visible_rows: int = 0
	for r_node in soc_ui._social_table_vbox.get_children():
		if r_node.visible:
			visible_rows += 1
	assert(visible_rows == soc_ui._get_all_sorted_npcs().size() - 1, "Social table must show one visible row per other neighbour!")
	soc_ui.close_panel()
	assert(not soc_ui.visible, "Closing SocialGlossaryUI must hide the panel!")

	# 18. Test Unconscious / Stunned / Sedated NPC Reactions Based on Relationship (Enemy Opportunist with Witness Lookout vs Friend Rescue)
	var smith_npc = null
	var garrick_npc = null
	var bram2_npc = null
	for n_u in root.get_tree().get_nodes_in_group("village_npcs"):
		var nm_u: String = str(n_u.get("npc_name"))
		if nm_u == "Thoran": smith_npc = n_u
		elif nm_u == "Garrick": garrick_npc = n_u
		elif nm_u == "Bram": bram2_npc = n_u
	assert(smith_npc != null and garrick_npc != null and bram2_npc != null, "Thoran, Garrick and Bram must exist")
	# Revive Thoran and place him in an isolated spot, sedated with 50 Gold
	smith_npc.is_dead = false
	smith_npc.is_downed = false
	smith_npc.corpse_on_ground = false
	smith_npc.corpse_reported = false
	smith_npc.personal_gold = 50
	smith_npc.global_position = Vector2(220, 320)
	smith_npc.apply_sleeping_draught(35.0)
	garrick_npc.is_dead = false
	garrick_npc.is_downed = false
	garrick_npc.sedated_timer = 0.0
	garrick_npc.is_stunned_flag = false
	garrick_npc.is_sleeping = false
	garrick_npc.npc_relationships["Thoran"] = -35
	smith_npc.npc_relationships["Garrick"] = -35
	garrick_npc.global_position = Vector2(232, 320)
	# Case 18a: While Player is watching nearby (at 240, 320), Garrick must NOT attempt to steal!
	player.global_position = Vector2(240, 320)
	var started_watched: bool = smith_npc.begin_unconscious_neighbor_reaction(garrick_npc)
	assert(not started_watched and smith_npc._unconscious_ignored_by.has("Garrick") and smith_npc.personal_gold == 50, "Opportunist rival Garrick must NOT steal when a witness is watching!")
	# Case 18b: Move Player and all other witnesses far away, clear ignore flag, and let Garrick find Thoran alone
	player.global_position = Vector2(1200, 1200)
	for other_w in root.get_tree().get_nodes_in_group("village_npcs"):
		if other_w != smith_npc and other_w != garrick_npc:
			other_w.global_position = Vector2(950, 150)
	smith_npc._unconscious_ignored_by.clear()
	var started_unseen: bool = smith_npc.begin_unconscious_neighbor_reaction(garrick_npc)
	assert(started_unseen and garrick_npc._unconscious_react_mode == "opportunist_steal", "When no one is watching, rival Garrick must start 'opportunist_steal' on unconscious Thoran!")
	var g_gold_before: int = garrick_npc.personal_gold
	for st_i in range(45):
		garrick_npc._process_unconscious_neighbor_reaction(0.1)
	assert(smith_npc.personal_gold < 50 and garrick_npc.personal_gold > g_gold_before and smith_npc.is_unconscious_on_ground(), "After 4s unseen, Garrick must steal gold from unconscious Thoran and leave him unconscious on the ground!")
	# Case 18c: Friend Bram (rel >= 25) finds unconscious Thoran, wakes him up in 4.0s, and heads to police (Phase 2)
	bram2_npc.is_dead = false
	bram2_npc.is_downed = false
	bram2_npc.sedated_timer = 0.0
	bram2_npc.is_stunned_flag = false
	bram2_npc.is_sleeping = false
	bram2_npc.npc_relationships["Thoran"] = 45
	smith_npc.npc_relationships["Bram"] = 45
	bram2_npc.global_position = Vector2(228, 320)
	var started_friend: bool = smith_npc.begin_unconscious_neighbor_reaction(bram2_npc)
	assert(started_friend and bram2_npc._unconscious_react_mode == "friend_rescue", "Friend Bram must start 'friend_rescue' when finding unconscious Thoran!")
	for fr_i in range(45):
		bram2_npc._process_unconscious_neighbor_reaction(0.1)
	assert(not smith_npc.is_unconscious_on_ground() and bram2_npc._unconscious_react_phase == 2 and bram2_npc.get_relationship_with_npc("Thoran") >= 53, "After 4s of friend rescue, Bram must wake Thoran up (+8 rel) and advance to Phase 2 (report attack to police)!")

	# 19. Sistema de Habilidades RPG (XP, niveles, guardado/carga, panel [K] modal, XP de sigilo)
	player.player_skills["cooking"] = 1
	player.player_skill_xp.clear()
	player.add_skill_xp("cooking", 55) # xp_for_next(1) == 55 -> nivel 2
	assert(player.get_skill_level("cooking") == 2 and player.get_skill_xp("cooking") == 0, "55 XP must level Cooking 1 -> 2 with 0 leftover XP!")
	player.add_skill_xp("cooking", 10)
	assert(player.get_skill_xp("cooking") == 10 and abs(player.get_skill_bonus("cooking") - 0.05) < 0.0001, "Cooking level 2 must give +5% bonus and keep 10 XP progress!")
	player.add_skill_xp("cooking", 100000)
	assert(player.get_skill_level("cooking") == SkillCatalog.MAX_LEVEL and player.get_skill_xp("cooking") == 0, "Skill level must cap at MAX_LEVEL!")
	player.add_skill_xp("invalid_skill", 50)
	assert(not player.player_skill_xp.has("invalid_skill"), "Unknown skills must be ignored!")
	player.player_skills["stealth"] = 3
	player.player_skill_xp["stealth"] = 17
	var sv: Dictionary = player.to_save_dict()
	player.player_skills["stealth"] = 1
	player.player_skill_xp["stealth"] = 0
	player.from_save_dict(sv)
	assert(player.get_skill_level("stealth") == 3 and player.get_skill_xp("stealth") == 17, "Skill level and XP must survive a save/load round trip!")
	var sk_ui = root.find_child("SkillsPanelUI", true, false)
	assert(sk_ui != null, "SkillsPanelUI must be instantiated in UI Root!")
	current_scene = main_inst
	sk_ui.open_panel()
	assert(sk_ui.visible and player.is_any_ui_modal_open(), "Skills panel must count as an open UI modal (mouse cursor visible)!")
	sk_ui.close_panel()
	assert(not sk_ui.visible, "Closing the skills panel must hide it!")
	var marlo_npc = null
	for n_s in root.get_tree().get_nodes_in_group("village_npcs"):
		if str(n_s.get("npc_name")) == "Marlo":
			marlo_npc = n_s
	assert(marlo_npc != null, "Marlo must exist")
	marlo_npc.is_dead = false
	marlo_npc.is_downed = false
	marlo_npc.sedated_timer = 0.0
	marlo_npc.is_stunned_flag = false
	var st_xp_before: int = player.get_skill_xp("stealth")
	var st_lvl_before: int = player.get_skill_level("stealth")
	marlo_npc.stealth_knockout(player)
	assert(player.get_skill_level("stealth") > st_lvl_before or player.get_skill_xp("stealth") > st_xp_before, "Stealth knockout must award Stealth XP!")

	print("ALL RIMWORLD MEDICAL, FOOTPRINTS, 3-PHASE CORPSE REPORT, MULTI-CORPSE FIX, RPG INTERROGATION, PUBLIC TRIAL, DYNAMIC RELATIONSHIPS, MISSING FAMILY SEARCH, SOCIAL GLOSSARY & UNCONSCIOUS REACTION TESTS PASSED!")
	quit(0)
