class_name VidaAnimal
extends RefCounted

## Vida tranquila de los animales en modo demo (fallo visible del usuario: «solo rondan sus nidos y van todos juntos»;
## 2026-11-11). Con la simulación completa del ecosistema en pausa, cada animal pasta por su «querencia» (un rincón
## propio alrededor de su nido, distinto para cada uno), va a beber al río, descansa un rato y huye del protagonista.
## Nada de caza, cría ni asaltos: eso sigue en pausa hasta que se apague el modo demo. Todo el estado va en `a.vida`.
## Desde la tanda 4b-2 del paso a 3D (2026-11-14) todo va en metros sobre el suelo.
## TRADUCTOR: la orilla del río aún se pregunta al mapa plano (RioLago), hasta que el río dé su forma en metros.

enum Modo { PASTAR, IR_A_BEBER, BEBER, DESCANSAR }

const QUERENCIA_M: Vector2 = Vector2(2.2, 9.5)  ## (mín., máx.) a qué distancia del nido está el rincón propio de cada animal
const RADIO_PASTO_M: float = 3.9       ## cuánto se aleja de su querencia al pastar
const LLEGADA_M: float = 0.4
const LLEGADA_ORILLA_M: float = 0.56
const SED_S: Vector2 = Vector2(240.0, 480.0)   ## cada cuánto le entra sed (segundos reales)
const BEBER_S: Vector2 = Vector2(8.0, 14.0)
const DESCANSO_S: Vector2 = Vector2(10.0, 22.0)
const PASTO_S: Vector2 = Vector2(3.0, 7.0)
const IR_A_BEBER_S: float = 40.0       ## si no llega a la orilla en este tiempo, lo deja
const PRISA_SED: float = 1.3           ## va a beber algo más deprisa de lo que pasta
const RIO_MAX_M: float = 23.5          ## más lejos que esto, no va a beber
const ORILLA_FUERA_PX: float = 10.0    ## a lo que se queda del agua (unidades del mapa plano, ver TRADUCTOR)
const PROB_DESCANSO: float = 0.10
const PROB_NUEVA_QUERENCIA: float = 0.10


static func paso(a: WildAnimal, delta: float) -> void:
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
			a.andar = Vector2.ZERO
			if float(v["t"]) <= 0.0:
				_nuevo_pasto(a, v)


static func _empezar(a: WildAnimal, v: Dictionary) -> void:
	v["querencia"] = _querencia(a)
	v["sed"] = randf_range(SED_S.x * 0.3, SED_S.y)
	_nuevo_pasto(a, v)


static func _querencia(a: WildAnimal) -> Vector2:
	return a.casa + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(QUERENCIA_M.x, QUERENCIA_M.y)


static func _nuevo_pasto(a: WildAnimal, v: Dictionary) -> void:
	if randf() < PROB_NUEVA_QUERENCIA:
		v["querencia"] = _querencia(a)
	v["modo"] = Modo.PASTAR
	v["meta"] = (v["querencia"] as Vector2) + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, RADIO_PASTO_M)
	v["t"] = randf_range(PASTO_S.x, PASTO_S.y)


static func _pastar(a: WildAnimal, v: Dictionary) -> void:
	var meta: Vector2 = v["meta"]
	var llegado: bool = a.sitio.distance_to(meta) <= LLEGADA_M
	if float(v["t"]) > 0.0 and not llegado:
		a.andar = (meta - a.sitio).normalized() * a.paso_m_s
		return
	a.andar = Vector2.ZERO
	var orilla: Vector2 = _orilla_cercana(a.sitio) if float(v["sed"]) <= 0.0 else Vector2.INF
	if orilla != Vector2.INF:
		v["modo"] = Modo.IR_A_BEBER
		v["meta"] = orilla
		v["t"] = IR_A_BEBER_S
	elif randf() < PROB_DESCANSO:
		v["modo"] = Modo.DESCANSAR
		v["t"] = randf_range(DESCANSO_S.x, DESCANSO_S.y)
	else:
		_nuevo_pasto(a, v)


static func _ir_a_beber(a: WildAnimal, v: Dictionary) -> void:
	var meta: Vector2 = v["meta"]
	if a.sitio.distance_to(meta) <= LLEGADA_ORILLA_M:
		v["modo"] = Modo.BEBER
		v["t"] = randf_range(BEBER_S.x, BEBER_S.y)
		v["sed"] = randf_range(SED_S.x, SED_S.y)
		a.andar = Vector2.ZERO
	elif float(v["t"]) <= 0.0:
		v["sed"] = randf_range(SED_S.x, SED_S.y) * 0.5
		_nuevo_pasto(a, v)
	else:
		a.andar = (meta - a.sitio).normalized() * a.paso_m_s * PRISA_SED


## Punto de la orilla del río más cercana a `sitio` (algo fuera del agua), o INF si el río queda lejos.
static func _orilla_cercana(sitio: Vector2) -> Vector2:
	var pos: Vector2 = Lugar.a_mapa(sitio)
	if pos.y < RioLago.river_y_start() or pos.y > RioLago.river_y_end():
		return Vector2.INF
	var orillas: Vector2 = RioLago.river_banks_at(pos.y)
	var x: float = orillas.x - ORILLA_FUERA_PX if absf(pos.x - orillas.x) <= absf(pos.x - orillas.y) else orillas.y + ORILLA_FUERA_PX
	var punto: Vector2 = Lugar.a_suelo(Vector2(x, pos.y))
	return punto if sitio.distance_to(punto) <= RIO_MAX_M else Vector2.INF
