@tool
extends Node3D

## Mueble de un edificio en el editor del mapa 3D (grupo «Muebles» de la escena de su edificio, mapa/edificios/<id>.tscn;
## en las casas de recién llegados, la de su casa modelo), 2026-11-10.
## Muévelo o gíralo (eje vertical) con el ratón: el juego lo pone ahí con su pared invisible («choque»). Como está
## dentro de su edificio, si mueves el edificio el mueble va con él.

const AssetLib = preload("res://scripts/visuals/AssetLibrary3D.gd")
const CARPETA := "Muebles" ## grupo que contiene los muebles de un edificio

## Nombre interno del mueble en el juego (no lo cambies).
@export var clave: String = ""
## Dónde estaba en el mapa 2D y en su edificio cuando se creó esta pieza (no lo cambies).
@export var pos_original: Vector2 = Vector2.ZERO
@export var local_original: Vector3 = Vector3.ZERO
@export var giro_original: float = 0.0
## Modelo y tamaño con que lo dibuja el juego (solo para verlo aquí).
@export var modelo: String = ""
@export var tam3: Vector3 = Vector3.ZERO
@export var alto3: float = -1.0
## Planta en la que está (0 = baja, 1 = alta).
@export var piso: int = 0
## Lo que ocupa su pared invisible visto desde arriba (ancho, fondo), en las mismas unidades que «tam3». En 0, 0 se
## atraviesa (sillas, alfombras…). Gira con el mueble. Si choca, los vecinos tampoco se quedan de pie encima.
@export var choque: Vector2 = Vector2.ZERO


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	for c in get_children():
		if c.has_meta("vista_mueble"):
			c.queue_free()
	var m: Node3D = AssetLib.instantiate_model(modelo, tam3, alto3, true, true)
	if m != null:
		m.set_meta("vista_mueble", true)
		add_child(m) # sin «owner»: no se guarda en la escena

