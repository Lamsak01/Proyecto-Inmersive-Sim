extends Node
class_name SimpleInventory

## Sistema de Inventario Ligero y Crafteo — Fase 2.2 / Fase 3
## Gestiona recursos recolectados (Tala, Minería, Forrajeo), consumibles, recetas de crafteo y serialización JSON.

signal inventory_changed()
signal item_added(item_id: String, amount: int, new_total: int)
signal item_removed(item_id: String, amount: int, new_total: int)
signal gold_changed(new_gold: int)
signal recipe_crafted(recipe_id: String, result_item: String)

const CATALOG: Dictionary = {
	"wood": {
		"name": "Madera",
		"category": "Material",
		"desc": "Troncos obtenidos talando árboles ([1] Arma Cortante). Útil para leña y construcción.",
		"usable": false
	},
	"stone": {
		"name": "Piedra",
		"category": "Material",
		"desc": "Roca firme extraída con herramientas contundentes ([2] Martillo).",
		"usable": false
	},
	"iron_ore": {
		"name": "Mineral de Hierro",
		"category": "Material",
		"desc": "Mineral bruto extraído de vetas rocosas. Valioso en la herrería.",
		"usable": false
	},
	"herbs": {
		"name": "Hierbas Medicinales",
		"category": "Forrajeo",
		"desc": "Plantas silvestres coagulantes. Úsalas directo (+10 HP) o craftea vendajes.",
		"usable": true,
		"heal_hp": 10.0,
		"stop_bleed": true
	},
	"mushroom": {
		"name": "Hongo Silvestre",
		"category": "Forrajeo",
		"desc": "Hongo del bosque. Comestible crudo (+12 HP, +15 Hambre) o cocinable en la cacerola.",
		"usable": true,
		"heal_hp": 12.0,
		"restore_stamina": 20.0,
		"restore_hunger": 15.0
	},
	"crop_seeds": {
		"name": "Semillas del Valle",
		"category": "Agricultura",
		"desc": "Semillas silvestres del bosque. Puedes usarlas para extraer semillas de cultivo.",
		"usable": false
	},
	"carrot_seeds": {
		"name": "Semillas de Zanahoria",
		"category": "Agricultura",
		"desc": "Ciclo rápido (2 días, o 1 día con abono). Pulsa [E] en tierra vacía para plantar o [R] para alternar semilla.",
		"usable": true,
		"is_seed": true
	},
	"cabbage_seeds": {
		"name": "Semillas de Col",
		"category": "Agricultura",
		"desc": "Ciclo medio (3 días, o 2 días con abono). Cosecha abundante y muy nutritiva.",
		"usable": true,
		"is_seed": true
	},
	"wheat_seeds": {
		"name": "Semillas de Trigo",
		"category": "Agricultura",
		"desc": "Ciclo largo (4 días, o 3 días con abono). Produce trigo para hornear pan.",
		"usable": true,
		"is_seed": true
	},
	"fertilizer": {
		"name": "Abono Orgánico",
		"category": "Agricultura",
		"desc": "Compost nutritivo. Aplícalo con [E] en un cultivo regado para adelantar +1 día y obtener +1 cosecha extra.",
		"usable": false
	},
	"carrot": {
		"name": "Zanahoria Fresca",
		"category": "Cosecha",
		"desc": "Hortaliza crujiente (+16 HP, +22 Hambre). Puedes cocinarla en la cacerola de la hoguera.",
		"usable": true,
		"heal_hp": 16.0,
		"restore_stamina": 25.0,
		"restore_hunger": 22.0
	},
	"cabbage": {
		"name": "Col de Huerta",
		"category": "Cosecha",
		"desc": "Repollo grande (+30 HP, +32 Hambre). Puedes cocinarlo en la cacerola de la hoguera.",
		"usable": true,
		"heal_hp": 30.0,
		"restore_stamina": 40.0,
		"restore_hunger": 32.0
	},
	"wheat": {
		"name": "Gavilla de Trigo",
		"category": "Cosecha",
		"desc": "Cereal maduro listo para hornear Pan o alimentar a las gallinas.",
		"usable": false
	},
	"cooked_vegetable": {
		"name": "Verdura Cocida",
		"category": "Alimento",
		"desc": "Plato caliente preparado en la cacerola de la hoguera (+28 HP, +40 STM, +45 Hambre).",
		"usable": true,
		"heal_hp": 28.0,
		"restore_stamina": 40.0,
		"restore_hunger": 45.0
	},
	"egg": {
		"name": "Huevo Fresco",
		"category": "Ganadería",
		"desc": "Huevo recién puesto en el Gallinero. Cómetelo crudo (+10 HP, +18 Hambre) o cocínalo en la hoguera.",
		"usable": true,
		"heal_hp": 10.0,
		"restore_stamina": 15.0,
		"restore_hunger": 18.0
	},
	"cooked_egg": {
		"name": "Huevo Cocido",
		"category": "Alimento",
		"desc": "Huevo caliente hecho en la cacerola (+24 HP, +35 STM, +38 Hambre).",
		"usable": true,
		"heal_hp": 24.0,
		"restore_stamina": 35.0,
		"restore_hunger": 38.0
	},
	"country_stew": {
		"name": "Estofado Campesino",
		"category": "Alimento",
		"desc": "Guiso caliente de carne, col y zanahoria (+55 HP, +75 STM, +80 Hambre).",
		"usable": true,
		"heal_hp": 55.0,
		"restore_stamina": 75.0,
		"restore_hunger": 80.0
	},
	"bandage": {
		"name": "Vendaje Limpio",
		"category": "Curación",
		"desc": "Corta cualquier hemorragia al instante y restaura +20 HP.",
		"usable": true,
		"heal_hp": 20.0,
		"stop_bleed": true
	},
	"herbal_poultice": {
		"name": "Cataplasma Curativa",
		"category": "Curación",
		"desc": "Ungüento concentrado de hierbas y hongos. Corta el sangrado y cura +40 HP.",
		"usable": true,
		"heal_hp": 40.0,
		"stop_bleed": true
	},
	"bread": {
		"name": "Hogaza de Pan",
		"category": "Alimento",
		"desc": "Pan horneado (+20 HP, +35 STM, +40 Hambre).",
		"usable": true,
		"heal_hp": 20.0,
		"restore_stamina": 35.0,
		"restore_hunger": 40.0
	},
	"roasted_mushroom": {
		"name": "Hongos Asados",
		"category": "Alimento",
		"desc": "Brocheta caliente hecha al fuego (+30 HP, +45 STM, +35 Hambre).",
		"usable": true,
		"heal_hp": 30.0,
		"restore_stamina": 45.0,
		"restore_hunger": 35.0
	},
	"raw_meat": {
		"name": "Carne Cruda",
		"category": "Caza",
		"desc": "Carne fresca obtenida cazando fauna del bosque. Cocínala con madera.",
		"usable": false
	},
	"leather": {
		"name": "Cuero Animal",
		"category": "Despiece",
		"desc": "Piel obtenida al desollar animales. Base para confeccionar ropa, armaduras y mochilas.",
		"usable": false
	},
	"fox_pelt": {
		"name": "Piel de Zorro",
		"category": "Despiece",
		"desc": "Pelaje tupido y valioso de depredador del bosque. Muy cotizado para abrigos y comercio.",
		"usable": false
	},
	"bones": {
		"name": "Huesos",
		"category": "Despiece",
		"desc": "Huesos limpios obtenidos del despiece. Sirven para tallar agujas, mangos o hacer caldo.",
		"usable": false
	},
	"antlers": {
		"name": "Astas y Cuernos",
		"category": "Despiece",
		"desc": "Cornamenta firme ideal para tallado artesanal, empuñaduras o venta a buen precio.",
		"usable": false
	},
	"sinew_viscera": {
		"name": "Vísceras y Tendones",
		"category": "Despiece",
		"desc": "Tripas y fibras resistentes para fabricar cuerdas de arco, suturas o pociones/cebos.",
		"usable": false
	},
	"animal_fat": {
		"name": "Grasa Animal",
		"category": "Despiece",
		"desc": "Sebo útil para fabricar antorchas, velas, ungüentos o impermeabilizar cuero.",
		"usable": false
	},
	"cooked_meat": {
		"name": "Carne Cocida",
		"category": "Alimento",
		"desc": "Carne cocinada en la cacerola de la hoguera (+40 HP, +60 STM, +55 Hambre).",
		"usable": true,
		"heal_hp": 40.0,
		"restore_stamina": 60.0,
		"restore_hunger": 55.0
	},
	"repair_kit": {
		"name": "Tablones Reforzados",
		"category": "Construcción",
		"desc": "Material elaborado con madera y piedra para construir tu casa o vender en el pueblo.",
		"usable": false
	}
}

