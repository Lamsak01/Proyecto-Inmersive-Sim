@tool
extends Node3D

## Cartel de madera con el nombre del edificio, clavado en la pared junto a la puerta (2026-11-12). Es una pieza de
## la escena del edificio (mapa/edificios/<id>.tscn → «Cartel»): se mueve con el ratón en el editor. El nombre no se
## guarda aquí: lo pone el juego con el título del edificio (así las casas de solar llevan el de su familia).
## Sustituye a los nombres que flotaban sobre el mapa. Lo coloca la primera vez tools/poner_carteles.gd.

const NOMBRE_NODO := "Cartel"
const ANCHO_M: float = 1.5             ## ancho normal; en paredes cortas el cartel puede ser más estrecho
const ALTO_M: float = 0.7               ## caben tres renglones (los nombres largos, como el de la posada)
const GROSOR_M: float = 0.06
const MARGEN_TEXTO_M: float = 0.08          ## madera libre alrededor de las letras
const METROS_POR_PUNTO: float = 0.003       ## tamaño de letra en el mundo: unas letras de 10 cm
const TAM_LETRA: int = 40
const COLOR_MADERA := Color(0.68, 0.52, 0.33) ## madera clara: las letras oscuras se leen sobre ella
const COLOR_LETRAS := Color(0.10, 0.06, 0.03) ## letras quemadas en la madera
const PRIMER_EMOJI: int = 0x2000            ## de aquí en adelante, símbolos que el texto 3D no sabe dibujar
const TEXTO_EN_EDITOR := "Nombre del edificio"

## Ancho de la tabla en metros (cámbialo en el editor si el cartel no cabe o tapa algo).
@export_range(0.6, 3.0, 0.05) var ancho_m: float = ANCHO_M

var _letras: Label3D


func _ready() -> void:
	add_child(_tabla()) # sin «owner»: se crea al cargar y no se guarda en la escena
	_letras = _texto()
	add_child(_letras)
	if Engine.is_editor_hint():
		_letras.text = _nombre_en_editor()


## El juego le pone el título del edificio (sin emojis, que no se dibujan en 3D).
func poner_texto(titulo: String) -> void:
	if _letras != null:
		_letras.text = sin_emojis(titulo)


static func sin_emojis(texto: String) -> String:
	var limpio := ""
	for ch: String in texto:
		if ch.unicode_at(0) < PRIMER_EMOJI:
			limpio += ch
	return limpio.strip_edges()


func _tabla() -> MeshInstance3D:
	var caja := BoxMesh.new()
	caja.size = Vector3(ancho_m, ALTO_M, GROSOR_M)
	var madera := StandardMaterial3D.new()
	madera.albedo_color = COLOR_MADERA
	madera.roughness = 0.9
	caja.material = madera
	var tabla := MeshInstance3D.new()
	tabla.mesh = caja
	return tabla


## Letras en la cara de delante (la que mira hacia +Z de la pieza, hacia la calle), justo encima de la madera.
func _texto() -> Label3D:
	var l := Label3D.new()
	l.font_size = TAM_LETRA
	l.pixel_size = METROS_POR_PUNTO
	l.modulate = COLOR_LETRAS
	l.outline_size = 0
	l.double_sided = false
	l.shaded = true
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.width = (ancho_m - MARGEN_TEXTO_M * 2.0) / METROS_POR_PUNTO
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, GROSOR_M * 0.5 + 0.005)
	return l


## En el editor, el nombre del edificio que lo contiene (la raíz de su escena sabe su id).
func _nombre_en_editor() -> String:
	var raiz: Node = owner if owner != null else get_parent()
	var id: String = String(raiz.get("id_edificio")) if raiz != null and raiz.get("id_edificio") != null else ""
	if id.is_empty():
		return TEXTO_EN_EDITOR
	return String(load("res://mapa/edificio.gd").call("nombre_legible", id))
