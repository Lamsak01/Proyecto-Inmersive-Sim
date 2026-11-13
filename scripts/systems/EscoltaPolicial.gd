extends RefCounted

## Escolta de la policía hasta la celda, sin atajos (usuario, 2026-11-12: «que me escolte de manera orgánica, tipo
## Kenshi o RimWorld»). El guardia viene andando hasta el preso y lo esposa; el preso va detrás pisando el mismo camino
## que el guardia; ante la reja el guardia se aparta y el preso entra andando. Nadie salta de sitio: si el guardia cae
## o no hay manera de avanzar, el preso queda libre donde esté. Lo mueve VillageManager cada fotograma (`tick`).

const Edificio = preload("res://mapa/edificio.gd")
const Marca = preload("res://mapa/marca.gd")

enum Fase { ACERCARSE, LLEVAR, ENTRAR }

const ALCANCE_ESPOSAR_PX: float = 22.0 ## a esta distancia el guardia pone las esposas
const CUERDA_PX: float = 14.0          ## el preso va este trecho detrás del guardia, por donde él ha pasado
const CUERDA_ESPERA_PX: float = 42.0   ## si el preso se queda más atrás, el guardia le espera
const PASO_TRAZA_PX: float = 4.0       ## cada cuánto se apunta un paso del guardia (y cuándo el preso lo da por pisado)
const PRESO_VELOCIDAD: float = 96.0    ## px/s como mucho del preso: algo más que el guardia, para no quedarse atrás
const LLEGADA_PX: float = 3.0          ## el preso ha llegado a un punto del camino de entrada
const GUARDIA_LLEGADA_PX: float = 8.0  ## el guardia ha llegado ante la reja
const ATASCO_S: float = 15.0           ## si en este tiempo quien anda no avanza ATASCO_AVANCE_PX, el guardia desiste
const ATASCO_AVANCE_PX: float = 24.0
const APARTE_PLANO := Vector2(24.0, -8.0) ## donde espera el guardia, a un lado de la salida de la celda (plano)

var fase: Fase = Fase.ACERCARSE
var _traza: PackedVector2Array = []    ## pasos del guardia que el preso aún no ha pisado
var _entrada: PackedVector2Array = []  ## salida de la celda → reja → centro de la celda
var _atasco_s: float = 0.0
var _atasco_ref: Vector2 = Vector2.INF


func empezar() -> void:
	fase = Fase.ACERCARSE
	_traza.clear()
	_entrada.clear()
	_reiniciar_atasco(Vector2.INF)


## Adónde anda el guardia que escolta (lo pide VillageNPC). Si el preso se queda atrás, se para a esperarle.
func destino_guardia(vm: Node, guardia: Node2D) -> Vector2:
	var preso: Node2D = vm.get("_cached_player")
	if fase == Fase.ACERCARSE and is_instance_valid(preso):
		return preso.global_position
	if fase == Fase.ENTRAR:
		return Marca.mundo(vm.get("ID_COMISARIA"), Marca.CELDA_SALIDA, APARTE_PLANO)
	if is_instance_valid(preso) and _pendiente(preso) > CUERDA_ESPERA_PX:
		return guardia.global_position
	return Marca.mundo(vm.get("ID_COMISARIA"), Marca.CELDA_SALIDA)


func tick(vm: Node, preso: CharacterBody2D, delta: float) -> void:
	var guardia: VillageNPC = vm.get("escorting_officer")
	if not _en_pie(guardia):
		vm.call("soltar_preso", preso, "⛓️ El guardia que te llevaba ha caído: estás libre")
		return
	match fase:
		Fase.ACERCARSE:
			_acercarse(vm, preso, guardia)
		Fase.LLEVAR:
			_llevar(vm, preso, guardia, delta)
		Fase.ENTRAR:
			_entrar(vm, preso, delta)
	_vigilar_atasco(vm, guardia if fase == Fase.ACERCARSE else preso, preso, delta)


