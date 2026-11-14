extends SceneTree

## Sondeo de las zonas de terreno: mueve en memoria la plaza, el lago y la ciénaga del editor
## (mapa/Mundo3D.tscn → «Zonas», sin guardar) y comprueba que el agua, la hondonada, la plataforma y el muelle
## van con su pieza en coordenadas reales del mundo y que en el sitio viejo ya no queda nada:
##   flatpak run org.godotengine.Godot --headless --path . -s tools/tests/sondeo_zonas.gd

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const ESCENA_EDITOR := "res://mapa/Mundo3D.tscn"
const DESPLAZAMIENTO_MUNDO := Vector2(2600.0, -1900.0)
const LAGO_VIEJO := Vector2(-4350.0, 800.0)
const CIENAGA_VIEJA := Vector2(-7675.0, 1640.0)
const PLAZA_VIEJA := Vector2(2325.0, 245.0)
const HONDO_COTA: float = -2.0

var _escena_movida: PackedScene = null
var _fallos: int = 0


func _initialize() -> void:
	_mover_zonas()
	var zona: GDScript = load("res://mapa/zona.gd")
	var agua: GDScript = load("res://scripts/fisica/Agua.gd")
	var relieve: GDScript = load("res://scripts/visuals/WorldStageBase3D.gd")
	var rio_lago: GDScript = load("res://scripts/fisica/RioLago.gd")
	var lago_nuevo: Vector2 = LAGO_VIEJO + DESPLAZAMIENTO_MUNDO
	_comprobar("el lago se desplaza a su sitio nuevo", (zona.call("rect_mundo", "lago") as Rect2).has_point(lago_nuevo))
	_comprobar("se nada en el lago nuevo", bool(agua.call("en_lago", lago_nuevo)))
	_comprobar("no se nada en el sitio viejo", not bool(agua.call("en_lago", LAGO_VIEJO)))
	_comprobar("hay hondonada en el lago nuevo", float(relieve.call("terrain_height_px", lago_nuevo)) < HONDO_COTA)
	_comprobar("no queda hondonada en el sitio viejo", float(relieve.call("terrain_height_px", LAGO_VIEJO)) > HONDO_COTA)
	var muelle: Vector2 = rio_lago.call("lake_dock_center")
	_comprobar("el muelle va con el lago", muelle.distance_to(lago_nuevo) < 1500.0)
	_comprobar("el muelle no es agua", not bool(agua.call("en_lago", muelle)))
	var cienaga_nueva: Vector2 = CIENAGA_VIEJA + DESPLAZAMIENTO_MUNDO
	_comprobar("hay cuenca en la ciénaga nueva", float(relieve.call("terrain_height_px", cienaga_nueva)) < HONDO_COTA)
	_comprobar("no queda cuenca en la ciénaga vieja", float(relieve.call("terrain_height_px", CIENAGA_VIEJA)) > HONDO_COTA)
	_comprobar("el jugador enferma en la ciénaga nueva", (zona.call("rect_mundo", "cienaga") as Rect2).has_point(cienaga_nueva))
	_comprobar("y no en la vieja", not (zona.call("rect_mundo", "cienaga") as Rect2).has_point(CIENAGA_VIEJA))
	var plaza_nueva: Vector2 = PLAZA_VIEJA + DESPLAZAMIENTO_MUNDO
	_comprobar("la plaza va a su sitio nuevo", (zona.call("rect_mundo", "plaza") as Rect2).has_point(plaza_nueva))
	_comprobar("y no queda en el sitio viejo", not (zona.call("rect_mundo", "plaza") as Rect2).has_point(PLAZA_VIEJA))
	print("SONDEO zonas: %s" % ("bien" if _fallos == 0 else "%d fallos" % _fallos))
	quit(1 if _fallos > 0 else 0)


func _comprobar(que: String, bien: bool) -> void:
	if not bien:
		_fallos += 1
		print("SONDEO zonas FALLA: " + que)


func _mover_zonas() -> void:
	var escena: Node = (load(ESCENA_EDITOR) as PackedScene).instantiate()
	var d3: Vector3 = Mapa3D.a_3d(DESPLAZAMIENTO_MUNDO, 0.0) - Mapa3D.a_3d(Vector2.ZERO, 0.0)
	d3.y = 0.0
	for z: Node in escena.get_node("Zonas").get_children():
		(z as Node3D).position += d3
	_escena_movida = PackedScene.new()
	_escena_movida.pack(escena)
	_escena_movida.take_over_path(ESCENA_EDITOR)
	escena.free()
