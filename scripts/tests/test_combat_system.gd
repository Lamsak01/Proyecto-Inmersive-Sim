extends SceneTree

func _init():
	print("Starting Combat System Verification...")
	test_armor_mitigation()
	test_equipment_logic()
	print("Verification Complete.")
	quit()

func test_armor_mitigation():
	print("\n--- Test Armor Mitigation ---")
	var armor = ArmorComponent.new()
	var dmg = DamageData.new()
	
	# Test 1: Cut vs Cloth (Expecting x1.5)
	armor.equip(CombatConstants.ArmorSlot.BODY, CombatConstants.ArmorMaterial.CLOTH)
	dmg.type = CombatConstants.DamageType.CUT
	dmg.amount = 10.0
	var res = armor.calculate_mitigation(dmg)
	assert_eq(res.amount, 15.0, "Cut vs Cloth should be x1.5")
	
	# Test 2: Cut vs Metal (Expecting x0.5)
	armor.equip(CombatConstants.ArmorSlot.BODY, CombatConstants.ArmorMaterial.METAL)
	dmg.amount = 10.0
	res = armor.calculate_mitigation(dmg)
	assert_eq(res.amount, 5.0, "Cut vs Metal should be x0.5")
	
	print("Armor Mitigation Tests Passed.")

func test_equipment_logic():
	print("\n--- Test Equipment Logic ---")
	var equip = EquipmentComponent.new()
	
	var sword_1h = WeaponData.new()
	sword_1h.name = "Sword 1H"
	sword_1h.handedness = CombatConstants.Handedness.ONE_HAND
	
	var shield = WeaponData.new()
	shield.name = "Shield"
	shield.handedness = CombatConstants.Handedness.ONE_HAND
	
	var axe_2h = WeaponData.new()
	axe_2h.name = "Axe 2H"
	axe_2h.handedness = CombatConstants.Handedness.TWO_HAND
	
	# Test 1: Equip 1H + Shield
	equip.equip_main(sword_1h)
	equip.equip_off(shield)
	assert_eq(equip.main_hand, sword_1h, "Main hand should have Sword")
	assert_eq(equip.off_hand, shield, "Off hand should have Shield")
	
	# Test 2: Equip 2H (Should clear offhand)
	equip.equip_main(axe_2h)
	assert_eq(equip.main_hand, axe_2h, "Main hand should have Axe 2H")
	assert_eq(equip.off_hand, null, "Off hand should be empty after equipping 2H")
	
	print("Equipment Logic Tests Passed.")

func assert_eq(actual, expected, msg):
	if actual != expected:
		print("FAILED: ", msg, " | Expected: ", expected, ", Got: ", actual)
	else:
		print("PASS: ", msg)
