extends Resource
class_name WeaponData

@export var name: String = "Weapon"
@export var handedness: CombatConstants.Handedness = CombatConstants.Handedness.ONE_HAND
@export var damage_data: DamageData
@export var scene_path: String = "" # Path to the weapon's visual scene or sprite
@export var icon: Texture2D
