class_name DomesticPet
extends "res://scripts/fisica/CuerpoBase3D.gd"

## Mascota del pueblo (perro o gato): vive alrededor de la casa de su familia, pasea, duerme en su cama, come de su
## cuenco y se deja acariciar o alimentar con [E]. Si la atacan, el gato huye y el perro se revuelve; maltratarla es delito.
## Desde la tanda 4b-3 del paso a 3D (2026-11-14) ES su cuerpo 3D: vive en el escenario 3D y piensa en metros sobre el
## suelo (x → este, y → sur). Ya no tiene nodo, dibujo ni áreas en el mapa plano: se le hiere por su Diana3D y se la usa
## por su Tocable3D. Sus piezas están en `mascotas/` (MascotaNecesidades, MascotaPelea, MascotaCasa, MascotaTrato).

enum PetType { DOG, CAT }

const RUTA_MODELO: String = "res://scripts/visuals/AnimalModel3D.gd" ## se carga al usarlo (sin ciclo de preloads)
## Modelo 3D y alto (m) de cada clase. El gato usa de momento el modelo del zorro (no hay gato).
const MODELOS: Dictionary = {PetType.DOG: ["animals/animated/ShibaInu.glb", 0.62], PetType.CAT: ["animals/animated/Fox.glb", 0.45]}
const VIDA: Dictionary = {PetType.DOG: 45.0, PetType.CAT: 24.0}
const AGUANTE_ATURDIR: Dictionary = {PetType.DOG: 60.0, PetType.CAT: 35.0}
const ATURDIDA_S: float = 6.0
const AFECTO_PERDIDO_AL_PEGARLE: float = 45.0
const PAREDES_M: float = 2.7          ## pide las paredes del mundo a esta distancia a la redonda
const REPASO_PAREDES: int = 6
const ZONA_E_M: float = 0.5           ## radio de la zona donde la tecla E la encuentra
const ROTULO_ALTO_M: float = 0.9
const ROTULO_CADA_S: float = 0.1
const SOBRE_EL_ROTULO_M: float = 0.3   ## lo que dice sale por encima de su nombre, sin taparlo
const COLOR_ROTULO: Color = Color(0.95, 0.91, 0.83)

@export var pet_type: PetType = PetType.DOG
@export var pet_name: String = "Toby"
@export var owner_label: String = "Granja"
@export var family_id: String = "none"
@export var is_guard_dog: bool = false
@export var tint_color: Color = Color.WHITE

var hit_mass: float = 0.5            ## un animal pequeño sale despedido con cualquier golpe
var casa: Vector2 = Vector2.ZERO     ## su cama y su cuenco (metros sobre el suelo)
var andar: Vector2 = Vector2.ZERO    ## hacia dónde y a qué velocidad quiere ir (m/s sobre el suelo)
var is_fed_today: bool = true
var affection: float = 75.0
var need_hunger: float = 88.0
var digestion_buffer: float = 0.0
var need_energy: float = 92.0
var is_dead: bool = false
var corpse_looted: bool = false
var is_stunned_flag: bool = false
var is_sleeping: bool = false
var is_hostile: bool = false
var hostile_timer: float = 0.0
var flee_timer: float = 0.0
var flee_de: Vector2 = Vector2.ZERO
var attack_cooldown: float = 0.0
var bite_windup_timer: float = 0.0
var stagger_timer: float = 0.0
var starve_timer: float = 0.0
var paseo_meta: Vector2 = Vector2.ZERO
var paseo_s: float = 1.0
var vuelta_s: float = 0.0
var vigila_s: float = 0.4
var ladrido_s: float = 0.0
var health_comp: HealthComponent = null
var stun_comp: StunComponent = null
var rotulo: Label3D = null           ## su nombre, cuando es lo que la tecla E tiene elegido
var zona_e: Tocable3D = null

var _vm: Node = null
var _talla_paso: int = 0
var _rotulo_s: float = 0.0