const RECIPES: Array[Dictionary] = [
	{
		"id": "craft_bandage",
		"result": "bandage",
		"amount": 1,
		"ingredients": {"herbs": 2},
		"desc": "Teje fibras medicinales para detener sangrados (+20 HP)."
	},
	{
		"id": "craft_poultice",
		"result": "herbal_poultice",
		"amount": 1,
		"ingredients": {"herbs": 2, "mushroom": 1},
		"desc": "Mezcla potente que corta hemorragias y cura +40 HP."
	},
	{
		"id": "craft_roasted_mushroom",
		"result": "roasted_mushroom",
		"amount": 1,
		"ingredients": {"mushroom": 2, "wood": 1},
		"desc": "Asa hongos silvestres con leña (+30 HP, +45 STM)."
	},
	{
		"id": "craft_cooked_meat",
		"result": "cooked_meat",
		"amount": 1,
		"ingredients": {"raw_meat": 1, "wood": 1},
		"desc": "Asa carne cruda al fuego (+40 HP, +60 STM)."
	},
	{
		"id": "craft_planks",
		"result": "repair_kit",
		"amount": 1,
		"ingredients": {"wood": 3, "stone": 1},
		"desc": "Prepara tablones para construcción o comercio en la aldea."
	},
	{
		"id": "craft_leather_bandage",
		"result": "herbal_poultice",
		"amount": 2,
		"ingredients": {"leather": 1, "herbs": 2},
		"desc": "Usa cuero limpio y hierbas para armar 2 Cataplasmas Curativas (+40 HP)."
	},
	{
		"id": "craft_fertilizer",
		"result": "fertilizer",
		"amount": 2,
		"ingredients": {"mushroom": 1, "herbs": 1},
		"desc": "Composta hongos y hierbas para producir 2 bolsas de Abono Orgánico."
	},
	{
		"id": "craft_bake_bread",
		"result": "bread",
		"amount": 2,
		"ingredients": {"wheat": 2, "wood": 1},
		"desc": "Hornea 2 Hogazas de Pan usando trigo cosechado y leña (+20 HP, +35 STM)."
	},
	{
		"id": "craft_country_stew",
		"result": "country_stew",
		"amount": 1,
		"ingredients": {"raw_meat": 1, "cabbage": 1, "carrot": 1},
		"desc": "Cocina un Estofado Campesino con carne, col y zanahoria (+55 HP, +75 STM)."
	}
]

