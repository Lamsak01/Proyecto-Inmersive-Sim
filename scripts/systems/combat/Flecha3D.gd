class_name Flecha3D
extends Node3D

## Flecha3D: una flecha (o una bala) que vuela de verdad por el mundo 3D (paso a 3D, tanda 7a-2, 2026-11-14).
## Sustituye a ArrowProjectile, que era un nodo del mapa plano con una altura apuntada aparte.
## - La flecha sale con la fuerza de la tensión del arco y cae por su peso: describe un arco y se clava donde aterriza
##   (suelo, pared u objeto). Su caída está medida para que un tiro recto llegue justo a su alcance; apuntando algo
##   hacia arriba llega más lejos. La bala va recta y desaparece al acabar su alcance.
## - En cada paso hiere a la diana 3D que cruza (Diana3D): da justo donde se apunta, a la altura de verdad.
## TRADUCTOR (se quita con las paredes y suelos 3D de verdad, tandas 3a-v y 3b): para tener paredes delante avisa a
## ChoquesMundo3D con su sitio en el mapa plano, y las losas de los pisos altos se preguntan a Vista.gd.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Vista = preload("res://scripts/fisica/Vista.gd")
const CuerpoBase3D = preload("res://scripts/fisica/CuerpoBase3D.gd")
const ChoquesMundo3D = preload("res://scripts/fisica/ChoquesMundo3D.gd")
const CombatFeel = preload("res://scripts/systems/combat/CombatFeel.gd")
const FlechaFigura3D = preload("res://scripts/systems/combat/FlechaFigura3D.gd")

const FRENO_FINAL: float = 0.65     ## la flecha acaba su vuelo a esta parte de su velocidad de salida
const PAREDES_RADIO_M: float = 3.6  ## pide las paredes del mundo a esta distancia a la redonda
const CLAVADA_S: float = 1.5        ## tiempo que se queda clavada antes de desvanecerse
const DESVANECE_S: float = 0.4
const VUELO_MAX_S: float = 6.0      ## por si se dispara al cielo: no vuela para siempre
const EMPUJE_BALA: Dictionary = {"stagger": 0.42, "hitstop": 0.04, "shake": 4.0, "pitch": 0.65}
const EMPUJE_FUSIL_PX: float = 18.0 ## lo que desplaza un balazo de fusil (unidades del mapa: CombatFeel aún es plano)
const EMPUJE_PISTOLA_PX: float = 12.0

var tirador: Node = null
var dano: DamageData = null
var es_bala: bool = false
var clavada: bool = false           ## ha acabado su vuelo (lo miran las pruebas)
var _velocidad: Vector3 = Vector3.ZERO
var _rapidez_salida: float = 0.0
var _caida: float = 0.0             ## m/s² hacia abajo (0 para la bala)
var _alcance: float = 0.0
var _recorrido: float = 0.0
var _vuelo_s: float = 0.0
var _nivel: int = 0                 ## piso de quien dispara (para saber qué suelo hay debajo)
var _vm: Node = null


## Dispara desde `origen` hacia `direccion` (mundo 3D). `alcance` es lo que recorre un tiro recto antes de caer (flecha)
## o de perderse (bala). Devuelve null si aún no hay escenario 3D.
static func disparar(p_tirador: Node, origen: Vector3, direccion: Vector3, rapidez: float, alcance: float, p_dano: DamageData) -> Flecha3D:
	var raiz: Node = CuerpoBase3D.escenario(p_tirador.get_tree())
	if raiz == null:
		return null
	var f := Flecha3D.new()
	f.tirador = p_tirador
	f.dano = p_dano
	f.es_bala = p_dano.is_firearm_bullet
	f._alcance = alcance
	f._rapidez_salida = rapidez
	f._velocidad = direccion.normalized() * rapidez
	f._vm = p_tirador.get_tree().get_first_node_in_group("village_manager")
	f._nivel = f._piso_del_tirador()
	raiz.add_child(f)
	f.global_position = origen
	p_dano.is_ranged_projectile = true
	if not f.es_bala: # cae lo justo para que un tiro recto desde ahí llegue a su alcance
		var alto: float = maxf(0.2, origen.y - f._suelo_en(origen))
		f._caida = 2.0 * alto * rapidez * rapidez / (alcance * alcance)
	f.add_child(FlechaFigura3D.crear(f.es_bala))
	if absf(direccion.normalized().dot(Vector3.UP)) < 0.999:
		f.look_at(origen + direccion, Vector3.UP)
	return f


