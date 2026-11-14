extends SceneTree

## Hornea en escenas editables en metros los objetos de exterior, caminos y naturaleza:
## cajas, barriles, muros débiles, postes indicadores, hierbas, setas, madrigueras y cubiles.

const U = preload("res://tools/hornear_util_3d.gd")
const DIR_EXT: String = "res://assests/curated_3d/exterior/"
const DIR_NAT: String = "res://assests/curated_3d/nature/"


func _initialize() -> void:
	var errs: Array[Error] = [
		_hornear_caja_y_barril(),
		_hornear_muro_y_poste(),
		_hornear_flora_y_madrigueras(),
	]
	var fallos: int = 0
	for e: Error in errs:
		if e != OK:
			fallos += 1
	print("HORNEAR_OBJETOS_CAMPO: fallos=%d" % fallos)
	quit(0 if fallos == 0 else 1)


func _hornear_caja_y_barril() -> Error:
	var caja := Node3D.new()
	caja.name = "CajaMaderaExterior"
	U.modelo(caja, "CajaMadera", "exterior/Crate.obj", Vector2.ZERO, 0.0, Vector2(14.0, 14.0), 12.0)
	var e1: Error = U.guardar_escena(caja, DIR_EXT + "caja_madera_prop.tscn")
	caja.free()
	var barril := Node3D.new()
	barril.name = "BarrilMaderaExterior"
	U.modelo(barril, "BarrilMadera", "props/Barrel.gltf", Vector2.ZERO, 0.0, Vector2(13.0, 13.0), 13.0)
	var e2: Error = U.guardar_escena(barril, DIR_EXT + "barril_madera_prop.tscn")
	barril.free()
	return OK if (e1 == OK and e2 == OK) else FAILED


func _hornear_muro_y_poste() -> Error:
	var m_muro: StandardMaterial3D = U.mat("weak_wall_stone", Color(0.56, 0.54, 0.50), 0.90, 0.02, Color.BLACK, 0.0, "town_textures/wall_stone.png", "", 0.70)
	var muro := Node3D.new()
	muro.name = "MuroDebilPiedra"
	U.caja(muro, "ZocaloPiedra", Vector2.ZERO, Vector2(18.0, 28.0), 0.0, 2.0, m_muro)
	U.caja(muro, "TramoNorte", Vector2(0.0, -4.0), Vector2(10.0, 18.0), 2.0, 12.0, m_muro)
	U.caja(muro, "TramoSurAgrietado", Vector2(0.0, 7.0), Vector2(10.0, 8.0), 2.0, 7.5, m_muro)
	var e1: Error = U.guardar_escena(muro, DIR_EXT + "muro_debil_piedra.tscn")
	muro.free()
	var m_mad: StandardMaterial3D = U.mat("prop_wood", Color(0.54, 0.36, 0.20), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_osc: StandardMaterial3D = U.mat("prop_dark_wood", Color(0.38, 0.24, 0.13), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var poste := Node3D.new()
	poste.name = "PosteCartelCamino"
	U.caja(poste, "BaseMadera", Vector2(0.0, 4.0), Vector2(12.5, 5.2), 0.0, 2.2, m_osc)
	U.caja(poste, "PosteIzquierdo", Vector2(-4.5, 4.0), Vector2(2.4, 2.6), 0.0, 14.5, m_osc)
	U.caja(poste, "PosteDerecho", Vector2(4.5, 4.0), Vector2(2.4, 2.6), 0.0, 14.5, m_osc)
	U.caja(poste, "TablaCartel", Vector2(0.0, 4.4), Vector2(16.5, 3.4), 6.2, 7.6, m_mad)
	U.prisma(poste, "TejadilloMadera", Vector2(0.0, 4.2), Vector2(18.5, 5.8), 13.6, 3.6, m_osc, false)
	var e2: Error = U.guardar_escena(poste, DIR_EXT + "poste_cartel_camino.tscn")
	poste.free()
	return OK if (e1 == OK and e2 == OK) else FAILED


func _hornear_flora_y_madrigueras() -> Error:
	var hierba := Node3D.new()
	hierba.name = "MataHierbaSilvestre"
	U.modelo(hierba, "FloresSilvestres", "nature/Flowers.obj", Vector2.ZERO, -0.5, Vector2(12.0, 12.0), 7.5)
	var e1: Error = U.guardar_escena(hierba, DIR_NAT + "mata_hierba_silvestre.tscn")
	hierba.free()
	var m_pie: StandardMaterial3D = U.mat("mush_stem_3d", Color(0.92, 0.88, 0.78), 0.88, 0.0)
	var m_som: StandardMaterial3D = U.mat("mush_cap_3d", Color(0.82, 0.24, 0.18), 0.78, 0.0)
	var setas := Node3D.new()
	setas.name = "GrupoSetasSilvestres"
	var ns: int = 0
	for m_off: Vector2 in [Vector2(-2.2, 0.8), Vector2(2.4, -1.2), Vector2(0.2, -2.0)]:
		ns += 1
		var sc: float = 1.0 if m_off.x < 0.0 else 0.75
		U.cilindro(setas, "PieSeta_%d" % ns, m_off, 1.1 * sc, -0.4, 3.4 * sc, m_pie, 0.9 * sc, 7)
		U.cilindro(setas, "SombreroSeta_%d" % ns, m_off, 2.8 * sc, 2.6 * sc, 2.2 * sc, m_som, 0.6 * sc, 8)
	var e2: Error = U.guardar_escena(setas, DIR_NAT + "grupo_setas_silvestres.tscn")
	setas.free()
	var m_tierra: StandardMaterial3D = U.mat("burrow_earth_3d", Color(0.42, 0.30, 0.19), 0.95, 0.0)
	var m_boca: StandardMaterial3D = U.mat("burrow_hole_3d", Color(0.08, 0.06, 0.05), 0.98, 0.0)
	var m_roca: StandardMaterial3D = U.mat("fox_den_rock_3d", Color(0.46, 0.43, 0.39), 0.92, 0.02)
	var madriguera := Node3D.new()
	madriguera.name = "MadrigueraConejo"
	U.cilindro(madriguera, "MonticuloTierra", Vector2.ZERO, 8.5, -0.8, 3.2, m_tierra, 5.2, 10)
	U.cilindro(madriguera, "BocaMadriguera", Vector2(0.0, 1.0), 4.2, 1.6, 1.0, m_boca, 3.8, 8)
	var e3: Error = U.guardar_escena(madriguera, DIR_NAT + "madriguera_conejo.tscn")
	madriguera.free()
	var cubil := Node3D.new()
	cubil.name = "CubilZorro"
	U.cilindro(cubil, "LomaTierra", Vector2.ZERO, 11.5, -1.0, 5.5, m_tierra, 7.5, 10)
	U.caja(cubil, "RocaAbrigo", Vector2(0.0, -3.0), Vector2(14.0, 9.0), 0.0, 6.8, m_roca)
	U.cilindro(cubil, "BocaCubil", Vector2(0.0, 2.2), 5.2, 1.2, 2.4, m_boca, 4.6, 8)
	var e4: Error = U.guardar_escena(cubil, DIR_NAT + "cubil_zorro.tscn")
	cubil.free()
	return OK if (e1 == OK and e2 == OK and e3 == OK and e4 == OK) else FAILED
