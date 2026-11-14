extends RefCounted

## AlturasChoque3D: a qué altura va cada pared 3D del mundo (ChoquesMundo3D): desde qué suelo se levanta y qué franja
## ocupa (toda la altura, solo planta baja, solo planta alta, bajo tierra, barandilla). Paso a 3D, tanda 3a (2026-11-14).
## Sin estado. Las alturas salen de las reglas de Suelo.gd mientras los pisos no sean losas 3D de verdad (tanda 3b).

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Suelo = preload("res://scripts/fisica/Suelo.gd")
const WorldStageBase3D = preload("res://scripts/visuals/WorldStageBase3D.gd")

const GRUPOS_BAJO_TIERRA: Array[String] = ["sewer_network_2d", "club_world"]
const ALTO_MURO_M: float = 9.0     ## sube hasta aquí sobre la calle (dos plantas: no se salta por encima)
const BAJO_CALLE_M: float = 4.2    ## y baja esto: los muros de una casa también cierran su sótano
const BAJO_PISO_M: float = 0.5     ## un choque de un solo piso empieza este poco por debajo de su suelo
const ALTO_PISO_M: float = 4.0     ## lo que sube un choque de la planta alta desde su suelo
const HOLGURA_TECHO_M: float = 0.15 ## un choque de la planta baja acaba este poco antes del suelo de arriba
const ALTO_BARANDILLA_M: float = 1.05 ## las barandillas llegan a la cintura: se pueden saltar
const TARIMA_MAS_ALTA_PX: float = 2.95 ## la tarima de planta baja más alta (la de la posada; las casas, 2,65)


## Altura 3D del suelo de abajo en ese punto: la calle o la planta baja; bajo tierra, el suelo del sótano.
static func suelo_y(p: Vector2, bajo_tierra: bool, vm: Node) -> float:
	var relieve: float = WorldStageBase3D.terrain_height_px(p)
	if bajo_tierra:
		return Mapa3D.a_3d(p, relieve + Suelo.PROFUNDIDAD_SOTANO_PX).y
	var pisos: Array[float] = Suelo.pisos_en(p)
	var suelo_px: float = pisos[0] if not pisos.is_empty() else Suelo.altura_px(p, 0, vm)
	return Mapa3D.a_3d(p, relieve + suelo_px).y


## Desde dónde (x) y cuánto sube (y) un choque, en metros sobre su suelo de abajo.
static func franja(piso: int, bajo_tierra: bool, barandilla: bool) -> Vector2:
	var planta_alta: float = Mapa3D.alto_a_3d(Mapa3D.PISO_ALTO_PX - TARIMA_MAS_ALTA_PX) # del suelo de abajo al de arriba
	var f := Vector2(-BAJO_CALLE_M, ALTO_MURO_M + BAJO_CALLE_M)
	if bajo_tierra: # las paredes del club y de las alcantarillas no asoman a la calle
		f = Vector2(-BAJO_PISO_M, -Mapa3D.alto_a_3d(Suelo.PROFUNDIDAD_SOTANO_PX) + BAJO_PISO_M - HOLGURA_TECHO_M * 2.0)
	elif piso == 0:
		f = Vector2(-BAJO_PISO_M, planta_alta + BAJO_PISO_M - HOLGURA_TECHO_M)
	elif piso == 1:
		f = Vector2(planta_alta - 0.05, ALTO_PISO_M)
	if barandilla:
		f.y = ALTO_BARANDILLA_M
	return f


static func es_bajo_tierra(nodo: Node) -> bool:
	var n: Node = nodo
	while n != null:
		for g in GRUPOS_BAJO_TIERRA:
			if n.is_in_group(g):
				return true
		n = n.get_parent()
	return false