const SEED_ORDER: Array[String] = ["carrot_seeds", "cabbage_seeds", "wheat_seeds"]

var gold: int = 25
var items: Dictionary = {} # item_id (String) -> count (int)
var selected_seed_id: String = "carrot_seeds"

func _ready() -> void:
	add_item("bandage", 2)
	add_item("bread", 1)
	add_item("carrot_seeds", 3)
	add_item("cabbage_seeds", 3)
	add_item("wheat_seeds", 3)
	add_item("fertilizer", 2)

func cycle_selected_seed() -> String:
	var idx := SEED_ORDER.find(selected_seed_id)
	idx = (idx + 1) % SEED_ORDER.size()
	selected_seed_id = SEED_ORDER[idx]
	return selected_seed_id

func get_item_info(item_id: String) -> Dictionary:
	if CATALOG.has(item_id):
		return CATALOG[item_id]
	return {
		"name": item_id.capitalize(),
		"category": "Objeto",
		"desc": "Recurso del mundo.",
		"usable": false
	}

func get_item_name(item_id: String) -> String:
	return get_item_info(item_id).get("name", item_id.capitalize())

func add_gold(amount: int) -> void:
	gold = max(0, gold + amount)
	gold_changed.emit(gold)
	inventory_changed.emit()

func add_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	var current: int = int(items.get(item_id, 0))
	var updated: int = current + amount
	items[item_id] = updated
	item_added.emit(item_id, amount, updated)
	inventory_changed.emit()

