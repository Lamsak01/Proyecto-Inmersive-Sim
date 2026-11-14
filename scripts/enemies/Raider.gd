extends "res://scripts/fisica/CuerpoBase3D.gd"

## Raider: un asaltante de las incursiones (un bandido o un jabalí). Entra por el este, va a por quien defiende el
## pueblo (el protagonista, los guardias y los vecinos con arrojo) y, si nadie lo para, llega a la plaza y saquea.
## Se le puede herir con cualquier arma (su diana 3D); malherido huye. El bandido lleva además una carabina vieja.
## Desde la tanda 4b-3b del paso a 3D (2026-11-14) ES su cuerpo 3D: vive en el escenario 3D y piensa en metros sobre el
## suelo (x → este, y → sur). Ya no tiene nodo ni dibujo en el mapa plano.
## TRADUCTOR: la plaza que saquea aún se lee del mapa plano (mapa/sitio.gd) y aquí se pasa a metros.

signal gone(raider: Node, outcome: String) ## «killed», «fled» o «looted»

const CombatFeel = preload("res://scripts/systems/combat/CombatFeel.gd")
const Sitio = preload("res://mapa/sitio.gd")

const RUTA: String = "res://scripts/enemies/Raider.gd"
const RUTA_MODELO_BANDIDO: String = "res://scripts/visuals/BanditModel3D.gd" ## se cargan al usarlos (sin ciclo de preloads)
const RUTA_MODELO_ANIMAL: String = "res://scripts/visuals/AnimalModel3D.gd"
const MODELO_JABALI: String = "animals/animated/Wolf.glb" ## de momento el lobo (no hay jabalí del mismo estilo)
const ALTO_JABALI_M: float = 0.78
const ANIM_JABALI_M_S: Vector2 = Vector2(2.24, 3.7) ## (andar, correr) a las que encaja su animación
const SITIO_BOTIN: String = "botin_plaza"  ## cruz de «Sitios»: a dónde van a saquear (la plaza)
const ENGAGE_RADIUS: float = 6.16     ## va a por quien tenga más cerca que esto
const MELEE_RANGE: float = 1.23       ## a esta distancia deja de andar y pega
const ALCANCE_GOLPE_M: float = 1.57   ## el golpe alcanza un poco más allá
const BOTIN_M: float = 1.68           ## a esta distancia de la plaza ya ha saqueado
const LLEGA_M: float = 0.06
const VIDA: Dictionary = {"boar": 34.0, "bandit": 42.0}
const PASO_M_S: Dictionary = {"boar": 4.14, "bandit": 3.36}
const DANO: Dictionary = {"boar": 9.0, "bandit": 7.0}
const MASA: Dictionary = {"boar": 2.2, "bandit": 1.0}
const GOLPE: Dictionary = {"boar": "colmillos", "bandit": "bandido"}
const HUIDA_ESTE_M: float = 7.84      ## huye hacia el este hasta alejarse esto de donde entró
const HUIDA_PRISA: float = 1.2
const HUIDA_LLEGA_M: float = 0.22
const HUIDA_ATASCO_S: float = 2.0     ## tanto tiempo huyendo sin avanzar: se da por huido
const MALHERIDO: float = 0.3          ## con menos vida que esta parte, huye
const ELIGE_CADA_S: float = 0.4
const AVISO_S: float = 0.4            ## lo que tarda en soltar el golpe desde que lo prepara
const ENTRE_GOLPES_S: float = 1.1
const DESARMADO_PEGA: float = 0.5
const CADAVER_S: float = 30.0         ## lo que tarda en desaparecer su cuerpo
const CARABINA_M: Vector2 = Vector2(2.24, 7.0) ## (mín., máx.) distancias a las que dispara
const CARABINA_CARTUCHOS: int = 2
const CARABINA_ENTRE_TIROS_S: float = 2.2
const CARABINA_RECARGA_S: float = 2.6
const CARABINA_DANO: float = 9.0
const CARABINA_SANGRA: float = 10.0
const CARABINA_ACIERTO: Vector2 = Vector2(0.35, 0.72) ## (peor, mejor) puntería
const CARABINA_PIERDE_POR_M: float = 0.0536
const PAREDES_M: float = 2.7
const REPASO_PAREDES: int = 6
const ANIM_GOLPE_BAJA_POR_S: float = 2.5

