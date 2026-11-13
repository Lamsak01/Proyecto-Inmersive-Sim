extends RefCounted

## Plano de la Comisaría y Cárcel del Valle (2026-11-13, interiores de tamaño real). Nivel 4 (autoridades): luz de la
## red oficial, teléfono y lámparas. La sala de guardia de punta a punta con el mostrador (donde se entrega el informe
## del Caso I) y bancos; al fondo, el calabozo con su reja corredera, el catre, el cubo y el taburete; a un lado, el
## despacho del comisario (con su terminal, que pone el juego) y el archivo de pruebas con la denuncia; al otro, el
## dormitorio de guardia, el comedor y la armería. Piedra y teja roja. De 8 × 5,4 m a 14 × 9,8 m.
## Metros respecto al centro; x hacia el este, z hacia el sur (puerta al sur): se construye con «girar» y la puerta
## queda al norte, como siempre estuvo. Lo lee tools/casas/construir_casa.gd (por tools/casas/leer_plano.gd).

const ID := "building_police"
const PLANTA_M := Vector2(14.0, 9.8)
const PUERTA_X_M: float = 0.0        ## la puerta, en medio del muro (da a la sala de guardia)
const PUERTA_ANCHO_M: float = 1.6
const VENTANA_X_M: float = -4.8      ## la ventana que se abre y se cierra (la del archivo, en el muro de la puerta)
const CARTEL_M := Vector3(1.6, 2.4, 5.12)

const FACHADA := "wall_brick_stone_center.png"
const TABIQUE := "wall_stone.png"
const MADERA := "floor_wood_planks_wide.png"
const BALDOSA := "floor_tiles_tan_large.png"
const LOSA := "floor_stone_pattern.png"   ## sala de guardia y calabozo
const TEJADO := "roof_clay_red_center.png"
const ZOCALO := "wall_stone.png"

const MESA_ALTO_M: float = 0.78
const CABLE_ALTO_M: float = 2.9      ## la acometida de la red, por encima de la puerta
const AZUL_POLICIA := Color(0.14, 0.18, 0.3)

## La reja del calabozo, en su tabique (este-oeste): se desliza a lo largo de él (ver tools/casas/cosas_oficio.gd).
const REJA: Dictionary = {"en": Vector2(0.0, -2.0), "ancho": 1.2}

