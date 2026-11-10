@tool
extends RefCounted

## Mapa3D: el ÚNICO sitio donde se pasa de una posición del mapa (x, y en píxeles, como piensan los vecinos) a una
## posición del mundo 3D, y al revés. Todo el juego, el editor del mapa y las herramientas lo usan.
## Paso del mundo a 3D (docs/PLAN_MUNDO_3D.md, paso 0, 2026-11-10).
##
## Por qué hay senos y cosenos: el 3D se construyó para que una cámara inclinada 58° cuadrara con el mapa plano, así que
## el eje norte-sur (z) está estirado ×1,18 y las alturas ×1,89. Se mantiene así para que el mundo se vea igual que hoy.
## Uso: const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")  →  Mapa3D.a_3d(pos), Mapa3D.a_mapa(v3)…

const ESCALA: float = 0.02            ## 1 píxel de mapa = 0,02 unidades 3D en el eje x
const INCLINACION_GRADOS: float = 58.0
const SIN: float = 0.848048096156426  ## sin(58°): estira el eje z
const COS: float = 0.5299192642332049 ## cos(58°): estira las alturas


## Mapa (x, y) + altura en píxeles → mundo 3D. No suma el relieve del suelo (eso lo hace el escenario).
static func a_3d(p: Vector2, alto_px: float = 0.0) -> Vector3:
	return Vector3(p.x * ESCALA, alto_px * ESCALA / COS, p.y * ESCALA / SIN)


## Mundo 3D → mapa (x, y). La altura se pierde; para ella, alto_a_px().
static func a_mapa(v: Vector3) -> Vector2:
	return Vector2(v.x / ESCALA, v.z * SIN / ESCALA)


## Altura en píxeles de mapa → unidades 3D, y al revés.
static func alto_a_3d(px: float) -> float:
	return px * ESCALA / COS


static func alto_a_px(y: float) -> float:
	return y * COS / ESCALA


## Tamaño de una caja: ancho y fondo del mapa más alto, todo en píxeles → tamaño 3D.
static func tam_a_3d(tam: Vector2, alto_px: float) -> Vector3:
	return Vector3(tam.x * ESCALA, alto_px * ESCALA / COS, tam.y * ESCALA / SIN)
