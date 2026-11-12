@tool
extends EditorPlugin
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## PINCEL DEL MAPA (Claude Code, 2026-11-10) para mapa/Mundo3D.tscn.
## Panel «Pincel» (a la derecha): eliges una mezcla (bosque de pinos, rocas, hierba…) o «lo seleccionado», el tamaño y lo
## apretado, y arrastras con el botón izquierdo sobre el suelo en la vista 3D. Cada cosa sembrada es una pieza normal de la
## escena: luego se mueve, gira o borra una a una. «Borrar» quita lo de la carpeta de la mezcla que toque el pincel.
## No siembra en el río, el lago, los edificios ni los caminos. Ctrl+Z deshace cada trazo entero.
## Guía para el usuario: docs/PINCEL_MAPA_GUIA.md.

const Mezclas = preload("res://mapa/pincel_mezclas.gd")
const WB = preload("res://scripts/visuals/WorldStageBase3D.gd")
const FS = preload("res://scripts/fisica/RioLago.gd")
const PIEZA = preload("res://mapa/pieza.gd")
const Nucleo = preload("res://mapa/pincel_nucleo.gd")

var _panel: HBoxContainer
var _c1: VBoxContainer
var _c2: VBoxContainer
var _c3: VBoxContainer
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


func _enter_tree() -> void:
	_nucleo = Nucleo.new()
	_crear_panel()
	add_control_to_bottom_panel(_panel, "Pincel del mapa")
	scene_changed.connect(_al_cambiar_escena)
	set_input_event_forwarding_always_enabled()
	if OS.get_environment("PINCEL_PRUEBA") == "1":
		_prueba.call_deferred()


func _exit_tree() -> void:
	_quitar_anillo()
	if _panel != null:
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()


## Al abrir Mundo3D se enseña el panel del pincel abajo (pestaña «Pincel del mapa», junto a «Output»).
func _al_cambiar_escena(_raiz: Node) -> void:
	if _mundo() != null:
		make_bottom_panel_item_visible(_panel)
	elif _activo != null:
		_activo.button_pressed = false
	_actualizar_info()


func _handles(_object: Object) -> bool:
	return false # recibe el ratón siempre (set_input_event_forwarding_always_enabled)


# ---------------------------------------------------------------- panel

func _crear_panel() -> void:
	_panel = HBoxContainer.new()
	_panel.name = "Pincel"
	_panel.custom_minimum_size = Vector2(0, 220)
	_panel.add_theme_constant_override("separation", 24)
	_c1 = VBoxContainer.new()
	_c2 = VBoxContainer.new()
	_c3 = VBoxContainer.new()
	for c in [_c1, _c2, _c3]:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_panel.add_child(c)
	var titulo := Label.new()
	titulo.text = "Pincel del mapa"
	titulo.add_theme_font_size_override("font_size", 18)
	_c1.add_child(titulo)
	var ayuda := Label.new()
	ayuda.text = "Abre Mundo3D, marca «Pincel encendido» y arrastra con el botón izquierdo sobre el suelo."
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_c1.add_child(ayuda)
	_activo = CheckButton.new()
	_activo.text = "Pincel encendido"
	_activo.toggled.connect(func(on: bool):
		if not on:
			_quitar_anillo()
		_actualizar_info())
	_c1.add_child(_activo)

	_c2.add_child(_etiqueta("Qué pintar"))
	_lista = OptionButton.new()
	for i in range(Mezclas.MEZCLAS.size()):
		_lista.add_item(str(Mezclas.MEZCLAS[i]["nombre"]), i)
	_lista.add_item("Lo seleccionado (tus modelos)", 1000)
	_lista.item_selected.connect(func(_i): _actualizar_info())
	_c2.add_child(_lista)
	var b_sel := Button.new()
	b_sel.text = "Usar lo seleccionado"
	b_sel.tooltip_text = "Elige en la escena uno o varios objetos (por ejemplo, un modelo tuyo de mis_recursos) y pulsa aquí: el pincel sembrará copias de ellos."
	b_sel.pressed.connect(_usar_seleccion)
	_c2.add_child(b_sel)
	_lbl_sel = Label.new()
	_lbl_sel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_c2.add_child(_lbl_sel)

	_c2.add_child(_etiqueta("Herramienta"))
	_modo = OptionButton.new()
	_modo.add_item("Pintar", 0)
	_modo.add_item("Borrar (goma)", 1)
	_c2.add_child(_modo)

	_lbl_radio = _etiqueta("")
	_c3.add_child(_lbl_radio)
	_radio = HSlider.new()
	_radio.min_value = 20.0
	_radio.max_value = 400.0
	_radio.step = 10.0
	_radio.value = 120.0
	_radio.value_changed.connect(func(_v): _actualizar_info())
	_c3.add_child(_radio)

	_lbl_densidad = _etiqueta("")
	_c3.add_child(_lbl_densidad)
	_densidad = HSlider.new()
	_densidad.min_value = 0.1
	_densidad.max_value = 1.0
	_densidad.step = 0.05
	_densidad.value = 0.5
	_densidad.value_changed.connect(func(_v): _actualizar_info())
	_c3.add_child(_densidad)

	_lbl_info = Label.new()
	_lbl_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_c1.add_child(_lbl_info)
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
	return p.y > Mapa3D.alto_a_3d(WB.terrain_height_px(p2))


func _a_2d(p: Vector3) -> Vector2:
	return Mapa3D.a_mapa(p)


func _a_3d(p: Vector2, h: float) -> Vector3:
	return Mapa3D.a_3d(p, h)


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


