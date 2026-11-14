extends Node
## Gestor de diálogos: recorre el árbol de frases y opciones que montan los vecinos y lo enseña en la ventana
## provisional (scripts/ui/dialogo/). Frases largas en trozos que se pasan con clic, E, Espacio o Intro; opciones
## con 1-9, W/S o ratón; Esc sale. Un nodo marcado «tienda» abre la ventana de tienda en vez de la caja.
## Cada opción puede cambiar la relación («affinity») y lanzar una acción («action»); eso no cambia (2026-11-13).

const DialogoTexto = preload("res://scripts/ui/dialogo/DialogoTexto.gd")
const DialogoVentanaScript = preload("res://scripts/ui/dialogo/DialogoVentana.gd")
const TiendaUIScript = preload("res://scripts/ui/dialogo/TiendaUI.gd")

const ESPERA_ENTRE_PULSACIONES: float = 0.15 ## evita que la E que abre el diálogo pase ya la primera frase
const XP_CARISMA_POR_CHARLA: int = 3
const NODO_TIENDA: String = "tienda"

@export var dialogue_box: Control ## caja antigua de la escena: se esconde
@export var dialogue_text: Label
@export var choices_box: VBoxContainer

signal dialogue_finished(last_id: String, speaker: Node)
signal choice_action_triggered(action_id: String, speaker: Node)

var graph: Dictionary = {}
var current_id: String = ""
var active: bool = false
var current_speaker: Node = null
var current_choices: Array = []

var _ventana: Control
var _tienda: Control
var _trozos: Array[String] = []
var _trozo: int = 0
var _opciones_puestas: bool = false
var _espera: float = 0.0

func _ready() -> void:
	if dialogue_box:
		dialogue_box.visible = false
	_construir()

func _construir() -> void:
	var cs: Node = get_tree().current_scene
	var padre: Node = cs.get_node_or_null("UI/UIRoot") if cs else null
	if padre == null:
		padre = get_parent()
	_ventana = DialogoVentanaScript.new()
	_ventana.name = "DialoguePanel"
	_ventana.visible = false
	_ventana.avanzar_pulsado.connect(_avanzar)
	_ventana.opcion_pulsada.connect(_on_choice_pressed)
	_tienda = TiendaUIScript.new()
	_tienda.name = "TiendaPanel"
	_tienda.fila_elegida.connect(_on_fila_tienda)
	_tienda.cerrada.connect(_on_tienda_cerrada)
	padre.call_deferred("add_child", _ventana)
	padre.call_deferred("add_child", _tienda)

func _process(delta: float) -> void:
	if _espera > 0.0:
		_espera -= delta
	if not active:
		return
	if not _hablante_puede_seguir():
		end_dialogue()
		return
	if not _opciones_puestas and _trozo == _trozos.size() - 1 and not _ventana.revelando():
		_poner_opciones()

func _hablante_puede_seguir() -> bool:
	if current_speaker == null:
		return true
	if not is_instance_valid(current_speaker):
		return false
	var sedado: float = float(current_speaker.get("sedated_timer")) if "sedated_timer" in current_speaker else 0.0
	for estado in ["is_dead", "is_downed", "is_hostile", "is_attacking", "is_stunned_flag"]:
		if current_speaker.get(estado) == true:
			return false
	return sedado <= 0.0

## El reloj del pueblo se para mientras dura la charla (incluida la tienda, que va dentro de ella)
func _parar_reloj(parar: bool) -> void:
	var reloj: Node = get_node_or_null("/root/WorldClock")
	if reloj != null and reloj.has_method("set_dialogue_pause"):
		reloj.call("set_dialogue_pause", parar)

func is_active() -> bool:
	return active

func start_dialogue(new_graph: Dictionary, start_id: String, speaker: Node = null) -> void:
	graph = new_graph
	current_speaker = speaker
	active = true
	_espera = ESPERA_ENTRE_PULSACIONES
	_parar_reloj(true)
	_poner_hablante()
	_ventana.visible = true
	_show_node(start_id)

