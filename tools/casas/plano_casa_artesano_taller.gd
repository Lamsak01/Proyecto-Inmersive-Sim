extends RefCounted

## Plano de la casa-taller de una familia artesana de dos que trabaja y vende en casa (2026-11-13, interiores de tamaño
## real): panadería, sastrería, herbolaria, granja y rancho. Nivel 2, artesano, como la casa del herrero: estufa de
## hierro y bomba de agua (aquí en la sala, que hace de cocina), bombillas de la red del pueblo en sala y taller, radio
## de válvulas, quinqués en los dormitorios, bañera de cinc y letrina en el patio. El mostrador da a la puerta.
## Lo propio de cada oficio (horno, maniquí, caldero…) va en POR_OFICIO. De 7,2 × 5,4 m a 12,6 × 9 m.
## Metros respecto al centro de la casa; x hacia el este, z hacia el sur (la puerta de la calle da al sur).
## Lo lee tools/casas/construir_casa.gd (por tools/casas/leer_plano.gd), que rehace la escena del edificio.

const ID := "mixed_family_baker"
const PLANTA_M := Vector2(12.6, 9.0)
const PUERTA_X_M: float = 0.0        ## centro de la puerta de la calle, en el muro sur
const PUERTA_ANCHO_M: float = 1.6
const VENTANA_X_M: float = 3.0       ## la ventana que se abre y se cierra (muro sur, la del taller; el horno, al lado)
const CARTEL_M := Vector3(-1.45, 2.4, 4.72)

## Texturas: fachada, tabiques, suelo de madera, suelo de baldosa, tejado y zócalo.
const FACHADA := "wall_timber_structure_horizontal.png"
const TABIQUE := "wall_timber.png"
const MADERA := "floor_wood_planks.png"
const BALDOSA := "floor_tiles_tan_small.png"
const TEJADO := "roof_clay_red_center.png"
const ZOCALO := "wall_stone.png"

## Cuartos: la sala-cocina con el mostrador (central) da a la calle y a todos; los demás tienen su hueco en un tabique.
const CUARTOS: Array[Dictionary] = [
	{"nombre": "Sala", "centro": Vector2(0.0, 0.0), "tam": Vector2(4.0, 9.0), "central": true, "suelo": BALDOSA},
	{"nombre": "DormitorioMaestro", "centro": Vector2(-4.15, -2.25), "tam": Vector2(4.3, 4.5), "paso": Vector2(-2.0, -1.2), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "DormitorioFamiliar", "centro": Vector2(-4.15, 2.25), "tam": Vector2(4.3, 4.5), "paso": Vector2(-2.0, 1.2), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "Aseo", "centro": Vector2(4.15, -3.0), "tam": Vector2(4.3, 3.0), "paso": Vector2(2.0, -2.6), "ancho": 0.9, "hoja": true, "suelo": BALDOSA},
	{"nombre": "Taller", "centro": Vector2(4.15, 1.5), "tam": Vector2(4.3, 6.0), "paso": Vector2(2.0, 1.0), "ancho": 1.6, "hoja": false, "suelo": MADERA},
]

## Tabiques (de punta a punta); los huecos de los cuartos que caen encima se abren solos.
const TABIQUES: Array = [
	[Vector2(-2.0, -4.5), Vector2(-2.0, 4.5)],
	[Vector2(-6.3, 0.0), Vector2(-2.0, 0.0)],
	[Vector2(2.0, -4.5), Vector2(2.0, 4.5)],
	[Vector2(2.0, -1.5), Vector2(6.3, -1.5)],
]

## Ventanas: muro (sur, norte, este, oeste), dónde (x en los muros sur y norte, z en este y oeste) y ancho.
const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.2, "abre": true},
	{"lado": "sur", "en": -4.15, "ancho": 1.0},
	{"lado": "oeste", "en": -2.25, "ancho": 1.0},
	{"lado": "norte", "en": 4.15, "ancho": 0.6},
	{"lado": "norte", "en": 1.5, "ancho": 0.8},
	{"lado": "este", "en": 1.5, "ancho": 1.0},
]

## Muebles: modelo comprado («modelo») o cosa armada a mano («cosa», tools/casas/cosas_*.gd). «choque» en píxeles
## del mapa, sin girar (gira con el mueble; 0, 0 = se atraviesa); «giro» en grados; «alto» del quinqué, en metros.
const MUEBLES: Array[Dictionary] = MUEBLES_CASA + MUEBLES_TALLER

