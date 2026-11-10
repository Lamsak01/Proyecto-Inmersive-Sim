@tool
extends Node3D
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

## Pieza del mundo (árbol, roca, planta, tronco…) en el editor del mapa 3D (mapa/Mundo3D.tscn), 2026-11-10.
## Dibuja su modelo con el mismo lector que el juego (AssetLibrary3D), así se ve igual en Godot y jugando.
## Muévela, gírala o duplícala (Ctrl+D) como cualquier cosa. Para cambiar el modelo, cambia «modelo» en el Inspector.

const AssetLib = preload("res://scripts/visuals/AssetLibrary3D.gd")
const WB = preload("res://scripts/visuals/WorldStageBase3D.gd")

## Modelo dentro de assests/curated_3d (p. ej. «nature/PineTree_1.obj») o ruta completa «res://…».
@export var modelo: String = "":
	set(v):
		modelo = v
		_rehacer()
## Altura del modelo (en las mismas unidades que el juego: una persona mide unos 28).
@export var alto: float = 24.0:
	set(v):
		alto = v
		_rehacer()
## Tamaño visto desde arriba (ancho, fondo). Déjalo en 0, 0 para que solo mande la altura.
@export var tam: Vector2 = Vector2.ZERO:
	set(v):
		tam = v
		_rehacer()
## Cómo choca en el juego: automático según el modelo, o ninguno / tronco (solo el tronco del árbol) / forma (lo que ocupa).
@export_enum("auto", "ninguno", "tronco", "forma") var choque: String = "auto"


func _ready() -> void:
	_rehacer()


func _rehacer() -> void:
	if not is_inside_tree():
		return
	for c in get_children():
		if c.has_meta("pieza_modelo"):
			remove_child(c)
			c.queue_free()
	if modelo.is_empty() or not AssetLib.has_curated_assets():
		return
	var target := Vector3.ZERO
	var fit_h := -1.0
	if tam != Vector2.ZERO:
		target = Mapa3D.tam_a_3d(tam, alto)
	else:
		fit_h = maxf(0.05, Mapa3D.alto_a_3d(alto))
	var inst: Node3D = AssetLib.instantiate_model(modelo, target, fit_h, true, true)
	if inst == null:
		return
	inst.set_meta("pieza_modelo", true)
	add_child(inst) # sin «owner»: el modelo no se guarda en la escena, solo la pieza


## Tipo de choque que usará el juego.
func tipo_choque() -> String:
	if choque != "auto":
		return choque
	var f := modelo.get_file()
	if "Tree" in f or "Willow" in f:
		return "tronco"
	if "Rock" in f or "WoodLog" in f or "Stump" in f or "Bush" in f:
		return "forma"
	return "ninguno"
