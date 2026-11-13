extends RefCounted

## Plano de la casa-taller acomodada del Arreglador y su familiar (2026-11-13, interiores de tamaño real). Nivel 3:
## bombilla en cada cuarto, agua corriente (fregadero, lavabo y retrete dentro, sin letrina), radio, gramola y
## ventilador de techo; en el taller, la terminal de pantalla verde; fuera, el generador diésel que da luz al pueblo y
## su cuadro eléctrico junto a la puerta, unidos por un cable por la fachada. Ladrillo y teja gris.
## De 7,2 × 5,4 m a 14 × 10 m.
## Se dibuja con la puerta al sur; la casa del Arreglador da al norte: se construye con «girar» (media vuelta).
## Metros respecto al centro de la casa; x hacia el este, z hacia el sur.
## Lo lee tools/casas/construir_casa.gd (por tools/casas/leer_plano.gd), que rehace la escena del edificio.

const ID := "mixed_family_tinker"
const PLANTA_M := Vector2(14.0, 10.0)
const PUERTA_X_M: float = -0.6       ## centro de la puerta de la calle, en el muro sur
const PUERTA_ANCHO_M: float = 1.6
const VENTANA_X_M: float = 4.2       ## la ventana que se abre y se cierra (muro sur, la del taller)
const CARTEL_M := Vector3(1.2, 2.4, 5.22)

## Texturas: fachada, tabiques, suelo de madera, suelo de baldosa, tejado y zócalo.
const FACHADA := "wall_brick_small_sand.png"
const TABIQUE := "wall_timber.png"
const MADERA := "floor_wood_planks_wide.png"
const BALDOSA := "floor_tiles_blue_small.png"
const TEJADO := "roof_clay_grey_center.png"
const ZOCALO := "wall_stone.png"

## Cuartos: la sala (central) da a la calle y a todos; los demás tienen su hueco en un tabique.
const CUARTOS: Array[Dictionary] = [
	{"nombre": "Sala", "centro": Vector2(-0.6, 0.0), "tam": Vector2(4.0, 10.0), "central": true, "suelo": MADERA},
	{"nombre": "DormitorioMaestro", "centro": Vector2(-4.8, -2.5), "tam": Vector2(4.4, 5.0), "paso": Vector2(-2.6, -1.4), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "DormitorioFamiliar", "centro": Vector2(-4.8, 2.5), "tam": Vector2(4.4, 5.0), "paso": Vector2(-2.6, 1.4), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "Bano", "centro": Vector2(4.2, -3.8), "tam": Vector2(5.6, 2.4), "paso": Vector2(1.4, -3.9), "ancho": 0.9, "hoja": true, "suelo": BALDOSA},
	{"nombre": "Cocina", "centro": Vector2(4.2, -0.8), "tam": Vector2(5.6, 3.6), "paso": Vector2(1.4, -1.6), "ancho": 1.2, "hoja": false, "suelo": BALDOSA},
	{"nombre": "Taller", "centro": Vector2(4.2, 3.0), "tam": Vector2(5.6, 4.0), "paso": Vector2(1.4, 2.6), "ancho": 1.6, "hoja": false, "suelo": MADERA},
]

## Tabiques (de punta a punta); los huecos de los cuartos que caen encima se abren solos.
const TABIQUES: Array = [
	[Vector2(-2.6, -5.0), Vector2(-2.6, 5.0)],
	[Vector2(-7.0, 0.0), Vector2(-2.6, 0.0)],
	[Vector2(1.4, -5.0), Vector2(1.4, 5.0)],
	[Vector2(1.4, -2.6), Vector2(7.0, -2.6)],
	[Vector2(1.4, 1.0), Vector2(7.0, 1.0)],
]

## Ventanas: muro (sur, norte, este, oeste), dónde (x en los muros sur y norte, z en este y oeste) y ancho.
const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.2, "abre": true},
	{"lado": "sur", "en": -4.8, "ancho": 1.0},
	{"lado": "norte", "en": -4.8, "ancho": 1.0},
	{"lado": "norte", "en": -0.6, "ancho": 1.0},
	{"lado": "norte", "en": 4.2, "ancho": 0.6},
	{"lado": "oeste", "en": -2.5, "ancho": 1.0},
	{"lado": "oeste", "en": 2.5, "ancho": 1.0},
	{"lado": "este", "en": -0.9, "ancho": 0.8},
	{"lado": "este", "en": 3.0, "ancho": 1.2},
]

