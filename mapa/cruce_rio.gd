@tool
extends Marker3D

## Un puente o vado (carpeta «Cruces» de mapa/Mundo3D.tscn): por aquí cruzan el río los vecinos y el jugador (en el
## resto del cauce el agua no deja pasar). Muévelo encima del río. Para uno nuevo: duplica otro (Ctrl+D) y cámbiale
## el nombre. Solo cuenta dónde está sobre el suelo (la altura da igual).

enum Tipo { VADO, PASARELA_DE_MADERA, PUENTE_DE_PIEDRA, TRONCO_CAIDO }

const GIZMO_M: float = 5.0

@export var nombre: String = "Puente nuevo":
	set(v):
		nombre = v
		_avisar()
@export var tipo: Tipo = Tipo.PASARELA_DE_MADERA:
	set(v):
		tipo = v
		_avisar()
## Ancho del paso en metros (lo que ocupa a lo largo del río). Menos de 1,8 y el jugador no cabe.
@export_range(0.65, 4.5, 0.05) var ancho_m: float = 1.8:
	set(v):
		ancho_m = v
		_avisar()
## Largo del paso en metros (de una orilla a la otra). Que sobresalga un poco del agua.
@export_range(1.1, 22.5, 0.05) var largo_m: float = 4.0:
	set(v):
		largo_m = v
		_avisar()
## Lo alto que se curva el puente en el centro (0 = plano, para vados).
@export_range(0.0, 4.0, 0.05) var altura_arco: float = 1.1
## No lo cambies: algunas misiones buscan un puente concreto por este nombre interno.
@export var id_interno: String = ""


func _ready() -> void:
	gizmo_extents = GIZMO_M
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_avisar()


func _avisar() -> void:
	var rio: Node = get_node_or_null("../../Rio")
	if rio != null and rio.has_method("redibujar"):
		rio.call("redibujar")
