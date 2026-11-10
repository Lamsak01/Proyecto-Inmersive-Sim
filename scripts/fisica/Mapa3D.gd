@tool
extends RefCounted

## Mapa3D: el ÚNICO sitio donde se pasa de una posición del mapa (x, y en píxeles, como piensan los vecinos) a una
## posición del mundo 3D, y al revés. Todo el juego, el editor del mapa y las herramientas lo usan.
## Paso del mundo a 3D (docs/PLAN_MUNDO_3D.md): paso 0 (un solo sitio) y paso 0b (escala uniforme), 2026-11-10.
##
## Escala uniforme (decisión del usuario, paso 0b): 1 unidad 3D = 1 metro, igual en los tres ejes. Una persona mide 1,75.
## - Suelo: 1 píxel de mapa = ESCALA metros, tanto este-oeste (x) como norte-sur (z).
## - Alturas: los números de altura del juego (pisos, muros, árboles…) se pensaron para la vista inclinada y por eso
##   cuentan algo menos que un píxel de suelo; ALTO los pasa a metros para que nada se aplaste.
## Uso: const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")  →  Mapa3D.a_3d(pos), Mapa3D.a_mapa(v3)…

const ESCALA: float = 0.056            ## 1 píxel de suelo = 5,6 cm
const ALTO: float = ESCALA / 0.5299192642332049 ## 1 píxel de altura ≈ 10,6 cm (el estiramiento antiguo de la vista inclinada)

## Escala del mundo antes del paso 0b (1 píxel = 0,02 unidades). Solo para los modelos y efectos que aún tienen medidas
## escritas a mano en la escala vieja: se agrandan con K. Se irá quitando según se reescriba cada uno.
const ESCALA_ANTIGUA: float = 0.02
const K: float = ESCALA / ESCALA_ANTIGUA

## Vista desde arriba: la cámara inclinada que hace que el 3D cuadre con el mapa del pueblo (ver WorldStage3D).
## Con suelo y alturas a distinta escala, el ángulo que los encaja es el de tan = 1/cos 58° (≈ 62,08°), y la imagen se
## estira en vertical 1/sin de ese ángulo.
const INCLINACION_GRADOS: float = 62.08002
const ESTIRA_VERTICAL: float = 1.1317307 ## 1 / sin(62,08°)


## Mapa (x, y) + altura en píxeles → mundo 3D. No suma el relieve del suelo (eso lo hace el escenario).
static func a_3d(p: Vector2, alto_px: float = 0.0) -> Vector3:
	return Vector3(p.x * ESCALA, alto_px * ALTO, p.y * ESCALA)


## Mundo 3D → mapa (x, y). La altura se pierde; para ella, alto_a_px().
static func a_mapa(v: Vector3) -> Vector2:
	return Vector2(v.x / ESCALA, v.z / ESCALA)


## Altura en píxeles de mapa → metros, y al revés.
static func alto_a_3d(px: float) -> float:
	return px * ALTO


static func alto_a_px(y: float) -> float:
	return y / ALTO


## Tamaño de una caja: ancho y fondo del mapa más alto, todo en píxeles → tamaño 3D.
static func tam_a_3d(tam: Vector2, alto_px: float) -> Vector3:
	return Vector3(tam.x * ESCALA, alto_px * ALTO, tam.y * ESCALA)


## Dirección del mapa → dirección 3D horizontal (sin normalizar).
static func dir_a_3d(d: Vector2) -> Vector3:
	return Vector3(d.x, 0.0, d.y)
