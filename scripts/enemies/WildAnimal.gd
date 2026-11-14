class_name WildAnimal
extends "res://scripts/fisica/CuerpoBase3D.gd"

## Fauna silvestre con simulación de vida: conejos, ciervos, zorros y jabalíes del bosque.
## - Saciedad y día de reserva: cada animal come hasta 2 veces al día; con 2 queda saciado, gana un día sin necesidad
##   de comer y puede buscar pareja (dos saciados de la misma especie pueden tener una cría al amanecer).
## - El zorro acecha y salta sobre los conejos; el jabalí embiste a quien le hiere; los demás huyen del peligro.
## - En modo demo solo hacen vida tranquila (VidaAnimal): pastar por su rincón, beber, descansar y huir del protagonista.
## Desde la tanda 4b-2 del paso a 3D (2026-11-14) el animal ES su cuerpo 3D: vive en el escenario 3D y piensa en metros
## sobre el suelo (x → este, y → sur). Ya no tiene nodo ni dibujo en el mapa plano. Sus piezas están en `animales/`
## (AnimalAlerta, AnimalAgenda, AnimalComida, AnimalCaza, AnimalJabali, AnimalDespiece, AnimalRotulo) y en VidaAnimal:
## son clases con nombre, sin preloads entre ellas, para no crear ciclos de carga.
## Su cadáver se despieza con [E] a través de un Tocable3D: la E lo encuentra en el mundo 3D (tanda 7-E).

enum SpeciesType { RABBIT, DEER, FOX, BOAR }
enum AnimalState {
	GRAZE, SEEK_FOOD, STALK_PREY, POUNCE, CHASE_PREY, CHARGE_ATTACK,
	EATING, SEEK_MATE, RETURN_HOME, SLEEP, IN_BURROW, FLEE, CARCASS, BUTCHERED
}

const RUTA_MODELO: String = "res://scripts/visuals/AnimalModel3D.gd" ## se carga al usarlo (sin ciclo de preloads)
const RUTA_AGUA: String = "res://scripts/fisica/Agua.gd"
const MAX_MEALS: int = 2
const ESTADOS_FUERA: Array[AnimalState] = [AnimalState.CARCASS, AnimalState.BUTCHERED, AnimalState.IN_BURROW] ## ni piensa ni se le hiere
## Modelo 3D y su alto (m) de cada especie. El jabalí usa de momento el lobo y el conejo una ardilla (no hay otros).
const MODELOS: Dictionary = {
	SpeciesType.RABBIT: ["animals/Squirrel.glb", 0.73],
	SpeciesType.DEER: ["animals/animated/Deer.glb", 1.12],
	SpeciesType.FOX: ["animals/animated/Fox.glb", 0.56],
	SpeciesType.BOAR: ["animals/animated/Wolf.glb", 0.78],
}
const MASAS: Dictionary = {SpeciesType.BOAR: 2.5, SpeciesType.DEER: 1.4, SpeciesType.FOX: 0.7, SpeciesType.RABBIT: 0.5}
const LEJOS_M: float = 28.0          ## más lejos que esto del protagonista piensa más despacio y anda sin mirar paredes
const PENSAR_S: float = 0.16         ## cada cuánto mira amenazas y decide qué hacer
const PENSAR_LEJOS_S: float = 0.45
const PENSAR_DEMO_S: float = 0.3
const PAREDES_M: float = 2.7         ## pide las paredes del mundo a esta distancia a la redonda
const REPASO_PAREDES: int = 30       ## pasos entre repasos de esas paredes
const SUELO_CADA_M: float = 0.25     ## cada cuánto camino vuelve a mirar la altura del suelo
const HUECO_PROTA_M: Vector2 = Vector2(0.84, 1.0)     ## (pequeños, grandes) lo que se apartan del protagonista
const APARTARSE_M_S: Vector2 = Vector2(3.36, 2.13)    ## (pequeños, grandes) y a qué velocidad
const ATURDIDO_FUERTE: float = 50.0  ## un golpe que aturde así lo deja quieto ATURDIDO_S
const ATURDIDO_S: float = 3.0
const JABALI_GOLPES_MIN: int = 3     ## un jabalí aguanta al menos estos golpes
const JABALI_VIDA_POR_GOLPE: float = 0.25
const JABALI_VIDA_MIN: float = 4.0

