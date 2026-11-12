extends SceneTree

## Inventario del mundo (Claude Code, 2026-11-11; paso 0 de docs/PLAN_MUNDO_DESDE_EDITOR.md). Arranca el juego dos veces:
## una tal cual y otra con TODAS las piezas del editor movidas lo mismo (sin guardar la escena). Lo que sale del editor se
## mueve con ellas; lo que se queda quieto sale de números del código; lo que se mueve otra cantidad está mal traducido.
## Uso (con ventana: sin ella el juego no crea los modelos 3D; ~1 min cada una):
##   flatpak run org.godotengine.Godot --path . -s tools/tests/inventario_mundo.gd -- quieto
##   flatpak run org.godotengine.Godot --path . -s tools/tests/inventario_mundo.gd -- movido
##   flatpak run org.godotengine.Godot --headless --path . -s tools/tests/inventario_mundo.gd -- comparar
## «comparar» escribe docs/INVENTARIO_MUNDO.md.

const Informe = preload("res://tools/tests/inventario_informe.gd")
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const ESCENA_EDITOR := "res://mapa/Mundo3D.tscn"
const ESCENA_JUEGO := "uid://dsoiuct8kdsk3"
const SALIDA := "user://inventario_%s.json"
const DESPLAZAMIENTO_PX := Vector2(373.0, 241.0) ## cualquier cantidad que no se confunda con el estirado ×5
const FOTOGRAMAS_ESPERA: int = 150 ## lo que tarda en crearse todo, incluidos árboles talables y vecinos
## Carpetas del editor cuyas piezas están un nivel más abajo (Decorado/Zona/pieza, Vegetacion/Arboles/pieza).
const GRUPOS_CON_CARPETAS: Array[String] = ["Decorado", "Vegetacion"]
const GRUPOS_SUELTOS: Array[String] = ["Edificios", "Solares", "Zonas", "Objetos", "Caminos", "BajoTierra", "Decoracion"]
## Partes del escenario que se mueven solas: cuerpos de vecinos y animales, y la cámara con las manos del jugador.
const PARTES_VIVAS: Array[String] = ["Characters3D", "WorldCamera3D"]
const CAMPOS_VECINO: Array[String] = ["bed_position", "home_table_pos", "work_position"]

## La caché de Godot no retiene la escena movida: si nadie la guarda, se borra y el juego vuelve a leer el archivo.
var _escena_movida: PackedScene = null


func _initialize() -> void:
	var modo: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "quieto"
	if modo == "comparar":
		Informe.escribir(_leer("quieto"), _leer("movido"), DESPLAZAMIENTO_PX)
		quit()
		return
	seed(11)
	load("res://scripts/visuals/WorldStageTerrain3D.gd").juntar_por_zonas = false
	if modo == "movido":
		_mover_escena_editor()
	root.add_child(load(ESCENA_JUEGO).instantiate())
	for _i in range(FOTOGRAMAS_ESPERA):
		await physics_frame
	var datos: Dictionary = {}
	_volcar_3d(datos)
	_volcar_2d(datos)
	_volcar_vecinos(datos)
	_volcar_edificios(datos)
	var f := FileAccess.open(SALIDA % modo, FileAccess.WRITE)
	f.store_string(JSON.stringify(datos))
	f.close()
	print("INVENTARIO %s: %d cosas anotadas" % [modo, datos.size()])
	quit()


## Mueve en memoria cada pieza del editor y hace que todo el juego lea esa versión en vez del archivo.
func _mover_escena_editor() -> void:
	var escena: Node = (load(ESCENA_EDITOR) as PackedScene).instantiate()
	var d3: Vector3 = Mapa3D.a_3d(DESPLAZAMIENTO_PX, 0.0) - Mapa3D.a_3d(Vector2.ZERO, 0.0)
	d3.y = 0.0
	for grupo: String in GRUPOS_SUELTOS + GRUPOS_CON_CARPETAS:
		var g: Node = escena.get_node_or_null(grupo)
		if g == null:
			continue
		for hijo: Node in g.get_children():
			var piezas: Array[Node] = [hijo]
			if grupo in GRUPOS_CON_CARPETAS:
				piezas = hijo.get_children()
			for p: Node in piezas:
				if p is Node3D:
					(p as Node3D).position += d3
	_escena_movida = PackedScene.new()
	_escena_movida.pack(escena)
	_escena_movida.take_over_path(ESCENA_EDITOR)
	escena.free()


