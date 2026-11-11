# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-12, Claude Code, portátil. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
Fallos visibles pendientes de la partida del usuario (`docs/FALLOS_VISIBLES.md`), en el orden aprobado:
1. ✅ Bosque del Caso I: árboles separados (hecho).
2. ✅ Posada: puertas en los 3 cuartos y camas de adulto (hecho).
3. ✅ Los sapos de la Llanura Salvaje son ahora bandidos (hecho).
4. ✅ Caso I con un día de margen (hecho).
5. ✅ Césped sin dibujo repetido (hecho).
6. ✅ Animales con vida propia en modo demo (hecho).
7. ✅ Reñidero en las alcantarillas (decorado; las peleas reales siguen bajo la posada).

**Mapa ×5 terminado y en `main`** (2026-11-12 de madrugada; registro en `docs/specs/PLAN_MAPA_X3.md` §8): todas las pruebas en verde (juego entero, física, puertas 29/29, Caso I a pie 25/25, atascos 3 h = 0). Siguiente bloque: los 11 edificios antiguos con huella ×2 (`BOCETO_EDIFICIOS_ANTIGUOS.md`), planificados con el usuario.

## b) Último avance completado
- 2026-11-11/12: mapa ×5 con el mecanismo de estiramiento por anclas y repaso de ~45 sitios fijos que seguían en el mapa antiguo (pozos, camas, celda, carro, corral, tienda del jugador…); antes, los 6 puntos del plan del día (posada, bandidos, Caso I día 2, césped, animales, reñidero) y la reorganización del repositorio.
- 2026-11-12 (noche anterior): conversión a 3D terminada y en `main` (etiqueta `fin-paso-a-3d`): cuerpos 3D de
  protagonista y vecinos, pisos y sótanos reales, nadar y bucear (30 s de aire), vista/oído con alturas, manos en 1.ª
  persona, agua con movimiento, modo 2D borrado, rendimiento (plaza ~25 fps en el portátil).

## c) Siguiente paso técnico inmediato
Que el usuario juegue el mapa ×5 (partida nueva: las guardadas no valen) y diga si el tamaño le convence (bajar a ×4 o ×3 es cambiar `Mapa3D.E`, reconvertir las escenas desde las copias `*.antes-x5.tscn` y repoblar). Luego, plan de edificios. Regla nueva para pruebas: dos vecinos «juntos» se colocan como distancia, nunca como dos puntos fijos (`PLAN_MAPA_X3.md` §8).

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
