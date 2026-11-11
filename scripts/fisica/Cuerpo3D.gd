extends CharacterBody3D

## Cuerpo3D: el cuerpo físico de verdad de un personaje en el mundo 3D: el protagonista y, desde la opción B (paso 4,
## noche del 2026-11-11), los vecinos cercanos a él (CuerposDelPueblo3D decide quién lo tiene en cada momento).
## Paso del mundo a 3D, paso 1 (docs/PLAN_MUNDO_3D.md), 2026-11-10. Idea: «cuerpo en 3D, cerebro en el mapa».
## - Quien lo usa le da una velocidad en el mapa (píxeles/s, como siempre) con mover(); el cuerpo anda en 3D, choca con
##   las copias sólidas de las paredes (ChoquesCercanos3D), cae con gravedad y salta; después escribe su sitio en el mapa
##   (global_position del personaje 2D), así el resto del juego sigue igual.
## - Si alguien mueve al personaje a mano en el mapa (camas, escaleras, cárcel, cargar partida…), el cuerpo salta ahí.
## - El suelo no es una pieza: el cuerpo sabe a qué altura está (Suelo.gd) y no baja de ahí (antes era una losa
##   invisible bajo los pies, pero las losas de los vecinos frenaban al protagonista cuando estaban a otra altura).
## - Paso 2: donde hay varios suelos uno encima de otro (la posada), pisa el que tiene debajo según su altura (sube la
##   escalera andando) y avisa al pueblo de en qué piso está (`player_elevation_level`, que sigue usando el resto del juego).
##   Al club de peleas y a las alcantarillas (de verdad bajo tierra desde el paso 2b) y a los pisos de tu casa se sigue
##   llegando con [E].
## - Paso 3: en el río y el lago (scripts/fisica/Agua.gd) pisa el fondo si hace pie; si no, flota con la cabeza fuera
##   (nada). Caer al agua honda no hace daño. Paso 3b: buceando (`buceando`, lo pone el mando) baja hasta el fondo.
## - Paso 4b–4c: los vecinos, bandidos y animales grandes que tiene cerca tienen un cuerpo «de contacto»
##   (CuerposCercanos3D): ya no se les atraviesa; andando contra ellos se les aparta poco a poco.
## - Paso 2c: si cae desde 3 m o más, se hace daño al aterrizar (sobre todo en las piernas); a 8 m, mortal.
## - Opción B: un vecino con cuerpo anda con él (VillageNPCSocial._finish_frame_movement): choca con paredes, muebles,
##   puertas cerradas y el agua (no nada), sube escaleras y cambia de piso solo; ya no hace falta recolocarlo a mano.
##   Dormido, sentado o caído, su cuerpo se apaga (se le pasa por encima). Los cuerpos de los vecinos no chocan entre sí
##   (su propia separación los aparta) pero sí con el protagonista, que puede apartarlos andando contra ellos.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Suelo = preload("res://scripts/fisica/Suelo.gd")
const ChoquesCercanos3D = preload("res://scripts/fisica/ChoquesCercanos3D.gd")
const Agua = preload("res://scripts/fisica/Agua.gd")
const CuerposCercanos3D = preload("res://scripts/fisica/CuerposCercanos3D.gd")
const CuerposDelPueblo3D = preload("res://scripts/fisica/CuerposDelPueblo3D.gd")
const WorldStageBase3D = preload("res://scripts/visuals/WorldStageBase3D.gd")

