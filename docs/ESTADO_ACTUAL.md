# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code, portátil. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
Fallos visibles pendientes de la partida del usuario (`docs/FALLOS_VISIBLES.md`), en el orden aprobado:
1. ✅ Bosque del Caso I: árboles separados (hecho).
2. ✅ Posada: puertas en los 3 cuartos y camas de adulto (hecho).
3. ✅ Los sapos de la Llanura Salvaje son ahora bandidos (hecho).
4. ✅ Caso I con un día de margen (hecho).
5. ✅ Césped sin dibujo repetido (hecho).
6. ✅ Animales con vida propia en modo demo (hecho).
7. ✅ Reñidero en las alcantarillas (decorado; las peleas reales siguen bajo la posada).

**Plan del 2026-11-11 terminado.** Siguiente bloque: lo que decida el usuario (pistas en el agua, edificios antiguos, mapa 3× o historia).

## b) Último avance completado
- 2026-11-11: los 6 puntos del plan del día (posada, bandidos, Caso I día 2, césped, animales, reñidero) y la reorganización del repositorio (nuevo `CLAUDE.md`, `docs/specs/`, `docs/archivo/`, filtros de IA).
- 2026-11-12 (noche anterior): conversión a 3D terminada y en `main` (etiqueta `fin-paso-a-3d`): cuerpos 3D de
  protagonista y vecinos, pisos y sótanos reales, nadar y bucear (30 s de aire), vista/oído con alturas, manos en 1.ª
  persona, agua con movimiento, modo 2D borrado, rendimiento (plaza ~25 fps en el portátil).

## c) Siguiente paso técnico inmediato
Ninguno en marcha: esperar al usuario. Candidatos: rehacer edificios antiguos uno a uno, mapa 3× más grande.

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
