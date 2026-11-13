extends RefCounted

## Plano de la tienda de un artesano que vive en otra casa (2026-11-13, interiores de tamaño real): herrería,
## carnicería, carpintería y pescadería. Nivel 2, artesano: bombillas de la red del pueblo. Delante, la tienda con el
## mostrador (se vende en «puesto»; el mercader espera en «cliente»); detrás, la trastienda con el sitio del maestro
## («trabajo»); al fondo, el taller del oficio («trabajo_familiar») y el almacén con el cofre. Lo propio de cada oficio,
## en POR_OFICIO. De 6,5 × 4,3 m a 9,8 × 6,4 m; el muro de la puerta no se mueve. Metros respecto al centro; x hacia
## el este, z hacia el sur (puerta al sur; carpintería y pescadería se construyen con «girar», puerta al norte).
## Lo lee tools/casas/construir_casa.gd (con el id de cada tienda).

const ID := "shop_family_smith"
const PLANTA_M := Vector2(9.8, 6.4)
const PUERTA_X_M: float = 0.0
const PUERTA_ANCHO_M: float = 1.4
const VENTANA_X_M: float = 3.0       ## la ventana que se abre y se cierra (la de la tienda, en el muro de la puerta)
const CARTEL_M := Vector3(1.4, 2.4, 3.42)

const FACHADA := "wall_timber_structure_horizontal.png"
const TABIQUE := "wall_timber.png"
const MADERA := "floor_wood_planks.png"
const BALDOSA := "floor_stone_pattern_small.png"   ## el taller, de piedra (fuego, sangre, agua o virutas)
const TEJADO := "roof_clay_red_center.png"
const ZOCALO := "wall_stone.png"

const MOSTRADOR_TAM := Vector3(1.2, 0.9, 0.55)
const MOSTRADOR_CHOQUE := Vector2(21, 10)
const HUECO_HONDO_M: float = 0.9   ## el hueco se cruza en recto hasta pasar el fondo del mostrador
const ESTANTE_TAM := Vector3(1.0, 1.5, 0.35)
const ESTANTE_CHOQUE := Vector2(18, 6)

const CUARTOS: Array[Dictionary] = [
	# delante del mostrador, donde se compra: da a la calle y, por el hueco entre los dos tramos del mostrador, a la
	# trastienda (la franja del mostrador queda entre las dos y se cruza en recto); así quien va detrás pasa por el
	# hueco y no a través del mueble
	{"nombre": "Tienda", "centro": Vector2(0.0, 2.1875), "tam": Vector2(9.8, 2.025), "paso": Vector2(-1.4, 1.175), "margen": HUECO_HONDO_M, "suelo": MADERA},
	{"nombre": "FranjaMostrador", "centro": Vector2(0.0, 0.9), "tam": Vector2(9.8, 0.55), "solo_suelo": true, "suelo": MADERA},
	{"nombre": "Trastienda", "centro": Vector2(0.0, 0.0125), "tam": Vector2(9.8, 1.225), "central": true, "suelo": MADERA},
	{"nombre": "Taller", "centro": Vector2(-1.5, -1.9), "tam": Vector2(6.8, 2.6), "paso": Vector2(1.0, -0.6), "ancho": 1.0, "hoja": true, "suelo": BALDOSA},
	{"nombre": "Almacen", "centro": Vector2(3.4, -1.9), "tam": Vector2(3.0, 2.6), "paso": Vector2(3.4, -0.6), "ancho": 0.9, "hoja": true, "suelo": MADERA},
]

const TABIQUES: Array = [
	[Vector2(-4.9, -0.6), Vector2(4.9, -0.6)],
	[Vector2(1.9, -3.2), Vector2(1.9, -0.6)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.2, "abre": true},
	{"lado": "sur", "en": -3.0, "ancho": 1.2},
	{"lado": "oeste", "en": -1.9, "ancho": 0.8},
	{"lado": "este", "en": 1.6, "ancho": 0.8},
	{"lado": "norte", "en": -1.5, "ancho": 0.8},
]