const RADIO_M: float = 0.28        ## lo que ocupa el protagonista visto desde arriba (5 px del mapa)
const ALTO_M: float = 1.74
const GRAVEDAD: float = 14.8       ## m/s²; con el impulso del salto da ~1,2 m al aire libre, como antes
const PELDANO_M: float = 0.45      ## lo más alto que sube andando de un suelo a otro (escalones, rampa)
## Daño por caída (paso 2c, decisión del usuario: «realista»): desde 3 m duele (~9 % de la vida) y a 8 m mata.
const CAIDA_DUELE_M: float = 3.0
const CAIDA_MORTAL_M: float = 8.0
const CAIDA_CERO_M: float = 2.5    ## donde empezaría la recta del daño (así a 3 m ya quita algo)
## Agua (paso 3)
const FLOTA_M: float = 1.35        ## nadando, los pies van esto bajo la superficie (la cabeza queda fuera)
const VADEA_M: float = 0.3         ## desde esta hondura ya se anda por el agua (más despacio)
const CAIDA_AGUA_SIN_DANO_M: float = 1.5 ## caer en agua así de honda no hace daño
const APARTA_PX_S: float = 40.0    ## a lo que aparta a quien tiene delante al andar contra él (píxeles del mapa por segundo)
const CAPA_PROTA: int = 1          ## capa 3D del cuerpo del protagonista
const CAPA_VECINO: int = 2         ## capa 3D de los cuerpos de los vecinos (no chocan entre sí; sí con el protagonista)
const MASCARA_MUROS_2D: int = 1    ## con qué choca en el mapa un vecino (paredes, muebles, puertas, agua)
const RADIO_CHOQUES_VECINO_PX: float = 48.0 ## un vecino copia solo las paredes que tiene al lado
const SALTO_MANUAL_PX: float = 8.0  ## un cambio de sitio en el mapa mayor que esto es «a mano» (cama, escalera, cargar…);
                                    ## uno menor (las rutas de los vecinos ajustan unos píxeles) solo desplaza el cuerpo
enum EnAgua { SECO, VADEANDO, NADANDO }

var actor: CharacterBody2D = null
var es_prota: bool = false         ## el protagonista: avisa al pueblo de su piso, nada, aparta a los demás y tiene CuerposCercanos
var destino_actor: Vector2 = Vector2.INF ## (vecinos) adónde va: lo que hay justo ahí (su cama, su silla) no le estorba
var _forma: CollisionShape3D = null
var _pueblo: Node3D = null         ## (solo el protagonista) reparte cuerpos a los vecinos cercanos
var _mascara_2d: int = 0
var _choques: Node3D = null
var _cercanos: Node3D = null       ## cuerpos de contacto de los vecinos y animales grandes cercanos
var _suelo_y: float = 0.0
var _calle_y: float = 0.0          ## suelo de abajo (calle o Planta 0): desde ahí se levantan los muros
var _ultima_pos_mapa: Vector2 = Vector2.INF
var _movido_en_este_paso: bool = false
var _cima_y: float = NAN           ## lo más alto que ha estado desde que dejó el suelo (NAN: está en el suelo)
var _nivel_visto: int = 0          ## el último piso que vio: si cambia desde fuera ([E] en una escalera), va al suelo nuevo sin caer
var en_agua: int = EnAgua.SECO     ## seco, vadeando o nadando (lo mira el mando del protagonista)
var buceando: bool = false         ## nadando, si bucea va por el fondo (paso 3b; lo pone el mando)


## Crea el cuerpo de `p_actor` dentro de `padre` (el escenario 3D; sin él, cualquier nodo del árbol).
static func crear(p_actor: CharacterBody2D, padre: Node) -> CharacterBody3D:
	var c: CharacterBody3D = load("res://scripts/fisica/Cuerpo3D.gd").new()
	c.actor = p_actor
	c.es_prota = p_actor.is_in_group("player")
	c.name = "Cuerpo3D_" + str(p_actor.name)
	padre.add_child(c)
	return c


func _ready() -> void:
	var forma := CapsuleShape3D.new()
	var tam: Vector2 = Vector2(RADIO_M, ALTO_M) if es_prota else CuerposCercanos3D.tamano_de_pie(actor) # animales: más bajos y anchos
	if tam == Vector2.ZERO:
		tam = Vector2(RADIO_M, ALTO_M)
	forma.radius = tam.x
	forma.height = tam.y
	_forma = CollisionShape3D.new()
	_forma.shape = forma
	_forma.position.y = tam.y * 0.5
	add_child(_forma)
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING # el suelo lo pone él mismo; los choques solo son muros y cuerpos
	safe_margin = 0.01
	process_physics_priority = 100 # después de quien lo mueve: así sabe si ese paso ya se movió
	collision_layer = CAPA_PROTA if es_prota else CAPA_VECINO
	collision_mask = (CAPA_PROTA | CAPA_VECINO) if es_prota else CAPA_PROTA
	_choques = ChoquesCercanos3D.new()
	get_parent().add_child.call_deferred(_choques)
	if es_prota:
		# El protagonista deja de chocar en el mapa: ahora choca su cuerpo 3D (los demás siguen chocando con él en el mapa)
		_mascara_2d = actor.collision_mask
		actor.collision_mask = 0
		_cercanos = CuerposCercanos3D.new()
		get_parent().add_child.call_deferred(_cercanos)
		_pueblo = CuerposDelPueblo3D.new()
		get_parent().add_child.call_deferred(_pueblo)
	else:
		_mascara_2d = MASCARA_MUROS_2D
		_choques.radio(RADIO_CHOQUES_VECINO_PX)
		_choques.cruza_agua = false
	_saltar_a(actor.global_position)


