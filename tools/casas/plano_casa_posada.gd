extends RefCounted

## Plano de la «Posada Humilde» de la familia Candil (2026-11-13, interiores de tamaño real): la misma casa-taller de
## artesano (tools/casas/plano_casa_artesano_taller.gd, nivel 2) con el cuarto del fondo hecho alcoba de huéspedes: dos
## camas para los forasteros que pagan la noche, mesilla con quinqué y un arcón. Se alquila en el mostrador de la sala.
## Metros respecto al centro de la casa; x hacia el este, z hacia el sur (la puerta de la calle da al sur).
## Lo lee tools/casas/construir_casa.gd (por tools/casas/leer_plano.gd), que rehace la escena del edificio.

const Base = preload("res://tools/casas/plano_casa_artesano_taller.gd")

const ID := "mixed_family_candil"
const PLANTA_M: Vector2 = Base.PLANTA_M
const PUERTA_X_M: float = Base.PUERTA_X_M
const PUERTA_ANCHO_M: float = Base.PUERTA_ANCHO_M
const VENTANA_X_M: float = Base.VENTANA_X_M
const CARTEL_M: Vector3 = Base.CARTEL_M
const FACHADA: String = Base.FACHADA
const TABIQUE: String = Base.TABIQUE
const MADERA: String = Base.MADERA
const BALDOSA: String = Base.BALDOSA
const TEJADO: String = Base.TEJADO
const ZOCALO: String = Base.ZOCALO
const CUARTOS: Array[Dictionary] = Base.CUARTOS     ## el «Taller» de la base es aquí la alcoba de huéspedes
const TABIQUES: Array = Base.TABIQUES
const VENTANAS: Array[Dictionary] = Base.VENTANAS

## La casa de la base y, en el cuarto del fondo, la alcoba de huéspedes.
const MUEBLES: Array[Dictionary] = Base.MUEBLES_CASA + ALCOBA_HUESPEDES

const ALCOBA_HUESPEDES: Array[Dictionary] = [
	{"modelo": "props/Bed_Twin2.gltf", "pos": Vector2(5.8, -0.3), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Bed_Twin2.gltf", "pos": Vector2(5.8, 3.3), "tam": Vector3(0.95, 0.9, 2.0)},
	{"modelo": "props/Nightstand_Shelf.gltf", "pos": Vector2(5.95, 1.5), "tam": Vector3(0.5, 0.6, 0.4)},
	{"cosa": "vela", "pos": Vector2(5.95, 1.5), "alto": 0.6},
	{"modelo": "props/Chest_Wood.gltf", "pos": Vector2(3.0, 4.0), "tam": Vector3(0.8, 0.5, 0.45), "choque": Vector2(14, 8)},
	{"modelo": "props/Stool.gltf", "pos": Vector2(2.6, -1.0), "tam": Vector3(0.4, 0.5, 0.4)},
	{"cosa": "bombilla", "pos": Vector2(4.15, 1.5)},
]

## Marcas que lee la lógica (mapa/marca.gd): el posadero atiende en el mostrador y su familiar recibe a la entrada.
const MARCAS: Dictionary = {
	"trabajo": Vector2(1.8, 2.8),
	"trabajo_familiar": Vector2(-1.0, 2.8),
	"puesto": Vector2(0.8, 2.8),
	"cama_1": Vector2(-5.45, -3.3),
	"cama_2": Vector2(-5.45, 3.3),
	"cama_huesped_1": Vector2(5.8, -0.3),
	"cama_huesped_2": Vector2(5.8, 3.3),
	"mesa": Vector2(0.0, -0.8),
	"cofre": Vector2(-5.45, -1.75),
	"puerta": Vector2(PUERTA_X_M, 4.5),
	"ventana": Vector2(VENTANA_X_M, 4.5),
}
