@tool
extends Marker3D

## Un punto del río (carpeta «Rio» de mapa/Mundo3D.tscn). Arrástralo para mover el cauce; cambia «ancho_m» para
## ensancharlo o estrecharlo aquí. Para añadir un punto: selecciona uno y pulsa Ctrl+D (duplicar), luego muévelo.
## Para quitarlo: Supr. Solo cuenta dónde está sobre el suelo (la altura da igual).

const GIZMO_M: float = 6.0 ## tamaño de la cruz en el editor: que se vea desde arriba

## Ancho del río en este punto, de orilla a orilla, en metros (una persona mide unos 0,5 m de ancho; el río del
## pueblo anda por 6–8 m).
@export_range(0.5, 22.5, 0.05) var ancho_m: float = 2.25:
	set(v):
		ancho_m = v
		_avisar()


func _ready() -> void:
	gizmo_extents = GIZMO_M
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_avisar()


func _avisar() -> void:
	var rio: Node = get_parent()
	if rio != null and rio.has_method("redibujar"):
		rio.call("redibujar")