## Al irse el cuerpo (el vecino se aleja o desaparece) se van con él sus copias de paredes y demás ayudantes, que
## cuelgan del escenario y no de él: si no, quedaban como muros invisibles (visto en la prueba de las puertas).
func _exit_tree() -> void:
	for ayudante in [_choques, _cercanos, _pueblo]:
		if is_instance_valid(ayudante):
			ayudante.queue_free()


## Un paso andando a `vel_mapa` (píxeles del mapa por segundo).
func mover(vel_mapa: Vector2, delta: float) -> void:
	_preparar()
	velocity.x = vel_mapa.x * Mapa3D.ESCALA
	velocity.z = vel_mapa.y * Mapa3D.ESCALA
	if not _en_suelo() or velocity.y > 0.0:
		velocity.y -= GRAVEDAD * delta
	move_and_slide()
	if es_prota and vel_mapa != Vector2.ZERO:
		_apartar(vel_mapa, delta)
	if global_position.y < _suelo_y: # nunca por debajo del suelo que pisa (sube escalones de hasta PELDANO_M)
		global_position.y = _suelo_y
		velocity.y = maxf(velocity.y, 0.0)
	_vigilar_caida()
	_volcar_al_mapa()
	_movido_en_este_paso = true


## Salta con `impulso` (m/s hacia arriba) si está en el suelo. Devuelve si saltó.
func saltar(impulso: float) -> bool:
	if en_agua == EnAgua.NADANDO or not _en_suelo():
		return false
	velocity.y = impulso
	return true


func esta_en_el_aire() -> bool:
	return velocity.y > 0.01 or not _en_suelo()


func _en_suelo() -> bool:
	return global_position.y <= _suelo_y + 0.03


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
	if not is_instance_valid(actor): # el vecino se fue del juego (huyó, murió y se enterró…)
		queue_free()
		return
	if not _movido_en_este_paso:
		mover(Vector2.ZERO, delta) # quieto (diálogo, aturdido…): sigue cayendo y siguiendo los cambios de sitio
	_movido_en_este_paso = false


## Antes de moverse: ¿lo han cambiado de sitio a mano? Suelo y paredes de alrededor al día.
func _preparar() -> void:
	var movido_px: float = actor.global_position.distance_to(_ultima_pos_mapa)
	if movido_px > SALTO_MANUAL_PX or _nivel() != _nivel_visto:
		_saltar_a(actor.global_position)
	elif movido_px > 0.01:
		var b0 := Mapa3D.a_3d(actor.global_position)
		global_position.x = b0.x
		global_position.z = b0.z
		_ultima_pos_mapa = actor.global_position
	if not es_prota: # dormido, sentado o caído no estorba (se le pasa por encima)
		_forma.disabled = CuerposCercanos3D.tamano_de_pie(actor) == Vector2.ZERO
	var p := actor.global_position
	_suelo_y = _altura_suelo(p, false)
	# Rendimiento: un vecino repasa las paredes de alrededor 1 de cada 3 pasos (las paredes no se mueven; las puertas
	# tardan un par de fotogramas más en contar); el protagonista, cada paso.
	if is_instance_valid(_choques) and _choques.is_inside_tree() and (es_prota or (Engine.get_physics_frames() + get_instance_id()) % 3 == 0):
		var excluir: Array[RID] = [actor.get_rid()]
		# Bajo tierra (capa −1) no cuentan los choques de los pisos de la posada de encima
		var mascara: int = _mascara_2d if _nivel() == -1 else _mascara_2d | Suelo.CAPA_PISOS
		_choques.excluir_destino = destino_actor
		_choques.actualizar(actor.get_world_2d().direct_space_state, p, mascara, excluir, _calle_y)
	if is_instance_valid(_cercanos) and _cercanos.is_inside_tree() and Engine.get_physics_frames() % 2 == 0:
		_cercanos.actualizar(p, _vm())
	if is_instance_valid(_pueblo) and _pueblo.is_inside_tree() and Engine.get_physics_frames() % 6 == 0:
		_pueblo.actualizar(p)