const MUEBLES: Array[Dictionary] = [
	# Tienda: el mostrador (dos tramos con un hueco en medio para pasar), la banqueta del maestro, estantes y bombilla
	{"modelo": "props/Workbench_Drawers.gltf", "pos": Vector2(-2.6, 0.9), "giro": 180.0, "tam": MOSTRADOR_TAM, "choque": MOSTRADOR_CHOQUE},
	{"modelo": "props/Workbench_Drawers.gltf", "pos": Vector2(-0.2, 0.9), "giro": 180.0, "tam": MOSTRADOR_TAM, "choque": MOSTRADOR_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-3.0, 0.15), "tam": Vector3(0.35, 0.45, 0.35)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(-2.6, -0.42), "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(-4.72, 1.5), "giro": 90.0, "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"cosa": "bombilla", "pos": Vector2(0.0, 1.5)},
	# Almacén: estantes, cajas y bombilla (el cofre lo pone el juego en su marca)
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(4.72, -1.9), "giro": -90.0, "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(2.5, -2.7), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
	{"cosa": "bombilla", "pos": Vector2(3.4, -1.9)},
	{"cosa": "bombilla", "pos": Vector2(-1.5, -1.9)},
]

## Lo de cada oficio: en el taller, contra el muro del fondo (el familiar trabaja delante, en «trabajo_familiar»);
## en la tienda, contra el muro este, lo que se enseña.
const POR_OFICIO: Dictionary = {
	"shop_family_smith": [
		{"cosa": "hogar", "pos": Vector2(-4.1, -2.75), "choque": Vector2(25, 14)},
		{"modelo": "props/Anvil.gltf", "pos": Vector2(-2.5, -2.6), "tam": Vector3(0.7, 0.6, 0.35), "choque": Vector2(12, 7)},
		{"modelo": "props/Whetstone.gltf", "pos": Vector2(-0.9, -2.8), "tam": Vector3(0.6, 0.7, 0.4), "choque": Vector2(11, 7)},
		{"modelo": "props/Barrel.gltf", "pos": Vector2(1.3, -2.75), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
		{"modelo": "props/WeaponStand.gltf", "pos": Vector2(4.55, 1.9), "giro": -90.0, "tam": Vector3(1.0, 1.6, 0.5), "choque": Vector2(18, 9)},
	],
	"shop_family_butcher": [
		{"modelo": "props/Workbench.gltf", "pos": Vector2(-4.0, -2.75), "tam": Vector3(1.6, 0.9, 0.7), "choque": Vector2(28, 12)},
		{"cosa": "tajo", "pos": Vector2(-2.5, -2.6), "choque": Vector2(10, 10)},
		{"modelo": "props/Bucket_Metal.gltf", "pos": Vector2(-0.9, -2.8), "tam": Vector3(0.4, 0.4, 0.4)},
		{"modelo": "props/Barrel.gltf", "pos": Vector2(1.3, -2.75), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
		{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(4.72, 1.5), "giro": -90.0, "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	],
	"shop_family_carpenter": [
		{"cosa": "lena", "pos": Vector2(-4.3, -2.75)},
		{"modelo": "props/Workbench.gltf", "pos": Vector2(-2.5, -2.75), "tam": Vector3(1.6, 0.9, 0.7), "choque": Vector2(28, 12)},
		{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(1.3, -2.7), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
		{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(4.3, 2.6), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
		{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(4.72, 1.2), "giro": -90.0, "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	],
	"shop_family_fishmonger": [
		{"modelo": "props/Barrel.gltf", "pos": Vector2(-4.3, -2.75), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
		{"cosa": "tina", "pos": Vector2(-2.5, -2.55), "choque": Vector2(19, 19)},
		{"modelo": "props/Bucket_Wooden_1.gltf", "pos": Vector2(-0.9, -2.8), "tam": Vector3(0.4, 0.4, 0.4)},
		{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(1.3, -2.7), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
		{"modelo": "props/Barrel.gltf", "pos": Vector2(4.4, 2.6), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
		{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(4.72, 1.2), "giro": -90.0, "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	],
}

const MARCAS: Dictionary = {
	"puesto": Vector2(-2.6, 0.9),
	"cliente": Vector2(-2.6, 1.75),
	"trabajo": Vector2(-2.6, 0.15),
	"trabajo_familiar": Vector2(-2.5, -1.4),
	"cofre": Vector2(4.2, -2.75),
	"expositor": Vector2(3.9, 1.9),
	"puerta": Vector2(PUERTA_X_M, 3.2),
	"ventana": Vector2(VENTANA_X_M, 3.2),
}
