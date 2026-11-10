@tool
extends Node2D

## Fondo de guía: cómo está el mapa hoy en el juego (edificios, caminos, árboles, rocas y lago). Solo se ve en el
## editor; no se puede editar desde aquí (todavía). Se rehace con tools/volcar_referencia_mapa.gd.

const JSON_PATH := "res://mapa/referencia_mapa.json"

@export var mostrar_nombres: bool = true:
	set(v):
		mostrar_nombres = v
		queue_redraw()
@export var mostrar_arboles: bool = true:
	set(v):
		mostrar_arboles = v
		queue_redraw()

var _ref: Dictionary = {}


func _cargar() -> Dictionary:
	if _ref.is_empty() and FileAccess.file_exists(JSON_PATH):
		var j = JSON.parse_string(FileAccess.get_file_as_string(JSON_PATH))
		if j is Dictionary:
			_ref = j
	return _ref


func edificios() -> Array:
	var out: Array = []
	for e in _cargar().get("edificios", []):
		var r: Array = e["r"]
		out.append({"id": e["id"], "nombre": e["nombre"], "rect": Rect2(r[0], r[1], r[2], r[3])})
	return out


func _draw() -> void:
	var d := _cargar()
	# Suelo del mundo (la zona que tiene terreno 3D)
	draw_rect(Rect2(Vector2(-3450, -1850), Vector2(6500, 5100)), Color(0.33, 0.42, 0.26), true)
	for c in d.get("caminos", []):
		var poly := PackedVector2Array()
		for p in c:
			poly.append(Vector2(p[0], p[1]))
		draw_colored_polygon(poly, Color(0.62, 0.53, 0.38, 0.9))
	var lago := PackedVector2Array()
	for p in d.get("lago", []):
		lago.append(Vector2(p[0], p[1]))
	if lago.size() >= 3:
		draw_colored_polygon(lago, Color(0.20, 0.50, 0.80, 0.8))
	if mostrar_arboles:
		for p in d.get("arboles", []):
			draw_circle(Vector2(p[0], p[1]), 9.0, Color(0.12, 0.30, 0.12))
		for p in d.get("rocas", []):
			draw_circle(Vector2(p[0], p[1]), 6.0, Color(0.55, 0.55, 0.55))
	var font := ThemeDB.fallback_font
	for e in edificios():
		var r: Rect2 = e["rect"]
		draw_rect(r, Color(0.55, 0.30, 0.22, 0.95), true)
		draw_rect(r, Color(0.15, 0.08, 0.05), false, 1.5)
		if mostrar_nombres and str(e["nombre"]) != "":
			draw_string(font, r.position + Vector2(3, 14), str(e["nombre"]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 4.0, 12, Color.WHITE)
