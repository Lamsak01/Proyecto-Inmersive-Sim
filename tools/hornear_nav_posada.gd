extends RefCounted

## Geometría específica de la posada (building_tavern) para hornear su NavigationMesh:
## planta alta en galería, escalera interior, tres alcobas con puerta y mobiliario fijo de obra.

const C = preload("res://tools/hornear_nav_comun.gd")

const GALERIA_Z: float = 3.248
const HUECO_RECT := Rect2(Vector2(6.944, -4.144), Vector2(2.800, 5.376))
const ESC_PIE := Vector2(7.952, -3.360)
const ESC_CIMA := Vector2(7.952, 1.232)
const ESC_ANCHO_M: float = 1.568
const CUARTOS_Z: float = 0.448
const PUERTAS_X: Array[float] = [-6.496, 0.0, 5.096]
const PUERTA_ANCHO_M: float = 1.120
const DIVISORIAS_X: Array[float] = [-3.248, 3.248]
const COFRE_ALTO := Vector2(-3.864, -4.256)
const FIJOS_BAJOS: Dictionary = {
	"barra": Vector2(5.376, 0.560),
	"chimenea": Vector2(0.672, 1.568),
	"fogones": Vector2(1.344, 0.616),
	"toneles": Vector2(2.912, 0.560),
	"poker": Vector2(0.784, 0.560),
	"billar": Vector2(1.456, 0.896),
	"pasaplatos": Vector2(0.784, 0.560),
}


static func armar_posada(
	fuente: NavigationMeshSourceGeometryData3D,
	planta: Vector2,
	marcas: Dictionary,
	y_bajo: float,
	y_alto: float
) -> void:
	var m: Vector2 = planta * 0.5
	var base_alta := Rect2(Vector2(-m.x, -m.y), Vector2(planta.x, GALERIA_Z + m.y))
	for r: Rect2 in C.restar_rect(base_alta, HUECO_RECT):
		C.agregar_losa(fuente, r.get_center(), r.size, y_alto)
	C.agregar_rampa(fuente, ESC_PIE - Vector2(0.0, 0.08), y_bajo, ESC_CIMA + Vector2(0.0, 0.08), y_alto, ESC_ANCHO_M)
	C.agregar_muro_tramo(fuente, Vector2(-m.x, GALERIA_Z - 0.11), Vector2(m.x, GALERIA_Z - 0.11), y_alto, 1.2, 0.30)
	C.agregar_muro_tramo(fuente, Vector2(6.944, -5.152), Vector2(6.944, 1.008), y_alto, 1.2, 0.30)
	C.agregar_muro_tramo(fuente, Vector2(6.944, -4.144), Vector2(m.x, -4.144), y_alto, 1.2, 0.30)
	var x_cur: float = -9.520
	for px: float in PUERTAS_X:
		var fin: float = px - PUERTA_ANCHO_M * 0.5
		C.agregar_muro_tramo(fuente, Vector2(x_cur, CUARTOS_Z), Vector2(fin, CUARTOS_Z), y_alto, 2.6, 0.25)
		x_cur = px + PUERTA_ANCHO_M * 0.5
	C.agregar_muro_tramo(fuente, Vector2(x_cur, CUARTOS_Z), Vector2(6.944, CUARTOS_Z), y_alto, 2.6, 0.25)
	for dx: float in DIVISORIAS_X:
		C.agregar_muro_tramo(fuente, Vector2(dx, -5.08), Vector2(dx, CUARTOS_Z), y_alto, 2.6, 0.25)
	var tc: Vector2 = C.encoger_mueble(Vector2(0.68, 0.48))
	C.agregar_caja(fuente, Vector3(COFRE_ALTO.x, y_alto + 0.5, COFRE_ALTO.y), Vector3(tc.x, 1.0, tc.y))
	for marca_fija: String in FIJOS_BAJOS:
		if not marcas.has(marca_fija):
			continue
		var tf: Vector2 = C.encoger_mueble(FIJOS_BAJOS[marca_fija])
		var pf: Vector2 = marcas[marca_fija]
		C.agregar_caja(fuente, Vector3(pf.x, y_bajo + 0.6, pf.y), Vector3(tf.x, 1.2, tf.y))
