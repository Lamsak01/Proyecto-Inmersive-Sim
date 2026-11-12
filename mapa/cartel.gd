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
const METROS_POR_PUNTO_MIN: float = 0.0012  ## límite al encoger la letra de un texto largo (letras de ~5 cm)
const ENCOGER: float = 0.9                  ## cada paso de encoger la letra hasta que quepa
const SOBRE_MADERA_M: float = 0.005         ## las letras, apenas por encima de la madera (si no, parpadean)
const META_TEXTO := "texto_cartel"          ## texto que lleva un poste de camino (meta del dibujo «sign_1» del mapa)
const COLOR_MADERA := Color(0.68, 0.52, 0.33) ## madera clara: las letras oscuras se leen sobre ella
const COLOR_LETRAS := Color(0.10, 0.06, 0.03) ## letras quemadas en la madera clara
const COLOR_LETRAS_PINTADAS := Color(0.93, 0.87, 0.72) ## letras pintadas sobre madera oscura (postes de los caminos)
const PRIMER_EMOJI: int = 0x2000            ## de aquí en adelante, símbolos que el texto 3D no sabe dibujar
const TEXTO_EN_EDITOR := "Nombre del edificio"

## Ancho de la tabla en metros (cámbialo en el editor si el cartel no cabe o tapa algo).
@export_range(0.6, 3.0, 0.05) var ancho_m: float = ANCHO_M

var _letras: Label3D


func _ready() -> void:
	add_child(_tabla()) # sin «owner»: se crea al cargar y no se guarda en la escena
	_letras = letras(Vector3(ancho_m, ALTO_M, GROSOR_M))
	add_child(_letras)
	if Engine.is_editor_hint():
		escribir(_letras, _nombre_en_editor(), Vector3(ancho_m, ALTO_M, GROSOR_M))


## El juego le pone el título del edificio.
func poner_texto(titulo: String) -> void:
	if _letras != null:
		escribir(_letras, titulo, Vector3(ancho_m, ALTO_M, GROSOR_M))


static func sin_emojis(texto: String) -> String:
	var limpio := ""
	for ch: String in texto:
		if ch.unicode_at(0) < PRIMER_EMOJI:
			limpio += ch
	return limpio.strip_edges()


## Letras para una tabla de ese tamaño (ancho, alto, grueso en metros), sobre su cara de delante (+Z).
## También las usan los postes de los caminos (scripts/visuals/WorldStageProps3D.gd), con letras pintadas claras.
static func letras(tabla: Vector3, color: Color = COLOR_LETRAS) -> Label3D:
	var l := Label3D.new()
	l.font_size = TAM_LETRA
	l.pixel_size = METROS_POR_PUNTO
	l.modulate = color
	l.outline_size = 0
	l.double_sided = false
	l.shaded = true
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, tabla.z * 0.5 + SOBRE_MADERA_M)
	return l


## Escribe el texto (sin emojis) y encoge la letra hasta que quepa en la tabla, para que los nombres largos no se salgan.
static func escribir(l: Label3D, texto: String, tabla: Vector3) -> void:
	l.text = sin_emojis(texto)
	var util := Vector2(tabla.x, tabla.y) - Vector2.ONE * MARGEN_TEXTO_M * 2.0
	var fuente: Font = ThemeDB.fallback_font
	var metros: float = METROS_POR_PUNTO
	while metros > METROS_POR_PUNTO_MIN:
		var alto: float = fuente.get_multiline_string_size(l.text, HORIZONTAL_ALIGNMENT_CENTER, util.x / metros, TAM_LETRA, -1, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND).y
		if alto * metros <= util.y:
			break
		metros *= ENCOGER
	l.pixel_size = metros
	l.width = util.x / metros


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


## En el editor, el nombre del edificio que lo contiene (la raíz de su escena sabe su id).
func _nombre_en_editor() -> String:
	var raiz: Node = owner if owner != null else get_parent()
	var id: String = String(raiz.get("id_edificio")) if raiz != null and raiz.get("id_edificio") != null else ""
	if id.is_empty():
		return TEXTO_EN_EDITOR
	return String(load("res://mapa/edificio.gd").call("nombre_legible", id))