const CUARTOS: Array[Dictionary] = [
	{"nombre": "SalaGuardia", "centro": Vector2(0.0, 1.45), "tam": Vector2(4.8, 6.9), "central": true, "suelo": LOSA},
	{"nombre": "Calabozo", "centro": Vector2(0.0, -3.45), "tam": Vector2(4.8, 2.9), "paso": REJA["en"], "ancho": REJA["ancho"], "hoja": false, "suelo": LOSA},
	{"nombre": "DespachoComisario", "centro": Vector2(-4.7, -2.45), "tam": Vector2(4.6, 4.9), "paso": Vector2(-2.4, -1.0), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "ArchivoPruebas", "centro": Vector2(-4.7, 2.45), "tam": Vector2(4.6, 4.9), "paso": Vector2(-2.4, 1.5), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "DormitorioGuardia", "centro": Vector2(4.7, -2.75), "tam": Vector2(4.6, 4.3), "paso": Vector2(2.4, -1.3), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	{"nombre": "Comedor", "centro": Vector2(4.7, 0.65), "tam": Vector2(4.6, 2.5), "paso": Vector2(2.4, 0.6), "ancho": 0.9, "hoja": true, "suelo": BALDOSA},
	{"nombre": "Armeria", "centro": Vector2(4.7, 3.4), "tam": Vector2(4.6, 3.0), "paso": Vector2(2.4, 3.0), "ancho": 0.9, "hoja": true, "suelo": LOSA},
]

const TABIQUES: Array = [
	[Vector2(-2.4, -4.9), Vector2(-2.4, 4.9)],
	[Vector2(2.4, -4.9), Vector2(2.4, 4.9)],
	[Vector2(-2.4, -2.0), Vector2(2.4, -2.0)],
	[Vector2(-7.0, 0.0), Vector2(-2.4, 0.0)],
	[Vector2(2.4, -0.6), Vector2(7.0, -0.6)],
	[Vector2(2.4, 1.9), Vector2(7.0, 1.9)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.2, "abre": true},
	{"lado": "sur", "en": 4.8, "ancho": 0.8},
	{"lado": "norte", "en": 0.0, "ancho": 0.5},
	{"lado": "norte", "en": -4.7, "ancho": 1.2},
	{"lado": "norte", "en": 4.7, "ancho": 1.0},
	{"lado": "oeste", "en": -2.45, "ancho": 1.0},
	{"lado": "oeste", "en": 2.45, "ancho": 1.0},
	{"lado": "este", "en": 0.65, "ancho": 0.8},
]

const MUEBLES: Array[Dictionary] = [
	# Sala de guardia: mostrador con su silla (la bandeja del informe la pone el juego), bancos de espera y lámparas
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.2, 2.6), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(0.6, 1.95), "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "telefono", "pos": Vector2(0.7, 2.6), "alto": MESA_ALTO_M},
	{"modelo": "props/Bench.gltf", "pos": Vector2(-1.95, 3.6), "giro": 90.0, "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(1.6, -1.8), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"cosa": "alfombra", "pos": Vector2(0.0, 3.4), "tam2": Vector2(1.8, 2.4), "color": AZUL_POLICIA},
	{"cosa": "lampara", "pos": Vector2(0.0, 0.4)},
	{"cosa": "bombilla", "pos": Vector2(0.0, 3.2)},
	# Calabozo: catre (su choque lo pone el juego), cubo y taburete
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(1.4, -4.0), "giro": 90.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Bucket_Wooden_1.gltf", "pos": Vector2(-1.9, -4.5), "tam": Vector3(0.35, 0.4, 0.35), "choque": Vector2(6, 6)},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-1.2, -4.4), "tam": Vector3(0.4, 0.5, 0.4), "choque": Vector2(7, 7)},
	{"cosa": "bombilla", "pos": Vector2(0.0, -3.45)},
	# Despacho del comisario: escritorio con teléfono, su silla y la del que viene, librería y armario
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-4.8, -2.6), "giro": 90.0, "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-5.55, -2.6), "giro": 90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-4.05, -2.6), "giro": -90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "telefono", "pos": Vector2(-4.8, -3.1), "alto": MESA_ALTO_M},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-4.8, -4.65), "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-3.3, -4.6), "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"cosa": "alfombra", "pos": Vector2(-4.8, -2.6), "tam2": Vector2(2.4, 2.4), "color": AZUL_POLICIA},
	{"cosa": "bombilla", "pos": Vector2(-4.7, -2.45)},
	# Archivo de pruebas: la mesa de la denuncia (su choque lo pone el juego), armarios y estanterías de legajos
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-4.7, 2.4), "tam": Vector3(1.6, 0.78, 0.9)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-4.7, 3.15), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-6.55, 1.4), "giro": 90.0, "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(-6.55, 3.3), "giro": 90.0, "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(-4.7, 0.3), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"cosa": "bombilla", "pos": Vector2(-4.7, 2.45)},
	# Dormitorio de guardia: la cama del comisario y del guardia, mesilla y armario
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(5.3, -3.85), "giro": 90.0, "tam": Vector3(0.95, 0.9, 2.0), "choque": Vector2(36, 17)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(3.9, -4.6), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(6.55, -1.6), "giro": -90.0, "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"cosa": "bombilla", "pos": Vector2(4.7, -2.75)},
	# Comedor: mesa con dos bancos y estante
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(5.0, 0.65), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(5.0, -0.1), "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(5.0, 1.4), "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"cosa": "bombilla", "pos": Vector2(4.7, 0.65)},
	# Armería: dos armeros, cajas de munición y estante
	{"modelo": "props/WeaponStand.gltf", "pos": Vector2(6.5, 2.8), "giro": -90.0, "tam": Vector3(1.2, 1.6, 0.5), "choque": Vector2(21, 9)},
	{"modelo": "props/WeaponStand.gltf", "pos": Vector2(6.5, 4.2), "giro": -90.0, "tam": Vector3(1.2, 1.6, 0.5), "choque": Vector2(21, 9)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(4.4, 4.4), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(4.4, 2.1), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"cosa": "bombilla", "pos": Vector2(4.7, 3.4)},
	# Fuera: el cuadro junto a la puerta y la acometida de la red oficial, que sube hasta el alero
	{"cosa": "cuadro_electrico", "pos": Vector2(-1.4, 5.1), "fuera": true},
	{"cosa": "cable", "pos": Vector2(-1.4, 5.08), "medida": Vector3(0.04, 1.6, 0.04), "alto": 1.5, "fuera": true},
	{"cosa": "cable", "pos": Vector2(-4.2, 5.08), "medida": Vector3(5.6, 0.04, 0.04), "alto": CABLE_ALTO_M, "fuera": true},
]

const MARCAS: Dictionary = {
	"trabajo": Vector2(1.4, 1.85),
	"informe": Vector2(1.7, 2.6),
	"escritorio": Vector2(-3.6, -1.8),
	"terminal": Vector2(-6.5, -0.8),
	"archivo": Vector2(-4.7, 2.4),
	"mesa": Vector2(3.6, 0.65),
	"cama_1": Vector2(5.3, -3.85),
	"celda": Vector2(0.0, -3.45),
	"cama_celda": Vector2(1.4, -4.0),
	"celda_puerta": REJA["en"],
	"celda_salida": Vector2(0.0, -1.3),
	"ante_celda": Vector2(-0.5, -1.5),
	"puerta": Vector2(PUERTA_X_M, 4.9),
	"ventana": Vector2(VENTANA_X_M, 4.9),
}
