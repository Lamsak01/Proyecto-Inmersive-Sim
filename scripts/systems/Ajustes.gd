extends Node

## Ajustes del jugador (Claude Code, 2026-11-10; menú principal pedido por el usuario).
## Se guardan en user://ajustes.cfg y se aplican al arrancar y cada vez que cambian (señal «cambiados»).
## Los usan: el menú de ajustes (scripts/ui/PanelAjustes.gd), la cámara en 1.ª persona y el escenario 3D (WorldStage3D).

signal cambiados

const RUTA: String = "user://ajustes.cfg"

## Valores por defecto. Claves en español, sin acentos.
const POR_DEFECTO: Dictionary = {
	"pantalla_completa": true,
	"vsync": true,
	"fps_max": 0,           # 0 = sin límite
	"sombras": 2,           # 0 = sin sombras, 1 = bajas, 2 = altas
	"nitidez": 1.0,         # escala de la imagen 3D: 1.0 = nítida, 0.75 = equilibrada, 0.5 = rápida
	"suavizado": 0,         # 0 = no, 1 = 2×, 2 = 4× (suaviza los bordes, cuesta rendimiento)
	"sensibilidad": 1.0,    # multiplicador del ratón en 1.ª persona
	"campo_vision": 70.0,   # grados, 1.ª persona
	"invertir_y": false,
	"vol_general": 1.0,     # 0..1
	"vol_musica": 0.8,
	"vol_efectos": 1.0,
}

var valores: Dictionary = POR_DEFECTO.duplicate()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cargar()
	aplicar()


func get_valor(clave: String):
	return valores.get(clave, POR_DEFECTO.get(clave))


func poner(clave: String, valor) -> void:
	valores[clave] = valor
	aplicar()
	guardar()


func restablecer() -> void:
	valores = POR_DEFECTO.duplicate()
	aplicar()
	guardar()


func cargar() -> void:
	var cf := ConfigFile.new()
	if cf.load(RUTA) != OK:
		return
	for k in POR_DEFECTO.keys():
		if cf.has_section_key("ajustes", k):
			valores[k] = cf.get_value("ajustes", k)


func guardar() -> void:
	var cf := ConfigFile.new()
	for k in valores.keys():
		cf.set_value("ajustes", k, valores[k])
	cf.save(RUTA)


func aplicar() -> void:
	var headless: bool = DisplayServer.get_name() == "headless"
	if not headless:
		var win := get_window()
		if win != null:
			var quiere_completa: bool = bool(get_valor("pantalla_completa"))
			var es_completa: bool = win.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]
			if quiere_completa != es_completa:
				win.mode = Window.MODE_FULLSCREEN if quiere_completa else Window.MODE_WINDOWED
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(get_valor("vsync")) else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = int(get_valor("fps_max"))
	_aplicar_sonido()
	cambiados.emit()


## Volumen: bus Master (general), Music (música) y SFX (efectos). Se crean si no existen.
func _aplicar_sonido() -> void:
	_poner_volumen("Master", float(get_valor("vol_general")))
	_poner_volumen("Music", float(get_valor("vol_musica")))
	_poner_volumen("SFX", float(get_valor("vol_efectos")))


func _poner_volumen(bus: String, v: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, bus)
		AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_mute(idx, v <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.001)))


## F11 cambia ventana / pantalla completa en cualquier pantalla (menú o partida) y se recuerda.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		poner("pantalla_completa", not bool(get_valor("pantalla_completa")))
		get_viewport().set_input_as_handled()


## El jugador pulsó F11 o cambió la ventana por su cuenta: recordar lo nuevo.
func recordar_pantalla() -> void:
	var win := get_window()
	if win == null:
		return
	valores["pantalla_completa"] = win.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]
	guardar()