var kind: String = "bandit"          ## «bandit» o «boar»
var max_hp: float = 40.0
var hp: float = 40.0
var speed: float = 3.47              ## m/s
var hit_damage: float = 7.0
var flee_x: float = 106.0            ## hasta dónde huye hacia el este (metros)
var is_dead: bool = false
var fleeing: bool = false
var hit_by_player: bool = false
var facing: Vector2 = Vector2.LEFT
var andar: Vector2 = Vector2.ZERO    ## hacia dónde y a qué velocidad quiere ir (m/s sobre el suelo)
var attack_anim: float = 0.0
var target: Node = null
var disarmed_until_msec: int = 0     ## el bandido sin su cuchillo pega la mitad
var bandit_ammo_loaded: int = CARABINA_CARTUCHOS
var bandit_reload_timer: float = 0.0
var stagger_timer: float = 0.0
var _retarget_t: float = 0.0
var _attack_t: float = 0.6
var _windup_t: float = 0.0
var _recover_t: float = 0.0          ## quieto tras soltar un golpe (más si falló)
var _carbine_cd: float = 1.6
var _done: bool = false
var _huida_parada: float = 0.0       ## segundos seguidos sin avanzar mientras huye
var _vm: Node = null
var _talla_paso: int = 0

## Dónde está, en metros sobre el suelo. Al ponerlo, va allí de golpe y pisa el suelo de ese sitio.
var sitio: Vector2:
	get:
		return Vector2(global_position.x, global_position.z)
	set(valor):
		global_position = Vector3(valor.x, suelo_y(valor.x, valor.y, 0, _vm), valor.y)
		velocity = Vector3.ZERO

var hit_mass: float:
	get:
		return float(MASA[kind])

## Caído en el suelo (lo mira el modelo 3D del jabalí).
var tumbado: bool:
	get:
		return is_dead


## Un asaltante nuevo dentro del escenario 3D (de la clase `guion`, por si es un secuestrador). Devuelve null si el
## escenario aún no existe.
static func crear(arbol: SceneTree, guion: GDScript = null) -> Node:
	var raiz: Node = escenario(arbol)
	if raiz == null:
		return null
	var r: Node = (guion if guion != null else load(RUTA) as GDScript).new()
	raiz.add_child(r)
	return r


func _ready() -> void:
	_vm = get_tree().get_first_node_in_group("village_manager")
	_crear_forma()
	_poner_diana(self)


## Lo prepara como bandido o jabalí en `donde` (metros sobre el suelo); `hp_mult` baja su vida si llega cansado.
func setup(p_kind: String, donde: Vector2, hp_mult: float = 1.0) -> void:
	kind = p_kind
	name = "Raider_%s_%d" % [kind, get_instance_id()]
	sitio = donde
	flee_x = donde.x + HUIDA_ESTE_M
	add_to_group("raiders")
	max_hp = float(VIDA[kind]) * hp_mult
	hp = max_hp
	speed = float(PASO_M_S[kind])
	hit_damage = float(DANO[kind])
	_vestir(self, false)
	if kind != "boar":
		(load(RUTA_MODELO_BANDIDO) as GDScript).call("attach", self)
		return
	var modelo: Node = (load(RUTA_MODELO_ANIMAL) as GDScript).call("poner", self, MODELO_JABALI, ALTO_JABALI_M)
	if modelo != null:
		modelo.call("pasos", ANIM_JABALI_M_S.x, ANIM_JABALI_M_S.y)


func take_damage(data: DamageData) -> void:
	if is_dead or _done:
		return
	if data != null and is_instance_valid(data.source) and data.source.is_in_group("player"):
		hit_by_player = true
	hp -= data.amount if data != null else 10.0
	if hp <= 0.0:
		_die()
	elif hp < max_hp * MALHERIDO and not fleeing:
		fleeing = true
		target = null


func _die() -> void:
	is_dead = true
	andar = Vector2.ZERO
	velocity = Vector3.ZERO
	Diana3D.poner_activa(self, false)
	_vestir(self, false) # un cadáver no estorba
	_finish("killed")
	get_tree().create_timer(CADAVER_S).timeout.connect(queue_free)


func _finish(outcome: String) -> void:
	if _done:
		return
	_done = true
	gone.emit(self, outcome)


