extends "res://scripts/fisica/CuerpoBase3D.gd"

## Cuerpo3D: el cuerpo físico de verdad de un personaje en el mundo 3D. Desde la tanda 4 del paso a 3D (2026-11-14) lo
## llevan TODOS, siempre: el protagonista, los vecinos, los animales, los bandidos y los enemigos (Poblacion3D se lo da a
## cada uno al entrar en el juego). Ya no hay reparto por cercanía ni «cuerpos de contacto».
## Sigue siendo «cuerpo en 3D, cerebro en el mapa» (docs/specs/PLAN_TODO_3D.md): quien piensa lo hace en el mapa plano.
## - Quien lo usa le da una velocidad en el mapa (píxeles/s) con mover(); el cuerpo anda en 3D, choca con las paredes 3D
##   del mundo (ChoquesMundo3D, compartidas por todos), cae con gravedad y salta; después escribe su sitio en el mapa.
## - Si alguien mueve al personaje a mano en el mapa (camas, escaleras, cárcel, cargar partida, el ganado en su corral,
##   los animales lejanos…), el cuerpo va con él sin chocar (_seguir). Lejos del protagonista, solo de vez en cuando.
## - El suelo no es una pieza: el cuerpo sabe a qué altura está (Suelo.gd) y no baja de ahí. Donde hay varios suelos uno
##   encima de otro pisa el que tiene debajo según su altura (sube la escalera andando) y avisa de en qué piso está.
## - Agua (Agua.gd): el protagonista pisa el fondo si hace pie y, si no, flota o bucea; a los demás el agua les frena.
## - Caer desde 3 m o más hace daño al aterrizar; a 8 m, mortal.
## - Tamaño y capa según quién es (TallaCuerpo3D): personas y animales grandes estorban; a los pequeños se les pasa por
##   encima. Dormido, sentado, caído o muerto, el cuerpo se apaga. Los vecinos no chocan entre sí (su propia separación
##   los aparta) pero sí con el protagonista, que puede apartarlos andando contra ellos.
## - ATAJO (se quita con las rutas 3D, tanda 5): si alguien lleva ATASCO_S queriendo andar sin avanzar, se cuela
##   COLARSE_S sin chocar. Antes se le quitaba el cuerpo. `colados` cuenta cuántas veces pasa.

const Suelo = preload("res://scripts/fisica/Suelo.gd")
const ChoquesMundo3D = preload("res://scripts/fisica/ChoquesMundo3D.gd")
const WorldStageBase3D = preload("res://scripts/visuals/WorldStageBase3D.gd")
const Agua = preload("res://scripts/fisica/Agua.gd")

const RUTA_POBLACION: String = "res://scripts/fisica/Poblacion3D.gd" ## se carga al crear el del protagonista (sin ciclo de preloads)
const META: String = "cuerpo3d"    ## cada personaje guarda aquí su cuerpo
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
const RADIO_PAREDES_PROTA_PX: float = 110.0 ## a esta distancia el protagonista necesita las paredes levantadas
const RADIO_PAREDES_VECINO_PX: float = 48.0 ## un vecino solo necesita las que tiene al lado
const REPASO_DESTINO: int = 30     ## pasos entre repasos de lo que hay en el destino de un vecino aunque no cambie
const AVISO_CADA: int = 3          ## (no protagonista) pasos entre avisos al mundo de dónde está
const LEJOS_M: float = 22.0        ## más lejos que esto del protagonista, el cuerpo que solo sigue a su personaje…
const SEGUIR_LEJOS_CADA: int = 10  ## …se pone al día 1 de cada tantos pasos
## Red contra atascos (atajo, ver cabecera)
const ATASCO_S: float = 5.0        ## segundos queriendo andar sin avanzar tras los que se cuela
const COLARSE_S: float = 0.5       ## rato que pasa sin chocar con nada
const ATASCO_VENTANA_S: float = 1.0 ## cada cuánto se mira si avanza
const ATASCO_AVANCE_MIN: float = 0.25 ## avanzar menos de esta parte de lo pedido es no avanzar
const ATASCO_PIDE_MIN_M: float = 0.3 ## pedir menos camino que este en una ventana no es querer andar
const MARGEN_ESCALERA_M: float = 0.1 ## (vecinos) a esto del suelo de arriba o de abajo ya han acabado la escalera
const MAX_EN_DESTINO: int = 8      ## choques del mapa que se miran en el punto de destino
const SALTO_MANUAL_PX: float = 8.0  ## un cambio de sitio en el mapa mayor que esto es «a mano» (cama, escalera, cargar…);
                                    ## uno menor (las rutas de los vecinos ajustan unos píxeles) solo desplaza el cuerpo
