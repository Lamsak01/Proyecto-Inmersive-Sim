extends RefCounted

## Dibuja dentro de su pieza cada cosa armada a mano de un plano de casa («cosa» en MUEBLES), 2026-11-13: busca quién
## la sabe hacer según el nivel de la casa (de todas, pobre, de oficio, acomodada, señorial o del molino). Lo usa tools/casas/armar_casa.gd.

const Cascaron = preload("res://tools/casas/cascaron_casa.gd")
const Cosas = preload("res://tools/casas/cosas_casa.gd")
const Pobre = preload("res://tools/casas/cosas_casa_pobre.gd")
const Oficio = preload("res://tools/casas/cosas_oficio.gd")
const Acomodada = preload("res://tools/casas/cosas_casa_acomodada.gd")
const Senorial = preload("res://tools/casas/cosas_casa_senorial.gd")
const Molino = preload("res://tools/casas/cosas_molino.gd")
const Restaurante = preload("res://tools/casas/cosas_restaurante.gd")


static func dibujar(pieza: Node3D, m: Dictionary) -> void:
	match String(m["cosa"]):
		"alfombra":
			Cosas.alfombra(pieza, m["tam2"], m["color"])
		"bombilla":
			Cosas.bombilla(pieza, Cascaron.MURO_ALTO_M - Cascaron.SUELO_Y_M)
		"estufa":
			Cosas.estufa(pieza)
		"pila_con_bomba":
			Cosas.pila_con_bomba(pieza)
		"banera":
			Cosas.banera(pieza)
		"radio":
			Cosas.radio(pieza)
		"palangana":
			Cosas.palangana(pieza)
		"letrina":
			Cosas.letrina(pieza)
		"hogar":
			Pobre.hogar(pieza)
		"hogar_frio":
			Pobre.hogar(pieza, false)
		"foso_reja":
			Molino.foso_reja(pieza)
		"muela_rota":
			Molino.muela_rota(pieza)
		"cordel":
			Molino.cordel(pieza, float(m.get("alto", 0.0)))
		"papel":
			Molino.papel(pieza, float(m.get("alto", 0.0)))
		"lena":
			Pobre.lena(pieza)
		"vela":
			Pobre.vela(pieza, float(m.get("alto", 0.0)))
		"tina":
			Pobre.tina(pieza)
		"tajo":
			Pobre.tajo(pieza)
		"horno":
			Oficio.horno(pieza)
		"mesa_morgue":
			Oficio.mesa_morgue(pieza)
		"pizarra":
			Oficio.pizarra(pieza)
		"banco_cantero":
			Oficio.banco_cantero(pieza)
		"sillares_piedra":
			Oficio.sillares_piedra(pieza)
		"terraza_trattoria":
			Restaurante.terraza_trattoria(pieza)
		"mesa_terraza_verde":
			Restaurante.mesa_terraza(pieza, true)
		"mesa_terraza_crema":
			Restaurante.mesa_terraza(pieza, false)
		"mantel_trattoria":
			Restaurante.mantel_trattoria(pieza)
		"piano_vertical":
			Restaurante.piano_vertical(pieza)
		"fogones_trattoria":
			Restaurante.fogones_trattoria(pieza)
		"camara_fria":
			Restaurante.camara_fria(pieza)
		"mesa_reservado":
			Restaurante.mesa_reservado(pieza)
		"ventilador":
			Acomodada.ventilador(pieza, Cascaron.MURO_ALTO_M - Cascaron.SUELO_Y_M)
		"inodoro":
			Acomodada.inodoro(pieza)
		"lavabo":
			Acomodada.lavabo(pieza)
		"fregadero":
			Acomodada.fregadero(pieza)
		"tocadiscos":
			Acomodada.tocadiscos(pieza)
		"terminal":
			Acomodada.terminal(pieza)
		"generador":
			Acomodada.generador(pieza)
		"cable":
			Acomodada.cable(pieza, m["medida"], float(m.get("alto", 0.0)))
		"cuadro_electrico":
			Acomodada.cuadro_electrico(pieza)
		"radio_galena":
			Pobre.radio_galena(pieza)
		"linterna":
			Pobre.linterna(pieza)
		"telefono":
			Senorial.telefono(pieza, float(m.get("alto", 0.0)))
		"nevera":
			Senorial.nevera(pieza)
		"lampara":
			Senorial.lampara(pieza, Cascaron.MURO_ALTO_M - Cascaron.SUELO_Y_M)
		"chimenea":
			Senorial.chimenea(pieza)
		"candelabro":
			Senorial.candelabro(pieza, float(m.get("alto", 0.0)))
		"retrato":
			Senorial.retrato(pieza)
		var otra:
			push_error("CASA: no sé armar «%s»" % otra)
