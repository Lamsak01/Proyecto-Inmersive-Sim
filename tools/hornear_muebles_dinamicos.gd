extends SceneTree

## Hornea en escenas editables en metros los muebles dinámicos de casa/tienda, robos y mascotas.
const U = preload("res://tools/hornear_util_3d.gd")
const DIR_PROPS: String = "res://assests/curated_3d/props/"

func _initialize() -> void:
	var errs: Array[Error] = [
		_hornear_libro_cuentas(),
		_hornear_robos(),
		_hornear_casa_jugador(),
		_hornear_mostrador_y_bolsa(),
		_hornear_cama_mascota(true),
		_hornear_cama_mascota(false),
	]
	var fallos: int = 0
	for e: Error in errs:
		if e != OK:
			fallos += 1
	print("HORNEAR_MUEBLES_DINAMICOS: fallos=%d" % fallos)
	quit(0 if fallos == 0 else 1)


func _hornear_libro_cuentas() -> Error:
	var raiz := Node3D.new()
	raiz.name = "LibroCuentasAyuntamiento"
	var m_cuero: StandardMaterial3D = U.mat("ledger_leather", Color(0.40, 0.20, 0.10), 0.82, 0.05)
	var m_pag: StandardMaterial3D = U.mat("heist_page", Color(0.95, 0.90, 0.76), 0.85, 0.0)
	U.caja(raiz, "TapasCuero", Vector2.ZERO, Vector2(12.0, 8.0), 10.2, 1.0, m_cuero)
	U.caja(raiz, "PaginaIzquierda", Vector2(-2.9, 0.0), Vector2(5.4, 6.8), 11.2, 0.8, m_pag)
	U.caja(raiz, "PaginaDerecha", Vector2(2.9, 0.0), Vector2(5.4, 6.8), 11.2, 0.8, m_pag)
	var err: Error = U.guardar_escena(raiz, DIR_PROPS + "libro_cuentas_ayuntamiento.tscn")
	raiz.free()
	return err


func _hornear_robos() -> Error:
	var m_oro: StandardMaterial3D = U.mat("heist_gold", Color(0.96, 0.80, 0.28), 0.25, 0.85, Color(0.95, 0.76, 0.22), 0.65)
	var m_carmesi: StandardMaterial3D = U.mat("heist_crimson", Color(0.76, 0.14, 0.20), 0.75, 0.05)
	var sello := Node3D.new()
	sello.name = "ObjetivoRoboSello"
	U.caja(sello, "CojinTerciopelo", Vector2.ZERO, Vector2(11.0, 9.0), 10.2, 2.2, m_carmesi)
	U.cilindro(sello, "LacreReal", Vector2(-2.0, 0.5), 2.6, 12.4, 1.4, m_carmesi, 2.6, 10)
	U.cilindro(sello, "MatrizOroSello", Vector2(1.8, -0.5), 2.2, 12.4, 5.2, m_oro, 1.5, 10)
	U.modelo(sello, "PergaminoReal", "props/Scroll_1.gltf", Vector2(-5.0, -2.0), 10.2, Vector2(7.0, 5.0), 3.5)
	var e1: Error = U.guardar_escena(sello, DIR_PROPS + "objetivo_robo_sello.tscn")
	sello.free()
	var caliz := Node3D.new()
	caliz.name = "ObjetivoRoboCaliz"
	U.cilindro(caliz, "PatenaDorada", Vector2.ZERO, 4.4, 12.4, 0.8, m_oro, 4.4, 12)
	U.modelo(caliz, "CalizSagrado", "props/Chalice.gltf", Vector2.ZERO, 13.0, Vector2(8.0, 8.0), 8.5)
	var e2: Error = U.guardar_escena(caliz, DIR_PROPS + "objetivo_robo_caliz.tscn")
	caliz.free()
	var libro := Node3D.new()
	libro.name = "ObjetivoRoboLibro"
	U.modelo(libro, "LibroMayorGremios", "props/Book_5.gltf", Vector2.ZERO, 10.2, Vector2(13.0, 10.0), 4.5)
	U.caja(libro, "HerrajeOroIzquierdo", Vector2(-5.8, 0.0), Vector2(1.4, 8.8), 10.2, 3.6, m_oro)
	U.caja(libro, "HerrajeOroDerecho", Vector2(5.8, 0.0), Vector2(1.4, 8.8), 10.2, 3.6, m_oro)
	var e3: Error = U.guardar_escena(libro, DIR_PROPS + "objetivo_robo_libro.tscn")
	libro.free()
	return OK if (e1 == OK and e2 == OK and e3 == OK) else FAILED


