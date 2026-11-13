extends RefCounted

## Plano de la Escuela del Valle (2026-11-13, interiores de tamaño real). Edificio público modesto: ladrillo arenisca,
## teja gris, bombillas y una estufa. El aula de punta a punta: seis filas de pupitres a cada lado del pasillo central,
## cada niño sentado en la banqueta de su pupitre (marca «pupitre_N»), la pizarra y la mesa del maestro al fondo;
## detrás, el despacho del maestro y el baño. De 7,2 × 5,4 m a 14 × 12,6 m. Metros respecto al centro; x hacia el
## este, z hacia el sur (puerta al sur, como siempre). Lo lee tools/casas/construir_casa.gd.

const ID := "building_school"
const PLANTA_M := Vector2(14.0, 12.6)
const PUERTA_X_M: float = 0.0        ## la puerta, en el eje del pasillo de los pupitres
const PUERTA_ANCHO_M: float = 1.4
const VENTANA_X_M: float = -4.5      ## la ventana que se abre y se cierra (en el muro de la puerta)
const CARTEL_M := Vector3(1.4, 2.4, 6.52)

const FACHADA := "wall_brick_sand_center.png"
const TABIQUE := "wall_brick_small_sand.png"
const MADERA := "floor_wood_planks.png"
const BALDOSA := "floor_tiles_tan_small.png"  ## el baño
const TEJADO := "roof_clay_grey_center.png"
const ZOCALO := "wall_stone.png"

const MESA_ALTO_M: float = 0.78
const PUPITRE_TAM := Vector3(1.0, 0.65, 0.5)   ## cada pupitre va de 0,9 a 1,9 m del eje: el pasillo queda libre
const PUPITRE_CHOQUE := Vector2(18, 9)
const BANQUETA_TAM := Vector3(0.35, 0.45, 0.35)
## Entre dos filas de pupitres, la franja de las banquetas: un «cuarto» solo para las rutas (sin suelo ni paredes),
## con su entrada en el pasillo, para que cada niño entre de lado hasta su banqueta sin cruzar pupitres.
const FRANJA_TAM := Vector2(1.5, 0.7)

