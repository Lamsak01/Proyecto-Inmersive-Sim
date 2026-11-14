extends RefCounted

## Catálogo de nombres y agrupaciones en español para las 416 piezas de «Decorado» en mapa/Mundo3D.tscn.
## Cada entrada devuelve [grupo_padre, nombre_pieza, zona_forzada] según el índice original (1..408) o nombre previo.


static func clasificar(nombre_viejo: String) -> Array[String]:
	if nombre_viejo.begins_with("Arbol_adorno_"):
		var na: int = int(nombre_viejo.trim_prefix("Arbol_adorno_"))
		if na <= 6:
			return ["", "Arbol_Adorno_Cementerio_%d" % na, ""]
		if na == 8:
			return ["", "Arbol_Adorno_Plaza", ""]
		return ["", "Arbol_Adorno_Parque", ""]
	var guion: int = nombre_viejo.rfind("_")
	var id: int = int(nombre_viejo.substr(guion + 1)) if guion >= 0 else -1
	if id <= 0:
		return ["", nombre_viejo, ""]
	if id == 1:
		return ["", "Molino_Viento_Este", ""]
	if id >= 2 and id <= 4:
		return ["", "Lenero_Caserio_%d" % (id - 1), ""]
	if id == 5:
		return ["", "Mojon_Cartel_Entrada", ""]
	if id >= 6 and id <= 25:
		return ["Calleja_Curva_Sur", "Tramo_%02d" % (id - 5), ""]
	if id >= 26 and id <= 48:
		return ["Calleja_Curva_Norte", "Tramo_%02d" % (id - 25), ""]
	return _clasificar_pueblo_y_rio(id, nombre_viejo)


static func _clasificar_pueblo_y_rio(id: int, nombre_viejo: String) -> Array[String]:
	if id == 49:
		return ["Bordillos_Plaza_Central", "Bordillo_Norte", "Zona_1_0"]
	if id == 50:
		return ["Bordillos_Plaza_Central", "Bordillo_Sur", "Zona_1_0"]
	if id == 51 or id == 52:
		return ["Bordillos_Acceso_Plaza_Oeste", "Bordillo_Norte" if id == 51 else "Bordillo_Sur", "Zona_0_0"]
	if id == 53 or id == 54:
		return ["Bordillos_Plaza_Central", "Bordillo_Este_Norte" if id == 53 else "Bordillo_Este_Sur", "Zona_1_0"]
	if id == 55 or id == 56:
		return ["Bordillos_Subida_Este", "Bordillo_Norte" if id == 55 else "Bordillo_Sur", "Zona_1_0"]
	if id == 57 or id == 58:
		return ["", "Banco_Plaza_Oeste" if id == 57 else "Banco_Plaza_Este", ""]
	if id == 59:
		return ["", "Tablon_Encargos_Plaza", ""]
	if id >= 60 and id <= 65:
		var np1: String = "Tierra_Arada" if id == 60 else "Surcos_Trigo_%d" % (id - 60)
		return ["Huerto_Granja_Oeste", np1, "Zona_-1_1"]
	if id >= 66 and id <= 71:
		var np2: String = "Tierra_Arada" if id == 66 else "Surcos_Trigo_%d" % (id - 66)
		return ["Huerto_Granja_Este", np2, "Zona_0_1"]
	if id == 72:
		return ["", "Explanada_Roca_Cantera", ""]
	if id >= 73 and id <= 105:
		return ["Corral_Rancho_Sur", _nombre_parte_corral(id), "Zona_0_1"]
	if id >= 106 and id <= 111:
		var partes_parque: Array[String] = ["Cesped", "Bordillo_Norte", "Bordillo_Sur", "Bordillo_Oeste", "Bordillo_Este", "Paseos_Cruz"]
		return ["Recinto_Parque_Roble", partes_parque[id - 106], "Zona_0_0"]
	if id == 112 or id == 113:
		return ["", "Banco_Parque_Oeste" if id == 112 else "Banco_Parque_Este", ""]
	if id >= 114 and id <= 118:
		return ["", "Macetero_Parque_%d" % (id - 113), ""]
	if id >= 119 and id <= 123:
		var nm: String = "Banco_Mirador" if id == 123 else "Barandilla_Tramo_%d" % (id - 118)
		return ["Mirador_Lago", nm, "Zona_-2_0"]
	if id >= 124 and id <= 129:
		var partes_lav: Array[String] = ["Pila_Piedra_Agua", "Poste_Noroeste", "Poste_Noreste", "Poste_Suroeste", "Poste_Sureste", "Tejado_Cubo_Barril"]
		return ["Lavadero_Municipal", partes_lav[id - 124], "Zona_0_0"]
	return _clasificar_cementerio_y_rio(id, nombre_viejo)


