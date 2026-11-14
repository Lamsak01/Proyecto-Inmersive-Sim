extends SceneTree

## Hornea las tres escenas del Club de Pelea y del Puesto del Paso con nombres descriptivos en metros:
## - res://mapa/edificios/sotano_club_pelea.tscn
## - res://assests/curated_3d/exterior/trampilla_club.tscn
## - res://mapa/edificios/puesto_del_paso.tscn
## Uso: flatpak run org.godotengine.Godot --headless --path . -s tools/hornear_club_y_puesto.gd

const U = preload("res://tools/hornear_util_3d.gd")
const Solar = preload("res://mapa/solar.gd")

const SALIDA_CLUB: String = "res://mapa/edificios/sotano_club_pelea.tscn"
const SALIDA_TRAMPILLA: String = "res://assests/curated_3d/exterior/trampilla_club.tscn"
const SALIDA_PUESTO: String = "res://mapa/edificios/puesto_del_paso.tscn"
const CENTRO_SOLAR_PUESTO: Vector2 = Vector2(1593.0, 47.0)


func _initialize() -> void:
	var err1: Error = _hornear_sotano_club()
	var err2: Error = _hornear_trampilla_club()
	var err3: Error = _hornear_puesto_del_paso()
	print("HORNEAR_CLUB_Y_PUESTO: club=%d trampilla=%d puesto=%d" % [err1, err2, err3])
	quit(0 if (err1 == OK and err2 == OK and err3 == OK) else 1)