enum EnAgua { SECO, VADEANDO, NADANDO }

static var prota_en: Vector3 = Vector3.INF ## dónde está el protagonista (para simular más barato a los lejanos)
static var colados: int = 0        ## veces que alguien se ha colado por atasco (lo miran las pruebas)

var actor: Node2D = null
var es_prota: bool = false         ## el protagonista: avisa al pueblo de su piso, nada y aparta a los demás
var destino_actor: Vector2 = Vector2.INF ## (vecinos) adónde va: lo que hay justo ahí (su cama, su silla) no le estorba
var _actor_cb: CharacterBody2D = null ## el personaje, si es un cuerpo del mapa (el ganado aún no lo es)
var _poblacion: Node = null        ## (solo el protagonista) da su cuerpo a todo el que entra en el juego
var _exentos: Array[StaticBody3D] = [] ## (vecinos) paredes de su destino con las que ahora no choca
var _destino_visto: Vector2 = Vector2.INF
var _destino_paso: int = 0
var _aviso_paso: int = -AVISO_CADA
var _talla_paso: int = 0
var _seguido_paso: int = 0
var _ultima_pos_mapa: Vector2 = Vector2.INF
var _movido_en_este_paso: bool = false
var _cima_y: float = NAN           ## lo más alto que ha estado desde que dejó el suelo (NAN: está en el suelo)
var _nivel_visto: int = 0          ## el último piso que vio: si cambia desde fuera ([E] en una escalera), va al suelo nuevo sin caer
var _ventana_s: float = 0.0        ## red contra atascos: tiempo, camino pedido (m) y sitio al empezar la ventana
var _pedido_m: float = 0.0
var _ventana_pos: Vector3 = Vector3.ZERO
var _atasco_s: float = 0.0
var _colarse_s: float = 0.0
var en_agua: int = EnAgua.SECO     ## seco, vadeando o nadando (lo mira el mando del protagonista)
var buceando: bool = false         ## nadando, si bucea va por el fondo (paso 3b; lo pone el mando)


## El cuerpo de `p_actor`: el que ya tiene o, la primera vez, uno nuevo dentro del escenario 3D. Devuelve null solo si
## el escenario aún no existe (se volverá a intentar).
static func de(p_actor: Node2D) -> CharacterBody3D:
	var ya: Variant = p_actor.get_meta(META) if p_actor.has_meta(META) else null
	if is_instance_valid(ya):
		return ya as CharacterBody3D
	var padre: Node = _escenario(p_actor)
	if padre == null:
		return null
	var c: CharacterBody3D = load("res://scripts/fisica/Cuerpo3D.gd").new()
	c.actor = p_actor
	c.es_prota = p_actor.is_in_group("player")
	c.name = "Cuerpo3D_" + str(p_actor.name)
	p_actor.set_meta(META, c)
	padre.add_child(c)
	return c


## Dónde cuelga el cuerpo de `p_actor`: el escenario 3D (CuerpoBase3D.escenario). En una escena suelta, sin pueblo,
## cuelga del propio personaje.
static func _escenario(p_actor: Node2D) -> Node:
	if not p_actor.is_inside_tree():
		return null
	if p_actor.get_tree().get_first_node_in_group("village_manager") == null:
		return p_actor
	return escenario(p_actor.get_tree())


