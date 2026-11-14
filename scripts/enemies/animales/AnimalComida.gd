class_name AnimalComida
extends RefCounted

## AnimalComida: qué come un animal salvaje, dónde lo busca y cómo se lo come. Los herbívoros (conejo, ciervo, jabalí)
## comen plantas del bosque, primero las de su zona; el zorro aprovecha un conejo muerto o caza uno vivo si quedan bastantes.
## Pieza de WildAnimal (tanda 4b-2 del paso a 3D, 2026-11-14): todo en metros sobre el suelo.

const HERBIVOROS: Array[WildAnimal.SpeciesType] = [WildAnimal.SpeciesType.RABBIT, WildAnimal.SpeciesType.DEER, WildAnimal.SpeciesType.BOAR]
const ZONA_PROPIA_M: float = 29.1    ## plantas a esta distancia de su nido: las de su zona
const PLANTA_MAX_M: float = 70.0     ## agotadas las de su zona, no va a por plantas más lejos que esto
const PRESA_MAX_M: float = 103.6     ## el zorro no va a por un conejo más lejos
const CONEJOS_MIN: int = 4           ## el zorro solo caza si quedan más conejos vivos que estos
const PRESA_YA_ELEGIDA_M: float = 14.56 ## un conejo que ya acecha otro zorro cuenta como así de más lejos
const ALCANZA_M: float = 0.84        ## a esta distancia de la comida, se pone a comer
const PRISA: float = 1.25            ## va a la comida algo más deprisa de lo que pasta
const COMER_S: float = 2.6
const CASA_LEJOS_M: float = 21.3     ## sin comida y más lejos que esto de casa, vuelve
const CASA_TRAS_COMER_M: float = 6.72


## La comida que le conviene ahora (una planta, un conejo muerto o un conejo vivo), o null.
static func buscar(a: WildAnimal) -> Node:
	if a.species in HERBIVOROS:
		var cerca: Node = _planta_mas_cercana(a, true)
		return cerca if cerca != null else _planta_mas_cercana(a, false)
	return _presa_del_zorro(a)


static func _planta_mas_cercana(a: WildAnimal, solo_su_zona: bool) -> Node:
	var mejor: Node = null
	var mejor_d: float = INF if solo_su_zona else PLANTA_MAX_M
	for nodo: Node in a.get_tree().get_nodes_in_group("wild_flora"):
		var planta: HarvestableNode = nodo as HarvestableNode
		if planta == null or planta.is_depleted:
			continue
		var donde: Vector2 = Lugar.de(planta)
		if solo_su_zona and a.casa.distance_to(donde) > ZONA_PROPIA_M:
			continue
		var d: float = a.sitio.distance_to(donde)
		if d < mejor_d:
			mejor_d = d
			mejor = planta
	return mejor


## Primero un conejo ya muerto; si no hay y quedan bastantes vivos, el vivo más a mano que no acecha ya otro zorro.
static func _presa_del_zorro(a: WildAnimal) -> Node:
	var muerto: WildAnimal = null
	var mejor_d: float = PRESA_MAX_M
	var vivos: int = 0
	for nodo: Node in a.get_tree().get_nodes_in_group("ecosystem_rabbits"):
		var conejo: WildAnimal = nodo as WildAnimal
		if conejo == null:
			continue
		if conejo.is_alive_in_ecosystem():
			vivos += 1
		elif conejo.state == WildAnimal.AnimalState.CARCASS and conejo.visible and a.sitio.distance_to(conejo.sitio) < mejor_d:
			mejor_d = a.sitio.distance_to(conejo.sitio)
			muerto = conejo
	if muerto != null or vivos <= CONEJOS_MIN:
		return muerto
	return _conejo_vivo_a_mano(a)


static func _conejo_vivo_a_mano(a: WildAnimal) -> WildAnimal:
	var mejor: WildAnimal = null
	var mejor_d: float = PRESA_MAX_M
	var zorros: Array[Node] = a.get_tree().get_nodes_in_group("ecosystem_foxes")
	for nodo: Node in a.get_tree().get_nodes_in_group("herbivore_prey"):
		var conejo: WildAnimal = nodo as WildAnimal
		if conejo == null or not conejo.is_alive_in_ecosystem() or conejo.state == WildAnimal.AnimalState.IN_BURROW or not conejo.visible:
			continue
		var d: float = a.sitio.distance_to(conejo.sitio)
		for z: Node in zorros:
			if z != a and z is WildAnimal and (z as WildAnimal).food_target == conejo:
				d += PRESA_YA_ELEGIDA_M
		if d < mejor_d:
			mejor_d = d
			mejor = conejo
	return mejor


## ¿Sigue ahí la comida? (una planta sin agotar o un animal a la vista)
static func _sigue_ahi(comida: Node) -> bool:
	if not is_instance_valid(comida) or comida.get("visible") != true:
		return false
	return not (comida is HarvestableNode and (comida as HarvestableNode).is_depleted)


static func ir_a_comer(a: WildAnimal) -> void:
	if a.is_fully_satiated():
		a.food_target = null
		a.state = WildAnimal.AnimalState.GRAZE
		return
	if not _sigue_ahi(a.food_target):
		a.food_target = buscar(a)
	if a.food_target == null:
		a.state = WildAnimal.AnimalState.RETURN_HOME if a.sitio.distance_to(a.casa) > CASA_LEJOS_M else WildAnimal.AnimalState.GRAZE
		a.andar = Vector2.ZERO
		return
	var hacia: Vector2 = Lugar.de(a.food_target) - a.sitio
	if hacia.length() > ALCANZA_M:
		a.andar = hacia.normalized() * a.paso_m_s * PRISA
		return
	a.andar = Vector2.ZERO
	a.eat_timer = COMER_S
	a.state = WildAnimal.AnimalState.EATING


static func comer(a: WildAnimal, delta: float) -> void:
	a.andar = Vector2.ZERO
	a.eat_timer -= delta
	if a.eat_timer > 0.0:
		return
	if _se_lo_come(a.food_target):
		_apuntar_comida(a)
	a.food_target = null
	a.state = WildAnimal.AnimalState.RETURN_HOME if a.sitio.distance_to(a.casa) > CASA_TRAS_COMER_M else WildAnimal.AnimalState.GRAZE


## Se come lo que tenía delante; devuelve si de verdad había algo que comer.
static func _se_lo_come(comida: Node) -> bool:
	if not is_instance_valid(comida):
		return false
	if comida is HarvestableNode:
		return comida.has_method("consume_by_animal") and bool(comida.call("consume_by_animal"))
	var presa: WildAnimal = comida as WildAnimal
	if presa == null or presa.is_alive_in_ecosystem():
		return false
	presa.consume_by_predator()
	return true


## Una comida más: con dos está saciado y gana un día de reserva (el zorro se sacia con una presa).
static func _apuntar_comida(a: WildAnimal) -> void:
	a.meals_eaten = WildAnimal.MAX_MEALS if a.species == WildAnimal.SpeciesType.FOX else a.meals_eaten + 1
	a.fed_today = true
	a.days_hungry = 0
	if a.meals_eaten >= WildAnimal.MAX_MEALS:
		a.has_reserve_day = true