## Lo de vivir (dormitorios, sala-cocina, aseo y letrina); la posada de los Candil lo reutiliza con otro cuarto del fondo.
const MUEBLES_CASA: Array[Dictionary] = [
	# Dormitorio del maestro (el cofre lo pone el juego en su marca)
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-5.45, -3.3), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-4.6, -4.15), "tam": Vector3(0.5, 0.6, 0.4)},
	{"cosa": "vela", "pos": Vector2(-4.6, -4.15), "alto": 0.6},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-2.9, -4.1), "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"cosa": "alfombra", "pos": Vector2(-4.3, -1.6), "tam2": Vector2(1.6, 1.0), "color": Color(0.45, 0.2, 0.15)},
	# Dormitorio del familiar
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-5.45, 3.3), "giro": 180.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Chest_Wood.gltf", "pos": Vector2(-5.45, 1.75), "tam": Vector3(0.8, 0.5, 0.45), "choque": Vector2(14, 8)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(-3.4, 0.3), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-3.0, 3.9), "tam": Vector3(0.4, 0.5, 0.4)},
	{"cosa": "vela", "pos": Vector2(-3.0, 3.9), "alto": 0.5},
	# Sala-cocina: estufa, pila con bomba, mesa con sillas, radio, bombilla y el mostrador junto a la puerta
	{"cosa": "estufa", "pos": Vector2(-1.2, -4.07), "choque": Vector2(14, 11)},
	{"cosa": "pila_con_bomba", "pos": Vector2(0.6, -4.15), "choque": Vector2(18, 10)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(0.0, -1.9), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-0.45, -2.65), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(0.45, -2.65), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-0.45, -1.15), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(0.45, -1.15), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "bombilla", "pos": Vector2(0.0, -1.9)},
	{"cosa": "radio", "pos": Vector2(-1.6, -3.1), "giro": 90.0, "choque": Vector2(11, 8)},
	{"cosa": "alfombra", "pos": Vector2(0.0, 1.4), "tam2": Vector2(2.2, 1.4), "color": Color(0.3, 0.32, 0.18)},
	{"modelo": "props/Workbench_Drawers.gltf", "pos": Vector2(1.3, 3.6), "tam": Vector3(1.2, 0.9, 0.55), "choque": Vector2(21, 10)},
	# Aseo: bañera de cinc, palangana y cubo
	{"cosa": "banera", "pos": Vector2(5.35, -3.6), "choque": Vector2(27, 12)},
	{"cosa": "palangana", "pos": Vector2(2.6, -4.05), "choque": Vector2(7, 7)},
	{"modelo": "props/Bucket_Wooden_1.gltf", "pos": Vector2(3.6, -4.1), "tam": Vector3(0.4, 0.4, 0.4)},
	# Patio trasero: la letrina
	{"cosa": "letrina", "pos": Vector2(4.6, -6.6), "choque": Vector2(22, 22), "fuera": true},
]

## Taller: banco de trabajo, estante, caja, barril y bombilla (lo de cada oficio, en POR_OFICIO).
const MUEBLES_TALLER: Array[Dictionary] = [
	{"modelo": "props/Workbench.gltf", "pos": Vector2(5.75, 0.6), "giro": 90.0, "tam": Vector3(1.6, 0.9, 0.7), "choque": Vector2(28, 12)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(6.0, 3.2), "giro": 90.0, "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(2.6, -1.0), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(5.8, -1.0), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
	{"cosa": "bombilla", "pos": Vector2(4.15, 1.5)},
]

## Lo propio de cada oficio, en el taller: un rincón al fondo (4.6, 3.7) y otro junto al tabique del aseo (3.8, -1.0).
const POR_OFICIO: Dictionary = {
	"mixed_family_baker": [
		{"cosa": "horno", "pos": Vector2(4.3, 3.75), "giro": 180.0, "choque": Vector2(25, 20)},
		{"modelo": "props/Bag.gltf", "pos": Vector2(3.8, -1.0), "tam": Vector3(0.5, 0.6, 0.4)},
	],
	"mixed_family_tailor": [
		{"modelo": "props/Dummy.gltf", "pos": Vector2(4.6, 3.7), "tam": Vector3(0.5, 1.7, 0.4), "choque": Vector2(8, 8)},
		{"modelo": "props/Bag.gltf", "pos": Vector2(3.8, -1.0), "tam": Vector3(0.5, 0.6, 0.4)},
	],
	"mixed_family_herbalist": [
		{"modelo": "props/Cauldron.gltf", "pos": Vector2(4.6, 3.7), "tam": Vector3(0.7, 0.6, 0.7), "choque": Vector2(12, 12)},
		{"modelo": "props/Shelf_Small_Bottles.gltf", "pos": Vector2(3.8, -1.15), "tam": Vector3(1.0, 1.2, 0.3), "choque": Vector2(18, 6)},
	],
	"mixed_family_farm": [
		{"modelo": "props/FarmCrate_Carrot.gltf", "pos": Vector2(4.6, 3.7), "tam": Vector3(0.7, 0.5, 0.5), "choque": Vector2(12, 9)},
		{"modelo": "props/FarmCrate_Apple.gltf", "pos": Vector2(3.8, -1.0), "tam": Vector3(0.7, 0.5, 0.5), "choque": Vector2(12, 9)},
	],
	"mixed_family_ranch": [
		{"modelo": "props/Bucket_Metal.gltf", "pos": Vector2(4.6, 3.7), "tam": Vector3(0.4, 0.4, 0.4)},
		{"modelo": "props/Bag.gltf", "pos": Vector2(3.8, -1.0), "tam": Vector3(0.5, 0.6, 0.4)},
	],
}

## Marcas que lee la lógica (mapa/marca.gd): el oficio trabaja en el taller y vende en el mostrador de la sala.
const MARCAS: Dictionary = {
	"trabajo": Vector2(4.95, 0.6),
	"trabajo_familiar": Vector2(3.3, 3.4),
	"puesto": Vector2(1.3, 2.9),
	"cama_1": Vector2(-5.45, -3.3),
	"cama_2": Vector2(-5.45, 3.3),
	"mesa": Vector2(0.0, -0.8),
	"cofre": Vector2(-5.45, -1.75),
	"puerta": Vector2(PUERTA_X_M, 4.5),
	"ventana": Vector2(VENTANA_X_M, 4.5),
}