@export var species: SpeciesType = SpeciesType.DEER
@export var animal_name: String = "Venado del Valle"
@export var max_hp: float = 25.0
@export var paso_m_s: float = 1.34    ## a lo que anda cuando pasta
@export var huida_m_s: float = 6.44   ## a lo que corre cuando huye
@export var alerta_m: float = 5.32    ## a qué distancia nota un peligro
@export var meat_drop: int = 2
@export var leather_drop: int = 1
@export var pelt_item_id: String = "leather"
@export var respawn_days: int = 2
@export var persistence_id: String = ""
@export var managed_by_ecosystem: bool = true
@export_group("Despiece")
@export var enable_advanced_anatomy: bool = true
@export var bones_drop: int = 1
@export var antlers_drop: int = 0
@export var viscera_drop: int = 1
@export var fat_drop: int = 0
@export var genetics_tier: int = 1
@export var max_damage_per_hit: float = 0.0

var offspring_genetics_tier: int = 1
var current_hp: float = 25.0
var respawn_on_day: int = -1
var state: AnimalState = AnimalState.GRAZE
var vida: Dictionary = {}            ## estado de la vida tranquila (VidaAnimal): modo, querencia, meta, sed
var meals_eaten: int = 0
var fed_today: bool = false
var has_reserve_day: bool = false
var is_on_reserve_day: bool = false
var mated_today: bool = false
var pending_offspring: bool = false
var days_hungry: int = 0
var hits_taken_count: int = 0
var escaped_first_pounce: bool = false

var casa: Vector2 = Vector2.ZERO     ## su nido, madriguera o claro (metros sobre el suelo)
var andar: Vector2 = Vector2.ZERO    ## hacia dónde y a qué velocidad quiere ir (m/s sobre el suelo)
var tumbado: bool = false            ## muerto en el suelo (lo mira su modelo 3D)
var wander_dir: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var flee_timer: float = 0.0
var flee_dir: Vector2 = Vector2.RIGHT
var eat_timer: float = 0.0
var mate_timer: float = 0.0
var burrow_hide_timer: float = 0.0
var attack_cooldown: float = 0.0
var stagger_timer: float = 0.0
var pounce_timer: float = 0.0
var pounce_dir: Vector2 = Vector2.RIGHT
var pounce_recovery_timer: float = 0.0
var food_target: Node = null         ## una planta del bosque o un conejo
var mate_target: WildAnimal = null
var boar_aggressor: Node = null
var boar_aggro_timer: float = 0.0
var boar_charge_windup: float = 0.0
var boar_charge_timer: float = 0.0
var boar_melee_windup: float = 0.0
var boar_recover: float = 0.0        ## el jabalí queda quieto tras un topetazo fallido (ventana para castigarle)
var boar_charge_dir: Vector2 = Vector2.RIGHT
var rotulo: Label3D = null           ## lo que se lee sobre él («Zzz», «¡Jabalí enfurecido!», «[E] Desollar…»)
var zona_despiece: Tocable3D = null  ## (solo cadáver) donde la tecla E lo encuentra

var _vm: Node = null
var _prota: Node = null
var _pensar_s: float = 0.0
var _talla_paso: int = 0
var _suelo_mirado_en: Vector3 = Vector3.INF

## Dónde está, en metros sobre el suelo. Al ponerlo, va allí de golpe y pisa el suelo de ese sitio.
var sitio: Vector2:
	get:
		return Vector2(global_position.x, global_position.z)
	set(valor):
		global_position = Vector3(valor.x, global_position.y, valor.y)
		_posar()

## Masa al recibir golpes (1 = una persona): el empujón se divide por ella.
var hit_mass: float:
	get:
		return float(MASAS[species])


## Un animal nuevo dentro del escenario 3D. Devuelve null si el escenario aún no existe.
static func crear(arbol: SceneTree) -> WildAnimal:
	var raiz: Node = escenario(arbol)
	if raiz == null:
		return null
	var a := WildAnimal.new()
	raiz.add_child(a)
	return a


