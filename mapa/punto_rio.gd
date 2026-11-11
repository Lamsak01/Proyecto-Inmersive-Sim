@tool
extends Marker2D

## Un punto del río. Arrástralo para mover el cauce; cambia «ancho» para ensancharlo o estrecharlo aquí.
## Para añadir un punto: selecciona uno y pulsa Ctrl+D (duplicar), luego arrástralo. Para quitarlo: Supr.

## Ancho del río en este punto, de orilla a orilla (en píxeles del juego; una persona mide unos 10; con el mapa ×5 el
## río del pueblo anda por 100–150).
@export_range(9.0, 400.0, 0.5) var ancho: float = 40.0:
	set(v):
		ancho = v
		_avisar()


func _ready() -> void:
	gizmo_extents = 16.0
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_avisar()


func _avisar() -> void:
	var p := get_parent()
	if p != null and p.has_method("redibujar"):
		p.call("redibujar")
