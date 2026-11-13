extends RefCounted

## Plano de la mansión del Señor del Valle (2026-11-13, interiores de tamaño real). Nivel 4: generador diésel propio,
## lámparas de techo, teléfono de baquelita, nevera, terminal verde en el despacho, agua corriente y baño completo.
## Un gran salón de punta a punta (recibidor junto a la puerta y, al fondo, la chimenea y la mesa de los banquetes);
## al oeste las alcobas del señor y de la señora y el despacho con el gabinete del Caso I; al este la cocina, el
## cuarto de la criada, el baño y el cuarto del heredero. Sin piso de arriba (el juego aún no tiene pisos en las casas):
## lo que el boceto ponía arriba va abajo. Piedra y teja roja. De 10,1 × 6,7 m a 19,6 × 14 m.
## Metros respecto al centro; x hacia el este, z hacia el sur (puerta al sur).
## Lo lee tools/casas/construir_casa.gd (por tools/casas/leer_plano.gd).

const ID := "building_mansion"
const PLANTA_M := Vector2(19.6, 14.0)
const PUERTA_X_M: float = 0.0        ## la puerta grande, en medio del muro sur (da al recibidor)
const PUERTA_ANCHO_M: float = 2.0
const VENTANA_X_M: float = -6.2      ## la ventana que se abre y se cierra (muro sur, la del despacho)
const CARTEL_M := Vector3(1.6, 2.4, 7.22)

const FACHADA := "wall_brick_stone_center.png"
const TABIQUE := "wall_brick_small_sand.png"
const MADERA := "floor_wood_planks_wide.png"
const BALDOSA := "floor_tiles_tan_large.png"
const LOSA := "floor_stone_pattern.png"   ## el suelo del salón
const TEJADO := "roof_clay_red_center.png"
const ZOCALO := "wall_stone.png"

const MESA_ALTO_M: float = 0.78
const TECHO_ALTO_M: float = 2.7      ## por donde corre el cable del generador, encima de las ventanas
const GRANATE := Color(0.42, 0.1, 0.12)
const AZUL_NOBLE := Color(0.16, 0.2, 0.36)

