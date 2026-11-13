extends RefCounted

## Plano del Hospital de Urgencias y Morgue Forense (2026-11-13, interiores de tamaño real). Nivel 4 (autoridades):
## luz de la red oficial, teléfono y bombillas. El pasillo de punta a punta con el mostrador de entrada; a un lado, la
## morgue con sus tres mesas de acero (los cuerpos los enseña el juego) y la sala de urgencias con la camilla; al otro,
## la consulta del médico, su dormitorio y la botica. Piedra y teja roja. De 7,7 × 5,4 m a 14 × 9,8 m.
## Metros respecto al centro; x hacia el este, z hacia el sur (puerta al sur): se construye con «girar» y la puerta
## queda al norte, como siempre estuvo. Lo lee tools/casas/construir_casa.gd (por tools/casas/leer_plano.gd).

const ID := "building_hospital"
const PLANTA_M := Vector2(14.0, 9.8)
const PUERTA_X_M: float = 0.0        ## la puerta, en medio del muro (da al pasillo)
const PUERTA_ANCHO_M: float = 1.6
const VENTANA_X_M: float = -4.7      ## la ventana que se abre y se cierra (la de urgencias, en el muro de la puerta)
const CARTEL_M := Vector3(1.6, 2.4, 5.12)

const FACHADA := "wall_brick_stone_center.png"
const TABIQUE := "wall_brick_small_sand.png"
const MADERA := "floor_wood_planks_wide.png"
const BALDOSA := "floor_tiles_tan_large.png"
const LOSA := "floor_stone_pattern.png"   ## pasillo y morgue
const TEJADO := "roof_clay_red_center.png"
const ZOCALO := "wall_stone.png"

const MESA_ALTO_M: float = 0.78
const CABLE_ALTO_M: float = 2.9      ## la acometida de la red, por encima de la puerta
const VERDE_HOSPITAL := Color(0.2, 0.34, 0.3)

