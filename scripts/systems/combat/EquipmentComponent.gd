extends Node
class_name EquipmentComponent

signal equipment_changed

var main_hand: WeaponData
var off_hand: WeaponData

func equip_main(weapon: WeaponData) -> void:
	if weapon == null:
		unequip_main()
		return

	if weapon.handedness == CombatConstants.Handedness.TWO_HAND:
		unequip_off()
		main_hand = weapon
	else:
		main_hand = weapon
	
	equipment_changed.emit()

func equip_off(weapon: WeaponData) -> void:
	if weapon == null:
		unequip_off()
		return
		
	if main_hand and main_hand.handedness == CombatConstants.Handedness.TWO_HAND:
		print("Cannot equip offhand weapon while holding a two-handed weapon.")
		return
	
	if weapon.handedness == CombatConstants.Handedness.TWO_HAND:
		print("Two-handed weapons must be equipped in the main hand.")
		return
		
	off_hand = weapon
	equipment_changed.emit()

func unequip_main() -> void:
	main_hand = null
	equipment_changed.emit()

func unequip_off() -> void:
	off_hand = null
	equipment_changed.emit()

func get_current_damage() -> float:
	var total = 0.0
	if main_hand and main_hand.damage_data:
		total += main_hand.damage_data.amount
	if off_hand and off_hand.damage_data:
		total += off_hand.damage_data.amount
	return total