func _hornear_sotano_club() -> Error:
	var raiz := Node3D.new()
	raiz.name = "SotanoClubPelea"
	var m_roca: StandardMaterial3D = U.mat("sewer_bedrock", Color(0.08, 0.10, 0.09), 0.96, 0.0)
	var m_tierra: StandardMaterial3D = U.mat("club_dirt", Color(0.36, 0.27, 0.18), 0.95, 0.0)
	var m_piedra: StandardMaterial3D = U.mat("sewer_brick", Color(0.28, 0.34, 0.30), 0.90, 0.05, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.35)
	var m_cuerda: StandardMaterial3D = U.mat("club_rope", Color(0.78, 0.66, 0.42), 0.90, 0.0)
	var m_madera: StandardMaterial3D = U.mat("sewer_wood", Color(0.46, 0.30, 0.16), 0.85, 0.04)
	var m_hierro: StandardMaterial3D = U.mat("sewer_iron", Color(0.24, 0.27, 0.32), 0.42, 0.78)
	var m_llama: StandardMaterial3D = U.mat("sewer_torch", Color(1.0, 0.76, 0.32), 0.20, 0.0, Color(1.0, 0.68, 0.22), 2.8)
	var sz := Vector2(240.0, 136.0)
	U.caja(raiz, "LosaRocaSubterranea", Vector2.ZERO, sz + Vector2(80.0, 80.0), 0.0, 1.0, m_roca)
	var techo: MeshInstance3D = U.caja(raiz, "TechoRocaSubterranea", Vector2.ZERO, sz + Vector2(80.0, 80.0), -U.PROFUNDIDAD_SOTANO_PX - 2.5, 2.0, m_roca)
	techo.add_to_group("techo_bajo_tierra_3d")
	U.caja(raiz, "SueloTierraBatida", Vector2.ZERO, sz, 1.0, 1.2, m_tierra)
	U.caja(raiz, "MuroNorteAlto", Vector2(0.0, -sz.y * 0.5 - 3.0), Vector2(sz.x + 12.0, 6.0), 2.0, 22.0, m_piedra)
	U.caja(raiz, "ZocaloSurBajo", Vector2(0.0, sz.y * 0.5 + 3.0), Vector2(sz.x + 12.0, 6.0), 2.0, 5.0, m_piedra)
	U.caja(raiz, "MuroSurAlto1P", Vector2(0.0, sz.y * 0.5 + 3.0), Vector2(sz.x + 12.0, 6.0), 7.0, 21.0, m_piedra).add_to_group("techo_bajo_tierra_3d")
	U.caja(raiz, "MuroOeste", Vector2(-sz.x * 0.5 - 3.0, 0.0), Vector2(6.0, sz.y), 2.0, 22.0, m_piedra)
	U.caja(raiz, "MuroEste", Vector2(sz.x * 0.5 + 3.0, 0.0), Vector2(6.0, sz.y), 2.0, 22.0, m_piedra)
	var corro: Node3D = U.grupo(raiz, "CorroCuerdas")
	var radio: float = 40.0
	for i: int in range(12):
		var a0: float = TAU * float(i) / 12.0
		var a1: float = TAU * float(i + 1) / 12.0
		var p0: Vector2 = Vector2(cos(a0), sin(a0)) * radio
		var p1: Vector2 = Vector2(cos(a1), sin(a1)) * radio
		U.cilindro(corro, "PosteCorro_%d" % (i + 1), p0, 1.2, 2.2, 9.0, m_madera, 1.2, 6)
		var d: Vector2 = p1 - p0
		var giro_cuerda: float = -rad_to_deg(atan2(d.y, d.x))
		U.caja(corro, "CuerdaCorro_%d" % (i + 1), (p0 + p1) * 0.5, Vector2(d.length(), 1.2), 8.0, 0.8, m_cuerda, giro_cuerda)
	var esc: Node3D = U.grupo(raiz, "EscalerillaSubida", Vector2(82.0, -52.0))
	U.caja(esc, "LargueroIzq", Vector2(-4.0, -6.0), Vector2(1.4, 2.0), 2.4, 22.0, m_hierro)
	U.caja(esc, "LargueroDer", Vector2(4.0, -6.0), Vector2(1.4, 2.0), 2.4, 22.0, m_hierro)
	for k: int in range(6):
		U.caja(esc, "Peldano_%d" % (k + 1), Vector2(0.0, -6.0), Vector2(8.0, 1.2), 4.0 + float(k) * 3.2, 0.9, m_madera)
	var nf := 0
	for off: Vector2 in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]:
		nf += 1
		var tp := Vector2(off.x * (sz.x * 0.5 - 8.0), off.y * (sz.y * 0.5 - 8.0))
		var farol: Node3D = U.grupo(raiz, "FarolEsquina_%d" % nf, tp)
		U.cilindro(farol, "PosteMadera", Vector2.ZERO, 1.4, 2.0, 10.0, m_madera, 1.0, 6)
		U.cilindro(farol, "LlamaTea", Vector2.ZERO, 2.2, 12.0, 3.0, m_llama, 1.4, 8)
		U.luz_omni(farol, "LuzFarol", Vector2.ZERO, 16.0, Color(1.0, 0.78, 0.42), 1.2, 3.4)
	var err: Error = U.guardar_escena(raiz, SALIDA_CLUB)
	raiz.free()
	return err


