extends RefCounted

## Plano de la Casa Grande de los Rentistas (2026-11-13, interiores de tamaño real): la primera casa de dos plantas.
## Nivel 4: generador propio, lámparas de techo, teléfono de baquelita, nevera y baño completo. Abajo: el recibidor con
## la escalera, el cuarto de cobro de rentas junto a la puerta (mesa con teléfono, sillas del rentista y del que paga,
## archivo y el cofre), el comedor con la vitrina, la cocina y la despensa. Arriba: las alcobas de los dos rentistas
## (sus puertas dan al rellano de la escalera), una salita con gramola y radio, el baño y un vestidor. Arenisca y teja roja. De 8,4 × 5,8 m a 11,2 × 8,4 m por planta.
## Metros respecto al centro; x hacia el este, z hacia el sur (puerta al sur). Lo de arriba va en los campos «…_ARRIBA».
## Lo lee tools/casas/construir_casa.gd (por tools/casas/leer_plano.gd).

const ID := "building_manor"
const PLANTA_M := Vector2(11.2, 8.4)
const PUERTA_X_M: float = 0.0        ## la puerta noble, en medio del muro sur (da al recibidor)
const PUERTA_ANCHO_M: float = 1.6
const VENTANA_X_M: float = -3.7      ## la ventana que se abre y se cierra (muro sur, la del cuarto de cobro)
const CARTEL_M := Vector3(1.6, 2.4, 4.42)

const FACHADA := "wall_brick_sand_center.png"
const TABIQUE := "wall_brick_small_sand.png"
const MADERA := "floor_wood_planks_wide.png"
const BALDOSA := "floor_tiles_tan_large.png"
const LOSA := "floor_stone_pattern.png"   ## el suelo del recibidor
const TEJADO := "roof_clay_red_center.png"
const ZOCALO := "wall_stone.png"

const MESA_ALTO_M: float = 0.78
const CABLE_ALTO_M: float = 2.7      ## por donde corre el cable del generador, encima de las ventanas de abajo
const GRANATE := Color(0.42, 0.1, 0.12)
const VERDE_NOBLE := Color(0.14, 0.26, 0.18)

## La escalera, recta en el recibidor junto al tabique este: sube hacia el norte, del pie (planta baja, en la parte
## abierta del recibidor) a la cima (planta alta, en el rellano del fondo, donde dan las puertas de las alcobas).
const ESCALERA: Dictionary = {"pie": Vector2(1.2, 0.4), "cima": Vector2(1.2, -2.8)}

