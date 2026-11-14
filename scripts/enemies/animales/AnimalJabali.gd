class_name AnimalJabali
extends RefCounted

## AnimalJabali: el jabalí no huye. Si le hieren (o un zorro le disputa el sitio) se enfurece: escarba, embiste a toda
## velocidad y, ya encima, da un topetazo con los colmillos. Tras fallar queda un momento quieto: es cuando castigarle.
## Pieza de WildAnimal (tanda 4b-2 del paso a 3D, 2026-11-14): todo en metros sobre el suelo.

const CombatFeel = preload("res://scripts/systems/combat/CombatFeel.gd")

const FURIA_S: float = 11.5          ## lo que le dura el enfado
const ESCARBAR_S: float = 0.4        ## aviso antes de embestir
const EMBESTIDA_S: float = 0.5
const EMBESTIDA_M_S: float = 9.41
const EMBESTIDA_DESDE_M: float = 6.44 ## embiste si tiene al rival más cerca que esto
const EMBESTIDA_ALCANZA_M: float = 1.23
const TOPETAZO_DESDE_M: float = 1.12 ## ya encima, en vez de embestir da un topetazo
const TOPETAZO_AVISO_S: float = 0.4
const TOPETAZO_ALCANZA_M: float = 1.46
const TOPETAZO_FALLO_ESPERA_S: float = 1.0
const ACOSO_M_S: float = 4.82        ## a lo que persigue hasta tener al rival a tiro
const DESISTE_M: float = 15.4        ## si el rival se aleja tanto, se le pasa
const GOLPE_ESPERA_S: float = 1.35   ## entre un golpe y el siguiente
const GOLPE_DANO: float = 18.0
const GOLPE_ATURDE: float = 32.0
const EMPUJE_PX_S: float = 180.0     ## lo que lanza a quien alcanza (TRADUCTOR: `apply_push` del golpeado aún va en el mapa plano)
const TIPO_GOLPE: String = "colmillos"
const COLOR_AVISO: Color = Color.ORANGE_RED


## Se enfurece con `rival` (quien le ha herido, o un zorro) y empieza a escarbar para embestirle.
static func enfurecer(a: WildAnimal, rival: Node) -> void:
	if a.state in WildAnimal.ESTADOS_FUERA:
		return
	a.boar_aggressor = rival
	a.boar_aggro_timer = FURIA_S
	a.boar_charge_windup = ESCARBAR_S
	a.boar_charge_timer = 0.0
	a.boar_melee_windup = 0.0
	_apuntar(a, Lugar.de(rival) - a.sitio)
	a.state = WildAnimal.AnimalState.CHARGE_ATTACK
	AnimalRotulo.decir(a, "¡Jabalí enfurecido!", COLOR_AVISO)


static func _apuntar(a: WildAnimal, hacia: Vector2) -> void:
	a.boar_charge_dir = hacia.normalized() if hacia.length() > 0.05 else Vector2.RIGHT


static func _rival_fuera_de_juego(rival: Node) -> bool:
	if not is_instance_valid(rival) or rival.get("is_dead") == true or rival.get("is_downed") == true:
		return true
	return rival is WildAnimal and not (rival as WildAnimal).is_alive_in_ecosystem()


static func _calmarse(a: WildAnimal) -> void:
	a.boar_aggressor = null
	a.boar_charge_windup = 0.0
	a.boar_charge_timer = 0.0
	a.boar_melee_windup = 0.0
	a.andar = Vector2.ZERO
	a.state = WildAnimal.AnimalState.GRAZE