func end_dialogue() -> void:
	active = false
	_parar_reloj(false)
	current_choices.clear()
	_ventana.visible = false
	if _tienda.visible:
		_tienda.visible = false
	dialogue_finished.emit(current_id, current_speaker)

func _poner_hablante() -> void:
	if not is_instance_valid(current_speaker):
		_ventana.poner_hablante("", "", "", Color.WHITE)
		return
	var nombre: String = str(current_speaker.get("npc_name")) if "npc_name" in current_speaker else str(current_speaker.name)
	var oficio: String = str(current_speaker.get("npc_role")) if "npc_role" in current_speaker else ""
	var relacion: String = ""
	var color: Color = Color.WHITE
	if current_speaker.has_method("get_relationship_status_text"):
		relacion = DialogoTexto.sin_emojis(str(current_speaker.get_relationship_status_text())).split("|")[-1].strip_edges() # sin repetir el oficio
		color = current_speaker.get_relationship_color()
	_ventana.poner_hablante(nombre, oficio, relacion, color)

func _show_node(id: String) -> void:
	if not graph.has(id):
		end_dialogue()
		return
	current_id = id
	var nodo: Dictionary = graph[id]
	current_choices = nodo.get("choices", [])
	if bool(nodo.get(NODO_TIENDA, false)):
		_abrir_tienda(nodo)
		return
	_tienda.visible = false # salir de la tienda por cualquier camino devuelve la caja
	_ventana.visible = true
	_trozos = DialogoTexto.trozos(DialogoTexto.limpiar_texto(str(nodo.get("text", ""))))
	_trozo = 0
	_pintar_trozo()

func _pintar_trozo() -> void:
	_opciones_puestas = false
	_ventana.poner_opciones([] as Array[String])
	_ventana.poner_trozo(_trozos[_trozo], _trozo + 1, _trozos.size())

func _poner_opciones() -> void:
	_opciones_puestas = true
	var etiquetas: Array[String] = []
	for c in current_choices:
		etiquetas.append(DialogoTexto.limpiar_etiqueta(str((c as Dictionary).get("label", "Seguir"))))
	_ventana.poner_opciones(etiquetas)

## Clic en la caja, E, Espacio o Intro: termina de escribir la frase o pasa al siguiente trozo. En el último no
## elige nada (para no escoger sin querer al pasar texto deprisa): ahí se elige con número, clic o Intro.
func _avanzar() -> void:
	if not active or _espera > 0.0:
		return
	if _ventana.revelando():
		_ventana.revelar_todo()
	elif _trozo < _trozos.size() - 1:
		_trozo += 1
		_pintar_trozo()
	elif current_choices.is_empty():
		end_dialogue()

