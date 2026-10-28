extends Resource
class_name DamageData

@export var amount: float = 0.0
@export var type: CombatConstants.DamageType = CombatConstants.DamageType.BLUNT
@export var bleed_buildup: float = 0.0 ## Acumulación de sangrado por golpe (armas cortantes)
@export var stun_buildup: float = 0.0 ## Acumulación de aturdimiento por golpe (armas contundentes)
@export var bleed_chance: float = 0.0 ## Legado / opcional
@export var knockback_force: float = 0.0
var source: Node

func copy() -> DamageData:
	var new_data = DamageData.new()
	new_data.amount = amount
	new_data.type = type
	new_data.bleed_buildup = bleed_buildup
	new_data.stun_buildup = stun_buildup
	new_data.bleed_chance = bleed_chance
	new_data.knockback_force = knockback_force
	new_data.source = source
	return new_data
