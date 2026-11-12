@tool
extends Node3D

## Zona de terreno en el editor del mapa 3D (mapa/Mundo3D.tscn → «Zonas»), 2026-11-11: la plaza, el lago o la ciénaga.
## Muévela con el ratón: su suelo o su agua, la hondonada del terreno y lo que el juego pone encima salen ahí.
## No gira ni cambia de forma. Paso 2 de docs/PLAN_MUNDO_DESDE_EDITOR.md. La lee mapa/anclas.gd.

const CARPETA := "Zonas"
const VISTA_COLOR := Color(0.3, 0.6, 0.95, 0.25)
const VISTA_ALTO_M: float = 0.1
const LETRERO_ALTURA_M: float = 6.0
const LETRERO_TAM_PIXEL: float = 0.04
const LETRERO_VISTO_HASTA_M: float = 800.0

## Nombre interno de la zona en el juego (no lo cambies).
@export var id_zona: String = ""
## Dónde estaba su centro en el mapa 2D cuando se creó la pieza (no lo cambies).
@export var centro_original: Vector2 = Vector2.ZERO
## Tamaño de la zona en el mundo: ancho (este-oeste) × fondo (norte-sur), en metros (no lo cambies).
@export var terreno_m: Vector2 = Vector2.ZERO


func _ready() -> void:
	if Engine.is_editor_hint():
		_poner_vista()


## Losa azul translúcida con el nombre de la zona (solo en el editor; jugando no se dibuja).
func _poner_vista() -> void:
	var losa := BoxMesh.new()
	losa.size = Vector3(terreno_m.x, VISTA_ALTO_M, terreno_m.y)
	var material := StandardMaterial3D.new()
	material.albedo_color = VISTA_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	losa.material = material
	var vista := MeshInstance3D.new()
	vista.mesh = losa
	add_child(vista) # sin «owner»: no se guarda en la escena
	var letrero := Label3D.new()
	letrero.text = "Zona: " + id_zona
	letrero.pixel_size = LETRERO_TAM_PIXEL
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.no_depth_test = true
	letrero.visibility_range_end = LETRERO_VISTO_HASTA_M
	letrero.position = Vector3(0.0, LETRERO_ALTURA_M, 0.0)
	add_child(letrero)
