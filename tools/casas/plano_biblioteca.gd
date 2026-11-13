extends RefCounted

## Plano de la Biblioteca del Valle (2026-11-13, interiores de tamaño real). Edificio público: madera y teja gris,
## bombillas. La sala de lectura con estanterías por las paredes, dos filas de mesas (cada lector en su silla, marcas
## «silla_lectura_N», y el sitio de lectura «lectura») y el mostrador junto a la puerta; al este, el archivo y, detrás
## de él, la sala oculta del Caso I: se entra por una estantería que se abre como una puerta («palanca»); dentro, la
## mesa con el cuaderno de firmas («libro_mayor») y el tomo de venenos («libro_roto»). De 7,2 × 5,4 m a 14 × 9,8 m.
## Metros respecto al centro; x hacia el este, z hacia el sur (puerta al sur, como siempre). Lo lee
## tools/casas/construir_casa.gd.

const ID := "building_library"
const PLANTA_M := Vector2(14.0, 9.8)
const PUERTA_X_M: float = 0.0
const PUERTA_ANCHO_M: float = 1.4
const VENTANA_X_M: float = -4.5      ## la ventana que se abre y se cierra (la de la sala, en el muro de la puerta)
const CARTEL_M := Vector3(1.4, 2.4, 5.12)

const FACHADA := "wall_timber_structure_horizontal.png"
const TABIQUE := "wall_timber.png"
const MADERA := "floor_wood_planks_wide.png"
const TEJADO := "roof_clay_grey_center.png"
const ZOCALO := "wall_stone.png"

const MESA_ALTO_M: float = 0.78
const ESTANTE_TAM := Vector3(0.9, 1.8, 0.4)
const ESTANTE_CHOQUE := Vector2(16, 7)
const MESA_TAM := Vector3(1.6, MESA_ALTO_M, 0.9)
const MESA_CHOQUE := Vector2(28, 16)
const SILLA_TAM := Vector3(0.45, 0.95, 0.45)
## Detrás de cada fila de mesas, la franja de las sillas: un «cuarto» solo para las rutas (sin suelo ni paredes), con
## su entrada hacia el pasillo, para que cada lector llegue de lado a su silla sin cruzar mesas.
const FRANJA_ALTO_M: float = 0.8

