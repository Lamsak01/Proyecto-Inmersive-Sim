extends "res://scripts/fisica/CuerpoBase3D.gd"

## Animal vivo de corral (Bloque FIS4): cada ejemplar de `ranch_herd`, en el corral del Rancho del Sur. Pasea despacio
## dentro de su valla, crece según su etapa (`chick`, `juvenile`, `adult`) y de noche se queda quieto.
## Desde la tanda 4b del paso a 3D (2026-11-14) ES su cuerpo 3D: vive en el escenario 3D y todo lo suyo va en metros.
## Ya no tiene nodo ni dibujo en el mapa plano. Un adulto estorba el paso; a gallinas y crías se les pasa por encima.

const AnimalModel3DScript = preload("res://scripts/visuals/AnimalModel3D.gd")

const RUTA: String = "res://scripts/obstacles/LivestockAnimal.gd"

const ETAPAS: Array[String] = ["chick", "juvenile", "adult"]
const MODELO_GALLINA: String = "procedural:chicken"
const ALTOS_GALLINA: Array[float] = [0.31, 0.39, 0.5] ## alto (m) de cría, joven y adulto
## Modelo y altos (m) de cría, joven y adulto de cada especie que no es gallina.
const MODELOS: Dictionary = {
	"sheep": ["animals/animated/Alpaca.glb", [0.53, 0.7, 0.87]],
	"cow": ["animals/Cow.obj", [0.59, 0.76, 0.92]],
	"bull": ["animals/Bull.obj", [0.62, 0.81, 0.98]],
	"donkey": ["animals/Donkey.obj", [0.53, 0.7, 0.84]],
	"horse": ["animals/animated/Horse.glb", [0.64, 0.84, 1.04]],
}
const PASO_OVEJA_M_S: float = 0.62  ## a lo que pasea una oveja
const PASO_M_S: float = 0.78        ## a lo que pasean los demás
const ANIM_ANDAR_M_S: float = 0.67  ## velocidad a la que encaja la animación de andar
const ANIM_CORRER_M_S: float = 3.08 ## por encima, galopa
const LLEGA_M: float = 0.1          ## a esto de su meta ya ha llegado
const HUECO_M: float = 0.78         ## distancia que guardan entre ellos
const APARTARSE_M_S: float = 1.46   ## a lo que se separan cuando están encima uno de otro
const ESPERA_INICIAL_S: Vector2 = Vector2(0.6, 2.4) ## (mín., máx.) antes del primer paseo
const ESPERA_S: Vector2 = Vector2(2.2, 4.8)         ## (mín., máx.) entre paseos
const GANAS_DE_PASEAR: float = 0.68 ## probabilidad de elegir un sitio nuevo en vez de quedarse
const HORA_DORMIR: int = 21
const HORA_DESPERTAR: int = 6
const SUELO_CADA_M: float = 0.2     ## cada cuánto camino vuelve a mirar la altura del suelo

var vm: Node = null
var animal_index: int = 0
var species: String = "sheep"
var stage: String = "chick"
var corral: Rect2 = Rect2() ## su valla, en metros sobre el suelo (x → este, y → sur)
var model_3d: Node = null

var _meta: Vector3 = Vector3.ZERO
var _espera_s: float = 1.0
var _suelo_mirado_en: Vector3 = Vector3.INF
var _talla_paso: int = 0


## Un animal nuevo dentro del escenario 3D del pueblo `p_vm`. Devuelve null si el escenario aún no existe.
static func crear(p_vm: Node) -> Node:
	var raiz: Node = escenario(p_vm.get_tree())
	if raiz == null:
		return null
	var animal: Node = (load(RUTA) as GDScript).new()
	raiz.add_child(animal)
	return animal


func _ready() -> void:
	_crear_forma()
	_vestir(self, false)


func configure_from_entry(p_vm: Node, p_index: int, d: Dictionary, p_corral: Rect2) -> void:
	var nuevo: bool = vm == null
	vm = p_vm
	corral = p_corral
	if nuevo:
		_entrar_al_corral(p_index)
	else:
		global_position = _dentro(global_position)
		_meta = _dentro(_meta)
	update_from_dict(p_index, d)


