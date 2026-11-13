extends RefCounted

## Arma la escena entera de una casa a partir de su plano (tools/casas/plano_*.gd), 2026-11-13: los grupos fijos de un
## edificio (mapa/edificio.gd, scripts/visuals/PartesEdificio3D.gd) más «Tabiques» (lo que choca), «Cuartos» (por
## dónde se cruza, scripts/systems/RutaCuartos.gd), marcas, muebles y el cartel de la puerta.

const Piezas = preload("res://tools/casas/piezas_casa.gd")
const Cascaron = preload("res://tools/casas/cascaron_casa.gd")
const Cosas = preload("res://tools/casas/cosas_casa.gd")
const Pobre = preload("res://tools/casas/cosas_casa_pobre.gd")
const Juntar = preload("res://tools/casas/juntar_casa.gd")
const PARTES = preload("res://scripts/visuals/PartesEdificio3D.gd")
const EDIFICIO_GD = preload("res://mapa/edificio.gd")
const MUEBLE_GD = preload("res://mapa/mueble.gd")
const MARCA_GD = preload("res://mapa/marca.gd")
const TABIQUE_GD = preload("res://mapa/tabique.gd")
const CUARTO_GD = preload("res://mapa/cuarto.gd")
const CARTEL_GD = preload("res://mapa/cartel.gd")

const TABIQUE_GROSOR_M: float = 0.12   ## lo que se ve
const TABIQUE_CHOQUE_M: float = 0.15   ## lo que choca
const SOBRE_TABIQUE_M: float = 0.05    ## un hueco cae sobre un tabique si está a menos de esto
const CARTEL_ANCHO_M: float = 1.2
const TINTE := Color(0.9, 0.86, 0.8)


static func armar(plano: Dictionary, centro_original: Vector2) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = plano["ID"]
	raiz.set_script(EDIFICIO_GD)
	raiz.set("id_edificio", plano["ID"])
	raiz.set("centro_original", centro_original)
	raiz.set("planta_m", plano["PLANTA_M"])
	raiz.set("puerta_ancho_m", plano["PUERTA_ANCHO_M"])
	var grupos: Dictionary = {}
	for nombre: String in [PARTES.MUROS, PARTES.INTERIOR, PARTES.PISO_ALTO, PARTES.TEJADO, PARTES.MUEBLES, PARTES.MARCAS, TABIQUE_GD.CARPETA, CUARTO_GD.CARPETA]:
		grupos[nombre] = _hijo(raiz, Node3D.new(), nombre)
	Cascaron.armar(grupos[PARTES.MUROS], grupos[PARTES.TEJADO], plano)
	_tabiques(grupos[PARTES.INTERIOR], grupos[TABIQUE_GD.CARPETA], plano)
	for quieto: String in [PARTES.MUROS, PARTES.INTERIOR, PARTES.TEJADO]:
		Juntar.juntar(grupos[quieto], plano["ID"])
	_muebles(grupos[PARTES.MUEBLES], plano)
	for id: String in plano["MARCAS"]:
		var marca := _hijo(grupos[PARTES.MARCAS], Marker3D.new(), id, MARCA_GD) as Marker3D
		marca.set("id_marca", id)
		marca.position = _en_suelo(plano["MARCAS"][id], 0.0)
	for c: Dictionary in plano["CUARTOS"]:
		var cuarto := _hijo(grupos[CUARTO_GD.CARPETA], Node3D.new(), c["nombre"], CUARTO_GD)
		cuarto.position = _en_suelo(c["centro"], 0.0)
		cuarto.set("tam_m", c["tam"])
		cuarto.set("central", bool(c.get("central", false)))
		cuarto.set("paso_m", _en_suelo(c.get("paso", c["centro"]) - (c["centro"] as Vector2), 0.0))
	var cartel := _hijo(raiz, Node3D.new(), "Cartel", CARTEL_GD)
	cartel.position = plano["CARTEL_M"]
	cartel.set("ancho_m", CARTEL_ANCHO_M)
	_dar_dueno(raiz, raiz)
	return raiz


## Cada tabique: la pared que se ve (con sus huecos y las hojas de los cuartos) y los trozos que chocan entre hueco y hueco.
static func _tabiques(interior: Node3D, chocan: Node3D, plano: Dictionary) -> void:
	var pared: Material = Piezas.material(plano["TABIQUE"], TINTE)
	var hoja: Material = Piezas.material("door_wood.png", TINTE)
	var alto: float = Cascaron.MURO_ALTO_M - Cascaron.SUELO_Y_M
	for t: Array in plano["TABIQUES"]:
		var a: Vector2 = t[0]
		var b: Vector2 = t[1]
		var huecos: Array = []
		for c: Dictionary in plano["CUARTOS"]:
			if not c.has("paso") or Geometry2D.get_closest_point_to_segment(c["paso"], a, b).distance_to(c["paso"]) > SOBRE_TABIQUE_M:
				continue
			huecos.append({"en": a.distance_to(c["paso"]), "ancho": c["ancho"], "alto": Cascaron.PUERTA_HUECO_ALTO_M})
			if bool(c.get("hoja", false)):
				Piezas.puerta_de_cuarto(interior, _en_suelo(c["paso"], Cascaron.SUELO_Y_M), c["ancho"], is_equal_approx(a.x, b.x), hoja)
		Piezas.muro(interior, a, b, Cascaron.SUELO_Y_M, alto, TABIQUE_GROSOR_M, huecos, pared)
		_trozos_que_chocan(chocan, a, b, huecos)


