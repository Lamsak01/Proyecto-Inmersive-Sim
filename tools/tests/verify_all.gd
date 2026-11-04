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
	assert(not smith_npc.is_unconscious_on_ground() and bram2_npc._unconscious_react_phase == 2 and smith_npc.get_relationship_with_npc("Bram") >= 53 and bram2_npc.get_relationship_with_npc("Thoran") >= 48, "After 4s of friend rescue, Bram must wake Thoran up (U2: +8 for the rescued, +3 for the rescuer) and advance to Phase 2 (report attack to police)!")

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
	var keep_pa: Array[String] = f_a.person_profile.personality.duplicate()
	var keep_pb: Array[String] = f_b.person_profile.personality.duplicate()
	f_a.person_profile.personality.assign(["Curioso"]) # Carácter neutro: el multiplicador por rasgos se prueba en #42
	f_b.person_profile.personality.assign(["Curioso"])
	vm._scan_rival_friction()
	vm._scan_rival_friction()
	var tension4: int = int(sd4.get_pair_entry(f_a.get_person_key(), f_b.get_person_key()).get("tension", 0))
	assert(tension4 >= 2 and tension4 <= 4, "B4.2: Enemies crossing paths gain tension once per day")
	assert(int(sd4.get_pair_entry(f_a.get_person_key(), f_b.get_person_key()).get("enmity_days", 0)) == 11, "B4.2: Crossing paths adds one enmity day")
	f_a.person_profile.personality.assign(keep_pa)
	f_b.person_profile.personality.assign(keep_pb)
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
	assert(str(diag51["opinion_0"]["text"]).contains("No lo soporto") or str(diag51["opinion_0"]["text"]).contains("No la soporto"), "B5.1/U5: Opinion must describe their own real feeling")
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
	assert(sd4.get_spark(m_a.get_person_key(), key54) >= 6 and sd4.get_spark(key54, m_a.get_person_key()) == 0 and str(pe54.get("stage", "none")) == "none", "B5.4/U2: Matchmaking sparks only the listener, without forcing a romance stage")
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

	# Test #35 (Q1): Registro de misiones con panel propio que sobrevive al guardado
	var qm = root.get_node("/root/QuestManager")
	qm.clear_all()
	var q1_id: String = qm.add_quest({"title": "Prueba", "giver_name": "Sora", "description": "Algo"})
	var q1_id2: String = qm.add_quest({"title": "Otra"})
	qm.complete_quest(q1_id, "Hecho")
	assert(not qm.fail_quest(q1_id), "Q1: A finished quest cannot change state again")
	var q1_saved: Dictionary = JSON.parse_string(JSON.stringify(qm.to_save_dict()))
	qm.clear_all()
	qm.from_save_dict(q1_saved)
	assert(str(qm.get_quest(q1_id)["status"]) == "completed" and qm.get_active_quests("side").size() == 1, "Q1: Quests survive a save")
	assert(str(qm.add_quest({"title": "Nueva"})) != q1_id2, "Q1: New ids never reuse saved ones")
	var q1_ui = root.find_child("QuestLogUI", true, false)
	assert(q1_ui != null, "Q1: Quest panel exists in the UI")
	q1_ui.open_panel()
	assert(q1_ui._shown_ids.size() == 3, "Q1: Panel lists side quests")
	q1_ui.close_panel()
	qm.clear_all()
	print("Q1 quest log OK")

	# Test #36 (Q2): Un enemistado pide ayuda en persona; se acepta, se cumple y se cobra hablando con él
	var vq = load("res://scripts/systems/VillageQuests.gd")
	var sd_q = vm.social_director
	var k_th: String = r1a.get_person_key()
	var k_br: String = m1_v.get_person_key()
	vq.on_day_passed(vm, 1.0)
	assert(qm.offers.size() >= 1 and qm.offers.size() <= vq.MAX_OPEN_SOCIAL, "Q2: Long enmities produce a few offers, capped")
	assert(r1a.get_node_or_null("QuestMarker") == null or r1a.get_node("QuestMarker").visible == qm.offers.has(k_th), "Q2: Marker follows offers")
	qm.clear_all()
	qm.set_offer(k_th, {"type": "peace", "giver_name": "Thoran", "target_key": k_br, "target_name": "Bram", "day_offered": int(wc_speed.current_day)})
	assert(r1a.get_node("QuestMarker").visible, "Q2: Giver shows ❗")
	assert(str(r1a._inject_character_lore_into_dialogue(r1a._build_dialogue())).contains("quest_accept"), "Q2: Giver offers the quest in dialogue")
	r1a.on_dialogue_action("quest_accept")
	assert(qm.get_active_quests("side").size() == 1 and not r1a.get_node("QuestMarker").visible, "Q2: Accepting moves it to the quest log")
	m1_v.npc_relationships[k_th] = -40
	sd_q.dials["gossip_min_chance"] = 1.0
	sd_q.dials["gossip_max_chance"] = 1.0
	var q2_tries: int = 0
	while not vq.is_quest_done(vm, qm.get_active_quest_by_giver(k_th)) and q2_tries < 10:
		sd_q.player_influence_day = -1
		m1_v.on_dialogue_action("social_gossip:peace:" + k_th)
		q2_tries += 1
	assert(q2_tries >= 2 and q2_tries < 10, "Q2: Peace takes more than one mediation")
	var q_base = load("res://scripts/systems/quests/QuestType.gd")
	var gold_q2: int = int(player.inventory.gold)
	r1a.on_dialogue_action("quest_turn_in")
	assert(int(player.inventory.gold) == gold_q2 + q_base.reward_gold(r1a, 30) and qm.get_quests("side", "completed").size() == 1, "Q2: Turning in pays and completes")
	qm.giver_cooldowns.clear()
	qm.set_offer(k_th, {"type": "slander", "giver_name": "Thoran", "target_key": k_br, "target_name": "Bram", "day_offered": int(wc_speed.current_day)})
	r1a.on_dialogue_action("quest_accept")
	sd_q.player_influence_day = -1
	m1_s.on_dialogue_action("social_gossip:bad:" + k_br)
	sd_q.player_influence_day = -1
	m1_s.on_dialogue_action("social_gossip:bad:" + k_br)
	assert(not vq.is_quest_done(vm, qm.get_active_quest_by_giver(k_th)), "Q2: Slander needs different listeners")
	sd_q.player_influence_day = -1
	m1_x.on_dialogue_action("social_gossip:bad:" + k_br)
	assert(vq.is_quest_done(vm, qm.get_active_quest_by_giver(k_th)), "Q2: Two listeners complete the slander")
	m1_v.is_dead = true
	vq.check_failures(vm)
	assert(qm.get_quests("side", "failed").size() == 1, "Q2: A quest fails if its target dies")
	m1_v.is_dead = false
	sd_q.dials["gossip_min_chance"] = 0.15
	sd_q.dials["gossip_max_chance"] = 0.90
	qm.clear_all()
	print("Q2 social quests OK")

	# Test #37 (Q3): Justicia por un asesinato (se resuelve con el veredicto) y averiguar qué piensa alguien
	vq.on_murder_case_opened(vm, m1_v, 1.0)
	assert(qm.offers.size() == 1 and str(qm.offers.values()[0]["type"]) == "justice", "Q3: Someone close to the victim asks for justice")
	vq.on_murder_case_opened(vm, m1_v, 1.0)
	assert(qm.offers.size() == 1, "Q3: Only one justice offer per victim")
	var j_giver = vm._get_npcs_by_person_key()[qm.offers.keys()[0]]
	j_giver.on_dialogue_action("quest_accept")
	assert(not vq.is_quest_done(vm, qm.get_active_quest_by_giver(j_giver.get_person_key())), "Q3: Justice waits for the verdict")
	vm._mark_morgue_case_resolved("Bram", "Sora (Arrestado por el Comisario Vane: 60%)")
	var gold_q3: int = int(player.inventory.gold)
	j_giver.on_dialogue_action("quest_turn_in")
	assert(int(player.inventory.gold) == gold_q3 + q_base.reward_gold(j_giver, 40), "Q3: A verdict lets you collect the justice reward")
	qm.clear_all()
	sd_q.get_pair_entry(k_th, m1_s.get_person_key())["spark"] = 20
	sd_q.add_spark_one_way(m1_s.get_person_key(), k_th, -20) # U3: Thoran está ilusionado; Sora no siente nada por él
	qm.set_offer(k_th, {"type": "opinion", "giver_name": "Thoran", "target_key": m1_s.get_person_key(), "target_name": "Sora", "day_offered": int(wc_speed.current_day)})
	r1a.on_dialogue_action("quest_accept")
	m1_s.affinity = 10
	m1_s.npc_relationships[k_th] = -30
	assert(str(m1_s._inject_character_lore_into_dialogue(m1_s._build_dialogue())).contains("quest_opinion_seen:" + k_th), "Q3: The asked neighbor appears in the opinions menu")
	m1_s.on_dialogue_action("quest_opinion_seen:" + k_th)
	r1a.on_dialogue_action("quest_turn_in:truth")
	assert(qm.get_quests("side", "completed").size() == 1 and sd_q.get_spark(k_th, m1_s.get_person_key()) == 14, "Q3/U3: A hard truth cools the crush, never creates a couple")
	qm.clear_all()
	print("Q3 justice & crush quests OK")

	# Test #38 (Q3): Un vecino calumnia; si le llega al afectado de segunda mano, se sigue la pista hasta el origen
	vm.social_event_log.clear()
	r1a.person_profile.personality.clear()
	r1a.person_profile.personality.append_array(["Rencoroso", "Valiente", "Trabajador"])
	r1a.npc_relationships[k_br] = -90
	var r_ev: Dictionary = vm.try_npc_slander(r1a, m1_s, 1.0)
	assert(str(r_ev.get("type", "")) == "npc_slander" and str(r_ev["target_id"]) == k_br and not r_ev["known_by"].has(k_br), "Q3: A spiteful neighbor badmouths the rival behind their back")
	vm.spread_gossip(m1_s, m1_x)
	var br_th_before: int = m1_v.get_relationship_with_npc(k_th)
	vm.spread_gossip(m1_x, m1_v)
	assert(m1_v.get_relationship_with_npc(k_th) == br_th_before, "Q3: Second-hand slander does not reveal its author")
	assert(not vm.gossip_text(r_ev).contains("Thoran") and not str(m1_x._inject_character_lore_into_dialogue(m1_x._build_dialogue()).get("npc_news", {})).contains("Thoran"), "Q3: Retold slander hides who started it")
	if not qm.offers.has(k_br):
		vq.on_rumor_reached_target(vm, r_ev, m1_x, m1_v, 1.0)
	assert(str(qm.offers[k_br]["type"]) == "rumor", "Q3: The victim of the rumor asks for help")
	m1_v.on_dialogue_action("quest_accept")
	for asked_npc in [m1_x, m1_s, r1a]:
		asked_npc.affinity = 10
		assert(str(asked_npc._inject_character_lore_into_dialogue(asked_npc._build_dialogue())).contains("quest_rumor_ask"), "Q3: Those who know the rumor can be asked")
		asked_npc.on_dialogue_action("quest_rumor_ask:" + str(qm.get_active_quest_by_giver(k_br)["id"]))
	var r_q: Dictionary = qm.get_active_quest_by_giver(k_br)
	assert(str(r_q["data"]["asked"][m1_x.get_person_key()]) == m1_s.get_person_key() and str(r_q["data"]["asked"][k_th]) == "self", "Q3: The chain leads back to the origin")
	var gold_r: int = int(player.inventory.gold)
	m1_v.on_dialogue_action("quest_turn_in:accuse:" + k_th)
	assert(int(player.inventory.gold) == gold_r + q_base.reward_gold(m1_v, 25) and m1_v.get_relationship_with_npc(k_th) <= br_th_before - 15, "Q3: Naming the culprit pays and turns the victim against them")
	qm.clear_all()
	print("Q3 rumor quest OK")

	# Test #39 (Q4): Catálogo de tipos de misión: ids únicos, textos completos y todos con su archivo
	var q_reg = load("res://scripts/systems/quests/QuestRegistry.gd")
	assert(q_reg.all_types().size() == q_reg.TYPE_SCRIPTS.size(), "Q4: Every registered quest type loads with a unique id")
	for q_t in q_reg.all_types():
		var q_tx: Dictionary = q_t.texts({"target_name": "X", "giver_name": "Y"})
		assert(str(q_tx.get("title", "")) != "" and str(q_tx.get("ask", "")) != "" and str(q_tx.get("desc", "")) != "", "Q4: Quest type %s needs title, ask and desc" % q_t.id)
		assert(q_t.trigger in ["daily", "event"], "Q4: Quest type %s has a valid trigger" % q_t.id)
	print("Q4 quest catalog OK")

	# Test #40 (T1): Los rasgos dan tendencias; calumnia más quien tiene más malicia y nunca quien no tiene
	var t_cat = load("res://scripts/data/TraitCatalog.gd")
	var pp_script = load("res://scripts/data/PersonProfile.gd")
	for tr_id in t_cat.TRAITS.keys():
		assert(t_cat.describe(tr_id) != "" and not (t_cat.TRAITS[tr_id]["tend"] as Dictionary).is_empty(), "T1: Trait %s needs a description and an effect" % tr_id)
	var vsl = load("res://scripts/systems/VillageSocialLife.gd")
	var t_chances: Array[float] = []
	for t_set in [["Rencoroso", "Celoso", "Chismoso"], ["Rencoroso", "Trabajador", "Curioso"], ["Bondadoso", "Leal", "Orgulloso"]]:
		m1_s.person_profile.personality.clear()
		m1_s.person_profile.personality.append_array(t_set)
		t_chances.append(vsl.npc_slander_chance(m1_s))
	assert(t_chances[0] > t_chances[1] and t_chances[1] > 0.0 and t_chances[2] == 0.0, "T1: Slander chance follows malice: %s" % str(t_chances))
	print("T1 trait tendencies OK")

	# Test #41 (T3): Los rasgos empiezan ocultos y se descubren por confianza, historia, rumores y viendo actuar
	m1_s.person_profile.personality.clear()
	m1_s.person_profile.personality.append_array(["Rencoroso", "Curioso", "Trabajador"])
	m1_s.known_traits.clear()
	m1_s.trait_trust_tier = 0
	m1_s.trait_lore_done = false
	m1_s.affinity = 0
	assert(m1_s.get_known_traits_text() == "❓, ❓, ❓", "T3: Traits start hidden")
	m1_s.modify_affinity(41)
	assert(m1_s.known_traits.size() == 2, "T3: Reaching trust 20 and 40 reveals two traits")
	m1_s.modify_affinity(1)
	assert(m1_s.known_traits.size() == 2, "T3: The same trust level never reveals twice")
	m1_s.known_traits.clear()
	m1_s.on_dialogue_action("trait_lore")
	m1_s.on_dialogue_action("trait_lore")
	assert(m1_s.known_traits.size() == 1, "T3: Personal story reveals one trait, once")
	r1a.affinity = 50
	r1a.npc_relationships[m1_s.get_person_key()] = 10 # Sin enemistad: dice la verdad
	m1_s.rumored_traits.clear()
	r1a.on_dialogue_action("quest_opinion_seen:" + m1_s.get_person_key())
	assert(m1_s.known_traits.size() == 1 and m1_s.rumored_traits.size() == 1 and str(m1_s.rumored_traits.keys()[0]) in m1_s.person_profile.personality, "T3/T2b: A trusting neighbor tells you a true trait, kept as hearsay")
	assert(m1_s.get_known_traits_text().contains("(según %s)" % r1a.npc_name), "T2b: Hearsay shows who said it")
	var t_disc = load("res://scripts/systems/TraitDiscovery.gd")
	var heard_t: String = str(m1_s.rumored_traits.keys()[0])
	t_disc.reveal(m1_s, heard_t, "test")
	assert(m1_s.rumored_traits.is_empty(), "T2b: Confirming a rumored trait clears the rumor")
	player.global_position = m1_s.global_position + Vector2(40, 0)
	m1_s.known_traits.clear()
	m1_s.npc_relationships[k_br] = -80
	vm.try_npc_slander(m1_s, m1_x, 1.0)
	assert(m1_s.known_traits == ["Rencoroso"], "T3: Hearing them slander reveals their spiteful trait")
	var t3_saved: Dictionary = m1_s.to_save_dict()
	m1_s.known_traits.clear()
	m1_s.from_save_dict(t3_saved)
	assert(m1_s.known_traits == ["Rencoroso"] and m1_s.trait_lore_done, "T3: Discovered traits survive saving")
	print("T3 trait discovery OK")

	# Test #42 (T4): Las tendencias llegan a peleas, pagos y a qué misión pide cada uno
	var sd_t4 = vm.social_director
	var prof_t4 = pp_script.new()
	prof_t4.personality.append_array(["Valiente", "Orgulloso", "Trabajador"])
	var prof_t4b = pp_script.new()
	prof_t4b.personality.append_array(["Pacífico", "Bondadoso", "Paciente"])
	assert(sd_t4.compute_fight_power(prof_t4, 0, 1.0) > sd_t4.compute_fight_power(prof_t4b, 0, 1.0), "T4: Aggressive neighbors hit harder than peaceful ones")
	m1_s.person_profile.personality.clear()
	m1_s.person_profile.personality.append_array(["Bondadoso", "Leal", "Alegre"])
	assert(q_base.reward_gold(m1_s, 40) > 40, "T4: Generous neighbors pay more")
	assert(vq.pick_offer_type(vm, r1a, m1_v) == "slander", "T4: A spiteful neighbor asks to slander the rival")
	m1_x.person_profile.personality.clear()
	m1_x.person_profile.personality.append_array(["Frío", "Desconfiado", "Noctámbulo"])
	m1_s.person_profile.personality.append("Trabajador")
	assert(m1_s.get_social_cooldown_mult() < 1.0 and m1_x.get_social_cooldown_mult() > 1.0, "T4: Sociable neighbors chat more often than cold ones")
	assert(m1_s.get_diligence_mult() > 1.0 and m1_x.get_diligence_mult() == 1.0, "T4: Hard workers work faster")
	print("T4 tendencies connected OK")

	# Test #43: Guardar en archivo y cargar conserva misiones, ofertas, esperas y rasgos descubiertos
	var save_q: String = "user://test_roundtrip_quests.json"
	qm.clear_all()
	qm.set_offer(k_br, {"type": "peace", "giver_name": "Bram", "target_key": k_th, "target_name": "Thoran", "day_offered": int(wc_speed.current_day)})
	qm.set_offer(k_th, {"type": "slander", "giver_name": "Thoran", "target_key": k_br, "target_name": "Bram", "day_offered": int(wc_speed.current_day)})
	r1a.on_dialogue_action("quest_accept")
	var q_act_id: String = str(qm.get_active_quest_by_giver(k_th)["id"])
	qm.get_quest(q_act_id)["data"]["slandered_to"] = [m1_s.get_person_key()]
	qm.giver_cooldowns[m1_x.get_person_key()] = 99
	r1a.known_traits.assign(["Rencoroso"])
	r1a.trait_trust_tier = 2
	assert(gm.save_game(save_q), "Save must succeed")
	qm.clear_all()
	r1a.known_traits.clear()
	r1a.trait_trust_tier = 0
	assert(gm.load_game(save_q), "Load must succeed")
	await process_frame
	var r43 = vm._find_npc_by_name("Thoran")
	var q43: Dictionary = qm.get_quest(q_act_id)
	assert(str(q43.get("status", "")) == "active" and (q43["data"]["slandered_to"] as Array).size() == 1, "Active quest and its progress survive the file")
	assert(qm.offers.has(k_br) and str(qm.offers[k_br]["type"]) == "peace" and int(qm.giver_cooldowns.get(m1_x.get_person_key(), 0)) == 99, "Offers and cooldowns survive the file")
	assert(r43.known_traits == ["Rencoroso"] and r43.trait_trust_tier == 2, "Discovered traits survive the file")
	assert(r43.get_node_or_null("QuestMarker") == null or not r43.get_node("QuestMarker").visible, "Giver with an active quest shows no ❗ after loading")
	assert(vm._find_npc_by_name("Bram").get_node("QuestMarker").visible, "Pending offer shows ❗ after loading")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_q))
	qm.clear_all()
	print("Quests & traits save/load round trip OK")

	# Test #44: Si un luchador tiene que empezar una escolta, la pelea se corta al momento
	var esc_a = vm._find_npc_by_name("Thoran")
	var esc_b = vm._find_npc_by_name("Bram")
	esc_a.begin_live_fight(esc_b)
	esc_b.begin_live_fight(esc_a)
	vm._live_fights.append({"a": esc_a, "b": esc_b, "res": {}, "elapsed": 0.0, "guard": null})
	var prev_officer = vm.escorting_officer
	vm.escorting_officer = esc_a
	vm._update_live_fights(0.01)
	vm.escorting_officer = prev_officer
	assert(vm._live_fights.is_empty() and not esc_a.is_in_live_fight() and not esc_b.is_in_live_fight(), "An escort interrupts a live fight at once")
	print("Escort interrupts fight OK")

	# Test #45 (T2): 140 rasgos con ejes; 6 por vecino sin opuestos, como mucho 1 raro, nombres según género,
	# y las fichas de 3 rasgos (iniciales o de partidas viejas) se completan igual siempre
	assert(t_cat.TRAITS.size() == 140, "T2: 140 traits in the catalog")
	var t_rng := RandomNumberGenerator.new()
	var axis_n: Dictionary = {}
	for tr_id in t_cat.TRAITS.keys():
		var ax_id: String = t_cat.axis_of(tr_id)
		if ax_id != "":
			axis_n[ax_id] = int(axis_n.get(ax_id, 0)) + 1
	for ax_id in axis_n.keys():
		assert(int(axis_n[ax_id]) >= 2, "T2: Axis %s needs two ends" % ax_id)
	assert(t_cat.conflicts("Trabajador", "Holgazán") and not t_cat.conflicts("Trabajador", "Leal"), "T2: Axes block opposites only")
	for g_pair in [["Celoso", "Celosa"], ["Trabajador", "Trabajadora"], ["Leal", "Leal"], ["Seguro de sí", "Segura de sí"], ["Holgazán", "Holgazana"], ["Fanfarrón", "Fanfarrona"], ["Frío", "Fría"]]:
		assert(t_cat.display(g_pair[0], "F") == g_pair[1] and t_cat.display(g_pair[0], "M") == g_pair[0], "T2: Gendered name for %s" % g_pair[0])
	for bal_i in range(300):
		t_rng.seed = 1000 + bal_i
		var bal: Array[String] = t_cat.roll_balanced(t_rng, ["Rencoroso"])
		var rare_c: int = 0
		for ia in range(bal.size()):
			rare_c += 1 if t_cat.is_rare(bal[ia]) else 0
			for ib in range(ia + 1, bal.size()):
				assert(not t_cat.conflicts(bal[ia], bal[ib]), "T2: Balanced roll without opposites: %s" % str(bal))
		assert(bal.size() == 6 and "Rencoroso" in bal and rare_c <= 1, "T2: Six traits, keeps old, at most one rare: %s" % str(bal))
	var old_d: Dictionary = {"person_id": "t2_old", "personality": ["Valiente", "Desconfiado", "Rencoroso"]}
	var old_a = pp_script.from_dict(old_d)
	var old_b = pp_script.from_dict(old_d)
	assert(old_a.personality.size() == 6 and old_a.personality == old_b.personality and old_a.personality.slice(0, 3) == ["Valiente", "Desconfiado", "Rencoroso"], "T2: Old 3-trait profiles complete to 6 the same way")
	for roll_i in range(200):
		t_rng.seed = roll_i
		var rolled: Array[String] = t_cat.roll_traits(t_rng, 6, ["Rencoroso"])
		assert(rolled.size() == 6 and rolled[0] == "Rencoroso", "T2: Six traits, keeping the existing ones")
		for ia in range(rolled.size()):
			for ib in range(ia + 1, rolled.size()):
				assert(not t_cat.conflicts(rolled[ia], rolled[ib]), "T2: No opposite traits together: %s" % str(rolled))
	t_rng.seed = 7
	var roll_a: Array[String] = t_cat.roll_traits(t_rng, 6)
	t_rng.seed = 7
	assert(t_cat.roll_traits(t_rng, 6) == roll_a, "T2: Same seed, same traits")
	print("T2 trait roller OK")

	# Test #46 (T2b): un vecino malicioso enemistado puede inventarse un rasgo; queda «según X», se guarda y se desmiente al conocerle
	var liar = r1a
	liar.person_profile.personality.assign(["Mentiroso", "Rencoroso"])
	var lie_target = null
	for cand_t in vm._get_npcs_by_person_key().values():
		if cand_t != liar and not cand_t.is_dead and cand_t.person_profile != null:
			liar.npc_relationships[cand_t.get_person_key()] = -60
			if t_disc.would_lie_about(liar, cand_t):
				lie_target = cand_t
				break
	assert(lie_target != null, "T2b: Some enemy gets a made-up trait")
	lie_target.known_traits.clear()
	lie_target.rumored_traits.clear()
	assert(t_disc.hearsay_trait(liar, lie_target) == t_disc.hearsay_trait(liar, lie_target), "T2b: Always the same lie")
	assert(t_disc.hear_trait(liar, lie_target), "T2b: The liar tells you something")
	var fake_t: String = str(lie_target.rumored_traits.keys()[0])
	assert(not fake_t in lie_target.person_profile.personality and t_cat.tone_of(fake_t) == "h", "T2b: The made-up trait is a nasty one they do not have")
	liar.npc_relationships[lie_target.get_person_key()] = 20
	assert(not t_disc.would_lie_about(liar, lie_target), "T2b: No lies without enmity")
	var rt_save: Dictionary = lie_target.to_save_dict()
	lie_target.rumored_traits.clear()
	lie_target.from_save_dict(rt_save)
	assert(str(lie_target.rumored_traits.get(fake_t, "")) == liar.npc_name, "T2b: Rumors survive saving")
	for real_t in lie_target.person_profile.personality.duplicate():
		t_disc.reveal(lie_target, real_t, "test")
	assert(lie_target.rumored_traits.is_empty(), "T2b: Knowing them fully disproves the lie")
	print("T2b trait rumors OK")

	# Test #47 (U1): chispa y aprecio de cada uno; lo de siempre sigue siendo mutuo y las partidas lo guardan
	var sd_u = vm.social_director
	sd_u.add_spark_one_way("u1a", "u1b", 30)
	var pe_u: Dictionary = sd_u.get_pair_entry("u1a", "u1b")
	assert(sd_u.get_spark("u1a", "u1b") == 30 and sd_u.get_spark("u1b", "u1a") == 0 and int(pe_u["spark"]) == 0, "U1: One-sided spark; the shared one is the lower")
	sd_u._add_spark_capped(pe_u, 5, 900)
	assert(sd_u.get_spark("u1a", "u1b") == 35 and sd_u.get_spark("u1b", "u1a") == 5 and int(pe_u["spark"]) == 5, "U1: Old mutual gains reach both sides")
	var u_save: Dictionary = sd_u.to_save_dict()
	sd_u.from_save_dict(u_save)
	assert(sd_u.get_spark("u1a", "u1b") == 35 and sd_u.get_spark("u1b", "u1a") == 5, "U1: One-sided spark survives saving")
	sd_u.get_pair_entry("u1a", "u1b")["spark"] = 12
	assert(sd_u.get_spark("u1a", "u1b") == 12 and sd_u.get_spark("u1b", "u1a") == 12, "U1: Writing the old shared value sets both sides")
	var u_ka: String = r1a.get_person_key()
	var u_kb: String = m1_s.get_person_key()
	var u_rel_b: int = m1_s.get_relationship_with_npc(u_ka)
	var u_rel_a: int = r1a.get_relationship_with_npc(u_kb)
	r1a.modify_npc_relationship(m1_s, 15, "", true)
	assert(r1a.get_relationship_with_npc(u_kb) == clampi(u_rel_a + 15, -100, 100) and m1_s.get_relationship_with_npc(u_ka) == u_rel_b, "U1: One-way change leaves the other side alone")
	print("U1 one-sided relationships OK")

	# Test #48 (U2): un mismo suceso se vive distinto; manías de un solo lado; chispa según carácter; reciprocidad lenta
	var pp_u = load("res://scripts/data/PersonProfile.gd")
	var hon = pp_u.from_dict({"person_id": "u2h", "personality": ["Honrado", "Curioso", "Prudente", "Ordenado", "Familiar", "Serio"]})
	var cha = pp_u.from_dict({"person_id": "u2c", "personality": ["Chismoso", "Curioso", "Prudente", "Ordenado", "Familiar", "Bromista"]})
	assert(sd_u.side_delta(hon, cha, 10) + 5 < sd_u.side_delta(cha, hon, 10), "U2: The honest one is irritated by the gossip, not the other way round (%d vs %d)" % [sd_u.side_delta(hon, cha, 10), sd_u.side_delta(cha, hon, 10)])
	assert(sd_u.side_delta(hon, cha, -10) < sd_u.side_delta(cha, hon, -10), "U2: A bad moment hurts more who is irritated")
	var rom = pp_u.from_dict({"person_id": "u2r", "personality": ["Romántico", "Curioso", "Prudente", "Ordenado", "Familiar", "Serio"]})
	var cold = pp_u.from_dict({"person_id": "u2d", "personality": ["Desapegado", "Curioso", "Prudente", "Ordenado", "Familiar", "Serio"]})
	sd_u.get_pair_entry("u2r", "u2d")["spark"] = 0
	sd_u._apply_spark_bias("u2r", rom, "u2d", cold, sd_u._add_spark_capped(sd_u.get_pair_entry("u2r", "u2d"), 8, 901))
	assert(sd_u.get_spark("u2r", "u2d") > sd_u.get_spark("u2d", "u2r"), "U2: The romantic falls harder than the detached")
	var rc_a = r1a
	var rc_b = m1_s
	var rc_ka: String = rc_a.get_person_key()
	var rc_kb: String = rc_b.get_person_key()
	rc_a.npc_relationships[rc_kb] = 60
	rc_b.npc_relationships[rc_ka] = 0
	for rc_d in range(7):
		vsl.daily_reciprocity(vm)
	var rc_now: int = rc_b.get_relationship_with_npc(rc_ka)
	assert(rc_now > 0 and rc_now < 30 and rc_a.get_relationship_with_npc(rc_kb) == 60, "U2: Feelings slowly become mutual, without matching (%d)" % rc_now)
	print("U2 asymmetric feelings OK")

	# Test #49 (U3): quien está ilusionado sin ser correspondido se declara y le dicen que no; celos ante una nueva pareja
	var rj_a = r1a
	var rj_b = m1_s
	var rj_ka: String = rj_a.get_person_key()
	var rj_kb: String = rj_b.get_person_key()
	var rj_keep: Array = [str(rj_a.person_profile.romance_status), str(rj_b.person_profile.romance_status)]
	rj_a.person_profile.romance_status = "single"
	rj_b.person_profile.romance_status = "single"
	sd_u.pair_metrics.erase(sd_u.make_pair_key(rj_ka, rj_kb))
	var rj_pe: Dictionary = sd_u.get_pair_entry(rj_ka, rj_kb)
	sd_u.add_spark_one_way(rj_ka, rj_kb, 40)
	rj_pe["last_contact_day"] = 950
	sd_u.dials["rejection_daily_chance"] = 1.0
	var rj_res: Dictionary = sd_u.advance_live_romance_day(950, {rj_ka: rj_a.person_profile, rj_kb: rj_b.person_profile})
	assert((rj_res["rejections"] as Array).size() == 1 and str(rj_res["rejections"][0]["from"]) == rj_ka and sd_u.get_spark(rj_ka, rj_kb) == 25, "U3: A one-sided crush ends in a rejection")
	rj_res = sd_u.advance_live_romance_day(951, {rj_ka: rj_a.person_profile, rj_kb: rj_b.person_profile})
	assert((rj_res["rejections"] as Array).is_empty(), "U3: No second declaration right away")
	sd_u.dials["rejection_daily_chance"] = 0.25
	var rj_rel: int = rj_a.get_relationship_with_npc(rj_kb)
	vsl.on_rejection(vm, rj_a, rj_b)
	assert(rj_a.get_relationship_with_npc(rj_kb) == rj_rel - 5 and vm.get_recent_social_events(80, "rejection").size() >= 1, "U3: Rejection hurts and becomes news")
	var jz_c = null
	for jz_n in vm._get_npcs_by_person_key().values():
		if jz_n != rj_a and jz_n != rj_b and not jz_n.is_dead:
			jz_c = jz_n
			break
	var jz_rel: int = rj_a.get_relationship_with_npc(jz_c.get_person_key())
	vsl.on_new_couple_jealousy(vm, rj_b, jz_c) # rj_a sigue ilusionado (25 < 28): sin celos
	assert(rj_a.get_relationship_with_npc(jz_c.get_person_key()) == jz_rel, "U3: A faded crush brings no jealousy")
	sd_u.add_spark_one_way(rj_ka, rj_kb, 10)
	vsl.on_new_couple_jealousy(vm, rj_b, jz_c)
	assert(rj_a.get_relationship_with_npc(jz_c.get_person_key()) == clampi(jz_rel - 10, -100, 100), "U3: Jealous of the new partner")
	rj_a.person_profile.romance_status = rj_keep[0]
	rj_b.person_profile.romance_status = rj_keep[1]
	print("U3 rejection and jealousy OK")

	# Test #50 (U4): amistad desigual: excusa cuando solo uno aprecia al otro; frases de un solo lado
	var ex_a = r1a
	var ex_b = jz_c
	sd_u.pair_metrics.erase(sd_u.make_pair_key(ex_a.get_person_key(), ex_b.get_person_key()))
	ex_a.npc_relationships[ex_b.get_person_key()] = 60
	ex_b.npc_relationships[ex_a.get_person_key()] = 0
	assert(vsl.try_hangout_excuse(vm, ex_a, ex_b, 0.0), "U4: The one who barely cares makes an excuse")
	assert(not vsl.try_hangout_excuse(vm, ex_b, ex_a, 0.0), "U4: The one who cares does not")
	assert(not vsl.try_hangout_excuse(vm, ex_a, ex_b, 0.99), "U4: Not always")
	assert(vsl.feeling_phrase(70, ex_b).begins_with("es mi mejor amig") and vsl.feeling_phrase(0, ex_b) == "ni fu ni fa", "U4: One-sided feeling phrases")
	print("U4 uneven friendship OK")

	# Test #51 (U5): lo que siente cada uno empieza oculto, se descubre al preguntar y se guarda; partidas viejas lo ven todo
	ex_a.known_feelings.clear()
	ex_a.feelings_all_known = false
	if str(ex_a.person_profile.partner_id) != ex_b.get_person_key() and not (ex_a.family_id != "none" and ex_a.family_id == ex_b.family_id):
		assert(not ex_a.knows_feeling_toward(ex_b.get_person_key()), "U5: Feelings start hidden")
	ex_a.on_dialogue_action("quest_opinion_seen:" + ex_b.get_person_key())
	assert(ex_a.knows_feeling_toward(ex_b.get_person_key()), "U5: Asking their opinion reveals it")
	var kf_save: Dictionary = ex_a.to_save_dict()
	ex_a.known_feelings.clear()
	ex_a.from_save_dict(kf_save)
	assert(ex_a.get_person_key() != "" and ex_b.get_person_key() in ex_a.known_feelings and not ex_a.feelings_all_known, "U5: Known feelings survive saving")
	kf_save.erase("known_feelings")
	kf_save.erase("feelings_all_known") # Una partida de antes de U5 no tiene ninguno de los dos
	ex_a.from_save_dict(kf_save)
	assert(ex_a.feelings_all_known, "U5: Saves from before U5 keep everything visible")
	ex_a.feelings_all_known = false
	print("U5 hidden feelings OK")

	# Test #52 (U6): sin verse una semana, lo que sienten se apaga poco a poco; la chispa se enfría sin igualarse
	var cool_pe: Dictionary = sd_u.get_pair_entry(ex_a.get_person_key(), ex_b.get_person_key())
	cool_pe["last_contact_day"] = 900
	cool_pe["stage"] = "none"
	ex_a.npc_relationships[ex_b.get_person_key()] = 50
	ex_b.npc_relationships[ex_a.get_person_key()] = -40
	vsl.daily_distance_cooling(vm, 920)
	if not (ex_a.family_id != "none" and ex_a.family_id == ex_b.family_id):
		assert(ex_a.get_relationship_with_npc(ex_b.get_person_key()) == 48 and ex_b.get_relationship_with_npc(ex_a.get_person_key()) == -39, "U6: Distance cools both feelings")
	var cool_before: int = ex_a.get_relationship_with_npc(ex_b.get_person_key())
	cool_pe["last_contact_day"] = 919
	vsl.daily_distance_cooling(vm, 920)
	assert(ex_a.get_relationship_with_npc(ex_b.get_person_key()) == cool_before, "U6: Recent contact stops the cooling")
	sd_u.get_pair_entry("u6a", "u6b")
	sd_u.add_spark_one_way("u6a", "u6b", 30)
	sd_u.get_pair_entry("u6a", "u6b")["last_contact_day"] = 1
	sd_u.on_day_passed(50)
	assert(sd_u.get_spark("u6a", "u6b") == 29 and sd_u.get_spark("u6b", "u6a") == 0, "U6: Spark cools on each side without being equalized")
	print("U6 distance cooling OK")

	# Test #53 (C1-C4): la crónica apunta lo público, esconde lo secreto hasta que te enteras, guarda 160 y se guarda
	var vch = load("res://scripts/systems/VillageChronicle.gd")
	vm.chronicle.clear()
	var pub_ev: Dictionary = vm.record_social_event("couple", ex_a, ex_b, "C test pareja")
	assert(vm.chronicle.size() == 1 and bool(vm.chronicle[0]["known"]) and int(vm.chronicle[0]["ev_uid"]) == int(pub_ev["uid"]), "C1: Public events enter the chronicle as known")
	vch.on_social_event(vm, {"type": "npc_slander", "summary": "C test secreto", "uid": 990001})
	assert(not bool(vm.chronicle[1]["known"]), "C1: Secret events stay hidden from the player")
	assert(vch.visible_entries(vm, "all", false).size() == 1 and vch.visible_entries(vm, "all", true).size() == 2, "C2: Only known entries show outside debug mode")
	assert(vch.visible_entries(vm, "love", true).size() == 1 and vch.visible_entries(vm, "conflict", true).size() == 1, "C2: Category filters")
	assert(vch.line_text(vm.chronicle[1], true).contains("🔒"), "C2: Debug mode marks unknown lines")
	vch.learn_event(vm, 990001)
	assert(bool(vm.chronicle[1]["known"]), "C1: Learning about an event reveals it")
	vch.on_quest_changed(vm, {"id": "c_q1", "status": "completed", "title": "Prueba"})
	vch.on_quest_changed(vm, {"id": "c_q1", "status": "completed", "title": "Prueba"})
	assert(vm.chronicle.size() == 3 and str(vm.chronicle[2]["type"]) == "quest_done", "C3: A finished quest is written once")
	var ch_save: Dictionary = vm.get_economy_save_dict()
	vm.chronicle.clear()
	vm.load_economy_save_dict(ch_save)
	assert(vm.chronicle.size() == 3 and str(vm.chronicle[1]["text"]) == "C test secreto", "C1: The chronicle survives save and load")
	ch_save.erase("chronicle")
	vm.load_economy_save_dict(ch_save)
	assert(vm.chronicle.size() > 0 and str(vm.chronicle.back()["text"]) == "C test pareja", "C1: Old saves start from the social log")
	for ci in range(600):
		vch.add(vm, "fight", "C relleno %d" % ci, true)
	assert(vm.chronicle.size() == 500 and str(vm.chronicle.back()["text"]) == "C relleno 599", "C1: Keeps only the last 500 entries")
	vm.chronicle.clear()
	# Amistad: un salto de escalón se apunta una vez; quedarse cerca del borde no repite avisos
	vm.chronicle_tiers.clear()
	ex_a.npc_relationships[ex_b.get_person_key()] = 10
	vch.daily_friendship_scan(vm)
	assert(vm.chronicle.is_empty(), "C5: The first scan only sets the starting point")
	ex_a.npc_relationships[ex_b.get_person_key()] = 40
	vch.daily_friendship_scan(vm)
	var fr_n: int = vch.visible_entries(vm, "friends", true).size()
	assert(fr_n == 1 and str(vch.visible_entries(vm, "friends", true)[0]["text"]).contains(ex_a.npc_name), "C5: Becoming friends is written")
	ex_a.npc_relationships[ex_b.get_person_key()] = 33
	vch.daily_friendship_scan(vm)
	assert(vch.visible_entries(vm, "friends", true).size() == 1, "C5: Small dips near the edge are not written")
	ex_a.npc_relationships[ex_b.get_person_key()] = 20
	vch.daily_friendship_scan(vm)
	assert(vch.visible_entries(vm, "friends", true).size() == 2, "C5: Growing apart is written")
	vch.on_gossip(vm, {"type": "fight", "summary": "C test chisme", "uid": 990002}, ex_a, ex_b)
	assert(vch.visible_entries(vm, "gossip", true).size() == 1 and str(vm.chronicle.back()["text"]).contains("C test chisme"), "C5: Gossip is written")
	vm.chronicle_daily = true
	var daily_e: Dictionary = vch.add(vm, "friendship", "C test diario", false)
	vm.chronicle_daily = false
	assert(bool(daily_e.get("daily", false)) and vch.line_text(daily_e).begins_with("Durante el día"), "C5: Day-change entries show no fake midnight time")
	vm.chronicle.clear()
	print("C chronicle OK")

	# Test #54 (R1-R3): los chismes se olvidan y se deforman al contarlos; la crónica apunta la versión que te cuentan
	var gmem = load("res://scripts/systems/GossipMemory.gd")
	var r_others: Array = []
	for rn in get_nodes_in_group("village_npcs"):
		if rn != ex_a and rn != ex_b and not rn.is_dead:
			r_others.append(rn)
	var rg_c = r_others[0]
	var rg_d = r_others[1]
	var rg_ev: Dictionary = vm.record_social_event("fight", ex_a, ex_b, "%s y %s se pelearon" % [ex_a.npc_name, ex_b.npc_name])
	var rg_ak: String = ex_a.get_person_key()
	var rg_ck: String = rg_c.get_person_key()
	var rg_dk: String = rg_d.get_person_key()
	assert(gmem.knows(rg_ev, rg_ak) and gmem.strength(rg_ev, rg_ak) == 100.0, "R1: Protagonists remember fully")
	assert(vm.spread_gossip(ex_a, rg_c) == rg_ev and gmem.knows(rg_ev, rg_ck) and gmem.strength(rg_ev, rg_ck) == 70.0, "R1: Hearing it starts a weaker memory")
	rg_ev["mem"][rg_ck] = 1.0
	gmem.daily_decay(vm)
	assert(not gmem.knows(rg_ev, rg_ck) and gmem.knows(rg_ev, rg_ak), "R1: Weak memories are forgotten, protagonists keep theirs")
	assert(not rg_ev in vm.get_news_known_by(rg_c) and vm.spread_gossip(rg_c, rg_d) != rg_ev, "R1: Forgotten gossip is neither news nor retold")
	assert(vm.spread_gossip(ex_a, rg_c) == rg_ev and gmem.knows(rg_ev, rg_ck), "R1: Being told again brings it back")
	rg_ev["ver"][rg_ck] = {"swap_from": ex_a.npc_name, "swap_to": "Zeta", "exag": 1}
	var r_txt: String = vm.gossip_text(rg_ev, null, rg_ck)
	assert(r_txt.contains("Zeta") and not r_txt.contains(ex_a.npc_name) and r_txt.ends_with("corrió la sangre"), "R2: A distorted version changes who and exaggerates")
	assert(vm.gossip_text(rg_ev) == "%s y %s se pelearon" % [ex_a.npc_name, ex_b.npc_name], "R2: The truth is kept apart")
	(rg_ev["known_by"] as Dictionary).erase(rg_dk)
	assert(vm.spread_gossip(rg_c, rg_d) == rg_ev and str(gmem.version(rg_ev, rg_dk).get("swap_to", "")) == "Zeta", "R2: Errors spread from mouth to mouth")
	assert(gmem.distort_chance(rg_ev, ex_a) < gmem.distort_chance(rg_ev, rg_c) + 0.001, "R2: Protagonists distort less")
	vm.chronicle.clear()
	vch.learn_news_from(vm, rg_c)
	vch.learn_news_from(vm, rg_c)
	var rg_hs: Array = vch.visible_entries(vm, "gossip", true).filter(func(e): return str(e.get("type", "")) == "hearsay")
	assert(rg_hs.size() == 1 and str(rg_hs[0]["text"]).contains("Zeta") and str(rg_hs[0]["text"]).contains("[deformado]"), "R3: The chronicle keeps the distorted version you heard, once")
	vm.chronicle.clear()
	print("R gossip memory OK")

	# Test #55 (S1-S5): aventuras raras según la fidelidad, se descubren, corren como chisme, chantaje y el jugador
	var vsec = load("res://scripts/systems/VillageSecrets.gd")
	var tcat = load("res://scripts/data/TraitCatalog.gd")
	var s_pool: Array = []
	for sn in get_nodes_in_group("village_npcs"):
		if not sn.is_dead and sn.person_profile != null:
			s_pool.append(sn)
	var s_a = s_pool[0]
	var s_p = null
	var s_c = null
	var s_w = null
	var s_q = null
	for sn in s_pool:
		if sn == s_a:
			continue
		var fam_same: bool = s_a.family_id != "none" and s_a.family_id == sn.family_id
		if s_c == null and not fam_same:
			s_c = sn
		elif s_p == null:
			s_p = sn
		elif s_w == null:
			s_w = sn
		elif s_q == null:
			s_q = sn
	var s_keys: Dictionary = {}
	for sn in [s_a, s_p, s_c, s_w, s_q]:
		s_keys[sn] = {"partner": str(sn.person_profile.partner_id), "status": str(sn.person_profile.romance_status), "pers": sn.person_profile.personality.duplicate(), "gold": sn.personal_gold}
	var sak: String = s_a.get_person_key()
	var spk: String = s_p.get_person_key()
	var sck: String = s_c.get_person_key()
	var set_couple = func() -> void:
		s_a.person_profile.partner_id = spk
		s_a.person_profile.romance_status = "partnered"
		s_p.person_profile.partner_id = sak
		s_p.person_profile.romance_status = "partnered"
	set_couple.call()
	s_a.person_profile.personality.assign(["Fiel"])
	assert(vsec.temptation(s_a) == 0.0, "S1: Faithful people never cheat")
	s_a.person_profile.personality.assign(["Infiel"])
	var t_inf: float = vsec.temptation(s_a)
	s_a.person_profile.personality.assign([])
	assert(t_inf > vsec.temptation(s_a) and vsec.temptation(s_a) > 0.0, "S1: Unfaithful people are more tempted than others")
	s_a.person_profile.personality.assign(["Infiel"])
	vm.secrets.clear()
	sd_u.add_spark_one_way(sak, sck, 50)
	sd_u.add_spark_one_way(sck, sak, 30)
	sd_u.get_pair_entry(sak, sck)["last_contact_day"] = int(root.get_node("/root/WorldClock").current_day)
	var s_aff: Dictionary = {}
	for si in range(400):
		vsec.daily(vm)
		s_aff = vsec.active_affair_of(vm, sak)
		if not s_aff.is_empty():
			break
	assert(not s_aff.is_empty() and str(s_aff["b"]) == sck and str(s_aff["partner"]) == spk, "S1: With mutual spark an affair can start")
	assert(vm.chronicle.back()["type"] == "affair_start" and not bool(vm.chronicle.back()["known"]), "S1: The affair is a secret in the chronicle")
	# S2: alguien cerca los pilla
	s_w.global_position = s_a.global_position
	s_w.is_sleeping = false
	for si in range(40):
		vsec.on_meeting(vm, s_a, s_c)
		if (s_aff["known_by"] as Dictionary).has(s_w.get_person_key()):
			break
	var s_ev: Dictionary = vsec._gossip_event(vm, s_aff)
	assert(not s_ev.is_empty() and gmem.knows(s_ev, s_w.get_person_key()), "S2: A witness turns it into gossip")
	assert(vsec.keeps_quiet(s_ev, sak) and vsec.keeps_quiet(s_ev, sck) and not vsec.keeps_quiet(s_ev, s_w.get_person_key()), "S2: Lovers keep quiet")
	# S3: quien lo oye piensa peor del infiel; la pareja reacciona
	var q_before: int = s_q.get_relationship_with_npc(sak)
	(s_ev["known_by"] as Dictionary).erase(s_q.get_person_key())
	for gev in vm.social_event_log:
		if gev != s_ev and gev.has("known_by"):
			(gev["known_by"] as Dictionary)[s_q.get_person_key()] = true # Que solo le quede por oír la aventura
	assert(vm.spread_gossip(s_w, s_q) == s_ev and s_q.get_relationship_with_npc(sak) == q_before + vsec.HEARD_REL_CHEATER, "S3: Hearing it lowers their opinion of the cheater")
	var p_before: int = s_p.get_relationship_with_npc(sak)
	for gev in vm.social_event_log:
		if gev != s_ev and gev.has("known_by"):
			(gev["known_by"] as Dictionary)[spk] = true
	assert(vm.spread_gossip(s_w, s_p) == s_ev, "S3: The gossip reaches the partner")
	assert(s_p.get_relationship_with_npc(sak) <= p_before + vsec.PARTNER_REL_CHEATER and not bool(s_aff["active"]), "S3: The partner is hurt and the affair ends")
	# S4: chantaje entre vecinos (paga / se niega y lo cuenta)
	set_couple.call()
	var s_aff2: Dictionary = vsec.start_affair(vm, s_a, s_c)
	s_a.personal_gold = 40
	var w_gold: int = maxi(0, s_w.personal_gold)
	vsec.blackmail(vm, s_aff2, s_w, s_a, 0.0)
	assert(s_a.personal_gold == 20 and s_w.personal_gold == w_gold + 20 and bool(s_aff2["active"]), "S4: Paying the blackmailer keeps the secret")
	vsec.blackmail(vm, s_aff2, s_q, s_a, 0.99)
	assert(not bool(s_aff2["active"]), "S4: Refusing to pay gets it told to the partner")
	# S5: el jugador
	set_couple.call()
	var s_aff3: Dictionary = vsec.start_affair(vm, s_a, s_c)
	vsec.player_learns(vm, s_aff3, s_c.npc_name, "prueba")
	var s_diag: Dictionary = {}
	var s_ch: Array = [{"label": "salir"}]
	vsec.add_dialogue_choices(vm, s_a, s_diag, s_ch)
	assert(s_diag.has("secret_a_%d" % int(s_aff3["id"])), "S5: You can confront the cheater")
	var s_inv = load("res://scripts/systems/SimpleInventory.gd").new()
	var inv_g0: int = s_inv.gold
	s_a.personal_gold = 40
	vsec.on_player_action(vm, s_a, "secret_blackmail:%d" % int(s_aff3["id"]), s_inv, 0.0)
	assert(s_inv.gold == inv_g0 + 20 and s_a.personal_gold == 20, "S5: Blackmailing the cheater pays")
	s_diag.clear()
	vsec.add_dialogue_choices(vm, s_p, s_diag, s_ch)
	assert(s_diag.has("secret_p_%d" % int(s_aff3["id"])), "S5: You can tell the partner")
	s_p.npc_relationships[sak] = 0 # Las pruebas anteriores la dejaron en el mínimo
	var p_before2: int = s_p.get_relationship_with_npc(sak)
	vsec.on_player_action(vm, s_p, "secret_tell:%d" % int(s_aff3["id"]), s_inv, 0.0)
	assert(not bool(s_aff3["active"]) and s_p.get_relationship_with_npc(sak) < p_before2, "S5: Telling the partner ends the affair")
	set_couple.call()
	var s_aff4: Dictionary = vsec.start_affair(vm, s_a, s_c)
	vsec.player_learns(vm, s_aff4, "Nadie", "rumor deformado")
	var g_wrong: int = s_inv.gold
	vsec.on_player_action(vm, s_a, "secret_blackmail:%d" % int(s_aff4["id"]), s_inv, 0.0)
	assert(s_inv.gold == g_wrong, "S5: A false rumor about the lover gets denied")
	var sec_save: Dictionary = vm.get_economy_save_dict()
	var sec_n: int = vm.secrets.size()
	vm.secrets.clear()
	vm.load_economy_save_dict(sec_save)
	assert(vm.secrets.size() == sec_n and int(vm.secret_uid) == int(s_aff4["id"]), "S: Secrets survive save and load")
	if s_inv is Node:
		s_inv.free()
	vm.secrets.clear()
	for sn in s_keys.keys():
		sn.person_profile.partner_id = s_keys[sn]["partner"]
		sn.person_profile.romance_status = s_keys[sn]["status"]
		sn.person_profile.personality.assign(s_keys[sn]["pers"])
		sn.personal_gold = s_keys[sn]["gold"]
	print("S secrets OK")

	# Test #56 (D1-D5): deseos propios — venganza, contra el jugador, ambición abierta y planes de asesinato
	var vdes = load("res://scripts/systems/VillageDesires.gd")
	var wclock = root.get_node("/root/WorldClock")
	var d_today: int = int(wclock.current_day)
	var d_bykey: Dictionary = vm._get_npcs_by_person_key()
	var d_shop = null
	for rk in vm.trade_npcs.keys():
		var tn = vm.trade_npcs[rk]
		if is_instance_valid(tn) and not tn.is_dead and vm.shop_businesses.has(int(rk)):
			d_shop = tn
			break
	var d_live: Array = []
	for dn in get_nodes_in_group("village_npcs"):
		if not dn.is_dead and dn != d_shop and dn.person_profile != null:
			d_live.append(dn)
	var d_h = d_live[0]
	var d_x = d_live[1]
	var d_v = d_live[2]
	var d_y = d_live[3]
	var d_hk: String = d_h.get_person_key()
	var d_saved_pers: Array = d_h.person_profile.personality.duplicate()
	d_h.person_profile.personality.assign([])
	d_h.affinity = 20
	vm.desires.clear()
	var d_tk: String = d_v.get_person_key()
	d_h.npc_relationships[d_tk] = -70
	var d_new: Dictionary = {}
	for di in range(300):
		vdes.daily(vm)
		d_new = vdes.active_of(vm, d_hk)
		if not d_new.is_empty():
			break
	assert(not d_new.is_empty() and str(d_new["type"]) == "revenge", "D2: Strong hatred can turn into a revenge plan")
	vm.desires.clear()
	var d_rev: Dictionary = vdes.create(vm, "revenge", d_h, d_tk, d_v.npc_name, "prueba", false)
	assert(not vdes.would_tell(d_h, d_rev), "D1: A secret desire is not told to someone they barely like")
	d_h.affinity = 60
	assert(vdes.would_tell(d_h, d_rev), "D1: With enough affinity they tell you")
	vdes.on_player_action(vm, d_h, "desire_ask")
	assert(bool(d_rev["player_knows"]), "D1: Asking reveals it")
	d_rev["next_day"] = 0
	vdes._advance(vm, d_rev, d_bykey, d_today)
	assert(str(vm.social_event_log.back()["type"]) == "npc_slander" and str(vm.social_event_log.back()["actor_id"]) == d_hk, "D2: The first step is badmouthing")
	d_h.npc_relationships[d_tk] = 0
	vdes._advance(vm, d_rev, d_bykey, d_today)
	assert(not bool(d_rev["active"]) and str(d_rev["outcome"]) == "reconciled", "D2: Revenge ends if the hatred fades")
	if d_shop != null:
		assert(vdes._sabotage(vm, d_h, d_shop) and int(vm.shop_businesses[int(d_shop.trade_role)]["sabotaged_days"]) > 0, "D2: Revenge can sabotage a business")
		vm.shop_businesses[int(d_shop.trade_role)]["sabotaged_days"] = 0
	var d_amb: Dictionary = vdes.create(vm, "ambition", d_x, d_tk, d_v.npc_name, "quiere prosperar", true)
	d_x.affinity = 15
	assert(vdes.would_tell(d_x, d_amb), "D3: Open desires are told easily")
	vdes.daily(vm)
	var d_amb_ev: Dictionary = vdes._rumor_event(vm, d_amb)
	assert(not d_amb_ev.is_empty() and gmem.knows(d_amb_ev, d_x.get_person_key()), "D3: Open desires become gossip told by the holder")
	vdes.finish(vm, d_amb, "satisfied")
	# D4: contra el jugador
	vm.desires.clear()
	var d_ap: Dictionary = vdes.create(vm, "against_player", d_y, "player", "el forastero", "odio", false)
	d_ap["step"] = 2
	vdes._player_step(vm, d_ap, d_y)
	var d_diag: Dictionary = {"start": {"text": "Hola", "choices": [{"label": "Comprar pan", "action": "buy:bread:2"}, {"label": "Salir", "next": "END"}]}}
	vdes.filter_dialogue(vm, d_y, d_diag)
	assert((d_diag["start"]["choices"] as Array).size() == 1, "D4: Someone who hates you refuses to sell")
	var d_bounty: int = vm.bounty_gold
	var d_crimes: Array = vm.crime_history.duplicate()
	vm.crime_history.clear()
	vm.crime_history.append("prueba")
	vdes.report_player(vm, d_y)
	assert(vm.bounty_gold == d_bounty + vdes.REPORT_BOUNTY_TRUE, "D4: They report your real crimes")
	vm.bounty_gold = d_bounty
	vm.crime_history.clear()
	vm.crime_history.append_array(d_crimes)
	vdes._player_rumor(vm, d_y, "player_badmouth", "prueba de mala fama")
	var d_bm: Dictionary = vm.social_event_log.back()
	for gev in vm.social_event_log:
		if gev != d_bm and gev.has("known_by"):
			(gev["known_by"] as Dictionary)[d_x.get_person_key()] = true
	var d_aff0: int = d_x.affinity
	assert(vm.spread_gossip(d_y, d_x) == d_bm and d_x.affinity == d_aff0 + vdes.PLAYER_BADMOUTH_AFF, "D4: Their badmouthing lowers others' opinion of you")
	vdes.finish(vm, d_ap, "satisfied")
	# D5: plan de asesinato (señales, aviso y crimen)
	var d_m2: Dictionary = vdes.create(vm, "murder", d_x, d_y.get_person_key(), d_y.npc_name, "", false)
	vdes.learn(vm, d_m2, d_h)
	var d_thr: Dictionary = vdes._rumor_event(vm, d_m2)
	assert(str(d_thr.get("type", "")) == "murder_threat" and vsec.keeps_quiet(d_thr, d_x.get_person_key()), "D5: Threats can be overheard; the plotter keeps quiet")
	d_m2["player_knows"] = true
	vdes.on_player_action(vm, d_y, "desire_warn:%d" % int(d_m2["id"]))
	assert(str(d_m2["outcome"]) == "foiled", "D5: Warning the victim stops the plan")
	var d_mur: Dictionary = vdes.create(vm, "murder", d_h, d_tk, d_v.npc_name, "", false)
	d_v.global_position = Vector2(-9000, -9000)
	assert(vdes.try_commit_murder(vm, d_mur, d_h, d_v) and d_v.is_dead and vdes.killer_of(vm, d_v.npc_name) == d_h.npc_name, "D5: The plan can end in murder")
	var d_case: Dictionary = load("res://scripts/systems/VillageJustice.gd")._build_investigation_case_dict(vm, d_v, d_v.global_position, "Puñalada", "", 5, false)
	assert(int(d_case["suspects"][d_h.npc_name]["score"]) >= 40, "D5: The investigation points at the real killer")
	var d_save: Dictionary = vm.get_economy_save_dict()
	var d_n: int = vm.desires.size()
	vm.desires.clear()
	vm.npc_murders.clear()
	vm.load_economy_save_dict(d_save)
	assert(vm.desires.size() == d_n and vdes.killer_of(vm, d_v.npc_name) == d_h.npc_name, "D: Desires and murders survive save and load")
	d_h.person_profile.personality.assign(d_saved_pers)
	vm.desires.clear()
	print("D desires OK")

	# Test #57 (G1-G6): fe del Alba, semana con fin de semana, Oficio del domingo, sacerdote, bandos y reputación por grupo
	var vfa = load("res://scripts/systems/VillageFaith.gd")
	var g_old_day: int = int(wclock.current_day)
	var g_old_hour: int = int(wclock.current_hour)
	wclock.current_day = 7
	assert(wclock.is_rite_day() and wclock.is_weekend() and wclock.get_weekday_name() == "Domingo", "G2: Day 7 is Sunday, the rite day")
	var g_priest = vfa.priest_of(vm)
	assert(g_priest != null, "G3: The chapel has a priest")
	var g_pr_pers: Array = g_priest.person_profile.personality.duplicate()
	g_priest.person_profile.personality.assign(["Escéptico"])
	vfa.ensure_priest_faith(g_priest)
	assert(vfa.faith_score(g_priest) >= vfa.FERVENT_MIN, "G3: A priest always has faith")
	var g_roles = load("res://scripts/enemies/VillageNPC.gd").TradeRole
	var g_live: Array = []
	for gn in get_nodes_in_group("village_npcs"):
		if not gn.is_dead and gn.person_profile != null and gn != g_priest and not (int(gn.trade_role) in [int(g_roles.SHERIFF), int(g_roles.GUARD), int(g_roles.TRAVELING_MERCHANT), int(g_roles.ROYAL_INVESTIGATOR)]):
			g_live.append(gn)
	var g_a = g_live[0]
	var g_b = g_live[1]
	var g_sk = g_live[2]
	var g_x = g_live[3]
	var g_saved: Array = [g_a.person_profile.personality.duplicate(), g_b.person_profile.personality.duplicate(), g_sk.person_profile.personality.duplicate()]
	g_a.person_profile.personality.assign(["Devoto"])
	g_b.person_profile.personality.assign(["Supersticioso"])
	g_sk.person_profile.personality.assign(["Escéptico"])
	assert(vfa.grade_of(g_a) == vfa.GRADE_FERVENT and vfa.grade_of(g_b) == vfa.GRADE_BELIEVER and vfa.grade_of(g_sk) == vfa.GRADE_SKEPTIC, "G1: Faith grade comes from traits")
	# G2: fin de semana con menos trabajo
	var g_w = null
	for gr in vm.trade_npcs.keys():
		var gt = vm.trade_npcs[gr]
		if is_instance_valid(gt) and not gt.is_dead:
			g_w = gt
			break
	if g_w != null:
		wclock.current_hour = 15
		if not g_w._is_morning_expedition_hours():
			assert(not g_w._is_mandatory_work_hours(), "G2: Craftsmen rest on Sunday")
			wclock.current_day = 6
			assert(not g_w._is_mandatory_work_hours(), "G2: On Saturday they only work in the morning")
			wclock.current_day = 3
			assert(g_w._is_mandatory_work_hours(), "G2: On weekdays they work as usual")
		wclock.current_day = 7
	# G2: el Oficio
	for gp in [g_a, g_b, g_sk, g_priest]:
		gp.clear_hangout()
		gp.leave_rite()
		gp.is_sleeping = false
		gp.current_activity = 0
		gp.need_energy = 80.0
		gp.need_hunger = 80.0
	vm.faith_state = {}
	wclock.current_hour = 9
	vfa.call_to_rite(vm)
	assert(g_a.rite_pos != Vector2.ZERO and g_priest.rite_pos != Vector2.ZERO and g_sk.rite_pos == Vector2.ZERO, "G2: Believers and the priest go to the rite; skeptics stay home")
	assert(g_a._get_social_target_pos() == g_a.rite_pos and not g_a._is_mandatory_work_hours(), "G2: They really walk to the chapel")
	g_b.leave_rite()
	g_b.global_position = Vector2(-9000, -8000)
	g_a.global_position = g_a.rite_pos
	g_priest.global_position = g_priest.rite_pos
	var g_pk: String = g_priest.get_person_key()
	g_a.npc_relationships[g_pk] = 0
	g_a.npc_relationships[g_b.get_person_key()] = 0
	g_a.npc_relationships[g_sk.get_person_key()] = 0
	g_priest.npc_relationships[g_sk.get_person_key()] = -100
	g_a.affinity = 0
	var g_pl = get_first_node_in_group("player")
	var g_pl_pos: Vector2 = Vector2.ZERO
	if g_pl != null:
		g_pl_pos = g_pl.global_position
		g_pl.global_position = vm._church_altar_pos
	var g_res: Dictionary = vfa.finish_rite(vm)
	assert(int(g_res["attendees"]) >= 2 and g_a.rite_pos == Vector2.ZERO, "G2: The rite ends and counts who came")
	assert(g_a.get_relationship_with_npc(g_pk) > 0, "G2: Attendees bond")
	assert(g_a.get_relationship_with_npc(g_b.get_person_key()) < 0, "G2: Fervent believers notice who missed the rite")
	assert(str(g_res["sermon"]) == g_sk.npc_name and g_a.get_relationship_with_npc(g_sk.get_person_key()) < 0, "G3: The priest's sermon turns attendees against his enemy")
	if g_pl != null:
		assert(bool(g_res["player"]) and g_a.affinity > 0 and vfa.rep_of(vm, "faith") > 0 and vfa.grade_known(vm, g_a), "G5: Going to the rite pleases believers and shows their faith")
		g_pl.global_position = g_pl_pos
	# G4: bandos
	vfa.refresh_bands(vm)
	var g_fam_found: bool = false
	for gband in vm.faith_bands:
		if str(gband["kind"]) == "family":
			g_fam_found = true
	assert(g_fam_found, "G4: Families are detected as bands")
	vm.faith_bands = [{"id": "gang:test", "kind": "gang", "name": "Prueba", "members": [g_a.get_person_key(), g_b.get_person_key(), g_sk.get_person_key()], "leader": ""}]
	assert(vfa.same_band(vm, g_a, g_b) and not vfa.same_band(vm, g_a, g_x), "G4: Band membership")
	g_a.npc_relationships[g_b.get_person_key()] = 60
	g_a.npc_relationships[g_x.get_person_key()] = 0
	vm.record_social_event("fight", g_x, g_b, "prueba de pelea de bando")
	assert(g_a.get_relationship_with_npc(g_x.get_person_key()) == vfa.BAND_DEFEND, "G4: A band takes the side of its member")
	var g_r0: int = vfa.rep_of(vm, "gang:test")
	g_b.modify_affinity(8)
	assert(vfa.rep_of(vm, "gang:test") > g_r0, "G5: Helping a member raises your standing with the band")
	# G6: diálogo con el sacerdote
	var g_diag: Dictionary = {"start": {"text": "Hola", "choices": [{"label": "Salir", "next": "END"}]}}
	vfa.add_dialogue_choices(vm, g_priest, g_diag, g_diag["start"]["choices"])
	assert(g_diag.has("faith_lore"), "G6: The priest talks about the faith")
	var g_inv = load("res://scripts/systems/SimpleInventory.gd").new()
	g_inv.gold = 50
	var g_rep0: int = vfa.rep_of(vm, "faith")
	vfa.on_player_action(vm, g_priest, "faith_donate", g_inv)
	assert(int(g_inv.gold) == 50 - vfa.DONATION_GOLD and vfa.rep_of(vm, "faith") > g_rep0, "G6: Donating raises your standing with believers")
	var g_paff: int = g_priest.affinity
	vfa.on_player_action(vm, g_priest, "faith_mock", g_inv)
	assert(g_priest.affinity < g_paff and vfa.rep_of(vm, "skeptics") > 0, "G6: Mocking the faith angers believers and pleases skeptics")
	if g_inv is Node:
		g_inv.free()
	var g_rep_saved: int = vfa.rep_of(vm, "faith")
	var g_save: Dictionary = vm.get_economy_save_dict()
	vm.faith_state = {}
	vm.load_economy_save_dict(g_save)
	assert(vfa.rep_of(vm, "faith") == g_rep_saved, "G: Group reputation survives save and load")
	g_a.person_profile.personality.assign(g_saved[0])
	g_b.person_profile.personality.assign(g_saved[1])
	g_sk.person_profile.personality.assign(g_saved[2])
	g_priest.person_profile.personality.assign(g_pr_pers)
	vm.faith_bands = []
	vm.faith_state = {}
	wclock.current_day = g_old_day
	wclock.current_hour = g_old_hour
	print("G groups and faith OK")

	# Test #58 (E1-E6): higiene, enfermedades, ricos y pobres, ladrones, bebida y juego
	var vne = load("res://scripts/systems/VillageNeeds.gd")
	var vil = load("res://scripts/systems/VillageIllness.gd")
	var vcr = load("res://scripts/systems/VillageCrime.gd")
	var e_roles = load("res://scripts/enemies/VillageNPC.gd").TradeRole
	var e_old_day: int = int(wclock.current_day)
	var e_old_hour: int = int(wclock.current_hour)
	wclock.current_day = 3
	vm.needs_state = {}
	var e_live: Array = []
	for en in get_nodes_in_group("village_npcs"):
		if not en.is_dead and en.person_profile != null and not (int(en.trade_role) in [int(e_roles.SHERIFF), int(e_roles.GUARD), int(e_roles.TRAVELING_MERCHANT), int(e_roles.ROYAL_INVESTIGATOR), int(e_roles.DOCTOR), int(e_roles.PRIEST)]):
			e_live.append(en)
	var e_a = e_live[0]
	var e_b = e_live[1]
	var e_c = e_live[2]
	var e_saved: Array = [e_a.person_profile.personality.duplicate(), e_b.person_profile.personality.duplicate(), e_c.person_profile.personality.duplicate()]
	var e_gold: Array = [e_a.personal_gold, e_b.personal_gold, e_c.personal_gold]
	# E1: higiene y lavarse
	e_a.person_profile.personality.assign(["Pulcro"])
	e_b.person_profile.personality.assign(["Desaliñado"])
	assert(vne.hygiene_decay(e_a) < vne.hygiene_decay(e_b) and vne.wash_threshold(e_a) > vne.wash_threshold(e_b), "E1: Tidy people get dirty slower and wash sooner")
	e_a.need_hygiene = 10.0
	e_a.start_errand("wash", vne.wash_spot(vm, e_a))
	assert(e_a._get_social_target_pos() == e_a.errand_pos, "E1: They really walk to wash")
	e_a.global_position = e_a.errand_pos
	vne.tick(vm)
	assert(e_a.need_hygiene == 100.0 and e_a.errand_kind == "", "E1: Arriving at the well cleans them")
	var e_pl = get_first_node_in_group("player")
	if e_pl != null and e_pl.survival_comp != null:
		e_pl.survival_comp.current_hygiene = 10.0
		vm._use_water_well(e_pl)
		assert(e_pl.survival_comp.current_hygiene == 100.0, "E1: The player washes at a well")
	# E3: posición económica
	e_a.personal_gold = 200
	e_b.personal_gold = 3
	e_c.personal_gold = 40
	assert(vne.class_of(e_a) == "rico" and vne.class_of(e_b) == "pobre" and vne.class_of(e_c) == "humilde", "E3: Wealth sets social position")
	# E2: enfermedades
	assert(vil.infect(vm, e_b.get_person_key(), "fever") and e_b.sick_level == 2 and not e_b._is_mandatory_work_hours(), "E2: A serious illness keeps them in bed")
	e_c.global_position = e_b.global_position + Vector2(10, 0)
	e_c.need_hygiene = 10.0
	var e_spread: bool = false
	for ei in range(200):
		vm.needs_state["inf_count"] = 0
		vil.on_hour(vm, 10)
		if vil.is_ill(vm, e_c.get_person_key()):
			e_spread = true
			break
	assert(e_spread, "E2: Illness spreads to people nearby")
	vil.treat(vm, e_b.get_person_key())
	assert(bool(vil.ill_of(vm, e_b.get_person_key())["treated"]), "E2: The doctor can treat it")
	vil.recover(vm, e_b.get_person_key())
	assert(e_b.sick_level == 0 and not vil.infect(vm, e_b.get_person_key(), "fever"), "E2: After recovering they are immune for a while")
	vil.recover(vm, e_c.get_person_key())
	# E4: ladrones
	e_b.person_profile.personality.assign(["Cleptómano"])
	e_a.person_profile.personality.assign(["Honrado"])
	assert(vcr.drive(vm, e_b) > 0.0 and vcr.drive(vm, e_a) == 0.0, "E4: Poor or kleptomaniac people may steal; honest people never")
	e_c.personal_gold = 100
	e_c.npc_relationships[e_b.get_person_key()] = 0
	var e_hon_sheriff = null
	var e_hon_pers: Array = []
	for eh in get_nodes_in_group("village_npcs"):
		if not eh.is_dead and int(eh.trade_role) == int(e_roles.SHERIFF):
			e_hon_sheriff = eh
			e_hon_pers = eh.person_profile.personality.duplicate()
			eh.person_profile.personality.assign(["Íntegro"])
	var e_b_gold: int = e_b.personal_gold
	var e_t: Dictionary = vcr.commit(vm, e_b, e_c)
	assert(not e_t.is_empty() and (str(e_t["status"]) == "caught" or (e_c.personal_gold == 100 - int(e_t["amount"]) and e_b.personal_gold == e_b_gold + int(e_t["amount"]))), "E4: A theft moves the gold (unless a witness reports it at once)")
	if str(e_t["status"]) == "open":
		e_t["player_knows"] = true
		var e_sheriff = null
		for es in get_nodes_in_group("village_npcs"):
			if not es.is_dead and int(es.trade_role) == int(e_roles.SHERIFF):
				e_sheriff = es
		if e_sheriff != null:
			vcr.on_player_action(vm, e_sheriff, "crime_report:%d" % int(e_t["id"]))
	assert(str(e_t["status"]) == "caught" and e_c.personal_gold >= 100 - 1, "E4: Reporting a thief makes them give it back")
	assert(e_c.get_relationship_with_npc(e_b.get_person_key()) <= vcr.VICTIM_REL, "E4: The victim resents the thief")
	if e_hon_sheriff != null:
		e_hon_sheriff.person_profile.personality.assign(e_hon_pers)
	# E5: bebida y juego
	e_a.person_profile.personality.assign(["Bebedor"])
	e_a.personal_gold = 50
	assert(vne.vice_chance(vm, e_a, "drink") > vne.vice_chance(vm, e_c, "drink"), "E5: Drinkers go to the tavern more often")
	for ek in range(8):
		vne.do_vice(vm, e_a, "drink")
	assert(e_a.personal_gold == 50 - 8 * vne.DRINK_COST and vne.is_addicted(vm, e_a.get_person_key(), "drink"), "E5: Drinking costs gold and hooks them")
	assert(vne.is_drunk_key(e_a.get_person_key()), "E5: They get drunk")
	var e_qev: Dictionary = {"type": "affair", "actor_id": e_a.get_person_key(), "target_id": "x"}
	var e_told: bool = false
	for ej in range(40):
		if not vsec.keeps_quiet(e_qev, e_a.get_person_key()):
			e_told = true
			break
	assert(e_told, "E5: Drunk people let secrets slip")
	# E6: limosna y ronda
	var e_inv = load("res://scripts/systems/SimpleInventory.gd").new()
	e_inv.gold = 30
	e_b.personal_gold = 0
	e_b.affinity = 0
	assert(vne.on_player_action(vm, e_b, "needs_gift", e_inv) and int(e_inv.gold) == 30 - vne.GIFT_GOLD and e_b.affinity > 0, "E6: Giving gold to the poor pleases them")
	e_inv.free()
	# Guardado
	e_a.need_hygiene = 33.0
	var e_nd: Dictionary = e_a.to_save_dict()
	var e_save: Dictionary = vm.get_economy_save_dict()
	var e_nthefts: int = (vm.needs_state["thefts"] as Array).size()
	vm.needs_state = {}
	vm.load_economy_save_dict(e_save)
	assert((vm.needs_state["thefts"] as Array).size() == e_nthefts and vne.is_addicted(vm, e_a.get_person_key(), "drink") and is_equal_approx(float(e_nd["need_hygiene"]), 33.0), "E: Needs, vices and thefts survive save and load")
	e_a.person_profile.personality.assign(e_saved[0])
	e_b.person_profile.personality.assign(e_saved[1])
	e_c.person_profile.personality.assign(e_saved[2])
	e_a.personal_gold = e_gold[0]
	e_b.personal_gold = e_gold[1]
	e_c.personal_gold = e_gold[2]
	vm.needs_state = {}
	vne.drunk_now = {}
	vil.apply_levels(vm)
	wclock.current_day = e_old_day
	wclock.current_hour = e_old_hour
	print("E economy and needs OK")

	# Test #59 (I1-I5): alcalde y elecciones, impuestos, desfalco, policía corrupta y sobornos
	var vto = load("res://scripts/systems/VillageTown.gd")
	var vne2 = load("res://scripts/systems/VillageNeeds.gd")
	var vcr2 = load("res://scripts/systems/VillageCrime.gd")
	var it_roles = load("res://scripts/enemies/VillageNPC.gd").TradeRole
	var it_old_day: int = int(wclock.current_day)
	vm.town_state = {}
	vm.needs_state = {}
	var it_res: Dictionary = vto.hold_election(vm)
	var it_mayor = vto.mayor_of(vm)
	assert(not it_res.is_empty() and it_mayor != null and vto.eligible(it_mayor), "I2: An election picks a mayor among eligible villagers")
	var it_cands: Array = vto.candidates(vm)
	var it_voter = null
	for iv in get_nodes_in_group("village_npcs"):
		if not iv.is_dead and vto.eligible(iv) and not (iv in it_cands):
			it_voter = iv
			break
	if it_voter != null and it_cands.size() >= 2:
		it_voter.affinity = 50
		vto.on_player_action(vm, it_voter, "town_pledge:%s" % it_cands[1].get_person_key(), null)
		assert(vto.vote_of(vm, it_voter, it_cands) == it_cands[1], "I5: Someone who likes you votes for your candidate")
	# I3: corrupción según los rasgos
	var it_m_pers: Array = it_mayor.person_profile.personality.duplicate()
	it_mayor.person_profile.personality.assign(["Íntegro"])
	assert(not vto.is_corrupt(it_mayor), "I3: Upright people are never corrupt")
	it_mayor.person_profile.personality.assign(["Sobornable", "Codicioso"])
	assert(vto.is_corrupt(it_mayor), "I3: Bribable and greedy people are corrupt")
	# I1: impuestos y desfalco
	var it_payer = null
	for ip in get_nodes_in_group("village_npcs"):
		if not ip.is_dead and ip != it_mayor and not vne2.is_outsider(ip):
			it_payer = ip
			break
	var it_payer_gold: int = it_payer.personal_gold
	it_payer.personal_gold = 120
	var it_mgold: int = it_mayor.personal_gold
	var it_tax: Dictionary = vto.collect_taxes(vm)
	assert(int(it_tax["taxed"]) > 0 and it_payer.personal_gold < 120, "I1: Villagers pay taxes on Saturdays")
	assert(int(it_tax["embezzled"]) > 0 and it_mayor.personal_gold > it_mgold, "I3: A corrupt mayor keeps part of the taxes")
	vm.town_state["embezzled_term"] = 30
	it_mayor.personal_gold += 30
	vto.expose(vm, "prueba")
	assert(vto.mayor_of(vm) != it_mayor and int(vm.town_state.get("exposed", 0)) == 1, "I3: An exposed mayor loses the post in a snap election")
	it_mayor.person_profile.personality.assign(it_m_pers)
	it_payer.personal_gold = it_payer_gold
	# I3: comisario corrupto y soborno del jugador
	var it_sheriff = null
	for isf in get_nodes_in_group("village_npcs"):
		if not isf.is_dead and int(isf.trade_role) == int(it_roles.SHERIFF):
			it_sheriff = isf
	if it_sheriff != null:
		var it_s_pers: Array = it_sheriff.person_profile.personality.duplicate()
		it_sheriff.person_profile.personality.assign(["Sobornable", "Codicioso"])
		var it_thief = it_payer
		it_thief.personal_gold = 40
		assert(vto.police_takes_bribe(vm, it_thief, null) and it_thief.personal_gold == 25, "I3: A corrupt sheriff lets a thief go for gold")
		vm.bounty_gold = 10
		vm.wanted_level = 1
		var it_inv = load("res://scripts/systems/SimpleInventory.gd").new()
		it_inv.gold = 100
		vto.on_player_action(vm, it_sheriff, "town_bribe", it_inv)
		assert(vm.bounty_gold == 0 and vm.wanted_level == 0 and int(it_inv.gold) == 100 - vto.BRIBE_MIN, "I5: You can bribe a corrupt sheriff to drop your charges")
		it_sheriff.person_profile.personality.assign(["Íntegro"])
		vm.bounty_gold = 10
		vto.on_player_action(vm, it_sheriff, "town_bribe", it_inv)
		assert(vm.bounty_gold == 10 + vto.BRIBE_FAIL_FINE, "I5: An upright sheriff raises your fine")
		vm.bounty_gold = 0
		vm.wanted_level = 0
		it_inv.free()
		it_sheriff.person_profile.personality.assign(it_s_pers)
	var it_save: Dictionary = vm.get_economy_save_dict()
	var it_mk: String = str(vm.town_state["mayor"])
	vm.town_state = {}
	vm.load_economy_save_dict(it_save)
	assert(str(vm.town_state.get("mayor", "")) == it_mk and it_mk != "", "I: The mayor and the treasury survive save and load")
	vm.town_state = {}
	vm.needs_state = {}
	wclock.current_day = it_old_day
	print("I institutions and corruption OK")

	# Test #60 (O1-O6): la secta secreta
	var vsc = load("res://scripts/systems/VillageSect.gd")
	var vfa_o = load("res://scripts/systems/VillageFaith.gd")
	vm.sect_state = {}
	vm.needs_state = {}
	var os_people: Array = []
	for on in get_nodes_in_group("village_npcs"):
		if not on.is_dead and vsc._can_be_member(on):
			os_people.append(on)
	assert(os_people.size() >= 5, "O: There are enough villagers for the sect test")
	var os_f = os_people[0]
	var os_t = os_people[1]
	var os_r = os_people[2]
	var os_v = os_people[3]
	var os_saved: Dictionary = {}
	for on in [os_f, os_t, os_r, os_v]:
		os_saved[on] = on.person_profile.personality.duplicate()
	var os_moods: Array = [os_f.mood, os_t.mood]
	os_f.person_profile.personality.assign(["Místico", "Manipulador"])
	os_t.person_profile.personality.assign(["Místico"])
	os_t.mood = 20.0
	os_r.person_profile.personality.assign(["Íntegro", "Devoto"])
	os_f.person_profile.personality.assign(["Místico", "Manipulador", "Líder"])
	assert(vsc.persuasion(vm, os_f) >= vsc.PERSUADE_MIN, "O1: A mystic manipulator leader can convince others")
	# O1: sin crisis ni aburrimiento no nace nada; con crisis, puede nacer
	assert(float(vsc.found_chance(vm, os_f, 0.0, 0.0)["p"]) == 0.0, "O1: In calm times no sect is born")
	os_f.mood = 20.0
	assert(float(vsc.found_chance(vm, os_f, 0.5, 0.0)["p"]) > 0.0 and str(vsc.found_chance(vm, os_f, 0.5, 0.0)["kind"]) == "desperate", "O1: Hard times and a persuasive leader can start a sect of the desperate")
	os_f.person_profile.personality.assign(["Trabajador"])
	assert(float(vsc.found_chance(vm, os_f, 0.9, 0.0)["p"]) == 0.0, "O1: Without a persuasive leader no sect is born, even in a crisis")
	os_f.person_profile.personality.assign(["Místico", "Manipulador", "Líder"])
	vsc.found(vm, os_f, "desperate")
	assert(vsc.active(vm) and vsc.is_member(vm, os_f), "O1: The founder starts the sect")
	for k in vm.sect_state["members"].keys():
		if k != os_f.get_person_key():
			vm.sect_state["members"].erase(k)
	os_t.npc_relationships[os_f.get_person_key()] = 50
	os_f.npc_relationships[os_t.get_person_key()] = 50
	assert(vsc.try_recruit(vm, os_f, os_t, 10.0) == "joined" and vsc.is_member(vm, os_t), "O2: A vulnerable mystic friend joins the sect")
	assert(vfa_o.same_band(vm, os_f, os_t), "O4: Sect members are a hidden band that covers for each other")
	assert(not ("Hijos" in vfa_o.glossary_line(vm, os_f)) and vsc.glossary_line(vm, os_f) == "", "O5: The sect stays hidden until you discover it")
	var os_log: int = vm.social_event_log.size()
	assert(vsc.try_recruit(vm, os_f, os_r) == "refused" and not vsc.is_member(vm, os_r), "O2: Upright believers refuse to join")
	assert(vm.social_event_log.size() > os_log and str(vm.social_event_log[-1]["type"]) == "sect_rumor" and int(vm.sect_state["suspicion"]) > 0, "O5: Whoever refuses spreads a rumor and suspicion grows")
	# O3: reunión de madrugada
	vm.sect_state["last_meeting_day"] = -1
	for on in [os_f, os_t]:
		on.join_rite(vsc.meeting_spot(vm, 0), "sect")
		on.global_position = on.rite_pos
	var os_meet: Dictionary = vsc.finish_meeting(vm)
	assert(int(os_meet["attendees"]) == 2 and int(vm.sect_state["meetings"]) == 1 and os_f.rite_kind == "", "O3: Members meet at night in the cemetery")
	# O6: el jugador se une
	vm.sect_state["invite_by"] = os_t.get_person_key()
	vsc.on_player_action(vm, os_t, "sect_join", null)
	assert(vsc.player_member(vm) and vsc.known_member(vm, os_f) and "miembro" in vsc.glossary_line(vm, os_f), "O6: You can join and then know the members")
	# O4: rito de sangre (muy raro; aquí forzado)
	vsc.start_plan(vm, os_v)
	vm.sect_state["last_meeting_day"] = -1
	for on in [os_f, os_t]:
		on.join_rite(vsc.meeting_spot(vm, 1), "sect")
		on.global_position = on.rite_pos
	os_v.join_rite(vsc.meeting_spot(vm, 9), "sect_lure")
	os_v.global_position = os_v.rite_pos
	var os_rite: Dictionary = vsc.finish_meeting(vm)
	assert(str(os_rite["rite"]) == os_v.npc_name and os_v.is_dead and str(vm.npc_murders.get(os_v.npc_name, "")) == os_f.npc_name, "O4: A prepared blood rite kills the lured victim and leaves a trail for the sheriff")
	var os_save: Dictionary = vm.get_economy_save_dict()
	vm.sect_state = {}
	vm.load_economy_save_dict(os_save)
	assert(vsc.is_member(vm, os_t) and vsc.player_member(vm), "O: The sect survives save and load")
	# O5: se destapa
	var os_rel: int = os_r.get_relationship_with_npc(os_f.get_person_key())
	vsc.expose(vm, "prueba")
	assert(not vsc.active(vm) and not vsc.player_member(vm) and os_r.get_relationship_with_npc(os_f.get_person_key()) < os_rel, "O5: Once exposed the sect dissolves and its members are shunned")
	for on in os_saved.keys():
		on.person_profile.personality.assign(os_saved[on])
	os_f.mood = os_moods[0]
	os_t.mood = os_moods[1]
	vm.sect_state = {}
	vm.needs_state = {}
	print("O secret sect OK")

	# Test #61 (V2): simulación simplificada lejos del jugador
	var v2_pl = get_first_node_in_group("player")
	var v2_n = null
	for vn in get_nodes_in_group("village_npcs"):
		if not vn.is_dead and not vn.is_hostile and not (int(vn.trade_role) in [int(it_roles.SHERIFF), int(it_roles.GUARD), int(it_roles.DOCTOR), int(it_roles.ROYAL_INVESTIGATOR)]):
			v2_n = vn
			break
	if v2_pl != null and v2_n != null:
		var v2_pos: Vector2 = v2_n.global_position
		var v2_ppos: Vector2 = v2_pl.global_position
		v2_pl.global_position = v2_n.global_position + Vector2(v2_n.LOD_DIST + 200.0, 0.0)
		assert(v2_n._lod_far(), "V2: A villager off screen is simulated in less detail")
		v2_pl.global_position = v2_n.global_position + Vector2(40.0, 0.0)
		assert(not v2_n._lod_far(), "V2: A villager near you is simulated in full detail")
		var v2_dt: float = v2_n.get_physics_process_delta_time()
		v2_n.velocity = Vector2(30.0, 0.0)
		var v2_p0: Vector2 = v2_n.global_position
		v2_n._lod_k = 4.0
		v2_n._finish_frame_movement(v2_dt * 4.0)
		v2_n._lod_k = 1.0
		assert(v2_n.global_position.distance_to(v2_p0) > 30.0 * v2_dt * 2.0 and v2_n.velocity.is_equal_approx(Vector2(30.0, 0.0)), "V2: A simplified step covers the distance of the frames it skipped")
		v2_n.velocity = Vector2.ZERO
		v2_n.global_position = v2_pos
		v2_pl.global_position = v2_ppos
	print("V2 far simulation OK")

	# Test #62 (V8): un ambicioso se queda un negocio vacante; la venganza por celos llega antes a la idea de matar
	var v8_c = null
	for vn8 in vm.unemployed_npcs:
		if is_instance_valid(vn8) and not vn8.is_dead:
			v8_c = vn8
			break
	if v8_c != null:
		var v8_pers: Array = v8_c.person_profile.personality.duplicate()
		var v8_gold: int = v8_c.personal_gold
		v8_c.person_profile.personality.assign(["Ambicioso", "Trabajador"])
		v8_c.personal_gold = 900
		assert(vm._pick_ambitious_successor(0, "Prueba") == v8_c and not (v8_c in vm.unemployed_npcs), "V8: The most ambitious villager takes over a vacant business")
		vm.unemployed_npcs.append(v8_c)
		v8_c.person_profile.personality.assign(v8_pers)
		v8_c.personal_gold = v8_gold
	var vde = load("res://scripts/systems/VillageDesires.gd")
	var v8_h = os_r
	var v8_t = os_t
	var v8_hp: Array = v8_h.person_profile.personality.duplicate()
	v8_h.person_profile.personality.assign(["Cruel", "Celoso"])
	v8_h.npc_relationships[v8_t.get_person_key()] = -65
	var v8_gap: int = vm.last_npc_murder_day
	vm.last_npc_murder_day = -999
	var v8_d: Dictionary = vde.create(vm, "revenge", v8_h, v8_t.get_person_key(), v8_t.npc_name, "prueba", false)
	v8_d["day"] = int(wclock.current_day) - 6
	assert(not vde._maybe_turn_murder(vm, v8_d, v8_h, v8_t, int(wclock.current_day)), "V8: An ordinary grudge of -65 is not enough to plan a murder")
	v8_d["passion"] = true
	var v8_turned: bool = false
	for _i8 in range(400):
		if vde._maybe_turn_murder(vm, v8_d, v8_h, v8_t, int(wclock.current_day)):
			v8_turned = true
			break
	assert(v8_turned and str(v8_d["type"]) == "murder", "V8: Jealous revenge after an affair can turn into a (rare) murder plan sooner")
	vde.finish(vm, v8_d, "foiled")
	vm.last_npc_murder_day = v8_gap
	v8_h.person_profile.personality.assign(v8_hp)
	print("V8 ambition and jealousy OK")

	# 63. V4: solares. Una casa la paga un vecino, la levanta el carpintero solo mientras trabaja allí, deja camas
	# libres y sobrevive a guardar y cargar.
	var vl = load("res://scripts/systems/VillageLots.gd")
	var v4_carp = null
	var v4_payer = vm._find_npc_by_name("Garrick")
	for n4 in get_nodes_in_group("village_npcs"):
		if v4_carp == null and not n4.is_dead and not n4.is_downed and n4 != v4_payer:
			v4_carp = n4 # Bram puede haber muerto en tests anteriores: hace de carpintero cualquier vecino vivo
	assert(v4_carp != null and v4_payer != null, "V4: A carpenter and Garrick exist")
	var v4_role = vm.trade_configs.keys().filter(func(k): return str(vm.trade_configs[k].get("name", "")) == "Bram")[0]
	var v4_holder = vm.trade_npcs.get(v4_role)
	vm.trade_npcs[v4_role] = v4_carp
	var v4_cw: Vector2 = v4_carp.work_position
	var v4_cg: int = v4_carp.personal_gold
	var v4_pg: int = v4_payer.personal_gold
	assert("n1" in vl.free_lots(vm, "house"), "V4: The town starts with free lots")
	v4_payer.personal_gold = 10
	assert(vl.request_build(vm, "n1", "house", v4_payer) == "", "V4: Nobody builds without the money")
	v4_payer.personal_gold = 160
	assert(vl.request_build(vm, "n1", "house", v4_payer) == "n1" and v4_payer.personal_gold == 160 - int(vl.KINDS["house"]["cost"]), "V4: The payer pays for the house")
	assert(vl.request_build(vm, "n2", "house", v4_payer) == "", "V4: The carpenter takes one job at a time")
	var v4_wp: Vector2 = vl.site_work_pos("n1")
	v4_carp.is_sleeping = false
	v4_carp.current_activity = 0
	v4_carp.global_position = Vector2(585, 148) # En su taller, lejos de la obra
	for _h4 in range(10):
		vl.on_hour(vm, 10)
	assert(v4_carp.work_position == v4_wp and float(vl.lot(vm, "n1")["progress"]) == 0.0, "V4: The work only advances with the carpenter on site")
	var v4_hours: int = 0
	while str(vl.lot(vm, "n1")["status"]) != "built" and v4_hours < 80:
		v4_carp.global_position = v4_wp
		v4_carp.current_activity = 0
		vl.on_hour(vm, 10)
		v4_hours += 1
	assert(str(vl.lot(vm, "n1")["status"]) == "built" and v4_hours >= 15, "V4: A house takes days of real work (%d h)" % v4_hours)
	var v4_bed: Dictionary = vl.free_house_bed(vm)
	assert(str(v4_bed.get("lot", "")) == "n1" and v4_carp.work_position == vm.trade_configs[v4_role]["work_pos"], "V4: The new house has free beds and the carpenter goes back to his shop")
	var v4_fp = func(): return vm.building_footprints.filter(func(f): return str(f["id"]) == "house_family_lot_n1").size()
	assert(v4_fp.call() == 1, "V4: The house is a real building")
	var v4_saved: Dictionary = JSON.parse_string(JSON.stringify(vm.lots_state))
	vm.lots_state = {}
	vl.after_load(vm)
	assert(v4_fp.call() == 0, "V4: Loading a game without the house removes it")
	vm.lots_state = v4_saved
	vl.after_load(vm)
	assert(v4_fp.call() == 1 and not vl.free_house_bed(vm).is_empty(), "V4: Loading a game with the house rebuilds it once")
	vm.lots_state = {}
	vl.after_load(vm)
	v4_carp.work_position = v4_cw
	v4_carp.personal_gold = v4_cg
	v4_payer.personal_gold = v4_pg
	if v4_holder != null:
		vm.trade_npcs[v4_role] = v4_holder
	else:
		vm.trade_npcs.erase(v4_role)
	print("V4 lots and buildings OK")

	# 64. V5a: panadería y sastrería en los solares; el puesto vacante se ocupa; los ricos estrenan ropa y los pobres no.
	var vt = load("res://scripts/systems/VillageTrades.gd")
	var v5_bk: int = vt.role_of("baker")
	var v5_tl: int = vt.role_of("tailor")
	assert(vm.trade_configs.has(v5_bk) and vm.shop_businesses.has(v5_bk) and vm.shop_businesses.has(v5_tl), "V5: The bakery and the tailor exist as businesses")
	assert(str(vl.lot(vm, "n2")["kind"]) == "shop_house" and vm.building_footprints.filter(func(f): return str(f["id"]) == "mixed_family_baker").size() == 1, "V5: The bakery stands on its lot")
	var v5_tries: int = 0
	while not (is_instance_valid(vm.trade_npcs.get(v5_bk)) and is_instance_valid(vm.trade_npcs.get(v5_tl))) and v5_tries < 4:
		vm.arrivals_today_count = 0
		vm._process_daily_map_edge_arrivals()
		v5_tries += 1
	var v5_tailor = vm.trade_npcs.get(v5_tl)
	assert(is_instance_valid(vm.trade_npcs.get(v5_bk)) and is_instance_valid(v5_tailor), "V5: Somebody comes to run the vacant bakery and tailor's shop")
	var v5_rich = vm._find_npc_by_name("Garrick")
	var v5_poor = vm._find_npc_by_name("Thoran")
	var v5_rg: int = v5_rich.personal_gold
	var v5_pg: int = v5_poor.personal_gold
	var v5_buys: int = 0
	for _d5 in range(80):
		v5_rich.personal_gold = 400
		v5_poor.personal_gold = 15
		v5_tailor.shop_stock["clothes"] = 5
		v5_tailor.is_downed = false
		vt.daily(vm)
		if v5_rich.personal_gold < 400:
			v5_buys += 1
		assert(v5_poor.personal_gold == 15, "V5: Somebody poor does not buy clothes")
	assert(v5_buys >= 1 and v5_buys < 40, "V5: The rich sometimes buy new clothes (%d/80)" % v5_buys)
	vm.shop_businesses[v5_bk]["owner_mode"] = "PARTNER"
	vm._lot_visuals["n2"][2] = "redibujar"
	vm.lots_state = {}
	vl.after_load(vm)
	assert(vm.building_footprints.filter(func(f): return str(f["id"]) == "mixed_family_baker").size() == 1 and str(vm.shop_businesses[v5_bk]["owner_mode"]) == "PARTNER", "V5: An old save keeps the bakery and its business data")
	vm.shop_businesses[v5_bk]["owner_mode"] = "NPC"
	v5_rich.personal_gold = v5_rg
	v5_poor.personal_gold = v5_pg
	print("V5a bakery and tailor OK")

	# 65. V5b: ayuntamiento (votar en persona, arcas que se pueden robar), Albergue del Alba y El Candil.
	var vc = load("res://scripts/systems/VillageCivic.gd")
	var v5b_fp = func(bid): return vm.building_footprints.filter(func(f): return str(f["id"]) == bid).size()
	assert(v5b_fp.call("building_town_hall") == 1 and v5b_fp.call("building_shelter") == 1 and vm.shop_businesses.has(vc.lodge_role()), "V5b: Town hall, shelter and El Candil stand on their lots")
	var v5b_ts: Dictionary = vm.town_state.duplicate(true)
	# Votar en persona: solo cuenta quien fue
	var v5b_people: Array = []
	for n5 in get_nodes_in_group("village_npcs"):
		if not n5.is_dead and not n5.is_downed and v5b_people.size() < 3 and n5.person_profile != null:
			v5b_people.append(n5)
	vc.open_voting(vm)
	assert(vc.is_voting_today(vm), "V5b: Election day opens the town hall")
	for n5 in v5b_people:
		n5.start_errand("vote", vc.hall_spots()["ballot"])
		vc.on_errand_arrived(vm, n5)
		assert(n5.errand_kind == "", "V5b: After voting they go back to their day")
	var v5b_res: Dictionary = vc.close_voting(vm)
	var v5b_total: int = 0
	for vk in (v5b_res.get("votes", {}) as Dictionary).values():
		v5b_total += int(vk)
	assert(not v5b_res.is_empty() and v5b_total >= 1 and v5b_total <= 3, "V5b: Only those who went to vote are counted (%d)" % v5b_total)
	# Arcas
	vm.town_state["treasury"] = 100
	var v5b_take: int = vc.rob_coffers(vm)
	assert(v5b_take >= 25 and v5b_take <= 60 and int(vm.town_state["treasury"]) == 100 - v5b_take, "V5b: Forcing the coffers takes the town's real money")
	vc.daily(vm)
	assert(int(vm.town_state.get("coffers_missing", 0)) == 0 and vm.chronicle.filter(func(e): return str(e.get("type", "")) == "coffers_robbed").size() >= 1, "V5b: Next day the town learns money is missing")
	vm.town_state = v5b_ts
	# Albergue: cuatro camas; el quinto acaba a la intemperie
	var v5b_saved: Array = []
	var v5b_n: Array = []
	for n5 in get_nodes_in_group("village_npcs"):
		if not n5.is_dead and not n5.in_shelter and v5b_n.size() < 5:
			v5b_n.append(n5)
			v5b_saved.append([n5.bed_position, n5.is_vagrant_camper, n5.lodging, n5.vagrant_camp_pos])
	for n5 in v5b_n:
		vm.evict_npc_to_vagrant_camp(n5)
	var v5b_in: int = v5b_n.filter(func(x): return x.in_shelter).size()
	assert(v5b_in == 4 and not v5b_n[4].in_shelter and v5b_n[4].is_vagrant_camper, "V5b: The shelter takes four; the fifth sleeps outdoors")
	assert(v5b_n[0].bed_position in vc.shelter_beds(), "V5b: Sheltered people sleep in the shelter beds")
	for i5 in range(v5b_n.size()):
		var n5 = v5b_n[i5]
		n5.in_shelter = false
		n5.bed_position = v5b_saved[i5][0]
		n5.is_vagrant_camper = v5b_saved[i5][1]
		n5.lodging = v5b_saved[i5][2]
		n5.vagrant_camp_pos = v5b_saved[i5][3]
		if vm.vagrant_camp_nodes.has(n5.npc_name) and is_instance_valid(vm.vagrant_camp_nodes[n5.npc_name]) and not n5.is_vagrant_camper:
			vm.vagrant_camp_nodes[n5.npc_name].visible = false
	# El Candil: quien no llega para El Jabalí pero sí para 3 de oro, duerme allí; sin dinero, sale
	var v5b_lr: int = vc.lodge_role()
	var v5b_keeper_old = vm.trade_npcs.get(v5b_lr)
	var v5b_keeper = v5b_people[0]
	var v5b_guest = v5b_people[1]
	vm.trade_npcs[v5b_lr] = v5b_keeper
	var v5b_gs: Array = [v5b_guest.personal_gold, v5b_guest.bed_position, v5b_guest.is_vagrant_camper]
	v5b_guest.is_vagrant_camper = false
	v5b_guest.lodging = ""
	v5b_guest.personal_gold = 4
	assert(vc.nightly_guest(vm, v5b_guest, 6) and v5b_guest.lodging == "candil" and v5b_guest.personal_gold == 1, "V5b: A guest short of money lodges at El Candil")
	assert(not vc.nightly_guest(vm, v5b_guest, 6) and v5b_guest.lodging == "", "V5b: Without even 3 gold they lose the bed at El Candil")
	v5b_guest.personal_gold = v5b_gs[0]
	v5b_guest.bed_position = v5b_gs[1]
	v5b_guest.is_vagrant_camper = v5b_gs[2]
	if v5b_keeper_old != null:
		vm.trade_npcs[v5b_lr] = v5b_keeper_old
	else:
		vm.trade_npcs.erase(v5b_lr)
	print("V5b town hall, shelter and inn OK")

	# 66. V5c: terceros espacios. En su rato libre, quien es sociable sale; con lluvia casi nadie; quien coincide charla.
	var vp = load("res://scripts/systems/VillagePlaces.gd")
	assert(vm.get_hangout_spots().filter(func(sp): return str(sp["id"]) == "park_lawn").size() == 1, "V5c: Hangouts can use the park")
	var v5c_a = v5b_people[0]
	var v5c_b = v5b_people[1]
	var v5c_wc = root.get_node_or_null("/root/WorldClock")
	var v5c_weather: int = int(v5c_wc.current_weather)
	v5c_wc.current_weather = 0
	var v5c_dry: float = vp.leisure_chance(v5c_a)
	v5c_wc.current_weather = 1
	assert(vp.leisure_chance(v5c_a) < v5c_dry * 0.5, "V5c: Rain keeps people at home")
	v5c_wc.current_weather = 0
	var v5c_rel: int = v5c_a.get_relationship_with_npc(v5c_b.get_person_key())
	if v5c_rel <= vp.FRICTION_REL:
		v5c_a.modify_npc_relationship(v5c_b, 60, "test", true)
		v5c_rel = v5c_a.get_relationship_with_npc(v5c_b.get_person_key())
	var v5c_pos: Array = [v5c_a.global_position, v5c_b.global_position]
	var v5c_soc: float = v5c_a.need_social
	for n5 in [v5c_a, v5c_b]:
		n5.set_meta("leisure_place", "park_lawn")
		n5.start_errand("leisure", vp.place("park_lawn")["pos"])
		n5.global_position = vp.place("park_lawn")["pos"] + Vector2(randf_range(-8, 8), 0)
		vp.on_arrived(vm, n5)
	assert(v5c_a.errand_kind == "leisure" and v5c_a.has_meta("leisure_since"), "V5c: On arrival they stay a while")
	var v5c_chats: int = int(vp.state(vm)["chats"])
	vp._chat_round(vm, [v5c_a, v5c_b])
	assert(int(vp.state(vm)["chats"]) == v5c_chats + 1 and v5c_a.get_relationship_with_npc(v5c_b.get_person_key()) > v5c_rel and v5c_a.need_social >= minf(100.0, v5c_soc), "V5c: People who meet in the park chat and get closer")
	for n5 in [v5c_a, v5c_b]:
		vp._leave(n5)
	assert(v5c_a.errand_kind == "" and not v5c_a.has_meta("leisure_place"), "V5c: Leaving ends the outing")
	v5c_a.global_position = v5c_pos[0]
	v5c_b.global_position = v5c_pos[1]
	v5c_wc.current_weather = v5c_weather
	print("V5c third places OK")

	# 67. V5d: afueras. Granja, rancho, cantera y leñador; los jornaleros cobran por las horas que trabajan de verdad.
	var vw = load("res://scripts/systems/VillageWork.gd")
	for r5 in [vt.role_of("farmer"), vt.role_of("rancher"), vt.role_of("quarry"), vt.role_of("woodcutter")]:
		assert(vm.shop_businesses.has(r5), "V5d: The outskirts business %d exists" % r5)
	assert(str(vl.lot(vm, "s2")["kind"]) == "fields" and vm.building_footprints.filter(func(f): return str(f["id"]) == "mixed_family_farm").size() == 1, "V5d: The farm and its fields stand on their lots")
	var v5d_fr: int = vt.role_of("farmer")
	var v5d_old = vm.trade_npcs.get(v5d_fr)
	var v5d_master = v5b_people[2]
	vm.trade_npcs[v5d_fr] = v5d_master
	var v5d_mg: int = v5d_master.personal_gold
	var v5d_worker = null
	for n5 in get_nodes_in_group("village_npcs"):
		if v5d_worker == null and vw.can_be_hired(n5) and n5 != v5d_master:
			v5d_worker = n5
	if v5d_worker == null: # V3: ya no hay siempre viajeros parados; traemos uno
		v5d_worker = load("res://scripts/systems/VillageMigration.gd")._spawn_one(vm, {"label": "Jornalero de prueba", "gold": Vector2i(10, 10)}, 0)
	assert(v5d_worker != null and vw.can_be_hired(v5d_worker), "V5d: There is somebody without a trade to hire")
	var v5d_wg: int = v5d_worker.personal_gold
	var v5d_wp: Vector2 = v5d_worker.global_position
	v5d_master.personal_gold = 200
	vw._assign(vm, v5d_worker, "farmer", vw.PLACES["farmer"]["spots"][0])
	assert(v5d_worker.has_meta("day_job") and vm.work_state["jobs"].has(v5d_worker.get_person_key()), "V5d: The laborer is hired")
	var v5d_wheat: int = int(v5d_master.shop_stock.get("wheat", 0))
	v5d_worker.global_position = Vector2(400, 0) # Lejos del campo: esa hora no cuenta
	v5d_worker.current_activity = 0
	v5d_worker.is_sleeping = false
	vw._count_hour(vm)
	assert(int(vm.work_state["jobs"][v5d_worker.get_person_key()]["hours"]) == 0, "V5d: Hours away from the field do not count")
	for _h5 in range(8):
		v5d_worker.global_position = v5d_worker.get_meta("day_job_pos")
		v5d_worker.current_activity = 0
		vw._count_hour(vm)
	assert(int(v5d_master.shop_stock.get("wheat", 0)) >= v5d_wheat + 1, "V5d: The laborer's work fills the farm's stock")
	v5d_worker.personal_gold = 0
	var v5d_pay: Dictionary = vw.pay(vm)
	assert(int(v5d_pay["paid"]) == 8 and v5d_worker.personal_gold == 8 and v5d_master.personal_gold == 192 and not v5d_worker.has_meta("day_job"), "V5d: At six they get paid for their hours")
	var v5d_rel: int = v5d_worker.get_relationship_with_npc(v5d_master.get_person_key())
	vw._assign(vm, v5d_worker, "farmer", vw.PLACES["farmer"]["spots"][0])
	vm.work_state["jobs"][v5d_worker.get_person_key()]["hours"] = 6
	v5d_master.personal_gold = 2
	v5d_pay = vw.pay(vm)
	assert(int(v5d_pay["unpaid"]) == 4 and v5d_worker.get_relationship_with_npc(v5d_master.get_person_key()) < v5d_rel, "V5d: An unpaid laborer resents the owner")
	# Lavadero
	var v5d_lav: int = 0
	for _i5 in range(200):
		if vw.wash_spot(vm, v5d_worker, Vector2(412, 70)).distance_to(vw.LAVADERO_POS) < 30.0:
			v5d_lav += 1
	assert(v5d_lav > 20 and v5d_lav < 120, "V5d: Some people wash at the laundry (%d/200)" % v5d_lav)
	var v5d_other = v5b_people[0]
	var v5d_op: Vector2 = v5d_other.global_position
	v5d_worker.global_position = vw.LAVADERO_POS
	v5d_other.global_position = vw.LAVADERO_POS + Vector2(10, 0)
	var v5d_r0: int = v5d_worker.get_relationship_with_npc(v5d_other.get_person_key())
	vw.on_washed(vm, v5d_worker)
	assert(v5d_worker.get_relationship_with_npc(v5d_other.get_person_key()) != v5d_r0 or v5d_r0 >= 100, "V5d: People who meet at the laundry chat")
	v5d_other.global_position = v5d_op
	v5d_worker.global_position = v5d_wp
	v5d_worker.personal_gold = v5d_wg
	v5d_master.personal_gold = v5d_mg
	if v5d_old != null:
		vm.trade_npcs[v5d_fr] = v5d_old
	else:
		vm.trade_npcs.erase(v5d_fr)
	print("V5d outskirts and laborers OK")

	# 68. V5e: biblioteca, escuela, mercado de los miércoles y arreglos del Taller de Reparaciones.
	var vcu = load("res://scripts/systems/VillageCulture.gd")
	assert(str(vl.lot(vm, "n5")["kind"]) == "library" and str(vl.lot(vm, "e3")["kind"]) == "school", "V5e: Library and school stand on their lots")
	assert(vm.building_footprints.filter(func(f): return str(f["id"]) in ["building_library", "building_school"]).size() == 2, "V5e: Both buildings are built")
	assert(vm.shop_businesses.has(vt.role_of("tinker")), "V5e: The repair workshop exists")
	# Leer en la biblioteca: una vez al día
	var v5e_pl = get_first_node_in_group("player")
	if v5e_pl != null:
		vcu.state(vm)["player_read_day"] = -1
		var v5e_rd: int = int(vcu.state(vm)["readings"])
		assert(vcu.try_interact(vm, v5e_pl, vcu.reading_spot()) and int(vcu.state(vm)["readings"]) == v5e_rd + 1, "V5e: The player reads at the library")
		vcu.try_interact(vm, v5e_pl, vcu.reading_spot())
		assert(int(vcu.state(vm)["readings"]) == v5e_rd + 1, "V5e: Only once a day")
	# Mercado: quien tiene género de sobra baja a la plaza y vuelve a su tienda al cerrar
	var v5e_s = v5b_people[2]
	var v5e_role: int = vt.role_of("farmer")
	var v5e_old = vm.trade_npcs.get(v5e_role)
	vm.trade_npcs[v5e_role] = v5e_s
	var v5e_stock: Dictionary = v5e_s.shop_stock.duplicate()
	var v5e_wp: Vector2 = v5e_s.work_position
	v5e_s.shop_stock["wheat"] = 12
	vm.shop_businesses[v5e_role]["sabotaged_days"] = 0
	assert(vcu.open_market(vm) >= 1 and v5e_s.work_position in vcu.MARKET_SPOTS, "V5e: A seller with surplus sets up in the plaza")
	var v5e_b = v5b_people[0]
	var v5e_bg: int = v5e_b.personal_gold
	var v5e_bp: Vector2 = v5e_b.global_position
	v5e_b.personal_gold = 20
	v5e_b.global_position = v5e_s.global_position + Vector2(0, 10)
	var v5e_sales: int = int(vcu.state(vm)["market_sales"])
	vcu.on_market_arrived(vm, v5e_b)
	assert(int(vcu.state(vm)["market_sales"]) == v5e_sales + 1 and v5e_b.personal_gold == 15, "V5e: A neighbour buys at the market")
	vcu.close_market(vm)
	assert(v5e_s.work_position == v5e_wp and not vcu.is_market_open(vm), "V5e: Sellers return to their shops when the market closes")
	# Arreglos: un negocio saboteado paga y pierde un día de avería
	var v5e_tr: int = vt.role_of("tinker")
	var v5e_told = vm.trade_npcs.get(v5e_tr)
	var v5e_t = v5b_people[1]
	var v5e_tstock: Dictionary = v5e_t.shop_stock.duplicate()
	var v5e_trole: int = int(v5e_t.trade_role)
	v5e_t.trade_role = v5e_tr
	vm.trade_npcs[v5e_tr] = v5e_t
	v5e_t.shop_stock["repair_kit"] = 3
	vm.shop_businesses[v5e_tr]["sabotaged_days"] = 0
	vm.shop_businesses[v5e_role]["sabotaged_days"] = 2
	var v5e_sg: int = v5e_s.personal_gold
	v5e_s.personal_gold = 50
	assert(vcu.daily(vm) >= 1 and int(vm.shop_businesses[v5e_role]["sabotaged_days"]) == 1 and v5e_s.personal_gold == 42, "V5e: The tinker repairs a sabotaged business for a fee")
	vm.shop_businesses[v5e_role]["sabotaged_days"] = 0
	vm._refresh_shop_stall_visual(v5e_role)
	v5e_t.trade_role = v5e_trole
	v5e_t.shop_stock = v5e_tstock
	v5e_s.shop_stock = v5e_stock
	v5e_s.personal_gold = v5e_sg
	v5e_b.personal_gold = v5e_bg
	v5e_b.global_position = v5e_bp
	for e5 in [[v5e_tr, v5e_told], [v5e_role, v5e_old]]:
		if e5[1] != null:
			vm.trade_npcs[e5[0]] = e5[1]
		else:
			vm.trade_npcs.erase(e5[0])
	print("V5e library, school, market and repairs OK")

	# 69. V3: llegadas y marchas según el atractivo del pueblo; casas para quien llega.
	var vmi = load("res://scripts/systems/VillageMigration.gd")
	for id3 in ["n0", "e6", "m1", "m2", "m3", "m4", "m5", "n6", "m6"]:
		var r3 := Rect2(vl.lot_def(id3)["center"] - vl.lot_def(id3)["size"] * 0.5, vl.lot_def(id3)["size"])
		for f3 in vm.building_footprints:
			assert(not r3.intersects(f3["rect"]), "V3: Lot %s is clear of %s" % [id3, str(f3["id"])])
	var v3_a: Dictionary = vmi.attractiveness(vm)
	assert(v3_a.has("score") and (v3_a["parts"] as Dictionary).has("jobs"), "V3: The town has an attractiveness score")
	# Una casa construida acoge a un recién llegado, que no paga posada
	var v3_st: Dictionary = vl.lot(vm, "n0")
	var v3_saved: Dictionary = v3_st.duplicate(true)
	v3_st["status"] = "built"
	v3_st["kind"] = "house"
	v3_st["title"] = "🏠 Casa de prueba"
	v3_st["payer"] = "town"
	v3_st["beds"] = vl._house_beds("n0")
	v3_st["residents"] = []
	var v3_pop: int = vmi.population(vm)
	var v3_arr: int = vm.arrivals_today_count
	vm.arrivals_today_count = 0
	var v3_n = vmi._spawn_one(vm, vmi.SETTLER_KINDS[0], 0)
	assert(vmi.population(vm) == v3_pop + 1, "V3: A settler arrives")
	assert(vmi.move_into_house(vm, v3_n) and vmi.house_of(v3_n) == "n0" and v3_n.bed_position in v3_st["beds"], "V3: The settler moves into a free house")
	v3_n.personal_gold = 5
	var v3_tr: int = int(vm.town_state.get("treasury", 0))
	assert(vmi.nightly(vm, v3_n) and v3_n.personal_gold == 3 and int(vm.town_state["treasury"]) == v3_tr + 2, "V3: Town houses pay a small rent to the coffers")
	# Si el pueblo va mal, quien no tiene casa ni lazos se marcha
	v3_n.lodging = ""
	vmi.prune_residents(vm)
	assert((v3_st["residents"] as Array).is_empty(), "V3: Residents who left the house are pruned")
	v3_n.is_vagrant_camper = true
	assert(vmi.leave_chance(vm, v3_n, -0.5) > 0.2 and vmi.leave_chance(vm, v3_n, 0.6) == 0.0, "V3: Homeless people leave a failing town, not a good one")
	vmi.start_leaving(vm, v3_n)
	assert(v3_n.errand_kind == "leave", "V3: The leaver walks to the edge of the valley")
	var v3_dep: int = int(vmi.state(vm)["departures"])
	vmi.on_left(vm, v3_n)
	assert(int(vmi.state(vm)["departures"]) == v3_dep + 1 and vmi.population(vm) == v3_pop, "V3: Once at the edge, they are gone")
	for k3 in v3_saved.keys():
		v3_st[k3] = v3_saved[k3]
	v3_st["residents"] = []
	vm.arrivals_today_count = v3_arr
	print("V3 arrivals and departures OK")

	# 70. V6: el señor del valle y los rentistas; rentas de las tierras y peso en las elecciones.
	var vno = load("res://scripts/systems/VillageNobility.gd")
	assert(str(vl.lot(vm, "f1")["kind"]) == "mansion" and str(vl.lot(vm, "f2")["kind"]) == "manor", "V6: Mansion and manor stand on their lots")
	assert(vm.building_footprints.filter(func(f): return str(f["id"]) in ["building_mansion", "building_manor"]).size() == 2, "V6: Both noble houses are built")
	vno.spawn_households(vm)
	assert(vno.nobles(vm).size() == 5 and vno.lord_of(vm) != null, "V6: The lord's family and the rentiers live in the valley")
	var v6_lord = vno.lord_of(vm)
	assert(vno.is_noble(v6_lord) and v6_lord.family_id == vno.MANSION_FAMILY and v6_lord.bed_position in vno.beds("f1"), "V6: The lord lives and sleeps in the mansion (fam=%s bed=%s)" % [v6_lord.family_id, str(v6_lord.bed_position)])
	assert(v6_lord.person_profile != null and str(v6_lord.person_profile.partner_id) != "", "V6: The lord is married")
	# Rentas
	var v6_fr: int = vt.role_of("farmer")
	var v6_old = vm.trade_npcs.get(v6_fr)
	var v6_t = v5b_people[2]
	vm.trade_npcs[v6_fr] = v6_t
	var v6_rr: int = vt.role_of("rancher")
	var v6_rold = vm.trade_npcs.get(v6_rr)
	vm.trade_npcs.erase(v6_rr)
	var v6_tg: int = v6_t.personal_gold
	var v6_lg: int = v6_lord.personal_gold
	v6_t.personal_gold = 100
	var v6_res: Dictionary = vno.collect_rents(vm)
	assert(int(v6_res["paid"]) == 10 and v6_t.personal_gold == 90 and v6_lord.personal_gold == v6_lg + 10, "V6: The tenant pays rent to the lord")
	v6_t.personal_gold = 1
	var v6_rel: int = v6_lord.get_relationship_with_npc(v6_t.get_person_key())
	v6_res = vno.collect_rents(vm)
	assert(int(v6_res["unpaid"]) == 3 and v6_lord.get_relationship_with_npc(v6_t.get_person_key()) < v6_rel, "V6: A tenant who cannot pay angers the lord")
	# Elecciones: el arrendatario tira hacia el favorito del señor
	var v6_c1 = v5b_people[0]
	var v6_c2 = v5b_people[1]
	v6_lord.modify_npc_relationship(v6_c2, 80, "Prueba", true)
	v6_lord.modify_npc_relationship(v6_c1, -80, "Prueba", true)
	assert(vno.lord_favourite(vm, [v6_c1, v6_c2]) == v6_c2, "V6: The lord has a favourite")
	assert(vno.sway(vm, v6_t, v6_c2, [v6_c1, v6_c2]) > 0.0 and vno.sway(vm, v6_c1, v6_c2, [v6_c1, v6_c2]) == 0.0, "V6: Only those who live off the lord's land are swayed")
	# Si el señor falta, manda el mayor de su casa
	var v6_key: String = str(vno.state(vm)["lord"])
	vno.state(vm)["lord"] = "nadie"
	var v6_heir = vno.lord_of(vm)
	assert(v6_heir != null and v6_heir.family_id == vno.MANSION_FAMILY, "V6: A family member inherits the lordship")
	vno.state(vm)["lord"] = v6_key
	v6_t.personal_gold = v6_tg
	v6_lord.personal_gold = v6_lg
	if v6_old != null:
		vm.trade_npcs[v6_fr] = v6_old
	else:
		vm.trade_npcs.erase(v6_fr)
	if v6_rold != null:
		vm.trade_npcs[v6_rr] = v6_rold
	print("V6 nobles OK")

	# 71. V9: hijos. Embarazo, nacimiento con rasgos y apellido heredados, crecer, escuela y maestro.
	var vfm = load("res://scripts/systems/VillageFamily.gd")
	var v9_m = vmi._spawn_one(vm, {"label": "Madre de prueba", "gold": Vector2i(60, 60)}, 0)
	var v9_f = vmi._spawn_one(vm, {"label": "Padre de prueba", "gold": Vector2i(60, 60)}, 1)
	v9_m.person_profile.gender = "F"
	v9_f.person_profile.gender = "M"
	v9_m.person_profile.age = 28
	v9_f.person_profile.age = 30
	v9_m.person_profile.partner_id = str(v9_f.person_profile.person_id)
	v9_f.person_profile.partner_id = str(v9_m.person_profile.person_id)
	v9_m.family_id = "family_test_v9"
	v9_f.family_id = "family_test_v9"
	v9_m.modify_npc_relationship(v9_f, 70, "Prueba", true)
	v9_f.modify_npc_relationship(v9_m, 70, "Prueba", true)
	assert(vfm.conceive_chance(vm, v9_m, v9_f) > 0.0, "V9: A housed, loving couple can have a child")
	v9_m.person_profile.age = 50
	assert(vfm.conceive_chance(vm, v9_m, v9_f) == 0.0, "V9: Not past the age")
	v9_m.person_profile.age = 28
	vfm.start_pregnancy(vm, v9_m, v9_f)
	assert(vfm.conceive_chance(vm, v9_m, v9_f) == 0.0, "V9: Not while already expecting")
	vfm.state(vm)["pregnancies"][v9_m.get_person_key()]["due"] = vfm.today()
	var v9_births: int = int(vfm.state(vm)["births"])
	assert(vfm.process_births(vm) == 1 and int(vfm.state(vm)["births"]) == v9_births + 1, "V9: The baby is born when due")
	var v9_kid = vfm.children_of_family(vm, "family_test_v9")[0]
	assert(vfm.is_child(v9_kid) and int(v9_kid.person_profile.age) == 0 and v9_kid.npc_name.ends_with(vfm._surname(v9_f)), "V9: A newborn with the father's surname")
	assert(v9_kid.get_relationship_with_npc(v9_m.get_person_key()) > 50 and v9_kid.scale.x < 0.7, "V9: Loves its parents and is small")
	assert(vm.social_director.compute_compatibility(v9_kid.person_profile, v9_m.person_profile) == 0 and not vm.VillageTown.eligible(v9_kid), "V9: Children have no romance and do not run for mayor")
	# Crecer y escuela
	var v9_kid2 = vfm.give_birth(vm, v9_m, v9_f)
	vfm.state(vm)["born"][v9_kid.get_person_key()] = vfm.today() - 7 * vfm.CHILD_YEAR_DAYS
	vfm.state(vm)["born"][v9_kid2.get_person_key()] = vfm.today() - 8 * vfm.CHILD_YEAR_DAYS
	vfm.update_ages(vm)
	assert(int(v9_kid.person_profile.age) == 7 and int(v9_kid2.person_profile.age) == 8, "V9: Children grow a year every few days")
	var v9_old_t: String = str(vfm.state(vm)["teacher"])
	var v9_tr: int = int(vm.town_state.get("treasury", 0))
	vm.town_state["treasury"] = 100
	vfm.update_school(vm)
	var v9_t = vfm.teacher_of(vm)
	assert(v9_t != null and v9_kid.has_meta("school_pos") and v9_kid.work_position == v9_kid.get_meta("school_pos"), "V9: With two pupils there is a teacher and they go to school")
	vfm.state(vm)["born"][v9_kid2.get_person_key()] = vfm.today() - 16 * vfm.CHILD_YEAR_DAYS
	vfm.update_ages(vm)
	assert(not vfm.is_child(v9_kid2) and int(v9_kid2.person_profile.age) == 16, "V9: At sixteen they grow up")
	assert(vmi.nightly(vm, v9_kid2), "V9: A grown-up child still lives with the parents")
	vm.town_state["treasury"] = v9_tr
	for n9 in [v9_kid, v9_kid2, v9_m, v9_f]:
		vfm.state(vm)["born"].erase(n9.get_person_key())
		vm.unemployed_npcs.erase(n9)
		vm._free_transient_npc(n9)
	if v9_t != null and v9_old_t == "":
		vfm.state(vm)["teacher"] = ""
		if not v9_t in [v9_m, v9_f]:
			v9_t.trade_role = 0 # Vuelve a ser un vecino sin oficio
			vm.unemployed_npcs.append(v9_t)
	print("V9 children OK")

	# 72. UI1: el menú principal del diálogo es corto y agrupa el resto.
	var ui1_n = v5b_people[0]
	var ui1_d: Dictionary = ui1_n._inject_character_lore_into_dialogue(ui1_n._build_dialogue())
	var ui1_start: Array = ui1_d["start"]["choices"]
	assert(ui1_d.has("npc_ficha") and ui1_start.any(func(c): return str(c.get("next", "")) == "npc_ficha"), "UI1: There is a profile entry")
	assert(not ui1_start.any(func(c): return str(c.get("next", "")) in ["neighbor_opinions", "npc_news"]) and ui1_d.has("talk_menu"), "UI1: Small talk goes into its own submenu")
	assert(not str(ui1_d["start"]["text"]).contains("Rasgos:"), "UI1: The header is short")
	print("UI1 dialogue menu OK")

	# 73. Bloque B: hijo mayor que ayuda en el negocio de casa; niño que llega con su familia; cartel de la escuela.
	var b_m = vmi._spawn_one(vm, {"label": "Madre B", "gold": Vector2i(40, 40)}, 0)
	var b_role: int = vt.role_of("tailor")
	var b_old = vm.trade_npcs.get(b_role)
	var b_kin_old = vm.family_npcs.get(b_role)
	vm.family_npcs.erase(b_role)
	var b_owner = v5b_people[1]
	var b_owner_fam: String = b_owner.family_id
	var b_owner_role: int = int(b_owner.trade_role)
	b_owner.trade_role = b_role
	b_owner.family_id = "family_test_b"
	b_m.family_id = "family_test_b"
	var b_kid = vfm.spawn_child(vm, b_m, b_owner, 9)
	assert(int(b_kid.person_profile.age) == 9 and vfm.is_child(b_kid), "B2: A child can arrive already grown a bit")
	vfm.grow_up(vm, b_kid)
	assert(int(b_kid.trade_role) == int(load("res://scripts/enemies/VillageNPC.gd").TradeRole.FAMILY_MEMBER) and vm.family_npcs.get(b_role) == b_kid, "B3: A grown child helps in the family business")
	var b_lbl = vm.get_meta("school_sign", null)
	assert(b_lbl != null and is_instance_valid(b_lbl), "B1: The school has a sign to update")
	b_owner.trade_role = b_owner_role
	b_owner.family_id = b_owner_fam
	vm.family_npcs.erase(b_role)
	if b_kin_old != null:
		vm.family_npcs[b_role] = b_kin_old
	if b_old != null:
		vm.trade_npcs[b_role] = b_old
	for nb in [b_kid, b_m]:
		vm.unemployed_npcs.erase(nb)
		vm._free_transient_npc(nb)
	print("Block B loose ends OK")

	# 74. Guardar y cargar conserva a los nobles y a los niños (prefijos NPC_Noble_ y NPC_Child_).
	var s_m = vmi._spawn_one(vm, {"label": "Madre S", "gold": Vector2i(40, 40)}, 0)
	var s_kid = vfm.spawn_child(vm, s_m, null, 5)
	var s_kid_name: String = s_kid.npc_name
	var s_nobles: int = vno.nobles(vm).size()
	var s_path: String = "user://test_v9_save.json"
	assert(gm.save_game(s_path), "SAVE9: Save must succeed")
	assert(gm.load_game(s_path), "SAVE9: Load must succeed")
	await process_frame
	var s_back = null
	for nn in get_nodes_in_group("village_npcs"):
		if is_instance_valid(nn) and not nn.is_dead and nn.npc_name == s_kid_name:
			s_back = nn
	assert(s_back != null and vfm.is_child(s_back) and int(s_back.person_profile.age) == 5 and s_back.scale.x < 0.9, "SAVE9: The child survives a save and load")
	assert(vno.nobles(vm).size() == s_nobles, "SAVE9: The nobles survive a save and load (%d vs %d)" % [vno.nobles(vm).size(), s_nobles])
	print("Save and load of nobles and children OK")

	# 75. Bloque E: una pareja sin casa junta sus ahorros para encargarla; las camas de posada no se reparten dos veces.
	var ve_saved: Dictionary = {}
	for le in vl.LOTS:
		ve_saved[str(le["id"])] = vl.lot(vm, str(le["id"])).duplicate(true)
	var ve_tr: int = int(vm.town_state.get("treasury", 0))
	var ve_arr: int = vm.arrivals_today_count
	vm.arrivals_today_count = 0
	var ve_a = vmi._spawn_one(vm, vmi.SETTLER_KINDS[0], 0)
	var ve_b = vmi._spawn_one(vm, vmi.SETTLER_KINDS[0], 1)
	vfm.marry(ve_a, ve_b)
	for ve_h in vmi.residents(vm):
		if vmi.is_unemployed(ve_h):
			ve_h.personal_gold = mini(ve_h.personal_gold, 10)
	ve_a.personal_gold = 90
	ve_b.personal_gold = 40
	ve_a.is_vagrant_camper = true
	vm.town_state["treasury"] = 0
	assert(vl.active_site(vm) == "" and vmi.free_house_beds(vm) == 0, "E: Test starts with no site and no free house bed")
	var ve_id: String = vmi.maybe_order_house(vm, 0.5)
	assert(ve_id != "" and str(vl.lot(vm, ve_id)["payer"]) == ve_a.get_person_key(), "E: A couple pools its savings to order a house")
	assert(ve_a.personal_gold + ve_b.personal_gold == 130 - int(vl.KINDS["house"]["cost"]) and not vl.lot(vm, ve_id).has("loan"), "E: The house cost comes out of the couple's savings")
	# Una cama de posada ocupada por alguien con oficio (p. ej. el maestro) ya no cuenta como libre
	ve_b.trade_role = load("res://scripts/enemies/VillageNPC.gd").TradeRole.TEACHER
	ve_b.lodging = ""
	ve_b.bed_position = vmi.TAVERN_GUEST_BEDS[0]
	var ve_bed = vmi.free_tavern_bed(vm)
	assert(ve_bed == null or ve_bed != vmi.TAVERN_GUEST_BEDS[0], "E: A tavern bed held by a working resident is not handed out again")
	for le_id in ve_saved.keys():
		var le_st: Dictionary = vl.lot(vm, le_id)
		for k in (ve_saved[le_id] as Dictionary).keys():
			le_st[k] = ve_saved[le_id][k]
		vl._draw_lot(vm, le_id, le_st)
	vm.town_state["treasury"] = ve_tr
	vm.arrivals_today_count = ve_arr
	# E4: un íntimo te cuenta lo que siente su pareja por un tercero; sale «según» él hasta que lo confirmas
	var ve_c = vmi._spawn_one(vm, vmi.SETTLER_KINDS[0], 2)
	ve_b.feelings_all_known = false
	ve_b.known_feelings.clear()
	ve_b.heard_feelings.clear()
	ve_b.npc_relationships.clear()
	ve_a.npc_relationships[ve_b.get_person_key()] = 60
	ve_b.npc_relationships[ve_c.get_person_key()] = -70
	var ve_hf: Dictionary = load("res://scripts/enemies/NPCDialogue.gd")._hearsay_feeling(ve_a, ve_b, 60)
	assert(str(ve_hf.get("key", "")) == ve_c.get_person_key(), "E4: A close friend tells you a strong feeling of theirs")
	ve_b.hear_feeling_toward(ve_c.get_person_key(), ve_a.npc_name)
	assert(int(ve_b.heard_feelings[ve_c.get_person_key()]["rel"]) == -70 and not ve_b.knows_feeling_toward(ve_c.get_person_key()), "E4: It is noted as hearsay, not as known")
	ve_b.learn_feeling_toward(ve_c.get_person_key())
	assert(not ve_b.heard_feelings.has(ve_c.get_person_key()), "E4: Asking them yourself replaces the hearsay")
	for ve_n in [ve_a, ve_b, ve_c]:
		vm.unemployed_npcs.erase(ve_n)
		ve_n.queue_free()
	print("Block E house pooling and tavern beds OK")

	# 76. Bloque F: el dueño contrata jornaleros según el hueco del almacén y se guarda dinero para comer.
	var vwf = load("res://scripts/systems/VillageWork.gd")
	var vf_m = vm.trade_npcs.get(vt.role_of("farmer"))
	if vf_m == null or not is_instance_valid(vf_m):
		vf_m = v5d_master # la granja empieza vacante; solo se mira su almacén
	var vf_stock: Dictionary = vf_m.shop_stock.duplicate()
	vf_m.shop_stock["wheat"] = vwf.STOCK_CAP
	assert(vwf.workers_needed(vf_m, "farmer") == 0, "F: A full barn hires nobody")
	vf_m.shop_stock["wheat"] = vwf.STOCK_CAP - 2
	assert(vwf.workers_needed(vf_m, "farmer") == 1, "F: A nearly full barn hires one laborer")
	vf_m.shop_stock["wheat"] = 0
	assert(vwf.workers_needed(vf_m, "farmer") >= 4, "F: An empty barn wants every spot filled")
	vf_m.shop_stock = vf_stock
	print("Block F need-based hiring OK")

	# 77. Bloque G: el ayudante del negocio familiar recibe su parte del dueño.
	var vg_h = null
	for vg_n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if vg_h == null and int(vg_n.trade_role) == int(load("res://scripts/enemies/VillageNPC.gd").TradeRole.FAMILY_MEMBER) and not vg_n.is_dead:
			for vg_r in vm.trade_npcs.keys():
				var vg_o = vm.trade_npcs[vg_r]
				if vg_o != null and is_instance_valid(vg_o) and vg_o.family_id == vg_n.family_id and vg_o != vg_n:
					vg_h = vg_n
	assert(vg_h != null, "G: Some shop has a family helper")
	var vg_owner = null
	for vg_r2 in vm.trade_npcs.keys():
		var vg_o2 = vm.trade_npcs[vg_r2]
		if vg_owner == null and vg_o2 != null and is_instance_valid(vg_o2) and vg_o2.family_id == vg_h.family_id and vg_o2 != vg_h:
			vg_owner = vg_o2
	var vg_hg: int = vg_h.personal_gold
	var vg_og: int = vg_owner.personal_gold
	vg_h.personal_gold = 0
	vg_owner.personal_gold = 100
	vfm.pay_helpers(vm)
	assert(vg_h.personal_gold == vfm.HELPER_SHARE and vg_owner.personal_gold <= 100 - vfm.HELPER_SHARE, "G: The helper gets a share from the family shop")
	vg_h.personal_gold = 0
	vg_owner.personal_gold = 10
	vfm.pay_helpers(vm)
	assert(vg_h.personal_gold == 0, "G: A broke owner keeps what they need to eat")
	vg_h.personal_gold = vg_hg
	vg_owner.personal_gold = vg_og
	print("Block G family helpers paid OK")

	# 78. Bloque H: casas a plazos con interés; cuotas, recargo y desahucio; el noble presta si las arcas no pueden.
	var vln = load("res://scripts/systems/VillageLoans.gd")
	var vh_saved: Dictionary = {}
	for lh in vl.LOTS:
		vh_saved[str(lh["id"])] = vl.lot(vm, str(lh["id"])).duplicate(true)
	var vh_tr: int = int(vm.town_state.get("treasury", 0))
	var vh_arr: int = vm.arrivals_today_count
	vm.arrivals_today_count = 0
	var vh_b = vmi._spawn_one(vm, vmi.SETTLER_KINDS[0], 0)
	for vh_h in vmi.residents(vm):
		if vmi.is_unemployed(vh_h) and vh_h != vh_b:
			vh_h.personal_gold = mini(vh_h.personal_gold, 10)
	vh_b.personal_gold = 30
	vh_b.is_vagrant_camper = true
	vm.town_state["treasury"] = 200
	var vh_id: String = vmi.maybe_order_house(vm, 0.5)
	assert(vh_id != "" and vl.lot(vm, vh_id).has("loan"), "H: With only the down payment, the house is bought on credit")
	var vh_loan: Dictionary = vl.lot(vm, vh_id)["loan"]
	assert(str(vh_loan["lender"]) == "town" and int(vh_loan["owed"]) == int(round(float(int(vh_loan["principal"])) * 1.25)) and vh_b.personal_gold == 5, "H: The town lends the rest at 25 %% interest (owes %d, has %d)" % [int(vh_loan["owed"]), vh_b.personal_gold])
	assert(vln.debt_text(vm, vh_b).begins_with("🏦 Debe"), "H: The debt shows on the villager's card")
	var vh_owed: int = int(vh_loan["owed"])
	var vh_t1: int = int(vm.town_state["treasury"])
	vln.daily(vm)
	assert(int(vh_loan["owed"]) == vh_owed - vln.INSTALLMENT and int(vm.town_state["treasury"]) == vh_t1 + vln.INSTALLMENT, "H: A daily installment goes back to the lender")
	vh_b.personal_gold = 0
	for _dh in range(vln.MAX_MISSED - 1):
		vln.daily(vm)
	assert(int(vh_loan["missed"]) == vln.MAX_MISSED - 1 and int(vh_loan["owed"]) == vh_owed - vln.INSTALLMENT + vln.MAX_MISSED - 1, "H: Missed installments add a late fee")
	vln.daily(vm)
	assert(not vl.lot(vm, vh_id).has("loan") and str(vl.lot(vm, vh_id)["payer"]) == "town", "H: Too many missed installments and the lender takes the house")
	vm.town_state["treasury"] = 0
	var vh_nob = null
	for vh_n in vm.VillageNobility.nobles(vm):
		if vh_nob == null:
			vh_nob = vh_n
	assert(vh_nob != null, "H: There is a noble to borrow from")
	var vh_ng: int = vh_nob.personal_gold
	vh_nob.personal_gold = 100000
	assert(str(vln.find_lender(vm, 80).get("key", "")) == vh_nob.get_person_key(), "H: With empty coffers, the richest noble lends")
	vh_nob.personal_gold = vh_ng
	for lh_id in vh_saved.keys():
		var lh_st: Dictionary = vl.lot(vm, lh_id)
		lh_st.erase("loan")
		for k in (vh_saved[lh_id] as Dictionary).keys():
			lh_st[k] = vh_saved[lh_id][k]
		vl._draw_lot(vm, lh_id, lh_st)
	vm.town_state["treasury"] = vh_tr
	vm.arrivals_today_count = vh_arr
	vm.unemployed_npcs.erase(vh_b)
	vh_b.queue_free()
	print("Block H house loans OK")

	# 79. Bloque J: jabalíes, causa de muerte a la vista, arcas iniciales y gachas del albergue.
	var vnpc = load("res://scripts/enemies/VillageNPC.gd")
	var vj_boar = null
	for vj_a in get_nodes_in_group("ecosystem_boars"):
		if vj_boar == null and vj_a.is_alive_in_ecosystem():
			vj_boar = vj_a
	assert(vj_boar != null, "J: There is a live boar")
	assert(vnpc.death_cause_for_source(vj_boar) == "Embestida de jabalí" and vnpc.is_natural_death_cause("Embestida de jabalí") and not vnpc.is_natural_death_cause("Puñalada (cuchillo)"), "J2: A boar wound is named and is not a crime")
	var vj_h = vmi._spawn_one(vm, vmi.SETTLER_KINDS[0], 0)
	var vj_bs = vj_boar.state
	vj_boar.state = load("res://scripts/enemies/WildAnimal.gd").AnimalState.CHARGE_ATTACK
	vj_boar.boar_aggressor = vj_h
	vj_boar.boar_aggro_timer = 11.0
	vj_h.health_comp.current_health = vj_h.health_comp.max_health * 0.9
	assert(not vj_h.should_flee_boar(vj_boar), "J1: A healthy hunter keeps going")
	vj_h.health_comp.current_health = vj_h.health_comp.max_health * 0.4
	assert(vj_h.should_flee_boar(vj_boar), "J1: A badly hurt hunter retreats from a charging boar")
	vj_h.flee_from_boar(vj_boar)
	assert(vj_boar.boar_aggro_timer <= 2.0, "J1: The boar loses interest in someone running away")
	vj_boar.state = vj_bs
	vj_boar.boar_aggressor = null
	vj_boar.boar_aggro_timer = 0.0
	# Muerte por animal: no se abre caso y la crónica lo dice
	var vj_was: bool = bool(vm.active_sheriff_investigation.get("active", false))
	load("res://scripts/systems/VillageJustice.gd").start_sheriff_investigation(vm, vj_h, vj_h.global_position, "Embestida de jabalí", "Prueba")
	assert(bool(vm.active_sheriff_investigation.get("active", false)) == vj_was, "J2: No murder case for a death by boar")
	assert(str(vm.chronicle[vm.chronicle.size() - 1]["text"]).contains("lo mató un jabalí"), "J2: The chronicle says what killed them")
	# Arcas de partida nueva y gachas
	assert(load("res://scripts/systems/VillageTown.gd").STARTING_TREASURY == 1000, "J3: A new town starts with 1000 gold")
	var vcv = load("res://scripts/systems/VillageCivic.gd")
	var vj_tr: int = int(vm.town_state.get("treasury", 0))
	vm.town_state["treasury"] = 100
	var vj_made: int = vcv.cook_shelter_rations(vm)
	assert(vj_made >= vcv.RATION_EXTRA and vj_made <= vcv.RATION_MAX and int(vm.town_state["treasury"]) == 100 - vj_made * vcv.RATION_COST_TOWN, "J4: The shelter cooks rations paid by the coffers (%d)" % vj_made)
	vj_h.personal_gold = 0
	assert(vcv.take_shelter_ration(vm, vj_h) and int(vm.town_state["shelter_rations"]) == vj_made - 1, "J4: A penniless villager eats porridge for free")
	vm.town_state["shelter_rations"] = 0
	assert(not vcv.take_shelter_ration(vm, vj_h), "J4: No porridge left, no meal")
	vm.town_state["treasury"] = vj_tr
	vm.unemployed_npcs.erase(vj_h)
	vj_h.queue_free()
	print("Block J boars, causes of death and porridge OK")

	# 80. Bloque K: el cantero trabaja en la roca y las obras compran piedra y troncos.
	var vk_q = vm.trade_npcs.get(vt.role_of("quarry"))
	var vk_tmp: bool = vk_q == null or not is_instance_valid(vk_q)
	if vk_tmp:
		vk_q = vmi._spawn_one(vm, vmi.SETTLER_KINDS[0], 0)
		vm.trade_npcs[vt.role_of("quarry")] = vk_q
	vt.fix_quarry_post(vm)
	assert(vk_q.work_position.distance_to(vt.yard_pos("w1")) < 1.0 and vt.yard_pos("w1").x > vl.building_center("w1").x, "K1: The quarryman works out on the rock")
	var vk_stock: Dictionary = vk_q.shop_stock.duplicate()
	var vk_g: int = vk_q.personal_gold
	vk_q.shop_stock["stone"] = 5
	var vk_spent: int = vl.buy_materials(vm, 100)
	assert(vk_spent >= 20 and int(vk_q.shop_stock["stone"]) == 2 and vk_q.personal_gold == vk_g + 20, "K1: A build buys stone from the quarry")
	vk_q.shop_stock = vk_stock
	vk_q.personal_gold = vk_g
	if vk_tmp:
		vm.trade_npcs.erase(vt.role_of("quarry"))
		vm.unemployed_npcs.erase(vk_q)
		vk_q.queue_free()
	print("Block K quarry at work OK")

	# 81. Bloque M: tipos de misión nuevos (aprendiz, medicina, fe).
	assert(q_reg.all_types().size() == 25, "M: 25 quest types registered")
	var vm_y = vmi._spawn_one(vm, vmi.SETTLER_KINDS[0], 0)
	var vm_own = vm.trade_npcs.get(int(load("res://scripts/enemies/VillageNPC.gd").TradeRole.BAKER))
	var vm_fam_before = vm.family_npcs.get(int(vm_own.trade_role))
	q_reg.get_type("apprentice").hire(vm, vm_own, vm_y)
	assert(int(vm_y.trade_role) == int(load("res://scripts/enemies/VillageNPC.gd").TradeRole.FAMILY_MEMBER) and vm.family_npcs[int(vm_own.trade_role)] == vm_y and not vm.unemployed_npcs.has(vm_y), "M8: The apprentice joins the shop as helper")
	var vm_q: Dictionary = {"giver_key": vm_y.get_person_key(), "target_key": vm_y.get_person_key(), "data": {"invited_week": 3}}
	var vm_ill = load("res://scripts/systems/VillageIllness.gd")
	vm_ill.infect(vm, vm_y.get_person_key(), "cold")
	assert(not q_reg.get_type("poor_medicine").is_done(vm, vm_q), "M6: Ill and untreated is not done")
	vm_ill.treat(vm, vm_y.get_person_key())
	assert(q_reg.get_type("poor_medicine").is_done(vm, vm_q), "M6: Treated counts as done")
	vm_ill.recover(vm, vm_y.get_person_key())
	var vm_fst: Dictionary = load("res://scripts/systems/VillageFaith.gd")._state(vm)
	var vm_fsave: Array = [vm_fst.get("last_rite_day", -1), vm_fst.get("last_attendees", [])]
	vm_fst["last_rite_day"] = 3 * 7 + 1
	vm_fst["last_attendees"] = [vm_y.get_person_key()]
	assert(q_reg.get_type("faith_doubt").is_done(vm, vm_q), "M7: Coming to the invited rite completes it")
	vm_fst["last_rite_day"] = vm_fsave[0]
	vm_fst["last_attendees"] = vm_fsave[1]
	vm.family_npcs[int(vm_own.trade_role)] = vm_fam_before
	if vm_fam_before == null:
		vm.family_npcs.erase(int(vm_own.trade_role))
	# M2: la taberna no sirve a quien está vetado; las gachas donadas se cocinan; el puesto del mercado se llena
	var vm_nd = load("res://scripts/systems/VillageNeeds.gd")
	var vm_ns_save = vm_nd.state(vm).get("no_serve", {}).duplicate()
	vm_nd.state(vm)["no_serve"] = {vm_y.get_person_key(): vm_nd.today() + 3}
	vm_y.personal_gold = 50
	assert(int(vm_nd.do_vice(vm, vm_y, "drink").get("gold", 0)) == 0 and vm_y.personal_gold == 50, "M14: A banned drinker is not served")
	vm_nd.state(vm)["no_serve"] = vm_ns_save
	var vm_rat: int = int(vm.town_state.get("shelter_rations", 0))
	var vm_pq: Dictionary = {"data": {"raised": 0}}
	q_reg.get_type("empty_pots").donate(vm, vm_pq, 10)
	assert(int(vm.town_state["shelter_rations"]) == vm_rat + 5 and q_reg.get_type("empty_pots").is_done(vm, {"data": {"raised": 20}}), "M11: 10 gold of donations cooks 5 more rations")
	vm.town_state["shelter_rations"] = vm_rat
	var vm_mk_st: Dictionary = vm_own.shop_stock.duplicate()
	q_reg.get_type("market_stall").restock(vm_own)
	assert(load("res://scripts/systems/VillageCulture.gd")._surplus(vm_own) >= load("res://scripts/systems/VillageCulture.gd").MARKET_MIN_STOCK, "M15: Restocked shop has enough for a stall")
	vm_own.shop_stock = vm_mk_st
	vm_y.is_vagrant_camper = true
	vm_y.in_shelter = false
	var vm_hq: Dictionary = {"giver_key": vm_y.get_person_key()}
	assert(not q_reg.get_type("homeless").is_done(vm, vm_hq), "M18: Sleeping rough is not done")
	vm_y.is_vagrant_camper = false
	assert(q_reg.get_type("homeless").is_done(vm, vm_hq), "M18: A roof completes it")
	vm_y.set_meta("evicted_day", 12)
	vm_y.set_meta("evicted_lot", "n0")
	vm_y.set_meta("inherited_day", 9)
	vm_y.set_meta("inherited_from", "Abuelo")
	vm_y.set_meta("inherited_family", "family_baker")
	vm_y.set_meta("read_day", 11)
	vm_y.set_meta("arrived_day", 5)
	vm_y.set_meta("rite_invited_week", 2)
	var vm_saved_npc: Dictionary = vm_y.to_save_dict()
	for mk_clr in ["evicted_day", "evicted_lot", "inherited_day", "inherited_from", "inherited_family", "read_day", "arrived_day", "rite_invited_week"]:
		vm_y.remove_meta(mk_clr)
	vm_y.from_save_dict(vm_saved_npc)
	assert(int(vm_y.get_meta("evicted_day", -1)) == 12 and str(vm_y.get_meta("evicted_lot", "")) == "n0" and int(vm_y.get_meta("inherited_day", -1)) == 9 and str(vm_y.get_meta("inherited_from", "")) == "Abuelo" and str(vm_y.get_meta("inherited_family", "")) == "family_baker" and int(vm_y.get_meta("read_day", -1)) == 11 and int(vm_y.get_meta("arrived_day", -1)) == 5 and int(vm_y.get_meta("rite_invited_week", -1)) == 2, "M: Quest marks persist across save and load")
	# Pruebas funcionales de las 13 misiones nuevas que estaban en 🟡
	# M1 affair_doubt: requiere testigo en known_by y se completa al encontrarlo
	var m1_sec_bak: Array = vm.secrets.duplicate(true)
	vm.secrets.clear()
	vm.secrets.append({"id": 777, "type": "affair", "a": vm_own.get_person_key(), "b": vm_y.get_person_key(), "partner": "partner_test", "a_name": vm_own.npc_name, "b_name": vm_y.npc_name, "p_name": "Pareja", "active": true, "known_by": {}, "player_knows": false})
	var m1_partner_bak: String = str(vm_y.person_profile.partner_id)
	vm_y.person_profile.partner_id = vm_own.get_person_key()
	assert(q_reg.get_type("affair_doubt").find_daily_offer(vm, vm_y, [], {}).is_empty(), "M1: Affair without witnesses is not offered")
	vm.secrets[0]["known_by"] = {"witness_x": 1}
	assert(not q_reg.get_type("affair_doubt").find_daily_offer(vm, vm_y, [], {}).is_empty(), "M1: Affair with a witness is offered")
	assert(not q_reg.get_type("affair_doubt").is_done(vm, {"data": {"secret_id": 777, "found": false}}) and q_reg.get_type("affair_doubt").is_done(vm, {"data": {"secret_id": 777, "found": true}}), "M1: Affair doubt completion check")
	vm_y.person_profile.partner_id = m1_partner_bak
	vm.secrets.clear()
	for s_bak in m1_sec_bak:
		vm.secrets.append(s_bak)
	# M2 loan_trouble: con cuotas atrasadas no está hecha; con missed=0 sí, y no rompe diálogo tras desahucio
	var m2_lot: Dictionary = vl.lot(vm, "n0")
	var m2_lot_bak: Dictionary = m2_lot.duplicate(true)
	m2_lot["payer"] = vm_y.get_person_key()
	m2_lot["loan"] = {"lender": "town", "lender_name": "el pueblo", "owed": 60, "missed": 2, "principal": 50}
	var m2_q: Dictionary = {"id": "q_m2", "giver_key": vm_y.get_person_key(), "giver_name": vm_y.npc_name, "target_key": "", "data": {"lot": "n0"}}
	assert(not q_reg.get_type("loan_trouble").find_daily_offer(vm, vm_y, [], {}).is_empty() and not q_reg.get_type("loan_trouble").is_done(vm, m2_q), "M2: Offered and pending when missed >= 2")
	m2_lot["loan"]["missed"] = 0
	assert(q_reg.get_type("loan_trouble").is_done(vm, m2_q), "M2: Done when missed == 0")
	m2_lot.erase("loan")
	m2_lot["payer"] = "town"
	var m2_ch: Array = []
	q_reg.get_type("loan_trouble").add_world_dialogue(vm, vm_y, m2_q, {}, m2_ch)
	assert(m2_ch.is_empty(), "M2: No crash in dialogue after eviction")
	m2_lot.clear()
	for k2 in m2_lot_bak.keys():
		m2_lot[k2] = m2_lot_bak[k2]
	# M3 boar_hunt: se cumple al bajar el número de jabalíes vivos
	var m3_now: int = q_reg.get_type("boar_hunt").live_boars(vm)
	assert(not q_reg.get_type("boar_hunt").is_done(vm, {"data": {"start_boars": m3_now}}) and q_reg.get_type("boar_hunt").is_done(vm, {"data": {"start_boars": m3_now + 1}}), "M3: Boar hunt checks live boars")
	# M4 vote_buying: cuenta promesas de voto en town_state.pledges
	var m4_pl_bak: Dictionary = (vm.town_state.get("pledges", {}) as Dictionary).duplicate()
	vm.town_state["pledges"] = {"v1": vm_y.get_person_key(), "v2": vm_y.get_person_key()}
	var m4_q: Dictionary = {"giver_key": vm_y.get_person_key(), "data": {"election_day": 99}}
	assert(not q_reg.get_type("vote_buying").is_done(vm, m4_q), "M4: 2 pledges is not enough")
	vm.town_state["pledges"]["v3"] = vm_y.get_person_key()
	assert(q_reg.get_type("vote_buying").is_done(vm, m4_q), "M4: 3 pledges completes vote_buying")
	vm.town_state["pledges"] = m4_pl_bak
	# M5 embezzle_proof: 2 testigos completan la misión
	assert(not q_reg.get_type("embezzle_proof").is_done(vm, {"data": {"proofs": ["a"]}}) and q_reg.get_type("embezzle_proof").is_done(vm, {"data": {"proofs": ["a", "b"]}}), "M5: Embezzle proof requires 2 witnesses")
	# M9 sabotage_job: se cumple si se denuncia o si el puesto rival queda saboteado
	var m9_role: int = int(vm_own.trade_role)
	var m9_sab_bak: int = int(vm.shop_businesses[m9_role].get("sabotaged_days", 0))
	vm.shop_businesses[m9_role]["sabotaged_days"] = 0
	var m9_q: Dictionary = {"data": {"role": m9_role, "reported": false}}
	assert(not q_reg.get_type("sabotage_job").is_done(vm, m9_q), "M9: Unsabotaged and unreported is not done")
	vm.shop_businesses[m9_role]["sabotaged_days"] = 2
	assert(q_reg.get_type("sabotage_job").is_done(vm, m9_q), "M9: Sabotaging the target shop completes it")
	vm.shop_businesses[m9_role]["sabotaged_days"] = m9_sab_bak
	# M10 scared_witness: pedir protección al comisario añade pista y sube sospecha del asesino real
	var m10_inv_bak: Dictionary = vm.active_sheriff_investigation.duplicate(true)
	var m10_mur_bak: Dictionary = vm.npc_murders.duplicate(true)
	vm.npc_murders["Víctima M10"] = vm_own.npc_name
	vm.active_sheriff_investigation = {"active": true, "victim_name": "Víctima M10", "reporter_name": vm_y.npc_name, "suspects": {vm_own.npc_name: {"score": 10}}, "clues_log": []}
	var m10_qm = get_root().get_node_or_null("/root/QuestManager")
	var m10_qid: String = m10_qm.add_quest({"category": "side", "type": "scared_witness", "title": "T", "description": "D", "giver_key": vm_y.get_person_key(), "giver_name": vm_y.npc_name, "target_key": "", "target_name": "Víctima M10", "data": {"victim": "Víctima M10", "protected": false}})
	q_reg.get_type("scared_witness").on_extra_action(vm, m10_qm, vm_own, "quest_witness_protect:" + m10_qid)
	assert(q_reg.get_type("scared_witness").is_done(vm, m10_qm.get_quest(m10_qid)) and int(vm.active_sheriff_investigation["suspects"][vm_own.npc_name]["score"]) == 25, "M10: Protecting witness boosts real killer suspect score")
	m10_qm.quests.erase(m10_qid)
	vm.active_sheriff_investigation = m10_inv_bak
	vm.npc_murders = m10_mur_bak
	# M12 love_letter: entregar la carta aviva la chispa si ya había interés
	var m12_qid: String = m10_qm.add_quest({"category": "side", "type": "love_letter", "title": "T", "description": "D", "giver_key": vm_y.get_person_key(), "giver_name": vm_y.npc_name, "target_key": vm_own.get_person_key(), "target_name": vm_own.npc_name, "data": {"answer": "", "read": false}})
	var m12_sp0: int = vm.social_director.get_spark(vm_own.get_person_key(), vm_y.get_person_key())
	vm.social_director.add_spark_one_way(vm_own.get_person_key(), vm_y.get_person_key(), 10)
	var m12_sp1: int = vm.social_director.get_spark(vm_own.get_person_key(), vm_y.get_person_key())
	q_reg.get_type("love_letter").on_extra_action(vm, m10_qm, vm_own, "quest_letter_give:" + m12_qid)
	assert(str(m10_qm.get_quest(m12_qid)["data"]["answer"]) == "yes" and vm.social_director.get_spark(vm_own.get_person_key(), vm_y.get_person_key()) > m12_sp1, "M12: Love letter fans existing spark")
	vm.social_director.add_spark_one_way(vm_own.get_person_key(), vm_y.get_person_key(), m12_sp0 - vm.social_director.get_spark(vm_own.get_person_key(), vm_y.get_person_key()))
	m10_qm.quests.erase(m12_qid)
	# M13 inheritance: el heredero reparte 15 de oro con el pariente
	var m13_qid: String = m10_qm.add_quest({"category": "side", "type": "inheritance", "title": "T", "description": "D", "giver_key": vm_y.get_person_key(), "giver_name": vm_y.npc_name, "target_key": vm_own.get_person_key(), "target_name": vm_own.npc_name, "data": {"dead_name": "Tío", "role": int(vm_own.trade_role), "result": ""}})
	var m13_og: int = vm_own.personal_gold
	var m13_yg: int = vm_y.personal_gold
	var m13_af: int = vm_own.affinity
	vm_own.personal_gold = 50
	vm_own.affinity = 25
	q_reg.get_type("inheritance").on_extra_action(vm, m10_qm, vm_own, "quest_inherit_share:" + m13_qid)
	assert(q_reg.get_type("inheritance").is_done(vm, m10_qm.get_quest(m13_qid)) and vm_y.personal_gold == m13_yg + 15 and vm_own.personal_gold == 35, "M13: Heir shares 15 gold with relative")
	vm_own.personal_gold = m13_og
	vm_y.personal_gold = m13_yg
	vm_own.affinity = m13_af
	m10_qm.quests.erase(m13_qid)
	# M16 night_reading: se cumple al conocer la secta
	var m16_sect_bak: Dictionary = vm.sect_state.duplicate(true)
	load("res://scripts/systems/VillageSect.gd").state(vm)["active"] = true
	load("res://scripts/systems/VillageSect.gd").state(vm)["player_knows"] = false
	assert(not q_reg.get_type("night_reading").is_done(vm, {}), "M16: Unknown sect is not done")
	load("res://scripts/systems/VillageSect.gd").state(vm)["player_knows"] = true
	assert(q_reg.get_type("night_reading").is_done(vm, {}), "M16: Knowing the sect completes night_reading")
	vm.sect_state = m16_sect_bak
	# M17 announced_fight: calmar a un rival baja la tensión del par
	var m17_pk: String = vm.social_director.make_pair_key(vm_y.get_person_key(), vm_own.get_person_key())
	var m17_pe: Dictionary = vm.social_director.get_pair_entry(vm_y.get_person_key(), vm_own.get_person_key())
	var m17_t0: int = int(m17_pe.get("tension", 0))
	m17_pe["tension"] = 22
	var m17_qid: String = m10_qm.add_quest({"category": "side", "type": "announced_fight", "title": "T", "description": "D", "giver_key": "g", "giver_name": "G", "target_key": vm_y.get_person_key(), "target_name": vm_y.npc_name, "data": {"foe_key": vm_own.get_person_key(), "foe_name": vm_own.npc_name, "fights": int(m17_pe.get("fights_count", 0)), "calmed": []}})
	assert(not q_reg.get_type("announced_fight").is_done(vm, m10_qm.get_quest(m17_qid)), "M17: Tension 22 is not done")
	q_reg.get_type("announced_fight").on_extra_action(vm, m10_qm, vm_y, "quest_fight_calm:" + m17_qid)
	assert(q_reg.get_type("announced_fight").is_done(vm, m10_qm.get_quest(m17_qid)), "M17: Calming drops tension <= 14 and completes quest")
	m17_pe["tension"] = m17_t0
	m10_qm.quests.erase(m17_qid)
	# M19 strange_newcomer: charlar o descubrir 2 rasgos cumple la misión
	vm_y.known_traits.clear()
	var m19_q: Dictionary = {"target_key": vm_y.get_person_key(), "data": q_reg.get_type("strange_newcomer").init_data(vm, vm_own, {"target_key": vm_y.get_person_key()})}
	assert(not q_reg.get_type("strange_newcomer").is_done(vm, m19_q), "M19: 0 traits known is not done")
	load("res://scripts/systems/TraitDiscovery.gd").reveal_next(vm_y, "test")
	load("res://scripts/systems/TraitDiscovery.gd").reveal_next(vm_y, "test")
	assert(q_reg.get_type("strange_newcomer").is_done(vm, m19_q), "M19: Discovering 2 traits completes strange_newcomer")
	# M20 nameless_grave: 2 testimonios completan la misión
	assert(not q_reg.get_type("nameless_grave").is_done(vm, {"data": {"witnesses": ["w1"]}}) and q_reg.get_type("nameless_grave").is_done(vm, {"data": {"witnesses": ["w1", "w2"]}}), "M20: 2 witnesses complete nameless_grave")
	# K2: el atajo «📜 Encargo» sale para peace/opinion/slander pero no contamina otras misiones
	var k2_qid: String = m10_qm.add_quest({"category": "side", "type": "slander", "title": "T", "description": "D", "giver_key": vm_own.get_person_key(), "giver_name": vm_own.npc_name, "target_key": vm_y.get_person_key(), "target_name": vm_y.npc_name, "data": {"slandered_to": []}})
	var k2_listener = v5b_people[0]
	var k2_af_bak: int = k2_listener.affinity
	k2_listener.affinity = 20
	var k2_diag: Dictionary = k2_listener._inject_character_lore_into_dialogue({"start": {"text": "Hola", "choices": [{"label": "[Salir]", "next": "END"}]}})
	assert((k2_diag["start"]["choices"] as Array).any(func(c): return str(c.get("label", "")).begins_with("📜 Encargo: hablarle de " + vm_y.npc_name)), "K2: Slander quest shows shortcut for target on third-party listener")
	k2_listener.affinity = k2_af_bak
	m10_qm.quests.erase(k2_qid)
	vm_y.queue_free()
	print("Block M quest types OK")

	# 82. Bloques P1–P7 (70 mecánicas: clanes, forense, linaje, confesión, alcaldía, vivienda y bajos fondos).
	var p70_pl = get_first_node_in_group("player")
	var p70_inv = p70_pl.inventory if p70_pl != null else load("res://scripts/systems/SimpleInventory.gd").new()
	p70_inv.gold = 500
	var p70_a = v5b_people[0]
	var p70_b = v5b_people[1]
	var p70_c = v5b_people[2]
	var p70_fam_a_bak: String = p70_a.family_id
	var p70_fam_b_bak: String = p70_b.family_id
	p70_a.family_id = "family_clan_a"
	p70_b.family_id = "family_clan_b"
	# P1: Clanes, feudo de sangre, deuda de honor y huérfano vengador
	var vcl = vm.VillageClans
	vcl.declare_blood_feud(vm, "family_clan_a", "family_clan_b", "prueba P1")
	var p1_fk: String = vcl.feud_key("family_clan_a", "family_clan_b")
	assert(vcl.state(vm)["feuds"].has(p1_fk), "P1: Blood feud declared between clans")
	assert(vcl.mediate_clan_peace(vm, p1_fk, "prueba P1") and not vcl.state(vm)["feuds"].has(p1_fk), "P1: Clan peace mediated")
	vcl.grant_honor_debt(vm, p70_a, "salvó su vida")
	assert(vcl.player_price_mult(vm, p70_a) < 1.0, "P1: Honor debt grants family discount")
	var p1_kid = vfm.spawn_child(vm, p70_a, null, 15)
	vcl.on_murder_resolved(vm, p70_a.npc_name, p70_b.npc_name)
	assert(vcl.state(vm)["orphan_killers"].has(p1_kid.get_person_key()), "P1: Orphan remembers parent's killer")
	vcl.on_child_grown_up(vm, p1_kid)
	assert(not vde.active_of(vm, p1_kid.get_person_key()).is_empty(), "P1: Grown orphan starts revenge desire against parent's killer")
	# Auditoría: el culpable sale del texto de cierre sin confundirlo con el comisario que firma
	assert(vcl.culprit_from_note("Caso Archivado por el Comisario Vane (Sin pruebas)") == "" and vcl.culprit_from_note("Ana (Arrestado por el Comisario Vane: 60%)") == "Ana" and vcl.culprit_from_note("Jugador (Declarado culpable por el Comisario Vane: 50%)") == "player" and vcl.culprit_from_note("Confesión de Ana (delatado ante la guardia)") == "Ana", "P1 audit: culprit parsed from closing note, never the sheriff")
	# P2: Forense, pistas falsas, coartadas y desmontar prueba
	var vfo = vm.VillageForensics
	vfo.state(vm)["planted"][p70_a.npc_name] = {"framed_name": p70_c.npc_name, "framed_key": p70_c.get_person_key(), "killer_name": p70_b.npc_name, "debunked": false}
	vfo.state(vm)["alibis"][p70_a.npc_name] = {"ally_key": p70_c.get_person_key(), "ally_name": p70_c.npc_name, "killer_name": p70_b.npc_name, "broken": false}
	vm.npc_murders[p70_a.npc_name] = p70_b.npc_name
	var p2_case: Dictionary = {"active": true, "victim_name": p70_a.npc_name, "reporter_name": p70_c.npc_name, "suspects": {p70_b.npc_name: {"score": 30}, p70_c.npc_name: {"score": 10}}, "clues_log": []}
	vfo.apply_to_case(vm, p70_a, p2_case)
	assert(int(p2_case["suspects"][p70_c.npc_name]["score"]) == 30 and int(p2_case["suspects"][p70_b.npc_name]["score"]) == 15, "P2: Planted clue raises framed suspect and false alibi lowers killer")
	var p2_inv_bak: Dictionary = vm.active_sheriff_investigation.duplicate(true)
	vm.active_sheriff_investigation = p2_case
	# Auditoría: el menú del comisario no nombra al asesino real antes de que el jugador lo averigüe
	vfo.state(vm)["moved"][p70_a.npc_name] = {"orig_x": 0.0, "orig_y": 0.0, "killer_name": p70_b.npc_name, "tracked": false}
	vfo.state(vm)["slips"][p70_b.get_person_key()] = {"killer_key": p70_b.get_person_key(), "killer_name": p70_b.npc_name, "victim_name": p70_a.npc_name, "day": -5, "reported": false}
	var p2_sh = vm.trade_npcs.get(9, null) # 9 = TradeRole.SHERIFF (sin nombrar VillageNPC en el test)
	if p2_sh != null:
		var p2_diag: Dictionary = {}
		vfo.add_dialogue_choices(vm, p2_sh, p2_diag, [])
		var p2_leak: bool = false
		for c2 in (p2_diag.get("forensic_menu", {}).get("choices", []) as Array):
			if p70_b.npc_name in str(c2.get("label", "")):
				p2_leak = true
		assert(not p2_leak, "P2 audit: sheriff's forensic menu does not reveal the real killer")
	vfo.state(vm)["moved"].erase(p70_a.npc_name)
	vfo.state(vm)["slips"].erase(p70_b.get_person_key())
	vfo.on_player_action(vm, p70_a, "forensic_debunk:" + p70_a.npc_name, p70_inv)
	assert(bool(vfo.state(vm)["planted"][p70_a.npc_name]["debunked"]) and int(p2_case["suspects"][p70_c.npc_name]["score"]) < 30, "P2: Debunking planted clue clears framed suspect")
	# Tanda 1 (1-5): lejía en escena, sobornar autopsia, póliza de seguro, trucar hora de muerte y limpiador nocturno
	p2_case["suspects"]["Jugador"] = {"score": 40}
	vm.spawn_blood_puddle(Vector2(-3500, -3500), p70_a.npc_name)
	var t1_puddles_before: int = vm.blood_puddles.size()
	assert(vfo.bleach_crime_scene(vm, p70_pl, p70_inv, Vector2(-3500, -3500)) and vm.blood_puddles.size() < t1_puddles_before and int(p2_case["suspects"]["Jugador"]["score"]) == 20, "Tanda 1.1: Bleaching crime scene removes blood puddle and lowers player suspicion")
	var t1_doc = vm.trade_npcs.get(8, p70_a) # 8 = DOCTOR
	var t1_doc_aff_bak: int = t1_doc.affinity
	var t1_doc_gold_bak: int = t1_doc.personal_gold
	t1_doc.affinity = 75
	p2_case["suspects"]["Jugador"]["score"] = 35
	vfo.on_player_action(vm, t1_doc, "forensic_bribe_autopsy:" + p70_a.npc_name, p70_inv)
	assert(bool(p2_case.get("autopsy_bribed", false)) and t1_doc.personal_gold == t1_doc_gold_bak + 35 and int(p2_case["suspects"]["Jugador"]["score"]) == 10, "Tanda 1.2: Bribing doctor pays into doctor's pocket and lowers player suspicion")
	t1_doc.affinity = t1_doc_aff_bak
	t1_doc.personal_gold = t1_doc_gold_bak
	vfo.state(vm)["insurance"][p70_a.npc_name] = {"victim_name": p70_a.npc_name, "beneficiary_key": p70_b.get_person_key(), "beneficiary_name": p70_b.npc_name, "payout": 40, "player_knows": false, "exposed": false, "paid": false, "victim_dead": true}
	vfo.on_player_action(vm, t1_doc, "forensic_check_insurance:" + p70_a.npc_name, p70_inv)
	assert(bool(vfo.state(vm)["insurance"][p70_a.npc_name]["player_knows"]), "Tanda 1.3a: Checking insurance records reveals policy")
	var t1_b_score0: int = int(p2_case["suspects"][p70_b.npc_name]["score"])
	vfo.on_player_action(vm, p70_a, "forensic_expose_insurance:" + p70_a.npc_name, p70_inv)
	assert(bool(vfo.state(vm)["insurance"][p70_a.npc_name]["exposed"]) and int(p2_case["suspects"][p70_b.npc_name]["score"]) == t1_b_score0 + 30, "Tanda 1.3b: Exposing life insurance blocks payout and raises beneficiary suspicion")
	vfo.state(vm)["tampered_time"][p70_a.npc_name] = {"killer_name": p70_b.npc_name, "examined": false}
	var t1_b_score1: int = int(p2_case["suspects"][p70_b.npc_name]["score"])
	vfo.on_player_action(vm, t1_doc, "forensic_check_rigor:" + p70_a.npc_name, p70_inv)
	assert(bool(vfo.state(vm)["tampered_time"][p70_a.npc_name]["examined"]) and int(p2_case["suspects"][p70_b.npc_name]["score"]) == t1_b_score1 + 25, "Tanda 1.4: Checking rigor mortis uncovers tampered death time and raises killer suspicion")
	vm.spawn_blood_puddle(Vector2(-3400, -3400), p70_a.npc_name)
	p2_case["suspects"]["Jugador"]["score"] = 30
	var t1_fence_g0: int = p70_c.personal_gold
	vfo.on_player_action(vm, p70_c, "forensic_hire_cleaner", p70_inv)
	assert(vm.blood_puddles.is_empty() and p70_c.personal_gold == t1_fence_g0 + 25 and int(p2_case["suspects"]["Jugador"]["score"]) == 10, "Tanda 1.5: Nocturnal cleaner clears blood puddles and gets paid")
	p70_c.personal_gold = t1_fence_g0
	# Tanda 2 (6-10): imitador forense, confesión forzada, patriarca del clan, sabotaje de clan y cartas de amantes
	vfo.state(vm)["copycats"][p70_a.npc_name] = {"killer_name": p70_b.npc_name, "imitated_killer": p70_c.npc_name, "imitated_victim": "Víctima Previa", "debunked": false}
	p2_case["suspects"][p70_c.npc_name]["score"] = 35
	var t2_b_score0: int = int(p2_case["suspects"][p70_b.npc_name]["score"])
	vfo.on_player_action(vm, t1_doc, "forensic_debunk_copycat:" + p70_a.npc_name, p70_inv)
	assert(bool(vfo.state(vm)["copycats"][p70_a.npc_name]["debunked"]) and int(p2_case["suspects"][p70_c.npc_name]["score"]) == 15 and int(p2_case["suspects"][p70_b.npc_name]["score"]) == t2_b_score0 + 25, "Tanda 2.6: Debunking copycat lowers imitated suspect and raises real killer")
	vm.secrets.append({"id": 9991, "type": "affair", "active": true, "player_knows": true, "a": p70_c.get_person_key(), "a_name": p70_c.npc_name, "b": p70_b.get_person_key(), "b_name": p70_b.npc_name})
	p2_case["suspects"]["Jugador"]["score"] = 45
	vm.wanted_level = 2
	vfo.on_player_action(vm, p70_c, "forensic_force_confession:" + p70_a.npc_name, p70_inv)
	assert(int(p2_case["suspects"]["Jugador"]["score"]) == 0 and int(vm.wanted_level) == 0, "Tanda 2.7: Forcing confession with known dirt clears player suspicion and wanted level")
	var t2_pat = vcl.patriarch_of(vm, "family_clan_a")
	var t2_pat_aff: int = t2_pat.affinity
	t2_pat.affinity = 60
	vm.town_state["player_candidate"] = true
	vcl.on_player_action(vm, t2_pat, "clan_patriarch_sway:family_clan_a", p70_inv)
	assert(str(vm.town_state["pledges"].get(t2_pat.get_person_key(), "")) == "player", "Tanda 2.8: Clan patriarch sways family pledges to player")
	t2_pat.affinity = t2_pat_aff
	vcl.state(vm)["clan_sabotages"]["1"] = {"role_id": 1, "victim_key": p70_a.get_person_key(), "victim_name": p70_a.npc_name, "victim_fam": "family_clan_a", "saboteur_key": p70_b.get_person_key(), "saboteur_name": p70_b.npc_name, "saboteur_fam": "family_clan_b", "discovered": false, "reported": false}
	vcl.on_player_action(vm, p70_a, "clan_inspect_sabotage:1", p70_inv)
	assert(bool(vcl.state(vm)["clan_sabotages"]["1"]["discovered"]), "Tanda 2.9a: Inspecting clan sabotage discovers culprit")
	var t2_bg0: int = p70_b.personal_gold
	var t2_ag0: int = p70_a.personal_gold
	p70_b.personal_gold = 30
	var t2_invg0: int = p70_inv.gold
	vcl.on_player_action(vm, p70_c, "clan_report_sabotage:1", p70_inv)
	assert(bool(vcl.state(vm)["clan_sabotages"]["1"]["reported"]) and p70_b.personal_gold == 10 and p70_a.personal_gold == t2_ag0 + 10 and p70_inv.gold == t2_invg0 + 10, "Tanda 2.9b: Reporting clan sabotage fines saboteur from pocket and splits between victim and player")
	p70_b.personal_gold = t2_bg0
	p70_a.personal_gold = t2_ag0
	vm.active_sheriff_investigation = p2_inv_bak
	# P3: Linaje, hijo secreto de amante, revelación y expósito en la capilla
	var vli = vm.VillageLineage
	vli._daily_love_letters(vm)
	assert(vli.state(vm)["love_letters"].has("9991"), "Tanda 2.10a: Affair secret generates interceptable love letter")
	vli.on_player_action(vm, p70_c, "lineage_intercept_letter:9991", p70_inv)
	assert(bool(vli.state(vm)["love_letters"]["9991"]["intercepted"]), "Tanda 2.10b: Intercepting love letter marks it intercepted")
	var t2_bg1: int = p70_b.personal_gold
	p70_b.personal_gold = 25
	var t2_invg1: int = p70_inv.gold
	vli.on_player_action(vm, p70_b, "lineage_deliver_letter:9991", p70_inv)
	assert(bool(vli.state(vm)["love_letters"]["9991"]["handled"]) and p70_b.personal_gold == 13 and p70_inv.gold == t2_invg1 + 12, "Tanda 2.10c: Delivering love letter pays tip from receiver's pocket")
	p70_b.personal_gold = t2_bg1
	vm.secrets.pop_back()
	vli.state(vm)["secret_preg"][p70_a.get_person_key()] = {"mother_key": p70_a.get_person_key(), "mother_name": p70_a.npc_name, "real_father": p70_b.get_person_key(), "real_father_name": p70_b.npc_name, "presumed_father": p70_c.get_person_key(), "presumed_name": p70_c.npc_name, "secret_id": 1, "player_knows": true}
	var p3_kid = vfm.spawn_child(vm, p70_a, p70_c, 0)
	vli.on_child_born(vm, p70_a, p70_c, p3_kid)
	assert(vli.state(vm)["bastards"].has(p3_kid.get_person_key()), "P3: Secret affair child registered in bastards")
	vli.reveal_paternity(vm, p3_kid.get_person_key(), "prueba P3")
	assert(bool(vli.state(vm)["bastards"][p3_kid.get_person_key()]["revealed"]), "P3: Paternity revelation processed")
	vli.leave_foundling_at_chapel(vm, p70_a, p3_kid)
	assert(vli.state(vm)["foundlings"].has(p3_kid.get_person_key()) and p3_kid.family_id == "family_chapel", "P3: Foundling left at chapel")
	# Auditoría P3: cambiar el apellido de un niño sincroniza los registros por nombre (`vagrant_camp_nodes`, `npc_murders`, `foundlings`, etc.)
	var p3_old_name: String = p3_kid.npc_name
	var p3_dummy_camp := Node2D.new()
	vm.vagrant_camp_nodes[p3_old_name] = p3_dummy_camp
	vm.npc_murders["TestVictim_P3"] = p3_old_name
	vli.rename_child(vm, p3_kid, "Valen")
	var p3_new_name: String = p3_kid.npc_name
	assert(p3_new_name.ends_with(" Valen") and p3_new_name != p3_old_name, "P3 audit: child surname updated")
	assert(vm.vagrant_camp_nodes.has(p3_new_name) and not vm.vagrant_camp_nodes.has(p3_old_name), "P3 audit: vagrant_camp_nodes migrated on child rename")
	assert(str(vm.npc_murders.get("TestVictim_P3", "")) == p3_new_name, "P3 audit: npc_murders migrated on child rename")
	assert(str(vli.state(vm)["foundlings"][p3_kid.get_person_key()].get("kid_name", "")) == p3_new_name, "P3 audit: foundlings kid_name migrated on child rename")
	vm.vagrant_camp_nodes.erase(p3_new_name)
	p3_dummy_camp.free()
	vm.npc_murders.erase("TestVictim_P3")
	# Tanda 3 (11-15): bodas concertadas con dote, padrinos en el bautizo, enseñar oficio a niño, escapada al mirador y hábito en confesionario
	var t3_ag0: int = p70_a.personal_gold
	var t3_bg0: int = p70_b.personal_gold
	p70_a.personal_gold = 60
	var t3_invg0: int = p70_inv.gold
	vli.state(vm)["arranged_marriages"][p70_a.get_person_key()] = {"parent_key": p70_a.get_person_key(), "parent_name": p70_a.npc_name, "youth_key": p70_b.get_person_key(), "youth_name": p70_b.npc_name, "suitor_key": p70_c.get_person_key(), "suitor_name": p70_c.npc_name, "dowry": 30, "resolved": false}
	var t3_b_pid_bak: String = str(p70_b.person_profile.partner_id)
	var t3_c_pid_bak: String = str(p70_c.person_profile.partner_id)
	vli.on_player_action(vm, p70_a, "lineage_arrange_wed:" + p70_a.get_person_key(), p70_inv)
	assert(bool(vli.state(vm)["arranged_marriages"][p70_a.get_person_key()]["resolved"]) and p70_a.personal_gold == 30 and p70_b.personal_gold == t3_bg0 + 15 and p70_inv.gold == t3_invg0 + 15, "Tanda 3.11: Arranged marriage pays dowry from parent's pocket to couple and broker")
	p70_b.person_profile.partner_id = t3_b_pid_bak
	p70_c.person_profile.partner_id = t3_c_pid_bak
	p70_a.personal_gold = t3_ag0
	p70_b.personal_gold = t3_bg0
	var t3_kg0: int = p3_kid.personal_gold
	vli.on_player_action(vm, p70_a, "lineage_become_godparent:" + p3_kid.get_person_key(), p70_inv)
	assert(str(vli.state(vm)["godparents"][p3_kid.get_person_key()]["godparent_key"]) == "player" and p3_kid.personal_gold == t3_kg0 + 10, "Tanda 3.12: Becoming godparent transfers 10 gold gift to child")
	p70_inv.gold = maxi(int(p70_inv.gold), 60)
	vli.on_player_action(vm, p3_kid, "lineage_mentor_child:" + p3_kid.get_person_key(), p70_inv)
	vli.on_child_grown_up(vm, p3_kid)
	assert(vli.state(vm)["mentored_kids"].has(p3_kid.get_person_key()) and int(p3_kid.days_in_role) >= 5, "Tanda 3.13: Mentoring child grants trade experience upon growing up")
	vcl.state(vm)["romeo_pairs"]["t3_rp"] = {"pair_key": "t3_rp", "a": p70_a.get_person_key(), "b": p70_b.get_person_key(), "a_name": p70_a.npc_name, "b_name": p70_b.npc_name, "feud_key": p1_fk, "helped": false}
	assert(vli.send_lovers_to_mirador(vm) >= 1 and bool(vcl.state(vm)["romeo_pairs"]["t3_rp"].get("at_mirador", false)), "Tanda 3.14a: Forbidden lovers escape to mirador at night")
	p70_a.end_errand()
	p70_b.end_errand()
	vli.on_player_action(vm, p70_a, "lineage_catch_mirador:t3_rp", p70_inv)
	assert(bool(vcl.state(vm)["romeo_pairs"]["t3_rp"].get("mirador_seen", false)), "Tanda 3.14b: Catching lovers at mirador reveals secret romance")
	vcl.state(vm)["romeo_pairs"].erase("t3_rp")
	# P4: Confesión, excomunión y sermón con indirectas
	var vcf = vm.VillageConfession
	vm.secrets.append({"id": 9992, "type": "affair", "active": true, "player_knows": false, "a": p70_c.get_person_key(), "a_name": p70_c.npc_name, "b": p70_b.get_person_key(), "b_name": p70_b.npc_name, "p_name": "Pareja"})
	vcf.state(vm)["priest_secrets"].erase(p70_c.get_person_key())
	var t3_cg0: int = p70_c.personal_gold
	p70_c.personal_gold = 25
	var t3_invg1: int = p70_inv.gold
	var t3_priest = vm.VillageFaith.priest_of(vm)
	var t3_ppos_bak: Vector2 = t3_priest.global_position if t3_priest != null else Vector2.ZERO
	if t3_priest != null:
		t3_priest.global_position = vm._church_altar_pos + Vector2(300, 0)
	vcf.on_player_action(vm, p70_c, "faith_impersonate_priest:" + p70_c.get_person_key(), p70_inv)
	if t3_priest != null:
		t3_priest.global_position = t3_ppos_bak
	assert(vcf.state(vm)["priest_secrets"].has(p70_c.get_person_key()) and bool(vm.secrets[vm.secrets.size() - 1]["player_knows"]) and p70_c.personal_gold == 15 and p70_inv.gold == t3_invg1 + 10, "Tanda 3.15: Impersonating priest in confessional learns sin and collects penance from sinner's pocket")
	p70_c.personal_gold = t3_cg0
	vm.secrets.pop_back()
	vcf.excommunicate(vm, p70_b, "prueba P4")
	assert(vcf.is_excommunicated(vm, p70_b) and not vm.VillageFaith.wants_attend(p70_b, 1), "P4: Excommunicated villager cannot attend Sunday rite")
	vcf.lift_excommunication(vm, p70_b, "prueba P4")
	assert(not vcf.is_excommunicated(vm, p70_b), "P4: Excommunication lifted")
	vcf.state(vm)["priest_secrets"][p70_b.get_person_key()] = {"sinner_key": p70_b.get_person_key(), "sinner_name": p70_b.npc_name, "kind": "robo", "desc": "robo de prueba", "day": 1}
	vcf.state(vm)["week_sin_counts"]["robo"] = 2
	assert(vcf.apply_sunday_indirect_sermon(vm, [p70_b]) == "robo", "P4: Sunday indirect sermon targets top confessed sin")
	# Tanda 4 (16): Fingir un milagro en el altar
	var t4_bel_rep0: int = vm.VillageFaith.rep_of(vm, "believers")
	if t3_priest != null:
		t3_priest.global_position = vm._church_altar_pos + Vector2(300, 0)
	vcf.on_player_action(vm, p70_a, "faith_stage_miracle", p70_inv)
	if t3_priest != null:
		t3_priest.global_position = t3_ppos_bak
	assert(vm.VillageFaith.rep_of(vm, "believers") == t4_bel_rep0 + 12, "Tanda 4.16: Staging miracle at altar boosts believers reputation and collects offerings")
	# P5: Presentarse a alcalde, ganar elección, decretos e impuestos
	var vma = vm.VillageMayor
	var p5_ts_bak: Dictionary = vm.town_state.duplicate(true)
	vma.on_player_action(vm, p70_a, "town_run_mayor", p70_inv)
	vma.on_player_action(vm, p70_a, "town_promise:low_tax", p70_inv)
	assert(bool(vm.town_state.get("player_candidate", false)), "P5: Player registered as mayoral candidate")
	# Tanda 4 (17): Debate público entre candidatos
	vm.town_state["pledges"].clear()
	vma.on_player_action(vm, p70_a, "town_debate:" + p70_c.get_person_key(), p70_inv)
	var t4_won: bool = int(vm.town_state.get("campaign_bonus", 0)) >= 10 and not (vm.town_state["pledges"] as Dictionary).is_empty()
	var t4_lost: bool = int(vm.town_state.get("campaign_bonus", 0)) < 10 and (vm.town_state["pledges"] as Dictionary).is_empty()
	assert(bool(vm.town_state.get("debate_done", false)) and (t4_won or t4_lost), "Tanda 4.17 (audit): debate can be won (sways voters) or lost (no votes)")
	vm.town_state["pledges"][p70_a.get_person_key()] = "player"
	vm.town_state["pledges"][p70_b.get_person_key()] = "player"
	var p5_el: Dictionary = vm.VillageTown.hold_election(vm, "prueba P5", [p70_a, p70_b])
	assert(str(p5_el.get("winner", "")) == "player" and vma.is_player_mayor(vm), "P5: Player wins mayoral election")
	assert(vma.toggle_decree(vm, "curfew") and vma.has_decree(vm, "curfew"), "P5: Mayor decree toggled on")
	vma.on_player_action(vm, p70_a, "town_tax:low", p70_inv)
	assert(is_equal_approx(vma.tax_multiplier(vm), 0.5), "P5: Tax edict changes tax multiplier")
	# Tanda 4 (18 y 19): Indultar acusados y decreto de «Tributo de paz»
	vm.town_state["treasury"] = 100
	vcl.state(vm)["disowned"][p70_c.get_person_key()] = {"fam": "family_clan_a", "by": p70_a.npc_name, "reason": "prueba"}
	vma.on_player_action(vm, p70_c, "town_pardon:" + p70_c.get_person_key(), p70_inv)
	assert(not vcl.state(vm)["disowned"].has(p70_c.get_person_key()) and int(vm.town_state["treasury"]) == 85, "Tanda 4.18: Mayoral pardon rehabilitates disowned neighbor and pays 15 treasury compensation")
	assert(vma.toggle_decree(vm, "peace_tax") and vma.has_decree(vm, "peace_tax"), "Tanda 4.19a: Peace tax decree toggled on")
	var t4_ag0: int = p70_a.personal_gold
	var t4_bg0: int = p70_b.personal_gold
	p70_a.personal_gold = 20
	p70_b.personal_gold = 20
	assert(vma.apply_peace_tax(vm, p70_a, p70_b) == 16 and p70_a.personal_gold == 12 and p70_b.personal_gold == 12 and int(vm.town_state["treasury"]) == 101, "Tanda 4.19b: Peace tax fines both fighters from their pockets into town treasury")
	p70_a.personal_gold = t4_ag0
	p70_b.personal_gold = t4_bg0
	vm.town_state = p5_ts_bak
	# P6: Casa propia con hipoteca, cofre privado, inquilinos y escondite bajo las tablas
	var vho = vm.VillageHousing
	var p6_lot_bak: Dictionary = vl.lot(vm, "n0").duplicate(true)
	var p6_tr_bak: int = int(vm.town_state.get("treasury", 0))
	vm.town_state["treasury"] = 300
	vl.lot(vm, "n0")["status"] = "empty"
	p70_inv.gold = 200
	assert(vho.buy_house_loan(vm, "n0", p70_inv) and str(vl.lot(vm, "n0").get("payer", "")) == "player" and vl.lot(vm, "n0").has("loan"), "P6: Player buys house on mortgage")
	vl.lot(vm, "n0")["status"] = "built"
	assert(vho.is_player_family_chest(vm, "family_lot_n0"), "P6: Player house chest is recognized as player's own")
	var p6_g0: int = p70_inv.gold
	vln.daily(vm)
	assert(p70_inv.gold == p6_g0 - vln.INSTALLMENT, "P6: Daily mortgage installment paid by player")
	var p6_lodge_bak: String = p70_c.lodging
	var p6_cgold: int = p70_c.personal_gold
	p70_c.lodging = "house:n0"
	p70_c.personal_gold = 20
	var p6_g1: int = p70_inv.gold
	assert(vmi.nightly(vm, p70_c) and p70_inv.gold == p6_g1 + vho.rent_for_lot(vm, "n0"), "P6: Tenant in player-owned house pays rent to player")
	p70_c.lodging = p6_lodge_bak
	p70_c.personal_gold = p6_cgold
	vho.on_player_action(vm, p70_a, "housing_build_stash", p70_inv)
	vho.on_player_action(vm, p70_a, "housing_stash_put", p70_inv)
	assert(bool(vho.state(vm).get("has_stash", false)) and int(vho.state(vm).get("stash_gold", 0)) == 25, "P6: Secret floorboard stash stores 25 gold")
	# Tanda 4 (20): Fiestas en casa
	var t4_aff_a0: int = p70_a.affinity
	p70_a.affinity = 20
	var t4_invg0: int = p70_inv.gold
	vho.on_player_action(vm, p70_a, "housing_party", p70_inv)
	assert(p70_inv.gold == t4_invg0 - 20 and p70_a.affinity == 30, "Tanda 4.20: Hosting house party costs 20 gold and boosts guests' affinity and relationships")
	p70_a.affinity = t4_aff_a0
	# Tanda 5 (21, 22, 23 y 24): Intrusos nocturnos, reventa de casa según barrio/mejoras, sótano secreto y hogar de leña
	p70_inv.gold = 300
	vho.on_player_action(vm, p70_a, "housing_upgrade:hidden_cellar", p70_inv)
	vho.on_player_action(vm, p70_a, "housing_upgrade:hearth", p70_inv)
	assert(vho.has_upgrade(vm, "hidden_cellar") and vho.has_upgrade(vm, "hearth"), "Tanda 5.23a & 5.24a: Hidden cellar and hearth upgrades installed")
	var t5_wl_bak: int = int(vm.wanted_level)
	var t5_mw_bak: int = int(vm.player_murder_warrants_count)
	vm.wanted_level = 1
	vm.player_murder_warrants_count = 0
	vho.on_player_action(vm, p70_a, "housing_hide_cellar", p70_inv)
	assert(int(vm.wanted_level) == 0, "Tanda 5.23b: Hiding in secret cellar clears minor wanted level")
	vm.wanted_level = t5_wl_bak
	vm.player_murder_warrants_count = t5_mw_bak
	assert(vho.rest_by_hearth(vm, p70_pl), "Tanda 5.24b: Resting by hearth warms and heals player")
	var t5_cg0: int = p70_c.personal_gold
	p70_c.personal_gold = 30
	vho.state(vm)["intruder_attempt"] = {"intruder_key": p70_c.get_person_key(), "intruder_name": p70_c.npc_name, "day": 1, "repelled": false}
	var t5_invg1: int = p70_inv.gold
	vho.on_player_action(vm, p70_a, "housing_repel_intruder", p70_inv)
	assert(bool(vho.state(vm)["intruder_attempt"]["repelled"]) and p70_c.personal_gold == 15 and p70_inv.gold == t5_invg1 + 15, "Tanda 5.21: Repelling intruder takes 15 gold from intruder's pocket")
	p70_c.personal_gold = t5_cg0
	var t5_sale_price: int = vho.house_sale_price(vm, "n0")
	assert(t5_sale_price > 95, "Tanda 5.22a: Upgraded house sale price exceeds base value")
	vm.town_state["treasury"] = 300
	var t5_invg2: int = p70_inv.gold
	(vl.lot(vm, "n0")["residents"] as Array).clear()
	vl.lot(vm, "n0")["loan"] = {"lender": "town", "lender_name": "Arcas", "owed": 30, "missed": 0, "principal": 85}
	vho.on_player_action(vm, p70_a, "housing_sell_house:n0", p70_inv)
	assert(str(vl.lot(vm, "n0").get("payer", "")) != "player" and not vl.lot(vm, "n0").has("loan") and p70_inv.gold == t5_invg2 + t5_sale_price - 30, "Tanda 5.22b (audit): selling a house pays off the mortgage first")
	vl.lot(vm, "n0").clear()
	for k6 in p6_lot_bak.keys():
		vl.lot(vm, "n0")[k6] = p6_lot_bak[k6]
	vl._draw_lot(vm, "n0", vl.lot(vm, "n0"))
	vm.town_state["treasury"] = p6_tr_bak
	# P7: Mercado negro, perista, robo por encargo, usura, extorsión y soborno nocturno al guardia
	var vun = vm.VillageUnderworld
	var p7_fence = vun.get_fence_npc(vm)
	assert(p7_fence != null and vun.is_fence(vm, p7_fence), "P7: Night fence NPC selected")
	p70_inv.gold = 300
	vun.on_player_action(vm, p7_fence, "underworld_buy:lockpick", p70_inv)
	assert(vun.get_item_count(vm, "lockpick") == 1, "P7: Bought lockpick from night fence")
	vun.on_player_action(vm, p7_fence, "underworld_take_heist", p70_inv)
	vun.on_player_action(vm, p7_fence, "underworld_steal_heist", p70_inv) # ya no existe: hay que ir al sitio
	assert(not bool(vun.state(vm)["active_heist"].get("stolen", false)), "P7 audit: heist cannot be stolen from a dialogue menu")
	vun.state(vm)["active_heist"]["stolen"] = true # como si el jugador hubiera ido de noche sin testigos
	var p7_g_before: int = p70_inv.gold
	vun.on_player_action(vm, p7_fence, "underworld_deliver_heist", p70_inv)
	assert(int(vun.state(vm).get("heists_done", 0)) == 1 and p70_inv.gold > p7_g_before, "P7: Custom heist stolen and delivered to fence")
	# Auditoría: el perista solo paga por mercancía que lleves, y de su bolsillo
	var p7_fg: int = p7_fence.personal_gold
	p7_fence.personal_gold = 50
	p70_inv.remove_item("bandit_scrap", p70_inv.get_count("bandit_scrap"))
	var p7_g2: int = p70_inv.gold
	vun.on_player_action(vm, p7_fence, "underworld_fence_goods", p70_inv)
	assert(p70_inv.gold == p7_g2, "P7 audit: fence pays nothing if you carry no stolen goods")
	p70_inv.add_item("bandit_scrap", 1)
	vun.on_player_action(vm, p7_fence, "underworld_fence_goods", p70_inv)
	assert(p70_inv.gold == p7_g2 + 12 and p7_fence.personal_gold == 38 and p70_inv.get_count("bandit_scrap") == 0, "P7 audit: fence buys a real item with his own gold")
	p7_fence.personal_gold = p7_fg
	vun.on_player_action(vm, p70_a, "underworld_bribe_patrol", p70_inv)
	assert(vun.is_guard_bribed_tonight(vm), "P7: Night guard bribed for immunity tonight")
	# Tanda 5 (25): Caravana de contrabando de medianoche (acampa de noche cada 3 días con lotes limitados)
	var t5_wc = root.get_node_or_null("WorldClock")
	var t5_day_bak: int = int(t5_wc.current_day)
	var t5_hour_bak: int = int(t5_wc.current_hour)
	t5_wc.current_day = 2
	t5_wc.current_hour = 22
	assert(not vun.is_caravan_here(vun.state(vm)), "Tanda 5.25 (audit): Caravan is not available on non-caravan days")
	t5_wc.current_day = 4
	t5_wc.current_hour = 22
	vun.state(vm)["caravan_busted_day"] = -99
	vun.daily(vm)
	var t5_dust0: int = vun.get_item_count(vm, "dusk_dust")
	var t5_invg3: int = p70_inv.gold
	vun.on_player_action(vm, p7_fence, "underworld_caravan_buy", p70_inv)
	assert(vun.get_item_count(vm, "dusk_dust") == t5_dust0 + 2 and int(vun.state(vm)["caravan_gold"]) == 95 and int(vun.state(vm)["caravan_batches_left"]) == 1 and p70_inv.gold == t5_invg3 - 25, "Tanda 5.25a: Bought contraband batch from midnight caravan")
	vun.on_player_action(vm, p7_fence, "underworld_caravan_sell", p70_inv)
	assert(vun.get_item_count(vm, "dusk_dust") == t5_dust0 + 1 and int(vun.state(vm)["caravan_gold"]) == 60 and p70_inv.gold == t5_invg3 + 10, "Tanda 5.25b: Sold dusk dust to midnight caravan")
	var t5_tr0: int = int(vm.town_state.get("treasury", 0))
	vun.on_player_action(vm, p70_a, "underworld_caravan_report", p70_inv)
	assert(int(vun.state(vm)["caravan_gold"]) == 0 and p70_inv.gold == t5_invg3 + 35 and int(vm.town_state["treasury"]) == t5_tr0 + 35, "Tanda 5.25c: Reporting midnight caravan confiscates funds into reward and town treasury")
	vm.town_state["treasury"] = t5_tr0
	t5_wc.current_day = t5_day_bak
	t5_wc.current_hour = t5_hour_bak
	# Tanda 6 (26, 27, 28 y 29): Timbas de dados, red de carteristas, falsificar escrituras y retar al jefe de la Red de las Sombras
	var t6_cg0: int = p70_c.personal_gold
	p70_c.personal_gold = 30
	p70_inv.gold = 200
	assert(vun.play_dice_bet(vm, p70_c, p70_inv, 1) == 10 and p70_c.personal_gold == 20 and p70_inv.gold == 210, "Tanda 6.26a: Winning dice bet transfers 10 gold from NPC pocket to player")
	assert(vun.play_dice_bet(vm, p70_c, p70_inv, -1) == -10 and p70_c.personal_gold == 30 and p70_inv.gold == 200, "Tanda 6.26b: Losing dice bet transfers 10 gold from player to NPC pocket")
	p70_c.personal_gold = 10
	vun.on_player_action(vm, p70_c, "underworld_recruit_pickpocket", p70_inv)
	assert((vun.state(vm)["pickpockets"] as Dictionary).has(p70_c.get_person_key()) and p70_c.personal_gold == 20 and p70_inv.gold == 190, "Tanda 6.27a: Recruiting pickpocket pays 10 gold advance into recruit's pocket")
	var t6_ag0: int = p70_a.personal_gold
	p70_a.personal_gold = 250
	var t6_invg1: int = p70_inv.gold
	assert(vun.run_pickpocket_network(vm, p70_inv, 0.0) == 3 and p70_c.personal_gold == 23 and p70_inv.gold == t6_invg1 + 3, "Tanda 6.27b: Pickpocket network steals 6 from rich villager and splits 3/3")
	(vun.state(vm)["pickpockets"] as Dictionary).clear()
	p70_a.personal_gold = t6_ag0
	p70_c.personal_gold = t6_cg0
	var t6_fg0: int = p7_fence.personal_gold
	p7_fence.personal_gold = 40
	vun.on_player_action(vm, p7_fence, "underworld_forge_deed", p70_inv)
	assert(bool(vun.state(vm).get("forged_deed", false)) and p7_fence.personal_gold == 65, "Tanda 6.28a: Forged municipal deed purchased from fence")
	var t6_invg2: int = p70_inv.gold
	var t6_wl0: int = int(vm.wanted_level)
	vho.on_player_action(vm, p70_a, "housing_deed:0", p70_inv)
	var t6_deed_ok: bool = bool(vho.state(vm)["commercial_deeds"].get("0", false)) and p70_inv.gold == t6_invg2 - (vho.COMMERCIAL_DEED_COST - 40)
	var t6_deed_caught: bool = not bool(vho.state(vm)["commercial_deeds"].get("0", false)) and p70_inv.gold == t6_invg2 and int(vm.wanted_level) == t6_wl0 + 1
	assert(not bool(vun.state(vm).get("forged_deed", false)) and (t6_deed_ok or t6_deed_caught), "Tanda 6.28b (audit): Forged municipal deed either discounts 40 gold or gets caught and raises wanted level")
	vm.wanted_level = t6_wl0
	(vho.state(vm)["commercial_deeds"] as Dictionary).erase("0")
	vun.state(vm)["boss"] = "fence"
	p7_fence.personal_gold = 65
	if p70_pl != null and p70_pl.get("health_comp") != null:
		p70_pl.get("health_comp").current_health = p70_pl.get("health_comp").max_health
	var t6_invg3: int = p70_inv.gold
	vun.on_player_action(vm, p7_fence, "underworld_challenge_boss", p70_inv)
	var t6_won: bool = str(vun.state(vm).get("boss", "")) == "player" and p7_fence.personal_gold == 40 and p70_inv.gold == t6_invg3 + 25
	var t6_lost: bool = str(vun.state(vm).get("boss", "")) == "fence" and p70_inv.gold == t6_invg3 and int(vun.state(vm).get("last_boss_challenge", -99)) == vun.today()
	assert(t6_won or t6_lost, "Tanda 6.29 (audit): challenging the Shadow boss can be won or lost, once a week")
	p7_fence.personal_gold = t6_fg0
	# Auditoría: el veneno lento no mata en el acto (actúa al día siguiente, o te pillan echándolo)
	vun.add_item(vm, "slow_poison", 1)
	var p7_wl: int = int(vm.wanted_level)
	vun.on_player_action(vm, p70_c, "underworld_use_poison", p70_inv)
	assert(not p70_c.is_dead and ((vun.state(vm)["pending_poison"] as Dictionary).has(p70_c.get_person_key()) or int(vm.wanted_level) == p7_wl + 1), "P7 audit: slow poison is not an instant kill")
	(vun.state(vm)["pending_poison"] as Dictionary).clear()
	vm.wanted_level = p7_wl
	p70_a.family_id = p70_fam_a_bak
	p70_b.family_id = p70_fam_b_bak
	for np_tmp in [p1_kid, p3_kid]:
		vfm.state(vm)["born"].erase(np_tmp.get_person_key())
		vm.unemployed_npcs.erase(np_tmp)
		vm._free_transient_npc(np_tmp)
	print("Blocks P1-P7 (70 mechanics) OK")

	# 83. Fama de los vecinos y Maestros Artesanos con estilo propio (`VillageFame.gd`)
	var vfa_fame = load("res://scripts/systems/VillageFame.gd")
	(vfa_fame.state(vm)["scores"] as Dictionary).clear()
	(vfa_fame.state(vm)["reasons"] as Dictionary).clear()
	(vfa_fame.state(vm)["masters"] as Dictionary).clear()
	(vfa_fame.state(vm)["patron_day"] as Dictionary).clear()
	vfa_fame.state(vm)["last_praise_day"] = -99
	var vf_artisan = null
	var vf_artisan2 = null
	for r_art in vm.trade_npcs.keys():
		var cand_art = vm.trade_npcs[r_art]
		if is_instance_valid(cand_art) and not cand_art.is_dead and cand_art.trade_role in load("res://scripts/enemies/VillageNPC.gd").SHOP_ROLES:
			if vf_artisan == null:
				vf_artisan = cand_art
			elif vf_artisan2 == null and cand_art != vf_artisan:
				vf_artisan2 = cand_art
				break
	assert(vf_artisan != null and vf_artisan2 != null, "Fame: Found two living shop artisans")
	var vf_days1_bak: int = vf_artisan.days_in_role
	var vf_days2_bak: int = vf_artisan2.days_in_role
	var vf_g1_bak: int = vf_artisan.personal_gold
	var vf_g2_bak: int = vf_artisan2.personal_gold
	vf_artisan.days_in_role = 10
	vf_artisan2.days_in_role = 3
	vfa_fame.daily(vm)
	assert(vfa_fame.is_master(vm, vf_artisan) and vfa_fame.fame_of(vm, vf_artisan) >= 25 and vfa_fame.tier_label(vfa_fame.fame_of(vm, vf_artisan)) != "", "Fame.1: Experienced artisan reaches Master Artisan rank with signature style and fame")
	var vf_minfo: Dictionary = vfa_fame.master_info(vm, vf_artisan)
	assert(str(vf_minfo.get("style", "")) != "" and int(vf_minfo.get("stock", 0)) == 1, "Fame.2: Master Artisan has a signature style and 1 masterwork in stock")
	# Comprar Obra Maestra en el taller
	p70_inv.gold = 200
	vf_artisan.personal_gold = 20
	vfa_fame.on_player_action(vm, vf_artisan, "fame_buy_masterwork", p70_inv)
	assert(p70_inv.has_item("masterwork_piece", 1) and p70_inv.gold == 165 and vf_artisan.personal_gold == 55 and int(vfa_fame.master_info(vm, vf_artisan).get("stock", -1)) == 0, "Fame.3: Buying a masterwork transfers 35 gold to artisan and gives masterwork_piece")
	# Vender Obra Maestra a un vecino rico/coleccionista de su propio bolsillo
	var vf_collector = p70_a
	var vf_col_g_bak: int = vf_collector.personal_gold
	vf_collector.personal_gold = 180
	var vf_col_fame0: int = vfa_fame.fame_of(vm, vf_collector)
	vfa_fame.on_player_action(vm, vf_collector, "fame_sell_masterwork", p70_inv)
	assert(not p70_inv.has_item("masterwork_piece", 1) and p70_inv.gold == 215 and vf_collector.personal_gold == 130 and vfa_fame.fame_of(vm, vf_collector) == vf_col_fame0 + 6, "Fame.4: Rich collector buys masterwork with 50 gold from his own pocket")
	vf_collector.personal_gold = vf_col_g_bak
	# Patrocinar taller de un artesano aún no maestro (`days_in_role = 3` -> `5` -> asciende a Maestro)
	assert(not vfa_fame.is_master(vm, vf_artisan2), "Fame.5a: Second artisan is not yet a master")
	vf_artisan2.personal_gold = 15
	vfa_fame.on_player_action(vm, vf_artisan2, "fame_patronize", p70_inv)
	assert(vfa_fame.is_master(vm, vf_artisan2) and vf_artisan2.personal_gold == 45 and p70_inv.gold == 185, "Fame.5b: Patronizing artisan workshop transfers 30 gold and promotes to Master Artisan")
	# Hablar bien / pregonar faltas con tirada y espera de 3 días
	var vf_praise_fame0: int = vfa_fame.fame_of(vm, p70_b)
	var vf_praise_aff0: int = p70_b.affinity
	vfa_fame.on_player_action(vm, p70_b, "fame_praise", p70_inv)
	var vf_praised_ok: bool = vfa_fame.fame_of(vm, p70_b) == vf_praise_fame0 + 10 and p70_b.affinity == vf_praise_aff0 + 8
	var vf_praised_fail: bool = vfa_fame.fame_of(vm, p70_b) == vf_praise_fame0 and p70_b.affinity == vf_praise_aff0 - 4
	assert((vf_praised_ok or vf_praised_fail) and int(vfa_fame.state(vm)["last_praise_day"]) == vfa_fame.today(), "Fame.6: Public praise has a risk roll and sets cooldown")
	# Guardado y carga
	var vf_save: Dictionary = vm.get_economy_save_dict()
	var vf_saved_style: String = str(vfa_fame.master_info(vm, vf_artisan).get("style", ""))
	(vfa_fame.state(vm)["masters"] as Dictionary).clear()
	vm.load_economy_save_dict(vf_save)
	assert(vfa_fame.is_master(vm, vf_artisan) and str(vfa_fame.master_info(vm, vf_artisan).get("style", "")) == vf_saved_style, "Fame.7: Fame and Master Artisan styles persist across save/load")
	vf_artisan.days_in_role = vf_days1_bak
	vf_artisan2.days_in_role = vf_days2_bak
	vf_artisan.personal_gold = vf_g1_bak
	vf_artisan2.personal_gold = vf_g2_bak
	print("VillageFame & Master Artisans OK")

	# 84. Bloque PG: Escuelas con ventaja de oficio al graduarse y Negocio propio del jugador con publicidad
	var pg_kid = vfm.spawn_child(vm, p70_a, p70_b, 8)
	var pg_c_role_bak: int = int(p70_c.trade_role)
	var pg_c_lrole_bak: int = int(p70_c.linked_trade)
	var pg_c_nrole_bak: String = p70_c.npc_role
	var pg_c_wpos_bak: Vector2 = p70_c.work_position
	var pg_teacher_bak: String = str(vfm.state(vm).get("teacher", ""))
	vfm.make_teacher(vm, p70_c)
	vfm.update_school(vm, false)
	assert(pg_kid.has_meta("school_pos"), "PG.1a: School-age pupil gets assigned a school desk")
	pg_kid.global_position = pg_kid.get_meta("school_pos")
	for _lesson_i in range(6):
		vfm.on_hour(vm, 14)
	assert(int((vfm.state(vm)["pupil_lessons"] as Dictionary).get(pg_kid.get_person_key(), 0)) == 6, "PG.1b: Pupil attendance at 14:00 accumulates individual lessons")
	vfm.grow_up(vm, pg_kid)
	assert(int(pg_kid.get_meta("school_bonus_days", 0)) == 3 and int(pg_kid.days_in_role) >= 3, "PG.1c: Graduating pupil receives trade mastery bonus days from school attendance")
	pg_kid.days_in_role = 0
	pg_kid.promote_to_trade(p70_a.trade_role, "Graduado del Valle", p70_a.work_position, p70_a.shop_stock.duplicate())
	assert(int(pg_kid.days_in_role) == 3, "PG.1d: School bonus days apply when taking a trade role as an adult")
	p70_c.trade_role = pg_c_role_bak
	p70_c.linked_trade = pg_c_lrole_bak
	p70_c.npc_role = pg_c_nrole_bak
	p70_c.work_position = pg_c_wpos_bak
	vfm.state(vm)["teacher"] = pg_teacher_bak
	vm.unemployed_npcs.erase(pg_kid)
	vm._free_transient_npc(pg_kid)
	# PG.2: Fundar tu propio negocio en un solar construido, abastecerlo, hacer publicidad, contratar dependiente y cobrar caja
	var pg_lot_bak: Dictionary = vl.lot(vm, "n0").duplicate(true)
	var pg_tr_bak: int = int(vm.town_state.get("treasury", 0))
	var pg_ag_bak: int = p70_a.personal_gold
	var pg_bg_bak: int = p70_b.personal_gold
	var pg_cg_bak: int = p70_c.personal_gold
	vl.lot(vm, "n0")["status"] = "built"
	vl.lot(vm, "n0")["payer"] = "player"
	(vho.state(vm)["player_shop"] as Dictionary).clear()
	p70_inv.gold = 200
	p70_a.personal_gold = 10
	vho.on_player_action(vm, p70_a, "housing_found_shop:n0", p70_inv)
	assert(vho.has_player_shop(vm) and p70_inv.gold == 135 and p70_a.personal_gold == 75 and int(vho.state(vm)["player_shop"]["stock"]) == 2, "PG.2a: Founding player shop on built lot transfers 65 gold to carpenter and initializes counter with 2 stock")
	p70_inv.remove_item("bread", p70_inv.get_count("bread"))
	p70_inv.add_item("bread", 2)
	vho.on_player_action(vm, p70_a, "housing_stock_shop", p70_inv)
	assert(not p70_inv.has_item("bread", 1) and int(vho.state(vm)["player_shop"]["stock"]) == 4, "PG.2b: Stocking player shop removes real items from inventory and adds to counter stock")
	vho.on_player_action(vm, p70_a, "housing_advertise_shop", p70_inv)
	assert(p70_inv.gold == 123 and int(vho.state(vm)["player_shop"]["ad_days"]) == 3, "PG.2c: Advertising player shop costs 12 gold into treasury and boosts clientele for 3 days")
	p70_c.trade_role = 0 # UNEMPLOYED
	p70_c.personal_gold = 10
	vho.on_player_action(vm, p70_c, "housing_hire_clerk", p70_inv)
	assert(str(vho.state(vm)["player_shop"]["clerk_key"]) == p70_c.get_person_key(), "PG.2d: Hiring unemployed neighbor sets shop clerk")
	p70_a.personal_gold = 45
	p70_b.personal_gold = 45
	vho.daily(vm)
	var pg_sales: int = int(vho.state(vm)["player_shop"]["total_sales"])
	var pg_till: int = int(vho.state(vm)["player_shop"]["till_gold"])
	assert(pg_sales >= 2 and int(vho.state(vm)["player_shop"]["stock"]) == 4 - pg_sales and p70_c.personal_gold == 14 and pg_till == pg_sales * 10 - 4, "PG.2e: Daily shop cycle sells stock to real neighbors, deducts their gold, and pays clerk wage from till")
	vho.on_player_action(vm, p70_a, "housing_collect_shop", p70_inv)
	assert(p70_inv.gold == 123 + pg_till and int(vho.state(vm)["player_shop"]["till_gold"]) == 0, "PG.2f: Collecting shop till transfers earnings to player")
	p70_c.trade_role = pg_c_role_bak
	p70_a.personal_gold = pg_ag_bak
	p70_b.personal_gold = pg_bg_bak
	p70_c.personal_gold = pg_cg_bak
	(vho.state(vm)["player_shop"] as Dictionary).clear()
	vl.lot(vm, "n0").clear()
	for k_pg in pg_lot_bak.keys():
		vl.lot(vm, "n0")[k_pg] = pg_lot_bak[k_pg]
	vl._draw_lot(vm, "n0", vl.lot(vm, "n0"))
	vm.town_state["treasury"] = pg_tr_bak
	print("Block PG (School Graduation & Player Business) OK")

	# 85. Bloque PH: Idolatría / obsesión por un personaje (muy rara) y Acompañantes del jugador
	var ph_ag_bak: int = p70_a.personal_gold
	var ph_bg_bak: int = p70_b.personal_gold
	var ph_cg_bak: int = p70_c.personal_gold
	var ph_a_aff_bak: int = p70_a.affinity
	var ph_b_aff_bak: int = p70_b.affinity
	var ph_c_aff_bak: int = p70_c.affinity
	(vfa_fame.state(vm)["obsessions"] as Dictionary).clear()
	(vfa_fame.state(vm)["companion"] as Dictionary).clear()
	vfa_fame.add_fame(vm, p70_a, 45, "Ídolo de prueba PH")
	assert(vfa_fame.try_spawn_obsession(vm, p70_c, p70_a) and (vfa_fame.state(vm)["obsessions"] as Dictionary).has(p70_c.get_person_key()), "PH.1a: Rare obsession spawns toward high-fame idol")
	p70_c.personal_gold = 30
	p70_a.personal_gold = 10
	p70_a.npc_relationships[p70_b.get_person_key()] = 60
	p70_c.npc_relationships[p70_b.get_person_key()] = 20
	var ph_c_rel_b0: int = p70_c.get_relationship_with_npc(p70_b.get_person_key())
	vfa_fame.daily(vm)
	assert(p70_c.personal_gold == 24 and p70_a.personal_gold == 16 and int(vfa_fame.state(vm)["obsessions"][p70_c.get_person_key()]["gifts_sent"]) == 1, "PH.1b: Obsessed admirer sends anonymous gift paid from their own pocket to idol")
	assert(p70_c.get_relationship_with_npc(p70_b.get_person_key()) == ph_c_rel_b0 - 8 and p70_c.errand_kind == "obsession_follow", "PH.1c: Obsessed admirer feels extreme jealousy toward idol's close friends and follows idol")
	vfa_fame.state(vm)["last_probe_day"] = -99
	vfa_fame.on_player_action(vm, p70_b, "fame_probe_obsession", p70_inv)
	assert(not bool(vfa_fame.state(vm)["obsessions"][p70_c.get_person_key()]["known_by_player"]), "PH.1d: Probing an innocent neighbor does not reveal stalker")
	vfa_fame.state(vm)["last_probe_day"] = -99
	var ph_c_aff0: int = p70_c.affinity
	vfa_fame.on_player_action(vm, p70_c, "fame_probe_obsession", p70_inv)
	var ph_probe_ok: bool = bool(vfa_fame.state(vm)["obsessions"][p70_c.get_person_key()]["known_by_player"])
	var ph_probe_fail: bool = not ph_probe_ok and p70_c.affinity == ph_c_aff0 - 4
	assert(ph_probe_ok or ph_probe_fail, "PH.1e: Probing the actual stalker has a risk roll")
	vfa_fame.state(vm)["obsessions"][p70_c.get_person_key()]["known_by_player"] = true
	p70_a.personal_gold = 25
	p70_inv.gold = 100
	vfa_fame.on_player_action(vm, p70_a, "fame_warn_idol:" + p70_c.get_person_key(), p70_inv)
	assert((vfa_fame.state(vm)["obsessions"] as Dictionary).is_empty() and p70_a.personal_gold == 10 and p70_inv.gold == 115, "PH.1f: Warning idol ends obsession and pays 15 gold reward from idol's pocket")
	# PH.2: Acompañantes del jugador (por amistad >= 55 o contratado por 15 Oro/día, respaldo con tirada y despido)
	p70_b.affinity = 60
	vfa_fame.on_player_action(vm, p70_b, "fame_companion_invite", p70_inv)
	assert(vfa_fame.is_companion(vm, p70_b) and str(vfa_fame.state(vm)["companion"]["mode"]) == "friend", "PH.2a: High-affinity friend joins player as companion")
	p70_a.affinity = 20
	var ph_a_aff0: int = p70_a.affinity
	vfa_fame.on_player_action(vm, p70_a, "fame_companion_backup", p70_inv)
	assert((p70_a.affinity == ph_a_aff0 + 8 or p70_a.affinity == ph_a_aff0 - 8) and int(vfa_fame.state(vm)["companion"]["last_backup_day"]) == vfa_fame.today(), "PH.2b: Companion backup has a risk roll and daily cooldown")
	vfa_fame.on_player_action(vm, p70_b, "fame_companion_dismiss", p70_inv)
	assert(not vfa_fame.is_companion(vm, p70_b), "PH.2c: Dismissing companion clears companion state")
	p70_c.affinity = 20
	p70_c.personal_gold = 10
	p70_inv.gold = 50
	vfa_fame.on_player_action(vm, p70_c, "fame_companion_hire", p70_inv)
	assert(vfa_fame.is_companion(vm, p70_c) and p70_inv.gold == 35 and p70_c.personal_gold == 25, "PH.2d: Hiring companion transfers 15 gold upfront into companion's pocket")
	vfa_fame.daily(vm)
	assert(vfa_fame.is_companion(vm, p70_c) and p70_inv.gold == 20 and p70_c.personal_gold == 40, "PH.2e: Daily cycle pays hired companion 15 gold from player inventory")
	p70_inv.gold = 5
	vfa_fame.daily(vm)
	assert(not vfa_fame.is_companion(vm, p70_c) and p70_inv.gold == 5, "PH.2f: Hired companion leaves if player cannot pay daily wage")
	p70_a.personal_gold = ph_ag_bak
	p70_b.personal_gold = ph_bg_bak
	p70_c.personal_gold = ph_cg_bak
	p70_a.affinity = ph_a_aff_bak
	p70_b.affinity = ph_b_aff_bak
	p70_c.affinity = ph_c_aff_bak
	print("Block PH (Obsession & Player Companions) OK")

	# 86. Bloque PI: Animales con etapas de crecimiento y crianza y Carreras / peleas de animales con apuestas
	var pi_ag_bak: int = p70_a.personal_gold
	var pi_bg_bak: int = p70_b.personal_gold
	(vho.state(vm)["player_animals"] as Array).clear()
	p70_inv.gold = 100
	p70_a.personal_gold = 10
	vho.on_player_action(vm, p70_a, "housing_buy_chick:rooster", p70_inv)
	assert((vho.state(vm)["player_animals"] as Array).size() == 1 and p70_inv.gold == 85 and p70_a.personal_gold == 25 and str(vho.state(vm)["player_animals"][0]["stage"]) == "chick", "PI.1a: Buying young animal transfers 15 gold to seller and starts at chick stage")
	p70_inv.remove_item("bread", p70_inv.get_count("bread"))
	p70_inv.add_item("bread", 2)
	vho.on_player_action(vm, p70_a, "housing_feed_animals", p70_inv)
	vho.daily(vm)
	assert(p70_inv.get_count("bread") == 1 and str(vho.state(vm)["player_animals"][0]["stage"]) == "juvenile", "PI.1b: Feeding and daily growth advances animal from chick to juvenile stage")
	vho.on_player_action(vm, p70_a, "housing_feed_animals", p70_inv)
	vho.daily(vm)
	assert(str(vho.state(vm)["player_animals"][0]["stage"]) == "adult" and vho.best_adult_animal_power(vm, "rooster") >= 3, "PI.1c: Animal reaches adult stage with increased vigor")
	# PI.2: Carreras de animales y peleas de gallos/perros con apuestas contra el bolsillo del vecino
	p70_b.personal_gold = 40
	p70_inv.gold = 100
	vun.state(vm)["last_animal_race_day"] = -99
	assert(vun.run_animal_race(vm, p70_b, p70_inv, 1) == 12 and p70_b.personal_gold == 28 and p70_inv.gold == 112, "PI.2a: Winning animal race transfers 12 gold from opponent's pocket")
	vun.state(vm)["last_animal_race_day"] = -99
	assert(vun.run_animal_race(vm, p70_b, p70_inv, -1) == -12 and p70_b.personal_gold == 40 and p70_inv.gold == 100, "PI.2b: Losing animal race transfers 12 gold to opponent's pocket")
	vun.state(vm)["last_cockfight_day"] = -99
	assert(vun.run_cockfight(vm, p70_b, p70_inv, 1) == 15 and p70_b.personal_gold == 25 and p70_inv.gold == 115, "PI.2c: Winning cockfight transfers 15 gold from opponent's pocket")
	vun.state(vm)["last_cockfight_day"] = -99
	assert(vun.run_cockfight(vm, p70_b, p70_inv, -1) == -15 and p70_b.personal_gold == 40 and p70_inv.gold == 100, "PI.2d: Losing cockfight transfers 15 gold to opponent's pocket")
	assert(vun.run_cockfight(vm, p70_b, p70_inv, 1) == 0, "PI.2e: Daily cooldown prevents repeating cockfight on the same day")
	(vho.state(vm)["player_animals"] as Array).clear()
	p70_a.personal_gold = pi_ag_bak
	p70_b.personal_gold = pi_bg_bak
	print("Block PI (Animal Growth & Animal Bets) OK")

	# 87. Bloque PJ: Amputaciones e implantes / prótesis médicas y Sabotaje lógico de la red eléctrica
	var vil_pj = load("res://scripts/systems/VillageIllness.gd")
	var vcu_pj = load("res://scripts/systems/VillageCulture.gd")
	var pj_doc = vm.trade_npcs.get(int(load("res://scripts/enemies/VillageNPC.gd").TradeRole.DOCTOR))
	var pj_tinker = vm.trade_npcs.get(int(load("res://scripts/enemies/VillageNPC.gd").TradeRole.TINKER))
	assert(pj_doc != null and pj_tinker != null, "PJ: Doctor and Tinker exist")
	var pj_doc_g0: int = pj_doc.personal_gold
	var pj_tink_g0: int = pj_tinker.personal_gold
	var pj_tink_kits0: int = int(pj_tinker.shop_stock.get("repair_kit", 0))
	var pj_bg0: int = p70_b.personal_gold
	var pj_cg0: int = p70_c.personal_gold
	var pj_tr0: int = int(vm.town_state.get("treasury", 0))
	vil_pj.amputations_of(vm).clear()
	vil_pj.recover(vm, pj_doc.get_person_key())
	p70_b.personal_gold = 5 # No puede pagarse prótesis aún
	p70_b.health_comp.wounds.append({
		"id": 9991, "region": "left_arm", "organ": "", "type": "deep_wound",
		"name": "Corte Profundo", "severity": 25.0, "bleed_rate": 0.0, "pain": 12.0,
		"bandaged": true, "bandage_dirty": 0.0, "stitched": false, "splinted": false, "clean": false,
		"infection": 72.0, "immunity": 20.0, "tend_quality": 10.0, "tend_tier": "makeshift", "weapon_cause": "Cuchillo"
	})
	vil_pj.daily(vm)
	assert(vil_pj.has_amputation(vm, p70_b.get_person_key()) and not vil_pj.has_prosthetic(vm, p70_b.get_person_key()) and float(p70_b.health_comp.region_hp["left_arm"]) == 0.0, "PJ.1a: Doctor performs emergency amputation on gangrenous limb")
	pj_tinker.shop_stock["repair_kit"] = 3
	p70_inv.gold = 100
	pj_doc.personal_gold = 10
	pj_tinker.personal_gold = 10
	vil_pj.on_player_action(vm, pj_doc, "illness_prosthetic_npc:" + p70_b.get_person_key(), p70_inv)
	assert(vil_pj.has_prosthetic(vm, p70_b.get_person_key()) and p70_inv.gold == 75 and pj_doc.personal_gold == 25 and pj_tinker.personal_gold == 20 and int(pj_tinker.shop_stock["repair_kit"]) == 2 and float(p70_b.health_comp.region_hp["left_arm"]) == 40.0, "PJ.1b: Sponsoring prosthetic pays Doctor (15) + Tinker (10), uses 1 repair_kit, and restores limb")
	# PJ.1c: El propio vecino se costea su prótesis si tiene >= 25 de oro
	vil_pj.amputate(vm, p70_c.get_person_key(), "right_leg", "fractura séptica")
	p70_c.personal_gold = 40
	vil_pj.daily(vm)
	assert(vil_pj.has_prosthetic(vm, p70_c.get_person_key()) and p70_c.personal_gold == 15 and pj_doc.personal_gold == 40 and pj_tinker.personal_gold == 30 and int(pj_tinker.shop_stock["repair_kit"]) == 1 and float(p70_c.health_comp.region_hp["right_leg"]) == 45.0, "PJ.1c: Neighbor with 25+ gold buys their own prosthetic from Doctor & Tinker")
	vil_pj.amputations_of(vm).clear()
	# PJ.2: Red eléctrica lógica (sabotaje de farolas, aspersor o generador general, y reparación por jugador o arreglador)
	vcu_pj.repair_grid(vm)
	assert(vcu_pj.is_lamps_powered(vm) and vcu_pj.is_sprinkler_powered(vm) and not vcu_pj.is_grid_sabotaged(vm), "PJ.2a: Grid starts repaired and powered")
	vcu_pj.sabotage_grid(vm, "lamps", false)
	assert(not vcu_pj.is_lamps_powered(vm) and vcu_pj.is_sprinkler_powered(vm) and vcu_pj.is_grid_sabotaged(vm), "PJ.2b: Sabotaging lamps circuit cuts streetlights while leaving sprinkler circuit intact")
	vcu_pj.sabotage_grid(vm, "sprinkler", false)
	var gm_pj = root.get_node_or_null("/root/GameManager")
	assert(not vcu_pj.is_sprinkler_powered(vm) and bool(gm_pj.get_flag("sprinkler_grid_disabled", false)), "PJ.2c: Sabotaging sprinkler circuit disables electric irrigation")
	p70_inv.remove_item("copper_coil", p70_inv.get_count("copper_coil"))
	p70_inv.add_item("copper_coil", 1)
	p70_inv.gold = 50
	vm.town_state["treasury"] = 100
	vcu_pj.on_player_action(vm, pj_tinker, "culture_repair_grid", p70_inv)
	assert(vcu_pj.is_lamps_powered(vm) and vcu_pj.is_sprinkler_powered(vm) and p70_inv.get_count("copper_coil") == 0 and p70_inv.gold == 62 and int(vm.town_state["treasury"]) == 88, "PJ.2d: Player repairing grid uses 1 copper_coil and receives 12 gold from town treasury")
	vcu_pj.sabotage_grid(vm, "all", false)
	vcu_pj.grid_state(vm)["sabotaged_days"] = 1
	pj_tinker.shop_stock["repair_kit"] = 2
	pj_tinker.personal_gold = 10
	vcu_pj.daily(vm)
	assert(not vcu_pj.is_grid_sabotaged(vm) and vcu_pj.is_lamps_powered(vm) and int(vm.town_state["treasury"]) == 80 and pj_tinker.personal_gold >= 18, "PJ.2e: Tinker repairs sabotaged grid in daily cycle paid by town treasury")
	pj_doc.personal_gold = pj_doc_g0
	pj_tinker.personal_gold = pj_tink_g0
	pj_tinker.shop_stock["repair_kit"] = pj_tink_kits0
	p70_b.personal_gold = pj_bg0
	p70_c.personal_gold = pj_cg0
	vm.town_state["treasury"] = pj_tr0
	print("Block PJ (Amputations & Prosthetics & Logical Electrical Grid) OK")

	# 88. Bloque PK: Sembrar árboles que influyan en el ecosistema y Rutas de comercio con otros lugares
	var pk_eco = get_first_node_in_group("ecosystem_manager")
	assert(pk_eco != null, "PK: EcosystemManager exists")
	var pk_wc_role: int = vt.role_of("woodcutter")
	var pk_frm_role: int = vt.role_of("farmer")
	var pk_wc_prev = vm.trade_npcs.get(pk_wc_role)
	var pk_frm_prev = vm.trade_npcs.get(pk_frm_role)
	vm.trade_npcs[pk_wc_role] = p70_a
	vm.trade_npcs[pk_frm_role] = p70_b
	var pk_ag0: int = p70_a.personal_gold
	var pk_bg0: int = p70_b.personal_gold
	var pk_tr0: int = int(vm.town_state.get("treasury", 0))
	var pk_trees0: int = pk_eco.count_live_trees()
	p70_inv.remove_item("crop_seeds", p70_inv.get_count("crop_seeds"))
	p70_inv.add_item("crop_seeds", 1)
	vcu_pj.forest_state(vm)["planted_trees"] = 0
	vcu_pj.forest_state(vm)["soil_fertility"] = 0
	vcu_pj.on_player_action(vm, p70_a, "culture_plant_tree", p70_inv)
	assert(pk_eco.count_live_trees() == pk_trees0 + 1 and p70_inv.get_count("crop_seeds") == 0 and int(vcu_pj.forest_state(vm)["planted_trees"]) == 1 and int(vcu_pj.forest_state(vm)["soil_fertility"]) == 2, "PK.1a: Planting a pine sapling spawns a new tree node in the ecosystem and enriches soil fertility")
	p70_a.shop_stock["wood"] = 4
	p70_b.shop_stock["wheat"] = 3
	# PK.2: Abrir ruta comercial con Puerto Fluvial del Este (exporta 2 wood -> importa 2 fish + 8 Oro) y ciclo diario
	vcu_pj.state(vm)["trade_routes"] = {}
	p70_inv.gold = 100
	vm.town_state["treasury"] = 50
	vcu_pj.on_player_action(vm, p70_a, "culture_open_route:river_port", p70_inv)
	assert(bool(vcu_pj.trade_routes_of(vm)["river_port"]["active"]) and p70_inv.gold == 75 and int(vm.town_state["treasury"]) == 75, "PK.2a: Opening external trade route pays 25 gold charter fee into town treasury")
	p70_a.personal_gold = 10
	p70_b.shop_stock["fish"] = 0
	vcu_pj.daily(vm)
	# En daily: fertilidad (+1 wood a p70_a, +1 wheat a p70_b) y ruta river_port (-2 wood de p70_a, +2 fish a p70_b, +6 oro a p70_a y +2 a arcas)
	assert(int(p70_a.shop_stock["wood"]) == 3 and int(p70_b.shop_stock["wheat"]) == 4 and int(p70_b.shop_stock["fish"]) == 2 and p70_a.personal_gold == 16 and int(vm.town_state["treasury"]) == 77, "PK.2b: Daily cycle applies forest soil fertility bonus and executes active external trade route")
	p70_inv.remove_item("wood", p70_inv.get_count("wood"))
	p70_inv.remove_item("fish", p70_inv.get_count("fish"))
	p70_inv.add_item("wood", 2)
	p70_inv.gold = 50
	vcu_pj.trade_routes_of(vm)["river_port"]["last_ship_day"] = -99
	vcu_pj.on_player_action(vm, p70_a, "culture_ship_route:river_port", p70_inv)
	assert(p70_inv.get_count("wood") == 0 and p70_inv.get_count("fish") == 2 and p70_inv.gold == 58, "PK.2c: Player shipment exchanges 2 wood for 2 fish and 8 gold from the route's balance")
	assert(not vcu_pj.send_player_shipment(vm, "river_port", p70_inv), "PK.2d: Daily cooldown prevents sending two player shipments on the same route in one day")
	vcu_pj.state(vm)["trade_routes"] = {}
	if pk_wc_prev != null:
		vm.trade_npcs[pk_wc_role] = pk_wc_prev
	else:
		vm.trade_npcs.erase(pk_wc_role)
	if pk_frm_prev != null:
		vm.trade_npcs[pk_frm_role] = pk_frm_prev
	else:
		vm.trade_npcs.erase(pk_frm_role)
	p70_a.personal_gold = pk_ag0
	p70_b.personal_gold = pk_bg0
	vm.town_state["treasury"] = pk_tr0
	print("Block PK (Tree Planting & Ecosystem & External Trade Routes) OK")

	# 89. Bloque PL: Árbol de investigación tecnológica e Incursiones organizadas contra el pueblo
	var pl_tink_g0: int = pj_tinker.personal_gold
	var pl_tr0: int = int(vm.town_state.get("treasury", 0))
	var pl_bkr_role: int = vt.role_of("baker")
	var pl_bkr_prev = vm.trade_npcs.get(pl_bkr_role)
	vm.trade_npcs[pl_bkr_role] = p70_a
	vcu_pj.state(vm)["research"] = {}
	vcu_pj.state(vm)["raids"] = {}
	p70_inv.gold = 100
	pj_tinker.personal_gold = 10
	assert(not vcu_pj.start_research(vm, "reinforced_locks", pj_tinker, p70_inv), "PL.1a: Prerequisite prevents starting advanced tech before base tech")
	vcu_pj.on_player_action(vm, pj_tinker, "culture_start_tech:waterwheel_gears", p70_inv)
	assert(str(vcu_pj.research_state(vm)["active_tech"]) == "waterwheel_gears" and p70_inv.gold == 75 and pj_tinker.personal_gold == 35, "PL.1b: Funding research transfers 25 gold to engineer and starts project")
	p70_inv.remove_item("bandit_scrap", p70_inv.get_count("bandit_scrap"))
	p70_inv.add_item("bandit_scrap", 1)
	vcu_pj.on_player_action(vm, pj_tinker, "culture_boost_tech", p70_inv)
	p70_a.shop_stock["bread"] = 4
	vcu_pj.daily(vm)
	assert(vcu_pj.has_tech(vm, "waterwheel_gears") and p70_inv.get_count("bandit_scrap") == 0, "PL.1c: Scrap boost + daily engineering completes research and unlocks tech")
	vcu_pj.daily(vm)
	assert(int(p70_a.shop_stock["bread"]) == 5, "PL.1d: Unlocked waterwheel_gears tech grants +1 daily bread to bakery")
	# PL.2: Incursiones organizadas contra el pueblo (milicia, rechazo con recompensa de las arcas y saqueo si se pierde)
	p70_inv.gold = 100
	vm.town_state["treasury"] = 100
	vcu_pj.on_player_action(vm, p70_b, "culture_fund_militia", p70_inv)
	assert(p70_inv.gold == 85 and int(vm.town_state["treasury"]) == 115 and int(vcu_pj.raids_state(vm)["militia_bonus"]) == 2, "PL.2a: Funding militia transfers 15 gold to town treasury and adds +2 defense")
	vcu_pj.start_raid_warning(vm, "bandits")
	assert(not (vcu_pj.raids_state(vm)["active_raid"] as Dictionary).is_empty(), "PL.2b: Raid warning registers an imminent attack")
	var pl_win: Dictionary = vcu_pj.resolve_raid(vm, true, p70_inv, 1)
	assert(bool(pl_win["repelled"]) and p70_inv.gold == 105 and int(vm.town_state["treasury"]) == 95 and int(vcu_pj.raids_state(vm)["raids_repelled"]) == 1, "PL.2c: Repelling raid with player pays 20 gold bounty from town treasury")
	vcu_pj.start_raid_warning(vm, "bandits")
	var pl_loss: Dictionary = vcu_pj.resolve_raid(vm, false, null, -1)
	assert(not bool(pl_loss["repelled"]) and int(vm.town_state["treasury"]) == 65 and int(vcu_pj.raids_state(vm)["raids_suffered"]) == 1, "PL.2d: Losing a raid pillages 30 gold from town treasury")
	vcu_pj.state(vm)["research"] = {}
	vcu_pj.state(vm)["raids"] = {}
	if pl_bkr_prev != null:
		vm.trade_npcs[pl_bkr_role] = pl_bkr_prev
	else:
		vm.trade_npcs.erase(pl_bkr_role)
	pj_tinker.personal_gold = pl_tink_g0
	vm.town_state["treasury"] = pl_tr0
	print("Block PL (Tech Research Tree & Organized Village Raids) OK")

	# 90. Bloque PM: Expediciones de exploración y hallazgos arqueológicos y Caballos / Carretas de carga en el rancho
	var pm_ag0: int = p70_a.personal_gold
	var pm_read0: int = int(vcu_pj.state(vm).get("readings", 0))
	vcu_pj.state(vm)["mounts"] = {}
	vcu_pj.state(vm)["exploration"] = {}
	p70_inv.gold = 120
	p70_a.personal_gold = 10
	vcu_pj.on_player_action(vm, p70_a, "culture_buy_horse", p70_inv)
	assert(vcu_pj.has_horse(vm) and p70_inv.gold == 75 and p70_a.personal_gold == 55, "PM.1a: Buying riding horse transfers 45 gold to rancher and activates mount")
	vcu_pj.on_player_action(vm, p70_a, "culture_buy_cart", p70_inv)
	assert(vcu_pj.has_cart(vm) and p70_inv.gold == 20 and p70_a.personal_gold == 110, "PM.1b: Buying cargo cart transfers 55 gold to rancher and activates cart")
	p70_inv.remove_item("copper_coil", p70_inv.get_count("copper_coil"))
	p70_inv.gold = 50
	var pm_exp_win: Dictionary = vcu_pj.run_expedition(vm, "west_ruins", p70_a, p70_inv, 1)
	assert(bool(pm_exp_win["ok"]) and bool(pm_exp_win["won"]) and p70_inv.gold == 38 and p70_a.personal_gold == 122 and p70_inv.get_count("copper_coil") == 1 and int(vcu_pj.state(vm)["readings"]) == pm_read0 + 2, "PM.2a: Successful expedition pays 12 gold to guide, yields relic item and adds +2 library readings")
	assert(not bool(vcu_pj.run_expedition(vm, "west_ruins", p70_a, p70_inv, 1).get("ok", false)), "PM.2b: Daily cooldown prevents running two expeditions on the same day")
	vcu_pj.exploration_state(vm)["last_exp_day"] = -99
	var pm_exp_loss: Dictionary = vcu_pj.run_expedition(vm, "north_caves", p70_a, p70_inv, -1)
	assert(bool(pm_exp_loss["ok"]) and not bool(pm_exp_loss["won"]) and p70_inv.gold == 26, "PM.2c: Failed expedition still consumes supplies and can be lost")
	# PM.1c: La carreta de carga añade +4 de oro de bonificación por remesa comercial
	vcu_pj.state(vm)["trade_routes"] = {}
	vcu_pj.trade_routes_of(vm)["river_port"]["active"] = true
	p70_inv.remove_item("wood", p70_inv.get_count("wood"))
	p70_inv.add_item("wood", 2)
	p70_inv.gold = 50
	assert(vcu_pj.send_player_shipment(vm, "river_port", p70_inv) and p70_inv.gold == 62, "PM.1c: Cargo cart increases player shipment payout from 8 to 12 gold from route balance")
	vcu_pj.state(vm)["mounts"] = {}
	vcu_pj.state(vm)["exploration"] = {}
	vcu_pj.state(vm)["trade_routes"] = {}
	vcu_pj.state(vm)["readings"] = pm_read0
	p70_a.personal_gold = pm_ag0
	print("Block PM (Exploration Expeditions & Ranch Horses and Carts) OK")

	# ==========================================================================
	# 91. Bloque PN — Niveles verticales por capas (elevation_level) y Alcantarillas con localizaciones nuevas
	# ==========================================================================
	assert(vm.are_on_same_elevation(0, 0) and not vm.are_on_same_elevation(-1, 0) and vm.distance_on_same_level(Vector2.ZERO, -1, Vector2.ONE, 0) == INF, "PN.1a: Elevation helper functions isolate distances across different vertical layers")
	var pn_pos: Vector2 = Vector2(465.0, 48.0)
	p70_a.is_dead = false
	p70_a.is_downed = false
	p70_a.is_sleeping = false
	p70_a.is_stunned_flag = false
	p70_a.sedated_timer = 0.0
	p70_a.global_position = pn_pos + Vector2(12.0, 0.0)
	vm.set_npc_elevation_level(p70_a, 0)
	vm.set_player_elevation_level(0)
	assert(vm._find_conscious_witness_near(pn_pos, 120.0, null) != null, "PN.1b: Street-level witness sees actions when player is also on street level 0")
	vm.set_player_elevation_level(-1)
	assert(vm._find_conscious_witness_near(pn_pos, 120.0, null) == null, "PN.1c: Street-level (0) NPCs do not witness actions performed in the sewers/cellar (-1)")
	vm.set_npc_elevation_level(p70_a, -1)
	assert(vm._find_conscious_witness_near(pn_pos, 120.0, null) != null, "PN.1d: An NPC on level -1 witnesses actions on level -1")
	vm.set_npc_elevation_level(p70_a, 0)
	vm.set_player_elevation_level(0)
	# PN.1e: Comprar altillo / primer piso ("upper_floor") y subir a nivel +1
	var pn_lot: String = vho.primary_player_lot(vm)
	if pn_lot == "":
		pn_lot = "n0"
		vm.VillageLots.lot(vm, pn_lot)["payer"] = "player"
		vm.VillageLots.lot(vm, pn_lot)["status"] = "built"
	var pn_lot_st: Dictionary = vm.VillageLots.lot(vm, pn_lot)
	if not pn_lot_st.has("upgrades") or not (pn_lot_st["upgrades"] is Dictionary):
		pn_lot_st["upgrades"] = {}
	pn_lot_st["upgrades"]["upper_floor"] = false
	p70_inv.gold = 90
	vho.on_player_action(vm, p70_a, "housing_upgrade:upper_floor", p70_inv)
	assert(vho.has_upgrade(vm, "upper_floor") and p70_inv.gold == 40, "PN.1e: Buying upper_floor upgrade costs 50 gold and unlocks upper floor")
	vho.on_player_action(vm, p70_a, "housing_change_level:1", p70_inv)
	assert(vm.player_elevation_level == 1, "PN.1f: housing_change_level:1 moves player to vertical layer +1")
	vho.on_player_action(vm, p70_a, "housing_change_level:0", p70_inv)
	assert(vm.player_elevation_level == 0, "PN.1g: housing_change_level:0 returns player to street level 0")
	# PN.2: Red de alcantarillas bajo el pueblo (Cisterna, Pasadizo del Contrabandista y Bóveda Inundada)
	vun.state(vm)["sewers"] = {"unlocked": false, "current_loc": "", "last_explore_day": -99, "lost_coins_pool": 14, "explored_count": 0}
	var pn_ag0: int = int(p70_a.personal_gold)
	p70_inv.gold = 60
	vun.on_player_action(vm, p70_a, "underworld_unlock_sewers", p70_inv)
	assert(bool(vun.sewers_state(vm).get("unlocked", false)) and p70_inv.gold == 40 and int(p70_a.personal_gold) == pn_ag0 + 20, "PN.2a: Unlocking the sewers pays 20 gold to the contact's pocket")
	var pn_scrap0: int = p70_inv.get_count("bandit_scrap")
	vm.wanted_level = 2
	var pn_res1: Dictionary = vun.explore_sewer_location(vm, "smuggler_tunnel", p70_inv, 1)
	assert(bool(pn_res1.get("ok", false)) and bool(pn_res1.get("success", false)) and vm.player_elevation_level == -1 and p70_inv.get_count("bandit_scrap") == pn_scrap0 + 1 and p70_inv.gold == 46 and int(vun.sewers_state(vm).get("lost_coins_pool", 0)) == 8 and vm.wanted_level == 1, "PN.2b: Exploring smuggler_tunnel moves player to level -1, yields loot + 6 coins from lost_coins_pool, and reduces wanted_level by 1")
	assert(not bool(vun.explore_sewer_location(vm, "cistern", p70_inv, 1).get("ok", false)), "PN.2c: Sewer exploration is limited to 1 per day")
	vun.sewers_state(vm)["last_explore_day"] = -99
	var pn_hyg0: float = float(vm.VillageNeeds.state(vm).get("player_hygiene", 80.0))
	var pn_res2: Dictionary = vun.explore_sewer_location(vm, "flooded_vault", p70_inv, -1)
	assert(bool(pn_res2.get("ok", false)) and not bool(pn_res2.get("success", true)) and float(vm.VillageNeeds.state(vm).get("player_hygiene", 80.0)) < pn_hyg0, "PN.2d: Failed sewer exploration reduces player hygiene and health")
	vun.on_player_action(vm, p70_a, "underworld_sewer_surface", p70_inv)
	assert(vm.player_elevation_level == 0 and str(vun.sewers_state(vm).get("current_loc", "")) == "", "PN.2e: underworld_sewer_surface returns player to street level 0")
	vm.wanted_level = 0
	p70_a.personal_gold = pn_ag0
	print("Block PN (Vertical Elevation Layers & Village Sewers) OK")

	# ==========================================================================
	# 92. Bloque PO — Armas de fuego de chispa y Terminales lógicas / Hackeo electromecánico
	# ==========================================================================
	var po_ag0: int = int(p70_a.personal_gold)
	var po_tr0: int = int(vm.town_state.get("treasury", 0))
	vcu_pj.state(vm)["research"] = {}
	vcu_pj.state(vm)["terminal"] = {}
	p70_inv.remove_item("flintlock_pistol", p70_inv.get_count("flintlock_pistol"))
	p70_inv.remove_item("powder_charge", p70_inv.get_count("powder_charge"))
	p70_inv.gold = 100
	p70_a.personal_gold = 10
	assert(not vcu_pj.buy_firearm(vm, p70_a, p70_inv), "PO.1a: Firearm requires reinforced_locks technology unlocked first")
	(vcu_pj.research_state(vm)["unlocked"] as Dictionary)["reinforced_locks"] = true
	vcu_pj.on_player_action(vm, p70_a, "culture_buy_firearm", p70_inv)
	assert(p70_inv.has_item("flintlock_pistol", 1) and p70_inv.get_count("powder_charge") == 2 and p70_inv.gold == 40 and p70_a.personal_gold == 70, "PO.1b: Buying firearm transfers 60 gold to artisan and grants flintlock_pistol + 2 powder_charge")
	vcu_pj.on_player_action(vm, p70_a, "culture_buy_powder", p70_inv)
	assert(p70_inv.get_count("powder_charge") == 4 and p70_inv.gold == 26 and p70_a.personal_gold == 84, "PO.1c: Buying powder pack transfers 14 gold to artisan and adds 2 powder_charge")
	var po_def_no_gun: int = vcu_pj.defense_power(vm, true, null)
	var po_def_with_gun: int = vcu_pj.defense_power(vm, true, p70_inv)
	assert(po_def_with_gun == po_def_no_gun + 3, "PO.1d: Carrying a loaded flintlock firearm adds +3 defense power against raids")
	vcu_pj.on_player_action(vm, p70_b, "culture_fire_flintlock", p70_inv)
	assert(p70_inv.get_count("powder_charge") == 3 and str(p70_b.last_hit_weapon_name) == "Arcabuz de Chispa", "PO.1e: Firing flintlock consumes 1 powder_charge and wounds target")
	# PO.2: Hackeo de la terminal lógica electromecánica (reembolso fiscal de las arcas, purga de búsqueda y alarma si falla)
	vm.town_state["treasury"] = 80
	p70_inv.gold = 30
	var po_hack1: Dictionary = vcu_pj.hack_terminal(vm, "census_ledger", p70_inv, 1)
	assert(bool(po_hack1.get("ok", false)) and bool(po_hack1.get("won", false)) and p70_inv.gold == 48 and int(vm.town_state["treasury"]) == 62, "PO.2a: Hacking census_ledger siphons 18 gold from town treasury into player's purse")
	assert(not bool(vcu_pj.hack_terminal(vm, "warrant_archive", p70_inv, 1).get("ok", false)), "PO.2b: Daily cooldown prevents hacking terminal twice on the same day")
	vcu_pj.terminal_state(vm)["last_hack_day"] = -99
	vm.wanted_level = 2
	vm.bounty_gold = 50
	var po_hack2: Dictionary = vcu_pj.hack_terminal(vm, "warrant_archive", p70_inv, 1)
	assert(bool(po_hack2.get("ok", false)) and bool(po_hack2.get("won", false)) and vm.wanted_level == 1 and vm.bounty_gold == 25, "PO.2c: Hacking warrant_archive reduces wanted_level by 1 and bounty_gold by 25")
	vcu_pj.terminal_state(vm)["last_hack_day"] = -99
	var po_hack_fail: Dictionary = vcu_pj.hack_terminal(vm, "grid_controller", p70_inv, -1)
	assert(bool(po_hack_fail.get("ok", false)) and not bool(po_hack_fail.get("won", true)) and vm.wanted_level == 2 and int(vcu_pj.terminal_state(vm)["alarms_triggered"]) == 1, "PO.2d: Failing a terminal hack triggers logical alarm and raises wanted_level")
	p70_inv.remove_item("flintlock_pistol", p70_inv.get_count("flintlock_pistol"))
	p70_inv.remove_item("powder_charge", p70_inv.get_count("powder_charge"))
	vcu_pj.state(vm)["research"] = {}
	vcu_pj.state(vm)["terminal"] = {}
	vm.wanted_level = 0
	vm.bounty_gold = 0
	p70_a.personal_gold = po_ag0
	vm.town_state["treasury"] = po_tr0
	print("Block PO (Flintlock Firearms & Electromechanical Logic Terminals) OK")

	# ==========================================================================
	# 93. Bloque PP — Crear tu propio asentamiento fronterizo e Historia Principal en 4 capítulos (panel [L])
	# ==========================================================================
	var pp_ag0: int = int(p70_a.personal_gold)
	var pp_bg0: int = int(p70_b.personal_gold)
	var pp_b_role0: int = int(p70_b.trade_role)
	var pp_tr0: int = int(vm.town_state.get("treasury", 0))
	vcu_pj.state(vm)["outpost"] = {}
	vcu_pj.state(vm)["main_story"] = {}
	p70_inv.remove_item("wood", p70_inv.get_count("wood"))
	p70_inv.remove_item("stone", p70_inv.get_count("stone"))
	p70_inv.add_item("wood", 2)
	p70_inv.add_item("stone", 2)
	p70_inv.gold = 150
	vm.town_state["treasury"] = 100
	vcu_pj.on_player_action(vm, p70_a, "culture_found_outpost", p70_inv)
	assert(bool(vcu_pj.outpost_state(vm).get("founded", false)) and p70_inv.gold == 60 and int(vm.town_state["treasury"]) == 170 and int(vcu_pj.outpost_state(vm)["treasury"]) == 20, "PP.1a: Founding outpost costs 90 gold + 2 wood + 2 stone, adds 70 to town treasury and seeds 20 in outpost treasury")
	p70_b.trade_role = load("res://scripts/enemies/VillageNPC.gd").TradeRole.UNEMPLOYED
	p70_b.personal_gold = 5
	vcu_pj.on_player_action(vm, p70_b, "culture_recruit_settler", p70_inv)
	assert((vcu_pj.outpost_state(vm)["settlers"] as Array).has(p70_b.get_person_key()) and p70_inv.gold == 45 and p70_b.personal_gold == 20, "PP.1b: Recruiting settler transfers 15 gold to unemployed villager and registers settler")
	p70_a.personal_gold = 10
	vcu_pj.on_player_action(vm, p70_a, "culture_upgrade_outpost:sawmill", p70_inv)
	assert(bool(vcu_pj.outpost_state(vm)["upgrades"]["sawmill"]) and p70_inv.gold == 10 and p70_a.personal_gold == 45, "PP.1c: Upgrading outpost sawmill transfers 35 gold to artisan")
	vcu_pj.trade_routes_of(vm)["river_port"]["balance"] = 30
	vcu_pj.process_outpost_daily(vm)
	# Con 1 colono y aserradero: cobra 6 de peaje de la ruta (+6 a arca -> 26) y paga 3 de jornal al colono (arca -> 23, p70_b -> 23)
	assert(int(vcu_pj.outpost_state(vm)["treasury"]) == 23 and p70_b.personal_gold == 23, "PP.1d: Daily outpost cycle collects route toll into outpost treasury and pays 3 gold wage to settler")
	vcu_pj.on_player_action(vm, p70_a, "culture_collect_outpost", p70_inv)
	assert(p70_inv.gold == 27 and int(vcu_pj.outpost_state(vm)["treasury"]) == 6, "PP.1e: Collecting outpost surplus leaves 6 gold wage reserve and transfers 17 gold to player")
	# PP.2: Historia Principal en 4 capítulos en QuestManager (categoría "main" del panel [L])
	var qm_pp = root.get_node_or_null("/root/QuestManager")
	assert(qm_pp != null, "PP.2: QuestManager exists")
	qm_pp.quests.erase("main_ch1")
	qm_pp.quests.erase("main_ch2")
	qm_pp.quests.erase("main_ch3")
	qm_pp.quests.erase("main_ch4")
	vcu_pj.exploration_state(vm)["discoveries"] = 1
	(vcu_pj.research_state(vm)["unlocked"] as Dictionary)["waterwheel_gears"] = true
	p70_inv.gold = 10
	vm.town_state["treasury"] = 200
	var pp_adv: int = vcu_pj.sync_main_story(vm, p70_inv)
	assert(pp_adv == 4 and bool(vcu_pj.main_story_state(vm).get("completed", false)) and str(qm_pp.get_quest("main_ch4").get("status", "")) == "completed" and p70_inv.gold == 125 and int(vm.town_state["treasury"]) == 85, "PP.2a: Completing all 4 main story chapters registers them in QuestManager ('main' tab) and pays 20+25+30+40=115 gold from town treasury")
	vcu_pj.state(vm)["outpost"] = {}
	vcu_pj.state(vm)["main_story"] = {}
	vcu_pj.state(vm)["research"] = {}
	vcu_pj.state(vm)["exploration"] = {}
	p70_b.trade_role = pp_b_role0
	p70_a.personal_gold = pp_ag0
	p70_b.personal_gold = pp_bg0
	vm.town_state["treasury"] = pp_tr0
	print("Block PP (Player Outpost Settlement & 4-Chapter Main Story) OK")

	print("ALL RIMWORLD MEDICAL, FOOTPRINTS, 3-PHASE CORPSE REPORT, MULTI-CORPSE FIX, RPG INTERROGATION, PUBLIC TRIAL, DYNAMIC RELATIONSHIPS, MISSING FAMILY SEARCH, SOCIAL GLOSSARY & UNCONSCIOUS REACTION TESTS PASSED!")
	quit(0)