func is_disarmed() -> bool:
	return Time.get_ticks_msec() < disarmed_until_msec


func disarm(seconds: float = 20.0) -> bool:
	if kind == "boar" or is_disarmed():
		return false
	disarmed_until_msec = Time.get_ticks_msec() + int(seconds * 1000.0)
	_windup_t = 0.0
	return true


func apply_parry_stagger(duration: float = 0.8, _quiet: bool = false) -> void:
	stagger_timer = maxf(stagger_timer, duration)
	_windup_t = 0.0
	_attack_t = maxf(_attack_t, duration)
	andar = Vector2.ZERO


## Alguien que anda contra él lo aparta un poco (lo llama el cuerpo del protagonista).
func apartar(desplazamiento: Vector3) -> void:
	move_and_collide(desplazamiento)


## Un empujón de golpe (el de un golpe recibido), en metros sobre el suelo: choca con las paredes.
func empujar_suelo(desplazamiento: Vector2) -> void:
	move_and_collide(Vector3(desplazamiento.x, 0.0, desplazamiento.y))


func _physics_process(delta: float) -> void:
	if is_dead or _done:
		return
	andar = Vector2.ZERO
	attack_anim = maxf(0.0, attack_anim - delta * ANIM_GOLPE_BAJA_POR_S)
	if stagger_timer > 0.0:
		stagger_timer = maxf(0.0, stagger_timer - delta)
		_windup_t = 0.0
	elif fleeing:
		_huir(delta)
		return
	elif _recover_t > 0.0:
		_recover_t = maxf(0.0, _recover_t - delta)
	elif _windup_t > 0.0:
		_preparar_golpe(delta)
	else:
		_ir_a_lo_suyo(delta)
	if not _done:
		_moverse(delta)


## Sin nada entre manos: va a por su objetivo o, si no tiene, a saquear la plaza.
func _ir_a_lo_suyo(delta: float) -> void:
	_retarget_t -= delta
	if _retarget_t <= 0.0:
		_retarget_t = ELIGE_CADA_S
		target = _pick_target()
	if is_instance_valid(target):
		_acosar(delta)
		return
	var botin: Vector2 = Lugar.a_suelo(Sitio.mundo(SITIO_BOTIN))
	_ir_hacia(botin, speed)
	if sitio.distance_to(botin) <= BOTIN_M:
		_finish("looted")
		queue_free()


## Malherido: corre hacia el este. Si llega lejos o se queda atascado contra algo, se da por huido.
func _huir(delta: float) -> void:
	_windup_t = 0.0
	var antes: Vector2 = sitio
	_ir_hacia(Vector2(flee_x, sitio.y), speed * HUIDA_PRISA)
	_moverse(delta)
	var paso_min: float = speed * HUIDA_PRISA * delta * 0.25 # menos de un cuarto del paso esperado: está contra algo
	_huida_parada = _huida_parada + delta if sitio.distance_to(antes) < paso_min else 0.0
	if sitio.x >= flee_x - HUIDA_LLEGA_M or _huida_parada >= HUIDA_ATASCO_S:
		_finish("fled")
		queue_free()


## Con el golpe preparado: al acabar el aviso lo suelta; si el objetivo ya no está a tiro, falla y queda vendido.
func _preparar_golpe(delta: float) -> void:
	_windup_t = maxf(0.0, _windup_t - delta)
	if _windup_t > 0.0:
		return
	_attack_t = ENTRE_GOLPES_S
	var sensacion: Dictionary = CombatFeel.attack_feel(str(GOLPE[kind]))
	CombatFeel.enemy_swing(self, str(GOLPE[kind]))
	if is_instance_valid(target) and sitio.distance_to(Lugar.de(target)) <= ALCANCE_GOLPE_M:
		_hit(target)
		_recover_t = float(sensacion["recover"])
	else:
		_recover_t = float(sensacion["miss_recover"])


