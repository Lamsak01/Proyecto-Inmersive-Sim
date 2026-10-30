extends Node
class_name SimpleInventory

## Sistema de Inventario Visual, Crafteo y Equipamiento de Armadura (4 Slots) — Fase 2.2 / Fase 4 / Fase 5
## - Incluye iconos pixel-art 16x16 (`get_item_icon`) para todos los recursos, peces, cosechas, carnes y armaduras.
## - Gestiona las 4 ranuras de armadura (`HEAD`, `CHEST`, `LEGS`, `BOOTS`) en 3 Tiers (Cuero, Hierro, Acero).
## - Gestiona el Taller de Crafteo y la serialización JSON completa.

signal inventory_changed()
signal item_added(item_id: String, amount: int, new_total: int)
signal item_removed(item_id: String, amount: int, new_total: int)
signal gold_changed(new_gold: int)
signal recipe_crafted(recipe_id: String, result_item: String)
signal armor_changed()

const ARMOR_SLOTS: Array[String] = ["HEAD", "CHEST", "LEGS", "BOOTS"]
const ARMOR_SLOT_NAMES: Dictionary = {
	"HEAD": "Casco",
	"CHEST": "Pecho",
	"LEGS": "Piernas",
	"BOOTS": "Botas"
}

const CATALOG: Dictionary = {
	"wood": {
		"name": "Madera",
		"category": "Material",
		"desc": "Troncos obtenidos talando árboles ([3] Hacha). Útil para leña, mejoras y construcción.",
		"usable": false
	},
	"stone": {
		"name": "Piedra",
		"category": "Material",
		"desc": "Roca firme extraída con herramientas de minería ([4] Pico).",
		"usable": false
	},
	"iron_ore": {
		"name": "Mineral de Hierro",
		"category": "Material",
		"desc": "Mineral bruto extraído de vetas rocosas. Esencial en la Herrería para forjar y mejorar herramientas.",
		"usable": false
	},
	"steel_ingot": {
		"name": "Lingote de Acero",
		"category": "Material",
		"desc": "Aleación refinada de hierro y carbón de leña. Permite forjar equipo y herramientas de Tier 3.",
		"usable": false
	},
	"herbs": {
		"name": "Hierbas Medicinales",
		"category": "Forrajeo",
		"desc": "Plantas silvestres coagulantes. Úsalas directo (+10 HP, corta sangrado) o craftea vendajes.",
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
		"desc": "Semillas silvestres del bosque. Puedes usarlas o intercambiarlas en la Herboristería.",
		"usable": false
	},
	"carrot_seeds": {
		"name": "Semillas de Zanahoria",
		"category": "Agricultura",
		"desc": "Ciclo rápido (2 días, o 1 día con abono). Pulsa [E] en tierra vacía para plantar o [R] para alternar.",
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
	"raw_chicken": {
		"name": "Pollo Crudo",
		"category": "Ganadería",
		"desc": "Ave desplumada del gallinero. Puedes comerla en emergencia (+12 HP, +22 Hambre) o asarla al fuego.",
		"usable": true,
		"heal_hp": 12.0,
		"restore_stamina": 15.0,
		"restore_hunger": 22.0
	},
	"roasted_chicken": {
		"name": "Pollo Asado",
		"category": "Alimento",
		"desc": "Pollo dorado y jugoso hecho al fuego (+48 HP, +65 STM, +68 Hambre).",
		"usable": true,
		"heal_hp": 48.0,
		"restore_stamina": 65.0,
		"restore_hunger": 68.0
	},
	"feather": {
		"name": "Plumas de Ave",
		"category": "Ganadería",
		"desc": "Plumas suaves obtenidas de las gallinas. Útiles para emplumar flechas o vender en el pueblo.",
		"usable": false
	},
	"frog_legs": {
		"name": "Ancas de Rana Crudas",
		"category": "Caza (Ciénaga)",
		"desc": "Ancas frescas obtenidas al cazar ranas en la Ciénaga de la Llanura del Oeste. Cocínalas en la hoguera.",
		"usable": false,
		"icon": "res://assests/items/icons/frog_legs.png"
	},
	"fried_frog_legs": {
		"name": "Ancas de Rana al Ajillo",
		"category": "Alimento",
		"desc": "Plato gourmet crujiente de la Ciénaga (+50 HP, +70 STM, +65 Hambre).",
		"usable": true,
		"heal_hp": 50.0,
		"restore_stamina": 70.0,
		"restore_hunger": 65.0,
		"icon": "res://assests/items/icons/fried_frog_legs.png"
	},
	"bandit_scrap": {
		"name": "Reliquia y Chatarra de Bandido",
		"category": "Botín (Llanura)",
		"desc": "Metal antiguo y monedas del campamento hostil del Oeste. Muy cotizado en la Herrería o para fundir acero.",
		"usable": false,
		"icon": "res://assests/items/icons/bandit_scrap.png"
	},
	"river_trout": {
		"name": "Trucha de Río",
		"category": "Pesca",
		"desc": "Pez de aguas frescas capturado de día. Cocínalo en la cacerola o véndelo en la Pescadería.",
		"usable": false
	},
	"golden_carp": {
		"name": "Carpa Dorada",
		"category": "Pesca",
		"desc": "Pez brillante y cotizado del lago. Cocínalo o véndelo a buen precio.",
		"usable": false
	},
	"night_catfish": {
		"name": "Siluro Nocturno",
		"category": "Pesca",
		"desc": "Gran pez de fondo que solo pica al atardecer y de noche. Muy valioso.",
		"usable": false
	},
	"cooked_fish": {
		"name": "Pescado Cocido",
		"category": "Alimento",
		"desc": "Filete de pescado recién hecho en la cacerola (+36 HP, +55 STM, +52 Hambre).",
		"usable": true,
		"heal_hp": 36.0,
		"restore_stamina": 55.0,
		"restore_hunger": 52.0
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
		"desc": "Carne fresca obtenida cazando fauna del bosque o dando de comer a mascotas. Cocínala al fuego.",
		"usable": false
	},
	"leather": {
		"name": "Cuero Animal",
		"category": "Despiece",
		"desc": "Piel obtenida al desollar animales. Base para confeccionar armaduras y empuñaduras.",
		"usable": false
	},
	"fox_pelt": {
		"name": "Piel de Zorro",
		"category": "Despiece",
		"desc": "Pelaje tupido y valioso de depredador del bosque. Muy cotizado en la Carnicería y Herrería.",
		"usable": false
	},
	"bones": {
		"name": "Huesos",
		"category": "Despiece",
		"desc": "Huesos limpios obtenidos del despiece. Sirven para tallar mangos o hacer abono.",
		"usable": false
	},
	"antlers": {
		"name": "Astas y Cuernos",
		"category": "Despiece",
		"desc": "Cornamenta firme ideal para empuñaduras de armas o venta a buen precio.",
		"usable": false
	},
	"sinew_viscera": {
		"name": "Vísceras y Tendones",
		"category": "Despiece",
		"desc": "Fibras resistentes para fabricar cuerdas de arco y costuras de armadura.",
		"usable": false
	},
	"animal_fat": {
		"name": "Grasa Animal",
		"category": "Despiece",
		"desc": "Sebo útil para templar acero, ungüentos o impermeabilizar cuero.",
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
		"desc": "Material elaborado con madera y piedra para construir o comerciar en el pueblo.",
		"usable": false
	},
	"sleeping_draught": {
		"name": "Somnífero Nocturno",
		"category": "Alquimia / Sigilo",
		"desc": "Elixir sedante de la Botica. Úsalo cerca de un NPC o guardia para dormirlo profundamente 40s sin matarlo ni dejar rastro forense.",
		"usable": true,
		"is_sleeping_draught": true,
		"icon": "res://assests/items/icons/sleeping_draught.png"
	},
	"speed_tonic": {
		"name": "Tónico de Velocidad",
		"category": "Alquimia",
		"desc": "Destilado energético (+65 STM y +25% Velocidad de movimiento durante 35 segundos).",
		"usable": true,
		"restore_stamina": 65.0,
		"speed_buff_duration": 35.0,
		"icon": "res://assests/items/icons/speed_tonic.png"
	},
	"surgical_kit": {
		"name": "Botiquín Quirúrgico",
		"category": "Medicina Hospitalaria",
		"desc": "Instrumental del Dr. Valen. Corta hemorragias, cura +85 HP o reanima al instante a un aldeano agonizando.",
		"usable": true,
		"heal_hp": 85.0,
		"stop_bleed": true,
		"icon": "res://assests/items/icons/surgical_kit.png"
	},
	"golden_egg": {
		"name": "Huevo Dorado (Genética Nv.3)",
		"category": "Ganadería Selecta",
		"desc": "Huevo extraordinario puesto por gallinas de Genética Nv.3 (+75 HP, +90 STM, +85 Hambre o véndelo por 35 Oro).",
		"usable": true,
		"heal_hp": 75.0,
		"restore_stamina": 90.0,
		"restore_hunger": 85.0,
		"icon": "res://assests/items/icons/golden_egg.png"
	},
	"copper_coil": {
		"name": "Bobina de Cobre Antiguo",
		"category": "Tecnología / Ingeniería",
		"desc": "Conductor electromagnético para construir o mejorar el Generador Antiguo y el Aspersor Automático.",
		"usable": false,
		"icon": "res://assests/items/icons/copper_coil.png"
	},
	"royal_safe_conduct": {
		"name": "Salvoconducto Real Sellado",
		"category": "Documento de la Corona",
		"desc": "Cédula oficial con sello de lacre del Reino que autoriza a cruzar las fronteras del valle. ¡Cuidado: si un Investigador Real te lo encuentra encima tras la muerte de un mercader, será prueba irrefutable!",
		"usable": false
	},
	"royal_ration": {
		"name": "Conserva Real de Extramuros",
		"category": "Importación Exótica",
		"desc": "Ración militar especiada traída de la capital por mercaderes con salvoconducto (+60 HP, +80 STM, +90 Hambre).",
		"usable": true,
		"heal_hp": 60.0,
		"restore_stamina": 80.0,
		"restore_hunger": 90.0
	},
	"master_lockpick": {
		"name": "Ganzúa Maestra de Relojero",
		"category": "Herramienta Real (Casimir)",
		"desc": "Instrumental de precisión de las Tierras Reales. Mientras la lleves en el inventario, reduces un 65% el radio de detección de testigos al forzar puertas ([F]) o cofres privados ([E]).",
		"usable": true,
		"is_passive_tool": true,
		"icon": "res://assests/items/icons/master_lockpick.png"
	},
	"steel_bear_trap": {
		"name": "Cepo de Acero de Frontera",
		"category": "Trampa Táctica (Casimir)",
		"desc": "Trampa mecánica dentada de las Tierras Reales. Úsala en el inventario para desplegarla en el suelo: atrapa al primer animal salvaje o enemigo hostil que la pise (35 Daño, Sangrado y 100 Stun).",
		"usable": true,
		"is_bear_trap": true,
		"icon": "res://assests/items/icons/steel_bear_trap.png"
	},
	"ranger_camo_cloak": {
		"name": "Manto de Camuflaje Montaraz",
		"category": "Equipo de Sigilo (Valeria)",
		"desc": "Capa mimética de las Tierras Reales. Mientras la lleves en el inventario, reduce un 40% la distancia a la que te detectan guardias, animales salvajes y el Investigador Real.",
		"usable": true,
		"is_passive_tool": true,
		"icon": "res://assests/items/icons/ranger_camo_cloak.png"
	},
	"royal_paralytic_venom": {
		"name": "Veneno Paralizante de Extramuros",
		"category": "Alquimia Exótica (Valeria)",
		"desc": "Destilado neurotóxico de las Tierras Reales. Impregna tu arma o flechas durante 60s: cada impacto aplica +50 de Stun/Parálisis adicional.",
		"usable": true,
		"venom_buff_duration": 60.0,
		"icon": "res://assests/items/icons/royal_paralytic_venom.png"
	},

	# --- ARMADURAS TIER 1: CUERO CURTIDO ---
	"helm_leather": {
		"name": "Capucha de Cuero",
		"category": "Armadura (Casco)",
		"desc": "Tier 1 [Casco]: +6% Defensa física, +15% Resistencia a Stun/KO y +10% Resistencia a Sangrado.",
		"usable": true,
		"armor_slot": "HEAD",
		"armor_tier": 1,
		"defense": 0.06,
		"bleed_res": 0.10,
		"stun_res": 0.15,
		"speed_bonus": 0.0,
		"icon": "res://assests/items/armor/helm_leather.png"
	},
	"chest_leather": {
		"name": "Peto de Cuero Curtido",
		"category": "Armadura (Pecho)",
		"desc": "Tier 1 [Pecho]: +12% Defensa física y +20% Resistencia a Sangrado.",
		"usable": true,
		"armor_slot": "CHEST",
		"armor_tier": 1,
		"defense": 0.12,
		"bleed_res": 0.20,
		"stun_res": 0.05,
		"speed_bonus": 0.0,
		"icon": "res://assests/items/armor/chest_leather.png"
	},
	"legs_leather": {
		"name": "Grebas de Cuero",
		"category": "Armadura (Piernas)",
		"desc": "Tier 1 [Piernas]: +8% Defensa física y +15% Resistencia a Sangrado.",
		"usable": true,
		"armor_slot": "LEGS",
		"armor_tier": 1,
		"defense": 0.08,
		"bleed_res": 0.15,
		"stun_res": 0.05,
		"speed_bonus": 0.0,
		"icon": "res://assests/items/armor/legs_leather.png"
	},
	"boots_leather": {
		"name": "Botas de Explorador",
		"category": "Armadura (Botas)",
		"desc": "Tier 1 [Botas]: +5% Defensa física y +8% Velocidad de movimiento.",
		"usable": true,
		"armor_slot": "BOOTS",
		"armor_tier": 1,
		"defense": 0.05,
		"bleed_res": 0.08,
		"stun_res": 0.05,
		"speed_bonus": 0.08,
		"icon": "res://assests/items/armor/boots_leather.png"
	},

	# --- ARMADURAS TIER 2: HIERRO FORJADO ---
	"helm_iron": {
		"name": "Yelmo de Hierro",
		"category": "Armadura (Casco)",
		"desc": "Tier 2 [Casco]: +11% Defensa física y +28% Resistencia a Stun/KO.",
		"usable": true,
		"armor_slot": "HEAD",
		"armor_tier": 2,
		"defense": 0.11,
		"bleed_res": 0.15,
		"stun_res": 0.28,
		"speed_bonus": 0.0,
		"icon": "res://assests/items/armor/helm_iron.png"
	},
	"chest_iron": {
		"name": "Coraza de Hierro",
		"category": "Armadura (Pecho)",
		"desc": "Tier 2 [Pecho]: +20% Defensa física y +30% Resistencia a Sangrado.",
		"usable": true,
		"armor_slot": "CHEST",
		"armor_tier": 2,
		"defense": 0.20,
		"bleed_res": 0.30,
		"stun_res": 0.12,
		"speed_bonus": 0.0,
		"icon": "res://assests/items/armor/chest_iron.png"
	},
	"legs_iron": {
		"name": "Quijotes de Hierro",
		"category": "Armadura (Piernas)",
		"desc": "Tier 2 [Piernas]: +14% Defensa física y +20% Resistencia a Sangrado.",
		"usable": true,
		"armor_slot": "LEGS",
		"armor_tier": 2,
		"defense": 0.14,
		"bleed_res": 0.20,
		"stun_res": 0.10,
		"speed_bonus": 0.0,
		"icon": "res://assests/items/armor/legs_iron.png"
	},
	"boots_iron": {
		"name": "Botas Herradas",
		"category": "Armadura (Botas)",
		"desc": "Tier 2 [Botas]: +9% Defensa física, +12% Resistencia a Stun y +5% Velocidad.",
		"usable": true,
		"armor_slot": "BOOTS",
		"armor_tier": 2,
		"defense": 0.09,
		"bleed_res": 0.12,
		"stun_res": 0.12,
		"speed_bonus": 0.05,
		"icon": "res://assests/items/armor/boots_iron.png"
	},

	# --- ARMADURAS TIER 3: ACERO TEMPLADO ---
	"helm_steel": {
		"name": "Gran Yelmo de Acero",
		"category": "Armadura (Casco)",
		"desc": "Tier 3 [Casco]: +16% Defensa física y +42% Resistencia a Stun/KO.",
		"usable": true,
		"armor_slot": "HEAD",
		"armor_tier": 3,
		"defense": 0.16,
		"bleed_res": 0.22,
		"stun_res": 0.42,
		"speed_bonus": 0.0,
		"icon": "res://assests/items/armor/helm_steel.png"
	},
	"chest_steel": {
		"name": "Armadura de Placas de Acero",
		"category": "Armadura (Pecho)",
		"desc": "Tier 3 [Pecho]: +28% Defensa física y +42% Resistencia a Sangrado.",
		"usable": true,
		"armor_slot": "CHEST",
		"armor_tier": 3,
		"defense": 0.28,
		"bleed_res": 0.42,
		"stun_res": 0.20,
		"speed_bonus": 0.0,
		"icon": "res://assests/items/armor/chest_steel.png"
	},
	"legs_steel": {
		"name": "Grebas de Acero Templado",
		"category": "Armadura (Piernas)",
		"desc": "Tier 3 [Piernas]: +19% Defensa física y +28% Resistencia a Sangrado.",
		"usable": true,
		"armor_slot": "LEGS",
		"armor_tier": 3,
		"defense": 0.19,
		"bleed_res": 0.28,
		"stun_res": 0.15,
		"speed_bonus": 0.0,
		"icon": "res://assests/items/armor/legs_steel.png"
	},
	"boots_steel": {
		"name": "Escarpes de Acero Real",
		"category": "Armadura (Botas)",
		"desc": "Tier 3 [Botas]: +12% Defensa física, +15% Resistencia a Sangrado y +10% Velocidad.",
		"usable": true,
		"armor_slot": "BOOTS",
		"armor_tier": 3,
		"defense": 0.12,
		"bleed_res": 0.15,
		"stun_res": 0.15,
		"speed_bonus": 0.10,
		"icon": "res://assests/items/armor/boots_steel.png"
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
		"id": "craft_roasted_chicken",
		"result": "roasted_chicken",
		"amount": 1,
		"ingredients": {"raw_chicken": 1, "wood": 1},
		"desc": "Asa un pollo entero al fuego (+48 HP, +65 STM, +68 Hambre)."
	},
	{
		"id": "craft_fried_frog_legs",
		"result": "fried_frog_legs",
		"amount": 1,
		"ingredients": {"frog_legs": 2, "herbs": 1},
		"desc": "Saltea ancas de rana de la Ciénaga con hierbas (+50 HP, +70 STM, +65 Hambre)."
	},
	{
		"id": "craft_steel_from_scrap",
		"result": "steel_ingot",
		"amount": 1,
		"ingredients": {"bandit_scrap": 1, "wood": 1},
		"desc": "Recicla chatarra de bandido con fuego para fundir 1 Lingote de Acero."
	},
	{
		"id": "craft_planks",
		"result": "repair_kit",
		"amount": 1,
		"ingredients": {"wood": 3, "stone": 1},
		"desc": "Prepara tablones reforzados para construcción, mejoras o comercio."
	},
	{
		"id": "craft_steel_ingot",
		"result": "steel_ingot",
		"amount": 1,
		"ingredients": {"iron_ore": 2, "wood": 2},
		"desc": "Funde mineral de hierro con carbón de leña para crear 1 Lingote de Acero."
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
	},
	{
		"id": "craft_helm_leather",
		"result": "helm_leather",
		"amount": 1,
		"ingredients": {"leather": 2},
		"desc": "Confecciona una Capucha de Cuero (Tier 1 Casco)."
	},
	{
		"id": "craft_chest_leather",
		"result": "chest_leather",
		"amount": 1,
		"ingredients": {"leather": 3, "wood": 1},
		"desc": "Confecciona un Peto de Cuero Curtido (Tier 1 Pecho)."
	},
	{
		"id": "craft_legs_leather",
		"result": "legs_leather",
		"amount": 1,
		"ingredients": {"leather": 2},
		"desc": "Confecciona unas Grebas de Cuero (Tier 1 Piernas)."
	},
	{
		"id": "craft_boots_leather",
		"result": "boots_leather",
		"amount": 1,
		"ingredients": {"leather": 2},
		"desc": "Confecciona unas Botas de Explorador (+8% Velocidad)."
	},
	{
		"id": "craft_sleeping_draught",
		"result": "sleeping_draught",
		"amount": 1,
		"ingredients": {"herbs": 2, "mushroom": 1, "sinew_viscera": 1},
		"desc": "Destila un Somnífero Nocturno para dormir guardias o aldeanos 40s sin herirlos."
	},
	{
		"id": "craft_speed_tonic",
		"result": "speed_tonic",
		"amount": 1,
		"ingredients": {"herbs": 1, "animal_fat": 1, "carrot": 1},
		"desc": "Destila un Tónico de Velocidad (+65 STM y +25% Velocidad por 35s)."
	},
	{
		"id": "craft_surgical_kit",
		"result": "surgical_kit",
		"amount": 1,
		"ingredients": {"bandage": 1, "herbs": 2, "sinew_viscera": 1},
		"desc": "Prepara un Botiquín Quirúrgico (+85 HP, corta sangrado y reanima heridos)."
	},
	{
		"id": "craft_bone_fertilizer",
		"result": "fertilizer",
		"amount": 3,
		"ingredients": {"bones": 2, "animal_fat": 1},
		"desc": "Muele huesos y grasa animal del despiece para crear 3 bolsas de Abono Orgánico."
	},
	{
		"id": "craft_copper_coil",
		"result": "copper_coil",
		"amount": 1,
		"ingredients": {"iron_ore": 1, "bandit_scrap": 1},
		"desc": "Bobina conductora antigua para el Generador Eléctrico y el Aspersor."
	}
]

const SEED_ORDER: Array[String] = ["carrot_seeds", "cabbage_seeds", "wheat_seeds"]

var gold: int = 45
var items: Dictionary = {} # item_id (String) -> count (int)
var selected_seed_id: String = "carrot_seeds"
var equipped_armor: Dictionary = {
	"HEAD": "",
	"CHEST": "",
	"LEGS": "",
	"BOOTS": ""
}
var _icon_cache: Dictionary = {}

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
	if item_id == "":
		return "Vacío"
	return str(get_item_info(item_id).get("name", item_id.capitalize()))

func get_item_icon(item_id: String) -> Texture2D:
	if item_id == "":
		return null
	if _icon_cache.has(item_id):
		return _icon_cache[item_id]
	var info: Dictionary = get_item_info(item_id)
	var candidate_paths: Array[String] = []
	if info.has("icon"):
		candidate_paths.append(str(info["icon"]))
	candidate_paths.append("res://assests/items/icons/%s.png" % item_id)
	candidate_paths.append("res://assests/items/armor/%s.png" % item_id)

	for res_path in candidate_paths:
		if ResourceLoader.exists(res_path):
			var tex = load(res_path)
			if tex is Texture2D:
				_icon_cache[item_id] = tex
				return tex
		var abs_path := ProjectSettings.globalize_path(res_path)
		if FileAccess.file_exists(abs_path):
			var img := Image.load_from_file(abs_path)
			if img and not img.is_empty():
				var itex := ImageTexture.create_from_image(img)
				_icon_cache[item_id] = itex
				return itex
	return null

func is_armor_item(item_id: String) -> bool:
	return get_item_info(item_id).has("armor_slot")

func equip_armor_item(item_id: String, player: Node = null) -> bool:
	if not has_item(item_id, 1) or not is_armor_item(item_id):
		return false
	var info: Dictionary = get_item_info(item_id)
	var slot: String = str(info.get("armor_slot", ""))
	if slot == "" or not equipped_armor.has(slot):
		return false

	var prev_item: String = str(equipped_armor.get(slot, ""))
	remove_item(item_id, 1)
	if prev_item != "":
		add_item(prev_item, 1)
	equipped_armor[slot] = item_id
	armor_changed.emit()
	inventory_changed.emit()
	if player:
		if player.has_method("apply_armor_stats"):
			player.call("apply_armor_stats")
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🛡️ Equipado: %s" % get_item_name(item_id), Color.SKY_BLUE, -42.0)
	return true

func unequip_armor_slot(slot: String, player: Node = null) -> bool:
	if not equipped_armor.has(slot):
		return false
	var cur_id: String = str(equipped_armor.get(slot, ""))
	if cur_id == "":
		return false
	equipped_armor[slot] = ""
	add_item(cur_id, 1)
	armor_changed.emit()
	inventory_changed.emit()
	if player:
		if player.has_method("apply_armor_stats"):
			player.call("apply_armor_stats")
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("Desequipado: %s" % get_item_name(cur_id), Color.LIGHT_GRAY, -40.0)
	return true

func get_total_armor_stats() -> Dictionary:
	var total_def: float = 0.0
	var total_bleed: float = 0.0
	var total_stun: float = 0.0
	var total_spd: float = 0.0
	var highest_tier: int = 0

	for slot in ARMOR_SLOTS:
		var item_id: String = str(equipped_armor.get(slot, ""))
		if item_id != "" and CATALOG.has(item_id):
			var info: Dictionary = CATALOG[item_id]
			total_def += float(info.get("defense", 0.0))
			total_bleed += float(info.get("bleed_res", 0.0))
			total_stun += float(info.get("stun_res", 0.0))
			total_spd += float(info.get("speed_bonus", 0.0))
			highest_tier = maxi(highest_tier, int(info.get("armor_tier", 1)))

	return {
		"defense": clampf(total_def, 0.0, 0.78),
		"bleed_res": clampf(total_bleed, 0.0, 0.88),
		"stun_res": clampf(total_stun, 0.0, 0.85),
		"speed_bonus": clampf(total_spd, 0.0, 0.25),
		"highest_tier": highest_tier
	}

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

	# Si es una pieza de armadura, equiparla en su slot correspondiente
	if info.has("armor_slot"):
		return equip_armor_item(item_id, player)

	# Si es un paquete de semillas, lo selecciona como semilla activa para sembrar con [E]
	if info.get("is_seed", false):
		selected_seed_id = item_id
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🌱 Semilla activa: %s" % get_item_name(item_id), Color.SPRING_GREEN, -42.0)
		return true

	# Herramientas pasivas de Tierras Reales (Ganzúa Maestra / Manto de Camuflaje)
	if info.get("is_passive_tool", false):
		if item_id == "master_lockpick":
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🗝️ Ganzúa Maestra lista (-65% detección al forzar puertas/cofres)", Color.GOLD, -42.0)
			if player.has_method("show_hint"):
				player.call("show_hint", "🗝️ Ganzúa Maestra de Relojero activa pasivamente: tienes -65% riesgo de ser visto al forzar puertas ([F]) o cofres ([E]).")
		elif item_id == "ranger_camo_cloak":
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🧥 Manto Montaraz activo (-40% detección visual y de sigilo)", Color.SPRING_GREEN, -42.0)
			if player.has_method("show_hint"):
				player.call("show_hint", "🧥 Manto de Camuflaje Montaraz activo pasivamente: guardias, animales y el Investigador Real te detectan un 40% menos.")
		return true

	# Desplegar Cepo de Acero de Frontera en el suelo
	if info.get("is_bear_trap", false) and player is Node2D:
		var p_node_trap: Node2D = player as Node2D
		var vm_trap = p_node_trap.get_tree().get_first_node_in_group("village_manager")
		if vm_trap and vm_trap.has_method("deploy_steel_bear_trap"):
			remove_item(item_id, 1)
			vm_trap.call("deploy_steel_bear_trap", p_node_trap.global_position, player)
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🪤 Cepo de Acero desplegado en el suelo", Color(0.95, 0.78, 0.32), -44.0)
			return true

	# Si es un Somnífero Nocturno, aplicarlo al NPC más cercano (<= 52 px) sin causar daño ni alerta
	if info.get("is_sleeping_draught", false) and player is Node2D:
		var p_node: Node2D = player as Node2D
		var best_npc: Node2D = null
		var best_d2: float = 52.0 * 52.0
		for n in p_node.get_tree().get_nodes_in_group("village_npcs"):
			if n is Node2D and not bool(n.get("is_dead")) and not bool(n.get("is_downed")) and not bool(n.get("is_stunned_flag")) and float(n.get("sedated_timer") if n.get("sedated_timer") != null else 0.0) <= 0.0 and not bool(n.get("is_at_poker_table")):
				var d2: float = p_node.global_position.distance_squared_to(n.global_position)
				if d2 <= best_d2:
					best_d2 = d2
					best_npc = n
		if best_npc and best_npc.has_method("apply_sleeping_draught"):
			remove_item(item_id, 1)
			best_npc.call("apply_sleeping_draught", 40.0)
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🧪💤 Somnífero aplicado a %s (Dormido 40s)" % str(best_npc.get("npc_name")), Color(0.75, 0.58, 1.0), -44.0)
			return true
		else:
			if player.has_method("show_hint"):
				player.call("show_hint", "🧪 Acércate a un aldeano o guardia (<= 50 px) para administrarle el Somnífero Nocturno.")
			return false

	# Si es un Botiquín Quirúrgico y hay un NPC agonizando al lado, reanimarlo de inmediato
	if item_id == "surgical_kit" and player is Node2D:
		var p_node2: Node2D = player as Node2D
		for n in p_node2.get_tree().get_nodes_in_group("village_npcs"):
			if n is Node2D and bool(n.get("is_downed")) and not bool(n.get("is_dead")):
				if p_node2.global_position.distance_squared_to(n.global_position) <= 64.0 * 64.0:
					if n.has_method("revive_from_downed"):
						remove_item(item_id, 1)
						n.call("revive_from_downed", player, true)
						return true

	var used := false
	var health_comp: HealthComponent = player.get_node_or_null("HealthComponent")
	var stamina_comp: StaminaComponent = player.get_node_or_null("StaminaComponent")
	var survival_comp: SurvivalComponent = player.get_node_or_null("SurvivalComponent")

	if info.has("speed_buff_duration") and player.has_method("apply_speed_tonic"):
		player.call("apply_speed_tonic", float(info["speed_buff_duration"]))
		used = true

	if info.has("venom_buff_duration") and player.has_method("apply_paralytic_venom"):
		player.call("apply_paralytic_venom", float(info["venom_buff_duration"]))
		used = true

	if info.get("stop_bleed", false) and health_comp:
		if health_comp.is_bleeding or health_comp.current_blood > 0.1:
			health_comp.stop_bleeding()
			used = true

	var heal_hp: float = float(info.get("heal_hp", 0.0))
	if heal_hp > 0.0 and health_comp:
		if health_comp.current_health < health_comp.max_health - 0.1:
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
	elif (heal_hp > 0.0 or bool(info.get("stop_bleed", false))) and player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🏥 Salud al 100% (No necesitas curación)", Color.LIGHT_GRAY, -42.0)
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
		"selected_seed_id": selected_seed_id,
		"items": items.duplicate(),
		"equipped_armor": equipped_armor.duplicate()
	}

func from_dict(data: Dictionary) -> void:
	gold = int(data.get("gold", 45))
	selected_seed_id = str(data.get("selected_seed_id", "wheat_seeds"))
	if selected_seed_id == "wheat_seed":
		selected_seed_id = "wheat_seeds"
	items.clear()
	var saved_items: Dictionary = data.get("items", {})
	for k in saved_items.keys():
		var count := int(saved_items[k])
		if count > 0:
			items[str(k)] = count

	for slot in ARMOR_SLOTS:
		equipped_armor[slot] = ""
	if data.has("equipped_armor") and typeof(data["equipped_armor"]) == TYPE_DICTIONARY:
		var saved_armor: Dictionary = data["equipped_armor"]
		for slot in ARMOR_SLOTS:
			if saved_armor.has(slot):
				equipped_armor[slot] = str(saved_armor[slot])

	gold_changed.emit(gold)
	armor_changed.emit()
	inventory_changed.emit()
