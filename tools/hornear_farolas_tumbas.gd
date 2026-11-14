extends SceneTree

## Hornea en escenas editables en metros las farolas, focos, barreras de sacos, tumbas y tocones:
## - assests/curated_3d/graveyard/tumba_enterrada_1..4.tscn
## - assests/curated_3d/exterior/{barrera_sacos_alambre,torre_foco_electrico,farola_calle}.tscn
## - assests/curated_3d/nature/tocon_arbol_talado.tscn

const U = preload("res://tools/hornear_util_3d.gd")

const COLOR_ELECTRICO: Color = Color(0.58, 0.96, 1.0)
const MODELOS_TUMBA: Array[String] = [
	"graveyard/gravestone-cross.glb",
	"graveyard/gravestone-decorative.glb",
	"graveyard/gravestone-round.glb",
	"graveyard/cross-column.glb",
]


func _initialize() -> void:
	var fallos: int = 0
	for i: int in range(MODELOS_TUMBA.size()):
		if _hornear_tumba(i) != OK:
			fallos += 1
	if _hornear_barrera() != OK:
		fallos += 1
	if _hornear_torre_foco() != OK:
		fallos += 1
	if _hornear_farola() != OK:
		fallos += 1
	if _hornear_tocon() != OK:
		fallos += 1
	print("HORNEAR_FAROLAS_TUMBAS: fallos=%d" % fallos)
	quit(0 if fallos == 0 else 1)


func _hornear_tumba(idx: int) -> Error:
	var raiz := Node3D.new()
	raiz.name = "TumbaEnterrada_%d" % (idx + 1)
	var m_tierra: StandardMaterial3D = U.mat("grave_earth", Color(0.36, 0.25, 0.16), 0.95, 0.0)
	U.caja(raiz, "MonticuloTierra", Vector2(0.0, 3.0), Vector2(7.5, 8.5), 1.0, 1.8, m_tierra)
	U.modelo(raiz, "LapidaPiedra", MODELOS_TUMBA[idx], Vector2(0.0, -4.0), 1.0, Vector2(6.8, 3.2), 8.8)
	var err: Error = U.guardar_escena(raiz, "res://assests/curated_3d/graveyard/tumba_enterrada_%d.tscn" % (idx + 1))
	raiz.free()
	return err


func _hornear_barrera() -> Error:
	var raiz := Node3D.new()
	raiz.name = "BarreraSacosAlambre"
	var m_saco: StandardMaterial3D = U.mat("epoch_sandbag", Color(0.50, 0.43, 0.31), 0.95, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.8)
	var m_estaca: StandardMaterial3D = U.mat("epoch_stake_wood", Color(0.30, 0.20, 0.12), 0.90, 0.0)
	var m_alambre: StandardMaterial3D = U.mat("epoch_barbed_wire", Color(0.24, 0.25, 0.27), 0.48, 0.82)
	var ns: int = 0
	for bx: float in [-7.5, -2.5, 2.5, 7.5]:
		ns += 1
		U.caja(raiz, "SacoBaseSur_%d" % ns, Vector2(bx, 1.2), Vector2(4.8, 3.4), 0.0, 2.4, m_saco)
		U.caja(raiz, "SacoBaseNorte_%d" % ns, Vector2(bx, -1.2), Vector2(4.8, 3.4), 0.0, 2.4, m_saco)
	var nm: int = 0
	for bx2: float in [-5.0, 0.0, 5.0]:
		nm += 1
		U.caja(raiz, "SacoMedio_%d" % nm, Vector2(bx2, 0.0), Vector2(4.8, 3.6), 2.3, 2.3, m_saco)
	var nc: int = 0
	for bx3: float in [-2.5, 2.5]:
		nc += 1
		U.caja(raiz, "SacoCumbre_%d" % nc, Vector2(bx3, 0.0), Vector2(4.6, 3.2), 4.5, 2.0, m_saco)
	var ne: int = 0
	for sx: float in [-8.5, 0.0, 8.5]:
		ne += 1
		U.cilindro(raiz, "EstacaNorte_%d" % ne, Vector2(sx, -2.8), 0.65, 0.0, 8.2, m_estaca, 0.55, 6)
		U.cilindro(raiz, "EstacaSur_%d" % ne, Vector2(sx, 2.8), 0.65, 0.0, 8.2, m_estaca, 0.55, 6)
	var nh: int = 0
	for wy: float in [5.2, 6.8, 8.0]:
		nh += 1
		U.caja(raiz, "HebraEspino_%d" % nh, Vector2.ZERO, Vector2(21.0, 0.45), wy, 0.45, m_alambre)
	var nr: int = 0
	for cx: float in [-7.0, -3.5, 0.0, 3.5, 7.0]:
		nr += 1
		U.cilindro(raiz, "RolloEspino_%d" % nr, Vector2(cx, 2.4), 2.2, 2.2, 3.8, m_alambre, 2.2, 8)
	var err: Error = U.guardar_escena(raiz, "res://assests/curated_3d/exterior/barrera_sacos_alambre.tscn")
	raiz.free()
	return err


