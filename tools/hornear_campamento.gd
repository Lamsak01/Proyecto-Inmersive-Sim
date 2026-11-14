extends SceneTree

## Hornea en escenas editables en metros tienda, hoguera, tronco asiento, tendedero y caballetes.
const U = preload("res://tools/hornear_util_3d.gd")
const DIR_EXT: String = "res://assests/curated_3d/exterior/"

func _initialize() -> void:
	var errs: Array[Error] = [
		_hornear_tienda(),
		_hornear_hoguera(),
		_hornear_tronco_asiento(),
		_hornear_tendedero(),
		_hornear_caballete("caballete_espada.tscn", "CaballeteEspada", "props/Sword_Bronze.gltf"),
		_hornear_caballete("caballete_martillo.tscn", "CaballeteMartillo", "weapons/Hammer_Double.obj"),
	]
	var fallos: int = 0
	for e: Error in errs:
		if e != OK:
			fallos += 1
	print("HORNEAR_CAMPAMENTO: fallos=%d" % fallos)
	quit(0 if fallos == 0 else 1)


func _hornear_tienda() -> Error:
	var raiz := Node3D.new()
	raiz.name = "TiendaCampana"
	var m_mad: StandardMaterial3D = U.mat("prop_wood", Color(0.54, 0.36, 0.20), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_osc: StandardMaterial3D = U.mat("prop_dark_wood", Color(0.38, 0.24, 0.13), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_lona: StandardMaterial3D = U.mat("tent_canvas", Color(0.84, 0.74, 0.54), 0.88, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "town_textures/T_Trim_Cloth_Normal.png", 0.55)
	var m_faldon: StandardMaterial3D = U.mat("tent_flap", Color(0.72, 0.60, 0.42), 0.90, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.65)
	var m_saco: StandardMaterial3D = U.mat("tent_bedroll", Color(0.58, 0.24, 0.20), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.70)
	var m_almohada: StandardMaterial3D = U.mat("tent_pillow", Color(0.92, 0.88, 0.78), 0.90, 0.0)
	var m_puerta: StandardMaterial3D = U.mat("tent_door", Color(0.16, 0.12, 0.09), 0.96, 0.0)
	U.caja(raiz, "TarimaMadera", Vector2(0.0, 2.0), Vector2(34.0, 24.0), 0.0, 1.6, m_osc)
	U.prisma(raiz, "LonaDosAguas", Vector2(0.0, 2.0), Vector2(32.0, 22.0), 1.4, 17.5, m_lona, false)
	U.caja(raiz, "CumbreraMadera", Vector2(0.0, 2.0), Vector2(3.0, 25.0), 17.2, 2.2, m_osc)
	U.cilindro(raiz, "MastilNorte", Vector2(0.0, -9.2), 1.4, 1.4, 17.6, m_osc, 1.4, 8)
	U.cilindro(raiz, "MastilSur", Vector2(0.0, 13.2), 1.3, 1.4, 17.6, m_osc, 1.3, 8)
	U.caja(raiz, "EntradaOscura", Vector2(0.0, 12.6), Vector2(8.5, 1.2), 1.6, 10.5, m_puerta)
	U.cilindro(raiz, "FaldonOeste", Vector2(-4.8, 13.0), 1.6, 1.6, 11.2, m_faldon, 1.4, 8)
	U.cilindro(raiz, "FaldonEste", Vector2(4.8, 13.0), 1.6, 1.6, 11.2, m_faldon, 1.4, 8)
	U.caja(raiz, "SacoDormir", Vector2(0.0, 4.5), Vector2(8.0, 13.0), 1.6, 2.2, m_saco)
	U.caja(raiz, "Almohada", Vector2(0.0, -0.5), Vector2(6.8, 3.4), 3.6, 1.4, m_almohada)
	var ne: int = 0
	for off: Vector2 in [Vector2(-18.5, -8.5), Vector2(18.5, -8.5), Vector2(-18.5, 12.5), Vector2(18.5, 12.5)]:
		ne += 1
		U.cilindro(raiz, "EstacaEsquina_%d" % ne, off, 1.0, 0.0, 4.2, m_osc, 0.8, 6)
		U.caja(raiz, "VientoTensor_%d" % ne, off * 0.82, Vector2(3.6, 0.9), 2.5, 1.2, m_mad)
	var err: Error = U.guardar_escena(raiz, DIR_EXT + "tienda_campana.tscn")
	raiz.free()
	return err


func _hornear_hoguera() -> Error:
	var raiz := Node3D.new()
	raiz.name = "HogueraCaldero"
	var m_osc: StandardMaterial3D = U.mat("prop_dark_wood", Color(0.38, 0.24, 0.13), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_fe: StandardMaterial3D = U.mat("prop_iron", Color(0.30, 0.31, 0.33), 0.6, 0.5)
	var m_piedra: StandardMaterial3D = U.mat("campfire_stone", Color(0.48, 0.46, 0.44), 0.92, 0.02)
	var m_brasa: StandardMaterial3D = U.mat("campfire_ember", Color(0.95, 0.34, 0.08), 0.40, 0.0, Color(1.0, 0.36, 0.06), 2.4)
	var m_llama: StandardMaterial3D = U.mat("campfire_flame", Color(1.0, 0.72, 0.18), 0.25, 0.0, Color(1.0, 0.58, 0.10), 3.0)
	var m_guiso: StandardMaterial3D = U.mat("campfire_stew", Color(0.76, 0.42, 0.18), 0.35, 0.05)
	for i: int in range(8):
		var ang: float = float(i) * TAU / 8.0
		U.caja(raiz, "PiedraCerco_%d" % (i + 1), Vector2(cos(ang), sin(ang)) * 7.2, Vector2(3.8, 3.2), 0.0, 2.6, m_piedra, rad_to_deg(ang))
	U.cilindro(raiz, "BrasasEncendidas", Vector2.ZERO, 5.8, 0.0, 1.6, m_brasa, 5.2, 10)
	U.caja(raiz, "TroncoCruzado_1", Vector2.ZERO, Vector2(13.0, 2.4), 0.8, 2.2, m_osc, 28.0)
	U.caja(raiz, "TroncoCruzado_2", Vector2.ZERO, Vector2(13.0, 2.4), 0.8, 2.2, m_osc, -32.0)
	U.cilindro(raiz, "LlamaViva_1", Vector2(-1.8, 0.8), 2.4, 1.4, 4.8, m_llama, 0.4, 7)
	U.cilindro(raiz, "LlamaViva_2", Vector2(1.8, -0.6), 2.0, 1.4, 4.2, m_llama, 0.3, 7)
	U.modelo(raiz, "HogueraModelo", "exterior/Bonfire_Lit.obj", Vector2.ZERO, 0.0, Vector2(16.0, 16.0), 9.0)
	U.modelo(raiz, "CalderoHierro", "exterior/Cauldron.obj", Vector2.ZERO, 3.2, Vector2(11.0, 11.0), 7.8)
	U.cilindro(raiz, "GuisoCaldero", Vector2.ZERO, 3.8, 8.8, 1.2, m_guiso, 3.8, 10)
	var np: int = 0
	for t_ang: float in [-2.1, 0.0, 2.1]:
		np += 1
		U.cilindro(raiz, "PataTripode_%d" % np, Vector2(cos(t_ang), sin(t_ang)) * 5.2, 0.75, 0.0, 15.5, m_fe, 0.65, 6)
	U.cilindro(raiz, "AroTripode", Vector2.ZERO, 4.8, 14.5, 1.2, m_fe, 4.8, 10)
	U.cilindro(raiz, "CadenaCaldero", Vector2.ZERO, 0.6, 9.5, 5.5, m_fe, 0.6, 6)
	U.luz_omni(raiz, "LuzHoguera", Vector2.ZERO, 10.0, Color(1.0, 0.62, 0.28), 1.35, 2.8)
	var err: Error = U.guardar_escena(raiz, DIR_EXT + "hoguera_caldero.tscn")
	raiz.free()
	return err


func _hornear_tronco_asiento() -> Error:
	var raiz := Node3D.new()
	raiz.name = "TroncoAsiento"
	var m_mad: StandardMaterial3D = U.mat("prop_wood", Color(0.54, 0.36, 0.20), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_osc: StandardMaterial3D = U.mat("prop_dark_wood", Color(0.38, 0.24, 0.13), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_anillo: StandardMaterial3D = U.mat("log_end_ring", Color(0.78, 0.64, 0.42), 0.85, 0.0)
	var tronco: MeshInstance3D = U.cilindro(raiz, "TroncoTumbado", Vector2.ZERO, 3.8, 0.0, 23.0, m_osc, 3.8, 10)
	tronco.rotation_degrees.z = 90.0
	tronco.position = U.pos_m(Vector2.ZERO, 3.8)
	for lado: Array in [["AnilloCorteOeste", -11.6], ["AnilloCorteEste", 11.6]]:
		var tapa: MeshInstance3D = U.cilindro(raiz, String(lado[0]), Vector2(float(lado[1]), 0.0), 3.4, 0.0, 0.6, m_anillo, 3.4, 10)
		tapa.rotation_degrees.z = 90.0
		tapa.position = U.pos_m(Vector2(float(lado[1]), 0.0), 3.8)
	U.caja(raiz, "CalzoOeste", Vector2(-7.0, 0.0), Vector2(3.0, 8.2), 0.0, 2.2, m_mad)
	U.caja(raiz, "CalzoEste", Vector2(7.0, 0.0), Vector2(3.0, 8.2), 0.0, 2.2, m_mad)
	var err: Error = U.guardar_escena(raiz, DIR_EXT + "tronco_asiento.tscn")
	raiz.free()
	return err


func _hornear_tendedero() -> Error:
	var raiz := Node3D.new()
	raiz.name = "TendederoRopa"
	var m_mad: StandardMaterial3D = U.mat("prop_wood", Color(0.54, 0.36, 0.20), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_osc: StandardMaterial3D = U.mat("prop_dark_wood", Color(0.38, 0.24, 0.13), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_cuerda: StandardMaterial3D = U.mat("clothesline_rope", Color(0.76, 0.66, 0.48), 0.90, 0.0)
	var m_morado: StandardMaterial3D = U.mat("cloth_purple", Color(0.62, 0.46, 0.84), 0.88, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.7)
	var m_casaca: StandardMaterial3D = U.mat("cloth_tunic", Color(0.58, 0.52, 0.42), 0.90, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.7)
	var m_turquesa: StandardMaterial3D = U.mat("cloth_teal", Color(0.24, 0.58, 0.68), 0.88, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.7)
	for info: Array in [["Oeste", -13.0], ["Este", 13.0]]:
		var px: float = float(info[1])
		U.caja(raiz, "BasePoste" + String(info[0]), Vector2(px, 3.0), Vector2(3.8, 3.8), 0.0, 2.0, m_osc)
		U.cilindro(raiz, "Poste" + String(info[0]), Vector2(px, 3.0), 1.6, 0.0, 16.5, m_mad, 1.4, 8)
		U.caja(raiz, "Nudo" + String(info[0]), Vector2(px, 3.0), Vector2(2.6, 2.8), 13.5, 1.8, m_cuerda)
	U.caja(raiz, "CuerdaTendida", Vector2(0.0, 3.0), Vector2(26.0, 1.2), 14.0, 1.0, m_cuerda)
	U.caja(raiz, "PantalonMoradoCintura", Vector2(-7.2, 3.2), Vector2(5.6, 1.6), 9.5, 4.8, m_morado)
	U.caja(raiz, "PantalonMoradoPerneraIzq", Vector2(-8.6, 3.2), Vector2(2.4, 1.6), 5.2, 4.5, m_morado)
	U.caja(raiz, "PantalonMoradoPerneraDer", Vector2(-5.8, 3.2), Vector2(2.4, 1.6), 5.2, 4.5, m_morado)
	U.caja(raiz, "CasacaCentroCuerpo", Vector2(0.0, 3.2), Vector2(6.4, 1.8), 4.8, 9.5, m_casaca)
	U.caja(raiz, "CasacaCentroMangas", Vector2(0.0, 3.2), Vector2(9.2, 1.6), 11.2, 3.0, m_casaca)
	U.caja(raiz, "PrendaTurquesaCintura", Vector2(7.4, 3.2), Vector2(5.4, 1.6), 9.5, 4.8, m_turquesa)
	U.caja(raiz, "PrendaTurquesaPerneraIzq", Vector2(6.1, 3.2), Vector2(2.3, 1.6), 5.5, 4.2, m_turquesa)
	U.caja(raiz, "PrendaTurquesaPerneraDer", Vector2(8.7, 3.2), Vector2(2.3, 1.6), 5.5, 4.2, m_turquesa)
	var np: int = 0
	for pin_x: float in [-8.4, -6.0, -1.8, 1.8, 6.2, 8.6]:
		np += 1
		U.caja(raiz, "PinzaMadera_%d" % np, Vector2(pin_x, 3.2), Vector2(0.9, 2.0), 14.2, 1.6, m_osc)
	var err: Error = U.guardar_escena(raiz, DIR_EXT + "tendedero_ropa.tscn")
	raiz.free()
	return err


func _hornear_caballete(archivo: String, nombre: String, ruta_arma: String) -> Error:
	var raiz := Node3D.new()
	raiz.name = nombre
	var m_mad: StandardMaterial3D = U.mat("prop_wood", Color(0.54, 0.36, 0.20), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_osc: StandardMaterial3D = U.mat("prop_dark_wood", Color(0.38, 0.24, 0.13), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	U.cilindro(raiz, "ToconArmero", Vector2(0.0, 2.0), 4.8, 0.0, 4.5, m_osc, 4.2, 10)
	U.caja(raiz, "SoporteMadera", Vector2(0.0, 2.0), Vector2(8.0, 3.2), 4.2, 1.6, m_mad)
	var arma: Node3D = U.modelo(raiz, "ArmaApoyada", ruta_arma, Vector2(0.0, 1.5), 4.5, Vector2.ZERO, 15.0, 25.0)
	arma.rotation_degrees.z = -28.0
	var err: Error = U.guardar_escena(raiz, DIR_EXT + archivo)
	raiz.free()
	return err
