extends SceneTree

## Paso 1 de docs/PLAN_MUNDO_DESDE_EDITOR.md (Claude Code, 2026-11-11): convierte cada edificio que todavía construye
## el código en una escena propia, mapa/edificios/<id>.tscn, con sus grupos fijos (Muros, Interior, PisoAlto, Tejado,
## Muebles y Marcas) en metros respecto al centro del edificio, y cambia su pieza de mapa/Mundo3D.tscn → «Edificios»
## por una copia de esa escena, sin moverla. Después el juego carga la escena y ya no hace falta el código que lo dibujaba.
## Con ventana (sin ella no se dibujan los modelos), ~1 min:
##   flatpak run org.godotengine.Godot --path . -s tools/convertir_edificios.gd
## No toca los edificios que ya tienen escena ni las casas de recién llegados (irán con una escena base común).

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Partes = preload("res://scripts/visuals/PartesEdificio3D.gd")
const Recursos = preload("res://tools/guardar_recursos_comunes.gd")
const ESCENARIO := "res://scripts/visuals/WorldStageBase3D.gd"
const EDIFICIO := "res://mapa/edificio.gd"
const MUEBLE := "res://mapa/mueble.gd"
const ESCENA_VALLE := "res://mapa/Mundo3D.tscn"
const ESCENA_JUEGO := "uid://dsoiuct8kdsk3"
const DIR := "res://mapa/edificios/"
const PREFIJO_SOLAR := "house_family_lot_"
const PREFIJO_NODO := "B3D_"
const FOTOGRAMAS_ESPERA: int = 60
const SEMILLA: int = 11

var _recursos := Recursos.new(DIR + "comun/")


func _initialize() -> void:
	var escenario_base: Script = load(ESCENARIO)
	escenario_base.set("grabar_muebles", true)        # los muebles no se dibujan: se anotan y pasan a piezas
	escenario_base.set("edificios_por_codigo", true)
	escenario_base.set("juntar_edificios", false)     # se juntan aquí, ya en metros respecto al edificio
	var ya_hechos: Dictionary = (load(EDIFICIO).call("escenas") as Dictionary).duplicate()
	# Todos los edificios en su sitio de fábrica y sin girar: así cada interior sale exacto respecto a su edificio
	load(EDIFICIO).set("_leido", true)
	load(EDIFICIO).set("_cache", {})
	seed(SEMILLA)
	root.add_child((load(ESCENA_JUEGO) as PackedScene).instantiate())
	for _i in range(FOTOGRAMAS_ESPERA):
		await process_frame
	var escenario: Node = _escenario()
	var pueblo: Node = get_first_node_in_group("village_manager")
	if escenario == null or pueblo == null:
		push_error("CONVERTIR: no encuentro el escenario 3D o el pueblo")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR + "comun"))
	var convertidos: Array[String] = []
	for planta: Dictionary in pueblo.get("building_footprints"):
		var id := String(planta.get("id", ""))
		if id.is_empty() or id.begins_with(PREFIJO_SOLAR) or ya_hechos.has(id):
			continue
		if _convertir(escenario, id, (planta["rect"] as Rect2).get_center()):
			convertidos.append(id)
	print("CONVERTIR: %d edificios guardados en %s" % [convertidos.size(), DIR])
	var error: int = _cambiar_piezas_del_valle(convertidos)
	print("CONVERTIR: valle guardado (error %d)" % error)
	quit(0 if error == OK else 1)


func _escenario() -> Node:
	for nodo: Node in root.find_children("*", "", true, false):
		if nodo.has_method("rebuild_buildings_3d"):
			return nodo
	return null


## Pasa un edificio construido por el juego a su escena. `centro`: centro de su planta en el mapa.
func _convertir(escenario: Node, id: String, centro: Vector2) -> bool:
	var construido: Node3D = (escenario.get("buildings_root_3d") as Node).get_node_or_null(PREFIJO_NODO + id)
	if construido == null:
		return false
	var origen: Vector3 = escenario.call("to_3d", centro)
	var raiz := Node3D.new()
	raiz.set_script(load(EDIFICIO))
	raiz.name = id
	raiz.set("id_edificio", id)
	raiz.set("centro_original", centro / Mapa3D.E)
	for nombre: String in [Partes.MUROS, Partes.INTERIOR, Partes.PISO_ALTO, Partes.TEJADO]:
		var grupo: Node3D = construido.get_node_or_null(nombre)
		if grupo == null:
			continue
		_a_metros_del_edificio(grupo, origen)
		escenario.call("_merge_meshes_under", grupo, {})
		_podar_hijos(grupo)
		construido.remove_child(grupo)
		raiz.add_child(grupo)
	_dejar_en_reposo(raiz)
	raiz.add_child(_muebles(id, escenario.get("muebles_grabados"), origen, centro))
	var marcas := Node3D.new()
	marcas.name = Partes.MARCAS
	raiz.add_child(marcas)
	_poner_dueno(raiz, raiz)
	_recursos.sacar_de(raiz)
	var escena := PackedScene.new()
	var error: int = escena.pack(raiz)
	if error == OK:
		error = ResourceSaver.save(escena, DIR + id + ".tscn")
	raiz.free()
	if error != OK:
		push_error("CONVERTIR: no pude guardar %s (error %d)" % [id, error])
	return error == OK


