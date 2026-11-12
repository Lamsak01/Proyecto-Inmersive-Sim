@tool
extends Node3D

## Tabique de un edificio (grupo «Tabiques» de su escena, mapa/edificios/<id>.tscn), 2026-11-11: una pared de dentro
## que en el juego no se puede atravesar (separa salas, cierra una celda…). Muévelo con el ratón y cambia su tamaño en
## «Tam m». Esto mueve lo que se pisa y choca, no el dibujo de la pared. Lo lee mapa/planta.gd.
## Paso 1 de docs/PLAN_MUNDO_DESDE_EDITOR.md.

const CARPETA := "Tabiques"            ## grupo que contiene los tabiques de un edificio
const VISTA_ALTO_M: float = 2.0        ## altura de la caja que lo enseña en el editor
const VISTA_COLOR := Color(0.95, 0.35, 0.2, 0.45)

## Tamaño de la pared vista desde arriba: ancho (este-oeste) × fondo (norte-sur), en metros.
@export var tam_m: Vector2 = Vector2(1.0, 0.3):
	set(valor):
		tam_m = valor
		_poner_vista()
## Si no deja ver a través (una reja de celda sí deja).
@export var tapa_vista: bool = true


func _ready() -> void:
	_poner_vista()


## Caja translúcida para verlo en el editor (jugando no se dibuja: la pared visible es parte de «Interior»).
func _poner_vista() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	for hijo: Node in get_children():
		if hijo.has_meta("vista_tabique"):
			hijo.queue_free()
	var caja := BoxMesh.new()
	caja.size = Vector3(tam_m.x, VISTA_ALTO_M, tam_m.y)
	var material := StandardMaterial3D.new()
	material.albedo_color = VISTA_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	caja.material = material
	var vista := MeshInstance3D.new()
	vista.mesh = caja
	vista.position.y = VISTA_ALTO_M * 0.5
	vista.set_meta("vista_tabique", true)
	add_child(vista) # sin «owner»: no se guarda en la escena
