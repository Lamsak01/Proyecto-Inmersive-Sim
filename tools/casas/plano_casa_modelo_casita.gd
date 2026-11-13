extends RefCounted

## Plano de la casita de los recién llegados (2026-11-13, interiores de tamaño real): la de quien llega con poco dinero.
## Sala-cocina en medio con la lumbre, dos dormitorios pequeños al oeste, aseo con tina y despensa al este y letrina en
## el patio. De 4,7 × 3,5 m a 9,2 × 6,4 m (lo común: tools/casas/plano_casa_modelo_comun.gd).
## Metros respecto al centro; x hacia el este, z hacia el sur (puerta al sur; en los solares que miran al norte el juego
## la gira). Lo lee tools/casas/construir_casa.gd (por tools/casas/leer_plano.gd).

const Comun = preload("res://tools/casas/plano_casa_modelo_comun.gd")

const ID := "modelo_casita"
const PLANTA_M := Vector2(9.2, 6.4)
const PUERTA_X_M: float = Comun.PUERTA_X_M
const PUERTA_ANCHO_M: float = Comun.PUERTA_ANCHO_M
const VENTANA_X_M: float = 3.4       ## la ventana que se abre y se cierra (muro sur, la de la despensa)
const CARTEL_M := Vector3(1.4, 2.4, 3.42)
const FACHADA: String = Comun.FACHADA
const TABIQUE: String = Comun.TABIQUE
const MADERA: String = Comun.MADERA
const BALDOSA: String = Comun.BALDOSA
const TEJADO: String = Comun.TEJADO
const TEJADO_CHAPA: bool = Comun.TEJADO_CHAPA
const ZOCALO: String = Comun.ZOCALO

const CUARTOS: Array[Dictionary] = [
	{"nombre": "Sala", "centro": Vector2(0.0, 0.0), "tam": Vector2(4.4, 6.4), "central": true, "suelo": BALDOSA},
	{"nombre": "DormitorioMaestro", "centro": Vector2(-3.4, -1.6), "tam": Vector2(2.4, 3.2), "paso": Vector2(-2.2, -0.8), "ancho": 0.8, "hoja": true, "suelo": MADERA},
	{"nombre": "DormitorioFamiliar", "centro": Vector2(-3.4, 1.6), "tam": Vector2(2.4, 3.2), "paso": Vector2(-2.2, 0.8), "ancho": 0.8, "hoja": true, "suelo": MADERA},
	{"nombre": "Aseo", "centro": Vector2(3.4, -1.8), "tam": Vector2(2.4, 2.8), "paso": Vector2(2.2, -1.2), "ancho": 0.8, "hoja": true, "suelo": BALDOSA},
	{"nombre": "Despensa", "centro": Vector2(3.4, 1.4), "tam": Vector2(2.4, 3.6), "paso": Vector2(2.2, 0.6), "ancho": 0.8, "hoja": true, "suelo": BALDOSA},
]

const TABIQUES: Array = [
	[Vector2(-2.2, -3.2), Vector2(-2.2, 3.2)],
	[Vector2(-4.6, 0.0), Vector2(-2.2, 0.0)],
	[Vector2(2.2, -3.2), Vector2(2.2, 3.2)],
	[Vector2(2.2, -0.4), Vector2(4.6, -0.4)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 0.8, "abre": true},
	{"lado": "sur", "en": -3.4, "ancho": 0.8},
	{"lado": "norte", "en": -3.4, "ancho": 0.8},
	{"lado": "norte", "en": 3.4, "ancho": 0.5},
	{"lado": "oeste", "en": -1.6, "ancho": 0.8},
	{"lado": "oeste", "en": 1.6, "ancho": 0.8},
	{"lado": "este", "en": 1.4, "ancho": 0.8},
]

