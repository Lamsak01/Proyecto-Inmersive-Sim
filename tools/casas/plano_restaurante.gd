extends RefCounted

## Plano de la Casa de Comidas «El Fogón del Valle» / Trattoria «Il Corvo» (2026-11-14, interiores de tamaño real,
## Tarea 4). Planta de 15,4 × 10,64 m con terraza empedrada al sur, comedor principal, cocina con campana, cámara fría,
## reservado de La Familia, bodega y alcoba con dos camas reales. Los seis recintos y sus pasos coinciden al milímetro
## con VillageRestaurant.ROOMS y OPENINGS; llevan «solo_suelo» para que VillageRestaurant.route enrute la cadena de dos
## pasos Comedor ↔ Cocina ↔ Cámara mientras el constructor corta los huecos y coloca las hojas batientes de los cuartos.

const MueblesRestaurante = preload("res://tools/casas/plano_restaurante_muebles.gd")

const ID := "building_restaurant"
const PLANTA_M := Vector2(15.4, 10.64)
const PUERTA_X_M: float = -2.1
const PUERTA_ANCHO_M: float = 1.8
const VENTANA_X_M: float = -5.2
const CARTEL_M := Vector3(-0.72, 1.82, 5.48)

const FACHADA := "wall_brick_sand_center.png"
const TABIQUE := "wall_brick_small_sand.png"
const MADERA := "floor_wood_planks_wide.png"
const MADERA_BODEGA := "floor_wood_planks_damaged.png"
const BALDOSA := "floor_tiles_tan_large.png"
const BALDOSA_COCINA := "floor_tiles_sand_small.png"
const LOSA_CAMARA := "floor_tiles_blue_small.png"
const TEJADO := "roof_clay_red_center.png"
const ZOCALO := "wall_stone.png"

const CUARTOS: Array[Dictionary] = [
	{"nombre": "Comedor", "centro": Vector2(-2.24, 2.24), "tam": Vector2(10.92, 6.16), "solo_suelo": true, "suelo": BALDOSA},
	{"nombre": "Cocina", "centro": Vector2(5.46, 2.24), "tam": Vector2(4.48, 6.16), "paso": Vector2(3.22, 2.296), "ancho": 1.5, "hoja": false, "solo_suelo": true, "suelo": BALDOSA_COCINA},
	{"nombre": "Camara", "centro": Vector2(5.46, -3.08), "tam": Vector2(4.48, 4.48), "paso": Vector2(5.292, -0.84), "ancho": 1.25, "hoja": true, "solo_suelo": true, "suelo": LOSA_CAMARA},
	{"nombre": "Reservado", "centro": Vector2(-5.32, -3.08), "tam": Vector2(4.76, 4.48), "paso": Vector2(-5.684, -0.84), "ancho": 1.2, "hoja": true, "solo_suelo": true, "suelo": MADERA},
	{"nombre": "Bodega", "centro": Vector2(-1.40, -3.08), "tam": Vector2(3.08, 4.48), "paso": Vector2(-1.54, -0.84), "ancho": 1.2, "hoja": true, "solo_suelo": true, "suelo": MADERA_BODEGA},
	{"nombre": "Dueno", "centro": Vector2(1.68, -3.08), "tam": Vector2(3.08, 4.48), "paso": Vector2(1.652, -0.84), "ancho": 1.2, "hoja": true, "solo_suelo": true, "suelo": MADERA},
]

const TABIQUES: Array = [
	[Vector2(-7.70, -0.84), Vector2(3.22, -0.84)],
	[Vector2(3.22, -0.84), Vector2(7.70, -0.84)],
	[Vector2(3.22, -5.32), Vector2(3.22, 5.32)],
	[Vector2(-2.94, -5.32), Vector2(-2.94, -0.84)],
	[Vector2(0.14, -5.32), Vector2(0.14, -0.84)],
]

const VENTANAS: Array[Dictionary] = [
	{"lado": "sur", "en": VENTANA_X_M, "ancho": 1.3, "abre": true},
	{"lado": "sur", "en": 1.1, "ancho": 1.3},
	{"lado": "sur", "en": 5.4, "ancho": 1.1},
	{"lado": "oeste", "en": 2.2, "ancho": 1.2},
	{"lado": "oeste", "en": -1.6, "ancho": 0.9},
	{"lado": "este", "en": 2.6, "ancho": 1.1},
	{"lado": "norte", "en": -3.2, "ancho": 0.9},
	{"lado": "norte", "en": 1.68, "ancho": 1.0},
]

const MUEBLES: Array[Dictionary] = MueblesRestaurante.MUEBLES

const MARCAS: Dictionary = {
	"fogones": Vector2(6.10, 1.40),
	"encimera": Vector2(4.90, 4.10),
	"colgadero": Vector2(5.35, -3.15),
	"puesto": Vector2(0.75, 3.45),
	"piano": Vector2(-3.60, 0.35),
	"mesa_reservado": Vector2(-5.32, -3.15),
	"cama_1": Vector2(0.75, -3.95),
	"cama_2": Vector2(2.60, -3.95),
	"cofre": Vector2(2.62, -1.85),
	"botellero": Vector2(-1.40, -3.55),
	"mesa_1": Vector2(-6.02, 1.624),
	"mesa_2": Vector2(-3.50, 1.624),
	"mesa_3": Vector2(-0.70, 1.624),
	"mesa_4": Vector2(1.82, 1.624),
	"mesa_5": Vector2(-6.02, 4.088),
	"mesa_terraza_1": Vector2(-6.30, 6.776),
	"mesa_terraza_2": Vector2(-3.78, 6.776),
	"mesa_terraza_3": Vector2(0.28, 6.776),
	"mesa_terraza_4": Vector2(2.80, 6.776),
	"mesa_terraza_5": Vector2(5.46, 6.776),
	"puerta": Vector2(PUERTA_X_M, 5.32),
	"ventana": Vector2(VENTANA_X_M, 5.32),
	"terraza": Vector2(-1.90, 6.776),
	"comedor": Vector2(-2.10, 2.85),
}
