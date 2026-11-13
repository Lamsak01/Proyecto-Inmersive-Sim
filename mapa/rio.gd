@tool
extends Node3D

## El río del valle (carpeta «Rio» de mapa/Mundo3D.tscn), de norte a sur. Sus hijos son los puntos del cauce
## (mapa/punto_rio.gd); los puentes y vados están en «Cruces» (mapa/cruce_rio.gd). Al mover un punto, el agua azul
## de la maqueta se rehace sola; el suelo de la maqueta, con la casilla «regenerar» de la raíz. El juego lee lo guardado.

const RioForma = preload("res://mapa/rio_forma.gd")
const RIO_LAGO := "res://scripts/fisica/RioLago.gd"

## 1 = orillas irregulares y curvas naturales; 0 = el cauce pasa justo por tus puntos.
@export_range(0.0, 1.0, 0.05) var curvas_naturales: float = 1.0:
	set(v):
		curvas_naturales = v
		redibujar()

var _pendiente: bool = false


func _ready() -> void:
	if Engine.is_editor_hint() and not child_order_changed.is_connected(redibujar):
		child_order_changed.connect(redibujar)


## Lo piden los puntos y los puentes al cambiar; se junta todo en un solo rehacer al final del fotograma.
func redibujar() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree() or _pendiente:
		return
	_pendiente = true
	_rehacer.call_deferred()


func datos() -> Dictionary:
	return RioForma.datos_desde_nodos(self, get_node_or_null("../Cruces"))


func _rehacer() -> void:
	_pendiente = false
	load(RIO_LAGO).call("usar_datos", datos())
	var raiz: Node = get_parent()
	if raiz != null and raiz.has_method("rehacer_rio"):
		raiz.call("rehacer_rio")
