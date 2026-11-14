@tool
extends RefCounted

## V5: oficios nuevos que viven en los solares (panadería y sastrería en V5a; granja, rancho, cantera y leñador en V5d).
## - El edificio está desde el principio, pero el puesto empieza VACANTE: lo ocupa quien quiera y pueda, por las reglas
##   de siempre (un vecino ambicioso, un viajero sin oficio de la posada o, si no, un forastero que llega por el camino).
## - Panadería: pan con harina del molino (pescadería) y leña; vende a casas y posadas como una tienda de comida más.
## - Sastrería: ropa con cuero del carnicero. Los vecinos estrenan ropa cuando les sobra dinero, más los ricos; da buen
##   humor y se nota en cómo los ven los demás.
## - V5d, las afueras: granja (trigo y zanahorias; sus campos ocupan también el solar s2), rancho (lana y carne),
##   cantera (piedra) y leñador (madera). Los oficios de siempre les compran (panadero trigo, sastre lana, carnicero
##   carne, carpintero troncos, herrero piedra) y dan trabajo de jornalero (VillageWork).
## Nombres provisionales (anotados en docs/APORTES_CREATIVOS.md).

const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const Planta = preload("res://mapa/planta.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const TIPO_3D_ROCA := "roca"     ## las rocas de la cantera comparten dibujo con las que se pican: se marcan aparte
const MARGEN_SOLAR: float = 8.0  ## holgura interior al borde del solar y al muro este del edificio

const CONFIG: Dictionary = {
	"baker": {"lot": "n2", "role_name": "BAKER", "family_id": "family_baker", "family_name": "Casa de la Espiga",
		"shop_title": "🍞 Panadería 'La Espiga'", "title": "Panadero", "tex": "res://assests/world/village/villager_innkeeper.png",
		"stock": {"bread": 6}},
	"tailor": {"lot": "n3", "role_name": "TAILOR", "family_id": "family_tailor", "family_name": "Casa del Dedal",
		"shop_title": "🧵 Sastrería 'El Dedal'", "title": "Sastre", "tex": "res://assests/world/village/villager_traveler.png",
		"stock": {"clothes": 2}},
	# `goods`: lo que el jugador compra [objeto, precio] y vende [objeto, precio] en el diálogo genérico (V5d)
	"farmer": {"lot": "s1", "role_name": "FARMER", "family_id": "family_farm", "family_name": "Casa de la Granja",
		"shop_title": "🌾 Granja del Sur", "title": "Granjero", "tex": "res://assests/world/village/villager_herbalist.png",
		"stock": {"wheat": 4, "carrot": 2}, "supply": ["wheat", "carrot", "cabbage"], "extras": "farm", "fields_lot": "s2",
		"goods": {"buy": [["wheat", 6], ["carrot", 5]], "sell": [["fertilizer", 4]]},
		"chat": "La tierra da lo que le das. Con buenos jornaleros, en la siega no falta pan en el valle."},
	"rancher": {"lot": "s3", "role_name": "RANCHER", "family_id": "family_ranch", "family_name": "Casa del Rancho",
		"shop_title": "🐑 Rancho del Sur", "title": "Ganadero", "tex": "res://assests/world/village/villager_butcher.png",
		"stock": {"wool": 2, "raw_meat": 2}, "supply": ["wool", "raw_meat"], "extras": "ranch",
		"goods": {"buy": [["wool", 7], ["raw_meat", 6]], "sell": [["wheat", 5]]},
		"chat": "Los animales no entienden de domingos: hay que darles de comer cada día, llueva o no."},
	"quarry": {"lot": "w1", "role_name": "QUARRYMAN", "family_id": "family_quarry", "family_name": "Casa de la Cantera",
		"shop_title": "⛏️ Cantera del Noroeste", "title": "Cantero", "tex": "res://assests/world/village/villager_smith.png",
		"stock": {"stone": 4}, "supply": ["stone"], "extras": "quarry",
		"goods": {"buy": [["stone", 6]], "sell": [["repair_kit", 10]]},
		"chat": "Cada casa nueva del pueblo sale de esta ladera, piedra a piedra."},
	"woodcutter": {"lot": "fw", "role_name": "WOODCUTTER", "family_id": "family_woodcutter", "family_name": "Casa del Leñador",
		"shop_title": "🪓 Cabaña del Leñador", "title": "Leñador", "tex": "res://assests/world/village/villager_carpenter.png",
		"stock": {"wood": 5}, "supply": ["wood"], "extras": "woods",
		"goods": {"buy": [["wood", 7]], "sell": [["repair_kit", 10]]},
		"chat": "Corto lo justo: si el bosque se queda pelado, se acaba el trabajo y la caza."},
	"tinker": {"lot": "e5", "role_name": "TINKER", "family_id": "family_tinker", "family_name": "Casa del Arreglador",
		"shop_title": "🔧 Taller de Reparaciones", "title": "Arreglador", "tex": "res://assests/world/village/villager_smith.png",
		"stock": {"repair_kit": 2}, "supply": ["repair_kit", "bandit_scrap"],
		"goods": {"buy": [["repair_kit", 14]], "sell": [["bandit_scrap", 16], ["iron_ore", 10]]},
		"chat": "Si te rompen el puesto, ven a verme: lo dejo como nuevo antes de que el gremio lo note. Eso sí, cobro."},
}

## Probabilidad diaria de estrenar ropa según la clase, si le sobra el dinero.
const CLOTHES_CHANCE: Dictionary = {"rico": 0.10, "acomodado": 0.05, "humilde": 0.02}
const CLOTHES_PRICE: int = 22
const CLOTHES_RESERVE: int = 30 # Solo compra si después le quedan al menos estas monedas

static func role_of(key: String) -> int:
	return int(VillageNPC.TradeRole[str(CONFIG[key]["role_name"])])

## Al montar el pueblo (antes de dibujar los solares): da de alta los oficios y marca sus solares como construidos.
static func setup_world(vm) -> void:
	for key in CONFIG.keys():
		var c: Dictionary = CONFIG[key]
		var lay: Dictionary = VillageLots.shop_house_layout_mundo(VillageLots.shop_house_id(str(c["family_id"])))
		vm.trade_configs[role_of(key)] = {
			"family_id": c["family_id"], "family_name": c["family_name"], "shop_title": c["shop_title"],
			"shop_center": VillageLots.lot_def(str(c["lot"]))["center"], "is_mixed_building": true,
			"house_title": c["shop_title"], "house_center": VillageLots.lot_def(str(c["lot"]))["center"],
			"title": c["title"], "tex": vm._load_tex(str(c["tex"])), "stock": (c["stock"] as Dictionary).duplicate(),
			"work_pos": lay["work_pos"], "bed1_pos": lay["bed1_pos"], "bed2_pos": lay["bed2_pos"], "table_pos": lay["table_pos"],
		}
		if str(c.get("extras", "")) in ["quarry", "farm", "ranch"]: # K1: el cantero, granjero y ganadero trabajan (y venden) en la roca, campo o corral, a la vista
			vm.trade_configs[role_of(key)]["work_pos"] = VillageLots.anexo(str(c["lot"]), yard_pos(str(c["lot"]))) # pegado al edificio
		elif str(c.get("extras", "")) == "woods":
			vm.trade_configs[role_of(key)]["work_pos"] = VillageLots.anexo(str(c["lot"]), VillageLots.building_center(str(c["lot"])) + Vector2(82, 14))
		vm.trade_configs[role_of(key)]["shop_center"] = VillageLots.building_center(str(c["lot"]))
		vm.trade_configs[role_of(key)]["house_center"] = VillageLots.building_center(str(c["lot"]))
		if not vm.house_pantry.has(str(c["family_id"])):
			vm.house_pantry[str(c["family_id"])] = 2
	ensure_lots(vm)

## Mitad del ancho real (este-oeste) de la pieza del edificio levantado en ese solar.
static func _mitad_ancho_edificio(id: String) -> float:
	var bc: Vector2 = VillageLots.building_center(id)
	var edificio: String = VillageLots.EdificioEditor.con_centro(bc)
	if edificio.is_empty():
		return VillageLots.house_size(id).x * 0.5
	var tam: Vector2 = Planta.de_edificio(edificio).get("size", Vector2.ZERO)
	var girado: bool = absf(fmod(absf(VillageLots.EdificioEditor.giro(edificio)), 180.0) - 90.0) < 1.0
	return (tam.y if girado else tam.x) * 0.5


## K1: centro de la explanada de roca de la cantera (la franja a la derecha del edificio).
static func yard_pos(id: String) -> Vector2:
	var d: Dictionary = VillageLots.lot_def(id)
	var lc: Vector2 = d["center"]
	var half: Vector2 = (d["size"] as Vector2) * 0.5
	var x0: float = maxf(lc.x - half.x + MARGEN_SOLAR, VillageLots.building_center(id).x + _mitad_ancho_edificio(id) + MARGEN_SOLAR)
	return Vector2((x0 + lc.x + half.x - MARGEN_SOLAR) * 0.5, lc.y)

## K1: partidas de antes: el cantero, granjero, ganadero y leñador trabajan en su roca, campo, corral o pila de troncos.
static func fix_quarry_post(vm) -> void:
	for key in ["quarry", "farmer", "rancher", "woodcutter"]:
		var q = vm.trade_npcs.get(role_of(key))
		if q != null and is_instance_valid(q) and not q.is_dead:
			if key == "woodcutter":
				q.work_position = VillageLots.anexo(str(CONFIG[key]["lot"]), VillageLots.building_center(str(CONFIG[key]["lot"])) + Vector2(82, 14))
			else:
				q.work_position = VillageLots.anexo(str(CONFIG[key]["lot"]), yard_pos(str(CONFIG[key]["lot"])))

## Lo que puede abastecer cada negocio nuevo (lo usa VillageManager al registrar el puesto).
static func supply_items_for(role_id: int) -> Array[String]:
	var out: Array[String] = []
	for key in CONFIG.keys():
		if role_of(key) == role_id:
			out.assign(CONFIG[key].get("supply", []))
	return out

static func config_for_role(role_id: int) -> Dictionary:
	for key in CONFIG.keys():
		if role_of(key) == role_id:
			return CONFIG[key]
	return {}

## Diálogo de compra y venta para los oficios con `goods` (V5d).
static func shop_dialogue(npc, needs_line: String, discount_tag: String) -> Dictionary:
	var c: Dictionary = config_for_role(int(npc.trade_role))
	var cat: Dictionary = SimpleInventory.CATALOG
	var stock_parts: Array[String] = []
	var choices: Array = [{"label": "📜 Negocio, Escritura de Propiedad y Caja Registradora", "next": "END", "action": "open_business_panel"}]
	for g in (c["goods"]["buy"] as Array):
		var nm: String = str(cat.get(g[0], {}).get("name", g[0]))
		stock_parts.append("%s: %d" % [nm, int(npc.shop_stock.get(g[0], 0))])
		choices.append({"label": "🛒 Comprar 1 %s (-%d Oro) [Stock: %d]" % [nm, npc._get_dynamic_buy_price(int(g[1])), int(npc.shop_stock.get(g[0], 0))], "next": "start", "action": "buy:%s:%d" % [g[0], int(g[1])]})
	for g in (c["goods"]["sell"] as Array):
		var nm2: String = str(cat.get(g[0], {}).get("name", g[0]))
		choices.append({"label": "💰 Vender 1 %s (+%d Oro)" % [nm2, npc._get_dynamic_sell_price(int(g[1]))], "next": "start", "action": "sell:%s:%d" % [g[0], int(g[1])]})
	choices.append({"label": "💬 Charlar un rato (+8 Relación)", "next": "family_chat", "affinity": 8})
	choices.append({"label": "Hasta pronto. [Salir]", "next": "END"})
	return {
		"start": {"text": "Soy %s de la %s (%s). %s%s%s\n[%s]" % [npc.npc_name, npc.family_name, npc.npc_role, needs_line, discount_tag, npc._get_market_header_line(), " | ".join(stock_parts)], "choices": choices},
		"family_chat": {"text": str(c.get("chat", "")), "choices": [{"label": "Entiendo. [Volver]", "next": "start"}]}
	}

## Campos, corrales, cantera y troncos alrededor de los edificios de las afueras (forman parte del dibujo del solar).
static func build_extras(vm, id: String) -> void:
	if id == "e5":
		load("res://scripts/systems/VillageCulture.gd").build_tinker_stations(vm)
	var c: Dictionary = {}
	for key in CONFIG.keys():
		if str(CONFIG[key]["lot"]) == id or str(CONFIG[key].get("fields_lot", "")) == id:
			c = CONFIG[key]
	if c.is_empty() or not c.has("extras"):
		return
	var d: Dictionary = VillageLots.lot_def(id)
	var lc: Vector2 = VillageLots.Solar.a_mundo(id, d["center"]) # centro del terreno en el mundo
	var half: Vector2 = (d["size"] as Vector2) * 0.5 # el terreno ya se mide en el mundo
	var props: String = "res://assests/Comprados/Epic RPG World - The Village V2.1/tilesets and props/props-sprites/"
	var is_fields_lot: bool = str(c.get("fields_lot", "")) == id
	# Todo se dibuja ya en el mundo: el terreno con su solar y lo pegado al edificio con el edificio
	_build_extras_en_mundo(vm, id, c, lc, half, is_fields_lot, props)


static func _build_extras_en_mundo(vm, id: String, c: Dictionary, lc: Vector2, half: Vector2, is_fields_lot: bool, props: String) -> void:
	var dc: Vector2 = VillageLots.anexo(id, Vector2.ZERO)
	var borde_solar: float = lc.x - half.x + MARGEN_SOLAR
	# Franja libre del solar (a la derecha del edificio según su ancho real, o el solar entero si es solo de campos)
	var x0: float = borde_solar if is_fields_lot else maxf(borde_solar, VillageLots.building_center(id).x + dc.x + _mitad_ancho_edificio(id) + MARGEN_SOLAR)
	var x1: float = lc.x + half.x - MARGEN_SOLAR
	var y0: float = lc.y - half.y + 10.0
	var y1: float = lc.y + half.y - 10.0
	match str(c["extras"]):
		"farm":
			if not is_fields_lot:
				vm.adorno_mundo(props + "hay_0.png", Vector2(x1 - 14.0, y1 - 10.0), 0.0)
		"ranch":
			vm.adorno_mundo(props + "hay_2.png", Vector2(x0 + 12.0, y1 - 12.0), 0.0)
			load("res://scripts/systems/VillageHousing.gd").sync_livestock(vm)
		"quarry":
			for rp in [Vector2(x0 + 18, y0 + 22), Vector2(x1 - 20, y0 + 40), Vector2(x0 + 30, y1 - 24), Vector2(x1 - 30, y1 - 18)]:
				vm.add_marca_3d_mundo(TIPO_3D_ROCA, rp)
		"woods":
			for lp in [Vector2(-82, 10), Vector2(82, 14)]:
				vm.adorno_mundo(props + "logs_0.png", VillageLots.building_center(id) + dc + lp, 0.0)

## Los solares de estos oficios siempre tienen su tienda (también en partidas guardadas antes de V5).
static func ensure_lots(vm) -> void:
	for key in CONFIG.keys():
		var c: Dictionary = CONFIG[key]
		var st: Dictionary = VillageLots.lot(vm, str(c["lot"]))
		if str(st["status"]) != "built" or str(st["kind"]) != "shop_house":
			st["status"] = "built"
			st["kind"] = "shop_house"
			st["progress"] = 1.0
		st["role"] = role_of(key)
		st["title"] = c["shop_title"]
		st["family_id"] = c["family_id"]
		if c.has("fields_lot"):
			var fs: Dictionary = VillageLots.lot(vm, str(c["fields_lot"]))
			fs["status"] = "built"
			fs["kind"] = "fields"
			fs["progress"] = 1.0
			fs["title"] = "🌾 Campos de la Granja"

## Cada día: quien tiene dinero de sobra puede estrenar ropa si la sastrería tiene y está abierta hoy.
static func daily(vm) -> void:
	fix_quarry_post(vm)
	var tailor = vm.trade_npcs.get(role_of("tailor"))
	if tailor == null or not is_instance_valid(tailor) or tailor.is_dead or tailor.is_downed or vm.is_trade_sabotaged(role_of("tailor")):
		return
	var VillageNeeds = vm.VillageNeeds
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if int(tailor.shop_stock.get("clothes", 0)) <= 0:
			return
		if not (n is VillageNPC) or n == tailor or n.is_dead or n.is_downed or VillageNeeds.is_outsider(n):
			continue
		var cls: String = VillageNeeds.class_of(n)
		var ch: float = float(CLOTHES_CHANCE.get(cls, 0.0))
		if ch <= 0.0 or n.personal_gold < CLOTHES_PRICE + CLOTHES_RESERVE:
			continue
		ch *= clampf(1.0 + TraitCatalog.npc_tendency(n, "spending") + 0.5 * TraitCatalog.npc_tendency(n, "fame"), 0.2, 2.5) # Derrochones y vanidosos, más; ahorradores, menos
		if randf() >= ch:
			continue
		buy_clothes(vm, n, tailor)

static func buy_clothes(_vm, n, tailor) -> void:
	n.personal_gold -= CLOTHES_PRICE
	tailor.personal_gold = maxi(0, tailor.personal_gold) + CLOTHES_PRICE
	tailor.shop_stock["clothes"] = int(tailor.shop_stock.get("clothes", 0)) - 1
	tailor._sync_shop_stock_to_vm()
	n.add_thought("Estrena ropa nueva (+8)", 8.0)
	n.set_meta("new_clothes_day", int(WorldClock.current_day) if WorldClock else 0)
