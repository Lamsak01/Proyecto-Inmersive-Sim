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

const Marca = preload("res://mapa/marca.gd")
const CasaModelo = preload("res://mapa/casa_modelo.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

const WORK_STATE: int = 0 # ActivityState.WORKING
const SITE_RADIUS: float = 50.0
const CARPENTER_SHARE: float = 0.4 # Lo que cobra el carpintero; el resto son materiales

## Solares. `door_south`: la puerta mira al sur (si no, al norte). Tamaños de terreno, no del edificio.
const LOTS: Array = [
	# Borde norte, en fila sobre una calle nueva detrás de la posada y las casas
	{"id": "n0", "zone": "borde", "plot": "small", "center": Vector2(190, -420), "size": Vector2(130, 96), "door_south": true}, # V3
	{"id": "n1", "zone": "borde", "plot": "medium", "center": Vector2(330, -420), "size": Vector2(130, 96), "door_south": true},
	{"id": "n2", "zone": "borde", "plot": "medium", "center": Vector2(470, -420), "size": Vector2(130, 96), "door_south": true},
	{"id": "n3", "zone": "borde", "plot": "large", "center": Vector2(610, -420), "size": Vector2(130, 96), "door_south": true},
	{"id": "n4", "zone": "borde", "plot": "small", "center": Vector2(760, -420), "size": Vector2(130, 96), "door_south": true},
	{"id": "n5", "zone": "borde", "plot": "medium", "center": Vector2(910, -420), "size": Vector2(130, 96), "door_south": true},
	{"id": "n6", "zone": "borde", "plot": "large", "center": Vector2(1070, -420), "size": Vector2(130, 96), "door_south": true}, # Para llegar a 50
	# Segunda fila al norte (para crecer): dan a una calleja nueva detrás de la calle norte
	{"id": "m1", "zone": "borde", "plot": "small", "center": Vector2(330, -580), "size": Vector2(130, 96), "door_south": true}, # Calleja de atrás
	{"id": "m2", "zone": "borde", "plot": "large", "center": Vector2(470, -580), "size": Vector2(130, 96), "door_south": true}, # Calleja de atrás
	{"id": "m3", "zone": "borde", "plot": "medium", "center": Vector2(610, -580), "size": Vector2(130, 96), "door_south": true}, # Calleja de atrás
	{"id": "m4", "zone": "borde", "plot": "small", "center": Vector2(760, -580), "size": Vector2(130, 96), "door_south": true}, # Calleja de atrás
	{"id": "m5", "zone": "borde", "plot": "large", "center": Vector2(910, -580), "size": Vector2(130, 96), "door_south": true}, # Calleja de atrás
	{"id": "m6", "zone": "borde", "plot": "medium", "center": Vector2(1070, -580), "size": Vector2(130, 96), "door_south": true}, # Para llegar a 50
	# Tercera fila al norte (Bloque PQ: expansión urbana para escalar a 100+ vecinos)
	{"id": "u0", "zone": "borde", "plot": "medium", "center": Vector2(190, -740), "size": Vector2(130, 96), "door_south": true},
	{"id": "u1", "zone": "borde", "plot": "small", "center": Vector2(330, -740), "size": Vector2(130, 96), "door_south": true},
	{"id": "u2", "zone": "borde", "plot": "large", "center": Vector2(470, -740), "size": Vector2(130, 96), "door_south": true},
	{"id": "u4", "zone": "borde", "plot": "medium", "center": Vector2(760, -740), "size": Vector2(130, 96), "door_south": true},
	{"id": "u5", "zone": "borde", "plot": "large", "center": Vector2(910, -740), "size": Vector2(130, 96), "door_south": true},
	{"id": "u6", "zone": "borde", "plot": "small", "center": Vector2(1070, -740), "size": Vector2(130, 96), "door_south": true},
	# Borde este, a los dos lados del camino principal alargado
	{"id": "e2", "zone": "borde", "plot": "small", "center": Vector2(1230, -36), "size": Vector2(130, 96), "door_south": true},
	{"id": "e3", "zone": "borde", "plot": "medium", "center": Vector2(1400, -36), "size": Vector2(130, 96), "door_south": true},
	{"id": "e4", "zone": "borde", "plot": "medium", "center": Vector2(1090, 140), "size": Vector2(130, 96), "door_south": false},
	{"id": "e5", "zone": "borde", "plot": "large", "center": Vector2(1230, 140), "size": Vector2(130, 96), "door_south": false},
	{"id": "e6", "zone": "borde", "plot": "small", "center": Vector2(1400, 140), "size": Vector2(130, 96), "door_south": false}, # V3
	# Bloque AA: barrios apartados (zona "barrio"). Los llenan antes los vecinos huraños; los demás, cuando el centro se llena.
	# Barrio del Lago: casitas sueltas en la orilla sur, mirando a la senda de los campos
	{"id": "l1", "zone": "barrio", "barrio": "Barrio del Lago", "plot": "small", "center": Vector2(-390, 300), "size": Vector2(110, 80), "door_south": true},
	{"id": "l2", "zone": "barrio", "barrio": "Barrio del Lago", "plot": "medium", "center": Vector2(-280, 308), "size": Vector2(130, 90), "door_south": true},
	{"id": "l3", "zone": "barrio", "barrio": "Barrio del Lago", "plot": "small", "center": Vector2(-165, 298), "size": Vector2(110, 80), "door_south": true},
	{"id": "l4", "zone": "barrio", "barrio": "Barrio del Lago", "plot": "small", "center": Vector2(-55, 306), "size": Vector2(110, 80), "door_south": true},
	# Caseríos del Bosque: casas aisladas al oeste del bosque, a lo largo de una senda propia
	{"id": "c1", "zone": "barrio", "barrio": "Caseríos del Bosque", "plot": "small", "center": Vector2(-610, 668), "size": Vector2(110, 80), "door_south": false},
	{"id": "c2", "zone": "barrio", "barrio": "Caseríos del Bosque", "plot": "medium", "center": Vector2(-600, 800), "size": Vector2(130, 90), "door_south": false},
	{"id": "c3", "zone": "barrio", "barrio": "Caseríos del Bosque", "plot": "small", "center": Vector2(-605, 930), "size": Vector2(110, 80), "door_south": false},
	# Molino del Este: dos casas de molineros al sur del Puesto del Paso, junto al molino de viento
	{"id": "o1", "zone": "barrio", "barrio": "Molino del Este", "plot": "small", "center": Vector2(1570, 240), "size": Vector2(110, 80), "door_south": false},
	{"id": "o2", "zone": "barrio", "barrio": "Molino del Este", "plot": "medium", "center": Vector2(1690, 240), "size": Vector2(130, 90), "door_south": false},
	# Afueras: campos al sur, entre el pueblo y el bosque, y la ladera del noroeste
	# `offset`: en los solares grandes el edificio va a un lado y deja sitio a campos, corrales o la cantera
	{"id": "s1", "zone": "afueras", "center": Vector2(-220, 470), "size": Vector2(230, 160), "door_south": false, "offset": Vector2(-50, 0)},
	{"id": "s2", "zone": "afueras", "center": Vector2(30, 470), "size": Vector2(230, 160), "door_south": false},
	{"id": "s3", "zone": "afueras", "center": Vector2(290, 470), "size": Vector2(230, 160), "door_south": false, "offset": Vector2(-50, 0)},
	{"id": "w1", "zone": "afueras", "center": Vector2(-230, -330), "size": Vector2(230, 160), "door_south": true, "offset": Vector2(-50, 0)},
	{"id": "fw", "zone": "afueras", "center": Vector2(-430, 556), "size": Vector2(130, 96), "door_south": true}, # Linde del bosque (V5d)
	# Apartados: lejos del centro, para mansiones
	{"id": "f1", "zone": "apartado", "center": Vector2(1315, -440), "size": Vector2(250, 180), "door_south": true},
	{"id": "f2", "zone": "apartado", "center": Vector2(40, -560), "size": Vector2(250, 180), "door_south": true},
]

## Tamaño de la casa que se levanta en cada solar (`plot` en LOTS; sin él, "medium"). El terreno del solar no cambia:
## la casita deja más patio alrededor. Quien tiene poco dinero busca casita; quien tiene mucho, casona.
const HOUSE_PLOTS: Dictionary = {
	"small": {"word": "Casita", "size": Vector2(84, 62), "beds": 2, "cost": 80},
	"medium": {"word": "Casa", "size": Vector2(112, 78), "beds": 2, "cost": 100},
	"large": {"word": "Casona", "size": Vector2(124, 90), "beds": 3, "cost": 140},
}

## Lo que cuesta levantar la casa de ese solar (casita más barata, casona más cara).
static func house_cost(id: String) -> int:
	return int(HOUSE_PLOTS[plot_of(id)]["cost"])

static func plot_of(id: String) -> String:
	var p: String = str(lot_def(id).get("plot", "medium"))
	return p if HOUSE_PLOTS.has(p) else "medium"

## Solar libre para una casa según el bolsillo: "poor" -> casita, "mid" -> casa, "rich" -> casona.
## Si no queda del tamaño buscado, el más parecido (el pobre antes una casa que nada; el rico antes casa que casita).
## `remote`: el comprador prefiere un barrio apartado (vecinos huraños). Si no, primero el centro y luego los barrios.
static func pick_house_lot(vm, wealth: String = "mid", remote: bool = false) -> String:
	var free: Array = free_lots(vm, "house")
	if free.is_empty():
		return ""
	var order: Array = ["medium", "small", "large"]
	if wealth == "poor":
		order = ["small", "medium", "large"]
	elif wealth == "rich":
		order = ["large", "medium", "small"]
	var zone_order: Array = ["barrio", "borde"] if remote else ["borde", "barrio"]
	for z in zone_order:
		for want in order:
			for id in free:
				if plot_of(str(id)) == want and str(lot_def(str(id)).get("zone", "")) == z:
					return str(id)
	return str(free[0])

## Calles y sendas nuevas hacia los solares (también las dibuja el mapa).
const ROADS: Array = [
	Rect2(Vector2(130, -362), Vector2(1010, 22)), # Calle norte (alargada hasta los solares n0 y n6)
	Rect2(Vector2(980, -686), Vector2(20, 346)), # Enlace de las callejas norte con la calle norte
	Rect2(Vector2(660, -362), Vector2(24, 230)), # Enlace con la calle de las casas
	Rect2(Vector2(1010, 36), Vector2(470, 28)), # Camino principal hacia el este
	Rect2(Vector2(-290, -250), Vector2(20, 286)), # Senda a la ladera del noroeste (puerta de la cantera)
	Rect2(Vector2(-450, 606), Vector2(72, 24)), # Camino del bosque hasta la cabaña del leñador
	Rect2(Vector2(-330, 362), Vector2(780, 20)), # Senda de los campos del sur
	Rect2(Vector2(1305, -350), Vector2(20, 386)), # Senda a la loma del este
	Rect2(Vector2(30, -470), Vector2(20, 506)), # Senda a la loma del norte
	Rect2(Vector2(-450, 362), Vector2(120, 20)), # Bloque AA: senda de los campos alargada hasta el Barrio del Lago
	Rect2(Vector2(-690, 606), Vector2(240, 22)), # Senda de los Caseríos del Bosque (sigue al camino del bosque)
	Rect2(Vector2(-690, 606), Vector2(20, 290)), # Senda de los Caseríos, hacia el sur
	Rect2(Vector2(-690, 733), Vector2(145, 20)), # Ramal del caserío c2
	Rect2(Vector2(-690, 868), Vector2(140, 20)), # Ramal del caserío c3
	Rect2(Vector2(1480, 64), Vector2(20, 128)), # Bajada del camino del este al Molino
	Rect2(Vector2(1480, 172), Vector2(280, 20)), # Calle del Molino del Este
]

## Bloque AB: las dos callejas del norte (filas m y u) ya no son rectas: siguen una curva suave y las casas de su fila
## la acompañan (ver `lot_shift`). Cada una es una línea de puntos por el centro de la calle y su anchura.
const STREET_WAVE_AMP: float = 11.0
const CURVED_ROADS: Array = [
	{"name": "Calleja de atrás", "from_x": 270.0, "to_x": 1140.0, "y": -516.0, "w": 20.0, "phase": 0.0},
	{"name": "Ronda alta del norte", "from_x": 130.0, "to_x": 1140.0, "y": -676.0, "w": 20.0, "phase": 2.1},
]

## Cuánto se desvía la calle (y las casas de su fila) en la x dada.
static func street_wave(road: Dictionary, x: float) -> float:
	var t: float = (x - float(road["from_x"])) / maxf(1.0, float(road["to_x"]) - float(road["from_x"]))
	return STREET_WAVE_AMP * sin(t * TAU * 0.85 + float(road["phase"]))

## Puntos del centro de una calleja curva (cada ~45 px).
static func curved_road_points(road: Dictionary) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var x: float = float(road["from_x"])
	while x < float(road["to_x"]):
		pts.append(Vector2(x, float(road["y"]) + street_wave(road, x)))
		x += 45.0
	pts.append(Vector2(float(road["to_x"]), float(road["y"]) + street_wave(road, float(road["to_x"]))))
	return pts

## Bloque AB: las filas del borde dejan de ser una cuadrícula. Cada solar se desplaza un poco (siempre fijo, sale del
## nombre del solar): en la calle norte, unos pasos hacia atrás; en las callejas m y u, siguiendo la curva de su calle.
static func lot_shift(id: String) -> Vector2:
	var base: Dictionary = _raw_def(id)
	if base.is_empty() or str(base.get("zone", "")) != "borde":
		return Vector2.ZERO
	var h: int = absi(id.hash())
	var h2: int = int(h / 3.0)
	var dx: float = float((h % 3) - 1) * 4.0
	var row: String = id.substr(0, 1)
	var c: Vector2 = base["center"]
	if row == "n":
		return Vector2(dx, -float(h2 % 4) * 5.0)
	if row == "m":
		return Vector2(dx, street_wave(CURVED_ROADS[0], c.x) - float(h2 % 3) * 3.0)
	if row == "u":
		return Vector2(dx, street_wave(CURVED_ROADS[1], c.x) - float(h2 % 3) * 3.0)
	return Vector2.ZERO

## Bloque AB: pozo vecinal en la ronda alta (sirve de verdad para coger agua y lavarse).
## Paso 2: se retira el "Huerto vecinal" que estaba plantado en mitad del camino del este.
const GAP_POCKETS: Array = [
	{"kind": "well", "pos": Vector2(610, -735), "title": "🪣 Pozo de la Ronda [E: Llenar Recipiente / Lavar Heridas y Sangre]"},
]

## Al montar el pueblo: borra lo calculado (los desplazamientos son fijos, pero así no queda nada de otra partida).
static func reset_layout() -> void:
	_def_cache.clear()
static var _def_cache: Dictionary = {}

static func _raw_def(id: String) -> Dictionary:
	for l in LOTS:
		if str(l["id"]) == id:
			return l
	return {}

## Bloque AA: molino de viento del Molino del Este (base sólida en 2D; en 3D, el modelo de molino).
const EAST_MILL_POS: Vector2 = Vector2(1458, 250)

## Clases de edificio. `hours`: horas de trabajo del carpintero (a diligencia media). `beds`: camas para vecinos.
const KINDS: Dictionary = {
	"house": {"title": "Casa", "cost": 100, "hours": 24.0, "beds": 2, "zones": ["borde", "barrio"]},
	"shop_house": {"title": "Tienda con vivienda", "cost": 90, "hours": 34.0, "beds": 2, "zones": ["borde"]}, # V5: `st.role` = oficio
}

static func state(vm) -> Dictionary:
	if typeof(vm.lots_state) != TYPE_DICTIONARY:
		vm.lots_state = {}
	return vm.lots_state

## Definición del solar con su sitio real (ya desplazado).
static func lot_def(id: String) -> Dictionary:
	if _def_cache.has(id):
		return _def_cache[id]
	var l: Dictionary = _raw_def(id)
	if l.is_empty():
		return {}
	var sh: Vector2 = lot_shift(id)
	var d: Dictionary = l
	if sh != Vector2.ZERO:
		d = l.duplicate()
		d["center"] = (l["center"] as Vector2) + sh
	_def_cache[id] = d
	return d

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

## Centro del edificio dentro del solar (en los grandes, desplazado a un lado).
static func building_center(id: String) -> Vector2:
	var d: Dictionary = lot_def(id)
	return (d["center"] as Vector2) + (d.get("offset", Vector2.ZERO) as Vector2)

## Un anexo del solar (campo, corral, cantera, troncos) va pegado a su edificio: su sitio en el mundo es el del
## edificio más el desplazamiento original (mapa ×E: el campo abierto se estira, el anexo no).
static func anexo(vm, id: String, p: Vector2) -> Vector2:
	var c: Vector2 = building_center(id)
	return vm.sitio(c) + (p - c)


static func site_work_pos(id: String) -> Vector2:
	var d: Dictionary = lot_def(id)
	var off: float = float((d["size"] as Vector2).y) * 0.5 + 12.0
	return (d["center"] as Vector2) + Vector2(0, off if bool(d["door_south"]) else -off)

# ---------------------------------------------------------------- mapa
## Al montar el pueblo: calles nuevas hacia los solares del borde y un cartel en cada solar libre.
static func build_world(vm) -> void:
	var dirt := Color(0.46, 0.36, 0.24, 0.65)
	_build_gap_pockets(vm)
	for r in ROADS:
		_road(vm, r, dirt)
	for cr in CURVED_ROADS:
		var pts: PackedVector2Array = curved_road_points(cr)
		var hw: float = float(cr["w"]) * 0.5
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var nrm: Vector2 = (b - a).normalized().orthogonal() * hw
			var ext: Vector2 = (b - a).normalized() * 2.0 # solapa un poco los tramos para que no queden rendijas
			vm._add_poly(PackedVector2Array([a - ext + nrm, b + ext + nrm, b + ext - nrm, a - ext - nrm]), dirt, -3)
	# Molino del Este: base de piedra sólida (los vecinos lo rodean) y su cartel
	vm._add_solid_wall_segment(EAST_MILL_POS, Vector2(34, 34), vm._load_tex("res://assests/world/village/wall_stone_h.png"))
	vm._add_title_label(EAST_MILL_POS + Vector2(-60, -40), Vector2(120, 14), "🌾 Molino del Este", Color(0.86, 0.80, 0.62), 7)
	for l in LOTS:
		var id: String = str(l["id"])
		var st: Dictionary = lot(vm, id)
		_draw_lot(vm, id, st)

static func _build_gap_pockets(vm) -> void:
	for g in GAP_POCKETS:
		var p: Vector2 = g["pos"]
		match str(g["kind"]):
			"well":
				vm._add_sprite_prop(vm._load_tex("res://assests/world/village/water_well.png"), p, Vector2(1.25, 1.25), 0)
				vm._add_station_area("RondaWaterWellArea", p, 24.0, "well")
				if not vm.sitio(p) in vm._well_positions:
					vm._well_positions.append(vm.sitio(p))
				var wl: Label = vm._make_station_label(p + Vector2(-135, -28), str(g["title"]))
				vm.entities_root.add_child(wl)
				vm._extra_station_labels.append([wl, p])
			"garden":
				vm._add_poly(_rect_pts(p, Vector2(96, 70)), Color(0.40, 0.30, 0.18, 0.35), -4)
				var soil: Texture2D = vm._load_tex("res://assests/world/farming/soil_dry.png")
				for gy in [-14.0, 14.0]:
					for gx in [-28.0, 0.0, 28.0]:
						vm._add_sprite_prop(soil, p + Vector2(gx, gy), Vector2(1.35, 1.35), -1)
				vm._add_title_label(p + Vector2(-60, -48), Vector2(120, 14), str(g["title"]), Color(0.70, 0.86, 0.55), 7)

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
	if vm.has_method("refresh_world_stage_3d"):
		vm.refresh_world_stage_3d()

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
			var has_up: bool = bool((st.get("upgrades", {}) as Dictionary).get("upper_floor", false))
			var beds: Array = _house_beds(id, has_up)
			# La casa es una copia de la casa modelo de su tamaño; con la puerta al norte va con media vuelta, y con ella su ventana
			vm._construct_solid_building(CasaModelo.PREFIJO + id, str(st["title"]), c, HOUSE_PLOTS[plot_of(id)]["size"], bool(d["door_south"]),
				"res://assests/world/village/floor_wood_planks.png", "res://assests/world/village/wall_timber_h.png",
				"res://assests/world/village/wall_timber_v.png", 38.0, 0.0, Color(0.92, 0.88, 0.72), not bool(d["door_south"]))
			for b in beds:
				vm._add_sprite_prop(tex_bed, b, Vector2(1.12, 1.12), -1)
			vm._spawn_decor_prop("res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/table_chairs_1.png", house_site(id, Marca.MESA), Vector2(0.45, 0.45))
			vm._spawn_house_chest(house_site(id, Marca.COFRE), "Cofre Familiar (" + str(st["title"]) + ")", fam)
		"shop_house":
			_build_shop_house(vm, id, st)
		"fields":
			load("res://scripts/systems/VillageTrades.gd").build_extras(vm, id)
		"civic", "shelter", "inn":
			load("res://scripts/systems/VillageCivic.gd").build(vm, id, st)
		"library", "school":
			load("res://scripts/systems/VillageCulture.gd").build(vm, id, st)
		"mansion", "manor":
			load("res://scripts/systems/VillageNobility.gd").build(vm, id, st)

## V5: tienda y vivienda en un solo edificio (como la Botica), con la puerta hacia la calle del solar.
## Si el edificio (`building_id`) tiene escena propia con marcas, sus sitios salen de ellas (mapa/marca.gd). Si no
## (tienda levantada en un solar durante la partida), del molde: posiciones relativas a la Botica (puerta al norte),
## reflejadas con la puerta al sur. Las dos paredes de dentro salen siempre del molde.
const SHOP_HOUSE_MARKS: Dictionary = {"work_pos": Marca.TRABAJO, "kin_work_pos": Marca.TRABAJO_FAMILIAR, "bed1_pos": Marca.CAMA_1,
	"bed2_pos": Marca.CAMA_2, "table_pos": Marca.MESA, "stall_pos": Marca.PUESTO, "chest_pos": Marca.COFRE}

static func shop_house_id(family_id: String) -> String:
	return "mixed_" + family_id

static func shop_house_layout(id: String, building_id: String = "") -> Dictionary:
	var lay: Dictionary = _shop_house_mold(id)
	if Marca.hay(building_id, Marca.TRABAJO):
		for campo: String in SHOP_HOUSE_MARKS:
			lay[campo] = Marca.sitio(building_id, SHOP_HOUSE_MARKS[campo])
	return lay

static func _shop_house_mold(id: String) -> Dictionary:
	var d: Dictionary = lot_def(id)
	var c: Vector2 = building_center(id)
	var m: float = -1.0 if bool(d["door_south"]) else 1.0
	var f := func(v: Vector2) -> Vector2: return c + Vector2(v.x, v.y * m)
	return {"work_pos": f.call(Vector2(0, -18)), "bed1_pos": f.call(Vector2(-36, 26)), "bed2_pos": f.call(Vector2(36, 26)),
		"table_pos": f.call(Vector2(0, 24)), "kin_work_pos": f.call(Vector2(-24, -14)), "stall_pos": f.call(Vector2(0, -10)),
		"chest_pos": f.call(Vector2(42, -26)), "wall_l": f.call(Vector2(-42, 4)), "wall_r": f.call(Vector2(42, 4))}

static func _build_shop_house(vm, id: String, st: Dictionary) -> void:
	var d: Dictionary = lot_def(id)
	var c: Vector2 = building_center(id)
	var role: int = int(st["role"])
	var fam: String = str(st.get("family_id", "family_lot_" + id))
	var lay: Dictionary = shop_house_layout(id, shop_house_id(fam))
	vm._construct_solid_building(shop_house_id(fam), str(st["title"]), c, Vector2(128, 96), bool(d["door_south"]),
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
	load("res://scripts/systems/VillageTrades.gd").build_extras(vm, id) # V5d: campos, corrales, cantera…

## Camas de la casa de ese solar: las que marca su casa modelo (mapa/casa_modelo.gd). Con altillo (`upper_floor`),
## también las de arriba.
static func _house_beds(id: String, has_upper: bool = false) -> Array:
	var d: Dictionary = lot_def(id)
	return CasaModelo.camas(plot_of(id), d["center"], bool(d["door_south"]), has_upper)

## Sitio de una marca (mesa, cofre…) de la casa de ese solar, en el mapa original.
static func house_site(id: String, marca: String) -> Vector2:
	var d: Dictionary = lot_def(id)
	return CasaModelo.sitio(plot_of(id), d["center"], bool(d["door_south"]), marca)

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
	var cost: int = house_cost(id) if kind == "house" else int(KINDS[kind]["cost"])
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
	buy_materials(vm, cost)
	var st: Dictionary = lot(vm, id)
	st["status"] = "building"
	st["kind"] = kind
	st["progress"] = 0.0
	st["title"] = title if title != "" else "🏠 %s nueva" % str(KINDS[kind]["title"])
	st["payer"] = payer.get_person_key() if payer != null else "town"
	_draw_lot(vm, id, st)
	vm.VillageChronicle.add(vm, "construction", "Empieza la obra de %s en las afueras del pueblo" % str(st["title"]).to_lower(), true)
	return id

## K1: la obra compra piedra a la cantera y troncos al leñador (si tienen), con el dinero de materiales.
const MATERIAL_UNITS: int = 3
const MATERIAL_SHARE: float = 0.2 # de lo que cuesta la obra, para cada proveedor
static func buy_materials(vm, cost: int) -> int:
	var spent: int = 0
	for pair in [[VillageNPC.TradeRole.QUARRYMAN, "stone"], [VillageNPC.TradeRole.WOODCUTTER, "wood"]]:
		var seller = vm.trade_npcs.get(pair[0])
		if seller == null or not is_instance_valid(seller) or seller.is_dead or int(seller.shop_stock.get(pair[1], 0)) < MATERIAL_UNITS:
			continue
		var pay: int = int(round(cost * MATERIAL_SHARE))
		seller.shop_stock[pair[1]] = int(seller.shop_stock[pair[1]]) - MATERIAL_UNITS
		seller.personal_gold += pay
		seller._sync_shop_stock_to_vm()
		seller.add_thought("Vendí material para una obra (+5)", 5.0)
		spent += pay
	return spent

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
	var wp: Vector2 = vm.sitio(site_work_pos(id))
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
		var has_up: bool = bool((st.get("upgrades", {}) as Dictionary).get("upper_floor", false))
		st["beds"] = _house_beds(id, has_up)
		st["residents"] = []
	_draw_lot(vm, id, st)
	if "VillageHousing" in vm and vm.VillageHousing != null:
		vm.VillageHousing.sync_home_props(vm)
	var cfg: Dictionary = vm.trade_configs.get(VillageNPC.TradeRole.CARPENTER, {})
	if carp != null:
		carp.work_position = cfg.get("work_pos", carp.work_position)
		carp.add_thought("Terminé %s (+6)" % str(st["title"]).to_lower(), 6.0)
		vm.VillageChronicle.add(vm, "construction", "%s terminó %s" % [carp.npc_name, str(st["title"]).to_lower()], true)
	if str(st.get("payer", "")) == "town" and "VillageMayor" in vm and vm.VillageMayor != null:
		vm.VillageMayor.announce_town_inauguration(vm, str(st.get("title", "obra municipal")))

## Partida nueva con más vecinos: una casa que ya está en pie al empezar (sin obra ni pago).
static func build_instant_house(vm, id: String) -> bool:
	if lot_def(id).is_empty() or str(lot(vm, id)["status"]) != "empty":
		return false
	var st: Dictionary = lot(vm, id)
	st["kind"] = "house"
	st["title"] = "🏠 %s" % str(HOUSE_PLOTS[plot_of(id)]["word"])
	st["payer"] = "town"
	_finish(vm, id, null)
	return true

## Bloque PQ: Ampliar una casa ya construida con altillo/primer piso (+2 camas, hasta 4 residentes por casa).
const UPPER_FLOOR_COST: int = 50
static func expand_house_upper_floor(vm, id: String, payer = null) -> bool:
	var st: Dictionary = lot(vm, id)
	if str(st.get("status", "")) != "built" or str(st.get("kind", "")) != "house":
		return false
	if not st.has("upgrades") or not (st["upgrades"] is Dictionary):
		st["upgrades"] = {}
	if bool(st["upgrades"].get("upper_floor", false)):
		return false
	if payer != null:
		if int(payer.personal_gold) < UPPER_FLOOR_COST:
			return false
		payer.personal_gold -= UPPER_FLOOR_COST
	else:
		if int(vm.town_state.get("treasury", 0)) < UPPER_FLOOR_COST:
			return false
		vm.town_state["treasury"] = int(vm.town_state["treasury"]) - UPPER_FLOOR_COST
	var carp = _carpenter(vm)
	if carp != null:
		carp.personal_gold += int(round(UPPER_FLOOR_COST * CARPENTER_SHARE))
	buy_materials(vm, UPPER_FLOOR_COST)
	st["upgrades"]["upper_floor"] = true
	st["beds"] = _house_beds(id, true)
	vm.VillageChronicle.add(vm, "house_expanded", "Se levantó un altillo con 2 camas nuevas en %s (solar %s)" % [str(st.get("title", "la casa")), id], true)
	return true

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
			return {"lot": id, "bed": beds[res.size()], "family_id": "family_lot_" + id, "table": house_site(id, Marca.MESA)}
	return {}

static func add_resident(vm, id: String, person_key: String) -> void:
	var res: Array = lot(vm, id)["residents"]
	if not person_key in res:
		res.append(person_key)

## Tras cargar: las camas se recalculan (el guardado no conserva Vector2) y se redibuja cada solar.
static func after_load(vm) -> void:
	for id in state(vm).keys():
		var st: Dictionary = state(vm)[id]
		var has_up: bool = bool((st.get("upgrades", {}) as Dictionary).get("upper_floor", false))
		st["beds"] = _house_beds(str(id), has_up) if str(st.get("kind", "")) == "house" and str(st.get("status", "")) == "built" else []
		st["progress"] = float(st.get("progress", 0.0))
		if not st.has("residents"):
			st["residents"] = []
	load("res://scripts/systems/VillageTrades.gd").ensure_lots(vm) # Partidas de antes de V5: sus tiendas siguen en pie
	load("res://scripts/systems/VillageCivic.gd").ensure_lots(vm)
	load("res://scripts/systems/VillageCulture.gd").ensure_lots(vm)
	load("res://scripts/systems/VillageNobility.gd").ensure_lots(vm)
	for l in LOTS:
		_draw_lot(vm, str(l["id"]), lot(vm, str(l["id"])))
	if "VillageHousing" in vm and vm.VillageHousing != null:
		vm.VillageHousing.sync_home_props(vm)
