@tool
extends Node3D

## Solar del pueblo en el editor del mapa 3D (mapa/Mundo3D.tscn → «Solares»), 2026-11-11: una parcela donde el juego
## levanta una casa, una tienda o un edificio público. Muévelo con el ratón: la obra, la casa que se construya en él,
## su letrero y sus campos salen ahí. Girarlo (eje vertical) gira lo construido de 90 en 90 grados.
## Paso 2 de docs/PLAN_MUNDO_DESDE_EDITOR.md. Lo lee mapa/anclas.gd.

const CARPETA := "Solares"
const VISTA_COLOR := Color(0.95, 0.8, 0.25, 0.3)
const VISTA_ALTO_M: float = 0.1
const LETRERO_ALTURA_M: float = 3.0
const LETRERO_TAM_PIXEL: float = 0.02
const LETRERO_VISTO_HASTA_M: float = 400.0

## Nombre interno del solar en el juego (no lo cambies).
@export var id_solar: String = ""
## Dónde estaba su centro en el mapa 2D cuando se creó la pieza (no lo cambies).
@export var centro_original: Vector2 = Vector2.ZERO
## Tamaño del terreno: ancho (este-oeste) × fondo (norte-sur), en metros. Lo que el juego crea dentro va con el solar.
@export var terreno_m: Vector2 = Vector2.ZERO


func _ready() -> void:
	if Engine.is_editor_hint():
		_poner_vista()


## Losa translúcida con el nombre del solar (solo en el editor; jugando no se dibuja).
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
	letrero.text = "Solar " + id_solar.to_upper()
	letrero.pixel_size = LETRERO_TAM_PIXEL
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.no_depth_test = true
	letrero.visibility_range_end = LETRERO_VISTO_HASTA_M
	letrero.position = Vector3(0.0, LETRERO_ALTURA_M, 0.0)
	add_child(letrero)
