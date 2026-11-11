extends CharacterBody3D

## Cuerpo3D: el cuerpo físico de verdad de un personaje en el mundo 3D (por ahora, el protagonista).
## Paso del mundo a 3D, paso 1 (docs/PLAN_MUNDO_3D.md), 2026-11-10. Idea: «cuerpo en 3D, cerebro en el mapa».
## - Quien lo usa le da una velocidad en el mapa (píxeles/s, como siempre) con mover(); el cuerpo anda en 3D, choca con
##   las copias sólidas de las paredes (ChoquesCercanos3D), cae con gravedad y salta; después escribe su sitio en el mapa
##   (global_position del personaje 2D), así el resto del juego sigue igual.
## - Si alguien mueve al personaje a mano en el mapa (camas, escaleras, cárcel, cargar partida…), el cuerpo salta ahí.
## - El suelo es una losa invisible que va bajo los pies a la altura que dice Suelo.gd.
## - Paso 2: donde hay varios suelos uno encima de otro (la posada), pisa el que tiene debajo según su altura (sube la
##   escalera andando) y avisa al pueblo de en qué piso está (`player_elevation_level`, que sigue usando el resto del juego).
##   Los sótanos, alcantarillas y pisos de las casas siguen siendo «capas» a las que se llega con [E].

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Suelo = preload("res://scripts/fisica/Suelo.gd")
const ChoquesCercanos3D = preload("res://scripts/fisica/ChoquesCercanos3D.gd")
const WorldStageBase3D = preload("res://scripts/visuals/WorldStageBase3D.gd")

const RADIO_M: float = 0.28        ## lo que ocupa el protagonista visto desde arriba (5 px del mapa)
const ALTO_M: float = 1.74
const GRAVEDAD: float = 14.8       ## m/s²; con el impulso del salto da ~1,2 m al aire libre, como antes
const LOSA_M: Vector3 = Vector3(3.0, 0.5, 3.0)
const PELDANO_M: float = 0.45      ## lo más alto que sube andando de un suelo a otro (escalones, rampa)

var actor: CharacterBody2D = null
var _mascara_2d: int = 0
var _choques: Node3D = null
var _losa: StaticBody3D = null
var _suelo_y: float = 0.0
var _calle_y: float = 0.0          ## suelo de abajo (calle o Planta 0): desde ahí se levantan los muros
var _ultima_pos_mapa: Vector2 = Vector2.INF
var _movido_en_este_paso: bool = false


## Crea el cuerpo de `p_actor` dentro de `padre` (el escenario 3D; sin él, cualquier nodo del árbol).
static func crear(p_actor: CharacterBody2D, padre: Node) -> CharacterBody3D:
	var c: CharacterBody3D = load("res://scripts/fisica/Cuerpo3D.gd").new()
	c.actor = p_actor
	c.name = "Cuerpo3D_" + str(p_actor.name)
	padre.add_child(c)
	return c


func _ready() -> void:
	var forma := CapsuleShape3D.new()
	forma.radius = RADIO_M
	forma.height = ALTO_M
	var cs := CollisionShape3D.new()
	cs.shape = forma
	cs.position.y = ALTO_M * 0.5
	add_child(cs)
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(50.0)
	safe_margin = 0.01
	process_physics_priority = 100 # después de quien lo mueve: así sabe si ese paso ya se movió
	# El protagonista deja de chocar en el mapa: ahora choca su cuerpo 3D (los demás siguen chocando con él en el mapa)
	_mascara_2d = actor.collision_mask
	actor.collision_mask = 0
	_choques = ChoquesCercanos3D.new()
	get_parent().add_child.call_deferred(_choques)
	_losa = StaticBody3D.new()
	_losa.name = "LosaSuelo3D"
	var cl := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = LOSA_M
	cl.shape = caja
	cl.position.y = -LOSA_M.y * 0.5
	_losa.add_child(cl)
	get_parent().add_child.call_deferred(_losa)
	_saltar_a(actor.global_position)


## Un paso andando a `vel_mapa` (píxeles del mapa por segundo).
func mover(vel_mapa: Vector2, delta: float) -> void:
	_preparar()
	velocity.x = vel_mapa.x * Mapa3D.ESCALA
	velocity.z = vel_mapa.y * Mapa3D.ESCALA
	if not is_on_floor() or velocity.y > 0.0:
		velocity.y -= GRAVEDAD * delta
	move_and_slide()
	if global_position.y < _suelo_y - 2.0: # nunca por debajo del suelo (por si la losa llega tarde)
		_saltar_a(actor.global_position)
	_volcar_al_mapa()
	_movido_en_este_paso = true


