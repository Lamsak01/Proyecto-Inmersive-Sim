extends SceneTree

## Sondeo de las zonas de terreno (Claude Code, 2026-11-11): mueve en memoria la plaza, el lago y la ciénaga del editor
## (mapa/Mundo3D.tscn → «Zonas», sin guardar) y comprueba que el agua, la hondonada y el muelle van con su pieza y que
## en el sitio viejo ya no queda nada. Sin ventana, unos segundos:
##   flatpak run org.godotengine.Godot --headless --path . -s tools/tests/sondeo_zonas.gd

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const ESCENA_EDITOR := "res://mapa/Mundo3D.tscn"
const DESPLAZAMIENTO_PX := Vector2(2600.0, -1900.0) ## lejos: la zona movida no se solapa con su sitio viejo
const LAGO_DENTRO := Vector2(-870.0, 160.0)   ## mapa original: en mitad del agua del lago
const CIENAGA_DENTRO := Vector2(-1535.0, 328.0) ## mapa original: centro de la cuenca de la ciénaga
const HONDO_PX: float = -2.0                  ## por debajo de esto el terreno es cuenca de agua

var _escena_movida: PackedScene = null ## si nadie la guarda, la caché la suelta y se vuelve a leer el archivo
var _fallos: int = 0


func _initialize() -> void:
	_mover_zonas()
	var anclas: GDScript = load("res://mapa/anclas.gd")
	var agua: GDScript = load("res://scripts/fisica/Agua.gd")
	var relieve: GDScript = load("res://scripts/visuals/WorldStageBase3D.gd")
	var pesca: GDScript = load("res://scripts/obstacles/FishingSpot.gd")
	var lago_viejo: Vector2 = LAGO_DENTRO * Mapa3D.E
	var lago_nuevo: Vector2 = lago_viejo + DESPLAZAMIENTO_PX
	_comprobar("el lago se estira a su sitio nuevo", (anclas.call("estirar", LAGO_DENTRO) as Vector2).is_equal_approx(lago_nuevo))
	_comprobar("la lógica (mover) lleva el lago al sitio nuevo", (anclas.call("mover", LAGO_DENTRO) as Vector2).is_equal_approx(lago_nuevo))
	_comprobar("desde el sitio nuevo se vuelve al original", (anclas.call("desmover", lago_nuevo) as Vector2).is_equal_approx(LAGO_DENTRO))
	_comprobar("se nada en el lago nuevo", bool(agua.call("en_lago", lago_nuevo)))
	_comprobar("no se nada en el sitio viejo", not bool(agua.call("en_lago", lago_viejo)))
	_comprobar("hay hondonada en el lago nuevo", float(relieve.call("terrain_height_px", lago_nuevo)) < HONDO_PX)
	_comprobar("no queda hondonada en el sitio viejo", float(relieve.call("terrain_height_px", lago_viejo)) > HONDO_PX)
	var muelle: Vector2 = pesca.call("lake_dock_center")
	_comprobar("el muelle va con el lago", (anclas.call("desestirar", muelle) as Vector2).distance_to(LAGO_DENTRO) < 300.0)
	_comprobar("el muelle no es agua", not bool(agua.call("en_lago", muelle)))
	var cienaga_nueva: Vector2 = CIENAGA_DENTRO * Mapa3D.E + DESPLAZAMIENTO_PX
	_comprobar("hay cuenca en la ciénaga nueva", float(relieve.call("terrain_height_px", cienaga_nueva)) < HONDO_PX)
	_comprobar("no queda cuenca en la ciénaga vieja", float(relieve.call("terrain_height_px", CIENAGA_DENTRO * Mapa3D.E)) > HONDO_PX)
	var campo := Vector2(-300.0, 1500.0)
	_comprobar("el campo abierto no cambia", (anclas.call("estirar", campo) as Vector2).is_equal_approx(campo * Mapa3D.E))
	print("SONDEO zonas: %s" % ("bien" if _fallos == 0 else "%d fallos" % _fallos))
	quit(1 if _fallos > 0 else 0)


func _comprobar(que: String, bien: bool) -> void:
	if not bien:
		_fallos += 1
		print("SONDEO zonas FALLA: " + que)


## Mueve en memoria cada pieza de «Zonas» y hace que el juego lea esa versión en vez del archivo.
func _mover_zonas() -> void:
	var escena: Node = (load(ESCENA_EDITOR) as PackedScene).instantiate()
	var d3: Vector3 = Mapa3D.a_3d(DESPLAZAMIENTO_PX, 0.0) - Mapa3D.a_3d(Vector2.ZERO, 0.0)
	d3.y = 0.0
	for zona: Node in escena.get_node("Zonas").get_children():
		(zona as Node3D).position += d3
	_escena_movida = PackedScene.new()
	_escena_movida.pack(escena)
	_escena_movida.take_over_path(ESCENA_EDITOR)
	escena.free()
