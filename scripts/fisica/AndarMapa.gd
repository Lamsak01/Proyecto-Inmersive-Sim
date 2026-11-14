extends RefCounted

## AndarMapa: un solo sitio para «dar el paso» de cualquier personaje (vecinos, animales, mascotas, bandidos, enemigos).
## Desde la tanda 4 del paso a 3D (2026-11-14) todos andan SIEMPRE con su cuerpo 3D: choca con las paredes 3D del
## mundo y escribe después su sitio en el mapa. Ya no queda el paso plano de reserva (`move_and_slide` del mapa).
## Sin preloads: así pueden usarlo los guiones de los personajes sin crear ciclos de carga.

const RUTA_CUERPO: String = "res://scripts/fisica/Cuerpo3D.gd"
const META_CUERPO: String = "cuerpo3d"


## El cuerpo 3D de `actor` (se crea la primera vez; null solo si el escenario 3D aún no existe).
static func cuerpo(actor: Node2D) -> Node:
	var c: Variant = actor.get_meta(META_CUERPO) if actor.has_meta(META_CUERPO) else null
	if is_instance_valid(c):
		return c as Node
	return load(RUTA_CUERPO).call("de", actor) as Node


## Un paso andando con la velocidad que tiene ahora `actor` (píxeles del mapa por segundo).
static func paso(actor: CharacterBody2D, delta: float) -> void:
	var c: Node = cuerpo(actor)
	if c != null:
		c.call("mover", actor.velocity, delta)


## Un desplazamiento de golpe (empujón de un golpe, zancada al atacar): choca con las paredes, no las atraviesa.
static func empujon(actor: Node2D, desplazamiento: Vector2) -> void:
	var c: Node = cuerpo(actor)
	if c != null:
		c.call("empujar", desplazamiento)


## ¿Ha chocado con algo en su último paso?
static func ha_chocado(actor: Node2D) -> bool:
	var c: Node = cuerpo(actor)
	return c != null and bool(c.get("toca_pared"))
