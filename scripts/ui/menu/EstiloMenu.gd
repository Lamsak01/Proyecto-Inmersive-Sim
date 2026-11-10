class_name EstiloMenu
extends RefCounted

## Aspecto común del menú principal, la pausa y sus paneles (Claude Code, 2026-11-10).
## Tonos de madera y pergamino, letra grande y legible.

const FONDO := Color(0.08, 0.07, 0.06, 0.94)
const MARCO := Color(0.55, 0.42, 0.25)
const TEXTO := Color(0.93, 0.88, 0.78)
const TEXTO_SUAVE := Color(0.70, 0.65, 0.56)
const ACENTO := Color(0.95, 0.75, 0.38)

static var _tema: Theme = null


static func caja(color: Color, borde: Color, grosor: int = 2, radio: int = 6, margen: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = borde
	s.set_border_width_all(grosor)
	s.set_corner_radius_all(radio)
	s.set_content_margin_all(margen)
	return s


static func tema() -> Theme:
	if _tema != null:
		return _tema
	var t := Theme.new()
	t.default_font_size = 20
	t.set_color("font_color", "Label", TEXTO)
	for tipo in ["Button", "OptionButton", "CheckButton"]:
		t.set_color("font_color", tipo, TEXTO)
		t.set_color("font_hover_color", tipo, ACENTO)
		t.set_color("font_focus_color", tipo, ACENTO)
		t.set_color("font_pressed_color", tipo, ACENTO)
		t.set_color("font_disabled_color", tipo, Color(0.45, 0.42, 0.38))
	t.set_stylebox("normal", "Button", caja(Color(0.17, 0.13, 0.09), Color(0.36, 0.27, 0.16), 2, 5, 10))
	t.set_stylebox("hover", "Button", caja(Color(0.25, 0.18, 0.11), MARCO, 2, 5, 10))
	t.set_stylebox("focus", "Button", caja(Color(0, 0, 0, 0), ACENTO, 2, 5, 10))
	t.set_stylebox("pressed", "Button", caja(Color(0.32, 0.23, 0.13), ACENTO, 2, 5, 10))
	t.set_stylebox("disabled", "Button", caja(Color(0.12, 0.10, 0.08), Color(0.22, 0.18, 0.13), 2, 5, 10))
	for k in ["normal", "hover", "focus", "pressed", "disabled"]:
		t.set_stylebox(k, "OptionButton", t.get_stylebox(k, "Button"))
	t.set_stylebox("panel", "PanelContainer", caja(FONDO, MARCO, 2, 8, 20))
	t.set_stylebox("panel", "TabContainer", caja(Color(0.11, 0.09, 0.07, 0.9), Color(0.30, 0.23, 0.14), 1, 4, 14))
	t.set_stylebox("tab_selected", "TabContainer", caja(Color(0.25, 0.18, 0.11), MARCO, 2, 4, 8))
	t.set_stylebox("tab_unselected", "TabContainer", caja(Color(0.13, 0.10, 0.08), Color(0.25, 0.19, 0.12), 1, 4, 8))
	t.set_stylebox("tab_hovered", "TabContainer", caja(Color(0.20, 0.15, 0.10), MARCO, 1, 4, 8))
	t.set_color("font_selected_color", "TabContainer", ACENTO)
	t.set_color("font_unselected_color", "TabContainer", TEXTO_SUAVE)
	t.set_color("font_hovered_color", "TabContainer", TEXTO)
	t.set_font_size("font_size", "TabContainer", 20)
	t.set_stylebox("slider", "HSlider", caja(Color(0.2, 0.16, 0.11), Color(0.36, 0.27, 0.16), 1, 3, 3))
	t.set_stylebox("panel", "PopupMenu", caja(Color(0.12, 0.09, 0.07), MARCO, 2, 4, 8))
	t.set_color("font_color", "PopupMenu", TEXTO)
	t.set_color("font_hover_color", "PopupMenu", ACENTO)
	t.set_font_size("font_size", "PopupMenu", 20)
	_tema = t
	return t


static func titulo(texto: String, tam: int = 34) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", ACENTO)
	return l


static func etiqueta(texto: String, suave: bool = false, tam: int = 20) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	if suave:
		l.add_theme_color_override("font_color", TEXTO_SUAVE)
	return l


static func boton(texto: String, ancho: float = 0.0) -> Button:
	var b := Button.new()
	b.text = texto
	if ancho > 0.0:
		b.custom_minimum_size = Vector2(ancho, 46)
	return b


## Panel centrado en pantalla con un fondo oscuro detrás que tapa lo demás.
static func velo(padre: Control) -> ColorRect:
	var v := ColorRect.new()
	v.color = Color(0, 0, 0, 0.6)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(v)
	return v
