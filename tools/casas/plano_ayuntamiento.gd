extends RefCounted

## Plano del Ayuntamiento (2026-11-13, interiores de tamaño real). Nivel 4 (autoridades): luz eléctrica de la red
## oficial con su cuadro junto a la puerta, teléfono de baquelita y lámparas de techo. Una planta: el vestíbulo de
## punta a punta con la urna de las elecciones, bancos para esperar y el mostrador del fondo (con el Libro Mayor de los
## Gremios); a un lado, el despacho del alcalde (con su terminal, que pone el juego) y el archivo; al otro, la tesorería
## de las arcas y la sala de juntas. Piedra y teja roja. De 7,2 × 5,4 m a 14 × 9,8 m.
## Metros respecto al centro; x hacia el este, z hacia el sur (puerta al sur).
## Lo lee tools/casas/construir_casa.gd (por tools/casas/leer_plano.gd).

const ID := "building_town_hall"
const PLANTA_M := Vector2(14.0, 9.8)
const PUERTA_X_M: float = 0.0        ## la puerta grande, en medio del muro sur (da al vestíbulo)
const PUERTA_ANCHO_M: float = 2.0
const VENTANA_X_M: float = -4.8      ## la ventana que se abre y se cierra (muro sur, la del archivo)
const CARTEL_M := Vector3(1.8, 2.4, 5.12)

const FACHADA := "wall_brick_stone_center.png"
const TABIQUE := "wall_brick_small_sand.png"
const MADERA := "floor_wood_planks_wide.png"
const BALDOSA := "floor_tiles_tan_large.png"
const LOSA := "floor_stone_pattern.png"   ## el suelo del vestíbulo
const TEJADO := "roof_clay_red_center.png"
const ZOCALO := "wall_stone.png"

const MESA_ALTO_M: float = 0.78
const CABLE_ALTO_M: float = 2.9      ## la acometida de la red, por encima de la puerta
const GRANATE := Color(0.42, 0.1, 0.12)
const AZUL_NOBLE := Color(0.16, 0.2, 0.36)

