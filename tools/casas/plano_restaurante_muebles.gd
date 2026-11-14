extends RefCounted

## Mobiliario 3D de la Casa de Comidas / Trattoria «Il Corvo» (2026-11-14, Tarea 4), separado de su plano geométrico
## (tools/casas/plano_restaurante.gd) para mantener cada módulo por debajo de 150 líneas. Todas las sillas del comedor
## están a ±0,812 m de su mesa (14,5 px) y las de terraza a ±0,70 m (12,5 px), coincidiendo con VillageRestaurant.gd.

const ALFOMBRA_VINO := Color(0.46, 0.10, 0.12)
const ALFOMBRA_DUENO := Color(0.42, 0.24, 0.15)
const MESA_TAM := Vector3(1.12, 0.78, 0.85)
const SILLA_TAM := Vector3(0.42, 0.92, 0.42)
const TERRAZA_Y: float = 0.19
const MANTEL_Y: float = 1.05

const MUEBLES: Array[Dictionary] = [
	# Exterior sur: terraza empedrada con toldo y guirnalda nocturna, 5 veladores con sombrilla y 10 sillas a ±0,70 m
	{"cosa": "terraza_trattoria", "pos": Vector2(0.0, 6.776), "fuera": true},
	{"cosa": "mesa_terraza_verde", "pos": Vector2(-6.30, 6.776), "choque": Vector2(14, 14), "fuera": true, "base_y": TERRAZA_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-7.00, 6.776), "giro": 90.0, "tam": SILLA_TAM, "fuera": true, "base_y": TERRAZA_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-5.60, 6.776), "giro": -90.0, "tam": SILLA_TAM, "fuera": true, "base_y": TERRAZA_Y},
	{"cosa": "mesa_terraza_crema", "pos": Vector2(-3.78, 6.776), "choque": Vector2(14, 14), "fuera": true, "base_y": TERRAZA_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-4.48, 6.776), "giro": 90.0, "tam": SILLA_TAM, "fuera": true, "base_y": TERRAZA_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-3.08, 6.776), "giro": -90.0, "tam": SILLA_TAM, "fuera": true, "base_y": TERRAZA_Y},
	{"cosa": "mesa_terraza_verde", "pos": Vector2(0.28, 6.776), "choque": Vector2(14, 14), "fuera": true, "base_y": TERRAZA_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-0.42, 6.776), "giro": 90.0, "tam": SILLA_TAM, "fuera": true, "base_y": TERRAZA_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(0.98, 6.776), "giro": -90.0, "tam": SILLA_TAM, "fuera": true, "base_y": TERRAZA_Y},
	{"cosa": "mesa_terraza_crema", "pos": Vector2(2.80, 6.776), "choque": Vector2(14, 14), "fuera": true, "base_y": TERRAZA_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(2.10, 6.776), "giro": 90.0, "tam": SILLA_TAM, "fuera": true, "base_y": TERRAZA_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(3.50, 6.776), "giro": -90.0, "tam": SILLA_TAM, "fuera": true, "base_y": TERRAZA_Y},
	{"cosa": "mesa_terraza_verde", "pos": Vector2(5.46, 6.776), "choque": Vector2(14, 14), "fuera": true, "base_y": TERRAZA_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(4.76, 6.776), "giro": 90.0, "tam": SILLA_TAM, "fuera": true, "base_y": TERRAZA_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(6.16, 6.776), "giro": -90.0, "tam": SILLA_TAM, "fuera": true, "base_y": TERRAZA_Y},
	# Comedor principal: 5 mesas con mantel italiano y sus 10 sillas, mostrador de caja, piano vertical y arañas de techo
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-6.02, 1.624), "tam": MESA_TAM, "choque": Vector2(20, 15)},
	{"cosa": "mantel_trattoria", "pos": Vector2(-6.02, 1.624), "base_y": MANTEL_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-6.832, 1.624), "giro": 90.0, "tam": SILLA_TAM},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-5.208, 1.624), "giro": -90.0, "tam": SILLA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-3.50, 1.624), "tam": MESA_TAM, "choque": Vector2(20, 15)},
	{"cosa": "mantel_trattoria", "pos": Vector2(-3.50, 1.624), "base_y": MANTEL_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-4.312, 1.624), "giro": 90.0, "tam": SILLA_TAM},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-2.688, 1.624), "giro": -90.0, "tam": SILLA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-0.70, 1.624), "tam": MESA_TAM, "choque": Vector2(20, 15)},
	{"cosa": "mantel_trattoria", "pos": Vector2(-0.70, 1.624), "base_y": MANTEL_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-1.512, 1.624), "giro": 90.0, "tam": SILLA_TAM},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(0.112, 1.624), "giro": -90.0, "tam": SILLA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(1.82, 1.624), "tam": MESA_TAM, "choque": Vector2(20, 15)},
	{"cosa": "mantel_trattoria", "pos": Vector2(1.82, 1.624), "base_y": MANTEL_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(1.008, 1.624), "giro": 90.0, "tam": SILLA_TAM},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(2.632, 1.624), "giro": -90.0, "tam": SILLA_TAM},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-6.02, 4.088), "tam": MESA_TAM, "choque": Vector2(20, 15)},
	{"cosa": "mantel_trattoria", "pos": Vector2(-6.02, 4.088), "base_y": MANTEL_Y},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-6.832, 4.088), "giro": 90.0, "tam": SILLA_TAM},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-5.208, 4.088), "giro": -90.0, "tam": SILLA_TAM},
	{"modelo": "props/Workbench_Drawers.gltf", "pos": Vector2(0.75, 4.25), "tam": Vector3(1.6, 0.95, 0.62), "choque": Vector2(28, 11)},
	{"cosa": "telefono", "pos": Vector2(1.25, 4.25), "alto": 0.95},
	{"cosa": "piano_vertical", "pos": Vector2(-3.60, -0.42), "choque": Vector2(24, 10)},
	{"modelo": "props/Stool.gltf", "pos": Vector2(-3.60, 0.14), "tam": Vector3(0.45, 0.50, 0.38)},
	{"modelo": "props/Chandelier.gltf", "pos": Vector2(-3.85, 3.35), "tam": Vector3(1.15, 0.68, 1.15), "base_y": 2.35},
	{"modelo": "props/Chandelier.gltf", "pos": Vector2(-1.55, 3.35), "tam": Vector3(1.15, 0.68, 1.15), "base_y": 2.35},
	{"cosa": "lampara", "pos": Vector2(-2.2, 2.4)},
	{"cosa": "retrato", "pos": Vector2(-3.60, -0.82)},
	{"cosa": "retrato", "pos": Vector2(0.10, -0.82)},
	# Cocina: fogones industriales con campana, banco de preparación, fregadero, estanterías y cajas de verdura/fruta
	{"cosa": "fogones_trattoria", "pos": Vector2(7.05, 1.40), "giro": -90.0, "choque": Vector2(28, 14)},
	{"modelo": "props/Workbench.gltf", "pos": Vector2(4.05, 4.10), "giro": 90.0, "tam": Vector3(1.75, 0.90, 0.68), "choque": Vector2(30, 12)},
	{"cosa": "fregadero", "pos": Vector2(6.25, 4.82), "giro": 180.0, "choque": Vector2(18, 10)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(7.35, -0.15), "giro": -90.0, "tam": Vector3(1.1, 1.6, 0.38), "choque": Vector2(19, 7)},
	{"modelo": "props/FarmCrate_Apple.gltf", "pos": Vector2(7.15, 3.35), "tam": Vector3(0.65, 0.45, 0.50), "choque": Vector2(11, 9)},
	{"modelo": "props/FarmCrate_Carrot.gltf", "pos": Vector2(7.15, 4.05), "tam": Vector3(0.65, 0.45, 0.50), "choque": Vector2(11, 9)},
	{"cosa": "bombilla", "pos": Vector2(5.46, 2.24)},
	# Cámara frigorífica (noreste): barra de carnes colgadas, bloques de hielo sobre palé y cajas de conserva
	{"cosa": "camara_fria", "pos": Vector2(5.75, -4.55), "choque": Vector2(36, 12)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(7.10, -2.10), "tam": Vector3(0.72, 0.72, 0.72), "choque": Vector2(12, 12)},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(7.10, -3.10), "tam": Vector3(0.62, 0.92, 0.62), "choque": Vector2(11, 11)},
	{"cosa": "bombilla", "pos": Vector2(5.46, -3.08)},
	# Reservado (noroeste, reuniones nocturnas de La Familia): alfombra carmesí, mesa redonda, 5 sillas, chimenea y cuadro
	{"cosa": "alfombra", "pos": Vector2(-5.32, -3.15), "tam2": Vector2(3.4, 3.0), "color": ALFOMBRA_VINO},
	{"cosa": "mesa_reservado", "pos": Vector2(-5.32, -3.15), "choque": Vector2(18, 18)},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-5.32, -3.95), "giro": 0.0, "tam": SILLA_TAM},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-6.18, -3.40), "giro": 74.0, "tam": SILLA_TAM},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-4.46, -3.40), "giro": -74.0, "tam": SILLA_TAM},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-5.86, -2.46), "giro": 142.0, "tam": SILLA_TAM},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-4.78, -2.46), "giro": -142.0, "tam": SILLA_TAM},
	{"cosa": "chimenea", "pos": Vector2(-7.18, -3.15), "giro": 90.0, "choque": Vector2(16, 26)},
	{"cosa": "retrato", "pos": Vector2(-5.32, -5.26)},
	{"cosa": "lampara", "pos": Vector2(-5.32, -3.15)},
	# Bodega central-norte: botelleros de pared, barricas de roble y cajas de vino
	{"modelo": "props/Shelf_Small_Bottles.gltf", "pos": Vector2(-1.95, -4.95), "tam": Vector3(0.95, 1.55, 0.36), "choque": Vector2(17, 6)},
	{"modelo": "props/Shelf_Small_Bottles.gltf", "pos": Vector2(-0.85, -4.95), "tam": Vector3(0.95, 1.55, 0.36), "choque": Vector2(17, 6)},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(-2.45, -3.85), "tam": Vector3(0.62, 0.92, 0.62), "choque": Vector2(11, 11)},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(-2.45, -2.75), "tam": Vector3(0.62, 0.92, 0.62), "choque": Vector2(11, 11)},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(-0.35, -3.85), "tam": Vector3(0.62, 0.92, 0.62), "choque": Vector2(11, 11)},
	{"cosa": "bombilla", "pos": Vector2(-1.40, -3.08)},
	# Alcoba del dueño y cocinero: dos camas reales (cama_1 y cama_2), mesilla, armario, alfombra y hueco para el cofre
	{"cosa": "alfombra", "pos": Vector2(1.68, -3.20), "tam2": Vector2(2.2, 2.4), "color": ALFOMBRA_DUENO},
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(0.75, -3.95), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(2.60, -3.95), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(1.68, -4.90), "tam": Vector3(0.52, 0.62, 0.40)},
	{"cosa": "vela", "pos": Vector2(1.68, -4.90), "alto": 0.62},
	{"modelo": "props/Cabinet.gltf", "pos": Vector2(0.55, -1.85), "giro": 90.0, "tam": Vector3(0.95, 1.75, 0.48), "choque": Vector2(17, 9)},
	{"cosa": "bombilla", "pos": Vector2(1.68, -2.85)},
]
