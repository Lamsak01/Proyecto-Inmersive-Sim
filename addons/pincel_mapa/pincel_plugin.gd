@tool
extends EditorPlugin

## PINCEL DEL MAPA (Claude Code, 2026-11-10) para mapa/Mundo3D.tscn.
## Panel «Pincel» (a la derecha): eliges una mezcla (bosque de pinos, rocas, hierba…) o «lo seleccionado», el tamaño y lo
## apretado, y arrastras con el botón izquierdo sobre el suelo en la vista 3D. Cada cosa sembrada es una pieza normal de la
## escena: luego se mueve, gira o borra una a una. «Borrar» quita lo de la carpeta de la mezcla que toque el pincel.
## No siembra en el río, el lago, los edificios ni los caminos. Ctrl+Z deshace cada trazo entero.
## Guía para el usuario: docs/PINCEL_MAPA_GUIA.md.

const Mezclas = preload("res://mapa/pincel_mezclas.gd")
const WB = preload("res://scripts/visuals/WorldStageBase3D.gd")
const FS = preload("res://scripts/obstacles/FishingSpot.gd")
const PIEZA = preload("res://mapa/pieza.gd")
const Nucleo = preload("res://mapa/pincel_nucleo.gd")

var _panel: VBoxContainer
var _activo: CheckButton
var _lista: OptionButton
var _modo: OptionButton
var _radio: HSlider
var _densidad: HSlider
var _lbl_radio: Label
var _lbl_densidad: Label
var _lbl_info: Label
var _lbl_sel: Label

var _plantillas: Array[Node3D] = [] # «lo seleccionado»
var _anillo: MeshInstance3D = null
var _pintando: bool = false
var _ultimo: Vector2 = Vector2.INF
var _nucleo = null
var _sin_p: float = sin(deg_to_rad(WB.PITCH_DEG))
var _cos_p: float = cos(deg_to_rad(WB.PITCH_DEG))


func _enter_tree() -> void:
	_nucleo = Nucleo.new()
	_crear_panel()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _panel)
	set_input_event_forwarding_always_enabled()


func _exit_tree() -> void:
	_quitar_anillo()
	if _panel != null:
		remove_control_from_docks(_panel)
		_panel.queue_free()


func _handles(_object: Object) -> bool:
	return false # recibe el ratón siempre (set_input_event_forwarding_always_enabled)


# ---------------------------------------------------------------- panel

func _crear_panel() -> void:
	_panel = VBoxContainer.new()
	_panel.name = "Pincel"
	var titulo := Label.new()
	titulo.text = "Pincel del mapa"
	titulo.add_theme_font_size_override("font_size", 18)
	_panel.add_child(titulo)
	var ayuda := Label.new()
	ayuda.text = "Abre Mundo3D, marca «Pincel encendido» y arrastra con el botón izquierdo sobre el suelo."
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(ayuda)
	_activo = CheckButton.new()
	_activo.text = "Pincel encendido"
	_activo.toggled.connect(func(on: bool):
		if not on:
			_quitar_anillo()
		_actualizar_info())
	_panel.add_child(_activo)

	_panel.add_child(_etiqueta("Qué pintar"))
	_lista = OptionButton.new()
	for i in range(Mezclas.MEZCLAS.size()):
		_lista.add_item(str(Mezclas.MEZCLAS[i]["nombre"]), i)
	_lista.add_item("Lo seleccionado (tus modelos)", 1000)
	_lista.item_selected.connect(func(_i): _actualizar_info())
	_panel.add_child(_lista)
	var b_sel := Button.new()
	b_sel.text = "Usar lo seleccionado"
	b_sel.tooltip_text = "Elige en la escena uno o varios objetos (por ejemplo, un modelo tuyo de mis_recursos) y pulsa aquí: el pincel sembrará copias de ellos."
	b_sel.pressed.connect(_usar_seleccion)
	_panel.add_child(b_sel)
	_lbl_sel = Label.new()
	_lbl_sel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_lbl_sel)

	_panel.add_child(_etiqueta("Herramienta"))
	_modo = OptionButton.new()
	_modo.add_item("Pintar", 0)
	_modo.add_item("Borrar (goma)", 1)
	_panel.add_child(_modo)

	_lbl_radio = _etiqueta("")
	_panel.add_child(_lbl_radio)
	_radio = HSlider.new()
	_radio.min_value = 20.0
	_radio.max_value = 400.0
	_radio.step = 10.0
	_radio.value = 120.0
	_radio.value_changed.connect(func(_v): _actualizar_info())
	_panel.add_child(_radio)

	_lbl_densidad = _etiqueta("")
	_panel.add_child(_lbl_densidad)
	_densidad = HSlider.new()
	_densidad.min_value = 0.1
	_densidad.max_value = 1.0
	_densidad.step = 0.05
	_densidad.value = 0.5
	_densidad.value_changed.connect(func(_v): _actualizar_info())
	_panel.add_child(_densidad)

	_lbl_info = Label.new()
	_lbl_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_lbl_info)
	_actualizar_info()


