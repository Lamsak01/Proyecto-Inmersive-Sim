@tool
extends RefCounted

## V4: solares alrededor del pueblo donde se levantan edificios nuevos.
## - Cada solar tiene un sitio fijo en el mapa y una zona: "borde" (junto al pueblo), "afueras" (granjas, rancho,
##   cantera) o "apartado" (mansiones).
## - Una obra la paga alguien (un vecino, las arcas o quien llega) y la levanta el carpintero EN PERSONA: mientras
##   haya obra, su sitio de trabajo es el solar, y solo avanza las horas que de verdad trabaja allí. Si está enfermo,
##   preso, muerto o de expedición, la obra se para. Nada se construye solo ni por fecha.
## - Lo que se construye en cada solar se guarda en `vm.lots_state` y se vuelve a levantar al cargar.
## - V3 decidirá cuándo hace falta una casa; V5 añadirá más clases de edificio (`KINDS`).

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

const WORK_STATE: int = 0 # ActivityState.WORKING
const SITE_RADIUS: float = 50.0
const CARPENTER_SHARE: float = 0.4 # Lo que cobra el carpintero; el resto son materiales

## Solares. `door_south`: la puerta mira al sur (si no, al norte). Tamaños de terreno, no del edificio.
const LOTS: Array = [
	# Borde norte, en fila sobre una calle nueva detrás de la posada y las casas
	{"id": "n1", "zone": "borde", "center": Vector2(330, -420), "size": Vector2(130, 96), "door_south": true},
	{"id": "n2", "zone": "borde", "center": Vector2(470, -420), "size": Vector2(130, 96), "door_south": true},
	{"id": "n3", "zone": "borde", "center": Vector2(610, -420), "size": Vector2(130, 96), "door_south": true},
	{"id": "n4", "zone": "borde", "center": Vector2(760, -420), "size": Vector2(130, 96), "door_south": true},
	{"id": "n5", "zone": "borde", "center": Vector2(910, -420), "size": Vector2(130, 96), "door_south": true},
	# Borde este, a los dos lados del camino principal alargado
	{"id": "e1", "zone": "borde", "center": Vector2(1090, -36), "size": Vector2(130, 96), "door_south": true},
	{"id": "e2", "zone": "borde", "center": Vector2(1230, -36), "size": Vector2(130, 96), "door_south": true},
	{"id": "e3", "zone": "borde", "center": Vector2(1400, -36), "size": Vector2(130, 96), "door_south": true},
	{"id": "e4", "zone": "borde", "center": Vector2(1090, 140), "size": Vector2(130, 96), "door_south": false},
	{"id": "e5", "zone": "borde", "center": Vector2(1230, 140), "size": Vector2(130, 96), "door_south": false},
	# Afueras: campos al sur, entre el pueblo y el bosque, y la ladera del noroeste
	{"id": "s1", "zone": "afueras", "center": Vector2(-220, 470), "size": Vector2(230, 160), "door_south": false},
	{"id": "s2", "zone": "afueras", "center": Vector2(30, 470), "size": Vector2(230, 160), "door_south": false},
	{"id": "s3", "zone": "afueras", "center": Vector2(290, 470), "size": Vector2(230, 160), "door_south": false},
	{"id": "w1", "zone": "afueras", "center": Vector2(-230, -330), "size": Vector2(230, 160), "door_south": true},
	# Apartados: lejos del centro, para mansiones
	{"id": "f1", "zone": "apartado", "center": Vector2(1315, -440), "size": Vector2(250, 180), "door_south": true},
	{"id": "f2", "zone": "apartado", "center": Vector2(40, -560), "size": Vector2(250, 180), "door_south": true},
]

## Calles y sendas nuevas hacia los solares (también las dibuja el mapa).
const ROADS: Array = [
	Rect2(Vector2(270, -362), Vector2(720, 22)), # Calle norte
	Rect2(Vector2(660, -362), Vector2(24, 230)), # Enlace con la calle de las casas
	Rect2(Vector2(1010, 36), Vector2(470, 28)), # Camino principal hacia el este
	Rect2(Vector2(-240, -250), Vector2(20, 286)), # Senda a la ladera del noroeste
	Rect2(Vector2(-330, 362), Vector2(780, 20)), # Senda de los campos del sur
	Rect2(Vector2(1305, -350), Vector2(20, 386)), # Senda a la loma del este
	Rect2(Vector2(30, -470), Vector2(20, 506)), # Senda a la loma del norte
]

