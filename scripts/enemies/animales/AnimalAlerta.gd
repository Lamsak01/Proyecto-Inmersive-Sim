class_name AnimalAlerta
extends RefCounted

## AnimalAlerta: cómo nota un animal salvaje el peligro, cómo huye y cómo se esconde el conejo en su madriguera.
## Pieza de WildAnimal (tanda 4b-2 del paso a 3D, 2026-11-14): todo en metros sobre el suelo.
## El conejo casi no nota al zorro que se le acerca agachado; el jabalí no huye: disputa su sitio a los zorros.

const HUIDA_S: float = 3.2              ## lo que dura una huida
const ALERTA_ACECHO_M: float = 2.58     ## a un zorro agachado solo se le nota así de cerca
const ALERTA_ZORRO: float = 0.95        ## parte de su alerta normal con la que un conejo nota a un zorro que no acecha
const ALERTA_DORMIDO: float = 0.38      ## dormido nota mucho menos
const ALERTA_SIGILO: float = 0.35       ## al protagonista agachado se le nota mucho menos
const RUIDO_FUERTE: float = 1.2         ## por encima de este ruido del protagonista…
const ALERTA_RUIDO: float = 1.55        ## …se le nota desde más lejos
const MADRIGUERA_CERCA_M: float = 10.64 ## un conejo que huye va a su madriguera si la tiene así de cerca…
const MADRIGUERA_DE_CARA: float = -0.25 ## …y no le pilla de espaldas al peligro
const MADRIGUERA_ENTRA_M: float = 1.0   ## a esta distancia de la boca, se mete
const ESCONDIDO_S: float = 7.0          ## lo que se queda dentro tras un susto
const SALIDA_M: float = 0.56            ## sale a esta distancia de la boca
const HORA_SALIR: int = 6               ## de día sale solo (de HORA_SALIR a HORA_ENTRAR)
const HORA_ENTRAR: int = 20
const GIRO_PARED: Vector2 = Vector2(1.0, 2.2) ## (mín., máx.) lo que gira, en radianes, si choca huyendo
const DISPUTA_PROB: float = 0.015       ## cada vez que piensa, lo fácil que es que un jabalí la tome con un zorro cercano
const DISPUTA_M: float = 3.0
const DISPUTA_MORDISCO_PROB: float = 0.55
const DISPUTA_MORDISCO: float = 10.0
const QUIETOS: Array[WildAnimal.AnimalState] = [
	WildAnimal.AnimalState.IN_BURROW, WildAnimal.AnimalState.CARCASS, WildAnimal.AnimalState.BUTCHERED,
	WildAnimal.AnimalState.POUNCE, WildAnimal.AnimalState.CHARGE_ATTACK, WildAnimal.AnimalState.EATING,
]


## Mira si hay algo de lo que huir (o, si es un jabalí, un zorro al que plantar cara).
static func mirar_amenazas(a: WildAnimal) -> void:
	if a.state in QUIETOS:
		return
	if a.species == WildAnimal.SpeciesType.BOAR:
		_disputa_con_zorros(a)
		return
	if a.species == WildAnimal.SpeciesType.RABBIT and _huir_de_un_zorro(a):
		return
	var pl: Node = a._protagonista()
	if pl != null and a.sitio.distance_to(Lugar.de(pl)) <= _alerta_ante_el_prota(a, pl):
		huir_de(a, Lugar.de(pl))


static func _disputa_con_zorros(a: WildAnimal) -> void:
	if a.attack_cooldown > 0.0 or randf() >= DISPUTA_PROB:
		return
	for nodo: Node in a.get_tree().get_nodes_in_group("ecosystem_foxes"):
		var zorro: WildAnimal = nodo as WildAnimal
		if zorro == null or not zorro.is_alive_in_ecosystem() or not zorro.visible or a.sitio.distance_to(zorro.sitio) > DISPUTA_M:
			continue
		AnimalJabali.enfurecer(a, zorro)
		if randf() < DISPUTA_MORDISCO_PROB and zorro.attack_cooldown <= 0.0:
			var mordisco := DamageData.new()
			mordisco.amount = DISPUTA_MORDISCO
			mordisco.type = CombatConstants.DamageType.BLUNT
			mordisco.source = zorro
			a.take_damage(mordisco)
		return


