extends RefCounted

## Hornea las NavigationMesh locales del subsuelo (bajo_alcantarillas.tscn y sotano_club_pelea.tscn),
## dejando transitables los andenes secos y galerías mientras bloquea los canales de agua sucia.

const C = preload("res://tools/hornear_nav_comun.gd")
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

const ESCENA_ALCANTARILLAS: String = "res://mapa/edificios/bajo_alcantarillas.tscn"
const ESCENA_SOTANO_CLUB: String = "res://mapa/edificios/sotano_club_pelea.tscn"
const Y_CAMARA_M: float = 3.4 * Mapa3D.ALTO
const Y_ANDEN_M: float = 4.6 * Mapa3D.ALTO
const Y_GALERIA_M: float = 4.4 * Mapa3D.ALTO
const Y_CLUB_M: float = 2.2 * Mapa3D.ALTO


static func hornear_alcantarillas() -> Error:
	var fuente := NavigationMeshSourceGeometryData3D.new()
	for cx: float in [-8.960, 0.0, 8.960]:
		C.agregar_losa(fuente, Vector2(cx, -0.532), Vector2(6.160, 2.968), Y_ANDEN_M)
		C.agregar_caja(fuente, Vector3(cx, Y_ANDEN_M + 1.1, 1.064), Vector3(6.160, 2.4, 0.224))
		C.agregar_caja(fuente, Vector3(cx, Y_ANDEN_M + 1.1, -2.408), Vector3(6.496, 2.4, 0.336))
		var t_cofre: Vector2 = C.encoger_mueble(Vector2(0.896, 0.672))
		C.agregar_caja(fuente, Vector3(cx + 1.344, Y_ANDEN_M + 0.55, -1.344), Vector3(t_cofre.x, 1.1, t_cofre.y))
		if cx < 8.0:
			var t_bar: Vector2 = C.encoger_mueble(Vector2(0.504, 0.504))
			var t_caj: Vector2 = C.encoger_mueble(Vector2(0.616, 0.616))
			C.agregar_caja(fuente, Vector3(cx - 2.128, Y_ANDEN_M + 0.5, 0.336), Vector3(t_bar.x, 1.0, t_bar.y))
			C.agregar_caja(fuente, Vector3(cx + 2.128, Y_ANDEN_M + 0.5, 0.336), Vector3(t_caj.x, 1.0, t_caj.y))
		else:
			_muebles_cisterna(fuente, cx)
	for gx: float in [-4.480, 4.480]:
		C.agregar_losa(fuente, Vector2(gx, -0.336), Vector2(3.300, 1.680), Y_GALERIA_M)
		C.agregar_caja(fuente, Vector3(gx, Y_GALERIA_M + 1.1, 0.616), Vector3(3.300, 2.4, 0.224))
		C.agregar_caja(fuente, Vector3(gx, Y_GALERIA_M + 1.1, -1.288), Vector3(3.136, 2.4, 0.336))
	for sx: float in [-5.880, -3.080, 3.080, 5.880]:
		C.agregar_caja(fuente, Vector3(sx, Y_GALERIA_M + 1.1, -1.792), Vector3(0.336, 2.4, 1.232))
		C.agregar_caja(fuente, Vector3(sx, Y_GALERIA_M + 1.1, 0.784), Vector3(0.336, 2.4, 0.672))
	for ex: float in [-12.208, 12.208]:
		C.agregar_caja(fuente, Vector3(ex, Y_CAMARA_M + 1.1, -0.532), Vector3(0.336, 2.4, 3.304))
	var ruta_res: String = C.CARPETA_SALIDA + "bajo_alcantarillas.res"
	var err: Error = C.hornear_y_guardar(fuente, C.crear_malla(), ruta_res)
	return C.poner_region_en_escena(ESCENA_ALCANTARILLAS, load(ruta_res) as NavigationMesh) if err == OK else err


static func _muebles_cisterna(fuente: NavigationMeshSourceGeometryData3D, cx: float) -> void:
	for par: Array in [
		[Vector2(0.0, -1.904), Vector2(1.456, 0.280)],
		[Vector2(-2.128, -0.448), Vector2(0.280, 1.344)],
		[Vector2(2.072, -0.336), Vector2(0.672, 0.504)],
	]:
		var p: Vector2 = par[0]
		var t: Vector2 = C.encoger_mueble(par[1])
		C.agregar_caja(fuente, Vector3(cx + p.x, Y_ANDEN_M + 0.5, p.y), Vector3(t.x, 1.0, t.y))
	for px: float in [-0.952, 0.952]:
		for pz: float in [-1.176, 0.280]:
			C.agregar_caja(fuente, Vector3(cx + px, Y_ANDEN_M + 0.6, pz), Vector3(0.16, 1.2, 0.16))


static func hornear_sotano_club() -> Error:
	if not ResourceLoader.exists(ESCENA_SOTANO_CLUB):
		return OK
	var fuente := NavigationMeshSourceGeometryData3D.new()
	var tam := Vector2(13.440, 7.616)
	C.agregar_losa(fuente, Vector2.ZERO, tam, Y_CLUB_M)
	C.agregar_caja(fuente, Vector3(0.0, Y_CLUB_M + 1.1, -3.976), Vector3(14.112, 2.4, 0.336))
	C.agregar_caja(fuente, Vector3(0.0, Y_CLUB_M + 1.1, 3.976), Vector3(14.112, 2.4, 0.336))
	C.agregar_caja(fuente, Vector3(-6.888, Y_CLUB_M + 1.1, 0.0), Vector3(0.336, 2.4, 7.616))
	C.agregar_caja(fuente, Vector3(6.888, Y_CLUB_M + 1.1, 0.0), Vector3(0.336, 2.4, 7.616))
	var ruta_res: String = C.CARPETA_SALIDA + "sotano_club_pelea.res"
	var err: Error = C.hornear_y_guardar(fuente, C.crear_malla(), ruta_res)
	return C.poner_region_en_escena(ESCENA_SOTANO_CLUB, load(ruta_res) as NavigationMesh) if err == OK else err
