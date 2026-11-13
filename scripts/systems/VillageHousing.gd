@tool
extends RefCounted

## Bloque P6: Casa propia, propiedades y ser terrateniente (10 mecánicas).
## 1) Construir tu casa al contado (100 Oro) o con hipoteca a plazos (15 de entrada + 3/día, con embargo si no pagas).
## 2) Cama propia, lavabo y cofre privado en tu casa (dormir gratis hasta las 6:00 y guardar sin que sea robo).
## 3) Mejoras de interior encargadas al carpintero (estantería, banco de trabajo, cama de roble, cerradura reforzada).
## 4) Invitar a tu pareja a vivir contigo (se muda a tu casa y aporta 5 de oro al día).
## 5) Comprar más casas o casas embargadas y ser casero (los inquilinos te pagan el alquiler cada noche).
## 6) Trato con tus inquilinos (subir el alquiler, perdonar cuotas a cambio de lealtad o desahuciarlos).
## 7) Pequeño huerto o gallinero en tu solar (produce comida fresca cada 2 días).
## 8) Invitar vecinos a cenar a tu casa (sube amistad, reconcilia rivales y sueltan secretos).
## 9) Escondite secreto bajo las tablas del suelo (oro oculto a salvo de robos y multas policiales).
## 10) Ser dueño de locales comerciales (cobras el 15 % semanal de la caja del taller).
## Estado en `vm.lots_state` y `vm.town_state["housing"]` (se guardan automáticamente).

