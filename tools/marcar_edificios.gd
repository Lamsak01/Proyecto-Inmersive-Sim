extends SceneTree

## Paso 1 de docs/PLAN_MUNDO_DESDE_EDITOR.md (Claude Code, 2026-11-11): pone en la escena de cada edificio
## (mapa/edificios/<id>.tscn → «Marcas») los sitios que usa la lógica y que el juego tiene ahora mismo: puesto de
## trabajo, camas, mesa, mostrador y cofre. Arranca el juego, mira dónde está cada sitio y lo apunta en metros
## respecto a su edificio. No toca una marca que ya exista (así no pisa lo que el usuario haya movido).
## Con ventana (sin ella las mallas de la escena se guardarían vacías), ~1 min:
##   flatpak run org.godotengine.Godot --path . -s tools/marcar_edificios.gd

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Marca = preload("res://mapa/marca.gd")
const ESCENA_JUEGO := "uid://dsoiuct8kdsk3"
const EDIFICIO := "res://mapa/edificio.gd"
const PREFIJO_NODO := "B3D_"
const FOTOGRAMAS_ESPERA: int = 60
const SEMILLA: int = 11
const TAMANO_CRUZ_M: float = 0.5 ## tamaño de la cruz de la marca en el editor
## Campo de la ficha de un oficio → marca. Solo las familias con familiar ayudante (las fundadoras) entran aquí.
const MARCAS_DE_OFICIO: Dictionary = {
	"work_pos": Marca.TRABAJO, "kin_work_pos": Marca.TRABAJO_FAMILIAR,
	"bed1_pos": Marca.CAMA_1, "bed2_pos": Marca.CAMA_2, "table_pos": Marca.MESA,
}

var _pueblo: Node
var _edificios_3d: Node
var _pendientes: Dictionary = {} ## id del edificio → {id de la marca → sitio en metros del edificio}


func _initialize() -> void:
	seed(SEMILLA)
	root.add_child((load(ESCENA_JUEGO) as PackedScene).instantiate())
	for _i in range(FOTOGRAMAS_ESPERA):
		await process_frame
	_pueblo = get_first_node_in_group("village_manager")
	var escenario: Node = _pueblo.get("world_stage_3d") if _pueblo != null else null
	if escenario == null:
		push_error("MARCAR: no encuentro el pueblo o su escenario 3D")
		quit(1)
		return
	_edificios_3d = escenario.get("buildings_root_3d")
	_apuntar_oficios()
	_apuntar_cofres()
	var guardados: int = 0
	for id: String in _pendientes:
		guardados += guardar(id, _pendientes[id])
	print("MARCAR: %d marcas nuevas en %d edificios" % [guardados, _pendientes.size()])
	quit(0)


## Puesto de trabajo, camas, mesa y mostrador de cada familia fundadora.
func _apuntar_oficios() -> void:
	var fichas: Dictionary = _pueblo.get("trade_configs")
	var negocios: Dictionary = _pueblo.get("shop_businesses")
	for oficio: Variant in fichas:
		var ficha: Dictionary = fichas[oficio]
		if not ficha.has("kin_work_pos"):
			continue
		for campo: String in MARCAS_DE_OFICIO:
			_apuntar(MARCAS_DE_OFICIO[campo], ficha[campo])
		if negocios.has(oficio):
			_apuntar(Marca.PUESTO, (negocios[oficio] as Dictionary)["stall_pos"])


## Cofres: solo los de los edificios que ya tienen alguna marca de oficio (los de las familias fundadoras).
func _apuntar_cofres() -> void:
	for cofre: Dictionary in _pueblo.get("house_chests"):
		var id: String = _edificio_en(cofre["pos"])
		if _pendientes.has(id):
			_apuntar(Marca.COFRE, cofre["pos"])


## Apunta un sitio del mundo como marca del edificio que lo contiene, en metros respecto a ese edificio.
func _apuntar(marca: String, sitio_mundo: Vector2) -> void:
	var id: String = _edificio_en(sitio_mundo)
	var nodo: Node3D = _edificios_3d.get_node_or_null(PREFIJO_NODO + id) as Node3D
	if id.is_empty() or nodo == null or load(EDIFICIO).call("escena", id) == null:
		push_warning("MARCAR: «%s» en %s no cae dentro de un edificio con escena" % [marca, sitio_mundo])
		return
	var en_edificio: Vector3 = nodo.transform.affine_inverse() * Mapa3D.a_3d(sitio_mundo)
	en_edificio.y = 0.0 # las marcas van en el suelo del edificio
	if not _pendientes.has(id):
		_pendientes[id] = {}
	(_pendientes[id] as Dictionary)[marca] = en_edificio


func _edificio_en(sitio_mundo: Vector2) -> String:
	for planta: Dictionary in _pueblo.get("building_footprints"):
		if (planta["rect"] as Rect2).has_point(sitio_mundo):
			return String(planta.get("id", ""))
	return ""


## Añade a la escena del edificio las marcas que le falten ({id de la marca → sitio en metros del edificio}).
## Devuelve cuántas añadió.
static func guardar(id: String, marcas: Dictionary) -> int:
	var escena: PackedScene = load(EDIFICIO).call("escena", id)
	var raiz: Node = escena.instantiate()
	var carpeta: Node = raiz.get_node(Marca.CARPETA)
	var nuevas: int = 0
	for marca: String in marcas:
		if carpeta.has_node(marca):
			continue
		var cruz := Marker3D.new()
		cruz.set_script(Marca)
		cruz.name = marca
		cruz.set("id_marca", marca)
		cruz.gizmo_extents = TAMANO_CRUZ_M
		cruz.position = marcas[marca]
		carpeta.add_child(cruz)
		cruz.owner = raiz
		nuevas += 1
	var error: int = OK
	if nuevas > 0:
		var nueva := PackedScene.new()
		error = nueva.pack(raiz)
		if error == OK:
			error = ResourceSaver.save(nueva, escena.resource_path)
	raiz.free()
	if error != OK:
		push_error("MARCAR: no pude guardar %s (error %d)" % [id, error])
		return 0
	return nuevas
