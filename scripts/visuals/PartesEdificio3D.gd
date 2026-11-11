extends RefCounted

## Nombres de las partes de un edificio 3D: sus cuatro grupos fijos y las etiquetas de lo que se mueve (puerta,
## postigo, luces de noche…). El juego reconoce cada parte por su etiqueta, venga el edificio del código o de su
## escena guardada (mapa/edificios/<id>.tscn), así no depende de nombres de nodo ni de posiciones.

const MUROS: String = "Muros"          ## suelo, paredes, fachada y puerta
const INTERIOR: String = "Interior"    ## tabiques, mostradores y detalles de dentro (los muebles van aparte, en «Muebles»)
const PISO_ALTO: String = "PisoAlto"   ## segunda planta: solo se ve al subir
const TEJADO: String = "Tejado"        ## lo que se retira al mirar dentro desde arriba
const MUEBLES: String = "Muebles"      ## una pieza por mueble (mapa/mueble.gd)
const MARCAS: String = "Marcas"        ## sitios sin dibujo (cama, mesa, puesto de trabajo) que lee la lógica

const ROL: StringName = &"rol"         ## nombre de la etiqueta (metadato del nodo)
const PUERTA: String = "puerta"                 ## bisagra de la puerta de la calle
const CANDADO: String = "candado"               ## chapa que se ve cuando la puerta está cerrada con llave
const CRISTAL: String = "cristal"               ## cristal de la ventana
const POSTIGO: String = "postigo"               ## tabla que tapa la ventana al cerrarla
const LUZ_NOCHE: String = "luz_noche"           ## se enciende al caer la tarde
const CUERPO_MORGUE: String = "cuerpo_morgue"   ## bulto bajo la sábana de cada camilla
const REJA_CELDA: String = "reja_celda"         ## reja corredera del calabozo
const PUERTA_CUARTO: String = "puerta_cuarto"   ## hoja de un cuarto, se abre sola al acercarse alguien
const BOMBILLA_CUADRO: String = "bombilla_cuadro" ## piloto del cuadro eléctrico del taller
const COFRE: String = "cofre"                   ## cofre de la casa: lo pone el juego aparte, no va en la escena

const HUECO: StringName = &"hueco"     ## puerta de cuarto: centro del hueco, en metros respecto al edificio
const HUECO_PX: StringName = &"hueco_px" ## lo mismo en el mapa, solo mientras el edificio se construye por código
const NIVEL: StringName = &"nivel"     ## puerta de cuarto: en qué planta está


## Todos los nodos etiquetados de un edificio, en el orden del árbol.
static func con_rol(raiz: Node) -> Array[Node]:
	var out: Array[Node] = []
	_buscar(raiz, out)
	return out


static func _buscar(nodo: Node, out: Array[Node]) -> void:
	for hijo: Node in nodo.get_children():
		if hijo.has_meta(ROL):
			out.append(hijo)
		_buscar(hijo, out)


## El primer descendiente de `nodo` con esa etiqueta, o null.
static func hijo_con_rol(nodo: Node, rol: String) -> Node:
	for parte: Node in con_rol(nodo):
		if String(parte.get_meta(ROL)) == rol:
			return parte
	return null