func _ready() -> void:
	_crear_forma()
	_poner_diana(self)
	_vm = get_tree().get_first_node_in_group("village_manager")
	current_hp = max_hp
	_pensar_s = randf_range(0.05, 0.35)
	WorldClock.day_passed.connect(_on_day_passed)
	GameManager.game_loaded.connect(_on_game_loaded)


## Lo coloca en su sitio y le da grupos, modelo y rótulo (lo llama quien lo crea, con sus datos ya puestos).
func setup_animal(p_casa: Vector2, p_sitio: Vector2) -> void:
	casa = p_casa
	sitio = p_sitio
	if persistence_id == "":
		persistence_id = "animal_%s_%d_%d" % [name, int(Lugar.a_mapa(casa).x), int(Lugar.a_mapa(casa).y)]
	add_to_group("wild_animals")
	match species:
		SpeciesType.RABBIT:
			add_to_group("ecosystem_rabbits")
			add_to_group("herbivore_prey")
		SpeciesType.DEER:
			add_to_group("ecosystem_deer")
		SpeciesType.FOX:
			add_to_group("ecosystem_foxes")
			add_to_group("predators")
		SpeciesType.BOAR:
			add_to_group("ecosystem_boars")
	_vestir(self, false)
	(load(RUTA_MODELO) as GDScript).call("poner", self, str((MODELOS[species] as Array)[0]), float((MODELOS[species] as Array)[1]))
	rotulo = AnimalRotulo.crear(self)
	AnimalDespiece.mirar_lo_guardado(self)


func is_alive_in_ecosystem() -> bool:
	return state != AnimalState.CARCASS and state != AnimalState.BUTCHERED


func is_fully_satiated() -> bool:
	return is_on_reserve_day or meals_eaten >= MAX_MEALS


func can_mate_today() -> bool:
	return is_alive_in_ecosystem() and visible and state != AnimalState.IN_BURROW and meals_eaten >= MAX_MEALS and not mated_today


func _physics_process(delta: float) -> void:
	if not is_alive_in_ecosystem():
		return
	if GameManager.is_demo_mode():
		_vida_tranquila(delta)
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if pounce_recovery_timer > 0.0:
		pounce_recovery_timer -= delta
		andar = Vector2.ZERO
		return
	if state == AnimalState.IN_BURROW:
		AnimalAlerta.en_madriguera(self, delta)
		return
	var lejos: bool = _lejos_del_prota()
	if state == AnimalState.POUNCE:
		AnimalCaza.salto(self, delta)
		_moverse(delta, lejos)
		return
	_pensar_s -= delta
	if _pensar_s <= 0.0:
		_pensar_s = PENSAR_LEJOS_S if lejos else PENSAR_S
		AnimalAlerta.mirar_amenazas(self)
		AnimalAgenda.decidir(self)
		AnimalRotulo.poner_al_dia(self, lejos)
	_hacer_lo_suyo(delta)
	if not lejos and state != AnimalState.SLEEP:
		_guardar_distancia_al_prota()
	_moverse(delta, lejos)


## Lo que toca según su estado: cada pieza deja en `andar` hacia dónde quiere ir.
func _hacer_lo_suyo(delta: float) -> void:
	match state:
		AnimalState.GRAZE: AnimalAgenda.pastar(self, delta)
		AnimalState.SEEK_FOOD: AnimalComida.ir_a_comer(self)
		AnimalState.STALK_PREY: AnimalCaza.acechar(self)
		AnimalState.CHASE_PREY: AnimalCaza.perseguir(self)
		AnimalState.CHARGE_ATTACK: AnimalJabali.embestir(self, delta)
		AnimalState.EATING: AnimalComida.comer(self, delta)
		AnimalState.SEEK_MATE: AnimalAgenda.buscar_pareja(self, delta)
		AnimalState.RETURN_HOME: AnimalAgenda.volver_a_casa(self)
		AnimalState.SLEEP: andar = Vector2.ZERO
		AnimalState.FLEE: AnimalAlerta.huir(self, delta)


