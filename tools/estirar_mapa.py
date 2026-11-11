#!/usr/bin/env python3
"""Mapa ×E (docs/specs/PLAN_MAPA_X3.md, 2026-11-11): estira las escenas del editor con el mismo número que
scripts/fisica/Mapa3D.gd (E). Se usa UNA vez; hace copia (*.antes-xE.tscn) y se niega a correr si la copia ya existe.
  python3 tools/estirar_mapa.py           → convierte
  python3 tools/estirar_mapa.py --probar  → solo cuenta qué cambiaría

Reglas:
- mapa/Mundo3D.tscn
  - Edificios y BajoTierra (centro_original), Objetos (pos_original) y Decorado/Zona/Objeto (metadata/pos_original):
    el origen pasa de c + d a E·c + d (c = sitio original en 3D); lo que el usuario movió (d) se conserva. Tamaño y giro
    igual. `origen_3d` no cambia (la foto del edificio se cuelga de él).
  - Vegetacion (árboles, rocas, plantas…): origen ×E en x y z.
  - Caminos: se borran; se rehacen con tools/hornear_caminos.gd (ya estirados y más anchos).
- mapa/EditorMapa.tscn (río en 2D): puntos del río y cruces ×E; ancho ×ANCHO_RIO.
- scenes/World.tscn: hijos directos de «Entities» (protagonista y bandidos de la llanura): posición ×E.
"""
import os
import re
import shutil
import sys

ESCALA = 0.056
ANCHO_RIO = 2.0
NUM = r"-?[0-9.]+(?:e-?[0-9]+)?"
RE_NODE = re.compile(r'^\[node name="([^"]+)"(?: type="[^"]+")?(?: parent="([^"]*)")?')
RE_XF = re.compile(r"^transform = Transform3D\(([^)]*)\)$")
RE_V2 = re.compile(r"^(pos_original|metadata/pos_original|centro_original|position) = Vector2\(([^)]*)\)$")
RE_ANCHO = re.compile(r"^ancho = (" + NUM + ")$")


def leer_e() -> float:
	with open("scripts/fisica/Mapa3D.gd", encoding="utf-8") as f:
		m = re.search(r"^const E: float = (" + NUM + ")", f.read(), re.M)
	return float(m.group(1))


def fmt(x: float) -> str:
	s = "%.8g" % x
	return "0" if s in ("-0", "0") else s


def bloques(lineas):
	"""Agrupa las líneas por nodo: [(cabecera o None, nombre, padre, [líneas])]."""
	out = []
	actual = [None, "", "", []]
	for ln in lineas:
		m = RE_NODE.match(ln)
		if m:
			out.append(actual)
			actual = [ln, m.group(1), m.group(2) or "", []]
		else:
			actual[3].append(ln)
	out.append(actual)
	return out


def mundo3d(E: float, probar: bool) -> int:
	with open("mapa/Mundo3D.tscn", encoding="utf-8", newline="") as f:
		lineas = f.read().split("\n")
	cambios = 0
	salida = []
	for cab, nombre, padre, cuerpo in bloques(lineas):
		if cab is None:
			salida.extend(cuerpo)
			continue
		if padre == "Caminos" or nombre == "Caminos":
			cambios += 1
			continue  # se rehacen con hornear_caminos
		origen = None
		for ln in cuerpo:
			m = RE_V2.match(ln)
			if m and m.group(1) in ("pos_original", "metadata/pos_original", "centro_original"):
				origen = [float(v) for v in m.group(2).split(",")]
		modo = ""
		if padre in ("Edificios", "BajoTierra", "Objetos") and origen is not None:
			modo = "pieza"
		elif padre.startswith("Decorado/") and padre.count("/") == 1 and origen is not None:
			modo = "pieza"
		elif padre.startswith("Vegetacion/"):
			modo = "escala"
		nuevo = []
		for ln in cuerpo:
			m = RE_XF.match(ln)
			if m and modo:
				v = [float(x) for x in m.group(1).split(",")]
				if modo == "pieza":
					v[9] += (E - 1.0) * origen[0] * ESCALA
					v[11] += (E - 1.0) * origen[1] * ESCALA
				else:
					v[9] *= E
					v[11] *= E
				ln = "transform = Transform3D(" + ", ".join(fmt(x) for x in v) + ")"
				cambios += 1
			nuevo.append(ln)
		salida.append(cab)
		salida.extend(nuevo)
	if not probar:
		with open("mapa/Mundo3D.tscn", "w", encoding="utf-8", newline="") as f:
			f.write("\n".join(salida))
	return cambios


def editor_2d(E: float, probar: bool) -> int:
	with open("mapa/EditorMapa.tscn", encoding="utf-8", newline="") as f:
		lineas = f.read().split("\n")
	cambios = 0
	salida = []
	for cab, nombre, padre, cuerpo in bloques(lineas):
		if cab is not None:
			salida.append(cab)
		for ln in cuerpo:
			if cab is not None and padre in ("Rio", "Cruces"):
				m = RE_V2.match(ln)
				if m and m.group(1) == "position":
					v = [float(x) * E for x in m.group(2).split(",")]
					ln = "position = Vector2(" + ", ".join(fmt(x) for x in v) + ")"
					cambios += 1
				m2 = RE_ANCHO.match(ln)
				if m2:
					ln = "ancho = " + fmt(float(m2.group(1)) * ANCHO_RIO)
					cambios += 1
			salida.append(ln)
	if not probar:
		with open("mapa/EditorMapa.tscn", "w", encoding="utf-8", newline="") as f:
			f.write("\n".join(salida))
	return cambios


def mundo_2d(E: float, probar: bool) -> int:
	with open("scenes/World.tscn", encoding="utf-8", newline="") as f:
		lineas = f.read().split("\n")
	cambios = 0
	salida = []
	for cab, nombre, padre, cuerpo in bloques(lineas):
		if cab is not None:
			salida.append(cab)
		for ln in cuerpo:
			if cab is not None and padre == "Entities":
				m = RE_V2.match(ln)
				if m and m.group(1) == "position":
					v = [float(x) * E for x in m.group(2).split(",")]
					ln = "position = Vector2(" + ", ".join(fmt(x) for x in v) + ")"
					cambios += 1
			salida.append(ln)
	if not probar:
		with open("scenes/World.tscn", "w", encoding="utf-8", newline="") as f:
			f.write("\n".join(salida))
	return cambios


def main() -> int:
	probar = "--probar" in sys.argv
	E = leer_e()
	if E == 1.0:
		print("E = 1 en Mapa3D.gd: nada que estirar"); return 1
	copias = [("mapa/Mundo3D.tscn", "mapa/Mundo3D.antes-x%g.tscn" % E), ("mapa/EditorMapa.tscn", "mapa/EditorMapa.antes-x%g.tscn" % E), ("scenes/World.tscn", "scenes/World.antes-x%g.tscn" % E)]
	if not probar:
		for orig, cop in copias:
			if os.path.exists(cop):
				print("Ya existe la copia %s: no se repite" % cop); return 1
		for orig, cop in copias:
			shutil.copyfile(orig, cop)
	print("E = %g · Mundo3D: %d cambios · EditorMapa: %d · World: %d%s" % (E, mundo3d(E, probar), editor_2d(E, probar), mundo_2d(E, probar), " (solo prueba)" if probar else ""))
	return 0


if __name__ == "__main__":
	sys.exit(main())
