class_name TextoFlotante3D
extends Label3D

## TextoFlotante3D: un texto corto que sale sobre algo del mundo 3D, sube un poco y se desvanece («Toby comió en casa»).
## Paso a 3D, tanda 4b-3 (2026-11-14): sustituye, para quien ya es un cuerpo 3D, al texto flotante del mapa plano
## (scenes/ui/FloatingText.tscn). Se lee igual de grande de cerca que de lejos y mira siempre a la cámara.

const TAMANO_LETRA: int = 30
const TAMANO_PUNTO: float = 0.0011
const BORDE: int = 8
const SUBE_M: float = 0.6
const DURA_S: float = 1.6


## Dice `texto` sobre `sobre`, a `alto` metros de sus pies. El texto se queda donde salió aunque `sobre` se mueva.
static func decir(sobre: Node3D, texto: String, color: Color, alto: float = 1.0) -> void:
	if not sobre.is_inside_tree() or sobre.get_parent() == null:
		return
	var t := TextoFlotante3D.new()
	t.text = texto
	t.modulate = color
	t.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	t.fixed_size = true
	t.font_size = TAMANO_LETRA
	t.pixel_size = TAMANO_PUNTO
	t.outline_size = BORDE
	t.outline_modulate = Color.BLACK
	sobre.get_parent().add_child(t)
	t.global_position = sobre.global_position + Vector3.UP * alto
	var vida := t.create_tween()
	vida.tween_property(t, "global_position:y", t.global_position.y + SUBE_M, DURA_S)
	vida.parallel().tween_property(t, "modulate:a", 0.0, DURA_S).set_ease(Tween.EASE_IN)
	vida.tween_callback(t.queue_free)