const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const Solar = preload("res://mapa/solar.gd")
const VillageLoans = preload("res://scripts/systems/VillageLoans.gd")
const TraitDiscovery = preload("res://scripts/systems/TraitDiscovery.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const LivestockAnimalScript = preload("res://scripts/obstacles/LivestockAnimal.gd")

const HOUSE_CASH_COST: int = 100 # Precio de una casa mediana; cada solar cobra lo suyo con VillageLots.house_cost
const FORECLOSED_COST: int = 80
const UPGRADE_COSTS: Dictionary = {"bookshelf": 35, "workbench": 40, "oak_bed": 30, "strong_lock": 25, "hidden_cellar": 45, "hearth": 25, "upper_floor": 50}
const STASH_BUILD_COST: int = 30
const DINNER_COST: int = 10
const COMMERCIAL_DEED_COST: int = 120
const FOUND_SHOP_COST: int = 65
const ADVERTISE_COST: int = 12
const ADVERTISE_COOLDOWN_DAYS: int = 3
const SHOP_SALE_PRICE: int = 10
const SHOP_STOCK_PER_PRESS: int = 6
## Precio de venta en tu bazar según lo que pongas en el mostrador (una madera no vale lo mismo que una prenda)
const SHOP_ITEM_PRICES: Dictionary = {"bread": 6, "cooked_meat": 7, "herbal_poultice": 9, "repair_kit": 12, "clothes": 14, "wood": 3, "iron_ore": 6, "fish": 5, "masterwork_piece": 40}
const SHOP_THEFT_CHANCE: float = 0.18 # Sin dependiente, de noche pueden vaciarte parte de la caja
const SHOP_THEFT_CHANCE_CLERK: float = 0.07
const CLERK_WAGE: int = 4
const SHOP_OPEN_HOUR: int = 8
const SHOP_CLOSE_HOUR: int = 18
const SHOP_CLERK_RADIUS: float = 42.0
const STOCKABLE_ITEMS: Array[String] = ["bread", "cooked_meat", "herbal_poultice", "repair_kit", "clothes", "wood", "iron_ore", "fish", "masterwork_piece"]
const JUVENILE_DAYS: int = 3
const ADULT_ANIMAL_DAYS: int = 6
const RANCH_PEN_RECT: Rect2 = Rect2(Vector2(310.0, 404.0), Vector2(100.0, 134.0))

## El corral del rancho en el mundo: centrado en la cruz «corral_rancho» de «Sitios» (en el centro de su valla).
const SITIO_CORRAL := "corral_rancho"
static func ranch_pen_rect_mundo() -> Rect2:
	var centro: Vector2 = load("res://mapa/sitio.gd").call("mundo", SITIO_CORRAL)
	return Rect2(centro - RANCH_PEN_RECT.size * 0.5, RANCH_PEN_RECT.size)
const CATERING_COST_PER_GUEST: int = 4
const TABLE_SEAT_DIST: float = 14.0
const GATHERING_PLAYER_RADIUS: float = 90.0
const GATHERING_DURATION_MIN: int = 120
const GATHERING_CHAT_INTERVAL_MIN: int = 20
const TABLE_FOOD_ITEMS: Array[String] = ["bread", "cooked_meat", "pasta_dish", "braised_meat", "country_stew", "roasted_chicken", "cooked_fish", "fried_frog_legs", "royal_ration", "fish", "carrot", "cabbage", "raw_meat", "raw_chicken", "wheat"]
const GATHERING_CHAT_PHRASES: Array[String] = [
	"🍷 «¡A vuestra salud!»",
	"🍲 «Esta comida huele de maravilla.»",
	"🕯️ «Se está bien aquí al calor de la mesa.»",
	"🍞 «Pásame el pan, por favor.»",
	"💬 «Hacía falta sentarse a charlar un rato.»",
	"🍺 «Brindemos por una noche tranquila en el valle.»",
]

static func state(vm) -> Dictionary:
	var ts: Dictionary = vm.VillageTown.state(vm)
	if not ts.has("housing") or not (ts["housing"] is Dictionary):
		ts["housing"] = {}
	var hs: Dictionary = ts["housing"]
	if not hs.has("partner_key"):
		hs["partner_key"] = ""
	if not hs.has("stash_gold"):
		hs["stash_gold"] = 0
	if not hs.has("has_stash"):
		hs["has_stash"] = false
	if not hs.has("last_dinner_day"):
		hs["last_dinner_day"] = -99
	if not hs.has("last_party_day"):
		hs["last_party_day"] = -99
	if not hs.has("last_study_day"):
		hs["last_study_day"] = -99
	if not hs.has("table_rations"):
		hs["table_rations"] = 0
	if not hs.has("gathering") or not (hs["gathering"] is Dictionary):
		hs["gathering"] = {}
	if not hs.has("commercial_deeds") or not (hs["commercial_deeds"] is Dictionary):
		hs["commercial_deeds"] = {}
	if not hs.has("rent_rates") or not (hs["rent_rates"] is Dictionary):
		hs["rent_rates"] = {}
	if not hs.has("intruder_attempt") or not (hs["intruder_attempt"] is Dictionary):
		hs["intruder_attempt"] = {}
	if not hs.has("player_shop") or not (hs["player_shop"] is Dictionary):
		hs["player_shop"] = {}
	if not hs.has("ranch_herd") or not (hs["ranch_herd"] is Array):
		hs["ranch_herd"] = [
			{"species": "cow", "stage": "adult", "age_days": 6},
			{"species": "bull", "stage": "adult", "age_days": 7},
			{"species": "sheep", "stage": "adult", "age_days": 6},
			{"species": "sheep", "stage": "juvenile", "age_days": 3},
			{"species": "donkey", "stage": "adult", "age_days": 6},
			{"species": "horse", "stage": "juvenile", "age_days": 4},
			{"species": "rooster", "stage": "adult", "age_days": 6},
			{"species": "rooster", "stage": "chick", "age_days": 1},
		]
	if not hs.has("toby_lot"):
		hs["toby_lot"] = ""
	return hs

static func today() -> int:
	return int(WorldClock.current_day) if WorldClock else 1

static func player_lots(vm, built_only: bool = true) -> Array[String]:
	var out: Array[String] = []
	for l in VillageLots.lots():
		var id: String = str(l["id"])
		var st: Dictionary = VillageLots.lot(vm, id)
		if str(st.get("payer", "")) == "player" and (not built_only or str(st.get("status", "")) == "built"):
			out.append(id)
	return out

static func primary_player_lot(vm) -> String:
	var lots: Array[String] = player_lots(vm, true)
	if not lots.is_empty():
		return lots[0]
	var all_p: Array[String] = player_lots(vm, false)
	return all_p[0] if not all_p.is_empty() else ""

static func has_upgrade(vm, upg: String) -> bool:
	for id in player_lots(vm, true):
		var up: Dictionary = VillageLots.lot(vm, id).get("upgrades", {})
		if bool(up.get(upg, false)):
			return true
	return false

## Borrar la búsqueda (sótano, pasadizo del contrabandista, archivo policial) comparte una espera de 7 días.
const WANTED_PURGE_DAYS: int = 7
static func can_purge_wanted(vm) -> bool:
	return today() - int(state(vm).get("last_hide_day", -99)) >= WANTED_PURGE_DAYS

static func mark_wanted_purge(vm) -> void:
	state(vm)["last_hide_day"] = today()

## Paso a 3D, paso 2e: ¿está `pos` dentro de una casa construida del jugador con la mejora `upg` («upper_floor»,
## «hidden_cellar»)? Lo usa Suelo.gd para dar altura de verdad al piso alto y al sótano.
static func casa_del_jugador_con(vm, pos: Vector2, upg: String) -> bool:
	if vm == null:
		return false
	for id in player_lots(vm, true):
		if bool((VillageLots.lot(vm, id).get("upgrades", {}) as Dictionary).get(upg, false)):
			var d: Dictionary = VillageLots.lot_def(id)
			if Rect2(Solar.a_mundo(id, d["center"] as Vector2) - (d["size"] as Vector2) * 0.5, d["size"]).grow(6.0).has_point(pos): # la casa está en su sitio del mundo
				return true
	return false

## Cambiar de piso solo tiene sentido dentro de tu casa: el jugador debe estar cerca de un solar suyo construido.
const HOME_LEVEL_RADIUS: float = 90.0
static func player_near_home(vm) -> bool:
	var pl = VillageNeeds.player_of(vm)
	if pl == null:
		return true
	for id in player_lots(vm, true):
		if pl.global_position.distance_to(Solar.a_mundo(id, VillageLots.lot_def(id)["center"])) <= HOME_LEVEL_RADIUS:
			return true
	return false

static func is_player_family_chest(vm, fam_id: String) -> bool:
	if not fam_id.begins_with("family_lot_"):
		return false
	var lot_id: String = fam_id.trim_prefix("family_lot_")
	return str(VillageLots.lot(vm, lot_id).get("payer", "")) == "player"

static func tenant_lot_of(vm, npc) -> String:
	if npc == null or not str(npc.lodging).begins_with("house:"):
		return ""
	var lid: String = str(npc.lodging).get_slice(":", 1)
	if str(VillageLots.lot(vm, lid).get("payer", "")) == "player":
		return lid
	return ""

static func rent_for_lot(vm, lot_id: String) -> int:
	var rates: Dictionary = state(vm)["rent_rates"]
	return int(rates.get(lot_id, 3))

## Tanda 5 (22): Precio de reventa de una casa según el atractivo del pueblo y las mejoras instaladas.
static func house_sale_price(vm, lot_id: String) -> int:
	var st: Dictionary = VillageLots.lot(vm, lot_id)
	var attr: float = float(vm.VillageMigration.attractiveness(vm).get("score", 0.0)) if "VillageMigration" in vm and vm.VillageMigration != null else 0.0
	var price: int = int(round(90.0 * float(VillageLots.house_cost(lot_id)) / 100.0)) + int(round(attr * 30.0)) # Casona vale más que casita
	var up: Dictionary = st.get("upgrades", {})
	for uk in up.keys():
		if bool(up[uk]):
			price += 15
	return clampi(price, 80, 200)

## Tanda 5 (24): Descansar junto al hogar de leña calienta a quienes viven en tu casa (+10 de humor) y restaura fuerzas.
static func rest_by_hearth(vm, player: Node2D = null) -> bool:
	if not has_upgrade(vm, "hearth"):
		return false
	var p_lot: String = primary_player_lot(vm)
	if p_lot == "":
		return false
	if player != null:
		var hc = player.get("health_comp")
		if hc != null and "max_health" in hc:
			hc.current_health = hc.max_health
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for rk in (VillageLots.lot(vm, p_lot).get("residents", []) as Array):
		var r_npc = by_key.get(str(rk), null)
		if r_npc != null and not r_npc.is_dead:
			r_npc.add_thought("Calor de hogar junto a la chimenea de leña (+10)", 10.0)
	return true

## Bloque PG: Fundar tu propio negocio desde cero en un solar construido tuyo, abastecerlo, contratar dependiente y hacerle publicidad.
static func has_player_shop(vm) -> bool:
	return not (state(vm)["player_shop"] as Dictionary).is_empty()

static func found_player_shop(vm, lot_id: String, inv, carpenter = null) -> bool:
	if lot_id == "" or has_player_shop(vm) or inv == null or int(inv.gold) < FOUND_SHOP_COST:
		return false
	var st: Dictionary = VillageLots.lot(vm, lot_id)
	if str(st.get("payer", "")) != "player" or str(st.get("status", "")) != "built":
		return false
	inv.add_gold(-FOUND_SHOP_COST)
	if carpenter != null and "personal_gold" in carpenter:
		carpenter.personal_gold += FOUND_SHOP_COST
	else:
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + FOUND_SHOP_COST
	state(vm)["player_shop"] = {
		"lot": lot_id,
		"name": "Bazar del Forastero",
		"stock": 0,
		"goods": {},
		"till_gold": 0,
		"ad_days": 0,
		"last_ad_day": -99,
		"clerk_key": "",
		"total_sales": 0,
		"buyers_today": 0,
		"last_wage_day": -99,
		"till_since_day": -99
	}
	sync_home_props(vm)
	VillageChronicle.add(vm, "player_shop_founded", "Acondicionaste un mostrador y fundaste tu propio negocio («Bazar del Forastero») en el solar %s" % lot_id, true)
	return true

static func stock_player_shop(vm, inv) -> int:
	if not has_player_shop(vm) or inv == null:
		return 0
	var ps: Dictionary = state(vm)["player_shop"]
	var added: int = 0
	if not (ps.get("goods", null) is Dictionary):
		ps["goods"] = {}
	for item_id in STOCKABLE_ITEMS:
		while added < SHOP_STOCK_PER_PRESS and inv.has_item(item_id, 1):
			inv.remove_item(item_id, 1)
			ps["goods"][item_id] = int((ps["goods"] as Dictionary).get(item_id, 0)) + 1
			added += 1
		if added >= SHOP_STOCK_PER_PRESS:
			break
	if added > 0:
		ps["stock"] = int(ps.get("stock", 0)) + added
	return added

static func collect_player_shop_till(vm, inv) -> int:
	if not has_player_shop(vm):
		return 0
	var ps: Dictionary = state(vm)["player_shop"]
	var gain: int = int(ps.get("till_gold", 0))
	if gain <= 0:
		return 0
	ps["till_gold"] = 0
	ps["till_since_day"] = -99
	if inv != null:
		inv.add_gold(gain)
	return gain

static func player_shop_lot(vm) -> String:
	if not has_player_shop(vm):
		return ""
	var lid: String = str(state(vm)["player_shop"].get("lot", ""))
	return lid if not lid.is_empty() else primary_player_lot(vm)

## Un sitio de la tienda del jugador (plano de su solar) llevado al mundo, donde está ahora la pieza del solar.
static func _en_tienda(vm, p_plano: Vector2) -> Vector2:
	var lid: String = player_shop_lot(vm)
	return p_plano if lid.is_empty() else Solar.a_mundo(lid, p_plano) # sin tienda no hay sitio que llevar


static func player_shop_counter_pos(vm) -> Vector2:
	var lid: String = player_shop_lot(vm)
	return home_prop_pos(vm, lid, "player_shop_counter") if not lid.is_empty() else Vector2.ZERO

static func player_shop_clerk_pos(vm) -> Vector2:
	var lid: String = player_shop_lot(vm)
	if lid.is_empty():
		return Vector2.ZERO
	var d: Dictionary = VillageLots.lot_def(lid)
	var m: float = -1.0 if bool(d.get("door_south", true)) else 1.0
	return home_prop_pos(vm, lid, "player_shop_counter") + Vector2(0.0, 6.0 * m)

static func player_shop_customer_pos(vm) -> Vector2:
	var lid: String = player_shop_lot(vm)
	if lid.is_empty():
		return Vector2.ZERO
	var d: Dictionary = VillageLots.lot_def(lid)
	var m: float = -1.0 if bool(d.get("door_south", true)) else 1.0
	return home_prop_pos(vm, lid, "player_shop_counter") + Vector2(0.0, -8.0 * m)

static func is_player_shop_open_hour(hour: int) -> bool:
	return hour >= SHOP_OPEN_HOUR and hour < SHOP_CLOSE_HOUR

static func get_player_shop_clerk(vm):
	if not has_player_shop(vm) or vm == null:
		return null
	var ck: String = str(state(vm)["player_shop"].get("clerk_key", ""))
	if ck.is_empty():
		return null
	var clerk = vm._get_npcs_by_person_key().get(ck, null)
	if clerk == null or not is_instance_valid(clerk) or clerk.is_dead:
		return null
	return clerk

static func is_player_shop_clerk_present(vm) -> bool:
	var clerk = get_player_shop_clerk(vm)
	if clerk == null or clerk.is_downed or clerk.is_sleeping or not clerk.is_conscious():
		return false
	return clerk.global_position.distance_to(_en_tienda(vm, player_shop_counter_pos(vm))) <= SHOP_CLERK_RADIUS

static func pay_player_shop_clerk(vm) -> bool:
	if not has_player_shop(vm):
		return false
	var ps: Dictionary = state(vm)["player_shop"]
	var ck: String = str(ps.get("clerk_key", ""))
	if ck.is_empty():
		return false
	var clerk = vm._get_npcs_by_person_key().get(ck, null)
	if clerk == null or not is_instance_valid(clerk) or clerk.is_dead:
		ps["clerk_key"] = ""
		return false
	if int(ps.get("last_wage_day", -99)) == today():
		return false
	if int(ps.get("till_gold", 0)) >= CLERK_WAGE:
		ps["till_gold"] = int(ps["till_gold"]) - CLERK_WAGE
		clerk.personal_gold += CLERK_WAGE
		ps["last_wage_day"] = today()
		return true
	return false

static func _next_shop_item_id(ps: Dictionary) -> String:
	var goods = ps.get("goods", null)
	if not (goods is Dictionary):
		return ""
	for g_id in (goods as Dictionary).keys():
		if int(goods[g_id]) > 0:
			return str(g_id)
	return ""

static func on_hour(vm, hour: int) -> void:
	if vm == null:
		return
	tick_gathering(vm, hour)
	if not has_player_shop(vm):
		return
	var ps: Dictionary = state(vm)["player_shop"]
	var clerk = get_player_shop_clerk(vm)
	if clerk == null and not str(ps.get("clerk_key", "")).is_empty():
		ps["clerk_key"] = ""
	if not is_player_shop_open_hour(hour):
		if hour == SHOP_CLOSE_HOUR:
			pay_player_shop_clerk(vm)
		if clerk != null and clerk.errand_kind == "player_shop_clerk":
			clerk.end_errand()
		for n in VillageNeeds.living(vm):
			if n.errand_kind == "player_shop_buy":
				n.end_errand()
		return
	# En horario comercial (8:00 a 18:00), el dependiente contratado camina hasta detrás de tu mostrador y se queda allí
	if clerk != null and not clerk.is_downed and not clerk.is_sleeping and clerk.is_conscious() and clerk.rite_pos == Vector2.ZERO and not clerk.is_in_live_fight() and not clerk.is_busy_with_player():
		if "VillageWork" in vm and vm.VillageWork != null:
			vm.VillageWork._release(clerk)
		var c_spot: Vector2 = _en_tienda(vm, player_shop_clerk_pos(vm)) # destino en el mundo
		if clerk.errand_kind != "player_shop_clerk":
			clerk.start_errand("player_shop_clerk", c_spot)
		else:
			clerk.errand_pos = c_spot
			clerk.errand_since = VillageNeeds.total_hours()
	# Clientes reales: durante el día, vecinos con oro se acercan andando al mostrador para comprar 1 unidad
	if int(ps.get("stock", 0)) <= 0 or clerk == null:
		return
	var next_item: String = _next_shop_item_id(ps)
	if next_item.is_empty():
		ps["stock"] = 0
		return
	var price: int = int(SHOP_ITEM_PRICES.get(next_item, 5))
	var max_daily_buyers: int = 2 + (2 if int(ps.get("ad_days", 0)) > 0 else 0)
	var active_walkers: int = 0
	var living_npcs: Array = VillageNeeds.living(vm)
	for n in living_npcs:
		if n.errand_kind == "player_shop_buy":
			active_walkers += 1
	var slots_left: int = mini(int(ps.get("stock", 0)), max_daily_buyers - int(ps.get("buyers_today", 0))) - active_walkers
	if slots_left <= 0:
		return
	var max_this_hour: int = mini(slots_left, 2 if int(ps.get("ad_days", 0)) > 0 else 1)
	var sent: int = 0
	var ck: String = clerk.get_person_key()
	var cust_spot: Vector2 = _en_tienda(vm, player_shop_customer_pos(vm)) # destino real de los clientes
	for pass_idx in range(2):
		if sent >= max_this_hour:
			break
		for n in living_npcs:
			if sent >= max_this_hour:
				break
			if int(n.trade_role) == int(VillageNPC.TradeRole.CHILD) or VillageNeeds.is_outsider(n) or n.get_person_key() == ck:
				continue
			if n.errand_kind != "" or n.rite_pos != Vector2.ZERO or n.is_in_live_fight() or n.is_busy_with_player() or n.sick_level >= 2:
				continue
			if pass_idx == 0 and not VillageNeeds.is_free(n):
				continue
			if int(n.personal_gold) >= price + 12:
				n.start_errand("player_shop_buy", cust_spot)
				sent += 1

static func on_customer_arrived(vm, customer) -> bool:
	if customer != null and is_instance_valid(customer) and customer.errand_kind == "player_shop_buy":
		customer.end_errand()
	if vm == null or not has_player_shop(vm) or customer == null or not is_instance_valid(customer) or customer.is_dead or customer.is_downed:
		return false
	# Sin el dependiente físicamente detrás del mostrador, la tienda no vende
	if not is_player_shop_clerk_present(vm):
		return false
	if customer.global_position.distance_to(_en_tienda(vm, player_shop_counter_pos(vm))) > SHOP_CLERK_RADIUS:
		return false
	var ps: Dictionary = state(vm)["player_shop"]
	if int(ps.get("stock", 0)) <= 0:
		return false
	if not (ps.get("goods", null) is Dictionary):
		ps["goods"] = {}
	var goods: Dictionary = ps["goods"]
	var sold_item: String = _next_shop_item_id(ps)
	if sold_item.is_empty():
		ps["stock"] = 0
		return false
	var price: int = int(SHOP_ITEM_PRICES.get(sold_item, 5))
	if int(customer.personal_gold) < price:
		return false
	var was_empty_till: bool = int(ps.get("till_gold", 0)) <= 0
	customer.personal_gold -= price
	goods[sold_item] = int(goods[sold_item]) - 1
	if int(goods[sold_item]) <= 0:
		goods.erase(sold_item)
	ps["till_gold"] = int(ps.get("till_gold", 0)) + price
	if was_empty_till:
		ps["till_since_day"] = today()
	ps["stock"] = maxi(0, int(ps.get("stock", 0)) - 1)
	ps["total_sales"] = int(ps.get("total_sales", 0)) + 1
	ps["buyers_today"] = int(ps.get("buyers_today", 0)) + 1
	if customer.has_method("add_pocket_item"):
		customer.add_pocket_item(sold_item, 1)
	customer.modify_affinity(2)
	customer.add_thought("Compré buena mercancía en el Bazar del Forastero (+3)", 3.0)
	customer._spawn_floating_text("🛍️ -%d Oro" % price, Color.GOLD, -30.0)
	var clerk = get_player_shop_clerk(vm)
	if clerk != null:
		clerk._spawn_floating_text("💰 +%d Oro (Caja)" % price, Color.SPRING_GREEN, -30.0)
	return true

static func advertise_player_shop(vm, inv) -> bool:
	if not has_player_shop(vm) or inv == null or int(inv.gold) < ADVERTISE_COST:
		return false
	var ps: Dictionary = state(vm)["player_shop"]
	if today() - int(ps.get("last_ad_day", -99)) < ADVERTISE_COOLDOWN_DAYS:
		return false
	inv.add_gold(-ADVERTISE_COST)
	vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + ADVERTISE_COST
	ps["ad_days"] = 3
	ps["last_ad_day"] = today()
	VillageChronicle.add(vm, "player_shop_ad", "Repartiste carteles y pregonaste tu negocio por el valle para atraer clientela", true)
	return true

## Bloque PI.1: Animales con etapas de crecimiento (cría -> joven -> adulto) y crianza en el Rancho y en tu corral.
static func animal_stage_for_days(days: int) -> String:
	if days >= ADULT_ANIMAL_DAYS:
		return "adult"
	if days >= JUVENILE_DAYS:
		return "juvenile"
	return "chick"

static func find_toby(vm):
	if vm == null:
		return null
	if "domestic_pets" in vm:
		for p in vm.domestic_pets:
			if is_instance_valid(p) and str(p.get("pet_name")) == "Toby":
				return p
	if vm.is_inside_tree() and vm.get_tree() != null:
		for p2 in vm.get_tree().get_nodes_in_group("domestic_pets"):
			if is_instance_valid(p2) and str(p2.get("pet_name")) == "Toby":
				return p2
	return null

static func toby_pos_for_lot(_vm, lot_id: String) -> Vector2:
	var d: Dictionary = VillageLots.lot_def(lot_id)
	if d.is_empty():
		return Vector2(128.0, 126.0)
	var c: Vector2 = d.get("center", Vector2.ZERO)
	var half_sz: Vector2 = VillageLots.house_size(lot_id) * 0.5
	var m: float = 1.0 if d.get("door_south") == true else -1.0
	return c + Vector2(half_sz.x * 0.55, (half_sz.y + 10.0) * m)

static func sync_relocated_camp_assets(vm, teleport_toby: bool = false) -> void:
	if vm == null:
		return
	var hs: Dictionary = state(vm)
	var t_lot: String = str(hs.get("toby_lot", ""))
	if t_lot != "" and str(VillageLots.lot(vm, t_lot).get("payer", "")) == "player" and str(VillageLots.lot(vm, t_lot).get("status", "")) == "built":
		var t_pos: Vector2 = Solar.a_mundo(t_lot, toby_pos_for_lot(vm, t_lot))
		if "entities_root" in vm and is_instance_valid(vm.entities_root):
			var bed: Node2D = vm.entities_root.get_node_or_null("PetBed_Toby") as Node2D
			if bed != null:
				bed.global_position = t_pos
		var toby = find_toby(vm)
		if toby != null and is_instance_valid(toby):
			toby.home_position = t_pos
			toby.owner_label = "Casa del Jugador (%s)" % t_lot
			if teleport_toby or toby.global_position.distance_to(t_pos) > 120.0:
				toby.global_position = t_pos
				toby._wander_target = t_pos

static func move_toby_to_lot(vm, lot_id: String = "") -> bool:
	if vm == null:
		return false
	var lid: String = lot_id if not lot_id.is_empty() else primary_player_lot(vm)
	if lid.is_empty():
		return false
	var st: Dictionary = VillageLots.lot(vm, lid)
	if str(st.get("payer", "")) != "player" or str(st.get("status", "")) != "built":
		return false
	state(vm)["toby_lot"] = lid
	sync_relocated_camp_assets(vm, true)
	VillageChronicle.add(vm, "toby_moved_home", "Trasladaste a Toby y su comedero al patio de tu casa en el solar %s" % lid, true)
	return true

static func sync_livestock(vm) -> void:
	if vm == null or not ("entities_root" in vm) or vm.entities_root == null or not is_instance_valid(vm.entities_root):
		return
	var hs: Dictionary = state(vm)
	var r_herd: Array = hs["ranch_herd"]
	var ranch_nodes: Array[Node2D] = []
	for c in vm.entities_root.get_children():
		if c is Node2D and is_instance_valid(c) and c.is_in_group("ranch_livestock"):
			ranch_nodes.append(c as Node2D)
	for i in range(r_herd.size()):
		if not (r_herd[i] is Dictionary):
			continue
		if i >= ranch_nodes.size():
			var node_r: Node2D = LivestockAnimalScript.new()
			vm.entities_root.add_child(node_r)
			ranch_nodes.append(node_r)
		ranch_nodes[i].call("configure_from_entry", vm, i, r_herd[i], ranch_pen_rect_mundo())
	while ranch_nodes.size() > r_herd.size():
		var ex_r: Node2D = ranch_nodes.pop_back()
		if ex_r != null and is_instance_valid(ex_r):
			ex_r.remove_from_group("ranch_livestock")
			ex_r.remove_from_group("livestock_animals")
			if ex_r.get_parent() != null:
				ex_r.get_parent().remove_child(ex_r)
			ex_r.queue_free()

static func shop_night_theft(vm, ps: Dictionary, chance: float) -> int:
	var till: int = int(ps.get("till_gold", 0))
	if till <= 1 or randf() >= chance:
		return 0
	var thief = null
	for n in VillageNeeds.living(vm):
		if int(n.trade_role) != int(VillageNPC.TradeRole.CHILD) and not VillageNeeds.is_outsider(n) and n.get_person_key() != str(ps.get("clerk_key", "")):
			if thief == null or int(n.personal_gold) < int(thief.personal_gold):
				thief = n
	if thief == null:
		return 0
	var stolen: int = int(float(till) / 2.0)
	ps["till_gold"] = till - stolen
	thief.personal_gold += stolen
	VillageChronicle.add(vm, "player_shop_robbed", "Alguien forzó de noche la caja del Bazar del Forastero y se llevó %d de oro" % stolen, true)
	return stolen

# ==============================================================================
# P6.1 y P6.5: Comprar casa al contado, con hipoteca o casa embargada
# ==============================================================================
static func buy_house_cash(vm, lot_id: String, inv) -> bool:
	var has_forged: bool = "VillageUnderworld" in vm and vm.VillageUnderworld != null and bool(vm.VillageUnderworld.state(vm).get("forged_deed", false))
	var cost: int = VillageLots.house_cost(lot_id) - (40 if has_forged else 0)
	if inv == null or int(inv.gold) < cost:
		return false
	if str(VillageLots.lot(vm, lot_id).get("status", "")) != "empty" or VillageLots.active_site(vm) != "":
		return false
	if has_forged:
		vm.VillageUnderworld.state(vm)["forged_deed"] = false
		if randf() < 0.30:
			vm.wanted_level = int(vm.wanted_level) + 1
			VillageChronicle.add(vm, "forged_deed_caught", "El ayuntamiento descubrió tu escritura falsificada al comprar el solar %s" % lot_id, true)
			return false
	inv.add_gold(-cost)
	# request_build con payer=null cobra de las arcas, así que ingresamos primero los 100 en las arcas y marcamos payer="player"
	# Con escritura falsa solo entra en las arcas lo que pagas: el resto lo pierde el pueblo (es un fraude, no oro nuevo)
	vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + cost
	var built: String = VillageLots.request_build(vm, lot_id, "house", null, "🏡 Casa del Forastero")
	if built == "":
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - cost
		inv.add_gold(cost)
		if has_forged:
			vm.VillageUnderworld.state(vm)["forged_deed"] = true
		return false
	var st: Dictionary = VillageLots.lot(vm, lot_id)
	st["payer"] = "player"
	st["upgrades"] = {}
	VillageChronicle.add(vm, "player_house_bought", "Encargaste al contado la construcción de tu propia casa en el solar %s" % lot_id, true)
	return true

static func buy_house_loan(vm, lot_id: String, inv) -> bool:
	if inv == null or int(inv.gold) < VillageLoans.DOWN_PAYMENT:
		return false
	if str(VillageLots.lot(vm, lot_id).get("status", "")) != "empty" or VillageLots.active_site(vm) != "":
		return false
	var full_cost: int = VillageLots.house_cost(lot_id)
	var principal: int = full_cost - VillageLoans.DOWN_PAYMENT
	var lender: Dictionary = VillageLoans.find_lender(vm, principal)
	if lender.is_empty():
		return false
	inv.add_gold(-VillageLoans.DOWN_PAYMENT)
	if str(lender["key"]) != "town" and lender.has("npc"):
		lender["npc"].personal_gold -= principal
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + full_cost
	else:
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + VillageLoans.DOWN_PAYMENT
	var built: String = VillageLots.request_build(vm, lot_id, "house", null, "🏡 Casa del Forastero")
	if built == "":
		inv.add_gold(VillageLoans.DOWN_PAYMENT)
		return false
	var st: Dictionary = VillageLots.lot(vm, lot_id)
	st["payer"] = "player"
	st["upgrades"] = {}
	var owed: int = int(round(float(principal) * (1.0 + VillageLoans.INTEREST)))
	st["loan"] = {"lender": str(lender["key"]), "lender_name": str(lender["name"]), "owed": owed, "missed": 0, "principal": principal}
	VillageChronicle.add(vm, "player_house_loan", "Encargaste tu casa en el solar %s con una hipoteca de %d de oro a %s" % [lot_id, owed, str(lender["name"])], true)
	return true

# ==============================================================================
# P6.2: Interactuar en el mundo con tu solar o tu cama (`VillageManager.interact`)
# ==============================================================================
## Muda a un vecino a tu casa principal (pareja o hijo adoptivo). Le saca de la lista de su casa anterior,
## para que no viva en dos sitios. `bed_i` elige cama (0 o 1). Devuelve false si no tienes casa.
static func move_into_player_home(vm, npc, bed_i: int) -> bool:
	var p_lot: String = primary_player_lot(vm)
	if p_lot == "" or npc == null:
		return false
	var key: String = npc.get_person_key()
	var old: String = str(npc.lodging)
	if old.begins_with("house:") and old != "house:" + p_lot:
		(VillageLots.lot(vm, old.trim_prefix("house:")).get("residents", []) as Array).erase(key)
	npc.lodging = "house:" + p_lot
	var beds: Array = VillageLots._house_beds(p_lot)
	if not beds.is_empty():
		npc.bed_position = Solar.a_mundo(p_lot, beds[clampi(bed_i, 0, beds.size() - 1)])
	npc.home_table_pos = Solar.a_mundo(p_lot, VillageLots.lot_def(p_lot)["center"] + Vector2(0, -2))
	VillageLots.add_resident(vm, p_lot, key)
	return true

## Confirmación sencilla: la primera E avisa; una segunda E en 4 s sobre lo mismo confirma.
static func press_twice(vm, tag: String) -> bool:
	var now: int = Time.get_ticks_msec()
	if str(vm.get_meta("e_confirm_tag", "")) == tag and now - int(vm.get_meta("e_confirm_ms", 0)) <= 4000:
		vm.set_meta("e_confirm_tag", "")
		return true
	vm.set_meta("e_confirm_tag", tag)
	vm.set_meta("e_confirm_ms", now)
	return false

static func try_interact(vm, player: Node2D, pos: Vector2) -> bool:
	var inv = player.get("inventory") if player != null else null
	for l in VillageLots.lots():
		var id: String = str(l["id"])
		var st: Dictionary = VillageLots.lot(vm, id)
		# 1. Cartel de solar libre de vivienda: encargar casa si tienes oro
		if str(st.get("status", "")) == "empty" and str(l.get("zone", "")) in ["borde", "barrio"] and pos.distance_to(Solar.a_mundo(id, VillageLots.site_work_pos(id))) <= 32.0:
			if VillageLots.active_site(vm) != "":
				if player.has_method("show_hint"):
					player.show_hint("🚧 El carpintero ya está ocupado en otra obra. Espera a que termine.")
				return true
			var lot_cost: int = VillageLots.house_cost(id)
			var can_cash: bool = inv != null and int(inv.gold) >= lot_cost
			var can_loan: bool = inv != null and int(inv.gold) >= VillageLoans.DOWN_PAYMENT
			if (can_cash or can_loan) and not press_twice(vm, "buy_lot:" + id):
				if player.has_method("show_hint"):
					var how: String = "al contado (-%d Oro)" % lot_cost if can_cash else "con hipoteca (-%d Oro de entrada y 3 Oro/día)" % VillageLoans.DOWN_PAYMENT
					player.show_hint("🏡❓ ¿Comprar el solar %s %s? Pulsa E otra vez para confirmar." % [id, how])
				return true
			var wanted_before: int = int(vm.wanted_level)
			if can_cash and buy_house_cash(vm, id, inv):
				if player.has_method("show_hint"):
					player.show_hint("🏡🔨 Compraste el solar %s al contado (-%d Oro). El carpintero vendrá a levantar tu casa." % [id, lot_cost])
				return true
			elif int(vm.wanted_level) > wanted_before:
				# Descubrieron la escritura falsa: no se sigue con la hipoteca como si nada.
				if player.has_method("show_hint"):
					player.show_hint("🚨📜 ¡El sello municipal de tu escritura es falso! Avisan a la guardia.")
				return true
			elif can_loan and buy_house_loan(vm, id, inv):
				if player.has_method("show_hint"):
					player.show_hint("🏦🏡 Encargaste tu casa en el solar %s con hipoteca (-15 Oro de entrada, 3 Oro/día)." % id)
				return true
		# 2. Dentro de una casa construida tuya: dormir en tu cama o estudiar en tu estantería
		if str(st.get("status", "")) == "built" and str(st.get("payer", "")) == "player":
			var c: Vector2 = Solar.a_mundo(id, VillageLots.lot_def(id)["center"])
			if pos.distance_to(c) <= 46.0:
				var hs: Dictionary = state(vm)
				var up: Dictionary = st.get("upgrades", {})
				# Dormir en tu cama es como la de la posada pero gratis: el tiempo pasa hasta la mañana
				var h_now: int = int(WorldClock.current_hour) if WorldClock != null else 22
				if h_now >= 6 and h_now < 20:
					if player.has_method("show_hint"):
						player.show_hint("🛏️ Aún es de día. Tu cama te espera a partir de las 20:00.")
					return true
				if bool(up.get("bookshelf", false)) and int(hs.get("last_study_day", -99)) != today():
					hs["last_study_day"] = today()
					if player.has_method("add_skill_xp"):
						player.call("add_skill_xp", "crafting", 15)
				var hearth_ok: bool = rest_by_hearth(vm, player)
				var surv = player.get_node_or_null("SurvivalComponent")
				if surv != null:
					if surv.has_method("restore_sleep"):
						surv.restore_sleep(100.0)
					surv.current_hygiene = 100.0
				var stam = player.get_node_or_null("StaminaComponent")
				if stam != null:
					stam.current_stamina = stam.max_stamina
					stam.stamina_changed.emit(stam.current_stamina, stam.max_stamina)
				if WorldClock != null and WorldClock.has_method("sleep_until_morning"):
					WorldClock.sleep_until_morning()
				if player.has_method("show_hint"):
					var bonus_txt: String = " (+estudio en tu estantería)" if bool(up.get("bookshelf", false)) else ""
					if hearth_ok:
						bonus_txt += " (+calor del hogar)"
					player.show_hint("🛌🏡 Dormiste en tu propia casa hasta la mañana%s." % bonus_txt)
				return true
	return false

# ==============================================================================
# Paso diario: pareja en casa, huerto, banco de trabajo y rentas comerciales
# ==============================================================================
static func daily(vm) -> void:
	var hs: Dictionary = state(vm)
	var pl = VillageNeeds.player_of(vm)
	var inv = pl.get("inventory") if pl != null else null
	var p_lots: Array[String] = player_lots(vm, true)
	if not p_lots.is_empty() and inv != null:
		# P6.4: Tu pareja que vive contigo aporta 5 de oro al día al hogar
		var pk: String = str(hs.get("partner_key", ""))
		if pk != "":
			var partner = vm._get_npcs_by_person_key().get(pk, null)
			if partner != null and not partner.is_dead and int(partner.personal_gold) >= 12:
				partner.personal_gold -= 5
				inv.add_gold(5)
		# P6.7 (FIS-P1): el banco de trabajo no mete objetos solos a medianoche en la mochila; se usa con [E] en casa.
		# Tanda 5 (21): Intrusos nocturnos o enemigos intentando forzar tu puerta si no tienes cerradura reforzada
		# Un intruso sin escarmentar en 2 días se lleva algo del escondite y deja sitio a otro
		var ia_old: Dictionary = hs["intruder_attempt"]
		if not ia_old.is_empty() and (bool(ia_old.get("repelled", false)) or today() - int(ia_old.get("day", today())) >= 2):
			if not bool(ia_old.get("repelled", false)):
				var stolen: int = mini(10, int(hs.get("stash_gold", 0)))
				hs["stash_gold"] = int(hs.get("stash_gold", 0)) - stolen
				var thief_n = vm._get_npcs_by_person_key().get(str(ia_old.get("intruder_key", "")), null)
				if thief_n != null and not thief_n.is_dead:
					thief_n.personal_gold += stolen
				VillageChronicle.add(vm, "intruder_stole", "Alguien forzó tu puerta de noche%s" % (" y se llevó %d de oro de tu escondite" % stolen if stolen > 0 else ""), false)
			hs["intruder_attempt"] = {}
		if (hs["intruder_attempt"] as Dictionary).is_empty() and not has_upgrade(vm, "strong_lock") and randf() < 0.20:
			for n in VillageNeeds.living(vm):
				if int(n.trade_role) != int(VillageNPC.TradeRole.CHILD) and (int(n.affinity) <= -35 or TraitCatalog.npc_tendency(n, "malice") >= 0.4):
					hs["intruder_attempt"] = {"intruder_key": n.get_person_key(), "intruder_name": n.npc_name, "day": today(), "repelled": false}
					VillageChronicle.add(vm, "intruder_try", "Anoche alguien intentó forzar la puerta de tu casa; quien fuera te guarda rencor", false)
					break
	# P6.10 / P5: la renta del sábado (15 % de la caja) ya no salta sola a tu mochila: la aparta
	# `VillageCollections.on_saturday` y la recoges en el propio local.
	# Bloque PG / Bloque P1: Las ventas de tu tienda ocurren durante el día cuando el dependiente atiende el mostrador
	# y los clientes se acercan andando a comprar; a medianoche se paga el jornal al dependiente y la caja sin recoger corre riesgo de robo nocturno.
	if has_player_shop(vm):
		var ps: Dictionary = hs["player_shop"]
		var ck: String = str(ps.get("clerk_key", ""))
		pay_player_shop_clerk(vm)
		if int(ps.get("till_gold", 0)) > 1 and int(ps.get("till_since_day", -99)) < today():
			shop_night_theft(vm, ps, SHOP_THEFT_CHANCE_CLERK if ck != "" else SHOP_THEFT_CHANCE)
		if int(ps.get("ad_days", 0)) > 0:
			ps["ad_days"] = maxi(0, int(ps["ad_days"]) - 1)
		ps["buyers_today"] = 0
	if "VillageCulture" in vm and vm.VillageCulture != null:
		vm.VillageCulture.cart_night_theft(vm, vm.VillageCulture.CART_THEFT_CHANCE)
	# Bloque PI.1: Crecimiento diario del ganado del Rancho (con renovación cuando madura) y de tus propios animales de corral
	var r_herd: Array = hs["ranch_herd"]
	var new_r_chicks: Array = []
	var culled_r: Array = []
	var rancher = vm.trade_npcs.get(int(VillageNPC.TradeRole.RANCHER), null) if "trade_npcs" in vm else null
	for ra in r_herd:
		if not (ra is Dictionary):
			continue
		var old_st: String = str(ra.get("stage", "chick"))
		ra["age_days"] = int(ra.get("age_days", 0)) + 1
		ra["stage"] = animal_stage_for_days(int(ra["age_days"]))
		if old_st != "adult" and str(ra["stage"]) == "adult":
			if rancher != null and is_instance_valid(rancher) and not rancher.is_dead:
				rancher.shop_stock["wool"] = int(rancher.shop_stock.get("wool", 0)) + 1
				rancher.shop_stock["raw_meat"] = int(rancher.shop_stock.get("raw_meat", 0)) + 1
				rancher._sync_shop_stock_to_vm()
			if r_herd.size() + new_r_chicks.size() < 8:
				new_r_chicks.append({"species": str(ra.get("species", "sheep")), "stage": "chick", "age_days": 0})
		elif int(ra["age_days"]) >= ADULT_ANIMAL_DAYS + 3 and r_herd.size() - culled_r.size() >= 2:
			culled_r.append(ra)
			if rancher != null and is_instance_valid(rancher) and not rancher.is_dead:
				rancher.shop_stock["raw_meat"] = int(rancher.shop_stock.get("raw_meat", 0)) + 1
				rancher.shop_stock["wool"] = int(rancher.shop_stock.get("wool", 0)) + 1
				rancher._sync_shop_stock_to_vm()
				var butcher = vm.trade_npcs.get(int(VillageNPC.TradeRole.BUTCHER), null) if "trade_npcs" in vm else null
				if butcher != null and is_instance_valid(butcher) and not butcher.is_dead and int(butcher.personal_gold) >= 12:
					butcher.personal_gold -= 8
					rancher.personal_gold += 8
			const NEXT_SPECIES: Dictionary = {
				"sheep": "rooster", "rooster": "cow", "cow": "donkey",
				"donkey": "sheep", "bull": "horse", "horse": "bull",
			}
			var next_sp: String = str(NEXT_SPECIES.get(str(ra.get("species", "sheep")), "sheep"))
			new_r_chicks.append({"species": next_sp, "stage": "chick", "age_days": 0})
			VillageChronicle.add(vm, "animal_bred", "El rancho vendió una res madura y crió una nueva camada (%s)" % next_sp, false)
	for c_ra in culled_r:
		r_herd.erase(c_ra)
	for nc in new_r_chicks:
		if r_herd.size() < 10:
			r_herd.append(nc)
	sync_livestock(vm)
	sync_home_props(vm)

# ==============================================================================
# Diálogos con el carpintero, pareja, inquilinos y vecinos
# ==============================================================================
static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null or npc == null or int(npc.trade_role) == int(VillageNPC.TradeRole.CHILD):
		return
	var hs: Dictionary = state(vm)
	var opts: Array = []
	var free: Array = VillageLots.free_lots(vm, "house")
	var p_lot: String = primary_player_lot(vm)
	var is_carp: bool = int(npc.trade_role) == int(VillageNPC.TradeRole.CARPENTER)

	# Con el carpintero: comprar solar, mejoras, huerto, escondite o casas embargadas
	if is_carp:
		if not free.is_empty() and VillageLots.active_site(vm) == "":
			var lid: String = VillageLots.pick_house_lot(vm, "mid")
			opts.append({"label": "🏡💰 Encargar %s propia en el solar %s al contado (-%d Oro)" % [str(VillageLots.HOUSE_PLOTS[VillageLots.plot_of(lid)]["word"]).to_lower(), lid, VillageLots.house_cost(lid)], "next": "END", "action": "housing_buy_cash:" + lid})
			opts.append({"label": "🏦🏡 Encargar casa en el solar %s con hipoteca (-15 Oro entrada, 3/día)" % lid, "next": "END", "action": "housing_buy_loan:" + lid})
		if p_lot != "" and str(VillageLots.lot(vm, p_lot).get("status", "")) == "built":
			var st: Dictionary = VillageLots.lot(vm, p_lot)
			var up: Dictionary = st.get("upgrades", {})
			for u in [["bookshelf", "📚 Estantería de estudio (+XP diaria)"], ["workbench", "⚗️ Banco de trabajo y alquimia"], ["oak_bed", "🛏️ Cama de roble macizo"], ["strong_lock", "🔒 Cerradura reforzada antirrobo"], ["hidden_cellar", "🕳️🕯️ Sótano secreto para esconderte o destilar"], ["hearth", "🔥🪵 Hogar de leña caldeado (+salud y humor)"], ["upper_floor", "🪜🏠 Altillo / Primer Piso con escalera (nivel +1)"]]:
				if not bool(up.get(u[0], false)):
					opts.append({"label": "%s (-%d Oro)" % [u[1], int(UPGRADE_COSTS[u[0]])], "next": "END", "action": "housing_upgrade:" + u[0]})
			if not bool(hs.get("has_stash", false)):
				opts.append({"label": "🪵🗝️ Construir escondite secreto bajo las tablas (-%d Oro)" % STASH_BUILD_COST, "next": "END", "action": "housing_build_stash"})
			if not has_player_shop(vm):
				opts.append({"label": "🏪🔨 Acondicionar mostrador y fundar tu propio negocio en el solar %s (-%d Oro)" % [p_lot, FOUND_SHOP_COST], "next": "END", "action": "housing_found_shop:" + p_lot})
			if str(hs.get("toby_lot", "")) != p_lot:
				opts.append({"label": "🐕🥣 Trasladar a Toby y su comedero al patio de tu casa en el solar %s" % p_lot, "next": "END", "action": "housing_move_toby:" + p_lot})
		# P6.5: Comprar una casa embargada al pueblo o al noble para alquilarla
		for l in VillageLots.lots():
			var id2: String = str(l["id"])
			var st2: Dictionary = VillageLots.lot(vm, id2)
			if str(st2.get("status", "")) == "built" and str(st2.get("kind", "")) == "house" and str(st2.get("payer", "")) in ["town", npc.get_person_key()]:
				opts.append({"label": "🏘️🔑 Comprar la casa del solar %s para alquilarla (-%d Oro)" % [id2, FORECLOSED_COST], "next": "END", "action": "housing_buy_foreclosed:" + id2})
				break

	# Tanda 5 (21): Defender tu puerta y escarmentar a un intruso nocturno
	# Solo hablando con el propio intruso (lo descubres al ver tu puerta forzada y preguntar por ahí)
	if not (hs["intruder_attempt"] as Dictionary).is_empty() and not bool(hs["intruder_attempt"].get("repelled", false)) and str(hs["intruder_attempt"].get("intruder_key", "")) == npc.get_person_key():
		opts.append({"label": "🚪🛡️ Plantarle cara por intentar forzar tu puerta anoche (hasta 15 Oro)", "next": "END", "action": "housing_repel_intruder"})

	# Tanda 5 (22): Vender una casa tuya reformada al precio del barrio y sus mejoras
	if is_carp or vm.VillageTown.is_mayor(vm, npc):
		for lid3 in player_lots(vm, true):
			opts.append({"label": "🏘️📈 Vender tu casa del solar %s (+%d Oro según atractivo y mejoras)" % [lid3, house_sale_price(vm, lid3)], "next": "END", "action": "housing_sell_house:" + lid3})

	# (FIS-P1: subir al altillo +1, bajar al sótano -1, esconderse en el sótano y meter/sacar oro del escondite bajo las tablas
	# se hacen físicamente pulsando [E] en la escalera/trampilla y en las tablas sueltas dentro de tu casa, no hablando con vecinos).

	# P6.4: Invitar a tu pareja o gran amistad soltera a mudarse contigo
	if p_lot != "" and str(hs.get("partner_key", "")) == "" and int(npc.affinity) >= 65 and npc.person_profile != null and str(npc.person_profile.partner_id) == "":
		opts.append({"label": "🏡💑 Invitarle a mudarse a vivir contigo en tu casa", "next": "END", "action": "housing_move_in"})

	# P6.6: Trato con tu inquilino si vive en una casa tuya
	var t_lot: String = tenant_lot_of(vm, npc)
	if t_lot != "":
		opts.append({"label": "💰📈 Subirle el alquiler de la casa a 5 de oro por noche", "next": "END", "action": "housing_rent_high:" + t_lot})
		opts.append({"label": "🤝🏠 Perdonarle la cuota a cambio de lealtad y su voto", "next": "END", "action": "housing_rent_forgive:" + t_lot})
		opts.append({"label": "📦🚪 Desahuciar al inquilino para dejar libre tu casa", "next": "END", "action": "housing_evict:" + t_lot})

	# P6.8 / P4.1: Invitar a cenar a tu casa esta noche (a las 20:00, sin cobro en diálogo; la comida sale de la mesa o del cáterin)
	if p_lot != "" and str(VillageLots.lot(vm, p_lot).get("status", "")) == "built" and today() - int(hs.get("last_dinner_day", -99)) >= 3 and int(npc.affinity) >= 10 and not has_active_gathering(vm):
		opts.append({"label": "🍷🍽️ Invitarle a cenar a tu casa esta noche (a las 20:00)", "next": "END", "action": "housing_dinner"})
	# Tanda 4 (20) / P4.2: Invitar uno a uno a los vecinos a la fiesta convocada hoy en la mesa de tu casa (hasta 6)
	var g_cur: Dictionary = hs.get("gathering", {})
	if str(g_cur.get("kind", "")) == "party" and not bool(g_cur.get("dispatched", false)) and (g_cur.get("guests", []) as Array).size() < 6:
		var pk_inv: String = npc.get_person_key()
		if not (pk_inv in (g_cur.get("guests", []) as Array)) and not (pk_inv in (g_cur.get("declined", []) as Array)):
			opts.append({"label": "🎉🍷 Invitarle a tu fiesta de esta noche", "next": "END", "action": "housing_party_invite"})
	# P4 Opción B: Contratar cáterin con la posadera (o panadera si no hay posadera) para la cena o fiesta de hoy
	if npc == caterer_npc_of(vm) and has_active_gathering(vm) and str(g_cur.get("place", "")) == "home" and not bool(g_cur.get("dispatched", false)) and not bool(g_cur.get("catering_hired", false)):
		var g_cnt: int = (g_cur.get("guests", []) as Array).size()
		if g_cnt > 0:
			opts.append({"label": "🍲🏠 Contratar a la posada para cocinar en tu casa (−%d oro)" % (CATERING_COST_PER_GUEST * g_cnt), "next": "END", "action": "housing_catering"})

	# P6.10: Comprar la escritura del local comercial de un artesano
	if npc.trade_role in VillageNPC.SHOP_ROLES and not (hs["commercial_deeds"] as Dictionary).has(str(int(npc.trade_role))):
		opts.append({"label": "🏪📜 Comprar la propiedad de su local comercial para cobrar renta semanal (-%d Oro)" % COMMERCIAL_DEED_COST, "next": "END", "action": "housing_deed:%d" % int(npc.trade_role)})

	# Bloque PG / Bloque P1: Pregonar y contratar dependiente siguen en charla (tratos con personas);
	# reponer mercancía y recoger la caja se hacen físicamente con [E] en el mostrador de tu solar (`player_shop_counter`).
	if has_player_shop(vm):
		var ps: Dictionary = hs["player_shop"]
		if today() - int(ps.get("last_ad_day", -99)) >= ADVERTISE_COOLDOWN_DAYS:
			opts.append({"label": "📣🪧 Hacer publicidad de tu negocio por el pueblo (-%d Oro, atrae más clientes 3 días)" % ADVERTISE_COST, "next": "END", "action": "housing_advertise_shop"})
		if str(ps.get("clerk_key", "")) == "" and int(npc.trade_role) == int(VillageNPC.TradeRole.UNEMPLOYED) and not VillageNeeds.is_outsider(npc):
			opts.append({"label": "🤝🏪 Contratarle como dependiente de tu negocio (%d Oro/día de la caja)" % CLERK_WAGE, "next": "END", "action": "housing_hire_clerk"})

	if not opts.is_empty():
		opts.append({"label": "⬅️ Volver", "next": "start"})
		diag["housing_menu"] = {"text": "🏡 Tu hogar, propiedades, inquilinos y alquileres:", "choices": opts}
		ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🏡 Casa propia, alquileres y propiedades…", "next": "housing_menu"})

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	var hs: Dictionary = state(vm)
	var arg: String = action_id.get_slice(":", 1)

	if action_id.begins_with("housing_buy_cash:"):
		var wanted_before: int = int(vm.wanted_level)
		if buy_house_cash(vm, arg, inv):
			npc._spawn_floating_text("🏡🔨 «¡Trato hecho! Hoy mismo empiezo a levantar tu casa en %s.»" % arg, Color.SPRING_GREEN, -46.0)
		elif int(vm.wanted_level) > wanted_before:
			# Descubrieron la escritura falsa (no es falta de oro).
			npc.modify_affinity(-15)
			npc._spawn_floating_text("🚨📜 «¡Este sello municipal es falso! ¡Guardias!»", Color.ORANGE_RED, -46.0)
		else:
			npc._spawn_floating_text("Necesitas %d de oro y que no haya otra obra en marcha" % VillageLots.house_cost(arg), Color.ORANGE_RED, -44.0)

	elif action_id.begins_with("housing_buy_loan:"):
		if buy_house_loan(vm, arg, inv):
			npc._spawn_floating_text("🏦🏡 «¡Hipoteca aprobada! Empezaré tu casa en el solar %s.»" % arg, Color.SPRING_GREEN, -46.0)
		else:
			npc._spawn_floating_text("Necesitas 15 de oro de entrada y un prestamista disponible", Color.ORANGE_RED, -44.0)

	elif action_id.begins_with("housing_upgrade:"):
		var cost: int = int(UPGRADE_COSTS.get(arg, 30))
		if inv == null or int(inv.gold) < cost:
			npc._spawn_floating_text("Necesitas %d de oro" % cost, Color.ORANGE_RED, -44.0)
			return
		var p_lot: String = primary_player_lot(vm)
		if p_lot == "":
			return
		inv.add_gold(-cost)
		npc.personal_gold += cost
		var st: Dictionary = VillageLots.lot(vm, p_lot)
		if not st.has("upgrades") or not (st["upgrades"] is Dictionary):
			st["upgrades"] = {}
		st["upgrades"][arg] = true
		if arg == "upper_floor":
			st["beds"] = VillageLots._house_beds(p_lot, true)
		sync_home_props(vm)
		VillageChronicle.add(vm, "home_upgraded", "Mejoraste tu casa con: %s" % arg, true)
		_notify_player(vm, npc, "🔨🏡 «¡Mejora instalada en tu casa!»", Color.SPRING_GREEN)

	elif action_id.begins_with("housing_move_toby:"):
		if move_toby_to_lot(vm, arg):
			_notify_player(vm, npc, "🐕🥣 Toby y su comedero ahora están junto a tu casa en el solar %s." % (arg if not arg.is_empty() else primary_player_lot(vm)), Color.SPRING_GREEN)
		else:
			_notify_player(vm, npc, "Necesitas tener tu casa ya construida en el pueblo", Color.ORANGE_RED)

	elif action_id == "housing_build_stash":
		if inv == null or int(inv.gold) < STASH_BUILD_COST:
			_notify_player(vm, npc, "Necesitas %d de oro" % STASH_BUILD_COST, Color.ORANGE_RED)
			return
		inv.add_gold(-STASH_BUILD_COST)
		if npc != null and "personal_gold" in npc:
			npc.personal_gold += STASH_BUILD_COST
		hs["has_stash"] = true
		sync_home_props(vm)
		_notify_player(vm, npc, "🪵🗝️ «Nadie encontrará jamás ese hueco bajo las tablas de tu casa.»", Color.SPRING_GREEN)

	elif action_id == "housing_stash_put":
		if inv == null or int(inv.gold) < 25:
			_notify_player(vm, npc, "Necesitas 25 de oro en la bolsa", Color.ORANGE_RED)
			return
		inv.add_gold(-25)
		hs["stash_gold"] = int(hs.get("stash_gold", 0)) + 25
		_notify_player(vm, npc, "🗝️ Guardaste 25 de oro bajo las tablas (Total oculto: %d)" % int(hs["stash_gold"]), Color.GOLD)

	elif action_id == "housing_stash_take":
		var g: int = int(hs.get("stash_gold", 0))
		hs["stash_gold"] = 0
		if inv != null and g > 0:
			inv.add_gold(g)
		_notify_player(vm, npc, "🗝️ Recuperaste %d de oro de tu escondite secreto" % g, Color.GOLD)

	elif action_id == "housing_craft_poultice":
		craft_home_poultice(vm, primary_player_lot(vm), inv, VillageNeeds.player_of(vm), npc)

	elif action_id.begins_with("housing_buy_foreclosed:"):
		if inv == null or int(inv.gold) < FORECLOSED_COST:
			_notify_player(vm, npc, "Necesitas %d de oro" % FORECLOSED_COST, Color.ORANGE_RED)
			return
		inv.add_gold(-FORECLOSED_COST)
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + FORECLOSED_COST
		var st: Dictionary = VillageLots.lot(vm, arg)
		st["payer"] = "player"
		sync_home_props(vm)
		VillageChronicle.add(vm, "landlord_buy", "Compraste la casa del solar %s para alquilarla a vecinos" % arg, true)
		npc._spawn_floating_text("🏘️🔑 «La escritura del solar %s es tuya. Cobrarás tú los alquileres.»" % arg, Color.SPRING_GREEN, -46.0)

	elif action_id == "housing_move_in":
		if not move_into_player_home(vm, npc, 0):
			return
		hs["partner_key"] = npc.get_person_key()
		npc.modify_affinity(20)
		VillageChronicle.add(vm, "partner_moved_in", "%s se mudó a vivir contigo a tu casa" % npc.npc_name, true)
		npc._spawn_floating_text("🏡💑 «¡Me mudo contigo hoy mismo!»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("housing_rent_high:"):
		hs["rent_rates"][arg] = 5
		npc.modify_affinity(-8)
		npc._spawn_floating_text("😠 «¿5 de oro por noche? Es un abuso, pero lo pagaré...»", Color.ORANGE, -46.0)

	elif action_id.begins_with("housing_rent_forgive:"):
		hs["rent_rates"][arg] = 0
		npc.modify_affinity(16)
		vm.VillageTown.state(vm)["pledges"][npc.get_person_key()] = "player"
		npc._spawn_floating_text("🤝🏠 «¡Mil gracias por perdonarme el alquiler! Tienes mi lealtad.»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("housing_evict:"):
		var st: Dictionary = VillageLots.lot(vm, arg)
		(st.get("residents", []) as Array).erase(npc.get_person_key())
		npc.lodging = ""
		vm.evict_npc_to_vagrant_camp(npc, "desahuciado por su casero")
		npc.modify_affinity(-20)
		VillageChronicle.add(vm, "tenant_evicted", "Desahuciaste a %s de tu casa en el solar %s" % [npc.npc_name, arg], true)
		npc._spawn_floating_text("📦😠 «¡Me dejas en la calle!»", Color.ORANGE_RED, -46.0)

	elif action_id == "housing_dinner":
		if npc == null:
			return
		if has_active_gathering(vm):
			npc._spawn_floating_text("«Ya tienes otra cena o reunión prevista.»", Color.ORANGE_RED, -44.0)
			return
		if schedule_dinner(vm, npc):
			npc._spawn_floating_text("🍷🍽️ «¡Con mucho gusto! A las 20:00 estaré en tu casa para cenar.»", Color.SPRING_GREEN, -46.0)
		else:
			npc._spawn_floating_text("«Hoy no puedo, tengo quehaceres esta noche.»", Color.ORANGE_RED, -44.0)

	elif action_id == "housing_party_call":
		if convoke_house_party(vm):
			_notify_player(vm, npc, "🎉🍷 Fiesta convocada para esta noche a las 21:00. Invita a los vecinos hablando con ellos (máx. 6) y prepara comida.", Color.SPRING_GREEN)
		else:
			_notify_player(vm, npc, "Ya tienes otra reunión activa o ya convocaste una fiesta hoy", Color.ORANGE_RED)

	elif action_id == "housing_party_invite":
		if npc == null:
			return
		if invite_to_house_party(vm, npc):
			npc._spawn_floating_text("🎉🍻 «¡Cuenta conmigo! A las 21:00 me pasaré por tu casa.»", Color.SPRING_GREEN, -46.0)
		else:
			npc._spawn_floating_text("«Esta noche no me viene bien ir a la fiesta.»", Color.ORANGE_RED, -44.0)

	elif action_id == "housing_table_put_food":
		var put_cnt: int = put_food_on_home_table(vm, inv)
		var g_f: Dictionary = hs.get("gathering", {})
		var need_f: int = maxi(2, (g_f.get("guests", []) as Array).size() * 2)
		var cur_f: int = int(hs.get("table_rations", 0))
		if put_cnt > 0:
			_notify_player(vm, npc, "🍞🍲 Pusiste %d ración(es) en la mesa (%d/%d raciones)" % [put_cnt, cur_f, need_f], Color.SPRING_GREEN)
		elif cur_f >= need_f:
			_notify_player(vm, npc, "La mesa ya tiene comida suficiente (%d/%d raciones)" % [cur_f, need_f], Color.GOLD)
		else:
			_notify_player(vm, npc, "No llevas comida en la mochila para poner en la mesa", Color.ORANGE_RED)

	elif action_id == "housing_catering":
		var g_cat: Dictionary = hs.get("gathering", {})
		var g_cnt_c: int = (g_cat.get("guests", []) as Array).size()
		if not has_active_gathering(vm) or str(g_cat.get("place", "")) != "home" or g_cnt_c <= 0 or bool(g_cat.get("catering_hired", false)):
			return
		var cat_cost: int = CATERING_COST_PER_GUEST * g_cnt_c
		if inv == null or int(inv.gold) < cat_cost:
			_notify_player(vm, npc, "Necesitas %d de oro para contratar el cáterin de la posada" % cat_cost, Color.ORANGE_RED)
			return
		if not press_twice(vm, "housing_catering"):
			_notify_player(vm, npc, "Pulsa [E] otra vez para confirmar el cáterin en tu casa (−%d oro)" % cat_cost, Color.GOLD)
			return
		if hire_catering(vm, inv):
			_notify_player(vm, npc, "🍲🏠 «¡Trato hecho! Iré a tu casa 1 h antes para dejar las raciones listas en tu mesa.»", Color.SPRING_GREEN)

	elif action_id == "housing_party":
		if inv == null or int(inv.gold) < 20:
			npc._spawn_floating_text("Necesitas 20 de oro para la comida y bebida de la fiesta", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-20)
		if vm.shop_businesses.has(int(VillageNPC.TradeRole.INNKEEPER)):
			vm.shop_businesses[int(VillageNPC.TradeRole.INNKEEPER)]["vault_gold"] = int(vm.shop_businesses[int(VillageNPC.TradeRole.INNKEEPER)].get("vault_gold", 0)) + 20
		else:
			vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + 20
		hs["last_party_day"] = today()
		var guests: Array = [npc]
		for o in VillageNeeds.living(vm):
			if o != npc and int(o.trade_role) != int(VillageNPC.TradeRole.CHILD) and int(o.affinity) >= 10 and guests.size() < 4:
				guests.append(o)
		for g in guests:
			g.modify_affinity(10)
			g.add_thought("Fiesta memorable en casa del forastero (+10)", 10.0)
		for i in range(guests.size()):
			for j in range(i + 1, guests.size()):
				guests[i].modify_npc_relationship(guests[j], 8, "Brindamos juntos en la fiesta del forastero", true)
				guests[j].modify_npc_relationship(guests[i], 8, "Brindamos juntos en la fiesta del forastero", true)
		VillageChronicle.add(vm, "house_party", "Celebraste una fiesta en tu casa con %d vecinos del valle" % guests.size(), true)
		npc._spawn_floating_text("🎉🍻 «¡La mejor fiesta del valle! Todos se han reconciliado y brindan por ti.»", Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("housing_deed:"):
		var has_forged_deed: bool = "VillageUnderworld" in vm and vm.VillageUnderworld != null and bool(vm.VillageUnderworld.state(vm).get("forged_deed", false))
		var d_cost: int = COMMERCIAL_DEED_COST - (40 if has_forged_deed else 0)
		if inv == null or int(inv.gold) < d_cost:
			npc._spawn_floating_text("Necesitas %d de oro para comprar el local" % d_cost, Color.ORANGE_RED, -44.0)
			return
		if has_forged_deed:
			vm.VillageUnderworld.state(vm)["forged_deed"] = false
			if randf() < 0.30:
				vm.wanted_level = int(vm.wanted_level) + 1
				npc.modify_affinity(-15)
				VillageChronicle.add(vm, "forged_deed_caught", "%s descubrió tu escritura municipal falsificada y avisó a la guardia" % npc.npc_name, true)
				npc._spawn_floating_text("🚨📜 «¡Este sello municipal es falso! ¡Guardias!»", Color.ORANGE_RED, -46.0)
				return
		inv.add_gold(-d_cost)
		npc.personal_gold += d_cost
		hs["commercial_deeds"][arg] = true
		npc.modify_affinity(12)
		VillageChronicle.add(vm, "commercial_deed", "Compraste la propiedad del local de %s; cobrarás renta cada sábado" % npc.npc_name, true)
		npc._spawn_floating_text("🏪📜 «El local ahora es tuyo. Te pagaré el 15 %% de la caja cada sábado.»", Color.GOLD, -46.0)

	elif action_id == "housing_repel_intruder":
		var ia: Dictionary = hs.get("intruder_attempt", {})
		if ia.is_empty() or bool(ia.get("repelled", false)):
			return
		ia["repelled"] = true
		var intruder = vm._get_npcs_by_person_key().get(str(ia.get("intruder_key", "")), null)
		var paid: int = vm.VillageClans.pay_from_pocket(intruder, 15, inv) if intruder != null else 0
		if intruder != null:
			intruder.modify_affinity(-10)
			intruder.add_thought("Me pillaron intentando forzar la puerta del forastero (-10)", -10.0)
		VillageChronicle.add(vm, "intruder_repelled", "Escarmentaste a %s cuando intentaba forzar la puerta de tu casa (+%d Oro)" % [str(ia.get("intruder_name", "")), paid], true)
		npc._spawn_floating_text("🚪🛡️ «¡Le diste una buena lección a %s en tu puerta! (+%d Oro)»" % [str(ia.get("intruder_name", "")), paid], Color.SPRING_GREEN, -46.0)

	elif action_id.begins_with("housing_sell_house:"):
		var st_sell: Dictionary = VillageLots.lot(vm, arg)
		if str(st_sell.get("payer", "")) != "player":
			return
		var my_key_set: Array = (st_sell.get("residents", []) as Array).duplicate()
		if not my_key_set.is_empty():
			npc._spawn_floating_text("«Primero tiene que mudarse quien vive en esa casa.»", Color.ORANGE_RED, -44.0)
			return
		var price: int = house_sale_price(vm, arg)
		# Si queda hipoteca, la venta primero salda la deuda con quien prestó
		var owed: int = int((st_sell.get("loan", {}) as Dictionary).get("owed", 0))
		var buyer = null
		for n in VillageNeeds.living(vm):
			if int(n.trade_role) != int(VillageNPC.TradeRole.CHILD) and not VillageNeeds.is_outsider(n) and not str(n.lodging).begins_with("house:") and int(n.personal_gold) >= price:
				buyer = n
				break
		var got: int = 0
		if buyer != null:
			buyer.personal_gold -= price
			got = price
		else:
			var t_gold: int = int(vm.town_state.get("treasury", 0))
			got = mini(price, maxi(0, t_gold))
			vm.town_state["treasury"] = t_gold - got
		if got < owed:
			# No llega para saldar la hipoteca: se deshace la venta
			if buyer != null:
				buyer.personal_gold += got
			else:
				vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + got
			npc._spawn_floating_text("«Nadie paga lo bastante para cubrir tu hipoteca (%d de oro).»" % owed, Color.ORANGE_RED, -44.0)
			return
		if owed > 0:
			VillageLoans._credit(vm, str(st_sell["loan"].get("lender", "")), owed)
		st_sell.erase("loan")
		var paid: int = got - owed
		if inv != null and paid > 0:
			inv.add_gold(paid)
		if buyer != null:
			st_sell["payer"] = buyer.get_person_key()
			buyer.lodging = "house:" + arg
			var beds_s: Array = VillageLots._house_beds(arg)
			if not beds_s.is_empty():
				buyer.bed_position = Solar.a_mundo(arg, beds_s[0])
			buyer.home_table_pos = Solar.a_mundo(arg, VillageLots.lot_def(arg)["center"] + Vector2(0, -2))
			VillageLots.add_resident(vm, arg, buyer.get_person_key())
		else:
			st_sell["payer"] = "town"
		sync_home_props(vm)
		VillageChronicle.add(vm, "house_sold", "Vendiste tu casa del solar %s por %d de oro%s" % [arg, got, (" (%d para saldar la hipoteca)" % owed if owed > 0 else "")], true)
		_notify_player(vm, npc, "🏘️💰 «¡Casa del solar %s vendida! Te quedan %d de oro.»" % [arg, paid], Color.GOLD)

	elif action_id == "housing_hide_cellar":
		if not has_upgrade(vm, "hidden_cellar") or int(vm.wanted_level) != 1 or int(vm.player_murder_warrants_count) > 0 or not can_purge_wanted(vm):
			return
		mark_wanted_purge(vm)
		vm.wanted_level = 0
		if player_near_home(vm):
			vm.set_player_elevation_level(-1)
		VillageChronicle.add(vm, "hid_in_cellar", "Te escondiste en el sótano secreto de tu casa hasta que la guardia dejó de buscarte", true)
		_notify_player(vm, npc, "🕳️🤫 «La patrulla pasó de largo sin encontrarte en tu sótano secreto (nivel -1).»", Color.SPRING_GREEN)

	elif action_id.begins_with("housing_change_level:"):
		var target_lvl: int = int(arg)
		if target_lvl == 1 and not has_upgrade(vm, "upper_floor"):
			return
		if target_lvl == -1 and not has_upgrade(vm, "hidden_cellar"):
			return
		if target_lvl != 0 and not player_near_home(vm):
			_notify_player(vm, npc, "Solo puedes cambiar de piso dentro de tu casa", Color.ORANGE_RED)
			return
		vm.set_player_elevation_level(target_lvl)
		if "VillageUnderworld" in vm and vm.VillageUnderworld != null:
			vm.VillageUnderworld.sewers_state(vm)["current_loc"] = ""
		var lvl_lbl: String = "el primer piso (nivel +1)" if target_lvl == 1 else ("el sótano (nivel -1)" if target_lvl == -1 else "la planta de calle (nivel 0)")
		_notify_player(vm, npc, "🪜🏠 Te desplazaste a %s" % lvl_lbl, Color.SPRING_GREEN)

	elif action_id.begins_with("housing_found_shop:"):
		if found_player_shop(vm, arg, inv, npc):
			npc._spawn_floating_text("🏪🔨 «¡Ya tienes mostrador y letrero! Tu negocio está abierto en el solar %s.»" % arg, Color.SPRING_GREEN, -46.0)
		else:
			npc._spawn_floating_text("Necesitas %d de oro y una casa construida tuya" % FOUND_SHOP_COST, Color.ORANGE_RED, -44.0)

	elif action_id == "housing_stock_shop":
		var added: int = stock_player_shop(vm, inv)
		if added > 0:
			_notify_player(vm, npc, "📦🏪 Colocaste %d artículo(s) en el mostrador (Stock: %d)" % [added, int(hs["player_shop"].get("stock", 0))], Color.SPRING_GREEN)
		else:
			_notify_player(vm, npc, "No llevas mercancía vendible en la mochila (pan, carne, ropa, madera, hierro...)", Color.ORANGE_RED)

	elif action_id == "housing_advertise_shop":
		if advertise_player_shop(vm, inv):
			_notify_player(vm, npc, "📣🪧 «¡Hecho! Pregonaré tu negocio por la plaza durante 3 días.»", Color.SPRING_GREEN)
		else:
			_notify_player(vm, npc, "Necesitas %d de oro o esperar a que termine la campaña anterior" % ADVERTISE_COST, Color.ORANGE_RED)

	elif action_id == "housing_collect_shop":
		var gain: int = collect_player_shop_till(vm, inv)
		if gain > 0:
			_notify_player(vm, npc, "💰🏪 Recogiste %d de oro de la caja de tu tienda" % gain, Color.GOLD)
		else:
			_notify_player(vm, npc, "La caja del mostrador está vacía ahora mismo", Color.ORANGE)

	elif action_id == "housing_hire_clerk":
		if not has_player_shop(vm) or npc == null or int(npc.trade_role) != int(VillageNPC.TradeRole.UNEMPLOYED):
			return
		hs["player_shop"]["clerk_key"] = npc.get_person_key()
		if "VillageWork" in vm and vm.VillageWork != null:
			vm.VillageWork._release(npc)
		var cur_h: int = int(WorldClock.current_hour) if WorldClock != null else 10
		if is_player_shop_open_hour(cur_h) and not npc.is_dead and not npc.is_downed and not npc.is_sleeping:
			npc.start_errand("player_shop_clerk", _en_tienda(vm, player_shop_clerk_pos(vm)))
		npc.modify_affinity(12)
		npc.add_thought("Tengo trabajo atendiendo el mostrador del Bazar del Forastero (+8)", 8.0)
		VillageChronicle.add(vm, "player_shop_clerk", "Contrataste a %s como dependiente de tu negocio" % npc.npc_name, true)
		npc._spawn_floating_text("🤝🏪 «¡Gracias por el empleo! Atenderé tu mostrador cada día.»", Color.SPRING_GREEN, -46.0)



static func _notify_player(vm, npc, text: String, col: Color = Color.SPRING_GREEN) -> void:
	if npc != null and is_instance_valid(npc) and npc.has_method("_spawn_floating_text"):
		npc._spawn_floating_text(text, col, -46.0)
		return
	var pl: Node2D = VillageNeeds.player_of(vm) as Node2D
	if pl != null and is_instance_valid(pl) and pl.has_method("show_hint"):
		pl.show_hint(text)


# ==============================================================================
# FIS-P1: Interior físico de tu propia casa (huerto, banco de trabajo, escondite bajo tablas y escaleras +1/-1)
# ==============================================================================
## Muebles de la casa del jugador → marca de su casa modelo (en la sala: mapa/casa_modelo.gd).
const MARCA_MUEBLE_CASA: Dictionary = {
	"home_table": "mesa_comedor", "home_workbench": "banco_casa", "home_stash": "escondite",
	"home_stairs": "escalera", "player_shop_counter": "mostrador_casa",
}

static func home_prop_pos(_vm, lot_id: String, kind: String) -> Vector2:
	if VillageLots.lot_def(lot_id).is_empty():
		return Vector2.ZERO
	return VillageLots.house_site(lot_id, String(MARCA_MUEBLE_CASA.get(kind, MARCA_MUEBLE_CASA["home_table"])))


static func sync_home_props(vm) -> void:
	if vm == null or not ("entities_root" in vm) or vm.entities_root == null or not is_instance_valid(vm.entities_root):
		return
	var PropScript: Script = load("res://scripts/obstacles/WorldInteractableProp.gd") as Script
	if PropScript == null:
		return
	var existing: Array[Node] = []
	for child in vm.entities_root.get_children():
		if is_instance_valid(child) and child.is_in_group("home_prop"):
			existing.append(child)
	for old_n in existing:
		old_n.remove_from_group("home_prop")
		old_n.remove_from_group("player_shop_counter")
		old_n.remove_from_group("home_table")
		if old_n.get_parent() != null:
			old_n.get_parent().remove_child(old_n)
		old_n.queue_free()

	var hs: Dictionary = state(vm)
	var prim_lot: String = primary_player_lot(vm)
	var shop_lot: String = player_shop_lot(vm) if has_player_shop(vm) else ""
	sync_relocated_camp_assets(vm, false)
	for lid in player_lots(vm, true):
		var st: Dictionary = VillageLots.lot(vm, lid)
		var up: Dictionary = st.get("upgrades", {})
		var h_title: String = str(st.get("title", "Casa del Forastero"))
		var tb_prop: Node2D = PropScript.new() as Node2D
		tb_prop.name = "HomeTable_" + lid
		tb_prop.global_position = home_prop_pos(vm, lid, "home_table")
		vm.entities_root.add_child(tb_prop)
		tb_prop.call("setup_prop", vm, "home_table", lid, h_title)
		if bool(up.get("workbench", false)):
			var wb: Node2D = PropScript.new() as Node2D
			wb.name = "HomeWorkbench_" + lid
			wb.global_position = home_prop_pos(vm, lid, "home_workbench")
			vm.entities_root.add_child(wb)
			wb.call("setup_prop", vm, "home_workbench", lid, h_title)
		if lid == prim_lot and bool(hs.get("has_stash", false)):
			var st_prop: Node2D = PropScript.new() as Node2D
			st_prop.name = "HomeStash_" + lid
			st_prop.global_position = home_prop_pos(vm, lid, "home_stash")
			vm.entities_root.add_child(st_prop)
			st_prop.call("setup_prop", vm, "home_stash", lid, h_title)
		if bool(up.get("upper_floor", false)) or bool(up.get("hidden_cellar", false)):
			var stairs: Node2D = PropScript.new() as Node2D
			stairs.name = "HomeStairs_" + lid
			stairs.global_position = home_prop_pos(vm, lid, "home_stairs")
			vm.entities_root.add_child(stairs)
			stairs.call("setup_prop", vm, "home_stairs", lid, h_title)
		if has_player_shop(vm) and lid == shop_lot:
			var sc_prop: Node2D = PropScript.new() as Node2D
			sc_prop.name = "PlayerShopCounter_" + lid
			sc_prop.global_position = home_prop_pos(vm, lid, "player_shop_counter")
			vm.entities_root.add_child(sc_prop)
			sc_prop.call("setup_prop", vm, "player_shop_counter", lid, str(hs["player_shop"].get("name", "Bazar del Forastero")))


static func get_player_shop_counter_label(vm) -> String:
	if vm == null or not has_player_shop(vm):
		return "Mostrador y caja de tu tienda"
	var ps: Dictionary = state(vm)["player_shop"]
	var stk: int = int(ps.get("stock", 0))
	var till: int = int(ps.get("till_gold", 0))
	if till > 0:
		return "Mostrador del Bazar (Stock: %d · Recoger la caja: +%d Oro)" % [stk, till]
	return "Mostrador del Bazar (Reponer mercancía · Stock: %d)" % stk


static func open_player_shop_counter_menu(vm, speaker: Node, _player: Node2D = null) -> void:
	if vm == null or not has_player_shop(vm):
		return
	var dm = vm.get_node_or_null("/root/DialogueManager")
	if dm == null or not dm.has_method("start_dialogue"):
		return
	var ps: Dictionary = state(vm)["player_shop"]
	var stk: int = int(ps.get("stock", 0))
	var till: int = int(ps.get("till_gold", 0))
	var clerk = get_player_shop_clerk(vm)
	var clerk_txt: String = "Sin dependiente contratado"
	if clerk != null:
		clerk_txt = "%s (%s)" % [clerk.npc_name, "atendiendo el mostrador" if is_player_shop_clerk_present(vm) else "fuera del mostrador"]
	var choices: Array = [
		{
			"label": "📦🏪 Reponer mercancía desde tu mochila (Stock: %d)" % stk,
			"next": "END",
			"action": "housing_stock_shop"
		},
		{
			"label": "💰🏪 Recoger la caja (+%d Oro)" % till,
			"next": "END",
			"action": "housing_collect_shop"
		},
		{"label": "Apartarse del mostrador [Salir]", "next": "END"}
	]
	var graph: Dictionary = {
		"start": {
			"text": "🏪💰 MOSTRADOR Y CAJA — %s\nExistencias en el mostrador: %d artículo(s) · Caja: %d de oro · Dependiente: %s." % [str(ps.get("name", "Bazar del Forastero")), stk, till, clerk_txt],
			"choices": choices
		}
	}
	dm.start_dialogue(graph, "start", speaker)


static func craft_home_poultice(vm, lot_id: String, inv, player: Node2D = null, npc = null) -> bool:
	if inv == null or not has_upgrade(vm, "workbench"):
		return false
	var lid: String = lot_id if not lot_id.is_empty() else primary_player_lot(vm)
	if lid.is_empty():
		return false
	if not inv.has_item("herbs", 1):
		_notify_player(vm, npc, "⚗️🌿 Necesitas llevar 1 Hierba Medicinal en la mochila para preparar una cataplasma.", Color.ORANGE_RED)
		return false
	inv.remove_item("herbs", 1)
	inv.add_item("herbal_poultice", 1)
	var pl: Node2D = player if player != null else (VillageNeeds.player_of(vm) as Node2D)
	if pl != null and pl.has_method("add_skill_xp"):
		pl.call("add_skill_xp", "crafting", 8)
	VillageChronicle.add(vm, "workbench_poultice", "Preparaste una cataplasma curativa en el banco de trabajo de tu casa", true)
	_notify_player(vm, npc, "🧪🌿 Preparaste 1 cataplasma curativa en tu banco de trabajo (-1 Hierbas Medicinales).", Color.SPRING_GREEN)
	return true


static func open_home_workbench_menu(vm, speaker: Node, _player: Node2D = null) -> void:
	if vm == null:
		return
	var dm = vm.get_node_or_null("/root/DialogueManager")
	if dm == null or not dm.has_method("start_dialogue"):
		return
	var st_uw: Dictionary = vm.VillageUnderworld.state(vm) if "VillageUnderworld" in vm and vm.VillageUnderworld != null else {}
	var dust_ready: bool = int(st_uw.get("last_cook_day", -1)) != today()
	var choices: Array = [
		{
			"label": "🧪🌿 Preparar cataplasma curativa (-1 Hierbas Medicinales -> +1 Cataplasma)",
			"next": "END",
			"action": "housing_craft_poultice"
		},
	]
	if dust_ready:
		choices.append({
			"label": "⚗️🌙 Destilar 2 dosis de «polvo de ocaso» (-25 Oro en reactivos, 1/día)",
			"next": "END",
			"action": "underworld_cook_dust"
		})
	choices.append({"label": "Apartarse del banco [Salir]", "next": "END"})
	var graph: Dictionary = {
		"start": {
			"text": "⚗️🌿 BANCO DE TRABAJO Y ALQUIMIA\nEl banco de roble de tu casa tiene mortero, redomas, hierbas secas y un alambique de cobre.",
			"choices": choices
		}
	}
	dm.start_dialogue(graph, "start", speaker)


static func open_home_stash_menu(vm, speaker: Node, _player: Node2D = null) -> void:
	if vm == null:
		return
	var dm = vm.get_node_or_null("/root/DialogueManager")
	if dm == null or not dm.has_method("start_dialogue"):
		return
	var hs: Dictionary = state(vm)
	var hidden_g: int = int(hs.get("stash_gold", 0))
	var choices: Array = [
		{
			"label": "🗝️💰 Guardar 25 de oro bajo las tablas (Oculto: %d Oro)" % hidden_g,
			"next": "END",
			"action": "housing_stash_put"
		}
	]
	if hidden_g > 0:
		choices.append({
			"label": "🗝️📤 Sacar todo tu oro del escondite (+%d Oro)" % hidden_g,
			"next": "END",
			"action": "housing_stash_take"
		})
	choices.append({"label": "Cerrar las tablas [Salir]", "next": "END"})
	var graph: Dictionary = {
		"start": {
			"text": "🪵🗝️ ESCONDITE BAJO LAS TABLAS\nUn hueco forrado en brea bajo el entarimado de tu casa mantiene tus ahorros a salvo de embargos y multas.\nOro oculto ahora mismo: %d." % hidden_g,
			"choices": choices
		}
	}
	dm.start_dialogue(graph, "start", speaker)


static func get_home_stairs_label(vm, _lot_id: String = "") -> String:
	var elev: int = int(vm.player_elevation_level)
	var can_hide: bool = has_upgrade(vm, "hidden_cellar") and int(vm.wanted_level) == 1 and int(vm.player_murder_warrants_count) == 0 and can_purge_wanted(vm)
	if elev == 1:
		return "Bajar a la planta baja (nivel 0)"
	if elev == -1:
		if can_hide:
			return "Trampilla del sótano (subir o esconderte)"
		return "Subir a la planta baja (nivel 0)"
	var has_up: bool = has_upgrade(vm, "upper_floor")
	var has_cel: bool = has_upgrade(vm, "hidden_cellar")
	if has_up and not has_cel:
		return "Subir al primer piso / altillo (nivel +1)"
	if has_cel and not has_up:
		if can_hide:
			return "Esconderte o bajar al sótano (nivel -1)"
		return "Bajar al sótano (nivel -1)"
	return "Usar escalera (+1) o trampilla (-1)"


static func interact_home_stairs(vm, _lot_id: String, speaker: Node = null, player: Node2D = null) -> bool:
	if vm == null:
		return false
	var pl: Node2D = player if player != null else (VillageNeeds.player_of(vm) as Node2D)
	var inv = pl.get("inventory") if pl != null else null
	var elev: int = int(vm.player_elevation_level)
	var has_up: bool = has_upgrade(vm, "upper_floor")
	var has_cel: bool = has_upgrade(vm, "hidden_cellar")
	var can_hide: bool = has_cel and int(vm.wanted_level) == 1 and int(vm.player_murder_warrants_count) == 0 and can_purge_wanted(vm)

	var choices: Array = []
	if can_hide:
		choices.append({"label": "🕳️🤫 Esconderte en tu sótano secreto hasta que pase la búsqueda", "next": "END", "action": "housing_hide_cellar"})
	if has_up and elev != 1:
		choices.append({"label": "🪜⬆️ Subir al primer piso / altillo de tu casa (nivel +1)", "next": "END", "action": "housing_change_level:1"})
	if has_cel and elev != -1:
		choices.append({"label": "🕳️⬇️ Bajar al sótano de tu casa (nivel -1)", "next": "END", "action": "housing_change_level:-1"})
	if elev != 0:
		choices.append({"label": "🚪➡️ Volver a la planta baja / nivel de calle (nivel 0)", "next": "END", "action": "housing_change_level:0"})

	if choices.is_empty():
		return false
	if choices.size() == 1:
		on_player_action(vm, null, str(choices[0]["action"]), inv)
		return true
	var dm = vm.get_node_or_null("/root/DialogueManager")
	if dm != null and dm.has_method("start_dialogue") and speaker != null:
		choices.append({"label": "Quedarse en esta planta [Salir]", "next": "END"})
		var graph: Dictionary = {
			"start": {
				"text": "🪜🕳️ ESCALERA Y TRAMPILLA DE CASA\nEstás en la planta %d de tu casa. ¿A qué nivel quieres ir?" % elev,
				"choices": choices
			}
		}
		dm.start_dialogue(graph, "start", speaker)
		return true
	on_player_action(vm, null, str(choices[0]["action"]), inv)
	return true


# ==============================================================================
# Bloque P4: Cenas con vecinos, fiestas en tu casa y cenas de paz hechas físicas
# ==============================================================================
static func total_minutes(override_hour: int = -1) -> int:
	var d: int = int(WorldClock.current_day) if WorldClock else 1
	var h: int = override_hour if override_hour >= 0 else (int(WorldClock.current_hour) if WorldClock else 12)
	var m: int = int(WorldClock.current_minute) if (WorldClock and override_hour < 0) else 0
	return (d * 24 + h) * 60 + m


static func table_seats(table_pos: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in range(6):
		var ang: float = float(i) * TAU / 6.0
		out.append(table_pos + Vector2(TABLE_SEAT_DIST, 0.0).rotated(ang))
	return out


static func has_active_gathering(vm) -> bool:
	if vm == null:
		return false
	var g: Dictionary = state(vm).get("gathering", {})
	return not g.is_empty() and str(g.get("kind", "")) != ""


## Devuelve a la posadera (`vm._innkeeper_npc`); si no hay o está muerta, usa la panadera como respaldo.
static func caterer_npc_of(vm):
	if vm == null:
		return null
	if is_instance_valid(vm._innkeeper_npc) and not vm._innkeeper_npc.is_dead:
		return vm._innkeeper_npc
	var baker = vm.trade_npcs.get(int(VillageNPC.TradeRole.BAKER), null)
	if baker != null and is_instance_valid(baker) and not baker.is_dead:
		return baker
	return null


## Preso: su cama es el catre de la celda (plano de la comisaría, llevado al mundo).
const CAMA_CELDA_PLANO := Vector2(872.0, 176.0)
const CAMA_CELDA_RADIO: float = 24.0
static func _duerme_en_celda(npc) -> bool:
	return npc.bed_position.distance_to(VillageLots.EdificioEditor.a_mundo("building_police", CAMA_CELDA_PLANO)) <= CAMA_CELDA_RADIO

static func can_walk_to_gathering(npc) -> bool:
	if npc == null or not is_instance_valid(npc):
		return false
	if npc.is_dead or npc.is_downed or not npc.is_conscious() or npc.is_sleeping or npc.is_hostile or npc.sick_level >= 2:
		return false
	if _duerme_en_celda(npc):
		return false
	return true


static func is_free_for_night_gathering(vm, npc) -> bool:
	if npc == null or not is_instance_valid(npc):
		return false
	if npc.is_dead or npc.is_downed or not npc.is_conscious() or npc.is_hostile or npc.sick_level >= 2:
		return false
	if int(npc.trade_role) == int(VillageNPC.TradeRole.CHILD) or VillageNeeds.is_outsider(npc):
		return false
	if _duerme_en_celda(npc):
		return false
	# Trabajo nocturno: la posadera atiende la taberna hasta las 23:00 y quien ya está en un recado nocturno no está libre
	if int(npc.trade_role) == int(VillageNPC.TradeRole.INNKEEPER):
		return false
	if npc.errand_kind in ["fence_alley", "catering", "smuggler_bust", "gathering"]:
		return false
	var g: Dictionary = state(vm).get("gathering", {}) if vm != null else {}
	var pk: String = npc.get_person_key()
	if pk in (g.get("guests", []) as Array) or pk == str(g.get("caterer_key", "")):
		return false
	return true


static func get_home_table_label(vm) -> String:
	if vm == null:
		return "Mesa del comedor"
	var hs: Dictionary = state(vm)
	var g: Dictionary = hs.get("gathering", {})
	var cur_r: int = int(hs.get("table_rations", 0))
	var need_r: int = maxi(2, (g.get("guests", []) as Array).size() * 2)
	if has_active_gathering(vm) and str(g.get("place", "")) == "home":
		return "Mesa del comedor (%d/%d raciones · %s a las %02d:00)" % [cur_r, need_r, ("Cena" if str(g.get("kind", "")) == "dinner" else "Fiesta"), int(g.get("start_hour", 20))]
	return "Mesa del comedor (Raciones: %d · Organizar fiesta)" % cur_r


static func open_home_table_menu(vm, speaker: Node, _player: Node2D = null) -> void:
	if vm == null:
		return
	var dm = vm.get_node_or_null("/root/DialogueManager")
	if dm == null or not dm.has_method("start_dialogue"):
		return
	var hs: Dictionary = state(vm)
	var g: Dictionary = hs.get("gathering", {})
	var cur_r: int = int(hs.get("table_rations", 0))
	var need_r: int = maxi(2, (g.get("guests", []) as Array).size() * 2)
	var choices: Array = [
		{
			"label": "🍞🍲 Poner comida en la mesa (%d/%d raciones)" % [cur_r, need_r],
			"next": "END",
			"action": "housing_table_put_food"
		}
	]
	if not has_active_gathering(vm) and int(hs.get("last_party_day", -99)) != today():
		choices.append({
			"label": "🎉🍷 Convocar una fiesta esta noche (a las 21:00)",
			"next": "END",
			"action": "housing_party_call"
		})
	var p_lot_tb: String = primary_player_lot(vm)
	if p_lot_tb != "" and str(VillageLots.lot(vm, p_lot_tb).get("status", "")) == "built":
		if str(hs.get("toby_lot", "")) != p_lot_tb:
			choices.append({
				"label": "🐕🥣 Traer a Toby y su comedero al patio de tu casa (%s)" % p_lot_tb,
				"next": "END",
				"action": "housing_move_toby:" + p_lot_tb
			})
	choices.append({"label": "Apartarse de la mesa [Salir]", "next": "END"})
	var status_txt: String = "Sin reunión prevista hoy."
	if has_active_gathering(vm) and str(g.get("place", "")) == "home":
		status_txt = "Reunión prevista: %s a las %02d:00 (%d invitado(s))." % [("Cena" if str(g.get("kind", "")) == "dinner" else "Fiesta"), int(g.get("start_hour", 20)), (g.get("guests", []) as Array).size()]
	var graph: Dictionary = {
		"start": {
			"text": "🍽️🕯️ MESA DEL COMEDOR\nRaciones preparadas sobre la mesa: %d/%d (hacen falta 2 raciones por invitado).\n%s" % [cur_r, need_r, status_txt],
			"choices": choices
		}
	}
	dm.start_dialogue(graph, "start", speaker)


## Pasa comida de la mochila del jugador (`inv`) a la mesa de casa (`table_rations`). 1 objeto de comida = 1 ración.
static func put_food_on_home_table(vm, inv, max_to_put: int = -1) -> int:
	if vm == null or inv == null or not inv.has_method("has_item") or not inv.has_method("remove_item"):
		return 0
	var hs: Dictionary = state(vm)
	var g: Dictionary = hs.get("gathering", {})
	var cur_r: int = int(hs.get("table_rations", 0))
	var need_r: int = maxi(2, (g.get("guests", []) as Array).size() * 2)
	var target_add: int = max_to_put if max_to_put > 0 else maxi(0, need_r - cur_r)
	if target_add <= 0:
		return 0
	var added: int = 0
	for fid in TABLE_FOOD_ITEMS:
		while added < target_add and bool(inv.has_item(fid, 1)):
			inv.remove_item(fid, 1)
			added += 1
		if added >= target_add:
			break
	if added > 0:
		hs["table_rations"] = cur_r + added
		if not g.is_empty():
			g["food_rations"] = int(hs["table_rations"])
	return added


## 1) Cena con un vecino en tu casa esta noche a las 20:00 (sin cobro en diálogo).
static func schedule_dinner(vm, npc) -> bool:
	if vm == null or npc == null or has_active_gathering(vm):
		return false
	var p_lot: String = primary_player_lot(vm)
	if p_lot == "" or str(VillageLots.lot(vm, p_lot).get("status", "")) != "built":
		return false
	var hs: Dictionary = state(vm)
	if today() - int(hs.get("last_dinner_day", -99)) < 3 or int(npc.affinity) < 10:
		return false
	if not is_free_for_night_gathering(vm, npc):
		return false
	var cur_h: int = int(WorldClock.current_hour) if WorldClock else 12
	var s_day: int = today() if cur_h <= 20 else today() + 1
	hs["last_dinner_day"] = today()
	var t_pos: Vector2 = Solar.a_mundo(p_lot, home_prop_pos(vm, p_lot, "home_table"))
	hs["gathering"] = {
		"kind": "dinner",
		"place": "home",
		"lot_id": p_lot,
		"table_pos": t_pos,
		"start_day": s_day,
		"start_hour": 20,
		"guests": [npc.get_person_key()],
		"declined": [],
		"arrived": [],
		"food_rations": int(hs.get("table_rations", 0)),
		"catering_hired": false,
		"catering_cost": 0,
		"caterer_key": "",
		"catering_dispatched": false,
		"catering_arrived": false,
		"dispatched": false,
		"started": false,
		"started_at_minutes": 0,
		"dispatched_at_minutes": 0,
		"last_chat_minutes": 0,
		"player_was_present": false
	}
	if s_day == today() and cur_h == 20:
		tick_gathering(vm, 20)
	return true


## 2) Convoca una fiesta en tu casa para esta noche a las 21:00 (luego invitas uno a uno hasta 6 vecinos).
static func convoke_house_party(vm) -> bool:
	if vm == null or has_active_gathering(vm):
		return false
	var p_lot: String = primary_player_lot(vm)
	if p_lot == "" or str(VillageLots.lot(vm, p_lot).get("status", "")) != "built":
		return false
	var hs: Dictionary = state(vm)
	if int(hs.get("last_party_day", -99)) == today():
		return false
	var cur_h: int = int(WorldClock.current_hour) if WorldClock else 12
	var s_day: int = today() if cur_h <= 21 else today() + 1
	hs["last_party_day"] = today()
	var t_pos: Vector2 = Solar.a_mundo(p_lot, home_prop_pos(vm, p_lot, "home_table"))
	hs["gathering"] = {
		"kind": "party",
		"place": "home",
		"lot_id": p_lot,
		"table_pos": t_pos,
		"start_day": s_day,
		"start_hour": 21,
		"guests": [],
		"declined": [],
		"arrived": [],
		"food_rations": int(hs.get("table_rations", 0)),
		"catering_hired": false,
		"catering_cost": 0,
		"caterer_key": "",
		"catering_dispatched": false,
		"catering_arrived": false,
		"dispatched": false,
		"started": false,
		"started_at_minutes": 0,
		"dispatched_at_minutes": 0,
		"last_chat_minutes": 0,
		"player_was_present": false
	}
	return true


## Invita a un vecino adulto a la fiesta de esta noche (máx. 6). Acepta si afinidad >= 10 y libre; 0..9 con 40 %; < 0 rechaza.
static func invite_to_house_party(vm, npc, force_roll: float = -1.0) -> bool:
	if vm == null or npc == null or not has_active_gathering(vm):
		return false
	var g: Dictionary = state(vm)["gathering"]
	if str(g.get("kind", "")) != "party" or bool(g.get("dispatched", false)):
		return false
	var guests: Array = g.get("guests", [])
	var declined: Array = g.get("declined", [])
	var pk: String = npc.get_person_key()
	if guests.size() >= 6 or pk in guests or pk in declined:
		return false
	if not is_free_for_night_gathering(vm, npc) or int(npc.affinity) < 0:
		declined.append(pk)
		g["declined"] = declined
		return false
	var accepts: bool = false
	if int(npc.affinity) >= 10:
		accepts = true
	else:
		var roll: float = force_roll if force_roll >= 0.0 else randf()
		accepts = roll < 0.40
	if accepts:
		guests.append(pk)
		g["guests"] = guests
		return true
	declined.append(pk)
	g["declined"] = declined
	return false


## Opción B: Contrata a la posadera (`CATERING_COST_PER_GUEST = 4` × invitados) para cocinar en tu mesa 1 h antes.
static func hire_catering(vm, inv) -> bool:
	if vm == null or inv == null or not has_active_gathering(vm):
		return false
	var g: Dictionary = state(vm)["gathering"]
	if str(g.get("place", "")) != "home" or bool(g.get("dispatched", false)) or bool(g.get("catering_hired", false)):
		return false
	var g_cnt: int = (g.get("guests", []) as Array).size()
	if g_cnt <= 0:
		return false
	var cat_npc = caterer_npc_of(vm)
	if cat_npc == null:
		return false
	var cost: int = CATERING_COST_PER_GUEST * g_cnt
	if int(inv.gold) < cost:
		return false
	inv.add_gold(-cost)
	vm.pay_into(cat_npc, cost)
	g["catering_hired"] = true
	g["catering_cost"] = cost
	g["caterer_key"] = cat_npc.get_person_key()
	g["catering_dispatched"] = false
	g["catering_arrived"] = false
	var cur_h: int = int(WorldClock.current_hour) if WorldClock else 12
	if int(g.get("start_day", today())) == today() and cur_h == int(g.get("start_hour", 20)) - 1:
		_dispatch_caterer_if_ready(vm, g)
	return true


## 3) Cena de paz en la posada mañana a las 20:00 entre dos familias en feudo (cabeza + hasta 2 adultos libres por familia).
static func schedule_peace_dinner(vm, fk: String, force_brawl: bool = false) -> bool:
	if vm == null or fk == "" or has_active_gathering(vm):
		return false
	var feuds: Dictionary = vm.VillageClans.state(vm).get("feuds", {})
	if not feuds.has(fk):
		return false
	var f: Dictionary = feuds[fk]
	var fam_a: String = str(f.get("fam_a", ""))
	var fam_b: String = str(f.get("fam_b", ""))
	var guests: Array = []
	for fam in [fam_a, fam_b]:
		var added_fam: int = 0
		var head = vm.VillageClans.patriarch_of(vm, fam)
		if head != null and is_free_for_night_gathering(vm, head):
			guests.append(head.get_person_key())
			added_fam += 1
		for m in vm.VillageClans.clan_members(vm, fam):
			if added_fam >= 3:
				break
			if m == head or (m.get_person_key() in guests):
				continue
			if is_free_for_night_gathering(vm, m):
				guests.append(m.get_person_key())
				added_fam += 1
	state(vm)["gathering"] = {
		"kind": "peace",
		"place": "inn",
		"lot_id": "",
		"table_pos": vm._tavern_social_pos,
		"start_day": today() + 1,
		"start_hour": 20,
		"guests": guests,
		"declined": [],
		"arrived": [],
		"food_rations": 99,
		"catering_hired": false,
		"catering_cost": 0,
		"caterer_key": "",
		"catering_dispatched": false,
		"catering_arrived": false,
		"dispatched": false,
		"started": false,
		"started_at_minutes": 0,
		"dispatched_at_minutes": 0,
		"last_chat_minutes": 0,
		"player_was_present": false,
		"feud_key": fk,
		"force_brawl": force_brawl
	}
	return true


static func _dispatch_caterer_if_ready(vm, g: Dictionary) -> void:
	if bool(g.get("catering_dispatched", false)) or not bool(g.get("catering_hired", false)):
		return
	g["catering_dispatched"] = true
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var cat_npc = by_key.get(str(g.get("caterer_key", "")), null)
	if cat_npc == null:
		cat_npc = caterer_npc_of(vm)
	if can_walk_to_gathering(cat_npc):
		var t_pos: Vector2 = g.get("table_pos", Vector2.ZERO)
		cat_npc.start_errand("catering", t_pos + Vector2(0.0, -14.0))


## B4: al cargar partida. Los recados y los asientos de los vecinos no se guardan: los invitados sentados vuelven a su
## silla, los que iban andando vuelven a echar a andar y la posadera, si iba de camino, vuelve a salir.
static func after_load_gathering(vm) -> void:
	if vm == null or not has_active_gathering(vm):
		return
	var g: Dictionary = state(vm)["gathering"]
	var t_pos: Vector2 = g.get("table_pos", Vector2.ZERO) if g.get("table_pos", null) is Vector2 else Vector2.ZERO
	if t_pos == Vector2.ZERO:
		_cleanup_gathering_All(vm)
		return
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	if bool(g.get("catering_dispatched", false)) and not bool(g.get("catering_arrived", false)):
		g["catering_dispatched"] = false
		_dispatch_caterer_if_ready(vm, g)
	if not bool(g.get("dispatched", false)):
		return
	var seats: Array[Vector2] = table_seats(t_pos)
	var guests: Array = g.get("guests", [])
	var arrived: Array = g.get("arrived", [])
	var left_nf: Array = g.get("left_no_food", [])
	for i in range(mini(guests.size(), seats.size())):
		var gk: String = str(guests[i])
		var gn = by_key.get(gk, null)
		if gn == null or not is_instance_valid(gn) or gn.is_dead:
			continue
		if gk in arrived:
			gn.global_position = seats[i]
			gn.set_poker_seating(true, seats[i])
		elif not (gk in left_nf) and can_walk_to_gathering(gn):
			gn.start_errand("gathering", seats[i])

static func on_caterer_arrived(vm, npc) -> void:
	if vm == null or npc == null or not has_active_gathering(vm):
		if npc != null and is_instance_valid(npc) and npc.errand_kind == "catering":
			npc.end_errand()
		return
	var hs: Dictionary = state(vm)
	var g: Dictionary = hs["gathering"]
	if not bool(g.get("catering_hired", false)):
		npc.end_errand()
		return
	if not bool(g.get("catering_arrived", false)):
		g["catering_arrived"] = true
		var needed: int = maxi(2, (g.get("guests", []) as Array).size() * 2)
		hs["table_rations"] = maxi(int(hs.get("table_rations", 0)), needed)
		g["food_rations"] = int(hs["table_rations"])
		npc._spawn_floating_text("🍲 «¡La cena está lista y servida en tu mesa!»", Color.GOLD, -36.0)


static func _refund_catering_and_cancel(vm, g: Dictionary) -> void:
	var hs: Dictionary = state(vm)
	var refund: int = int(g.get("catering_cost", 0))
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var cat_npc = by_key.get(str(g.get("caterer_key", "")), null)
	if cat_npc == null:
		cat_npc = caterer_npc_of(vm)
	if refund > 0:
		if cat_npc != null and is_instance_valid(cat_npc):
			var from_cat: int = mini(refund, maxi(0, int(cat_npc.personal_gold)))
			cat_npc.personal_gold -= from_cat
			var rem: int = refund - from_cat
			if rem > 0 and vm.town_state is Dictionary:
				vm.town_state["treasury"] = maxi(0, int(vm.town_state.get("treasury", 0)) - rem)
		elif vm.town_state is Dictionary:
			vm.town_state["treasury"] = maxi(0, int(vm.town_state.get("treasury", 0)) - refund)
		var pl = VillageNeeds.player_of(vm)
		var inv = pl.get("inventory") if pl != null else null
		if inv != null and inv.has_method("add_gold"):
			inv.add_gold(refund)
	if cat_npc != null and is_instance_valid(cat_npc) and cat_npc.errand_kind == "catering":
		cat_npc.end_errand()
	hs["gathering"] = {}


static func _min_guests_to_start(g: Dictionary) -> int:
	if str(g.get("kind", "")) == "dinner":
		return 1
	var total_inv: int = (g.get("guests", []) as Array).size()
	return mini(2, maxi(1, total_inv))


static func on_gathering_guest_arrived(vm, npc) -> void:
	if vm == null or npc == null or not has_active_gathering(vm):
		if npc != null and is_instance_valid(npc) and npc.errand_kind == "gathering":
			npc.end_errand()
		return
	var hs: Dictionary = state(vm)
	var g: Dictionary = hs["gathering"]
	var guests: Array = g.get("guests", [])
	var pk: String = npc.get_person_key()
	if not (pk in guests):
		npc.end_errand()
		return
	var needed_food: int = 0 if str(g.get("place", "")) == "inn" else (guests.size() * 2)
	var avail_food: int = 99 if str(g.get("place", "")) == "inn" else maxi(int(hs.get("table_rations", 0)), int(g.get("food_rations", 0)))
	if avail_food < needed_food:
		# Sin comida suficiente en la mesa: el invitado ve la mesa vacía, se marcha molesto (-5 afinidad) y no se sienta
		npc.end_errand()
		npc.modify_affinity(-5)
		npc.add_thought("Me invitaron a cenar y la mesa estaba vacía (-5)", -5.0)
		npc._spawn_floating_text("😠 «¿Nos invitas y la mesa está vacía? ¡Qué desfachatez!»", Color.ORANGE_RED, -42.0)
		var left_arr: Array = g.get("left_no_food", [])
		if not (pk in left_arr):
			left_arr.append(pk)
		g["left_no_food"] = left_arr
		var any_walking: bool = false
		var by_key: Dictionary = vm._get_npcs_by_person_key()
		for gk in guests:
			var gn = by_key.get(str(gk), null)
			if gn != null and is_instance_valid(gn) and gn.errand_kind == "gathering":
				any_walking = true
				break
		if not any_walking:
			_cleanup_gathering_All(vm)
		return

	var seat_pos: Vector2 = npc.errand_pos
	npc.end_errand()
	npc.set_poker_seating(true, seat_pos)
	var arrived: Array = g.get("arrived", [])
	if not (pk in arrived):
		arrived.append(pk)
	g["arrived"] = arrived
	if not bool(g.get("started", false)) and arrived.size() >= _min_guests_to_start(g):
		g["started"] = true
		var now_m: int = total_minutes()
		g["started_at_minutes"] = now_m
		g["last_chat_minutes"] = now_m
		var by_key2: Dictionary = vm._get_npcs_by_person_key()
		var cat_npc = by_key2.get(str(g.get("caterer_key", "")), null)
		if cat_npc != null and is_instance_valid(cat_npc) and cat_npc.errand_kind == "catering":
			cat_npc.end_errand()


static func tick_gathering(vm, override_hour: int = -1) -> void:
	if vm == null or not has_active_gathering(vm):
		return
	var hs: Dictionary = state(vm)
	var g: Dictionary = hs["gathering"]
	var cur_d: int = today()
	var s_day: int = int(g.get("start_day", cur_d))
	var s_hour: int = int(g.get("start_hour", 20))
	var now_min: int = total_minutes(override_hour)
	var start_min: int = (s_day * 24 + s_hour) * 60

	# 1 h antes de `start_hour`: la posadera camina a tu mesa si contrataste cáterin
	if bool(g.get("catering_hired", false)) and not bool(g.get("catering_dispatched", false)):
		if now_min >= start_min - 60 and now_min < start_min:
			_dispatch_caterer_if_ready(vm, g)

	# A `start_hour`: comprobar cáterin y enviar a los invitados andando hacia su asiento (`start_errand("gathering", seat_pos)`)
	if not bool(g.get("dispatched", false)) and now_min >= start_min:
		if bool(g.get("catering_hired", false)) and not bool(g.get("catering_arrived", false)):
			var by_key_c: Dictionary = vm._get_npcs_by_person_key()
			var cat_n = by_key_c.get(str(g.get("caterer_key", "")), null)
			if cat_n != null and is_instance_valid(cat_n) and cat_n.global_position.distance_to(g.get("table_pos", Vector2.ZERO)) <= VillageNeeds.ARRIVE_RADIUS * 1.5:
				on_caterer_arrived(vm, cat_n)
			else:
				_refund_catering_and_cancel(vm, g)
				return
		g["dispatched"] = true
		g["dispatched_at_minutes"] = now_min
		var guests: Array = g.get("guests", [])
		if guests.is_empty():
			_cleanup_gathering_All(vm)
			return
		var seats: Array[Vector2] = table_seats(g.get("table_pos", Vector2.ZERO))
		var by_key: Dictionary = vm._get_npcs_by_person_key()
		for i in range(mini(guests.size(), seats.size())):
			var gn = by_key.get(str(guests[i]), null)
			if can_walk_to_gathering(gn):
				gn.start_errand("gathering", seats[i])

	if not bool(g.get("dispatched", false)):
		return

	# Si en 2 h desde `start_hour` algún rezagado no ha llegado, ya no cuenta
	var disp_min: int = int(g.get("dispatched_at_minutes", start_min))
	if now_min >= disp_min + GATHERING_DURATION_MIN:
		var by_key_l: Dictionary = vm._get_npcs_by_person_key()
		for gk in (g.get("guests", []) as Array):
			var gn_l = by_key_l.get(str(gk), null)
			if gn_l != null and is_instance_valid(gn_l) and gn_l.errand_kind == "gathering":
				gn_l.end_errand()
		if not bool(g.get("started", false)):
			if str(g.get("kind", "")) == "peace":
				_complete_gathering(vm)
			elif (g.get("arrived", []) as Array).size() >= 1:
				g["started"] = true
				g["started_at_minutes"] = disp_min
				g["last_chat_minutes"] = now_min
			else:
				_cleanup_gathering_All(vm)
				return

	if not bool(g.get("started", false)):
		return

	var pl: Node2D = VillageNeeds.player_of(vm) as Node2D
	var t_pos: Vector2 = g.get("table_pos", Vector2.ZERO)
	var pl_near: bool = pl != null and is_instance_valid(pl) and pl.global_position.distance_to(t_pos) < GATHERING_PLAYER_RADIUS
	if pl_near:
		g["player_was_present"] = true
	elif bool(g.get("player_was_present", false)):
		# El jugador estaba en la reunión y se marchó antes de terminar: se disuelve y se enfadan (-5)
		_abandon_gathering(vm)
		return

	# Charla en la mesa cada 20 min de juego
	var last_chat: int = int(g.get("last_chat_minutes", now_min))
	if now_min - last_chat >= GATHERING_CHAT_INTERVAL_MIN:
		g["last_chat_minutes"] = now_min
		var arr_keys: Array = g.get("arrived", [])
		if not arr_keys.is_empty():
			var by_key_ch: Dictionary = vm._get_npcs_by_person_key()
			var spk_key: String = str(arr_keys[randi() % arr_keys.size()])
			var spk = by_key_ch.get(spk_key, null)
			if spk != null and is_instance_valid(spk):
				var phrase: String = GATHERING_CHAT_PHRASES[randi() % GATHERING_CHAT_PHRASES.size()]
				spk._spawn_floating_text(phrase, Color(1.0, 0.92, 0.68), -34.0)

	# Al cumplirse las 2 h de duración desde que empezó
	var started_min: int = int(g.get("started_at_minutes", disp_min))
	if now_min >= started_min + GATHERING_DURATION_MIN:
		if not pl_near:
			_abandon_gathering(vm)
		else:
			_complete_gathering(vm)


static func _abandon_gathering(vm) -> void:
	var hs: Dictionary = state(vm)
	var g: Dictionary = hs.get("gathering", {})
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for ak in (g.get("arrived", []) as Array):
		var gn = by_key.get(str(ak), null)
		if gn != null and is_instance_valid(gn):
			gn.set_poker_seating(false)
			gn.modify_affinity(-5)
			gn.add_thought("El forastero nos dejó plantados", -5.0)
			gn._spawn_floating_text("😠 «¡El forastero nos dejó plantados!»", Color.ORANGE_RED, -42.0)
	_cleanup_gathering_All(vm)


static func _complete_gathering(vm) -> void:
	var hs: Dictionary = state(vm)
	var g: Dictionary = hs.get("gathering", {})
	var kind: String = str(g.get("kind", ""))
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var arrived_npcs: Array = []
	for ak in (g.get("arrived", []) as Array):
		var gn = by_key.get(str(ak), null)
		if gn != null and is_instance_valid(gn) and not gn.is_dead:
			gn.set_poker_seating(false)
			arrived_npcs.append(gn)

	if str(g.get("place", "")) == "home":
		var used_r: int = (g.get("guests", []) as Array).size() * 2
		hs["table_rations"] = maxi(0, int(hs.get("table_rations", 0)) - used_r)

	if kind == "dinner":
		if not arrived_npcs.is_empty():
			var guest = arrived_npcs[0]
			guest.modify_affinity(14)
			guest.add_thought("Cena estupenda en casa del forastero (+8)", 8.0)
			TraitDiscovery.reveal_next(guest, "en una cena en tu casa")
			for o in VillageNeeds.living(vm):
				if o != guest and guest.get_relationship_with_npc(o.get_person_key()) <= -20:
					guest.modify_npc_relationship(o, 15, "Hicimos las paces cenando en casa del forastero", false)
					break
			VillageChronicle.add(vm, "dinner_party", "Invitaste a %s a cenar en tu casa" % guest.npc_name, true)
			guest._spawn_floating_text("🍷🍽️ «¡Qué gran velada en tu casa!»", Color.SPRING_GREEN, -46.0)

	elif kind == "party":
		for guest_p in arrived_npcs:
			guest_p.modify_affinity(10)
			guest_p.add_thought("Fiesta memorable en casa del forastero (+10)", 10.0)
		for i in range(arrived_npcs.size()):
			for j in range(i + 1, arrived_npcs.size()):
				arrived_npcs[i].modify_npc_relationship(arrived_npcs[j], 8, "Brindamos juntos en la fiesta del forastero", true)
				arrived_npcs[j].modify_npc_relationship(arrived_npcs[i], 8, "Brindamos juntos en la fiesta del forastero", true)
		if not arrived_npcs.is_empty():
			VillageChronicle.add(vm, "house_party", "Celebraste una fiesta en tu casa con %d vecinos del valle" % arrived_npcs.size(), true)
			arrived_npcs[0]._spawn_floating_text("🎉🍻 «¡La mejor fiesta del valle! Todos brindan por ti.»", Color.SPRING_GREEN, -46.0)

	elif kind == "peace":
		var fk: String = str(g.get("feud_key", ""))
		var feuds: Dictionary = vm.VillageClans.state(vm).get("feuds", {})
		if feuds.has(fk):
			var f: Dictionary = feuds[fk]
			var fam_a: String = str(f.get("fam_a", ""))
			var fam_b: String = str(f.get("fam_b", ""))
			var name_a: String = str(f.get("name_a", fam_a))
			var name_b: String = str(f.get("name_b", fam_b))
			var present_a: Array = []
			var present_b: Array = []
			for an in arrived_npcs:
				if str(an.family_id) == fam_a:
					present_a.append(an)
				elif str(an.family_id) == fam_b:
					present_b.append(an)
			if present_a.is_empty() or present_b.is_empty():
				var missing_fam: String = name_a if present_a.is_empty() else name_b
				VillageChronicle.add(vm, "clan_peace_absent", "La familia %s no se presentó" % missing_fam, true)
			else:
				var sum_agg: float = 0.0
				for an2 in arrived_npcs:
					sum_agg += TraitCatalog.npc_tendency(an2, "aggression")
				var avg_agg: float = sum_agg / float(maxi(1, arrived_npcs.size()))
				var feud_days: int = maxi(0, today() - int(f.get("day", today())))
				var prob: float = 0.10 + 0.25 * avg_agg + minf(0.20, 0.02 * float(feud_days))
				if bool(g.get("force_brawl", false)):
					prob = 1.0
				elif g.has("brawl_prob_override"):
					prob = float(g["brawl_prob_override"])
				if randf() < prob:
					for an3 in arrived_npcs:
						an3._spawn_floating_text("🤬🍷 «¡No olvidaremos vuestras ofensas! ¡Nos marchamos!»", Color.ORANGE_RED, -42.0)
					for ma in vm.VillageClans.clan_members(vm, fam_a):
						for mb in vm.VillageClans.clan_members(vm, fam_b):
							ma.modify_npc_relationship(mb, -5, "La cena de paz en la posada acabó a gritos", true)
							mb.modify_npc_relationship(ma, -5, "La cena de paz en la posada acabó a gritos", true)
					VillageChronicle.add(vm, "clan_peace_brawl", "La cena de paz entre %s y %s acabó a gritos" % [name_a, name_b], true)
				else:
					vm.VillageClans.mediate_clan_peace(vm, fk, "en una cena de paz en la posada")
					for an4 in arrived_npcs:
						an4.modify_affinity(12)
						an4._spawn_floating_text("🍷🕊️ «Habrá paz entre nuestras familias.»", Color.SPRING_GREEN, -42.0)

	_cleanup_gathering_All(vm)


static func _cleanup_gathering_All(vm) -> void:
	var hs: Dictionary = state(vm)
	var g: Dictionary = hs.get("gathering", {})
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for gk in (g.get("guests", []) as Array):
		var gn = by_key.get(str(gk), null)
		if gn != null and is_instance_valid(gn):
			if gn.errand_kind == "gathering":
				gn.end_errand()
			if gn.is_at_poker_table:
				gn.set_poker_seating(false)
	var ck: String = str(g.get("caterer_key", ""))
	if ck != "":
		var cn = by_key.get(ck, null)
		if cn != null and is_instance_valid(cn) and cn.errand_kind == "catering":
			cn.end_errand()
	hs["gathering"] = {}