const CUARTOS: Array[Dictionary] = [
	{"nombre": "Recibidor", "centro": Vector2(0.0, 0.0), "tam": Vector2(3.6, 8.4), "central": true, "suelo": LOSA},
	{"nombre": "Comedor", "centro": Vector2(-3.7, -1.3), "tam": Vector2(3.8, 5.8), "paso": Vector2(-1.8, 1.1), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	{"nombre": "CobroRentas", "centro": Vector2(-3.7, 2.9), "tam": Vector2(3.8, 2.6), "paso": Vector2(-1.8, 2.9), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "Cocina", "centro": Vector2(3.7, -1.2), "tam": Vector2(3.8, 6.0), "paso": Vector2(1.8, 1.2), "ancho": 0.9, "hoja": false, "suelo": BALDOSA},
	{"nombre": "Despensa", "centro": Vector2(3.7, 3.0), "tam": Vector2(3.8, 2.4), "paso": Vector2(1.8, 3.0), "ancho": 0.8, "hoja": true, "suelo": BALDOSA},
]

const TABIQUES: Array = [
	[Vector2(-1.8, -4.2), Vector2(-1.8, 4.2)],
	[Vector2(1.8, -4.2), Vector2(1.8, 4.2)],
	[Vector2(-5.6, 1.6), Vector2(-1.8, 1.6)],
	[Vector2(1.8, 1.8), Vector2(5.6, 1.8)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.2, "abre": true},
	{"lado": "sur", "en": 3.7, "ancho": 0.6},
	{"lado": "norte", "en": -3.7, "ancho": 1.2},
	{"lado": "norte", "en": 3.7, "ancho": 0.8},
	{"lado": "oeste", "en": -1.3, "ancho": 1.0},
	{"lado": "oeste", "en": 2.9, "ancho": 1.0},
	{"lado": "este", "en": -2.2, "ancho": 0.8},
	{"lado": "este", "en": 3.0, "ancho": 0.6},
]

const MUEBLES: Array[Dictionary] = [
	# Cuarto de cobro de rentas: mesa con teléfono, la silla del rentista y la del que paga, archivo (el cofre lo pone el juego)
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-4.6, 2.9), "giro": 90.0, "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-5.35, 2.9), "giro": 90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-3.85, 2.9), "giro": -90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "telefono", "pos": Vector2(-4.6, 2.4), "alto": MESA_ALTO_M},
	{"cosa": "candelabro", "pos": Vector2(-4.6, 3.4), "alto": MESA_ALTO_M},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-3.0, 1.88), "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"cosa": "alfombra", "pos": Vector2(-4.2, 2.9), "tam2": Vector2(2.4, 2.0), "color": VERDE_NOBLE},
	{"cosa": "bombilla", "pos": Vector2(-3.7, 2.9)},
	# Comedor: mesa con cuatro sillas, la vitrina y la lámpara
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-3.7, -2.2), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-4.2, -3.0), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-3.2, -3.0), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-4.2, -1.4), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-3.2, -1.4), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-5.3, -2.2), "giro": 90.0, "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"cosa": "lampara", "pos": Vector2(-3.7, -2.2)},
	# Recibidor: retratos, dos sillones y lámpara (la escalera la pone el constructor)
	{"cosa": "retrato", "pos": Vector2(-0.6, -4.15)},
	{"cosa": "retrato", "pos": Vector2(-1.7, -2.6), "giro": 90.0},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-1.3, -1.0), "giro": 90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-1.3, -1.8), "giro": 90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "alfombra", "pos": Vector2(-0.3, 2.6), "tam2": Vector2(2.2, 2.6), "color": GRANATE},
	{"cosa": "lampara", "pos": Vector2(-0.3, 1.6)},
	# Cocina: estufa, fregadero, nevera, mesa del servicio con bancos y estante
	{"cosa": "estufa", "pos": Vector2(5.25, -3.6), "giro": -90.0, "choque": Vector2(14, 11)},
	{"cosa": "fregadero", "pos": Vector2(5.25, -2.2), "giro": -90.0, "choque": Vector2(18, 10)},
	{"cosa": "nevera", "pos": Vector2(5.25, -1.1), "giro": -90.0, "choque": Vector2(14, 13)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(3.4, -2.2), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(3.4, -2.95), "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(3.4, -1.45), "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(3.3, -3.95), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"cosa": "bombilla", "pos": Vector2(3.7, -1.2)},
	# Despensa: sacos, barril, caja y estante
	{"modelo": "props/Bag.gltf", "pos": Vector2(5.1, 2.4), "tam": Vector3(0.6, 0.7, 0.5), "choque": Vector2(10, 9)},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(5.1, 3.5), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(4.0, 3.75), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(3.6, 2.0), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	# Fuera: el generador junto al muro oeste y el cuadro junto a la puerta, unidos por el cable por encima de las ventanas
	{"cosa": "generador", "pos": Vector2(-7.1, 1.0), "fuera": true},
	{"cosa": "cuadro_electrico", "pos": Vector2(-1.2, 4.4), "fuera": true},
	{"cosa": "cable", "pos": Vector2(-5.8, 1.0), "medida": Vector3(0.04, 2.24, 0.04), "alto": 0.5, "fuera": true},
	{"cosa": "cable", "pos": Vector2(-5.8, 2.69), "medida": Vector3(0.04, 0.04, 3.42), "alto": CABLE_ALTO_M, "fuera": true},
	{"cosa": "cable", "pos": Vector2(-3.5, 4.38), "medida": Vector3(4.64, 0.04, 0.04), "alto": CABLE_ALTO_M, "fuera": true},
	{"cosa": "cable", "pos": Vector2(-1.2, 4.38), "medida": Vector3(0.04, 1.24, 0.04), "alto": 1.5, "fuera": true},
]

const MARCAS: Dictionary = {
	"despacho": Vector2(-3.1, 3.4),
	"mesa": Vector2(-2.5, -2.2),
	"cofre": Vector2(-2.4, 3.7),
	"puerta": Vector2(PUERTA_X_M, 4.2),
	"ventana": Vector2(VENTANA_X_M, 4.2),
}

# ---------------------------------------------------------------- planta alta
const CUARTOS_ARRIBA: Array[Dictionary] = [
	{"nombre": "Distribuidor", "centro": Vector2(0.0, 0.0), "tam": Vector2(3.6, 8.4), "central": true, "suelo": MADERA},
	{"nombre": "AlcobaPrimera", "centro": Vector2(-3.7, -2.1), "tam": Vector2(3.8, 4.2), "paso": Vector2(-1.8, -3.7), "ancho": 0.8, "hoja": true, "suelo": MADERA},
	{"nombre": "AlcobaSegunda", "centro": Vector2(3.7, -2.1), "tam": Vector2(3.8, 4.2), "paso": Vector2(1.8, -3.6), "ancho": 0.8, "hoja": true, "suelo": MADERA},
	{"nombre": "Salita", "centro": Vector2(-3.7, 2.1), "tam": Vector2(3.8, 4.2), "paso": Vector2(-1.8, 2.0), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "Bano", "centro": Vector2(3.7, 1.0), "tam": Vector2(3.8, 2.0), "paso": Vector2(1.8, 1.0), "ancho": 0.8, "hoja": true, "suelo": BALDOSA},
	{"nombre": "Vestidor", "centro": Vector2(3.7, 3.1), "tam": Vector2(3.8, 2.2), "paso": Vector2(1.8, 3.1), "ancho": 0.8, "hoja": true, "suelo": MADERA},
]