## Dónde está, en metros sobre el suelo. Al ponerlo, va allí de golpe y pisa el suelo de ese sitio.
var sitio: Vector2:
	get:
		return Vector2(global_position.x, global_position.z)
	set(valor):
		global_position = Vector3(valor.x, suelo_y(valor.x, valor.y, 0, _vm), valor.y)
		velocity = Vector3.ZERO

## Tumbada en el suelo: muerta o aturdida (lo mira su modelo 3D).
var tumbado: bool:
	get:
		return is_dead or is_stunned_flag


## Una mascota nueva dentro del escenario 3D. Devuelve null si el escenario aún no existe.
static func crear(arbol: SceneTree) -> DomesticPet:
	var raiz: Node = escenario(arbol)
	if raiz == null:
		return null
	var m := DomesticPet.new()
	raiz.add_child(m)
	return m


func _ready() -> void:
	_vm = get_tree().get_first_node_in_group("village_manager")
	_crear_forma()
	_poner_diana(self)
	add_to_group("domestic_pets")
	WorldClock.day_passed.connect(_on_day_passed)


## La pone en su casa con su vida, su modelo y su zona de la tecla E (lo llama quien la crea, con sus datos ya puestos).
func instalar(p_casa: Vector2) -> void:
	casa = p_casa
	sitio = p_casa
	paseo_meta = p_casa
	health_comp = HealthComponent.new()
	health_comp.name = "HealthComponent"
	health_comp.max_health = float(VIDA[pet_type])
	health_comp.current_health = health_comp.max_health
	health_comp.died.connect(morir)
	health_comp.bleed_triggered.connect(func(_dps: float = 0.0) -> void: decir("¡Sangrado!", Color.CRIMSON))
	add_child(health_comp)
	stun_comp = StunComponent.new()
	stun_comp.name = "StunComponent"
	stun_comp.max_stun = float(AGUANTE_ATURDIR[pet_type])
	stun_comp.stun_duration = ATURDIDA_S
	stun_comp.stunned.connect(_on_stunned)
	add_child(stun_comp)
	(load(RUTA_MODELO) as GDScript).call("attach", self, str((MODELOS[pet_type] as Array)[0]), float((MODELOS[pet_type] as Array)[1]) / Mapa3D.ESCALA, 0.0, tint_color)
	zona_e = Tocable3D.poner(self, self, ZONA_E_M)
	rotulo = Label3D.new()
	rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	rotulo.fixed_size = true
	rotulo.font_size = TextoFlotante3D.TAMANO_LETRA
	rotulo.pixel_size = TextoFlotante3D.TAMANO_PUNTO
	rotulo.outline_size = TextoFlotante3D.BORDE
	rotulo.outline_modulate = Color.BLACK
	rotulo.position.y = ROTULO_ALTO_M
	rotulo.visible = false
	add_child(rotulo)
	_vestir(self, false)


