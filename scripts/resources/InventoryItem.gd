class_name InventoryItem
extends Resource

@export var id: String = ""
@export var name: String = "Item"
@export var description: String = ""
@export var texture: Texture2D
@export var grid_size: Vector2i = Vector2i(1, 1)

@export_group("Usage Data")
@export var is_weapon: bool = false
@export var weapon_data: Resource # Type WeaponData

@export var is_consumable: bool = false
@export var heal_amount: float = 0.0

func use(player: Node) -> bool:
	var used = false
	
	if is_weapon:
		var combat_ctrl = player.get_node_or_null("PlayerCombatController")
		if combat_ctrl and weapon_data:
			combat_ctrl.equip_weapon(weapon_data)
			used = true
			
	if is_consumable:
		var health_comp = player.get_node_or_null("HealthComponent")
		if health_comp and health_comp.current_health < health_comp.max_health:
			health_comp.heal(heal_amount)
			used = true
			
	return used
