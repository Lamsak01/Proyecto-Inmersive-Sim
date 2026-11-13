extends SceneTree

## Volcado del mundo lógico (Claude Code, 2026-11-12; paso 4 de docs/PLAN_MUNDO_DESDE_EDITOR.md): arranca la partida y
## apunta, ordenado, cada choque (sitio, tamaño, giro, planta), zona de uso, marca 3D, planta o árbol que se recoge,
## vecino y sitio donde no se puede estar de pie. Se usa antes y después de mudar algo al editor: con `diff` de los dos
## archivos se ve qué se movió (lo ideal: nada, o solo lo que se quería arreglar). Sin ventana, ~1 min.
## Uso: flatpak run org.godotengine.Godot --headless --path . -s tools/tests/volcado_mundo.gd -- <nombre>
## Escribe user://volcado_<nombre>.txt (en Linux: ~/.var/app/org.godotengine.Godot/data/godot/app_userdata/La Placa de Petri).

const ESCENA_JUEGO := "uid://dsoiuct8kdsk3"
const SALIDA := "user://volcado_%s.txt"
const SEMILLA: int = 11
const FOTOGRAMAS_ESPERA: int = 150 ## lo que tarda en crearse todo, incluidos árboles talables y vecinos
const GRUPOS_VIVOS: Array[String] = ["destructible", "wild_flora", "village_npc"]


func _initialize() -> void:
	var nombre: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "actual"
	seed(SEMILLA)
	root.add_child(load(ESCENA_JUEGO).instantiate())
	for _i in range(FOTOGRAMAS_ESPERA):
		await physics_frame
	var vm: Node = root.find_child("VillageManager", true, false)
	var lineas: Array[String] = _choques()
	lineas.append_array(_zonas_y_marcas(vm))
	lineas.append_array(_vivos())
	lineas.sort() # el orden de creación no importa: solo dónde acaba cada cosa
	for r: Rect2 in vm.get("_no_stand_furniture_rects") + vm.get("_no_pisar_muebles"):
		lineas.append("NO_PISAR %s" % str(r))
	var f := FileAccess.open(SALIDA % nombre, FileAccess.WRITE)
	f.store_string("\n".join(lineas) + "\n")
	f.close()
	print("VOLCADO %s: %d líneas" % [nombre, lineas.size()])
	quit()


## Paredes invisibles: sitio, tamaño, giro, grupos de planta de la taberna y capa de choque.
func _choques() -> Array[String]:
	var out: Array[String] = []
	for sb: Node in get_nodes_in_group("prop_collider"):
		if not (sb is StaticBody2D):
			continue
		var tam := Vector2.ZERO
		for ch: Node in sb.get_children():
			if ch is CollisionShape2D and (ch as CollisionShape2D).shape is RectangleShape2D:
				tam = ((ch as CollisionShape2D).shape as RectangleShape2D).size.round()
		var grupos: Array[String] = []
		for g: StringName in sb.get_groups():
			if String(g).begins_with("tavern_"):
				grupos.append(String(g))
		grupos.sort()
		var cuerpo := sb as StaticBody2D
		out.append("%s %s %d %s capa=%d" % [str(cuerpo.global_position.round()), str(tam), roundi(cuerpo.rotation_degrees), str(grupos), cuerpo.collision_layer])
	return out


## Zonas donde se pulsa [E] (por nombre) y marcas que dicen al 3D qué poner.
func _zonas_y_marcas(vm: Node) -> Array[String]:
	var out: Array[String] = []
	var raiz: Node = vm.get("entities_root")
	for n: Node in raiz.get_children() + vm.get_children():
		if n is Area2D and not String(n.name).begins_with("@"):
			out.append("ZONA %s %s" % [n.name, str((n as Area2D).global_position.round())])
		elif n is Area2D:
			out.append("ZONA_SIN_NOMBRE %s %s" % [String(n.get_meta("village_station", "")), str((n as Area2D).global_position.round())])
		elif n is Node2D and n.has_meta("tipo_3d"):
			out.append("MARCA %s %s %s" % [String(n.get_meta("tipo_3d")), str((n as Node2D).global_position.round()), str(n.get_meta("giro_3d", 0.0))])
	return out


## Lo que se recoge o se tala y los vecinos, con su nombre y su sitio.
func _vivos() -> Array[String]:
	var out: Array[String] = []
	for g: String in GRUPOS_VIVOS:
		for n: Node in get_nodes_in_group(g):
			if n is Node2D:
				out.append("%s %s %s" % [g, n.name, str((n as Node2D).global_position.round())])
	return out
