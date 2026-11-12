extends RefCounted
const Marca = preload("res://mapa/marca.gd")
const Planta = preload("res://mapa/planta.gd")

## Casas modelo de los recién llegados (2026-11-11, paso 1 de docs/PLAN_MUNDO_DESDE_EDITOR.md): hay tres escenas
## (casita, casa y casona) y cada casa que se levanta en un solar es una copia de la de su tamaño. Lo que cambies en
## una casa modelo (muebles, camas, cofre) cambia en todas las casas de ese tamaño, las de hoy y las que se construyan.
## Están hechas con la puerta al sur; en los solares que miran al norte es la misma casa con media vuelta.

const PREFIJO := "house_family_lot_"        ## id de edificio de una casa de solar: prefijo + id del solar
const ESCENAS: Dictionary = {               ## tamaño de la casa (`plot` del solar) → su casa modelo
	"small": "res://mapa/edificios/modelo_casita.tscn",
	"medium": "res://mapa/edificios/modelo_casa.tscn",
	"large": "res://mapa/edificios/modelo_casona.tscn",
}
const GIRO_PUERTA_NORTE: float = 180.0
const CAMA := "cama_%d"                     ## camas de la planta baja: cama_1, cama_2… (tantas como marcas haya)
const CAMA_ALTA := "cama_alta_%d"           ## camas que añade el altillo, si la casa lo tiene

static var _marcas: Dictionary = {} ## tamaño → {id de la marca → sitio respecto al centro de la casa, puerta al sur}


static func es_casa_de_solar(id_edificio: String) -> bool:
	return id_edificio.begins_with(PREFIJO)


static func solar_de(id_edificio: String) -> String:
	return id_edificio.trim_prefix(PREFIJO)


static func escena(tamano: String) -> PackedScene:
	return load(ESCENAS[tamano]) as PackedScene


## Planta (tamaño, puerta y ventana; mapa/planta.gd) de la casa de ese tamaño según a dónde mire la puerta del solar.
static func planta(tamano: String, puerta_sur: bool) -> Dictionary:
	var de_fabrica: Dictionary = Planta.de_escena(escena(tamano))
	return de_fabrica if puerta_sur else Planta.con_media_vuelta(de_fabrica)


## Lo que hay que girar la casa modelo para que su puerta mire a donde mira la del solar.
static func giro_de_fabrica(puerta_sur: bool) -> float:
	return 0.0 if puerta_sur else GIRO_PUERTA_NORTE


## Sitio de una marca en el mapa original para la casa de ese tamaño levantada con centro en `centro`.
static func sitio(tamano: String, centro: Vector2, puerta_sur: bool, marca: String) -> Vector2:
	var marcas: Dictionary = _marcas_de(tamano)
	if not marcas.has(marca):
		push_error("CASA MODELO: a la casa «%s» le falta la marca «%s»" % [tamano, marca])
		return centro
	return _en_el_solar(centro, puerta_sur, marcas[marca])


## Camas de la casa, en orden: las de la planta baja y, con altillo, las de arriba.
static func camas(tamano: String, centro: Vector2, puerta_sur: bool, con_altillo: bool) -> Array:
	var out: Array = []
	var marcas: Dictionary = _marcas_de(tamano)
	var series: Array[String] = [CAMA]
	if con_altillo:
		series.append(CAMA_ALTA)
	for serie: String in series:
		var n: int = 1
		while marcas.has(serie % n):
			out.append(_en_el_solar(centro, puerta_sur, marcas[serie % n]))
			n += 1
	return out


## Media vuelta alrededor del centro = cambiar de signo lo que la marca se aparta de él.
static func _en_el_solar(centro: Vector2, puerta_sur: bool, desde_el_centro: Vector2) -> Vector2:
	return centro + (desde_el_centro if puerta_sur else -desde_el_centro)


static func _marcas_de(tamano: String) -> Dictionary:
	if not _marcas.has(tamano):
		_marcas[tamano] = Marca.de_escena(escena(tamano))
	return _marcas[tamano]
