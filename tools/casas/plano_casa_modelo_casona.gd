extends RefCounted

## Plano de la casona de los recién llegados (2026-11-13, interiores de tamaño real): la de quien llega con más dinero,
## para tres. Sala-cocina en medio con la lumbre, dos dormitorios al oeste; al este, aseo con tina, despensa y el
## tercer dormitorio; letrina en el patio. De 6,9 × 5 m a 12,6 × 9 m (lo común: tools/casas/plano_casa_modelo_comun.gd).
## Metros respecto al centro; x hacia el este, z hacia el sur (puerta al sur; en los solares que miran al norte el juego
## la gira). Lo lee tools/casas/construir_casa.gd (por tools/casas/leer_plano.gd).

const Comun = preload("res://tools/casas/plano_casa_modelo_comun.gd")

const ID := "modelo_casona"
const PLANTA_M := Vector2(12.6, 9.0)
const PUERTA_X_M: float = Comun.PUERTA_X_M
const PUERTA_ANCHO_M: float = Comun.PUERTA_ANCHO_M
const VENTANA_X_M: float = 4.25      ## la ventana que se abre y se cierra (muro sur, la del tercer dormitorio)
const CARTEL_M := Vector3(1.4, 2.4, 4.72)
const FACHADA: String = Comun.FACHADA
const TABIQUE: String = Comun.TABIQUE
const MADERA: String = Comun.MADERA
const BALDOSA: String = Comun.BALDOSA
const TEJADO: String = Comun.TEJADO
const TEJADO_CHAPA: bool = Comun.TEJADO_CHAPA
const ZOCALO: String = Comun.ZOCALO