## Va a por su objetivo: de lejos se acerca (y el bandido dispara su carabina); encima, prepara el golpe.
func _acosar(delta: float) -> void:
	var d: float = sitio.distance_to(Lugar.de(target))
	var con_carabina: bool = kind == "bandit" and not is_disarmed()
	if con_carabina:
		_cuidar_carabina(delta)
	if d > MELEE_RANGE:
		_ir_hacia(Lugar.de(target), speed)
		if con_carabina and bandit_reload_timer <= 0.0 and _carbine_cd <= 0.0 and d >= CARABINA_M.x and d <= CARABINA_M.y:
			_disparar_carabina(target, d)
		return
	_attack_t -= delta
	if _attack_t <= 0.0:
		_windup_t = AVISO_S
		attack_anim = 1.0


func _cuidar_carabina(delta: float) -> void:
	if bandit_reload_timer <= 0.0:
		_carbine_cd = maxf(0.0, _carbine_cd - delta)
		return
	bandit_reload_timer = maxf(0.0, bandit_reload_timer - delta)
	if bandit_reload_timer <= 0.0:
		bandit_ammo_loaded = CARABINA_CARTUCHOS


func _ir_hacia(meta: Vector2, rapidez: float) -> void:
	var falta: Vector2 = meta - sitio
	if falta.length() < LLEGA_M:
		return
	andar = falta.normalized() * rapidez
	facing = falta.normalized()


## Da el paso de este fotograma con su cuerpo: choca con paredes y muebles.
func _moverse(delta: float) -> void:
	var paso: int = Engine.get_physics_frames()
	if paso - _talla_paso >= TALLA_CADA:
		_talla_paso = paso
		_vestir(self, false)
	_suelo_y = suelo_y(global_position.x, global_position.z, 0, _vm)
	_pedir_paredes(_vm, PAREDES_M, REPASO_PAREDES)
	_paso_fisico(andar, delta)
	_pisar()


## Lo más cercano a lo que pegar: el protagonista o un vecino que esté defendiendo (guardias y vecinos con arrojo).
func _pick_target() -> Node:
	var mejor: Node = null
	var mejor_d: float = ENGAGE_RADIUS
	var pl: Node = get_tree().get_first_node_in_group("player")
	if pl != null and pl.get("is_dead") != true and sitio.distance_to(Lugar.de(pl)) < mejor_d:
		mejor_d = sitio.distance_to(Lugar.de(pl))
		mejor = pl
	for nodo: Node in get_tree().get_nodes_in_group("village_npcs"):
		var n: VillageNPC = nodo as VillageNPC
		if n == null or n.is_dead or n.is_downed or not n.is_conscious():
			continue
		if n.errand_kind != "raid_defend" and not (int(n.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)]):
			continue
		var d: float = sitio.distance_to(Lugar.de(n))
		if d < mejor_d:
			mejor_d = d
			mejor = n
	return mejor


func _hit(t: Node) -> void:
	attack_anim = 1.0
	if not t.has_method("take_damage"):
		return
	var d := DamageData.new()
	d.amount = hit_damage * (DESARMADO_PEGA if is_disarmed() else 1.0)
	d.weapon_tag = "Embestida de jabalí" if kind == "boar" else "Tajo de bandido"
	d.knockback_force = float(CombatFeel.attack_feel(str(GOLPE[kind]))["push"])
	d.source = self
	t.call("take_damage", d)


## Carabina vieja con poca puntería: gasta un cartucho y, a media distancia, puede errar el tiro.
func _disparar_carabina(t: Node, dist: float) -> void:
	bandit_ammo_loaded -= 1
	_carbine_cd = CARABINA_ENTRE_TIROS_S
	if bandit_ammo_loaded <= 0:
		bandit_reload_timer = CARABINA_RECARGA_S
	attack_anim = 0.85
	if not is_instance_valid(t) or not t.has_method("take_damage"):
		return
	if randf() > clampf(CARABINA_ACIERTO.y - (dist - CARABINA_M.x) * CARABINA_PIERDE_POR_M, CARABINA_ACIERTO.x, CARABINA_ACIERTO.y):
		return
	var d := DamageData.new()
	d.amount = CARABINA_DANO
	d.type = CombatConstants.DamageType.CUT
	d.bleed_buildup = CARABINA_SANGRA
	d.weapon_tag = "Carabina Vieja de Bandido"
	d.is_ranged_projectile = true
	d.is_firearm_bullet = true
	d.firearm_kind = "pistol"
	d.shot_distance_px = dist / Mapa3D.ESCALA # HealthComponent aún mide en el mapa plano
	d.source = self
	t.call("take_damage", d)