const TABIQUES_ARRIBA: Array = [
	[Vector2(-1.8, -4.2), Vector2(-1.8, 4.2)],
	[Vector2(1.8, -4.2), Vector2(1.8, 4.2)],
	[Vector2(-5.6, 0.0), Vector2(-1.8, 0.0)],
	[Vector2(1.8, 0.0), Vector2(5.6, 0.0)],
	[Vector2(1.8, 2.0), Vector2(5.6, 2.0)],
]

const VENTANAS_ARRIBA: Array[Dictionary] = [
	{"lado": "sur", "en": -3.7, "ancho": 1.2},
	{"lado": "sur", "en": 0.0, "ancho": 1.0},
	{"lado": "sur", "en": 3.7, "ancho": 0.8},
	{"lado": "norte", "en": -3.7, "ancho": 1.2},
	{"lado": "norte", "en": 3.7, "ancho": 1.2},
	{"lado": "oeste", "en": -2.1, "ancho": 1.0},
	{"lado": "oeste", "en": 2.1, "ancho": 1.0},
	{"lado": "este", "en": -2.1, "ancho": 1.0},
	{"lado": "este", "en": 1.0, "ancho": 0.6},
]

const MUEBLES_ARRIBA: Array[Dictionary] = [
	# Alcoba del primer rentista: cama con la cabecera al tabique sur, mesillas, ropero y alfombra
	{"modelo": "props/Bed_Twin2.gltf", "pos": Vector2(-3.9, -1.13), "giro": 180.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-4.85, -0.2), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-2.95, -0.2), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-5.3, -3.0), "giro": 90.0, "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"cosa": "alfombra", "pos": Vector2(-3.9, -2.6), "tam2": Vector2(2.0, 1.4), "color": GRANATE},
	{"cosa": "bombilla", "pos": Vector2(-3.7, -2.1)},
	# Alcoba del segundo: igual pero al otro lado del rellano, con cómoda en vez de ropero
	{"modelo": "props/Bed_Twin2.gltf", "pos": Vector2(3.9, -1.13), "giro": 180.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(2.95, -0.2), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(4.85, -0.2), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Workbench_Drawers.gltf", "pos": Vector2(5.3, -3.0), "giro": -90.0, "tam": Vector3(1.2, 0.9, 0.55), "choque": Vector2(21, 10)},
	{"cosa": "alfombra", "pos": Vector2(3.9, -2.6), "tam2": Vector2(2.0, 1.4), "color": VERDE_NOBLE},
	{"cosa": "bombilla", "pos": Vector2(3.7, -2.1)},
	# Distribuidor: retrato en el rellano y lámpara
	{"cosa": "retrato", "pos": Vector2(-0.6, -4.15)},
	{"cosa": "lampara", "pos": Vector2(-0.6, 2.0)},
	# Salita: sillones, gramola, radio, librería y lámpara
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-3.6, 1.6), "giro": 90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-3.6, 2.6), "giro": 90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "tocadiscos", "pos": Vector2(-5.3, 0.6), "giro": 90.0, "choque": Vector2(9, 8)},
	{"cosa": "radio", "pos": Vector2(-5.3, 2.4), "giro": 90.0, "choque": Vector2(11, 8)},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-3.7, 4.0), "giro": 180.0, "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"cosa": "alfombra", "pos": Vector2(-4.2, 2.1), "tam2": Vector2(2.2, 2.4), "color": GRANATE},
	{"cosa": "lampara", "pos": Vector2(-3.9, 2.1)},
	# Baño: bañera, retrete y lavabo
	{"cosa": "banera", "pos": Vector2(5.0, 1.0), "giro": 90.0, "choque": Vector2(27, 12)},
	{"cosa": "inodoro", "pos": Vector2(3.0, 0.3), "choque": Vector2(8, 9)},
	{"cosa": "lavabo", "pos": Vector2(3.9, 0.25), "choque": Vector2(10, 7)},
	{"cosa": "bombilla", "pos": Vector2(3.7, 1.0)},
	# Vestidor: ropero y silla
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(5.3, 3.1), "giro": -90.0, "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(3.6, 3.8), "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "bombilla", "pos": Vector2(3.7, 3.1)},
]

## Las camas de los dos rentistas, arriba (el juego lo sabe por su altura).
const MARCAS_ARRIBA: Dictionary = {
	"cama_1": Vector2(-3.9, -1.13),
	"cama_2": Vector2(3.9, -1.13),
}
