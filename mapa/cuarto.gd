@tool
extends Node3D

## Cuarto de una casa (grupo «Cuartos» de su escena, mapa/edificios/<id>.tscn), 2026-11-13: un dormitorio, la cocina,
## el aseo… Dice qué trozo de la planta es ese cuarto y por qué hueco se entra en él, para que los vecinos crucen
## de un cuarto a otro por las puertas y no contra los tabiques (scripts/systems/RutaCuartos.gd). Una casa tiene un
## cuarto «central» (la sala) al que dan la puerta de la calle y todos los demás cuartos.
## Muévelo con el ratón junto con sus tabiques; cambia «Tam m» si cambias el tamaño del cuarto.

const CARPETA := "Cuartos"             ## grupo que contiene los cuartos de un edificio
const VISTA_ALTO_M: float = 0.05       ## lámina que lo enseña en el editor, pegada al suelo
const VISTA_COLOR := Color(0.3, 0.6, 0.95, 0.25)
const VISTA_COLOR_CENTRAL := Color(0.95, 0.85, 0.3, 0.25)

## Tamaño del cuarto visto desde arriba: ancho (este-oeste) × fondo (norte-sur), en metros.
@export var tam_m: Vector2 = Vector2(4.0, 4.0):
	set(valor):
		tam_m = valor
		_poner_vista()
## Centro del hueco por el que se entra, en metros respecto al centro del cuarto (sobre uno de sus lados).
@export var paso_m: Vector3 = Vector3.ZERO
## La sala que da a la calle y a los demás cuartos (solo una por casa; no necesita hueco).
@export var central: bool = false:
	set(valor):
		central = valor
		_poner_vista()


func _ready() -> void:
	_poner_vista()


## Lámina translúcida para verlo en el editor (jugando no se dibuja).
func _poner_vista() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	for hijo: Node in get_children():
		if hijo.has_meta("vista_cuarto"):
			hijo.queue_free()
	var lamina := BoxMesh.new()
	lamina.size = Vector3(tam_m.x, VISTA_ALTO_M, tam_m.y)
	var material := StandardMaterial3D.new()
	material.albedo_color = VISTA_COLOR_CENTRAL if central else VISTA_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lamina.material = material
	var vista := MeshInstance3D.new()
	vista.mesh = lamina
	vista.position.y = VISTA_ALTO_M
	vista.set_meta("vista_cuarto", true)
	add_child(vista) # sin «owner»: no se guarda en la escena
