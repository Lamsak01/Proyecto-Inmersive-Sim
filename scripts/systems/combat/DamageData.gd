extends Resource
class_name DamageData

@export var amount: float = 0.0
@export var type: CombatConstants.DamageType = CombatConstants.DamageType.BLUNT
@export var bleed_buildup: float = 0.0 ## Acumulación de sangrado por golpe (armas cortantes)
@export var stun_buildup: float = 0.0 ## Acumulación de aturdimiento por golpe (armas contundentes)
@export var logging_efficiency: float = 0.35 ## Multiplicador de eficiencia al talar árboles (Espada = 0.35, Hacha = 1.8)
@export var mining_efficiency: float = 0.35 ## Multiplicador de eficiencia al picar rocas/vetas (Martillo = 0.35, Pico = 1.8)
@export var bleed_chance: float = 0.0 ## Legado / opcional
@export var knockback_force: float = 0.0
var weapon_tag: String = ""
var source: Node

func copy() -> DamageData:
	var new_data = DamageData.new()
	new_data.amount = amount
	new_data.type = type
	new_data.bleed_buildup = bleed_buildup
	new_data.stun_buildup = stun_buildup
	new_data.logging_efficiency = logging_efficiency
	new_data.mining_efficiency = mining_efficiency
	new_data.bleed_chance = bleed_chance
	new_data.knockback_force = knockback_force
	new_data.weapon_tag = weapon_tag
	new_data.source = source
	return new_data
