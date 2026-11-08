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
var is_ranged_projectile: bool = false
var is_firearm_bullet: bool = false
var firearm_kind: String = "" ## "pistol" o "rifle"
var shot_distance_px: float = 0.0
var is_aimed_shot: bool = false
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
	new_data.is_ranged_projectile = is_ranged_projectile
	new_data.is_firearm_bullet = is_firearm_bullet
	new_data.firearm_kind = firearm_kind
	new_data.shot_distance_px = shot_distance_px
	new_data.is_aimed_shot = is_aimed_shot
	new_data.source = source
	return new_data
