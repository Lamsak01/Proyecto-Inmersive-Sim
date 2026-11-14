extends RefCounted

## Plano de la casa y taller de cantería (2026-11-14, interiores de tamaño real, Tarea 4): vivienda humilde de piedra
## rústica con taller de labra abierto hacia la explanada de rocas del este (solar_w1). Su planta (8,4 × 9,8 m) deja
## margen limpio entre el muro este y los cuatro peñascos de la cantera, con dormitorios al oeste y taller al este.
## Metros respecto al centro de la casa; x hacia el este, z hacia el sur (la puerta de la calle da al sur).

const ID := "mixed_family_quarry"
const PLANTA_M := Vector2(8.4, 9.8)
const PUERTA_X_M: float = -0.05
const PUERTA_ANCHO_M: float = 1.4
const VENTANA_X_M: float = 2.8
const CARTEL_M := Vector3(-1.50, 2.4, 5.12)

const FACHADA := "wall_rock_structure.png"
const TABIQUE := "wall_timber.png"
const MADERA := "floor_wood_planks_damaged.png"
const BALDOSA := "floor_stone_pattern_small.png"
const TIERRA := "floor_ground_dirt.png"
const TEJADO := ""
const TEJADO_CHAPA: bool = true
const ZOCALO := "wall_stone.png"

const CUARTOS: Array[Dictionary] = [
	{"nombre": "Sala", "centro": Vector2(-0.05, 0.0), "tam": Vector2(2.9, 9.8), "central": true, "suelo": TIERRA},
	{"nombre": "DormitorioMaestro", "centro": Vector2(-2.85, -2.45), "tam": Vector2(2.7, 4.9), "paso": Vector2(-1.5, -1.2), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	{"nombre": "DormitorioFamiliar", "centro": Vector2(-2.85, 2.45), "tam": Vector2(2.7, 4.9), "paso": Vector2(-1.5, 1.2), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	{"nombre": "Aseo", "centro": Vector2(2.8, -3.3), "tam": Vector2(2.8, 3.2), "paso": Vector2(1.4, -2.8), "ancho": 0.9, "hoja": true, "suelo": TIERRA},
	{"nombre": "Taller", "centro": Vector2(2.8, 1.6), "tam": Vector2(2.8, 6.6), "paso": Vector2(1.4, 1.2), "ancho": 1.6, "hoja": false, "suelo": BALDOSA},
]

const TABIQUES: Array = [
	[Vector2(-1.5, -4.9), Vector2(-1.5, 4.9)],
	[Vector2(-4.2, 0.0), Vector2(-1.5, 0.0)],
	[Vector2(1.4, -4.9), Vector2(1.4, 4.9)],
	[Vector2(1.4, -1.7), Vector2(4.2, -1.7)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.0, "abre": true},
	{"lado": "sur", "en": -2.85, "ancho": 0.8},
	{"lado": "oeste", "en": -2.45, "ancho": 0.8},
	{"lado": "norte", "en": 2.8, "ancho": 0.6},
	{"lado": "norte", "en": -0.05, "ancho": 0.6},
	{"lado": "este", "en": 1.8, "ancho": 1.1},
]

const MUEBLES: Array[Dictionary] = [
	# Dormitorio del maestro cantero (el cofre va en su marca): cama, mesilla con vela y linterna de dinamo
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-3.55, -3.65), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-2.7, -4.45), "tam": Vector3(0.5, 0.6, 0.4)},
	{"cosa": "vela", "pos": Vector2(-2.7, -4.45), "alto": 0.6},
	{"cosa": "linterna", "pos": Vector2(-2.05, -4.45)},
	# Dormitorio del familiar: cama, estante y taburete con vela
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-3.55, 3.65), "giro": 180.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(-2.45, 4.55), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-2.2, 0.55), "tam": Vector3(0.4, 0.5, 0.4)},
	{"cosa": "vela", "pos": Vector2(-2.2, 0.55), "alto": 0.5},
	# Sala central: hogar de piedra, mesa con bancos, barril de agua, radio de galena y mostrador de venta
	{"cosa": "hogar", "pos": Vector2(-0.05, -4.35), "choque": Vector2(25, 14)},
	{"cosa": "lena", "pos": Vector2(0.95, -4.42)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-0.05, -2.05), "tam": Vector3(1.45, 0.78, 0.85), "choque": Vector2(25, 15)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(-0.05, -2.75), "tam": Vector3(1.3, 0.5, 0.42), "choque": Vector2(23, 8)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(-0.05, -1.35), "tam": Vector3(1.3, 0.5, 0.42), "choque": Vector2(23, 8)},
	{"cosa": "vela", "pos": Vector2(-0.05, -2.05), "alto": 0.78},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(-1.10, -4.30), "tam": Vector3(0.56, 0.9, 0.56), "choque": Vector2(10, 10)},
	{"modelo": "props/Bucket_Wooden_1.gltf", "pos": Vector2(-1.10, -3.65), "tam": Vector3(0.38, 0.4, 0.38)},
	{"cosa": "radio_galena", "pos": Vector2(0.95, -3.65), "choque": Vector2(7, 7)},
	{"modelo": "props/Workbench_Drawers.gltf", "pos": Vector2(1.02, 3.55), "giro": -90.0, "tam": Vector3(1.1, 0.9, 0.5), "choque": Vector2(19, 9)},
	# Taller de cantería (al este, mirando a las rocas): caballete con bloque de caliza, sillares, pico, muela y banco
	{"modelo": "props/Workbench.gltf", "pos": Vector2(3.75, 0.75), "giro": 90.0, "tam": Vector3(1.5, 0.9, 0.65), "choque": Vector2(26, 11)},
	{"cosa": "banco_cantero", "pos": Vector2(3.25, 2.80), "giro": -90.0, "choque": Vector2(18, 12)},
	{"cosa": "sillares_piedra", "pos": Vector2(2.35, 4.25), "choque": Vector2(17, 10)},
	{"modelo": "props/Pickaxe_Bronze.gltf", "pos": Vector2(3.82, 1.95), "giro": 25.0, "tam": Vector3(0.45, 0.9, 0.2)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(3.65, -1.1), "tam": Vector3(0.68, 0.68, 0.68), "choque": Vector2(12, 12)},
	{"modelo": "props/Whetstone.gltf", "pos": Vector2(2.15, -1.15), "tam": Vector3(0.7, 0.8, 0.5), "choque": Vector2(12, 9)},
	# Aseo y letrina exterior
	{"cosa": "tina", "pos": Vector2(3.40, -3.4), "choque": Vector2(19, 19)},
	{"cosa": "palangana", "pos": Vector2(2.00, -4.4), "choque": Vector2(7, 7)},
	{"modelo": "props/Bucket_Wooden_1.gltf", "pos": Vector2(2.75, -4.45), "tam": Vector3(0.38, 0.4, 0.38)},
	{"cosa": "letrina", "pos": Vector2(2.8, -6.6), "choque": Vector2(22, 22), "fuera": true},
]

const MARCAS: Dictionary = {
	"trabajo": Vector2(2.65, 1.5),
	"trabajo_familiar": Vector2(2.20, 3.20),
	"puesto": Vector2(0.35, 3.55),
	"cama_1": Vector2(-3.55, -3.65),
	"cama_2": Vector2(-3.55, 3.65),
	"mesa": Vector2(-0.05, -0.35),
	"cofre": Vector2(-3.55, -2.05),
	"puerta": Vector2(PUERTA_X_M, 4.9),
	"ventana": Vector2(VENTANA_X_M, 4.9),
}
