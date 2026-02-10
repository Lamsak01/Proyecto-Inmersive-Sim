@tool
extends SceneTree

func _init():
	var damage = load("res://scripts/systems/combat/DamageData.gd").new()
	damage.amount = 10.0
	damage.type = 0 # CUT (Assuming 0 based on enum)
	
	var sword = load("res://scripts/systems/combat/WeaponData.gd").new()
	sword.name = "Sword"
	sword.handedness = 0 # ONE_HAND
	sword.damage_data = damage
	sword.icon = load("res://assests/items/sword.png")
	
	var err = ResourceSaver.save(sword, "res://resources/weapons/Sword.tres")
	if err == OK:
		print("Successfully saved Sword.tres")
	else:
		print("Failed to save Sword.tres: ", err)
	quit()
