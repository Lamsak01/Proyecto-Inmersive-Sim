extends RefCounted

## Plano de la Capilla del Alba (2026-11-13, interiores de tamaño real). Sin luz eléctrica: velas y candelabros. La
## nave de punta a punta con el altar al fondo, el atril y seis filas de bancos a cada lado del pasillo central (cada
## fiel se sienta junto al pasillo, en su marca «banco_N»); el atrio, junto a la puerta, da a los dos cuartos de los
## lados (y, por un arco, a la nave): la sacristía y la casa del sacerdote (su cama, la del niño expósito si lo hay, y su mesa). Piedra y teja roja.
## De 7,4 × 5,2 m a 14 × 9,8 m. Metros respecto al centro; x hacia el este, z hacia el sur (puerta al sur): se construye
## con «girar» y la puerta queda al norte, como siempre estuvo. Lo lee tools/casas/construir_casa.gd.

const ID := "building_church"
const PLANTA_M := Vector2(14.0, 9.8)
const PUERTA_X_M: float = 0.0        ## la puerta, en medio del muro (da al atrio)
const PUERTA_ANCHO_M: float = 1.8
const VENTANA_X_M: float = -5.0      ## la ventana que se abre y se cierra (la de la sacristía, en el muro de la puerta)
const CARTEL_M := Vector3(1.8, 2.4, 5.12)

const FACHADA := "wall_brick_stone_center.png"
const TABIQUE := "wall_stone.png"
const MADERA := "floor_wood_planks_wide.png"
const LOSA := "floor_stone_pattern.png"   ## la nave
const TEJADO := "roof_clay_red_center.png"
const ZOCALO := "wall_stone.png"

const ALTAR_ALTO_M: float = 0.87     ## encima del altar van los candelabros
const MESA_ALTO_M: float = 0.78
const GRANATE := Color(0.42, 0.1, 0.12)
const ARCO_ANCHO_M: float = 2.0     ## el arco entre el atrio y la nave: todo el pasillo central
const BANCO_TAM := Vector3(1.4, 0.72, 0.4)   ## cada banco va de 1 a 2,4 m del eje: el pasillo central queda libre
const BANCO_CHOQUE := Vector2(25, 7)

const CUARTOS: Array[Dictionary] = [
	# el atrio reparte: a la nave se entra por el arco del pasillo central, así nadie cruza los bancos en diagonal
	{"nombre": "Atrio", "centro": Vector2(0.0, 4.25), "tam": Vector2(6.0, 1.3), "central": true, "suelo": LOSA},
	{"nombre": "Nave", "centro": Vector2(0.0, -0.65), "tam": Vector2(6.0, 8.5), "paso": Vector2(0.0, 3.6), "ancho": ARCO_ANCHO_M, "suelo": LOSA},
	{"nombre": "Sacristia", "centro": Vector2(-5.0, 0.0), "tam": Vector2(4.0, 9.8), "paso": Vector2(-3.0, 4.25), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "CasaSacerdote", "centro": Vector2(5.0, 0.0), "tam": Vector2(4.0, 9.8), "paso": Vector2(3.0, 4.25), "ancho": 1.0, "hoja": true, "suelo": MADERA},
]

const TABIQUES: Array = [
	[Vector2(-3.0, -4.9), Vector2(-3.0, 4.9)],
	[Vector2(3.0, -4.9), Vector2(3.0, 4.9)],
	[Vector2(-3.0, 3.6), Vector2(3.0, 3.6)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.0, "abre": true},
	{"lado": "sur", "en": 5.0, "ancho": 1.0},
	{"lado": "norte", "en": -1.6, "ancho": 0.6},
	{"lado": "norte", "en": 1.6, "ancho": 0.6},
	{"lado": "norte", "en": -5.0, "ancho": 0.8},
	{"lado": "norte", "en": 5.0, "ancho": 0.8},
	{"lado": "oeste", "en": -2.5, "ancho": 0.8},
	{"lado": "oeste", "en": 1.5, "ancho": 0.8},
	{"lado": "este", "en": -2.5, "ancho": 0.8},
	{"lado": "este", "en": 1.5, "ancho": 0.8},
]