## Muebles: modelo comprado («modelo») o cosa armada a mano («cosa», tools/casas/cosas_*.gd). «choque» en píxeles
## del mapa, sin girar (gira con el mueble; 0, 0 = se atraviesa); «giro» en grados.
const MUEBLES: Array[Dictionary] = [
	# Dormitorio del maestro (el cofre lo pone el juego en su marca)
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-6.35, -3.5), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-5.5, -4.6), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-3.5, -4.55), "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"cosa": "alfombra", "pos": Vector2(-4.8, -2.0), "tam2": Vector2(1.8, 1.2), "color": Color(0.35, 0.18, 0.2)},
	{"cosa": "bombilla", "pos": Vector2(-4.8, -2.5)},
	# Dormitorio del familiar
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-6.35, 3.5), "giro": 180.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-5.5, 4.6), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Chest_Wood.gltf", "pos": Vector2(-6.35, 1.8), "tam": Vector3(0.8, 0.5, 0.45), "choque": Vector2(14, 8)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(-3.6, 4.65), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"cosa": "bombilla", "pos": Vector2(-4.8, 2.5)},
	# Sala de estar: gramola, radio, sillas, ventilador, librería y el mostrador junto a la puerta
	{"cosa": "tocadiscos", "pos": Vector2(-2.0, -4.55), "choque": Vector2(9, 8)},
	{"cosa": "radio", "pos": Vector2(0.8, -4.55), "choque": Vector2(11, 8)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-1.2, -3.0), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(0.0, -3.0), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "alfombra", "pos": Vector2(-0.6, -3.4), "tam2": Vector2(2.6, 1.8), "color": Color(0.42, 0.16, 0.12)},
	{"cosa": "ventilador", "pos": Vector2(-0.6, -2.6)},
	{"cosa": "bombilla", "pos": Vector2(-0.6, 1.2)},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-2.2, 3.2), "giro": 90.0, "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Workbench_Drawers.gltf", "pos": Vector2(0.75, 4.1), "tam": Vector3(1.2, 0.9, 0.55), "choque": Vector2(21, 10)},
	# Cocina: estufa, fregadero con grifo, mesa de comer con cuatro sillas
	{"cosa": "estufa", "pos": Vector2(6.55, -2.0), "giro": 90.0, "choque": Vector2(14, 11)},
	{"cosa": "fregadero", "pos": Vector2(6.55, 0.3), "giro": 90.0, "choque": Vector2(18, 10)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(4.0, -0.8), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(3.55, -1.55), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(4.45, -1.55), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(3.55, -0.05), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(4.45, -0.05), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "bombilla", "pos": Vector2(4.0, -0.8)},
	# Baño: retrete de cisterna, lavabo y bañera
	{"cosa": "inodoro", "pos": Vector2(2.2, -4.6), "choque": Vector2(8, 9)},
	{"cosa": "lavabo", "pos": Vector2(3.4, -4.65), "choque": Vector2(10, 7)},
	{"cosa": "banera", "pos": Vector2(6.5, -3.8), "giro": 90.0, "choque": Vector2(27, 12)},
	{"cosa": "bombilla", "pos": Vector2(4.2, -3.8)},
	# Taller: banco, yunque, caja de herramientas y la terminal verde
	{"modelo": "props/Workbench.gltf", "pos": Vector2(6.45, 2.2), "giro": 90.0, "tam": Vector3(1.6, 0.9, 0.7), "choque": Vector2(28, 12)},
	{"cosa": "terminal", "pos": Vector2(6.5, 4.2), "giro": -90.0, "choque": Vector2(18, 11)},
	{"modelo": "props/Anvil.gltf", "pos": Vector2(3.6, 4.4), "tam": Vector3(0.7, 0.6, 0.35), "choque": Vector2(12, 7)},
	{"modelo": "props/Crate_Metal.gltf", "pos": Vector2(2.2, 4.4), "tam": Vector3(0.6, 0.6, 0.6), "choque": Vector2(11, 11)},
	{"cosa": "bombilla", "pos": Vector2(4.2, 3.0)},
	# Fuera: el generador diésel junto al muro oeste y el cuadro eléctrico junto a la puerta
	{"cosa": "generador", "pos": Vector2(-8.3, 0.8), "fuera": true},
	{"cosa": "cuadro_electrico", "pos": Vector2(-2.4, 5.2), "fuera": true},
	# El cable grueso: sube del generador, corre por el muro oeste y la fachada por encima de las ventanas y baja al cuadro
	{"cosa": "cable", "pos": Vector2(-7.2, 0.8), "medida": Vector3(0.04, 2.24, 0.04), "alto": 0.5, "fuera": true},
	{"cosa": "cable", "pos": Vector2(-7.2, 2.99), "medida": Vector3(0.04, 0.04, 4.42), "alto": 2.7, "fuera": true},
	{"cosa": "cable", "pos": Vector2(-4.8, 5.18), "medida": Vector3(4.84, 0.04, 0.04), "alto": 2.7, "fuera": true},
	{"cosa": "cable", "pos": Vector2(-2.4, 5.18), "medida": Vector3(0.04, 1.24, 0.04), "alto": 1.5, "fuera": true},
]

## Marcas que lee la lógica (mapa/marca.gd).
const MARCAS: Dictionary = {
	"terminal": Vector2(5.7, 4.2),
	"trabajo": Vector2(5.6, 2.2),
	"trabajo_familiar": Vector2(3.6, 3.5),
	"puesto": Vector2(0.75, 3.4),
	"cama_1": Vector2(-6.35, -3.5),
	"cama_2": Vector2(-6.35, 3.5),
	"mesa": Vector2(2.6, -0.8),
	"cofre": Vector2(-6.35, -1.8),
	"puerta": Vector2(PUERTA_X_M, 5.0),
	"ventana": Vector2(VENTANA_X_M, 5.0),
	"cuadro_electrico": Vector2(-2.4, 5.8),
	"generador": Vector2(-8.3, 0.8),
}