## Primera vez: se apunta a sus grupos y elige un sitio del corral según su número (siempre el mismo).
func _entrar_al_corral(p_index: int) -> void:
	add_to_group("livestock_animal")
	add_to_group("livestock_animals")
	add_to_group("ranch_livestock")
	var fx: float = fposmod(0.22 + float(p_index) * 0.27, 0.84) + 0.08
	var fy: float = fposmod(0.25 + float(p_index) * 0.37, 0.80) + 0.10
	global_position = Vector3(lerpf(corral.position.x, corral.end.x, fx), 0.0, lerpf(corral.position.y, corral.end.y, fy))
	_posar()
	_meta = global_position
	_espera_s = randf_range(ESPERA_INICIAL_S.x, ESPERA_INICIAL_S.y)


func update_from_dict(p_index: int, d: Dictionary) -> void:
	animal_index = p_index
	species = str(d.get("species", "sheep"))
	stage = str(d.get("stage", "chick"))
	var etapa: int = maxi(0, ETAPAS.find(stage))
	var modelo: String = MODELO_GALLINA
	var alto_m: float = ALTOS_GALLINA[etapa]
	if MODELOS.has(species):
		modelo = str((MODELOS[species] as Array)[0])
		alto_m = float(((MODELOS[species] as Array)[1] as Array)[etapa])
	if is_instance_valid(model_3d):
		model_3d.call("cambiar_modelo", modelo, alto_m)
		return
	model_3d = AnimalModel3DScript.poner(self, modelo, alto_m)
	if model_3d != null:
		model_3d.call("pasos", ANIM_ANDAR_M_S, ANIM_CORRER_M_S)


func _physics_process(delta: float) -> void:
	if corral.size.x <= LLEGA_M or corral.size.y <= LLEGA_M:
		return
	var paso: int = Engine.get_physics_frames()
	if paso - _talla_paso >= TALLA_CADA: # una cría crece y pasa a estorbar
		_talla_paso = paso
		_vestir(self, false)
	if _es_de_noche():
		return
	_espera_s -= delta
	if _espera_s <= 0.0:
		_espera_s = randf_range(ESPERA_S.x, ESPERA_S.y)
		_meta = _sitio_al_azar() if randf() < GANAS_DE_PASEAR else global_position
	var falta: Vector3 = _meta - global_position
	falta.y = 0.0
	var paseo: Vector3 = Vector3.ZERO
	if falta.length() > LLEGA_M:
		paseo = falta.normalized() * (PASO_OVEJA_M_S if species == "sheep" else PASO_M_S) * delta
	var mov: Vector3 = paseo + _separarse(delta)
	if mov.length_squared() > 0.0:
		_ir(global_position + mov)


## Alguien que anda contra él lo aparta un poco (lo llama el cuerpo del protagonista). No sale de su valla.
func apartar(desplazamiento: Vector3) -> void:
	_ir(global_position + desplazamiento)


func _es_de_noche() -> bool:
	if WorldClock == null:
		return false
	var h: int = int(WorldClock.current_hour)
	return h >= HORA_DORMIR or h < HORA_DESPERTAR


func _sitio_al_azar() -> Vector3:
	return Vector3(randf_range(corral.position.x, corral.end.x), 0.0, randf_range(corral.position.y, corral.end.y))


## El punto `p` metido dentro de la valla.
func _dentro(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, corral.position.x, corral.end.x), p.y, clampf(p.z, corral.position.y, corral.end.y))


## Se pone en `p` (sin salir de la valla) y, si ha andado lo bastante, vuelve a mirar la altura del suelo.
func _ir(p: Vector3) -> void:
	var q: Vector3 = _dentro(p)
	global_position = Vector3(q.x, global_position.y, q.z)
	if _suelo_mirado_en == Vector3.INF or global_position.distance_squared_to(_suelo_mirado_en) > SUELO_CADA_M * SUELO_CADA_M:
		_posar()


## Los pies, a la altura del suelo del corral (al aire libre: piso 0).
func _posar() -> void:
	global_position.y = suelo_y(global_position.x, global_position.z, 0, vm)
	_suelo_mirado_en = global_position


## Paso para no quedarse encima de otro animal del corral.
func _separarse(delta: float) -> Vector3:
	var empuje: Vector3 = Vector3.ZERO
	for otro: Node in get_tree().get_nodes_in_group("livestock_animal"):
		if otro == self or not (otro is Node3D):
			continue
		var de_el: Vector3 = global_position - (otro as Node3D).global_position
		de_el.y = 0.0
		var d: float = de_el.length()
		if d >= HUECO_M:
			continue
		var dir: Vector3 = de_el / d if d > 0.001 else Vector3(cos(float(animal_index)), 0.0, sin(float(animal_index)))
		empuje += dir * ((HUECO_M - d) / HUECO_M) * APARTARSE_M_S * delta
	return empuje