func _unhandled_input(event: InputEvent) -> void:
	if not active or _espera > 0.0:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _tienda.visible:
			_tienda.cerrar()
		else:
			end_dialogue()
		return
	if _tienda.visible:
		return
	if event.is_action_pressed("Interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_avanzar()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var tecla: InputEventKey = event
	if tecla.keycode >= KEY_1 and tecla.keycode <= KEY_9 and _opciones_puestas:
		get_viewport().set_input_as_handled()
		_on_choice_pressed(tecla.keycode - KEY_1)
	elif tecla.physical_keycode in [KEY_W, KEY_S] and _opciones_puestas:
		get_viewport().set_input_as_handled()
		_ventana.mover_foco(-1 if tecla.physical_keycode == KEY_W else 1)

func _on_choice_pressed(index: int) -> void:
	if not active or _espera > 0.0 or index < 0 or index >= current_choices.size():
		return
	var elegida: Dictionary = current_choices[index]
	_espera = ESPERA_ENTRE_PULSACIONES
	_aplicar(elegida)
	var siguiente: String = str(elegida.get("next", "END"))
	if siguiente == "" or siguiente == "END":
		end_dialogue()
		return
	_show_node(siguiente)

## Efectos de una opción: relación, acción y árbol rehecho (la acción puede cambiar lo que el vecino ofrece).
func _aplicar(elegida: Dictionary) -> void:
	if elegida.has("affinity") and is_instance_valid(current_speaker) and current_speaker.has_method("modify_affinity"):
		var antes: int = int(current_speaker.get("affinity")) if current_speaker.get("affinity") != null else 0
		current_speaker.modify_affinity(int(elegida["affinity"]))
		if int(elegida["affinity"]) > 0 and antes < 100:
			var jugador = get_tree().get_first_node_in_group("player")
			if jugador and jugador.has_method("add_skill_xp"):
				jugador.call("add_skill_xp", "charisma", XP_CARISMA_POR_CHARLA)
		_poner_hablante()
	var accion: String = str(elegida.get("action", ""))
	if accion == "":
		return
	choice_action_triggered.emit(accion, current_speaker)
	if is_instance_valid(current_speaker) and current_speaker.has_method("on_dialogue_action"):
		current_speaker.on_dialogue_action(accion)
	if is_instance_valid(current_speaker) and current_speaker.has_method("_build_dialogue"):
		var nuevo: Dictionary = current_speaker.call("_build_dialogue")
		if current_speaker.has_method("_inject_character_lore_into_dialogue"):
			nuevo = current_speaker.call("_inject_character_lore_into_dialogue", nuevo)
		graph = nuevo
		_poner_hablante()

# ---------------------------------------------------------------- tienda
func _abrir_tienda(nodo: Dictionary) -> void:
	_ventana.visible = false
	var jugador = get_tree().get_first_node_in_group("player")
	var inv: Object = jugador.get("inventory") if jugador != null else null
	var nombre: String = str(current_speaker.get("npc_name")) if is_instance_valid(current_speaker) and "npc_name" in current_speaker else ""
	var oficio: String = str(current_speaker.get("npc_role")) if is_instance_valid(current_speaker) and "npc_role" in current_speaker else ""
	var titulo: String = ("%s · %s" % [nombre, oficio]) if oficio != "" else nombre
	var frase: String = str(nodo.get("text", ""))
	_tienda.abrir(titulo, ("«%s»" % frase) if frase != "" else "", current_choices, inv)

func _on_fila_tienda(indice: int) -> void:
	if not active or indice < 0 or indice >= current_choices.size():
		return
	var fila: Dictionary = current_choices[indice]
	var jugador = get_tree().get_first_node_in_group("player")
	var inv: Object = jugador.get("inventory") if jugador != null else null
	var f: Dictionary = TiendaUIScript.describir(fila, inv)
	var oro_antes: int = int(inv.get("gold")) if inv != null else 0
	_aplicar(fila)
	if not graph.has(NODO_TIENDA) or not bool((graph[NODO_TIENDA] as Dictionary).get(NODO_TIENDA, false)):
		_tienda.cerrar() # ya no vende (se ha ido del mostrador…): vuelve a la charla
		return
	_show_node(NODO_TIENDA) # repinta con existencias y bolsa nuevas
	var oro_despues: int = int(inv.get("gold")) if inv != null else oro_antes
	_tienda.avisar(_resultado_compra(bool(f["es_compra"]), str(f["nombre"]), oro_despues - oro_antes, oro_antes, int(f["precio"])), oro_despues != oro_antes)

## Qué ha pasado al pulsar una fila (el aviso del vecino sale sobre su cabeza, tapado por la tienda).
func _resultado_compra(es_compra: bool, nombre: String, diferencia: int, oro_antes: int, precio: int) -> String:
	if diferencia < 0:
		return "Has comprado %s por %d %s." % [nombre, -diferencia, DialogoTexto.PALABRA_DINERO]
	if diferencia > 0:
		return "Has vendido %s por %d %s." % [nombre, diferencia, DialogoTexto.PALABRA_DINERO]
	if es_compra and oro_antes < precio:
		return "No te llega el dinero."
	return "No ha podido ser: ya no le queda." if es_compra else "Ahora no te lo puede comprar."

func _on_tienda_cerrada() -> void:
	if not active:
		return
	_ventana.visible = true
	_espera = ESPERA_ENTRE_PULSACIONES
	_show_node("start")