## Un paso de su pelea: desequilibrado, calmándose, reponiéndose, golpeando, embistiendo, escarbando o acosando.
static func embestir(a: WildAnimal, delta: float) -> void:
	a.andar = Vector2.ZERO
	if a.stagger_timer > 0.0:
		a.stagger_timer = maxf(0.0, a.stagger_timer - delta)
		a.boar_charge_windup = 0.0
		a.boar_charge_timer = 0.0
		a.boar_melee_windup = 0.0
		return
	a.boar_aggro_timer -= delta
	if a.boar_aggro_timer <= 0.0 or _rival_fuera_de_juego(a.boar_aggressor) or a.sitio.distance_to(Lugar.de(a.boar_aggressor)) > DESISTE_M:
		_calmarse(a)
		return
	var hacia: Vector2 = Lugar.de(a.boar_aggressor) - a.sitio
	if a.boar_recover > 0.0:
		a.boar_recover = maxf(0.0, a.boar_recover - delta)
	elif a.boar_melee_windup > 0.0:
		_topetazo(a, hacia, delta)
	elif a.boar_charge_timer > 0.0:
		_carrera(a, hacia, delta)
	elif a.boar_charge_windup > 0.0:
		_escarbar(a, hacia, delta)
	else:
		_acosar(a, hacia)


## Ya encima del rival: tras el aviso, da el topetazo; si falla, queda vendido un momento.
static func _topetazo(a: WildAnimal, hacia: Vector2, delta: float) -> void:
	a.boar_melee_windup = maxf(0.0, a.boar_melee_windup - delta)
	if a.boar_melee_windup > 0.0:
		return
	CombatFeel.enemy_swing(a, TIPO_GOLPE)
	var sensacion: Dictionary = CombatFeel.attack_feel(TIPO_GOLPE)
	if hacia.length() <= TOPETAZO_ALCANZA_M:
		_golpear(a, a.boar_aggressor)
		a.boar_recover = float(sensacion["recover"])
	else:
		a.attack_cooldown = TOPETAZO_FALLO_ESPERA_S
		a.boar_recover = float(sensacion["miss_recover"])


static func _carrera(a: WildAnimal, hacia: Vector2, delta: float) -> void:
	a.boar_charge_timer -= delta
	a.andar = a.boar_charge_dir * EMBESTIDA_M_S
	if hacia.length() <= EMBESTIDA_ALCANZA_M and a.attack_cooldown <= 0.0:
		_golpear(a, a.boar_aggressor)
		a.boar_charge_timer = 0.0
		a.andar = Vector2.ZERO


## Escarba el suelo mirando al rival; al acabar, sale embistiendo.
static func _escarbar(a: WildAnimal, hacia: Vector2, delta: float) -> void:
	a.boar_charge_windup -= delta
	_apuntar(a, hacia)
	if a.boar_charge_windup <= 0.0:
		a.boar_charge_timer = EMBESTIDA_S
		AnimalRotulo.decir(a, "¡EMBESTIDA!", Color(1.0, 0.3, 0.2))


## Persigue al rival hasta tenerlo a tiro de embestida o, si ya lo tiene encima, de topetazo.
static func _acosar(a: WildAnimal, hacia: Vector2) -> void:
	var d: float = hacia.length()
	if a.attack_cooldown > 0.0 or d > EMBESTIDA_DESDE_M:
		a.andar = hacia.normalized() * ACOSO_M_S
		return
	if d <= TOPETAZO_DESDE_M:
		a.boar_melee_windup = TOPETAZO_AVISO_S
	else:
		a.boar_charge_windup = ESCARBAR_S
	_apuntar(a, hacia)
	AnimalRotulo.decir(a, "¡!", COLOR_AVISO)


static func _golpear(a: WildAnimal, rival: Node) -> void:
	a.attack_cooldown = GOLPE_ESPERA_S
	if not is_instance_valid(rival):
		return
	if rival.has_method("take_damage"):
		var golpe := DamageData.new()
		golpe.amount = GOLPE_DANO
		golpe.type = CombatConstants.DamageType.BLUNT
		golpe.stun_buildup = GOLPE_ATURDE
		golpe.knockback_force = float(CombatFeel.attack_feel(TIPO_GOLPE)["push"])
		golpe.source = a
		rival.call("take_damage", golpe)
	if rival.has_method("apply_push"):
		rival.call("apply_push", a.boar_charge_dir * EMPUJE_PX_S)