func _physics_process(delta: float) -> void:
	if corpse_looted:
		return
	_poner_rotulo(delta)
	if is_dead or (WorldClock.has_method("is_time_frozen") and WorldClock.is_time_frozen()):
		return
	ladrido_s = maxf(0.0, ladrido_s - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	andar = Vector2.ZERO
	if not is_stunned_flag:
		MascotaNecesidades.pasar(self, delta)
		if is_dead:
			return
		_hacer_lo_suyo(delta)
	_moverse(delta)


## Lo que toca ahora: huir, pelear, dormir o pasear (y vigilar, si es guardián). Cada pieza deja en `andar` su paso.
func _hacer_lo_suyo(delta: float) -> void:
	if flee_timer > 0.0:
		MascotaPelea.huir(self, delta)
	elif is_hostile and pet_type == PetType.DOG:
		MascotaPelea.pelear(self, delta)
	else:
		MascotaCasa.vigilar(self, delta)
		if MascotaCasa.toca_dormir(self):
			MascotaCasa.dormir(self, delta)
		else:
			MascotaCasa.pasear(self, delta)


## Da el paso de este fotograma con su cuerpo: choca con las paredes del pueblo.
func _moverse(delta: float) -> void:
	var paso: int = Engine.get_physics_frames()
	if paso - _talla_paso >= TALLA_CADA:
		_talla_paso = paso
		_vestir(self, false)
	_suelo_y = suelo_y(global_position.x, global_position.z, 0, _vm)
	_pedir_paredes(_vm, PAREDES_M, REPASO_PAREDES)
	_paso_fisico(andar, delta)
	_pisar()


## Dice algo sobre ella (un texto que sube y se desvanece).
func decir(texto: String, color: Color) -> void:
	TextoFlotante3D.decir(self, texto, color, ROTULO_ALTO_M + SOBRE_EL_ROTULO_M)


## Su nombre aparece cuando es lo que la tecla E tiene elegido.
func _poner_rotulo(delta: float) -> void:
	_rotulo_s -= delta
	if _rotulo_s > 0.0:
		return
	_rotulo_s = ROTULO_CADA_S
	var pl: Node = get_tree().get_first_node_in_group("player")
	var selector: Variant = pl.get("interaction_selector") if pl != null else null
	var elegida: bool = is_instance_valid(selector) and (selector.call("selected") as Dictionary).get("target") == self
	rotulo.visible = elegida
	if not elegida:
		return
	var estado: String = "Muerto" if is_dead else ("Aturdido" if is_stunned_flag else ("Perro" if pet_type == PetType.DOG else "Gato"))
	rotulo.text = "%s · %s" % [pet_name, estado]
	rotulo.modulate = COLOR_ROTULO


## Algo ha cambiado (ha muerto, la han desollado, se ha cargado partida): pone al día su diana, su zona de la E y su cuerpo.
func al_cambiar_de_estado() -> void:
	Diana3D.poner_activa(self, not is_dead)
	zona_e.collision_layer = 0 if corpse_looted else Capas3D.TOCABLES
	_vestir(self, false)


## Alguien que anda contra ella la aparta un poco (lo llama el cuerpo del protagonista).
func apartar(desplazamiento: Vector3) -> void:
	move_and_collide(desplazamiento)


## Un empujón de golpe (el de un golpe recibido), en metros sobre el suelo: choca con las paredes.
func empujar_suelo(desplazamiento: Vector2) -> void:
	move_and_collide(Vector3(desplazamiento.x, 0.0, desplazamiento.y))


func apply_parry_stagger(duration: float = 0.8, quiet: bool = false) -> void:
	stagger_timer = maxf(stagger_timer, duration)
	bite_windup_timer = 0.0
	attack_cooldown = maxf(attack_cooldown, duration)
	if not quiet:
		decir("¡Desequilibrado!", Color.AQUA)


func take_damage(data: DamageData) -> void:
	if is_dead or corpse_looted:
		return
	is_sleeping = false
	if data != null and is_instance_valid(data.source) and data.source.is_in_group("player"):
		affection = maxf(0.0, affection - AFECTO_PERDIDO_AL_PEGARLE)
		if _vm != null and _vm.has_method("report_pet_assault_crime"):
			_vm.call("report_pet_assault_crime", self)
	MascotaPelea.reaccionar(self, data)
	health_comp.take_damage(data)
	if health_comp.current_health > 0.0:
		stun_comp.take_damage(data)


func _on_stunned(aturdida: bool) -> void:
	if is_dead:
		return
	is_stunned_flag = aturdida
	if aturdida:
		MascotaPelea.calmar(self)


## Muere donde está (`silent`: sin decirlo, al cargar una partida).
func morir(silent: bool = false) -> void:
	if is_dead:
		return
	health_comp.stop_bleeding()
	is_dead = true
	is_sleeping = false
	MascotaPelea.calmar(self)
	al_cambiar_de_estado()
	if not silent:
		decir("%s ha muerto" % pet_name, Color.CRIMSON)


func interact(player: Node) -> void:
	MascotaTrato.usar(self, player)


func _on_day_passed(_new_day: int) -> void:
	if not is_dead:
		is_fed_today = false


func to_save_dict() -> Dictionary:
	return MascotaTrato.guardar(self)


func from_save_dict(data: Dictionary) -> void:
	MascotaTrato.cargar(self, data)
