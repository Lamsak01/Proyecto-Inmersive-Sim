extends RefCounted

## Arma el reñidero subterráneo de la Cisterna (cuadrilátero de serrín y cuerdas, bancos del público,
## mesa del apostador con monedas y pizarra, y pintada que remite al sótano de la posada) para
## tools/hornear_alcantarillas.gd. Todo con nombres descriptivos en metros.

const U = preload("res://tools/hornear_util_3d.gd")


static func armar(cam: Node3D, m_mad: Material, m_fe: Material, m_lat: Material) -> void:
	var ren: Node3D = U.grupo(cam, "Renidero")
	var suelo: float = 4.6
	var m_cuerda: StandardMaterial3D = U.mat("sewer_rope", Color(0.72, 0.60, 0.36), 0.92, 0.0)
	var m_serrin: StandardMaterial3D = U.mat("sewer_sawdust", Color(0.46, 0.33, 0.20), 0.95, 0.0)
	var m_sangre: StandardMaterial3D = U.mat("sewer_blood", Color(0.30, 0.08, 0.06), 0.90, 0.0)
	var m_pizarra: StandardMaterial3D = U.mat("sewer_slate", Color(0.10, 0.11, 0.10), 0.85, 0.0)
	var m_tiza: StandardMaterial3D = U.mat("sewer_chalk", Color(0.92, 0.92, 0.88), 0.80, 0.0)
	U.caja(ren, "SueloSerrin", Vector2(0.0, -8.0), Vector2(34.0, 26.0), suelo, 0.3, m_serrin)
	var manchas: Array[Array] = [[Vector2(-5.0, -12.0), 18.0], [Vector2(7.0, -3.0), 42.0], [Vector2(2.0, 2.0), 9.0]]
	for i: int in range(manchas.size()):
		U.caja(ren, "ManchaSangre_%d" % (i + 1), manchas[i][0], Vector2(3.5, 2.5), suelo + 0.32, 0.1, m_sangre, float(manchas[i][1]))
	var np := 0
	for px: float in [-17.0, 17.0]:
		for py: float in [-21.0, 5.0]:
			np += 1
			U.cilindro(ren, "PosteCorro_%d" % np, Vector2(px, py), 1.1, suelo, 11.0, m_mad, 1.1, 6)
		var lado: String = "O" if px < 0.0 else "E"
		U.caja(ren, "CuerdaLateralBaja_%s" % lado, Vector2(px, -8.0), Vector2(0.7, 26.0), suelo + 5.0, 0.7, m_cuerda)
		U.caja(ren, "CuerdaLateralAlta_%s" % lado, Vector2(px, -8.0), Vector2(0.7, 26.0), suelo + 9.0, 0.7, m_cuerda)
	for py: float in [-21.0, 5.0]:
		var suf: String = "N" if py < 0.0 else "S"
		U.caja(ren, "CuerdaFondoBaja_%s" % suf, Vector2(0.0, py), Vector2(34.0, 0.7), suelo + 5.0, 0.7, m_cuerda)
		U.caja(ren, "CuerdaFondoAlta_%s" % suf, Vector2(0.0, py), Vector2(34.0, 0.7), suelo + 9.0, 0.7, m_cuerda)
	for b_info: Array in [["BancoNorte", Vector2(0.0, -34.0), Vector2(26.0, 5.0)], ["BancoOeste", Vector2(-38.0, -8.0), Vector2(5.0, 24.0)]]:
		var b_grp: Node3D = U.grupo(ren, String(b_info[0]), b_info[1])
		var tam_b: Vector2 = b_info[2]
		U.caja(b_grp, "TablaAsiento", Vector2.ZERO, tam_b, suelo + 3.5, 1.2, m_mad)
		var hb: Vector2 = tam_b * 0.5 - Vector2(1.5, 1.5)
		var ip := 0
		for esq: Vector2 in [Vector2(-hb.x, -hb.y), Vector2(hb.x, -hb.y), Vector2(-hb.x, hb.y), Vector2(hb.x, hb.y)]:
			ip += 1
			U.caja(b_grp, "Pata_%d" % ip, esq, Vector2(1.4, 1.4), suelo, 3.5, m_mad)
	var mesa: Node3D = U.grupo(ren, "MesaApostador", Vector2(37.0, -6.0))
	U.caja(mesa, "TableroMesa", Vector2.ZERO, Vector2(12.0, 9.0), suelo + 6.0, 1.0, m_mad)
	var ipm := 0
	for pata: Vector2 in [Vector2(-5.0, -3.5), Vector2(5.0, -3.5), Vector2(-5.0, 3.5), Vector2(5.0, 3.5)]:
		ipm += 1
		U.caja(mesa, "Pata_%d" % ipm, pata, Vector2(1.2, 1.2), suelo, 6.0, m_mad)
	var imo := 0
	for mon: Vector2 in [Vector2(-2.5, -1.0), Vector2(1.0, 1.5), Vector2(3.0, -2.0)]:
		imo += 1
		U.cilindro(mesa, "Monedas_%d" % imo, mon, 0.9, suelo + 7.0, 0.3, m_lat, 0.9, 8)
	U.caja(mesa, "CajaApuestas", Vector2(0.0, 2.0), Vector2(3.0, 2.0), suelo + 7.0, 1.2, m_fe)
	var piz: Node3D = U.grupo(ren, "PizarraApuestas", Vector2(53.0, -8.0))
	U.caja(piz, "LosaPizarra", Vector2.ZERO, Vector2(1.0, 16.0), suelo + 8.0, 10.0, m_pizarra)
	for r: int in range(4):
		U.caja(piz, "RayaTiza_%d" % (r + 1), Vector2(-0.7, -5.0 + float(r) * 3.2), Vector2(0.4, 8.0 - float(r) * 1.5), suelo + 15.5 - float(r) * 2.0, 0.5, m_tiza)
	var pintada := Label3D.new()
	pintada.name = "PintadaMuroNorte"
	pintada.text = "PELEAS · SÓTANO DEL JABALÍ\nNOCHES PARES · A LAS 23"
	pintada.font_size = 48
	pintada.pixel_size = 0.0022 * U.K
	pintada.modulate = Color(0.90, 0.88, 0.80, 0.85)
	pintada.position = U.pos_m(Vector2(0.0, -39.0), suelo + 12.0)
	ren.add_child(pintada, true)
	U.luz_omni(ren, "LuzRenidero", Vector2(0.0, -8.0), 18.0, Color(1.0, 0.72, 0.40), 1.2, 3.0)
