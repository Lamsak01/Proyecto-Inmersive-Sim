@tool
extends RefCounted

## Mezclas del pincel del mapa (Claude Code, 2026-11-10). Cada mezcla dice qué siembra el pincel y en qué carpeta de
## mapa/Mundo3D.tscn. «peso» = cuántas veces más sale ese modelo que los demás; «alto» = [mínimo, máximo].
## Los árboles van a Vegetacion/Arboles (se talan y chocan por el tronco), los matorrales «Bush» se cortan y dan ramas,
## las rocas de Vegetacion/Rocas son adorno (las que se pican van en Vetas). Para añadir tus modelos de mis_recursos
## no hace falta tocar esto: coloca uno, selecciónalo y pulsa «Usar lo seleccionado» en el panel del pincel.

const MEZCLAS: Array = [
	{"nombre": "Bosque de pinos", "carpeta": "Vegetacion/Arboles", "separacion": 26.0, "densidad": 1.0, "modelos": [
		{"modelo": "nature/PineTree_1.obj", "alto": [40, 70], "peso": 3},
		{"modelo": "nature/PineTree_2.obj", "alto": [40, 70], "peso": 3},
		{"modelo": "nature/PineTree_3.obj", "alto": [40, 70], "peso": 3},
		{"modelo": "nature/PineTree_4.obj", "alto": [42, 76], "peso": 2},
	]},
	{"nombre": "Bosque mixto", "carpeta": "Vegetacion/Arboles", "separacion": 28.0, "densidad": 1.0, "modelos": [
		{"modelo": "nature/CommonTree_1.obj", "alto": [36, 66], "peso": 2},
		{"modelo": "nature/CommonTree_2.obj", "alto": [36, 70], "peso": 2},
		{"modelo": "nature/CommonTree_3.obj", "alto": [36, 70], "peso": 2},
		{"modelo": "nature/CommonTree_4.obj", "alto": [40, 70], "peso": 2},
		{"modelo": "nature/BirchTree_1.obj", "alto": [40, 70], "peso": 1},
		{"modelo": "nature/BirchTree_2.obj", "alto": [44, 76], "peso": 1},
		{"modelo": "nature/PineTree_1.obj", "alto": [40, 70], "peso": 1},
	]},
	{"nombre": "Sauces (orilla del agua)", "carpeta": "Vegetacion/Arboles", "separacion": 30.0, "densidad": 0.7, "modelos": [
		{"modelo": "nature/Willow_1.obj", "alto": [36, 56], "peso": 1},
		{"modelo": "nature/Willow_2.obj", "alto": [36, 56], "peso": 1},
	]},
	{"nombre": "Matorrales", "carpeta": "Vegetacion/Plantas", "separacion": 14.0, "densidad": 1.0, "modelos": [
		{"modelo": "nature/Bush_1.obj", "alto": [8, 12], "peso": 2},
		{"modelo": "nature/Bush_2.obj", "alto": [10, 12], "peso": 1},
		{"modelo": "nature/BushBerries_1.obj", "alto": [11, 13], "peso": 1},
		{"modelo": "nature/BushBerries_2.obj", "alto": [11, 14], "peso": 1},
	]},
	{"nombre": "Hierba y plantas", "carpeta": "Vegetacion/Plantas", "separacion": 9.0, "densidad": 1.0, "modelos": [
		{"modelo": "nature/Grass.obj", "alto": [4, 6], "peso": 3},
		{"modelo": "nature/Grass_2.obj", "alto": [4, 5], "peso": 3},
		{"modelo": "nature/Grass_Short.obj", "alto": [4, 6], "peso": 3},
		{"modelo": "nature/Plant_1.obj", "alto": [6, 8], "peso": 1},
		{"modelo": "nature/Plant_3.obj", "alto": [6, 9], "peso": 1},
		{"modelo": "nature/Plant_4.obj", "alto": [7, 9], "peso": 1},
		{"modelo": "nature/Plant_5.obj", "alto": [7, 9], "peso": 1},
	]},
	{"nombre": "Rocas", "carpeta": "Vegetacion/Rocas", "separacion": 16.0, "densidad": 0.6, "modelos": [
		{"modelo": "nature/Rock_2.obj", "alto": [5, 12], "peso": 3},
		{"modelo": "nature/Rock_3.obj", "alto": [6, 10], "peso": 1},
		{"modelo": "nature/Rock_4.obj", "alto": [6, 10], "peso": 1},
		{"modelo": "nature/Rock_5.obj", "alto": [6, 10], "peso": 1},
	]},
	{"nombre": "Troncos y tocones", "carpeta": "Vegetacion/Troncos", "separacion": 24.0, "densidad": 0.4, "modelos": [
		{"modelo": "nature/WoodLog.obj", "alto": [14, 18], "peso": 1},
		{"modelo": "nature/WoodLog_Moss.obj", "alto": [14, 18], "peso": 1},
		{"modelo": "nature/TreeStump_Moss.obj", "alto": [8, 10], "peso": 1},
	]},
]
