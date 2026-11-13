extends RefCounted

## Plano de la casa-taller de una familia pobre de dos (2026-11-13, interiores de tamaño real): el leñador y la cantera,
## que trabajan y venden en casa. Nivel 1, pobre: lumbre de leña para cocinar y calentarse, velas, tina de madera, agua
## del pozo en un barril y letrina en el patio; su técnica es una linterna de dinamo, una radio de galena y el tejado
## de chapa ondulada. Más pequeña que la de artesano (de 7,2 × 5,4 m a 11,2 × 8,4 m) y con suelo de tierra.
## Metros respecto al centro de la casa; x hacia el este, z hacia el sur (la puerta de la calle da al sur).
## Lo lee tools/casas/construir_casa.gd (por tools/casas/leer_plano.gd), que rehace la escena del edificio.

const ID := "mixed_family_woodcutter"
const PLANTA_M := Vector2(11.2, 8.4)
const PUERTA_X_M: float = -0.4       ## centro de la puerta de la calle, en el muro sur
const PUERTA_ANCHO_M: float = 1.4
const VENTANA_X_M: float = 3.6       ## la ventana que se abre y se cierra (muro sur, la del taller)
const CARTEL_M := Vector3(-1.85, 2.4, 4.42)

## Texturas: fachada, tabiques, suelo de tablas, suelo de tierra, tejado (no se usa: es de chapa) y zócalo.
const FACHADA := "wall_rock_structure.png"
const TABIQUE := "wall_timber.png"
const MADERA := "floor_wood_planks_damaged.png"
const BALDOSA := "floor_ground_dirt.png"
const TEJADO := ""
const TEJADO_CHAPA: bool = true
const ZOCALO := "wall_stone.png"

## Cuartos: la sala con la lumbre (central) da a la calle y a todos; cada otro cuarto tiene su hueco en un tabique.
const CUARTOS: Array[Dictionary] = [
	{"nombre": "Sala", "centro": Vector2(-0.4, 0.0), "tam": Vector2(4.0, 8.4), "central": true, "suelo": BALDOSA},
	{"nombre": "DormitorioMaestro", "centro": Vector2(-4.0, -2.1), "tam": Vector2(3.2, 4.2), "paso": Vector2(-2.4, -1.2), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	{"nombre": "DormitorioFamiliar", "centro": Vector2(-4.0, 2.1), "tam": Vector2(3.2, 4.2), "paso": Vector2(-2.4, 1.2), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	{"nombre": "Aseo", "centro": Vector2(3.6, -2.8), "tam": Vector2(4.0, 2.8), "paso": Vector2(1.6, -2.4), "ancho": 0.9, "hoja": true, "suelo": BALDOSA},
	{"nombre": "Taller", "centro": Vector2(3.6, 1.4), "tam": Vector2(4.0, 5.6), "paso": Vector2(1.6, 1.0), "ancho": 1.6, "hoja": false, "suelo": BALDOSA},
]

## Tabiques (de punta a punta); los huecos de los cuartos que caen encima se abren solos.
const TABIQUES: Array = [
	[Vector2(-2.4, -4.2), Vector2(-2.4, 4.2)],
	[Vector2(-5.6, 0.0), Vector2(-2.4, 0.0)],
	[Vector2(1.6, -4.2), Vector2(1.6, 4.2)],
	[Vector2(1.6, -1.4), Vector2(5.6, -1.4)],
]

## Ventanas: muro (sur, norte, este, oeste), dónde (x en los muros sur y norte, z en este y oeste) y ancho.
const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.0, "abre": true},
	{"lado": "sur", "en": -4.0, "ancho": 0.8},
	{"lado": "oeste", "en": -2.1, "ancho": 0.8},
	{"lado": "norte", "en": 3.6, "ancho": 0.5},
	{"lado": "norte", "en": 1.0, "ancho": 0.6},
	{"lado": "este", "en": 1.4, "ancho": 1.0},
]

