@tool
extends RefCounted

## V5e: biblioteca, escuela, mercado semanal y arreglos del Taller de Reparaciones.
## - Biblioteca (solar n5): un sitio de ocio bajo techo (VillagePlaces). Va más quien es curioso; con lluvia es casi
##   el único sitio al que la gente sale. Cada visita suma lecturas al pueblo (para la escuela y la secta, más
##   adelante). El jugador puede leer un rato una vez al día y aprende algo de un oficio.
## - Escuela (solar e3): el edificio está, pero no hay alumnos hasta que haya niños (V9).
## - Mercado (miércoles, 8–13 h): las tiendas con género de sobra montan un puesto en la plaza; los vecinos libres
##   se acercan a comprar algo y a charlar. Si nadie tiene de sobra, no hay mercado.
## - Taller de Reparaciones (solar e5, oficio TINKER): cada día, si un negocio sigue saboteado y su dueño puede
##   pagar, el arreglador gasta un kit y le quita un día de avería.
## Estado en `vm.culture_state` (se guarda). Nombres provisionales (docs/APORTES_CREATIVOS.md).

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const VillageTrades = preload("res://scripts/systems/VillageTrades.gd")
const VillageFame = preload("res://scripts/systems/VillageFame.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")

const LIBRARY_LOT: String = "n5"
const SCHOOL_LOT: String = "e3"
const LIBRARY_TITLE: String = "📚 Biblioteca"
const SCHOOL_TITLE: String = "🏫 Escuela"
const READ_SKILLS: Array = ["cooking", "alchemy", "medicine", "animals", "crafting"]
const READ_XP: int = 12
const MARKET_WEEKDAY: int = 2 # Miércoles
const MARKET_OPEN: int = 8
const MARKET_CLOSE: int = 13
const MARKET_MIN_STOCK: int = 8 # Solo monta puesto quien tiene género de sobra
const MARKET_SPOTS: Array = [Vector2(422, 26), Vector2(508, 26), Vector2(522, 52), Vector2(488, 46)]
const MARKET_VISIT_CHANCE: float = 0.25
const REPAIR_PRICE: int = 8
const REPAIRS_PER_DAY: int = 2
const GRID_REPAIR_REWARD: int = 12
const SAPLING_COST: int = 6
const ROUTE_CHARTER_COST: int = 25

static func state(vm) -> Dictionary:
	if not vm.culture_state is Dictionary:
		vm.culture_state = {}
	var defs: Dictionary = {"readings": 0, "player_read_day": -1, "market_day": -1, "market_sellers": {}, "market_sales": 0,
		"markets_held": 0, "repairs": 0, "grid": {}, "forest": {}, "trade_routes": {}}
	for k in defs.keys():
		if not vm.culture_state.has(k):
			vm.culture_state[k] = defs[k]
	return vm.culture_state

