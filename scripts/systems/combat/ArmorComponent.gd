extends Node
class_name ArmorComponent

# Slot -> Material
var equipped_armor: Dictionary = {
	CombatConstants.ArmorSlot.HEAD: CombatConstants.ArmorMaterial.NONE,
	CombatConstants.ArmorSlot.BODY: CombatConstants.ArmorMaterial.NONE,
	CombatConstants.ArmorSlot.LEGS: CombatConstants.ArmorMaterial.NONE
}

func equip(slot: CombatConstants.ArmorSlot, material: CombatConstants.ArmorMaterial) -> void:
	equipped_armor[slot] = material

func unequip(slot: CombatConstants.ArmorSlot) -> void:
	equipped_armor[slot] = CombatConstants.ArmorMaterial.NONE

func calculate_mitigation(data: DamageData) -> DamageData:
	var new_data = data.copy()
	
	match data.type:
		CombatConstants.DamageType.CUT:
			var body_mat = equipped_armor[CombatConstants.ArmorSlot.BODY]
			match body_mat:
				CombatConstants.ArmorMaterial.NONE:
					new_data.amount *= 1.5
					new_data.bleed_chance *= 1.5
				CombatConstants.ArmorMaterial.CLOTH:
					new_data.amount *= 1.5
					new_data.bleed_chance *= 1.2
				CombatConstants.ArmorMaterial.LEATHER:
					new_data.amount *= 1.0
				CombatConstants.ArmorMaterial.METAL:
					new_data.amount *= 0.5
					new_data.bleed_chance *= 0.1
					
		CombatConstants.DamageType.ELECTRIC:
			var has_metal = false
			for slot in equipped_armor:
				if equipped_armor[slot] == CombatConstants.ArmorMaterial.METAL:
					has_metal = true
					break
			if has_metal:
				new_data.amount *= 1.25
				
		CombatConstants.DamageType.THERMAL:
			pass
			
		CombatConstants.DamageType.BLUNT:
			pass

	return new_data

func get_metal_piece_count() -> int:
	var count = 0
	for slot in equipped_armor:
		if equipped_armor[slot] == CombatConstants.ArmorMaterial.METAL:
			count += 1
	return count
