# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code, portátil. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
Fallos visibles pendientes de la partida del usuario (`docs/FALLOS_VISIBLES.md`), en el orden aprobado:
1. ✅ Bosque del Caso I: árboles separados (hecho).
2. **Siguiente:** cuartos de la posada con puertas y camas más grandes (planta +1, 3 cuartos ya hechos).
3. El Caso I empieza a la vez que llega el jugador (pendiente de decisión del usuario, ver bloqueos).
4. Sapos de la Llanura Salvaje: diseño pedido (sapo verde de pie con ropa roja); hoy usan el modelo de rana.

## b) Último avance completado
- 2026-11-11: reorganización del repositorio (nuevo `CLAUDE.md`, `docs/specs/`, `docs/archivo/`, filtros de IA).
- 2026-11-12 (noche anterior): conversión a 3D terminada y en `main` (etiqueta `fin-paso-a-3d`): cuerpos 3D de
  protagonista y vecinos, pisos y sótanos reales, nadar y bucear (30 s de aire), vista/oído con alturas, manos en 1.ª
  persona, agua con movimiento, modo 2D borrado, rendimiento (plaza ~25 fps en el portátil).

## c) Siguiente paso técnico inmediato
Posada, planta +1: puertas en los 3 cuartos y camas de tamaño real; comprobar con `tools/tests/puertas_3d.gd` y una foto
(`tools/tests/capturas_fijas.gd`, sitio «taberna_dentro»).

## d) Bloqueos activos
- Punto 3: el usuario debe elegir si el Caso I empieza con un día de margen o al entrar en la posada.
- Pistas en el fondo del agua: mecanismo listo; el usuario decide cuáles.
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