const CUARTOS: Array[Dictionary] = [
	{"nombre": "Sala", "centro": Vector2(0.0, 0.0), "tam": Vector2(4.4, 9.0), "central": true, "suelo": BALDOSA},
	{"nombre": "DormitorioMaestro", "centro": Vector2(-4.25, -2.25), "tam": Vector2(4.1, 4.5), "paso": Vector2(-2.2, -1.0), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	{"nombre": "DormitorioFamiliar", "centro": Vector2(-4.25, 2.25), "tam": Vector2(4.1, 4.5), "paso": Vector2(-2.2, 1.0), "ancho": 0.9, "hoja": true, "suelo": MADERA},
	{"nombre": "Aseo", "centro": Vector2(4.25, -3.25), "tam": Vector2(4.1, 2.5), "paso": Vector2(2.2, -2.6), "ancho": 0.9, "hoja": true, "suelo": BALDOSA},
	{"nombre": "Despensa", "centro": Vector2(4.25, -1.0), "tam": Vector2(4.1, 2.0), "paso": Vector2(2.2, -1.0), "ancho": 0.9, "hoja": true, "suelo": BALDOSA},
	{"nombre": "DormitorioTercero", "centro": Vector2(4.25, 2.25), "tam": Vector2(4.1, 4.5), "paso": Vector2(2.2, 1.0), "ancho": 0.9, "hoja": true, "suelo": MADERA},
]

const TABIQUES: Array = [
	[Vector2(-2.2, -4.5), Vector2(-2.2, 4.5)],
	[Vector2(-6.3, 0.0), Vector2(-2.2, 0.0)],
	[Vector2(2.2, -4.5), Vector2(2.2, 4.5)],
	[Vector2(2.2, 0.0), Vector2(6.3, 0.0)],
	[Vector2(2.2, -2.0), Vector2(6.3, -2.0)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.0, "abre": true},
	{"lado": "sur", "en": -4.25, "ancho": 1.0},
	{"lado": "norte", "en": -4.25, "ancho": 1.0},
	{"lado": "norte", "en": 4.25, "ancho": 0.6},
	{"lado": "oeste", "en": -2.25, "ancho": 1.0},
	{"lado": "oeste", "en": 2.25, "ancho": 1.0},
	{"lado": "este", "en": -1.0, "ancho": 0.6},
	{"lado": "este", "en": 2.25, "ancho": 1.0},
]

## Muebles («choque» en píxeles del mapa; 0, 0 = se atraviesa).
const MUEBLES: Array[Dictionary] = [
	# Dormitorio del maestro (el cofre lo pone el juego en su marca): cama, mesilla con vela y linterna de dinamo
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-5.35, -3.37), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-4.4, -4.15), "tam": Vector3(0.5, 0.6, 0.4)},
	{"cosa": "vela", "pos": Vector2(-4.4, -4.15), "alto": 0.6},
	{"cosa": "linterna", "pos": Vector2(-3.5, -4.25)},
	# Dormitorio del familiar: cama, mesilla con vela y estante
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-5.35, 3.37), "giro": 180.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-4.4, 4.15), "tam": Vector3(0.5, 0.6, 0.4)},
	{"cosa": "vela", "pos": Vector2(-4.4, 4.15), "alto": 0.6},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(-3.1, 4.2), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	# Tercer dormitorio: cama, mesilla con vela y taburete
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(5.35, 3.37), "giro": 180.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(4.4, 4.15), "tam": Vector3(0.5, 0.6, 0.4)},
	{"cosa": "vela", "pos": Vector2(4.4, 4.15), "alto": 0.6},
	{"modelo": "props/Stool.gltf", "pos": Vector2(5.6, 1.0), "tam": Vector3(0.4, 0.5, 0.4)},
	# Sala: lumbre con leña, barril y cubo, mesa con bancos y vela, radio de galena junto a la puerta
	{"cosa": "hogar", "pos": Vector2(0.0, -3.97), "choque": Vector2(25, 14)},
	{"cosa": "lena", "pos": Vector2(1.3, -4.05)},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(-1.75, -4.0), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
	{"modelo": "props/Bucket_Wooden_1.gltf", "pos": Vector2(-1.75, -3.35), "tam": Vector3(0.4, 0.4, 0.4)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(0.0, -1.8), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(0.0, -2.55), "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(0.0, -1.05), "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"cosa": "vela", "pos": Vector2(0.0, -1.8), "alto": 0.78},
	{"cosa": "radio_galena", "pos": Vector2(-1.9, 4.15), "choque": Vector2(7, 7)},
	# Aseo: tina, palangana y cubo
	{"cosa": "tina", "pos": Vector2(5.4, -3.3), "choque": Vector2(19, 19)},
	{"cosa": "palangana", "pos": Vector2(2.7, -4.15), "choque": Vector2(7, 7)},
	{"modelo": "props/Bucket_Wooden_1.gltf", "pos": Vector2(3.6, -4.2), "tam": Vector3(0.4, 0.4, 0.4)},
	# Despensa: sacos, barril y caja
	{"modelo": "props/Bag.gltf", "pos": Vector2(5.8, -1.5), "tam": Vector3(0.6, 0.7, 0.5), "choque": Vector2(10, 9)},
	{"modelo": "props/Bag.gltf", "pos": Vector2(5.8, -0.55), "tam": Vector3(0.6, 0.7, 0.5), "choque": Vector2(10, 9)},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(4.9, -1.55), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(4.0, -1.55), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
	# Patio trasero: la letrina
	{"cosa": "letrina", "pos": Vector2(4.25, -6.3), "choque": Vector2(22, 22), "fuera": true},
]

## Marcas (mapa/marca.gd): camas, cofre, sitio para comer, puerta y ventana; en la sala, los muebles de la casa del
## jugador (mesa_comedor, escondite, escalera, mostrador_casa, banco_casa) y las camas del altillo.
const MARCAS: Dictionary = {
	"cama_1": Vector2(-5.35, -3.37),
	"cama_2": Vector2(-5.35, 3.37),
	"cama_3": Vector2(5.35, 3.37),
	"cofre": Vector2(-5.35, -1.5),
	"mesa": Vector2(0.0, -0.4),
	"mesa_comedor": Vector2(0.0, -1.8),
	"escondite": Vector2(1.55, -1.8),
	"escalera": Vector2(-1.6, -2.6),
	"mostrador_casa": Vector2(-1.3, 3.8),
	"banco_casa": Vector2(1.4, 3.85),
	"cama_alta_1": Vector2(-1.1, 2.0),
	"cama_alta_2": Vector2(1.1, 2.0),
	"puerta": Vector2(PUERTA_X_M, 4.5),
	"ventana": Vector2(VENTANA_X_M, 4.5),
}