## Cuartos: el salón (central) da a la calle y a todos; los demás tienen su hueco en un tabique.
const CUARTOS: Array[Dictionary] = [
	{"nombre": "Salon", "centro": Vector2(0.0, 0.0), "tam": Vector2(5.2, 14.0), "central": true, "suelo": LOSA},
	{"nombre": "AlcobaSenor", "centro": Vector2(-6.2, -4.75), "tam": Vector2(7.2, 4.5), "paso": Vector2(-2.6, -3.1), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "AlcobaSenora", "centro": Vector2(-6.2, -0.25), "tam": Vector2(7.2, 4.5), "paso": Vector2(-2.6, -1.9), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "Despacho", "centro": Vector2(-6.2, 4.5), "tam": Vector2(7.2, 5.0), "paso": Vector2(-2.6, 2.6), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "Cocina", "centro": Vector2(6.2, -4.75), "tam": Vector2(7.2, 4.5), "paso": Vector2(2.6, -3.2), "ancho": 1.2, "hoja": false, "suelo": BALDOSA},
	{"nombre": "CuartoCriada", "centro": Vector2(6.2, -1.25), "tam": Vector2(7.2, 2.5), "paso": Vector2(2.6, -1.9), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	{"nombre": "Bano", "centro": Vector2(6.2, 1.25), "tam": Vector2(7.2, 2.5), "paso": Vector2(2.6, 0.6), "ancho": 0.9, "hoja": true, "suelo": BALDOSA},
	{"nombre": "CuartoHeredero", "centro": Vector2(6.2, 4.75), "tam": Vector2(7.2, 4.5), "paso": Vector2(2.6, 3.1), "ancho": 1.0, "hoja": true, "suelo": MADERA},
]

## Tabiques (de punta a punta); los huecos de los cuartos que caen encima se abren solos.
const TABIQUES: Array = [
	[Vector2(-2.6, -7.0), Vector2(-2.6, 7.0)],
	[Vector2(2.6, -7.0), Vector2(2.6, 7.0)],
	[Vector2(-9.8, -2.5), Vector2(-2.6, -2.5)],
	[Vector2(-9.8, 2.0), Vector2(-2.6, 2.0)],
	[Vector2(2.6, -2.5), Vector2(9.8, -2.5)],
	[Vector2(2.6, 0.0), Vector2(9.8, 0.0)],
	[Vector2(2.6, 2.5), Vector2(9.8, 2.5)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.2, "abre": true},
	{"lado": "sur", "en": 6.2, "ancho": 1.2},
	{"lado": "norte", "en": -6.2, "ancho": 1.2},
	{"lado": "norte", "en": 6.2, "ancho": 1.0},
	{"lado": "oeste", "en": -4.75, "ancho": 1.2},
	{"lado": "oeste", "en": 1.0, "ancho": 1.0},
	{"lado": "este", "en": -4.3, "ancho": 0.8},
	{"lado": "este", "en": 1.25, "ancho": 0.6},
	{"lado": "este", "en": 4.0, "ancho": 1.0},
]

## Muebles («choque» en píxeles del mapa, gira con el mueble; 0, 0 = se atraviesa; «giro» en grados).
const MUEBLES: Array[Dictionary] = [
	# Alcoba del señor (el cofre lo pone el juego en su marca, a los pies de la cama): cama, mesillas y ropero
	{"modelo": "props/Bed_Twin2.gltf", "pos": Vector2(-6.2, -5.87), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-7.15, -6.6), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-5.25, -6.6), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-9.5, -4.4), "giro": 90.0, "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"cosa": "alfombra", "pos": Vector2(-6.2, -4.6), "tam2": Vector2(2.4, 1.6), "color": GRANATE},
	{"cosa": "bombilla", "pos": Vector2(-6.2, -4.75)},
	# Alcoba de la señora: cama con la cabecera al oeste, mesilla, ropero, cómoda y gramola
	{"modelo": "props/Bed_Twin2.gltf", "pos": Vector2(-8.68, -0.25), "giro": 90.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-9.5, -1.3), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-5.6, -2.15), "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"modelo": "props/Workbench_Drawers.gltf", "pos": Vector2(-6.4, 1.65), "giro": 180.0, "tam": Vector3(1.2, 0.9, 0.55), "choque": Vector2(21, 10)},
	{"cosa": "tocadiscos", "pos": Vector2(-4.0, 1.7), "giro": 180.0, "choque": Vector2(9, 8)},
	{"cosa": "alfombra", "pos": Vector2(-6.6, -0.25), "tam2": Vector2(1.6, 2.4), "color": AZUL_NOBLE},
	{"cosa": "bombilla", "pos": Vector2(-6.2, -0.25)},
	# Despacho: escritorio con teléfono, sillón, librerías, la terminal verde (el gabinete lo pone el juego en su marca)
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-6.6, 5.0), "giro": 90.0, "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-7.55, 5.0), "giro": 90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "telefono", "pos": Vector2(-6.6, 5.5), "alto": MESA_ALTO_M},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-9.5, 3.75), "giro": 90.0, "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-9.5, 5.5), "giro": 90.0, "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"cosa": "terminal", "pos": Vector2(-8.5, 6.45), "giro": 180.0, "choque": Vector2(18, 11)},
	{"cosa": "alfombra", "pos": Vector2(-6.2, 4.6), "tam2": Vector2(2.6, 2.2), "color": GRANATE},
	{"cosa": "bombilla", "pos": Vector2(-6.2, 4.5)},
	# Salón, al fondo: chimenea, retratos de los antepasados y la mesa de los banquetes (dos mesas juntas), con sus
	# candelabros y ocho sillas; queda libre la franja de en medio, por donde se cruza de un ala a la otra
	{"cosa": "chimenea", "pos": Vector2(0.0, -6.45), "choque": Vector2(36, 16)},
	{"cosa": "retrato", "pos": Vector2(-1.75, -6.95)},
	{"cosa": "retrato", "pos": Vector2(1.75, -6.95)},
	{"cosa": "retrato", "pos": Vector2(-2.5, -5.0), "giro": 90.0},
	{"cosa": "retrato", "pos": Vector2(2.5, -5.0), "giro": -90.0},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-0.8, -4.6), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(0.8, -4.6), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"cosa": "candelabro", "pos": Vector2(-0.8, -4.6), "alto": MESA_ALTO_M},
	{"cosa": "candelabro", "pos": Vector2(0.8, -4.6), "alto": MESA_ALTO_M},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-1.0, -5.45), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(0.0, -5.45), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(1.0, -5.45), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-1.0, -3.75), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(0.0, -3.75), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(1.0, -3.75), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-1.95, -4.6), "giro": 90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(1.95, -4.6), "giro": -90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "alfombra", "pos": Vector2(0.0, -4.6), "tam2": Vector2(4.2, 2.6), "color": GRANATE},
	{"cosa": "lampara", "pos": Vector2(0.0, -4.6)},
	# Salón, junto a la puerta (el recibidor): teléfono, ropero de los abrigos, alfombra y otra lámpara
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-2.15, 6.55), "tam": Vector3(0.5, 0.6, 0.4)},
	{"cosa": "telefono", "pos": Vector2(-2.15, 6.55), "alto": 0.6},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(1.9, 6.55), "giro": 180.0, "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"cosa": "alfombra", "pos": Vector2(0.0, 4.2), "tam2": Vector2(2.2, 3.4), "color": AZUL_NOBLE},
	{"cosa": "lampara", "pos": Vector2(0.0, 3.6)},
	# Cocina: estufa, fregadero, nevera, mesa del servicio con bancos, estante y barril
	{"cosa": "estufa", "pos": Vector2(9.35, -6.0), "giro": -90.0, "choque": Vector2(14, 11)},
	{"cosa": "fregadero", "pos": Vector2(9.35, -4.3), "giro": -90.0, "choque": Vector2(18, 10)},
	{"cosa": "nevera", "pos": Vector2(9.35, -3.1), "giro": -90.0, "choque": Vector2(14, 13)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(5.8, -4.8), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(5.8, -5.55), "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(5.8, -4.05), "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(4.2, -6.75), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(3.2, -6.55), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
	{"cosa": "bombilla", "pos": Vector2(6.2, -4.75)},
	# Cuarto de la criada: cama con la cabecera al este, mesilla y taburete
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(8.68, -1.25), "giro": -90.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(9.5, -2.2), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Stool.gltf", "pos": Vector2(6.6, -2.1), "tam": Vector3(0.4, 0.5, 0.4)},
	{"cosa": "bombilla", "pos": Vector2(6.2, -1.25)},
	# Baño: retrete de cisterna, lavabo y bañera
	{"cosa": "inodoro", "pos": Vector2(4.0, 0.4), "choque": Vector2(8, 9)},
	{"cosa": "lavabo", "pos": Vector2(5.2, 0.35), "choque": Vector2(10, 7)},
	{"cosa": "banera", "pos": Vector2(8.9, 1.25), "giro": 90.0, "choque": Vector2(27, 12)},
	{"cosa": "bombilla", "pos": Vector2(6.2, 1.25)},
	# Cuarto del heredero: cama con la cabecera al este, mesilla, escritorio con silla, radio y librería
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(8.68, 5.8), "giro": -90.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(9.5, 4.85), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Workbench_Drawers.gltf", "pos": Vector2(5.0, 6.65), "giro": 180.0, "tam": Vector3(1.2, 0.9, 0.55), "choque": Vector2(21, 10)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(5.0, 6.0), "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "radio", "pos": Vector2(3.3, 6.65), "giro": 180.0, "choque": Vector2(11, 8)},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(6.0, 2.8), "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"cosa": "bombilla", "pos": Vector2(6.2, 4.75)},
	# Fuera: el generador diésel propio junto al muro oeste y el cuadro eléctrico junto a la puerta
	{"cosa": "generador", "pos": Vector2(-11.1, 4.0), "fuera": true},
	{"cosa": "cuadro_electrico", "pos": Vector2(-1.8, 7.2), "fuera": true},
	# El cable: sube del generador, corre por el muro oeste y la fachada por encima de las ventanas y baja al cuadro
	{"cosa": "cable", "pos": Vector2(-10.0, 4.0), "medida": Vector3(0.04, 2.24, 0.04), "alto": 0.5, "fuera": true},
	{"cosa": "cable", "pos": Vector2(-10.0, 5.59), "medida": Vector3(0.04, 0.04, 3.22), "alto": TECHO_ALTO_M, "fuera": true},
	{"cosa": "cable", "pos": Vector2(-5.9, 7.18), "medida": Vector3(8.24, 0.04, 0.04), "alto": TECHO_ALTO_M, "fuera": true},
	{"cosa": "cable", "pos": Vector2(-1.8, 7.18), "medida": Vector3(0.04, 1.24, 0.04), "alto": 1.5, "fuera": true},
]

## Marcas que lee la lógica (mapa/marca.gd): las camas del señor, la señora y el heredero; el despacho (el sello),
## el gabinete forzado del Caso I (lo dibuja el juego: queda libre), la mesa, el cofre, la puerta y la ventana.
const MARCAS: Dictionary = {
	"cama_1": Vector2(-6.2, -5.87),
	"cama_2": Vector2(-8.68, -0.25),
	"cama_3": Vector2(8.68, 5.8),
	"gabinete": Vector2(-8.2, 2.45),
	"despacho": Vector2(-7.6, 3.7),
	"mesa": Vector2(-1.4, -3.2),
	"cofre": Vector2(-6.2, -4.4),
	"puerta": Vector2(PUERTA_X_M, 7.0),
	"ventana": Vector2(VENTANA_X_M, 7.0),
}
