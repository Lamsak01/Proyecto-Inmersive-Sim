extends CharacterBody3D

## CuerpoBase3D: lo común a todo cuerpo 3D de personaje (paso a 3D, tanda 4b, 2026-11-14): su cápsula, su tamaño, con
## quién choca y a qué altura está el suelo que pisa. Lo heredan Cuerpo3D (el cuerpo de un personaje que aún vive en el
## mapa plano) y los personajes que ya SON su cuerpo y viven en metros (el ganado; después animales, bandidos y vecinos).
## TRADUCTOR (se quita con los suelos y paredes 3D de verdad, tandas 3b y 3a-v): la altura del suelo y las paredes de
## alrededor aún se preguntan al mapa plano (suelo_y, _pedir_paredes).
## Sin preloads de los sistemas del juego (el suelo, el relieve y las paredes se cargan al usarlos): así puede heredar de
## aquí cualquier personaje sin crear ciclos de carga.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Capas3D = preload("res://scripts/fisica/Capas3D.gd")
const TallaCuerpo3D = preload("res://scripts/fisica/TallaCuerpo3D.gd")

const RUTA_SUELO: String = "res://scripts/fisica/Suelo.gd"
const RUTA_RELIEVE: String = "res://scripts/visuals/WorldStageBase3D.gd"
const RUTA_PAREDES: String = "res://scripts/fisica/ChoquesMundo3D.gd"
const GRUPO_CUERPOS: String = "cuerpos_3d"
const CAPA_PROTA: int = Capas3D.PROTA
const CAPA_VECINO: int = Capas3D.VECINO
const CAPA_PEQUENO: int = Capas3D.PEQUENO
const TALLA_CADA: int = 10         ## (no protagonista) pasos entre repasos de su tamaño y de si está apagado
const GRAVEDAD: float = 14.8       ## m/s²; con el impulso del salto da ~1,2 m al aire libre
const EN_SUELO_M: float = 0.03     ## a esto del suelo ya lo pisa

static var _guion_suelo: GDScript = null
static var _guion_relieve: GDScript = null

var toca_pared: bool = false       ## chocó con algo en su último paso
var _forma: CollisionShape3D = null
var _mascara: int = 0              ## con qué choca normalmente
var _suelo_y: float = 0.0          ## altura del suelo que pisa
var _mundo: Node3D = null          ## las paredes 3D del mundo (ChoquesMundo3D), compartidas por todos los cuerpos
var _diana: Diana3D = null         ## dónde se le puede herir (solo quien sabe recibir daño)


## Dónde viven los cuerpos: la raíz del escenario 3D (todos en el mismo mundo, con las mismas paredes). Devuelve null
## si el escenario aún no existe.
static func escenario(arbol: SceneTree) -> Node:
	var vm: Node = arbol.get_first_node_in_group("village_manager")
	if vm == null:
		return null
	var stage: Variant = vm.get("world_stage_3d")
	var raiz: Variant = (stage as Object).get("stage_root_3d") if is_instance_valid(stage) else null
	if not is_instance_valid(raiz) or not (raiz as Node).is_inside_tree():
		return null
	return raiz as Node


## Altura (m) del suelo que se pisa en el punto (x, z) del mundo para alguien del piso `nivel`.
static func suelo_y(x: float, z: float, nivel: int, vm: Node) -> float:
	if _guion_suelo == null:
		_guion_suelo = load(RUTA_SUELO) as GDScript
		_guion_relieve = load(RUTA_RELIEVE) as GDScript
	var p: Vector2 = Mapa3D.a_mapa(Vector3(x, 0.0, z))
	return Mapa3D.alto_a_3d(float(_guion_relieve.call("terrain_height_px", p)) + float(_guion_suelo.call("altura_px", p, nivel, vm)))


## Crea la cápsula del cuerpo y lo apunta al grupo de los cuerpos (lo llaman los hijos al entrar en el juego).
func _crear_forma() -> void:
	add_to_group(GRUPO_CUERPOS)
	_forma = CollisionShape3D.new()
	_forma.shape = CapsuleShape3D.new()
	add_child(_forma)
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING # el suelo lo pone él mismo; los choques solo son muros y cuerpos
	safe_margin = 0.01
	_mundo = (load(RUTA_PAREDES) as GDScript).call("de", get_parent()) as Node3D


func _en_suelo() -> bool:
	return global_position.y <= _suelo_y + EN_SUELO_M


## Un paso andando a `vel` (m/s sobre el suelo: x → este, y → sur): cae si está en el aire y choca con paredes y cuerpos.
func _paso_fisico(vel: Vector2, delta: float) -> void:
	velocity.x = vel.x
	velocity.z = vel.y
	if not _en_suelo() or velocity.y > 0.0:
		velocity.y -= GRAVEDAD * delta
	move_and_slide()
	toca_pared = get_slide_collision_count() > 0


## Nunca por debajo del suelo que pisa (así sube andando los escalones bajos).
func _pisar() -> void:
	if global_position.y < _suelo_y:
		global_position.y = _suelo_y
		velocity.y = maxf(velocity.y, 0.0)


## Avisa al mundo de que necesita levantadas las paredes a `radio_m` a la redonda (TRADUCTOR, ver cabecera).
func _pedir_paredes(vm: Node, radio_m: float, repaso: int) -> void:
	if is_instance_valid(_mundo) and vm is Node2D:
		_mundo.call("interes", (vm as Node2D).get_world_2d().direct_space_state, Mapa3D.a_mapa(global_position), radio_m / Mapa3D.ESCALA, repaso)


## Si `quien` sabe recibir daño, le pone su diana: ahí le buscan la espada y las flechas (tanda 7a).
func _poner_diana(quien: Node) -> void:
	if _diana == null and quien.has_method("take_damage"):
		_diana = Diana3D.poner(self, quien)


## Tamaño, capa y con qué choca, según quién es (`quien`) y cómo está ahora (TallaCuerpo3D). Se repasa cada TALLA_CADA
## pasos: una cría crece, alguien se duerme o se sienta. `fijar_mascara` a false mientras se cuela por un atasco.
func _vestir(quien: Node, es_prota: bool, fijar_mascara: bool = true) -> void:
	var talla: Vector2 = TallaCuerpo3D.de(quien)
	var capsula := _forma.shape as CapsuleShape3D
	if capsula.radius != talla.x or capsula.height != talla.y:
		capsula.radius = talla.x
		capsula.height = talla.y
		_forma.position.y = talla.y * 0.5
	if _diana != null:
		_diana.medir(talla.x, talla.y)
	# Paredes: las del mundo, compartidas. El agua tiene su capa: frena a los demás; el protagonista entra y nada.
	var muros: int = Capas3D.MUROS
	var capa: int = CAPA_PROTA
	_mascara = CAPA_PROTA | CAPA_VECINO | muros
	if not es_prota:
		var grande: bool = talla != TallaCuerpo3D.PEQUENO
		capa = CAPA_VECINO if grande else CAPA_PEQUENO
		_mascara = muros | Capas3D.AGUA | (CAPA_PROTA if grande else 0)
		var apagado: bool = TallaCuerpo3D.apagado(quien)
		if _forma.disabled != apagado:
			_forma.disabled = apagado
	if collision_layer != capa:
		collision_layer = capa
	if fijar_mascara and collision_mask != _mascara:
		collision_mask = _mascara
