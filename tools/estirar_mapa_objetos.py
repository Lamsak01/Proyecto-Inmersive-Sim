#!/usr/bin/env python3
"""Mapa ×E, segunda pasada (2026-11-11): tras tools/estirar_mapa.py, los objetos y decorados que estaban pegados a un
edificio (hasta CERCA px de su planta original: pozo de la posada, barro del molino, farolas de la puerta…) se habían ido a
E veces su sitio, lejos del edificio. Aquí vuelven con él: origen = E·c_edificio + (p − c_edificio) + lo que el usuario
los hubiera movido. Las plantas originales salen de mapa/referencia_mapa.json. Se usa UNA vez, después de estirar_mapa.py.
  python3 tools/estirar_mapa_objetos.py [--probar]
"""
import json
import re
import sys

ESCALA = 0.056
CERCA = 40.0
NUM = r"-?[0-9.]+(?:e-?[0-9]+)?"
RE_NODE = re.compile(r'^\[node name="([^"]+)"(?: type="[^"]+")?(?: parent="([^"]*)")?')
RE_XF = re.compile(r"^transform = Transform3D\(([^)]*)\)$")
RE_V2 = re.compile(r"^(pos_original|metadata/pos_original) = Vector2\(([^)]*)\)$")


def leer_e() -> float:
	with open("scripts/fisica/Mapa3D.gd", encoding="utf-8") as f:
		return float(re.search(r"^const E: float = (" + NUM + ")", f.read(), re.M).group(1))


def fmt(x: float) -> str:
	s = "%.8g" % x
	return "0" if s in ("-0", "0") else s


def edificio_de(p, rects):
	for (x, y, w, h) in rects:
		if x - CERCA <= p[0] <= x + w + CERCA and y - CERCA <= p[1] <= y + h + CERCA:
			return (x + w * 0.5, y + h * 0.5)
	return None


def main() -> int:
	probar = "--probar" in sys.argv
	E = leer_e()
	if E == 1.0:
		print("E = 1: nada que hacer"); return 1
	ref = json.load(open("mapa/referencia_mapa.json", encoding="utf-8"))
	rects = [tuple(e["r"]) for e in ref["edificios"]]
	with open("mapa/Mundo3D.tscn", encoding="utf-8", newline="") as f:
		lineas = f.read().split("\n")
	salida, cambios = [], 0
	cab, padre, orig, bloque = None, "", None, []

	def cerrar():
		nonlocal cambios
		if cab is not None and orig is not None and (padre == "Objetos" or (padre.startswith("Decorado/") and padre.count("/") == 1)):
			cb = edificio_de(orig, rects)
			if cb is not None:
				for k, ln in enumerate(bloque):
					m = RE_XF.match(ln)
					if m:
						v = [float(x) for x in m.group(1).split(",")]
						dx = v[9] - E * orig[0] * ESCALA
						dz = v[11] - E * orig[1] * ESCALA
						v[9] = (E * cb[0] + (orig[0] - cb[0])) * ESCALA + dx
						v[11] = (E * cb[1] + (orig[1] - cb[1])) * ESCALA + dz
						bloque[k] = "transform = Transform3D(" + ", ".join(fmt(x) for x in v) + ")"
						cambios += 1
		if cab is not None:
			salida.append(cab)
		salida.extend(bloque)

	for ln in lineas:
		m = RE_NODE.match(ln)
		if m:
			cerrar()
			cab, padre, orig, bloque = ln, m.group(2) or "", None, []
			continue
		mv = RE_V2.match(ln)
		if mv:
			orig = [float(x) for x in mv.group(2).split(",")]
		bloque.append(ln)
	cerrar()
	if not probar:
		with open("mapa/Mundo3D.tscn", "w", encoding="utf-8", newline="") as f:
			f.write("\n".join(salida))
	print("E = %g · objetos pegados a un edificio recolocados: %d%s" % (E, cambios, " (solo prueba)" if probar else ""))
	return 0


if __name__ == "__main__":
	sys.exit(main())