func _etiqueta(t: String) -> Label:
	var l := Label.new()
	l.text = t
	return l


func _actualizar_info() -> void:
	if _lbl_radio == null:
		return
	_lbl_radio.text = "Tamaño del pincel: %d (una casa mide unos 120)" % int(_radio.value)
	_lbl_densidad.text = "Apretado: %d %%" % int(_densidad.value * 100.0)
	_lbl_sel.text = ("Seleccionados: %d objeto(s)" % _plantillas.size()) if not _plantillas.is_empty() else ""
	var m := _mundo()
	if m == null:
		_lbl_info.text = "Abre la escena mapa/Mundo3D.tscn para usar el pincel."
	else:
		var veg := m.get_node_or_null("Vegetacion")
		var n: int = _contar(veg) if veg != null else 0
		_lbl_info.text = "Piezas de vegetación en el mapa: %d. Ctrl+Z deshace el último trazo." % n
		if n > 4000:
			_lbl_info.text += " ¡Son muchas! El juego puede ir más lento."


func _contar(n: Node) -> int:
	var c: int = 0
	for h in n.get_children():
		c += 1 if h.get_script() == PIEZA else _contar(h)
	return c


func _usar_seleccion() -> void:
	_plantillas.clear()
	for n in get_editor_interface().get_selection().get_selected_nodes():
		if n is Node3D and _mundo() != null and _mundo().is_ancestor_of(n):
			_plantillas.append(n)
	_lista.select(_lista.get_item_count() - 1)
	_actualizar_info()


# ---------------------------------------------------------------- ratón

func _forward_3d_gui_input(cam: Camera3D, event: InputEvent) -> int:
	if not _activo.button_pressed or _mundo() == null:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventMouse:
		var hit = _tocar_suelo(cam, (event as InputEventMouse).position)
		if hit == null:
			_mover_anillo(null)
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		_mover_anillo(hit)
		var p2: Vector2 = _a_2d(hit)
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_empezar_trazo()
				_aplicar(p2)
			else:
				_terminar_trazo()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		if event is InputEventMouseMotion and _pintando:
			if _ultimo == Vector2.INF or _ultimo.distance_to(p2) >= _radio.value * 0.35:
				_aplicar(p2)
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	return EditorPlugin.AFTER_GUI_INPUT_PASS


## Punto del suelo (con el mismo relieve que el juego) bajo el ratón, en 3D. null si no toca el suelo.
func _tocar_suelo(cam: Camera3D, pos: Vector2):
	var o: Vector3 = cam.project_ray_origin(pos)
	var d: Vector3 = cam.project_ray_normal(pos)
	var t: float = 0.0
	var paso: float = 0.5
	var prev_t: float = 0.0
	var prev_sobre: bool = _sobre_suelo(o)
	if not prev_sobre:
		return null
	while t < 600.0:
		t += paso
		var p: Vector3 = o + d * t
		if not _sobre_suelo(p):
			var a: float = prev_t
			var b: float = t
			for _i in range(12):
				var m: float = (a + b) * 0.5
				if _sobre_suelo(o + d * m):
					a = m
				else:
					b = m
			var q: Vector3 = o + d * b
			var q2: Vector2 = _a_2d(q)
			return _a_3d(q2, WB.terrain_height_px(q2))
		prev_t = t
		paso = minf(2.0, paso * 1.15)
	return null


func _sobre_suelo(p: Vector3) -> bool:
	var p2: Vector2 = _a_2d(p)
	return p.y > (WB.terrain_height_px(p2) * WB.WORLD_SCALE) / _cos_p


