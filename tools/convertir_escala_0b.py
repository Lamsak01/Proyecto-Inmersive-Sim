#!/usr/bin/env python3
"""Paso 0b del paso a 3D (docs/PLAN_MUNDO_3D.md): convierte el mapa editado por el usuario (mapa/Mundo3D.tscn) de la
escala vieja (1 px = 0,02 u; norte-sur estirado 1/sin 58°) a la uniforme en metros (scripts/fisica/Mapa3D.gd).

Se usa UNA vez. Hace copia antes (mapa/Mundo3D.antes-3d.tscn) y se niega a correr si la copia ya existe.
Cada cosa cae en el MISMO sitio del mapa del pueblo que antes (Mapa3D.a_mapa da las mismas x, y); solo cambia el 3D.
  python3 tools/convertir_escala_0b.py            → convierte
  python3 tools/convertir_escala_0b.py --probar   → solo cuenta qué cambiaría

Reglas (por carpeta de la escena):
- Posiciones: x, y (altura) × K; z × K·sin 58°  (= P).
- Vegetacion, Objetos, Edificios, BajoTierra: el modelo se rehace solo desde sus medidas en píxeles → el giro y la
  escala que puso el usuario se quedan igual; solo se mueve el origen. Edificios: «origen_3d» también.
- Muebles (dentro de cada edificio): sus medidas son locales al edificio → P en local (origen, local_original, tam3)
  y alto3 × K.
- Decorado y Caminos: las mallas guardadas están en la escala vieja → su forma entera pasa por P (en coordenadas del
  mundo); las carpetas que agrupan (Decorado/Zona/Objeto) solo mueven su origen y conservan el giro.
"""
import math
import os
import re
import shutil
import sys

ESCENA = "mapa/Mundo3D.tscn"
COPIA = "mapa/Mundo3D.antes-3d.tscn"
K = 0.056 / 0.02
S = math.sin(math.radians(58.0))
P = [K, K, K * S]  # escala de cada eje (x, y, z)

NUM = r"-?[0-9.]+(?:e-?[0-9]+)?"
RE_NODE = re.compile(r'^\[node name="([^"]+)"(?: type="[^"]+")?(?: parent="([^"]*)")?')
RE_XF = re.compile(r"^transform = Transform3D\(([^)]*)\)$")
RE_V3 = re.compile(r"^(origen_3d|local_original|tam3) = Vector3\(([^)]*)\)$")
RE_ALTO3 = re.compile(r"^alto3 = (" + NUM + ")$")


def fmt(x: float) -> str:
	s = "%.8g" % x
	return "0" if s in ("-0", "0") else s


# --- matrices 3×4: (filas de la base, origen) como en Godot: mundo = M·local + o ---
def mat_de(nums):
	v = [float(n) for n in nums.split(",")]
	return [v[0:3], v[3:6], v[6:9]], v[9:12]