## Salta con `impulso` (m/s hacia arriba) si está en el suelo. Devuelve si saltó.
func saltar(impulso: float) -> bool:
	if not is_on_floor() and global_position.y > _suelo_y + 0.05:
		return false
	velocity.y = impulso
	return true


func esta_en_el_aire() -> bool:
	return velocity.y > 0.01 or global_position.y > _suelo_y + 0.03


## Cuánto se ha levantado del suelo, en píxeles de altura (lo usan la cámara y el muñeco).
func altura_sobre_suelo_px() -> float:
	return maxf(0.0, Mapa3D.alto_a_px(global_position.y - _suelo_y))


## A qué altura tiene los pies sobre el relieve, en píxeles de altura (suelo que pisa + salto). Lo usan la cámara en
## 1.ª persona y el muñeco del protagonista.
func altura_pies_px() -> float:
	return Mapa3D.alto_a_px(global_position.y) - WorldStageBase3D.terrain_height_px(Mapa3D.a_mapa(global_position))


## Lo deja en el suelo, quieto en vertical.
func aterrizar() -> void:
	velocity.y = 0.0
	global_position.y = _suelo_y


func choques_copiados() -> int:
	return _choques.cuantas() if is_instance_valid(_choques) else 0


func _physics_process(delta: float) -> void:
	if not _movido_en_este_paso and is_instance_valid(actor):
		mover(Vector2.ZERO, delta) # quieto (diálogo, aturdido…): sigue cayendo y siguiendo los cambios de sitio
	_movido_en_este_paso = false


## Antes de moverse: ¿lo han cambiado de sitio a mano? Suelo y paredes de alrededor al día.
func _preparar() -> void:
	if actor.global_position.distance_squared_to(_ultima_pos_mapa) > 0.0001:
		_saltar_a(actor.global_position)
	var p := actor.global_position
	_suelo_y = _altura_suelo(p, false)
	if is_instance_valid(_losa) and _losa.is_inside_tree():
		var b := Mapa3D.a_3d(p)
		_losa.global_position = Vector3(b.x, _suelo_y, b.z)
	if is_instance_valid(_choques) and _choques.is_inside_tree():
		var excluir: Array[RID] = [actor.get_rid()]
		# Bajo tierra (capa −1, a la misma altura por ahora) no cuentan los choques de los pisos de encima
		var mascara: int = _mascara_2d if _nivel() == -1 else _mascara_2d | Suelo.CAPA_PISOS
		_choques.actualizar(actor.get_world_2d().direct_space_state, p, mascara, excluir, _calle_y)


func _vm() -> Node:
	return actor.get_tree().get_first_node_in_group("village_manager")


func _nivel() -> int:
	var vm := _vm()
	return int(vm.get("player_elevation_level")) if vm != null else 0


## Altura 3D del suelo que pisa en `p`. Donde hay varios suelos: al llegar de golpe (`de_golpe`), el de su piso; andando,
## el que tiene debajo según su altura, y si cambia de piso se lo dice al pueblo.
func _altura_suelo(p: Vector2, de_golpe: bool) -> float:
	var vm := _vm()
	var nivel := _nivel()
	var relieve: float = WorldStageBase3D.terrain_height_px(p)
	var pisos: Array[float] = Suelo.pisos_en(p) if nivel != -1 else ([] as Array[float])
	if pisos.is_empty():
		_calle_y = Mapa3D.a_3d(p, relieve + Suelo.altura_px(p, 0, vm)).y
		return Mapa3D.a_3d(p, relieve + Suelo.altura_px(p, nivel, vm)).y
	_calle_y = Mapa3D.a_3d(p, relieve + pisos[0]).y
	var h: float
	if de_golpe:
		h = pisos.back() if nivel == 1 else pisos[0]
	else:
		h = Suelo.elegir(pisos, Mapa3D.alto_a_px(global_position.y) - relieve, Mapa3D.alto_a_px(PELDANO_M))
		var n: int = Suelo.nivel_de(h)
		if n != nivel and vm != null and vm.has_method("set_player_elevation_level"):
			vm.call("set_player_elevation_level", n)
	return Mapa3D.a_3d(p, relieve + h).y


func _saltar_a(p: Vector2) -> void:
	_suelo_y = _altura_suelo(p, true)
	var b := Mapa3D.a_3d(p)
	global_position = Vector3(b.x, _suelo_y, b.z)
	velocity = Vector3.ZERO
	_ultima_pos_mapa = p


func _volcar_al_mapa() -> void:
	var p := Mapa3D.a_mapa(global_position)
	actor.global_position = p
	actor.velocity = Vector2(velocity.x, velocity.z) / Mapa3D.ESCALA
	_ultima_pos_mapa = p