func _ready() -> void:
	_actor_cb = actor as CharacterBody2D
	_crear_forma()
	_poner_diana(actor)
	_talla_paso = Engine.get_physics_frames() + int(get_instance_id() % TALLA_CADA) # no todos repasan en el mismo paso
	_poner_talla()
	process_physics_priority = 100 # después de quien lo mueve: así sabe si ese paso ya se movió
	if es_prota:
		# El protagonista deja de chocar en el mapa: ahora choca su cuerpo 3D
		if _actor_cb != null:
			_actor_cb.collision_mask = 0
		_poblacion = (load(RUTA_POBLACION) as GDScript).new() as Node
		get_parent().add_child.call_deferred(_poblacion)
	_saltar_a(actor.global_position)
	_ventana_pos = global_position


## Tamaño, capa y con qué choca según quién es su personaje (lo hace la base); la máscara no se toca mientras se cuela.
func _poner_talla() -> void:
	_vestir(actor, es_prota, _colarse_s <= 0.0)


## Al irse el cuerpo se va con él su ayudante, que cuelga del escenario y no de él. Las paredes no: son del mundo y las
## suelta ChoquesMundo3D cuando ya no queda nadie cerca.
func _exit_tree() -> void:
	if is_instance_valid(_poblacion):
		_poblacion.queue_free()
	if is_instance_valid(actor) and actor.has_meta(META) and actor.get_meta(META) == self:
		actor.remove_meta(META)


## Un paso andando a `vel_mapa` (píxeles del mapa por segundo).
func mover(vel_mapa: Vector2, delta: float) -> void:
	_preparar()
	_paso_fisico(vel_mapa * Mapa3D.ESCALA, delta)
	if es_prota and vel_mapa != Vector2.ZERO:
		_apartar(vel_mapa, delta)
	_pisar() # sube escalones de hasta PELDANO_M
	_vigilar_caida()
	_volcar_al_mapa()
	if es_prota:
		prota_en = global_position
	else:
		_vigilar_atasco(vel_mapa, delta)
	_movido_en_este_paso = true


## Un desplazamiento de golpe (empujón de un golpe, zancada al atacar), en píxeles del mapa: choca con las paredes.
func empujar(desplazamiento_mapa: Vector2) -> void:
	_preparar()
	move_and_collide(Mapa3D.dir_a_3d(desplazamiento_mapa) * Mapa3D.ESCALA)
	var p := Mapa3D.a_mapa(global_position)
	actor.global_position = p
	_ultima_pos_mapa = p


## Salta con `impulso` (m/s hacia arriba) si está en el suelo. Devuelve si saltó.
func saltar(impulso: float) -> bool:
	if en_agua == EnAgua.NADANDO or not _en_suelo():
		return false
	velocity.y = impulso
	return true


func esta_en_el_aire() -> bool:
	return velocity.y > 0.01 or not _en_suelo()


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


func _paredes() -> ChoquesMundo3D:
	return _mundo as ChoquesMundo3D


## Cuántas paredes 3D tiene levantadas ahora el mundo (lo miran las pruebas).
func paredes_del_mundo() -> int:
	return _paredes().cuantos() if is_instance_valid(_mundo) else 0


func _physics_process(delta: float) -> void:
	if not is_instance_valid(actor): # el personaje se fue del juego (huyó, murió y se enterró…)
		queue_free()
		return
	if _movido_en_este_paso:
		_movido_en_este_paso = false
		return
	if es_prota or not _en_suelo():
		mover(Vector2.ZERO, delta) # quieto (diálogo, aturdido…): sigue cayendo y siguiendo los cambios de sitio
		_movido_en_este_paso = false
		return
	_seguir()


