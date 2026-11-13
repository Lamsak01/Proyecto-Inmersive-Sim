extends RefCounted

## Plano de la Escuela del Valle (2026-11-13, interiores de tamaño real). Edificio público modesto: ladrillo arenisca,
## teja gris, dos bombillas y una estufa. El aula de punta a punta: seis filas de pupitres a cada lado del pasillo
## central (cada niño se sienta junto al pasillo, en su marca «pupitre_N»), la pizarra y la mesa del maestro al fondo;
## detrás de la pizarra, el despacho del maestro con sus libros. De 7,2 × 5,4 m a 11,2 × 9,8 m. Metros respecto al
## centro; x hacia el este, z hacia el sur (puerta al sur, como siempre). Lo lee tools/casas/construir_casa.gd.

const ID := "building_school"
const PLANTA_M := Vector2(11.2, 9.8)
const PUERTA_X_M: float = 0.0        ## la puerta, en el eje del pasillo de los pupitres
const PUERTA_ANCHO_M: float = 1.4
const VENTANA_X_M: float = -3.6      ## la ventana que se abre y se cierra (en el muro de la puerta)
const CARTEL_M := Vector3(1.4, 2.4, 5.12)

const FACHADA := "wall_brick_sand_center.png"
const TABIQUE := "wall_brick_small_sand.png"
const MADERA := "floor_wood_planks.png"
const TEJADO := "roof_clay_grey_center.png"
const ZOCALO := "wall_stone.png"

const MESA_ALTO_M: float = 0.78
const PUPITRE_TAM := Vector3(1.0, 0.65, 0.5)   ## cada pupitre va de 0,9 a 1,9 m del eje: el pasillo queda libre
const PUPITRE_CHOQUE := Vector2(18, 9)
const BANQUETA_TAM := Vector3(0.35, 0.45, 0.35)

const CUARTOS: Array[Dictionary] = [
	{"nombre": "Aula", "centro": Vector2(0.0, 0.95), "tam": Vector2(11.2, 7.9), "central": true, "suelo": MADERA},
	# detrás de la pizarra; su puerta, en el eje del pasillo, para que el camino a la calle no cruce pupitres
	{"nombre": "DespachoMaestro", "centro": Vector2(0.0, -3.95), "tam": Vector2(11.2, 1.9), "paso": Vector2(0.0, -3.0), "ancho": 0.9, "hoja": true, "suelo": MADERA},
]

const TABIQUES: Array = [
	[Vector2(-5.6, -3.0), Vector2(5.6, -3.0)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.2, "abre": true},
	{"lado": "sur", "en": 3.6, "ancho": 1.2},
	{"lado": "oeste", "en": -0.5, "ancho": 1.2},
	{"lado": "oeste", "en": 2.5, "ancho": 1.2},
	{"lado": "este", "en": -0.5, "ancho": 1.2},
	{"lado": "este", "en": 2.5, "ancho": 1.2},
	{"lado": "norte", "en": -3.5, "ancho": 0.8},
	{"lado": "norte", "en": 3.5, "ancho": 0.8},
]

const MUEBLES: Array[Dictionary] = [
	# Aula, fondo: la pizarra en el tabique, la mesa del maestro con su silla, la estufa y bombillas
	{"cosa": "pizarra", "pos": Vector2(-2.0, -2.97)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(2.0, -2.2), "tam": Vector3(1.6, MESA_ALTO_M, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(2.0, -2.75), "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "vela", "pos": Vector2(2.5, -2.2), "alto": MESA_ALTO_M},
	{"cosa": "estufa", "pos": Vector2(-5.0, -2.3)},
	{"cosa": "bombilla", "pos": Vector2(0.0, -0.5)},
	{"cosa": "bombilla", "pos": Vector2(0.0, 2.8)},
	# Aula, paredes: librería, estante y, junto a la puerta, el colgador de los abrigos
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-5.4, 1.5), "giro": 90.0, "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(5.4, 1.5), "giro": -90.0, "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(-1.9, 4.7), "giro": 180.0, "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	# Seis filas de pupitres a cada lado del pasillo, con su banqueta detrás (al sur): los niños miran a la pizarra
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-1.4, -1.00), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-1.15, -0.55), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.4, -1.00), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(1.15, -0.55), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-1.4, -0.05), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-1.15, 0.40), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.4, -0.05), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(1.15, 0.40), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-1.4, 0.90), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-1.15, 1.35), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.4, 0.90), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(1.15, 1.35), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-1.4, 1.85), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-1.15, 2.30), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.4, 1.85), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(1.15, 2.30), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-1.4, 2.80), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-1.15, 3.25), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.4, 2.80), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(1.15, 3.25), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-1.4, 3.75), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-1.15, 4.20), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.4, 3.75), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(1.15, 4.20), "tam": BANQUETA_TAM},
	# Despacho del maestro: mesa con silla y vela, dos librerías y el arcón de los cuadernos
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-3.5, -4.1), "tam": Vector3(1.6, MESA_ALTO_M, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-3.5, -3.45), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "vela", "pos": Vector2(-3.0, -4.1), "alto": MESA_ALTO_M},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(2.6, -4.65), "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(3.7, -4.65), "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Chest_Wood.gltf", "pos": Vector2(5.0, -3.8), "tam": Vector3(0.8, 0.6, 0.5), "choque": Vector2(14, 9)},
	{"cosa": "bombilla", "pos": Vector2(0.0, -3.95)},
]

const MARCAS: Dictionary = {
	"maestro": Vector2(-0.8, -2.3),
	"pupitre_1": Vector2(-0.65, -0.55),
	"pupitre_2": Vector2(0.65, -0.55),
	"pupitre_3": Vector2(-0.65, 0.40),
	"pupitre_4": Vector2(0.65, 0.40),
	"pupitre_5": Vector2(-0.65, 1.35),
	"pupitre_6": Vector2(0.65, 1.35),
	"pupitre_7": Vector2(-0.65, 2.30),
	"pupitre_8": Vector2(0.65, 2.30),
	"pupitre_9": Vector2(-0.65, 3.25),
	"pupitre_10": Vector2(0.65, 3.25),
	"pupitre_11": Vector2(-0.65, 4.20),
	"pupitre_12": Vector2(0.65, 4.20),
	"puerta": Vector2(PUERTA_X_M, 4.9),
	"ventana": Vector2(VENTANA_X_M, 4.9),
}
