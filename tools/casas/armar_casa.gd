extends RefCounted

## Arma la escena entera de una casa a partir de su plano (tools/casas/plano_*.gd), 2026-11-13: los grupos fijos de un
## edificio (mapa/edificio.gd, scripts/visuals/PartesEdificio3D.gd) más «Tabiques» (lo que choca), «Cuartos» (por
## dónde se cruza, scripts/systems/RutaCuartos.gd), marcas, muebles y el cartel de la puerta. En las casas de dos
## plantas, lo de arriba va a la altura de la planta alta (así lo reconoce el juego) y se ve con «PisoAlto».

const Piezas = preload("res://tools/casas/piezas_casa.gd")
const Cascaron = preload("res://tools/casas/cascaron_casa.gd")
const DibujarCosa = preload("res://tools/casas/dibujar_cosa.gd")
const Juntar = preload("res://tools/casas/juntar_casa.gd")
const LeerPlano = preload("res://tools/casas/leer_plano.gd")
const PlantaAlta = preload("res://tools/casas/planta_alta.gd")
const PisosCasas = preload("res://scripts/fisica/PisosCasas.gd")
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
	var cuenta_muebles: Dictionary = {}
	for piso: int in range(LeerPlano.PLANTAS.size()):
		var planta: String = LeerPlano.PLANTAS[piso]
		if not plano.has("CUARTOS" + planta):
			continue
		var y: float = PlantaAlta.alto_m() if piso > 0 else 0.0 # lo de arriba, a la altura de la planta alta
		_tabiques(grupos[PARTES.PISO_ALTO if piso > 0 else PARTES.INTERIOR], grupos[TABIQUE_GD.CARPETA], plano, planta, y)
		_muebles(grupos[PARTES.MUEBLES], plano, planta, piso, cuenta_muebles)
		_marcas(grupos[PARTES.MARCAS], plano["MARCAS" + planta], y)
		_cuartos(grupos[CUARTO_GD.CARPETA], plano["CUARTOS" + planta], y)
	if PlantaAlta.tiene(plano):
		for choque: Array in PlantaAlta.armar(grupos[PARTES.INTERIOR], grupos[PARTES.PISO_ALTO], plano):
			_trozos_que_chocan(grupos[TABIQUE_GD.CARPETA], choque[0], choque[1], [], PlantaAlta.alto_m() if int(choque[2]) > 0 else 0.0)
		_marcas(grupos[PARTES.MARCAS], {PisosCasas.PIE: plano["ESCALERA"]["pie"]}, 0.0)
		_marcas(grupos[PARTES.MARCAS], {PisosCasas.CIMA: plano["ESCALERA"]["cima"]}, PlantaAlta.alto_m())
	for quieto: String in [PARTES.MUROS, PARTES.INTERIOR, PARTES.TEJADO, PARTES.PISO_ALTO]:
		Juntar.juntar(grupos[quieto], plano["ID"])
	var cartel := _hijo(raiz, Node3D.new(), "Cartel", CARTEL_GD)
	cartel.position = plano["CARTEL_M"]
	if plano.get("PUERTA_LADO", "sur") == "norte":
		cartel.rotation_degrees.y = 180.0 # de cara a la calle del norte
	cartel.set("ancho_m", CARTEL_ANCHO_M)
	_dar_dueno(raiz, raiz)
	return raiz


