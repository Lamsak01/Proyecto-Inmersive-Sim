extends SceneTree

## Prueba del pincel del mapa sin editor (Claude Code, 2026-11-10), ~20 s:
##   timeout 120 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/pincel_mapa.gd
## Pinta pinos en un prado, intenta pintar sobre el río y la posada, borra con la goma y siembra copias de lo seleccionado.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
## Se cargan al arrancar (no con preload): dependen de scripts que usan los autoloads, que aún no existen al compilar.
var Nucleo
var Mezclas

var fallos: int = 0

func _ok(c: bool, txt: String) -> void:
	print(("PINCEL ✅ " if c else "PINCEL ❌ ") + txt)
	if not c:
		fallos += 1


func _initialize() -> void:
	for _i in range(3): # los autoloads (WorldClock…) aún no existen en el primer instante y RioLago no compilaría
		await process_frame
	Nucleo = load("res://mapa/pincel_nucleo.gd")
	Mezclas = load("res://mapa/pincel_mezclas.gd")
	var mundo: Node3D = load("res://mapa/Mundo3D.tscn").instantiate()
	root.add_child(mundo)
	await process_frame
	var arboles: Node = mundo.get_node("Vegetacion/Arboles")
	var antes: int = arboles.get_child_count()
	var nu = Nucleo.new()
	nu.sembrar(7)
	nu.raiz = mundo
	nu.mezcla = Mezclas.MEZCLAS[0]
	nu.radio = 150.0
	nu.densidad = 1.0
	nu.empezar()
	var t0 := Time.get_ticks_msec()
	nu.pintar(Vector2(1600, -900))
	nu.pintar(Vector2(1700, -900))
	var n_pinos: int = nu.nuevos.size()
	_ok(n_pinos >= 15, "pinos pintados en un prado: %d (%d ms)" % [n_pinos, Time.get_ticks_msec() - t0])
	_ok(arboles.get_child_count() == antes + n_pinos, "están en Vegetacion/Arboles con dueño: %s" % str(nu.nuevos[0].owner == mundo))
	var min_d := INF
	for i in range(nu.nuevos.size()):
		for j in range(i + 1, nu.nuevos.size()):
			min_d = minf(min_d, nu.nuevos[i].global_position.distance_to(nu.nuevos[j].global_position) / Mapa3D.ESCALA)
	_ok(min_d > 15.0, "separados entre sí (mínimo ~%d)" % int(min_d))
	# Río y edificio
	nu.empezar()
	var FS = load("res://scripts/fisica/RioLago.gd")
	nu.radio = 20.0
	var en_agua := 0
	for y in range(-300, 300, 30):
		nu.pintar(Vector2(FS.river_center_x(float(y)), float(y)))
	for n in nu.nuevos:
		var p := Mapa3D.a_mapa(n.global_position)
		if FS.is_point_in_river_water(p, 0.0):
			en_agua += 1
	_ok(en_agua == 0, "nada dentro del río (%d intentos sembraron %d en la orilla)" % [20, nu.nuevos.size()])
	nu.empezar()
	nu.radio = 40.0
	# Centro real de la posada El Jabalí, donde esté (el editor la puede mover)
	nu.pintar(Mapa3D.a_mapa((mundo.get_node("Edificios/building_tavern") as Node3D).global_position))
	_ok(nu.nuevos.is_empty(), "nada dentro de la posada (%d)" % nu.nuevos.size())
	# Goma
	nu.empezar()
	nu.radio = 150.0
	nu.borrar(Vector2(1600, -900))
	nu.borrar(Vector2(1700, -900))
	_ok(nu.borrados.size() >= n_pinos, "la goma quita los pinos pintados: %d" % nu.borrados.size())
	# Lo seleccionado: copias de una roca
	nu.empezar()
	var roca: Node3D = mundo.get_node("Vegetacion/Rocas").get_child(0)
	nu.mezcla = {}
	nu.plantillas.assign([roca])
	nu.radio = 100.0
	nu.pintar(Vector2(1600, -600))
	_ok(nu.nuevos.size() >= 3 and nu.nuevos[0].get_parent() == roca.get_parent() and str(nu.nuevos[0].get("modelo")) == str(roca.get("modelo")),
		"copias de lo seleccionado: %d en su misma carpeta" % nu.nuevos.size())
	# Guardar y volver a leer
	var ps := PackedScene.new()
	ps.pack(mundo)
	ResourceSaver.save(ps, "user://pincel_prueba.tscn")
	var otra: Node = load("user://pincel_prueba.tscn").instantiate()
	_ok(otra.get_node("Vegetacion/Rocas").get_child_count() == mundo.get_node("Vegetacion/Rocas").get_child_count(), "lo pintado se guarda en la escena")
	otra.free()
	print("PINCEL FIN fallos=%d" % fallos)
	quit(0)