const CUARTOS: Array[Dictionary] = [
	{"nombre": "Fila1", "centro": Vector2(-1.65, -0.60), "tam": FRANJA_TAM, "paso": Vector2(-0.9, -0.60), "solo_ruta": true},
	{"nombre": "Fila2", "centro": Vector2(1.65, -0.60), "tam": FRANJA_TAM, "paso": Vector2(0.9, -0.60), "solo_ruta": true},
	{"nombre": "Fila3", "centro": Vector2(-1.65, 0.60), "tam": FRANJA_TAM, "paso": Vector2(-0.9, 0.60), "solo_ruta": true},
	{"nombre": "Fila4", "centro": Vector2(1.65, 0.60), "tam": FRANJA_TAM, "paso": Vector2(0.9, 0.60), "solo_ruta": true},
	{"nombre": "Fila5", "centro": Vector2(-1.65, 1.80), "tam": FRANJA_TAM, "paso": Vector2(-0.9, 1.80), "solo_ruta": true},
	{"nombre": "Fila6", "centro": Vector2(1.65, 1.80), "tam": FRANJA_TAM, "paso": Vector2(0.9, 1.80), "solo_ruta": true},
	{"nombre": "Fila7", "centro": Vector2(-1.65, 3.00), "tam": FRANJA_TAM, "paso": Vector2(-0.9, 3.00), "solo_ruta": true},
	{"nombre": "Fila8", "centro": Vector2(1.65, 3.00), "tam": FRANJA_TAM, "paso": Vector2(0.9, 3.00), "solo_ruta": true},
	{"nombre": "Fila9", "centro": Vector2(-1.65, 4.20), "tam": FRANJA_TAM, "paso": Vector2(-0.9, 4.20), "solo_ruta": true},
	{"nombre": "Fila10", "centro": Vector2(1.65, 4.20), "tam": FRANJA_TAM, "paso": Vector2(0.9, 4.20), "solo_ruta": true},
	{"nombre": "Fila11", "centro": Vector2(-1.65, 5.40), "tam": FRANJA_TAM, "paso": Vector2(-0.9, 5.40), "solo_ruta": true},
	{"nombre": "Fila12", "centro": Vector2(1.65, 5.40), "tam": FRANJA_TAM, "paso": Vector2(0.9, 5.40), "solo_ruta": true},
	{"nombre": "Aula", "centro": Vector2(0.0, 1.5), "tam": Vector2(14.0, 9.6), "central": true, "suelo": MADERA},
	{"nombre": "DespachoMaestro", "centro": Vector2(-3.5, -4.8), "tam": Vector2(7.0, 3.0), "paso": Vector2(-0.8, -3.3), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	{"nombre": "Bano", "centro": Vector2(3.5, -4.8), "tam": Vector2(7.0, 3.0), "paso": Vector2(0.8, -3.3), "ancho": 0.9, "hoja": true, "suelo": BALDOSA},
]

const TABIQUES: Array = [
	[Vector2(-7.0, -3.3), Vector2(7.0, -3.3)],
	[Vector2(0.0, -6.3), Vector2(0.0, -3.3)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.4, "abre": true},
	{"lado": "sur", "en": 4.5, "ancho": 1.4},
	{"lado": "oeste", "en": -0.4, "ancho": 1.4},
	{"lado": "oeste", "en": 3.2, "ancho": 1.4},
	{"lado": "este", "en": -0.4, "ancho": 1.4},
	{"lado": "este", "en": 3.2, "ancho": 1.4},
	{"lado": "oeste", "en": -4.8, "ancho": 0.8},
	{"lado": "este", "en": -4.8, "ancho": 0.6},
	{"lado": "norte", "en": -3.5, "ancho": 1.0},
	{"lado": "norte", "en": 3.5, "ancho": 0.6},
]

const MUEBLES: Array[Dictionary] = [
	# Aula, fondo: la pizarra en el tabique, la mesa del maestro con su silla, la estufa y bombillas
	{"cosa": "pizarra", "pos": Vector2(-3.2, -3.27)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(3.0, -2.4), "tam": Vector3(1.6, MESA_ALTO_M, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(3.0, -3.08), "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "vela", "pos": Vector2(3.5, -2.4), "alto": MESA_ALTO_M},
	{"cosa": "estufa", "pos": Vector2(-6.4, -2.4), "giro": 90.0, "choque": Vector2(14, 11)},
	{"cosa": "bombilla", "pos": Vector2(0.0, -1.0)},
	{"cosa": "bombilla", "pos": Vector2(0.0, 3.0)},
	# Aula, paredes: librerías, estante y, junto a la puerta, el colgador de los abrigos
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-6.75, 1.5), "giro": 90.0, "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-6.75, 2.5), "giro": 90.0, "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(6.75, 1.5), "giro": -90.0, "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(-2.2, 6.1), "giro": 180.0, "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	# Seis filas de pupitres a cada lado del pasillo, con su banqueta detrás (al sur): los niños miran a la pizarra
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-1.4, -1.2), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-1.4, -0.6), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.4, -1.2), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(1.4, -0.6), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-1.4, 0.0), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-1.4, 0.6), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.4, 0.0), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(1.4, 0.6), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-1.4, 1.2), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-1.4, 1.8), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.4, 1.2), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(1.4, 1.8), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-1.4, 2.4), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-1.4, 3.0), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.4, 2.4), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(1.4, 3.0), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-1.4, 3.6), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-1.4, 4.2), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.4, 3.6), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(1.4, 4.2), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-1.4, 4.8), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-1.4, 5.4), "tam": BANQUETA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.4, 4.8), "tam": PUPITRE_TAM, "choque": PUPITRE_CHOQUE},
	{"modelo": "props/Stool.gltf", "pos": Vector2(1.4, 5.4), "tam": BANQUETA_TAM},
	# Despacho del maestro: mesa con silla y vela, librerías, el arcón de los cuadernos y una bombilla
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-4.5, -5.2), "tam": Vector3(1.6, MESA_ALTO_M, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-4.5, -4.48), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "vela", "pos": Vector2(-4.0, -5.2), "alto": MESA_ALTO_M},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-6.75, -4.8), "giro": 90.0, "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-2.4, -6.05), "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Chest_Wood.gltf", "pos": Vector2(-1.2, -5.9), "tam": Vector3(0.8, 0.6, 0.5), "choque": Vector2(14, 9)},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-0.25, -4.8), "giro": -90.0, "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"cosa": "bombilla", "pos": Vector2(-3.5, -4.8)},
	# Baño: tres retretes contra el muro del fondo, dos lavabos y una palangana
	{"cosa": "inodoro", "pos": Vector2(3.0, -5.95), "choque": Vector2(8, 9)},
	{"cosa": "inodoro", "pos": Vector2(4.4, -5.95), "choque": Vector2(8, 9)},
	{"cosa": "inodoro", "pos": Vector2(5.8, -5.95), "choque": Vector2(8, 9)},
	{"cosa": "lavabo", "pos": Vector2(6.7, -4.3), "giro": -90.0, "choque": Vector2(10, 7)},
	{"cosa": "lavabo", "pos": Vector2(6.7, -3.6), "giro": -90.0, "choque": Vector2(10, 7)},
	{"cosa": "palangana", "pos": Vector2(1.5, -5.95)},
	{"cosa": "bombilla", "pos": Vector2(3.5, -4.8)},
]

const MARCAS: Dictionary = {
	"maestro": Vector2(-0.6, -2.6),
	"pupitre_1": Vector2(-1.4, -0.6),
	"pupitre_2": Vector2(1.4, -0.6),
	"pupitre_3": Vector2(-1.4, 0.6),
	"pupitre_4": Vector2(1.4, 0.6),
	"pupitre_5": Vector2(-1.4, 1.8),
	"pupitre_6": Vector2(1.4, 1.8),
	"pupitre_7": Vector2(-1.4, 3.0),
	"pupitre_8": Vector2(1.4, 3.0),
	"pupitre_9": Vector2(-1.4, 4.2),
	"pupitre_10": Vector2(1.4, 4.2),
	"pupitre_11": Vector2(-1.4, 5.4),
	"pupitre_12": Vector2(1.4, 5.4),
	"puerta": Vector2(PUERTA_X_M, 6.3),
	"ventana": Vector2(VENTANA_X_M, 6.3),
}
