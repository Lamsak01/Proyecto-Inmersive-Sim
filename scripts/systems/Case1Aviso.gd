extends RefCounted

## Caso I, arranque (decidido por el usuario el 2026-11-13): al alba del día 2 aparece el cuerpo; un guardia viene
## andando a buscarte («el alguacil mayor Vane le manda llamar»), luego se queda custodiando la escena hasta que el
## cuerpo va a la morgue; Vane, en la comisaría, te cuenta lo del arroyo. Estado en town_state › forensics › case1.

## Sin preload de VillageCase1 (que carga este archivo): el estado del caso y el sitio del cuerpo llegan como parámetros.
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const Agua = preload("res://scripts/fisica/Agua.gd")

const MENSAJERO: String = "case1_mensajero" ## encargo del guardia que va a buscarte
const CUSTODIA: String = "case1_custodia"   ## encargo del guardia que vigila el cuerpo
const LLEGA_PX: float = 40.0                ## a ~2 m de ti, te da el recado
const CUSTODIA_DESFASE_PX: Vector2 = Vector2(55.0, 10.0) ## de pie a ~3 m del cuerpo, sin pisarlo
const HORAS_SIN_LLEGAR: int = 2             ## si el guardia no te alcanza en 2 horas, el recado llega igual (un chico)
const SALIDA_PX: float = 900.0              ## aparece a ~50 m de ti, en su dirección (lo ves llegar sin esperar horas)
const SALIDA_GIRO_GRADOS: float = 30.0      ## si ese punto cae en agua o dentro de una casa, prueba girando de 30 en 30°
const RECADO: String = "💂 Un guardia: «Detective, el alguacil mayor Vane le manda llamar a la comisaría. Es urgente.»"
const RECADO_HABLADO: String = "Detective, por fin le encuentro. El alguacil mayor Vane le manda llamar a la comisaría. Es urgente: han encontrado a alguien junto al arroyo."
const RESPUESTA_RECADO: String = "Voy enseguida."
const RECADO_SIN_GUARDIA: String = "🔔 Un chico del pueblo te trae un recado: el alguacil mayor Vane te manda llamar a la comisaría."
const ENCARGO_VANE: String = "«Al alba han encontrado a una mujer muerta junto al arroyo del norte. He dejado a un guardia vigilando para que nadie toque nada. Mírela usted antes de que la llevemos a la morgue.»"
const PREGUNTA_VANE: String = "🔎 «¿Para qué me ha mandado llamar?»"
const ACCION_VANE: String = "case1:encargo_vane"

## Llamado al empezar el caso (VillageCase1.sync): manda al guardia una sola vez.
static func empezar(vm, st: Dictionary, cuerpo_pos: Vector2) -> void:
	if st.has("aviso"):
		return
	st["aviso"] = "en_camino"
	st["aviso_desde"] = VillageNeeds.total_hours()
	var guardia = _guardia(vm, st)
	if guardia == null:
		_dar_recado(vm, st, null, cuerpo_pos)
		return
	guardia.start_errand(MENSAJERO, _jugador_pos(vm))
	_acercar(vm, guardia)

## Cada segundo (VillageCase1.tick): el mensajero te sigue hasta alcanzarte.
static func tick(vm, st: Dictionary, cuerpo_pos: Vector2) -> void:
	if str(st.get("aviso", "")) != "en_camino":
		return
	var guardia = _guardia(vm, st)
	var tarde: bool = VillageNeeds.total_hours() - int(st.get("aviso_desde", 0)) >= HORAS_SIN_LLEGAR
	if guardia == null or tarde:
		_dar_recado(vm, st, null, cuerpo_pos)
		return
	var destino: Vector2 = _jugador_pos(vm)
	if guardia.errand_kind != MENSAJERO:
		guardia.start_errand(MENSAJERO, destino)
	guardia.errand_pos = destino
	if guardia.global_position.distance_to(destino) <= LLEGA_PX and not _jugador_ocupado(vm):
		_dar_recado(vm, st, guardia, cuerpo_pos)

## Cada hora (VillageCase1.sync): el guardia vuelve a su puesto junto al cuerpo hasta que se lo llevan a la morgue.
static func vigilar(vm, st: Dictionary, cuerpo_pos: Vector2) -> void:
	if str(st.get("aviso", "")) != "dado":
		return
	var guardia = _guardia(vm, st)
	if guardia == null:
		return
	var cuerpo = vm.entities_root.get_node_or_null("NPC_Case1_Victim")
	var sigue_alli: bool = is_instance_valid(cuerpo) and not bool(cuerpo.corpse_in_morgue) and not bool(cuerpo.corpse_buried)
	if not sigue_alli:
		if guardia.errand_kind == CUSTODIA:
			guardia.end_errand()
		return
	if guardia.errand_kind != CUSTODIA:
		guardia.start_errand(CUSTODIA, cuerpo_pos + CUSTODIA_DESFASE_PX)