func _hornear_trampilla_club() -> Error:
	var raiz := Node3D.new()
	raiz.name = "ClubTrapdoor3D"
	var m_roca: StandardMaterial3D = U.mat("sewer_bedrock", Color(0.08, 0.10, 0.09), 0.96, 0.0)
	var m_madera: StandardMaterial3D = U.mat("sewer_wood", Color(0.46, 0.30, 0.16), 0.85, 0.04)
	var m_hierro: StandardMaterial3D = U.mat("sewer_iron", Color(0.24, 0.27, 0.32), 0.42, 0.78)
	var m_llama: StandardMaterial3D = U.mat("sewer_torch", Color(1.0, 0.76, 0.32), 0.20, 0.0, Color(1.0, 0.68, 0.22), 2.8)
	var cerrada: Node3D = U.grupo(raiz, "ClosedLid")
	U.caja(cerrada, "TapaMadera", Vector2.ZERO, Vector2(16.0, 14.0), 2.5, 1.1, m_madera)
	U.caja(cerrada, "HerrajeSur", Vector2(0.0, 4.2), Vector2(12.0, 1.3), 3.6, 0.6, m_hierro)
	U.caja(cerrada, "HerrajeNorte", Vector2(0.0, -4.2), Vector2(12.0, 1.3), 3.6, 0.6, m_hierro)
	var abierta: Node3D = U.grupo(raiz, "OpenHatch")
	U.caja(abierta, "MarcoNorte", Vector2(0.0, -7.2), Vector2(16.0, 1.6), 2.5, 1.4, m_madera)
	U.caja(abierta, "MarcoSur", Vector2(0.0, 7.2), Vector2(16.0, 1.6), 2.5, 1.4, m_madera)
	U.caja(abierta, "MarcoOeste", Vector2(-7.8, 0.0), Vector2(1.6, 13.0), 2.5, 1.4, m_madera)
	U.caja(abierta, "MarcoEste", Vector2(7.8, 0.0), Vector2(1.6, 13.0), 2.5, 1.4, m_madera)
	U.caja(abierta, "HuecoOscuroSotano", Vector2.ZERO, Vector2(13.6, 12.2), 2.45, 0.4, m_roca)
	U.caja(abierta, "HojaAbiertaNorte", Vector2(0.0, -7.8), Vector2(15.2, 1.8), 3.2, 11.5, m_madera)
	U.caja(abierta, "HerrajeInterior", Vector2(0.0, -6.8), Vector2(12.0, 0.6), 6.0, 1.2, m_hierro)
	U.caja(abierta, "LargueroIzq", Vector2(-4.0, -1.5), Vector2(1.2, 1.4), 1.5, 4.8, m_hierro)
	U.caja(abierta, "LargueroDer", Vector2(4.0, -1.5), Vector2(1.2, 1.4), 1.5, 4.8, m_hierro)
	U.caja(abierta, "PeldanoSuperior", Vector2(0.0, -1.5), Vector2(7.4, 1.0), 3.2, 0.8, m_madera)
	U.caja(abierta, "ResplandorSotano", Vector2(0.0, 1.5), Vector2(7.4, 1.0), 2.6, 0.8, m_llama)
	U.luz_omni(abierta, "LuzSotano", Vector2.ZERO, 5.5, Color(1.0, 0.72, 0.28), 1.35, 1.8)
	var err: Error = U.guardar_escena(raiz, SALIDA_TRAMPILLA)
	raiz.free()
	return err


