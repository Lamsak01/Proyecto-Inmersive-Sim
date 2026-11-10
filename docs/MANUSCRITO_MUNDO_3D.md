# Manuscrito del paso a 3D (y de cada reorganización del código)

> Una entrada por bloque, de la más nueva a la más antigua. Para personas: qué cambió en el juego, por qué, qué archivos
> (y de dónde a dónde se movió cada cosa), cómo se probó y cómo deshacerlo. El resumen de una línea va en el Registro de
> `docs/PLAN_MUNDO_3D.md` §10. Rama de trabajo: `mundo-3d`. Copia de seguridad: etiqueta `antes-de-mundo-3d`.

---

## Paso 0 — Preparación (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** nada visible. Es la base para lo demás.

**Por qué:** antes de dar física 3D al mundo hacía falta (1) poder volver atrás, (2) medir cómo está todo hoy para
comparar después y (3) que la fórmula que pasa del mapa al 3D esté en un solo sitio, porque la física la va a usar en todas
partes y había unas 20 copias repartidas.

**Qué se hizo:**
1. **Copia de seguridad y rama aparte.** Etiqueta `antes-de-mundo-3d` en `main` y rama `mundo-3d` (subidas a GitHub).
2. **Conversión única:** archivo nuevo `scripts/fisica/Mapa3D.gd` con `a_3d`, `a_mapa`, `alto_a_3d`, `alto_a_px` y
   `tam_a_3d`. Los mismos números que antes (comprobado con 2.000 puntos al azar).
   - `scripts/visuals/WorldStageBase3D.gd`: `WORLD_SCALE`, `PITCH_DEG`, `_sin_p` y `_cos_p` salen de `Mapa3D`;
     `to_3d`, `to_3d_flat` y `size_3d` llaman a `Mapa3D` (de 20 líneas a 6).
   - `scripts/visuals/WorldStageTerrain3D.gd`: `_a_mapa_2d` llama a `Mapa3D.a_mapa`.
   - `scripts/visuals/AnimalModel3D.gd`: su `WORLD_SCALE` sale de `Mapa3D`.
   - Editor del mapa (`mapa/anclas.gd`, `camino.gd`, `edificio.gd`, `mueble.gd`, `objeto.gd`, `pieza.gd`, `mundo3d.gd`,
     `pincel_nucleo.gd`) y `addons/pincel_mapa/pincel_plugin.gd`: fuera sus constantes `WORLD_SCALE`/`PITCH_DEG` y sus
     senos/cosenos propios; usan `Mapa3D`.
   - Herramientas `tools/hornear_*.gd` (vegetación, edificios, objetos, decorado, caminos, bajo tierra): igual.
3. **Arreglos de paso (fallaban ya antes de este trabajo; comprobado en la copia `antes-de-mundo-3d`):**
   - `tools/hornear_edificios.gd` no compilaba (`.hash()` sobre bytes); ahora usa `hash(...)` como la herramienta del decorado.
   - `tools/tests/rio_editor_juego.gd` esperaba el río original; el usuario ya lo editó (6 cruces, 7 tramos de agua). Ahora
     comprueba que el juego usa el río del editor y que hay un tramo de agua más que cruces.
   - `tools/tests/pincel_mapa.gd` cargaba sus piezas antes de que existieran los autoloads (no compilaba); ahora las carga
     al arrancar.
4. **Pruebas nuevas:**
   - `tools/tests/fisica_3d.gd`: prueba del paso a 3D; de momento comprueba que la conversión única da lo mismo que la
     antigua y que el escenario la usa.
   - `tools/tests/capturas_fijas.gd`: 6 fotos siempre iguales (plaza, río, bosque, molino, mansión, dentro de la taberna;
     mediodía, sin personajes) y comparación con una carpeta de referencia (% de píxeles distintos).
   - Fotos de referencia en `docs/capturas_mundo3d/referencia_paso0/` (hechas en el portátil, 3072×1728; en otro
     ordenador hay que hacer las suyas antes de comparar).
5. **Documentos nuevos:** `docs/MAPA_DEL_CODIGO.md` (qué hace cada carpeta y archivo) y este manuscrito.

**Cómo se probó:** `fisica_3d.gd` 7/7; fotos fijas iguales a la referencia (peor 0,38 %; el ruido entre dos tandas sin
cambios llega a 0,8 %); `verify_all.gd` ✅; `guardado_largo.gd` ✅; `sondeo_edificios_movidos.gd -- movido` 29/29;
`rio_editor_juego.gd` (normal y «mover») ✅; `pincel_mapa.gd` ✅; todos los scripts del editor y las herramientas cargan.

**Cómo deshacerlo:** `git checkout antes-de-mundo-3d` (todo el juego como estaba) o revertir el commit de este paso en la
rama `mundo-3d`.
