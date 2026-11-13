extends RefCounted

## Plano del Molino Viejo Abandonado (Caso I, 2026-11-13, interiores de tamaño real). Una ruina sin luz: piedra, suelo
## de tablas rotas y techo de paja. La sala de la puerta con el foso del sótano (su reja da al canal de la rueda, al
## oeste), el banco del cordel, la mesa con el papel y las muelas rotas; al fondo, por un hueco del tabique, el granero
## con el pajar y el hogar frío donde esperan los dos forasteros. De 6,9 × 5,2 m a 14 × 9,8 m: el muro de la puerta y el
## del oeste siguen donde estaban (la rueda, el canal y el barro rojo no se mueven); crece al norte y al este.
## Metros respecto al centro; x hacia el este, z hacia el sur (puerta al sur). Lo lee tools/casas/construir_casa.gd.

const ID := "building_abandoned_mill"
const PLANTA_M := Vector2(14.0, 9.8)
const PUERTA_X_M: float = -3.528     ## donde estaba la puerta: delante quedan el barro rojo y la pista del claro
const PUERTA_ANCHO_M: float = 2.2    ## portón de carro
const VENTANA_X_M: float = -5.7      ## la ventana que se abre y se cierra
const CARTEL_M := Vector3(-1.8, 2.4, 5.12)

const FACHADA := "wall_stone.png"
const TABIQUE := "wall_timber.png"
const MADERA := "floor_wood_planks_wide_damaged.png"
const TIERRA := "floor_ground_dirt.png"   ## el granero: suelo de tierra
const TEJADO := "roof_thatch_center.png"
const ZOCALO := "wall_stone.png"

const MESA_ALTO_M: float = 0.78
const BANCO_ALTO_M: float = 0.9
const TABIQUE_Z_M: float = -1.6
const HUECO_ANCHO_M: float = 2.0     ## el hueco del tabique entre la sala y el granero (sin puerta: se cayó)
const BARRO_ROJO := Color(0.72, 0.36, 0.3)   ## la arcilla roja con pisadas (Caso I): fuera, junto a la puerta y al muro de la rueda
const PAJA_TAM := Vector3(1.2, 0.9, 0.9)
const PAJA_CHOQUE := Vector2(21, 16)

const CUARTOS: Array[Dictionary] = [
	{"nombre": "Sala", "centro": Vector2(0.0, 1.65), "tam": Vector2(14.0, 6.5), "central": true, "suelo": MADERA},
	{"nombre": "Granero", "centro": Vector2(0.0, -3.25), "tam": Vector2(14.0, 3.3), "paso": Vector2(PUERTA_X_M, TABIQUE_Z_M), "ancho": HUECO_ANCHO_M, "suelo": TIERRA},
]

const TABIQUES: Array = [
	[Vector2(-7.0, TABIQUE_Z_M), Vector2(7.0, TABIQUE_Z_M)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.0, "abre": true},
	{"lado": "sur", "en": 3.0, "ancho": 0.8},
	{"lado": "norte", "en": -2.0, "ancho": 0.6},
	{"lado": "norte", "en": 4.5, "ancho": 0.6},
	{"lado": "este", "en": -3.2, "ancho": 0.6},
	{"lado": "este", "en": 1.6, "ancho": 0.8},
	{"lado": "oeste", "en": 3.2, "ancho": 0.6},
]

