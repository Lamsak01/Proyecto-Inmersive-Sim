@tool
extends Marker2D

## Un puente o vado: por aquí cruzan el río los vecinos y el jugador (en el resto del cauce el agua no deja pasar).
## Arrástralo encima del río. Para uno nuevo: duplica otro (Ctrl+D) y cámbiale el nombre.

enum Tipo { VADO, PASARELA_DE_MADERA, PUENTE_DE_PIEDRA }

@export var nombre: String = "Puente nuevo":
	set(v):
		nombre = v
		_avisar()
@export var tipo: Tipo = Tipo.PASARELA_DE_MADERA:
	set(v):
		tipo = v
		_avisar()
## Ancho del paso (lo que ocupa a lo largo del río).
@export_range(12.0, 80.0, 1.0) var ancho: float = 32.0:
	set(v):
		ancho = v
		_avisar()
## Largo del paso (de una orilla a la otra). Que sobresalga un poco del agua.
@export_range(20.0, 160.0, 1.0) var largo: float = 72.0:
	set(v):
		largo = v
		_avisar()
## Lo alto que se curva el puente en el centro (0 = plano, para vados).
@export_range(0.0, 4.0, 0.05) var altura_arco: float = 1.1
## No lo cambies: algunas misiones buscan un puente concreto por este nombre interno.
@export var id_interno: String = ""


func _ready() -> void:
	gizmo_extents = 14.0
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_avisar()


func _avisar() -> void:
	var r := get_node_or_null("../../Rio")
	if r != null and r.has_method("redibujar"):
		r.call("redibujar")
	var p := get_parent()
	if p != null and p is CanvasItem:
		(p as CanvasItem).queue_redraw()
