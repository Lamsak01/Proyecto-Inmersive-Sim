extends Node

## Teclas que el jugador puede cambiar (Claude Code, 2026-11-10; menú de ajustes → Controles).
## Se guardan en user://teclas.cfg. En el código, en vez de «event.keycode == KEY_I», se pregunta
## «Teclas.es(event, "mochila")». Las de los menús (diálogos, juegos de la taberna…), Esc y los trucos con Ctrl no
## se cambian. La lista de teclas por defecto está también en docs/CONTROLES.md.

signal cambiadas

const RUTA: String = "user://teclas.cfg"

## [id, nombre para el jugador, tecla por defecto, grupo, acción del InputMap ("" si no tiene)]
const ACCIONES: Array = [
	["avanzar", "Avanzar", KEY_W, "Moverse y pelear", "move_up"],
	["retroceder", "Retroceder", KEY_S, "Moverse y pelear", "move_down"],
	["izquierda", "Izquierda", KEY_A, "Moverse y pelear", "move_left"],
	["derecha", "Derecha", KEY_D, "Moverse y pelear", "move_right"],
	["correr", "Correr", KEY_SHIFT, "Moverse y pelear", "sprint"],
	["saltar", "Saltar", KEY_SPACE, "Moverse y pelear", ""],
	["rodar", "Rodar / golpe letal", KEY_V, "Moverse y pelear", ""],
	["sigilo", "Sigilo (agacharse)", KEY_C, "Moverse y pelear", ""],
	["bloquear", "Bloquear / golpe no letal", KEY_Q, "Moverse y pelear", ""],
	["empujar", "Empujar", KEY_X, "Moverse y pelear", ""],
	["recargar", "Recargar / cambiar semilla", KEY_R, "Moverse y pelear", ""],
	["accion", "Acción / hablar / recoger", KEY_E, "Mundo", "Interact"],
	["otra_accion", "Cambiar de objetivo", KEY_G, "Mundo", ""],
	["atrancar", "Atrancar puerta", KEY_B, "Mundo", ""],
	["forzar", "Forzar cerradura", KEY_F, "Mundo", ""],
	["rueda", "Rueda de herramientas", KEY_TAB, "Paneles", ""],
	["mochila", "Mochila", KEY_I, "Paneles", ""],
	["salud", "Salud / heridas", KEY_U, "Paneles", ""],
	["ayuda", "Ayuda de teclas", KEY_H, "Paneles", ""],
	["mapa", "Mapa del valle", KEY_M, "Paneles", ""],
	["vecinos", "Vecinos", KEY_J, "Paneles", ""],
	["caso", "Caso (detective)", KEY_N, "Paneles", ""],
	["habilidades", "Habilidades", KEY_K, "Paneles", ""],
	["encargos", "Diario de encargos", KEY_L, "Paneles", ""],
	["cronica", "Crónica del pueblo", KEY_O, "Paneles", ""],
	["primera_persona", "Vista en 1.ª persona", KEY_P, "Cámara", ""],
	["camara", "Cámara 2D / 3D", KEY_F9, "Cámara", ""],
	["guardado_rapido", "Guardado rápido", KEY_F5, "Partida", ""],
	["carga_rapida", "Carga rápida", KEY_F12, "Partida", ""],
]

## Teclas que no se pueden usar (fijas del juego o del editor de Godot).
const RESERVADAS: Array = [KEY_ESCAPE, KEY_F11, KEY_CTRL, KEY_ALT, KEY_META, KEY_ENTER, KEY_KP_ENTER]

var mapa: Dictionary = {} # id -> keycode


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in ACCIONES:
		mapa[a[0]] = int(a[2])
	cargar()
	_aplicar_input_map()


func tecla(id: String) -> int:
	return int(mapa.get(id, KEY_NONE))


## ¿Este evento de teclado es la tecla de «id»? Mira la tecla física y la lógica (teclados no QWERTY).
func es(event: InputEvent, id: String) -> bool:
	if not (event is InputEventKey):
		return false
	var k: int = tecla(id)
	if k == KEY_NONE:
		return false
	var ek := event as InputEventKey
	return ek.physical_keycode == k or ek.keycode == k


func nombre_tecla(id: String) -> String:
	return texto_de(tecla(id))


static func texto_de(k: int) -> String:
	match k:
		KEY_SHIFT: return "Mayús"
		KEY_SPACE: return "Espacio"
		KEY_TAB: return "Tab"
		KEY_QUOTELEFT: return "º"
	return OS.get_keycode_string(k)


## Cambia la tecla. Si otra acción la usaba, se intercambian (nunca quedan dos con la misma). Devuelve el id de la
## acción que cambió con ella, o "".
func cambiar(id: String, k: int) -> String:
	if k in RESERVADAS or not mapa.has(id):
		return ""
	var vieja: int = tecla(id)
	var otra: String = ""
	for o in mapa.keys():
		if o != id and int(mapa[o]) == k:
			otra = o
			mapa[o] = vieja
	mapa[id] = k
	_aplicar_input_map()
	guardar()
	cambiadas.emit()
	return otra


func restablecer() -> void:
	for a in ACCIONES:
		mapa[a[0]] = int(a[2])
	_aplicar_input_map()
	guardar()
	cambiadas.emit()


func cargar() -> void:
	var cf := ConfigFile.new()
	if cf.load(RUTA) != OK:
		return
	for a in ACCIONES:
		if cf.has_section_key("teclas", a[0]):
			mapa[a[0]] = int(cf.get_value("teclas", a[0]))


func guardar() -> void:
	var cf := ConfigFile.new()
	for k in mapa.keys():
		cf.set_value("teclas", k, int(mapa[k]))
	cf.save(RUTA)


## Las acciones del InputMap (moverse, correr, acción) usan la tecla elegida; se conservan mandos y ratón.
func _aplicar_input_map() -> void:
	for a in ACCIONES:
		var accion: String = a[4]
		if accion == "" or not InputMap.has_action(accion):
			continue
		for ev in InputMap.action_get_events(accion):
			if ev is InputEventKey:
				InputMap.action_erase_event(accion, ev)
		var nuevo := InputEventKey.new()
		nuevo.physical_keycode = tecla(a[0]) as Key
		InputMap.action_add_event(accion, nuevo)
