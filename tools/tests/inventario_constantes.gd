extends RefCounted
const MapaViejo = preload("res://tools/tests/mapa_viejo.gd") ## posiciones escritas en el mapa original → mundo

## Inventario del mundo, sitios escritos en el código (Claude Code, 2026-11-12; paso 3 de
## docs/PLAN_MUNDO_DESDE_EDITOR.md). Recorre las constantes de los sistemas de vecinos y anota a dónde lleva la
## traducción cada punto (bancos, paseos, oficios de campo, mascotas…). Lo usa tools/tests/inventario_mundo.gd: si al
## mover todas las piezas del editor el punto no se mueve, es que ningún objeto del editor manda sobre él.

const CARPETAS: Array[String] = ["res://scripts/systems", "res://scripts/enemies", "res://scripts/obstacles"]
const MINIMO_POSICION: float = 100.0 ## por debajo son tamaños o separaciones, no sitios del mapa
const CLASE := "Constante"


## Añade a `datos` una entrada por cada punto: "const|archivo|constante|n" → [x, y, clase] ya en el mundo.
static func volcar(datos: Dictionary) -> void:
	for carpeta: String in CARPETAS:
		for archivo: String in DirAccess.get_files_at(carpeta):
			if archivo.ends_with(".gd"):
				_volcar_script(datos, carpeta.path_join(archivo))


static func _volcar_script(datos: Dictionary, ruta: String) -> void:
	var guion: GDScript = load(ruta) as GDScript
	if guion == null:
		return
	var constantes: Dictionary = guion.get_script_constant_map()
	for nombre: String in constantes:
		var puntos: Array[Vector2] = []
		_juntar_puntos(constantes[nombre], puntos)
		for i in range(puntos.size()):
			var en_mundo: Vector2 = MapaViejo.a_mundo(puntos[i])
			datos["const|%s|%s|%d" % [ruta.get_file().get_basename(), nombre, i]] = [en_mundo.x, en_mundo.y, CLASE]


## Saca los puntos de una constante, mire donde mire: sola, en una lista o dentro de un diccionario.
static func _juntar_puntos(valor: Variant, puntos: Array[Vector2]) -> void:
	if valor is Vector2 and maxf(absf((valor as Vector2).x), absf((valor as Vector2).y)) >= MINIMO_POSICION:
		puntos.append(valor)
	elif valor is Rect2:
		_juntar_puntos((valor as Rect2).get_center(), puntos)
	elif valor is Array or valor is PackedVector2Array:
		for hijo: Variant in valor:
			_juntar_puntos(hijo, puntos)
	elif valor is Dictionary:
		for hijo: Variant in (valor as Dictionary).values():
			_juntar_puntos(hijo, puntos)