## Cada tabique de una planta (`planta`: "" la baja, "_ARRIBA" la alta, cuyo suelo está a `y`): la pared que se ve
## (con sus huecos y las hojas de los cuartos) y los trozos que chocan entre hueco y hueco. En una casa de dos plantas,
## los de abajo suben hasta el techo (el suelo de arriba).
static func _tabiques(visto: Node3D, chocan: Node3D, plano: Dictionary, planta: String, y: float) -> void:
	var pared: Material = Piezas.material(plano["TABIQUE"], TINTE)
	var hoja: Material = Piezas.material("door_wood.png", TINTE)
	var suelo: float = y if y > 0.0 else Cascaron.SUELO_Y_M
	var alto: float = PlantaAlta.alto_m() - Cascaron.SUELO_Y_M if (y <= 0.0 and PlantaAlta.tiene(plano)) else Cascaron.MURO_ALTO_M - Cascaron.SUELO_Y_M
	for t: Array in plano["TABIQUES" + planta]:
		var a: Vector2 = t[0]
		var b: Vector2 = t[1]
		var huecos: Array = []
		for c: Dictionary in plano["CUARTOS" + planta]:
			if not c.has("paso") or Geometry2D.get_closest_point_to_segment(c["paso"], a, b).distance_to(c["paso"]) > SOBRE_TABIQUE_M:
				continue
			huecos.append({"en": a.distance_to(c["paso"]), "ancho": c["ancho"], "alto": Cascaron.PUERTA_HUECO_ALTO_M})
			if bool(c.get("hoja", false)):
				Piezas.puerta_de_cuarto(visto, _en_suelo(c["paso"], suelo), c["ancho"], is_equal_approx(a.x, b.x), hoja, 1 if y > 0.0 else 0)
		Piezas.muro(visto, a, b, suelo, alto, TABIQUE_GROSOR_M, huecos, pared)
		_trozos_que_chocan(chocan, a, b, huecos, y)


## Los trozos de pared que chocan (mapa/tabique.gd), a la altura `y` de su planta.
static func _trozos_que_chocan(chocan: Node3D, a: Vector2, b: Vector2, huecos: Array, y: float) -> void:
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
		tabique.position = _en_suelo(a + dir * (cortes[i] + cortes[i + 1]) * 0.5, y)
		var en_x: bool = absf(dir.x) > absf(dir.y)
		tabique.set("tam_m", Vector2(tramo, TABIQUE_CHOQUE_M) if en_x else Vector2(TABIQUE_CHOQUE_M, tramo))


## Muebles de una planta: el modelo comprado lo dibuja el juego; las cosas armadas a mano van dibujadas dentro de su pieza.
## `cuenta`: cuántos van de cada clase (la comparten las dos plantas para que no se repitan los nombres).
static func _muebles(grupo: Node3D, plano: Dictionary, planta: String, piso: int, cuenta: Dictionary) -> void:
	for m: Dictionary in plano["MUEBLES" + planta]:
		var base: String = String(m.get("cosa", String(m.get("modelo", "")).get_file().get_basename()))
		cuenta[base] = int(cuenta.get(base, 0)) + 1
		var nombre: String = base if int(cuenta[base]) == 1 else "%s%d" % [base, cuenta[base]]
		var pieza := _hijo(grupo, Node3D.new(), nombre, MUEBLE_GD)
		pieza.position = _en_suelo(m["pos"], PlantaAlta.alto_m() if piso > 0 else (0.0 if bool(m.get("fuera", false)) else Cascaron.SUELO_Y_M))
		pieza.set("piso", piso)
		pieza.rotation_degrees.y = float(m.get("giro", 0.0))
		pieza.set("clave", "%s_%s" % [plano["ID"], nombre.to_lower()])
		pieza.set("modelo", String(m.get("modelo", "")))
		pieza.set("tam3", m.get("tam", Vector3.ZERO))
		pieza.set("choque", m.get("choque", Vector2.ZERO))
		if m.has("cosa"):
			DibujarCosa.dibujar(pieza, m)


static func _marcas(grupo: Node3D, marcas: Dictionary, y: float) -> void:
	for id: String in marcas:
		var marca := _hijo(grupo, Marker3D.new(), id, MARCA_GD) as Marker3D
		marca.set("id_marca", id)
		marca.position = _en_suelo(marcas[id], y)


static func _cuartos(grupo: Node3D, cuartos: Array, y: float) -> void:
	for c: Dictionary in cuartos:
		var cuarto := _hijo(grupo, Node3D.new(), c["nombre"], CUARTO_GD)
		cuarto.position = _en_suelo(c["centro"], y)
		cuarto.set("tam_m", c["tam"])
		cuarto.set("central", bool(c.get("central", false)))
		cuarto.set("paso_m", _en_suelo(c.get("paso", c["centro"]) - (c["centro"] as Vector2), 0.0))


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