## Modo demo: la simulación completa está en pausa, pero el animal pasta por su rincón, bebe, descansa y huye.
func _vida_tranquila(delta: float) -> void:
	if state == AnimalState.IN_BURROW:
		AnimalAlerta.en_madriguera(self, delta)
		return
	_pensar_s -= delta
	if _pensar_s <= 0.0:
		_pensar_s = PENSAR_DEMO_S
		AnimalAlerta.mirar_amenazas(self)
	if state == AnimalState.FLEE:
		AnimalAlerta.huir(self, delta)
	else:
		state = AnimalState.GRAZE # cualquier estado de la simulación completa se ignora aquí
		VidaAnimal.paso(self, delta)
	_moverse(delta, _lejos_del_prota())


## Da el paso de este fotograma hacia `andar`. Cerca del protagonista, con su cuerpo: choca con paredes y cuerpos.
## Lejos, donde nadie mira, avanza sin más (simulación barata).
func _moverse(delta: float, lejos: bool) -> void:
	var paso: int = Engine.get_physics_frames()
	if paso - _talla_paso >= TALLA_CADA:
		_talla_paso = paso
		_vestir(self, false)
	if lejos:
		toca_pared = false
		if andar.length_squared() > 0.0001:
			global_position += Vector3(andar.x, 0.0, andar.y) * delta
			_posar_si_ha_andado()
		return
	_suelo_y = suelo_y(global_position.x, global_position.z, 0, _vm)
	_pedir_paredes(_vm, PAREDES_M, REPASO_PAREDES)
	_paso_fisico(andar, delta)
	_pisar()


## Los pies, a la altura del suelo (al aire libre: piso 0).
func _posar() -> void:
	_suelo_y = suelo_y(global_position.x, global_position.z, 0, _vm)
	global_position.y = _suelo_y
	velocity = Vector3.ZERO
	_suelo_mirado_en = global_position


## (Lejos del protagonista) Cada SUELO_CADA_M de camino vuelve a mirar el suelo. Si ese paso lo metería en el agua desde
## tierra firme, no lo da: se queda donde estaba y cambia de rumbo (cerca del protagonista eso lo hacen las paredes).
func _posar_si_ha_andado() -> void:
	if _suelo_mirado_en != Vector3.INF and global_position.distance_squared_to(_suelo_mirado_en) <= SUELO_CADA_M * SUELO_CADA_M:
		return
	if _suelo_mirado_en != Vector3.INF and _es_agua(global_position) and not _es_agua(_suelo_mirado_en):
		global_position = _suelo_mirado_en
		toca_pared = true
		wander_timer = 0.0
		return
	_posar()


## ¿Es agua (río o lago) ese punto del mundo? TRADUCTOR: se pregunta al mapa plano (Agua.gd).
func _es_agua(punto: Vector3) -> bool:
	return bool((load(RUTA_AGUA) as GDScript).call("en_agua", Lugar.a_mapa(Vector2(punto.x, punto.z))))


func _protagonista() -> Node:
	if not is_instance_valid(_prota):
		_prota = get_tree().get_first_node_in_group("player")
	return _prota


func _lejos_del_prota() -> bool:
	var pl: Node = _protagonista()
	return pl != null and sitio.distance_squared_to(Lugar.de(pl)) > LEJOS_M * LEJOS_M


## No se queda pegado al protagonista: si lo tiene encima, se aparta un poco.
func _guardar_distancia_al_prota() -> void:
	var pl: Node = _protagonista()
	if pl == null:
		return
	var pequeno: bool = species == SpeciesType.RABBIT or species == SpeciesType.FOX
	var hueco: float = HUECO_PROTA_M.x if pequeno else HUECO_PROTA_M.y
	var de_el: Vector2 = sitio - Lugar.de(pl)
	var d: float = de_el.length()
	if d >= hueco:
		return
	var fuera: Vector2 = de_el / d if d >= 0.001 else Vector2.RIGHT
	andar += fuera * ((hueco - d) / hueco) * (APARTARSE_M_S.x if pequeno else APARTARSE_M_S.y)


## Alguien que anda contra él lo aparta un poco (lo llama el cuerpo del protagonista). Choca con las paredes.
func apartar(desplazamiento: Vector3) -> void:
	move_and_collide(desplazamiento)


