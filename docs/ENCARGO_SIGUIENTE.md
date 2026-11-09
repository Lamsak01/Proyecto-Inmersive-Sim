# ⭐ ENCARGO DE HOY — Cimiento: interiores en 1.ª persona de los edificios del Caso I
Objetivo: que los edificios que pisa el detective en el Caso I se vean y se recorran bien **en primera persona**, con el
nivel de la trattoria (salas con sentido, muebles 3D bien colocados, luz). **Edificio a edificio**, en este orden:
**comisaría y calabozo → morgue/hospital → taberna → biblioteca → botica del alquimista → capilla.** No crees edificios
nuevos ni toques el mapa (el río y el molino son otro encargo). Modo demo activo.

Fallos a cerrar (entradas de `docs/FALLOS_VISIBLES.md`): «edificios antiguos diminutos y feos» y «todas las casas
comparten la misma puerta» (solo en estos 6 edificios). Además, vistos en las capturas del recorrido de hoy:
- **Comisaría:** rejas verde chillón gigantes, cajón suelto, cepo; la cámara queda pegada a la pared. Necesita un
  **calabozo creíble** (celda con reja de hierro oscuro, catre, cubo, puerta con llave): el final de la demo pasa ahí.
- **Taberna:** mancha naranja enorme en el suelo y una franja amarilla (`docs/capturas_arreglos/recorrido/03_taberna_interior.png`).

Para cada edificio:
1. Entrar por la puerta en 1.ª persona sin atascarse (respeta los carriles de puerta), recorrer todas las salas.
2. Ninguna pared atravesable, ningún mueble flotando, metido en otro o bloqueando el paso; techos sin parpadeo.
3. La puerta pega con la fachada (no la misma para todos).
4. Captura antes/después en 1.ª persona en `docs/capturas_arreglos/interiores/` (al menos 2 por edificio: entrada y
   sala principal). Commit y push por edificio.
5. Al final, pasa `tools/tests/recorrido_fijo.gd` (debe seguir en «RECORRIDO PASSED»).

Si un edificio necesita algo grande (más metros, otra planta), **no lo hagas**: anótalo en el informe para el usuario.
Informe arriba de `docs/INFORME_ANTIGRAVITY.md`, máx. 15 líneas. Godot siempre en primer plano con `timeout`.

## Notas del supervisor
(ninguna)