func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	var current: int = int(items.get(item_id, 0))
	if current < amount:
		return false
	var updated: int = current - amount
	if updated <= 0:
		items.erase(item_id)
		updated = 0
	else:
		items[item_id] = updated
	item_removed.emit(item_id, amount, updated)
	inventory_changed.emit()
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	return int(items.get(item_id, 0)) >= amount

func get_count(item_id: String) -> int:
	return int(items.get(item_id, 0))

func use_item(item_id: String, player: Node) -> bool:
	if not has_item(item_id, 1) or not player:
		return false
	var info := get_item_info(item_id)
	if not info.get("usable", false):
		return false

	# Si es un paquete de semillas, lo selecciona como semilla activa para sembrar con [E]
	if info.get("is_seed", false):
		selected_seed_id = item_id
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🌱 Semilla activa: %s" % get_item_name(item_id), Color.SPRING_GREEN, -42.0)
		return true

	var used := false
	var health_comp: HealthComponent = player.get_node_or_null("HealthComponent")
	var stamina_comp: StaminaComponent = player.get_node_or_null("StaminaComponent")
	var survival_comp: SurvivalComponent = player.get_node_or_null("SurvivalComponent")

	if info.get("stop_bleed", false) and health_comp:
		health_comp.stop_bleeding()
		used = true

	var heal_hp: float = float(info.get("heal_hp", 0.0))
	if heal_hp > 0.0 and health_comp:
		health_comp.heal(heal_hp)
		used = true

	var restore_stam: float = float(info.get("restore_stamina", 0.0))
	if restore_stam > 0.0 and stamina_comp:
		stamina_comp.current_stamina = min(stamina_comp.max_stamina, stamina_comp.current_stamina + restore_stam)
		stamina_comp.stamina_changed.emit(stamina_comp.current_stamina, stamina_comp.max_stamina)
		used = true

	var restore_hun: float = float(info.get("restore_hunger", 0.0))
	if restore_hun > 0.0 and survival_comp:
		survival_comp.restore_hunger(restore_hun)
		used = true

	if used:
		remove_item(item_id, 1)
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("Usado: %s" % get_item_name(item_id), Color.LIGHT_GREEN, -42.0)
	return used

# --- Sistema de Crafteo ---

func can_craft(recipe: Dictionary) -> bool:
	var ing: Dictionary = recipe.get("ingredients", {})
	for item_id in ing.keys():
		var req: int = int(ing[item_id])
		if get_count(str(item_id)) < req:
			return false
	return true

func craft_recipe(recipe: Dictionary, player: Node = null) -> bool:
	if not can_craft(recipe):
		return false
	var ing: Dictionary = recipe.get("ingredients", {})
	for item_id in ing.keys():
		remove_item(str(item_id), int(ing[item_id]))

	var result_id: String = str(recipe.get("result", ""))
	var amount: int = int(recipe.get("amount", 1))
	add_item(result_id, amount)
	recipe_crafted.emit(str(recipe.get("id", "")), result_id)

	if player and player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🔨 Fabricado: +%d %s" % [amount, get_item_name(result_id)], Color.CYAN, -44.0)
	return true

func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"items": items.duplicate()
	}

func from_dict(data: Dictionary) -> void:
	gold = int(data.get("gold", 25))
	items.clear()
	var saved_items: Dictionary = data.get("items", {})
	for k in saved_items.keys():
		var count := int(saved_items[k])
		if count > 0:
			items[str(k)] = count
	gold_changed.emit(gold)
	inventory_changed.emit()
