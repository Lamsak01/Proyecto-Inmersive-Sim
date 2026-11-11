extends RefCounted

## Vida tranquila de los animales en modo demo (fallo visible del usuario: «solo rondan sus nidos y van todos juntos»;
## 2026-11-11). Con la simulación completa del ecosistema en pausa, cada animal pasta por su «querencia» (un rincón
## propio alrededor de su nido, distinto para cada uno), va a beber al río, descansa un rato y huye del protagonista.
## Nada de caza, cría ni asaltos: eso sigue en pausa hasta que se apague el modo demo. Todo el estado va en `a.vida`.

enum Modo { PASTAR, IR_A_BEBER, BEBER, DESCANSAR }

const QUERENCIA_MIN_PX: float = 40.0   ## a qué distancia del nido está el rincón propio de cada animal
const QUERENCIA_MAX_PX: float = 170.0
const RADIO_PASTO_PX: float = 70.0     ## cuánto se aleja de su querencia al pastar
const LLEGADA_PX: float = 7.0
const SED_S: Vector2 = Vector2(240.0, 480.0)   ## cada cuánto le entra sed (segundos reales)
const BEBER_S: Vector2 = Vector2(8.0, 14.0)
const DESCANSO_S: Vector2 = Vector2(10.0, 22.0)
const PASTO_S: Vector2 = Vector2(3.0, 7.0)
const RIO_MAX_PX: float = 420.0        ## más lejos que esto, no va a beber
const PROB_DESCANSO: float = 0.10
const PROB_NUEVA_QUERENCIA: float = 0.10


static func paso(a: Node2D, delta: float) -> void:
	var v: Dictionary = a.vida
	if v.is_empty():
		_empezar(a, v)
	v["t"] = float(v["t"]) - delta
	v["sed"] = float(v["sed"]) - delta
	match int(v["modo"]):
		Modo.PASTAR:
			_pastar(a, v)
		Modo.IR_A_BEBER:
			_ir_a_beber(a, v)
		_:
			a.velocity = Vector2.ZERO
			if float(v["t"]) <= 0.0:
				_nuevo_pasto(a, v)


static func _empezar(a: Node2D, v: Dictionary) -> void:
	v["querencia"] = _querencia(a)
	v["sed"] = randf_range(SED_S.x * 0.3, SED_S.y)
	_nuevo_pasto(a, v)


static func _querencia(a: Node2D) -> Vector2:
	return a.home_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(QUERENCIA_MIN_PX, QUERENCIA_MAX_PX)


static func _nuevo_pasto(a: Node2D, v: Dictionary) -> void:
	if randf() < PROB_NUEVA_QUERENCIA:
		v["querencia"] = _querencia(a)
	v["modo"] = Modo.PASTAR
	v["meta"] = (v["querencia"] as Vector2) + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, RADIO_PASTO_PX)
	v["t"] = randf_range(PASTO_S.x, PASTO_S.y)


static func _pastar(a: Node2D, v: Dictionary) -> void:
	var meta: Vector2 = v["meta"]
	var llegado: bool = a.global_position.distance_to(meta) <= LLEGADA_PX
	if float(v["t"]) > 0.0 and not llegado:
		a.velocity = (meta - a.global_position).normalized() * float(a.graze_speed)
		return
	a.velocity = Vector2.ZERO
	var orilla: Vector2 = _orilla_cercana(a.global_position) if float(v["sed"]) <= 0.0 else Vector2.INF
	if orilla != Vector2.INF:
		v["modo"] = Modo.IR_A_BEBER
		v["meta"] = orilla
		v["t"] = 40.0 # si no llega en este tiempo, lo deja
	elif randf() < PROB_DESCANSO:
		v["modo"] = Modo.DESCANSAR
		v["t"] = randf_range(DESCANSO_S.x, DESCANSO_S.y)
	else:
		_nuevo_pasto(a, v)


static func _ir_a_beber(a: Node2D, v: Dictionary) -> void:
	var meta: Vector2 = v["meta"]
	if a.global_position.distance_to(meta) <= LLEGADA_PX + 3.0:
		v["modo"] = Modo.BEBER
		v["t"] = randf_range(BEBER_S.x, BEBER_S.y)
		v["sed"] = randf_range(SED_S.x, SED_S.y)
		a.velocity = Vector2.ZERO
	elif float(v["t"]) <= 0.0:
		v["sed"] = randf_range(SED_S.x, SED_S.y) * 0.5
		_nuevo_pasto(a, v)
	else:
		a.velocity = (meta - a.global_position).normalized() * float(a.graze_speed) * 1.3


## Punto de la orilla del río más cercana (10 px fuera del agua), o INF si el río queda lejos.
static func _orilla_cercana(pos: Vector2) -> Vector2:
	if pos.y < FishingSpot.river_y_start() or pos.y > FishingSpot.river_y_end():
		return Vector2.INF
	var orillas: Vector2 = FishingSpot.river_banks_at(pos.y)
	var x: float = orillas.x - 10.0 if absf(pos.x - orillas.x) <= absf(pos.x - orillas.y) else orillas.y + 10.0
	var punto := Vector2(x, pos.y)
	return punto if pos.distance_to(punto) <= RIO_MAX_PX else Vector2.INF