func _hornear_casa_jugador() -> Error:
	var m_roble: StandardMaterial3D = U.mat("hp_oak", Color(0.46, 0.30, 0.16), 0.85, 0.05)
	var m_osc: StandardMaterial3D = U.mat("hp_dark", Color(0.14, 0.10, 0.06), 0.95, 0.0)
	var m_fe: StandardMaterial3D = U.mat("hp_iron", Color(0.28, 0.32, 0.36), 0.45, 0.75)
	var m_oro: StandardMaterial3D = U.mat("hp_gold", Color(0.95, 0.78, 0.24), 0.25, 0.85, Color(0.92, 0.74, 0.20), 0.55)
	var m_hierba: StandardMaterial3D = U.mat("hp_herb", Color(0.30, 0.82, 0.38), 0.45, 0.10, Color(0.20, 0.65, 0.28), 0.35)
	var m_polvo: StandardMaterial3D = U.mat("hp_dust", Color(0.74, 0.44, 0.96), 0.30, 0.15, Color(0.66, 0.36, 0.90), 0.55)
	var mesa := Node3D.new()
	mesa.name = "MesaCasaJugador"
	U.caja(mesa, "CuerpoMesa", Vector2.ZERO, Vector2(18.0, 10.6), 2.0, 6.2, m_roble)
	U.caja(mesa, "TableroMesa", Vector2.ZERO, Vector2(19.4, 11.6), 7.8, 1.0, m_roble)
	var viandas: Node3D = U.grupo(mesa, "ViandasMesa")
	U.cilindro(viandas, "HogazaPan", Vector2(-3.2, -0.5), 2.2, 8.8, 1.4, m_oro, 2.0, 8)
	U.cilindro(viandas, "CuencoGuiso", Vector2(3.2, 0.5), 2.0, 8.8, 2.0, m_hierba, 1.6, 8)
	var e1: Error = U.guardar_escena(mesa, DIR_PROPS + "mesa_casa_jugador.tscn")
	mesa.free()
	var banco := Node3D.new()
	banco.name = "BancoTrabajoCasa"
	U.modelo(banco, "BancoCarpintero", "props/Workbench_Drawers.gltf", Vector2.ZERO, 2.0, Vector2(18.0, 10.0), 8.2)
	U.cilindro(banco, "MorteroCataplasma", Vector2(-4.0, -0.5), 2.2, 9.5, 2.6, m_hierba, 1.8, 8)
	U.cilindro(banco, "AlambiquePolvoOcaso", Vector2(3.5, -0.5), 2.0, 9.5, 3.8, m_polvo, 1.0, 10)
	var e2: Error = U.guardar_escena(banco, DIR_PROPS + "banco_trabajo_casa.tscn")
	banco.free()
	var alijo := Node3D.new()
	alijo.name = "EsconditeSueloCasa"
	U.caja(alijo, "HuecoBajoSuelo", Vector2.ZERO, Vector2(13.0, 9.5), 1.8, 0.8, m_osc)
	U.caja(alijo, "TablaIzquierda", Vector2(-3.2, 0.0), Vector2(4.2, 8.8), 2.2, 1.2, m_roble)
	U.caja(alijo, "TablaEntreabierta", Vector2(3.4, -0.6), Vector2(4.2, 8.8), 2.6, 1.4, m_roble)
	U.cilindro(alijo, "MonedasOcultas", Vector2(0.0, 0.8), 2.2, 2.2, 1.2, m_oro, 2.2, 8)
	var e3: Error = U.guardar_escena(alijo, DIR_PROPS + "escondite_suelo_casa.tscn")
	alijo.free()
	var esc := Node3D.new()
	esc.name = "EscaleraTrampillaCasa"
	U.caja(esc, "MarcoTrampilla", Vector2.ZERO, Vector2(13.0, 14.0), 1.8, 1.2, m_osc)
	U.caja(esc, "TapaRoble", Vector2.ZERO, Vector2(11.6, 12.6), 2.4, 1.4, m_roble)
	U.caja(esc, "ArgollaHierro", Vector2(4.0, 0.0), Vector2(1.8, 1.8), 3.6, 1.2, m_fe)
	var peldanos: Node3D = U.grupo(esc, "PeldanosAltillo")
	for i: int in range(4):
		U.caja(peldanos, "Peldano_%d" % (i + 1), Vector2(0.0, -4.5 + float(i) * 3.0), Vector2(10.0, 2.2), 4.0 + float(i) * 4.2, 1.6, m_roble)
	var e4: Error = U.guardar_escena(esc, DIR_PROPS + "escalera_trampilla_casa.tscn")
	esc.free()
	return OK if (e1 == OK and e2 == OK and e3 == OK and e4 == OK) else FAILED


