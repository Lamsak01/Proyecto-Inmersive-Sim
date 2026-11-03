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

static func state(vm) -> Dictionary:
	if not vm.culture_state is Dictionary:
		vm.culture_state = {}
	var defs: Dictionary = {"readings": 0, "player_read_day": -1, "market_day": -1, "market_sellers": {}, "market_sales": 0,
		"markets_held": 0, "repairs": 0}
	for k in defs.keys():
		if not vm.culture_state.has(k):
			vm.culture_state[k] = defs[k]
	return vm.culture_state

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
	var price: int = 5
	if item == "" or n.personal_gold < price:
		return
	n.personal_gold -= price
	seller.personal_gold = maxi(0, seller.personal_gold) + price
	seller.shop_stock[item] = int(seller.shop_stock[item]) - 1
	seller._sync_shop_stock_to_vm()
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
## Cada día: el arreglador acude a los negocios saboteados cuyo dueño puede pagar.
static func daily(vm) -> int:
	var tinker = vm.trade_npcs.get(VillageTrades.role_of("tinker"))
	if tinker == null or not is_instance_valid(tinker) or tinker.is_dead or tinker.is_downed or vm.is_trade_sabotaged(VillageTrades.role_of("tinker")):
		return 0
	var done: int = 0
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
