@tool
extends RefCounted

## V5: oficios nuevos que viven en los solares (panadería y sastrería, de momento).
## - El edificio está desde el principio, pero el puesto empieza VACANTE: lo ocupa quien quiera y pueda, por las reglas
##   de siempre (un vecino ambicioso, un viajero sin oficio de la posada o, si no, un forastero que llega por el camino).
## - Panadería: pan con harina del molino (pescadería) y leña; vende a casas y posadas como una tienda de comida más.
## - Sastrería: ropa con cuero del carnicero. Los vecinos estrenan ropa cuando les sobra dinero, más los ricos; da buen
##   humor y se nota en cómo los ven los demás.
## Nombres provisionales (anotados en docs/APORTES_CREATIVOS.md).

const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

const CONFIG: Dictionary = {
	"baker": {"lot": "n2", "role_name": "BAKER", "family_id": "family_baker", "family_name": "Casa de la Espiga",
		"shop_title": "🍞 Panadería 'La Espiga'", "title": "Panadero", "tex": "res://assests/world/village/villager_innkeeper.png",
		"stock": {"bread": 6}},
	"tailor": {"lot": "n3", "role_name": "TAILOR", "family_id": "family_tailor", "family_name": "Casa del Dedal",
		"shop_title": "🧵 Sastrería 'El Dedal'", "title": "Sastre", "tex": "res://assests/world/village/villager_traveler.png",
		"stock": {"clothes": 2}},
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
		var lay: Dictionary = VillageLots.shop_house_layout(str(c["lot"]))
		vm.trade_configs[role_of(key)] = {
			"family_id": c["family_id"], "family_name": c["family_name"], "shop_title": c["shop_title"],
			"shop_center": VillageLots.lot_def(str(c["lot"]))["center"], "is_mixed_building": true,
			"house_title": c["shop_title"], "house_center": VillageLots.lot_def(str(c["lot"]))["center"],
			"title": c["title"], "tex": vm._load_tex(str(c["tex"])), "stock": (c["stock"] as Dictionary).duplicate(),
			"work_pos": lay["work_pos"], "bed1_pos": lay["bed1_pos"], "bed2_pos": lay["bed2_pos"], "table_pos": lay["table_pos"],
		}
		if not vm.house_pantry.has(str(c["family_id"])):
			vm.house_pantry[str(c["family_id"])] = 2
	ensure_lots(vm)

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

## Cada día: quien tiene dinero de sobra puede estrenar ropa si la sastrería tiene y está abierta hoy.
static func daily(vm) -> void:
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

static func buy_clothes(vm, n, tailor) -> void:
	n.personal_gold -= CLOTHES_PRICE
	tailor.personal_gold = maxi(0, tailor.personal_gold) + CLOTHES_PRICE
	tailor.shop_stock["clothes"] = int(tailor.shop_stock.get("clothes", 0)) - 1
	tailor._sync_shop_stock_to_vm()
	n.add_thought("Estrena ropa nueva (+8)", 8.0)
	n.set_meta("new_clothes_day", int(WorldClock.current_day) if WorldClock else 0)
