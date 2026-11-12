@tool
extends Marker3D
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Marca de un edificio (grupo «Marcas» de su escena, mapa/edificios/<id>.tscn), 2026-11-11: un sitio sin dibujo que
## usa la lógica del juego: dónde duerme, come y trabaja cada vecino, dónde va el puesto de venta y el cofre.
## Muévela con el ratón dentro de su edificio: el vecino irá ahí. Como cuelga del edificio, si mueves o giras el
## edificio la marca va con él. Paso 1 de docs/PLAN_MUNDO_DESDE_EDITOR.md.

const CARPETA := "Marcas"                 ## grupo que contiene las marcas de un edificio
const EDIFICIO := "res://mapa/edificio.gd"
const TRABAJO := "trabajo"                ## donde atiende el maestro del oficio
const TRABAJO_FAMILIAR := "trabajo_familiar" ## donde ayuda su familiar
const CAMA_1 := "cama_1"                  ## cama del maestro
const CAMA_2 := "cama_2"                  ## cama de su familiar
const MESA := "mesa"                      ## mesa de casa: comer y estar en familia
const PUESTO := "puesto"                  ## mostrador de venta
const COFRE := "cofre"                    ## cofre de la casa o de la tienda
const CAMILLA := "camilla"                ## hospital: cama de urgencias
const MESA_MORGUE := "mesa_morgue_%d"     ## morgue: camillas de autopsia, de la 1 a la 3
const CELDA := "celda"                    ## comisaría: centro del calabozo
const CAMA_CELDA := "cama_celda"          ## comisaría: catre del preso
const ARCHIVO := "archivo"                ## comisaría: mesa con la denuncia archivada (Caso I)
const ESCRITORIO := "escritorio"          ## comisaría: donde se repasa el expediente al amanecer
const ALTAR := "altar"                    ## capilla
const DESPACHO := "despacho"              ## casas nobles: escritorio donde pasan el día
const GABINETE := "gabinete"              ## mansión: gabinete forzado (Caso I)
const PAJAR := "pajar"                    ## molino abandonado (Caso I): montón de paja
const HOGAR := "hogar"                    ## molino abandonado (Caso I): hogar con ceniza
const CORDEL := "cordel"                  ## molino abandonado (Caso I): banco con el rollo de cordel
const MESA_PAPEL := "mesa_papel"          ## molino abandonado (Caso I): mesa con el papel
const SOTANO := "sotano"                  ## molino abandonado (Caso I): foso con la reja al canal
const LETRERO_ALTURA_M: float = 1.2
const LETRERO_TAM_PIXEL: float = 0.008    ## metros por píxel de letra: se lee al acercarse, no tapa el edificio
const LETRERO_VISTO_HASTA_M: float = 60.0

## Nombre interno del sitio (no lo cambies): el juego lo busca por este nombre.
@export var id_marca: String = ""

static var _por_edificio: Dictionary = {} ## id del edificio → {id de la marca → sitio en el mapa original}


func _ready() -> void:
	if Engine.is_editor_hint():
		add_child(_letrero()) # sin «owner»: no se guarda en la escena


## El nombre de la marca flotando encima (solo en el editor), para saber cuál es cada cruz.
func _letrero() -> Label3D:
	var letrero := Label3D.new()
	letrero.text = id_marca
	letrero.pixel_size = LETRERO_TAM_PIXEL
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.no_depth_test = true
	letrero.visibility_range_end = LETRERO_VISTO_HASTA_M
	letrero.position = Vector3(0.0, LETRERO_ALTURA_M, 0.0)
	return letrero


## ¿Tiene ese edificio esa marca?
static func hay(id_edificio: String, marca: String) -> bool:
	return _marcas_de(id_edificio).has(marca)


## Sitio de una marca en el mapa ORIGINAL (el edificio en su sitio de fábrica y sin girar): es lo que esperan las
## funciones que colocan cosas y vecinos, que luego lo llevan a donde esté de verdad el edificio (mapa/anclas.gd).
## El interior de la escena está en metros respecto al centro del edificio, así que basta sumarle ese centro.
static func sitio(id_edificio: String, marca: String) -> Vector2:
	var marcas: Dictionary = _marcas_de(id_edificio)
	if not marcas.has(marca):
		push_error("MARCAS: al edificio «%s» le falta la marca «%s»" % [id_edificio, marca])
		return Vector2.ZERO
	return marcas[marca]


static func _marcas_de(id_edificio: String) -> Dictionary:
	if not _por_edificio.has(id_edificio):
		_por_edificio[id_edificio] = de_escena(load(EDIFICIO).call("escena", id_edificio) as PackedScene)
	return _por_edificio[id_edificio]


## Lee las marcas de la escena de un edificio sin crearla (solo sus datos guardados): {id de la marca → sitio}.
## En una casa modelo (sin sitio propio en el mapa) el sitio queda respecto al centro de la casa.
static func de_escena(escena: PackedScene) -> Dictionary:
	var out: Dictionary = {}
	if escena == null:
		return out
	var estado: SceneState = escena.get_state()
	var centro: Vector2 = _propiedades(estado, 0).get("centro_original", Vector2.ZERO)
	for i in range(estado.get_node_count()):
		if not str(estado.get_node_path(i)).begins_with("./" + CARPETA + "/"):
			continue
		var propiedades: Dictionary = _propiedades(estado, i)
		var id := String(propiedades.get("id_marca", ""))
		if id.is_empty():
			continue
		var en_edificio: Transform3D = propiedades.get("transform", Transform3D.IDENTITY)
		out[id] = centro + Mapa3D.a_mapa(en_edificio.origin)
	return out


static func _propiedades(estado: SceneState, nodo: int) -> Dictionary:
	var out: Dictionary = {}
	for k in range(estado.get_node_property_count(nodo)):
		out[String(estado.get_node_property_name(nodo, k))] = estado.get_node_property_value(nodo, k)
	return out
