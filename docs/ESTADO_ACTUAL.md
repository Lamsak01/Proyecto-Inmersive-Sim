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

**Mapa ×5 hecho** (rama `mapa-x5` → `main` al pasar todas las pruebas; registro en `docs/specs/PLAN_MAPA_X3.md` §8). Siguiente bloque: los 11 edificios antiguos con huella ×2 (`BOCETO_EDIFICIOS_ANTIGUOS.md`), planificados con el usuario.

## b) Último avance completado
- 2026-11-11 (tarde/noche): mapa ×5 con el mecanismo de estiramiento por anclas; antes, los 6 puntos del plan del día (posada, bandidos, Caso I día 2, césped, animales, reñidero) y la reorganización del repositorio.
- 2026-11-12 (noche anterior): conversión a 3D terminada y en `main` (etiqueta `fin-paso-a-3d`): cuerpos 3D de
  protagonista y vecinos, pisos y sótanos reales, nadar y bucear (30 s de aire), vista/oído con alturas, manos en 1.ª
  persona, agua con movimiento, modo 2D borrado, rendimiento (plaza ~25 fps en el portátil).

## c) Siguiente paso técnico inmediato
Que el usuario juegue el mapa ×5 y diga si el tamaño le convence (bajar a ×4 o ×3 es cambiar `Mapa3D.E`, volver a convertir las escenas desde las copias `*.antes-x5.tscn` y repoblar). Luego, plan de edificios.

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
