extends Node3D

## Poblacion3D: todo personaje lleva su cuerpo 3D desde que entra en el juego hasta que desaparece (paso a 3D, tanda 4,
## 2026-11-14). Sustituye a CuerposDelPueblo3D (solo daba cuerpo a los 24 más cercanos al protagonista y se lo quitaba
## si se atascaban) y a CuerposCercanos3D (cuerpos «de contacto» para los que no tenían el suyo).
## Regla general, sin listas: es personaje todo `CharacterBody2D` y todo nodo que se apunte al grupo `con_cuerpo_3d`
## (el ganado, que aún no es un cuerpo del mapa). Nadie tiene que acordarse de pedir su cuerpo.

const Cuerpo3D = preload("res://scripts/fisica/Cuerpo3D.gd")

const NOMBRE: String = "Poblacion3D"
const GRUPO: String = "con_cuerpo_3d"


func _init() -> void:
	name = NOMBRE


func _ready() -> void:
	get_tree().node_added.connect(_al_entrar)
	for n: Node in get_tree().root.find_children("*", "CharacterBody2D", true, false):
		_dar(n)
	for n: Node in get_tree().get_nodes_in_group(GRUPO):
		_dar(n)


## Cuántos personajes del juego tienen ahora su cuerpo (lo miran las pruebas).
func cuantos() -> int:
	return get_tree().get_nodes_in_group(Cuerpo3D.GRUPO_CUERPOS).size()


## Alguien entra en el juego: si es un personaje, recibe su cuerpo. Se mira al acabar el fotograma, cuando ya se ha
## apuntado a sus grupos.
func _al_entrar(n: Node) -> void:
	if n is Node2D and n.get_script() != null:
		_dar.call_deferred(n)


func _dar(n: Node) -> void:
	if not is_instance_valid(n) or not n.is_inside_tree():
		return
	if n is CharacterBody2D or n.is_in_group(GRUPO):
		Cuerpo3D.de(n as Node2D)