const MUEBLES: Array[Dictionary] = [
	# Nave: seis filas de bancos a cada lado del pasillo, el altar de piedra con dos candelabros, el atril, la alfombra
	# del pasillo y candelabros en las esquinas
	{"modelo": "props/Bench.gltf", "pos": Vector2(-1.7, -2.0), "tam": BANCO_TAM, "choque": BANCO_CHOQUE},
	{"modelo": "props/Bench.gltf", "pos": Vector2(1.7, -2.0), "tam": BANCO_TAM, "choque": BANCO_CHOQUE},
	{"modelo": "props/Bench.gltf", "pos": Vector2(-1.7, -1.0), "tam": BANCO_TAM, "choque": BANCO_CHOQUE},
	{"modelo": "props/Bench.gltf", "pos": Vector2(1.7, -1.0), "tam": BANCO_TAM, "choque": BANCO_CHOQUE},
	{"modelo": "props/Bench.gltf", "pos": Vector2(-1.7, 0.0), "tam": BANCO_TAM, "choque": BANCO_CHOQUE},
	{"modelo": "props/Bench.gltf", "pos": Vector2(1.7, 0.0), "tam": BANCO_TAM, "choque": BANCO_CHOQUE},
	{"modelo": "props/Bench.gltf", "pos": Vector2(-1.7, 1.0), "tam": BANCO_TAM, "choque": BANCO_CHOQUE},
	{"modelo": "props/Bench.gltf", "pos": Vector2(1.7, 1.0), "tam": BANCO_TAM, "choque": BANCO_CHOQUE},
	{"modelo": "props/Bench.gltf", "pos": Vector2(-1.7, 2.0), "tam": BANCO_TAM, "choque": BANCO_CHOQUE},
	{"modelo": "props/Bench.gltf", "pos": Vector2(1.7, 2.0), "tam": BANCO_TAM, "choque": BANCO_CHOQUE},
	{"modelo": "props/Bench.gltf", "pos": Vector2(-1.7, 3.0), "tam": BANCO_TAM, "choque": BANCO_CHOQUE},
	{"modelo": "props/Bench.gltf", "pos": Vector2(1.7, 3.0), "tam": BANCO_TAM, "choque": BANCO_CHOQUE},
	{"modelo": "graveyard/altar-stone.glb", "pos": Vector2(0.0, -3.9), "tam": Vector3(1.57, ALTAR_ALTO_M, 0.53), "choque": Vector2(28, 10)},
	{"cosa": "candelabro", "pos": Vector2(-0.55, -3.9), "alto": ALTAR_ALTO_M},
	{"cosa": "candelabro", "pos": Vector2(0.55, -3.9), "alto": ALTAR_ALTO_M},
	{"modelo": "props/BookStand.gltf", "pos": Vector2(1.5, -3.3), "giro": 200.0, "tam": Vector3(0.42, 1.16, 0.42), "choque": Vector2(8, 8)},
	{"cosa": "alfombra", "pos": Vector2(0.0, 0.0), "tam2": Vector2(1.2, 6.8), "color": GRANATE},
	{"cosa": "candelabro", "pos": Vector2(-2.7, -4.6)},
	{"cosa": "candelabro", "pos": Vector2(2.7, -4.6)},
	# Sacristía: armario de las vestiduras, librería, mesa con candelabro y arcón
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-6.55, -3.0), "giro": 90.0, "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-6.65, -0.8), "giro": 90.0, "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-5.0, -2.0), "giro": 90.0, "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"cosa": "candelabro", "pos": Vector2(-5.0, -2.0), "alto": MESA_ALTO_M},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(-6.4, 1.6), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
	# Casa del sacerdote: su cama, la cuna del expósito, mesilla, mesa con silla y estante
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(5.9, -3.6), "giro": 90.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(6.1, -1.3), "giro": 90.0, "tam": Vector3(0.7, 0.6, 1.4)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(6.65, -2.45), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(5.6, 1.6), "giro": 90.0, "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(6.35, 1.6), "giro": -90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "vela", "pos": Vector2(5.6, 1.2), "alto": MESA_ALTO_M},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(6.65, 3.6), "giro": -90.0, "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
]

const MARCAS: Dictionary = {
	"altar": Vector2(0.0, -3.9),
	"cama_1": Vector2(5.9, -3.6),
	"cama_2": Vector2(6.1, -1.3),
	"mesa": Vector2(4.8, 1.6),
	"banco_1": Vector2(-0.7, -2.0),
	"banco_2": Vector2(0.7, -2.0),
	"banco_3": Vector2(-0.7, -1.0),
	"banco_4": Vector2(0.7, -1.0),
	"banco_5": Vector2(-0.7, 0.0),
	"banco_6": Vector2(0.7, 0.0),
	"banco_7": Vector2(-0.7, 1.0),
	"banco_8": Vector2(0.7, 1.0),
	"banco_9": Vector2(-0.7, 2.0),
	"banco_10": Vector2(0.7, 2.0),
	"banco_11": Vector2(-0.7, 3.0),
	"banco_12": Vector2(0.7, 3.0),
	"puerta": Vector2(PUERTA_X_M, 4.9),
	"ventana": Vector2(VENTANA_X_M, 4.9),
}
