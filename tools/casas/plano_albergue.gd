extends RefCounted

## Plano del Albergue del Alba (2026-11-13, interiores de tamaño real): el refugio de la capilla donde duermen los que
## se quedan sin dinero (4 camas, scripts/systems/VillageCivic.gd) y se reparten las gachas. Nivel 1, pobre: comedor
## con la lumbre y el caldero, dos dormitorios de dos camas (hombres y mujeres), aseo con tina, despensa de sacos y
## letrina en el patio; velas, linterna de dinamo, radio de galena y tejado de chapa. De 6,3 × 4,4 m a 11,2 × 8,4 m.
## Se dibuja con la puerta al sur; el albergue da al norte: se construye con «girar» (media vuelta).
## Metros respecto al centro; x hacia el este, z hacia el sur.
## Lo lee tools/casas/construir_casa.gd (por tools/casas/leer_plano.gd), que rehace la escena del edificio.

const ID := "building_shelter"
const PLANTA_M := Vector2(11.2, 8.4)
const PUERTA_X_M: float = -0.4       ## centro de la puerta de la calle, en el muro sur
const PUERTA_ANCHO_M: float = 1.4
const VENTANA_X_M: float = 3.6       ## la ventana que se abre y se cierra (muro sur, la de la despensa)
const CARTEL_M := Vector3(1.25, 2.4, 4.42)

## Texturas: fachada, tabiques, suelo de tablas, suelo de tierra, tejado (no se usa: es de chapa) y zócalo.
const FACHADA := "wall_rock_structure.png"
const TABIQUE := "wall_timber.png"
const MADERA := "floor_wood_planks_damaged.png"
const BALDOSA := "floor_ground_dirt.png"
const TEJADO := ""
const TEJADO_CHAPA: bool = true
const ZOCALO := "wall_stone.png"

