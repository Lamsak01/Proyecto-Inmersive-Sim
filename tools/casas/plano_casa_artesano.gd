extends RefCounted

## Plano de la casa de una familia artesana de dos (2026-11-13, interiores de tamaño real): el maestro y su familiar
## (hijo, hija, hermano o hermana), un dormitorio para cada uno. La primera fue la del herrero Thoran y su hijo Kael;
## la usan también el carnicero, el carpintero y el pescadero (con otro `id`, y en espejo para no ser calcadas).
## Nivel 2, artesano: estufa de hierro, bomba de agua en la cocina, una bombilla de la red del pueblo, radio de válvulas,
## bañera de cinc y letrina en el patio. Doble de lado que la casa vieja (de 6,3 × 4,4 m a 12,6 × 9 m).
## Metros respecto al centro de la casa; x hacia el este, z hacia el sur (la puerta de la calle da al sur).
## Lo lee tools/casas/construir_casa.gd (por tools/casas/leer_plano.gd), que rehace la escena del edificio.

const ID := "house_family_smith"
const PLANTA_M := Vector2(12.6, 9.0)
const PUERTA_X_M: float = 0.0        ## centro de la puerta de la calle, en el muro sur
const PUERTA_ANCHO_M: float = 1.6
const VENTANA_X_M: float = 4.15      ## la ventana que se abre y se cierra (muro sur, la de la cocina)
const CARTEL_M := Vector3(1.45, 2.4, 4.72)

## Texturas: fachada, tabiques, suelo de madera, suelo de baldosa, tejado y zócalo.
const FACHADA := "wall_timber_structure_horizontal.png"
const TABIQUE := "wall_timber.png"
const MADERA := "floor_wood_planks.png"
const BALDOSA := "floor_tiles_tan_small.png"
const TEJADO := "roof_clay_red_center.png"
const ZOCALO := "wall_stone.png"

## Cuartos: la sala (central) da a la calle y a todos; cada otro cuarto tiene su hueco («paso») en un tabique.
const CUARTOS: Array[Dictionary] = [
	{"nombre": "Sala", "centro": Vector2(0.0, 0.0), "tam": Vector2(4.0, 9.0), "central": true, "suelo": MADERA},
	{"nombre": "DormitorioMaestro", "centro": Vector2(-4.15, -2.25), "tam": Vector2(4.3, 4.5), "paso": Vector2(-2.0, -1.2), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "DormitorioFamiliar", "centro": Vector2(-4.15, 2.25), "tam": Vector2(4.3, 4.5), "paso": Vector2(-2.0, 1.2), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "Aseo", "centro": Vector2(4.15, -2.75), "tam": Vector2(4.3, 3.5), "paso": Vector2(2.0, -2.0), "ancho": 1.0, "hoja": true, "suelo": BALDOSA},
	{"nombre": "Cocina", "centro": Vector2(4.15, 1.75), "tam": Vector2(4.3, 5.5), "paso": Vector2(2.0, 0.8), "ancho": 1.4, "hoja": false, "suelo": BALDOSA},
]

## Tabiques (de punta a punta); los huecos de los cuartos que caen encima se abren solos.
const TABIQUES: Array = [
	[Vector2(-2.0, -4.5), Vector2(-2.0, 4.5)],
	[Vector2(-6.3, 0.0), Vector2(-2.0, 0.0)],
	[Vector2(2.0, -4.5), Vector2(2.0, 4.5)],
	[Vector2(2.0, -1.0), Vector2(6.3, -1.0)],
]

## Ventanas: muro (sur, norte, este, oeste), dónde (x en los muros sur y norte, z en este y oeste) y ancho.
const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.2, "abre": true},
	{"lado": "sur", "en": -4.15, "ancho": 1.0},
	{"lado": "oeste", "en": -2.25, "ancho": 1.0},
	{"lado": "norte", "en": 4.15, "ancho": 0.6},
	{"lado": "este", "en": 2.0, "ancho": 1.0},
	{"lado": "norte", "en": 0.0, "ancho": 1.0},
]

## Muebles: modelo comprado («modelo») o cosa armada a mano («cosa», tools/casas/cosas_casa.gd). «choque» en píxeles
## del mapa, sin girar (gira con el mueble; 0, 0 = se atraviesa); «giro» en grados.
const MUEBLES: Array[Dictionary] = [
	# Dormitorio del maestro
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-5.45, -3.3), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-4.6, -4.15), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-2.9, -4.1), "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"cosa": "alfombra", "pos": Vector2(-4.3, -1.6), "tam2": Vector2(1.6, 1.0), "color": Color(0.45, 0.2, 0.15)},
	# Dormitorio del familiar
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-5.45, 3.3), "giro": 180.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Chest_Wood.gltf", "pos": Vector2(-5.45, 1.75), "tam": Vector3(0.8, 0.5, 0.45), "choque": Vector2(14, 8)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(-3.4, 0.3), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-3.0, 3.9), "tam": Vector3(0.4, 0.5, 0.4)},
	# Sala: mesa de comer, radio de válvulas, bombilla, banco y librería
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(0.0, -2.2), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-0.45, -2.95), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(0.45, -2.95), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-0.45, -1.45), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "radio", "pos": Vector2(-1.5, -4.05), "choque": Vector2(11, 8)},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(1.45, -4.1), "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(1.6, 3.0), "giro": 90.0, "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"cosa": "alfombra", "pos": Vector2(0.0, 1.8), "tam2": Vector2(2.2, 1.6), "color": Color(0.3, 0.32, 0.18)},
	{"cosa": "bombilla", "pos": Vector2(0.0, -2.2)},
	# Cocina: estufa de hierro, pila con bomba, encimera, mesa y despensa
	{"cosa": "estufa", "pos": Vector2(5.8, 0.2), "giro": 90.0, "choque": Vector2(14, 11)},
	{"cosa": "pila_con_bomba", "pos": Vector2(4.1, -0.65), "choque": Vector2(18, 10)},
	{"modelo": "props/Workbench_Drawers.gltf", "pos": Vector2(5.9, 2.4), "giro": 90.0, "tam": Vector3(1.6, 0.9, 0.6), "choque": Vector2(28, 11)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(3.9, 2.6), "tam": Vector3(1.2, 0.78, 0.8), "choque": Vector2(21, 14)},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(5.8, 4.0), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(2.3, 3.4), "giro": 90.0, "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"cosa": "bombilla", "pos": Vector2(4.0, 1.6)},
	# Aseo: bañera de cinc, palangana, cubo
	{"cosa": "banera", "pos": Vector2(5.35, -3.65), "choque": Vector2(27, 12)},
	{"cosa": "palangana", "pos": Vector2(2.6, -4.05), "choque": Vector2(7, 7)},
	{"modelo": "props/Bucket_Wooden_1.gltf", "pos": Vector2(4.0, -4.1), "tam": Vector3(0.4, 0.4, 0.4)},
	# Patio trasero: la letrina
	{"cosa": "letrina", "pos": Vector2(4.6, -6.6), "choque": Vector2(22, 22), "fuera": true},
]

## Marcas que lee la lógica (mapa/marca.gd).
const MARCAS: Dictionary = {
	"cama_1": Vector2(-5.45, -3.3),
	"cama_2": Vector2(-5.45, 3.3),
	"mesa": Vector2(0.0, -1.0),
	"cofre": Vector2(-5.45, -1.75),
	"puerta": Vector2(PUERTA_X_M, 4.5),
	"ventana": Vector2(VENTANA_X_M, 4.5),
}