## Muebles («choque» en píxeles del mapa; las camas, de través, con la cabecera al muro oeste).
const MUEBLES: Array[Dictionary] = [
	# Dormitorio del maestro (el cofre lo pone el juego en su marca)
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-3.48, -2.55), "giro": 90.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-4.3, -1.75), "tam": Vector3(0.5, 0.6, 0.4)},
	{"cosa": "vela", "pos": Vector2(-4.3, -1.75), "alto": 0.6},
	# Dormitorio del familiar
	{"modelo": "props/Bed_Twin1.gltf", "pos": Vector2(-3.48, 2.55), "giro": 90.0, "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(-4.3, 1.75), "tam": Vector3(0.5, 0.6, 0.4)},
	{"cosa": "linterna", "pos": Vector2(-4.3, 1.75)},
	# Sala: lumbre con barril y cubo, mesa con bancos y vela, radio de galena junto a la puerta
	{"cosa": "hogar", "pos": Vector2(0.0, -2.67), "choque": Vector2(25, 14)},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(-1.75, -2.7), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
	{"modelo": "props/Bucket_Wooden_1.gltf", "pos": Vector2(-1.75, -2.05), "tam": Vector3(0.4, 0.4, 0.4)},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(0.0, -0.8), "tam": Vector3(1.6, 0.78, 0.9), "choque": Vector2(28, 16)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(0.0, -1.55), "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"modelo": "props/Bench.gltf", "pos": Vector2(0.0, -0.05), "tam": Vector3(1.4, 0.5, 0.45), "choque": Vector2(25, 8)},
	{"cosa": "vela", "pos": Vector2(0.0, -0.8), "alto": 0.78},
	{"cosa": "radio_galena", "pos": Vector2(-1.9, 2.85), "choque": Vector2(7, 7)},
	# Aseo: tina, palangana y cubo
	{"cosa": "tina", "pos": Vector2(3.6, -2.3), "choque": Vector2(19, 19)},
	{"cosa": "palangana", "pos": Vector2(4.25, -0.8), "choque": Vector2(7, 7)},
	{"modelo": "props/Bucket_Wooden_1.gltf", "pos": Vector2(2.6, -2.9), "tam": Vector3(0.4, 0.4, 0.4)},
	# Despensa: saco, barril, caja y estante
	{"modelo": "props/Bag.gltf", "pos": Vector2(4.2, 0.3), "tam": Vector3(0.6, 0.7, 0.5), "choque": Vector2(10, 9)},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(4.2, 1.3), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(10, 10)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(4.1, 2.6), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
	{"modelo": "props/Shelf_Simple.gltf", "pos": Vector2(3.0, 3.0), "tam": Vector3(1.0, 1.5, 0.35), "choque": Vector2(18, 6)},
	# Patio trasero: la letrina
	{"cosa": "letrina", "pos": Vector2(3.4, -5.0), "choque": Vector2(22, 22), "fuera": true},
]

## Marcas (mapa/marca.gd): camas, cofre, sitio para comer, puerta y ventana; en la sala, los muebles de la casa del
## jugador (mesa_comedor, escondite, escalera, mostrador_casa, banco_casa) y las camas del altillo.
const MARCAS: Dictionary = {
	"cama_1": Vector2(-3.48, -2.55),
	"cama_2": Vector2(-3.48, 2.55),
	"cofre": Vector2(-4.25, -0.45),
	"mesa": Vector2(-0.9, 0.6),
	"mesa_comedor": Vector2(0.0, -0.8),
	"escondite": Vector2(1.55, -0.8),
	"escalera": Vector2(1.6, -2.5),
	"mostrador_casa": Vector2(-1.3, 2.5),
	"banco_casa": Vector2(1.4, 2.55),
	"cama_alta_1": Vector2(-1.0, 1.6),
	"cama_alta_2": Vector2(1.0, 1.6),
	"puerta": Vector2(PUERTA_X_M, 3.2),
	"ventana": Vector2(VENTANA_X_M, 3.2),
}