# ---------------------------------------------------------------- prueba dentro del editor
## Solo con la variable PINCEL_PRUEBA=1 (Claude Code): abre Mundo3D, pinta con el ratón de verdad, deshace, saca una
## foto y cierra el editor SIN guardar. Resultado en el archivo que diga PINCEL_SALIDA.
func _prueba() -> void:
	var out: Array[String] = []
	var ei := get_editor_interface()
	for _i in range(30):
		await get_tree().process_frame
	ei.open_scene_from_path("res://mapa/Mundo3D.tscn")
	var t0 := Time.get_ticks_msec()
	while _mundo() == null and Time.get_ticks_msec() - t0 < 90000:
		await get_tree().process_frame
	for _i in range(60):
		await get_tree().process_frame
	ei.set_main_screen_editor("3D")
	for _i in range(60):
		await get_tree().process_frame
	var raiz := _mundo()
	out.append("mundo_abierto=%s (%d ms)" % [str(raiz != null), Time.get_ticks_msec() - t0])
	if raiz == null:
		var r0 := ei.get_edited_scene_root()
		out.append("escena_editada=%s" % (str(r0.name) if r0 != null else "ninguna"))
		var f0 := FileAccess.open(OS.get_environment("PINCEL_SALIDA"), FileAccess.WRITE)
		f0.store_string("\n".join(out))
		f0.close()
		get_tree().quit()
		return
	var vp: SubViewport = ei.get_editor_viewport_3d(0)
	var cam: Camera3D = vp.get_camera_3d()
	# Busca un punto de la pantalla que caiga en suelo donde se pueda sembrar
	_activo.button_pressed = true
	_lista.select(4) # Hierba y plantas
	_radio.value = 60.0
	_densidad.value = 1.0
	var nucleo_prueba = Nucleo.new()
	nucleo_prueba.raiz = raiz
	var punto := Vector2(-1, -1)
	var sz: Vector2 = Vector2(vp.size)
	for fy in [0.5, 0.6, 0.4, 0.7, 0.3]:
		for fx in [0.5, 0.4, 0.6, 0.3, 0.7]:
			var sp := Vector2(sz.x * fx, sz.y * fy)
			var hit = _tocar_suelo(cam, sp)
			if hit != null and not nucleo_prueba._prohibido(_a_2d(hit)):
				punto = sp
				break
		if punto.x >= 0.0:
			break
	out.append("punto_pantalla=%s camara=%s" % [str(punto), str(cam.global_position)])
	var veg := raiz.get_node("Vegetacion")
	var n0: int = _contar(veg)
	# 1) Llamada directa al manejador del ratón
	_simular(cam, punto, false)
	var n1: int = _contar(veg)
	out.append("directo: %d -> %d" % [n0, n1])
	# 2) Ratón de verdad por el editor (como el usuario)
	var cont: Control = vp.get_parent() as Control
	var base: Vector2 = cont.get_global_rect().position
	_simular(cam, punto + Vector2(140, 0), true, base)
	for _i in range(10):
		await get_tree().process_frame
	var n2: int = _contar(veg)
	out.append("raton_real: %d -> %d" % [n1, n2])
	# Foto con el anillo a la vista
	_mover_anillo(_tocar_suelo(cam, punto + Vector2(140, 0)))
	for _i in range(10):
		await get_tree().process_frame
	var img := ei.get_base_control().get_viewport().get_texture().get_image()
	img.save_png(OS.get_environment("PINCEL_FOTO"))
	# Goma
	_modo.select(1)
	_simular(cam, punto, false)
	var n3: int = _contar(veg)
	out.append("goma: %d -> %d" % [n2, n3])
	_modo.select(0)
	# Deshacer todo (3 trazos)
	var urm := get_undo_redo()
	var hist: UndoRedo = urm.get_history_undo_redo(urm.get_object_history_id(raiz))
	for _i in range(3):
		hist.undo()
	var n4: int = _contar(veg)
	out.append("deshacer: %d -> %d (inicio %d)" % [n3, n4, n0])
	var anc: Node = _panel
	var cadena: Array[String] = []
	while anc != null and cadena.size() < 6:
		cadena.append("%s(%s,%s)" % [anc.get_class(), str(anc.visible) if anc is CanvasItem else "-", str(anc.get_global_rect()) if anc is Control else "-"])
		anc = anc.get_parent()
	out.append("panel: " + " < ".join(cadena))
	out.append("RESULTADO " + ("OK" if n1 > n0 and n2 > n1 and n3 < n2 and n4 == n0 else "FALLO"))
	var f := FileAccess.open(OS.get_environment("PINCEL_SALIDA"), FileAccess.WRITE)
	f.store_string("\n".join(out))
	f.close()
	get_tree().quit()


func _simular(cam: Camera3D, p: Vector2, real: bool, base: Vector2 = Vector2.ZERO) -> void:
	var evs: Array[InputEvent] = []
	var b := InputEventMouseButton.new()
	b.button_index = MOUSE_BUTTON_LEFT
	b.pressed = true
	b.position = p + base
	b.global_position = p + base
	evs.append(b)
	for k in range(1, 6):
		var m := InputEventMouseMotion.new()
		m.position = p + base + Vector2(k * 12.0, k * 6.0)
		m.global_position = m.position
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		evs.append(m)
	var u := InputEventMouseButton.new()
	u.button_index = MOUSE_BUTTON_LEFT
	u.pressed = false
	u.position = p + base + Vector2(60, 30)
	u.global_position = u.position
	evs.append(u)
	for e in evs:
		if real:
			Input.parse_input_event(e)
		else:
			var loc: InputEventMouse = e.duplicate()
			_forward_3d_gui_input(cam, loc)