const MUEBLES: Array[Dictionary] = [
	# Granero: el pajar (noroeste), el hogar frío con la ceniza y su leña (norte), la paja donde duermen los forasteros,
	# y sacos, barril y caja del viejo grano (este)
	{"modelo": "exterior/Hay.obj", "pos": Vector2(-6.1, -4.2), "tam": PAJA_TAM, "choque": PAJA_CHOQUE},
	{"modelo": "exterior/Hay.obj", "pos": Vector2(-4.8, -4.3), "giro": 20.0, "tam": PAJA_TAM, "choque": PAJA_CHOQUE},
	{"cosa": "hogar_frio", "pos": Vector2(1.5, -4.45), "choque": Vector2(25, 14)},
	{"cosa": "lena", "pos": Vector2(2.75, -4.55), "choque": Vector2(12, 6)},
	{"modelo": "exterior/Hay.obj", "pos": Vector2(4.2, -4.3), "giro": 90.0, "tam": PAJA_TAM, "choque": Vector2(16, 21)},
	{"modelo": "exterior/Bags.obj", "pos": Vector2(6.1, -4.2), "tam": Vector3(1.0, 0.7, 0.8), "choque": Vector2(18, 14)},
	{"modelo": "props/Barrel.gltf", "pos": Vector2(6.4, -2.3), "tam": Vector3(0.6, 0.9, 0.6), "choque": Vector2(11, 11)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(5.4, -2.3), "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
	# Sala: el foso del sótano junto al muro de la rueda, el banco con el cordel (suroeste), la mesa con el papel y la vela
	# de los forasteros, las muelas rotas y escombros
	{"cosa": "foso_reja", "pos": Vector2(-6.2, 0.2)},
	{"modelo": "props/Workbench.gltf", "pos": Vector2(-6.5, 3.4), "giro": 90.0, "tam": Vector3(1.6, BANCO_ALTO_M, 0.7), "choque": Vector2(12, 28)},
	{"cosa": "cordel", "pos": Vector2(-6.5, 3.2), "alto": BANCO_ALTO_M},
	{"modelo": "props/Table_Large.gltf", "pos": Vector2(-0.5, 2.6), "tam": Vector3(1.6, MESA_ALTO_M, 0.9), "choque": Vector2(28, 16)},
	{"cosa": "papel", "pos": Vector2(-0.3, 2.6), "alto": MESA_ALTO_M},
	{"cosa": "vela", "pos": Vector2(-1.0, 2.45), "alto": MESA_ALTO_M},
	{"modelo": "props/Chair_1.gltf", "pos": Vector2(-0.5, 3.4), "giro": 180.0, "tam": Vector3(0.45, 0.95, 0.45)},
	{"cosa": "muela_rota", "pos": Vector2(3.4, 0.6), "choque": Vector2(36, 20)},
	{"cosa": "muela_rota", "pos": Vector2(4.6, 3.6), "giro": 140.0, "choque": Vector2(30, 30)},
	{"modelo": "exterior/Rock_1.obj", "pos": Vector2(6.2, -0.6), "tam": Vector3(0.8, 0.5, 0.7), "choque": Vector2(14, 12)},
	{"modelo": "props/Crate_Wooden.gltf", "pos": Vector2(1.6, 4.3), "giro": 25.0, "tam": Vector3(0.7, 0.7, 0.7), "choque": Vector2(12, 12)},
	# Fuera: el barro rojo de la orilla, donde estaba (lo pisaron los secuestradores; su sitio es «barro_rojo_molino»)
	{"cosa": "alfombra", "pos": Vector2(-6.4, 5.45), "giro": -8.0, "tam2": Vector2(2.9, 0.9), "color": BARRO_ROJO, "fuera": true},
	{"cosa": "alfombra", "pos": Vector2(-7.55, 2.9), "giro": 4.0, "tam2": Vector2(0.7, 2.6), "color": BARRO_ROJO, "fuera": true},
]

const MARCAS: Dictionary = {
	"pajar": Vector2(-5.4, -4.2),
	"hogar": Vector2(1.5, -4.45),
	"cordel": Vector2(-6.5, 3.2),
	"mesa_papel": Vector2(-0.5, 2.6),
	"sotano": Vector2(-6.2, 0.2),
	"secuestrador_young": Vector2(2.6, -3.2),
	"secuestrador_driver": Vector2(0.4, -3.2),
	"puerta": Vector2(PUERTA_X_M, 4.9),
	"ventana": Vector2(VENTANA_X_M, 4.9),
}