## Un empujón de golpe (el de un golpe recibido), en metros sobre el suelo: choca con las paredes.
func empujar_suelo(desplazamiento: Vector2) -> void:
	move_and_collide(Vector3(desplazamiento.x, 0.0, desplazamiento.y))


## Un golpe lo deja un rato desequilibrado: corta su ataque y no se mueve.
func apply_parry_stagger(duration: float = 0.8, quiet: bool = false) -> void:
	stagger_timer = maxf(stagger_timer, duration)
	boar_charge_windup = 0.0
	boar_charge_timer = 0.0
	boar_melee_windup = 0.0
	attack_cooldown = maxf(attack_cooldown, duration)
	andar = Vector2.ZERO
	if not quiet:
		AnimalRotulo.decir(self, "¡Desequilibrado!", Color.AQUA)


## El zorro lo ha atrapado: cae en el acto.
func take_pounce_takedown() -> void:
	if state in ESTADOS_FUERA:
		return
	current_hp = 0.0
	AnimalDespiece.caer_muerto(self)


func take_damage(data: DamageData) -> void:
	if state in ESTADOS_FUERA:
		return
	var golpe: float = data.amount if data != null else 10.0
	hits_taken_count += 1
	current_hp -= minf(golpe, max_damage_per_hit) if max_damage_per_hit > 0.0 else golpe
	if species == SpeciesType.BOAR and hits_taken_count < JABALI_GOLPES_MIN and current_hp <= 0.0:
		current_hp = maxf(JABALI_VIDA_MIN, max_hp * float(JABALI_GOLPES_MIN - hits_taken_count) * JABALI_VIDA_POR_GOLPE)
	if current_hp <= 0.0:
		AnimalDespiece.caer_muerto(self)
		return
	if data != null and data.stun_buildup >= ATURDIDO_FUERTE:
		pounce_recovery_timer = maxf(pounce_recovery_timer, ATURDIDO_S)
	var atacante: Node = _quien_ataca(data)
	if species == SpeciesType.BOAR and atacante != null:
		AnimalJabali.enfurecer(self, atacante)
	else:
		AnimalAlerta.huir_de(self, Lugar.de(atacante) if atacante != null else sitio)


## Quién le ha hecho daño: el autor del golpe o, si fue un cepo, el protagonista que lo puso.
func _quien_ataca(data: DamageData) -> Node:
	var autor: Node = data.source if data != null and is_instance_valid(data.source) else null
	if autor == null or autor.is_in_group("player_trap") or not (autor is Node2D or autor is Node3D):
		return _protagonista()
	return autor


## Huye del peligro que hay en `peligro` (metros sobre el suelo). Lo usan también los perros guardianes.
func huir_de(peligro: Vector2) -> void:
	AnimalAlerta.huir_de(self, peligro)


func entrar_en_madriguera(segundos: float = 0.0) -> void:
	AnimalAlerta.entrar_en_madriguera(self, segundos)


func salir_de_madriguera() -> void:
	AnimalAlerta.salir_de_madriguera(self)


## Sale del mundo hasta que le toque renacer (ya despiezado, o de reserva en el ecosistema).
func retirar() -> void:
	AnimalDespiece.acabar_despiece(self)


func consume_by_predator() -> void:
	if state == AnimalState.CARCASS:
		AnimalDespiece.acabar_despiece(self)


func get_anatomy_yields() -> Dictionary:
	return AnimalDespiece.piezas(self)


## El protagonista lo despieza con [E] (la E lo encuentra por su Tocable3D).
func interact(player: Node) -> void:
	AnimalDespiece.despiezar(self, player)


func respawn_from_ecosystem(new_genetics: int = 1) -> void:
	genetics_tier = clampi(new_genetics, 1, 3)
	AnimalDespiece.renacer(self)


func _on_day_passed(new_day: int) -> void:
	if not managed_by_ecosystem and state == AnimalState.BUTCHERED and respawn_on_day > 0 and new_day >= respawn_on_day:
		AnimalDespiece.renacer(self)


func _on_game_loaded(_filepath: String) -> void:
	AnimalDespiece.mirar_lo_guardado(self)


func to_save_dict() -> Dictionary:
	return AnimalDespiece.guardar(self)


func from_save_dict(data: Dictionary) -> void:
	AnimalDespiece.cargar(self, data)