static func _trozos_que_chocan(chocan: Node3D, a: Vector2, b: Vector2, huecos: Array) -> void:
	var largo: float = a.distance_to(b)
	var dir: Vector2 = (b - a) / largo
	var cortes: Array[float] = [0.0]
	var ordenados: Array = huecos.duplicate()
	ordenados.sort_custom(func(h1: Dictionary, h2: Dictionary) -> bool: return float(h1["en"]) < float(h2["en"]))
	for h: Dictionary in ordenados:
		cortes.append_array([float(h["en"]) - float(h["ancho"]) * 0.5, float(h["en"]) + float(h["ancho"]) * 0.5])
	cortes.append(largo)
	for i in range(0, cortes.size(), 2):
		var tramo: float = cortes[i + 1] - cortes[i]
		if tramo < 0.01:
			continue
		var tabique := _hijo(chocan, Node3D.new(), "Tabique", TABIQUE_GD)
		tabique.position = _en_suelo(a + dir * (cortes[i] + cortes[i + 1]) * 0.5, 0.0)
		var en_x: bool = absf(dir.x) > absf(dir.y)
		tabique.set("tam_m", Vector2(tramo, TABIQUE_CHOQUE_M) if en_x else Vector2(TABIQUE_CHOQUE_M, tramo))


## Muebles: el modelo comprado lo dibuja el juego; las cosas armadas a mano van dibujadas dentro de su pieza.
static func _muebles(grupo: Node3D, plano: Dictionary) -> void:
	var cuenta: Dictionary = {}
	for m: Dictionary in plano["MUEBLES"]:
		var base: String = String(m.get("cosa", String(m.get("modelo", "")).get_file().get_basename()))
		cuenta[base] = int(cuenta.get(base, 0)) + 1
		var nombre: String = base if int(cuenta[base]) == 1 else "%s%d" % [base, cuenta[base]]
		var pieza := _hijo(grupo, Node3D.new(), nombre, MUEBLE_GD)
		pieza.position = _en_suelo(m["pos"], 0.0 if bool(m.get("fuera", false)) else Cascaron.SUELO_Y_M)
		pieza.rotation_degrees.y = float(m.get("giro", 0.0))
		pieza.set("clave", "%s_%s" % [plano["ID"], nombre.to_lower()])
		pieza.set("modelo", String(m.get("modelo", "")))
		pieza.set("tam3", m.get("tam", Vector3.ZERO))
		pieza.set("choque", m.get("choque", Vector2.ZERO))
		if m.has("cosa"):
			_dibujar_cosa(pieza, m)


static func _dibujar_cosa(pieza: Node3D, m: Dictionary) -> void:
	match String(m["cosa"]):
		"alfombra":
			Cosas.alfombra(pieza, m["tam2"], m["color"])
		"bombilla":
			Cosas.bombilla(pieza, Cascaron.MURO_ALTO_M - Cascaron.SUELO_Y_M)
		"estufa":
			Cosas.estufa(pieza)
		"pila_con_bomba":
			Cosas.pila_con_bomba(pieza)
		"banera":
			Cosas.banera(pieza)
		"radio":
			Cosas.radio(pieza)
		"palangana":
			Cosas.palangana(pieza)
		"letrina":
			Cosas.letrina(pieza)
		"hogar":
			Pobre.hogar(pieza)
		"lena":
			Pobre.lena(pieza)
		"vela":
			Pobre.vela(pieza, float(m.get("alto", 0.0)))
		"tina":
			Pobre.tina(pieza)
		"tajo":
			Pobre.tajo(pieza)
		"radio_galena":
			Pobre.radio_galena(pieza)
		"linterna":
			Pobre.linterna(pieza)
		var otra:
			push_error("CASA: no sé armar «%s»" % otra)


static func _hijo(padre: Node3D, hijo: Node3D, nombre: String, guion: Script = null) -> Node3D:
	if guion != null:
		hijo.set_script(guion)
	hijo.name = nombre
	padre.add_child(hijo, true)
	return hijo


static func _en_suelo(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, p.y)


static func _dar_dueno(nodo: Node, raiz: Node) -> void:
	for hijo: Node in nodo.get_children():
		hijo.owner = raiz
		_dar_dueno(hijo, raiz)
