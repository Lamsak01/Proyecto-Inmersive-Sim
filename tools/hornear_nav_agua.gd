extends RefCounted

## Genera por sector la malla pisable del relieve exterior excluyendo agua honda (río, lago y ciénaga)
## y tendiendo pasarelas y rampas continuas en los 6 pasos del río y el muelle de madera del lago.

const C = preload("res://tools/hornear_nav_comun.gd")
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Agua = preload("res://scripts/fisica/Agua.gd")
const RioLago = preload("res://scripts/fisica/RioLago.gd")
const Base3D = preload("res://scripts/visuals/WorldStageBase3D.gd")
const Terreno3D = preload("res://scripts/visuals/WorldStageTerrain3D.gd")

const PASO_GRUESO_M: float = 3.36
const SUBDIV_AGUA: int = 3
const MARGEN_RIO_M: float = 5.50


static func cota_suelo_m(xz_m: Vector2) -> float:
	var p: Vector2 = Mapa3D.a_mapa(Vector3(xz_m.x, 0.0, xz_m.y))
	return Mapa3D.alto_a_3d(Base3D.terrain_height_px(p) + Base3D.surface_elevation_offset_px(p))


static func preparar_datos_agua() -> Dictionary:
	var cienaga: PackedVector2Array = Terreno3D.agua_cienaga_mundo()
	var lago: PackedVector2Array = RioLago.lake_water_world()
	return {
		"cienaga": cienaga,
		"caja_cienaga": _caja_poligono_m(cienaga, 4.0),
		"caja_lago": _caja_poligono_m(lago, 4.0),
		"muelle": Agua.muelle_lago_mundo(),
		"cruces": RioLago.river_crossings(),
	}


static func agregar_terreno_sector(fuente: NavigationMeshSourceGeometryData3D, rect_m: Rect2, agua: Dictionary) -> Vector2:
	var caras := PackedVector3Array()
	var cotas: Dictionary = {}
	var rango_y := Vector2(INF, -INF)
	var expandido: Rect2 = rect_m.grow(PASO_GRUESO_M)
	var gx0: int = int(floor(expandido.position.x / PASO_GRUESO_M))
	var gx1: int = int(ceil(expandido.end.x / PASO_GRUESO_M))
	var gz0: int = int(floor(expandido.position.y / PASO_GRUESO_M))
	var gz1: int = int(ceil(expandido.end.y / PASO_GRUESO_M))
	var cienaga: PackedVector2Array = agua["cienaga"]
	var caja_cienaga: Rect2 = agua["caja_cienaga"]
	var caja_lago: Rect2 = agua["caja_lago"]
	for gz: int in range(gz0, gz1):
		var z0: float = float(gz) * PASO_GRUESO_M
		for gx: int in range(gx0, gx1):
			var x0: float = float(gx) * PASO_GRUESO_M
			var celda := Rect2(Vector2(x0, z0), Vector2(PASO_GRUESO_M, PASO_GRUESO_M))
			var fino: bool = _cerca_de_rio(celda) or caja_lago.intersects(celda) or caja_cienaga.intersects(celda)
			var n: int = SUBDIV_AGUA if fino else 1
			var paso: float = PASO_GRUESO_M / float(n)
			for sz: int in range(n):
				for sx: int in range(n):
					rango_y = _intentar_cuadro(caras, cotas, rango_y, x0 + float(sx) * paso, z0 + float(sz) * paso, paso, cienaga, fino)
	if not caras.is_empty():
		fuente.add_faces(caras, Transform3D.IDENTITY)
	_agregar_cruces_y_muelle(fuente, expandido, agua)
	return Vector2(-2.0, 4.0) if rango_y.x > rango_y.y else rango_y


static func _cota_cache(cotas: Dictionary, x_m: float, z_m: float) -> float:
	var clave := Vector2i(int(roundf(x_m * 100.0)), int(roundf(z_m * 100.0)))
	if not cotas.has(clave):
		cotas[clave] = cota_suelo_m(Vector2(x_m, z_m))
	return float(cotas[clave])