## Lo construido viene en metros del mundo; cada hijo directo del grupo pasa a metros respecto al centro del edificio.
func _a_metros_del_edificio(grupo: Node3D, origen: Vector3) -> void:
	for hijo: Node in grupo.get_children():
		if hijo is Node3D:
			(hijo as Node3D).position -= origen


## Tras juntar las mallas quedan cientos de nodos vacíos (cajas y modelos ya fundidos): fuera. También los cofres,
## que el juego pone aparte.
func _podar_hijos(nodo: Node) -> void:
	for hijo: Node in nodo.get_children():
		if String(hijo.get_meta(Partes.ROL, "")) == Partes.COFRE:
			nodo.remove_child(hijo)
			hijo.free()
			continue
		_podar_hijos(hijo)
		var malla_vacia: bool = hijo is MeshInstance3D and (hijo as MeshInstance3D).mesh == null
		var nodo_vacio: bool = hijo.get_class() == "Node3D" and hijo.get_script() == null
		var sobra_animacion: bool = hijo is AnimationPlayer
		if hijo.get_child_count() == 0 and not hijo.has_meta(Partes.ROL) and (malla_vacia or nodo_vacio or sobra_animacion):
			nodo.remove_child(hijo)
			hijo.free()


## Estado de reposo de lo que se mueve (así se ve en el editor; jugando lo pone el juego a cada momento) y ningún
## resto de «esto era una copia de un modelo».
func _dejar_en_reposo(raiz: Node3D) -> void:
	for parte: Node in Partes.con_rol(raiz):
		var parte_3d := parte as Node3D
		match String(parte.get_meta(Partes.ROL)):
			Partes.PUERTA, Partes.PUERTA_CUARTO:
				parte_3d.rotation = Vector3.ZERO
			Partes.CANDADO, Partes.POSTIGO, Partes.CUERPO_MORGUE:
				parte_3d.visible = false
			Partes.LUZ_NOCHE:
				parte_3d.visible = true
	for nodo: Node in raiz.find_children("*", "", true, false):
		nodo.scene_file_path = ""


## Grupo «Muebles»: una pieza por mueble anotado, en metros del edificio, con lo que el usuario la hubiera movido.
func _muebles(id: String, anotados: Array, origen: Vector3, centro: Vector2) -> Node3D:
	var carpeta := Node3D.new()
	carpeta.name = Partes.MUEBLES
	for anotado: Dictionary in anotados:
		if String(anotado["id"]) != id:
			continue
		var sitio: Vector3 = (anotado["p3"] as Vector3) - origen
		var pieza := Node3D.new()
		pieza.set_script(load(MUEBLE))
		pieza.name = ("%s_%s" % [String(anotado["modelo"]).get_file().get_basename(), "piso1" if int(anotado["piso"]) == 1 else ""]).trim_suffix("_").validate_node_name()
		pieza.set("clave", anotado["clave"])
		pieza.set("pos_original", centro / Mapa3D.E + Mapa3D.a_mapa(sitio))
		pieza.set("local_original", sitio)
		pieza.set("giro_original", float(anotado["giro"]))
		pieza.set("modelo", anotado["modelo"])
		pieza.set("tam3", anotado["tam3"])
		pieza.set("piso", int(anotado["piso"]))
		var ajuste: Array = load(MUEBLE).call("ajuste", anotado["clave"])
		pieza.position = sitio + (Mapa3D.a_3d(ajuste[0]) if not ajuste.is_empty() else Vector3.ZERO)
		pieza.rotation_degrees.y = float(anotado["giro"]) + (float(ajuste[1]) if not ajuste.is_empty() else 0.0)
		carpeta.add_child(pieza, true)
	return carpeta


func _poner_dueno(nodo: Node, dueno: Node) -> void:
	for hijo: Node in nodo.get_children():
		hijo.owner = dueno
		_poner_dueno(hijo, dueno)


## En el valle, cada pieza convertida pasa a ser una copia de su escena, en el mismo sitio y con el mismo giro.
func _cambiar_piezas_del_valle(ids: Array[String]) -> int:
	if ids.is_empty():
		return OK
	var valle: Node = (load(ESCENA_VALLE) as PackedScene).instantiate()
	var edificios: Node = valle.get_node("Edificios")
	for id: String in ids:
		var vieja: Node3D = edificios.get_node_or_null(id)
		var nueva: Node3D = (load(DIR + id + ".tscn") as PackedScene).instantiate()
		nueva.name = id
		if vieja != null:
			nueva.transform = vieja.transform
			var puesto: int = vieja.get_index()
			edificios.remove_child(vieja)
			vieja.free()
			edificios.add_child(nueva)
			edificios.move_child(nueva, puesto)
		else:
			nueva.position = Mapa3D.a_3d((nueva.get("centro_original") as Vector2) * Mapa3D.E)
			edificios.add_child(nueva)
		nueva.owner = valle
	var escena := PackedScene.new()
	var error: int = escena.pack(valle)
	if error == OK:
		error = ResourceSaver.save(escena, ESCENA_VALLE)
	valle.free()
	return error
