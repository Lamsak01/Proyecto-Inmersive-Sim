class_name Lugar
extends RefCounted

## Lugar: dónde está alguien, se le pregunte como se le pregunte (paso a 3D, tanda 4b, 2026-11-14).
## Mientras dura el paso a 3D conviven personajes que ya SON su cuerpo 3D (viven en metros) y otros que aún son nodos
## del mapa plano (en píxeles). TRADUCTOR: quien piensa en metros pregunta `de()` y quien aún piensa en el mapa plano
## pregunta `en_mapa()`, sin saber de qué clase es el otro. Se borra cuando no quede nadie en el mapa plano.
## «Suelo» = el plano horizontal del mundo: x hacia el este, y hacia el sur (la z del mundo 3D), en metros.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")


## Dónde está `n`, en metros sobre el suelo.
static func de(n: Node) -> Vector2:
	if n is Node3D:
		var p: Vector3 = (n as Node3D).global_position
		return Vector2(p.x, p.z)
	return (n as Node2D).global_position * Mapa3D.ESCALA


## Dónde está `n`, en el mapa plano (píxeles).
static func en_mapa(n: Node) -> Vector2:
	if n is Node3D:
		return Mapa3D.a_mapa((n as Node3D).global_position)
	return (n as Node2D).global_position


## Un punto del mapa plano (píxeles) → metros sobre el suelo, y al revés.
static func a_suelo(punto_mapa: Vector2) -> Vector2:
	return punto_mapa * Mapa3D.ESCALA


static func a_mapa(punto_suelo: Vector2) -> Vector2:
	return punto_suelo / Mapa3D.ESCALA