## Cuartos: el comedor (central) da a la calle y a todos; cada otro cuarto tiene su hueco en un tabique.
const CUARTOS: Array[Dictionary] = [
	{"nombre": "Comedor", "centro": Vector2(-0.4, 0.0), "tam": Vector2(4.0, 8.4), "central": true, "suelo": BALDOSA},
	{"nombre": "DormitorioHombres", "centro": Vector2(-4.0, -2.1), "tam": Vector2(3.2, 4.2), "paso": Vector2(-2.4, -1.0), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	{"nombre": "DormitorioMujeres", "centro": Vector2(-4.0, 2.1), "tam": Vector2(3.2, 4.2), "paso": Vector2(-2.4, 1.0), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	{"nombre": "Aseo", "centro": Vector2(3.6, -2.8), "tam": Vector2(4.0, 2.8), "paso": Vector2(1.6, -2.4), "ancho": 0.9, "hoja": true, "suelo": BALDOSA},
	{"nombre": "Despensa", "centro": Vector2(3.6, 1.4), "tam": Vector2(4.0, 5.6), "paso": Vector2(1.6, 1.0), "ancho": 1.0, "hoja": true, "suelo": BALDOSA},
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
	{"lado": "norte", "en": -4.0, "ancho": 0.8},
	{"lado": "norte", "en": 3.6, "ancho": 0.5},
	{"lado": "oeste", "en": -2.1, "ancho": 0.8},
	{"lado": "oeste", "en": 2.1, "ancho": 0.8},
	{"lado": "este", "en": 1.4, "ancho": 0.8},
]

## Muebles: modelo comprado («modelo») o cosa armada a mano («cosa», tools/casas/cosas_*.gd). «choque» en píxeles
## del mapa, sin girar (gira con el mueble; 0, 0 = se atraviesa); «giro» en grados; «alto» de la vela, en metros.
const MUEBLES: Array[Dictionary] = [
	# Dormitorio de hombres: dos camas con su mesilla, vela y la linterna de dinamo del celador
	{"modelo": "props/Bed_Twin2.gltf", "pos": Vector2(-5.1, -3.0), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Bed_Twin2.gltf", "pos": Vector2(-3.4, -3.0), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-4.25, -3.85), "tam": Vector3(0.5, 0.6, 0.4)},
	{"cosa": "vela", "pos": Vector2(-4.25, -3.85), "alto": 0.6},
	{"cosa": "linterna", "pos": Vector2(-2.85, -3.95)},
	# Dormitorio de mujeres: dos camas, mesilla con vela y un arcón para lo poco que traen
	{"modelo": "props/Bed_Twin2.gltf", "pos": Vector2(-5.1, 3.0), "giro": 180.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Bed_Twin2.gltf", "pos": Vector2(-3.4, 3.0), "giro": 180.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-4.25, 3.85), "tam": Vector3(0.5, 0.6, 0.4)},
	{"cosa": "vela", "pos": Vector2(-4.25, 3.85), "alto": 0.6},
	{"modelo": "props/Chest_Wood.gltf", "pos": Vector2(-5.1, 1.4), "giro": 90.0, "tam": Vector3(0.8, 0.5, 0.45), "choque": Vector2(8, 14)},
	# Comedor: la lumbre con el caldero de las gachas, la mesa larga con bancos (el paso de la puerta
	# a los cuartos queda libre) y la radio de galena
	{"cosa": "hogar", "pos": Vector2(-0.4, -3.67), "choque": Vector2(25, 14)},
	{"modelo": "props/Cauldron.gltf", "pos": Vector2(0.85, -3.6), "tam": Vector3(0.7, 0.6, 0.7), "choque": Vector2(12, 12)},
	{"cosa": "lena", "pos": Vector2(-1.75, -3.75)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-0.4, -1.4), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(-0.4, -2.15), "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(-0.4, -0.65), "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"cosa": "vela", "pos": Vector2(-0.4, -1.4), "alto": 0.78},
	{"cosa": "radio_galena", "pos": Vector2(-1.95, 3.85), "choque": Vector2(7, 7)},
	{"modelo": "props/Bucket_Wooden_1.gltf", "pos": Vector2(1.2, 3.85), "tam": Vector3(0.4, 0.4, 0.4)},
	# Despensa: sacos de grano para las gachas, barriles, cajas y un estante
	{"modelo": "props/Bag.gltf", "pos": Vector2(5.1, -0.8), "tam": Vector3(0.6, 0.7, 0.5), "choque": Vector2(10, 9)},
	{"modelo": "props/Bag.gltf", "pos": Vector2(5.1, 0.0), "tam": Vector3(0.6, 0.7, 0.5), "choque": Vector2(10, 9)},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(5.1, 1.2), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
	{"modelo": "props/Barrel_Apples.gltf", "pos": Vector2(5.1, 2.0), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
	{"modelo": "props/FarmCrate_Carrot.gltf", "pos": Vector2(4.9, 3.7), "tam": Vector3(0.7, 0.5, 0.5), "choque": Vector2(12, 9)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(3.9, 3.7), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(3.4, -1.15), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	# Aseo: tina de madera, palangana y cubo
	{"cosa": "tina", "pos": Vector2(4.6, -2.9), "choque": Vector2(19, 19)},
	{"cosa": "palangana", "pos": Vector2(2.2, -3.75), "choque": Vector2(7, 7)},
	{"modelo": "props/Bucket_Wooden_1.gltf", "pos": Vector2(3.2, -3.85), "tam": Vector3(0.4, 0.4, 0.4)},
	# Patio trasero: la letrina
	{"cosa": "letrina", "pos": Vector2(3.6, -6.0), "choque": Vector2(22, 22), "fuera": true},
]

## Marcas que lee la lógica (mapa/marca.gd): las cuatro camas que reparte el albergue.
const MARCAS: Dictionary = {
	"cama_1": Vector2(-5.1, -3.0),
	"cama_2": Vector2(-3.4, -3.0),
	"cama_3": Vector2(-5.1, 3.0),
	"cama_4": Vector2(-3.4, 3.0),
	"puerta": Vector2(PUERTA_X_M, 4.2),
	"ventana": Vector2(VENTANA_X_M, 4.2),
}