## (Vecinos y animales) Nadie le ha pedido andar en este paso. Si a su personaje lo han cambiado de sitio en el mapa (las
## reglas que aún escriben la posición: el ganado, los animales lejanos, una cama, una escalera…), el cuerpo va con él
## sin chocar. Lejos del protagonista se pone al día solo de vez en cuando: simulación barata, pero el cuerpo existe.
func _seguir() -> void:
	var paso: int = Engine.get_physics_frames()
	if paso - _talla_paso >= TALLA_CADA:
		_talla_paso = paso
		_poner_talla()
	var p: Vector2 = actor.global_position
	if p.is_equal_approx(_ultima_pos_mapa) and _nivel() == _nivel_visto:
		return
	if _lejos_del_prota(global_position) and _lejos_del_prota(Mapa3D.a_3d(p)) and paso - _seguido_paso < SEGUIR_LEJOS_CADA:
		return # ni de donde sale ni adonde llega hay nadie mirando: se pone al día de vez en cuando
	_seguido_paso = paso
	_saltar_a(p)


## ¿Está ese punto del mundo lejos del protagonista (sin contar la altura)?
func _lejos_del_prota(punto: Vector3) -> bool:
	if prota_en == Vector3.INF:
		return false
	return Vector2(punto.x - prota_en.x, punto.z - prota_en.z).length_squared() > LEJOS_M * LEJOS_M


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
	var paso: int = Engine.get_physics_frames()
	if not es_prota and paso - _talla_paso >= TALLA_CADA:
		_talla_paso = paso
		_poner_talla()
	var p := actor.global_position
	_suelo_y = _altura_suelo(p, false)
	# Avisa al mundo de dónde está para que tenga levantadas las paredes de alrededor (los demás, cada AVISO_CADA pasos).
	if not is_instance_valid(_mundo) or not _mundo.is_inside_tree() or not (es_prota or paso - _aviso_paso >= AVISO_CADA):
		return
	_aviso_paso = paso
	var espacio: PhysicsDirectSpaceState2D = actor.get_world_2d().direct_space_state
	_paredes().interes(espacio, p, RADIO_PAREDES_PROTA_PX if es_prota else RADIO_PAREDES_VECINO_PX, _repaso())
	if not es_prota:
		_eximir_destino(espacio)


## Cada cuántos pasos hay que repasar las paredes de donde está: el protagonista, casi siempre (puertas al instante);
## los demás, despacio salvo que estén tocando algo (una puerta que se les acaba de abrir).
func _repaso() -> int:
	if es_prota:
		return ChoquesMundo3D.REPASO_PROTA
	return ChoquesMundo3D.REPASO_VECINO if toca_pared else ChoquesMundo3D.REPASO_TRANQUILO


## Red contra atascos (ATAJO, ver cabecera): si lleva ATASCO_S queriendo andar sin avanzar, se cuela un momento.
func _vigilar_atasco(vel_mapa: Vector2, delta: float) -> void:
	if _colarse_s > 0.0:
		_colarse_s -= delta
		if _colarse_s <= 0.0:
			collision_mask = _mascara
		return
	_ventana_s += delta
	_pedido_m += vel_mapa.length() * Mapa3D.ESCALA * get_physics_process_delta_time()
	if _ventana_s < ATASCO_VENTANA_S:
		return
	var avance_m: float = Vector2(global_position.x - _ventana_pos.x, global_position.z - _ventana_pos.z).length()
	var parado: bool = _pedido_m > ATASCO_PIDE_MIN_M and avance_m < _pedido_m * ATASCO_AVANCE_MIN
	_atasco_s = _atasco_s + _ventana_s if parado else 0.0
	_ventana_s = 0.0
	_pedido_m = 0.0
	_ventana_pos = global_position
	if _atasco_s < ATASCO_S:
		return
	_atasco_s = 0.0
	_colarse_s = COLARSE_S
	collision_mask = 0
	colados += 1


