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
	sdir.active_scenes.clear()  # Evita interferencias de charlas en vivo surgidas durante los frames iniciales
	var sc1: Dictionary = sdir.start_scene("chat", "bram", "mila", 5.0, 4)
	var sc2: Dictionary = sdir.start_scene("chat", "elena", "valen", 5.0, 4)
	var sc3: Dictionary = sdir.start_scene("chat", "thoran", "vane", 5.0, 4)
	var sc_dup: Dictionary = sdir.start_scene("chat", "bram", "tomas", 5.0, 4)
	var sc4: Dictionary = sdir.start_scene("chat", "garrick", "lina", 5.0, 4)
	assert(not sc1.is_empty() and not sc2.is_empty() and not sc3.is_empty() and sc_dup.is_empty() and sc4.is_empty(), "B0.7: SocialDirector must enforce max 3 concurrent scenes and prevent actor overlap!")
	sdir.tick(6.0, vm)
	assert(sdir.active_scenes.is_empty(), "B0.7: Scenes must expire after duration!")
	# B0.8: Verify initial couple Elena + Dr. Valen
	assert(elena_npc.person_profile.romance_status == "partnered" and elena_npc.person_profile.partner_id == "valen", "B0.8: Elena must start partnered with Dr. Valen!")
	assert(doc_npc.person_profile.romance_status == "partnered" and doc_npc.person_profile.partner_id == "elena", "B0.8: Dr. Valen must start partnered with Elena!")
	assert(str(sdir.get_pair_entry("elena", "valen").get("stage", "")) == "couple", "B0.8: SocialDirector must seed Elena + Valen as stage 'couple'!")

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
	assert(doc_npc.person_profile.romance_status == "widowed" and doc_npc.person_profile.partner_id == "", "B0.8: When Elena dies, Dr. Valen must become widowed!")
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

	# 20. Persistent Time Scale Multiplier (RimWorld / RTS style: 1x, 2x, 4x, 8x)
	var wc_speed = root.get_node_or_null("/root/WorldClock")
	assert(wc_speed != null, "WorldClock autoload must exist")
	wc_speed.set_persistent_time_scale(4.0)
	assert(is_equal_approx(wc_speed.persistent_time_scale, 4.0) and is_equal_approx(Engine.time_scale, 4.0) and Engine.physics_ticks_per_second == 180, "4x persistent time scale must set Engine.time_scale=4.0 and physics_ticks_per_second=180!")
	wc_speed.start_organic_fast_forward(6, 26.0)
	assert(is_equal_approx(Engine.time_scale, 26.0), "Organic fast-forward [T] must override to 26x while active!")
	wc_speed.stop_organic_fast_forward(false)
	assert(is_equal_approx(Engine.time_scale, 4.0) and Engine.physics_ticks_per_second == 180, "Stopping organic fast-forward must restore persistent 4x speed, not 1.0x!")
	wc_speed.cycle_persistent_time_scale(1)
	assert(is_equal_approx(wc_speed.persistent_time_scale, 8.0) and is_equal_approx(Engine.time_scale, 8.0) and Engine.physics_ticks_per_second == 240, "Stepping up from 4x must reach 8x (240 physics TPS)!")
	wc_speed.set_persistent_time_scale(1.0)
	assert(is_equal_approx(Engine.time_scale, 1.0) and Engine.physics_ticks_per_second == 60, "Resetting to 1x must restore Engine.time_scale=1.0 and 60 physics TPS!")

	# 21. B1.3: Escena de conversación en vivo de 2 turnos (SocialDirector + VillageNPC)
	assert(smith_npc != null and bram2_npc != null and vm.social_director != null, "Thoran, Bram and SocialDirector must exist")
	vm.social_director.active_scenes.clear()
	smith_npc.is_dead = false
	smith_npc.is_downed = false
	smith_npc.is_sleeping = false
	smith_npc.sedated_timer = 0.0
	smith_npc._npc_social_event_cooldown = 0.0
	smith_npc._pending_social_reply_timer = 0.0
	bram2_npc.is_dead = false
	bram2_npc.is_downed = false
	bram2_npc.is_sleeping = false
	bram2_npc.sedated_timer = 0.0
	bram2_npc._npc_social_event_cooldown = 0.0
	bram2_npc._pending_social_reply_timer = 0.0
	smith_npc.global_position = Vector2(300, 300)
	bram2_npc.global_position = Vector2(316, 300)
	var rel_before_conv: int = smith_npc.get_relationship_with_npc("bram")
	smith_npc._trigger_dynamic_npc_social_interaction(bram2_npc)
	assert(smith_npc.last_social_line_spoken != "", "Initiator Thoran must speak a real opening phrase in Turn 1!")
	assert(bram2_npc._pending_social_reply_timer > 1.0 and not bram2_npc._pending_social_reply_data.is_empty(), "Partner Bram must have a pending Turn 2 reply scheduled (~1.8s)!")
	assert(vm.social_director.active_scenes.size() == 1, "SocialDirector must track the active conversation scene!")
	assert(smith_npc.get_relationship_with_npc("bram") == rel_before_conv, "Relationship change must wait until Turn 2 reply completes!")
	bram2_npc._process_pending_social_reply(2.0)
	assert(bram2_npc._pending_social_reply_timer == 0.0 and bram2_npc.last_social_line_spoken != "", "Partner Bram must speak his Turn 2 reply after 1.8s!")
	assert(smith_npc.get_relationship_with_npc("bram") != rel_before_conv, "Relationship must update after Turn 2 reply completes!")

	# Test #22 (B2.2): Quedada física entre amigos (Thoran y Bram) a las 19h + rivales que se evitan
	print("Testing B2.2 physical hangouts...")
	vm.social_director.active_scenes.clear()
	vm.social_director.active_hangouts.clear()
	vm.social_director.finished_hangouts.clear()
	vm.social_director.hangout_day_counts.clear()
	wc_speed.current_hour = 19
	for n_h in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n_h.has_method("clear_hangout"):
			n_h.clear_hangout()
			if n_h != smith_npc and n_h != bram2_npc:
				n_h.current_activity = 0  # ActivityState.WORKING
	for v_h in [smith_npc, bram2_npc]:
		v_h.is_hostile = false
		v_h.is_sleeping = false
		v_h.current_activity = 3  # ActivityState.SOCIALIZING
	smith_npc.modify_npc_relationship(bram2_npc, 60 - smith_npc.get_relationship_with_npc(bram2_npc.get_person_key()), "Test amistad")
	vm._hangout_plan_timer = 0.0
	vm._update_social_hangouts(0.1)
	assert(smith_npc.hangout_id >= 0 and smith_npc.hangout_id == bram2_npc.hangout_id, "Thoran and Bram (friends, 19h, socializing) must be assigned the same hangout!")
	assert(smith_npc._social_partner == bram2_npc and bram2_npc._social_partner == smith_npc, "Hangout partners must target each other")
	assert(smith_npc.get_activity_description().begins_with("🚶"), "Activity must show they are on the way to the hangout")
	var rel_before_hg: int = smith_npc.get_relationship_with_npc(bram2_npc.get_person_key())
	smith_npc.global_position = smith_npc._get_social_target_pos()
	bram2_npc.global_position = bram2_npc._get_social_target_pos()
	vm._update_social_hangouts(0.1)
	var hg_live: Dictionary = vm.social_director.get_active_hangout_for(smith_npc.get_person_key())
	assert(str(hg_live.get("phase", "")) == "together", "Both at the spot -> hangout phase must be 'together'")
	assert(smith_npc.get_activity_description().begins_with("☕"), "Activity must show they are spending time together")
	vm.social_director.tick(50.0)
	vm._update_social_hangouts(0.1)
	assert(smith_npc.hangout_id == -1 and bram2_npc.hangout_id == -1, "Hangout must be cleared on both NPCs after completing")
	assert(smith_npc.get_relationship_with_npc(bram2_npc.get_person_key()) > rel_before_hg, "Completed hangout must raise the relationship")
	var hg_events: Array = vm.get_recent_social_events(5, "hangout")
	assert(hg_events.size() >= 1, "Completed hangout must be recorded in the social event log")
	# Interrupción: si uno se va a dormir, la quedada se cancela y ambos quedan libres
	vm.social_director.hangout_day_counts.clear()
	vm._hangout_plan_timer = 0.0
	vm._update_social_hangouts(0.1)
	assert(smith_npc.hangout_id >= 0, "A new hangout must be planned (daily cap reset)")
	bram2_npc.current_activity = 2  # ActivityState.SLEEPING
	vm._update_social_hangouts(0.1)
	vm._update_social_hangouts(0.1)
	assert(smith_npc.hangout_id == -1 and vm.social_director.active_hangouts.is_empty(), "Hangout must be cancelled if a participant leaves")
	# Rivales se evitan: Thoran no elige a Garrick como compañero de charla
	vm.social_director.set_pair_metrics(smith_npc.get_person_key(), garrick_npc.get_person_key(), -50, 20, 0, 50)
	assert(vm.social_director.should_avoid(smith_npc.get_person_key(), garrick_npc.get_person_key()), "Rivals must be flagged to avoid each other")
	garrick_npc.is_dead = false
	garrick_npc.is_downed = false
	garrick_npc.is_sleeping = false
	for _rr in range(25):
		assert(smith_npc._find_best_social_partner() != garrick_npc, "Rival Garrick must never be chosen as social partner")
	print("B2.2 physical hangouts OK")

	# Test #23 (B3.1): Avance diario de cortejo en vivo hasta formar pareja (fichas, relación, registro social)
	var sd3 = vm.social_director
	var best3: Array = []
	var best3_c: int = -1
	var live3: Array = []
	for n3 in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n3.has_method("get_person_key") and not n3.is_dead and n3.person_profile != null and str(n3.person_profile.romance_status) == "single":
			live3.append(n3)
	for i3 in range(live3.size()):
		for j3 in range(i3 + 1, live3.size()):
			var fa3: String = str(live3[i3].family_id)
			var same3: bool = fa3 != "none" and fa3 != "" and fa3 != "family_police" and fa3 == str(live3[j3].family_id)
			var c3: int = sd3.compute_compatibility(live3[i3].person_profile, live3[j3].person_profile, same3)
			if c3 > best3_c:
				best3_c = c3
				best3 = [live3[i3], live3[j3]]
	assert(best3_c >= 40, "There must be a compatible single pair in the village")
	var na3 = best3[0]
	var nb3 = best3[1]
	var day3: int = int(wc_speed.current_day)
	sd3.set_pair_metrics(na3.get_person_key(), nb3.get_person_key(), 40, 50, 70, 0, "dating")
	sd3.get_pair_entry(na3.get_person_key(), nb3.get_person_key())["last_contact_day"] = day3
	var old_chance3 = sd3.dials["live_stage_advance_chance"]
	sd3.dials["live_stage_advance_chance"] = 10.0
	vm._advance_live_romances(day3)
	sd3.dials["live_stage_advance_chance"] = old_chance3
	assert(str(na3.person_profile.romance_status) == "partnered" and str(na3.person_profile.partner_id) == nb3.get_person_key(), "B3.1: Dating pair with spark 70 must become a couple")
	assert(na3.get_relationship_with_npc(nb3.get_person_key()) >= 68 and nb3.get_relationship_with_npc(na3.get_person_key()) >= 68, "B3.1: New couple relationship must be >= 68 on both sides")
	assert(vm.get_recent_social_events(5, "couple").size() >= 1, "B3.1: New couple must be recorded in the social event log")
	print("B3.1 live romance stages OK (%s + %s)" % [na3.npc_name, nb3.npc_name])

	# Test #24 (B3.2): Comportamiento en vivo de la pareja (tarde juntos, estado 💑 y evento 'date')
	sd3.active_hangouts.clear()
	sd3.finished_hangouts.clear()
	sd3.hangout_day_counts.clear()
	for n_r in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n_r.has_method("clear_hangout"):
			n_r.clear_hangout()
			if n_r != na3 and n_r != nb3:
				n_r.current_activity = 0
	for v_r in [na3, nb3]:
		v_r.is_hostile = false
		v_r.is_sleeping = false
		v_r.current_activity = 3
	wc_speed.current_hour = 19
	vm._hangout_plan_timer = 0.0
	vm._update_social_hangouts(0.1)
	assert(na3.hangout_id >= 0 and na3.hangout_id == nb3.hangout_id, "B3.2: Couple must plan an evening hangout together")
	assert(na3.get_activity_description().begins_with("💑"), "B3.2: Couple hangout activity must show 💑")
	na3.global_position = na3._get_social_target_pos()
	nb3.global_position = nb3._get_social_target_pos()
	vm._update_social_hangouts(0.1)
	assert(na3.get_activity_description().begins_with("💑 Pasando la tarde con"), "B3.2: Couple at spot must show '💑 Pasando la tarde con...'")
	sd3.tick(50.0)
	vm._update_social_hangouts(0.1)
	assert(vm.get_recent_social_events(5, "date").size() >= 1, "B3.2: Completed couple hangout must record a 'date' social event")
	print("B3.2 romantic behavior & dates OK")

	# Test #25 (B3.3): Ruptura por alta tensión y reconciliación posterior en vivo
	var day33: int = int(wc_speed.current_day)
	sd3.set_pair_metrics(na3.get_person_key(), nb3.get_person_key(), 5, 60, 65, 75, "couple")
	var old_brk = sd3.dials["breakup_daily_chance"]
	sd3.dials["breakup_daily_chance"] = 1.0
	vm._advance_live_romances(day33)
	sd3.dials["breakup_daily_chance"] = old_brk
	assert(str(na3.person_profile.romance_status) == "single" and str(nb3.person_profile.romance_status) == "single", "B3.3: Couple with high tension & low affinity must break up")
	assert(vm.get_recent_social_events(5, "breakup").size() >= 1, "B3.3: Breakup must be recorded in the social event log")
	sd3.set_pair_metrics(na3.get_person_key(), nb3.get_person_key(), 42, 65, 50, 10, "none")
	sd3.get_pair_entry(na3.get_person_key(), nb3.get_person_key())["ex_couple"] = true
	sd3.get_pair_entry(na3.get_person_key(), nb3.get_person_key())["last_contact_day"] = day33
	var old_rec = sd3.dials["reconcile_ex_chance"]
	sd3.dials["reconcile_ex_chance"] = 1.0
	vm._advance_live_romances(day33)
	sd3.dials["reconcile_ex_chance"] = old_rec
	assert(str(na3.person_profile.romance_status) == "partnered" and str(na3.person_profile.partner_id) == nb3.get_person_key(), "B3.3: Ex-couple with spark & low tension must reconcile")
	assert(vm.get_recent_social_events(5, "couple_reconciled").size() >= 1, "B3.3: Reconciliation must be recorded in the social event log")
	print("B3.3 jealousy, breakups & reconciliation OK")

	# Test #26 (B3.4): Duelo y viudedad mejorados (luto de varios días y visita a la tumba en horas libres)
	na3.person_profile.start_bereavement(nb3.npc_name, 2)
	na3.clear_hangout()
	na3.current_activity = 3  # ActivityState.SOCIALIZING
	assert(na3.is_visiting_grave(), "B3.4: Widowed NPC in bereavement during socializing hours must visit the grave")
	var grave_target: Vector2 = na3._get_social_target_pos()
	assert(grave_target.distance_to(vm._cemetery_gate_pos) <= 120.0, "B3.4: Social target during bereavement must point to the cemetery")
	na3.global_position = grave_target
	assert(na3.get_activity_description().begins_with("🪦 Visitando la tumba de"), "B3.4: Activity at grave must show '🪦 Visitando la tumba de...'")
	vm._advance_live_romances(day33 + 1)
	assert(int(na3.person_profile.bereavement_days_left) == 1 and str(na3.person_profile.romance_status) == "widowed", "B3.4: Day 1 of bereavement must keep widowed status and decrement counter")
	vm._advance_live_romances(day33 + 2)
	assert(int(na3.person_profile.bereavement_days_left) == 0 and str(na3.person_profile.romance_status) == "single", "B3.4: Finishing bereavement must return status to single")
	assert(vm.get_recent_social_events(5, "bereavement_ended").size() >= 1, "B3.4: Ending bereavement must record 'bereavement_ended' social event")
	print("B3.4 bereavement & grave visits OK")

	# B4.1: Un vecino real expone su salud para el poder de pelea
	var hp_saved: float = smith.health_comp.current_health
	smith.health_comp.current_health = smith.health_comp.get_effective_max_health() * 0.5
	assert(absf(smith.health_comp.get_overall_health_pct() - 50.0) < 0.01, "B4.1: Salud a la mitad debe dar 50%")
	smith.health_comp.current_health = hp_saved
	print("B4.1 real health for fight power OK")

	# Test #27 (B4.2): Pelea discreta en vivo sin muerte, con reacción del guardia y registro social
	var sd4 = vm.social_director
	var f_a = vm._find_npc_by_name("Thoran")
	var f_b = vm._find_npc_by_name("Bram")
	var police4: Array = []
	for n4 in vm.get_tree().get_nodes_in_group("village_npcs"):
		if int(n4.trade_role) in [9, 10]:  # SHERIFF, GUARD
			police4.append(n4)
			n4.global_position = Vector2(-4000, -4000)
	var prepare_fight = func(tension_v: int, day_v: int) -> void:
		sd4.active_scenes.clear()
		sd4.pair_metrics.clear()
		sd4.last_drama_day = -10
		vm._live_fights.clear()
		sd4.dials["live_fight_daily_chance"] = 10.0
		sd4.set_pair_metrics(f_a.get_person_key(), f_b.get_person_key(), -35, 40, 0, tension_v)
		sd4.get_pair_entry(f_a.get_person_key(), f_b.get_person_key())["enmity_days"] = 10
		for fv in [f_a, f_b]:
			fv.is_sleeping = false
			fv.is_hostile = false
			fv.is_vagrant_camper = false
			fv._reporting_corpse_target = null
			fv._searching_missing_kin = null
			fv._reacting_unconscious_target = null
			fv.clear_hangout()
			fv.end_live_fight()
		f_a.global_position = Vector2(300, 300)
		f_b.global_position = Vector2(330, 300)
		wc_speed.current_day = day_v
		vm._fight_scan_timer = 0.0
	var old_chance4 = sd4.dials["live_fight_daily_chance"]
	var rel_before4: int = f_a.get_relationship_with_npc(f_b.get_person_key())
	var ev_before4: int = vm.get_recent_social_events(80, "fight").size()
	prepare_fight.call(20, int(wc_speed.current_day) + 20)
	vm._try_start_live_fight()
	assert(vm._live_fights.is_empty(), "B4.2: Below the live threshold there must be no fight")
	prepare_fight.call(45, int(wc_speed.current_day) + 20)
	vm._try_start_live_fight()
	assert(vm._live_fights.size() == 1 and f_a.is_in_live_fight() and f_b.is_in_live_fight(), "B4.2: Tense neighbors close together must start a fight")
	assert(f_a.get_activity_description().contains("Peleando"), "B4.2: Fight must be visible in the activity text")
	var wounds_before4: int = f_a.health_comp.wounds.size() + f_b.health_comp.wounds.size()
	vm._fight_scan_timer = 999.0
	vm._update_live_fights(4.0)
	assert(vm._live_fights.is_empty() and not f_a.is_in_live_fight() and not f_b.is_in_live_fight(), "B4.2: Fight must end and free both NPCs")
	assert(sd4.active_scenes.is_empty(), "B4.2: Fight scene must be released")
	assert(f_a.health_comp.wounds.size() + f_b.health_comp.wounds.size() == wounds_before4 + 1, "B4.2: Loser must get exactly one wound")
	var last_w4: Dictionary = (f_a.health_comp.wounds + f_b.health_comp.wounds).filter(func(w): return str(w.get("weapon_cause", "")).begins_with("Pelea con"))[0]
	assert(str(last_w4["type"]) == "bruise" and str(last_w4["organ"]) == "" and float(last_w4["bleed_rate"]) == 0.0, "B4.2: Wound must be a light bruise")
	assert(f_a.get_relationship_with_npc(f_b.get_person_key()) < rel_before4, "B4.2: Fight must worsen the relationship")
	assert(vm.get_recent_social_events(80, "fight").size() == ev_before4 + 1, "B4.2: Fight must be recorded in the social log")
	assert(not f_a.is_hostile and not f_b.is_hostile and not f_a.is_incapacitated() and not f_b.is_incapacitated(), "B4.2: Fight must not trigger hostility or unconsciousness")
	# El perdedor nunca baja del 35% de salud
	var hurt_hp4: float = f_a.health_comp.get_effective_max_health() * 0.36
	f_a.health_comp.current_health = hurt_hp4
	assert(f_a.health_comp.apply_minor_bruise(20.0, 0.35) > 0.0 and f_a.health_comp.current_health >= f_a.health_comp.get_effective_max_health() * 0.35 - 0.01, "B4.2: Bruise must respect the 35% floor")
	assert(f_a.health_comp.apply_minor_bruise(20.0, 0.35) == 0.0, "B4.2: At the floor a bruise does nothing")
	f_a.health_comp.current_health = f_a.health_comp.get_effective_max_health()
	# Un guardia a 140 px o menos separa a los vecinos antes de que haya heridas
	prepare_fight.call(45, int(wc_speed.current_day) + 20)
	police4[0].global_position = Vector2(315, 400)
	police4[0].is_sleeping = false
	vm._try_start_live_fight()
	assert(vm._live_fights.size() == 1 and vm._live_fights[0]["guard"] == police4[0], "B4.2: Nearby guard must be assigned")
	var wounds_guard4: int = f_a.health_comp.wounds.size() + f_b.health_comp.wounds.size()
	vm._fight_scan_timer = 999.0
	vm._update_live_fights(1.7)
	assert(vm._live_fights.is_empty(), "B4.2: Guard must stop the fight early")
	assert(f_a.health_comp.wounds.size() + f_b.health_comp.wounds.size() == wounds_guard4, "B4.2: A stopped fight leaves no wound")
	# Una pelea interrumpida no gasta el cupo y unos ex enemigos reconciliados ya no pelean
	prepare_fight.call(45, int(wc_speed.current_day) + 20)
	vm._try_start_live_fight()
	vm._fight_scan_timer = 999.0
	f_b.is_hostile = true
	vm._update_live_fights(0.01)
	f_b.is_hostile = false
	var pe_refund: Dictionary = sd4.get_pair_entry(f_a.get_person_key(), f_b.get_person_key())
	assert(int(pe_refund["fights_count"]) == 0 and int(pe_refund["tension"]) == 45, "B6.4: An interrupted fight must be refunded")
	pe_refund["affinity"] = 40
	assert(not sd4.can_pair_fight(f_a.get_person_key(), f_b.get_person_key(), int(wc_speed.current_day) + 40), "B6.4: Reconciled pairs must not fight")
	# Dos rivales que se cruzan acumulan tensión, una sola vez al día
	prepare_fight.call(0, int(wc_speed.current_day) + 20)
	f_a.npc_relationships[f_b.get_person_key()] = -30
	vm._scan_rival_friction()
	vm._scan_rival_friction()
	var tension4: int = int(sd4.get_pair_entry(f_a.get_person_key(), f_b.get_person_key()).get("tension", 0))
	assert(tension4 >= 2 and tension4 <= 4, "B4.2: Enemies crossing paths gain tension once per day")
	assert(int(sd4.get_pair_entry(f_a.get_person_key(), f_b.get_person_key()).get("enmity_days", 0)) == 11, "B4.2: Crossing paths adds one enmity day")
	sd4.dials["live_fight_daily_chance"] = old_chance4
	vm._fight_scan_timer = 3.0
	print("B4.2 live fights OK")

	# Test #28 (B5.1): Preguntar opiniones y escuchar a escondidas
	for k51 in f_a.npc_relationships.keys():
		f_a.npc_relationships[k51] = 0
	f_a.npc_relationships[f_b.get_person_key()] = -80
	f_a.affinity = 50
	var diag51: Dictionary = f_a._inject_character_lore_into_dialogue(f_a._build_dialogue())
	assert(str(diag51["neighbor_opinions"]["choices"][0]["label"]).contains("Bram"), "B5.1: Strongest feeling must be listed first")
	assert(str(diag51["opinion_0"]["text"]).contains("detestan"), "B5.1: Opinion must describe the real relationship")
	f_a.affinity = -5
	assert(not f_a._inject_character_lore_into_dialogue(f_a._build_dialogue()).has("opinion_0"), "B5.1: Neighbors do not open up to someone they dislike")
	f_a.affinity = 50
	var pos51: Vector2 = player.global_position
	var mv51 = player.get_node("PlayerMovementController")
	var st51: bool = mv51.is_stealthing
	player.global_position = f_a.global_position + Vector2(40, 0)
	mv51.is_stealthing = false
	assert(not f_a._try_player_overhear(f_b, "Discutieron"), "B5.1: Without stealth nothing is overheard")
	mv51.is_stealthing = true
	assert(f_a._try_player_overhear(f_b, "Discutieron"), "B5.1: Stealthing nearby must overhear")
	player.global_position = f_a.global_position + Vector2(400, 0)
	assert(not f_a._try_player_overhear(f_b, "Discutieron"), "B5.1: Too far to overhear")
	mv51.is_stealthing = st51
	player.global_position = pos51
	print("B5.1 opinions & eavesdropping OK")

	# Test #29 (B5.2): Hablar mal de un vecino, una vez al día, y fallar se vuelve contra el jugador
	var key52: String = f_b.get_person_key()
	f_a.npc_relationships[key52] = 0
	sd4.dials["gossip_min_chance"] = 1.0
	sd4.player_influence_day = -1
	f_a.on_dialogue_action("social_gossip:bad:" + key52)
	var rel52: int = f_a.get_relationship_with_npc(key52)
	assert(rel52 <= -4 and rel52 >= -8, "B5.2: Successful slander must slightly lower the relationship")
	assert(not str(f_a._inject_character_lore_into_dialogue(f_a._build_dialogue())["opinion_0"]["choices"]).contains("social_gossip"), "B5.2: Only one influence per day")
	f_a.on_dialogue_action("social_gossip:bad:" + key52)
	assert(f_a.get_relationship_with_npc(key52) == rel52, "B5.2: A second attempt the same day does nothing")
	sd4.dials["gossip_min_chance"] = 0.0
	sd4.dials["gossip_max_chance"] = 0.0
	sd4.player_influence_day = -1
	var aff52: int = f_a.affinity
	f_a.on_dialogue_action("social_gossip:bad:" + key52)
	assert(f_a.affinity < aff52 and f_a.get_relationship_with_npc(key52) == rel52, "B5.2: Failure must hurt the player, not the neighbors")
	sd4.dials["gossip_min_chance"] = 0.15
	sd4.dials["gossip_max_chance"] = 0.90
	print("B5.2 player gossip OK")

	# Test #30 (B5.3): Mediar enfría la enemistad y el jugador puede separar una pelea sin heridas
	var old_chance53 = sd4.dials["live_fight_daily_chance"]
	prepare_fight.call(45, int(wc_speed.current_day) + 20)
	f_a.npc_relationships[key52] = -30
	sd4.dials["gossip_min_chance"] = 1.0
	sd4.player_influence_day = -1
	assert(str(f_a._inject_character_lore_into_dialogue(f_a._build_dialogue())).contains("social_gossip:peace:" + key52), "B5.3: Enemies must offer the mediation option")
	f_a.on_dialogue_action("social_gossip:peace:" + key52)
	var pe53: Dictionary = sd4.get_pair_entry(f_a.get_person_key(), key52)
	assert(f_a.get_relationship_with_npc(key52) > -30 and int(pe53["tension"]) <= 34 and int(pe53["enmity_days"]) == 6, "B5.3: Mediation must cool the enmity")
	sd4.dials["gossip_min_chance"] = 0.15
	prepare_fight.call(45, int(wc_speed.current_day) + 20)
	vm._try_start_live_fight()
	assert(str(f_a._inject_character_lore_into_dialogue(f_a._build_dialogue())).contains("social_stop_fight"), "B5.3: A fight must offer to separate them")
	var wounds53: int = f_a.health_comp.wounds.size() + f_b.health_comp.wounds.size()
	f_a.on_dialogue_action("social_stop_fight")
	assert(vm._live_fights.is_empty() and not f_a.is_in_live_fight() and not f_b.is_in_live_fight() and sd4.active_scenes.is_empty(), "B5.3: Player must end the fight")
	assert(f_a.health_comp.wounds.size() + f_b.health_comp.wounds.size() == wounds53, "B5.3: A separated fight leaves no wound")
	sd4.dials["live_fight_daily_chance"] = old_chance53
	print("B5.3 mediation OK")

	# Test #31 (B5.4): Casamentero solo entre solteros compatibles; suma chispa sin saltarse etapas
	var pair54: Array = []
	for x54 in live3:
		for y54 in live3:
			if pair54.is_empty() and x54 != y54 and x54.family_id != y54.family_id and not x54.is_dead and not y54.is_dead and sd4.can_matchmake(x54.person_profile, y54.person_profile, false):
				pair54 = [x54, y54]
	assert(pair54.size() == 2, "B5.4: The village must have a compatible single pair")
	var m_a = pair54[0]
	var key54: String = pair54[1].get_person_key()
	var keep_status54: String = str(pair54[1].person_profile.romance_status)
	pair54[1].person_profile.romance_status = "partnered"
	assert(not sd4.can_matchmake(m_a.person_profile, pair54[1].person_profile, false), "B5.4: Someone with a partner cannot be matched")
	pair54[1].person_profile.romance_status = keep_status54
	sd4.pair_metrics.clear()
	sd4.set_pair_metrics(m_a.get_person_key(), key54, 10, 20, 0, 0)
	sd4.dials["gossip_min_chance"] = 1.0
	sd4.player_influence_day = -1
	m_a.affinity = 50
	m_a.on_dialogue_action("social_gossip:match:" + key54)
	var pe54: Dictionary = sd4.get_pair_entry(m_a.get_person_key(), key54)
	assert(int(pe54["spark"]) >= 6 and str(pe54.get("stage", "none")) == "none", "B5.4: Matchmaking adds spark without forcing a romance stage")
	sd4.dials["gossip_min_chance"] = 0.15
	print("B5.4 matchmaking OK")

	# Test #32 (B6.1/B6.2): Los chismes corren de uno en uno y solo lo muy sabido llega al tablón
	vm.social_event_log.clear()
	var g_c = vm._find_npc_by_name("Sora")
	vm.record_social_event("fight", f_a, f_b, "Thoran y Bram se pelearon")
	vm.record_social_event("hangout", f_a, f_b, "Pasaron un rato juntos")
	assert(vm.get_public_news().is_empty(), "B6.2: News known only by its protagonists is not public yet")
	assert(str(vm.spread_gossip(f_a, g_c).get("type", "")) == "fight", "B6.1: A teller shares news the listener ignores")
	assert(vm.spread_gossip(f_a, g_c).is_empty(), "B6.1: The same news is not told twice")
	assert(vm.get_news_known_by(g_c).size() == 1, "B6.1: Listener can now tell the player")
	assert(vm.get_public_news().size() == 1, "B6.2: Widely known news reaches the board")
	vm._open_notice_board_ui()
	assert(not vm.board_panel or vm.board_info_lbl.text.contains("se pelearon"), "B6.2: Board must show the news")
	vm.board_panel.visible = false
	vm.social_event_log.clear()
	vm.record_social_event("player_slander", f_a, f_b, "El forastero habló mal de Bram a Thoran")
	var aff_b6: int = f_b.affinity
	vm.spread_gossip(f_a, f_b)
	assert(f_b.affinity < aff_b6, "B6.1: Learning what the player said hurts their affinity")
	print("B6.1/B6.2 gossip & news OK")

	# Test #33 (R1): Ciclo real de guardar en archivo, cambiar el mundo y cargar
	var gm = root.get_node("/root/GameManager")
	var save_path: String = "user://test_roundtrip_r1.json"
	var key_a: String = f_a.get_person_key()
	var key_b: String = f_b.get_person_key()
	sd4.set_pair_metrics(key_a, key_b, -40, 40, 12, 33)
	sd4.get_pair_entry(key_a, key_b)["enmity_days"] = 7
	sd4.get_pair_entry(key_a, key_b)["fights_count"] = 1
	sd4.player_influence_day = 77
	sd4.last_drama_day = 55
	vm.social_event_log.clear()
	vm.record_social_event("fight", f_a, f_b, "Pelea guardada")
	vm.spread_gossip(f_a, g_c)
	f_a.npc_relationships[key_b] = -44
	f_a.health_comp.apply_minor_bruise(8.0)
	var hp_r1: float = f_a.health_comp.current_health
	var wounds_r1: int = f_a.health_comp.wounds.size()
	f_a.person_profile.age = 51
	f_a.affinity = 23
	vm.wanted_level = 2
	vm.bounty_gold = 40
	var gold_r1: int = int(player.inventory.gold)
	var day_r1: int = int(wc_speed.current_day)
	assert(gm.save_game(save_path), "R1: Save must succeed")
	# Cambiar todo lo anterior, incluida una pelea en marcha
	sd4.set_pair_metrics(key_a, key_b, 90, 1, 1, 1)
	sd4.player_influence_day = 1
	sd4.last_drama_day = 1
	vm.social_event_log.clear()
	f_a.npc_relationships[key_b] = 90
	f_a.health_comp.current_health = 5.0
	f_a.health_comp.wounds.clear()
	f_a.person_profile.age = 20
	f_a.affinity = 0
	vm.wanted_level = 0
	vm.bounty_gold = 0
	player.inventory.gold = gold_r1 + 500
	wc_speed.current_day = day_r1 + 9
	f_a.begin_live_fight(f_b)
	f_b.begin_live_fight(f_a)
	vm._live_fights.append({"a": f_a, "b": f_b, "res": {}, "elapsed": 0.0, "guard": null})
	vm._fight_scan_timer = 999.0 # Evita que el roce entre estos enemigos cambie los datos justo tras cargar
	assert(gm.load_game(save_path), "R1: Load must succeed")
	await process_frame
	var r1a = vm._find_npc_by_name("Thoran")
	var pe_r1: Dictionary = vm.social_director.get_pair_entry(key_a, key_b)
	assert(int(wc_speed.current_day) == day_r1, "R1: Day must be restored")
	assert(int(pe_r1["affinity"]) == -40 and int(pe_r1["tension"]) == 33 and int(pe_r1["enmity_days"]) == 7 and int(pe_r1["fights_count"]) == 1, "R1: Pair metrics must survive the file")
	assert(int(vm.social_director.player_influence_day) == 77 and int(vm.social_director.last_drama_day) == 55, "R1: Director state must be restored")
	assert(r1a.get_relationship_with_npc(key_b) == -44, "R1: Relationships must be restored")
	assert(r1a.affinity == 23 and int(r1a.person_profile.age) == 51, "R1: NPC data must be restored")
	assert(absf(r1a.health_comp.current_health - hp_r1) < 0.01 and r1a.health_comp.wounds.size() == wounds_r1, "R1: Health and wounds must be restored")
	assert(int(vm.wanted_level) == 2 and int(vm.bounty_gold) == 40, "R1: Crime state must be restored")
	assert(int(player.inventory.gold) == gold_r1, "R1: Player gold must be restored")
	assert(vm.get_news_known_by(g_c).size() == 1, "R1: Gossip knowledge must survive the file")
	assert(vm._live_fights.is_empty() and not r1a.is_in_live_fight(), "R1: A live fight must not survive loading")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("R1 save/load round trip OK")

	# Test #34 (M1): Las enemistades y los rumores dan móvil en una investigación
	var m1_v = vm._find_npc_by_name("Bram")
	var m1_s = vm._find_npc_by_name("Sora")
	var m1_x = null
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n != r1a and n != m1_v and n != m1_s and not n.is_dead:
			m1_x = n
			break
	vm.social_event_log.clear()
	var m1_ev: Dictionary = vm.record_social_event("breakup", m1_x, m1_v, "Rompieron")
	m1_ev["known_by"][m1_s.get_person_key()] = true
	var m1_case: Dictionary = vm._build_investigation_case_dict(m1_v, m1_v.global_position, "Cuchillo", "", 5, false)
	var m1_sus: Dictionary = m1_case["suspects"]
	assert(bool(m1_sus["Thoran"].get("motive_known", false)) and int(m1_sus["Thoran"]["motive_pts"]) == 10, "M1: A past fight with the victim is a known motive")
	assert(not bool(m1_sus[m1_x.npc_name].get("motive_known", false)), "M1: A private breakup is not known before interviews")
	vm._evaluate_npc_interview(r1a, m1_s, m1_sus, m1_case["clues_log"], m1_case)
	assert(int(m1_sus[m1_x.npc_name].get("motive_pts", 0)) == 8, "M1: A witness who knows the rumor reveals the motive")
	print("M1 social motives OK")

	print("ALL RIMWORLD MEDICAL, FOOTPRINTS, 3-PHASE CORPSE REPORT, MULTI-CORPSE FIX, RPG INTERROGATION, PUBLIC TRIAL, DYNAMIC RELATIONSHIPS, MISSING FAMILY SEARCH, SOCIAL GLOSSARY & UNCONSCIOUS REACTION TESTS PASSED!")
	quit(0)
