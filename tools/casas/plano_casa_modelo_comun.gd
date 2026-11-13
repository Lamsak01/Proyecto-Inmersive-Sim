extends RefCounted

## Lo común de las tres casas modelo de los recién llegados (2026-11-13, interiores de tamaño real; mapa/casa_modelo.gd):
## nivel 1, pobre (lumbre, velas, tina, letrina, linterna de dinamo, radio de galena y tejado de chapa), con la sala en
## medio, de x −2,2 a 2,2 m. En la sala van también las marcas de lo que el juego pone si la casa es del jugador (mesa,
## banco, escondite, escalera del altillo y mostrador: scripts/systems/VillageHousing.gd, home_prop_pos) y las dos camas
## del altillo, que está encima de la sala. Lo leen los planos de cada tamaño (tools/casas/plano_casa_modelo_*.gd).

const FACHADA := "wall_timber.png"
const TABIQUE := "wall_timber.png"
const MADERA := "floor_wood_planks_damaged.png"
const BALDOSA := "floor_ground_dirt.png"
const TEJADO := ""
const TEJADO_CHAPA: bool = true
const ZOCALO := "wall_stone.png"

const PUERTA_X_M: float = 0.0     ## la puerta de la calle, en medio del muro sur (da a la sala)
const PUERTA_ANCHO_M: float = 1.4