func _a_2d(p: Vector3) -> Vector2:
	return Vector2(p.x / WB.WORLD_SCALE, p.z * _sin_p / WB.WORLD_SCALE)


func _a_3d(p: Vector2, h: float) -> Vector3:
	return Vector3(p.x * WB.WORLD_SCALE, (h * WB.WORLD_SCALE) / _cos_p, (p.y * WB.WORLD_SCALE) / _sin_p)


# ---------------------------------------------------------------- trazo

func _empezar_trazo() -> void:
	_pintando = true
	_ultimo = Vector2.INF
	_nucleo.raiz = _mundo()
	_nucleo.mezcla = _mezcla()
	_nucleo.plantillas = _plantillas
	_nucleo.radio = _radio.value
	_nucleo.densidad = _densidad.value
	_nucleo.empezar()


func _terminar_trazo() -> void:
	if not _pintando:
		return
	_pintando = false
	var ur := get_undo_redo()
	var raiz := _mundo()
	var nuevos: Array = _nucleo.nuevos.duplicate()
	var borrados: Array = _nucleo.borrados.duplicate()
	if not nuevos.is_empty():
		ur.create_action("Pincel: pintar %d" % nuevos.size(), UndoRedo.MERGE_DISABLE, raiz)
		for n in nuevos:
			var padre: Node = n.get_parent()
			ur.add_do_method(padre, "add_child", n, true)
			ur.add_do_method(self, "_poner_dueno", n, raiz)
			ur.add_do_reference(n)
			ur.add_undo_method(padre, "remove_child", n)
		ur.commit_action(false) # ya están puestos
	if not borrados.is_empty():
		ur.create_action("Pincel: borrar %d" % borrados.size(), UndoRedo.MERGE_DISABLE, raiz)
		for b in borrados:
			ur.add_do_method(b[1], "remove_child", b[0])
			ur.add_undo_method(b[1], "add_child", b[0], true)
			ur.add_undo_method(b[1], "move_child", b[0], b[2])
			ur.add_undo_method(self, "_poner_dueno", b[0], raiz)
			ur.add_undo_reference(b[0])
		ur.commit_action(false)
	_nucleo.nuevos.clear()
	_nucleo.borrados.clear()
	_actualizar_info()
	if _nucleo.aviso != "":
		_lbl_info.text = _nucleo.aviso


func _poner_dueno(n: Node, raiz: Node) -> void:
	Nucleo.poner_dueno(n, raiz)


func _aplicar(p: Vector2) -> void:
	_ultimo = p
	if _modo.selected == 1:
		_nucleo.borrar(p)
	else:
		_nucleo.pintar(p)


func _mezcla() -> Dictionary:
	var id: int = _lista.get_selected_id()
	if id == 1000:
		return {}
	return Mezclas.MEZCLAS[clampi(id, 0, Mezclas.MEZCLAS.size() - 1)]


# ---------------------------------------------------------------- utilidades

func _mundo() -> Node3D:
	var r := get_editor_interface().get_edited_scene_root()
	if r is Node3D and r.get_node_or_null("Vegetacion") != null:
		return r as Node3D
	return null


func _mover_anillo(p) -> void:
	var raiz := _mundo()
	if raiz == null:
		return
	if _anillo == null or not is_instance_valid(_anillo):
		_anillo = MeshInstance3D.new()
		_anillo.name = "_AnilloPincel"
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.85, 0.2)
		mat.no_depth_test = true
		_anillo.material_override = mat
		raiz.add_child(_anillo) # sin «owner»: no se guarda
	if p == null:
		_anillo.visible = false
		return
	_anillo.visible = true
	var c2: Vector2 = _a_2d(p)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var col := Color(1.0, 0.3, 0.3) if _modo.selected == 1 else Color(1.0, 0.85, 0.2)
	(_anillo.material_override as StandardMaterial3D).albedo_color = col
	for i in range(49):
		var a: float = TAU * float(i) / 48.0
		var q: Vector2 = c2 + Vector2(cos(a), sin(a)) * _radio.value
		im.surface_add_vertex(_a_3d(q, WB.terrain_height_px(q) + 2.0))
	im.surface_end()
	_anillo.mesh = im


func _quitar_anillo() -> void:
	if _anillo != null and is_instance_valid(_anillo):
		_anillo.queue_free()
	_anillo = null