func _physics_process(delta: float) -> void:
	if clavada:
		return
	_vuelo_s += delta
	var a: Vector3 = global_position
	var avance: float = clampf(_recorrido / maxf(0.01, _alcance), 0.0, 1.0)
	# La flecha pierde algo de velocidad al final; la bala la mantiene
	var freno: float = 1.0 if es_bala else lerpf(1.0, FRENO_FINAL, avance * avance)
	_velocidad.y -= _caida * delta
	var b: Vector3 = a + _velocidad * freno * delta
	_pedir_paredes(b)
	if _herir(a, b):
		return
	var tope: Dictionary = _pared_en(a, b)
	if not tope.is_empty():
		_golpear_objeto(tope["collider"] as Node)
		_acabar(tope["position"] as Vector3)
		return
	if b.y <= _suelo_en(b) or _tapa_una_losa(a, b):
		_acabar(Vector3(b.x, maxf(b.y, _suelo_en(b)), b.z))
		return
	global_position = b
	_recorrido += a.distance_to(b)
	if _velocidad.length_squared() > 0.0001:
		look_at(b + _velocidad, Vector3.UP)
	if (es_bala and _recorrido >= _alcance) or _vuelo_s > VUELO_MAX_S:
		queue_free()


## ¿Cruza la diana de alguien en este paso? Entonces le hiere y la flecha se acaba.
func _herir(a: Vector3, b: Vector3) -> bool:
	var diana: Diana3D = Diana3D.en_tramo(get_world_3d(), a, b, tirador)
	if diana == null:
		return false
	dano.shot_distance_px = (_recorrido + a.distance_to(b)) / Mapa3D.ESCALA # HealthComponent aún mide en el mapa plano
	var herido: Node = diana.duenio
	diana.recibir(dano)
	if es_bala and (herido is Node2D or herido is Node3D):
		_sacudir(herido)
	queue_free()
	return true


## El balazo empuja y aturde a quien alcanza (CombatFeel aún trabaja en el mapa plano).
func _sacudir(herido: Node) -> void:
	var hacia := Vector2(_velocidad.x, _velocidad.z).normalized()
	var fuerza: Dictionary = EMPUJE_BALA.duplicate()
	fuerza["knockback"] = EMPUJE_FUSIL_PX if dano.firearm_kind == "rifle" else EMPUJE_PISTOLA_PX
	CombatFeel.apply_hit_reaction(herido, hacia, fuerza)
	if is_instance_valid(tirador) and tirador is Node2D and tirador.is_in_group("player"):
		load("res://scripts/visuals/WorldStage3D.gd").call("notify_fp_melee_hit", tirador, herido as Node2D, hacia, fuerza, 1.35)


## La pared (o el objeto) del mundo que corta el tramo; vacío si no hay ninguna.
func _pared_en(a: Vector3, b: Vector3) -> Dictionary:
	var rayo := PhysicsRayQueryParameters3D.create(a, b, ChoquesMundo3D.CAPA_MUROS)
	return get_world_3d().direct_space_state.intersect_ray(rayo)


## Si lo que ha parado la flecha es un objeto rompible (caja, barril…), recibe el daño.
func _golpear_objeto(pared: Node) -> void:
	var origen: Variant = pared.get_meta(ChoquesMundo3D.META_ORIGEN) if pared != null and pared.has_meta(ChoquesMundo3D.META_ORIGEN) else null
	if is_instance_valid(origen) and (origen as Node).is_in_group("destructible") and (origen as Node).has_method("take_damage"):
		dano.shot_distance_px = _recorrido / Mapa3D.ESCALA
		(origen as Node).call("take_damage", dano)


## Avisa al mundo de que necesita levantadas las paredes de alrededor de `p` (ver TRADUCTOR en la cabecera).
func _pedir_paredes(p: Vector3) -> void:
	if not (_vm is Node2D):
		return
	var mundo: ChoquesMundo3D = ChoquesMundo3D.de(get_parent()) as ChoquesMundo3D
	mundo.interes((_vm as Node2D).get_world_2d().direct_space_state, Mapa3D.a_mapa(p), PAREDES_RADIO_M / Mapa3D.ESCALA, ChoquesMundo3D.REPASO_TRANQUILO)


func _suelo_en(p: Vector3) -> float:
	return CuerpoBase3D.suelo_y(p.x, p.z, _nivel, _vm)


## ¿Atraviesa en este paso el suelo de un piso alto (la galería de la posada, la planta alta de una casa)?
func _tapa_una_losa(a: Vector3, b: Vector3) -> bool:
	return Vista.tapa_un_suelo(Mapa3D.a_mapa(a), Mapa3D.alto_a_px(a.y), Mapa3D.a_mapa(b), Mapa3D.alto_a_px(b.y))


func _piso_del_tirador() -> int:
	if tirador.is_in_group("player") and _vm != null:
		return int(_vm.get("player_elevation_level"))
	return int(tirador.get("elevation_level")) if "elevation_level" in tirador else 0


## Fin del vuelo en `donde`: la bala desaparece; la flecha se queda clavada un rato y se desvanece.
func _acabar(donde: Vector3) -> void:
	clavada = true
	global_position = donde
	if es_bala:
		queue_free()
		return
	var fin := create_tween()
	fin.tween_interval(CLAVADA_S)
	fin.tween_property(self, "scale", Vector3.ONE * 0.01, DESVANECE_S)
	fin.tween_callback(queue_free)
