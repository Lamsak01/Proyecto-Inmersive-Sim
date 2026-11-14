class_name AnimalCaza
extends RefCounted

## AnimalCaza: cómo caza el zorro. Se acerca agachado al conejo, salta sobre él cuando lo tiene a tiro y, si el conejo
## echa a correr, lo persigue un trecho. La primera vez que lo atrapa, el conejo tiene media oportunidad de zafarse.
## Pieza de WildAnimal (tanda 4b-2 del paso a 3D, 2026-11-14): todo en metros sobre el suelo.

const ACECHO_PRISA: float = 1.38     ## agachado avanza algo más deprisa de lo que pasta
const SALTO_DESDE_M: float = 2.24    ## acechando, salta desde esta distancia
const SALTO_DESDE_CARRERA_M: float = 2.0
const PRESA_SE_ESCAPA_M: float = 2.9 ## si el conejo ya corre y está más lejos, pasa a perseguirlo
const SALTO_S: float = 0.24
const SALTO_M_S: float = 13.72
const SALTO_ATRAPA_M: float = 0.92   ## en el aire, lo atrapa a esta distancia
const SALTO_ATRAPA_AL_CAER_M: float = 1.12
const SALTO_FALLIDO_S: float = 0.45  ## lo que tarda en reponerse de un salto al vacío
const ZAFARSE_PROB: float = 0.5
const ZAFARSE_M: float = 0.56        ## lo que se aleja el conejo al zafarse
const ZAFARSE_ESPERA_S: float = 1.2  ## lo que tarda el zorro en poder saltar otra vez
const ZAFARSE_REPONERSE_S: float = 0.65
const DEVORAR_S: float = 3.0
const DESISTE_M: float = 8.12        ## el conejo corre más: si se aleja tanto, el zorro lo deja


## ¿Sigue teniendo una presa viva a la vista? Si no, deja la caza (y si ya está muerta, va a comérsela).
static func _presa(a: WildAnimal) -> WildAnimal:
	var presa: WildAnimal = a.food_target as WildAnimal
	if a.is_fully_satiated() or not is_instance_valid(presa) or not presa.visible or presa.state == WildAnimal.AnimalState.IN_BURROW:
		a.food_target = null
		a.state = WildAnimal.AnimalState.GRAZE
		return null
	if presa.state == WildAnimal.AnimalState.CARCASS:
		a.state = WildAnimal.AnimalState.SEEK_FOOD
		return null
	return presa


static func acechar(a: WildAnimal) -> void:
	var presa: WildAnimal = _presa(a)
	if presa == null:
		return
	var hacia: Vector2 = presa.sitio - a.sitio
	if hacia.length() <= SALTO_DESDE_M and a.attack_cooldown <= 0.0:
		_saltar(a, presa)
	elif presa.state == WildAnimal.AnimalState.FLEE and hacia.length() > PRESA_SE_ESCAPA_M:
		a.state = WildAnimal.AnimalState.CHASE_PREY
	else:
		a.andar = hacia.normalized() * a.paso_m_s * ACECHO_PRISA


static func perseguir(a: WildAnimal) -> void:
	var presa: WildAnimal = _presa(a)
	if presa == null:
		return
	var hacia: Vector2 = presa.sitio - a.sitio
	if hacia.length() <= SALTO_DESDE_CARRERA_M and a.attack_cooldown <= 0.0:
		_saltar(a, presa)
	elif hacia.length() > DESISTE_M:
		a.food_target = null
		a.state = WildAnimal.AnimalState.GRAZE
	else:
		a.andar = hacia.normalized() * a.huida_m_s


static func _saltar(a: WildAnimal, presa: WildAnimal) -> void:
	a.state = WildAnimal.AnimalState.POUNCE
	a.pounce_timer = SALTO_S
	a.pounce_dir = (presa.sitio - a.sitio).normalized()
	if a.pounce_dir == Vector2.ZERO:
		a.pounce_dir = Vector2.RIGHT


## En el aire: corrige hacia la presa y, si la alcanza, la atrapa; si acaba el salto sin alcanzarla, se repone.
static func salto(a: WildAnimal, delta: float) -> void:
	a.pounce_timer -= delta
	var presa: WildAnimal = a.food_target as WildAnimal
	var a_tiro: bool = is_instance_valid(presa) and presa.visible and presa.state != WildAnimal.AnimalState.IN_BURROW
	if a_tiro:
		var hacia: Vector2 = presa.sitio - a.sitio
		if hacia.length() <= SALTO_ATRAPA_M:
			_atrapar(a, presa)
			return
		a.pounce_dir = hacia.normalized()
	a.andar = a.pounce_dir * SALTO_M_S
	if a.pounce_timer > 0.0:
		return
	a.andar = Vector2.ZERO
	if is_instance_valid(presa) and a.sitio.distance_to(presa.sitio) <= SALTO_ATRAPA_AL_CAER_M:
		_atrapar(a, presa)
		return
	a.pounce_recovery_timer = SALTO_FALLIDO_S
	a.state = WildAnimal.AnimalState.GRAZE


## Ha caído sobre el conejo: o se le zafa (solo la primera vez) o lo abate y se pone a comer.
static func _atrapar(a: WildAnimal, presa: WildAnimal) -> void:
	a.andar = Vector2.ZERO
	if not presa.is_alive_in_ecosystem() or presa.state == WildAnimal.AnimalState.IN_BURROW:
		a.state = WildAnimal.AnimalState.GRAZE
		return
	if not presa.escaped_first_pounce and randf() < ZAFARSE_PROB:
		presa.escaped_first_pounce = true
		presa.huir_de(a.sitio)
		presa.empujar_suelo(presa.flee_dir * ZAFARSE_M)
		AnimalRotulo.decir(presa, "¡Se zafó!", Color.SPRING_GREEN)
		a.attack_cooldown = ZAFARSE_ESPERA_S
		a.pounce_recovery_timer = ZAFARSE_REPONERSE_S
		a.state = WildAnimal.AnimalState.GRAZE
		return
	presa.take_pounce_takedown()
	a.eat_timer = DEVORAR_S
	a.state = WildAnimal.AnimalState.EATING