static func _clasificar_cementerio_y_rio(id: int, nombre_viejo: String) -> Array[String]:
	if id == 130:
		return ["", "Muelle_Lago", ""]
	if id >= 131 and id <= 138:
		return ["", "Mata_Orilla_Cienaga_%d" % (id - 130), ""]
	if id >= 139 and id <= 157:
		return ["Recinto_Cementerio", _nombre_parte_cementerio(id), "Zona_2_0"]
	if id >= 158 and id <= 181:
		var idx_t: int = id - 158
		return ["", "Tumba_Fila%d_%d" % [idx_t / 6 + 1, idx_t % 6 + 1], ""]
	if id >= 182 and id <= 184:
		var rejas: Array[String] = ["Rejilla_Alcantarilla_Plaza", "Rejilla_Alcantarilla_Callejon", "Rejilla_Alcantarilla_Rio"]
		return ["", rejas[id - 182], ""]
	if id >= 185 and id <= 192:
		return ["Sendero_Arroyo_Norte", "Tramo_%d" % (id - 184), ""]
	if id >= 193 and id <= 341:
		var es_junco: bool = nombre_viejo.begins_with("Cilindro_") or id in [201, 218, 228, 238, 240, 241, 245, 246, 249, 252, 253, 257, 258, 261, 264, 265, 269, 270, 273, 276, 277, 281, 282, 285, 286, 289, 292, 293, 298, 299, 303, 304, 307, 310, 311, 321, 331, 336]
		return ["Juncos_Orilla_Rio" if es_junco else "Cantos_Orilla_Rio", ("Mata_Juncos_%03d" if es_junco else "Canto_Orilla_%03d") % id, ""]
	if id >= 342 and id <= 349:
		return ["", "Banco_Lodo_Meandro_%d" % (id - 341), ""]
	if id >= 350 and id <= 357:
		return ["", "Tronco_Musgoso_Claro_%d" % (id - 349), ""]
	if id >= 358 and id <= 382:
		return ["Puente_Viejo", _nombre_parte_puente_viejo(id), "Zona_0_0"]
	if id == 383:
		return ["", "Zapato_Victima_Caso1", "Zona_0_0"]
	if id == 384:
		return ["", "Vado_Piedras_Claro", ""]
	if id >= 385 and id <= 394:
		return ["Pasarela_Calle_Norte", "Pieza_Pasarela_%02d" % (id - 384), "Zona_0_-1"]
	if id >= 395 and id <= 404:
		return ["Puente_Campos_Sur", "Pieza_Puente_%02d" % (id - 394), "Zona_0_0"]
	if id == 405 or id == 406:
		return ["Vado_Piedras_Bosque_Sur", "Losas_Oeste" if id == 405 else "Losas_Este", "Zona_0_2"]
	if id == 407:
		return ["", "Tronco_Puente_Bosque_Sur", ""]
	return ["", "Tarima_Pesca_Rio", ""]


static func _nombre_parte_corral(id: int) -> String:
	if id == 73:
		return "Suelo_Tierra"
	if id <= 80:
		return "Valla_Norte_%d" % (id - 73)
	if id <= 88:
		return "Valla_Este_%d" % (id - 80)
	if id <= 95:
		return "Valla_Sur_%d" % (id - 88)
	if id <= 103:
		return "Valla_Oeste_%d" % (id - 95)
	return "Abrevadero" if id == 104 else "Pacas_Heno"


static func _nombre_parte_cementerio(id: int) -> String:
	var fijos: Dictionary = {
		139: "Suelo_Cementerio", 140: "Camino_Norte_Sur", 141: "Camino_Este_Oeste",
		142: "Muro_Verja_Sur", 143: "Muro_Verja_Oeste", 144: "Muro_Verja_Este",
		145: "Muro_Verja_Norte_Izq", 146: "Muro_Verja_Norte_Der", 157: "Puerta_Hierro_Norte",
	}
	if fijos.has(id):
		return String(fijos[id])
	return "Pilar_Perimetro_%02d" % (id - 146)


static func _nombre_parte_puente_viejo(id: int) -> String:
	var p: Array[String] = [
		"Estribo_Oeste", "Estribo_Este", "Pilar_Tajamar_Oeste", "Pilar_Tajamar_Este",
		"Arco_Norte_Oeste", "Arco_Sur_Oeste", "Arco_Norte_Centro", "Arco_Sur_Centro",
		"Arco_Norte_Este", "Arco_Sur_Este", "Rampa_Empedrada_Oeste", "Rampa_Empedrada_Este",
		"Tablero_Madera", "Traviesas_1", "Traviesas_2", "Traviesas_3", "Traviesas_4",
		"Pretil_Norte_Muro", "Pretil_Norte_Postes_Oeste", "Pretil_Norte_Postes_Centro", "Pretil_Norte_Postes_Este",
		"Pretil_Sur_Muro", "Pretil_Sur_Postes_Oeste", "Pretil_Sur_Postes_Centro", "Pretil_Sur_Postes_Este",
	]
	return p[id - 358]
