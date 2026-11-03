@tool
extends RefCounted

## V5c: terceros espacios (ni casa ni trabajo): el parque, los bancos de la plaza y el mirador del lago.
## - En su tiempo libre (al salir del trabajo y los fines de semana) algunos vecinos van a pasar un rato. Va más quien
##   es sociable o se siente solo; con lluvia, casi nadie sale.
## - Quien coincide en el mismo sitio charla: se conocen mejor, se cuentan chismes y, si se llevan mal, se rozan.
## - Las quedadas (SocialDirector) también usan estos sitios.
## Nada está programado: cada hora cada uno decide según su humor, sus rasgos, el tiempo y si está libre.
## Nombres provisionales (docs/APORTES_CREATIVOS.md).

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

const PARK_RECT: Rect2 = Rect2(Vector2(184, 216), Vector2(240, 84))
const PLACES: Array = [
	{"id": "park_lawn", "kind": "park", "pos": Vector2(304, 262), "label": "el Parque del Roble", "text": "🌳 Paseando por el parque"},
	{"id": "park_bench", "kind": "bench", "pos": Vector2(232, 236), "label": "un banco del parque", "text": "🪑 Sentado en el parque"},
	{"id": "plaza_benches", "kind": "bench", "pos": Vector2(500, 74), "label": "los bancos de la plaza", "text": "🪑 Sentado en la plaza"},
	{"id": "lake_view", "kind": "overlook", "pos": Vector2(-65, 166), "label": "el Mirador del Lago", "text": "🌅 Mirando el lago"},
]
const LEISURE_FREE_HOURS: Vector2i = Vector2i(17, 21) # Entre semana, al salir del trabajo
const LEISURE_WEEKEND_HOURS: Vector2i = Vector2i(10, 21)
const STAY_HOURS: int = 1 # Cuánto se queda como poco (luego decide cada hora si sigue)
const CHAT_RADIUS: float = 46.0
const CHAT_REL: int = 2
const FRICTION_REL: int = -40 # Por debajo de esto, coincidir es incómodo
const GOSSIP_CHANCE: float = 0.5

static func place(id: String) -> Dictionary:
	for p in PLACES:
		if str(p["id"]) == id:
			return p
	return {}

static func state(vm) -> Dictionary:
	if not vm.places_state is Dictionary:
		vm.places_state = {}
	for k in ["visits", "chats", "gossip", "frictions"]:
		if not vm.places_state.has(k):
			vm.places_state[k] = 0
	return vm.places_state

# ---------------------------------------------------------------- mapa
static func build_world(vm) -> void:
	var dec: String = "res://assests/Comprados/Epic RPG World - The Village V2.1/"
	var bench: String = "res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/bench_0.png"
	# Parque: césped, borde, pinos, flores y bancos
	var r: Rect2 = PARK_RECT
	vm._add_poly(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), Color(0.30, 0.52, 0.26, 0.55), -4)
	var border := Line2D.new()
	border.width = 1.5
	border.default_color = Color(0.46, 0.36, 0.22, 0.8)
	border.points = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position])
	border.z_index = -3
	vm.entities_root.add_child(border)
	var tree: Texture2D = vm._load_tex(dec + "tilesets and props/props-sprites/pine-tree_0.png")
	for tp in [Vector2(200, 232), Vector2(410, 236), Vector2(270, 290), Vector2(380, 288)]:
		vm._add_sprite_prop(tree, tp, Vector2(0.7, 0.7), 0)
	for fp in [Vector2(304, 228), Vector2(250, 280), Vector2(350, 262)]:
		vm._spawn_decor_prop(dec + "buildings/Decorations_sprites/flowers_plants_0.png", fp, Vector2(0.5, 0.5))
	vm._spawn_decor_prop(bench, place("park_bench")["pos"] + Vector2(0, -8), Vector2(0.4, 0.4))
	vm._spawn_decor_prop(bench, Vector2(330, 236), Vector2(0.4, 0.4))
	vm._add_title_label(Vector2(224, 218), Vector2(160, 14), "🌳 Parque del Roble", Color(0.78, 0.96, 0.66), 8)
	# Bancos de la plaza
	vm._spawn_decor_prop(bench, place("plaza_benches")["pos"] + Vector2(0, -8), Vector2(0.4, 0.4))
	vm._spawn_decor_prop(bench, Vector2(440, 80), Vector2(0.4, 0.4))
	# Mirador del lago: barandilla de madera y un banco
	var lv: Vector2 = place("lake_view")["pos"]
	vm._add_rect_poly(lv + Vector2(0, -12), Vector2(36, 2), Color(0.50, 0.34, 0.18, 0.95), -1)
	for px in [-34, -12, 12, 34]:
		vm._add_rect_poly(lv + Vector2(px, -9), Vector2(1.5, 4), Color(0.42, 0.28, 0.14, 0.95), -1)
	vm._spawn_decor_prop(bench, lv + Vector2(0, -2), Vector2(0.4, 0.4))
	vm._add_title_label(lv + Vector2(-70, 8), Vector2(140, 14), "🌅 Mirador del Lago", Color(0.70, 0.88, 1.0), 7)

## Para las quedadas del SocialDirector.
static func hangout_spots() -> Array:
	var out: Array = []
	for p in PLACES:
		out.append({"id": p["id"], "pos": p["pos"], "kind": p["kind"], "label": p["label"]})
	return out