static func _intentar_cuadro(caras: PackedVector3Array, cotas: Dictionary, ry: Vector2, x0: float, z0: float, paso: float, cienaga: PackedVector2Array, revisar_agua: bool) -> Vector2:
	if revisar_agua:
		for muestra: Vector2 in [
			Vector2(x0 + paso * 0.5, z0 + paso * 0.5),
			Vector2(x0 + paso * 0.15, z0 + paso * 0.15), Vector2(x0 + paso * 0.85, z0 + paso * 0.15),
			Vector2(x0 + paso * 0.15, z0 + paso * 0.85), Vector2(x0 + paso * 0.85, z0 + paso * 0.85),
		]:
			var pm: Vector2 = Mapa3D.a_mapa(Vector3(muestra.x, 0.0, muestra.y))
			if Agua.en_rio(pm) or Agua.en_lago(pm) or Geometry2D.is_point_in_polygon(pm, cienaga):
				return ry
	var y00: float = _cota_cache(cotas, x0, z0)
	var y10: float = _cota_cache(cotas, x0 + paso, z0)
	var y01: float = _cota_cache(cotas, x0, z0 + paso)
	var y11: float = _cota_cache(cotas, x0 + paso, z0 + paso)
	var v00 := Vector3(x0, y00, z0)
	var v10 := Vector3(x0 + paso, y10, z0)
	var v01 := Vector3(x0, y01, z0 + paso)
	var v11 := Vector3(x0 + paso, y11, z0 + paso)
	caras.append(v00); caras.append(v10); caras.append(v11)
	caras.append(v00); caras.append(v11); caras.append(v01)
	return Vector2(minf(ry.x, minf(minf(y00, y10), minf(y01, y11))), maxf(ry.y, maxf(maxf(y00, y10), maxf(y01, y11))))


static func _agregar_cruces_y_muelle(fuente: NavigationMeshSourceGeometryData3D, rect_m: Rect2, agua: Dictionary) -> void:
	for cr: Dictionary in agua["cruces"]:
		var cpos: Vector2 = cr["pos"]
		var cz_m: float = cpos.y * Mapa3D.ESCALA
		var ancho_z_m: float = maxf(1.50, float(cr["half_h"]) * 2.0 * Mapa3D.ESCALA)
		var orillas: Vector2 = RioLago.river_banks_at(cpos.y)
		var x_izq: float = orillas.x * Mapa3D.ESCALA
		var x_der: float = orillas.y * Mapa3D.ESCALA
		if not rect_m.intersects(Rect2(Vector2(x_izq - 2.0, cz_m - ancho_z_m), Vector2((x_der - x_izq) + 4.0, ancho_z_m * 2.0))):
			continue
		var y_tab: float = cota_suelo_m(Vector2((x_izq + x_der) * 0.5, cz_m))
		C.agregar_losa(fuente, Vector2((x_izq + x_der) * 0.5, cz_m), Vector2((x_der - x_izq) + 0.5, ancho_z_m), y_tab)
		C.agregar_rampa(fuente, Vector2(x_izq - 1.1, cz_m), cota_suelo_m(Vector2(x_izq - 1.1, cz_m)), Vector2(x_izq + 0.25, cz_m), y_tab, ancho_z_m)
		C.agregar_rampa(fuente, Vector2(x_der - 0.25, cz_m), y_tab, Vector2(x_der + 1.1, cz_m), cota_suelo_m(Vector2(x_der + 1.1, cz_m)), ancho_z_m)
	var m_rect := Rect2((agua["muelle"] as Rect2).position * Mapa3D.ESCALA, (agua["muelle"] as Rect2).size * Mapa3D.ESCALA)
	if rect_m.intersects(m_rect):
		var mc: Vector2 = m_rect.get_center()
		C.agregar_losa(fuente, mc, m_rect.size + Vector2(0.8, 0.0), cota_suelo_m(Vector2(m_rect.end.x + 0.6, mc.y)))


static func _cerca_de_rio(celda_m: Rect2) -> bool:
	var y_px: float = celda_m.get_center().y / Mapa3D.ESCALA
	if y_px < RioLago.river_y_start() - 120.0 or y_px > RioLago.river_y_end() + 120.0:
		return false
	var hw_m: float = RioLago.river_half_width(y_px) * Mapa3D.ESCALA + MARGEN_RIO_M
	return absf(celda_m.get_center().x - RioLago.river_center_x(y_px) * Mapa3D.ESCALA) <= hw_m + celda_m.size.x


static func _caja_poligono_m(poli: PackedVector2Array, margen_m: float) -> Rect2:
	if poli.is_empty():
		return Rect2()
	var r := Rect2(poli[0] * Mapa3D.ESCALA, Vector2.ZERO)
	for v: Vector2 in poli:
		r = r.expand(v * Mapa3D.ESCALA)
	return r.grow(margen_m)