## Clases de edificio. `hours`: horas de trabajo del carpintero (a diligencia media). `beds`: camas para vecinos.
const KINDS: Dictionary = {
	"house": {"title": "Casa", "cost": 60, "hours": 24.0, "beds": 2, "zones": ["borde"]},
	"shop_house": {"title": "Tienda con vivienda", "cost": 90, "hours": 34.0, "beds": 2, "zones": ["borde"]}, # V5: `st.role` = oficio
}

static func state(vm) -> Dictionary:
	if typeof(vm.lots_state) != TYPE_DICTIONARY:
		vm.lots_state = {}
	return vm.lots_state

static func lot_def(id: String) -> Dictionary:
	for l in LOTS:
		if str(l["id"]) == id:
			return l
	return {}

static func lot(vm, id: String) -> Dictionary:
	var st: Dictionary = state(vm)
	if not st.has(id):
		st[id] = {"status": "empty", "kind": "", "progress": 0.0, "title": "", "payer": "", "beds": [], "residents": []}
	return st[id]

static func free_lots(vm, kind: String = "house") -> Array:
	var zones: Array = (KINDS.get(kind, {}) as Dictionary).get("zones", [])
	var out: Array = []
	for l in LOTS:
		if (zones.is_empty() or str(l["zone"]) in zones) and str(lot(vm, str(l["id"]))["status"]) == "empty":
			out.append(str(l["id"]))
	return out

static func active_site(vm) -> String:
	for l in LOTS:
		if str(lot(vm, str(l["id"]))["status"]) == "building":
			return str(l["id"])
	return ""

static func site_work_pos(id: String) -> Vector2:
	var d: Dictionary = lot_def(id)
	var off: float = float((d["size"] as Vector2).y) * 0.5 + 12.0
	return (d["center"] as Vector2) + Vector2(0, off if bool(d["door_south"]) else -off)

# ---------------------------------------------------------------- mapa
## Al montar el pueblo: calles nuevas hacia los solares del borde y un cartel en cada solar libre.
static func build_world(vm) -> void:
	var dirt := Color(0.46, 0.36, 0.24, 0.65)
	for r in ROADS:
		_road(vm, r, dirt)
	for l in LOTS:
		var id: String = str(l["id"])
		var st: Dictionary = lot(vm, id)
		_draw_lot(vm, id, st)

static func _road(vm, rect: Rect2, col: Color) -> void:
	vm._add_poly(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), col, -3)

## Dibuja lo que toque según el estado: cartel de solar libre, obra o edificio terminado. Lo creado se apunta para
## poder quitarlo al cargar otra partida.
static func _sig(st: Dictionary) -> String:
	return "%s|%s|%s" % [str(st.get("status", "")), str(st.get("kind", "")), str(st.get("role", ""))]

static func _draw_lot(vm, id: String, st: Dictionary) -> void:
	if vm._lot_visuals.has(id) and (vm._lot_visuals[id] as Array).size() > 2 and str(vm._lot_visuals[id][2]) == _sig(st):
		if str(st["status"]) == "building":
			_update_site_label(vm, id)
		return # Ya está dibujado así (p. ej. al cargar una partida con el mismo pueblo)
	var old_biz: Dictionary = {}
	if st.has("role") and vm.shop_businesses.has(int(st["role"])):
		old_biz = vm.shop_businesses[int(st["role"])]
	_clear_lot_visuals(vm, id)
	var d: Dictionary = lot_def(id)
	var c: Vector2 = d["center"]
	var sz: Vector2 = d["size"]
	var snap: Dictionary = _capture_begin(vm)
	match str(st["status"]):
		"empty":
			vm._add_poly(_rect_pts(c, sz), Color(0.40, 0.34, 0.22, 0.22), -4)
			vm._add_sprite_prop(vm._load_tex("res://assests/Comprados/Epic RPG World - The Village V2.1/buildings/Decorations_sprites/sign_1.png"), site_work_pos(id), Vector2(0.8, 0.8), -1)
			vm._add_title_label(site_work_pos(id) + Vector2(-60, -26), Vector2(120, 14), "📜 Solar libre", Color(0.86, 0.80, 0.62), 7)
		"building":
			vm._add_poly(_rect_pts(c, sz), Color(0.42, 0.32, 0.20, 0.45), -4)
			for off in [Vector2(-30, -10), Vector2(24, 8), Vector2(-6, 18)]:
				vm._spawn_decor_prop("res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/crates_0.png", c + off, Vector2(0.5, 0.5))
			var lbl: Label = vm._add_title_label(c + Vector2(-90, -sz.y * 0.5 - 4), Vector2(180, 14), "", Color(1.0, 0.82, 0.42), 8)
			lbl.name = "LotSiteLabel_" + id
			_update_site_label(vm, id)
		"built":
			_build_kind(vm, id, st)
	var rec: Array = _capture_end(vm, snap)
	rec.append(_sig(st))
	vm._lot_visuals[id] = rec
	if not old_biz.is_empty() and vm.shop_businesses.has(int(st["role"])):
		var nb: Dictionary = vm.shop_businesses[int(st["role"])]
		for k in old_biz.keys():
			if not k in ["stall_pos", "stall_sprite", "stall_label"]:
				nb[k] = old_biz[k] # Conserva dueño, caja, sabotaje y existencias al redibujar