## Muebles: modelo comprado («modelo») o cosa armada a mano («cosa», tools/casas/cosas_casa*.gd). «choque» en píxeles
## del mapa, sin girar (gira con el mueble; 0, 0 = se atraviesa); «giro» en grados; «alto» de la vela, en metros.
const MUEBLES: Array[Dictionary] = [
	# Dormitorio del maestro (el cofre lo pone el juego en su marca): cama, mesilla con vela y la linterna de dinamo
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-4.95, -3.05), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-4.0, -3.85), "tam": Vector3(0.5, 0.6, 0.4)},
	{"cosa": "vela", "pos": Vector2(-4.0, -3.85), "alto": 0.6},
	{"cosa": "linterna", "pos": Vector2(-3.1, -3.85)},
	# Dormitorio del familiar: cama, estante y taburete con vela
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-4.95, 3.05), "giro": 180.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(-3.3, 3.9), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-3.2, 0.6), "tam": Vector3(0.4, 0.5, 0.4)},
	{"cosa": "vela", "pos": Vector2(-3.2, 0.6), "alto": 0.5},
	# Sala: lumbre con leña, mesa con bancos, barril de agua, estante, radio de galena y el mostrador junto a la puerta
	{"cosa": "hogar", "pos": Vector2(-0.4, -3.67), "choque": Vector2(25, 14)},
	{"cosa": "lena", "pos": Vector2(0.75, -3.75)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(0.1, -1.6), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(0.1, -2.35), "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(0.1, -0.85), "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"cosa": "vela", "pos": Vector2(0.1, -1.6), "alto": 0.78},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(-1.95, -3.7), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
	{"modelo": "props/Bucket_Wooden_1.gltf", "pos": Vector2(-1.95, -3.05), "tam": Vector3(0.4, 0.4, 0.4)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(-2.1, 2.6), "giro": 90.0, "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"cosa": "radio_galena", "pos": Vector2(1.25, -3.75), "choque": Vector2(7, 7)},
	{"modelo": "props/Workbench_Drawers.gltf", "pos": Vector2(1.0, 3.55), "tam": Vector3(1.2, 0.9, 0.55), "choque": Vector2(21, 10)},
	# Taller: banco de trabajo, tajo, leña por partir, caja y piedra de afilar
	{"modelo": "props/Workbench.gltf", "pos": Vector2(5.15, 1.2), "giro": 90.0, "tam": Vector3(1.6, 0.9, 0.7), "choque": Vector2(28, 12)},
	{"cosa": "tajo", "pos": Vector2(4.3, 3.0), "choque": Vector2(10, 10)},
	{"cosa": "lena", "pos": Vector2(5.0, 3.75)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(4.6, -0.8), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
	{"modelo": "props/Whetstone.gltf", "pos": Vector2(2.4, -0.85), "tam": Vector3(0.7, 0.8, 0.5), "choque": Vector2(12, 9)},
	# Aseo: tina de madera, palangana y cubo
	{"cosa": "tina", "pos": Vector2(4.6, -2.9), "choque": Vector2(19, 19)},
	{"cosa": "palangana", "pos": Vector2(2.2, -3.75), "choque": Vector2(7, 7)},
	{"modelo": "props/Bucket_Wooden_1.gltf", "pos": Vector2(3.2, -3.85), "tam": Vector3(0.4, 0.4, 0.4)},
	# Patio trasero: la letrina
	{"cosa": "letrina", "pos": Vector2(3.6, -6.0), "choque": Vector2(22, 22), "fuera": true},
]

## Marcas que lee la lógica (mapa/marca.gd): el oficio trabaja en el taller y vende en el mostrador de la sala.
const MARCAS: Dictionary = {
	"trabajo": Vector2(4.4, 1.2),
	"trabajo_familiar": Vector2(2.9, 3.3),
	"puesto": Vector2(1.0, 2.85),
	"cama_1": Vector2(-4.95, -3.05),
	"cama_2": Vector2(-4.95, 3.05),
	"mesa": Vector2(0.1, 0.0),
	"cofre": Vector2(-4.95, -1.55),
	"puerta": Vector2(PUERTA_X_M, 4.2),
	"ventana": Vector2(VENTANA_X_M, 4.2),
}