## (Vecinos) Lo que hay justo en su destino (su cama, su silla, su puesto) no le frena: deja de chocar con esas paredes
## mientras va hacia allí. Se repasa al cambiar de destino y cada REPASO_DESTINO pasos (por si se levantan después).
func _eximir_destino(espacio: PhysicsDirectSpaceState2D) -> void:
	var paso: int = Engine.get_physics_frames()
	if destino_actor == _destino_visto and paso - _destino_paso < REPASO_DESTINO:
		return
	_destino_visto = destino_actor
	_destino_paso = paso
	var nuevos: Array[StaticBody3D] = []
	if destino_actor != Vector2.INF:
		var punto := PhysicsPointQueryParameters2D.new()
		punto.position = destino_actor
		punto.collision_mask = ChoquesMundo3D.MASCARA_MAPA
		for r: Dictionary in espacio.intersect_point(punto, MAX_EN_DESTINO):
			var pared: StaticBody3D = _paredes().gemelo("%d:%d" % [(r["rid"] as RID).get_id(), int(r["shape"])])
			if is_instance_valid(pared):
				nuevos.append(pared)
	for pared in _exentos:
		if is_instance_valid(pared) and not nuevos.has(pared):
			remove_collision_exception_with(pared)
	for pared in nuevos:
		if not _exentos.has(pared):
			add_collision_exception_with(pared)
	_exentos = nuevos


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
		return _suelo_en_agua(p)
	if pisos.is_empty():
		return Mapa3D.a_3d(p, relieve + Suelo.altura_px(p, nivel, vm)).y
	var h: float
	if de_golpe:
		h = pisos.back() if nivel == 1 else pisos[0]
	else:
		h = Suelo.elegir(pisos, Mapa3D.alto_a_px(global_position.y) - relieve, Mapa3D.alto_a_px(PELDANO_M))
		var n: int = Suelo.nivel_de(h) if es_prota else _nivel_al_acabar_escalera(h, nivel)
		if n != nivel:
			_cambiar_nivel(n)
	return Mapa3D.a_3d(p, relieve + h).y


## (Vecinos) Sus rutas piensan por pisos y dan por hecho que no se cambia de piso hasta acabar la escalera: en mitad de
## la rampa conservan el piso que traían (si no, a media escalera la ruta ya los mandaba al pasillo de arriba, contra
## la barandilla). Se quita con las rutas 3D (tanda 5).
func _nivel_al_acabar_escalera(h_px: float, nivel: int) -> int:
	var margen: float = Mapa3D.alto_a_px(MARGEN_ESCALERA_M)
	if h_px >= Mapa3D.PISO_ALTO_PX - margen:
		return 1
	if h_px <= Mapa3D.TARIMA_PX + margen:
		return 0
	return nivel


## Andando contra el cuerpo de alguien, lo aparta hacia el lado en que ya está, poco a poco.
func _apartar(vel_mapa: Vector2, delta: float) -> void:
	for i in range(get_slide_collision_count()):
		var con := get_slide_collision(i).get_collider()
		if con is CharacterBody3D and con.has_method("apartar"): # ya ES su cuerpo (vive en metros): se aparta él
			var lado_m: Vector3 = (con as CharacterBody3D).global_position - global_position
			var hacia: Vector3 = Mapa3D.dir_a_3d(vel_mapa).normalized()
			lado_m -= hacia * lado_m.dot(hacia)
			lado_m.y = 0.0
			if lado_m.length_squared() < 0.0001:
				lado_m = hacia.cross(Vector3.UP)
			con.call("apartar", lado_m.normalized() * APARTA_PX_S * Mapa3D.ESCALA * delta)
			continue
		var quien: Node2D = (con.get("actor") as Node2D) if con is CharacterBody3D and "actor" in con else null
		if not is_instance_valid(quien):
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
	var hc: Variant = actor.get("health_comp")
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
	if _actor_cb != null:
		_actor_cb.velocity = Vector2(velocity.x, velocity.z) / Mapa3D.ESCALA
	_ultima_pos_mapa = p