static func forest_state(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	if not (st.get("forest", null) is Dictionary):
		st["forest"] = {}
	var f: Dictionary = st["forest"]
	for k in ["planted_trees", "soil_fertility"]:
		if not f.has(k):
			f[k] = 0
	if not f.has("last_plant_day"):
		f["last_plant_day"] = -99
	return f

static func plant_forest_tree(vm, planter_name: String = "Jugador") -> bool:
	if vm == null:
		return false
	var eco = vm.get_tree().get_first_node_in_group("ecosystem_manager") if vm.is_inside_tree() else null
	if eco != null and eco.has_method("plant_sapling"):
		eco.plant_sapling()
	var f: Dictionary = forest_state(vm)
	f["planted_trees"] = int(f.get("planted_trees", 0)) + 1
	f["soil_fertility"] = mini(10, int(f.get("soil_fertility", 0)) + 2)
	f["last_plant_day"] = int(WorldClock.current_day) if WorldClock else 1
	VillageChronicle.add(vm, "reforest", "%s sembró un pino joven en el bosque, enriqueciendo el suelo y atrayendo fauna" % planter_name, true)
	return true

static func trade_routes_of(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	if not (st.get("trade_routes", null) is Dictionary):
		st["trade_routes"] = {}
	var tr: Dictionary = st["trade_routes"]
	var route_defs: Dictionary = {
		"high_pass": {
			"name": "Paso Alto (Minas del Norte)",
			"exports": "bread", "export_qty": 2,
			"imports": "iron_ore", "import_qty": 2,
			"seller_role": "baker", "buyer_role": "tinker",
			"balance": 90, "tariff_gold": 8, "active": false, "last_ship_day": -99,
		},
		"river_port": {
			"name": "Puerto Fluvial del Este",
			"exports": "wood", "export_qty": 2,
			"imports": "fish", "import_qty": 2,
			"seller_role": "woodcutter", "buyer_role": "farmer",
			"balance": 90, "tariff_gold": 8, "active": false, "last_ship_day": -99,
		},
		"sun_plain": {
			"name": "Vega del Sol",
			"exports": "clothes", "export_qty": 1,
			"imports": "wheat", "import_qty": 3,
			"seller_role": "tailor", "buyer_role": "baker",
			"balance": 90, "tariff_gold": 10, "active": false, "last_ship_day": -99,
		},
	}
	for r_id in route_defs.keys():
		if not (tr.get(r_id, null) is Dictionary):
			tr[r_id] = (route_defs[r_id] as Dictionary).duplicate()
	return tr

static func open_trade_route(vm, route_id: String, inv = null) -> bool:
	if vm == null:
		return false
	var routes: Dictionary = trade_routes_of(vm)
	if not routes.has(route_id):
		return false
	var r: Dictionary = routes[route_id]
	if bool(r.get("active", false)):
		return false
	if inv != null:
		if int(inv.gold) < ROUTE_CHARTER_COST:
			return false
		inv.add_gold(-ROUTE_CHARTER_COST)
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + ROUTE_CHARTER_COST
	r["active"] = true
	routes[route_id] = r
	VillageChronicle.add(vm, "trade_route", "Se abrió la ruta comercial con %s" % str(r.get("name", route_id)), true)
	return true

static func send_player_shipment(vm, route_id: String, inv) -> bool:
	if vm == null or inv == null:
		return false
	var routes: Dictionary = trade_routes_of(vm)
	if not routes.has(route_id):
		return false
	var r: Dictionary = routes[route_id]
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	if not bool(r.get("active", false)) or int(r.get("last_ship_day", -99)) == today:
		return false
	var exp_item: String = str(r.get("exports", "wood"))
	var exp_qty: int = int(r.get("export_qty", 2))
	var imp_item: String = str(r.get("imports", "fish"))
	var imp_qty: int = int(r.get("import_qty", 2))
	var pay: int = int(r.get("tariff_gold", 8))
	if int(inv.items.get(exp_item, 0)) < exp_qty or int(r.get("balance", 0)) < pay:
		return false
	inv.remove_item(exp_item, exp_qty)
	inv.add_item(imp_item, imp_qty)
	r["balance"] = int(r.get("balance", 0)) - pay
	r["last_ship_day"] = today
	inv.add_gold(pay)
	routes[route_id] = r
	return true

static func process_trade_routes(vm) -> int:
	if vm == null:
		return 0
	var routes: Dictionary = trade_routes_of(vm)
	var exchanged: int = 0
	for r_id in routes.keys():
		var r: Dictionary = routes[r_id]
		if not bool(r.get("active", false)):
			continue
		var pay: int = int(r.get("tariff_gold", 8))
		if int(r.get("balance", 0)) < pay:
			continue
		var seller = vm.trade_npcs.get(VillageTrades.role_of(str(r.get("seller_role", "woodcutter"))))
		var buyer = vm.trade_npcs.get(VillageTrades.role_of(str(r.get("buyer_role", "farmer"))))
		if seller == null or not is_instance_valid(seller) or seller.is_dead:
			continue
		var exp_item: String = str(r.get("exports", "wood"))
		var exp_qty: int = int(r.get("export_qty", 2))
		if int(seller.shop_stock.get(exp_item, 0)) < exp_qty:
			continue
		seller.shop_stock[exp_item] = int(seller.shop_stock.get(exp_item, 0)) - exp_qty
		seller._sync_shop_stock_to_vm()
		var imp_item: String = str(r.get("imports", "fish"))
		var imp_qty: int = int(r.get("import_qty", 2))
		var dst = buyer if (buyer != null and is_instance_valid(buyer) and not buyer.is_dead) else seller
		dst.shop_stock[imp_item] = int(dst.shop_stock.get(imp_item, 0)) + imp_qty
		dst._sync_shop_stock_to_vm()
		r["balance"] = int(r.get("balance", 0)) - pay
		seller.personal_gold = maxi(0, seller.personal_gold) + (pay - 2)
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + 2
		routes[r_id] = r
		exchanged += 1
	return exchanged

static func grid_state(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	if not (st.get("grid", null) is Dictionary):
		st["grid"] = {}
	var g: Dictionary = st["grid"]
	var g_defs: Dictionary = {
		"sabotaged_days": 0,
		"overloaded_node": "",
		"last_op_day": -99,
		"lamps_disabled": false,
		"sprinkler_disabled": false,
	}
	for k in g_defs.keys():
		if not g.has(k):
			g[k] = g_defs[k]
	return g

static func is_grid_sabotaged(vm) -> bool:
	if vm == null:
		return false
	var g: Dictionary = grid_state(vm)
	return int(g.get("sabotaged_days", 0)) > 0 or bool(g.get("lamps_disabled", false)) or bool(g.get("sprinkler_disabled", false))

static func is_lamps_powered(vm) -> bool:
	if vm == null:
		return false
	var g: Dictionary = grid_state(vm)
	return not bool(g.get("lamps_disabled", false))

static func is_sprinkler_powered(vm) -> bool:
	if vm == null:
		return false
	var g: Dictionary = grid_state(vm)
	return not bool(g.get("sprinkler_disabled", false))

static func sabotage_grid(vm, node_target: String = "all", check_risk: bool = false) -> Dictionary:
	if vm == null:
		return {"ok": false, "caught": false}
	var g: Dictionary = grid_state(vm)
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	g["last_op_day"] = today
	if check_risk and randf() < 0.30:
		vm.wanted_level = clampi(int(vm.wanted_level) + 1, 1, 5)
		return {"ok": false, "caught": true}
	var target: String = node_target if node_target in ["all", "lamps", "sprinkler"] else "all"
	g["overloaded_node"] = target
	if target == "all":
		g["sabotaged_days"] = 2
		g["lamps_disabled"] = true
		g["sprinkler_disabled"] = true
	elif target == "lamps":
		g["sabotaged_days"] = maxi(1, int(g.get("sabotaged_days", 0)))
		g["lamps_disabled"] = true
	elif target == "sprinkler":
		g["sabotaged_days"] = maxi(1, int(g.get("sabotaged_days", 0)))
		g["sprinkler_disabled"] = true
	if GameManager != null and bool(g.get("lamps_disabled", false)):
		GameManager.set_flag("electric_grid_active", false)
	if GameManager != null:
		GameManager.set_flag("sprinkler_grid_disabled", bool(g.get("sprinkler_disabled", false)))
	vm._update_streetlights_glow()
	var desc_map: Dictionary = {
		"all": "el generador general",
		"lamps": "el circuito de farolas",
		"sprinkler": "la bomba eléctrica de riego",
	}
	VillageChronicle.add(vm, "grid_sabotage", "Alguien saboteó %s: saltaron chispas en el tendido eléctrico" % str(desc_map.get(target, "la red")), true)
	return {"ok": true, "caught": false, "target": target}

static func repair_grid(vm) -> bool:
	if vm == null:
		return false
	var g: Dictionary = grid_state(vm)
	g["sabotaged_days"] = 0
	g["overloaded_node"] = ""
	g["lamps_disabled"] = false
	g["sprinkler_disabled"] = false
	if GameManager != null:
		GameManager.set_flag("electric_grid_active", true)
		GameManager.set_flag("sprinkler_grid_disabled", false)
	vm._update_streetlights_glow()
	return true

static func library_pos() -> Vector2:
	return VillageLots.building_center(LIBRARY_LOT)

static func reading_spot() -> Vector2:
	return library_pos() + Vector2(0, -16 if bool(VillageLots.lot_def(LIBRARY_LOT)["door_south"]) else 16)

# ---------------------------------------------------------------- mapa
static func ensure_lots(vm) -> void:
	for e in [[LIBRARY_LOT, "library", LIBRARY_TITLE], [SCHOOL_LOT, "school", SCHOOL_TITLE]]:
		var st: Dictionary = VillageLots.lot(vm, e[0])
		st["status"] = "built"
		st["kind"] = e[1]
		st["progress"] = 1.0
		st["title"] = e[2]

static func build(vm, id: String, st: Dictionary) -> void:
	var d: Dictionary = VillageLots.lot_def(id)
	var c: Vector2 = VillageLots.building_center(id)
	var props: String = "res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/"
	var m: float = -1.0 if bool(d["door_south"]) else 1.0
	vm._construct_solid_building("building_" + str(st["kind"]), str(st["title"]), c, Vector2(128, 96), bool(d["door_south"]),
		"res://assests/world/village/floor_wood_planks.png", "res://assests/world/village/wall_timber_h.png",
		"res://assests/world/village/wall_timber_v.png", 42.0, 0.0, Color(0.86, 0.92, 1.0))
	match str(st["kind"]):
		"library":
			for sx in [-40, -14, 14, 40]: # Estanterías al fondo
				vm._add_rect_poly(c + Vector2(sx, 34 * m), Vector2(11, 4), Color(0.42, 0.26, 0.14, 1.0), -1)
				vm._add_rect_poly(c + Vector2(sx, 31 * m), Vector2(9, 1.5), Color(0.75, 0.30, 0.25, 1.0), 0)
			vm._spawn_decor_prop(props + "table_chairs_1.png", reading_spot(), Vector2(0.45, 0.45))
			vm._add_title_label(reading_spot() + Vector2(-50, -22), Vector2(100, 12), "📖 Leer un rato [E]", Color(0.9, 0.95, 1.0), 7)
		"school":
			for p in [Vector2(-30, 6), Vector2(0, 6), Vector2(30, 6), Vector2(-30, 26), Vector2(0, 26), Vector2(30, 26)]:
				vm._add_rect_poly(c + Vector2(p.x, p.y * m), Vector2(9, 5), Color(0.55, 0.38, 0.20, 1.0), -1) # Pupitres
			vm._add_rect_poly(c + Vector2(0, -26 * m), Vector2(30, 3), Color(0.15, 0.25, 0.18, 1.0), -1) # Pizarra
			vm.set_meta("school_sign", vm._add_title_label(c + Vector2(-80, 38 * m - 6), Vector2(160, 12), "Esperando alumnos", Color(0.8, 0.8, 0.8), 7)) # V9 lo actualiza

# ---------------------------------------------------------------- biblioteca
## VillagePlaces: alguien ha llegado a la biblioteca.
static func on_read(vm, n) -> void:
	var st: Dictionary = state(vm)
	st["readings"] = int(st["readings"]) + 1
	n.add_thought("Leí un rato en la biblioteca (+3)", 3.0)
	n.set_meta("read_day", int(WorldClock.current_day) if WorldClock else 1) # M16 «Lo que se lee de noche»

## El jugador pulsa E cerca de la mesa de lectura. Devuelve true si la interacción era suya.
static func try_interact(vm, player, pos: Vector2) -> bool:
	if VillageLots.lot(vm, LIBRARY_LOT).get("kind", "") != "library" or pos.distance_to(reading_spot()) > 26.0:
		return false
	var st: Dictionary = state(vm)
	var day: int = int(WorldClock.current_day) if WorldClock else 0
	if int(st["player_read_day"]) == day:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("📖 Hoy ya has leído bastante", Color.LIGHT_GRAY, -40.0)
		return true
	st["player_read_day"] = day
	st["readings"] = int(st["readings"]) + 1
	var skill: String = str(READ_SKILLS.pick_random())
	if player.has_method("add_skill_xp"):
		player.add_skill_xp(skill, READ_XP)
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("📖 Lees un buen rato y aprendes algo (+%d %s)" % [READ_XP, skill], Color.LIGHT_SKY_BLUE, -40.0)
	return true

# ---------------------------------------------------------------- mercado
static func is_market_day() -> bool:
	return WorldClock != null and WorldClock.has_method("get_weekday") and int(WorldClock.get_weekday()) == MARKET_WEEKDAY

static func is_market_open(vm) -> bool:
	return not (state(vm)["market_sellers"] as Dictionary).is_empty()

static func _surplus(n) -> int:
	var best: int = 0
	for k in n.shop_stock.keys():
		best = maxi(best, int(n.shop_stock[k]))
	return best

## 8 h del miércoles: quien tiene género de sobra baja a la plaza (primero los de las afueras, que no tienen
## clientela de paso).
static func open_market(vm) -> int:
	var st: Dictionary = state(vm)
	if is_market_open(vm):
		return 0
	var cands: Array = []
	for r in VillageNPC.SHOP_ROLES:
		var n = vm.trade_npcs.get(r)
		if n == null or not is_instance_valid(n) or n.is_dead or n.is_downed or n.sick_level >= 2 or vm.is_trade_sabotaged(int(r)):
			continue
		if _surplus(n) >= MARKET_MIN_STOCK and not n in cands: # Quien lleva dos negocios monta un solo puesto
			cands.append(n)
	if cands.is_empty():
		return 0
	cands.sort_custom(func(a, b): return a.work_position.distance_to(MARKET_SPOTS[0]) > b.work_position.distance_to(MARKET_SPOTS[0]))
	var sellers: Dictionary = {}
	for i in range(mini(cands.size(), MARKET_SPOTS.size())):
		var n = cands[i]
		var spot: Vector2 = MARKET_SPOTS[i]
		sellers[n.get_person_key()] = {"x": n.work_position.x, "y": n.work_position.y, "spot": i}
		n.work_position = spot
		n.add_thought("Hoy monto puesto en el mercado (+3)", 3.0)
	st["market_sellers"] = sellers
	st["market_day"] = int(WorldClock.current_day) if WorldClock else 0
	st["markets_held"] = int(st["markets_held"]) + 1
	_draw_market(vm)
	return sellers.size()

static func close_market(vm) -> void:
	var st: Dictionary = state(vm)
	for n in _all_npcs(vm):
		var e = (st["market_sellers"] as Dictionary).get(n.get_person_key())
		if e != null:
			n.work_position = Vector2(float(e["x"]), float(e["y"]))
		if n.errand_kind == "market":
			n.end_errand()
	st["market_sellers"] = {}
	_clear_market(vm)

static func _draw_market(vm) -> void:
	_clear_market(vm)
	var cap: Dictionary = VillageLots._capture_begin(vm)
	for e in (state(vm)["market_sellers"] as Dictionary).values():
		var p: Vector2 = MARKET_SPOTS[int(e["spot"])]
		vm._add_rect_poly(p + Vector2(0, -10), Vector2(14, 4), Color(0.55, 0.36, 0.18, 1.0), -1) # Mesa
		vm._add_rect_poly(p + Vector2(0, -16), Vector2(15, 2), Color(0.85, 0.25, 0.22, 0.95), 0) # Toldo
	vm._add_title_label(Vector2(405, -4), Vector2(120, 12), "🧺 Mercado del Miércoles", Color(1.0, 0.9, 0.6), 7)
	vm.set_meta("market_nodes", VillageLots._capture_end(vm, cap)[0])

static func _clear_market(vm) -> void:
	for nd in vm.get_meta("market_nodes", []):
		if is_instance_valid(nd):
			nd.queue_free()
	vm.set_meta("market_nodes", [])

static func _sellers(vm) -> Array:
	var out: Array = []
	var sellers: Dictionary = state(vm)["market_sellers"]
	for n in _all_npcs(vm):
		if sellers.has(n.get_person_key()) and not n.is_dead:
			out.append(n)
	return out

static func _all_npcs(vm) -> Array:
	return vm.get_tree().get_nodes_in_group("village_npcs").filter(func(n): return n is VillageNPC and is_instance_valid(n))

static func on_hour(vm, hour: int) -> void:
	if hour == MARKET_OPEN and is_market_day():
		open_market(vm)
	elif hour >= MARKET_CLOSE and is_market_open(vm):
		close_market(vm)
		return
	if not is_market_open(vm) or hour >= MARKET_CLOSE - 1:
		return
	var sellers: Array = _sellers(vm)
	for n in VillageNeeds.living(vm):
		if n in sellers or not VillageNeeds.is_free(n) or n.personal_gold < 6 or randf() >= MARKET_VISIT_CHANCE:
			continue
		var s = sellers.pick_random()
		n.start_errand("market", s.work_position + Vector2(randf_range(-10, 10), 16))

## VillageNeeds.tick: un vecino llega al mercado; compra algo al puesto más cercano y charla con el vendedor.
static func on_market_arrived(vm, n) -> void:
	n.end_errand()
	var seller = null
	var best: float = INF
	for s in _sellers(vm):
		var d: float = n.global_position.distance_to(s.global_position)
		if d < best:
			best = d
			seller = s
	if seller == null or best > 80.0:
		return
	var item: String = ""
	for k in seller.shop_stock.keys():
		if int(seller.shop_stock[k]) > 0 and (item == "" or int(seller.shop_stock[k]) > int(seller.shop_stock[item])):
			item = str(k)
	var price: int = 7 if (VillageFame.is_master(vm, seller) and n.personal_gold >= 25) else 5
	if item == "" or n.personal_gold < price:
		return
	n.personal_gold -= price
	seller.personal_gold = maxi(0, seller.personal_gold) + price
	seller.shop_stock[item] = int(seller.shop_stock[item]) - 1
	seller._sync_shop_stock_to_vm()
	if VillageFame.is_master(vm, seller):
		VillageFame.add_fame(vm, seller, 1, "Su puesto de autor triunfa en el mercado")
	var fam: String = str(n.family_id) if "family_id" in n else ""
	if fam != "" and vm.house_pantry.has(fam) and _is_food(item):
		vm.house_pantry[fam] = int(vm.house_pantry[fam]) + 1
	n.add_thought("Compré en el mercado (+3)", 3.0)
	n.modify_npc_relationship(seller, 2, "Le compré en el mercado", true)
	state(vm)["market_sales"] = int(state(vm)["market_sales"]) + 1

static func _is_food(item: String) -> bool:
	return item in ["bread", "country_stew", "cooked_meat", "raw_meat", "fish", "wheat", "carrot", "cabbage"]

## Al cargar: si la partida se guardó con el mercado montado, cada vendedor vuelve a su tienda.
static func after_load(vm) -> void:
	if is_market_open(vm):
		close_market(vm)

# ---------------------------------------------------------------- arreglos
## Cada día: rutas comerciales, fertilidad forestal y arreglos del Taller de Reparaciones.
static func daily(vm) -> int:
	process_trade_routes(vm)
	var f_st: Dictionary = forest_state(vm)
	if int(f_st.get("soil_fertility", 0)) >= 2:
		f_st["soil_fertility"] = maxi(0, int(f_st.get("soil_fertility", 0)) - 1)
		var wc = vm.trade_npcs.get(VillageTrades.role_of("woodcutter"))
		if wc != null and is_instance_valid(wc) and not wc.is_dead:
			wc.shop_stock["wood"] = int(wc.shop_stock.get("wood", 0)) + 1
			wc._sync_shop_stock_to_vm()
		var frm = vm.trade_npcs.get(VillageTrades.role_of("farmer"))
		if frm != null and is_instance_valid(frm) and not frm.is_dead:
			frm.shop_stock["wheat"] = int(frm.shop_stock.get("wheat", 0)) + 1
			frm._sync_shop_stock_to_vm()
	var tinker = vm.trade_npcs.get(VillageTrades.role_of("tinker"))
	if tinker == null or not is_instance_valid(tinker) or tinker.is_dead or tinker.is_downed or vm.is_trade_sabotaged(VillageTrades.role_of("tinker")):
		return 0
	var done: int = 0
	var g: Dictionary = grid_state(vm)
	if int(g.get("sabotaged_days", 0)) > 0 and int(tinker.shop_stock.get("repair_kit", 0)) > 0 and int(vm.town_state.get("treasury", 0)) >= REPAIR_PRICE:
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - REPAIR_PRICE
		tinker.personal_gold = maxi(0, tinker.personal_gold) + REPAIR_PRICE
		tinker.shop_stock["repair_kit"] = int(tinker.shop_stock["repair_kit"]) - 1
		tinker._sync_shop_stock_to_vm()
		g["sabotaged_days"] = maxi(0, int(g.get("sabotaged_days", 0)) - 1)
		if int(g["sabotaged_days"]) <= 0:
			repair_grid(vm)
		done += 1
	for r in vm.shop_businesses.keys():
		if done >= REPAIRS_PER_DAY or int(tinker.shop_stock.get("repair_kit", 0)) <= 0:
			break
		var biz: Dictionary = vm.shop_businesses[r]
		if int(r) == int(tinker.trade_role) or int(biz.get("sabotaged_days", 0)) <= 0:
			continue
		var owner = vm.trade_npcs.get(r)
		if owner == null or not is_instance_valid(owner) or owner.is_dead or owner.personal_gold < REPAIR_PRICE:
			continue
		owner.personal_gold -= REPAIR_PRICE
		tinker.personal_gold = maxi(0, tinker.personal_gold) + REPAIR_PRICE
		tinker.shop_stock["repair_kit"] = int(tinker.shop_stock["repair_kit"]) - 1
		tinker._sync_shop_stock_to_vm()
		biz["sabotaged_days"] = maxi(0, int(biz["sabotaged_days"]) - 1)
		vm._refresh_shop_stall_visual(int(r))
		owner.add_thought("El arreglador me dejó el puesto mejor (+3)", 3.0)
		owner.modify_npc_relationship(tinker, 2, "Me arregló el puesto", true)
		done += 1
	state(vm)["repairs"] = int(state(vm)["repairs"]) + done
	return done

static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null:
		return
	var role_i: int = int(npc.trade_role)
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	if role_i == int(VillageNPC.TradeRole.TINKER):
		var g: Dictionary = grid_state(vm)
		if int(g.get("last_op_day", -99)) != today:
			ch_arr.append({"label": "⚡🔧 Manipular a escondidas el cuadro eléctrico (1/día, riesgo de chispazo)", "next": "culture_grid_menu"})
			diag["culture_grid_menu"] = {
				"text": "«Mientras el arreglador mira hacia otro lado, ves los tres interruptores de cobre del tendido del pueblo...»",
				"choices": [
					{"label": "🌑 Cortar el circuito de farolas (Calles a oscuras)", "next": "END", "action": "culture_sabotage_grid:lamps"},
					{"label": "🥀 Cortar la bomba eléctrica de riego (Secar aspersor)", "next": "END", "action": "culture_sabotage_grid:sprinkler"},
					{"label": "💥 Cortocircuitar el generador general (Apagón 2 días)", "next": "END", "action": "culture_sabotage_grid:all"},
					{"label": "⬅️ Volver", "next": "start"},
				]
			}
		if is_grid_sabotaged(vm):
			ch_arr.append({"label": "🛠️⚡ Ayudar a reparar el tendido eléctrico (-1 Bobina de Cobre, +%d Oro del arca)" % GRID_REPAIR_REWARD, "next": "END", "action": "culture_repair_grid"})
	if role_i == int(VillageNPC.TradeRole.WOODCUTTER):
		ch_arr.append({"label": "🌲🌱 Sembrar pino joven en el bosque (-1 Semilla de Cultivo, enriquece suelo y fauna)", "next": "END", "action": "culture_plant_tree"})
		ch_arr.append({"label": "🌲🪙 Comprar y plantar plantón de pino (-%d Oro al leñador, enriquece suelo y fauna)" % SAPLING_COST, "next": "END", "action": "culture_buy_sapling"})
	if role_i in [int(VillageNPC.TradeRole.TRAVELING_MERCHANT), int(VillageNPC.TradeRole.WOODCUTTER), int(VillageNPC.TradeRole.BAKER), int(VillageNPC.TradeRole.TAILOR)]:
		var routes: Dictionary = trade_routes_of(vm)
		var r_choices: Array = []
		for r_id in routes.keys():
			var r: Dictionary = routes[r_id]
			var r_name: String = str(r.get("name", r_id))
			if not bool(r.get("active", false)):
				r_choices.append({"label": "📜 Abrir ruta comercial con %s (-%d Oro de arancel municipal)" % [r_name, ROUTE_CHARTER_COST], "next": "END", "action": "culture_open_route:" + str(r_id)})
			elif int(r.get("last_ship_day", -99)) != today:
				r_choices.append({"label": "📦 Enviar remesa a %s (-%d %s → +%d %s y +%d Oro)" % [r_name, int(r["export_qty"]), str(r["exports"]), int(r["import_qty"]), str(r["imports"]), int(r["tariff_gold"])], "next": "END", "action": "culture_ship_route:" + str(r_id)})
		r_choices.append({"label": "⬅️ Volver", "next": "start"})
		ch_arr.append({"label": "🗺️📦 Rutas comerciales con otros asentamientos", "next": "culture_routes_menu"})
		diag["culture_routes_menu"] = {
			"text": "«Las caravanas regulares conectan nuestro valle con los asentamientos vecinos y traen suministros a cambio de nuestros excedentes.»",
			"choices": r_choices,
		}

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	if action_id.begins_with("culture_sabotage_grid:"):
		var g: Dictionary = grid_state(vm)
		var today: int = int(WorldClock.current_day) if WorldClock else 1
		if int(g.get("last_op_day", -99)) == today:
			npc._spawn_floating_text("⚡ Hoy ya manipulaste el cuadro eléctrico", Color.LIGHT_GRAY, -44.0)
			return
		var target: String = action_id.substr("culture_sabotage_grid:".length())
		var res: Dictionary = sabotage_grid(vm, target, true)
		if bool(res.get("caught", false)):
			npc.affinity = clampi(npc.affinity - 15, -100, 100)
			npc._spawn_floating_text("🚨 «¡Eh! ¡Suelta esos cables! ¡Guardias!» (Búsqueda +1)", Color.ORANGE_RED, -46.0)
		else:
			npc._spawn_floating_text("⚡💥 ¡Chispazo! Saboteaste el nodo eléctrico (%s)" % target, Color.CYAN, -46.0)
	elif action_id == "culture_repair_grid":
		if inv == null or int(inv.items.get("copper_coil", 0)) <= 0:
			npc._spawn_floating_text("«Necesitamos al menos 1 Bobina de Cobre para empalmar la línea.»", Color.ORANGE_RED, -46.0)
			return
		inv.remove_item("copper_coil", 1)
		repair_grid(vm)
		var pay: int = mini(GRID_REPAIR_REWARD, maxi(0, int(vm.town_state.get("treasury", 0))))
		if pay > 0:
			vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - pay
			inv.add_gold(pay)
		npc.affinity = clampi(npc.affinity + 10, -100, 100)
		npc._spawn_floating_text("🛠️⚡ «¡Línea restablecida! Toma %d de oro del fondo municipal.»" % pay, Color.AQUAMARINE, -46.0)
	elif action_id == "culture_plant_tree":
		if inv == null or int(inv.items.get("crop_seeds", 0)) <= 0:
			npc._spawn_floating_text("«Necesitas al menos 1 Semilla de Cultivo para plantar un pino joven.»", Color.ORANGE_RED, -46.0)
			return
		inv.remove_item("crop_seeds", 1)
		plant_forest_tree(vm, "El forastero")
		npc.affinity = clampi(npc.affinity + 6, -100, 100)
		npc._spawn_floating_text("🌲🌱 «¡Buen ojo! Ese pino dará sombra, setas y cobijo a los venados.»", Color.SPRING_GREEN, -46.0)
	elif action_id == "culture_buy_sapling":
		if inv == null or int(inv.gold) < SAPLING_COST:
			npc._spawn_floating_text("«Necesito %d de oro por el plantón de vivero.»" % SAPLING_COST, Color.ORANGE_RED, -46.0)
			return
		inv.add_gold(-SAPLING_COST)
		npc.personal_gold += SAPLING_COST
		plant_forest_tree(vm, npc.npc_name)
		npc.affinity = clampi(npc.affinity + 6, -100, 100)
		npc._spawn_floating_text("🌲🌱 «Lo plantaremos en el claro sur. El bosque te lo agradecerá.»", Color.SPRING_GREEN, -46.0)
	elif action_id.begins_with("culture_open_route:"):
		var r_id: String = action_id.substr("culture_open_route:".length())
		if open_trade_route(vm, r_id, inv):
			npc.affinity = clampi(npc.affinity + 8, -100, 100)
			npc._spawn_floating_text("🗺️📜 ¡Ruta comercial abierta! Las caravanas ya cruzan el paso", Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("«Necesitas %d de oro para pagar la carta de arancel municipal.»" % ROUTE_CHARTER_COST, Color.ORANGE_RED, -46.0)
	elif action_id.begins_with("culture_ship_route:"):
		var r_id2: String = action_id.substr("culture_ship_route:".length())
		if send_player_shipment(vm, r_id2, inv):
			npc._spawn_floating_text("📦🪙 ¡Remesa enviada y mercancía importada recibida!", Color.AQUAMARINE, -46.0)
		else:
			npc._spawn_floating_text("«No tienes la mercancía requerida o hoy ya enviaste una remesa por esta ruta.»", Color.ORANGE_RED, -46.0)