static func _en_pie(guardia: VillageNPC) -> bool:
	return is_instance_valid(guardia) and not guardia.is_dead and guardia.is_conscious() and guardia.sedated_timer <= 0.0


## El preso espera quieto a que llegue el guardia; al tenerlo al lado, esposas.
func _acercarse(vm: Node, preso: CharacterBody2D, guardia: Node2D) -> void:
	preso.velocity = Vector2.ZERO
	if preso.global_position.distance_to(guardia.global_position) > ALCANCE_ESPOSAR_PX:
		return
	fase = Fase.LLEVAR
	_traza = PackedVector2Array([guardia.global_position])
	_reiniciar_atasco(preso.global_position)
	vm.call("_hint_player", "⛓️ Esposado: el guardia te lleva andando a la celda de la comisaría", preso)


## El preso pisa los pasos del guardia en orden (así cruza las mismas puertas) hasta quedar a una cuerda de él.
func _llevar(vm: Node, preso: CharacterBody2D, guardia: Node2D, delta: float) -> void:
	if _traza[_traza.size() - 1].distance_to(guardia.global_position) >= PASO_TRAZA_PX:
		_traza.append(guardia.global_position)
	while _traza.size() > 1 and preso.global_position.distance_to(_traza[0]) <= PASO_TRAZA_PX:
		_traza.remove_at(0)
	preso.velocity = Vector2.ZERO if _pendiente(preso) <= CUERDA_PX else _hacia(preso, _traza[0], delta)
	var ante_reja: Vector2 = Marca.mundo(vm.get("ID_COMISARIA"), Marca.CELDA_SALIDA)
	if guardia.global_position.distance_to(ante_reja) > GUARDIA_LLEGADA_PX:
		return
	fase = Fase.ENTRAR
	var id: String = vm.get("ID_COMISARIA")
	_entrada = PackedVector2Array([ante_reja, Marca.mundo(id, Marca.CELDA_PUERTA), Marca.mundo(id, Marca.CELDA)])


## El guardia se ha apartado: el preso cruza la reja andando y, en el centro de la celda, se cierra.
func _entrar(vm: Node, preso: CharacterBody2D, delta: float) -> void:
	while _entrada.size() > 1 and preso.global_position.distance_to(_entrada[0]) <= LLEGADA_PX:
		_entrada.remove_at(0)
	if _entrada.size() == 1 and preso.global_position.distance_to(_entrada[0]) <= LLEGADA_PX:
		preso.velocity = Vector2.ZERO
		vm.call("complete_police_escort_to_jail", preso)
		return
	preso.velocity = _hacia(preso, _entrada[0], delta)


## Si quien tiene que andar no avanza en mucho rato (un paso cerrado), el guardia desiste: nadie salta de sitio.
func _vigilar_atasco(vm: Node, quien: Node2D, preso: Node2D, delta: float) -> void:
	if _atasco_ref == Vector2.INF or quien.global_position.distance_to(_atasco_ref) >= ATASCO_AVANCE_PX:
		_reiniciar_atasco(quien.global_position)
		return
	_atasco_s += delta
	if _atasco_s >= ATASCO_S and vm.get("player_being_escorted_to_jail"):
		vm.call("soltar_preso", preso, "⛓️ El guardia no encuentra paso y te suelta: estás libre, pero te siguen buscando")


func _reiniciar_atasco(p: Vector2) -> void:
	_atasco_ref = p
	_atasco_s = 0.0


## Camino que le queda al preso hasta el guardia: hasta el primer paso sin pisar y de ahí, paso a paso.
func _pendiente(preso: Node2D) -> float:
	if _traza.is_empty():
		return 0.0
	var largo: float = preso.global_position.distance_to(_traza[0])
	for i in range(1, _traza.size()):
		largo += _traza[i - 1].distance_to(_traza[i])
	return largo


## Velocidad para llegar a `p` sin pasarse en este fotograma.
static func _hacia(preso: Node2D, p: Vector2, delta: float) -> Vector2:
	return ((p - preso.global_position) / maxf(delta, 0.001)).limit_length(PRESO_VELOCIDAD)
