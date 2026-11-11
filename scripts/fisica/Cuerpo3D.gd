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
##   Al club de peleas y a las alcantarillas (de verdad bajo tierra desde el paso 2b) y a los pisos de tu casa se sigue
##   llegando con [E].
## - Paso 3: en el río y el lago (scripts/fisica/Agua.gd) pisa el fondo si hace pie; si no, flota con la cabeza fuera
##   (nada). Caer al agua honda no hace daño.
## - Paso 4b–4c: los vecinos, bandidos y animales grandes que tiene cerca tienen un cuerpo «de contacto»
##   (CuerposCercanos3D): ya no se les atraviesa.
## - Paso 2c: si cae desde 3 m o más, se hace daño al aterrizar (sobre todo en las piernas); a 8 m, mortal.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Suelo = preload("res://scripts/fisica/Suelo.gd")
const ChoquesCercanos3D = preload("res://scripts/fisica/ChoquesCercanos3D.gd")
const Agua = preload("res://scripts/fisica/Agua.gd")
const CuerposCercanos3D = preload("res://scripts/fisica/CuerposCercanos3D.gd")
const WorldStageBase3D = preload("res://scripts/visuals/WorldStageBase3D.gd")

const RADIO_M: float = 0.28        ## lo que ocupa el protagonista visto desde arriba (5 px del mapa)
const ALTO_M: float = 1.74
const GRAVEDAD: float = 14.8       ## m/s²; con el impulso del salto da ~1,2 m al aire libre, como antes
const LOSA_M: Vector3 = Vector3(3.0, 0.5, 3.0)
const PELDANO_M: float = 0.45      ## lo más alto que sube andando de un suelo a otro (escalones, rampa)
## Daño por caída (paso 2c, decisión del usuario: «realista»): desde 3 m duele (~9 % de la vida) y a 8 m mata.
const CAIDA_DUELE_M: float = 3.0
const CAIDA_MORTAL_M: float = 8.0
const CAIDA_CERO_M: float = 2.5    ## donde empezaría la recta del daño (así a 3 m ya quita algo)
## Agua (paso 3)
const FLOTA_M: float = 1.35        ## nadando, los pies van esto bajo la superficie (la cabeza queda fuera)
const VADEA_M: float = 0.3         ## desde esta hondura ya se anda por el agua (más despacio)
const CAIDA_AGUA_SIN_DANO_M: float = 1.5 ## caer en agua así de honda no hace daño
enum EnAgua { SECO, VADEANDO, NADANDO }

var actor: CharacterBody2D = null
var _mascara_2d: int = 0
var _choques: Node3D = null
var _cercanos: Node3D = null       ## cuerpos de contacto de los vecinos y animales grandes cercanos
var _losa: StaticBody3D = null
var _suelo_y: float = 0.0
var _calle_y: float = 0.0          ## suelo de abajo (calle o Planta 0): desde ahí se levantan los muros
var _ultima_pos_mapa: Vector2 = Vector2.INF
var _movido_en_este_paso: bool = false
var _cima_y: float = NAN           ## lo más alto que ha estado desde que dejó el suelo (NAN: está en el suelo)
var en_agua: int = EnAgua.SECO     ## seco, vadeando o nadando (lo mira el mando del protagonista)


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
	_cercanos = CuerposCercanos3D.new()
	get_parent().add_child.call_deferred(_cercanos)
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
	_vigilar_caida()
	_volcar_al_mapa()
	_movido_en_este_paso = true


## Salta con `impulso` (m/s hacia arriba) si está en el suelo. Devuelve si saltó.
func saltar(impulso: float) -> bool:
	if en_agua == EnAgua.NADANDO:
		return false
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
	_cima_y = NAN
	velocity.y = 0.0
	global_position.y = _suelo_y


## Vida que quita caer `caida_m` metros a quien tiene `vida_max`.
static func dano_por_caida(caida_m: float, vida_max: float) -> float:
	if caida_m < CAIDA_DUELE_M:
		return 0.0
	return vida_max * clampf((caida_m - CAIDA_CERO_M) / (CAIDA_MORTAL_M - CAIDA_CERO_M), 0.0, 1.0)


func choques_copiados() -> int:
	return _choques.cuantas() if is_instance_valid(_choques) else 0


## Los cuerpos de contacto de quien tiene cerca (pasos 4b–4c).
func cercanos() -> Node3D:
	return _cercanos


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
		# Bajo tierra (capa −1) no cuentan los choques de los pisos de la posada de encima
		var mascara: int = _mascara_2d if _nivel() == -1 else _mascara_2d | Suelo.CAPA_PISOS
		_choques.actualizar(actor.get_world_2d().direct_space_state, p, mascara, excluir, _calle_y)
	if is_instance_valid(_cercanos) and _cercanos.is_inside_tree():
		_cercanos.actualizar(p, _vm())


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
	en_agua = EnAgua.SECO
	if pisos.is_empty() and nivel == 0 and Agua.en_agua(p):
		_calle_y = Mapa3D.a_3d(p, relieve).y
		return _suelo_en_agua(p)
	if pisos.is_empty():
		var suelo_y: float = Mapa3D.a_3d(p, relieve + Suelo.altura_px(p, nivel, vm)).y
		# Bajo tierra (club, alcantarillas) los muros se levantan desde su propio suelo
		_calle_y = suelo_y if nivel == -1 else Mapa3D.a_3d(p, relieve + Suelo.altura_px(p, 0, vm)).y
		return suelo_y
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


## En el aire apunta lo más alto que llega; al tocar suelo, si cayó desde muy alto, se hace daño.
func _vigilar_caida() -> void:
	if not is_on_floor():
		_cima_y = global_position.y if is_nan(_cima_y) else maxf(_cima_y, global_position.y)
		return
	if is_nan(_cima_y):
		return
	var caida_m: float = _cima_y - global_position.y
	_cima_y = NAN
	if Agua.hondura_m(actor.global_position) >= CAIDA_AGUA_SIN_DANO_M:
		return # el agua honda frena la caída
	var hc = actor.get("health_comp")
	var dano: float = dano_por_caida(caida_m, float(hc.max_health) if hc != null else 100.0)
	if dano > 0.0 and actor.has_method("recibir_dano_caida"):
		actor.call("recibir_dano_caida", dano, caida_m)


## En el agua: el fondo si hace pie; si no, flotando con la cabeza fuera.
func _suelo_en_agua(p: Vector2) -> float:
	var sup: float = Agua.superficie_y(p)
	var hondura: float = Agua.hondura_m(p)
	var flota: float = sup - FLOTA_M
	var fondo: float = sup - hondura
	if fondo < flota:
		en_agua = EnAgua.NADANDO
		return flota
	en_agua = EnAgua.VADEANDO if hondura >= VADEA_M else EnAgua.SECO
	return fondo


func _saltar_a(p: Vector2) -> void:
	_suelo_y = _altura_suelo(p, true)
	var b := Mapa3D.a_3d(p)
	global_position = Vector3(b.x, _suelo_y, b.z)
	velocity = Vector3.ZERO
	_cima_y = NAN # cambiar de sitio a mano (escalera con [E], cama…) no es caerse
	_ultima_pos_mapa = p


func _volcar_al_mapa() -> void:
	var p := Mapa3D.a_mapa(global_position)
	actor.global_position = p
	actor.velocity = Vector2(velocity.x, velocity.z) / Mapa3D.ESCALA
	_ultima_pos_mapa = p