static func _rect_pts(c: Vector2, sz: Vector2) -> PackedVector2Array:
	var h := sz * 0.5
	return PackedVector2Array([c - h, c + Vector2(h.x, -h.y), c + h, c + Vector2(-h.x, h.y)])

static func _build_kind(vm, id: String, st: Dictionary) -> void:
	var d: Dictionary = lot_def(id)
	var c: Vector2 = d["center"]
	match str(st["kind"]):
		"house":
			var tex_bed: Texture2D = vm._load_tex("res://assests/world/village/tavern_bed.png")
			var fam: String = "family_lot_" + id
			var beds: Array = _house_beds(id)
			var hc: Vector2 = c
			vm._construct_solid_building("house_" + fam, str(st["title"]), hc, Vector2(112, 78), bool(d["door_south"]),
				"res://assests/world/village/floor_wood_planks.png", "res://assests/world/village/wall_timber_h.png",
				"res://assests/world/village/wall_timber_v.png", 38.0, 0.0, Color(0.92, 0.88, 0.72))
			for b in beds:
				vm._add_sprite_prop(tex_bed, b, Vector2(1.12, 1.12), -1)
			vm._spawn_decor_prop("res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/table_chairs_1.png", hc + Vector2(0, -2), Vector2(0.45, 0.45))
			vm._spawn_house_chest(hc + Vector2(0, -24 if bool(d["door_south"]) else 24), "Cofre Familiar (" + str(st["title"]) + ")", fam)
		"shop_house":
			_build_shop_house(vm, id, st)
		"civic", "shelter", "inn":
			load("res://scripts/systems/VillageCivic.gd").build(vm, id, st)

## V5: tienda y vivienda en un solo edificio (como la Botica), con la puerta hacia la calle del solar.
## Posiciones relativas a la Botica (puerta al norte); con la puerta al sur se reflejan.
static func shop_house_layout(id: String) -> Dictionary:
	var d: Dictionary = lot_def(id)
	var c: Vector2 = d["center"]
	var m: float = -1.0 if bool(d["door_south"]) else 1.0
	var f := func(v: Vector2) -> Vector2: return c + Vector2(v.x, v.y * m)
	return {"work_pos": f.call(Vector2(0, -18)), "bed1_pos": f.call(Vector2(-36, 26)), "bed2_pos": f.call(Vector2(36, 26)),
		"table_pos": f.call(Vector2(0, 24)), "kin_work_pos": f.call(Vector2(-24, -14)), "stall_pos": f.call(Vector2(0, -10)),
		"chest_pos": f.call(Vector2(42, -26)), "wall_l": f.call(Vector2(-42, 4)), "wall_r": f.call(Vector2(42, 4))}

