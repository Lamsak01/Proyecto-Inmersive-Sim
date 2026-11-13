#!/usr/bin/env python3
"""Junta un grupo del «Decorado» del editor que se estiró ×E pieza a pieza (Claude Code, 2026-11-13).

Con el mapa ×5 (tools/estirar_mapa.py, ya borrada) cada pieza del decorado fue a E veces su sitio original, con su
mismo tamaño: un conjunto hecho de varias piezas (el cementerio: muros, verja, parcelas) quedó en trozos sueltos por
el prado. Esto lo recompone: cada pieza cuyo sitio original (metadata/pos_original) cae en el recinto dado va a
    E·c + (p − c)        (c = centro del grupo en el mapa original)
es decir, el grupo entero en su sitio ×E pero con su forma de siempre. Con --sitios mueve también las cruces de
«Sitios» cuyo nombre empiece por uno de los prefijos dados (su sitio original es el del mundo / E).

  python3 tools/juntar_decorado.py X0 Y0 X1 Y1 [--sitios tumba_,entierro] [--probar]

X0 Y0 X1 Y1: recinto en el mapa ORIGINAL (píxeles de antes del ×5). --probar: solo lista lo que movería.
Úsala una vez por grupo (si ya no queda ninguna pieza estirada, no hace nada). Si Godot tiene abierta la escena,
recárgala SIN guardar después.
"""
import argparse
import math
import re
import sys

ESCENA = "mapa/Mundo3D.tscn"
E = 5.0          # el mismo número que scripts/fisica/Mapa3D.gd
ESCALA = 0.056   # metros por píxel del mapa (Mapa3D.ESCALA)
YA_JUNTA_PX = 2.0  # una pieza que no está en E·p ya se movió a mano: se avisa, pero se junta igual

RE_NODO = re.compile(r'\[node name="([^"]+)"[^\]]*parent="([^"]+)"')
RE_XF = re.compile(r'transform = Transform3D\(([^)]*)\)')
RE_ORIG = re.compile(r'metadata/pos_original = Vector2\(([^,]+), ([^)]+)\)')


def leer_piezas(bloques, recinto, prefijos):
    """Índice, nombre, sitio original y transform de cada pieza del grupo."""
    x0, y0, x1, y1 = recinto
    out = []
    for i, b in enumerate(bloques):
        m = RE_NODO.match(b)
        xf = RE_XF.search(b)
        if not m or not xf:
            continue
        nombre, padre = m.groups()
        v = [float(x) for x in xf.group(1).split(",")]
        orig = RE_ORIG.search(b)
        if padre.startswith("Decorado/") and orig:
            p = (float(orig.group(1)), float(orig.group(2)))
        elif padre == "Sitios" and any(nombre.startswith(pre) for pre in prefijos):
            p = (v[9] / ESCALA / E, v[11] / ESCALA / E)
        else:
            continue
        if x0 <= p[0] <= x1 and y0 <= p[1] <= y1:
            out.append((i, padre + "/" + nombre, p, v, xf.group(0)))
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("recinto", nargs=4, type=float)
    ap.add_argument("--sitios", default="", help="prefijos de cruces de «Sitios» que van con el grupo, separados por comas")
    ap.add_argument("--probar", action="store_true")
    a = ap.parse_args()
    texto = open(ESCENA, encoding="utf-8").read()
    bloques = re.split(r"(?=^\[)", texto, flags=re.M)
    prefijos = [p for p in a.sitios.split(",") if p]
    piezas = leer_piezas(bloques, a.recinto, prefijos)
    if not piezas:
        print("No hay piezas en ese recinto.")
        return 1
    estiradas = [p for p in piezas if p[1].startswith("Decorado/") and
                 math.dist((p[3][9] / ESCALA, p[3][11] / ESCALA), (p[2][0] * E, p[2][1] * E)) < YA_JUNTA_PX]
    if not estiradas:
        # Las cruces de «Sitios» no guardan su sitio original: juntar dos veces las movería de nuevo
        print("Ninguna pieza del decorado sigue estirada: el grupo ya está junto, no se toca.")
        return 1
    xs = [p[2][0] for p in piezas]
    ys = [p[2][1] for p in piezas]
    c = ((min(xs) + max(xs)) / 2.0, (min(ys) + max(ys)) / 2.0)
    print("%d piezas; centro original %s" % (len(piezas), c))
    for i, ruta, p, v, viejo in piezas:
        nuevo = (c[0] * E + (p[0] - c[0]), c[1] * E + (p[1] - c[1]))
        aviso = "" if math.dist((v[9] / ESCALA, v[11] / ESCALA), (p[0] * E, p[1] * E)) < YA_JUNTA_PX else "  (estaba movida a mano)"
        print("  %s: %s -> (%d, %d)%s" % (ruta, p, round(nuevo[0]), round(nuevo[1]), aviso))
        v2 = v[:]
        v2[9] = round(nuevo[0] * ESCALA, 4)
        v2[11] = round(nuevo[1] * ESCALA, 4)
        bloques[i] = bloques[i].replace(viejo, "transform = Transform3D(" + ", ".join("%g" % x for x in v2) + ")", 1)
    if a.probar:
        print("(--probar: no se ha guardado nada)")
        return 0
    open(ESCENA, "w", encoding="utf-8").write("".join(bloques))
    print("Guardado %s. Si Godot la tiene abierta: recargar SIN guardar." % ESCENA)
    return 0


if __name__ == "__main__":
    sys.exit(main())