def mul(a, b):
	(ma, oa), (mb, ob) = a, b
	m = [[sum(ma[i][k] * mb[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
	o = [sum(ma[i][k] * ob[k] for k in range(3)) + oa[i] for i in range(3)]
	return m, o


def inv(a):
	m, o = a
	det = (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
		+ m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))
	c = [[0.0] * 3 for _ in range(3)]
	for i in range(3):
		for j in range(3):
			r = [x for x in range(3) if x != j]
			q = [x for x in range(3) if x != i]
			minor = m[r[0]][q[0]] * m[r[1]][q[1]] - m[r[0]][q[1]] * m[r[1]][q[0]]
			c[i][j] = ((-1) ** (i + j)) * minor / det
	oi = [-sum(c[i][k] * o[k] for k in range(3)) for i in range(3)]
	return c, oi


IDENT = ([[1.0, 0, 0], [0, 1.0, 0], [0, 0, 1.0]], [0.0, 0.0, 0.0])


def regla(ruta: str) -> str:
	"""Qué regla toca a un nodo según su ruta en la escena (sin el «./» inicial)."""
	partes = ruta.split("/")
	raiz = partes[0]
	if len(partes) == 1:
		return "carpeta"
	if raiz == "Edificios" and "Muebles" in partes:
		return "carpeta" if partes[-1] == "Muebles" else "mueble"
	if raiz in ("Decorado",):
		return "carpeta_giro" if len(partes) <= 3 else "forma"
	if raiz == "Caminos":
		return "forma"
	return "rehace"


def _nueva_global(r, viejo_padre, nuevo_padre, local, cuenta):
	"""Transform global nueva de un nodo a partir de la vieja, según su regla."""
	m, o = mul(viejo_padre, local)
	tipo = regla(r)
	cuenta[tipo] = cuenta.get(tipo, 0) + 1
	if tipo == "mueble":
		lm, lo = local
		return mul(nuevo_padre, (lm, [lo[i] * P[i] for i in range(3)]))
	o2 = [o[i] * P[i] for i in range(3)]
	if tipo == "forma":
		return [[m[i][j] * P[i] for j in range(3)] for i in range(3)], o2
	return [row[:] for row in m], o2


def _texto_xf(t):
	lm, lo = t
	nums = [lm[0][0], lm[0][1], lm[0][2], lm[1][0], lm[1][1], lm[1][2], lm[2][0], lm[2][1], lm[2][2]] + lo
	return "transform = Transform3D(" + ", ".join(fmt(x) for x in nums) + ")"


def _es_identidad(t):
	m, o = t
	return all(abs(m[i][j] - (1.0 if i == j else 0.0)) < 1e-7 for i in range(3) for j in range(3)) and all(abs(x) < 1e-7 for x in o)


def convertir(texto: str):
	"""Devuelve (texto nuevo, cuenta por regla, globales viejas, globales nuevas)."""
	bloques = re.split(r"\n(?=\[)", texto)
	viejo_g = {".": IDENT}
	nuevo_g = {".": IDENT}
	cuenta = {}
	salida = []
	for bl in bloques:
		lns = bl.split("\n")
		mn = RE_NODE.match(lns[0])
		if not mn or mn.group(2) is None:
			salida.append(bl)  # recursos, conexiones y la raíz: igual
			continue
		nombre, pa = mn.group(1), mn.group(2)
		ruta = nombre if pa == "." else pa + "/" + nombre
		local = IDENT
		i_xf = -1
		for i, ln in enumerate(lns):
			mx = RE_XF.match(ln)
			if mx:
				local = mat_de(mx.group(1))
				i_xf = i
		viejo_g[ruta] = mul(viejo_g[pa], local)
		nuevo_g[ruta] = _nueva_global(ruta, viejo_g[pa], nuevo_g[pa], local, cuenta)
		local_nuevo = mul(inv(nuevo_g[pa]), nuevo_g[ruta])
		if i_xf >= 0:
			lns[i_xf] = _texto_xf(local_nuevo)
		elif not _es_identidad(local_nuevo):
			lns.insert(1, _texto_xf(local_nuevo))
			cuenta["transform añadida"] = cuenta.get("transform añadida", 0) + 1
		for i, ln in enumerate(lns):
			mv = RE_V3.match(ln)
			if mv:
				v = [float(x) for x in mv.group(2).split(",")]
				lns[i] = "%s = Vector3(%s)" % (mv.group(1), ", ".join(fmt(v[k] * P[k]) for k in range(3)))
				cuenta[mv.group(1)] = cuenta.get(mv.group(1), 0) + 1
			ma = RE_ALTO3.match(ln)
			if ma:
				a_ = float(ma.group(1))
				lns[i] = "alto3 = " + fmt(a_ * K if a_ > 0 else a_)
				cuenta["alto3"] = cuenta.get("alto3", 0) + 1
		salida.append("\n".join(lns))
	return "\n".join(salida), cuenta, viejo_g, nuevo_g


def main():
	os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
	probar = "--probar" in sys.argv
	if os.path.exists(COPIA) and not probar:
		print("CONVERTIR_0B: ya existe %s: el mapa ya se convirtió; no se hace nada" % COPIA)
		sys.exit(1)
	texto = open(ESCENA, encoding="utf-8").read()
	nuevo, cuenta, vg, ng = convertir(texto)
	# Comprobación: cada nodo queda en el mismo sitio del mapa 2D (x/0,02 ; z·sin/0,02 → x/0,056 ; z/0,056)
	peor = 0.0
	for r, (_, o) in vg.items():
		o2 = ng[r][1]
		a = (o[0] / 0.02, o[2] * S / 0.02)
		b = (o2[0] / 0.056, o2[2] / 0.056)
		peor = max(peor, abs(a[0] - b[0]), abs(a[1] - b[1]))
	print("CONVERTIR_0B: %s" % ", ".join("%s=%d" % kv for kv in sorted(cuenta.items())))
	print("CONVERTIR_0B: peor diferencia en el mapa del pueblo = %.4f px (%d nodos)" % (peor, len(vg)))
	if peor > 0.01:
		print("CONVERTIR_0B: FALLO, algo se movería en el mapa del pueblo; no se guarda")
		sys.exit(1)
	if probar:
		return
	shutil.copyfile(ESCENA, COPIA)
	open(ESCENA, "w", encoding="utf-8").write(nuevo)
	print("CONVERTIR_0B: hecho; copia en %s" % COPIA)


if __name__ == "__main__":
	main()