const CUARTOS: Array[Dictionary] = [
	{"nombre": "FilaLectura1", "centro": Vector2(-3.5, -0.65), "tam": Vector2(4.2, FRANJA_ALTO_M), "paso": Vector2(-1.4, -0.65), "solo_ruta": true},
	{"nombre": "FilaLectura2", "centro": Vector2(-4.3, 2.35), "tam": Vector2(2.6, FRANJA_ALTO_M), "paso": Vector2(-3.0, 2.35), "solo_ruta": true},
	{"nombre": "SalaLectura", "centro": Vector2(-2.0, 0.0), "tam": Vector2(10.0, 9.8), "central": true, "suelo": MADERA},
	{"nombre": "Archivo", "centro": Vector2(5.0, 2.0), "tam": Vector2(4.0, 5.8), "paso": Vector2(3.0, 2.6), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	# la sala oculta da al archivo, no a la sala: solo entra quien la busca (los vecinos no tienen nada ahí)
	{"nombre": "SalaOculta", "centro": Vector2(5.0, -2.9), "tam": Vector2(4.0, 4.0), "paso": Vector2(5.5, -0.9), "ancho": 0.8, "suelo": MADERA},
]

const TABIQUES: Array = [
	[Vector2(3.0, -4.9), Vector2(3.0, 4.9)],
	[Vector2(3.0, -0.9), Vector2(7.0, -0.9)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.4, "abre": true},
	{"lado": "sur", "en": 5.0, "ancho": 0.8},
	{"lado": "oeste", "en": -1.0, "ancho": 1.2},
	{"lado": "norte", "en": 1.6, "ancho": 1.0},
	{"lado": "este", "en": 3.0, "ancho": 0.8},
]

const MUEBLES: Array[Dictionary] = [
	# Sala: estanterías en las paredes oeste y norte
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-6.75, -3.6), "giro": 90.0, "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-6.75, -2.6), "giro": 90.0, "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-6.75, 0.6), "giro": 90.0, "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-6.75, 1.6), "giro": 90.0, "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-6.75, 3.6), "giro": 90.0, "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-6.0, -4.65), "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-4.9, -4.65), "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-3.8, -4.65), "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-2.7, -4.65), "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-1.6, -4.65), "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-0.5, -4.65), "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(0.6, -4.65), "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(2.5, -4.65), "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	# Sala: dos filas de mesas de lectura con sus sillas al sur (los lectores miran al norte) y una vela en cada mesa
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-4.4, -1.5), "tam": MESA_TAM, "choque": MESA_CHOQUE},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-2.6, -1.5), "tam": MESA_TAM, "choque": MESA_CHOQUE},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-4.4, 1.5), "tam": MESA_TAM, "choque": MESA_CHOQUE},
	{"cosa": "vela", "pos": Vector2(-4.4, -1.5), "alto": MESA_ALTO_M},
	{"cosa": "vela", "pos": Vector2(-2.6, -1.5), "alto": MESA_ALTO_M},
	{"cosa": "vela", "pos": Vector2(-4.4, 1.5), "alto": MESA_ALTO_M},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-4.9, -0.65), "giro": 180.0, "tam": SILLA_TAM},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-3.9, -0.65), "giro": 180.0, "tam": SILLA_TAM},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-3.1, -0.65), "giro": 180.0, "tam": SILLA_TAM},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-2.1, -0.65), "giro": 180.0, "tam": SILLA_TAM},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-4.9, 2.35), "giro": 180.0, "tam": SILLA_TAM},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-3.9, 2.35), "giro": 180.0, "tam": SILLA_TAM},
	# Sala: el mostrador del bibliotecario junto a la puerta, con su silla, una alfombra y bombillas
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-3.0, 4.0), "tam": MESA_TAM, "choque": MESA_CHOQUE},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-3.0, 4.55), "tam": SILLA_TAM},
	{"cosa": "alfombra", "pos": Vector2(-3.5, 0.5), "tam2": Vector2(4.4, 4.0), "color": Color(0.3, 0.22, 0.16)},
	{"cosa": "bombilla", "pos": Vector2(-3.5, -1.0)},
	{"cosa": "bombilla", "pos": Vector2(-3.5, 2.0)},
	{"cosa": "bombilla", "pos": Vector2(0.5, 0.5)},
	# Archivo: estantes de legajos, cajas y la estantería móvil, abierta como una puerta delante de la sala oculta
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(6.75, 1.5), "giro": -90.0, "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(6.75, 2.6), "giro": -90.0, "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(6.75, 3.7), "giro": -90.0, "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(4.0, 4.3), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(3.6, -0.4), "tam": Vector3(0.6, 0.6, 0.6), "choque": Vector2(11, 11)},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(4.5, -0.65), "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(6.15, -0.45), "giro": 90.0, "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"cosa": "bombilla", "pos": Vector2(5.0, 2.0)},
	# Sala oculta: la mesa con el cuaderno de firmas y el tomo de venenos, la estantería prohibida, un arcón y una vela
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(5.0, -3.6), "tam": MESA_TAM, "choque": MESA_CHOQUE},
	{"cosa": "vela", "pos": Vector2(5.0, -3.6), "alto": MESA_ALTO_M},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(3.45, -2.9), "giro": 90.0, "tam": ESTANTE_TAM, "choque": ESTANTE_CHOQUE},
	{"modelo": "props/Chest_Wood.gltf", "pos": Vector2(6.4, -2.4), "giro": -90.0, "tam": Vector3(0.8, 0.6, 0.5), "choque": Vector2(14, 9)},
]

const MARCAS: Dictionary = {
	"lectura": Vector2(-3.5, -0.65),
	"silla_lectura_1": Vector2(-4.9, -0.65),
	"silla_lectura_2": Vector2(-3.9, -0.65),
	"silla_lectura_3": Vector2(-3.1, -0.65),
	"silla_lectura_4": Vector2(-2.1, -0.65),
	"silla_lectura_5": Vector2(-4.9, 2.35),
	"silla_lectura_6": Vector2(-3.9, 2.35),
	"palanca": Vector2(5.5, -0.3),
	"libro_mayor": Vector2(4.6, -3.6),
	"libro_roto": Vector2(5.4, -3.6),
	"puerta": Vector2(PUERTA_X_M, 4.9),
	"ventana": Vector2(VENTANA_X_M, 4.9),
}