static func _build_shop_house(vm, id: String, st: Dictionary) -> void:
	var d: Dictionary = lot_def(id)
	var c: Vector2 = d["center"]
	var lay: Dictionary = shop_house_layout(id)
	var role: int = int(st["role"])
	var fam: String = str(st.get("family_id", "family_lot_" + id))
	vm._construct_solid_building("mixed_" + fam, str(st["title"]), c, Vector2(128, 96), bool(d["door_south"]),
		"res://assests/world/village/floor_wood_planks.png", "res://assests/world/village/wall_timber_h.png",
		"res://assests/world/village/wall_timber_v.png", 42.0, 0.0, Color(0.96, 0.86, 0.62))
	var tex_wall_h: Texture2D = vm._load_tex("res://assests/world/village/wall_timber_h.png")
	vm._add_solid_wall_segment(lay["wall_l"], Vector2(40, 6), tex_wall_h)
	vm._add_solid_wall_segment(lay["wall_r"], Vector2(40, 6), tex_wall_h)
	var stall: Sprite2D = vm._add_sprite_prop(vm._load_tex("res://assests/world/village/work_stall.png"), lay["stall_pos"], Vector2(1.3, 1.3), -1)
	vm._register_shop_business_stall(role, str(st["title"]), fam, stall.global_position, stall)
	var tex_bed: Texture2D = vm._load_tex("res://assests/world/village/tavern_bed.png")
	for b in [lay["bed1_pos"], lay["bed2_pos"]]:
		vm._add_sprite_prop(tex_bed, b, Vector2(1.12, 1.12), -1)
	vm._spawn_decor_prop("res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/table_chairs_1.png", lay["table_pos"], Vector2(0.45, 0.45))
	vm._spawn_house_chest(lay["chest_pos"], "Cofre de " + str(st["title"]), fam)

## Camas dentro de la casa, lejos de la puerta.
static func _house_beds(id: String) -> Array:
	var d: Dictionary = lot_def(id)
	var c: Vector2 = d["center"]
	var dy: float = -18.0 if bool(d["door_south"]) else 18.0
	return [c + Vector2(-30, dy), c + Vector2(30, dy)]

# Lo que crean las funciones de dibujo de VillageManager va a entities_root, al propio vm y a varias listas.
static func _capture_begin(vm) -> Dictionary:
	return {"ent": vm.entities_root.get_child_count(), "vm": vm.get_child_count(), "fp": vm.building_footprints.size(),
		"doors": vm.building_doors.size(), "wins": vm.building_windows.size(), "occ": vm._wall_occluder_rects.size(),
		"chests": vm.house_chests.size()}

static func _capture_end(vm, s: Dictionary) -> Array:
	var nodes: Array = []
	for i in range(int(s["ent"]), vm.entities_root.get_child_count()):
		nodes.append(vm.entities_root.get_child(i))
	for i in range(int(s["vm"]), vm.get_child_count()):
		nodes.append(vm.get_child(i))
	var entries: Dictionary = {"fp": vm.building_footprints.slice(int(s["fp"])), "doors": vm.building_doors.slice(int(s["doors"])),
		"wins": vm.building_windows.slice(int(s["wins"])), "occ": vm._wall_occluder_rects.slice(int(s["occ"])),
		"chests": vm.house_chests.slice(int(s["chests"]))}
	return [nodes, entries]

static func _clear_lot_visuals(vm, id: String) -> void:
	if not vm._lot_visuals.has(id):
		return
	var rec: Array = vm._lot_visuals[id]
	for n in (rec[0] as Array):
		if is_instance_valid(n):
			n.get_parent().remove_child(n)
			n.queue_free()
	var e: Dictionary = rec[1]
	for x in e["fp"]:
		vm.building_footprints.erase(x)
	for x in e["doors"]:
		vm.building_doors.erase(x)
	for x in e["wins"]:
		vm.building_windows.erase(x)
	for x in e["occ"]:
		vm._wall_occluder_rects.erase(x)
	for x in e["chests"]:
		vm.house_chests.erase(x)
	vm._lot_visuals.erase(id)

# ---------------------------------------------------------------- obras
## Encarga una obra. `payer` paga en el acto (un vecino con su oro) o, si es null, las arcas del pueblo.
## Devuelve "" si no se puede (sin dinero, sin solar o ya hay una obra: el carpintero solo lleva una).
static func request_build(vm, id: String, kind: String, payer = null, title: String = "") -> String:
	if not KINDS.has(kind) or lot_def(id).is_empty() or str(lot(vm, id)["status"]) != "empty" or active_site(vm) != "":
		return ""
	var cost: int = int(KINDS[kind]["cost"])
	if payer != null:
		if int(payer.personal_gold) < cost:
			return ""
		payer.personal_gold -= cost
	else:
		var ts: Dictionary = vm.town_state
		if int(ts.get("treasury", 0)) < cost:
			return ""
		ts["treasury"] = int(ts["treasury"]) - cost
	var carp = _carpenter(vm)
	if carp != null:
		carp.personal_gold += int(round(cost * CARPENTER_SHARE))
	var st: Dictionary = lot(vm, id)
	st["status"] = "building"
	st["kind"] = kind
	st["progress"] = 0.0
	st["title"] = title if title != "" else "🏠 %s nueva" % str(KINDS[kind]["title"])
	st["payer"] = payer.get_person_key() if payer != null else "town"
	_draw_lot(vm, id, st)
	vm.VillageChronicle.add(vm, "construction", "Empieza la obra de %s en las afueras del pueblo" % str(st["title"]).to_lower(), true)
	return id

