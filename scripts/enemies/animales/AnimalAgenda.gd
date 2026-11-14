class_name AnimalAgenda
extends RefCounted

## AnimalAgenda: la rutina de un animal salvaje a lo largo del día: de noche vuelve a su nido y duerme (el conejo, en su
## madriguera); de día pasta, busca comida si tiene hambre y, si ya ha comido dos veces, busca pareja.
## Pieza de WildAnimal (tanda 4b-2 del paso a 3D, 2026-11-14): todo en metros sobre el suelo.

const HORAS_NOCHE: Vector2i = Vector2i(20, 6)       ## (anochece, amanece) para casi todos
const HORAS_NOCHE_ZORRO: Vector2i = Vector2i(1, 6)  ## el zorro trasnocha: solo duerme de madrugada
const EN_CASA_M: float = 1.0          ## de noche, más lejos que esto del nido aún tiene que volver
const CASA_A_LA_VISTA_M: float = 4.76 ## de día, al llegar a esta distancia de casa deja de volver y pasta
const CASA_LEJOS_SACIADO_M: float = 23.5
const CASA_LEJOS_SIN_COMIDA_M: float = 25.2
const PAREJA_MAX_M: float = 21.3      ## no busca pareja más lejos
const PAREJA_JUNTOS_M: float = 1.12
const CORTEJO_S: float = 1.6
const CRIA_PROB: float = 0.75
const GENETICA_MAX: int = 3
const PRISA: float = 1.15             ## vuelve a casa o va hacia su pareja algo más deprisa de lo que pasta
const LLEGA_A_CASA_M: float = 0.78
const PASTO_PARADA_PROB: float = 0.2
const PASTO_PARADA_S: Vector2 = Vector2(1.2, 2.4)
const PASTO_PASEO_S: Vector2 = Vector2(2.8, 5.8)
const PASTO_LEJOS_M: float = 21.3     ## más lejos que esto de casa, pasta volviendo hacia ella
const PASTO_PEGADO_M: float = 3.08    ## más cerca que esto, sale a explorar hacia fuera
const PASTO_GIRO_VUELTA: float = 0.55
const PASTO_GIRO_SALIDA: float = 0.7
const HUECO_ENTRE_ANIMALES_M: float = 6.72 ## se separa de los animales que tiene más cerca que esto
const PESO_SEPARACION: float = 0.85
const NO_DECIDE: Array[WildAnimal.AnimalState] = [
	WildAnimal.AnimalState.FLEE, WildAnimal.AnimalState.EATING, WildAnimal.AnimalState.POUNCE,
	WildAnimal.AnimalState.CHARGE_ATTACK, WildAnimal.AnimalState.CARCASS, WildAnimal.AnimalState.BUTCHERED,
	WildAnimal.AnimalState.IN_BURROW,
]
const BUSCANDO_COMIDA: Array[WildAnimal.AnimalState] = [
	WildAnimal.AnimalState.SEEK_FOOD, WildAnimal.AnimalState.STALK_PREY, WildAnimal.AnimalState.CHASE_PREY,
]
const GRUPOS: Dictionary = {
	WildAnimal.SpeciesType.RABBIT: "ecosystem_rabbits", WildAnimal.SpeciesType.DEER: "ecosystem_deer",
	WildAnimal.SpeciesType.FOX: "ecosystem_foxes", WildAnimal.SpeciesType.BOAR: "ecosystem_boars",
}


## Decide qué le toca hacer ahora según la hora, el hambre y si puede criar.
static func decidir(a: WildAnimal) -> void:
	if a.state in NO_DECIDE:
		return
	if es_de_noche(a):
		_recogerse(a)
		return
	if a.state == WildAnimal.AnimalState.SLEEP:
		a.state = WildAnimal.AnimalState.GRAZE
	elif a.state == WildAnimal.AnimalState.RETURN_HOME and _a_casa(a) <= CASA_A_LA_VISTA_M:
		a.state = WildAnimal.AnimalState.GRAZE
	if a.can_mate_today():
		a.mate_target = _pareja_lista(a)
		if a.mate_target != null:
			a.state = WildAnimal.AnimalState.SEEK_MATE
			return
	if a.is_fully_satiated():
		_descansar_saciado(a)
	elif a.state == WildAnimal.AnimalState.GRAZE:
		_salir_a_comer(a)


static func es_de_noche(a: WildAnimal) -> bool:
	var hora: int = int(WorldClock.current_hour)
	if a.species == WildAnimal.SpeciesType.FOX:
		return hora >= HORAS_NOCHE_ZORRO.x and hora < HORAS_NOCHE_ZORRO.y
	return hora >= HORAS_NOCHE.x or hora < HORAS_NOCHE.y


static func _a_casa(a: WildAnimal) -> float:
	return a.sitio.distance_to(a.casa)


## De noche: vuelve al nido y, ya en él, duerme (el conejo se mete en su madriguera).
static func _recogerse(a: WildAnimal) -> void:
	if _a_casa(a) > EN_CASA_M:
		a.state = WildAnimal.AnimalState.RETURN_HOME
	elif a.species == WildAnimal.SpeciesType.RABBIT:
		a.entrar_en_madriguera()
	else:
		a.state = WildAnimal.AnimalState.SLEEP


## Ya ha comido: deja de buscar y se queda por su zona.
static func _descansar_saciado(a: WildAnimal) -> void:
	if a.state in BUSCANDO_COMIDA:
		a.food_target = null
		a.state = WildAnimal.AnimalState.GRAZE
	if a.state == WildAnimal.AnimalState.GRAZE and _a_casa(a) > CASA_LEJOS_SACIADO_M:
		a.state = WildAnimal.AnimalState.RETURN_HOME