func _volcar_3d(datos: Dictionary) -> void:
	var escenario: Node = root.find_child("WorldStage3D", true, false)
	if escenario == null:
		push_error("INVENTARIO: no hay escenario 3D")
		return
	for n: Node in escenario.find_children("*", "Node3D", true, false):
		if not (n is VisualInstance3D or n is CollisionShape3D) or _es_de_algo_vivo(n):
			continue
		if n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			_volcar_lote(datos, n as MultiMeshInstance3D, str(escenario.get_path_to(n)))
			continue
		var p: Vector3 = _sitio_dibujado(n as Node3D)
		var en_mapa: Vector2 = Mapa3D.a_mapa(p)
		datos["3d|" + str(escenario.get_path_to(n))] = [en_mapa.x, en_mapa.y, n.get_class()]


## Suelos, agua y caminos son mallas con los puntos ya en el mundo y el nodo en el origen: su sitio es el centro de la malla.
func _sitio_dibujado(n: Node3D) -> Vector3:
	var malla: MeshInstance3D = n as MeshInstance3D
	if malla == null or malla.mesh == null or not malla.position.is_zero_approx():
		return n.global_position
	return malla.global_transform * malla.mesh.get_aabb().get_center()


## Un lote junta muchas copias de una malla (árboles, rocas) en un solo nodo que no se mueve: se anota cada copia.
func _volcar_lote(datos: Dictionary, lote: MultiMeshInstance3D, ruta: String) -> void:
	var copias: MultiMesh = lote.multimesh
	for i in range(copias.instance_count):
		var p: Vector3 = lote.global_transform * copias.get_instance_transform(i).origin
		var en_mapa: Vector2 = Mapa3D.a_mapa(p)
		datos["3d|%s/Copia_%d" % [ruta, i]] = [en_mapa.x, en_mapa.y, "Copia"]


## La lógica del juego sigue en el plano: paredes invisibles, zonas de uso, puertas, letreros.
func _volcar_2d(datos: Dictionary) -> void:
	var vm: Node = get_first_node_in_group("village_manager")
	if vm == null:
		return
	for n: Node in vm.find_children("*", "Node2D", true, false):
		if not (n is CollisionObject2D) or _es_de_algo_vivo(n):
			continue
		var p: Vector2 = (n as Node2D).global_position
		datos["2d|" + str(vm.get_path_to(n))] = [p.x, p.y, n.get_class()]


func _volcar_vecinos(datos: Dictionary) -> void:
	for n: Node in get_nodes_in_group("village_npcs"):
		for campo: String in CAMPOS_VECINO:
			var v: Variant = n.get(campo)
			if v is Vector2 and (v as Vector2) != Vector2.ZERO:
				datos["vecino|%s|%s" % [n.name, campo]] = [(v as Vector2).x, (v as Vector2).y, "Sitio"]


## Planta de cada edificio en el mundo: el informe mira qué muebles han quedado fuera de todos.
func _volcar_edificios(datos: Dictionary) -> void:
	var vm: Node = get_first_node_in_group("village_manager")
	if vm == null:
		return
	for b: Dictionary in vm.get("building_footprints"):
		var r: Rect2 = b["rect"]
		datos["edificio|" + String(b["id"])] = [r.position.x, r.position.y, r.size.x, r.size.y]


## Vecinos, animales, el jugador y lo que se mueve solo cambian de sitio entre las dos partidas: no cuentan.
func _es_de_algo_vivo(n: Node) -> bool:
	var a: Node = n
	while a != null:
		if a is CharacterBody2D or a is CharacterBody3D or a is RigidBody2D or a is RigidBody3D:
			return true
		if a.is_in_group("village_npcs") or a.is_in_group("player") or a.is_in_group("animals") or String(a.name) in PARTES_VIVAS:
			return true
		a = a.get_parent()
	return false


func _leer(modo: String) -> Dictionary:
	var texto := FileAccess.get_file_as_string(SALIDA % modo)
	var datos: Variant = JSON.parse_string(texto)
	return datos if datos is Dictionary else {}