## Diálogo de Vane: tras el recado y hasta que te lo cuenta, ofrece la pregunta del encargo.
static func add_dialogue(npc, st: Dictionary, diag: Dictionary, ch_arr: Array) -> void:
	if int(npc.trade_role) != int(VillageNPC.TradeRole.SHERIFF):
		return
	if str(st.get("aviso", "")) != "dado" or st.get("encargo_vane") == true:
		return
	diag["case1_encargo_vane"] = {"text": ENCARGO_VANE, "choices": [{"label": "⬅️ Volver", "next": "start"}]}
	ch_arr.insert(0, {"label": PREGUNTA_VANE, "next": "case1_encargo_vane", "action": ACCION_VANE})

## Vane ya te ha encargado el caso: se apunta en el cuaderno (y abre el primer objetivo).
static func on_encargo(vm, npc, st: Dictionary) -> void:
	st["encargo_vane"] = true
	var jugador = vm.get_tree().get_first_node_in_group("player")
	vm._record_case_clue(jugador, "🗣️ " + str(npc.npc_name), ENCARGO_VANE,
		"%s: %s" % [npc.npc_name, ENCARGO_VANE], "Encargo del alguacil", "case1_encargo_vane", Color(0.95, 0.80, 0.55))

static func _dar_recado(vm, st: Dictionary, guardia, cuerpo_pos: Vector2) -> void:
	st["aviso"] = "dado"
	vm._hint_player(RECADO if guardia != null else RECADO_SIN_GUARDIA)
	if guardia != null:
		guardia.end_errand()
		_hablar(vm, guardia)
	vigilar(vm, st, cuerpo_pos)

## El guardia te lo dice de viva voz, con la caja de diálogo: una línea suelta abajo se perdía (usuario, 2026-11-13).
static func _hablar(vm, guardia) -> void:
	var jugador = vm.get_tree().get_first_node_in_group("player")
	var dm = jugador.get("dialogue_manager") if jugador != null else null
	if dm == null:
		return
	var grafo: Dictionary = {"start": {"text": RECADO_HABLADO, "choices": [{"label": RESPUESTA_RECADO, "next": "END"}]}}
	dm.start_dialogue(grafo, "start", guardia)

## ¿Estás ya hablando o con un panel abierto? Entonces el guardia espera a tu lado en vez de cortarte.
static func _jugador_ocupado(vm) -> bool:
	var jugador = vm.get_tree().get_first_node_in_group("player")
	if jugador == null:
		return false
	return jugador.has_method("is_any_ui_modal_open") and bool(jugador.is_any_ui_modal_open())

## El valle es grande y andando tardaría horas: el guardia aparece en campo abierto a ~50 m de ti, por el lado del
## pueblo, para que lo veas llegar y no salga de golpe delante de ti. Nunca en el agua ni dentro de una casa.
static func _acercar(vm, guardia) -> void:
	var jugador_pos: Vector2 = _jugador_pos(vm)
	if guardia.global_position.distance_to(jugador_pos) <= SALIDA_PX:
		return
	var hacia_pueblo: Vector2 = jugador_pos.direction_to(guardia.global_position)
	var intentos: int = int(360.0 / SALIDA_GIRO_GRADOS)
	for i in range(intentos):
		var giro: float = deg_to_rad(SALIDA_GIRO_GRADOS * ceil(i / 2.0) * (1.0 if i % 2 == 0 else -1.0)) # 0, +30, -30, +60…
		var punto: Vector2 = jugador_pos + hacia_pueblo.rotated(giro) * SALIDA_PX
		if not Agua.en_agua(punto) and not vm._is_pos_inside_any_building(punto):
			guardia.global_position = punto
			return

## El guardia del caso: el primero de patrulla (se guarda por nombre para que sea siempre el mismo).
static func _guardia(vm, st: Dictionary):
	var vivos: Array = VillageNeeds.living(vm)
	var nombre: String = str(st.get("guardia", ""))
	for n in vivos:
		if nombre != "" and str(n.npc_name) == nombre:
			return n
	for n in vivos:
		if int(n.trade_role) == int(VillageNPC.TradeRole.GUARD):
			st["guardia"] = str(n.npc_name)
			return n
	return null

static func _jugador_pos(vm) -> Vector2:
	var jugador = vm.get_tree().get_first_node_in_group("player") as Node2D
	return jugador.global_position if jugador != null else Vector2.ZERO
