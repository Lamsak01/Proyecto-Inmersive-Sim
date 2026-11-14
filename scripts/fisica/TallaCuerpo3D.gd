extends RefCounted

## TallaCuerpo3D: cuánto ocupa el cuerpo 3D de cada personaje y cuándo se apaga (paso a 3D, tanda 4, 2026-11-14).
## Una sola tabla para todos (antes repartida entre los «cuerpos de contacto» y el reparto por cercanía).
## - Personas (vecinos, bandidos, enemigos, el protagonista) y animales grandes (ciervo, jabalí, ganado adulto) estorban
##   el paso. Los pequeños (conejos, zorros, mascotas, gallinas y crías) tienen cuerpo pero se pasa por encima.
## - Dormido, sentado, caído o muerto, el cuerpo se apaga: no frena a nadie.
## Sin estado y sin preloads de otros sistemas.

const PERSONA: Vector2 = Vector2(0.28, 1.74)   ## radio y alto (m)
const ANIMAL: Vector2 = Vector2(0.4, 1.3)      ## jabalí, ciervo, oveja, vaca…
const PEQUENO: Vector2 = Vector2(0.15, 0.4)    ## conejo, zorro, mascota, gallina, cría
const GANADO_GRANDE: Array[String] = ["sheep", "cow", "bull", "donkey", "horse"]
const GANADO_CRIA: Array[String] = ["chick", "juvenile"]
const ESPECIES_GRANDES: Array[int] = [1, 3]    ## WildAnimal.SpeciesType: DEER, BOAR
const QUIETO_PX_S_2: float = 4.0               ## por debajo de esta velocidad (al cuadrado) cuenta como quieto


## Radio y alto (m) del cuerpo de `n`.
static func de(n: Node) -> Vector2:
	if n.has_method("is_alive_in_ecosystem"): # un animal salvaje (vivo o cadáver: muerto ya no está en su grupo)
		return ANIMAL if int(n.get("species")) in ESPECIES_GRANDES else PEQUENO
	if n.is_in_group("livestock_animals"):
		var adulto: bool = str(n.get("species")) in GANADO_GRANDE and not (str(n.get("stage")) in GANADO_CRIA)
		return ANIMAL if adulto else PEQUENO
	if n.is_in_group("domestic_pets"):
		return PEQUENO
	if n.is_in_group("raiders") and str(n.get("kind")) == "boar":
		return ANIMAL
	return PERSONA


## ¿Estorba el paso al protagonista? Los pequeños no.
static func estorba(n: Node) -> bool:
	return de(n) != PEQUENO


## ¿Está fuera de juego (muerto, caído, dormido, sentado o escondido)? Entonces su cuerpo se apaga.
static func apagado(n: Node) -> bool:
	if _si(n, "is_dead") or _si(n, "is_downed") or _si(n, "is_sleeping") or _si(n, "is_at_poker_table"):
		return true
	if n is CanvasItem and not (n as CanvasItem).visible: # escondido (un conejo en su madriguera, un animal retirado)
		return true
	if n is Node3D and not (n as Node3D).visible: # lo mismo para quien ya es un cuerpo 3D
		return true
	if n.has_method("is_alive_in_ecosystem") and not bool(n.call("is_alive_in_ecosystem")): # un cadáver no estorba
		return true
	if not n.has_method("_is_seated_on_furniture"): # solo los vecinos se sientan
		return false
	# Sentado solo si está quieto: las sillas del salón quedan bajo la galería de la posada y el mapa no distingue pisos
	var quieto: bool = not ("velocity" in n) or (n.get("velocity") as Vector2).length_squared() < QUIETO_PX_S_2
	return quieto and bool(n.call("_is_seated_on_furniture", (n as Node2D).global_position))


## ¿Tiene `n` la propiedad `prop` y está a true? (no todos tienen las mismas: el ganado no duerme ni cae)
static func _si(n: Node, prop: String) -> bool:
	return n.get(prop) == true