func _hornear_puesto_del_paso() -> Error:
	var c: Vector2 = Solar.marca("puesto_del_paso", "centro") - CENTRO_SOLAR_PUESTO
	var gate_p: Vector2 = Solar.marca("puesto_del_paso", "puerta") - CENTRO_SOLAR_PUESTO
	var raiz := Node3D.new()
	raiz.name = "PuestoDelPaso"
	var m_camino: StandardMaterial3D = U.mat("road_dirt", Color(0.46, 0.37, 0.25), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.35)
	var m_tronco: StandardMaterial3D = U.mat("outpost_log", Color(0.55, 0.40, 0.26), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/floor_wood_planks.png", "", 0.45)
	var m_tabla: StandardMaterial3D = U.mat("outpost_plank", Color(0.68, 0.50, 0.32), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/floor_wood_planks.png", "", 0.45)
	var m_piedra: StandardMaterial3D = U.mat("outpost_stone", Color(0.65, 0.64, 0.60), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.35)
	var camino: Node3D = U.grupo(raiz, "CaminoAcceso")
	U.caja(camino, "CalzadaTierraEste", Vector2(1512.0, 50.0) - CENTRO_SOLAR_PUESTO, Vector2(72.0, 26.0), 0.0, 1.2, m_camino)
	var solar: Node3D = U.grupo(raiz, "SolarSinFundar")
	var ne := 0
	for p: Vector2 in [Vector2(-64.0, -68.0), Vector2(64.0, -68.0), Vector2(64.0, 68.0), Vector2(-64.0, 68.0)]:
		ne += 1
		U.cilindro(solar, "EstacaLinde_%d" % ne, c + p, 2.5, 0.0, 11.0, m_tronco, 2.0, 8)
	U.caja(solar, "PosteCartel", gate_p, Vector2(4.0, 4.0), 0.0, 16.0, m_tronco)
	U.caja(solar, "TablaCartel", gate_p + Vector2(0.0, -2.0), Vector2(16.0, 3.0), 11.0, 5.0, m_tabla)
	var fuerte: Node3D = U.grupo(raiz, "FuerteFundado")
	U.caja(fuerte, "ExplanadaPiedra", c, Vector2(152.0, 164.0), 0.0, 1.5, m_piedra)
	U.caja(fuerte, "EmpalizadaNorte", c + Vector2(0.0, -80.0), Vector2(152.0, 6.0), 1.5, 22.0, m_tronco)
	U.caja(fuerte, "EmpalizadaSur", c + Vector2(0.0, 80.0), Vector2(152.0, 6.0), 1.5, 22.0, m_tronco)
	U.caja(fuerte, "EmpalizadaEste", c + Vector2(74.0, 0.0), Vector2(6.0, 164.0), 1.5, 22.0, m_tronco)
	U.caja(fuerte, "EmpalizadaOesteNorte", c + Vector2(-74.0, -50.0), Vector2(6.0, 60.0), 1.5, 22.0, m_tronco)
	U.caja(fuerte, "EmpalizadaOesteSur", c + Vector2(-74.0, 50.0), Vector2(6.0, 60.0), 1.5, 22.0, m_tronco)
	U.cilindro(fuerte, "PorticoPosteNorte", gate_p + Vector2(0.0, -20.0), 4.0, 1.5, 28.0, m_tronco, 3.5, 8)
	U.cilindro(fuerte, "PorticoPosteSur", gate_p + Vector2(0.0, 20.0), 4.0, 1.5, 28.0, m_tronco, 3.5, 8)
	U.caja(fuerte, "PorticoDintel", gate_p, Vector2(8.0, 44.0), 25.0, 5.0, m_tabla)
	U.modelo(fuerte, "CabanaMando", "buildings/House_2.obj", c + Vector2(34.0, 0.0), 1.5, Vector2(50.0, 42.0), 34.0, -90.0)
	U.modelo(fuerte, "ArcaAsentamiento", "props/Chest_Wood.gltf", c + Vector2(6.0, 0.0), 1.5, Vector2(13.0, 9.0), 8.0, -90.0)
	U.modelo(fuerte, "HogueraCentral", "exterior/Bonfire_Lit.obj", c + Vector2(-18.0, 0.0), 1.5, Vector2(16.0, 16.0), 11.0)
	U.modelo(fuerte, "CajaSuministros", "props/Crate_Wooden.gltf", c + Vector2(14.0, 24.0), 1.5, Vector2(10.0, 10.0), 8.0)
	U.modelo(fuerte, "BarrilAgua", "props/Barrel.gltf", c + Vector2(14.0, -24.0), 1.5, Vector2(9.0, 9.0), 9.5)
	U.luz_omni(fuerte, "LuzHoguera", c + Vector2(-18.0, 0.0), 12.0, Color(1.0, 0.65, 0.25), 1.6, 3.2)
	var aserradero: Node3D = U.grupo(raiz, "MejoraAserradero", c + Vector2(-26.0, -50.0))
	U.modelo(aserradero, "EdificioAserradero", "buildings/Sawmill.obj", Vector2.ZERO, 1.5, Vector2(48.0, 32.0), 28.0)
	U.modelo(aserradero, "TroncoCortado", "nature/WoodLog.obj", Vector2(22.0, 10.0), 1.5, Vector2(14.0, 8.0), 6.0)
	var granero: Node3D = U.grupo(raiz, "MejoraGranero", c + Vector2(-26.0, 50.0))
	U.modelo(granero, "MolinoGranero", "buildings/Mill.obj", Vector2.ZERO, 1.5, Vector2(38.0, 38.0), 36.0)
	var atalaya: Node3D = U.grupo(raiz, "MejoraAtalaya", c + Vector2(-56.0, -56.0))
	U.modelo(atalaya, "AtalayaGuardia", "buildings/Bell_Tower.obj", Vector2.ZERO, 1.5, Vector2(30.0, 30.0), 48.0)
	var err: Error = U.guardar_escena(raiz, SALIDA_PUESTO)
	raiz.free()
	return err