func _hornear_mostrador_y_bolsa() -> Error:
	var m_roble: StandardMaterial3D = U.mat("hp_oak", Color(0.46, 0.30, 0.16), 0.85, 0.05)
	var m_fe: StandardMaterial3D = U.mat("hp_iron", Color(0.28, 0.32, 0.36), 0.45, 0.75)
	var m_oro: StandardMaterial3D = U.mat("hp_gold", Color(0.95, 0.78, 0.24), 0.25, 0.85, Color(0.92, 0.74, 0.20), 0.55)
	var m_hierba: StandardMaterial3D = U.mat("hp_herb", Color(0.30, 0.82, 0.38), 0.45, 0.10, Color(0.20, 0.65, 0.28), 0.35)
	var most := Node3D.new()
	most.name = "MostradorTiendaJugador"
	U.caja(most, "CuerpoMostrador", Vector2.ZERO, Vector2(18.0, 9.2), 2.0, 6.8, m_roble)
	U.caja(most, "TableroMostrador", Vector2.ZERO, Vector2(19.6, 10.4), 8.6, 1.2, m_roble)
	U.caja(most, "CajaRecaudacion", Vector2(4.6, -0.2), Vector2(5.2, 4.4), 9.8, 2.6, m_fe)
	U.cilindro(most, "MonedasCaja", Vector2(4.6, -0.2), 1.8, 12.2, 1.2, m_oro, 1.8, 8)
	U.caja(most, "Mercancia_1", Vector2(-4.8, -0.4), Vector2(3.8, 3.6), 9.8, 2.4, m_hierba)
	U.caja(most, "Mercancia_2", Vector2(-1.2, 0.4), Vector2(3.6, 3.4), 9.8, 2.2, m_oro)
	var e1: Error = U.guardar_escena(most, DIR_PROPS + "mostrador_tienda_jugador.tscn")
	most.free()
	var bolsa := Node3D.new()
	bolsa.name = "BolsaObjetoCaido"
	U.cilindro(bolsa, "ZurronCuero", Vector2.ZERO, 3.4, 0.0, 4.2, U.mat("dropped_pouch_3d", Color(0.68, 0.52, 0.32), 0.85, 0.05), 2.0, 8)
	var e2: Error = U.guardar_escena(bolsa, DIR_PROPS + "bolsa_objeto_caido.tscn")
	bolsa.free()
	return OK if (e1 == OK and e2 == OK) else FAILED


func _hornear_cama_mascota(es_perro: bool) -> Error:
	var raiz := Node3D.new()
	raiz.name = "CamaMascotaPerro" if es_perro else "CamaMascotaGato"
	var m_mad: StandardMaterial3D = U.mat("pet_bed_wood", Color(0.46, 0.30, 0.16), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.75)
	var col_cojin: Color = Color(0.74, 0.28, 0.24) if es_perro else Color(0.72, 0.54, 0.38)
	var m_cojin: StandardMaterial3D = U.mat("pet_bed_dog" if es_perro else "pet_bed_cat", col_cojin, 0.92, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.65)
	var m_cuenco: StandardMaterial3D = U.mat("pet_bowl_brass", Color(0.82, 0.68, 0.30), 0.38, 0.65)
	var m_agua: StandardMaterial3D = U.mat("pet_bowl_water", Color(0.22, 0.56, 0.82), 0.20, 0.10)
	U.caja(raiz, "BastidorMadera", Vector2.ZERO, Vector2(19.0, 11.0), 0.0, 2.2, m_mad)
	U.caja(raiz, "RespaldoNorte", Vector2(0.0, -4.8), Vector2(19.0, 1.8), 2.2, 2.0, m_mad)
	U.caja(raiz, "BrazoOeste", Vector2(-8.6, 0.0), Vector2(1.8, 11.0), 2.2, 1.8, m_mad)
	U.caja(raiz, "BrazoEste", Vector2(8.6, 0.0), Vector2(1.8, 11.0), 2.2, 1.8, m_mad)
	U.caja(raiz, "CojinTela", Vector2(0.0, 0.5), Vector2(15.0, 7.6), 1.8, 1.8, m_cojin)
	U.cilindro(raiz, "CuencoLaton", Vector2(13.5, 1.0), 2.8, 0.0, 2.2, m_cuenco, 2.4, 10)
	U.cilindro(raiz, "AguaCuenco", Vector2(13.5, 1.0), 2.1, 1.6, 0.8, m_agua, 2.1, 10)
	var archivo: String = "cama_mascota_perro.tscn" if es_perro else "cama_mascota_gato.tscn"
	var err: Error = U.guardar_escena(raiz, DIR_PROPS + archivo)
	raiz.free()
	return err