const CUARTOS: Array[Dictionary] = [
	{"nombre": "Vestibulo", "centro": Vector2(0.0, 0.0), "tam": Vector2(5.2, 9.8), "central": true, "suelo": LOSA},
	{"nombre": "DespachoAlcalde", "centro": Vector2(-4.8, -2.45), "tam": Vector2(4.4, 4.9), "paso": Vector2(-2.6, -1.2), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "Archivo", "centro": Vector2(-4.8, 2.45), "tam": Vector2(4.4, 4.9), "paso": Vector2(-2.6, 1.6), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	{"nombre": "Tesoreria", "centro": Vector2(4.8, -2.45), "tam": Vector2(4.4, 4.9), "paso": Vector2(2.6, -1.2), "ancho": 0.9, "hoja": true, "suelo": BALDOSA},
	{"nombre": "SalaJuntas", "centro": Vector2(4.8, 2.45), "tam": Vector2(4.4, 4.9), "paso": Vector2(2.6, 1.6), "ancho": 1.0, "hoja": true, "suelo": MADERA},
]

const TABIQUES: Array = [
	[Vector2(-2.6, -4.9), Vector2(-2.6, 4.9)],
	[Vector2(2.6, -4.9), Vector2(2.6, 4.9)],
	[Vector2(-7.0, 0.0), Vector2(-2.6, 0.0)],
	[Vector2(2.6, 0.0), Vector2(7.0, 0.0)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.2, "abre": true},
	{"lado": "sur", "en": 4.8, "ancho": 1.2},
	{"lado": "norte", "en": -4.8, "ancho": 1.2},
	{"lado": "norte", "en": 4.8, "ancho": 0.8},
	{"lado": "oeste", "en": -2.45, "ancho": 1.0},
	{"lado": "oeste", "en": 2.45, "ancho": 1.0},
	{"lado": "este", "en": -2.45, "ancho": 0.6},
	{"lado": "este", "en": 2.45, "ancho": 1.0},
]

const MUEBLES: Array[Dictionary] = [
	# Vestíbulo: mostrador al fondo con el Libro Mayor, bancos para esperar, retrato del Señor y lámparas (la urna la pone
	# el juego en su marca)
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(0.0, -3.6), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.6, -3.6), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(0.4, -4.4), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-1.6, -4.65), "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"cosa": "candelabro", "pos": Vector2(1.9, -3.6), "alto": MESA_ALTO_M},
	{"cosa": "retrato", "pos": Vector2(1.0, -4.85)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(-2.15, 3.6), "giro": 90.0, "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(2.15, 3.6), "giro": 90.0, "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"cosa": "alfombra", "pos": Vector2(0.0, 1.4), "tam2": Vector2(2.0, 5.0), "color": GRANATE},
	{"cosa": "lampara", "pos": Vector2(0.0, -2.2)},
	{"cosa": "lampara", "pos": Vector2(0.0, 2.2)},
	# Despacho del alcalde: escritorio con teléfono, su silla y la del que viene a verle, librería y armario
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-5.0, -2.6), "giro": 90.0, "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-5.75, -2.6), "giro": 90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-4.25, -2.6), "giro": -90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "telefono", "pos": Vector2(-5.0, -3.1), "alto": MESA_ALTO_M},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-4.8, -4.65), "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-3.4, -4.6), "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"cosa": "alfombra", "pos": Vector2(-5.0, -2.6), "tam2": Vector2(2.4, 2.4), "color": AZUL_NOBLE},
	{"cosa": "bombilla", "pos": Vector2(-4.8, -2.45)},
	# Archivo: estanterías y armarios de legajos, mesa de consulta
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-6.55, 1.6), "giro": 90.0, "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-6.55, 3.2), "giro": 90.0, "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-4.8, 0.32), "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(-3.4, 4.65), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-4.6, 2.6), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-4.6, 3.35), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "bombilla", "pos": Vector2(-4.8, 2.45)},
	# Tesorería: armarios y cajas de caudales (las arcas del pueblo las pone el juego en su marca), mesa del tesorero
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(6.55, -2.6), "giro": -90.0, "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(6.4, -1.0), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(4.4, -2.6), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(4.4, -3.35), "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "candelabro", "pos": Vector2(4.0, -2.6), "alto": MESA_ALTO_M},
	{"cosa": "bombilla", "pos": Vector2(4.8, -2.45)},
	# Sala de juntas: mesa con seis sillas (una en cada cabecera), retrato y lámpara; libre el paso de la puerta
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(5.0, 2.6), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(4.6, 1.8), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(5.4, 1.8), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(4.6, 3.4), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(5.4, 3.4), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(3.85, 2.6), "giro": -90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(6.15, 2.6), "giro": 90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "retrato", "pos": Vector2(6.95, 2.6), "giro": -90.0},
	{"cosa": "lampara", "pos": Vector2(5.0, 2.6)},
	# Fuera: el cuadro junto a la puerta y la acometida de la red oficial, que sube por la fachada hasta el alero
	{"cosa": "cuadro_electrico", "pos": Vector2(-1.6, 5.1), "fuera": true},
	{"cosa": "cable", "pos": Vector2(-1.6, 5.08), "medida": Vector3(0.04, 1.6, 0.04), "alto": 1.5, "fuera": true},
	{"cosa": "cable", "pos": Vector2(-4.3, 5.08), "medida": Vector3(5.4, 0.04, 0.04), "alto": CABLE_ALTO_M, "fuera": true},
]

const MARCAS: Dictionary = {
	"mesa": Vector2(0.0, -2.6),
	"libro_gremial": Vector2(0.8, -3.6),
	"urna": Vector2(-1.2, 0.4),
	"alcalde": Vector2(-3.6, -1.6),
	"terminal": Vector2(-6.5, -0.7),
	"cofre": Vector2(6.3, -4.2),
	"puerta": Vector2(PUERTA_X_M, 4.9),
	"ventana": Vector2(VENTANA_X_M, 4.9),
}