## Con hambre: va a por la comida que encuentre (el zorro, acechando a un conejo vivo).
static func _salir_a_comer(a: WildAnimal) -> void:
	a.food_target = AnimalComida.buscar(a)
	if a.food_target == null:
		if _a_casa(a) > CASA_LEJOS_SIN_COMIDA_M:
			a.state = WildAnimal.AnimalState.RETURN_HOME
		return
	var presa: WildAnimal = a.food_target as WildAnimal
	var viva: bool = presa != null and presa.state != WildAnimal.AnimalState.CARCASS
	a.state = WildAnimal.AnimalState.STALK_PREY if a.species == WildAnimal.SpeciesType.FOX and viva else WildAnimal.AnimalState.SEEK_FOOD


## El de su especie más cercano que también pueda criar hoy.
static func _pareja_lista(a: WildAnimal) -> WildAnimal:
	var mejor: WildAnimal = null
	var mejor_d: float = PAREJA_MAX_M
	for nodo: Node in a.get_tree().get_nodes_in_group(str(GRUPOS[a.species])):
		var otro: WildAnimal = nodo as WildAnimal
		if otro == null or otro == a or not otro.can_mate_today():
			continue
		var d: float = a.sitio.distance_to(otro.sitio)
		if d < mejor_d:
			mejor_d = d
			mejor = otro
	return mejor


## Pasta: ratos de paseo y ratos quieto, sin alejarse mucho de casa ni pegarse a otros animales.
static func pastar(a: WildAnimal, delta: float) -> void:
	a.wander_timer -= delta
	if a.wander_timer <= 0.0:
		if randf() < PASTO_PARADA_PROB:
			a.wander_timer = randf_range(PASTO_PARADA_S.x, PASTO_PARADA_S.y)
			a.wander_dir = Vector2.ZERO
		else:
			a.wander_timer = randf_range(PASTO_PASEO_S.x, PASTO_PASEO_S.y)
			a.wander_dir = _rumbo_de_paseo(a)
	a.andar = a.wander_dir * a.paso_m_s


static func _rumbo_de_paseo(a: WildAnimal) -> Vector2:
	var a_casa: Vector2 = a.casa - a.sitio
	var rumbo: Vector2 = Vector2.RIGHT.rotated(randf() * TAU)
	if a_casa.length() > PASTO_LEJOS_M:
		rumbo = a_casa.normalized().rotated(randf_range(-PASTO_GIRO_VUELTA, PASTO_GIRO_VUELTA))
	elif a_casa.length() < PASTO_PEGADO_M and a_casa != Vector2.ZERO:
		rumbo = (-a_casa).normalized().rotated(randf_range(-PASTO_GIRO_SALIDA, PASTO_GIRO_SALIDA))
	var separacion: Vector2 = _separacion(a)
	if separacion.length_squared() > 0.04:
		rumbo = (rumbo + separacion * PESO_SEPARACION).normalized()
	return rumbo


## Hacia dónde alejarse de los animales cercanos, para que no vayan siempre juntos.
static func _separacion(a: WildAnimal) -> Vector2:
	var suma: Vector2 = Vector2.ZERO
	for nodo: Node in a.get_tree().get_nodes_in_group("wild_animals"):
		var otro: WildAnimal = nodo as WildAnimal
		if otro == null or otro == a or not otro.is_alive_in_ecosystem():
			continue
		var de_el: Vector2 = a.sitio - otro.sitio
		var d: float = de_el.length()
		if d > 0.05 and d < HUECO_ENTRE_ANIMALES_M:
			suma += de_el / d * (1.0 - d / HUECO_ENTRE_ANIMALES_M)
	return suma


## Dos de la misma especie que han comido dos veces hoy se buscan y, juntos un rato, pueden tener una cría.
static func buscar_pareja(a: WildAnimal, delta: float) -> void:
	if not is_instance_valid(a.mate_target) or not a.mate_target.can_mate_today():
		a.mate_target = null
		a.state = WildAnimal.AnimalState.GRAZE
		return
	var hacia: Vector2 = a.mate_target.sitio - a.sitio
	if hacia.length() > PAREJA_JUNTOS_M:
		a.andar = hacia.normalized() * a.paso_m_s * PRISA
		return
	a.andar = Vector2.ZERO
	a.mate_timer += delta
	AnimalRotulo.decir(a, "%s [Cortejo]" % a.animal_name, Color(1.0, 0.65, 0.82))
	if a.mate_timer < CORTEJO_S:
		return
	a.mate_timer = 0.0
	a.mated_today = true
	a.mate_target.mated_today = true
	a.offspring_genetics_tier = mini(GENETICA_MAX, maxi(a.genetics_tier, a.mate_target.genetics_tier) + 1)
	a.pending_offspring = a.pending_offspring or randf() <= CRIA_PROB
	a.mate_target = null
	a.state = WildAnimal.AnimalState.GRAZE


static func volver_a_casa(a: WildAnimal) -> void:
	var a_casa: Vector2 = a.casa - a.sitio
	if a_casa.length() > LLEGA_A_CASA_M:
		a.andar = a_casa.normalized() * a.paso_m_s * PRISA
		return
	a.andar = Vector2.ZERO
	var noche: bool = int(WorldClock.current_hour) >= HORAS_NOCHE.x or int(WorldClock.current_hour) < HORAS_NOCHE.y
	if not noche:
		a.state = WildAnimal.AnimalState.GRAZE
	elif a.species == WildAnimal.SpeciesType.RABBIT:
		a.entrar_en_madriguera()
	else:
		a.state = WildAnimal.AnimalState.SLEEP