func _vm() -> Node:
	return actor.get_tree().get_first_node_in_group("village_manager")


## Piso del actor: el del protagonista lo guarda el pueblo; el de un vecino, él mismo.
func _nivel() -> int:
	if not es_prota:
		return int(actor.get("elevation_level")) if "elevation_level" in actor else 0
	var vm := _vm()
	return int(vm.get("player_elevation_level")) if vm != null else 0


## Cambia el piso del actor avisando a quien lo guarda.
func _cambiar_nivel(n: int) -> void:
	var vm := _vm()
	_nivel_visto = n
	if es_prota:
		if vm != null and vm.has_method("set_player_elevation_level"):
			vm.call("set_player_elevation_level", n)
	elif vm != null and vm.has_method("set_npc_elevation_level") and actor is VillageNPC:
		vm.call("set_npc_elevation_level", actor, n)
	elif "elevation_level" in actor:
		actor.set("elevation_level", n)


## Altura 3D del suelo que pisa en `p`. Donde hay varios suelos: al llegar de golpe (`de_golpe`), el de su piso; andando,
## el que tiene debajo según su altura, y si cambia de piso se lo dice al pueblo.
func _altura_suelo(p: Vector2, de_golpe: bool) -> float:
	var vm := _vm()
	var nivel := _nivel()
	var relieve: float = WorldStageBase3D.terrain_height_px(p)
	var pisos: Array[float] = Suelo.pisos_en(p) if nivel != -1 else ([] as Array[float])
	en_agua = EnAgua.SECO
	if es_prota and pisos.is_empty() and nivel == 0 and Agua.en_agua(p): # los vecinos no nadan: el agua les es un muro
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
		if n != nivel:
			_cambiar_nivel(n)
	return Mapa3D.a_3d(p, relieve + h).y


## Andando contra alguien con cuerpo de contacto (paso 4b), lo aparta hacia el lado en que ya está, poco a poco.
func _apartar(vel_mapa: Vector2, delta: float) -> void:
	for i in range(get_slide_collision_count()):
		var con := get_slide_collision(i).get_collider()
		var quien = null
		if con != null and con.has_meta("quien"): # cuerpo de contacto (CuerposCercanos3D)
			quien = con.get_meta("quien")
		elif con is CharacterBody3D and "actor" in con: # cuerpo completo de un vecino (opción B)
			quien = con.get("actor")
		if not (quien is Node2D) or not is_instance_valid(quien):
			continue
		var lado: Vector2 = quien.global_position - actor.global_position
		lado -= vel_mapa.normalized() * lado.dot(vel_mapa.normalized())
		if lado.length_squared() < 0.01:
			lado = vel_mapa.orthogonal()
		var destino: Vector2 = quien.global_position + lado.normalized() * APARTA_PX_S * delta
		var vm := _vm()
		if vm != null and vm.has_method("sanitize_npc_separation_pos") and "elevation_level" in quien:
			destino = vm.call("sanitize_npc_separation_pos", quien.global_position, destino, int(quien.elevation_level))
		quien.global_position = destino


## En el aire apunta lo más alto que llega; al tocar suelo, si cayó desde muy alto, se hace daño.
func _vigilar_caida() -> void:
	if not _en_suelo():
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
		return fondo if buceando else flota
	en_agua = EnAgua.VADEANDO if hondura >= VADEA_M else EnAgua.SECO
	return fondo


func _saltar_a(p: Vector2) -> void:
	_nivel_visto = _nivel()
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