func _hornear_torre_foco() -> Error:
	var raiz := Node3D.new()
	raiz.name = "TorreFocoElectrico"
	var m_poste: StandardMaterial3D = U.mat("epoch_pole_wood", Color(0.28, 0.19, 0.11), 0.90, 0.0)
	var m_carcasa: StandardMaterial3D = U.mat("epoch_hood_iron", Color(0.16, 0.18, 0.21), 0.45, 0.82)
	var m_bombilla: StandardMaterial3D = U.mat("bulb_voltaic", Color(0.55, 0.96, 1.0), 0.2, 0.0, Color(0.45, 0.92, 1.0), 3.4)
	U.cilindro(raiz, "PosteMadera", Vector2.ZERO, 2.2, 0.0, 35.0, m_poste, 1.5, 8)
	U.caja(raiz, "CrucetaMadera", Vector2.ZERO, Vector2(7.5, 2.2), 31.5, 1.8, m_poste)
	var cabeza: Node3D = U.grupo(raiz, "CabezaFoco")
	U.caja(cabeza, "CarcasaProyector", Vector2(0.0, -2.8), Vector2(5.2, 5.2), 33.0, 4.2, m_carcasa)
	U.cilindro(cabeza, "BombillaFoco", Vector2(0.0, -4.4), 2.1, 33.4, 2.6, m_bombilla, 2.1, 8)
	var haz := SpotLight3D.new()
	haz.name = "HazFoco"
	haz.position = U.pos_m(Vector2(0.0, -2.8), 34.5)
	haz.spot_range = 9.5 * U.K
	haz.spot_angle = 42.0
	haz.light_energy = 3.2
	haz.light_color = COLOR_ELECTRICO
	cabeza.add_child(haz, true)
	U.luz_omni(raiz, "CharcoLuzSuelo", Vector2(0.0, -18.0), 10.0, COLOR_ELECTRICO, 2.1, 5.4)
	var err: Error = U.guardar_escena(raiz, "res://assests/curated_3d/exterior/torre_foco_electrico.tscn")
	raiz.free()
	return err


func _hornear_farola() -> Error:
	var raiz := Node3D.new()
	raiz.name = "FarolaCalle"
	var m_bombilla: StandardMaterial3D = U.mat("bulb_voltaic", Color(0.55, 0.96, 1.0), 0.2, 0.0, Color(0.45, 0.92, 1.0), 3.4)
	U.modelo(raiz, "PosteFarola", "graveyard/lightpost-single.glb", Vector2.ZERO, 0.0, Vector2(9.0, 9.0), 34.8)
	U.caja(raiz, "CristalFarol", Vector2(0.0, 2.5), Vector2(8.4, 3.6), 27.48, 2.64, m_bombilla)
	var omni: OmniLight3D = U.luz_omni(raiz, "ResplandorFarol", Vector2(0.0, 2.5), 28.8, COLOR_ELECTRICO, 3.0, 3.6)
	omni.distance_fade_enabled = true
	omni.distance_fade_begin = 70.0
	omni.distance_fade_length = 15.0
	var charco := SpotLight3D.new()
	charco.name = "CharcoLuzCalle"
	charco.position = U.pos_m(Vector2(0.0, 2.5), 27.48)
	charco.rotation_degrees.x = -90.0
	charco.spot_range = 6.0 * U.K
	charco.spot_angle = 60.0
	charco.light_energy = 15.0
	charco.light_color = COLOR_ELECTRICO
	charco.distance_fade_enabled = true
	charco.distance_fade_begin = 70.0
	charco.distance_fade_length = 15.0
	raiz.add_child(charco, true)
	var err: Error = U.guardar_escena(raiz, "res://assests/curated_3d/exterior/farola_calle.tscn")
	raiz.free()
	return err


func _hornear_tocon() -> Error:
	var raiz := Node3D.new()
	raiz.name = "ToconArbolTalado"
	var m_tocon: StandardMaterial3D = U.mat("tree_stump", Color(0.45, 0.32, 0.20), 0.9, 0.0, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78)
	U.cilindro(raiz, "ToconCorteza", Vector2.ZERO, 5.0, -1.2, 6.2, m_tocon, 4.5, 8)
	var err: Error = U.guardar_escena(raiz, "res://assests/curated_3d/nature/tocon_arbol_talado.tscn")
	raiz.free()
	return err