# ---------------------------------------------------------------- ocio
static func is_leisure_hour(hour: int) -> bool:
	var weekend: bool = WorldClock != null and WorldClock.has_method("is_weekend") and WorldClock.is_weekend()
	var span: Vector2i = LEISURE_WEEKEND_HOURS if weekend else LEISURE_FREE_HOURS
	if weekend and WorldClock.has_method("is_rite_day") and WorldClock.is_rite_day() and hour < 13:
		return false # Domingo por la mañana: el Oficio del Alba
	return hour >= span.x and hour < span.y

static func is_raining() -> bool:
	return WorldClock != null and int(WorldClock.current_weather) == 1

## Ganas de salir un rato ahora (0..1).
static func leisure_chance(n) -> float:
	var c: float = 0.08 + 0.12 * TraitCatalog.npc_tendency(n, "sociability")
	if float(n.need_social) < 50.0:
		c += 0.10
	if float(n.mood) < 30.0:
		c *= 0.6 # Muy decaído, se queda en casa
	if is_raining():
		c *= 0.15
	if VillageNeeds.class_of(n) == "mendigo":
		c *= 0.5
	return clampf(c, 0.0, 0.5)

static func pick_place(n) -> Dictionary:
	var best: Dictionary = {}
	var best_s: float = -INF
	var romantic: bool = n.person_profile != null and str(n.person_profile.partner_id) != ""
	for p in PLACES:
		var s: float = -n.global_position.distance_to(p["pos"]) / 120.0 + randf_range(0.0, 2.5)
		if str(p["kind"]) == "overlook" and (romantic or (n.person_profile != null and "Melancólico" in n.person_profile.personality)):
			s += 1.0
		if s > best_s:
			best_s = s
			best = p
	return best

static func on_hour(vm, hour: int) -> void:
	var now: int = VillageNeeds.total_hours()
	var people: Array = VillageNeeds.living(vm)
	# 1. Los que ya están: charlan con quien haya y deciden si siguen
	var at_place: Dictionary = {}
	for n in people:
		if n.errand_kind != "leisure":
			continue
		if not n.has_meta("leisure_since"):
			continue # Aún de camino
		if not is_leisure_hour(hour) or (now - int(n.get_meta("leisure_since")) >= STAY_HOURS and randf() < 0.5) or is_raining():
			_leave(n)
			continue
		var pid: String = str(n.get_meta("leisure_place", ""))
		if not at_place.has(pid):
			at_place[pid] = []
		at_place[pid].append(n)
	for pid in at_place.keys():
		_chat_round(vm, at_place[pid])
	# 2. Quién sale un rato
	if not is_leisure_hour(hour):
		return
	for n in people:
		if not VillageNeeds.is_free(n) or randf() >= leisure_chance(n):
			continue
		var p: Dictionary = pick_place(n)
		if p.is_empty():
			continue
		n.set_meta("leisure_place", str(p["id"]))
		if n.has_meta("leisure_since"):
			n.remove_meta("leisure_since")
		n.start_errand("leisure", (p["pos"] as Vector2) + Vector2(randf_range(-18, 18), randf_range(-6, 10)))

static func _leave(n) -> void:
	n.end_errand()
	for m in ["leisure_since", "leisure_place"]:
		if n.has_meta(m):
			n.remove_meta(m)

## VillageNeeds.tick: ha llegado. Se queda (el encargo no se cierra hasta que decida irse).
static func on_arrived(vm, n) -> void:
	if not n.has_meta("leisure_since"):
		n.set_meta("leisure_since", VillageNeeds.total_hours())
		state(vm)["visits"] = int(state(vm)["visits"]) + 1

## Quienes coinciden en un sitio charlan por parejas (una vez por hora).
static func _chat_round(vm, group: Array) -> void:
	var st: Dictionary = state(vm)
	for i in range(group.size()):
		for j in range(i + 1, group.size()):
			var a = group[i]
			var b = group[j]
			if a.global_position.distance_to(b.global_position) > CHAT_RADIUS:
				continue
			var rel: int = a.get_relationship_with_npc(b.get_person_key())
			if rel <= FRICTION_REL:
				a.modify_npc_relationship(b, -2, "Coincidimos en %s y fue incómodo" % str(place(str(a.get_meta("leisure_place", "")))["label"]), true)
				st["frictions"] = int(st["frictions"]) + 1
				continue
			a.modify_npc_relationship(b, CHAT_REL, "Charlamos un rato en %s" % str(place(str(a.get_meta("leisure_place", "")))["label"]), true)
			a.need_social = minf(100.0, float(a.need_social) + 12.0)
			b.need_social = minf(100.0, float(b.need_social) + 12.0)
			st["chats"] = int(st["chats"]) + 1
			if randf() < GOSSIP_CHANCE:
				var teller = a if randf() < 0.5 else b
				var res: Dictionary = vm.VillageSocialLife.spread_gossip(vm, teller, b if teller == a else a)
				if not res.is_empty():
					st["gossip"] = int(st["gossip"]) + 1

static func activity_text(n, arrived: bool) -> String:
	var p: Dictionary = place(str(n.get_meta("leisure_place", "")))
	if p.is_empty():
		return "🌳 Dando un paseo"
	return str(p["text"]) if arrived else "🚶 Yendo a %s" % str(p["label"])
