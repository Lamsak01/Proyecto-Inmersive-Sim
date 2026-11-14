extends SceneTree

## Hornea la red completa de alcantarillas y su reñidero en res://mapa/edificios/bajo_alcantarillas.tscn
## con nombres descriptivos en metros, y conecta la instancia en BajoTierra/Alcantarillas de Mundo3D.tscn.
## Uso: flatpak run org.godotengine.Godot --headless --path . -s tools/hornear_alcantarillas.gd

const U = preload("res://tools/hornear_util_3d.gd")
const Renidero = preload("res://tools/hornear_renidero.gd")

const SALIDA_RED: String = "res://mapa/edificios/bajo_alcantarillas.tscn"
const ESCENA_MAPA: String = "res://mapa/Mundo3D.tscn"
const CENTRO_RED: Vector2 = Vector2(420.0, 63.0)


func _initialize() -> void:
	var raiz := Node3D.new()
	raiz.name = "Alcantarillas"
	raiz.set_script(load("res://mapa/edificio.gd"))
	raiz.set("id_edificio", "bajo_alcantarillas")
	raiz.set("centro_original", CENTRO_RED)
	var muros: Node3D = U.grupo(raiz, "Muros")
	var m_roca: StandardMaterial3D = U.mat("sewer_bedrock", Color(0.08, 0.10, 0.09), 0.96, 0.0)
	var m_lad: StandardMaterial3D = U.mat("sewer_brick", Color(0.28, 0.34, 0.30), 0.90, 0.05, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.35)
	var m_and: StandardMaterial3D = U.mat("sewer_walkway", Color(0.36, 0.40, 0.38), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/rf_cobblestone.png", "", 0.45)
	var m_ag: StandardMaterial3D = U.mat("sewer_water", Color(0.12, 0.26, 0.20, 0.92), 0.22, 0.12)
	var m_fe: StandardMaterial3D = U.mat("sewer_iron", Color(0.24, 0.27, 0.32), 0.42, 0.78)
	var m_mad: StandardMaterial3D = U.mat("sewer_wood", Color(0.46, 0.30, 0.16), 0.85, 0.04)
	var m_lat: StandardMaterial3D = U.mat("sewer_brass", Color(0.90, 0.74, 0.26), 0.28, 0.85, Color(0.85, 0.68, 0.20), 0.45)
	var m_ll: StandardMaterial3D = U.mat("sewer_torch", Color(1.0, 0.76, 0.32), 0.20, 0.0, Color(1.0, 0.68, 0.22), 2.8)
	U.caja(muros, "LosaRocaSubterranea", Vector2.ZERO, Vector2(720.0, 320.0), 1.2, 0.8, m_roca)
	var techo: MeshInstance3D = U.caja(muros, "TechoRocaSubterranea", Vector2.ZERO, Vector2(720.0, 320.0), -U.PROFUNDIDAD_SOTANO_PX - 2.5, 2.0, m_roca)
	techo.add_to_group("techo_bajo_tierra_3d")
	_armar_camara(raiz, "BovedaInundada", Vector2(260.0, 63.0), m_lad, m_and, m_ag, m_fe, m_mad, m_lat, m_ll, false)
	_armar_camara(raiz, "PasadizoContrabandista", Vector2(420.0, 63.0), m_lad, m_and, m_ag, m_fe, m_mad, m_lat, m_ll, false)
	_armar_camara(raiz, "Cisterna", Vector2(580.0, 63.0), m_lad, m_and, m_ag, m_fe, m_mad, m_lat, m_ll, true)
	_armar_galerias(muros, m_lad, m_and, m_ag)
	var err: Error = U.guardar_escena(raiz, SALIDA_RED)
	raiz.free()
	if err == OK:
		err = _conectar_en_mapa()
	print("HORNEAR_ALCANTARILLAS: %s (err=%d)" % [SALIDA_RED, err])
	quit(0 if err == OK else 1)


func _armar_camara(raiz: Node3D, nombre: String, centro_abs: Vector2, m_lad: Material, m_and: Material, m_ag: Material, m_fe: Material, m_mad: Material, m_lat: Material, m_ll: Material, es_cisterna: bool) -> void:
	var c: Vector2 = centro_abs - CENTRO_RED
	var cam: Node3D = U.grupo(raiz, nombre, c)
	U.caja(cam, "SueloLadrillo", Vector2.ZERO, Vector2(110.0, 80.0), 2.0, 1.4, m_lad)
	U.caja(cam, "AndenSecoNorte", Vector2(0.0, -8.0), Vector2(106.0, 56.0), 3.4, 1.2, m_and)
	U.caja(cam, "CanalAguasTurbias", Vector2(0.0, 26.0), Vector2(106.0, 18.0), 2.6, 1.0, m_ag)
	U.caja(cam, "MuroNorteAlto", Vector2(0.0, -43.0), Vector2(116.0, 6.0), 3.0, 20.0, m_lad)
	U.caja(cam, "ZocaloSurBajo", Vector2(0.0, 43.0), Vector2(116.0, 6.0), 3.0, 5.0, m_lad)
	U.caja(cam, "MuroSurAlto1P", Vector2(0.0, 43.0), Vector2(116.0, 6.0), 8.0, 20.0, m_lad).add_to_group("techo_bajo_tierra_3d")
	var esc: Node3D = U.grupo(cam, "EscalerillaSalida", Vector2(-24.0, -24.0))
	U.caja(esc, "BaseHierro", Vector2(0.0, -2.0), Vector2(11.0, 8.0), 4.6, 0.8, m_fe)
	U.caja(esc, "LargueroIzq", Vector2(-4.0, -10.0), Vector2(1.4, 2.0), 4.6, 20.0, m_fe)
	U.caja(esc, "LargueroDer", Vector2(4.0, -10.0), Vector2(1.4, 2.0), 4.6, 20.0, m_fe)
	for i: int in range(6):
		U.caja(esc, "Peldano_%d" % (i + 1), Vector2(0.0, -10.0), Vector2(8.0, 1.2), 6.5 + float(i) * 3.0, 0.9, m_lat)
	var ant: Node3D = U.grupo(cam, "AntorchaMural", Vector2(-12.0, -37.0))
	U.cilindro(ant, "MangoMadera", Vector2.ZERO, 1.4, 13.0, 5.0, m_mad, 1.0, 6)
	U.cilindro(ant, "LlamaTea", Vector2.ZERO, 2.2, 18.0, 3.0, m_ll, 1.4, 8)
	U.luz_omni(ant, "LuzAntorcha", Vector2(0.0, 5.0), 19.0, Color(1.0, 0.78, 0.42), 1.35, 3.2)
	var cofre: Node3D = U.grupo(cam, "AlijoCofre", Vector2(24.0, -24.0))
	U.caja(cofre, "PedestalPiedra", Vector2.ZERO, Vector2(16.0, 12.0), 4.6, 1.4, m_lad)
	U.modelo(cofre, "CofreContrabando", "props/Chest_Wood.gltf", Vector2.ZERO, 6.0, Vector2(13.0, 9.5), 8.5)
	U.caja(cofre, "CerraduraLaton", Vector2(0.0, 4.6), Vector2(2.4, 1.4), 8.5, 2.6, m_lat)
	if es_cisterna:
		Renidero.armar(cam, m_mad, m_fe, m_lat)
		return
	U.modelo(cam, "BarrilAlijo", "props/Barrel.gltf", Vector2(-38.0, 6.0), 4.6, Vector2(9.0, 9.0), 9.5)
	U.modelo(cam, "CajaAlijo", "props/Crate_Wooden.gltf", Vector2(38.0, 6.0), 4.6, Vector2(11.0, 11.0), 8.5)


func _armar_galerias(muros: Node3D, m_lad: Material, m_and: Material, m_ag: Material) -> void:
	for info: Array in [["GaleriaOeste", -80.0], ["GaleriaEste", 80.0]]:
		var g: Node3D = U.grupo(muros, String(info[0]), Vector2(float(info[1]), 0.0))
		U.caja(g, "SueloPiedra", Vector2.ZERO, Vector2(56.0, 42.0), 2.0, 2.4, m_and)
		U.caja(g, "CanalAgua", Vector2(0.0, 14.0), Vector2(56.0, 10.0), 2.6, 1.0, m_ag)
		U.caja(g, "MuroNorte", Vector2(0.0, -23.0), Vector2(56.0, 6.0), 3.0, 18.0, m_lad)
		U.caja(g, "ZocaloSur", Vector2(0.0, 23.0), Vector2(56.0, 6.0), 3.0, 5.0, m_lad)
		U.caja(g, "MuroSur1P", Vector2(0.0, 23.0), Vector2(56.0, 6.0), 8.0, 20.0, m_lad).add_to_group("techo_bajo_tierra_3d")
	var nt := 0
	for sx: float in [-105.0, -55.0, 55.0, 105.0]:
		nt += 1
		U.caja(muros, "TabiqueNorte_%d" % nt, Vector2(sx, -32.0), Vector2(6.0, 22.0), 3.0, 20.0, m_lad)
		U.caja(muros, "TabiqueSur_%d" % nt, Vector2(sx, 32.0), Vector2(6.0, 22.0), 3.0, 5.0, m_lad)
		U.caja(muros, "TabiqueSur1P_%d" % nt, Vector2(sx, 32.0), Vector2(6.0, 22.0), 8.0, 20.0, m_lad).add_to_group("techo_bajo_tierra_3d")
	U.caja(muros, "MuroCierreOeste", Vector2(-218.0, 0.0), Vector2(6.0, 86.0), 3.0, 20.0, m_lad)
	U.caja(muros, "MuroCierreEste", Vector2(218.0, 0.0), Vector2(6.0, 86.0), 3.0, 20.0, m_lad)


func _conectar_en_mapa() -> Error:
	var mundo: Node = (load(ESCENA_MAPA) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var bt: Node3D = mundo.get_node("BajoTierra") as Node3D
	var vieja: Node3D = bt.get_node_or_null("Alcantarillas") as Node3D
	var pos_actual := Vector3(117.6, U.PROFUNDIDAD_SOTANO_PX * U.ALTO, 17.64)
	if vieja != null:
		pos_actual = Vector3(vieja.position.x, U.PROFUNDIDAD_SOTANO_PX * U.ALTO, vieja.position.z)
		vieja.owner = null
		bt.remove_child(vieja)
		vieja.free()
	var inst: Node3D = (load(SALIDA_RED) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node3D
	inst.name = "Alcantarillas"
	inst.position = pos_actual
	bt.add_child(inst)
	inst.owner = mundo
	var ps := PackedScene.new()
	var err: Error = ps.pack(mundo)
	if err == OK:
		err = ResourceSaver.save(ps, ESCENA_MAPA)
	mundo.free()
	return err
