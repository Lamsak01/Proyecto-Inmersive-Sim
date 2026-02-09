extends Resource
class_name DamageData

@export var amount: float = 0.0
@export var type: CombatConstants.DamageType = CombatConstants.DamageType.BLUNT
@export var bleed_chance: float = 0.0
var source: Node

func copy() -> DamageData:
	var new_data = DamageData.new()
	new_data.amount = amount
	new_data.type = type
	new_data.bleed_chance = bleed_chance
	new_data.source = source
	return new_data