static func _carpenter(vm):
	var c = vm.trade_npcs.get(VillageNPC.TradeRole.CARPENTER)
	if c != null and is_instance_valid(c) and not c.is_dead:
		return c
	return null

## Cada hora: el carpintero tiene su puesto en la obra; solo avanza si está allí trabajando.
static func on_hour(vm, _hour: int) -> void:
	var id: String = active_site(vm)
	var carp = _carpenter(vm)
	if id == "" or carp == null:
		return
	var wp: Vector2 = site_work_pos(id)
	if carp.work_position != wp:
		carp.work_position = wp
	if carp.is_downed or carp.is_sleeping or int(carp.current_activity) != WORK_STATE or carp.global_position.distance_to(wp) > SITE_RADIUS:
		return
	var st: Dictionary = lot(vm, id)
	var hours: float = float(KINDS[str(st["kind"])]["hours"])
	st["progress"] = minf(1.0, float(st["progress"]) + (0.7 + 0.6 * TraitCatalog.npc_tendency(carp, "diligence")) / hours)
	if float(st["progress"]) >= 1.0:
		_finish(vm, id, carp)
	else:
		_update_site_label(vm, id)

static func _finish(vm, id: String, carp) -> void:
	var st: Dictionary = lot(vm, id)
	st["status"] = "built"
	st["progress"] = 1.0
	if str(st["kind"]) == "house":
		st["beds"] = _house_beds(id)
		st["residents"] = []
	_draw_lot(vm, id, st)
	var cfg: Dictionary = vm.trade_configs.get(VillageNPC.TradeRole.CARPENTER, {})
	if carp != null:
		carp.work_position = cfg.get("work_pos", carp.work_position)
		carp.add_thought("Terminé %s (+6)" % str(st["title"]).to_lower(), 6.0)
		vm.VillageChronicle.add(vm, "construction", "%s terminó %s" % [carp.npc_name, str(st["title"]).to_lower()], true)

static func _update_site_label(vm, id: String) -> void:
	var lbl = vm.entities_root.get_node_or_null("LotSiteLabel_" + id)
	if lbl != null:
		var st: Dictionary = lot(vm, id)
		lbl.text = "🚧 En obra: %s (%d %%)" % [str(st["title"]), int(round(float(st["progress"]) * 100.0))]

# ---------------------------------------------------------------- vivienda (la usará V3)
## Una cama libre en una casa construida: {"lot": id, "bed": Vector2, "family_id": ...} o vacío.
static func free_house_bed(vm) -> Dictionary:
	for l in LOTS:
		var id: String = str(l["id"])
		var st: Dictionary = lot(vm, id)
		if str(st["status"]) != "built" or str(st["kind"]) != "house":
			continue
		var res: Array = st["residents"]
		var beds: Array = st["beds"]
		if res.size() < beds.size():
			return {"lot": id, "bed": beds[res.size()], "family_id": "family_lot_" + id, "table": (l["center"] as Vector2) + Vector2(0, -2)}
	return {}

static func add_resident(vm, id: String, person_key: String) -> void:
	var res: Array = lot(vm, id)["residents"]
	if not person_key in res:
		res.append(person_key)

## Tras cargar: las camas se recalculan (el guardado no conserva Vector2) y se redibuja cada solar.
static func after_load(vm) -> void:
	for id in state(vm).keys():
		var st: Dictionary = state(vm)[id]
		st["beds"] = _house_beds(str(id)) if str(st.get("kind", "")) == "house" and str(st.get("status", "")) == "built" else []
		st["progress"] = float(st.get("progress", 0.0))
		if not st.has("residents"):
			st["residents"] = []
	load("res://scripts/systems/VillageTrades.gd").ensure_lots(vm) # Partidas de antes de V5: sus tiendas siguen en pie
	load("res://scripts/systems/VillageCivic.gd").ensure_lots(vm)
	for l in LOTS:
		_draw_lot(vm, str(l["id"]), lot(vm, str(l["id"])))
