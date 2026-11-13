extends RefCounted

## Dibuja dentro de su pieza cada cosa armada a mano de un plano de casa («cosa» en MUEBLES), 2026-11-13: busca quién
## la sabe hacer según el nivel de la casa (de todas, pobre, de oficio, acomodada o señorial). Lo usa tools/casas/armar_casa.gd.

const Cascaron = preload("res://tools/casas/cascaron_casa.gd")
const Cosas = preload("res://tools/casas/cosas_casa.gd")
const Pobre = preload("res://tools/casas/cosas_casa_pobre.gd")
const Oficio = preload("res://tools/casas/cosas_oficio.gd")
const Acomodada = preload("res://tools/casas/cosas_casa_acomodada.gd")
const Senorial = preload("res://tools/casas/cosas_casa_senorial.gd")


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