const CUARTOS: Array[Dictionary] = [
	{"nombre": "Pasillo", "centro": Vector2(0.0, 0.0), "tam": Vector2(4.8, 9.8), "central": true, "suelo": LOSA},
	{"nombre": "Morgue", "centro": Vector2(-4.7, -2.45), "tam": Vector2(4.6, 4.9), "paso": Vector2(-2.4, -1.0), "ancho": 1.0, "hoja": true, "suelo": LOSA},
	{"nombre": "Urgencias", "centro": Vector2(-4.7, 2.45), "tam": Vector2(4.6, 4.9), "paso": Vector2(-2.4, 1.6), "ancho": 1.1, "hoja": true, "suelo": BALDOSA},
	{"nombre": "Consulta", "centro": Vector2(4.7, -3.25), "tam": Vector2(4.6, 3.3), "paso": Vector2(2.4, -2.6), "ancho": 1.0, "hoja": true, "suelo": MADERA},
	{"nombre": "DormitorioMedico", "centro": Vector2(4.7, 0.0), "tam": Vector2(4.6, 3.2), "paso": Vector2(2.4, 0.0), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	{"nombre": "Botica", "centro": Vector2(4.7, 3.25), "tam": Vector2(4.6, 3.3), "paso": Vector2(2.4, 3.0), "ancho": 0.9, "hoja": true, "suelo": BALDOSA},
]

const TABIQUES: Array = [
	[Vector2(-2.4, -4.9), Vector2(-2.4, 4.9)],
	[Vector2(2.4, -4.9), Vector2(2.4, 4.9)],
	[Vector2(-7.0, 0.0), Vector2(-2.4, 0.0)],
	[Vector2(2.4, -1.6), Vector2(7.0, -1.6)],
	[Vector2(2.4, 1.6), Vector2(7.0, 1.6)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.2, "abre": true},
	{"lado": "sur", "en": 4.7, "ancho": 0.8},
	{"lado": "norte", "en": -4.7, "ancho": 0.6},
	{"lado": "norte", "en": 4.7, "ancho": 1.2},
	{"lado": "oeste", "en": -2.45, "ancho": 0.6},
	{"lado": "oeste", "en": 2.45, "ancho": 1.2},
	{"lado": "este", "en": 0.0, "ancho": 1.0},
	{"lado": "este", "en": 3.25, "ancho": 0.6},
]

const MUEBLES: Array[Dictionary] = [
	# Pasillo: el mostrador de entrada junto a la puerta, contra la fachada, con su teléfono; bombillas
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-1.55, 4.42), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"cosa": "telefono", "pos": Vector2(-2.0, 4.42), "alto": MESA_ALTO_M},
	{"modelo": "props/Shelf_Small_Bottles.gltf", "pos": Vector2(1.6, -4.7), "tam": Vector3(1.0, 1.2, 0.35), "choque": Vector2(18, 6)},
	{"cosa": "bombilla", "pos": Vector2(0.0, -2.4)},
	{"cosa": "bombilla", "pos": Vector2(0.0, 2.4)},
	# Morgue: tres mesas de acero (sus choques y cuerpos los pone el juego), armario y estante de frascos
	{"cosa": "mesa_morgue", "pos": Vector2(-6.1, -2.4)},
	{"cosa": "mesa_morgue", "pos": Vector2(-4.7, -2.4)},
	{"cosa": "mesa_morgue", "pos": Vector2(-3.3, -2.4)},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-4.7, -4.6), "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"modelo": "props/Shelf_Small_Bottles.gltf", "pos": Vector2(-6.65, -0.6), "giro": 90.0, "tam": Vector3(1.0, 1.2, 0.35), "choque": Vector2(18, 6)},
	{"cosa": "bombilla", "pos": Vector2(-4.7, -2.45)},
	# Urgencias: la camilla (su choque lo pone el juego), una segunda cama, palangana y armario de vendas
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-4.4, 2.6), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-6.2, 2.6), "tam": Vector3(0.95, 0.9, 2.0), "choque": Vector2(17, 36)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-5.3, 1.9), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(-4.7, 0.32), "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"cosa": "bombilla", "pos": Vector2(-4.7, 2.45)},
	# Consulta: mesa del médico con teléfono, su silla y la del enfermo, librería
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(5.0, -3.4), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(5.0, -4.2), "tam": Vector3(0.45, 0.95, 0.45)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(5.0, -2.6), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "telefono", "pos": Vector2(5.5, -3.4), "alto": MESA_ALTO_M},
	{"modelo": "props/Bookcase_2.gltf", "pos": Vector2(6.75, -3.2), "giro": -90.0, "tam": Vector3(0.9, 1.8, 0.4), "choque": Vector2(16, 7)},
	{"cosa": "alfombra", "pos": Vector2(5.0, -3.4), "tam2": Vector2(2.4, 2.0), "color": VERDE_HOSPITAL},
	{"cosa": "bombilla", "pos": Vector2(4.7, -3.25)},
	# Dormitorio del médico: su cama (choque del juego), mesilla y la mesa donde cena, contra la pared (paso libre a la cama)
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(6.3, 0.3), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(6.55, -1.3), "tam": Vector3(0.5, 0.6, 0.4)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(4.2, 1.1), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(3.15, 1.1), "giro": 90.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "bombilla", "pos": Vector2(4.7, 0.0)},
	# Botica: estantes de frascos, armario y caja
	{"modelo": "props/Shelf_Small_Bottles.gltf", "pos": Vector2(6.65, 2.6), "giro": -90.0, "tam": Vector3(1.0, 1.2, 0.35), "choque": Vector2(18, 6)},
	{"modelo": "props/Shelf_Small_Bottles.gltf", "pos": Vector2(6.65, 3.9), "giro": -90.0, "tam": Vector3(1.0, 1.2, 0.35), "choque": Vector2(18, 6)},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(4.6, 4.6), "tam": Vector3(1.2, 1.9, 0.55), "choque": Vector2(21, 10)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(3.4, 4.4), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
	{"cosa": "bombilla", "pos": Vector2(4.7, 3.25)},
	# Fuera: el cuadro junto a la puerta y la acometida de la red oficial, que sube hasta el alero
	{"cosa": "cuadro_electrico", "pos": Vector2(1.4, 5.1), "fuera": true},
	{"cosa": "cable", "pos": Vector2(1.4, 5.08), "medida": Vector3(0.04, 1.6, 0.04), "alto": 1.5, "fuera": true},
	{"cosa": "cable", "pos": Vector2(4.2, 5.08), "medida": Vector3(5.6, 0.04, 0.04), "alto": CABLE_ALTO_M, "fuera": true},
]

const MARCAS: Dictionary = {
	"trabajo": Vector2(-1.55, 3.75),
	"camilla": Vector2(-4.4, 2.6),
	"cama_1": Vector2(6.3, 0.3),
	"mesa": Vector2(4.2, 0.4),
	"mesa_morgue_1": Vector2(-6.1, -2.4),
	"mesa_morgue_2": Vector2(-4.7, -2.4),
	"mesa_morgue_3": Vector2(-3.3, -2.4),
	"puerta": Vector2(PUERTA_X_M, 4.9),
	"ventana": Vector2(VENTANA_X_M, 4.9),
}