## ¿Hay un zorro con hambre lo bastante cerca? Entonces el conejo huye de él.
static func _huir_de_un_zorro(a: WildAnimal) -> bool:
	for nodo: Node in a.get_tree().get_nodes_in_group("predators"):
		var zorro: WildAnimal = nodo as WildAnimal
		if zorro == null or not zorro.is_alive_in_ecosystem() or not zorro.visible:
			continue
		if zorro.is_fully_satiated() and zorro.state == WildAnimal.AnimalState.GRAZE:
			continue
		var alerta: float = ALERTA_ACECHO_M if zorro.state == WildAnimal.AnimalState.STALK_PREY else a.alerta_m * ALERTA_ZORRO
		if a.sitio.distance_to(zorro.sitio) <= alerta:
			huir_de(a, zorro.sitio)
			return true
	return false


## A qué distancia nota al protagonista, según la hora, si duerme y si el protagonista va agachado o haciendo ruido.
static func _alerta_ante_el_prota(a: WildAnimal, pl: Node) -> float:
	var alerta: float = a.alerta_m * WorldClock.get_vision_multiplier()
	if a.state == WildAnimal.AnimalState.SLEEP:
		alerta *= ALERTA_DORMIDO
	if pl.has_method("is_stealthing") and bool(pl.call("is_stealthing")):
		alerta *= ALERTA_SIGILO
		if pl.has_method("get_stealth_detection_multiplier"):
			alerta *= float(pl.call("get_stealth_detection_multiplier"))
	elif pl.has_method("get_noise_multiplier") and float(pl.call("get_noise_multiplier")) > RUIDO_FUERTE:
		alerta *= ALERTA_RUIDO
	return alerta


## Empieza a huir del peligro que hay en `peligro`. El conejo, si puede, hacia su madriguera.
static func huir_de(a: WildAnimal, peligro: Vector2) -> void:
	if a.state in WildAnimal.ESTADOS_FUERA:
		return
	var fuera: Vector2 = (a.sitio - peligro).normalized()
	if fuera == Vector2.ZERO:
		fuera = Vector2.LEFT
	if a.species == WildAnimal.SpeciesType.RABBIT:
		var a_casa: Vector2 = a.casa - a.sitio
		if a_casa.length() < MADRIGUERA_CERCA_M and a_casa.normalized().dot(fuera) > MADRIGUERA_DE_CARA:
			fuera = a_casa.normalized()
	a.flee_dir = fuera
	a.flee_timer = HUIDA_S
	a.state = WildAnimal.AnimalState.FLEE


static func huir(a: WildAnimal, delta: float) -> void:
	a.flee_timer -= delta
	a.andar = a.flee_dir * a.huida_m_s
	if a.species == WildAnimal.SpeciesType.RABBIT and a.sitio.distance_to(a.casa) <= MADRIGUERA_ENTRA_M:
		entrar_en_madriguera(a, ESCONDIDO_S)
		return
	if a.toca_pared: # chocó con algo en su último paso: cambia de rumbo
		a.flee_dir = a.flee_dir.rotated(randf_range(GIRO_PARED.x, GIRO_PARED.y))
	if a.flee_timer <= 0.0:
		a.state = WildAnimal.AnimalState.GRAZE
		a.andar = Vector2.ZERO


## Se mete en la madriguera `segundos` (0: hasta que sea de día). Dentro ni se le ve ni se le puede herir.
static func entrar_en_madriguera(a: WildAnimal, segundos: float) -> void:
	a.state = WildAnimal.AnimalState.IN_BURROW
	a.burrow_hide_timer = segundos
	a.andar = Vector2.ZERO
	a.visible = false
	Diana3D.poner_activa(a, false)


static func salir_de_madriguera(a: WildAnimal) -> void:
	if a.state != WildAnimal.AnimalState.IN_BURROW:
		return
	a.state = WildAnimal.AnimalState.GRAZE
	a.sitio = a.casa + Vector2.RIGHT.rotated(randf() * TAU) * SALIDA_M
	a.visible = true
	if not a.is_in_group("wild_animals"):
		a.add_to_group("wild_animals")
	Diana3D.poner_activa(a, true)


static func en_madriguera(a: WildAnimal, delta: float) -> void:
	if a.burrow_hide_timer > 0.0:
		a.burrow_hide_timer -= delta
		if a.burrow_hide_timer <= 0.0:
			salir_de_madriguera(a)
		return
	var hora: int = int(WorldClock.current_hour)
	if hora >= HORA_SALIR and hora < HORA_ENTRAR:
		salir_de_madriguera(a)
